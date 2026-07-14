---
document_type: adr
level: L3
adr_id: "001"
slug: graph-execution-model
title: "Graph Execution Model: BSP Channel Versioning vs Hybrid Orchestrator-Actor"
status: accepted
gate: D9-PASSED
gate_note: "D9 human gate passed 2026-07-14. Alternative B (Hybrid orchestrator-loop + actor-scheduler) selected per D11.1 steering."
producer: architect
timestamp: 2026-07-14T14:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D9, D11, D17]
supersedes: []
changelog:
  - "rev-1 (ADV-P1D-PASS-36): F-P36-02 adjudicate interrupt-queue check timing. Line ~101 'after reduction' retired — corrected to 'at the Collecting→Reducing transition' to match line 163 and LangGraph HITL semantics. Consequences section expanded with precise nuanced rule: completed-sibling writes are reduced and checkpointed; interrupted node's in-progress writes are discarded; only the INTERRUPT marker is written for the interrupted task. Both references now agree on Collecting→Reducing as the detection point."
---

# ADR-001: Graph Execution Model

**Status:** ACCEPTED — D9 gate passed 2026-07-14. **Decision: Alternative B (Hybrid orchestrator-loop + actor-scheduler).**

**Context:** ferrochain-graph is the highest-complexity, highest-risk crate in the workspace.
D9 mandated ≥2 alternatives presented to human before ADR lock. Human selected Alternative B
per D11.1 steering (orchestrator-loop + actor-scheduler synthesis). Alternative A is retained
below as the rejected alternative with rationale.

**Human Decision Record:** Alternative B selected 2026-07-14. Rationale accepted verbatim:
budget governance (D17-Q4) integrates as an orchestrator transition concern; crash isolation
is cleaner in the HYBRID model; type-state machine pattern bounds the complexity.

---

## Alternative A: LangGraph-Faithful BSP with Channel Versioning

### Description

This alternative is a faithful Rust port of LangGraph's internal `Pregel` execution loop.
Each super-step maintains a `versions_seen: HashMap<NodeId, Version>` map per running task.
After each super-step, channel writes are aggregated. A task only runs if the max version
of any input channel exceeds the version it last saw.

Concurrency model: tasks within a super-step dispatch as concurrent `tokio::spawn` futures.
The scheduler collects all outputs via a `JoinSet<(TaskId, Vec<ChannelUpdate>)>`, waits
for all to complete, then applies reducers in task-identity-sorted order (per DI-001).

HITL interrupt model: after all tasks in a super-step complete, the scheduler checks the
interrupt queue before starting the next super-step. If an interrupt is registered for
the current node, the graph suspends. Resume value is enqueued FIFO; the interrupted
node re-runs from the start of the next super-step with the dequeued value in scratchpad.

Checkpoint model: `put_writes` is called per-task as each `JoinSet` item completes, before
the super-step transition. This satisfies DI-002 (sync durability default).

### Pros

| Factor | Assessment |
|--------|-----------|
| Python parity | Highest fidelity — `versions_seen` maps directly from `pregel.py` |
| Golden-vector tests | Easier to derive test cases from Python reference behavior |
| Invariant clarity | All invariants (DI-001, DI-002, DI-003) map to explicit Pregel code paths |
| VP-001 feasibility | `reduce(sort_by_task_id(tasks))` is directly provable with Kani |
| Kani scope | Reducer stage is naturally pure: `(TaskId, ChannelUpdate) → State` |

### Cons

| Factor | Assessment |
|--------|-----------|
| `versions_seen` memory | O(nodes × super-steps) memory growth for long-running graphs |
| Async Rust idiom fit | Python's async event loop maps awkwardly to `JoinSet`; requires careful cancellation handling |
| Type complexity | `versions_seen: HashMap<NodeId, Version>` must be threaded through all super-step state |
| Budget governance | Budget checks must be woven into the `JoinSet` collection loop — not a clean separation |
| Scheduler extensibility | Adding new dispatch modes (priority, rate-limit) requires modifying the core loop |

### Key Implementation Risk

`JoinSet` cancellation: if a task panics or its future is dropped mid-super-step, partial
channel writes may reach `put_writes` before the super-step is complete. Requires careful
handling to maintain DI-002 (crash recovery) when the scheduler itself crashes. Mitigation:
the outer `GraphConfig::interrupt_before` mechanism must clear the in-flight write set before
the scheduler crashes can be surfaced as completed tasks.

---

## Alternative B: Hybrid Orchestrator-Loop + Actor-Scheduler (D11.1)

### Description

An outer **orchestrator loop** owns the super-step lifecycle. Each super-step is a
discrete state machine transition: `Idle → Dispatching → Collecting → Reducing → Checkpointing → Idle`.
Within `Dispatching`, tasks are sent as messages to an **actor scheduler** (a Tokio actor
implemented as a select loop over MPSC channels). Each task actor sends its output back
to the scheduler on completion. The scheduler notifies the orchestrator loop when all
actors complete.

The orchestrator loop is responsible for:
1. Selecting which nodes to run this super-step (based on channel versions).
2. Dispatching tasks to the actor scheduler.
3. Collecting outputs from the scheduler.
4. Applying reducers in task-identity-sorted order (DI-001).
5. Calling `put_writes` for each completed task before declaring the super-step done (DI-002).
6. Checking the interrupt queue at the Collecting→Reducing transition (DI-003).
7. Evaluating budget policy (SS-10) between super-steps.

The actor scheduler is a Tokio task that owns a `HashMap<TaskId, JoinHandle<Output>>`.
It receives `Dispatch(task_id, future)` messages and sends back `Completed(task_id, output)`.
The scheduler has no knowledge of graph semantics — it is a bounded concurrency manager.

### Pros

| Factor | Assessment |
|--------|-----------|
| Architectural clarity | Orchestrator owns all state transitions; actor scheduler is a generic concurrency primitive |
| Budget governance fit | Budget checks happen cleanly between orchestrator state transitions (D17-Q4) |
| Extensibility | New dispatch modes (priority scheduling, rate limiting) extend the scheduler without touching graph logic |
| Crash isolation | Scheduler crash is isolated from orchestrator loop state; partially-completed tasks are tracked in the orchestrator's in-flight set |
| Idiomatic Rust | MPSC message-passing is idiomatic async Rust; avoids JoinSet cancellation complexity |
| Test isolation | Orchestrator loop can be unit-tested with a mock scheduler actor (inject as trait object) |
| VP-001 feasibility | Reducer application is in a pure sub-function called by the orchestrator; identical Kani harness applies |

### Cons

| Factor | Assessment |
|--------|-----------|
| Implementation complexity | Two separate components (orchestrator + actor scheduler) vs one loop |
| Python divergence | `versions_seen` map is implicit in the orchestrator channel-version tracking; harder to trace to Python reference |
| Message-passing overhead | Actor message round-trips add latency vs direct JoinSet polling (estimated < 1μs per task; negligible vs NFR-001) |
| Larger surface area | Orchestrator↔scheduler protocol (Dispatch/Completed/Cancel messages) must be verified; not in Python reference |
| HITL model subtlety | Interrupt suspension is an orchestrator loop state transition, not a JoinSet cancellation — requires careful state machine design |

### Key Implementation Risk

Orchestrator state machine completeness: the orchestrator loop has 6 states. If any
transition is missing (e.g., `Dispatching → Idle` on panic), the loop can deadlock.
Mitigation: implement the orchestrator as a type-state machine using Rust's enum-based
state pattern, making illegal transitions unrepresentable. Proptest fuzzes the state
machine over random task-completion sequences.

---

## Decision: ACCEPTED — Alternative B (Hybrid Orchestrator-Loop + Actor-Scheduler)

**D9 gate passed 2026-07-14.** Human selected Alternative B per D11.1 steering.
Alternative A (LangGraph-faithful BSP) is REJECTED. Rationale:

1. D11.1 explicitly steered toward HYBRID (orchestrator-loop + actor-scheduler).
2. Budget governance (D17-Q4) integrates cleanly as an orchestrator transition concern (not woven into a JoinSet collection loop).
3. Crash isolation is architecturally cleaner: scheduler crash is isolated from orchestrator state.
4. Type-state machine pattern bounds complexity and prevents illegal state transitions.
5. VP-001 Kani proof applies equally to both alternatives (pure reducer function is identical).

**Alternative A REJECTED because:** `versions_seen` memory growth for Domain B long-running
graphs; JoinSet cancellation complexity under partial super-step failure; budget governance
integration is awkward in the collection loop; Python event-loop idiom doesn't map cleanly
to Rust JoinSet semantics.

## Consequences

- `graph::scheduler` contains both the orchestrator state machine and the actor scheduler.
- Orchestrator state machine: `Idle → Dispatching → Collecting → Reducing → Checkpointing → Idle` (enum-based type-state).
- Actor scheduler: Tokio MPSC select loop; receives `Dispatch(task_id, future)`, sends `Completed(task_id, output)`.
- Budget governance as orchestrator transition hook between Reducing and Checkpointing states.
- `graph::bsp_engine` contains the pure reducer function (VP-001 Kani target).
- HITL interrupt: orchestrator checks interrupt queue at the Collecting→Reducing transition (DI-003). Precise rule: when the orchestrator detects an INTERRUPT marker among the collected task outputs, it (1) runs reducers on outputs from COMPLETED sibling tasks only — the interrupted node contributes no state delta; (2) writes the INTERRUPT marker as the interrupted task's sole output; (3) proceeds through Checkpointing so the reduced sibling state and the INTERRUPT marker are durably persisted together; (4) suspends after Checkpointing rather than initiating the next Idle→Dispatching cycle. The interrupted node's in-progress writes from the halted execution attempt are NOT included in the reduction or checkpoint state. On resume (BC-2.05.003), the interrupted node re-executes from its function entry — sibling writes from the interrupted super-step are already checkpointed and those nodes do not re-run.
- `put_writes` called per completed task in the Collecting phase (DI-002 sync durability default).
