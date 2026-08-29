---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.005
version: "1.7"
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
timestamp: 2026-08-23T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-graph per module-decomposition.md v1.10."
  - "1.2 (F-P107-01, 2026-07-18): E-GRAPH-011 ConditionalEdgePanic struct corrected from single-field to two-field form. Was: { source: 'source_node' } (1 field — wrong field name, missing panic message). Now: { source_node: <edge source node name>, message: <captured panic text> } (2 fields, 1:1 with taxonomy placeholders '<source_node>' and '<message>'). Root cause: EC-003 prose 'preserving the panic message as the error source' was ambiguous — 'source' was used as the error source (i.e., a catch-all field), conflating node name and panic text. Fix: PC5 struct updated; EC-003 struct updated and ambiguous 'error source' prose clarified; TV-005 struct updated. Three-site sibling sweep within file (TD-VSDD-060) — all uses updated."
  - "1.3 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
  - "1.4 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.15 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (P2-bc-completeness-burst-B/SS-01..03/2026-08-26): Two gaps closed. (1) Gap MED — side-effecting path_fn declared 'not defined behavior' without a concrete outcome. Decision (production-grade default): side effects ARE executed (graph provides no sandbox); they are NOT covered by checkpoint/rollback boundaries. Rewrote {INV-002} to specify this explicitly. (2) Gap LOW — multi-edge union with conflicting End + NodeName was ambiguous (INV-004 said 'union determines scheduling' but PC-003 said 'End → no further nodes'; tension unresolved). Decision: End is added to the scheduling union as a terminus marker, but does NOT preempt live-node scheduling from other concurrent edges; live nodes run to completion before the terminus takes effect. Added {INV-005} and {EC-006} to specify this."
  - "1.7 (round-38/F-P2A163-01/2026-08-29): F-P2A163-01 [MED] — §Architecture Anchors: phantom `pregolya-graph/src/graph/state.rs` replaced with architect-confirmed canonical `pregolya-graph/src/definition.rs` (`graph::definition`). There is no `graph/` subdir in pregolya-graph; `add_conditional_edges` and `path_map` compilation live in `definition.rs`. SS-02 sibling sweep: BC-2.02.001 also had this phantom anchor (fixed in the same burst)."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "4119aa3"
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

1. {PRE-001} A `StateGraph` has been compiled with at least one `add_conditional_edges(source, path_fn)`
   call.
2. {PRE-002} `source` node has completed its execution in a super-step, producing an output (or `None`).
3. {PRE-003} The graph's channel state reflects all writes from `source` via `apply_writes` before
   `path_fn` is called (path function receives the merged post-step state).
4. {PRE-004} `path_fn` is a pure function `fn(state: &GraphState) -> RouteResult` where
   `RouteResult` is one of: `NodeName(String)`, `NodeNames(Vec<String>)`, `End`,
   or `Send(...)` (the last delegated to BC-2.02.006).

## Postconditions

1. {PC-001} If `path_fn(state)` returns `NodeName("target")`, the graph schedules node `"target"`
   in the next super-step by triggering its subscribed channel.
2. {PC-002} If `path_fn(state)` returns `NodeNames(["a", "b"])`, both nodes `"a"` and `"b"` are
   scheduled in the next super-step.
3. {PC-003} If `path_fn(state)` returns `End`, no further nodes are scheduled; the graph run
   transitions to `completed` after flushing the current step.
4. {PC-004} If `path_map` is provided, symbolic return values from `path_fn` are translated via the
   map before scheduling; the raw string must appear as a key in the map.
5. {PC-005} If `path_fn` raises a Rust panic or returns an `Err`, the graph transitions to `failed`
   with `Err(E-GRAPH-011 ConditionalEdgePanic { source_node: "source_node", message: "<captured panic text>" })`,
   preserving both the edge source node name and the captured panic text in the error struct.

## Invariants

- {INV-001} `path_fn` is called exactly once per super-step for each edge where `source_node`
  completed; it is not called if `source_node` was not triggered in the current step.
- {INV-002} `path_fn` is required to be a pure function that reads state without side effects.
  **Side-effect execution semantics (production-grade decision):** The graph does NOT sandbox
  `path_fn`. If `path_fn` performs I/O or mutates external state, those operations ARE executed —
  they are not dropped, blocked, or deferred. However, they are NOT covered by the graph's
  checkpoint/rollback boundary: if a run is retried from a checkpoint, any external writes
  from `path_fn` are not rolled back. Callers who require transactional side effects must place
  them inside node functions (where checkpoint coverage applies), not in routing functions.
- {INV-003} A routing decision that targets an unknown node name (not registered in the compiled
  graph) returns `Err(E-GRAPH-003 UnknownRoutingTarget)` and fails the run.
- {INV-004} Multiple `add_conditional_edges` calls from the same source node are allowed; each
  `path_fn` is evaluated; the union of their return values determines next-step scheduling.
  See INV-005 for how `End` from one path_fn interacts with live node targets from another.
- {INV-005} **Multi-edge End-vs-NodeName resolution:** When multiple conditional edges fire from
  the same source and their results form a union that includes both `End` and one or more live
  node names (e.g., path_fn-A returns `End`, path_fn-B returns `NodeName("next")`):
  `End` is added to the scheduling set as a terminus marker but does NOT preempt the live-node
  targets. The live nodes (`"next"` in the example) are scheduled and execute in the next
  super-step. The graph terminates naturally once all paths in the scheduling set have been
  exhausted — which includes reaching `END` via the terminus marker. `End`-only returns
  (no concurrent live targets) halt immediately per PC-003.

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

### EC-006: Multi-edge union — one path_fn returns End, another returns NodeName
**Scenario:** Two `add_conditional_edges` calls are registered for the same source node
`"router"`. In a given super-step, path_fn-A returns `End` and path_fn-B returns
`NodeName("cleanup")`.
**Expected behavior:** The scheduling union is `{ End, "cleanup" }`. `"cleanup"` is scheduled
and executes in the next super-step. `End` is a terminus marker in the union but does NOT
prevent `"cleanup"` from running. After `"cleanup"` completes (and assuming no further
outgoing edges lead elsewhere), the graph terminates with status `completed`.
The caller does NOT see an immediate halt after the `"router"` step.
**Reference:** INV-005 for the resolution rule.

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

- `pregolya-graph/src/definition.rs` (`graph::definition`) — `add_conditional_edges`, `path_map` compilation
- `pregolya-graph/src/bsp_engine.rs` (`graph::bsp_engine`) — `prepare_next_tasks`, routing function evaluation
- `pregolya-graph/src/types.rs` — `RouteResult` enum (NodeName, NodeNames, End, Send)

## Story Anchor

S-1.15

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
| Module | pregolya-graph |
