---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.001
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
input-hash: "7e85a5e"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.001: StateGraph Node Definition with Typed Channel Assignment

## Description

A `StateGraph` is constructed by declaring a typed state schema, adding named nodes
(Runnables or plain functions), wiring static and conditional edges, and then calling
`compile()` to produce an executable `CompiledStateGraph`. The state schema drives
channel allocation: every schema key becomes a channel of the inferred type, and each
node's output dictionary keys must match a subset of those channels. This contract covers
the builder API surface — `add_node`, `add_edge`, `compile` — and the schema-to-channel
inference step that makes those keys typed and reducer-governed.

## Preconditions

1. The caller constructs `StateGraph(state_schema)` where `state_schema` is a Rust struct
   (or equivalent typed map) whose fields declare channel types: bare fields infer
   `LastValue`; fields annotated with a reducer infer `BinaryOperatorAggregate`; fields
   annotated with a `BaseChannel` subtype use that channel directly.
2. At least one node is registered via `add_node(name, fn)` where `fn` has signature
   `(state) -> state_update_dict | Command | None`; or `(state, config) -> ...`.
3. At least one edge exists connecting `START` → a node and at least one node → `END`
   (directly or via conditional edges); the graph is reachable from `START`.
4. `compile()` is invoked; an optional `CheckpointSaver` may be attached.

## Postconditions

1. `compile()` validates the graph topology and returns `Ok(CompiledStateGraph)` (a
   `Pregel`).
2. For each key in the state schema a channel is allocated and registered in the compiled
   graph's channel map before any execution begins.
3. Plain schema fields are wired to `LastValue` channels; `Annotated<T, reducer>` fields
   are wired to `BinaryOperatorAggregate(T, reducer)` channels; explicit `BaseChannel`
   annotations bind to those channel types directly.
4. The compiled graph's input projection accepts an initial state dict; keys not in the
   schema are silently ignored (not an error).
5. Calling `compiled_graph.invoke(input, config)` with a valid initial state dict starts
   a Pregel super-step loop; the call returns `Ok(output_state)` when the graph reaches
   `END` naturally.
6. Node functions that return `None` (no output) do not mutate any channels for that task
   in that super-step.

## Invariants

- Every key in a node's output dictionary must correspond to a registered channel; writing
  to an unregistered key is an error (not silently ignored).
- Node names must be unique within a graph; registering a duplicate name at `add_node`
  returns `Err(DuplicateNodeName)`.
- `START` and `END` are reserved sentinels and cannot be used as node names.
- The graph must have at least one path from `START` to `END`; `compile()` validates
  reachability and returns `Err(UnreachableGraph)` if none exists.

## Edge Cases

### EC-001: Node writes to an unregistered channel key
**Scenario:** A node function returns `{ "unknown_key": value }` where `unknown_key` is
not in the state schema.
**Expected behavior:** `Err(E-GRAPH-007 UnknownChannelKey { key: "unknown_key" })` is
returned from `invoke`/`stream` at the `apply_writes` stage; the run transitions to
`failed`. The error is not silently ignored.

### EC-002: compile() called with no entry edge from START
**Scenario:** Nodes and edges among nodes are added, but no edge from `START` to any node
is added before `compile()` is called.
**Expected behavior:** `compile()` returns `Err(E-GRAPH-008 UnreachableGraph { reason:
"no entry edge from START" })`. No compiled graph is produced.

### EC-003: Duplicate node name registration
**Scenario:** `add_node("agent", fn_a)` is called, then `add_node("agent", fn_b)` on
the same builder.
**Expected behavior:** The second `add_node` returns `Err(E-GRAPH-009 DuplicateNodeName
{ name: "agent" })`; the builder state is unchanged; `fn_a` remains registered.

### EC-004: Node function returns Command with goto targeting unknown node
**Scenario:** A node function returns `Command { goto: "nonexistent_node" }` at runtime.
**Expected behavior:** The graph returns `Err(E-GRAPH-003 UnknownRoutingTarget { node:
"nonexistent_node" })` when the `Command` is processed after `apply_writes`; the run
transitions to `failed`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `StateGraph` with schema `{ messages: Append<AiMessage> }`, one node `"agent"` that returns `{ "messages": [AiMessage("hello")] }`, edge `START → agent → END`; `compile()` called | `Ok(CompiledStateGraph)`; `invoke({"messages": []})` returns `{"messages": [AiMessage("hello")]}` | Happy path — schema inference, single node, linear graph |
| TV-002 | Same graph; node returns `None` | `invoke({"messages": []})` returns `{"messages": []}` (no mutation) | Node returns None — no channel mutation |
| TV-003 | Builder with no `START` edge; `compile()` | `Err(E-GRAPH-008 UnreachableGraph)` | No entry edge — compile-time validation |
| TV-004 | `add_node("agent", fn)` called twice on same builder | Second call returns `Err(E-GRAPH-009 DuplicateNodeName)` | Duplicate node name |
| TV-005 | Node returns `{ "bad_key": 1 }` on invoke | `Err(E-GRAPH-007 UnknownChannelKey { key: "bad_key" })` from invoke | Unregistered channel key at runtime |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-GRAPH-01 | compile() produces CompiledStateGraph with channels matching schema keys | Unit test (schema → channel map inspection) | Phase 1 |

## Related BCs

- BC-2.02.002 — depends on: channel types inferred by this BC are governed by that BC's semantics
- BC-2.02.005 — composes with: conditional edges extend the static edges registered here
- BC-2.02.006 — composes with: Send fan-out is wired via conditional edges registered here
- BC-2.03.001 — depends on: BSP execution runs on the compiled graph produced here

## Architecture Anchors

- `ferrochain-graph/src/graph/state.rs` — `StateGraph` builder (add_node, add_edge, compile)
- `ferrochain-graph/src/types.rs` — `CompiledStateGraph`, `Command`, `PregelTask`
- `ferrochain-graph/src/channels/` — `LastValue`, `BinaryOperatorAggregate`, `BaseChannel` trait

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-GRAPH-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — this BC specifies the builder API contract (add_node, channel inference, compile) that is the core entry-point of the StateGraph definition capability named in CAP-003 |
| L2 Domain Invariants | — |
| D17 Commitment | D17 §6.1 StateGraph API surface (semport/graph/behavioral-intent.md §6.1) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-graph |
