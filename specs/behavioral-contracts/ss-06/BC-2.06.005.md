---
document_type: behavioral-contract
level: L3
bc_id: BC-2.06.005
version: "1.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-06
capability: CAP-034
crate: ferrochain-graph
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.2 (F-P142-03, burst-242, 2026-07-23): Sweep Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority and F-P120-01 adjudication. H1 title, Description, PC-2, PC-4, TV-001/002/003 updated. Zero Command:: enum-variant residue remains in live body text."
  - "1.1 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
  - "1.0 (D23/2026-07-22): Initial BC — D23 streaming event taxonomy extension, event 14 tool_approval_resolved."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-034
  - architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - architecture/decisions/ADR-019-rolling-context-compaction.md
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - .factory/specs/architecture/decisions/ADR-019-rolling-context-compaction.md
input-hash: "8c63ca4"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.06.005: `tool_approval_resolved` StreamEvent (Event 14) — Payload; Emission on Command(resume=…); Decision Outcome

## Description

`StreamEvent::ToolApprovalResolved` is the 14th variant in the streaming event taxonomy.
It is emitted when a `Command(resume=PreToolDecision)` arrives for a run that is suspended
at a `ToolApprovalRequest` interrupt. The event carries the run ID, tool name, and the
resolved decision so that stream consumers can update their UI (e.g., mark the approval
dialog as resolved). The event is emitted AFTER the run's interrupt state is consumed and
BEFORE the decision is applied (tool invocation or ToolOutput::Error construction). This
event always pairs with a prior `BC-2.06.004 tool_approval_request` event for the same
`run_id` and `tool_name`.

## Preconditions

1. A graph run is in `interrupted` state with a pending `ToolApprovalRequest` interrupt.
2. `Command(resume=PreToolDecision)` is delivered (via the API or programmatically).
3. The `PreToolDecision` is one of: `Approve`, `Deny { reason }`, or `Edit { modified_args }`.

## Postconditions

1. **Emission:** The engine emits `StreamEvent::ToolApprovalResolved` with the following
   payload immediately after consuming the interrupt, before applying the decision:
   ```json
   {
     "run_id":    "<run-uuid>",
     "tool_name": "<tool name string>",
     "decision":  "Approve" | "Deny" | "Edit",
     "reason":    "<reason string | null>",
     "modified_args": { ... } | null
   }
   ```
   - `decision`: the variant name of the `PreToolDecision` that was delivered.
   - `reason`: populated for `Deny { reason }`; `null` for Approve and Edit.
   - `modified_args`: populated for `Edit { modified_args }`; `null` for Approve and Deny.
2. **Pairing with BC-2.06.004:** Every `tool_approval_resolved` event corresponds to a
   prior `tool_approval_request` event for the same `run_id` and `tool_name`.
3. **Causal ordering:** `tool_approval_resolved` is emitted before the resolved decision is
   applied (i.e., before `tool.invoke(args)` is called for Approve/Edit, or before
   `ToolOutput::Error` is constructed for Deny). Stream consumers see the resolution event
   before any downstream effects.
4. **No emission without prior request:** If `Command(resume=…)` arrives for a run that has
   no pending `ToolApprovalRequest` interrupt, it is handled by BC-2.05.004 (standard
   resume mechanics); no `tool_approval_resolved` event is emitted.

## Invariants

- `tool_approval_resolved` is emitted exactly once per `tool_approval_request` / resume
  cycle. It is never emitted without a corresponding prior `tool_approval_request`.
- The `decision` field reflects the delivered `PreToolDecision` variant faithfully —
  it is not the outcome of hook re-evaluation (skip-hook-on-resume invariant, BC-2.05.008).
- `StreamEvent` variants are typed enum members (BC-2.06.001 invariant).
- **DI-014:** The event payload must not be silently dropped; fire-and-forget semantics
  apply as for all streaming events.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Resume with Approve | Event: `{ "decision": "Approve", "reason": null, "modified_args": null }` |
| EC-002 | Resume with Deny | Event: `{ "decision": "Deny", "reason": "<reason>", "modified_args": null }` |
| EC-003 | Resume with Edit | Event: `{ "decision": "Edit", "reason": null, "modified_args": { ... } }` |
| EC-004 | Stream consumer disconnected before event | Event dropped; engine does not block; decision applied normally |
| EC-005 | Two queued ToolApprovalRequest interrupts; first resume delivered | Only one `tool_approval_resolved` emitted (for the first); second waits for its own resume |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | Tool suspended at PendingHumanApproval; `Command(resume=Approve)` delivered | Stream: `ToolApprovalResolved { ..., "decision": "Approve" }` BEFORE tool invocation | happy-path (approve) |
| TV-002 | `Command(resume=Deny { reason: "blocked" })` | Stream: `ToolApprovalResolved { ..., "decision": "Deny", "reason": "blocked" }` | deny resolved |
| TV-003 | `Command(resume=Edit { modified_args: {"cmd": "ls"} })` | Stream: `ToolApprovalResolved { ..., "decision": "Edit", "modified_args": {"cmd": "ls"} }` | edit resolved |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.06.005-A | tool_approval_resolved emitted before decision applied (causal ordering) | Integration test: collect stream events; assert ToolApprovalResolved arrives before next ToolStart/ToolEnd or stream close |
| VP-2.06.005-B | Every tool_approval_resolved pairs with a prior tool_approval_request | Integration test: collect full stream; verify (request, resolved) pair for same run_id + tool_name |

## Related BCs

- BC-2.06.001 — extends: 12-variant event taxonomy (this adds event 14)
- BC-2.06.004 — pairs with: tool_approval_request (event 13) — every resolved has a prior request
- BC-2.05.007 — depends on: decision application rules (PC-1 through PC-3) executed after this event
- BC-2.05.008 — depends on: skip-hook-on-resume invariant applies here (decision applied without re-calling pre_invoke)

## Architecture Anchors

- `architecture/decisions/ADR-018-per-tool-call-approval-hook.md` — Decision 5 (tool_approval_resolved event, complementary to tool_approval_request)
- `architecture/module-decomposition.md` — SS-06, `graph::event_emitter (ferrochain-graph/src/event_emitter.rs)`

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-06 extension story]_

## VP Anchors

- VP-2.06.005-A
- VP-2.06.005-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-034 |
| Capability Anchor Justification | CAP-034 ("Per-Tool-Call Interactive Approval Hook (PreToolCallHook / PreToolDecision)") per capabilities-p1-p2.md §CAP-034 — this BC specifies the tool_approval_resolved streaming event (14th variant) mandated by CAP-034's "Two new streaming events" PO BC obligation, completing the request/resolved event pair for pre-tool-call approval |
| L2 Domain Invariants | DI-014 (Error Propagation — event payload not silently dropped; fire-and-forget semantics; engine does not block) |
| Architecture Authority | ADR-018 Decision 5 (complementary tool_approval_resolved event) |
| Binding Decisions | D23 (per-tool-call approval hook mandate; streaming taxonomy 12→14) |
| VP Registration | VP-2.06.005-A/B (integration tests) |
| Module | ferrochain-graph / streaming |
| Priority | P1 |
| Wave | 1 |
| Test Types | integration |
