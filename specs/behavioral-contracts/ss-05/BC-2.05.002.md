---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.002
version: "1.2"
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
  - "1.2 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-006
  - domain-spec/invariants.md#DI-003
  - domain-spec/edge-cases.md#DEC-007
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "97ad8a7"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.002: FIFO Resume-Value Delivery Order

## Description

When a node calls `interrupt()` multiple times during its execution, each call occupies
a positional slot in a per-task scratchpad keyed by `interrupt_counter`. Resume values
are consumed from this scratchpad in strict FIFO order — the value delivered to the
first `interrupt()` call is consumed before the value for the second, regardless of
wall-clock timing of resume submissions. There is no mechanism to deliver a resume value
out of order, skip an interrupt, or address a specific interrupt by value content alone.
This contract implements the DI-003 invariant and is the runtime guarantee that makes
multi-step HITL dialogs reliable.

## Preconditions

1. A node has called `interrupt()` one or more times during its execution.
2. For each `interrupt()` call, a corresponding `Command(resume=value)` has been submitted
   by the caller (in any order of submission, but FIFO delivery is independent of submission
   order — delivery order is determined by the positional scratchpad slot).
3. The graph has a `CheckpointSaver` attached (DI-003 requires durable state; see BC-2.05.001).
4. Each `Command(resume=value)` references the same `thread_id` as the interrupted run.

## Postconditions

1. On the first `Command(resume=v1)`: `v1` is assigned to scratchpad slot 0 (the first
   `interrupt()` call's position). When the node re-executes, the first `interrupt()` returns
   `v1` instead of raising; the second `interrupt()` call (if any) raises again and halts.
2. On the second `Command(resume=v2)`: `v2` is assigned to scratchpad slot 1. When the node
   re-executes again, both `interrupt()` calls return their respective values; the node
   completes if there are no further `interrupt()` calls.
3. The scratchpad is scoped per-task (per-node invocation), not shared across nodes. Two
   different nodes that each call `interrupt()` have independent FIFO queues.
4. Resume values are never reordered by the engine regardless of the time gap between
   `Command(resume=...)` submissions.
5. After all interrupt slots are filled and the node completes, the scratchpad is cleared
   and the super-step advances.

## Invariants

- **DI-003 (HITL FIFO Resume-Value Delivery):** Resume values are consumed in strict FIFO
  order. There is no mechanism to deliver a resume value out of order or to skip an
  interrupt.
- The interrupt counter is a monotonically increasing integer per-task; the N-th call to
  `interrupt()` in a given node execution receives the N-th resume value (zero-indexed).
- Resume values are scoped per-task (not per-thread or per-graph): two nodes cannot share
  their interrupt queues.
- A `Command(resume=value)` submitted before the N-th interrupt is reached in the node
  is held in the scratchpad until the node re-executes and reaches slot N.

## Edge Cases

### EC-001: Multiple stacked interrupts in one node (DEC-007)
**Scenario:** Node calls `interrupt("step1")` then `interrupt("step2")`. HITL submits
`Command(resume="a")`, then `Command(resume="b")`.
**Expected behavior:** On first resume, node re-executes; first `interrupt()` returns `"a"`;
second `interrupt()` raises again and halts. On second resume, node re-executes again;
both `interrupt()` calls return `"a"` and `"b"` respectively; node completes.
**Reference:** DEC-007; DI-003; semport §3.1 (`interrupt_counter()`).

### EC-002: Single interrupt — trivial FIFO (one-element queue)
**Scenario:** Node calls `interrupt("approval_needed")` exactly once. `Command(resume="yes")`
submitted.
**Expected behavior:** `interrupt()` returns `"yes"` on re-execution. No ordering ambiguity.
The single-element case is the canonical HITL approval gate.

### EC-003: Resume value submitted before second interrupt is reached
**Scenario:** Node calls `interrupt("step1")`. First resume `"a"` submitted. On re-execution,
node calls `interrupt("step1")` again (returns `"a"`) and then `interrupt("step2")`. Second
resume `"b"` has not yet been submitted.
**Expected behavior:** Node halts at the second `interrupt()`. When `"b"` is later submitted,
node re-executes; `interrupt("step1")` returns `"a"`; `interrupt("step2")` returns `"b"`;
node completes. The second resume is held in the scratchpad until needed.

### EC-004: Two nodes both call interrupt() in same super-step
**Scenario:** Super-step has nodes A and B; A calls `interrupt("a_needs_input")` and B calls
`interrupt("b_needs_input")` — their scratchpads are independent.
**Expected behavior:** Two separate interrupts are surfaced. Each must be resumed independently.
The FIFO order is per-task (A's scratchpad and B's scratchpad are disjoint).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Node calls `interrupt("q1")` then `interrupt("q2")`; resume with `Command(resume="a")` | Node re-executes; `q1` returns `"a"`; graph halts at `q2` again | FIFO first-slot consumed |
| TV-002 | Resume again with `Command(resume="b")` | Node re-executes; `q1` returns `"a"`, `q2` returns `"b"`; node completes | FIFO second-slot consumed |
| TV-003 | Single `interrupt("approve?")`; resume with `Command(resume="yes")` | `interrupt("approve?")` returns `"yes"`; node proceeds | Trivial one-element FIFO |
| TV-004 | Two nodes A and B each call `interrupt()` in same super-step | Two separate `{"__interrupt__": ...}` payloads; each node's FIFO queue is independent | Per-task scratchpad isolation |
| TV-005 | Resume value `v2` submitted before `v1`'s interrupt is reached in re-execution | `v2` stays in scratchpad slot 1; `v1` is consumed first on slot 0; ordering preserved | Out-of-order submission does not reorder delivery |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-HITL-03 | For N calls to `interrupt()`, exactly N `Command(resume=...)` invocations are required to advance past the node, consumed in call-site order | Integration test (parameterized N=1..5) | Phase 1 |
| VP-HITL-04 | Per-task scratchpad isolation: node A's resume values never appear in node B's scratchpad | Integration test (two-node super-step) | Phase 1 |

## Related BCs

- BC-2.05.001 — depends on: per-task scratchpad is created at interrupt persistence time
- BC-2.05.003 — composes with: FIFO delivery is realized during node re-execution from start
- BC-2.05.004 — depends on: Command(resume=value) is the API that populates FIFO slots
- BC-2.05.005 — related to: empty-queue guard catches extra Command(resume) after all slots filled

## Architecture Anchors

- `ferrochain-graph/src/hitl.rs` (`graph::hitl`) — `_scratchpad`, `interrupt_counter()` per-task state
- `ferrochain-graph/src/types.rs` — `InterruptScratchpad`, FIFO slot indexing

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-HITL-03, VP-HITL-04

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-006 |
| Capability Anchor Justification | CAP-006 ("HITL Interrupt / Resume with FIFO Resume-Value Delivery") per capabilities-p0.md §CAP-006 — this BC specifies the FIFO resume-value delivery constraint that is named verbatim in CAP-006's title |
| L2 Domain Invariants | DI-003 (HITL FIFO Resume-Value Delivery) |
| Domain Edge Cases | DEC-007 (Multiple Stacked Interrupts — FIFO Order) |
| D17 Commitment | D17-Q2 — HITL contract as Phase-1 BC |
| CONFLICT Reference | CONFLICT-3 (adk-rust has no per-task scratchpad, no FIFO delivery; this BC codifies the LangGraph requirement) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-graph |
