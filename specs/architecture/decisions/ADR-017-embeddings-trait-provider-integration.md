---
document_type: adr
level: L3
adr_id: "017"
slug: embeddings-trait-provider-integration
title: "Embeddings Trait and Provider Integration: Async Dyn-Compatible Trait, Dimensionality Contract, and First-Party Provider Scope"
status: accepted
date: "2026-07-23"
producer: architect
timestamp: 2026-07-23T00:00:00Z
version: "1.6"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D21]
supersedes: null
superseded_by: null
subsystems_affected: [SS-22, SS-08]
changelog:
  - "1.6 (D-35-rename-sweep/2026-07-28): D-35 canonical xtask naming sweep — §Consequences DI-009 enforcement note: `deny-client-new` → `check-client-timeout`. Canonical `check-<subject>` form per D-35."
  - "1.5 (FIX-BURST-270/P1D-168-casing/2026-07-25): PascalCase canon sweep — §Dimensionality contract FerrochainError sketch: Category::VAL → Category::Val per ADR-010 v1.9 Direction B adjudication."
  - "1.4 (burst-240/2026-07-23): F-P140-06 — fix §Dimensionality contract FerrochainError sketch: non-canonical `category: VALIDATION` → `category: Category::VAL` per ADR-016 v1.2 adjudication (VALIDATION is not a canonical Category variant; canonical abbreviated form is VAL per error-taxonomy). F-P140-08 — remove un-minted error code E-EMBED-003 from two sites: (1) §Provider explicitly excluded body: '`E-EMBED-003 UnsupportedOperation`' → 'an UnsupportedOperation error'; (2) §Alt B heading: 'returning E-EMBED-003' → 'returning an UnsupportedOperation error'. E-EMBED-003 was never minted (error-taxonomy EMBED namespace has exactly 1 code: E-EMBED-001). E-EMBED-002 implied gap also removed."
  - "1.3 (burst-238/2026-07-23): Stale-handoff sweep — remove stale 'VP-008 candidate' labels (two sites: §Dimensionality contract body paragraph, §Consequences bullets). VP-008 was seeded in burst-223 (D21, VP-INDEX v1.2, proptest P1). Replace with 'VP-008 (proptest P1, seeded burst-223)'."
  - "1.2 (burst-225/2026-07-21): F-P130-07 sibling sweep — correct stale E-EMBED-001 message prefix in §Dimensionality contract: `DimensionMismatch: ...` → `EmbeddingDimensionMismatch: ...` per error-taxonomy v1.29 (PO renamed prefix to distinguish from E-VS-002 which retains bare `DimensionMismatch:`)."
  - "1.1 (crates.io/2026-07-20): Add Ollama endpoint preference (prefer POST /api/embed, `input` field; /api/embeddings legacy fallback with `use_legacy_endpoint` toggle); note OpenAI model currency (text-embedding-3-small/large current, ada-002 legacy)."
  - "1.0 (D21/2026-07-20): Initial ADR — Embeddings trait in ferrochain-core (core::embeddings), async dyn-compatible shape, dimensionality contract, ferrochain-openai + ferrochain-ollama gain embeddings modules, ferrochain-anthropic excluded (no embedding API), ferrochain-vectorstores uses Embeddings for in-memory backend."
---

# ADR-017: Embeddings Trait and Provider Integration

**Status:** Accepted — D21 ecosystem-parity scope expansion

## Context

D21 promotes embeddings to full v1 scope. The Python reference corpus
(`langchain_core/embeddings/base.py`) defines an `Embeddings` abstract base class
with two core methods: `embed_documents` (batch) and `embed_query` (single query).

Three questions must be resolved:

1. **Trait placement:** ferrochain-core vs ferrochain-vectorstores vs a new crate?
2. **Async dyn-compatible shape:** following ADR-005 object-safety precedent.
3. **Provider scope:** which of the three existing provider crates get embedding impls,
   and which do not (based on what APIs actually exist)?

## Decision 1 — Trait Placement: `core::embeddings` in ferrochain-core

`Embeddings` is a foundational abstraction used by:
- `ferrochain-vectorstores` (VectorStoreFactory takes `Arc<dyn Embeddings>`)
- `ferrochain-memory` (memory::search may drive semantic search via embeddings)
- Any Runnable pipeline node that generates embeddings

Placing `Embeddings` in ferrochain-core makes it available to all of these without
creating a circular dependency. The trait itself carries no additional deps beyond
`ferrochain-core`'s existing imports (serde, thiserror). This is the same placement
decision made for `Retriever` (ADR-014) and `BudgetPolicy` (ADR-009).

The `Document` type (ADR-014, `core::documents`) is already in ferrochain-core and is
the natural output type of retrieval pipelines that use `Embeddings`.

## Decision 2 — Async Dyn-Compatible Trait Shape

```rust
// ferrochain-core: core::embeddings
use ferrochain_core::error::FerrochainError;

#[async_trait]
pub trait Embeddings: Send + Sync {
    /// Embed a batch of texts. Returns one embedding vector per input text.
    ///
    /// # Dyn-compatibility
    /// `&self` receiver + `#[async_trait]` boxed-future desugaring. No generic type params.
    ///
    /// # Dimensionality contract
    /// All returned vectors MUST have the same length as the vector returned by
    /// `embed_query` for the same model. Implementors MUST return Err if the
    /// embedding service returns inconsistent dimensions within a batch.
    async fn embed_documents(
        &self,
        texts: Vec<String>,
    ) -> Result<Vec<Vec<f32>>, FerrochainError>;

    /// Embed a single query string. Semantically equivalent to embed_documents([text])[0]
    /// but may use a different tokenization or prefix depending on the provider model.
    async fn embed_query(
        &self,
        text: String,
    ) -> Result<Vec<f32>, FerrochainError>;
}
```

Object-safety: `&self` receivers, no generic type params, `#[async_trait]` desugaring
to `Pin<Box<dyn Future<...> + Send + '_>>`. `Arc<dyn Embeddings>` compiles without E0038.
Pattern follows ADR-005 §Object-Safety and the Retriever trait shape (ADR-014).

### Dimensionality contract

Every `Embeddings` implementation MUST guarantee:
- `embed_documents(texts).len() == texts.len()` — one vector per input
- All returned vectors have the same length (the model's embedding dimension)
- `embed_query(text)` returns a vector of the same length as any `embed_documents` vector

Violation of these invariants MUST return `Err(FerrochainError { code: "E-EMBED-001", category: Category::Val, .. })`. Returning a ragged result
silently (wrong-length vectors in the output) violates DI-014 (no silent failures).

VP-008 (proptest P1, seeded burst-223): proptest property test that for any valid `Embeddings` impl, all
output vectors have the same length and `embed_query` length == `embed_documents` inner length.

### Batch error semantics

`embed_documents` on a batch: if the provider returns a partial batch error (e.g., OpenAI
rate limit hits mid-batch), the entire call returns `Err`. No silent partial-batch
degradation to `Vec::new()` (DI-014 / Code Conventions: no silent empty returns).

## Decision 3 — Provider Scope

### Providers that gain embedding impls in v1

**ferrochain-openai** → gains `openai::embeddings` module

OpenAI provides the `/v1/embeddings` endpoint supporting multiple text embedding models.
**Model currency (crates.io/2026-07-20):** `text-embedding-3-small` and
`text-embedding-3-large` are the current recommended models; `text-embedding-ada-002`
is legacy (still supported by OpenAI but superseded by the 3-series — prefer 3-small for
cost/performance balance). `ferrochain-openai` gains an `EmbeddingsOpenAI` struct
configurable to any model name string, defaulting to `text-embedding-3-small`. These are
the dominant embedding models in the Python langchain ecosystem (~4 of the 23 partner
registry entries relate to OpenAI). reqwest client with `rustls-tls` mandatory per
workspace convention; 30-second timeout per DI-009.

**ferrochain-ollama** → gains `ollama::embeddings` module

Ollama exposes two embedding endpoints: `POST /api/embed` (newer, uses `input` field,
**preferred**) and `POST /api/embeddings` (legacy, uses `prompt` field, fallback). Both
support any local model with embedding capabilities (e.g., `nomic-embed-text`,
`mxbai-embed-large`). `EmbeddingsOllama` defaults to `POST /api/embed`; a
`use_legacy_endpoint: bool` config field enables the `/api/embeddings` fallback for Ollama
deployments that predate the `/api/embed` introduction. No API key required (Ollama is
local); uses the existing Ollama base URL config.

### Provider explicitly excluded from v1

**ferrochain-anthropic** → NO embedding module

Anthropic does not provide a public embeddings API. As of the D21 scope cut, Anthropic's
Claude models do not expose an embedding endpoint. Adding a stub module that returns
an UnsupportedOperation error would violate the production-grade default (no phantom
functionality). ferrochain-anthropic ships with no `Embeddings` impl in v1.

If Anthropic adds an embeddings API post-v1, a new module can be added without any
architectural change — the `Embeddings` trait in ferrochain-core is already in place.

### Community embedding providers

~77 embedding providers exist in `langchain-community`. These land in `ferrochain-community`
(post-v1), consistent with the broader community strategy. The `Embeddings` trait in
ferrochain-core is the extension point.

## Decision 4 — ferrochain-vectorstores Dependency on Embeddings

`ferrochain-vectorstores` depends on ferrochain-core (and therefore on `core::embeddings`).
The in-memory VectorStore backend (`vectorstores::memory`) accepts `Arc<dyn Embeddings>`
at construction time to convert query strings to vectors for cosine search. The in-memory
backend stores raw `Vec<f32>` vectors internally; embedding generation is delegated to the
injected `Embeddings` impl (Arc-DI wiring per workspace convention).

```rust
pub struct InMemoryVectorStore {
    embedding: Arc<dyn Embeddings>,
    docs: RwLock<Vec<(Document, Vec<f32>)>>,
}
```

This is the canonical Arc-DI pattern: no placeholder construction; the embedding provider
is wired at construction time and held for the lifetime of the store.

## Rationale

**Why `core::embeddings` in ferrochain-core and not ferrochain-vectorstores?**
`ferrochain-memory` may also use embeddings for semantic search (`memory::search`). If the
trait lived in ferrochain-vectorstores, ferrochain-memory would depend on ferrochain-vectorstores
just to accept `Arc<dyn Embeddings>` — an inversion of the correct dependency direction.
Core is the right home for shared abstraction traits (same reasoning as `Retriever`,
`BudgetPolicy`, `GuardrailHook`).

**Why exclude ferrochain-anthropic?** Shipping a stub that always errors is not
production-grade. An `Embeddings` impl must be callable without silently failing —
if there is no API endpoint, there is no impl. Anthropic's provider crate ships without
an `Embeddings` impl and gains one when the API exists.

**Why `Vec<f32>` and not `ndarray::Array1<f32>`?** Semport analysis (§8) explicitly
recommends "plain `Vec<f32>` cosine, avoid `ndarray` in core." `ndarray` is a large,
compile-heavy crate that would become a transitive dep of ferrochain-core for all users.
`Vec<f32>` is zero-overhead for the memory backend and sufficient for cosine similarity.
Performance-critical backends (e.g., a Faiss-backed community adapter) can convert
internally.

## Alternatives Considered

### Alt A: Embeddings trait in ferrochain-vectorstores

Arguments for: tighter co-location with VectorStore.
Rejected: ferrochain-memory would need to depend on ferrochain-vectorstores (wrong
direction). ferrochain-core already depends on neither, so the trait must live there.

### Alt B: Add Anthropic embedding stub returning an UnsupportedOperation error

Arguments for: uniform interface; future-proof if Anthropic adds the API.
Rejected: a stub that always errors is phantom functionality. Users discovering that
`EmbeddingsAnthropic` exists but always fails is a worse experience than it not existing.
When the API exists, the module is added.

### Alt C: ndarray::Array1<f32> for embedding vectors

Arguments for: richer linear algebra API; performance.
Rejected: `ndarray` is too heavy for core (semport §8 explicit recommendation). `Vec<f32>`
is interoperable with every linear algebra library and adds zero deps.

### Alt D: New `ferrochain-embeddings` crate

Arguments for: isolates embedding providers from the VectorStore/Retriever abstraction.
Rejected: trait only (no heavy deps) belongs in core; provider impls belong in their
respective provider crates. An intermediary crate adds complexity with no benefit.

## Source / Origin

- **D21 (burst 216)**: ecosystem-parity scope expansion for embeddings.
- **semport/core/rust-translation-strategy.md §8**: `Embeddings` trait difficulty 🟢,
  `Vec<f32>` cosine recommendation, `ndarray` avoidance in core.
- **ADR-005 §Object-Safety**: `&self` + `#[async_trait]` dyn-compatible async trait precedent.
- **ADR-014**: VectorStore depends on `Embeddings` for in-memory backend and factory.
- **DI-009**: mandatory 30-second timeout for outbound HTTP clients (`EmbeddingsOpenAI`,
  `EmbeddingsOllama` reqwest clients).
- **DI-010**: credential opacity — `EmbeddingsOpenAI` takes `OpenAiApiKey` newtype.
- **DI-014**: no silent empty returns — partial batch failures return `Err`.

## Consequences

- `core::embeddings` is a new module in ferrochain-core. `Embeddings` trait and
  `EmbeddingError` (E-EMBED-NNN codes) are new public surface in ferrochain-core.
- ferrochain-openai gains `openai::embeddings` (new module, new struct `EmbeddingsOpenAI`).
- ferrochain-ollama gains `ollama::embeddings` (new module, new struct `EmbeddingsOllama`).
- ferrochain-anthropic gains NO embeddings module in v1.
- ferrochain-vectorstores depends on ferrochain-core for `Arc<dyn Embeddings>` in its
  in-memory VectorStore backend constructor.
- VP-008 (proptest P1, seeded burst-223): proptest dimensionality invariant for any Embeddings impl.
- Both `EmbeddingsOpenAI` and `EmbeddingsOllama` require `reqwest` with `rustls-tls`.
  They must NOT use `reqwest::Client::new()` without `.timeout()` (DI-009; xtask CI gate
  `check-client-timeout` enforces this workspace-wide).
