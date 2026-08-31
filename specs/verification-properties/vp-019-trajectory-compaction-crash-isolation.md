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
input-hash: "85f1f9d"
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
version: "1.0"
changelog:
  - "1.0 (round-50/F-P2A209-03/2026-08-31): Initial — trajectory compaction crash-isolation integration P1. BC-2.04.011 {INV-003} anchor: SQLite BEGIN IMMEDIATE/COMMIT atomicity under SIGKILL. Scoped from VP-018: VP-018 proptest covers pure-core selection/filtering ({INV-001}/{INV-002}); VP-019 covers OS-level crash-recovery semantics that proptest and Kani cannot model. Human-approved VP mint: crash-isolation test of durable audit trajectory compaction is a production-grade correctness obligation. Arithmetic: total 19→20 (P0 6 unchanged, P1 13→14); integration 2→3."
---

# VP-019: Trajectory Compaction Crash Isolation — SQLite Atomicity Under SIGKILL

## Property Statement

For any `TrajectoryCompactor::compact` call that is interrupted by SIGKILL at any of
three crash points during the SQLite transaction — before `BEGIN IMMEDIATE`, mid-transaction,
or after `COMMIT` sync — a subsequent `TrajectoryReader::replay(run_id)` call after process
restart returns the **complete pre-compaction trajectory record sequence** with no partial
compaction, no record loss, and no record mutation.

The property follows from SQLite's `BEGIN IMMEDIATE` / `COMMIT` atomicity: either the
full compaction transaction commits or the database is left in its pre-compaction state.
A partially written transaction (SIGKILL before `COMMIT`) is rolled back by SQLite on the
next open.

Three crash scenarios (BC-2.04.011 TV-002 three-case matrix):

1. **Before begin:** SIGKILL before `BEGIN IMMEDIATE` is issued. No transaction started;
   pre-compaction state is trivially preserved.
2. **Mid-transaction:** SIGKILL after `BEGIN IMMEDIATE` but before `COMMIT`. SQLite
   rollback journal restores pre-compaction state on restart.
3. **After sync:** SIGKILL after `COMMIT` returns. Compaction is fully committed; post-compaction
   state is the correct outcome (retained records only).

> **Scope note:** The pure-core record-selection invariant ({INV-001}/{INV-002}) is covered
> by VP-018 proptest. VP-019 covers {INV-003} exclusively — the OS-level crash-recovery
> property that proptest and Kani cannot model (no SIGKILL injection, no SQLite WAL semantics).

## Formal Invariant

```
∀ run_id: Uuid,
  pre_records: Vec<TrajectoryRecord> (committed to storage via put_record),
  policy: TrajectoryRetentionPolicy,
  crash_point ∈ {before_begin, mid_txn, after_sync}:

  let crash_outcome = process_killed_at(crash_point, compact(run_id, policy));
  let post_replay   = restart_and_replay(run_id);  // TrajectoryReader::replay after process restart

  crash_point ∈ {before_begin, mid_txn}
    → post_replay == pre_records               // pre-compaction state fully preserved
  crash_point == after_sync
    → post_replay == filter(!policy.is_eligible, pre_records)  // compaction committed; correct
```

## Source Contract

BC-2.04.011 {INV-003}: "Compaction is crash-isolated. A SIGKILL delivered at any point
during `compact(run_id, policy)` leaves `replay(run_id)` in a consistent state: either the
complete pre-compaction replay (if the transaction did not commit) or the complete
post-compaction replay (if the transaction committed). No partial compaction state is
observable."

ADR-030 §Decision 2 mandates SQLite `BEGIN IMMEDIATE` / `COMMIT` for the transaction boundary
and `WAL` journal mode to prevent blocking `CheckpointSaver::put_writes` during the compaction
transaction window.

## Proof Method

| Attribute | Value |
|-----------|-------|
| Tool | integration |
| Location | `pregolya-checkpoint/tests/trajectory_crash_isolation.rs` |
| Phase | 6 |
| Bounded? | Three discrete crash points per TV-002; deterministic fixture |
| Coverage | {INV-003} before-begin crash (case 1), mid-txn crash (case 2), after-sync crash (case 3) |
| Oracle | Independent `replay()` call after process restart vs pre-compaction fixture |

## BC Traceability

| BC | Clause | Coverage |
|----|--------|---------|
| BC-2.04.011 | {INV-003} crash-isolation — no partial compaction observable after SIGKILL | integration: three crash-point cases (before_begin, mid_txn, after_sync) |
| BC-2.04.011 | TV-002 crash-recovery test vector — SIGKILL mid-compaction, restart, replay returns pre-compaction result | integration: direct TV-002 implementation |
| BC-2.04.011 | EC-001 — SQLite journal mode WAL + BEGIN IMMEDIATE boundary | integration: implicit WAL guarantee exercised by crash scenarios |

## BC Contradictions Flagged

None identified. BC-2.04.011 is authored and active (v1.0). ADR-030 §Decision 2 SQLite
topology is consistent with this VP.

## Integration Test Outline

```rust
/// Integration test: trajectory compaction crash isolation
///
/// Three test cases per TV-002. Each case:
///  1. Start a fresh SQLite-backed CheckpointSaver + TrajectoryWriter.
///  2. Write pre_records (N trajectory records, strictly ascending step_idx).
///  3. Spawn a subprocess that runs compact(run_id, policy) and receives SIGKILL
///     at the designated crash_point.
///  4. Restart: open the same SQLite database in a new process.
///  5. Call replay(run_id) and assert it equals pre_records (crash_point before_begin
///     or mid_txn) or the correctly-retained post-compaction sequence (crash_point after_sync).

#[test]
fn trajectory_crash_isolation_before_begin() {
    // Crash before BEGIN IMMEDIATE: no transaction started.
    // Expected: replay == pre_records (unchanged).
    let db = TempDb::new();
    let pre_records = write_fixture_trajectory(&db, /* n_records = */ 10);
    let policy = retention_frontier_policy(/* frontier = */ 5);

    // Subprocess kills itself before issuing BEGIN IMMEDIATE.
    kill_subprocess_at(CrashPoint::BeforeBegin, &db, &policy);

    let post_replay = open_and_replay(&db);
    assert_eq!(post_replay, pre_records,
        "crash before BEGIN: pre-compaction state must be fully preserved");
}

#[test]
fn trajectory_crash_isolation_mid_transaction() {
    // Crash after BEGIN IMMEDIATE, before COMMIT: SQLite rolls back.
    // Expected: replay == pre_records (rollback journal restores pre-compaction state).
    let db = TempDb::new();
    let pre_records = write_fixture_trajectory(&db, /* n_records = */ 10);
    let policy = retention_frontier_policy(/* frontier = */ 5);

    // Subprocess kills itself mid-transaction (after DELETE eligible, before COMMIT).
    kill_subprocess_at(CrashPoint::MidTransaction, &db, &policy);

    let post_replay = open_and_replay(&db);
    assert_eq!(post_replay, pre_records,
        "crash mid-txn: SQLite rollback must restore pre-compaction state");
}

#[test]
fn trajectory_crash_isolation_after_commit() {
    // Crash after COMMIT returns: transaction committed successfully.
    // Expected: replay == retained subset (post-compaction is the correct committed state).
    let db = TempDb::new();
    let pre_records = write_fixture_trajectory(&db, /* n_records = */ 10);
    let policy = retention_frontier_policy(/* frontier = */ 5);
    let expected_post: Vec<_> = pre_records.iter()
        .filter(|r| !policy.is_eligible(r))
        .cloned()
        .collect();

    // Subprocess kills itself after COMMIT returns (full compaction committed).
    kill_subprocess_at(CrashPoint::AfterCommit, &db, &policy);

    let post_replay = open_and_replay(&db);
    assert_eq!(post_replay, expected_post,
        "crash after COMMIT: post-compaction state must match committed retained set");
}
```

## Feasibility Assessment

**Feasible.** The property depends on SQLite `BEGIN IMMEDIATE` / `COMMIT` atomicity, which
is a well-proven SQLite guarantee in WAL mode. The integration test requires:

1. A real SQLite database (provided by the `pregolya-checkpoint` SQLite backend).
2. Process crash injection at three deterministic crash points — achievable via a helper
   subprocess that sends itself `SIGKILL` at a nominated crash point (controlled by an
   environment variable or command argument).
3. Database reopening and `replay()` call after restart.

**Why Phase 6 (not Phase 3):** VP-019 requires a fully-implemented `TrajectoryCompactor`
SQLite backend (Phase 3 deliverable). Phase 6 integration tests run against real
implementations; the crash-isolation test cannot be constructed against stubs.

**Why integration (not proptest or Kani):** SIGKILL cannot be modeled by proptest (in-process,
no crash semantics). Kani cannot model OS-level `BEGIN IMMEDIATE` / `COMMIT` / rollback
journal interactions. The integration test is the only viable proof method for this property.

**Phase 6** — requires `TrajectoryCompactor::compact` + SQLite backend (Phase 3).
Follows the pattern of VP-004 and VP-005 (integration P1 tests that require a real
network or process boundary).

## Proof Obligations

- [ ] Pre-compaction records are fully preserved after a before-begin crash (TV-002 case 1).
- [ ] Pre-compaction records are fully preserved after a mid-transaction crash (TV-002 case 2; SQLite rollback journal).
- [ ] Post-compaction (correctly retained) records are present after an after-commit crash (TV-002 case 3).
- [ ] No partial compaction state (some eligible records removed, some not) is observable in any crash scenario.
- [ ] SQLite WAL mode is enabled for the test database (ADR-030 §Decision 2 WAL requirement).
- [ ] All three integration test functions pass in CI with a real SQLite backend.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-31 | architect |
| BC-2.04.011 authored | 2026-08-31 | product-owner |
| `TrajectoryCompactor` SQLite backend implemented | | implementer |
| Integration test authored | | test-writer |
| Integration test first passed | | implementer |
| Locked (VERIFIED) | | formal-verifier |
