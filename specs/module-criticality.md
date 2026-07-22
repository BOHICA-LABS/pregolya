---
document_type: module-criticality
level: L3
version: "1.5"
status: active
producer: architect
timestamp: 2026-07-22T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "4634a31"
traces_to: ARCH-INDEX.md
lifecycle: "Mutable through Phase 5; frozen after Phase 5 gate passes."
note: "This is the architecture-view criticality. The prd-supplements/module-criticality.md is the PO draft; this file is authoritative post-Phase 1b."
changelog:
  - "1.5 (burst-229/2026-07-22): Input-hash cascade refresh — ARCH-INDEX.md v1.6 + module-decomposition.md v1.15 both changed in burst 229 (D23 architecture layer: ADR-018/019/020, SS-23 ferrochain-tools crate #21, Wave-1 promotions SS-15/SS-16). No content rows added (ferrochain-tools criticality rows deferred to architect D23 content authoring). Hash: ac2e35a → db6f656."
  - "1.4 (burst-224/2026-07-21): D21+burst-224 backfill — add 6 criticality rows missing since burst-223 (D21 module universe not propagated to this file). CRITICAL +2: serializable-reviver (VP-010 Kani P0 / SS-19), vectorstores-similarity (VP-009 Kani P0 / SS-21 / burst-224 final name after F-P129-11). HIGH +3: injection_guard (VP-006 Kani P1 / SS-18), serializable (VP-007 proptest P1 / SS-19), embeddings (VP-008 proptest P1 / SS-22). MEDIUM +1: vectorstores-mmr (SS-21; MMR-only after VP-009 relocated to vectorstores-similarity in burst-224). Summary 35→41. Definitions-only D21 artifacts (core::guardrail) excluded per no-row precedent (ADR-014 Decision 6 / ADR-009 Option 3). Input-hash refresh pending compute-input-hash (module-decomposition.md v1.12 changed in same burst)."
  - "1.3 (D20/CAP-021): add mcp-server MEDIUM row (+1 execution module; CAP-021 MCP server role, inbound tool-call dispatch). Summary 34→35: MEDIUM 10→11 total."
  - "1.2 (D20/ADR-012): add memory::write_guard HIGH row (+1 execution module per ADR-012 Decision 4 gate #25 ruling; write-path injection scanning enforcement, security-significant). Summary 33→34: HIGH 12→13 total. Definitions-only D20 artifacts (core::context_mutation, core::write_guard, memory::skills) excluded per no-row precedent (ADR-009 Option 3 / D18-P61-C)."
  - "1.1 (ADV-P1D-PASS-32): F-P32-04 (LOW, adjudicated) add ferrochain-macros HIGH-tier row to Module Inventory (consistent with OBS-P31-1 prd-supplements decision; orchestrator adjudication — #[tool]/#[entrypoint] affect P0 paths per ADR-008); add facade/SDK exclusion note mirroring prd-supplements/module-criticality.md. F-P32-01 (HIGH) recount all rows and rewrite Summary to match exactly (pre-fix summary was wrong: said HIGH 10 / MEDIUM 12, actual HIGH 11 / MEDIUM 10; +macros → CRITICAL 9 / HIGH 12 / MEDIUM 10 / LOW 2 = 33 total)."
---

# Module Criticality Classification: ferrochain (Architecture View)

## Tier Definitions

| Tier | Kill Rate Target | Description |
|------|-----------------|-------------|
| CRITICAL | ≥ 95% | Kani VP targets, security boundaries, durability invariants |
| HIGH | ≥ 90% | Core business logic, conformance contracts, server lifecycle |
| MEDIUM | ≥ 80% | Supporting functionality with correctness requirements |
| LOW | ≥ 70% | Build tooling, infrastructure, boilerplate |

## Module Classification

| Module | Crate | SS | Tier | VP | Kill Rate | Phase Gate |
|--------|-------|-----|------|-----|-----------|-----------|
| bsp-engine (reducer stage) | ferrochain-graph | SS-03 | CRITICAL | VP-001 | ≥ 95% | P3 per-story + P5 |
| scheduler | ferrochain-graph | SS-03 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| hitl | ferrochain-graph | SS-05 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| session-index | ferrochain-checkpoint | SS-04 | CRITICAL | VP-002 | ≥ 95% | P3 per-story + P5 |
| clock | ferrochain-checkpoint | SS-04 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| encryption | ferrochain-checkpoint | SS-04 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| path-guard | ferrochain-sandbox | SS-13 | CRITICAL | VP-003 | ≥ 95% | P3 per-story + P5 |
| credentials | ferrochain-core | SS-14 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| error | ferrochain-core | SS-14 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| channels | ferrochain-graph | SS-02 | HIGH | — | ≥ 90% | P5 |
| budget | ferrochain-graph | SS-10 | HIGH | — | ≥ 90% | P5 |
| provenance | ferrochain-graph | SS-11 | HIGH | — | ≥ 90% | P5 |
| runnable | ferrochain-core | SS-01 | HIGH | — | ≥ 90% | P5 |
| message | ferrochain-core | SS-01 | HIGH | — | ≥ 90% | P5 |
| server handlers | ferrochain-server | SS-12 | HIGH | — | ≥ 90% | P5 |
| server security | ferrochain-server | SS-12 | HIGH | — | ≥ 90% | P5 |
| openai (BaseChatModel impl) | ferrochain-openai | SS-08 | HIGH | — | ≥ 90% | P5 |
| anthropic (BaseChatModel impl) | ferrochain-anthropic | SS-08 | HIGH | — | ≥ 90% | P5 |
| ollama (BaseChatModel impl) | ferrochain-ollama | SS-08 | HIGH | — | ≥ 90% | P5 |
| lineage | ferrochain-checkpoint | SS-04 | HIGH | — | ≥ 90% | P5 |
| ferrochain-macros (#[tool], #[entrypoint]) | ferrochain-macros | — | HIGH | — | ≥ 90% | P5 |
| write-guard enforcement | ferrochain-memory | SS-15 | HIGH | — | ≥ 90% | P5 |
| sqlite backend | ferrochain-checkpoint | SS-04 | MEDIUM | — | ≥ 80% | P5 |
| recursive splitter | ferrochain-splitters | SS-07 | MEDIUM | — | ≥ 80% | P5 |
| mcp client | ferrochain-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| mcp adapter | ferrochain-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| mcp server | ferrochain-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| sandbox-wasm | ferrochain-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| sandbox-policy | ferrochain-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| ferrochain-standard-tests | ferrochain-standard-tests | SS-08 | MEDIUM | — | ≥ 80% | P5 |
| retry | ferrochain-core | SS-16 | MEDIUM | — | ≥ 80% | P5 |
| memory-store (MemoryStore) | ferrochain-memory | SS-15 | MEDIUM | — | ≥ 80% | P5 |
| event_emitter | ferrochain-graph | SS-06 | MEDIUM | — | ≥ 80% | P5 |
| xtask | xtask | SS-17 | LOW | — | ≥ 70% | advisory |
| ferrochain-community | ferrochain-community | — | LOW | — | ≥ 70% | advisory |
| serializable-reviver | ferrochain-core | SS-19 | CRITICAL | VP-010 | ≥ 95% | P3 per-story + P5 |
| vectorstores-similarity | ferrochain-vectorstores | SS-21 | CRITICAL | VP-009 | ≥ 95% | P3 per-story + P5 |
| injection_guard | ferrochain-prompts | SS-18 | HIGH | VP-006 | ≥ 90% | P3 per-story + P5 |
| serializable | ferrochain-core | SS-19 | HIGH | VP-007 | ≥ 90% | P5 |
| embeddings | ferrochain-core | SS-22 | HIGH | VP-008 | ≥ 90% | P5 |
| vectorstores-mmr | ferrochain-vectorstores | SS-21 | MEDIUM | — | ≥ 80% | P5 |

> **D21+burst-224 additions (v1.4):** serializable-reviver and vectorstores-similarity added as CRITICAL (Kani P0 proof obligations VP-010 and VP-009 respectively). injection_guard, serializable, embeddings added as HIGH (Kani P1 and proptest P1 proof obligations VP-006/007/008). vectorstores-mmr added as MEDIUM (MMR-only selection algorithm; VP-009 relocated to vectorstores-similarity by F-P129-11 in burst-224). Definitions-only D21 artifacts (core::guardrail per ADR-014 Decision 6) excluded per no-row precedent.

> **Exclusion criteria (F-P32-04, ADV-P1D-PASS-32):** Facade/re-export and codegen-thin
> crates (`ferrochain` #1, `ferrochain-openai-sdk` #16, `ferrochain-anthropic-sdk` #17,
> `ferrochain-ollama-sdk` #18) carry no criticality-bearing modules of their own and are
> intentionally excluded from this inventory — they re-export from the implementation crates
> listed above and contain no independent logic paths. `xtask` is classified because its
> file-size-check and CI-lint logic gates all merges (SS-17). `ferrochain-macros` is NOT
> excluded: `#[tool]` generates ToolDefinition plumbing for all P0 tool-calling paths
> (BC-2.09.001, BC-2.09.002) and `#[entrypoint]` gates graph composition entry points;
> incorrect macro expansion silently corrupts P0 execution without a clear runtime error.
> DECISION: `ferrochain-macros` receives a HIGH-tier row. Consistent with OBS-P31-1
> (prd-supplements/module-criticality.md) and orchestrator adjudication in ADV-P1D-PASS-32.
> `ferrochain-community` retains a LOW row as a placeholder for post-v1 third-party
> contributions; it is not in-tree at v1.

## Classification Summary

| Tier | Module Count |
|------|-------------|
| CRITICAL | 11 |
| HIGH | 16 |
| MEDIUM | 12 |
| LOW | 2 |
| **Total** | **41** |

## CRITICAL Module — Security Profile

| Module | Blast Radius | Security Sensitivity | VP |
|--------|-------------|---------------------|----|
| bsp-engine | all graph runs | low (correctness) | VP-001 |
| scheduler | all graph runs | low (correctness) | — |
| hitl | all HITL scenarios | medium (auth gates in Domain A) | — |
| session-index | multi-tenant isolation | HIGH (cross-tenant data leak) | VP-002 |
| clock | all durable runs | medium (ordering) | — |
| encryption | all checkpoint state | HIGH (data at rest) | — |
| path-guard | all tool execution | HIGH (path traversal, Domain C) | VP-003 |
| credentials | error observability | HIGH (credential leak) | — |
| error | API contract | HIGH (leaks in Debug output) | — |
| serializable-reviver | all lc-JSON deserialization paths | HIGH (unknown type deserialization bypasses allowlist → arbitrary constructor execution) | VP-010 |
| vectorstores-similarity | all similarity/MMR search paths | MEDIUM (IEEE-754 NaN corruption of ranking; data integrity, not direct auth bypass) | VP-009 |

## Anti-Patterns Enforced by Architecture (NE Catalog)

All 17 NE patterns from COMPARATIVE-ASSESSMENT are anchored. Architecture-specific enforcements:

| NE | Module | Enforcement Mechanism |
|----|--------|-----------------------|
| NE-01 | sandbox-policy | Enforcing backend default; `Err(PolicyNotEnforceable)` on mismatch |
| NE-02 | path-guard | `canonicalize_beneath_root` mandatory; VP-003 Kani proof |
| NE-04 | all provider + mcp modules | `cargo xtask deny-client-new` CI gate |
| NE-07 | all crates | `cargo xtask deny-expect-in-lib` CI gate |
| NE-10 | credentials module | Newtype enforcement; `cargo xtask` custom lint |
| NE-12 | session-index | Triple-address composite key; VP-002 Kani proof |
| NE-13 | server::streaming | Same engine for streaming + unary; SSE tap only |
| NE-14 | server::security | `SecurityConfig::default()` deny-CORS; debug route opt-in |
| NE-17 | bsp-engine | Task-identity sort + VP-001 Kani proof |
