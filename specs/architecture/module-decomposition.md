---
document_type: architecture-section
level: L3
section: module-decomposition
version: "1.41"
status: active
producer: architect
timestamp: 2026-07-27T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/module-criticality.md
input-hash: "pending-FIX-BURST-275"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7, D12, D13, D17, D20, D21, D23]
changelog:
  - "1.41 (D-35-rename-sweep/2026-07-28): D-35 canonical xtask naming sweep — §xtask subcommands blockquote and list: `deny-client-new` → `check-client-timeout` (NE-04, 2 sites); `deny-expect-in-lib` → `check-no-panic` (NE-07, 2 sites); `lint-no-panic` removed from NE-07 blockquote example (was variant name, now `check-no-panic` canonical); blockquote resolution note updated from 'resolved at implementation time' to D-35 canonical-form declaration. §Provider Embeddings NE anchors: `deny-client-new` → `check-client-timeout` (1 site). Canonical `check-<subject>` form per D-35."
  - "1.40 (FIX-BURST-280-corr/F-P175-A24-followup/2026-07-28): Update `core::embeddings` description to register `validate_embedding_batch` as a `pub` free function in the module's function surface. Function is the production dimensionality validation gate for all Embeddings impls; VP-008 proptest harnesses call it directly. Visibility `pub` — cross-crate callers: ferrochain-openai and ferrochain-ollama provider embeddings impls. Criticality unchanged (HIGH; VP-008 proptest P1 drives the tier independently of function count)."
  - "1.39 (FIX-BURST-278/F-P175-D102+D110+D111+D212/2026-07-28): Four findings closed. (1) F-P175-D102 — `vectorstores::retriever` row: the lifetime-parameterized VectorStoreRetriever wrapping `&dyn VectorStore` → `VectorStoreRetriever` owning `Arc<dyn VectorStore>` (no lifetime; `'static`; per ADR-014 D-48 fix). (2) F-P175-D110+D111 — Iron Law blockquote census: `71 total (69 tiered / 2 exempt) per module-criticality.md canonical registry` clarified to attribute 71 to this file's own universe (module-decomposition.md table rows); registry total is 83 (77 tiered + 6 definitions-only/exempt). Also fix `= 77 rows total` in module-criticality.md is `= 77 tiered rows` (propagated there separately). (3) F-P175-D212 — add missing `core::tool` row (Tool trait + DynTool + ToolInput + ToolOutput; HIGH; SS-08) to ferrochain-core section; module was present in api-surface.md but absent from module-decomposition.md."
  - "1.38 (FIX-BURST-277-WAVE-B/2026-07-28): Item 6 module census — add 4 definitions-only module rows (core::guardrail SS-11, core::action_risk SS-05, core::context_mutation SS-01, core::write_guard SS-15) to the D21 additions table with Criticality `—` (matching core::documents precedent; these modules contain type/trait definitions only, no execution logic, no VP targets per ADR-009 Option 3 precedent). Add §Crate-Level Roll-Up section with 7 crate-level entries (ferrochain-anthropic, ferrochain-community, ferrochain-macros, ferrochain-ollama, ferrochain-openai, ferrochain-standard-tests, xtask) so the module census validator can resolve 4-way set equality across purity-boundary-map, verification-coverage-matrix, and module-criticality."
  - "1.37 (FIX-BURST-276-TD091/2026-07-27): TD-VSDD-091 anti-volatile-pin repair — Iron Law blockquote (§Standard Test Modules): replace live-body sibling-artifact version pin with stable section anchor. observability.md §Catalog (the Catalog table section that contains the eval.judge_infra_error row and its emitter attribution) replaces a specific version number. Sibling-sweep of this file live body: no additional version pins found."
  - "1.36 (FIX-BURST-276/F-P173-coordinator-addendum/2026-07-27): Fix phantom symbol `on_watermark` in VP anchors block (SS-23 section). Correct symbol: `check_watermark_trigger` (the real pure-core function in core::budget; `on_watermark` does not exist). Correct ADR anchor: ADR-019 Decision 3 step 1 (watermark arithmetic trigger threshold formula), not Decision 2 as previously stated. One site corrected: VP-012 anchor paragraph in §VP anchors. Sibling check: `on_watermark` does not appear in any other location in this file. VP-012 body (v1.5) and verification-architecture.md §VP-012 (v2.12) corrected to same canon by parallel VP-bodies agent in same burst."
  - "1.35 (FIX-BURST-276/F-P173-305/2026-07-27): F-P173-305 — replace stale phantom count 'Module universe 56 → 57' in Iron Law blockquote. Derivation: module-decomposition.md tables contain 69 tiered module rows (12 CRITICAL: core::error, core::credentials, core::serializable, graph::bsp_engine, graph::hitl, graph::scheduler, checkpoint::saver, checkpoint::session_index, checkpoint::clock, checkpoint::encryption, sandbox::path_guard, vectorstores::similarity; 23+ HIGH; 34+ MEDIUM; 2 LOW: xtask, ferrochain-community) + 2 exempt (core::documents definitions-only, memory::skills routing-overlay) = 71 total. The module-criticality.md canonical registry records 71 total (69 tiered / 2 exempt). Surrounding Iron Law blockquote audited: no other stale count references found in the live body. The '56 → 57' was the module-decomp's own incremental running count from the D20 gate-25 baseline — accurate at v1.32 time of writing but stale as subsequent additions in module-criticality.md (tracked in matrix v2.5/v2.6) were not reflected in the running count here."
  - "1.34 (FIX-BURST-276-WAVE-B1/F-P173-301+402/2026-07-27): F-P173-301/402 — fix eval::judge BC anchor mis-anchoring. (1) eval::judge module row in Standard Test Modules table: `(BC-2.08.013/BC-2.08.014 scope)` → `(BC-2.08.008 scope)`. Correct anchor: BC-2.08.008 = Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome (NE-15); BC-2.08.013 = Pluggable Tool-Call Dialect Seam; BC-2.08.014 = Provider Failover Chain — both are provider-behavior BCs, not eval-scoring BCs. (2) Iron Law blockquote: `BC-2.08.013/BC-2.08.014 scope the judge LLM behavior` → `BC-2.08.008 scopes the judge score aggregation behavior`; false closure claim corrected per TD-VSDD-059: the observability.md emitter linkage was restored by FIX-BURST-276-WAVE-C1 (a concurrent PO fix to observability.md v1.7), not by the Iron Law row addition in v1.32; v1.32 changelog claim 'this clears observability.md pending note' was erroneous (historical record preserved; correction is in Iron Law blockquote body text). TD-VSDD-060 sibling sweep: eval::judge BC anchor also corrected in module-criticality.md (v2.3), purity-boundary-map.md (v1.23), verification-coverage-matrix.md (v2.9) in same burst."
  - "1.33 (FIX-BURST-275-REOPENED/Defect-4/2026-07-26): Defect 4 — fix `core::serializable` Criticality HIGH → CRITICAL in D21 additions table. Rationale: module-criticality.md is the authoritative registry; registry has CRITICAL row for Reviver aspect (VP-010 Kani P0; allowlist containment security boundary per R12) and HIGH row for LcSerializable round-trip aspect (VP-007 proptest P1). Decomp takes max tier (CRITICAL); dual-aspect nature documented in description and criticality note. Registry→decomposition sweep (all 69 tiered modules): 1 divergence found and fixed (`core::serializable`: decomp=HIGH, registry-max=CRITICAL); all remaining 68 tiered modules have matching registry tiers confirmed post Wave-B fixes."
  - "1.32 (FIX-BURST-275/F-P172b-03+04+15+Iron-Law/2026-07-26): F-P172b-03 — fix tier divergences: `core::embeddings` MEDIUM → HIGH in D21 additions table (credential-bearing HTTP surface; DI-009/DI-010; VP-008 proptest P1; HIGH in module-criticality.md since v1.4 — decomp was stale); `vectorstores::similarity` MEDIUM → CRITICAL in vectorstores table (VP-009 Kani P0 target; CRITICAL in module-criticality.md since v1.4 — decomp was stale). F-P172b-03 sibling sweep (TD-VSDD-060) — raise `openai::embeddings` and `ollama::embeddings` MEDIUM → HIGH in Provider Embeddings table (both raised to HIGH in module-criticality.md as new rows in same burst; openai::embeddings is credential-bearing HTTP surface per DI-009/DI-010; ollama::embeddings has same conformance contract tier as ollama crate-level HIGH). F-P172b-04 — fix three H2 crate headings that understate max tier: `ferrochain-memory (SS-15) — MEDIUM` → `HIGH (write_guard) / MEDIUM (store, sqlite, in_memory, search, skills)`; `ferrochain-prompts (SS-18) — MEDIUM` → `HIGH (injection_guard) / MEDIUM (template, chat_template, few_shot)`; `ferrochain-vectorstores (SS-20, SS-21) — MEDIUM` → `CRITICAL (similarity) / MEDIUM (store, retriever, memory, mmr)`. F-P172b-15 sibling sweep (TD-VSDD-060) — raise `mcp::ingress` MEDIUM → HIGH in mcp table and fix section heading `ferrochain-mcp (SS-09) — MEDIUM` → `HIGH (ingress) / MEDIUM (client, discovery, adapter, server)`. F-P172b-03 sibling sweep — fix `Provider Embeddings Modules (SS-22) — MEDIUM` → `HIGH` heading (both modules raised). Iron Law gap — add `eval::judge` MEDIUM module row to Provider Crates section; add Standard Test Modules subsection; this clears observability.md pending note. OBS-P172b-A — add `specs/module-criticality.md` to inputs (live authoritative architecture-view registry; prd-supplements entry is historical PO draft). Module universe 56 → 57 (+eval::judge MEDIUM)."
  - "1.31 (FIX-BURST-274/module-universe-sweep/2026-07-26): Fix memory::skills Criticality column MEDIUM → '—' — the routing-overlay exemption (ADR-012 Decision 4; structural decomposition row only, no criticality-counted row) was declared in the surrounding block note but not reflected in the table Criticality column, creating a silent inconsistency with the established pattern (see core::documents v1.30 for precedent). Annotation added in table row. No module-universe count change (56 rows unchanged)."
  - "1.30 (FIX-BURST-274/D21-definitions-sweep/2026-07-26): core::documents definitions-only adjudication (F-P172a-04) — Criticality column MEDIUM → — (definitions-only); description extended to note definitions-only exemption per ADR-009 definitions-only precedent (ADR-014 Decision 2: pure data carrier; no execution methods; no VP target). Module universe count unchanged at 56."
  - "1.29 (FIX-BURST-273/F-P171a-02/2026-07-25): Add `tools::config` module row to ferrochain-tools (SS-23) — ToolConfig adjudication: shared per-tool framework configuration type; `override_risk(self, risk: ActionRisk) -> Result<ToolConfig, FerrochainError>` builder-consuming validator enforces per-tool risk-floor rules (E-TOOLS-007 on below-floor tier for BashTool); `#[non_exhaustive]`; construction-time validation per VP-013 postcondition (VP-013 §Source Contract PC-4 wins over BC-2.23.005 §PC-4 'register time' on lifecycle — VP-013 postcondition states `override_risk` returns `Err(E-TOOLS-007)`; BC §PC-4 needs PO correction to align); zero I/O, no async (ADR-020 Decision 3 / BC-2.23.005). Module universe 55→56 (+tools::config MEDIUM row)."
  - "1.28 (F-P170-16/burst-272/2026-07-25): Fix retired symbol name in VP-013 anchor paragraph — `BashTool::set_risk(ReadOnly)` and `set_risk(Low)` → `ToolConfig::override_risk(ActionRisk::ReadOnly)` and `ToolConfig::override_risk(ActionRisk::Low)` on a `BashTool` instance, per ADR-020 Decision 3 canonical form."
  - "1.27 (FIX-BURST-272/F-P170-06/2026-07-25): ActionRisk dependency adjudication propagation. (a) ferrochain-tools description: 'ferrochain-graph::hitl::ActionRisk' → 'ferrochain-core::ActionRisk (core::action_risk)'. (b) ferrochain-tools ADR anchor dep list: 'ferrochain-sandbox/core/graph/macros' → 'ferrochain-sandbox/core/macros' (ferrochain-graph is not a compile-time dep; ActionRisk now sourced from ferrochain-core). (c) Add core::action_risk definitions-only note to ferrochain-core D21 additions section, following core::guardrail precedent."
  - "1.26 (burst-264/F-P164-01/2026-07-25): Adjudicate canonical module name for SS-12 cron subsystem — server::cron is the canonical Rust module name (two authoritative architecture sources: module-decomp + purity-boundary-map; one BC-2.12.004 Architecture Anchors outlier used filesystem path `src/scheduler/` implying server::scheduler). Extend server::cron row description to cite canonical filesystem path `ferrochain-server/src/cron/`, locking out the drift-inducing `src/scheduler/` form. PO-owned downstream fixes listed in burst-264 report: BC-2.12.004 line 172 path and observability.md Module column."
  - "1.25 (FIX-BURST-262/F-P161-01/2026-07-25): De-pin live-body BC version pin per TD-VSDD-091 BC-pin variant: Budget definitions blockquote — BC-2.10.003 v1.2 + BC-2.10.004 → BC-2.10.003 + BC-2.10.004."
  - "1.24 (FIX-BURST-258/2026-07-24): OBS-1 — sandbox::path_guard row gains WorkspaceFs facade clause: description extended to include '`WorkspaceFs` facade routes all workspace file ops — sole permitted path for `std::fs` calls within sandbox (BC-2.13.004 INV-2)'; BC-2.13.004 Architecture Anchor already cited this clause but the row lacked it. OBS-2 — core::guardrail definitions note heading corrected: SS-20 label was the promotion-trigger subsystem (ADR-014 lives in SS-20/SS-21 RAG context), not the owning subsystem; corrected to '(SS-11 owner; promoted via ADR-014 Decision 6 [SS-20 RAG context]; DI-012, definitions-only)' — SS-11 is the content-provenance subsystem that owns GuardrailHook/BoundaryType/IngressContent (BC-2.11.001–006 all carry subsystem: SS-11). Definitions-only note sweep: Budget definitions (SS-10, line 66) and Self-improvement definitions (SS-01/SS-15, line 89) carry correct owning-subsystem labels — no changes needed. No PO-side changes required."
  - "1.23 (FIX-BURST-252/2026-07-24): F-P151-01/02/05 compaction type-canon corrections. (1) core::budget row: `fraction: f32` → `fraction: f64` in check_watermark_trigger signature (F-P151-05). (2) D23 compaction additions note: `OnWatermark{fraction: f32}` → `OnWatermark{fraction: f64}` (F-P151-05); `CompactionSummary struct (summary_text: String, compacted_range: RangeInclusive<usize>)` → `(summary_text: String, compacted_start: usize, compacted_end: usize)` (F-P151-02 flat-fields adjudication). No module-universe count change."
  - "1.22 (burst-244/2026-07-23): F-P144-01/F-P144-02 — (1) ferrochain-tools section header MEDIUM → HIGH (tools-shell) / MEDIUM (tools-fs, tools-search); tools::shell module row MEDIUM → HIGH (VP-013 Kani P1; aligns with verification-coverage-matrix.md and module-criticality.md v1.6 adjudication). (2) Add core::budget module row to ferrochain-core base table (HIGH, VP-012 Kani P1, SS-10); update budget definitions note to remove stale no-row / no-execution-logic claim (core::budget now hosts check_watermark_trigger pure-core function, not only type definitions). Module universe 54→55 (+core::budget row)."
  - "1.21 (burst-240/2026-07-23): F-P140-01 layout-adjudication clarifications — expand four ferrochain-graph module row descriptions to make the canonical flat-layout file-path mapping unambiguous for BC sweep. (1) graph::bsp_engine: add WriteRecord/PregelTask types, reduce_super_step pure-function callout (VP-001 Kani target), apply_writes callout, ferrochain-graph/src/bsp_engine.rs path. (2) graph::scheduler: add orchestrator state-machine transition sequence, ExecutionContext {run_id, parent_ids} (propagated into nested invocations), CompiledGraph::run() entry point, ferrochain-graph/src/scheduler.rs path. (3) graph::event_emitter: explicitly name StreamEvent enum and tick/after_tick emission callsites, ferrochain-graph/src/event_emitter.rs path. (4) graph::hitl: add per-task interrupt bookkeeping (InterruptScratchpad, interrupt_counter) alongside interrupt queue, ferrochain-graph/src/hitl.rs path. Architecture-doc pregel Rust-path sweep: 0 stale pregel/ paths found in architecture/ layer; no architecture-doc changes required beyond this entry."
  - "1.20 (burst-238/2026-07-23): Stale-handoff sweep (continuation) — fix graph::scheduler description: remove stale '(decision pending ADR-001 D9 gate)' note; D9 gate passed 2026-07-14, Alternative B selected per D11.1 steering (ADR-001); update description to 'Outer orchestrator loop + actor-scheduler synthesis (ADR-001 Alternative B, D9 gate passed 2026-07-14)'."
  - "1.19 (burst-238/2026-07-23): Stale-handoff sweep — (1) Fix VP-010 label in core::serializable criticality note: 'VP-010 candidate' → 'VP-010 (Kani P0, seeded burst-223)'; VP-010 was seeded in burst-223 (D21, VP-INDEX v1.2). (2) Fix VP-006 label in prompts::injection_guard criticality note: 'VP-006 candidate' → 'VP-006 (Kani P1, seeded burst-223)'. (3) Fix stale BC-2.18.001–TBD anchor in prompts BC anchors note → BC-2.18.001–005 (BCs authored in D21 burst). (4) Fix stale BC-2.20.001–TBD / BC-2.21.001–TBD in vectorstores BC anchors note → BC-2.20.001–003 (Retriever) / BC-2.21.001–004 (VectorStore) (BCs authored in D21 burst)."
  - "1.18 (burst-235/F-P135-05/2026-07-22): Add missing `sandbox::process` module row to ferrochain-sandbox (SS-13) section — ProcessBackend is a full behavioral contract (BC-2.13.002) and must appear in module-decomposition per Iron Law. Module is MEDIUM criticality (Effectful Shell; explicitly non-default, opt-in only via `unsafe_process_no_isolation()`). DI-015 co-enforcement note added: ProcessBackend enforces subprocess timeout at the sandbox layer via `.kill_on_drop(true)` (defense-in-depth beneath BashTool's outer `tokio::time::timeout`). Module universe 53→54."
  - "1.17 (burst-234/2026-07-22): TD-VSDD-060 sibling sweep — update SS-23 E-TOOLS-* count note: '8 codes post-burst-233' → '9 codes post-burst-234'; add E-TOOLS-009 InvalidRegexPattern to cite. Input-hash refresh for upstream prd.md drift."
  - "1.16 (burst-233/2026-07-22): F-P133-07 — fix SS-23 VP anchor block: VP-011 corrected from 'candidate (Kani P0) graph::hitl' to 'VP-011 (Kani P0, seeded burst-232)'; VP-012 corrected from 'candidate (integration P1) interrupt/resume' to 'VP-012 (Kani P1, seeded burst-232) — OnWatermark arithmetic, BC-2.10.005, ferrochain-core, ADR-019'; VP-013 corrected from 'candidate (Kani P0)' to 'VP-013 (Kani P1, seeded burst-232)'. F-P133-08 — fix similar crate attribution: 'dtolnay' → 'mitsuhiko'; 'MIT/Apache-2.0' → 'Apache-2.0 single-licensed'; section renamed 'Dependency research flags' → 'Validated external dependencies'; both deps marked as confirmed (ADR-020 Decision 7 v1.1). BC anchors updated to reflect SS-23 BCs as authored (BC-2.23.001..006)."
  - "1.15 (D23/2026-07-22): Add ferrochain-tools crate #21 section (SS-23): tools::fs, tools::shell, tools::search (all MEDIUM). Extend graph::hitl row for ADR-018 PreToolCallHook types. Extend core::budget definitions note for D23 compaction types (CompactionTrigger, CompactionPolicy, ConversationSnapshot, CompactionSummary — ADR-019). Extend graph::budget row for compaction engine dispatch. Note Wave 1 promotions: core::retry (SS-16) and ferrochain-memory (SS-15) per D23 items 3+4. Module universe 50→53 (+tools::fs +tools::shell +tools::search; definitions-only additions follow no-criticality-row precedent per ADR-009)."
  - "1.14 (burst-226/2026-07-21): F-P131-05 sibling sweep — prompts::injection_guard row: replace 'untrusted ProvenanceTag in TrustRequired slot' with 'TrustLevel::Untrusted in TrustRequired slot'; add note that TrustLevel is SS-18-local type distinct from core::guardrail::ProvenanceTag (SS-11) per ADR-015 v1.3 adjudication."
  - "1.13 (burst-225/2026-07-21): F-P130-01 sibling sweep — correct core::guardrail comment block: GuardrailHook method updated from wrong sync `fn check` to canonical `async fn evaluate` per interface-definitions.md §GuardrailHook; full type list (GuardrailHook, GuardrailResult, IngressContent, GuardrailSeverity, BoundaryType); rag_ingress note updated: async per-document evaluate calls per BC-2.11.003 PC5."
  - "1.12 (burst-224/2026-07-21): F-P129-11 — add vectorstores::similarity module (shared cosine_similarity primitive, VP-009 Kani target); update vectorstores::mmr description to MMR-selection-only (no longer hosts cosine_similarity); update VP anchors note. F-P129-09 — add core::guardrail definitions module (GuardrailHook trait + BoundaryType enum, promoted to ferrochain-core consistent with trait-in-core precedent); add GuardedDocuments type note to core::retriever (rag_ingress enforcement gate). Module universe 49→50 (+vectorstores::similarity MEDIUM; core::guardrail definitions-only, no criticality row per ADR-009 precedent)."
  - "1.11 (D21/2026-07-20): ecosystem-parity scope expansion — add ferrochain-prompts section (SS-18: prompts::template, prompts::chat_template, prompts::few_shot, prompts::injection_guard); add ferrochain-vectorstores section (SS-20/SS-21: vectorstores::store, vectorstores::retriever, vectorstores::memory, vectorstores::mmr); add ferrochain-core new modules: core::documents, core::retriever, core::embeddings, core::serializable; add provider embedding modules in ferrochain-openai (openai::embeddings) and ferrochain-ollama (ollama::embeddings); ferrochain-anthropic explicitly excluded from SS-22 (no embedding API). Module universe 35→49 (+14 criticality-counted rows: 4 in ferrochain-core, 4 in ferrochain-prompts, 4 in ferrochain-vectorstores, 2 in provider crates). ADRs: ADR-014/015/016/017."
  - "1.10 (F-P92-02, 2026-07-17): budget definitions note extended — RunnableConfig (core::config, SS-01) gains budget_config: Option<BudgetConfig> per OPTION A adjudication (BC-2.10.004 PC6 / BC-2.10.003 PC7/TV-004). Parallel to the context_mutations addition in the self-improvement definitions note. No new module rows — BudgetConfig is already a pure-core type in core::budget; the field addition does not change core::config's module boundary or criticality tier."
  - "1.9 (F-P91-02 sibling sweep, 2026-07-17): update budget definitions note to include OnCeiling enum and BudgetConfig struct (both newly defined in interface-definitions.md v2.29); note now lists all six core::budget types: BudgetPolicy, PolicyDecision, OnCeiling, BudgetConfig, TokenUsage, RunContext."
  - "1.8 (provenance-fix-169/2026-07-17): remove .factory/STATE.md from inputs (not a genuine spec-content input; D-NNN decisions are baked-in stable facts per PO corpus adjudication)."
  - "1.7 (F-P72-04/ADR-013): correct mcp::server attribution from ADR-012 to ADR-013; ADR-012 contains no MCP server content."
  - "1.6 (D20/CAP-021+CAP-020): add mcp::server (MEDIUM) to ferrochain-mcp for CAP-021 MCP server role; add BC anchors note to ferrochain-mcp section; update ferrochain-memory BC anchors to BC-2.15.001–006 for CAP-020. Universe 34→35 (+mcp::server MEDIUM execution row, gate #25)."
  - "1.5 (D20/ADR-012): add ferrochain-core self-improvement definitions note (core::context_mutation + core::write_guard, definitions-only, no new rows per ADR-009 precedent); add memory::skills (MEDIUM) and memory::write_guard (HIGH) module rows to ferrochain-memory per ADR-012 placements. Universe 33→34 (+memory::write_guard HIGH execution row, gate #25)."
  - "1.4 (ADV-P1D-PASS-62): F-P62-01 add deny-anyhow-in-lib (ADR-010/NE-03/DI-014) and deny-description-cache-key (ADR-011/NE-05) to xtask inventory; add non-exhaustive qualifier citing behavioral-contracts/ as authoritative subcommand registry."
  - "1.3 (ADV-P1D-PASS-61): F-P61-01 add ferrochain-core budget definitions note per ADR-009 Option 3; qualify graph::budget row to clarify trait lives in core; rename BudgetContext → RunContext per pass-61 adjudication."
  - "1.2 (ADV-P1D-PASS-37): F-P37-01 reconcile criticality column drift against authoritative module-criticality.md — core::message CRITICAL→HIGH; graph::channels CRITICAL→HIGH; graph::event_emitter HIGH→MEDIUM; ferrochain-macros section heading MEDIUM→HIGH; macros::tool/entrypoint/task all MEDIUM→HIGH."
  - "1.1 (ADV-P1D-PASS-29): F-P29-04 correct core::events description from past-tense (RunStarted/Ended, NodeStarted/Ended) to imperative canon (RunStart/Stream/End, NodeStart/Stream/End) per BC-2.06.001 authority."
  - "1.0 (initial): base module decomposition authored."
---

# Module Decomposition: ferrochain

## [Section Content]

> Per the criticality classification in `.factory/specs/module-criticality.md`.
> This file maps subsystems to internal crate modules and their responsibilities.

## ferrochain-core (SS-01, SS-06, SS-14) — CRITICAL

Responsibilities: universal composition protocol, typed message model, error taxonomy,
credential security primitives, streaming event types.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `core::runnable` | `Runnable<I,O>` trait + `RunnableSequence` pipe combinator | HIGH | SS-01 |
| `core::message` | `Message` enum (AiMessage/HumanMessage/SystemMessage/ToolMessage), ContentBlock | HIGH | SS-01 |
| `core::error` | `FerrochainError` 2D struct (Component × Category), RFC-7807 emission | CRITICAL | SS-14 |
| `core::credentials` | API key newtypes with redacted Debug; no Serialize; no Deref<Target=str> | CRITICAL | SS-14 |
| `core::events` | Streaming event taxonomy types (RunStart/Stream/End, NodeStart/Stream/End, etc.) | HIGH | SS-06 |
| `core::config` | `RunnableConfig`, `ChatConfig` structs | MEDIUM | SS-01 |
| `core::retry` | `ToolRetryPolicy` (keyed by tool_name; P-71 ADOPT), `CircuitBreaker` state machine, `RetryPolicy` with finite `global_limit: Option<NonZeroU32>`; shared combinator — provider crates and graph both route through this; **D23 item 4 (CAP-018): promoted from Wave 2 → Wave 1** | MEDIUM | SS-16 |
| `core::budget` | VP-012 Kani P1 target: pure-core `check_watermark_trigger(tokens_remaining: u64, ceiling: u64, fraction: f64) -> bool` (BC-2.10.005 watermark arithmetic — seeded burst-232; f64 precision per FIX-BURST-252 adjudication); type definitions: `BudgetPolicy` trait, `PolicyDecision` enum, `OnCeiling` enum, `BudgetConfig` struct, `TokenUsage` struct, `RunContext` struct (SS-10/ADR-009), `CompactionTrigger` enum, `CompactionPolicy` trait, `ConversationSnapshot` struct, `CompactionSummary` struct (D23/ADR-019); dispatch engine lives in `graph::budget` (ferrochain-graph); module path: `ferrochain-core/src/budget.rs` | HIGH | SS-10 |
| `core::tool` | `Tool` trait (Runnable-based; methods: `name`, `description`, `schema`, `action_risk`; `ToolInput(serde_json::Value)` newtype; `#[non_exhaustive] #[derive(Serialize)] ToolOutput` enum (Text/Json/Error)); `DynTool` object-safe façade trait (`invoke_dyn`; blanket impl for `T: Tool + Send + Sync + 'static`; `ToolOutput::Error` → `Err(FerrochainError)` per DI-014); `Arc<dyn DynTool>` is the composition seam for all dynamic tool dispatch (ADR-005 §Adjacent Adjudications; BC-2.08.010) | HIGH | SS-08 |

> **Budget definitions (SS-10 — VP-012 elevation — ADR-009 Option 3):** ferrochain-core hosts
> the DEFINITIONS for budget governance: `BudgetPolicy` trait, `PolicyDecision` enum (Allow/Escalate/Deny),
> `OnCeiling` enum (Halt/Escalate/Summarize — BC-2.10.003 + BC-2.10.004), `BudgetConfig` struct
> (soft_limit, hard_limit, on_ceiling — BC-2.10.001 TV-001–TV-003 + ADR-009), `TokenUsage` struct, and
> `RunContext` struct (fields: thread_id, run_id, sub-agent identity, budget_info per BC-2.10.001
> precondition 3). **F-P144-02 adjudication (burst-244):** `core::budget` has been elevated from definitions-only to HIGH criticality — VP-012 (Kani P1, seeded burst-232) requires `check_watermark_trigger` to live here as an executable pure-core function, not only type definitions. A criticality-counted module row now appears in the table above. The DISPATCH engine (`BudgetEngine`,
> `EvidenceJournal`) lives in ferrochain-graph::budget per the guardrail core-definitions/graph-dispatch
> split precedent. Module path: `ferrochain-core/src/budget.rs` (module `core::budget`).
> `RunnableConfig` (SS-01, `core::config`) gains `budget_config: Option<BudgetConfig>` — per-run
> budget override field (F-P92-02, OPTION A); `None` inherits `GraphConfig::budget_config`; `Some(bc)`
> overrides for that single run/resume. Used by `BudgetResume::Extend { new_ceiling }` to apply the
> extended ceiling without mutating the graph-level config (BC-2.10.004 PC6, BC-2.10.003 PC7/TV-004).
>
> **D23 compaction additions (ADR-019):** `core::budget` gains four new definitions-only types:
> `CompactionTrigger` enum (Disabled/OnWatermark{fraction: f64}/OnMessageCount{count: usize}/OnTokenCount{tokens: u64}),
> `CompactionPolicy` trait (async `compact(&ConversationSnapshot, &RunContext) -> Result<CompactionSummary, FerrochainError>`),
> `ConversationSnapshot` struct (turns: Vec<(usize, Message)>, token_estimate: u64), and `CompactionSummary`
> struct (summary_text: String, compacted_start: usize, compacted_end: usize). All definitions-only; execution
> lives in `graph::budget` (compaction engine). `BudgetConfig` gains two new fields:
> `compaction_trigger: CompactionTrigger` (default: Disabled) and
> `compaction_policy: Option<Arc<dyn CompactionPolicy>>` (None = DefaultSummarizationPolicy). No new
> criticality-counted module rows (definitions-only precedent per ADR-009 Option 3).

> **Self-improvement definitions (SS-01/SS-15, trait-definitions-only — ADR-012 D20):** ferrochain-core
> hosts DEFINITIONS for the three D20 self-improvement primitives. These are pure types and traits with
> no execution logic — no criticality-counted module rows are added for these definitions. Execution
> modules (`memory::skills`, `memory::write_guard`) live in ferrochain-memory per the
> definitions-in-core / enforcement-in-storage precedent.
>
> - `core::context_mutation` (`ferrochain-core/src/context_mutation.rs`): `ContextSourceSpec`
>   (namespace + key), `ContextMutationConfig` (Vec<ContextSourceSpec>). `RunnableConfig` (SS-01)
>   gains `context_mutations: Option<ContextMutationConfig>`. Loaded by `graph::scheduler` at run
>   start (frozen-snapshot semantics — context assembled once before first super-step; writes during
>   the run are visible at next run start only; preserves prompt-prefix caching per ADR-011/ADR-012
>   Decision 3).
>
> - `core::write_guard` (`ferrochain-core/src/write_guard.rs`): `MemoryWriteRequest` enum
>   (Add/Replace/Remove), `MemoryWriteGuard` trait (pure synchronous validation:
>   `fn validate(&self, req: &MemoryWriteRequest) -> WriteGuardDecision`), `WriteGuardDecision`
>   (Allow / Deny{reason} / Transform{sanitized}). This is the write-path analog to `GuardrailHook`
>   (ingress path). `BoundaryType` is NOT extended — write-path safety is a separate seam
>   (PASS-58 canon unchanged; BoundaryType = ToolResult|RAGRetrieval|MemoryIngress, 3 variants).

**NE anchors enforced:** NE-07 (constructor Result), NE-10 (credential opacity), NE-03 (no silent None)

## ferrochain-graph (SS-02, SS-03, SS-05, SS-10, SS-11) — CRITICAL

Responsibilities: StateGraph definition, BSP execution, HITL, budget governance,
content provenance.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `graph::definition` | `StateGraph` builder, node/edge registration, conditional routing | HIGH | SS-02 |
| `graph::channels` | LastValue / Append / BarrierValue / NamedBarrierValue / EphemeralValue reducers | HIGH | SS-02 |
| `graph::bsp_engine` | Super-step executor: task dispatch, `versions_seen` map, task-identity sort (`sort_by_task_id`), `reduce_super_step` (VP-001 pure-function Kani target), `apply_writes`, `InvalidUpdateError`; task-identity types: `WriteRecord { task_id, channel_name, value }`, `PregelTask`; `_reapply_writes_to_succeeded_nodes`; super-step-end `finish()` dispatch on channels (`ferrochain-graph/src/bsp_engine.rs`) | CRITICAL | SS-03 |
| `graph::hitl` | Interrupt queue (FIFO), suspend/resume protocol, risk-tiered classification; per-task interrupt bookkeeping: `InterruptScratchpad`, `interrupt_counter` (per-task resume-slot index); `PreToolCallHook` trait + `ToolCallPreview` + `PreToolDecision` (Approve/Deny/Edit/PendingHumanApproval) + `ToolApprovalRequest` + `AlwaysApprovePolicy` (ADR-018); `pre_tool_dispatch` routing function — fail-closed Deny invariant (VP-011, Kani P0, seeded burst-232); `GraphConfig.pre_tool_hook: Option<Arc<dyn PreToolCallHook>>` hook registration (`ferrochain-graph/src/hitl.rs`) | CRITICAL | SS-05 |
| `graph::scheduler` | Outer orchestrator loop + actor-scheduler synthesis (ADR-001 Alternative B; D9 gate passed 2026-07-14); orchestrator state machine (`Idle→Dispatching→Collecting→Reducing→Checkpointing→Idle`); actor scheduler (Tokio MPSC, `Dispatch(task_id, future)` / `Completed(task_id, output)` messages); `ExecutionContext { run_id: Uuid, parent_ids: Vec<Uuid> }` propagated into nested invocations; `CompiledGraph::run()` top-level entry point; tick() Collecting phase: LLM-call / tool-invocation evaluation callsites for budget and UntrackedValue sanitization (`ferrochain-graph/src/scheduler.rs`) | CRITICAL | SS-03 |
| `graph::budget` | `BudgetEngine` dispatch (allow/escalate/deny via `BudgetPolicy` trait from ferrochain-core), `EvidenceJournal`, ceiling halt/escalate — trait definitions live in `core::budget` per ADR-009 Option 3; compaction engine: evaluates `CompactionTrigger` after each super-step, builds `ConversationSnapshot` via `CheckpointSaver::search_history` (BC-2.04.008), calls `CompactionPolicy::compact()`, applies mid-run message-window mutation, appends `CompactionEvent` to `EvidenceJournal`, emits `compaction_event` streaming event (ADR-019) | HIGH | SS-10 |
| `graph::provenance` | `ProvenanceTag` attachment at ingress boundaries, `GuardrailHook` dispatch | HIGH | SS-11 |
| `graph::event_emitter` | `StreamEvent` enum (RunStart/Stream/End, NodeStart/End, ToolStart/End, StepEnd); streaming event emission — emission callsites inside `tick()` (NodeStart/End, ToolStart/End) and `after_tick()` (StepEnd) are in `graph::scheduler`; run_id + parent_ids correlation; `StreamEvent` base fields: `run_id: Uuid`, `parent_ids: Vec<Uuid>` (`ferrochain-graph/src/event_emitter.rs`) | MEDIUM | SS-06 |

**VP anchor:** `graph::bsp_engine` is VP-001 target (BSP determinism Kani harness).

## ferrochain-checkpoint (SS-04) — CRITICAL

Responsibilities: durable per-task checkpointing, monotonic clock, fork lineage, encryption.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `checkpoint::saver` | `CheckpointSaver` trait + `put_writes` contract | CRITICAL | SS-04 |
| `checkpoint::session_index` | Triple-address (thread_id, checkpoint_ns, checkpoint_id) enforcement | CRITICAL | SS-04 |
| `checkpoint::clock` | Monotonic logical clock; rejects wall-clock UUIDs | CRITICAL | SS-04 |
| `checkpoint::lineage` | Fork via parent_checkpoint_id; no state copy on fork | HIGH | SS-04 |
| `checkpoint::encryption` | At-rest encryption covering state AND event payloads; rotation error propagation | CRITICAL | SS-04 |
| `checkpoint::sqlite` | SQLite backend (default Cargo feature `checkpoint-sqlite`) | MEDIUM | SS-04 |
| `checkpoint::memory` | In-memory backend for tests (`checkpoint-memory` feature) | MEDIUM | SS-04 |
| `checkpoint::postgres` | PostgreSQL backend (stretch; `checkpoint-postgres` feature) | MEDIUM | SS-04 |

**VP anchors:** `checkpoint::session_index` is VP-002 target (session tenancy Kani harness).

## ferrochain-server (SS-12) — HIGH

Responsibilities: Axum HTTP server, resource CRUD, cron scheduler, security defaults.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `server::handlers` | Thread/Assistant/Run/Schedule CRUD routes | HIGH | SS-12 |
| `server::security` | `SecurityConfig::default()` deny-CORS, debug route opt-in (DI-013) | HIGH | SS-12 |
| `server::streaming` | SSE streaming endpoint; same engine as unary (DI-011) | HIGH | SS-12 |
| `server::stores` | `IdempotencyStore` / `RateLimitStore` / `RunStore` trait seams (NE-08) | HIGH | SS-12 |
| `server::cron` | CronSchedule parsing and proactive run triggering (`ferrochain-server/src/cron/`) | MEDIUM | SS-12 |

## ferrochain-sandbox (SS-13) — CRITICAL (path-guard) / MEDIUM (backends)

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `sandbox::path_guard` | `canonicalize_beneath_root(base, path)`; `Err(FerrochainError { code: "E-SBXD-001", .. })` on workspace escape; `WorkspaceFs` facade routes all workspace file ops — sole permitted path for `std::fs` calls within sandbox (BC-2.13.004 INV-2) | CRITICAL | SS-13 |
| `sandbox::wasm` | WASM execution backend (default `sandbox-wasm` feature) | MEDIUM | SS-13 |
| `sandbox::container` | Container execution backend (`sandbox-container` feature) | MEDIUM | SS-13 |
| `sandbox::seatbelt` | macOS Seatbelt deny-by-default profile (NE-16) | MEDIUM | SS-13 |
| `sandbox::process` | `ProcessBackend` — explicit non-default OS process execution; only accessible via `Sandbox::unsafe_process_no_isolation()`; provides `env_clear()` + wall-clock timeout (`tokio::process::Command` with `.kill_on_drop(true)`); WARN log on every `execute()` call; `BackendCapabilities { filesystem_isolated: false, network_isolated: false, memory_bounded: false }`; DI-015 co-enforcer at sandbox layer via `.kill_on_drop(true)` — ensures subprocess is killed on Future drop when BashTool's outer `tokio::time::timeout` fires (BC-2.13.002 / SS-13) | MEDIUM | SS-13 |
| `sandbox::policy` | `SandboxPolicy` enforcement; Err(PolicyNotEnforceable) on mismatch | MEDIUM | SS-13 |

**VP anchor:** `sandbox::path_guard` is VP-003 target (workspace confinement Kani harness).

## ferrochain-splitters (SS-07) — MEDIUM

| Module | Responsibility | Criticality |
|--------|---------------|-------------|
| `splitters::recursive` | Recursive character splitter; Unicode code-point boundary counting | MEDIUM |
| `splitters::parity` | Golden-vector parity tests vs Python reference (R8 Red Gate coverage) | MEDIUM |

## Provider Crates and Standard Tests (SS-08) — HIGH

Each provider is split into **two separate Cargo crates** per D17-Q5 / ADR-007 / BC-2.08.006:

| Crate | Role | ferrochain-core dep |
|-------|------|---------------------|
| `ferrochain-openai-sdk` | OpenAI wire client (HTTP, SSE, types) | NO |
| `ferrochain-openai` | `impl BaseChatModel` for ChatOpenAI; translation | YES |
| `ferrochain-anthropic-sdk` | Anthropic wire client | NO |
| `ferrochain-anthropic` | `impl BaseChatModel` for ChatAnthropic | YES |
| `ferrochain-ollama-sdk` | Ollama wire client | NO |
| `ferrochain-ollama` | `impl BaseChatModel` for ChatOllama (no API key newtype) | YES |
| `ferrochain-standard-tests` | Shared conformance test suite; all adapter crates as dev-dep | YES |

The SDK crates have no ferrochain-core dep and are publishable standalone. Enforced by CI:
`cargo check -p ferrochain-<provider>-sdk` must succeed without ferrochain-core in Cargo.lock.

### Standard Test Modules

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `eval::judge` | LLM judge execution for conformance evaluation; invokes a configurable judge LLM to score implementation outputs against golden answers; emits `eval.judge_infra_error` structured event on judge call failure (observability.md); `JudgeError` propagated as `FerrochainError`; async / Effectful Shell (BC-2.08.008 scope) | MEDIUM | SS-08 |

> **Iron Law — eval::judge (FIX-BURST-275):** `ferrochain-standard-tests` provides `eval::judge`
> as the LLM judge execution module for conformance scoring. The `eval.judge_infra_error` event
> type in observability.md names this module as the emitter (restored in observability.md §Catalog
> via FIX-BURST-276-WAVE-C1, a concurrent PO fix; the emitter linkage was not yet present in
> observability.md when this Iron Law row was added in v1.32 — see v1.32 changelog correction
> in v1.34). Behavioral contract BC-2.08.008 scopes the judge score aggregation behavior.
> The module has observable behavior (structured event emission, error propagation) and BC
> coverage — it therefore satisfies Iron Law criteria requiring a module-level row. The
> pre-existing `ferrochain-standard-tests` crate-level row in module-criticality.md remains
> as a crate-level annotation; `eval::judge` is the module-level row that satisfies Iron Law.
> Current module universe: 71 total (69 tiered / 2 exempt: `core::documents`, `memory::skills`) by this file's own table rows. The module-criticality.md registry total is 83 (77 tiered + 6 definitions-only/exempt rows added in FIX-BURST-277) — the difference is the 6 definitions-only/exempt module rows and the 6 crate-level roll-up rows that appear in the registry but are not in this file's tiered table. `eval::judge` was the 57th module when added in v1.32 by the module-decomp's own running count from gate-25 baseline; the canonical registry subsequently recorded additional modules (tracked in matrix v2.5/v2.6) bringing the total to 71.

## ferrochain-mcp (SS-09) — HIGH (ingress) / MEDIUM (client, discovery, adapter, server)

| Module | Responsibility | Criticality |
|--------|---------------|-------------|
| `mcp::client` | `MultiServerMcpClient`; no live connections until invoke (R11) | MEDIUM |
| `mcp::discovery` | Tool discovery and registration from MCP server at runtime | MEDIUM |
| `mcp::adapter` | `ToolInvocation` routing; ToolException re-raise with type identity (R11) | MEDIUM |
| `mcp::ingress` | Untrusted-ingress routing; DI-012 guardrail seam; external untrusted-input entry point for tool invocations arriving from MCP clients (BC-2.09.003) | HIGH |
| `mcp::server` | MCP server endpoint: exposes registered tools to external MCP clients; accepts inbound tool-call requests, dispatches to registered tools, and returns serialized responses (CAP-021/D20/ADR-013) | MEDIUM |

**BC anchors:** BC-2.09.001–007 (CAP-021: BCs 006–007 cover server-side tool exposure and response serialization contracts).

**VP anchors:** `mcp::adapter` is VP-004 target; `mcp::client` is VP-005 target (both integration-tier, Phase 3).

## ferrochain-memory (SS-15) — HIGH (write_guard) / MEDIUM (store, sqlite, in_memory, search, skills)

Responsibilities: long-horizon memory persistence (KV + vector), GDPR erasure protocol,
search (keyword / vector / hybrid). Canonical trait: `MemoryStore`.
**D23 item 3 (CAP-017): promoted from Wave 2 → Wave 1.**

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `memory::store` | `MemoryStore` trait (KV + vector ops, GDPR erasure) | MEDIUM | SS-15 |
| `memory::sqlite` | SQLite durable backend implementation | MEDIUM | SS-15 |
| `memory::in_memory` | Ephemeral in-memory backend (test/dev) | MEDIUM | SS-15 |
| `memory::search` | Keyword, vector, and hybrid search implementations | MEDIUM | SS-15 |
| `memory::skills` | `SkillStore` trait + `SkillDescriptor`; routing/discovery overlay over `MemoryStore` KV; load-on-demand skill documents by name/tags; **routing-overlay — no criticality-counted module row per ADR-012 Decision 4** (structural decomposition row only; all execution dispatch delegated to `MemoryStore` backend) (D20/ADR-012) | — | SS-15 |
| `memory::write_guard` | Guarded write enforcement engine: calls `MemoryWriteGuard::validate()` (from `core::write_guard`) before committing writes; injection scanning dispatch; blocks or sanitizes writes per `WriteGuardDecision`; security-significant write-path seam (D20/ADR-012) | HIGH | SS-15 |

**BC anchors:** BC-2.15.001–006 (CAP-020: BCs 004–006 cover self-improvement primitives — `SkillStore` routing overlay, `MemoryWriteGuard` execution enforcement, and `ContextMutationConfig` assembly). Canonical trait name: `MemoryStore` per BC-2.15.001 Architecture Anchors.

> **Self-improvement execution note (D20/ADR-012):** `memory::skills` provides `SkillStore`
> trait + `SkillDescriptor` types as a routing overlay over `MemoryStore`. Skill documents are
> ordinary KV entries under a skills namespace; `SkillStore` adds naming, tagging, and
> load-on-demand semantics. Write path for skill documents passes through `memory::write_guard`
> (guarded write enforcement). `memory::write_guard` is the execution counterpart of
> `core::write_guard` (definitions-only, ferrochain-core) — same split as ADR-009 Option 3
> (BudgetPolicy trait in core / BudgetEngine dispatch in graph). Universe updated to 34 (gate #25):
> +1 HIGH execution row (`memory::write_guard`); definitions-only entries (`core::context_mutation`,
> `core::write_guard`) and routing-overlay entry (`memory::skills`) follow the no-criticality-row
> precedent — `memory::skills` has a structural decomposition row here but no criticality-counted
> row (ADR-012 Decision 4). Universe further updated to 35 in v1.6 (gate #25): +1 MEDIUM execution
> row (`mcp::server`, CAP-021/D20/ADR-013).

## ferrochain-macros (ADR-008) — HIGH

Responsibilities: proc-macro crate for `#[tool]`, `#[entrypoint]`, `#[task]`.
Re-exported from ferrochain-core.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `macros::tool` | `#[tool]` proc-macro: `Tool` implementor with JSON Schema derivation | HIGH | SS-08 |
| `macros::entrypoint` | `#[entrypoint]` proc-macro: START edge wiring for StateGraph nodes | HIGH | SS-08 |
| `macros::task` | `#[task]` proc-macro: task registration boilerplate | HIGH | SS-08 |

**BC anchors:** BC-2.08.010, BC-2.08.011, BC-2.08.012 (all active, authored Phase 1b).

## xtask (SS-17 support) — LOW

> **Inventory scope (non-exhaustive):** This list covers subcommands explicitly cited in
> architecture/ ADRs and the NE Disposition Table (PRD §9) as sole enforcement mechanisms.
> The authoritative registry for all CI lint gate contracts — including exact subcommand
> names and their acceptance criteria — is the behavioral-contracts/ directory
> (BC-2.14.003–006, BC-2.08.007) and individual ADRs. Subcommand names are canonical per
> D-35 (`check-<subject>` form); pre-D-35 variants (`deny-client-new`, `lint-no-timeout`,
> `deny-expect-in-lib`, `lint-no-panic`) are superseded and must not be used.

- `check-file-size`: file line-count gate (D12); reads allowlist.toml
- `check-client-timeout`: CI lint gate; rejects `Client::new()` outside tests (NE-04)
- `check-no-panic`: CI lint gate; rejects `.expect()` and `.unwrap()` in library code (NE-07)
- `deny-anyhow-in-lib`: CI lint gate; scans library crate `src/` for `anyhow` imports; sole enforcement of NE-03 / DI-014 anyhow confinement — `anyhow` is banned from all `ferrochain-*` library crates (ADR-010)
- `deny-description-cache-key`: CI lint gate; scans `cache_key` / `CacheKey` / `cache_key_for` call sites in `ferrochain-*` library crates for description-proxy usage; sole enforcement of NE-05 content-hash cache-key contract (ADR-011)

## ferrochain-core — D21 additions (SS-19, SS-20, SS-22)

> **New modules added in D21.** These extend ferrochain-core without adding new Cargo
> dependencies beyond `inventory` (for `core::serializable` registry) and `async-trait`
> (already present for existing async traits).

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `core::documents` | `Document { page_content, metadata, id }` type — carrier for all retrieval output; derives Serialize/Deserialize/JsonSchema; `#[non_exhaustive]`; **definitions-only — no criticality-counted module row per ADR-009 definitions-only precedent** (ADR-014 Decision 2: pure data carrier; no execution methods; no VP target) | — | SS-20 |
| `core::guardrail` | Definitions-only: `GuardrailHook` trait (`async fn evaluate`), `GuardrailResult` enum, `IngressContent` enum, `GuardrailSeverity` enum, `BoundaryType` enum (3 variants: ToolResult/RAGRetrieval/MemoryIngress); promoted to ferrochain-core per trait-in-core precedent (ADR-014 Decision 6 / DI-012); no execution logic; dispatch in `graph::provenance` and `mcp::ingress` | — | SS-11 |
| `core::action_risk` | Definitions-only: `ActionRisk` enum (4 variants: ReadOnly/Low/Medium/High); `#[non_exhaustive]`; relocated from `graph::hitl` per dependency-inversion precedent enabling ferrochain-tools compile-time access without ferrochain-graph dep (F-P170-06 / ADR-020 Decision 3) | — | SS-05 |
| `core::context_mutation` | Definitions-only: `ContextSourceSpec` (namespace + key), `ContextMutationConfig` (`Vec<ContextSourceSpec>`); enables `RunnableConfig.context_mutations`; loaded by `graph::scheduler` at run start; no execution logic (ADR-012 D20) | — | SS-01 |
| `core::write_guard` | Definitions-only: `MemoryWriteRequest` enum (Add/Replace/Remove), `MemoryWriteGuard` trait (sync validation: `fn validate -> WriteGuardDecision`), `WriteGuardDecision` (Allow/Deny/Transform); write-path safety seam definitions; enforcement execution in `memory::write_guard` (ADR-012 D20) | — | SS-15 |
| `core::retriever` | `Retriever` trait: async dyn-compatible `get_relevant_documents(&self, query: &str)`; `Arc<dyn Retriever>` seam for graph RAG nodes; `GuardedDocuments` newtype (no public constructor) + `GuardedDocuments::rag_ingress(docs, guardrail)` sole constructor enforcing DI-012 RAGRetrieval guardrail at call time (ADR-014 Decision 6) | MEDIUM | SS-20 |
| `core::embeddings` | `Embeddings` trait: async dyn-compatible `embed_documents` + `embed_query`; dimensionality contract (E-EMBED-001 on mismatch); no `ndarray` dep; credential-bearing HTTP surface (DI-009 timeout + DI-010 key opacity apply to all impls); VP-008 proptest P1. `pub fn validate_embedding_batch(texts: &[String], vecs: &[Vec<f32>]) -> Result<(), FerrochainError>` — production dimensionality gate called by all Embeddings impls; visibility `pub` (cross-crate callers: ferrochain-openai, ferrochain-ollama) | HIGH | SS-22 |
| `core::serializable` | `LcSerializable` trait + `Serialized` wire enum + `Reviver` + `inventory`-based static registry (141 core entries); valid-namespace `OnceLock<HashSet>` derived from registry; E-SRLZ-001/002 error codes; dual-aspect: Reviver (CRITICAL/VP-010 Kani P0 — allowlist containment security boundary) + LcSerializable round-trip (HIGH/VP-007 proptest P1) | CRITICAL | SS-19 |

> **core::serializable criticality (CRITICAL/HIGH dual-aspect):** this module hosts two
> verification properties with different tiers. **Reviver aspect (CRITICAL):** deserialization of
> external lc-JSON blobs is a security-sensitive surface (R12); the Reviver enforces an
> allowlist-by-registration safety property; VP-010 (Kani P0, seeded burst-223) proves allowlist
> containment. CRITICAL: Kani P0 VP target + security boundary (external deserialization allowlist).
> **LcSerializable round-trip aspect (HIGH):** VP-007 (proptest P1) tests round-trip fidelity of
> lc-JSON serialization. HIGH: proptest P1 VP host. Decomp table takes max tier (CRITICAL); both
> aspects are tracked as separate registry rows in module-criticality.md (Reviver / LcSerializable
> round-trip). Tier corrected from HIGH → CRITICAL in FIX-BURST-275-reopened per registry authority.

> **NE anchors:** `core::documents` — #[non_exhaustive] required (public API type per workspace
> convention). `core::embeddings` — DI-009 timeout applies to provider impls; DI-014 no silent
> empty returns applies to batch operations. `core::serializable` — DI-010 secret opacity
> enforced via `lc_secrets()` stripping; DI-014 no silent None on unregistered types.

> **Guardrail definitions (SS-11 owner; promoted via ADR-014 Decision 6 [SS-20 RAG context]; DI-012, definitions-only):** ferrochain-core
> hosts DEFINITIONS for the DI-012 guardrail interface promoted in burst-224 (F-P129-09). These are
> pure type and trait definitions with no execution logic — no criticality-counted module row per
> ADR-009 definitions-only precedent.
>
> - `core::guardrail` (`ferrochain-core/src/guardrail.rs`): `GuardrailHook` trait (canonical
>   `async fn evaluate(&self, content: IngressContent, provenance_tag: ProvenanceTag) -> GuardrailResult`
>   per interface-definitions.md §GuardrailHook — `#[async_trait]` desugared; definitions-only,
>   no execution logic in trait body); `GuardrailResult` enum (Pass | Fail{reason,severity} |
>   Transform{new_content}); `IngressContent` enum (ToolResult(ContentBlock) | RagChunk(Value) |
>   MemoryItem(Value)); `GuardrailSeverity` enum (Critical/High/Medium/Low); `BoundaryType` enum
>   (ToolResult | RAGRetrieval | MemoryIngress — 3 variants, PASS-58 canon; not extended).
>   Promoted from graph::provenance/mcp::ingress to ferrochain-core consistent with trait-in-core
>   precedent (BudgetPolicy → core::budget, MemoryWriteGuard → core::write_guard). Existing
>   dispatch modules (graph::provenance, mcp::ingress) import from ferrochain-core.
>
> `core::retriever` gains `GuardedDocuments` (private-field newtype wrapping `Vec<Document>` with
> no external constructor) and `GuardedDocuments::rag_ingress(docs, &dyn GuardrailHook) async →
> Result<GuardedDocuments, FerrochainError>` as the sole public constructor — per-document async
> `evaluate` calls per BC-2.11.003 PC5. Graph nodes that inject retrieved documents into context
> accept `&GuardedDocuments`, making bypass a compile-time type error
> (ADR-014 Decision 6 / BC-2.20.002 VP upgrade).

> **ActionRisk definitions (SS-05 owner; relocated from graph::hitl per F-P170-06 adjudication; definitions-only):** ferrochain-core
> hosts DEFINITIONS for the ActionRisk risk-classification enum, relocated from `ferrochain-graph::hitl`
> following the dependency-inversion precedent established by BudgetPolicy (ADR-009 Option 3),
> GuardrailHook/BoundaryType (ADR-014 Decision 6), and MemoryWriteGuard (ADR-012). This relocation
> is required so that `ferrochain-tools` (Wave 1 position 7) can use ActionRisk at compile time
> without taking a `ferrochain-graph` dependency (Wave 1 position 8). No execution logic; no
> criticality-counted module row per ADR-009 definitions-only precedent.
>
> - `core::action_risk` (`ferrochain-core/src/action_risk.rs`): `ActionRisk` enum — 4 variants:
>   `ReadOnly`, `Low`, `Medium`, `High`. `#[non_exhaustive]` per workspace convention. BC-2.05.006
>   anchor preserved. `ferrochain-graph` re-exports `core::action_risk::ActionRisk` as
>   `ferrochain_graph::hitl::ActionRisk` for existing graph-layer consumers (zero BC changes required).

## ferrochain-prompts (SS-18) — HIGH (injection_guard) / MEDIUM (template, chat_template, few_shot)

Responsibilities: prompt template construction (PromptTemplate, ChatPromptTemplate,
MessagesPlaceholder, FewShot*), f-string rendering engine, optional mustache/jinja2,
injection safety guard (pure-core blocker for untrusted content in system-position slots).

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `prompts::template` | `PromptTemplate`; f-string engine (in-house, no external dep); variable extraction at construction; `.partial()` builder | MEDIUM | SS-18 |
| `prompts::chat_template` | `ChatPromptTemplate` + `MessagesPlaceholder`; multi-message template; `PromptValue` output with per-message `MessageProvenance` | MEDIUM | SS-18 |
| `prompts::few_shot` | `FewShotPromptTemplate`; example selectors; snapshot-frozen golden fixture tests | MEDIUM | SS-18 |
| `prompts::injection_guard` | `SlotTrustPolicy` enum; SystemMessage-slot `TrustRequired` immutable enforcement; render-time `E-TMPL-001` blocker for `TrustLevel::Untrusted` in `TrustRequired` slot; pure-core, no I/O; `TrustLevel` is SS-18-local type distinct from `core::guardrail::ProvenanceTag` (SS-11) | HIGH | SS-18 |

> **prompts::injection_guard criticality (HIGH):** the injection blocker is a security-critical
> pure-core module. It must prevent untrusted content from reaching SystemMessage positions
> regardless of caller configuration. VP-006 (Kani P1, seeded burst-223): Kani proof that untrusted-tagged
> variable substitution into a TrustRequired slot always returns Err (never renders).
> Consistent with the production-grade default — security invariants enforced by construction.

> **BC anchors:** BC-2.18.001–005. ADR-015 governs the trust model and engine selection.

## ferrochain-vectorstores (SS-20, SS-21) — CRITICAL (similarity) / MEDIUM (store, retriever, memory, mmr)

Responsibilities: `VectorStore` trait (async dyn-compatible), `VectorStoreFactory` (Sized-bounded
constructor pattern), in-memory VectorStore backend, MMR selection algorithm, `VectorStoreRetriever`.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `vectorstores::store` | `VectorStore` trait (`add_texts`, `similarity_search`, `similarity_search_with_score`, `max_marginal_relevance_search`, `delete`, `as_retriever`); `VectorStoreFactory` trait; `MetadataFilter` type | MEDIUM | SS-21 |
| `vectorstores::retriever` | `VectorStoreRetriever` owning `Arc<dyn VectorStore>` (no lifetime; `'static`; satisfies `Arc<dyn Retriever + 'static>`); impl `Retriever`; `SearchType` enum (`#[non_exhaustive]`; Similarity / SimilarityScoreThreshold / Mmr) | MEDIUM | SS-20 |
| `vectorstores::memory` | In-memory VectorStore backend; `Arc<dyn Embeddings>` injection via constructor; interior mutability via `RwLock`; `Vec<f32>` cosine similarity; no `ndarray` dep | MEDIUM | SS-21 |
| `vectorstores::similarity` | Shared cosine similarity primitive: `cosine_similarity(a: &[f32], b: &[f32]) → Result<f32, FerrochainError>`; zero-norm IEEE-754 guard (E-VS-001) before division; pure `Vec<f32>` inner product, no `ndarray`, no I/O; called by `vectorstores::memory`, `vectorstores::mmr`, and any future VectorStore backend | CRITICAL | SS-21 |
| `vectorstores::mmr` | Maximal Marginal Relevance selection algorithm; calls `vectorstores::similarity::cosine_similarity` for pairwise similarity + diversity penalty; `lambda_mult` ∈ [0.0, 1.0] parameter; pure math, no I/O | MEDIUM | SS-21 |

> **VP anchors:** `vectorstores::similarity` is VP-009 target (Kani P0 proof that `cosine_similarity`
> returns `Err(E-VS-001)` and never `Ok(f32::NAN)` when either vector norm is 0.0; BC-2.21.003).
> `vectorstores::memory` in-memory backend serves as the integration test double for
> VectorStore conformance tests (analogous to `checkpoint::memory` for checkpoint backends).

> **BC anchors:** BC-2.20.001–003 (Retriever), BC-2.21.001–004 (VectorStore). ADR-014 governs
> trait shapes, factory pattern, SS-15 boundary, and inventory extension seam.

## Provider Embeddings Modules (SS-22) — HIGH

Each embedding-capable provider crate gains a new `<provider>::embeddings` module.
ferrochain-anthropic is EXCLUDED — Anthropic provides no public embeddings API (ADR-017).

| Module | Crate | Responsibility | Criticality | SS |
|--------|-------|---------------|-------------|-----|
| `openai::embeddings` | ferrochain-openai | `EmbeddingsOpenAI` impl of `Embeddings` trait; `/v1/embeddings` endpoint; models: text-embedding-3-small/large, text-embedding-ada-002; `OpenAiApiKey` newtype (DI-009/DI-010 credential-bearing HTTP surface); reqwest rustls-tls; 30s timeout | HIGH | SS-22 |
| `ollama::embeddings` | ferrochain-ollama | `EmbeddingsOllama` impl of `Embeddings` trait; `/api/embeddings` endpoint; model-configurable (nomic-embed-text, mxbai-embed-large, etc.); no API key; reqwest rustls-tls; 30s timeout; same conformance contract tier as ollama BaseChatModel crate-level | HIGH | SS-22 |

> **NE anchors (both embedding modules):** DI-009 (mandatory timeout); DI-010 (OpenAI key is
> `OpenAiApiKey` newtype with redacted Debug); DI-014 (batch failures return Err, not Vec::new()).
> xtask `check-client-timeout` CI gate enforces the reqwest timeout requirement at the workspace level.

## ferrochain-tools (SS-23) — HIGH (tools-shell) / MEDIUM (tools-fs, tools-search)

Responsibilities: first-party file I/O, bash execution, and text-search tools;
implements the `Tool` trait (ferrochain-core) with sandbox path-guard integration
(ferrochain-sandbox) and risk-tier defaults (ferrochain-core::ActionRisk via
`core::action_risk`; relocated from `ferrochain-graph::hitl` per F-P170-06 adjudication).
Crate #21. **D23 item 5 / Wave 1.**

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `tools::config` | `ToolConfig` — shared per-tool framework configuration; `override_risk(self, risk: ActionRisk) -> Result<ToolConfig, FerrochainError>` builder-consuming validator that enforces per-tool risk-floor rules (E-TOOLS-007 on below-floor tier for BashTool); `#[non_exhaustive]`; zero I/O, no async; construction-time validation per VP-013 §Source Contract (ADR-020 Decision 3 / BC-2.23.005 / SS-23) | MEDIUM | SS-23 |
| `tools::fs` | `ReadFileTool`, `WriteFileTool`, `EditFileTool`, `ListDirTool` — all path-guarded via `sandbox::path_guard`; `ReadFileTool` enforces `max_bytes` limit (default 1 MiB; E-TOOLS-002 on excess); `EditFileTool` exact-string replace (E-TOOLS-003 on old_string not found); opt-in fuzzy fallback via `EditConfig::fuzzy_threshold` with `similar` crate; `WriteFileTool`/`EditFileTool` default `ActionRisk::High`; `ReadFileTool`/`ListDirTool` default `ActionRisk::ReadOnly` (ADR-020 / SS-23) | MEDIUM | SS-23 |
| `tools::shell` | `BashTool` — subprocess execution via ferrochain-sandbox backend (WASM or container); stdout/stderr/exit-code capture in `BashOutput`; `max_output_bytes` truncation with `BashOutput::truncated: bool` (E-TOOLS-005 advisory); 30s timeout default (E-TOOLS-004 on timeout); default `ActionRisk::High`; minimum risk floor `ActionRisk::Medium` — configuration error if caller attempts `ReadOnly` or `Low` (E-TOOLS-007) (ADR-020 / SS-23) | HIGH | SS-23 |
| `tools::search` | `GrepTool` — in-process regex search via `regex` crate; path-guarded directory traversal via `sandbox::path_guard`; `max_results` cap (E-TOOLS-006 advisory); default `ActionRisk::ReadOnly`; accepts `{pattern, path, recursive, case_insensitive, max_results}` (ADR-020 / SS-23) | MEDIUM | SS-23 |

**ADR anchor:** ADR-020 governs crate placement (separate from ferrochain-sandbox), dependency
graph (ferrochain-tools → ferrochain-sandbox/core/macros, one-way; no ferrochain-graph
compile-time dep; ActionRisk sourced from ferrochain-core per F-P170-06),
risk tier defaults, retry classification, and `E-TOOLS-*` error namespace.

**VP anchors:**
- VP-011 (Kani P0, seeded burst-232) — `graph::hitl::pre_tool_dispatch`: fail-closed Deny;
  Deny never allows tool invocation (ADR-018 Decision 3 / BC-2.05.007).
- VP-012 (Kani P1, seeded burst-232) — OnWatermark arithmetic: `check_watermark_trigger` never produces
  a token count exceeding the hard limit; no overflow; BC-2.10.005, ferrochain-core,
  core::budget (ADR-019 Decision 3 step 1).
- VP-013 (Kani P1, seeded burst-232) — `ToolConfig::override_risk(ActionRisk::ReadOnly)` and `ToolConfig::override_risk(ActionRisk::Low)`
  on a `BashTool` instance always return `Err(E-TOOLS-007)`, never succeed (ADR-020 Decision 3 / BashTool risk floor /
  BC-2.23.005).

**Validated external dependencies (ADR-020 Decision 7):**
- `similar` crate (mitsuhiko) — fuzzy-match fallback for EditFileTool; pinned `"3"` (3.1.1,
  Apache-2.0 single-licensed, MSRV 1.85). Confirmed ADR-020 Decision 7 v1.1.
- `regex` crate — GrepTool in-process pattern engine; pinned `"1"` (1.13.1, MIT/Apache-2.0,
  linear-time DFA, net-new dep). Confirmed ADR-020 Decision 7 v1.1.

**BC anchors:** BC-2.23.001 (ReadFileTool), BC-2.23.002 (WriteFileTool), BC-2.23.003
(EditFileTool), BC-2.23.004 (ListDirTool), BC-2.23.005 (BashTool, VP-013 seed),
BC-2.23.006 (GrepTool). `E-TOOLS-*` error namespace: 9 codes post-burst-234
(E-TOOLS-008 FileIoError added burst-233; E-TOOLS-009 InvalidRegexPattern added burst-234).

## Crate-Level Roll-Up (Cross-Subsystem Annotation)

> The following crates do not decompose into subsystem-owned modules in this file.
> They are provider impl crates, a proc-macro crate, a shared test suite, and a
> workspace build-tool. They appear as crate-level annotation rows (Qualifier prefix
> "crate-level") in verification-coverage-matrix.md, module-criticality.md, and
> purity-boundary-map.md. This table ensures 4-way set equality in the module census
> validator (verify-module-canonicality.sh).

| Module | Role |
|--------|------|
| `ferrochain-anthropic` | Provider impl crate — `BaseChatModel` for Claude API; implements ferrochain-core traits; crate-level annotation only |
| `ferrochain-community` | Community extensions crate — third-party integrations; crate-level annotation only |
| `ferrochain-macros` | Proc-macro crate — `#[tool]`, `#[entrypoint]`, `#[task]` attribute macros; no public traits; crate-level annotation only |
| `ferrochain-ollama` | Provider impl crate — `BaseChatModel` + `Embeddings` for Ollama; crate-level annotation only |
| `ferrochain-openai` | Provider impl crate — `BaseChatModel` + `Embeddings` for OpenAI; crate-level annotation only |
| `ferrochain-standard-tests` | Shared conformance test suite + `eval::judge` module; test-only crate; crate-level annotation only |
| `xtask` | Workspace task runner — `check-file-size`, lint gate subcommands (SS-17 support); crate-level annotation only |
