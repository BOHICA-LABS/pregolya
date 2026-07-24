---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.003
version: "1.9"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-10
capability: CAP-012
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-61): F-P61-01 (HIGH) — ADR-009 Option-3 trait-in-core split propagated. Architecture Anchors: BudgetPolicy::on_ceiling anchor moved from ferrochain-graph/src/budget/policy.rs to ferrochain-core/src/budget.rs (OnCeiling type is a policy definition, per ADR-009 Option 3). Module field resolved: ferrochain-core (BudgetPolicy + OnCeiling types) / ferrochain-graph (halt path in pregel loop)."
  - "1.2 (D20 sub-burst 1, 2026-07-15): Add OnCeiling::Summarize variant behavior (PCs 4+8, EC-005, TV-006) and remaining-budget exposure via RunContext.budget_info (PC5, TV-007) per D20 orchestrator adjudication items (2) stop-and-summarize and (2) remaining-budget exposure."
  - "1.3 (pass-72 fix, 2026-07-15): F-P72-05 — VP Anchors section missing VP-BUDGET-05 and VP-BUDGET-06 (both added in v1.2 Verification Properties table but not propagated to VP Anchors). Added VP-BUDGET-05 and VP-BUDGET-06 to VP Anchors section."
  - "1.4 (2026-07-15, F-P78-SWEEP/D18-P78-A): E-BUDGET-001 message-prefix correction. PC5: added 'BudgetCeilingReached:' prefix to message string (was 'run halted: budget ceiling reached'; now 'BudgetCeilingReached: run halted: budget ceiling reached'). Taxonomy E-BUDGET-001 corrected from elaborate 'run <run_id> halted; token budget of <limit> exceeded at <actual> tokens' to 'BudgetCeilingReached: run halted: budget ceiling reached' (BC wins on content)."
  - "1.5 (F-P91-01, 2026-07-17): Attribute on_ceiling to BudgetConfig struct (not BudgetPolicy trait) per interface-definitions v2.29 §BudgetConfig. Description: 'policy\\'s on_ceiling mode is halt' → 'BudgetConfig::on_ceiling is OnCeiling::Halt'. PC1: 'BudgetPolicy with on_ceiling = halt ... in RunnableConfig' → 'BudgetConfig with on_ceiling = OnCeiling::Halt ... in GraphConfig.budget_config'. PC4 (Summarize variant): same correction (BudgetPolicy → BudgetConfig; RunnableConfig → GraphConfig.budget_config). PC5 (remaining-budget): 'BudgetPolicy is active' → 'BudgetConfig is active'. Architecture Anchor: 'BudgetPolicy::on_ceiling field' → 'BudgetConfig::on_ceiling field'. on_ceiling is a data field on BudgetConfig; BudgetPolicy::evaluate is pure and data-free (interface-definitions v2.29 §Engine branching note + ADR-009 Option 3)."
  - "1.6 (F-P92-01/F-P92-02, 2026-07-17): F-P92-01 — two residual BudgetPolicy-owns-data attributions corrected in canonical test vectors. TV-001 Input: 'BudgetPolicy halt at 10k tokens' → 'BudgetConfig { on_ceiling: OnCeiling::Halt, hard_limit: Some(10_000) }'. TV-007 Input: 'BudgetPolicy with token ceiling = 10000' → 'BudgetConfig with hard_limit = Some(10_000)'. F-P92-02 — precision updates per architect D18-P92-A: PC7 ceiling reference expanded to full field path ('supplies a new RunnableConfig with budget_config: Some(BudgetConfig { hard_limit: Some(higher_ceiling), .. })'); TV-004 Notes column expanded to name the field path ('new RunnableConfig carries budget_config: Some(BudgetConfig { hard_limit: Some(N) })') per interface-definitions v2.31 §RunnableConfig."
  - "1.7 (F-P93-04, 2026-07-17): VP ID collision resolved. BC-2.10.003 and BC-2.10.004 both defined VP-BUDGET-05 with different semantics. Resolution per append-only-numbering policy: BC-2.10.004's VP-BUDGET-05 (Phase 1, older) is canonical; BC-2.10.003's Summarize-path VP-BUDGET-05 renumbered → VP-BUDGET-07 (next free after VP-BUDGET-06). VP Anchors updated: VP-BUDGET-04, VP-BUDGET-05, VP-BUDGET-06 → VP-BUDGET-04, VP-BUDGET-06, VP-BUDGET-07. Zero VP-BUDGET-NN collisions across SS-10 after this change."
  - "1.8 (F-P97-05, 2026-07-17): VP table Phase-column axis normalized. VP-BUDGET-06 and VP-BUDGET-07 'Wave 1' corrected to 'Phase 1' to match the SS-10 convention established by VP-BUDGET-01/02/04/05 (all Phase 1). The v1.2 additions used the wave axis; the column carries the VSDD pipeline phase, not the wave. No behavioral change."
  - "1.9 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-012
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "cf63c3a"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.003: Graceful Halt When Budget Ceiling Reached (on_ceiling = halt | summarize); Remaining-Budget Exposure

## Description

When a `BudgetPolicy::evaluate` call returns `PolicyDecision::Deny` and the configured
`BudgetConfig::on_ceiling` is `OnCeiling::Halt`, the execution engine completes all in-flight
tasks for the current super-step, writes their outputs to the checkpoint via `put_writes`, then stops
the run — making no further LLM calls or tool invocations. The run transitions to `failed`
with a structured `FerrochainError { component: BUDGET, category: POLICY, code: "E-BUDGET-001" }`.
The checkpoint at the last completed super-step is preserved and retrievable. The Domain B
dark-factory holdout evaluation shape 6 ("budget-bounded run") directly exercises this BC.

**v1.2 additions:** (a) `OnCeiling::Summarize { summarize_prompt: String }` variant — on
`Deny`, the engine injects one final LLM call using `summarize_prompt` as a `HumanMessage`
and returns the model's response as the run output with status `summary_halt`. (b)
`RunContext.budget_info: BudgetInfo` carries `tokens_remaining` and `steps_remaining` at
each super-step boundary, allowing model nodes to adapt their strategy as budget runs low.

## Preconditions

1. A `BudgetConfig` with `on_ceiling = OnCeiling::Halt` is configured in `GraphConfig.budget_config`.
2. A `BudgetPolicy::evaluate` call has returned `PolicyDecision::Deny` after an LLM call
   or tool invocation.
3. The execution engine is currently at an evaluation point (post-LLM-call or
   post-tool-invocation) within a super-step.
4. *(Summarize variant)* `BudgetConfig` with `on_ceiling = OnCeiling::Summarize { summarize_prompt: String }` is configured in `GraphConfig.budget_config`. The `summarize_prompt` is a non-empty string injected as a `HumanMessage` before the final LLM call.
5. *(Remaining-budget exposure)* A `BudgetConfig` is active (any `on_ceiling` variant). `graph::budget_engine` populates `RunContext.budget_info: BudgetInfo { tokens_remaining: Option<i64>, steps_remaining: Option<u32> }` at each super-step boundary before dispatching tasks.

## Postconditions

1. The execution engine does NOT schedule any further LLM calls or tool invocations for
   this run after the `Deny` decision is received.
2. In-flight tasks for the current super-step are allowed to complete their current work
   unit (the LLM call or tool call that triggered the evaluation is already done; no new
   calls are started).
3. `put_writes` is called for every completed task in the current super-step (DI-002 —
   per-task durability applies even in the halt path).
4. A `JournalEntry` with `decision: Deny` is written to the `EvidenceJournal` before the
   run transitions to `failed` (BC-2.10.002).
5. The run transitions to status `failed` with error:
   `FerrochainError { component: BUDGET, category: POLICY, code: "E-BUDGET-001",
   message: "BudgetCeilingReached: run halted: budget ceiling reached", retry_hint: Never }`.
6. The caller (`invoke` or `stream`) receives `Err(E-BUDGET-001 BudgetCeilingReached)` with
   the `current_usage: TokenUsage` and `policy_name` fields in the error context.
7. The checkpoint at the last fully-completed super-step is preserved with `status = failed`.
   It is resumable in principle (same `thread_id`, different `run_id`) if the operator
   supplies a new `RunnableConfig` with `budget_config: Some(BudgetConfig { hard_limit: Some(higher_ceiling), .. })`.
8. *(Summarize variant — `on_ceiling = OnCeiling::Summarize`)* When `PolicyDecision::Deny`
   is received: (a) In-flight tasks for the current super-step are allowed to settle (same
   as halt). (b) One final LLM call is issued with `summarize_prompt` appended as a
   `HumanMessage` to the current conversation context. (c) The model's response is returned
   as the run's final output. (d) The run transitions to status `summary_halt` (not
   `failed`). (e) A `JournalEntry { decision: Deny, mode: Summarize }` is written to the
   `EvidenceJournal` (BC-2.10.002) before the summarize LLM call is issued. (f) If the
   summarize LLM call itself triggers a new `PolicyDecision::Deny`, the run falls back to
   halt semantics (EC-005): `Err(E-BUDGET-001 BudgetCeilingReached)` with `status = failed`.
9. *(Remaining-budget exposure)* `RunContext.budget_info` is populated by `graph::budget_engine`
   at each super-step boundary: `tokens_remaining: Some(ceiling - accumulated_tokens)` (may
   be negative if Deny was just triggered); `steps_remaining: Some(recursion_limit - current_step)`.
   Values are `None` when the corresponding budget dimension is not configured. Graph nodes
   may read `budget_info` from `RunContext` and inject it into model prompts to allow the
   model to adapt its strategy as budget decreases.

## Invariants

- Graceful, not panic: the halt path must NOT call `.unwrap()`, `.expect()`, or `panic!()`.
  All errors propagate via `Result<_, FerrochainError>` (DI-008).
- No new LLM calls or tool invocations after a `Deny` decision — no "one more call"
  exceptions or continuation-on-error fallbacks.
- The checkpoint preserved at halt time must be consistent: it reflects exactly the state
  at the last fully-applied super-step boundary, not a partial mid-step state.
- The `E-BUDGET-001` error carries a `retry_hint: Never` because retrying the same run
  without changing the budget ceiling would immediately re-hit the ceiling.
- The Summarize path invokes exactly **1** additional LLM call. If that call also returns
  a `Deny`, the run falls back to halt semantics (E-BUDGET-001, `status = failed`). No
  recursive summarize attempt is made.
- `budget_info.tokens_remaining` is of type `Option<i64>` (signed) because it may be
  negative at the moment a Deny is triggered (the ceiling was exceeded on the current call).
  Arithmetic: for a ceiling `C` (in tokens, `C > 0`) and accumulated usage `U` (in tokens,
  `U >= 0`), `tokens_remaining = C - U as i64`. When `U > C`, `tokens_remaining < 0`.

## Edge Cases

### EC-001: Deny triggered mid-super-step (multiple in-flight tasks)
**Scenario:** A super-step has 3 tasks executing concurrently. Task 1 completes and triggers
a `Deny` decision. Tasks 2 and 3 are still in-flight.
**Expected behavior:** Tasks 2 and 3 are allowed to complete their current work unit (no
cancellation of in-flight async tasks). After all 3 tasks complete, `put_writes` is called
for all 3. No new super-step is started. The run transitions to `failed` after all in-flight
tasks are settled.

### EC-002: Deny on the very first LLM call (over-allocated starting state)
**Scenario:** The initial `TokenUsage` snapshot already exceeds the ceiling (e.g., the
input prompt is larger than the budget allows).
**Expected behavior:** The run halts after the first LLM call without executing any further
nodes. The caller receives `Err(E-BUDGET-001)`. The journal records the `Deny` decision at
`evaluation_point: AfterLlmCall` for step 1, node 1.

### EC-003: Halt path writes fail (storage I/O error during put_writes)
**Scenario:** After a `Deny` decision, the `put_writes` call to checkpoint the final
super-step's outputs fails with an I/O error.
**Expected behavior:** `Err(E-CHKPT-001 CheckpointWriteFailed)` is returned (taking
precedence over the budget error). The run state is `failed` for both reasons. The
`EvidenceJournal` entry for the `Deny` decision was already written (journal write precedes
`put_writes` in the halt sequence); the journal entry survives even if checkpoint write fails.

### EC-005: Summarize prompt itself triggers Deny (recursive budget exhaustion)
**Scenario:** `on_ceiling = Summarize`; budget `Deny` received on step 3; summarize LLM
call is issued; that call's token usage also triggers `PolicyDecision::Deny` from
`BudgetPolicy::evaluate`.
**Expected behavior:** The summarize LLM call result is discarded. The run transitions to
`failed` with `Err(E-BUDGET-001 BudgetCeilingReached)` (halt semantics). No recursive
summarize attempt. The `JournalEntry` for the original `Deny` is preserved.

### EC-004: Sub-agent run hits its ceiling; parent run continues
**Scenario:** A nested sub-agent run has `on_ceiling = halt` and hits its Deny at 10k tokens.
The parent run has a separate policy with a 200k ceiling (not yet reached).
**Expected behavior:** The sub-agent run returns `Err(E-BUDGET-001)` to the parent run's
node that invoked it. The parent node can choose to handle the error (log and continue),
propagate it, or trigger its own escalation. The parent run is not automatically halted by
the sub-agent's halt.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Graph with 3 LLM nodes; `BudgetConfig { on_ceiling: OnCeiling::Halt, hard_limit: Some(10_000) }`; tokens accumulate to 12k on 3rd call | Run fails after 3rd node; caller receives `Err(E-BUDGET-001)`; checkpoint preserved after step 2 | Happy path — ceiling hit on 3rd call |
| TV-002 | Same graph; budget ceiling hit on 1st LLM call (oversize prompt) | Run fails after step 1; caller receives `Err(E-BUDGET-001)`; journal has 1 entry `decision: Deny` | Ceiling on first call |
| TV-003 | 3 concurrent tasks in step 2; 1st task triggers Deny | All 3 tasks complete their in-flight work; `put_writes` for all 3; run fails; no step 3 scheduled | Mid-super-step Deny — all in-flight tasks finish |
| TV-004 | Operator re-runs halted thread with new RunnableConfig (higher ceiling) | New run starts from the preserved checkpoint; runs to completion | Halted checkpoint is resumable; new `RunnableConfig` carries `budget_config: Some(BudgetConfig { hard_limit: Some(N) })` (interface-definitions v2.31 §RunnableConfig) |
| TV-005 | Sub-agent hits ceiling; parent node receives `Err(E-BUDGET-001)` from sub-agent | Parent node handles error and logs it; parent run continues with remaining budget | Sub-agent halt does not auto-halt parent |
| TV-006 | `on_ceiling = Summarize { summarize_prompt: "Summarize your findings." }`; budget ceiling hit on step 3; model responds to summarize prompt with "I found X." | Run output = "I found X."; run `status = summary_halt`; `JournalEntry { decision: Deny, mode: Summarize }` written | Summarize variant happy path |
| TV-007 | `BudgetConfig` with `hard_limit = Some(10_000)`; after step 1 accumulated = 3000 tokens; `recursion_limit = 25`; node reads `RunContext.budget_info` | `budget_info.tokens_remaining = Some(7000)`; `budget_info.steps_remaining = Some(24)` | Remaining-budget exposure; arithmetic: `10000 - 3000 = 7000`; `25 - 1 = 24` |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BUDGET-04 | Halt path: no new LLM calls after Deny; `put_writes` called for all in-flight tasks; run transitions to `failed` with `E-BUDGET-001` | Integration test — mock LLM call counter; assert count does not increase after Deny; assert checkpoint state | Phase 1 |
| VP-BUDGET-07 | Summarize path: exactly 1 additional LLM call issued after Deny; model response returned as `summary_halt` output; recursive Deny falls back to halt | Integration test — mock LLM call counter; assert 1 summarize call; assert run status | Phase 1 |
| VP-BUDGET-06 | `RunContext.budget_info.tokens_remaining` decreases monotonically across super-steps; `steps_remaining` decreases by 1 per super-step | Unit test — assert budget_info values at steps 1, 2, 3 | Phase 1 |

## Related BCs

- BC-2.10.001 — depends on: `PolicyDecision::Deny` returned by `BudgetPolicy::evaluate` triggers this BC
- BC-2.10.002 — composes with: `JournalEntry` with `decision: Deny` is written before halt executes
- BC-2.10.004 — related to: `on_ceiling = escalate` is the alternative to `on_ceiling = halt` (specified there)
- BC-2.04.001 — related to: `put_writes` per-task durability applies in the halt path (tasks that completed before Deny have their writes preserved)

## Architecture Anchors

- `ferrochain-graph/src/scheduler.rs` (`graph::scheduler`) — halt path in `tick()`: after `Deny` decision, no new task scheduling; allow in-flight tasks to settle; call `put_writes`; transition run to `failed`; Summarize path: inject `HumanMessage(summarize_prompt)`, issue one final LLM call, return `summary_halt` result; budget_info population at each super-step boundary
- `ferrochain-graph/src/budget.rs` (`graph::budget`) — `FerrochainError` variant for `E-BUDGET-001 BudgetCeilingReached`
- `ferrochain-core/src/budget.rs` — `BudgetConfig::on_ceiling` field: `OnCeiling::Halt | OnCeiling::Escalate | OnCeiling::Summarize { summarize_prompt: String }` (per ADR-009 Option 3 and interface-definitions v2.29 §BudgetConfig); `BudgetInfo { tokens_remaining: Option<i64>, steps_remaining: Option<u32> }` struct; `RunContext.budget_info: BudgetInfo` field (v1.2 addition)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BUDGET-04, VP-BUDGET-06, VP-BUDGET-07

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-012 |
| Capability Anchor Justification | CAP-012 ("Budget Governance (Allow / Escalate / Deny; Cost Metering)") per capabilities-p0.md §CAP-012 — this BC specifies the "degrade gracefully: halt the run" behavior named in the "when the ceiling is reached, degrade gracefully" clause of CAP-012 |
| L2 Domain Invariants | — |
| D17 Commitment | D17-Q4 — Domain B dark-factory holdout evaluation shape 6 ("give a run a token/cost ceiling; verify it meters spend across sub-agents and halts-or-degrades gracefully at the ceiling") directly exercises this BC |
| D20 Addition | v1.2: `OnCeiling::Summarize` + `RunContext.budget_info` per D20 orchestrator adjudication (stop-and-summarize on budget exhaustion + remaining-budget exposure); domain-d-hermes-agent.md req 2 — "stop-and-summarize graceful degradation mode" and "budget exposed to model mid-run" |
| ADAPT Reference | adk-rust P-73 `deny(hard-stop)` variant of `PaymentPolicyGuardrail` as structural analog |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-core (BudgetPolicy + OnCeiling types) / ferrochain-graph (halt path in graph::scheduler / graph::budget) |
