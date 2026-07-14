---
document_type: behavioral-contract
level: L3
bc_id: BC-2.03.001
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-03
vp_seed: true
vp_id: VP-001
capability: CAP-004
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-004
  - domain-spec/invariants.md#DI-001
  - NE-17
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "19a5567c0bc106d5cf83270335021aea43256ce374f0df4652894fc0deda7e67"
---

# BC-2.03.001: BSP Super-Step Execution Determinism — Kani VP Seed (NE-17)

## Description

The ferrochain-graph Bulk-Synchronous Parallel (BSP) scheduler must produce identical
`GraphState` for identical inputs, regardless of the completion order of nodes within a
super-step. In each super-step all scheduled `PregelTask`s execute; then channel reducers
apply in deterministic task-identity-sorted order. The property must be formally verifiable
by a Kani harness (VP seed — the harness itself is a Phase-6 deliverable; this BC specifies
the behavioral invariant to be proved). NE-17 names adk-rust's `buffer_unordered` as the
counter-example that this contract explicitly rejects.

## Preconditions

1. A `StateGraph` is compiled with one or more nodes that write to shared channels.
2. A `Run` is started with an initial `GraphState` and a deterministic set of inputs.
3. The same graph and inputs are executed twice (or in two concurrent super-steps).
4. Node completion order may differ between the two executions (simulated by varying task
   scheduling delays or by the Kani non-determinism model).

## Postconditions

1. Both executions produce bit-identical `GraphState` after each super-step completes.
2. Channel reducer application order is determined by a deterministic sort of `(task_id, channel_name)` — not by task completion arrival order.
3. Identical `(graph_definition, initial_state, inputs)` always produces identical `final_state` regardless of OS scheduler, thread pool, or tokio runtime interleaving.
4. If any determinism violation is detected at runtime (reducer order constraint broken by a bug), the run transitions to `failed` with `E-GRAPH-006: BspDeterminismViolation`.

## Invariants

- **DI-001 (BSP Reducer Determinism):** Identical inputs always produce identical `GraphState` regardless of node completion order. Concurrent writes to a `LastValue` channel from the same super-step raise `InvalidUpdateError` (not silent race).
- The sort key for reducer application is `(task_id: &str, channel_name: &str)` — lexicographic ascending. No floating-point, random, or wall-clock component may enter the sort key.
- The BSP scheduler must NOT use `FuturesUnordered::buffer_unordered` or any unordered stream combinator to collect task outputs — it must collect all task results then sort before applying reducers.

## Reference Evidence

**Source:** LangGraph Python reference (`pregel/algo.py`, `pregel/__init__.py`).
- LangGraph's `PregelRunner` applies channel reducers after all tasks in a step complete;
  task outputs are collected into a list and sorted by `(task_id, channel_name)` before
  the reducer map is applied.
- adk-rust (CONFLICT-1) uses `futures::stream::FuturesUnordered::buffer_unordered` which
  produces task results in completion order — a non-deterministic ordering for reducers.
  This is the counter-example this contract rejects (NE-17).
- The determinism invariant is not explicitly unit-tested in langchain-core (it is tested
  in the LangGraph graph engine tests), but the behavioral contract is stated in the
  LangGraph design docs as a core invariant.

## Edge Cases

### EC-001: Two nodes complete in reversed order on second run
**Scenario:** Node A and Node B both write to `LastValue` channel `output`. On run 1, A completes before B (B wins, output = B's value). On run 2, B completes before A.
**Expected behavior:** Both runs produce `E-GRAPH-001 InvalidUpdateError` — concurrent writes to `LastValue` are rejected, not raced. If they write to different channels, the reducer application order is identical in both runs (sorted by task_id).
**Reference:** DI-001; BC-2.03.002.

### EC-002: Single-node graph — trivially deterministic
**Scenario:** A graph with one node writing to one channel; no concurrency.
**Expected behavior:** Output is identical across repeated runs. No sorting logic is exercised but the invariant still holds.

### EC-003: Large fan-out — 50 parallel tasks, all writing to Append channels
**Scenario:** A `Send` fan-out creates 50 parallel tasks; each appends one item to an `Append` channel.
**Expected behavior:** The final `Append` channel value is a list of 50 items in a deterministic order (sorted by task_id), not in completion-arrival order.

### EC-004: Kani non-determinism model
**Scenario:** Kani model checking assigns non-deterministic execution order to two tasks that write to different channels.
**Expected behavior:** For all non-deterministic interleavings modeled by Kani, the post-super-step `GraphState` is identical. The Kani harness asserts `state_after_run1 == state_after_run2` for all orderings.
**Phase:** This edge case becomes a formal Kani proof in Phase 6 (VP-BSP-DET-01).

### EC-005: Runtime determinism violation detection
**Scenario:** A bug in the scheduler (e.g., a hash map iteration that leaks non-determinism) causes a reducer to be applied out of order.
**Expected behavior:** The runtime guard (enabled in debug builds, optional in release) detects the ordering violation and returns `Err(FerrochainError { code: E-GRAPH-006, ... })`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Graph with 2 nodes writing to 2 separate Append channels; run 3 times with identical inputs | All 3 runs produce identical `GraphState` | Baseline determinism |
| TV-002 | Graph with 2 nodes, completion delays simulated as [A then B] and [B then A] | Both orderings produce identical `GraphState` after reducer application | Completion-order independence |
| TV-003 | Fan-out of 10 tasks, each appending to same `Append` channel | Append channel final value has items in sorted task_id order across all runs | Reducer sort order |
| TV-004 | Identical graph + inputs executed by two separate tokio runtimes with different thread counts | Both produce identical final `GraphState` | Thread-count independence |
| TV-005 | Kani harness: 2 tasks, 2 channels, non-det completion order | Kani verifies `state1 == state2` for all orderings (Phase 6 VP) | Formal verification seed |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BSP-DET-01 | For all non-deterministic task completion orders, post-super-step state is identical | Kani model checking | Phase 6 |
| VP-BSP-DET-02 | Reducer application order matches sorted `(task_id, channel_name)` — not arrival order | Property test (proptest) | Phase 1 |
| VP-BSP-DET-03 | No `FuturesUnordered::buffer_unordered` or equivalent in reducer collection path | Static analysis / CI grep | Wave 1 CI |

> **Kani VP Seed:** This BC is a Phase-6 Kani harness seed. The behavioral invariant
> (identical inputs → identical state) must be encoded as the postcondition of the Kani
> harness `verify_bsp_determinism`. The harness uses Kani's non-determinism (`kani::any()`)
> to model all possible task completion orderings. See BC-2.17.001 for harness scope.

## Related BCs

- BC-2.03.002 — Concurrent LastValue write rejection (composes with: DI-001 dual obligation)
- BC-2.03.003 — Deterministic reducer application order (composes with: specifies sort key)
- BC-2.17.001 — Kani harness scope (depends on: this BC is one of the 3 committed VP targets)

## Architecture Anchors

- `ferrochain-graph/src/pregel/scheduler.rs` (to be created)
- `ferrochain-graph/src/pregel/reducer.rs` (to be created)
- `tests/kani/bsp_determinism.rs` (Phase 6 artifact)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BSP-DET-01 (Phase 6), VP-BSP-DET-02, VP-BSP-DET-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-004 |
| Capability Anchor Justification | CAP-004 ("BSP Graph Execution with Deterministic Reducer Order") per capabilities-p0.md §CAP-004 — this BC directly specifies the deterministic reducer order property named in the capability title |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism) |
| NE References | NE-17 |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | P (property), K (Kani — Phase 6) |
| Module | [architect to assign — ferrochain-graph] |
