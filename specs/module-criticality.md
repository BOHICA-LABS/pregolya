---
document_type: module-criticality
level: L3
version: "1.0"
status: active
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "db400a11e5a3a521"
traces_to: ARCH-INDEX.md
lifecycle: "Mutable through Phase 5; frozen after Phase 5 gate passes."
note: "This is the architecture-view criticality. The prd-supplements/module-criticality.md is the PO draft; this file is authoritative post-Phase 1b."
---

# Module Criticality Classification: ferrochain (Architecture View)

## Tier Definitions

| Tier | Kill Rate Target | Description |
|------|-----------------|-------------|
| CRITICAL | ≥ 95% | Kani VP targets, security boundaries, durability invariants |
| HIGH | ≥ 90% | Core business logic, conformance contracts, server lifecycle |
| MEDIUM | ≥ 80% | Supporting functionality with correctness requirements |
| LOW | ≥ 70% | Build tooling, infrastructure, boilerplate |

## Module Inventory (Architecture View)

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
| sqlite backend | ferrochain-checkpoint | SS-04 | MEDIUM | — | ≥ 80% | P5 |
| recursive splitter | ferrochain-splitters | SS-07 | MEDIUM | — | ≥ 80% | P5 |
| mcp client | ferrochain-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| mcp adapter | ferrochain-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| sandbox-wasm | ferrochain-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| sandbox-policy | ferrochain-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| ferrochain-standard-tests | ferrochain-standard-tests | SS-08 | MEDIUM | — | ≥ 80% | P5 |
| retry | ferrochain-graph | SS-16 | MEDIUM | — | ≥ 80% | P5 |
| memory_seam | ferrochain-graph | SS-15 | MEDIUM | — | ≥ 80% | P5 |
| event_emitter | ferrochain-graph | SS-06 | MEDIUM | — | ≥ 80% | P5 |
| xtask | xtask | SS-17 | LOW | — | ≥ 70% | advisory |
| ferrochain-community | ferrochain-community | — | LOW | — | ≥ 70% | advisory |

## Summary

| Tier | Module Count |
|------|-------------|
| CRITICAL | 9 |
| HIGH | 10 |
| MEDIUM | 12 |
| LOW | 2 |
| **Total** | **33** |

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
