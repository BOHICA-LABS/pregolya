---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.009
version: "1.2"
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
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-040
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "a280d94"
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
| TST-PROM-01 | `Promote` is idempotent: applying it twice for the same `entry_id` yields the same active set as applying it once | Unit test — not a registered VP | Wave 1 |
| TST-PROM-02 | `Retire` is idempotent: applying it for an absent `entry_id` leaves the active set unchanged | Unit test — not a registered VP | Wave 1 |

## Related BCs

- BC-2.02.007 — related to: `LedgerChannel` provides monotonic accumulation; `PromoteRetireChannel` provides a bidirectional promote/retire lifecycle; both are composable channel types in the same `StateGraph`
- BC-2.02.008 — related to: `LedgerChannel` first-appearance ordering is a different ordering semantics; `PromoteRetireChannel` active set has no defined ordering guarantee beyond its `Vec<T>` representation
- BC-2.02.002 — depends on: `PromoteRetireChannel` extends the `graph::channels` channel family alongside existing channel types

## Architecture Anchors

- `pregolya-graph/src/channels.rs` (`graph::channels`) — `PromoteRetireOp<T>` enum (`Promote(T)` / `Retire(String)`); `PromoteRetireChannel<T>` struct; reducer function operating on `Vec<T>` active set
- `pregolya-graph/src/definition.rs` (`graph::definition`) — `StateGraph` channel registration; `PromoteRetireChannel` registered as a channel type with reducer `PromoteRetireOp<T>`
- ADR-030 §Decision 3 — `PromoteRetireChannel` design; `LedgerEntry` as the common marker trait for both `LedgerChannel` and `PromoteRetireChannel` entries

## Story Anchor

S-TBD (assigned at story decomposition — Stage 3)

## VP Anchors

None

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `PromoteRetireChannel` is the second of the two new ledger-style channel types introduced by CAP-040; the promote/retire lifecycle enables the quality-diversity allocation cycle described in CAP-040 §PromoteRetireChannel |
| L2 Domain Invariants | DI-014 (Error Propagation — No Silent Swallowing: idempotent `Promote` and `Retire` operations return the correct active set without raising `Err`; the contract is explicit no-op, not silent error; DI-014 prohibits returning `None` to represent these cases, which is satisfied by always returning `Vec<T>`) |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit) |
| Module | pregolya-graph |
