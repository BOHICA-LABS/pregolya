---
document_type: story
level: ops
story_id: S-1.28
epic_id: E-07
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-31T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.007.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.008.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.009.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "cb4731d"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.14]
blocks: []
behavioral_contracts: [BC-2.02.007, BC-2.02.008, BC-2.02.009]
verification_properties: [VP-017]
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-02]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
changelog:
  - "1.0 (praxist-Stage-3/2026-08-31): Initial authoring — LedgerChannel and PromoteRetireChannel additive primitives for the research-orchestrator use case; BC-2.02.007 + BC-2.02.008 + BC-2.02.009; VP-017 proptest P1 anchor; Wave 1 / E-07 extension; depends on S-1.14."
---

> **tdd_mode:** strict — full TDD Iron Law enforced. Write all failing tests before writing any channel reducer implementation. VP-017 proptest must reach a red state before the `LedgerChannel` reducer body is written.

> **Execute:** `/vsdd-factory:deliver-story S-1.28`

# S-1.28: LedgerChannel and PromoteRetireChannel — Ledger-Style State Channels

## Narrative

- **As a** graph runtime developer building CAP-040 research-orchestrator primitives
- **I want to** add `LedgerChannel<T>` (dedup-idempotent append accumulator) and `PromoteRetireChannel<T>` (promote/retire active-set lifecycle) to `graph::channels` in `pregolya-graph`
- **So that** research-orchestrator graphs can use evidence-accumulation and quality-diversity allocation channels alongside the existing `LastValue` / `Append` / `BarrierValue` / `EphemeralValue` channel family

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.02.007 | LedgerChannel Dedup-Idempotent Append | AC-001..AC-006 |
| BC-2.02.008 | LedgerChannel First-Appearance Ordering | AC-007..AC-010 |
| BC-2.02.009 | PromoteRetireChannel Promote/Retire Lifecycle | AC-011..AC-017 |

## Acceptance Criteria

### AC-001 (traces to BC-2.02.007 PRE-001 / PRE-002 — LedgerEntry trait definition)
The public trait `LedgerEntry` is declared in `graph::channels` (pregolya-graph) with a single required method `fn entry_id(&self) -> &str`. Any `T: LedgerEntry + Clone + Send + Sync + 'static` is a valid element type for both `LedgerChannel<T>` and `PromoteRetireChannel<T>`. Verified by `test_BC_2_02_007_ledger_entry_trait_exists()`.

### AC-002 (traces to BC-2.02.007 PC-001 — novel entry appended)
`LedgerChannel<T>::reduce(acc: Vec<T>, incoming: T) -> Vec<T>` — when `incoming.entry_id()` is NOT in `acc`, the returned `Vec<T>` is `acc` with `incoming` appended at the end. Length grows by exactly one. Verified by `test_BC_2_02_007_novel_entry_appended()`.

### AC-003 (traces to BC-2.02.007 PC-002 — duplicate entry is a silent no-op)
`LedgerChannel<T>::reduce(acc, incoming)` — when `incoming.entry_id()` IS already in `acc`, the returned `Vec<T>` is identical to `acc` (same length, same elements, same order). No `Err(PregolyaError)` is raised. Verified by `test_BC_2_02_007_duplicate_entry_noop()`.

### AC-004 (traces to BC-2.02.007 PC-004 — mixed novel and duplicate sequence produces one element per distinct entry_id)
Processing a sequence `[T{id:"a"}, T{id:"b"}, T{id:"a"}, T{id:"c"}]` (in task-identity order per DI-001) from accumulated `vec![]` yields `vec![T{id:"a"}, T{id:"b"}, T{id:"c"}]` — exactly three elements, one per distinct `entry_id`. Verified by `test_BC_2_02_007_mixed_sequence_unique_entries()`.

### AC-005 (traces to BC-2.02.007 INV-001 — monotonically non-decreasing length)
For any sequence of `reduce` calls, the `Vec<T>` length never decreases across calls. The proptest VP-017 (`ledger_channel_dedup_idempotency`) covers this property for arbitrary input sequences. Verified by `test_BC_2_02_007_length_never_decreases()` (unit) and VP-017 (proptest — RED GATE: this test MUST fail on a stub before implementation).

### AC-006 (traces to BC-2.02.007 INV-003 — reducer is a pure function)
`LedgerChannel<T>::reduce` is stateless: given the same `acc` and the same `incoming`, the result is always identical. No global state, timestamps, or random numbers are consulted. Verified by `test_BC_2_02_007_reducer_is_deterministic()`.

### AC-007 (traces to BC-2.02.008 PC-001 — entries ordered by first-appearance chronologically)
Iterating the `Vec<T>` returned by successive `reduce` calls yields entries in the order their `entry_id` first appeared across all prior super-steps (earlier first-appearance = lower index). Verified by `test_BC_2_02_008_first_appearance_ordering_across_steps()`.

### AC-008 (traces to BC-2.02.008 PC-002 — duplicate submission does not alter position)
Re-submitting a `T` with an already-seen `entry_id` does NOT change the position of any existing entry. The `Vec<T>` before and after the no-op reduce is identical. Verified by `test_BC_2_02_008_duplicate_does_not_shift_position()`.

### AC-009 (traces to BC-2.02.008 PC-004 — within one super-step novel entries ordered by task-identity sort, DI-001)
When multiple novel entries arrive in a single super-step, their relative order in the `Vec<T>` matches the task-identity-sorted write order (DI-001). The `reduce` function processes them in the order given to it; the BSP engine is responsible for providing task-identity order. Verified by `test_BC_2_02_008_within_step_task_identity_order()`.

### AC-010 (traces to BC-2.02.008 INV-003 — monotonically stable ordering)
Elements already in the `Vec<T>` never change position. New entries are always appended at the end. No in-place reordering occurs after any `reduce` call. Verified by `test_BC_2_02_008_ordering_monotonically_stable()`.

### AC-011 (traces to BC-2.02.009 PRE-002 — PromoteRetireOp enum declared non_exhaustive)
`PromoteRetireOp<T>` is a `#[non_exhaustive]` enum in `graph::channels` with variants `Promote(T)` and `Retire(String)`. External `match` arms must include a wildcard `_ => {}` arm. Verified by compile-fail test `test_BC_2_02_009_promote_retire_op_non_exhaustive_requires_wildcard()`.

### AC-012 (traces to BC-2.02.009 PC-001 — Promote novel entry appends to active set)
`PromoteRetireChannel<T>::reduce(active: Vec<T>, op: PromoteRetireOp<T>) -> Vec<T>` — when `op` is `Promote(entry)` and `entry.entry_id()` is NOT in `active`, the returned `Vec<T>` is `active` with `entry` appended. Length grows by one. Verified by `test_BC_2_02_009_promote_novel_appends()`.

### AC-013 (traces to BC-2.02.009 PC-002 — Promote existing entry_id is idempotent)
When `op` is `Promote(entry)` and `entry.entry_id()` IS already in `active`, the active set is unchanged (no duplicate added, same length). Verified by `test_BC_2_02_009_promote_duplicate_noop()`.

### AC-014 (traces to BC-2.02.009 PC-003 — Retire present entry_id removes it)
When `op` is `Retire(entry_id)` and `entry_id` IS in the active set, the entry with that `entry_id` is removed. Active set shrinks by exactly one. Verified by `test_BC_2_02_009_retire_present_entry()`.

### AC-015 (traces to BC-2.02.009 PC-004 — Retire absent entry_id is idempotent, no error)
When `op` is `Retire(entry_id)` and `entry_id` is NOT in the active set, the active set is unchanged. No `Err(PregolyaError)` is raised. Verified by `test_BC_2_02_009_retire_absent_noop_no_error()`.

### AC-016 (traces to BC-2.02.009 PC-006 — concurrent ops processed in task-identity order, DI-001)
Within a single super-step, multiple `PromoteRetireOp` values are processed in task-identity-sorted order. EC-003 and EC-004 from BC-2.02.009 (Promote-then-Retire and Retire-then-Promote in same super-step) yield deterministic, distinct final active sets. Verified by `test_BC_2_02_009_concurrent_promote_retire_deterministic_order()`.

### AC-017 (traces to BC-2.02.009 INV-001 — active set contains no duplicate entry_id values at any time)
`INV-001` holds after any `reduce` call: no two elements in the active `Vec<T>` share an `entry_id`. Verified by `test_BC_2_02_009_active_set_no_duplicate_entry_ids()`.

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `LedgerEntry` trait, `LedgerChannel<T>` struct and reducer | `pregolya_graph::channels` (`graph::channels`) | pregolya-graph | Pure (stateless reducer over `Vec<T>`) |
| `PromoteRetireOp<T>` enum, `PromoteRetireChannel<T>` struct and reducer | `pregolya_graph::channels` (`graph::channels`) | pregolya-graph | Pure (stateless reducer over `Vec<T>`) |
| VP-017 proptest harness `ledger_channel_dedup_idempotency` | `pregolya_graph::channels` `#[cfg(test)]` | pregolya-graph | Pure (test code) |

**Subsystem anchor:** SS-02 owns this story's scope because SS-02 is the StateGraph Definition subsystem (`graph::channels` in `pregolya-graph`) per ARCH-INDEX Subsystem Registry. `LedgerChannel` and `PromoteRetireChannel` are ledger-style channel reducer types that extend the existing channel family (`LastValue`/`Append`/`BarrierValue`/`EphemeralValue`) registered in the same `graph::channels` module per ADR-030 §Decision 3.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `LedgerEntry` trait | Pure | Type definition; no I/O |
| `LedgerChannel<T>::reduce` | Pure | Stateless function: `(Vec<T>, T) -> Vec<T>`; no external state or I/O |
| `PromoteRetireOp<T>` | Pure | Data type definition; no I/O |
| `PromoteRetireChannel<T>::reduce` | Pure | Stateless function: `(Vec<T>, PromoteRetireOp<T>) -> Vec<T>`; no external state or I/O |

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~3,500 |
| BC-2.02.007 | ~2,000 |
| BC-2.02.008 | ~1,500 |
| BC-2.02.009 | ~1,800 |
| Architecture module-decomposition.md (SS-02 section) | ~700 |
| S-1.14 context (existing `graph::channels`) | ~3,500 |
| Test files | ~2,500 |
| **Total** | **~15,500** |

Well within the 20-30% agent context window threshold.

## Tasks

- [ ] Read `pregolya-graph/src/channels.rs` (from S-1.14) to understand the existing channel infrastructure before adding anything
- [ ] Declare `LedgerEntry` trait in `channels.rs` with `fn entry_id(&self) -> &str`
- [ ] Declare `LedgerChannel<T>` struct and implement its reducer function (dedup-idempotent append)
- [ ] Declare `#[non_exhaustive] PromoteRetireOp<T>` enum with variants `Promote(T)` and `Retire(String)`
- [ ] Declare `PromoteRetireChannel<T>` struct and implement its reducer function (promote/retire active set)
- [ ] Apply `#[non_exhaustive]` to `LedgerChannel<T>` and `PromoteRetireChannel<T>` structs
- [ ] Write VP-017 proptest (`ledger_channel_dedup_idempotency`) in `#[cfg(test)]` — MUST fail on stubs (Red Gate discipline)
- [ ] Write unit tests for AC-001 through AC-017 (red first, then implement)
- [ ] Run `just iter pregolya-graph` — all tests green (including existing S-1.14 tests)
- [ ] Confirm `PromoteRetireOp` compile-fail test AC-011 (missing wildcard arm must fail to compile)

## Previous Story Intelligence

- S-1.14 (StateGraph Node and Channel Reducer Semantics) established `graph::channels` with `LastValue<T>`, `Append<T>`, `BarrierValue`, `NamedBarrierValue`, and `EphemeralValue` channel types. S-1.28 extends this module; load `pregolya-graph/src/channels.rs` as context before authoring. Do not modify any existing channel types — only add the new `LedgerEntry` trait, `LedgerChannel`, `PromoteRetireOp`, and `PromoteRetireChannel` symbols.
- The `reduce` function pattern in `graph::channels` is established by the existing channel types. Follow the same function signature and module layout conventions.
- BC-2.02.007 {INV-003} requires the reducer to be a pure function — do not introduce any `use std::time` or `rand` dependencies.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-graph` and ADR-030 §Decision 3:

1. `LedgerEntry` trait, `LedgerChannel<T>`, `PromoteRetireOp<T>`, and `PromoteRetireChannel<T>` MUST be defined in `pregolya-graph/src/channels.rs` (`graph::channels`). Do NOT create a new file or new module for these types — they are additive channel types in the existing module.
2. `LedgerChannel<T>::reduce` MUST be a pure function: `(Vec<T>, T) -> Vec<T>`. No mutation of the `acc` argument through shared state; return a new or modified `Vec<T>` without side effects.
3. `PromoteRetireChannel<T>::reduce` MUST be a pure function: `(Vec<T>, PromoteRetireOp<T>) -> Vec<T>`.
4. `PromoteRetireOp<T>` MUST carry `#[non_exhaustive]` per code convention (public API enum).
5. `LedgerChannel<T>` and `PromoteRetireChannel<T>` structs MUST carry `#[non_exhaustive]` per code convention.
6. No `unwrap()` / `expect()` in non-test code.
7. No `println!` / `eprintln!` in library crate code.
8. `LedgerEntry` requires `T: Clone + Send + Sync + 'static` as bounds — these must match BC-2.02.007 {PRE-001} exactly.
9. The VP-017 proptest harness (`ledger_channel_dedup_idempotency`) MUST exercise arbitrary-length sequences via the `proptest!` macro, not fixed vectors. It must assert both the dedup-uniqueness invariant (BC-2.02.007 {INV-002}) and the first-appearance ordering invariant (BC-2.02.008 {INV-001}).
10. **Forbidden dependencies:** `graph::channels` must NOT gain a dependency on `pregolya-checkpoint`, `pregolya-mcp`, `pregolya-server`, or any I/O crate. The channel reducers are pure types.

## Library & Framework Requirements

| Library | Version | Usage |
|---------|---------|-------|
| (inherited from S-1.14) | — | `pregolya-graph` existing crate context |
| `proptest` | workspace pin | VP-017 `proptest!` macro in `#[cfg(test)]` |

No new crate-level dependencies are expected beyond `proptest` (dev-dependency) which is already present from S-1.16 / existing graph tests.

## File Structure Requirements

Files to MODIFY:
- `pregolya-graph/src/channels.rs` — add `LedgerEntry` trait, `LedgerChannel<T>`, `PromoteRetireOp<T>`, `PromoteRetireChannel<T>` and their reducer impls; add `#[cfg(test)]` VP-017 proptest and unit tests for AC-001..AC-017

Files to MODIFY (re-export):
- `pregolya-graph/src/lib.rs` — ensure `LedgerEntry`, `LedgerChannel`, `PromoteRetireOp`, `PromoteRetireChannel` are publicly re-exported

No new files are expected for this story. All new types live in the existing `channels.rs` module.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `entry_id` is an empty string `""` | Treated as a valid `entry_id` — first `T` with `entry_id=""` is appended; subsequent duplicates are no-ops (BC-2.02.007 EC-004) |
| EC-002 | All entries in a super-step are duplicates for `LedgerChannel` | Active `Vec<T>` unchanged — all reduce calls are no-ops (BC-2.02.007 EC-003) |
| EC-003 | Concurrent Promote + Retire in same super-step (task-id: Promote lower) | Promote processed first (adds entry), Retire processed second (removes it) — net: unchanged active set (BC-2.02.009 EC-003) |
| EC-004 | Concurrent Retire + Promote in same super-step (task-id: Retire lower) | Retire is a no-op (entry not yet present), Promote adds it — net: entry is in active set (BC-2.02.009 EC-004) |
| EC-005 | `Retire` for an entry_id not in the active set | Silent no-op — returns unchanged active set, no error (BC-2.02.009 PC-004) |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.0 | 2026-08-31 | Initial authoring — praxist Stage-3 story decomposition for BC-2.02.007/008/009 + VP-017 | story-writer |
