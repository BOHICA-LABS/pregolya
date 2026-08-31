---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.010
version: "1.2"
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
  - "1.0 (ADR-030 Stage 2a/2026-08-31): Initial greenfield spec — TrajectoryReader::replay ascending step_idx ordering; DI-004 + DI-014 invariant enforcement; ADR-030 Decision 2."
  - "1.1 (ADR-030/Stage-3.5-product-owner/2026-08-31): EC-004 category corrected INTERNAL→DURABILITY (E-TRAJ-003 minted as DURABILITY; read failures are DURABILITY per taxonomy convention matching E-CHKPT-003)."
  - "1.2 (round-50/Stage-B1-product-owner/2026-08-31): VP-TRAJ-01 phantom label relabeled TST-TRAJ-01 in §Verification Properties; removed from §VP Anchors (not a registered VP — durability-after-restart integration test concept only; no real VP covers BC-2.04.010 yet)."
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

# BC-2.04.010: TrajectoryReader::replay Ascending step_idx Order

## Description

`TrajectoryReader::replay(run_id: Uuid) -> Result<Vec<TrajectoryRecord>, PregolyaError>`
returns all `TrajectoryRecord`s previously committed for the given `run_id` via
`TrajectoryWriter::put_record` (BC-2.04.009). The returned `Vec<TrajectoryRecord>` is sorted
in strictly ascending order of `step_idx` — the logical-clock position at which each record
was emitted. This ordering mirrors the checkpoint-clock monotonicity invariant (DI-004) and
enables deterministic replay of a run's full audit trail. If no records exist for the given
`run_id`, `Ok(vec![])` is returned without error.

## Preconditions

1. {PRE-001} A concrete `impl TrajectoryReader` (backed by the same storage tier as
   `TrajectoryWriter`) has been constructed.
2. {PRE-002} `run_id: Uuid` is a valid non-nil UUID identifying the research run to replay.
3. {PRE-003} Zero or more `TrajectoryRecord`s have been durably committed for `run_id` via
   `TrajectoryWriter::put_record` (BC-2.04.009 {PC-001}).

## Postconditions

1. {PC-001} `replay(run_id)` returns `Ok(Vec<TrajectoryRecord>)` where the `Vec` contains
   every `TrajectoryRecord` whose `run_id` field equals the supplied `run_id` argument.
   Records belonging to other `run_id` values are excluded.
2. {PC-002} The returned `Vec<TrajectoryRecord>` is sorted in **strictly ascending order** by
   `step_idx`. For any adjacent elements `records[i]` and `records[i+1]`:
   `records[i].step_idx < records[i+1].step_idx`.
3. {PC-003} The returned `Vec` is **complete**: every record committed via `put_record` for
   the given `run_id` (and for which `put_record` returned `Ok(())`) appears in the result.
   No record is silently omitted.
4. {PC-004} If no records have been committed for the given `run_id`, `replay` returns
   `Ok(vec![])`. An unknown or unused `run_id` is not an error condition.
5. {PC-005} Storage errors (backend I/O failure, connection loss) propagate as
   `Err(PregolyaError)`. A partial read that cannot guarantee completeness is not returned
   as `Ok`; the caller may retry.

## Invariants

- {INV-001} **Ordering is by step_idx, not by wall-clock write time.** `step_idx` is sourced
  from the checkpoint's monotonic logical clock (DI-004). Two records with adjacent `step_idx`
  values may have been written in any wall-clock order; `replay` always returns them in
  `step_idx` ascending order regardless.
- {INV-002} **Deterministic across replays:** calling `replay(run_id)` multiple times returns
  the same ordered `Vec<TrajectoryRecord>` (assuming no new `put_record` calls have been made
  between the calls). The result is deterministic and not dependent on internal cursor state.
- {INV-003} **Completeness is absolute:** the `Vec` is not paginated, truncated, or
  sampled. All records for the `run_id` are returned in a single call. If the number of
  records for a run becomes impractically large, the caller is responsible for managing
  pagination at the application layer.

## Edge Cases

### EC-001: No records for the given run_id
**Scenario:** `replay(run_id_X)` is called before any `put_record` for `run_id_X`, or for a
`run_id` that was never used.
**Expected behavior:** `Ok(vec![])`. Not an error.

### EC-002: Records were written out of step_idx order
**Scenario:** `put_record` was called with `step_idx = 3` before `step_idx = 1` (due to out-
of-order node completion in the orchestrator). Both records belong to the same `run_id`.
**Expected behavior:** `replay(run_id)` returns `[record(step_idx=1), record(step_idx=3)]` —
in ascending `step_idx` order, regardless of the order in which they were written.

### EC-003: Records for multiple run_ids in the same store
**Scenario:** The `TrajectoryWriter` was used for `run_id_A` (5 records) and `run_id_B`
(3 records). `replay(run_id_A)` is called.
**Expected behavior:** Returns exactly 5 records for `run_id_A` in ascending `step_idx` order.
No records for `run_id_B` appear in the result.

### EC-004: Storage error during replay
**Scenario:** The SQLite backend encounters an I/O error while reading trajectory records.
**Expected behavior:** `replay` returns
`Err(PregolyaError { code: E-TRAJ-003, message: "TrajectoryReadFailed: replay for run '<run_id>' failed — backend error: <backend_error>", category: DURABILITY, .. })`.
No partial `Vec` is returned as `Ok`; the caller knows the result is incomplete and must
decide whether to retry or abort.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Write `r0(step_idx=0)`, `r1(step_idx=2)`, `r2(step_idx=1)` for `run_id R`; call `replay(R)` | `Ok([r0(0), r2(1), r1(2)])` — sorted ascending by step_idx | Out-of-write-order sorted on read; {PC-002} |
| TV-002 | `replay(unknown_run_id)` where no records exist | `Ok(vec![])` | Unknown run_id returns empty; {PC-004} |
| TV-003 | Write 3 records for `run_id_A`, 2 for `run_id_B`; `replay(run_id_A)` | `Ok([r_A0, r_A1, r_A2])` — only run_id_A records | Multi-run isolation; {PC-001} |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| TST-TRAJ-01 | `put_record` followed by process restart: `replay` returns all committed records | Integration test (write + kill + restart fixture) — not a registered VP | Wave 2 |

## Related BCs

- BC-2.04.009 — composes with: `put_record` durability is the write guarantee that makes `replay` return complete results; this BC specifies the ordering of what BC-2.04.009 writes
- BC-2.04.003 — depends on: `step_idx` is sourced from the monotonic checkpoint clock (DI-004); DI-004 ensures `step_idx` is a reliable sort key
- BC-2.04.008 — related to: `fts_search` is also a read path over checkpoint storage; trajectory `replay` is a separate, ordering-by-logical-clock read path with different semantics

## Architecture Anchors

- `pregolya-core/src/trajectory.rs` (`core::trajectory`) — `TrajectoryReader` trait; `async fn replay(&self, run_id: Uuid) -> Result<Vec<TrajectoryRecord>, PregolyaError>`
- `pregolya-checkpoint/src/trajectory.rs` (`checkpoint::trajectory`) — concrete `impl TrajectoryReader`; SQL ORDER BY step_idx ASC enforces ascending ordering; storage slice is isolated from the conversation-context checkpoint tables
- ADR-030 §Decision 2 — `TrajectoryReader::replay` contract; `step_idx` as logical-clock position; isolation from compaction

## Story Anchor

S-TBD (assigned at story decomposition — Stage 3)

## VP Anchors

None

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `TrajectoryReader::replay` is the read API for the trajectory primitive introduced in CAP-040; this BC specifies the ordering guarantee (ascending step_idx) that makes the trajectory an ordered audit log suitable for reproducibility review |
| L2 Domain Invariants | DI-004 (Monotonic Checkpoint Clock: `step_idx` is a monotonically increasing logical-clock value — using it as the sort key in `replay` produces a well-defined, unambiguous ordering per {INV-001}), DI-014 (Error Propagation — No Silent Swallowing: storage errors propagate as `Err(PregolyaError)` per {PC-005}; a partial result is not returned as `Ok`) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | pregolya-checkpoint |
