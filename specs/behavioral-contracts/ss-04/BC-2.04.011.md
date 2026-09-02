---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.011
version: "1.8"
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
  - "1.2 (round-50/Stage-B1-product-owner/2026-08-31): {PRE-001} reconciled to single-file SQLite WAL topology (ADR-030 §SQLite Topology Decision/F-P2A209-04). {INV-003} updated to VP-019 canonical wording (either complete pre-compaction OR complete post-compaction state visible after crash — previously stated pre-compaction only, ignoring committed after-sync case). {INV-005} rescoped to record-level table isolation + WAL non-blocking behavior + bounded compaction batch (1,000 records/BEGIN IMMEDIATE); dropped absolute 'cannot interfere' claim that ignores write serialization. {INV-006} added: at-rest encryption mirrored from BC-2.04.009 {INV-002} — compacted retained records remain encrypted when EncryptedSerializer is configured. §Verification Properties: VP-COMPACT-01→VP-018 (proptest, {INV-001} retention integrity), VP-COMPACT-02→VP-019 (integration, {INV-003} crash-isolation). Routing blockquote deleted (VP-018/019 are minted). §VP Anchors updated to VP-018, VP-019."
  - "1.3 (round-51/Stage-B2-product-owner/2026-08-31): §Story Anchor resolved: S-2.12 (per STORY-INDEX; F-P2A214-01 hook #19 compliance)."
  - "1.4 (round-52/F-P2A216-01+F-P2A216-03+F-P2A217-03+F-P2A216-05+F-P2A219-01/2026-08-31): Combined architectural corrections. (1) {PC-005}/{INV-004}/EC-004/TV-003 REMOVED — E-TRAJ-004 TrajectoryRetainedEligible was structurally unreachable: `TrajectoryRetentionPolicy` derives eligible/retained as complements by construction; a policy cannot simultaneously mark a record as both retained and eligible. The condition {PC-005} described could never be reached at `compact` call time. E-TRAJ-004 retired in error-taxonomy.md (tombstone). (2) {PC-006} wired to E-TRAJ-005 TrajectoryCompactionFailed (DURABILITY, broken, Maybe-retry) — minted in error-taxonomy.md for SQLite backend I/O error / disk-full / transaction abort before commit; pre-compaction state intact (uncommitted WAL frames discarded on next open). (3) {INV-003} WAL-mode wording: replaced 'SQLite rollback journal restores pre-compaction state' with canonical WAL behaviour (no rollback journal in WAL mode; uncommitted WAL frames after last commit marker are discarded by SQLite on next database open). (4) {PRE-002} frontier definition: replaced vague example with architect canonical wording (step_idx strictly < retention_frontier and not in promoted are eligible; step_idx >= retention_frontier (frontier record where step_idx == retention_frontier retained) and all promoted records retained; retention_frontier is exclusive lower bound for eligibility). (5) Traceability DI-014 citation updated: removed stale {PC-005} reference; {PC-006} reference updated to cite E-TRAJ-005. TV count 5→4 (TV-003 removed). TRAJ namespace: E-TRAJ-004 retired, E-TRAJ-005 minted (net-neutral; census stays 142)."
  - "1.5 (round-53/F-P2A221-01/2026-08-31): {PC-004} redefined as reader-visible atomicity — replay always observes complete pre- or post-compaction state, never a partial intermediate. {INV-003} amended — staging-table atomicity boundary explicit: the atomicity boundary is the swap-phase BEGIN IMMEDIATE / COMMIT that renames trajectory_records_staging to trajectory_records; a crash during the build phase leaves trajectory_records fully intact (staging table dropped on recovery); WAL-mode wording preserved for crash point. {INV-005} bounded-batch scope clarified to build phase on the staging table; swap-phase is a single brief atomic commit. Architecture Anchors and Description updated to reflect staging-table atomic-swap strategy."
  - "1.6 (round-53/F-P2A221-01-corrective/2026-08-31): Corrective micro-fix for VP-019 four-crash-point coherence. {INV-003} 'Verified by VP-019' clause updated from three-crash-point matrix (before-begin, mid-txn, after-sync) to authoritative four-crash-point matrix per VP-019 §four-crash-point matrix and ADR-030 §Compaction Atomicity Decision: (1) before-build-begins, (2) mid-build (staging partially filled before swap), (3) mid-swap-transaction (after BEGIN IMMEDIATE, before COMMIT), (4) after-swap-commit. §Verification Properties VP-019 row updated to match (three crash points / three cases → four crash points / four cases). No other content changes."
  - "1.7 (round-62/F-P2A234-01+F-P2A234-02/2026-09-01): Compaction mechanism redesigned from staging-table atomic-swap to per-run single-transaction DELETE per ADR-030 §Decision 2 (round-62 update). §Description: staging-table strategy replaced with `BEGIN IMMEDIATE; DELETE FROM trajectory_records WHERE run_id = :run_id AND step_idx < :retention_frontier AND step_idx NOT IN (:promoted_step_idxs); COMMIT;`; run_id filter preserves all other runs' records — scope-safety explicit (F-P2A234-01); `BEGIN IMMEDIATE` write-lock serializes concurrent `put_record` — no build→swap window, no clobber possible (F-P2A234-02). {PRE-002}: `promoted` explicitly typed as `Vec<u64>` of `step_idx` values; entries below the frontier listed in `promoted` are retained (OBS-3). {INV-003}: four-crash-point staging matrix replaced with two-crash-point DELETE matrix (before-COMMIT → complete pre-compaction state; after-COMMIT → complete post-compaction state); atomicity boundary is the single `BEGIN IMMEDIATE`/`COMMIT` DELETE transaction; no staging table. {INV-005}: bounded-batch (1,000 records/batch, staging-table) parenthetical removed; concurrency semantics restated: `BEGIN IMMEDIATE` write-lock serializes `put_record` (a `put_record` either fully precedes or fully follows the DELETE; no clobber; the prior build→swap window no longer exists). OBS-2 note added: deletion-tamper-evidence explicitly OUT OF SCOPE for v1 per ADR-030 §Deletion Tamper-Evidence Decision. §Related BCs BC-2.04.009 sentence rewritten to true guarantee (concurrent `put_record` serialized by `BEGIN IMMEDIATE` write-lock). §Architecture Anchors first anchor updated to per-run DELETE mechanism. VP-019 Verification Properties updated from four-crash-point to two-crash-point matrix."
  - "1.8 (round-63/F-P2A235-02/2026-09-01): §Architecture Anchors third anchor retired-model residue fixed: 'atomic segment-swap requirement' replaced with per-run single-transaction DELETE atomicity requirement (single `BEGIN IMMEDIATE`/`COMMIT` DELETE scoped to run_id; reader-visible atomic; no staging table; no segment-swap). Normative-text sweep result: all other 'swap'/'staging' occurrences in the BC body (lines describing 'no build→swap window', 'no staging table') correctly describe the ABSENCE of those mechanics and required no change — sole normative residue was the third anchor."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-040
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "df596f3"
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
preserved intact and in ascending `step_idx` order. Compaction is atomic — it uses a per-run single-transaction DELETE:
`BEGIN IMMEDIATE; DELETE FROM trajectory_records WHERE run_id = :run_id AND step_idx < :retention_frontier AND step_idx NOT IN (:promoted_step_idxs); COMMIT;`.
The `run_id` filter preserves all records for every other run — only eligible records belonging
to the compacted run are removed, so compaction of different runs is inherently scope-safe
(F-P2A234-01). The `BEGIN IMMEDIATE` write-lock acquired at transaction start serializes any
concurrent `put_record` calls for the duration of the DELETE — a `put_record` either fully
precedes or fully follows the compaction transaction; no build→swap window exists and no clobber
is possible (F-P2A234-02). The crash matrix collapses to two points: a SIGKILL before the
`COMMIT` leaves the pre-compaction state fully intact (uncommitted WAL frames discarded by
SQLite on next open); a SIGKILL after the `COMMIT` leaves the post-compaction state. Records
designated as retained (promoted or at the frontier) are never eligible for removal. The operation enables long-running
research orchestrator sessions to prevent unbounded storage growth without compromising
audit-grade record integrity.

## Preconditions

1. {PRE-001} A `TrajectoryCompactor` implementation exists, backed by the dedicated
   `trajectory_records` table within the same single-file SQLite database as `CheckpointSaver`
   and `TrajectoryWriter` / `TrajectoryReader` (BC-2.04.009, BC-2.04.010), operated in WAL
   mode (ADR-030 §SQLite Topology Decision).
2. {PRE-002} The caller supplies a `TrajectoryRetentionPolicy` value specifying which records are
   eligible for removal: records with `step_idx` strictly less than `retention_frontier` and not
   in `promoted` are eligible; records with `step_idx >= retention_frontier` (the frontier record
   where `step_idx == retention_frontier` is retained) and all `promoted` records are retained;
   `retention_frontier` is an exclusive lower bound for eligibility. `promoted` is a
   `Vec<u64>` of `step_idx` values; records with `step_idx < retention_frontier` that appear
   in `promoted` are retained even though they fall below the frontier.
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
4. {PC-004} Compaction is reader-visible-atomic: `replay(run_id)` always observes either the
   complete pre-compaction state or the complete post-compaction state — never an intermediate
   partial compaction. Either all eligible records are removed and all retained records are
   preserved (`Ok(())`), or no change is observable through `replay` and an `Err(PregolyaError)`
   is returned. No intermediate partial state is ever visible through `replay`.
5. {PC-006} Storage errors (backend I/O failure, transaction abort, disk full) propagate as
   `Err(PregolyaError { code: E-TRAJ-005, message: "TrajectoryCompactionFailed: compact for run_id='<run_id>' failed — <backend_error>", category: DURABILITY, .. })`.
   After any such error, `replay(run_id)` returns the same result as before the attempted
   compaction — the pre-compaction state is fully intact (uncommitted WAL frames from the
   incomplete transaction are discarded by SQLite on the next database open).

## Invariants

- {INV-001} **No committed retained record is lost or mutated.** For any `(run_id, step_idx)`
  pair that `replay(run_id)` returned before compaction AND whose record is designated as
  retained by the policy, that exact `TrajectoryRecord` (same `step_idx`, `event_kind`,
  `payload`) appears in `replay(run_id)` after compaction.
- {INV-002} **Replay determinism is preserved for retained records.** The post-compaction
  replay order is a strict ascending sub-sequence of the pre-compaction order. No retained
  record changes its relative position or `step_idx` value.
- {INV-003} **Compaction is crash-isolated (atomic transaction boundary).** A SIGKILL
  delivered at any point during `compact(run_id, policy)` leaves `replay(run_id)` in a
  consistent state: either the **complete pre-compaction replay** (if the `BEGIN IMMEDIATE`
  DELETE transaction did not commit before the kill) or the **complete post-compaction replay**
  (if the transaction committed before the kill). No partial compaction state — some eligible
  records removed and some not — is ever observable. In WAL mode, uncommitted WAL frames after
  the last commit marker are discarded by SQLite on the next database open, restoring the
  pre-compaction state (no rollback journal is used in WAL mode). The atomicity boundary is
  the single `BEGIN IMMEDIATE; DELETE ...; COMMIT` transaction — there is no build phase, no
  staging table, and no rename operation; the crash matrix collapses to two points:
  before-COMMIT (kill before `COMMIT` written to WAL → pre-compaction state intact) and
  after-COMMIT (kill after `COMMIT` written to WAL → post-compaction state). Verified by
  VP-019 (integration, two-crash-point matrix: before-COMMIT, after-COMMIT).
- {INV-005} **Record-level table isolation from ADR-019.** Trajectory compaction operates on
  the `trajectory_records` table only; it has no access to and does not affect the
  conversation-context checkpoint tables (`checkpoint_*`) managed by `CheckpointSaver`
  (ADR-019). The two storage paths are isolated at the table level — no FK joins, no shared
  table operations. WAL mode on the shared database file enables concurrent reads from WAL
  snapshots without blocking writes. The `BEGIN IMMEDIATE` write-lock acquired by the DELETE
  transaction serializes any concurrent `put_record` call: a `put_record` either fully precedes
  the compaction transaction (completes before `BEGIN IMMEDIATE` is issued) or fully follows it
  (blocks until `COMMIT` is written and then proceeds); no clobber is possible and no
  build→swap window exists (ADR-030 §SQLite Topology Decision). There is no staging table and
  no batching; the single DELETE transaction operates directly on `trajectory_records`.
- {INV-006} **At-rest encryption preserved across compaction.** When `EncryptedSerializer`
  is configured in the `checkpoint::trajectory` implementation, the retained records written
  back to `trajectory_records` after compaction MUST remain in their encrypted form.
  Compaction MUST NOT rewrite retained record payloads in plaintext — the encryption boundary
  is enforced at the storage layer, not the policy layer (mirrors BC-2.04.009 {INV-002}).

> **Deletion Tamper-Evidence (Out of Scope for v1):** The per-run DELETE mechanism provides no
> cryptographic evidence of correct deletion (no deletion log, Merkle update, or proof of
> erasure). Tamper-evidence for compaction events is explicitly OUT OF SCOPE for v1 per
> ADR-030 §Deletion Tamper-Evidence Decision. A future hardening cycle may address this if
> audit-grade deletion accountability requirements expand.

## Edge Cases

### EC-001: Crash during compaction — pre-compaction record survives
**Scenario:** `compact(run_id, policy)` begins executing. The process is killed (SIGKILL /
OS crash) mid-transaction, before the atomic commit completes.
**Expected behavior:** After process restart, `replay(run_id)` returns the exact set of
records that were present before `compact` was called. In WAL mode, the uncommitted WAL
frames from the in-progress transaction are discarded by SQLite on the next database open.
No partial compaction result is visible.

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

### EC-005: Compaction frontier equals the highest committed step_idx — retain only the frontier
**Scenario:** `replay(run_id)` returns `[r0, r1, r2]` with `step_idx` = 0, 1, 2. The
policy marks `r0` and `r1` as eligible and `r2` (the frontier) as retained.
**Expected behavior:** `compact` returns `Ok(())`. `replay(run_id)` returns `[r2]` — the
single retained record — in ascending `step_idx` order ({PC-002}).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `replay(R)` = `[r0(step=0), r1(step=1), r2(step=2)]`; policy retains `r2`, marks `r0`/`r1` eligible; `compact(R, policy)` | `Ok(())`; `replay(R)` = `[r2(step=2)]` in ascending order | Happy-path compaction; {PC-001}, {PC-002}, {PC-003} |
| TV-002 | `compact(R, policy)` begins; process SIGKILL before transaction commit; restart; `replay(R)` | `replay(R)` = pre-compaction `[r0, r1, r2]` (unchanged) | Crash isolation; {INV-003}, EC-001 |
| TV-004 | `compact(run_id_X, policy)` where `replay(run_id_X)` = `Ok(vec![])` | `Ok(())`; `replay(run_id_X)` = `Ok(vec![])` | Empty trajectory; EC-002 |
| TV-005 | `replay(R)` = `[r0(step=0)]`; policy retains `r0` (frontier); `compact(R, policy)` | `Ok(())`; `replay(R)` = `[r0(step=0)]` (unchanged) | Single retained record; EC-003 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-018 | For any trajectory and any retention policy, after `compact` returns `Ok(())`, every retained record appears in `replay` with identical `step_idx` and `payload`; retained set is the oracle-defined sub-sequence; eligible records are absent | proptest (harness `trajectory_compaction_retention_integrity`; independent oracle using `>=` + OR vs `is_eligible` `<` + AND + NOT — {INV-001}, {INV-002}, {PC-001}, {PC-002}, {PC-003}) | Phase 3 |
| VP-019 | Crash-isolated compaction: SIGKILL at either of two crash points (before-COMMIT (kill before `COMMIT` written to WAL), after-COMMIT (kill after `COMMIT` written to WAL)), restart, `replay` returns complete pre-compaction or complete post-compaction state — no partial compaction observable | Integration test (subprocess SIGKILL fixture, two cases, real SQLite WAL — {INV-003}, TV-002) | Phase 6 |

## Related BCs

- BC-2.04.009 — composes with: `TrajectoryWriter::put_record` creates the records that
  compaction operates on; `put_record` durability guarantees make the pre-compaction record
  authoritative; concurrent `put_record` calls during compaction are serialized by the
  compaction transaction's `BEGIN IMMEDIATE` write-lock — a `put_record` either fully precedes
  or fully follows the DELETE transaction; no clobber is possible (the prior build→swap window
  no longer exists)
- BC-2.04.010 — composes with: `TrajectoryReader::replay` ascending `step_idx` ordering
  invariant applies to the post-compaction retained record set; {PC-002} explicitly requires
  the sub-sequence property

## Architecture Anchors

- `pregolya-checkpoint/src/trajectory.rs` (`checkpoint::trajectory`) — `TrajectoryCompactor`
  trait (`async fn compact(&self, run_id: Uuid, policy: TrajectoryRetentionPolicy) -> Result<(), PregolyaError>`);
  concrete implementation using a per-run single-transaction DELETE:
  `BEGIN IMMEDIATE; DELETE FROM trajectory_records WHERE run_id = :run_id AND step_idx < :retention_frontier AND step_idx NOT IN (:promoted_step_idxs); COMMIT;`;
  run_id filter preserves all records for other runs (scope-safe per F-P2A234-01);
  `BEGIN IMMEDIATE` write-lock serializes concurrent `put_record` calls (F-P2A234-02);
  crash matrix: before-COMMIT → pre-compaction state intact (uncommitted WAL frames discarded
  on next open); after-COMMIT → post-compaction state; no staging table; no batching;
  storage slice isolated from ADR-019 conversation-context tables
- `pregolya-core/src/trajectory.rs` (`core::trajectory`) — `TrajectoryRetentionPolicy` type definition
  (per ADR-009 definitions-in-core separation); specifies eligible vs retained record sets.
  NOTE: named `TrajectoryRetentionPolicy` rather than `CompactionPolicy` to avoid collision
  with `CompactionPolicy` from CAP-035 (rolling-context compaction in `core::budget_config`).
- ADR-030 §Decision 2 — Trajectory Compaction Isolation scope; isolation from ADR-019 rolling-context
  compaction; per-run single-transaction DELETE atomicity requirement (single `BEGIN IMMEDIATE`/`COMMIT`
  DELETE scoped to run_id; reader-visible atomic; no staging table; no segment-swap); retained-record
  protection contract

## Story Anchor

S-2.12

## VP Anchors

- VP-018 (proptest, {INV-001} retention integrity — no retained record lost or mutated)
- VP-019 (integration, {INV-003} crash-isolation — SQLite atomicity under SIGKILL)

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `TrajectoryCompactor` extends the trajectory storage primitive introduced in CAP-040 with a safe compaction operation that prevents unbounded storage growth while preserving audit-grade record integrity for the research orchestrator pattern |
| L2 Domain Invariants | DI-002 (Per-Task Durability: retained records survive compaction with the same durability guarantee as the initial `put_record`; no committed retained record is lost per {INV-001}), DI-004 (Monotonic Checkpoint Clock: `step_idx` ordering is preserved in the post-compaction replay sub-sequence per {INV-002}; {PC-002} enforces ascending order over retained records), DI-014 (Error Propagation — No Silent Swallowing: storage errors propagate as `Err(E-TRAJ-005 PregolyaError)` per {PC-006}; no `Ok(())` is returned unless compaction completed correctly) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | pregolya-checkpoint |
