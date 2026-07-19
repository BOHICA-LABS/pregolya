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
pass: 118
previous_review: pass-117.md
---

# Adversarial Review: ferrochain (Pass 118)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 117 produced one HIGH finding:
- F-P117-01: `summary_halt` absent from BC-2.12.003 PC7/PC8/PC13/PC18/PC19 and Output Invariant, interface-definitions v2.37 Run Object Schema, and entities-server v1.7 RunStatus lifecycle — SS-10↔SS-12 cross-subsystem contradiction

Fix burst 120 was dispatched (Option 1 adjudication — `summary_halt` is a first-class terminal Run status). Verification follows.

### F-P117-01 Verification — CLOSED (8-file touch set); Corpus-Wide Sweep (f) FAILED

**8-file touch set verification (checks a–e from PASS-118 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) `summary_halt` present in all status enumerations of the 8 touched files: BC-2.12.003 v1.4 seven sites (PC7 arc, PC8 terminal set, PC13 completed_at, PC18 filter, PC19 deletable, Output Invariant, Description); BC-2.12.006 v1.2 PC7 RunStore transition list; BC-2.06.001 v1.4 EC-005 RunEnd rule; interface-definitions v2.38 six sites (status enum, status desc, completed_at, output note, GET filter, DELETE desc); entities-server v1.8 RunStatus lifecycle + completed_at semantics; ubiquitous-language-server v1.3 Run lifecycle prose | PASS — all 8 files carry `summary_halt` in every relevant enumeration site |
| (b) H1↔BC-INDEX↔prd.md title sync for BC-2.12.003 — all three must read "completed/failed/cancelled/summary_halt" | PASS — BC-2.12.003 H1 reads "Run Lifecycle State Machine (queued/in_progress/completed/failed/interrupted/cancelled/summary_halt)"; BC-INDEX row updated; prd.md line 281 title updated |
| (c) Output invariant coherent with BC-2.10.003 PC8(c): output populated when status ∈ {completed, summary_halt} | PASS — BC-2.12.003 v1.4 Output Invariant reads "Run output (`output`) is populated only when `status ∈ {completed, summary_halt}`"; coherent with BC-2.10.003 PC8(c) mandate |
| (d) `summary_halt` semantics table coherent: not cancellable (→ PC12 returns HTTP 409 if already terminal); directly deletable (→ PC19); `completed_at` set; RunEnd emitted | PASS — BC-2.12.003 v1.4 PC12/PC13/PC18/PC19 + BC-2.06.001 v1.4 EC-005 collectively verify all four semantic properties |
| (e) Grep 8 touched files for 3-element terminal-set assertions {completed, failed, cancelled} without `summary_halt` in non-changelog live content | PASS — zero 3-member terminal-set hits across the 8-file touch scope after fix burst 120 |

**Corpus-wide extension sweep:**

| Check | Result |
|-------|--------|
| (f) Adversary-initiated corpus-wide grep `rg "completed.*failed.*cancelled" specs/ --type=md` (excluding changelog rows, ADR alternatives tables, and pure-concrete TV fields) — must yield 0 hits for any 3-member terminal-set assertion missing `summary_halt` in non-exempt live content | FAIL — 3 BCs carry 3-member terminal-set forms outside the fix burst 120 scope: BC-2.12.004 lines 70+163 (cron-fired lifecycle arrow + Related BCs description); BC-2.05.004 lines 99–100 (invariant non-interrupted status guard); BC-2.05.005 line 137 (Related BCs `BC-2.12.003` description cites old 3-member form) |

**Root cause:** fix burst 120 sweep was scoped to the 8 files that directly carry the Run state machine authority (BC-2.12.003, BC-2.12.006, BC-2.06.001, interface-definitions, entities-server, ubiquitous-language-server, prd.md, BC-INDEX). Sibling BCs in ss-05 and ss-12 that reference the Run lifecycle by enumeration were not in scope. The bc-authoring-plan §12 lifecycle census gate also mandated the old 3-member set — a process-gap propagation miss that would actively mandate reverting the fix if the gate were run. Raises F-P118-01 [process-gap] and F-P118-02 [sibling propagation].

**Additional spot-check:**

| Axis | Disposition |
|------|-------------|
| entities-server v1.8 completed_at source citation (line 57) | FINDING — line 57 cites "F-P24-01, BC-2.12.003 PC8(c)(d)" for completed_at semantics; correct clause for completed_at is BC-2.12.003 PC13 (not PC8); BC-2.10.003 PC8(c)(d) is the OnCeiling::Summarize → summary_halt path (separate subsystem); adjacent updated_at line already correctly cites PC13. Raises F-P118-03 |
| `summary_halt` NOT cited in bc-authoring-plan §12 lifecycle census gate example/assertion (only §12 canonical terminal-set forms checked against bc-authoring-plan as a gate target — bc-authoring-plan body) | See F-P118-01 — §12 gate mandates 3-member set; batch-table line 270 drifted |

**F-P117-01 conclusion:** CLOSED for the 8-file touch set (all checks a–e PASS). Corpus-wide sweep check (f) FAILED — raises F-P118-01 [process-gap] and F-P118-02 [sibling propagation]. Entities-server citation spot-check raises F-P118-03.

---

## Part B — New Findings

### F-P118-01 — HIGH [process-gap]: bc-authoring-plan §12 Lifecycle Census Gate Mandates 3-Member Terminal Set — Actively Reverts F-P117-01 Fix; Batch-Table Line 270 Drifted

**Severity:** HIGH [process-gap]
**Scope:** `specs/prd-supplements/bc-authoring-plan.md` (v2.39 at pass-118 time) §12 lifecycle census gate definition and batch-table at line ~270

#### Evidence

bc-authoring-plan v2.39 §12 (`## §12 — Run Lifecycle Census and Terminal-Set Consistency`) contains the gate enforcement instruction that future adversary passes use to verify Run terminal-set consistency. At pass-118 time, the §12 gate canon reads something to the effect of:

```
Canonical terminal set: {completed, failed, cancelled}
Gate instruction: grep for any enumeration of the terminal set;
  assert each contains exactly these three members.
```

After fix burst 120 adjudicated `summary_halt` as a first-class terminal Run status (F-P117-01, Option 1), the canonical terminal set is `{completed, failed, cancelled, summary_halt}` — four members. The §12 gate definition was NOT updated to reflect this adjudication.

**Consequence 1 — Revert risk:** If any adversarial pass after burst 120 runs the §12 gate as written, it will assert that the now-correct four-member terminal set in BC-2.12.003 v1.4 PC8 is NON-CONFORMANT (because the gate requires exactly three members). The gate would then mandate a "fix" that reverts BC-2.12.003 PC8, BC-2.12.004, BC-2.05.004, and BC-2.05.005 back to the old three-member form, undoing the F-P117-01 adjudication entirely.

**Consequence 2 — Grep-verify mismatch:** The §12 grep-verify examples embedded in the gate also use the three-member pattern. Future automation (DEFER-002 enforcement) would false-flag all correctly-updated four-member enumerations.

**Batch-table drift:** bc-authoring-plan contains a batch-table (line ~270 at pass-118 time) that enumerates Run terminal statuses as part of a multi-BC consistency check summary. This row was also not updated to include `summary_halt`, leaving a data-level mismatch between the table and the current BC-2.12.003 v1.4 canonical definition.

**Failure Mode:**
| Trigger | Impact |
|---------|--------|
| Future adversary runs §12 gate verbatim against BC-2.12.003 v1.4 PC8 {completed,failed,cancelled,summary_halt} | Gate reports FAIL; adversary opens a HIGH finding; fix burst reverts BC-2.12.003 PC8 to 3-member; cascade of sibling revert fixes follows |
| DEFER-002 CI lint uses §12 grep-verify pattern | CI flags all four-member terminal-set enumerations as non-conformant; blocks PRs with correct four-member forms |

**Fix burst 121 dispatched** (PO: bc-authoring-plan §12 canonical terminal-set updated to four-member {completed, failed, cancelled, summary_halt}; grep-verify examples updated; batch-table line 270 synced verbatim).

---

### F-P118-02 — HIGH: Sibling Propagation — Three Sibling BCs Carry 3-Member Terminal-Set Enumerations After F-P117-01 Fix; summary_halt Absent

**Severity:** HIGH
**Scope:** `specs/behavioral-contracts/ss-12/BC-2.12.004.md` (v1.2 at pass-118 time) lines 70 and 163; `specs/behavioral-contracts/ss-05/BC-2.05.004.md` (v1.2 at pass-118 time) lines 99–100; `specs/behavioral-contracts/ss-05/BC-2.05.005.md` (v1.3 at pass-118 time) line 137

#### Evidence

**BC-2.12.004 — Cron-Run Lifecycle, lines 70 and 163:**

At pass-118 time, BC-2.12.004 describes the lifecycle of cron-fired Runs. Because each cron-fired Run IS a Run (it follows the standard Run state machine per BC-2.12.003), the lifecycle description must reflect the canonical terminal set.

- **Line 70 (PC2b lifecycle arrow):** `queued → in_progress → completed | failed | cancelled` — three-member terminal set. `summary_halt` absent. A cron-fired Run that hits `OnCeiling::Summarize` reaches `summary_halt` per BC-2.10.003 PC8(c)(d), but the cron BC's own lifecycle arrow does not acknowledge this.

- **Line 163 (Related BCs §BC-2.12.003 description):** States that the cron BC "depends on" BC-2.12.003 for `completed | failed | cancelled` lifecycle — again three-member, missing `summary_halt`. This is directly inconsistent with BC-2.12.003 v1.4.

**BC-2.05.004 — Command Resume Invariant, lines 99–100:**

At pass-118 time, BC-2.05.004 contains the invariant: "A `Command` submitted to a non-interrupted run (status `queued`, `in_progress`, `completed`, `failed`, or `cancelled`) returns `Err(E-GRAPH-002 NoActiveInterrupt)`." The status list enumeration at lines 99–100 omits `summary_halt`. A Run in `summary_halt` is non-interrupted and is a terminal state — submitting a `Command` resume to it must also return `E-GRAPH-002 NoActiveInterrupt`, but the BC-2.05.004 invariant as written does not include this case. An implementer reading BC-2.05.004 could fail to guard the `summary_halt` path, allowing a resume attempt on a terminated summarize run to proceed.

**BC-2.05.005 — Related BCs section, line 137:**

At pass-118 time, BC-2.05.005 §Related BCs describes BC-2.12.003 as governing "run lifecycle states (queued/in_progress/completed/failed/interrupted/cancelled)" — six members, missing `summary_halt`. VP-HITL-10 also reads "four non-interrupted states" (parameterized list for the `E-GRAPH-002 NoActiveInterrupt { run_status }` error-carrying states), which is incorrect: after F-P117-01 the count is five (completed/failed/in_progress/summary_halt/slot-exhausted).

#### Failure Mode Table

| BC | Site | Trigger | Impact |
|----|------|---------|--------|
| BC-2.12.004 | Line 70 PC2b | Phase 3 implementer writes cron-run state machine from BC-2.12.004 | `summary_halt` transition absent from cron-run lifecycle; cron runs hitting `OnCeiling::Summarize` transition to undefined state or remain `in_progress` indefinitely |
| BC-2.12.004 | Line 163 Related BCs | Consistency validator sweeps cron BC vs Run BC | Validator sees BC-2.12.004 cites {completed,failed,cancelled} while BC-2.12.003 v1.4 defines {completed,failed,cancelled,summary_halt}; false-positive finding raised even though BC-2.12.003 is the authority |
| BC-2.05.004 | Lines 99–100 | Phase 3 implementer writes `E-GRAPH-002 NoActiveInterrupt` guard | Guard for `summary_halt` missing; resume call on a `summary_halt` Run proceeds to attempt to resume a terminated run |
| BC-2.05.005 | Line 137 VP-HITL-10 | Phase 3 test-writer counts expected `run_status` variants for VP-HITL-10 parameterized test | Test writer uses count "four" → generates 4-variant test instead of 5-variant test; `summary_halt` variant dropped from VP-HITL-10 parameterized test suite |

**Fix burst 121 dispatched** (PO: BC-2.12.004 v1.2→v1.3 PC2b lifecycle arrow +summary_halt + Related BCs description; BC-2.05.004 v1.2→v1.3 invariant status list +summary_halt; BC-2.05.005 v1.3→v1.4 Related BCs description +summary_halt + VP-HITL-10 "four"→"five").

---

### F-P118-03 — MED: entities-server Line 56 — completed_at Source Cites BC-2.12.003 PC8(c)(d) but Correct Clause is BC-2.12.003 PC13; PC8(c)(d) Belongs to BC-2.10.003

**Severity:** MED
**Scope:** `specs/domain-spec/entities-server.md` (v1.8 at pass-118 time) line 56

#### Evidence

At pass-118 time, entities-server v1.8 line 57 (`completed_at semantics`) reads:

```
- **completed_at semantics:** Set only on terminal transition (to `completed`, `failed`, `cancelled`,
  or `summary_halt`); `None` in non-terminal states (`queued`, `in_progress`, `interrupted`).
  Operationally distinct from updated_at — provides a clean terminal-timestamp without noise
  from intermediate mutations. Source: F-P24-01, BC-2.12.003 PC8(c)(d).
```

**Error:** `BC-2.12.003 PC8(c)(d)` is the wrong citation for `completed_at` semantics.

- **BC-2.12.003 PC13** is the correct clause governing `completed_at`: it defines the terminal-state set that triggers `completed_at` assignment (`completed`, `failed`, `cancelled`, and, after F-P117-01, `summary_halt`). The adjacent `updated_at semantics` line on line 56 already correctly cites `BC-2.12.003 PC13`.

- **BC-2.12.003 PC8(c)(d)** does not exist as lettered sub-clauses in BC-2.12.003. PC8 in BC-2.12.003 defines the terminal state SET. There are no PC8(c) or PC8(d) lettered sub-points within that BC — that lettered notation (`PC8(c)`, `PC8(d)`) belongs to **BC-2.10.003** (the BudgetPolicy subsystem), where PC8(c) mandates the summarize LLM call on `OnCeiling::Summarize` and PC8(d) asserts the resulting Run status is `summary_halt`.

The mis-citation creates an ambiguity: a reader looking up `BC-2.12.003 PC8(c)(d)` to understand `completed_at` behavior will not find the cited sub-clauses (they don't exist in that BC), and the citation conflates two different contracts — the Run state machine (SS-12) with the budget policy path (SS-10).

**Adjacent line 58** in entities-server v1.8 correctly cites `BC-2.10.003 PC8(c)(d)` for the `summary_halt` state-machine authority note. The correct form for `completed_at` semantics is to cite both `BC-2.12.003 PC13` (the clause governing completed_at assignment) AND `BC-2.10.003 PC8(c)(d)` (the authority for `summary_halt` as one of the triggering terminals).

**Failure Mode:**
| Trigger | Impact |
|---------|--------|
| Reviewer looks up `BC-2.12.003 PC8(c)(d)` to verify `completed_at` semantics | Cannot find lettered sub-clauses; citation appears broken; reviewer cannot verify correctness; may incorrectly conclude `completed_at` is not anchored |
| Consistency validator sweeps entities-server `completed_at` source citation against BC-2.12.003 | Finds `PC8(c)(d)` notation absent in BC-2.12.003; raises false BC-anchor finding; OR conflates SS-10 and SS-12 authority |

**Fix burst 121 dispatched** (BA: entities-server v1.8→v1.9 line 57 — `completed_at` Source changed from `"F-P24-01, BC-2.12.003 PC8(c)(d)"` to `"F-P24-01, BC-2.12.003 PC13, BC-2.10.003 PC8(c)(d)"`; TD-VSDD-060 sweep confirmed no other BC-2.12.003 PC8(c)(d) conflations in entities-server.md).

---

## Full Closure-Grep Table (Fix Burst 121)

Corpus-wide sweep for 3-member terminal-set assertions after fix burst 121. Exempt categories: (1) gate-instruction prose describing the gate-detection pattern itself, (2) error-struct transition-value fields in concrete TV rows (specific concrete status, not a set enumeration), (3) execution-path sequences showing a SPECIFIC transition chain (e.g., "in_progress → completed" per an execution trace, not a set membership list).

| File | Pattern Hit | Disposition |
|------|-------------|-------------|
| bc-authoring-plan.md §12 gate canonical forms | FIXED — four-member {completed,failed,cancelled,summary_halt} | CLOSED |
| bc-authoring-plan.md §12 grep-verify examples | FIXED — updated to match four-member forms | CLOSED |
| bc-authoring-plan.md batch-table line ~270 | FIXED — synced verbatim with four-member terminal set | CLOSED |
| BC-2.12.004 line 70 PC2b lifecycle arrow | FIXED — `completed \| failed \| cancelled \| summary_halt` | CLOSED |
| BC-2.12.004 line 163 Related BCs §BC-2.12.003 description | FIXED — four-member form | CLOSED |
| BC-2.05.004 lines 99–100 invariant status list | FIXED — `summary_halt` added to non-interrupted guard | CLOSED |
| BC-2.05.005 line 137 Related BCs description | FIXED — four-member form | CLOSED |
| BC-2.05.005 VP-HITL-10 | FIXED — "four"→"five non-interrupted terminal/running states" | CLOSED |
| entities-server.md line 57 completed_at Source | FIXED — `BC-2.12.003 PC13, BC-2.10.003 PC8(c)(d)` | CLOSED |
| All other non-exempt corpus sites | ZERO non-exempt 3-member hits — confirmed by adversary sweep | CLEAN |

---

## Cleared Candidates

| Axis | Disposition |
|------|-------------|
| F-P117-01 8-file touch set (BC-2.12.003, BC-2.12.006, BC-2.06.001, interface-definitions, entities-server, ubiquitous-language-server, prd.md, BC-INDEX) | CLOSED — all enumeration sites carry `summary_halt`; output invariant, completed_at, BC-INDEX, prd.md title all correct; see Part A checks (a)–(e) |
| `summary_halt` semantics coherent: not cancellable; directly deletable; completed_at set; RunEnd emitted | CLEAN — BC-2.12.003 v1.4 PC12/PC13/PC18/PC19 + BC-2.06.001 v1.4 EC-005 all verify correctly |
| BC-2.10.003 PC8(c)(d) authority for OnCeiling::Summarize → summary_halt path | CLEAN — unchanged by fix burst 120; PC8(c)(d) remains correct at BC-2.10.003 |
| VP-HITL-10 count coherent (raised as sibling check in PASS-118 checklist) | FINDING — VP-HITL-10 "four" count resolved as F-P118-02; fixed in burst 121 to "five" |

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 2 (F-P118-01 [process-gap]: bc-authoring-plan §12 gate mandated 3-member terminal set — would actively revert F-P117-01 adjudication; batch-table line 270 drifted; F-P118-02: sibling propagation miss — BC-2.12.004 lines 70+163 + BC-2.05.004 lines 99–100 + BC-2.05.005 line 137 carry 3-member terminal-set forms inconsistent with BC-2.12.003 v1.4) |
| MED | 1 (F-P118-03: entities-server line 57 completed_at Source mis-cites BC-2.12.003 PC8(c)(d) — correct is BC-2.12.003 PC13; PC8(c)(d) notation belongs to BC-2.10.003) |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **3** |

**CLEAN (strict):** no (2 HIGH + 1 MED findings)
**CLEAN (PR-merge):** no (2 HIGH + 1 MED findings)

**Convergence counter:** 0/3 (counter unchanged — pass 118 NOT CLEAN strict; fix burst 121 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** HIGH (F-P118-01 is a process-gap that would actively REVERT the F-P117-01 adjudication — a gate definition attacking its own fix; F-P118-02 reveals the burst-120 scope was insufficient for sibling BCs not in the 8-file touch set)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 118 |
| **New findings** | 3 |
| **Cleared axes** | F-P117-01 8-file touch set CLOSED; summary_halt semantics table coherent; BC-2.10.003 PC8(c)(d) authority CLEAN |
| **Novelty score** | HIGH |
| **Median severity** | HIGH |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (2 HIGH + 1 MED; counter 0/3 unchanged; fix burst 121 dispatched; NEXT: pass 119 on new HEAD after fix burst 121) |
