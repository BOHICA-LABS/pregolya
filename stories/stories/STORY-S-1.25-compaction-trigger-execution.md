---
document_type: story
level: ops
story_id: S-1.25
epic_id: E-10
version: "1.1"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors; 7 mis-anchors corrected (AC-003 PC-003→INV-006, AC-004 INV-001→INV-003, AC-005 PC-002→INV-001, AC-007 PC-002→PC-004, AC-008 PC-003→INV-003, AC-009 INV-001→INV-008, AC-010 INV-002→INV-008)"
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.005.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "8b5fd4d"
traces_to:
  - behavioral-contracts/BC-2.10.005
  - behavioral-contracts/BC-2.10.006
points: 5
depends_on: [S-1.10, S-1.18, S-1.24]
blocks: [S-6.01]
behavioral_contracts: [BC-2.10.005, BC-2.10.006]
verification_properties: [VP-012]
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: [pregolya-core, pregolya-graph]
subsystems: [SS-10]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: N/A — BCs authored (BC-2.10.005, BC-2.10.006)
---

# STORY-S-1.25: Compaction Trigger Configuration and 7-Step Execution Cycle

## Narrative

As a system operator, I want `CompactionTrigger` configuration variants — `Disabled`, `OnWatermark`, `OnMessageCount`, and `OnTokenCount` — and a correct 7-step compaction execution cycle, so that agents operating on long conversations can automatically compact their context at configurable thresholds without disrupting in-progress execution.

## Token Budget Estimate

| Context Component | Estimated Tokens |
|-------------------|-----------------|
| This story spec | ~4,000 |
| BC files (2 BCs: BC-2.10.005–006) | ~8,000 |
| Architecture module-decomposition.md | ~3,000 |
| Target source files (pregolya-core/src/budget.rs, pregolya-graph/src/budget/) | ~8,000 |
| Test files | ~9,000 |
| S-1.10 (checkpoint core) interface | ~3,000 |
| S-1.18 (evidence journal) interface | ~2,000 |
| **Total estimate** | **~37,000** |

Comfortable within context window. No split required.

## Behavioral Contracts

| BC ID | Title | Red Gate? |
|-------|-------|-----------|
| BC-2.10.005 | CompactionTrigger — 4-variant configuration enum with watermark arithmetic | No |
| BC-2.10.006 | Compaction execution cycle — 7-step atomic execution with abort-on-error | No |

## Acceptance Criteria

### AC-001: CompactionTrigger::Disabled is the default
`CompactionTrigger::Disabled` is the default variant. When configured, no compaction ever fires.
(traces to BC-2.10.005 PC-001)

### AC-002: check_watermark_trigger arithmetic uses non-strict <= (VP-012 anchor)
The free function `check_watermark_trigger(tokens_remaining: u64, ceiling: u64, fraction: f64) -> bool` in `pregolya_core::budget` fires when `tokens_remaining as f64 / ceiling as f64 <= (1.0 - fraction)` computed in `f64`. The `<=` operator is NON-STRICT — this is load-bearing: `fraction = 1.0` requires `0.0 <= 0.0 = true`. Using strict `<` is a behavioral defect. This free function is the VP-012 proof vehicle; the Kani harness is `watermark_arithmetic_harness` in `pregolya-core`.
(traces to BC-2.10.005 PC-002)

### AC-003: CompactionTrigger construction rejects degenerate values
`OnWatermark { fraction: 0.0 }` returns `Err` at construction. `OnMessageCount { count: 0 }` returns `Err`. `OnTokenCount { tokens: 0 }` returns `Err`. Zero thresholds are meaningless and would fire immediately on every super-step.
(traces to BC-2.10.005 INV-006)

### AC-004: CompactionTrigger is #[non_exhaustive]
`CompactionTrigger` is declared `#[non_exhaustive]`. Future variants can be added without breaking existing match arms that include a wildcard.
(traces to BC-2.10.005 INV-003)

### AC-005: VP-012 seed — check_watermark_trigger <= correctness (Kani anchor)
This story is the VP-012 anchor. The Kani harness `watermark_arithmetic_harness` in `crates/pregolya-core/src/proofs/watermark.rs` must verify: for `fraction = 1.0`, the threshold check `0.0 <= 0.0` returns `true` (fires). For `fraction = 0.0` (rejected at construction), no invocation. The test `test_AC_005_check_watermark_trigger_non_strict_le_kani_seed` exercises the boundary: `fraction = 1.0` fires when `tokens_remaining = 0`, `ceiling = 100_000` — `check_watermark_trigger(0, 100_000, 1.0)` computes `0.0 / 100_000 = 0.0 <= 0.0 → true`.
(traces to BC-2.10.005 INV-001)

### AC-006: 7-step compaction cycle — correct step ordering
The compaction execution cycle follows exactly these 7 steps in order:
1. Snapshot current messages from checkpoint state
2. Call compaction function (summarization / compression)
3. Mid-run REPLACE: replace snapshot messages with compacted output in the working state
4. `CheckpointSaver::put` — write compacted checkpoint durably (not `put_writes`)
5. Write `EvidenceJournal` entry for this compaction event
6. Emit `StreamEvent::CompactionEvent` (step defined in S-1.24)
7. Continue graph execution from compacted state
(traces to BC-2.10.006 PC-001)

### AC-007: CheckpointSaver::put used for compaction checkpoint write (not put_writes)
The compaction cycle uses `CheckpointSaver::fts_search` for history lookup and `CheckpointSaver::put` for writing the compacted checkpoint. `put_writes` is NOT called. `search_history` is NOT called — that name refers to the Tool wrapper, not the trait method.
(traces to BC-2.10.006 PC-004)

### AC-008: Abort-on-compact-error — run continues; no state mutation
If the compaction function (step 2) returns an error, the cycle aborts after step 2. Steps 3-7 do NOT execute. The running graph continues from the ORIGINAL (uncompacted) state. The error is non-fatal and must not crash the run.
(traces to BC-2.10.006 INV-003)

### AC-009: Compaction fires only at super-step boundaries
Compaction is never triggered during an in-progress node execution or during an interrupt park. The trigger check occurs only at super-step boundaries — after all pending nodes in a step have completed.
(traces to BC-2.10.006 INV-008)

### AC-010: Compaction and Suspend non-interaction
Compaction cannot fire while a run is suspended (interrupted, waiting for HITL approval). The trigger check is gated on run state: if `run.state == interrupted`, skip compaction check.
(traces to BC-2.10.006 INV-008)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `CompactionTrigger` enum | `pregolya_core::budget` | pregolya-core | Pure (enum + arithmetic config) |
| `BudgetConfig` (compaction_trigger/compaction_policy fields) | `pregolya_core::budget` | pregolya-core | Pure (configuration) |
| `check_watermark_trigger(tokens_remaining, ceiling, fraction)` | `pregolya_core::budget` | pregolya-core | Pure (arithmetic gate; VP-012 Kani proof vehicle) |
| `run_compaction` | `pregolya_graph::budget` | pregolya-graph | Effectful (calls checkpoint put, emits event) |
| super-step compaction trigger check | `pregolya-graph/src/scheduler.rs` | pregolya-graph | Effectful (reads run state at super-step boundary; calls `core::budget::check_watermark_trigger`) |

**Subsystem anchor:** SS-10 owns this story's scope because SS-10 is the Budget Governance and Compaction subsystem per ARCH-INDEX Subsystem Registry. `CompactionTrigger` configuration and `check_watermark_trigger` (pure arithmetic) live in `pregolya_core::budget` (file `pregolya-core/src/budget.rs`); the 7-step compaction execution (`run_compaction`) lives in `pregolya_graph::budget` (file `pregolya-graph/src/budget/executor.rs`). Both halves are SS-10 responsibility. The streaming event emission (step 6) is wired from SS-10 into SS-06 via `emit_compaction_event` from S-1.24.

**Dependency anchors:**
- Depends on S-1.10: `CheckpointSaver::put` and `fts_search` trait methods established in S-1.10 (checkpoint core). Compaction cycle calls `put` in step 4.
- Depends on S-1.18: `EvidenceJournal` write established in S-1.18. Compaction cycle calls EvidenceJournal in step 5.
- Depends on S-1.24: `emit_compaction_event` established in S-1.24. Compaction cycle calls it in step 6.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `CompactionTrigger` (pregolya-core) | Pure | Enum in `pregolya_core::budget`; no I/O |
| `check_watermark_trigger(tokens_remaining, ceiling, fraction)` (pregolya-core) | Pure | Arithmetic only; no I/O; VP-012 Kani harness vehicle (`watermark_arithmetic_harness`) |
| `BudgetConfig::new` (pregolya-core) | Pure | Validates and stores compaction_trigger/compaction_policy config |
| `run_compaction` (pregolya-graph) | Effectful | In `pregolya_graph::budget`; calls checkpoint put, evidence journal, stream emit |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.10.005 EC-1 | `OnWatermark { fraction: 1.0 }`, `tokens_remaining = 0`, `ceiling = 100_000` | `check_watermark_trigger(0, 100_000, 1.0)` returns true (`0.0 / 100_000 = 0.0 <= 0.0`) |
| EC-002 | BC-2.10.005 EC-2 | `OnWatermark { fraction: 0.0 }` | `Err` at construction |
| EC-003 | BC-2.10.005 EC-3 | `OnMessageCount { count: 0 }` | `Err` at construction |
| EC-004 | BC-2.10.005 EC-4 | `OnTokenCount { tokens: 0 }` | `Err` at construction |
| EC-005 | BC-2.10.006 EC-1 | Compaction function returns Err | Abort after step 2; run continues from original state |
| EC-006 | BC-2.10.006 EC-2 | `CheckpointSaver::put` fails (step 4) | Abort; partial state not visible (mid-run REPLACE not persisted) |
| EC-007 | BC-2.10.006 EC-3 | Run is interrupted when super-step ends | Compaction trigger check skipped; run stays interrupted |
| EC-008 | BC-2.10.006 EC-4 | `Disabled` trigger | `check_watermark_trigger` not called; `Disabled` variant short-circuits; cycle never runs |

## Tasks

- [ ] Create `crates/pregolya-core/src/budget.rs` — `CompactionTrigger` (#[non_exhaustive] enum with 4 variants: Disabled, OnWatermark, OnMessageCount, OnTokenCount), `BudgetConfig` compaction_trigger/compaction_policy fields, `check_watermark_trigger(tokens_remaining: u64, ceiling: u64, fraction: f64) -> bool` free fn with non-strict `<=`
- [ ] Create `crates/pregolya-core/src/proofs/watermark.rs` — `#[cfg(kani)]` `watermark_arithmetic_harness` stub (body `todo!()` for Phase 6 formal hardening; VP-012)
- [ ] Create `crates/pregolya-graph/src/budget/mod.rs` (re-exports only)
- [ ] Create `crates/pregolya-graph/src/budget/executor.rs` — `run_compaction` implementing 7-step cycle; calls `check_watermark_trigger` from pregolya-core; writes to `EvidenceJournal` (S-1.18 module `pregolya_graph::budget::journal`) at step 5
- [ ] Write failing tests for AC-001..AC-010 before any implementation
- [ ] Write `test_AC_005_check_watermark_trigger_non_strict_le_kani_seed` — VP-012 boundary test (uses `check_watermark_trigger(0, 100_000, 1.0)` → true; `0.0 / 100_000 = 0.0 <= 0.0`)
- [ ] Implement `check_watermark_trigger` in pregolya-core with `<=` (NOT `<`)
- [ ] Implement 7-step cycle in pregolya-graph: verify step ordering in test
- [ ] Verify abort-on-compact-error: mock compaction fn returning Err, assert steps 3-7 not executed
- [ ] Verify compaction × suspend non-interaction: gated on run state check
- [ ] Run `just iter pregolya-core` then `just iter pregolya-graph` — all tests green

## Previous Story Intelligence

**From S-1.10 (Checkpoint Core):**
- `CheckpointSaver::put` is the correct trait method for writing checkpoints. Do NOT call `put_writes`.
- `CheckpointSaver::fts_search` is the trait method for history search. Do NOT call `search_history` — that is the Tool wrapper name, not the trait method.

**From S-1.18 (Budget Policy & Evidence Journal):**
- `EvidenceJournal` is written at step 5 of the compaction cycle, AFTER `CheckpointSaver::put` (step 4) and BEFORE `emit_compaction_event` (step 6). This ordering matches the canonical 7-step sequence.

**From S-1.24 (Tool Approval & Compaction Events):**
- `emit_compaction_event` is implemented in S-1.24. It takes a `CompactionEvent` struct with mandatory `parent_ids`. Build `CompactionEvent` with `parent_ids` populated before calling `emit_compaction_event`.

## Architecture Compliance Rules

1. **Non-strict `<=` in `check_watermark_trigger` is load-bearing.** The function lives in `pregolya_core::budget` (`pregolya-core/src/budget.rs`). Using strict `<` is a behavioral defect. The Kani proof (VP-012, harness `watermark_arithmetic_harness` in `crates/pregolya-core/src/proofs/watermark.rs`) will fail with `<`. Do not substitute.
2. **7-step ordering is fixed.** Steps must execute in order 1→7. Swapping step 4 and step 5 is incorrect (EvidenceJournal must follow checkpoint write).
3. **Abort-on-compact-error means no mutation.** If step 2 fails, the working state must remain unmodified. The mid-run REPLACE (step 3) must only execute after step 2 succeeds.
4. **Compaction trigger check at super-step boundary only.** The trigger check must appear in the super-step loop, not inside any node execution.
5. **`#[non_exhaustive]`** on `CompactionTrigger` (public API surface enum).
6. **`mod.rs` re-export only.** `pregolya-graph/src/budget/mod.rs` contains only `pub use` declarations. Logic belongs in `executor.rs`.
7. **No `unwrap()` / `expect()` in production code.**
8. **Forbidden dependency:** `pregolya-graph::budget` must NOT depend on `pregolya-server` or `pregolya-tools`.

## Library & Framework Requirements

| Library | Version | Feature Flags | License | Usage |
|---------|---------|--------------|---------|-------|
| `tokio` | (workspace pin) | default | MIT | Async execution in compaction cycle |
| `tracing` | (workspace pin) | default | MIT | Structured logging for compaction events |
| `pregolya-core` | (workspace) | — | — | `PregolyaError`, checkpoint types |
| `uuid` | (workspace pin) | `v4` | MIT/Apache | `parent_ids` in `CompactionEvent` |

## File Structure Requirements

```
crates/pregolya-core/
  src/
    budget.rs                          # CompactionTrigger (#[non_exhaustive]), BudgetConfig (compaction_trigger/compaction_policy), check_watermark_trigger free fn
    proofs/
      watermark.rs                     # #[cfg(kani)] watermark_arithmetic_harness stub (VP-012; todo!() body for Phase 6)

crates/pregolya-graph/
  src/
    budget/
      mod.rs                           # re-export only (shares module tree with S-1.18: composed.rs, journal.rs)
      executor.rs                      # run_compaction — 7-step cycle (effectful); writes to EvidenceJournal (pregolya_graph::budget::journal)
  tests/
    compaction_tests.rs                # unit tests: trigger variants, arithmetic boundary, 7-step cycle, abort-on-error
```

**Files to create (new):** `pregolya-core/src/budget.rs` (extended with CompactionTrigger fields), `pregolya-core/src/proofs/watermark.rs`, `pregolya-graph/src/budget/executor.rs`.
**Files to modify (existing):** `pregolya-core/src/lib.rs` (add `pub mod budget` if not already present from S-1.18), `pregolya-graph/src/budget/mod.rs` (add `pub use executor::*;` — S-1.18 already creates this file), `pregolya-graph/src/scheduler.rs` (super-step-loop compaction trigger check — calls `core::budget::check_watermark_trigger` at super-step boundary).

**Scheduler.rs coordination note:** S-1.25 is in sub-batch 1l — transitively after all other scheduler modifiers (S-1.16 in 1h modifies ceiling/run-ID; S-1.18 in 1g modifies budget evaluation; both feed S-1.16 which feeds S-1.25 via the S-1.25→S-1.24→S-1.23→S-1.20→S-1.16 chain). No new `depends_on` edge is required: the existing DAG guarantees S-1.25 merges after S-1.16 and S-1.18. The compaction trigger check is additive in the per-super-step section — it must be positioned AFTER the budget evaluation from S-1.18 and AFTER the ceiling check from S-1.16.
