---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.009
version: "1.9"
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
  - "1.0 (ADR-030 Stage 2a/2026-08-31): Initial greenfield spec — PromoteRetireChannel promote/retire lifecycle; DI-014 invariant enforcement; ADR-030 Decision 3."
  - "1.1 (ADR-030 Stage 2b/2026-08-31): [INACCURATE — superseded by v1.2 provenance correction] Previously stated 'Renumbered from BC-2.04.011 to BC-2.02.009' — this is incorrect per ADR-030 §Renumber-Provenance Canonical Narrative (F-P2A210-02)."
  - "1.2 (round-50/Stage-B1-product-owner/2026-08-31): Provenance corrected per ADR-030 §Renumber-Provenance (F-P2A210-02): BC-2.02.009 was CREATED as a new SS-02 BC; PromoteRetireChannel content was physically relocated from an erroneous PO draft that used BC-2.04.011 (which was always reserved for Trajectory Compaction Isolation in SS-04; BC-2.04.011 continues as a separate active BC). BC-2.04.011 is NOT the prior_id of BC-2.02.009. Prior-ID: N/A (new creation). {PRE-001} supertrait bound corrected: T: LedgerEntry (supertrait already includes Clone + Serialize + DeserializeOwned + Send + Sync + 'static — use-site redundancy removed per F-P2A208-11). VP-PROM-01/02 phantom labels relabeled TST-PROM-01/02 in §Verification Properties; removed from §VP Anchors (not registered VPs)."
  - "1.3 (round-51/Stage-B2-product-owner/2026-08-31): §Story Anchor resolved: S-1.28 (per STORY-INDEX; F-P2A214-01 hook #19 compliance). §Architecture Anchors: PromoteRetireOp<T> + PromoteRetireChannel<T> canonical file corrected from phantom flat-file channels.rs to directory module channels/promote_retire.rs (F-P2A215-01; graph::channels module path unchanged)."
  - "1.4 (round-52/F-P2A216-04/2026-08-31): §Architecture Anchors: `PromoteRetireChannel<T>` struct canonical shape added — `#[non_exhaustive] pub struct PromoteRetireChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (zero-sized marker; `Default::default()` produces the zero-sized marker struct; the `Vec<T>` active-set accumulator is external to the marker, owned and managed by the BSP engine — F-P2A216-04). No behavioral change."
  - "1.5 (round-55/F-P2A225-01/2026-09-01): §Traceability L2 Domain Invariants: DI-014 replaced with DI-001 per architect ADR-030 §VP ruling — PromoteRetireChannel::reduce is a pure infallible reducer returning Vec<T> with no Result/Err/None path; DI-014 (error propagation) is inapplicable (vacuously compliant, not meaningfully enforced). DI-001 (BSP Reducer Determinism) is the correct domain-invariant anchor: the reducer is deterministic given the same accumulated state and input sequence in task-identity order."
  - "1.6 (round-57/F-P2A227-01/2026-09-01): §Architecture Anchors: replaced implicit `Default::default()` annotation with an explicit manual bound-free `impl<T: LedgerEntry> Default for PromoteRetireChannel<T>` per ADR-030 §Decision 3 round-57 architect ruling — `#[derive(Default)]` would emit a spurious `T: Default` bound that breaks the `Channel: Default + Send + Sync + 'static` supertrait obligation for callers holding only `T: LedgerEntry`. {INV-004} added: explicit `Channel: Default` supertrait-obligation clause — satisfied by the manual bound-free impl, not a derive. Supersedes the implicit Default from round-52 (F-P2A216-04)."
  - "1.7 (round-58/F-P2A229-01/2026-09-01): {INV-004} extended with Update-side Clone obligation — `PromoteRetireOp<T>` satisfies `Channel::Update: Clone + Send + Sync + 'static` via `#[derive(Clone)]`; sound because `LedgerEntry: Clone` (supertrait bundles Clone), so `PromoteRetireOp<T>: Clone` holds for all `T: LedgerEntry` with no bound beyond the supertrait; no use-site may add `T: Clone` as an explicit constraint — it is implied by `T: LedgerEntry` (per ADR-030 §Decision 3 round-58 / F-P2A229-01)."
  - "1.8 (round-62/F-P2A234-04/2026-09-01): §Verification Properties updated — promote/retire idempotency and ordering invariants ({INV-001}/{INV-002}) are now covered by registered VP-020 (proptest P1, Phase-3, harness `promote_retire_channel_idempotency`; DI-001); TST-PROM-01/TST-PROM-02 unit tests retained as supplementary verification alongside VP-020. §VP Anchors updated from None to VP-020."
  - "1.9 (round-65/F-P2A237-03/2026-09-01): §Traceability Test Types corrected from 'U (unit)' to 'U (unit), P (property)' — VP-020 (registered proptest, harness promote_retire_channel_idempotency) was added in v1.8 but §Traceability Test Types cell was not updated; aligned with sibling BC-2.02.007 canonical form."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-040
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "df596f3"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.009: PromoteRetireChannel Promote/Retire Lifecycle

## Description

`PromoteRetireChannel<T>` is a `StateGraph` channel reducer type in `graph::channels`
(pregolya-graph) that maintains an active set of entries. Its reducer operates on a
`PromoteRetireOp<T>` discriminated union: `Promote(T)` adds an entry to the active set
(idempotent if already present); `Retire(entry_id: String)` removes an entry from the active
set by its `entry_id` (idempotent if already absent). The channel value is `Vec<T>` — the
current active set. The lifecycle enables candidates in a quality-diversity allocation cycle
to advance from pending to active and be retired when superseded or committed.

## Preconditions

1. {PRE-001} A `StateGraph` channel of type `PromoteRetireChannel<T>` is declared for a state
   field, where `T: LedgerEntry`. (`LedgerEntry` is a supertrait that already requires
   `Clone + Serialize + DeserializeOwned + Send + Sync + 'static`; use-site repetition of
   those bounds is redundant and should be omitted — supertrait form per F-P2A208-11.)
2. {PRE-002} The reducer input type is `PromoteRetireOp<T>` — a `#[non_exhaustive]` enum
   with variants `Promote(T)` and `Retire(String)` (the `String` is the `entry_id` to remove).
3. {PRE-003} Node outputs that write to this channel emit `PromoteRetireOp<T>` values via the
   standard StateGraph channel-write path.

## Postconditions

1. {PC-001} `PromoteRetireOp::Promote(entry)` where `entry.entry_id()` is NOT already in the
   active set: the entry is appended to the `Vec<T>` active set. The active set grows by
   exactly one element.
2. {PC-002} `PromoteRetireOp::Promote(entry)` where `entry.entry_id()` IS already in the
   active set: the active set is unchanged (idempotent promote). No duplicate is created.
3. {PC-003} `PromoteRetireOp::Retire(entry_id)` where `entry_id` IS present in the active
   set: the entry with that `entry_id` is removed from the `Vec<T>`. The active set shrinks
   by exactly one element.
4. {PC-004} `PromoteRetireOp::Retire(entry_id)` where `entry_id` is NOT present in the
   active set: the active set is unchanged (idempotent retire). No error is raised.
5. {PC-005} The reducer returns `Vec<T>` (the updated active set) in all four cases
   ({PC-001}–{PC-004}). No `Err(PregolyaError)` is raised for idempotent operations.
6. {PC-006} Within a single super-step, multiple `PromoteRetireOp` values are processed in
   deterministic task-identity-sorted order (DI-001), so concurrent Promote + Retire
   operations on the same `entry_id` produce a deterministic final active set.

## Invariants

- {INV-001} The active set `Vec<T>` contains no duplicate `entry_id` values at any time.
  `Promote` is idempotent (does not add a second copy); `Retire` removes exactly one entry.
- {INV-002} The reducer is a pure function of its inputs: given the same initial active set
  and the same sequence of `PromoteRetireOp` values (in task-identity order), the resulting
  active set is always identical.
- {INV-003} `Retire` operates by `entry_id` matching only — it does not require the full `T`
  value. Any entry in the active set whose `entry_id()` equals the `Retire(entry_id)` argument
  is removed, regardless of the entry's other fields.
- {INV-004} **Channel trait dispatch contract:** `PromoteRetireChannel<T>` implements
  `graph::channels::Channel` with `Accumulator = Vec<T>` and `Update = PromoteRetireOp<T>`; the
  BSP engine dispatches to `PromoteRetireChannel::<T>::reduce` during the reduce phase. No
  additional bounds beyond `T: LedgerEntry` are required at call sites — the `LedgerEntry`
  supertrait (`Clone + Serialize + DeserializeOwned + Send + Sync + 'static`) already satisfies
  the `Accumulator` bounds of the `Channel` trait. The `Channel` supertrait additionally requires
  `Self: Default`; `PromoteRetireChannel<T>: Default` for all `T: LedgerEntry` is satisfied by a
  MANUAL bound-free `Default` impl — NOT `#[derive(Default)]`, which would emit a spurious
  `T: Default` bound and break call sites where `T: LedgerEntry` but `T: !Default`, violating the
  "no bounds beyond `T: LedgerEntry`" guarantee of this invariant (per ADR-030 §Decision 3 round-57).
  The `Channel` trait additionally requires `Update: Clone + Send + Sync + 'static`;
  `PromoteRetireOp<T>` satisfies this bound. `Clone` is satisfied via `#[derive(Clone)]` on
  `PromoteRetireOp<T>` — sound because `LedgerEntry: Clone` (the supertrait bundles `Clone`),
  so `PromoteRetireOp<T>: Clone` holds for all `T: LedgerEntry` with no bound beyond the supertrait.
  No use-site may add `T: Clone` as an explicit constraint — it is implied by `T: LedgerEntry`
  (per ADR-030 §Decision 3 round-58 / F-P2A229-01).

## Edge Cases

### EC-001: Promote the same entry_id twice
**Scenario:** `Promote(T{id:"a"})` is applied to an active set already containing `T{id:"a"}`.
**Expected behavior:** Active set unchanged — the second Promote is a no-op. No error.

### EC-002: Retire an entry_id not in the active set
**Scenario:** `Retire("phantom_id")` is applied to an active set that does not contain any
entry with `entry_id = "phantom_id"`.
**Expected behavior:** Active set unchanged. No error. Idempotent retire is a valid
steady-state operation in a convergence loop where the entry may have been retired in a
previous super-step.

### EC-003: Promote then Retire in the same super-step
**Scenario:** In one super-step, node1 emits `Promote(T{id:"x"})` (task-id lower) and node2
emits `Retire("x")` (task-id higher). Both ops apply to an initial active set not containing
`"x"`.
**Expected behavior:** In task-identity order, `Promote` is processed first (adds `"x"`),
then `Retire` is processed (removes `"x"`). Net result: active set unchanged. Deterministic
per DI-001.

### EC-004: Retire then Promote in the same super-step (opposite order)
**Scenario:** Same as EC-003 but node1 has higher task-id and node2 has lower. `Retire("x")`
processes first (no-op — "x" not yet present), then `Promote(T{id:"x"})` processes (adds
"x").
**Expected behavior:** Active set contains `T{id:"x"}` after the super-step. The outcome
differs from EC-003 because task-identity order is deterministic per DI-001.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Active `vec![]`; `Promote(T{id:"a"})`, `Promote(T{id:"b"})` | Active `vec![T{id:"a"}, T{id:"b"}]` | Happy-path two promotes |
| TV-002 | Active `vec![T{id:"a"}, T{id:"b"}]`; `Retire("a")` | Active `vec![T{id:"b"}]` | Retire removes entry by entry_id |
| TV-003 | Active `vec![T{id:"a"}]`; `Promote(T{id:"a"})` | Active `vec![T{id:"a"}]` (unchanged) | Idempotent promote; {PC-002} |
| TV-004 | Active `vec![]`; `Retire("non_existent")` | Active `vec![]` (unchanged, no error) | Idempotent retire; {PC-004} |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-020 | Promote/retire idempotency and deterministic ordering: for any sequence of `PromoteRetireOp` values in task-identity order, the resulting active set contains no duplicate `entry_id` values ({INV-001}) and the reducer produces the same output given the same inputs ({INV-002}); harness exercises idempotent promote, idempotent retire, and concurrent promote+retire ordering | proptest (harness `promote_retire_channel_idempotency`; DI-001 — {INV-001}, {INV-002}, {PC-001}–{PC-006}) | Phase 3 |
| TST-PROM-01 | `Promote` is idempotent: applying it twice for the same `entry_id` yields the same active set as applying it once | Unit test (supplementary, alongside VP-020) | Wave 1 |
| TST-PROM-02 | `Retire` is idempotent: applying it for an absent `entry_id` leaves the active set unchanged | Unit test (supplementary, alongside VP-020) | Wave 1 |

## Related BCs

- BC-2.02.007 — related to: `LedgerChannel` provides monotonic accumulation; `PromoteRetireChannel` provides a bidirectional promote/retire lifecycle; both are composable channel types in the same `StateGraph`
- BC-2.02.008 — related to: `LedgerChannel` first-appearance ordering is a different ordering semantics; `PromoteRetireChannel` active set has no defined ordering guarantee beyond its `Vec<T>` representation
- BC-2.02.002 — depends on: `PromoteRetireChannel` extends the `graph::channels` channel family alongside existing channel types

## Architecture Anchors

- `pregolya-graph/src/channels/promote_retire.rs` (`graph::channels`) — `PromoteRetireOp<T>` enum
  (`Promote(T)` / `Retire(String)`); `PromoteRetireChannel<T>` struct canonical shape:
  `#[non_exhaustive] pub struct PromoteRetireChannel<T: LedgerEntry> { _inner: PhantomData<T> }` (zero-sized
  marker; `Default` is provided by a MANUAL bound-free impl — NOT `#[derive(Default)]`, which would emit
  a spurious `T: Default` bound incompatible with callers holding only `T: LedgerEntry` and violating
  {INV-004} — per ADR-030 §Decision 3 round-57:
  `impl<T: LedgerEntry> Default for PromoteRetireChannel<T> { fn default() -> Self { Self { _inner: PhantomData } } }`;
  no `Clone` / `Serialize` / `Deserialize` derives on the marker struct;
  the `Vec<T>` active-set accumulator is external to the marker, owned and managed by the BSP engine);
  reducer function operating on `Vec<T>` active set
- `pregolya-graph/src/definition.rs` (`graph::definition`) — `StateGraph` channel registration; `PromoteRetireChannel` registered as a channel type with reducer `PromoteRetireOp<T>`
- ADR-030 §Decision 3 — `PromoteRetireChannel` design; `LedgerEntry` as the common marker trait for both `LedgerChannel` and `PromoteRetireChannel` entries

## Story Anchor

S-1.28

## VP Anchors

- VP-020 (proptest P1, Phase-3, harness `promote_retire_channel_idempotency` — {INV-001} no-duplicate active set, {INV-002} deterministic pure reducer, DI-001)

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `PromoteRetireChannel` is the second of the two new ledger-style channel types introduced by CAP-040; the promote/retire lifecycle enables the quality-diversity allocation cycle described in CAP-040 §PromoteRetireChannel |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism: `PromoteRetireChannel` reducer is deterministic; given the same accumulated state and input sequence in task-identity order, the result is always identical — per ADR-030 §VP round-55 architect ruling) |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), P (property) |
| Module | pregolya-graph |
