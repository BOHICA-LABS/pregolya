---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.004
version: "1.3"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-01
capability: CAP-002
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-core per module-decomposition.md v1.10."
  - "1.2 (FIX-BURST-B5-WAVE-B/2026-07-29): Error-construction notation sweep (ADR-010 §Class 3). Three sites corrected: PC5 single-line (E-CORE-004, `, ..` added); EC-001 3-line multiline span closure (E-CORE-004, `, ..` added before closing `})`); TV-004 table-cell (E-CORE-004, `, ..` added). All spans have category/code/message but lack component and retry_hint."
  - "1.3 (BURST-303/O-P194-A/2026-08-17): Precondition 2 generic-arity reconciliation — replaced type-erased `DynRunnable<Value, Value>` pipelines with canonical `Arc<dyn DynRunnable>` form per architect DynRunnable canon (O-P194-A). DynRunnable is a non-generic trait; Value is the runtime boundary type, not a type parameter."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-002
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "22e7fbd"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.004: Runnable Pipe Composition (A.pipe(B) = AB Chain)

## Description

pregolya-core's `Runnable` trait exposes a `.pipe(other)` builder method (the Rust equivalent
of Python's `|` operator) that composes two Runnables into a `RunnableSequence`. The sequence
feeds the output of the first Runnable as the input to the second. A heterogeneous pipeline
assembled via `.pipe()` satisfies the full `Runnable` surface itself, enabling further chaining.
`RunnableSequence` flattens nested sequences so that `a.pipe(b).pipe(c)` produces a single
`RunnableSequence { first: a, middle: [b], last: c }` rather than nested wrappers.

## Preconditions

1. Two Runnables `A: Runnable<Input=I, Output=M>` and `B: Runnable<Input=M, Output=O>` are in scope.
2. The output type of `A` matches the input type of `B` (enforced at compile time for typed
   Runnables; checked at runtime for type-erased `Arc<dyn DynRunnable>` pipelines).
3. The resulting `RunnableSequence` will be used in non-test code.

## Postconditions

1. `a.pipe(b)` returns a `RunnableSequence` that implements `Runnable<Input=I, Output=O>`.
2. `seq.invoke(input, &config).await` runs `a.invoke(input)`, then feeds the result to
   `b.invoke(result)`, returning the final output or the first error encountered.
3. `seq.stream(input, &config)` passes the output chunks of `a` into `b` incrementally when
   both `a` and `b` are streaming-native (`transform`-capable); otherwise buffers at each
   non-streaming step. Token-by-token throughput is preserved in an all-streaming pipeline.
4. Sequence flattening: `a.pipe(b).pipe(c)` produces one `RunnableSequence` with
   `first=a, middle=[b], last=c` — NOT `RunnableSequence { first: RunnableSequence{a,b}, last: c }`.
5. A type-boundary mismatch in a type-erased `DynRunnable` pipeline is detected at the sequence's
   first `invoke` call and returns `Err(PregolyaError { category: INTERNAL, code: E-CORE-004, .. })`.
6. The composed sequence inherits config (tags, metadata, callbacks) from the caller's
   `RunnableConfig`; each step receives a child config tagged with its sequential position
   (`seq:step:1`, `seq:step:2`, etc.).

## Invariants

- **Composition is left-associative:** `a.pipe(b).pipe(c)` ≡ `(a.pipe(b)).pipe(c)`.
- **Type check at call time (DynRunnable path):** A type mismatch between stages in a type-erased
  pipeline is NOT a compile-time error but produces a well-typed `PregolyaError`, not a panic.
- **Streaming through sequences:** Token streaming is preserved end-to-end when every step is
  `transform`-capable (see rust-translation-strategy.md `RunnableSequence`). A buffering step
  (e.g. `RunnableLambda`) acts as a natural barrier; downstream steps begin only after the
  buffering step has consumed all upstream output.
- **Sequence flattening is structural** — it does not change observable behavior but avoids
  allocating nested wrapper objects.

## Edge Cases

### EC-001: Type mismatch in type-erased pipeline (DynRunnable path)
**Scenario:** `dyn_runnable_a.pipe(dyn_runnable_b)` where `a` outputs `serde_json::Value::Bool`
but `b` expects `serde_json::Value::String`. Detected only at invocation.
**Expected behavior:** `seq.invoke(input).await` returns `Err(PregolyaError { category: INTERNAL,
code: E-CORE-004, message: "Pipe composition failed: type boundary mismatch between stage 1 output
and stage 2 input", .. })`. No panic, no silent wrong-type coercion.
**Reference:** error-taxonomy.md E-CORE-004.

### EC-002: Three-stage pipeline with streaming-native middle step
**Scenario:** `prompt_template.pipe(chat_model).pipe(str_output_parser)` — the typical streaming
chain. The chat model is streaming-native; prompt template and output parser are transform-capable.
**Expected behavior:** Tokens flow end-to-end; `seq.stream(input)` emits incremental string chunks
rather than a single final chunk. Each stage's output is fed to the next before the upstream
stage completes.

### EC-003: Sequence with a RunnableLambda (buffering step)
**Scenario:** `step_a.pipe(lambda_b).pipe(step_c)` where `lambda_b` requires the full output
of `step_a` before it can produce any output.
**Expected behavior:** `lambda_b` buffers `step_a`'s output chunks via `+` (addable) or
keep-last (non-addable). Once `lambda_b` produces its output, it is streamed into `step_c`.
The upstream-before-downstream ordering invariant is preserved within each segment.

### EC-004: Deep pipeline (10+ stages)
**Scenario:** 10 identical lambda stages chained via `.pipe()`.
**Expected behavior:** The resulting `RunnableSequence` has `first`, `middle: [8 items]`, `last`.
`invoke` on the sequence runs all 10 in order. No stack overflow, no intermediate allocations
beyond the `middle` vec.

### EC-005: Empty-sequence guard (pipe with self)
**Scenario:** `a.pipe(a)` where `a` is a `RunnableLambda` that is `Clone`.
**Expected behavior:** A valid `RunnableSequence` is created. Execution runs `a` twice sequentially.
No error unless the output type of `a` does not match the input type of `a`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `to_upper.pipe(add_exclamation).invoke("hello", &cfg)` | `Ok("HELLO!")` | Happy path — two-stage typed pipeline |
| TV-002 | `a.pipe(b).pipe(c)` — check structure | `RunnableSequence { first: a, middle: [b], last: c }` — flattened | Sequence flattening |
| TV-003 | Streaming chain: `a.pipe(b).stream("input")` where both are streaming-native | Emits chunks incrementally, not one final chunk | Token streaming through sequence |
| TV-004 | Type-erased `a.pipe(b)` with type mismatch, `invoke` | `Err(PregolyaError { category: INTERNAL, code: E-CORE-004, .. })` | DynRunnable type mismatch |
| TV-005 | `seq.batch(vec!["x","y","z"], &cfg)` on a two-stage pipeline | `[Ok("X!"), Ok("Y!"), Ok("Z!")]` in input order | Batch through sequence respects order |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC201004-01 | Sequence flattening: `a.pipe(b).pipe(c)` yields a single-level `RunnableSequence` | Unit test (structural check) | Wave 0 |
| VP-BC201004-02 | Token streaming end-to-end: `streaming_a.pipe(streaming_b).stream(x)` emits >1 chunk for a multi-token model output | Integration test | Wave 0 |

## Related BCs

- BC-2.01.003 — Runnable trait invocation (depends on: the composed sequence delegates to invoke/stream via the Runnable trait)
- BC-2.06.001 — Streaming event taxonomy (composes with: each stage in a sequence emits run/step events tagged seq:step:N)
- BC-2.14.001 — PregolyaError 2D struct (depends on: type-mismatch errors propagate via PregolyaError)

## Architecture Anchors

- `pregolya-core/src/runnables/sequence.rs` — `RunnableSequence` struct with `first`, `middle`, `last` and `pipe()` method (to be created)
- `pregolya-core/src/runnables/base.rs` — `Runnable::pipe()` default method implementation (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC201004-01, VP-BC201004-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-002 |
| Capability Anchor Justification | CAP-002 ("Runnable Trait Abstraction (Compose, Pipe, Chain)") per capabilities-p0.md §CAP-002 — this BC implements the pipe composition mechanism (`a.pipe(b)` = `RunnableSequence`) that is explicitly named in CAP-002 as the "compose via `\|` pipe into chains" universal protocol |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), I (integration), ST (streaming) |
| Module | pregolya-core |
