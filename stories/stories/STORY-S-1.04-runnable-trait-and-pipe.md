---
document_type: story
level: ops
story_id: S-1.04
epic_id: E-01
version: "1.7"
status: draft
producer: story-writer
timestamp: 2026-08-29T00:00:00Z
changelog:
  - "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors."
  - "1.2 (M3c/ADR-027/2026-08-24): ADR-027 M3c: escalation-resolution AC re-citations."
  - "1.3 (M4/ADR-027/2026-08-24): ADR-027 M4: normalize edge-case citations to stable EC-NNN tag."
  - "1.4 (P2-bc-completeness-burst-B/2026-08-26): BC-2.01.003 PC-002: AC-002 updated with BoxStream return type and Ok(chunk) wrapping. {EC-006}: AC-013 added — invoke-Err yielded as single Err stream item. BC table version bumped."
  - "1.5 (R36/F-P2A152-01-propagation/2026-08-29): BC-2.01.003 reconciled to canonical form in R36. AC-001: associated-type form (Self::Input/Self::Output/&RunnableConfig/async fn) replaced with generic-parameter form (Input/Output/Option<RunnableConfig>/fn...->impl Future+Send). AC-002: BoxStream replaced with async outer-Ok stream return. input-hash refreshed (BC-2.01.003 updated in R36)."
  - "1.6 (R37/F-P2A156-01+F-P2A156-02+F-P2A156-03+F-P2A156-04+F-P2A158-01+F-P2A158-02+F-P2A158-03/2026-08-29): F-P2A156-01/F-P2A158-02 [HIGH/MED]: AC-013 outer-Result contradiction resolved — stream() returns Ok(stream) outer Result; Err is yielded as single stream item (callers poll to discover error); removed erroneous 'stream() does NOT return an outer Result' clause per BC-2.01.003 {PC-002}/{EC-006}. F-P2A156-03/F-P2A158-03 [HIGH/MED]: AC-004 + Task 5 recursion_limit type corrected u32 → usize per BC-2.01.003 {PRE-003}. F-P2A156-04 [HIGH]: AC-008 RunnableSequence 3-param → 2-param (RunnableSequence<I, O>); pipe sig updated to canonical form. F-P2A156-02 [HIGH, POL-18]: AC-008 Runnable associated-type binding (Input=I/Output=M) replaced with positional (I, M) per ADR-010/ADR-025 canon (E0229-invalid binding form). F-P2A158-01 [HIGH, POL-4]: Architecture Mapping + Purity Classification + Task 5 + File Structure RunnableConfig anchor corrected src/runnable/config.rs → src/config.rs (core::config, re-exported at crate root) per BC-2.01.003 §Architecture Anchors."
  - "1.7 (round-38/F-P2A160-01/2026-08-29): F-P2A160-01 [HIGH]: AC-007 updated to reflect BC-2.01.003 {PC-001} — E-CORE-003 is raised at the serde-bounded blanket boundary when `serde_json::from_value::<I>` fails, before typed `Runnable<I,O>::invoke` is called; callers are NOT responsible for pre-deserializing Value input; trace updated to EC-001/{PC-001}. AC-008 updated to reflect BC-2.01.004 {PC-001} — typed stages (e.g. `impl Runnable<String,String>`) auto-satisfy `DynRunnable` via the serde-bounded blanket without any `Runnable<Value,Value>` requirement; `RunnableSequence<I,O>` also auto-derives `DynRunnable` and can be stored as `Box<dyn DynRunnable>` directly. Sweep of story body confirmed: no residual 'callers do JSON round-tripping' or `Runnable<Value,Value>` requirement language present. input-hash refreshed (BC-2.01.003 and BC-2.01.004 updated round-38)."
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.004.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "8860df1"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.03, S-1.02]
blocks: [S-1.05, S-1.06, S-1.07, S-1.10, S-1.12, S-1.13, S-1.14, S-1.17, S-1.18, S-1.19, S-1.21, S-1.26, S-2.01, S-2.02, S-2.03, S-2.04, S-2.06, S-2.10]
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

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.01.003 | Runnable Trait Invocation — invoke, stream, batch | AC-001..AC-007, AC-013 |
| BC-2.01.004 | Runnable Pipe Composition (A.pipe(B) = AB Chain) | AC-008..AC-012 |

## Acceptance Criteria

### AC-001 (traces to BC-2.01.003 PC-001)
The `Runnable` trait uses **generic parameters** `Input` and `Output` (not associated types), and every
implementor provides:
`fn invoke(&self, input: Input, config: Option<RunnableConfig>) -> impl std::future::Future<Output = Result<Output, PregolyaError>> + Send`
(RPITIT + Send form; bare `async fn` is not permitted as it lacks a `Send` bound on the returned future — required for the `DynRunnable` blanket impl per ADR-005 §Send-Bounded RPITIT).
A custom `DoubleString` struct that implements `Runnable<String, String>` constructs and calls `invoke`
returning `Ok(format!("{}{}", s, s))`. Verified by `test_BC_2_01_003_custom_runnable_invoke()`.

### AC-002 (traces to BC-2.01.003 PC-002)
The default `stream` method on `Runnable` is async and returns `Result<impl Stream<Item = Result<Output, PregolyaError>> + Send, PregolyaError>` — an outer `Ok(stream)` wrapping a stream of `Result<Output, PregolyaError>` items. The non-streaming fallback calls `invoke` internally: if `invoke` returns `Ok(output)`, the outer future resolves to `Ok(stream)` where the stream yields `Ok(output)` as its single item and then terminates; if `invoke` returns `Err(e)`, the stream yields `Err(e)` as its single item (per EC-006). A `DoubleString` stream over input "hello" yields exactly one item: `Ok("hellohello".to_string())` then terminates. Verified by `test_BC_2_01_003_default_stream_single_item()`.

### AC-003 (traces to BC-2.01.003 PC-003)
The default `batch` method on `Runnable` calls `invoke` concurrently for each input with bounded concurrency (default max 10 in-flight). A batch of 5 inputs returns 5 outputs in order. Verified by `test_BC_2_01_003_default_batch_order_preserved()`.

### AC-004 (traces to BC-2.01.003 PC-005)
`RunnableConfig` has a `recursion_limit: usize` field with default value 25. Accessing `config.recursion_limit` from within `invoke` is possible. Verified by `test_BC_2_01_003_runnable_config_recursion_limit()`.

### AC-005 (traces to BC-2.01.003 INV-006)
`DynRunnable` is a non-generic trait (not `DynRunnable<Input, Output>`) that uses `serde_json::Value` as both input and output. It has methods `async fn invoke(&self, input: Value, config: Option<RunnableConfig>) -> Result<Value, PregolyaError>` and `fn stream(...)`. `Arc<dyn DynRunnable>` is the type-erased composition handle. Verified by `test_BC_2_01_003_dyn_runnable_non_generic()`.

### AC-006 (traces to BC-2.01.003 INV-005)
When `recursion_limit` is exceeded (checked by a graph-level depth counter, not the `Runnable` trait itself), the error returned is `Err(PregolyaError { code: "E-CORE-006", message: "RecursionLimitExceeded: recursion limit exceeded at depth <depth>", .. })`. A unit test simulates this by manually decrementing the counter to zero. Verified by `test_BC_2_01_003_recursion_limit_exceeded_error()`.

### AC-007 (traces to BC-2.01.003 EC-001 / {PC-001} — E-CORE-003 at DynRunnable blanket boundary)
When an `Arc<dyn DynRunnable>` receives a `Value` that cannot be deserialized into the expected
concrete input type `I`, `E-CORE-003` is raised at the serde-bounded blanket boundary — specifically
when `serde_json::from_value::<I>(input)` fails at that boundary — before the typed
`Runnable<I, O>::invoke` is ever called on the concrete impl. Callers are NOT responsible for
pre-deserializing the `Value` input; the blanket handles the `Value → I` round-trip internally.
The error returned is:
`Err(PregolyaError { category: VAL, code: E-CORE-003, message: "Runnable input type mismatch: expected '<expected>', got '<actual>'", .. })`.
Verified by `test_BC_2_01_003_input_type_mismatch_error()`.

### AC-008 (traces to BC-2.01.004 {PC-001})
`a.pipe(b)` where `a: Runnable<I, M>` and `b: Runnable<M, O>` (positional type params; the
binding form `Runnable<Input=I, Output=M>` is E0229-invalid and MUST NOT be used) returns
`RunnableSequence<I, O>` (2-param; canonical `pipe` sig:
`fn pipe<NextOutput>(self, next: impl Runnable<Output, NextOutput>) -> RunnableSequence<Input, NextOutput>`)
with `first: a`, `middle: []`, `last: b`. Invoking the sequence calls `a.invoke(input)` then
feeds output to `b.invoke(m)`.
By the serde-bounded `DynRunnable` blanket impl, any `Runnable<I, O>` where
`I: serde::de::DeserializeOwned + Send + 'static` and `O: serde::Serialize + Send + 'static`
auto-satisfies `DynRunnable` — a typed stage such as `impl Runnable<String, String>` is
therefore directly coercible to `Box<dyn DynRunnable>` WITHOUT requiring a `Runnable<Value, Value>`
adapter. `RunnableSequence<I, O>` also auto-derives `DynRunnable` and can be stored as
`Box<dyn DynRunnable>` directly. TV-001's typed stages compose via `pipe()` and are usable as
`Box<dyn DynRunnable>` elements without any `Value`-typed wrapper.
Verified by `test_BC_2_01_004_pipe_two_stages()`.

### AC-009 (traces to BC-2.01.004 PC-004)
`a.pipe(b).pipe(c)` flattens into `RunnableSequence { first: a, middle: [b], last: c }` — NOT nested `RunnableSequence<RunnableSequence<...>, c>`. The `first` field is always the first runnable in the chain. Verified by `test_BC_2_01_004_pipe_flattens_sequence()`.

### AC-010 (traces to BC-2.01.004 PC-005)
For `DynRunnable` pipeline composition where a type boundary mismatch is detected at construction time, the error is `Err(PregolyaError { code: "E-CORE-004", message: "Pipe composition failed: type boundary mismatch between stage <n> output and stage <n+1> input", .. })`. Verified by `test_BC_2_01_004_pipe_type_mismatch_error()`.

### AC-011 (traces to BC-2.01.004 PC-003)
Streaming through a `RunnableSequence` propagates chunks: each step must buffer non-streaming steps and stream out chunks from streaming steps. A two-stage sequence where step A is streaming and step B is non-streaming: stream collects all A's chunks, calls B.invoke, emits B's single output as one chunk. Verified by `test_BC_2_01_004_streaming_through_sequence()`.

### AC-012 (traces to BC-2.01.004 INV-004)
`RunnableSequence::first` is never a `RunnableSequence` (flattening invariant). This prevents unbounded nesting. Verified by `test_BC_2_01_004_sequence_not_nested()` asserting the type of `first` in a multi-stage chain.

### AC-013 (traces to BC-2.01.003 PC-002 and {EC-006} — invoke-Err yielded as single stream item)
When a `Runnable::invoke` returns `Err(e)`, calling `stream()` on the same runnable returns
`Ok(stream)` (outer `Ok`); polling the stream yields exactly one item: `Err(e)`. The stream
then terminates. The error is surfaced as a stream item inside the `Ok(stream)` outer result —
callers must poll stream items to discover the error; the outer `Result` is `Ok` in the default
non-streaming fallback (per BC-2.01.003 {PC-002}/{EC-006}). The `stream()` call does not panic.
Verified by `test_BC_2_01_003_stream_invoke_err_yielded_as_single_item()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `Runnable` trait | `pregolya-core/src/runnable/trait.rs` | pure-core (trait definition) |
| `RunnableConfig` | `pregolya-core/src/config.rs` (`core::config`) | pure-core |
| `DynRunnable` trait | `pregolya-core/src/runnable/dyn_runnable.rs` | pure-core (trait definition) |
| `RunnableSequence` | `pregolya-core/src/runnable/sequence.rs` | effectful (async invoke calls) |
| Module root | `pregolya-core/src/runnable/mod.rs` | re-export-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/runnable/trait.rs` | pure-core | Trait definition only; no implementation-side I/O. |
| `pregolya-core/src/config.rs` | pure-core | Plain data struct; re-exported at crate root. |
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
5. [ ] Create `pregolya-core/src/config.rs` — `RunnableConfig` with `recursion_limit: usize = 25`, `merge_configs`; re-exported at crate root (`pub use config::RunnableConfig;` in `lib.rs`)
6. [ ] Create `pregolya-core/src/runnable/dyn_runnable.rs` — `DynRunnable` trait (non-generic)
7. [ ] Create `pregolya-core/src/runnable/sequence.rs` — `RunnableSequence` with `pipe` method and flattening
8. [ ] Add `pub mod runnable;`, `pub mod config;`, and re-export `RunnableConfig` at crate root (`pub use config::RunnableConfig;`) in `pregolya-core/src/lib.rs`
9. [ ] Implement E-CORE-003, E-CORE-004, E-CORE-006 error constructions
10. [ ] Wire streaming through sequence (buffer non-streaming, propagate streaming)
11. [ ] Write failing test `test_BC_2_01_003_stream_invoke_err_yielded_as_single_item()` for AC-013 (test-writer)
12. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.03 established `Message` types needed by Runnables. S-1.02 established credential and error machinery. `DynRunnable` in S-1.04 will wrap `Message` types via `serde_json::Value` — the `Value` representation of a `Message` is what crosses the DynRunnable boundary.

S-1.01 error codes: `E-CORE-003`, `E-CORE-004`, `E-CORE-006` must be present in the error taxonomy before implementation.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `runnable/mod.rs` is re-export-only | CLAUDE.md Code Conventions | Code review |
| `DynRunnable` is non-generic (not `DynRunnable<I, O>`) | BC-2.01.003 INV-006 | Type signature inspection; compile test |
| `RunnableSequence::first` is never a `RunnableSequence` (no nested sequences) | BC-2.01.004 PC-004 | Unit test + type-level enforcement |
| `batch` default uses bounded concurrency (max 10 in-flight) | BC-2.01.003 PC-003 | Unit test counting concurrent executions |

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
| `pregolya-core/src/config.rs` | CREATE | `RunnableConfig`, `merge_configs`; re-exported at crate root |
| `pregolya-core/src/runnable/dyn_runnable.rs` | CREATE | `DynRunnable` non-generic trait |
| `pregolya-core/src/runnable/sequence.rs` | CREATE | `RunnableSequence` + `pipe` |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod runnable;`, `pub mod config;`, re-export `RunnableConfig` at crate root |
