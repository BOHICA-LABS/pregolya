---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.006
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-02
capability: CAP-003
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "38542d3"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.006: Send API Dynamic Fan-Out

## Description

The `Send` API enables dynamic fan-out: a `path_fn` attached to a conditional edge returns
`N` `Send("worker", arg_i)` objects in a single step, each pushing an independent
`PregelTask` (a PUSH task) into the `TASKS` topic channel. In the next super-step all N
tasks execute concurrently with their individual `arg_i` payloads. Fan-out width is
determined at runtime from graph state, not at compile time. Results from the N worker
tasks fan back in via reducer channels (e.g., `Append`). `Send.arg` values containing
`UntrackedValue` fields are sanitized before checkpointing, ensuring that ephemeral
routing payloads do not pollute the durable checkpoint.

## Preconditions

1. A `StateGraph` is compiled with at least one `add_conditional_edges(source, path_fn)`
   where `path_fn` may return `Send` objects.
2. `path_fn(state)` evaluates to a list `[Send("worker", arg_0), Send("worker", arg_1),
   ..., Send("worker", arg_{N-1})]` in the current step.
3. A node `"worker"` is registered in the graph; its signature accepts an individual
   `arg_i` payload (not the full graph state).
4. A `CheckpointSaver` is configured (required for crash-safety of multi-task fan-out).

## Postconditions

1. Each `Send("worker", arg_i)` pushes one entry onto the `TASKS` topic channel in the
   current step's write deque; the topic is a `BinaryOperatorAggregate` (list-append) so
   all N entries accumulate.
2. In the NEXT super-step, `prepare_next_tasks` creates N independent PUSH `PregelTask`s,
   one per `Send`, each carrying its own `arg_i` as the node input (not the full graph
   state).
3. All N PUSH tasks execute concurrently in that next super-step.
4. Each `arg_i` payload is content-addressed to produce a deterministic task ID:
   `xxh3_128(checkpoint_id ++ checkpoint_ns ++ step ++ "worker" ++ PUSH ++ arg_hash)`.
5. `Send.arg` values that contain `UntrackedValue` fields are sanitized (those fields
   stripped) before the arg is written to the `TASKS` topic; the sanitized arg is what
   is checkpointed and what the worker node receives.
6. After all N tasks complete in the fan-out step, reducer channels (e.g., `Append`) fold
   their individual outputs in deterministic task-identity-sorted order back into the
   shared state.
7. On process restart mid fan-out (K of N tasks completed before crash), the K completed
   tasks are not re-executed (their `put_writes` persisted the task outputs); the remaining
   N-K tasks are re-run. No task is lost; no task runs more than once.

## Invariants

- Fan-out width is dynamic: `path_fn` determines N at runtime from state; N may be 0, 1,
  or any positive integer.
- PUSH tasks from `Send` are distinct from PULL tasks (triggered by channel writes); they
  are stored in the `TASKS` topic and materialized into tasks only in the NEXT super-step.
- Task IDs are deterministic: given the same checkpoint_id and arg content, the same task
  ID is produced on re-run (enabling idempotent pending-write matching on resume).
- UntrackedValue sanitization is unconditional: no `Send.arg` carrying an UntrackedValue
  field may enter the checkpoint in unsanitized form.

## Edge Cases

### EC-001: path_fn returns zero Send objects (empty fan-out)
**Scenario:** `path_fn(state)` returns `[]` (no Send tasks emitted) in a step.
**Expected behavior:** No PUSH tasks are created; the `TASKS` topic channel receives no
writes; if no other nodes are triggered in the next step, the graph halts naturally. No
error. Fan-out of zero is valid.

### EC-002: Fan-out of N=1 — single dynamic task
**Scenario:** `path_fn` returns `[Send("worker", arg_0)]` — exactly one task.
**Expected behavior:** One PUSH task is created; the worker node runs with `arg_0`; the
result is folded back via reducer. Functionally equivalent to a conditional edge that
routes to `"worker"` statically, but the arg differs from graph state.

### EC-003: Process restart mid fan-out — K of N completed
**Scenario:** `path_fn` returned `[Send("worker", a0), Send("worker", a1), Send("worker",
a2)]` (N=3). Tasks for `a0` and `a1` completed (put_writes persisted) before the process
crashed. On restart, the graph resumes from the same checkpoint.
**Expected behavior:** Tasks for `a0` and `a1` are NOT re-executed (their outputs are
restored from pending writes). Only the task for `a2` re-runs. Final output is identical
to a non-crashed run.
**Reference:** DEC-009 (Process Restart During Active Send Fan-Out).

### EC-004: Send.arg contains UntrackedValue field
**Scenario:** A user-defined arg struct carries a field annotated as `UntrackedValue`
(e.g., a runtime-only handle). `path_fn` returns `Send("worker", arg_with_untracked)`.
**Expected behavior:** Before the arg is written to the `TASKS` topic / checkpoint, the
`UntrackedValue` field is stripped. The worker node receives the arg without the untracked
field. No error; sanitization is transparent.

### EC-005: Worker node not registered — Send targets unknown node
**Scenario:** `path_fn` returns `Send("phantom_worker", arg)` but no node named
`"phantom_worker"` exists in the compiled graph.
**Expected behavior:** `Err(E-GRAPH-003 UnknownRoutingTarget { node: "phantom_worker" })`
is returned from the run when the PUSH task is scheduled in the next step. The run fails.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `path_fn` returns `[Send("worker", 1), Send("worker", 2), Send("worker", 3)]`; worker doubles its arg and appends to `results: Append<Vec<i64>>` | After fan-out step: `results = [2, 4, 6]` (order per task-identity sort) | Happy-path N=3 fan-out with Append reducer |
| TV-002 | `path_fn` returns `[]` | No PUSH tasks; graph halts (if no other triggers) | Zero fan-out |
| TV-003 | N=3 fan-out; crash after 2 tasks complete; resume | K=2 tasks not re-run; only third task re-runs; same final result | Crash recovery — DEC-009 |
| TV-004 | `Send.arg` contains an `UntrackedValue` field | Field stripped from checkpointed arg; worker receives arg without untracked field | UntrackedValue sanitization |
| TV-005 | `Send("ghost", arg)` where `"ghost"` not in graph | `Err(E-GRAPH-003 UnknownRoutingTarget)` at PUSH-task scheduling time | Unknown worker target |
| TV-006 | N=100 concurrent worker tasks; each appends one item to `results: Append<Vec<i64>>` | `results` has 100 items in deterministic task-identity-sorted order | Large fan-out determinism |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-SEND-01 | Process restart mid-fan-out produces same final result as uninterrupted run | Integration test (kill + restart fixture, N=5 fan-out) | Phase 1 |
| VP-SEND-02 | Fan-out result order is deterministic regardless of task completion order | Property test: shuffle completion latencies, assert same final Append state | Phase 1 |

## Related BCs

- BC-2.02.005 — depends on: Send objects are a return-value variant of conditional edge path_fn
- BC-2.02.002 — depends on: Append (BinaryOperatorAggregate) channel folds the fan-out results
- BC-2.04.001 — depends on: per-task put_writes durability is what enables idempotent crash recovery
- BC-2.04.005 — depends on: crash recovery logic (reapply writes to succeeded tasks) applies here
- BC-2.03.001 — depends on: deterministic reducer order (DI-001) governs how fan-out results are merged

## Architecture Anchors

- `ferrochain-graph/src/types.rs` — `Send`, `UntrackedValue`, `TASKS` topic channel
- `ferrochain-graph/src/pregel/algo.rs` — `prepare_next_tasks`, PUSH task creation from TASKS topic
- `ferrochain-graph/src/pregel/loop.rs` — `apply_writes`, UntrackedValue sanitization of Send.arg

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-SEND-01, VP-SEND-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — "Send API for dynamic fan-out" is listed by name as a component of the StateGraph definition capability in CAP-003 |
| L2 Domain Invariants | — |
| D17 Commitment | semport/graph/behavioral-intent.md §6.3 Send API (dynamic fan-out / map-reduce) |
| DEC Reference | DEC-009 (Process Restart During Active Send Fan-Out — Domain B forcing function) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration), P (property) |
| Module | ferrochain-graph |
