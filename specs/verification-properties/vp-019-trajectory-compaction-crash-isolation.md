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
input-hash: "6579f43"
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
version: "1.3"
changelog:
  - "1.3 (round-57/F-P2A227-03/2026-09-01): §BC Contradictions Flagged updated from OPEN to RESOLVED. The prior text carried a stale present-tense claim that BC-2.04.011 {INV-003} and its §Verification Properties VP-019 row 'currently describe a three crash-point matrix (before-begin, mid-txn, after-sync) ... flagged for product-owner reconciliation and routed via the orchestrator/state-manager'. That claim is now false and the open action is complete: BC-2.04.011 adopted the four-crash-point matrix in its round-53-corrective revision — its live {INV-003} and its §Verification Properties VP-019 row both now read four crash points (before-build-begins, mid-build (staging partially filled before swap), mid-swap-transaction (after BEGIN IMMEDIATE, before COMMIT), after-swap-commit). Section rewritten to record the contradiction as resolved (BC and this VP now agree on the four-point matrix; no open reconciliation action remains). No property, invariant, formal-invariant, harness, or proof-obligation change; VP does not edit BC files."
  - "1.2 (round-53/F-P2A221-01/2026-08-31): Crash matrix extended from three to FOUR crash points under the staging-table single-atomic-swap compaction model (ADR-030 §Compaction Atomicity Decision). Under this model, `compact` builds a shadow `trajectory_records_staging` table in bounded per-batch transactions (default 1,000 records per BEGIN IMMEDIATE/COMMIT on the staging table) while `trajectory_records` is untouched, then performs a single BEGIN IMMEDIATE; DROP TABLE trajectory_records; ALTER TABLE trajectory_records_staging RENAME TO trajectory_records; COMMIT swap — the sole reader-visible atomicity boundary. New crash point (case 2) added: mid-build (staging partially filled, before swap begins) → pre-compaction state intact, stale `trajectory_records_staging` dropped on recovery (implementation drops any stale staging table at the start of the next `compact` entry before a new build). §Property Statement, §Formal Invariant, §Source Contract, §Proof Method, §BC Traceability, §Proof Harness Skeleton, §Feasibility Assessment, and §Proof Obligations rewritten for four cases + recovery-time stale-staging cleanup. Reader-visible atomicity kept coherent with BC-2.04.011 {PC-004}/{INV-003}: `replay` always observes complete pre-compaction OR complete post-compaction state, never a partial. ADR-030 §Compaction Atomicity Decision added to inputs; input-hash refreshed. BC-2.04.011 {INV-003}/§VP-table three-point wording predates ADR-030 §Compaction Atomicity Decision and is flagged for product-owner reconciliation in §BC Contradictions Flagged (surface, not silently diverge)."
  - "1.1 (round-52/F-P2A217-03/2026-08-31): WAL-correct language applied throughout. SQLite topology is WAL mode (ADR-030 §SQLite Topology Decision). Scenario 2 (mid-transaction crash): 'SQLite rollback journal restores pre-compaction state on restart' → 'uncommitted WAL frames after the last commit marker are discarded on the next database open; pre-compaction state is fully recovered'. §Property Statement introductory sentence corrected similarly. Integration test assert message updated. §Proof Obligations updated. Rollback journal is not used in WAL mode; the correct recovery mechanism is WAL frame discard on next open."
  - "1.0 (round-50/F-P2A209-03/2026-08-31): Initial — trajectory compaction crash-isolation integration P1. BC-2.04.011 {INV-003} anchor: SQLite BEGIN IMMEDIATE/COMMIT atomicity under SIGKILL. Scoped from VP-018: VP-018 proptest covers pure-core selection/filtering ({INV-001}/{INV-002}); VP-019 covers OS-level crash-recovery semantics that proptest and Kani cannot model. Human-approved VP mint: crash-isolation test of durable audit trajectory compaction is a production-grade correctness obligation. Arithmetic: total 19→20 (P0 6 unchanged, P1 13→14); integration 2→3."
---

# VP-019: Trajectory Compaction Crash Isolation — SQLite Atomicity Under SIGKILL

## Property Statement

For any `TrajectoryCompactor::compact` call that is interrupted by SIGKILL at any of
**four crash points** across the staging-table single-atomic-swap compaction
(ADR-030 §Compaction Atomicity Decision) — before the build phase begins, mid-build
(the shadow table `trajectory_records_staging` partially filled, before the swap begins),
mid-swap (after `BEGIN IMMEDIATE`, before `COMMIT`), or after the swap `COMMIT` returns —
a subsequent `TrajectoryReader::replay(run_id)` call after process restart returns either
the **complete pre-compaction trajectory record sequence** or the **complete post-compaction
retained sequence**, with no partial compaction, no record loss, and no record mutation.

The property follows from the staging-table single-atomic-swap model:

- **Build phase** copies retained records from `trajectory_records` into
  `trajectory_records_staging` in bounded per-batch transactions (default 1,000 records per
  `BEGIN IMMEDIATE / COMMIT` on the staging table). `trajectory_records` is never modified
  during the build phase, and `TrajectoryReader::replay` reads `trajectory_records` only —
  `trajectory_records_staging` is invisible to `replay` throughout the build.
- **Swap phase** is a single transaction — `BEGIN IMMEDIATE; DROP TABLE trajectory_records;
  ALTER TABLE trajectory_records_staging RENAME TO trajectory_records; COMMIT` — that is the
  **sole reader-visible atomicity boundary**. In WAL mode, if the process is killed after
  `BEGIN IMMEDIATE` but before the `COMMIT` marker is durably recorded, the uncommitted WAL
  frames of the swap transaction are discarded by SQLite on the next database open (no
  rollback journal — WAL mode uses frame discard), leaving `trajectory_records` in its
  pre-compaction state.
- **Recovery-time stale-staging cleanup:** a `trajectory_records_staging` table left behind by
  a mid-build or mid-swap crash is dropped unconditionally at the start of the next `compact`
  entry, before a new build begins. This guarantees a crashed build never corrupts or
  contaminates a subsequent compaction.

This yields reader-visible atomicity coherent with BC-2.04.011 {PC-004}/{INV-003}: `replay`
always observes either the complete pre-compaction state or the complete post-compaction
state, and never a partial compaction, regardless of when the SIGKILL lands.

Four crash scenarios (ADR-030 §Compaction Atomicity Decision four-point matrix):

1. **Before build begins:** SIGKILL before any staging batch is written and before the swap.
   No reader-visible mutation occurred; `trajectory_records` is intact. Pre-compaction state
   is trivially preserved.
2. **Mid-build [NEW]:** SIGKILL after `BEGIN IMMEDIATE` on the staging table but before the
   swap phase begins — `trajectory_records_staging` is partially filled (indeterminate state).
   `trajectory_records` was never touched, so `replay` returns the complete pre-compaction
   sequence. The stale `trajectory_records_staging` is dropped on recovery at the next
   `compact` entry.
3. **Mid-swap transaction:** SIGKILL after `BEGIN IMMEDIATE` of the swap transaction but before
   `COMMIT`. In WAL mode the uncommitted swap-transaction WAL frames are discarded on the next
   database open; `trajectory_records` is left in its pre-compaction state (and any residual
   `trajectory_records_staging` is dropped on recovery at the next `compact` entry).
4. **After swap commit:** SIGKILL after the swap `COMMIT` returns. The rename is durably
   committed; `trajectory_records` is the retained-only post-compaction state, which is the
   correct outcome.

> **Scope note:** The pure-core record-selection invariant ({INV-001}/{INV-002}) is covered
> by VP-018 proptest. VP-019 covers {INV-003} exclusively — the OS-level crash-recovery
> property that proptest and Kani cannot model (no SIGKILL injection, no SQLite WAL semantics,
> no staging-table swap topology).

## Formal Invariant

```
∀ run_id: Uuid,
  pre_records: Vec<TrajectoryRecord> (committed to storage via put_record),
  policy: TrajectoryRetentionPolicy,
  crash_point ∈ {before_build, mid_build, mid_swap, after_swap_commit}:

  let crash_outcome = process_killed_at(crash_point, compact(run_id, policy));
  let post_replay   = restart_and_replay(run_id);  // TrajectoryReader::replay after process restart

  crash_point ∈ {before_build, mid_build, mid_swap}
    → post_replay == pre_records               // pre-compaction state fully preserved
  crash_point == after_swap_commit
    → post_replay == filter(!policy.is_eligible, pre_records)  // swap committed; correct

  // Recovery-time stale-staging cleanup (build/swap crashes):
  crash_point ∈ {mid_build, mid_swap}
    → after restart, a subsequent compact(run_id, policy) first DROPs any stale
      trajectory_records_staging, rebuilds, swaps, and returns Ok(()) with
      replay(run_id) == filter(!policy.is_eligible, pre_records)

  // Reader-visible atomicity holds in every case:
  ∀ crash_point: post_replay ∈ {pre_records, filter(!policy.is_eligible, pre_records)}
    // never a partial compaction — replay reads trajectory_records only,
    // never trajectory_records_staging
```

## Source Contract

BC-2.04.011 {INV-003}: "Compaction is crash-isolated. A SIGKILL delivered at any point
during `compact(run_id, policy)` leaves `replay(run_id)` in a consistent state: either the
complete pre-compaction replay (if the transaction did not commit) or the complete
post-compaction replay (if the transaction committed). No partial compaction state is
observable." BC-2.04.011 {PC-004} states the same reader-visible whole-operation atomicity.

ADR-030 §Compaction Atomicity Decision — Staging-Table Single-Atomic-Swap Model — mandates
the topology that realizes this invariant: the build phase copies retained records into
`trajectory_records_staging` in bounded per-batch transactions (default 1,000 records per
`BEGIN IMMEDIATE / COMMIT` on the staging table) while `trajectory_records` is untouched, and
the swap phase performs the single `BEGIN IMMEDIATE; DROP TABLE trajectory_records; ALTER
TABLE trajectory_records_staging RENAME TO trajectory_records; COMMIT` transaction as the sole
reader-visible atomicity boundary. Per that decision's crash semantics: crash mid-build leaves
`trajectory_records` intact with stale staging dropped on recovery; crash mid-swap is
WAL-atomic (pre or post depending on whether `COMMIT` landed, stale staging dropped on
recovery); and the implementation MUST drop any stale `trajectory_records_staging` table at the
start of each `compact` call before beginning a new build. ADR-030 §Compaction Atomicity
Decision (added round-53) is the later, more-specific artifact and supersedes the earlier
single-transaction narrative for this property (Source-of-Truth Precedence rule 2 + rule 4).

## Proof Method

| Attribute | Value |
|-----------|-------|
| Tool | integration |
| Location | `pregolya-checkpoint/tests/trajectory_crash_isolation.rs` |
| Phase | 6 |
| Bounded? | Four discrete crash points per ADR-030 §Compaction Atomicity Decision; deterministic fixture |
| Coverage | {INV-003} before-build crash (case 1), mid-build crash (case 2, NEW), mid-swap crash (case 3), after-swap-commit crash (case 4), plus recovery-time stale-staging cleanup |
| Oracle | Independent `replay()` call after process restart vs pre-compaction fixture (cases 1–3) and vs retained-only oracle (case 4) |

## BC Traceability

| BC | Clause | Coverage |
|----|--------|---------|
| BC-2.04.011 | {INV-003} crash-isolation — no partial compaction observable after SIGKILL | integration: four crash-point cases (before_build, mid_build, mid_swap, after_swap_commit) |
| BC-2.04.011 | {PC-004} reader-visible whole-operation atomicity — `replay` observes complete pre- OR complete post-compaction state | integration: all four cases assert `replay` == pre_records (cases 1–3) or retained-only oracle (case 4) |
| BC-2.04.011 | {INV-005} bounded compaction batch (build phase writes staging table only; swap is fast catalog op) | integration: build-phase batches exercised against `trajectory_records_staging`; `trajectory_records` untouched until swap |
| ADR-030 | §Compaction Atomicity Decision — staging-table single-atomic-swap model; recovery-time stale-staging cleanup | integration: mid_build/mid_swap cases assert stale `trajectory_records_staging` is dropped and a subsequent `compact` succeeds |

## BC Contradictions Flagged

**RESOLVED (round-57/F-P2A227-03).** An earlier revision of this VP flagged a contradiction:
BC-2.04.011 {INV-003} and its §Verification Properties table (VP-019 row) described a **three**
crash-point matrix (before-begin, mid-txn, after-sync) that predated the staging-table
single-atomic-swap model, whereas that model requires a **four**-point matrix (the mid-build
point, case 2, has no analogue in the pre-staging single-transaction model). That contradiction
is now closed: BC-2.04.011 adopted the four-crash-point matrix in its round-53-corrective
revision. BC-2.04.011 {INV-003} now records "Verified by VP-019 (integration, four-crash-point
matrix: before-build-begins, mid-build (staging partially filled before swap),
mid-swap-transaction (after BEGIN IMMEDIATE, before COMMIT), after-swap-commit)", and the
BC-2.04.011 §Verification Properties VP-019 row now describes four crash points / four cases.
This VP and BC-2.04.011 {INV-003} are therefore in agreement on the four-crash-point matrix; no
open reconciliation action remains, and none is routed to product-owner or state-manager. This
VP does not edit BC files.

## Proof Harness Skeleton

> **Integration VP note:** for integration-method VPs, the proof harness is an integration
> test outline rather than a unit-test proptest skeleton. The harness below is the
> authoritative test structure for Phase 6 implementation.

```rust
/// Integration test: trajectory compaction crash isolation
///
/// Four test cases per ADR-030 §Compaction Atomicity Decision (staging-table
/// single-atomic-swap model). Each case:
///  1. Start a fresh SQLite-backed CheckpointSaver + TrajectoryWriter (WAL mode).
///  2. Write pre_records (N trajectory records, strictly ascending step_idx) to
///     `trajectory_records`.
///  3. Spawn a subprocess that runs compact(run_id, policy) and receives SIGKILL
///     at the designated crash_point.
///  4. Restart: open the same SQLite database in a new process.
///  5. Call replay(run_id) and assert reader-visible atomicity:
///       - before_build / mid_build / mid_swap → replay == pre_records (pre-compaction),
///       - after_swap_commit → replay == retained-only oracle (post-compaction).
///  6. For mid_build / mid_swap: additionally assert recovery-time stale-staging cleanup —
///     a subsequent compact(run_id, policy) DROPs the stale `trajectory_records_staging`,
///     rebuilds, swaps, and returns Ok(()) with replay == retained-only oracle.

enum CrashPoint {
    /// Case 1: kill before the build phase writes any staging batch.
    BeforeBuild,
    /// Case 2 [NEW]: kill after BEGIN IMMEDIATE on the staging table, staging partially
    /// filled, before the swap phase begins.
    MidBuild,
    /// Case 3: kill after BEGIN IMMEDIATE of the swap transaction, before its COMMIT.
    MidSwap,
    /// Case 4: kill after the swap COMMIT returns.
    AfterSwapCommit,
}

#[test]
fn trajectory_crash_isolation_before_build() {
    // Crash before the build phase begins: trajectory_records untouched, no staging.
    // Expected: replay == pre_records (unchanged).
    let db = TempDb::new_wal();
    let pre_records = write_fixture_trajectory(&db, /* n_records = */ 10);
    let policy = retention_frontier_policy(/* frontier = */ 5);

    kill_subprocess_at(CrashPoint::BeforeBuild, &db, &policy);

    let post_replay = open_and_replay(&db);
    assert_eq!(post_replay, pre_records,
        "crash before build: pre-compaction state must be fully preserved");
}

#[test]
fn trajectory_crash_isolation_mid_build() {
    // NEW under the staging-table model.
    // Crash mid-build: trajectory_records_staging partially filled, swap not yet begun.
    // Expected: replay == pre_records (trajectory_records never modified during build);
    //           stale trajectory_records_staging dropped on recovery at next compact entry.
    let db = TempDb::new_wal();
    let pre_records = write_fixture_trajectory(&db, /* n_records = */ 10);
    let policy = retention_frontier_policy(/* frontier = */ 5);
    let expected_post: Vec<_> = pre_records.iter()
        .filter(|r| !policy.is_eligible(r))
        .cloned()
        .collect();

    // Subprocess kills itself after a staging batch commit, before the swap phase.
    kill_subprocess_at(CrashPoint::MidBuild, &db, &policy);

    // Reader-visible atomicity: trajectory_records is unchanged.
    let post_replay = open_and_replay(&db);
    assert_eq!(post_replay, pre_records,
        "crash mid-build: trajectory_records untouched during build; pre-compaction state preserved");

    // Recovery-time stale-staging cleanup: a stale staging table may remain until the next
    // compact entry drops it. The subsequent compact must succeed (drop stale staging,
    // rebuild, swap) and produce the correct post-compaction state.
    let rerun = compact_in_process(&db, &policy);
    assert!(rerun.is_ok(),
        "recovery: subsequent compact must drop stale trajectory_records_staging and succeed");
    let after_rerun = open_and_replay(&db);
    assert_eq!(after_rerun, expected_post,
        "recovery: after stale-staging cleanup + rebuild + swap, replay == retained-only oracle");
}

#[test]
fn trajectory_crash_isolation_mid_swap() {
    // Crash inside the swap transaction (after BEGIN IMMEDIATE, before COMMIT).
    // Expected: replay == pre_records (WAL mode: uncommitted swap-transaction frames discarded
    //           on next open); residual staging dropped on recovery at next compact entry.
    let db = TempDb::new_wal();
    let pre_records = write_fixture_trajectory(&db, /* n_records = */ 10);
    let policy = retention_frontier_policy(/* frontier = */ 5);
    let expected_post: Vec<_> = pre_records.iter()
        .filter(|r| !policy.is_eligible(r))
        .cloned()
        .collect();

    kill_subprocess_at(CrashPoint::MidSwap, &db, &policy);

    let post_replay = open_and_replay(&db);
    assert_eq!(post_replay, pre_records,
        "crash mid-swap: uncommitted swap-transaction WAL frames discarded on next open; pre-compaction state recovered");

    // Recovery-time stale-staging cleanup + successful re-compaction.
    let rerun = compact_in_process(&db, &policy);
    assert!(rerun.is_ok(),
        "recovery: subsequent compact must drop any residual trajectory_records_staging and succeed");
    let after_rerun = open_and_replay(&db);
    assert_eq!(after_rerun, expected_post,
        "recovery: after stale-staging cleanup + rebuild + swap, replay == retained-only oracle");
}

#[test]
fn trajectory_crash_isolation_after_swap_commit() {
    // Crash after the swap COMMIT returns: rename durably committed.
    // Expected: replay == retained subset (post-compaction is the correct committed state).
    let db = TempDb::new_wal();
    let pre_records = write_fixture_trajectory(&db, /* n_records = */ 10);
    let policy = retention_frontier_policy(/* frontier = */ 5);
    let expected_post: Vec<_> = pre_records.iter()
        .filter(|r| !policy.is_eligible(r))
        .cloned()
        .collect();

    kill_subprocess_at(CrashPoint::AfterSwapCommit, &db, &policy);

    let post_replay = open_and_replay(&db);
    assert_eq!(post_replay, expected_post,
        "crash after swap COMMIT: post-compaction state must match committed retained set");
}
```

## Feasibility Assessment

**Feasible.** The property depends on (a) SQLite `BEGIN IMMEDIATE` / `COMMIT` atomicity of the
single swap transaction in WAL mode — a well-proven SQLite guarantee — and (b) the invariant
that the build phase writes only `trajectory_records_staging` and never `trajectory_records`.
The integration test requires:

1. A real SQLite database in WAL mode (provided by the `pregolya-checkpoint` SQLite backend).
2. Process crash injection at four deterministic crash points — achievable via a helper
   subprocess that sends itself `SIGKILL` at a nominated crash point (controlled by an
   environment variable or command argument): before the first staging batch, after a staging
   batch commit but before the swap, inside the swap transaction before `COMMIT`, and after the
   swap `COMMIT` returns.
3. Database reopening and `replay()` call after restart, plus a re-entrant `compact` call to
   exercise recovery-time stale-staging cleanup for the mid-build and mid-swap cases.

**Why Phase 6 (not Phase 3):** VP-019 requires a fully-implemented `TrajectoryCompactor`
SQLite backend with the staging-table swap topology (Phase 3 deliverable). Phase 6 integration
tests run against real implementations; the crash-isolation test cannot be constructed against
stubs.

**Why integration (not proptest or Kani):** SIGKILL cannot be modeled by proptest (in-process,
no crash semantics). Kani cannot model OS-level `BEGIN IMMEDIATE` / `COMMIT` / WAL
frame-discard semantics or the `DROP TABLE` / `ALTER TABLE ... RENAME TO` catalog swap. The
integration test is the only viable proof method for this property.

**Phase 6** — requires `TrajectoryCompactor::compact` + SQLite staging-swap backend (Phase 3).
Follows the pattern of VP-004 and VP-005 (integration P1 tests that require a real
network or process boundary).

## Proof Obligations

- [ ] Pre-compaction records are fully preserved after a before-build crash (case 1).
- [ ] Pre-compaction records are fully preserved after a mid-build crash (case 2, NEW; `trajectory_records` untouched during the staging build).
- [ ] Pre-compaction records are fully preserved after a mid-swap crash (case 3; uncommitted swap-transaction WAL frames discarded on next database open).
- [ ] Post-compaction (correctly retained) records are present after an after-swap-commit crash (case 4).
- [ ] Recovery-time stale-staging cleanup: after a mid-build or mid-swap crash, a subsequent `compact` drops any stale `trajectory_records_staging` table before rebuilding and returns `Ok(())` with the correct post-compaction `replay` result.
- [ ] No partial compaction state (some eligible records removed, some not) is observable by `replay` in any crash scenario — `replay` reads `trajectory_records` only and never `trajectory_records_staging`.
- [ ] SQLite WAL mode is enabled for the test database (ADR-030 §SQLite Topology Decision WAL requirement).
- [ ] All four integration test functions pass in CI with a real SQLite backend.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-31 | architect |
| BC-2.04.011 authored | 2026-08-31 | product-owner |
| `TrajectoryCompactor` SQLite backend implemented | | implementer |
| Integration test authored | | test-writer |
| Integration test first passed | | implementer |
| Locked (VERIFIED) | | formal-verifier |
