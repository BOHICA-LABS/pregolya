---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.011
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-003
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.0 (2026-07-13): initial authoring — Greenfield batch 13"
  - "1.1 (2026-07-14): Architecture Anchor pregolya-core/src/graph/builder.rs corrected to pregolya-graph/src/graph/state.rs — StateGraph builder is owned by pregolya-graph per ADR-007 / module-decomposition.md / BC-2.02.001 (F-P42-01, ADV-P1D-PASS-42)"
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
  - architecture/decisions/ADR-008-proc-macro-attributes.md
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-008-proc-macro-attributes.md
input-hash: "7175152"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.011: `#[entrypoint]` Attribute Macro — START Edge Auto-Wiring for StateGraph

## Description

The `#[pregolya::entrypoint]` proc-macro attribute marks a StateGraph node function as
the start node, automatically generating the `StateGraph::add_edge(START, "<node_name>")`
wiring when the graph is compiled from its builder. This is ergonomic sugar: a graph without
`#[entrypoint]` is fully valid (the user calls `add_edge(START, ...)` manually). With
`#[entrypoint]`, the graph builder detects the annotation at build time and inserts the
START edge without user boilerplate. At most one `#[entrypoint]` may appear per graph
definition; applying it to two nodes in the same graph is a compile-time error.

## Preconditions

1. The annotated function is a StateGraph node function with signature
   `async fn node_name(state: S) -> Result<Update<S>, PregolyaError>` (or equivalent
   per the node function contract in CAP-004/BC-2.02.001).
2. The `StateGraph` builder being constructed is the same graph scope where the annotation
   applies. The entrypoint annotation is scoped to the graph builder invocation.
3. `pregolya-macros` is available (re-exported from `pregolya-core`).

## Postconditions

1. When the `StateGraph::build()` call compiles the graph, `add_edge(START, "<node_name>")`
   is automatically inserted — exactly equivalent to the user writing it manually.
2. No duplicate START edge is inserted: if the user also calls `add_edge(START, ...)` manually,
   a compile-time or build-time error (`GraphBuildError::DuplicateStartEdge`) is returned.
3. The annotated node remains a fully valid node in all other respects — it may still have
   incoming edges from other nodes.
4. Removing the `#[entrypoint]` attribute and manually adding the START edge produces
   semantically identical runtime behavior.

## Invariants

- The `#[entrypoint]` attribute is purely additive ergonomics — it generates no logic that
  could not be written by hand. Any graph built with `#[entrypoint]` is equivalent to a
  graph built without it plus a manual `add_edge(START, node_name)` call.
- At most one `#[entrypoint]` per `StateGraph` builder scope is valid. This is the
  primary invariant; violation is a hard compile error.

## Edge Cases

### EC-001: Two nodes in the same graph annotated with `#[entrypoint]`
**Scenario:** `#[pregolya::entrypoint] async fn node_a(...)` and
`#[pregolya::entrypoint] async fn node_b(...)` both added to the same graph builder.
**Expected behavior:** Compile-time error: `#[entrypoint] may only be applied to one node
per StateGraph builder`. The error must identify both annotated functions.

### EC-002: `#[entrypoint]` on a function not registered as a node
**Scenario:** The annotated function is never passed to `graph.add_node(node_a)`.
**Expected behavior:** Build-time error (from `StateGraph::build()`): the START edge
references an unregistered node. Error message: `GraphBuildError::UnknownNode("node_a")`.

### EC-003: Graph has both `#[entrypoint]` annotation and explicit `add_edge(START, ...)`
**Scenario:** User annotates `node_a` with `#[entrypoint]` AND calls
`graph.add_edge(START, "node_a")` manually.
**Expected behavior:** `GraphBuildError::DuplicateStartEdge` returned from `build()`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `#[pregolya::entrypoint] async fn my_node(...)` + single `build()` | Graph builds successfully; START → my_node edge present | Happy path |
| TV-002 | Two functions in same builder both annotated `#[entrypoint]` | Compile-time error identifying both functions | Exclusive constraint |
| TV-003 | `#[entrypoint]` node + manual `add_edge(START, ...)` on same node | `GraphBuildError::DuplicateStartEdge` at `build()` | Idempotency guard |
| TV-004 | Annotated function not registered as a node | `GraphBuildError::UnknownNode` at `build()` | Node existence check |
| TV-005 | Graph without `#[entrypoint]` using manual `add_edge(START, ...)` | Compiles and behaves identically to TV-001 | Equivalence |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208011-01 | Graph built with `#[entrypoint]` is semantically equivalent to graph with manual `add_edge(START, ...)` | Equivalence test: both graphs produce identical execution traces for the same input | Phase 3 |

## Related BCs

- BC-2.08.010 — sibling: `#[tool]` macro (same proc-macro crate)
- BC-2.08.012 — sibling: `#[task]` macro (same proc-macro crate)
- BC-2.02.001 — depends on: StateGraph node definition contract
- BC-2.03.001 — depends on: BSP execution of graph built via this macro

## Architecture Anchors

- `pregolya-macros/src/entrypoint.rs` — `#[entrypoint]` proc-macro implementation
- `pregolya-graph/src/graph/state.rs` — StateGraph builder START edge wiring (add_edge API the macro calls)
- `architecture/decisions/ADR-008-proc-macro-attributes.md` — proc-macro design rationale

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208011-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — the `#[entrypoint]` macro generates the START edge wiring that is a core part of StateGraph definition; it is ergonomic sugar over the `add_edge(START, ...)` call that CAP-003 defines as the graph construction primitive |
| L2 Domain Invariants | — (no DI directly anchored; the macro generates correct graph structure per CAP-003 constraints) |
| DEC Reference | — |
| Risk Source | ADR-008 acceptance (D5 gate resolved via ADR-004); proc-macro design |
| D17 Commitment | D17-Q6 — proc-macro BCs gated on D5 ADR; ADR-004 accepted unblocks this BC |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit) |
| Module | pregolya-macros (re-exported pregolya-core) |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.1 | 2026-07-14 | Architecture Anchor `pregolya-core/src/graph/builder.rs` corrected to `pregolya-graph/src/graph/state.rs` — StateGraph builder is owned by pregolya-graph per ADR-007 / module-decomposition.md / BC-2.02.001 (F-P42-01, ADV-P1D-PASS-42) | F-P42-01 |
| 1.0 | 2026-07-13 | Initial authoring | Greenfield batch 13 |
