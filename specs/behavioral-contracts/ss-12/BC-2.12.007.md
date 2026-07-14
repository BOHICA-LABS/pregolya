---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.007
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-12
capability: CAP-014
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
  - domain-spec/invariants.md#DI-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/platform/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "36380e5449ee7f2e14d04b727a5c3c6d66881f2ce4d460037d3d7a5821de470b"
---

# BC-2.12.007: Streaming Endpoint and Unary Endpoint Drive Same Graph Engine, Same Final Answer

## Description

`ferrochain-server` exposes two run execution surfaces: `POST /runs/{id}/stream`
(server-sent events) and `POST /runs/{id}` (unary response). Both endpoints must
invoke the **same `CompiledGraph` execution engine** for the same inputs and produce
an **identical final answer**. There is no stub path, no cached task-state replay, and
no code divergence between the two handlers beyond how output is surfaced to the HTTP
client. This contract is the direct correction of the adk-rust counter-example
(CONFLICT-10): a streaming stub that emitted task-state events without invoking the
graph engine, producing output that could diverge from the unary path.

## Preconditions

1. A `CompiledGraph` is registered with an `Assistant` (`assistant_id`).
2. A `Run` is created for that `Assistant` on a given `thread_id` with a given input.
3. Both the streaming endpoint (`GET /runs/{run_id}/stream` or
   `POST /runs/{run_id}/stream`) and the unary endpoint (`POST /runs` with
   `stream: false`) are available.
4. The same input, same `thread_id`, and same `RunConfig` are used for both execution
   paths (tested with two fresh threads of identical initial state, or via a
   deterministic graph with no side effects).

## Postconditions

1. The unary endpoint returns `{ "output": <final_answer>, "status": "completed" }` in
   a single JSON response after the Run completes.
2. The streaming endpoint emits a sequence of server-sent events (SSE) including:
   - One `run_start` event
   - One or more `node_start`, `node_delta`, `node_end` events (per graph node
     executed)
   - One `run_end` event with `output: <final_answer>`
3. The `output` value in the streaming `run_end` event is byte-for-byte identical to
   the `output` value in the unary endpoint response, given the same graph and same
   inputs.
4. The streaming endpoint's `run_end` event carries the same `run_id`, `status`,
   and `output` fields as the unary endpoint response.
5. There is no code path in the streaming handler that produces output without invoking
   the `CompiledGraph` (no stub, no hardcoded response, no mock event sequence).

## Invariants

- **DI-011 (Streaming/Unary Run Equivalence):** The same `CompiledGraph` instance is
  invoked by both handlers; the only difference is the output adapter (stream vs. collect).
- A `Run` cannot be simultaneously executed via both the streaming and unary endpoints
  for the same `run_id`; the first request claims execution and the second receives
  `409 Conflict` with `E-SERVER-015 RunAlreadyExecuting { run_id }`.
- If the graph raises an error mid-execution, both the streaming endpoint (as an
  `error` SSE event) and the unary endpoint (as a non-2xx response body) surface the
  same `FerrochainError` cause.

## Edge Cases

### EC-001: Graph raises error in first node
**Scenario:** A node raises `Err(FerrochainError)` in the first executed node.
**Expected behavior:**
- Streaming: `run_start` emitted; `node_start` for the failing node emitted; then an
  `error` SSE event with the error payload; the stream closes with no `run_end` event
  (or a `run_end` with `status: "failed"`).
- Unary: `422 Unprocessable Entity` (or `500`, depending on error category) with the
  same `FerrochainError` payload.

### EC-002: Streaming client disconnects mid-run
**Scenario:** An HTTP client opens the SSE stream but closes the connection mid-execution.
**Expected behavior:** The graph execution continues to completion in the background.
The `Run` record transitions to `completed` or `failed` normally. The partial stream is
lost (not buffered for reconnect in v1). A future `GET /runs/{run_id}` reflects the
final `status` and `output`.

### EC-003: Graph with interrupt inside node
**Scenario:** A node calls `interrupt(value)` mid-execution (see BC-2.05.001).
**Expected behavior:**
- Streaming: emits `{"__interrupt__": [InterruptPayload]}` as an SSE event; stream
  ends with `status: interrupted`.
- Unary: response body is `{"__interrupt__": [InterruptPayload], "status": "interrupted"}`.
Both surfaces carry the same interrupt payload.

### EC-004: Very large output (>1 MB)
**Scenario:** A graph produces a final answer exceeding 1 MB (e.g., large RAG synthesis).
**Expected behavior:** The streaming endpoint emits the output in `node_delta` chunks,
with no truncation. The unary endpoint returns the full output in a single response.
Both outputs are identical in content; no data loss occurs in either path.

### EC-005: Concurrent requests for same run_id on both paths
**Scenario:** Two concurrent HTTP requests both attempt to execute `run_id = "r1"`:
one via streaming, one via unary.
**Expected behavior:** First request proceeds; second request receives `409 Conflict`
with `E-SERVER-015 RunAlreadyExecuting`. The successfully executing request completes
normally.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Same graph + same fresh thread; execute via streaming; collect `run_end.output`; execute via unary on identical fresh thread; compare `output` | `run_end.output == unary.output` (byte-for-byte JSON equality) | Core DI-011 verification |
| TV-002 | Streaming run on 3-node graph | SSE stream contains: `run_start`, `node_start`×3, `node_end`×3, `run_end` (in topological order) | Event taxonomy: DI-011 streaming surface |
| TV-003 | Graph with error in node 2; streaming | SSE: `run_start`, `node_start` (node1), `node_end` (node1), `node_start` (node2), then `error` event with `FerrochainError`; stream closes | Error propagation via streaming |
| TV-004 | Graph with error in node 2; unary | `4xx/5xx` response with same `FerrochainError` as TV-003 | Error equivalence: streaming = unary |
| TV-005 | Graph with `interrupt()` call; streaming | SSE emits `{"__interrupt__": [...]}` event; `run_end.status = interrupted` | Interrupt via streaming surface |
| TV-006 | Concurrent `POST /runs/r1` (unary) and `POST /runs/r1/stream`; second arrives 10ms later | Second returns `409 Conflict`, `E-SERVER-015 RunAlreadyExecuting` | Concurrent execution guard |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI011-01 | Streaming and unary endpoints produce identical `output` JSON for the same graph + input | Integration test (deterministic graph; compare outputs byte-for-byte) | Phase 1 |
| VP-DI011-02 | Streaming handler code path passes through `CompiledGraph.invoke`; no stub path exists | Static analysis (ensure no streaming handler returns a response without calling graph execute) | Phase 1 |

## Related BCs

- BC-2.06.003 — depends on: global streaming/unary equivalence is the graph-layer contract; this BC is the server-layer enforcement of the same invariant
- BC-2.05.001 — related to: interrupt payload equivalence across streaming and unary surfaces
- BC-2.10.003 — related to: budget ceiling halt produces same error via both surfaces

## Architecture Anchors

- `ferrochain-server/src/routes/runs.rs` — both streaming and unary handlers call shared `execute_run(graph, input, config)` fn
- `ferrochain-graph/src/pregel/loop.rs` — single `CompiledGraph` execution path shared by both handlers
- `ferrochain-server/src/sse.rs` — SSE adapter wraps `CompiledGraph` stream output for HTTP transport

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-DI011-01, VP-DI011-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — "Streaming and unary run endpoints drive the same graph execution engine" is verbatim text in the CAP-014 description |
| L2 Domain Invariants | DI-011 (Streaming/Unary Run Equivalence) |
| NE Reference | NE-13 — streaming/unary equivalence mandate (adk-rust streaming stub that never invokes engine is the counter-example) |
| CONFLICT Reference | CONFLICT-10 — adk-rust streaming stub emitting task-state events without invoking graph engine is the direct counter-example |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration), S (static analysis) |
| Module | [architect to assign — ferrochain-server, ferrochain-graph] |
