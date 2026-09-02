---
document_type: verification-property
level: L4
vp_id: VP-019
title: "Trajectory Compaction Crash Isolation — SQLite Atomicity Under SIGKILL"
status: draft
producer: architect
timestamp: 2026-08-31T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.011.md
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "efe1832"
traces_to: ARCH-INDEX.md
source_bc: BC-2.04.011
bc_anchor: BC-2.04.011 {INV-003}
di_anchor: DI-002
module: checkpoint::trajectory
crate: pregolya-checkpoint
tool: integration
proof_method: integration
proof_phase: 6
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
version: "1.4"
changelog:
  - "1.4 (round-62/F-P2A234-01/2026-09-01): Compaction model rewritten from the staging-table single-atomic-swap (FOUR crash points) to the per-run single-transaction DELETE (TWO crash points) per ADR-030 §Compaction Atomicity Decision (F-P2A234-01 redesign; the staging-table swap silently destroyed all other run_ids' records). New crash_point set: {before_commit, after_commit}. §Property Statement, §Formal Invariant, §Source Contract, §Proof Method, §BC Traceability, §Proof Harness Skeleton, §Feasibility Assessment, and §Proof Obligations rewritten for the two-case matrix. Added per-run scope-safety invariant clause and harness witness (a second run_id's records untouched before OR after commit — supports the F-P2A234-01 scope-safety property; DELETE WHERE run_id = :run_id predicate). §BC Contradictions Flagged kept RESOLVED: BC-2.04.011 was reconciled in the same round-62 burst — its {INV-003}, §VP-table VP-019 row, §Description, §Architecture Anchors, and §Related BCs now describe the two-crash-point per-run DELETE model and cite VP-019's two-crash-point matrix, so BC and VP agree; no open reconciliation action remains. input-hash refreshed (ADR-030 advanced under F-P2A234-01). VP does not edit BC files."
  - "1.3 (round-57/F-P2A227-03/2026-09-01): §BC Contradictions Flagged updated from OPEN to RESOLVED. The prior text carried a stale present-tense claim that BC-2.04.011 {INV-003} and its §Verification Properties VP-019 row 'currently describe a three crash-point matrix (before-begin, mid-txn, after-sync) ... flagged for product-owner reconciliation and routed via the orchestrator/state-manager'. That claim is now false and the open action is complete: BC-2.04.011 adopted the four-crash-point matrix in its round-53-corrective revision — its live {INV-003} and its §Verification Properties VP-019 row both now read four crash points (before-build-begins, mid-build (staging partially filled before swap), mid-swap-transaction (after BEGIN IMMEDIATE, before COMMIT), after-swap-commit). Section rewritten to record the contradiction as resolved (BC and this VP now agree on the four-point matrix; no open reconciliation action remains). No property, invariant, formal-invariant, harness, or proof-obligation change; VP does not edit BC files."
  - "1.2 (round-53/F-P2A221-01/2026-08-31): Crash matrix extended from three to FOUR crash points under the staging-table single-atomic-swap compaction model (ADR-030 §Compaction Atomicity Decision). Under this model, `compact` builds a shadow `trajectory_records_staging` table in bounded per-batch transactions (default 1,000 records per BEGIN IMMEDIATE/COMMIT on the staging table) while `trajectory_records` is untouched, then performs a single BEGIN IMMEDIATE; DROP TABLE trajectory_records; ALTER TABLE trajectory_records_staging RENAME TO trajectory_records; COMMIT swap — the sole reader-visible atomicity boundary. New crash point (case 2) added: mid-build (staging partially filled, before swap begins) → pre-compaction state intact, stale `trajectory_records_staging` dropped on recovery (implementation drops any stale staging table at the start of the next `compact` entry before a new build). §Property Statement, §Formal Invariant, §Source Contract, §Proof Method, §BC Traceability, §Proof Harness Skeleton, §Feasibility Assessment, and §Proof Obligations rewritten for four cases + recovery-time stale-staging cleanup. Reader-visible atomicity kept coherent with BC-2.04.011 {PC-004}/{INV-003}: `replay` always observes complete pre-compaction OR complete post-compaction state, never a partial. ADR-030 §Compaction Atomicity Decision added to inputs; input-hash refreshed. BC-2.04.011 {INV-003}/§VP-table three-point wording predates ADR-030 §Compaction Atomicity Decision and is flagged for product-owner reconciliation in §BC Contradictions Flagged (surface, not silently diverge)."
  - "1.1 (round-52/F-P2A217-03/2026-08-31): WAL-correct language applied throughout. SQLite topology is WAL mode (ADR-030 §SQLite Topology Decision). Scenario 2 (mid-transaction crash): 'SQLite rollback journal restores pre-compaction state on restart' → 'uncommitted WAL frames after the last commit marker are discarded on the next database open; pre-compaction state is fully recovered'. §Property Statement introductory sentence corrected similarly. Integration test assert message updated. §Proof Obligations updated. Rollback journal is not used in WAL mode; the correct recovery mechanism is WAL frame discard on next open."
  - "1.0 (round-50/F-P2A209-03/2026-08-31): Initial — trajectory compaction crash-isolation integration P1. BC-2.04.011 {INV-003} anchor: SQLite BEGIN IMMEDIATE/COMMIT atomicity under SIGKILL. Scoped from VP-018: VP-018 proptest covers pure-core selection/filtering ({INV-001}/{INV-002}); VP-019 covers OS-level crash-recovery semantics that proptest and Kani cannot model. Human-approved VP mint: crash-isolation test of durable audit trajectory compaction is a production-grade correctness obligation. Arithmetic: total 19→20 (P0 6 unchanged, P1 13→14); integration 2→3."
---

# VP-019: Trajectory Compaction Crash Isolation — SQLite Atomicity Under SIGKILL

## Property Statement

For any `TrajectoryCompactor::compact(run_id, policy)` call that is interrupted by SIGKILL at
either of **two crash points** across the per-run single-transaction DELETE compaction
(ADR-030 §Compaction Atomicity Decision, F-P2A234-01 redesign) — before the `COMMIT` of the
DELETE transaction is durably recorded, or after that `COMMIT` returns — a subsequent
`TrajectoryReader::replay(run_id)` call after process restart returns either the **complete
pre-compaction trajectory record sequence** (crash before commit) or the **complete
post-compaction retained sequence** (crash after commit), with no partial compaction, no record
loss, and no record mutation.

The property follows from the per-run single-transaction DELETE model:

- Compaction is a **single-phase** operation scoped to the target `run_id`: `BEGIN IMMEDIATE;
  DELETE FROM trajectory_records WHERE run_id = :run_id AND step_idx < :retention_frontier AND
  step_idx NOT IN (:promoted_step_idxs); COMMIT`. The single `BEGIN IMMEDIATE / COMMIT`
  transaction is the **sole reader-visible atomicity boundary**.
- **Per-run scope-safety:** the DELETE `WHERE` clause filters on `run_id = :run_id`, so only
  records belonging to the target run are ever read, modified, or deleted. Records belonging to
  every other `run_id` are structurally untouched — enforced by the query predicate, not by
  documentation convention. This supports the F-P2A234-01 scope-safety property: a compaction of
  `run_id_A` can never destroy `run_id_B`'s trajectory.
- **WAL rollback on crash-before-commit:** in WAL mode, if the process is killed after
  `BEGIN IMMEDIATE` but before the `COMMIT` marker is durably recorded, the uncommitted WAL frames
  of the DELETE transaction are discarded by SQLite on the next database open (no rollback
  journal — WAL mode uses frame discard), leaving `trajectory_records` in its pre-compaction
  state.
- **No stale-artifact cleanup:** no staging table is created; there is no
  `trajectory_records_staging` to detect or drop on recovery. The redesign eliminates the two
  intermediate crash points (mid-build, mid-swap) that existed under the prior staging-table
  single-atomic-swap model.

This yields reader-visible atomicity coherent with BC-2.04.011 {PC-004}/{INV-003}: `replay`
always observes either the complete pre-compaction state or the complete post-compaction state,
and never a partial compaction, regardless of when the SIGKILL lands.

Two crash scenarios (ADR-030 §Compaction Atomicity Decision two-point matrix):

1. **Before commit:** SIGKILL during DELETE execution, before the `COMMIT` WAL record is durably
   written. In WAL mode the uncommitted DELETE-transaction WAL frames are discarded on the next
   database open; `trajectory_records` is fully intact at the pre-compaction state.
   `replay(run_id)` returns the complete pre-compaction record sequence — the same result as if
   `compact` had never run.
2. **After commit:** SIGKILL after the `COMMIT` WAL record is durably flushed. Eligible records
   for `run_id` have been removed; all retained records for `run_id` — and all records for every
   other `run_id` — are present. `replay(run_id)` returns the complete post-compaction retained
   sequence, which is the correct outcome.

> **Scope note:** The pure-core record-selection invariant ({INV-001}/{INV-002}) is covered
> by VP-018 proptest. VP-019 covers {INV-003} exclusively — the OS-level crash-recovery
> property that proptest and Kani cannot model (no SIGKILL injection, no SQLite WAL
> frame-discard semantics).

## Formal Invariant

```
∀ run_id: Uuid,
  pre_records: Vec<TrajectoryRecord> (committed to storage via put_record),
  policy: TrajectoryRetentionPolicy,
  crash_point ∈ {before_commit, after_commit}:

  let expected = match crash_point {
    before_commit => pre_records,                        // uncommitted WAL frames discarded
    after_commit  => retained_set(pre_records, policy),  // DELETE committed; correct
  };
  process_killed_at(crash_point, compact(run_id, policy))
    → restart_and_replay(run_id) == expected             // TrajectoryReader::replay after restart

  where retained_set(records, policy) =
    records.filter(|r| r.step_idx >= policy.retention_frontier
                       || policy.promoted.contains(&r.step_idx))

  // Reader-visible atomicity holds in every case:
  ∀ crash_point: restart_and_replay(run_id) ∈ {pre_records, retained_set(pre_records, policy)}
    // never a partial compaction — the single BEGIN IMMEDIATE/COMMIT DELETE is the
    // sole reader-visible atomicity boundary

  // Per-run scope-safety (F-P2A234-01):
  ∀ other_run_id ≠ run_id, ∀ crash_point:
    restart_and_replay(other_run_id) == pre_records_of(other_run_id)
    // records of every other run_id are structurally untouched by compact(run_id, ...)
    // — the DELETE WHERE run_id = :run_id predicate — before OR after commit
```

## Source Contract

BC-2.04.011 {INV-003}: "Compaction is crash-isolated. A SIGKILL delivered at any point
during `compact(run_id, policy)` leaves `replay(run_id)` in a consistent state: either the
complete pre-compaction replay (if the transaction did not commit) or the complete
post-compaction replay (if the transaction committed). No partial compaction state is
observable." BC-2.04.011 {PC-004} states the same reader-visible whole-operation atomicity.

ADR-030 §Compaction Atomicity Decision — Per-Run Single-Transaction DELETE (F-P2A234-01
redesign) — mandates the topology that realizes this invariant: compaction is a single-phase
operation `BEGIN IMMEDIATE; DELETE FROM trajectory_records WHERE run_id = :run_id AND step_idx <
:retention_frontier AND step_idx NOT IN (:promoted_step_idxs); COMMIT`. The single
`BEGIN IMMEDIATE / COMMIT` transaction is the sole reader-visible atomicity boundary. Per that
decision's crash semantics: crash before `COMMIT` leaves `trajectory_records` fully intact
(uncommitted WAL frames discarded on the next database open); crash after `COMMIT` yields the
post-compaction retained state. The DELETE `WHERE run_id = :run_id` predicate makes the operation
inherently per-run-scoped — records of every other `run_id` are structurally untouched, and no
staging table is created (so there is no stale-artifact cleanup on recovery). ADR-030
§Compaction Atomicity Decision (revised round-62, F-P2A234-01) is the later, more-specific
artifact and supersedes both the earlier single-transaction narrative and the intervening
staging-table single-atomic-swap model for this property (Source-of-Truth Precedence rule 2 +
rule 4).

## Proof Method

| Attribute | Value |
|-----------|-------|
| Tool | integration |
| Location | `pregolya-checkpoint/tests/trajectory_crash_isolation.rs` |
| Phase | 6 |
| Bounded? | Two discrete crash points per ADR-030 §Compaction Atomicity Decision; deterministic fixture |
| Coverage | {INV-003} before-commit crash (case 1), after-commit crash (case 2), plus per-run scope-safety (a second `run_id`'s records untouched in both cases) |
| Oracle | Independent `replay()` call after process restart vs pre-compaction fixture (case 1) and vs retained-only oracle (case 2); a second `run_id`'s replay asserted unchanged in both cases |

## BC Traceability

| BC | Clause | Coverage |
|----|--------|---------|
| BC-2.04.011 | {INV-003} crash-isolation — no partial compaction observable after SIGKILL | integration: two crash-point cases (before_commit, after_commit) |
| BC-2.04.011 | {PC-004} reader-visible whole-operation atomicity — `replay` observes complete pre- OR complete post-compaction state | integration: case 1 asserts `replay` == pre_records; case 2 asserts `replay` == retained-only oracle |
| BC-2.04.011 | {INV-005} record-level table isolation + WAL non-blocking reads (single-transaction DELETE; no build-phase batching under the per-run DELETE model) | integration: DELETE transaction scoped to target `run_id`; other `run_id` records present after both crashes |
| ADR-030 | §Compaction Atomicity Decision — per-run single-transaction DELETE; per-run scope-safety | integration: a second `run_id`'s records asserted unchanged after a `compact(target_run_id)` crash at both crash points |

## BC Contradictions Flagged

**RESOLVED (round-62/F-P2A234-01).** The staging-table single-atomic-swap model (four-crash-point
matrix) was superseded by ADR-030 §Compaction Atomicity Decision (revised round-62, F-P2A234-01),
which replaced it with the **per-run single-transaction DELETE** model and a **two**-crash-point
matrix (before-commit, after-commit) — the staging-table build/swap crash points (mid-build,
mid-swap) no longer exist. BC-2.04.011 was reconciled in the same round-62 burst: its {INV-003}
now reads "the atomicity boundary is the single `BEGIN IMMEDIATE; DELETE ...; COMMIT` transaction
— there is no build phase, no staging table, and no rename operation; the crash matrix collapses
to two points: before-COMMIT ... and after-COMMIT ... Verified by VP-019 (integration,
two-crash-point matrix: before-COMMIT, after-COMMIT)", its {INV-005} dropped the bounded-batch
parenthetical and restated the concurrent-`put_record` guarantee, and its §Description,
§Architecture Anchors, §Related BCs, and §Verification Properties VP-019 row were all updated to
the per-run DELETE model. This VP and BC-2.04.011 {INV-003} are therefore in agreement on the
two-crash-point per-run DELETE matrix; no open reconciliation action remains. This VP does not
edit BC files.

## Proof Harness Skeleton

> **Integration VP note:** for integration-method VPs, the proof harness is an integration
> test outline rather than a unit-test proptest skeleton. The harness below is the
> authoritative test structure for Phase 6 implementation.

```rust
/// Integration test: trajectory compaction crash isolation
///
/// Two test cases per ADR-030 §Compaction Atomicity Decision (per-run single-transaction
/// DELETE model). Each case:
///  1. Start a fresh SQLite-backed CheckpointSaver + TrajectoryWriter (WAL mode).
///  2. Write pre_records for the TARGET run_id (N records, strictly ascending step_idx),
///     AND write other_pre_records for a SECOND run_id (scope-safety witness).
///  3. Spawn a subprocess that runs compact(target_run_id, policy) and receives SIGKILL
///     at the designated crash_point.
///  4. Restart: open the same SQLite database in a new process.
///  5. Call replay(target_run_id) and assert reader-visible atomicity:
///       - before_commit → replay == pre_records (pre-compaction),
///       - after_commit  → replay == retained-only oracle (post-compaction).
///  6. Call replay(other_run_id) and assert per-run scope-safety: it equals
///     other_pre_records UNCHANGED in both crash cases (compact of one run never
///     touches another run's records — the DELETE WHERE run_id = :run_id predicate).

enum CrashPoint {
    /// Case 1: kill during DELETE execution, before the COMMIT WAL record is written.
    BeforeCommit,
    /// Case 2: kill after the COMMIT WAL record is durably flushed.
    AfterCommit,
}

#[test]
fn trajectory_crash_isolation_before_commit() {
    // Crash before COMMIT: uncommitted DELETE-transaction WAL frames are discarded on the
    // next database open. Expected: replay(target) == pre_records (unchanged).
    let db = TempDb::new_wal();
    let pre_records = write_fixture_trajectory(&db, TARGET_RUN_ID, /* n_records = */ 10);
    let other_pre_records = write_fixture_trajectory(&db, OTHER_RUN_ID, /* n_records = */ 4);
    let policy = retention_frontier_policy(/* frontier = */ 5);

    kill_subprocess_at(CrashPoint::BeforeCommit, &db, TARGET_RUN_ID, &policy);

    let post_replay = open_and_replay(&db, TARGET_RUN_ID);
    assert_eq!(post_replay, pre_records,
        "crash before commit: uncommitted WAL frames discarded on next open; pre-compaction state preserved");

    // Per-run scope-safety: the second run's records are untouched.
    let other_replay = open_and_replay(&db, OTHER_RUN_ID);
    assert_eq!(other_replay, other_pre_records,
        "scope-safety: compact(target) before-commit crash must not touch another run_id's records");
}

#[test]
fn trajectory_crash_isolation_after_commit() {
    // Crash after COMMIT: DELETE durably committed.
    // Expected: replay(target) == retained subset (post-compaction is the correct committed state).
    let db = TempDb::new_wal();
    let pre_records = write_fixture_trajectory(&db, TARGET_RUN_ID, /* n_records = */ 10);
    let other_pre_records = write_fixture_trajectory(&db, OTHER_RUN_ID, /* n_records = */ 4);
    let policy = retention_frontier_policy(/* frontier = */ 5);
    let expected_post: Vec<_> = pre_records.iter()
        .filter(|r| r.step_idx >= policy.retention_frontier || policy.promoted.contains(&r.step_idx))
        .cloned()
        .collect();

    kill_subprocess_at(CrashPoint::AfterCommit, &db, TARGET_RUN_ID, &policy);

    let post_replay = open_and_replay(&db, TARGET_RUN_ID);
    assert_eq!(post_replay, expected_post,
        "crash after commit: post-compaction state must match committed retained set");

    // Per-run scope-safety: the second run's records are untouched (all present).
    let other_replay = open_and_replay(&db, OTHER_RUN_ID);
    assert_eq!(other_replay, other_pre_records,
        "scope-safety: compact(target) after-commit crash must not touch another run_id's records");
}
```

## Feasibility Assessment

**Feasible.** The property depends on (a) SQLite `BEGIN IMMEDIATE` / `COMMIT` atomicity of the
single per-run DELETE transaction in WAL mode — a well-proven SQLite guarantee — and (b) the
`DELETE ... WHERE run_id = :run_id` predicate that structurally scopes the operation to the
target run. The integration test requires:

1. A real SQLite database in WAL mode (provided by the `pregolya-checkpoint` SQLite backend).
2. Process crash injection at two deterministic crash points — achievable via a helper
   subprocess that sends itself `SIGKILL` at a nominated crash point (controlled by an
   environment variable or command argument): during DELETE execution before `COMMIT`, and after
   the `COMMIT` returns.
3. Database reopening and a `replay(target_run_id)` call after restart, plus a
   `replay(other_run_id)` call to witness per-run scope-safety (a second run's records untouched
   in both crash cases).

**Why Phase 6 (not Phase 3):** VP-019 requires a fully-implemented `TrajectoryCompactor`
SQLite backend with the per-run DELETE compaction (Phase 3 deliverable). Phase 6 integration
tests run against real implementations; the crash-isolation test cannot be constructed against
stubs.

**Why integration (not proptest or Kani):** SIGKILL cannot be modeled by proptest (in-process,
no crash semantics). Kani cannot model OS-level `BEGIN IMMEDIATE` / `COMMIT` / WAL frame-discard
semantics or the SQLite `DELETE` execution and durable-commit boundary. The integration test is
the only viable proof method for this property.

**Phase 6** — requires `TrajectoryCompactor::compact` + SQLite per-run DELETE backend (Phase 3).
Follows the pattern of VP-004 and VP-005 (integration P1 tests that require a real
network or process boundary).

## Proof Obligations

- [ ] Pre-compaction records are fully preserved after a before-commit crash (case 1; uncommitted DELETE-transaction WAL frames discarded on next database open).
- [ ] Post-compaction (correctly retained) records are present after an after-commit crash (case 2).
- [ ] Per-run scope-safety: a second `run_id`'s records are unchanged after a `compact(target_run_id)` crash at both crash points — the `DELETE WHERE run_id = :run_id` predicate never touches another run's records (F-P2A234-01).
- [ ] No partial compaction state (some eligible records removed, some not) is observable by `replay` in either crash scenario — the single `BEGIN IMMEDIATE / COMMIT` DELETE is the sole reader-visible atomicity boundary.
- [ ] SQLite WAL mode is enabled for the test database (ADR-030 §SQLite Topology Decision WAL requirement).
- [ ] Both integration test functions pass in CI with a real SQLite backend.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-31 | architect |
| BC-2.04.011 authored | 2026-08-31 | product-owner |
| `TrajectoryCompactor` SQLite backend implemented | | implementer |
| Integration test authored | | test-writer |
| Integration test first passed | | implementer |
| Locked (VERIFIED) | | formal-verifier |
