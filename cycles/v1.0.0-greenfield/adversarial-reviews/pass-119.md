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
pass: 119
previous_review: pass-118.md
---

# Adversarial Review: ferrochain (Pass 119)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 118 produced three findings:
- F-P118-01: bc-authoring-plan §12 lifecycle census gate mandates 3-member terminal set — actively reverts F-P117-01 fix; batch-table line 270 drifted
- F-P118-02: Sibling BCs (BC-2.12.004, BC-2.05.004, BC-2.05.005) carry 3-member terminal-set forms outside fix-burst-120 scope
- F-P118-03: entities-server v1.8 line 57 completed_at source cites BC-2.12.003 PC8(c)(d) instead of PC13

Fix burst 121 was dispatched (bc-authoring-plan v2.39→v2.40; BC-2.12.004 v1.2→v1.3; BC-2.05.004 v1.2→v1.3; BC-2.05.005 v1.3→v1.4; entities-server v1.8→v1.9). Verification follows.

### F-P118-01 through F-P118-03 Verification — ALL CLOSED

**PASS-119 sibling-checks verification (checks a–f from PASS-119 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) bc-authoring-plan v2.40 §12 canonical terminal-set is four-member `{completed, failed, cancelled, summary_halt}`; grep-verify examples updated verbatim; batch-table line 270 synced | PASS — bc-authoring-plan v2.40 §12 gate instruction reads `{completed, failed, cancelled, summary_halt}`; grep-verify command updated; batch-table line 270 updated to match |
| (b) BC-2.12.004 v1.3 PC2b lifecycle arrow reads `completed \| failed \| cancelled \| summary_halt`; Related BCs §BC-2.12.003 description is four-member `(queued/in_progress/completed/failed/interrupted/cancelled/summary_halt)` | PASS — PC2b updated; Related BCs description four-member |
| (c) BC-2.05.004 v1.3 Invariants non-interrupted status guard includes `summary_halt`: `'(status queued, in_progress, completed, failed, cancelled, or summary_halt) returns Err(E-GRAPH-002 NoActiveInterrupt)'` | PASS — line 99-100 reads all six non-interrupted statuses correctly |
| (d) BC-2.05.005 v1.4 Related BCs §BC-2.12.003 description is four-member (lifecycle list); VP-HITL-10 reads "five non-interrupted terminal/running states" and parameterized list includes `summary_halt` | PASS (scope-limited) — Related BCs lifecycle reference updated to four-member; VP-HITL-10 text updated to "five non-interrupted terminal/running states" and parameterized list adds `summary_halt`; sibling-check (d) PASSES. See F-P119-01 for deeper within-BC gap found during this pass |
| (e) entities-server v1.9 line 57 completed_at Source reads `"F-P24-01, BC-2.12.003 PC13, BC-2.10.003 PC8(c)(d)"` | PASS — entities-server v1.9 line 57 corrected as required |
| (f) Independent corpus-wide grep: `rg "completed.*failed.*cancelled" specs/ --type=md` excluding changelog rows, ADR alternatives tables, and concrete TV single-value transition sequences — zero non-exempt 3-member hits | PASS — zero non-exempt 3-member terminal-set hits confirmed corpus-wide; summary_halt enumeration tail fully propagated from the fix-burst-121 scope |

**F-P118-01 conclusion:** CLOSED — bc-authoring-plan v2.40 §12 gate now mandates the correct four-member terminal set. Revert-risk eliminated.
**F-P118-02 conclusion:** CLOSED — BC-2.12.004 v1.3, BC-2.05.004 v1.3, BC-2.05.005 v1.4 all carry `summary_halt` in their enumeration sites within sibling-check scope.
**F-P118-03 conclusion:** CLOSED — entities-server v1.9 line 57 completed_at citation corrected to BC-2.12.003 PC13 + BC-2.10.003 PC8(c)(d).
**Corpus-wide sweep (check f):** CONCURS — zero non-exempt 3-member hits. The summary_halt enumeration tail is closed corpus-wide.

**BC-2.05.005 v1.4 deeper sweep (prompted by check (d) deeper inspection):**

While confirming check (d), this pass read BC-2.05.005 v1.4 Preconditions §2 directly, finding a within-BC PC↔VP contradiction. See F-P119-01 below.

---

## Part B — New Findings

### F-P119-01 — MED: BC-2.05.005 v1.4 Preconditions §2, Description, and Test Vectors Missing `summary_halt` Guard — Within-BC PC↔VP Contradiction

**Severity:** MED
**Scope:** `specs/behavioral-contracts/ss-05/BC-2.05.005.md` (v1.4 at pass-119 time) — Preconditions §2, Description first paragraph, Canonical Test Vectors

#### Evidence

**Per-site status-enumeration sweep table for BC-2.05.005 v1.4:**

| Site | Enumerated Run Statuses | `summary_halt` Present? | Notes |
|------|------------------------|------------------------|-------|
| Preconditions §2, clauses a-d | `completed` (a), `failed` (b), `in_progress` (c), `interrupted`/slots-consumed (d) | **NO** | Guards only 4 cases; `summary_halt` established as first-class terminal by F-P117-01 |
| Description, first paragraph | "completed, failed, still running (`in_progress`), or all prior interrupts have already been consumed" | **NO** | Description prose omits `summary_halt` |
| Canonical Test Vectors | TV-001 (`completed`), TV-002 (`completed` slots-consumed), TV-003 (`completed` endpoint), TV-004 (`in_progress`), TV-005 (`failed`) | **NO** | No TV for `summary_halt` guard case; VP-HITL-10 parameterized list included it but no corresponding TV row |
| VP-HITL-10 parameterized list | "five non-interrupted terminal/running states: `completed`, `failed`, `in_progress`, `summary_halt`, … plus the interrupted-slots-consumed scenario" | **YES** | Added in fix burst 121 (v1.4); VP-HITL-10 is the contract authority for this test but Preconditions §2 is the BC normative body |
| Related BCs §BC-2.12.003 lifecycle reference | `queued/in_progress/completed/failed/interrupted/cancelled/summary_halt` | YES | This is a non-normative lifecycle reference (informational); not a guard predicate |

**Contradiction:** VP-HITL-10 mandates "five non-interrupted terminal/running states" including `summary_halt`, but Preconditions §2 — the normative guard body — lists only 4 cases with no `summary_halt` clause. The test vector inventory does not include a `summary_halt` guard TV. A test-writer implementing VP-HITL-10 against BC-2.05.005 v1.4 would need to derive the `summary_halt` case from VP-HITL-10 alone, with no Preconditions anchor — fragile and ungrounded.

**Census-sweep table (corpus-wide run_status non-interrupted guard enumerations; historical archives exempt; HTTP-status 503/504 hits exempt):**

| File | Guard Site | Enumerates `summary_halt`? | Notes |
|------|-----------|---------------------------|-------|
| BC-2.05.004 v1.3 Invariants line 99-100 | non-interrupted status guard | YES | Correctly includes all 6 non-interrupted statuses |
| BC-2.05.005 v1.4 Preconditions §2 | primary guard body | **NO** | F-P119-01 — normative body disagrees with VP-HITL-10 |
| BC-2.12.003 v1.4 PC8 | terminal set | YES | Four-member {completed,failed,cancelled,summary_halt} |
| BC-2.12.004 v1.3 PC2b | lifecycle arrow | YES | Includes `summary_halt` |
| All other non-interrupted guard enumerations | (no other sites enumerate a non-interrupted status guard) | n/a | Corpus clean |

**Root cause:** Fix burst 121 scope for BC-2.05.005 v1.4 was limited to Related BCs lifecycle reference and VP-HITL-10 text (the two sites identified in PASS-118 F-P118-02 finding description). Preconditions §2 — the normative guard body — was not in the v1.4 touch scope. The VP-HITL-10 update introduced "summary_halt" into the test contract but the normative Preconditions §2 was not updated in the same burst.

**Impact:** MED — the within-BC contradiction is confined to BC-2.05.005. BC-2.05.004 Invariants already correctly enumerate all six non-interrupted statuses and delegate to BC-2.05.005. A test-writer generating tests for BC-2.05.005 would produce a VP-HITL-10-compliant test for `summary_halt` but cannot anchor it to any Preconditions clause. At Phase 3 this would surface as an ungrounded test case.

---

### OBS-1 — Delegation Gap: `queued` and `cancelled` Absent from BC-2.05.005 Preconditions §2

**Severity:** OBS (folded — adjudication pending)
**Scope:** `specs/behavioral-contracts/ss-05/BC-2.05.005.md` v1.4 Preconditions §2

**Observation:** BC-2.05.004 v1.3 Invariants (lines 99-101) enumerate six non-interrupted statuses: `queued, in_progress, completed, failed, cancelled, summary_halt`. All six are delegated to BC-2.05.005. However, BC-2.05.005 v1.4 Preconditions §2 guards only four cases: `completed` (a), `failed` (b), `in_progress` (c), and `interrupted`/slots-consumed (d). The `queued` and `cancelled` statuses — both confirmed non-interruptible by domain reasoning — are not covered by any Preconditions clause.

**Domain reasoning for `queued`:** A `queued` run has not yet started executing — no node has run, so no interrupt slot can have been created. A spurious `Command(resume=)` against a `queued` run must fail with `Err(E-GRAPH-002 NoActiveInterrupt)`.

**Domain reasoning for `cancelled`:** A `cancelled` run had any in-flight interrupt slots discarded at cancellation time. No valid un-consumed interrupt slot remains. A spurious `Command(resume=)` must fail.

**Adjudication intent:** Recommend production-grade totality — BC-2.05.005 guard is a complete predicate over ALL non-interrupted run_status values. BC-2.05.004 Invariants already enumerate six statuses and delegate all six to BC-2.05.005. Both BCs should be coherent. Totality preference over delegation narrowing eliminates ambiguity for test-writers and engine implementers.

---

### OBS-2 — VP-HITL-10 Count Imprecision: "Five States" Does Not Derive Cleanly from Preconditions §2

**Severity:** OBS (folded — adjudication pending)
**Scope:** `specs/behavioral-contracts/ss-05/BC-2.05.005.md` v1.4 VP-HITL-10

**Observation:** VP-HITL-10 reads: "Unit test (parameterized over the five non-interrupted terminal/running states: `completed`, `failed`, `in_progress`, `summary_halt`, …; plus the interrupted-slots-consumed scenario (PC2(d)/TV-002) — 6 total parameterized test cases)".

The "five" count is not derivable from Preconditions §2 (which only lists 4 cases in v1.4). More importantly, `queued` and `cancelled` are also valid non-interrupted statuses (per OBS-1) but are not in the "five" enumeration. After OBS-1 adjudication adds `queued` and `cancelled`, the total becomes 7 (6 non-interrupted statuses + 1 slots-consumed scenario), not 6.

**Adjudication intent:** Rewrite VP-HITL-10 to derive its count from the complete guard set once OBS-1 is resolved: "six non-interrupted run_status values (`completed`, `failed`, `in_progress`, `summary_halt`, `queued`, `cancelled`) plus the interrupted-slots-consumed scenario (PC2(d)/TV-002) — 7 total parameterized test cases". The count must be derivable from first principles via Preconditions §2 alone.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 (F-P119-01: BC-2.05.005 v1.4 Preconditions §2 guard body missing `summary_halt` clause — within-BC PC↔VP contradiction with VP-HITL-10 which mandates "five non-interrupted states" including `summary_halt`; no TV-006 for `summary_halt` guard case) |
| LOW | 0 |
| OBS | 2 (folded: OBS-1 — `queued` and `cancelled` also absent from Preconditions §2 guard, delegation gap vs BC-2.05.004; OBS-2 — VP-HITL-10 "five states" count imprecise once OBS-1 resolved) |
| **Total findings** | **1 (+ 2 OBS folded)** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision

**CLEAN (strict):** no (1 MED finding)
**CLEAN (PR-merge):** no (1 MED finding)

**Convergence counter:** 0/3 (counter unchanged — pass 119 NOT CLEAN strict; fix burst 122 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** MEDIUM (F-P119-01 is a VP-updated-without-PC§2-update class — within-BC PC↔VP contradiction; first occurrence of this pattern in Phase 1d cascade; OBS-1/OBS-2 are delegation-gap and count-imprecision observations adjudicated as production-grade totality requirement)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 119 |
| **New findings** | 1 (F-P119-01 MED) + 2 OBS (folded) |
| **Cleared axes** | F-P118-01/02/03 ALL CLOSED; corpus-wide grep CONCURS zero non-exempt 3-member terminal-set hits |
| **Novelty score** | MEDIUM — new within-BC PC↔VP gap class (VP updated without normative body update in same burst); OBS-1/OBS-2 are related delegation-gap and count-imprecision observations |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1 MED; counter 0/3 unchanged; fix burst 122 dispatched; NEXT: pass 120 on new HEAD after fix burst 122) |
