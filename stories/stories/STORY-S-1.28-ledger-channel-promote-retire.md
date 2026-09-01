---
document_type: story
level: ops
story_id: S-1.28
epic_id: E-07
version: "1.4"
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
  - .factory/specs/prd-supplements/interface-definitions.md
input-hash: "914465a"
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
  - "1.4 (Round-53-Phase-2-fix-burst/2026-08-31): F-P2A220-03: AC-018 added (BC-2.02.007 {INV-004}) — LedgerChannel<T> implements graph::channels::Channel (Accumulator=Vec<T>, Update=T); BSP engine dispatches to LedgerChannel::<T>::reduce in reduce phase; no extra bounds beyond T: LedgerEntry at call sites; PromoteRetireChannel<T> analogously implements Channel (Update=PromoteRetireOp<T>). BC table updated (BC-2.02.007 covers AC-001..AC-006, AC-018). F-P2A220-01: Rule 13 updated — #[derive(Default)] ONLY on marker structs, no Clone/Serialize/Deserialize derives; Rule 15 added for Channel trait impl + BSP dispatch contract. AC-001 struct shape updated with #[derive(Default)]. Architecture Mapping updated with Channel trait impl. Tasks updated: Default impl tasks use #[derive(Default)]; Channel trait task added. File Structure updated for ledger.rs and promote_retire.rs."
  - "1.3 (Round-52-Phase-2-fix-burst/2026-08-31): F-P2A216-04 — canonical struct shape specified: LedgerChannel and PromoteRetireChannel are zero-sized markers with private `_inner: PhantomData<T>` field; Default yields `{ _inner: PhantomData }` (NOT empty Vec<T>); Vec<T> accumulator is BSP-engine responsibility. AC-001 updated with canonical struct shape. AC-011 load-bearing gate re-focused to PromoteRetireOp<T> ENUM wildcard-arm (field privacy already blocks struct-literal construction independently). Rule 13 updated (PhantomData shape, not empty Vec). File Structure updated. interface-definitions.md added to inputs; input-hash refreshed to 914465a."
  - "1.2 (Round-51-Phase-2-fix-burst/2026-08-31): F-P2A212-06 — AC-011 compile-fail gate moved to external crate tests/external/non-exhaustive-gate/; extends to LedgerChannel and PromoteRetireChannel. F-P2A212-08 — AC-002/AC-003 incoming->update; AC-012..AC-015 and Rules active/op->acc/update for PromoteRetireChannel. Default impls added for both structs (no new() beyond Default). Rule 2 specifies Vec-linear-scan reduce body. Rules 13-14 added. File structure updated."
  - "1.1 (Round-50-Phase-2-fix-burst/2026-08-31): LedgerEntry supertrait bounds Serialize+DeserializeOwned; channels/ directory module (ledger.rs + promote_retire.rs); VP-017 dual-anchor BC-2.02.007+BC-2.02.008; TST-PROM-01/02 non-VP labels; pure reducer no-Result rule; serde dependency; file-structure update."
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
| BC-2.02.007 | LedgerChannel Dedup-Idempotent Append | AC-001..AC-006, AC-018 |
| BC-2.02.008 | LedgerChannel First-Appearance Ordering | AC-007..AC-010 |
| BC-2.02.009 | PromoteRetireChannel Promote/Retire Lifecycle | AC-011..AC-017 |

## Acceptance Criteria

### AC-001 (traces to BC-2.02.007 PRE-001 / PRE-002 — LedgerEntry trait definition)
The public trait `LedgerEntry` is declared in `graph::channels` (pregolya-graph) with supertrait bounds `Clone + Serialize + DeserializeOwned + Send + Sync + 'static` and a single required method `fn entry_id(&self) -> &str` — i.e., `pub trait LedgerEntry: Clone + Serialize + DeserializeOwned + Send + Sync + 'static { fn entry_id(&self) -> &str; }`. Any `T: LedgerEntry` is therefore also `T: Clone + Serialize + DeserializeOwned + Send + Sync + 'static` and is a valid element type for both `LedgerChannel<T>` and `PromoteRetireChannel<T>`. Both `LedgerChannel<T>` and `PromoteRetireChannel<T>` structs carry `#[non_exhaustive]` and `#[derive(Default)]` as the ONLY derive, with canonical zero-sized marker shape: `#[non_exhaustive] #[derive(Default)] pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (and analogously `PromoteRetireChannel<T>`). No additional derives (`Clone`, `Serialize`, `Deserialize`, or any other) are permitted on the marker structs. These are zero-sized marker types; the accumulator `Vec<T>` is maintained externally by the BSP engine, not stored as a field. Both channel types implement `graph::channels::Channel` with `Accumulator = Vec<T>` (see AC-018). Verified by `test_BC_2_02_007_ledger_entry_trait_exists()`.

### AC-002 (traces to BC-2.02.007 PC-001 — novel entry appended)
`LedgerChannel<T>::reduce(acc: Vec<T>, update: T) -> Vec<T>` — when `update.entry_id()` is NOT in `acc`, the returned `Vec<T>` is `acc` with `update` appended at the end. Length grows by exactly one. Verified by `test_BC_2_02_007_novel_entry_appended()`.

### AC-003 (traces to BC-2.02.007 PC-002 — duplicate entry is a silent no-op)
`LedgerChannel<T>::reduce(acc, update)` — when `update.entry_id()` IS already in `acc`, the returned `Vec<T>` is identical to `acc` (same length, same elements, same order). No `Err(PregolyaError)` is raised. Verified by `test_BC_2_02_007_duplicate_entry_noop()`.

### AC-004 (traces to BC-2.02.007 PC-004 — mixed novel and duplicate sequence produces one element per distinct entry_id)
Processing a sequence `[T{id:"a"}, T{id:"b"}, T{id:"a"}, T{id:"c"}]` (in task-identity order per DI-001) from accumulated `vec![]` yields `vec![T{id:"a"}, T{id:"b"}, T{id:"c"}]` — exactly three elements, one per distinct `entry_id`. Verified by `test_BC_2_02_007_mixed_sequence_unique_entries()`.

### AC-005 (traces to BC-2.02.007 INV-001 — monotonically non-decreasing length)
For any sequence of `reduce` calls, the `Vec<T>` length never decreases across calls. VP-017 (`ledger_channel_dedup_idempotency`) is a dual-anchor proptest covering both BC-2.02.007 {INV-001}/{INV-002} (dedup/monotonicity) and BC-2.02.008 {INV-001}/{INV-003} (first-appearance ordering stability) — both invariants are exercised by the same proptest. Verified by `test_BC_2_02_007_length_never_decreases()` (unit) and VP-017 (proptest — RED GATE: this test MUST fail on a stub before implementation).

### AC-006 (traces to BC-2.02.007 INV-003 — reducer is a pure function)
`LedgerChannel<T>::reduce` is stateless: given the same `acc` and the same `incoming`, the result is always identical. No global state, timestamps, or random numbers are consulted. Verified by `test_BC_2_02_007_reducer_is_deterministic()`.

### AC-007 (traces to BC-2.02.008 PC-001 — entries ordered by first-appearance chronologically)
Iterating the `Vec<T>` returned by successive `reduce` calls yields entries in the order their `entry_id` first appeared across all prior super-steps (earlier first-appearance = lower index). Verified by `test_BC_2_02_008_first_appearance_ordering_across_steps()`.

### AC-008 (traces to BC-2.02.008 PC-002 — duplicate submission does not alter position)
Re-submitting a `T` with an already-seen `entry_id` does NOT change the position of any existing entry. The `Vec<T>` before and after the no-op reduce is identical. Verified by `test_BC_2_02_008_duplicate_does_not_shift_position()`.

### AC-009 (traces to BC-2.02.008 PC-004 — within one super-step novel entries ordered by task-identity sort, DI-001)
When multiple novel entries arrive in a single super-step, their relative order in the `Vec<T>` matches the task-identity-sorted write order (DI-001). The `reduce` function processes them in the order given to it; the BSP engine is responsible for providing task-identity order. Verified by `test_BC_2_02_008_within_step_task_identity_order()`.

### AC-010 (traces to BC-2.02.008 INV-003 — monotonically stable ordering)
Elements already in the `Vec<T>` never change position. New entries are always appended at the end. No in-place reordering occurs after any `reduce` call. VP-017 (dual-anchor) also exercises this ordering stability invariant for arbitrary input sequences. Verified by `test_BC_2_02_008_ordering_monotonically_stable()` (unit) and VP-017 (proptest, BC-2.02.008 {INV-003} clause).

### AC-011 (traces to BC-2.02.009 PRE-002 — PromoteRetireOp enum and struct types declared non_exhaustive; primary gate is enum wildcard)
`PromoteRetireOp<T>` is a `#[non_exhaustive]` enum in `graph::channels` with variants `Promote(T)` and `Retire(String)`. External `match` arms must include a wildcard `_ => {}` arm — this is the PRIMARY, load-bearing effect of `#[non_exhaustive]` in this story. The same `#[non_exhaustive]` annotation applies to `LedgerChannel<T>` and `PromoteRetireChannel<T>` (AC-001); however, because both structs have a private `_inner: PhantomData<T>` field, field privacy ALREADY blocks external struct-literal construction independently of `#[non_exhaustive]` — the `#[non_exhaustive]` enforcement on the structs is therefore SECONDARY (it confirms the annotation is present but the privacy gate provides the primary enforcement). The compile-fail test MUST target the `PromoteRetireOp<T>` ENUM wildcard-arm case as its primary assertion; struct coverage is retained as secondary verification. The test MUST live in the external gate crate `tests/external/non-exhaustive-gate/` — NOT in the defining `pregolya-graph` crate, where `#[non_exhaustive]` is inert for match-completeness and struct-literal enforcement. Verified by `test_BC_2_02_009_promote_retire_op_non_exhaustive_requires_wildcard()` in `tests/external/non-exhaustive-gate/`.

### AC-012 (traces to BC-2.02.009 PC-001 — Promote novel entry appends to active set)
`PromoteRetireChannel<T>::reduce(acc: Vec<T>, update: PromoteRetireOp<T>) -> Vec<T>` — when `update` is `Promote(entry)` and `entry.entry_id()` is NOT in `acc`, the returned `Vec<T>` is `acc` with `entry` appended. Length grows by one. Verified by `test_BC_2_02_009_promote_novel_appends()`.

### AC-013 (traces to BC-2.02.009 PC-002 — Promote existing entry_id is idempotent)
When `update` is `Promote(entry)` and `entry.entry_id()` IS already in `acc`, the active set is unchanged (no duplicate added, same length). Verified by `test_BC_2_02_009_promote_duplicate_noop()`.

### AC-014 (traces to BC-2.02.009 PC-003 — Retire present entry_id removes it)
When `update` is `Retire(entry_id)` and `entry_id` IS in the active set, the entry with that `entry_id` is removed. Active set shrinks by exactly one. Verified by `test_BC_2_02_009_retire_present_entry()`.

### AC-015 (traces to BC-2.02.009 PC-004 — Retire absent entry_id is idempotent, no error)
When `update` is `Retire(entry_id)` and `entry_id` is NOT in the active set, the active set is unchanged. No `Err(PregolyaError)` is raised. Verified by `test_BC_2_02_009_retire_absent_noop_no_error()`.

### AC-016 (traces to BC-2.02.009 PC-006 — concurrent ops processed in task-identity order, DI-001)
Within a single super-step, multiple `PromoteRetireOp` values are processed in task-identity-sorted order. EC-003 and EC-004 from BC-2.02.009 (Promote-then-Retire and Retire-then-Promote in same super-step) yield deterministic, distinct final active sets. Verified by `test_BC_2_02_009_concurrent_promote_retire_deterministic_order()` (TST-PROM-01 non-VP label; deterministic ordering test for `PromoteRetireChannel`).

### AC-017 (traces to BC-2.02.009 INV-001 — active set contains no duplicate entry_id values at any time)
`INV-001` holds after any `reduce` call: no two elements in the active `Vec<T>` share an `entry_id`. Verified by `test_BC_2_02_009_active_set_no_duplicate_entry_ids()` (TST-PROM-02 non-VP label; active-set uniqueness invariant test for `PromoteRetireChannel`).

### AC-018 (traces to BC-2.02.007 INV-004 — LedgerChannel<T> implements graph::channels::Channel; BSP engine reduce-dispatch)
`LedgerChannel<T>` implements the `graph::channels::Channel` trait with associated types `Accumulator = Vec<T>` and `Update = T`. The BSP execution engine dispatches to `LedgerChannel::<T>::reduce` during the reduce phase without imposing additional bounds beyond `T: LedgerEntry` at call sites. `PromoteRetireChannel<T>` analogously implements `graph::channels::Channel` with `Accumulator = Vec<T>` and `Update = PromoteRetireOp<T>`. Verified by `test_BC_2_02_007_ledger_channel_implements_channel_trait()`.

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `LedgerEntry` trait, `LedgerChannel<T>` struct, reducer, and `Channel` trait impl (`Accumulator = Vec<T>`, `Update = T`) | `pregolya_graph::channels::ledger` (`graph::channels/ledger.rs`) | pregolya-graph | Pure (stateless reducer over `Vec<T>`; `Channel` impl wires BSP dispatch) |
| `PromoteRetireOp<T>` enum, `PromoteRetireChannel<T>` struct, reducer, and `Channel` trait impl (`Accumulator = Vec<T>`, `Update = PromoteRetireOp<T>`) | `pregolya_graph::channels::promote_retire` (`graph::channels/promote_retire.rs`) | pregolya-graph | Pure (stateless reducer over `Vec<T>`; `Channel` impl wires BSP dispatch) |
| VP-017 proptest harness `ledger_channel_dedup_idempotency` (dual-anchor: BC-2.02.007 {INV-001}/{INV-002} + BC-2.02.008 {INV-001}/{INV-003}) | `pregolya_graph::channels::ledger` `#[cfg(test)]` | pregolya-graph | Pure (test code) |

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
| interface-definitions.md (canonical channel struct shapes) | ~500 |
| S-1.14 context (existing `graph::channels`) | ~3,500 |
| Test files | ~2,500 |
| **Total** | **~16,000** |

Well within the 20-30% agent context window threshold.

## Tasks

- [ ] Read `pregolya-graph/src/channels/mod.rs`, `channels/last_value.rs`, and `channels/append.rs` (from S-1.14) to understand the directory module layout and existing channel infrastructure before adding anything
- [ ] Create `pregolya-graph/src/channels/ledger.rs` — declare `LedgerEntry` trait with supertrait bounds `Clone + Serialize + DeserializeOwned + Send + Sync + 'static` and required method `fn entry_id(&self) -> &str`
- [ ] In `channels/ledger.rs` — declare `#[non_exhaustive] #[derive(Default)] pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (canonical zero-sized marker shape per Rule 13; `#[derive(Default)]` ONLY — no Clone/Serialize/Deserialize; the Vec<T> accumulator lives outside the struct, managed by the BSP engine) and implement pure reducer `fn reduce(acc: Vec<T>, update: T) -> Vec<T>` (no Result; Vec linear scan per Rule 2 — no indexmap)
- [ ] In `channels/ledger.rs` — implement `graph::channels::Channel` for `LedgerChannel<T>` with `type Accumulator = Vec<T>` and `type Update = T` (BSP dispatch contract per Rule 15 / BC-2.02.007 {INV-004}); NO manual `impl Default` — use `#[derive(Default)]` on the struct instead (Rule 13)
- [ ] Create `pregolya-graph/src/channels/promote_retire.rs` — declare `#[non_exhaustive] PromoteRetireOp<T>` enum with variants `Promote(T)` and `Retire(String)`
- [ ] In `channels/promote_retire.rs` — declare `#[non_exhaustive] #[derive(Default)] pub struct PromoteRetireChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (canonical zero-sized marker shape per Rule 13; `#[derive(Default)]` ONLY — no Clone/Serialize/Deserialize; the active-set Vec<T> lives outside the struct, managed by the BSP engine) and implement pure reducer `fn reduce(acc: Vec<T>, update: PromoteRetireOp<T>) -> Vec<T>` (no Result; Vec linear scan for Promote-dedup per Rule 3 — no indexmap)
- [ ] In `channels/promote_retire.rs` — implement `graph::channels::Channel` for `PromoteRetireChannel<T>` with `type Accumulator = Vec<T>` and `type Update = PromoteRetireOp<T>` (BSP dispatch contract per Rule 15 / BC-2.02.007 {INV-004}); NO manual `impl Default` — use `#[derive(Default)]` on the struct instead (Rule 13)
- [ ] Add `pub use` re-exports for all new symbols in `pregolya-graph/src/channels/mod.rs` (no logic)
- [ ] Confirm `serde` is listed in `pregolya-graph/Cargo.toml` (workspace pin); add if absent
- [ ] Write VP-017 proptest (`ledger_channel_dedup_idempotency`) in `channels/ledger.rs` `#[cfg(test)]` — MUST fail on stubs (Red Gate discipline; dual-anchor: BC-2.02.007 {INV-001}/{INV-002} + BC-2.02.008 {INV-001}/{INV-003})
- [ ] Write unit tests for AC-001..AC-010 in `channels/ledger.rs` `#[cfg(test)]` (red first, then implement)
- [ ] Write unit tests for AC-011..AC-017 in `channels/promote_retire.rs` `#[cfg(test)]` (red first; label TST-PROM-01/TST-PROM-02 as noted in ACs)
- [ ] Run `just iter pregolya-graph` — all tests green (including existing S-1.14 tests)
- [ ] Confirm AC-011 compile-fail test (missing wildcard `_ => {}` arm for `PromoteRetireOp` + non-exhaustive construction for `LedgerChannel` and `PromoteRetireChannel`) lives in `tests/external/non-exhaustive-gate/` — NOT in `pregolya-graph` where `#[non_exhaustive]` is inert for match-completeness and struct-literal enforcement (Rule 14 / AC-011)

## Previous Story Intelligence

- S-1.14 (StateGraph Node and Channel Reducer Semantics) established the `graph::channels` directory module (`pregolya-graph/src/channels/`) with `channels/last_value.rs` (`LastValue<T>`), `channels/append.rs` (`Append<T>`), and further channel types, plus a re-export-only `channels/mod.rs`. S-1.28 extends this directory by creating `channels/ledger.rs` and `channels/promote_retire.rs`. Load `pregolya-graph/src/channels/mod.rs` and the existing channel files as context before authoring. Do not modify any existing channel types — only add the new `LedgerEntry` trait, `LedgerChannel`, `PromoteRetireOp`, and `PromoteRetireChannel` symbols in their respective new files.
- The `reduce` function pattern in `graph::channels` is established by the existing channel types. Follow the same function signature and module layout conventions.
- BC-2.02.007 {INV-003} requires the reducer to be a pure function — do not introduce any `use std::time` or `rand` dependencies.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-graph` and ADR-030 §Decision 3:

1. `LedgerEntry` trait and `LedgerChannel<T>` MUST be defined in `pregolya-graph/src/channels/ledger.rs` (`graph::channels::ledger`). `PromoteRetireOp<T>` and `PromoteRetireChannel<T>` MUST be defined in `pregolya-graph/src/channels/promote_retire.rs` (`graph::channels::promote_retire`). `channels/mod.rs` is re-export-only — no logic per CLAUDE.md `mod.rs` rule. Creating these new files is REQUIRED; adding logic to `mod.rs` is FORBIDDEN.
2. `LedgerChannel<T>::reduce` MUST be a pure function: `(Vec<T>, T) -> Vec<T>`. The canonical implementation uses Vec linear scan — NO `indexmap` dependency: `fn reduce(acc: Vec<T>, update: T) -> Vec<T> { if acc.iter().any(|e| e.entry_id() == update.entry_id()) { acc } else { let mut result = acc; result.push(update); result } }`. No mutation through shared state; no side effects.
3. `PromoteRetireChannel<T>::reduce` MUST be a pure function with signature `fn reduce(acc: Vec<T>, update: PromoteRetireOp<T>) -> Vec<T>`. Apply Vec linear scan for the Promote-dedup path (same no-indexmap rule as Rule 2).
4. `PromoteRetireOp<T>` MUST carry `#[non_exhaustive]` per code convention (public API enum).
5. `LedgerChannel<T>` and `PromoteRetireChannel<T>` structs MUST carry `#[non_exhaustive]` per code convention.
6. No `unwrap()` / `expect()` in non-test code.
7. No `println!` / `eprintln!` in library crate code.
8. `LedgerEntry` supertrait bounds MUST be exactly: `Clone + Serialize + DeserializeOwned + Send + Sync + 'static`; the single required method is `fn entry_id(&self) -> &str`. These MUST match BC-2.02.007 {PRE-001} exactly. Consequently `T: LedgerEntry` implies `T: Clone + Serialize + DeserializeOwned + Send + Sync + 'static` without additional explicit bounds at the use-site.
9. The VP-017 proptest harness (`ledger_channel_dedup_idempotency`) MUST exercise arbitrary-length sequences via the `proptest!` macro, not fixed vectors. It must assert both the dedup-uniqueness invariant (BC-2.02.007 {INV-002}) and the first-appearance ordering invariant (BC-2.02.008 {INV-001}).
10. **Forbidden dependencies:** `graph::channels` (including `channels/ledger.rs` and `channels/promote_retire.rs`) must NOT gain a dependency on `pregolya-checkpoint`, `pregolya-mcp`, `pregolya-server`, or any I/O crate. The channel reducers are pure types.
11. `LedgerChannel<T>::reduce` and `PromoteRetireChannel<T>::reduce` MUST return `Vec<T>` directly — NOT `Result<Vec<T>, _>`. The canonical pure reducer signatures are `fn reduce(acc: Vec<T>, update: T) -> Vec<T>` (Ledger) and `fn reduce(acc: Vec<T>, update: PromoteRetireOp<T>) -> Vec<T>` (PromoteRetire). Dedup and no-op paths are silent by spec (BC-2.02.007 {PC-002}, BC-2.02.009 {PC-002}/{PC-004}).
12. `serde::Serialize` and `serde::de::DeserializeOwned` in the `LedgerEntry` supertrait bounds are satisfied via `serde` (workspace pin). Do NOT import these traits from any I/O-layer crate — use only `serde::{Serialize, Deserialize}` re-exports. The `serde` crate is already a workspace dependency; confirm it is listed in `pregolya-graph/Cargo.toml` before implementing.
13. `LedgerChannel<T>` and `PromoteRetireChannel<T>` MUST have the canonical zero-sized marker shape with `#[derive(Default)]` as the ONLY derive: `#[non_exhaustive] #[derive(Default)] pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (and analogously `PromoteRetireChannel<T>`). The `Default` implementation MUST use `#[derive(Default)]` — NOT a manual `impl Default` block. No additional derives (`Clone`, `Serialize`, `Deserialize`, or any other) are permitted on the marker structs themselves — the marker type is a BSP dispatch tag, not a value type for serialization or cloning. The `Default` yield is `LedgerChannel { _inner: PhantomData }` / `PromoteRetireChannel { _inner: PhantomData }` (the zero-sized marker — NOT an empty `Vec<T>`; the accumulator `Vec<T>` is maintained externally by the BSP engine, not stored as a struct field). No `pub fn new()` constructor beyond `Default` is permitted. Use `LedgerChannel::default()` / `PromoteRetireChannel::default()` at call-sites. Cross-crate construction is blocked by both the private `_inner` field (primary: field privacy prevents struct-literal construction) and `#[non_exhaustive]` (secondary: confirms the annotation is present); both mechanisms are retained by design.
14. `indexmap` MUST NOT appear in `pregolya-graph/Cargo.toml` (production or dev dependencies). The dedup scan is a Vec linear scan per Rule 2 — O(n) is acceptable for the channel element counts expected in research-orchestrator use. Verify the Library table in this story has no `indexmap` row before closing the PR.
15. `LedgerChannel<T>` MUST implement `graph::channels::Channel` with associated types `Accumulator = Vec<T>` and `Update = T`. The BSP execution engine dispatches to `LedgerChannel::<T>::reduce` during the reduce phase; no additional bounds beyond `T: LedgerEntry` are imposed at call sites. `PromoteRetireChannel<T>` MUST analogously implement `graph::channels::Channel` with `Accumulator = Vec<T>` and `Update = PromoteRetireOp<T>`. The `Channel` trait impl is the integration contract between these channel types and the BSP engine (BC-2.02.007 {INV-004}). The `Channel` trait is defined in `graph::channels` (established by S-1.14); the impl goes in the respective channel module files.

## Library & Framework Requirements

| Library | Version | Usage |
|---------|---------|-------|
| (inherited from S-1.14) | — | `pregolya-graph` existing crate context |
| `serde` | workspace pin; confirm in `pregolya-graph/Cargo.toml` | `Serialize + DeserializeOwned` supertrait bounds on `LedgerEntry`; derive macros on implementor types |
| `proptest` | workspace pin | VP-017 `proptest!` macro in `#[cfg(test)]` |

No new crate-level dependencies are expected beyond `proptest` (dev-dependency) which is already present from S-1.16 / existing graph tests.

**No `indexmap`:** The dedup scan in `LedgerChannel::reduce` and the Promote-dedup path in `PromoteRetireChannel::reduce` MUST use Vec linear scan (Architecture Rule 2). `indexmap` must NOT appear in `pregolya-graph/Cargo.toml` — production or dev dependencies (Architecture Rule 14).

## File Structure Requirements

Files to CREATE:
- `pregolya-graph/src/channels/ledger.rs` — `LedgerEntry` trait (supertrait bounds: `Clone + Serialize + DeserializeOwned + Send + Sync + 'static`), `#[non_exhaustive] #[derive(Default)] pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (zero-sized marker; no Vec<T> field; `#[derive(Default)]` ONLY — no Clone/Serialize/Deserialize), `Channel` trait impl (`Accumulator = Vec<T>`, `Update = T`), pure `reduce(acc: Vec<T>, update: T) -> Vec<T>` impl (Vec linear scan — no indexmap); `#[cfg(test)]` VP-017 proptest `ledger_channel_dedup_idempotency` + AC-001..AC-010, AC-018 unit tests
- `pregolya-graph/src/channels/promote_retire.rs` — `#[non_exhaustive] PromoteRetireOp<T>` enum, `#[non_exhaustive] #[derive(Default)] pub struct PromoteRetireChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (zero-sized marker; no Vec<T> field; `#[derive(Default)]` ONLY — no Clone/Serialize/Deserialize), `Channel` trait impl (`Accumulator = Vec<T>`, `Update = PromoteRetireOp<T>`), pure `reduce(acc: Vec<T>, update: PromoteRetireOp<T>) -> Vec<T>` impl (Vec linear scan for Promote-dedup; no indexmap); `#[cfg(test)]` AC-012..AC-017 unit tests (TST-PROM-01: `test_BC_2_02_009_concurrent_promote_retire_deterministic_order`; TST-PROM-02: `test_BC_2_02_009_active_set_no_duplicate_entry_ids`); compile-fail test for AC-011 is in the external gate crate (see below)
- `tests/external/non-exhaustive-gate/Cargo.toml` — manifest for the external compile-fail gate crate; depends on `pregolya-graph`; `edition = "2024"`
- `tests/external/non-exhaustive-gate/src/lib.rs` — `test_BC_2_02_009_promote_retire_op_non_exhaustive_requires_wildcard()` compile-fail test verifying `#[non_exhaustive]` enforcement on `PromoteRetireOp<T>`, `LedgerChannel<T>`, and `PromoteRetireChannel<T>` from outside the defining crate (AC-011)

Files to MODIFY:
- `pregolya-graph/src/channels/mod.rs` — `pub use` re-exports for `LedgerEntry`, `LedgerChannel`, `PromoteRetireOp`, `PromoteRetireChannel` (re-export-only; no logic per CLAUDE.md `mod.rs` rule)
- `pregolya-graph/src/lib.rs` — ensure `LedgerEntry`, `LedgerChannel`, `PromoteRetireOp`, `PromoteRetireChannel` are publicly re-exported at the crate root

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
| 1.4 | 2026-08-31 | Round-53 fix-burst: F-P2A220-03 — AC-018 added (BC-2.02.007 {INV-004}): LedgerChannel<T> + PromoteRetireChannel<T> implement graph::channels::Channel (Accumulator=Vec<T>; BSP dispatch contract); BC table updated; F-P2A220-01 — Rule 13 extended with #[derive(Default)] ONLY + no Clone/Serialize/Deserialize on marker structs; Rule 15 added; AC-001 struct shape updated; Architecture Mapping updated; Tasks updated for #[derive(Default)] + Channel trait; File Structure updated | story-writer |
| 1.3 | 2026-08-31 | Round-52 fix-burst: PhantomData struct shape canonicalized (LedgerChannel + PromoteRetireChannel are zero-sized markers; Default yields marker not Vec<T>); AC-001 + AC-011 + Rule 13 + File Structure updated; AC-011 load-bearing gate re-focused to PromoteRetireOp enum wildcard; interface-definitions.md added to inputs | story-writer |
| 1.2 | 2026-08-31 | Round-51 fix-burst: F-P2A212-06 AC-011 compile-fail gate to external crate (LedgerChannel+PromoteRetireChannel too); F-P2A212-08 incoming->update in AC-002/003, active/op->acc/update in AC-012..015+Rules; Default impls for both structs; Rule 2 Vec-linear-scan implementation; Rules 13-14 added; File structure updated | story-writer |
| 1.1 | 2026-08-31 | Round-50 fix-burst: LedgerEntry Serialize+DeserializeOwned supertrait bounds; channels/ directory module; VP-017 dual-anchor; TST-PROM-01/02 labels; pure reducer no-Result rule; serde dep; file-structure for ledger.rs+promote_retire.rs | story-writer |
| 1.0 | 2026-08-31 | Initial authoring — praxist Stage-3 story decomposition for BC-2.02.007/008/009 + VP-017 | story-writer |
