---
document_type: behavioral-contract
level: L3
bc_id: BC-2.06.004
version: "1.4"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-06
capability: CAP-034
crate: pregolya-graph
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 streaming event taxonomy extension, event 13 tool_approval_request."
  - "1.1 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
  - "1.2 (BURST-315/F-A1/2026-08-17): Remove spurious ADR-019-rolling-context-compaction.md from traces_to and inputs — copy-paste residue; ADR-019 governs compaction (SS-07), which is disjoint from the per-tool-call approval hook (CAP-034). ADR-018 is the correct sole architectural input. Symmetric with the BC-2.06.006 burst-285 ADR-019 purge."
  - "1.3 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.24 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.4 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-034
  - architecture/decisions/ADR-018-per-tool-call-approval-hook.md
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-018-per-tool-call-approval-hook.md
input-hash: "2dc86b0"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.06.004: `tool_approval_request` StreamEvent (Event 13) — Payload; Emission Timing; Causal Ordering Before Interrupt

## Description

`StreamEvent::ToolApprovalRequest` is the 13th variant in the streaming event taxonomy
(BC-2.06.001 12-variant base + ADR-018 Decision 5). It is emitted by the graph engine when
`pre_tool_dispatch` receives `PreToolDecision::PendingHumanApproval` from the configured
hook — BEFORE the internal `interrupt()` call is issued. The event carries the tool
identification, the pending approval context, and the run ID so that stream consumers
(e.g., a CLI or IDE) can surface a human-approval dialog without polling the run status.
This event is a notification only; the actual suspension occurs via BC-2.05.001 interrupt
machinery after the event is emitted.

## Preconditions

1. {PRE-001} A graph run is executing and `GraphConfig.pre_tool_hook` is configured with a hook that
   returns `PendingHumanApproval`.
2. {PRE-002} The graph scheduler has called `pre_tool_dispatch` and received
   `PreToolDecision::PendingHumanApproval { prompt }`.
3. {PRE-003} The run is in an executing (not yet interrupted) state at the moment of emission.

## Postconditions

1. {PC-001} **Emission:** Before issuing `interrupt(ToolApprovalRequest { ... })`, the engine emits
   `StreamEvent::ToolApprovalRequest` with the following payload:
   ```json
   {
     "run_id":     "<run-uuid>",
     "tool_name":  "<tool name string>",
     "tool_args":  { ... },
     "action_risk": "<tier string | null>",
     "prompt":     "<optional prompt string | null>"
   }
   ```
   - `tool_name`: the tool's registered name.
   - `tool_args`: the original JSON args (before any Edit modification, since PendingHumanApproval
     means no Edit was applied yet).
   - `action_risk`: the string representation of `ActionRisk` tier if annotated; `null` if not.
   - `prompt`: the `Option<String>` from `PendingHumanApproval`; `null` if `None`.
2. {PC-002} **Causal ordering:** `StreamEvent::ToolApprovalRequest` is emitted BEFORE the run transitions
   to `interrupted` state. Stream consumers receive the event while the run is still in-flight,
   enabling them to surface the approval dialog before the status poll returns `interrupted`.
3. {PC-003} **Exactly once per `PendingHumanApproval` return:** One `ToolApprovalRequest` event is
   emitted per hook decision that returns `PendingHumanApproval`. If the run is interrupted
   and resumed multiple times for the same tool (no retry involved), exactly one event is
   emitted per suspension.
4. {PC-004} **No emission on Approve, Deny, or Edit:** `StreamEvent::ToolApprovalRequest` is ONLY
   emitted when `PendingHumanApproval` is returned. The other three decision variants do not
   produce this event.

## Invariants

- {INV-001} Emission precedes interrupt: the streaming channel receives `ToolApprovalRequest` before
  the checkpoint is written with the `interrupted` state. This is a happens-before guarantee,
  not a wall-clock guarantee.
- {INV-002} `tool_args` in the event payload matches the args presented to `pre_invoke` (original args
  before any potential Edit). This ensures the stream consumer sees exactly what the hook saw.
- {INV-003} `StreamEvent` variants are typed enum members (BC-2.06.001 Invariant): `ToolApprovalRequest`
  is a first-class enum variant, not a stringly-typed dynamic event.
- {INV-004} **DI-014:** The event payload must not be silently dropped. If the stream channel is full
  or the consumer is disconnected, the emit attempt must complete (fire-and-forget allowed per
  streaming semantics) but must not panic or block the engine.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Hook returns Deny (not PendingHumanApproval) | No `ToolApprovalRequest` event emitted |
| EC-002 | Hook returns PendingHumanApproval with no prompt (`None`) | Event emitted with `"prompt": null` |
| EC-003 | Stream consumer is disconnected before event arrives | Event dropped (fire-and-forget); engine does NOT block; interrupt() still issued |
| EC-004 | Tool has no `#[tool(action_risk = ...)]` annotation | Event emitted with `"action_risk": null` |
| EC-005 | Two sequential tool calls both return PendingHumanApproval | Two `ToolApprovalRequest` events emitted in order; FIFO interrupt delivery per BC-2.05.002 |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | Hook returns PendingHumanApproval for `bash` tool with args `{"command": "rm -rf /"}`, action_risk High | Stream contains `ToolApprovalRequest { run_id: ..., tool_name: "bash", tool_args: {"command": "rm -rf /"}, action_risk: "High", prompt: null }` BEFORE interrupted status | happy-path |
| TV-002 | Hook returns Approve for same tool | No `ToolApprovalRequest` event in stream | no-event-on-approve |
| TV-003 | PendingHumanApproval with prompt `"Are you sure?"` | `ToolApprovalRequest { ..., "prompt": "Are you sure?" }` | prompt present |
| TV-004 | Tool has no action_risk annotation | `ToolApprovalRequest { ..., "action_risk": null }` | null action_risk |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.06.004-A | ToolApprovalRequest emitted before interrupt() is issued (causal ordering) | Integration test: collect stream events; assert ToolApprovalRequest arrives before run.status == "interrupted" |
| VP-2.06.004-B | No ToolApprovalRequest event on Approve/Deny/Edit decisions | Integration test: configure hooks with each decision; assert no ToolApprovalRequest in collected events |

## Related BCs

- BC-2.06.001 — extends: 12-variant event taxonomy (this adds event 13)
- BC-2.06.005 — composes with: tool_approval_resolved (event 14) — emitted on resume
- BC-2.05.007 — depends on: PendingHumanApproval decision triggers this event
- BC-2.05.008 — related to: skip-hook-on-resume invariant (resume → BC-2.06.005)

## Architecture Anchors

- `architecture/decisions/ADR-018-per-tool-call-approval-hook.md` — Decision 5 (tool_approval_request event, payload fields)
- `architecture/module-decomposition.md` — SS-06, `graph::event_emitter (pregolya-graph/src/event_emitter.rs)`

## Story Anchor

S-1.24

## VP Anchors

- VP-2.06.004-A
- VP-2.06.004-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-034 |
| Capability Anchor Justification | CAP-034 ("Per-Tool-Call Interactive Approval Hook (PreToolCallHook / PreToolDecision)") per capabilities-p1-p2.md §CAP-034 — this BC specifies the tool_approval_request streaming event (13th variant) mandated by CAP-034's "Two new streaming events" PO BC obligation, enabling stream consumers to surface approval dialogs when PendingHumanApproval is returned |
| L2 Domain Invariants | DI-014 (Error Propagation — event payload not silently dropped; fire-and-forget allowed but must not panic or block) |
| Architecture Authority | ADR-018 Decision 5 (streaming event, payload schema) |
| Binding Decisions | D23 (per-tool-call approval hook mandate; streaming taxonomy 12→14) |
| VP Registration | VP-2.06.004-A/B (integration tests) |
| Module | pregolya-graph / streaming |
| Priority | P1 |
| Wave | 1 |
| Test Types | integration |
