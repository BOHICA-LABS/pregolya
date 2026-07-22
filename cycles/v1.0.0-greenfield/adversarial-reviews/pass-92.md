---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T00:00:00Z
phase: 1d
pass: 92
previous_review: pass-91.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: [specs/behavioral-contracts/, specs/prd-supplements/, specs/architecture/, specs/domain-spec/]
input-hash: "5758a30"
---

# Adversarial Review: ferrochain (Pass 92)

**Date:** 2026-07-17
**Phase:** 1d (Spec Crystallization — adversarial cascade)
**Verdict:** NOT CLEAN
**CLEAN (strict):** no
**CLEAN (PR-merge):** yes (all findings fixed in burst 174; zero CRIT/HIGH/MED residue post-fix)
**Findings:** 2 (1 HIGH + 1 MED)
**Novelty:** MEDIUM (partial-fix echo of pass-91 budget cluster at previously-unswept sites)

## Finding ID Convention

Finding IDs for this pass use the format `F-P92-NN` (project convention; cycle prefix omitted per established ferrochain shorthand).

Probes executed — verified clean:
- Error-code census recount: 86 = 43+16+27 EXACT — PASS
- E-MEMORY-008 anchor (BC-2.15.004 EC-004+TV-008): PASS
- interface-definitions v2.30 OnCeiling + BudgetConfig definitions: PASS
- module-decomposition/purity-map inventories: PASS
- capabilities-p0 v1.2 CAP-012: PASS
- NE-01/02/11/12/13/14 tracing: PASS
- gate #33 9-code sample: PASS
- No duplicate changelog rows
- SS-02/SS-05/ADR-004..011 spot-checks: PASS

## Part A — Fix Verification

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P91-01 | HIGH | RESOLVED | BC-2.10.001/003/004 + BC-2.06.003 + CAP-012 on_ceiling attribution corrected to BudgetConfig STRUCT. Partial — TV-001/TV-007 in BC-2.10.003 and PC6 in BC-2.10.004 not swept (→ F-P92-01). |
| F-P91-02 | MED | RESOLVED | interface-definitions v2.29 adds OnCeiling + BudgetConfig defs. RunnableConfig::budget_config field still absent (→ F-P92-02). |
| F-P91-03 | OBS | RESOLVED | TOML Summarize exclusion adjudicated. |
| F-P91-04 | OBS | RESOLVED | E-MEMORY-008 minted; BC-2.15.004 v1.1; census 86 = 43+16+27. |

## Part B — New Findings (or all findings for pass 1)

### CRITICAL

None.

### HIGH

#### F-P92-01: BudgetPolicy-owns-data attribution residue

- **Severity:** HIGH
- **Category:** spec-fidelity
- **Location:** BC-2.10.003 TV-001, TV-007; BC-2.10.004 PC6
- **Description:** Pass-91 corrected on_ceiling attribution in BC-2.10.003 PC1/PC4/PC5 and BC-2.10.004 PC1/TV-001/EC-001, but did not sweep TV-001 and TV-007 in BC-2.10.003 (still say "BudgetPolicy halt at 10k" and "BudgetPolicy with token ceiling") nor PC6 in BC-2.10.004 (still says "policy's current ceiling in the RunnableConfig"). These forms attribute data ownership to the BudgetPolicy TRAIT — canonically incorrect per D18-P91-A (BudgetConfig STRUCT owns on_ceiling/soft_limit/hard_limit).
- **Evidence:** BC-2.10.003 TV-001: "BudgetPolicy halt at 10k tokens triggers Halt"; TV-007: "BudgetPolicy with token ceiling configured"; BC-2.10.004 PC6: "policy's current ceiling in the RunnableConfig" — all three use BudgetPolicy as a data-bearing noun after D18-P91-A retired that attribution.
- **Proposed Fix:** BC-2.10.003 TV-001 → "BudgetConfig halt at 10k" form; TV-007 → "BudgetConfig with token ceiling" form; BC-2.10.004 PC6 → "patch RunnableConfig::budget_config" form. Exhaustive multi-pattern corpus sweep; every remaining hit dispositioned (fixed / changelog-exempt / verbatim-quote-exempt). BC-2.10.003 v1.6, BC-2.10.004 v1.3.

**Status:** FIXED in burst 174.

### MEDIUM

#### F-P92-02: Resume-path ceiling home ambiguity

- **Severity:** MEDIUM
- **Category:** interface-gaps
- **Location:** interface-definitions (§RunnableConfig absent), api-surface, BC-2.10.003 PC7, BC-2.10.004 PC6
- **Description:** Three resume-path spec sites (BC-2.10.003 PC7, BC-2.10.004 PC6, interface-definitions) name RunnableConfig as the target for resume ceiling patches (BudgetResume::Extend), but RunnableConfig had no `budget_config` field defined anywhere in the interface surface. Without a field definition, the BC authority citations are unresolvable — the spec describes patching a field that does not exist in any declared struct.
- **Evidence:** BC-2.10.003 PC7 says "resume ceiling changes patch RunnableConfig"; BC-2.10.004 PC6 says "patch RunnableConfig::budget_config"; interface-definitions §RunnableConfig did not exist as a struct definition (only mentioned in prose). Two candidates: OPTION A — RunnableConfig gains `budget_config: Option<BudgetConfig>` (per-run override); OPTION B — resume patches GraphConfig.budget_config directly.
- **Proposed Fix:** OPTION A (architect adjudication D18-P92-A): RunnableConfig gains `budget_config: Option<BudgetConfig>`; None = inherit GraphConfig::budget_config. Rationale: (1) BC authority names RunnableConfig explicitly; (2) Option B mutates graph-level config shared across concurrent runs — production-grade race defect; (3) reference corpus: RunnableConfig = per-call override bag (TypedDict total=False). interface-definitions v2.31→v2.32, api-surface v1.4, module-decomposition v1.10, entities-server v1.6.

**Status:** FIXED in burst 174. D18-P92-A minted.

### LOW

None.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 1 |
| LOW | 0 |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate (counter 0/3; both findings fixed in burst 174)
**Readiness:** requires revision (burst 174 complete; pass 93 next)

All 2 findings fixed in burst 174. Novelty MEDIUM — partial-fix echo of pass-91 budget cluster (previously-unswept TV/PC residue + undefined field gap). D18-P92-A minted (RunnableConfig::budget_config canon established; OPTION A selected; GraphConfig mutation rejected). Exhaustive corpus sweep terminal.

**CLEAN (strict):** no (2 findings found before fix)
**CLEAN (PR-merge):** yes (all fixed; zero CRIT/HIGH/MED residue post-fix)
**Counter:** 0/3 — NOT CLEAN; streak stays at 0

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 92 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (2/2) |
| **Median severity** | 3.5 (1 HIGH + 1 MED) |
| **Trajectory** | →4→4→1→4→2 |
| **Verdict** | FINDINGS_REMAIN |
