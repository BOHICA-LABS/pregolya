---
document_type: story
level: ops
story_id: S-1.12
epic_id: E-06
version: "1.2"
status: draft
producer: story-writer
timestamp: 2026-08-24T12:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.001.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.002.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "86f8392"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.04, S-1.02]
blocks: [S-1.13]
behavioral_contracts: [BC-2.15.001, BC-2.15.002, BC-2.15.003]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-memory
subsystems: [SS-15]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.12: Memory KV and Vector Persistence, Tenant Tier Isolation, and GDPR Erasure

## Narrative

- **As a** pregolya library user building long-horizon agents
- **I want to** store and retrieve key-value entries, vector embeddings, and perform hybrid search across a persistent memory store with strict per-scope isolation and GDPR erasure support
- **So that** agents can maintain context across sessions, tenant data cannot leak across scope boundaries, and user data can be atomically erased on demand

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.15.001 | MemoryStore CRUD — KV, Vector, Hybrid Search, Orthogonal to Checkpoint | AC-001..AC-005 |
| BC-2.15.002 | Scope Isolation — User/App/Session Tiers (NE-12 tenancy analogue) | AC-006..AC-010 |
| BC-2.15.003 | GDPR Erasure — Atomic Across All Three Memory Tiers | AC-011..AC-015 |

## Acceptance Criteria

### AC-001 (traces to BC-2.15.001 PC-001)
`MemoryStore::memory_set(scope, key, value)` stores a key-value pair. `memory_get(scope, key)` retrieves it. `memory_delete(scope, key)` removes it. Concurrency semantics are last-write-wins (LWW). All three methods return `Result<_, PregolyaError>` and do NOT return `None` on storage errors — errors propagate as `Err` per DI-014. Verified by `test_BC_2_15_001_kv_set_get_delete()`.

### AC-002 (traces to BC-2.15.001 PC-005)
`MemoryStore::vector_search(scope, query_embedding, top_k)` returns the top-K nearest neighbors by cosine similarity. When no vector backend is configured, returns `Err(PregolyaError { code: "E-MEMORY-001", message: "EmbeddingBackendNotConfigured: ...", .. })`. Verified by `test_BC_2_15_001_vector_search()` and `test_BC_2_15_001_vector_search_no_backend_error()`.

### AC-003 (traces to BC-2.15.001 PC-007)
`MemoryStore::hybrid_search(scope, query_text, query_embedding, top_k)` combines KV full-text and vector results with a configurable fusion strategy. Returns the top-K merged results. When the vector backend is not configured, hybrid search operates in KV-only mode (no error). Verified by `test_BC_2_15_001_hybrid_search()`.

### AC-004 (traces to BC-2.15.001 INV-001)
Memory entries persist across `thread_id` boundaries — they are NOT scoped to a single graph execution thread. Memory is orthogonal to the checkpoint lifecycle (S-1.10). A memory entry written in thread A is retrievable in thread B when both use the same scope. Verified by `test_BC_2_15_001_cross_thread_persistence()`.

### AC-005 (traces to BC-2.15.001 EC-004)
When the storage backend is full, `memory_set` returns `Err(PregolyaError { code: "E-MEMORY-002", message: "StorageFull: ...", .. })`. The in-memory ephemeral backend (for tests) imposes no size limit and always returns `Ok`. Verified by `test_BC_2_15_001_storage_full_error()` (with a mock backend that rejects after N entries).

### AC-006 (traces to BC-2.15.002 PC-001)
`MemoryScope::User(user_id)`, `MemoryScope::App(app_id)`, and `MemoryScope::Session(session_id)` each produce SQL WHERE clauses that isolate their data. A `memory_get` call with `MemoryScope::User("alice")` does NOT return entries written with `MemoryScope::User("bob")`. Verified by `test_BC_2_15_002_user_scope_isolation()`.

### AC-007 (traces to BC-2.15.002 PC-004)
There is no code path that allows reading across scope boundaries without an explicit `AdminContext`. `memory_get` with one scope cannot retrieve entries stored under a different scope. Verified by `test_BC_2_15_002_no_implicit_scope_elevation()`.

### AC-008 (traces to BC-2.15.002 INV-001)
The scope fields (`user_id`, `app_id`, `session_id`) flow from the `MemoryScope` enum variant through to the SQL WHERE clause without collapsing or merging. There is no intermediate representation that discards scope information. Verified by `test_BC_2_15_002_scope_fields_in_sql_where()` (inspects generated SQL via a query interceptor).

### AC-009 (traces to BC-2.15.002 INV-002)
If the caller's `MemoryScope` does not match the stored entry's scope and the caller is not an admin, returns `Err(PregolyaError { code: "E-MEMORY-003", message: "ScopeAccessDenied: ...", .. })`. Verified by `test_BC_2_15_002_scope_access_denied_error()`.

### AC-010 (traces to BC-2.15.002 EC-001)
If no scope context is available (e.g., anonymous call without scope), returns `Err(PregolyaError { code: "E-MEMORY-004", message: "NoScopeContext: ...", .. })`. `admin_list_all` requires `AdminContext` — calling without it returns `Err(E-MEMORY-004)`. `memory_delete_session(session_id)` deletes all entries for a session scope. Verified by `test_BC_2_15_002_no_scope_context_error()`.

### AC-011 (traces to BC-2.15.003 INV-001)
`MemoryStore::gdpr_erase(user_id, admin_ctx)` atomically erases all data across all three memory tiers (KV, vector, hybrid) for the given `user_id`. The operation is atomic — either all data is erased or none is (transactional). Verified by `test_BC_2_15_003_gdpr_erase_atomic()`.

### AC-012 (traces to BC-2.15.003 PC-004)
`gdpr_erase` returns `Ok(GdprErasureReceipt { user_id, erased_at, user_scoped_count, app_scoped_authored_count, session_scoped_count })`. All five fields are present. `app_scoped_authored_count` counts app-scoped entries where `author_id == user_id` (not all app-scoped entries). Verified by `test_BC_2_15_003_gdpr_erase_receipt_fields()`.

### AC-013 (traces to BC-2.15.003 EC-005)
`gdpr_erase` called without `AdminContext` returns `Err(PregolyaError { code: "E-MEMORY-006", message: "InsufficientPrivilege: operation '<operation>' requires <required>", .. })`. No data is erased. Verified by `test_BC_2_15_003_gdpr_erase_requires_admin_context()`.

### AC-014 (traces to BC-2.15.003 EC-002)
If the erasure transaction partially fails (e.g., vector backend deletion succeeds but KV deletion fails), the error surfaces as `Err(PregolyaError { code: "E-MEMORY-005", message: "ErasurePartialFailure: ...", .. })`. The transaction is rolled back — no partial erasure persists. Verified by `test_BC_2_15_003_erasure_partial_failure_rollback()` (mock backend that fails mid-transaction).

### AC-015 (traces to BC-2.15.003 EC-004)
App-scoped entries without an `author_id` (created by system, not attributable to a user) are NOT erased by `gdpr_erase`. Before returning, `gdpr_erase` emits a tracing WARN event with `event_type = "memory.gdpr_unattributed_session_entries"` if any such entries exist for the user's sessions. WARN is required (not DEBUG) because unattributed session entries represent a GDPR compliance gap that operators must observe (BC-2.15.003 EC-004 canonical). Verified by `test_BC_2_15_003_unattributed_entries_warn_log()`.

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `MemoryStore` trait, `MemoryScope` enum, `GdprErasureReceipt` | `pregolya_memory` (`lib.rs`) | pregolya-memory | Pure (trait and data type definitions; no I/O) |
| `MemoryScope` scope-to-SQL-WHERE mapping | `pregolya_memory::scope` | pregolya-memory | Pure (deterministic enum-to-SQL predicate; no I/O) |
| `SqliteMemoryStore` (`memory_set`, `memory_get`, `memory_delete`, `vector_search`, `hybrid_search`) | `pregolya_memory::store` | pregolya-memory | Effectful Shell (SQLite reads and writes via `rusqlite`; optional vector backend query) |
| `gdpr_erase` transactional erasure | `pregolya_memory::gdpr` | pregolya-memory | Effectful Shell (`BEGIN IMMEDIATE` / `COMMIT` SQLite transaction via `rusqlite`; tracing WARN event emission on unattributed entries) |
| `EphemeralMemoryStore` (in-memory test backend) | `pregolya_memory::ephemeral` | pregolya-memory | Pure (in-memory `HashMap`; `#[cfg(test)]`) |

**Subsystem anchor:** SS-15 owns this story's scope because SS-15 is the Long-Horizon Memory subsystem (`pregolya-memory` crate) per ARCH-INDEX Subsystem Registry. Pure-core / effectful-shell boundary: `MemoryStore` trait, `MemoryScope`, and `GdprErasureReceipt` are pure core (data/trait definitions); `SqliteMemoryStore`, `gdpr_erase`, and the vector backend interaction are effectful shells. `EphemeralMemoryStore` is pure-core for test use.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `MemoryStore` trait, `MemoryScope`, `GdprErasureReceipt` | Pure | Type and trait definitions; no I/O side effects |
| `MemoryScope` scope-to-SQL-WHERE mapping | Pure | Deterministic pure function; produces SQL predicate strings from enum variants; no database access |
| `SqliteMemoryStore::memory_set` / `memory_get` / `memory_delete` | Effectful Shell | SQLite DML (INSERT, SELECT, DELETE) via `rusqlite`; persistent I/O |
| `SqliteMemoryStore::vector_search` / `hybrid_search` | Effectful Shell | SQLite SELECT + optional `Arc<dyn VectorBackend>` query; persistent I/O |
| `MemoryStore::gdpr_erase` (`SqliteMemoryStore` impl) | Effectful Shell | `BEGIN IMMEDIATE` SQLite transaction across all three tiers; tracing WARN event emission on unattributed entries |
| `EphemeralMemoryStore` (`#[cfg(test)]`) | Pure | In-memory `HashMap`; no persistent I/O; no side effects outside the object |

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~5,500 |
| BC files (3 BCs: BC-2.15.001/002/003) | ~7,500 |
| Architecture module-decomposition.md (SS-15 section) | ~1,000 |
| pregolya-memory crate skeleton | ~3,000 |
| Test files | ~4,000 |
| **Total** | **~21,000** |

Within the 20-30% agent context window threshold.

## Tasks

- [ ] Create `pregolya-memory/Cargo.toml`
- [ ] Create `pregolya-memory/src/lib.rs` — `MemoryStore` trait, `MemoryScope` enum, `GdprErasureReceipt`
- [ ] Create `pregolya-memory/src/store.rs` — `SqliteMemoryStore` implementing `MemoryStore`; schema with `author_id` column; KV table + FTS table + vector table (optional backend)
- [ ] Create `pregolya-memory/src/scope.rs` — `MemoryScope` variants, scope-to-SQL-WHERE mapping; NE-12 tenancy enforcement
- [ ] Create `pregolya-memory/src/gdpr.rs` — `gdpr_erase` transactional implementation, `GdprErasureReceipt`, AdminContext guard
- [ ] Create `pregolya-memory/src/ephemeral.rs` — in-memory backend for tests (no persistence, no size limit)
- [ ] Write unit tests for all 15 ACs
- [ ] Add `pregolya-memory` to workspace `Cargo.toml` members
- [ ] Run `just iter pregolya-memory` — all tests green

## Previous Story Intelligence

- S-1.04 (Runnable Trait and Pipe) established `PregolyaError` and the `Result`-returning constructor pattern (DI-008). Memory constructors must follow the same pattern.
- S-1.02 (Error Policy Enforcement) established error propagation rules. DI-014 (Error Propagation) requires storage errors to surface as `Err`, never masked as `None`.
- N/A for previous memory stories — this is the first memory story.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-memory`:

1. `MemoryStore` is a trait (`trait MemoryStore: Send + Sync`), not a concrete struct. `SqliteMemoryStore` is the concrete production implementation. `EphemeralMemoryStore` is the in-memory test backend.
2. Scope fields MUST flow from `MemoryScope` to SQL WHERE without collapsing. No intermediate representation may merge scopes or discard scope fields. This enforces the NE-12 tenancy analogue.
3. `author_id` MUST be a column in the app-scoped memory table. It is populated when a user creates an app-scoped entry and is NULL for system-created entries. `gdpr_erase` counts non-NULL `author_id == user_id` rows for `app_scoped_authored_count`.
4. The GDPR erasure transaction MUST use SQLite `BEGIN IMMEDIATE` / `COMMIT` / `ROLLBACK` — no partial erasure state must be visible.
5. All memory entries returned by `memory_get` on a storage error MUST return `Err`, not `None`. DI-014 compliance.
6. `MemoryScope`, `GdprErasureReceipt`, `AdminContext` must all carry `#[non_exhaustive]`.
7. `event_type` values that must be in the Canonical Structured Event Catalog: `"memory.gdpr_unattributed_session_entries"` (WARN, per-erase) — BC-2.15.003 EC-004 canonical log level.
8. No `unwrap()` / `expect()` in non-test code. No `println!`.

## Library & Framework Requirements

Derived from `architecture/dependency-graph.md` external dependency table:

| Library | Version | Usage |
|---------|---------|-------|
| `rusqlite` | 0.31.x, feature `bundled` | SQLite backend for KV and FTS storage |
| `serde` | workspace pin | Serialization of stored values |
| `serde_json` | workspace pin | JSON encoding of values |
| `tokio` | workspace pin | Async trait methods |
| `tracing` | workspace pin | `"memory.gdpr_unattributed_session_entries"` WARN event (BC-2.15.003 EC-004) |
| `pregolya-core` | workspace path | `PregolyaError` |

**Optional vector backend:** The vector storage backend (e.g., sqlite-vss or an external vector DB) is optional. When not configured, `vector_search` returns E-MEMORY-001. The concrete backend type is configurable via `MemoryStoreConfig`. Do not hardcode a specific vector library — use a trait object `Arc<dyn VectorBackend>`.

**Forbidden Dependencies:** `pregolya-memory` MUST NOT depend on `pregolya-checkpoint`, `pregolya-graph`, or `pregolya-sandbox`. Memory is a primitive orthogonal to those subsystems.

## File Structure Requirements

Files to CREATE:
- `/pregolya-memory/Cargo.toml`
- `/pregolya-memory/src/lib.rs`
- `/pregolya-memory/src/store.rs`
- `/pregolya-memory/src/scope.rs`
- `/pregolya-memory/src/gdpr.rs`
- `/pregolya-memory/src/ephemeral.rs`
- `/pregolya-memory/tests/kv_tests.rs`
- `/pregolya-memory/tests/scope_tests.rs`
- `/pregolya-memory/tests/gdpr_tests.rs`

Files to MODIFY:
- `/Cargo.toml` — add `"pregolya-memory"` to `[workspace] members`

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `memory_get` for non-existent key | Returns `Ok(None)` — not-found is not an error |
| EC-002 | `memory_set` with same key twice (LWW) | Second write wins; first value is overwritten |
| EC-003 | `vector_search` with top_k = 0 | Returns `Ok(vec![])` or `Err` depending on validation; must not panic |
| EC-004 | `gdpr_erase` for user with no stored data | Returns `Ok(GdprErasureReceipt { ..counts all zero.. })` — not an error |
| EC-005 | App-scoped entry has `author_id = NULL` (system-created) | Not erased by `gdpr_erase`; counted in unattributed warning log event |

## Escalations (Routes to Product-Owner)

| Story | AC | Current Cite | Asserted Behavior | BC Checked | Issue | Proposed Resolution |
|-------|----|--------------|-------------------|------------|-------|---------------------|
| S-1.12 | AC-015 | BC-2.15.003 EC-004 | `tracing::WARN` event with `event_type = "memory.gdpr_unattributed_session_entries"` | BC-2.15.003 EC-004 | RESOLVED M3c: PO adjudicated BC is canonical — story AC-015 corrected to WARN per BC-2.15.003 EC-004 | Resolved — AC-015 updated to WARN; BC not amended |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.2 | 2026-08-24 | ADR-027 M3c: escalation-resolution AC corrections — AC-015 log level DEBUG→WARN per BC-2.15.003 EC-004 (BC canonical) | M3c/ADR-027 |
| 1.1 | 2026-08-24 | ADR-027 M3: AC traces re-cited to stable clause anchors | M3/ADR-027 |
| 1.0 | 2026-08-18 | Initial authoring | story-writer |
