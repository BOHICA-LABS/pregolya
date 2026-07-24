---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.001
version: "1.6"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-10
capability: CAP-012
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-61): F-P61-01 (HIGH) — ADR-009 Option-3 trait-in-core split propagated. Architecture Anchors: trait/PolicyDecision/TokenUsage/RunContext anchor moved from ferrochain-graph/src/budget/policy.rs to ferrochain-core/src/budget.rs (definitions, per ADR-009 Option 3). Module field resolved from stale placeholder to ferrochain-core (trait + types) / ferrochain-graph (engine). BudgetEngine/EvidenceJournal anchors unchanged (ferrochain-graph)."
  - "1.2 (F-P91-01, 2026-07-17): Attribute soft_limit/hard_limit configuration fields to BudgetConfig struct (not BudgetPolicy trait) per interface-definitions v2.29 §BudgetConfig. PC1: reframed from 'RunnableConfig includes a BudgetPolicy' to 'BudgetConfig configured in GraphConfig.budget_config; engine constructs BudgetPolicy from it'. TV-001: 'BudgetPolicy with soft_limit = ...' → 'BudgetConfig with soft_limit = ...'; TV-002/TV-003: 'Same policy' → 'Same BudgetConfig'. soft_limit and hard_limit are BudgetConfig fields per interface-definitions v2.29; BudgetPolicy::evaluate is pure and data-free."
  - "1.3 (D18-P93-B, 2026-07-17): Cost-ceiling scope adjudication. CAP-012 names 'Cost Metering' but does NOT require a configurable cost-based ceiling in v1. Verdict: metering-via-journal satisfies the cost dimension. `JournalEntry.token_usage.estimated_cost` (BC-2.10.002 PC2) provides cost observability; `BudgetConfig` v1 thresholds (`soft_limit`, `hard_limit`) are token counts (`u64`) only. Cost-based ceiling evaluation would require a `Decimal` or `f64` threshold field — not present in v1 spec. Scope note added to Traceability table. Reported as D18-P93-B for state-manager."
  - "1.4 (F-P94-03, 2026-07-17): Fix Deny characterization to reflect three-way on_ceiling dispatch per interface-definitions v2.33 §PolicyDecision×on_ceiling decision table. (a) Description: 'Deny (halt the run immediately)' → 'Deny (engine dispatches per BudgetConfig::on_ceiling — halt, HITL escalation, or summarize)'. (b) PC3 Deny clause: 'execution halts at the next safe super-step boundary (BC-2.10.003)' → three-way dispatch: Halt→BC-2.10.003; Escalate→BC-2.10.004 PC1b/PC2b; Summarize→BC-2.10.003 PC8. (c) Related BCs: BC-2.10.003 line updated to reflect Halt and Summarize paths; BC-2.10.004 line updated to reflect both soft-ceiling Escalate and hard-ceiling Deny+on_ceiling=Escalate HITL paths. Sweep fix: EC-004 expected-behavior clarified with '(on_ceiling=Halt in this scenario)' to prevent implicit halt assumption."
  - "1.5 (F-P95-03, 2026-07-17): Update PC3 Deny cite and Related-BCs cite to reflect BC-2.10.004 v1.6 precondition renumbering. Old cites 'BC-2.10.004 PC1b/PC2b' (stale after v1.6 restructure) replaced with 'BC-2.10.004 PC2 (hard-ceiling path)' at PC3 dispatch block (×1) and Related-BCs line (×1). Semantics unchanged — the hard-ceiling Deny+on_ceiling=Escalate path is now cleanly PC2 in BC-2.10.004."
  - "1.6 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-012
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/comparative/adk-rust/behavioral-intent.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "7abcbf1"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.001: BudgetPolicy allow/escalate/deny Evaluation per Run and per Sub-Agent

## Description

A `BudgetPolicy` is a composable, stateless trait that evaluates a `TokenUsage` snapshot
against configured thresholds and returns a `PolicyDecision`: `Allow` (continue), `Escalate`
(suspend and raise a HITL interrupt), or `Deny` (engine dispatches per `BudgetConfig::on_ceiling` — halt, HITL escalation, or summarize). The policy is
evaluated after every LLM call and every tool invocation, both for the top-level run and for
each nested sub-agent run independently. The policy shape is adapted from adk-rust P-73
(adk-payments `PaymentPolicyGuardrail` — allow/escalate/deny with append-only journal), which
provides the correct structural template for LLM token/cost budget governance where P-46
confirms adk-rust has no native token/cost ceiling primitive.

## Preconditions

1. A `BudgetConfig` is configured in `GraphConfig.budget_config` for the run; the engine
   constructs a `BudgetPolicy` implementation from it (may be a composed chain of multiple
   policies). Absence of a `BudgetConfig` means the default Allow-all policy is applied
   silently — see BC-2.10.002 for the journal record in this case.
2. A `TokenUsage` struct is updated after every LLM call and tool invocation with cumulative
   token counts (prompt, completion, total) and estimated cost.
3. The execution engine has access to the `RunContext` (thread_id, run_id, sub-agent identity
   if applicable) for policy evaluation calls.

## Postconditions

1. After every LLM call, the execution engine calls `policy.evaluate(usage, context)` and
   receives a `PolicyDecision`.
2. After every tool invocation, the execution engine calls `policy.evaluate(usage, context)`
   and receives a `PolicyDecision`.
3. Each returned `PolicyDecision` is one of the three variants:
   - `PolicyDecision::Allow` — execution continues uninterrupted.
   - `PolicyDecision::Escalate { reason: String, current_usage: TokenUsage }` — execution
     suspends; the run transitions to `interrupted` via the HITL interrupt mechanism
     (BC-2.10.004).
   - `PolicyDecision::Deny { reason: String, current_usage: TokenUsage }` — engine dispatch
     is governed by `BudgetConfig::on_ceiling`: `Halt` → graceful halt (BC-2.10.003);
     `Escalate` → HITL interrupt (BC-2.10.004 PC2 hard-ceiling path); `Summarize` → final summarize
     call then `summary_halt` (BC-2.10.003 PC8).
4. Every policy evaluation — including `Allow` outcomes — is appended to the `EvidenceJournal`
   (BC-2.10.002). No evaluation is silently discarded.
5. When multiple policies are composed (policy chain), the most restrictive outcome wins:
   Deny > Escalate > Allow. The first Deny short-circuits the remaining chain.
6. Sub-agent runs (subgraph invocations) are evaluated against the sub-agent's own policy
   (from its `RunnableConfig`) independently of the parent run's policy.

## Invariants

- `BudgetPolicy::evaluate` is a pure, stateless function (takes snapshot, returns decision);
  no side effects inside `evaluate`. Side effects (journal write, interrupt trigger) are
  performed by the caller (the execution engine) after receiving the decision.
- A `BudgetPolicy` cannot mutate the graph state, execution context, or checkpoint store
  directly. Its only output is a `PolicyDecision`.
- Policy composition must be associative and deterministic: composing policy A then policy B
  with the same inputs produces the same result regardless of call-site ordering.
- The absence of a `BudgetPolicy` in `RunnableConfig` is equivalent to an always-`Allow` policy.
  This must be explicit in the `RunnableConfig` defaults documentation.

## Edge Cases

### EC-001: No BudgetPolicy configured (permissive default)
**Scenario:** A `RunnableConfig` is created without specifying a `BudgetPolicy`.
**Expected behavior:** The execution engine applies an implicit always-`Allow` policy.
An `EvidenceJournal` entry is still written for each evaluation point (with `policy: "default-allow"`
and `decision: Allow`) so that budget usage is observable even without a ceiling policy.

### EC-002: Composed policy chain — first policy Allow, second policy Deny
**Scenario:** Two policies are composed. For a given `TokenUsage`, policy 1 returns `Allow`,
policy 2 returns `Deny`.
**Expected behavior:** The composed result is `Deny`. Policy 2's decision wins per the
Deny > Escalate > Allow precedence rule. The `EvidenceJournal` records both evaluations and
the composed outcome.

### EC-003: Evaluation after tool invocation that produces no tokens
**Scenario:** A deterministic tool (no LLM call) returns a result. `TokenUsage` does not
change. The engine calls `policy.evaluate(usage, context)`.
**Expected behavior:** The policy evaluates the unchanged `TokenUsage` snapshot and returns
its decision. If the ceiling has not been reached, the result is `Allow`. The journal records
the evaluation at the tool boundary even though token counts did not change.

### EC-004: Sub-agent with a stricter policy than the parent
**Scenario:** Parent run has a soft ceiling (Escalate at 50k tokens). Sub-agent run has a
hard ceiling (Deny at 10k tokens). Sub-agent accumulates 12k tokens.
**Expected behavior:** Sub-agent policy evaluates to `Deny` (with `on_ceiling=Halt` in this
scenario); the sub-agent run halts. The parent run receives a structured error from the
sub-agent (not a panic). The parent's policy
is evaluated independently and may choose to continue, escalate, or deny the parent run.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | BudgetConfig with `soft_limit = 100_000`, `hard_limit = 200_000`; current usage = 50_000 tokens | `PolicyDecision::Allow`; journal entry written | Happy path — under soft limit |
| TV-002 | Same BudgetConfig; current usage = 110_000 tokens (exceeds soft limit) | `PolicyDecision::Escalate { reason: "soft limit exceeded", current_usage: ... }`; journal entry written | Escalate path — see BC-2.10.004 |
| TV-003 | Same BudgetConfig; current usage = 210_000 tokens (exceeds hard limit) | `PolicyDecision::Deny { reason: "hard limit exceeded", current_usage: ... }`; journal entry written | Deny path — see BC-2.10.003 |
| TV-004 | Composed policy chain: [SoftLimitPolicy(100k→Escalate), HardLimitPolicy(200k→Deny)]; usage = 110k | Escalate wins (first matching policy in chain by precedence) | Chain composition; most restrictive wins |
| TV-005 | Sub-agent run with Deny policy at 10k; sub-agent accumulates 12k | Sub-agent returns `Err(E-BUDGET-001 BudgetCeilingReached)`; parent run receives structured error, evaluates its own policy separately | Sub-agent independent evaluation |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BUDGET-01 | `BudgetPolicy::evaluate` is pure: same `(usage, context)` inputs always produce same `PolicyDecision` | Unit test (determinism assertion — call evaluate 100× with same args, assert identical results) | Phase 1 |
| VP-BUDGET-02 | Composed policy chain: Deny > Escalate > Allow precedence holds across all combinations | Unit test truth table — 3×3 combinations of two-policy chains | Phase 1 |

## Related BCs

- BC-2.10.002 — composes with: every evaluation call produces an EvidenceJournal entry (specified there)
- BC-2.10.003 — depends on: Deny + on_ceiling=Halt dispatches graceful halt (BC-2.10.003); Deny + on_ceiling=Summarize dispatches final summarize call then summary_halt (BC-2.10.003 PC8)
- BC-2.10.004 — depends on: PolicyDecision::Escalate (soft-ceiling) always triggers HITL interrupt; PolicyDecision::Deny + on_ceiling=Escalate also routes to HITL interrupt (BC-2.10.004 PC2 hard-ceiling path)
- BC-2.05.001 — related to: Escalate reuses the `interrupt()` mechanism defined there

## Architecture Anchors

- `ferrochain-core/src/budget.rs` — `BudgetPolicy` trait, `PolicyDecision` enum, `TokenUsage` struct, `RunContext` struct (definitions, per ADR-009 Option 3)
- `ferrochain-graph/src/budget/composed.rs` — `ComposedBudgetPolicy` with Deny > Escalate > Allow precedence
- `ferrochain-graph/src/scheduler.rs` (`graph::scheduler`) — evaluation call sites after each LLM call and tool invocation within `tick()`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BUDGET-01, VP-BUDGET-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-012 |
| Capability Anchor Justification | CAP-012 ("Budget Governance (Allow / Escalate / Deny; Cost Metering)") per capabilities-p0.md §CAP-012 — this BC specifies the `BudgetPolicy` trait's `evaluate` contract (the allow/escalate/deny decision), which is the primary governance primitive named in CAP-012 |
| L2 Domain Invariants | — |
| D17 Commitment | D17-Q4 — budget governance allow/escalate/deny policy trait, composable, append-only evidence journal; Domain B dark-factory holdout requires it |
| D18-P93-B Cost-Ceiling Scope | Cost-based ceilings (`BudgetConfig` with cost thresholds) are **not v1 scope**. CAP-012 "Cost Metering" is satisfied by `JournalEntry.token_usage.estimated_cost` in the `EvidenceJournal` (BC-2.10.002 PC2) — this provides cost observability and auditability. `BudgetConfig` v1 thresholds (`soft_limit`, `hard_limit`) are token counts (`u64`). A cost-based ceiling would require a `Decimal` or `f64` threshold field — not present in v1 spec; deferred to a future CAP-012 extension if required. (D18-P93-B, adjudicated 2026-07-17) |
| ADAPT Reference | adk-rust P-73 (adk-payments PaymentPolicyGuardrail: allow/escalate/deny, composable, append-only journal) provides the correct policy SHAPE; P-46 confirms adk-rust has no native token/cost ceiling primitive (gap that ferrochain must close) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-core (trait + types) / ferrochain-graph (engine) |
