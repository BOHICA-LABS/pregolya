---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.003
version: "2.9"
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
timestamp: 2026-08-29T00:00:00Z
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
  - "2.1 (P2A-044 F-06/2026-08-24): P2A-044 F-06: compressed-ordinal citations normalized to stable tags."
  - "2.2 (P2-bc-completeness-burst-B/SS-01..03/2026-08-26): Gap BC-2.01.003 LOW — default-stream item type and invoke-Err streaming behavior were unspecified. Updated PC-002 to name the stream item type as `Result<Self::Output, PregolyaError>` and specify that an invoke Err is yielded as a single `Err(e)` stream item (stream does not propagate as an outer error). Added {EC-006} as a canonical test vector for the error-in-stream path."
  - "2.3 (round-34/F-P2A144-01+F-P2A144-02/2026-08-29): F-P2A144-01 [HIGH] — signature citations updated from bare `async fn` to explicit RPITIT + Send form per interface-definitions.md §Runnable<Input,Output> canon (ADR-005 §Send-Bounded RPITIT). Description: `async fn invoke(...)` → `fn invoke(...) -> impl std::future::Future<Output = ...> + Send`. PRE-001: `async fn invoke(...)` → `fn invoke(...) -> impl Future<Output = ...> + Send` with Send-bounded RPITIT rationale added. F-P2A144-02 [MED] — §Architecture Anchors module-path drift: `src/runnables/base.rs` → `src/runnable/base.rs`; `src/runnables/config.rs` → `src/runnable/config.rs` per module-decomposition.md §core::runnable canonical singular form."
  - "2.4 (round-36/F-P2A152-01+F-P2A152-02/2026-08-29): F-P2A152-01 [HIGH] — three structural contradictions reconciled to interface-definitions.md §Runnable<Input,Output> authority. (a) Associated-type form (`Self::Input`/`Self::Output`) replaced throughout with generic-parameter form (`Input`/`Output`) — associated types are non-realizable with multiple blanket impls (E0107). Description, all PCs, TVs updated. (b) Borrowed `config: &RunnableConfig` replaced with owned `config: Option<RunnableConfig>` at all call sites (Description, {PC-001}, {PC-002}, {PC-003}, EC-006, TVs). (c) `stream()` reconciled to async form: the outer future returns `Result<impl Stream<...>, PregolyaError>` (not a synchronous `BoxStream`); {PC-002} and EC-006 updated to describe `Ok(stream)` outer result with error surfaced as stream item in the default non-streaming fallback. F-P2A152-02 [MED] — phantom RunnableConfig surface purged. {PRE-003}: phantom fields `max_concurrency`, `tags`, `metadata`, `callbacks`, `run_name`, `run_id` removed; canonical 5 fields enumerated (`recursion_limit`, `thread_id`, `budget_config`, `context_mutations`, `configurable`). {PC-003}: `config.max_concurrency` phantom reference removed; Tokio-runtime bounded concurrency documented. {PC-004}: phantom `batch_as_completed` method replaced with `pipe` postcondition (canonical four-method surface stated). {PC-006}: phantom tag/metadata/callback/run_name/run_id inheritance replaced with correct Option<RunnableConfig> pass-through statement. {INV-002}: `batch_as_completed` reference removed. {INV-003}: phantom field propagation replaced with correct config-forwarding statement. EC-002: `max_concurrency=Some(1)` scenario replaced with `config=None` batch scenario. Corpus grep confirms `max_concurrency`/`batch_as_completed`/`run_name` appear ONLY in BC-2.01.003 (no sibling sweep required). `callbacks` also appears in BC-2.01.004 {PC-006} — flagged for product-owner to address in a follow-on burst (outside this mandate). TVs updated to `Option<RunnableConfig>` call form and outer-Ok for batch."
  - "2.5 (round-37/F-P2A158-01/2026-08-29): F-P2A158-01 [HIGH] — §Architecture Anchors: `RunnableConfig` module anchor corrected from `pregolya-core/src/runnable/config.rs` to `pregolya-core/src/config.rs` (`core::config`) with re-export at crate root, per ADR-025 / interface-definitions.md canon and architect directive (canonical anchor `pregolya-core/src/config.rs`, `core::config`, re-exported at crate root; `src/runnable/config.rs` is the former stale path)."
  - "2.6 (round-38/F-P2A160-01/2026-08-29): F-P2A160-01 [HIGH] — Mirror architect's serde-bounded DynRunnable blanket canon into BC layer. (1) {INV-006}: replaced stale 'associated types' phrasing with 'generic type parameters'; formalizes that the serde-bounded blanket `impl<I, O, T> DynRunnable for T where T: Runnable<I, O> + Send + Sync + 'static, I: serde::de::DeserializeOwned + Send + 'static, O: serde::Serialize + Send + 'static` handles the `Value ↔ I/O` round-trip INTERNALLY — the blanket deserializes `Value → I` (raising E-CORE-003 on failure), calls `Runnable<I,O>::invoke`, then serializes `O → Value`; callers are NOT responsible for JSON round-tripping. (2) {PC-001}: added DynRunnable-boundary note specifying E-CORE-003 is raised when `serde_json::from_value::<I>(input)` fails at the blanket boundary (before typed invoke is called). interface-definitions.md §DynRunnable is the authoritative canon (R38)."
  - "2.7 (round-39/F-P2A164-01+OPT-PC1/2026-08-29): F-P2A164-01 [CRIT] — DynRunnable adapter model replacing non-realizable E0207 serde-bounded blanket. {INV-006}: serde-bounded blanket `impl<I, O, T> DynRunnable for T` replaced with adapter model: 'Typed-stage coercion to Box<dyn DynRunnable> is performed via DynRunnableAdapter<I, O, R> where R: Runnable<I, O>. DynRunnableAdapter handles the Value↔I/O round-trip INTERNALLY; E-CORE-003 raised at the ADAPTER boundary (not the blanket boundary); R::invoke called.' {PC-001}: 'via the DynRunnable serde-bounded blanket impl' and 'at the blanket boundary' replaced with 'via DynRunnableAdapter<I, O, R>' and 'at the ADAPTER boundary'; 'Runnable<I, O>::invoke called on the concrete typed impl' corrected to 'R::invoke called on the concrete typed impl'. OPT-PC1 [OBS] — {PC-004}: 'BC-2.01.004 PC1' old-form ordinal corrected to 'BC-2.01.004 {PC-001}' stable-tag form (verify-ordinal-form-residue advisory). interface-definitions.md §DynRunnable + ADR-005 §Send-Bounded RPITIT + ADR-029 §Decision 5 are the authoritative canon (R39)."
  - "2.8 (round-42/F-P2A176-01/2026-08-29): F-P2A176-01 [HIGH] — Replace Tokio-thread-pool-bounded batch language with architect canon. Description: 'via the Tokio runtime' → 'via `futures::future::join_all` within the calling task — no spawn, no Tokio thread-pool'. {PC-003}: 'Concurrency is bounded by the Tokio thread-pool; there is no per-invocation concurrency cap in `RunnableConfig` (no `max_concurrency` field).' replaced with full join_all canon: default `batch` uses in-task cooperative concurrency via `futures::future::join_all` (or `FuturesOrdered`) — polls all `invoke` futures concurrently within the calling task; no spawn, no thread-pool parallelism; input order preserved. Includes `JoinSet::spawn` impossibility rationale: `+ Send` RPITIT future from `invoke(&self, ..)` borrows `&self` and is NOT `'static`; `JoinSet::spawn` (requires `F: Future + Send + 'static`) CANNOT be used in a default `&self` method. Notes implementor override path for `'static`/`Arc<Self>` state. EC-002 updated to use 'in-task cooperative concurrency via `futures::future::join_all`' language. {INV-002} order-preservation unchanged. No per-invocation cap language remains."
  - "2.9 (round-43/F-P2A180-01/2026-08-30): F-P2A180-01 [HIGH] — {PC-002} stream return type corrected from nested `impl Trait` form (E0562-invalid on stable Rust) to boxed form. OLD: `Result<impl Stream<Item = Result<Output, PregolyaError>> + Send, PregolyaError>`. NEW: `Result<Pin<Box<dyn Stream<Item = Result<Output, PregolyaError>> + Send>>, PregolyaError>`. Nested `impl Trait` inside `impl Future<Output=...>` binding is rejected by stable Rust E0562; the canonical realizable form boxes the yielded stream via `Pin<Box<dyn Stream<...>>>`. Canonical function signature: `fn stream(&self, input: Input, config: Option<RunnableConfig>) -> impl std::future::Future<Output = Result<Pin<Box<dyn Stream<Item = Result<Output, PregolyaError>> + Send>>, PregolyaError>> + Send` per interface-definitions.md §Runnable (v3.00)."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-002
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "56f0a6f"
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

The `Runnable` trait is pregolya-core's universal unit of work. `Runnable<Input, Output>` uses
**generic parameters** (not associated types); `BaseChatModel: Runnable<Vec<Message>, AiMessage>` and
`Tool: Runnable<ToolInput, ToolOutput>` are distinct instantiations without trait conflicts (E0107). Every
implementor must provide
`fn invoke(&self, input: Input, config: Option<RunnableConfig>) -> impl std::future::Future<Output = Result<Output, PregolyaError>> + Send`
(generic-parameter form; RPITIT + Send form per ADR-005 §Send-Bounded RPITIT).
The trait provides a default implementation of `stream` (async; outer future resolves to `Ok(stream)` that
yields a single chunk equal to the `invoke` result as a stream item) and `batch` (maps `invoke` across
inputs concurrently via `futures::future::join_all` within the calling task — no spawn, no Tokio
thread-pool) so that a type implementing only `invoke` automatically satisfies
the full `Runnable` surface. This contract encodes the LangChain v1 `Runnable` ABC `invoke` abstract-method
pattern (semport/core/behavioral-intent.md §1 "Runnables (LCEL)").

## Preconditions

1. {PRE-001} A type `T` implements `Runnable` by providing `fn invoke(...) -> impl Future<Output = Result<...>> + Send` (RPITIT + Send form; bare `async fn` is not permitted as it lacks a `Send` bound on the returned future — required for the `DynRunnable` blanket impl to compile on stable Rust per ADR-005 §Send-Bounded RPITIT).
2. {PRE-002} The type satisfies `Send + Sync` (required for concurrent batch execution).
3. {PRE-003} The `RunnableConfig` carries exactly five fields: `recursion_limit: usize` (default 25),
   `thread_id: Option<Uuid>`, `budget_config: Option<BudgetConfig>`,
   `context_mutations: Option<ContextMutationConfig>`, and `configurable: Option<HashMap<String, Value>>`.
   External callers construct via `RunnableConfig::default()` (all Option fields `None`,
   `recursion_limit = 25`). There is no `max_concurrency`, `tags`, `metadata`, `callbacks`,
   `run_name`, or `run_id` field on `RunnableConfig`.

## Postconditions

1. {PC-001} `runnable.invoke(input, config).await` (where `config: Option<RunnableConfig>`) returns
   `Ok(output)` for a valid input, or `Err(PregolyaError { category: VAL, code: E-CORE-003, .. })`
   on input-type mismatch.
   When invoked via `DynRunnableAdapter<I, O, R>`, `E-CORE-003` is specifically
   raised when `serde_json::from_value::<I>(input)` fails at the ADAPTER boundary — before
   `R::invoke` is called on the concrete typed impl.
2. {PC-002} `runnable.stream(input, config).await` (where `config: Option<RunnableConfig>`) returns
   `Result<Pin<Box<dyn Stream<Item = Result<Output, PregolyaError>> + Send>>, PregolyaError>`.
   The outer `Result` covers pre-stream initialization failures; each item yielded by the inner stream
   is a `Result<Output, PregolyaError>`.
   When the implementor does not override `stream` (non-streaming fallback): the outer future resolves to
   `Ok(stream)`, then the stream yields exactly one chunk equal to the `invoke` result:
   - If `invoke` returns `Ok(output)`, the stream yields `Ok(output)` as its single item and then terminates.
   - If `invoke` returns `Err(e)`, the stream yields `Err(e)` as its single item and then terminates.
     The error is surfaced as a stream item inside an `Ok(stream)` outer result — callers must poll
     stream items to discover the error; the outer `Result` is `Ok` in the default fallback.
   A streaming-native implementor may override `stream` to yield multiple chunks; each chunk is still a `Result`.
3. {PC-003} `runnable.batch(inputs, config).await` (where `config: Option<RunnableConfig>`) returns
   `Result<Vec<Result<Output, PregolyaError>>, PregolyaError>` with inner results in input-insertion
   order — even though execution is concurrent. The default `batch` uses in-task cooperative
   concurrency via `futures::future::join_all` (or `FuturesOrdered`) — polls all `invoke` futures
   concurrently within the calling task; no spawn, no thread-pool parallelism; input order preserved.
   The `+ Send` RPITIT future from `invoke(&self, ..)` borrows `&self` and is NOT `'static`;
   `JoinSet::spawn` (requires `F: Future + Send + 'static`) CANNOT be used in a default `&self`
   method. Implementors owning `'static`/`Arc<Self>` state MAY override `batch` to spawn via
   `JoinSet` for true parallelism.
4. {PC-004} `runnable.pipe(next)` returns a concrete `RunnableSequence<Input, NextOutput>`
   (BC-2.01.004 {PC-001}). The canonical `Runnable<Input, Output>` surface has exactly four methods:
   `invoke`, `stream`, `batch`, `pipe`. There is no `batch_as_completed` method on the `Runnable` trait.
5. {PC-005} `recursion_limit` in `RunnableConfig` defaults to 25. Exceeding it in nested Runnable calls
   returns `Err(PregolyaError { category: INTERNAL, code: E-CORE-006, message: "RecursionLimitExceeded: recursion limit exceeded at depth <depth>", .. })`.
6. {PC-006} The `Option<RunnableConfig>` passed to `invoke`/`stream`/`batch` is forwarded as-is to
   each nested `Runnable` invocation. The `Runnable` trait imposes no automatic field accumulation,
   stripping, or inheritance — callers compose `RunnableConfig` explicitly for each level. The only
   field semantically consumed (depth-counted) during forwarding is `recursion_limit` per {PC-005}/{INV-005}.

## Invariants

- {INV-001} `invoke` is the ONLY required method; all other surface methods have working defaults.
- {INV-002} `batch` output order matches input order — not completion order (execution is concurrent but results are reordered to match input position).
- {INV-003} Config forwarding: `Option<RunnableConfig>` is passed unchanged to each child `invoke`/`stream`/`batch` call.
  The `Runnable` trait imposes no field accumulation or stripping. Only `recursion_limit` is semantically
  consumed (depth-counted) by the recursion guard per {INV-005}.
- {INV-004} `recursion_limit` is honored across all nested `invoke` / `stream` calls via the task-local
  config mechanism.
- {INV-006} **DynRunnable is non-generic (O-P194-A):** `DynRunnable` is a type-erased, non-generic trait
  with `serde_json::Value` as the runtime input/output boundary type — NOT a generic
  `DynRunnable<Input, Output>`. Type-erased invocation sites hold `Arc<dyn DynRunnable>`.
  This design enables heterogeneous Runnables to be composed at runtime without monomorphization.
  Typed-stage coercion to `Box<dyn DynRunnable>` is performed via `DynRunnableAdapter<I, O, R>`
  where `R: Runnable<I, O>`. `DynRunnableAdapter` handles the `Value ↔ I/O` round-trip
  INTERNALLY: it deserializes `Value → I` via `serde_json::from_value::<I>` (raising
  `E-CORE-003` on failure at the ADAPTER boundary — not the blanket boundary), calls `R::invoke`,
  then serializes `O → Value`. Concrete `Runnable` impls retain their own typed `Input`/`Output`
  generic type parameters internally; callers are NOT responsible for JSON round-tripping at the
  `DynRunnable` boundary.
- {INV-005} **`recursion_limit` layer disambiguation (F-P49-02):** `config.recursion_limit` (default 25)
  is read by TWO independent enforcement layers that share the same `RunnableConfig` key:
  (1) **This BC (Runnable-layer):** counts nested `invoke`/`stream` call depth across chained
  Runnables; exceeding it returns `Err(PregolyaError { category: INTERNAL, code: E-CORE-006,
  message: "RecursionLimitExceeded: recursion limit exceeded at depth <depth>", .. })` — no run-level halt, just a Runnable call error.
  (2) **BC-2.03.001 PC-005 (graph-engine-layer):** counts BSP super-steps per invocation segment;
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

### EC-002: batch with config=None (default config)
**Scenario:** Caller invokes `runnable.batch(vec!["a","b","c"], None).await`.
**Expected behavior:** Each input is processed concurrently via `futures::future::join_all` within
the calling task (in-task cooperative concurrency — no spawn, no thread-pool) with
`RunnableConfig::default()` semantics for recursion limit and other fields. Results are returned
in input-insertion order regardless of completion order. `RunnableConfig` has no `max_concurrency`
field — concurrency is bounded by the number of polled futures, not by a per-invocation cap.
Returns `Ok(vec![Ok("A"), Ok("B"), Ok("C")])`. No timeout or panic occurs.

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

### EC-006: stream on a Runnable whose invoke returns Err
**Scenario:** A `RunnableLambda` that always returns
`Err(PregolyaError { category: VAL, code: E-CORE-003, .. })` is called via `stream()`.
**Expected behavior:** Awaiting `stream(input, None)` resolves to `Ok(stream)` — the outer `Result`
is `Ok`. Polling the stream yields exactly one item:
`Err(PregolyaError { category: VAL, code: E-CORE-003, .. })`. The stream then terminates.
The error is surfaced as a stream item inside the `Ok(stream)` outer result; the outer future from
`stream()` resolves to `Ok`, not `Err`. Callers must poll stream items to discover the error.
`stream()` itself does not panic.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `lambda.invoke("hello", None).await` where lambda returns `input.to_uppercase()` | `Ok("HELLO")` | Happy path — invoke with default config |
| TV-002 | `lambda.batch(vec!["a","b","c"], None).await` | `Ok(vec![Ok("A"), Ok("B"), Ok("C")])` — insertion order preserved | Batch ordering invariant; outer Ok wraps the Vec |
| TV-003 | `lambda.stream("hello", None).await` (non-streaming) | `Ok(stream)` — polling stream yields one item `Ok("HELLO")`, then terminates | Async stream form; outer future resolves to Ok; single Ok chunk per default non-streaming impl |
| TV-004 | `lambda.invoke(input, Some(config))` where `config.recursion_limit = 25` and call depth = 26 | `Err(PregolyaError { category: INTERNAL, code: E-CORE-006, .. })` | Recursion guard |
| TV-005 | `lambda.batch(vec![], None).await` | `Ok(vec![])` | Empty batch returns outer Ok with empty Vec |

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

- `pregolya-core/src/runnable/base.rs` — `Runnable` trait definition with default `batch`/`stream` (to be created)
- `pregolya-core/src/config.rs` (`core::config`) — `RunnableConfig` struct and `merge_configs`, re-exported at crate root (to be created)

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
