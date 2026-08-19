---
document_type: story
level: ops
story_id: S-2.03
epic_id: E-21
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-21/BC-2.21.001.md
  - .factory/specs/behavioral-contracts/ss-21/BC-2.21.002.md
  - .factory/specs/behavioral-contracts/ss-21/BC-2.21.003.md
  - .factory/specs/behavioral-contracts/ss-21/BC-2.21.004.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "a561511"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-2.02, S-1.04]
blocks: [S-6.01]
behavioral_contracts: [BC-2.21.001, BC-2.21.002, BC-2.21.003, BC-2.21.004]
verification_properties: [VP-009]
priority: P0
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-vectorstores
subsystems: [SS-21]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-2.03: VectorStore Trait, InMemoryVectorStore, Zero-Norm Guard, and MetadataFilter

## Narrative

- **As a** pregolya library user building RAG pipelines
- **I want to** interact with vector stores through `Arc<dyn VectorStore>`, backed by an `InMemoryVectorStore` that uses `Arc<dyn Embeddings>` for document embedding and Vec<f32> cosine similarity
- **So that** I can develop and test vector search logic locally without an external service, with a zero-norm guard that provably never produces NaN cosine similarity, and a `MetadataFilter` contract that prevents partial filter-unsupported implementations from silently returning wrong results

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.21.001 | VectorStore Trait — Core Methods, `&self` Receivers, Async Dyn-Compatible; VectorStoreFactory Sized-Bound Split | P1 |
| BC-2.21.002 | InMemoryVectorStore — Arc<dyn Embeddings> DI, RwLock Storage, Vec<f32> Cosine Similarity | P1 |
| BC-2.21.003 | InMemoryVectorStore Cosine Similarity Zero-Norm Guard: norm == 0.0 OR !norm.is_finite() → E-VS-001; VP-009 Kani P0 Proof | P0 |
| BC-2.21.004 | MetadataFilter — FilterClause::Eq / Ne / In #[non_exhaustive]; Default similarity_search_with_filter Impl Returns Err(E-VS-005) on Non-Empty Filter | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.21.001 postcondition 1)
`Arc<dyn VectorStore>` compiles without E0038 for all core methods (`add_documents`,
`similarity_search`, `similarity_search_with_score`, `delete`). These methods use `&self`
receivers with `#[async_trait]`. Compile-time gate in `tests/external/vectorstore-dyn-compat/`.
Verified by `test_BC_2_21_001_arc_dyn_vectorstore_no_e0038()`.

### AC-002 (traces to BC-2.21.001 postcondition 2)
`VectorStore::add_documents(&self, docs: Vec<Document>) -> Result<Vec<String>, PregolyaError>`
inserts documents and returns assigned IDs in input order. An empty batch returns `Ok(vec![])`.
Verified by `test_BC_2_21_001_add_documents_returns_ids()`.

### AC-003 (traces to BC-2.21.001 postcondition 3)
`VectorStore::similarity_search(&self, query: &str, k: usize) -> Result<Vec<Document>, PregolyaError>`
returns at most `k` documents ranked by decreasing similarity. Fewer than `k` docs when store has
fewer. Verified by `test_BC_2_21_001_similarity_search_at_most_k()`.

### AC-004 (traces to BC-2.21.001 postcondition 4)
`VectorStore::similarity_search_with_score` returns `Vec<(Document, f32)>` with scores in
`[-1.0, 1.0]`. Verified by `test_BC_2_21_001_similarity_search_score_range()`.

### AC-005 (traces to BC-2.21.001 postcondition 5)
`VectorStoreFactory` is a separate trait with a `Sized` bound for methods that are not
object-safe (e.g., `from_texts`). `VectorStoreFactory: Sized` ensures E0038 is impossible
on `VectorStore`. The split is compile-time verified.
Verified by `test_BC_2_21_001_vectorstore_factory_sized_split()`.

### AC-006 (traces to BC-2.21.001 postcondition 6)
`VectorStore::delete(&self, ids: &[String]) -> Result<(), PregolyaError>` removes documents
by ID. Deleting non-existent IDs is a no-op (returns `Ok(())`). Verified by
`test_BC_2_21_001_delete_nonexistent_noop()`.

### AC-007 (traces to BC-2.21.002 postcondition 1)
`InMemoryVectorStore::new(embeddings: Arc<dyn Embeddings>) -> Self` stores the Arc without
taking ownership. No `Arc<dyn Embeddings>` placeholder construction — requires a real injected
Arc. Verified by `test_BC_2_21_002_new_arc_embeddings_di()`.

### AC-008 (traces to BC-2.21.002 postcondition 2)
`InMemoryVectorStore` stores documents as `RwLock<Vec<(Document, Vec<f32>)>>`. Multiple
concurrent readers can access the store simultaneously; a single writer holds exclusive access.
Verified by `test_BC_2_21_002_rwlock_concurrent_read()`.

### AC-009 (traces to BC-2.21.002 postcondition 3)
`add_documents` embeds each document by calling `embeddings.embed_documents(&texts).await`
(batch call, NOT one-by-one) and stores `(doc, embedding)` pairs. Verified by
`test_BC_2_21_002_add_documents_uses_batch_embed()`.

### AC-010 (traces to BC-2.21.002 postcondition 4)
Cosine similarity between two identical non-zero vectors is 1.0. Between two orthogonal
non-zero vectors the cosine is 0.0. No ndarray dependency — pure Vec<f32> dot product.
Verified by `test_BC_2_21_002_cosine_similarity_values()`.

### AC-011 (traces to BC-2.21.003 precondition 1 — Red Gate)
**RED GATE**: This test must COMPILE and FAIL before the zero-norm guard is implemented.
An embedding vector `[0.0_f32, 0.0, 0.0]` (all-zero) would produce `norm == 0.0` and
would divide-by-zero, yielding NaN. Test asserts `cosine_similarity([0.0, 0.0], ...)` returns
`Err(E-VS-001)` — fails as Red Gate because the guard is not yet implemented.
Verified by `test_BC_2_21_003_zero_norm_returns_err_e_vs_001_rg()`.

### AC-012 (traces to BC-2.21.003 postcondition 1)
The zero-norm guard condition is `if norm == 0.0 || !norm.is_finite()`. This covers:
- All-zero vector (`norm == 0.0`)
- Overflow-to-infinity (`norm.is_finite()` is false when components are very large)
Any guard that uses only `norm == 0.0` is INCOMPLETE — it misses the infinity case.
Verified by `test_BC_2_21_003_guard_covers_infinity_overflow()`.

### AC-013 (traces to BC-2.21.003 postcondition 2)
When the guard fires, the error is:
`Err(PregolyaError::new(Component::Vs, Category::Val, RetryHint::Never, "E-VS-001",
"degenerate-norm embedding vector: norm is zero or non-finite"))`.
The message is STATIC — no variable values interpolated.
Verified by `test_BC_2_21_003_e_vs_001_static_message()`.

### AC-014 (traces to BC-2.21.003 postcondition 3 — VP-009 Kani anchor)
`cosine_similarity` never returns `f32::NAN` for any finite input combination when the
zero-norm guard is in place. VP-009 (Kani P0) provides formal proof. Unit test:
`test_BC_2_21_003_cosine_never_nan_for_finite_inputs()` verifies the property with
a proptest sweep over randomly generated non-zero vectors.
This story is the ANCHOR story for VP-009.

### AC-015 (traces to BC-2.21.003 invariant 1)
The zero-norm guard fires at the cosine similarity computation site. It is NOT deferred
to the caller. An `InMemoryVectorStore::similarity_search` call with a degenerate query
embedding propagates `Err(E-VS-001)` upward.
Verified by `test_BC_2_21_003_degenerate_query_propagates_err()`.

### AC-016 (traces to BC-2.21.004 postcondition 1)
`MetadataFilter { filters: Vec<FilterClause> }` is `#[non_exhaustive]`. `FilterClause`
has variants `Eq`, `Ne`, `In`, each carrying a field key and value(s). Both types are
`#[non_exhaustive]`. Compile-fail tests confirm external exhaustive matches fail.
Verified by `test_BC_2_21_004_filter_non_exhaustive_compile_fail()`.

### AC-017 (traces to BC-2.21.004 postcondition 2)
`VectorStore::similarity_search_with_filter` default implementation: if
`filter.filters.is_empty()` delegates to `similarity_search`; if filter is non-empty returns
`Err(PregolyaError { code: "E-VS-005", message: "FilterUnsupported: this store does not support metadata filtering", .. })`.
Verified by `test_BC_2_21_004_default_filter_impl_returns_err_e_vs_005()`.

### AC-018 (traces to BC-2.21.004 invariant 1)
The fail-safe default prevents returning incorrect results when a concrete store does NOT
override `similarity_search_with_filter`. This is NOT a silent empty-return — it must be
`Err(E-VS-005)`, never `Ok(vec![])`. Verified by
`test_BC_2_21_004_no_silent_empty_return_on_unsupported_filter()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `VectorStore` trait + `VectorStoreFactory` trait | `pregolya-vectorstores/src/store/mod.rs` | pure-core (trait definitions) |
| `InMemoryVectorStore` impl | `pregolya-vectorstores/src/store/in_memory.rs` | effectful (calls async Embeddings) |
| `MetadataFilter` + `FilterClause` | `pregolya-vectorstores/src/filter.rs` | pure-core |
| `cosine_similarity` fn | `pregolya-vectorstores/src/store/cosine.rs` | pure-core (pure math, no I/O) |
| Compile-fail tests | `pregolya-vectorstores/tests/external/vectorstore-dyn-compat/`, `tests/external/filter-non-exhaustive/` | test-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-vectorstores/src/store/mod.rs` | pure-core | Trait definitions only. |
| `pregolya-vectorstores/src/store/cosine.rs` | pure-core | Pure math; no I/O. Zero-norm guard is a pure conditional. |
| `pregolya-vectorstores/src/filter.rs` | pure-core | Data types only. |
| `pregolya-vectorstores/src/store/in_memory.rs` | effectful | Calls `embeddings.embed_documents().await`. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Empty store, `similarity_search(q, 5)` | Returns `Ok(vec![])` — no error, empty result |
| EC-002 | Query embedding is all-zero | `Err(E-VS-001)` — zero-norm guard fires on query |
| EC-003 | Stored embedding is all-zero (degenerate stored doc) | `Err(E-VS-001)` — zero-norm guard fires on stored vector during scoring |
| EC-004 | Very large vector components cause infinity norm | `Err(E-VS-001)` — `!norm.is_finite()` arm fires |
| EC-005 | `add_documents` with `embed_documents` returning `Err` | `Err(PregolyaError)` propagated; no partial state written to store |
| EC-006 | `similarity_search_with_filter` with empty filter | Delegates to `similarity_search` — no error |
| EC-007 | `similarity_search_with_filter` with non-empty filter on default impl | `Err(E-VS-005)` — fail-safe |
| EC-008 | `delete` with empty slice | `Ok(())` immediately — no lock contention |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~4,800 |
| BC files (4 BCs) | ~12,000 |
| `module-decomposition.md` (SS-21 section) | ~400 |
| ADR for vectorstore abstraction | ~2,000 |
| Module files (~100 lines each × 4 files) | ~3,600 |
| Test files (~150 lines) | ~2,200 |
| VP-009 kani harness spec (~50 lines) | ~700 |
| Tool outputs | ~500 |
| **Total** | **~26,200** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~13%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-018 (test-writer); verify Red Gate (AC-011 must FAIL before zero-norm guard implemented)
2. [ ] Verify Red Gate density ≥ 0.5
3. [ ] Create `pregolya-vectorstores/src/store/mod.rs` — `VectorStore` async trait (`&self` receivers, `#[async_trait]`), `VectorStoreFactory` with `Sized` bound; default `similarity_search_with_filter`
4. [ ] Create `pregolya-vectorstores/src/store/cosine.rs` — `cosine_similarity(a: &[f32], b: &[f32]) -> Result<f32, PregolyaError>` with zero-norm guard `if norm == 0.0 || !norm.is_finite()`
5. [ ] Create `pregolya-vectorstores/src/store/in_memory.rs` — `InMemoryVectorStore`, `Arc<dyn Embeddings>` DI constructor, `RwLock<Vec<(Document, Vec<f32>)>>` storage, batch embed on `add_documents`
6. [ ] Create `pregolya-vectorstores/src/filter.rs` — `MetadataFilter` and `FilterClause` (both `#[non_exhaustive]`)
7. [ ] Register `E-VS-001` (`Component::Vs, Category::Val, RetryHint::Never`) and `E-VS-005` in error taxonomy
8. [ ] Update `pregolya-vectorstores/src/lib.rs` — `pub mod store; pub mod filter;`
9. [ ] Create compile-fail tests for VectorStore dyn-compat, VectorStoreFactory Sized split, and MetadataFilter/FilterClause non-exhaustive
10. [ ] Write VP-009 Kani harness stub in `pregolya-vectorstores/src/proofs/` for Phase 6 formal hardening
11. [ ] Run `cargo nextest run -p pregolya-vectorstores` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-2.02 established `Arc<dyn Retriever>`, `Document`, and `GuardedDocuments` in `pregolya-core`. This story creates `VectorStore` in `pregolya-vectorstores`. `VectorStoreRetriever` (from S-2.02's `pregolya-vectorstores/src/retriever.rs`) calls the `VectorStore` methods defined in this story — the trait contract for `similarity_search` etc. is now defined here; S-2.02 stubbed the `VectorStore` reference forward.

S-1.04 established `Runnable` trait. `VectorStore` is NOT a `Runnable` — do not add `pipe` or `invoke` to it. `Embeddings` trait is defined elsewhere (likely S-1.XX, SS-14 or similar); `Arc<dyn Embeddings>` is a dependency. If `Embeddings` is not yet available, create a minimal stub trait in `pregolya-vectorstores` or `pregolya-core` for compilation.

The zero-norm guard `if norm == 0.0 || !norm.is_finite()` is EXACT — both conditions required. The prior art in the CLIP workstream showed that `norm == 0.0`-only guards passed review but missed the infinity overflow path, discovered only in a follow-on adversarial pass. This two-condition form closes that gap.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `VectorStore` trait uses `&self` receivers only (dyn-compatible, not `&mut self`) | BC-2.21.001 invariant 1; ADR-014 Decision 3 | Compile-time E0038 check |
| `VectorStoreFactory` has `Sized` bound — E0038-safe split | BC-2.21.001 postcondition 5 | Compile-fail test |
| Zero-norm guard condition is `norm == 0.0 || !norm.is_finite()` (both arms required) | BC-2.21.003 postcondition 1 | Code review; VP-009 Kani proof |
| No ndarray dependency — Vec<f32> cosine only | BC-2.21.002 postcondition 4 | Cargo.toml inspection; deny ndarray |
| `Arc<dyn Embeddings>` DI at constructor (no placeholder) | BC-2.21.002 postcondition 1; CLAUDE.md Arc-DI rule | Code review; no `Arc::new(Embeddings::placeholder())` |
| Default `similarity_search_with_filter` returns `Err(E-VS-005)` on non-empty filter — NOT `Ok(vec![])` | BC-2.21.004 invariant 1 | Unit test AC-018 |
| E-VS-001 message is STATIC — no variable interpolation | BC-2.21.003 postcondition 2 | String equality test |

**Forbidden dependencies:** `pregolya-vectorstores/src/store/cosine.rs` must NOT depend on `ndarray`, `nalgebra`, or any external linear-algebra crate. `pregolya-vectorstores` must NOT depend on `pregolya-graph`.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `async-trait` | workspace pin | `#[async_trait]` for dyn-compatible VectorStore trait |
| `tokio` | workspace pin | `RwLock` + async methods in InMemoryVectorStore |
| `serde_json` | workspace pin | Document metadata (`Map<String, Value>`); FilterClause values |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-vectorstores/src/store/mod.rs` | CREATE | `VectorStore` async trait + `VectorStoreFactory` |
| `pregolya-vectorstores/src/store/cosine.rs` | CREATE | `cosine_similarity` with zero-norm guard |
| `pregolya-vectorstores/src/store/in_memory.rs` | CREATE | `InMemoryVectorStore` |
| `pregolya-vectorstores/src/filter.rs` | CREATE | `MetadataFilter` + `FilterClause` |
| `pregolya-vectorstores/src/lib.rs` | MODIFY | Add `pub mod store; pub mod filter;` |
| `pregolya-vectorstores/src/proofs/zero_norm.rs` | CREATE | VP-009 Kani harness stub (Phase 6 target) |
| `pregolya-vectorstores/tests/external/vectorstore-dyn-compat/main.rs` | CREATE | E0038 compile-time gate |
| `pregolya-vectorstores/tests/external/filter-non-exhaustive/main.rs` | CREATE | MetadataFilter/FilterClause non-exhaustive compile-fail gate |
