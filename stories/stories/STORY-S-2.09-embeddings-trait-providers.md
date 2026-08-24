---
document_type: story
level: ops
story_id: S-2.09
epic_id: E-20
version: "1.1"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-22/BC-2.22.001.md
  - .factory/specs/behavioral-contracts/ss-22/BC-2.22.002.md
  - .factory/specs/behavioral-contracts/ss-22/BC-2.22.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "4494a62"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-2.06, S-1.02]
blocks: [S-2.03, S-6.01]
behavioral_contracts: [BC-2.22.001, BC-2.22.002, BC-2.22.003]
verification_properties: [VP-008]
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: [pregolya-core, pregolya-openai, pregolya-ollama]
subsystems: [SS-22]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: all 3 BCs active; BC-2.22.002 contains Red Gate (credential opacity); status = draft per Spec-First Gate S-7.01
---

# S-2.09: Embeddings Trait and Provider Implementations — OpenAI and Ollama Embeddings

## Narrative

- **As a** pregolya consumer building semantic search, RAG pipelines, and vector similarity workflows
- **I want to** have a production-grade `Embeddings` trait in `pregolya-core` with OpenAI and Ollama implementations that deliver deterministic `Vec<f32>` embeddings with proper credential opacity, batch coherence, and error propagation
- **So that** all embedding-consuming components (`VectorStore`, retrieval chains, similarity scorers) can program against a single uniform trait, credential values are never leaked through Debug output, and batch failures are surfaced as structured errors rather than silent partial results

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.22.001 | Embeddings Trait — Async, Vec<f32>, Arc<dyn Embeddings> Object-Safety | P1 |
| BC-2.22.002 | EmbeddingsOpenAI — Credential Opacity Red Gate, Model Selection, Batch Behavior | P1 |
| BC-2.22.003 | EmbeddingsOllama — Batch and Legacy Endpoint Behavior | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.22.001 PC-002)
`Embeddings::embed_documents(texts: Vec<String>) -> Result<Vec<Vec<f32>>, PregolyaError>`
returns a `Vec` with exactly `texts.len()` inner vectors — one embedding per input text.
If the provider returns fewer vectors than inputs, the adapter returns
`Err(PregolyaError { code: "E-EMBED-001", .. })`. Verified by
`test_BC_2_22_001_one_vector_per_input()`.

### AC-002 (traces to BC-2.22.001 PC-003)
`Embeddings::embed_query(text: String) -> Result<Vec<f32>, PregolyaError>` returns a
single embedding vector whose length equals the inner vector length of `embed_documents`
for the same model. Verified by `test_BC_2_22_001_embed_query_dimension_matches_documents()`.

### AC-003 (traces to BC-2.22.001 INV-002)
All inner vectors in the `embed_documents` result have the same length. If the provider
returns vectors of inconsistent length (malformed response), the adapter returns
`Err(PregolyaError { code: "E-EMBED-001", .. })`. Verified by
`test_BC_2_22_001_consistent_inner_vector_length()`.

### AC-004 (traces to BC-2.22.001 PC-002)
No partial batch fallback: if any text in the batch fails to embed, the entire call returns
`Err`. No partial `Vec` with some vectors populated and others empty is ever returned.
Verified by `test_BC_2_22_001_no_partial_batch_fallback()`.

### AC-005 (traces to BC-2.22.001 PC-001)
`Arc<dyn Embeddings>` compiles without E0038 (object safety error). The `Embeddings`
trait is object-safe: no generic methods, no `Self` return types in the dyn surface.
Verified by `test_BC_2_22_001_arc_dyn_embeddings_compiles()` (compile test).

### AC-006 (traces to BC-2.22.002 PC-004 — RED GATE)
**Red Gate:** The test `test_BC_2_22_002_openai_api_key_debug_is_redacted()` asserts that
`format!("{:?}", OpenAiApiKey("sk-test".to_string())) == "<redacted>"`. This test MUST
compile and FAIL before the `OpenAiApiKey` Debug implementation is written (the derived
Debug would emit `OpenAiApiKey("sk-test")`, not `"<redacted>"`). Once the hand-written
`impl fmt::Debug for OpenAiApiKey` returning `"<redacted>"` is in place, the test passes.
This is the Red Gate verification for BC-2.22.002.

### AC-007 (traces to BC-2.22.002 PC-003)
`EmbeddingsOpenAI::default()` uses `text-embedding-3-small` as the default model, producing
1536-dimensional vectors. Verified by `test_BC_2_22_002_default_model_is_3_small()`.

### AC-008 (traces to BC-2.22.002 PC-003)
`EmbeddingsOpenAI::new_with_model(model: OpenAiEmbeddingModel::TextEmbedding3Large)` produces
3072-dimensional vectors. Verified by `test_BC_2_22_002_large_model_produces_3072_dims()`.

### AC-009 (traces to BC-2.22.002 PC-003)
`EmbeddingsOpenAI::new_with_model(model: OpenAiEmbeddingModel::TextEmbeddingAda002)` emits:
`tracing::warn!(event_type = "embeddings.legacy_model_warning")` at construction time.
The `event_type` value `"embeddings.legacy_model_warning"` is registered in the Canonical
Structured Event Catalog per SAP-1. Verified by `test_BC_2_22_002_ada_002_emits_legacy_warning()`.

### AC-010 (traces to BC-2.22.002 PC-005)
`EmbeddingsOpenAI` uses `reqwest` with `default-features = false, features = ["rustls-tls"]`
and `.timeout(Duration::from_secs(30))`. The `native-tls` feature is absent from
`pregolya-openai/Cargo.toml`. Verified by `test_BC_2_22_002_reqwest_rustls_tls_and_30s_timeout()`.

### AC-011 (traces to BC-2.22.002 PC-006)
If the OpenAI API returns fewer embedding objects than input texts (batch partial failure),
`EmbeddingsOpenAI::embed_documents` returns `Err(PregolyaError { code: "E-EMBED-001", .. })`.
No partial result vector is returned. Verified by
`test_BC_2_22_002_batch_partial_failure_returns_err()`.

### AC-012 (traces to BC-2.22.003 PC-001)
`EmbeddingsOllama::embed_documents` uses `POST /api/embed` with the `input` field as an
array: `{ "model": "...", "input": ["text1", "text2", ...] }`. Verified by
`test_BC_2_22_003_embed_documents_uses_batch_endpoint()`.

### AC-013 (traces to BC-2.22.003 PC-002)
`EmbeddingsOllama::new_with_legacy(use_legacy_endpoint: true)` uses `POST /api/embeddings`
with serial per-text requests using the `prompt` field: `{ "model": "...", "prompt": "text" }`.
Verified by `test_BC_2_22_003_legacy_endpoint_per_text_serial()`.

### AC-014 (traces to BC-2.22.003 PC-004)
`EmbeddingsOllama` uses a 30-second timeout unconditionally — even for localhost connections.
No auto-timeout shortcut for local Ollama. Verified by
`test_BC_2_22_003_30s_timeout_unconditional()`.

### AC-015 (traces to BC-2.22.003 INV-001)
`EmbeddingsOllama` does NOT automatically fall back from `/api/embed` to `/api/embeddings`
or vice versa based on a server response. The endpoint is determined solely by the
`use_legacy_endpoint` configuration flag. Verified by
`test_BC_2_22_003_no_auto_fallback_between_endpoints()`.

### AC-016 (traces to BC-2.22.003 INV-003)
In legacy serial mode, if any per-text request fails, the entire `embed_documents` call
returns `Err`. Partial results from earlier texts are discarded. Verified by
`test_BC_2_22_003_legacy_partial_failure_returns_err()`.

### AC-017 (traces to BC-2.22.001 INV-006)
`validate_embedding_batch(texts: &[String], vecs: &[Vec<f32>]) -> Result<(), PregolyaError>`
is a public production function in `pregolya-core/src/embeddings.rs` (not test-only). All
`Embeddings` implementations (`EmbeddingsOpenAI`, `EmbeddingsOllama`) call it before returning
`Ok` from `embed_documents`. It returns `Err(PregolyaError { code: "E-EMBED-001", .. })` on:
(1) `vecs.len() != texts.len()`; (2) any inner `vecs[i].len() == 0`; (3) inconsistent inner
lengths across `vecs`. Empty input (`texts.is_empty()`) returns `Ok(())`. Verified by the
VP-008 proptest harness (5 families A–E) in `pregolya-core/src/embeddings.rs`
`#[cfg(test)] mod tests`.

## VP-008 Anchor

VP-008 is the `proptest` property test for the `Embeddings` dimensionality contract. S-2.09 is the **anchor story** for VP-008 (SS-22 owns this subsystem; this story is where the `Embeddings` trait and the shared production validator `validate_embedding_batch` are introduced).

The VP-008 proptest harness lives in `pregolya-core/src/embeddings.rs` `#[cfg(test)] mod tests` — NOT in `pregolya-standard-tests`. It tests the production `validate_embedding_batch` function directly. The `RawMockEmbeddings` mock contains NO validation logic and returns raw vectors only; each of the 5 harness families calls the PRODUCTION `validate_embedding_batch` directly:
- **VP-008-A:** random valid batch → `validate_embedding_batch` returns `Ok(())`
- **VP-008-B:** empty input → `validate_embedding_batch` returns `Ok(())`
- **VP-008-C:** ragged inner lengths → `Err(E-EMBED-001)` from production validator
- **VP-008-D:** count mismatch → `Err(E-EMBED-001)` from production validator
- **VP-008-E:** zero-length inner vector → `Err(E-EMBED-001)` from production validator

No harness tests mock internals; all assertions exercise production code.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `Embeddings` trait | `pregolya-core/src/embeddings.rs` | pure-core (trait definition only) |
| `EmbeddingsOpenAI` | `pregolya-openai/src/embeddings.rs` | effectful (reqwest HTTP) |
| `EmbeddingsOllama` | `pregolya-ollama/src/embeddings.rs` | effectful (reqwest HTTP) |
| `OpenAiEmbeddingModel` enum | `pregolya-openai/src/embeddings.rs` | pure-core (data type) |
| `validate_embedding_batch` production fn | `pregolya-core/src/embeddings.rs` | pure-core (Vec length arithmetic; no I/O/async) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `Embeddings` trait | pure-core | No I/O; only defines the async method signatures |
| `EmbeddingsOpenAI` | effectful | Issues HTTP requests to OpenAI `/v1/embeddings` endpoint |
| `EmbeddingsOllama` | effectful | Issues HTTP requests to Ollama `/api/embed` or `/api/embeddings` |
| `validate_embedding_batch` / embeddings.rs test harness | pure-core | VP-008 Kani/proptest is pure |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Empty `texts` vec passed to `embed_documents` | `Ok(vec![])` — empty input is valid; zero-length result |
| EC-002 | `OpenAiApiKey` printed with `{:?}` | Output is `"<redacted>"` — never leaks key material |
| EC-003 | Ollama legacy mode, 3 texts, 2nd fails network (connection refused before response) | `Err(PregolyaError { code: "E-PROV-012", message: "ProviderConnectionError: cannot connect to provider '<provider>': <transport_error>", .. })` — no partial result (traces to BC-2.22.003 EC-003) |
| EC-004 | Provider returns vectors of length 0 | `Err(E-EMBED-001)` — zero-dimension embeddings are invalid |
| EC-005 | `text-embedding-ada-002` model used via `EmbeddingsOpenAI` | Emits `embeddings.legacy_model_warning`; proceeds with the request |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,600 |
| BC files (3 BCs) | ~6,500 |
| `module-decomposition.md` SS-22 section | ~400 |
| `pregolya-core/src/embeddings.rs` (new) | ~500 |
| Provider embeddings files (2 files) | ~1,500 |
| Test files (~100 lines) | ~1,500 |
| VP-008 proptest harness (in `pregolya-core/src/embeddings.rs` `#[cfg(test)] mod tests`) | ~800 |
| Tool outputs | ~400 |
| **Total** | **~15,000** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~7.5%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-017, including Red Gate AC-006 (test-writer step)
2. [ ] **Red Gate check:** confirm `test_BC_2_22_002_openai_api_key_debug_is_redacted()` FAILS before implementation (stub uses derived Debug)
3. [ ] Define `Embeddings` trait in `pregolya-core/src/embeddings.rs` with `async_trait`
4. [ ] Write hand-coded `impl fmt::Debug for OpenAiApiKey` returning `"<redacted>"` (resolves Red Gate AC-006)
5. [ ] Implement `EmbeddingsOpenAI::embed_documents` — batch POST to `/v1/embeddings`
6. [ ] Implement `EmbeddingsOpenAI::embed_query` — single-text POST
7. [ ] Add `OpenAiEmbeddingModel` enum with `TextEmbedding3Small`, `TextEmbedding3Large`, `TextEmbeddingAda002`
8. [ ] Emit `tracing::warn!(event_type = "embeddings.legacy_model_warning")` for Ada-002 model
9. [ ] Register `embeddings.legacy_model_warning` in Canonical Structured Event Catalog (SAP-1)
10. [ ] Implement `EmbeddingsOllama::embed_documents` — batch `/api/embed` + legacy `/api/embeddings`
11. [ ] Implement `EmbeddingsOllama::embed_query` — single text via batch path
12. [ ] Define `pub fn validate_embedding_batch(texts: &[String], vecs: &[Vec<f32>]) -> Result<(), PregolyaError>` as a NON-test production fn in `pregolya-core/src/embeddings.rs` (per VP-008 §Proof Method + BC-2.22.001 Invariant 6): (1) Err(E-EMBED-001) if `vecs.len() != texts.len()`; (2) Ok(()) if `vecs.is_empty()`; (3) Err(E-EMBED-001) if any inner vec len == 0; (4) Err(E-EMBED-001) if any inner vec len != vecs[0].len(). All Embeddings impls (EmbeddingsOpenAI, EmbeddingsOllama) call it before returning Ok from embed_documents. Error construction per ADR-010 + error-taxonomy (E-EMBED-001).
13. [ ] Write VP-008 proptest harness (5 property families A–E) in `pregolya-core/src/embeddings.rs` `#[cfg(test)] mod tests` per VP-008 §Proof Harness Skeleton: (A) `prop_validate_embedding_batch_accepts_valid` — random (dim 1..=4096, n 1..=64) uniform batch → Ok(()); (B) `prop_validate_embedding_batch_accepts_empty` — validate_embedding_batch(&[],&[]) → Ok(()); (C) `ragged_batch_rejected_by_production_validator` — 2 texts, vecs=[768-dim,512-dim] → Err code E-EMBED-001; (D) `count_mismatch_rejected_by_production_validator` — 3 texts, 2 vecs → Err(E-EMBED-001); (E) `zero_length_vector_rejected_by_production_validator` — 2 texts, vecs=[768-dim,0-dim] → Err(E-EMBED-001). Mock `RawMockEmbeddings { dim }` contains NO validation logic — returns raw vectors only; each family calls the PRODUCTION `validate_embedding_batch` directly.
14. [ ] Run `cargo nextest run -p pregolya-core -p pregolya-openai -p pregolya-ollama` — all ACs green
15. [ ] Confirm Red Gate AC-006 passes after implementation

## Previous Story Intelligence (MANDATORY)

S-2.06 established `OpenAiApiKey` as a newtype with a placeholder or derived Debug. This story
REPLACES that Debug implementation with a hand-written redacted one (Red Gate BC-2.22.002).
The stub-architect may have left `#[derive(Debug)]` on `OpenAiApiKey` — this must be removed
and replaced with the hand-written impl.

S-1.02 established `PregolyaError` with `E-EMBED-001` (`EmbeddingDimensionMismatch`) in the
error taxonomy. Use this exact error code for dimension invariant violations and partial batch
failures. Do not invent a new code.

The `Embeddings` trait uses `async_trait` for object safety of async methods (same pattern as
other traits in `pregolya-core`). The `embed_documents` and `embed_query` methods take `&self`
not `&mut self` — implementations must not require interior mutability for the happy path.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `OpenAiApiKey` Debug impl returns `"<redacted>"` — no derived Debug | BC-2.22.002 PC-004 Red Gate | Red Gate test AC-006 |
| `embed_documents` returns exactly `texts.len()` vectors or Err | BC-2.22.001 PC-002 | Unit test AC-001 |
| No partial batch result on any failure (DI-014) | BC-2.22.001 PC-002; BC-2.22.002 PC-006 | Tests AC-004, AC-011, AC-016 |
| `Arc<dyn Embeddings>` is E0038-free | BC-2.22.001 PC-001 | Compile test AC-005 |
| `reqwest` with `rustls-tls`; `.timeout(Duration::from_secs(30))` | BC-2.22.002 PC-005; CLAUDE.md | Test AC-010; workspace dependency audit |
| No auto-fallback between Ollama endpoints | BC-2.22.003 INV-001 | Test AC-015 |
| `embeddings.legacy_model_warning` registered in Structured Event Catalog | SAP-1 | Pre-PR catalog row check |
| `validate_embedding_batch` called by all `embed_documents` impls before returning Ok | BC-2.22.001 INV-006; VP-008 §Proof Obligations | Unit/proptest — removing `validate_embedding_batch` fails VP-008-A/C/D/E |

**Forbidden dependencies:** `pregolya-core` embeddings module must NOT depend on `pregolya-openai`,
`pregolya-ollama`, `pregolya-graph`, `pregolya-mcp`, or any other implementation crate. The
`Embeddings` trait is defined in `pregolya-core` and implemented in the provider crates. A
dependency from `pregolya-core` to any provider adapter crate MUST fail the build.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `async-trait` | workspace pin | Object-safe async `Embeddings` trait |
| `reqwest` | workspace pin | HTTP client; `rustls-tls` feature; `.timeout(30s)` |
| `serde` + `serde_json` | workspace pin | Embedding request/response serialization |
| `tracing` | workspace pin | `tracing::warn!` for Ada-002 legacy warning (SAP-1) |
| `proptest` | workspace pin | VP-008 property-based tests for dimension invariant |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/embeddings.rs` | CREATE | `Embeddings` trait definition + production `validate_embedding_batch` fn + VP-008 proptest harness in `#[cfg(test)] mod tests` |
| `pregolya-openai/src/embeddings.rs` | CREATE | `EmbeddingsOpenAI`, `OpenAiEmbeddingModel`, credential Debug |
| `pregolya-ollama/src/embeddings.rs` | CREATE | `EmbeddingsOllama` batch + legacy endpoints |
| `pregolya-openai/src/lib.rs` | MODIFY | Re-export `EmbeddingsOpenAI` |
| `pregolya-ollama/src/lib.rs` | MODIFY | Re-export `EmbeddingsOllama` |

## Changelog

- **1.1 (ADR-027 M3 / 2026-08-24):** ADR-027 M3: AC traces re-cited to stable clause anchors. Mis-anchors corrected across all 17 ACs: AC-001 PC-001→PC-002 (one-per-input is in PC-002, not PC-001 which is object safety), AC-002 PC-002→PC-003 (embed_query is PC-003), AC-003 PC-003→INV-002 (consistent inner length is INV-002), AC-004 PC-004→PC-002 (no-partial-batch is in PC-002 last bullet, not PC-004 which is about dimension being model-specific), AC-005 INV-001→PC-001 (object safety is PC-001; INV-001 is one-vector-per-input), AC-006 PC-001→PC-004 (credential opacity is PC-004), AC-007 PC-002→PC-003 (model names/defaults is PC-003), AC-008 PC-003→PC-003 (direct ordinal match confirmed), AC-009 PC-004→PC-003 (ada-002 legacy warning is in PC-003, not PC-004 credential opacity), AC-010 PC-005→PC-005 (direct ordinal match confirmed), AC-011 PC-006→PC-006 (direct ordinal match confirmed), AC-012 PC-001→PC-001 (direct ordinal match confirmed), AC-013 PC-002→PC-002 (direct ordinal match confirmed), AC-014 PC-003→PC-004 (30s timeout is PC-004; PC-003 is no-API-key), AC-015 PC-004→INV-001 (no auto-fallback is INV-001), AC-016 PC-005→INV-003 (batch DI-014 legacy is INV-003; PC-005 is model validation), AC-017 INV-006→INV-006 (direct ordinal match confirmed). Architecture Compliance Rules table updated to match.
