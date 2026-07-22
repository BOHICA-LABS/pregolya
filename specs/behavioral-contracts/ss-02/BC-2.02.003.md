---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.003
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
red_gate: true
red_gate_source: R10
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph per module-decomposition.md v1.10."
  - "1.2 (F-P107-01 census, 2026-07-18): E-GRAPH-004 struct expanded to include step field missing from prior struct form. Was: { channel, writer } (2 fields — missing taxonomy placeholder '<n>' for super-step). Now: { channel, writer, step } (3 fields, 1:1 with taxonomy '<channel>', '<writer>', '<n>'). EC-003 and TV-004 updated. Same-class defect as E-GRAPH-011 discovered during message↔struct census rerun."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "deb1a0f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.003: NamedBarrierValue Missing-Writer Boundary Behavior (Red Gate — R10)

> **Red Gate test required.** A test for this contract must compile and FAIL (i.e., the
> behavior is demonstrably absent) before the implementation of `NamedBarrierValue` begins.
> This is a D17-Q9 Phase-1 mandatory Red Gate per R10: the upstream LangGraph reference has
> no unit test covering `NamedBarrierValue` missing-writer behavior (DEC-003). The test
> must be authored first and checked into the repository in a failing state.

## Description

`NamedBarrierValue` is a synchronization channel that becomes available only after each
of its declared named upstream writers has delivered exactly one write in the current
super-step. This contract specifies the boundary behavior when one or more declared
writers have NOT delivered a write before the super-step closes — a condition that has no
upstream Python unit test (R10) and therefore carries meaningful risk of an undiscovered
specification gap. The required behavior is: a missing writer causes the channel to remain
unavailable, which means the downstream node is not triggered in that step. The channel
does not raise an error, block indefinitely, or produce a partial value; it simply does
not become available.

## Preconditions

1. A `StateGraph` is compiled with a `NamedBarrierValue` channel that declares a fixed set
   of named writers, e.g., `writers: ["a", "b", "c"]`.
2. A super-step executes in which a strict subset of the declared writers delivers a write
   (e.g., writers `"a"` and `"b"` deliver, but `"c"` does not).
3. A downstream node is subscribed to the `NamedBarrierValue` channel.

## Postconditions

1. The `NamedBarrierValue` channel's `is_available()` returns `false` at the end of the
   super-step because not all declared writers delivered.
2. The downstream node subscribed to the channel is NOT triggered; no `PregelTask` is
   created for it in the current step.
3. No error is raised; the run does not transition to `failed`.
4. The partial writes that were delivered (`"a"`, `"b"`) are not observable to the
   downstream node in any step until the barrier is fully satisfied.
5. If in a subsequent super-step the remaining writers (`"c"`) deliver, and the prior
   writers (`"a"`, `"b"`) also deliver in that same subsequent step, then the barrier
   becomes available and the downstream node IS triggered in that later step.

## Invariants

- `NamedBarrierValue` availability is an all-or-nothing predicate: partial delivery never
  makes the channel available.
- Partial writes do not accumulate across super-steps: each super-step's writer-set is
  evaluated independently. A writer that wrote in step N but not step N+1 is treated as
  absent in step N+1.
- The channel does not block the event loop; a missing writer causes silent non-triggering,
  not a blocking wait.

## Edge Cases

### EC-001: All declared writers deliver — happy path barrier satisfaction
**Scenario:** All three named writers `"a"`, `"b"`, `"c"` each deliver exactly one write
to the `NamedBarrierValue` channel in the same super-step.
**Expected behavior:** The channel becomes available; `is_available()` returns `true`; the
downstream node is triggered in that step. This is the intended usage and confirms the
basic contract.

### EC-002: Zero writers deliver — channel unavailable, no error
**Scenario:** No declared writers deliver any write in a super-step (e.g., no upstream
node was triggered).
**Expected behavior:** The channel is unavailable; the downstream node is not triggered;
the graph may halt naturally (no tasks triggered at all) or continue if other nodes are
active. No error.

### EC-003: One writer delivers twice in same step
**Scenario:** Writer `"a"` produces two writes to the `NamedBarrierValue` channel in the
same super-step (e.g., via two separate `Send` tasks both named `"a"`).
**Expected behavior:** `Err(E-GRAPH-004 DuplicateBarrierWrite { channel: name, writer: "a", step: <n> })`
is returned; the run transitions to `failed`. A named writer must write exactly
once per step to avoid ambiguity.

### EC-004: NamedBarrierValue with unknown writer name registered at compile time
**Scenario:** `NamedBarrierValue` declares writer `"ghost"`, but no node named `"ghost"`
is registered in the graph.
**Expected behavior:** `compile()` returns `Err(E-GRAPH-010 UnknownBarrierWriter { channel:
name, writer: "ghost" })`; no compiled graph is produced.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `NamedBarrierValue(writers=["a","b","c"])`; step delivers from `"a"` and `"b"` only | Channel unavailable; downstream not triggered; run continues | **Red Gate vector** — must fail before implementation |
| TV-002 | Same channel; step delivers from all three `"a"`, `"b"`, `"c"` | Channel available; downstream triggered | Happy-path barrier satisfaction |
| TV-003 | Same channel; zero writers deliver | Channel unavailable; downstream not triggered; no error | Zero-delivery step |
| TV-004 | Writer `"a"` delivers twice in super-step 2 | `Err(E-GRAPH-004 DuplicateBarrierWrite { channel: "results", writer: "a", step: 2 })` | Duplicate write — channel, writer, and step all captured |
| TV-005 | Step N: `"a"`, `"b"` deliver (barrier unsatisfied). Step N+1: `"a"`, `"b"`, `"c"` all deliver | Step N: not triggered. Step N+1: triggered. | Per-step independent evaluation |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BARRIER-01 | NamedBarrierValue with partial writers does not trigger downstream and does not error | Red Gate test (compile+fail), then integration test post-implementation | Phase 1 |

## Related BCs

- BC-2.02.002 — sibling: unnamed BarrierValue shares the same availability predicate pattern
- BC-2.02.004 — sibling: EphemeralValue also has a clear-on-step lifecycle that complements barrier semantics
- BC-2.02.001 — depends on: channel registered via state schema inference described there

## Architecture Anchors

- `ferrochain-graph/src/channels/named_barrier.rs` — `NamedBarrierValue` channel type
- `ferrochain-graph/src/pregel/algo.rs` — `is_available()` check in `prepare_next_tasks`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BARRIER-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — `NamedBarrierValue` is explicitly listed by name in CAP-003's channel type inventory; this BC specifies its missing-writer boundary, which CAP-003 identifies as requiring a Red Gate test (R10) |
| L2 Domain Invariants | — |
| D17 Commitment | D17-Q9 — R10 Red Gate test required (NamedBarrierValue missing-writer has no upstream test) |
| DEC Reference | DEC-003 (NamedBarrierValue with Missing Writer — R10) |
| Risk Source | R10 (upstream LangGraph has no unit test for NamedBarrierValue missing-writer) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), Red Gate |
| Module | ferrochain-graph |
