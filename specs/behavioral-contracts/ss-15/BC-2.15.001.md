---
document_type: behavioral-contract
level: L3
bc_id: BC-2.15.001
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P2
subsystem: SS-15
capability: CAP-017
wave: 2
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-memory per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-017
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "8bc9bb2"
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

`ferrochain-memory` provides a long-horizon store that persists key-value entries and
vector embeddings **across threads**, independently of the checkpoint lifecycle. A
memory entry written in one thread (or session) is readable from any other thread in
the same scope — not automatically deleted when a checkpoint is rolled back, a thread
is deleted, or a process restarts. The default backend is SQLite with optional vector
embeddings (OpenAI/Gemini/local). This contract specifies the core persistence and
retrieval semantics: decoupled-from-checkpoint, cross-thread durability, keyword
search, and vector similarity search.

## Preconditions

1. A `MemoryStore` is configured (default: SQLite at a configured path).
2. At least one memory entry has been written to the store with a `namespace` key
   and a `value` (string, bytes, or structured JSON).
3. For vector search: an embedding backend is configured (e.g., local sentence
   transformers or an API-based embedding model).
4. The write and read operations may use different `thread_id` values.

## Postconditions

**KV persistence:**
1. A key-value entry written via `memory_set(namespace, key, value)` in `thread_A`
   is readable via `memory_get(namespace, key)` in `thread_B`.
2. The entry is not deleted when:
   - The originating thread (`thread_A`) is deleted from the checkpoint store.
   - A checkpoint referencing `thread_A` is rolled back or deleted.
   - The server process restarts (SQLite backend).
3. `memory_get(namespace, key)` returns `None` only if the key was never written or
   was explicitly deleted via `memory_delete(namespace, key)`.

**Keyword search:**
4. `memory_search(namespace, query)` returns all entries in `namespace` whose value
   contains `query` as a substring match (case-insensitive). Results are ordered by
   recency (most recently written first) by default.

**Vector search (when embedding backend configured):**
5. `vector_search(namespace, query_embedding, top_k)` returns the top-K entries
   ranked by cosine similarity between the stored embedding and `query_embedding`.
6. Entries written without an embedding are excluded from vector search results.

**Hybrid search:**
7. `hybrid_search(namespace, query, top_k)` combines keyword match and vector
   similarity results, de-duplicates by key, and returns up to `top_k` results.
   De-duplication keeps the higher-ranked copy.

## Invariants

- Memory store state is **orthogonal to checkpoint state**: no code path in the
  checkpoint subsystem may delete memory entries. The two stores are logically
  independent and physically separate (different tables or files).
- The `MemoryStore` trait has at minimum two implementations: an in-memory ephemeral
  backend (for tests) and a SQLite durable backend (for production). The in-memory
  backend is explicitly documented as non-durable.
- Concurrent writes to the same `(namespace, key)` from different threads are
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

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-MEM-01 | Memory entries survive checkpoint deletion on the same thread | Integration test (write memory, delete all checkpoints for thread, read memory) | Post-v1 |
| VP-MEM-02 | Memory entries survive server restart with SQLite backend | Integration test (write, restart, read) | Post-v1 |

## Related BCs

- BC-2.15.002 — depends on: tier isolation is the access-control layer over the persistence defined here
- BC-2.15.003 — depends on: GDPR erasure operates on the store defined here

## Architecture Anchors

- `ferrochain-memory/src/store.rs` — `MemoryStore` trait definition
- `ferrochain-memory/src/sqlite.rs` — SQLite durable backend implementation
- `ferrochain-memory/src/in_memory.rs` — ephemeral in-memory backend (test/dev)
- `ferrochain-memory/src/search.rs` — keyword, vector, and hybrid search implementations

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-MEM-01, VP-MEM-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-017 |
| Capability Anchor Justification | CAP-017 ("Long-Horizon Cross-Session Memory Store (KV + Vector)") per capabilities-p1-p2.md §CAP-017 — this BC specifies the KV and vector persistence mechanics, the cross-thread durability guarantee, and the hybrid search surface that are the foundational behaviors named in CAP-017 |
| L2 Domain Invariants | — (no DI directly applies; CONFLICT-7 memory scope model is the primary reference) |
| Domain C Forcing Function | domain-c-openclaw.md §2.6 — "SQLite with optional vector embeddings" + hybrid retrieval; §7 memory checklist item "[PARTIAL] Long-horizon cross-session store (KV + vector) decoupled from checkpoints" |
| Priority | P2 |
| Wave | Wave 2 |
| Test Types | I (integration) |
| Module | ferrochain-memory |
