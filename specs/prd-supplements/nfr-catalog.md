---
document_type: prd-supplement-nfr-catalog
level: L3
version: "1.2"
status: active
producer: product-owner
timestamp: 2026-07-17T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/risks.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "3f9cd20"
changelog:
  - "1.2 (2026-07-17, F-P89-03): Resolved pending hash recomputation from v1.1. Recomputed input-hash against current post-STATE.md-removal inputs (prd.md, risks.md, invariants.md): 2153125 → 0f05a12. The value 2153125 was the pre-v1.1 hash computed when STATE.md was still an input; v1.1 removed STATE.md but deferred the recompute. No content change — hash correction only."
  - "1.1 (2026-07-17): Provenance-integrity fix — removed .factory/STATE.md from inputs: list. STATE.md is a live pipeline-state file; input-hash drifts on every state write with zero spec-content signal for this supplement. All genuine derivation sources (prd.md, risks.md, invariants.md) are already listed and unchanged. D-NNN decision references cited inline (D17-Q7, D12, D17-Q2, D17-Q4, D17-Q8) are stable baked-in facts, not live STATE.md dependencies. Input-hash marked pending recomputation."
traces_to: prd.md
primary_consumers: [architect, performance-engineer, formal-verifier]
---

# Non-Functional Requirements Catalog: ferrochain

> PRD supplement — extracted from PRD Section 4.
> NFRs are cross-cutting concerns. All have numerical targets.
> NFRs are NOT converted to BCs — they stay tabular.
> Risk Source column cites originating R-NNN from domain-spec/risks.md.

## NFR Registry

| ID | Category | Requirement | Target | Validation Method | Priority | Risk Source | BC Trace |
|----|----------|-------------|--------|------------------|----------|-------------|---------|
| NFR-001 | Performance | `Runnable::invoke` latency overhead above direct async fn call | ≤ 1ms per invocation on M1 Mac baseline hardware | Criterion benchmark: `cargo bench --bench runnable_overhead` | P0 | N/A | BC-2.01.003 |
| NFR-002 | Reliability | Tasks completed before process crash must not be lost when sync-tier checkpointing is active | 0 completed tasks lost in 100 crash-restart cycles | Chaos test: `cargo test --test crash_recovery -- --nocapture` | P0 | N/A — DI-002 (per-task durability invariant) / CONFLICT-2 | BC-2.04.001, BC-2.04.005 |
| NFR-003 | Formal Verification | All 3 committed VP obligations must pass Kani harness before v1 convergence | 3/3 Kani proofs: BSP determinism (DI-001), session tenancy partition (DI-005), workspace confinement (DI-007) | `cargo kani --harness bsp_determinism_harness && cargo kani --harness session_tenancy_harness && cargo kani --harness workspace_confinement_harness` in Phase 6 | P0 | N/A — D17-Q7 mandate | BC-2.03.001, BC-2.04.006, BC-2.13.004 |
| NFR-004 | Maintainability | Production crate source files (excluding tests) must not exceed line limits | ≤ 500 lines soft limit; ≤ 750 lines hard limit (CI fails); test files: ≤ 1,000 soft / ≤ 1,500 hard | CI: `cargo xtask check-file-size` | P0 | N/A — D12 mandate | N/A (CI policy) |
| NFR-005 | Security | `FerrochainError` and all `Debug` impls must never emit secret material | Zero occurrences of API key literal patterns in captured `{:?}` output across all error variants | Static analysis: `cargo test --test debug_redaction_audit` | P0 | N/A — DI-010 | BC-2.14.005 |
| NFR-006 | Conformance | All Wave 2 provider crates must pass ferrochain-standard-tests before v1 release | 100% pass rate (0 failures) for ferrochain-openai, -anthropic, -ollama across all 5 conformance categories (streaming, tool-call, structured-output, error-fidelity, token-accounting) | `cargo test -p ferrochain-standard-tests -- --include-ignored` | P1 | R-003 | BC-2.08.001–005, BC-2.08.008 |
| NFR-007 | Performance | ferrochain-graph single-threaded graph execution throughput | ≥ 100 nodes/second on M1 Mac for a 10-node linear graph (no IO) | Criterion benchmark: `cargo bench --bench graph_throughput` | P1 | N/A | BC-2.03.001 |
| NFR-008 | Reliability | HITL interrupt state must survive process restart; no resume values lost | 0 resume values lost in 50 interrupt-crash-restart cycles with sync-tier checkpointing | Soak test: `cargo test --test hitl_crash_recovery` | P0 | N/A — DI-003 | BC-2.05.001, BC-2.05.002 |
| NFR-009 | Security | No outbound HTTP connection may hang indefinitely | 0 `reqwest::ClientBuilder` calls without `.timeout()` in non-test code; all timed out within 30s | CI lint: `cargo xtask check-client-timeout`; integration test: timeout injection | P0 | N/A — DI-009 | BC-2.14.004 |
| NFR-010 | Adoptability | ferrochain-core crates.io download rate | ≥ 4,000 downloads/month within 12 months of public release | Measure at 3-month, 6-month, 12-month post-launch against langchain-rust baseline | P1 | ASM-005 | N/A (launch metric) |
| NFR-011 | Correctness | BSP reducer output must be deterministic regardless of task completion order | ∀ identical graph inputs: output state is identical regardless of concurrency scheduling; zero counterexamples found by Kani in ≤ 1,000 bounds | `cargo kani --harness bsp_determinism_harness --unwind 8` | P0 | R-001 (competitor velocity) | BC-2.03.001, BC-2.03.003 |

## NFR Categories

| Category | Description | Validation Agent |
|----------|-------------|-----------------|
| Performance | Throughput, latency, memory consumption | performance-engineer |
| Security | Credential hygiene, sandbox enforcement, injection isolation | security-reviewer |
| Reliability | Durability, crash recovery, data integrity | formal-verifier |
| Formal Verification | Kani proofs, cargo-fuzz coverage | formal-verifier |
| Maintainability | File size limits, module coupling | code-reviewer |
| Conformance | ferrochain-standard-tests pass rate | test-writer, holdout-evaluator |
| Adoptability | Download metrics (post-launch; not automated) | human |

## NFR-to-Module Mapping

| NFR ID | Primary Module(s) | Architectural Impact |
|--------|------------------|---------------------|
| NFR-001 | ferrochain-core (Runnable trait) | Dispatch overhead must be zero-cost abstraction; avoid heap alloc in hot path |
| NFR-002 | ferrochain-checkpoint | Sync-tier write must be synchronous before returning from put_writes |
| NFR-003 | ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox | Three distinct Kani proof targets; each requires a dedicated harness |
| NFR-004 | All crates | cargo xtask must enforce at CI gate; exceptions via allowlist only |
| NFR-005 | ferrochain-core (credential newtypes) | All API key types must implement newtype pattern; no bare String |
| NFR-006 | ferrochain-standard-tests, all provider crates | Standard-tests crate must be in CI for Wave 2 |
| NFR-007 | ferrochain-graph (BSP engine) | Pre-allocated task buffers; no per-super-step heap allocation for task scheduling |
| NFR-008 | ferrochain-checkpoint, ferrochain-graph | HITL state must be checkpointed before returning from interrupt() |
| NFR-009 | All crates with outbound HTTP (ferrochain-\<provider\>, ferrochain-mcp, ferrochain-server) | Builder pattern enforces timeout; no default client construction |
| NFR-010 | ferrochain-core (published crate) | Documentation quality and README completeness affect download rate |
| NFR-011 | ferrochain-graph (BSP reducer application) | Sort-then-apply reducer strategy; no fold over unordered iterator |

## Success Criteria Cross-Reference

> Maps PRD success criteria (product-brief §Success Criteria) to NFRs.

| Success Criterion | Metric | NFR |
|------------------|--------|-----|
| Community adoption | ≥ 4,000 downloads/month within 12 months | NFR-010 |
| Competitive time-to-market | ferrochain-graph GA ships before competing Rust framework announces equivalent | NFR-007 (quality signal) |
| Provider conformance | 100% ferrochain-standard-tests pass rate | NFR-006 |
| Holdout evaluation | Mean ≥ 0.85; critical holdout floor ≥ 0.60 | NFR-002, NFR-008 (durability for Domains A/B) |
| Formal verification | All 3 VP obligations pass Kani | NFR-003, NFR-011 |
