---
document_type: adr
level: L3
adr_id: "018"
slug: per-tool-call-approval-hook
title: "First-Class Per-Tool-Call Approval Hook: PreToolCallHook Trait, Pre-Invoke Dispatch, and Retry/Approval Ordering"
status: accepted
date: "2026-07-23"
producer: architect
timestamp: 2026-07-23T00:00:00Z
version: "1.4"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D23]
supersedes: null
superseded_by: null
subsystems_affected: [SS-05, SS-06, SS-16]
changelog:
  - "1.4 (burst-242/2026-07-23): Fix-242 Command-notation sweep — convert 4 residual enum-variant form Command::Resume(...) occurrences (Decision 1 doc comment, Decision 3 step 6, Decision 3 on-resume paragraph, Decision 4 resume paragraph) to canonical struct kwarg form Command(resume=...). Canonical form per BC-2.05.004 v1.5 + F-P120-01 adjudication."
  - "1.3 (burst-239/2026-07-23): F-P139-05 — reconcile frontmatter date/timestamp mismatch: date corrected from 2026-07-22 to 2026-07-23, matching timestamp 2026-07-23T00:00:00Z (burst-238 canonical date per ARCH-INDEX v1.9)."
  - "1.2 (burst-238/2026-07-23): Stale-handoff sweep — resolve 4 stale PO-must obligations: (1) BC-2.05.008 authored (skip-hook-on-resume invariant, burst-229, active); (2) BC-2.06.004/005 authored (streaming event variants, burst-229, active); (3) BC-2.08.010 v1.1 amended (action_risk macro param, burst-229, active); (4) Status section updated to reflect all BCs delivered and VP-011 seeded."
  - "1.1 (burst-233/2026-07-22): F-P133-07 sibling sweep (TD-VSDD-060) — remove stale 'VP-011 candidate' labels (VP-011 seeded burst-232, Kani P0). Two sites updated: §Decision 2 dispatch sequence step 4 Deny path, and §Rationale summary line."
  - "1.0 (D23/2026-07-22): Initial ADR — per-tool-call approval hook replacing the 2-node-per-tool workaround identified in domain-e-agentic-coding-assistant.md §3 item 5 / §6 item 1."
---

# ADR-018: First-Class Per-Tool-Call Approval Hook

**Status:** Accepted — D23 authority (2026-07-22)

## Context

`interrupt()` (BC-2.05.001) fires at **node boundaries** — between super-steps in the BSP
execution model. Fine-grained per-tool-call approval requires structuring each tool
dispatch as two separate nodes: a "reason" node proposes the call, a node-boundary
interrupt suspends, then an "execute" node invokes the tool. For a ReAct loop with N
sequential tool calls this produces a 2N-node graph — verbose, error-prone, and hostile
to dynamic tool dispatch via the Send API.

Domain E (agentic coding CLI, domain-e-agentic-coding-assistant.md §3 item 5, §6 item 1)
explicitly classifies the current surface as DEGRADED and identifies a "first-class
pre-tool interrupt hook at sub-node granularity" as the closure path. D23 mandates this
closure in v1.

The existing risk-tiered interrupt surface (BC-2.05.006 / SS-05) governs who may approve
a parked run, but operates at node granularity, not tool-dispatch granularity. CAP-006
carries no tool-dispatch hook mechanism.

## Decision 1 — `PreToolCallHook` Trait in `ferrochain-graph::hitl`

A new trait `PreToolCallHook` is added to `ferrochain-graph::hitl` (NOT `ferrochain-core`):

```rust
/// Read-only preview of a tool invocation about to be dispatched.
#[non_exhaustive]
pub struct ToolCallPreview {
    pub tool_name: String,
    pub tool_args: serde_json::Value,
    /// Risk tier from #[tool(action_risk = ...)] annotation, if set.
    pub action_risk: Option<ActionRisk>,
}

/// Decision produced by a PreToolCallHook.
#[non_exhaustive]
pub enum PreToolDecision {
    Approve,
    Deny { reason: String },
    /// Allow the tool with modified arguments (human narrowed the bash command, etc.).
    Edit { modified_args: serde_json::Value },
    /// Suspend via interrupt() and wait for a human decision delivered via Command(resume=PreToolDecision).
    PendingHumanApproval { prompt: Option<String> },
}

/// Interrupt payload produced internally when PendingHumanApproval is returned.
#[non_exhaustive]
pub struct ToolApprovalRequest {
    pub preview: ToolCallPreview,
    pub prompt: Option<String>,
}

#[async_trait]
pub trait PreToolCallHook: Send + Sync {
    async fn pre_invoke(
        &self,
        preview: &ToolCallPreview,
        run_ctx: &RunContext,
    ) -> PreToolDecision;
}
```

**Default implementation:** `AlwaysApprovePolicy` always returns `PreToolDecision::Approve`
without I/O. Existing graphs that do not configure a hook see identical behaviour to today.

**Trait placement rationale (graph not core):** The trait-in-core pattern (ADR-009,
ADR-012, ADR-014) is driven by dependency inversion — a downstream crate needs the trait
without depending on ferrochain-graph. `PreToolCallHook` has no such consumer: it is
exclusively a graph-configuration concern. Putting it in ferrochain-core would add an
orphan definitions module with no dependency-inversion benefit, violating the "put it
where it is used" principle. `ActionRisk` (used in `ToolCallPreview`) already lives in
`ferrochain-graph::hitl::action_risk`; no relocation is needed.

## Decision 2 — Hook Registration in `GraphConfig`

`GraphConfig` (in `ferrochain-graph`) gains one new optional field:

```rust
pub struct GraphConfig {
    // ... existing fields unchanged ...
    pub pre_tool_hook: Option<Arc<dyn PreToolCallHook>>,
}
```

`None` → `AlwaysApprovePolicy` semantics (backward compatible). The hook is
graph-scoped, not run-scoped: it governs all runs on the graph, consistent with how
`RiskGatePolicy` is applied.

## Decision 3 — Dispatch in `graph::hitl::pre_tool_dispatch`

The tool dispatch path in `graph::scheduler` calls
`graph::hitl::pre_tool_dispatch(hook, preview, run_ctx).await` before every tool
execution. The function:

1. No hook configured → return `Approve` immediately.
2. `hook.pre_invoke(preview, run_ctx).await`.
3. `Approve` → proceed to tool invocation.
4. `Deny { reason }` → construct `ToolOutput::Error(reason)`; do **not** invoke the tool;
   return error to model context. This path MUST be fail-closed — VP-011 (Kani P0, seeded burst-232).
5. `Edit { modified_args }` → replace `tool_args` with `modified_args`; proceed.
6. `PendingHumanApproval { prompt }` → call `interrupt(ToolApprovalRequest { preview, prompt })`
   internally (BC-2.05.001 machinery); on resume, the caller delivers
   `Command(resume=PreToolDecision)`. Apply the resumed decision via rules 3–5 above.

**On resume semantics:** The engine captures the pending `ToolCallPreview` in the
checkpoint. On `Command(resume=decision)`, the engine applies the decision directly
without re-calling `pre_invoke` (the hook is skipped for the resumed dispatch). BC-2.05.008
authors this "skip-hook-on-resume" invariant as an extension to SS-05 (authored burst-229, active).

## Decision 4 — `PendingHumanApproval` Reuses Existing Interrupt Machinery

`PendingHumanApproval` issues `interrupt()` internally — the existing BC-2.05.001
suspension and durable persistence contract applies unchanged. `ToolApprovalRequest` is
serialized to msgpack via the existing checkpoint format (ADR-002). Mid-approval resume
survives process restart exactly as standard interrupts do. No new suspension mechanism is
introduced.

`Command(resume=PreToolDecision)` delivers the decision. `PreToolDecision` is
`#[non_exhaustive]`; future variants (e.g., `EditAndRetry`) are addable without breaking
existing hook implementations.

## Decision 5 — Streaming Events `tool_approval_request` / `tool_approval_resolved`

When `PendingHumanApproval` is returned (before the internal interrupt is issued), the
engine emits a new streaming event variant `tool_approval_request` carrying
`{ tool_name, tool_args, action_risk, run_id, prompt }`. A complementary
`tool_approval_resolved` event is emitted when the resume decision arrives.

The existing 12-variant streaming event taxonomy (BC-2.06.001 v1.4) grows to 14 variants.
BC-2.06.004 and BC-2.06.005 author these two new variants (authored burst-229, active).

## Decision 6 — Retry / Approval Ordering (CAP-018 Wave Promotion Interaction)

The ordered call sequence for each tool dispatch is:

```
circuit_breaker.check(tool_name)         // fast reject if breaker is open
  → pre_tool_dispatch(hook, preview)     // approval gate (may suspend)
    → tool.invoke(args)                  // actual tool execution
      → retry_policy.record(result)      // update per-tool counter on failure
```

Circuit breaker check is first: if the breaker is open, no approval dialog is presented.
Each retry attempt flows through `pre_tool_dispatch` independently:
- Auto-approve policies (`AlwaysApprovePolicy`, ReadOnly tier) see retries transparently.
- Interactive policies re-prompt on each retry — giving the human the ability to deny after
  observing the first failure's error output.

**`#[tool(action_risk = ...)]` macro extension (ADR-008):** The `#[tool]` proc-macro gains
an optional `action_risk` parameter populating `ToolCallPreview.action_risk` at dispatch
time. If absent, `action_risk = None`. BC-2.08.010 v1.1 amended to include the
`action_risk` attribute parameter (burst-229, active).

## Rationale

The 2-node-per-tool workaround is O(N) in graph node count and requires application
authors to know and implement an advanced LangGraph structural pattern. Every coding agent
built on ferrochain would independently re-implement the same boilerplate. First-class
support eliminates this friction and ensures the fail-closed Deny property is provable
at the framework level rather than repeated in each application.

Placing the hook in `ferrochain-graph::hitl` (Decision 1) keeps the trait alongside
`ActionRisk`, `RiskGatePolicy`, and `GraphConfig` where it belongs architecturally.
`ferrochain-core` definitions-only modules are justified only by dependency inversion
(ADR-009 Option 3 precedent); no such inversion exists here.

Reusing `interrupt()` internally (Decision 4) is the correct choice over a new suspension
primitive: the existing checkpoint, FIFO delivery, and resume machinery (BC-2.05.001
through BC-2.05.004) already handles all the edge cases (process restart, partial-step
durability, FIFO ordering). Introducing a second suspension mechanism would duplicate this
work and add new failure modes.

Retry-outside-approval (Decision 6) is the semantically correct ordering: a tool that
fails should not silently retry inside the approval gate; the human who approved the first
attempt should also have the chance to deny the second. Circuit breaker first avoids
presenting a dialog for a tool the framework has already classified as persistently failing.

## Alternatives Considered

- **Option A — Document the 2-node pattern (status quo):** Each application implements
  two-node tool dispatch manually. Rejected: scales poorly (40-node graph for a 20-tool
  loop), error-prone, duplicates boilerplate across every ferrochain-based coding agent.

- **Option B — New streaming event only, no hook:** Emit `tool_approval_request` and let
  the application issue its own interrupt. Rejected: application still re-implements the
  interrupt plumbing; no reduction in structural verbosity; fail-closed Deny becomes an
  application-layer responsibility that is not provable at the framework level.

- **Option C — `PreToolCallHook` in `ferrochain-core`:** Trait in core following the
  ADR-009/ADR-012/ADR-014 precedent. Rejected: the dependency-inversion motivation for
  trait-in-core does not apply here — no crate needs `PreToolCallHook` without already
  depending on `ferrochain-graph`. Putting it in core creates an orphan definitions module
  with no benefit.

- **Option D — Risk-tiered interrupt at node boundary (BC-2.05.006):** Extend BC-2.05.006
  with tool-dispatch semantics, keeping node-level granularity. Rejected: this is exactly
  the 2-node workaround restated as a BC; it does not eliminate the structural verbosity.

## Source / Origin

- **D23 authority:** D23 decisions log entry (STATE.md) — five Domain-E parity capabilities
  elevated to v1 scope; item 1 is "first-class per-tool-call HITL hook."
- **Domain E forcing function:** domain-e-agentic-coding-assistant.md §3 item 5 and §6
  table row "Per-tool-call interactive HITL (fine-grained)" — DEGRADED classification
  with closure path "first-class pre-tool interrupt hook at sub-node granularity."
- **BC-2.05.001–006:** existing HITL machinery reused by Decision 4 (interrupt/resume).
- **ADR-009:** precedent for trait-in-core vs trait-in-consuming-crate decision analysis.
- **NE-09 (CAP-018):** tool-retry termination guarantee — ordering in Decision 6 ensures
  retry counter is bounded even with per-attempt approval.

## Consequences

### Positive

- Application authors build 20-tool ReAct coding agents with a single hook, not a
  40-node graph.
- Fail-closed `Deny` is a pure routing decision provable by Kani (VP-011, Kani P0, seeded burst-232).
- `PendingHumanApproval` reuses the existing interrupt/resume machinery — zero new
  failure modes in the checkpoint path.
- Interactive approval survives process restart transparently (BC-2.05.001 durability).
- `AlwaysApprovePolicy` default preserves full backward compatibility; existing graphs
  are unaffected.

### Negative / Trade-offs

- `ToolApprovalRequest` is a new msgpack-serialized interrupt payload type; BC-2.04.002
  checkpoint format must handle it.
- Two new streaming event variants (14 total) require PO BC amendments to BC-2.06.001
  or new SS-06 BCs.
- The `#[tool(action_risk = ...)]` macro extension requires amending BC-2.08.010 and the
  `ferrochain-macros` implementation.
- "Skip-hook-on-resume" is a novel invariant differing from standard BC-2.05.003
  node-re-execute semantics; BC-2.05.008 authors it explicitly (authored burst-229, active).
- `PreToolDecision::Edit` allows argument modification by humans — the engine must
  validate that `modified_args` remains a valid JSON object before invoking the tool.

### Status as of 2026-07-23

Architecture decision accepted. No implementation yet (Phase 1). All BC obligations satisfied: BC-2.05.008 (skip-hook-on-resume invariant), BC-2.06.004/005 (streaming event variants), BC-2.08.010 v1.1 (`action_risk` macro param) — all authored burst-229. VP-011 seeded burst-232 (Kani P0). Implementation deferred to Phase 3.
