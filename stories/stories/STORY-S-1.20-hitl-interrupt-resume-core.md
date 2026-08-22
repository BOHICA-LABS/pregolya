---
document_type: story
level: ops
story_id: S-1.20
epic_id: E-12
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.001.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.002.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.003.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.004.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.005.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "cf7c625"
traces_to: .factory/stories/STORY-INDEX.md
points: 13
depends_on: [S-1.16, S-1.17, S-1.10]
blocks: [S-1.23]
behavioral_contracts: [BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005, BC-2.05.006]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-05]
estimated_days: 5
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

> **tdd_mode:** strict — full TDD Iron Law enforced. HITL is a multi-step state machine; write failing tests for each state transition first.

> **Execute:** `/vsdd-factory:deliver-story S-1.20`

# S-1.20: HITL Interrupt, Resume, and Risk-Tiered Gate Core

## Narrative

- **As a** graph runtime developer building the pregolya-graph HITL system
- **I want to** implement `interrupt(value)` that suspends a run at a checkpoint boundary with an INTERRUPT marker, deliver resume values to nodes via a FIFO per-task scratchpad, re-execute the interrupted node from START on `Command(resume=v)`, handle `Command` struct variants (resume, update, goto, graph), guard against empty queues and invalid states, and gate tool execution via risk-tiered `ActionRisk` interrupts
- **So that** human operators can review and approve or reject agent actions before they execute, and the interrupt/resume protocol is crash-safe via the INTERRUPT marker checkpoint

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.05.001 | interrupt() Suspends Run with INTERRUPT Marker Checkpoint | AC-001..AC-004 |
| BC-2.05.002 | FIFO Resume-Value Delivery via Per-Task Scratchpad | AC-005..AC-007 |
| BC-2.05.003 | Interrupted Node Re-Executes from START on Resume | AC-008..AC-010 |
| BC-2.05.004 | Command Struct Variants and Validation | AC-011..AC-014 |
| BC-2.05.005 | Empty Queue and Invalid-State Guards | AC-015..AC-018 |
| BC-2.05.006 | Risk-Tiered ActionRisk Interrupts | AC-019..AC-023 |

## Acceptance Criteria

### AC-001 (traces to BC-2.05.001 postcondition 1 — interrupt() suspends run and writes INTERRUPT marker)
Calling `interrupt(value)` from within a node function synchronously writes an INTERRUPT marker checkpoint entry `{ "__interrupt__": [InterruptPayload { value, interrupt_id }] }` and suspends execution before any further nodes run in the current super-step. Verified by `test_BC_2_05_001_interrupt_writes_marker_and_suspends()`.

### AC-002 (traces to BC-2.05.001 postcondition 2 — INTERRUPT marker uses sync put_writes)
The INTERRUPT marker is written via synchronous `put_writes` to the checkpoint, not batched async. This ensures the marker is durable before the scheduler returns. Verified by `test_BC_2_05_001_interrupt_uses_sync_put_writes()`.

### AC-003 (traces to BC-2.05.001 postcondition 3 — interrupt_id is unique per call)
Each `interrupt(value)` call generates a unique `interrupt_id` (UUID v4). Multiple `interrupt()` calls in the same run produce distinct `interrupt_id` values. Verified by `test_BC_2_05_001_interrupt_id_is_unique()`.

### AC-004 (traces to BC-2.05.001 edge case EC-001 — E-GRAPH-016 on INTERRUPT marker write failure)
If `put_writes` fails during INTERRUPT marker write, the scheduler returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-016, .. })`. The run does not continue with a partial checkpoint. Verified by `test_BC_2_05_001_marker_write_failure_returns_e_graph_016()`.

### AC-005 (traces to BC-2.05.002 postcondition 1 — resume value delivered FIFO to interrupted task)
Resume values are delivered to the interrupted task via a FIFO per-task scratchpad. The first `Command(resume=v)` delivered to a task provides the value that the interrupted node's `interrupt()` call returns. Verified by `test_BC_2_05_002_resume_delivered_fifo()`.

### AC-006 (traces to BC-2.05.002 postcondition 2 — interrupt_counter tracks multiple interrupts in same task)
An `interrupt_counter` on the per-task scratchpad tracks multiple `interrupt()` calls within a single task execution. Each counter value corresponds to a distinct `interrupt_id`. Verified by `test_BC_2_05_002_interrupt_counter_tracks_multiple_interrupts()`.

### AC-007 (traces to BC-2.05.002 invariant 1 — scratchpad is per-task, not per-run)
The per-task scratchpad is scoped to the individual task (identified by `task_id`), not the run. Two parallel tasks have independent scratchpads. Verified by `test_BC_2_05_002_scratchpad_is_per_task()`.

### AC-008 (traces to BC-2.05.003 postcondition 1 — node re-executes from START on resume)
On `Command(resume=v)`, the interrupted node re-executes from the beginning of its function body — not from the `interrupt()` call site. The previous partial execution state is discarded. Verified by `test_BC_2_05_003_node_re_executes_from_start_on_resume()`.

### AC-009 (traces to BC-2.05.003 postcondition 2 — resume value replayed from scratchpad)
On re-execution, when the node calls `interrupt()` again, the value returned is taken from the scratchpad (FIFO) rather than suspending again. The node continues execution past the `interrupt()` call. Verified by `test_BC_2_05_003_resume_value_replayed_from_scratchpad()`.

### AC-010 (traces to BC-2.05.003 invariant 1 — idempotent replay from scratchpad)
Re-executing the node with the scratchpad populated is idempotent: repeated `Command(resume=v)` inputs with the same scratchpad value produce the same node output. Verified by `test_BC_2_05_003_replay_is_idempotent()`.

### AC-011 (traces to BC-2.05.004 postcondition 1 — Command struct has resume, update, goto, graph fields)
`Command { resume: Option<Value>, update: Option<HashMap<String, Value>>, goto: Option<SendTarget>, graph: Option<GraphTarget> }` is the canonical command struct. All fields are `Option`. Verified by `test_BC_2_05_004_command_struct_fields()`.

### AC-012 (traces to BC-2.05.004 postcondition 2 — Command.PARENT shorthand maps to parent run)
`Command.PARENT` as a `goto` target resolves to the parent run's ID (for subgraph-spawned tasks). Using `Command.PARENT` on a top-level run returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-015, .. })`. Verified by `test_BC_2_05_004_command_parent_resolves_or_errors()`.

### AC-013 (traces to BC-2.05.004 edge case EC-004 — Command on non-interrupted run returns E-GRAPH-002)
Sending `Command(resume=v)` to a run that is not in interrupted state returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-002, .. })` with fields `{ thread_id, run_status }`. Verified by `test_BC_2_05_004_command_on_non_interrupted_run_returns_e_graph_002()`.

### AC-014 (traces to BC-2.05.004 invariant 1 — interrupt_id field is canonical in Command)
The `interrupt_id` field in `Command(resume=v)` matches the `interrupt_id` from the `InterruptPayload` that triggered the interruption. A mismatched `interrupt_id` returns an error. Verified by `test_BC_2_05_004_interrupt_id_canonical_in_command()`.

### AC-015 (traces to BC-2.05.005 postcondition 1 — empty resume queue returns E-GRAPH-002)
When `Command(resume=v)` arrives but the per-task scratchpad has no pending interrupt for this run (queue exhausted), the scheduler returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-002, .. })` with fields `{ thread_id, run_status }`. Verified by `test_BC_2_05_005_empty_queue_returns_e_graph_002()`.

### AC-016 (traces to BC-2.05.005 postcondition 2 — 7 guard cases on run state)
`E-GRAPH-002` is returned for resume attempts on runs in any of these 7 states: `completed`, `failed`, `in_progress`, `summary_halt`, `queued`, `cancelled`, and `slots-consumed`. Verified by `test_BC_2_05_005_all_seven_guard_cases_return_e_graph_002()`.

### AC-017 (traces to BC-2.05.005 postcondition 3 — HTTP 422 for invalid resume)
When the HTTP API layer receives an invalid resume command, it returns HTTP 422. This story ensures the scheduler produces the `E-GRAPH-002` error that the HTTP API layer maps to 422. Verified by `test_BC_2_05_005_e_graph_002_semantics_for_http_422()`.

### AC-018 (traces to BC-2.05.005 invariant 1 — queue exhausted vs wrong state are distinct error payloads)
`E-GRAPH-002` from an empty queue carries `run_status: "interrupted"` (right state, wrong queue). `E-GRAPH-002` from wrong run state carries the actual state name. Both use the same error code but different `run_status` field values. Verified by `test_BC_2_05_005_empty_queue_vs_wrong_state_e_graph_002()`.

### AC-019 (traces to BC-2.05.006 postcondition 1 — ActionRisk enum defined with 4 variants)
`ActionRisk` is defined in `pregolya-core/src/action_risk.rs` as an enum with variants `ReadOnly`, `Low`, `Medium`, `High` and carries `#[non_exhaustive]`. External match arms must include a wildcard `_ => {}` arm. Verified by `test_BC_2_05_006_action_risk_enum_variants()`.

### AC-020 (traces to BC-2.05.006 postcondition 2 — wildcard arm fails-closed to High for unknown variants)
An unrecognised `ActionRisk` variant (future addition, deserialised from a newer binary) is treated as `High` risk by the gate logic — fail-closed. The wildcard arm in `RiskGatePolicy` must map unknown variants to `High`. Verified by `test_BC_2_05_006_wildcard_arm_fails_closed_to_high()`.

### AC-021 (traces to BC-2.05.006 postcondition 3 — risk gate triggers interrupt for configured threshold)
When a tool call carries `ActionRisk` at or above the configured `RiskGatePolicy` threshold, the scheduler calls `interrupt()` with `HitlInterruptPayload { action_risk, action, context }` before the tool executes. Verified by `test_BC_2_05_006_risk_gate_triggers_interrupt()`.

### AC-022 (traces to BC-2.05.006 edge case EC-001 — E-GRAPH-013 on risk gate rejection)
When the HITL operator rejects a risk-gated action, the scheduler returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-013, .. })`. The tool is not called. Verified by `test_BC_2_05_006_risk_gate_rejection_e_graph_013()`.

### AC-023 (traces to BC-2.05.006 invariant 1 — lazy deadline evaluation for risk gate)
The deadline for risk-gate HITL responses is evaluated lazily at resume time — not at interrupt time. This prevents pre-computing a fixed timeout that could expire before the HITL UI is even shown. Verified by `test_BC_2_05_006_risk_gate_deadline_lazy_evaluation()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| `interrupt()` call in node context | `pregolya-graph/src/scheduler.rs` | Effectful (checkpoint write) |
| INTERRUPT marker checkpoint write | `pregolya-graph/src/scheduler.rs` | Effectful (sync put_writes) |
| Per-task scratchpad | `pregolya-graph/src/types.rs` | Pure (data structure) |
| Resume-value FIFO delivery | `pregolya-graph/src/scheduler.rs` | Effectful (reads scratchpad) |
| `Command` struct | `pregolya-graph/src/types.rs` | Pure (data type) |
| `ActionRisk` enum | `pregolya-core/src/action_risk.rs` | Pure (type definition) |
| `RiskGatePolicy` | `pregolya-graph/src/scheduler.rs` | Pure (evaluate) + Effectful (interrupt dispatch) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/action_risk.rs` (`ActionRisk`, `RiskGatePolicy` trait) | pure-core | Type definitions + pure trait |
| `pregolya-graph/src/types.rs` (`Command`, `InterruptPayload`, `HitlInterruptPayload`, per-task scratchpad) | pure-core | Data structures; no I/O |
| `pregolya-graph/src/scheduler.rs` (interrupt/resume dispatch) | effectful-shell | Checkpoint writes, FIFO scratchpad reads, risk gate interrupt dispatch |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | `interrupt()` called twice in same node without resume between | Two `InterruptPayload` entries in INTERRUPT marker; `interrupt_counter` incremented; both must be resolved before node completes |
| EC-002 | Resume arrives before INTERRUPT marker is durably written | Not possible — `put_writes` is synchronous; marker is durable before scheduler returns |
| EC-003 | `Command.PARENT` on top-level run (no parent) | `E-GRAPH-015 { .. }` |
| EC-004 | `ActionRisk` value from future binary version (unknown variant) | Wildcard arm fails-closed to `High`; interrupt triggered |
| EC-005 | HITL deadline expires (lazy evaluation) | At resume time, deadline check fires; `E-GRAPH-014` if expired |
| EC-006 | `Command(resume=v)` with wrong `interrupt_id` | Error returned; scratchpad not consumed |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~5,000 |
| BC files (6 BCs) | ~8,500 |
| S-1.16 context (scheduler, BSP engine) | ~2,000 |
| S-1.10 context (checkpoint put_writes) | ~1,500 |
| S-1.17 context (StreamEvent for interrupt) | ~1,000 |
| `types.rs` additions (Command, InterruptPayload, scratchpad) | ~1,200 |
| `pregolya-core/src/action_risk.rs` | ~800 |
| `scheduler.rs` interrupt/resume additions | ~2,500 |
| Test files | ~5,000 |
| **Total** | **~27,500** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~13.8%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001..AC-004 (interrupt() + INTERRUPT marker) first — crash-safe invariant
2. [ ] Write failing tests for AC-019..AC-023 (ActionRisk risk gate) — security-critical path second
3. [ ] Write remaining failing tests for AC-005..AC-018
4. [ ] Create `pregolya-core/src/action_risk.rs` — `ActionRisk` enum (`#[non_exhaustive]`), `RiskGatePolicy` trait
5. [ ] Add `InterruptPayload`, `HitlInterruptPayload`, `Command`, per-task scratchpad to `pregolya-graph/src/types.rs`
6. [ ] Implement `interrupt(value)` in node execution context in `pregolya-graph/src/scheduler.rs` — sync `put_writes` to checkpoint
7. [ ] Implement resume delivery: FIFO scratchpad reads on node re-execution from START
8. [ ] Implement `Command` handling: `resume`, `update`, `goto`, `graph` variants; `Command.PARENT` check
9. [ ] Implement all 7 guard-case checks for `E-GRAPH-002` in scheduler
10. [ ] Implement risk-gate `ActionRisk` evaluation + lazy deadline + `E-GRAPH-013`/`E-GRAPH-014`
11. [ ] Export `ActionRisk`, `RiskGatePolicy` from `pregolya-core/src/lib.rs`
12. [ ] Run `cargo nextest run -p pregolya-graph -p pregolya-core --no-fail-fast` — all tests green

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.16 | `scheduler.rs` has super-step ceiling + run state management | Scheduler owns run lifecycle state machine | Interrupt is a run state transition: `running` → `interrupted` → `running` (on resume). The 7 guard cases are state checks on this machine |
| S-1.17 | `StreamEvent` defined; run/step events emitted in scheduler | Streaming events emitted via channel from scheduler | `StreamEvent::RunEnd` must NOT be emitted when run is in `interrupted` state |
| S-1.10 | `CheckpointSaver::put_writes()` is the Sync-durability-tier write API (`async fn put_writes`; storage confirmed before super-step) | Checkpoint backend is SQLite; `put_writes` returns `Result<(), PregolyaError>` | INTERRUPT marker uses `put_writes` not `put_checkpoint` — it is a pending-writes entry, not a full checkpoint snapshot |

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `ActionRisk` carries `#[non_exhaustive]`; wildcard arm mandatory | CLAUDE.md §`#[non_exhaustive]` on public API surface types | Non-exhaustive gate crate; compile-fail test |
| Wildcard arm in `RiskGatePolicy` fails-closed to `High` | BC-2.05.006 postcondition 2 | Unit test `test_BC_2_05_006_wildcard_arm_fails_closed_to_high()` |
| `interrupt()` uses synchronous `put_writes` — not async batch | BC-2.05.001 postcondition 2 | Code review: no `.await` between `interrupt(value)` call and checkpoint write |
| Node re-executes from START — no resumption from interrupt site | BC-2.05.003 postcondition 1 | Integration test: side-effect counter before `interrupt()` is 1 after resume (node ran from start again) |
| `E-GRAPH-016` on INTERRUPT marker write failure | BC-2.05.001 invariant 1 | Unit test with injected checkpoint write failure |
| FIFO ordering of resume values to interrupt calls | BC-2.05.002 postcondition 1 | Unit test: two sequential `interrupt()` calls; first resume goes to first call |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `uuid` | workspace-pinned | `interrupt_id` generation, per-task scratchpad key |
| `serde_json` | workspace-pinned | `InterruptPayload.value` and `Command.resume` are `serde_json::Value` |
| `tokio` | workspace-pinned | Async scheduler; `put_writes` is called in async context |
| `tracing` | workspace-pinned | Structured events for interrupt/resume lifecycle |
| `pregolya-checkpoint` | workspace path | `CheckpointSaver::put_writes` for INTERRUPT marker |

**Forbidden Dependencies:** `pregolya-core/src/action_risk.rs` must NOT import from `pregolya-graph`. Dependency direction: `pregolya-graph` → `pregolya-core`.

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/action_risk.rs` | create | `ActionRisk` enum, `RiskGatePolicy` trait, `HitlInterruptPayload` |
| `pregolya-core/src/lib.rs` | modify | Re-export `ActionRisk`, `RiskGatePolicy` |
| `pregolya-graph/src/types.rs` | modify | Add `Command`, `InterruptPayload`, `SendTarget`, per-task scratchpad type |
| `pregolya-graph/src/scheduler.rs` | modify | `interrupt()` impl; resume dispatch; 7-guard state machine; risk gate |
| `pregolya-graph/tests/hitl_interrupt_resume.rs` | create | AC-001..AC-023 tests |
