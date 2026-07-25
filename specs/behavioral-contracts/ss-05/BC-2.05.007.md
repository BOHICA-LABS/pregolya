---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.007
version: "1.3"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-05
capability: CAP-034
crate: ferrochain-graph
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-23T00:00:00Z
di_anchors: [DI-014]
vp_seed: true
vp_id: VP-011
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 per-tool-call approval hook, SS-05 extension. VP-011 Kani P0 seed."
  - "1.1 (burst-234/F-P134-03/2026-07-22): Add reciprocal Related BCs entry for BC-2.08.010 — the `#[tool]` proc-macro sets `action_risk` which is consumed by this BC's `pre_tool_dispatch` via `ToolCallPreview.action_risk`. BC-2.08.010 v1.2 corrected its mis-anchor (BC-2.05.004 → this BC); reciprocal link added here per anchor-back rule."
  - "1.2 (burst-236/OBS-P136-A/2026-07-23): VP Anchors and Traceability VP Registration updated: stale 'ARCH-INDEX D23 candidate — architect to assign VP-INDEX entry' prose replaced with 'assigned in VP-INDEX v1.5 as VP-011' (VP-INDEX v1.5 burst-232 seeded VP-011 Kani P0)."
  - "1.3 (F-P142-03, burst-242, 2026-07-23): Sweep Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority and F-P120-01 adjudication. PC-4 updated. Zero Command:: enum-variant residue remains in live body text."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-034
  - architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "d4d38b2"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.007: PreToolCallHook Dispatch — pre_invoke Contract; Approve/Deny/Edit/PendingHumanApproval; Fail-Closed Deny (VP-011 Kani Seed)

## Description

`graph::hitl::pre_tool_dispatch` is called before EVERY tool invocation in the graph
scheduler. It consults the `PreToolCallHook` (if configured in `GraphConfig.pre_tool_hook`)
and routes based on the returned `PreToolDecision`. The four decision branches are: `Approve`
(proceed immediately), `Deny { reason }` (construct `ToolOutput::Error(reason)` without
invoking the tool — fail-closed), `Edit { modified_args }` (replace tool_args then proceed),
and `PendingHumanApproval { prompt }` (issue internal interrupt via BC-2.05.001 machinery
and suspend). The default hook is `AlwaysApprovePolicy`; existing graphs without a configured
hook see no behavior change. The fail-closed `Deny` branch is the VP-011 Kani P0 candidate:
under no code path does a `Deny` decision allow the tool to execute.

## Preconditions

1. The graph scheduler is executing a tool invocation for tool `T` with args `A`.
2. `GraphConfig.pre_tool_hook` is either:
   - `None` → `AlwaysApprovePolicy` semantics apply (Approve returned immediately, no I/O).
   - `Some(Arc<dyn PreToolCallHook>)` → `hook.pre_invoke(&preview, &run_ctx).await` is called.
3. `ToolCallPreview { tool_name: T.name(), tool_args: A, action_risk: T.action_risk() }` is
   constructed read-only before the call; `action_risk` is `Some(tier)` if the tool is
   annotated with `#[tool(action_risk = ...)]`, `None` otherwise.
4. The hook implementation is `Send + Sync`; awaiting it does not block the Tokio thread pool.

## Postconditions

1. **Approve:** `pre_invoke` returns `PreToolDecision::Approve`. `pre_tool_dispatch` returns
   `Ok(A)` (original args unchanged). The scheduler proceeds to `tool.invoke(A)`.
2. **Deny:** `pre_invoke` returns `PreToolDecision::Deny { reason }`. `pre_tool_dispatch`
   constructs `ToolOutput::Error(reason)` and returns it WITHOUT calling `tool.invoke(A)`.
   The tool is not invoked. The `ToolOutput::Error` is delivered to the model's context as
   the tool result. This path is fail-closed: the tool NEVER executes when Deny is returned.
3. **Edit:** `pre_invoke` returns `PreToolDecision::Edit { modified_args }`. The scheduler
   validates that `modified_args` is a valid JSON object (non-null); if validation fails,
   falls back to Deny with reason "invalid modified_args". If valid, proceeds to
   `tool.invoke(modified_args)`.
4. **PendingHumanApproval:** `pre_invoke` returns `PreToolDecision::PendingHumanApproval { prompt }`.
   `pre_tool_dispatch` issues `interrupt(ToolApprovalRequest { preview, prompt })` via
   BC-2.05.001 machinery. The run is suspended. On resume, the delivered
   `Command(resume=PreToolDecision)` is applied via rules PC-1 through PC-3. See
   BC-2.05.008 for the skip-hook-on-resume invariant.
5. **Hook error (panic or `Err`):** If `hook.pre_invoke(...)` panics or returns an error,
   `pre_tool_dispatch` treats this as `Deny { reason: "hook error: <detail>" }`. The hook
   is fail-closed under all error conditions.
6. **No hook configured:** `pre_tool_dispatch` returns `Ok(A)` immediately (equivalent to
   Approve) without calling `pre_invoke`. Existing graphs unaffected.

## Invariants

- **Fail-closed Deny (VP-011 Kani seed):** `PreToolDecision::Deny` ALWAYS results in
  `ToolOutput::Error(reason)` being returned WITHOUT invoking the tool. Under no control flow
  path does a Deny decision allow tool execution. This is a pure routing decision provable
  by Kani: the Deny branch contains no call to `tool.invoke`.
- `pre_tool_dispatch` is called for EVERY tool invocation — there is no bypass, no
  tool-whitelist that skips the hook.
- Hook failure (panic or error) is treated as Deny, not Approve. This is the fail-closed
  safety property.
- `AlwaysApprovePolicy` is the default; the behavior change is opt-in via `GraphConfig`.
- **DI-014 (No Silent Swallowing):** `ToolOutput::Error(reason)` is returned to the model
  context on Deny; the Deny reason is never silently discarded.
- **Retry ordering (ADR-018 Decision 6):** The call sequence per tool invocation is:
  `circuit_breaker.check(tool_name)` → `pre_tool_dispatch(hook, preview)` →
  `tool.invoke(args)` → `retry_policy.record(result)`. Each retry attempt invokes
  `pre_tool_dispatch` independently.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Hook returns Deny; tool was BashTool | `ToolOutput::Error(reason)` — BashTool NOT executed; no subprocess spawned |
| EC-002 | Hook panics inside pre_invoke | Treated as Deny with reason "hook error: <panic detail>"; tool not invoked |
| EC-003 | Hook returns Edit with modified_args that is not a JSON object (e.g., a JSON string) | Fallback to Deny with reason "invalid modified_args"; tool not invoked |
| EC-004 | AlwaysApprovePolicy (default, no hook configured) | Approve returned immediately; no I/O; tool invoked with original args |
| EC-005 | Hook returns PendingHumanApproval; process restarts before resume | BC-2.05.001 interrupt machinery handles process restart; ToolApprovalRequest durable in checkpoint |
| EC-006 | ReadOnly tool (e.g., ReadFileTool) with hook returning Deny | Same Deny semantics apply — ReadOnly risk does not bypass the hook |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | Hook returns Approve; tool `echo_tool` | `ToolOutput::Text("echo: ...")` — tool invoked normally | happy-path (approve) |
| TV-002 | Hook returns `Deny { reason: "not allowed" }` | `ToolOutput::Error("not allowed")` — tool NOT invoked | deny (fail-closed) |
| TV-003 | Hook returns `Edit { modified_args: {"cmd": "ls"} }` where original was `{"cmd": "rm -rf /"}` | Tool invoked with `{"cmd": "ls"}` — args replaced | edit path |
| TV-004 | Hook returns `Edit { modified_args: "not-an-object" }` | Fallback to Deny — `ToolOutput::Error("invalid modified_args")` | edit-validation |
| TV-005 | No hook configured (GraphConfig.pre_tool_hook = None) | Tool invoked with original args; no pre_invoke call | default (no hook) |
| TV-006 | Hook panics | `ToolOutput::Error("hook error: ...")` — tool not invoked | fail-closed (panic) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-011 (Kani P0 candidate) | PreToolDecision::Deny never results in tool.invoke being called — pure routing guarantee | Kani exhaustive proof: Deny branch has no call to invoke; no side-channel to tool execution |
| VP-2.05.007-B | Hook panic treated as Deny (fail-closed); tool not invoked | Unit test: hook impl that panics; assert ToolOutput::Error returned |
| VP-2.05.007-C | Edit path validates modified_args is JSON object; falls back to Deny if not | Unit test: hook returns Edit with invalid args; assert ToolOutput::Error |

## Related BCs

- BC-2.05.001 — depends on: interrupt() machinery reused for PendingHumanApproval path
- BC-2.05.006 — related to: ActionRisk tiers feed ToolCallPreview.action_risk; risk-tiered HITL composes with PreToolCallHook
- BC-2.05.008 — depends on: skip-hook-on-resume invariant (this BC's PendingHumanApproval path → BC-2.05.008)
- BC-2.16.001 — related to: retry ordering — each retry attempt invokes pre_tool_dispatch independently
- BC-2.23.005 — related to: BashTool High risk; ADR-020 Decision 4 retry-approval ordering
- BC-2.08.010 — composes with: `#[tool(action_risk = ...)]` macro attribute produces the `action_risk()` value that this BC's `pre_tool_dispatch` receives via `ToolCallPreview.action_risk`; the declared risk tier is the hook's primary input for approve/deny/edit decisions

## Architecture Anchors

- `architecture/decisions/ADR-018-per-tool-call-approval-hook.md` — Decision 1 (PreToolCallHook trait in ferrochain-graph::hitl), Decision 2 (GraphConfig.pre_tool_hook), Decision 3 (pre_tool_dispatch dispatch logic — 6-step sequence), Decision 6 (retry-approval ordering)
- `architecture/module-decomposition.md` — SS-05, `ferrochain-graph / hitl` module
- `architecture/verification-architecture.md` — VP-011 (D23 candidate)

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-05 extension story]_

## VP Anchors

- VP-011 (assigned in VP-INDEX v1.5 as VP-011 — Kani P0; ferrochain-graph `deny_excludes_tool_invocation`)
- VP-2.05.007-B
- VP-2.05.007-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-034 |
| Capability Anchor Justification | CAP-034 ("Per-Tool-Call Interactive Approval Hook (PreToolCallHook / PreToolDecision)") per capabilities-p1-p2.md §CAP-034 — this BC specifies the pre_tool_dispatch dispatch contract including all four PreToolDecision branches, fail-closed Deny invariant, AlwaysApprovePolicy default, hook failure semantics, and retry-ordering that CAP-034 defines as the framework-level per-tool-call approval primitive |
| L2 Domain Invariants | DI-014 (Error Propagation — Deny reason surfaced in ToolOutput::Error; never silently discarded) |
| Architecture Authority | ADR-018 Decisions 1, 2, 3, and 6 (trait placement, GraphConfig registration, dispatch logic, retry ordering) |
| Binding Decisions | D23 (per-tool-call approval hook mandate, SS-05 extension) |
| VP Registration | VP-011 (assigned in VP-INDEX v1.5 as VP-011 — Kani P0; ferrochain-graph `deny_excludes_tool_invocation`) |
| Module | ferrochain-graph / hitl |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + Kani (VP-011) |
