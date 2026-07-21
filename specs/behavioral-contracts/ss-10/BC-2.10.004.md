---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.004
version: "1.6"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-10
capability: CAP-012
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-61): F-P61-01 (HIGH) — ADR-009 Option-3 propagation. Module field resolved from stale placeholder. All Architecture Anchor crate references already correct per ADR-009 split (BudgetEscalation/BudgetResume types + journal stay in ferrochain-graph as dispatch/escalation artifacts, not policy definitions)."
  - "1.2 (F-P91-01, 2026-07-17): Attribute on_ceiling to BudgetConfig struct (not BudgetPolicy trait) per interface-definitions v2.29 §BudgetConfig. Description: 'policy\\'s on_ceiling mode is escalate' → 'BudgetConfig::on_ceiling is OnCeiling::Escalate'. PC1: 'BudgetPolicy with on_ceiling = escalate ... in RunnableConfig' → 'BudgetConfig with on_ceiling = OnCeiling::Escalate ... in GraphConfig.budget_config'. TV-001: same BudgetConfig attribution + OnCeiling::Escalate enum form. EC-001: 'on_ceiling = escalate' → 'BudgetConfig::on_ceiling = OnCeiling::Escalate'. on_ceiling is a data field on BudgetConfig; BudgetPolicy::evaluate is pure and data-free (interface-definitions v2.29 §Engine branching note + ADR-009 Option 3)."
  - "1.3 (F-P92-01, 2026-07-17): PC6 BudgetResume::Extend ceiling-application mechanism corrected per interface-definitions v2.31 §RunnableConfig struct definition and architect adjudication D18-P92-A. Old: 'The new_ceiling replaces the policy\\'s current ceiling in the RunnableConfig for the resumed execution.' New: 'The new_ceiling is applied by patching RunnableConfig::budget_config with BudgetConfig { hard_limit: Some(new_ceiling), ..original } for the resumed execution.' Ceiling is applied via the budget_config field on RunnableConfig — not by mutating BudgetPolicy. GraphConfig::budget_config is shared across concurrent runs and must not be mutated per-resume."
  - "1.4 (F-P93-02/F-P93-03, 2026-07-17): F-P93-02 (HIGH) — BC corrected to reflect Model A canon (interface-definitions.md v2.33 §PolicyDecision×on_ceiling decision table): `PolicyDecision::Escalate` (soft-limit) ALWAYS triggers HITL interrupt unconditionally, `on_ceiling` NOT consulted; `PolicyDecision::Deny` + `on_ceiling=OnCeiling::Escalate` (hard-ceiling) ALSO routes to this same HITL interrupt mechanism. (a) H1 title updated to name both paths. (b) Description first sentence revised: soft-path Escalate → unconditional HITL; additionally Deny+OnCeiling::Escalate → same HITL path. (c) PC1 renamed PC1a (hard-ceiling config path) + PC1b added (OR: Deny returned + on_ceiling=Escalate). (d) PC2 labeled '(Soft-ceiling path)' + PC2b added '(Hard-ceiling path)' for Deny+on_ceiling=Escalate trigger. (e) TV-001b added: on_ceiling=Halt + soft_limit crossed → Escalate → HITL fires (proves on_ceiling not consulted for the Escalate path). F-P93-03 (MED) — Capability Anchor Justification verbatim CAP-012 quote updated to v1.2 text: old 'the policy\\'s `on_ceiling` setting' → new 'the budget configuration\\'s `on_ceiling` setting (`BudgetConfig::on_ceiling`)' per capabilities-p0.md v1.2."
  - "1.5 (F-P94-02, 2026-07-17): Convention verdict: renumber TV-001b → TV-006 to eliminate the corpus's only lettered sub-vector and restore unambiguous TV-NNN sequential numbering throughout. TV-001b removed from between TV-001 and TV-002; appended as TV-006 at end of table. Notes text unchanged. test-vectors.md BC-2.10.004 row updated 5→6 (v1.8). No other TV-001b references found in corpus (sweep performed)."
  - "1.6 (F-P95-03 + coordinator CAP-012-v1.3 update, 2026-07-17): (a) Preconditions restructured: malformed 1a/1b/2/2b numbering (PC1b and PC2b were verbatim duplicates of the Deny+on_ceiling=Escalate trigger; no plain PC1 existed) replaced with clean PC1 (config context: BudgetConfig active in GraphConfig.budget_config), PC2 (trigger — two alternatives: soft-ceiling path Escalate + `on_ceiling` NOT consulted; OR hard-ceiling path Deny + on_ceiling=OnCeiling::Escalate). PC3 and PC4 (CheckpointSaver, evaluation point) unchanged in content, renumbered from 3 and 4 (were already correct ordinals, now references are cleaned). One statement of the Deny+Escalate trigger total. (b) Capability Anchor Justification updated to CAP-012 v1.3 verbatim: old quote used two-mode 'halt the run, or escalate to a HITL interrupt' text; new quote enumerates all three modes per v1.3: 'halt the run, escalate to a HITL interrupt, or issue a final summarize call (summary_halt), according to the budget configuration\\'s `on_ceiling` setting (`BudgetConfig::on_ceiling` — `OnCeiling::Halt | Escalate | Summarize`)'. Cite sweep: BC-2.10.001 v1.4→v1.5 updated 'PC1b/PC2b' references → 'PC2 (hard-ceiling path)' (lines 79+151)."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-012
  - domain-spec/capabilities-p0.md#CAP-006
  - domain-spec/invariants.md#DI-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/comparative/adk-rust/behavioral-intent.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "01ed52f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.10.004: Budget Escalation to HITL Interrupt (Soft-Limit Escalate Path and Hard-Ceiling on_ceiling=Escalate Path)

## Description

When a `BudgetPolicy::evaluate` call returns `PolicyDecision::Escalate`, the execution engine
suspends the run via the same `interrupt()` mechanism used by standard HITL interrupts
(BC-2.05.001). Additionally, when `PolicyDecision::Deny` is returned and the configured
`BudgetConfig::on_ceiling` is `OnCeiling::Escalate`, the engine also routes to this HITL
mechanism instead of the halt path. The interrupt payload
carries a typed `BudgetEscalation` context (current usage, ceiling, policy name, reason).
The run parks in `interrupted` status, durably checkpointed, until a human or orchestrator
resumes it via `Command(resume = BudgetResume::Extend { new_ceiling } | BudgetResume::Halt)`.
The `EvidenceJournal` records both the escalation and the resume decision. DI-003 applies:
the resume value is consumed FIFO and the interrupted node re-executes from its super-step start.

## Preconditions

1. A `BudgetConfig` is configured in `GraphConfig.budget_config`.
2. *(Trigger — exactly one of two paths holds):*
   - **(Soft-ceiling path)** A `BudgetPolicy::evaluate` call has returned
     `PolicyDecision::Escalate` after an LLM call or tool invocation —
     `BudgetConfig::on_ceiling` is NOT consulted for this path (see
     interface-definitions v2.33 "any — not consulted" row).
   - **(Hard-ceiling path)** A `BudgetPolicy::evaluate` call has returned
     `PolicyDecision::Deny` and `BudgetConfig::on_ceiling` = `OnCeiling::Escalate`.
3. A `CheckpointSaver` is attached to the graph (an interrupt without a checkpointer is a
   precondition violation — same as BC-2.05.001 EC-001).
4. The execution engine is currently at an evaluation point within a super-step.

## Postconditions

1. The execution engine triggers `interrupt(BudgetEscalation { current_usage, ceiling, policy_name, reason })` via the standard interrupt mechanism.
2. The interrupt payload is pushed to the per-task scratchpad (FIFO slot) as per DI-003 and BC-2.05.001 postcondition 2.
3. A checkpoint is written with the INTERRUPT marker and the `BudgetEscalation` payload before
   the run suspends (sync durability tier, DI-002). The checkpoint write completes before the
   caller receives the interrupt notification.
4. The run transitions to `interrupted` status; the caller receives:
   `{"__interrupt__": [InterruptPayload { value: BudgetEscalation { ... }, interrupt_id }]}`.
5. A `JournalEntry` with `decision: Escalate` and the `BudgetEscalation` context is appended
   to the `EvidenceJournal` before the interrupt is raised (BC-2.10.002).
6. On resume via `Command(resume = BudgetResume::Extend { new_ceiling })`:
   - The `new_ceiling` is applied by patching `RunnableConfig::budget_config` with
     `BudgetConfig { hard_limit: Some(new_ceiling), ..original }` for the resumed execution.
   - The interrupted node re-executes from the start of its super-step (DI-003).
   - A `JournalEntry` recording the resume decision and new ceiling is appended.
   - Execution continues under the extended ceiling.
7. On resume via `Command(resume = BudgetResume::Halt)`:
   - The run halts gracefully (same behavior as BC-2.10.003 postconditions 3–7).
   - A `JournalEntry` recording the halt decision is appended.

## Invariants

- **DI-003 (HITL FIFO Resume-Value Delivery):** The budget escalation interrupt participates
  in the FIFO resume-value queue alongside any other concurrent interrupts. If multiple
  interrupts are pending, resume values are consumed in strict FIFO order.
- The `BudgetEscalation` interrupt uses the same `put_writes` / INTERRUPT-marker checkpoint
  mechanism as all other interrupts (BC-2.05.001). No special-case checkpoint path exists.
- A budget escalation without a `CheckpointSaver` is a hard precondition violation, identical
  to BC-2.05.001 EC-001. The error returned is `Err(E-GRAPH-016 InterruptWithoutCheckpointer)`.
- After resume with `Extend`, the resumed execution is subject to the same budget policy
  evaluation — the extended ceiling takes effect immediately for the next evaluation call.
  If the extended ceiling is still lower than current usage, the next evaluation immediately
  escalates again (the run does not get unlimited budget by virtue of resuming).

## Edge Cases

### EC-001: Budget escalation without a CheckpointSaver
**Scenario:** A graph with `BudgetConfig::on_ceiling = OnCeiling::Escalate` runs without a `CheckpointSaver`.
**Expected behavior:** On the first `PolicyDecision::Escalate`, the engine returns
`Err(E-GRAPH-016 InterruptWithoutCheckpointer)` rather than raising an interrupt without
durable state. The run transitions to `failed`.

### EC-002: Escalation and an existing `interrupt()` call are both pending
**Scenario:** Node B called `interrupt("review_this")` in slot 0. Node C triggered a budget
escalation in slot 1. Both are in the FIFO queue.
**Expected behavior:** Slot 0 (`interrupt("review_this")`) is consumed first on resume.
Slot 1 (BudgetEscalation) is consumed second in the next resume round. FIFO order is strict
per DI-003 regardless of interrupt source.

### EC-003: Human resumes with a new_ceiling still below current usage
**Scenario:** Run has accumulated 120k tokens. Policy ceiling is 100k (escalated). Human
resumes with `BudgetResume::Extend { new_ceiling: 110k }`. New ceiling (110k) < current
usage (120k).
**Expected behavior:** The resumed execution evaluates the budget policy immediately after
the resumed node's first LLM call. If usage is still 120k > 110k, the policy returns
`PolicyDecision::Escalate` again immediately. The run re-escalates on the next evaluation.
The journal records the re-escalation. No infinite-escalation loop occurs between evaluation
calls (each escalation requires a new resume action from the human).

### EC-004: Process restart after budget escalation interrupt is durably parked
**Scenario:** A budget escalation interrupt is durably checkpointed (INTERRUPT marker written).
The process crashes. On restart, the operator reloads the `CheckpointSaver`.
**Expected behavior:** The checkpointer surfaces the INTERRUPT-marker checkpoint with the
`BudgetEscalation` payload. The engine recognizes the thread as requiring action. The run
is not re-executed from scratch; it is resumable via `Command(resume = BudgetResume::Extend
{ ... } | BudgetResume::Halt)`.

### EC-005: Sub-agent escalation propagates to parent
**Scenario:** A sub-agent run escalates (interrupted). The parent run is waiting for the
sub-agent's result.
**Expected behavior:** The sub-agent's interrupt is visible to the parent graph via the
sub-agent node returning an `interrupt` outcome. The parent can route via a conditional edge
to a HITL approval node or propagate the interrupt. Sub-agent escalation does not silently
block the parent — it surfaces as an explicit result.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | BudgetConfig `on_ceiling = OnCeiling::Escalate, soft_limit = 10k`; run accumulates 12k tokens on 3rd LLM call | Run transitions to `interrupted`; caller receives `{"__interrupt__": [BudgetEscalation { ... }]}`; checkpoint with INTERRUPT marker written | Happy path — escalation triggered |
| TV-002 | Resume with `BudgetResume::Extend { new_ceiling: 50k }` after TV-001 | Interrupted node re-executes from super-step start; new ceiling 50k is active; execution continues; journal records Extend decision | Resume with extended ceiling |
| TV-003 | Resume with `BudgetResume::Halt` after TV-001 | Run halts gracefully; same behavior as BC-2.10.003; journal records Halt decision | Resume with halt decision |
| TV-004 | Process crash after INTERRUPT-marker checkpoint; restart; resume with Extend | On restart, run is in `interrupted`; `Command(resume = Extend { ... })` resumes from correct checkpoint | Durable escalation across restart — DI-003 |
| TV-005 | Budget escalation while a prior `interrupt("review")` is in FIFO slot 0 | Resume 1: `interrupt("review")` consumed; Resume 2: `BudgetEscalation` consumed (FIFO per DI-003) | FIFO ordering across interrupt sources |
| TV-006 | BudgetConfig `on_ceiling = OnCeiling::Halt, soft_limit = 10k`; run accumulates 12k tokens on 3rd LLM call (triggers `PolicyDecision::Escalate` at soft limit) | Run transitions to `interrupted`; caller receives `{"__interrupt__": [BudgetEscalation { ... }]}`; checkpoint with INTERRUPT marker written — `on_ceiling = Halt` is NOT consulted for the `Escalate` path | Proves Model A canon: `PolicyDecision::Escalate` → HITL unconditionally regardless of `on_ceiling` value (interface-definitions v2.33 "any — not consulted" row) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BUDGET-05 | Budget escalation uses identical interrupt mechanism to BC-2.05.001; checkpoint with INTERRUPT marker is written before caller receives interrupt notification; resume with Extend continues from correct super-step | Integration test — escalate, checkpoint-assert, process-restart, resume-with-extend, assert-continuation | Phase 1 |

## Related BCs

- BC-2.10.001 — depends on: `PolicyDecision::Escalate` returned by `BudgetPolicy::evaluate` triggers this BC
- BC-2.10.002 — composes with: `JournalEntry` with `decision: Escalate` and resume-decision entries are written
- BC-2.10.003 — related to: `on_ceiling = halt` is the alternative (specified there); on `BudgetResume::Halt`, this BC delegates to BC-2.10.003 postconditions
- BC-2.05.001 — depends on: the interrupt and durable-state-persistence mechanism used here is exactly the mechanism defined in BC-2.05.001; BC-2.10.004 is a consumer of that mechanism, not a reimplementation

## Architecture Anchors

- `ferrochain-graph/src/pregel/loop.rs` — Escalate path: call `interrupt(BudgetEscalation {...})` using the same interrupt entry point as standard HITL interrupts
- `ferrochain-graph/src/budget/types.rs` — `BudgetEscalation` struct (interrupt payload), `BudgetResume` enum (resume value variants)
- `ferrochain-graph/src/budget/journal.rs` — journal entry for Escalate and for resume decisions (Extend / Halt)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BUDGET-05

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-012 |
| Capability Anchor Justification | CAP-012 ("Budget Governance (Allow / Escalate / Deny; Cost Metering)") per capabilities-p0.md §CAP-012 — this BC specifies the "escalate to a HITL interrupt" behavior named in the "When the ceiling is reached, degrade gracefully: halt the run, escalate to a HITL interrupt, or issue a final summarize call (summary_halt), according to the budget configuration's `on_ceiling` setting (`BudgetConfig::on_ceiling` — `OnCeiling::Halt \| Escalate \| Summarize`)" clause of CAP-012 (v1.3) |
| Secondary Capability | CAP-006 ("HITL Interrupt / Resume with FIFO Resume-Value Delivery") per capabilities-p0.md §CAP-006 — this BC reuses the interrupt/resume mechanism of CAP-006 for budget escalation |
| L2 Domain Invariants | DI-003 (HITL FIFO Resume-Value Delivery) — budget escalation participates in the same FIFO resume-value queue as all other interrupts |
| D17 Commitment | D17-Q4 — budget governance escalate mode; D17-Q2 — HITL interrupt reuse |
| ADAPT Reference | adk-rust P-73 `escalate(human-review)` variant of `PaymentPolicyGuardrail` as structural analog; ferrochain adapts this to HITL interrupt mechanism |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | I (integration) |
| Module | ferrochain-graph (pregel loop escalation path, BudgetEscalation/BudgetResume types, journal) |
