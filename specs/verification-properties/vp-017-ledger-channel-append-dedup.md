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
input-hash: "42892e9"
traces_to: ARCH-INDEX.md
source_bc: BC-2.02.007
bc_anchor: BC-2.02.007 + BC-2.02.008
di_anchor: DI-014
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
version: "1.1"
changelog:
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
∀ entries: Vec<T>, let ledger = reduce_all(LedgerChannel::new(), entries):
  ledger.len() == entries.iter().map(|e| e.entry_id()).collect::<IndexSet>().len()
  ∧ ∀ i < ledger.len():
      ledger[i].entry_id() == first_occurrence_id(entries, i)
```

where `first_occurrence_id(entries, i)` is the `entry_id` of the `i`-th first-appearance
entry in `entries`.

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

/// A minimal test entry type implementing LedgerEntry.
#[derive(Clone, Debug, PartialEq)]
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
        let mut channel = LedgerChannel::<TestEntry>::new();
        for entry in &entries {
            channel.reduce(entry.clone());
        }

        let ledger = channel.value();

        // 1. Length equals the count of distinct entry_ids
        let distinct_ids: IndexSet<&str> = entries.iter().map(|e| e.entry_id()).collect();
        prop_assert_eq!(ledger.len(), distinct_ids.len(),
            "LedgerChannel length must equal distinct entry_id count");

        // 2. Every entry_id in the ledger is present exactly once
        let ledger_ids: Vec<&str> = ledger.iter().map(|e| e.entry_id()).collect();
        prop_assert_eq!(ledger_ids.len(), ledger_ids.iter().collect::<HashSet<_>>().len(),
            "LedgerChannel must not contain duplicate entry_ids");

        // 3. Order matches first-appearance order in the input sequence
        let mut seen = IndexSet::<String>::new();
        let expected_order: Vec<String> = entries.iter()
            .filter_map(|e| {
                if seen.insert(e.entry_id().to_owned()) { Some(e.entry_id().to_owned()) }
                else { None }
            })
            .collect();
        prop_assert_eq!(ledger_ids, expected_order.iter().map(|s| s.as_str()).collect::<Vec<_>>(),
            "LedgerChannel must maintain first-appearance order");
    }
}
```

## Feasibility Assessment

**Feasible.** `LedgerChannel::reduce` is a pure-core function (takes `Vec<T>`, returns
`Vec<T>`) with no I/O or async. The dedup invariant is structurally simple: an internal
`IndexSet` (or equivalent) tracks seen IDs. proptest's `Vec` strategy with a small-alphabet
ID generator will force frequent collision/dedup events, exercising all three invariant
branches with high probability. No Kani constraint applies (this is a proptest target by
design — see ADR-030 §Rationale).

**Phase 3** (concurrent with the story that implements `graph::channels` ledger types).

## Proof Obligations

- [ ] `LedgerChannel::new()` produces an empty ledger.
- [ ] `reduce(novel_entry)` appends; `len` increments.
- [ ] `reduce(seen_entry)` is a no-op; `len` unchanged; existing entries unchanged.
- [ ] Final ledger matches first-appearance ordering from input sequence.
- [ ] Zero-entry input produces empty ledger.
- [ ] Single-entry input produces single-element ledger.
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
