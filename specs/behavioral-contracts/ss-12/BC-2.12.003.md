---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.003
version: "1.4"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-12
capability: CAP-014
wave: 1
phase: 1a
red_gate: false
producer: product-owner
timestamp: 2026-07-14T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/platform/behavioral-intent.md
input-hash: "6e20e9f"
changelog:
  - "1.1 (ADV-P1D-PASS-31): F-P31-01 PC18 list-runs endpoint — add limit (default 10, max 100; values > 100 clamped) and offset pagination params + declare created_at DESC ordering (pagination coherence canon)."
  - "1.2 (ADV-P1D-PASS-33): F-P33-02 add Run-Config Merge Precedence invariant — run-supplied config/metadata/context deep-merge over Assistant's stored values, run wins at leaf key. Upstream-check result: no contradicting semantics in BC-2.01.003 or semport behavioral-intent §2.3; leaf-level deep-merge adopted as spec canon."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-server per module-decomposition.md v1.10."
  - "1.4 (F-P117-01, fix burst 120, 2026-07-19): summary_halt promoted to first-class terminal Run status throughout (Option 1 adjudication: BC-2.10.003 PC8(d) explicitly asserts the Run status IS summary_halt '(not failed)'; entities-server.md §91 agrees). H1 title and Description: add summary_halt to state machine enumeration. PC7: add in_progress → summary_halt arc (OnCeiling::Summarize path per BC-2.10.003 PC8(c)(d)). PC8: terminal set {completed, failed, cancelled} → {completed, failed, cancelled, summary_halt}. PC13: completed_at terminal set gains summary_halt. PC18: status filter enum gains 'summary_halt'. PC19: deletable terminal states gain summary_halt. Output invariant: output populated when status ∈ {completed, summary_halt} (summary_halt output = summarize model response per BC-2.10.003 PC8(c)); null in all other states. Traceability state machine description updated."
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.003: Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable)

## Description

A Run is a single execution of a ferrochain graph against a Thread, dispatched by
ferrochain-server. This BC specifies the Run creation endpoint, its lifecycle state
machine (`queued → in_progress → completed | failed | cancelled | summary_halt`, with `interrupted` as a pausable/resumable state; `summary_halt` is a budget-summarize terminal state per BC-2.10.003 PC8(d)), and the
failure modes including the `E-SERVER-002 RunNotFound` error. Runs are created synchronously
via `POST /threads/{thread_id}/runs`; execution begins asynchronously. Status can be
polled via `GET /threads/{thread_id}/runs/{run_id}`. No wire-compatibility with
LangGraph Platform (D13).

## Preconditions

1. `ferrochain-server` is running with configured `RunStore`, `CheckpointSaver`, and
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
     config?: RunnableConfig,
     metadata?: Map<String, Value>,
     multitask_strategy?: "reject" | "interrupt" | "rollback" | "enqueue"
   }
   ```
2. `thread_id` must exist; if not: HTTP 404 with `E-SERVER-003 ThreadNotFound`.
3. `assistant_id` must reference a registered Assistant; if not: HTTP 422.
4. `multitask_strategy` governs concurrent run handling on the same thread (default `"reject"`):
   - `"reject"`: if another Run is already `queued` or `in_progress` on the thread → HTTP 409.
   - `"interrupt"`: interrupt the current Run before starting the new one.
   - `"rollback"`: rollback the current Run's state before starting the new one.
   - `"enqueue"`: queue the new Run to start after the current Run finishes.
5. Returns HTTP 202 with `Run { run_id, thread_id, assistant_id, status: "queued", created_at }`.
6. Execution is dispatched asynchronously to the graph executor.

### Run Lifecycle State Machine

7. Lifecycle states and valid transitions:
   ```
   queued      → in_progress   (executor picks up the run)
   in_progress → completed     (graph reaches END)
   in_progress → failed        (unhandled error in graph or executor)
   in_progress → interrupted   (HITL interrupt raised; graph paused, awaiting resume)
   in_progress → cancelled     (POST .../cancel called while run is active)
   in_progress → summary_halt  (OnCeiling::Summarize path: budget ceiling hit; one final summarize LLM call completes; model response returned as output — BC-2.10.003 PC8(c)(d))
   queued      → cancelled     (POST .../cancel called before executor picks up the run)
   interrupted → in_progress   (caller posts resume value via POST .../runs/{run_id}/resume)
   ```
8. Terminal states (no further transitions possible): `completed`, `failed`, `cancelled`, and `summary_halt`.
   `interrupted` is **not** terminal — it is a pausable/resumable state.
   `summary_halt` is terminal (no further transitions); it is not cancellable (already terminal when the cancel signal would arrive — HTTP 409 per PC12). A `summary_halt` run IS directly deletable (PC19) without needing a prior cancel step.
9. A Run that is `interrupted` can be resumed via
   `POST /threads/{thread_id}/runs/{run_id}/resume { resume_value }` (see BC-2.05.002
   for HITL contract); this transitions the Run back to `in_progress`.

### Cancel Run (`POST /threads/{thread_id}/runs/{run_id}/cancel`)

10. Cancels a `queued` or `in_progress` Run. Signals the executor to stop and transitions
    the Run to `cancelled` status.
11. Cancellation is best-effort: if the run completes naturally before the cancellation
    signal is processed, the status will be `completed` or `failed`, not `cancelled`.
12. Returns HTTP 202 on successful cancellation signal; HTTP 404 if run not found;
    HTTP 409 if run is already in a terminal state.

### Read Run (`GET /threads/{thread_id}/runs/{run_id}`)

13. Returns `Run { run_id, thread_id, assistant_id, status, output?, error?, created_at, updated_at, completed_at? }`.
    `updated_at` is set on every state mutation. `completed_at` is set only on terminal
    transition (status → `completed` | `failed` | `cancelled` | `summary_halt`); it is `null` in all
    non-terminal states (`queued`, `in_progress`, `interrupted`). Authority: F-P24-01.
14. Returns HTTP 404 with `{ code: "E-SERVER-002", message: "RunNotFound: run '<run_id>' does not exist in thread '<thread_id>'" }` if not found.
15. A completed Run carries `output: GraphOutput` (the final state values).
16. A failed Run carries `error: { code, message, component, category }` from the
    propagated `FerrochainError`.

### List Runs (`GET /threads/{thread_id}/runs`)

17. Returns `{ runs: [Run], total_count: u64 }` for all runs on the thread.
18. Accepts `status` filter query param (`"queued"`, `"in_progress"`, `"completed"`, `"failed"`, `"interrupted"`, `"cancelled"`, `"summary_halt"`) and canonical pagination params: `limit` (default 10, max 100; values > 100 clamped to 100) and `offset` (default 0); results ordered `created_at` descending (F-P31-01, ADV-P1D-PASS-31).

### Delete Run (`DELETE /threads/{thread_id}/runs/{run_id}`)

19. Deletes a Run record that is in a terminal state (`completed`, `failed`, `cancelled`, or `summary_halt`).
    Cannot delete a `queued`, `in_progress`, or `interrupted` Run — HTTP 409 is returned.
    For `interrupted` Runs: either resume (POST .../resume) to complete/fail/cancel/summary_halt, or
    cancel first (POST .../cancel → `cancelled`), then delete once terminal.
    **Decision basis (F-02):** DELETE = record deletion only. Separation from cancellation
    follows langgraph-sdk semantics (`runs.cancel()` ≠ delete). Prevents accidental data
    loss on active runs.
20. Returns HTTP 204 on success; HTTP 404 if run not found.

## Invariants

- `run_id` is globally unique within the server instance.
- The executor MUST NOT start a Run that was created in a `queued` state on a different
  server instance without distributed coordination — in single-node deployment, all
  `queued` Runs on startup are retried.
- Run output (`output`) is populated when `status ∈ {"completed", "summary_halt"}`. For
  `summary_halt`, output carries the summarize model response (BC-2.10.003 PC8(c)). It is
  `null` in all other states (`queued`, `in_progress`, `interrupted`, `failed`, `cancelled`).
- Run error (`error`) is populated ONLY when `status = "failed"`. It is `null` in all other states.
- A Run cannot be in `in_progress` state if no executor task is active for it (no orphan runs).
- **Run-Config Merge Precedence (F-P33-02):** When a Create-Run request body supplies `config`,
  `metadata`, or `context`, these values are **deep-merged** over the Assistant's stored values
  at the leaf-key level, with run-supplied keys winning over Assistant-stored keys on any
  collision. Fields absent from the run request body retain the Assistant's stored values
  unchanged. This applies to each of the three fields independently. Merge is applied at run
  creation time before the run is dispatched to the executor; the merged effective config is
  what the graph receives. **Upstream-check result:** BC-2.01.003 PC6 specifies that metadata
  "accumulates" down the run tree (consistent with merge; run wins), and semport behavioral-intent
  §2.3 declares no explicit merge rule for run-over-assistant config — no contradiction found.
  Leaf-level deep-merge is adopted as spec canon. Cross-ref: BC-2.12.002 §Description.

## Edge Cases

### EC-001: Create Run on non-existent thread
**Scenario:** `POST /threads/ghost/runs { ... }`.
**Expected behavior:** HTTP 404 `{ code: "E-SERVER-003", message: "ThreadNotFound: thread 'ghost' does not exist" }`. No Run is created.

### EC-002: Concurrent run with multitask_strategy=reject (default)
**Scenario:** Thread "t1" has an `in_progress` Run; another `POST /threads/t1/runs` arrives with
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

### EC-005: Delete an active (in_progress) run
**Scenario:** `DELETE /threads/t1/runs/<run_id>` while `status = "in_progress"`.
**Expected behavior:** HTTP 409. Caller must cancel the run first
(`POST /threads/t1/runs/<run_id>/cancel`), wait for terminal state, then delete.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `POST /threads/t1/runs { assistant_id: "a1", input: { message: "hello" } }` | HTTP 202, `{ run_id, status: "queued" }` | Happy-path create |
| TV-002 | Poll `GET /threads/t1/runs/<run_id>` until status changes | `queued → in_progress → completed` with `output` populated | Lifecycle progression |
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
- BC-2.05.002 — sibling: HITL interrupt resume contract covers the `interrupted` pausable state resume path (interrupted → in_progress transition)

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
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — this BC implements the Run resource lifecycle, which is explicitly listed as the third of the four managed resources: "Run (single execution)". Canonical state machine: queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable (PC7-PC9 are the authoritative source; see PC7 for transition arcs, PC8 for terminal-set definition, PC9 for interrupted→in_progress resume arc) |
| L2 Domain Invariants | — |
| DEC Reference | DEC-006 (Resume Value Injection with Empty Interrupt Queue — applies to the `interrupted` state resume path) |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration), E2E (end-to-end) |
| Module | ferrochain-server |
