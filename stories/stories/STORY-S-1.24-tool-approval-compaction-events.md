---
document_type: story
level: ops
story_id: S-1.24
epic_id: E-09
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.004.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.005.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "8952921"
traces_to:
  - behavioral-contracts/BC-2.06.004
  - behavioral-contracts/BC-2.06.005
  - behavioral-contracts/BC-2.06.006
points: 5
depends_on: [S-1.23, S-1.17, S-1.18]
blocks: [S-1.25]
behavioral_contracts: [BC-2.06.004, BC-2.06.005, BC-2.06.006]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-06]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: N/A — BCs authored (BC-2.06.004, BC-2.06.005, BC-2.06.006)
---

# STORY-S-1.24: Tool Approval and Compaction Streaming Events (Events 13, 14, 15)

## Narrative

As a stream consumer (CLI or IDE), I want three new streaming events — `tool_approval_request` (event 13), `tool_approval_resolved` (event 14), and `compaction_event` (event 15) — so that I can surface interactive tool approval dialogs and observe compaction activity in real time without polling run status endpoints.

## Token Budget Estimate

| Context Component | Estimated Tokens |
|-------------------|-----------------|
| This story spec | ~4,000 |
| BC files (3 BCs: BC-2.06.004–006) | ~9,000 |
| Architecture module-decomposition.md | ~3,000 |
| Target source files (pregolya-graph/src/event_emitter.rs) | ~5,000 |
| Test files | ~8,000 |
| S-1.17 (streaming event types) interface | ~3,000 |
| **Total estimate** | **~32,000** |

Comfortable within context window. No split required.

## Behavioral Contracts

| BC ID | Title | Red Gate? |
|-------|-------|-----------|
| BC-2.06.004 | `tool_approval_request` StreamEvent (Event 13) — payload, causal ordering before interrupt | No |
| BC-2.06.005 | `tool_approval_resolved` StreamEvent (Event 14) — payload, emission on resume | No |
| BC-2.06.006 | `compaction_event` StreamEvent (Event 15) — payload, parent_ids mandatory | No |

## Acceptance Criteria

### AC-001: tool_approval_request emitted BEFORE interrupt() is issued
When `pre_tool_dispatch` returns `PendingHumanApproval`, the engine emits `StreamEvent::ToolApprovalRequest` BEFORE calling `interrupt(ToolApprovalRequest)`. Stream consumers receive the event while the run is still in-flight (not yet `interrupted`).
(traces to BC-2.06.004 postcondition 2)

### AC-002: tool_approval_request payload — complete and correct fields
The emitted `StreamEvent::ToolApprovalRequest` carries: `run_id` (UUID), `tool_name` (registered name string), `tool_args` (original JSON args before any Edit), `action_risk` (ActionRisk string or null if not annotated), `prompt` (Option<String> from PendingHumanApproval, null if None).
(traces to BC-2.06.004 postcondition 1)

### AC-003: tool_approval_request emitted exactly once per PendingHumanApproval
One `ToolApprovalRequest` event is emitted per hook decision that returns `PendingHumanApproval`. Approve, Deny, and Edit decisions produce NO `ToolApprovalRequest` event.
(traces to BC-2.06.004 postcondition 3)

### AC-004: tool_approval_request — stream channel full does not block engine
If the streaming channel is full or the consumer is disconnected, the emit attempt uses fire-and-forget semantics (non-blocking send). The engine does NOT panic and does NOT block. `interrupt()` is still issued.
(traces to BC-2.06.004 invariant 1)

### AC-005: tool_approval_resolved emitted AFTER interrupt consumed, BEFORE decision applied
When `Command(resume=<decision>)` is delivered for a `ToolApprovalRequest` interrupt, the engine emits `StreamEvent::ToolApprovalResolved` after consuming the interrupt and before applying the decision (before `tool.invoke` is called for Approve/Edit, before `ToolOutput::Error` for Deny).
(traces to BC-2.06.005 postcondition 3)

### AC-006: tool_approval_resolved payload — correct per decision variant
- `Approve`: `{ decision: "Approve", reason: null, modified_args: null }`
- `Deny { reason }`: `{ decision: "Deny", reason: "<reason>", modified_args: null }`
- `Edit { modified_args }`: `{ decision: "Edit", reason: null, modified_args: { ... } }`
All payloads include `run_id` and `tool_name`.
(traces to BC-2.06.005 postcondition 1)

### AC-007: Every tool_approval_resolved pairs with a prior tool_approval_request
For the same `run_id` + `tool_name`, `tool_approval_resolved` is only emitted after a `tool_approval_request` was emitted. `tool_approval_resolved` is never emitted for a run with no pending `ToolApprovalRequest` interrupt.
(traces to BC-2.06.005 postcondition 2)

### AC-008: compaction_event emitted AFTER compacted checkpoint durably written
`StreamEvent::CompactionEvent` is emitted only after `CheckpointSaver::put` has completed and the compacted checkpoint is durably persisted. Not before.
(traces to BC-2.06.006 postcondition 1)

### AC-009: compaction_event payload — parent_ids is MANDATORY
The `compaction_event` payload includes: `run_id`, `parent_ids` (Vec<Uuid>, MANDATORY — must not be null or empty), `trigger` (CompactionTrigger variant string), `compacted_start` (message index), `compacted_end` (message index), `summary_token_count` (u64), `tokens_remaining_after` (Option<i64> — null when no token ceiling; negative on Deny path).
(traces to BC-2.06.006 postcondition 2)

### AC-010: compaction_event — parent_ids is mandatory (non-null, non-empty array)
`parent_ids` field on `CompactionEvent` payload must be a non-null, non-empty array. Emitting a `compaction_event` with `parent_ids: null` or `parent_ids: []` violates the CompactionEvent structural invariant (BC-2.06.006 invariant 1) and must not occur.
(traces to BC-2.06.006 invariant 1)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `StreamEvent::ToolApprovalRequest` variant | `pregolya_graph::event_emitter` | pregolya-graph | Pure (enum variant addition) |
| `StreamEvent::ToolApprovalResolved` variant | `pregolya_graph::event_emitter` | pregolya-graph | Pure (enum variant addition) |
| `StreamEvent::CompactionEvent` variant | `pregolya_graph::event_emitter` | pregolya-graph | Pure (enum variant addition) |
| `event_emitter::emit_tool_approval_request` | `pregolya_graph::event_emitter` | pregolya-graph | Effectful (channel send) |
| `event_emitter::emit_tool_approval_resolved` | `pregolya_graph::event_emitter` | pregolya-graph | Effectful (channel send) |
| `event_emitter::emit_compaction_event` | `pregolya_graph::event_emitter` | pregolya-graph | Effectful (channel send) |

**Subsystem anchor:** SS-06 owns this story's scope because SS-06 is the Streaming Event subsystem per ARCH-INDEX Subsystem Registry. All three new events (13, 14, 15) are managed by `pregolya_graph::event_emitter` which is the SS-06 module responsible for emitting typed `StreamEvent` variants onto the streaming channel.

**Dependency anchors:**
- Depends on S-1.23: `pre_tool_dispatch` (built in S-1.23) is the emission site for events 13 and 14. S-1.24 adds the emit calls to the PendingHumanApproval branch and the resume path.
- Depends on S-1.17: `StreamEvent` enum established in S-1.17. S-1.24 extends it with 3 new variants (events 13, 14, 15).
- Depends on S-1.18: `EvidenceJournal` and `CheckpointSaver::put` (built in S-1.18) are called before `emit_compaction_event` — the compaction event is emitted after checkpoint write completes.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `StreamEvent::ToolApprovalRequest` | Pure | Enum variant — data only |
| `StreamEvent::ToolApprovalResolved` | Pure | Enum variant — data only |
| `StreamEvent::CompactionEvent` | Pure | Enum variant — data only |
| `emit_tool_approval_request` | Effectful | Non-blocking send to streaming channel |
| `emit_tool_approval_resolved` | Effectful | Non-blocking send to streaming channel |
| `emit_compaction_event` | Effectful | Non-blocking send after checkpoint write |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.06.004 EC-1 | Hook returns Deny (not PendingHumanApproval) | No `ToolApprovalRequest` event emitted |
| EC-002 | BC-2.06.004 EC-2 | PendingHumanApproval with `prompt: None` | Event emitted with `"prompt": null` |
| EC-003 | BC-2.06.004 EC-3 | Stream consumer disconnected | Event dropped; engine does NOT block; interrupt() still issued |
| EC-004 | BC-2.06.004 EC-4 | Tool has no `action_risk` annotation | `"action_risk": null` in event payload |
| EC-005 | BC-2.06.005 EC-1 | Resume with Approve | `{ "decision": "Approve", "reason": null, "modified_args": null }` |
| EC-006 | BC-2.06.005 EC-2 | Resume with Deny | `{ "decision": "Deny", "reason": "<reason>", "modified_args": null }` |
| EC-007 | BC-2.06.005 EC-3 | Resume with Edit | `{ "decision": "Edit", "reason": null, "modified_args": { ... } }` |
| EC-008 | BC-2.06.006 EC-1 | `tokens_remaining_after` when no token ceiling | Field is null (`Option<i64>: None`) |
| EC-009 | BC-2.06.006 EC-2 | Compaction on Deny path | `tokens_remaining_after` negative (ceiling - used, where used > ceiling) |

## Tasks

- [ ] Add `StreamEvent::ToolApprovalRequest`, `ToolApprovalResolved`, `CompactionEvent` variants to `event_emitter.rs`
- [ ] Write failing tests for AC-001..AC-010 before any implementation
- [ ] Implement `emit_tool_approval_request` — fire-and-forget channel send, called in PendingHumanApproval branch of `pre_tool_dispatch` BEFORE `interrupt()`
- [ ] Implement `emit_tool_approval_resolved` — fire-and-forget channel send, called on resume BEFORE decision applied
- [ ] Implement `emit_compaction_event` — fire-and-forget channel send, called AFTER `CheckpointSaver::put` completes
- [ ] Enforce `parent_ids` non-empty in `CompactionEvent` construction
- [ ] Add `tokens_remaining_after: Option<i64>` field to `CompactionEvent`
- [ ] Integration test: collect stream, assert event 13 precedes interrupted status
- [ ] Integration test: collect stream, assert event 14 precedes tool invocation
- [ ] Run `just iter pregolya-graph` — all tests green

## Previous Story Intelligence

**From S-1.23 (PreToolCallHook):**
- `pre_tool_dispatch` dispatch branches are established. S-1.24 adds emit calls at specific points within those branches. The emit must happen BEFORE `interrupt()` for event 13, and BEFORE decision application for event 14.
- `Command(resume=<decision>)` struct kwarg form is established. Do NOT use `Command::Resume(...)` enum variant form.

**From S-1.17 (Streaming Event Types):**
- `StreamEvent` enum is `#[non_exhaustive]` — adding new variants in S-1.24 requires updating the enum file. No changes to existing variant serialization.
- The streaming channel is an async broadcast/mpsc channel. Fire-and-forget send semantics: use `try_send` or similar non-blocking send; do not await a full channel.

**From S-1.18 (Budget Policy & Evidence Journal):**
- `CheckpointSaver::put` (not `put_writes`) is the trait method for writing checkpoints. Compaction event must be emitted after this call returns `Ok`.
- `EvidenceJournal` step 5 in the compaction cycle writes the journal before the stream event (step 6). Ordering: checkpoint `put` → EvidenceJournal → emit compaction_event.

## Architecture Compliance Rules

1. **Causal ordering is structural, not incidental.** `emit_tool_approval_request` call must appear BEFORE `interrupt()` call in source — not after. Compiler ordering guarantees this.
2. **`parent_ids` is mandatory.** Any `CompactionEvent` struct construction without a non-empty `parent_ids` must fail to compile or fail with assertion. Prefer a constructor that takes `Vec<Uuid>` and asserts non-empty.
3. **Fire-and-forget semantics.** All three emit functions use non-blocking send. If the channel is full, the event is dropped without error. The emitter must NOT block or panic on full channel.
4. **No `ToolApprovalRequest` event on Approve/Deny/Edit.** The emit call exists only in the `PendingHumanApproval` arm.
5. **`#[non_exhaustive]`** on `StreamEvent` variants' payload structs.
6. **No `unwrap()` / `expect()` in production code.**

## Library & Framework Requirements

| Library | Version | Feature Flags | License | Usage |
|---------|---------|--------------|---------|-------|
| `tokio` | (workspace pin) | `sync` feature | MIT | Async channel for event emission |
| `uuid` | (workspace pin) | `v4` feature | MIT/Apache | `run_id`, `parent_ids` UUID types |
| `serde` | (workspace pin) | `derive` | MIT/Apache | Serialization of event payloads |
| `tracing` | (workspace pin) | default | MIT | Logging emit attempts |

## File Structure Requirements

```
crates/pregolya-graph/
  src/
    event_emitter.rs                 # add: ToolApprovalRequest, ToolApprovalResolved, CompactionEvent variants
                                     # add: emit_tool_approval_request, emit_tool_approval_resolved, emit_compaction_event
  tests/
    streaming_events_tests.rs        # integration: event ordering, payload validation, fire-and-forget
```

**Files to modify (existing):**
- `pregolya-graph/src/event_emitter.rs` — add 3 new `StreamEvent` variants and emit functions
- `pregolya-graph/src/executor/tool_dispatch.rs` — add emit call in PendingHumanApproval branch and resume path
- `pregolya-graph/src/compaction/executor.rs` — add emit call after checkpoint put (step 6 of compaction cycle)
