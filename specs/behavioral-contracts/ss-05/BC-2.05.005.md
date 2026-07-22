---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.005
version: "1.6"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.1 (ADV-P1D-PASS-27): F-P27-01 replace retired E-GRAPH-* wildcard citation in EC-001 and TV-003 with concrete E-GRAPH-002 POLICY→422 per-endpoint override citation (BC-2.14.002 PC3 9th override); wildcard was retired by OBS-1 narrowing in P26."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph / ferrochain-server per module-decomposition.md v1.10."
  - "1.3 (F-P109-01, 2026-07-18): Add thread_id to all E-GRAPH-002 struct/variant sites — 9 sites (EC-001/002/003/004, TV-001/002/003/004/005). Canonical form { thread_id, run_status } per PC1/PC3. EC-002 and TV-002 were bare-variant forms (no struct braces); expanded to full struct with run_status: 'completed'. TD-VSDD-060 file-wide sweep: all 10 E-GRAPH-002 occurrences (including PC1 which was already correct) now uniformly carry both fields. Alias: thread_id <-> <run_id> (interrupt context — registered in gate #33 v2.36)."
  - "1.4 (F-P118-02, fix burst 121, 2026-07-19): Related BCs §BC-2.12.003 run lifecycle state list: add summary_halt — '(queued/in_progress/completed/failed/interrupted/cancelled/summary_halt)'. VP-HITL-10: 'four non-interrupted states' → 'five non-interrupted terminal/running states'; parameterized list adds summary_halt. TD-VSDD-060 file-wide sweep: these two sites are the only status enumerations not already exhaustive; all E-GRAPH-002 { run_status } struct sites enumerate specific concrete values (not the full set) and are exempt."
  - "1.5 (F-P119-01 + OBS-1 + OBS-2, fix burst 122, 2026-07-19): F-P119-01: Description updated to enumerate all non-interrupted statuses including summary_halt; Preconditions §2 adds clause (e) summary_halt (run terminated via OnCeiling::Summarize; BC-2.10.003 PC8(d) + BC-2.12.003 PC8); Canonical Test Vectors adds TV-006 (summary_halt guard). OBS-1 adjudication — production-grade totality chosen over delegation narrowing: BC-2.05.005 guard must be total over ALL non-interrupted run_status values because queued (never-started run has no interrupt slot before first node executes) and cancelled (in-flight slots discarded at cancellation) are equally unable to have an active interrupt; Preconditions §2 adds clauses (f) queued and (g) cancelled; TVs add TV-007 (queued guard) and TV-008 (cancelled guard); BC-2.05.004 Invariants already correctly enumerated all six statuses — both BCs now coherent. OBS-2: VP-HITL-10 rewritten precisely — 'six non-interrupted run_status values (completed, failed, in_progress, summary_halt, queued, cancelled) plus the interrupted-slots-consumed scenario (PC2(d)/TV-002) — 7 total parameterized test cases'. TD-VSDD-060 sweep: Preconditions §2 normative guard list (clauses a-g): now total over all 7 guard cases; VP-HITL-10 parameterized count: rewritten with derivable 7-case enumeration; Related BCs lifecycle list (~line 138, BC-2.12.003 lifecycle reference): not a guard enumeration, already exhaustive, exempt; all E-GRAPH-002 {run_status} struct sites (EC-001/002/003/004, TV-001 through TV-008): specific concrete values, correctly exempt."
  - "1.6 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
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

# BC-2.05.005: Resume on Empty Interrupt Queue Returns Err(NoActiveInterrupt)

## Description

If a caller submits `Command(resume=value)` to a graph run that has no active interrupt
pending — because the run is completed, failed, still running (`in_progress`), queued but
not yet started, cancelled, terminated via ceiling summarize (`summary_halt`), or all
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
   e. `summary_halt` — the run was terminated by an `OnCeiling::Summarize` policy
      (BC-2.10.003 PC8(d); BC-2.12.003 PC8); the ceiling caused the run to halt
      with a summary rather than raising an interrupt slot.
   f. `queued` — the run has been scheduled but execution has not yet begun; no
      interrupt slot can exist before the first node executes.
   g. `cancelled` — the run was cancelled before completing; any in-flight interrupt
      slots have been discarded.

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
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "completed" })`.
HTTP endpoint returns `422 Unprocessable Entity` (E-GRAPH-002 POLICY→422 per-endpoint override; BC-2.14.002 PC3 9th override; interface-definitions.md §HTTP Status Codes 422 row). Run state unchanged.
**Reference:** DEC-006.

### EC-002: Resume after all interrupt slots consumed
**Scenario:** Node called `interrupt()` once; first `Command(resume="a")` was applied and
consumed the slot. Caller submits a second `Command(resume="b")` even though the node
has since completed.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "completed" })`. The second resume has nowhere
to go. If the run has since completed, status is `completed`.

### EC-003: Resume on a run that has never been interrupted
**Scenario:** A `thread_id` exists with a completed run that never called `interrupt()`.
Caller submits `Command(resume="unexpected")`.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "completed" })`.
The run has no INTERRUPT marker in its checkpoint.

### EC-004: Resume on a run that is still actively running (no interrupt yet)
**Scenario:** A run is in-flight (status `in_progress`); caller preemptively submits
`Command(resume="preemptive")`.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "in_progress" })`.
The engine does not buffer the preemptive resume value for a future interrupt.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `graph.invoke(Command(resume="oops"), config_for_completed_thread)` | `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "completed" })` | Happy-path error — DEC-006 |
| TV-002 | Node called `interrupt()` once; first resume consumed; second `Command(resume="extra")` submitted | `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "completed" })` after node completes | Slot-exhausted guard |
| TV-003 | `POST /threads/{thread_id}/runs/{run_id}/resume` on thread with no interrupt history | HTTP 422; `E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "completed" }` in body | Server-side endpoint guard (E-GRAPH-002 POLICY→422 per-endpoint override; BC-2.14.002 PC3; interface-definitions.md §HTTP Status Codes 422 row) |
| TV-004 | `Command(resume="x")` while run is in `in_progress` state (concurrent access) | `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "in_progress" })` | Race-condition guard |
| TV-005 | `Command(resume="x")` on `failed` run | `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "failed" })` | Failed run guard |
| TV-006 | `Command(resume="x")` on a run with status `summary_halt` | `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "summary_halt" })` | Summary-halt guard — ceiling-terminated run |
| TV-007 | `Command(resume="x")` on a run with status `queued` (not yet started) | `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "queued" })` | Queued guard — never-started run |
| TV-008 | `Command(resume="x")` on a run with status `cancelled` | `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status: "cancelled" })` | Cancelled guard — terminated run |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-HITL-09 | Spurious Command(resume=) never mutates checkpoint or run state | Unit test (assert checkpoint unchanged after Err) | Phase 1 |
| VP-HITL-10 | Error carries run_status field for all non-interrupted guard cases | Unit test (parameterized over the six non-interrupted run_status values: completed, failed, in_progress, summary_halt, queued, cancelled; plus the interrupted-slots-consumed scenario (PC2(d)/TV-002) — 7 total parameterized test cases) | Phase 1 |

## Related BCs

- BC-2.05.001 — composes with: the dual of this BC — interrupt() establishes the slot this BC guards against
- BC-2.05.002 — composes with: FIFO slot exhaustion detected here after BC-2.05.002's delivery
- BC-2.05.004 — composes with: Command(resume=) submitted here is the same Command type BC-2.05.004 defines
- BC-2.12.003 — related to: run lifecycle states (queued/in_progress/completed/failed/interrupted/cancelled/summary_halt) are defined in the server's run contract; BC-2.12.003 defines `in_progress`

## Architecture Anchors

- `ferrochain-graph/src/scheduler.rs` (`graph::scheduler`) — resume path: check INTERRUPT marker before applying Command
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
| Module | ferrochain-graph / ferrochain-server |
