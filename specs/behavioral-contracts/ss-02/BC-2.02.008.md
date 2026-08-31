---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.008
version: "1.1"
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
  - "1.0 (ADR-030 Stage 2a/2026-08-31): Initial greenfield spec — LedgerChannel first-appearance ordering; DI-001 invariant enforcement; ADR-030 Decision 3."
  - "1.1 (round-50/Stage-B1-product-owner/2026-08-31): §Verification Properties VP-017 description updated to reflect dual-anchor: VP-017 proptest now explicitly anchors both BC-2.02.007 (dedup-idempotent append) and BC-2.02.008 (first-appearance ordering) — the ordering invariant is exercised by the same arbitrary-sequence proptest harness. VP-INDEX propagation to architect per vp_index_is_vp_catalog_source_of_truth policy."
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

# BC-2.02.008: LedgerChannel First-Appearance Ordering

## Description

`LedgerChannel<T>` accumulates entries in a `Vec<T>` that is ordered by the first appearance
of each distinct `entry_id`. When an entry with a novel `entry_id` is appended (per the
dedup-idempotent semantics of BC-2.02.007), it is placed at the end of the `Vec`. Duplicate
entries (already-seen `entry_id`) do not affect position. The result is that iterating over
the channel value yields entries in the chronological order in which their `entry_id` first
appeared across all super-steps. This deterministic ordering is an invariant of the channel
reducer — not a post-processing sort — and enables reproducible traversal of accumulated
evidence.

## Preconditions

1. {PRE-001} A `StateGraph` channel of type `LedgerChannel<T>` has been populated across one
   or more super-steps via the dedup-idempotent reducer (BC-2.02.007 {PC-001}).
2. {PRE-002} The channel value is a `Vec<T>` accessible for iteration.
3. {PRE-003} `T: LedgerEntry` — `T::entry_id(&self) -> &str` is stable across calls for the
   same entry instance.

## Postconditions

1. {PC-001} Iterating over `Vec<T>` (the channel value) yields entries in the order their
   `entry_id` FIRST appeared chronologically across all prior super-steps. The position of an
   entry in the `Vec` equals the index at which its `entry_id` was first seen (0-indexed,
   earliest = 0).
2. {PC-002} Re-submitting an entry with an already-seen `entry_id` (duplicate) does not alter
   the position of any existing entry in the `Vec`. Ordering is stable under any sequence of
   duplicate submissions.
3. {PC-003} For any two entries `e_i` and `e_j` in the `Vec` where `e_i` was first submitted
   in an earlier super-step than `e_j`, `e_i` appears at a lower index than `e_j`.
4. {PC-004} Within a single super-step where multiple novel entries arrive, their relative
   order in the `Vec` is the deterministic task-identity-sorted write order (DI-001 /
   BC-2.03.001), ensuring reproducibility across reruns.

## Invariants

- {INV-001} Insertion order of first-seen `entry_id` values is preserved as the `Vec<T>`
  ordering invariant. This order is not affected by subsequent duplicate submissions and is
  not affected by the order in which duplicates are processed.
- {INV-002} The ordering of the `Vec<T>` is deterministic: two runs of the same graph with
  the same input sequence produce a `Vec<T>` with the same element order. No random
  permutation occurs.
- {INV-003} The `Vec<T>` ordering is monotonically stable: elements already in the `Vec`
  never change position. New entries are always appended to the end.

## Edge Cases

### EC-001: Re-submitting an entry shifts nothing
**Scenario:** The accumulated `Vec<T>` is `[A(id:"a"), B(id:"b")]`. In the next super-step,
an entry `A'` with `entry_id = "a"` is submitted again.
**Expected behavior:** `Vec<T>` remains `[A(id:"a"), B(id:"b")]`. `A` does not move to the
end; `B` does not move forward. Ordering is stable.

### EC-002: Empty channel
**Scenario:** `LedgerChannel<T>` has accumulated value `vec![]`.
**Expected behavior:** Iteration yields no elements. The first novel entry submitted will
appear at index 0.

### EC-003: All entries arrive in a single super-step
**Scenario:** In one super-step, three nodes emit `T{id:"c"}`, `T{id:"a"}`, `T{id:"b"}` in
task-identity-sorted order (DI-001).
**Expected behavior:** `Vec<T>` is `[T{id:"c"}, T{id:"a"}, T{id:"b"}]` — in task-identity
order for that super-step. Within a single super-step there is no "prior history" to
reference; task-identity sort (DI-001) determines first-appearance order.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Acc `vec![]`; step-1 submit `T{id:"a"}`, `T{id:"b"}`; step-2 submit `T{id:"c"}` | `vec![T{id:"a"}, T{id:"b"}, T{id:"c"}]` | First-appearance ordering across two super-steps |
| TV-002 | Acc `vec![T{id:"a"}, T{id:"b"}]`; step-2 submit `T{id:"b"}` (dup), `T{id:"c"}` (novel) | `vec![T{id:"a"}, T{id:"b"}, T{id:"c"}]` | Duplicate does not change b's position; novel appends at end |
| TV-003 | Acc `vec![]`; step-1 submit `T{id:"b"}`, `T{id:"a"}`, `T{id:"b"}` (task-id order) | `vec![T{id:"b"}, T{id:"a"}]` | Within a super-step: task-id order governs; second `T{id:"b"}` is deduped |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-017 | **Dual-anchor: BC-2.02.007 + BC-2.02.008.** VP-017 proptest (harness `ledger_channel_dedup_idempotency`) exercises arbitrary entry sequences and asserts both dedup-idempotency ({INV-002} no-duplicate) AND first-appearance ordering (this BC's {INV-001}): the final `Vec<T>` contains entries in the order their `entry_id` first appeared across the full sequence. The ordering invariant is an emergent property of the same `Vec::push`-on-novel append operation that VP-017 already validates. | proptest | 3 |

## Related BCs

- BC-2.02.007 — composes with: dedup-idempotent append is the prerequisite for first-appearance ordering; this BC is the ordering companion to BC-2.02.007
- BC-2.03.001 — depends on: within a single super-step, DI-001 BSP deterministic task-identity sort determines the relative first-appearance order among novel entries
- BC-2.02.009 — related to: `PromoteRetireChannel` provides a promote/retire lifecycle on a separate active-set channel; `LedgerChannel` provides the monotonic accumulator; the two are composable in the same `StateGraph` state

## Architecture Anchors

- `pregolya-graph/src/channels.rs` (`graph::channels`) — `LedgerChannel<T>` struct; the `Vec<T>` accumulator preserves insertion order natively; the reducer appends novel entries at the end using `Vec::push`, guaranteeing first-appearance ordering without a separate sort pass
- ADR-030 §Decision 3 — LedgerChannel semantics: "Reducing with a T whose entry_id() is novel appends it"; append-at-end is the specified operation, encoding first-appearance order

## Story Anchor

S-TBD (assigned at story decomposition — Stage 3)

## VP Anchors

- VP-017

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `LedgerChannel` first-appearance ordering is one of the two semantic axes of `LedgerChannel` (the other being dedup-idempotency, BC-2.02.007); both axes are jointly required by the evidence-accumulation use case in CAP-040 |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism: first-appearance order within a super-step is governed by deterministic task-identity sort; given the same inputs the same order results per {INV-002}) |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), P (property) |
| Module | pregolya-graph |
