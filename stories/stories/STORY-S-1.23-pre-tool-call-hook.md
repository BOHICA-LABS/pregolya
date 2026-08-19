---
document_type: story
level: ops
story_id: S-1.23
epic_id: E-12
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.007.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.008.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "c480ca5"
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
| Target source files (pregolya-graph/src/hooks/) | ~7,000 |
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
(traces to BC-2.05.007 precondition 1)

### AC-002: Approve branch — tool invoked with original args
When `pre_tool_dispatch` returns `PreToolDecision::Approve`, the engine calls `tool.invoke(original_args)` and returns the result. No modification to args.
(traces to BC-2.05.007 postcondition 1)

### AC-003: Deny branch — tool is NOT invoked; ToolOutput::Error returned
When `pre_tool_dispatch` returns `PreToolDecision::Deny { reason }`, the engine returns `ToolOutput::Error(reason)` WITHOUT calling `tool.invoke`. This is the VP-011 (Kani P0) property: the Deny branch has zero calls to `tool.invoke`.
(traces to BC-2.05.007 postcondition 2)

### AC-004: Edit branch — modified args validated, then tool invoked
When `pre_tool_dispatch` returns `PreToolDecision::Edit { modified_args }`, the engine validates `modified_args` and then calls `tool.invoke(modified_args)`. If `modified_args` are invalid (fail tool schema validation), the edit degrades to Deny and `ToolOutput::Error` is returned without invoking the tool.
(traces to BC-2.05.007 postcondition 3)

### AC-005: PendingHumanApproval branch — run interrupted with ToolApprovalRequest
When `pre_tool_dispatch` returns `PreToolDecision::PendingHumanApproval { prompt }`, the engine calls `interrupt(ToolApprovalRequest { tool_name, tool_args, action_risk, prompt })` and suspends execution. The tool is NOT invoked at this point.
(traces to BC-2.05.007 postcondition 4)

### AC-006: Fallback — hook panic degrades to Deny
If the configured `PreToolCallHook` panics (or returns an unrecoverable error), the engine treats the outcome as `Deny` and returns `ToolOutput::Error`. The tool is NOT invoked on hook panic.
(traces to BC-2.05.007 postcondition 5)

### AC-007: VP-011 Kani P0 seed — Deny branch has NO call to tool.invoke
This story is the VP-011 anchor. The Kani harness for VP-011 must verify: for all possible `PreToolDecision::Deny` paths in `pre_tool_dispatch`, no execution path contains a call to `tool.invoke`. The test `test_AC_007_deny_branch_no_invoke_kani_seed` provides the unit test vector: mock hook returning Deny, assert tool stub was never called.
(traces to BC-2.05.007 invariant 1)

### AC-008: Skip-hook-on-resume — hook NOT re-called after PendingHumanApproval
After a run is suspended with `PendingHumanApproval` and then resumed via `Command(resume=<decision>)`, `pre_tool_dispatch` is NOT called again. The delivered decision (`Approve`, `Deny`, or `Edit`) is applied directly per BC-2.05.007 postconditions 1-3 (branch PC-1, PC-2, or PC-3).
(traces to BC-2.05.008 postcondition 1)

### AC-009: PC-4 (PendingHumanApproval) is not valid on resume
A resume `Command(resume=PendingHumanApproval)` is invalid. The engine rejects this and returns an error. `PendingHumanApproval` is only a valid hook decision, not a valid resume decision.
(traces to BC-2.05.008 postcondition 2)

### AC-010: ToolApprovalRequest persisted via msgpack for process-restart durability
The `ToolApprovalRequest` interrupt payload is persisted using the msgpack checkpoint mechanism so that a process restart can reconstruct the pending approval state. FIFO ordering of pending approvals is maintained per the approval queue invariant (see BC-2.05.008 invariant 1).
(traces to BC-2.05.008 invariant 1)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `PreToolCallHook` trait | `pregolya_graph::hooks::pre_tool` | pregolya-graph | Pure (trait definition) |
| `PreToolDecision` enum | `pregolya_graph::hooks::pre_tool` | pregolya-graph | Pure (enum) |
| `pre_tool_dispatch` | `pregolya_graph::executor::tool_dispatch` | pregolya-graph | Effectful (calls hook, may interrupt run) |
| `ToolApprovalRequest` | `pregolya_graph::hooks::approval` | pregolya-graph | Pure (data type) |

**Subsystem anchor:** SS-05 owns this story's scope because SS-05 is the Graph Execution Engine subsystem per ARCH-INDEX Subsystem Registry. `pre_tool_dispatch` is a gate within the graph's tool-call dispatch cycle that executes before `DynTool::invoke`. The hook trait and decision enum are core graph execution contracts.

**Dependency anchors:**
- Depends on S-1.20: HITL interrupt/resume core machinery (`interrupt()`, `Command(resume=...)`) is built in S-1.20. Pre-tool-call hook uses `interrupt(ToolApprovalRequest)` to suspend the run.
- Depends on S-1.17: Streaming event taxonomy established in S-1.17 provides the `StreamEvent` enum that carries `ToolApprovalRequest` events (see S-1.24).

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `PreToolDecision` | Pure | Enum with no side effects |
| `PreToolCallHook::pre_invoke` | Pure (trait contract) | Returns decision; no I/O by contract |
| `pre_tool_dispatch` | Effectful | May call hook, may interrupt run, may invoke tool |
| `ToolApprovalRequest` | Pure | Data type; serialization is separate |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.05.007 EC-1 | Hook returns Approve | `tool.invoke(original_args)` called |
| EC-002 | BC-2.05.007 EC-2 | Hook returns Deny | `ToolOutput::Error(reason)` — NO tool.invoke |
| EC-003 | BC-2.05.007 EC-3 | Edit with invalid modified_args | Degrades to Deny; `ToolOutput::Error` |
| EC-004 | BC-2.05.007 EC-4 | Hook panics | Treated as Deny; tool NOT invoked |
| EC-005 | BC-2.05.007 EC-5 | No hook configured | Implicit Approve; tool invoked with original args |
| EC-006 | BC-2.05.008 EC-1 | Resume with Approve | Tool invoked with original args; hook NOT called |
| EC-007 | BC-2.05.008 EC-2 | Resume with Deny | `ToolOutput::Error`; hook NOT called |
| EC-008 | BC-2.05.008 EC-3 | Resume with PendingHumanApproval | Error; invalid resume decision |
| EC-009 | BC-2.05.008 EC-4 | Process restart with pending ToolApprovalRequest | Approval state reconstructed from msgpack checkpoint |

## Tasks

- [ ] Create `crates/pregolya-graph/src/hooks/mod.rs` (re-exports only)
- [ ] Create `crates/pregolya-graph/src/hooks/pre_tool.rs` — `PreToolCallHook` trait, `PreToolDecision` enum
- [ ] Create `crates/pregolya-graph/src/hooks/approval.rs` — `ToolApprovalRequest` struct
- [ ] Create `crates/pregolya-graph/src/executor/tool_dispatch.rs` — `pre_tool_dispatch` function
- [ ] Write failing tests for AC-001..AC-010 before any implementation
- [ ] Write `test_AC_007_deny_branch_no_invoke_kani_seed` — mock hook returning Deny, assert tool not called
- [ ] Implement `PreToolDecision` enum — Approve / Deny { reason } / Edit { modified_args } / PendingHumanApproval { prompt }
- [ ] Implement `pre_tool_dispatch` — 4-branch dispatch with fallback Deny on panic
- [ ] Implement skip-hook-on-resume: extract `pre_tool_dispatch` branch from resume path
- [ ] Validate `Command(resume=PendingHumanApproval)` returns error
- [ ] Implement `ToolApprovalRequest` msgpack serialization (msgpack checkpoint mechanism from S-1.20)
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
5. **`mod.rs` re-export only.** `hooks/mod.rs` contains only `pub use` declarations.
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
    hooks/
      mod.rs                         # re-export only: pub use pre_tool::*; pub use approval::*;
      pre_tool.rs                    # PreToolCallHook trait, PreToolDecision enum
      approval.rs                    # ToolApprovalRequest struct (msgpack-serializable)
    executor/
      tool_dispatch.rs               # pre_tool_dispatch — 4-branch dispatch, panic fallback
  tests/
    pre_tool_hook_tests.rs           # unit tests: all 4 branches, panic fallback, skip-on-resume
```

**Files to create (new):** `hooks/pre_tool.rs`, `hooks/approval.rs`, `executor/tool_dispatch.rs`.
**Files to modify (existing):** `pregolya-graph/src/hooks/mod.rs` (add pub use), `pregolya-graph/src/executor/mod.rs` (add pub use tool_dispatch).
