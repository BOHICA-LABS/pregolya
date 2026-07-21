---
document_type: adr
level: L3
adr_id: "014"
slug: vectorstore-retriever-abstraction
title: "VectorStore + Retriever Abstraction: Async Dyn-Compatible Traits, Factory Pattern, MMR Surface, and SS-15 Boundary"
status: accepted
date: "2026-07-20"
producer: architect
timestamp: 2026-07-20T00:00:00Z
version: "1.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D21]
supersedes: null
superseded_by: null
subsystems_affected: [SS-20, SS-21]
changelog:
  - "1.1 (crates.io/2026-07-20): Add zero-norm vector guard hardening note for cosine similarity (NaN prevention, 2-line check, no new dep)."
  - "1.0 (D21/2026-07-20): Initial ADR — crate placement (ferrochain-vectorstores new crate; Retriever + Document in ferrochain-core), async dyn-compatible trait shapes, VectorStoreFactory pattern, MMR surface, SS-15 MemoryStore boundary definition, inventory extension seam."
---

# ADR-014: VectorStore + Retriever Abstraction

**Status:** Accepted — D21 ecosystem-parity scope expansion

## Context

D21 promotes retrievers and vectorstores to full v1 scope. The Python reference corpus
(`langchain_core/retrievers/`, `langchain_core/vectorstores/`) defines two cooperative
abstractions: `Retriever` (query → ranked documents) and `VectorStore` (document index
with similarity/MMR search). Both must be async, dyn-compatible (following ADR-005
object-safety precedent), and non-overlapping with SS-15's MemoryStore.

Three design questions must be resolved:

1. **Crate placement:** new `ferrochain-vectorstores` vs fold into ferrochain-core or
   ferrochain-memory.
2. **Trait shapes:** how to achieve dyn-compatibility for `from_texts` (a constructor,
   not an instance method) and for stream-returning methods.
3. **Boundary with SS-15 (MemoryStore / long-horizon memory):** the new standalone
   VectorStore must not duplicate or conflict with CAP-017.

## Decision 1 — Crate Placement

**Retriever trait → ferrochain-core** (module `core::retriever`)
**Document type → ferrochain-core** (module `core::documents`)
**VectorStore trait + in-memory impl + MMR + VectorStoreRetriever → new `ferrochain-vectorstores` crate**

Rationale:

`Retriever` is as foundational as `BaseChatModel` and `Runnable`: graph nodes that perform
RAG operations need `Arc<dyn Retriever>` without pulling in a heavier crate. Placing it in
ferrochain-core preserves the same gravity as the other top-level trait abstractions.
`Document { page_content, metadata, id }` is the carrier type for all retrieval output
and must be accessible from both ferrochain-core and ferrochain-vectorstores.

`VectorStore` is heavier: it owns a document index, performs embedding-driven search,
implements MMR, and exposes an in-memory backend with `Vec<f32>` cosine math. These
concerns justify their own crate. An in-memory impl in ferrochain-core would pull
vector arithmetic into the core dependency. A new `ferrochain-vectorstores` crate
(depending on ferrochain-core) keeps core lean and matches the pattern of
`ferrochain-memory` (its own crate) and `ferrochain-splitters` (its own crate).

External community adapters (Chroma, Qdrant, pgvector, Weaviate, etc.) live in
`ferrochain-community` (post-v1), consistent with the ~89 vectorstore and ~43 retriever
community implementations in the Python reference corpus.

**Rejected alternatives:**
- **Fold into ferrochain-core:** Pulls vector arithmetic and optional embedding deps into
  every downstream user of ferrochain-core. REJECT.
- **Fold into ferrochain-memory:** MemoryStore and VectorStore are semantically distinct
  (see Decision 3). Colocation creates confusion and couples unrelated subsystems. REJECT.
- **Fold Retriever into ferrochain-vectorstores:** Requires graph nodes to depend on
  ferrochain-vectorstores just to hold `Arc<dyn Retriever>`. REJECT.

## Decision 2 — Async Dyn-Compatible Trait Shapes

### Document type

```rust
// ferrochain-core: core::documents
#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
#[non_exhaustive]
pub struct Document {
    pub page_content: String,
    pub metadata: serde_json::Map<String, serde_json::Value>,
    pub id: Option<String>,
}
```

No I/O. Pure data carrier. Pure Core classification.

### Retriever trait (ferrochain-core)

```rust
// ferrochain-core: core::retriever
#[async_trait]
pub trait Retriever: Send + Sync {
    /// Retrieve documents relevant to `query`.
    ///
    /// # Dyn-compatibility
    /// `&self` receiver + `async_trait` boxed-future desugaring. No generic type params.
    async fn get_relevant_documents(
        &self,
        query: &str,
    ) -> Result<Vec<Document>, FerrochainError>;
}
```

Object-safety: `&self` receiver, no generic type params, no `impl Trait` return (desugared
by `#[async_trait]` to `Pin<Box<dyn Future<Output = ...> + Send + '_>>`). `Arc<dyn Retriever>`
compiles without E0038. Consistent with ADR-005 §Object-Safety.

### VectorStore trait (ferrochain-vectorstores)

`from_texts` is a static constructor that creates a new store. Static methods are NOT
dyn-compatible (no vtable dispatch without a receiver). Resolution: `from_texts` is
defined as an associated method on a separate `VectorStoreFactory` trait, NOT on the
`VectorStore` trait itself. The main `VectorStore` trait contains only instance methods.

```rust
// ferrochain-vectorstores: vectorstores::store
#[async_trait]
pub trait VectorStore: Send + Sync {
    /// Add texts (and optional metadata) to the store. Returns document IDs.
    async fn add_texts(
        &self,
        texts: Vec<String>,
        metadatas: Option<Vec<serde_json::Map<String, serde_json::Value>>>,
    ) -> Result<Vec<String>, FerrochainError>;

    /// Standard k-nearest-neighbor similarity search.
    async fn similarity_search(
        &self,
        query: &str,
        k: usize,
    ) -> Result<Vec<Document>, FerrochainError>;

    /// Similarity search with relevance scores in [0.0, 1.0].
    async fn similarity_search_with_score(
        &self,
        query: &str,
        k: usize,
    ) -> Result<Vec<(Document, f32)>, FerrochainError>;

    /// Maximal Marginal Relevance search.
    ///
    /// Reduces redundancy in results by penalizing similarity to already-selected
    /// documents. `lambda_mult` ∈ [0.0, 1.0]: 0.0 = maximum diversity, 1.0 = maximum
    /// relevance (degenerates to standard similarity search).
    async fn max_marginal_relevance_search(
        &self,
        query: &str,
        k: usize,
        fetch_k: usize,
        lambda_mult: f32,
    ) -> Result<Vec<Document>, FerrochainError>;

    /// Delete documents by ID.
    async fn delete(&self, ids: &[&str]) -> Result<(), FerrochainError>;

    /// Return a Retriever view over this store. Concrete return type — not a method
    /// with opaque return, preserving dyn-compatibility.
    fn as_retriever(&self) -> VectorStoreRetriever<'_>;
}

/// Factory trait: static constructors for VectorStore implementors. NOT part of the
/// dyn VectorStore contract (static methods are excluded from trait objects).
pub trait VectorStoreFactory: VectorStore + Sized {
    type Config: Default;

    /// Create a new store from a set of texts.
    fn from_texts_sync(
        texts: Vec<String>,
        embedding: Arc<dyn Embeddings>,
        config: Self::Config,
    ) -> impl std::future::Future<Output = Result<Self, FerrochainError>> + Send;
}

/// Concrete retriever wrapper over any VectorStore.
pub struct VectorStoreRetriever<'a> {
    store: &'a dyn VectorStore,
    search_type: SearchType,
    k: usize,
    fetch_k: usize,
    lambda_mult: f32,
}

#[derive(Debug, Clone, Default)]
pub enum SearchType {
    #[default]
    Similarity,
    SimilarityScoreThreshold { score_threshold: f32 },
    Mmr,
}

// VectorStoreRetriever implements Retriever
#[async_trait]
impl Retriever for VectorStoreRetriever<'_> {
    async fn get_relevant_documents(
        &self,
        query: &str,
    ) -> Result<Vec<Document>, FerrochainError> { /* dispatch to store */ }
}
```

Object-safety of `VectorStore`: all instance methods have `&self` receivers; all async
methods are desugared via `#[async_trait]`; `as_retriever` returns a concrete struct (not
an opaque type). `Arc<dyn VectorStore>` compiles without E0038.

`add_texts` uses `&self` (not `&mut self`) because external VectorStore backends (Qdrant,
Chroma, pgvector) are fundamentally stateless from the client perspective — mutations go
to the remote server. The in-memory backend uses interior mutability (`RwLock`).

### Metadata filter surface

A `MetadataFilter` type is defined to enable pre-filtering before similarity search:

```rust
pub struct MetadataFilter {
    pub filters: Vec<FilterClause>,
}
pub enum FilterClause {
    Eq { key: String, value: serde_json::Value },
    Ne { key: String, value: serde_json::Value },
    In { key: String, values: Vec<serde_json::Value> },
    // extensible via #[non_exhaustive]
}
```

Optional parameter on `similarity_search_with_filter` (additive method on the trait,
not breaking the base contract). Community adapters that support native metadata
filtering implement this optional method; in-memory impl implements via post-filter.

### Hardening note — zero-norm vector guard

The in-memory cosine similarity implementation MUST guard against zero-norm vectors
before performing division. A zero-length embedding vector produces a NaN result
(`0.0 / 0.0`) that silently corrupts ranking and propagates through similarity scores.
The guard is two lines and requires no new dependency:

```rust
let norm = v.iter().map(|x| x * x).sum::<f32>().sqrt();
if norm == 0.0 { return Err(FerrochainError { code: "E-VS-001", ... }); }
```

This check belongs in `vectorstores::mmr` (pure-core) before any cosine call. VP-009
(MMR semantic diversity) should include a proptest property asserting no NaN in output
scores for any valid non-zero query embedding.

## Decision 3 — SS-15 (MemoryStore) Boundary Definition

`MemoryStore` (SS-15, ferrochain-memory) and `VectorStore` (SS-21, ferrochain-vectorstores)
are parallel but NON-OVERLAPPING abstractions with distinct purposes:

| Dimension | MemoryStore (SS-15) | VectorStore (SS-21) |
|-----------|--------------------|--------------------|
| Purpose | Long-horizon agent memory (persistent across runs) | RAG document retrieval (external document index) |
| Scope | Session-scoped; owned by the agent | Stateless from agent's perspective; externally managed |
| GDPR | Explicit erasure protocol (BC-2.15.002) | NOT scoped here |
| Write path | Guarded via `memory::write_guard` (ADR-012) | Unguarded add_texts (no injection scanning) |
| Read path | `MemoryStore::search` (keyword/vector/hybrid within agent's own data) | `VectorStore::similarity_search` (document retrieval for RAG) |
| Guardrail | RAG results entering agent context go through `BoundaryType::RAGRetrieval` (DI-012) | Same — RAG results from VectorStore enter via DI-012 guardrail |
| CAP ownership | CAP-017 (self-improvement, memory retrieval) | New CAP under D21 |

The key rule: **MemoryStore owns agent state; VectorStore owns external document indices.**
A graph node that retrieves its own memory uses `MemoryStore`. A graph node that retrieves
external documents for RAG uses `VectorStore` (via `Retriever`). They may share a vector
backend technology internally (e.g., both could use SQLite-vec under the hood) but they are
exposed through independent trait seams.

`memory::search` in ferrochain-memory is NOT removed or reimplemented — it continues to
serve CAP-017 via MemoryStore. The new `VectorStore` abstraction serves the separate
retrieval pipeline use case.

## Decision 4 — External Adapter Extension Seam

Community VectorStore adapters (post-v1) register via the `inventory` crate with a
`submit!` call, consistent with the lc-JSON registry design (ADR-016). This gives:
- Static, link-time registration (no runtime mutation of the adapter set)
- Feature-gated inclusion (adapter only links when its Cargo feature is enabled)
- Zero reflection or dynamic plugin loading

The `ferrochain-vectorstores` crate exports the `VectorStore` + `VectorStoreFactory` traits
and the `inventory` submit macro re-export. Community adapters implement `VectorStoreFactory`
and call `inventory::submit! { VectorStoreFactoryDescriptor { name: "chroma", ... } }`.

## Rationale

`Retriever` in ferrochain-core follows the same gravity principle as `Runnable` and
`BaseChatModel`: graph nodes that fan out to external document sources need to hold
`Arc<dyn Retriever>` without pulling in a heavier crate. Placing it in core satisfies
the DRY-dependency principle — core is the stable foundation everything else builds on.

`VectorStore` in its own crate avoids bloating ferrochain-core with vector arithmetic
(`Vec<f32>` cosine, MMR selection), the `RwLock`-backed in-memory backend, and the
`inventory`-based adapter seam. The pattern matches `ferrochain-memory` (its own crate
for stateful, I/O-bound concerns) and `ferrochain-splitters`.

The `VectorStoreFactory` split (constructor-on-separate-trait vs constructor-on-main-trait)
is required by Rust's dyn-compatibility rules: a `fn new()` associated function is not
vtable-dispatchable and would make `dyn VectorStore` impossible (E0038). Splitting it
into a separate `Sized`-bounded `VectorStoreFactory` preserves both the constructor
convenience and `Arc<dyn VectorStore>` dyn dispatch, following the same `&self`-receiver
discipline established in ADR-005.

The SS-15 boundary (MemoryStore vs VectorStore) is defined by semantics, not by technology:
agent-owned session data vs externally-managed document indices. Conflating them would
force GDPR erasure logic, write guards, and session scoping into a general-purpose vector
index abstraction — a category error.

## Alternatives Considered

### Alt A: VectorStore trait in ferrochain-core (alongside Retriever)

Arguments for: single crate for all retrieval abstractions; no extra dep for graph nodes.
Rejected: pulls `Vec<f32>` cosine math, `RwLock`-backed in-memory backend, and the
`inventory` extension seam into every ferrochain-core user. Core stays lean.

### Alt B: VectorStore and Retriever both in ferrochain-vectorstores

Arguments for: all retrieval in one crate. Rejected: forces graph nodes to depend on
ferrochain-vectorstores just to hold `Arc<dyn Retriever>` — a violation of the
"core for shared primitives" principle. Every RAG-capable graph would grow an
unnecessary heavy dependency.

### Alt C: from_texts as an optional method on VectorStore trait with `where Self: Sized` bound

Arguments for: keeps factory co-located with the main trait. Rejected: `where Self: Sized`
excludes the method from the vtable (E0038 workaround), but still burdens the trait with
a Sized-bounded method users of `dyn VectorStore` cannot call. Explicit `VectorStoreFactory`
trait is cleaner API design and a clearer signal to implementors.

### Alt D: Fold into ferrochain-memory

Rejected: MemoryStore and VectorStore are semantically orthogonal (see Decision 3 table).
Coupling them creates confusion about GDPR erasure, session scoping, and write-guard
applicability. Two separate crates with a clear boundary is correct.

## Source / Origin

- **D21 (burst 216)**: ecosystem-parity scope expansion promoting retrievers and vectorstores
  to full v1 scope.
- **semport/core/rust-translation-strategy.md §8**: `Document`, `Embeddings`, `Retriever`,
  `VectorStore` difficulty assessment (🟢–🟡); in-memory VectorStore recommendation (plain
  `Vec<f32>` cosine, avoid `ndarray` in core).
- **ADR-005 §Object-Safety**: `&self` receiver + `#[async_trait]` desugaring precedent for
  dyn-compatible async trait methods; `Arc<dyn CheckpointSaver>` pattern.
- **DI-012 / BC-2.11.001**: `BoundaryType::RAGRetrieval` existing variant confirms the
  guardrail seam already covers VectorStore-backed retrieval — no BoundaryType extension needed.
- **ADR-012**: MemoryStore write-guard confirms MemoryStore is agent-scoped; this ADR
  defines the non-overlapping RAG-scoped VectorStore boundary.

## Consequences

- ferrochain-vectorstores is a new crate (20th published crate in the roster, alongside
  `ferrochain-prompts` = 19th, both added in D21).
- `core::documents` and `core::retriever` are new modules in ferrochain-core. ferrochain-core
  gains `Document` and `Retriever` as first-class public types.
- ferrochain-vectorstores depends on ferrochain-core (for `Document`, `Retriever`,
  `Embeddings`, `FerrochainError`).
- `VectorStoreRetriever` implements `Retriever` — graph nodes accepting `Arc<dyn Retriever>`
  can transparently use any VectorStore backend.
- The `inventory` crate becomes a dependency of ferrochain-vectorstores (and ferrochain-core,
  for the lc-JSON registry — see ADR-016).
- reqwest in any community VectorStore adapter: rustls-tls mandatory per workspace convention.
- DI-012 guardrail: documents returned by `Retriever::get_relevant_documents` enter the
  graph context as `BoundaryType::RAGRetrieval`. This existing boundary type correctly covers
  all VectorStore-backed retrievers — no extension needed.

