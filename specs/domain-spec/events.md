---
document_type: domain-spec-section
level: L2
section: events
version: "1.9"
status: active
producer: business-analyst
timestamp: 2026-07-22T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "e978d8d"
traces_to: L2-INDEX.md
decisions: [D11, D13, D17, D18, D21, D23]
changelog:
  - "1.9 (2026-07-22): Fix burst 242 BA residual sweep — Command notation: 3 enum-variant form occurrences of `Command::Resume(PreToolDecision)` corrected to struct kwarg form `Command(resume=PreToolDecision)` per BC-2.05.004/F-P120-01 adjudication. Sites: §ToolApprovalResolved description (line 109), §ToolApprovalResolved Trigger (line 110), §StreamEventEmitted Trigger (line 149). TD-VSDD-060 sweep: zero Command:: enum-form occurrences remain in this file's body text."
  - "1.8 (F-P139-01/02, fix burst 239, 2026-07-23): §CompactionExecuted Outcome: BC-2.04.001 immutability citation corrected to BC-2.04.001 Inv-5 (checkpoint append-only — records never deleted or mutated in place). §CompactionExecuted EvidenceJournal entry fields: tokens_remaining_after type corrected from u64 to Option<i64> to match BC-2.06.006 PC-1 / BC-2.06.001 PC2 / interface-definitions §BudgetInfo (None when no token ceiling; negative on Deny). TD-VSDD-060 sweep: no other stale BC-2.04.001 immutability citations or tokens_remaining_after: u64 renderings found in file."
  - "1.7 (F-P135-06, fix burst 235, 2026-07-22): StreamEventEmitted Trigger: D23 stream events 13-15 added — tool_approval_request (BC-2.06.004), tool_approval_resolved (BC-2.06.005), compaction_event (BC-2.06.006); StreamEvent taxonomy updated to 15 variants (12-variant base + 3 D23). Domain events added: CompactionExecuted (BC-2.10.006, after CheckpointWritten — mid-run window replacement + EvidenceJournal); ToolApprovalRaised + ToolApprovalResolved (BC-2.05.007/008, after ResumeValueReceived — PreToolCallHook suspend/resume cycle). Ordering rules 7-8 added. decisions: D21 added (RagChunk/MemoryItem ingress types already referenced in v1.5); D23 added (scope driver for all D23 additions)."
  - "1.0 (initial): base events authored."
  - "1.1 (ADV-P1D-PASS-29): F-P29-06 — relabel InterruptRaised Stream event field: `interrupt_raised` is an internal domain event; its SSE wire surface is the {\"__interrupt__\": [...]} JSON envelope (BC-2.12.007 EC-003, BC-2.05.001), NOT a StreamEvent variant. Decision: do not add interrupt variant to StreamEvent enum — no L2/BC evidence one was intended."
  - "1.2 (2026-07-17): F-P94-fix-burst — BudgetEvaluated.Outcome: correct monolithic 'Deny (halt run)' to per-on_ceiling dispatch; PolicyDecision::Deny does not unconditionally halt — engine dispatches per BudgetConfig::on_ceiling (Halt → graceful halt; Escalate → HITL interrupt; Summarize → final summarize call → summary_halt). Canon: D18-P93-A, interface-definitions v2.33."
  - "1.3 (2026-07-17): F-P99-01 — StreamEventEmitted trigger: extend to include guardrail_decision surface (Fail/Transform only; Pass not streamed); GuardrailChecked: add stream surface line (guardrail_decision metadata-only payload per BC-2.11.005 INV-5, fires before enclosing tool_end); ToolInvoked tool_end: note post-guardrail content semantics. Canon: ADR-006 rev-3, interface-definitions v2.34 §StreamEvent, BC-2.06.001 v1.3."
  - "1.4 (2026-07-17): F-P100-01 — StreamEventEmitted Outcome: removed blanket 'identical content to unary callers' claim; qualified guardrail_decision as stream-observer-only (not delivered to unary callers; DI-011 scoped to execution-path equivalence, not stream-observer equivalence; canon: BC-2.06.003, ADR-006 rev-3). F-P100-03 — GuardrailChecked Outcome: retired Accept/Reject/Redact vocabulary; aligned to canonical Pass/Fail/Transform (GuardrailResult variants per ubiquitous-language-server.md §GuardrailHook v1.2 F-P58-03); Transform explicitly noted as strict superset of redact-only to preserve semantics."
  - "1.5 (2026-07-17): F-P101-01 — GuardrailChecked Stream surface: rewrote unconditional 'fires before the enclosing tool_end' to boundary-qualified ordering; ToolResult fires before enclosing tool_end (tool_call_id present); RagChunk/MemoryItem fire within enclosing NodeStart/NodeEnd window before inference (tool_call_id absent). Sweep: no other unconditional tool_end-ordering or tool_call_id-always-present claims for guardrail_decision found elsewhere in file. Canon: ADR-006 rev-4, BC-2.06.001 v1.3 PC4, BC-2.11.003/004 v1.5."
  - "1.6 (F-P121-01, fix burst 124, 2026-07-19): §ToolInvoked description: 'ToolUse ContentBlock' → 'ContentBlock::ToolCall in an AiMessage' (canonical BC-2.01.001 PC2 variant name). §ToolInvoked outcome: 'ToolResult ContentBlock produced' → 'ToolMessage produced (BC-2.09.002)' per BC-2.09.002 authority. TD-VSDD-060 sweep: only ToolInvoked was the affected domain-event site in this file; both lines fixed."
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
A new Checkpoint stored to the CheckpointSaver at a super-step boundary.
- **Trigger:** ReducersApplied completes; sync-default durability tier
- **Preconditions:** GraphState valid; CheckpointSaver writable
- **Outcome:** Checkpoint persisted with monotonic ID (DI-004); parent pointer set

### CompactionExecuted
BudgetEngine completed a mid-run compaction cycle: active message window replaced, EvidenceJournal updated, stream notified.
- **Trigger:** `CompactionTrigger` condition met after a super-step; `CompactionPolicy::compact()` returned `Ok(CompactionSummary)` (BC-2.10.006)
- **Preconditions:** Run in `in_progress`; between super-steps (compaction CANNOT fire mid-node or during a `PendingHumanApproval` park window — BC-2.10.006 × BC-2.05.007 temporal non-interaction invariant); `BudgetConfig.compaction_trigger != Disabled`
- **Outcome:** `messages[compacted_range]` in ACTIVE conversation window replaced by single `SystemMessage(summary_text)` (mid-run mutation — takes effect immediately; distinct from BC-2.15.006 frozen-snapshot which takes effect at next run start); original checkpoint records NOT deleted (BC-2.04.001 Inv-5 (checkpoint append-only — records never deleted or mutated in place)); `CompactionEvent { compacted_range, summary_token_count, tokens_remaining_after }` appended to `EvidenceJournal` (BC-2.10.001 append-only, step 5); `compaction_event` StreamEvent emitted AFTER checkpoint commit (step 6 post-commit ordering)
- **EvidenceJournal entry fields:** `compacted_range` (`RangeInclusive<usize>`), `summary_token_count` (u64), `tokens_remaining_after` (`Option<i64>` — captured AFTER window replacement; same schema as BC-2.06.006 PC-1 / BC-2.06.001 PC2 / interface-definitions §BudgetInfo; None when no token ceiling configured, negative on Deny)
- **Stream event:** `compaction_event` (event 15) — post-commit; payload: `{ run_id, trigger, compacted_turns: { start, end }, summary_token_count, tokens_remaining_after }` (BC-2.06.006 PC-1)
- **Non-fatal failure paths:** `compact()` error or `put_writes` failure aborts cycle without message-window mutation; no journal entry or stream event emitted; run continues with pre-compaction window (BC-2.10.006 invariants)

### InterruptRaised
Graph execution suspended at a node boundary awaiting a ResumeValue.
- **Trigger:** Node calls `interrupt()` or graph meets an interrupt edge condition
- **Preconditions:** Run in `in_progress`
- **Outcome:** Run transitions to `interrupted`; InterruptRecord stored durably; scratchpad saved
- **Wire surface (domain event — NOT a StreamEvent variant; F-P29-06, ADV-P1D-PASS-29):** When a node calls `interrupt()`, the SSE wire representation is the `{"__interrupt__": [InterruptPayload]}` JSON envelope (BC-2.12.007 EC-003, BC-2.05.001) — not a typed `StreamEvent` variant. `interrupt_raised` was previously listed here as a stream event label; that was incorrect. The interrupt payload is surfaced via the `__interrupt__` envelope and is structurally distinct from the `StreamEvent` enum variants (RunStart/Stream/End, NodeStart/Stream/End, etc.).

### ResumeValueReceived
An external actor delivers a ResumeValue for a pending Interrupt.
- **Trigger:** `POST /threads/{thread_id}/runs/{run_id}/resume`
- **Preconditions:** Run in `interrupted`; matching interrupt exists
- **Outcome:** ResumeValue enqueued FIFO (DI-003); Run transitions back to `in_progress`

### ToolApprovalRaised
A `PreToolCallHook` returned `PendingHumanApproval`; tool dispatch suspended awaiting human decision.
- **Trigger:** `pre_tool_dispatch` receives `PreToolDecision::PendingHumanApproval` from configured hook (BC-2.05.007 PC-4)
- **Preconditions:** Run in `in_progress`; `GraphConfig.pre_tool_hook` configured; hook returned `PendingHumanApproval { prompt }`
- **Outcome:** `ToolApprovalRequest { preview: ToolCallPreview { tool_name, tool_args, action_risk }, prompt }` serialized to checkpoint (msgpack per BC-2.05.008 PC-3 / BC-2.04.002 wire format); run transitions to `interrupted`; `hook.pre_invoke` will NOT be re-called on resume (skip-hook-on-resume invariant, BC-2.05.008)
- **Stream event:** `tool_approval_request` (event 13) — emitted BEFORE the run transitions to `interrupted` (causal ordering per BC-2.06.004 PC-2); payload: `{ run_id, tool_name, tool_args, action_risk, prompt }`. The interrupt payload is surfaced via the `{"__interrupt__": [ToolApprovalRequest]}` envelope (BC-2.05.001 machinery) — analogous to `InterruptRaised` (F-P29-06 pattern); the `tool_approval_request` stream event is the consumer's signal to surface an approval dialog before the status poll returns `interrupted`.

### ToolApprovalResolved
A human (or automation) delivered `Command(resume=PreToolDecision)` for a pending `ToolApprovalRequest` interrupt.
- **Trigger:** `POST /threads/{thread_id}/runs/{run_id}/resume` with `Command(resume=PreToolDecision)` carrying `Approve`, `Deny { reason }`, or `Edit { modified_args }` (BC-2.05.004/2.05.008)
- **Preconditions:** Run in `interrupted`; pending `ToolApprovalRequest` interrupt present in checkpoint (FIFO queue per BC-2.05.002)
- **Outcome:** `hook.pre_invoke` NOT re-called (BC-2.05.008 skip-hook-on-resume — human decision IS the hook decision for this dispatch attempt); delivered `PreToolDecision` applied per BC-2.05.007 PC-1/2/3: `Approve` → tool invoked with original checkpoint args; `Deny { reason }` → `ToolOutput::Error(reason)` (fail-closed, tool not invoked); `Edit { modified_args }` → args replaced then tool invoked (with JSON-object validation); run transitions back to `in_progress`
- **Stream event:** `tool_approval_resolved` (event 14) — emitted AFTER interrupt consumed, BEFORE decision applied (causal ordering per BC-2.06.005 PC-3); payload: `{ run_id, tool_name, decision, reason, modified_args }`. Always pairs with a prior `tool_approval_request` for the same `run_id` + `tool_name`.

### RunCompleted
Graph execution reached a terminal node or interrupt with no more work.
- **Trigger:** Graph frontier is empty and no interrupts pending
- **Preconditions:** Run in `in_progress`
- **Outcome:** Run in `completed`; final GraphState in last Checkpoint
- **Stream event:** `run_end {run_id, status, final_output?}`

---

## Tool and Model Events

### ToolInvoked
A Tool Runnable was called by the execution engine in response to a `ContentBlock::ToolCall` in an AiMessage.
- **Trigger:** Model output contains a `ContentBlock::ToolCall` block; execution engine dispatches
- **Preconditions:** Tool registered; policy allows invocation
- **Outcome:** `ToolMessage` produced (BC-2.09.002); GuardrailHook fired on result content as `IngressContent::ToolResult` before model context entry (DI-012)
- **Stream events:** `tool_start`, `tool_stream` (for streaming tools), `tool_end` (carries post-guardrail ToolResult — content is guardrail-filtered per BC-2.06.001 v1.3; Fail/Transform outcomes emit `guardrail_decision` before `tool_end`)

### GuardrailChecked
A GuardrailHook evaluated content at an ingress boundary.
- **Trigger:** ToolResult received; RAG chunk retrieved; memory returned
- **Preconditions:** GuardrailHook registered for this IngressBoundary
- **Outcome:** Pass (content passes into model context unchanged), Fail (content blocked; replaced by a guardrail-generated error block; carries reason and GuardrailSeverity), or Transform (guardrail rewrites content; sanitized replacement forwarded, original discarded — encompasses redaction, sanitization, and arbitrary content substitution; a strict superset of redact-only)
- **Stream surface:** `guardrail_decision` (Fail/Transform only; metadata-only payload — boundary, decision, reason/severity [Fail only], ingress_id, tool_call_id; zero bytes of rejected content per BC-2.11.005 INV-5; ordering is boundary-dependent: ToolResult fires before the enclosing `tool_end` (tool_call_id present); RagChunk/MemoryItem fire within the enclosing NodeStart/NodeEnd window before inference (tool_call_id absent) — per ADR-006 ordering and BC-2.06.001 PC4)

### BudgetEvaluated
A BudgetPolicy evaluated a token/cost tally for the current Run.
- **Trigger:** After each model call; after each tool invocation
- **Preconditions:** BudgetPolicy configured in RunnableConfig
- **Outcome:** Allow (continue), Escalate (raise HITL interrupt), or Deny (engine dispatches per on_ceiling — halt, HITL escalation, or summarize)
- **EvidenceJournal:** Entry appended with outcome (BC-2.10.002: append-only journal)

### StreamEventEmitted
A typed streaming event was emitted by the execution engine.
- **Trigger:** Any phase transition (run/step/node/tool start|stream|end), guardrail outcome (Fail/Transform — emitted as `guardrail_decision`; Pass is not streamed), pre-tool approval suspension (`tool_approval_request` event 13 — on `PendingHumanApproval`; D23 per BC-2.06.004), pre-tool approval resolution (`tool_approval_resolved` event 14 — on `Command(resume=PreToolDecision)`; D23 per BC-2.06.005), or post-compaction-commit notification (`compaction_event` event 15 — D23 per BC-2.06.006). **StreamEvent taxonomy: 15 variants** (12-variant base per BC-2.06.001 — includes `guardrail_decision` — + events 13/14/15 per D23).
- **Outcome:** Delivered to all active stream subscribers. Execution-lifecycle events have unary-equivalent content (DI-011 execution-path equivalence); `guardrail_decision` is stream-observer-only — not delivered to unary callers, whose guardrail outcomes are observable via error blocks in the final output (BC-2.06.003). `tool_approval_request` and `tool_approval_resolved` are notification-only events (no unary equivalent — approval dialogs are stream-consumer surfaces only; BC-2.06.004/005). `compaction_event` is a post-commit observer notification (not reflected in unary response payload; BC-2.06.006).

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
7. `ToolApprovalRaised` (`tool_approval_request` stream event) emitted before run transitions to `interrupted`; `ToolApprovalResolved` (`tool_approval_resolved` stream event) emitted before the resumed `PreToolDecision` is applied — both precede their downstream state effects (BC-2.06.004/005 causal ordering).
8. `CompactionExecuted` (`compaction_event` stream event) emitted after the compacted checkpoint is durably written — stream consumer sees the event only after the state mutation is committed (BC-2.06.006 PC-2 post-commit ordering); `CompactionExecuted` can only follow a `CheckpointWritten` within the same super-step boundary cycle.
