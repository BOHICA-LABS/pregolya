---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.005
version: "1.3"
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
  - "1.2 (F-P107-01, 2026-07-18): E-GRAPH-011 ConditionalEdgePanic struct corrected from single-field to two-field form. Was: { source: 'source_node' } (1 field — wrong field name, missing panic message). Now: { source_node: <edge source node name>, message: <captured panic text> } (2 fields, 1:1 with taxonomy placeholders '<source_node>' and '<message>'). Root cause: EC-003 prose 'preserving the panic message as the error source' was ambiguous — 'source' was used as the error source (i.e., a catch-all field), conflating node name and panic text. Fix: PC5 struct updated; EC-003 struct updated and ambiguous 'error source' prose clarified; TV-005 struct updated. Three-site sibling sweep within file (TD-VSDD-060) — all uses updated."
  - "1.3 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "ea59533"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.005: Conditional Edge Routing Function

## Description

A conditional edge is registered via `add_conditional_edges(source_node, path_fn,
path_map?)`. After `source_node` completes in a super-step, the graph calls `path_fn(state)`
to determine the next node(s) to schedule. The routing function returns a node name (string),
a list of node names, `Send` objects for dynamic fan-out, or the `END` sentinel. The optional
`path_map` translates symbolic return values to node names at compile time. This contract
covers the evaluation semantics, allowed return values, and error behavior of the conditional
edge routing function. Static edges and `Send` fan-out (BC-2.02.006) are distinct concerns.

## Preconditions

1. A `StateGraph` has been compiled with at least one `add_conditional_edges(source, path_fn)`
   call.
2. `source` node has completed its execution in a super-step, producing an output (or `None`).
3. The graph's channel state reflects all writes from `source` via `apply_writes` before
   `path_fn` is called (path function receives the merged post-step state).
4. `path_fn` is a pure function `fn(state: &GraphState) -> RouteResult` where
   `RouteResult` is one of: `NodeName(String)`, `NodeNames(Vec<String>)`, `End`,
   or `Send(...)` (the last delegated to BC-2.02.006).

## Postconditions

1. If `path_fn(state)` returns `NodeName("target")`, the graph schedules node `"target"`
   in the next super-step by triggering its subscribed channel.
2. If `path_fn(state)` returns `NodeNames(["a", "b"])`, both nodes `"a"` and `"b"` are
   scheduled in the next super-step.
3. If `path_fn(state)` returns `End`, no further nodes are scheduled; the graph run
   transitions to `completed` after flushing the current step.
4. If `path_map` is provided, symbolic return values from `path_fn` are translated via the
   map before scheduling; the raw string must appear as a key in the map.
5. If `path_fn` raises a Rust panic or returns an `Err`, the graph transitions to `failed`
   with `Err(E-GRAPH-011 ConditionalEdgePanic { source_node: "source_node", message: "<captured panic text>" })`,
   preserving both the edge source node name and the captured panic text in the error struct.

## Invariants

- `path_fn` is called exactly once per super-step for each edge where `source_node`
  completed; it is not called if `source_node` was not triggered in the current step.
- `path_fn` must be a pure function; it reads state but must not produce side effects
  (state writes from inside `path_fn` are not defined behavior).
- A routing decision that targets an unknown node name (not registered in the compiled
  graph) returns `Err(E-GRAPH-003 UnknownRoutingTarget)` and fails the run.
- Multiple `add_conditional_edges` calls from the same source node are allowed; each
  `path_fn` is evaluated; the union of their return values determines next-step scheduling.

## Edge Cases

### EC-001: path_fn returns END — graph terminates
**Scenario:** `path_fn` evaluates the state and returns `End` (e.g., a convergence
condition is met).
**Expected behavior:** No further nodes are scheduled; the run completes with the current
graph state as output; status transitions to `completed`.

### EC-002: path_fn returns unknown node name
**Scenario:** `path_fn` returns `NodeName("mystery")` but `"mystery"` was never registered
via `add_node`.
**Expected behavior:** `Err(E-GRAPH-003 UnknownRoutingTarget { node: "mystery" })` is
returned from the current `invoke`/`stream`; the run fails. The graph does not silently
drop the routing result.

### EC-003: path_fn panics (unwind)
**Scenario:** `path_fn` panics due to a programming error (index out of bounds, unwrap on
None, etc.).
**Expected behavior:** The panic is caught by the Pregel executor (via `std::panic::catch_unwind`
or equivalent); the run transitions to `failed` with
`Err(E-GRAPH-011 ConditionalEdgePanic { source_node: "source_node", message: "<captured panic text>" })`,
preserving both the edge source node name (for routing context) and the captured panic text
(the panic payload stringified) in the two-field error struct.

### EC-004: path_fn returns empty list
**Scenario:** `path_fn` returns `NodeNames([])` (empty routing result, not `End`).
**Expected behavior:** No nodes are scheduled from this edge; if no other edges trigger
any nodes, the graph halts naturally (run transitions to `completed`). Returning an empty list is semantically
equivalent to routing to END only for this edge's contribution.

### EC-005: path_map does not contain the returned symbolic key
**Scenario:** `path_fn` returns `"continue"` and a `path_map = { "stop": "END" }` is
provided, but `"continue"` is not in the map.
**Expected behavior:** `Err(E-GRAPH-012 UnmappedRouteKey { key: "continue" })` is returned
from the run; the graph fails. Missing path_map entries are not silently ignored.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `path_fn` returns `NodeName("next_node")`; `"next_node"` is registered | `"next_node"` is triggered in the next step | Happy path — single target |
| TV-002 | `path_fn` returns `End` | Run completes; status `completed` | END routing — graph terminates |
| TV-003 | `path_fn` returns `NodeNames(["branch_a", "branch_b"])` | Both nodes triggered in next step | Multi-target routing |
| TV-004 | `path_fn` returns `NodeName("ghost")` where `"ghost"` is not a registered node | `Err(E-GRAPH-003 UnknownRoutingTarget { node: "ghost" })` | Unknown target |
| TV-005 | `path_fn` panics with message `"index out of bounds: the len is 0 but the index is 0"` | `Err(E-GRAPH-011 ConditionalEdgePanic { source_node: "source_node", message: "index out of bounds: the len is 0 but the index is 0" })` | Panic catch — both source node and panic text captured |
| TV-006 | `path_fn` returns `NodeNames([])` | No nodes scheduled from this edge; graph may halt | Empty routing result |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-EDGE-01 | path_fn returning END halts the run; path_fn returning unknown node fails the run | Unit tests per TV-002 and TV-004 | Phase 1 |

## Related BCs

- BC-2.02.001 — depends on: nodes must be registered via add_node before they can be routing targets
- BC-2.02.006 — extends: Send routing is a specialization of conditional edge return values (Send objects)
- BC-2.03.001 — depends on: routing decision feeds into prepare_next_tasks in the BSP loop

## Architecture Anchors

- `ferrochain-graph/src/graph/state.rs` — `add_conditional_edges`, `path_map` compilation
- `ferrochain-graph/src/bsp_engine.rs` (`graph::bsp_engine`) — `prepare_next_tasks`, routing function evaluation
- `ferrochain-graph/src/types.rs` — `RouteResult` enum (NodeName, NodeNames, End, Send)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-EDGE-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — conditional edges with routing functions are explicitly named in CAP-003 as a component of the StateGraph definition surface ("typed edges including conditional edges") |
| L2 Domain Invariants | — |
| D17 Commitment | semport/graph/behavioral-intent.md §6.1 add_conditional_edges (path_fn, path_map) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit) |
| Module | ferrochain-graph |
