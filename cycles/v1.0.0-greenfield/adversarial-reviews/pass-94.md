---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T00:00:00Z
phase: 1d
pass: 94
previous_review: pass-93.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: [specs/behavioral-contracts/, specs/prd-supplements/, specs/architecture/, specs/domain-spec/]
input-hash: "a7768e5"
---

# Adversarial Review: ferrochain (Pass 94)

**Date:** 2026-07-17
**Phase:** 1d (Spec Crystallization — adversarial cascade)
**Verdict:** NOT CLEAN
**CLEAN (strict):** no — 3 MED findings
**CLEAN (PR-merge):** yes (all findings fixed in burst 176; zero CRIT/HIGH/MED residue post-fix)
**Findings:** 3 (0 HIGH + 3 MED + 0 OBS)
**Novelty:** MEDIUM (all localized to SS-10 burst-175 fix radius; no new systemic patterns)
**Session note:** Pass 94 exercised burst-175 sibling-checks (gate #1 hedge sweep, gate #13 VP-uniqueness census, gate #16/#33 SS-16 E-RETRY census, gate #34 format, H1↔postcondition rotation, holdout CAP-005/012/013 traces, SS-16 coherence). Broader content probes for SS-03/SS-12 (index-level only this pass), ADR-001..003, server-endpoint signatures, and TV-index 10-BC sampling remain owed for pass 95.

## Finding ID Convention

Finding IDs for this pass use the format `F-P94-NN` (project convention; cycle prefix omitted per established ferrochain shorthand).

## Part A — Fix Verification

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P93-01 | HIGH | RESOLVED | entities-server v1.7 confirmed: BudgetConfig uses `soft_limit/hard_limit/on_ceiling: OnCeiling`; EvidenceJournal uses JournalEntry 8-field set verbatim; zero PolicyOutcome/token_ceiling/cost_ceiling_usd residue |
| F-P93-02 (D18-P93-A) | HIGH | RESOLVED | interface-definitions v2.33 §OnCeiling 5-row decision table confirmed; BC-2.10.004 v1.4 dual-path (PC1a/PC1b, PC2/PC2b, TV-001b) confirmed; BC-2.10.001 v1.3 PC3 "Escalate ALWAYS HITL" confirmed |
| F-P93-03 | MED | RESOLVED | BC-2.10.004 v1.4 CAP-012 quote updated to capabilities-p0 v1.2 wording |
| F-P93-04 | MED | RESOLVED | BC-2.10.003 v1.7 VP-BUDGET-07; BC-2.10.004 keeps VP-BUDGET-05; sequence VP-BUDGET-01..07 clean; zero duplicates corpus-wide |
| OBS-P93-01 | OBS [process-gap] | RESOLVED | bc-authoring-plan v2.26 gate #13 VP-uniqueness sub-check; VP-STREAM-02 collision fixed (BC-2.06.002 v1.1 VP-STREAM-04); corpus census zero duplicates |

## Part B — New Findings (or all findings for pass 1)

### MEDIUM

#### F-P94-01 — BC-INDEX BC-2.10.003 Row Title Has Trailing Italic Annotation

- **Severity:** MED
- **Category:** spec-fidelity
- **Location:** `.factory/specs/behavioral-contracts/BC-INDEX.md` line ~112
- **Description:** The BC-INDEX.md row for BC-2.10.003 carries a trailing italic enrichment `_(v1.2: adds OnCeiling::Summarize + RunContext.budget_info / BudgetInfo)_` that is absent from the BC's H1 heading. This is a one-off annotation that breaks the required byte-exact title sync between the index row and the BC's canonical H1. The annotation was presumably added during the v1.2 burst as an inline reminder but was never cleaned up after the BC title did not adopt it.
- **Evidence:** BC-INDEX.md line 112 title: "Graceful Halt When Budget Ceiling Reached (on_ceiling = halt | summarize); Remaining-Budget Exposure _(v1.2: adds OnCeiling::Summarize + RunContext.budget_info / BudgetInfo)_". BC-2.10.003.md H1: "# BC-2.10.003: Graceful Halt When Budget Ceiling Reached (on_ceiling = halt | summarize); Remaining-Budget Exposure".
- **Proposed Fix:** Remove the italic parenthetical from the BC-INDEX row so the title column matches the H1 exactly. Bump BC-INDEX version and add changelog entry.
- **Fix applied:** BC-INDEX v1.4→v1.5; line 112 italic removed; byte-exact H1 match verified. Changelog entry added.

#### F-P94-02 — BC-2.10.004 TV-001b Lettered Sub-Vector Naming Anomaly

- **Severity:** MED
- **Category:** spec-fidelity
- **Location:** `specs/behavioral-contracts/ss-10/BC-2.10.004.md`; `specs/prd-supplements/test-vectors.md`
- **Description:** Burst-175 introduced TV-001b as a new test vector in BC-2.10.004 (the hard-ceiling HITL escalation path for the Model A adjudication). This created the only lettered sub-vector identifier in the entire corpus — all other test vectors use sequential integer IDs (TV-001, TV-002, ...). The lettered form is inconsistent with the naming convention and creates a special-case that complicates test-vector census tooling and cross-BC referencing. Additionally, test-vectors.md was not updated to reflect the additional SS-10 row — the subtotal and grand total were stale.
- **Evidence:** BC-2.10.004 v1.4 references "TV-001b"; every other BC test vector uses integer-only suffixes (TV-NNN). test-vectors.md §SS-10 showed subtotal 22 but BC-2.10.004 now has 6 test vectors (TV-001a + TV-001b split made 6 distinct vectors).
- **Proposed Fix:** Adjudication: option (ii) — rename TV-001b → TV-006 (sequential). This eliminates the only lettered sub-vector in the corpus and restores uniform convention. Update test-vectors.md SS-10 subtotal and grand total.
- **Fix applied (option ii):** BC-2.10.004 v1.4→v1.5 (TV-001b renamed TV-006); test-vectors v1.7→v1.8 (row 5→6; Notes annotation added; SS-10 subtotal 22→23; canonical TVs 503→504; GRAND TOTAL 512→513 = 504 canonical + 9 GTV).

#### F-P94-03 — BC-2.10.001 Deny Dispatch Model Incomplete After D18-P93-A

- **Severity:** MED
- **Category:** spec-fidelity, contradictions
- **Location:** `specs/behavioral-contracts/ss-10/BC-2.10.001.md`
- **Description:** D18-P93-A established the three-way `on_ceiling` dispatch for `PolicyDecision::Deny` (Halt / Escalate / Summarize paths). BC-2.10.004 and interface-definitions were updated in burst-175, but BC-2.10.001 (the primary Deny evaluator) was NOT updated — its Description still reads "the run halts" (monolithic halt semantics) and PC3 does not enumerate the three dispatch branches. A reader of BC-2.10.001 alone would not know about the Escalate and Summarize paths from Deny. The propagation of D18-P93-A was incomplete.
- **Evidence:** BC-2.10.001 v1.3 Description: "the engine halts the run" — no mention of Escalate/Summarize paths. PC3: "Deny → E-BUDGET-001 raised; run halts" — missing the on_ceiling=Escalate and on_ceiling=Summarize branches. interface-definitions v2.33 §OnCeiling 5-row table shows all three Deny branches fully specified.
- **Proposed Fix:** BC-2.10.001 v1.4: update Description to name dispatch per BudgetConfig::on_ceiling; add PC3 three-way dispatch block; update Related-BCs to dual-path; clarify EC-004 applies only when on_ceiling=Halt. Sweep bonus: BC-2.10.002 also needs minor note clarification (TV-002 + Related-BCs "before engine dispatch").
- **Fix applied:** BC-2.10.001 v1.3→v1.4 (Description + PC3 three-way dispatch block: Halt→BC-2.10.003 / Escalate→BC-2.10.004 PC1b/PC2b / Summarize→BC-2.10.003 PC8; Related-BCs dual-path; EC-004 qualified "(with on_ceiling=Halt in this scenario)"). BC-2.10.002 v1.1→v1.2 (TV-002 Note + Related-BCs "before engine dispatch"). BA follow-through: events.md v1.1→v1.2 (BudgetEvaluated Outcome → dispatch-per-on_ceiling form).

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 3 |
| LOW | 0 |
| OBS [process-gap] | 0 |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — all fixed in burst 176; counter stays 0/3
**Readiness:** requires pass 95 (sibling-checks for burst-176 fixes; content probes SS-03/SS-12, ADR-001..003, server-endpoint signatures, TV-index 10-BC sampling)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 94 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 1 |
| **Novelty score** | 0.67 (2/3) |
| **Median severity** | 3.0 (MED MED MED — position 2 = MED) |
| **Trajectory** | →4→1→4→2→5→3 |
| **Verdict** | FINDINGS_REMAIN |
