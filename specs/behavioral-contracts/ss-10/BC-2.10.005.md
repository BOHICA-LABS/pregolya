---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.005
version: "1.1"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-10
capability: CAP-035
crate: ferrochain-core
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-23T00:00:00Z
di_anchors: [DI-014]
vp_seed: true
vp_id: VP-012
red_gate: false
changelog:
  - "1.1 (burst-236/OBS-P136-A/2026-07-23): VP Anchors and Traceability VP Registration updated: stale 'ARCH-INDEX D23 candidate — architect to assign VP-INDEX entry' prose replaced with 'assigned in VP-INDEX v1.5 as VP-012' (VP-INDEX v1.5 burst-232 seeded VP-012 Kani P1)."
  - "1.0 (D23/2026-07-22): Initial BC — D23 rolling compaction, SS-10 CompactionTrigger configuration contract. VP-012 Kani seed."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-035
  - architecture/decisions/ADR-019-rolling-context-compaction.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-019-rolling-context-compaction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "f85aba2"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.005: CompactionTrigger Configuration — Disabled/OnWatermark/OnMessageCount/OnTokenCount; BudgetConfig Extension; Watermark Arithmetic (VP-012 Kani Seed)

## Description

`CompactionTrigger` is a `#[non_exhaustive]` enum added to `ferrochain-core::core::budget`
(definitions-only module, ADR-009 Option 3). It extends `BudgetConfig` with two new fields:
`compaction_trigger: CompactionTrigger` (default `Disabled`) and
`compaction_policy: Option<Arc<dyn CompactionPolicy>>` (default `None` → `DefaultSummarizationPolicy`).
The four variants govern when the `BudgetEngine` in `graph::budget` initiates a compaction
cycle. `Disabled` is the default and preserves full backward compatibility. `OnWatermark`
uses a pure arithmetic comparison `(tokens_remaining / ceiling) < (1.0 - fraction)` that is
the VP-012 Kani P1 seed candidate. `DefaultSummarizationPolicy` (when `compaction_policy` is
`None`) prompts the model to summarize the `ConversationSnapshot`, using the same mechanism
as `OnCeiling::Summarize`.

## Preconditions

1. `BudgetConfig` is being constructed for a `GraphConfig`. The developer sets
   `compaction_trigger` and optionally `compaction_policy`.
2. For `OnWatermark { fraction }`: `fraction ∈ (0.0, 1.0]`; a value of 0.0 is rejected at
   `BudgetConfig` construction with a configuration error (fraction 0.0 would always trigger).
3. For `OnMessageCount { count }`: `count > 0`; a value of 0 is rejected.
4. For `OnTokenCount { tokens }`: `tokens > 0`; a value of 0 is rejected.
5. `compaction_trigger: Disabled` is the default; no explicit configuration needed for
   backward compatibility.

## Postconditions

1. **Disabled (default):** No proactive compaction occurs during the run. `OnCeiling`
   behavior (BC-2.10.003) is unchanged. This variant preserves full backward compatibility.
2. **OnWatermark { fraction }:** The `BudgetEngine` evaluates after each super-step:
   `tokens_remaining / budget_ceiling < (1.0 - fraction)`.
   - `fraction = 0.8` means "trigger when 80% of budget is consumed" (i.e., 20% remaining).
   - The comparison uses `f32` arithmetic. `tokens_remaining` and `budget_ceiling` are
     cast from `u64` to `f32` for the comparison; precision loss is accepted (the
     threshold is approximate, not exact to the token).
   - When the condition is true, the compaction cycle is initiated (BC-2.10.006).
3. **OnMessageCount { count }:** The `BudgetEngine` evaluates after each super-step:
   `active_window_message_count >= count`. When true, compaction is initiated.
4. **OnTokenCount { tokens }:** The `BudgetEngine` evaluates after each super-step:
   `cumulative_window_tokens >= tokens`. When true, compaction is initiated.
5. **DefaultSummarizationPolicy (compaction_policy: None):** When compaction fires and no
   explicit `CompactionPolicy` is configured, the `DefaultSummarizationPolicy` is used.
   It assembles the `ConversationSnapshot` from checkpoint FTS (BC-2.04.008), prompts the
   model to produce a concise summary, and returns a `CompactionSummary`. The mechanism is
   identical to `OnCeiling::Summarize` (BC-2.10.003 PC8) but triggered proactively.

## Invariants

- **OnWatermark arithmetic (VP-012 Kani seed):** The trigger condition
  `tokens_remaining / ceiling < (1.0 - fraction)` is a pure f32 comparison with no side
  effects. VP-012 Kani candidate: for any valid `(tokens_remaining, ceiling, fraction)` tuple
  where `0 < tokens_remaining <= ceiling` and `fraction ∈ (0.0, 1.0]`, the comparison
  returns the mathematically correct boolean.
- `CompactionTrigger::Disabled` is the default — graphs without explicit compaction
  configuration see NO behavior change (backward compatible).
- `CompactionTrigger` is `#[non_exhaustive]`: future variants (e.g., `OnIdle`) are addable
  without breaking existing `BudgetConfig` construction code.
- Only one trigger variant fires per evaluation cycle. `BudgetEngine` uses the configured
  variant; there is no "first-matching" logic across multiple configured triggers.
- `BudgetConfig.compaction_trigger` and `BudgetConfig.compaction_policy` reside in
  `ferrochain-core::core::budget` (definitions-only) following ADR-009 Option 3. Execution
  logic is in `ferrochain-graph::graph::budget`.
- **DI-014 (No Silent Swallowing):** Configuration errors (fraction=0.0, count=0, tokens=0)
  propagate as `Err` at construction time; they are not silently treated as `Disabled`.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `OnWatermark { fraction: 0.0 }` at BudgetConfig construction | `Err` — fraction=0.0 always fires; configuration error |
| EC-002 | `OnWatermark { fraction: 1.0 }` | Valid — triggers when 100% of budget consumed (i.e., `tokens_remaining == 0`); fires at ceiling |
| EC-003 | `OnMessageCount { count: 0 }` | `Err` — count=0 would always fire; configuration error |
| EC-004 | `tokens_remaining > ceiling` (budget accounting error) | `OnWatermark` condition `tokens_remaining / ceiling < (1.0 - fraction)` evaluates to `false` for any fraction ≤ 1.0 (tokens_remaining/ceiling > 1.0); no spurious trigger |
| EC-005 | `compaction_policy: None` with any trigger variant | `DefaultSummarizationPolicy` used; same summarization mechanism as `OnCeiling::Summarize` |
| EC-006 | `CompactionTrigger::Disabled` (default) | No compaction throughout run; `OnCeiling` behavior unchanged |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `OnWatermark { fraction: 0.8 }`, budget_ceiling=100_000, tokens_remaining=19_999 | Trigger fires (19_999/100_000 = 0.19999 < 0.2) | watermark fires |
| TV-002 | `OnWatermark { fraction: 0.8 }`, budget_ceiling=100_000, tokens_remaining=20_001 | Trigger does NOT fire (20_001/100_000 = 0.20001 > 0.2) | watermark does not fire |
| TV-003 | `OnWatermark { fraction: 0.0 }` construction | `Err` — configuration error; fraction=0.0 invalid | config error |
| TV-004 | `OnMessageCount { count: 10 }`, active_window has 10 messages after super-step | Trigger fires | message count fires |
| TV-005 | `Disabled` (default), any usage | No compaction event emitted; run proceeds to ceiling normally | disabled (default) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-012 (Kani P1 candidate) | OnWatermark: `tokens_remaining / ceiling < (1.0 - fraction)` fires if and only if the mathematical condition holds for all valid (tokens_remaining, ceiling, fraction) tuples | Kani: exhaustive over bounded integer ranges; f32 cast; assert correct boolean for all valid inputs |
| VP-2.10.005-B | fraction=0.0 and count=0 and tokens=0 are rejected at construction with Err | Unit tests for each invalid configuration |
| VP-2.10.005-C | Disabled default: no CompactionEvent emitted across a full run | Integration test: BudgetConfig with default Disabled; assert no CompactionEvent in stream |

## Related BCs

- BC-2.10.001 — related to: BudgetPolicy evaluation pipeline; CompactionTrigger is evaluated in same BudgetEngine as policy
- BC-2.10.003 — related to: OnCeiling::Summarize is the reactive ceiling path; CompactionTrigger is the proactive path; both distinct
- BC-2.10.006 — depends on: compaction execution contract (what happens when trigger fires)
- BC-2.06.006 — related to: compaction_event streaming event emitted after successful compaction cycle

## Architecture Anchors

- `architecture/decisions/ADR-019-rolling-context-compaction.md` — Decision 1 (CompactionTrigger enum, CompactionPolicy trait, ConversationSnapshot, CompactionSummary types in core::budget), Decision 2 (BudgetConfig extensions)
- `architecture/module-decomposition.md` — SS-10, `ferrochain-core / core::budget` (definitions); `ferrochain-graph / graph::budget` (engine)
- `architecture/verification-architecture.md` — VP-012 (D23 candidate)

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-10 extension story]_

## VP Anchors

- VP-012 (assigned in VP-INDEX v1.5 as VP-012 — Kani P1; ferrochain-core `watermark_arithmetic_harness`)
- VP-2.10.005-B
- VP-2.10.005-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-035 |
| Capability Anchor Justification | CAP-035 ("Rolling Proactive Context Compaction (CompactionTrigger / CompactionPolicy)") per capabilities-p1-p2.md §CAP-035 — this BC specifies the CompactionTrigger enum variants, BudgetConfig extension fields, OnWatermark arithmetic (VP-012 Kani seed), and DefaultSummarizationPolicy fallback that CAP-035 defines as the configuration layer of the rolling compaction primitive |
| L2 Domain Invariants | DI-014 (Error Propagation — invalid configuration values propagate as Err; not silently treated as Disabled) |
| Architecture Authority | ADR-019 Decisions 1 and 2 (CompactionTrigger types in core::budget, BudgetConfig fields) |
| Binding Decisions | D23 (rolling compaction mandate, SS-10 extension) |
| VP Registration | VP-012 (assigned in VP-INDEX v1.5 as VP-012 — Kani P1; ferrochain-core `watermark_arithmetic_harness`) |
| Module | ferrochain-core / core::budget (definitions) |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + Kani (VP-012) |
