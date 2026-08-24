---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.007
version: "1.4"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-01
capability: CAP-039
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-08-24T00:00:00Z
di_anchors: [DI-014]
changelog:
  - "1.0 (burst-302b/D-170/2026-08-17): Initial — RunnablePassthrough identity pass-through semantics and inspect side-effect contract. LCEL composition scope expansion (D-170); ADR-026 §Decision 3."
  - "1.1 (BURST-303/F-P194-01/2026-08-17): DynRunnable canon alignment — replaced all `invoke_dyn` with `invoke` and `stream_dyn` with `stream` in DynRunnable context per architect canon (F-P194-01). DynRunnable canonical methods are `invoke` and `stream`; `invoke_dyn`/`stream_dyn` belong to DynTool. Signature uses `config: Option<RunnableConfig>`."
  - "1.2 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.05 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.3 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.4 (P2A-044 F-06/2026-08-24): P2A-044 F-06: compressed-ordinal citations normalized to stable tags."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-039
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-026-lcel-composition-primitives-parallel-passthrough.md
input-hash: "4ccce82"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.007: RunnablePassthrough Identity Pass-Through and Inspect Side-Effect Contract

## Description

`RunnablePassthrough` is pregolya-core's zero-cost identity runnable: `invoke(input)`
always returns `Ok(input.clone())` — the output is structurally identical to the input.
An optional `inspect_fn: Arc<dyn Fn(&serde_json::Value) + Send + Sync>` may be attached
for read-only side effects (logging, tracing, debug inspection). The inspect function is
called with a reference to the input **before** the Ok return; it MUST NOT alter the return
value. `RunnablePassthrough` implements `DynRunnable` and composes freely via `pipe()`.
It is also the construction entry point for `RunnableAssign` (via `RunnablePassthrough::assign`).

## Preconditions

1. {PRE-001} `RunnablePassthrough::new()` is called (no inspect function), OR
   `RunnablePassthrough::with_inspect(f)` is called with a `Fn(&Value) + Send + Sync + 'static`
   closure.
2. {PRE-002} The resulting `RunnablePassthrough` is invoked via `invoke(input, config)`.
3. {PRE-003} If an `inspect_fn` is present, it is callable with the input reference without
   panicking (caller responsibility).

## Postconditions

1. {PC-001} `invoke(input, config)` returns `Ok(input.clone())` — the returned value is
   structurally and semantically identical to the input. The output is a deep clone, not
   the same owned value.
2. {PC-002} If `inspect_fn` is `Some(f)`: `f(&input)` is called exactly once with an immutable
   reference to `input` **before** the `Ok(input.clone())` is returned. The call is
   synchronous; the function must not block the async executor.
3. {PC-003} If `inspect_fn` is `None`: no side-effect call occurs.
4. {PC-004} The return value of `inspect_fn` (if any) is discarded. `inspect_fn` cannot alter
   the output of `invoke`.
5. {PC-005} `stream(input, config)` passes each incoming chunk through unchanged — each chunk
   in the stream is `Ok(chunk)` with the chunk value equal to the received chunk.
6. {PC-006} For `stream` with an `inspect_fn`: the function is called once after the stream
   is exhausted with the accumulated input value (the reassembled whole, if addable, or
   the last chunk if not addable). This mirrors the Python `RunnablePassthrough.transform`
   behavior of accumulating then calling `func`.
7. {PC-007} `RunnablePassthrough` never returns `Err` on its own — it cannot fail. Any `Err`
   in the output stream originates from an upstream producer, not from the passthrough itself.

## Invariants

- {INV-001} **True identity:** `invoke(v, cfg) == Ok(v.clone())` for all `v`. The return value
  is a fresh clone of the input — not the same owned `Value`, but structurally identical.
- {INV-002} **Inspect does not alter output:** `f(&input)` is called, but the return value is
  discarded. `inspect_fn` has no mechanism to mutate `input` or the return value (it
  receives only `&Value`, not `&mut Value`).
- {INV-003} **Infallibility:** `RunnablePassthrough::invoke` NEVER returns `Err`. If a caller
  receives `Err` from a pipeline containing `RunnablePassthrough`, the error originated
  upstream or downstream.
- {INV-004} **Streaming identity:** each chunk passes through unchanged; no buffering in the
  non-inspect path.
- {INV-005} **`#[non_exhaustive]` struct:** external callers use `RunnablePassthrough::new()` or
  `::with_inspect(f)`; struct-literal construction is barred (ADR-023 §Required Inventory).

## Edge Cases

### EC-001: Input is `Value::Null`

**Scenario:** `invoke(Value::Null, None)` with no inspect function.
**Expected behavior:** Returns `Ok(Value::Null)`. No special handling for Null.

### EC-002: inspect_fn panics

**Scenario:** `inspect_fn` panics with "inspection failed".
**Expected behavior:** The panic propagates up from `invoke`. This is a programming
error in the inspect function; `RunnablePassthrough` does not catch panics in `inspect_fn`
(the inspect contract requires the function to be non-panicking in production use).
The panic will be caught by the `JoinSet` task boundary if inside a `RunnableParallel`
(BC-2.01.006 EC-003 JoinError path).

### EC-003: Streaming — inspect_fn accumulation

**Scenario:** `stream` emits 5 addable chunks (`Value::String` chunks from an LLM);
`inspect_fn` is present.
**Expected behavior:** All 5 chunks pass through as-is to the downstream consumer.
After the upstream stream is exhausted, `inspect_fn` is called once with the accumulated
full string value. No latency added to individual chunks (accumulation happens in parallel
with downstream processing; inspect call is after full accumulation).

### EC-004: Pipe composition — RunnablePassthrough as intermediate stage

**Scenario:** `prompt.pipe(passthrough).pipe(model)` where `passthrough` has an inspect
function that logs the prompt value.
**Expected behavior:** The prompt value flows through `passthrough` unchanged (same
`Value::Object` semantics) to `model`. The `inspect_fn` is called with the prompt value
for logging, but does not alter it. The pipeline behaves identically to `prompt.pipe(model)`.

### EC-005: with_inspect closure captures shared state

**Scenario:** `RunnablePassthrough::with_inspect(|v| { counter.fetch_add(1, Relaxed); })`
where `counter` is an `Arc<AtomicUsize>`.
**Expected behavior:** The closure is valid since it implements `Fn(&Value) + Send + Sync`.
Each `invoke` call increments the counter once. Concurrent calls from parallel branches
serialize on the atomic increment.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `RunnablePassthrough::new().invoke(Value::String("hello".into()), None)` | `Ok(Value::String("hello".into()))` | Identity pass-through; no inspect |
| TV-002 | `RunnablePassthrough::new().invoke(Value::Object({...}), None)` | `Ok(Value::Object({...}))` — structurally identical object | Object identity |
| TV-003 | `with_inspect(log_fn).invoke(v, None)` | `Ok(v.clone())` AND `log_fn` called once with `&v` | Inspect called before return |
| TV-004 | `invoke(v, None)` where v is a large nested JSON tree | `Ok(v.clone())` — deep clone, not alias | Deep clone invariant |
| TV-005 | `stream` with 3 chunks; inspect_fn present | All 3 chunks emitted unchanged; inspect_fn called once after exhaustion | Streaming identity + inspect accumulation |

## Verification Properties

_No Kani VP targeted at this BC — RunnablePassthrough is trivially correct (identity function);
proptest and unit tests are sufficient to verify the clone-identity invariant._

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| _(none)_ | RunnablePassthrough identity is a structural property verified by unit tests | unit | 1 |

## Related BCs

- BC-2.01.008 — RunnableAssign dict augmentation (depends on: RunnablePassthrough::assign() is the factory method that constructs RunnableAssign; this BC defines the container for RunnableAssign's mapper)
- BC-2.01.005 — RunnableParallel construction (composes with: RunnablePassthrough::assign() wraps a RunnableParallel as its mapper)
- BC-2.01.004 — Runnable pipe composition (depends on: RunnablePassthrough implements DynRunnable and composes via pipe())

## Architecture Anchors

- `pregolya-core/src/runnables/passthrough.rs` — `RunnablePassthrough` struct and `DynRunnable` impl (to be created)
- ADR-026 §Decision 3 — zero-cost identity semantics, inspect_fn side-effect contract, streaming accumulation-then-inspect pattern

## Story Anchor

S-1.05

## VP Anchors

_(none — unit tests sufficient)_

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-039 |
| Capability Anchor Justification | CAP-039 ("LCEL Map/Passthrough Composition: RunnableParallel and RunnablePassthrough") per capabilities-p1-p2.md §CAP-039 (D-170) — this BC describes the identity semantics and inspect side-effect contract of `RunnablePassthrough`, the second named component of CAP-039 per ADR-026 §Decision 3. |
| L2 Domain Invariants | DI-014 (Error Propagation: No Silent Swallowing — PC-007 enforces that RunnablePassthrough never silently drops errors from upstream; the passthrough itself is infallible, so no errors originate from it) |
| NE References | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), ST (streaming) |
| Module | pregolya-core |
