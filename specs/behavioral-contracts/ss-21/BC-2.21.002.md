---
document_type: behavioral-contract
level: L3
bc_id: BC-2.21.002
version: "1.5"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-21
capability: CAP-029
crate: pregolya-vectorstores
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-21 VectorStore Abstraction"
  - "1.1 (F-P224/H-2/2026-07-21): Write-time zero-norm guard added per ADR-014 Decision 5. `add_texts` and `from_texts_sync` now return `Err(E-VS-004)` with `document_index` context (0-based) when any document's embedding vector has L2 norm == 0.0 at write time; no documents from the batch are persisted. Distinct from E-VS-001 (search-time cosine guard). Added: PC4 (write-time zero-norm precondition/postcondition), EC-007, TV-006. E-VS-004 minted in error-taxonomy.md v1.28."
  - "1.2 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B): Component::VS → Component::Vs, Category::VAL → Category::Val in PC-1 zero-norm inline code (from_texts_sync postcondition)."
  - "1.3 (fix-burst-280/F-P175-A25/ADR-010/2026-07-28): Remove phantom `document_index` field from all E-VS-004 construction examples — ADR-010 §F-P174-303-adjudication (no-context-field ruling, later authoritative) rules no context field on PregolyaError; diagnostics go in message string. Per ADR-010 §no-context-field-decision the E-VS-004 message is static (no index placeholder). Five sites converted: PC4 precondition prose (phantom field reference removed), PC1 from_texts_sync struct literal → PregolyaError::new(Component::Vs, Category::Val, RetryHint::Never, ...), PC2 add_texts inline code same, EC-007 expected output same, TV-006 expected output same. TD-VSDD-060 sibling sweep: EC-002/EC-006/TV-005 use shorthand `{ ... }` — classified (c) verification-field descriptions, not construction examples; left as-is."
  - "1.4 (wave-b-b7-notation-sweep/2026-07-29): ADR-010 §Class 3 notation sweep — 4 violations corrected. (1) PC-1 embedding-failure arm: CLASS3_ASCII_ELLIPSIS_VIOLATION — `PregolyaError { ... }` → `PregolyaError { .. }`. (2) EC-002 expected-output: CLASS3_ASCII_ELLIPSIS_VIOLATION — same replacement. (3) EC-006 expected-output: CLASS3_MISSING_DOTDOT — `PregolyaError { code: \"E-VS-002\" }` → add `, ..`. (4) TV-005 expected-output: CLASS3_ASCII_ELLIPSIS_VIOLATION — `PregolyaError { ... }` → `PregolyaError { .. }`. No security semantics or VP anchors altered."
  - "1.5 (fix-burst-287/ADR-010-C3/2026-08-01): ADR-010 Class 3 notation fix — 4 violations. (1) PC-1 from_texts_sync postcondition: multi-line PregolyaError::new(..., \"E-VS-004\", ...) → Err(PregolyaError { code: \"E-VS-004\", .. }). (2) PC-2 add_texts postcondition: same conversion. (3) EC-007 table cell: same conversion. (4) TV-006 table cell: same conversion. Bare constructor form forbidden in prose/table context per ADR-010 Class 3 rules."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-029
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "d4c75fa"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.21.002: InMemoryVectorStore — Arc<dyn Embeddings> DI; RwLock Interior Mutability; Vec<f32> Cosine; VectorStoreFactory Constructor

## Description

`InMemoryVectorStore` is the reference `VectorStore` implementation in
`pregolya-vectorstores: vectorstores::memory`. It stores documents and their pre-computed
embedding vectors in `RwLock<Vec<(Document, Vec<f32>)>>`. An `Arc<dyn Embeddings>` is
injected at construction time via `VectorStoreFactory::from_texts_sync` — Arc-DI wiring per
workspace convention; no placeholder construction is permitted (production-grade default).
Embedding vectors are generated at `add_texts` time (not lazily at search time). Cosine
similarity is computed from `Vec<f32>` inner products without `ndarray` (semport §8 avoidance:
no heavy linear algebra dep in core vector path). The zero-norm guard (BC-2.21.003) fires
unconditionally before any cosine division.

## Preconditions

1. `InMemoryVectorStore::from_texts_sync(texts, arc_embeddings, config)` is called with a
   non-null `Arc<dyn Embeddings>` (Arc-DI wiring — no placeholder, no `Arc::new(SomeThing::placeholder())`).
2. `arc_embeddings.embed_documents(texts)` succeeds and returns `Vec<Vec<f32>>` where each
   inner `Vec<f32>` is non-empty and has the same dimensionality as the query embedding.
3. Concurrent read and write access may occur; `RwLock` serializes writes.
4. **Zero-norm write-time guard:** before any `(Document, Vec<f32>)` pair is appended to
   the internal store (in both `from_texts_sync` and `add_texts`), the L2 norm of each
   embedding vector is checked. If `norm == 0.0` for the vector at batch position `i`,
   `from_texts_sync` / `add_texts` returns `Err(E-VS-004)`
   and NO documents from the batch are persisted (all-or-nothing; ADR-014 Decision 5).

## Postconditions

1. `from_texts_sync(texts, arc_embeddings, config)`:
   - Calls `arc_embeddings.embed_documents(texts.clone()).await` to pre-compute all document
     embeddings.
   - Checks each embedding vector's L2 norm before persisting: if any vector has norm == 0.0,
     returns `Err(PregolyaError { code: "E-VS-004", .. })`.
     No `InMemoryVectorStore` is constructed (ADR-014 Decision 5 — all-or-nothing).
   - Stores each `(Document { page_content: text, ... }, Vec<f32>)` pair in the internal
     `RwLock<Vec<(Document, Vec<f32>)>>`.
   - Returns `Ok(InMemoryVectorStore { ... })` — the store is ready for search immediately.
   - On embedding failure: returns `Err(PregolyaError { .. })` propagated from the
     `Embeddings` impl (no partial construction, DI-008).
2. `add_texts(texts, metadatas)`:
   - Calls `arc_embeddings.embed_documents(new_texts).await` to embed the new texts.
   - Checks each embedding vector's L2 norm before acquiring the write lock: if any vector
     has norm == 0.0, returns `Err(PregolyaError { code: "E-VS-004", .. })`;
     no documents from the batch are appended (all-or-nothing per Invariant 2, DI-014).
   - Acquires a write lock on the `RwLock` and appends new `(Document, Vec<f32>)` pairs.
   - Returns `Ok(Vec<String>)` of assigned document IDs.
3. `similarity_search(query, k)`:
   - Calls `arc_embeddings.embed_query(query).await` to embed the query.
   - Acquires a read lock; computes cosine similarity between the query vector and each
     stored document vector; zero-norm guard fires per BC-2.21.003.
   - Returns top-k documents by descending similarity score (no score, only documents).
4. `similarity_search_with_score(query, k)`:
   - Same as `similarity_search` but returns `Vec<(Document, f32)>` with normalized scores
     ∈ [0.0, 1.0] (`(cosine + 1.0) / 2.0` normalization).
5. Cosine similarity is computed as pure `Vec<f32>` inner products: dot product divided by
   the product of L2 norms. No `ndarray`, no BLAS, no SIMD intrinsics (pure safe Rust).

## Invariants

1. **Arc-DI is mandatory.** `InMemoryVectorStore` MUST be constructed with a real `Arc<dyn Embeddings>`.
   Any constructor variant that accepts a placeholder or `None` is a production-grade violation.
2. **Embeddings are pre-computed at write time.** `add_texts` embeds immediately; search queries
   do NOT re-embed documents. If `embed_documents` fails during `add_texts`, the entire batch
   fails — no partial-success with some documents embedded and others not (DI-014).
3. **`RwLock` not `Mutex`.** Multiple concurrent reads are permitted (read-lock is shared);
   writes are exclusive. This maximizes read throughput for search-heavy workloads.
4. **Cosine scores are in `[-1.0, 1.0]`** before normalization. `similarity_search_with_score`
   maps them to `[0.0, 1.0]` via `(raw + 1.0) / 2.0`.
5. **No `ndarray` dependency.** The cosine implementation uses only `std::iter` methods and
   basic arithmetic on `Vec<f32>`. Adding `ndarray` as a dep of `pregolya-vectorstores` is
   a violation of semport §8 avoidance.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `from_texts_sync` called with empty `texts` | `Ok(store)` with empty internal storage; subsequent searches return `Ok(vec![])` |
| EC-002 | `add_texts` fails because `embed_documents` returns `Err` | `Err(PregolyaError { .. })` — none of the new texts are added to the store (atomic batch: all-or-nothing) |
| EC-003 | `similarity_search` with `k > stored_doc_count` | `Ok(all_stored_docs)` — returns all available docs (fewer than k); not an error |
| EC-004 | Concurrent `add_texts` and `similarity_search` | `RwLock` ensures no data race; `similarity_search` holds a read lock that cannot interleave with the write lock of `add_texts` |
| EC-005 | Two document vectors with identical embeddings | Both returned in similarity search; ordering between them is implementation-defined (e.g., stable sort by insertion order) |
| EC-006 | Embedding dimensionality mismatch between stored docs and query vector | `Err(PregolyaError { code: "E-VS-002", .. })` — dimensionality mismatch detected before cosine computation |
| EC-007 | `add_texts(["doc A", "doc B"], None)` where "doc B"'s embedding is `vec![0.0f32; 768]` (zero-norm; position 1 in batch) | `Err(PregolyaError { code: "E-VS-004", .. })` — batch rejected; "doc A" is NOT persisted (all-or-nothing; ADR-014 Decision 5) |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `from_texts_sync(["doc A", "doc B"], mock_embeddings, Config::default())` | `Ok(InMemoryVectorStore { docs: 2 })` | happy-path (construction) |
| TV-002 | `store.similarity_search("query matching doc A", 1)` | `Ok(vec![Document { page_content: "doc A" }])` — doc A ranked higher | happy-path (search) |
| TV-003 | `store.similarity_search_with_score("query", 2)` | `Ok(vec![(doc_a, 0.9), (doc_b, 0.7)])` — scores in [0.0, 1.0] | happy-path (scored search) |
| TV-004 | `store.add_texts(["doc C"], None)` → `store.similarity_search("C", 1)` | `Ok(vec![Document { page_content: "doc C" }])` — newly added doc searchable | happy-path (add then search) |
| TV-005 | `from_texts_sync(...)` when `embed_documents` returns `Err` | `Err(PregolyaError { .. })` — construction fails | error-case (embedding failure) |
| TV-006 | `store.add_texts(["doc A", "doc B"], None)` where mock embeddings return `[vec![1.0f32; 3], vec![0.0f32; 3]]` (doc B has zero L2 norm; position 1 in batch) | `Err(PregolyaError { code: "E-VS-004", .. })` — neither doc persisted | error-case (write-time zero-norm, ADR-014 Decision 5) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.21.002-A | Cosine similarity values produced by `similarity_search_with_score` are in [0.0, 1.0] | proptest — random non-zero Vec<f32> pairs; assert score ∈ [0.0, 1.0] after normalization |
| VP-2.21.002-B | Partial-success in `add_texts` is impossible — if any embedding fails, no docs are added | unit test — mock embeddings fail on second text; assert store doc count unchanged after error |

## Related BCs

- BC-2.21.001 — depends on: InMemoryVectorStore is a concrete VectorStore impl; it must satisfy all postconditions of BC-2.21.001
- BC-2.21.003 — composes with: zero-norm guard fires before every cosine computation in this store; see BC-2.21.003 for the E-VS-001 contract
- BC-2.20.003 — depends on: VectorStoreRetriever wraps InMemoryVectorStore via as_retriever()

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-21, `vectorstores::memory` module
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 (InMemoryVectorStore struct, Arc<dyn Embeddings> DI, RwLock interior mutability, Vec<f32> cosine, no ndarray)
- `architecture/decisions/ADR-017-embeddings-trait-provider-integration.md` — Embeddings trait shape (Arc<dyn Embeddings> at injection point)

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-21 story]_

## VP Anchors

- VP-2.21.002-A, VP-2.21.002-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-029 |
| Capability Anchor Justification | CAP-029 ("InMemoryVectorStore — Arc<dyn Embeddings> DI; RwLock Interior Mutability; Vec<f32> Cosine; E-VS-001 Zero-Norm Guard") per capabilities-p1-p2.md §CAP-029 — this BC specifies the Arc-DI wiring, RwLock interior mutability, Vec<f32> cosine computation, and VectorStoreFactory constructor that CAP-029 defines as the InMemoryVectorStore's implementation contract (zero-norm guard is in sibling BC-2.21.003) |
| L2 Domain Invariants | DI-008 (from_texts_sync, add_texts, similarity_search all return Result; no .unwrap()), Arc-DI wiring per workspace convention (no placeholder construction) |
| Architecture Authority | ADR-014 Decision 2 (InMemoryVectorStore internal structure, Arc<dyn Embeddings> injection, RwLock, Vec<f32> cosine, no ndarray); ADR-014 Decision 5 (write-time zero-norm guard — `add_texts` and `from_texts_sync` reject zero-norm vectors with E-VS-004 before persistence) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-vectorstores / vectorstores::memory |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + proptest |
