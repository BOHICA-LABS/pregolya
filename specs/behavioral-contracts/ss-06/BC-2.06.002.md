---
document_type: behavioral-contract
level: L3
bc_id: BC-2.06.002
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-06
capability: CAP-007
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-007
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/events.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "ba8b2643a565de06e82d5be3c4da33497acff41f22610e0e0ff06a2c8e8ee246"
---

# BC-2.06.002: run_id + parent_ids Correlation Across All Streaming Events

## Description

Every `StreamEvent` carries two mandatory correlation fields: `run_id` (a stable UUID
assigned at `RunStart` and held constant for the run's lifetime) and `parent_ids` (an ordered
list of ancestor `run_id`s from the outermost run to the immediate parent). Together these
fields form a directed correlation tree that allows observers to attribute events to their
originating run, reconstruct nested call graphs, and route per-step costs to the initiating
run. The contract follows the astream_events v2 7-key shape (semport/core/behavioral-intent.md
§D-2) adapted to ferrochain's native types; D13 exempts ferrochain from exact wire compatibility.

## Preconditions

1. A `Run` is executing; a `run_id` UUID has been assigned at `RunStart`.
2. For nested executions (subgraphs, tool-spawned sub-runs), a new `run_id` is assigned to
   the nested unit at its creation; the parent run's `run_id` is captured in the execution
   context before the nested unit starts.
3. The execution context propagates `run_id` and `parent_ids` through all nested call boundaries.

## Postconditions

1. Every `StreamEvent` variant carries the same `run_id` UUID assigned at `RunStart` for
   the run that emitted it. The field is present and non-null on every event variant.
2. For a top-level run, `parent_ids` is an empty list `[]`.
3. For a nested sub-run (subgraph invocation or tool-spawned run), `parent_ids` is the
   ordered list of ancestor `run_id`s from outermost to immediate parent:
   - Top-level run A: `run_id = A`, `parent_ids = []`
   - Subgraph run B nested inside A: `run_id = B`, `parent_ids = [A]`
   - Tool sub-run C invoked inside B: `run_id = C`, `parent_ids = [A, B]`
4. `parent_ids` is the same on every event emitted within a single sub-run (it does not
   change mid-run unless a deeper nesting is entered, which would create yet another sub-run).
5. `run_id` values are non-repeating UUIDs (v4 or v7). Two distinct runs, even on the same
   `thread_id`, carry distinct `run_id`s.

## Invariants

- `run_id` is immutable for the lifetime of a run — it is never regenerated at super-step
  boundaries, interrupts, or resumes. A resumed run that creates a new `Run` record issues a
  new `run_id` (not a reuse of the interrupted run's `run_id`).
- `parent_ids` is assigned once at run creation and is read-only thereafter. It is not
  mutated by sub-events within the run.
- The transitivity rule must hold: if run A is an ancestor of run B, then `run_id(A)` appears
  in the `parent_ids` of every event emitted by run B (directly or transitively).
- No two concurrent runs share a `run_id`, regardless of thread, namespace, or fork.
- Fan-out PUSH tasks (Send API) within a super-step share the parent run's `run_id` and
  `parent_ids` — they are tasks within a run, not independent sub-runs.

## Edge Cases

### EC-001: Interrupted run resumed as a new Run record
**Scenario:** A run is interrupted (via `interrupt()`), checkpointed, then resumed. The server
creates a new `Run` record for the resumed execution.
**Expected behavior:** The resumed run receives a new `run_id`; it does NOT reuse the
interrupted run's `run_id`. Correlation between interrupted run and resume run is available
via `parent_checkpoint_id` in the checkpoint metadata (DI-004), not via `run_id` reuse.
If the resume run is created with the interrupted run as a logical parent, the interrupted
run's `run_id` may appear in the new run's `parent_ids` (server implementation choice,
must be documented in ADR).

### EC-002: Fan-out via Send API
**Scenario:** A Send API fan-out in a super-step creates N parallel PUSH tasks. Each PUSH
task may emit `NodeStart`/`NodeEnd` events.
**Expected behavior:** All PUSH task events carry the same `run_id` as the enclosing run;
`parent_ids` is unchanged. Fan-out tasks are not independent sub-runs and do not create
new `run_id`s.

### EC-003: run_id serialization round-trip
**Scenario:** A `StreamEvent` is serialized to msgpack (checkpoint wire format) and
deserialized by a remote consumer.
**Expected behavior:** `run_id` and `parent_ids` are byte-identical across the
serialization/deserialization round-trip. UUIDs are stored as 16-byte binary or UUID string
consistently (ferrochain-native format; consistency is the requirement, not the specific
encoding).

### EC-004: Very deep nesting (≥ 10 levels of subgraph)
**Scenario:** A graph invokes a subgraph that invokes a subgraph, recursively, 10 levels deep.
**Expected behavior:** `parent_ids` grows to hold 10 entries. No truncation occurs. The
full ancestry chain is preserved. Performance is O(depth) for `parent_ids` allocation.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Top-level run, no subgraphs; collect all events | All events: same `run_id`; `parent_ids = []` | Happy path — flat run |
| TV-002 | Run A → subgraph B; collect B's events | B events: `run_id = <B_uuid>`, `parent_ids = [<A_uuid>]` | Single nesting level |
| TV-003 | Run A → subgraph B → subgraph C; collect C's events | C events: `run_id = <C_uuid>`, `parent_ids = [<A_uuid>, <B_uuid>]` | Two nesting levels |
| TV-004 | Two concurrent runs R1 and R2 on different threads | R1 events: `run_id = <R1_uuid>`; R2 events: `run_id = <R2_uuid>`; no UUID collision | Concurrency uniqueness |
| TV-005 | Send API fan-out: 3 PUSH tasks in one super-step | All 3 PUSH-task events carry same `run_id` as enclosing run; `parent_ids` unchanged | Fan-out is within-run, not sub-run |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-STREAM-02 | All events for a run share the same `run_id`; subgraph events carry correct `parent_ids` ancestry | Integration test — collect all events for nested run scenario; assert UUID uniqueness + parent chain correctness | Phase 1 |

## Related BCs

- BC-2.06.001 — depends on: `run_id` + `parent_ids` fields must exist on every `StreamEvent` variant defined there
- BC-2.06.003 — composes with: correlation fields must be correct on both streaming and unary event paths
- BC-2.04.004 — related to: `parent_checkpoint_id` provides lineage across interrupted/resumed runs where `run_id` changes
- BC-2.10.002 — related to: `EvidenceJournal` entries record `run_id` to correlate budget evaluations with runs

## Architecture Anchors

- `ferrochain-graph/src/pregel/events.rs` — `StreamEvent` base fields: `run_id: Uuid`, `parent_ids: Vec<Uuid>`
- `ferrochain-graph/src/pregel/context.rs` — `ExecutionContext` that propagates `run_id` and `parent_ids` into nested invocations
- `ferrochain-server/src/run_lifecycle.rs` — `run_id` UUID generation at `Run` creation

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-STREAM-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-007 |
| Capability Anchor Justification | CAP-007 ("Structured Streaming Event Taxonomy") per capabilities-p0.md §CAP-007 — this BC specifies the `run_id` and `parent_ids` correlation tree that is explicitly named in the "each carrying a run_id, parent_ids chain" clause of CAP-007 |
| L2 Domain Invariants | — |
| D17 Commitment | CONFLICT-5 (astream_events v2 fixed 7-key shape including `run_id` and `parent_ids` per semport/core/behavioral-intent.md §D-2 is the reference model; ferrochain adopts this correlation design) |
| CONFLICT Reference | CONFLICT-5 |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | I (integration) |
| Module | [architect to assign — ferrochain-graph, ferrochain-server] |
