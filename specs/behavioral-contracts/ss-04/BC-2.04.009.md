---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.009
version: "1.3"
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
  - "1.0 (ADR-030 Stage 2a/2026-08-31): Initial greenfield spec — TrajectoryWriter::put_record durability; DI-002 + DI-014 invariant enforcement; ADR-030 Decision 2."
  - "1.1 (ADR-030/Stage-3.5-product-owner/2026-08-31): EC-002 category corrected INTERNAL→DURABILITY (E-TRAJ-001 minted as DURABILITY; write failures are DURABILITY per taxonomy convention matching E-CHKPT-001); EC-005 added for ConflictingDuplicate — wires the {INV-001} mismatched-payload error path to its canonical taxonomy code E-TRAJ-002."
  - "1.2 (round-50/Stage-B1-product-owner/2026-08-31): {INV-002} reframed from credential-opacity-caller-responsible to at-rest encryption fail-safe per ADR-030 §At-Rest Confidentiality Decision (F-P2A209-01/CWE-311): when EncryptedSerializer is wired at construction, TrajectoryWriter MUST encrypt payload with per-record nonce before persisting to SQLite; plaintext MUST NOT be observable in database file. {PRE-001} reconciled to single-file SQLite WAL topology (ADR-030 §SQLite Topology Decision/F-P2A209-04). TV-004 added: asserts plaintext not observable at rest when EncryptedSerializer configured. VP-TRAJ-01 phantom label relabeled TST-TRAJ-01 in §Verification Properties; removed from §VP Anchors (not a registered VP — no real VP covers BC-2.04.009)."
  - "1.3 (round-51/Stage-B2-product-owner/2026-08-31): §Story Anchor resolved: S-2.12 (per STORY-INDEX; F-P2A214-01 hook #19 compliance). {PRE-002} and {INV-002}: event_kind explicitly designated as cleartext index/discriminator field that MUST NOT carry sensitive or credential material — extends DI-010 credential-opacity constraint to event_kind (F-P2A213-01/CWE-312 metadata-confidentiality gap closure)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-040
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-030-research-orchestrator-composition.md
input-hash: "5703511"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.04.009: TrajectoryWriter::put_record Durability

## Description

`TrajectoryWriter` (trait in `core::trajectory`, pregolya-core) provides the durable write
path for audit-grade `TrajectoryRecord` values in a research-orchestrator run. After a
successful `put_record` call returns `Ok(())`, the written record is durably committed to
the storage tier backing `checkpoint::trajectory` (pregolya-checkpoint) and is guaranteed to
appear in a subsequent `TrajectoryReader::replay` call for the same `run_id`, even across a
process restart. Trajectory records are isolated from `CheckpointSaver` compaction (ADR-019)
and are never pruned by the rolling-context compaction mechanism.

## Preconditions

1. {PRE-001} A concrete `impl TrajectoryWriter` (the `checkpoint::trajectory` implementation)
   has been constructed, backed by a dedicated `trajectory_records` table within the same
   single-file SQLite database as `CheckpointSaver`, operated in WAL mode (ADR-030 §SQLite
   Topology Decision). An optional `EncryptedSerializer` is wired at construction time
   (`Option<Arc<dyn Serializer + Send + Sync>>`) to configure at-rest encryption for payload
   values ({INV-002}).
2. {PRE-002} A `TrajectoryRecord` is prepared with:
   - `run_id: Uuid` — a non-nil UUID identifying the research run
   - `step_idx: u64` — the logical-clock position sourced from the checkpoint clock
   - `event_kind: String` — a non-empty event kind string (e.g., `"generation_complete"`);
     `event_kind` is a cleartext index/discriminator field stored unencrypted alongside
     `run_id` and `step_idx` as queryable metadata and MUST NOT carry sensitive or credential
     material (DI-010 / Code Conventions credential-opacity rule)
   - `payload: serde_json::Value` — a structured JSON payload containing no credential
     material (see DI-010 / Code Conventions credential-opacity rule)
3. {PRE-003} The storage backend is reachable (not shutdown, not out of disk space).

## Postconditions

1. {PC-001} `put_record(&self, record: TrajectoryRecord) -> Result<(), PregolyaError>` returns
   `Ok(())` when the record has been durably committed to the backing storage tier.
2. {PC-002} After `put_record` returns `Ok(())`, a call to `TrajectoryReader::replay(run_id)`
   on the same `run_id` returns a `Vec<TrajectoryRecord>` that contains the written record
   (identified by its `(run_id, step_idx)` pair).
3. {PC-003} Durability survives process restart: after `put_record` returns `Ok(())`, killing
   and restarting the process does not cause the record to be absent from a subsequent
   `replay(run_id)`.
4. {PC-004} Storage errors (backend I/O failure, disk full, connection loss) propagate as
   `Err(PregolyaError)` — no `Ok(())` is returned unless the record has actually been
   durably committed. This prevents silent data loss.
5. {PC-005} Trajectory records are isolated from ADR-019 rolling-context compaction. A
   compaction event applied to the conversation context window does NOT remove or modify
   any `TrajectoryRecord`. After compaction, `replay(run_id)` returns the same records as
   before compaction.

## Invariants

- {INV-001} **Write-once per (run_id, step_idx):** each `(run_id, step_idx)` pair identifies
  at most one `TrajectoryRecord` in the store. Submitting a second `put_record` call with the
  same `(run_id, step_idx)` pair is idempotent: the stored record is unchanged (no duplicate
  created, no error raised on a matching payload; a mismatching payload for the same pair
  returns `Err(PregolyaError)` to preserve audit integrity).
- {INV-002} **At-rest encryption via EncryptedSerializer (fail-safe):** `checkpoint::trajectory`
  receives an `Option<Arc<dyn Serializer + Send + Sync>>` at construction via Arc-DI. When an
  `EncryptedSerializer` is provided, `put_record` MUST serialize `TrajectoryRecord::payload`
  through `EncryptedSerializer` using a per-record nonce before persisting to SQLite. Plaintext
  payload values MUST NOT be observable in the database file when encryption is configured — the
  `TrajectoryWriter` implementation enforces encryption at the storage boundary; there is no
  caller-bypass path. When no `EncryptedSerializer` is provided, records are stored in their
  serialized (plaintext) form (opt-in encryption model per ADR-030 §At-Rest Confidentiality
  Decision). Regardless of encryption configuration, credential material MUST NOT be placed
  in `payload` or `event_kind` before calling `put_record`. `event_kind`, like `run_id` and
  `step_idx`, is a cleartext index/discriminator field stored unencrypted at all times — it
  is never passed through `EncryptedSerializer` — and MUST NOT carry sensitive or credential
  material (DI-010 / Code Conventions credential-opacity rule).
- {INV-003} **Compaction isolation:** `TrajectoryRecord` storage is addressed independently of
  the `CheckpointSaver` conversation-context storage (ADR-030 §Rationale / ADR-019 §Scope).
  No code path that compacts, rolls, or prunes conversation-context checkpoints may touch
  the trajectory storage slice.

## Edge Cases

### EC-001: Process restart after successful put_record
**Scenario:** `put_record(record_A)` returns `Ok(())`. The process is then killed (SIGKILL /
OS crash). A new process instance starts, creates a fresh `TrajectoryWriter` pointing to the
same storage backend.
**Expected behavior:** `replay(record_A.run_id)` returns a `Vec<TrajectoryRecord>` that
includes `record_A`. Durability is not contingent on an in-memory write-back flush; the
backing store was already committed by the time `Ok(())` was returned.

### EC-002: Storage backend error during put_record
**Scenario:** The underlying SQLite slice or storage layer returns an I/O error mid-write.
**Expected behavior:** `put_record` returns
`Err(PregolyaError { code: E-TRAJ-001, message: "TrajectoryWriteFailed: put_record for (run_id='<run_id>', step_idx=<step_idx>) failed — backend error: <backend_error>", category: DURABILITY, .. })`.
No record is partially written or visible to `replay`. The caller MUST handle the `Err` and
decide whether to retry or abort the run — `put_record` never silently swallows the error.

### EC-003: ADR-019 compaction fires while trajectory records exist
**Scenario:** The `CheckpointSaver` rolling-context compaction triggers (OnWatermark threshold
exceeded). The trajectory slice for the same `run_id` contains 50 `TrajectoryRecord`s.
**Expected behavior:** After compaction completes, `replay(run_id)` still returns all 50
records unchanged. Compaction operates on the conversation-context partition only; trajectory
records are in a separate, compaction-isolated storage slice.

### EC-004: put_record called for an already-committed (run_id, step_idx) with matching payload
**Scenario:** `put_record(record_A)` succeeds. The graph is resumed from a checkpoint and
the same node re-runs, calling `put_record` with the same `record_A` value.
**Expected behavior:** The call is idempotent — returns `Ok(())` without creating a duplicate.
`replay(run_id)` continues to contain exactly one copy of the record for that `step_idx`.

### EC-005: put_record called for an already-committed (run_id, step_idx) with mismatched payload
**Scenario:** `put_record(record_A)` succeeds with `run_id=R`, `step_idx=7`. A subsequent
call submits `record_B` with the same `run_id=R` and `step_idx=7` but a different `payload`
or `event_kind` value (content divergence from the committed record).
**Expected behavior:** `put_record(record_B)` returns
`Err(PregolyaError { code: E-TRAJ-002, message: "ConflictingDuplicate: put_record for (run_id='R', step_idx=7) conflicts with committed record — payload or event_kind differs", category: VAL, .. })`.
No records are modified; `replay(R)` still returns the original `record_A` at `step_idx=7`.
The audit trail is preserved intact. Distinct from EC-004 (matching payload returns `Ok(())`):
E-TRAJ-002 fires only when the content differs, protecting the write-once audit contract
({INV-001}).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `put_record(TrajectoryRecord { run_id: R, step_idx: 0, event_kind: "generation_complete", payload: json!({"answer": "Paris"}) })` | `Ok(())`; subsequent `replay(R)` contains the record | Happy-path durable write |
| TV-002 | `put_record(r1)` where `r1.run_id = R`, `r1.step_idx = 0`; then `put_record(r2)` where `r2.run_id = R`, `r2.step_idx = 1` | Both `Ok(())`; `replay(R)` returns `[r1, r2]` (two records for same run) | Multiple records for one run |
| TV-003 | `put_record(r1)`; kill process; restart with same storage backend; `replay(r1.run_id)` | `replay` returns `[r1]` | Durability across process restart; {PC-003} |
| TV-004 | `EncryptedSerializer` configured at construction; `put_record(r1)` where `r1.payload = json!({"answer": "Paris"})` returns `Ok(())`; raw byte inspection of `trajectory_records` table in the SQLite file | No plaintext occurrence of `"Paris"` or the unencrypted JSON bytes observable in the raw database file; stored column bytes are ciphertext produced by `EncryptedSerializer` with per-record nonce | At-rest encryption; {INV-002} |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| TST-TRAJ-01 | `put_record` followed by process restart: `replay` returns all committed records | Integration test (write + kill + restart fixture) — not a registered VP | Wave 2 |

## Related BCs

- BC-2.04.010 — composes with: `TrajectoryReader::replay` is the read counterpart; BC-2.04.009 guarantees durability, BC-2.04.010 guarantees ordering of the read result
- BC-2.04.001 — depends on: `TrajectoryWriter` is isolated from but co-located with `CheckpointSaver`; `put_writes` durability tier (BC-2.04.001) is the architectural precedent
- BC-2.04.008 — related to: both BCs extend `pregolya-checkpoint` with additional query capabilities; trajectory is an audit-grade event log, FTS search is a content-retrieval index

## Architecture Anchors

- `pregolya-core/src/trajectory.rs` (`core::trajectory`) — `TrajectoryRecord` struct (non_exhaustive, run_id/step_idx/event_kind/payload); `TrajectoryWriter` trait (`async fn put_record`); `TrajectoryReader` trait (`async fn replay`)
- `pregolya-checkpoint/src/trajectory.rs` (`checkpoint::trajectory`) — concrete `impl TrajectoryWriter + TrajectoryReader` backed by the SQLite storage tier; isolated from ADR-019 compaction; MEDIUM execution module per ADR-030 §Module Placement
- ADR-030 §Decision 2 — TrajectoryWriter/Reader design; isolation from ADR-019 compaction; ADR-009 definitions-in-core / execution-in-domain split

## Story Anchor

S-2.12

## VP Anchors

None

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-040 |
| Capability Anchor Justification | CAP-040 ("Durable Trajectory Records and Ledger-Style State Channels (Research Orchestrator Primitives)") per capabilities-p1-p2.md §CAP-040 — `TrajectoryWriter::put_record` is the durable-write API for the trajectory primitive introduced in CAP-040; this BC specifies the durability guarantees that make trajectory records audit-grade and replayable |
| L2 Domain Invariants | DI-002 (Per-Task Durability: `put_record` provides the same durability guarantee as `put_writes` — the record is committed before `Ok(())` returns; a process crash after `Ok(())` does not lose the record per {PC-003}), DI-014 (Error Propagation — No Silent Swallowing: storage errors propagate as `Err(PregolyaError)` per {PC-004}; no `Ok(())` is returned for a failed write) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | pregolya-checkpoint |
