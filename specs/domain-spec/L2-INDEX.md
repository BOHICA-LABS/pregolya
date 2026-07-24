---
document_type: domain-spec-index
level: L2
version: "1.13"
status: active
producer: business-analyst
timestamp: 2026-07-22T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
  - .factory/planning/holdout-domains/domain-e-agentic-coding-assistant.md
input-hash: "40fe43d"
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
decisions: [D1, D2, D3, D4, D6, D7, D8, D11, D12, D13, D17, D19, D20, D21, D23]
changelog:
  - "v1.13 (2026-07-24): Burst 250 F-P149-01/F-P149-02 — capabilities-p1-p2 v1.11→v1.12 (TD-VSDD-091 corpus-wide de-pin sweep: §CAP-029 VP-009 framing anchors — 2 sites (F-P149-01) + 3 sites (F-P149-02) + 1 near-miss 'Decision 3 and v1.1' outside grep pattern all replaced with stable 'ADR-014 Decision 2 §Hardening note' per D18-P84-A). Zero live-body ADR version pins remain in domain-spec/ corpus."
  - "v1.12 (2026-07-23): Fix burst 242 F-P142-02 — Document Map failure-modes.md row updated: ~140→~257 lines, (14 modes)→(19 modes). ID Registry: FM-NNN count 14→19 (FM-015..019 added in failure-modes.md v1.1 burst-241). Registry sweep: CAP 38, DI 15, DEC 13, ASM 9, R 8 all confirmed stable — no additional drift found."
  - "v1.11 (2026-07-22): Fix burst 235 F-P135-06 (BA scope) — events.md v1.6→v1.7 (D23 execution-time transitions: StreamEvent taxonomy 12→15 variants; CompactionExecuted domain event added after CheckpointWritten; ToolApprovalRaised + ToolApprovalResolved domain events added after ResumeValueReceived; ordering rules 7-8 added; decisions D21+D23 added). Document Map line count updated: events.md ~140→~175."
  - "v1.10 (2026-07-22): Fix burst 234 — invariants.md v1.1→v1.2 (DI-015 Subprocess Execution Timeout added per F-P134-06 architect adjudication; Tool Execution Invariants section added). DI-NNN census 14→15. Document Map and ID Registry updated."
  - "v1.9 (2026-07-22): Fix burst 233 F-P133-08 (BA micro-fix) — capabilities-p1-p2.md v1.7→v1.8 (CAP-036 similar-crate facts corrected per ADR-020 Decision 7 v1.1: pin `\"3\"`, owner mitsuhiko, Apache-2.0 single-licensed; stale confirm-before-write instruction removed). TD-VSDD-060 sweep: no other dtolnay/MIT similar-crate facts in domain-spec/ tree."
  - "v1.8 (2026-07-22): D23 L2 CAP layer (burst-230) — capabilities-p1-p2.md v1.6→v1.7 (CAP-017/018 promoted P2→P1; CAP-034..038 authored; D23 section added); entities-graph.md v1.5→v1.6 (HITL Approval Hook Domain + Context Compaction Domain sections added; Tool entity first-party subtypes; Relationships Summary extended); ubiquitous-language-core.md v1.5→v1.6 (D23 section: 13 new terms — PreToolCallHook, PreToolDecision, CompactionTrigger, CompactionPolicy, ConversationSnapshot, CompactionSummary, ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, BashTool, BashOutput, GrepTool). CAP census: 33→38. Priority: P1 19→26, P2 3→1. D23 and domain-e added. Document Map updated."
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
| Capabilities — P1/P2 | capabilities-p1-p2.md | ~530 | product-owner, architect, story-writer | P1: CAP-009–011, CAP-014–015, CAP-017–018 (D23 Wave 1 promotions), CAP-020–038 (D21 + D23 additions); P2: CAP-019 only |
| Entities — Core/Graph/Checkpoint/Retrieval/Serialization/VectorStore/Embeddings/HITL/Compaction | entities-graph.md | ~315 | architect, product-owner | Core primitives, graph, checkpoint + D21: Document, PromptValue, TrustLevel, Serialized, VectorStore, Embeddings, MetadataFilter, SearchType + D23: PreToolCallHook, PreToolDecision, ToolCallPreview, ToolApprovalRequest, CompactionTrigger, CompactionPolicy, ConversationSnapshot, CompactionSummary |
| Entities — Server/Policy/Provider | entities-server.md | ~95 | architect, product-owner | Server, governance, and provider entities |
| Domain Invariants | invariants.md | ~175 | product-owner, architect | DI-NNN business rules (15 invariants) |
| Domain Events | events.md | ~175 | architect | Processing stages, triggers, preconditions; StreamEvent taxonomy 15 variants (D23); ToolApprovalRaised/Resolved + CompactionExecuted domain events (D23) |
| Edge Cases | edge-cases.md | ~133 | story-writer, test-writer | DEC-NNN domain-level edge cases (13 cases) |
| Assumptions | assumptions.md | ~48 | product-owner, test-writer | ASM-NNN with validation methods (9 assumptions) |
| Risks | risks.md | ~51 | product-owner, architect | R-NNN risk register (8 risks) |
| Failure Modes | failure-modes.md | ~257 | architect, test-writer | FM-NNN runtime failure catalog (19 modes) |
| Differentiators | differentiators.md | ~62 | product-owner | Competitive differentiator → CAP-NNN traceability |
| Ubiquitous Language — Core/Graph/D21/D23 | ubiquitous-language-core.md | ~330 | all agents | Core and graph term definitions + D21 (16 terms) + D23 (13 terms: PreToolCallHook, PreToolDecision, CompactionTrigger, CompactionPolicy, ConversationSnapshot, CompactionSummary, ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, BashTool, BashOutput, GrepTool) |
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
| CAP-NNN | 38 | capabilities-p0.md (CAP-001–008, CAP-012, CAP-013, CAP-016) + capabilities-p1-p2.md (CAP-009–011, CAP-014–015, CAP-017–038) |
| DI-NNN | 15 | invariants.md |
| DEC-NNN | 13 | edge-cases.md |
| ASM-NNN | 9 | assumptions.md |
| R-NNN | 8 | risks.md |
| FM-NNN | 19 | failure-modes.md |

> **Risk ID scheme note (F-10):** The R-NNN scheme in domain-spec/risks.md is canonical for all spec artifacts (PRD RTM, BC Traced-To, NFR catalog). STATE.md uses a separate R-N numeric alias (R8, R10, R11 map to R-004, R-005, R-006 respectively) retained for decision-log continuity only — see risks.md §Dual Risk ID Reconciliation for the full cross-walk table.

## Priority Distribution

| Priority | Count | Capabilities |
|----------|-------|-------------|
| P0 (must-have) | 11 | CAP-001, CAP-002, CAP-003, CAP-004, CAP-005, CAP-006, CAP-007, CAP-008, CAP-012, CAP-013, CAP-016 |
| P1 (should-have) | 26 | CAP-009, CAP-010, CAP-011, CAP-014, CAP-015, CAP-017 (D23), CAP-018 (D23), CAP-020, CAP-021, CAP-022, CAP-023, CAP-024, CAP-025, CAP-026, CAP-027, CAP-028, CAP-029, CAP-030, CAP-031, CAP-032, CAP-033, CAP-034, CAP-035, CAP-036, CAP-037, CAP-038 |
| P2 (nice-to-have) | 1 | CAP-019 |

> **Priority note (ADV-P1D-PASS-21):** CAP-012, CAP-013, and CAP-016 were elevated from P1 to P0
> to align with D17-Q4 (budget governance), D17-Q8 (guardrail-on-ingress), and D17 CONFLICT-6
> (error taxonomy) mandates. All constituent BCs are P0 in the PRD RTM (§2.10, §2.11, §2.14).
> Detail relocated from capabilities-p1-p2.md to capabilities-p0.md.
>
> **D23 promotion note (2026-07-22):** CAP-017 (long-horizon memory) and CAP-018 (tool retry)
> promoted P2 → P1 per domain-e-agentic-coding-assistant.md §3 items 13/16 DEGRADED closures.
> CAP-034..038 authored as net-new P1 Wave 1 capabilities (per-tool-call approval hook ADR-018,
> rolling context compaction ADR-019, first-party tool library ADR-020 / SS-23).

## Design-Forcing-Function Summary (D8)

Five holdout domains constrain the domain model as Phase-1 forcing functions:

| Domain | Primary Forcing Pressure | Key Capabilities |
|--------|--------------------------|-----------------|
| A — SOC Analyst | Risk-tiered HITL auth gates; forensic audit; prompt-injection isolation | CAP-004, CAP-006, CAP-013, CAP-015 |
| B — Dark Factory | Multi-day durable runs; budget governance; convergence loops | CAP-004, CAP-005, CAP-006, CAP-012 |
| C — OpenClaw | Persistent sessions; channel ingress; local-first deployment; pluggable embedding backends [NEW D21 requirement — CAP-017 vector path requires a concrete Embeddings impl; SS-22 is the holdout-necessary D21 piece for Domain C evaluation] | CAP-005, CAP-014, CAP-017, CAP-031, CAP-032, CAP-033 |
| D — Hermes Agent | Inbound MCP server role; expose registered tools as MCP endpoint | CAP-020, CAP-021 |
| E — Agentic Coding CLI | Fine-grained per-tool-call HITL; rolling context compaction; multi-session project memory; tool retry; first-party file/bash/search tools [D22/D23; five DEGRADED gaps closed to Wave 1] | CAP-017 (D23↑), CAP-018 (D23↑), CAP-034, CAP-035, CAP-036, CAP-037, CAP-038 |

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
