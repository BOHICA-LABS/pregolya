---
document_type: behavioral-contract
level: L3
bc_id: BC-2.03.002
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-03
capability: CAP-004
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-004
  - domain-spec/invariants.md#DI-001
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/behavioral-intent.md
input-hash: "147ddda"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.03.002: Concurrent LastValue Write Rejection Raises InvalidUpdateError

## Description

When two or more `PregelTask`s in the same super-step both write to the same `LastValue`
channel, the BSP scheduler must reject the operation with `E-GRAPH-001 InvalidUpdateError`
rather than silently racing to a non-deterministic result. The run transitions to `failed`
state. The error records which tasks wrote to which channel and which super-step number.
This is the enforcement mechanism for DI-001's concurrent-write prohibition.

## Preconditions

1. A `StateGraph` has a `LastValue` channel (not `Append`, `BarrierValue`, or other multi-writer channel).
2. In a single super-step, two or more scheduled `PregelTask`s both produce writes to the same `LastValue` channel.
3. The writes arrive at the reducer phase (they are not filtered out before reducer application).

## Postconditions

1. The run does NOT commit a final channel value for the contested `LastValue` channel.
2. The run transitions to `failed` state.
3. `Err(FerrochainError { component: GRAPH, category: CONCURRENCY, code: E-GRAPH-001, retry_hint: Never, message: "InvalidUpdateError: concurrent writes to LastValue channel '<channel>' from tasks [<task_ids>] in super-step <n>" })` is returned to the run caller.
4. The error's `message` field includes:
   - The channel name
   - All task IDs that attempted to write (sorted for determinism)
   - The super-step number
5. Writes to different channels from the same tasks are unaffected — only the conflicting channel is rejected.
6. The checkpoint for the failed super-step is NOT written (the state before the super-step is preserved).

## Invariants

- **DI-001 (BSP Reducer Determinism):** Concurrent writes to a `LastValue` channel from the same super-step are an invariant violation — they cannot produce a deterministic result and must be rejected immediately.
- A `LastValue` channel has exactly-one-writer semantics within a super-step: at most one task may write to it per step.
- This rejection is not configurable — there is no `allow_concurrent_writes` override for `LastValue` channels. (If multi-writer behavior is needed, the graph designer must use `Append` with a custom reducer.)

## Reference Evidence

**Source:** LangGraph Python reference (`pregel/algo.py`).
- LangGraph's channel update logic checks for duplicate writes to `LastValue` channels within
  a step and raises `InvalidUpdateError` (not a silent last-wins race).
- The error class `InvalidUpdateError` is defined in `langgraph.errors` and is used by the
  pregel step execution loop (`pregel/__init__.py`).
- DEC-005 in `edge-cases.md` captures this scenario: "Two nodes in the same super-step both
  write to the same LastValue channel → `InvalidUpdateError` raised; the Run transitions to
  `failed`."

## Edge Cases

### EC-001: Three tasks, two write to channel, one does not
**Scenario:** Super-step has tasks A, B, C. A and B write to `LastValue` channel `x`. C writes to a different channel `y`.
**Expected behavior:** Run fails with `E-GRAPH-001` citing tasks A and B for channel `x`. Channel `y` is unaffected. The error does not mention task C.

### EC-002: Same task writes twice (programming error in node fn)
**Scenario:** A node function writes to the same `LastValue` channel twice in one execution (e.g., two `Command` emissions for the same channel).
**Expected behavior:** This is treated as two writes from the same task — still raises `E-GRAPH-001` if the node is the only writer, because a single task writing a `LastValue` channel twice is itself an invariant violation (no idempotent re-send semantics).
**Note:** If only one unique write reaches the reducer, no error; if two distinct values are produced, error.

### EC-003: Concurrent writes to Append channel (not an error)
**Scenario:** Two tasks both write to an `Append` channel (which accumulates all writes).
**Expected behavior:** No error. `Append` channels are designed for multi-writer use. Both values are accumulated in the list.

### EC-004: Retry after InvalidUpdateError
**Scenario:** The application catches `E-GRAPH-001` and retries the run with the same graph and state.
**Expected behavior:** The retry will produce the same error if the graph definition causes concurrent writes. The graph must be fixed (by making one node conditional) before the run can succeed. `retry_hint: Never` communicates this.

### EC-005: DEC-005 from edge-cases.md
**Scenario:** Two nodes in the same super-step both write to the same `LastValue` channel. The run's event log must record both writes.
**Expected behavior:** `InvalidUpdateError` is raised. The run's event log (if checkpointing is enabled) contains both the write attempt from task A and task B, with the conflict annotated.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Graph: 2 nodes, both write `state.x = "value"` to same `LastValue` channel in same super-step | `Err(FerrochainError { code: E-GRAPH-001, category: CONCURRENCY, message: "InvalidUpdateError: concurrent writes to LastValue channel 'x' from tasks [node_a, node_b] in super-step 1" })` | Happy-path for error case |
| TV-002 | Graph: 2 nodes, node_a writes `state.x`, node_b writes `state.y` (different channels) | `Ok(GraphState { x: node_a_value, y: node_b_value })` | No conflict — different channels |
| TV-003 | Graph: 1 node writes `state.x` once | `Ok(GraphState { x: node_value })` | Single writer — no conflict |
| TV-004 | Graph: 2 nodes both append to `Append` channel | `Ok(GraphState { items: [node_a_item, node_b_item] })` | Append channels allow concurrent writes |
| TV-005 | E-GRAPH-001 error message format check | Message contains channel name, sorted task IDs, and super-step number | Error observability |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI001-01 | Concurrent LastValue writes always produce `E-GRAPH-001`, never a silent race | Property test (proptest with random task counts 2–10) | Phase 1 |
| VP-DI001-02 | Error message contains all writer task IDs (no partial omission) | Unit test with 3+ concurrent writers | Phase 1 |

## Related BCs

- BC-2.03.001 — BSP determinism (composes with: DI-001 dual obligation; this is the enforcement arm)
- BC-2.03.003 — Deterministic reducer order (composes with: defines what happens for non-conflicting writes)
- BC-2.02.002 — Channel semantics (depends on: defines LastValue vs Append channel types)

## Architecture Anchors

- `ferrochain-graph/src/pregel/reducer.rs` — concurrent write detection
- `ferrochain-core/src/errors.rs` — `E-GRAPH-001` definition

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-DI001-01, VP-DI001-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-004 |
| Capability Anchor Justification | CAP-004 ("BSP Graph Execution with Deterministic Reducer Order") per capabilities-p0.md §CAP-004 — "Concurrent writes to the same LastValue channel raise InvalidUpdateError rather than silently racing" is verbatim in the capability description |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism) |
| DEC References | DEC-005 |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), P (property) |
| Module | ferrochain-graph |
