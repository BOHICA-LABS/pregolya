---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T21:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 97
previous_review: pass-96.md
---

# Adversarial Review: ferrochain (Pass 97)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 96 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P96-01 | OBS [process-gap] | RESOLVED | All 59 BC Module fields resolved from `[architect to assign — <crate>]` placeholders per module-decomposition v1.10; dual-crate forms applied; each BC patch-bumped; post-sweep grep = zero live `[architect to assign]` hits; bc-authoring-plan v2.28 gate #27 exemption removed. D18-P89-A: 95/95 MATCH. However: semantic variant class NOT caught — see F-P97-01. |

## Part B — New Findings

### HIGH

#### F-P97-01: BC-2.08.009 Semantic Module Placeholder Survived Pass-96 Sweep

- **Severity:** HIGH
- **Category:** spec-fidelity
- **Location:** BC-2.08.009 Traceability §Module field
- **Description:** BC-2.08.009 Module field carried the live placeholder `[architect to confirm crate→subsystem in Phase 1b]`. This is a semantic variant of the `[architect to assign]` class that pass-96 resolved. The burst-178 sweep used the literal pattern only and missed the variant phrasing. Phase 1b was closed 2026-07-14. The "all 59 resolved" claim from pass-96 was falsified — the actual count was 59 literal-form + 1 semantic-variant = 60 total placeholders.
- **Evidence:** `grep -r "architect to confirm" .factory/specs/behavioral-contracts/` → BC-2.08.009.md (before fix).
- **Proposed Fix:** Resolve BC-2.08.009 Module field to authoritative crate assignment per module-decomposition v1.10. Widen gate #27 to semantic class. Update bc-authoring-plan count row to 60.

### MEDIUM

#### F-P97-02: prd.md §10 Stale Deferred-Actor Parenthetical

- **Severity:** MEDIUM
- **Category:** spec-fidelity
- **Location:** prd.md §10 (subsystem tracing / Module column commentary)
- **Description:** prd.md §10 retained the parenthetical `(architect to confirm crate→subsystem mapping in Phase 1b)`. Phase 1b closed 2026-07-14; this is stale deferred-actor language of the same class as F-P97-01 but in the PRD body rather than a BC traceability field. Pass-96 sweep covered behavioral-contracts/ only.
- **Evidence:** `grep -r "architect to confirm" .factory/specs/prd.md` → §10 parenthetical.
- **Proposed Fix:** Delete stale parenthetical from prd.md §10. Bump prd version.

### LOW

#### F-P97-03: BC-2.08.006 Changelog Rows Non-Monotonic

- **Severity:** LOW
- **Category:** spec-fidelity
- **Location:** BC-2.08.006 changelog section
- **Description:** BC-2.08.006 changelog section listed entries in order 1.3/1.1/1.2 (non-monotonic). The canonical convention (gate #28 Rule 1 for BC files) requires newest-first descending: 1.3/1.2/1.1.
- **Evidence:** BC-2.08.006 frontmatter changelog array ordering.
- **Proposed Fix:** Reorder changelog rows to 1.3/1.2/1.1. Metadata-only; no version bump required.

#### F-P97-04: Gate #27 Literal-Only Scope — Semantic Variants Uncovered [process-gap]

- **Severity:** LOW [process-gap]
- **Category:** spec-fidelity
- **Location:** bc-authoring-plan.md gate #27
- **Description:** Gate #27 residue-class was defined as the literal `[architect to assign]` only. The semantic variant class (`architect to confirm`, `architect to determine`, `architect to resolve`) was not enumerated. No operational sweep command was present in the gate body, leaving verification manual and incomplete. This is the process gap that allowed F-P97-01 and F-P97-02 to survive pass-96.
- **Evidence:** bc-authoring-plan.md gate #27 text (before fix) — literal pattern only, no sweep command.
- **Proposed Fix:** Widen gate #27 to semantic regex: `architect to (assign|confirm|determine|resolve)`, scope = ALL .factory/specs/. Add sweep command. Run widened sweep corpus-wide and verify zero live hits after F-P97-01/02 fixes.

#### F-P97-05: BC-2.10.003 VP-Table Phase Column Shows Wave Label

- **Severity:** LOW
- **Category:** spec-fidelity
- **Location:** BC-2.10.003 VP Identifiers table, VP-BUDGET-06 and VP-BUDGET-07 rows
- **Description:** VP-BUDGET-06 and VP-BUDGET-07 in BC-2.10.003's VP Identifiers table showed "Wave 1" in the Phase column. The Phase column canonically carries VSDD phase designations ("Phase 1", "Phase 3") per the convention established in BC-2.10.001/004. All other VPs in BC-2.10.003 correctly showed "Phase 1". The "Wave 1" entries were introduced during VP renumbering at pass-93.
- **Evidence:** BC-2.10.003 VP Identifiers table rows for VP-BUDGET-06/07.
- **Proposed Fix:** Normalize VP-BUDGET-06/07 Phase column: "Wave 1" → "Phase 1".

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 1 |
| LOW | 3 |
| OBS | 0 |

**Overall Assessment:** pass-with-findings (1H+1M+3L — all fixed in burst 179)
**Convergence:** FINDINGS_REMAIN (strict — findings present; fixed in burst 179)
**Readiness:** CLEAN (PR-merge) — zero CRIT+HIGH+MED findings pre-fix; ready for pass 98 on burst-179 HEAD

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 97 |
| **New findings** | 5 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (5 new, 0 duplicate) |
| **Median severity** | LOW (sorted: HIGH, MED, LOW, LOW, LOW; 3rd = LOW) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5 |
| **Verdict** | FINDINGS_REMAIN (NOT CLEAN strict); CLEAN (PR-merge) |
