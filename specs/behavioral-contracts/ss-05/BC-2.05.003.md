---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.003
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-05
capability: CAP-006
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-006
  - domain-spec/invariants.md#DI-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "2f16fbd"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.003: Interrupted Node Re-Executes from Start of Super-Step on Resume

## Description

When a `Command(resume=value)` is applied to an interrupted graph, the interrupted node
re-executes from the **beginning of its function body** — not from the point where
`interrupt()` was called. All code before the `interrupt()` call runs again. Prior
`interrupt()` calls in the re-execution return their stored resume values from the
per-task scratchpad (idempotent replay) instead of raising. This is a deliberate,
load-bearing contract: the node body must be tolerant of re-execution up to the interrupt
point. This contract is the Rust port of LangGraph's `Command(resume=...)` replay
behavior (semport §3.2) and is the primary design distinction from adk-rust's
notification-only interrupt (CONFLICT-3).

## Preconditions

1. A node was previously halted by `interrupt()` (BC-2.05.001 is satisfied: state is
   durably persisted with INTERRUPT marker).
2. The caller submits `Command(resume=value)` to the graph, referencing the same
   `thread_id` as the interrupted run.
3. The engine has loaded the interrupted checkpoint from the `CheckpointSaver`.
4. The resume value has been placed into scratchpad slot N corresponding to the
   interrupted `interrupt()` call's FIFO position (BC-2.05.002).

## Postconditions

1. The engine identifies the interrupted task from the checkpoint's INTERRUPT marker.
2. The interrupted task's node function is **invoked from its first line** — not
   from the position of the `interrupt()` call.
3. All code before the `interrupt()` call executes again as part of the re-execution.
4. Each `interrupt()` call encountered during re-execution checks the per-task scratchpad:
   - If a resume value is stored at this FIFO position, `interrupt()` returns that value
     **without raising** (idempotent replay).
   - If no resume value is stored (a new, not-yet-resumed interrupt), `interrupt()` raises
     again and halts the re-execution with a new interrupt.
5. When all previously-resumed `interrupt()` calls have returned their values and the node
   reaches new logic (or completes without further interrupts), the super-step advances
   normally.
6. The node does NOT resume "from where it left off" — there is no continuation-passing or
   coroutine-resume mechanism; re-execution is total from the function's start.

## Invariants

- **DI-003 (HITL FIFO Resume-Value Delivery):** The node's re-execution replays prior
  interrupt positions from the scratchpad in strict FIFO order; no out-of-order replay.
- The re-execution replay is idempotent with respect to the interrupt() calls: the same
  node function called again with the same scratchpad state produces the same interrupt-
  return values.
- Side effects that occur before the `interrupt()` point run again on re-execution.
  The node implementer is responsible for making those side effects idempotent; the
  framework does NOT deduplicate external side effects automatically.
- This "re-execute from start" contract applies to every level of nested subgraphs —
  a subgraph node that interrupted also re-executes from its entry point.

## Edge Cases

### EC-001: Node has observable side effects before the interrupt()
**Scenario:** Node calls `external_api_call()` then `interrupt("approve?")`. On resume,
`external_api_call()` is called again before `interrupt("approve?")` returns the value.
**Expected behavior:** `external_api_call()` executes again. The node implementer must
ensure the call is idempotent (or guarded by a flag in node state). ferrochain does not
automatically deduplicate side effects. This is a documented contract footgun.
**Reference:** semport §5.3 (idempotency expectations).

### EC-002: Node calls interrupt() twice; first resume already delivered
**Scenario:** Node calls `interrupt("q1")` (slot 0) then `interrupt("q2")` (slot 1).
`Command(resume="a")` has been applied. On re-execution: `interrupt("q1")` has slot 0
filled → returns `"a"` without halting. `interrupt("q2")` does NOT have slot 1 filled
→ raises again.
**Expected behavior:** The graph halts at `interrupt("q2")` awaiting a second resume.
The re-execution stops at the first not-yet-resumed interrupt, not at the end of the
function.
**Reference:** DI-003; BC-2.05.002.

### EC-003: resume value causes node to take a different code path than original execution
**Scenario:** Node checks the return value of `interrupt("decision?")` to branch: if
`"reject"`, it raises an error; if `"approve"`, it proceeds. On re-execution, the same
branching code runs.
**Expected behavior:** The resume value `"reject"` or `"approve"` is returned by
`interrupt()` and the branching logic executes normally. The node's code path may differ
from the original execution that raised the interrupt — this is the intended use case.

### EC-004: Node re-executes but checkpoint state has changed (time-travel fork)
**Scenario:** Operator forks the thread to a prior checkpoint (BC-2.04.004) and applies
a different resume value, creating an alternate execution branch.
**Expected behavior:** Node re-executes from its start with the forked checkpoint's state.
FIFO scratchpad for the forked thread is independent of the original. Fork lineage is
preserved via parent_checkpoint_id.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Node: `let x = compute(); let v = interrupt("ask"); use(v)`. Resume with `"answer"` | On re-execution: `compute()` runs again; `interrupt("ask")` returns `"answer"`; `use("answer")` proceeds | Happy path — re-execute from start, prior slot returns stored value |
| TV-002 | Same node; `compute()` has an observable side effect (counter += 1) | Counter incremented twice (once on original execution, once on re-execution) | Side-effect re-execution — node must be idempotent |
| TV-003 | Node calls `interrupt("q1")` then `interrupt("q2")`; only first resume delivered | Re-execution: `q1` returns resume value; `q2` raises again; run halts at `q2` | Partial re-execution halts at first un-resumed interrupt |
| TV-004 | Resume value causes node to branch and NOT reach `interrupt("q2")` | `q2` never fires; node completes; super-step advances | Branching on resume value — some interrupt calls may not be reached |
| TV-005 | Node calls `interrupt()` inside a loop; first 3 iterations each interrupt | 3 rounds of resume required; each re-execution replays prior slots 0..N-1 | Loop with interrupt per iteration |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-HITL-05 | Re-execution always starts from node function entry, never from interrupt() call site | Integration test (instrument node entry point with counter; verify count increments on each resume) | Phase 1 |
| VP-HITL-06 | Prior interrupt() calls in re-execution return stored values without halting | Integration test (multi-interrupt node; verify second interrupt() does not surface before first is resolved) | Phase 1 |

## Related BCs

- BC-2.05.001 — depends on: durable interrupt state with INTERRUPT marker is prerequisite
- BC-2.05.002 — depends on: FIFO scratchpad slots are the source of idempotent replay values
- BC-2.05.004 — depends on: Command(resume=value) is the API that triggers re-execution
- BC-2.04.001 — related to: per-task put_writes durability is what makes re-execution safe (no lost work from completed tasks)

## Architecture Anchors

- `ferrochain-graph/src/pregel/loop.rs` — `_suppress_interrupt` / resume path; node re-invocation
- `ferrochain-graph/src/pregel/algo.rs` — `_reapply_writes_to_succeeded_nodes` (skip INTERRUPT/RESUME markers)
- `ferrochain-graph/src/types.rs` — `NodeInterrupt`, `Command`, `InterruptScratchpad`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-HITL-05, VP-HITL-06

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-006 |
| Capability Anchor Justification | CAP-006 ("HITL Interrupt / Resume with FIFO Resume-Value Delivery") per capabilities-p0.md §CAP-006 — the "Resume" half of CAP-006 is specified by this BC: the node-re-executes-from-start contract is explicitly named in the capability's grounding ("CONFLICT-3/D17-Q2: node-re-executes-from-start") |
| L2 Domain Invariants | DI-003 (HITL FIFO Resume-Value Delivery) |
| D17 Commitment | D17-Q2 — HITL contract as Phase-1 BC |
| CONFLICT Reference | CONFLICT-3 (adk-rust has no node-re-executes-from-start contract; LangGraph is the behavioral reference per §3.2) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | I (integration) |
| Module | ferrochain-graph |
