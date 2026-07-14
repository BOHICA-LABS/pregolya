---
document_type: behavioral-contract
level: L3
bc_id: BC-2.10.002
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
  - .factory/comparative/adk-rust/behavioral-intent.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "ae45b7342b7598ae4399661744a20724845198492a1630b32b03f5bb50a3ba1b"
---

# BC-2.10.002: Append-Only EvidenceJournal Records Every Budget Evaluation

## Description

Every call to `BudgetPolicy::evaluate` (BC-2.10.001) — regardless of the returned decision —
produces an entry appended to the `EvidenceJournal` for the current run. The journal is
append-only: no entry is ever deleted, mutated, or overwritten. It provides an auditable,
ordered record of every budget decision made during a run's lifetime, enabling post-hoc cost
attribution, anomaly detection, and compliance verification. This mirrors the adk-rust P-73
payment-guardrail pattern where every transaction step is written to an append-only
`journal/` (evidence_store) for audit.

## Preconditions

1. A `Run` is executing with a `BudgetPolicy` configured in its `RunConfig` (or the implicit
   default-allow policy — see BC-2.10.001 EC-001).
2. An `EvidenceJournal` store is accessible from the execution context (backed by the same
   SQLite or in-memory backend used for checkpointing).
3. `BudgetPolicy::evaluate` has returned a `PolicyDecision`.

## Postconditions

1. Immediately after each `BudgetPolicy::evaluate` call, exactly one `JournalEntry` is
   appended to the `EvidenceJournal`. The append happens before execution continues (Allow)
   or before the halt/interrupt is triggered (Deny/Escalate).
2. Each `JournalEntry` contains, at minimum:
   - `run_id` — UUID of the run that triggered the evaluation
   - `sub_agent_id` — sub-agent identifier (if evaluation is for a sub-agent run; else null)
   - `evaluation_point` — the trigger: `AfterLlmCall` | `AfterToolInvocation`
   - `token_usage` — a snapshot of `TokenUsage` at evaluation time (prompt, completion, total, estimated_cost)
   - `policy_name` — name of the policy (or composed chain) that was evaluated
   - `decision` — `Allow | Escalate | Deny`
   - `reason` — human-readable reason string (empty string for Allow if no threshold message)
   - `timestamp` — wall-clock timestamp of the evaluation
3. The `EvidenceJournal` is ordered by append sequence. No two entries share the same
   monotonic sequence position.
4. Journal entries for a run are retrievable by `run_id`; entries for a sub-agent are
   retrievable by `sub_agent_id`.
5. The journal persists across process restarts (stored in the same durable backend as checkpoints).

## Invariants

- Append-only: no existing `JournalEntry` may be deleted, updated, or truncated after it is
  written. The journal is a write-once-read-many log.
- Every evaluation call produces exactly one journal entry — no evaluation is silently skipped,
  even for Allow decisions.
- Journal writes use the same durability guarantees as checkpoint `put_writes`: under the
  sync durability tier (the default), the journal entry is persisted before execution resumes.
- The journal schema is stable; new fields may be added (backward-compatible) but existing
  fields may not be removed or renamed without a version bump.

## Edge Cases

### EC-001: Journal write fails (storage I/O error)
**Scenario:** The underlying storage raises an I/O error when the journal entry is being written.
**Expected behavior:** The storage error propagates as `Err(E-BUDGET-002 JournalWriteFailed)`.
Execution does not silently continue after a journal write failure — the integrity of the
audit log takes precedence over execution continuity. The run transitions to `failed`.

### EC-002: EvidenceJournal queried for a sub-agent run
**Scenario:** An operator queries the journal for all entries related to sub-agent
`sub_agent_id = "wave-1-task-3"`.
**Expected behavior:** All journal entries where `sub_agent_id = "wave-1-task-3"` are returned
in append-sequence order. Parent-run journal entries are not included in the sub-agent query
unless explicitly joined.

### EC-003: Large run with many tool invocations (> 1000 evaluations)
**Scenario:** A Domain B dark-factory run makes 1000 tool calls, each triggering a journal entry.
**Expected behavior:** All 1000 entries are written and retrievable. Journal storage does not
impose an arbitrary entry count limit. Performance is bounded (O(1) per append; O(n) for full
journal scan).

### EC-004: Default-allow policy (no explicit BudgetPolicy configured)
**Scenario:** A run has no `BudgetPolicy` in its `RunConfig`. The implicit default-allow
policy is applied.
**Expected behavior:** Journal entries are still written for every evaluation point, with
`policy_name: "default-allow"` and `decision: Allow`. The journal is never empty for a run
that completed any LLM call or tool invocation.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Run with 1 LLM call and 1 tool call; policy returns Allow for both | Journal has exactly 2 entries in append order: first `evaluation_point: AfterLlmCall`, second `AfterToolInvocation`; both `decision: Allow` | Happy path — journal completeness |
| TV-002 | Run where 3rd LLM call triggers Deny | Journal has ≥ 3 entries; 3rd entry: `decision: Deny, reason: "hard limit exceeded"` | Deny recorded before halt |
| TV-003 | Sub-agent run within parent run; sub-agent makes 2 LLM calls | Journal has 2 entries with non-null `sub_agent_id`; parent journal and sub-agent journal are queryable independently | Sub-agent attribution |
| TV-004 | Process restart mid-run; run resumes | On resume, journal from before the restart is preserved and readable; new entries appended after restart are in correct sequence order | Durable persistence across restart |
| TV-005 | Journal write fails on entry 5 | `Err(E-BUDGET-002 JournalWriteFailed)` returned; run transitions to `failed`; entries 1–4 are preserved; entry 5 is not silently skipped | Journal write failure is fatal |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BUDGET-03 | EvidenceJournal contains exactly one entry per evaluate() call; entries are in append order; no missing evaluations | Integration test — instrument evaluation calls; assert journal count == evaluation call count; verify ordering | Phase 1 |

## Related BCs

- BC-2.10.001 — depends on: every `BudgetPolicy::evaluate` call is the source trigger for a journal entry
- BC-2.10.003 — related to: Deny entries are written before the halt is executed
- BC-2.10.004 — related to: Escalate entries are written before the HITL interrupt is raised; resume decision is also journaled
- BC-2.04.007 — related to: EvidenceJournal is a write-once log; encryption at rest applies to journal entries as it does to state payloads

## Architecture Anchors

- `ferrochain-graph/src/budget/journal.rs` — `EvidenceJournal` trait, `JournalEntry` struct, append API
- `ferrochain-checkpoint/src/backend/sqlite.rs` — SQLite-backed journal storage (append-only table, no DELETE/UPDATE allowed)
- `ferrochain-graph/src/pregel/loop.rs` — journal append call after `policy.evaluate(...)` returns, before execution resumes

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BUDGET-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-012 |
| Capability Anchor Justification | CAP-012 ("Budget Governance (Allow / Escalate / Deny; Cost Metering)") per capabilities-p1-p2.md §CAP-012 — this BC specifies the "append-only EvidenceJournal" explicitly named in CAP-012, which records every evaluation for audit and cost attribution |
| L2 Domain Invariants | — |
| D17 Commitment | D17-Q4 — "append-only evidence journal" is a named requirement of the budget governance mandate |
| ADAPT Reference | adk-rust P-73 (adk-payments `journal/` evidence_store: every step written for audit; append-only pattern) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | [architect to assign — ferrochain-graph, ferrochain-checkpoint] |
