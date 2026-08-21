---
document_type: story
level: ops
story_id: S-1.16
epic_id: E-08
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-03/BC-2.03.001.md
  - .factory/specs/behavioral-contracts/ss-03/BC-2.03.002.md
  - .factory/specs/behavioral-contracts/ss-03/BC-2.03.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "0ed02f5"
traces_to: .factory/stories/STORY-INDEX.md
points: 13
depends_on: [S-1.14, S-1.15, S-1.10, S-1.13, S-1.17, S-1.18]
blocks: [S-1.20, S-1.26, S-6.01]
behavioral_contracts: [BC-2.03.001, BC-2.03.002, BC-2.03.003]
verification_properties: [VP-001]
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-03]
estimated_days: 5
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

> **tdd_mode:** strict — full TDD Iron Law enforced. VP-001 (Kani harness `bsp_determinism_harness` for `reduce_super_step`) is the verification property anchored to this story.

> **Execute:** `/vsdd-factory:deliver-story S-1.16`

# S-1.16: BSP Super-Step Determinism and Ceiling Enforcement

## Narrative

- **As a** graph runtime developer building the pregolya-graph BSP engine
- **I want to** guarantee deterministic super-step execution (same inputs always produce the same outputs and same next tasks), enforce a super-step ceiling (`step_at_invoke_start + recursion_limit + 1`, default limit 25), and reject concurrent `LastValue` writes with a structured error
- **So that** graph runs are reproducible for debugging and formal verification, infinite recursion is detected and reported, and VP-001 (`bsp_determinism_harness` Kani proof) can be established against the `reduce_super_step` pure function

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.03.001 | BSP Determinism — Super-Step Ceiling and Reproducibility | AC-001..AC-005 |
| BC-2.03.002 | Concurrent LastValue Write Rejection | AC-006..AC-007 |
| BC-2.03.003 | Deterministic Reducer Sort — (task_id, channel_name) Ascending | AC-008..AC-010 |

## Acceptance Criteria

### AC-001 (traces to BC-2.03.001 postcondition 1 — same inputs produce same super-step outputs)
Given the same set of `WriteRecord` entries and the same channel state at the start of a super-step, `reduce_super_step` always produces identical output channel state. No non-deterministic data structure iteration is used in the reduction path. Verified by `test_BC_2_03_001_reduce_super_step_deterministic()`.

### AC-002 (traces to BC-2.03.001 postcondition 2 — super-step ceiling enforced)
When the current step count exceeds `step_at_invoke_start + recursion_limit + 1` (default `recursion_limit = 25`), the engine returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-017, .. })` with fields `{ run_id, step, limit }`. Verified by `test_BC_2_03_001_super_step_ceiling_enforced()`.

### AC-003 (traces to BC-2.03.001 postcondition 3 — custom recursion_limit respected)
When `RunnableConfig::recursion_limit` is set to a value other than 25, the ceiling uses the configured value. Verified by `test_BC_2_03_001_custom_recursion_limit()`.

### AC-004 (traces to BC-2.03.001 invariant 1 — E-GRAPH-006 on run ID collision)
If two concurrent runs attempt to use the same `run_id`, the engine returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-006, .. })` with field `{ run_id }`. Verified by `test_BC_2_03_001_run_id_collision_error()`.

### AC-005 (traces to BC-2.03.001 postcondition 4 — VP-001 Kani harness anchored here)
A Kani proof harness `bsp_determinism_harness` is defined in `pregolya-graph/src/proofs/bsp_determinism.rs` that calls `reduce_super_step` with symbolic inputs and asserts determinism via `kani::assert`. This harness is the test vehicle for VP-001. Verified by `test_BC_2_03_001_kani_harness_compiles()` (compile check) and `kani::proof` execution in Phase 6.

### AC-006 (traces to BC-2.03.002 postcondition 1 — concurrent LastValue writes produce structured error)
When two tasks in the same super-step both write to the same `LastValue<T>` channel, the engine returns `Err(PregolyaError { category: CONCURRENCY, code: E-GRAPH-001, retry_hint: Never, .. })` with structured fields `{ component: GRAPH, category: CONCURRENCY, code: E-GRAPH-001 }`. Verified by `test_BC_2_03_002_concurrent_last_value_write_rejected()`.

### AC-007 (traces to BC-2.03.002 invariant 1 — error is deterministic not data-race UB)
The concurrent-write error is produced at the reduction phase, not at write time — both writes are accepted as `WriteRecord` entries and the conflict is detected during sorted reduce. This ensures the error is deterministic regardless of task scheduling order. Verified by `test_BC_2_03_002_concurrent_write_detected_at_reduce_not_write_time()`.

### AC-008 (traces to BC-2.03.003 postcondition 1 — writes sorted by task_id then channel_name)
All `WriteRecord` entries collected in a super-step are sorted by `(task_id, channel_name)` lexicographic ascending before the reduce function is applied. No `HashMap` or any unordered iteration is used in the reduce path. Verified by `test_BC_2_03_003_writes_sorted_by_task_id_then_channel()`.

### AC-009 (traces to BC-2.03.003 invariant 1 — sort key is (task_id: &str, channel_name: &str))
The sort comparator uses the `task_id` string (not a numeric hash) as the primary key and `channel_name` as the secondary key, both in ascending lexicographic order. Verified by `test_BC_2_03_003_sort_key_is_string_lexicographic()`.

### AC-010 (traces to BC-2.03.003 postcondition 2 — reduce_super_step is a pure function)
`reduce_super_step(writes: Vec<WriteRecord>, channels: ChannelState) -> Result<ChannelState, PregolyaError>` has no mutable global state, no spawned tasks, and no I/O calls. It is suitable for extraction as a Kani proof target. Verified by `test_BC_2_03_003_reduce_super_step_is_pure()` (function signature inspection + no side-effect assertions).

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| `reduce_super_step` pure fn | `pregolya-graph/src/bsp_engine.rs` | Pure (extracted for Kani) |
| Super-step ceiling check | `pregolya-graph/src/scheduler.rs` | Effectful (accesses run state) |
| Run ID collision detection | `pregolya-graph/src/scheduler.rs` | Effectful (state lookup) |
| Kani proof harness | `pregolya-graph/src/proofs/bsp_determinism.rs` | Pure (Kani symbolic execution) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `bsp_engine.rs::reduce_super_step` | pure-core | No I/O; deterministic; suitable for formal verification |
| `scheduler.rs` (ceiling + run ID checks) | effectful-shell | Reads and writes mutable run-state |
| `proofs/bsp_determinism.rs` | pure-core | Kani harness; all symbolic inputs, no I/O |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | `recursion_limit = 0` | Ceiling is `step_at_invoke_start + 1`; first recursive step exceeds it → `E-GRAPH-017` |
| EC-002 | Empty `WriteRecord` list in super-step | `reduce_super_step` returns current channel state unchanged; no error |
| EC-003 | Two tasks write same `LastValue` with identical values | Still `E-GRAPH-001` — concurrent write is a contract violation regardless of value equality |
| EC-004 | Sort with 1000+ write records | Deterministic; performance is acceptable (sort is O(N log N)) |
| EC-005 | `run_id` is a UUID; same UUID used by two concurrent runs | `E-GRAPH-006 { run_id }` on second run |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,500 |
| BC files (3 BCs) | ~5,000 |
| S-1.14 context (channels, types, WriteRecord) | ~2,000 |
| S-1.15 context (scheduler skeleton) | ~1,000 |
| `bsp_engine.rs` (reduce_super_step pure fn) | ~1,500 |
| `scheduler.rs` (ceiling + run ID) | ~1,200 |
| `proofs/bsp_determinism.rs` (Kani harness) | ~800 |
| Test files | ~3,500 |
| Architecture module-decomposition.md (SS-03) | ~600 |
| **Total** | **~19,100** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~9.6%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for all 10 ACs in `pregolya-graph/tests/bsp_determinism.rs`
2. [ ] Extract `reduce_super_step(writes: Vec<WriteRecord>, channels: ChannelState) -> Result<ChannelState, PregolyaError>` as a pure free function in `pregolya-graph/src/bsp_engine.rs`
3. [ ] Implement `WriteRecord` sort: `(task_id, channel_name)` lexicographic ascending
4. [ ] Add super-step ceiling enforcement in `pregolya-graph/src/scheduler.rs` — `E-GRAPH-017`
5. [ ] Add run ID collision detection in `pregolya-graph/src/scheduler.rs` — `E-GRAPH-006`
6. [ ] Create `pregolya-graph/src/proofs/mod.rs` (re-export only)
7. [ ] Create `pregolya-graph/src/proofs/bsp_determinism.rs` — Kani harness `bsp_determinism_harness`
8. [ ] Verify harness compiles with `cargo kani -p pregolya-graph` (full proof runs in Phase 6)
9. [ ] Run `cargo nextest run -p pregolya-graph --no-fail-fast` — all tests green

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.14 | `WriteRecord { task_id, channel_name, value }` struct defined in `types.rs`; channel materialisation at compile | `mod.rs` re-export only; all channels in `channels/` | Concurrent-write detection must happen during reduce (not write time) — AC-007 |
| S-1.15 | `add_conditional_edges` + path_fn catch_unwind; PUSH task queue in `scheduler.rs` | S-1.15 creates `scheduler.rs` skeleton (PUSH task queue, TASKS topic, `ctx.send()`); S-1.17 adds `run()`/`stream()` executors | Coordinate bsp_engine.rs changes between S-1.14 (Red Gate tests), S-1.15 (path dispatch), and S-1.16 (reduce_super_step extraction) |
| S-1.17 | `StreamEvent` enum (16 variants); `run()`/`stream()` executors in `scheduler.rs`; event emission in `tick()`/`after_tick()` | `scheduler.rs::run()` method body exists when S-1.16 adds ceiling + run ID checks; S-1.16 modifies scheduler.rs — ensure rebase on S-1.17 | S-1.16 adds ceiling check and run ID collision detection to the `scheduler.rs` run() body established by S-1.17 |
| S-1.18 | `BudgetPolicy` trait; per-super-step budget evaluation in `scheduler.rs` | Budget evaluation is inside the super-step loop; ceiling check (E-GRAPH-017) is also per-step — both must coexist without conflict | S-1.16 and S-1.18 both modify the per-super-step section of `scheduler.rs`; the second PR to merge must rebase on the first |
| S-1.10 | Checkpoint core — `CheckpointStore` trait, sqlite backend | `bsp_engine.rs::finish()` writes to checkpoint; `reduce_super_step` must NOT call checkpoint (pure) | Ensure `reduce_super_step` is extracted before `finish()` so the Kani harness is a clean pure-fn target |

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `reduce_super_step` must be a pure free function — no global state, no async, no I/O | BC-2.03.001 postcondition 4; VP-001 Kani requirement | Signature: `fn reduce_super_step(writes: Vec<WriteRecord>, channels: ChannelState) -> Result<ChannelState, PregolyaError>` |
| No `FuturesUnordered::buffer_unordered` in reduce path | BC-2.03.003 invariant 1 | Code review; `cargo grep FuturesUnordered pregolya-graph` must be empty in reduce path |
| Super-step ceiling formula: `step_at_invoke_start + recursion_limit + 1` | BC-2.03.001 postcondition 2 | Unit test with exact formula check |
| Default `recursion_limit = 25` | BC-2.03.001 postcondition 2 | Const in `types.rs` or `scheduler.rs` |
| Kani proofs in `src/proofs/` subdirectory | CLAUDE.md §Formal Verification | Directory structure check |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `kani` | workspace-pinned | Formal verification harness for `bsp_determinism_harness` |
| `tokio` | workspace-pinned | Async scheduler; `reduce_super_step` itself is sync |
| `tracing` | workspace-pinned | Structured events for ceiling exceeded, run ID collision |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-graph/src/bsp_engine.rs` | modify | Extract `reduce_super_step` as pure free function; sort by `(task_id, channel_name)` |
| `pregolya-graph/src/scheduler.rs` | modify | Add ceiling check (`E-GRAPH-017`), run ID collision (`E-GRAPH-006`) |
| `pregolya-graph/src/proofs/mod.rs` | create | Re-export only |
| `pregolya-graph/src/proofs/bsp_determinism.rs` | create | `bsp_determinism_harness` Kani proof (VP-001 test vehicle) |
| `pregolya-graph/tests/bsp_determinism.rs` | create | AC-001..AC-010 tests |
