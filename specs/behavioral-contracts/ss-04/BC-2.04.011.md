---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.011
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-04
capability: CAP-040
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-31T00:00:00Z
changelog:
  - "1.0 (ADR-030 Stage 2b/2026-08-31): Initial greenfield spec — Trajectory Compaction Isolation; safe, atomic, crash-isolated compaction of an unbounded durable audit trajectory; DI-002 + DI-004 + DI-014 invariant enforcement; ADR-030 §Decision 2 Trajectory Compaction Isolation scope. Human-approved 6th additive BC."
  - "1.1 (ADR-030/Stage-3.5-product-owner/2026-08-31): PC-005, EC-004, INV-004, TV-003 wired to E-TRAJ-004 TrajectoryRetainedEligible (VAL, broken, Never); category notation corrected from VALIDATION→VAL throughout to match taxonomy category code convention."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-040
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "9f857f5"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.04.011: Trajectory Compaction Isolation

## Description

`TrajectoryCompactor` (trait in `checkpoint::trajectory`, pregolya-checkpoint) provides an
operation to compact an unbounded durable audit trajectory by removing historical records
that are no longer needed for replay, while guaranteeing that every retained record is
preserved intact and in ascending `step_idx` order. Compaction is atomic — it uses a SQLite
transaction (or equivalent storage-tier atomic swap) such that a process crash mid-compaction
leaves the pre-compaction trajectory fully intact. Records designated as retained (promoted
or at the frontier) are never eligible for removal. The operation enables long-running
research orchestrator sessions to prevent unbounded storage growth without compromising
audit-grade record integrity.

## Preconditions

1. {PRE-001} A `TrajectoryCompactor` implementation exists, backed by the same durable
   storage tier as `TrajectoryWriter` / `TrajectoryReader` (BC-2.04.009, BC-2.04.010).
2. {PRE-002} The caller supplies a `TrajectoryRetentionPolicy` value specifying which records are
   eligible for removal (e.g., records with `step_idx` strictly below a retention frontier,
   where the frontier record itself and any promoted records are excluded from eligibility).
3. {PRE-003} The storage backend is reachable (not shutdown, not out of disk space).

## Postconditions

1. {PC-001} After `compact(run_id, policy)` returns `Ok(())`, every record designated as
   retained by the policy is still present in `replay(run_id)` with its original `step_idx`
   and `payload` values unchanged. No retained record is mutated.
2. {PC-002} After `compact(run_id, policy)` returns `Ok(())`, `replay(run_id)` returns all
   retained records in strictly ascending `step_idx` order, consistent with BC-2.04.010
   {PC-002}. The post-compaction replay sequence is a strict ascending sub-sequence of the
   pre-compaction replay sequence.
3. {PC-003} Records that were eligible for removal per the policy are absent from
   `replay(run_id)` after `Ok(())` returns. No eligible record survives compaction.
4. {PC-004} Compaction is atomic: either all eligible records are removed and all retained
   records are preserved (`Ok(())`), or no change is made and an `Err(PregolyaError)` is
   returned. No intermediate partial state is observable by `replay`.
5. {PC-005} If `policy` attempts to mark a retained (promoted/frontier) record as eligible,
   `compact` returns `Err(PregolyaError { code: E-TRAJ-004, category: VAL, .. })` without
   modifying any records. The pre-compaction trajectory remains intact.
6. {PC-006} Storage errors (backend I/O failure, transaction abort, disk full) propagate as
   `Err(PregolyaError)`. After any error, `replay(run_id)` returns the same result as before
   the attempted compaction — the pre-compaction state is fully intact.

## Invariants

- {INV-001} **No committed retained record is lost or mutated.** For any `(run_id, step_idx)`
  pair that `replay(run_id)` returned before compaction AND whose record is designated as
  retained by the policy, that exact `TrajectoryRecord` (same `step_idx`, `event_kind`,
  `payload`) appears in `replay(run_id)` after compaction.
- {INV-002} **Replay determinism is preserved for retained records.** The post-compaction
  replay order is a strict ascending sub-sequence of the pre-compaction order. No retained
  record changes its relative position or `step_idx` value.
- {INV-003} **Compaction is crash-isolated (atomic segment swap).** A process crash or
  SIGKILL at any point during compaction execution leaves the pre-compaction trajectory
  record fully intact. The implementation uses an atomic storage transaction (e.g., SQLite
  `BEGIN IMMEDIATE` / `COMMIT`) — no torn state is allowed. After recovery, `replay(run_id)`
  returns the pre-compaction result.
- {INV-004} **Retained records are never eligible.** A policy MUST NOT mark a record as
  eligible if that record is designated as retained (promoted or at the frontier). Any
  attempt to do so is a contract violation caught at `compact` call time with
  `Err(PregolyaError { code: E-TRAJ-004, category: VAL, .. })`.
- {INV-005} **Compaction isolation from ADR-019.** Trajectory compaction operates on the
  trajectory storage slice only; it has no access to and does not affect the conversation-
  context checkpoint tables managed by `CheckpointSaver` (ADR-019). The two compaction paths
  are independent and cannot interfere.

## Edge Cases

### EC-001: Crash during compaction — pre-compaction record survives
**Scenario:** `compact(run_id, policy)` begins executing. The process is killed (SIGKILL /
OS crash) mid-transaction, before the atomic commit completes.
**Expected behavior:** After process restart, `replay(run_id)` returns the exact set of
records that were present before `compact` was called. The in-progress transaction was
rolled back by the storage tier. No partial compaction result is visible.

### EC-002: Compact an empty trajectory
**Scenario:** `compact(run_id_X, policy)` is called for a `run_id` with zero committed
records (`replay(run_id_X)` returns `Ok(vec![])`).
**Expected behavior:** `compact` returns `Ok(())`. `replay(run_id_X)` continues to return
`Ok(vec![])`. No error.

### EC-003: Single-record trajectory where the record is retained
**Scenario:** `replay(run_id_Y)` returns one record (`r0`). The policy designates `r0` as
retained (e.g., it is the frontier record).
**Expected behavior:** `compact(run_id_Y, policy)` returns `Ok(())`. `replay(run_id_Y)`
still returns `[r0]`. Zero records were eligible; compaction was a no-op.

### EC-004: Policy attempts to compact a retained record
**Scenario:** The caller constructs a `TrajectoryRetentionPolicy` that incorrectly marks a promoted
record as eligible for removal.
**Expected behavior:** `compact(run_id, policy)` returns
`Err(PregolyaError { code: E-TRAJ-004, message: "TrajectoryRetainedEligible: compact(run_id='<run_id>') attempted to remove retained record at step_idx=<step_idx> — retained records are never eligible for compaction", category: VAL, .. })`
without modifying any records. The trajectory is unchanged; `replay(run_id)` returns the
same result as before the call.

### EC-005: Compaction frontier equals the highest committed step_idx — retain only the frontier
**Scenario:** `replay(run_id)` returns `[r0, r1, r2]` with `step_idx` = 0, 1, 2. The
policy marks `r0` and `r1` as eligible and `r2` (the frontier) as retained.
**Expected behavior:** `compact` returns `Ok(())`. `replay(run_id)` returns `[r2]` — the
single retained record — in ascending `step_idx` order ({PC-002}).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `replay(R)` = `[r0(step=0), r1(step=1), r2(step=2)]`; policy retains `r2`, marks `r0`/`r1` eligible; `compact(R, policy)` | `Ok(())`; `replay(R)` = `[r2(step=2)]` in ascending order | Happy-path compaction; {PC-001}, {PC-002}, {PC-003} |
| TV-002 | `compact(R, policy)` begins; process SIGKILL before transaction commit; restart; `replay(R)` | `replay(R)` = pre-compaction `[r0, r1, r2]` (unchanged) | Crash isolation; {INV-003}, {PC-006} |
| TV-003 | Policy marks promoted record `r0` as eligible; `compact(R, policy)` | `Err(PregolyaError { code: E-TRAJ-004, category: VAL, .. })` ; `replay(R)` unchanged | Retained-record protection; {INV-004}, {PC-005} |
| TV-004 | `compact(run_id_X, policy)` where `replay(run_id_X)` = `Ok(vec![])` | `Ok(())`; `replay(run_id_X)` = `Ok(vec![])` | Empty trajectory; EC-002 |
| TV-005 | `replay(R)` = `[r0(step=0)]`; policy retains `r0` (frontier); `compact(R, policy)` | `Ok(())`; `replay(R)` = `[r0(step=0)]` (unchanged) | Single retained record; EC-003 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-COMPACT-01 | After `compact` returns `Ok(())`, every retained record appears in `replay` with identical `step_idx` and `payload` | Integration test (write N records + compact + replay) | Wave 2 |
| VP-COMPACT-02 | Crash-isolated compaction: SIGKILL mid-compaction, restart, `replay` returns pre-compaction result | Integration test (write + compact + kill + restart fixture) | Wave 2 |

> **VP candidate for architect routing:** {INV-001} (no committed retained record lost under
> compaction) is a strong safety property expressible as a proptest or Kani bounded proof
> over arbitrary compaction policies and trajectory sizes. Recommend architect evaluate
> VP-COMPACT-01 for proptest upgrade (similar to VP-017 ledger-channel pattern). Routing to
> architect per bc_array_changes_propagate_to_body_and_acs and vp_index_is_vp_catalog_source_of_truth
> policies — do not self-mint a VP entry here.

## Related BCs

- BC-2.04.009 — composes with: `TrajectoryWriter::put_record` creates the records that
  compaction operates on; `put_record` durability guarantees make the pre-compaction record
  authoritative; compaction never conflicts with in-flight `put_record` calls due to the
  atomic transaction boundary
- BC-2.04.010 — composes with: `TrajectoryReader::replay` ascending `step_idx` ordering
  invariant applies to the post-compaction retained record set; {PC-002} explicitly requires
  the sub-sequence property

## Architecture Anchors

- `pregolya-checkpoint/src/trajectory.rs` (`checkpoint::trajectory`) — `TrajectoryCompactor`
  trait (`async fn compact(&self, run_id: Uuid, policy: TrajectoryRetentionPolicy) -> Result<(), PregolyaError>`);
  concrete implementation using SQLite `BEGIN IMMEDIATE` / `COMMIT` atomic transaction;
  storage slice isolated from ADR-019 conversation-context tables
- `pregolya-core/src/trajectory.rs` (`core::trajectory`) — `TrajectoryRetentionPolicy` type definition
  (per ADR-009 definitions-in-core separation); specifies eligible vs retained record sets.
  NOTE: named `TrajectoryRetentionPolicy` rather than `CompactionPolicy` to avoid collision
  with `CompactionPolicy` from CAP-035 (rolling-context compaction in `core::budget_config`).
- ADR-030 §Decision 2 — Trajectory Compaction Isolation scope; isolation from ADR-019 rolling-context
  compaction; atomic segment-swap requirement; retained-record protection contract

## Story Anchor

S-TBD (assigned at story decomposition — Stage 3)

## VP Anchors

- VP-COMPACT-01, VP-COMPACT-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `TrajectoryCompactor` extends the trajectory storage primitive introduced in CAP-040 with a safe compaction operation that prevents unbounded storage growth while preserving audit-grade record integrity for the research orchestrator pattern |
| L2 Domain Invariants | DI-002 (Per-Task Durability: retained records survive compaction with the same durability guarantee as the initial `put_record`; no committed retained record is lost per {INV-001}), DI-004 (Monotonic Checkpoint Clock: `step_idx` ordering is preserved in the post-compaction replay sub-sequence per {INV-002}; {PC-002} enforces ascending order over retained records), DI-014 (Error Propagation — No Silent Swallowing: storage errors and policy violations propagate as `Err(PregolyaError)` per {PC-005} and {PC-006}; no `Ok(())` is returned unless compaction completed correctly) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | pregolya-checkpoint |
