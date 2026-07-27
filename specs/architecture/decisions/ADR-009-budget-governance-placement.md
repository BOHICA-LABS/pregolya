---
document_type: adr
level: L3
adr_id: "009"
slug: budget-governance-placement
title: "Budget Governance Engine Placement (D17-Q4): ferrochain-graph vs ferrochain-core"
status: accepted
date: 2026-07-14
producer: architect
timestamp: 2026-07-14T12:00:00Z
version: "1.3"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17]
supersedes: null
superseded_by: null
subsystems_affected: [SS-10]
changelog:
  - "1.3 (F-P95-01/D18-P84-A/2026-07-17): Reconcile budget-evaluation placement with BC canon. (1) Option 2 description: 'evaluated between super-steps' → 'evaluated per-LLM-call and per-tool-invocation within tick() (Collecting phase)'. (2) Engine call description: 'between super-steps (or after task dispatch)' → 'after each LLM call and tool invocation within tick() during Collecting (BC-2.10.001 PC1/PC2); halt dispatch waits for in-flight tasks to settle at super-step boundary (BC-2.10.003 EC-001)'. (3) Consequences: 'BudgetEngine::evaluate() between super-steps' → 'after each LLM call and tool invocation within tick() during Collecting (BC-2.10.001 PC1/PC2)'. Template structure: add date, subsystems_affected, superseded_by, supersedes frontmatter fields; add Rationale, Alternatives Considered, Source / Origin sections."
  - "1.2 (F-P61-02/Pass-61/2026-07-15): Rename `BudgetContext` → `RunContext` per BC-2.10.001 precondition 3 (fields: thread_id, run_id, sub-agent identity). Evaluate signature is now canon: `fn evaluate(&self, usage: TokenUsage, context: &RunContext) -> PolicyDecision`. Core-exports line updated: `RunContext` replaces `BudgetContext`. Name `BudgetContext` is retired."
  - "1.1 (F-P60-01/F-P60-03/Pass-60/2026-07-15): Rename `BudgetDecision` → `PolicyDecision` per BC-2.10.001–004 behavioral authority. Align evaluate signature to canon: `fn evaluate(&self, usage: TokenUsage, context: &BudgetContext) -> PolicyDecision`. Add `Escalate { reason: String, current_usage: TokenUsage }` and `Deny { reason: String, current_usage: TokenUsage }` payload fields. Add `TokenUsage` to ferrochain-core exported types. Name `BudgetDecision` is retired."
  - "1.0 (D17-Q4/2026-07-14): Initial decision: Option 3 (trait in core, engine in graph)."
---

# ADR-009: Budget Governance Engine Placement

**Status:** Accepted

## Context

D17-Q4 mandates budget governance (BudgetPolicy allow/escalate/deny, EvidenceJournal) as
Phase-1 BCs (BC-2.10.001–004). The question is whether the budget engine belongs in
ferrochain-core (pure primitives) or ferrochain-graph (graph execution concern).

Three options:
1. **ferrochain-core** — Budget as a standalone primitive; any Runnable can use it.
2. **ferrochain-graph** — Budget as a graph-execution concern; evaluated per-LLM-call and per-tool-invocation within `tick()` (Collecting phase).
3. **ferrochain-graph with BudgetPolicy trait in ferrochain-core** — Trait in core, engine in graph.

## Decision: BudgetPolicy Trait in ferrochain-core; Engine in ferrochain-graph

**Chosen:** Option 3 — split at the trait boundary.

`BudgetPolicy` is a public trait in `ferrochain-core`:
```rust
pub trait BudgetPolicy: Send + Sync {
    fn evaluate(&self, usage: TokenUsage, context: &RunContext) -> PolicyDecision; // pure; no async
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
- The engine is called by the graph orchestrator after each LLM call and tool invocation within `tick()` during Collecting (BC-2.10.001 PC1/PC2); halt dispatch waits for in-flight tasks to settle at the super-step boundary (BC-2.10.003 EC-001).

## Rationale

- `BudgetPolicy::evaluate()` is pure (no I/O, no side effects) → testable with unit/proptest.
- `EvidenceJournal` write is effectful → belongs in ferrochain-graph with the scheduler.
- Placing the trait in ferrochain-core allows non-graph `Runnable` implementations to use budget policies without a ferrochain-graph dep.
- Budget escalation (BC-2.10.004) triggers a HITL interrupt, which requires ferrochain-graph's interrupt queue — so the engine must be in ferrochain-graph anyway.
- Evaluation call sites (per-LLM-call, per-tool-invocation within `tick()`) live in the Collecting phase of the orchestrator loop, cleanly separated from BSP channel operations and reduction logic.

## Consequences

- `ferrochain-core` adds: `BudgetPolicy` trait, `RunContext`, `TokenUsage`, `PolicyDecision` types.
- `ferrochain-graph` adds: `BudgetEngine`, `EvidenceJournal`.
- `GraphConfig` gains a `budget_config: Option<BudgetConfig>` field.
- The orchestrator loop (ADR-001) calls `BudgetEngine::evaluate()` after each LLM call and tool invocation within `tick()` during Collecting (BC-2.10.001 PC1/PC2).
- BC-2.10.004 (escalate → HITL interrupt): `PolicyDecision::Escalate` causes the
  orchestrator to push an interrupt onto the HITL queue before the next super-step begins.
- Domain B holdout scenario (dark factory): budget ceiling halt is the primary mechanism
  for preventing runaway multi-day graphs.

## Alternatives Considered

- **Option 1 — ferrochain-core only:** Budget as a standalone primitive any Runnable can use. Rejected because budget escalation (BC-2.10.004) requires the HITL interrupt queue which is a ferrochain-graph concern; placing the engine in core would create an upward dependency.
- **Option 2 — ferrochain-graph only:** Budget as a graph-execution concern with both trait and engine in ferrochain-graph. Rejected because non-graph Runnables could not implement `BudgetPolicy` without depending on the full graph crate; trait belongs in core per ADR-009 Option 3 split.
- **Option 3 — split (chosen):** Trait in ferrochain-core; engine in ferrochain-graph. Satisfies purity boundary (trait is pure-core), crate layering (no upward dep), and HITL integration requirements.

## Source / Origin

- **D17-Q4** — budget governance (allow/escalate/deny policy trait, composable, append-only evidence journal) mandate; Phase-1 BCs BC-2.10.001–004.
- **BC-2.10.001 PC1/PC2** — evaluation call sites: after every LLM call and tool invocation within `tick()`.
- **BC-2.10.003 EC-001** — halt execution landing point: in-flight Collecting tasks settle; no new super-step; halt at super-step boundary.
- **ADR-001** — orchestrator loop that owns the call sites; budget evaluation is a Collecting-phase concern.
