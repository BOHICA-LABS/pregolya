---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.005
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.1 (ADV-P1D-PASS-27): F-P27-01 replace retired E-GRAPH-* wildcard citation in EC-001 and TV-003 with concrete E-GRAPH-002 POLICY→422 per-endpoint override citation (BC-2.14.002 PC3 9th override); wildcard was retired by OBS-1 narrowing in P26."
origin: greenfield
priority: P0
subsystem: SS-05
capability: CAP-006
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-006
  - domain-spec/invariants.md#DI-003
  - domain-spec/edge-cases.md#DEC-006
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "ccc8f52"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.005: Resume on Empty Interrupt Queue Returns Err(NoActiveInterrupt)

## Description

If a caller submits `Command(resume=value)` to a graph run that has no active interrupt
pending — because the run is already completed, has failed, is still running, or all
prior interrupts have already been consumed — the operation returns
`Err(E-GRAPH-002 NoActiveInterrupt)` immediately. The run state is not modified. The
checkpoint is not written. This is a guard contract: it makes the "spurious resume"
case deterministic and observable rather than silently corrupting state or being ignored.
This contract directly implements DEC-006.

## Preconditions

1. A caller submits `Command(resume=value)` or `POST /threads/{thread_id}/runs/{run_id}/resume`.
2. The run referenced by `thread_id` is in one of these states:
   a. `completed` — the run finished normally.
   b. `failed` — the run ended in error.
   c. `in_progress` — the run is still executing (not yet interrupted).
   d. `interrupted` but all FIFO slots have already been consumed (no un-resolved
      interrupt positions remain in the per-task scratchpad).

## Postconditions

1. `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status })` is returned to the
   caller.
2. The run state in the checkpoint is NOT modified — no new checkpoint is written, no
   scratchpad slot is created, no status transition occurs.
3. The error carries the `thread_id` and the current `run_status` so the caller can
   distinguish "already completed" from "still running" without a separate status query.
4. Subsequent valid `Command(resume=...)` calls (if the run later enters `interrupted`
   state via a new interrupt) are unaffected by the failed attempt.

## Invariants

- **DI-003 (HITL FIFO Resume-Value Delivery):** There is no mechanism to deliver a
  resume value out of order or to skip an interrupt. Attempting to deliver to a non-
  existent interrupt slot is a hard error, not a silent no-op.
- Returning an error is the ONLY valid outcome for a spurious resume — the engine must
  never silently discard a resume value, silently advance state, or create a phantom
  interrupt slot to consume the value.
- The error type is `E-GRAPH-002 NoActiveInterrupt` (from the error taxonomy in §5
  of the PRD). It must carry enough context for the caller to diagnose without an
  additional status query.

## Edge Cases

### EC-001: Resume on a completed run (DEC-006)
**Scenario:** `POST /threads/{thread_id}/runs/{run_id}/resume` called but the run completed normally several
seconds ago. No interrupt was ever pending.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt { run_status: "completed" })`.
HTTP endpoint returns `422 Unprocessable Entity` (E-GRAPH-002 POLICY→422 per-endpoint override; BC-2.14.002 PC3 9th override; interface-definitions.md §HTTP Status Codes 422 row). Run state unchanged.
**Reference:** DEC-006.

### EC-002: Resume after all interrupt slots consumed
**Scenario:** Node called `interrupt()` once; first `Command(resume="a")` was applied and
consumed the slot. Caller submits a second `Command(resume="b")` even though the node
has since completed.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt)`. The second resume has nowhere
to go. If the run has since completed, status is `completed`.

### EC-003: Resume on a run that has never been interrupted
**Scenario:** A `thread_id` exists with a completed run that never called `interrupt()`.
Caller submits `Command(resume="unexpected")`.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt { run_status: "completed" })`.
The run has no INTERRUPT marker in its checkpoint.

### EC-004: Resume on a run that is still actively running (no interrupt yet)
**Scenario:** A run is in-flight (status `in_progress`); caller preemptively submits
`Command(resume="preemptive")`.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt { run_status: "in_progress" })`.
The engine does not buffer the preemptive resume value for a future interrupt.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `graph.invoke(Command(resume="oops"), config_for_completed_thread)` | `Err(E-GRAPH-002 NoActiveInterrupt { run_status: "completed" })` | Happy-path error — DEC-006 |
| TV-002 | Node called `interrupt()` once; first resume consumed; second `Command(resume="extra")` submitted | `Err(E-GRAPH-002 NoActiveInterrupt)` after node completes | Slot-exhausted guard |
| TV-003 | `POST /threads/{thread_id}/runs/{run_id}/resume` on thread with no interrupt history | HTTP 422; `E-GRAPH-002 NoActiveInterrupt { run_status: "completed" }` in body | Server-side endpoint guard (E-GRAPH-002 POLICY→422 per-endpoint override; BC-2.14.002 PC3; interface-definitions.md §HTTP Status Codes 422 row) |
| TV-004 | `Command(resume="x")` while run is in `in_progress` state (concurrent access) | `Err(E-GRAPH-002 NoActiveInterrupt { run_status: "in_progress" })` | Race-condition guard |
| TV-005 | `Command(resume="x")` on `failed` run | `Err(E-GRAPH-002 NoActiveInterrupt { run_status: "failed" })` | Failed run guard |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-HITL-09 | Spurious Command(resume=) never mutates checkpoint or run state | Unit test (assert checkpoint unchanged after Err) | Phase 1 |
| VP-HITL-10 | Error carries run_status field for all four non-interrupted states | Unit test (parameterized over completed/failed/in_progress/slot-exhausted) | Phase 1 |

## Related BCs

- BC-2.05.001 — composes with: the dual of this BC — interrupt() establishes the slot this BC guards against
- BC-2.05.002 — composes with: FIFO slot exhaustion detected here after BC-2.05.002's delivery
- BC-2.05.004 — composes with: Command(resume=) submitted here is the same Command type BC-2.05.004 defines
- BC-2.12.003 — related to: run lifecycle states (queued/in_progress/completed/failed/interrupted/cancelled) are defined in the server's run contract; BC-2.12.003 defines `in_progress`

## Architecture Anchors

- `ferrochain-graph/src/pregel/loop.rs` — resume path: check INTERRUPT marker before applying Command
- `ferrochain-graph/src/error.rs` — `E-GRAPH-002 NoActiveInterrupt` error variant definition
- `ferrochain-server/src/routes/runs.rs` — `POST /threads/{thread_id}/runs/{run_id}/resume` endpoint guard

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-HITL-09, VP-HITL-10

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-006 |
| Capability Anchor Justification | CAP-006 ("HITL Interrupt / Resume with FIFO Resume-Value Delivery") per capabilities-p0.md §CAP-006 — this BC specifies the guard behavior that makes FIFO delivery semantically complete: delivering to an absent slot is a hard error, not a silent no-op or phantom delivery |
| L2 Domain Invariants | DI-003 (HITL FIFO Resume-Value Delivery) |
| Domain Edge Cases | DEC-006 (Resume Value Injection with Empty Interrupt Queue) |
| D17 Commitment | D17-Q2 — HITL contract as Phase-1 BC |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit) |
| Module | [architect to assign — ferrochain-graph, ferrochain-server] |
