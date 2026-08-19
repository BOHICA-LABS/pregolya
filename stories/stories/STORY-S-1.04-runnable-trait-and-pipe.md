---
document_type: story
level: ops
story_id: S-1.04
epic_id: E-01
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "923aa7a"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.03, S-1.02]
blocks: [S-1.05, S-1.06, S-1.07]
behavioral_contracts: [BC-2.01.003, BC-2.01.004]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-core
subsystems: [SS-01]
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.04: Runnable Trait Invocation and Pipe Composition

## Narrative

- **As a** pregolya library user building LLM chains
- **I want to** have a `Runnable` trait with `invoke`, `stream`, and `batch` methods, and a `pipe` operator that chains two runnables into a `RunnableSequence`
- **So that** I can compose complex LLM workflows from simple building-block types without writing boilerplate orchestration code

## Acceptance Criteria

### AC-001 (traces to BC-2.01.003 postcondition 1)
The `Runnable` trait is defined with associated types `Input` and `Output`, and the method:
`async fn invoke(&self, input: Self::Input, config: &RunnableConfig) -> Result<Self::Output, PregolyaError>`.
A custom `DoubleString` struct that implements `Runnable<Input=String, Output=String>` constructs and calls `invoke` returning `Ok(format!("{}{}", s, s))`. Verified by `test_BC_2_01_003_custom_runnable_invoke()`.

### AC-002 (traces to BC-2.01.003 postcondition 2)
The default `stream` method on `Runnable` yields a single item: the result of `invoke`. A `DoubleString` stream over input "hello" yields exactly one item: `Ok("hellohello".to_string())` then terminates. Verified by `test_BC_2_01_003_default_stream_single_item()`.

### AC-003 (traces to BC-2.01.003 postcondition 3)
The default `batch` method on `Runnable` calls `invoke` concurrently for each input with bounded concurrency (default max 10 in-flight). A batch of 5 inputs returns 5 outputs in order. Verified by `test_BC_2_01_003_default_batch_order_preserved()`.

### AC-004 (traces to BC-2.01.003 postcondition 4)
`RunnableConfig` has a `recursion_limit: u32` field with default value 25. Accessing `config.recursion_limit` from within `invoke` is possible. Verified by `test_BC_2_01_003_runnable_config_recursion_limit()`.

### AC-005 (traces to BC-2.01.003 postcondition 5)
`DynRunnable` is a non-generic trait (not `DynRunnable<Input, Output>`) that uses `serde_json::Value` as both input and output. It has methods `async fn invoke(&self, input: Value, config: Option<RunnableConfig>) -> Result<Value, PregolyaError>` and `fn stream(...)`. `Arc<dyn DynRunnable>` is the type-erased composition handle. Verified by `test_BC_2_01_003_dyn_runnable_non_generic()`.

### AC-006 (traces to BC-2.01.003 postcondition 6)
When `recursion_limit` is exceeded (checked by a graph-level depth counter, not the `Runnable` trait itself), the error returned is `Err(PregolyaError { code: "E-CORE-006", message: "RecursionLimitExceeded: recursion limit exceeded at depth <depth>", .. })`. A unit test simulates this by manually decrementing the counter to zero. Verified by `test_BC_2_01_003_recursion_limit_exceeded_error()`.

### AC-007 (traces to BC-2.01.003 edge case EC-001 — E-CORE-003)
When `DynRunnable::invoke` is called with a `Value` that cannot be deserialized into the expected concrete input type, the error is `Err(PregolyaError { code: "E-CORE-003", message: "Runnable input type mismatch: expected '<expected>', got '<actual>'", .. })`. Verified by `test_BC_2_01_003_input_type_mismatch_error()`.

### AC-008 (traces to BC-2.01.004 postcondition 1)
`a.pipe(b)` where `a: Runnable<Input=I, Output=M>` and `b: Runnable<Input=M, Output=O>` returns `RunnableSequence<I, M, O>` with `first: a`, `middle: []`, `last: b`. Invoking the sequence calls `a.invoke(input)` then feeds output to `b.invoke(m)`. Verified by `test_BC_2_01_004_pipe_two_stages()`.

### AC-009 (traces to BC-2.01.004 postcondition 2)
`a.pipe(b).pipe(c)` flattens into `RunnableSequence { first: a, middle: [b], last: c }` — NOT nested `RunnableSequence<RunnableSequence<...>, c>`. The `first` field is always the first runnable in the chain. Verified by `test_BC_2_01_004_pipe_flattens_sequence()`.

### AC-010 (traces to BC-2.01.004 postcondition 3)
For `DynRunnable` pipeline composition where a type boundary mismatch is detected at construction time, the error is `Err(PregolyaError { code: "E-CORE-004", message: "Pipe composition failed: type boundary mismatch: <detail>", .. })`. Verified by `test_BC_2_01_004_pipe_type_mismatch_error()`.

### AC-011 (traces to BC-2.01.004 postcondition 4)
Streaming through a `RunnableSequence` propagates chunks: each step must buffer non-streaming steps and stream out chunks from streaming steps. A two-stage sequence where step A is streaming and step B is non-streaming: stream collects all A's chunks, calls B.invoke, emits B's single output as one chunk. Verified by `test_BC_2_01_004_streaming_through_sequence()`.

### AC-012 (traces to BC-2.01.004 invariant)
`RunnableSequence::first` is never a `RunnableSequence` (flattening invariant). This prevents unbounded nesting. Verified by `test_BC_2_01_004_sequence_not_nested()` asserting the type of `first` in a multi-stage chain.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `Runnable` trait | `pregolya-core/src/runnable/trait.rs` | pure-core (trait definition) |
| `RunnableConfig` | `pregolya-core/src/runnable/config.rs` | pure-core |
| `DynRunnable` trait | `pregolya-core/src/runnable/dyn_runnable.rs` | pure-core (trait definition) |
| `RunnableSequence` | `pregolya-core/src/runnable/sequence.rs` | effectful (async invoke calls) |
| Module root | `pregolya-core/src/runnable/mod.rs` | re-export-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/runnable/trait.rs` | pure-core | Trait definition only; no implementation-side I/O. |
| `pregolya-core/src/runnable/config.rs` | pure-core | Plain data struct. |
| `pregolya-core/src/runnable/sequence.rs` | effectful | `invoke` on a sequence calls sub-runnables which may do I/O (LLM calls, tool calls). |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Empty middle in RunnableSequence (2-stage) | Valid; middle is empty Vec; first feeds directly to last |
| EC-002 | Batch with 0 inputs | Returns empty Vec — no concurrency spawned |
| EC-003 | `DynRunnable::invoke` where inner Runnable panics | Panic propagates; DOES NOT become structured error (panic is a logic bug, not an API error) |
| EC-004 | Pipe where first stage errors | Error propagated; second stage never invoked |
| EC-005 | RunnableConfig recursion_limit = 0 | Valid construction; immediately returns E-CORE-006 if invoke is called recursively |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,200 |
| BC-2.01.003.md (~250 lines) | ~3,800 |
| BC-2.01.004.md (~200 lines) | ~3,000 |
| `module-decomposition.md` (SS-01 section) | ~500 |
| `runnable/` module files (~80 lines each × 4 files) | ~3,500 |
| Test files (~120 lines) | ~1,800 |
| Tool outputs | ~500 |
| **Total** | **~16,300** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~8%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-012 (test-writer)
2. [ ] Verify Red Gate
3. [ ] Create `pregolya-core/src/runnable/mod.rs` — re-exports only
4. [ ] Create `pregolya-core/src/runnable/trait.rs` — `Runnable` trait with `invoke`, `stream`, `batch` defaults
5. [ ] Create `pregolya-core/src/runnable/config.rs` — `RunnableConfig` with `recursion_limit: u32 = 25`
6. [ ] Create `pregolya-core/src/runnable/dyn_runnable.rs` — `DynRunnable` trait (non-generic)
7. [ ] Create `pregolya-core/src/runnable/sequence.rs` — `RunnableSequence` with `pipe` method and flattening
8. [ ] Add `pub mod runnable;` to `pregolya-core/src/lib.rs`
9. [ ] Implement E-CORE-003, E-CORE-004, E-CORE-006 error constructions
10. [ ] Wire streaming through sequence (buffer non-streaming, propagate streaming)
11. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.03 established `Message` types needed by Runnables. S-1.02 established credential and error machinery. `DynRunnable` in S-1.04 will wrap `Message` types via `serde_json::Value` — the `Value` representation of a `Message` is what crosses the DynRunnable boundary.

S-1.01 error codes: `E-CORE-003`, `E-CORE-004`, `E-CORE-006` must be present in the error taxonomy before implementation.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `runnable/mod.rs` is re-export-only | CLAUDE.md Code Conventions | Code review |
| `DynRunnable` is non-generic (not `DynRunnable<I, O>`) | BC-2.01.003 postcondition 5 | Type signature inspection; compile test |
| `RunnableSequence::first` is never a `RunnableSequence` (no nested sequences) | BC-2.01.004 postcondition 2 | Unit test + type-level enforcement |
| `batch` default uses bounded concurrency (max 10 in-flight) | BC-2.01.003 postcondition 3 | Unit test counting concurrent executions |

**Forbidden dependencies for `pregolya-core/src/runnable/trait.rs`, `config.rs`, `dyn_runnable.rs`:** No direct tokio import at trait-definition level. Tokio is used in the impl (sequence.rs) not the trait.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `tokio` | workspace pin | `async fn invoke` and `JoinSet` for batch default implementation |
| `serde_json` | workspace pin | `Value` as DynRunnable I/O type |
| `futures` | workspace pin | `Stream` trait for streaming API |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/runnable/mod.rs` | CREATE | Re-export-only module root |
| `pregolya-core/src/runnable/trait.rs` | CREATE | `Runnable` trait |
| `pregolya-core/src/runnable/config.rs` | CREATE | `RunnableConfig` |
| `pregolya-core/src/runnable/dyn_runnable.rs` | CREATE | `DynRunnable` non-generic trait |
| `pregolya-core/src/runnable/sequence.rs` | CREATE | `RunnableSequence` + `pipe` |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod runnable;` |
