---
document_type: behavioral-contract
level: L3
bc_id: BC-2.20.003
version: "1.10"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-20
capability: CAP-027
crate: pregolya-vectorstores
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-20 Document Retrieval"
  - "1.1 (D21/Batch-3b-i/2026-07-20): E-CFG-001 → E-VS-003 reassignment per ADR-010 v1.1 (no CFG component; VS component owns all VectorStoreRetriever config validation errors). Updated: Invariant 2 (error code + added full struct form with E-CORE-005 message pattern), TV-004 (full struct form for lambda_mult violation), TV-005 (full struct form for fetch_k < k violation). TD-VSDD-060 E-CFG residue: zero (grep confirmed below)."
  - "1.2 (F-P224/F-P129-07/2026-07-21): Invariant 2 corrected — 'clamped to [0.0, 1.0]' → 'validated against [0.0, 1.0]'. The clamping language contradicted TV-004 which shows rejection semantics (Err, not silently clamped value). Validation with rejection is the correct behavior."
  - "1.3 (FIX-BURST-277-WAVE-B/2026-07-28): VP-2.20.003-A verification property text corrected (architect scope — verification strategy, not behavioral contract). Old text incorrectly described the property as preventing E0038 (object safety). Actual property: VectorStoreRetriever (no lifetime parameter; store: Arc<dyn VectorStore>) satisfies Retriever + 'static; Arc<dyn Retriever> coercion succeeds without a lifetime-bound error. Wave C PO routing required for BC body + PC-2 corrections (see fix-burst 277 Wave C routing spec)."
  - "1.4 (FIX-BURST-277-WAVE-C/ADR-014-Decision-2-body/2026-07-28): BC body aligned with ADR-014 Decision 2 VectorStoreRetriever lifetime removal. (1) Description: lifetime-parameterized VectorStoreRetriever and borrowed `&'a dyn VectorStore` removed; as_retriever made fallible with Arc<Self>-receiver returning Result<VectorStoreRetriever, PregolyaError>; Err(E-VS-003) on invalid config. (2) PC2: infallible `&self`-receiver form -> fallible Arc<Self>-receiver form. (3) PC3: lifetime-annotated VectorStoreRetriever -> VectorStoreRetriever. (4) PC4: coercion succeeds because Retriever + 'static. (5) PC5: updated to fallible signature; E0038-safe framing removed (issue was lifetime, not object safety). (6) Invariant 5: lifetime-borrow language -> Arc ownership language; 'static coercion documented. (7) EC-006: Ok(VectorStoreRetriever) return; Arc clone semantics."
  - "1.5 (FIX-BURST-278-WAVE-B/D-48-receiver-sweep/2026-07-28): D-48 receiver sweep — all non-dyn-compatible receiver forms corrected to `Arc<Self>` in Description, Precondition PC-2, Postcondition PC-5, Edge Case EC-006, and VP-2.20.003-A inline spec. Related BCs stale description fixed: 'wraps a &dyn VectorStore' → 'owns Arc<dyn VectorStore>'. See wave-b-po-routing-spec.md Routing Items 6/6g."
  - "1.6 (FIX-BURST-278-WAVE-C/D-48-ratification/2026-07-28): PO ratification of D-48 receiver sweep (wave-b-po-routing-spec.md Routing Items 6a–6g). Substantive verification: (1) Inv-2 states 'validated against [0.0, 1.0]; rejected with Err(PregolyaError{code:E-VS-003})' — matches error-taxonomy.md §E-VS-003 and PC-5 fallible semantics; COHERENT. (2) TV-004/TV-005 show PregolyaError{code:E-VS-003} in table cells (S5-exempt prose); error semantics correct. (3) PC-5 reads 'as_retriever(self: Arc<Self>)' — dyn-compatible per D-48; CORRECT. (4) No non-dyn-compatible borrowed-Arc receiver residue: file confirmed zero occurrences. (5) No lifetime-parameterized VectorStoreRetriever residue: file confirmed zero occurrences. Ratification: COHERENT."
  - "1.7 (wave-b-b7-notation-sweep/2026-07-29): ADR-010 §Class 3 notation sweep — 3 CLASS3_MISSING_DOTDOT violations corrected. (1) Invariant 2 inline E-VS-003 reject cite: add `, ..` field-elision marker. (2) TV-004 expected-output cell: add `, ..` field-elision marker. (3) TV-005 expected-output cell: add `, ..` field-elision marker. Zero-space `PregolyaError{code:E-VS-003}` in frontmatter changelog entry 1.6 (historical record, no space before brace) is EXEMPT — not modified per append-only record protocol."
  - "1.8 (P2A-021/story-anchor/2026-08-21): Story Anchor set to S-2.03 — VectorStoreRetriever / as_retriever delivery moved from S-2.02 to S-2.03 per architect P2A-021 build-ordering ruling (VectorStoreRetriever depends on the VectorStore trait, which is delivered in S-2.03)."
  - "1.9 (M1/ADR-027/2026-08-23): ADR-027 stable clause anchors added (M1). Purely additive — no content change."
  - "1.10 (P2A-048/F-048-02/2026-08-24): PRE-001 borrowed `&dyn VectorStore` → owned `Arc<dyn VectorStore>` (D-48 sweep straggler; PRE-001 omitted from the v1.5 enumerated-clause sweep per wave-b-po-routing-spec.md Routing Items 6/6g)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-027
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "869996f"
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

`VectorStoreRetriever` is a concrete `Retriever` implementation in
`pregolya-vectorstores: vectorstores::retriever` that owns an `Arc<dyn VectorStore>` and
dispatches `get_relevant_documents` to the appropriate VectorStore search method based on
`SearchType`. It is constructed via `VectorStore::as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>`,
a concrete (non-opaque) fallible constructor that validates configuration before constructing
and returns `Err(E-VS-003)` on invalid config (ADR-014 Decision 2). The retriever is configured
with `k` (final result count), `fetch_k` (MMR candidate pool size), and `lambda_mult` (MMR
diversity weight). `VectorStoreRetriever` has no lifetime parameter; the `Arc<dyn VectorStore>`
internal field allows `VectorStoreRetriever` to satisfy `Retriever + 'static`, enabling
`Arc<dyn Retriever>` coercion.

## Preconditions

1. {PRE-001} An `Arc<dyn VectorStore>` value is available (the store has been initialized and is Arc-owned).
2. {PRE-002} `VectorStore::as_retriever(self: Arc<Self>)` is called on an `Arc<dyn VectorStore>`,
   returning `Ok(VectorStoreRetriever)` on valid config or `Err(E-VS-003)` on invalid config
   (ADR-014 Decision 2).
3. {PRE-003} The caller configures `search_type`, `k`, `fetch_k`, and `lambda_mult` (defaults apply
   if not explicitly set: `SearchType::Similarity`, `k=4`, `fetch_k=20`, `lambda_mult=0.5`).
4. {PRE-004} The `VectorStoreRetriever` (no lifetime parameter) is coerced to `Arc<dyn Retriever>` by
   wrapping in `Arc::new`; this coercion succeeds because `VectorStoreRetriever: Retriever + 'static`.

## Postconditions

1. {PC-001} `SearchType::Similarity` — `get_relevant_documents(query)` dispatches to
   `store.similarity_search(query, k)`. Returns the top-k documents by cosine similarity.
2. {PC-002} `SearchType::SimilarityScoreThreshold { score_threshold }` — dispatches to
   `store.similarity_search_with_score(query, k)`, then filters results where `score < threshold`.
   Returns only documents meeting the threshold; may return fewer than `k` documents or zero.
3. {PC-003} `SearchType::Mmr` — dispatches to `store.max_marginal_relevance_search(query, k, fetch_k, lambda_mult)`.
   Returns `k` documents from the `fetch_k` candidate pool, selected for both relevance and diversity.
4. {PC-004} In all three search types, the returned `Vec<Document>` satisfies DI-012 (each document that
   enters graph context must pass `BoundaryType::RAGRetrieval` — coverage obligation per BC-2.20.002).
5. {PC-005} `VectorStore::as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>`
   is a concrete (non-opaque) fallible return — NOT `async fn`, NOT `impl Retriever`. Returns the
   concrete named type `VectorStoreRetriever` (no lifetime parameter). `VectorStore` trait remains
   object-safe; `as_retriever` takes `self: Arc<Self>` — the dyn-compatible receiver that allows
   internal `Arc<dyn VectorStore>` storage (ADR-014 Decision 2). Returns `Err(E-VS-003)` on invalid
   config.

## Invariants

- {INV-001} `SearchType` is `#[non_exhaustive]` — match arms in callers must include `_` wildcard to guard
  against future variants.
- {INV-002} `lambda_mult` is **validated against** `[0.0, 1.0]` at construction time; values outside this range are
  rejected with `Err(PregolyaError { code: "E-VS-003", message: "Validation failed for 'lambda_mult': must be in [0.0, 1.0]", .. })` at `as_retriever()` call.
- {INV-003} `k ≥ 1` is enforced at construction time; `k = 0` is rejected.
- {INV-004} `fetch_k ≥ k` is enforced at construction time for `SearchType::Mmr` (the candidate pool must
  be at least as large as the final result count); `fetch_k < k` is rejected.
- {INV-005} `VectorStoreRetriever` owns its store via `Arc<dyn VectorStore>`; it is `'static` (no lifetime
  parameter). The `Arc` reference count keeps the store alive for the retriever's lifetime — no
  borrow-checker lifetime constraint applies (ADR-014 Decision 2). `Arc<dyn Retriever>` coercion
  succeeds without a lifetime-bound error.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `SearchType::SimilarityScoreThreshold { score_threshold: 1.0 }` — no docs pass | `Ok(vec![])` — empty result; not an error |
| EC-002 | `SearchType::SimilarityScoreThreshold { score_threshold: 0.0 }` — all docs pass | `Ok(all_docs_up_to_k)` — threshold of 0.0 passes everything |
| EC-003 | `SearchType::Mmr` with `fetch_k = k` | MMR runs with a candidate pool of exactly k; minimal diversity effect (degenerate to similarity search) — valid |
| EC-004 | `lambda_mult = 0.0` (maximum diversity) | MMR returns maximally diverse documents; may include low-relevance but high-diversity documents |
| EC-005 | `lambda_mult = 1.0` (pure relevance) | MMR degenerates to similarity search; diversity penalty is zero |
| EC-006 | `as_retriever(self: Arc<Self>)` called on an `Arc<dyn VectorStore>` with valid config | Returns `Ok(VectorStoreRetriever)` (no lifetime parameter); retriever owns a clone of the `Arc<dyn VectorStore>`; caller may drop the original `Arc` after construction |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `store.as_retriever()` with default config → `get_relevant_documents("test")` | Dispatches to `similarity_search("test", 4)`; returns `Ok(docs)` | happy-path (default Similarity) |
| TV-002 | `as_retriever()` with `SearchType::SimilarityScoreThreshold { score_threshold: 0.8 }` → query → only 1 of 5 docs scores ≥ 0.8 | `Ok(vec![<1 doc>])` — 4 docs filtered out | happy-path (score threshold) |
| TV-003 | `as_retriever()` with `SearchType::Mmr`, `k=3`, `fetch_k=10`, `lambda_mult=0.5` → query | Dispatches to `max_marginal_relevance_search("query", 3, 10, 0.5)`; returns `Ok(3 diverse docs)` | happy-path (MMR) |
| TV-004 | `as_retriever()` with `lambda_mult = 1.5` | `Err(PregolyaError { code: "E-VS-003", message: "Validation failed for 'lambda_mult': must be in [0.0, 1.0]", .. })` | error-case (invalid config) |
| TV-005 | `as_retriever()` with `SearchType::Mmr`, `fetch_k = 2`, `k = 5` | `Err(PregolyaError { code: "E-VS-003", message: "Validation failed for 'fetch_k': must be ≥ k (5) for MMR search", .. })` | error-case (invalid MMR config) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.20.003-A | `VectorStoreRetriever` (no lifetime parameter; `store: Arc<dyn VectorStore>`) satisfies `Retriever + 'static`; `Arc<dyn Retriever>` coercion succeeds without a lifetime-bound error; `as_retriever(self: Arc<Self>)` is fallible: validates config before constructing | compile-time test + unit test (invalid config → `Err(E-VS-003)`) |
| VP-2.20.003-B | Each SearchType variant dispatches to the correct VectorStore method | unit test with mock VectorStore — assert method call dispatch per SearchType |

## Related BCs

- BC-2.20.001 — depends on: VectorStoreRetriever implements the Retriever trait defined in BC-2.20.001
- BC-2.20.002 — composes with: callers of VectorStoreRetriever's get_relevant_documents must apply the DI-012 guardrail coverage obligation
- BC-2.21.001 — depends on: VectorStoreRetriever owns Arc<dyn VectorStore>; VectorStore trait defined in BC-2.21.001

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-20, `vectorstores::retriever` module in pregolya-vectorstores
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 (VectorStoreRetriever struct, SearchType enum, as_retriever concrete-return-type requirement, k/fetch_k/lambda_mult fields)

## Story Anchor

S-2.03

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
| Module | pregolya-vectorstores / vectorstores::retriever |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + compile-time (E0038 dyn-compat gate) |
