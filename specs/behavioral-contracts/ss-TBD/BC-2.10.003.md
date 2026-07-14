---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.003
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-TBD
capability: CAP-012
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-012
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "e4e989dd90846726d103e98fe154892ab82df5be62f1b85dfb75a2ee565cba9c"
---

# BC-2.10.003: Graceful Halt When Budget Ceiling Reached (on_ceiling = halt)

## Description

When a `BudgetPolicy::evaluate` call returns `PolicyDecision::Deny` and the policy's
`on_ceiling` mode is `halt`, the execution engine completes all in-flight tasks for the
current super-step, writes their outputs to the checkpoint via `put_writes`, then stops
the run — making no further LLM calls or tool invocations. The run transitions to `failed`
with a structured `FerrochainError { category: BudgetExceeded, code: "E-BUDGET-001" }`.
The checkpoint at the last completed super-step is preserved and retrievable. The Domain B
dark-factory holdout evaluation shape 6 ("budget-bounded run") directly exercises this BC.

## Preconditions

1. A `BudgetPolicy` with `on_ceiling = halt` is configured in the `RunConfig`.
2. A `BudgetPolicy::evaluate` call has returned `PolicyDecision::Deny` after an LLM call
   or tool invocation.
3. The execution engine is currently at an evaluation point (post-LLM-call or
   post-tool-invocation) within a super-step.

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
   `FerrochainError { component: Graph, category: BudgetExceeded, code: "E-BUDGET-001",
   message: "run halted: budget ceiling reached", retry_hint: Never }`.
6. The caller (`invoke` or `stream`) receives `Err(E-BUDGET-001 BudgetCeilingReached)` with
   the `current_usage: TokenUsage` and `policy_name` fields in the error context.
7. The checkpoint at the last fully-completed super-step is preserved with `status = failed`.
   It is resumable in principle (same `thread_id`, different `run_id`) if the operator
   supplies a new `RunConfig` with a higher ceiling.

## Invariants

- Graceful, not panic: the halt path must NOT call `.unwrap()`, `.expect()`, or `panic!()`.
  All errors propagate via `Result<_, FerrochainError>` (DI-008).
- No new LLM calls or tool invocations after a `Deny` decision — no "one more call"
  exceptions or continuation-on-error fallbacks.
- The checkpoint preserved at halt time must be consistent: it reflects exactly the state
  at the last fully-applied super-step boundary, not a partial mid-step state.
- The `E-BUDGET-001` error carries a `retry_hint: Never` because retrying the same run
  without changing the budget ceiling would immediately re-hit the ceiling.

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
| TV-001 | Graph with 3 LLM nodes; BudgetPolicy halt at 10k tokens; tokens accumulate to 12k on 3rd call | Run fails after 3rd node; caller receives `Err(E-BUDGET-001)`; checkpoint preserved after step 2 | Happy path — ceiling hit on 3rd call |
| TV-002 | Same graph; budget ceiling hit on 1st LLM call (oversize prompt) | Run fails after step 1; caller receives `Err(E-BUDGET-001)`; journal has 1 entry `decision: Deny` | Ceiling on first call |
| TV-003 | 3 concurrent tasks in step 2; 1st task triggers Deny | All 3 tasks complete their in-flight work; `put_writes` for all 3; run fails; no step 3 scheduled | Mid-super-step Deny — all in-flight tasks finish |
| TV-004 | Operator re-runs halted thread with new RunConfig (higher ceiling) | New run starts from the preserved checkpoint; runs to completion | Halted checkpoint is resumable |
| TV-005 | Sub-agent hits ceiling; parent node receives `Err(E-BUDGET-001)` from sub-agent | Parent node handles error and logs it; parent run continues with remaining budget | Sub-agent halt does not auto-halt parent |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BUDGET-04 | Halt path: no new LLM calls after Deny; `put_writes` called for all in-flight tasks; run transitions to `failed` with `E-BUDGET-001` | Integration test — mock LLM call counter; assert count does not increase after Deny; assert checkpoint state | Phase 1 |

## Related BCs

- BC-2.10.001 — depends on: `PolicyDecision::Deny` returned by `BudgetPolicy::evaluate` triggers this BC
- BC-2.10.002 — composes with: `JournalEntry` with `decision: Deny` is written before halt executes
- BC-2.10.004 — related to: `on_ceiling = escalate` is the alternative to `on_ceiling = halt` (specified there)
- BC-2.04.001 — related to: `put_writes` per-task durability applies in the halt path (tasks that completed before Deny have their writes preserved)

## Architecture Anchors

- `ferrochain-graph/src/pregel/loop.rs` — halt path in `tick()`: after `Deny` decision, no new task scheduling; allow in-flight tasks to settle; call `put_writes`; transition run to `failed`
- `ferrochain-graph/src/pregel/errors.rs` — `FerrochainError` variant for `E-BUDGET-001 BudgetCeilingReached`
- `ferrochain-graph/src/budget/policy.rs` — `BudgetPolicy::on_ceiling` field: `OnCeiling::Halt | OnCeiling::Escalate`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BUDGET-04

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-012 |
| Capability Anchor Justification | CAP-012 ("Budget Governance (Allow / Escalate / Deny; Cost Metering)") per capabilities-p1-p2.md §CAP-012 — this BC specifies the "degrade gracefully: halt the run" behavior named in the "when the ceiling is reached, degrade gracefully" clause of CAP-012 |
| L2 Domain Invariants | — |
| D17 Commitment | D17-Q4 — Domain B dark-factory holdout evaluation shape 6 ("give a run a token/cost ceiling; verify it meters spend across sub-agents and halts-or-degrades gracefully at the ceiling") directly exercises this BC |
| ADAPT Reference | adk-rust P-73 `deny(hard-stop)` variant of `PaymentPolicyGuardrail` as structural analog |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | [architect to assign — ferrochain-graph] |
