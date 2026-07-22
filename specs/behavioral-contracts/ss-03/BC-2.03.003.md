---
document_type: behavioral-contract
level: L3
bc_id: BC-2.03.003
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
  - NE-17
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

# BC-2.03.003: Deterministic Reducer Application Order (Task-Identity Sort)

## Description

After all `PregelTask`s in a super-step have completed, the channel reducer map is applied
in a deterministic order determined by sorting the collected write records by
`(task_id: &str, channel_name: &str)` in lexicographic ascending order. This guarantees
that the same task outputs always produce the same post-step `GraphState`, regardless of
which order the tasks happened to complete on the OS scheduler. No hash map iteration order,
completion timestamp, thread-pool index, or other non-deterministic quantity may influence
reducer application order.

## Preconditions

1. At least one `PregelTask` in the current super-step has produced a channel write.
2. All tasks in the super-step have completed (the super-step is at the reduce phase).
3. Multiple writes to `Append` channels (where multi-write is permitted) are present.

## Postconditions

1. Channel reducer functions are applied in ascending lexicographic order of `(task_id, channel_name)` for the collected write set.
2. An `Append` channel that received writes from tasks `["task_b", "task_a", "task_c"]` (in completion order) applies them in order `["task_a", "task_b", "task_c"]` (sorted order). The resulting list has items in the sorted task order.
3. The sort is stable: if two writes have the same `task_id` and `channel_name` (a programming error, not a normal case), they maintain their relative order as collected.
4. The sort key contains no runtime-non-deterministic component: no `Instant::now()`, no `std::thread::current().id()` hash, no `HashMap` iteration.
5. The deterministic order is identical for the same write set on any OS, CPU, or Rust toolchain version (pure string comparison).

## Invariants

- **DI-001 (BSP Reducer Determinism):** Identical inputs always produce identical `GraphState`. The sort-key contract is the mechanism by which this invariant is implemented for `Append` and `BinaryOperatorAggregate` channels.
- The sort is applied to the entire write set before any reducer call — it is not applied per-channel individually. This means the global ordering of (task_id, channel_name) determines which reducer call happens first when there are multiple channels with writes.

## Reference Evidence

**Source:** LangGraph Python reference (`pregel/algo.py`).
- `apply_writes` in LangGraph iterates channel writes sorted by `(task_id, channel_name)`.
  Python dicts maintain insertion order (3.7+) but the sort ensures writes from concurrent
  tasks are applied in a consistent order regardless of which task finished first.
- The sort is on the string representation of the task ID — matching the behavior of Python's
  default string comparison (lexicographic UTF-8 order).
- NE-17: adk-rust's `buffer_unordered` collects task outputs in arrival order and applies
  reducers in that non-deterministic order — the counter-example this BC forbids.

## Edge Cases

### EC-001: Append channel with 5 tasks, random completion order
**Scenario:** Tasks `["t3", "t1", "t5", "t2", "t4"]` each append one item to an `Append` channel. They complete in the order `[t5, t1, t3, t4, t2]`.
**Expected behavior:** The Append channel's final value is `[t1_item, t2_item, t3_item, t4_item, t5_item]` (sorted by task_id). The completion order is irrelevant.

### EC-002: Multiple channels, multiple tasks
**Scenario:** Tasks A and B write to channels X and Y. A writes to X; B writes to X and Y.
**Expected behavior:** Reducer order for non-conflicting writes: sorted by `(task_id, channel_name)`:
1. `(A, X)` — A's write to X
2. `(B, X)` — B's write to X (only valid if X is Append; LastValue would produce EC-001 in BC-2.03.002)
3. `(B, Y)` — B's write to Y

### EC-003: Sort key stability with identical task_id (abnormal)
**Scenario:** The same task writes to the same channel twice in one super-step (a programming error).
**Expected behavior:** The stable sort preserves their relative order as collected. Whether this is an error depends on the channel type (LastValue → error per BC-2.03.002; Append → two items in collected order).

### EC-004: BinaryOperatorAggregate channel with non-commutative operator
**Scenario:** A `BinaryOperatorAggregate` channel uses string concatenation as its reducer (non-commutative: `"a" + "b" != "b" + "a"`). Tasks A and B both write.
**Expected behavior:** The reducer applies in sorted task-id order: A's write first, then B's. The result is deterministic because the sort order is deterministic.
**Note:** This edge case demonstrates why the sort order matters for non-commutative reducers. `Append` channels are always sorted by task-id; BinaryOperatorAggregate channels follow the same rule.

### EC-005: Single task — sort is vacuous
**Scenario:** Only one task writes to any channel in a super-step.
**Expected behavior:** No sort is needed; the single write is applied directly. Behavior identical to before the sort was introduced.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | 3 tasks `["t3","t1","t2"]` append to `items` channel, completion order `[t3,t2,t1]` | `items == [t1_val, t2_val, t3_val]` | Sorted, not completion-order |
| TV-002 | Same graph as TV-001, run twice with different completion delays | Identical final state on both runs | Determinism across runs |
| TV-003 | Task "zz" and task "aa" both append to `items` | `items == [aa_val, zz_val]` | Lexicographic sort ("aa" < "zz") |
| TV-004 | Single task writes to 3 channels | Reducers applied in channel_name order (only one task_id) | Single-task degenerate case |
| TV-005 | Kani: non-det completion order for 2 tasks, Append channel | Kani verifies `items` is identical for all orderings | Phase 6 formal seed |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI001-03 | Reducer application order matches `sort_by((task_id, channel_name))` for all tested inputs | Property test (proptest: random task_ids, random completion order) | Phase 1 |
| VP-DI001-04 | No std::HashMap unordered iteration appears in reducer application path | Static analysis / CI grep | Wave 1 CI |

## Related BCs

- BC-2.03.001 — BSP determinism (composes with: this BC is the sort-key specification for the determinism invariant)
- BC-2.03.002 — Concurrent LastValue rejection (composes with: the sort runs after concurrent-write detection)
- BC-2.02.002 — Channel semantics (depends on: defines which channels allow multiple writers)

## Architecture Anchors

- `ferrochain-graph/src/pregel/reducer.rs` — sort-before-reduce logic
- `ferrochain-graph/src/pregel/types.rs` — `WriteRecord { task_id: String, channel_name: String, value: ChannelValue }`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-DI001-03, VP-DI001-04

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-004 |
| Capability Anchor Justification | CAP-004 ("BSP Graph Execution with Deterministic Reducer Order") per capabilities-p0.md §CAP-004 — "all channel reducers apply in deterministic task-identity-sorted order" is verbatim in the capability description |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism) |
| NE References | NE-17 |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | P (property), K (Kani — Phase 6) |
| Module | ferrochain-graph |
