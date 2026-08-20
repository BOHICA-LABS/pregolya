---
document_type: prd-supplement-nfr-catalog
level: L3
version: "1.7"
status: active
producer: product-owner
timestamp: 2026-07-24T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/risks.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "ea81137"
changelog:
  - "1.7 (F-P150-01/burst-251/2026-07-24): TD-VSDD-060 sweep — 14-NFR consistency audit, 2 module-map rows corrected. (1) NFR-013: 'Batch-size guard before provider call; use provider-declared max batch size' directly contradicted the requirement row (EC-002 adjudication: no pre-send cap mandated; provider-limit behavior = structured provider-error passthrough); rewritten to: provider rejection propagated as structured Err; no pre-send batch-size cap; no panic; no silent truncation; vecs.len() == texts.len() on any Ok path. (2) NFR-014: Architectural Impact was f-string-only; requirement row already mandates the engine-neutral ≤100ms bound covering both f-string and jinja2/minijinja (v1.4 changelog baked both engines into the requirement but map was not swept); extended to add jinja2/minijinja bounded-traversal obligation. 12 of 14 NFRs confirmed consistent."
  - "1.6 (F-P149-02/burst-250/2026-07-24): NFR-012 Risk Source version pin de-pinned: 'N/A — ADR-014 v1.5 §Performance Note' → 'N/A — ADR-014 Decision 2 §VectorStore trait' (TD-VSDD-091 stable-anchor enforcement, F-P149-02; ADR-014 has no §Performance Note heading — the InMemoryVectorStore O(n·d) design is documented in Decision 2 §VectorStore trait)."
  - "1.5 (burst-241/Wave-2/2026-07-23): F-P141-02 VP-gate expansion — NFR-003 expanded from 3 to 6 P0 Kani proof targets (VP-001/002/003 from D17-Q7 + VP-009 zero-norm, VP-010 allowlist, VP-011 tool-deny from D21+D23). NFR-to-Module map updated to add pregolya-vectorstores and pregolya-core for VP-009/010, and P1 targets VP-006/012/013. Success Criteria row updated to '6 P0'."
  - "1.4 (burst-227/F-P132-05+F-P132-07/2026-07-21): (1) NFR-013: Restate to conform to BC-2.22.001 EC-002 adjudication — drop E-EMBED-001 citation (wrong error code; E-EMBED-001 is EmbeddingDimensionMismatch post-response) and drop pre-send batch-size cap mandate (no BC specifies a pre-send cap; EC-002 deliberate adjudication stands). New statement: embed_documents with an over-limit batch completes deterministically — either Ok or structured Err propagating provider rejection; no panic; no silent truncation. Validation method conforms. (2) NFR-014: Add jinja2/minijinja render benchmark to Validation Method so the stated engine-neutral bound is independently verified for both engines."
  - "1.3 (burst-226/F-P131-07+F-P131-08/2026-07-21): (1) NFR-012: InMemoryVectorStore O(n·d) linear scan corpus envelope per ADR-014 v1.5. (2) NFR-013: embed_documents input-size constraint vs provider max-batch-size caps per ADR-017. (3) NFR-014: template render bounds — max template variables and slots per render call per ADR-015. (4) NFR-009 extended: add embedding call sites (pregolya-prompts not applicable; pregolya-vectorstores and pregolya-core::embeddings are new HTTP-timeout scopes for embed_documents/embed_query). (5) NFR-to-Module map updated: NFR-009 extended to pregolya-vectorstores + pregolya-core::embeddings; NFR-012/013/014 rows added."
  - "1.2 (2026-07-17, F-P89-03): Resolved pending hash recomputation from v1.1. Recomputed input-hash against current post-STATE.md-removal inputs (prd.md, risks.md, invariants.md): 2153125 → 0f05a12. The value 2153125 was the pre-v1.1 hash computed when STATE.md was still an input; v1.1 removed STATE.md but deferred the recompute. No content change — hash correction only."
  - "1.1 (2026-07-17): Provenance-integrity fix — removed .factory/STATE.md from inputs: list. STATE.md is a live pipeline-state file; input-hash drifts on every state write with zero spec-content signal for this supplement. All genuine derivation sources (prd.md, risks.md, invariants.md) are already listed and unchanged. D-NNN decision references cited inline (D17-Q7, D12, D17-Q2, D17-Q4, D17-Q8) are stable baked-in facts, not live STATE.md dependencies. Input-hash marked pending recomputation."
traces_to: prd.md
primary_consumers: [architect, performance-engineer, formal-verifier]
---

# Non-Functional Requirements Catalog: pregolya

> PRD supplement — extracted from PRD Section 4.
> NFRs are cross-cutting concerns. All have numerical targets.
> NFRs are NOT converted to BCs — they stay tabular.
> Risk Source column cites originating R-NNN from domain-spec/risks.md.

## NFR Registry

| ID | Category | Requirement | Target | Validation Method | Priority | Risk Source | BC Trace |
|----|----------|-------------|--------|------------------|----------|-------------|---------|
| NFR-001 | Performance | `Runnable::invoke` latency overhead above direct async fn call | ≤ 1ms per invocation on M1 Mac baseline hardware | Criterion benchmark: `cargo bench --bench runnable_overhead` | P0 | N/A | BC-2.01.003 |
| NFR-002 | Reliability | Tasks completed before process crash must not be lost when sync-tier checkpointing is active | 0 completed tasks lost in 100 crash-restart cycles | Chaos test: `cargo test --test crash_recovery -- --nocapture` | P0 | N/A — DI-002 (per-task durability invariant) / CONFLICT-2 | BC-2.04.001, BC-2.04.005 |
| NFR-003 | Formal Verification | All 6 P0 Kani VP obligations must pass before v1 convergence | 6/6 P0 Kani proofs: VP-001 BSP determinism (DI-001), VP-002 session tenancy (DI-005), VP-003 workspace confinement (DI-007), VP-009 zero-norm cosine guard (DI-014), VP-010 reviver allowlist containment (DI-014), VP-011 PreToolCallHook fail-closed (DI-014) | `cargo kani --harness bsp_determinism_harness && cargo kani --harness session_tenancy_harness && cargo kani --harness workspace_confinement_harness && cargo kani --harness zero_norm_guard_fail_closed && cargo kani --harness allowlist_rejects_unregistered_id && cargo kani --harness deny_excludes_tool_invocation` in Phase 6 | P0 | N/A — D17-Q7 + D21 + D23 mandate | BC-2.03.001, BC-2.04.006, BC-2.13.004, BC-2.21.003, BC-2.19.005, BC-2.05.007 |
| NFR-004 | Maintainability | Production crate source files (excluding tests) must not exceed line limits | ≤ 500 lines soft limit; ≤ 750 lines hard limit (CI fails); test files: ≤ 1,000 soft / ≤ 1,500 hard | CI: `cargo xtask check-file-size` | P0 | N/A — D12 mandate | N/A (CI policy) |
| NFR-005 | Security | `PregolyaError` and all `Debug` impls must never emit secret material | Zero occurrences of API key literal patterns in captured `{:?}` output across all error variants | Static analysis: `cargo test --test debug_redaction_audit` | P0 | N/A — DI-010 | BC-2.14.005 |
| NFR-006 | Conformance | All Wave 2 provider crates must pass pregolya-standard-tests before v1 release | 100% pass rate (0 failures) for pregolya-openai, -anthropic, -ollama across all 5 conformance categories (streaming, tool-call, structured-output, error-fidelity, token-accounting) | `cargo test -p pregolya-standard-tests -- --include-ignored` | P1 | R-003 | BC-2.08.001–005, BC-2.08.008 |
| NFR-007 | Performance | pregolya-graph single-threaded graph execution throughput | ≥ 100 nodes/second on M1 Mac for a 10-node linear graph (no IO) | Criterion benchmark: `cargo bench --bench graph_throughput` | P1 | N/A | BC-2.03.001 |
| NFR-008 | Reliability | HITL interrupt state must survive process restart; no resume values lost | 0 resume values lost in 50 interrupt-crash-restart cycles with sync-tier checkpointing | Soak test: `cargo test --test hitl_crash_recovery` | P0 | N/A — DI-003 | BC-2.05.001, BC-2.05.002 |
| NFR-009 | Security | No outbound HTTP connection may hang indefinitely | 0 `reqwest::ClientBuilder` calls without `.timeout()` in non-test code; all timed out within 30s. Applies to all outbound provider calls including `embed_documents` and `embed_query` call paths in pregolya-openai and pregolya-ollama | CI lint: `cargo xtask check-client-timeout`; integration test: timeout injection | P0 | N/A — DI-009 | BC-2.14.004, BC-2.22.002, BC-2.22.003 |
| NFR-010 | Adoptability | pregolya-core crates.io download rate | ≥ 4,000 downloads/month within 12 months of public release | Measure at 3-month, 6-month, 12-month post-launch against langchain-rust baseline | P1 | ASM-005 | N/A (launch metric) |
| NFR-011 | Correctness | BSP reducer output must be deterministic regardless of task completion order | ∀ identical graph inputs: output state is identical regardless of concurrency scheduling; zero counterexamples found by Kani in ≤ 1,000 bounds | `cargo kani --harness bsp_determinism_harness --unwind 8` | P0 | R-001 (competitor velocity) | BC-2.03.001, BC-2.03.003 |
| NFR-012 | Performance | InMemoryVectorStore cosine similarity scan must not degrade unboundedly for large corpora | ≤ 5s for a corpus of 100,000 documents with 1,536-dim embeddings (OpenAI `text-embedding-3-small` dimension) on M1 Mac baseline hardware; linear O(n·d) time complexity confirmed by benchmark | Criterion benchmark: `cargo bench --bench vectorstore_scan_100k`; complexity verified by profiling against 10k, 50k, 100k corpus sizes | P1 | N/A — ADR-014 Decision 2 §VectorStore trait | BC-2.21.002, BC-2.21.003 |
| NFR-013 | Reliability | `embed_documents` with an over-limit batch must complete deterministically — either `Ok` or a structured `Err` propagating the provider's rejection; no panic; zero silent truncation (BC-2.22.001 EC-002 adjudication: no pre-send cap is mandated; provider-limit behavior = structured provider-error passthrough) | 0 panics; 0 silent truncations; over-limit `embed_documents` returns either `Ok(vecs)` or a structured `Err`; memory bounded; `vecs.len() == texts.len()` on any `Ok` path (DI-014) | Integration test per provider: send an oversized batch; assert response is either `Ok` (if provider accepted) or a structured `Err` (if provider rejected) — never panic, never truncated-`Ok` with fewer vectors than inputs. Assert no `E-EMBED-001` dimension-mismatch is raised on an over-limit scenario (E-EMBED-001 is for vector-length inconsistency, not batch-size rejection) | P1 | N/A — ADR-017 Decision 2; BC-2.22.001 EC-002; DI-014 | BC-2.22.001 EC-002, BC-2.22.002, BC-2.22.003 |
| NFR-014 | Security | Template render must complete in bounded time regardless of variable count — engine-neutral bound applies to both f-string and jinja2 engines | `ChatPromptTemplate::format_messages` (f-string engine) and `ChatPromptTemplate::format_messages` (jinja2/minijinja engine) each complete in ≤ 100ms for a template with 500 variables across 20 slots on M1 Mac | Criterion benchmark: `cargo bench --bench template_render_500vars_fstring` (f-string engine) and `cargo bench --bench template_render_500vars_jinja2` (jinja2/minijinja engine); both must satisfy ≤ 100ms independently; no unbounded regex backtracking in either engine (f-string: linear scan; jinja2/minijinja: bounded traversal) | P1 | N/A — ADR-015 Decision 4 (engine-neutral; both f-string and jinja2 must be bounded) | BC-2.18.001, BC-2.18.004 |

## NFR Categories

| Category | Description | Validation Agent |
|----------|-------------|-----------------|
| Performance | Throughput, latency, memory consumption | performance-engineer |
| Security | Credential hygiene, sandbox enforcement, injection isolation | security-reviewer |
| Reliability | Durability, crash recovery, data integrity | formal-verifier |
| Formal Verification | Kani proofs, cargo-fuzz coverage | formal-verifier |
| Maintainability | File size limits, module coupling | code-reviewer |
| Conformance | pregolya-standard-tests pass rate | test-writer, holdout-evaluator |
| Adoptability | Download metrics (post-launch; not automated) | human |

## NFR-to-Module Mapping

| NFR ID | Primary Module(s) | Architectural Impact |
|--------|------------------|---------------------|
| NFR-001 | pregolya-core (Runnable trait) | Dispatch overhead must be zero-cost abstraction; avoid heap alloc in hot path |
| NFR-002 | pregolya-checkpoint | Sync-tier write must be synchronous before returning from put_writes |
| NFR-003 | pregolya-graph, pregolya-checkpoint, pregolya-sandbox, pregolya-vectorstores, pregolya-core | Six P0 Kani proof targets (VP-001/002/003/009/010/011); each requires a dedicated harness; three P1 targets (VP-006/012/013) hosted in pregolya-prompts, pregolya-core, pregolya-tools |
| NFR-004 | All crates | cargo xtask must enforce at CI gate; exceptions via allowlist only |
| NFR-005 | pregolya-core (credential newtypes) | All API key types must implement newtype pattern; no bare String |
| NFR-006 | pregolya-standard-tests, all provider crates | Standard-tests crate must be in CI for Wave 2 |
| NFR-007 | pregolya-graph (BSP engine) | Pre-allocated task buffers; no per-super-step heap allocation for task scheduling |
| NFR-008 | pregolya-checkpoint, pregolya-graph | HITL state must be checkpointed before returning from interrupt() |
| NFR-009 | All crates with outbound HTTP (pregolya-\<provider\>, pregolya-mcp, pregolya-server, pregolya-vectorstores where provider calls occur, pregolya-core::embeddings call sites) | Builder pattern enforces timeout; no default client construction; embedding provider calls included |
| NFR-010 | pregolya-core (published crate) | Documentation quality and README completeness affect download rate |
| NFR-011 | pregolya-graph (BSP reducer application) | Sort-then-apply reducer strategy; no fold over unordered iterator |
| NFR-012 | pregolya-vectorstores (InMemoryVectorStore) | O(n·d) linear scan — no index structure; use InMemoryVectorStore only within documented corpus size envelope |
| NFR-013 | pregolya-core::embeddings trait, pregolya-openai (EmbeddingsOpenAI), pregolya-ollama (EmbeddingsOllama) | Provider rejection propagated as structured `Err`; no pre-send batch-size cap (EC-002 adjudication); no panic; no silent truncation; `vecs.len() == texts.len()` on any `Ok` path — over-limit batches pass through to the provider and are never intercepted pre-send |
| NFR-014 | pregolya-prompts (ChatPromptTemplate::format_messages) | f-string engine: linear scan; no regex backtracking; bounded per-variable iteration. jinja2/minijinja engine: bounded traversal; no unbounded recursion or backtracking; same ≤ 100ms ceiling applies independently — both engines must satisfy the engine-neutral bound stated in the requirement row |

## Success Criteria Cross-Reference

> Maps PRD success criteria (product-brief §Success Criteria) to NFRs.

| Success Criterion | Metric | NFR |
|------------------|--------|-----|
| Community adoption | ≥ 4,000 downloads/month within 12 months | NFR-010 |
| Competitive time-to-market | pregolya-graph GA ships before competing Rust framework announces equivalent | NFR-007 (quality signal) |
| Provider conformance | 100% pregolya-standard-tests pass rate | NFR-006 |
| Holdout evaluation | Mean ≥ 0.85; critical holdout floor ≥ 0.60 | NFR-002, NFR-008 (durability for Domains A/B) |
| Formal verification | All 6 P0 VP obligations pass Kani | NFR-003, NFR-011 |
