---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.009
version: "1.7"
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
  - "1.4 (round-52/F-P2A216-02+F-P2A217-01/2026-08-31): DI seam explicit in {PRE-001}: `Option<Arc<dyn Serializer + Send + Sync>>` is the `core::serializer::Serializer` trait (pregolya-core); `EncryptedSerializer` (`checkpoint::serializer`, pregolya-checkpoint) is the canonical concrete implementor. {INV-001} extended with plaintext-comparison clause: per-record-nonce encryption requires that `(run_id, step_idx)` conflict detection compare the **plaintext** payload (decrypt-then-compare or deterministic content-hash of the pre-encryption plaintext), NOT the ciphertext — ciphertext is non-deterministic across calls with distinct nonces; comparing ciphertext would generate false E-TRAJ-002 on legitimate idempotent resume-retries. {INV-002} note added: plaintext comparison ensures per-record-nonce does not break write-once idempotency. TV-005 added (encryption + duplicate identical plaintext → Ok(())); TV-006 added (encryption + duplicate divergent plaintext → E-TRAJ-002). TV count 4→6."
  - "1.5 (round-53/F-P2A221-02+F-P2A220-02/2026-08-31): {INV-001} amended — hash-oracle alternative REMOVED (CWE-916/311 finding F-P2A221-02); conflict detection is now DECRYPT-THEN-COMPARE exclusively: the implementation decrypts the stored record ciphertext and compares plaintext payloads in memory using the 256-bit AES-GCM key already held by EncryptedSerializer (EncryptedSerializer::new(key: &[u8;32])); no auxiliary hash or digest may be stored on disk. {INV-002} cross-reference updated to match. Architecture Anchors: TrajectoryRecord explicit pub-visibility stated — all fields pub (F-P2A220-02)."
  - "1.6 (round-62/F-P2A234-03+OBS-1/2026-09-01): {INV-001} extended — when `EncryptedSerializer` is configured, an AES-GCM authentication/decrypt failure during conflict-detection read MUST surface as `Err(E-TRAJ-006 TrajectoryIntegrityCheckFailed)` (never silently swallowed per DI-014); MUST NOT be mislabeled as E-TRAJ-002 (ConflictingDuplicate — implies successful read of divergent plaintext) or E-TRAJ-001 (TrajectoryWriteFailed — covers I/O layer failures, not integrity failures). {INV-002} OBS-1 cross-reference added: per-record AES-GCM nonce uniqueness (96-bit nonce; ~2^48 birthday bound) is guaranteed by the EncryptedSerializer contract per BC-2.04.007; TrajectoryWriter relies on that guarantee without independently managing nonce allocation."
  - "1.7 (round-63/F-P2A235-05/2026-09-01): EC-006 added — AES-GCM authentication failure during conflict-detection decrypt; `put_record` returns `Err(E-TRAJ-006 TrajectoryIntegrityCheckFailed)` non-silent (DI-014), MUST NOT be mislabeled as E-TRAJ-002 (successful-decrypt-then-diverge) or E-TRAJ-001 (I/O layer failure); consistent with {INV-001} authentication-failure clause (round-62 extension). TV-007 added as canonical test vector for EC-006 path (single-byte ciphertext tamper → E-TRAJ-006 during conflict-detection decrypt)."
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
   Topology Decision). An optional `Arc<dyn Serializer + Send + Sync>` (the
   `core::serializer::Serializer` trait from `pregolya-core`) is wired at construction time
   to configure at-rest encryption for payload values ({INV-002}); `EncryptedSerializer`
   (`checkpoint::serializer`, `pregolya-checkpoint`) is the canonical concrete implementor.
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
  returns `Err(E-TRAJ-002)` to preserve audit integrity). **Conflict detection MUST use decrypt-then-compare exclusively** — when `EncryptedSerializer`
  is configured, the implementation decrypts the stored record ciphertext and compares
  plaintext payloads in memory using the 256-bit AES-GCM key already held by
  `EncryptedSerializer` (`EncryptedSerializer::new(key: &[u8; 32])`); no additional secret
  is required. No auxiliary hash or digest may be stored on disk for this purpose.
  Ciphertext MUST NOT be compared directly — ciphertext is non-deterministic across calls
  that use a per-record nonce; comparing ciphertexts would generate false E-TRAJ-002 errors
  on legitimate idempotent resume-retries ({INV-002}). When `EncryptedSerializer` is
  configured, a decrypt failure or AES-GCM authentication failure encountered while reading
  the stored ciphertext for conflict detection MUST surface as
  `Err(PregolyaError { code: E-TRAJ-006, .. })` — it MUST NOT be silently swallowed (DI-014),
  and MUST NOT be mislabeled as `E-TRAJ-002` (ConflictingDuplicate — that code implies a
  successful plaintext comparison that found a divergence) or `E-TRAJ-001`
  (TrajectoryWriteFailed — that code covers I/O layer failures, not integrity or tamper
  failures).
- {INV-002} **At-rest encryption via `core::serializer::Serializer` DI seam (fail-safe):**
  `checkpoint::trajectory` receives an `Option<Arc<dyn Serializer + Send + Sync>>`
  (the `core::serializer::Serializer` trait from `pregolya-core`) at construction via Arc-DI;
  `EncryptedSerializer` (`checkpoint::serializer`, `pregolya-checkpoint`) is the canonical
  concrete implementor. When an `EncryptedSerializer` is provided, `put_record` MUST serialize
  `TrajectoryRecord::payload` through `EncryptedSerializer` using a per-record nonce before
  persisting to SQLite. Plaintext payload values MUST NOT be observable in the database file
  when encryption is configured — the `TrajectoryWriter` implementation enforces encryption at
  the storage boundary; there is no caller-bypass path. **Per-record-nonce reconciliation:**
  because each nonce is unique per call, the ciphertext of the same plaintext differs across
  calls; conflict detection for {INV-001} MUST therefore use decrypt-then-compare (see {INV-001}),
  not direct ciphertext comparison. When no `EncryptedSerializer` is provided, records are stored in their
  serialized (plaintext) form (opt-in encryption model per ADR-030 §At-Rest Confidentiality
  Decision). Regardless of encryption configuration, credential material MUST NOT be placed
  in `payload` or `event_kind` before calling `put_record`. `event_kind`, like `run_id` and
  `step_idx`, is a cleartext index/discriminator field stored unencrypted at all times — it
  is never passed through `EncryptedSerializer` — and MUST NOT carry sensitive or credential
  material (DI-010 / Code Conventions credential-opacity rule). **Nonce-uniqueness
  cross-reference (OBS-1):** Per-record AES-GCM nonce uniqueness (96-bit nonce; ~2^48
  birthday bound before collision probability becomes material) is an obligation of
  `EncryptedSerializer`, not `TrajectoryWriter`. `TrajectoryWriter` relies on the
  EncryptedSerializer contract for nonce uniqueness — see BC-2.04.007 (at-rest encryption
  contract for `checkpoint::` implementations) for the authority on nonce allocation and
  uniqueness guarantees. `TrajectoryWriter` does not independently manage or audit nonce
  values.
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

### EC-006: AES-GCM authentication failure during conflict-detection decrypt
**Scenario:** `EncryptedSerializer` is configured at construction. `put_record` is called for
`(run_id=R, step_idx=7)` and a record is already committed at that position. During
conflict-detection, the implementation attempts to decrypt the stored ciphertext but the
AES-GCM authentication tag verification fails — caused by storage corruption, single-bit
tamper, or use of a wrong decryption key.
**Expected behavior:** `put_record` returns
`Err(PregolyaError { code: E-TRAJ-006, message: "TrajectoryIntegrityCheckFailed: stored trajectory record failed AES-GCM integrity check during conflict-detection read — tamper, corruption, or wrong key", category: DURABILITY, .. })`.
The error MUST NOT be silently swallowed (DI-014). It MUST NOT be returned as `E-TRAJ-002`
(ConflictingDuplicate — that code implies a successful decrypt-then-compare found divergent
plaintext) and MUST NOT be returned as `E-TRAJ-001` (TrajectoryWriteFailed — that code covers
I/O layer failures, not AES-GCM integrity failures). The committed record at `(R, 7)` is
unchanged; `replay(R)` still returns the original record at `step_idx=7`. Consistent with
{INV-001} authentication-failure clause: the AES-GCM authentication failure is a non-transient
integrity condition requiring operator investigation (key verification or storage restore) —
not a conflict or write failure.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `put_record(TrajectoryRecord { run_id: R, step_idx: 0, event_kind: "generation_complete", payload: json!({"answer": "Paris"}) })` | `Ok(())`; subsequent `replay(R)` contains the record | Happy-path durable write |
| TV-002 | `put_record(r1)` where `r1.run_id = R`, `r1.step_idx = 0`; then `put_record(r2)` where `r2.run_id = R`, `r2.step_idx = 1` | Both `Ok(())`; `replay(R)` returns `[r1, r2]` (two records for same run) | Multiple records for one run |
| TV-003 | `put_record(r1)`; kill process; restart with same storage backend; `replay(r1.run_id)` | `replay` returns `[r1]` | Durability across process restart; {PC-003} |
| TV-004 | `EncryptedSerializer` configured at construction; `put_record(r1)` where `r1.payload = json!({"answer": "Paris"})` returns `Ok(())`; raw byte inspection of `trajectory_records` table in the SQLite file | No plaintext occurrence of `"Paris"` or the unencrypted JSON bytes observable in the raw database file; stored column bytes are ciphertext produced by `EncryptedSerializer` with per-record nonce | At-rest encryption; {INV-002} |
| TV-005 | `EncryptedSerializer` configured at construction; `put_record(r1)` with `run_id=R`, `step_idx=0`, `payload=json!({"answer":"Paris"})` returns `Ok(())`; same call `put_record(r1)` again (identical plaintext payload) | Second call returns `Ok(())` — no false E-TRAJ-002; plaintext comparison identifies matching payloads despite per-record-nonce producing different ciphertexts across calls | Idempotency under encryption; {INV-001} + {INV-002} |
| TV-006 | `EncryptedSerializer` configured at construction; `put_record(r1)` with `run_id=R`, `step_idx=0`, `payload=json!({"answer":"Paris"})` returns `Ok(())`; then `put_record(r2)` with same `run_id=R`, `step_idx=0`, but `payload=json!({"answer":"London"})` (divergent plaintext) | `Err(PregolyaError { code: E-TRAJ-002, message: "ConflictingDuplicate: put_record for (run_id='R', step_idx=0) conflicts with committed record — payload or event_kind differs", category: VAL, .. })` — plaintext comparison correctly detects divergence despite encryption | Conflict detection under encryption; {INV-001} + {INV-002} |
| TV-007 | `EncryptedSerializer` configured at construction; `put_record(r1)` with `run_id=R`, `step_idx=7`, `payload=json!({"step":"init"})` returns `Ok(())`; the stored ciphertext bytes for that record are then directly mutated in the SQLite file (single byte flip) to simulate storage corruption; `put_record(r2)` with same `run_id=R`, `step_idx=7` is called (triggers conflict-detection, which attempts to decrypt the now-corrupt ciphertext) | `Err(PregolyaError { code: E-TRAJ-006, message: "TrajectoryIntegrityCheckFailed: stored trajectory record failed AES-GCM integrity check during conflict-detection read — tamper, corruption, or wrong key", category: DURABILITY, .. })` — non-silent; not E-TRAJ-001; not E-TRAJ-002; original `r1` at `step_idx=7` remains in storage | AES-GCM auth failure during conflict detection; EC-006; {INV-001} |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| TST-TRAJ-01 | `put_record` followed by process restart: `replay` returns all committed records | Integration test (write + kill + restart fixture) — not a registered VP | Wave 2 |

## Related BCs

- BC-2.04.010 — composes with: `TrajectoryReader::replay` is the read counterpart; BC-2.04.009 guarantees durability, BC-2.04.010 guarantees ordering of the read result
- BC-2.04.001 — depends on: `TrajectoryWriter` is isolated from but co-located with `CheckpointSaver`; `put_writes` durability tier (BC-2.04.001) is the architectural precedent
- BC-2.04.008 — related to: both BCs extend `pregolya-checkpoint` with additional query capabilities; trajectory is an audit-grade event log, FTS search is a content-retrieval index

## Architecture Anchors

- `pregolya-core/src/trajectory.rs` (`core::trajectory`) — `TrajectoryRecord` struct: `#[non_exhaustive] pub struct TrajectoryRecord { pub run_id: Uuid, pub step_idx: u64, pub event_kind: String, pub payload: serde_json::Value }` — all fields `pub` (cross-crate visibility: `checkpoint::trajectory` reads fields for serialization, conflict detection, and replay); `TrajectoryWriter` trait (`async fn put_record(&self, record: TrajectoryRecord) -> Result<(), PregolyaError>`); `TrajectoryReader` trait (`async fn replay(&self, run_id: Uuid) -> Result<Vec<TrajectoryRecord>, PregolyaError>`)
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
