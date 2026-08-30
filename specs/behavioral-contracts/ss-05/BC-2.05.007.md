---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.007
version: "1.9"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-05
capability: CAP-034
crate: pregolya-graph
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-08-24T00:00:00Z
di_anchors: [DI-014]
vp_seed: true
vp_id: VP-011
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 per-tool-call approval hook, SS-05 extension. VP-011 Kani P0 seed."
  - "1.1 (burst-234/F-P134-03/2026-07-22): Add reciprocal Related BCs entry for BC-2.08.010 — the `#[tool]` proc-macro sets `action_risk` which is consumed by this BC's `pre_tool_dispatch` via `ToolCallPreview.action_risk`. BC-2.08.010 v1.2 corrected its mis-anchor (BC-2.05.004 → this BC); reciprocal link added here per anchor-back rule."
  - "1.2 (burst-236/OBS-P136-A/2026-07-23): VP Anchors and Traceability VP Registration updated: stale 'ARCH-INDEX D23 candidate — architect to assign VP-INDEX entry' prose replaced with 'assigned in VP-INDEX as VP-011' (VP-INDEX v1.5 burst-232 seeded VP-011 Kani P0)."
  - "1.3 (F-P142-03, burst-242, 2026-07-23): Sweep Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority and F-P120-01 adjudication. PC-4 updated. Zero Command:: enum-variant residue remains in live body text."
  - "1.4 (fix-burst-287/TD-VSDD-091/2026-08-01): VP-INDEX version pin removed. §VP Anchors and §Traceability VP Registration: 'VP-INDEX v1.5 as' → 'VP-INDEX as' (plain prose, no §-anchor introduced). verify-no-version-pins.sh PASS."
  - "1.5 (fix-burst-P2A-010/F-P2A010-08/2026-08-20): Add PC-7 (Pure Routing Core — VP-011 proof surface): formally define `route_pre_tool_decision`, `shield_hook_result`, and `DispatchOutcome` as required named items in `graph::hitl`. These are the VP-011 Kani proof targets; Kani 0.67.0 cannot target `pre_tool_dispatch` directly (async), so pure extraction is required. Update §Invariants fail-closed Deny text to name `route_pre_tool_decision`. Update §Verification Properties VP-011 row to reference the pure functions and DispatchOutcome by name."
  - "1.6 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.23 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.7 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.8 (P2A-044 F-06/2026-08-24): P2A-044 F-06: compressed-ordinal citations normalized to stable tags."
  - "1.9 (round-46/SEC-008-class-audit/2026-08-30): catch_unwind class-audit closure — {INV-003} and TV-006. {INV-003}: async panic-catch mechanism specified: hook.pre_invoke is wrapped in FutureExt::catch_unwind(AssertUnwindSafe(...)); panic during .await polling caught and converted to Deny via shield_hook_result ({PC-007}); synchronous std::panic::catch_unwind cannot catch it. SEC-008 build-profile dependency note added (canonical workspace-root form): AUTHORITATIVE pin is workspace-root [profile.release] governing pregolya-server binary; library-member [profile.release] panic override silently ignored by Cargo; panic=\"abort\" voids catch (CWE-248/703). TV-006 Notes: async catch mechanism and SEC-008 note added. R05 gate (catch_unwind implies SEC-008 note) satisfied — zero remaining BC-layer catch_unwind-without-SEC-008 sites in this BC."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-034
  - architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "fd9ce03"
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

1. {PRE-001} The graph scheduler is executing a tool invocation for tool `T` with args `A`.
2. {PRE-002} `GraphConfig.pre_tool_hook` is either:
   - `None` → `AlwaysApprovePolicy` semantics apply (Approve returned immediately, no I/O).
   - `Some(Arc<dyn PreToolCallHook>)` → `hook.pre_invoke(&preview, &run_ctx).await` is called.
3. {PRE-003} `ToolCallPreview { tool_name: T.name(), tool_args: A, action_risk: T.action_risk() }` is
   constructed read-only before the call; `action_risk` is `Some(tier)` if the tool is
   annotated with `#[tool(action_risk = ...)]`, `None` otherwise.
4. {PRE-004} The hook implementation is `Send + Sync`; awaiting it does not block the Tokio thread pool.

## Postconditions

1. {PC-001} **Approve:** `pre_invoke` returns `PreToolDecision::Approve`. `pre_tool_dispatch` returns
   `Ok(A)` (original args unchanged). The scheduler proceeds to `tool.invoke(A)`.
2. {PC-002} **Deny:** `pre_invoke` returns `PreToolDecision::Deny { reason }`. `pre_tool_dispatch`
   constructs `ToolOutput::Error(reason)` and returns it WITHOUT calling `tool.invoke(A)`.
   The tool is not invoked. The `ToolOutput::Error` is delivered to the model's context as
   the tool result. This path is fail-closed: the tool NEVER executes when Deny is returned.
3. {PC-003} **Edit:** `pre_invoke` returns `PreToolDecision::Edit { modified_args }`. The scheduler
   validates that `modified_args` is a valid JSON object (non-null); if validation fails,
   falls back to Deny with reason "invalid modified_args". If valid, proceeds to
   `tool.invoke(modified_args)`.
4. {PC-004} **PendingHumanApproval:** `pre_invoke` returns `PreToolDecision::PendingHumanApproval { prompt }`.
   `pre_tool_dispatch` issues `interrupt(ToolApprovalRequest { preview, prompt })` via
   BC-2.05.001 machinery. The run is suspended. On resume, the delivered
   `Command(resume=PreToolDecision)` is applied via rules PC-001 through PC-003. See
   BC-2.05.008 for the skip-hook-on-resume invariant.
5. {PC-005} **Hook error (panic or `Err`):** If `hook.pre_invoke(...)` panics or returns an error,
   `pre_tool_dispatch` treats this as `Deny { reason: "hook error: <detail>" }`. The hook
   is fail-closed under all error conditions.
6. {PC-006} **No hook configured:** `pre_tool_dispatch` returns `Ok(A)` immediately (equivalent to
   Approve) without calling `pre_invoke`. Existing graphs unaffected.
7. {PC-007} **Pure Routing Core (VP-011 Proof Surface):** The implementation MUST define the following
   type and extract the following two named pure-core synchronous functions in `graph::hitl`.
   These are the VP-011 Kani proof targets. Extraction is required because Kani 0.67.0 has no
   native async support and cannot target `pre_tool_dispatch` (async) directly.

   `DispatchOutcome` enum (in `graph::hitl`):
   - `Proceed(Option<serde_json::Value>)` — `None` = proceed with original args (Approve path);
     `Some(args)` = proceed with modified args (valid Edit path). The effectful `pre_tool_dispatch`
     wrapper resolves the final arg value before calling `tool.invoke`.
   - `Reject(String)` — tool MUST NOT be invoked; reason propagated to model context as
     `ToolOutput::Error(reason)`.

   `route_pre_tool_decision(decision: PreToolDecision) -> DispatchOutcome` (pure, sync, no I/O):
   Maps the three routable `PreToolDecision` variants plus the `#[non_exhaustive]` wildcard to
   their dispatch outcome. `PendingHumanApproval` is peeled off upstream by the async
   `pre_tool_dispatch` wrapper before this function is called (Option A design):
   - `Deny { reason }` → `Reject(reason)` (fail-closed; `Proceed` is structurally unreachable
     from this arm — this is the VP-011 primary invariant)
   - `Approve` → `Proceed(None)` (signal to use original args from wrapper context)
   - `Edit { modified_args }` where `modified_args.is_object()` →
     `Proceed(Some(modified_args))`
   - `Edit { modified_args }` where `!modified_args.is_object()` →
     `Reject("invalid modified_args")`
   - `_ (#[non_exhaustive] wildcard)` → `Reject("unexpected_variant")` (fail-closed safety for
     `PendingHumanApproval` if it unexpectedly bypasses the peel-off, and for any future
     `PreToolDecision` variants)

   `shield_hook_result(result: Result<PreToolDecision, HookError>) -> PreToolDecision`
   (pure, sync, no I/O):
   - `Err(_)` → `PreToolDecision::Deny { reason: "hook error: <detail>" }` (step 2 of
     ADR-018 Decision 3 dispatch sequence)
   - `Ok(d)` → `d`

   The async `pre_tool_dispatch` wrapper calls these functions in order: first
   `shield_hook_result` on the raw hook result (or constructs `Deny` on panic-catch), then
   peels off `PendingHumanApproval` if present (issuing interrupt via BC-2.05.001 machinery),
   then calls `route_pre_tool_decision` on the remaining routable variant.

## Invariants

- {INV-001} **Fail-closed Deny (VP-011 Kani seed):** `PreToolDecision::Deny` ALWAYS results in
  `ToolOutput::Error(reason)` being returned WITHOUT invoking the tool. Under no control flow
  path does a Deny decision allow tool execution. The property is proved by Kani via the
  pure-core `route_pre_tool_decision` function (PC-007): `Deny { reason }` returns
  `DispatchOutcome::Reject(reason)` and `DispatchOutcome::Proceed` is structurally unreachable
  from the `Deny` arm.
- {INV-002} `pre_tool_dispatch` is called for EVERY tool invocation — there is no bypass, no
  tool-whitelist that skips the hook.
- {INV-003} Hook failure (panic or error) is treated as Deny, not Approve. This is the fail-closed
  safety property. The async hook invocation `hook.pre_invoke(&preview, &run_ctx)` is wrapped in
  `FutureExt::catch_unwind(AssertUnwindSafe(...))` so that a panic during `.await` polling is caught
  and converted to `PreToolDecision::Deny { reason: "hook error: <panic_detail>" }` via
  `shield_hook_result` (per {PC-007}); a synchronous `std::panic::catch_unwind` around
  future-construction cannot catch it because the hook body fires during the polled future.
  **SEC-008 build-profile dependency:** This recovery depends on `panic = "unwind"`. The
  AUTHORITATIVE pin point is the workspace-root `[profile.release]` governing the `pregolya-server`
  binary; Cargo honors `[profile.release] panic` ONLY at the workspace root (applied at link time);
  a library-member `[profile.release] panic` override (e.g., in `pregolya-graph`'s own manifest) is
  silently ignored by Cargo and MUST NOT be relied upon; `panic = "abort"` at the workspace root
  voids the catch and causes process termination (CWE-248/703).
- {INV-004} `AlwaysApprovePolicy` is the default; the behavior change is opt-in via `GraphConfig`.
- {INV-005} **DI-014 (No Silent Swallowing):** `ToolOutput::Error(reason)` is returned to the model
  context on Deny; the Deny reason is never silently discarded.
- {INV-006} **Retry ordering (ADR-018 Decision 6):** The call sequence per tool invocation is:
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
| TV-006 | Hook panics | `ToolOutput::Error("hook error: ...")` — tool not invoked | fail-closed (panic); async hook panic caught via `FutureExt::catch_unwind(AssertUnwindSafe(hook.pre_invoke(...)))` inside `pre_tool_dispatch`; caught panic constructs `Deny { reason: "hook error: <detail>" }` via `shield_hook_result` ({PC-007}); SEC-008: requires workspace-root `[profile.release]` `panic = "unwind"` governing `pregolya-server` binary (library-member override silently ignored by Cargo; `panic = "abort"` voids catch, causes process termination, CWE-248/703) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-011 (Kani P0) | `route_pre_tool_decision(Deny{..})` returns `DispatchOutcome::Reject` only; `DispatchOutcome::Proceed` unreachable from `Deny` arm; `shield_hook_result(Err(_))` → `Deny{..}`; `#[non_exhaustive]` wildcard → `Reject` (fail-closed) — all proved over pure-core sync functions (PC-007) | Kani exhaustive proof targeting `route_pre_tool_decision` and `shield_hook_result` in `graph::hitl`; async `pre_tool_dispatch` excluded from Kani scope (no native async support in Kani 0.67.0) |
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

- `architecture/decisions/ADR-018-per-tool-call-approval-hook.md` — Decision 1 (PreToolCallHook trait in pregolya-graph::hitl), Decision 2 (GraphConfig.pre_tool_hook), Decision 3 (pre_tool_dispatch dispatch logic — 6-step sequence), Decision 6 (retry-approval ordering)
- `architecture/module-decomposition.md` — SS-05, `pregolya-graph / hitl` module
- `architecture/verification-architecture.md` — VP-011 (D23 candidate)

## Story Anchor

S-1.23

## VP Anchors

- VP-011 (assigned in VP-INDEX as VP-011 — Kani P0; pregolya-graph `deny_excludes_tool_invocation`)
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
| VP Registration | VP-011 (assigned in VP-INDEX as VP-011 — Kani P0; pregolya-graph `deny_excludes_tool_invocation`) |
| Module | pregolya-graph / hitl |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + Kani (VP-011) |
