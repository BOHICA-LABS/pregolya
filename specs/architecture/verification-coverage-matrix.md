---
document_type: architecture-section
level: L3
section: verification-coverage-matrix
version: "1.0"
status: draft
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "23a4f9b5afbbeaf7"
traces_to: ARCH-INDEX.md
---

# Verification Coverage Matrix: ferrochain

> **VP-INDEX.md is the authoritative VP catalog.** This matrix derives from it.
> Arithmetic invariant: VP total (3) = Kani total (3). Status is updated per Phase 6 gate.

## VP-to-Module Mapping

| VP | Title | Module | Crate | Tool | BC Anchor | Phase | Status |
|----|-------|--------|-------|------|-----------|-------|--------|
| VP-001 | BSP Super-Step Determinism | bsp-engine (reducer stage) | ferrochain-graph | Kani | BC-2.03.001 | 6 | draft |
| VP-002 | Session Triple-Address Uniqueness | session-index | ferrochain-checkpoint | Kani | BC-2.04.006 | 6 | draft |
| VP-003 | Workspace Path Confinement | path-guard | ferrochain-sandbox | Kani | BC-2.13.004 | 6 | draft |

**Totals: 3 VPs | Kani: 3 | proptest: 0 | fuzz: 0 | integration: 0**

## Per-Module Coverage Status

| Module | Crate | Kani | proptest | fuzz | Integration | Notes |
|--------|-------|------|---------|------|-------------|-------|
| bsp-engine | ferrochain-graph | VP-001 | yes (BC-2.03.003) | yes (BC-2.17.002) | yes | Core VP target |
| channels | ferrochain-graph | — | yes (BC-2.02.002) | — | yes | Reducer invariants via proptest |
| hitl | ferrochain-graph | — | — | — | yes | FIFO + suspend/resume |
| scheduler | ferrochain-graph | — | — | — | yes | Pending ADR-001 |
| budget | ferrochain-graph | — | yes | — | yes | EvidenceJournal ordering |
| provenance | ferrochain-graph | — | — | — | yes | Hook dispatch |
| retry | ferrochain-graph | — | yes | — | yes | Policy termination |
| event_emitter | ferrochain-graph | — | — | — | yes | Streaming/unary equivalence |
| session-index | ferrochain-checkpoint | VP-002 | yes | — | yes | Core VP target |
| clock | ferrochain-checkpoint | — | yes | — | yes | Monotonic property |
| lineage | ferrochain-checkpoint | — | — | — | yes | Fork pointer |
| encryption | ferrochain-checkpoint | — | — | — | yes | Payload coverage |
| sqlite | ferrochain-checkpoint | — | — | yes (BC-2.17.002) | yes | Round-trip fuzz |
| path-guard | ferrochain-sandbox | VP-003 | — | — | yes | Core VP target |
| sandbox-policy | ferrochain-sandbox | — | — | — | yes | Err(PolicyNotEnforceable) |
| message | ferrochain-core | — | yes | — | yes | ContentBlock invariants |
| error | ferrochain-core | — | — | — | yes | RFC-7807 emission |
| credentials | ferrochain-core | — | — | — | yes | Redacted Debug |
| runnable | ferrochain-core | — | yes | — | yes | Pipe associativity |
| server handlers | ferrochain-server | — | — | — | yes | CRUD lifecycle |
| server security | ferrochain-server | — | — | — | yes | SecurityConfig defaults |
| recursive splitter | ferrochain-splitters | — | yes | — | yes | Code-point boundaries |
| openai | ferrochain-openai | — | — | — | yes | Conformance suite |
| anthropic | ferrochain-anthropic | — | — | — | yes | Conformance suite |
| ollama | ferrochain-ollama | — | — | — | yes | Conformance suite |
| mcp client | ferrochain-mcp | — | — | — | yes | Red Gate BCs |
| mcp adapter | ferrochain-mcp | — | — | — | yes | ToolException fidelity |

## Coverage by Criticality Tier

| Tier | Modules | Kani VPs | proptest | fuzz | Kill Rate Target |
|------|---------|---------|---------|------|-----------------|
| CRITICAL | 6 | 3 (VP-001, VP-002, VP-003) | all | subset | ≥ 95% |
| HIGH | 7 | 0 | most | subset | ≥ 90% |
| MEDIUM | 5 | 0 | some | — | ≥ 80% |
| LOW | 2 | 0 | — | — | ≥ 70% |

## Mutation Kill Rate Gates (cargo-mutants)

Kill rate gates are Phase-5 adversarial gates. Phase-3 per-story gates apply to CRITICAL modules only.

| Tier | Gate | Phase |
|------|------|-------|
| CRITICAL | ≥ 95% | Phase 3 (per story) + Phase 5 |
| HIGH | ≥ 90% | Phase 5 |
| MEDIUM | ≥ 80% | Phase 5 |
| LOW | ≥ 70% | Phase 5 advisory |
