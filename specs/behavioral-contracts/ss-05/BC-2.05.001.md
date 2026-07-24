---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.001
version: "1.3"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-05
capability: CAP-006
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-006
  - domain-spec/invariants.md#DI-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "2190fd4"
changelog:
  - "1.1 (ADV-P1D-PASS-26): F-P26-03 TV-005 field name risk_tier→action_risk (propagation of F-P25-06 action_risk canon; retired field name drained per RETIRED-IDENTIFIER RESIDUE GREP gate)."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph per module-decomposition.md v1.10."
  - "1.3 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.001: Interrupt Suspension with Durable State Persistence

## Description

When `interrupt(value)` is called inside a running node, the graph halts execution at
that node boundary, emits the interrupt value to the caller, and persists the full
interrupted graph state to the checkpointer before returning. The interrupted run is
durably parked: it survives a process restart and can be resumed by delivering a resume
value to the correct thread. This contract mandates that interruption and durable
persistence are an atomic unit — an interrupt with no checkpointer is a precondition
violation, and an interrupt whose state write fails propagates a storage error.

## Preconditions

1. A `StateGraph` is compiled with a `CheckpointSaver` attached (the graph has a
   durable checkpointer configured).
2. The graph is executing a super-step (one or more `PregelTask`s are in-flight).
3. A node function calls `interrupt(value)` where `value` is any serializable type.
4. No static `interrupt_before` / `interrupt_after` config overrides the node's execution
   (this BC covers dynamic `interrupt()` called from inside node body).

## Postconditions

1. The executing node raises a `NodeInterrupt` exception internally; the graph loop
   catches it and sets run status to `interrupted`.
2. The interrupt value is pushed onto the per-task scratchpad for the interrupted task
   (keyed by the `interrupt_counter` position — FIFO slot 0 for the first `interrupt()`).
3. A checkpoint is written via `put_writes` (carrying the `INTERRUPT` marker and the
   interrupt value payload) **before** the graph returns control to the caller; the
   write completes synchronously under the `sync` durability tier.
4. The caller (graph `invoke` / `stream`) receives the interrupt notification as
   `{"__interrupt__": [InterruptPayload { value, interrupt_id }]}`.
5. The run status in the checkpoint metadata is `interrupted`; the super-step boundary
   **has not advanced** (the checkpoint_id has not incremented past the interrupted step).
6. The thread can be resumed by a future `Command(resume=...)` call referencing the same
   `thread_id`.

## Invariants

- **DI-003 (HITL FIFO Resume-Value Delivery):** The interrupt value is recorded in
  the per-task scratchpad at a stable positional index; the FIFO order of future
  resume-value consumption is established at the moment `interrupt()` is called.
- An interrupt without a checkpointer is a hard precondition violation (returns
  `Err(E-GRAPH-016 InterruptWithoutCheckpointer)` before the node runs).
- The checkpoint written at interrupt time must include the INTERRUPT marker so that
  on process restart the engine recognizes the thread as interrupted (not failed).
- The interrupt does NOT advance to the next super-step; `versions_seen` and
  `channel_versions` for the interrupted task remain at their pre-interrupt values.

## Edge Cases

### EC-001: Interrupt called without a checkpointer attached
**Scenario:** A node calls `interrupt()` but the `StateGraph` was compiled without a
`CheckpointSaver`.
**Expected behavior:** `Err(E-GRAPH-016 InterruptWithoutCheckpointer)` is returned to
the caller before the interrupt halts. The node cannot be interrupted without a
checkpointer because there is no durable state to resume from.

### EC-002: Process restart after interrupt
**Scenario:** The process crashes immediately after `interrupt()` persists the INTERRUPT
marker. On restart the operator reloads the same `CheckpointSaver` and calls `resume`.
**Expected behavior:** The checkpointer surfaces the INTERRUPT-marker checkpoint; the
engine recognizes the thread as interrupted; `Command(resume=value)` succeeds and the
node re-executes from the start of the interrupted super-step (see BC-2.05.003).
**Reference:** semport §3.5 (durability across process restart).

### EC-003: Interrupt checkpoint write fails mid-way
**Scenario:** The `put_writes` call to persist the INTERRUPT marker fails (e.g., SQLite
returns an IO error).
**Expected behavior:** The storage error propagates as `Err(E-CHKPT-001
CheckpointWriteFailed)` to the graph caller; the run is treated as failed (not
interrupted), since the state was not durably saved.

### EC-004: interrupt() called with a non-serializable value
**Scenario:** A node calls `interrupt(value)` where `value` contains a type that cannot
be serialized by the configured checkpoint serializer (msgpack).
**Expected behavior:** `Err(E-CHKPT-006 SerializationFailed { field: "interrupt_value" })`
is returned. The graph does not proceed and does not leave a partial checkpoint.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Node calls `interrupt("approve_this_plan?")` with SQLite checkpointer attached | Run returns `{"__interrupt__": [{ "value": "approve_this_plan?", "interrupt_id": <hash> }]}`; checkpoint written with INTERRUPT marker | Happy path — standard interrupt with string payload |
| TV-002 | Same thread_id resumed after process kill+restart; call `Command(resume="yes")` | Node re-executes from its start; `interrupt()` call inside returns `"yes"` without raising | Durable persistence across restart — DI-003 + §3.5 |
| TV-003 | `interrupt()` called inside a graph compiled without `CheckpointSaver` | `Err(E-GRAPH-016 InterruptWithoutCheckpointer)` returned before node executes | Precondition violation |
| TV-004 | Two nodes in a super-step — only node B calls `interrupt()`; node A has completed | Checkpoint reflects node A's writes via `put_writes` (durable); run halts at node B interrupt | Partial-step durability — completed tasks' writes are not lost |
| TV-005 | `interrupt()` called with a structured payload `{ "action_risk": "High", "action": "isolate_host" }` | Interrupt payload is serialized to msgpack; checkpoint stores typed struct | Structured interrupt value round-trip (F-P26-03: field name corrected from `risk_tier` to `action_risk` per F-P25-06 canon) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-HITL-01 | Interrupt value persisted to checkpoint before caller receives interrupt notification | Integration test (assert checkpoint exists before `invoke` future resolves) | Phase 1 |
| VP-HITL-02 | Thread with INTERRUPT-marker checkpoint survives process restart and accepts resume | Integration test (kill + restart fixture) | Phase 1 |

## Related BCs

- BC-2.05.002 — depends on: per-task FIFO scratchpad established here is consumed by FIFO delivery
- BC-2.05.003 — depends on: node re-execute semantics apply only when interrupt is durable
- BC-2.05.004 — depends on: Command(resume=) API operates on the interrupt state established here
- BC-2.05.005 — composes with: empty-queue guard is the dual of this (what happens when no interrupt exists)
- BC-2.04.001 — depends on: per-task put_writes durability is the storage primitive this uses
- BC-2.04.005 — related to: crash-recovery for interrupted runs uses the INTERRUPT marker
- _(v2-deferred: in-flight cancellation — cancelling a run that is currently mid-super-step and propagating a CancelledError through the active node tasks is deferred to v2; v1 interrupt-and-resume covers only voluntary pause-and-wait, not async abort of executing nodes)_

## Architecture Anchors

- `ferrochain-graph/src/scheduler.rs` (`graph::scheduler`) — interrupt handling inside `tick()`
- `ferrochain-graph/src/types.rs` — `NodeInterrupt`, `InterruptPayload`, `Command` types
- `ferrochain-checkpoint/src/base.rs` — `put_writes` with INTERRUPT channel index

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-HITL-01, VP-HITL-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-006 |
| Capability Anchor Justification | CAP-006 ("HITL Interrupt / Resume with FIFO Resume-Value Delivery") per capabilities-p0.md §CAP-006 — this BC specifies the interrupt suspension and durable persistence contract that is the first half of the HITL round-trip named in CAP-006 |
| L2 Domain Invariants | DI-003 (HITL FIFO Resume-Value Delivery) |
| D17 Commitment | D17-Q2 — HITL contract as Phase-1 BC |
| CONFLICT Reference | CONFLICT-3 (adk-rust notification-only HITL is the counter-example; full LangGraph durable interrupt is the requirement) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | I (integration) |
| Module | ferrochain-graph |
