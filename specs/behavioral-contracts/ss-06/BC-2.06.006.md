---
document_type: behavioral-contract
level: L3
bc_id: BC-2.06.006
version: "1.4"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-06
capability: CAP-035
crate: ferrochain-graph
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-23T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 streaming event taxonomy extension, event 15 compaction_event."
  - "1.1 (burst-234/F-P134-05/2026-07-22): Remove spurious ADR-018 (per-tool-call approval hook) from traces_to and inputs. BC-2.06.006 is compaction_event (event 15); its sole architecture authority is ADR-019 Decision 4. ADR-018 was copy-paste residue from BC-2.06.004/005 (tool_approval streaming events which DO depend on ADR-018). input-hash recomputed after inputs list change: 9c3892a → ee8a02b."
  - "1.2 (burst-236/F-P136-04/2026-07-23): PC1 JSON payload `tokens_remaining_after` type fixed: `<u64>` → `<i64 | null>`. Source is `RunContext.budget_info.tokens_remaining: Option<i64>` (interface-definitions.md §BudgetInfo v2.21). When no token ceiling is configured (OnMessageCount/OnTokenCount triggers fire), `tokens_remaining` is `None` → u64 has no representation; may also be negative (i64) on Deny. Invariants updated to note the `Option<i64>` source type. BC-2.10.006 Step 5 and interface-def §StreamEvent CompactionEvent updated identically (three-site reconciliation F-P136-04)."
  - "1.3 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
  - "1.4 (F-P151-03, burst-252, 2026-07-24): ADR-019 v1.4 adjudicated canon applied. (1) PC1 JSON payload → flat wire shape: `compacted_turns: { start, end }` removed; replaced with `compacted_start: <usize>` + `compacted_end: <usize>` (flat inclusive bounds per interface-definitions.md §Compaction CompactionSummary). (2) `parent_ids: [\"<parent_run_id>\"]` added to PC1 JSON (BC-2.06.002 Inv-2 mandate — every StreamEvent variant carries parent_ids). (3) PC1 field descriptions updated: `compacted_turns`/`CompactionSummary.compacted_range` references replaced with `compacted_start`/`compacted_end` flat-field descriptions (inclusive bounds, slice note). (4) Invariants: add parent_ids mandatory note citing BC-2.06.002 Inv-2. (5) EC-005 + TV-001 + TV-004 updated to flat + parent_ids wire shape."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-035
  - architecture/decisions/ADR-019-rolling-context-compaction.md
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-019-rolling-context-compaction.md
input-hash: "41cc598"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.06.006: `compaction_event` StreamEvent (Event 15) — Payload; Emission After Compaction Completes; Trigger Variant

## Description

`StreamEvent::CompactionEvent` is the 15th variant in the streaming event taxonomy
(BC-2.06.001 12-variant base + 2 from ADR-018 + 1 from ADR-019 Decision 4). It is emitted
by the `BudgetEngine` in `graph::budget` after a compaction cycle completes — after
`CompactionPolicy::compact` returns, the compacted checkpoint state is written, and the
`CompactionEvent` is appended to `EvidenceJournal` (BC-2.10.006). The event gives stream
consumers real-time visibility into the compaction's scope and token impact, enabling the
host to update context-window visualization without polling.

## Preconditions

1. `BudgetConfig.compaction_trigger != CompactionTrigger::Disabled`.
2. The `BudgetEngine` has evaluated the trigger condition after a super-step and determined
   that compaction should fire (watermark crossed, message count exceeded, or token count
   exceeded — per BC-2.10.005).
3. `CompactionPolicy::compact` has returned `Ok(CompactionSummary)`.
4. The compacted checkpoint state has been durably written (the message window replacement
   committed before this event is emitted).

## Postconditions

1. **Emission:** After the compacted state is committed, the engine emits
   `StreamEvent::CompactionEvent` with the following payload:
   ```json
   {
     "run_id":                 "<run-uuid>",
     "parent_ids":             ["<parent_run_id>"],
     "trigger":                "OnWatermark" | "OnMessageCount" | "OnTokenCount",
     "compacted_start":        <usize>,
     "compacted_end":          <usize>,
     "summary_token_count":    <u64>,
     "tokens_remaining_after": <i64 | null>
   }
   ```
   - `parent_ids`: ancestry chain per BC-2.06.002 Inv-2 (MANDATORY on every `StreamEvent`
     variant); `[]` for a top-level run; `["<parent_run_id>"]` for a sub-agent run.
   - `trigger`: the `CompactionTrigger` variant that fired (string representation of the enum
     variant name that caused compaction; not the full variant with fields).
   - `compacted_start`: inclusive start turn index replaced by the summary (from
     `CompactionSummary.compacted_start`; see interface-definitions.md §Compaction).
   - `compacted_end`: inclusive end turn index replaced by the summary (from
     `CompactionSummary.compacted_end`); the replaced slice is `messages[compacted_start..=compacted_end]`.
   - `summary_token_count`: the token count of the injected `SystemMessage(summary_text)`.
   - `tokens_remaining_after`: `RunContext.budget_info.tokens_remaining` after the compacted
     context is active.
2. **Emission timing:** The event is emitted AFTER the compacted checkpoint is written — the
   stream consumer sees the event only after the state mutation is durable. This prevents a
   race where the consumer reads the compaction event but the engine reverts the state.
3. **Exactly once per compaction cycle:** One `compaction_event` per trigger evaluation that
   results in compaction. If the trigger fires but `compact()` returns an error, no event is
   emitted (the engine logs the error and continues without compaction).
4. **Not emitted when Disabled:** `CompactionTrigger::Disabled` never triggers compaction;
   no `compaction_event` is ever emitted in this configuration.

## Invariants

- Emission is post-commit: the stream consumer can trust that when `compaction_event` arrives,
  the run's active message window has already been replaced by the summary.
- `tokens_remaining_after` reflects `RunContext.budget_info.tokens_remaining` AFTER the
  compaction (not before). Type is `Option<i64>`: `None` when no token ceiling is configured
  (e.g., `OnMessageCount`/`OnTokenCount` triggers with neither `soft_limit` nor `hard_limit` set);
  negative `i64` when `accumulated > ceiling` (Deny path). Wire serializes as `null` when
  `None`. This is the meaningful value for capacity-management consumers.
- **`parent_ids` is mandatory (BC-2.06.002 Inv-2):** Every `StreamEvent` variant, including
  `CompactionEvent`, MUST carry `parent_ids: Vec<RunId>`. For a top-level run `parent_ids`
  is empty (`[]`); for a sub-agent run it contains the parent `RunId` chain. This field
  must not be omitted from the wire payload.
- `StreamEvent` variants are typed enum members (BC-2.06.001 invariant).
- **DI-014:** The event payload must not be silently dropped; fire-and-forget semantics apply.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `CompactionTrigger::Disabled` (default) | No `compaction_event` emitted at any point in the run |
| EC-002 | `compact()` returns `Err(...)` (policy error) | No `compaction_event` emitted; engine logs error, continues without compaction |
| EC-003 | Compaction fires twice in one run (trigger crosses watermark again after first compaction) | Two `compaction_event` events emitted in sequence; each reflects its respective compacted range |
| EC-004 | Stream consumer disconnected before event | Event dropped; engine does not block; run continues normally |
| EC-005 | `compacted_start..=compacted_end` spans the full conversation history | Event emitted with `compacted_start: 0, compacted_end: <last_turn>` |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | OnWatermark trigger fires after super-step 5; compact() succeeds; 10 turns compacted | Stream: `CompactionEvent { run_id: "<uuid>", parent_ids: [], trigger: "OnWatermark", compacted_start: 0, compacted_end: 9, summary_token_count: 250, tokens_remaining_after: 45000 }` | happy-path |
| TV-002 | `CompactionTrigger::Disabled` | No `compaction_event` in stream across full run | no-emission (disabled) |
| TV-003 | compact() returns Err | No `compaction_event`; run continues; error observable via EvidenceJournal only | error — no event |
| TV-004 | OnMessageCount trigger fires; 5 turns compacted | `CompactionEvent { run_id: "<uuid>", parent_ids: [], trigger: "OnMessageCount", compacted_start: 0, compacted_end: 4, ... }` | message-count trigger |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.06.006-A | compaction_event emitted after checkpoint commit (post-commit ordering) | Integration test: assert stream event arrives after checkpoint GET confirms new message window |
| VP-2.06.006-B | No compaction_event when Disabled or when compact() errors | Unit test: Disabled config → assert no CompactionEvent in collected stream; compact() Err → same |

## Related BCs

- BC-2.06.001 — extends: 12-variant event taxonomy (this adds event 15; events 13+14 from BC-2.06.004/005)
- BC-2.10.005 — depends on: CompactionTrigger evaluation (what fires the compaction that produces this event)
- BC-2.10.006 — composes with: CompactionEvent appended to EvidenceJournal in same cycle; stream event emitted after journal write

## Architecture Anchors

- `architecture/decisions/ADR-019-rolling-context-compaction.md` — Decision 4 (compaction_event streaming event, payload fields)
- `architecture/module-decomposition.md` — SS-06, `graph::event_emitter (ferrochain-graph/src/event_emitter.rs)`; SS-10, `ferrochain-graph / budget`

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-06 extension story]_

## VP Anchors

- VP-2.06.006-A
- VP-2.06.006-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-035 |
| Capability Anchor Justification | CAP-035 ("Rolling Proactive Context Compaction (CompactionTrigger / CompactionPolicy)") per capabilities-p1-p2.md §CAP-035 — this BC specifies the compaction_event streaming event (15th variant) mandated by CAP-035's "PO BC obligation (SS-06): amend BC-2.06.001 or author BC-2.06.006 for compaction_event variant", providing observability for the rolling compaction primitive |
| L2 Domain Invariants | DI-014 (Error Propagation — event payload not silently dropped; fire-and-forget semantics; engine does not block) |
| Architecture Authority | ADR-019 Decision 4 (compaction_event payload definition) |
| Binding Decisions | D23 (rolling compaction mandate; streaming taxonomy 14→15) |
| VP Registration | VP-2.06.006-A/B (integration/unit tests) |
| Module | ferrochain-graph / streaming + budget |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
