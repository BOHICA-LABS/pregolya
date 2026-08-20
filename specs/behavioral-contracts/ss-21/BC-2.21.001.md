---
document_type: behavioral-contract
level: L3
bc_id: BC-2.21.001
version: "1.3"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-21
capability: CAP-028
crate: pregolya-vectorstores
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-21 VectorStore Abstraction"
  - "1.1 (FIX-BURST-277-WAVE-C/ADR-014-Decision-2-infallibility/2026-07-28): as_retriever infallibility contradiction resolved. PC-2 contradicted BC-2.20.003 Inv-2, TV-004/TV-005, and DI-008 by declaring as_retriever infallible. ADR-014 Decision 2 is authority: fallible signature with no lifetime parameter. Changes: (1) Description: prior `&self`-receiver infallible form -> `as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>`; VectorStoreRetriever owns Arc<dyn VectorStore>. (2) PC2 method entry: updated to fallible Arc<Self>-receiver signature. (3) Invariant 4: lifetime-bound type and borrowed `&'_ dyn VectorStore` -> Ok(VectorStoreRetriever) owns Arc<dyn VectorStore>; Result return noted. (4) EC-005: borrowed store receiver -> Arc<dyn VectorStore>; non-static VectorStoreRetriever -> Ok(VectorStoreRetriever). (5) Related BCs: VectorStoreRetriever wraps &dyn VectorStore -> owns Arc<dyn VectorStore>."
  - "1.2 (FIX-BURST-278-WAVE-B/D-48-receiver-sweep/2026-07-28): D-48 receiver sweep — all non-dyn-compatible receiver forms corrected to `Arc<Self>` in Description, Postcondition PC-2 method entry, and Edge Case EC-005. See wave-b-po-routing-spec.md Routing Item 7."
  - "1.3 (FIX-BURST-278-WAVE-C/D-48-ratification/2026-07-28): PO ratification of D-48 receiver sweep (wave-b-po-routing-spec.md Routing Items 7a–7c). Substantive verification: (1) PC-2 method list reads 'as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>' — correct fallible Arc<Self>-receiver form per D-48; CORRECT. (2) Inv-4 states 'constructs Ok(VectorStoreRetriever) that owns an Arc<dyn VectorStore> clone, or returns Err(E-VS-003) on invalid config' — consistent with BC-2.20.003 Inv-2 and error-taxonomy.md §E-VS-003; COHERENT. (3) EC-005 reads 'as_retriever(self: Arc<Self>) called via Arc<dyn VectorStore> with valid config' — correct; CORRECT. (4) No non-dyn-compatible borrowed-Arc receiver residue: file confirmed zero occurrences. Ratification: COHERENT."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-028
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "97d9bcd"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.21.001: VectorStore Trait — Instance-Method Surface; VectorStoreFactory Sized-Bounded Separation; Arc<dyn VectorStore> Dyn-Safety

## Description

`VectorStore` is a dyn-compatible async trait in `pregolya-vectorstores: vectorstores::store`
providing the document-index contract. All instance methods use `&self` receivers (not `&mut self`)
and are desugared by `#[async_trait]` to `Pin<Box<dyn Future>>` for dyn-compatibility. Static
constructors (`from_texts_sync`) are placed on a separate `VectorStoreFactory` trait with a
`Sized` bound — E0038-safe split required by Rust's dyn-compatibility rules. `Arc<dyn VectorStore>`
compiles without E0038. The `as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>`
method returns a concrete (non-opaque) fallible result, validating configuration before constructing;
`VectorStoreRetriever` has no lifetime parameter and owns `Arc<dyn VectorStore>` internally
(ADR-014 Decision 2).

## Preconditions

1. `pregolya-vectorstores` has `async-trait` as a dependency.
2. A concrete type `T` implements `VectorStore` with all required instance methods using
   `&self` receivers and `#[async_trait]`.
3. Static construction goes through `VectorStoreFactory::from_texts_sync`, NOT through a
   method on the `VectorStore` vtable.

## Postconditions

1. `Arc<dyn VectorStore>` compiles without E0038 — confirmed by a compile-time test in
   `tests/external/vectorstore-dyn-compat/`.
2. `VectorStore` trait instance methods:
   - `add_texts(&self, texts, metadatas) → Result<Vec<String>, PregolyaError>` — ingests
     texts, returns assigned document IDs.
   - `similarity_search(&self, query, k) → Result<Vec<Document>, PregolyaError>` — returns
     the top-k documents.
   - `similarity_search_with_score(&self, query, k) → Result<Vec<(Document, f32)>, PregolyaError>`
     — returns top-k with scores ∈ [0.0, 1.0].
   - `max_marginal_relevance_search(&self, query, k, fetch_k, lambda_mult) → Result<Vec<Document>, PregolyaError>`
     — MMR retrieval.
   - `delete(&self, ids: &[&str]) → Result<(), PregolyaError>` — removes documents by ID.
   - `as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>` — concrete (non-opaque) fallible return (BC-2.20.003); validates config before constructing; `VectorStoreRetriever` owns `Arc<dyn VectorStore>`, no lifetime parameter.
3. `VectorStoreFactory` trait (separate, `Sized`-bounded):
   - `from_texts_sync(texts, embedding: Arc<dyn Embeddings>, config: Self::Config) → impl Future<Output = Result<Self, PregolyaError>> + Send`
   - Can only be called on a concrete type (not through `dyn VectorStore`).
4. `add_texts` uses `&self` (interior mutability via `RwLock` in concrete impls). External
   vectorstore backends are stateless from the client's perspective.

## Invariants

1. NO instance method on `VectorStore` has a generic type parameter — no `where T: Serialize`
   or similar bounds that would break E0038. Type-parameterized functionality goes on
   `VectorStoreFactory`.
2. `similarity_search_with_score` scores are in `[0.0, 1.0]` — implementors are responsible
   for normalizing backend scores to this range; raw cosine similarity in `[-1.0, 1.0]` must
   be mapped (e.g., `(score + 1.0) / 2.0` or by backend convention).
3. `VectorStore: Send + Sync` — all impls must be `Send + Sync` for use in multi-threaded
   Tokio tasks.
4. `as_retriever` is a synchronous, non-async method (no `.await`) — it validates config and
   constructs `Ok(VectorStoreRetriever)` that owns an `Arc<dyn VectorStore>` clone, or returns
   `Err(E-VS-003)` on invalid config. No I/O.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `add_texts` with empty `texts` vec | `Ok(vec![])` — zero IDs assigned; no error; idempotent |
| EC-002 | `similarity_search` with `k` larger than the number of indexed documents | `Ok(all_docs)` — returns all available documents (fewer than k); not an error |
| EC-003 | `delete` with an ID that does not exist | Implementation-defined: either `Ok(())` (idempotent delete) or `Err(...)` (strict delete). The BC does NOT mandate one behavior — implementors must document which semantics they apply. |
| EC-004 | `Arc<dyn VectorStore>` called across threads concurrently | `VectorStore: Send + Sync` ensures safety; interior mutability via `RwLock` serializes writes in the in-memory impl |
| EC-005 | `as_retriever(self: Arc<Self>)` called via `Arc<dyn VectorStore>` with valid config | Compiles; returns `Ok(VectorStoreRetriever)` that owns a clone of the `Arc<dyn VectorStore>`; no lifetime constraint |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `Arc<dyn VectorStore>` compile-time check (any impl) | Compiles without E0038 | compile-time gate |
| TV-002 | `store.add_texts(vec!["doc 1", "doc 2"], None) → Result` | `Ok(vec!["id-0", "id-1"])` or similar ID assignments | happy-path |
| TV-003 | `store.similarity_search("hello", 3)` on store with 5 docs | `Ok(vec![<3 ranked docs>])` | happy-path |
| TV-004 | `store.delete(&["id-0"])` | `Ok(())` | happy-path |
| TV-005 | `VectorStoreFactory::from_texts_sync(texts, arc_embeddings, Config::default())` on concrete type | `Ok(store_instance)` — factory constructor works on concrete type | happy-path (factory) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.21.001-A | `Arc<dyn VectorStore>` compiles without E0038 | compile-time test in `tests/external/vectorstore-dyn-compat/` |
| VP-2.21.001-B | `VectorStoreFactory::from_texts_sync` on a concrete type compiles; cannot be called through `dyn VectorStore` (Sized-bound enforcement) | compile-fail test — attempt dyn VectorStore factory call; assert compile error |

## Related BCs

- BC-2.20.003 — composes with: VectorStoreRetriever owns Arc<dyn VectorStore>; as_retriever() is the fallible constructor
- BC-2.21.002 — depends on: InMemoryVectorStore is the reference VectorStore impl of this trait
- BC-2.21.004 — composes with: MetadataFilter is an optional extension on this trait via similarity_search_with_filter

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-21, `vectorstores::store` and `vectorstores::factory` modules
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 (VectorStore trait shape, VectorStoreFactory split, E0038 rationale, as_retriever concrete return, &self vs &mut self rationale)

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-21 story]_

## VP Anchors

- VP-2.21.001-A, VP-2.21.001-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-028 |
| Capability Anchor Justification | CAP-028 ("VectorStore Trait — add_texts; Similarity Search; MMR; delete; as_retriever (Concrete Return for Dyn-Compat)") per capabilities-p1-p2.md §CAP-028 — this BC specifies the full VectorStore trait instance-method surface, the VectorStoreFactory Sized-bounded separation for E0038 safety, and the as_retriever concrete-return-type requirement that CAP-028 identifies as the foundational document-index contract |
| L2 Domain Invariants | DI-008 (all VectorStore methods return Result; no .unwrap() on search or mutation results) |
| Architecture Authority | ADR-014 Decision 2 (VectorStore trait, VectorStoreFactory separation, as_retriever concrete return, &self rationale) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-vectorstores / vectorstores::store |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + compile-time (E0038 gate, factory Sized-bound gate) + compile-fail |
