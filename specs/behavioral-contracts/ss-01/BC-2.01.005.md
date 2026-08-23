---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.005
version: "1.5"
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
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-016, DI-014]
changelog:
  - "1.0 (burst-302b/D-170/2026-08-17): Initial — RunnableParallel construction and concurrent invocation. LCEL composition scope expansion (D-170); ADR-026 §Decision 1."
  - "1.1 (BURST-303/F-P194-01/2026-08-17): DynRunnable canon alignment — replaced all `invoke_dyn` with `invoke` and `stream_dyn` with `stream` in DynRunnable context per architect canon (F-P194-01). DynRunnable canonical methods are `invoke` and `stream`; `invoke_dyn`/`stream_dyn` belong to DynTool. Signature uses `config: Option<RunnableConfig>`."
  - "1.2 (BURST-312/F-P203-02/2026-08-17): Capability Anchor Justification quote-fidelity fix — replaced single ADR-026 §Decision 1 citation that incorrectly claimed 'type representation and concurrent execution' (Decision 1 covers key ordering only; concurrent execution is Decision 2) with two separate single-§ citations per POL-19: §Decision 1 (RunnableParallel: Type Representation and Key Ordering) and §Decision 2 (RunnableParallel: Concurrent Execution and Error Handling). F-P203-02."
  - "1.3 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.05 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.4 (F-036-01/P2A-036-adjudication/2026-08-22): Duplicate-step-key edge case gap closed (adjudication of STORY-S-1.05 AC-001 conflict vs BC infallible contract). PC-1 postcondition clarified: 'all provided branches' means after IndexMap last-write-wins deduplication; duplicate keys do NOT cause Err — this is intentional parity with Python RunnableParallel dict semantics per ADR-026 §Decision 1. Added EC-006 (Duplicate step key — last-write-wins) and TV-006. Story AC-001 fallible-constructor assertion must be removed by story-writer (STORY-S-1.05 AC-001 conflicts with infallible contract)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
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

# BC-2.01.005: RunnableParallel Construction and Concurrent Invocation

## Description

`RunnableParallel` is pregolya-core's fan-out composition primitive: it accepts an ordered
map of named branches (each an `Arc<dyn DynRunnable>`) and runs all branches concurrently
against the **same** input value when invoked. The result is a `serde_json::Value::Object`
with exactly one key per configured branch, in insertion order. Key ordering is
deterministic (backed by `IndexMap`) and does not depend on task completion order.
`RunnableParallel` implements `DynRunnable` and composes via `pipe()` with any other
pregolya `Runnable`.

## Preconditions

1. {PRE-001} `RunnableParallel::new(steps)` receives an iterator of `(key, Arc<dyn DynRunnable>)` pairs
   where each key is a non-empty `String`.
2. {PRE-002} The resulting `RunnableParallel` holds `N ≥ 0` configured branches in insertion order
   (an `IndexMap<String, Arc<dyn DynRunnable>>`).
3. {PRE-003} The caller invokes `invoke(input, config)` on the constructed `RunnableParallel`.
4. {PRE-004} All `N` branches are available (not dropped or deallocated) at invocation time.

## Postconditions

1. {PC-001} `RunnableParallel::new(steps)` returns a `RunnableParallel` (infallible — never returns
   `Err`) containing the deduplicated set of provided branches in insertion order.
   Duplicate keys are resolved by last-write-wins (`IndexMap` insert semantics): if the
   iterator yields `("a", fn1)` followed by `("a", fn2)`, the resulting map contains a
   single entry keyed `"a"` bound to `fn2`. This matches Python `RunnableParallel` dict
   semantics per ADR-026 §Decision 1.
2. {PC-002} `invoke(input, config)` fans out `N` Tokio tasks concurrently — all tasks launch
   before any result is awaited; each task receives an independent clone of `input` and
   `config`.
3. {PC-003} On success (all `N` branches return `Ok`): returns
   `Ok(serde_json::Value::Object(map))` where `map` has **exactly `N` keys**, each key
   equal to its branch's configured name, and key order matches the `steps` insertion order
   regardless of task completion order.
4. {PC-004} The output object key order equals the `steps` `IndexMap` insertion order —
   verified by re-inserting results keyed by `self.steps.keys()` after collection.
5. {PC-005} Every branch receives the **same** `input` value — branches share the same logical input,
   not different slices of it.
6. {PC-006} If `N == 0`, returns `Ok(Value::Object(Map::new()))` — an empty object is a valid
   successful result.

## Invariants

- {INV-001} **Insertion-order output:** output key order is always the `steps` insertion order,
  regardless of which task completed first (collected into an intermediate `Vec` and then
  re-inserted in `steps.keys()` order).
- {INV-002} **All-or-nothing success:** either all `N` branches contribute a key to the output object,
  or the invocation returns `Err` (see BC-2.01.006 for the failure case).
- {INV-003} **Independent input clones:** each branch's task receives `input.clone()` and
  `config.clone()`; no branch can observe mutations made by another branch (each has its
  own owned copy).
- {INV-004} **DynRunnable implementation:** `RunnableParallel` implements `DynRunnable`
  (both `invoke` and `stream`), enabling composition via `pipe()` (BC-2.01.004).
- {INV-005} **`#[non_exhaustive]` struct:** external callers construct via `RunnableParallel::new(...)`;
  struct-literal construction is barred (ADR-023 §Required Inventory).

## Edge Cases

### EC-001: Zero-branch RunnableParallel

**Scenario:** `RunnableParallel::new([])` with no branches; `invoke` called.
**Expected behavior:** Returns `Ok(Value::Object(Map::new()))` — an empty object.
No tasks spawned, no `join_next` awaited. This is a degenerate but valid configuration.

### EC-002: Single-branch RunnableParallel

**Scenario:** One branch only; `invoke` called.
**Expected behavior:** Returns `Ok(Value::Object({ "key": branch_output }))`. The single
task runs as a fan-out of one. Output is a one-key object; no concurrency overhead, but
still goes through the `JoinSet` path (no special-casing for `N == 1`).

### EC-003: Input value is `Value::Null`

**Scenario:** `invoke(Value::Null, None)` on a three-branch parallel.
**Expected behavior:** All three branches receive `Value::Null` as input. Each branch runs
its own logic on `Value::Null`. The output is a three-key object with each branch's
response. No input-type validation at the `RunnableParallel` level (branches validate
their own inputs).

### EC-004: Input is a large JSON array

**Scenario:** `invoke(Value::Array(vec![...100_items...]))` on a two-branch parallel.
**Expected behavior:** Each branch receives a clone of the full array. No truncation.
Memory usage: O(branches × input_size) per invocation.

### EC-006: Duplicate step key — last-write-wins (infallible)

**Scenario:** `RunnableParallel::new([("a", fn1), ("a", fn2)])` — the key `"a"` appears
twice in the input iterator.
**Expected behavior:** Construction succeeds (no `Err`). The resulting `RunnableParallel`
contains one branch keyed `"a"` bound to `fn2` (the later entry wins). `invoke` runs a
single-branch parallel and returns `Ok(Object({ "a": fn2_output }))`. `fn1` is never
executed. This is identical to Python `RunnableParallel({"a": fn2})` — Python's dict
literal overwrites the earlier value silently, and the Rust port inherits that semantic
via `IndexMap` per ADR-026 §Decision 1.

### EC-005: Branches with heterogeneous output types

**Scenario:** Branch "a" returns `Value::String("hello")`, branch "b" returns
`Value::Number(42)`.
**Expected behavior:** Returns `Ok(Value::Object({ "a": "hello", "b": 42 }))`. Branches
may produce heterogeneous `Value` variants — the parallel combinator does not enforce
uniform output types.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `RunnableParallel::new([("upper", upper_fn), ("lower", lower_fn)]).invoke(Value::String("Hello"), None)` | `Ok(Object({ "upper": "HELLO", "lower": "hello" }))` | Happy path: 2-branch parallel, string input |
| TV-002 | `RunnableParallel::new([]).invoke(Value::Null, None)` | `Ok(Object({}))` | Zero-branch returns empty object |
| TV-003 | 3-branch parallel where output order should equal insertion order `["a", "b", "c"]` regardless of which branch finishes first | `Object` keys in order `["a", "b", "c"]` | Insertion-order invariant |
| TV-004 | 2-branch parallel; inspect that both branches receive `Value::Number(1)` (the same input) | Both branches invoked with `Value::Number(1)` | Independent input-clone invariant |
| TV-005 | `invoke` on a parallel with `N == 1` branch | `Ok(Object({ "only": <output> }))` | Single-branch degenerate case |
| TV-006 | `RunnableParallel::new([("a", fn1), ("a", fn2)]).invoke(Value::Null, None)` | `Ok(Object({ "a": fn2_output }))` — fn1 never called; construction did not Err | Duplicate-key last-write-wins (EC-006) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-014 | For any N-branch RunnableParallel, if `invoke` returns `Ok(output)`: `output.as_object().len() == N` AND output key set equals configured branch key set | proptest | 3 |

## Related BCs

- BC-2.01.006 — RunnableParallel branch failure (composes with: this BC covers the success path; BC-2.01.006 covers the failure path)
- BC-2.01.008 — RunnableAssign dict augmentation (depends on: RunnableAssign wraps a RunnableParallel internally; BC-2.01.008 relies on this BC's construction postconditions)
- BC-2.01.004 — Runnable pipe composition (depends on: RunnableParallel implements DynRunnable and composes via pipe() as defined in BC-2.01.004)
- BC-2.01.003 — Runnable trait invocation (depends on: RunnableParallel extends the Runnable invocation protocol with concurrent fan-out)

## Architecture Anchors

- `pregolya-core/src/runnables/parallel.rs` — `RunnableParallel` struct and `DynRunnable` impl (to be created)
- `pregolya-core/src/runnables/mod.rs` — re-export of `RunnableParallel` from `core::runnable`
- ADR-026 §Decision 1 — IndexMap type representation and key ordering
- ADR-026 §Decision 2 — JoinSet fan-out, completion-order collection, re-insertion in steps order

## Story Anchor

S-1.05

## VP Anchors

- VP-014

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-039 |
| Capability Anchor Justification | CAP-039 ("LCEL Map/Passthrough Composition: RunnableParallel and RunnablePassthrough") per capabilities-p1-p2.md §CAP-039 (D-170) — this BC describes the construction and concurrent invocation behavior of `RunnableParallel`, which is the primary component of CAP-039; the construction behavior per ADR-026 §Decision 1 (RunnableParallel: Type Representation and Key Ordering) and the concurrent invocation behavior per ADR-026 §Decision 2 (RunnableParallel: Concurrent Execution and Error Handling). |
| L2 Domain Invariants | DI-016 (RunnableParallel Key-Completeness and Branch-Failure Propagation); DI-014 (Error Propagation: No Silent Swallowing — errors from branches must propagate as Err, not degrade to empty results) |
| NE References | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), ST (streaming), P (proptest) |
| Module | pregolya-core |
