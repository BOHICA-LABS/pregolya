---
document_type: story
level: ops
story_id: S-1.18
epic_id: E-10
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.001.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.004.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "b6db228"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.14, S-1.04, S-1.10]
blocks: [S-1.24, S-1.25]
behavioral_contracts: [BC-2.10.001, BC-2.10.002, BC-2.10.003, BC-2.10.004]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-10]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

> **tdd_mode:** strict — full TDD Iron Law enforced.

> **Execute:** `/vsdd-factory:deliver-story S-1.18`

# S-1.18: Budget Policy, Evidence Journal, Graceful Halt, and Budget Escalation

## Narrative

- **As a** graph runtime developer building the pregolya-graph budget system
- **I want to** implement the `BudgetPolicy` trait (pure `evaluate` method with chain composition), an append-only `EvidenceJournal`, graceful halt on ceiling (Halt halts with `E-BUDGET-001`; Summarize calls one final LLM), and budget escalation via `interrupt()` when the policy returns `Escalate`
- **So that** graph runs can be bounded by token and step budgets, audit trails are maintained, and operators can interactively extend or halt runs that exceed their budgets

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.10.001 | BudgetPolicy Trait — Pure evaluate, Chain Composition | AC-001..AC-004 |
| BC-2.10.002 | EvidenceJournal — Append-Only Audit Log | AC-005..AC-008 |
| BC-2.10.003 | Graceful Halt — OnCeiling::Halt and Summarize | AC-009..AC-012 |
| BC-2.10.004 | Budget Escalation via interrupt() | AC-013..AC-016 |

## Acceptance Criteria

### AC-001 (traces to BC-2.10.001 postcondition 1 — BudgetPolicy trait has pure evaluate method)
`BudgetPolicy` trait in `pregolya-core/src/budget.rs` defines `fn evaluate(&self, usage: &TokenUsage) -> PolicyDecision` as a synchronous pure method returning `PolicyDecision::Allow`, `PolicyDecision::Escalate`, or `PolicyDecision::Deny`. Verified by `test_BC_2_10_001_budget_policy_trait_signature()`.

### AC-002 (traces to BC-2.10.001 postcondition 2 — chain composition: Deny > Escalate > Allow)
When multiple `BudgetPolicy` instances are composed in a chain, `Deny` takes precedence over `Escalate`, which takes precedence over `Allow`. A chain of N policies returns `Deny` if any policy returns `Deny`, else `Escalate` if any returns `Escalate`, else `Allow`. Verified by `test_BC_2_10_001_chain_deny_over_escalate_over_allow()`.

### AC-003 (traces to BC-2.10.001 postcondition 3 — per-evaluation journal entry written)
Each call to `evaluate` produces a `JournalEntry` written to the `EvidenceJournal`. The entry includes the policy name, decision, and current usage snapshot. Verified by `test_BC_2_10_001_per_evaluation_journal_entry()`.

### AC-004 (traces to BC-2.10.001 postcondition 4 — sub-agents evaluated independently)
Each sub-agent spawned via the Send API receives an independent `BudgetPolicy` evaluation; they do not share a single global ceiling. Verified by `test_BC_2_10_001_subagent_independent_evaluation()`.

### AC-005 (traces to BC-2.10.002 postcondition 1 — EvidenceJournal is append-only)
`EvidenceJournal` only supports `append(entry: JournalEntry) -> Result<(), PregolyaError>`. There are no delete, update, or truncate methods. Verified by `test_BC_2_10_002_journal_is_append_only()`.

### AC-006 (traces to BC-2.10.002 postcondition 2 — JournalEntry fields)
`JournalEntry` contains: `run_id: Uuid`, `sub_agent_id: Option<Uuid>`, `evaluation_point: String`, `token_usage: TokenUsage`, `policy_name: String`, `decision: PolicyDecision`, `reason: Option<String>`, `timestamp: DateTime<Utc>`. Verified by `test_BC_2_10_002_journal_entry_fields()`.

### AC-007 (traces to BC-2.10.002 postcondition 3 — journal backed by SQLite checkpoint)
`EvidenceJournal` persists entries to the SQLite checkpoint backend (`pregolya-checkpoint/src/backend/sqlite.rs`). Verified by `test_BC_2_10_002_journal_backed_by_sqlite()`.

### AC-008 (traces to BC-2.10.002 invariant 1 — E-BUDGET-002 on journal write failure)
If the journal fails to write an entry (I/O error, constraint violation), the budget evaluation returns `Err(PregolyaError { category: BUDGET, code: E-BUDGET-002, .. })`. The graph run does not proceed as if the journal write succeeded. Verified by `test_BC_2_10_002_journal_write_failure_returns_error()`.

### AC-009 (traces to BC-2.10.003 postcondition 1 — OnCeiling::Halt produces E-BUDGET-001)
When `PolicyDecision::Deny` is returned and `BudgetConfig.on_ceiling = OnCeiling::Halt`, the scheduler halts the run and returns `Err(PregolyaError { category: BUDGET, code: E-BUDGET-001, retry_hint: Never, .. })`. No further nodes execute. Verified by `test_BC_2_10_003_halt_on_ceiling_returns_e_budget_001()`.

### AC-010 (traces to BC-2.10.003 postcondition 2 — OnCeiling::Summarize calls one final LLM)
When `PolicyDecision::Deny` and `on_ceiling = OnCeiling::Summarize`, the scheduler makes exactly one final LLM call to produce a summary, then transitions the run to `summary_halt` state. Verified by `test_BC_2_10_003_summarize_on_ceiling_calls_one_llm()`.

### AC-011 (traces to BC-2.10.003 postcondition 3 — BudgetInfo available in node context)
Node functions can read `BudgetInfo { tokens_remaining: Option<i64>, steps_remaining: Option<i64> }` from the run context. Verified by `test_BC_2_10_003_budget_info_available_in_node_context()`.

### AC-012 (traces to BC-2.10.003 invariant 1 — Halt never retried)
`E-BUDGET-001` carries `retry_hint: Never`. The error is not transient; no automatic retry logic should be applied. Verified by `test_BC_2_10_003_e_budget_001_retry_hint_never()`.

### AC-013 (traces to BC-2.10.004 postcondition 1 — Escalate always triggers HITL interrupt)
When `PolicyDecision::Escalate` is returned (regardless of `on_ceiling` setting), the scheduler calls `interrupt()` with a `BudgetEscalation { current_usage, ceiling, policy_name, reason }` payload. Verified by `test_BC_2_10_004_escalate_always_triggers_interrupt()`.

### AC-014 (traces to BC-2.10.004 postcondition 2 — BudgetResume::Extend applies new ceiling)
When the HITL operator resumes with `BudgetResume::Extend { new_ceiling }`, the scheduler patches `RunnableConfig::budget_config` with the new ceiling and continues execution. The journal records the extension. Verified by `test_BC_2_10_004_budget_resume_extend_applies_new_ceiling()`.

### AC-015 (traces to BC-2.10.004 postcondition 3 — BudgetResume::Halt stops the run)
When the HITL operator resumes with `BudgetResume::Halt`, the scheduler halts the run with `E-BUDGET-001`. Verified by `test_BC_2_10_004_budget_resume_halt_stops_run()`.

### AC-016 (traces to BC-2.10.004 invariant 1 — Deny + on_ceiling=Escalate triggers HITL even on hard ceiling)
When `on_ceiling = OnCeiling::Escalate` and a `Deny` decision is returned, the run is also interrupted via HITL before halting — the soft path applies first. Verified by `test_BC_2_10_004_deny_escalate_ceiling_triggers_hitl()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| `BudgetPolicy` trait + `PolicyDecision` | `pregolya-core/src/budget.rs` | Pure (trait definition + evaluate) |
| `BudgetConfig` + `OnCeiling` enum | `pregolya-core/src/budget.rs` | Pure (config types) |
| Chain composition | `pregolya-graph/src/budget/composed.rs` | Pure (chain logic) |
| `EvidenceJournal` | `pregolya-graph/src/budget/journal.rs` | Effectful (SQLite writes) |
| Scheduler budget evaluation | `pregolya-graph/src/scheduler.rs` | Effectful (calls evaluate, calls interrupt) |
| `BudgetInfo` in node context | `pregolya-graph/src/types.rs` | Pure (data type) |
| SQLite journal backend | `pregolya-checkpoint/src/backend/sqlite.rs` | Effectful (I/O) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/budget.rs` (trait + enums) | pure-core | Types and trait definitions only; no I/O |
| `pregolya-graph/src/budget/composed.rs` (chain) | pure-core | Chain composition is a pure function over policy list |
| `pregolya-graph/src/budget/journal.rs` | effectful-shell | SQLite persistence — inherently effectful |
| `pregolya-graph/src/scheduler.rs` (budget eval) | effectful-shell | Calls evaluate + interrupt(); reads/writes run state |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Budget check when `tokens_remaining = 0` | Immediate `Deny`; `E-BUDGET-001` or HITL depending on `on_ceiling` |
| EC-002 | `on_ceiling = Summarize` but LLM call fails | Summary LLM error → run transitions to `failed`; `E-BUDGET-001` not issued |
| EC-003 | Sub-agent with its own `BudgetPolicy` + parent also has policy | Each evaluated independently; sub-agent ceiling does not affect parent |
| EC-004 | Journal write times out | `E-BUDGET-002`; run does not continue without audit record |
| EC-005 | `BudgetResume::Extend` sets `new_ceiling` lower than current usage | Immediate re-evaluation → `Deny` again → `E-BUDGET-001` or another HITL |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,500 |
| BC files (4 BCs) | ~6,000 |
| S-1.14 context (scheduler skeleton) | ~1,500 |
| S-1.10 context (checkpoint SQLite backend) | ~1,500 |
| `budget/` module stubs (3 files) | ~1,500 |
| `pregolya-core/src/budget.rs` | ~1,000 |
| Test files | ~3,000 |
| **Total** | **~18,000** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~9.0%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for all 16 ACs in `pregolya-graph/tests/budget_policy.rs`
2. [ ] Create `pregolya-core/src/budget.rs` — `BudgetPolicy` trait, `PolicyDecision`, `BudgetConfig`, `OnCeiling`, `BudgetInfo`, `TokenUsage`
3. [ ] Create `pregolya-graph/src/budget/mod.rs` (re-export only)
4. [ ] Create `pregolya-graph/src/budget/composed.rs` — chain composition (`Deny > Escalate > Allow`)
5. [ ] Create `pregolya-graph/src/budget/journal.rs` — `EvidenceJournal`, `JournalEntry`, SQLite-backed append
6. [ ] Create `pregolya-graph/src/budget/types.rs` — `BudgetEscalation`, `BudgetResume` enum
7. [ ] Add budget evaluation to `pregolya-graph/src/scheduler.rs` — calls `evaluate` each super-step; calls `interrupt()` on `Escalate`; halts on `Deny + Halt`; calls final LLM on `Deny + Summarize`
8. [ ] Add `BudgetInfo` to node execution context
9. [ ] Export budget types from `pregolya-core/src/lib.rs` and `pregolya-graph/src/lib.rs`
10. [ ] Run `cargo nextest run -p pregolya-graph --no-fail-fast` — all tests green

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.14 | Channel + reducer foundation; `scheduler.rs` skeleton | `mod.rs` re-export only | Budget eval in scheduler; do not put I/O in trait `evaluate` |
| S-1.10 | `CheckpointStore` trait; `SqliteCheckpointStore` | SQLite is the persistence backend | `EvidenceJournal` must use `pregolya-checkpoint` SQLite backend, not a separate DB connection |
| S-1.04 | `PregolyaError` with category + code; `E-BUDGET-*` codes in taxonomy | `retry_hint: Never` for policy denials | Confirm `E-BUDGET-001` and `E-BUDGET-002` codes are in error taxonomy before use |

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `BudgetPolicy::evaluate` is synchronous (not async) | BC-2.10.001 postcondition 1 | Trait signature: `fn evaluate` not `async fn evaluate` |
| `EvidenceJournal` uses SQLite checkpoint backend — not a separate DB | BC-2.10.002 architecture anchors | Import path check: `pregolya-checkpoint::backend::sqlite` |
| `E-BUDGET-001` has `retry_hint: Never` | BC-2.10.003 invariant 1 | Unit test `test_BC_2_10_003_e_budget_001_retry_hint_never()` |
| `Escalate` always triggers HITL interrupt — even when `on_ceiling = Halt` | BC-2.10.004 postcondition 1 | Unit test `test_BC_2_10_004_escalate_always_triggers_interrupt()` |
| `pregolya-core/src/budget.rs` must NOT import from `pregolya-graph` | Dependency direction: graph → core | `cargo deny` + import scan |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `chrono` | workspace-pinned | `DateTime<Utc>` for `JournalEntry.timestamp` |
| `uuid` | workspace-pinned | `run_id`, `sub_agent_id` UUIDs |
| `tokio` | workspace-pinned | Async scheduler methods |
| `tracing` | workspace-pinned | Structured events for budget decisions |
| `pregolya-checkpoint` | workspace path | SQLite backend for `EvidenceJournal` |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/budget.rs` | create | `BudgetPolicy` trait, `PolicyDecision`, `BudgetConfig`, `OnCeiling`, `BudgetInfo`, `TokenUsage` |
| `pregolya-core/src/lib.rs` | modify | Re-export budget types |
| `pregolya-graph/src/budget/mod.rs` | create | Re-export only |
| `pregolya-graph/src/budget/composed.rs` | create | Chain composition logic |
| `pregolya-graph/src/budget/journal.rs` | create | `EvidenceJournal`, `JournalEntry`, SQLite append |
| `pregolya-graph/src/budget/types.rs` | create | `BudgetEscalation`, `BudgetResume` |
| `pregolya-graph/src/scheduler.rs` | modify | Budget evaluation, halt/summarize/escalate dispatch |
| `pregolya-graph/tests/budget_policy.rs` | create | AC-001..AC-016 tests |
