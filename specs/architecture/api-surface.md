---
document_type: architecture-section
level: L3
section: api-surface
version: "1.17"
status: active
producer: architect
timestamp: 2026-07-27T00:00:00Z
changelog:
  - "1.17 (FIX-BURST-277-WAVE-B-errata/2026-07-28): Correct Wave C DynTool migration list blockquote — prior v1.16 cited BC-2.05.003/BC-2.05.004/BC-2.08.010/BC-2.09.001 as `dyn Tool` sites; corpus re-verification found zero `dyn Tool` in BC-2.05.003/BC-2.05.004/BC-2.08.010 and ToolCallPreview never had a `tool` field. Corrected list: BC-2.09.001 (Description+PC2) and BC-2.09.002 (PC1) — both cite `Arc<dyn ferrochain_core::Tool>` in MCP tool discovery/invocation context. ADR-005 v1.9 carries the same correction."
  - "1.16 (FIX-BURST-277-WAVE-B/2026-07-28): Three api-surface propagations from fix-burst 277. (1) DynTool — add DynTool row to §Public Rust Traits (ferrochain-core): DynTool is the type-erased object-safety seam for Arc<dyn Tool> dispatch; Tool inherits Runnable::stream (opaque impl Stream return) and Runnable::pipe (impl Runnable + where Self: Sized), making direct dyn Tool non-trivially non-object-safe (E0038 fires on direct dyn Tool); blanket impl: T: Tool + Send + Sync + 'static auto-implements DynTool; SS-08, BC-2.08.010 (ADR-005 v1.8 §Adjacent Trait Object-Safety Adjudications). (2) VectorStoreRetriever lifetime + as_retriever fallibility — fix stale blockquote in §Public Traits (ferrochain-vectorstores): remove VectorStoreRetriever<'_> lifetime annotation; document store: Arc<dyn VectorStore> field enabling Retriever + 'static coercion so Arc<dyn Retriever> compiles; document fallible signature as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError> with Err(E-VS-003) on invalid config (ADR-014 v1.11 Decision 2). (3) FerrochainError constructor — add construction note to §Error Type: FerrochainError::new(component, category, retry_hint, code, message: impl Into<String>) and .with_source(Arc<dyn Error + Send + Sync>) are sole sanctioned construction paths; struct literal construction barred by #[non_exhaustive] from external crates (ADR-010 v1.13 §impl FerrochainError)."
  - "1.15 (FIX-BURST-276-TD091/2026-07-27): TD-VSDD-091 anti-volatile-pin repair — §Error Type source field inline comment: replace live-body sibling-artifact version pin with stable section anchor. ADR-010 §Decision (the section containing the FerrochainError struct definition and the Arc-not-Box source field rationale) replaces a specific version number. Sibling-sweep of this file live body: no additional version pins found."
  - "1.14 (FIX-BURST-276-WAVE-B3/F-P173-201+203+204+205+206+207/2026-07-27): Six HIGH findings from P1D-173. F-P173-201 — move BudgetConfig (SS-10/core::budget), CompactionTrigger (SS-10/core::budget), and ProvenanceTag (SS-11/core::guardrail) from §ferrochain-graph Public Types to §ferrochain-core Public Types; all three are ferrochain-core types — cataloguing them under graph implied a circular core→graph dependency (D-24/BudgetPolicy/ADR-009, GuardrailHook/ADR-014 Decision 6, MemoryWriteGuard/ADR-012 relocation precedents confirm pattern; ProvenanceTag must be in ferrochain-core because GuardrailHook::evaluate in core takes it as a parameter); inclusion criterion note updated. F-P173-203 — remove standalone §ferrochain-graph Public Types row for CompactionEvent; CompactionEvent is a StreamEvent enum variant, not a top-level type; StreamEvent row already reads '15 variants ... CompactionEvent'; variant count 15 confirmed intact after deletion. F-P173-204 — PathGuard row in §Public Traits and Types (ferrochain-tools): E-TOOLS-001 → E-SBXD-001 on workspace escape; BC-2.13.004 PC4 raises E-SBXD-001 at the sandbox layer (module-decomposition.md sandbox::path_guard row confirms); E-TOOLS-001 is the tool-layer translation per interface-definitions.md F-P173-601; crate attribution ferrochain-sandbox/SS-13 and VP-003 anchor unchanged. F-P173-205 — add five missing D21 ferrochain-core traits to §Public Rust Traits (ferrochain-core): Retriever (SS-20/core::retriever, ADR-014 Decision 1, BC-2.20.001-003), Embeddings (SS-22/core::embeddings, ADR-017 Decision 2, BC-2.22.001-003), LcSerializable (SS-19/core::serializable, ADR-016 Decision 1+2, BC-2.19.001-006), MemoryWriteGuard (SS-15/core::write_guard, ADR-012 D20, BC-2.15.005), ToolCallDialect (SS-08/ferrochain-core, ADR-018, BC-2.08.013; interface-definitions.md §ToolCallDialect source confirms ferrochain-core placement); add SkillStore (SS-15/memory::skills, ADR-012 Decision 1, BC-2.15.004) to §Public Traits (ferrochain-memory); add §Public Traits (ferrochain-graph) with PreToolCallHook (SS-05/graph::hitl, ADR-018 Decision 1, BC-2.05.007); add §Public Traits (ferrochain-vectorstores) with VectorStore (SS-21, ADR-014 Decision 2, BC-2.21.001-004) and VectorStoreFactory (SS-21, ADR-014 Decision 2, BC-2.21.001); add explicit no-public-traits notes for ferrochain-prompts, ferrochain-mcp, ferrochain-sandbox, ferrochain-splitters, ferrochain-macros, SDK crates, provider impl crates, and ferrochain-standard-tests. TD-VSDD-060 sibling sweep: other architecture files do not enumerate per-crate trait sections — no further changes required outside this file. F-P173-206 — add 4 missing Cargo Feature Flags (total 6→10): sandbox-process (off; security: NOT enforcing — no filesystem/network/memory isolation; accessible ONLY via Sandbox::unsafe_process_no_isolation(); BC-2.13.001/BC-2.13.002), mcp (off; BC-2.09.001), budget (on; BC-2.10.001), guardrail (on; BC-2.11.001). Derivation: cross-checked against interface-definitions.md §Cargo Feature Flags (authoritative 10-flag list: checkpoint-sqlite, checkpoint-memory, checkpoint-postgres, sandbox-wasm, sandbox-container, sandbox-process, server, mcp, budget, guardrail); total confirmed 10. F-P173-207 — apply F-P170-03 crate qualification to sibling types PreToolDecision and ToolCallPreview in §Public Traits and Types (ferrochain-tools): both defined in ferrochain-graph::hitl per ADR-018 Decision 1; D-24 relocated ActionRisk to ferrochain-core but the three HITL types (PreToolCallHook/PreToolDecision/ToolCallPreview) remained in graph::hitl."
  - "1.13 (FIX-BURST-276-WAVE-B1/F-P173-202+210+619+214/2026-07-27): F-P173-202 (HIGH) — add missing `message` and `source` fields to §Error Type `FerrochainError` struct display: `message: String` (Human-readable; MUST NOT contain credentials per DI-010) and `source: Option<Arc<dyn std::error::Error + Send + Sync>>` (causal error chain; MUST NOT be exposed in HTTP responses; `Arc` not `Box` — Arc preserves Clone per F-P173-211 adjudication in ADR-010 v1.12). F-P173-210/619 — add `#[non_exhaustive]` attribute to FerrochainError in §Error Type; all sibling public API surface types carry `#[non_exhaustive]` per CLAUDE.md Code Conventions. F-P173-214 (LOW) — fix stale `17→18` transition delta: `gate count 17→18` → `gate count 18` (transition completed in v1.7/D23; delta notation no longer meaningful)."
  - "1.12 (FIX-BURST-273/F-P171a-19/2026-07-25): Adjudicate `ActionRisk` row inclusion criterion in §ferrochain-core Public Types. `ActionRisk` has a row because: (a) it is consumed cross-crate by ferrochain-tools as a standalone API input (`ToolConfig::override_risk(risk: ActionRisk)`) and must be addressable without a ferrochain-graph dependency; (b) no other ferrochain-core type currently meets criterion (a) — BoundaryType/IngressContent/GuardrailResult are only consumed through `GuardrailHook::evaluate` trait method signatures, not as standalone parameters in cross-crate public APIs. Inclusion criterion documented in §ferrochain-core Public Types note."
  - "1.11 (FIX-BURST-272/F-P170-03+04+06/2026-07-25): Three api-surface fixes in one burst. (1) F-P170-03 — Remove `PreToolCallHook` from §Public Rust Traits (ferrochain-core); ADR-018 Decision 1 places it in `ferrochain-graph::hitl`, not core; putting it in core was exactly the 'orphan definitions module' alternative ADR-018 rejected by name. Fix ferrochain-tools section note: 'trait is defined in core, tools crate provides impls' → 'trait defined in ferrochain-graph::hitl per ADR-018 Decision 1'. (2) F-P170-04 — Correct PathGuard SS-23 → SS-13 with amended BC anchor; PathGuard is owned by ferrochain-sandbox/SS-13/BC-2.13.004 and is the CRITICAL path-guard module with VP-003 Kani P0. (3) F-P170-06 adjudication (option b) — ActionRisk relocates to ferrochain-core (core::action_risk) per dependency-inversion precedent; ferrochain-tools needs ActionRisk at compile time without depending on ferrochain-graph. Move ActionRisk row from ferrochain-tools section to ferrochain-core Public Types section; SS-23 → SS-05 (HITL risk tiering); add BC-2.05.006 anchor."
  - "1.10 (FIX-BURST-266/OBS-P164-B/2026-07-25): Adjudicate and fix Tool trait row mixed anchoring. `Tool | ferrochain-core | SS-09 | BC-2.09.002` was wrong on both anchors: SS-09 is ferrochain-mcp (the CONSUMER crate — BC-2.09.002 PC1 takes `Arc<dyn ferrochain_core::Tool>` as input); BC-2.09.002 is 'ToolInvocation Routing to Correct MCP Server Transport' (MCP routing, not trait definition). Adjudicated: Tool trait is DEFINED in `ferrochain-core/src/tool.rs` (BC-2.08.010 Architecture Anchors), owned by SS-08 (macros::tool module is SS-08 per module-decomposition.md; BC-2.08.010 lives in ss-08/). Correct row: `Tool | ferrochain-core | SS-08 | BC-2.08.010`. Parallel to BaseChatModel | ferrochain-core | SS-08 pattern. Trait-row audit: all other 6 ferrochain-core trait rows (Runnable/SS-01, BaseChatModel/SS-08, GuardrailHook/SS-11, BudgetPolicy/SS-10, PreToolCallHook/SS-05, CompactionPolicy/SS-10) are correctly definition-anchored — no further mixing found."
  - "1.9 (burst-242/2026-07-23): Fix-242 Command-notation sweep — convert residual enum-style notation Command::resume(value) in §ferrochain-graph Public Types table to canonical struct kwarg form Command(resume=value). Canonical form per BC-2.05.004 v1.5 + F-P120-01 adjudication."
  - "1.8 (burst-238/2026-07-23): F-P138-02 stale-handoff sweep — remove stale Note on api-surface.md §Error Type: 'ADR-010 amendment required to add TOOLS variant — architect task per error-taxonomy.md §TOOLS delegation note.' ADR-010 v1.3 (burst-232) already registered TOOLS as component 17; error-taxonomy.md §TOOLS delegation note was removed in v1.32 (burst-233 F-P133-09); TOOLS already listed as 17th component in the enum. Dangling cross-reference to removed delegation note deleted."
  - "1.7 (D23/2026-07-22): Add D23 API surfaces. (1) ferrochain-core Public Traits: +PreToolCallHook (SS-05, BC-2.05.007), +CompactionPolicy (SS-10, BC-2.10.005/006). (2) ferrochain-graph Public Types: StreamEvent BC range 001–002→001–006 + 15-variant count noted; +CompactionTrigger (SS-10, BC-2.10.005), +CompactionEvent (SS-10, BC-2.10.006/BC-2.06.006). (3) §Public Traits and Types (ferrochain-tools) added: ActionRisk, PreToolDecision, ToolCallPreview, PathGuard, ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, BashTool (VP-013), GrepTool. (4) Component enum 16→17 (+TOOLS); #[non_exhaustive] gate count 17→18. ADR-010 amendment delegated to architect."
  - "1.6 (D21/Batch-3b-i/2026-07-20): Component enum expanded 12→16 per ADR-010 v1.1. Added TMPL (ferrochain-prompts), SRLZ (ferrochain-core::serializable), VS (ferrochain-vectorstores), EMBED (ferrochain-core::embeddings) to Component list. #[non_exhaustive] gate count 13→17 (16 named variants + Custom = 17). Implementer updates ALL three gate locations (gate crate, expected count constant, expected symbol list) when creating ferrochain-core/src/error.rs at Wave 0 per CLAUDE.md non-exhaustive gate rule."
  - "1.5 (F-P115-02 ripple, 2026-07-19): Extend CheckpointSaver BC anchor range from BC-2.04.001–006 to BC-2.04.001–007. BC-2.04.007 is now a live anchor because the `put` method (added to the trait per F-P115-02 adjudication) carries BC-2.04.007 PC1/INV-1 encryption-parity obligations. Sweep: no method-count enumerations or get_next_version absence claims present in this file — api-surface.md delegates all signatures to interface-definitions.md."
  - "1.4 (F-P92-02, 2026-07-17): Add §ferrochain-core Public Types table. RunnableConfig gains budget_config: Option<BudgetConfig> (OPTION A — BC-2.10.004 PC6 / BC-2.10.003 PC7/TV-004). Row documents all four known RunnableConfig fields (recursion_limit, thread_id, budget_config, context_mutations)."
  - "1.3 (provenance-fix-169/2026-07-17): hash-currency refresh — prd.md updated to v1.2 in same burst; add [Section Content] template compliance fix. No spec content changes."
  - "1.2 (ADV-P1D-PASS-64): F-P64-01 adjudication — default port 7437 is mandated; replaced 'no default port mandated' with authoritative default per interface-definitions.md §Base URL."
  - "1.1 (ADV-P1D-PASS-25): F-P25-04 to_problem_detail()→to_problem() method name correction."
  - "1.0 (initial / 2026-07-13): initial API surface authored — ferrochain-core Public Traits, ferrochain-server HTTP endpoint catalog, and ferrochain-server Public Types. NOTE (F-P104-01, 2026-07-18): reconstructed from commit ef41eda (burst 73, 2026-07-13) — no initial changelog row was written at authoring."
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/interface-definitions.md
input-hash: "48a8fd4"
traces_to: ARCH-INDEX.md
decisions: [D13, D17]
---

# API Surface: ferrochain

> Full signatures in `prd-supplements/interface-definitions.md`. This file is the
> architecture-level summary: which traits belong to which crate/subsystem, and
> the HTTP endpoint catalog for ferrochain-server.

## [Section Content]

This file documents ferrochain's public API surface: the public Rust traits by crate/subsystem, and the HTTP endpoint catalog for ferrochain-server. It is the architecture-level summary; full signatures live in `prd-supplements/interface-definitions.md`.

## Public Rust Traits (ferrochain-core)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `Runnable<Input, Output>` | ferrochain-core | SS-01 | BC-2.01.003, BC-2.01.004 |
| `BaseChatModel` | ferrochain-core | SS-08 | BC-2.08.001–005 |
| `GuardrailHook` | ferrochain-core | SS-11 | BC-2.11.002–004 |
| `BudgetPolicy` | ferrochain-core | SS-10 | BC-2.10.001 |
| `Tool` | ferrochain-core | SS-08 | BC-2.08.010 |
| `DynTool` | ferrochain-core (`core::tool`) | SS-08 | BC-2.08.010 |
| `CompactionPolicy` | ferrochain-core | SS-10 | BC-2.10.005, BC-2.10.006 |
| `Retriever` | ferrochain-core | SS-20 | BC-2.20.001–003 |
| `Embeddings` | ferrochain-core | SS-22 | BC-2.22.001–003 |
| `LcSerializable` | ferrochain-core | SS-19 | BC-2.19.001–006 |
| `MemoryWriteGuard` | ferrochain-core | SS-15 | BC-2.15.005 |
| `ToolCallDialect` | ferrochain-core | SS-08 | BC-2.08.013 |

> `DynTool` is the type-erased object-safety seam per ADR-005
> §Adjacent Trait Object-Safety Adjudications (option b). `Tool` inherits from `Runnable`,
> which exposes `stream()` (opaque `impl Stream` return) and `pipe()` (`impl Runnable` +
> `where Self: Sized`), making `dyn Tool` non-trivially non-object-safe (E0038). `DynTool`
> re-exposes the tool API via object-safe `invoke_dyn(&self, Value) -> Result<Value, FerrochainError>`.
> A blanket impl provides `T: Tool + Send + Sync + 'static → DynTool` automatically.
> `Arc<dyn DynTool>` is the composition seam for all dynamic dispatch sites.
> Wave C BC-side migration (ADR-005 §Adjacent Adjudications corrected list — 2 sites):
> `BC-2.09.001` (Description + PC2) and `BC-2.09.002 PC1` — `Arc<dyn ferrochain_core::Tool>`
> → `Arc<dyn DynTool>` (MCP tool discovery/invocation BCs; these are the actual corpus
> occurrences; prior v1.8 list citing BC-2.05.003/BC-2.05.004/BC-2.08.010 was incorrect).

## ferrochain-core Public Types

| Type | Role | SS | BC Anchors |
|------|------|----|-----------|
| `RunnableConfig` | Per-invocation config: `recursion_limit` (default 25), `thread_id`, `budget_config: Option<BudgetConfig>` (per-run budget override — `None` inherits `GraphConfig::budget_config`; `Some` overrides for that run; used by `BudgetResume::Extend`), `context_mutations: Option<ContextMutationConfig>` | SS-01 | BC-2.01.003 PC5, BC-2.10.003 PC7/TV-004, BC-2.10.004 PC6, BC-2.15.006 PC1 |
| `ActionRisk` | Risk classification enum for tool dispatch; 4 variants: `ReadOnly`/`Low`/`Medium`/`High` (`#[non_exhaustive]`); relocated from `ferrochain-graph::hitl` to `ferrochain-core` (`core::action_risk`) per dependency-inversion precedent — `ferrochain-tools` consumes it at compile time without a `ferrochain-graph` dep (F-P170-06/ADR-020 adjudication) | SS-05 | BC-2.05.006, BC-2.23.005 |
| `BudgetConfig` | Budget ceiling + on_ceiling policy; embedded in `RunnableConfig.budget_config` (per-run override) and `GraphConfig.budget_config` (graph-level default); defined in `core::budget` (ferrochain-core — ADR-009 Option 3) | SS-10 | BC-2.10.001 |
| `CompactionTrigger` | `Disabled \| OnWatermark{fraction: f64} \| OnMessageCount{count: usize} \| OnTokenCount{tokens: u64}`; field in `BudgetConfig.compaction_trigger`; defined in `core::budget` (ferrochain-core — ADR-019 Decision 1) | SS-10 | BC-2.10.005 |
| `ProvenanceTag` | Content source tag attached at every ingress boundary; parameter to `GuardrailHook::evaluate` in ferrochain-core; defined in ferrochain-core (`core::guardrail` area — cannot be in ferrochain-graph without creating a circular core→graph dependency) | SS-11 | BC-2.11.001 |

> **Public Types inclusion criterion (F-P171a-19 adjudication, extended F-P173-201):** A type earns a row in
> §ferrochain-core Public Types when (a) it is consumed by a downstream crate as a
> standalone API input or output independent of any trait method signature — i.e., the
> downstream crate passes it directly as a function argument or struct field without
> going through a trait; OR (b) it is defined in ferrochain-core but was previously
> misattributed to ferrochain-graph, implying a circular core→graph dependency.
> `ActionRisk` meets criterion (a): `ferrochain-tools` passes it directly to
> `ToolConfig::override_risk(risk: ActionRisk)`. `BudgetConfig` meets criterion (a):
> embedded as `RunnableConfig.budget_config` (struct field consumed cross-crate).
> `CompactionTrigger` meets criterion (a): embedded in `BudgetConfig.compaction_trigger`.
> `ProvenanceTag` meets criterion (b): it is a ferrochain-core type (parameter to
> `GuardrailHook::evaluate`; GuardrailHook is defined in ferrochain-core) — cataloguing
> it under ferrochain-graph would imply core depends on graph, which is forbidden.
> Types such as `GuardrailResult`, `IngressContent`, `BoundaryType`, `WriteGuardDecision`,
> `MemoryWriteRequest`, `PolicyDecision`, and `OnCeiling` do not currently meet either
> criterion — they appear only in trait method signatures and are not standalone
> cross-crate function inputs or misattributed graph types.
> When a new type meets criterion (a) or (b), add it here.

## Public Traits (ferrochain-memory)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `MemoryStore` | ferrochain-memory | SS-15 | BC-2.15.001–003 |
| `SkillStore` | ferrochain-memory | SS-15 | BC-2.15.004 |

## Public Traits (ferrochain-checkpoint)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `CheckpointSaver` | ferrochain-checkpoint | SS-04 | BC-2.04.001–007 |

## Public Traits (ferrochain-server)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `IdempotencyStore` | ferrochain-server | SS-12 | BC-2.12.006 |
| `RateLimitStore` | ferrochain-server | SS-12 | BC-2.12.006 |
| `RunStore` | ferrochain-server | SS-12 | BC-2.12.006 |

## Public Traits (ferrochain-graph)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `PreToolCallHook` | ferrochain-graph (`graph::hitl`, ADR-018 Decision 1) | SS-05 | BC-2.05.007 |

> `PreToolCallHook` is defined in `ferrochain-graph::hitl` per ADR-018 Decision 1.
> The alternative of placing it in ferrochain-core was explicitly rejected by ADR-018
> (the "orphan definitions module" option). `ferrochain-tools` interacts with it via
> `ActionRisk` risk-tier defaults (sourced from `ferrochain-core::ActionRisk`) without
> taking a compile-time ferrochain-graph dependency (ADR-020 Decision 3).

## Public Traits (ferrochain-vectorstores)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `VectorStore` | ferrochain-vectorstores (`vectorstores::store`) | SS-21 | BC-2.21.001–004 |
| `VectorStoreFactory` | ferrochain-vectorstores (`vectorstores::store`; `Sized`-bounded for `Arc<dyn VectorStore>` dyn-safety) | SS-21 | BC-2.21.001 |

> `VectorStore` and `VectorStoreFactory` are both defined in `ferrochain-vectorstores`.
> `VectorStoreFactory: VectorStore + Sized` — the `Sized` bound preserves `Arc<dyn VectorStore>`
> object-safety (ADR-014 Decision 2). `Retriever` (the trait) is defined in ferrochain-core.
> `VectorStoreRetriever` (no lifetime parameter; `store: Arc<dyn VectorStore>`) is the adapter
> struct. `Arc<dyn VectorStore>` ownership (not a borrow) allows `VectorStoreRetriever` to satisfy
> `Retriever + 'static`, enabling `Arc<dyn Retriever>` coercion without a lifetime bound error.
> `VectorStore::as_retriever` signature: `fn as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` —
> fallible; returns `Err(E-VS-003)` when store configuration is invalid for retrieval
> (ADR-014 Decision 2).

## Crates with No Public Traits

The following crates define no public Rust traits. Each is listed with its reason to make
omissions falsifiable rather than silent.

| Crate | Reason |
|-------|--------|
| `ferrochain-prompts` | Concrete types only (`PromptTemplate`, `ChatPromptTemplate`, `FewShotPromptTemplate`, `MessagesPlaceholder`, `SlotTrustPolicy` enum, `TrustLevel` enum); no trait definitions |
| `ferrochain-mcp` | Struct-and-impl surface only (`MultiServerMcpClient`, tool discovery, `ToolInvocation` routing); no public trait definitions; consumes `Tool` from ferrochain-core |
| `ferrochain-sandbox` | `SandboxPolicy` and `ProcessBackend` are structs/enums, not public trait definitions; `WorkspaceFs` facade is a struct; `sandbox::path_guard` exposes free functions (`canonicalize_beneath_root`, `canonicalize_beneath_root_pure`) |
| `ferrochain-splitters` | Free-function splitter implementations; no public trait definitions |
| `ferrochain-macros` | Proc-macro crate (`#[tool]`, `#[entrypoint]`, `#[task]`); proc-macros are attribute macros, not Rust trait definitions |
| `ferrochain-openai` | Implements `BaseChatModel` and `Embeddings` from ferrochain-core; defines no new public traits |
| `ferrochain-anthropic` | Implements `BaseChatModel` from ferrochain-core; defines no new public traits |
| `ferrochain-ollama` | Implements `BaseChatModel` and `Embeddings` from ferrochain-core; defines no new public traits |
| `ferrochain-openai-sdk` | Wire client; no ferrochain-core dependency; no public trait definitions |
| `ferrochain-anthropic-sdk` | Wire client; no ferrochain-core dependency; no public trait definitions |
| `ferrochain-ollama-sdk` | Wire client; no ferrochain-core dependency; no public trait definitions |
| `ferrochain-standard-tests` | Shared conformance test suite and `eval::judge` module; test-only crate; no public trait definitions shipped to consumers |

## ferrochain-graph Public Types

| Type | Role | SS | BC Anchors |
|------|------|----|-----------|
| `StateGraph<State>` | Graph builder: nodes, edges, channels | SS-02 | BC-2.02.001–006 |
| `GraphConfig` | Execution config: checkpoint_saver, interrupt_before/after | SS-03 | BC-2.03.001 |
| `Command` | HITL resume carrier: `Command(resume=value)` | SS-05 | BC-2.05.004 |
| `StreamEvent` | Streaming event enum; run_id + parent_ids; 15 variants (D23 adds ToolApprovalRequest/Resolved/CompactionEvent as variants 13–15) | SS-06 | BC-2.06.001–006 |

## Public Traits and Types (ferrochain-tools)

| Symbol | Kind | SS | BC Anchors |
|--------|------|----|-----------|
| `PreToolCallHook` | trait (defined in `ferrochain-graph::hitl` per ADR-018 Decision 1; ferrochain-tools registers tools that interact with this hook via `ActionRisk` risk-tier defaults — ADR-020 Decision 3) | SS-05 | BC-2.05.007 |
| `PreToolDecision` | enum (4 variants: Approve/Deny/Edit/PendingHumanApproval) (defined in `ferrochain-graph::hitl` per ADR-018 Decision 1; D-24 relocated `ActionRisk` to ferrochain-core but these three HITL types remained in graph::hitl) | SS-05 | BC-2.05.007 |
| `ToolCallPreview` | struct (tool_name, tool_args, action_risk: Option\<ActionRisk\>) (defined in `ferrochain-graph::hitl` per ADR-018 Decision 1) | SS-05 | BC-2.05.007 |
| `PathGuard` | struct (workspace-root-confined path validator; `E-SBXD-001` on workspace escape at sandbox layer — entry points: `canonicalize_beneath_root` / `canonicalize_beneath_root_pure`; tool layer translates to `E-TOOLS-001` per interface-definitions.md §First-Party Tools error layer split) — owned by ferrochain-sandbox/SS-13 (VP-003 Kani P0); consumed by SS-23 tools | SS-13 | BC-2.13.004 |
| `ToolConfig` | shared per-tool framework configuration; `override_risk(self, risk: ActionRisk) -> Result<ToolConfig, FerrochainError>` builder-consuming validator (`#[non_exhaustive]`); ADR-020 Decision 3 | SS-23 | BC-2.23.005 |
| `ReadFileTool` | first-party tool | SS-23 | BC-2.23.001 |
| `WriteFileTool` | first-party tool (High ActionRisk) | SS-23 | BC-2.23.002 |
| `EditFileTool` | first-party tool | SS-23 | BC-2.23.003 |
| `ListDirTool` | first-party tool (ReadOnly) | SS-23 | BC-2.23.004 |
| `BashTool` | first-party tool (Medium ActionRisk floor; VP-013 Kani seed) | SS-23 | BC-2.23.005 |
| `GrepTool` | first-party tool | SS-23 | BC-2.23.006 |

## ferrochain-server HTTP Endpoints

Base URL: configurable; default port 7437 (server.port in ferrochain-server.toml — see interface-definitions.md §Base URL).

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads` | Create thread | BC-2.12.001 |
| GET | `/threads/{thread_id}` | Read thread | BC-2.12.001 |
| GET | `/threads` | List threads | BC-2.12.001 |
| DELETE | `/threads/{thread_id}` | Delete thread | BC-2.12.001 |
| GET | `/threads/{thread_id}/state` | Latest checkpoint state (`{ values, checkpoint, next }`) | BC-2.12.001 |
| POST | `/threads/{thread_id}/state` | Apply state delta (`{ values, as_node? }` → `{ checkpoint }`) | BC-2.12.001 |
| GET | `/threads/{thread_id}/history` | Checkpoint history, newest-first (`?limit=N`) | BC-2.12.001 |
| POST | `/assistants` | Create assistant (named agent config) | BC-2.12.002 |
| GET | `/assistants` | List assistants | BC-2.12.002 |
| GET | `/assistants/{assistant_id}` | Read assistant (resolves via latest-version pointer) | BC-2.12.002 |
| PATCH | `/assistants/{assistant_id}` | Sparse update; creates immutable new version | BC-2.12.002 |
| DELETE | `/assistants/{assistant_id}` | Delete assistant | BC-2.12.002 |
| GET | `/assistants/{assistant_id}/versions` | List immutable version snapshots (ascending) | BC-2.12.002 |
| POST | `/assistants/{assistant_id}/set_latest` | Set latest-version pointer (`{ version: N }`) | BC-2.12.002 |
| POST | `/threads/{thread_id}/runs` | Create and start run (async; 202 Accepted) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs` | List runs for thread (`?status=`) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}` | Read run status and result | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}/stream` | SSE streaming run output | BC-2.12.007 |
| POST | `/threads/{thread_id}/runs/{run_id}/resume` | Deliver HITL resume value | BC-2.05.004 |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | Cancel queued/in_progress run (→ cancelled) | BC-2.12.003 |
| DELETE | `/threads/{thread_id}/runs/{run_id}` | Delete terminal run record (409 if non-terminal) | BC-2.12.003 |
| POST | `/schedules` | Create cron schedule (assistant-owned; flat path) | BC-2.12.004 |
| GET | `/schedules/{cron_id}` | Read schedule (enabled state, last_fired_at) | BC-2.12.004 |
| PATCH | `/schedules/{cron_id}` | Enable/disable schedule (`{ "enabled": false }`) | BC-2.12.004 |
| DELETE | `/schedules/{cron_id}` | Delete schedule; halts future firings | BC-2.12.004 |
| GET | `/runs?schedule_id={cron_id}` | Cross-thread aggregate: list all Runs for a schedule (read-only; flat) | BC-2.12.004 |

**URL scheme (F-P23-01):** Runs are thread-nested (`/threads/{thread_id}/runs/...`). Schedules are
flat (`/schedules/{cron_id}`). The one flat `/runs?schedule_id=` endpoint is a read-only
cross-thread aggregate query for schedule-fired runs only.

**Wire format:** JSON for HTTP responses. msgpack for checkpoint state (ADR-002).

**Security:** `SecurityConfig::default()` denies CORS. Debug route requires opt-in key (BC-2.12.005).

## Cargo Feature Flags

| Feature | Default | Description | BC Anchor |
|---------|---------|-------------|-----------|
| `checkpoint-sqlite` | YES | SQLite checkpoint backend | BC-2.04.002 |
| `checkpoint-memory` | NO | In-memory backend (tests) | — |
| `checkpoint-postgres` | NO | PostgreSQL backend (stretch) | — |
| `sandbox-wasm` | YES | WASM execution backend (enforcing default) | BC-2.13.001 |
| `sandbox-container` | NO | Container execution backend | BC-2.13.001 |
| `sandbox-process` | NO | **Security-annotated.** Process backend — NOT enforcing (no filesystem/network/memory isolation); compiles `ProcessBackend` but does NOT make it a default; accessible ONLY via `Sandbox::unsafe_process_no_isolation()`; `SandboxBackend::default()` returns `Err(E-SBXD-003)` when no enforcing backend is compiled (BC-2.13.001 PC3/PC4) | BC-2.13.001, BC-2.13.002 |
| `server` | NO | Include ferrochain-server in binary | BC-2.12.001 |
| `mcp` | NO | ferrochain-mcp adapter | BC-2.09.001 |
| `budget` | YES | Budget governance policy primitive | BC-2.10.001 |
| `guardrail` | YES | Content provenance + guardrail hook | BC-2.11.001 |

## Error Type

`#[non_exhaustive] FerrochainError { component: Component, category: Category, retry_hint: RetryHint, code: &'static str, message: String /* Human-readable; MUST NOT contain credentials */, source: Option<Arc<dyn std::error::Error + Send + Sync>> /* Causal chain; MUST NOT appear in HTTP responses (DI-010); Arc not Box — Arc preserves Clone (F-P173-211 adjudication, ADR-010 §Decision) */ }`

Construction (ADR-010 §impl FerrochainError — sole sanctioned paths):
- `FerrochainError::new(component: Component, category: Category, retry_hint: RetryHint, code: &'static str, message: impl Into<String>) -> Self` — `source` defaults to `None`.
- `.with_source(self, source: Arc<dyn std::error::Error + Send + Sync>) -> Self` — builder; threads a causal error into the chain. Chain as needed: `FerrochainError::new(...).with_source(Arc::new(e))`.
- Struct literal construction is barred by `#[non_exhaustive]` (E0639) from external crates.

Authoritative list lives in `error-taxonomy.md` §Components; enum reproduced here for the FerrochainError type definition:
`Component` = CORE | GRAPH | CHKPT | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET | TMPL | SRLZ | VS | EMBED | TOOLS (17 components as of D23; `#[non_exhaustive]` gate count 18: 17 named + `Custom`).
Full catalog: `prd-supplements/error-taxonomy.md`.
RFC-7807 serialization: `FerrochainError::to_problem()` (BC-2.14.002). Note: corrected from `to_problem_detail()` (F-P25-04; BC-2.14.002 is authoritative for method name).
