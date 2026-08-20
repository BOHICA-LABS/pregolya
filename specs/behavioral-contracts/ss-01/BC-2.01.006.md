---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.006
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
timestamp: 2026-08-17T00:00:00Z
di_anchors: [DI-016, DI-014]
changelog:
  - "1.0 (burst-302b/D-170/2026-08-17): Initial — RunnableParallel branch failure: fail-fast semantics, structured error with branch key, no partial results. LCEL composition scope expansion (D-170); ADR-026 §Decision 2."
  - "1.1 (burst-302b/D-171/2026-08-17): Notation fix — §Invariants JoinError bullet: PregolyaError { category: Internal } → PregolyaError { category: Internal, .. } per ADR-010 §Class-3 positive obligation (CLASS3_MISSING_DOTS_VIOLATION; verify-error-notation-canon gate)."
  - "1.2 (BURST-303/F-P194-01/2026-08-17): DynRunnable canon alignment — replaced all `invoke_dyn` with `invoke` and `stream_dyn` with `stream` in DynRunnable context per architect canon (F-P194-01). DynRunnable canonical methods are `invoke` and `stream`; `invoke_dyn`/`stream_dyn` belong to DynTool. Signature uses `config: Option<RunnableConfig>`."
  - "1.3 (burst-309/F-P201-01/2026-08-17): Add E-CORE-011 code annotation to the Tokio-task-panic (JoinError) path in PC-4, EC-003, TV-003, and Traceability Error Code Minted. E-CORE-011 (INTERNAL/RunnableParallelTaskPanic) is the structured error code for the panic path where no branch key is available at the JoinError catch site. Distinct from E-CORE-009 (EXEC/RunnableParallelBranchFailure) which covers the branch-returned-Err path where the key is available."
  - "1.4 (P1D-208/F-P208-01/2026-08-18): §Category casing canon — E-CORE-011 INTERNAL category rendered as bare PascalCase `Internal` corrected to ALL-CAPS taxonomy code `INTERNAL` at §Postconditions PC-4, §Invariants, §Edge Cases EC-003, §Canonical Test Vectors TV-003 per ADR-010 §Category casing canon (matches sibling E-CORE-009 `EXEC` form); sibling-swept 4 prose category references (§Description, §Invariants label, §Postconditions prose, §Architecture Anchors) Internal→INTERNAL per TD-VSDD-060."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-039
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-026-lcel-composition-primitives-parallel-passthrough.md
input-hash: "98a93c5"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.006: RunnableParallel Branch Failure — Fail-Fast, Structured Error, No Partial Results

## Description

When any branch of a `RunnableParallel` invocation returns `Err`, the parallel combinator
aborts all remaining in-flight branches immediately (`JoinSet::abort_all()`) and returns a
structured `PregolyaError` that identifies the failing branch by key. No partial output
dictionary is ever returned — the result is either a complete `N`-key object or an `Err`.
This satisfies DI-014 (No Silent Swallowing) and DI-016 (Key-Completeness and Branch-Failure
Propagation). Tokio task panics (JoinError) are similarly surfaced as structured INTERNAL
errors rather than being silently ignored or causing the combinator to hang.

## Preconditions

1. A `RunnableParallel` with `N ≥ 1` configured branches has been constructed
   (per BC-2.01.005 postconditions).
2. `invoke(input, config)` is called; one or more branches will return `Err` at
   runtime.
3. All branch tasks have been spawned and are in-flight via `JoinSet`.

## Postconditions

1. The first branch error detected via `JoinSet::join_next()` triggers `set.abort_all()`
   — all remaining in-flight branch tasks receive a cancellation signal immediately.
2. `invoke` returns `Err(PregolyaError { category: EXEC, code: "E-CORE-009",
   message: "RunnableParallelBranchFailure: branch '<key>' failed: <cause>", .. })`
   where `<key>` is the name of the failing branch and `<cause>` is the error message
   from the originating branch error.
3. **No partial output dictionary is returned on failure.** The caller receives only the
   `Err`; there is no `Ok(partial_map)` path for partial success.
4. A Tokio task panic (the `join_next()` returns `Err(JoinError)` due to a panic in the
   branch task) maps to `Err(PregolyaError { category: INTERNAL, code: "E-CORE-011",
   message: "RunnableParallelTaskPanic: task panicked: <detail>", .. })` — the panic is
   treated as an INTERNAL invariant violation, not silently swallowed.
5. For `stream`: the first `Err` from any branch stream aborts all branch streams and
   propagates the error to the caller. No partial chunk sequence is emitted after the
   first error.

## Invariants

- **Fail-fast, abort-all:** the combinator MUST call `JoinSet::abort_all()` after the
  first error is detected, before returning from `invoke`. There is no
  "collect all errors" mode in v1.
- **No partial result on failure:** returning `Ok(Value::Object(...))` with fewer than `N`
  keys is a contract violation. If the result is `Ok`, it MUST have exactly `N` keys
  (DI-016 completeness half, proved by VP-014). If any branch fails, the result MUST be
  `Err`.
- **Structured error with branch key:** the error message MUST include the failing branch's
  key (`<key>` placeholder); a structureless "execution failed" without identification of
  the failing branch violates this BC.
- **JoinError maps to INTERNAL:** Tokio task panics (JoinError) are not re-raised as-is;
  they are wrapped in a `PregolyaError { category: INTERNAL, .. }` — consistent with ADR-010
  §Class 1 (programming-error invariant violations). This ensures structured error
  propagation rather than payload leakage through raw panic messages.
- **DI-014 enforcement:** no branch error may be silently discarded; every branch failure
  must surface as an `Err` return from `invoke`.

## Edge Cases

### EC-001: First branch fails before others complete

**Scenario:** Branch "a" fails immediately; branches "b" and "c" are still in-flight.
**Expected behavior:** `set.abort_all()` called; `invoke` returns
`Err(PregolyaError { category: EXEC, code: "E-CORE-009",
message: "RunnableParallelBranchFailure: branch 'a' failed: <cause>", .. })`.
Branches "b" and "c" receive cancellation; their partial results are discarded.

### EC-002: Multiple branches fail nearly simultaneously

**Scenario:** Branches "a" and "b" both fail; task scheduler yields branch "a"'s error
first.
**Expected behavior:** Branch "a"'s error is returned. `abort_all()` fires. Branch "b"'s
error is discarded (only the first-detected error is reported). The calling code must
treat any branch failure as a full failure and retry the entire parallel if appropriate.

### EC-003: Branch task panics (JoinError)

**Scenario:** Branch "slow" panics inside its `invoke` — `JoinSet::join_next()`
returns `Err(JoinError)`.
**Expected behavior:** The JoinError is mapped to
`Err(PregolyaError { category: INTERNAL, code: "E-CORE-011",
message: "RunnableParallelTaskPanic: task panicked: <detail>", .. })`.
`abort_all()` is called on remaining tasks. The panic is not re-raised via
`std::panic::resume_unwind`.

### EC-004: All branches fail

**Scenario:** All N branches return `Err`.
**Expected behavior:** The first error detected (non-deterministic task completion order)
is returned. `abort_all()` fires for remaining tasks (which will also complete as errors,
but those are dropped). Exactly one `Err` is returned.

### EC-005: Zero-branch parallel invocation (no failure possible)

**Scenario:** `RunnableParallel::new([]).invoke(...)` — N = 0.
**Expected behavior:** Per BC-2.01.005 PC-6, returns `Ok(Value::Object(Map::new()))`.
No tasks spawned; no error possible; this edge case is technically under BC-2.01.005,
documented here as a contrast point.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | 2-branch parallel; branch "slow" returns `Err(PregolyaError { .. })` | `Err(PregolyaError { category: EXEC, code: "E-CORE-009", message: "RunnableParallelBranchFailure: branch 'slow' failed: <cause>", .. })` | Happy-path failure; branch key in error |
| TV-002 | 2-branch parallel; branch "fast" succeeds, branch "slow" fails | `Err(PregolyaError { category: EXEC, code: "E-CORE-009", .. })` — NO partial object with "fast" key | No partial result on failure |
| TV-003 | Branch task panics (JoinError path) | `Err(PregolyaError { category: INTERNAL, code: "E-CORE-011", .. })` | JoinError → INTERNAL (E-CORE-011) |
| TV-004 | 3-branch parallel; branch "b" fails first; inspect that branches "a" and "c" receive abort signal | `abort_all()` called; only 1 Err returned | Abort-all on first error |
| TV-005 | Stream invocation; first error on branch "x" at chunk 3 | Stream emits up to 2 chunks, then `Err`; no subsequent chunks | Streaming fail-fast |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-014 | For any N-branch RunnableParallel and any input producing Ok(output): output.as_object().len() == N AND output key set == configured branch key set (verifies the success-path completeness half; combined with this BC's Err postconditions establishes the no-partial-result invariant) | proptest | 3 |

## Related BCs

- BC-2.01.005 — RunnableParallel construction and concurrent invocation (composes with: this BC is the failure path; BC-2.01.005 is the success path)
- BC-2.01.008 — RunnableAssign dict augmentation (depends on: mapper errors in RunnableAssign propagate via this BC's fail-fast semantics since mapper is a RunnableParallel internally)
- BC-2.14.001 — PregolyaError 2D struct (depends on: E-CORE-009 error construction follows ADR-010 notation canon)

## Architecture Anchors

- `pregolya-core/src/runnables/parallel.rs` — `RunnableParallel::invoke` failure path: `join_next()` Err branch, `abort_all()` call, error construction with branch key
- ADR-026 §Decision 2 — fail-fast with abort semantics, structured error with branch key, JoinError → INTERNAL mapping

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-014

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-039 |
| Capability Anchor Justification | CAP-039 ("LCEL Map/Passthrough Composition: RunnableParallel and RunnablePassthrough") per capabilities-p1-p2.md §CAP-039 (D-170) — this BC governs the error propagation behavior of `RunnableParallel`, the fail-fast abort-all semantics that prevent partial results, and the structured error that identifies the failing branch — all integral to CAP-039's definition of `RunnableParallel` per ADR-026 §Decision 2. |
| L2 Domain Invariants | DI-016 (RunnableParallel Key-Completeness and Branch-Failure Propagation; PC-3 enforces the "no partial results" half); DI-014 (Error Propagation: No Silent Swallowing — PC-1 through PC-4 ensure every branch failure surfaces as Err) |
| NE References | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), ST (streaming) |
| Module | pregolya-core |
| Error Code Minted | E-CORE-009 (EXEC/RunnableParallelBranchFailure — branch returned Err; key available), E-CORE-011 (INTERNAL/RunnableParallelTaskPanic — panic path; key not available at JoinError catch site) — see error-taxonomy.md §Component: CORE |
