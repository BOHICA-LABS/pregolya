---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.003
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-TBD
capability: CAP-014
wave: 1
phase: 1a
red_gate: false
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/platform/behavioral-intent.md
input-hash: "992d1136d6ecd5fd6aa833f0ece030db3e548c8fdd727917f8474f6c21522745"
---

# BC-2.12.003: Run Creation and Execution Lifecycle (create → running → completed/failed)

## Description

A Run is a single execution of a ferrochain graph against a Thread, dispatched by
ferrochain-server. This BC specifies the Run creation endpoint, its lifecycle state
machine (`pending → running → completed | failed | interrupted`), and the failure
modes including the `E-SERVER-002 RunNotFound` error. Runs are created synchronously
via `POST /threads/{thread_id}/runs`; execution begins asynchronously. Status can be
polled via `GET /threads/{thread_id}/runs/{run_id}`. No wire-compatibility with
LangGraph Platform (D13).

## Preconditions

1. `ferrochain-server` is running with configured `RunStore`, `CheckpointStore`, and
   an executor connected to the `ferrochain-graph` engine.
2. A Thread identified by `thread_id` exists (see BC-2.12.001).
3. The caller holds a valid authentication credential (or server is in dev mode).

## Postconditions

### Create Run (`POST /threads/{thread_id}/runs`)

1. Accepts body:
   ```
   {
     assistant_id: Uuid,
     input?: GraphInput,
     config?: RunConfig,
     metadata?: Map<String, Value>,
     multitask_strategy?: "reject" | "interrupt" | "rollback" | "enqueue"
   }
   ```
2. `thread_id` must exist; if not: HTTP 404 with `E-SERVER-003 ThreadNotFound`.
3. `assistant_id` must reference a registered Assistant; if not: HTTP 422.
4. `multitask_strategy` governs concurrent run handling on the same thread (default `"reject"`):
   - `"reject"`: if another Run is already `pending` or `running` on the thread → HTTP 409.
   - `"interrupt"`: interrupt the current Run before starting the new one.
   - `"rollback"`: rollback the current Run's state before starting the new one.
   - `"enqueue"`: queue the new Run to start after the current Run finishes.
5. Returns HTTP 202 with `Run { run_id, thread_id, assistant_id, status: "pending", created_at }`.
6. Execution is dispatched asynchronously to the graph executor.

### Run Lifecycle State Machine

7. Lifecycle states and valid transitions:
   ```
   pending → running    (executor picks up the run)
   running → completed  (graph reaches END)
   running → failed     (unhandled error in graph or executor)
   running → interrupted (HITL interrupt raised; graph paused)
   ```
8. No backward transitions: `completed`, `failed`, and `interrupted` are terminal states.
9. A Run that is `interrupted` can be resumed via
   `POST /threads/{thread_id}/runs/{run_id}/resume { resume_value }` (see BC-2.05.002
   for HITL contract).

### Read Run (`GET /threads/{thread_id}/runs/{run_id}`)

10. Returns `Run { run_id, thread_id, assistant_id, status, output?, error?, created_at, updated_at }`.
11. Returns HTTP 404 with `{ code: "E-SERVER-002", message: "RunNotFound: run '<run_id>' does not exist in thread '<thread_id>'" }` if not found.
12. A completed Run carries `output: GraphOutput` (the final state values).
13. A failed Run carries `error: { code, message, component, category }` from the
    propagated `FerrochainError`.

### List Runs (`GET /threads/{thread_id}/runs`)

14. Returns `{ runs: [Run], total_count: u64 }` for all runs on the thread.
15. Accepts `status` filter query param (`"pending"`, `"running"`, `"completed"`, `"failed"`, `"interrupted"`).

### Delete Run (`DELETE /threads/{thread_id}/runs/{run_id}`)

16. Deletes a Run record in a terminal state. Cannot delete a `pending` or `running` Run
    (HTTP 409: use cancel first).
17. Returns HTTP 204 on success; HTTP 404 if run not found.

## Invariants

- `run_id` is globally unique within the server instance.
- The executor MUST NOT start a Run that was created in a `pending` state on a different
  server instance without distributed coordination — in single-node deployment, all
  `pending` Runs on startup are retried.
- Run output (`output`) is populated ONLY when `status = "completed"`. It is `null` in
  all other states.
- Run error (`error`) is populated ONLY when `status = "failed"`. It is `null` in all other states.
- A Run cannot be in `running` state if no executor task is active for it (no orphan runs).

## Edge Cases

### EC-001: Create Run on non-existent thread
**Scenario:** `POST /threads/ghost/runs { ... }`.
**Expected behavior:** HTTP 404 `{ code: "E-SERVER-003", message: "ThreadNotFound: thread 'ghost' does not exist" }`. No Run is created.

### EC-002: Concurrent run with multitask_strategy=reject (default)
**Scenario:** Thread "t1" has a `running` Run; another `POST /threads/t1/runs` arrives with
default `multitask_strategy`.
**Expected behavior:** HTTP 409 `{ code: "E-SERVER-012", message: "ConcurrentRun: thread 't1' already has an active run; use multitask_strategy to override" }`.

### EC-003: Run fails due to unhandled graph error
**Scenario:** A node in the graph panics or returns `Err(FerrochainError { ... })`.
**Expected behavior:** Run transitions to `failed` with `error` field populated from the
`FerrochainError`. DI-014 ensures the error is not silently swallowed. The thread's
checkpoint state reverts to the last successful checkpoint before the failed Run.

### EC-004: Get run with wrong thread_id
**Scenario:** `GET /threads/t2/runs/<run_id>` where the run belongs to thread `t1`.
**Expected behavior:** HTTP 404 `E-SERVER-002 RunNotFound`. The run exists but is
scoped to a different thread — cross-thread run access is not permitted.

### EC-005: Delete an active (running) run
**Scenario:** `DELETE /threads/t1/runs/<run_id>` while `status = "running"`.
**Expected behavior:** HTTP 409. Caller must cancel the run first
(`POST /threads/t1/runs/<run_id>/cancel`), wait for terminal state, then delete.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `POST /threads/t1/runs { assistant_id: "a1", input: { message: "hello" } }` | HTTP 202, `{ run_id, status: "pending" }` | Happy-path create |
| TV-002 | Poll `GET /threads/t1/runs/<run_id>` until status changes | `pending → running → completed` with `output` populated | Lifecycle progression |
| TV-003 | `GET /threads/t1/runs/nonexistent` | HTTP 404 E-SERVER-002 | Run not found |
| TV-004 | `GET /threads/ghost/runs/<run_id>` (wrong thread) | HTTP 404 E-SERVER-002 | Thread scoping enforced |
| TV-005 | Graph node returns error → run status | `status: "failed"`, `error: { code: "E-GRAPH-...", ... }` | Error surfacing |
| TV-006 | Second run on same thread, default strategy | HTTP 409 E-SERVER-012 | Concurrent rejection |
| TV-007 | `GET /threads/t1/runs?status=completed` | Filtered list of completed runs | Status filter |

## Verification Properties

_No Kani VP seed required. Integration tests against in-process ferrochain-server and
ferrochain-graph engine are sufficient._

## Related BCs

- BC-2.12.001 — depends on: Runs are executed against Threads; thread must exist before run creation
- BC-2.12.002 — depends on: Runs reference an Assistant config at creation time
- BC-2.05.002 — sibling: HITL interrupt resume contract covers the `interrupted` terminal state resume path

## Architecture Anchors

- `ferrochain-server/src/api/runs.rs` — Run CRUD handlers
- `ferrochain-server/src/executor.rs` — Async executor dispatching pending runs to graph engine
- `ferrochain-server/src/store/run_store.rs` — `RunRecord` and lifecycle state persistence

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

_[to be filled after verification-architecture phase]_

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — this BC implements the Run resource lifecycle, which is explicitly listed as the third of the four managed resources: "Run (single execution)" and specifies the "create → running → completed/failed" lifecycle |
| L2 Domain Invariants | — |
| DEC Reference | DEC-006 (Resume Value Injection with Empty Interrupt Queue — applies to the `interrupted` state resume path) |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration), E2E (end-to-end) |
| Module | [architect to assign — ferrochain-server] |
