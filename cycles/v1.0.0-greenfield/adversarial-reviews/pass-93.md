---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T00:00:00Z
phase: 1d
pass: 93
previous_review: pass-92.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: [specs/behavioral-contracts/, specs/prd-supplements/, specs/architecture/, specs/domain-spec/]
input-hash: "eb289f1"
---

# Adversarial Review: ferrochain (Pass 93)

**Date:** 2026-07-17
**Phase:** 1d (Spec Crystallization — adversarial cascade)
**Verdict:** NOT CLEAN
**CLEAN (strict):** no
**CLEAN (PR-merge):** yes (all findings fixed in burst 175; zero CRIT/HIGH/MED residue post-fix)
**Findings:** 5 (2 HIGH + 2 MED + 1 OBS [process-gap])
**Novelty:** HIGH (model-level defects in P0 budget-governance cluster that survived the F-P91/92 sweeps by hiding in unverified documents; VP ID collision class newly introduced)
**Session note:** Pass 93 concentrated on budget-cluster terminal verification. Broader content probes (SS-03/SS-12/SS-16, ADR-001..003↔BCs, server-endpoint interface↔BC signatures, test-vectors index sampling, Domain A/B forcing-function traces) were NOT exercised — deferred to pass 94.

## Finding ID Convention

Finding IDs for this pass use the format `F-P93-NN` (project convention; cycle prefix omitted per established ferrochain shorthand).

## Part A — Fix Verification

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P92-01 | HIGH | RESOLVED | BC-2.10.003 TV-001/007 + BC-2.10.004 PC6 BudgetPolicy-owns-data forms confirmed absent; corpus grep terminal clean |
| F-P92-02 (D18-P92-A) | MED | RESOLVED | RunnableConfig::budget_config: Option<BudgetConfig> present in interface-definitions v2.32 §RunnableConfig; api-surface/module-decomposition/entities-server updated |

## Part B — New Findings (or all findings for pass 1)

### HIGH

#### F-P93-01 — entities-server v1.6 §Policy/Governance Semantic Drift

- **Severity:** HIGH
- **Category:** spec-fidelity
- **Location:** `specs/domain-spec/entities-server.md` v1.6 §BudgetConfig, §EvidenceJournal
- **Description:** The burst-174 BA edit introduced invented fields and types not present in the canonical interface spec. BudgetConfig used `token_ceiling`/`cost_ceiling_usd` (invented) and `on_ceiling: PolicyOutcome (Allow|Escalate|Deny)` (invented type + wrong variants). EvidenceEntry used `node_name`/`cost_usd`/`tokens_used`/`policy_outcome` (all invented) instead of BC-2.10.002 PC2 JournalEntry verbatim 8-field set.
- **Evidence:** interface-definitions.md v2.29 §BudgetConfig: `soft_limit: Option<u64>`, `hard_limit: Option<u64>`, `on_ceiling: OnCeiling (Halt|Escalate|Summarize)`. BC-2.10.002 PC2 JournalEntry: `{run_id, sub_agent_id, evaluation_point, token_usage, policy_name, decision: PolicyDecision (Allow|Escalate|Deny), reason, timestamp}`.
- **Proposed Fix:** Rewrite entities-server v1.7 as verbatim-canon transcription from interface-definitions §BudgetPolicy + BC-2.10.002 PC2.
- **Fix applied:** entities-server v1.7. Residue sweep: `PolicyOutcome`, `token_ceiling`, `cost_ceiling_usd` zero live occurrences; entities-graph.md confirmed clean.

#### F-P93-02 — Contradictory HITL Trigger Model (D18-P93-A Adjudication)

- **Severity:** HIGH
- **Category:** contradictions, ambiguous-language
- **Location:** `specs/prd-supplements/interface-definitions.md` v2.32 engine-branching note; `specs/behavioral-contracts/ss-10/BC-2.10.004.md` v1.3 H1 title; `specs/behavioral-contracts/ss-10/BC-2.10.001.md` PC3
- **Description:** Three-way contradiction: (1) interface-definitions v2.32 engine-branching note specified only `PolicyDecision::Deny` dispatch and left `PolicyDecision::Escalate` entirely unspecified — no engine handler defined; (2) BC-2.10.004 v1.3 H1 title "When on_ceiling = escalate" implied `on_ceiling=Escalate` is the gate for HITL even on the soft-limit path; (3) BC-2.10.001 PC3 "Escalate → HITL unconditionally, no on_ceiling qualification". Under Model B (title reading), soft_limit with `on_ceiling=Halt` would return `PolicyDecision::Escalate` with no handler — panicking engine.
- **Evidence:** BC-2.10.001 PC3 verbatim: "Escalate → execution suspends; the run transitions to `interrupted` via the HITL interrupt mechanism (BC-2.10.004)" — zero qualification on `on_ceiling`. BC-2.10.004 PC2 scope: "engine consults BudgetConfig::on_ceiling after a Deny" — PC2 scope = Deny path only.
- **Proposed Fix:** Adjudicate Model A. Define complete 5-row decision table (PolicyDecision × on_ceiling → action).
- **Fix applied (D18-P93-A — Model A):** `PolicyDecision::Escalate` ALWAYS triggers HITL unconditionally; `PolicyDecision::Deny` branches on `on_ceiling` (Halt→E-BUDGET-001/halt; Escalate→HITL/interrupted; Summarize→summary call/summary_halt; recursive Deny→Halt fallback). interface-definitions v2.33: §OnCeiling docstring updated; complete 5-row decision table added. BC-2.10.004 v1.4: dual-path form (PC1a/PC1b, PC2/PC2b, TV-001b). BC-INDEX: title cite updated.

### MEDIUM

#### F-P93-03 — BC-2.10.004 Stale CAP-012 Quote

- **Severity:** MED
- **Category:** spec-fidelity
- **Location:** `specs/behavioral-contracts/ss-10/BC-2.10.004.md` v1.3, Capability Anchor Justification verbatim quote
- **Description:** CAP-012 verbatim quote was pre-v1.2 wording "the policy's `on_ceiling` setting". capabilities-p0 v1.2 updated CAP-012 to "the budget configuration's `on_ceiling` setting (`BudgetConfig::on_ceiling`)".
- **Evidence:** capabilities-p0.md v1.2 CAP-012 definition vs BC-2.10.004 v1.3 Justification quote.
- **Proposed Fix:** Update verbatim quote to v1.2 text.
- **Fix applied:** Folded into BC-2.10.004 v1.4 changelog row.

#### F-P93-04 — VP-BUDGET-05 ID Collision Between BC-2.10.003 and BC-2.10.004

- **Severity:** MED
- **Category:** verification-gaps
- **Location:** `specs/behavioral-contracts/ss-10/BC-2.10.003.md` VP Anchors; `specs/behavioral-contracts/ss-10/BC-2.10.004.md` VP Anchors
- **Description:** Both BCs defined a verification property VP-BUDGET-05 with different semantics — BC-2.10.003's Summarize-path Kani proof vs BC-2.10.004's HITL Escalate-path integration test.
- **Evidence:** BC-2.10.003 v1.6 VP section: "VP-BUDGET-05 (Kani, P0): ..."; BC-2.10.004 v1.3 VP section: "VP-BUDGET-05 (P1): ...".
- **Proposed Fix:** BC-2.10.004 keeps VP-BUDGET-05 (canonical — phase 1a, lower ordinal); BC-2.10.003 renumbers to VP-BUDGET-07.
- **Fix applied:** BC-2.10.003 v1.7 VP Anchors: VP-BUDGET-05→VP-BUDGET-07. Final sequence VP-BUDGET-01..07 no gaps/collisions.

### OBSERVATIONS / PROCESS GAPS

#### OBS-P93-01 — [process-gap] Gate #13/#14 VP-Uniqueness Census Gap

- **Severity:** OBS [process-gap]
- **Category:** coverage-gap
- **Location:** `specs/prd-supplements/bc-authoring-plan.md` v2.25 §Gate #13/#14
- **Description:** Gates #13/#14 only censused VP-INDEX-registered VPs. BC-local `VP-<DOMAIN>-NNN` identifiers in individual BC files' "VP Anchors" sections were invisible. The VP-BUDGET-05 collision was not catchable by existing gates.
- **Evidence:** gate #13 command greps VP-INDEX only; no corpus-wide BC-local VP ID uniqueness check existed.
- **Proposed Fix:** Extend gate #13 with BC-local VP uniqueness sub-check (`grep -rh "VP-[A-Z]*-[0-9]*" .factory/specs/behavioral-contracts/ | sort | uniq -d`).
- **Fix applied:** bc-authoring-plan v2.26: gate #13 extended with VP-uniqueness sub-check + census command. FIRST CENSUS RUN detected pre-existing VP-STREAM-02 collision (BC-2.06.001 vs BC-2.06.002) — fixed in-scope: BC-2.06.002 v1.1 (VP-STREAM-02 → VP-STREAM-04). Post-fix census: zero duplicate VP IDs corpus-wide.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 2 |
| LOW | 0 |
| OBS [process-gap] | 1 |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — all fixed in burst 175; counter stays 0/3
**Readiness:** requires pass 94 (deferred content probes owed; sibling-checks for burst-175 fixes)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 93 |
| **New findings** | 5 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (5/5) |
| **Median severity** | 3.0 (HIGH HIGH MED MED OBS — position 3 = MED) |
| **Trajectory** | →4→1→4→2→5 |
| **Verdict** | FINDINGS_REMAIN |
