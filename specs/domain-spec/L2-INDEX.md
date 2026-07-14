---
document_type: domain-spec-index
level: L2
version: "1.1"
status: draft
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/STATE.md
input-hash: "06d989076ed5db7de243da4eaa4d5f44071df64cf4b451fb4c85faa4d695aa1a"
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
decisions: [D1, D2, D3, D4, D6, D7, D8, D11, D12, D13, D17]
changelog:
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
| Capabilities — P0 | capabilities-p0.md | ~95 | product-owner, architect, story-writer | CAP-001 to CAP-008 (must-have for release) |
| Capabilities — P1/P2 | capabilities-p1-p2.md | ~115 | product-owner, architect, story-writer | CAP-009 to CAP-019 (Wave 2 + extended) |
| Entities — Core/Graph/Checkpoint | entities-graph.md | ~100 | architect, product-owner | Core primitives, graph, and checkpoint entities |
| Entities — Server/Policy/Provider | entities-server.md | ~95 | architect, product-owner | Server, governance, and provider entities |
| Domain Invariants | invariants.md | ~156 | product-owner, architect | DI-NNN business rules (14 invariants) |
| Domain Events | events.md | ~140 | architect | Processing stages, triggers, preconditions |
| Edge Cases | edge-cases.md | ~133 | story-writer, test-writer | DEC-NNN domain-level edge cases (13 cases) |
| Assumptions | assumptions.md | ~48 | product-owner, test-writer | ASM-NNN with validation methods (9 assumptions) |
| Risks | risks.md | ~51 | product-owner, architect | R-NNN risk register (8 risks) |
| Failure Modes | failure-modes.md | ~140 | architect, test-writer | FM-NNN runtime failure catalog (12 modes) |
| Differentiators | differentiators.md | ~62 | product-owner | Competitive differentiator → CAP-NNN traceability |
| Ubiquitous Language — Core/Graph | ubiquitous-language-core.md | ~105 | all agents | Core and graph term definitions |
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
| CAP-NNN | 19 | capabilities-p0.md (CAP-001–008) + capabilities-p1-p2.md (CAP-009–019) |
| DI-NNN | 14 | invariants.md |
| DEC-NNN | 13 | edge-cases.md |
| ASM-NNN | 9 | assumptions.md |
| R-NNN | 8 | risks.md |
| FM-NNN | 12 | failure-modes.md |

> **Risk ID scheme note (F-10):** The R-NNN scheme in domain-spec/risks.md is canonical for all spec artifacts (PRD RTM, BC Traced-To, NFR catalog). STATE.md uses a separate R-N numeric alias (R8, R10, R11 map to R-004, R-005, R-006 respectively) retained for decision-log continuity only — see risks.md §Dual Risk ID Reconciliation for the full cross-walk table.

## Priority Distribution

| Priority | Count | Capabilities |
|----------|-------|-------------|
| P0 (must-have) | 8 | CAP-001, CAP-002, CAP-003, CAP-004, CAP-005, CAP-006, CAP-007, CAP-008 |
| P1 (should-have) | 8 | CAP-009, CAP-010, CAP-011, CAP-012, CAP-013, CAP-014, CAP-015, CAP-016 |
| P2 (nice-to-have) | 3 | CAP-017, CAP-018, CAP-019 |

## Design-Forcing-Function Summary (D8)

Three holdout domains constrain the domain model as Phase-1 forcing functions:

| Domain | Primary Forcing Pressure | Key Capabilities |
|--------|--------------------------|-----------------|
| A — SOC Analyst | Risk-tiered HITL auth gates; forensic audit; prompt-injection isolation | CAP-004, CAP-006, CAP-013, CAP-015 |
| B — Dark Factory | Multi-day durable runs; budget governance; convergence loops | CAP-004, CAP-005, CAP-006, CAP-012 |
| C — OpenClaw | Persistent sessions; channel ingress; local-first deployment | CAP-005, CAP-014, CAP-017 |

## Key Anchors from COMPARATIVE-ASSESSMENT.md (D17)

| Source | Domain Impact |
|--------|--------------|
| CONFLICT-1, NE-17 | BSP determinism → DI-001; FM-001 |
| CONFLICT-2, D11.3 | Per-task durability → DI-002; FM-002 |
| CONFLICT-3 | HITL FIFO resume → DI-003; FM-003 |
| CONFLICT-4 | Monotonic checkpoint clock → DI-004 |
| CONFLICT-6 | FerrochainError 2D struct → entities-server.md, CAP-016 |
| NE-01 | Enforcing sandbox default → DI-006; FM-007 |
| NE-02 | Workspace confinement → DI-007; DEC-012 |
| NE-04 | Outbound timeout → DI-009; FM-011 |
| NE-06, HS-8 | Guardrail ingress coverage → DI-012; CAP-013 |
| NE-07 | Constructor Result → DI-008; FM-010 |
| NE-10 | Credential opacity → DI-010; FM-010 |
| NE-12 | Session triple-address → DI-005; FM-005 |
| NE-13 | Streaming/unary equiv. → DI-011; FM-007 |
| NE-14 | Secure server defaults → DI-013; FM-008, FM-009 |
