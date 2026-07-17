---
document_type: behavioral-contract
level: L3
bc_id: BC-2.03.001
version: "1.4"
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
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.4 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph per module-decomposition.md v1.10."
  - "1.1 (ADV-P1D-PASS-49): F-P49-02 — port graph super-step ceiling. Added PC5 (super-step ceiling halt via E-GRAPH-017), PC6 (per-invocation-segment semantics for interrupted/resumed runs), EC-006 (ceiling exceeded edge case), TV-006 (cyclic graph test vector). Reference Evidence section updated with upstream LangGraph evidence. This is the primary enforcing BC for E-GRAPH-017."
  - "1.2 (ADV-P1D-PASS-50): F-P50-01 — fix arithmetic in EC-006 Scenario (false claim 6 > 6 corrected to 7 > stop = 6; unified to 1-indexed super-step labels per TV-006 convention, resolving OBS-P50-1 mixed-indexing observation). Correct PC6 resume bound from N × recursion_limit to N × (recursion_limit + 1) — each invocation segment allows recursion_limit + 1 super-steps before halt (TV-006 arithmetic: recursion_limit=3 → 4 steps execute; recursion_limit=5 → 6 steps execute)."
  - "1.3 (ADV-P1D-PASS-56): OBS-P56-1 resolved — tighten 10007 claim in Reference Evidence. The `DEFAULT_RECURSION_LIMIT` constant in `langgraph._internal._config` (verified against `.reference/langgraph` pinned source) reads from the `LANGGRAPH_DEFAULT_RECURSION_LIMIT` environment variable with a hardcoded default of 10007. This is a code constant, not itself an env var. Distinct from langchain-core's `DEFAULT_RECURSION_LIMIT = 25` in `langchain_core.runnables.config` (Runnable-layer). The 10007 claim was always accurate; this edit adds the precise constant name and source module."
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
input-hash: "f05069f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
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

This BC also specifies the **graph-engine super-step ceiling**: the BSP loop must halt with
`E-GRAPH-017 GraphRecursionLimitExceeded` when the super-step count for the current
invocation segment exceeds `config.recursion_limit` (default 25, from `RunnableConfig` —
the same key that BC-2.01.003 uses for the Runnable-layer nested-call-depth guard). This is
ferrochain's port of LangGraph's primary infinite-loop guard (`GraphRecursionError`,
`graph/behavioral-intent.md §1.3`: `stop = step + recursion_limit + 1`).

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
5. **Super-step ceiling:** The BSP loop tracks a super-step counter per invocation segment. Before dispatching the next super-step, the engine checks whether the current step count would exceed `step_at_invoke_start + config.recursion_limit + 1`. If exceeded, the run transitions to `failed` with `Err(FerrochainError { category: POLICY, code: E-GRAPH-017, message: "GraphRecursionLimitExceeded: ..." })`. `config.recursion_limit` defaults to 25 (from `RunnableConfig` — same key as BC-2.01.003; graph-engine interpretation = super-step ceiling). Upstream parity: LangGraph computes `stop = step + recursion_limit + 1` in `PregelLoop.__init__` / `PregelLoop.astart`, sets status `out_of_steps` in `tick()`, and raises `GraphRecursionError` in the outer invoke loop (`graph/behavioral-intent.md §1.3`).
6. **Resume semantics for interrupted runs:** Upon resume from an interrupt checkpoint, `step_at_invoke_start` is set to the step index of the resume point (the checkpoint's current `step`). Each invocation segment (fresh invoke or resume) independently receives `recursion_limit` additional super-steps from its start point. A run that is interrupted and resumed N times can execute at most N × (`recursion_limit` + 1) total post-resume super-steps without triggering E-GRAPH-017 per segment (each segment executes up to `recursion_limit` + 1 super-steps before the ceiling triggers; TV-006 arithmetic: limit=3 → 4 steps execute before halt at step 5; limit=5 → 6 steps execute before halt at step 7). The count does NOT reset to zero on resume — it continues from the checkpoint step and the ceiling window shifts accordingly. Adjudicated rule: ceiling is per-invocation-segment (upstream parity: LangGraph recomputes `stop` at each `invoke`/`ainvoke` entry point).

## Invariants

- **DI-001 (BSP Reducer Determinism):** Identical inputs always produce identical `GraphState` regardless of node completion order. Concurrent writes to a `LastValue` channel from the same super-step raise `InvalidUpdateError` (not silent race).
- The sort key for reducer application is `(task_id: &str, channel_name: &str)` — lexicographic ascending. No floating-point, random, or wall-clock component may enter the sort key.
- The BSP scheduler must NOT use `FuturesUnordered::buffer_unordered` or any unordered stream combinator to collect task outputs — it must collect all task results then sort before applying reducers.

## Reference Evidence

**Source:** LangGraph Python reference (`pregel/algo.py`, `pregel/__init__.py`, `pregel/_loop.py`, `pregel/main.py`).
- LangGraph's `PregelRunner` applies channel reducers after all tasks in a step complete;
  task outputs are collected into a list and sorted by `(task_id, channel_name)` before
  the reducer map is applied.
- adk-rust (CONFLICT-1) uses `futures::stream::FuturesUnordered::buffer_unordered` which
  produces task results in completion order — a non-deterministic ordering for reducers.
  This is the counter-example this contract rejects (NE-17).
- The determinism invariant is not explicitly unit-tested in langchain-core (it is tested
  in the LangGraph graph engine tests), but the behavioral contract is stated in the
  LangGraph design docs as a core invariant.

**Super-step ceiling evidence** (F-P49-02, `semport/graph/behavioral-intent.md §1.3`):
- LangGraph's `PregelLoop` tracks `step`/`stop` where `stop = step + recursion_limit + 1`.
  The `tick()` method sets `loop.status = "out_of_steps"` when `step > stop`; the outer
  invoke loop in `main.py` then raises `GraphRecursionError` after checking loop status.
  This is the PRIMARY infinite-loop guard for cyclic graphs.
- `recursion_limit` is drawn from `RunnableConfig` (langchain-core's key; default 25 in
  ferrochain). LangGraph upstream uses 10007 as its graph-layer default: the
  `DEFAULT_RECURSION_LIMIT` constant in the `langgraph._internal._config` module reads from
  the `LANGGRAPH_DEFAULT_RECURSION_LIMIT` environment variable with a hardcoded default of
  10007 (verified: `.reference/langgraph/langgraph/_internal/_config.py` symbol
  `DEFAULT_RECURSION_LIMIT`). This is distinct from langchain-core's
  `DEFAULT_RECURSION_LIMIT = 25` in `langchain_core.runnables.config` (the Runnable-layer
  default). Ferrochain aligns BOTH layers (Runnable-depth and graph-super-step) at 25 per
  `RunnableConfig` convention.
- ferrochain error code: E-GRAPH-017 `GraphRecursionLimitExceeded` (error-taxonomy.md §GRAPH).

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

### EC-006: Super-step ceiling exceeded — cyclic graph without termination
**Scenario:** A conditional-edge graph (e.g., a model→tools→model loop) has no termination condition and `config.recursion_limit = 5`. The graph loops: super-step 1 completes (step = 1 ≤ stop = 6) → super-step 2 completes (step = 2 ≤ stop = 6) → ... → super-step 6 completes (step = 6 ≤ stop = 6; ceiling not yet exceeded); before dispatching super-step 7, step would become 7 > stop = 0 + 5 + 1 = 6 → halt.
**Expected behavior:** Before dispatching super-step 7, the engine detects `current_step > step_at_invoke_start + recursion_limit + 1` and transitions the run to `failed` with `Err(FerrochainError { category: POLICY, code: E-GRAPH-017 })`. The run does not hang indefinitely. The run's `error` field is populated with the RFC-7807 representation of E-GRAPH-017.
**Reference:** E-GRAPH-017; upstream LangGraph `GraphRecursionError` (`graph/behavioral-intent.md §1.3`). Also see BC-2.02.005 (conditional edges), BC-2.08.002 PC/invariant (agent loop step limit).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Graph with 2 nodes writing to 2 separate Append channels; run 3 times with identical inputs | All 3 runs produce identical `GraphState` | Baseline determinism |
| TV-002 | Graph with 2 nodes, completion delays simulated as [A then B] and [B then A] | Both orderings produce identical `GraphState` after reducer application | Completion-order independence |
| TV-003 | Fan-out of 10 tasks, each appending to same `Append` channel | Append channel final value has items in sorted task_id order across all runs | Reducer sort order |
| TV-004 | Identical graph + inputs executed by two separate tokio runtimes with different thread counts | Both produce identical final `GraphState` | Thread-count independence |
| TV-005 | Kani harness: 2 tasks, 2 channels, non-det completion order | Kani verifies `state1 == state2` for all orderings (Phase 6 VP) | Formal verification seed |
| TV-006 | Cyclic graph (A→B→A→...) with no termination condition; `config.recursion_limit = 3`; fresh invocation (`step_at_invoke_start = 0`) | Run fails with `Err(FerrochainError { category: POLICY, code: E-GRAPH-017 })` before dispatching super-step 5 (`stop = 0 + 3 + 1 = 4`; halt when `step > 4`) | Super-step ceiling (EC-006) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BSP-DET-01 | For all non-deterministic task completion orders, post-super-step state is identical | Kani model checking | Phase 6 |
| VP-BSP-DET-02 | Reducer application order matches sorted `(task_id, channel_name)` — not arrival order | Property test (proptest) | Phase 1 |
| VP-BSP-DET-03 | No `FuturesUnordered::buffer_unordered` or equivalent in reducer collection path | Static analysis / CI grep | Wave 1 CI |

> **Kani VP Seed:** This BC is a Phase-6 Kani harness seed. The behavioral invariant
> (identical inputs → identical state) must be encoded as the postcondition of the Kani
> harness `bsp_determinism_harness`. The harness uses Kani's non-determinism (`kani::any()`)
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
| Module | ferrochain-graph |
