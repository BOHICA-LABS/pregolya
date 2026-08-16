---
document_type: adversarial-review
level: ops
pass_id: P1D-178
pass_label: FULL-PERIMETER
frozen_head: 8708955
date: 2026-08-16
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-16T00:00:00Z"
phase: 1
pass: 178
previous_review: pass-177.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-178 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** 5 findings: 0C/1H/3M/1L. CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak: 0/3 unchanged. All findings were burst-288 partial-fix residue. 10 priority regression targets on burst-288 substantive fixes verified sound. 8 discard-class candidates (A:3, B:2, C:1, D:0, E:2). Frozen HEAD: post-burst-288 factory-artifacts HEAD `8708955`. This is pass #179 total.

## Finding ID Convention

Finding IDs use the format: `F-178-NN` for this pass (project-local shorthand consistent with P1D-177 pass convention). Canonical format per template: `ADV-P1CONV-P178-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-178 FULL-PERIMETER |
| Frozen HEAD | `8708955` |
| Date | 2026-08-16 |
| Pass total | 179 passes total in project history |
| Method | FULL-PERIMETER. All slices completed. 8 candidate findings discarded (A:3, B:2, C:1, D:0, E:2). |
| Scope | A: ARCH-INDEX, ADRs, architecture sections, VPs. B: BCs SS-01..SS-12 + BC-INDEX. C: BCs SS-13..SS-23. D: PRD, prd-supplements, 15 domain-spec shards, product-brief. E: policies.yaml, hooks, planning, comparative, semport, CI. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — UNCHANGED, do NOT advance** |

## Part A — Fix Verification

Burst-288 closed all findings from P1D-177. 10 priority regression targets were re-verified as CLEAN in this pass. See §Balance section below.

| Prior Finding | Status | Evidence |
|---------------|--------|---------|
| C-02 ADR-024 confinement proof unsound | RESOLVED | AS-01..AS-09 all caught; adversary probed 10th attack shape; all PC-1..PC-5 hold |
| C-01 BC-2.13.005 EC-003 vs ADR-024 contradiction | RESOLVED | BC-2.13.005 EC-003 (dangling-symlink → PathNotFound) matches ADR-024 PC-3 |
| E01 verify-error-notation-canon inverted routing | RESOLVED | Class-1 positive scanner rebuilt; routing correct |
| 60-finding slate (3C/20H/19M/18L-OBS) | PARTIALLY_RESOLVED — 5 residue findings remain (see Part B) | All substantive fixes verified sound; 5 partial-fix propagation misses found |

## Part B — New Findings

5 findings, all burst-288 partial-fix residue.

### HIGH

#### F-178-01 (HIGH) — StreamEvent count 15→16 propagation miss

- **Severity:** HIGH
- **Category:** spec-fidelity / sibling-sweep miss
- **Location:** interface-definitions.md §StreamEvent; product-brief.md; L2-INDEX.md; capabilities-p0.md; events.md (≥6 sites)
- **Description:** Burst-288 added StreamEvent::Error as the 16th variant in BC-2.06.001 §Postconditions PC2 but did not propagate the updated count to ≥6 sibling documents. A Phase-3 implementer building SSE serialization from interface-definitions would have shipped a 15-variant enum missing StreamEvent::Error, dropping the EC-005 failed-run terminal event entirely.
- **Evidence:** BC-2.06.001 §Postconditions PC2 reads 16 variants including StreamEvent::Error. interface-definitions.md §StreamEvent still reads 15 variants. Product-brief, L2-INDEX, capabilities-p0, events.md similarly stale.
- **Proposed Fix:** Architect/BA sweep — update variant count to 16 in all ≥6 documents. BC-2.06.001 §Postconditions PC2 is the single source of truth authority.

### MEDIUM

#### F-178-02 (MED) — ADR-024 §Consumers table stale citation status

- **Severity:** MEDIUM
- **Category:** spec-fidelity / stale-propagation
- **Location:** ADR-024 §Consumers table
- **Description:** Burst-288 revised ADR-024 extensively but left the §Consumers table's "Required Citation Status" column with 6 BCs marked MISSING (BC-2.13.001/002/003/004/005/006) even though all 6 now cite ADR-024. Additionally, BC-2.23.004 and BC-2.23.006 are absent from the consumer list; these WriteFile-adjacent BCs need confinement-proof coverage tracking.
- **Evidence:** ADR-024 §Consumers table rows for BC-2.13.001..006 show status MISSING; burst-288 edit log shows those BCs were updated to reference ADR-024.
- **Proposed Fix:** Architect — update 6 rows from MISSING to PRESENT; add BC-2.23.004/006 rows.

#### F-178-03 (MED) — ADR-023 phantom §-anchor `SS-06 §StreamEvent-Variants` (POL-47 irony)

- **Severity:** MEDIUM
- **Category:** spec-fidelity / phantom-anchor
- **Location:** ADR-023 body
- **Description:** ADR-023 was edited in burst-288. The edit re-introduced a phantom §-anchor reference `SS-06 §StreamEvent-Variants`. No such section heading exists in SS-06. StreamEvent variant enumeration lives in BC-2.06.001 §Postconditions PC2. A stale completed-handoff directive also remains in the body. POL-47 irony: ADR-023 governs phantom-anchor discipline yet its own burst-288 edit introduced a new phantom anchor.
- **Evidence:** `grep -n "StreamEvent-Variants" .factory/specs/architecture/decisions/ADR-023*.md` → hit. `grep -rn "StreamEvent-Variants" .factory/specs/domain-spec/` → no SS-06 section heading found.
- **Proposed Fix:** Architect — replace `SS-06 §StreamEvent-Variants` with `BC-2.06.001 §Postconditions PC2`; remove stale completed-directive.

#### F-178-04 (MED) — BC-2.10.003 phantom §-anchor `BC-2.03.001 §recursion_limit_canon` (3 sites)

- **Severity:** MEDIUM
- **Category:** spec-fidelity / phantom-anchor
- **Location:** BC-2.10.003 body (Invariants + 2 Postconditions entries)
- **Description:** Burst-288 edited BC-2.10.003 (v1.12). The edit introduced references to `BC-2.03.001 §recursion_limit_canon`. No such heading exists in BC-2.03.001 — the recursion-limit canon is in BC-2.03.001's Description prose, not a named heading. Three body sites carry this phantom anchor.
- **Evidence:** `grep -n "recursion_limit_canon" .factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md` → 3 hits. `grep -n "## recursion_limit_canon\|^# recursion_limit_canon" .factory/specs/behavioral-contracts/ss-03/BC-2.03.001.md` → 0 hits.
- **Proposed Fix:** Product-owner — replace `BC-2.03.001 §recursion_limit_canon` with `BC-2.03.001 Description` at all 3 sites; bump to v1.13.

### LOW

#### F-178-05 (LOW) — ADR-023 "17 original" enum subtotal label ambiguous

- **Severity:** LOW
- **Category:** ambiguous-language
- **Location:** ADR-023 §Decision count arithmetic section
- **Description:** ADR-023 references "17 original" enum variants as a subtotal label. After burst-288 renaming (Decision-4) and StreamEvent::Error addition, "17 original" is ambiguous — unclear whether pre-rename, post-rename, or pre-Error-addition. The count arithmetic summary (18 enums/19 structs/37 required/11 exempt) is correct; only the label is unclear.
- **Evidence:** ADR-023 §Decision "17 original" — no clarifying note.
- **Proposed Fix:** Architect — clarify label with explicit context, e.g., "17 variants before StreamEvent::Error addition in burst-288."

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 1 |
| **Total** | **5** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision (burst-289 fix-burst)

---

## Balance — Verified CLEAN Regression Targets

10 priority regression targets on burst-288's substantive fixes verified sound.

| Target | Result |
|--------|--------|
| ADR-024 confinement proof AS-01..AS-09 + 10th attack shape | CLEAN |
| C-01: BC-2.13.005/ADR-024 PC-3 agreement | CLEAN |
| E01 error-notation canon (Class-1 scanner not inverted) | CLEAN |
| StreamEvent-16 in BC-2.06.001/ADR-023 | CLEAN |
| ADR-023 count arithmetic (18/19/37/11) | CLEAN |
| ADR-023 Decision-4 rename (no orphaned citations) | CLEAN |
| bc-authoring-plan 23-row mapping | CLEAN |
| steps_remaining Option<i64> sweep | CLEAN |
| BC-2.12.003 interrupted→cancelled deadlock resolved | CLEAN |
| policies.yaml no fabricated citations | CLEAN |

**E03 REFUTED (3rd time):** No `enforcement_anchor` field exists in policies.yaml. Confirmed stable false-positive probe.

---

## Discard Summary

8 candidate findings discarded (A:3, B:2, C:1, D:0, E:2). All refutations — corpus evidence contradicted proposed findings in each case.

---

## Process-Gap Observations

### PG-178-01 — StreamEvent count-drift: second occurrence

F-178-01 is the 2nd StreamEvent count-propagation miss (D23 12→15 was the 1st). A count stated in ≥6 docs has no single-source-of-truth gate. Per-file changelog-claim gates are blind to cross-doc count drift. Proposal: lightweight grep-vs-BC-2.06.001 §Postconditions PC2 consistency advisory on SS-06 bursts.

### PG-178-02 — BC-target §anchors machine-unenforced

Phantom BC-body anchors (F-178-03, F-178-04) recur across bursts. verify-adr-anchor-citations.sh covers ADR-target anchors only. Two burst-288 edits minted new phantom BC-body anchors despite POL-47 active. Proposal: extend anchor-existence checking to BC/VP/CAP §target references (advisory hook candidate).

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 178 |
| **New findings** | 5 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 5/5 = 1.00 |
| **Median severity** | 3.0 (MED) |
| **Trajectory** | →256→189→160→60→5 |
| **Verdict** | FINDINGS_REMAIN |
