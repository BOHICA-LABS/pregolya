---
document_type: adr
level: L3
adr_id: "009"
slug: budget-governance-placement
title: "Budget Governance Engine Placement (D17-Q4): ferrochain-graph vs ferrochain-core"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
version: "1.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17]
---

# ADR-009: Budget Governance Engine Placement

**Status:** Accepted

## Context

D17-Q4 mandates budget governance (BudgetPolicy allow/escalate/deny, EvidenceJournal) as
Phase-1 BCs (BC-2.10.001–004). The question is whether the budget engine belongs in
ferrochain-core (pure primitives) or ferrochain-graph (graph execution concern).

Three options:
1. **ferrochain-core** — Budget as a standalone primitive; any Runnable can use it.
2. **ferrochain-graph** — Budget as a graph-execution concern; evaluated between super-steps.
3. **ferrochain-graph with BudgetPolicy trait in ferrochain-core** — Trait in core, engine in graph.

## Decision: BudgetPolicy Trait in ferrochain-core; Engine in ferrochain-graph

**Chosen:** Option 3 — split at the trait boundary.

`BudgetPolicy` is a public trait in `ferrochain-core`:
```rust
pub trait BudgetPolicy: Send + Sync {
    fn evaluate(&self, usage: TokenUsage, context: &BudgetContext) -> PolicyDecision; // pure; no async
}
pub enum PolicyDecision {
    Allow,
    Escalate { reason: String, current_usage: TokenUsage },
    Deny    { reason: String, current_usage: TokenUsage },
}
```

`BudgetEngine` (evaluation + EvidenceJournal) lives in `ferrochain-graph::budget`:
- `BudgetEngine::evaluate()` calls `BudgetPolicy::evaluate()` (pure) and records to `EvidenceJournal`.
- `EvidenceJournal` is an append-only async writer; effectful (I/O).
- The engine is called by the graph orchestrator between super-steps (or after task dispatch).

**Rationale:**
- `BudgetPolicy::evaluate()` is pure (no I/O, no side effects) → testable with unit/proptest.
- `EvidenceJournal` write is effectful → belongs in ferrochain-graph with the scheduler.
- Placing the trait in ferrochain-core allows non-graph `Runnable` implementations to use budget policies without a ferrochain-graph dep.
- Budget escalation (BC-2.10.004) triggers a HITL interrupt, which requires ferrochain-graph's interrupt queue — so the engine must be in ferrochain-graph anyway.

## Consequences

- `ferrochain-core` adds: `BudgetPolicy` trait, `BudgetContext`, `TokenUsage`, `PolicyDecision` types.
- `ferrochain-graph` adds: `BudgetEngine`, `EvidenceJournal`.
- `GraphConfig` gains a `budget_config: Option<BudgetConfig>` field.
- The orchestrator loop (ADR-001) calls `BudgetEngine::evaluate()` between super-steps.
- BC-2.10.004 (escalate → HITL interrupt): `PolicyDecision::Escalate` causes the
  orchestrator to push an interrupt onto the HITL queue before the next super-step begins.
- Domain B holdout scenario (dark factory): budget ceiling halt is the primary mechanism
  for preventing runaway multi-day graphs.

## Changelog

| Version | Date | Author | References | Summary |
|---------|------|--------|------------|---------|
| 1.0 | 2026-07-14 | architect | D17-Q4 | Initial decision: Option 3 (trait in core, engine in graph). |
| 1.1 | 2026-07-15 | architect | F-P60-01, F-P60-03, Pass-60 adjudication | Rename `BudgetDecision` → `PolicyDecision` per BC-2.10.001–004 behavioral authority. Align evaluate signature to canon: `fn evaluate(&self, usage: TokenUsage, context: &BudgetContext) -> PolicyDecision`. Add `Escalate { reason: String, current_usage: TokenUsage }` and `Deny { reason: String, current_usage: TokenUsage }` payload fields. Add `TokenUsage` to ferrochain-core exported types. Name `BudgetDecision` is retired. |
