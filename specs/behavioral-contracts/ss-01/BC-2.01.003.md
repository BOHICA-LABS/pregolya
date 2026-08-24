---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.003
version: "2.0"
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
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-49): F-P49-02 — added `recursion_limit` layer disambiguation invariant. Same config key serves two distinct enforcement layers: this BC (nested Runnable call depth, INTERNAL error) vs BC-2.03.001 (BSP super-step ceiling, E-GRAPH-017 POLICY). Cross-reference added to prevent implementer confusion about which halt applies at each layer."
  - "1.2 (ADV-P1D-PASS-56): F-P56-01 — added code: E-CORE-006 to PC5, invariant §layer-disambiguation, EC-004, and TV-004. The Runnable-layer recursion halt was codeless while its graph-engine counterpart (E-GRAPH-017) carried a code. E-CORE-006 (RecursionLimitExceeded, INTERNAL, broken) minted in error-taxonomy.md v1.7."
  - "1.3 (2026-07-15, F-P78-SWEEP/D18-P78-A): E-CORE-006 message-prefix correction at all three BC sites. (1) PC5: was 'recursion limit exceeded' (no prefix, no depth); corrected to 'RecursionLimitExceeded: recursion limit exceeded at depth <depth>' (adds universal <ErrorName>: prefix and harmonizes with EC-004/invariant which already specified depth). (2) Invariant §layer-disambiguation: added 'RecursionLimitExceeded:' prefix to message string. (3) EC-004: added 'RecursionLimitExceeded:' prefix. All three sites now produce the canonical template 'RecursionLimitExceeded: recursion limit exceeded at depth <depth>'. Corresponding taxonomy E-CORE-006 detail corrected from 'nested invoke/stream call depth <depth> exceeded recursion_limit <limit>' to 'recursion limit exceeded at depth <depth>' (BC wins on content). interface-definitions.md dual-layer table row for Runnable-layer also updated to add prefix."
  - "1.4 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-core per module-decomposition.md v1.10."
  - "1.5 (FIX-BURST-B5-WAVE-B/2026-07-29): Error-construction notation sweep (ADR-010 §Class 3). Six sites corrected: PC1 single-line (E-CORE-003, `, ..` added); PC5 single-line (E-CORE-006, `, ..` added before closing `})`); invariant §layer-disambiguation multiline continuation line (E-CORE-006, `, ..` added before closing `})`); EC-001 multiline continuation line (E-CORE-003, `, ..` added); EC-004 multiline continuation line (E-CORE-006, `, ..` added); TV-004 table-cell (E-CORE-006, `, ..` added). All spans have category/code (plus message where present) but lack component and retry_hint."
  - "1.6 (burst-294/F-185-02/2026-08-16): Invariant §recursion_limit-layer-disambiguation — 'at depth N' bare-N placeholder corrected to 'at depth <depth>' (angle-bracket placeholder convention; harmonizes with PC5 and EC-004 canonical template for E-CORE-006). D-134 sibling sweep: sole occurrence of bare-N template placeholder in BC-2.01.003; no other bare-N placeholders present."
  - "1.7 (BURST-303/O-P194-A/2026-08-17): EC-001 generic-arity reconciliation — replaced `DynRunnable<Value, Value>` generic form with canonical non-generic `Arc<dyn DynRunnable>` per architect DynRunnable canon (O-P194-A). DynRunnable is a non-generic trait; Value is the runtime boundary type, not a type parameter."
  - "1.8 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.04 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.9 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "2.0 (M3b/ADR-027-escalation-3/2026-08-24): Added {INV-006} — DynRunnable non-generic design clause; formalizes architect canon O-P194-A (already in v1.7 changelog and EC-001); S-1.04 AC-005 adjudicated as clause-author (real v1 design requirement)."
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

# BC-2.01.003: Runnable Trait Invocation — invoke, stream, batch

## Description

The `Runnable` trait is pregolya-core's universal unit of work. Every implementor must provide
`async fn invoke(&self, input: Self::Input, config: &RunnableConfig) -> Result<Self::Output, PregolyaError>`.
The trait provides default implementations of `stream` (yields a single chunk equal to `invoke` output)
and `batch` (maps `invoke` across inputs with bounded concurrency) so that a type implementing only
`invoke` automatically satisfies the full `Runnable` surface. This contract encodes the LangChain v1
`Runnable` ABC `invoke` abstract-method pattern (semport/core/behavioral-intent.md §1 "Runnables (LCEL)").

## Preconditions

1. {PRE-001} A type `T` implements `Runnable` by providing `async fn invoke(...)`.
2. {PRE-002} The type satisfies `Send + Sync` (required for concurrent batch execution).
3. {PRE-003} The `RunnableConfig` carries optional `max_concurrency`, `recursion_limit` (default 25),
   `tags`, `metadata`, `callbacks`, `run_name`, `run_id`, and `configurable` map.

## Postconditions

1. {PC-001} `runnable.invoke(input, &config).await` returns `Ok(output)` for a valid input, or
   `Err(PregolyaError { category: VAL, code: E-CORE-003, .. })` on input-type mismatch.
2. {PC-002} `runnable.stream(input, &config)` returns a `BoxStream` that yields exactly one chunk equal to
   the `invoke` result when the implementor does not override `stream` (non-streaming fallback).
   A streaming-native implementor may yield multiple chunks.
3. {PC-003} `runnable.batch(inputs, &config).await` returns `Vec<Result<Output, PregolyaError>>`
   in input-insertion order — even though execution is concurrent. Concurrency is bounded by
   `config.max_concurrency` (if `None`, bounded by the tokio thread pool).
4. {PC-004} `runnable.batch_as_completed(inputs, &config)` yields `(usize, Result<Output, _>)` tuples
   out of insertion order but with the index from the original input slice.
5. {PC-005} `recursion_limit` in `RunnableConfig` defaults to 25. Exceeding it in nested Runnable calls
   returns `Err(PregolyaError { category: INTERNAL, code: E-CORE-006, message: "RecursionLimitExceeded: recursion limit exceeded at depth <depth>", .. })`.
6. {PC-006} A child run inherits `tags` and `metadata` (accumulated) and `callbacks` from the parent
   `RunnableConfig`; `run_name` and `run_id` are consumed by the immediate run and not inherited.

## Invariants

- {INV-001} `invoke` is the ONLY required method; all other surface methods have working defaults.
- {INV-002} `batch` output order matches input order — not completion order (unlike `batch_as_completed`).
- {INV-003} Config propagation: `tags` and `metadata` accumulate down the run tree; `run_id`/`run_name`
  are consumed once and not passed to child runs.
- {INV-004} `recursion_limit` is honored across all nested `invoke` / `stream` calls via the task-local
  config mechanism.
- {INV-006} **DynRunnable is non-generic (O-P194-A):** `DynRunnable` is a type-erased, non-generic trait
  with `serde_json::Value` as the runtime input/output boundary type — NOT a generic
  `DynRunnable<Input, Output>`. Type-erased invocation sites hold `Arc<dyn DynRunnable>`.
  This design enables heterogeneous Runnables to be composed at runtime without monomorphization.
  The `Value` boundary applies at the DynRunnable call surface; the concrete `Runnable` impls
  retain their own typed `Input`/`Output` associated types internally.
- {INV-005} **`recursion_limit` layer disambiguation (F-P49-02):** `config.recursion_limit` (default 25)
  is read by TWO independent enforcement layers that share the same `RunnableConfig` key:
  (1) **This BC (Runnable-layer):** counts nested `invoke`/`stream` call depth across chained
  Runnables; exceeding it returns `Err(PregolyaError { category: INTERNAL, code: E-CORE-006,
  message: "RecursionLimitExceeded: recursion limit exceeded at depth <depth>", .. })` — no run-level halt, just a Runnable call error.
  (2) **BC-2.03.001 PC5 (graph-engine-layer):** counts BSP super-steps per invocation segment;
  exceeding it transitions the entire run to `failed` with `Err(E-GRAPH-017
  GraphRecursionLimitExceeded)`. Both layers enforce `recursion_limit = 25` by default; the
  enforcement mechanism and error code differ by layer. Implementers must not conflate the two.

## Edge Cases

### EC-001: invoke with wrong input type (type-erased DynRunnable path)
**Scenario:** An `Arc<dyn DynRunnable>` receives an input that does not conform to the
expected schema at runtime.
**Expected behavior:** Returns `Err(PregolyaError { category: VAL, code: E-CORE-003,
message: "Runnable input type mismatch: expected '<expected>', got '<actual>'", .. })`.
**Reference:** error-taxonomy.md E-CORE-003.

### EC-002: batch with max_concurrency=1 (sequential fallback)
**Scenario:** Caller sets `config.max_concurrency = Some(1)` for a batch of 3 inputs.
**Expected behavior:** Inputs are processed one at a time (sequential). Output order still
matches input order. No timeout or panic occurs.

### EC-003: stream on a non-streaming implementor
**Scenario:** A `RunnableLambda` that returns a full output (not a stream) is called via `stream()`.
**Expected behavior:** The stream yields exactly one chunk — the full `invoke` output. The stream
then terminates. No buffering delay beyond the `invoke` call itself.

### EC-004: Nested recursion limit exceeded
**Scenario:** A `RunnableLambda` wraps another `RunnableLambda` which wraps another, reaching
depth 26 (recursion_limit=25).
**Expected behavior:** The 26th nesting depth returns `Err(PregolyaError { category: INTERNAL,
code: E-CORE-006, message: "RecursionLimitExceeded: recursion limit exceeded at depth 26", .. })`. No stack overflow occurs.

### EC-005: batch with empty input slice
**Scenario:** `runnable.batch(vec![], &config).await`
**Expected behavior:** Returns `Ok(vec![])` immediately. No error, no panic.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `lambda.invoke("hello", &RunnableConfig::default()).await` where lambda returns `input.to_uppercase()` | `Ok("HELLO")` | Happy path — synchronous invoke |
| TV-002 | `lambda.batch(vec!["a","b","c"], &config).await` | `[Ok("A"), Ok("B"), Ok("C")]` — insertion order preserved | Batch ordering invariant |
| TV-003 | `lambda.stream("hello", &config)` (non-streaming) | yields one chunk `"HELLO"`, then terminates | Default stream yields single chunk |
| TV-004 | `lambda.invoke(input, &config)` where config has `recursion_limit: 25` and call depth = 26 | `Err(PregolyaError { category: INTERNAL, code: E-CORE-006, .. })` | Recursion guard |
| TV-005 | `lambda.batch(vec![], &config).await` | `Ok(vec![])` | Empty batch returns empty vec |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC201003-01 | `batch` output indices match input indices under concurrent execution (ordering invariant) | Property test (concurrent batch with shuffled completion order via mock executor) | Wave 0 |
| VP-BC201003-02 | Default `stream` yields exactly one chunk equal to `invoke` result | Unit test | Wave 0 |

## Related BCs

- BC-2.01.004 — Runnable pipe composition (composes with: composed Runnables also satisfy the full Runnable surface via this contract)
- BC-2.01.001 — Typed ContentBlock construction (composes with: message Runnables input/output typed content)
- BC-2.14.001 — PregolyaError 2D struct (depends on: all invoke/stream/batch error paths use PregolyaError)
- BC-2.14.003 — Constructor Result contract (depends on: Runnable construction returns Result)

## Architecture Anchors

- `pregolya-core/src/runnables/base.rs` — `Runnable` trait definition with default `batch`/`stream` (to be created)
- `pregolya-core/src/runnables/config.rs` — `RunnableConfig` struct and `merge_configs` (to be created)

## Story Anchor

S-1.04

## VP Anchors

- VP-BC201003-01, VP-BC201003-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-002 |
| Capability Anchor Justification | CAP-002 ("Runnable Trait Abstraction (Compose, Pipe, Chain)") per capabilities-p0.md §CAP-002 — this BC defines the mandatory `invoke` method plus the `stream`/`batch` defaults that form the universal composition protocol all pregolya crates depend on |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), P (property) |
| Module | pregolya-core |
