---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.003
version: "1.14"
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
timestamp: 2026-08-24T01:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/platform/behavioral-intent.md
input-hash: "f898ec5"
changelog:
  - "1.1 (ADV-P1D-PASS-31): F-P31-01 PC18 list-runs endpoint — add limit (default 10, max 100; values > 100 clamped) and offset pagination params + declare created_at DESC ordering (pagination coherence canon)."
  - "1.2 (ADV-P1D-PASS-33): F-P33-02 add Run-Config Merge Precedence invariant — run-supplied config/metadata/context deep-merge over Assistant's stored values, run wins at leaf key. Upstream-check result: no contradicting semantics in BC-2.01.003 or semport behavioral-intent §2.3; leaf-level deep-merge adopted as spec canon."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-server per module-decomposition.md v1.10."
  - "1.4 (F-P117-01, fix burst 120, 2026-07-19): summary_halt promoted to first-class terminal Run status throughout (Option 1 adjudication: BC-2.10.003 PC8(d) explicitly asserts the Run status IS summary_halt '(not failed)'; entities-server.md §91 agrees). H1 title and Description: add summary_halt to state machine enumeration. PC7: add in_progress → summary_halt arc (OnCeiling::Summarize path per BC-2.10.003 PC8(c)(d)). PC8: terminal set {completed, failed, cancelled} → {completed, failed, cancelled, summary_halt}. PC13: completed_at terminal set gains summary_halt. PC18: status filter enum gains 'summary_halt'. PC19: deletable terminal states gain summary_halt. Output invariant: output populated when status ∈ {completed, summary_halt} (summary_halt output = summarize model response per BC-2.10.003 PC8(c)); null in all other states. Traceability state machine description updated."
  - "1.5 (notation-sweep-B6/2026-07-29): B6 error-construction notation sweep. EC-003: replaced `PregolyaError { ... }` with `PregolyaError { .. }` — CLASS3_ASCII_ELLIPSIS_VIOLATION (three-dot ASCII form forbidden in prose/observation context; canonical elision marker is two dots per ADR-010 §Error-Construction Notation Canon)."
  - "1.6 (F-P177-B03, burst-288, 2026-08-15): Add `interrupted → cancelled` arc to PC7 (9th arc); extend PC10 to authorize cancellation of `interrupted` Runs. Resolves deadlock: PC19 directed callers to cancel an interrupted Run before deletion, but the arc was absent from PC7 and unauthorized by PC10, making interrupted Runs permanently undeletable."
  - "1.7 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.26 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.8 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.9 (P2A-044 F-08/2026-08-24): Mint E-SERVER-018 RunStateConflict — PC-012 and PC-019 both mandated HTTP 409 for invalid-state-transition but named no error code, leaving the response body unspecified. PC-012 amended to cite E-SERVER-018 for the terminal-state cancel conflict. PC-019 amended to cite E-SERVER-018 for the non-terminal-state delete conflict. EC-006 added covering both scenarios. No arc transitions changed; amendment adds specification precision only."
  - "1.10 (P2A-044 F-06/2026-08-24): compressed-ordinal citations normalized to stable tags."
  - "1.11 (P2A-046 F-3/2026-08-24): same-BC self-ref compressed ordinals normalized to stable tags."
  - "1.12 (P2A-052 F-052-01/2026-08-25): ## VP Anchors section corrected from duplicated Story-Anchor story-ID to 'None' (BC has no Kani VP seed; see §Verification Properties)."
  - "1.13 (P2A-BC-scan-B/2026-08-26): ADR-028 D1-D3 multitask propagation — PC-004 expanded with full lifecycle semantics for multitask_strategy interrupt, rollback, and enqueue: pre-empted run terminal state (cancelled, not interrupted per ADR-028 D1); rollback target (latest_completed_checkpoint_id, delete rows with checkpoint_id > anchor per ADR-028 D2); enqueue FIFO order, max_queued_runs=10 configurable cap, queue-full → E-SERVER-019 RunQueueFull HTTP 429 per ADR-028 D3. EC-007 added for enqueue-queue-full path. TV-008/009/010 added for interrupt/rollback/enqueue strategies. ADR-028 anchor cited throughout new clauses."
  - "1.14 (round-42/F-P2A177-01/2026-08-29): F-P2A177-01 [HIGH, CWE-248/703] — Substantiate node-body panic recovery in EC-003 and mint {INV-007} panic-text-isolation invariant. EC-003 expanded to cover both Err and panic paths: node Err path is unchanged; node-body panic path now specifies `FutureExt::catch_unwind(AssertUnwindSafe(...))` mechanism — panic caught during `.await` polling → `Err(PregolyaError { code: \"E-GRAPH-019\", category: INTERNAL, message: \"NodePanic: graph node panicked during execution — see server error log for details\", retry_hint: Never, .. })`; run transitions `in_progress → failed`; raw panic text logged server-side at ERROR only; NEVER in `Run.error.message` per new {INV-007}; {INV-005} (no orphan runs) upheld — run MUST NOT remain `in_progress` after panic caught. SEC-008 note added to EC-003: `panic = \"unwind\"` required on pregolya-server release profile. {INV-007} added: panic-text-isolation — raw panic text MUST NOT appear in `Run.error.message`; E-GRAPH-019 STATIC message invariant. TV-011 minted: node-body-panic → failed + E-GRAPH-019 + static message + no orphan `in_progress` (TV count 10→11). Traceability Error Codes row added citing E-GRAPH-019."
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

A Run is a single execution of a pregolya graph against a Thread, dispatched by
pregolya-server. This BC specifies the Run creation endpoint, its lifecycle state
machine (`queued → in_progress → completed | failed | cancelled | summary_halt`, with `interrupted` as a pausable/resumable state; `summary_halt` is a budget-summarize terminal state per BC-2.10.003 {PC-008}(d)), and the
failure modes including the `E-SERVER-002 RunNotFound` error. Runs are created synchronously
via `POST /threads/{thread_id}/runs`; execution begins asynchronously. Status can be
polled via `GET /threads/{thread_id}/runs/{run_id}`. No wire-compatibility with
LangGraph Platform (D13).

## Preconditions

1. {PRE-001} `pregolya-server` is running with configured `RunStore`, `CheckpointSaver`, and
   an executor connected to the `pregolya-graph` engine.
2. {PRE-002} A Thread identified by `thread_id` exists (see BC-2.12.001).
3. {PRE-003} The caller holds a valid authentication credential (or server is in dev mode).

## Postconditions

### Create Run (`POST /threads/{thread_id}/runs`)

1. {PC-001} Accepts body:
   ```
   {
     assistant_id: Uuid,
     input?: GraphInput,
     config?: RunnableConfig,
     metadata?: Map<String, Value>,
     multitask_strategy?: "reject" | "interrupt" | "rollback" | "enqueue"
   }
   ```
2. {PC-002} `thread_id` must exist; if not: HTTP 404 with `E-SERVER-003 ThreadNotFound`.
3. {PC-003} `assistant_id` must reference a registered Assistant; if not: HTTP 422.
4. {PC-004} `multitask_strategy` governs concurrent run handling on the same thread (default `"reject"`). Per ADR-028 Decisions 1–3:

   - `"reject"`: if another Run is already `queued` or `in_progress` on the thread → HTTP 409 `{ code: "E-SERVER-012", message: "ConcurrentRun: ..." }`.

   - `"interrupt"` (ADR-028 Decision 1): The pre-empted Run transitions to **`cancelled`** (NOT `interrupted`; `interrupted` is reserved for HITL-pause per BC-2.05.002 {PC-002}; sibling-preempted runs have no resume path). The new Run enters `queued` immediately; HTTP 202 is returned synchronously. The executor MUST NOT start the new Run concurrently with the pre-empted Run's shutdown — the new Run transitions to `in_progress` only AFTER the pre-empted Run's `cancelled` state is durably written to the RunStore. If the pre-empted Run is in `queued` state (not yet started), it transitions `queued → cancelled` without ever reaching `in_progress`. Error path: if the cancellation signal delivery fails (RunStore write error) → `Err(E-SERVER-014 RunStoreFailed)`; the new Run is NOT queued until the pre-empted Run's cancellation is durable.

   - `"rollback"` (ADR-028 Decision 2): The pre-empted Run transitions to `cancelled`. The thread's checkpoint state is reset to the **`latest_completed_checkpoint_id`** captured at the moment `POST .../runs` is processed (the last checkpoint written by the previous completed/failed/cancelled Run). Execution sequence: (1) look up `latest_completed_checkpoint_id`; (2) signal pre-empted Run to cancel; (3) await `cancelled` state (durable RunStore write); (4) delete all checkpoint rows with `checkpoint_id > latest_completed_checkpoint_id` for this thread (bounded delete using the logical-clock monotone property per ADR-005 §Decision); (5) advance thread's `current_checkpoint` pointer back to `latest_completed_checkpoint_id`; (6) start new Run against rolled-back state. If the thread has no prior checkpoint, the rollback target is the empty thread state. Error path: checkpoint discard failure → `Err(E-CHKPT-001 CheckpointWriteFailed)`; new Run NOT started until rollback is complete; partial rollback is not permitted.

   - `"enqueue"` (ADR-028 Decision 3): The new Run is added to the thread's FIFO run queue. Queue bound: `max_queued_runs` (default **10**; configurable per server-instance at startup; applies to the count of Runs in `queued` state on a single thread, excluding the currently `in_progress` Run). If the thread's queued Run count is already at capacity → HTTP 429 `{ code: "E-SERVER-019", message: "RunQueueFull: thread '<thread_id>' already has <queue_depth> queued run(s); max_queued_runs=<max_queued_runs>" }` (EC-007). Ordering: FIFO (`created_at` ascending); when the `in_progress` Run terminates (any terminal state), the executor selects the oldest `queued` Run on the thread and transitions it to `in_progress`.
5. {PC-005} Returns HTTP 202 with `Run { run_id, thread_id, assistant_id, status: "queued", created_at }`.
6. {PC-006} Execution is dispatched asynchronously to the graph executor.

### Run Lifecycle State Machine

7. {PC-007} Lifecycle states and valid transitions:
   ```
   queued      → in_progress   (executor picks up the run)
   in_progress → completed     (graph reaches END)
   in_progress → failed        (unhandled error in graph or executor)
   in_progress → interrupted   (HITL interrupt raised; graph paused, awaiting resume)
   in_progress → cancelled     (POST .../cancel called while run is active)
   in_progress → summary_halt  (OnCeiling::Summarize path: budget ceiling hit; one final summarize LLM call completes; model response returned as output — BC-2.10.003 {PC-008}(c)(d))
   queued      → cancelled     (POST .../cancel called before executor picks up the run)
   interrupted → in_progress   (caller posts resume value via POST .../runs/{run_id}/resume)
   interrupted → cancelled     (POST .../cancel called on an interrupted run)
   ```
8. {PC-008} Terminal states (no further transitions possible): `completed`, `failed`, `cancelled`, and `summary_halt`.
   `interrupted` is **not** terminal — it is a pausable/resumable state.
   `summary_halt` is terminal (no further transitions); it is not cancellable (already terminal when the cancel signal would arrive — HTTP 409 per {PC-012}). A `summary_halt` run IS directly deletable ({PC-019}) without needing a prior cancel step.
9. {PC-009} A Run that is `interrupted` can be resumed via
   `POST /threads/{thread_id}/runs/{run_id}/resume { resume_value }` (see BC-2.05.002
   for HITL contract); this transitions the Run back to `in_progress`.

### Cancel Run (`POST /threads/{thread_id}/runs/{run_id}/cancel`)

10. {PC-010} Cancels a `queued`, `in_progress`, or `interrupted` Run. Signals the executor to stop and transitions
    the Run to `cancelled` status.
11. {PC-011} Cancellation is best-effort: if the run completes naturally before the cancellation
    signal is processed, the status will be `completed` or `failed`, not `cancelled`.
12. {PC-012} Returns HTTP 202 on successful cancellation signal; HTTP 404 `{ code: "E-SERVER-002", message: "RunNotFound: ..." }` if run not found; HTTP 409 `{ code: "E-SERVER-018", message: "RunStateConflict: cannot perform 'cancel' on run '<run_id>' in state '<current_state>'" }` if run is already in a terminal state (EC-006).

### Read Run (`GET /threads/{thread_id}/runs/{run_id}`)

13. {PC-013} Returns `Run { run_id, thread_id, assistant_id, status, output?, error?, created_at, updated_at, completed_at? }`.
    `updated_at` is set on every state mutation. `completed_at` is set only on terminal
    transition (status → `completed` | `failed` | `cancelled` | `summary_halt`); it is `null` in all
    non-terminal states (`queued`, `in_progress`, `interrupted`). Authority: F-P24-01.
14. {PC-014} Returns HTTP 404 with `{ code: "E-SERVER-002", message: "RunNotFound: run '<run_id>' does not exist in thread '<thread_id>'" }` if not found.
15. {PC-015} A completed Run carries `output: GraphOutput` (the final state values).
16. {PC-016} A failed Run carries `error: { code, message, component, category }` from the
    propagated `PregolyaError`.

### List Runs (`GET /threads/{thread_id}/runs`)

17. {PC-017} Returns `{ runs: [Run], total_count: u64 }` for all runs on the thread.
18. {PC-018} Accepts `status` filter query param (`"queued"`, `"in_progress"`, `"completed"`, `"failed"`, `"interrupted"`, `"cancelled"`, `"summary_halt"`) and canonical pagination params: `limit` (default 10, max 100; values > 100 clamped to 100) and `offset` (default 0); results ordered `created_at` descending (F-P31-01, ADV-P1D-PASS-31).

### Delete Run (`DELETE /threads/{thread_id}/runs/{run_id}`)

19. {PC-019} Deletes a Run record that is in a terminal state (`completed`, `failed`, `cancelled`, or `summary_halt`).
    Cannot delete a `queued`, `in_progress`, or `interrupted` Run — HTTP 409 `{ code: "E-SERVER-018", message: "RunStateConflict: cannot perform 'delete' on run '<run_id>' in state '<current_state>'" }` (EC-006).
    For `interrupted` Runs: either resume (POST .../resume) to complete/fail/cancel/summary_halt, or
    cancel first (POST .../cancel → `cancelled`), then delete once terminal.
    **Decision basis (F-02):** DELETE = record deletion only. Separation from cancellation
    follows langgraph-sdk semantics (`runs.cancel()` ≠ delete). Prevents accidental data
    loss on active runs.
20. {PC-020} Returns HTTP 204 on success; HTTP 404 if run not found.

## Invariants

- {INV-001} `run_id` is globally unique within the server instance.
- {INV-002} The executor MUST NOT start a Run that was created in a `queued` state on a different
  server instance without distributed coordination — in single-node deployment, all
  `queued` Runs on startup are retried.
- {INV-003} Run output (`output`) is populated when `status ∈ {"completed", "summary_halt"}`. For
  `summary_halt`, output carries the summarize model response (BC-2.10.003 {PC-008}(c)). It is
  `null` in all other states (`queued`, `in_progress`, `interrupted`, `failed`, `cancelled`).
- {INV-004} Run error (`error`) is populated ONLY when `status = "failed"`. It is `null` in all other states.
- {INV-005} A Run cannot be in `in_progress` state if no executor task is active for it (no orphan runs).
- {INV-006} **Run-Config Merge Precedence (F-P33-02):** When a Create-Run request body supplies `config`,
  `metadata`, or `context`, these values are **deep-merged** over the Assistant's stored values
  at the leaf-key level, with run-supplied keys winning over Assistant-stored keys on any
  collision. Fields absent from the run request body retain the Assistant's stored values
  unchanged. This applies to each of the three fields independently. Merge is applied at run
  creation time before the run is dispatched to the executor; the merged effective config is
  what the graph receives. **Upstream-check result:** BC-2.01.003 {PC-006} specifies that metadata
  "accumulates" down the run tree (consistent with merge; run wins), and semport behavioral-intent
  §2.3 declares no explicit merge rule for run-over-assistant config — no contradiction found.
  Leaf-level deep-merge is adopted as spec canon. Cross-ref: BC-2.12.002 §Description.

- {INV-007} **Panic-text-isolation:** Raw panic text from node-body panics MUST NOT appear in
  `Run.error.message`. The `pregolya-server` run-executor converts node-body panics caught by
  `FutureExt::catch_unwind(AssertUnwindSafe(...))` to `E-GRAPH-019 NodePanic` with a STATIC
  message; the raw panic text is logged at ERROR severity server-side only. `Run.error.message`
  derives SOLELY from the E-GRAPH-019 STATIC message:
  `"NodePanic: graph node panicked during execution — see server error log for details"`.
  No dynamic content from the panic (backtrace, panic message, source location) is included.
  This prevents information disclosure (CWE-209) via the Run status polling endpoint.

## Edge Cases

### EC-001: Create Run on non-existent thread
**Scenario:** `POST /threads/ghost/runs { ... }`.
**Expected behavior:** HTTP 404 `{ code: "E-SERVER-003", message: "ThreadNotFound: thread 'ghost' does not exist" }`. No Run is created.

### EC-002: Concurrent run with multitask_strategy=reject (default)
**Scenario:** Thread "t1" has an `in_progress` Run; another `POST /threads/t1/runs` arrives with
default `multitask_strategy`.
**Expected behavior:** HTTP 409 `{ code: "E-SERVER-012", message: "ConcurrentRun: thread 't1' already has an active run; use multitask_strategy to override" }`.

### EC-003: Run fails due to unhandled graph error or node-body panic
**Scenario:** A graph node returns `Err(PregolyaError { .. })` or panics during execution.
**Expected behavior (node returns Err):** `GraphRunner` propagates `Err(PregolyaError { .. })`.
Run transitions `in_progress → failed` with `error` populated from the `PregolyaError`.
DI-014 ensures the error is not silently swallowed. The thread's checkpoint state reverts
to the last successful checkpoint before the failed Run.
**Expected behavior (node body PANICS):** The `pregolya-server` run-executor wraps graph
execution in `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(...))`. A panic in
a node body during `.await` polling is caught; the executor converts it to:
`Err(PregolyaError { code: "E-GRAPH-019", category: INTERNAL,
message: "NodePanic: graph node panicked during execution — see server error log for details",
retry_hint: Never, .. })`.
Run transitions `in_progress → failed` with `error` populated from the E-GRAPH-019 STATIC
message. Raw panic text is logged server-side at ERROR severity only — it MUST NEVER appear
in `Run.error.message` (panic-text-isolation per {INV-007}). The run MUST NOT remain in
`in_progress` state after the panic is caught — {INV-005} (no orphan runs) is upheld.
The thread's checkpoint state reverts to the last successful checkpoint before the failed Run.
**Both paths:** DI-014 ensures neither error is silently swallowed.
**SEC-008:** This panic recovery requires `panic = "unwind"` on the `pregolya-server`
release profile; `panic = "abort"` voids the catch and causes process termination (CWE-248).

### EC-004: Get run with wrong thread_id
**Scenario:** `GET /threads/t2/runs/<run_id>` where the run belongs to thread `t1`.
**Expected behavior:** HTTP 404 `E-SERVER-002 RunNotFound`. The run exists but is
scoped to a different thread — cross-thread run access is not permitted.

### EC-005: Delete an active (in_progress) run
**Scenario:** `DELETE /threads/t1/runs/<run_id>` while `status = "in_progress"`.
**Expected behavior:** HTTP 409 `{ code: "E-SERVER-018", message: "RunStateConflict: cannot perform 'delete' on run '<run_id>' in state 'in_progress'" }`. Caller must cancel the run first (`POST /threads/t1/runs/<run_id>/cancel`), wait for terminal state, then delete.

### EC-006: Invalid state transition — operation on run in incompatible state (P2A-044 F-08)
**Scenario:** Any operation that the Run state machine does not permit in the Run's current state: (a) `POST .../cancel` on a Run in a terminal state (`completed`, `failed`, `cancelled`, `summary_halt`); (b) `DELETE .../runs/{run_id}` on a Run in a non-terminal state (`queued`, `in_progress`, `interrupted`). Distinct from EC-002 (ConcurrentRun / E-SERVER-012) which is about a second Run conflicting on the same Thread, not about an invalid transition on an existing Run.
**Expected behavior:** HTTP 409 `{ code: "E-SERVER-018", message: "RunStateConflict: cannot perform '<operation>' on run '<run_id>' in state '<current_state>'" }`. Three struct fields: `run_id` (String), `current_state` (String), `operation` (String, value `"cancel"` or `"delete"`). The run record is not mutated; no state change occurs. Caller must first bring the run to a compatible state before retrying (e.g., wait for natural completion, or use the correct endpoint). Error code: E-SERVER-018 RunStateConflict (POLICY; RetryHint: Never — the same operation on the same terminal/non-terminal run always fails while the state persists).

### EC-007: Enqueue queue full — max_queued_runs reached (ADR-028 Decision 3) {EC-007}
**Scenario:** Thread `"t1"` has one `in_progress` Run and 10 `queued` Runs (default `max_queued_runs=10`). A new `POST /threads/t1/runs { multitask_strategy: "enqueue" }` arrives.
**Expected behavior:** HTTP 429 `{ code: "E-SERVER-019", message: "RunQueueFull: thread 't1' already has 10 queued run(s); max_queued_runs=10" }`. No new Run is created. The caller should wait for the `in_progress` Run to reach a terminal state (freeing a queue slot) and then retry. RetryHint: Later (queue slot opens when the in_progress run completes — ADR-028 Decision 3).

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
| TV-008 | Thread `t1` has active `in_progress` Run `r1`; `POST /threads/t1/runs { multitask_strategy: "interrupt" }` | HTTP 202, new Run `r2` in `queued`; `r1` transitions to `cancelled`; after `r1` cancelled durably, `r2` transitions to `in_progress` | multitask_strategy=interrupt |
| TV-009 | Thread `t1` has active Run `r1` (3 checkpoints written); `POST /threads/t1/runs { multitask_strategy: "rollback" }` | HTTP 202, new Run `r2`; `r1` transitions to `cancelled`; checkpoint rows from `r1` deleted (only rows up to `latest_completed_checkpoint_id` retained); `r2` starts against rolled-back state | multitask_strategy=rollback |
| TV-010 | Thread `t1` has active `in_progress` Run `r1` and 10 `queued` Runs (queue at capacity); `POST /threads/t1/runs { multitask_strategy: "enqueue" }` | HTTP 429 `E-SERVER-019 RunQueueFull` | multitask_strategy=enqueue queue-full |
| TV-011 | Run `r1` on thread `t1` is `in_progress`; a graph node body calls `panic!("unexpected node failure")`; poll `GET /threads/t1/runs/r1` | Run `r1` transitions to `status: "failed"` (NOT `in_progress`); `error.code == "E-GRAPH-019"`; `error.message == "NodePanic: graph node panicked during execution — see server error log for details"` (STATIC — literal string equality); `error.message` does NOT contain `"unexpected node failure"` or any other panic text; no run remains orphaned in `in_progress` state | Node-body panic → E-GRAPH-019 STATIC message; panic-text-isolation ({INV-007}); no orphan `in_progress` ({INV-005}); EC-003 node-body-panic path; SEC-008 requires `panic = "unwind"` on pregolya-server release profile (CWE-248) |

## Verification Properties

_No Kani VP seed required. Integration tests against in-process pregolya-server and
pregolya-graph engine are sufficient._

## Related BCs

- BC-2.12.001 — depends on: Runs are executed against Threads; thread must exist before run creation
- BC-2.12.002 — depends on: Runs reference an Assistant config at creation time
- BC-2.05.002 — sibling: HITL interrupt resume contract covers the `interrupted` pausable state resume path (interrupted → in_progress transition)

## Architecture Anchors

- `pregolya-server/src/api/runs.rs` — Run CRUD handlers
- `pregolya-server/src/executor.rs` — Async executor dispatching pending runs to graph engine
- `pregolya-server/src/store/run_store.rs` — `RunRecord` and lifecycle state persistence

## Story Anchor

S-1.26

## VP Anchors

None

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — this BC implements the Run resource lifecycle, which is explicitly listed as the third of the four managed resources: "Run (single execution)". Canonical state machine: queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable ({PC-007}-{PC-009} are the authoritative source; see {PC-007} for transition arcs, {PC-008} for terminal-set definition, {PC-009} for interrupted→in_progress resume arc) |
| L2 Domain Invariants | — |
| DEC Reference | DEC-006 (Resume Value Injection with Empty Interrupt Queue — applies to the `interrupted` state resume path) |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration), E2E (end-to-end) |
| Module | pregolya-server |
| Error Codes | E-GRAPH-019 NodePanic (INTERNAL, broken, Never) — minted at this BC's EC-003 node-body-panic path ({INV-007} panic-text-isolation enforcer); STATIC message: "NodePanic: graph node panicked during execution — see server error log for details"; raised by pregolya-server run-executor when `FutureExt::catch_unwind` catches a node-body panic during `.await` polling; raw panic text suppressed at BC boundary (CWE-209) |
