---
document_type: verification-property
level: L4
vp_id: VP-020
title: "PromoteRetireChannel Idempotency — Dedup-Safe Promote/Retire Active Set"
status: draft
producer: architect
timestamp: 2026-09-01T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.009.md
input-hash: "38a34db"
traces_to: ARCH-INDEX.md
source_bc: BC-2.02.009
bc_anchor: BC-2.02.009 {INV-001} + {INV-002}
di_anchor: DI-001
module: graph::channels
crate: pregolya-graph
tool: proptest
proof_method: proptest
proof_phase: 3
priority: P1
red_gate: false
red_gate_source: null
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v1.0.0-greenfield
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
version: "1.0"
changelog:
  - "1.0 (round-62/F-P2A234-05/2026-09-01): Initial — PromoteRetireChannel idempotency proptest P1. Anchors BC-2.02.009 {INV-001} (no duplicate entry_id in the active set) + {INV-002} (reducer is a pure, deterministic function of its inputs); di_anchor DI-001 (BSP reducer determinism). Structurally analogous to VP-017 (LedgerChannel dedup-idempotency); closes the BC-2.02.009 unit-test-only coverage gap (TST-PROM-01/TST-PROM-02 were unit tests, not registered VPs). Harness `promote_retire_channel_idempotency` folds arbitrary Promote/Retire op sequences via `<PromoteRetireChannel<T> as Channel>::reduce` and asserts (a) no duplicate entry_id, (b) determinism, (c) Promote dedup-idempotency, (d) Retire idempotency, (e) order-sensitivity. Vec/HashSet only — no IndexSet (banned per S-1.28 Rule 2 / Rule 14). VP mint recorded in ADR-030 §Decision 3; VP-INDEX, verification-architecture, and verification-coverage-matrix VP-020 rows added by architect in the same burst."
---

# VP-020: PromoteRetireChannel Idempotency — Dedup-Safe Promote/Retire Active Set

## Property Statement

For any arbitrary sequence of `Promote`/`Retire` operations reduced against a
`PromoteRetireChannel<T>` via `<PromoteRetireChannel<T> as Channel>::reduce` (folded into a
`Vec<T>` active set), the resulting active set satisfies:

1. **No duplicate `entry_id`** — the active set never contains two entries with the same
   `entry_id()`. **({INV-001})**
2. **Determinism** — the reducer is a pure function of its inputs: folding the same op sequence
   (in task-identity order) over the same starting accumulator always yields an identical
   `Vec<T>`. **({INV-002})**
3. **Promote is dedup-idempotent** — re-`Promote` of an `entry_id` already present in the active
   set is a no-op; the active set is unchanged (no second copy is created). **({INV-001}; BC-2.02.009 {PC-002})**
4. **Retire is idempotent** — `Retire` of an `entry_id` that is absent from the active set is a
   no-op; the active set is unchanged and no error is raised. **(BC-2.02.009 {PC-004})**
5. **Order-sensitivity is correct** — `Promote(a)` then `Retire(a.entry_id())` leaves `a` absent;
   `Retire(a.entry_id())` then `Promote(a)` leaves `a` present. The result depends on operation
   order, and that dependence is deterministic per DI-001 task-identity ordering. **(BC-2.02.009 EC-003 / EC-004)**

## Formal Invariant

```
∀ ops: Vec<PromoteRetireOp<T>>,
  let active: Vec<T> =
    ops.iter().fold(Vec::new(), |acc, op| PromoteRetireChannel::reduce(acc, op.clone())):

  // (a) {INV-001}: no duplicate entry_id in the active set
  active.iter().map(|e| e.entry_id()).collect::<HashSet<_>>().len() == active.len()

  // (b) {INV-002}: determinism — the reducer is a pure function of its inputs;
  //     folding the same op sequence again yields an identical Vec
  ∧ ops.iter().fold(Vec::new(), |acc, op| PromoteRetireChannel::reduce(acc, op.clone())) == active

  // (c) Promote is dedup-idempotent: re-Promote of a present entry_id is a no-op
  ∧ ∀ e: T where active.iter().any(|x| x.entry_id() == e.entry_id()):
      PromoteRetireChannel::reduce(active.clone(), PromoteRetireOp::Promote(e)) == active

  // (d) Retire is idempotent: Retire of an absent entry_id is a no-op
  ∧ ∀ id: String where !active.iter().any(|x| x.entry_id() == id):
      PromoteRetireChannel::reduce(active.clone(), PromoteRetireOp::Retire(id)) == active

  // (e) order-sensitivity (deterministic per DI-001 task-identity order)
  ∧ reduce(reduce(Vec::new(), Promote(a)), Retire(a.entry_id().to_owned())) == Vec::new()  // absent
  ∧ reduce(reduce(Vec::new(), Retire(a.entry_id().to_owned())), Promote(a)) == vec![a]     // present
```

where:
- `PromoteRetireChannel::reduce` is a pure function
  `fn reduce(acc: Vec<T>, update: PromoteRetireOp<T>) -> Vec<T>` — no mutable state, no
  constructor, no `.value()` accessor. The `Vec<T>` accumulator is threaded through `fold` and is
  the direct output of the harness.
- `PromoteRetireOp<T>` is a `#[non_exhaustive]` enum with variants `Promote(T)` and
  `Retire(String)` (the `String` is the `entry_id` to remove).
- `T: LedgerEntry` (the supertrait already requires `Clone + Serialize + DeserializeOwned +
  Send + Sync + 'static`; use-site repetition of those bounds is omitted).

## Source Contract

BC-2.02.009 {INV-001}: "The active set `Vec<T>` contains no duplicate `entry_id` values at any
time. `Promote` is idempotent (does not add a second copy); `Retire` removes exactly one entry."

BC-2.02.009 {INV-002}: "The reducer is a pure function of its inputs: given the same initial
active set and the same sequence of `PromoteRetireOp` values (in task-identity order), the
resulting active set is always identical."

BC-2.02.009 {PC-002}/{PC-004} define the per-operation idempotency (idempotent Promote /
idempotent Retire); EC-003/EC-004 define the order-sensitivity of Promote-then-Retire versus
Retire-then-Promote. ADR-030 §Decision 3 defines the `Channel` reducer contract
(`Accumulator = Vec<T>`, `Update = PromoteRetireOp<T>`, pure infallible `reduce`).

## Proof Method

| Attribute | Value |
|-----------|-------|
| Tool | proptest |
| Location | `pregolya-graph/src/channels/promote_retire.rs` `#[cfg(test)] mod tests` |
| Phase | 3 |
| Bounded? | No — proptest generates arbitrary `Vec<PromoteRetireOp<T>>` of arbitrary length |
| Coverage | All five properties (no-duplicate, determinism, Promote dedup-idempotency, Retire idempotency, order-sensitivity) |

## BC Traceability

| BC | Clause | Coverage |
|----|--------|---------|
| BC-2.02.009 | {INV-001} no duplicate `entry_id`; `Promote` dedup-idempotent | proptest: no-duplicate assertion (Property a), Promote dedup-idempotency (Property c) |
| BC-2.02.009 | {INV-002} reducer is a pure, deterministic function of its inputs | proptest: fold-twice determinism assertion (Property b) |
| BC-2.02.009 | {PC-004} idempotent `Retire` of an absent `entry_id` | proptest: Retire-absent no-op (Property d) |
| BC-2.02.009 | EC-003 / EC-004 order-sensitivity (Promote-then-Retire vs Retire-then-Promote) | proptest: deterministic order-sensitivity point cases (Property e) |

## BC Contradictions Flagged

None identified. BC-2.02.009 is active; {INV-001} and {INV-002} are the direct anchors, and
DI-001 (BSP reducer determinism) is the adjudicated domain-invariant anchor per ADR-030 §VP.

## Proof Harness Skeleton

```rust
use proptest::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
// PromoteRetireChannel, PromoteRetireOp, Channel, and LedgerEntry are in scope from
// graph::channels (pregolya-graph).

/// A minimal test entry type implementing LedgerEntry.
/// Serialize + Deserialize required by the LedgerEntry supertrait
/// (Clone + Serialize + DeserializeOwned + Send + Sync + 'static).
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
struct TestEntry {
    id: String,
    value: u64,
}

impl LedgerEntry for TestEntry {
    fn entry_id(&self) -> &str {
        &self.id
    }
}

/// Arbitrary Promote/Retire op over a small entry_id alphabet to force frequent
/// dedup / idempotent-retire collisions.
fn arb_op() -> impl Strategy<Value = PromoteRetireOp<TestEntry>> {
    prop_oneof![
        ("[a-e]", any::<u64>())
            .prop_map(|(id, value)| PromoteRetireOp::Promote(TestEntry { id, value })),
        "[a-e]".prop_map(PromoteRetireOp::Retire),
    ]
}

proptest! {
    #[test]
    fn promote_retire_channel_idempotency(
        ops in prop::collection::vec(arb_op(), 0..40)
    ) {
        // Pure fold — no mutable channel state; reduce is the Channel associated function.
        let active: Vec<TestEntry> = ops.iter().fold(Vec::new(), |acc, op| {
            <PromoteRetireChannel<TestEntry> as Channel>::reduce(acc, op.clone())
        });

        // (a) {INV-001}: no duplicate entry_id.
        let distinct: HashSet<&str> = active.iter().map(|e| e.entry_id()).collect();
        prop_assert_eq!(distinct.len(), active.len(),
            "active set must contain no duplicate entry_id");

        // (b) {INV-002}: determinism — the same op sequence folds to an identical Vec.
        let active2: Vec<TestEntry> = ops.iter().fold(Vec::new(), |acc, op| {
            <PromoteRetireChannel<TestEntry> as Channel>::reduce(acc, op.clone())
        });
        prop_assert_eq!(&active, &active2,
            "reduce is a pure function: identical op sequence must yield an identical active set");

        // Independent oracle: replay ops tracking active ids in first-Promote order with a Vec
        // (membership via linear scan; Retire removes by entry_id). No IndexSet.
        let mut oracle_ids: Vec<String> = Vec::new();
        for op in &ops {
            match op {
                PromoteRetireOp::Promote(e) => {
                    if !oracle_ids.iter().any(|id| id == e.entry_id()) {
                        oracle_ids.push(e.entry_id().to_owned());
                    }
                }
                PromoteRetireOp::Retire(id) => {
                    oracle_ids.retain(|existing| existing != id);
                }
                _ => {} // #[non_exhaustive] wildcard
            }
        }
        let active_ids: Vec<&str> = active.iter().map(|e| e.entry_id()).collect();
        prop_assert_eq!(
            active_ids,
            oracle_ids.iter().map(|s| s.as_str()).collect::<Vec<_>>(),
            "active-set membership/order must match the independent Promote/Retire oracle"
        );
    }

    // (c) Promote is dedup-idempotent: re-Promote of a present entry_id is a no-op.
    #[test]
    fn promote_dedup_idempotent(
        entry in ("[a-e]", any::<u64>()).prop_map(|(id, value)| TestEntry { id, value })
    ) {
        let once = <PromoteRetireChannel<TestEntry> as Channel>::reduce(
            Vec::new(), PromoteRetireOp::Promote(entry.clone()));
        let twice = <PromoteRetireChannel<TestEntry> as Channel>::reduce(
            once.clone(), PromoteRetireOp::Promote(entry.clone()));
        prop_assert_eq!(once, twice, "re-Promote of an active entry_id is a no-op ({PC-002})");
    }

    // (d) Retire is idempotent: Retire of an absent entry_id is a no-op.
    #[test]
    fn retire_absent_idempotent(id in "[a-e]") {
        let empty: Vec<TestEntry> = Vec::new();
        let after = <PromoteRetireChannel<TestEntry> as Channel>::reduce(
            empty.clone(), PromoteRetireOp::Retire(id));
        prop_assert_eq!(empty, after, "Retire of an absent entry_id is a no-op ({PC-004})");
    }
}

// (e) order-sensitivity — deterministic point cases.
#[test]
fn order_sensitivity_promote_then_retire_is_absent() {
    let e = TestEntry { id: "a".to_owned(), value: 1 };
    let ops = [
        PromoteRetireOp::Promote(e.clone()),
        PromoteRetireOp::Retire("a".to_owned()),
    ];
    let active = ops.iter().fold(Vec::new(), |acc, op| {
        <PromoteRetireChannel<TestEntry> as Channel>::reduce(acc, op.clone())
    });
    assert!(active.is_empty(), "Promote(a) then Retire(a) → a absent (EC-003)");
}

#[test]
fn order_sensitivity_retire_then_promote_is_present() {
    let e = TestEntry { id: "a".to_owned(), value: 1 };
    let ops = [
        PromoteRetireOp::Retire("a".to_owned()),
        PromoteRetireOp::Promote(e.clone()),
    ];
    let active = ops.iter().fold(Vec::new(), |acc, op| {
        <PromoteRetireChannel<TestEntry> as Channel>::reduce(acc, op.clone())
    });
    assert_eq!(active, vec![e], "Retire(a) then Promote(a) → a present (EC-004)");
}
```

## Feasibility Assessment

**Feasible.** `<PromoteRetireChannel<T> as Channel>::reduce` is a pure-core function (takes
`Vec<T>` + `PromoteRetireOp<T>`, returns `Vec<T>`) with no I/O and no async. The invariants are
structurally simple: a `Vec` linear scan over the accumulator's existing `entry_id` values
decides whether a `Promote` is novel (append) or already present (no-op), and a `Retire` removes
the matching entry by `entry_id` (no-op if absent) — the mandated implementation per S-1.28
Rule 2 / Rule 14. The harness oracle tracks active ids with a `Vec` (membership by linear scan)
and distinctness with a `HashSet`, matching §Formal Invariant; no order-preserving hash-set
structure (`IndexSet`) is used. proptest's `Vec` strategy with a small-alphabet id generator
forces frequent dedup / idempotent-retire / order-swap events, exercising all five properties
with high probability. No Kani constraint applies (this is a proptest target by design; the
op-sequence space is unbounded — see ADR-030 §Rationale). Structurally analogous to VP-017.

**Phase 3** (concurrent with the story that implements `graph::channels`
`PromoteRetireChannel` — S-1.28).

## Proof Obligations

- [ ] Fold over empty input (`ops = vec![]`) produces an empty `Vec<T>` — zero-op identity.
- [ ] Active set contains no duplicate `entry_id` for any generated op sequence ({INV-001}).
- [ ] Determinism: folding the same op sequence twice yields byte-identical `Vec<T>` ({INV-002}).
- [ ] `Promote` of an `entry_id` already present is a no-op; the active set is unchanged ({PC-002}).
- [ ] `Retire` of an absent `entry_id` is a no-op; the active set is unchanged, no error ({PC-004}).
- [ ] `Promote(a)` then `Retire(a.entry_id())` leaves `a` absent (EC-003).
- [ ] `Retire(a.entry_id())` then `Promote(a)` leaves `a` present (EC-004).
- [ ] Active-set membership/order matches the independent `Vec`/`HashSet` oracle (non-tautological).
- [ ] `TestEntry` round-trips through serde (Serialize + Deserialize derives satisfy the `LedgerEntry` supertrait).
- [ ] All proptest cases pass within the CI time budget.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-09-01 | architect |
| BC-2.02.009 authored | 2026-08-31 | product-owner |
| Red Gate test authored | | test-writer |
| Proptest harness committed | | implementer |
| Proptest first passed | | implementer |
| Locked (VERIFIED) | | formal-verifier |
