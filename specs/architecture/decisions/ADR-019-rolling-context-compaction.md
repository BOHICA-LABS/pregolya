---
document_type: adr
level: L3
adr_id: "019"
slug: rolling-context-compaction
title: "Rolling Proactive Context Compaction: CompactionTrigger, CompactionPolicy Trait, and Budget Engine Dispatch"
status: accepted
date: "2026-07-22"
producer: architect
timestamp: 2026-07-22T00:00:00Z
version: "1.5"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D23]
supersedes: null
superseded_by: null
subsystems_affected: [SS-10, SS-04]
changelog:
  - "1.5 (FIX-BURST-254/2026-07-24): F-P153-02 — annotate Decision 4 trigger field with wire-serialization clarification: on the SSE wire the field serializes as the bare variant-name string (\"OnWatermark\" | \"OnMessageCount\" | \"OnTokenCount\") per BC-2.06.006 PC1 — NOT serde's default full-variant form with nested fields ({\"OnWatermark\":{\"fraction\":0.8}}). Coherence check of remaining Decision 4 fields against BC-2.06.006 PC1: run_id, parent_ids, compacted_start, compacted_end, summary_token_count, tokens_remaining_after all match exactly — no other divergence found."
  - "1.4 (FIX-BURST-252/2026-07-24): Six compaction type-canon adjudications (F-P151-01/02/03/04/05/07). (1) F-P151-01: OnMessageCount/OnTokenCount field names confirmed as `count`/`tokens` (ADR-019 original authority wins over interface-def `threshold`). (2) F-P151-02: CompactionSummary shape — `compacted_range: RangeInclusive<usize>` → flat `compacted_start: usize` + `compacted_end: usize` (serde-safe, wire-consistent, matches interface-definitions §Compaction). (3) F-P151-03: StreamEvent::CompactionEvent — canonical shape is flat compacted_start/compacted_end + parent_ids: Vec<RunId> per BC-2.06.002 mandate; BC-2.06.006 PC1 omitted parent_ids and used nested compacted_turns (PO to fix). (4) F-P151-04: OnWatermark predicate — `<` → `<=` (`tokens_remaining / ceiling <= (1.0 - fraction)`); strict-less-than broke EC-002 (fraction=1.0 never fired); non-strict-leq is correct (fires when tokens_remaining=0 for fraction=1.0). (5) F-P151-05: fraction type f32 → f64 throughout (interface-definitions was already f64; ADR was stale; f64 avoids precision issues for budgets >16M tokens). (6) F-P151-07: Step 4 checkpoint write mechanism — `put_writes` → `put` (put_writes is for PregelTask outputs keyed by task_id within a super-step; compaction runs between super-steps and must write a full checkpoint blob; CheckpointSaver::put is the correct method). VP-012 updated in same burst to match adjudications 4+5."
  - "1.3 (burst-239/2026-07-23): F-P139-01 — update BC-2.04.001 citations in Decision 3 step 4 and Consequences Positive to BC-2.04.001 Inv-5 (append-only checkpoint records, matching PO canonical anchor). F-P139-02 — Decision 4 CompactionEvent field tokens_remaining_after: u64 → Option<i64> (None when no token ceiling; negative on Deny — per BC-2.06.001 PC2, BC-2.06.006 PC1, interface-definitions §BudgetInfo). TD-VSDD-060 sibling sweep: no other stale BC-2.04.001 immutability citations or tokens_remaining_after: u64 renderings found in architecture-layer docs."
  - "1.2 (burst-234/2026-07-22): F-P134-04 — Decision 3 step 5: rename CompactionEvent journal field `trigger_tokens_remaining` → `tokens_remaining_after` to match BC-2.10.006 v1.1 canonical field name and Decision 4 streaming payload (both use `tokens_remaining_after`). TD-VSDD-060 sibling sweep: sole remaining occurrence in architect-scope files; entities-graph.md (domain-spec, out of scope) and BC-2.10.006 changelog (historical documentation, out of scope) retain the old name in quoted context only."
  - "1.1 (burst-233/2026-07-22): F-P133-07 sibling sweep (TD-VSDD-060) — remove stale 'VP-012 candidate' labels (VP-012 seeded burst-232, Kani P1). Two sites updated: §Compaction Trigger Evaluation Sequence step 1 watermark check, and §Positive Properties rationale line."
  - "1.0 (D23/2026-07-22): Initial ADR — rolling proactive context compaction as a first-class framework primitive. Closes the DEGRADED gap identified in domain-e-agentic-coding-assistant.md §3 item 10."
---

# ADR-019: Rolling Proactive Context Compaction

**Status:** Accepted — D23 authority (2026-07-22)

## Context

`OnCeiling::Summarize` (BC-2.10.003 v1.2) handles the ceiling-triggered compaction path:
when the run exhausts its token budget the engine invokes a summarize call and transitions
the run to `summary_halt`. This is reactive, not proactive.

Domain E (agentic coding CLI, §3 item 10, §6 table row "Rolling proactive context
compaction") classifies the current surface as DEGRADED:

> "Periodically compact history using checkpoint FTS + MemoryStore; not a first-class
> framework primitive … Full cross-session rolling memory requires CAP-017 (P2/Wave 2).
> For v1, within-session rolling compaction is achievable via application-layer logic."

D23 mandates a first-class rolling-compaction primitive so application authors do not
independently re-implement the watermark detection, history snapshot, summary injection,
and journal-entry logic. Within-session compaction is the v1 scope; cross-session
integration with CAP-017 (now Wave 1 per D23 item 3) is additive.

`budget_info.tokens_remaining` is already exposed to nodes mid-run (BC-2.10.001 PC3,
`RunContext`). The checkpoint FTS (`search_history`, BC-2.04.008) can retrieve recent
conversation turns. The frozen-snapshot context mutation (BC-2.15.006) injects memory
items into the next run's system prompt. The infrastructure exists; it needs a framework
coordination layer.

## Decision 1 — `CompactionTrigger` and New Types in `core::budget` (Definitions-Only)

The existing definitions-only `core::budget` module (ADR-009 Option 3) gains:

```rust
/// When the budget engine should attempt proactive compaction.
#[non_exhaustive]
pub enum CompactionTrigger {
    /// No proactive compaction. OnCeiling behaviour is unchanged. (default)
    Disabled,
    /// Compact when tokens_remaining / budget_ceiling <= (1.0 - fraction),
    /// equivalently tokens_used / budget_ceiling >= fraction.
    /// fraction ∈ (0.0, 1.0]. E.g., 0.8 = trigger when ≥80% of budget consumed.
    /// fraction=1.0 fires only when tokens_remaining==0 (budget fully exhausted).
    OnWatermark { fraction: f64 },
    /// Compact when the message count in the active conversation exceeds n.
    OnMessageCount { count: usize },
    /// Compact when the cumulative token count in the conversation exceeds a threshold.
    OnTokenCount { tokens: u64 },
}

/// Read-only snapshot of recent conversation history, produced by the budget engine
/// from checkpoint FTS (BC-2.04.008 search_history).
#[non_exhaustive]
pub struct ConversationSnapshot {
    /// Ordered slice of (turn_index, Message) pairs selected for compaction.
    pub turns: Vec<(usize, Message)>,
    pub token_estimate: u64,
}

/// Output produced by a CompactionPolicy implementation.
/// Flat scalar fields (not RangeInclusive) for serde compatibility and wire consistency.
#[non_exhaustive]
pub struct CompactionSummary {
    /// The compact summary text to inject as a SystemMessage.
    pub summary_text: String,
    /// Inclusive start turn index of the compacted range.
    pub compacted_start: usize,
    /// Inclusive end turn index of the compacted range.
    pub compacted_end: usize,
}

#[async_trait]
pub trait CompactionPolicy: Send + Sync {
    /// Produce a CompactionSummary from a ConversationSnapshot.
    /// The engine replaces messages[compacted_start..=compacted_end] with SystemMessage(summary_text).
    async fn compact(
        &self,
        snapshot: &ConversationSnapshot,
        run_ctx: &RunContext,
    ) -> Result<CompactionSummary, FerrochainError>;
}
```

These are pure type and trait definitions; no execution logic in `core::budget`. Follows
the ADR-009 Option 3 pattern (BudgetPolicy trait definitions in core, dispatch in graph).

## Decision 2 — `BudgetConfig` Extensions

`BudgetConfig` (in `core::budget`) gains two new optional fields:

```rust
pub struct BudgetConfig {
    // ... existing fields: soft_limit, hard_limit, on_ceiling ...
    pub compaction_trigger: CompactionTrigger,    // default: Disabled
    pub compaction_policy: Option<Arc<dyn CompactionPolicy>>, // None = DefaultSummarizationPolicy
}
```

If `compaction_trigger != Disabled` and `compaction_policy = None`, the engine uses a
built-in `DefaultSummarizationPolicy` that prompts the model to produce a concise summary
of the `ConversationSnapshot.turns` (same mechanism as `OnCeiling::Summarize`).

## Decision 3 — Compaction Execution in `graph::budget`

The `BudgetEngine` in `graph::budget` (execution counterpart of `core::budget` definitions,
per ADR-009) evaluates `CompactionTrigger` after each super-step:

1. **Watermark check:** `tokens_remaining / ceiling <= (1.0 - fraction)` (equivalently:
   `tokens_used / ceiling >= fraction`) using `budget_info` in `RunContext`. This is a pure
   arithmetic comparison (VP-012, Kani P1, seeded burst-232). `fraction = 0.8` fires when
   ≥80% consumed; `fraction = 1.0` fires only when tokens_remaining == 0.
2. **History snapshot:** query `CheckpointSaver::search_history` (BC-2.04.008) to retrieve
   the `count` most recent turns (or all turns up to the token estimate threshold).
3. **Compact:** call `compaction_policy.compact(&snapshot, &run_ctx).await`.
4. **Apply:** call `CheckpointSaver::get_next_version` to obtain a new CheckpointId, then
   call `CheckpointSaver::put` to write a NEW full checkpoint entry where
   `messages[compacted_start..=compacted_end]` is replaced by a single
   `SystemMessage(summary_text)`. Using `put` (full checkpoint blob) rather than
   `put_writes` (per-PregelTask output keyed by task_id) is correct because compaction
   runs between super-steps and is not a task. The original checkpoint records are NOT
   deleted (append-only checkpoint records per BC-2.04.001 Inv-5). If `put` fails, the
   in-memory window is reverted; the run continues with the pre-compaction window.
5. **Journal:** append a `CompactionEvent { compacted_start, compacted_end,
   summary_token_count, tokens_remaining_after }` to `EvidenceJournal`
   (BC-2.10.001 append-only journal).
6. **Stream:** emit a `compaction_event` streaming event (see Decision 4).
7. Continue the run from the next super-step with the compacted context.

Compaction is a **mid-run state mutation** — it modifies the active conversation context,
not the next-run context (contrast with frozen-snapshot mutation in BC-2.15.006 which
takes effect on the next run). The compaction applies immediately to the current run's
message window.

**Determinism note:** Compaction is NOT deterministic (the model produces the summary).
It is therefore logged in `EvidenceJournal`, is visible in the streaming event channel,
and does not affect BSP determinism invariants (VP-001) because it runs between
super-steps, not within them.

## Decision 4 — Streaming Event `compaction_event`

When compaction completes, the engine emits a new streaming event:

```
compaction_event {
    run_id,
    parent_ids: Vec<RunId>,       // BC-2.06.002 mandate: present on every StreamEvent variant
    trigger: CompactionTrigger,   // which variant fired; wire serialization: bare variant-name string only
                                  // ("OnWatermark" | "OnMessageCount" | "OnTokenCount") per BC-2.06.006 PC1.
                                  // NOT serde's default full-variant form ({"OnWatermark":{"fraction":0.8}}).
                                  // The internal StreamEvent variant may hold the full enum for in-process use;
                                  // SSE wire emission must serialize only the tag string — custom Serialize impl
                                  // or a wire-only tag enum (e.g. #[serde(rename_all = "PascalCase")] on a
                                  // fieldless mirror enum) is required.
    compacted_start: usize,       // inclusive start turn index (flat, not RangeInclusive)
    compacted_end: usize,         // inclusive end turn index
    summary_token_count: u64,
    tokens_remaining_after: Option<i64>,
}
```

The 14-variant streaming event taxonomy (after ADR-018's two additions) grows to 15
variants. **PO BC obligation (SS-06):** amend BC-2.06.001 or author BC-2.06.006 for the
`compaction_event` variant.

**PO BC obligation (SS-10):** author new BC(s) for compaction trigger semantics, watermark
arithmetic, and journal entry requirements.

## Decision 5 — CAP-017 Wave Promotion Interaction

CAP-017 (Long-Horizon Cross-Session Memory, promoted from P2/Wave 2 → v1/Wave 1 per D23
item 3) uses `MemoryStore` for cross-session persistence. Rolling compaction (this ADR)
operates within a single session on the live message window. The two are additive:

- Within-session: `CompactionPolicy` compacts the active window (this ADR, v1).
- Cross-session: `CompactionPolicy` MAY write the `CompactionSummary` to `MemoryStore`
  (CAP-017) as a project knowledge entry. This is an optional path enabled by injecting
  a `CompactionPolicy` impl that also calls `MemoryStore::put` — the framework enforces
  no constraint on what `compact()` does beyond returning `CompactionSummary`.

This separation is intentional: within-session compaction is available without CAP-017,
and CAP-017 is available without compaction. The coupling is opt-in at the application layer.

## Rationale

The application-layer alternative (status quo) requires every coding agent to independently
implement: watermark detection from `RunContext.budget_info`, FTS history queries, summary
injection via message mutation, and `EvidenceJournal` entries. This is non-trivial
boilerplate that diverges across implementations and is not testable at the framework level.

`core::budget` (definitions-only) is the correct placement for `CompactionTrigger` and
`CompactionPolicy` because `BudgetConfig` already lives there, and these fields are
configuration-time types (not execution types). This follows ADR-009 Option 3 exactly.

`graph::budget` (existing MEDIUM execution module) is the correct dispatch location because
it already holds `BudgetEngine` and `EvidenceJournal` — compaction is logically a
budget-governance action (triggered by token consumption) and produces an audit-trail entry.

Making compaction a mid-run checkpoint mutation (Decision 3 step 4) rather than a next-run
frozen-snapshot injection (BC-2.15.006) is correct for the use case: the entire point of
rolling compaction is to CONTINUE the current run below the watermark without halting.
Frozen-snapshot is a next-run-start mechanism; it cannot extend the current run.

## Alternatives Considered

- **Option A — Application-layer only (status quo):** Document the pattern using
  `budget_info + FTS + frozen-snapshot`. Rejected: every coding-agent application
  re-implements the same boilerplate; no auditability via EvidenceJournal; no streaming
  observability of compaction events.

- **Option B — Extend `OnCeiling` with a new variant:** Add `OnCeiling::RollingCompact`
  to replace `Summarize`. Rejected: ceiling-triggered and watermark-triggered compaction
  are independent concerns — `OnCeiling` governs what to do WHEN the ceiling is hit;
  `CompactionTrigger` governs WHEN to compact proactively. Conflating them in `OnCeiling`
  would produce confusing semantics (e.g., a run could want both proactive compaction at
  80% AND halt at 100%).

- **Option C — Compaction as a special graph node:** Require the application to add a
  "compaction node" to their graph topology. Rejected: graph topology should not be
  polluted with framework infrastructure; the compaction node would need to be inserted
  at every possible super-step boundary, reproducing the same verbosity as the 2-node HITL
  workaround (see ADR-018 context).

- **Option D — Compaction as a checkpoint FTS query tool:** Expose compaction as a
  callable tool so the model can self-request compaction. Considered as an additive option
  (not a replacement). Not selected for v1: makes compaction model-initiative rather than
  policy-governed, creating non-deterministic compaction timing. Could be offered in a
  future CAP.

## Source / Origin

- **D23 authority:** D23 decisions log entry (STATE.md) — item 2 "rolling proactive
  context compaction primitive."
- **Domain E forcing function:** domain-e-agentic-coding-assistant.md §3 item 10 and §6
  table row "Rolling proactive context compaction" — DEGRADED, closure path "first-class
  rolling-compaction primitive (CAP addition) or accept application-layer orchestration."
- **BC-2.10.001/003:** existing budget governance BCs; `EvidenceJournal` and `OnCeiling`
  are the context for this extension.
- **BC-2.04.008:** `search_history` FTS — the mechanism for building `ConversationSnapshot`.
- **BC-2.15.006:** frozen-snapshot context mutation — explicitly NOT used for within-session
  compaction (see Decision 3 and Rationale).
- **ADR-009:** precedent for `core::budget` definitions-only + `graph::budget` execution
  split pattern adopted here.

## Consequences

### Positive

- Coding agents configure rolling compaction in one field (`BudgetConfig::compaction_trigger`)
  with zero application-layer boilerplate.
- Compaction is auditable via `EvidenceJournal` entries and observable via streaming events.
- `CompactionTrigger::Disabled` (default) preserves full backward compatibility; existing
  graphs are unaffected.
- `OnWatermark` arithmetic is a pure comparison — VP-012 (Kani P1, seeded burst-232) (trigger fires if
  and only if `tokens_remaining / ceiling <= (1.0 - fraction)`, equivalently `tokens_used / ceiling >= fraction`).
- Framework-owned compaction respects BC-2.04.001 Inv-5 (append-only checkpoint records):
  original turns are not deleted, only superseded in the active message window.

### Negative / Trade-offs

- Mid-run checkpoint mutation is a new primitive — the engine must ensure the compacted
  state is durable before proceeding (a failed `put` during compaction must not
  silently corrupt the message window; revert in-memory state on `put` failure).
- `ConversationSnapshot` assembly from FTS requires a `CheckpointSaver` dependency in
  `graph::budget`; this is already present (the engine holds the saver reference) but
  formalizes the coupling.
- Non-deterministic compaction (model-produced summary) means replaying a run from a
  checkpoint after compaction may produce a different context. This is an accepted tradeoff
  documented in EvidenceJournal.
- A new streaming event variant (15 total) requires PO BC amendment to BC-2.06.001 or
  a new BC-2.06.006.

### Status as of 2026-07-22

Architecture decision accepted. No implementation yet (Phase 1). PO BC delivery for SS-10
compaction contracts and SS-06 streaming event amendment are prerequisites for Phase 2
story decomposition.
