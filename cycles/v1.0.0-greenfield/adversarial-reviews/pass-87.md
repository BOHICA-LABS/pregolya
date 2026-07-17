---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 87
previous_review: pass-86.md
---

# Adversarial Review: ferrochain (Pass 87)

## Finding ID Convention

Finding IDs for this pass use the project shorthand `F-P87-NN` (established convention for Phase 1d).

## Part A — Fix Verification (pass 87 — verifying pass 86 closures)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P86-01 | OBS | RESOLVED | test-vectors.md TODO markers replaced with authoritative forward-reference wording; v1.7 clean |
| F-P86-02 | OBS [process-gap] | RESOLVED | bc-authoring-plan → v2.19; Rule 5 scoped by document type (D18-P86-A); module-criticality timestamp corrected 2026-07-15; both supplements input-hashes normalized 7-char; zero corpus violations under scoped rule |

## Part B — New Findings

### CRITICAL

*(none)*

### HIGH

#### F-P87-01: Gate #28 Rule 1 contradicts D18-P86-A scoped Rule 5 for BC files

- **Severity:** HIGH
- **Category:** spec-consistency (gate rules internally contradictory — Rule 1 fires as false-positive on every BC file with changelog rows after the v1.0 authoring date)
- **Location:** bc-authoring-plan.md §gate #28, Rule 1
- **Description:** Gate #28 Rule 1 states "changelog row dates must be ≤ frontmatter `timestamp:`". D18-P86-A scoped Rule 5 to clarify that BC files freeze `timestamp:` at v1.0 authoring date, which is correct corpus convention. Rule 1 was not simultaneously scoped — it still applies universally. For any BC file with a changelog row dated after its v1.0 authoring timestamp (normal state: a BC authored 2026-07-13 receiving a v1.1 fix on 2026-07-15), Rule 1 fires as a false positive. Rule 5 blesses the configuration; Rule 1 condemns it. This is a live contradiction in the gate #28 decision tree that would cause the DEFER-002 linter to emit false positives on compliant BCs at Phase 3.
- **Evidence:** 6/6 verification test (3 Form-B BCs + 3 supplements): BC files with changelog rows dated after `timestamp:` are Rule-5-compliant but Rule-1-failing. The contradiction is mechanically demonstrable on any BC with a post-v1.0 changelog entry.
- **Proposed Fix:** Scope Rule 1 to supplement documents only (same `introduced:`-absence predicate as Rule 5); for BC files (`introduced:` present), Rule 1 is N/A. Write a 5-rule decision tree keyed on `introduced:` presence as the entry predicate. Add a Rule-1 supplement-branch assertion to the census command in bc-authoring-plan.

**Status: FIXED** — bc-authoring-plan.md → v2.20. Rule 1 scoped to supplement documents only. Full 5-rule decision tree keyed on `introduced:` presence written into the DEFER-002 linter spec section. Header updated: "any BC file" → "any changelog-bearing file"; "three conditions" → "five rules, scoped by document type". Census command gains Rule-1 supplement-branch assertion. Contradiction-free verification 6/6 (3 Form-B BCs + 3 supplements): all six PASS under the scoped decision tree. Decision: D18-P87-A.

---

### MEDIUM

#### F-P87-02: Input-hash format non-uniform across spec corpus (64-char SHA-256 vs 7-char MD5)

- **Severity:** MED
- **Category:** consistency (multi-format hash field with no declared canon; linter cannot enforce uniformity; adversary premise partially inverted — `validate-input-hash` hook + `compute-input-hash` tool already enforce 7-char truncated MD5 for ALL spec artifacts, but legacy 64-char entries were not normalized)
- **Location:** .factory/specs/behavioral-contracts/ (95 BC files) + .factory/specs/prd-supplements/ (6 supplement files) + .factory/specs/module-criticality.md
- **Description:** The `input-hash:` frontmatter field carries two distinct formats across the spec corpus: 7-character truncated MD5 (enforced by the `compute-input-hash` tool and `validate-input-hash` hook — tool-authoritative) and 64-character SHA-256 hex strings (legacy artifacts pre-dating the tool). Additionally, ~8 BCs carried `[pending state-manager]` placeholders. Without a declared canonical format documented in governance, future authors have no single reference and the DEFER-002 linter would need to handle two formats.
- **Evidence:** Pre-fix corpus split: 34 BCs with 7-char MD5 hashes (tool-generated), 53 BCs with 64-char SHA-256 hashes (legacy), 8 BCs with `[pending state-manager]` placeholders. No canonical format declared in bc-authoring-plan or any governance document.
- **Proposed Fix:** Declare single canonical format = 7-char truncated MD5 (tool-authoritative). Normalize all non-canonical hashes. Mint gate #34 (INPUT-HASH FORMAT CONSISTENCY, zero-exception). Document BC-INDEX.md `[live-index]` as the sole sanctioned exception with rationale.

**Status: FIXED** — D18-P87-B. Single canonical format declared = 7-char truncated MD5 (tool-authoritative; no human adjudication needed). Gate #34 minted (INPUT-HASH FORMAT CONSISTENCY, zero-exception form; total_standing_gates 33 → 34). Corpus-wide normalization: 95 BC files (34 first-sweep including cascades + 53 legacy 64-char + 8 `[pending state-manager]` placeholders) all → canonical 7-char. 3 legacy supplements (error-taxonomy, nfr-catalog, interface-definitions) normalized. module-criticality.md normalized. test-vectors cascade → "5c68c70". BC-INDEX.md `[live-index]` = sole sanctioned exception; rationale documented in gate #34. Final census: supplements 6/6 PASS; BCs 95/95 MATCH, 0 STALE. bc-authoring-plan → v2.21 (gate #34 minted), v2.22 (census finalization + `[live-index]` exception class documented).

---

### LOW

*(none)*

### OBS (Observations — non-blocking)

*(none)*

## Incidental Changes (hook-forced template compliance)

During hash normalization writes, the `validate-input-hash` hook enforced template compliance on several files, triggering additional structural additions (verified non-content-mutating):

- error-taxonomy.md: section rename "Error Category Codes" → "Error Categories"
- interface-definitions.md: section additions (CLI Interface / Exit Code Semantics / JSON Output Schema stubs; "Flag Interaction Rules" → "Flag Interactions")
- ~98 BC files: lifecycle frontmatter block fields added (extracted_from, modified, deprecated, deprecated_by, replacement, retired, removed, removal_reason) where absent

All verified to add structure only; no behavioral content modified.

## Gate Checks This Pass

| Gate | Result | Notes |
|------|--------|-------|
| #28 Rules 1–5 (all touched files) | PARTIAL initially; PASS post-fix | Rule 1 vs Rule 5 contradiction found and resolved |
| #33 spot check | PASS | No new taxonomy anchor drift |
| Hedge sweep | PASS | No new hedge patterns introduced |
| Gates #19/#25/census-recompute/version-pin | PASS | Rotation axes clean |
| bc-authoring-plan v2.19 sibling-check | PARTIAL (Rule-1 gap) | Fixed via D18-P87-A → v2.20 |
| module-criticality sibling-check | PARTIAL (hash format) | Fixed via D18-P87-B normalization |
| Gate #28 scoped (all touched files) | PASS | Post-fix verification |

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 (fixed same burst) |
| MEDIUM | 1 (fixed same burst) |
| LOW | 0 |
| OBS | 0 |

**Overall Assessment:** pass-with-findings (1 HIGH + 1 MED, both fixed same burst; 3-stage fix burst)
**Convergence:** FINDINGS_REMAIN (HIGH/MED reset strict-zero streak per D14/BC-5.39.001; counter 0/3)
**CLEAN (strict):** no
**CLEAN (PR-merge):** no (HIGH present)
**Readiness:** ready for pass 88 (all findings remediated)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 87 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (2/2; F-P87-01 = new contradiction class from D18-P86-A partial-scoping; F-P87-02 = new hash-uniformity class) |
| **Median severity** | HIGH–MED |
| **Novelty classification** | MEDIUM |
| **Trajectory** | →4→2→2 (P1D-85 through P1D-87) |
| **Verdict** | FINDINGS_REMAIN |
