---
document_type: behavioral-contract
level: L3
bc_id: BC-2.20.003
version: "1.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-20
capability: CAP-027
crate: ferrochain-vectorstores
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-20 Document Retrieval"
  - "1.1 (D21/Batch-3b-i/2026-07-20): E-CFG-001 → E-VS-003 reassignment per ADR-010 v1.1 (no CFG component; VS component owns all VectorStoreRetriever config validation errors). Updated: Invariant 2 (error code + added full struct form with E-CORE-005 message pattern), TV-004 (full struct form for lambda_mult violation), TV-005 (full struct form for fetch_k < k violation). TD-VSDD-060 E-CFG residue: zero (grep confirmed below)."
  - "1.2 (F-P224/F-P129-07/2026-07-21): Invariant 2 corrected — 'clamped to [0.0, 1.0]' → 'validated against [0.0, 1.0]'. The clamping language contradicted TV-004 which shows rejection semantics (Err, not silently clamped value). Validation with rejection is the correct behavior."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-027
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "725e31f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.20.003: VectorStoreRetriever — SearchType Enum (Similarity | SimilarityScoreThreshold | Mmr); k / fetch_k / lambda_mult Configuration; Constructed via as_retriever()

## Description

`VectorStoreRetriever<'a>` is a concrete `Retriever` implementation in
`ferrochain-vectorstores: vectorstores::retriever` that wraps a `&'a dyn VectorStore` and
dispatches `get_relevant_documents` to the appropriate VectorStore search method based on
`SearchType`. It is constructed via `VectorStore::as_retriever(&self) → VectorStoreRetriever<'_>`,
a concrete (non-opaque) return type that preserves `VectorStore`'s dyn-compatibility (E0038-safe
per ADR-014). The retriever is configured with `k` (final result count), `fetch_k` (MMR
candidate pool size), and `lambda_mult` (MMR diversity weight).

## Preconditions

1. A `&dyn VectorStore` value is available (the store has been initialized).
2. `VectorStore::as_retriever(&self)` is called on the store, returning a `VectorStoreRetriever<'_>`.
3. The caller configures `search_type`, `k`, `fetch_k`, and `lambda_mult` (defaults apply
   if not explicitly set: `SearchType::Similarity`, `k=4`, `fetch_k=20`, `lambda_mult=0.5`).
4. The `VectorStoreRetriever<'_>` is coerced to `Arc<dyn Retriever>` by wrapping in `Arc::new`.

## Postconditions

1. `SearchType::Similarity` — `get_relevant_documents(query)` dispatches to
   `store.similarity_search(query, k)`. Returns the top-k documents by cosine similarity.
2. `SearchType::SimilarityScoreThreshold { score_threshold }` — dispatches to
   `store.similarity_search_with_score(query, k)`, then filters results where `score < threshold`.
   Returns only documents meeting the threshold; may return fewer than `k` documents or zero.
3. `SearchType::Mmr` — dispatches to `store.max_marginal_relevance_search(query, k, fetch_k, lambda_mult)`.
   Returns `k` documents from the `fetch_k` candidate pool, selected for both relevance and diversity.
4. In all three search types, the returned `Vec<Document>` satisfies DI-012 (each document that
   enters graph context must pass `BoundaryType::RAGRetrieval` — coverage obligation per BC-2.20.002).
5. `VectorStore::as_retriever(&self) → VectorStoreRetriever<'_>` is a concrete (non-opaque) return.
   This is NOT `async fn`, NOT `impl Retriever` — it returns the concrete named type, preserving
   `VectorStore`'s dyn-compatibility (E0038-safe).

## Invariants

1. `SearchType` is `#[non_exhaustive]` — match arms in callers must include `_` wildcard to guard
   against future variants.
2. `lambda_mult` is **validated against** `[0.0, 1.0]` at construction time; values outside this range are
   rejected with `Err(FerrochainError { code: "E-VS-003", message: "Validation failed for 'lambda_mult': must be in [0.0, 1.0]" })` at `as_retriever()` call.
3. `k ≥ 1` is enforced at construction time; `k = 0` is rejected.
4. `fetch_k ≥ k` is enforced at construction time for `SearchType::Mmr` (the candidate pool must
   be at least as large as the final result count); `fetch_k < k` is rejected.
5. `VectorStoreRetriever<'_>` borrows the store with lifetime `'a`; it CANNOT outlive the store it
   wraps (lifetime-safe — the borrow checker enforces this statically).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `SearchType::SimilarityScoreThreshold { score_threshold: 1.0 }` — no docs pass | `Ok(vec![])` — empty result; not an error |
| EC-002 | `SearchType::SimilarityScoreThreshold { score_threshold: 0.0 }` — all docs pass | `Ok(all_docs_up_to_k)` — threshold of 0.0 passes everything |
| EC-003 | `SearchType::Mmr` with `fetch_k = k` | MMR runs with a candidate pool of exactly k; minimal diversity effect (degenerate to similarity search) — valid |
| EC-004 | `lambda_mult = 0.0` (maximum diversity) | MMR returns maximally diverse documents; may include low-relevance but high-diversity documents |
| EC-005 | `lambda_mult = 1.0` (pure relevance) | MMR degenerates to similarity search; diversity penalty is zero |
| EC-006 | `as_retriever()` called on a store via `Arc<dyn VectorStore>` | Returns `VectorStoreRetriever<'_>` with lifetime tied to the deref of the Arc; caller holds the Arc for the retriever's lifetime |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `store.as_retriever()` with default config → `get_relevant_documents("test")` | Dispatches to `similarity_search("test", 4)`; returns `Ok(docs)` | happy-path (default Similarity) |
| TV-002 | `as_retriever()` with `SearchType::SimilarityScoreThreshold { score_threshold: 0.8 }` → query → only 1 of 5 docs scores ≥ 0.8 | `Ok(vec![<1 doc>])` — 4 docs filtered out | happy-path (score threshold) |
| TV-003 | `as_retriever()` with `SearchType::Mmr`, `k=3`, `fetch_k=10`, `lambda_mult=0.5` → query | Dispatches to `max_marginal_relevance_search("query", 3, 10, 0.5)`; returns `Ok(3 diverse docs)` | happy-path (MMR) |
| TV-004 | `as_retriever()` with `lambda_mult = 1.5` | `Err(FerrochainError { code: "E-VS-003", message: "Validation failed for 'lambda_mult': must be in [0.0, 1.0]" })` | error-case (invalid config) |
| TV-005 | `as_retriever()` with `SearchType::Mmr`, `fetch_k = 2`, `k = 5` | `Err(FerrochainError { code: "E-VS-003", message: "Validation failed for 'fetch_k': must be ≥ k (5) for MMR search" })` | error-case (invalid MMR config) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.20.003-A | `as_retriever()` returns a concrete `VectorStoreRetriever<'_>` that can be stored as `Arc<dyn Retriever>` (E0038 does not fire) | compile-time test |
| VP-2.20.003-B | Each SearchType variant dispatches to the correct VectorStore method | unit test with mock VectorStore — assert method call dispatch per SearchType |

## Related BCs

- BC-2.20.001 — depends on: VectorStoreRetriever implements the Retriever trait defined in BC-2.20.001
- BC-2.20.002 — composes with: callers of VectorStoreRetriever's get_relevant_documents must apply the DI-012 guardrail coverage obligation
- BC-2.21.001 — depends on: VectorStoreRetriever wraps a &dyn VectorStore whose trait is defined in BC-2.21.001

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-20, `vectorstores::retriever` module in ferrochain-vectorstores
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 (VectorStoreRetriever struct, SearchType enum, as_retriever concrete-return-type requirement, k/fetch_k/lambda_mult fields)

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-20 story]_

## VP Anchors

- VP-2.20.003-A, VP-2.20.003-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-027 |
| Capability Anchor Justification | CAP-027 ("VectorStoreRetriever — SearchType Enum; k / fetch_k / lambda_mult Configuration") per capabilities-p1-p2.md §CAP-027 — this BC specifies the VectorStoreRetriever concrete Retriever implementation with SearchType dispatch, k/fetch_k/lambda_mult parameters, and the as_retriever() concrete-return-type construction pattern that CAP-027 names as its core BC surface |
| L2 Domain Invariants | DI-008 (VectorStoreRetriever::get_relevant_documents returns Result; no unwrap on search results) |
| Architecture Authority | ADR-014 Decision 2 (VectorStoreRetriever struct, SearchType enum, as_retriever concrete-return-type, config validation) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-vectorstores / vectorstores::retriever |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + compile-time (E0038 dyn-compat gate) |
