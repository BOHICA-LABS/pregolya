---
document_type: domain-spec-section
level: L2
section: events
version: "1.0"
status: active
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "96a97c892cfd894c1e3b2d9df10121c70d1b282157e5d6d8dcb5a139c887f694"
traces_to: L2-INDEX.md
decisions: [D11, D13, D17]
---

# Domain Events (Processing Stages)

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

For this pipeline-oriented framework, domain events are the observable transitions during
graph execution. All events carry `run_id` and `parent_ids` for correlation.

---

## Execution Lifecycle Events

### RunCreated
A new Run is registered for an Assistant + Thread pair.
- **Trigger:** `POST /threads/{thread_id}/runs`
- **Preconditions:** Thread exists; Assistant exists; caller authenticated
- **Outcome:** Run in `queued` status; config resolved; execution scheduled

### RunStarted
Graph execution engine begins processing a Run.
- **Trigger:** Run dequeued from execution scheduler
- **Preconditions:** Run in `queued`; checkpoint store accessible
- **Outcome:** Run in `in_progress`; prior checkpoint loaded (or empty state initialized)
- **Stream event:** `run_start {run_id, assistant_id, config}`

### SuperStepStarted
A BSP execution round begins with a set of PregelTasks.
- **Trigger:** Engine schedules tasks from the current graph frontier
- **Preconditions:** GraphState valid; at least one node in the frontier
- **Outcome:** PregelTasks submitted for concurrent execution
- **Note:** This is the unit of atomicity; DI-002 requires per-task put_writes before next step.

### NodeExecuted
A single Node's Runnable completed within a super-step.
- **Trigger:** Node Runnable returns or streams its output
- **Preconditions:** Node scheduled in current super-step
- **Outcome:** PendingWrites produced; put_writes called (DI-002)
- **Stream events:** `node_start`, `node_stream` (per token), `node_end`

### ReducersApplied
All channel reducers applied to the accumulated PendingWrites of the super-step.
- **Trigger:** All PregelTasks in the super-step complete
- **Preconditions:** No in-flight tasks remain for this super-step
- **Outcome:** New GraphState produced; applied in deterministic task-identity order (DI-001)
- **Invariant check:** Concurrent LastValue writes → InvalidUpdateError before this stage

### CheckpointWritten
A new Checkpoint stored to the CheckpointStore at a super-step boundary.
- **Trigger:** ReducersApplied completes; sync-default durability tier
- **Preconditions:** GraphState valid; CheckpointStore writable
- **Outcome:** Checkpoint persisted with monotonic ID (DI-004); parent pointer set

### InterruptRaised
Graph execution suspended at a node boundary awaiting a ResumeValue.
- **Trigger:** Node calls `interrupt()` or graph meets an interrupt edge condition
- **Preconditions:** Run in `in_progress`
- **Outcome:** Run transitions to `interrupted`; InterruptRecord stored durably; scratchpad saved
- **Stream event:** `interrupt_raised {run_id, node_name, scratchpad?}`

### ResumeValueReceived
An external actor delivers a ResumeValue for a pending Interrupt.
- **Trigger:** `POST /threads/{thread_id}/runs/{run_id}/resume`
- **Preconditions:** Run in `interrupted`; matching interrupt exists
- **Outcome:** ResumeValue enqueued FIFO (DI-003); Run transitions back to `in_progress`

### RunCompleted
Graph execution reached a terminal node or interrupt with no more work.
- **Trigger:** Graph frontier is empty and no interrupts pending
- **Preconditions:** Run in `in_progress`
- **Outcome:** Run in `completed`; final GraphState in last Checkpoint
- **Stream event:** `run_end {run_id, status, final_output?}`

---

## Tool and Model Events

### ToolInvoked
A Tool Runnable was called with a ToolUse ContentBlock.
- **Trigger:** Model output contains a tool_use block; execution engine dispatches
- **Preconditions:** Tool registered; policy allows invocation
- **Outcome:** ToolResult ContentBlock produced; GuardrailHook fired on result (DI-012)
- **Stream events:** `tool_start`, `tool_stream` (for streaming tools), `tool_end`

### GuardrailChecked
A GuardrailHook evaluated content at an ingress boundary.
- **Trigger:** ToolResult received; RAG chunk retrieved; memory returned
- **Preconditions:** GuardrailHook registered for this IngressBoundary
- **Outcome:** Accept (content passes into model context), Reject (content replaced by error), or Redact

### BudgetEvaluated
A BudgetPolicy evaluated a token/cost tally for the current Run.
- **Trigger:** After each model call; after each tool invocation
- **Preconditions:** BudgetPolicy configured in RunConfig
- **Outcome:** Allow (continue), Escalate (raise HITL interrupt), or Deny (halt run)
- **EvidenceJournal:** Entry appended with outcome (BC-2.10.002: append-only journal)

### StreamEventEmitted
A typed streaming event was emitted by the execution engine.
- **Trigger:** Any phase transition (run/step/node/tool start|stream|end)
- **Outcome:** Delivered to all active stream subscribers; identical content delivered to unary callers (DI-011)

---

## Server Lifecycle Events

### CronFired
A CronSchedule triggered a new Run.
- **Trigger:** Cron schedule expression matches current time
- **Outcome:** New Run created with fresh session (no prior thread context unless configured)

### ThreadCreated / AssistantCreated
Administrative creation events; not execution events.
- **Trigger:** API calls `POST /threads` or `POST /assistants`

---

## Event Ordering Rules

1. `RunStarted` before any `SuperStepStarted` in the same Run.
2. `SuperStepStarted` before any `NodeExecuted` in the same super-step.
3. All `NodeExecuted` events before `ReducersApplied` in the same super-step.
4. `ReducersApplied` before `CheckpointWritten`.
5. `CheckpointWritten` before next `SuperStepStarted`.
6. `InterruptRaised` terminates the current super-step chain until `ResumeValueReceived`.
