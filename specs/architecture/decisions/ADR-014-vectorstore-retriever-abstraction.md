---
document_type: adr
level: L3
adr_id: "014"
slug: vectorstore-retriever-abstraction
title: "VectorStore + Retriever Abstraction: Async Dyn-Compatible Traits, Factory Pattern, MMR Surface, and SS-15 Boundary"
status: accepted
date: "2026-07-21"
producer: architect
timestamp: 2026-07-23T00:00:00Z
version: "1.7"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D21]
supersedes: null
superseded_by: null
subsystems_affected: [SS-20, SS-21]
changelog:
  - "1.7 (burst-238/2026-07-23): Stale-handoff sweep (continuation) — rewrite five 'Error taxonomy must mint' future-tense obligations to past-tense facts: (1) Consequences §E-VS-004 line: 'must mint' → 'minted'; (2) §PO Obligations E-VS-004 header: 'Error taxonomy must mint E-VS-004' → 'E-VS-004 minted (error-taxonomy v1.27/D21)'; (3) §PO Obligations E-CORE-008 header: 'Error taxonomy must mint E-CORE-008' → 'E-CORE-008 minted (error-taxonomy v1.30/burst-226)'; (4) §PO Obligations E-VS-005 header: 'Error taxonomy must mint E-VS-005' → 'E-VS-005 minted (error-taxonomy v1.30/burst-226)'."
  - "1.6 (burst-238/2026-07-23): Stale-handoff sweep — rewrite three 'PO must' future-tense obligations in §PO Obligations to past-tense facts: (1) BC-2.20.002 anchor corrections → 'BC-2.20.002 v1.2 applied'; (2) BC-2.20.002 PC2 severity-bifurcation update → 'BC-2.20.002 v1.3 updated PC2'; (3) BC-2.21.004 INV-3 fail-safe update → 'BC-2.21.004 v1.2 updated INV-3'."
  - "1.5 (burst-226/2026-07-21): F-P131-01 (HIGH) — GuardedDocuments::rag_ingress Fail arm severity-bifurcated per BC-2.11.005 PC4/PC5. Critical Fail → Err(E-CORE-008, GuardrailCriticalRejection, SECURITY) — batch aborts. Non-Critical Fail → error-entry Document substituted at position i, batch continues. Docstring updated. Consequences bullet updated (Fail arm description). PO Obligations: E-CORE-008 mint obligation added; BC-2.20.002 PC2 update obligation added. F-P131-07 (MED) — similarity_search_with_filter default implementation changed from lossy-fallback to fail-safe: non-empty filter on an adapter that has not overridden this method returns Err(E-VS-005, FilterUnsupported, VAL). Empty filter (vacuously true) still delegates to similarity_search. PO Obligations: E-VS-005 mint obligation added; BC-2.21.004 INV-3 update obligation added."
  - "1.4 (burst-225/2026-07-21): F-P130-01 (CRITICAL) — Decision 6 GuardrailHook re-definition removed; replaced with canonical `async fn evaluate` signature from interface-definitions.md §GuardrailHook (authority-deference: BC-2.11.001..006 supersede on contract semantics). GuardedDocuments::rag_ingress made async; mechanism corrected to per-document evaluate calls with IngressContent::RagChunk per BC-2.11.003 PC1/PC5; all three GuardrailResult arms (Pass/Fail/Transform) honoured. BoundaryType re-definition in Decision 6 body removed — BoundaryType is defined in core::guardrail per BC-2.11.001 canonical precedent; only referenced here via ProvenanceTag. Purity classification note updated: rag_ingress is async → Boundary Module classification confirmed unchanged. Consequences bullets updated accordingly. Sibling sweep: purity-boundary-map.md v1.8 (core::guardrail + core::retriever rows), module-decomposition.md v1.13 (guardrail comment block). PO handoff text for BC-2.20.002 ferrochain-guardrail→ferrochain-core anchor corrections (F-P130-02) recorded in §PO Obligations."
  - "1.3 (burst-224/2026-07-21): Collision correction — error-taxonomy.md line 288 already defines E-VS-003 (VectorStoreRetriever config validation, VAL, BC-2.20.003). Write-time zero-norm rejection code corrected from E-VS-003 → E-VS-004 throughout Decision 5 heading, table, code sketches, and Consequences section. PO handoff updated to mint E-VS-004."
  - "1.2 (burst-224/2026-07-21): F-P129-05 — fix Hardening Note: VP-009 is Zero-Norm Cosine Guard (Kani P0), not MMR proptest; reference VP-2.21.003-C for MMR proptest sub-property. F-P129-11 — update cosine primitive location: vectorstores::mmr → vectorstores::similarity. F-P129-08 — add Decision 5: write-time zero-norm rejection (E-VS-004, corrected in v1.3) at add_texts/from_texts_sync; search-time E-VS-001 (VP-009) remains as defense-in-depth. F-P129-09 — add Decision 6: GuardedDocuments newtype (no public constructor; sole constructor rag_ingress); GuardrailHook promoted to core::guardrail (pure-core, trait-in-core precedent); core::retriever reclassified Boundary; DI-012 becomes compile-time type-error enforcement. Add Consequences bullets for E-VS-004 (corrected in v1.3), GuardedDocuments, and core::guardrail."
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
filtering MUST override this method with a native implementation.

**F-P131-07 adjudication (burst-226) — default must be fail-safe, not lossy:**
The default trait implementation of `similarity_search_with_filter` MUST NOT silently
ignore a non-empty filter (the former "lossy fallback to `similarity_search`"). Silent
degradation is a cross-tenant-exposure hazard: an adapter that forgets to override
would return unfiltered results as if filtering occurred.

Default implementation:

```rust
// Default implementation — fail-safe for adapters that have not overridden this method.
async fn similarity_search_with_filter(
    &self,
    query: &str,
    k: usize,
    filter: MetadataFilter,
) -> Result<Vec<Document>, FerrochainError> {
    if !filter.filters.is_empty() {
        // Non-empty filter on an adapter that has not overridden this method.
        // Returning silently-unfiltered results would expose cross-tenant data.
        return Err(FerrochainError {
            component: Component::VS,
            category: Category::VAL,
            code: "E-VS-005",
            message: "FilterUnsupported: this VectorStore backend does not support \
                      metadata filtering; override similarity_search_with_filter to \
                      provide native filter support".to_string(),
        });
    }
    // Empty filter = vacuously true (BC-2.21.004 EC-004) — delegate to unfiltered search.
    self.similarity_search(query, k).await
}
```

An empty `MetadataFilter` (no filter clauses) is vacuously true — the default
implementation delegates to `similarity_search` in that case, preserving the
empty-filter semantics per BC-2.21.004 EC-004.

### Hardening note — zero-norm vector guard

The cosine similarity implementation MUST guard against zero-norm vectors before
performing division. A zero-length embedding vector produces a NaN result (`0.0 / 0.0`)
that silently corrupts ranking and propagates through similarity scores. The guard is
two lines and requires no new dependency:

```rust
let norm = v.iter().map(|x| x * x).sum::<f32>().sqrt();
if norm == 0.0 { return Err(FerrochainError { component: Component::VS, category: Category::VAL, code: "E-VS-001", ... }); }
```

This check belongs in `vectorstores::similarity` (pure-core) — the shared cosine
primitive called by `vectorstores::memory`, `vectorstores::mmr`, and any future backend
— not in `vectorstores::mmr` specifically.

**VP-009** is the Zero-Norm Cosine Guard: a Kani P0 formal proof that
`cosine_similarity` returns `Err(E-VS-001)` when either input vector has L2 norm equal
to 0.0. This property is exhaustive over all IEEE-754 zero-norm input combinations;
the target harness is `vectorstores::similarity::cosine_similarity`.

The MMR output-quality property (no NaN in output scores for valid non-zero embeddings)
is a separate, complementary sub-property anchored to BC-2.21.003 as **VP-2.21.003-C**
(proptest P1 — statistically explores the non-zero input space).

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

## Decision 5 — Write-Time Zero-Norm Guard (E-VS-004)

### Problem

The search-time cosine guard (`E-VS-001`, VP-009 Kani P0) fires when a zero-norm
document is already in the index. A single stored zero-norm embedding makes every
subsequent similarity query fail — total search outage — with poor diagnosability.
The store is effectively unusable until the bad document is deleted.

### Decision

`add_texts` and `from_texts_sync` MUST reject any document whose embedding vector has
L2 norm == 0.0 at write time, before the document is persisted to the index.

**Error code:** `E-VS-004` (new code; NOT a reuse of `E-VS-001`; E-VS-003 is already taken by VectorStoreRetriever config validation per error-taxonomy.md)

| Code | Trigger | Context |
|------|---------|---------|
| `E-VS-001` | Search-time cosine guard; zero-norm query or stored embedding encountered during similarity computation | — |
| `E-VS-004` | Write-time zero-norm rejection; embedding rejected before storage | `document_index` (0-based index of the offending document) |

Both codes are in the `VS` namespace (`ferrochain-vectorstores`). `E-VS-004` minted in
error-taxonomy v1.27/D21 (see §PO Obligations for mint record).

**`document_index` placement:** structured context field, NOT interpolated in the
message string (gate #33 / cross-cutting error-context convention):

```rust
FerrochainError {
    component: Component::VS,
    category: Category::VAL,
    code: "E-VS-004",
    message: "embedding vector has zero L2 norm; document rejected at write time",
    context: {
        "document_index": <0-based usize index of rejected document>,
    },
}
```

### Write-time check sketch

```rust
// in add_texts / from_texts_sync, after embedding generation, before index write:
for (i, embedding) in embeddings.iter().enumerate() {
    let norm = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm == 0.0 {
        return Err(FerrochainError {
            component: Component::VS,
            category: Category::VAL,
            code: "E-VS-004",
            message: "embedding vector has zero L2 norm; document rejected at write time",
            context: [("document_index", i)].into(),
        });
    }
}
```

### Defense-in-depth

The search-time guard (`E-VS-001`, VP-009 Kani P0 in `vectorstores::similarity`)
remains active alongside the write-time guard. Both guards are required:

- **Write-time E-VS-004** — primary gate; prevents bad data from entering the index
- **Search-time E-VS-001** — defense-in-depth; handles embeddings loaded from external
  stores that bypassed ferrochain's write path, or future index migration scenarios

## Decision 6 — GuardedDocuments Typed Wrapper (DI-012 Mechanization)

### Problem

BC-2.20.002 (SECURITY-MANDATORY P0, DI-012) requires that every batch of documents
entering the graph context via RAG passes through the `BoundaryType::RAGRetrieval`
guardrail. The prior VP for BC-2.20.002 was "code review + unit test per graph node"
— not mechanizable: guardrail bypass is detected only at review time or runtime, not at
compile time. A single missed graph-node update silently skips the guardrail.

### Decision

Introduce `GuardedDocuments` — a newtype in `core::retriever` that is a type-level
proof that the RAG guardrail has been applied. There is no public struct constructor;
`GuardedDocuments::rag_ingress` is the sole public constructor.

**Newtype shape (ferrochain-core / core::retriever):**

```rust
// No `pub` on the inner field; construction is gated entirely through rag_ingress.
pub struct GuardedDocuments(Vec<Document>);

impl GuardedDocuments {
    /// Sole public constructor. Per-document async guardrail gate per BC-2.11.003.
    ///
    /// For each document D in `docs`:
    ///   1. Constructs `IngressContent::RagChunk(serde_json::to_value(&D)?)`.
    ///   2. Constructs `ProvenanceTag { boundary_type: BoundaryType::RAGRetrieval,
    ///      ingress_id, sequence_position: i }` per BC-2.11.001.
    ///   3. Calls `guardrail.evaluate(chunk, tag).await`.
    ///   4. GuardrailResult arms:
    ///      - Pass               → D included in GuardedDocuments
    ///      - Fail{reason,sev}   → Critical severity → Err(E-CORE-008) propagated;
    ///                             batch aborts (BC-2.11.005 PC4).
    ///                             Non-Critical severity → error-entry Document
    ///                             substituted at position i; batch continues
    ///                             (BC-2.11.005 PC5).
    ///      - Transform{content} → deserializes RagChunk Value back to Document;
    ///                             transformed document included (BC-2.11.003 PC4)
    ///
    /// N documents → N independent `GuardrailHook::evaluate` calls (BC-2.11.003 PC5).
    pub async fn rag_ingress(
        docs: Vec<Document>,
        guardrail: &dyn GuardrailHook,
    ) -> Result<GuardedDocuments, FerrochainError> {
        let ingress_id = Uuid::new_v4();
        let mut guarded = Vec::with_capacity(docs.len());
        for (i, doc) in docs.into_iter().enumerate() {
            let chunk = IngressContent::RagChunk(serde_json::to_value(&doc)?);
            let tag = ProvenanceTag {
                boundary_type: BoundaryType::RAGRetrieval,
                ingress_id,
                sequence_position: i,
            };
            match guardrail.evaluate(chunk, tag).await {
                GuardrailResult::Pass => guarded.push(doc),
                GuardrailResult::Fail { reason, severity } => {
                    match severity {
                        GuardrailSeverity::Critical => {
                            // Critical rejection: abort the entire batch (BC-2.11.005 PC4).
                            return Err(FerrochainError {
                                component: Component::CORE,
                                category: Category::SECURITY,
                                code: "E-CORE-008",
                                message: format!(
                                    "GuardrailCriticalRejection: document at position {} \
                                     critically rejected at RAGRetrieval boundary — {}",
                                    i, reason
                                ),
                            });
                        }
                        _ => {
                            // Non-Critical: substitute an error-entry Document at
                            // this position and continue the batch (BC-2.11.005 PC5).
                            guarded.push(Document {
                                page_content: format!("[GUARDRAIL BLOCKED: {}]", reason),
                                metadata: serde_json::json!({
                                    "ferrochain.guardrail_blocked": true,
                                    "ferrochain.guardrail_reason": reason,
                                    "ferrochain.sequence_position": i,
                                }),
                                id: None,
                            });
                        }
                    }
                }
                GuardrailResult::Transform { new_content } => {
                    if let IngressContent::RagChunk(val) = new_content {
                        guarded.push(serde_json::from_value(val)?);
                    }
                }
            }
        }
        Ok(GuardedDocuments(guarded))
    }

    /// Read-only access to the inner documents.
    pub fn documents(&self) -> &[Document] {
        &self.0
    }
}
```

**GuardrailHook trait** is defined in `core::guardrail` (ferrochain-core)
— promoted from per-subsystem dispatch modules (graph::provenance, mcp::ingress) to
ferrochain-core, consistent with the trait-in-core precedent established for
`BudgetPolicy` → `core::budget` (ADR-009) and `MemoryWriteGuard` → `core::write_guard`
(ADR-012). Existing per-subsystem dispatch modules import from ferrochain-core.

**Canonical trait (interface-definitions.md §GuardrailHook — authoritative; not re-minted here):**

```rust
// ferrochain-core: core::guardrail — definitions-only (trait + supporting enums; no execution logic)
#[async_trait]
pub trait GuardrailHook: Send + Sync {
    async fn evaluate(
        &self,
        content: IngressContent,
        provenance_tag: ProvenanceTag,
    ) -> GuardrailResult;
}

pub enum GuardrailResult {
    Pass,
    Fail { reason: String, severity: GuardrailSeverity },
    Transform { new_content: IngressContent },
}

// IngressContent variants encode the ingress boundary — RagChunk corresponds to
// BoundaryType::RAGRetrieval in ProvenanceTag (BC-2.11.001).
pub enum IngressContent {
    ToolResult(ContentBlock),
    RagChunk(serde_json::Value),  // Document serialized to Value at RAG ingress
    MemoryItem(serde_json::Value),
}

pub enum GuardrailSeverity { Critical, High, Medium, Low }

/// BoundaryType — canonical 3-variant closed set (PASS-58 canon, not #[non_exhaustive]).
/// Defined in core::guardrail; used in ProvenanceTag per BC-2.11.001.
/// Variants: ToolResult | RAGRetrieval | MemoryIngress.
/// (Full definition per BC-2.11.001 — not re-enumerated here to avoid divergence.)
```

Authority: BC-2.11.001 (ProvenanceTag + BoundaryType), BC-2.11.002 (ToolResult boundary),
BC-2.11.003 (RAGRetrieval boundary — primary authority for rag_ingress mechanism),
BC-2.11.004 (MemoryIngress boundary), BC-2.11.005 (fail-closed), BC-2.11.006 (no-hook default).
The canonical full definition is in interface-definitions.md §GuardrailHook — that section
is the source of truth for compiler-facing types. Decision 6 mechanizes BC-2.20.002 coverage
obligation on top of the established SS-11 contract.

### Enforcement pattern

Graph nodes that inject retrieved documents into agent context accept `&GuardedDocuments`
(not `Vec<Document>` or `&[Document]`). Bypassing the guardrail is a compile-time type
error — `Vec<Document>` does not coerce to `GuardedDocuments`.

### Purity classification

- `core::guardrail` → **Pure Core** (definitions-only: `GuardrailHook` trait with
  `async fn evaluate` signature, `GuardrailResult`, `IngressContent`, `GuardrailSeverity`,
  `BoundaryType` — zero execution logic; the `async` on `evaluate` is a trait method signature
  requirement, not an indication of I/O in the trait body; `core::guardrail` contains no call sites)
- `core::retriever` → **Boundary Module** (`rag_ingress` is `async fn`: per-document routing
  gate that dispatches to the injected `&dyn GuardrailHook` implementation for each document.
  The Boundary Module classification holds regardless of the async surface — async boundary
  modules are the norm per the `memory::write_guard` + `graph::provenance` pattern; the
  pure validation logic and effectful GuardrailHook dispatch are cleanly separated.)

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
- **E-VS-004** (Decision 5): new write-time zero-norm error code minted in the `VS` namespace
  (E-VS-003 is taken — VectorStoreRetriever config validation, error-taxonomy.md);
  `add_texts` and `from_texts_sync` reject documents whose embedding has L2 norm == 0.0 before
  persistence; `document_index` carried as structured context field. `E-VS-004` minted in
  error-taxonomy v1.27/D21 (VS namespace; write-time zero-norm rejection; BC-2.21.002).
- **GuardedDocuments** (Decision 6): new newtype in `core::retriever`; no public constructor;
  sole constructor is `GuardedDocuments::rag_ingress(docs, &dyn GuardrailHook)` — `async fn`;
  iterates per-document, calling `guardrail.evaluate(IngressContent::RagChunk(...), provenance_tag).await`
  per BC-2.11.003 PC1/PC5 (N documents → N evaluate calls); honors all three GuardrailResult
  arms (Pass → include; Fail Critical → Err(E-CORE-008) aborts batch per BC-2.11.005 PC4;
  Fail non-Critical → error-entry Document substituted at position i, batch continues per
  BC-2.11.005 PC5; Transform → include deserialized replacement Document).
  Graph nodes consuming RAG output accept `&GuardedDocuments`,
  making DI-012 guardrail bypass a compile-time type error (compile_fail Red Gate / VP-2.20.002-A).
- **core::guardrail** (Decision 6): new Pure Core definitions module in ferrochain-core hosting
  the canonical `GuardrailHook` trait (`async fn evaluate` per interface-definitions.md §GuardrailHook),
  `GuardrailResult`, `IngressContent`, `GuardrailSeverity`, and `BoundaryType`; promotes from
  per-subsystem modules consistent with ADR-009 + ADR-012 trait-in-core pattern.
  `core::retriever` reclassified from Pure Core to Boundary Module (async `rag_ingress`
  routes through effectful `&dyn GuardrailHook`).
- **vectorstores::similarity** (Decision 2 + F-P129-11): new Pure Core module in
  ferrochain-vectorstores hosting the shared `cosine_similarity` primitive (called by
  `vectorstores::memory`, `vectorstores::mmr`, and future backends); VP-009 Kani P0 target.
  `vectorstores::mmr` retains Pure Core classification but no longer hosts `cosine_similarity`.

## PO Obligations

### E-VS-004 (carried from v1.3)

`E-VS-004` minted (error-taxonomy v1.27/D21) — write-time zero-norm rejection in the `VS` namespace
(`ferrochain-vectorstores`); `add_texts` and `from_texts_sync` reject documents whose
embedding has L2 norm == 0.0 before persistence; `document_index` carried as structured
context field (gate #33 Form 3 convention). BC-2.21.002 write-time contract row authority.

### BC-2.20.002 Anchor Corrections (F-P130-02 — burst-225)

BC-2.20.002 contains three occurrences of `ferrochain-guardrail` that reference a
nonexistent crate. This crate does not exist; the guardrail trait and BoundaryType enum
live in `ferrochain-core: core::guardrail` (Decision 6 of this ADR; trait-in-core
precedent per ADR-009/ADR-012).

**BC-2.20.002 v1.2 applied the following three textual corrections:**

1. **Description paragraph** (currently: "…variant in `ferrochain-guardrail` already covers
   this seam — no new variant, trait, or guardrail is introduced by this BC.")
   → Replace `` `ferrochain-guardrail` `` with `` `ferrochain-core: core::guardrail` ``.

2. **Precondition 1** (currently: "`BoundaryType::RAGRetrieval` exists in
   `ferrochain-guardrail: guardrail::boundary` (defined in BC-2.11.001).")
   → Replace `` `ferrochain-guardrail: guardrail::boundary` `` with
   `` `ferrochain-core: core::guardrail` ``.

3. **Architecture Anchors** (currently: "`architecture/purity-boundary-map.md` —
   `ferrochain-guardrail` guardrail boundary enforcement")
   → Replace `` `ferrochain-guardrail` guardrail boundary enforcement `` with
   `` `ferrochain-core: core::guardrail` guardrail boundary enforcement ``.

Additionally, **VP-2.20.002-A** references the compile_fail Red Gate mechanism —
the type it calls is `GuardedDocuments::rag_ingress` in `ferrochain-core: core::retriever`.
The compile_fail test verifies that a graph node accepting `Vec<Document>` directly
does not satisfy the required `&GuardedDocuments` parameter — unchanged by this correction.

**VP-2.20.002-B** ("guardrail failure propagates as Err without document fallback") scope
updated: this now specifically covers the Critical-severity path (Err(E-CORE-008) propagation).
Non-Critical path behavior (error-entry Document substitution) is covered by BC-2.11.005 PC5.

No BC body postconditions or test vectors need rewording — the behavioral contract is
unchanged; only the crate anchor in three prose locations is wrong.

### E-CORE-008 (F-P131-01 — burst-226)

`E-CORE-008` minted (error-taxonomy v1.30/burst-226):

| Field | Value |
|-------|-------|
| Code | E-CORE-008 |
| Namespace | CORE (ferrochain-core) |
| Category | SECURITY |
| Mnemonic | GuardrailCriticalRejection |
| Anchor BC | BC-2.20.002 (Guardrail Coverage at RAG Ingress) |
| Raise condition | `GuardedDocuments::rag_ingress` receives `GuardrailResult::Fail { severity: GuardrailSeverity::Critical, reason }` from the guardrail hook during RAGRetrieval boundary evaluation — the batch is aborted and the Err propagated to the caller (BC-2.11.005 PC4). |
| Recovery | `Never` — Critical guardrail rejection is always fatal to the RAG batch; callers must handle the Err and fail the run. |

### BC-2.20.002 PC2 (F-P131-01 — burst-226)

BC-2.20.002 PC2 currently states: "Err propagated on any `GuardrailResult::Fail`."
BC-2.20.002 v1.3 updated PC2 to reflect severity bifurcation:
- Critical Fail → Err(E-CORE-008) propagated; run transitions to `failed` state.
- Non-Critical Fail → error-entry Document substituted at document position; run continues.

### E-VS-005 (F-P131-07 — burst-226)

`E-VS-005` minted (error-taxonomy v1.30/burst-226):

| Field | Value |
|-------|-------|
| Code | E-VS-005 |
| Namespace | VS (ferrochain-vectorstores) |
| Category | VAL |
| Mnemonic | FilterUnsupported |
| Anchor BC | BC-2.21.004 (VectorStore metadata filter contract) |
| Raise condition | `VectorStore::similarity_search_with_filter` called with a non-empty `MetadataFilter` on an adapter that has not overridden the default trait implementation. The default implementation returns this error rather than silently degrading to an unfiltered search. |
| Recovery | `Never` — the caller must either use a VectorStore adapter that overrides `similarity_search_with_filter` natively, or call `similarity_search` directly if filtering is not required. |

### BC-2.21.004 INV-3 (F-P131-07 — burst-226)

BC-2.21.004 INV-3 currently documents a "lossy" fallback: "default implementation falls
back to `similarity_search` with no filtering (empty filter → all docs pass). This default
is lossy if a real filter is passed."

BC-2.21.004 v1.2 updated INV-3:
- Default implementation returns `Err(E-VS-005)` when `filter.filters` is non-empty.
- Empty filter (vacuously true, `filter.filters.is_empty()`) still delegates to
  `similarity_search` — this preserves EC-004 empty-filter semantics.
- Remove the "lossy" description. The new behavior is fail-safe, not lossy.

