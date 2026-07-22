---
document_type: behavioral-contract
level: L3
bc_id: BC-2.22.001
version: "1.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-22
capability: CAP-031
crate: ferrochain-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
di_anchors: [DI-008, DI-014]
vp_seed: true
vp_id: VP-008
changelog:
  - "1.2 (burst-238/sweep/2026-07-22): VP Registration (Traceability) and VP Anchors section updated: stale 'ARCH-INDEX candidate — architect assigns VP-INDEX entry after BC authoring completes' and 'pending VP-008 registration in VP-INDEX.md' replaced with 'assigned in VP-INDEX v1.2 as VP-008' (VP-INDEX v1.2 burst-223 seeded VP-008 proptest P1; VP-008.md exists). Completed-handoff residue removal."
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-22 Embeddings"
  - "1.1 (F-P130-07/2026-07-21): Fix E-EMBED-001 message prefix: `DimensionMismatch:` → `EmbeddingDimensionMismatch:` to match canonical PRD name and eliminate collision with E-VS-002 prefix. Gate #33 reverse: error-taxonomy.md v1.28→v1.29 updated in same burst."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-031
  - architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "13c4e9f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.22.001: Embeddings Trait — embed_documents Batch; embed_query; Dimensionality Contract → E-EMBED-001; Batch Partial-Failure as Err; Arc<dyn Embeddings> Dyn-Safe (VP-008 Proptest Seed)

## Description

`Embeddings` is a dyn-compatible async trait in `ferrochain-core: core::embeddings` with two
abstract methods: `async fn embed_documents(&self, texts: Vec<String>) → Result<Vec<Vec<f32>>,
FerrochainError>` (batch) and `async fn embed_query(&self, text: String) → Result<Vec<f32>,
FerrochainError>` (single query). All returned embedding vectors must satisfy the dimensionality
contract: one vector per input, all vectors have the same length, and `embed_query` output
matches `embed_documents` inner vector length. Violations return `Err(E-EMBED-001)`. Batch
partial failures (e.g., rate limit mid-batch) return `Err` for the whole call — no silent
partial-batch fallback to a truncated or empty result (DI-014). `Arc<dyn Embeddings>` compiles
without E0038. VP-008: proptest dimensionality invariant for any valid `Embeddings` impl.

## Preconditions

1. `ferrochain-core` has `async-trait` as a dependency.
2. A concrete type `T` implements `Embeddings` with `#[async_trait]` and `&self` receivers.
3. `T` is wrapped as `Arc<dyn Embeddings>` and held by consumers (e.g., `InMemoryVectorStore`).

## Postconditions

1. `Arc<dyn Embeddings>` compiles without E0038 for any impl with `&self` + `#[async_trait]`.
2. `embed_documents(&self, texts) → Result<Vec<Vec<f32>>, FerrochainError>`:
   - `Ok(vecs)` where `vecs.len() == texts.len()` — one embedding vector per input text.
   - All inner `Vec<f32>` have identical length `d` (the model's embedding dimension).
   - If `texts` is empty: `Ok(vec![])` — zero vectors; no error.
   - If the provider returns an inconsistent batch (inner vectors of different lengths):
     `Err(FerrochainError { component: Component::EMBED, category: Category::VALIDATION,
     code: "E-EMBED-001", message: "EmbeddingDimensionMismatch: embedding batch returned inconsistent
     vector lengths" })`.
   - If the provider returns a partial batch error (e.g., rate limit, service error):
     `Err(FerrochainError { ... })` for the whole call — NO silent truncation to a partial
     result set, NO `Vec::new()` fallback (DI-014).
3. `embed_query(&self, text) → Result<Vec<f32>, FerrochainError>`:
   - `Ok(vec)` where `vec.len() == d` — same dimension as `embed_documents` inner vectors.
   - If the returned vector length differs from the model's declared dimension:
     `Err(E-EMBED-001)`.
4. The dimension `d` is model-specific and implementation-defined; it is NOT part of the
   trait signature. Consumers who need dimensionality checking (e.g., VectorStore mismatch)
   check externally — the trait guarantees internal consistency, not a fixed dimension.

## Invariants

1. **One vector per input** — `embed_documents(texts).ok().map(|v| v.len()) == Some(texts.len())`.
   This invariant holds for ALL valid `Embeddings` impls; a violation returns `Err(E-EMBED-001)`.
2. **Consistent inner length** — for any `Ok(vecs)` from `embed_documents`, all `vecs[i].len()`
   are equal. Mixed-length outputs are an `Err(E-EMBED-001)` condition.
3. **embed_query length == embed_documents inner length** — for the same model and config,
   `embed_query(t).ok().map(|v| v.len()) == embed_documents(vec![t]).ok().map(|vs| vs[0].len())`.
4. **No `ndarray`** — return type is `Vec<f32>` (standard library). No heavy linear algebra
   dep is pulled into ferrochain-core.
5. `Embeddings: Send + Sync` — all impls must be thread-safe for use in multi-threaded Tokio tasks.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `embed_documents(vec![])` — empty input | `Ok(vec![])` — zero vectors; not an error |
| EC-002 | `embed_documents(vec!["a".to_string(); 10_000])` — very large batch | `Ok(vecs)` or `Err(...)` depending on provider limits; no panic; no truncation to fewer vectors without `Err` |
| EC-003 | Provider returns 9 vectors for 10 inputs (partial batch) | `Err(E-EMBED-001)` — batch count mismatch detected by the impl before returning |
| EC-004 | Provider returns a vector of length 0 | `Err(E-EMBED-001)` — zero-length embedding is a dimensionality violation |
| EC-005 | `embed_query` called concurrently from multiple tasks via `Arc<dyn Embeddings>` | Safe — `Embeddings: Send + Sync` ensures no data race |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `embed_documents(vec!["hello", "world"])` on a mock impl returning 2 × 768-dim vectors | `Ok(vec![[f32; 768], [f32; 768]])` — one vector per text | happy-path |
| TV-002 | `embed_query("hello")` on same mock | `Ok([f32; 768])` — same dimension as embed_documents output | happy-path (dimension consistency) |
| TV-003 | Mock impl returns `vec![[0.1; 768], [0.2; 512]]` (ragged batch) — detected by impl | `Err(E-EMBED-001)` — inconsistent inner lengths | error-case (ragged batch) |
| TV-004 | `embed_documents(vec![])` | `Ok(vec![])` — zero results | edge-case (empty input) |
| TV-005 | `Arc<dyn Embeddings>` compile-time check | Compiles without E0038 | compile-time gate |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.22.001-A (VP-008 candidate) | For any valid `Embeddings` impl, all inner vectors from `embed_documents` have the same length, and `embed_query` output length equals `embed_documents` inner length | proptest — random text batches; assert length invariants hold for all `Ok(...)` responses |
| VP-2.22.001-B | `Arc<dyn Embeddings>` compiles without E0038 | compile-time test in `tests/external/embeddings-dyn-compat/` |
| VP-2.22.001-C | `embed_documents` on an empty input returns `Ok(vec![])` — not `Err` | unit test — assert empty input produces empty output |

## Related BCs

- BC-2.22.002 — depends on: EmbeddingsOpenAI is a concrete impl of this trait
- BC-2.22.003 — depends on: EmbeddingsOllama is a concrete impl of this trait
- BC-2.21.002 — depends on: InMemoryVectorStore injects `Arc<dyn Embeddings>` from this trait at construction time

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-22, `core::embeddings` module in ferrochain-core
- `architecture/decisions/ADR-017-embeddings-trait-provider-integration.md` — Decision 1 (trait placement in ferrochain-core), Decision 2 (async dyn-compatible shape, dimensionality contract, batch error semantics)
- `architecture/decisions/ADR-005-*.md` — §Object-Safety precedent for `#[async_trait]` + `Arc<dyn Trait>`

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-22 story]_

## VP Anchors

- VP-2.22.001-A (VP-008 assigned VP-INDEX v1.2; VP-008.md exists)
- VP-2.22.001-B
- VP-2.22.001-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-031 |
| Capability Anchor Justification | CAP-031 ("Embeddings Trait — embed_documents (Batch); embed_query; Dimensionality Contract; Arc<dyn Embeddings> Seam") per capabilities-p1-p2.md §CAP-031 — this BC specifies the exact Embeddings trait surface, the three-part dimensionality contract, batch partial-failure Err semantics (DI-014), and Arc<dyn Embeddings> dyn-safety that CAP-031 defines as the foundational embedding seam for InMemoryVectorStore and semantic search |
| L2 Domain Invariants | DI-008 (embed_documents and embed_query return Result; no .unwrap()), DI-014 (batch partial-failure propagates as Err; no silent truncation or Vec::new() fallback) |
| Architecture Authority | ADR-017 Decisions 1 and 2 (trait placement, async dyn-compat shape, dimensionality contract, batch error semantics) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| VP Registration | VP-008 (assigned in VP-INDEX v1.2 as VP-008 — proptest P1; ferrochain-core embeddings) |
| Module | ferrochain-core / core::embeddings |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + compile-time (dyn-compat gate) + proptest (VP-008) |
