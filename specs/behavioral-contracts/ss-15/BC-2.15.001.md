---
document_type: behavioral-contract
level: L3
bc_id: BC-2.15.001
version: "1.6"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-15
capability: CAP-017
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-memory per module-decomposition.md v1.10."
  - "1.2 (D23/2026-07-22): Priority P2→P1, wave 2→1 per D23 CAP-017 promotion (rolling compaction and per-tool-call approval hook add first-party memory integration surfaces in Wave 1)."
  - "1.3 (F-P159-01, 2026-07-25): Body Traceability Priority P2→P1, Wave 2→Wave 1; VP-MEM-01/02 phases Post-v1→v1 phase — residue from incomplete D23 body sweep (F-P159-01)."
  - "1.4 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.12 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (B-SS15-18-hardening/2026-08-26): TWO gaps from Phase-2 bc-completeness-scan (D-270, burst B). (1) {PC-007} hybrid_search RRF fusion rule specified: Reciprocal Rank Fusion k=60 combining keyword (recency-ranked) and vector (cosine-ranked) results; tie-break by recency; TV-008 added. (2) {EC-006} added: vector-search query/stored embedding-dimension mismatch → E-MEMORY-010 MemoryVectorDimensionMismatch (VAL/Never; minted in error-taxonomy.md burst-A-error-coord); EC-001..EC-005 were already occupied — error-taxonomy.md references this raise site as BC-2.15.001; the edge case is EC-006."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-017
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "f0812aa"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.15.001: KV and Vector Memory Persistence Across Threads (Not Per-Checkpoint)

## Description

`pregolya-memory` provides a long-horizon store that persists key-value entries and
vector embeddings **across threads**, independently of the checkpoint lifecycle. A
memory entry written in one thread (or session) is readable from any other thread in
the same scope — not automatically deleted when a checkpoint is rolled back, a thread
is deleted, or a process restarts. The default backend is SQLite with optional vector
embeddings (OpenAI/Gemini/local). This contract specifies the core persistence and
retrieval semantics: decoupled-from-checkpoint, cross-thread durability, keyword
search, and vector similarity search.

## Preconditions

1. {PRE-001} A `MemoryStore` is configured (default: SQLite at a configured path).
2. {PRE-002} At least one memory entry has been written to the store with a `namespace` key
   and a `value` (string, bytes, or structured JSON).
3. {PRE-003} For vector search: an embedding backend is configured (e.g., local sentence
   transformers or an API-based embedding model).
4. {PRE-004} The write and read operations may use different `thread_id` values.

## Postconditions

**KV persistence:**
1. {PC-001} A key-value entry written via `memory_set(namespace, key, value)` in `thread_A`
   is readable via `memory_get(namespace, key)` in `thread_B`.
2. {PC-002} The entry is not deleted when:
   - The originating thread (`thread_A`) is deleted from the checkpoint store.
   - A checkpoint referencing `thread_A` is rolled back or deleted.
   - The server process restarts (SQLite backend).
3. {PC-003} `memory_get(namespace, key)` returns `None` only if the key was never written or
   was explicitly deleted via `memory_delete(namespace, key)`.

**Keyword search:**
4. {PC-004} `memory_search(namespace, query)` returns all entries in `namespace` whose value
   contains `query` as a substring match (case-insensitive). Results are ordered by
   recency (most recently written first) by default.

**Vector search (when embedding backend configured):**
5. {PC-005} `vector_search(namespace, query_embedding, top_k)` returns the top-K entries
   ranked by cosine similarity between the stored embedding and `query_embedding`.
6. {PC-006} Entries written without an embedding are excluded from vector search results.

**Hybrid search:**
7. {PC-007} `hybrid_search(namespace, query, top_k)` combines keyword search (recency-ranked)
   and vector similarity (cosine-ranked) results via **Reciprocal Rank Fusion (RRF, k=60)**:
   - The keyword component ranks entries by recency (most recently written first = rank 0).
   - The vector component ranks entries by cosine similarity descending (highest cosine = rank 0).
   - Each entry's combined RRF score is: `rrf_score = 1/(60 + r_keyword) + 1/(60 + r_vector)`,
     where `r_keyword` and `r_vector` are the 0-based rank positions in their respective lists.
     An entry present in only one component list contributes only that component's term;
     the missing term contributes 0.
   - After scoring, entries are de-duplicated by `(namespace, key)`; the final list is sorted
     by `rrf_score` descending; ties are broken by recency (most recently written first).
     Up to `top_k` entries are returned; if fewer than `top_k` unique entries exist across
     both component lists, all available entries are returned.

## Invariants

- {INV-001} Memory store state is **orthogonal to checkpoint state**: no code path in the
  checkpoint subsystem may delete memory entries. The two stores are logically
  independent and physically separate (different tables or files).
- {INV-002} The `MemoryStore` trait has at minimum two implementations: an in-memory ephemeral
  backend (for tests) and a SQLite durable backend (for production). The in-memory
  backend is explicitly documented as non-durable.
- {INV-003} Concurrent writes to the same `(namespace, key)` from different threads are
  serialized by the store; the last writer wins (LWW semantics). There is no
  conflict-resolution mechanism in v1 beyond LWW.

## Edge Cases

### EC-001: Vector embedding backend not configured; vector_search called
**Scenario:** A caller invokes `vector_search()` when no embedding backend has been
configured in the `MemoryStore`.
**Expected behavior:** `Err(E-MEMORY-001 EmbeddingBackendNotConfigured)` is returned.
The call does NOT panic, does not return empty results silently, and does not attempt
to generate embeddings via a default provider.

### EC-002: Key-value entry read after originating thread deleted
**Scenario:** `memory_set("user:alice", "preference", "dark mode")` in thread `t1`.
Thread `t1` is deleted via `DELETE /threads/t1`. `memory_get("user:alice", "preference")`
called from thread `t2`.
**Expected behavior:** Returns `Some("dark mode")`. Memory store is unaffected by
thread deletion.

### EC-003: Concurrent writes to same key (LWW)
**Scenario:** Two graph nodes in different threads write to `("shared_ns", "counter")`
simultaneously with values "A" and "B".
**Expected behavior:** One write wins; subsequent reads return either "A" or "B" (the
later writer's value). The store does not corrupt the entry or return a partial value.

### EC-004: MemoryStore at storage capacity (disk full)
**Scenario:** The SQLite file reaches the filesystem's disk-full condition during a
`memory_set()` call.
**Expected behavior:** `Err(E-MEMORY-002 StorageFull { backend: "sqlite", path: "<path>" })`
is returned. The existing store state is not corrupted; previously written entries
remain readable.

### EC-006: Vector-search query dimension mismatches stored embedding dimension
**Scenario:** `vector_search(namespace, query_embedding, top_k)` is called with a
`query_embedding` of dimension 768, but all stored embeddings in `namespace` were indexed
at dimension 1536 (different embedding backend or model change since write time).
**Expected behavior:** `Err(E-MEMORY-010 MemoryVectorDimensionMismatch { query_dim: 768,
stored_dim: 1536 })` is returned. No partial result set is returned. The store state is
not corrupted. The caller must either fix the query dimension or re-index the stored entries
under the matching backend. (Stable anchor: {EC-006}. E-MEMORY-010 minted in error-taxonomy.md
burst-A-error-coord; this BC is the authoritative raise site.)

### EC-005: Hybrid search with no vector backend; keyword matches exist
**Scenario:** `hybrid_search()` called with no embedding backend configured; some
keyword matches exist.
**Expected behavior:** Keyword results are returned; the vector component is skipped
with a `DEBUG` log: `"hybrid_search: vector component skipped — no embedding backend
configured"`. This is NOT an error; hybrid search degrades gracefully to keyword-only.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `memory_set("ns", "key1", "dark mode")` in thread_A; `memory_get("ns", "key1")` in thread_B | `Some("dark mode")` | Cross-thread read |
| TV-002 | Write `("ns", "key1", "dark mode")`; delete thread_A (all checkpoints removed); `memory_get("ns", "key1")` from thread_B | `Some("dark mode")` | Checkpoint deletion does not remove memory |
| TV-003 | Write 5 entries in "ns" containing "weather"; `memory_search("ns", "weather")` | Returns all 5 matching entries, most recent first | Keyword search |
| TV-004 | Configure local embedding backend; write entry with pre-computed embedding; `vector_search("ns", similar_embedding, top_k=1)` | Returns the entry with highest cosine similarity | Vector search happy path |
| TV-005 | No embedding backend; `vector_search(...)` called | `Err(E-MEMORY-001 EmbeddingBackendNotConfigured)` | Embedding backend required for vector search |
| TV-006 | Restart server (SQLite backend); `memory_get("ns", "key1")` | `Some("dark mode")` (persists across restart) | Durable persistence |
| TV-007 | Restart server (in-memory backend); `memory_get("ns", "key1")` | `None` (in-memory is non-durable) | In-memory backend documented as ephemeral |
| TV-008 | Write entries A (recency rank 0, cosine rank 1), B (recency rank 1, cosine rank 0), C (keyword only, recency rank 2); `hybrid_search("ns", query, top_k=3)` | A: rrf=1/60+1/61≈0.0330; B: rrf=1/62+1/60≈0.0328; C: rrf=1/62≈0.0161. Order: A, B, C | RRF fusion ranking (PC-007) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-MEM-01 | Memory entries survive checkpoint deletion on the same thread | Integration test (write memory, delete all checkpoints for thread, read memory) | v1 phase |
| VP-MEM-02 | Memory entries survive server restart with SQLite backend | Integration test (write, restart, read) | v1 phase |

## Related BCs

- BC-2.15.002 — depends on: tier isolation is the access-control layer over the persistence defined here
- BC-2.15.003 — depends on: GDPR erasure operates on the store defined here

## Architecture Anchors

- `pregolya-memory/src/store.rs` — `MemoryStore` trait definition
- `pregolya-memory/src/sqlite.rs` — SQLite durable backend implementation
- `pregolya-memory/src/in_memory.rs` — ephemeral in-memory backend (test/dev)
- `pregolya-memory/src/search.rs` — keyword, vector, and hybrid search implementations

## Story Anchor

S-1.12

## VP Anchors

- VP-MEM-01, VP-MEM-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-017 |
| Capability Anchor Justification | CAP-017 ("Long-Horizon Cross-Session Memory Store (KV + Vector)") per capabilities-p1-p2.md §CAP-017 — this BC specifies the KV and vector persistence mechanics, the cross-thread durability guarantee, and the hybrid search surface that are the foundational behaviors named in CAP-017 |
| L2 Domain Invariants | — (no DI directly applies; CONFLICT-7 memory scope model is the primary reference) |
| Domain C Forcing Function | domain-c-openclaw.md §2.6 — "SQLite with optional vector embeddings" + hybrid retrieval; §7 memory checklist item "[PARTIAL] Long-horizon cross-session store (KV + vector) decoupled from checkpoints" |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration) |
| Module | pregolya-memory |
