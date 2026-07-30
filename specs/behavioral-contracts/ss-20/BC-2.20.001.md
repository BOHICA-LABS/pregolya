---
document_type: behavioral-contract
level: L3
bc_id: BC-2.20.001
version: "1.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-20
capability: CAP-026
crate: pregolya-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008, DI-012, DI-014]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-20 Document Retrieval"
  - "1.1 (F-P130-04/2026-07-21): Add DI-014 to di_anchors — EC-002 already cited DI-014 in body ('error propagated, not swallowed; no Vec::new() fallback on partial failure'); frontmatter anchor was missing."
  - "1.2 (wave-b-b7-notation-sweep/2026-07-29): ADR-010 §Class 3 notation sweep — 3 CLASS3_ASCII_ELLIPSIS_VIOLATION violations corrected. PC-2 failure arm, EC-002 expected-output, and TV-003 expected-output: `PregolyaError { ... }` → `PregolyaError { .. }` (replace `...` with `..` field-elision marker). No security semantics or VP anchors altered."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-026
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-012
  - domain-spec/invariants.md#DI-014
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

# BC-2.20.001: Retriever Trait — get_relevant_documents Async Dyn-Compatible; Document Carrier Type; Arc<dyn Retriever> Graph Seam

## Description

`Retriever` is a dyn-compatible async trait in `pregolya-core: core::retriever` with a single
abstract method: `async fn get_relevant_documents(&self, query: &str) → Result<Vec<Document>, PregolyaError>`.
Graph nodes that perform RAG operations hold `Arc<dyn Retriever>` without depending on
`pregolya-vectorstores`. The `Document` type (`pregolya-core: core::documents`) is the
carrier for all retrieval output: `{ page_content: String, metadata: Map<String, Value>, id: Option<String> }`.
Object-safety is achieved via `&self` receiver and `#[async_trait]` desugaring
(`Pin<Box<dyn Future<Output = ...> + Send>>`), following the ADR-005 precedent established for
`Arc<dyn CheckpointSaver>`.

## Preconditions

1. `pregolya-core` Cargo.toml includes `async-trait` as a dependency.
2. A concrete type `T` implements `Retriever` with `#[async_trait]` and `&self` receiver.
3. The concrete `T` is wrapped in `Arc<T>` and stored as `Arc<dyn Retriever>` at the call site.
4. The query string is a valid UTF-8 `&str` (including empty string — callers may pass `""` and
   receive a valid empty `Vec<Document>` or a meaningful result depending on the implementation).

## Postconditions

1. `Arc<dyn Retriever>` compiles without E0038 ("the trait cannot be made into an object") when
   `T` is an `#[async_trait]`-annotated impl with `&self` receivers only (no type parameters,
   no `impl Trait` in function position).
2. `get_relevant_documents(&self, query: &str) → Result<Vec<Document>, PregolyaError>`:
   - On success: returns `Ok(docs)` where `docs` is a `Vec<Document>` (possibly empty) ranked
     by relevance to the query. The ordering is implementation-defined; the invariant is that
     the vector is deterministic for a given `(self-state, query)` pair.
   - On failure: returns `Err(PregolyaError { .. })` propagated via `?` (DI-008 — no
     `unwrap()` in non-test code).
3. `Document { page_content, metadata, id }` carries:
   - `page_content`: the retrieved text content — MUST be non-empty for content-bearing documents;
     empty `page_content` is permitted only for metadata-only stubs.
   - `metadata`: a `serde_json::Map<String, Value>` — MAY be empty `{}`.
   - `id`: `Option<String>` — `None` when the backend does not assign stable IDs.
4. `Document` is `#[non_exhaustive]` — match arms on Document fields require a wildcard `..`
   to guard against future field additions.

## Invariants

1. The `Retriever` trait has exactly ONE required async method (`get_relevant_documents`). No
   default method implementations may add I/O side effects to the base trait.
2. `Arc<dyn Retriever + Send + Sync>` compiles and is Send + Sync. All Retriever impls must be
   `Send + Sync` (enforced by the trait bound `Retriever: Send + Sync`).
3. `Document` is a pure data carrier — no methods, no I/O, no async. It is `Clone + Debug +
   Serialize + Deserialize + JsonSchema`.
4. The `Retriever` trait resides in `pregolya-core: core::retriever`, NOT in
   `pregolya-vectorstores`. Graph crates depend only on `pregolya-core` for `Arc<dyn Retriever>`.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Query is empty string `""` | `Ok(vec![])` or implementation-specific ranked result; never a panic |
| EC-002 | Underlying backend is unavailable (network error, file not found) | `Err(PregolyaError { .. })` — error propagated, not swallowed; no `Vec::new()` fallback on partial failure (DI-014) |
| EC-003 | `get_relevant_documents` returns a large result set (e.g., 10,000 docs) | `Ok(docs)` with all 10,000 docs — no silent truncation at the trait level; truncation is the caller's responsibility |
| EC-004 | Two `Arc<dyn Retriever>` clones call `get_relevant_documents` concurrently | Both calls proceed without data race; `Retriever: Send + Sync` enforces this |
| EC-005 | Document with `id: None` received from a backend that doesn't assign IDs | Caller handles `None` gracefully; no `unwrap()` on `doc.id` without a prior `is_some()` guard |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `Arc<TestRetriever> as Arc<dyn Retriever>` → `get_relevant_documents("hello")` | Compiles; returns `Ok(vec![Document { page_content: "test doc", metadata: {}, id: None }])` | happy-path (dyn-compat compile check) |
| TV-002 | `get_relevant_documents("")` on a retriever with 0 indexed docs | `Ok(vec![])` | edge-case (empty query, empty index) |
| TV-003 | `get_relevant_documents("query")` on a retriever whose backend returns an I/O error | `Err(PregolyaError { .. })` — error propagated | error-case (backend failure) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.20.001-A | `Arc<dyn Retriever>` compiles without E0038 for any impl with `&self` + `#[async_trait]` | compile-time test — dummy impl in `tests/` that stores as `Arc<dyn Retriever>`; CI fails if E0038 regresses |
| VP-2.20.001-B | `Document` is `#[non_exhaustive]` — external match arms without `..` cause compile error | compile-fail test in `tests/external/document-non-exhaustive/` |

## Related BCs

- BC-2.20.002 — composes with: DI-012 guardrail coverage obligation for all documents entering graph context via this Retriever seam
- BC-2.20.003 — depends on: VectorStoreRetriever is a concrete Retriever impl that satisfies this trait's contract
- BC-2.11.001 — depends on: the BoundaryType::RAGRetrieval variant defined there is the guardrail applied to documents returned by this trait

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-20, `core::retriever` and `core::documents` modules in pregolya-core
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 1 (crate placement: Retriever + Document in pregolya-core), Decision 2 (async dyn-compatible trait shape, `&self` receiver, `#[async_trait]`, Document struct)
- `architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` — §Object-Safety precedent for `#[async_trait]` + `Arc<dyn Trait>`

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-20 story]_

## VP Anchors

- VP-2.20.001-A, VP-2.20.001-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-026 |
| Capability Anchor Justification | CAP-026 ("Retriever Trait — get_relevant_documents; Arc<dyn Retriever> Seam; DI-012 RAGRetrieval Guardrail Coverage") per capabilities-p1-p2.md §CAP-026 — this BC specifies the exact Retriever trait surface, Document carrier type, and Arc<dyn Retriever> dyn-compatibility contract that CAP-026 defines as the foundational document-retrieval seam for graph nodes |
| L2 Domain Invariants | DI-008 (get_relevant_documents returns Result; no .unwrap() on retrieval results), DI-012 (documents entering graph context via Retriever must pass BoundaryType::RAGRetrieval guardrail — coverage assertion in BC-2.20.002), DI-014 (errors propagated via `?`; no silent `Vec::new()` fallback on partial or backend failure — per EC-002) |
| Architecture Authority | ADR-014 Decision 1 (Retriever + Document in pregolya-core) and Decision 2 (trait shape, async dyn-compat, Document struct) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-core / core::retriever, core::documents |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + compile-fail (dyn-compat gate, non_exhaustive gate) |
