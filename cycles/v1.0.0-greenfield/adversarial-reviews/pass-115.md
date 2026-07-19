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
pass: 115
previous_review: pass-114.md
---

# Adversarial Review: ferrochain (Pass 115)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 114 produced one CRIT finding (F-P114-01: ADR-005 rev-1 AtomicU64 MonotonicClock design violated BC-2.04.003/005/006 cross-restart invariants; all 7 ss-04 BCs cited nonexistent `architecture/ferrochain-checkpoint.md`). Fix burst 117 was dispatched. Verification of that fix follows.

### F-P114-01 Verification — CLOSED at design level

**ADR-005 rev-2 (F-P114-01 fix):**

| Check | Result |
|-------|--------|
| `MonotonicClock` redesigned as stateless ZST (no `AtomicU64` field) | VERIFIED — ADR-005 §Decision shows `pub struct MonotonicClock;` with no fields |
| `get_next_version(current: Option<CheckpointId>, _channel: &ChannelName) -> Result<CheckpointId, FerrochainError>` signature present | VERIFIED — function signature matches BC-2.04.003 PC1 exactly |
| "Cross-instance ordering: not required" claim retracted | VERIFIED — §Cross-Restart Monotonicity Guarantee explicitly states "The rev-1 claim … is retracted" |
| Seeding scope defined as per-(thread_id, checkpoint_ns) pair via `get_tuple()` | VERIFIED — §Seeding Scope documents the seeding mechanism with `get_tuple()` return fed as `current` |
| E-CHKPT-003 failure path documented (get_tuple failure halts recovery) | VERIFIED — §Failure Mode: get_tuple() Read Failure present in ADR-005 body |
| Crash-recovery walk end-to-end: `get_tuple()` → `current = Some(c)` → `get_next_version(Some(c), channel)` → `Ok(CheckpointId(c.0 + 1))` | PASS — the design is coherent: no ID regression possible; persisted-max is always the seed |
| BC-2.04.005 crash-recovery compliance: restart resumes same `(thread_id, checkpoint_ns)` with IDs strictly > persisted maximum | VERIFIED PASS — `get_tuple()` returns the persisted maximum before `get_next_version` is called; `c.0 + 1` guarantee holds |
| BC-2.04.006 Inv1 PK uniqueness across restarts | VERIFIED PASS — composite PK `(thread_id, checkpoint_ns, checkpoint_id)` cannot collide across restarts because `get_tuple()` supplies the current persisted max |

**7 Anchor targets (BC-2.04.001–007 Architecture Anchors):**

All 7 ss-04 BCs were corrected from nonexistent `architecture/ferrochain-checkpoint.md` to real files in fix burst 117. Verification of anchor validity:

| BC | Corrected Anchor | Target exists? | Notes |
|----|-----------------|----------------|-------|
| BC-2.04.001 | `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` | VERIFIED | ADR-005 v1.1+ present |
| BC-2.04.002 | `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` | VERIFIED | Same ADR |
| BC-2.04.003 | `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` | VERIFIED (partial) | §CheckpointSaver Trait Placement absent from ADR at pass-115 time → F-P115-02 |
| BC-2.04.004 | `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` | VERIFIED | Fork lineage section present |
| BC-2.04.005 | `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` | VERIFIED | §Failure Mode documents crash-recovery halt path |
| BC-2.04.006 | `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` | VERIFIED | §Seeding Scope / §Rationale documents composite PK scope |
| BC-2.04.007 | `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` | PARTIAL | `put` method absent from interface-definitions §CheckpointSaver (3-method trait at pass-115 time) → F-P115-02 |

**Rev-1 BC residue check (live spec corpus, excluding semport/ and retraction-table rows):**

| Pattern | Result |
|---------|--------|
| `AtomicU64` in live spec content (non-changelog) | CLEAN — hits in ADR-005 are comparison-table / alternatives-considered / changelog (audit-trail exempt); hits in semport/ are dependency-disposition (different domain) |
| `next_id` in live spec content (non-changelog) | CLEAN — only occurrence is ADR-005 comparison table §API Surface Reconciliation (retraction audit-trail) |
| `per saver instance` in live spec content (non-changelog) | CLEAN — only occurrence is VP-002 v1.1 changelog row (correctly notes the v1.0 framing as superseded) |

**F-P114-01 conclusion:** CLOSED at design level. Crash-recovery walk PASS. All 7 anchors resolve to a real file (1 partial triggers F-P115-02 on a separate axis). Zero rev-1 BC residue in live spec content.

## Part B — New Findings

### F-P115-01 — HIGH: ADR-005 rev-2 Ripple Not Swept — verification-architecture.md and purity-boundary-map.md Still Describe Retracted AtomicU64 Design

**Severity:** HIGH
**Scope:** `specs/architecture/verification-architecture.md` (line 43 at pass-115 time),
`specs/architecture/purity-boundary-map.md` (line 59 at pass-115 time)

#### Evidence

**verification-architecture.md line 43 (at pass-115 time, before fix burst 118):**

The Kani sync-core mandate section contained:
```
- `checkpoint::clock` — (monotonic AtomicU64 read) — sync increment and compare
```

ADR-005 rev-2 replaced the `AtomicU64` counter design with a stateless ZST and a pure successor function `get_next_version(current, channel)`. There is no `AtomicU64` read or "sync increment and compare" in the rev-2 design — the function takes `current: Option<CheckpointId>` as a parameter and computes `c.0 + 1` with no mutable state. The parenthetical description was carrying forward the rev-1 design language verbatim.

**Risk:** A Kani harness implementer reading this line would scaffold a proof that models an in-memory counter as a mutable atomic variable — the wrong abstraction for a stateless pure function. The Phase 6 harness for `checkpoint::clock` should model `MonotonicClock::get_next_version` as a pure function mapping `(Option<u64>, _)` → `u64`; any proof that introduces an `AtomicU64` or a mutable counter would be testing a non-existent design.

**purity-boundary-map.md line 59 (at pass-115 time, before fix burst 118):**

The Pure Core table's `checkpoint::clock` row contained in the Pure Guarantee column:
```
Monotonic counter increment; UUID wall-clock rejection is pure check
```

"Monotonic counter increment" implies an in-memory mutable counter increments on each call — again the retracted AtomicU64 framing. The rev-2 design has NO counter. The function is a pure arithmetic successor: `None → CheckpointId(1)`, `Some(c) → CheckpointId(c.0 + 1)`. The phrase "counter increment" is incorrect and misleading — it describes state that does not exist.

#### Required Fix (fix burst 118 dispatched)

1. **verification-architecture.md:** Replace the `checkpoint::clock` entry to reflect the stateless pure function description: `pure get_next_version(current) successor function; stateless, no atomic counter`
2. **purity-boundary-map.md §Pure Core `checkpoint::clock` row:** Replace Pure Guarantee column from "Monotonic counter increment; UUID wall-clock rejection is pure check" to "Pure successor function of caller-supplied `current`; UUID wall-clock rejection is pure check"

---

### F-P115-02 — HIGH: interface-definitions §CheckpointSaver 3-Method Trait — BC-2.04.006 PC2 / BC-2.04.007 PC1 / BC-2.04.002 PC4 / BC-2.04.001 EC-003 Unsatisfiable; get_next_version Placement Unresolved

**Severity:** HIGH
**Scope:** `specs/prd-supplements/interface-definitions.md` §CheckpointSaver (at pass-115 time),
`specs/behavioral-contracts/ss-04/BC-2.04.003.md` PC1,
`specs/architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` §CheckpointSaver Trait Placement (absent at pass-115 time)

#### Evidence Chain

**Axis A — Missing `put` method (BC-2.04.006 PC2 / BC-2.04.007 PC1 / BC-2.04.002 PC4 / BC-2.04.001 EC-003)**

At pass-115 time, `interface-definitions.md` §CheckpointSaver defined a 3-method trait:

```rust
pub trait CheckpointSaver: Send + Sync {
    async fn put_writes(...) -> Result<(), FerrochainError>;
    async fn get_tuple(...) -> Result<Option<CheckpointTuple>, FerrochainError>;
    async fn list(...) -> Result<impl Stream<...>, FerrochainError>;
}
```

The following BCs cannot be satisfied by a 3-method trait:

- **BC-2.04.006 PC2:** requires the saver to enforce the composite PK `(thread_id, checkpoint_ns, checkpoint_id)` uniqueness constraint — this occurs at the point of persisting a full checkpoint blob. `put_writes` persists only partial channel updates before the next super-step; it is not the full-checkpoint persistence call. A `put` method (persisting `Checkpoint` + `CheckpointMetadata`) is required to satisfy PC2's enforcement obligation.

- **BC-2.04.007 PC1:** requires encryption to be applied to the checkpoint blob when an `EncryptedSerializer` is active. `put_writes` persists write-ahead log entries, not the checkpoint blob. The encryption-at-blob-persistence guarantee requires a `put` method that accepts a `Checkpoint` argument.

- **BC-2.04.002 PC4 / BC-2.04.001 EC-003:** PC4 specifies persistence at `DurabilityTier::Exit`; EC-003 specifies `E-CHKPT-001` on `CheckpointSaver` initialization failure. Both require a full-blob persistence operation distinct from `put_writes`.

The absence of `put` means the interface-definitions §CheckpointSaver trait cannot satisfy any of the four BC predicates above — they are structurally unsatisfiable against the 3-method surface.

**Axis B — get_next_version Placement Unresolved**

BC-2.04.003 PC1 states: "A `CheckpointSaver` implementation provides a `get_next_version(current, channel)` method." This language names the `CheckpointSaver` as the provider. At pass-115 time:

- ADR-005 rev-2 defined `MonotonicClock::get_next_version` as a static associated function on `MonotonicClock` — but did NOT define a corresponding provided method on `CheckpointSaver`. The ADR addressed the ID-generation algorithm, not the trait placement.
- `interface-definitions.md` §CheckpointSaver had no `get_next_version` method in the trait definition.
- BC-2.04.003 PC1's language ("A `CheckpointSaver` implementation provides...") was formally unsatisfied — a caller using only the `CheckpointSaver` trait surface would find no `get_next_version` method.

**The langgraph reference corpus** (`BaseCheckpointSaver` in langgraph) places `get_next_version` on the saver class, not on a separate clock utility. This is the reference design that PC1's "provides a method" language follows. An implementation that exposes `get_next_version` only via `MonotonicClock::` without a trait-level method violates PC1's literal text and the reference-corpus parity it captures.

#### Failure Modes

| Failure mode | Trigger | Impact |
|---|---|---|
| Full-blob checkpoint never persisted | Implementer scaffolds `CheckpointSaver` from `interface-definitions.md`; no `put` method defined | BC-2.04.006/007 obligations silently dropped; encryption not applied; PK uniqueness not enforced at persistence time |
| Phase 3 `get_next_version` call fails to compile | Story writer uses `saver.get_next_version(...)` based on BC-2.04.003 PC1 text | `CheckpointSaver` has no such method; Red Gate tests fail with trait-resolution error |
| Kani harness targets wrong module | Phase 6 implementer reads ADR-005 and writes harness against `MonotonicClock` only | BC-2.04.003's "saver provides" contract remains unverified at trait level |

#### Required Fix (fix burst 118 dispatched)

1. **interface-definitions.md §CheckpointSaver:** Add `put` method (5th method) with full doc-comment, `E-CHKPT-005` tenancy error annotation, and 4 BC anchor annotations (BC-2.04.002 PC4/EC-002, BC-2.04.001 EC-003, BC-2.04.006 PC2, BC-2.04.007 PC1+INV-1). Add `get_next_version` as provided method with default delegation to `MonotonicClock::get_next_version`. Extend BC anchor line to 001–007. Extend Gate #31 type note with `Checkpoint`/`CheckpointMetadata` (entities-graph.md §Checkpoint) and `CheckpointId` (ADR-005).
2. **ADR-005:** Add §CheckpointSaver Trait Placement subsection adjudicating the provided-method pattern and rationale (BC-2.04.003 PC1 "provides a method" language + langgraph reference corpus parity).
3. **BC-2.04.003 PC1:** Sharpen wording to reflect provided-method semantics explicitly (default impl delegates to `MonotonicClock`; MAY override).
4. **api-surface.md CheckpointSaver row:** Extend BC anchor range from 001–006 to 001–007 (BC-2.04.007 now a live anchor via `put` method's encryption obligation).

## Cleared Axes

| Axis | Result |
|------|--------|
| F-P114-01 ADR-005 rev-2 crash-recovery design correctness | CLOSED — crash-recovery walk end-to-end PASS (see Part A) |
| Rev-1 residue scan (AtomicU64 / next_id / per saver instance) in live spec | CLEAN — no live-spec residue; all hits are audit-trail rows or different domain (semport) |
| VP-002 v1.1 "unique across the durable store" framing | VERIFIED — traceability section carries correct framing |
| ADR-005 §Alternatives Considered completeness | CLEAN — four alternatives (A/B/C/D) documented with rejection rationale |
| BC-2.04.004 fork lineage (unchanged) | VERIFIED — §Fork Lineage in ADR-005 unchanged; `CheckpointMetadata.parent_checkpoint_id` field intact |

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 2 (F-P115-01: verification-architecture + purity-boundary-map AtomicU64 residue; F-P115-02: interface-definitions missing `put` + `get_next_version`; BC obligations unsatisfiable) |
| MED | 0 |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **2** |

**CLEAN (strict):** no (2 HIGH findings)
**CLEAN (PR-merge):** no (2 HIGH findings)

**Convergence counter:** 0/3 (counter unchanged — pass 115 NOT CLEAN strict; fix burst 118 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** HIGH (F-P115-01 identifies a ripple-propagation failure class — ADR-005 rev-2 redesign required synchronous updates to verification-architecture and purity-boundary-map which were not included in fix burst 117; F-P115-02 identifies that a 3-method `CheckpointSaver` trait is structurally inadequate for 4 BCs and that `get_next_version` placement was adjudicated in ADR but not propagated to either `interface-definitions` or BC-2.04.003 PC1)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 115 |
| **New findings** | 2 |
| **Cleared axes** | F-P114-01 design correctness; rev-1 residue; VP-002 v1.1 framing; ADR-005 alternatives; BC-2.04.004 fork lineage |
| **Novelty score** | HIGH |
| **Median severity** | HIGH |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (2 HIGH; counter 0/3 unchanged; fix burst 118 dispatched; NEXT: pass 116 on new HEAD after fix burst 118) |
