---
document_type: story
level: ops
story_id: S-1.11
epic_id: E-05
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.008.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "1c867c1"
traces_to: .factory/stories/STORY-INDEX.md
points: 3
depends_on: [S-1.10]
blocks: []
behavioral_contracts: [BC-2.04.008]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-checkpoint
subsystems: [SS-04]
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.11: FTS Conversation Search Over Checkpoint History

## Narrative

- **As a** pregolya library user building conversational agents
- **I want to** search across the full conversation history stored in checkpoints using full-text search
- **So that** agents can retrieve relevant prior exchanges by semantic query, enabling long-horizon memory access without loading all checkpoints into context

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.04.008 | Full-Text Search Over Checkpoint History via SQLite FTS5 | AC-001..AC-008 |

## Acceptance Criteria

### AC-001 (traces to BC-2.04.008 postcondition 1 — fts_search trait method)
`CheckpointSaver` trait includes method `fts_search(query: &str, config: FtsSearchConfig) -> Result<Vec<FtsSearchResult>, PregolyaError>`. `FtsSearchConfig` has fields `thread_id: Option<&str>` (scope to one thread when `Some`) and `limit: usize`. Verified by `test_BC_2_04_008_fts_search_signature_exists()`.

### AC-002 (traces to BC-2.04.008 postcondition 2 — result fields)
`FtsSearchResult` has fields: `checkpoint_id: CheckpointId`, `thread_id: String`, `checkpoint_ns: String`, `message_role: String`, `content_snippet: String`, `rank: f64`. All fields are present and non-nullable. Verified by `test_BC_2_04_008_result_struct_fields()`.

### AC-003 (traces to BC-2.04.008 postcondition 3 — same transaction FTS index update)
The FTS5 index is updated in the same SQLite transaction as the checkpoint write. After `put_writes` completes successfully, the FTS index contains the new content and is immediately searchable. Verified by `test_BC_2_04_008_fts_index_updated_same_transaction()`.

### AC-004 (traces to BC-2.04.008 postcondition 4 — search_history_tool)
`search_history_tool()` returns a `Tool`-implementing type that wraps `fts_search`. The tool is callable by agents via the standard `Tool::invoke` interface. When the tool is invoked with a query string and optional thread_id, it calls `fts_search` on the underlying `CheckpointSaver` and returns the results serialized as a `ToolOutput`. Verified by `test_BC_2_04_008_search_history_tool_invocable()`.

### AC-005 (traces to BC-2.04.008 edge case EC-001 — FtsLimitZero)
`fts_search` with `FtsSearchConfig { limit: 0, .. }` returns `Err(PregolyaError { code: "E-CHKPT-008", message: "FtsLimitZero: FtsSearchConfig.limit must be > 0; got <limit>", .. })`. Verified by `test_BC_2_04_008_fts_limit_zero_error()`.

### AC-006 (traces to BC-2.04.008 edge case EC-002 — Fts5Unavailable)
If the SQLite build does not include the FTS5 extension (e.g., compiled without `SQLITE_ENABLE_FTS5`) and FTS is requested, `CheckpointSaver::new()` returns `Err(PregolyaError { code: "E-CHKPT-009", message: "Fts5Unavailable: FTS5 extension not available in this SQLite build — recompile SQLite with FTS5 support or use a pre-built distribution that includes it", .. })` at construction time — before any DDL executes. The error fires during construction, not at query time. Verified by `test_BC_2_04_008_fts5_unavailable_error()`.

### AC-007 (traces to BC-2.04.008 invariant 1 — append-only index consistency)
Checkpoint records are append-only by design: writes add rows, never update or delete them. The FTS index mirrors this append-only invariant — FTS entries are never deleted or updated during a run. The FTS index accurately reflects the full append-only checkpoint write history. Verified by `test_BC_2_04_008_fts_index_append_only()`.

### AC-008 (traces to BC-2.04.008 edge case EC-007 — FtsEncryptionIncompatible)
`CheckpointSaver::new()` with FTS5 enabled and `EncryptedSerializer` configured returns `Err(PregolyaError { code: "E-CHKPT-010", message: "FtsEncryptionIncompatible: ...", .. })` at construction time. FTS5 and `EncryptedSerializer` are mutually exclusive — the error fires before any DDL executes and no checkpoint tables are created. Verified by `test_BC_2_04_008_fts_encryption_incompatible()`.

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `FtsSearchConfig`, `FtsSearchResult` structs | `pregolya_checkpoint::fts` | pregolya-checkpoint | Pure (data type definitions; no I/O) |
| `CheckpointSaver::fts_search` trait method | `pregolya_checkpoint::saver` | pregolya-checkpoint | Effectful Shell (executes SQLite FTS5 SELECT query via `rusqlite`) |
| FTS5 virtual table schema creation and same-transaction index update (`SqliteCheckpointSaver`) | `pregolya_checkpoint::fts` | pregolya-checkpoint | Effectful Shell (SQLite DDL `CREATE VIRTUAL TABLE` + DML `INSERT` into FTS table via `rusqlite`) |
| `search_history_tool()` factory function | `pregolya_checkpoint::fts` | pregolya-checkpoint | Effectful Shell (returns a `Tool` impl whose `invoke` delegates to `fts_search` and performs SQLite reads) |

**Subsystem anchor:** SS-04 owns this story's scope because SS-04 is the Durable Checkpointing subsystem (`pregolya-checkpoint` crate) per ARCH-INDEX Subsystem Registry. Pure-core / effectful-shell boundary: `FtsSearchConfig` and `FtsSearchResult` are pure data types; all SQLite FTS5 interactions (`fts_search` execution, schema init, index update, `search_history_tool` invoke) are effectful shells.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `FtsSearchConfig`, `FtsSearchResult` | Pure | Data type definitions; no I/O side effects |
| `SqliteCheckpointSaver::fts_search` | Effectful Shell | Executes SQLite FTS5 SELECT via `rusqlite`; reads from persistent storage |
| FTS5 virtual table schema init | Effectful Shell | SQLite `CREATE VIRTUAL TABLE` DDL executed on connection init via `rusqlite` |
| FTS5 index update (same-transaction as `put_writes`) | Effectful Shell | SQLite `INSERT` into FTS virtual table in the same `rusqlite` transaction as the checkpoint write |
| `search_history_tool()` return value's `Tool::invoke` | Effectful Shell | Delegates to `fts_search`; performs SQLite FTS5 reads on each agent invocation |

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~2,800 |
| BC-2.04.008 | ~2,300 |
| Architecture module-decomposition.md (SS-04 section) | ~600 |
| pregolya-checkpoint existing code (S-1.10 context) | ~3,000 |
| Test files | ~2,200 |
| **Total** | **~10,900** |

Well within the 20-30% agent context window threshold.

## Tasks

- [ ] Extend `pregolya-checkpoint/src/saver.rs` — add `fts_search` method to `CheckpointSaver` trait
- [ ] Define `FtsSearchConfig` and `FtsSearchResult` structs in `pregolya-checkpoint/src/fts.rs`
- [ ] Implement SQLite FTS5 table creation in `SqliteCheckpointSaver` schema init
- [ ] Implement FTS index update in the same SQLite transaction as `put_writes` and `put`
- [ ] Implement `fts_search` query execution against FTS5 table
- [ ] Implement `search_history_tool()` factory function returning a `Tool` wrapping `fts_search`
- [ ] Return `Err(E-CHKPT-010 FtsEncryptionIncompatible)` at construction time when both FTS5 and `EncryptedSerializer` are configured (BC-2.04.008 EC-007 / AC-008)
- [ ] Write unit tests for all 8 ACs (AC-001..AC-008), including `test_BC_2_04_008_fts_encryption_incompatible()`
- [ ] Run `just iter pregolya-checkpoint` — all tests green (including S-1.10 tests)

## Previous Story Intelligence

- S-1.10 (Checkpoint Core) established `CheckpointSaver`, `SqliteCheckpointSaver`, the `pending_writes` table schema, and the transaction pattern. S-1.11 extends the same SQLite schema with an FTS5 virtual table and adds `fts_search` to the existing trait. Load the S-1.10 story and the current `saver.rs` file as context before implementing S-1.11.
- The `search_history_tool()` function must return a type that satisfies the `Tool` trait established in S-1.04. The `Tool` trait's `invoke` signature requires `Result<ToolOutput, PregolyaError>` — ensure `FtsSearchResult` serializes cleanly to `ToolOutput`.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-checkpoint`:

1. `fts_search` is a `CheckpointSaver` trait method — it must be on the trait, not an inherent method of `SqliteCheckpointSaver`. This ensures that in-memory or other backend implementations can stub it.
2. FTS5 virtual table MUST be created in the same `CREATE TABLE` migration that creates the checkpoint tables. No separate migration step.
3. FTS index updates MUST be in the same SQLite transaction as the checkpoint write (not a best-effort post-commit update). Transactional consistency is required per AC-003.
4. `E-CHKPT-008` (FtsLimitZero) and `E-CHKPT-009` (Fts5Unavailable) must be defined in the `pregolya-core` error taxonomy before being used. If they are not yet present, add them as part of this story's implementation.
5. `search_history_tool` returns a value that implements `Tool` (from `pregolya-core`). It must NOT be an `Arc<dyn Tool>` — return a concrete type that can be boxed by the caller.
6. No `unwrap()` / `expect()` in non-test code.
7. `FtsSearchResult` and `FtsSearchConfig` must carry `#[non_exhaustive]`.
8. When `EncryptedSerializer` is configured, FTS5 MUST NOT be enabled simultaneously. `SqliteCheckpointSaver::new()` MUST return `Err(E-CHKPT-010 FtsEncryptionIncompatible)` at construction time when both are set — before any DDL executes. The FTS5 virtual table stores plaintext payload content in the SQLite file, which violates the at-rest encryption guarantee when `EncryptedSerializer` is active. This is a VAL error (caller configuration mistake), not an INTERNAL error.

## Library & Framework Requirements

Same as S-1.10 (inherits crate context):

| Library | Version | Usage |
|---------|---------|-------|
| `rusqlite` | 0.31.x | FTS5 virtual table and queries; feature `bundled` required to ensure FTS5 is compiled in |
| `serde` | 1.x | Serialize `FtsSearchResult` for `ToolOutput` |
| `pregolya-core` | workspace path | `Tool` trait, `PregolyaError` |

**Critical note:** `rusqlite` must be compiled with the `bundled` feature to ensure SQLite FTS5 is available. If `bundled` is not enabled and the system SQLite lacks FTS5, AC-006 (`E-CHKPT-009`) fires at runtime. The `bundled` feature should be enabled in `pregolya-checkpoint/Cargo.toml` to guarantee FTS5 availability.

## File Structure Requirements

Files to CREATE:
- `/pregolya-checkpoint/src/fts.rs` — `FtsSearchConfig`, `FtsSearchResult`, FTS5 schema, FTS index update logic
- `/pregolya-checkpoint/tests/fts_tests.rs` — tests for AC-001..AC-008

Files to MODIFY:
- `/pregolya-checkpoint/src/saver.rs` — add `fts_search` to `CheckpointSaver` trait; add `search_history_tool()` factory
- `/pregolya-checkpoint/src/lib.rs` — re-export `fts` module public types
- `/pregolya-checkpoint/Cargo.toml` — ensure `rusqlite` has `features = ["bundled"]`

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `fts_search` with `limit: 0` | `Err(E-CHKPT-008 FtsLimitZero)` |
| EC-002 | FTS5 extension absent from SQLite build (detected at construction) | `CheckpointSaver::new()` returns `Err(E-CHKPT-009 Fts5Unavailable)` at construction time — not at query time |
| EC-003 | `thread_id: Some("nonexistent")` in FtsSearchConfig | Returns `Ok(vec![])` — no results, no error |
| EC-004 | Query is an empty string `""` | Implementation-defined: either `Ok(vec![])` or returns all results up to limit. Must not panic |
| EC-005 | FTS5 enabled simultaneously with `EncryptedSerializer` | Construction-time `Err(E-CHKPT-010 FtsEncryptionIncompatible)` — FTS5 stores plaintext message content, tool call arguments, and tool results in the SQLite database file; this would write plaintext state and event payload to disk, violating the at-rest encryption guarantee (no plaintext payload may reach persistent storage when `EncryptedSerializer` is active). FTS5 and `EncryptedSerializer` are mutually exclusive by design; `CheckpointSaver::new()` returns the error before any DDL executes. See BC-2.04.008 EC-007 and AC-008. |
