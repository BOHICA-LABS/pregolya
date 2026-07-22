---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.002
version: "1.2"
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
  - "1.2 (F-P107-01 census, 2026-07-18): E-GRAPH-001 struct expanded to include task_ids and step fields missing from prior struct form. Was: { channel } (EC-001) or { channel, reason } (PC3/EC-002) — both lacking taxonomy placeholders '<task_ids>' and '<n>' (super-step). Now: { channel, task_ids, step } (3 fields, 1:1 with taxonomy '<channel>', '<task_ids>', '<n>'). The 'reason' field was static text (not a taxonomy placeholder); replaced by the two structurally required dynamic fields. PC3, EC-001, EC-002, TV-002 updated. Same-class defect as E-GRAPH-011 discovered during message↔struct census rerun."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
  - domain-spec/invariants.md#DI-001
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "b51f89c"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.002: LastValue / Append / BarrierValue Channel Semantics and Reducer Wiring

## Description

The three primary channel types — `LastValue`, `Append` (backed by
`BinaryOperatorAggregate` with a fold reducer), and `BarrierValue` — each enforce distinct
write-cardinality and availability semantics within a super-step. `LastValue` allows
exactly one write per step; `Append` folds multiple writes in deterministic sorted order;
`BarrierValue` (unnamed variant) becomes available only once all expected writers have
contributed in a step. Reducer application order is deterministic (task-identity-sorted)
per DI-001, making identical inputs produce identical state regardless of concurrent node
completion order.

## Preconditions

1. A `StateGraph` is compiled with at least one channel of each type under test.
2. The graph has a `CheckpointSaver` configured or is running in-memory.
3. A super-step is in progress with one or more `PregelTask`s active.
4. Multiple tasks may attempt writes to the same channel within the same super-step.

## Postconditions

### LastValue
1. A channel of type `LastValue<T>` that receives exactly one write `v` in a super-step
   stores `v` and makes it available to the next step.
2. A `LastValue` channel that receives zero writes in a super-step is unchanged
   (`update([])` is a no-op).
3. A `LastValue` channel that receives two or more writes from different tasks in the same
   super-step raises `Err(E-GRAPH-001 InvalidUpdateError { channel: name,
   task_ids: [<id_1>, <id_2>, ...], step: <n> })`; the run transitions to
   `failed`.

### Append (BinaryOperatorAggregate)
4. A channel of type `BinaryOperatorAggregate<T, op>` (e.g. `Append<T>` backed by
   `operator.add`) folds all writes in the super-step using `op` applied in
   task-identity-sorted order: `value = op(op(…op(seed, w_0), w_1), …, w_n)`.
5. An `Overwrite(v)` written to an Append channel replaces the accumulated value entirely
   (`value = v`) rather than folding; at most one `Overwrite` per step is allowed; two
   `Overwrite`s in the same step raise `Err(E-GRAPH-001 InvalidUpdateError)`.
6. The reduction order is the same regardless of which node finished first; concurrent node
   completion order does not affect the final channel value.

### BarrierValue
7. A `BarrierValue` channel (unnamed variant) becomes `available()` in a step only after
   all registered upstream writers have each submitted exactly one write; it is not
   available for downstream nodes until the full writer set has delivered.
8. A downstream node subscribed to a `BarrierValue` channel is not triggered until the
   channel becomes available; it remains pending until that step's writers all complete.

## Invariants

- **DI-001 (BSP Reducer Determinism):** Reducer application order within any super-step is
  the deterministic task-identity sort (`task_path[:3]`). Identical graph inputs produce
  identical channel states regardless of concurrent task completion order.
- No channel update is observable to any other task within the same super-step (BSP write
  isolation); all merging happens in `apply_writes` after all tasks complete.
- A `LastValue` channel that receives concurrent writes raises `InvalidUpdateError`; this is
  a hard error, not a last-one-wins race condition.

## Edge Cases

### EC-001: Concurrent LastValue writes from two tasks in same super-step
**Scenario:** Node A and Node B both return `{ "result": value }` targeting the same
`LastValue` channel `"result"` in the same super-step.
**Expected behavior:** `Err(E-GRAPH-001 InvalidUpdateError { channel: "result", task_ids: ["node_a", "node_b"], step: 1 })` is
returned from `invoke`/`stream`; the run transitions to `failed`. No value is written to
the channel.
**Reference:** DEC-005 (Concurrent LastValue Writes in Same Super-Step).

### EC-002: Append channel with Overwrite — two Overwrites in same step
**Scenario:** Two tasks both return `Overwrite(v)` for the same `Append` channel in the
same super-step.
**Expected behavior:** `Err(E-GRAPH-001 InvalidUpdateError { channel: name, task_ids: [<id_1>, <id_2>], step: <n> })` is raised at `apply_writes`; the run fails.

### EC-003: BarrierValue channel — one writer has not delivered by step end
**Scenario:** A `BarrierValue` channel expects writes from two upstream nodes. Only one
delivers before the step closes (the other has no outgoing channel update).
**Expected behavior:** The channel is not available; the downstream node is not triggered;
execution halts at that step boundary. If no other nodes are triggered the graph halts
naturally (run transitions to `completed`) without ever activating the downstream node.
**Note:** See BC-2.02.003 for `NamedBarrierValue` missing-writer boundary semantics.

### EC-004: Append fold order with three concurrent writers
**Scenario:** Tasks P (path sort key "p"), Q (key "q"), R (key "r") all write integers
`[3, 1, 2]` respectively to an `Append<Vec<i64>>` channel in the same step.
**Expected behavior:** The fold order is P then Q then R (alphabetical by task-identity
sort): the resulting list is `[3, 1, 2]` (in task-identity-sorted write order, which may
differ from task completion order at runtime).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Node returns `{ "value": 42 }` to `LastValue<i64>` channel; no other writer | Channel stores `42` after step | Happy path — single write |
| TV-002 | Nodes `"node_a"` and `"node_b"` both return `{ "value": X }` to same `LastValue<i64>` channel in super-step 1 | `Err(E-GRAPH-001 InvalidUpdateError { channel: "value", task_ids: ["node_a", "node_b"], step: 1 })` | Concurrent LastValue writes — both conflicting task IDs and step captured |
| TV-003 | Three nodes return `[3, 1, 2]` (in task-identity-sort order P, Q, R) to `Append<Vec<i64>>` channel | Channel value is `[3, 1, 2]` (sorted write order) | Deterministic fold order — DI-001 |
| TV-004 | Node returns `Overwrite([99])` to `Append<Vec<i64>>` channel | Channel value is `[99]` (bypass fold) | Overwrite replaces accumulated value |
| TV-005 | `LastValue` channel receives zero writes in a step | Channel unchanged (no-op) | update([]) → no-op |
| TV-006 | `BarrierValue` channel with two expected writers; only one writes | Downstream node not triggered; step completes without activating it | Barrier not yet available |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-CHAN-01 | Append fold order is deterministic regardless of concurrent task completion sequence | Property test: shuffle completion order, assert final channel value identical | Phase 1 |

## Related BCs

- BC-2.02.001 — depends on: channel types are inferred from the state schema registered there
- BC-2.02.003 — extends: NamedBarrierValue (named variant) semantics and missing-writer edge case
- BC-2.02.004 — sibling: EphemeralValue (cleared-after-step) completes the channel type inventory
- BC-2.03.001 — depends on: BSP reducer determinism (DI-001) is the execution invariant that makes this reproducible
- BC-2.03.002 — composes with: concurrent LastValue rejection is the same error class as DI-001 concurrent write rejection

## Architecture Anchors

- `ferrochain-graph/src/channels/last_value.rs` — `LastValue<T>` channel
- `ferrochain-graph/src/channels/binary_operator.rs` — `BinaryOperatorAggregate<T, Op>`, `Overwrite<T>`
- `ferrochain-graph/src/channels/barrier.rs` — `BarrierValue`
- `ferrochain-graph/src/pregel/algo.rs` — `apply_writes` deterministic sort

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-CHAN-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — this BC specifies the reducer semantics for the three primary channel types (LastValue, Append/BinaryOperatorAggregate, BarrierValue) that are explicitly enumerated in CAP-003's definition |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism) |
| D17 Commitment | semport/graph/behavioral-intent.md §1.4 channel type semantics (HIGH confidence, read from source) |
| DEC Reference | DEC-005 (Concurrent LastValue Writes) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), P (property) |
| Module | ferrochain-graph |
