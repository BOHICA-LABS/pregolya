---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.008
version: "1.0"
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
timestamp: 2026-08-17T00:00:00Z
di_anchors: [DI-016, DI-014]
changelog:
  - "1.0 (burst-302b/D-170/2026-08-17): Initial — RunnableAssign dict augmentation semantics, merge semantics (mapper-wins-on-collision), and dict-input validation. LCEL composition scope expansion (D-170); ADR-026 §Decision 4."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-039
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-026-lcel-composition-primitives-parallel-passthrough.md
input-hash: "208fc08"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.008: RunnableAssign Dict Augmentation — Merge Semantics and Dict-Input Validation

## Description

`RunnableAssign` augments a JSON object input with additional computed keys. It is always
created via `RunnablePassthrough::assign(pairs)` — there is no public `RunnableAssign::new()`
constructor. Internally, `RunnableAssign` wraps a `RunnableParallel` as its `mapper`:
`invoke_dyn` validates that the input is a `Value::Object`, runs the mapper on the input
(concurrently, per BC-2.01.005), and merges the mapper output over the input object —
**mapper keys overwrite input keys on collision** (matching Python's `{**value, **mapper_output}`
semantics). Non-dict input is a hard error (`E-CORE-010`); mapper errors propagate via the
fail-fast semantics of `RunnableParallel` (BC-2.01.006).

## Preconditions

1. `RunnablePassthrough::assign(pairs)` is called with an iterator of
   `(key, Arc<dyn DynRunnable>)` pairs, constructing a `RunnableAssign { mapper: RunnableParallel::new(pairs) }`.
2. `invoke_dyn(input, config)` is called on the resulting `RunnableAssign`.
3. The caller provides a `serde_json::Value` as input; its type determines whether
   invocation proceeds or returns an immediate `Err`.

## Postconditions

1. `RunnablePassthrough::assign(pairs)` constructs a `RunnableAssign` whose `mapper`
   field is a `RunnableParallel::new(pairs)`. No I/O occurs at construction time.
2. If `input` is NOT a `serde_json::Value::Object(...)`: returns
   `Err(PregolyaError { category: VAL, code: "E-CORE-010",
   message: "RunnableAssignNonDictInput: input to RunnablePassthrough.assign() must be a JSON object", .. })`
   immediately without invoking the mapper.
3. If `input` IS a `Value::Object(input_map)`: invokes
   `self.mapper.invoke_dyn(input.clone(), config.clone()).await`
   per BC-2.01.005. On success, merges the results:
   - Start with all key-value pairs from `input_map`.
   - Overwrite / insert with all key-value pairs from `mapper_output` (an object).
   - **Mapper keys take precedence on collision** — the merged value for a colliding key
     is the mapper's output, not the input's value.
   - Return `Ok(Value::Object(merged_map))`.
4. If the mapper invocation fails (any branch returns `Err`):
   `invoke_dyn` returns `Err(...)` propagated from the mapper (per BC-2.01.006 fail-fast
   semantics). No partial merged object is returned.
5. The output `Value::Object` contains all keys from `input_map` PLUS all keys from
   the mapper output, with mapper values taking precedence on collision.

## Invariants

- **Dict-input gate:** any non-Object input is immediately rejected at the start of
  `invoke_dyn` before the mapper runs. `Value::Array`, `Value::String`, `Value::Null`,
  `Value::Bool`, `Value::Number` all trigger `Err(E-CORE-010)`.
- **Mapper-wins-on-collision:** this is the canonical Python `{**value, **mapper.invoke(value)}`
  behavior. Callers that need input-wins semantics must wrap the assignment explicitly.
- **No partial output on mapper failure:** if the mapper (a `RunnableParallel`) fails,
  the error propagates intact per BC-2.01.006; no partial merged map is returned.
- **Input-clone isolation:** the mapper receives `input.clone()` and `config.clone()` — it
  cannot observe the merge operation and cannot mutate the original `input_map`.
- **DynRunnable implementation:** `RunnableAssign` implements `DynRunnable` and composes
  via `pipe()` — it can be used anywhere a `DynRunnable` is expected.
- **`#[non_exhaustive]` struct:** callers cannot construct `RunnableAssign` directly;
  they must use `RunnablePassthrough::assign(...)` (ADR-023 §Required Inventory).

## Edge Cases

### EC-001: Non-dict input — Value::Array

**Scenario:** `invoke_dyn(Value::Array(vec![1, 2, 3]), None)` on a RunnableAssign.
**Expected behavior:** Returns
`Err(PregolyaError { category: VAL, code: "E-CORE-010",
message: "RunnableAssignNonDictInput: input to RunnablePassthrough.assign() must be a JSON object", .. })`.
The mapper is never invoked.

### EC-002: Non-dict input — Value::Null

**Scenario:** `invoke_dyn(Value::Null, None)`.
**Expected behavior:** Same as EC-001 — immediate `Err(E-CORE-010)`.

### EC-003: Mapper key collides with input key — mapper wins

**Scenario:** `input = { "city": "London", "country": "UK" }`;
mapper produces `{ "city": "Paris" }`.
**Expected behavior:** Output is `{ "city": "Paris", "country": "UK" }`.
Mapper value "Paris" overwrites input value "London" for key "city".

### EC-004: Mapper key collides with input key — no ambiguity

**Scenario:** Same as EC-003 but mapper also produces `{ "population": 2_100_000 }`.
**Expected behavior:** Output is `{ "city": "Paris", "country": "UK", "population": 2100000 }`.
All input keys preserved except colliding ones (city → Paris). All mapper keys inserted
(population added).

### EC-005: Mapper fails — no partial merge

**Scenario:** Mapper has 2 branches; branch "extra_key" fails.
**Expected behavior:** `invoke_dyn` returns `Err(PregolyaError { category: EXEC,
code: "E-CORE-009", message: "RunnableParallelBranchFailure: branch 'extra_key' ...", .. })`.
No merged object is returned even if some branches succeeded; the merge never starts
(the mapper failure is detected before the merge step).

### EC-006: Empty mapper (no pairs)

**Scenario:** `RunnablePassthrough::assign([])` — no mapper pairs; `invoke_dyn` called
with `Value::Object({ "a": 1 })`.
**Expected behavior:** `mapper` is a zero-branch `RunnableParallel`. Per BC-2.01.005 PC-6,
mapper returns `Ok(Value::Object({}))` — empty mapper output. Merge: all input keys
preserved, mapper adds nothing. Output is `{ "a": 1 }` — identical to input.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `assign([("extra", const_fn("val"))]).invoke_dyn(Object({"a": 1}), None)` | `Ok(Object({"a": 1, "extra": "val"}))` | Happy path: new key added |
| TV-002 | `assign([("a", const_fn("new"))]).invoke_dyn(Object({"a": 1, "b": 2}), None)` | `Ok(Object({"a": "new", "b": 2}))` | Mapper-wins on collision |
| TV-003 | `assign([...]).invoke_dyn(Value::Null, None)` | `Err(PregolyaError { category: VAL, code: "E-CORE-010", .. })` | Non-dict input: Null |
| TV-004 | `assign([...]).invoke_dyn(Value::Array([1,2,3]), None)` | `Err(PregolyaError { category: VAL, code: "E-CORE-010", .. })` | Non-dict input: Array |
| TV-005 | `assign([("k", failing_fn)]).invoke_dyn(Object({"a": 1}), None)` | `Err(PregolyaError { category: EXEC, code: "E-CORE-009", .. })` — no partial merge | Mapper failure propagates; no partial output |
| TV-006 | `assign([]).invoke_dyn(Object({"x": 99}), None)` | `Ok(Object({"x": 99}))` | Empty mapper: output = input |

## Verification Properties

_No dedicated Kani VP — correctness of dict-input validation and merge semantics is
covered by unit tests and the VP-014 proptest on the underlying RunnableParallel._

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-014 | RunnableParallel key-completeness (RunnableAssign wraps a RunnableParallel; VP-014 verifies the mapper returns all expected keys on success) | proptest | 3 |

## Related BCs

- BC-2.01.007 — RunnablePassthrough identity (depends on: RunnablePassthrough::assign() is a static factory method on RunnablePassthrough; this BC's construction entry point is defined by BC-2.01.007)
- BC-2.01.005 — RunnableParallel construction (depends on: RunnableAssign.mapper is a RunnableParallel; mapper invocation follows BC-2.01.005 postconditions)
- BC-2.01.006 — RunnableParallel branch failure (depends on: mapper errors propagate via BC-2.01.006 fail-fast semantics)

## Architecture Anchors

- `pregolya-core/src/runnables/passthrough.rs` — `RunnableAssign` struct, `RunnablePassthrough::assign()` static factory method, `DynRunnable` impl for `RunnableAssign` (to be created)
- ADR-026 §Decision 4 — dict-input validation, merge semantics (mapper-wins-on-collision), streaming RunnableAssign via safetee pattern

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-014 (indirect — via the wrapped RunnableParallel mapper)

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-039 |
| Capability Anchor Justification | CAP-039 ("LCEL Map/Passthrough Composition: RunnableParallel and RunnablePassthrough") per capabilities-p1-p2.md §CAP-039 (D-170) — this BC describes `RunnableAssign`, the third named component of CAP-039, which augments dict inputs with computed keys via the `RunnablePassthrough::assign()` factory per ADR-026 §Decision 4. |
| L2 Domain Invariants | DI-016 (RunnableParallel Key-Completeness and Branch-Failure Propagation — PC-4 enforces mapper errors propagate as Err with no partial merged output); DI-014 (Error Propagation: No Silent Swallowing — PC-2 enforces non-dict input returns Err; PC-4 enforces mapper errors propagate) |
| NE References | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), ST (streaming) |
| Module | pregolya-core |
| Error Code Minted | E-CORE-010 (VAL/RunnableAssignNonDictInput — see error-taxonomy.md §Component: CORE) |
