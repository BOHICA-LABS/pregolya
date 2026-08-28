---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.005
version: "1.8"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-10
capability: CAP-035
crate: pregolya-core
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-08-24T00:00:00Z
di_anchors: [DI-014]
vp_seed: true
vp_id: VP-012
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 rolling compaction, SS-10 CompactionTrigger configuration contract. VP-012 Kani seed."
  - "1.1 (burst-236/OBS-P136-A/2026-07-23): VP Anchors and Traceability VP Registration updated: stale 'ARCH-INDEX D23 candidate — architect to assign VP-INDEX entry' prose replaced with 'assigned in VP-INDEX as VP-012' (VP-INDEX v1.5 burst-232 seeded VP-012 Kani P1)."
  - "1.2 (F-P151-04/05, burst-252, 2026-07-24): ADR-019 v1.4 adjudicated canon applied. (1) F-P151-04: OnWatermark predicate `< (1.0 - fraction)` → `<= (1.0 - fraction)` (non-strict is load-bearing: strict `<` can never fire when fraction=1.0 and tokens_remaining=0, violating EC-002). Applied at Description, PC2 (predicate + rationale), Invariants (predicate + Kani bound `0 < …` → `0 <=`), EC-002 (explicit `0.0 <= 0.0 = true` arithmetic), EC-004 (predicate), TV-001 (annotation), VP-012 (table row). (2) F-P151-05: f32 → f64 throughout OnWatermark context (Description, PC2 comparison arithmetic, Invariants); f64 preserves integer exactness up to 2^53 tokens (no precision loss for any realistic token count). (3) ADD TV-006: OnWatermark { fraction: 1.0 }, ceiling=100_000, remaining=0 → fires (0.0 <= 0.0), EC-002 boundary."
  - "1.3 (fix-burst-287/TD-VSDD-091/2026-08-01): VP-INDEX version pin removed. §VP Anchors and §Traceability VP Registration: 'VP-INDEX v1.5 as' → 'VP-INDEX as' (plain prose, no §-anchor introduced). verify-no-version-pins.sh PASS."
  - "1.4 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.25 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (P2A-044 F-06/2026-08-24): compressed-ordinal citation normalized to stable tag."
  - "1.7 (burst-B-SS09-11/bc-scan-hardening/2026-08-26): MED gap — OnWatermark fraction domain: PRE-002 extended to cover fraction > 1.0, negative, and NaN as construction-time Err. INV-006 updated to list all invalid domain values and note E-CORE-005 reuse. EC-007 (fraction > 1.0) and EC-008 (negative / NaN) added. TV-007, TV-008, TV-009 added. VP-2.10.005-B extended to cover full invalid domain. Error code reuse: E-CORE-005 ('Validation failed for fraction: must be in (0.0, 1.0]; got <value>') — no new E-code minted. ADR-027 stable clause anchors {EC-007}, {EC-008}."
  - "1.8 (round-25/F-P2A108-02/2026-08-28): F-P2A108-02 [MED] blast-radius — three doubled non-resolving path notations corrected to parenthetical form: §Description `pregolya-core::core::budget` → `pregolya-core (core::budget)`; {INV-005} `pregolya-core::core::budget` → `pregolya-core (core::budget)` and `pregolya-graph::graph::budget` → `pregolya-graph (graph::budget)`. Double-colon crate::module notation is non-resolving in prose; parenthetical form matches module-decomposition.md §Architecture Anchors convention."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-035
  - architecture/decisions/ADR-019-rolling-context-compaction.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-019-rolling-context-compaction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "2fed6ae"
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

`CompactionTrigger` is a `#[non_exhaustive]` enum added to `pregolya-core (core::budget)`
(definitions-only module, ADR-009 Option 3). It extends `BudgetConfig` with two new fields:
`compaction_trigger: CompactionTrigger` (default `Disabled`) and
`compaction_policy: Option<Arc<dyn CompactionPolicy>>` (default `None` → `DefaultSummarizationPolicy`).
The four variants govern when the `BudgetEngine` in `graph::budget` initiates a compaction
cycle. `Disabled` is the default and preserves full backward compatibility. `OnWatermark`
uses a pure arithmetic comparison `(tokens_remaining / ceiling) <= (1.0 - fraction)` that is
the VP-012 Kani P1 seed candidate. `DefaultSummarizationPolicy` (when `compaction_policy` is
`None`) prompts the model to summarize the `ConversationSnapshot`, using the same mechanism
as `OnCeiling::Summarize`.

## Preconditions

1. {PRE-001} `BudgetConfig` is being constructed for a `GraphConfig`. The developer sets
   `compaction_trigger` and optionally `compaction_policy`.
2. {PRE-002} For `OnWatermark { fraction }`: `fraction ∈ (0.0, 1.0]`. At `BudgetConfig`
   construction, any value outside this closed-open range returns `Err(E-CORE-005)`:
   - `fraction ≤ 0.0` — always triggers or is boundary-invalid (0.0 would fire every super-step)
   - `fraction > 1.0` — `1.0 - fraction` becomes negative; the trigger fires before any budget
     is consumed, defeating the purpose of a watermark
   - `fraction = NaN` or any non-finite `f64` (positive/negative infinity) — IEEE 754 NaN
     comparisons (`NaN <= x`) are always `false`, silently disabling the watermark trigger
   No silent coercion, clamping, or defaulting is applied; all out-of-range values are hard
   construction errors returned as `Err`.
3. {PRE-003} For `OnMessageCount { count }`: `count > 0`; a value of 0 is rejected.
4. {PRE-004} For `OnTokenCount { tokens }`: `tokens > 0`; a value of 0 is rejected.
5. {PRE-005} `compaction_trigger: Disabled` is the default; no explicit configuration needed for
   backward compatibility.

## Postconditions

1. {PC-001} **Disabled (default):** No proactive compaction occurs during the run. `OnCeiling`
   behavior (BC-2.10.003) is unchanged. This variant preserves full backward compatibility.
2. {PC-002} **OnWatermark { fraction }:** The `BudgetEngine` evaluates after each super-step:
   `tokens_remaining / budget_ceiling <= (1.0 - fraction)`.
   - `fraction = 0.8` means "trigger when 80% of budget is consumed" (i.e., 20% remaining).
   - The comparison uses `f64` arithmetic. `tokens_remaining` and `budget_ceiling` are
     cast from `u64` to `f64` for the comparison; `f64` preserves integer exactness up to
     2^53 tokens (no precision loss for any realistic token count).
   - **Non-strict (`<=`) is load-bearing:** strict `< (1.0 - fraction)` with `fraction = 1.0`
     evaluates to `< 0.0`, which can never be true (operands are non-negative); `<= 0.0`
     fires when `tokens_remaining == 0`, implementing the correct "trigger when 100%
     consumed" semantics (EC-002).
   - When the condition is true, the compaction cycle is initiated (BC-2.10.006).
3. {PC-003} **OnMessageCount { count }:** The `BudgetEngine` evaluates after each super-step:
   `active_window_message_count >= count`. When true, compaction is initiated.
4. {PC-004} **OnTokenCount { tokens }:** The `BudgetEngine` evaluates after each super-step:
   `cumulative_window_tokens >= tokens`. When true, compaction is initiated.
5. {PC-005} **DefaultSummarizationPolicy (compaction_policy: None):** When compaction fires and no
   explicit `CompactionPolicy` is configured, the `DefaultSummarizationPolicy` is used.
   It assembles the `ConversationSnapshot` from checkpoint FTS (BC-2.04.008), prompts the
   model to produce a concise summary, and returns a `CompactionSummary`. The mechanism is
   identical to `OnCeiling::Summarize` (BC-2.10.003 {PC-008}) but triggered proactively.

## Invariants

- {INV-001} **OnWatermark arithmetic (VP-012 Kani seed):** The trigger condition
  `tokens_remaining / ceiling <= (1.0 - fraction)` is a pure f64 comparison with no side
  effects. VP-012 Kani candidate: for any valid `(tokens_remaining, ceiling, fraction)` tuple
  where `0 <= tokens_remaining <= ceiling` and `fraction ∈ (0.0, 1.0]`, the comparison
  returns the mathematically correct boolean. **Non-strict `<=` is load-bearing:** strict `<`
  cannot fire when `fraction = 1.0` and `tokens_remaining = 0` (EC-002 boundary case requires
  `0.0 <= 0.0 = true`).
- {INV-002} `CompactionTrigger::Disabled` is the default — graphs without explicit compaction
  configuration see NO behavior change (backward compatible).
- {INV-003} `CompactionTrigger` is `#[non_exhaustive]`: future variants (e.g., `OnIdle`) are addable
  without breaking existing `BudgetConfig` construction code.
- {INV-004} Only one trigger variant fires per evaluation cycle. `BudgetEngine` uses the configured
  variant; there is no "first-matching" logic across multiple configured triggers.
- {INV-005} `BudgetConfig.compaction_trigger` and `BudgetConfig.compaction_policy` reside in
  `pregolya-core (core::budget)` (definitions-only) following ADR-009 Option 3. Execution
  logic is in `pregolya-graph (graph::budget)`.
- {INV-006} **DI-014 (No Silent Swallowing):** Configuration errors propagate as `Err` at
  `BudgetConfig` construction time and are never silently treated as `Disabled`. Full invalid
  domain for each variant: `OnWatermark` — `fraction ≤ 0.0`, `fraction > 1.0`, `fraction` is
  NaN or non-finite; `OnMessageCount` — `count = 0`; `OnTokenCount` — `tokens = 0`.
  **Error code reuse:** E-CORE-005 (`"Validation failed for 'fraction': must be in (0.0, 1.0];
  got <value>"` for `OnWatermark` domain errors) — no new E-code minted; VAL
  construction-time fraction-domain rejection fits the canonical E-CORE-005 format.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `OnWatermark { fraction: 0.0 }` at BudgetConfig construction | `Err` — fraction=0.0 always fires; configuration error |
| EC-002 | `OnWatermark { fraction: 1.0 }` | Valid — triggers when 100% of budget consumed (i.e., `tokens_remaining == 0`); fires because `0.0 / ceiling = 0.0 <= 0.0` (non-strict equality; strict `<` would yield `0.0 < 0.0 = false` and could never fire — non-strict is load-bearing for this boundary) |
| EC-003 | `OnMessageCount { count: 0 }` | `Err` — count=0 would always fire; configuration error |
| EC-004 | `tokens_remaining > ceiling` (budget accounting error) | `OnWatermark` condition `tokens_remaining / ceiling <= (1.0 - fraction)` evaluates to `false` for any fraction ≤ 1.0 (tokens_remaining/ceiling > 1.0 > any valid `1.0 - fraction`); no spurious trigger |
| EC-005 | `compaction_policy: None` with any trigger variant | `DefaultSummarizationPolicy` used; same summarization mechanism as `OnCeiling::Summarize` |
| EC-006 | `CompactionTrigger::Disabled` (default) | No compaction throughout run; `OnCeiling` behavior unchanged |
| {EC-007} | `OnWatermark { fraction: 1.5 }` (fraction > 1.0) at `BudgetConfig` construction | `Err(E-CORE-005)`: `"Validation failed for 'fraction': must be in (0.0, 1.0]; got 1.5"` — fraction > 1.0 yields `1.0 - fraction < 0.0`; the watermark predicate would evaluate to `tokens_remaining/ceiling <= negative`, which fires immediately before any budget is consumed |
| {EC-008} | `OnWatermark { fraction: -0.5 }` (negative fraction) or `OnWatermark { fraction: f64::NAN }` at construction | `Err(E-CORE-005)`: `"Validation failed for 'fraction': must be in (0.0, 1.0]; got <value>"` — negative values are below the valid domain; NaN comparisons in IEEE 754 are always `false` (`NaN <= x = false`), which would silently disable the watermark trigger at runtime |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `OnWatermark { fraction: 0.8 }`, budget_ceiling=100_000, tokens_remaining=19_999 | Trigger fires (19_999/100_000 = 0.19999 <= 0.2) | watermark fires |
| TV-002 | `OnWatermark { fraction: 0.8 }`, budget_ceiling=100_000, tokens_remaining=20_001 | Trigger does NOT fire (20_001/100_000 = 0.20001 > 0.2) | watermark does not fire |
| TV-003 | `OnWatermark { fraction: 0.0 }` construction | `Err` — configuration error; fraction=0.0 invalid | config error |
| TV-004 | `OnMessageCount { count: 10 }`, active_window has 10 messages after super-step | Trigger fires | message count fires |
| TV-005 | `Disabled` (default), any usage | No compaction event emitted; run proceeds to ceiling normally | disabled (default) |
| TV-006 | `OnWatermark { fraction: 1.0 }`, budget_ceiling=100_000, tokens_remaining=0 | Trigger fires: `0.0 / 100_000 = 0.0 <= 0.0` (non-strict equality at EC-002 boundary) | watermark fraction=1.0 fires at zero remaining |
| TV-007 | `BudgetConfig` construction with `OnWatermark { fraction: 1.5 }` | `Err(E-CORE-005)` — construction fails; fraction 1.5 > 1.0 is outside valid domain | fraction domain error (>1.0) — EC-007 |
| TV-008 | `BudgetConfig` construction with `OnWatermark { fraction: -0.5 }` | `Err(E-CORE-005)` — construction fails; fraction -0.5 < 0.0 is below valid domain | fraction domain error (negative) — EC-008 |
| TV-009 | `BudgetConfig` construction with `OnWatermark { fraction: f64::NAN }` | `Err(E-CORE-005)` — construction fails; NaN is non-finite and produces indeterminate comparisons | fraction domain error (NaN) — EC-008 |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-012 (Kani P1 candidate) | OnWatermark: `tokens_remaining / ceiling <= (1.0 - fraction)` fires if and only if the mathematical condition holds for all valid (tokens_remaining, ceiling, fraction) tuples (including the EC-002 boundary `remaining=0, fraction=1.0`) | Kani: exhaustive over bounded integer ranges; f64 cast; assert correct boolean for all valid inputs including the non-strict equality boundary |
| VP-2.10.005-B | All invalid construction configurations rejected with `Err`: `fraction ≤ 0.0`, `fraction > 1.0`, `fraction = NaN`, `count = 0`, `tokens = 0` | Unit tests for each invalid configuration (TV-003, TV-007, TV-008, TV-009) |
| VP-2.10.005-C | Disabled default: no CompactionEvent emitted across a full run | Integration test: BudgetConfig with default Disabled; assert no CompactionEvent in stream |

## Related BCs

- BC-2.10.001 — related to: BudgetPolicy evaluation pipeline; CompactionTrigger is evaluated in same BudgetEngine as policy
- BC-2.10.003 — related to: OnCeiling::Summarize is the reactive ceiling path; CompactionTrigger is the proactive path; both distinct
- BC-2.10.006 — depends on: compaction execution contract (what happens when trigger fires)
- BC-2.06.006 — related to: compaction_event streaming event emitted after successful compaction cycle

## Architecture Anchors

- `architecture/decisions/ADR-019-rolling-context-compaction.md` — Decision 1 (CompactionTrigger enum, CompactionPolicy trait, ConversationSnapshot, CompactionSummary types in core::budget), Decision 2 (BudgetConfig extensions)
- `architecture/module-decomposition.md` — SS-10, `pregolya-core / core::budget` (definitions); `pregolya-graph / graph::budget` (engine)
- `architecture/verification-architecture.md` — VP-012 (D23 candidate)

## Story Anchor

S-1.25

## VP Anchors

- VP-012 (assigned in VP-INDEX as VP-012 — Kani P1; pregolya-core `watermark_arithmetic_harness`)
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
| VP Registration | VP-012 (assigned in VP-INDEX as VP-012 — Kani P1; pregolya-core `watermark_arithmetic_harness`) |
| Module | pregolya-core / core::budget (definitions) |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + Kani (VP-012) |
