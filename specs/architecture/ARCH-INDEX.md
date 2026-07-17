---
document_type: architecture-index
level: L3
version: "1.4"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/module-criticality.md
input-hash: "065003c"
traces_to: prd.md
deployment_topology: single-service
decisions: [D4, D6, D9, D11, D13, D17, D20]
changelog:
  - "1.2 (D20/CAP-021+CAP-020): SS-09 BC range 001–005→001–007 (CAP-021 MCP server role); SS-15 BC range 001–003→001–006 (CAP-020 self-improvement primitives); SS-04 001–007→001–008; SS-08 001–012→001–014; SS-13 001–006→001–007; BC total 86→95."
  - "1.3 (F-P72-04/ADR-013): add ADR-013 (mcp::server module placement) to ADR registry; update SS-09 D20 capability note to attribute mcp::server to ADR-013 (not ADR-012); ADR count 12→13."
  - "1.4 (provenance-fix-169/2026-07-17): remove .factory/STATE.md from inputs (not a genuine spec-content input; D-NNN decisions are baked-in stable facts per PO corpus adjudication)."
---

# Architecture Index: ferrochain

> **Context Engineering:** Lightweight index (~300 tokens). Load only the section
> files you need. Every section targets 800-1,200 tokens with `traces_to: ARCH-INDEX.md`.

## Document Map

| Section | File | Primary Consumer | Purpose |
|---------|------|-----------------|---------|
| System Overview | system-overview.md | orchestrator, all agents | Vision, principles, crate topology, constraints |
| Module Decomposition | module-decomposition.md | story-writer, implementer | 18-crate catalog, responsibilities, wave alignment |
| Dependency Graph | dependency-graph.md | story-writer, consistency-validator | Crate DAG, topological build order |
| API Surface | api-surface.md | test-writer, implementer | Public Rust traits, ferrochain-server endpoints, Cargo features |
| Verification Architecture | verification-architecture.md | formal-verifier, architect | Provable Properties Catalog, P0/P1 VP list, proof strategy |
| Purity Boundary Map | purity-boundary-map.md | implementer, formal-verifier | Per-crate pure-core / effectful-shell classification |
| Tooling Selection | tooling-selection.md | formal-verifier | Kani, cargo-fuzz, cargo-mutants, proptest versions + config |
| Verification Coverage Matrix | verification-coverage-matrix.md | consistency-validator | VP-to-module coverage status |

**ADRs:** `.factory/specs/architecture/decisions/` — 13 files (ADR-001 to ADR-013)

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
> State-manager backfills all 95 BC files with SS-NN after this index is committed.

| SS ID | Name | PRD Section | Primary Crate(s) | BCs | Wave |
|-------|------|-------------|------------------|-----|------|
| SS-01 | Core Primitives | 2.01 | ferrochain-core | BC-2.01.001–004 | 1 |
| SS-02 | StateGraph Definition | 2.02 | ferrochain-graph | BC-2.02.001–006 | 1 |
| SS-03 | BSP Execution Engine | 2.03 | ferrochain-graph | BC-2.03.001–003 | 1 |
| SS-04 | Durable Checkpointing | 2.04 | ferrochain-checkpoint | BC-2.04.001–008 | 1 |
| SS-05 | HITL Interrupt / Resume | 2.05 | ferrochain-graph | BC-2.05.001–006 | 1 |
| SS-06 | Streaming Event Taxonomy | 2.06 | ferrochain-graph, ferrochain-core | BC-2.06.001–003 | 1 |
| SS-07 | Text Splitting | 2.07 | ferrochain-splitters | BC-2.07.001–003 | 1 |
| SS-08 | Provider Conformance + Standard Tests | 2.08 | ferrochain-openai, ferrochain-anthropic, ferrochain-ollama, ferrochain-standard-tests | BC-2.08.001–014 | 2 |
| SS-09 | MCP Tool Adapter | 2.09 | ferrochain-mcp | BC-2.09.001–007 | 2 |
| SS-10 | Budget Governance | 2.10 | ferrochain-graph | BC-2.10.001–004 | 1 |
| SS-11 | Content Provenance / Guardrail | 2.11 | ferrochain-graph | BC-2.11.001–006 | 1 |
| SS-12 | Durable-Run HTTP Server | 2.12 | ferrochain-server | BC-2.12.001–007 | 1 |
| SS-13 | Sandboxed Tool Execution | 2.13 | ferrochain-sandbox | BC-2.13.001–007 | 1 |
| SS-14 | Typed Error Taxonomy | 2.14 | ferrochain-core | BC-2.14.001–006 | 1 |
| SS-15 | Long-Horizon Memory | 2.15 | ferrochain-memory | BC-2.15.001–006 | 2 |
| SS-16 | Tool Retry + Circuit Breaker | 2.16 | ferrochain-core | BC-2.16.001–003 | 2 |
| SS-17 | Formal Verification Pipeline | 2.17 | xtask, ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox | BC-2.17.001–002 | 6 |

> **D20 Capability Additions (v1.2):** SS-09 adds CAP-021 (MCP server role) per ADR-013 — introduces `mcp::server` execution module in ferrochain-mcp; BC range extended from 001–005 to 001–007. SS-15 adds CAP-020 (self-improvement primitives) per ADR-012 — includes `SkillStore`, `MemoryWriteGuard` execution modules and `ContextMutationConfig` definitions; BC range extended from 001–003 to 001–006.

## Canonical Crate Roster (Source of Truth)

> **Authoritative.** All other documents (ADR-007, system-overview, dependency-graph) derive
> from this table. Derivation: D6 base (9) + D1 (mcp, standard-tests) + D13 (server)
> + P2-05 (sandbox, memory) + ADR-008 (macros) + D17-Q5 (3 × -sdk) = **18 published crates**.

| # | Crate | Origin | Wave | Published |
|---|-------|--------|------|-----------|
| 1 | ferrochain | D6 | facade | YES |
| 2 | ferrochain-core | D6 | 1 | YES |
| 3 | ferrochain-graph | D6 | 1 | YES |
| 4 | ferrochain-checkpoint | D6 | 1 | YES |
| 5 | ferrochain-openai | D6+D17-Q5 | 2 | YES |
| 6 | ferrochain-anthropic | D6+D17-Q5 | 2 | YES |
| 7 | ferrochain-ollama | D6+D17-Q5 | 2 | YES |
| 8 | ferrochain-community | D6 | post-v1 | YES (post-v1) |
| 9 | ferrochain-splitters | D6 | 1 | YES |
| 10 | ferrochain-mcp | D1 | 2 | YES |
| 11 | ferrochain-standard-tests | D1 | 2 | YES |
| 12 | ferrochain-server | D13 | 1 | YES |
| 13 | ferrochain-sandbox | P2-05 | 1 | YES |
| 14 | ferrochain-memory | P2-05 | 2 | YES |
| 15 | ferrochain-macros | ADR-008 | 1 | YES |
| 16 | ferrochain-openai-sdk | D17-Q5 | 2 | YES |
| 17 | ferrochain-anthropic-sdk | D17-Q5 | 2 | YES |
| 18 | ferrochain-ollama-sdk | D17-Q5 | 2 | YES |
| — | xtask | D12 | — | NO (workspace binary) |

R6 namespace reservation: publish-all.sh must cover all 18 published crates before public announcement.

## ADR Registry

| ADR | Title | Status | Gate |
|-----|-------|--------|------|
| ADR-001 | Graph Execution Model (Alt B: HYBRID) | accepted — D9 gate passed 2026-07-14 | — |
| ADR-002 | Checkpoint Wire Format (msgpack) | accepted | — |
| ADR-003 | Durability Tiers | accepted | — |
| ADR-004 | Schema Generation: serde / schemars | accepted | D5 ✓ |
| ADR-005 | Logical Clock and Checkpoint Ordering | accepted | — |
| ADR-006 | Streaming Event Taxonomy | accepted | — |
| ADR-007 | Crate Topology and SDK Split | accepted | — |
| ADR-008 | Proc-Macro Attributes | accepted | ADR-004 ✓ |
| ADR-009 | Budget Governance Engine Placement | accepted | — |
| ADR-010 | Error Taxonomy and anyhow Confinement | accepted | — |
| ADR-011 | Cache-Key Content-Hash Contract (NE-05) | accepted — constrained by D17 NE adoption | — |
| ADR-012 | Self-Improvement Primitives: Skill Registry, Context Mutation, Guarded Writes (D20) | accepted — D20 authority | — |
| ADR-013 | MCP Server Module Placement in ferrochain-mcp (CAP-021) | accepted — D19/D20 authority | — |

## Verification Properties (VP-INDEX)

5 VPs total (3 Kani P0 + 2 integration P1):

| VP | BC Anchor | Module | Tool | Status |
|----|-----------|--------|------|--------|
| VP-001 | BC-2.03.001 (BSP determinism) | ferrochain-graph / bsp-engine | Kani | draft |
| VP-002 | BC-2.04.006 (session tenancy) | ferrochain-checkpoint / session-index | Kani | draft |
| VP-003 | BC-2.13.004 (workspace confinement) | ferrochain-sandbox / path-guard | Kani | draft |
| VP-004 | BC-2.09.004 (MCP ToolException) | ferrochain-mcp / mcp-adapter | integration | draft |
| VP-005 | BC-2.09.005 (MCP no live connections) | ferrochain-mcp / mcp-client | integration | draft |
