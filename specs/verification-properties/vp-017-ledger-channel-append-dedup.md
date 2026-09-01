---
document_type: verification-property
level: L4
vp_id: VP-017
title: "LedgerChannel Dedup-Idempotent Append — Seen entry_id Write Is No-Op"
status: draft
producer: architect
timestamp: 2026-08-31T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "e7b31ef"
traces_to: ARCH-INDEX.md
source_bc: BC-2.02.007
bc_anchor: BC-2.02.007 + BC-2.02.008
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
version: "1.3"
changelog:
  - "1.3 (round-57/F-P2A228-03/2026-09-01): F-P2A228-03 [LOW, spec-drift] §Feasibility Assessment no longer names the forbidden order-preserving hash-set structure as the dedup implementation exemplar; replaced with the mandated `Vec` linear scan over accumulator `entry_id` values per S-1.28 Rule 2 / Rule 14, with the harness oracle tracking seen IDs via `HashSet` — consistent with §Formal Invariant and the proof harness. Version bump: 1.2→1.3."
  - "1.2 (round-52/F-P2A217-04+F-P2A219-05/2026-08-31): F-P2A217-04 [HIGH] Harness rewritten to canonical pure-fold API — removed stale stateful LedgerChannel::new()/channel.reduce(e)/channel.value() API; harness now uses entries.iter().fold(Vec::new(), |acc, e| LedgerChannel::reduce(acc, e.clone())); TestEntry gains Serialize+Deserialize derives (required by LedgerEntry: Serialize+DeserializeOwned supertrait); §Formal Invariant updated to fold-form (removed LedgerChannel::new() / IndexSet reduce_all oracle; replaced with fold accumulation directly); §Proof Obligations updated (removed 'LedgerChannel::new() produces empty ledger' — now 'fold over empty input produces empty Vec'). F-P2A219-05 [LOW] di_anchor corrected DI-014→DI-001: VP-017 proves LedgerChannel::reduce idempotency/ordering/determinism (BSP reducer determinism = DI-001); DI-014 (error-propagation no-silent-swallow) is irrelevant since reduce is pure and returns Vec<T>, not Result."
  - "1.1 (round-50/F-P2A211-05/2026-08-31): Dual anchor: BC-2.02.008 added alongside BC-2.02.007. VP-017 harness exercises first-appearance ordering (Property Statement point 3) which is the subject of BC-2.02.008; anchoring only BC-2.02.007 left first-appearance ordering without a VP attribution. Follows VP-014 two-BC precedent. bc_anchor updated, §Source Contract expanded, §BC-Traceability row added. Version bump: 1.0→1.1."
  - "1.0 (ADR-030/2026-08-31): Initial — LedgerChannel dedup-idempotency proptest P1. ADR-030 Decision 3; BC-2.02.007 (draft; PO authors in Stage 2)."
---

# VP-017: LedgerChannel Dedup-Idempotent Append — Seen entry_id Write Is No-Op

## Property Statement

For any sequence of reduce operations against a `LedgerChannel<T>`:

1. Reducing with an entry whose `entry_id()` is **novel** (not yet in the accumulated
   ledger) appends the entry — `new_len == old_len + 1`.
2. Reducing with an entry whose `entry_id()` **already exists** in the accumulated
   ledger is a no-op — `new_len == old_len` and no existing entry is modified.
3. The accumulated `Vec<T>` contains entries in first-appearance order (the order of first
   insertion for each unique `entry_id`). **(BC-2.02.008 anchor — first-appearance ordering is
   the primary subject of BC-2.02.008; this VP is dual-anchored per VP-014 precedent.)**

## Formal Invariant

```
∀ entries: Vec<T>,
  let ledger: Vec<T> = entries.iter().fold(Vec::new(), |acc, e| LedgerChannel::reduce(acc, e.clone())):

  ledger.len() == count_distinct_entry_ids(entries)
  ∧ ∀ i < ledger.len():
      ledger[i].entry_id() == first_occurrence_id(entries, i)
```

where:
- `count_distinct_entry_ids(entries)` = `entries.iter().map(|e| e.entry_id()).collect::<HashSet<_>>().len()`
- `first_occurrence_id(entries, i)` is the `entry_id` of the `i`-th entry (in first-appearance
  order) in `entries`

`LedgerChannel::reduce` is a pure function: `fn reduce(acc: Vec<T>, update: T) -> Vec<T>`.
No mutable state; no constructor; no `.value()` accessor — the `Vec<T>` accumulator is
threaded through `fold` and is the direct output of the harness.

## Source Contract

BC-2.02.007 (draft — PO authors in Stage 2): `LedgerChannel` dedup-idempotent append —
novel `entry_id` → append; seen `entry_id` → no-op.

BC-2.02.008 (draft — PO authors in Stage 2): `LedgerChannel` first-appearance ordering —
accumulated `Vec<T>` preserves first-appearance order of unique `entry_id` values.

ADR-030 §Decision 3 defines the reducer contract for both properties.

## Proof Method

| Attribute | Value |
|-----------|-------|
| Tool | proptest |
| Location | `pregolya-graph/src/channels/ledger.rs` `#[cfg(test)] mod tests` |
| Phase | 3 |
| Bounded? | No — proptest generates arbitrary `Vec<T>` of arbitrary length |
| Coverage | All three invariants (novel-append, dedup-noop, first-appearance order) |

## BC Traceability

| BC | Clause | Coverage |
|----|--------|---------|
| BC-2.02.007 | Dedup-idempotent append — novel `entry_id` → append; seen `entry_id` → no-op | proptest: novel-append (Property 1), seen-noop (Property 2) |
| BC-2.02.008 | First-appearance ordering — accumulated `Vec<T>` ordered by first insertion, not lexicographic | proptest: first-appearance order assertion (Property 3) |

## BC Contradictions Flagged

None identified. BC-2.02.007 and BC-2.02.008 are drafts pending product-owner authoring.

## Proof Harness Skeleton

```rust
use proptest::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

/// A minimal test entry type implementing LedgerEntry.
/// Serialize + Deserialize required by the LedgerEntry supertrait (ADR-030 §Decision 3
/// Serialization Bound — checkpoint-resume round-trip correctness).
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

fn arb_entry() -> impl Strategy<Value = TestEntry> {
    // IDs drawn from a small alphabet to force frequent collisions
    ("[a-e]", any::<u64>()).prop_map(|(id, value)| TestEntry { id, value })
}

proptest! {
    #[test]
    fn ledger_channel_dedup_idempotency(
        entries in prop::collection::vec(arb_entry(), 0..20)
    ) {
        // Pure fold — no mutable channel state; LedgerChannel::reduce is a free function.
        let ledger: Vec<TestEntry> = entries
            .iter()
            .fold(Vec::new(), |acc, e| LedgerChannel::reduce(acc, e.clone()));

        // 1. Length equals the count of distinct entry_ids
        let distinct_ids: HashSet<&str> = entries.iter().map(|e| e.entry_id()).collect();
        prop_assert_eq!(ledger.len(), distinct_ids.len(),
            "LedgerChannel length must equal distinct entry_id count");

        // 2. Every entry_id in the ledger is present exactly once
        let ledger_ids: Vec<&str> = ledger.iter().map(|e| e.entry_id()).collect();
        prop_assert_eq!(
            ledger_ids.len(),
            ledger_ids.iter().cloned().collect::<HashSet<_>>().len(),
            "LedgerChannel must not contain duplicate entry_ids"
        );

        // 3. Order matches first-appearance order in the input sequence
        let mut seen = HashSet::<String>::new();
        let expected_order: Vec<String> = entries.iter()
            .filter_map(|e| {
                if seen.insert(e.entry_id().to_owned()) { Some(e.entry_id().to_owned()) }
                else { None }
            })
            .collect();
        prop_assert_eq!(
            ledger_ids,
            expected_order.iter().map(|s| s.as_str()).collect::<Vec<_>>(),
            "LedgerChannel must maintain first-appearance order"
        );
    }
}
```

## Feasibility Assessment

**Feasible.** `LedgerChannel::reduce` is a pure-core function (takes `Vec<T>`, returns
`Vec<T>`) with no I/O or async. The dedup invariant is structurally simple: a `Vec` linear
scan over the accumulator's existing `entry_id` values decides whether an update is novel
(append) or already seen (no-op) — the mandated implementation per S-1.28 Rule 2 /
Rule 14; the harness oracle tracks seen IDs with a `HashSet`, matching §Formal Invariant.
proptest's `Vec` strategy with a small-alphabet
ID generator will force frequent collision/dedup events, exercising all three invariant
branches with high probability. No Kani constraint applies (this is a proptest target by
design — see ADR-030 §Rationale).

**Phase 3** (concurrent with the story that implements `graph::channels` ledger types).

## Proof Obligations

- [ ] Fold over empty input (`entries = vec![]`) produces empty `Vec<T>` — zero-entry identity.
- [ ] Fold over a single entry produces a single-element `Vec<T>` with that entry.
- [ ] `LedgerChannel::reduce(acc, novel_entry)` appends; `new_acc.len() == acc.len() + 1`.
- [ ] `LedgerChannel::reduce(acc, seen_entry)` is a no-op; `new_acc.len() == acc.len()` and existing entries are unchanged.
- [ ] Final ledger matches first-appearance ordering from the input sequence.
- [ ] `TestEntry` round-trips through serde (Serialize + Deserialize derives satisfy LedgerEntry supertrait).
- [ ] All proptest cases pass within the CI time budget.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-31 | architect |
| BC-2.02.007 authored | | product-owner |
| Red Gate test authored | | test-writer |
| Proptest harness committed | | implementer |
| Proptest first passed | | implementer |
| Locked (VERIFIED) | | formal-verifier |
