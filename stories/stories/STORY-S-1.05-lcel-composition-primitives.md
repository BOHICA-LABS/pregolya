---
document_type: story
level: ops
story_id: S-1.05
epic_id: E-01
version: "1.2"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.2 (P2A-043 F-05/2026-08-24): prose ordinal cross-refs converted to stable tags."
  - "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors."
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.007.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.008.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "f83a7d4"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.04]
blocks: [S-6.01]
behavioral_contracts: [BC-2.01.005, BC-2.01.006, BC-2.01.007, BC-2.01.008]
verification_properties: [VP-014]
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-core
subsystems: [SS-01]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.05: LCEL Composition Primitives — RunnableParallel, RunnablePassthrough, RunnableAssign

## Narrative

- **As a** pregolya library user building parallel-fan-out workflows
- **I want to** have `RunnableParallel` (concurrent fan-out with abort-all on failure), `RunnablePassthrough` (identity passthrough with optional inspection), and `RunnableAssign` (dict augmentation via `assign`)
- **So that** I can build LangChain Expression Language (LCEL)-compatible pipelines that fan out to multiple branches, pass-through values for inspection, and augment dictionaries with computed keys — with deterministic, structured error propagation

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.01.005 | RunnableParallel Construction and Concurrent Invocation | AC-001..AC-004 |
| BC-2.01.006 | RunnableParallel Branch Failure — Fail-Fast, Structured Error, No Partial Results | AC-005..AC-007 |
| BC-2.01.007 | RunnablePassthrough Identity Pass-Through and Inspect Side-Effect Contract | AC-008..AC-010 |
| BC-2.01.008 | RunnableAssign Dict Augmentation — Merge Semantics and Dict-Input Validation | AC-011..AC-014 |

## Acceptance Criteria

### AC-001 (traces to BC-2.01.005 PC-001; EC-006; TV-006)
`RunnableParallel::new(steps)` is infallible — it never returns `Err`. When the input iterator yields duplicate keys (e.g., `[("a", fn1), ("a", fn2)]`), `IndexMap` last-write-wins semantics apply: the resulting `RunnableParallel` contains one branch keyed `"a"` bound to `fn2`; `fn1` is discarded and never called. Invoking with `Value::Null` returns `Ok(Object({"a": fn2_output}))`. This matches Python `RunnableParallel` dict semantics per ADR-026 §Decision 1. Verified by `test_BC_2_01_005_duplicate_key_last_write_wins`.

### AC-002 (traces to BC-2.01.005 PC-002 and PC-003)
`rp.invoke(input, config)` spawns all N branches concurrently via Tokio `JoinSet`, collects their outputs, and returns `Ok(Value::Object(map))` with exactly N keys in the original insertion order. Verified by `test_BC_2_01_005_invoke_N_keys_insertion_order()`.

### AC-003 (traces to BC-2.01.005 PC-006; EC-001)
`RunnableParallel::new([]).invoke(input, config)` returns `Ok(Value::Object(Map::new()))` — an empty object, not an error. Verified by `test_BC_2_01_005_zero_branch_returns_empty_object()`.

### AC-004 (traces to BC-2.01.005 PC-004 — VP-014)
A proptest over randomly generated N-branch parallel inputs asserts: `output.as_object().unwrap().len() == N` AND the key set of the output equals the set of configured branch keys. Verified by `proptest_BC_2_01_005_output_completeness_VP014()`.

### AC-005 (traces to BC-2.01.006 PC-001 and PC-002)
When any branch returns `Err`, `JoinSet::abort_all()` is called immediately. The returned error is `Err(PregolyaError { category: EXEC, code: "E-CORE-009", message: "RunnableParallelBranchFailure: branch '<key>' failed: <cause>", .. })`. Verified by `test_BC_2_01_006_branch_failure_abort_all()`.

### AC-006 (traces to BC-2.01.006 PC-003)
No partial output `Ok(partial_map)` is ever returned — on any branch failure, the result is always `Err`. A test where branch "fast" succeeds but branch "slow" fails asserts that no `Ok` with a "fast" key is returned. Verified by `test_BC_2_01_006_no_partial_result()`.

### AC-007 (traces to BC-2.01.006 PC-004)
A Tokio task panic (JoinError from a panicking branch task) maps to `Err(PregolyaError { category: INTERNAL, code: "E-CORE-011", message: "RunnableParallelTaskPanic: task panicked: <detail>", .. })`. `abort_all()` is still called. Verified by `test_BC_2_01_006_join_error_maps_to_internal()`.

### AC-008 (traces to BC-2.01.007 PC-001)
`RunnablePassthrough::new()` constructs without arguments. `passthrough.invoke(input, config)` returns `Ok(input.clone())` — a deep clone of the input value. Verified by `test_BC_2_01_007_passthrough_returns_clone()`.

### AC-009 (traces to BC-2.01.007 PC-002)
`RunnablePassthrough::with_inspect(f)` accepts `f: Arc<dyn Fn(&Value) + Send + Sync>`. The inspect function is called once per `invoke` call before the input is returned. It receives `&Value` (immutable borrow) — it cannot modify the output. Verified by `test_BC_2_01_007_inspect_fn_called_once()`.

### AC-010 (traces to BC-2.01.007 PC-007 and EC-002)
`RunnablePassthrough::invoke` NEVER returns `Err` on its own — the return value is always `Ok(input.clone())` regardless of whether an `inspect_fn` is attached. A panicking `inspect_fn` is a caller contract violation (BC-2.01.007 PRE-003 requires the function to be non-panicking in production use); the panic propagates as a Rust unwind rather than being caught and converted to `Err` by `RunnablePassthrough` (BC-2.01.007 EC-002). Any `Err` observed from a pipeline containing `RunnablePassthrough` originates upstream or downstream, not from the passthrough itself. The test exercises the infallibility invariant over a range of inputs with and without an inspect function. Verified by `test_BC_2_01_007_passthrough_infallible()`.

### AC-011 (traces to BC-2.01.008 PC-001)
`RunnablePassthrough::assign(pairs)` creates a `RunnableAssign` whose internal mapper is a `RunnableParallel::new(pairs)`. There is no public `RunnableAssign::new()` constructor. Verified by `test_BC_2_01_008_assign_uses_parallel_mapper()`.

### AC-012 (traces to BC-2.01.008 PC-003)
`assign.invoke(input, config)` where `input` is a `Value::Object` returns `Ok(Value::Object(merged))` where merged contains all input keys plus all mapper output keys; mapper keys win on collision (`{**input, **mapper_output}` semantics). Verified by `test_BC_2_01_008_assign_mapper_wins_collision()`.

### AC-013 (traces to BC-2.01.008 PC-002)
`assign.invoke(Value::String("not_an_object"), config)` returns `Err(PregolyaError { category: VAL, code: "E-CORE-010", message: "RunnableAssignNonDictInput: input to RunnablePassthrough.assign() must be a JSON object", .. })`. Verified by `test_BC_2_01_008_non_dict_input_error()`.

### AC-014 (traces to BC-2.01.008 INV-002)
Merge is always `{**input, **mapper_output}`: input keys not in mapper remain unchanged; mapper keys override matching input keys; no mapper keys are silently dropped. A three-key merge test verifies all three conditions. Verified by `test_BC_2_01_008_merge_semantics_complete()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `RunnableParallel` | `pregolya-core/src/runnable/parallel.rs` | effectful (JoinSet, async) |
| `RunnablePassthrough` | `pregolya-core/src/runnable/passthrough.rs` | pure-core (invoke is synchronous clone) |
| `RunnableAssign` | `pregolya-core/src/runnable/assign.rs` | effectful (delegates to RunnableParallel mapper) |
| Module root | `pregolya-core/src/runnable/mod.rs` | re-export-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/runnable/passthrough.rs` | pure-core | `invoke` clones the input value; no I/O, no async needed (though async trait impl required for trait compat). |
| `pregolya-core/src/runnable/parallel.rs` | effectful | Spawns Tokio tasks via `JoinSet::spawn`; requires Tokio runtime. |
| `pregolya-core/src/runnable/assign.rs` | effectful | Delegates to `RunnableParallel` mapper internally. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | RunnableParallel with 1 branch that fails | `abort_all()` still called; E-CORE-009 returned |
| EC-002 | Multiple branches fail simultaneously | First-detected error wins; others discarded after `abort_all()` |
| EC-003 | inspect_fn is very slow | Does not affect output correctness; timing is user concern |
| EC-004 | assign input has 0 keys | `Ok(Value::Object(mapper_output))` — empty input merged with mapper output |
| EC-005 | assign mapper branch fails | Propagates E-CORE-009 from RunnableParallel fail-fast |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,500 |
| BC-2.01.005.md (~200 lines) | ~3,000 |
| BC-2.01.006.md (~190 lines) | ~2,800 |
| BC-2.01.007.md (~150 lines) | ~2,200 |
| BC-2.01.008.md (~160 lines) | ~2,400 |
| `module-decomposition.md` (SS-01 section) | ~500 |
| `runnable/` files (~100 lines each × 3 files) | ~4,500 |
| Test + proptest files (~150 lines) | ~2,250 |
| Tool outputs | ~500 |
| **Total** | **~21,650** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~11%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-014 (test-writer)
2. [ ] Write `proptest_BC_2_01_005_output_completeness_VP014` proptest (test-writer)
3. [ ] Verify Red Gate
4. [ ] Create `pregolya-core/src/runnable/mod.rs` — re-exports only
5. [ ] Create `pregolya-core/src/runnable/parallel.rs` — `RunnableParallel` with `IndexMap`, `JoinSet::abort_all` fail-fast
6. [ ] Create `pregolya-core/src/runnable/passthrough.rs` — `RunnablePassthrough` with optional `inspect_fn: Arc<dyn Fn(&Value) + Send + Sync>`
7. [ ] Create `pregolya-core/src/runnable/assign.rs` — `RunnableAssign` backed by `RunnableParallel` mapper
8. [ ] Implement `RunnablePassthrough::assign(pairs)` factory method
9. [ ] Implement E-CORE-009, E-CORE-010, E-CORE-011 error constructions
10. [ ] Implement abort-all on first branch failure (BC-2.01.006)
11. [ ] Implement mapper-wins-on-collision merge semantics (BC-2.01.008)
12. [ ] Add `pub mod runnable;` to `pregolya-core/src/lib.rs`
13. [ ] Add proptest dep to `pregolya-core/Cargo.toml` dev-dependencies
14. [ ] Run `cargo nextest run -p pregolya-core` — all tests including proptest pass

## Previous Story Intelligence (MANDATORY)

S-1.04 established `Runnable` trait, `DynRunnable`, and `RunnableConfig`. `RunnableParallel` implements `DynRunnable` (not the generic `Runnable` trait) because its I/O is always `Value`. The `JoinSet` pattern for parallel dispatch was established in the architecture but not yet implemented; this story is the first JoinSet usage.

S-1.04 established: `Arc<dyn DynRunnable>` as the type-erased composition handle. S-1.05 `RunnableParallel` takes `Arc<dyn DynRunnable>` steps, not generic `Runnable` implementors.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `runnable/mod.rs` is re-export-only | CLAUDE.md Code Conventions | Code review |
| `RunnableParallel` MUST call `abort_all()` before returning Err | BC-2.01.006 INV-001 | Unit test captures abort signal via channel |
| No partial `Ok` on failure — only complete N-key `Ok` or `Err` | BC-2.01.006 INV-002 (DI-016) | Test: fast-succeeds/slow-fails → assert Err |
| mapper-wins-on-collision: `{**input, **mapper_output}` semantics | BC-2.01.008 INV-002 | Table-driven merge test |
| `IndexMap` used for insertion-order preservation | BC-2.01.005 INV-001 | Compile-time: `IndexMap` import; runtime: order assertion |

**Forbidden dependencies for `pregolya-core/src/runnable/passthrough.rs`:** No direct tokio spawn; passthrough.rs should not create tasks. The async implementation is a thin wrapper.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `tokio` | workspace pin | `JoinSet` for concurrent branch dispatch in RunnableParallel |
| `indexmap` | workspace pin | `IndexMap<String, Arc<dyn DynRunnable>>` for insertion-order preservation |
| `serde_json` | workspace pin | `Value`, `Map` for I/O types and merge |
| `proptest` | workspace pin (dev) | VP-014 property test for N-key output completeness |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/runnable/mod.rs` | CREATE | Re-export-only module root |
| `pregolya-core/src/runnable/parallel.rs` | CREATE | `RunnableParallel` |
| `pregolya-core/src/runnable/passthrough.rs` | CREATE | `RunnablePassthrough` |
| `pregolya-core/src/runnable/assign.rs` | CREATE | `RunnableAssign` |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod runnable;` |
| `pregolya-core/Cargo.toml` | MODIFY | Add `proptest` to `[dev-dependencies]`, `indexmap` to `[dependencies]` |
