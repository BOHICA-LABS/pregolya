---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 117
previous_review: pass-116.md
---

# Adversarial Review: ferrochain (Pass 117)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 116 produced one HIGH finding:
- F-P116-01: `get_next_version` receiver-less → E0038 on `Arc<dyn CheckpointSaver>`; override promise undispatchable; langgraph instance-method parity misstated

Fix burst 119 was dispatched. Verification follows.

### F-P116-01 Verification — CLOSED

**ADR-005 v1.4 §CheckpointSaver Trait Placement:**

| Check | Result |
|-------|--------|
| `get_next_version` code block has `&self` receiver | VERIFIED — v1.4 code block shows `fn get_next_version(&self, current: Option<CheckpointId>, channel: &ChannelName) -> Result<CheckpointId, FerrochainError>` |
| "static because pure" rationale replaced with receiver rationale | VERIFIED — §CheckpointSaver Trait Placement now states three reasons: (1) E0038 dyn-compatibility avoidance; (2) virtual dispatch of backend overrides through `Arc<dyn CheckpointSaver>` vtable; (3) langgraph `BaseCheckpointSaver.get_next_version` is an instance method — prior "static because pure" claim correctly retracted |
| §Object-Safety of the 5-Method CheckpointSaver Trait section present | VERIFIED — explicit per-method dyn-compatibility status table present covering all 5 methods: `put_writes` (&self async, dyn-compat OK), `get_tuple` (&self async, dyn-compat OK), `list` (&self async, Pin<Box<dyn Stream>> OK), `put` (&self async, dyn-compat OK), `get_next_version` (&self provided, dyn-compat OK) |
| §Adjacent Trait Object-Safety Adjudications section present | VERIFIED — settles three adjacent axes: Runnable<Input,Output>→DynRunnable seam (receiver-less methods excluded via DynRunnable wrapper), BaseChatModel (static dispatch only; no `Arc<dyn BaseChatModel>` seam), MonotonicClock::get_next_version (receiver-less — separate symbol, not on CheckpointSaver vtable) |
| `list` return type updated to Pin<Box<dyn Stream...>> | VERIFIED — §Object-Safety table lists `list` return as `Pin<Box<dyn Stream<Item = Result<CheckpointTuple, FerrochainError>> + Send>>` per dyn-compatible boxed-stream pattern |

**interface-definitions v2.37 §CheckpointSaver:**

| Check | Result |
|-------|--------|
| `get_next_version` provided-method signature has `&self` receiver | VERIFIED — method signature reads `fn get_next_version(&self, current: Option<CheckpointId>, channel: &ChannelName) -> Result<CheckpointId, FerrochainError>` |
| `list` return type is `Pin<Box<dyn Stream<Item = Result<CheckpointTuple, FerrochainError>> + Send>>` | VERIFIED — v2.37 changes `Result<impl Stream<...>, FerrochainError>` (not dyn-compatible) to `Pin<Box<dyn Stream<Item = Result<CheckpointTuple, FerrochainError>> + Send>>` (dyn-compatible) |

**BC-2.04.003 v1.6 PC1:**

| Check | Result |
|-------|--------|
| PC1 quoted signature includes `&self` receiver | VERIFIED — PC1 reads `get_next_version(&self, current: Option<CheckpointId>, channel: &ChannelName) -> Result<CheckpointId, FerrochainError>` |
| Architecture Anchors cite updated to include `&self` | VERIFIED — Architecture Anchors section references `&self` in the get_next_version signature context |

**Rev-2 residue check (receiver-less `get_next_version` in live spec corpus, excluding changelog rows):**

| Pattern | Result |
|---------|--------|
| `fn get_next_version(current:` without `&self` in live spec (non-changelog) | CLEAN — all occurrences in ADR-005 have `&self`; receiver-less form present only in Alternatives-Considered comparison table (retraction audit-trail, exempt) |
| Receiver-less form in interface-definitions.md (non-changelog) | CLEAN — v2.37 body shows `&self`; v2.36 entry in changelog is retraction audit-trail (exempt) |
| Receiver-less form in BC-2.04.003.md (non-changelog) | CLEAN — PC1 body shows `&self`; v1.5 changelog row is retraction audit-trail (exempt) |

**dyn-Runnable / dyn-BaseChatModel zero-requirement claims (adjacent axes from §Adjacent Adjudications):**

| Axis | Result |
|------|--------|
| `Runnable<Input,Output>` not used as `dyn Runnable` | VERIFIED — ADR-005 §Adjacent confirms `DynRunnable` wrapper pattern excludes receiver-less methods from vtable; no `Arc<dyn Runnable>` seam exists |
| `BaseChatModel` not used as `dyn BaseChatModel` | VERIFIED — ADR-005 §Adjacent confirms static dispatch only; `Arc<dyn BaseChatModel>` is not a bounded-context seam |
| `MonotonicClock::get_next_version` confirmed as separate symbol | VERIFIED — remains receiver-less (not on `CheckpointSaver` vtable); called from `get_next_version(&self, ...)` default body |

**Cleared spot-checks:**

| Axis | Disposition |
|------|-------------|
| NFR-009 anchor (DI-009 connection-timeout 30s; IdempotencyStore lock_timeout cross-reference) | CLEAN — NFR-009 anchor is correct in BC-2.12.006 EC-002; lock_timeout default 30s cites NFR-009 correctly; no drift from F-P116-01 fix |
| SS-10 budget canon (BC-2.10.001/003/004 PolicyDecision table; BudgetConfig fields) | CLEAN — interface-definitions v2.37 §BudgetPolicy and §OnCeiling unchanged by F-P116-01 fix; decision table intact; F-P117-01 raised below for SS-10↔SS-12 gap |
| SS-12↔api-surface endpoints (CheckpointSaver BC anchor range in api-surface.md v1.5) | CLEAN — BC anchor range 001–007 in api-surface.md v1.5 is current; no drift from F-P116-01 fix |

**F-P116-01 conclusion:** CLOSED. `get_next_version` has `&self` in all three primary spec locations (ADR-005 v1.4, interface-definitions v2.37, BC-2.04.003 v1.6). Object-safety adjudications documented. Adjacent-trait zero-requirement claims verified. Zero receiver-less residue in live spec content.

---

## Part B — New Findings

### F-P117-01 — HIGH: summary_halt Absent from BC-2.12.003 Authoritative Run State Machine (PC7/PC8/PC13/PC18/PC19 and Output Invariant), interface-definitions Run Object Schema, and entities-server RunStatus Lifecycle — SS-10↔SS-12 Cross-Subsystem Contradiction

**Severity:** HIGH
**Scope:** `specs/behavioral-contracts/ss-12/BC-2.12.003.md` (v1.3, at pass-117 time) PC7, PC8, PC13, PC18, PC19, and Output Invariant; `specs/prd-supplements/interface-definitions.md` (v2.37, at pass-117 time) §Run Object Schema status enum, completed_at field, and output note; `specs/domain-spec/entities-server.md` (v1.7, at pass-117 time) §Run RunStatus lifecycle and completed_at semantics

#### Evidence Chain (5 independent facts)

**Fact 1 — BC-2.10.003 PC8(c)(d) explicitly defines summary_halt as the terminal Run status for the OnCeiling::Summarize path:**

`BC-2.10.003 PC8(c)` (SS-10, BudgetPolicy subsystem) mandates that when `PolicyDecision::Deny` fires with `on_ceiling = OnCeiling::Summarize`, the engine makes one final LLM call using `BudgetConfig.summarize_prompt` and the response IS the final run output. `BC-2.10.003 PC8(d)` explicitly asserts: the Run status after this summarize call is `summary_halt` (not `failed`). These two postconditions together establish `summary_halt` as a first-class terminal Run status with a defined output.

`entities-server.md v1.7` §BudgetConfig §OnCeiling variants (lines ~89-93) independently corroborates: `Summarize { summarize_prompt: String } — one final LLM call using the prompt; transition to summary_halt`. This is consistent with BC-2.10.003.

**Fact 2 — BC-2.12.003 v1.3 PC7 is missing the `in_progress → summary_halt` arc:**

At pass-117 time, `BC-2.12.003` v1.3 PC7 (the authoritative Run lifecycle state machine) enumerated the following arcs:
```
queued      → in_progress   (executor picks up the run)
in_progress → completed     (graph reaches END)
in_progress → failed        (unhandled error in graph or executor)
in_progress → interrupted   (HITL interrupt raised)
in_progress → cancelled     (POST .../cancel called while run is active)
queued      → cancelled     (POST .../cancel called before executor picks up)
interrupted → in_progress   (caller posts resume value)
```
The `in_progress → summary_halt` transition is not listed. The transition defined by BC-2.10.003 PC8(c)(d) has no corresponding arc in the BC-2.12.003 state machine. The OnCeiling::Summarize code path — when fully implemented in Phase 3 — would emit a Run in `summary_halt` status with no arc from the authoritative lifecycle document.

**Fact 3 — BC-2.12.003 v1.3 PC8 terminal set {completed, failed, cancelled} omits summary_halt:**

PC8 at pass-117 time reads: "Terminal states (no further transitions possible): `completed`, `failed`, `cancelled`." This three-member terminal set directly contradicts BC-2.10.003 PC8(d)'s assertion that summary_halt is a Run terminal state. A Phase 3 implementer reading PC8 would not include summary_halt in the terminal-state guard, making the state unreachable and potentially causing the OnCeiling::Summarize path to fail or leave the Run in `in_progress` indefinitely.

**Fact 4 — BC-2.12.003 v1.3 Output Invariant silently discards the summarize model response:**

The Invariant section at pass-117 time reads: "Run output (`output`) is populated only when `status = 'completed'`." The summarize model response — which BC-2.10.003 PC8(c) mandates as the final output for `summary_halt` runs — would be silently discarded by any implementation following this invariant verbatim. A caller polling a `summary_halt` run via `GET /threads/{thread_id}/runs/{run_id}` would receive `output: null` instead of the summarize response.

**Fact 5 — interface-definitions v2.37 Run Object Schema compounds the discrepancy at the API surface layer:**

At pass-117 time, `interface-definitions.md` v2.37 §Run Object Schema:
- `status` enum: `"queued" | "in_progress" | "completed" | "failed" | "interrupted" | "cancelled"` — `"summary_halt"` absent
- `completed_at` description: "set only on terminal transition (`completed`, `failed`, or `cancelled`)" — `summary_halt` absent
- `output` note: "present only when `status=completed`" — contradicts BC-2.10.003 PC8(c)

A client implementation following this schema would: (1) fail to parse/recognize `summary_halt` as a valid status; (2) not expect `completed_at` to be set on `summary_halt` transitions; (3) not request or display the output for `summary_halt` runs.

#### Failure Mode Table

| Mode | Trigger | Impact |
|------|---------|--------|
| Output silently discarded | Phase 3 implementer writes `output = if status == "completed" { Some(...) } else { None }` following BC-2.12.003 Invariant v1.3 | `summary_halt` runs return `null` output to callers; summarize model response silently discarded; `OnCeiling::Summarize` feature delivers zero value — callers see `status: "summary_halt"` but no summarize output |
| Run terminal state unreachable from state machine | Phase 3 implementer builds the Run state machine from BC-2.12.003 PC7/PC8 v1.3 | `summary_halt` transition is absent from the authoritative PC7 arc list and PC8 terminal set; implementer never adds the `in_progress → summary_halt` transition; the `OnCeiling::Summarize` code path transitions the Run to an unrecognized state or fails to persist the status change |
| completed_at not set on summary_halt transition | Phase 3 implementer sets `completed_at` per BC-2.12.003 PC13 terminal-set {completed, failed, cancelled} v1.3 | `summary_halt` runs have `completed_at: null` in storage; callers relying on `completed_at` for audit trail get no terminal timestamp for summarize-path runs |
| Status deserialization failure | Client follows interface-definitions v2.37 status enum (6 variants, no `summary_halt`) | Server returns `status: "summary_halt"` in JSON; client deserialization fails or silently ignores the value as unknown — callers cannot distinguish `summary_halt` from other terminal states |

#### Adjudication Required

Two structural options:

**Option 1 (authoritative):** `summary_halt` is a first-class terminal Run status — add `in_progress → summary_halt` arc to PC7; extend PC8 terminal set to `{completed, failed, cancelled, summary_halt}`; extend PC13 `completed_at` terminal set; extend PC18 status filter enum; extend PC19 deletable terminal set; update Output Invariant to `output populated when status ∈ {completed, summary_halt}`; update interface-definitions Run Object Schema status enum, completed_at, and output note; update entities-server.md RunStatus lifecycle and completed_at semantics. BC-2.10.003 PC8(d) is the authority. BC-2.06.001 EC-005 also needs clarification (RunEnd emitted for output-producing terminals: completed + summary_halt; not emitted for failed/cancelled/interrupted).

**Option 2 (alternative):** Retroactively reclassify `summary_halt` as a `failed` subcase (contradicts BC-2.10.003 PC8(d)'s explicit assertion "not failed"; requires BC-2.10.003 amendment; high cascading impact to SS-10 budget subsystem). **Not recommended.**

Option 1 is the correct path (BC-2.10.003 PC8(d) is authoritative; entities-server v1.7 §OnCeiling already correctly cites `summary_halt`; the gap is exclusively in SS-12 and interface surface documents).

**Fix burst 120 dispatched** (Option 1 adjudication; PO + BA sequential).

---

## Cleared Candidates

| Axis | Disposition |
|------|-------------|
| F-P116-01 `get_next_version` receiver-less E0038 | CLOSED — `&self` present in all three primary spec sites; §Object-Safety table documents dyn-compat status of all 5 CheckpointSaver methods; §Adjacent Trait Object-Safety Adjudications settles Runnable/BaseChatModel/MonotonicClock axes; zero receiver-less residue in live spec content |
| dyn-Runnable / dyn-BaseChatModel zero-requirement | CLEARED — ADR-005 v1.4 §Adjacent Adjudications explicitly settles both axes; no `Arc<dyn Runnable>` or `Arc<dyn BaseChatModel>` seam in bounded-contexts |
| NFR-009 anchor and IdempotencyStore lock_timeout cross-reference | CLEAN — no drift from F-P116-01 fix; 30s correctly cited in BC-2.12.006 EC-002 |
| SS-10 budget canon correctness (interface-definitions §BudgetPolicy + BC-2.10.001/003/004) | CLEAN — F-P116-01 fix did not touch budget canon; PolicyDecision × on_ceiling decision table intact; F-P117-01 raised above for the SS-10→SS-12 propagation gap (separate finding) |
| SS-12↔api-surface BC anchor range for CheckpointSaver | CLEAN — api-surface.md v1.5 BC anchor range 001–007 is current; no drift |

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 (F-P117-01: `summary_halt` absent from BC-2.12.003 PC7/PC8/Invariant v1.3 and interface-definitions v2.37 Run Object Schema — SS-10↔SS-12 cross-subsystem contradiction; output-only-when-completed invariant silently discards summarize model response) |
| MED | 0 |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **1** |

**CLEAN (strict):** no (1 HIGH finding)
**CLEAN (PR-merge):** no (1 HIGH finding)

**Convergence counter:** 0/3 (counter unchanged — pass 117 NOT CLEAN strict; fix burst 120 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** HIGH (F-P117-01 is a cross-subsystem propagation gap — BC-2.10.003 in SS-10 defined `summary_halt` correctly, but the authoritative SS-12 Run state machine in BC-2.12.003 never received the corresponding arc/terminal-set/invariant updates; the output-only-when-completed invariant directly contradicts the BC-2.10.003 PC8(c) mandate that the summarize model response IS the final output)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 117 |
| **New findings** | 1 |
| **Cleared axes** | F-P116-01 E0038 CLOSED; dyn-Runnable/dyn-BaseChatModel zero-requirement CLEARED; NFR-009 anchor CLEAN; SS-10 budget canon CLEAN; SS-12↔api-surface anchor range CLEAN |
| **Novelty score** | HIGH |
| **Median severity** | HIGH |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1 HIGH; counter 0/3 unchanged; fix burst 120 dispatched; NEXT: pass 118 on new HEAD after fix burst 120) |
