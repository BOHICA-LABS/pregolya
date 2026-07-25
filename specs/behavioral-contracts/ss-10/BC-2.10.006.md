---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.006
version: "1.6"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-10
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
  - "1.0 (D23/2026-07-22): Initial BC — D23 rolling compaction, SS-10 compaction execution contract."
  - "1.1 (burst-233/F-P133-10/2026-07-22): Step 5 EvidenceJournal entry — rename field `trigger_tokens_remaining` → `tokens_remaining_after`. Adjudication: the value is captured AFTER window replacement in step 3, so `trigger_tokens_remaining` was semantically misleading (suggests the value was captured at trigger time/step 1, not post-replacement). Renaming to `tokens_remaining_after` aligns with BC-2.06.006 streaming event payload which uses `tokens_remaining_after` for the same conceptual value. Both BCs now agree on the canonical field name for post-compaction remaining tokens."
  - "1.2 (burst-234/F-P134-07/2026-07-22): Add Invariant — Compaction × PendingHumanApproval temporal non-interaction. Closes the F-P134-07 LOW/OBS ambiguity: no BC previously stated that compaction (which fires only at super-step boundaries, PC-4) cannot fire while a run is parked at a PendingHumanApproval interrupt (which is NOT at a super-step boundary). Also states the durability corollary: a ToolApprovalRequest's message-window references survive any subsequent compaction because compaction can only fire after the approval is resolved and the run resumes to a super-step. Cross-references BC-2.05.007 PC-4 and BC-2.05.008 PC-4."
  - "1.3 (burst-236/F-P136-04/2026-07-23): Step 5 EvidenceJournal CompactionEvent.tokens_remaining_after type clarified: source is `RunContext.budget_info.tokens_remaining: Option<i64>` (interface-definitions.md §BudgetInfo). When no token ceiling is configured (OnMessageCount/OnTokenCount triggers with neither soft_limit nor hard_limit set), tokens_remaining is None — the EvidenceJournal entry carries `tokens_remaining_after: Option<i64>` matching the source type. Three-site reconciliation with BC-2.06.006 PC1 and interface-def §StreamEvent (F-P136-04)."
  - "1.4 (2026-07-22, F-P139-01b, burst-239): Fix stale 'BC-2.04.001 immutability' citations (Description, Invariants, Related BCs). F-P139-01 (deep-read pass) found that BC-2.04.001 contains no immutability invariant — that BC is about put_writes timing. The anchor is now BC-2.04.001 Inv-5, which was added in this same burst (F-P139-01a) as a new general checkpoint append-only invariant covering all in-run operations including compaction."
  - "1.5 (F-P142-03, burst-242, 2026-07-23): Sweep Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority and F-P120-01 adjudication. Invariants §Compaction × PendingHumanApproval updated. Zero Command:: enum-variant residue remains in live body text."
  - "1.6 (F-P151-02/07, burst-252, 2026-07-24): ADR-019 v1.4 adjudicated canon applied + F-P151-06 invariant generalization. (1) F-P151-02: All `compacted_range`/`messages[compacted_range]`/`compacted_range.len()` sites → flat form (`messages[compacted_start..=compacted_end]`; count decrease `(compacted_end - compacted_start)`; CompactionSummary inline to flat fields `compacted_start: usize, compacted_end: usize`). Step 5 EvidenceJournal entry updated to `{ compacted_start, compacted_end, … }`. EC-002/TV-003/VP-2.10.006-C/DI-014 rows `put_writes` → `put`. EC-004 flat form. (2) F-P151-07: Step 4 `put_writes` → `get_next_version` + `put` (between-super-steps full-blob write; `put_writes` is per-task within-super-step only; `put` preserves BC-2.04.001 Inv-5 append-only). (3) F-P151-06: Compaction × suspend non-interaction invariant generalized from PendingHumanApproval-only to all three suspend classes: (a) generic `interrupt()` parks (BC-2.05.001 PC5), (b) budget-escalation interrupts (BC-2.10.004 PC4), (c) PendingHumanApproval (BC-2.05.007 PC-4 / BC-2.05.008 PC-4)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-035
  - architecture/decisions/ADR-019-rolling-context-compaction.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-019-rolling-context-compaction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "b6d3831"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.006: Compaction Execution — ConversationSnapshot from FTS; Mid-Run Window REPLACEMENT; CompactionEvent → EvidenceJournal; Checkpoint Immutability; DefaultSummarizationPolicy

## Description

When `BudgetEngine` in `graph::budget` determines that the configured `CompactionTrigger`
condition has been met (BC-2.10.005), it executes a compaction cycle. The cycle follows a
fixed 7-step sequence: (1) assemble `ConversationSnapshot` from checkpoint FTS
(BC-2.04.008), (2) call `CompactionPolicy::compact(snapshot, run_ctx)`, (3) apply the
returned `CompactionSummary` by replacing `messages[compacted_start..=compacted_end]` with a single
`SystemMessage(summary_text)` in the ACTIVE message window (mid-run mutation — NOT
next-run frozen-snapshot), (4) write the updated checkpoint durably, (5) append a
`CompactionEvent` to `EvidenceJournal`, (6) emit `compaction_event` streaming event
(BC-2.06.006), (7) continue the run. Original checkpoint records are NOT deleted
(BC-2.04.001 Inv-5 — append-only; records never deleted or mutated in place). If `compact()`
fails, the cycle is aborted without mutating the message window.

## Preconditions

1. `CompactionTrigger` condition evaluated as true after a super-step (BC-2.10.005).
2. `CheckpointSaver::search_history` (BC-2.04.008) is accessible from `BudgetEngine`.
3. `BudgetConfig.compaction_policy` is either `Some(Arc<dyn CompactionPolicy>)` or `None`
   (in which case `DefaultSummarizationPolicy` is used).
4. The run is between super-steps (not mid-node execution); compaction runs at super-step
   boundaries only.

## Postconditions

**Step 1 — Snapshot assembly:**
The `BudgetEngine` calls `CheckpointSaver::search_history` to retrieve recent conversation
turns. The result is a `ConversationSnapshot { turns: Vec<(usize, Message)>, token_estimate: u64 }`
containing the ordered slice of turns selected for compaction. Turn selection heuristic:
the engine selects the oldest turns not yet compacted, up to a token budget ceiling
(implementation-defined; typically the turn range that would be replaced by the summary).

**Step 2 — Policy compact:**
`compaction_policy.compact(&snapshot, &run_ctx).await` is called. On success: `CompactionSummary
{ summary_text: String, compacted_start: usize, compacted_end: usize }` is returned (flat
inclusive bounds per ADR-019 Decision 1 / interface-definitions.md §Compaction). On error:
`Err(FerrochainError)` — cycle aborted, no mutation, error logged, run continues.

**Step 3 — Mid-run window replacement:**
`messages[compacted_start..=compacted_end]` in the ACTIVE conversation window is replaced by a single
`SystemMessage(summary_text)`. This is a mid-run state mutation — it takes effect
immediately in the current run (contrast: BC-2.15.006 frozen-snapshot takes effect on the
NEXT run start). The total message count decreases by `(compacted_end - compacted_start)`.

**Step 4 — Durable write:**
The updated message window is written to the checkpoint via `CheckpointSaver::get_next_version`
(allocates a new `CheckpointId`) followed by `CheckpointSaver::put` (writes the full
checkpoint state blob under the new `CheckpointId`). `put` is the correct call here —
not `put_writes` — because `put_writes` persists per-task channel writes within the
current super-step, whereas compaction produces a complete new checkpoint state that
spans the between-super-steps boundary; `put` is the full-blob, new-version write path
(BC-2.04.001 Inv-5 append-only: the pre-compaction checkpoint is NOT deleted; the new
checkpoint is appended as a fresh entry). If `put` fails, the in-memory window is reverted
and the cycle is aborted (the run continues with the pre-compaction window). The write
MUST succeed before proceeding to step 5.

**Step 5 — EvidenceJournal entry:**
`CompactionEvent { compacted_start, compacted_end, summary_token_count: summary_text.token_count(),
tokens_remaining_after: RunContext.budget_info.tokens_remaining }` is appended to the
`EvidenceJournal` (BC-2.10.001 append-only journal). This entry provides an audit trail
of when and why compaction occurred. The `tokens_remaining_after` field is typed
`Option<i64>` — matching `RunContext.budget_info.tokens_remaining: Option<i64>`
(interface-definitions.md §BudgetInfo): `None` when no token ceiling is configured;
negative when accumulated > ceiling on the Deny path.

**Step 6 — Streaming event:**
`StreamEvent::CompactionEvent` (BC-2.06.006) is emitted with the compaction summary payload.

**Step 7 — Continue run:**
The run proceeds from the next super-step with the compacted context window active.

## Invariants

- **Checkpoint append-only invariant (BC-2.04.001 Inv-5):** Original message records are
  NEVER deleted from the checkpoint store. The compaction writes a NEW checkpoint entry with
  the compacted window; the old entries remain in the store and are readable via history APIs.
- **Mid-run, not next-run:** Compaction takes effect immediately in the current run.
  This is structurally different from BC-2.15.006 (frozen-snapshot context mutation),
  which takes effect only at the next run's start. The two mechanisms are NOT interchangeable.
- **Abort on compact() failure:** If `compact()` returns `Err`, NO checkpoint mutation occurs.
  The run continues with the pre-compaction window. The error is logged but does NOT propagate
  as a run failure — compaction failure is non-fatal.
- **Abort on checkpoint write failure:** If `put` fails after `compact()` succeeds,
  the in-memory window is reverted to the pre-compaction state. The `CompactionEvent`
  journal entry is NOT written. The run continues.
- **EvidenceJournal append-only:** The compaction journal entry follows BC-2.10.001
  append-only invariant. It is written AFTER the checkpoint is durably committed.
- **DI-014 (No Silent Swallowing):** `put` failures revert the in-memory state
  and log the error. `compact()` errors are logged. Neither is silently swallowed as a
  no-op success.
- **Non-determinism:** The `summary_text` produced by `DefaultSummarizationPolicy` is
  model-generated and non-deterministic. This is an accepted tradeoff documented in the
  `EvidenceJournal` entry; BSP determinism invariants (BC-2.03.001 / VP-001) are not
  violated because compaction runs BETWEEN super-steps, not within them.
- **Compaction × Suspend Non-Interaction — general super-step-boundary property (F-P151-06; cross-ref BC-2.05.001 PC5, BC-2.05.007 PC-4, BC-2.05.008 PC-4, BC-2.10.004 PC4):** Compaction fires only at super-step boundaries (PC-4 above). Any run in `interrupted` status — regardless of the suspend source — is NOT at a super-step boundary, so compaction CANNOT fire during any interrupt park window. This property holds across all three suspend classes:

  **(a) Generic `interrupt()` parks (BC-2.05.001):** A node calling `interrupt(value)` fires inside the scheduler's `tick()`, mid-super-step. The run transitions to `interrupted` status with the super-step boundary NOT yet advanced (BC-2.05.001 PC5: "the super-step boundary has not advanced"). The run is parked waiting for a `Command(resume=...)`. Compaction CANNOT fire during this park.

  **(b) Budget-escalation interrupts (BC-2.10.004 PC4):** A `PolicyDecision::Escalate` (or `Deny + OnCeiling::Escalate`) triggers `interrupt(BudgetEscalation{...})` from within a super-step evaluation (BC-2.10.004 PC4: "evaluation point within a super-step"). After the interrupt is raised, the run parks in `interrupted` status. Compaction CANNOT fire during this park.

  **(c) PendingHumanApproval interrupts (BC-2.05.007 PC-4 / BC-2.05.008 PC-4):** A run parked awaiting pre-invoke tool approval is suspended mid-scheduler-step waiting for a `Command(resume=PreToolDecision)`. Compaction CANNOT fire during this park. The `ToolApprovalRequest`'s `ToolCallPreview` payload and message-window references (serialized to checkpoint per BC-2.05.008 PC-3) are stable across any later compaction, because that compaction can only occur after the approval is resolved and the run advances to the next super-step boundary.

  **General corollary:** Any checkpoint state serialized at interrupt time is stable across subsequent compaction cycles, because those cycles are deferred until the park is resolved and the run reaches the next super-step boundary.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `compact()` returns `Err` | Cycle aborted; message window unchanged; error logged; run continues; no EvidenceJournal entry |
| EC-002 | `put` fails after `compact()` succeeds | In-memory window reverted; no EvidenceJournal entry; run continues with pre-compaction window; checkpoint unmodified |
| EC-003 | Compaction fires twice in one run (trigger crosses threshold again after first compaction) | Second cycle runs independently; second `CompactionEvent` appended to journal; second streaming event emitted |
| EC-004 | `compacted_start..=compacted_end` spans all turns in the conversation | All turns replaced by one SystemMessage; message count = 1 after compaction; run proceeds |
| EC-005 | Custom `CompactionPolicy` that also writes to `MemoryStore` (CAP-017 opt-in path) | Policy behavior is application-controlled; framework only requires `Ok(CompactionSummary)` from `compact()`; side effects in policy are unrestricted |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | OnWatermark fires; snapshot covers turns 0-9; DefaultSummarizationPolicy returns summary | Checkpoint: messages[0..=9] replaced by SystemMessage("summary..."); EvidenceJournal: +1 CompactionEvent; stream: +1 compaction_event | happy-path |
| TV-002 | compact() returns Err | Message window unchanged; no journal entry; no stream event; run continues | compact-error |
| TV-003 | `put` fails after `compact()` succeeds | In-memory window reverted to pre-compaction; no journal entry; run continues with pre-compaction window | checkpoint-write-failure |
| TV-004 | Original checkpoint records before compaction | Readable via search_history API even after compaction — immutability preserved | checkpoint immutability |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.10.006-A | Original checkpoint records NOT deleted after compaction (immutability) | Integration test: call search_history after compaction; assert pre-compaction records still present |
| VP-2.10.006-B | compact() Err → no mutation, no journal entry, run continues | Unit test: mock policy returning Err; assert window unchanged and journal not appended |
| VP-2.10.006-C | `put` failure → in-memory revert (no partial-write state) | Unit test: inject `put` failure; assert in-memory window equals pre-compaction state |

## Related BCs

- BC-2.04.001 — depends on: Inv-5 checkpoint append-only invariant (original records never deleted or mutated in place; compaction appends new checkpoint entries; history readable via search_history)
- BC-2.04.008 — depends on: search_history FTS for ConversationSnapshot assembly
- BC-2.10.001 — composes with: EvidenceJournal append-only invariant
- BC-2.10.003 — related to: OnCeiling::Summarize is reactive ceiling path; compaction execution is proactive mid-run path
- BC-2.10.005 — depends on: trigger evaluation (what fires this execution cycle)
- BC-2.15.006 — related to: frozen-snapshot is NEXT-RUN context mutation; compaction execution is CURRENT-RUN mid-run mutation — explicitly distinct mechanisms
- BC-2.06.006 — composes with: compaction_event streaming event emitted at step 6

## Architecture Anchors

- `architecture/decisions/ADR-019-rolling-context-compaction.md` — Decision 3 (7-step compaction execution sequence in graph::budget), Decision 5 (mid-run vs next-run distinction, additive CAP-017 path)
- `architecture/module-decomposition.md` — SS-10, `ferrochain-graph / graph::budget` (BudgetEngine, EvidenceJournal)

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-10 extension story]_

## VP Anchors

- VP-2.10.006-A
- VP-2.10.006-B
- VP-2.10.006-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-035 |
| Capability Anchor Justification | CAP-035 ("Rolling Proactive Context Compaction (CompactionTrigger / CompactionPolicy)") per capabilities-p1-p2.md §CAP-035 — this BC specifies the compaction execution contract: 7-step cycle, ConversationSnapshot assembly from FTS, mid-run REPLACEMENT semantics (distinct from BC-2.15.006 next-run path), CompactionEvent EvidenceJournal entry, checkpoint immutability preservation, and DefaultSummarizationPolicy that CAP-035 defines as the execution layer of the rolling compaction primitive |
| L2 Domain Invariants | DI-014 (Error Propagation — compact() errors and `put` failures logged; in-memory state reverted; neither silently swallowed as no-op success) |
| Architecture Authority | ADR-019 Decision 3 (7-step execution sequence, mid-run mutation, abort-on-error semantics) |
| Binding Decisions | D23 (rolling compaction mandate, SS-10 extension) |
| VP Registration | VP-2.10.006-A/B/C (integration/unit tests) |
| Module | ferrochain-graph / graph::budget |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
