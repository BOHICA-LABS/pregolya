---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.007
version: "1.4"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-02
capability: CAP-040
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-08-31T00:00:00Z
changelog:
  - "1.0 (ADR-030 Stage 2a/2026-08-31): Initial greenfield spec — LedgerChannel dedup-idempotent append; VP-017 proptest anchor (harness ledger_channel_dedup_idempotency); DI-014 + DI-001 invariant enforcement; ADR-030 Decision 3."
  - "1.1 (round-50/Stage-B1-product-owner/2026-08-31): {PRE-001} supertrait bound adopted: T: LedgerEntry (replaces T: LedgerEntry + Clone + Send + Sync + 'static — those bounds are already imposed by the LedgerEntry supertrait, use-site repetition removed per F-P2A208-11). §Architecture Anchors: LedgerEntry trait definition updated to show Serialize + DeserializeOwned supertrait bounds (F-P2A211-07 serde requirement for CheckpointSaver::put_writes checkpoint-resume; fn entry_id now returns &str not String). LedgerChannel reducer model stated as fn reduce(acc: Vec<T>, update: T) -> Vec<T> pure function — consistent with interface-definitions.md §LedgerChannel stateless-reducer-marker model and S-1.14 channel family (no Result, no Ok(()))."
  - "1.2 (round-51/Stage-B2-product-owner/2026-08-31): §Story Anchor resolved: S-1.28 (per STORY-INDEX; F-P2A214-01 hook #19 compliance). §Architecture Anchors: LedgerEntry + LedgerChannel canonical file corrected from phantom flat-file channels.rs to directory module channels/ledger.rs (F-P2A215-01; graph::channels module path unchanged)."
  - "1.3 (round-52/F-P2A216-04/2026-08-31): §Architecture Anchors: `LedgerChannel<T>` struct canonical shape added — `#[non_exhaustive] pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }`; `Default::default()` produces `LedgerChannel { _inner: PhantomData }` (the zero-sized marker struct); the `Vec<T>` accumulator is external to the marker, owned and managed by the BSP engine. No behavioral change."
  - "1.4 (round-53/F-P2A220-03+F-P2A220-01/2026-08-31): {INV-004} added — Channel trait dispatch contract: LedgerChannel<T> implements graph::channels::Channel with Accumulator = Vec<T> and Update = T; BSP engine dispatches to LedgerChannel::<T>::reduce during the reduce phase; no additional bounds beyond T: LedgerEntry required at call sites. Architecture Anchors: LedgerChannel<T> canonical derive set made explicit — #[derive(Default)] only; all Accumulator/serde/Clone/Send/Sync bounds come from LedgerEntry supertrait on T and Vec<T> derived properties (F-P2A220-01)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-040
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "410c38d"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.007: LedgerChannel Dedup-Idempotent Append

## Description

`LedgerChannel<T>` is a `StateGraph` channel reducer type in `graph::channels`
(pregolya-graph). Its reducer semantics guarantee dedup-idempotent append: a `T` whose
`entry_id()` is novel is appended to the accumulated `Vec<T>` channel value; a `T` whose
`entry_id()` has already been seen is silently discarded as a no-op, without raising an error.
The accumulated value never shrinks and the `entry_id` set across all accumulated entries is
always a unique ordered sequence. This property is the formal target of VP-017 (proptest P1,
harness `ledger_channel_dedup_idempotency`).

## Preconditions

1. {PRE-001} A `StateGraph` channel of type `LedgerChannel<T>` is declared for a state
   field, where `T: LedgerEntry`. (`LedgerEntry` is a supertrait defined as
   `pub trait LedgerEntry: Clone + Serialize + DeserializeOwned + Send + Sync + 'static`
   with `fn entry_id(&self) -> &str`; use-site repetition of the supertrait bounds is
   redundant and must be omitted — supertrait form per F-P2A208-11 and
   interface-definitions.md §LedgerChannel.)
2. {PRE-002} `T::entry_id(&self) -> &str` returns a stable string identifier for each
   instance of `T`. Two logically distinct entries MUST have different `entry_id` values;
   two logically identical entries MUST have the same `entry_id` value.
3. {PRE-003} One or more `T` values are submitted to the channel via the standard
   StateGraph channel-write path (node output fields or `Send` arg) in a super-step.

## Postconditions

1. {PC-001} For each `T` submitted in a super-step whose `entry_id()` has NOT appeared in
   the current accumulated `Vec<T>`, the `T` is appended to the end of the `Vec<T>`.
2. {PC-002} For each `T` submitted whose `entry_id()` HAS already appeared in the
   current accumulated `Vec<T>`, the `Vec<T>` is unchanged (no append, no replacement, no
   in-place mutation). The result is the same as if that `T` had not been submitted.
3. {PC-003} The reducer returns a `Vec<T>` result in both the novel-append ({PC-001}) and
   the duplicate-skip ({PC-002}) cases. No `Err(PregolyaError)` is raised for a duplicate
   `entry_id` — duplicates are a valid and expected operating condition.
4. {PC-004} After processing a super-step containing a mix of novel and duplicate entries,
   the resulting `Vec<T>` contains exactly one element per distinct `entry_id` value seen
   across the entire accumulated history (not just the current super-step).

## Invariants

- {INV-001} The accumulated `Vec<T>` is monotonically non-decreasing in length: it never
  shrinks. The only permitted transition is from length N to length N+k (k ≥ 0) per
  super-step.
- {INV-002} The `entry_id` values across all elements of the accumulated `Vec<T>` form a
  set: no two elements share an `entry_id`. This holds at all times, not only after a
  complete super-step.
- {INV-003} The reducer is a pure function: given the same accumulated `Vec<T>` and the
  same sequence of incoming `T` values (in task-identity order per DI-001), the resulting
  `Vec<T>` is always identical. No external state, random numbers, or wall-clock time are
  consulted.
- {INV-004} **Channel trait dispatch contract:** `LedgerChannel<T>` implements
  `graph::channels::Channel` with `Accumulator = Vec<T>` and `Update = T`; the BSP engine
  dispatches to `LedgerChannel::<T>::reduce` during the reduce phase. No additional bounds
  beyond `T: LedgerEntry` are required at call sites — the `LedgerEntry` supertrait
  (`Clone + Serialize + DeserializeOwned + Send + Sync + 'static`) already satisfies the
  `Accumulator` bounds of the `Channel` trait, and `T: Clone + Send + Sync + 'static`
  (via `LedgerEntry`) satisfies the `Update` bounds.

## Edge Cases

### EC-001: Duplicate entry_id submitted by multiple concurrent nodes in the same super-step
**Scenario:** Two nodes in the same super-step both emit a `T` with `entry_id = "x"`. The
LedgerChannel reducer processes writes in deterministic task-identity-sorted order (DI-001).
**Expected behavior:** The first write (lowest task-identity) appends the entry; the second
write sees `"x"` already present and is a no-op. Only one element with `entry_id = "x"` is
in the accumulated `Vec`. No error.

### EC-002: Empty channel — first append
**Scenario:** The `LedgerChannel<T>` has initial value `vec![]` and a single novel `T` is
submitted.
**Expected behavior:** `Vec<T>` transitions to `vec![T]`. Length changes from 0 to 1.

### EC-003: All entries in a super-step are duplicates
**Scenario:** Every `T` submitted in a super-step has an `entry_id` already present in the
accumulated `Vec<T>`.
**Expected behavior:** The accumulated `Vec<T>` is identical before and after the super-step.
Length does not change. No error. This is a normal operating condition in a convergence loop
where all outstanding evidence entries have already been recorded.

### EC-004: entry_id is an empty string
**Scenario:** `T::entry_id()` returns `""` for a submitted entry.
**Expected behavior:** The empty string `""` is treated as a valid `entry_id` subject to the
same dedup-idempotent semantics. The first `T` with `entry_id = ""` is appended; subsequent
ones are no-ops. Callers are responsible for ensuring `entry_id` values are semantically
meaningful within their domain; `LedgerChannel` imposes no minimum-length constraint.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Acc `vec![]`; append `T{id:"a"}` then `T{id:"b"}` | `vec![T{id:"a"}, T{id:"b"}]` | Happy-path two novel appends |
| TV-002 | Acc `vec![T{id:"a"}]`; append `T{id:"a"}` | `vec![T{id:"a"}]` (length unchanged) | Duplicate no-op; {PC-002} |
| TV-003 | Acc `vec![]`; submit `T{id:"a"}`, `T{id:"b"}`, `T{id:"a"}`, `T{id:"c"}` in task-id order | `vec![T{id:"a"}, T{id:"b"}, T{id:"c"}]` | Mixed novel + duplicate sequence; 4 inputs → 3 unique entries |
| TV-004 | Acc `vec![T{id:"x"}, T{id:"y"}]`; concurrent super-step: node1 emits `T{id:"y"}` (dup), node2 emits `T{id:"z"}` (novel) | `vec![T{id:"x"}, T{id:"y"}, T{id:"z"}]` | Concurrent writes; one duplicate (no-op), one novel (append) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-017 | For any sequence of reduces on `LedgerChannel<T>`, the final `Vec<T>` contains exactly the entries with distinct `entry_id` values, in first-appearance order | proptest | 3 |

## Related BCs

- BC-2.02.008 — composes with: first-appearance ordering is the complementary ordering invariant for LedgerChannel (dedup is one axis; ordering is the other)
- BC-2.02.002 — depends on: LedgerChannel extends the `graph::channels` channel family alongside Append / BarrierValue / EphemeralValue
- BC-2.03.001 — depends on: BSP deterministic task-identity reducer order (DI-001) governs which concurrent write "wins" when the same `entry_id` appears from multiple nodes in the same super-step

## Architecture Anchors

- `pregolya-graph/src/channels/ledger.rs` (`graph::channels`) — `LedgerEntry` supertrait definition:
  `pub trait LedgerEntry: Clone + Serialize + DeserializeOwned + Send + Sync + 'static`
  with `fn entry_id(&self) -> &str` (stable dedup key; `Serialize + DeserializeOwned` bounds
  required for `CheckpointSaver::put_writes` checkpoint-resume serialization — F-P2A211-07);
  `LedgerChannel<T>` struct canonical shape:
  `#[non_exhaustive] #[derive(Default)] pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }` —
  the zero-sized marker type; canonical derive set: `Default` only (all `Accumulator` / serde /
  `Clone` / `Send` / `Sync` bounds come from the `LedgerEntry` supertrait on `T` and from
  `Vec<T>`'s derived properties — no additional derives on the marker struct itself);
  `Default::default()` produces `LedgerChannel { _inner: PhantomData }` (F-P2A216-04);
  the `Vec<T>` accumulator is external to the marker, owned and managed by the BSP engine;
  reducer pure function
  `fn reduce(acc: Vec<T>, update: T) -> Vec<T>` (no `Result`, no `Ok(())`) implementing
  the dedup-idempotent semantics
- `pregolya-graph/src/definition.rs` (`graph::definition`) — `StateGraph` channel registration API; `LedgerChannel` is registered as a channel type via the same mechanism as `Append` / `LastValue`
- ADR-030 §Decision 3 — design rationale for `LedgerChannel` in `graph::channels`; `LedgerEntry` marker trait; `PromoteRetireOp` companion type

## Story Anchor

S-1.28

## VP Anchors

- VP-017

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `LedgerChannel` is one of the two new channel types introduced under CAP-040; the dedup-idempotent-append reducer is the core semantics defined in CAP-040 for evidence accumulation in multi-generation research loops |
| L2 Domain Invariants | DI-014 (Error Propagation — No Silent Swallowing: the dedup no-op case returns the unchanged `Vec<T>` without raising `Err`, which is the specified contract, not silent error swallowing; DI-014 is enforced because {PC-003} prohibits returning `None` or silent `Err` to represent duplicate detection), DI-001 (BSP Reducer Determinism: `LedgerChannel` reducer is deterministic; given the same accumulated state and the same input sequence in task-identity order, the result is always identical per {INV-003}) |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), P (property) |
| Module | pregolya-graph |
