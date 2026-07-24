---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.004
version: "1.5"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-05
changelog:
  - "1.1 (ADV-P1D-PASS-25): F-P25-05 PC4 'id field'→'interrupt_id field' with authority citations."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph per module-decomposition.md v1.10."
  - "1.3 (F-P118-02, fix burst 121, 2026-07-19): Invariant non-interrupted status list gains summary_halt: '(status queued, in_progress, completed, failed, cancelled, or summary_halt) returns Err(E-GRAPH-002 NoActiveInterrupt)'. TD-VSDD-060 file-wide sweep: line 87 'completed / interrupted / failed' describes specific re-execution outcomes (not a terminal-set enumeration; cancelled/summary_halt absent by design as it covers the resumed-execution state machine); exempt. Only line 99-100 enumerates the full non-interrupted guard set."
  - "1.4 (OBS-1 adjudication, fix burst 122, 2026-07-19): No normative text change — Invariants §4 (lines 99-101) already correctly delegated all six non-interrupted run_status values (queued, in_progress, completed, failed, cancelled, summary_halt) to BC-2.05.005. OBS-1 adjudication chose production-grade totality: BC-2.05.005 was updated to enumerate all six statuses plus the interrupted-slots-consumed scenario; delegation is now coherent in both directions. TD-VSDD-060 sweep: PC7 status transition description (line 87) — 'interrupted→in_progress→completed/interrupted/failed' describes re-execution path outcomes, not the terminal set; cancelled/summary_halt absent by design; exempt. Invariants non-interrupted guard (lines 99-101) — already exhaustive over all six statuses; unchanged."
  - "1.5 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
capability: CAP-006
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-006
  - domain-spec/invariants.md#DI-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "aac981e"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.004: Command(resume=value) API Contract for Programmatic Resume

## Description

`Command` is the programmatic type that callers submit to resume an interrupted graph.
A `Command(resume=value)` places `value` into the interrupted thread's per-task scratchpad
at the next available FIFO slot, then triggers node re-execution from start (BC-2.05.003).
`Command` optionally carries a state `update` (side-load state into channels), a `goto`
(dynamic routing to one or more nodes or `Send`s), and a `graph` scope selector (current
graph or parent). A `Command` returned from a tool function is also valid (tool output
mixin). This BC specifies the full `Command` shape and the contract each field satisfies.

## Preconditions

1. A graph run is in the `interrupted` state (INTERRUPT marker persisted per BC-2.05.001)
   for the target `thread_id`.
2. The caller has a valid `thread_id` matching the interrupted run.
3. Either `Command(resume=value)` is submitted via `graph.invoke(Command(resume=v),
   config)` or `graph.stream(Command(resume=v), config)`.
4. If `Command(resume={interrupt_id: value})` form is used, the `interrupt_id` must match
   the `interrupt_id` field of one of the surfaced `InterruptPayload`s (hash of the checkpoint
   namespace at interrupt time). Authority: BC-2.05.001 TV-001 (`interrupt_id` is the canonical
   field name in `InterruptPayload`); entities-server.md §Interrupt (`interrupt_id: Uuid`). Fixed
   F-P25-05: prior wording incorrectly said "the `id` field".

## Postconditions

1. **`resume` field:** The resume value is placed into the per-task scratchpad's next FIFO
   slot for the interrupted task. Node re-executes from start (BC-2.05.003). The resume
   value is available via `interrupt()` return at the appropriate FIFO position.
2. **`resume={interrupt_id: value}` form:** The resume value is routed to the specific
   interrupt matching `interrupt_id`. This allows targeted delivery when a super-step
   surfaces multiple concurrent interrupts from different tasks; each interrupt_id
   addresses a distinct task's scratchpad.
3. **`update` field (optional):** If present, channel updates are applied to graph state
   BEFORE the node re-executes. These are treated as a state side-load (equivalent to
   `update_state`). Channels are updated via their configured reducers.
4. **`goto` field (optional):** If present and non-empty, after the current command is
   processed, routing is forced to the specified node name(s) or `Send`(s), bypassing
   the normal conditional-edge routing for that step.
5. **`graph` field (optional):** `None` (default) = route within the current graph.
   `Command.PARENT` = escape to the parent graph, surfaced as a `ParentCommand`. Enables
   subgraph-to-parent handoff.
6. A `Command` returned by a tool function (tool output mixin) is treated identically to
   a `Command` submitted via `graph.invoke`. The graph recognizes it as a routing/resume
   directive.
7. The run status transitions from `interrupted` → `in_progress` upon `Command` application,
   then to `completed` / `interrupted` / `failed` as the re-execution resolves.

## Invariants

- **DI-003 (HITL FIFO Resume-Value Delivery):** `resume` value is placed into the
  FIFO slot dictated by the scratchpad's `interrupt_counter`; delivery order is the
  invariant even when `{interrupt_id: value}` targeting is used (within a single task's
  scratchpad, FIFO is preserved).
- A `Command` with no `resume`, no `update`, and no `goto` is valid (a no-op resume signal
  that merely unblocks the super-step); it is NOT an error condition.
- `Command.PARENT` is only valid inside a subgraph execution context; submitting it at the
  root graph level returns `Err(E-GRAPH-015 NoParentGraph)`.
- A `Command` submitted to a non-interrupted run (status `queued`, `in_progress`, `completed`,
  `failed`, `cancelled`, or `summary_halt`) returns `Err(E-GRAPH-002 NoActiveInterrupt)` (see BC-2.05.005).

## Edge Cases

### EC-001: Command with both resume and goto
**Scenario:** `Command(resume="yes", goto="escalation_node")` submitted. The interrupted
node re-executes; after it completes, routing goes to `escalation_node` rather than
following the normal conditional edge.
**Expected behavior:** `resume="yes"` is delivered to the first un-filled FIFO slot;
upon node completion, `goto` forces routing to `escalation_node`. Both fields are
independent and are applied in the correct phase.

### EC-002: Command(resume={interrupt_id: value}) targeted form
**Scenario:** Two nodes A and B both interrupted in the same super-step, each with an
`interrupt_id`. Caller submits `Command(resume={id_A: "approve_a"})`.
**Expected behavior:** Only node A's scratchpad receives `"approve_a"`. Node B remains
halted awaiting its own resume. The `id_A` targeting prevents cross-contamination.

### EC-003: Tool returns Command(goto="another_node")
**Scenario:** A tool function (not a node) returns `Command(goto="override_node")`.
**Expected behavior:** The graph processes the Command as a routing directive; routing
is forced to `override_node` for the next step. This is the tool-output-mixin behavior.

### EC-004: Command(resume=value) submitted when run is already completed
**Scenario:** A run completed normally; caller mistakenly submits `Command(resume="late")`.
**Expected behavior:** `Err(E-GRAPH-002 NoActiveInterrupt)` returned; run state is not
modified (see BC-2.05.005).

### EC-005: Command.PARENT submitted at root graph
**Scenario:** No subgraph context; `Command(graph=Command.PARENT, resume="x")` submitted.
**Expected behavior:** `Err(E-GRAPH-015 NoParentGraph)` — there is no parent to escape to.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Interrupted run; `Command(resume="approved")` submitted | Node re-executes; `interrupt()` returns `"approved"`; run proceeds to next step | Happy path — standard programmatic resume |
| TV-002 | `Command(resume="yes", update={"status": "approved"})` | Node gets `"yes"` from interrupt(); `status` channel updated to `"approved"` before re-execution | Compound command with state side-load |
| TV-003 | `Command(resume="ok", goto="audit_log_node")` | After node completes, routing forced to `audit_log_node` regardless of conditional edges | goto override post-resume routing |
| TV-004 | `Command(resume={interrupt_id_A: "approve_a"})` when two tasks are interrupted | Only task A's scratchpad updated; task B still halted | Targeted FIFO delivery by interrupt_id |
| TV-005 | Tool function returns `Command(resume="delegate_to_human")` | Graph treats it as routing directive; equivalent to caller submitting the same Command | Tool-output-mixin behavior |
| TV-006 | `Command(resume="x")` submitted to non-interrupted run | `Err(E-GRAPH-002 NoActiveInterrupt)` | Guard against stale resume |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-HITL-07 | Command(resume=v) transitions run from interrupted → in_progress → completed/interrupted | Integration test (assert status sequence) | Phase 1 |
| VP-HITL-08 | Command.PARENT at root level returns Err(NoParentGraph), not panic | Unit test | Phase 1 |

## Related BCs

- BC-2.05.001 — depends on: INTERRUPT marker in checkpoint is the precondition for Command acceptance
- BC-2.05.002 — depends on: FIFO scratchpad populated by Command is the contract BC-2.05.002 defines
- BC-2.05.003 — depends on: Command triggers node re-execution from start as specified by BC-2.05.003
- BC-2.05.005 — composes with: Command on empty queue → Err(NoActiveInterrupt) is specified in BC-2.05.005
- BC-2.10.004 — related to: budget escalation submits a Command to HITL; this BC specifies the receiving contract

## Architecture Anchors

- `ferrochain-graph/src/types.rs` — `Command { resume, update, goto, graph }` struct + `Command.PARENT` constant
- `ferrochain-graph/src/scheduler.rs` (`graph::scheduler`) — `_suppress_interrupt` path that consumes Command fields

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-HITL-07, VP-HITL-08

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-006 |
| Capability Anchor Justification | CAP-006 ("HITL Interrupt / Resume with FIFO Resume-Value Delivery") per capabilities-p0.md §CAP-006 — the capability grounding explicitly names "Command(resume=value) API" as one of the four HITL primitives mandated by CONFLICT-3/D17-Q2 |
| L2 Domain Invariants | DI-003 (HITL FIFO Resume-Value Delivery) |
| D17 Commitment | D17-Q2 — HITL contract as Phase-1 BC |
| CONFLICT Reference | CONFLICT-3 (adk-rust has no Command type and no resume-value injection path; Command is a ferrochain-original implementation of the LangGraph contract) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-graph |
