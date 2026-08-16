---
document_type: architecture-index
level: L3
version: "1.29"
status: active
producer: architect
timestamp: 2026-08-16T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/module-criticality.md
input-hash: "pending"
traces_to: prd.md
deployment_topology: single-service
decisions: [D4, D6, D9, D11, D13, D17, D20, D21, D23]
changelog:
  - "1.29 (burst-292/P1D-183-F3/2026-08-16): Fix ADR-025 row in §ADR Registry: 'grounds verify-signature-canon.sh rules S2/S3/S4' → 'S1/S2/S3/S4'. S1 (as_retriever Arc<Self> receiver rule) is grounded by ADR-025 per ADR-025 §Consequences and §Source/Origin; v1.26 changelog entry already stated S1/S2/S3/S4 correctly but the live ADR Registry table cell was not updated in that burst."
  - "1.28 (FIX-BURST-291/F-P1D182-01/2026-08-16): Fix phantom §-anchors in D23 VP seeding blockquote. 'BC-2.23.005 §Category amended to VAL in burst-232' → 'BC-2.23.005 §Postconditions (PC-4) category amended to VAL in burst-232'; 'error-taxonomy §TOOLS' → 'error-taxonomy.md §Component: TOOLS'. Rationale: BC-2.23.005 has no §Category heading (category field in §Postconditions PC-4); error-taxonomy.md has no §TOOLS heading (real heading §Component: TOOLS (pregolya-tools))."
  - "1.27 (fix-burst-287/records-lint-pin/2026-08-01): Fix records-lint L9b failures in v1.26 entry: three version pins removed from changelog prose (ADR-023, purity-boundary-map.md, and module-criticality.md document references changed from versioned to document-name-only form per TD-VSDD-091). Fix typo: canon-govenance → canon-governance in burst slug."
  - "1.26 (fix-burst-287/canon-governance/2026-08-01): ADR-025 minted — Type Signature Canon: Object Safety and Arc Ownership Patterns (D-43, D-45, D-48). Grounds verify-signature-canon.sh rules S1/S2/S3/S4 in citable ADR headings; hook now enforces rather than defines the canon. POL-18 D-43/D-45/D-48 entries can be repointed to: §DynTool: Canonical Object-Safe Tool Dispatch Form (D-43), §VectorStoreRetriever: No Lifetime Parameter (D-45), §as_retriever Receiver: Arc<Self> Ownership (D-48), §&Arc<Self> Receiver: Standing Prohibition (D-48 General). ADR count 24→25. ADR-023: three phantom §citations fixed (§compile-fail-gate ×2, §public-API-enums). purity-boundary-map.md: stale intro count corrected (71/69/2 → 76/70/6 from ground-truth crate::module-form path row count in module-decomposition.md; +1 tiered core::tool, +4 definitions-only/exempt rows from FIX-BURST-277). module-criticality.md: Census quintuple updated (decomposition_total_rows=76, decomposition_tiered_rows=70, exempt_count=6, registry_rows=84, matched_rows=70); no Classification Summary content changes."
  - "1.25 (fix-burst-287/F-P176-C002/2026-08-01): ADR-024 minted — WriteFileTool Create-Path Confinement Protocol: parent-canonicalize extension for non-existent target paths (two-phase protocol), TOCTOU residual risk analysis (LOW for standard deployment; v2 mitigation path via rustix+openat+O_NOFOLLOW documented), error routing table (E-TOOLS-001 for genuine escapes, E-TOOLS-008 for missing parent or I/O failure — A missing parent directory and a missing target file do not collapse to NotFound-means-violation), symlinked parent handling (canonicalize follows link; target outside workspace = WorkspaceEscape), atomic write interaction. Product-owner applies to BC-2.23.002 next. ADR count 23→24."
  - "1.24 (fix-burst-287/CANON-SETTING/2026-08-01): ADR-022 minted — §Named-Section Citation Convention: restriction to real markdown headings, TD-VSDD-091 conflict resolution, machine-verification specification (F-P176-A039+E001). ADR-023 minted — #[non_exhaustive] Governance for Public API Types: governing rule, exception criteria, Exempt Inventory (5 types), Required Inventory (12 enums + 8 structs), BC-2.22.001 gate scope consequence (F-P176-A028+A029+D009+B026+C028). ADR count 21→23. ADR-010 §Class-3 prohibition strengthened — PregolyaError::new() is now explicitly FORBIDDEN in Class 3 prose/observation contexts with full rationale (F-P176-C008 adjudication)."
  - "1.23 (fix-burst-283/F-P175-C101+F-P175-C113/2026-07-30): ADR-021 minted — SecurityConfig TOML representation (Decision 1) and RunnableConfig.configurable field (Decision 2). Resolves mutual unbootability between BC-2.12.005 EC-005 and interface-definitions.md TOML template (C101); resolves fabricated-capability finding for BC-2.12.002 §Description (C113 mislabeled as BC-2.12.005). ADR count 20→21. Document Map unchanged; no new section files."
  - "1.22 (fix-burst-279/gap-corrections/2026-07-28): Gap-fix wave (three corrections to initial wave). (1) ADR-012 §Decision 1 Amendment — Gap 3: empty app_id B101 path corrected from Ok(None) to Err(E-MEMORY-004 NoScopeContext); fail-loud symmetric with B102 (SkillStore). (2) ADR-015 §Decision 3 Amendment — Gap 1: FewShotPromptTemplate adjudication body added (pre-expansion trust check; examples typed as Vec<(TemplateVar, TemplateVar)>); TemplateInput enum concretized (Scalar/Messages/FewShotExamples arms); B201 type-level enforcement design question answered (prohibition retained for v1; API friction outweighs benefit; v2 trigger condition documented). (3) interface-definitions.md §Prompt Templates — Gap 2 (TD-VSDD-060 sweep): TemplateInput enum defined; format_messages signature corrected to HashMap<String, TemplateInput>. (4) VP-006 §Formal invariant + §Kani harness — formal invariant updated to HashMap<String, TemplateInput>; harness extended to cover Scalar, Messages, and FewShotExamples arms."
  - "1.21 (fix-burst-279/F-P175-B101+B102+B201+B202+B208/2026-07-28): Architect security adjudication wave — three architecture files bumped. ADR-012 §Decision 1 Amendment: ContextMutationConfig scope bridge (B101: spec.namespace is key-prefix not app_id; loading uses RunContext.app_id) and SkillStore scope encapsulation (B102: bind MemoryScope::App(app_id) at construction; E-MEMORY-004 on missing app_id). ADR-015 §Decision 3 Amendment: PromptTemplate::format explicitly unguarded (B201); MessageListVar guard added to injection check (B202); TrustLevel severity inversion fixed with severity() method + #[non_exhaustive] + Ord prohibition (B208). interface-definitions.md §Prompt Templates + §RunContext + §SkillStore: TrustLevel enum updated (Copy+non_exhaustive+kani::Arbitrary+severity()); RunContext.app_id field added; SkillStore scope note added; context_mutations doc updated with scope bridge."
  - "1.20 (FIX-BURST-278/L9b-de-pin/2026-07-28): L9b de-pin: api-surface.md §FIX-BURST-277-WAVE-B-errata changelog entry and interface-definitions.md §FIX-BURST-277-WAVE-B-errata changelog entry — ADR-005 version pins replaced with ADR-005 §Adjacent Trait Object-Safety Adjudications section anchors. records-lint FAIL=0 achieved. api-surface.md bumped to v1.20; interface-definitions.md bumped to v2.65."
  - "1.19 (FIX-BURST-278/Wave-C-S4-complete/2026-07-28): ADR-005 §Wave C BC-side migration spec: four non-object-safe (E0038) notation lines annotated to satisfy S4 gate exemption (all four classification (b) hazard-naming prose). ADR-005 §Failure Mode: SCREAMING-CASE struct literal replaced with prose error-code reference."
  - "1.18 (FIX-BURST-278-WAVE-A/F-P175-D212-propagation/2026-07-28): Iron Law propagation for core::tool (triggered by module-decomposition.md §core::tool row addition) — add core::tool Pure Core row to purity-boundary-map.md (83→84 total rows); add core::tool HIGH row to verification-coverage-matrix.md (HIGH count 28→29); add core::tool HIGH row to module-criticality.md (Classification Summary HIGH 28→29, Total 83→84)."
  - "1.17 (FIX-BURST-278/F-P175-D215+D220+D223/2026-07-28): Three findings closed. (1) F-P175-D215 — §Verification Properties preamble: `see VP-INDEX v1.7` version pin removed; replaced with stable `see VP-INDEX` (no version number per TD-VSDD-091). (2) F-P175-D220 — `input-hash: \"pending-FIX-BURST-275\"` stale burst reference removed; now `\"pending\"` (state-manager routes hash computation). (3) F-P175-D223 — `timestamp: 2026-07-26T00:00:00Z` corrected to `2026-07-28T00:00:00Z` (ARCH-INDEX is not an ADR; D-31 frozen-timestamp exemption does not apply; latest changelog entry v1.16 is dated 2026-07-28)."
  - "1.16 (FIX-BURST-277-WAVE-B/2026-07-28): CHECK4 closure propagation — canonicalize all 13 Module cells in §Verification Properties VP table to crate::module form (matching VP-INDEX which closed CHECK4). VP-INDEX reference in preamble updated."
  - "1.15 (FIX-BURST-275/OBS-P172b-A/2026-07-26): OBS-P172b-A — add `specs/module-criticality.md` to inputs (live architecture-view criticality registry, authoritative post-Phase 1b; the prd-supplements entry is the superseded PO draft and is retained for historical traceability). F-P172b-14 — advance timestamp to 2026-07-26."
  - "1.14 (FIX-BURST-272/DEFECT-1/2026-07-25): De-pin live-body BC version pin per TD-VSDD-091 BC-pin variant: D23 VP seeding blockquote — 'BC-2.23.005 v1.1 amended to category VAL in burst-232' → 'BC-2.23.005 §Category amended to VAL in burst-232'. Newly-authored text (v1.8 RESOLVED note), not grandfathered."
  - "1.13 (FIX-BURST-272/F-P170-19/2026-07-25): De-pin stale BC count in Subsystem Registry blockquote note: '95 BC files' → annotated historical record '(95 at the time of the D20 backfill; 129 as of D23)' to preserve context while accurately reflecting the current corpus."
  - "1.12 (FIX-BURST-265/F-P163-04/2026-07-25): Fix Canonical Crate Roster row #14 pregolya-memory Wave 2→1 (D23 item 3 promotion, consistent with Subsystem Registry SS-15 Wave 1 and module-decomposition). Per-row wave audit: all other 20 rows verified consistent with Subsystem Registry — sole mismatch was row #14. Also: frontmatter timestamp advanced to 2026-07-25."
  - "1.11 (FIX-BURST-248/F-P147-01/2026-07-24): Remove stale 'red_gate' label from D23 VP seeding note (line 179) — VP-011 is NOT Red-Gated per BC-2.05.007 red_gate: false (product-owner authority). Note corrected from 'Kani P0 red_gate' to 'Kani P0'."
  - "1.10 (2026-07-23): F-P144-03 — Document Map module-decomposition descriptor corrected 18-crate→21-crate catalog (D21 +2, D23 +1 expansions)."
  - "1.9 (burst-238/2026-07-23): Stale-handoff sweep — resolve TBD BC ranges in Subsystem Registry (SS-18 001–005, SS-19 001–006, SS-20 001–003, SS-21 001–004, SS-22 001–003; BCs authored D21 burst per bc-authoring-plan); remove stale 'BC ranges TBD' trailing clauses from D21 and D23 Capability Addition notes; resolve stale VP section note (BC-2.23.005 CONFIGURATION→VAL contradiction — content change missed in v1.8; now marked RESOLVED)."
  - "1.8 (burst-233/2026-07-22): F-P133-06 — resolve stale BC-2.23.005 Category::CONFIGURATION contradiction note in VP section callout (~L176): update to RESOLVED (BC-2.23.005 v1.1 = VAL, burst-232, consistent with error-taxonomy v1.31 and VP-013 harness)."
  - "1.7 (burst-232/2026-07-22): D23 VP loop closure — VP-011/012/013 SEEDED with BC anchors (no longer candidates); VP section total 10→13 (6 Kani P0 + 3 Kani P1 + 2 proptest P1 + 2 integration P1); VP-INDEX reference v1.4→v1.5; SS-05 BC range 001–006→001–008; SS-06 BC range 001–003→001–006; SS-10 BC range 001–004→001–006; SS-23 BC range TBD→001–006."
  - "1.6 (D23/2026-07-22): D23 architecture layer — add SS-23 (First-Party Tool Library, pregolya-tools crate #21); ADR registry 17→20 (ADR-018 per-tool-call approval hook, ADR-019 rolling context compaction, ADR-020 first-party tool library); Canonical Crate Roster 20→21 (+pregolya-tools); SS-15 wave 2→1 (CAP-017 D23 item 3); SS-16 wave 2→1 (CAP-018 D23 item 4); VP table reflects VP-INDEX v1.6 (10 VPs at D23 open; VP-011..013 minted at burst-232 bringing total to 13); VP-011/012/013 D23 candidate anchors noted; fix stale Document Map ADR count (was 13, actually 17 post-D21, now 20 post-D23); fix stale VP total in VP section header (was 5, now 10)."
  - "1.5 (D21/2026-07-20): ecosystem-parity scope expansion — add SS-18 (Prompt Templates, pregolya-prompts), SS-19 (LC Serialization, pregolya-core), SS-20 (Document Retrieval, pregolya-core + pregolya-vectorstores), SS-21 (VectorStore Abstraction, pregolya-vectorstores), SS-22 (Embeddings, pregolya-core + providers); Canonical Crate Roster 18→20 (+pregolya-prompts +pregolya-vectorstores); ADR registry 13→17 (ADR-014 VectorStore+Retriever, ADR-015 PromptInjectionSafety, ADR-016 lc-JSON safety, ADR-017 Embeddings); VP candidates noted (no new VP files yet)."
  - "1.4 (provenance-fix-169/2026-07-17): remove .factory/STATE.md from inputs (not a genuine spec-content input; D-NNN decisions are baked-in stable facts per PO corpus adjudication)."
  - "1.3 (F-P72-04/ADR-013): add ADR-013 (mcp::server module placement) to ADR registry; update SS-09 D20 capability note to attribute mcp::server to ADR-013 (not ADR-012); ADR count 12→13."
  - "1.2 (D20/CAP-021+CAP-020): SS-09 BC range 001–005→001–007 (CAP-021 MCP server role); SS-15 BC range 001–003→001–006 (CAP-020 self-improvement primitives); SS-04 001–007→001–008; SS-08 001–012→001–014; SS-13 001–006→001–007; BC total 86→95."
  - "1.1 (bursts 74–86 / 2026-07-13–14): ADR-001 through ADR-010 all accepted (ADR-001 finalised Alt B: HYBRID); VP-004 + VP-005 added (MCP integration tests); VP table gained Tool column; ADR-011 added (Cache-Key Content-Hash Contract NE-05); ADR count 10 stubs→11 files; Canonical Crate Roster section added (18-crate table derivation: D6+D1+D13+P2-05+ADR-008+D17-Q5); SS-15 crate corrected pregolya-graph→pregolya-memory; SS-16 crate corrected pregolya-graph→pregolya-core; Module Decomp description 12-crate→18-crate; status draft→active; BC count 82→86; SS-08 range 001–008→001–012. NOTE (F-P104-01, 2026-07-18): reconstructed from commit 8aebfcd (burst 86, 2026-07-14) — version was never incremented to 1.1 before jumping to 1.2 in commit 85b168f (burst 149, 2026-07-15)."
  - "1.0 (initial / 2026-07-13): initial architecture index authored — 10 ADRs in proposed/draft state; 3 Kani VPs seeded (VP-001/002/003); 17 subsystems; deployment_topology single-service. NOTE (F-P104-01, 2026-07-18): reconstructed from commit ef41eda (burst 73, 2026-07-13) — no initial changelog row was written at authoring."
---

# Architecture Index: pregolya

> **Context Engineering:** Lightweight index (~300 tokens). Load only the section
> files you need. Every section targets 800-1,200 tokens with `traces_to: ARCH-INDEX.md`.

## Document Map

| Section | File | Primary Consumer | Purpose |
|---------|------|-----------------|---------|
| System Overview | system-overview.md | orchestrator, all agents | Vision, principles, crate topology, constraints |
| Module Decomposition | module-decomposition.md | story-writer, implementer | 21-crate catalog, responsibilities, wave alignment |
| Dependency Graph | dependency-graph.md | story-writer, consistency-validator | Crate DAG, topological build order |
| API Surface | api-surface.md | test-writer, implementer | Public Rust traits, pregolya-server endpoints, Cargo features |
| Verification Architecture | verification-architecture.md | formal-verifier, architect | Provable Properties Catalog, P0/P1 VP list, proof strategy |
| Purity Boundary Map | purity-boundary-map.md | implementer, formal-verifier | Per-crate pure-core / effectful-shell classification |
| Tooling Selection | tooling-selection.md | formal-verifier | Kani, cargo-fuzz, cargo-mutants, proptest versions + config |
| Verification Coverage Matrix | verification-coverage-matrix.md | consistency-validator | VP-to-module coverage status |

**ADRs:** `.factory/specs/architecture/decisions/` — 25 files (ADR-001 to ADR-025)

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
> State-manager backfills all BC files with SS-NN after this index is committed.
> (95 at the time of the D20 backfill; 129 as of D23)

| SS ID | Name | PRD Section | Primary Crate(s) | BCs | Wave |
|-------|------|-------------|------------------|-----|------|
| SS-01 | Core Primitives | 2.01 | pregolya-core | BC-2.01.001–004 | 1 |
| SS-02 | StateGraph Definition | 2.02 | pregolya-graph | BC-2.02.001–006 | 1 |
| SS-03 | BSP Execution Engine | 2.03 | pregolya-graph | BC-2.03.001–003 | 1 |
| SS-04 | Durable Checkpointing | 2.04 | pregolya-checkpoint | BC-2.04.001–008 | 1 |
| SS-05 | HITL Interrupt / Resume | 2.05 | pregolya-graph | BC-2.05.001–008 | 1 |
| SS-06 | Streaming Event Taxonomy | 2.06 | pregolya-graph, pregolya-core | BC-2.06.001–006 | 1 |
| SS-07 | Text Splitting | 2.07 | pregolya-splitters | BC-2.07.001–003 | 1 |
| SS-08 | Provider Conformance + Standard Tests | 2.08 | pregolya-openai, pregolya-anthropic, pregolya-ollama, pregolya-standard-tests | BC-2.08.001–014 | 2 |
| SS-09 | MCP Tool Adapter | 2.09 | pregolya-mcp | BC-2.09.001–007 | 2 |
| SS-10 | Budget Governance | 2.10 | pregolya-graph | BC-2.10.001–006 | 1 |
| SS-11 | Content Provenance / Guardrail | 2.11 | pregolya-graph | BC-2.11.001–006 | 1 |
| SS-12 | Durable-Run HTTP Server | 2.12 | pregolya-server | BC-2.12.001–007 | 1 |
| SS-13 | Sandboxed Tool Execution | 2.13 | pregolya-sandbox | BC-2.13.001–007 | 1 |
| SS-14 | Typed Error Taxonomy | 2.14 | pregolya-core | BC-2.14.001–006 | 1 |
| SS-15 | Long-Horizon Memory | 2.15 | pregolya-memory | BC-2.15.001–006 | 1 |
| SS-16 | Tool Retry + Circuit Breaker | 2.16 | pregolya-core | BC-2.16.001–003 | 1 |
| SS-17 | Formal Verification Pipeline | 2.17 | xtask, pregolya-graph, pregolya-checkpoint, pregolya-sandbox | BC-2.17.001–002 | 6 |
| SS-18 | Prompt Templates | 2.18 | pregolya-prompts | BC-2.18.001–005 | 2 |
| SS-19 | LC Serialization / Round-Trip Registry | 2.19 | pregolya-core | BC-2.19.001–006 | 2 |
| SS-20 | Document Retrieval | 2.20 | pregolya-core, pregolya-vectorstores | BC-2.20.001–003 | 2 |
| SS-21 | VectorStore Abstraction | 2.21 | pregolya-vectorstores | BC-2.21.001–004 | 2 |
| SS-22 | Embeddings | 2.22 | pregolya-core, pregolya-openai, pregolya-ollama | BC-2.22.001–003 | 2 |
| SS-23 | First-Party Tool Library | 2.23 | pregolya-tools | BC-2.23.001–006 | 1 |

> **D20 Capability Additions (v1.2):** SS-09 adds CAP-021 (MCP server role) per ADR-013 — introduces `mcp::server` execution module in pregolya-mcp; BC range extended from 001–005 to 001–007. SS-15 adds CAP-020 (self-improvement primitives) per ADR-012 — includes `SkillStore`, `MemoryWriteGuard` execution modules and `ContextMutationConfig` definitions; BC range extended from 001–003 to 001–006.

> **D21 Capability Additions (v1.5):** SS-18 (Prompt Templates) via ADR-015 — pregolya-prompts new crate; injection safety pure-core guard. SS-19 (LC Serialization) via ADR-016 — core::serializable in pregolya-core; inventory-based static registry; 141 core entries + feature-gated partner registration. SS-20 (Document Retrieval) via ADR-014 — Retriever trait + Document type in pregolya-core; VectorStoreRetriever in pregolya-vectorstores. SS-21 (VectorStore Abstraction) via ADR-014 — pregolya-vectorstores new crate; in-memory backend + MMR. SS-22 (Embeddings) via ADR-017 — Embeddings trait in pregolya-core; impls in pregolya-openai + pregolya-ollama (pregolya-anthropic excluded: no embedding API).

> **D23 Capability Additions (v1.6):** SS-23 (First-Party Tool Library) via ADR-020 — pregolya-tools new crate (crate #21); tools::fs (ReadFileTool/WriteFileTool/EditFileTool/ListDirTool), tools::shell (BashTool), tools::search (GrepTool). SS-05 (HITL) extended with per-tool-call PreToolCallHook API per ADR-018 — sub-node granularity HITL (PreToolCallHook trait, PreToolDecision enum). SS-10 (Budget Governance) extended with rolling compaction primitive per ADR-019 — CompactionTrigger/CompactionPolicy/CompactionSummary types in core::budget; compaction engine in graph::budget. SS-15 (Long-Horizon Memory) promoted Wave 2→1 (CAP-017 multi-session memory, D23 item 3). SS-16 (Tool Retry + Circuit Breaker) promoted Wave 2→1 (CAP-018 tool retry, D23 item 4).

## Canonical Crate Roster (Source of Truth)

> **Authoritative.** All other documents (ADR-007, system-overview, dependency-graph) derive
> from this table. Derivation: D6 base (9) + D1 (mcp, standard-tests) + D13 (server)
> + P2-05 (sandbox, memory) + ADR-008 (macros) + D17-Q5 (3 × -sdk) + D21 (prompts, vectorstores) + D23 (tools) = **21 published crates**.

| # | Crate | Origin | Wave | Published |
|---|-------|--------|------|-----------|
| 1 | pregolya | D6 | facade | YES |
| 2 | pregolya-core | D6 | 1 | YES |
| 3 | pregolya-graph | D6 | 1 | YES |
| 4 | pregolya-checkpoint | D6 | 1 | YES |
| 5 | pregolya-openai | D6+D17-Q5 | 2 | YES |
| 6 | pregolya-anthropic | D6+D17-Q5 | 2 | YES |
| 7 | pregolya-ollama | D6+D17-Q5 | 2 | YES |
| 8 | pregolya-community | D6 | post-v1 | YES (post-v1) |
| 9 | pregolya-splitters | D6 | 1 | YES |
| 10 | pregolya-mcp | D1 | 2 | YES |
| 11 | pregolya-standard-tests | D1 | 2 | YES |
| 12 | pregolya-server | D13 | 1 | YES |
| 13 | pregolya-sandbox | P2-05 | 1 | YES |
| 14 | pregolya-memory | P2-05 | 1 | YES |
| 15 | pregolya-macros | ADR-008 | 1 | YES |
| 16 | pregolya-openai-sdk | D17-Q5 | 2 | YES |
| 17 | pregolya-anthropic-sdk | D17-Q5 | 2 | YES |
| 18 | pregolya-ollama-sdk | D17-Q5 | 2 | YES |
| 19 | pregolya-prompts | D21/ADR-015 | 2 | YES |
| 20 | pregolya-vectorstores | D21/ADR-014 | 2 | YES |
| 21 | pregolya-tools | D23/ADR-020 | 1 | YES |
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
| ADR-013 | MCP Server Module Placement in pregolya-mcp (CAP-021) | accepted — D19/D20 authority | — |
| ADR-014 | VectorStore + Retriever Abstraction (D21) | accepted — D21 authority | — |
| ADR-015 | Prompt Template Rendering and Injection Safety (D21, SECURITY-CRITICAL) | accepted — D21 authority | — |
| ADR-016 | lc-JSON Round-Trip and Deserialization Safety (D21, SECURITY-CRITICAL) | accepted — D21 authority | — |
| ADR-017 | Embeddings Trait and Provider Integration (D21) | accepted — D21 authority | — |
| ADR-018 | Per-Tool-Call Approval Hook (D23) | accepted — D23 authority | — |
| ADR-019 | Rolling Context Compaction Primitive (D23) | accepted — D23 authority | — |
| ADR-020 | First-Party Tool Library (D23) | accepted — D23 authority | — |
| ADR-021 | SecurityConfig TOML Representation and RunnableConfig.configurable Field (fix-burst-283) | accepted — architect adjudication F-P175-C101+C113 | — |
| ADR-022 | §Named-Section Citation Convention: Restriction to Real Markdown Headings (fix-burst-287) | accepted — architect adjudication F-P176-A039+E001 (Mechanism 1) | — |
| ADR-023 | #[non_exhaustive] Governance for Public API Types (fix-burst-287) | accepted — architect adjudication F-P176-A028+A029+D009+B026+C028 (Mechanism 4) | — |
| ADR-024 | WriteFileTool Create-Path Confinement Protocol (fix-burst-287 / F-P176-C002) | accepted — architect adjudication F-P176-C002 CRIT; product-owner applies to BC-2.23.002 | — |
| ADR-025 | Type Signature Canon: Object Safety and Arc Ownership Patterns (D-43, D-45, D-48) (fix-burst-287) | accepted — grounds verify-signature-canon.sh rules S1/S2/S3/S4 in citable ADR headings; hook now enforces ADR rather than defining it | — |

## Verification Properties (VP-INDEX)

13 VPs total (6 Kani P0 + 3 Kani P1 + 2 proptest P1 + 2 integration P1 — see VP-INDEX):

| VP | BC Anchor | Module | Tool | Priority | Status |
|----|-----------|--------|------|----------|--------|
| VP-001 | BC-2.03.001 (BSP determinism) | `graph::bsp_engine` | Kani | P0 | draft |
| VP-002 | BC-2.04.006 (session tenancy) | `checkpoint::session_index` | Kani | P0 | draft |
| VP-003 | BC-2.13.004 (workspace confinement) | `sandbox::path_guard` | Kani | P0 | draft |
| VP-004 | BC-2.09.004 (MCP ToolException) | `mcp::adapter` | integration | P1 | draft |
| VP-005 | BC-2.09.005 (MCP no live connections) | `mcp::client` | integration | P1 | draft |
| VP-006 | BC-2.18.004 (injection_guard fail-closed) | `prompts::injection_guard` | Kani | P1 | draft |
| VP-007 | BC-2.19.001 (serializable round-trip) | `core::serializable` | proptest | P1 | draft |
| VP-008 | BC-2.22.001 (embeddings dimension parity) | `core::embeddings` | proptest | P1 | draft |
| VP-009 | BC-2.21.003 (zero-norm guard fail-closed) | `vectorstores::similarity` | Kani | P0 | draft |
| VP-010 | BC-2.19.005 (allowlist rejects unregistered) | `core::serializable` | Kani | P0 | draft |
| VP-011 | BC-2.05.007 (PreToolCallHook fail-closed) | `graph::hitl` | Kani | P0 | draft |
| VP-012 | BC-2.10.005 (OnWatermark arithmetic) | `core::budget` | Kani | P1 | draft |
| VP-013 | BC-2.23.005 (BashTool risk floor) | `tools::shell` | Kani | P1 | draft |

> **D23 VPs SEEDED (burst-232):** VP-011/012/013 minted with BC anchors, Kani harness skeletons, and input-hashes. VP-011 (graph::hitl / PreToolCallHook fail-closed — Kani P0); VP-012 (core-budget / OnWatermark arithmetic — Kani P1); VP-013 (tools-shell / BashTool risk floor — Kani P1). BC-2.23.005 category RESOLVED: BC-2.23.005 §Postconditions (PC-4) category amended to VAL in burst-232 (error-taxonomy.md §Component: TOOLS; consistent with VP-013 harness).
