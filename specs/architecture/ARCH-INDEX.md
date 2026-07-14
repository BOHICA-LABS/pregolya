---
document_type: architecture-index
level: L3
version: "1.0"
status: draft
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/STATE.md
input-hash: "202f525322e71692"
traces_to: prd.md
deployment_topology: single-service
decisions: [D4, D6, D9, D11, D13, D17]
---

# Architecture Index: ferrochain

> **Context Engineering:** Lightweight index (~300 tokens). Load only the section
> files you need. Every section targets 800-1,200 tokens with `traces_to: ARCH-INDEX.md`.

## Document Map

| Section | File | Primary Consumer | Purpose |
|---------|------|-----------------|---------|
| System Overview | system-overview.md | orchestrator, all agents | Vision, principles, crate topology, constraints |
| Module Decomposition | module-decomposition.md | story-writer, implementer | 12-crate catalog, responsibilities, wave alignment |
| Dependency Graph | dependency-graph.md | story-writer, consistency-validator | Crate DAG, topological build order |
| API Surface | api-surface.md | test-writer, implementer | Public Rust traits, ferrochain-server endpoints, Cargo features |
| Verification Architecture | verification-architecture.md | formal-verifier, architect | Provable Properties Catalog, P0/P1 VP list, proof strategy |
| Purity Boundary Map | purity-boundary-map.md | implementer, formal-verifier | Per-crate pure-core / effectful-shell classification |
| Tooling Selection | tooling-selection.md | formal-verifier | Kani, cargo-fuzz, cargo-mutants, proptest versions + config |
| Verification Coverage Matrix | verification-coverage-matrix.md | consistency-validator | VP-to-module coverage status |

**ADRs:** `.factory/specs/architecture/decisions/` — 10 stubs (ADR-001 to ADR-010)

**Module Criticality:** `.factory/specs/module-criticality.md`

## Cross-References

| If you need... | Read these together |
|----------------|-------------------|
| Implementation plan for a crate | module-decomposition.md + dependency-graph.md + api-surface.md |
| Verification plan for a module | verification-architecture.md + purity-boundary-map.md + tooling-selection.md |
| Story decomposition input | module-decomposition.md + dependency-graph.md + ARCH-INDEX.md#subsystem-registry |
| Full module picture | module-decomposition.md + purity-boundary-map.md + verification-coverage-matrix.md |

## Subsystem Registry

> **Source of truth** for subsystem names and SS-NN IDs. BC frontmatter `subsystem:`,
> BC-INDEX subsystem column, story `subsystems:`, and PRD references MUST use exact Name.
> State-manager backfills all 82 BC files with SS-NN after this index is committed.

| SS ID | Name | PRD Section | Primary Crate(s) | BCs | Wave |
|-------|------|-------------|------------------|-----|------|
| SS-01 | Core Primitives | 2.01 | ferrochain-core | BC-2.01.001–004 | 1 |
| SS-02 | StateGraph Definition | 2.02 | ferrochain-graph | BC-2.02.001–006 | 1 |
| SS-03 | BSP Execution Engine | 2.03 | ferrochain-graph | BC-2.03.001–003 | 1 |
| SS-04 | Durable Checkpointing | 2.04 | ferrochain-checkpoint | BC-2.04.001–007 | 1 |
| SS-05 | HITL Interrupt / Resume | 2.05 | ferrochain-graph | BC-2.05.001–006 | 1 |
| SS-06 | Streaming Event Taxonomy | 2.06 | ferrochain-graph, ferrochain-core | BC-2.06.001–003 | 1 |
| SS-07 | Text Splitting | 2.07 | ferrochain-splitters | BC-2.07.001–003 | 1 |
| SS-08 | Provider Conformance + Standard Tests | 2.08 | ferrochain-openai, ferrochain-anthropic, ferrochain-ollama, ferrochain-standard-tests | BC-2.08.001–008 | 2 |
| SS-09 | MCP Tool Adapter | 2.09 | ferrochain-mcp | BC-2.09.001–005 | 2 |
| SS-10 | Budget Governance | 2.10 | ferrochain-graph | BC-2.10.001–004 | 1 |
| SS-11 | Content Provenance / Guardrail | 2.11 | ferrochain-graph | BC-2.11.001–006 | 1 |
| SS-12 | Durable-Run HTTP Server | 2.12 | ferrochain-server | BC-2.12.001–007 | 1 |
| SS-13 | Sandboxed Tool Execution | 2.13 | ferrochain-sandbox | BC-2.13.001–006 | 1 |
| SS-14 | Typed Error Taxonomy | 2.14 | ferrochain-core | BC-2.14.001–006 | 1 |
| SS-15 | Long-Horizon Memory | 2.15 | ferrochain-graph | BC-2.15.001–003 | 2 |
| SS-16 | Tool Retry + Circuit Breaker | 2.16 | ferrochain-graph | BC-2.16.001–003 | 2 |
| SS-17 | Formal Verification Pipeline | 2.17 | xtask, ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox | BC-2.17.001–002 | 6 |

## ADR Registry

| ADR | Title | Status | Gate |
|-----|-------|--------|------|
| ADR-001 | Graph Execution Model | draft — BLOCKED-ON-HUMAN (D9) | D9 human gate |
| ADR-002 | Checkpoint Wire Format (msgpack) | proposed | — |
| ADR-003 | Durability Tiers | proposed | — |
| ADR-004 | Schema Generation: serde / schemars | proposed | D5 |
| ADR-005 | Logical Clock and Checkpoint Ordering | proposed | — |
| ADR-006 | Streaming Event Taxonomy | proposed | — |
| ADR-007 | Crate Topology and SDK Split | proposed | — |
| ADR-008 | Proc-Macro Attributes | proposed | D5 ADR-004 |
| ADR-009 | Budget Governance Engine Placement | proposed | — |
| ADR-010 | Error Taxonomy and anyhow Confinement | proposed | — |

## Verification Properties (VP-INDEX)

3 committed Kani VPs (D17-Q7):

| VP | BC Anchor | Module | Status |
|----|-----------|--------|--------|
| VP-001 | BC-2.03.001 (BSP determinism) | ferrochain-graph / bsp-engine | draft |
| VP-002 | BC-2.04.006 (session tenancy) | ferrochain-checkpoint / session-index | draft |
| VP-003 | BC-2.13.004 (workspace confinement) | ferrochain-sandbox / path-guard | draft |
