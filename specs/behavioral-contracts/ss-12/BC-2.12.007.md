---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.007
version: "2.1"
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
timestamp: 2026-08-24T01:00:00Z
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
input-hash: "a1ab276"
changelog:
  - "1.0 (initial): base BC authored."
  - "1.1 (ADV-P1D-PASS-29): F-P29-03 — replace non-canonical `node_delta` with canonical `node_stream` at PC2, EC-004, and TV-002. BC-2.06.001 is the streaming taxonomy authority; `node_delta` was never a valid variant. Added to retired-identifier registry (bc-authoring-plan.md gate #19)."
  - "1.2 (ADV-P1D-PASS-46): F-P46-01 — fix streaming × interrupt seam contradiction with BC-2.06.001 (the declared streaming taxonomy authority). TV-005: remove `run_end.status = interrupted`; interrupt envelope is the terminal SSE frame, no run_end emitted. EC-003: fix 'stream ends with status: interrupted' → stream truncates after interrupt envelope; run status queryable via REST only. EC-001: resolve hedge '(or a run_end with status: failed)' — definitive: stream closes with no run_end on failure; authority is BC-2.06.001 EC-005 (completion-only RunEnd contract)."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-server / pregolya-graph per module-decomposition.md v1.10."
  - "1.4 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
  - "1.5 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.27 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.6 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.7 (P2A-043/F-05 adjudication/2026-08-24): Author EC-006 — non-first-node mid-run failure, run_end NOT emitted. EC-001 was scoped to 'first node'; INV-003 covers error equivalence but did not explicitly state the no-run_end rule for mid-run failure. EC-006 closes that gap; authority is BC-2.06.001 EC-005 (completion-only RunEnd contract)."
  - "1.8 (P2A-044 F-06/2026-08-24): compressed-ordinal citations normalized to stable tags."
  - "1.9 (round-46/F-P2A195-01+F-P2A195-03/2026-08-30): F-P2A195-01 [HIGH] — VP-DI011-02 static-analysis anchor corrected: phantom `CompiledGraph.invoke` (dot notation, non-canonical type) → `CompiledStateGraph::invoke` (canonical per BC-2.02.001 {PC-001}; Rust :: path). VP-DI011-02 is the SOLE mechanized DI-011 defense against the CONFLICT-10/NE-13 streaming-stub counter-example. F-P2A195-03 [MED] — non-canonical type `CompiledGraph` corrected to `CompiledStateGraph` at five live-body sites: §Description, {PRE-001}, {PC-005}, {INV-001}, §Architecture Anchors. Historical changelog entries grandfathered per append_only_numbering policy."
  - "2.0 (round-48/F-P2A201-01+F-P2A203-01/2026-08-30): F-P2A201-01 [HIGH, CWE-209/532] + F-P2A203-01 [HIGH, CWE-209/532] — SSE boundary bypasses SEC-BOUND-001 (3rd external boundary). {INV-003} reconciled: 'same PregolyaError cause' → 'same SANITIZED PregolyaError cause' per SEC-BOUND-001 parity requirement; both surfaces now explicitly apply the 3-step pipeline before emission. {INV-004} added: External-Boundary Error-Sanitization (SEC-BOUND-001) — mandatory 3-step pipeline (internal-panic static-replace [E-GRAPH-011 + E-GRAPH-019] → redact_credentials [4-pattern set] → sanitize_internal_ids [UUID-shaped only; u64-CheckpointId carve-out]) on BOTH the SSE `StreamEvent::Error.error_message` AND the unary non-2xx error body BEFORE emission; references ADR-029 §SEC-BOUND-001; mirrors BC-2.12.003 {INV-007}/{INV-008}; closes 3rd external boundary gap. EC-001 and EC-006 updated to reference sanitized error. TV-007 minted (E-GRAPH-011 static-replace on SSE surface; TV count 6→7). TV-008 minted (E-GRAPH-019 static-replace on SSE surface; TV count 7→8). TV-009 minted (Bearer-token credential redaction on SSE surface; TV count 8→9)."
  - "2.1 (round-49/F-P2A205-02-sibling/2026-08-31): F-P2A205-02 sibling sweep — {INV-004} step 2 canonical pattern set extended from 4 to 6 patterns: pattern 5 URL-embedded userinfo `[a-zA-Z][a-zA-Z0-9+.\\-]*://[^/\\s:@]+:[^/\\s:@]+@` → `<redacted>`; pattern 6 HTTP Basic auth `Basic\\s+[A-Za-z0-9+/=]+` → `<redacted>`. 'four-pattern set' → 'six-pattern set'. BC-2.09.007 {INV-003}(b) is the canonical authority. No new TVs minted (TV-009 already tests Bearer-token path; URL-userinfo and Basic-auth coverage tested via TV-012/TV-013 in BC-2.09.007)."
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.007: Streaming Endpoint and Unary Endpoint Drive Same Graph Engine, Same Final Answer

## Description

`pregolya-server` exposes two run execution surfaces: `GET /threads/{thread_id}/runs/{run_id}/stream`
(server-sent events) and `GET /threads/{thread_id}/runs/{run_id}` (unary polling response
after a Run reaches `completed` status). Both surfaces must be driven by the
**same `CompiledStateGraph` execution engine** for the same inputs and produce
an **identical final answer**. There is no stub path, no cached task-state replay, and
no code divergence between the two handlers beyond how output is surfaced to the HTTP
client. This contract is the direct correction of the adk-rust counter-example
(CONFLICT-10): a streaming stub that emitted task-state events without invoking the
graph engine, producing output that could diverge from the unary path.

## Preconditions

1. {PRE-001} A `CompiledStateGraph` is registered with an `Assistant` (`assistant_id`).
2. {PRE-002} A `Run` is created for that `Assistant` on a given `thread_id` with a given input.
3. {PRE-003} Both the streaming endpoint (`GET /threads/{thread_id}/runs/{run_id}/stream`)
   and the unary polling endpoint (`GET /threads/{thread_id}/runs/{run_id}`,
   polled after `POST /threads/{thread_id}/runs` creates the Run) are available.
4. {PRE-004} The same input, same `thread_id`, and same `RunnableConfig` are used for both execution
   paths (tested with two fresh threads of identical initial state, or via a
   deterministic graph with no side effects).

## Postconditions

1. {PC-001} The unary endpoint returns `{ "output": <final_answer>, "status": "completed" }` in
   a single JSON response after the Run completes.
2. {PC-002} The streaming endpoint emits a sequence of server-sent events (SSE) including:
   - One `run_start` event
   - One or more `node_start`, `node_stream`, `node_end` events (per graph node
     executed; `node_stream` appears once per token/chunk for streaming nodes, zero times for synchronous nodes)
   - One `run_end` event with `output: <final_answer>`
3. {PC-003} The `output` value in the streaming `run_end` event is byte-for-byte identical to
   the `output` value in the unary endpoint response, given the same graph and same
   inputs.
4. {PC-004} The streaming endpoint's `run_end` event carries the same `run_id`, `status`,
   and `output` fields as the unary endpoint response.
5. {PC-005} There is no code path in the streaming handler that produces output without invoking
   the `CompiledStateGraph` (no stub, no hardcoded response, no mock event sequence).

## Invariants

- {INV-001} **DI-011 (Streaming / Unary Run Equivalence):** The same `CompiledStateGraph` instance is
  invoked by both handlers; the only difference is the output adapter (stream vs. collect).
- {INV-002} A `Run` cannot be simultaneously executed via both the streaming and unary endpoints
  for the same `run_id`; the first request claims execution and the second receives
  `409 Conflict` with `E-SERVER-015 RunAlreadyExecuting { run_id }`.
- {INV-003} If the graph raises an error mid-execution, both the streaming endpoint (as an
  `error` SSE event) and the unary endpoint (as a non-2xx response body) surface the
  same **sanitized** `PregolyaError` cause — both surfaces apply the SEC-BOUND-001 3-step
  sanitization pipeline per {INV-004} before emission.

- {INV-004} **External-Boundary Error-Sanitization (SEC-BOUND-001; DI-010 Credential Opacity; CWE-209/CWE-532):**
  `pregolya-server` MUST apply the following 3-step sanitization pipeline to error content
  BEFORE emission on BOTH the SSE surface (`StreamEvent::Error.error_message`) AND the
  unary non-2xx error body. Pipeline order is mandatory: step 1 THEN step 2 THEN step 3.
  1. **Internal-panic static-replace** (per BC-2.12.003 {INV-007}): if `error.code ∈
     {"E-GRAPH-011", "E-GRAPH-019"}`, replace the error message with the corresponding STATIC
     message — no dynamic panic text, no `source_node` topology:
     - E-GRAPH-011: `"ConditionalEdgePanic: conditional edge function panicked during
       execution — see server error log for details"`
     - E-GRAPH-019: `"NodePanic: graph node panicked during execution — see server error
       log for details"`
  2. **`redact_credentials`**: apply the canonical six-pattern set (BC-2.09.007 {INV-003}(b)):
     (1) `sk-[A-Za-z0-9_\-]{20,}`, (2) `sk-ant-[A-Za-z0-9_\-]{32,}`, (3) `[A-Za-z0-9]{64,}`,
     (4) `Bearer\s+[A-Za-z0-9._~+/=\-]+`, (5) `[a-zA-Z][a-zA-Z0-9+.\-]*://[^/\s:@]+:[^/\s:@]+@`
     (URL-embedded userinfo), (6) `Basic\s+[A-Za-z0-9+/=]+` (HTTP Basic auth) — replace each
     match with `"<redacted>"`. Symmetric with BC-2.12.003 {INV-008} step 2.
  3. **`sanitize_internal_ids`**: replace UUID-shaped internal identifiers (run IDs, internal
     trace IDs, node instance IDs not already disclosed to the caller) with `"<redacted-id>"`.
     `u64` CheckpointId is NOT UUID-shaped and is NOT covered by this pass; authoring-site
     discipline (BC-2.09.008 {INV-001}) is its sole framework guarantee. Symmetric with
     BC-2.12.003 {INV-008} step 3.
  This closes the 3rd external boundary gap (SSE streaming + unary error body) under ADR-029
  §External-Boundary Error-Sanitization Parity (SEC-BOUND-001). Boundary inventory after this
  fix: MCP content (BC-2.09.008 {INV-003}); HTTP Run-status polling (BC-2.12.003 {INV-008});
  SSE streaming + unary error body (this BC {INV-004}).

## Edge Cases

### EC-001: Graph raises error in first node
**Scenario:** A node raises `Err(PregolyaError)` in the first executed node.
**Expected behavior:**
- Streaming: `run_start` emitted; `node_start` for the failing node emitted; then an
  `error` SSE event with the error payload; the stream closes with **no `run_end` event**.
  `RunEnd` is reserved for the completion path only (BC-2.06.001 {PC-002} + EC-005 authority:
  completion-only `RunEnd` contract). Run status queryable via
  `GET /threads/{thread_id}/runs/{run_id}` = `failed`.
- Unary: `422 Unprocessable Entity` (or `500`, depending on error category) with the
  same `PregolyaError` payload, sanitized per {INV-004}.

### EC-002: Streaming client disconnects mid-run
**Scenario:** An HTTP client opens the SSE stream but closes the connection mid-execution.
**Expected behavior:** The graph execution continues to completion in the background.
The `Run` record transitions to `completed` or `failed` normally. The partial stream is
lost (not buffered for reconnect in v1). A future `GET /threads/{thread_id}/runs/{run_id}` reflects the
final `status` and `output`.

### EC-003: Graph with interrupt inside node
**Scenario:** A node calls `interrupt(value)` mid-execution (see BC-2.05.001).
**Expected behavior:**
- Streaming: emits `{"__interrupt__": [InterruptPayload]}` as the **terminal SSE frame**;
  stream truncates after the interrupt envelope. **No `run_end` SSE event is emitted.**
  (BC-2.06.001 TV-004 authority: "RunEnd not emitted for interrupted run | Interrupt
  truncates event stream at boundary.") Run status queryable via
  `GET /threads/{thread_id}/runs/{run_id}` = `interrupted`. Resume produces a new
  `RunStart` sequence (BC-2.06.001 Related BCs, BC-2.05.004).
- Unary: response body is `{"__interrupt__": [InterruptPayload], "status": "interrupted"}`.
Both surfaces carry the same interrupt payload.

### EC-004: Very large output (>1 MB)
**Scenario:** A graph produces a final answer exceeding 1 MB (e.g., large RAG synthesis).
**Expected behavior:** The streaming endpoint emits the output in `node_stream` chunks,
with no truncation. The unary endpoint returns the full output in a single response.
Both outputs are identical in content; no data loss occurs in either path.

### EC-006: Graph raises error in non-first node (mid-run) — no run_end emitted
**Scenario:** A multi-node graph executes nodes 1..N-1 successfully; node N returns
`Err(PregolyaError)` mid-run (after at least one prior `node_start`/`node_end` pair has
already been emitted to the stream).
**Expected behavior:**
- Streaming: `run_start`, `node_start`/`node_end` pairs for all prior nodes, then
  `node_start` for the failing node N; then `StreamEvent::Error` with the error payload
  (`run_id`, `parent_ids`, `error_code`, `error_message`); stream closes. **No `run_end`
  event is emitted.** The completion-only `RunEnd` contract applies regardless of how many
  prior nodes executed successfully (authority: BC-2.06.001 EC-005).
  Run status queryable via `GET /threads/{thread_id}/runs/{run_id}` = `failed`.
- Unary: `4xx/5xx` response with the same sanitized `PregolyaError` as the streaming path ({INV-003}/{INV-004}).
**Distinction from EC-001:** EC-001 covers first-node failure (only `run_start` +
`node_start` precede the error); EC-006 covers mid-run failure where partial successful
output has already been streamed. The no-run_end rule is identical in both cases.

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
| TV-002 | Streaming run on 3-node graph (streaming LLM nodes) | SSE stream contains: `run_start`, (`node_start` → `node_stream`×N → `node_end`)×3, `run_end`; `node_stream` events present for each streaming token per node | Event taxonomy: DI-011 streaming surface; canonical streaming-node token is `node_stream` per BC-2.06.001 |
| TV-003 | Graph with error in node 2; streaming | SSE: `run_start`, `node_start` (node1), `node_end` (node1), `node_start` (node2), then `error` event with `PregolyaError`; stream closes | Error propagation via streaming |
| TV-004 | Graph with error in node 2; unary | `4xx/5xx` response with same `PregolyaError` as TV-003 | Error equivalence: streaming = unary |
| TV-005 | Graph with `interrupt()` call; streaming | SSE emits `{"__interrupt__": [...]}` as the terminal frame; stream truncates; **no `run_end` event emitted**; run status = `interrupted` queryable via `GET /threads/{thread_id}/runs/{run_id}` | Interrupt via streaming surface; BC-2.06.001 TV-004 authority — completion-only RunEnd |
| TV-006 | Concurrent `GET /threads/t1/runs/r1/stream` (streaming) and a second `GET /threads/t1/runs/r1/stream`; second arrives 10ms later | Second returns `409 Conflict`, `E-SERVER-015 RunAlreadyExecuting` | Concurrent execution guard |
| TV-007 | A conditional-edge `path_fn` panics mid-run (surfaces as E-GRAPH-011 ConditionalEdgePanic); streaming endpoint | SSE: `run_start`, prior `node_start`/`node_end` pairs for preceding nodes, then `error` event with `error_message == "ConditionalEdgePanic: conditional edge function panicked during execution — see server error log for details"` (STATIC — literal string equality); `source_node` topology suppressed; no raw panic text in `error_message`; stream closes; run status = `failed` | E-GRAPH-011 static-replace on SSE surface per {INV-004} step 1; mirrors BC-2.12.003 TV-012 on HTTP Run-status surface; closes F-P2A201-01/F-P2A203-01 SSE boundary gap |
| TV-008 | A graph node body panics during execution (surfaces as E-GRAPH-019 NodePanic via `FutureExt::catch_unwind`); streaming endpoint | SSE: `run_start`, `node_start` for failing node, then `error` event with `error_message == "NodePanic: graph node panicked during execution — see server error log for details"` (STATIC — literal string equality); no raw panic text in `error_message`; stream closes; run status = `failed` | E-GRAPH-019 static-replace on SSE surface per {INV-004} step 1; mirrors BC-2.12.003 TV-011 on HTTP Run-status surface; closes F-P2A201-01/F-P2A203-01 SSE boundary gap |
| TV-009 | A graph node returns `Err(PregolyaError { code: "E-GRAPH-003", message: "provider auth failed: Bearer eyJhbGciOiJIUzI1NiJ9.short_opaque_token", .. })`; streaming endpoint | SSE: `error` event with `error_message` NOT containing `"Bearer eyJhbGciOiJIUzI1NiJ9.short_opaque_token"` or any Bearer-token span; `Bearer <token>` replaced with `"<redacted>"` per {INV-004} step 2 pattern 4; stream closes; run status = `failed` | Bearer-token credential redaction on SSE surface ({INV-004} step 2); Bearer pattern (BC-2.09.007 {INV-003}(b) pattern 4) closes gap for short opaque tokens not matching provider-key patterns 1–3; closes F-P2A203-01 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI011-01 | Streaming and unary endpoints produce identical `output` JSON for the same graph + input | Integration test (deterministic graph; compare outputs byte-for-byte) | Phase 1 |
| VP-DI011-02 | Streaming handler code path passes through `CompiledStateGraph::invoke`; no stub path exists | Static analysis (ensure no streaming handler returns a response without calling graph execute) | Phase 1 |

## Related BCs

- BC-2.06.003 — depends on: global streaming/unary equivalence is the graph-layer contract; this BC is the server-layer enforcement of the same invariant
- BC-2.05.001 — related to: interrupt payload equivalence across streaming and unary surfaces
- BC-2.10.003 — related to: budget ceiling halt produces same error via both surfaces

## Architecture Anchors

- `pregolya-server/src/routes/runs.rs` — both streaming and unary handlers call shared `execute_run(graph, input, config)` fn
- `pregolya-graph/src/scheduler.rs` (`graph::scheduler`) — single `CompiledStateGraph` execution path shared by both handlers
- `pregolya-server/src/sse.rs` — SSE adapter wraps `CompiledStateGraph` stream output for HTTP transport

## Story Anchor

S-1.27

## VP Anchors

- VP-DI011-01, VP-DI011-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — "Streaming and unary run endpoints drive the same graph execution engine" is verbatim text in the CAP-014 description |
| L2 Domain Invariants | DI-011 (Streaming / Unary Run Equivalence) |
| NE Reference | NE-13 — streaming/unary equivalence mandate (adk-rust streaming stub that never invokes engine is the counter-example) |
| CONFLICT Reference | CONFLICT-10 — adk-rust streaming stub emitting task-state events without invoking graph engine is the direct counter-example |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration), S (static analysis) |
| Module | pregolya-server / pregolya-graph |
