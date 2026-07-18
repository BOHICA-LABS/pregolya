---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-18T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 103
previous_review: pass-102.md
---

# Adversarial Review: ferrochain (Pass 103)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 102 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P102-01 | LOW (PO) | RESOLVED | BC-2.11.005 changelog rows reordered ascending (1.0, 1.1, 1.2, 1.3); pure metadata reorder; gate #28 Rule 3 satisfied. |
| F-P102-OBS-A | OBS [process-gap] (PO+orchestrator — D18-P102-A) | RESOLVED | Gate #28 gains Rule 6 VERSION-MONOTONICITY; bc-authoring-plan v2.30→v2.31; first corpus census: 14 total transposed files repaired; orchestrator correction: error-taxonomy + interface-definitions restored descending per supplement convention; census command corrected direction-aware. |

**Sibling-checks (burst-184 owed list):**

| Check | Result |
|-------|--------|
| Gate #28 Rule 6 census re-verify: all 14 repaired files show correct direction per file-class (BCs+architecture ascend; prd-supplements descend per D18-P64-B; equal-version adjacency permitted) | FAIL — see OBS-P103-A; census command was direction-blind; census re-run under corrected five-class model post-fix PASS |
| bc-authoring-plan v2.31 Rule 6 prose coherent with prior Rules 1–5 | PASS (after OBS-P103-A fix: Rule 6 prose aligned to hook-enforced five-class model) |
| Zero live changelog-transposition violations corpus-wide (124 files) | PASS — corrected census re-run post-fix confirms 0 violations |

**GuardrailDecision 12-variant propagation (positive verification):** Spot-check 5/5 of the 14 reorder-repaired files — pure changelog reorders; no behavioral content altered. H1↔INDEX sync PASS. GuardrailDecision radius remains FULLY CLOSED.

## Part B — New Findings

### MED

#### F-P103-01: nfr-catalog.md Changelog Rows Transposed

- **Severity:** MED (per D18-P103-A: supplements are descend-ordered per D18-P64-B; transposition in supplement = gate #28 Rule 6 violation in a newer-lower-than-older direction)
- **Owner:** PO
- **Category:** metadata-ordering (changelog convention)
- **Location:** nfr-catalog.md changelog section
- **Description:** The nfr-catalog.md changelog had rows in ascending order (oldest-at-top), but supplement documents governed by D18-P64-B must be descending (newest-at-top). This is the same class as F-P102-OBS-A but now applying to a supplement file missed by the burst-184 direction-blind census.
- **Evidence:** nfr-catalog.md changelog rows were ascending; post-burst-184 Rule 6 should have caught this; the direction-blind census passed it because it only checked internal monotonicity without checking expected direction.
- **Fix:** Swap rows to descending order (pure reorder; no content change; no version bump). Gate #28 Rule 6 satisfied.

### [process-gap] OBS

#### OBS-P103-A: Gate #28 Rule 6 Census Was Direction-Blind (Structural Flaw)

- **Severity:** OBS [process-gap]
- **Owner:** PO + orchestrator (codification decision)
- **Category:** process-gap (gate enforcement gap)
- **Location:** bc-authoring-plan.md gate #28 Rule 6 census command (v2.31)
- **Description:** The burst-184 Rule 6 census command checked internal monotonicity only — it verified that version numbers within a file were monotonically ordered relative to each other, but it did not assert the EXPECTED DIRECTION (ascending vs descending) per file class. This is a structural blindspot: a file with consistently-wrong-direction ordering (e.g., a supplement with consistently ascending rows) would pass the internal-monotonicity check while still violating the descending-convention requirement. Exactly this is how nfr-catalog.md passed the burst-184 census — its rows were consistently ascending (internally monotonic) but should be descending.

  Additionally, during the PO's hook-source audit to investigate the deeper root cause, the burst-184 Rule 6 file-class rules were found to be partly WRONG. The actual machine-hook enforcement model (from the hook source) differs from the bc-authoring-plan v2.31 prose:

  | File class | bc-authoring-plan v2.31 (burst-184) | Actual hook enforcement |
  |---|---|---|
  | prd-supplements/ | descend | desc (hook-enforced) |
  | architecture/ Form B (ADRs) | ascend | desc (hook-enforced) |
  | architecture/ Form A | ascend | desc (hook-enforced for hook; asc = project convention per CLAUDE.md) |
  | behavioral-contracts/ Form A | ascend | asc (hook-enforced) |
  | behavioral-contracts/ Form B non-INDEX | (not specified) | desc (hook-enforced) |
  | BC-INDEX.md | (not specified) | EXEMPT (hook skips) |

  The burst-184 "BCs+architecture ascend" rule was a simplification that incorrectly applied ascending to architecture/ Form B (ADRs) and mixed Form A/B without distinction.

- **Fix (D18-P103-A — orchestrator codification decision):** Rule 6 gate prose rewritten to the five-class hook-aligned model with explicit `expected_dir` per path+form:
  1. `prd-supplements/` → desc (newest-at-top; hook-enforced)
  2. `architecture/` Form A → desc (hook-enforced; also project convention)
  3. `architecture/` Form B (ADRs, `adr/` subdir) → desc (hook-enforced)
  4. `behavioral-contracts/` Form A → asc (oldest-to-newest; hook-enforced)
  5. `behavioral-contracts/` Form B non-INDEX → desc (hook-enforced)
  6. `BC-INDEX.md` → EXEMPT (hook skips this file)

  Census command updated to include direction assertion (`expected_dir` per path+form). A corpus-wide re-run under the corrected model was executed:
  - 27 Form-A behavioral-contract files corrected desc→asc (previously direction-blind census had flagged them as OK when ascending; correct under five-class model)
  - 7 architecture Form-A files corrected asc→desc (several were ascended at burst-184 under the then-wrong rule; now correctly descended per hook authority)
  - purity-boundary-map retained desc (supplement-like convention, architecture/ sub-path)
  - 3 Form-B ADRs retained desc (correct per five-class model)
  - BC-INDEX retained desc (exempt per five-class model; hook skips)

  All corrections are pure reorders. bc-authoring-plan v2.31 → v2.32. verification-coverage-matrix hash cabbed8 → 6b6537d. Post-census: 0 violations under the five-class direction-asserting model.

### Positive Observation (non-finding)

#### OBS-P103-B: GuardrailDecision 12-Variant Propagation Fully Symmetric

- **Severity:** positive (not a finding)
- **Description:** Spot-check of 5 reorder-corrected files confirms all pure reorders with no behavioral content altered. Independent verification: GuardrailDecision variant count (12) propagated correctly across BC-2.06.001 v1.3, BC-2.11.002 v1.6, BC-2.11.003 v1.5, BC-2.11.004 v1.5, BC-2.11.005 v1.3, ADR-006 rev-4, interface-definitions v2.35, events.md v1.5. All carrier documents agree on all dimensions (Fail/Transform only; Pass not streamed; metadata-only payload; boundary-qualified ordering; unary no-emission; ToolEnd POST-guardrail). Nine-dimension symmetry table verified FULLY SYMMETRIC across all three SS-11 carriers. This closes the D18-P99-A scope expansion (burst-181/182/183) cleanly.

## Part C — Additional Probes

### Gate Checks

| Gate | Result |
|------|--------|
| Gate #28 Rule 6 five-class direction-asserting census: 124 files scanned, 0 violations (post-fix) | PASS |
| Gate #28 Rules 1–5 on all files touched in burst-184 | PASS |
| Gate #34 input-hash format: spot-check 5 BC files corrected in census re-run | PASS (7-char MD5 throughout) |
| Gate #13 VP-uniqueness census: zero duplicate VP IDs corpus-wide | PASS |
| Gate #33 9-artifact reverse-verification sample | PASS |
| Hedge sweep (all five patterns) | PASS |
| H1↔INDEX sync: BC-INDEX.md byte-exact title match for 5 spot-checked BCs | PASS |

### Fresh Probes

| Probe | Result |
|-------|--------|
| 14-file reorder spot-check (5/5 pure reorders; no row text lost) | PASS |
| burst-184 Rule 6 "BCs+architecture ascend" rule coherence with hook source | FAIL — see OBS-P103-A (hook has architecture/ as desc; burst-184 prose said ascend) |
| Five-class model post-fix coherence: census command ↔ gate prose ↔ hook behavior | PASS (all three aligned post-fix) |
| nfr-catalog.md post-fix direction: descending | PASS (F-P103-01 fix applied) |
| Double-flip audit for api-surface (ascended at burst-184, then descended at burst-185 five-class correction): compare row SET against 2 commits back | PASS — row SET identical across the double-flip; only ordering changed |

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 |
| LOW | 0 |
| OBS [process-gap] | 1 |
| Positive OBS | 1 |
| **Total findings** | **2** |

**CLEAN (strict):** no (1 MED + 1 OBS/process-gap)
**CLEAN (PR-merge):** no (1 MED present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM (gate #28 Rule 6 structural flaw in direction-assertion is a new axis; F-P103-01 is a recurrence-class instance)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 103 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | MEDIUM (OBS-P103-A is a deeper structural finding — direction-blind census design flaw; F-P103-01 is recurrence-class but caused by the structural flaw) |
| **Median severity** | MED (one MED + one OBS) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2 |
| **CLEAN (strict)** | no (1 MED + 1 OBS/process-gap) |
| **CLEAN (PR-merge)** | no (1 MED present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
