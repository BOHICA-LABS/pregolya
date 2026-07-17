---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-16T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 86
previous_review: pass-85.md
---

# Adversarial Review: ferrochain (Pass 86)

## Finding ID Convention

Finding IDs for this pass use the project shorthand `F-P86-NN` (established convention for Phase 1d).

## Part A — Fix Verification (pass 86 — verifying pass 85 closures)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P85-01 | HIGH | RESOLVED | purity-boundary-map splitters::parity BC corrected → BC-2.07.002; v1.2 recount 58 rows PASS |
| F-P85-02 | HIGH | RESOLVED | memory::write_guard Boundary citation corrected → ADR-012/BC-2.15.005; v1.2 verified |
| F-P85-03 | MED | RESOLVED | core::budget Pure Core row added; 22 pure / 58 total; v1.2 verified PASS |
| F-P85-04 | MED | RESOLVED | test-vectors exact 512 = 503 + 9 GTVs; GTV convention note present; v1.6 clean |

## Part B — New Findings

### CRITICAL

*(none)*

### HIGH

*(none)*

### MEDIUM

*(none)*

### LOW

*(none)*

### OBS (Observations — non-blocking, fixed same burst)

#### F-P86-01: test-vectors.md carried literal [TODO:] markers in two template-conformance stub sections

- **Severity:** OBS
- **Category:** coverage-gap (template stub — TODO markers in live consumer-facing document)
- **Location:** test-vectors.md §Per-Subsystem Test Vectors; §Cross-Subsystem Integration Vectors
- **Description:** test-vectors.md v1.6 added three template-conformance sections (Per-Subsystem Test Vectors, Cross-Subsystem Integration Vectors, Golden File References) as structural stubs. Two of those sections retained literal `[TODO:]` placeholder text — one as a conditional instruction, one as an empty placeholder table row. A document with `[TODO:]` markers is confusing to its primary consumers (test-writer, holdout-evaluator) because the markers imply missing authoritative content.
- **Evidence:** Per-Subsystem Test Vectors body: `[TODO: If inline per-subsystem tables are required in this supplement, populate from the BC files following the template format.]`; Cross-Subsystem Integration Vectors: `| [TODO: add cross-subsystem integration scenarios] | | | | |`
- **Proposed Fix:** Replace each TODO with an authoritative forward-reference statement explaining why the section is intentionally minimal at Phase 1a and where the content will come from.

**Status: FIXED** — test-vectors.md → v1.7. Both TODO markers replaced with authoritative forward-reference wording. Retroactive v1.6 changelog note added recording the stub-section addition that was omitted from v1.6 changelog.

---

#### F-P86-02: gate #28 Rule 5 (FRONTMATTER-CURRENCY) contradicted the established BC-corpus timestamp convention

- **Severity:** OBS [process-gap]
- **Category:** spec-fidelity (process gate scope too broad — created false-positive violations for compliant BC files)
- **Location:** bc-authoring-plan.md §gate #28 Rule 5
- **Description:** Rule 5 as written (D18-P75-A) stated `timestamp:` must equal the newest changelog entry date for ALL documents. Applied to BC files, this is incorrect — BC files use `timestamp:` as the v1.0 authoring date (stable, never updated); currency is tracked via `version:` + `## Changelog` + `introduced:` field. BC-2.07.002 (ts 2026-07-13, newest changelog 2026-07-15), BC-2.08.011 (ts 2026-07-13, newest changelog 2026-07-14), and BC-2.08.012 (ts 2026-07-13, newest changelog 2026-07-14) are all COMPLIANT per corpus convention but appeared as violations under Rule 5 as written.
- **Evidence:** BC-2.07.002 frontmatter `timestamp: 2026-07-13T00:00:00Z` vs v1.3 changelog entry date `2026-07-15` — Rule 5 universal form would flag this as a violation; the actual corpus convention says it is correct.
- **Proposed Fix:** Scope Rule 5 by document type — supplements (no `introduced:` field) must match newest changelog date; BC files (has `introduced:` field) must match v1.0 authoring date. Adjudicate as D18-P86-A.

**Status: FIXED** — bc-authoring-plan.md → v2.19. Rule 5 scoped by document type per D18-P86-A. module-criticality.md timestamp corrected 2026-07-14 → 2026-07-15 (metadata-only; was the one supplement actually non-compliant). Both supplements' input-hashes normalized to 7-char short-form. Zero corpus violations remain under scoped rule (9-file verification: 3 BCs + 6 supplements, all PASS).

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |
| OBS | 2 (both fixed same burst) |

**Overall Assessment:** pass-with-findings (2 OBS, both fixed)
**Convergence:** FINDINGS_REMAIN (OBS findings reset strict-zero streak per D14/BC-5.39.001; counter 0/3)
**Readiness:** ready for pass 87 (all findings remediated; content quality HIGH — all substantive axes verified clean)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 86 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (2/2; both OBS — no prior recurrence of these exact classes) |
| **Median severity** | OBS (below LOW on the 1–5 scale; non-blocking) |
| **Trajectory** | →2→3→1→4→2 (P1D-82 through P1D-86) |
| **Verdict** | FINDINGS_REMAIN |
