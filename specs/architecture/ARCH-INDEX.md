---
document_type: architecture-index
level: L3
version: "1.10"
status: active
producer: architect
timestamp: 2026-07-23T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/module-criticality.md
input-hash: "dcfda45"
traces_to: prd.md
deployment_topology: single-service
decisions: [D4, D6, D9, D11, D13, D17, D20, D21, D23]
changelog:
  - "1.10 (2026-07-23): F-P144-03 — Document Map module-decomposition descriptor corrected 18-crate→21-crate catalog (D21 +2, D23 +1 expansions)."
  - "1.9 (burst-238/2026-07-23): Stale-handoff sweep — resolve TBD BC ranges in Subsystem Registry (SS-18 001–005, SS-19 001–006, SS-20 001–003, SS-21 001–004, SS-22 001–003; BCs authored D21 burst per bc-authoring-plan); remove stale 'BC ranges TBD' trailing clauses from D21 and D23 Capability Addition notes; resolve stale VP section note (BC-2.23.005 CONFIGURATION→VAL contradiction — content change missed in v1.8; now marked RESOLVED)."
  - "1.8 (burst-233/2026-07-22): F-P133-06 — resolve stale BC-2.23.005 Category::CONFIGURATION contradiction note in VP section callout (~L176): update to RESOLVED (BC-2.23.005 v1.1 = VAL, burst-232, consistent with error-taxonomy v1.31 and VP-013 harness)."
  - "1.7 (burst-232/2026-07-22): D23 VP loop closure — VP-011/012/013 SEEDED with BC anchors (no longer candidates); VP section total 10→13 (6 Kani P0 + 3 Kani P1 + 2 proptest P1 + 2 integration P1); VP-INDEX reference v1.4→v1.5; SS-05 BC range 001–006→001–008; SS-06 BC range 001–003→001–006; SS-10 BC range 001–004→001–006; SS-23 BC range TBD→001–006."
  - "1.6 (D23/2026-07-22): D23 architecture layer — add SS-23 (First-Party Tool Library, ferrochain-tools crate #21); ADR registry 17→20 (ADR-018 per-tool-call approval hook, ADR-019 rolling context compaction, ADR-020 first-party tool library); Canonical Crate Roster 20→21 (+ferrochain-tools); SS-15 wave 2→1 (CAP-017 D23 item 3); SS-16 wave 2→1 (CAP-018 D23 item 4); VP table reflects VP-INDEX v1.5 (10 VPs at D23 open; VP-011..013 minted at burst-232 bringing total to 13); VP-011/012/013 D23 candidate anchors noted; fix stale Document Map ADR count (was 13, actually 17 post-D21, now 20 post-D23); fix stale VP total in VP section header (was 5, now 10)."
  - "1.5 (D21/2026-07-20): ecosystem-parity scope expansion — add SS-18 (Prompt Templates, ferrochain-prompts), SS-19 (LC Serialization, ferrochain-core), SS-20 (Document Retrieval, ferrochain-core + ferrochain-vectorstores), SS-21 (VectorStore Abstraction, ferrochain-vectorstores), SS-22 (Embeddings, ferrochain-core + providers); Canonical Crate Roster 18→20 (+ferrochain-prompts +ferrochain-vectorstores); ADR registry 13→17 (ADR-014 VectorStore+Retriever, ADR-015 PromptInjectionSafety, ADR-016 lc-JSON safety, ADR-017 Embeddings); VP candidates noted (no new VP files yet)."
  - "1.4 (provenance-fix-169/2026-07-17): remove .factory/STATE.md from inputs (not a genuine spec-content input; D-NNN decisions are baked-in stable facts per PO corpus adjudication)."
  - "1.3 (F-P72-04/ADR-013): add ADR-013 (mcp::server module placement) to ADR registry; update SS-09 D20 capability note to attribute mcp::server to ADR-013 (not ADR-012); ADR count 12→13."
  - "1.2 (D20/CAP-021+CAP-020): SS-09 BC range 001–005→001–007 (CAP-021 MCP server role); SS-15 BC range 001–003→001–006 (CAP-020 self-improvement primitives); SS-04 001–007→001–008; SS-08 001–012→001–014; SS-13 001–006→001–007; BC total 86→95."
  - "1.1 (bursts 74–86 / 2026-07-13–14): ADR-001 through ADR-010 all accepted (ADR-001 finalised Alt B: HYBRID); VP-004 + VP-005 added (MCP integration tests); VP table gained Tool column; ADR-011 added (Cache-Key Content-Hash Contract NE-05); ADR count 10 stubs→11 files; Canonical Crate Roster section added (18-crate table derivation: D6+D1+D13+P2-05+ADR-008+D17-Q5); SS-15 crate corrected ferrochain-graph→ferrochain-memory; SS-16 crate corrected ferrochain-graph→ferrochain-core; Module Decomp description 12-crate→18-crate; status draft→active; BC count 82→86; SS-08 range 001–008→001–012. NOTE (F-P104-01, 2026-07-18): reconstructed from commit 8aebfcd (burst 86, 2026-07-14) — version was never incremented to 1.1 before jumping to 1.2 in commit 85b168f (burst 149, 2026-07-15)."
  - "1.0 (initial / 2026-07-13): initial architecture index authored — 10 ADRs in proposed/draft state; 3 Kani VPs seeded (VP-001/002/003); 17 subsystems; deployment_topology single-service. NOTE (F-P104-01, 2026-07-18): reconstructed from commit ef41eda (burst 73, 2026-07-13) — no initial changelog row was written at authoring."
---

# Architecture Index: ferrochain

> **Context Engineering:** Lightweight index (~300 tokens). Load only the section
> files you need. Every section targets 800-1,200 tokens with `traces_to: ARCH-INDEX.md`.

## Document Map

| Section | File | Primary Consumer | Purpose |
|---------|------|-----------------|---------|
| System Overview | system-overview.md | orchestrator, all agents | Vision, principles, crate topology, constraints |
| Module Decomposition | module-decomposition.md | story-writer, implementer | 21-crate catalog, responsibilities, wave alignment |
| Dependency Graph | dependency-graph.md | story-writer, consistency-validator | Crate DAG, topological build order |
| API Surface | api-surface.md | test-writer, implementer | Public Rust traits, ferrochain-server endpoints, Cargo features |
| Verification Architecture | verification-architecture.md | formal-verifier, architect | Provable Properties Catalog, P0/P1 VP list, proof strategy |
| Purity Boundary Map | purity-boundary-map.md | implementer, formal-verifier | Per-crate pure-core / effectful-shell classification |
| Tooling Selection | tooling-selection.md | formal-verifier | Kani, cargo-fuzz, cargo-mutants, proptest versions + config |
| Verification Coverage Matrix | verification-coverage-matrix.md | consistency-validator | VP-to-module coverage status |

**ADRs:** `.factory/specs/architecture/decisions/` — 20 files (ADR-001 to ADR-020)

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
| SS-05 | HITL Interrupt / Resume | 2.05 | ferrochain-graph | BC-2.05.001–008 | 1 |
| SS-06 | Streaming Event Taxonomy | 2.06 | ferrochain-graph, ferrochain-core | BC-2.06.001–006 | 1 |
| SS-07 | Text Splitting | 2.07 | ferrochain-splitters | BC-2.07.001–003 | 1 |
| SS-08 | Provider Conformance + Standard Tests | 2.08 | ferrochain-openai, ferrochain-anthropic, ferrochain-ollama, ferrochain-standard-tests | BC-2.08.001–014 | 2 |
| SS-09 | MCP Tool Adapter | 2.09 | ferrochain-mcp | BC-2.09.001–007 | 2 |
| SS-10 | Budget Governance | 2.10 | ferrochain-graph | BC-2.10.001–006 | 1 |
| SS-11 | Content Provenance / Guardrail | 2.11 | ferrochain-graph | BC-2.11.001–006 | 1 |
| SS-12 | Durable-Run HTTP Server | 2.12 | ferrochain-server | BC-2.12.001–007 | 1 |
| SS-13 | Sandboxed Tool Execution | 2.13 | ferrochain-sandbox | BC-2.13.001–007 | 1 |
| SS-14 | Typed Error Taxonomy | 2.14 | ferrochain-core | BC-2.14.001–006 | 1 |
| SS-15 | Long-Horizon Memory | 2.15 | ferrochain-memory | BC-2.15.001–006 | 1 |
| SS-16 | Tool Retry + Circuit Breaker | 2.16 | ferrochain-core | BC-2.16.001–003 | 1 |
| SS-17 | Formal Verification Pipeline | 2.17 | xtask, ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox | BC-2.17.001–002 | 6 |
| SS-18 | Prompt Templates | 2.18 | ferrochain-prompts | BC-2.18.001–005 | 2 |
| SS-19 | LC Serialization / Round-Trip Registry | 2.19 | ferrochain-core | BC-2.19.001–006 | 2 |
| SS-20 | Document Retrieval | 2.20 | ferrochain-core, ferrochain-vectorstores | BC-2.20.001–003 | 2 |
| SS-21 | VectorStore Abstraction | 2.21 | ferrochain-vectorstores | BC-2.21.001–004 | 2 |
| SS-22 | Embeddings | 2.22 | ferrochain-core, ferrochain-openai, ferrochain-ollama | BC-2.22.001–003 | 2 |
| SS-23 | First-Party Tool Library | 2.23 | ferrochain-tools | BC-2.23.001–006 | 1 |

> **D20 Capability Additions (v1.2):** SS-09 adds CAP-021 (MCP server role) per ADR-013 — introduces `mcp::server` execution module in ferrochain-mcp; BC range extended from 001–005 to 001–007. SS-15 adds CAP-020 (self-improvement primitives) per ADR-012 — includes `SkillStore`, `MemoryWriteGuard` execution modules and `ContextMutationConfig` definitions; BC range extended from 001–003 to 001–006.

> **D21 Capability Additions (v1.5):** SS-18 (Prompt Templates) via ADR-015 — ferrochain-prompts new crate; injection safety pure-core guard. SS-19 (LC Serialization) via ADR-016 — core::serializable in ferrochain-core; inventory-based static registry; 141 core entries + feature-gated partner registration. SS-20 (Document Retrieval) via ADR-014 — Retriever trait + Document type in ferrochain-core; VectorStoreRetriever in ferrochain-vectorstores. SS-21 (VectorStore Abstraction) via ADR-014 — ferrochain-vectorstores new crate; in-memory backend + MMR. SS-22 (Embeddings) via ADR-017 — Embeddings trait in ferrochain-core; impls in ferrochain-openai + ferrochain-ollama (ferrochain-anthropic excluded: no embedding API).

> **D23 Capability Additions (v1.6):** SS-23 (First-Party Tool Library) via ADR-020 — ferrochain-tools new crate (crate #21); tools::fs (ReadFileTool/WriteFileTool/EditFileTool/ListDirTool), tools::shell (BashTool), tools::search (GrepTool). SS-05 (HITL) extended with per-tool-call PreToolCallHook API per ADR-018 — sub-node granularity HITL (PreToolCallHook trait, PreToolDecision enum). SS-10 (Budget Governance) extended with rolling compaction primitive per ADR-019 — CompactionTrigger/CompactionPolicy/CompactionSummary types in core::budget; compaction engine in graph::budget. SS-15 (Long-Horizon Memory) promoted Wave 2→1 (CAP-017 multi-session memory, D23 item 3). SS-16 (Tool Retry + Circuit Breaker) promoted Wave 2→1 (CAP-018 tool retry, D23 item 4).

## Canonical Crate Roster (Source of Truth)

> **Authoritative.** All other documents (ADR-007, system-overview, dependency-graph) derive
> from this table. Derivation: D6 base (9) + D1 (mcp, standard-tests) + D13 (server)
> + P2-05 (sandbox, memory) + ADR-008 (macros) + D17-Q5 (3 × -sdk) + D21 (prompts, vectorstores) + D23 (tools) = **21 published crates**.

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
| 19 | ferrochain-prompts | D21/ADR-015 | 2 | YES |
| 20 | ferrochain-vectorstores | D21/ADR-014 | 2 | YES |
| 21 | ferrochain-tools | D23/ADR-020 | 1 | YES |
| — | xtask | D12 | — | NO (workspace binary) |

R6 namespace reservation: publish-all.sh must cover all 21 published crates before public announcement.

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
| ADR-014 | VectorStore + Retriever Abstraction (D21) | accepted — D21 authority | — |
| ADR-015 | Prompt Template Rendering and Injection Safety (D21, SECURITY-CRITICAL) | accepted — D21 authority | — |
| ADR-016 | lc-JSON Round-Trip and Deserialization Safety (D21, SECURITY-CRITICAL) | accepted — D21 authority | — |
| ADR-017 | Embeddings Trait and Provider Integration (D21) | accepted — D21 authority | — |
| ADR-018 | Per-Tool-Call Approval Hook (D23) | accepted — D23 authority | — |
| ADR-019 | Rolling Context Compaction Primitive (D23) | accepted — D23 authority | — |
| ADR-020 | First-Party Tool Library (D23) | accepted — D23 authority | — |

## Verification Properties (VP-INDEX)

13 VPs total (6 Kani P0 + 3 Kani P1 + 2 proptest P1 + 2 integration P1 — see VP-INDEX v1.5):

| VP | BC Anchor | Module | Tool | Priority | Status |
|----|-----------|--------|------|----------|--------|
| VP-001 | BC-2.03.001 (BSP determinism) | ferrochain-graph / bsp-engine | Kani | P0 | draft |
| VP-002 | BC-2.04.006 (session tenancy) | ferrochain-checkpoint / session-index | Kani | P0 | draft |
| VP-003 | BC-2.13.004 (workspace confinement) | ferrochain-sandbox / path-guard | Kani | P0 | draft |
| VP-004 | BC-2.09.004 (MCP ToolException) | ferrochain-mcp / mcp-adapter | integration | P1 | draft |
| VP-005 | BC-2.09.005 (MCP no live connections) | ferrochain-mcp / mcp-client | integration | P1 | draft |
| VP-006 | BC-2.18.004 (injection_guard fail-closed) | ferrochain-prompts / injection_guard | Kani | P1 | draft |
| VP-007 | BC-2.19.001 (serializable round-trip) | ferrochain-core / serializable | proptest | P1 | draft |
| VP-008 | BC-2.22.001 (embeddings dimension parity) | ferrochain-core / embeddings | proptest | P1 | draft |
| VP-009 | BC-2.21.003 (zero-norm guard fail-closed) | ferrochain-vectorstores / vectorstores-similarity | Kani | P0 | draft |
| VP-010 | BC-2.19.005 (allowlist rejects unregistered) | ferrochain-core / serializable-reviver | Kani | P0 | draft |
| VP-011 | BC-2.05.007 (PreToolCallHook fail-closed) | ferrochain-graph / hitl | Kani | P0 | draft |
| VP-012 | BC-2.10.005 (OnWatermark arithmetic) | ferrochain-core / core-budget | Kani | P1 | draft |
| VP-013 | BC-2.23.005 (BashTool risk floor) | ferrochain-tools / tools-shell | Kani | P1 | draft |

> **D23 VPs SEEDED (burst-232):** VP-011/012/013 minted with BC anchors, Kani harness skeletons, and input-hashes. VP-011 (graph::hitl / PreToolCallHook fail-closed — Kani P0 red_gate); VP-012 (core-budget / OnWatermark arithmetic — Kani P1); VP-013 (tools-shell / BashTool risk floor — Kani P1). BC-2.23.005 category RESOLVED: BC-2.23.005 v1.1 amended to category VAL in burst-232 (error-taxonomy v1.31; consistent with VP-013 harness).
