---
document_type: story
level: ops
story_id: S-2.02
epic_id: E-16
version: "1.1"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-20/BC-2.20.001.md
  - .factory/specs/behavioral-contracts/ss-20/BC-2.20.002.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "e8a6b2e"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.19, S-1.04]
blocks: [S-2.03]
behavioral_contracts: [BC-2.20.001, BC-2.20.002]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-core
subsystems: [SS-20]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-2.02: Retriever Trait, GuardedDocuments and RAGRetrieval Guardrail Coverage

## Narrative

- **As a** pregolya graph node author performing RAG operations
- **I want to** hold `Arc<dyn Retriever>` and call `get_relevant_documents` to obtain a `Vec<Document>`, which is then gated by the `BoundaryType::RAGRetrieval` guardrail via `GuardedDocuments` before any content enters graph context
- **So that** all retrieval-augmented generation paths are provably guarded against untrusted document injection, and the type system prevents bypassing the guardrail at compile time

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.20.001 | Retriever Trait — get_relevant_documents Async Dyn-Compatible; Document Carrier Type; Arc<dyn Retriever> Graph Seam | P1 |
| BC-2.20.002 | BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns Entering Graph Context (DI-012 Coverage Obligation) | P0 |

## Acceptance Criteria

### AC-001 (traces to BC-2.20.001 PC-001)
`Arc<dyn Retriever>` compiles without E0038 for any impl with `&self` receiver and
`#[async_trait]` annotation. A compile-time test in `tests/external/retriever-dyn-compat/`
asserts this. Verified by `test_BC_2_20_001_arc_dyn_retriever_no_e0038()`.

### AC-002 (traces to BC-2.20.001 PC-002)
`Retriever::get_relevant_documents(&self, query: &str) -> Result<Vec<Document>, PregolyaError>`
returns `Ok(docs)` where `docs` is a `Vec<Document>` (possibly empty) ranked by relevance.
Verified by `test_BC_2_20_001_get_relevant_documents_ok()`.

### AC-003 (traces to BC-2.20.001 PC-003)
`Document { page_content: String, metadata: serde_json::Map<String, Value>, id: Option<String> }`
carries non-empty `page_content` for content-bearing documents. `Document` is `#[non_exhaustive]`.
Verified by `test_BC_2_20_001_document_struct_fields()` and compile-fail test for non-exhaustive.

### AC-004 (traces to BC-2.20.001 PC-004)
`Document` is `#[non_exhaustive]` — external match arms on `Document` fields require `..` wildcard.
A compile-fail test in `tests/external/document-non-exhaustive/` asserts this.
Verified by `test_BC_2_20_001_document_non_exhaustive_compile_fail()`.

### AC-005 (traces to BC-2.20.001 INV-001)
The `Retriever` trait has exactly ONE required async method (`get_relevant_documents`). No
default method implementations add I/O side effects. Verified by `test_BC_2_20_001_trait_single_required_method()`.

### AC-006 (traces to BC-2.20.001 INV-004)
The `Retriever` trait resides in `pregolya-core: core::retriever`, NOT in `pregolya-vectorstores`.
Graph crates depend only on `pregolya-core` for `Arc<dyn Retriever>`. Verified by CI dependency
graph check that `pregolya-graph` does not list `pregolya-vectorstores` in its direct deps
for the Retriever seam.

### AC-007 (traces to BC-2.20.002 PC-001)
**RED GATE**: This test must COMPILE and FAIL before any graph node wires `Arc<dyn Retriever>`.
A graph node that calls `get_relevant_documents` and attempts to pass `Vec<Document>` directly to
`inject_context(docs: &GuardedDocuments)` produces a compile-time type error. Test in
`pregolya-core/tests/external/rag-guardrail-compile-fail/`. Verified by `test_BC_2_20_002_vec_document_not_guarded_compile_fail_rg()`.

### AC-008 (traces to BC-2.20.002 PC-002)
`GuardedDocuments::rag_ingress(docs, guardrail, BoundaryType::RAGRetrieval)` with a Critical Fail
guardrail returns `Err(E-CORE-008)`. No `GuardedDocuments` is produced; the run transitions to
failed state. Verified by `test_BC_2_20_002_critical_guardrail_fail_returns_err_e_core_008()`.

### AC-009 (traces to BC-2.20.002 PC-002)
A Non-Critical guardrail Fail substitutes an error-entry Document at the rejected position
(`page_content: "[GUARDRAIL BLOCKED: <reason>]"`, `metadata.pregolya.guardrail_blocked: true`).
The batch continues; `GuardedDocuments` is produced. Verified by
`test_BC_2_20_002_non_critical_guardrail_fail_substitutes_error_entry()`.

### AC-010 (traces to BC-2.20.002 PC-003)
The guardrail call occurs BEFORE document content is used for any purpose in the graph context.
No deferred check or "check at final boundary" alternative exists. Verified by
`test_BC_2_20_002_guardrail_fires_before_content_use()` using a mock that panics if content
is read before `rag_ingress` returns.

### AC-011 (traces to BC-2.20.002 INV-003)
The coverage obligation applies to ALL Retriever implementations — custom in-memory retrievers
return externally ingested content and must be treated as a RAGRetrieval boundary. Verified by
`test_BC_2_20_002_coverage_obligation_all_retriever_impls()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `Retriever` trait | `pregolya-core/src/retriever/retriever.rs` | pure-core (trait definition; `retriever/mod.rs` is re-export-only) |
| `Document` struct | `pregolya-core/src/documents/document.rs` | pure-core (data carrier; `documents/mod.rs` is re-export-only) |
| `GuardedDocuments` typed wrapper | `pregolya-core/src/retriever/guarded.rs` | effectful (invokes guardrail async fn) |
| Compile-fail tests | `pregolya-core/tests/external/retriever-dyn-compat/`, `tests/external/document-non-exhaustive/`, `tests/external/rag-guardrail-compile-fail/` | test-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/retriever/retriever.rs` | pure-core | Trait definition only; no I/O. `retriever/mod.rs` is re-export-only. |
| `pregolya-core/src/documents/document.rs` | pure-core | Plain data carrier struct. `documents/mod.rs` is re-export-only. |
| `pregolya-core/src/retriever/guarded.rs` | effectful (invokes guardrail async fn) | GuardedDocuments::rag_ingress calls async guardrail hook. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Empty `Vec<Document>` from retriever | No guardrail call needed (no content to gate); `Vec::new()` is NOT a policy violation |
| EC-002 | Backend unavailable (network error) | `Err(PregolyaError { .. })` propagated; no Vec::new() fallback |
| EC-003 | Large result set (10,000 docs) | All 10,000 docs returned — no silent truncation at trait level |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,200 |
| BC files (2 BCs) | ~6,500 |
| `module-decomposition.md` (SS-20 section) | ~400 |
| `ADR-014-vectorstore-retriever-abstraction.md` | ~2,500 |
| Module files (~80 lines each × 3 files) | ~2,100 |
| Test files (~120 lines) | ~1,800 |
| Tool outputs | ~500 |
| **Total** | **~17,000** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~8.5%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-011 (test-writer); verify Red Gate (AC-007 must FAIL before `GuardedDocuments` wrapper is implemented)
2. [ ] Verify Red Gate density ≥ 0.5
3. [ ] Create `pregolya-core/src/documents/document.rs` — `Document` struct with `#[non_exhaustive]`; create `pregolya-core/src/documents/mod.rs` as re-export-only (`pub mod document; pub use document::Document;`)
4. [ ] Create `pregolya-core/src/retriever/retriever.rs` — `Retriever` async trait with `#[async_trait]`, single required method `get_relevant_documents`; create `pregolya-core/src/retriever/mod.rs` as re-export-only (`pub mod retriever; pub mod guarded; pub use retriever::Retriever;`)
5. [ ] Create `pregolya-core/src/retriever/guarded.rs` — `GuardedDocuments` typed wrapper; `rag_ingress()` method with Critical/Non-Critical fail semantics; `E-CORE-008` error emission
6. [ ] Add `pub mod retriever; pub mod documents;` to `pregolya-core/src/lib.rs`
7. [ ] Create compile-fail tests for dyn-compat and non-exhaustive Document; create `pregolya-core/tests/external/rag-guardrail-compile-fail/main.rs` (Red Gate: Vec<Document> not accepted where GuardedDocuments required)
8. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.19 (GuardrailHook) established `BoundaryType::RAGRetrieval` in `pregolya-core: core::guardrail`. The `GuardedDocuments::rag_ingress` method in this story calls the guardrail with exactly `BoundaryType::RAGRetrieval` — do NOT introduce a new boundary variant. S-1.19's `GuardrailHook` mechanism and `E-CORE-008 GuardrailCriticalRejection` error code are already defined; use them verbatim.

S-1.04 established `Runnable` trait. `Retriever` is a separate trait in `pregolya-core` — it does NOT extend `Runnable`. The `async-trait` crate is already in pregolya-core's dependencies from S-1.04.

The VectorStoreRetriever, SearchType, and `as_retriever` binding are delivered in S-2.03 after the VectorStore trait is defined. This story's scope is pregolya-core only: Retriever trait, Document struct, GuardedDocuments wrapper.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `Retriever` trait in `pregolya-core`, NOT `pregolya-vectorstores` | BC-2.20.001 INV-004; ADR-014 Decision 1 | Dependency graph check; no pregolya-vectorstores dep in pregolya-graph for this seam |
| `GuardedDocuments` typed wrapper prevents `Vec<Document>` as graph context input | BC-2.20.002 postcondition; ADR-014 §Decision 6 | Compile-fail test (AC-007) |
| `GuardedDocuments::rag_ingress` returns `Err(E-CORE-008)` on Critical Fail | BC-2.20.002 PC-002; ADR-014 Decision 6 | Unit test AC-008 |
| `Document` is `#[non_exhaustive]` | BC-2.20.001 PC-004 | Compile-fail test AC-004 |
| `retriever/mod.rs` and `documents/mod.rs` are re-export-only — trait and struct definitions live in named files (`retriever/retriever.rs`, `documents/document.rs`) | CLAUDE.md §Forbidden patterns (mod.rs logic rule) | Code review; `mod.rs` contains only `pub mod` and `pub use` declarations |

**Forbidden dependencies:** `pregolya-core/src/retriever/` must NOT depend on `pregolya-vectorstores`. `VectorStoreRetriever` in `pregolya-vectorstores` depends on `pregolya-core` — not vice versa.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `async-trait` | workspace pin | `#[async_trait]` for dyn-compatible async Retriever trait |
| `serde_json` | workspace pin | `serde_json::Map<String, Value>` for Document metadata |
| `tokio` | workspace pin | async runtime for `get_relevant_documents` impls |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/documents/document.rs` | CREATE | `Document` struct (`#[non_exhaustive]`, Clone, Debug, Serialize, Deserialize) |
| `pregolya-core/src/documents/mod.rs` | CREATE | Re-export only: `pub mod document; pub use document::Document;` |
| `pregolya-core/src/retriever/retriever.rs` | CREATE | `Retriever` async trait (`#[async_trait]`, `get_relevant_documents` required method) |
| `pregolya-core/src/retriever/mod.rs` | CREATE | Re-export only: `pub mod retriever; pub mod guarded; pub use retriever::Retriever;` |
| `pregolya-core/src/retriever/guarded.rs` | CREATE | `GuardedDocuments` typed wrapper; `rag_ingress()` |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod retriever; pub mod documents;` |
| `pregolya-core/tests/external/retriever-dyn-compat/main.rs` | CREATE | E0038 compile-time gate |
| `pregolya-core/tests/external/document-non-exhaustive/main.rs` | CREATE | `#[non_exhaustive]` compile-fail gate |
| `pregolya-core/tests/external/rag-guardrail-compile-fail/main.rs` | CREATE | Red Gate: Vec<Document> not accepted where GuardedDocuments required |

## Changelog

- "1.0 (2026-08-19): initial story authored"
- "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors"
