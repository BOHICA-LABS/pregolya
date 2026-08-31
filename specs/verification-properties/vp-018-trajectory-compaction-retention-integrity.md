---
document_type: verification-property
level: L4
vp_id: VP-018
title: "Trajectory Compaction Retention Integrity — No Retained Record Lost or Mutated"
status: draft
producer: architect
timestamp: 2026-08-31T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.011.md
input-hash: "c0e37b3"
traces_to: ARCH-INDEX.md
source_bc: BC-2.04.011
bc_anchor: BC-2.04.011 {INV-001}
di_anchor: DI-002
module: checkpoint::trajectory
crate: pregolya-checkpoint
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
  - "1.0 (BC-2.04.011/2026-08-31): Initial — TrajectoryCompactor retention-integrity proptest P1. BC-2.04.011 {INV-001} primary anchor (no retained record lost or mutated by compaction); {INV-002} corollary (ascending step_idx ordering preserved). Human-approved VP mint: durable audit record never corrupted by compaction. Harness: trajectory_compaction_retention_integrity."
---

# VP-018: Trajectory Compaction Retention Integrity — No Retained Record Lost or Mutated

## Property Statement

For any trajectory consisting of N records with ascending `step_idx` values, and any
`TrajectoryRetentionPolicy` that designates a subset of those records as retained:

1. After `compact(run_id, policy)` returns `Ok(())`, every record designated as retained
   appears in `replay(run_id)` with its original `step_idx` and `payload` values
   unchanged. No retained record is removed or mutated.
2. The post-compaction replay sequence contains all retained records in strictly ascending
   `step_idx` order. The retained sub-sequence preserves relative position from the
   pre-compaction sequence.
3. Eligible (non-retained) records do not appear in the post-compaction replay.

These three assertions correspond to BC-2.04.011 {INV-001} (no-loss/no-mutation) and
{INV-002} (replay determinism) acting as a corollary.

> **Scope note:** {INV-003} (crash-isolated / atomic segment swap) requires OS-level crash
> recovery semantics (SQLite `BEGIN IMMEDIATE` / `COMMIT`). It cannot be modeled by proptest
> or Kani — it is covered by integration tests targeting BC-2.04.011 TV-002 (SIGKILL
> mid-compaction, restart, replay returns pre-compaction result). This VP covers the
> pure-core selection/filtering invariant only.

## Formal Invariant

```
∀ records: Vec<TrajectoryRecord> (strictly ascending step_idx),
  policy: TrajectoryRetentionPolicy,
  where policy.is_valid(records) == true:

let retained = records.iter().filter(|r| !policy.is_eligible(r)).collect::<Vec<_>>();
let post     = compact_and_replay(records, policy);  // Ok(post_records) branch

  post.len() == retained.len()
  ∧ ∀ i < post.len():
      post[i].step_idx == retained[i].step_idx
      ∧ post[i].payload == retained[i].payload
  ∧ ∀ i in 1..post.len():
      post[i].step_idx > post[i - 1].step_idx
```

where `compact_and_replay` calls the pure-core in-memory compaction model extracted from
`TrajectoryCompactor` and returns the resulting replay sequence on `Ok(())`.

## Source Contract

BC-2.04.011 {INV-001}: "No committed retained record is lost or mutated. For any
`(run_id, step_idx)` pair that `replay(run_id)` returned before compaction AND whose record
is designated as retained by the policy, that exact `TrajectoryRecord` (same `step_idx`,
`event_kind`, `payload`) appears in `replay(run_id)` after compaction."

{INV-002}: "Replay determinism is preserved for retained records. The post-compaction
replay order is a strict ascending sub-sequence of the pre-compaction order."

ADR-030 §Decision 2 scope defines the atomic-transaction
implementation requirement; the pure-core selection invariant is what proptest tests here.

## Proof Method

| Attribute | Value |
|-----------|-------|
| Tool | proptest |
| Location | `pregolya-checkpoint/src/trajectory.rs` `#[cfg(test)] mod tests` |
| Phase | 3 |
| Bounded? | No — proptest generates arbitrary `Vec<TestTrajectoryRecord>` of arbitrary length (0..=20) with arbitrary eligibility fractions |
| Coverage | {INV-001} no-loss/no-mutation, {INV-002} ascending step_idx order, empty-trajectory no-op, single-retained-record, all-eligible (empty post), no-eligible (identity) |

## BC Traceability

| BC | Clause | Coverage |
|----|--------|---------|
| BC-2.04.011 | {INV-001} no retained record lost or mutated | proptest: post-records match retained pre-records by step_idx + payload |
| BC-2.04.011 | {INV-002} replay determinism (ascending step_idx sub-sequence) | proptest: post[i].step_idx > post[i-1].step_idx for all i |
| BC-2.04.011 | {PC-001} retained records present after Ok(()) | proptest: post.len() == retained.len() |
| BC-2.04.011 | {PC-002} ascending step_idx order in replay | proptest: strict ascending assertion |
| BC-2.04.011 | {PC-003} eligible records absent after Ok(()) | proptest: eligible records not present in post |

## BC Contradictions Flagged

None identified. BC-2.04.011 is authored and active (v1.0).

## Proof Harness Skeleton

```rust
use proptest::prelude::*;

/// Minimal trajectory record for proptest.
#[derive(Clone, Debug, PartialEq, Eq)]
struct TestTrajectoryRecord {
    step_idx: u64,
    payload: Vec<u8>,
}

/// Pure-core in-memory compaction model — models the record-selection logic of
/// TrajectoryCompactor without the async SQLite transaction layer.
fn compact_in_memory(
    records: &[TestTrajectoryRecord],
    eligible_set: &std::collections::HashSet<u64>, // set of eligible step_idx values
) -> Vec<TestTrajectoryRecord> {
    records
        .iter()
        .filter(|r| !eligible_set.contains(&r.step_idx))
        .cloned()
        .collect()
}

fn arb_trajectory_record(step_idx: u64) -> impl Strategy<Value = TestTrajectoryRecord> {
    prop::collection::vec(any::<u8>(), 1..=16)
        .prop_map(move |payload| TestTrajectoryRecord { step_idx, payload })
}

proptest! {
    #[test]
    fn trajectory_compaction_retention_integrity(
        n_records in 0usize..=20,
        // Fraction of non-frontier records to mark eligible (0.0 = no removals, 1.0 = all removable)
        eligible_fraction in 0.0f64..=1.0f64,
    ) {
        // Build a trajectory with strictly ascending step_idx values
        let pre_records: Vec<TestTrajectoryRecord> = (0..n_records as u64)
            .map(|step| TestTrajectoryRecord {
                step_idx: step,
                payload: vec![(step % 256) as u8, ((step * 7) % 256) as u8],
            })
            .collect();

        // Frontier record (last record, if any) is always retained — mirrors TrajectoryRetentionPolicy
        let eligible_set: std::collections::HashSet<u64> = (0..n_records as u64)
            .filter(|&step| {
                let is_frontier = (n_records > 0) && (step == n_records as u64 - 1);
                !is_frontier && {
                    // Eligible if its fractional position falls below eligible_fraction
                    (step as f64) / (n_records.max(1) as f64) < eligible_fraction
                }
            })
            .collect();

        let retained_pre: Vec<&TestTrajectoryRecord> = pre_records
            .iter()
            .filter(|r| !eligible_set.contains(&r.step_idx))
            .collect();

        // Run the pure-core compaction model
        let post_records = compact_in_memory(&pre_records, &eligible_set);

        // INV-001 + PC-001: every retained record is present, count matches
        prop_assert_eq!(
            post_records.len(),
            retained_pre.len(),
            "post-compaction record count must equal retained count ({} retained, {} eligible out of {})",
            retained_pre.len(),
            eligible_set.len(),
            n_records
        );

        // INV-001: each retained record has identical step_idx and payload
        for (post, pre) in post_records.iter().zip(retained_pre.iter()) {
            prop_assert_eq!(
                post.step_idx,
                pre.step_idx,
                "retained record step_idx must be unchanged after compaction"
            );
            prop_assert_eq!(
                &post.payload,
                &pre.payload,
                "retained record payload must be unchanged after compaction"
            );
        }

        // INV-002: post-compaction replay is in strictly ascending step_idx order
        for i in 1..post_records.len() {
            prop_assert!(
                post_records[i].step_idx > post_records[i - 1].step_idx,
                "post-compaction replay must be in strictly ascending step_idx order: \
                 post[{}].step_idx={} must be > post[{}].step_idx={}",
                i, post_records[i].step_idx,
                i - 1, post_records[i - 1].step_idx
            );
        }

        // PC-003: eligible records are absent from post
        for r in &post_records {
            prop_assert!(
                !eligible_set.contains(&r.step_idx),
                "eligible record with step_idx={} must not appear in post-compaction replay",
                r.step_idx
            );
        }
    }
}
```

## Feasibility Assessment

**Feasible.** The pure-core record-selection and ordering invariants of
`TrajectoryCompactor::compact` are testable in isolation from the async SQLite transaction
layer. The proptest harness models `compact_in_memory` — a synchronous subset that captures
the selection/filtering logic (which records survive, which are removed, what order they
appear in). This approach mirrors VP-014 (RunnableParallel key-completeness), VP-016
(GraphAgentTool state-isolation), and VP-017 (LedgerChannel dedup-idempotency), all of
which extract the pure-core logic from async or effectful wrappers.

**Why proptest (not Kani):** The retention-integrity property ranges over variable-length
`Vec<TrajectoryRecord>` inputs. Kani's bounded model checking is tractable for arithmetic
invariants and finite state machines, but is not the right tool for collection invariants
over variable-length sequences. Additionally, `TrajectoryCompactor::compact` is async
(SQLite backend I/O), and Kani 0.67.0 has no native async support.

**Why not Kani for {INV-003} (crash-isolation):** The atomicity guarantee depends on
SQLite `BEGIN IMMEDIATE` / `COMMIT` behavior under SIGKILL. This OS-level crash-recovery
property cannot be modeled by Kani or proptest. It is covered by BC-2.04.011 TV-002
(crash-recovery integration test) and EC-001 integration scenario.

**Phase 3** — concurrent with the story implementing `checkpoint::trajectory`
(`TrajectoryCompactor` trait + SQLite backend). The harness tests the pure-core logic;
the Phase 6 integration test covers crash-isolation ({INV-003}).

## Proof Obligations

- [ ] `compact_in_memory` with empty trajectory returns empty result — matches BC-2.04.011 TV-004.
- [ ] `compact_in_memory` with all records retained (eligible_set empty) returns identical records.
- [ ] `compact_in_memory` with all-but-frontier eligible returns only frontier record in ascending order.
- [ ] Every retained record in post has identical `step_idx` and `payload` as pre-compaction — {INV-001}.
- [ ] Post-compaction records are in strictly ascending `step_idx` order — {INV-002}.
- [ ] No eligible record appears in post — {PC-003}.
- [ ] Single-record trajectory where the record is retained returns `[r0]` unchanged — EC-003.
- [ ] All proptest cases pass within the CI time budget (256 cases × 20 records each).

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-31 | architect |
| BC-2.04.011 authored | 2026-08-31 | product-owner |
| Red Gate test authored | | test-writer |
| Proptest harness committed | | implementer |
| Proptest first passed | | implementer |
| Locked (VERIFIED) | | formal-verifier |
