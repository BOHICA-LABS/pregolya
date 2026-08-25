---
document_type: story
level: ops
story_id: S-1.23
epic_id: E-12
version: "1.4"
status: draft
producer: story-writer
timestamp: 2026-08-24T14:00:00Z
changelog:
  - "1.4 (P2A-046 OBS-1/2026-08-24): AC-009 heading compressed ordinal normalized to stable tag"
  - "1.3 (P2A-043 F-04-adj/2026-08-24): 6 wrong-ordinal EC-source citations corrected per PO adjudication"
  - "1.2 (P2A-043 F-04/2026-08-24): old-form ordinal cross-refs converted to stable tags"
  - "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors; 3 mis-anchors corrected (AC-001 PRE-001→INV-002, AC-009 PC-002→EC-006, AC-010 INV-001→INV-002)"
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.007.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.008.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "5ac9ddd"
traces_to:
  - behavioral-contracts/BC-2.05.007
  - behavioral-contracts/BC-2.05.008
points: 5
depends_on: [S-1.20, S-1.17]
blocks: [S-1.24, S-6.01]
behavioral_contracts: [BC-2.05.007, BC-2.05.008]
verification_properties: [VP-011]
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-05]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: N/A — BCs authored (BC-2.05.007, BC-2.05.008)
---

# STORY-S-1.23: Pre-Tool-Call Hook (PreToolCallHook / PreToolDecision)

## Narrative

As a platform operator, I want a `PreToolCallHook` dispatch gate that intercepts every tool invocation before execution so that approval, denial, argument editing, or human-escalation decisions can be applied to individual tool calls based on configurable hook logic, with a hard guarantee that `Deny` decisions never invoke the tool.

## Token Budget Estimate

| Context Component | Estimated Tokens |
|-------------------|-----------------|
| This story spec | ~4,000 |
| BC files (2 BCs: BC-2.05.007–008) | ~7,000 |
| Architecture module-decomposition.md | ~3,000 |
| Target source files (`pregolya-graph/src/hitl.rs`) | ~7,000 |
| Test files | ~8,000 |
| S-1.20 (HITL interrupt/resume core) interface | ~3,000 |
| **Total estimate** | **~32,000** |

Comfortable within context window. No split required.

## Behavioral Contracts

| BC ID | Title | Red Gate? |
|-------|-------|-----------|
| BC-2.05.007 | PreToolCallHook — 4-branch pre-invoke dispatch gate | No |
| BC-2.05.008 | Skip-hook-on-resume invariant after PendingHumanApproval | No |

## Acceptance Criteria

### AC-001: pre_tool_dispatch called for every tool invocation, no bypass
`pre_tool_dispatch` is called before every `DynTool::invoke` call. There is no code path that invokes a tool without passing through `pre_tool_dispatch`. The retry ordering is: `circuit_breaker → pre_tool_dispatch → invoke → retry_policy.record`.
(traces to BC-2.05.007 INV-002)

### AC-002: Approve branch — tool invoked with original args
When `pre_tool_dispatch` returns `PreToolDecision::Approve`, the engine calls `tool.invoke(original_args)` and returns the result. No modification to args.
(traces to BC-2.05.007 PC-001)

### AC-003: Deny branch — tool is NOT invoked; ToolOutput::Error returned
When `pre_tool_dispatch` returns `PreToolDecision::Deny { reason }`, the engine returns `ToolOutput::Error(reason)` WITHOUT calling `tool.invoke`. This is the VP-011 (Kani P0) property: the Deny branch has zero calls to `tool.invoke`.
(traces to BC-2.05.007 PC-002)

### AC-004: Edit branch — modified args validated, then tool invoked
When `pre_tool_dispatch` returns `PreToolDecision::Edit { modified_args }`, the engine validates `modified_args` and then calls `tool.invoke(modified_args)`. If `modified_args` are invalid (fail tool schema validation), the edit degrades to Deny and `ToolOutput::Error` is returned without invoking the tool.
(traces to BC-2.05.007 PC-003)

### AC-005: PendingHumanApproval branch — run interrupted with ToolApprovalRequest
When `pre_tool_dispatch` returns `PreToolDecision::PendingHumanApproval { prompt }`, the engine calls `interrupt(ToolApprovalRequest { tool_name, tool_args, action_risk, prompt })` and suspends execution. The tool is NOT invoked at this point.
(traces to BC-2.05.007 PC-004)

### AC-006: Fallback — hook panic degrades to Deny
If the configured `PreToolCallHook` panics (or returns an unrecoverable error), the engine treats the outcome as `Deny` and returns `ToolOutput::Error`. The tool is NOT invoked on hook panic.
(traces to BC-2.05.007 PC-005)

### AC-007: VP-011 Kani P0 seed — Deny branch has NO call to tool.invoke
This story is the VP-011 anchor. The Kani harness for VP-011 must verify: for all possible `PreToolDecision::Deny` paths in `pre_tool_dispatch`, no execution path contains a call to `tool.invoke`. The test `test_AC_007_deny_branch_no_invoke_kani_seed` provides the unit test vector: mock hook returning Deny, assert tool stub was never called.
(traces to BC-2.05.007 INV-001)

### AC-008: Skip-hook-on-resume — hook NOT re-called after PendingHumanApproval
After a run is suspended with `PendingHumanApproval` and then resumed via `Command(resume=<decision>)`, `pre_tool_dispatch` is NOT called again. The delivered decision (`Approve`, `Deny`, or `Edit`) is applied directly per BC-2.05.007 PC-001 through PC-003 (branch PC-001, PC-002, or PC-003).
(traces to BC-2.05.008 PC-001)

### AC-009: BC-2.05.007 PC-004 (PendingHumanApproval) is not valid as a resume decision
A resume `Command(resume=PendingHumanApproval)` is invalid. The engine rejects this and returns an error. `PendingHumanApproval` is only a valid hook decision, not a valid resume decision.
(traces to BC-2.05.008 EC-006)

### AC-010: ToolApprovalRequest persisted via msgpack for process-restart durability
The `ToolApprovalRequest` interrupt payload is persisted using the msgpack checkpoint mechanism so that a process restart can reconstruct the pending approval state. FIFO ordering of pending approvals is maintained per the approval queue invariant (see BC-2.05.008 PC-005).
(traces to BC-2.05.008 INV-002)

### AC-011: Pure-core router functions — fail-closed routing (VP-011 Kani proof targets)
`route_pre_tool_decision(decision: PreToolDecision) -> DispatchOutcome` and `shield_hook_result(result: Result<PreToolDecision, HookError>) -> PreToolDecision` are implemented as named pure sync functions in `pregolya_graph::hitl`. `DispatchOutcome` has variants `Proceed(Option<serde_json::Value>)` and `Reject(String)`. Routing semantics: `Deny{reason}` → `Reject(reason)`; `Approve` → `Proceed(None)`; `Edit{modified_args}` where `modified_args` is a JSON object → `Proceed(Some(modified_args))`; `Edit{modified_args}` where `modified_args` is NOT a JSON object → `Reject("invalid modified_args")`; `#[non_exhaustive]` wildcard arm → `Reject("unexpected_variant")`; `shield_hook_result(Err(_))` → `Deny{reason: "hook error: <detail>"}`. The VP-011 Kani harness stub (`deny_excludes_tool_invocation` in `src/proofs/pre_tool_hook.rs`) calls `route_pre_tool_decision` and `shield_hook_result` directly and MUST compile against this implementation.
(traces to BC-2.05.007 PC-007)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `PreToolCallHook` trait | `pregolya_graph::hitl` | pregolya-graph | Pure (trait definition) |
| `PreToolDecision` enum | `pregolya_graph::hitl` | pregolya-graph | Pure (enum) |
| `DispatchOutcome` enum | `pregolya_graph::hitl` | pregolya-graph | Pure (enum — `Proceed(Option<serde_json::Value>)` / `Reject(String)`) |
| `route_pre_tool_decision` | `pregolya_graph::hitl` | pregolya-graph | Pure (sync, no I/O — VP-011 Kani proof target per BC-2.05.007 PC-007) |
| `shield_hook_result` | `pregolya_graph::hitl` | pregolya-graph | Pure (sync, no I/O — VP-011 Kani proof target per BC-2.05.007 PC-007) |
| `pre_tool_dispatch` | `pregolya_graph::hitl` | pregolya-graph | Effectful (async wrapper; calls hook, peels `PendingHumanApproval`, may interrupt run) |
| `ToolApprovalRequest` | `pregolya_graph::hitl` | pregolya-graph | Pure (data type) |

**Subsystem anchor:** SS-05 owns this story's scope because SS-05 is the HITL Interrupt / Resume subsystem per ARCH-INDEX Subsystem Registry. `pre_tool_dispatch` is a gate within the graph's tool-call dispatch cycle that executes before `DynTool::invoke`. The hook trait, decision enum, and pure-routing functions are core HITL contracts.

**Dependency anchors:**
- Depends on S-1.20: HITL interrupt/resume core machinery (`interrupt()`, `Command(resume=...)`) is built in S-1.20. Pre-tool-call hook uses `interrupt(ToolApprovalRequest)` to suspend the run.
- Depends on S-1.17: Streaming event taxonomy established in S-1.17 provides the `StreamEvent` enum that carries `ToolApprovalRequest` events (see S-1.24).

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `PreToolDecision` | Pure | Enum with no side effects |
| `DispatchOutcome` | Pure | Enum with no side effects (`Proceed` / `Reject`) |
| `PreToolCallHook::pre_invoke` | Pure (trait contract) | Returns decision; no I/O by contract |
| `route_pre_tool_decision` | Pure (sync) | Pure match over `PreToolDecision` → `DispatchOutcome`; no I/O, no await — VP-011 Kani proof target per BC-2.05.007 PC-007 |
| `shield_hook_result` | Pure (sync) | Pure conversion `Result<PreToolDecision, HookError>` → `PreToolDecision`; `Err(_)` → `Deny{reason: "hook error: <detail>"}`, `Ok(d)` → `d`; no I/O — VP-011 Kani proof target per BC-2.05.007 PC-007 |
| `pre_tool_dispatch` | Effectful | Async wrapper; calls hook, shields result, peels `PendingHumanApproval` interrupt, calls `route_pre_tool_decision` for routable variants |
| `ToolApprovalRequest` | Pure | Data type; serialization is separate |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.05.007 PC-001 | Hook returns Approve | `tool.invoke(original_args)` called |
| EC-002 | BC-2.05.007 EC-001 | Hook returns Deny | `ToolOutput::Error(reason)` — NO tool.invoke |
| EC-003 | BC-2.05.007 EC-003 | Edit with invalid modified_args | Degrades to Deny; `ToolOutput::Error` |
| EC-004 | BC-2.05.007 EC-002 | Hook panics | Treated as Deny; tool NOT invoked |
| EC-005 | BC-2.05.007 EC-004 | No hook configured | Implicit Approve; tool invoked with original args |
| EC-006 | BC-2.05.008 EC-001 | Resume with Approve | Tool invoked with original args; hook NOT called |
| EC-007 | BC-2.05.008 EC-002 | Resume with Deny | `ToolOutput::Error`; hook NOT called |
| EC-008 | BC-2.05.008 EC-006 | Resume with PendingHumanApproval | Error; invalid resume decision |
| EC-009 | BC-2.05.007 EC-005 | Process restart with pending ToolApprovalRequest | Approval state reconstructed from msgpack checkpoint |

## Tasks

- [ ] Create `crates/pregolya-graph/src/hitl.rs` — single module for all PreTool/HITL surface items
- [ ] Register module: add `pub mod hitl;` in `crates/pregolya-graph/src/lib.rs`
- [ ] Implement `DispatchOutcome` enum: `Proceed(Option<serde_json::Value>)` / `Reject(String)` in `hitl.rs` (BC-2.05.007 PC-007)
- [ ] Implement `route_pre_tool_decision(decision: PreToolDecision) -> DispatchOutcome` — pure sync; `Deny{reason}` → `Reject(reason)`; `Approve` → `Proceed(None)`; `Edit{obj}` where obj is JSON object → `Proceed(Some(obj))`; `Edit{non-obj}` → `Reject("invalid modified_args")`; `#[non_exhaustive]` wildcard → `Reject("unexpected_variant")` (BC-2.05.007 PC-007; VP-011 Kani target)
- [ ] Implement `shield_hook_result(result: Result<PreToolDecision, HookError>) -> PreToolDecision` — pure sync; `Err(_)` → `Deny{reason: "hook error: <detail>"}`, `Ok(d)` → `d` (BC-2.05.007 PC-007; VP-011 Kani target)
- [ ] Implement `PreToolDecision` enum — `#[non_exhaustive]`; variants: `Approve` / `Deny { reason: String }` / `Edit { modified_args: serde_json::Value }` / `PendingHumanApproval { prompt: String }`
- [ ] Implement `PreToolCallHook` trait in `hitl.rs`
- [ ] Implement `pre_tool_dispatch` — async wrapper: calls hook, shields result via `shield_hook_result`, peels `PendingHumanApproval` (calls `interrupt(ToolApprovalRequest{..})`), calls `route_pre_tool_decision` for remaining variants
- [ ] Implement `ToolApprovalRequest` struct (msgpack-serializable) in `hitl.rs`
- [ ] Implement `ToolApprovalRequest` msgpack serialization (msgpack checkpoint mechanism from S-1.20)
- [ ] Write failing tests for AC-001..AC-011 before any implementation
- [ ] Write `test_AC_007_deny_branch_no_invoke_kani_seed` — mock hook returning Deny, assert tool not called
- [ ] Write `test_AC_011_route_pre_tool_decision_*` — unit tests for all routing arms in `route_pre_tool_decision` and `shield_hook_result`
- [ ] Implement skip-hook-on-resume: `pre_tool_dispatch` is NOT called on resume path
- [ ] Validate `Command(resume=PendingHumanApproval)` returns error
- [ ] Create `crates/pregolya-graph/src/proofs/pre_tool_hook.rs` — `#[cfg(kani)]` `deny_excludes_tool_invocation` stub (body `todo!()` for Phase 6 formal hardening; VP-011); harness calls `route_pre_tool_decision` and `shield_hook_result` directly
- [ ] Verify Kani harness stub compiles: `cargo kani -p pregolya-graph --harness deny_excludes_tool_invocation` aborts with `todo!()` (not a compile error)
- [ ] Run `just iter pregolya-graph` — all tests green

## Previous Story Intelligence

**From S-1.20 (HITL Interrupt/Resume Core):**
- `interrupt(T)` is the function that suspends graph execution. For PendingHumanApproval, call `interrupt(ToolApprovalRequest { .. })`.
- `Command(resume=<decision>)` is the struct kwarg form for resume commands. Do NOT use `Command::Resume(...)` enum variant form — that notation was corrected in the F-P142-03 fix cycle (see S-1.20 implementation notes).
- Msgpack checkpoint for interrupt payloads is handled by the msgpack persistence machinery established in S-1.20.

**From S-1.17 (Streaming Event Types):**
- The `StreamEvent` enum was established in S-1.17. Events 13 (`tool_approval_request`) and 14 (`tool_approval_resolved`) are added by S-1.24 (which depends on this story). S-1.23 only defines the hook mechanics; streaming events are wired in S-1.24.

**N/A — first story implementing hook dispatch.** No prior hook story exists.

## Architecture Compliance Rules

1. **No bypass of pre_tool_dispatch.** Every code path from the executor to `DynTool::invoke` must pass through `pre_tool_dispatch`. The executor must have no "fast path" that skips the hook.
2. **Deny branch has zero calls to tool.invoke.** This is a structural requirement (VP-011), not just a test. The Deny arm of `pre_tool_dispatch` must contain no call to `tool.invoke` in its source — not even a conditional one.
3. **Hook panic → Deny (fail-closed).** The pre_tool_dispatch implementation must wrap hook execution in a catch-unwind or equivalent. A panicking hook must not propagate to crash the executor.
4. **PendingHumanApproval on resume → immediate error.** No special handling; return early with error before any hook or tool invocation.
5. **`mod.rs` re-export only.** `hitl/mod.rs` (if a `src/hitl/` subdirectory is used instead of `src/hitl.rs`) contains only `pub use` declarations. No logic in `mod.rs` files.
6. **`#[non_exhaustive]`** on `PreToolDecision` (public API surface enum — future variants possible).
7. **No `unwrap()` / `expect()` in production code.**

## Library & Framework Requirements

| Library | Version | Feature Flags | License | Usage |
|---------|---------|--------------|---------|-------|
| `tokio` | (workspace pin) | default | MIT | Async executor context for hook dispatch |
| `tracing` | (workspace pin) | default | MIT | Structured logging for dispatch decisions |
| `pregolya-core` | (workspace) | — | — | `PregolyaError`, `DynTool`, `ActionRisk` |
| `rmp-serde` | (workspace pin) | — | MIT | msgpack serialization of `ToolApprovalRequest` |

## File Structure Requirements

```
crates/pregolya-graph/
  src/
    hitl.rs                          # All PreTool/HITL surface items:
                                     #   PreToolCallHook trait
                                     #   PreToolDecision enum (#[non_exhaustive])
                                     #   DispatchOutcome enum (Proceed(Option<serde_json::Value>) / Reject(String))
                                     #   route_pre_tool_decision (pure sync — VP-011 Kani proof target)
                                     #   shield_hook_result (pure sync — VP-011 Kani proof target)
                                     #   pre_tool_dispatch (async wrapper)
                                     #   ToolApprovalRequest struct (msgpack-serializable)
    proofs/
      pre_tool_hook.rs               # VP-011 Kani harness stub — deny_excludes_tool_invocation
                                     #   (body todo!() for Phase 6 formal hardening)
  tests/
    pre_tool_hook_tests.rs           # unit tests: all 4 branches + pure-router arms (AC-001..AC-011),
                                     #   panic fallback, skip-on-resume
```

**Files to create (new):** `src/hitl.rs` (all HITL surface items per above), `src/proofs/pre_tool_hook.rs` (VP-011 Kani harness stub — `deny_excludes_tool_invocation`; body `todo!()` for Phase 6).
**Files to modify (existing):** `pregolya-graph/src/lib.rs` (add `pub mod hitl;` declaration).
