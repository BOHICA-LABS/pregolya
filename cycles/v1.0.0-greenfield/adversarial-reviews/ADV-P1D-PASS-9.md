---
document_type: adversarial-review
pass: 9
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
open_findings: 2
timestamp: 2026-07-14T00:00:00Z
trajectory: "14→5→7→13→3→3→3→5→2"
counter_clean: 0
counter_clean_needed: 3
---

# ADV-P1D PASS-9: Adversarial Review — Phase 1d

**Verdict: NOT CLEAN — 2 findings (1 HIGH, 1 LOW)**

## Findings

### F-P9-01 (HIGH): BC-INDEX DI Anchors column and plan/prd DI tables omit enforcing BCs

**Scope:** BC-INDEX DI Anchors column; bc-authoring-plan.md DI Invariant Enforcement Coverage table; prd.md Section 2 BC catalog and Section 7 RTM Source column.

**Root cause:** The pass-8 batch of BC-INDEX fixes correctly added DI anchors to several BCs but missed: all 6 ss-11 BCs (DI-012), all 6 ss-13 BCs (DI-006/DI-007), and BC-2.13.006 in the plan DI-006 row. Additional full-census sweep found further omissions in the plan/RTM tables (see reconciliation below).

**Affected artifacts (BC-INDEX DI Anchors column before fix):**
- BC-2.05.005: missing DI-003
- BC-2.09.004, BC-2.09.005: missing DI-014
- BC-2.11.001–BC-2.11.006: missing DI-012 (6 BCs)
- BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.006: missing DI-006
- BC-2.13.004, BC-2.13.005: missing DI-007

**Plan (bc-authoring-plan.md) DI table before fix:** DI-001 missing BC-2.17.001; DI-003 missing BC-2.05.005/006/010.004; DI-005 missing BC-2.17.001; DI-006 missing BC-2.13.006; DI-007 missing BC-2.17.001; DI-008 missing BC-2.08.006/010; DI-009 missing BC-2.08.007; DI-011 missing BC-2.08.001; DI-012 missing BC-2.09.003; DI-014 missing BC-2.09.004/005.

**Status: FIXED in this pass** (see reconciliation table below).

---

### F-P9-02 (LOW): BC-2.08.009 has empty input-hash field

**File:** `.factory/specs/behavioral-contracts/ss-08/BC-2.08.009.md`

**Defect:** Frontmatter field `input-hash: ""` — never populated when batch 13 BCs (BC-2.08.009–012) were created. BC-2.08.010/011/012 had their hashes filled as NF-04 in Phase 1 spec crystallization; BC-2.08.009 was skipped.

**Status: FIXED in this pass.** Computed per documented convention (sha256 of each input file content sorted alphabetically by path, then sha256 of the manifest of `path:sha256` lines).

Computed hash: `96fc00a51eb0520c18f63f083f70e76801db9a793eb520b79a51a688b1c3d608`

**Evidence:** `grep -c 'input-hash: ""' specs/behavioral-contracts/ss-08/BC-2.08.009.md` → 0

---

## Sibling Checks (5/5 PASS)

| Check | Result |
|-------|--------|
| BC-INDEX total count == 86 | PASS |
| All BC files present in ss-NN dirs | PASS |
| VP-INDEX registration (VP-001–005) | PASS |
| Red Gate BCs (5) complete | PASS |
| Kani VP seed BCs (BC-2.03.001, BC-2.04.006, BC-2.13.004) | PASS |

---

## Re-Verified Axes (3 of 5 re-checked)

| Axis | Result |
|------|--------|
| BC-body precondition/postcondition completeness (sample 10 BCs) | CLEAN |
| Capability Anchor Justification presence (sample 10 BCs) | CLEAN |
| DI-anchoring across all 86 BCs → BC-INDEX → plan → prd RTM | F-P9-01 (FIXED) |

---

## BC-Body Coverage

**86/86 BCs scanned (100%)** — full-census grep for `L2 Domain Invariants` row in all BC Traceability tables.

---

## Full-Census DI→BC Reconciliation Table

Three-way comparison: (1) BC body `L2 Domain Invariants` rows, (2) BC-INDEX DI Anchors column, (3) bc-authoring-plan.md DI Invariant Enforcement Coverage table + prd.md RTM Source column.

**After fixes in this pass — all 14 DIs exact 3-way match:**

| DI | Body-Census BCs | BC-INDEX (after fix) | Plan/RTM (after fix) | Match? |
|----|-----------------|---------------------|----------------------|--------|
| DI-001 | BC-2.02.002, BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.17.001 | BC-2.02.002 ✓, BC-2.03.001 ✓, BC-2.03.002 ✓, BC-2.03.003 ✓, BC-2.17.001 ✓ | Same 5 ✓ | MATCH |
| DI-002 | BC-2.04.001, BC-2.04.002, BC-2.04.005 | same 3 ✓ | same 3 ✓ | MATCH |
| DI-003 | BC-2.05.001–006, BC-2.10.004 | same 7 ✓ (BC-2.05.005 DI-003 added) | same 7 ✓ | MATCH |
| DI-004 | BC-2.04.003, BC-2.04.004 | same 2 ✓ | same 2 ✓ | MATCH |
| DI-005 | BC-2.04.006, BC-2.17.001 | same 2 ✓ | same 2 ✓ (BC-2.17.001 added) | MATCH |
| DI-006 | BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.006 | same 4 ✓ (all 4 added) | same 4 ✓ (BC-2.13.006 added) | MATCH |
| DI-007 | BC-2.13.004, BC-2.13.005, BC-2.17.001 | same 3 ✓ (BC-2.13.004/005 added) | same 3 ✓ (BC-2.17.001 added) | MATCH |
| DI-008 | BC-2.01.001, BC-2.01.002, BC-2.08.006, BC-2.08.010, BC-2.14.001, BC-2.14.003 | same 6 ✓ | same 6 ✓ (BC-2.08.006/010 added) | MATCH |
| DI-009 | BC-2.08.007, BC-2.14.004 | same 2 ✓ | same 2 ✓ (BC-2.08.007 added) | MATCH |
| DI-010 | BC-2.14.005 | same 1 ✓ | same 1 ✓ | MATCH |
| DI-011 | BC-2.06.001, BC-2.06.003, BC-2.08.001, BC-2.12.007 | same 4 ✓ | same 4 ✓ (BC-2.08.001 added) | MATCH |
| DI-012 | BC-2.09.003, BC-2.11.001–006 | same 7 ✓ (BC-2.11.001–006 added) | same 7 ✓ (BC-2.09.003 added) | MATCH |
| DI-013 | BC-2.12.005 | same 1 ✓ | same 1 ✓ | MATCH |
| DI-014 | BC-2.08.004, BC-2.08.007, BC-2.09.004, BC-2.09.005, BC-2.14.001, BC-2.14.006 | same 6 ✓ (BC-2.09.004/005 added) | same 6 ✓ (BC-2.09.004/005 added) | MATCH |

**14/14 DIs: exact 3-way match. Zero orphan invariants.**

---

## Trajectory

`14 → 5 → 7 → 13 → 3 → 3 → 3 → 5 → 2`

Clean counter: 0/3 (NOT CLEAN — 2 findings fixed in this pass; next pass starts fresh count toward 3 consecutive CLEAN).

---

## Observations (Non-Blocking)

**VP-anchor local naming divergence:** Several BC files in ss-08 and ss-13 use locally-defined VP IDs in the VP Anchors section (e.g., `VP-BC208009-01`) rather than globally-registered VP-INDEX IDs. This is consistent naming within those BCs and not a correctness error, but the pattern diverges from the VP-INDEX registration convention used by the Kani VPs (VP-001–003). Logged here as a Phase-2 BC template rule candidate **(S-7.02 codification trail)**: story-writer should standardize whether local VP anchors in Wave-2+ BCs get registered in VP-INDEX or remain BC-local.

**ss-13 shared input-hash:** BC-2.08.011 and BC-2.08.012 share hash `9d30ffb534046864` — correct, as their input files are identical. Not a defect.
