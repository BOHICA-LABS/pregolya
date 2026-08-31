---
document_type: story
level: ops
story_id: S-2.12
epic_id: E-05
version: "1.2"
status: draft
producer: story-writer
timestamp: 2026-08-31T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.009.md
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.010.md
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.011.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "d04ebe2"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.10]
blocks: []
behavioral_contracts: [BC-2.04.009, BC-2.04.010, BC-2.04.011]
verification_properties: [VP-018, VP-019]
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-checkpoint
subsystems: [SS-04]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
changelog:
  - "1.2 (Round-51-Phase-2-fix-burst/2026-08-31): F-P2A212-04: encryption changed to OPT-IN model per BC-2.04.009 INV-002; optional Serializer wired at construction; payload-only serialization; event_kind stays cleartext per PRE-002; no fail-closed guard; re-anchor from PC-001 to INV-002 in AC-002 and Rule 13. F-P2A212-01 follow-on: AC-001/AC-014/Tasks cite TrajectoryRecord::new and TrajectoryRetentionPolicy::new constructors with exact signatures; Rule 14 added for cross-crate constructor requirement."
  - "1.1 (Round-50-Phase-2-fix-burst/2026-08-31): Fix error categories to canonical DURABILITY/VAL per TRAJ taxonomy (AC-005/007/011/019); add VP-019 crash-isolation integration anchor; add #[async_trait] dyn-compatibility rule; add EncryptedSerializer at-rest requirement for put_record; add WAL-mode crash-isolation rule for compact; correct BC-2.04.010 table title to match BC H1; add uuid serde feature requirement; reword TRAJ taxonomy task from mint to verify-canonical."
  - "1.0 (praxist-Stage-3/2026-08-31): Initial authoring — Durable Audit Trajectory and Compaction Isolation; core::trajectory type definitions (pregolya-core) + checkpoint::trajectory concrete impl (pregolya-checkpoint); BC-2.04.009 + BC-2.04.010 + BC-2.04.011; VP-018 proptest P1 anchor; Wave 2 / E-05 extension; depends on S-1.10."
---

> **tdd_mode:** strict — full TDD Iron Law enforced. Write all failing tests before writing any implementation. VP-018 proptest and integration tests for process-restart durability (BC-2.04.009 {PC-003}) and crash-isolated compaction (BC-2.04.011 {INV-003}) must be red before implementation begins.

> **Execute:** `/vsdd-factory:deliver-story S-2.12`

# S-2.12: Durable Audit Trajectory — Writer, Reader, and Compaction Isolation

## Narrative

- **As a** research-orchestrator runtime developer building on the CAP-040 trajectory primitive
- **I want to** write durable `TrajectoryRecord`s via `TrajectoryWriter::put_record`, replay them in ascending `step_idx` order via `TrajectoryReader::replay`, and compact an unbounded audit trail via `TrajectoryCompactor::compact` with full crash isolation
- **So that** research-orchestrator sessions have an audit-grade, compaction-safe record of every generation event that survives process restarts and is isolated from `CheckpointSaver` rolling-context compaction (ADR-019)

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.04.009 | TrajectoryWriter::put_record Durability | AC-001..AC-007 |
| BC-2.04.010 | TrajectoryReader::replay Ascending step_idx Order | AC-008..AC-013 |
| BC-2.04.011 | Trajectory Compaction Isolation | AC-014..AC-021 |

## Acceptance Criteria

### AC-001 (traces to BC-2.04.009 PRE-001 / PRE-002 — TrajectoryRecord struct and core::trajectory type definitions)
`pregolya-core/src/trajectory.rs` declares `#[non_exhaustive] TrajectoryRecord` with fields `run_id: uuid::Uuid`, `step_idx: u64`, `event_kind: String`, `payload: serde_json::Value`, and provides the constructor `TrajectoryRecord::new(run_id: Uuid, step_idx: u64, event_kind: impl Into<String>, payload: serde_json::Value) -> TrajectoryRecord`. Because the type carries `#[non_exhaustive]`, cross-crate callers and tests MUST use this constructor — struct literal construction will not compile outside `pregolya-core`. The `TrajectoryWriter` trait declares `async fn put_record(&self, record: TrajectoryRecord) -> Result<(), PregolyaError>`. The `TrajectoryReader` trait declares `async fn replay(&self, run_id: uuid::Uuid) -> Result<Vec<TrajectoryRecord>, PregolyaError>`. The `TrajectoryRetentionPolicy` type is declared in the same module per ADR-009 definitions-in-core. Verified by `test_BC_2_04_009_trajectory_types_exist()`.

### AC-002 (traces to BC-2.04.009 PC-001 / INV-002 — put_record returns Ok(()) on successful commit; opt-in encryption)
`put_record(record)` returns `Ok(())` when the record has been durably committed to the backing `checkpoint::trajectory` SQLite slice. Encryption is OPT-IN per BC-2.04.009 {INV-002}: `SqliteTrajectoryStore` accepts an `Option<Arc<dyn Serializer + Send + Sync>>` at construction. When a serializer is wired, `TrajectoryRecord::payload` is serialized via that serializer before the SQLite write; `event_kind` is persisted as cleartext because it is a discriminator field per BC-2.04.009 {PRE-002}. When no serializer is provided, payload is persisted as-is — there is NO fail-closed guard. No `Ok(())` is returned unless the record is durably committed. Verified by `test_BC_2_04_009_put_record_returns_ok_on_commit()`.

### AC-003 (traces to BC-2.04.009 PC-002 — record visible in replay after put_record Ok)
After `put_record(record_A)` returns `Ok(())`, `replay(record_A.run_id)` returns a `Vec<TrajectoryRecord>` containing `record_A` (matched by `run_id` + `step_idx` pair). Verified by `test_BC_2_04_009_put_then_replay_contains_record()`.

### AC-004 (traces to BC-2.04.009 PC-003 — durability survives process restart — RED GATE)
After `put_record(record_A)` returns `Ok(())`, a process restart (new `SqliteTrajectoryStore` pointing to the same database file) does not cause `record_A` to be absent from `replay(record_A.run_id)`. This test MUST be written first and MUST fail on stubs before implementation (Red Gate discipline — the stub will likely return `Ok(vec![])` after "restart"). Verified by `test_BC_2_04_009_durability_survives_restart()` (integration test; uses a temp SQLite file on disk).

### AC-005 (traces to BC-2.04.009 PC-004 — storage errors propagate as Err, no silent data loss)
When the underlying SQLite layer returns an error during `put_record`, the method returns `Err(PregolyaError { category: DURABILITY, code: "E-TRAJ-001", .. })`. No `Ok(())` is returned on a failed write. Verified by `test_BC_2_04_009_storage_error_returns_err()`.

### AC-006 (traces to BC-2.04.009 PC-005 — trajectory records isolated from ADR-019 compaction)
A compaction event on the `CheckpointSaver` conversation-context window (ADR-019 `OnWatermark` trigger) does NOT remove or modify any `TrajectoryRecord`. After a simulated compaction, `replay(run_id)` returns the same records as before compaction. Verified by `test_BC_2_04_009_records_survive_checkpoint_compaction()`.

### AC-007 (traces to BC-2.04.009 INV-001 — write-once per (run_id, step_idx); idempotent on matching payload)
Calling `put_record` twice with the same `(run_id, step_idx)` and identical payload is idempotent: returns `Ok(())` and `replay` contains exactly one copy. Calling `put_record` a second time with the same `(run_id, step_idx)` but a DIFFERENT payload returns `Err(PregolyaError { category: VAL, code: "E-TRAJ-002", .. })` to preserve audit integrity. Verified by `test_BC_2_04_009_idempotent_matching_payload_and_error_on_conflict()`.

### AC-008 (traces to BC-2.04.010 PC-001 — replay returns all records for run_id, no cross-run contamination)
`replay(run_id_A)` returns only records whose `run_id` field equals `run_id_A`. Records belonging to other `run_id` values are excluded. Verified by `test_BC_2_04_010_replay_returns_only_matching_run_id()`.

### AC-009 (traces to BC-2.04.010 PC-002 — returned Vec is sorted ascending by step_idx)
The `Vec<TrajectoryRecord>` returned by `replay` is sorted in **strictly ascending order** by `step_idx`. For any adjacent elements `records[i]` and `records[i+1]`, `records[i].step_idx < records[i+1].step_idx`. This order holds even when records were written out of `step_idx` order. Verified by `test_BC_2_04_010_replay_ascending_step_idx()`.

### AC-010 (traces to BC-2.04.010 PC-004 — replay of unknown run_id returns Ok(vec![]))
`replay(run_id_X)` for a `run_id` that has never had any `put_record` call returns `Ok(vec![])`. An unknown `run_id` is not an error condition. Verified by `test_BC_2_04_010_unknown_run_id_returns_empty()`.

### AC-011 (traces to BC-2.04.010 PC-005 — storage errors propagate as Err)
When the SQLite backend returns an I/O error during `replay`, the method returns `Err(PregolyaError { category: DURABILITY, code: "E-TRAJ-003", .. })`. No partial `Vec` is returned as `Ok`. Verified by `test_BC_2_04_010_storage_error_returns_err()`.

### AC-012 (traces to BC-2.04.010 INV-002 — replay is deterministic across multiple calls)
Calling `replay(run_id)` multiple times (with no intervening `put_record` calls) returns the same ordered `Vec<TrajectoryRecord>` each time. Verified by `test_BC_2_04_010_replay_is_deterministic()`.

### AC-013 (traces to BC-2.04.010 INV-003 — replay is complete, not paginated)
All records for the `run_id` are returned in a single call. No pagination, truncation, or sampling is performed by the implementation. Verified by `test_BC_2_04_010_replay_is_complete_not_paginated()` (writes 100 records, verifies all 100 returned).

### AC-014 (traces to BC-2.04.011 PRE-001 / PRE-002 — TrajectoryCompactor trait and TrajectoryRetentionPolicy type)
`checkpoint::trajectory` declares the `TrajectoryCompactor` trait with `async fn compact(&self, run_id: uuid::Uuid, policy: TrajectoryRetentionPolicy) -> Result<(), PregolyaError>`. `TrajectoryRetentionPolicy` (in `core::trajectory` per ADR-009) specifies which records are eligible for removal vs retained, and provides the constructor `TrajectoryRetentionPolicy::new(retention_frontier: u64, promoted: Vec<u64>) -> TrajectoryRetentionPolicy`. Because the type carries `#[non_exhaustive]`, cross-crate callers and tests MUST use this constructor — struct literal construction will not compile outside `pregolya-core`. Verified by `test_BC_2_04_011_compactor_trait_exists()`.

### AC-015 (traces to BC-2.04.011 PC-001 — retained records survive compact intact)
After `compact(run_id, policy)` returns `Ok(())`, every record designated as retained by the policy is still present in `replay(run_id)` with its original `step_idx`, `event_kind`, and `payload` values unchanged. Verified by `test_BC_2_04_011_retained_records_survive_compact()`.

### AC-016 (traces to BC-2.04.011 PC-002 — post-compact replay is ascending step_idx sub-sequence)
`replay(run_id)` after `Ok(())` from `compact` returns all retained records in strictly ascending `step_idx` order. The post-compaction sequence is a strict ascending sub-sequence of the pre-compaction sequence (no retained record changes `step_idx` or relative position). Verified by `test_BC_2_04_011_post_compact_replay_ascending_subsequence()`.

### AC-017 (traces to BC-2.04.011 PC-003 — eligible records absent after compact)
Records designated as eligible for removal by the policy are absent from `replay(run_id)` after `compact` returns `Ok(())`. No eligible record survives compaction. Verified by `test_BC_2_04_011_eligible_records_absent_after_compact()`.

### AC-018 (traces to BC-2.04.011 PC-004 — compaction is atomic; no partial state on error)
After any error from `compact` (storage error, policy violation), `replay(run_id)` returns the exact same result as before the attempted compaction. No partial compaction state is observable. Verified by `test_BC_2_04_011_compact_error_leaves_trajectory_intact()`.

### AC-019 (traces to BC-2.04.011 PC-005 — policy attempting to mark retained record as eligible returns Err VAL — RED GATE)
When `policy` marks a retained (promoted or frontier) record as eligible for removal, `compact` returns `Err(PregolyaError { category: VAL, code: "E-TRAJ-004", .. })` without modifying any records. This test MUST fail on stubs before implementation (Red Gate discipline — stub will likely return `Ok(())` or not validate the policy). Verified by `test_BC_2_04_011_retained_record_eligible_returns_err()`.

### AC-020 (traces to BC-2.04.011 INV-003 — compaction is crash-isolated; SIGKILL mid-compact leaves pre-compaction trajectory intact — RED GATE — VP-019 anchor)
A process kill (SIGKILL) during compaction execution leaves the pre-compaction trajectory fully intact. After restart, `replay(run_id)` returns the exact pre-compaction record set. The implementation uses SQLite WAL mode (`PRAGMA journal_mode=WAL`) and a `BEGIN IMMEDIATE` / `COMMIT` atomic transaction — WAL single-file topology ensures the journal is applied atomically on restart, so no torn state is possible across a crash. This test MUST fail on stubs before implementation (Red Gate discipline — a stub without WAL-mode transaction boundaries is not crash-safe). Verified by `test_BC_2_04_011_crash_isolated_compaction()` (VP-019 integration test anchor; uses a temp SQLite file).

### AC-021 (traces to BC-2.04.011 INV-005 — trajectory compaction does not touch CheckpointSaver tables)
The `TrajectoryCompactor::compact` implementation operates on the trajectory storage slice only. It issues no SQL statements against the `CheckpointSaver` conversation-context tables (established by S-1.10). The two compaction paths are independent. Verified by `test_BC_2_04_011_compact_does_not_touch_checkpoint_tables()` (inspects SQLite table state before and after compact; confirms CheckpointSaver tables unchanged).

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `TrajectoryRecord` struct, `TrajectoryWriter` trait, `TrajectoryReader` trait, `TrajectoryRetentionPolicy` type | `pregolya_core::trajectory` (`core::trajectory`) | pregolya-core | Pure (definitions-only; no I/O; ADR-009 Option 3 exemption) |
| `SqliteTrajectoryStore` (concrete `impl TrajectoryWriter + TrajectoryReader + TrajectoryCompactor`) | `pregolya_checkpoint::trajectory` (`checkpoint::trajectory`) | pregolya-checkpoint | Effectful Shell (SQLite reads and writes via `rusqlite`; isolated storage slice) |
| `TrajectoryCompactor` trait | `pregolya_checkpoint::trajectory` (`checkpoint::trajectory`) | pregolya-checkpoint | Effectful Shell (SQLite `BEGIN IMMEDIATE` / `COMMIT` atomic transactions) |
| VP-018 proptest harness `trajectory_compaction_retention_integrity` (retention invariant, proptest) | `pregolya_checkpoint::trajectory` `#[cfg(test)]` | pregolya-checkpoint | Pure (test code; uses in-memory SQLite) |
| VP-019 integration test `test_BC_2_04_011_crash_isolated_compaction` (crash-isolation, integration) | `pregolya_checkpoint/tests/trajectory_tests.rs` | pregolya-checkpoint | Effectful (uses temp-file SQLite; WAL mode) |

**Subsystem anchor:** SS-04 owns this story's scope because SS-04 is the Durable Checkpointing subsystem per ARCH-INDEX Subsystem Registry. `core::trajectory` is a definitions-only module (ADR-009 Option 3) in pregolya-core; its execution counterpart `checkpoint::trajectory` is a MEDIUM-criticality module in pregolya-checkpoint. The trajectory storage slice is separate from the `CheckpointSaver` conversation-context tables but shares the same SQLite database file via a dedicated table set.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `TrajectoryRecord`, `TrajectoryRetentionPolicy` | Pure | Data type definitions; no I/O |
| `TrajectoryWriter` trait, `TrajectoryReader` trait, `TrajectoryCompactor` trait | Pure | Trait definitions; no I/O |
| `SqliteTrajectoryStore::put_record` | Effectful Shell | Executes SQLite `INSERT` via `rusqlite`; writes to persistent storage |
| `SqliteTrajectoryStore::replay` | Effectful Shell | Executes SQLite `SELECT ORDER BY step_idx ASC` via `rusqlite`; reads from persistent storage |
| `SqliteTrajectoryStore::compact` | Effectful Shell | Executes SQLite `BEGIN IMMEDIATE` / `DELETE` / `COMMIT` via `rusqlite`; atomic mutation of storage |

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~4,200 |
| BC-2.04.009 | ~2,300 |
| BC-2.04.010 | ~2,000 |
| BC-2.04.011 | ~2,500 |
| VP-018 spec file (proptest retention) | ~800 |
| VP-019 spec file (crash-isolation integration) | ~800 |
| Architecture module-decomposition.md (SS-04 section) | ~700 |
| S-1.10 context (existing `pregolya-checkpoint` checkpoint infrastructure) | ~4,000 |
| Test files (unit + integration) | ~3,500 |
| **Total** | **~20,800** |

Within the 20-30% agent context window threshold; approach the upper bound. If the agent's context is tight, load only the SS-04 section of `module-decomposition.md` rather than the full file.

## Tasks

- [ ] Declare `TrajectoryRecord` (`#[non_exhaustive]`, fields `run_id`, `step_idx`, `event_kind`, `payload`) in `pregolya-core/src/trajectory.rs`
- [ ] Declare `TrajectoryWriter` trait (`#[async_trait]` annotated; async `put_record`) and `TrajectoryReader` trait (`#[async_trait]` annotated; async `replay`) in `pregolya-core/src/trajectory.rs`
- [ ] Declare `TrajectoryRetentionPolicy` type in `pregolya-core/src/trajectory.rs` (specifies eligible vs retained record sets per BC-2.04.011 §PRE-002)
- [ ] Implement `TrajectoryRecord::new(run_id: Uuid, step_idx: u64, event_kind: impl Into<String>, payload: serde_json::Value) -> TrajectoryRecord` constructor (required for cross-crate construction; `#[non_exhaustive]` prevents struct literals from compiling externally per Architecture Rule 14)
- [ ] Implement `TrajectoryRetentionPolicy::new(retention_frontier: u64, promoted: Vec<u64>) -> TrajectoryRetentionPolicy` constructor (required for cross-crate construction per Architecture Rule 14)
- [ ] Re-export `core::trajectory` module from `pregolya-core/src/lib.rs`
- [ ] Define trajectory table schema in `pregolya-checkpoint/src/trajectory.rs` (SQLite table `trajectory_records(run_id TEXT, step_idx INTEGER, event_kind TEXT, payload TEXT)` with `PRIMARY KEY(run_id, step_idx)`) — SEPARATE from `CheckpointSaver` tables
- [ ] Implement `SqliteTrajectoryStore::put_record` — INSERT with idempotency: matching payload → no-op OK; conflicting payload → `Err(E-TRAJ-002)`; storage error → `Err(E-TRAJ-001)`
- [ ] Implement `SqliteTrajectoryStore::replay` — SELECT ORDER BY step_idx ASC; storage error → `Err(E-TRAJ-003)`
- [ ] Declare `TrajectoryCompactor` trait in `pregolya-checkpoint/src/trajectory.rs` (`#[async_trait]` annotated; async `compact`)
- [ ] Implement `SqliteTrajectoryStore::compact` using WAL mode (`PRAGMA journal_mode=WAL`) and `BEGIN IMMEDIATE` / `DELETE` / `COMMIT` atomic transaction; policy-violation guard → `Err(E-TRAJ-004)` VAL before any writes; storage error → `Err(PregolyaError { category: DURABILITY })` with full rollback
- [ ] Verify E-TRAJ-001..E-TRAJ-004 are present in the already-canonical TRAJ taxonomy rows in `.factory/specs/prd-supplements/error-taxonomy.md` before closing this story (do NOT mint new entries — these codes are already registered)
- [ ] Write VP-018 proptest (`trajectory_compaction_retention_integrity`) in `#[cfg(test)]` — MUST fail on stubs (Red Gate discipline)
- [ ] Write integration tests for AC-004 (process-restart durability) and AC-020 (crash-isolated compaction) — use temp-file SQLite databases
- [ ] Write unit tests for AC-001..AC-021 (red first, then implement)
- [ ] Run `just iter pregolya-checkpoint` — all tests green (including existing S-1.10 and S-1.11 tests)
- [ ] Run `just iter pregolya-core` — no regressions

## Previous Story Intelligence

- S-1.10 (Checkpoint Core) established `pregolya-checkpoint`, `SqliteCheckpointSaver`, the SQLite schema, and the `rusqlite` dependency. S-2.12 adds a separate `checkpoint::trajectory` module with its own table set — do NOT modify any existing `CheckpointSaver` tables or methods.
- S-1.11 (FTS Search) extended `pregolya-checkpoint` with the FTS5 virtual table in the same SQLite database. Follow the same module-extension pattern: new module file, separate table, re-exported from `lib.rs`.
- ADR-009 (definitions-in-core) requires `TrajectoryRecord`, `TrajectoryWriter`, `TrajectoryReader`, `TrajectoryRetentionPolicy` to be defined in `pregolya-core`. The `TrajectoryCompactor` trait is an EXECUTION concern and belongs in `checkpoint::trajectory` per ADR-030 §Decision 2 and the Architecture Anchors in BC-2.04.011.
- The `rusqlite` crate is already a dependency of `pregolya-checkpoint` from S-1.10. No new crate-level dependency is needed.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-checkpoint` and ADR-030 §Decision 2:

1. `TrajectoryRecord`, `TrajectoryWriter`, `TrajectoryReader`, `TrajectoryRetentionPolicy` MUST be defined in `pregolya-core/src/trajectory.rs` (`core::trajectory`). This is a definitions-only module (ADR-009 Option 3 / exempt from Iron Law module counting). No I/O code in this file.
2. `SqliteTrajectoryStore` (concrete impl) and `TrajectoryCompactor` trait MUST be defined in `pregolya-checkpoint/src/trajectory.rs` (`checkpoint::trajectory`).
3. The trajectory SQLite table (`trajectory_records`) MUST be separate from `CheckpointSaver` tables. No `JOIN` or cross-table interaction is permitted between trajectory tables and `CheckpointSaver` tables.
4. `TrajectoryCompactor::compact` MUST enable WAL mode (`PRAGMA journal_mode=WAL`) on the SQLite connection and MUST use an atomic transaction (`BEGIN IMMEDIATE` / `COMMIT`). No non-transactional DELETE is permitted — WAL single-file topology and the transaction boundary together ensure any mid-compact process crash leaves the trajectory fully intact (AC-020 / BC-2.04.011 {INV-003}).
5. `TrajectoryRecord` MUST carry `#[non_exhaustive]`.
6. No `unwrap()` / `expect()` in non-test code.
7. No `println!` / `eprintln!` in library crate code.
8. `put_record` MUST NOT return `Ok(())` when the storage write has not been durably committed (no write-back without fsync, no in-memory-only commit).
9. `TrajectoryRetentionPolicy` MUST be named `TrajectoryRetentionPolicy` (not `CompactionPolicy`) to avoid collision with `CompactionPolicy` from CAP-035 rolling-context compaction in `core::budget_config` (BC-2.04.011 §Architecture Anchors note).
10. **Forbidden dependencies:** `core::trajectory` MUST NOT import from `pregolya-checkpoint`, `pregolya-graph`, `pregolya-mcp`, or `pregolya-server`. It is a definitions-only leaf module.
11. Error codes E-TRAJ-001..E-TRAJ-004 are already-canonical TRAJ taxonomy rows. The implementer MUST verify their presence in `.factory/specs/prd-supplements/error-taxonomy.md` before the PR merges; do NOT add them as new codes. The categories are fixed: E-TRAJ-001 = DURABILITY, E-TRAJ-002 = VAL, E-TRAJ-003 = DURABILITY, E-TRAJ-004 = VAL.
12. `TrajectoryWriter`, `TrajectoryReader`, and `TrajectoryCompactor` traits MUST be annotated with `#[async_trait]` (from the `async-trait` crate). Native `async fn` in trait is not dyn-compatible; `Arc<dyn TrajectoryWriter>` / `Arc<dyn TrajectoryReader>` / `Arc<dyn TrajectoryCompactor>` DI wiring requires the `async_trait` macro. Omitting `#[async_trait]` produces a compilation error on the `Arc<dyn …>` use-site.
13. Encryption is OPT-IN per BC-2.04.009 {INV-002}: `SqliteTrajectoryStore` accepts an `Option<Arc<dyn Serializer + Send + Sync>>` at construction time. When a serializer is wired, `put_record` MUST serialize `TrajectoryRecord::payload` via that serializer before any SQLite write. `event_kind` is persisted as cleartext — it is a discriminator field per BC-2.04.009 {PRE-002}, not payload data. When no serializer is configured, payload is persisted as-is; there is NO fail-closed guard. This re-anchors the encryption guarantee from {PC-001} to {INV-002}: the invariant that payload data is protected applies only when a serializer is wired, not unconditionally.
14. Cross-crate construction MUST use the provided constructors: `TrajectoryRecord::new(run_id: Uuid, step_idx: u64, event_kind: impl Into<String>, payload: serde_json::Value)` and `TrajectoryRetentionPolicy::new(retention_frontier: u64, promoted: Vec<u64>)`. Both types carry `#[non_exhaustive]` — struct literals will not compile in external crates. Cross-crate tests MUST use these constructors, not struct literals.

## Library & Framework Requirements

| Library | Version | Usage |
|---------|---------|-------|
| `rusqlite` | workspace pin (inherited from S-1.10) | SQLite operations in `checkpoint::trajectory` |
| `uuid` | workspace pin (inherited from S-1.10); `features = ["serde"]` required | `run_id: uuid::Uuid` field type; `serde` feature required for `Serialize`/`Deserialize` derives on `TrajectoryRecord` |
| `serde` + `serde_json` | workspace pin (inherited from pregolya-core) | `TrajectoryRecord.payload: serde_json::Value`; serializing `run_id` to/from SQLite TEXT |
| `async-trait` | workspace pin | `#[async_trait]` macro on `TrajectoryWriter`, `TrajectoryReader`, `TrajectoryCompactor` for dyn-compatible async trait methods |
| `tokio` | workspace pin (inherited) | `async fn` impls in `SqliteTrajectoryStore` |
| `proptest` | workspace pin (dev-dep) | VP-018 `proptest!` harness in `#[cfg(test)]` |

No new crate-level production dependencies expected.

## File Structure Requirements

Files to CREATE:
- `pregolya-core/src/trajectory.rs` — `TrajectoryRecord` (non_exhaustive), `TrajectoryWriter` trait, `TrajectoryReader` trait, `TrajectoryRetentionPolicy` type
- `pregolya-checkpoint/src/trajectory.rs` — `SqliteTrajectoryStore`, `TrajectoryCompactor` trait, DDL for `trajectory_records` table, `put_record`/`replay`/`compact` implementations
- `pregolya-checkpoint/tests/trajectory_tests.rs` — unit and integration tests for AC-001..AC-021; VP-018 proptest in `#[cfg(test)]` block

Files to MODIFY:
- `pregolya-core/src/lib.rs` — `pub mod trajectory;` and public re-exports
- `pregolya-checkpoint/src/lib.rs` — `pub mod trajectory;` and public re-exports

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Process restart after successful `put_record` | `replay` returns the committed record after restart (AC-004 / BC-2.04.009 {PC-003}) |
| EC-002 | `put_record` with duplicate `(run_id, step_idx)` and matching payload | Idempotent — returns `Ok(())`, no duplicate in replay (BC-2.04.009 {INV-001}) |
| EC-003 | `put_record` with duplicate `(run_id, step_idx)` and DIFFERENT payload | Returns `Err(E-TRAJ-002)` to protect audit integrity (BC-2.04.009 {INV-001}) |
| EC-004 | `replay` when records were written out of `step_idx` order | Returns records sorted ascending by `step_idx` regardless of write order (BC-2.04.010 {PC-002}) |
| EC-005 | `replay` for an unknown `run_id` | Returns `Ok(vec![])` — not an error (BC-2.04.010 {PC-004}) |
| EC-006 | `compact` on empty trajectory | Returns `Ok(())` — compaction of zero records is valid (BC-2.04.011 EC-002) |
| EC-007 | `compact` where all records are retained | Returns `Ok(())` — zero eligible records is valid; trajectory unchanged (BC-2.04.011 EC-003) |
| EC-008 | `compact` policy marks retained record as eligible | Returns `Err(E-TRAJ-004 VALIDATION)` before any writes (BC-2.04.011 {PC-005}, {INV-004}) |
| EC-009 | SIGKILL mid-compaction | Restart: `replay` returns pre-compaction records — atomic transaction rolled back by SQLite (BC-2.04.011 {INV-003}) |
| EC-010 | `compact` when `CheckpointSaver` compaction fires concurrently | No interference — trajectory tables are separate; ADR-019 does not touch trajectory slice (BC-2.04.011 {INV-005}) |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.2 | 2026-08-31 | Round-51 fix-burst: F-P2A212-04 encryption changed to OPT-IN per INV-002 (optional Serializer, payload-only, event_kind cleartext, no fail-closed guard, re-anchored from PC-001 to INV-002 in AC-002 and Rule 13); F-P2A212-01 follow-on — AC-001/AC-014/Tasks cite TrajectoryRecord::new and TrajectoryRetentionPolicy::new constructors with exact signatures; Rule 13 revised to opt-in model; Rule 14 added for cross-crate constructor requirement | story-writer |
| 1.1 | 2026-08-31 | Round-50 fix-burst: DURABILITY/VAL error categories; VP-019 crash-isolation anchor; async-trait rule; EncryptedSerializer at-rest anchor; WAL-mode compaction rule; BC-2.04.010 title fix; uuid serde feature; verify-canonical TRAJ taxonomy task | story-writer |
| 1.0 | 2026-08-31 | Initial authoring — praxist Stage-3 story decomposition for BC-2.04.009/010/011 + VP-018 | story-writer |
