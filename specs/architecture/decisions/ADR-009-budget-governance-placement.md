---
document_type: adr
level: L3
adr_id: "009"
slug: budget-governance-placement
title: "Budget Governance Engine Placement (D17-Q4): ferrochain-graph vs ferrochain-core"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17]
---

# ADR-009: Budget Governance Engine Placement

**Status:** Proposed (D17-Q4; finalizable)

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
    fn evaluate(&self, ctx: &BudgetContext) -> BudgetDecision; // pure; no async
}
pub enum BudgetDecision { Allow, Escalate, Deny }
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

- `ferrochain-core` adds: `BudgetPolicy` trait, `BudgetContext`, `BudgetDecision` types.
- `ferrochain-graph` adds: `BudgetEngine`, `EvidenceJournal`.
- `GraphConfig` gains a `budget_config: Option<BudgetConfig>` field.
- The orchestrator loop (ADR-001) calls `BudgetEngine::evaluate()` between super-steps.
- BC-2.10.004 (escalate → HITL interrupt): `BudgetDecision::Escalate` causes the
  orchestrator to push an interrupt onto the HITL queue before the next super-step begins.
- Domain B holdout scenario (dark factory): budget ceiling halt is the primary mechanism
  for preventing runaway multi-day graphs.
