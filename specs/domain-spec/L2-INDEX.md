---
document_type: domain-spec-index
level: L2
version: "1.7"
status: active
producer: business-analyst
timestamp: 2026-07-21T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "f49b669"
traces_to: .factory/specs/product-brief.md
sections:
  - capabilities-p0.md
  - capabilities-p1-p2.md
  - entities-graph.md
  - entities-server.md
  - invariants.md
  - events.md
  - edge-cases.md
  - assumptions.md
  - risks.md
  - failure-modes.md
  - differentiators.md
  - ubiquitous-language-core.md
  - ubiquitous-language-server.md
  - bounded-contexts.md
decisions: [D1, D2, D3, D4, D6, D7, D8, D11, D12, D13, D17, D19, D20, D21]
changelog:
  - "v1.7 (2026-07-21): F-P131-04/05 adjudication (burst-226) — entities-graph.md v1.4→v1.5 (PromptValue MessageProvenance.tag→highest_trust_level; TrustLevel entity added to Retrieval and Serialization Domain; Relationships Summary updated); entities-server.md v1.11→v1.12 (ProvenanceTag disambiguation note added); capabilities-p1-p2.md v1.5→v1.6 (CAP-022 strict-undefined universal; CAP-022 security invariant TrustLevel::Untrusted explicit; CAP-023 highest-severity TrustLevel); ubiquitous-language-core.md v1.4→v1.5 (TrustLevel D21 term added; 15→16 D21 terms); ubiquitous-language-server.md v1.3→v1.4 (ProvenanceTag disambiguation note added). Document Map updated."
  - "v1.6 (2026-07-20): D21 second-half CAP authoring complete. ID Registry: CAP-NNN count 27→33 (CAP-028..033 authored for SS-21/22). Priority Distribution: P1 count 13→19; total 27→33. capabilities-p1-p2.md updated (v1.4→v1.5); entities-graph.md updated (v1.3→v1.4, VectorStore/Embeddings/MetadataFilter/SearchType added); ubiquitous-language-core.md updated (v1.3→v1.4, 6 D21 terms added). Domain C forcing-function row updated (SS-22/CAP-031..033 added). Document Map updated."
  - "v1.5 (2026-07-20): D21 first-half CAP authoring complete. ID Registry: CAP-NNN count 21→27 (CAP-022..027 authored for SS-18/19/20). Priority Distribution: P1 count 7→13; total 21→27. capabilities-p1-p2.md updated (v1.3→v1.4); capabilities-p0.md updated (v1.6→v1.7, CAP-002 D21 reversal); entities-graph.md updated (v1.2→v1.3, Document/PromptValue/Serialized added); ubiquitous-language-core.md updated (v1.2→v1.3, 9 D21 terms added). D21 added to decisions list. Document Map row descriptions updated."
  - "v1.4 (2026-07-20): Design-Forcing-Function Summary updated — Four holdout domains (was three); Domain D (Hermes Agent, inbound MCP server role per D19/D20) added to forcing-function table. D19 added to decisions list. TD-VSDD-060 sweep: one stale occurrence corrected; second occurrence (v1.1 changelog: 'all three were over 1,500-token threshold') refers to split files, not holdout domains — accurate, no change."
  - "v1.3 (2026-07-17): Provenance-integrity fix — STATE.md removed from inputs (D-NNN decisions baked at authoring time, not live state); domain-d-hermes-agent.md added (D19/D20 forcing function for CAP-020/CAP-021 added in v1.2); input-hash recomputed. All section files updated in same burst."
  - "v1.2 (D20 sub-burst 2): CAP-020 (Self-Improvement Primitives: SkillStore + MemoryWriteGuard + Frozen-Snapshot Context Mutation, P1) and CAP-021 (MCP Server Role: Expose Registered Tools as MCP Server Endpoint, P1) added to capabilities-p1-p2.md (v1.1). CAP count 19→21; P1 count 5→7; total 19→21. D20 added to decisions list."
  - "v1.1: Split capabilities.md → capabilities-p0.md + capabilities-p1-p2.md; entities.md → entities-graph.md + entities-server.md; ubiquitous-language.md → ubiquitous-language-core.md + ubiquitous-language-server.md (all three were over 1,500-token threshold per DF-021)"
---

# L2 Domain Specification: ferrochain

> **Sharded artifact (DF-021).** This index provides navigation and summary.
> Detail lives in per-section files listed below. Each section targets
> 800-1,200 tokens for optimal LLM consumption.

## Domain Summary

ferrochain occupies the agent-orchestration domain: composing AI model calls, tool
invocations, and durable state transitions into resumable graphs with human-in-the-loop
interrupts, structured checkpointing, typed error propagation, and provider conformance —
expressed as a Rust async-native port of the LangChain v1 semantic surface.

## Document Map

| Section | File | Lines | Primary Consumer | Purpose |
|---------|------|-------|-----------------|---------|
| Capabilities — P0 | capabilities-p0.md | ~140 | product-owner, architect, story-writer | CAP-001–008 (Wave 0/1) + CAP-012, CAP-013, CAP-016 (D17-elevated to P0; cross-cutting Wave 0/1); CAP-002 revised v1.7 (D21 reversal) |
| Capabilities — P1/P2 | capabilities-p1-p2.md | ~380 | product-owner, architect, story-writer | P1: CAP-009–011, CAP-014–015, CAP-020–033 (Wave 2 + Wave 0/1; D21 full expansion CAP-022..033); P2: CAP-017, CAP-018, CAP-019 |
| Entities — Core/Graph/Checkpoint/Retrieval/Serialization/VectorStore/Embeddings | entities-graph.md | ~200 | architect, product-owner | Core primitives, graph, checkpoint + D21 full: Document, PromptValue, TrustLevel, Serialized, VectorStore, Embeddings, MetadataFilter, SearchType |
| Entities — Server/Policy/Provider | entities-server.md | ~95 | architect, product-owner | Server, governance, and provider entities |
| Domain Invariants | invariants.md | ~156 | product-owner, architect | DI-NNN business rules (14 invariants) |
| Domain Events | events.md | ~140 | architect | Processing stages, triggers, preconditions |
| Edge Cases | edge-cases.md | ~133 | story-writer, test-writer | DEC-NNN domain-level edge cases (13 cases) |
| Assumptions | assumptions.md | ~48 | product-owner, test-writer | ASM-NNN with validation methods (9 assumptions) |
| Risks | risks.md | ~51 | product-owner, architect | R-NNN risk register (8 risks) |
| Failure Modes | failure-modes.md | ~140 | architect, test-writer | FM-NNN runtime failure catalog (14 modes) |
| Differentiators | differentiators.md | ~62 | product-owner | Competitive differentiator → CAP-NNN traceability |
| Ubiquitous Language — Core/Graph/D21 | ubiquitous-language-core.md | ~215 | all agents | Core and graph term definitions + D21 full (16 terms): PromptTemplate, ChatPromptTemplate, MessagesPlaceholder, FewShot, LcSerializable, Reviver, Retriever, Document, VectorStoreRetriever, VectorStore, InMemoryVectorStore, MetadataFilter, Embeddings, EmbeddingsOpenAI, EmbeddingsOllama, TrustLevel |
| Ubiquitous Language — Server/Policy | ubiquitous-language-server.md | ~100 | all agents | Server, policy/safety, error terms + reconciliation table |
| Bounded Contexts | bounded-contexts.md | ~155 | architect | Crate-level subsystem boundaries |

## Cross-References

| If you need... | Read these together |
|----------------|-------------------|
| BC creation input | capabilities-p0.md + capabilities-p1-p2.md + invariants.md + edge-cases.md + assumptions.md + risks.md + differentiators.md |
| Architecture design input | capabilities-p0.md + capabilities-p1-p2.md + entities-graph.md + entities-server.md + invariants.md + events.md + risks.md + failure-modes.md + bounded-contexts.md |
| Story decomposition input | capabilities-p0.md + capabilities-p1-p2.md + edge-cases.md + ubiquitous-language-core.md |
| Holdout scenario generation | assumptions.md + risks.md + failure-modes.md + edge-cases.md |
| NFR derivation | risks.md + failure-modes.md + invariants.md |
| Vocabulary / term resolution | ubiquitous-language-core.md + ubiquitous-language-server.md |
| Full domain review | ALL sections |

## ID Registry Summary

| ID Format | Count | Section |
|-----------|-------|---------|
| CAP-NNN | 33 | capabilities-p0.md (CAP-001–008, CAP-012, CAP-013, CAP-016) + capabilities-p1-p2.md (CAP-009–011, CAP-014–015, CAP-017–033) |
| DI-NNN | 14 | invariants.md |
| DEC-NNN | 13 | edge-cases.md |
| ASM-NNN | 9 | assumptions.md |
| R-NNN | 8 | risks.md |
| FM-NNN | 14 | failure-modes.md |

> **Risk ID scheme note (F-10):** The R-NNN scheme in domain-spec/risks.md is canonical for all spec artifacts (PRD RTM, BC Traced-To, NFR catalog). STATE.md uses a separate R-N numeric alias (R8, R10, R11 map to R-004, R-005, R-006 respectively) retained for decision-log continuity only — see risks.md §Dual Risk ID Reconciliation for the full cross-walk table.

## Priority Distribution

| Priority | Count | Capabilities |
|----------|-------|-------------|
| P0 (must-have) | 11 | CAP-001, CAP-002, CAP-003, CAP-004, CAP-005, CAP-006, CAP-007, CAP-008, CAP-012, CAP-013, CAP-016 |
| P1 (should-have) | 19 | CAP-009, CAP-010, CAP-011, CAP-014, CAP-015, CAP-020, CAP-021, CAP-022, CAP-023, CAP-024, CAP-025, CAP-026, CAP-027, CAP-028, CAP-029, CAP-030, CAP-031, CAP-032, CAP-033 |
| P2 (nice-to-have) | 3 | CAP-017, CAP-018, CAP-019 |

> **Priority note (ADV-P1D-PASS-21):** CAP-012, CAP-013, and CAP-016 were elevated from P1 to P0
> to align with D17-Q4 (budget governance), D17-Q8 (guardrail-on-ingress), and D17 CONFLICT-6
> (error taxonomy) mandates. All constituent BCs are P0 in the PRD RTM (§2.10, §2.11, §2.14).
> Detail relocated from capabilities-p1-p2.md to capabilities-p0.md.

## Design-Forcing-Function Summary (D8)

Four holdout domains constrain the domain model as Phase-1 forcing functions:

| Domain | Primary Forcing Pressure | Key Capabilities |
|--------|--------------------------|-----------------|
| A — SOC Analyst | Risk-tiered HITL auth gates; forensic audit; prompt-injection isolation | CAP-004, CAP-006, CAP-013, CAP-015 |
| B — Dark Factory | Multi-day durable runs; budget governance; convergence loops | CAP-004, CAP-005, CAP-006, CAP-012 |
| C — OpenClaw | Persistent sessions; channel ingress; local-first deployment; pluggable embedding backends [NEW D21 requirement — CAP-017 vector path requires a concrete Embeddings impl; SS-22 is the holdout-necessary D21 piece for Domain C evaluation] | CAP-005, CAP-014, CAP-017, CAP-031, CAP-032, CAP-033 |
| D — Hermes Agent | Inbound MCP server role; expose registered tools as MCP endpoint | CAP-020, CAP-021 |

## Key Anchors from COMPARATIVE-ASSESSMENT.md (D17)

| Source | Domain Impact |
|--------|--------------|
| CONFLICT-1, NE-17 | BSP determinism → DI-001; FM-001 |
| CONFLICT-2, D11.3 | Per-task durability → DI-002; FM-002 |
| CONFLICT-3 | HITL FIFO resume → DI-003; FM-003 |
| CONFLICT-4 | Monotonic checkpoint clock → DI-004 |
| CONFLICT-6 | FerrochainError 2D struct → entities-server.md, CAP-016 |
| NE-01 | Enforcing sandbox default → DI-006; FM-013 |
| NE-02 | Workspace confinement → DI-007; DEC-011 |
| NE-04 | Outbound timeout → DI-009; FM-011 |
| NE-06, HS-8 | Guardrail ingress coverage → DI-012; CAP-013 |
| NE-07 | Constructor Result → DI-008; FM-014 |
| NE-10 | Credential opacity → DI-010; FM-010 |
| NE-12 | Session triple-address → DI-005; FM-005 |
| NE-13 | Streaming/unary equiv. → DI-011; FM-007 |
| NE-14 | Secure server defaults → DI-013; FM-008, FM-009 |
