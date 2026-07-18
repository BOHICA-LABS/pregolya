---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-18T10:30:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 104
previous_review: pass-103.md
---

# Adversarial Review: ferrochain (Pass 104)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 103 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P103-01 | MED (PO) | RESOLVED | nfr-catalog.md changelog rows swapped to descending order (supplement convention per D18-P64-B; pure reorder; no version bump). Gate #28 Rule 6 five-class census re-run confirms PASS. |
| OBS-P103-A | OBS [process-gap] (PO+orchestrator — D18-P103-A) | RESOLVED | Gate #28 Rule 6 census rewritten to five-class hook-aligned direction-asserting model; bc-authoring-plan v2.31→v2.32; 27 Form-A behavioral-contract files corrected desc→asc; 7 architecture Form-A files corrected asc→desc. BC-INDEX edit blocker root cause resolved. |

**Sibling-checks (burst-185 owed list — HEAVY — two bursts of direction churn needed independent verification):**

| Check | Result |
|-------|--------|
| (a) Run the v2.32 direction-asserting census corpus-wide — expect PASS after 34 file corrections | PASS — five-class census confirms 0 direction violations across all 124 files |
| (b) Spot 8 reordered files across all five classes verifying PURE reorders vs git history (no row text lost across double-flip — compare row SETS against 2 commits back) | PASS — 8/8 files spot-checked: pure reorders confirmed; double-flip api-surface row-SET audit shows identical content, no text lost across asc→desc→asc→desc chain |
| (c) Rule 6 five-class prose ↔ census command ↔ hook behavior coherence | PASS — bc-authoring-plan v2.32 prose, census command expected_dir assertions, and hook source all agree on five-class model |
| (d) BC-INDEX edit blocker status | PASS — blocker resolved in burst-185; validate-count-propagation hook accepts current STATE.md phrasing |

**Summary of Part A positive verification:**
- Rule 6 direction+monotonicity corpus-wide: PASS
- 8/8 double-flip reorders pure (api-surface row set intact across full flip chain)
- Rule 6 prose ↔ census ↔ hook behavior coherence: PASS
- nfr-catalog/BC-2.11.005/bc-authoring-plan self-compliance: PASS
- D18-P87-B hook-safe rephrase meaning-intact: PASS
- Gates #27/#34/#13: PASS; gate #33: partial (no in-scope status-table edits in burst-185)

## Part B — New Findings

### MED

#### F-P104-01: ARCH-INDEX.md Missing v1.1 Changelog Row

- **Severity:** MED
- **Owner:** architect
- **Category:** gate-completeness (changelog incompleteness; gate #28 completeness axis)
- **Location:** `.factory/specs/architecture/ARCH-INDEX.md` changelog section
- **Description:** ARCH-INDEX.md is currently at version 1.4 but the changelog contains only the v1.4, v1.3, and v1.2 rows. The v1.1 row is MISSING. The presence of the v1.2 row (which documents "BC total 86→95") proves that pre-1.2 history exists and was authored — a v1.0→v1.1 transition occurred at some point before the v1.2 change, and the row documenting that transition is absent from the changelog.
- **Evidence:** ARCH-INDEX.md changelog shows rows for v1.4, v1.3, v1.2 only. No v1.1 row. The v1.2 row content ("BC total 86→95" or equivalent) establishes that a v1.0→v1.1 transition must have occurred and was recorded in some contemporaneous commit message. ARCH-INDEX.md is the sole architecture file with this gap; all other architecture files with multi-version changelogs were verified complete.
- **Gate:** Gate #28 completeness axis — all version transitions must be documented in the changelog; a changelog with a gap between the current version and v1.0 is a completeness violation.
- **Precedent:** F-P88-03 established the reconstruction procedure for missing changelog rows via git archaeology.
- **Fix:** Reconstruct the missing v1.1 row from git history using `git -C .factory log --all --follow --diff-filter=M -- specs/architecture/ARCH-INDEX.md` to identify the commit where v1.0→v1.1 occurred; extract the change description from the commit message; insert the reconstructed row at the correct position in the changelog (bottom, preserving descending order v1.4/v1.3/v1.2/v1.1/v1.0); annotate with a NOTE marker citing the source commit SHA per F-P88-03 precedent. Sweep ADRs and other architecture files for the same missing-level class in the same burst.

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 |
| LOW | 0 |
| **Total findings** | **1** |

**CLEAN (strict):** no (1 MED)
**CLEAN (PR-merge):** no (1 MED present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM (ARCH-INDEX.md missing v1.1 changelog row is a new class — changelog-completeness vs changelog-ordering; distinct from the transposition/direction findings of passes 101-103; affects the sole architecture index file)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 104 |
| **New findings** | 1 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | MEDIUM (new class: changelog-completeness gap; not changelog-ordering; not a recurrence of passes 101-103 transposition class) |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1 |
| **CLEAN (strict)** | no (1 MED) |
| **CLEAN (PR-merge)** | no (1 MED present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
