---
document_type: adversarial-review
pass: 45
verdict: NOT_CLEAN
severity: MEDIUM
novelty: MEDIUM
phase: 1d
timestamp: 2026-07-14T00:00:00Z
findings_count: 2
observations_count: 1
---

# Adversarial Review — Pass 45

## Verdict: NOT CLEAN — 2 findings (both MED). Novelty MEDIUM.

---

## Findings

### F-P45-01 (MED): verification-coverage-matrix.md — retry module crate ownership contradicts 6 authorities

**Location:** `specs/architecture/verification-coverage-matrix.md` line 51 (retry module row)

**Finding:** The verification-coverage-matrix.md anchors the retry module to `ferrochain-graph`, contradicting six independent authoritative sources that all assign retry to `ferrochain-core`:
- `module-criticality.md` line 64 — owning crate: `ferrochain-core`
- `ARCH-INDEX.md` line 75 — retry responsibility: `ferrochain-core`
- `purity-boundary-map` line 94 — retry: `ferrochain-core`
- `prd.md` line 403 — retry module: `ferrochain-core`
- `prd-supplements/error-taxonomy.md` line 184 — retry: `ferrochain-core`
- `bc-authoring-plan.md` line 869 — retry ownership: `ferrochain-core`

**Why it survived:** Gate #25 Part B census commands compare tier values across the four criticality-bearing docs. The retry row is tier-identical across all four docs (tier = HIGH in all) — so the tier diff passes. The crate-ownership column was never diffed. Gate #25 has no Part C requiring per-row crate ownership comparison.

**Fix route:** Architect (concurrent burst) — fix the coverage-matrix.md cell, relocate the row if needed, run a full 33-row crate diff across all four docs.

---

### F-P45-02 (MED): BC-2.05.006 line 178 — budget escalation mis-characterized as High-tier interrupt

**Location:** `.factory/specs/behavioral-contracts/ss-05/BC-2.05.006.md` line 178 (Related BCs section)

**Finding:** BC-2.05.006 line 178 reads:
> `- BC-2.10.004 — composes with: budget escalation to HITL uses a High-tier interrupt internally`

This characterization contradicts BC-2.10.004's entire contract:
1. BC-2.10.004 resumes via `BudgetResume::Extend | BudgetResume::Halt` — not a risk-tiered role credential.
2. BC-2.10.004 resumes by "human or orchestrator" (automated orchestrator resume is explicitly permitted); High-tier semantics MUST NOT auto-approve (per BC-2.05.006 invariant + E-GRAPH-013).
3. BC-2.10.004 interrupt payload is `BudgetEscalation { current_usage, ceiling, policy_name, reason }` — it carries no `action_risk` field.
4. BC-2.10.004 TVs (TV-002/TV-003) use `BudgetResume::Extend|Halt` with no role credential required.
5. BC-2.10.004 anchors only BC-2.05.001 (the base mechanism), not BC-2.05.006 (the risk-tier extension).

An implementer following the BC-2.05.006 line-178 characterization would apply `RiskGatePolicy(High, RequireApprover(SeniorAnalyst))` to budget escalation interrupts — breaking BC-2.10.004 PC6/PC7 (orchestrator-permitted resume) and TVs (no role credential in resume payload).

**Correct characterization:** BC-2.10.004 budget escalation reuses the BASE interrupt mechanism (BC-2.05.001) with a distinct `BudgetEscalation` payload and `BudgetResume::Extend|Halt` resume variants. It is NOT risk-tiered and is NOT subject to `RiskGatePolicy` or High-tier approver gating. BC-2.05.006's risk-tier classification applies only to domain-action interrupts carrying an `HitlInterruptPayload { action_risk: ActionRisk, ... }`.

**Fix route:** Product-owner (this burst) — correct line 178 in BC-2.05.006; verify no other lines in BC-2.05.006 imply budget escalation is risk-tiered; confirm BC-2.10.004 needs no change.

---

## Observations

### OBS-P45-1 (pending intent verification): Wave 0 in BC frontmatter/batch tables vs ARCH-INDEX Wave convention

**Location:** Batch table Wave column entries (SS-01, SS-07, SS-14 — 13 BCs carry "Wave 0") vs ARCH-INDEX Subsystem Registry and dependency-graph.md (both use a coarser two-wave scheme: Wave 1 / Wave 2)

**Observation:** "Wave 0" appears in BC frontmatter and batch tables for 13 BCs across SS-01 (core primitives), SS-07 (text splitters), and SS-14 (error taxonomy). The ARCH-INDEX Subsystem Registry and dependency-graph.md use a two-wave crate-build scheme (Wave 1 / Wave 2) with no "Wave 0." This is internally uniform (all 13 BCs consistently say Wave 0) and plausibly deliberate: Wave 0 = foundational sub-wave of Wave 1 for BCs with no intra-workspace dependencies. However, no canonical reconciliation note exists explaining the relationship between "Wave 0" (BC granularity) and "Wave 1" (ARCH-INDEX/dependency-graph granularity).

**Intent:** If Wave 0 ⊂ Wave 1 is the intended convention, a brief note in bc-authoring-plan.md near the batch tables (and/or in ARCH-INDEX) would close this as a documented convention rather than an unexplained discrepancy. **Routed to product-owner for documentation in bc-authoring-plan.md (this burst).**

---

## Regression Spot-Checks

1. **Gate #28 version-changelog integrity:** Distribution 55/23/6/2 (CRITICAL/HIGH/MEDIUM/LOW) — matches prior pass arithmetic. PASS.
2. **Gate #27 zero wrong-crate anchors:** No new BC files created this pass; no anchor edits. PASS.
3. **Batch-table cell consistency (gate #13):** BC-2.05.006 batch table row CAP = CAP-006, DI = DI-003 — matches BC body. BC-2.10.004 batch row CAP = CAP-012, DI = DI-003 — matches BC body. PASS.

## Novel Probes

- **Cross-BC seam: budget × HITL risk-tier** → F-P45-02 (new dimension — inter-subsystem semantic seam between SS-05 and SS-10 interrupt mechanisms)
- **Per-row crate ownership in coverage-matrix** → F-P45-01 (new dimension — tier-identical, crate-divergent rows survive all prior census gates)
- **Internal consistency stress: BC-2.05.002, BC-2.10.002, BC-2.14.002, BC-2.12.007** → CLEAN
- **Quantitative coherence spot-check (priority sums 48/30/8; VP propagation 3-doc)** → CLEAN

---

## Novelty Assessment

**MEDIUM** — two genuinely new probe dimensions at pass 45. The cross-BC seam attack (composing two subsystems and checking for contract incompatibility) and the per-row crate ownership check (going below tier-level diff to cell-level crate ownership) are both novel relative to all prior gates. Fresh-context compounding value confirmed at pass 45.

---

## Routing

| Finding | Owner | Status |
|---------|-------|--------|
| F-P45-01 | architect (concurrent burst) | fix cell + relocate row + 33-row crate diff |
| F-P45-02 | product-owner (this burst) | fix BC-2.05.006 line 178; verify no other occurrences |
| OBS-P45-1 | product-owner (this burst) | add Wave-0 reconciliation note to bc-authoring-plan.md |
