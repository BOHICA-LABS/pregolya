---
document_type: prd-supplement-interface-definitions
level: L3
version: "2.52"
status: active
producer: product-owner
timestamp: 2026-07-24T00:00:00Z
phase: 1d
changelog:
  - "2.52 (F-P149-02/burst-250/2026-07-24): Two live-body version pins de-pinned (TD-VSDD-091 stable-anchor enforcement, F-P149-02). (1) §GuardedDocuments rag_ingress doc comment: 'ADR-014 v1.5' → 'ADR-014 Decision 6 §GuardedDocuments' (severity-bifurcated Fail behavior is defined in Decision 6 rag_ingress code). (2) similarity_search_with_filter default body comment: 'ADR-014 v1.5 F-P131-07 adjudication' → 'ADR-014 Decision 2 §Metadata filter surface F-P131-07 adjudication' (F-P131-07 adjudication is embedded in Decision 2 §Metadata filter surface subsection)."
  - "2.51 (F-P145-01+F-P145-04, burst-246, 2026-07-23): (1) F-P145-01: §First-Party Tools BashTool stub — default max_duration corrected 120s→30s to match canon (BC-2.23.005 H1/Description/PC1/EC-002/TV-004/DI-015 chain, ADR-020 Decision 2, ubiquitous-language-core). TD-VSDD-060 sweep: rg 'max_duration|120s|120 s' .factory/specs/ — sole 120s live-body site was this line; all other max_duration references already read 30s/30 seconds; zero further residue. (2) F-P145-04: §First-Party Tools opening sentence — over-generalization 'All tools use PathGuard' reworded to distinguish the five file-access tools (PathGuard-confined) from BashTool (ferrochain-sandbox-confined per BC-2.23.005); 'All tools implement the Tool trait' clause preserved."
  - "2.50 (F-P142-01+F-P142-03, burst-242, 2026-07-23): (1) F-P142-01: §First-Party Tools — three CreateFileTool phantom sites replaced with ListDirTool per BC-2.23.004 H1: BC anchor BC-2.23.004 label, PathGuard shared-list doc comment, and tool stub comment+description. (2) F-P142-03: Sweep Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form at 6 sites (L835 ToolApprovalResolved emission comment, L881 causal ordering diagram, L921 BC-2.06.005 StreamEvent BC anchor, L931 §PreToolCallHook BC anchor BC-2.05.004 citation, L969 PendingHumanApproval doc comment, L1631 /stream endpoint row). Zero Command:: enum-variant and CreateFileTool residue remains."
  - "2.49 (burst-240/F-P140-04/2026-07-22): Blanket omission annotation updated — E-MCP-006 McpContentUnsupported (VAL/Never, minted burst-240) added to E-MCP-* namespace (5→6 codes). E-MCP-006 confirmed library-layer only: raised by _convert_mcp_content_to_block in ferrochain-mcp when a CallToolResult contains an unsupported content block type (e.g., AudioContent); surfaces as library Err(FerrochainError) return, never as a direct HTTP terminal response in v1 (propagates embedded in Run.error if it reaches ferrochain-server). Disposition census 107→108: 43 HTTP + 17 individual + 48 blanket. Blanket group breakdown: E-MCP-* 6 + E-SBXD-* 6 + E-RETRY-* 4 + E-BUDGET-* 2 + E-MEMORY-* 8 + E-SPLIT-* 2 + E-TMPL-* 3 + E-SRLZ-* 2 + E-VS-* 5 + E-EMBED-* 1 + E-TOOLS-* 9 = 48."
  - "2.48 (burst-236/F-P136/2026-07-23): Fix burst 236 placement-marker corrections (five findings + sweep). (1) F-P136-01: §Retriever Trait/GuardedDocuments placement marker `core::guardrail` → `core::retriever` (ADR-014 Decision 6; GuardedDocuments struct and rag_ingress are in core::retriever, not core::guardrail); §-source line drops `, core::guardrail`. (2) F-P136-02: §PreToolCallHook three co-located fixes per ADR-018 Decision 1 + BC-2.05.007: (a) module `graph::approval` → `graph::hitl` in both §-source and code-block marker; (b) trait method `pre_tool_dispatch` → `pre_invoke`; (c) restore dropped second parameter `run_ctx: &RunContext`. (3) F-P136-03: §Compaction type-definition marker `ferrochain-graph: graph::budget` → `ferrochain-core: core::budget` for CompactionTrigger/ConversationSnapshot/CompactionSummary/CompactionPolicy (ADR-019 Decision 1); §-source extended to note execution engine in graph::budget. (4) F-P136-04: StreamEvent::CompactionEvent.tokens_remaining_after type `u64` → `Option<i64>` (source is RunContext.budget_info.tokens_remaining: Option<i64>; three-site reconciliation with BC-2.06.006 v1.2 and BC-2.10.006 v1.3). (5) F-P136-05: §PreToolCallHook BC anchors re-attributed — BC-2.05.004 (Command(resume=value) API) removed from trait/ToolCallPreview/PreToolDecision/fail-closed description; BC-2.05.007 is the authoritative contract; BC-2.05.004 retained only for Command::Resume(PreToolDecision) resume-API role. Sweep also corrects PreToolDecision variant shapes to ADR-018 Decision 1 / BC-2.05.007: Deny { reason: String }, Edit { modified_args: serde_json::Value }, PendingHumanApproval { prompt: Option<String> }."
  - "2.47 (burst-233/F-P133-03/2026-07-22): E-TOOLS-* blanket annotation updated — 7→9 codes (+E-TOOLS-008 FileIoError TOOL/Maybe, +E-TOOLS-009 InvalidRegexPattern VAL/Never, minted burst-233). Disposition census 105→107 (43 HTTP + 17 individual + 47 blanket). Blanket group breakdown: E-MCP-* 5 + E-SBXD-* 6 + E-RETRY-* 4 + E-BUDGET-* 2 + E-MEMORY-* 8 + E-SPLIT-* 2 + E-TMPL-* 3 + E-SRLZ-* 2 + E-VS-* 5 + E-EMBED-* 1 + E-TOOLS-* 9 = 47."
  - "2.46 (D23/2026-07-22): Add D23 API surfaces. (1) StreamEvent enum 12→15 variants: +ToolApprovalRequest (event 13, PendingHumanApproval interrupt signal per ADR-018 Decision 5), +ToolApprovalResolved (event 14, resume decision applied), +CompactionEvent (event 15, post-compaction durable write per ADR-019 Decision 4) — causal ordering diagram updated. BC-2.06.004/005/006 anchor refs added to §StreamEvent. (2) §PreToolCallHook section added: ActionRisk enum (4 tiers: ReadOnly/Low/Medium/High), ToolCallPreview struct (tool_name, tool_args, action_risk: Option<ActionRisk>), PreToolDecision enum (4 variants: Approve/Deny/Edit/PendingHumanApproval), PreToolCallHook trait; source ADR-018 Decision 2–6. (3) §Compaction section added: CompactionTrigger enum (4 variants: Disabled/OnWatermark/OnMessageCount/OnTokenCount), ConversationSnapshot struct, CompactionSummary struct, CompactionPolicy trait; source ADR-019 Decision 1–5. (4) §First-Party Tools section added: PathGuard struct (E-TOOLS-001 sandbox confinement); ReadFileTool/WriteFileTool/EditFileTool/CreateFileTool/BashTool/GrepTool comment anchors. (5) /stream endpoint row: added tool_approval_request, tool_approval_resolved, compaction_event event mentions (D23/ADR-018/ADR-019). (6) Blanket omission annotation: E-TOOLS-* 7 new codes added; census 98→105 (43 HTTP + 17 individual + 45 blanket)."
  - "2.45 (burst-227/F-P132-02/2026-07-21): §ChatPromptTemplate — complete BC-2.18.x anchor swap from burst-226 partial-propagation. (1) SlotTrustPolicy doc anchor: BC-2.18.003 PC1-PC2 (MessagesPlaceholder!) → BC-2.18.002 PC4 (slot_trust_policy field) + BC-2.18.005 PC1-PC5 (construction-time policy guard). (2) from_messages anchor: BC-2.18.001 PC1 (PromptTemplate construction!) → BC-2.18.002 PC1 (ChatPromptTemplate construction). (3) PromptValue struct anchor: BC-2.18.001 PC3 (input_variables()!) → BC-2.18.002 PC2 (PromptValue.messages). (4) MessageProvenance struct anchor: BC-2.18.003 PC2-PC3 (MessagesPlaceholder!) → BC-2.18.002 PC3-PC4 (highest_trust_level + slot_trust_policy). (5) Footer: BC-2.18.001 description corrected to PromptTemplate F-String scope; BC-2.18.003 description corrected to MessagesPlaceholder/FewShot scope; BC-2.18.005 description corrected to construction guard scope."
  - "2.44 (burst-226/F-P131-01+F-P131-05+F-P131-06+F-P131-07/2026-07-21): (1) F-P131-05: ChatPromptTemplate section — TrustLevel migration. Added TrustLevel enum + TemplateVar struct definitions. MessageProvenance.tag → MessageProvenance.highest_trust_level. SlotTrustPolicy TrustRequired doc comment: ProvenanceTag::Trusted/Internal → TrustLevel::Trusted/None. format_messages BC anchor: BC-2.18.001↔BC-2.18.002 swap (format_messages rendering → BC-2.18.002; strict-undefined → BC-2.18.001). BC anchor footer: ProvenanceTag → TrustLevel; ADR-015 Decision 4 added. (2) F-P131-01: GuardedDocuments::rag_ingress docstring updated with severity-bifurcated Fail semantics (Critical → Err(E-CORE-008); Non-Critical → error-entry substitution). E-CORE-008 individual omission note added. (3) F-P131-07: similarity_search_with_filter default method doc updated: lossy fallback → fail-safe Err(E-VS-005 FilterUnsupported) on non-empty filter. (4) Disposition census 96→98: individual 16→17 (+E-CORE-008), blanket 37→38 (+E-VS-005)."
  - "2.43 (F-P130-03/2026-07-21): Add six missing D21 trait sections to §Public Rust Trait Signatures (F-P130-03 HIGH). Sections added with verbatim ADR-authoritative signatures + per-method BC anchors: (1) §Retriever Trait and GuardedDocuments — ADR-014 Decision 2 + Decision 6; anchors BC-2.20.001..003. (2) §VectorStore Trait and VectorStoreFactory — ADR-014 Decision 2; anchors BC-2.21.001..004. (3) §Embeddings Trait — ADR-017 Decision 2; anchors BC-2.22.001..003. (4) §ChatPromptTemplate and PromptValue Surface — ADR-015; anchors BC-2.18.001..005. (5) §LcSerializable and Reviver Surface — ADR-016; anchors BC-2.19.001..006. Coverage cross-check: all methods have BC anchors; no orphan methods found in either direction."
  - "2.42 (F-P224/H-1/2026-07-21): Blanket omission annotation updated for E-VS-004 (ZeroNormWriteTime, VAL, BC-2.21.002) minted in error-taxonomy.md v1.28. E-VS-* namespace 3→4 codes; blanket group total 36→37. Disposition census 95→96 (43 HTTP + 16 individual + 37 blanket = 96). E-VS-004 is library-layer only (write-path Err return from add_texts / from_texts_sync; no direct HTTP terminal response in v1)."
  - "2.41 (D21/Batch-3b-i/2026-07-20): Blanket omission annotation updated for D21 ecosystem-parity expansion. (1) Added four new component namespaces to §Library/execution-layer codes blanket omission: E-TMPL-* (BC-2.18.x, SECURITY/VAL), E-SRLZ-* (BC-2.19.x, VAL), E-VS-* (BC-2.20.x/BC-2.21.x, VAL), E-EMBED-* (BC-2.22.x, VAL) — all library-layer only per ADR-010 v1.1, no HTTP terminal responses. (2) Disposition census updated: 86→95 (blanket 27→36; 43 HTTP + 16 individual + 36 blanket = 95). (3) Note appended to §Error Type citing Component enum expansion 12→16 and #[non_exhaustive] gate count 13→17."
  - "2.40 (F-P124-01, fix burst 127, 2026-07-19): §MemoryStore — E-MEMORY-003 ScopeAccessDenied raise-site mis-anchored to memory_get; BC wins (BC-2.15.002 Invariant defines it as a WRITE error; PC1/TV-001 define cross-owner READ as Ok(None) — isolation-by-invisibility). Three changes: (1) memory_set docstring: added E-MEMORY-003 ScopeAccessDenied raise site with full struct form { requested_scope, caller_identity } (BC-2.15.002 Invariant). (2) memory_get docstring: removed E-MEMORY-003 raise site; replaced with BC-true cross-owner read semantics documenting isolation-by-invisibility (cross-owner reads return Ok(None) per BC-2.15.002 PC1/TV-001); E-MEMORY-004 NoScopeContext placement retained (correct per BC-2.15.002 EC-001). (3) BC anchor footer: E-MEMORY-003 re-anchored from memory_get to memory_set. Sweep of E-MEMORY-001/002/004: all PASS (E-MEMORY-001 on vector_search correct per BC-2.15.001 EC-001; E-MEMORY-002 on memory_set correct per BC-2.15.001 EC-004; E-MEMORY-004 on memory_get correct per BC-2.15.002 EC-001)."
  - "2.39 (OBS-P123-b, fix burst 126, 2026-07-19): §Public Rust Trait Signatures — add §MemoryStore block (OBS-P123-b promoted to blocker under production-grade lens). Derived strictly from BC-2.15.001 PC1–PC7 (6-method surface: memory_set/memory_get/memory_delete/memory_search/vector_search/hybrid_search) + BC-2.15.002 MemoryScope tier-isolation semantics (scope parameter on every method; storage-layer WHERE-predicate enforcement). Supporting types: MemoryScope enum (3 variants: User/App/Session) and MemoryEntry struct (scope/key/value/author_id) defined inline. Error raise sites cited per-method: E-MEMORY-001 (vector_search EC-001), E-MEMORY-002 (memory_set EC-004), E-MEMORY-003 (memory_get scope-mismatch per BC-2.15.002 Invariant, opt-in enforcement), E-MEMORY-004 (memory_get BC-2.15.002 EC-001). BC-2.15.003 GDPR erasure confirmed NOT a trait method (standalone admin fn requiring AdminContext); excluded. memory_delete_session (BC-2.15.002 Invariant) confirmed standalone store fn, not a trait method; excluded from the 6-method surface. Gate #31: MemoryScope RESOLVED, MemoryEntry RESOLVED, query_embedding RESOLVED. Cross-check: api-surface.md MemoryStore BC anchor range BC-2.15.001–003 verified accurate (no architect routing required). Ubiquitous-language-server.md MemoryStore entry (line 142) in sync. BC-2.15.006 PC1 method-name drift fixed in this burst (MemoryStore::get → MemoryStore::memory_get; MemoryScope::App scope type made explicit; EC-001 and Architecture Anchors updated; BC-2.15.006 version 1.1 → 1.2)."
  - "2.38 (F-P117-01, fix burst 120, 2026-07-19): summary_halt promoted to first-class terminal Run status throughout (Option 1 adjudication — BC-2.10.003 PC8(d) is authoritative). (1) §Run Object Schema status enum: add 'summary_halt' (in_progress → summary_halt via OnCeiling::Summarize per BC-2.10.003 PC8(d)). (2) status description: state machine enumeration gains '| summary_halt'. (3) completed_at terminal set: add 'summary_halt'. (4) output note: 'present only when status=completed or status=summary_halt; for summary_halt output=summarize model response (BC-2.10.003 PC8(c))'. (5) §Runs HTTP table GET runs filter: add summary_halt to status filter enumeration. (6) §Runs HTTP table DELETE runs description: add summary_halt to deletable terminal states."
  - "2.37 (F-P116-01, 2026-07-19): §CheckpointSaver — dyn-compatibility fixes per ADR-005 v1.3 §Object-Safety (F-P116-01). (A) `get_next_version` provided-method receiver: `&self` added as first parameter (was receiver-less, causing E0038 on Arc<dyn CheckpointSaver>). Rationale: dyn-compatibility requires a receiver on every non-Sized-bounded method; virtual dispatch of backend overrides through Arc<dyn CheckpointSaver> vtable requires &self; langgraph BaseCheckpointSaver.get_next_version is an instance method — prior 'static method' parity claim corrected (F-P116-01). Default body unchanged — still delegates to MonotonicClock::get_next_version(current, channel), ignoring &self. (B) `list` return type: `Result<impl Stream<Item = Result<CheckpointTuple, FerrochainError>>, FerrochainError>` → `Pin<Box<dyn Stream<Item = Result<CheckpointTuple, FerrochainError>> + Send>>`. Rationale: `impl Stream` opaque return is NOT dyn-compatible even with async-trait desugaring (E0038); Pin<Box<dyn Stream<Item = ...> + Send>> is the established dyn-compatible boxed-stream pattern for object-safe async traits. Authority: ADR-005 v1.3 §Object-Safety of the 5-Method CheckpointSaver Trait."
  - "2.36 (F-P115-02, 2026-07-19): §CheckpointSaver — add `put` and `get_next_version` methods (trait becomes 5-method). (A) `put` method: persists full checkpoint state blob; called once per run under DurabilityTier::Exit or at run completion (BC-2.04.002 PC4/EC-002, BC-2.04.001 EC-003); encrypted when EncryptedSerializer active (BC-2.04.007 PC1); raises E-CHKPT-005 on tenant-context conflict (BC-2.04.006 EC-005). BC anchor annotations: BC-2.04.002 PC4/EC-002, BC-2.04.001 EC-003, BC-2.04.006 PC2, BC-2.04.007 PC1+INV-1. (B) `get_next_version` provided method: default impl delegates to MonotonicClock::get_next_version; implementors MAY override; channel param accepted for API compatibility only (BC-2.04.003 PC1/PC5); E-CHKPT-002 on u64 overflow. BC anchor line extended: BC-2.04.001 through BC-2.04.007 with per-method precision. Gate #31 type note extended: Checkpoint and CheckpointMetadata (entities-graph.md §Checkpoint), CheckpointId (ADR-005 / BC-2.04.003 newtype over u64) added. Architect routing: api-surface.md CheckpointSaver row BC range 001–006 is now stale (needs 001–007); flagged for architect."
  - "2.35 (F-P100-02, 2026-07-17): Citation-completeness amendment — no behavioral change. /stream endpoint row BC citation extended from 'BC-2.11.002 PC3/PC4' to 'BC-2.11.002/003/004 PC3/PC4 (per-boundary)'. §StreamEvent BC anchor extended: BC-2.11.003 PC3/PC4 (GuardrailDecision emitted on Fail/Transform for RagChunk boundary) and BC-2.11.004 PC3/PC4 (GuardrailDecision for MemoryItem boundary) added alongside existing BC-2.11.002 PC3/PC4 (ToolResult boundary). GuardrailDecision fires symmetrically at all three ingress boundaries; prior citations listed only the ToolResult boundary BC. ADR-006 rev-4 is co-artifact."
  - "2.34 (F-P99-01, 2026-07-17): Axis (a) Add GuardrailDecision (12th StreamEvent variant) — fires for non-Pass guardrail outcomes (Fail/Transform only; Pass not streamed) at tool-result, RAG, and memory ingress boundaries. Audit-log-only is insufficient for Domain A SOC live-analyst use case (domain-a-soc-analyst.md §5 NEW forcing function); SSE consumer has zero in-band signal otherwise. Axis (b) ToolEnd.data carries POST-guardrail content — raw rejected payloads must not exit the security boundary via any StreamEvent (same isolation as model input buffer, BC-2.11.005 PC1). Axis (c) Ordering: GuardrailDecision fires before ToolEnd within the ToolStart/ToolEnd window (ToolResult boundary); within NodeStart/NodeEnd window before inference (RagChunk/MemoryItem boundaries). Axis (d) StreamEvent variant count 11→12; wire token guardrail_decision; supporting types IngressBoundary/GuardrailDecisionKind/GuardrailSeverityWire. New §StreamEvent section added to Public Rust Trait Signatures; /stream endpoint row updated to reference guardrail_decision events and ToolEnd post-guardrail semantics. ADR-006 rev-3 is co-artifact. Downstream PO amendments required: BC-2.06.001 PC2/PC4/new-EC-006, BC-2.11.002 PC3/PC4, BC-2.11.005 PC1/new-INV-5, BC-2.06.003 new-INV note."
  - "2.33 (F-P93-02, 2026-07-17): Adjudicate contradictory HITL-trigger model (F-P93-02 HIGH). VERDICT: Model A — `PolicyDecision::Escalate` (soft-ceiling) ALWAYS triggers the HITL interrupt unconditionally, independent of `BudgetConfig::on_ceiling`; `PolicyDecision::Deny` (hard-ceiling) branches on `on_ceiling` (Halt | Escalate→HITL | Summarize). BC authority: BC-2.10.001 PC3 — 'Escalate → execution suspends; the run transitions to `interrupted` via the HITL interrupt mechanism (BC-2.10.004)' — no on_ceiling qualification. Changes: (1) §OnCeiling enum docstring updated: field governs `PolicyDecision::Deny` dispatch ONLY; explicit statement that `PolicyDecision::Escalate` routes to HITL unconditionally per BC-2.10.001 PC3 without consulting `on_ceiling`. (2) `OnCeiling::Escalate` variant docstring updated: this variant means 'when `PolicyDecision::Deny` (hard ceiling) is received, redirect to HITL instead of halting'; clarifies both the soft-limit Escalate path and this hard-ceiling Deny→Escalate path use the same `BudgetEscalation` interrupt mechanism. (3) Engine-branching note replaced with a complete PolicyDecision × on_ceiling decision table — zero unspecified cells. Previously the note covered only `PolicyDecision::Deny` dispatch and left `PolicyDecision::Escalate` entirely unspecified. Now all three PolicyDecision variants are fully specified with Engine Action, Run Status, and Resume Mechanism columns. BC anchor updated to cite BC-2.10.001 PC3 as the Escalate-path authority. Sibling architecture docs (api-surface, module-decomposition) do not state the trigger model at decision-table precision — no change required."
  - "2.32 (F-P92-01-sweep, 2026-07-17): §RunnableConfig doc comment — stale verbatim citations to old BC-2.10.003 PC7 and BC-2.10.004 PC6 text updated to match new wording from same burst (F-P92-01/F-P92-02). Old PC7 quote: 'operator supplies a new RunnableConfig with a higher ceiling'. New: 'operator supplies a new RunnableConfig with budget_config: Some(BudgetConfig { hard_limit: Some(higher_ceiling), .. })'. Old PC6 quote: 'new_ceiling replaces the policy\\'s current ceiling in the RunnableConfig for the resumed execution'. New: 'The new_ceiling is applied by patching RunnableConfig::budget_config with BudgetConfig { hard_limit: Some(new_ceiling), ..original } for the resumed execution'. The struct definition itself (pub budget_config: Option<BudgetConfig>) was already correct from v2.31; this entry corrects only the inline authority citations in the doc comment. Exhaust-sweep finding: pattern 'policy\\'s.{0,20}ceiling' matched interface-definitions.md line 155 (prd-supplement, in-scope for fixes per task)."
  - "2.31 (F-P92-02, 2026-07-17): OPTION A adjudication — add `budget_config: Option<BudgetConfig>` to §RunnableConfig. Authority: BC-2.10.004 PC6 explicitly places new_ceiling 'in the RunnableConfig for the resumed execution'; BC-2.10.003 PC7/TV-004 say 'operator supplies a new RunnableConfig with a higher ceiling'. BudgetResume::Extend { new_ceiling } is processed by the engine, which patches RunnableConfig::budget_config with a cloned BudgetConfig{ hard_limit: Some(new_ceiling), ..original } before resuming — this applies the extended ceiling to only that resumed execution without mutating GraphConfig (which is shared across concurrent runs on the same graph). Formal §RunnableConfig struct block added with all four known fields (recursion_limit, thread_id, budget_config, context_mutations) and per-field BC citations. TOML [budget] comment updated: 'overridable per run' expanded with explicit reference to RunnableConfig::budget_config and BudgetResume::Extend mechanism. Sibling sweep: api-surface.md v1.3→v1.4 (new §ferrochain-core Public Types row for RunnableConfig), module-decomposition.md v1.9→v1.10 (budget definitions note extended). purity-boundary-map unchanged — BudgetConfig already a pure core type; adding Option<BudgetConfig> to RunnableConfig does not change core::config purity classification."
  - "2.30 (F-P91-04, 2026-07-17): Census update 85→86 — E-MEMORY-008 (MemoryStoreReadFailed, DURABILITY) minted in error-taxonomy.md v1.18 (BC-2.15.004 EC-004/TV-008 anchor). E-MEMORY-008 is covered by the existing E-MEMORY-* blanket annotation (§Library/execution-layer codes blanket omission); category DURABILITY is already in the blanket annotation category list (VAL/POLICY/DURABILITY/SECURITY); no HTTP routing row or blanket annotation body change needed. Updated census: 43 HTTP + 16 individual + 27 blanket = 86 (E-MEMORY-* 7→8 in blanket group; E-MCP-* 5 + E-SBXD-* 6 + E-RETRY-* 4 + E-BUDGET-* 2 + E-MEMORY-* 8 + E-SPLIT-* 2 = 27)."
  - "2.29 (F-P91-02/F-P91-03, 2026-07-17): F-P91-02 (MED) — add OnCeiling enum and BudgetConfig struct to §BudgetPolicy; both are SS-10 public API surface items absent from the interface spec, leaving implementers unable to build the halt-vs-summarize branch without them. OnCeiling variants: Halt | Escalate | Summarize { summarize_prompt: String } per BC-2.10.003 v1.2 Architecture Anchors + BC-2.10.004. BudgetConfig fields: soft_limit: Option<u64> (Escalate threshold — BC-2.10.001 TV-002), hard_limit: Option<u64> (Deny threshold — BC-2.10.001 TV-003), on_ceiling: OnCeiling (BC-2.10.003 + BC-2.10.004). Prose paragraph added: engine branches on BudgetConfig::on_ceiling after Deny; BudgetPolicy::evaluate stays pure; ADR-009 Option 3 section anchor. BC anchor updated: BC-2.10.003 + BC-2.10.004 + ADR-009 added; TV citation text updated. F-P91-03 (OBS) — fix TOML default_on_ceiling comment: state that 'summarize' is config-API-only (requires summarize_prompt payload; not expressible as a bare-string default; table form documented). Sibling sweep: module-decomposition.md budget note + purity-boundary-map.md core::budget row updated with OnCeiling and BudgetConfig."
  - "2.28 (F-P88-01, 2026-07-17): Version/changelog/timestamp propagation for pass-87 burst body changes. Pass-87 (bc-authoring-plan v2.21) added §CLI Interface, §Exit Code Semantics, and §JSON Output Schema stubs; renamed §'Flag Interaction Rules' → §'Flag Interactions'; and normalized input-hash from legacy 64-char SHA-256 to 7-char MD5 ('cdce094'). Those body modifications landed without a corresponding version/timestamp bump, leaving the file at v2.27/2026-07-15. Correction applied: version 2.27 → 2.28, timestamp → 2026-07-17. No semantic content changes in this entry."
  - "2.27 (2026-07-15, F-P83-01/F-P83-02): Mandatory sibling sweep of all BC anchor lines — two mis-citations corrected. F-P83-01 (ToolCallDialect §ProviderFallbackPolicy, line ~314): old citation 'BC-2.08.013 PC1–PC4 (object-safe trait contract, built-in impls, E-PROV-009 on parse failure)' was wrong on two counts — PC1–PC4 cover only the NativeOpenAiJson and NativeAnthropic dialect round-trips; object-safety lives at PC10; E-PROV-009 is raised at PC8 (HermesChatMlXml malformed JSON) and PC9 (any dialect serialize/deserialize error). Fixed to 'BC-2.08.013 PC1–PC9 (built-in dialect round-trips; PC8/PC9 = E-PROV-009 on parse failure) + PC10 (object-safe trait contract)'. F-P83-02 (ProviderFallbackPolicy, line ~336): old citation 'BC-2.08.014 PC1–PC4 (ordered fallback semantics, E-PROV-010 on chain exhaustion)' incorrectly attributed E-PROV-010 to the PC1–PC4 block; PC4 = ordered chain semantics (no error raised); E-PROV-010 is raised at PC5 (chain exhausted postcondition). Fixed to 'BC-2.08.014 PC1–PC4 (ordered fallback semantics) + PC5 (E-PROV-010 on chain exhaustion)'. Sweep covered all 13 BC anchor locations in the file; no other mis-citations found. Disposition census unchanged: 43 HTTP + 16 individual + 26 blanket = 85."
  - "2.26 (2026-07-15, F-P82-02): E-CHKPT-008 omission note raise-timing corrected. Previous wording stated both sub-cases were raised 'at construction time', which was wrong for the malformed-FTS5-query case. Fixed: (1) `FtsSearchConfig.limit = 0` raised at FtsSearchConfig construction time (BC-2.04.008 PC6/EC-004); (2) malformed FTS5 query string raised at fts_search call time via SQLite FTS5 parse error propagation (BC-2.04.008 EC-002). Clarified that `query` is a standalone first parameter to fts_search, NOT a field of FtsSearchConfig. BC citations split to match each sub-case. Disposition census unchanged: 43 HTTP + 16 individual + 26 blanket = 85."
  - "2.25 (F-P78-SWEEP, 2026-07-15): Gate #33 step-11 follow-through — E-CORE-006 dual-layer table Runnable-layer row corrected. Message was 'recursion limit exceeded at depth N'; corrected to 'RecursionLimitExceeded: recursion limit exceeded at depth <depth>'. (1) Added 'RecursionLimitExceeded:' prefix per D18-P78-A universal <ErrorName>: convention. (2) Changed placeholder N → <depth> for consistency with BC-2.01.003 PC5 authoritative template (updated in same burst). This is the only message string in the dual-layer table; no other content changed. Disposition census unchanged: 43 HTTP + 16 individual + 26 blanket = 85."
  - "2.24 (F-P78-02/F-P78-03, 2026-07-15): Fix two omission-note BC-anchor citations that pointed at success-path PCs/ECs (OBS-P78-E gate #33 step-11 violation class). F-P78-02 — E-PROV-010 note corrected: 'BC-2.08.014 PC4/EC-002' → 'BC-2.08.014 PC5/EC-004'. BC-2.08.014 PC4 = ordered-chain semantics (no error raised); EC-002 = primary auth-refresh success path. Correct raising points: PC5 (chain exhausted postcondition explicitly returns E-PROV-010) and EC-004 (all-providers-exhausted scenario). F-P78-03 — E-PROV-009 note corrected: 'BC-2.08.013 PC4/EC-002' → 'BC-2.08.013 PC8/PC9/EC-002'. BC-2.08.013 PC4 = NativeAnthropic success-parse of tool_use blocks. Correct raising points: PC8 (Hermes <tool_call> payload not valid JSON → E-PROV-009) and PC9 (any dialect serialize/deserialize error → E-PROV-009); EC-002 correctly cites malformed JSON case."
  - "2.23 (F-P74-01, 2026-07-15): Fix retired spelling CheckpointStore::fts_search → CheckpointSaver::fts_search in E-CHKPT-008 library-layer omission note (~line 542). CheckpointSaver is the canonical trait name; CheckpointStore was retired. Full-file scan for other retired spellings (RunConfig, BaseCheckpointSaver, AIMessage-in-Rust-context, Checkpointer-as-type): none found."
  - "2.22 (pass-72 fix, 2026-07-15): F-P72-01 + F-P72-06 — fix SkillStore trait signatures to BC/ADR-authoritative name-keyed + tag-filtered forms (load_skill/skill_exists take name: &str; list_skills takes tags: &[String]) per BC-2.15.004 PC1-PC3 + ADR-012 Decision 1 Primitive A; name→(namespace,key) storage mapping is impl-internal (BC-2.15.004 Invariant). Fix Replace.old_value from Value to Option<Value> per ADR-012 Decision 1 Primitive C (None=unconditional replace; Some(v)=match-based replace) + BC-2.15.005 PC2. Gate #31 SkillStore row stays RESOLVED with corrected shapes; MemoryWriteRequest RESOLVED note unchanged (variant structure correct, type corrected). D18-P72-A + D18-P72-B adjudicated."
  - "2.21 (D20 TOUCH-UP burst): Residue 1 — §BudgetPolicy RunContext inline note updated: added field `budget_info: Option<BudgetInfo>` (BC-2.10.003 v1.2 PC5/INV); `BudgetInfo` struct defined inline with fields `tokens_remaining: Option<i64>` and `steps_remaining: Option<u32>` (gate #31 RESOLVED). BC anchor updated to cite BC-2.10.003. Disposition census unchanged: 43 HTTP table rows, 16 individual omission notes, 26 blanket library-layer coverage entries = 85. CORRIGENDUM (Residue 2): This document's split (43 HTTP + 16 individual + 26 blanket = 85) is the verified correct partition; error-taxonomy.md v1.11 erroneously stated 44 HTTP + 15 individual + 26 blanket = 85 — the split error arose because the E-CORE-004 move (HTTP table → individual omission note, interface-definitions.md v2.19) was not reflected in error-taxonomy.md v1.10 census; corrected in error-taxonomy.md v1.12."
  - "2.20 (D20 INTEGRATE sub-burst 2): Four new §Public Rust Trait Signatures added: §ToolCallDialect (BC-2.08.013 — object-safe dialect seam for tool-call serialization; built-ins NativeOpenAiJson/NativeAnthropic/HermesChatMlXml), §ProviderFallbackPolicy (BC-2.08.014 — ordered fallback chain struct; ProviderCredential/CredentialRefreshConfig flagged UNRESOLVED implementer-scope for architect), §SkillStore (BC-2.15.004 — async trait with SkillDescriptor inline struct), §MemoryWriteGuard (BC-2.15.005 — pure sync guard with MemoryWriteRequest + WriteGuardDecision inline enums). Blanket omission MEMORY annotation: VAL/POLICY/DURABILITY → VAL/POLICY/DURABILITY/SECURITY (+E-MEMORY-007 SECURITY). Four individual omission notes added: E-CHKPT-008 (VAL), E-CHKPT-009 (INTERNAL), E-PROV-009 (VAL), E-PROV-010 (POLICY) — all library-layer Err, never direct HTTP terminal. Gate #31 census: 19/21 → 25/28 resolved (+ToolCall, SkillDescriptor, MemoryWriteRequest, WriteGuardDecision all RESOLVED; ProviderCredential, CredentialRefreshConfig UNRESOLVED). Disposition census 78→85: 43 HTTP table rows, 16 individual omission notes (+4), 26 blanket library-layer coverage entries (+3: E-MCP-005 in MCP blanket, E-SBXD-006 in SBXD blanket, E-MEMORY-007 in MEMORY blanket)."
  - "2.19 (ADV-P1D-PASS-69): F-P69-01 — fix 400 row range-shorthand category mismatch: 'E-CORE-001 through E-CORE-005' silently included E-CORE-004 (INTERNAL, not VAL). (1) 400 row: range replaced with explicit VAL enumeration 'E-CORE-001, E-CORE-002, E-CORE-003, E-CORE-005' — each verified VAL in error-taxonomy.md (lines 68-70, 72). (2) E-CORE-004 (INTERNAL — BC-2.01.004 PC5, pipe-composition type-boundary mismatch) given individual omission note mirroring E-CORE-006/E-CORE-007 (library-layer Err return, never direct HTTP terminal; INTERNAL→500 categorical fallback). (3) Range sweep: 'E-CORE-001 through E-CORE-005' was the only range expression in the status table rows — no other ranges found. Disposition census 78→78: 43 HTTP table rows (−E-CORE-004 from 400 row), 12 individual omission notes (+E-CORE-004 library-layer note), 23 blanket library-layer coverage, 0 uncovered."
  - "2.18 (ADV-P1D-PASS-67): F-P67-01 — fix 422 row cross-reference enumeration: DURABILITY/INTERNAL E-CHKPT codes listed as routed to the 500 row omitted E-CHKPT-007 (CipherHeaderMissing, INTERNAL), which IS in the 500 row. Enumeration corrected from (E-CHKPT-001, -002, -003, -004, -006) to (E-CHKPT-001, -002, -003, -004, -006, -007). Gate #21 cross-row routing-enumeration completeness sub-check applied — all inter-row enumerations verified. Disposition census unchanged: 44 HTTP table rows, 11 individual omission notes, 23 blanket library-layer coverage, 0 uncovered."
  - "2.17 (ADV-P1D-PASS-66): F-P66-03 — remove E-SERVER-005 (CorsRejected, POLICY) from 403 row; code RETIRED (tombstone in error-taxonomy.md v1.9). BC-2.12.005 PC2/TV-001 specifies CORS denial as silent header-omission — no error body is ever emitted; listing E-SERVER-005 in the 403 row misled implementers toward building explicit CORS error bodies. 403 row description updated to remove 'CORS'. E-PROV-007 omission note updated to remove E-SERVER-005 from the list of direct-403 codes. Disposition census 79→78: 44 HTTP table rows (−E-SERVER-005), 11 individual omission notes, 23 blanket library-layer coverage, 0 uncovered. Gates #20 POLICY census + gate #21 §17-C re-run: all remaining POLICY codes correctly mapped (E-SERVER-004 → 403 direct; E-GRAPH-013 → 403 direct; others library-layer or per-endpoint overrides). PASS."
  - "2.16 (ADV-P1D-PASS-61): F-P61-02 (MED) + F-P61-01 (HIGH, partial) — §BudgetPolicy context param corrected per orchestrator canon D18-P61-A. (1) Rename context param &BudgetContext → &RunContext: BC-2.10.001 precondition 3 names RunContext (thread_id, run_id, sub-agent identity) as the context type; BudgetContext was minted without corpus search (gate #31 near-name blindspot); BudgetContext RETIRED per gate #19. (2) RunContext implementer-scope note replaced with RESOLVED note: precondition 3 fully enumerates fields (thread_id, run_id, sub-agent identity) → RunContext is RESOLVED, not implementer-scope. Citation corrected: BC-2.10.001 precondition 3 (NOT PC3/INV — those sections describe PolicyDecision and purity, not context contents). (3) BC anchor note updated: precondition 3 authority added."
  - "2.15 (ADV-P1D-PASS-60): F-P60-01 (HIGH) + F-P60-02 (MED) + F-P60-03 (HIGH) — rewrite §BudgetPolicy block per orchestrator adjudication D18-P60-A (authority-deference: BC-2.10.001–004 are behavioral authority). (1) Rename BudgetDecision → PolicyDecision (BC-2.10.001 PC3 — three-variant contract is the canonical name); BudgetDecision retired per gate #19. (2) Add current_usage: TokenUsage payload to Escalate and Deny variants (BC-2.10.001 PC3, TV-002, TV-003 — F-P60-02). (3) Rewrite evaluate signature: remove async (pure/sync per BC-2.10.001 INV + ADR-009); remove run_id param; remove journal param (journal writes are caller responsibility per BC-2.10.001 INV + ADR-009); add context: &BudgetContext second param (BC-2.10.001 PC1/PC2 two-param canon) — F-P60-03. (4) BudgetContext flagged implementer-scope (shape not enumerated in spec corpus; BC-2.10.001 PC3/INV provides contextual description — same treatment as ChatConfig). (5) BC anchors corrected: BC-2.10.001 PC3 + TV-001–TV-003 + BC-2.10.002 INV."
  - "2.14 (ADV-P1D-PASS-59): F-P59-01 (HIGH) — fix GuardrailSeverity::Critical authority mis-citations. BC-2.11.003 INV-2 (ordering invariant) → BC-2.11.003 PC3 (Critical severity rule); BC-2.11.004 INV-4 (ordering invariant) → BC-2.11.004 PC3 (Critical severity rule). Correct authority: BC-2.11.002 INV-3, BC-2.11.003 PC3, BC-2.11.004 PC3, BC-2.11.005 PC4. F-P59-02 (HIGH) — fix Transform doc-comment cross-boundary claim: replace 'any IngressContent variant, including a different variant from the original' with same-boundary rule (new_content must be same IngressContent variant; inner payload may change freely — e.g. different ContentBlock variant within ToolResult per BC-2.11.002 EC-003). No BC authorizes cross-boundary transforms (e.g. ToolResult→RagChunk)."
  - "2.13 (ADV-P1D-PASS-58): F-P58-02 (HIGH) + F-P58-01 (MED) — define IngressContent and GuardrailSeverity inline in §GuardrailHook block. (1) IngressContent enum: ToolResult(ContentBlock) / RagChunk(Value) / MemoryItem(Value) — BC-2.11.002 PC1 / BC-2.11.003 PC1,PC5 / BC-2.11.004 PC1,PC5; E-CORE-007 content_type placeholder resolved to IngressContent variant name. (2) GuardrailSeverity enum: Critical/High/Medium/Low — authority BC-2.11.002 INV-3, BC-2.11.005 PC4/PC5. (3) Minimal type notes added for ChatConfig (BaseChatModel) and CheckpointConfig (CheckpointSaver) per gate #31 census — both flagged corpus-unresolved for architect. Gate #31 census: 20/22 types resolved; ChatConfig and CheckpointConfig flagged."
  - "2.12 (ADV-P1D-PASS-57): F-P57-01 (HIGH) — fix GuardrailHook trait signature trilateral contradiction (authority-deference D18-P47-A: BCs win). (1) Method name on_ingress → evaluate (all 6 ss-11 BC postconditions + E-CORE-007 taxonomy message are uniform). (2) Return type Result<IngressContent, GuardrailError> → GuardrailResult enum with Pass / Fail{reason,severity} / Transform{new_content} variants (BC-2.11.002 PC2-PC4). (3) Second parameter renamed provenance → provenance_tag per BC-2.11.002 INV-4. (4) GuardrailResult enum definition added to §GuardrailHook block with Fail/Transform variant bodies. (5) Panic path moved to doc-comment citing E-CORE-007 and BC-2.11.002 EC-001 (panic is a non-return code path; the trait method return type is GuardrailResult not Result). (6) GuardrailError type removed — not defined in spec corpus; was incorrect. BC anchor enumeration expanded to cite all 6 BCs by role."
  - "2.11 (ADV-P1D-PASS-56-COMPLETION): Gate #30 drain — three new codes from error-taxonomy.md v1.8. (1) E-PROV-008 (ProviderHttpError, TRANSPORT) added to 502 row alongside E-PROV-003 — categorical fallback, surfaced embedded in Run.error. (2) E-CHKPT-007 (CipherHeaderMissing, INTERNAL) added to 500 row alongside other CHKPT INTERNAL codes. (3) E-CORE-007 (GuardrailHookPanic, INTERNAL) individual omission note added — library-layer INTERNAL error, never direct HTTP terminal in v1; INTERNAL→500 categorical fallback. Disposition census 76→79: 45 HTTP table rows (+E-PROV-008 +E-CHKPT-007), 11 individual omission notes (+E-CORE-007), 23 blanket library-layer coverage, 0 uncovered."
  - "2.10 (ADV-P1D-PASS-56): F-P56-01 — add E-CORE-006 (RecursionLimitExceeded, INTERNAL — BC-2.01.003 PC5) to dual-layer table Runnable-layer row; add E-CORE-006 individual omission note (INTERNAL, library-layer Err return, never direct HTTP response in v1; INTERNAL→500 categorical fallback). OBS-P56-1 resolved: tighten 10007 text in dual-layer note to cite `DEFAULT_RECURSION_LIMIT` constant in `langgraph._internal._config` (reads from `LANGGRAPH_DEFAULT_RECURSION_LIMIT` env var) and distinguish from langchain-core `DEFAULT_RECURSION_LIMIT = 25`. Disposition census 75→76: 43 HTTP table rows, 10 individual omission notes (+E-CORE-006), 23 blanket library-layer coverage, 0 uncovered."
  - "2.9 (ADV-P1D-PASS-55): F-P55-01 — add E-SERVER-013 (InvalidDebugRouteKey, VAL — BC-2.12.005 EC-005/TV-007) startup-only omission note; raised at boot before any HTTP listener is bound, never surfaced as a terminal HTTP response (same treatment as E-CHKPT-005). Full disposition census: 75 live codes — 43 HTTP table rows, 9 explicit individual omission notes, 23 blanket library-layer coverage, 0 uncovered."
  - "2.8 (ADV-P1D-PASS-49): F-P49-02 — add RunnableConfig recursion_limit dual-interpretation note (§Runnable trait); add E-GRAPH-017 (GraphRecursionLimitExceeded, POLICY — BC-2.03.001 PC5) to the graph execution errors embedded-in-Run.error blockquote. No HTTP status table row change (E-GRAPH-017 surfaces embedded in Run.error, never as a direct terminal HTTP status; POLICY→403 categorical fallback applies only if ever surfaced directly — not in v1)."
  - "2.7 (ADV-P1D-PASS-48): F-P48-01 fix E-RETRY-* blanket omission annotation — E-RETRY-004 (VAL, minted P34) expands namespace to POLICY/VAL; annotation corrected from POLICY to POLICY/VAL. OBS-P48-1 (adjudicated D17-Q2 FIFO-resume contract) add FIFO-only documentation line to Resume Request Schema: REST resume delivers to single active interrupt slot FIFO; targeted delivery by interrupt_id is library-API only (Command(resume={interrupt_id: value}), BC-2.05.004 EC-002)."
  - "2.6 (ADV-P1D-PASS-47): F-P47-01 (CRITICAL) fix Flag Interaction Rules row for sandbox-wasm+container-both-off — remove silent-process-fallback claim, replace with SandboxBackend::default()→Err(E-SBXD-003 SandboxInitFailed) per BC-2.13.001 PC4/EC-002/DI-006/NE-01; F-P47-02 fix [sandbox] config comment 'process emits WARNING on startup'→'once per execute() invocation — NOT construction/startup' per BC-2.13.002 PC2/EC-002; OBS-P47-1 add sandbox-process row to Cargo Feature Flags table with NOT-enforcing/explicit-constructor-only semantics per BC-2.13.001 PC3/PC4."
  - "2.5 (ADV-P1D-PASS-46): F-P46-01 — clarify /stream row description: run_end is emitted on completion only; interrupt and failure paths truncate stream without run_end (BC-2.06.001 PC2 + EC-005 authority; BC-2.12.007 v1.2)."
  - "2.4 (ADV-P1D-PASS-33): F-P33-01 add BC-2.12.002 PC21-PC23 to §Canonical Pagination Convention BC anchors list (list-assistants anchor). F-P33-02 add run-config merge precedence note to POST /threads/{thread_id}/runs row description (deep-merge over Assistant config, run wins at leaf key; BC-2.12.003 §Run-Config Merge Precedence Invariant)."
  - "2.3 (ADV-P1D-PASS-32): F-P32-03 add canonical pagination to GET /assistants/{id}/versions row (limit default 10 max 100 clamped / offset / ordering exemption: version ASC — deviates from created_at DESC default); BC-2.12.002 PC20 added as anchor. OBS-P32-1 add no-list-schedules note in §Cron Schedules."
  - "2.2 (ADV-P1D-PASS-31): F-P31-01 add §Canonical Pagination Convention section; propagate limit (default 10, max 100, silently clamped if > 100) + offset (default 0) + created_at DESC ordering to GET /threads (explicit defaults), GET /threads/{id}/history (declare default 10/max 100 on existing limit), GET /assistants (add limit/offset), GET /threads/{id}/runs (add limit/offset alongside status filter), GET /runs?schedule_id={cron_id} (add limit/offset, declare created_at DESC). Out-of-range canon: clamp (not reject). BC anchors: BC-2.12.001 PC8/PC17, BC-2.12.003 PC18, BC-2.12.004 PC7."
  - "2.1 (ADV-P1D-PASS-30): F-P30-01 blanket omission note: TOOL→N/A corrected to TOOL→422 (BC-2.14.002 PC3 categorical authority); full 12-category token diff applied — added TRANSPORT→502 and INTERNAL→500 (both present in family labels but absent from summary); corrected VAL→400/422 to VAL→400 (categorical default; 422 requires per-endpoint override decision, not applicable to library-layer fallback)."
  - "2.0 (ADV-P1D-PASS-29): F-P29-03 fix SSE description on /stream row: node_start/delta/end → node_start/stream/end (node_delta was never canonical; BC-2.06.001 is the streaming taxonomy authority). OBS-P29-1 add blanket omission note for library/execution-layer codes (E-MCP-*, E-SBXD-*, E-RETRY-*, E-BUDGET-*, E-MEMORY-*, E-SPLIT-*) confirming none has a direct HTTP row."
  - "1.9 (ADV-P1D-PASS-28): OBS-P28-3 add E-PROV-007 (StructuredOutputRefused, POLICY) omission note — categorical POLICY→403 fallback only; surfaced embedded in Run.error, not as a direct terminal HTTP status."
  - "1.8 (ADV-P1D-PASS-27): F-P27-01 add E-GRAPH-002 (POLICY→422 per-endpoint override) to 422 row; F-P27-02/03 replace 'all E-CHKPT-*' over-broad text with specific enumeration, add E-CHKPT-004 (INTERNAL) to 500 row, add E-CHKPT-005 omission note; F-P27-04 add E-GRAPH-013 (SECURITY) to 403 row, add E-GRAPH-001/014/016 embedded omission notes; 422 row description updated to note POLICY→422 overrides."
  - "1.7 (ADV-P1D-PASS-26): F-P26-04 config comment X-Debug-Key+/debug/*→Authorization:Bearer+/_debug; F-P26-05 rewrite 401 row with E-PROV-004 categorical-fallback; OBS-1 narrow 422 wildcard to enumerated VAL E-GRAPH codes; OBS-2 add E-CRON-001/003 intentional-omission note; OBS-3 add E-PROV-005/006 to 400 row with embedded-in-Run.error annotation."
  - "1.6 (ADV-P1D-PASS-25): F-P25-01 add 503 row (E-SERVER-016 IdempotencyLockTimeout per-endpoint override); F-P25-02 recategorize 401→reserved, 403 now E-SERVER-004 POLICY + E-SERVER-005; F-P25-06 reconcile Run.interrupt sub-fields (interrupt_id, node_name, value, action_risk, action, context added; node_id→node_name, risk_tier→action_risk renamed); F-P25-07 add 201 and 204 rows, add E-CRON-002 to 400 row; OBS-2 add 502 and 504 categorical fallback rows."
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
input-hash: "b65b2b0"
traces_to: prd.md
primary_consumers: [implementer, test-writer, devops-engineer]
note: "ferrochain is a Rust library framework, not a CLI tool. 'Interface' covers public Rust traits/types, ferrochain-server HTTP API, Cargo feature flags, and config schemas."
---

# Interface Definitions: ferrochain

> PRD supplement — extracted from PRD Section 3.
> ferrochain is a library crate workspace, not a CLI application.
> The public interface is the set of public Rust traits, types, and the
> ferrochain-server HTTP API.

## CLI Interface

ferrochain is a Rust library framework — there is no standalone CLI tool. The interface surface consists of: (a) public Rust traits and types (see §Public Rust Trait Signatures below), (b) the embedded `ferrochain-server` HTTP API (see §ferrochain-server HTTP API below), and (c) Cargo feature flags (see §Cargo Feature Flags below). All interface contracts are expressed in Rust types; there are no command-line flags or environment variable arguments.

## Public Rust Trait Signatures (ferrochain-core)

### Runnable\<Input, Output\>

```rust
pub trait Runnable<Input, Output>: Send + Sync {
    /// Invoke the runnable synchronously (blocks async task).
    async fn invoke(&self, input: Input, config: Option<RunnableConfig>)
        -> Result<Output, FerrochainError>;

    /// Invoke and stream output chunks.
    async fn stream(&self, input: Input, config: Option<RunnableConfig>)
        -> Result<impl Stream<Item = Result<Output, FerrochainError>>, FerrochainError>;

    /// Invoke in batch; returns results in input order.
    async fn batch(&self, inputs: Vec<Input>, config: Option<RunnableConfig>)
        -> Result<Vec<Result<Output, FerrochainError>>, FerrochainError>;

    /// Pipe this runnable into another: self | other.
    fn pipe<NextOutput>(self, next: impl Runnable<Output, NextOutput>)
        -> impl Runnable<Input, NextOutput>
    where
        Self: Sized;
}
```

**BC anchor:** BC-2.01.003, BC-2.01.004

#### RunnableConfig Key Reference — `recursion_limit` Dual-Layer Interpretation (F-P49-02, ADV-P1D-PASS-49)

`recursion_limit: usize` (default **25**) in `RunnableConfig` serves two distinct enforcement
purposes at two independent layers. Both read the same key; enforcement, error code, and
failure scope differ:

| Layer | What is counted | Halt condition | Error | BC authority |
|-------|----------------|---------------|-------|-------------|
| **Runnable-layer** (ferrochain-core) | Nested `invoke`/`stream` call depth across chained Runnables (e.g., A pipes into B pipes into C…) | Depth exceeds `recursion_limit` | `Err(FerrochainError { category: INTERNAL, code: E-CORE-006, message: "RecursionLimitExceeded: recursion limit exceeded at depth <depth>" })` | BC-2.01.003 PC5 |
| **Graph-engine-layer** (ferrochain-graph BSP loop) | Super-steps per invocation segment; `stop = step_at_invoke_start + recursion_limit + 1` | `current_step > stop` before dispatching next super-step | `Err(E-GRAPH-017 GraphRecursionLimitExceeded)` — run transitions to `failed` | BC-2.03.001 PC5-PC6 |

Upstream parity: LangGraph reuses the same `RunnableConfig.recursion_limit` key for both layers.
LangGraph's graph-layer default is 10007 (the `DEFAULT_RECURSION_LIMIT` constant in the
`langgraph._internal._config` module reads from the `LANGGRAPH_DEFAULT_RECURSION_LIMIT`
environment variable with a hardcoded default of 10007 — verified against
`.reference/langgraph/langgraph/_internal/_config.py` `DEFAULT_RECURSION_LIMIT`
symbol; distinct from langchain-core's `DEFAULT_RECURSION_LIMIT = 25` in
`langchain_core.runnables.config` which is the Runnable-layer default); ferrochain
aligns both layers at 25 per langchain-core `RunnableConfig` convention. The graph-engine-layer
halt produces a run-level failure embedded in `Run.error` (see embedded omission note below).

#### RunnableConfig — Struct Definition (F-P92-02)

```rust
/// Per-invocation execution config passed to every `Runnable` method.
/// Carries per-run overrides for runtime parameters; absent/`None` fields inherit
/// the graph-level or system defaults.
///
/// Module: `ferrochain-core/src/config.rs` (`core::config`), re-exported at crate root.
/// All fields are optional at construction except `recursion_limit` (has a default).
pub struct RunnableConfig {
    /// Maximum Runnable call depth (Runnable-layer) and graph super-step count
    /// (graph-engine-layer). Default: 25. Dual-layer semantics documented above in
    /// §RunnableConfig Key Reference.
    /// Authority: BC-2.01.003 PC5 (Runnable-layer halt), BC-2.03.001 PC5 (graph-layer halt).
    pub recursion_limit: usize,

    /// Thread identity for checkpoint addressing. `None` = stateless run (no prior
    /// thread context shared; each invocation is isolated — BC-2.12.004 PC1/EC-001).
    /// Authority: BC-2.12.004 (schedule thread assignment), entities-server.md §Run.
    pub thread_id: Option<Uuid>,

    /// Per-run budget policy override.
    ///
    /// - `None` → inherit `GraphConfig::budget_config` for this run (graph-level default).
    /// - `Some(bc)` → use `bc` for this run or resumed execution; `GraphConfig::budget_config`
    ///   is ignored for the duration of this invocation.
    ///
    /// **Precedence rule:** `RunnableConfig::budget_config = Some(_)` takes priority over
    /// `GraphConfig::budget_config` for the single run or resumed execution. The graph-level
    /// config is NOT mutated — concurrent runs on the same graph are unaffected.
    ///
    /// **BudgetResume::Extend mechanism:** When the execution engine processes a
    /// `Command(resume = BudgetResume::Extend { new_ceiling })`, it constructs a patched
    /// `BudgetConfig { hard_limit: Some(new_ceiling), ..original }` and places it in
    /// `RunnableConfig::budget_config` for the resumed execution. This is the canonical
    /// mechanism by which the extended ceiling is applied to only that resume.
    ///
    /// Authority: BC-2.10.003 PC7 ("operator supplies a new `RunnableConfig` with
    /// `budget_config: Some(BudgetConfig { hard_limit: Some(higher_ceiling), .. })`"),
    /// BC-2.10.003 TV-004 (halted checkpoint resumable via new RunnableConfig with budget_config),
    /// BC-2.10.004 PC6 ("The `new_ceiling` is applied by patching `RunnableConfig::budget_config`
    /// with `BudgetConfig { hard_limit: Some(new_ceiling), ..original }` for the resumed execution").
    pub budget_config: Option<BudgetConfig>,

    /// Per-run memory context mutation spec. Declares which memory keys are loaded as a
    /// frozen-snapshot prompt prefix at run start (`graph::scheduler`). `None` = no memory
    /// context loaded for this run. Writes during the run are visible at next run start only.
    /// Authority: BC-2.15.006 PC1 (frozen-snapshot context mutation at run start),
    /// ADR-012 Decision 1 Primitive B.
    pub context_mutations: Option<ContextMutationConfig>,
}
```

**BC anchor:** BC-2.01.003 PC5 (`recursion_limit` Runnable-layer), BC-2.03.001 PC5 (`recursion_limit` graph-layer), BC-2.12.004 PC1 (`thread_id`), BC-2.10.003 PC7/TV-004 (`budget_config` resume path), BC-2.10.004 PC6 (`budget_config` BudgetResume::Extend), BC-2.15.006 PC1 (`context_mutations`)

### BaseChatModel

```rust
pub trait BaseChatModel: Runnable<Vec<Message>, AiMessage> + Send + Sync {
    fn model_name(&self) -> &str;
    async fn stream_chat(&self, messages: Vec<Message>, config: Option<ChatConfig>)
        -> Result<impl Stream<Item = Result<AiMessageChunk, FerrochainError>>, FerrochainError>;
    async fn bind_tools(&self, tools: Vec<ToolDefinition>) -> impl BaseChatModel;
    fn with_structured_output<T: DeserializeOwned>(&self) -> impl Runnable<Vec<Message>, T>;
}
```

**BC anchor:** BC-2.08.001 through BC-2.08.005

> **Gate #31 type note — `ChatConfig`, `AiMessageChunk`, `ToolDefinition`:** `ChatConfig` is a provider-specific streaming-configuration struct (temperature, max_tokens, etc.); not formally enumerated in the spec corpus — implementer defines as a provider-specific struct; flagged corpus-unresolved. `AiMessageChunk` is the per-token streaming output type; defined via BC-2.08.001 PC1 + BC-2.08.005 TV (streaming completions BC). `ToolDefinition` is the public tool-schema type; defined via BC-2.08.009 (tool schema naming stability BC).

### CheckpointSaver

```rust
pub trait CheckpointSaver: Send + Sync {
    /// Persist task outputs before the next super-step.
    async fn put_writes(
        &self,
        config: CheckpointConfig,
        writes: &[(ChannelName, ChannelValue)],
        task_id: TaskId,
    ) -> Result<(), FerrochainError>;

    /// Load the most recent checkpoint matching the config.
    async fn get_tuple(&self, config: &CheckpointConfig)
        -> Result<Option<CheckpointTuple>, FerrochainError>;

    /// List checkpoints for a thread (newest first).
    async fn list(&self, config: &CheckpointConfig, limit: Option<usize>)
        -> Pin<Box<dyn Stream<Item = Result<CheckpointTuple, FerrochainError>> + Send>>;

    /// Persist a full checkpoint state blob.
    ///
    /// Called once per run under `DurabilityTier::Exit`, or at the end of any run that
    /// produced a complete checkpoint (BC-2.04.002 PC4/EC-002, BC-2.04.001 EC-003).
    /// Both `checkpoint` and `metadata` bytes are encrypted when an `EncryptedSerializer`
    /// is active (BC-2.04.007 PC1).
    ///
    /// # Errors
    /// - `Err(FerrochainError { category: TENANCY, code: "E-CHKPT-005" })` if the composite
    ///   triple `(config.thread_id, config.checkpoint_ns, config.checkpoint_id)` already
    ///   exists under a different tenant context (BC-2.04.006 EC-005).
    async fn put(
        &self,
        config: CheckpointConfig,
        checkpoint: Checkpoint,
        metadata: CheckpointMetadata,
    ) -> Result<(), FerrochainError>;

    /// Compute the next monotonic checkpoint ID for a `(thread_id, checkpoint_ns)` pair.
    ///
    /// Default implementation delegates to `MonotonicClock::get_next_version`.
    /// Implementors MAY override for backend-specific ordering logic.
    ///
    /// # Arguments
    /// - `current`: `None` for a fresh pair (no prior checkpoints); `Some(c)` for the
    ///   `checkpoint_id` from the most recently loaded `CheckpointTuple` for this pair.
    /// - `channel`: accepted for API compatibility (BC-2.04.003 PC1); unused for ordering
    ///   (all channels within a super-step share a single `next_version` — BC-2.04.003 PC5).
    ///
    /// # Errors
    /// - `Err(E-CHKPT-002)` on `u64` overflow (unreachable in practice).
    fn get_next_version(
        &self,
        current: Option<CheckpointId>,
        channel: &ChannelName,
    ) -> Result<CheckpointId, FerrochainError> {
        MonotonicClock::get_next_version(current, channel)
    }
}
```

**BC anchor:** BC-2.04.001 through BC-2.04.007; `put` method: BC-2.04.002 PC4/EC-002, BC-2.04.001 EC-003, BC-2.04.006 PC2, BC-2.04.007 PC1+INV-1; `get_next_version` provided method: BC-2.04.003 PC1/PC5

> **Gate #31 type note — `CheckpointConfig`, `ChannelName`, `ChannelValue`, `TaskId`, `CheckpointTuple`, `Checkpoint`, `CheckpointMetadata`, `CheckpointId`:** `CheckpointConfig` is the checkpoint-addressing config; not formally enumerated as a spec-level struct — logically derived from BC-2.04.006 triple-address invariant (`thread_id: Uuid`, `checkpoint_ns: NamespaceId`, `checkpoint_id: Option<LogicalClockId>`); flagged corpus-unresolved for architect. `ChannelName` and `ChannelValue` are defined in entities-graph.md §GraphState (`Map<ChannelName, ChannelValue>`). `TaskId` is defined in VP-001.md (Kani harness: `TaskId(i as u64)` newtype around u64). `CheckpointTuple` is defined in entities-graph.md §CheckpointTuple. `Checkpoint` and `CheckpointMetadata` are defined in entities-graph.md §Checkpoint (`Checkpoint` has fields `checkpoint_id: LogicalClockId`, `thread_id`, `checkpoint_ns: NamespaceId`, `parent_checkpoint_id: Option<LogicalClockId>`, `state: GraphState`, `metadata: CheckpointMetadata`, `pending_sends: Vec<Send>`; `CheckpointMetadata` is the inline metadata sub-type on `Checkpoint`). `CheckpointId` is a newtype over `u64` per ADR-005 / BC-2.04.003 Architecture Anchors (monotonic logical clock; `get_next_version` produces instances).

### GuardrailHook

```rust
pub trait GuardrailHook: Send + Sync {
    /// Evaluate a single content unit arriving at a tool-result, RAG retrieval, or
    /// memory ingress boundary before it enters the model context (BC-2.11.001 PC5).
    ///
    /// # Return values
    /// - `GuardrailResult::Pass`                       → content forwarded unchanged
    ///   (BC-2.11.002 PC2)
    /// - `GuardrailResult::Fail { reason, severity }`  → content blocked; error block injected
    ///   at content's position; run continues unless `severity == Critical`
    ///   (BC-2.11.002 PC3, BC-2.11.005 PC4)
    /// - `GuardrailResult::Transform { new_content }`  → replacement forwarded; original
    ///   discarded (BC-2.11.002 PC4)
    ///
    /// # Panic safety
    /// A panic in this method is caught at the ingress boundary and treated as fail-closed:
    /// the pipeline propagates `Err(FerrochainError { category: INTERNAL, code: E-CORE-007 })`
    /// to the caller; content does not enter model context (BC-2.11.002 EC-001, E-CORE-007).
    async fn evaluate(
        &self,
        content: IngressContent,
        provenance_tag: ProvenanceTag,
    ) -> GuardrailResult;
}

pub enum GuardrailResult {
    /// Content passes through to model context unchanged.
    Pass,
    /// Content is blocked; an error block is injected at the content's position.
    /// `severity == Critical` transitions the run to `failed` and halts inference;
    /// lower severities (High, Medium, Low) allow the run to continue with the error
    /// block substituted (BC-2.11.002 PC3, BC-2.11.005 PC4).
    Fail {
        reason: String,
        severity: GuardrailSeverity,
    },
    /// Content is replaced; `new_content` enters model context; original is discarded.
    /// `new_content` MUST be the same `IngressContent` variant as the input content
    /// (same ingress boundary — e.g. a ToolResult evaluator must return ToolResult).
    /// The inner payload may change freely — for example, a different `ContentBlock`
    /// variant within `IngressContent::ToolResult` is permitted (BC-2.11.002 EC-003).
    /// Cross-boundary transforms (e.g. ToolResult → RagChunk) are not authorized
    /// by any contract and are semantically nonsensical at a fixed ingress boundary.
    Transform {
        new_content: IngressContent,
    },
}

/// Content unit passed to `GuardrailHook::evaluate`.
/// Each variant corresponds to one ingress boundary type.
///
/// The `<content_type>` placeholder in E-CORE-007's message format
/// (`GuardrailHook::evaluate panicked at <boundary> for content type '<content_type>'`)
/// is the variant name: `"ToolResult"`, `"RagChunk"`, or `"MemoryItem"`.
///
/// BC authorities: BC-2.11.002 PC1 (ToolResult boundary),
/// BC-2.11.003 PC1/PC5 (RAG boundary), BC-2.11.004 PC1/PC5 (memory boundary).
pub enum IngressContent {
    /// ContentBlock from a tool-result ingress boundary (BC-2.11.002 PC1).
    /// Inner type: `ContentBlock` per entities-graph.md §ContentBlock.
    ToolResult(ContentBlock),
    /// Document chunk from a RAG retrieval ingress boundary (BC-2.11.003 PC1, PC5).
    /// Payload type `Value` = `serde_json::Value`; internal structure is backend-specific.
    RagChunk(Value),
    /// Memory item from a memory ingress boundary (BC-2.11.004 PC1, PC5).
    /// Payload type `Value` = `serde_json::Value`; internal structure is store-specific.
    MemoryItem(Value),
}

/// Severity of a `GuardrailResult::Fail` outcome.
/// Determines whether the run continues (High/Medium/Low) or transitions to `failed` (Critical).
pub enum GuardrailSeverity {
    /// Run transitions to `failed`; inference halted; no further nodes execute.
    /// Authority: BC-2.11.002 INV-3, BC-2.11.003 PC3, BC-2.11.004 PC3, BC-2.11.005 PC4.
    Critical,
    /// Error block substituted at content position; run continues (BC-2.11.005 PC5).
    High,
    /// Error block substituted at content position; run continues (BC-2.11.005 PC5).
    Medium,
    /// Error block substituted at content position; run continues (BC-2.11.005 PC5).
    Low,
}
```

**BC anchor:** BC-2.11.001 (ProvenanceTag precondition for evaluate call),
BC-2.11.002 (tool-result boundary — primary trait-shape authority),
BC-2.11.003 (RAG retrieval boundary), BC-2.11.004 (memory ingress boundary),
BC-2.11.005 (fail-closed rejection guarantee — GuardrailResult::Fail closure contract),
BC-2.11.006 (no-hook default — GuardrailHook not registered)

### BudgetPolicy

```rust
pub trait BudgetPolicy: Send + Sync {
    /// Evaluate the current token/cost usage against this policy's configured thresholds.
    ///
    /// **Pure, synchronous, and side-effect-free.** This function returns a decision only;
    /// it must not write to any journal, mutate state, or perform I/O.
    /// All side effects (EvidenceJournal append, interrupt trigger, halt sequencing)
    /// are the responsibility of the caller (BudgetEngine / execution engine) after
    /// receiving the decision.
    ///
    /// Authority: BC-2.10.001 INV (purity invariant) + ADR-009.
    fn evaluate(&self, usage: TokenUsage, context: &RunContext) -> PolicyDecision;
}

/// Decision returned by `BudgetPolicy::evaluate`.
///
/// Authority: BC-2.10.001 PC3 (three-variant contract),
/// BC-2.10.001 TV-001 (Allow), TV-002 (Escalate with payload), TV-003 (Deny with payload).
pub enum PolicyDecision {
    Allow,
    Escalate { reason: String, current_usage: TokenUsage },
    Deny { reason: String, current_usage: TokenUsage },
}

/// Engine behavior when `PolicyDecision::Deny` (hard-ceiling exceeded) is received.
///
/// `on_ceiling` is consulted by the execution engine ONLY for `PolicyDecision::Deny`.
/// It does NOT affect handling of `PolicyDecision::Escalate`: a soft-ceiling Escalate
/// decision ALWAYS suspends the run via HITL interrupt — `on_ceiling` is not read for
/// that path (BC-2.10.001 PC3).
///
/// When `PolicyDecision::Deny` is received, the engine reads this field to choose
/// between halting immediately, re-escalating to HITL (same mechanism as the soft-limit
/// path), or issuing a final summarize LLM call. The `BudgetPolicy::evaluate` trait
/// stays pure and data-free; the engine owns all dispatch (ADR-009 Option 3).
///
/// Authority: BC-2.10.001 PC3 (Escalate decision → HITL unconditionally),
/// BC-2.10.003 v1.2 (Halt + Summarize variants for Deny),
/// BC-2.10.004 (Escalate variant for Deny; also covers the soft-limit Escalate path).
pub enum OnCeiling {
    /// Stop the run immediately when `PolicyDecision::Deny` (hard ceiling) is received;
    /// transition to `failed` with E-BUDGET-001 (BC-2.10.003 PC5).
    Halt,
    /// When `PolicyDecision::Deny` (hard ceiling) is received, suspend via HITL interrupt
    /// rather than halting; run parks in `interrupted` status, awaiting
    /// `BudgetResume::Extend { new_ceiling }` or `BudgetResume::Halt` (BC-2.10.004).
    /// This is the "escalate on ceiling hit" mode: both the soft-ceiling
    /// `PolicyDecision::Escalate` path (always HITL) and this hard-ceiling Deny→Escalate
    /// path use the same `BudgetEscalation` interrupt mechanism (BC-2.10.004).
    Escalate,
    /// Issue one final LLM call using `summarize_prompt` as a `HumanMessage`;
    /// return the model response as run output with `status = summary_halt`
    /// (BC-2.10.003 PC8). If the summarize call itself triggers `Deny`, the run falls
    /// back to `Halt` semantics — E-BUDGET-001, `status = failed` (BC-2.10.003 EC-005).
    Summarize { summarize_prompt: String },
}

/// Configuration for the built-in budget governance policy.
///
/// Carried via `GraphConfig::budget_config: Option<BudgetConfig>` (ADR-009 Option 3).
/// The engine constructs a `BudgetPolicy` implementation from these fields; policy
/// evaluation itself is pure (`BudgetPolicy::evaluate` has no side effects).
///
/// Authority: BC-2.10.001 TV-001/TV-002/TV-003 (`soft_limit` + `hard_limit` thresholds),
/// BC-2.10.003 + BC-2.10.004 (`on_ceiling` behavior), ADR-009 Option 3.
pub struct BudgetConfig {
    /// Token count at which `PolicyDecision::Escalate` is returned.
    /// `None` = no soft ceiling; the Escalate path is never triggered by token count alone.
    pub soft_limit: Option<u64>,
    /// Token count at which `PolicyDecision::Deny` is returned.
    /// `None` = no hard ceiling; the Deny path is never triggered by token count alone.
    pub hard_limit: Option<u64>,
    /// Engine behavior when the hard ceiling (`PolicyDecision::Deny`) is reached.
    pub on_ceiling: OnCeiling,
}
```

> **Engine dispatch decision table — complete `PolicyDecision` × `on_ceiling` → action
> mapping. Zero unspecified cells.**
> `BudgetPolicy::evaluate` is pure and data-free — `evaluate` has no knowledge of
> `on_ceiling`; the engine owns all dispatch (ADR-009 Option 3).
>
> | `PolicyDecision` | `BudgetConfig::on_ceiling` | Engine Action | Run Status | Resume Mechanism |
> |---|---|---|---|---|
> | `Allow` | (any — not consulted) | Continue execution; journal entry written (BC-2.10.002) | unchanged | — |
> | `Escalate` | **(any — not consulted)** | Trigger HITL interrupt with `BudgetEscalation` payload; `on_ceiling` is NOT read for this path (BC-2.10.004; authority: BC-2.10.001 PC3) | `interrupted` | `BudgetResume::Extend { new_ceiling }` or `BudgetResume::Halt` |
> | `Deny` | `Halt` | Graceful halt per BC-2.10.003: complete in-flight super-step tasks, call `put_writes`, error `E-BUDGET-001` | `failed` | Resumable via new `RunnableConfig` with higher `hard_limit` (not a HITL resume) |
> | `Deny` | `Escalate` | Trigger HITL interrupt with `BudgetEscalation` payload; same `interrupt()` mechanism as the `Escalate` row above (BC-2.10.004) | `interrupted` | `BudgetResume::Extend { new_ceiling }` or `BudgetResume::Halt` |
> | `Deny` | `Summarize { summarize_prompt }` | Issue one final LLM call per BC-2.10.003 PC8; fall back to `Halt` semantics (E-BUDGET-001, `status = failed`) if the summarize call itself triggers `Deny` (BC-2.10.003 EC-005) | `summary_halt` (or `failed` on recursive `Deny`) | — |
>
> Escalate-path authority: BC-2.10.001 PC3 — "execution suspends; the run transitions to
> `interrupted` via the HITL interrupt mechanism (BC-2.10.004)" — no `on_ceiling`
> qualification. Deny-path authority: BC-2.10.003 (Halt + Summarize), BC-2.10.004
> (Deny + `on_ceiling = Escalate` → HITL).

> **`RunContext`** — RESOLVED. Defined by BC-2.10.001 precondition 3: "The execution engine
> has access to the `RunContext` (thread_id, run_id, sub-agent identity if applicable) for
> policy evaluation calls." Fields: `thread_id`, `run_id`, `sub_agent_id: Option<SubAgentId>`,
> `budget_info: Option<BudgetInfo>` (v1.2 addition — BC-2.10.003 PC5/INV; populated by
> `graph::budget_engine` at each super-step boundary before task dispatch; `None` when no
> `BudgetPolicy` is active).
> Concrete struct definition lives in `ferrochain-core/src/budget.rs` per ADR-009 Option 3.
> (gate #31 RESOLVED via BC-2.10.001 precondition 3 — name-equality verified)

> **`BudgetInfo`** — RESOLVED (defined inline). Struct carried in `RunContext.budget_info:
> Option<BudgetInfo>` at each super-step boundary. Fields:
> `tokens_remaining: Option<i64>` — `ceiling - accumulated_tokens` (signed; may be negative
> when a Deny has just been triggered because `accumulated > ceiling`; `None` if no token
> ceiling is configured), `steps_remaining: Option<u32>` — `recursion_limit - current_step`
> (`None` if no step limit is configured).
> Authority: BC-2.10.003 v1.2 PC5 (remaining-budget exposure postcondition),
> BC-2.10.003 INV (signed arithmetic rationale for `Option<i64>`),
> BC-2.10.003 TV-007 (canonical test vector: ceiling=10000, accumulated=3000,
> recursion_limit=25, step=1 → tokens_remaining=Some(7000), steps_remaining=Some(24)).
> Module: `ferrochain-core/src/budget.rs` (alongside `RunContext`).
> (gate #31 RESOLVED — defined inline; added v2.21)

**BC anchor:** BC-2.10.001 precondition 3 (RunContext fields: thread_id, run_id, sub-agent identity),
BC-2.10.001 PC3 (PolicyDecision variants + purity invariant),
BC-2.10.001 TV-001–TV-003 (soft_limit/hard_limit thresholds + variant payloads),
BC-2.10.002 INV (journal writes are caller responsibility),
BC-2.10.003 v1.2 (OnCeiling Halt + Summarize variants; PC5/INV/TV-007 BudgetInfo shape and arithmetic),
BC-2.10.004 (OnCeiling Escalate variant — HITL interrupt path),
ADR-009 Option 3 (BudgetConfig placement in GraphConfig; pure/effectful boundary)

### ToolCallDialect

```rust
/// Pluggable, object-safe seam for serializing and deserializing tool calls.
/// Implementations: NativeOpenAiJson (default), NativeAnthropic, HermesChatMlXml.
///
/// Authority: BC-2.08.013 (Pluggable Tool-Call Dialect Seam).
/// Module: ferrochain-core (trait definition); ferrochain-<provider> (dispatch).
pub trait ToolCallDialect: Send + Sync {
    /// Serialize a single ToolCall to the dialect's wire format.
    fn serialize_tool_call(&self, call: &ToolCall) -> Result<String, FerrochainError>;
    /// Deserialize zero or more tool calls from model output content.
    fn deserialize_tool_calls(&self, content: &str) -> Result<Vec<ToolCall>, FerrochainError>;
    /// Machine-readable dialect identifier (e.g., "openai_json", "anthropic", "hermes_chatml_xml").
    fn dialect_name(&self) -> &str;
}
```

**BC anchor:** BC-2.08.013 PC1–PC9 (built-in dialect round-trips; PC8/PC9 = E-PROV-009 on parse failure) + PC10 (object-safe trait contract)

### ProviderFallbackPolicy

```rust
/// Ordered fallback chain for provider-level resilience.
/// Tries each provider in `chain` in order; falls over on 429, 5xx, or auth failure.
///
/// Authority: BC-2.08.014 (Provider Failover Chain).
/// Module: ferrochain-core (struct definition); ferrochain-<provider> (dispatch).
pub struct ProviderFallbackPolicy {
    /// Ordered list of provider credentials to try; first entry is primary.
    pub chain: Vec<ProviderCredential>,
    /// Optional configuration for automatic credential refresh on auth failure.
    pub credential_refresh: Option<CredentialRefreshConfig>,
}
```

> **`ProviderCredential`** — UNRESOLVED (implementer-scope). Provider-specific credential shape differs per provider (API key, OAuth token, custom header). Not formally enumerated in spec corpus; flagged for architect. (gate #31 UNRESOLVED)
>
> **`CredentialRefreshConfig`** — UNRESOLVED (implementer-scope). Configuration for automatic credential refresh callback on auth failure. Not formally enumerated in spec corpus; flagged for architect. (gate #31 UNRESOLVED)

**BC anchor:** BC-2.08.014 PC1–PC4 (ordered fallback semantics) + PC5 (E-PROV-010 on chain exhaustion)

### SkillStore

```rust
/// Pluggable skill document registry for load-on-demand skill retrieval.
///
/// Authority: BC-2.15.004 (SkillStore Registry — Load-on-Demand Skill Documents).
/// Module: ferrochain-memory (memory::skills).
pub trait SkillStore: Send + Sync {
    /// Load a skill document by its registered name.
    /// Returns `Ok(Some(content))` if found; `Ok(None)` if no skill with that name exists.
    /// The name→(namespace, key) storage mapping is impl-internal (BC-2.15.004 Invariant).
    async fn load_skill(&self, name: &str) -> Result<Option<String>, FerrochainError>;

    /// List all registered skill descriptors, optionally filtered by tags.
    /// Passing an empty slice returns ALL registered descriptors (BC-2.15.004 PC2).
    async fn list_skills(&self, tags: &[String]) -> Result<Vec<SkillDescriptor>, FerrochainError>;

    /// Check whether a skill with the given name is registered, without loading its document.
    /// A cheap existence check — does NOT load content (BC-2.15.004 PC3).
    async fn skill_exists(&self, name: &str) -> Result<bool, FerrochainError>;
}

/// Metadata descriptor for a registered skill document.
///
/// Authority: BC-2.15.004 (SkillStore Registry) — defined inline.
pub struct SkillDescriptor {
    pub name: String,
    pub namespace: String,
    pub key: String,
    pub tags: Vec<String>,
}
```

> **`SkillDescriptor`** — RESOLVED. Defined inline above; fields match BC-2.15.004 postconditions (name, namespace, key, tags). (gate #31 RESOLVED)

**BC anchor:** BC-2.15.004 PC1–PC4 (load-on-demand, list, exists; None on missing is Ok not Err)

### MemoryWriteGuard

```rust
/// Pure, synchronous guard that validates memory and skill write operations
/// before they are committed to the backing store.
/// Fail-closed: Deny and Transform decisions block writes; Allow proceeds.
///
/// Authority: BC-2.15.005 (Guarded Memory and Skill Writes).
/// Module: ferrochain-core (core::write_guard); ferrochain-memory (write_guard dispatch).
pub trait MemoryWriteGuard: Send + Sync {
    /// Validate a proposed write operation. Pure — no I/O, no state mutation.
    fn validate(&self, req: &MemoryWriteRequest) -> WriteGuardDecision;
}

/// Describes a proposed write to the memory or skill store.
///
/// Authority: BC-2.15.005 — defined inline.
pub enum MemoryWriteRequest {
    Add { namespace: String, key: String, value: Value },
    /// `old_value: None` — unconditional replace (replace regardless of current value).
    /// `old_value: Some(v)` — match-based replace (only if current value equals `v`).
    /// Authority: ADR-012 Decision 1 / Primitive C; BC-2.15.005 PC2.
    Replace { namespace: String, key: String, old_value: Option<Value>, new_value: Value },
    Remove { namespace: String, key: String },
}

/// Decision returned by `MemoryWriteGuard::validate`.
///
/// Authority: BC-2.15.005 — defined inline.
pub enum WriteGuardDecision {
    Allow,
    Deny { reason: String },
    Transform { sanitized: Value },
}
```

> **`MemoryWriteRequest`** — RESOLVED. Defined inline above; variants match BC-2.15.005 PC1 (Add/Replace/Remove). (gate #31 RESOLVED)
>
> **`WriteGuardDecision`** — RESOLVED. Defined inline above; variants match BC-2.15.005 PC2–PC4 (Allow/Deny/Transform). (gate #31 RESOLVED)
>
> **`Value`** — EXTERNAL. `serde_json::Value` — Rust standard JSON value type. (gate #31 EXTERNAL)

**BC anchor:** BC-2.15.005 PC1–PC5 (guard validation contract, E-MEMORY-007 on Deny, Transform semantics)

### MemoryStore

The foundational long-horizon key-value and vector memory store. Provides cross-thread,
cross-session durability independent of the checkpoint lifecycle (BC-2.15.001 Invariant).
**Six-method surface:** `memory_set`, `memory_get`, `memory_delete`, `memory_search`,
`vector_search`, `hybrid_search` (BC-2.15.001 PC1–PC7). Scope isolation is enforced at
the storage layer, not the application layer (BC-2.15.002 PC6).

```rust
/// Long-horizon KV and vector memory store, decoupled from the checkpoint lifecycle.
/// Entries persist across threads and process restarts (SQLite backend — BC-2.15.001 PC2).
/// An ephemeral in-memory backend is also provided for tests (BC-2.15.001 Invariant).
///
/// Authority: BC-2.15.001 (6-method surface + cross-thread durability),
///            BC-2.15.002 (MemoryScope tier isolation; scope parameter on every method),
///            BC-2.15.003 (GDPR erasure — admin-only standalone fn; NOT a trait method).
/// Module: ferrochain-memory (memory::store).
pub trait MemoryStore: Send + Sync {
    /// Write a key-value entry to the store under `scope` and `key`.
    ///
    /// The entry is readable from any thread via `memory_get` with the same scope
    /// (BC-2.15.001 PC1–PC2). Concurrent writes to the same `(scope, key)` use
    /// last-writer-wins (LWW) semantics (BC-2.15.001 Invariant).
    /// Raises E-MEMORY-002 StorageFull if the backing store reaches capacity
    /// (BC-2.15.001 EC-004).
    /// Raises E-MEMORY-003 ScopeAccessDenied when identity enforcement is active
    /// (opt-in at the server layer — BC-2.15.002 Invariant) and the caller-supplied
    /// scope mismatches the verified caller identity:
    /// `Err(E-MEMORY-003 ScopeAccessDenied { requested_scope, caller_identity })`
    /// (BC-2.15.002 Invariant).
    async fn memory_set(
        &self,
        scope: MemoryScope,
        key: &str,
        value: Value,
    ) -> Result<(), FerrochainError>;

    /// Read a single entry by `(scope, key)`.
    ///
    /// Returns `Ok(None)` if the key was never written, was explicitly deleted via
    /// `memory_delete` (BC-2.15.001 PC3), or was written under a different owner's
    /// scope (isolation-by-invisibility: cross-owner reads return `Ok(None)`, not an
    /// error — BC-2.15.002 PC1/TV-001). Scope isolation enforced at the storage layer
    /// (`WHERE scope_key = ?` predicate — BC-2.15.002 PC6): entries from other scopes
    /// are silently invisible, never returned.
    /// Raises E-MEMORY-004 NoScopeContext when no session context is derivable from the
    /// call context and the caller omitted an explicit scope (BC-2.15.002 EC-001).
    async fn memory_get(
        &self,
        scope: MemoryScope,
        key: &str,
    ) -> Result<Option<Value>, FerrochainError>;

    /// Delete an entry by `(scope, key)`.
    ///
    /// After deletion, `memory_get` for the same `(scope, key)` returns `Ok(None)`
    /// (BC-2.15.001 PC3). Idempotent: deleting a non-existent key returns `Ok(())`.
    async fn memory_delete(
        &self,
        scope: MemoryScope,
        key: &str,
    ) -> Result<(), FerrochainError>;

    /// Full-text keyword search over entries in `scope`.
    ///
    /// Returns all entries whose stored value contains `query` as a case-insensitive
    /// substring (BC-2.15.001 PC4). Results are ordered by recency (most recently
    /// written first) by default. Search is strictly scoped: app-scoped entries are
    /// not returned by a user-scope search (BC-2.15.002 EC-003).
    async fn memory_search(
        &self,
        scope: MemoryScope,
        query: &str,
    ) -> Result<Vec<MemoryEntry>, FerrochainError>;

    /// Vector similarity search over entries in `scope` that have stored embeddings.
    ///
    /// Returns the top-`top_k` entries ranked by cosine similarity between the stored
    /// embedding and `query_embedding` (BC-2.15.001 PC5). Entries without a stored
    /// embedding are excluded from results (BC-2.15.001 PC6).
    /// Raises E-MEMORY-001 EmbeddingBackendNotConfigured if no embedding backend is
    /// configured (BC-2.15.001 EC-001).
    async fn vector_search(
        &self,
        scope: MemoryScope,
        query_embedding: Vec<f32>,
        top_k: usize,
    ) -> Result<Vec<MemoryEntry>, FerrochainError>;

    /// Hybrid search: union of keyword and vector similarity results.
    ///
    /// De-duplicates by key (higher-ranked copy retained); returns up to `top_k`
    /// results (BC-2.15.001 PC7). Degrades gracefully to keyword-only when no
    /// embedding backend is configured: the vector component is silently skipped
    /// with a DEBUG log; no error is raised (BC-2.15.001 EC-005).
    async fn hybrid_search(
        &self,
        scope: MemoryScope,
        query: &str,
        top_k: usize,
    ) -> Result<Vec<MemoryEntry>, FerrochainError>;
}

/// Memory scope tier for isolation enforcement (BC-2.15.002).
///
/// Scope flows from the trait method parameter directly to the SQL `WHERE scope_key = ?`
/// predicate — never collapsed or merged (NE-12 tenancy partition analog;
/// BC-2.15.002 Invariant / PC6).
pub enum MemoryScope {
    /// Private to the named user across all of that user's sessions (BC-2.15.002 PC1).
    User(String),
    /// Shared across all callers within the same application deployment
    /// (BC-2.15.002 PC3/PC5).
    App(String),
    /// Private to the named session; eligible for cleanup via `memory_delete_session`
    /// (BC-2.15.002 PC2 / Invariant — standalone store fn, not a trait method).
    Session(String),
}

/// An entry returned by search operations (`memory_search`, `vector_search`,
/// `hybrid_search`).
///
/// Authority: BC-2.15.001 PC4–PC7 (search return payload),
///            BC-2.15.003 §Invariants (author_id required for GDPR erasure of
///            app-scoped entries attributed to a specific user).
pub struct MemoryEntry {
    /// The scope under which this entry was written (BC-2.15.002 tier model).
    pub scope: MemoryScope,
    /// The storage key.
    pub key: String,
    /// The stored value (`serde_json::Value`).
    pub value: Value,
    /// Author identity, required for GDPR erasure of app-scoped entries
    /// (BC-2.15.003 §Invariants: author_id tracking). `None` for entries
    /// lacking attribution or for non-app-scoped entries.
    pub author_id: Option<String>,
}
```

> **`MemoryScope`** — RESOLVED. Defined inline above; variants match BC-2.15.002 scope definitions: `User(user_id)`, `App(app_id)`, `Session(session_id)` (BC-2.15.002 Preconditions). (gate #31 RESOLVED)
>
> **`MemoryEntry`** — RESOLVED. Defined inline above; fields satisfy BC-2.15.001 PC4–PC7 search return requirements and BC-2.15.003 `author_id` tracking obligation. (gate #31 RESOLVED)
>
> **`query_embedding: Vec<f32>`** — RESOLVED. Standard float-32 embedding vector; dimensionality determined by the configured embedding backend. (gate #31 RESOLVED)

**BC anchor:** BC-2.15.001 PC1–PC7 (6-method surface — every method traces to a BC PC: `memory_set`=PC1, `memory_get`=PC3, `memory_delete`=PC3, `memory_search`=PC4, `vector_search`=PC5–PC6, `hybrid_search`=PC7) + BC-2.15.002 PC1–PC6 + INV (MemoryScope tier isolation; storage-layer enforcement; opt-in identity enforcement) + E-MEMORY-001 (`vector_search`; BC-2.15.001 EC-001) + E-MEMORY-002 (`memory_set`; BC-2.15.001 EC-004) + E-MEMORY-003 (`memory_set`; BC-2.15.002 Invariant) + E-MEMORY-004 (`memory_get`; BC-2.15.002 EC-001)

### StreamEvent

The complete streaming event taxonomy emitted by `ferrochain-graph` during a run and
serialized to SSE by `ferrochain-server`. **15 variants** (11 execution lifecycle + 1
guardrail observability + 2 per-tool-call approval [D23/ADR-018] + 1 compaction
[D23/ADR-019]). All variants carry `run_id` and `parent_ids` (BC-2.06.002).

```rust
/// Streaming events emitted during graph execution.
/// All variants carry `run_id` (stable per-run UUID) and `parent_ids` (ancestry chain)
/// for event correlation (BC-2.06.002).
///
/// Wire format: JSON with `#[serde(tag = "event", rename_all = "snake_case")]`.
/// Example: `{"event": "guardrail_decision", "run_id": "...", ...}`.
///
/// Authority: BC-2.06.001 (variant enumeration + causal ordering), ADR-006 rev-3.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "event", rename_all = "snake_case")]
pub enum StreamEvent {
    // Run lifecycle — wire: run_start | run_stream | run_end
    RunStart   { run_id: RunId, parent_ids: Vec<RunId>, data: RunStartData },
    RunStream  { run_id: RunId, parent_ids: Vec<RunId>, data: ChunkData },
    RunEnd     { run_id: RunId, parent_ids: Vec<RunId>, data: RunEndData },
    // Super-step lifecycle — wire: step_start | step_end
    StepStart  { run_id: RunId, parent_ids: Vec<RunId>, step: u32 },
    StepEnd    { run_id: RunId, parent_ids: Vec<RunId>, step: u32 },
    // Node lifecycle — wire: node_start | node_stream | node_end
    NodeStart  { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: NodeData },
    NodeStream { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: ChunkData },
    NodeEnd    { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: NodeData },
    // Tool lifecycle — wire: tool_start | tool_stream | tool_end
    // ToolEnd content semantics: `data` carries POST-guardrail content —
    // the content the model context receives, not the raw tool output.
    // Raw rejected payloads are absent from ToolEnd and all StreamEvents
    // (BC-2.11.005 INV-5 — zero bytes of rejected content in any stream payload).
    ToolStart  { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
    ToolStream { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ChunkData },
    ToolEnd    { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
    // Guardrail observability — wire: guardrail_decision  (F-P99-01, 2026-07-17)
    // Emitted ONLY for Fail and Transform outcomes; Pass is never streamed.
    // Stream-observer notification only: NOT emitted in unary mode.
    // Underlying GuardrailHook::evaluate fires on both streaming and unary paths
    // per DI-012 — absence from unary output is not a DI-011 violation (BC-2.06.003).
    GuardrailDecision {
        run_id:       RunId,
        parent_ids:   Vec<RunId>,
        /// The ingress boundary at which this decision was made.
        boundary:     IngressBoundary,
        /// Fail or Transform. Pass decisions are not streamed.
        decision:     GuardrailDecisionKind,
        /// Rejection reason — Some for Fail; None for Transform.
        reason:       Option<String>,
        /// Rejection severity — Some for Fail; None for Transform.
        severity:     Option<GuardrailSeverityWire>,
        /// Correlates to the audit log entry (BC-2.11.005 PC3 `ingress_id`).
        ingress_id:   Uuid,
        /// Correlates to the enclosing ToolStart/ToolEnd; None for RagChunk/MemoryItem.
        tool_call_id: Option<String>,
    },
    // Per-tool-call approval request — wire: tool_approval_request  (D23/2026-07-22, ADR-018)
    // Emitted BEFORE interrupt() when pre_tool_dispatch hook returns PendingHumanApproval.
    // Fires inside the NodeStart/NodeEnd window, BEFORE any ToolStart for this tool call.
    // The run transitions to `interrupted` immediately after this event.
    // Causal ordering authority: BC-2.06.004.
    ToolApprovalRequest {
        run_id:      RunId,
        parent_ids:  Vec<RunId>,
        tool_name:   String,
        /// Serialized tool arguments as JSON.
        tool_args:   serde_json::Value,
        /// Risk tier declared via `action_risk` attribute on the tool; None if omitted.
        action_risk: Option<ActionRisk>,
        /// Human-readable approval request prompt for the approver.
        prompt:      String,
    },
    // Per-tool-call approval resolved — wire: tool_approval_resolved  (D23/2026-07-22, ADR-018)
    // Emitted AFTER interrupt is consumed by Command(resume=PreToolDecision),
    // BEFORE the approval decision is applied. Fires on run resume; correlates to
    // the preceding ToolApprovalRequest by tool_name.
    // Causal ordering authority: BC-2.06.005.
    ToolApprovalResolved {
        run_id:        RunId,
        parent_ids:    Vec<RunId>,
        tool_name:     String,
        /// The resolution: Approve | Edit(modified_args) | Deny.
        decision:      PreToolDecision,
        /// Optional rationale from the human approver.
        reason:        Option<String>,
        /// Modified tool arguments when decision is Edit; None for Approve/Deny.
        modified_args: Option<serde_json::Value>,
    },
    // Rolling compaction lifecycle event — wire: compaction_event  (D23/2026-07-22, ADR-019)
    // Emitted at step 6 of the 7-step compaction cycle (BC-2.10.006), AFTER the
    // compacted checkpoint is durably written. Fires between super-steps: after StepEnd
    // and before the next StepStart.
    // Causal ordering authority: BC-2.06.006.
    CompactionEvent {
        run_id:                 RunId,
        parent_ids:             Vec<RunId>,
        /// Which trigger condition fired (OnWatermark / OnMessageCount / OnTokenCount).
        trigger:                CompactionTrigger,
        /// First turn index replaced by the summary (inclusive start of compacted range).
        compacted_start:        usize,
        /// Last turn index replaced by the summary (inclusive end of compacted range).
        compacted_end:          usize,
        /// Token count of the generated summary text.
        summary_token_count:    u64,
        /// Tokens remaining in the budget window after compaction.
        /// Source: RunContext.budget_info.tokens_remaining: Option<i64>.
        /// None when no token ceiling is configured; negative i64 when accumulated > ceiling.
        tokens_remaining_after: Option<i64>,
    },
}

/// Causal ordering (BC-2.06.001 PC4 — updated D23/2026-07-22):
///
/// RunStart
///   → (StepStart
///       → (NodeStart
///           → GuardrailDecision[RagChunk|MemoryItem]*    // RAG/Memory: within Node window
///           → (ToolApprovalRequest                        // On PendingHumanApproval (0 or 1 per tool call)
///               → [run transitions to interrupted]
///               → [external Command(resume=PreToolDecision)]
///               → ToolApprovalResolved                    // On resume; BEFORE decision applied
///             )?
///           → (ToolStart                                  // Only if Approve or Edit decision
///               → GuardrailDecision[ToolResult]*          // ToolResult: before ToolEnd
///               → ToolEnd                                 // Always last in its window
///             )*
///           → NodeEnd
///         )*
///       → StepEnd
///       → CompactionEvent?                               // After StepEnd, before next StepStart (0 or 1)
///     )*
/// → RunEnd
///
/// GuardrailDecision* = 0..N — one per non-Pass ContentBlock/chunk/item.
/// A tool invocation producing N ContentBlocks with K failures emits K GuardrailDecision
/// events before one ToolEnd.
/// ToolApprovalRequest/Resolved: 0 or 1 per tool call attempt (only on PendingHumanApproval path).
/// CompactionEvent: 0 or 1 per super-step boundary (fires when compaction trigger threshold met).

/// The ingress boundary at which a GuardrailDecision was produced.
/// Maps to IngressContent variants in GuardrailHook (§GuardrailHook above).
/// BC authority: BC-2.11.001–BC-2.11.004 (three boundary types).
pub enum IngressBoundary { ToolResult, RagChunk, MemoryItem }

/// The non-trivial outcome streamed to observers. Pass is never streamed.
/// BC authority: BC-2.11.002 PC3 (Fail), BC-2.11.002 PC4 (Transform).
pub enum GuardrailDecisionKind { Fail, Transform }

/// Wire-serializable severity mirroring GuardrailSeverity for stream consumers.
/// BC authority: BC-2.11.002 INV-3, BC-2.11.005 PC4/PC5.
pub enum GuardrailSeverityWire { Critical, High, Medium, Low }
```

**BC anchor:**
BC-2.06.001 PC2 (variant enumeration + ToolEnd output semantics — updated D23 15 variants),
BC-2.06.001 PC4 (causal ordering — updated D23/2026-07-22),
BC-2.06.002 (run_id + parent_ids on every variant),
BC-2.06.003 (streaming/unary execution equivalence; GuardrailDecision stream-only notification),
BC-2.06.004 (ToolApprovalRequest — event 13; emitted before interrupt on PendingHumanApproval),
BC-2.06.005 (ToolApprovalResolved — event 14; emitted on Command(resume=…) delivery),
BC-2.06.006 (CompactionEvent — event 15; emitted after compacted checkpoint durably written),
BC-2.11.002 PC3/PC4 (GuardrailDecision emitted on Fail/Transform for ToolResult boundary), BC-2.11.003 PC3/PC4 (GuardrailDecision emitted on Fail/Transform for RagChunk boundary), BC-2.11.004 PC3/PC4 (GuardrailDecision emitted on Fail/Transform for MemoryItem boundary),
BC-2.11.005 PC1/INV (ToolEnd post-guardrail content; zero rejected bytes in any StreamEvent),
ADR-006 rev-3 (guardrail design authority), ADR-018 (per-tool-call approval hook design authority), ADR-019 (rolling compaction design authority).

### PreToolCallHook

**Source:** ADR-018 Decision 2 (trait shape) + Decision 3 (dispatch ordering) + Decision 4 (fail-closed Deny) + Decision 5 (streaming events) + Decision 6 (action_risk attribute); ferrochain-graph: graph::hitl.

BC anchor: BC-2.05.007 (PreToolCallHook trait — pre_invoke contract; ToolCallPreview shape; PreToolDecision variants Approve/Deny/Edit/PendingHumanApproval; AlwaysApprovePolicy default; fail-closed Deny; hook failure = Deny; VP-011 Kani P0 seed), BC-2.05.004 (Command(resume=PreToolDecision) resume-API: delivers PreToolDecision to engine when PendingHumanApproval interrupt is resolved), BC-2.06.004 (ToolApprovalRequest event), BC-2.06.005 (ToolApprovalResolved event), BC-2.08.010 PC1 (action_risk() method on Tool), BC-2.16.001 Invariant (retry-approval dispatch ordering).

```rust
// ferrochain-graph: graph::hitl

/// Risk tier declared by a tool via the `action_risk` attribute.
/// BashTool enforces a floor of `Medium`; `ReadOnly` and `Low` are
/// rejected at BashTool construction time (E-TOOLS-007).
/// BC anchor: BC-2.23.005 PC3 (BashTool risk floor), BC-2.08.010 PC1 (action_risk() method).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[non_exhaustive]
pub enum ActionRisk { ReadOnly, Low, Medium, High }

/// The tool call preview presented to the hook before invocation.
/// BC anchor: BC-2.05.007 PC3 (ToolCallPreview constructed read-only before pre_invoke call; action_risk populated from #[tool(action_risk = ...)] annotation).
#[derive(Debug, Clone)]
pub struct ToolCallPreview {
    pub tool_name:   String,
    pub tool_args:   serde_json::Value,
    /// Risk tier from the tool's `action_risk` attribute; None if omitted.
    pub action_risk: Option<ActionRisk>,
}

/// Decision returned by the PreToolCallHook.
/// BC anchor: BC-2.05.007 PC1-PC5 (four PreToolDecision branches; fail-closed Deny; hook error = Deny).
#[derive(Debug, Clone)]
#[non_exhaustive]
pub enum PreToolDecision {
    /// Proceed with original args. (BC-2.05.007 PC1)
    Approve,
    /// Abort the tool call; return ToolOutput::Error(reason) without invoking the tool.
    /// Fail-closed: the tool is NEVER invoked on Deny under any code path (VP-011 Kani P0).
    /// BC anchor: BC-2.05.007 PC2 (Deny path — fail-closed; reason surfaced in ToolOutput::Error).
    Deny { reason: String },
    /// Proceed with modified args (override tool_args with modified_args value).
    /// Engine validates modified_args is a JSON object; falls back to Deny if not.
    /// BC anchor: BC-2.05.007 PC3 (Edit path; invalid modified_args → Deny fallback).
    Edit { modified_args: serde_json::Value },
    /// Suspend the run (interrupt()) and await human approval via Command(resume=PreToolDecision).
    /// ToolApprovalRequest StreamEvent is emitted before interrupt().
    /// BC anchor: BC-2.05.007 PC4 (PendingHumanApproval — reuses BC-2.05.001 interrupt machinery).
    PendingHumanApproval { prompt: Option<String> },
}

/// Per-tool-call approval hook invoked before each tool.invoke().
/// If not configured (GraphConfig.pre_tool_hook = None), AlwaysApprovePolicy semantics apply.
/// Fail-closed: if the hook panics or returns an error, the engine treats the result as
/// Deny { reason: "hook error: <detail>" } — tool is NOT invoked (BC-2.05.007 PC5).
/// BC anchor: BC-2.05.007 PC1-PC6 (full dispatch contract: Approve/Deny/Edit/PendingHumanApproval/
/// hook-error/no-hook paths; fail-closed invariant; VP-011 Kani P0 seed).
#[async_trait]
pub trait PreToolCallHook: Send + Sync {
    /// Called after circuit_breaker.check() passes and before tool.invoke().
    /// Dispatch ordering: circuit_breaker.check → pre_invoke (this method) → tool.invoke → retry.record()
    /// (ADR-018 Decision 6; BC-2.16.001 Invariant "Retry-Approval Ordering").
    /// Note: `pre_tool_dispatch` is the free function in graph::hitl that calls this method —
    /// do not confuse the dispatcher function with the trait method name.
    async fn pre_invoke(
        &self,
        preview: &ToolCallPreview,
        run_ctx: &RunContext,
    ) -> PreToolDecision;
}
```

### Compaction

**Source:** ADR-019 Decision 1 (CompactionTrigger enum) + Decision 2 (CompactionPolicy trait) + Decision 3 (7-step execution sequence) + Decision 4 (streaming event) + Decision 5 (mid-run vs next-run distinction); ferrochain-core: core::budget (type definitions — Decision 1); ferrochain-graph: graph::budget (BudgetEngine execution — Decision 3).

BC anchor: BC-2.10.005 (CompactionTrigger evaluation — VP-012 Kani candidate for OnWatermark arithmetic), BC-2.10.006 (compaction execution — 7-step cycle, ConversationSnapshot assembly, mid-run REPLACEMENT, EvidenceJournal, streaming event, checkpoint immutability), BC-2.06.006 (CompactionEvent StreamEvent), BC-2.15.006 (frozen-snapshot — NEXT-run context mutation, explicitly distinct from BC-2.10.006 CURRENT-run mid-run mutation).

```rust
// ferrochain-core: core::budget
// NOTE: CompactionTrigger, ConversationSnapshot, CompactionSummary, CompactionPolicy are
// definitions-only types in ferrochain-core::core::budget (ADR-019 Decision 1 / ADR-009 Option 3).
// The execution engine (BudgetEngine, EvidenceJournal dispatch) lives in ferrochain-graph::graph::budget.
// If BudgetConfig gains fields of these types (it does — Decision 2), core→graph dep is avoided because
// the type definitions live in core::budget, not in graph::budget.

/// Configures when the BudgetEngine triggers a compaction cycle.
/// BC anchor: BC-2.10.005 PC1-PC3 (trigger evaluation), BC-2.10.006 PC1 (precondition).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[non_exhaustive]
pub enum CompactionTrigger {
    /// Compaction is disabled (default).
    Disabled,
    /// Compact when tokens_used / hard_limit >= fraction.
    /// VP-012 Kani seed: arithmetic correctness of the fraction comparison.
    /// BC anchor: BC-2.10.005 PC2 (OnWatermark evaluation rule).
    OnWatermark { fraction: f64 },
    /// Compact when the message count in the active window exceeds the threshold.
    /// BC anchor: BC-2.10.005 PC3.
    OnMessageCount { threshold: usize },
    /// Compact when the estimated token count in the active window exceeds the threshold.
    /// BC anchor: BC-2.10.005 PC3.
    OnTokenCount { threshold: u64 },
}

/// Snapshot of recent conversation turns assembled from checkpoint FTS (BC-2.04.008).
/// BC anchor: BC-2.10.006 Step 1 (snapshot assembly from search_history).
#[derive(Debug, Clone)]
pub struct ConversationSnapshot {
    pub turns:           Vec<(usize, Message)>,
    pub token_estimate:  u64,
}

/// Summary produced by a CompactionPolicy.
/// BC anchor: BC-2.10.006 Step 2 (compact() return value).
#[derive(Debug, Clone)]
pub struct CompactionSummary {
    pub summary_text:    String,
    /// Inclusive range of turn indices to replace with the summary.
    pub compacted_start: usize,
    pub compacted_end:   usize,
}

/// Pluggable compaction strategy.
/// Default: DefaultSummarizationPolicy (calls the configured LLM).
/// BC anchor: BC-2.10.006 Step 2 (compact() contract — abort-on-Err, non-fatal).
#[async_trait]
pub trait CompactionPolicy: Send + Sync {
    /// Summarize the given snapshot. Return Err to abort the compaction cycle (non-fatal;
    /// run continues with pre-compaction window — BC-2.10.006 EC-001).
    async fn compact(
        &self,
        snapshot: &ConversationSnapshot,
        run_ctx:  &RunContext,
    ) -> Result<CompactionSummary, FerrochainError>;
}
```

### First-Party Tools

**Source:** ADR-020 (ferrochain-tools crate); ferrochain-tools crate. All file-access tools (ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, GrepTool) use `PathGuard` for workspace confinement (E-TOOLS-001 on escape); BashTool is confined via the ferrochain-sandbox backend (BC-2.23.005). All tools implement the `Tool` trait via `#[ferrochain::tool]` proc-macro.

BC anchor: BC-2.23.001 (ReadFileTool), BC-2.23.002 (WriteFileTool), BC-2.23.003 (EditFileTool), BC-2.23.004 (ListDirTool), BC-2.23.005 (BashTool — ActionRisk::Medium floor, EC-005 timeout, EC-006 output truncation), BC-2.23.006 (GrepTool — match cap, E-TOOLS-006 capped flag).

```rust
// ferrochain-tools crate

/// Workspace confinement guard.
/// Resolves the path via `canonicalize` and verifies it falls under `root`.
/// Shared by ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, GrepTool.
/// BC anchor: BC-2.23.001–006 shared PathGuard invariant; E-TOOLS-001 on escape.
pub struct PathGuard { root: PathBuf }
impl PathGuard {
    pub fn new(root: impl Into<PathBuf>) -> Result<Self, FerrochainError>;
    /// Returns Err(E-TOOLS-001) if resolved path escapes root.
    pub fn check(&self, path: &Path) -> Result<PathBuf, FerrochainError>;
}

// ReadFileTool — BC-2.23.001
// Errors: E-TOOLS-001 (path confinement), E-TOOLS-002 (file exceeds max_bytes limit).
// #[ferrochain::tool(name = "read_file", description = "...")]

// WriteFileTool — BC-2.23.002
// Errors: E-TOOLS-001 (path confinement). Creates parent dirs; overwrites atomically.
// #[ferrochain::tool(name = "write_file", description = "...")]

// EditFileTool — BC-2.23.003
// Errors: E-TOOLS-001 (path confinement), E-TOOLS-003 (old_string not found).
// Performs exact-string replacement; requires unique match (fails on 0 or >1 matches).
// #[ferrochain::tool(name = "edit_file", description = "...")]

// ListDirTool — BC-2.23.004
// Errors: E-TOOLS-001 (path confinement), E-TOOLS-008 (not a directory, permission denied). Returns directory entries (depth 1) as JSON array of DirEntry objects.
// #[ferrochain::tool(name = "list_dir", description = "...")]

/// BashTool — BC-2.23.005.
/// action_risk floor: ActionRisk::Medium — construction fails with E-TOOLS-007
/// if action_risk < Medium is requested.
/// Timeout: configurable max_duration (default 30s); E-TOOLS-004 on exceed.
/// Output cap: stdout+stderr combined truncated to max_output_bytes; BashOutput.truncated = true (E-TOOLS-005 payload field).
// #[ferrochain::tool(name = "bash", description = "...", action_risk = ActionRisk::Medium)]

/// GrepTool — BC-2.23.006.
/// Match cap: max_matches (default 100); GrepResult.capped = true when exceeded (E-TOOLS-006 payload field).
/// Errors: E-TOOLS-001 (path confinement).
// #[ferrochain::tool(name = "grep", description = "...")]
```

### Retriever Trait and GuardedDocuments

**Source:** ADR-014 Decision 2 (trait shape) + Decision 6 (GuardedDocuments); ferrochain-core: core::retriever, core::documents. (Note: core::guardrail provides types referenced by rag_ingress — GuardrailHook, IngressContent, ProvenanceTag — but GuardedDocuments itself is defined in core::retriever per ADR-014 Decision 6.)

```rust
// ferrochain-core: core::retriever
#[async_trait]
pub trait Retriever: Send + Sync {
    /// Returns documents relevant to `query`, ranked by relevance (implementation-defined).
    /// BC anchor: BC-2.20.001 PC2 (success/failure semantics, Result, DI-008 no .unwrap()),
    /// BC-2.20.001 PC4 (#[non_exhaustive] Document shape)
    async fn get_relevant_documents(
        &self,
        query: &str,
    ) -> Result<Vec<Document>, FerrochainError>;
}

// ferrochain-core: core::documents
/// Pure data carrier for all retrieval output. No methods, no I/O.
/// BC anchor: BC-2.20.001 PC3 (field semantics: page_content non-empty for content docs,
/// metadata MAY be empty, id: Option<String>), BC-2.20.001 INV-3 (no methods/I/O/async)
#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
#[non_exhaustive]
pub struct Document {
    /// The retrieved text content. Non-empty for content-bearing documents.
    pub page_content: String,
    /// Arbitrary key/value metadata. May be empty `{}`.
    pub metadata: serde_json::Map<String, serde_json::Value>,
    /// Optional stable ID assigned by the backend. None when backend assigns no stable IDs.
    pub id: Option<String>,
}

// ferrochain-core: core::retriever
// (GuardedDocuments is in core::retriever — it references types from core::guardrail such as
// GuardrailHook, IngressContent, and ProvenanceTag, but the struct and rag_ingress constructor
// are defined in core::retriever per ADR-014 Decision 6.)
/// Newtype wrapper produced by `rag_ingress`; the sole type accepted by graph nodes that
/// consume retrieved documents. Passing `Vec<Document>` directly to a node that expects
/// `&GuardedDocuments` is a compile-time type error (VP-2.20.002-A compile_fail gate).
/// BC anchor: BC-2.20.002 VP-2.20.002-A (compile_fail gate — Vec<Document> not accepted),
/// BC-2.20.002 PC1 (no page_content use before guardrail clearance)
pub struct GuardedDocuments(Vec<Document>);

impl GuardedDocuments {
    /// Evaluate each document through the guardrail hook before returning.
    /// Async, per-document evaluation. Fail behavior is severity-bifurcated (ADR-014 Decision 6 §GuardedDocuments):
    /// - `GuardrailSeverity::Critical` Fail → returns `Err(E-CORE-008 GuardrailCriticalRejection)`;
    ///   entire batch is aborted; no `GuardedDocuments` produced (DI-014 fail-closed).
    /// - Non-Critical Fail (High/Medium/Low) → error-entry Document substituted at the rejected
    ///   position (`page_content: "[GUARDRAIL BLOCKED: <reason>]"`, `metadata.ferrochain.guardrail_blocked: true`);
    ///   batch continues; `GuardedDocuments` produced with the substitution.
    /// BC anchor: BC-2.20.002 PC2 (severity-bifurcated Fail; Critical → Err(E-CORE-008); non-critical → substitution),
    /// BC-2.20.002 PC3 (guardrail fires BEFORE any doc content is used),
    /// BC-2.20.002 PC4 (documents failing guardrail never enter prompt under any condition)
    pub async fn rag_ingress(
        docs: Vec<Document>,
        guardrail: &dyn GuardrailHook,
    ) -> Result<GuardedDocuments, FerrochainError> { ... }

    /// Access the guardrail-cleared documents.
    pub fn documents(&self) -> &[Document] { &self.0 }
}
```

**BC anchor:**
BC-2.20.001 (Retriever trait — async dyn-compat, Document carrier, Arc\<dyn Retriever\> graph seam),
BC-2.20.002 (DI-012 RAGRetrieval guardrail coverage — GuardedDocuments typed wrapper enforces guardrail boundary at compile time; Red Gate test),
BC-2.20.003 (VectorStoreRetriever — SearchType/k/fetch_k/lambda_mult; as_retriever() → Retriever).
ADR-014 Decision 1 (crate placement: Retriever + Document in ferrochain-core), Decision 2 (trait shape, Document struct), Decision 6 (GuardedDocuments typed wrapper, rag_ingress async per-document evaluation).

---

### VectorStore Trait and VectorStoreFactory

**Source:** ADR-014 Decision 2; ferrochain-vectorstores: vectorstores::store.

```rust
// ferrochain-vectorstores: vectorstores::store
#[async_trait]
pub trait VectorStore: Send + Sync {
    /// Add texts (with optional per-text metadata) to the store. Returns assigned IDs.
    /// BC anchor: BC-2.21.001 PC1 (add_texts semantics), BC-2.21.002 PC2 (InMemoryVectorStore
    /// acquires write lock, embeds via Arc<dyn Embeddings>, stores Vec<f32>)
    async fn add_texts(
        &self,
        texts: Vec<String>,
        metadatas: Option<Vec<serde_json::Map<String, serde_json::Value>>>,
    ) -> Result<Vec<String>, FerrochainError>;

    /// Return the top-k documents most similar to `query`.
    /// BC anchor: BC-2.21.001 PC2, BC-2.21.002 PC3/PC4 (cosine similarity, RwLock read lock)
    async fn similarity_search(
        &self,
        query: &str,
        k: usize,
    ) -> Result<Vec<Document>, FerrochainError>;

    /// Return the top-k documents with their cosine similarity scores.
    /// BC anchor: BC-2.21.001 PC3
    async fn similarity_search_with_score(
        &self,
        query: &str,
        k: usize,
    ) -> Result<Vec<(Document, f32)>, FerrochainError>;

    /// Maximal Marginal Relevance search balancing relevance and diversity.
    /// BC anchor: BC-2.21.001 PC4, BC-2.20.003 PC3/INV-3 (SearchType::Mmr dispatch path)
    async fn max_marginal_relevance_search(
        &self,
        query: &str,
        k: usize,
        fetch_k: usize,
        lambda_mult: f32,
    ) -> Result<Vec<Document>, FerrochainError>;

    /// Delete documents by stable ID. Returns Ok(()) even if some IDs do not exist.
    /// BC anchor: BC-2.21.001 PC5
    async fn delete(&self, ids: &[&str]) -> Result<(), FerrochainError>;

    /// Construct a VectorStoreRetriever adapter over this store.
    /// Raises E-VS-003 (VAL) if config is invalid (lambda_mult outside [0,1], k < 1, etc.).
    /// BC anchor: BC-2.20.003 PC1 (as_retriever() construction), BC-2.20.003 INV-2 (E-VS-003 on invalid config)
    fn as_retriever(&self) -> VectorStoreRetriever<'_>;

    /// Metadata-filter similarity search. Default returns `Err(E-VS-005 FilterUnsupported)` when
    /// `filter.filters` is non-empty — fail-safe (not lossy). An empty `MetadataFilter` (vacuously
    /// true, `filter.filters.is_empty()`) delegates to `similarity_search`.
    /// Implementations with native backend filter support MUST override this method.
    /// BC anchor: BC-2.21.004 PC5–PC6 (filter semantics; native pre-filter vs InMemoryVectorStore post-filter),
    /// BC-2.21.004 INV-3 (default fail-safe: Err(E-VS-005 FilterUnsupported) on non-empty filter)
    async fn similarity_search_with_filter(
        &self,
        query: &str,
        k: usize,
        filter: MetadataFilter,
    ) -> Result<Vec<Document>, FerrochainError> {
        // Default: fail-safe on non-empty filter — returning unfiltered results would be lossy
        // and a potential cross-tenant-exposure hazard (ADR-014 Decision 2 §Metadata filter surface F-P131-07 adjudication).
        if !filter.filters.is_empty() {
            return Err(FerrochainError::new("E-VS-005", "FilterUnsupported: metadata filter is not supported by this VectorStore implementation"));
        }
        self.similarity_search(query, k).await
    }
}

/// Factory trait for constructing a concrete VectorStore from raw texts.
/// Sized-bounded to preserve Arc<dyn VectorStore> dyn-safety (Sized is not object-safe).
/// BC anchor: BC-2.21.001 INV-2 (Sized-bounded factory separation rationale)
pub trait VectorStoreFactory: VectorStore + Sized {
    type Config: Default;

    /// Construct a new store by embedding `texts` using `embedding`.
    /// Not callable through Arc<dyn VectorStore> — use only at construction time.
    /// BC anchor: BC-2.21.002 PC1 (InMemoryVectorStore::from_texts_sync semantics and signature)
    fn from_texts_sync(
        texts: Vec<String>,
        embedding: Arc<dyn Embeddings>,
        config: Self::Config,
    ) -> impl std::future::Future<Output = Result<Self, FerrochainError>> + Send;
}

/// Adapter returned by VectorStore::as_retriever(). Implements Retriever.
/// BC anchor: BC-2.20.003 PC1–PC3 (SearchType dispatch: Similarity, SimilarityScoreThreshold, Mmr),
/// BC-2.20.003 INV-1 (#[non_exhaustive] on SearchType)
pub struct VectorStoreRetriever<'a> {
    store: &'a dyn VectorStore,
    search_type: SearchType,
    k: usize,
    fetch_k: usize,
    lambda_mult: f32,
}

/// Dispatch enum for VectorStoreRetriever search strategy.
/// BC anchor: BC-2.20.003 PC2–PC3 (variant semantics), BC-2.20.003 INV-1 (#[non_exhaustive])
#[derive(Debug, Clone, Default)]
#[non_exhaustive]
pub enum SearchType {
    #[default]
    Similarity,
    SimilarityScoreThreshold { score_threshold: f32 },
    Mmr,
}

/// Optional metadata filter for similarity_search_with_filter.
/// BC anchor: BC-2.21.004 PC1–PC4 (multi-clause AND conjunction),
/// BC-2.21.004 INV-1 (#[non_exhaustive] — future variants Gte/Lt/Contains permitted)
#[derive(Debug, Clone)]
#[non_exhaustive]
pub struct MetadataFilter {
    pub filters: Vec<FilterClause>,
}

/// Single filter predicate on document metadata.
/// All three variants use serde_json::Value::PartialEq for exact match (no type coercion).
/// BC anchor: BC-2.21.004 PC1 (Eq semantics), BC-2.21.004 PC2 (Ne semantics — absent key passes),
/// BC-2.21.004 PC3 (In semantics — absent key fails), BC-2.21.004 INV-5 (no type coercion)
#[derive(Debug, Clone)]
#[non_exhaustive]
pub enum FilterClause {
    Eq { key: String, value: serde_json::Value },
    Ne { key: String, value: serde_json::Value },
    In { key: String, values: Vec<serde_json::Value> },
}
```

**BC anchor:**
BC-2.21.001 (VectorStore trait surface, VectorStoreFactory Sized-bounded separation, Arc\<dyn VectorStore\> dyn-safety),
BC-2.21.002 (InMemoryVectorStore — Arc\<dyn Embeddings\> DI, RwLock interior mutability, Vec\<f32\> cosine, VectorStoreFactory constructor),
BC-2.21.003 (zero-norm vector guard → E-VS-001 before cosine division; VP-009 Kani candidate),
BC-2.21.004 (MetadataFilter — Eq/Ne/In FilterClause; additive similarity_search_with_filter; pre vs post filter; #[non_exhaustive]).
ADR-014 Decision 2 (all method signatures, VectorStoreRetriever, SearchType, MetadataFilter), Decision 3 (InMemoryVectorStore), Decision 4 (zero-norm guard E-VS-001), Decision 5 (write-time zero-norm guard E-VS-004).

---

### Embeddings Trait

**Source:** ADR-017 Decision 2; ferrochain-core: core::embeddings.

```rust
// ferrochain-core: core::embeddings
#[async_trait]
pub trait Embeddings: Send + Sync {
    /// Embed a batch of texts. Output must satisfy: output.len() == texts.len() and all
    /// inner vectors have the same length. Violations → Err(E-EMBED-001).
    /// Partial provider failure → Err for entire call; no truncated partial result (DI-014).
    /// BC anchor: BC-2.22.001 PC2 (batch semantics, dimensionality contract → E-EMBED-001,
    /// DI-014 no partial result), BC-2.22.001 INV-1 (all valid impls must satisfy dimensionality)
    async fn embed_documents(
        &self,
        texts: Vec<String>,
    ) -> Result<Vec<Vec<f32>>, FerrochainError>;

    /// Embed a single query text. Returns one vector of the model's declared dimension.
    /// BC anchor: BC-2.22.001 PC3 (embed_query semantics, dimension consistent with embed_documents),
    /// BC-2.22.001 INV-2 (embed_query dimension matches embed_documents dimension for same model)
    async fn embed_query(
        &self,
        text: String,
    ) -> Result<Vec<f32>, FerrochainError>;
}
```

**BC anchor:**
BC-2.22.001 (Embeddings trait — embed_documents batch, embed_query, dimensionality contract → E-EMBED-001, batch partial-failure as Err, Arc\<dyn Embeddings\> dyn-safe; VP-008 proptest seed),
BC-2.22.002 (EmbeddingsOpenAI — text-embedding-3-small/large/ada-002-legacy; OpenAiApiKey DI-010 credential opacity; reqwest/rustls-tls/.timeout(30s); DI-009 per BC-2.14.004),
BC-2.22.003 (EmbeddingsOllama — no API key; /api/embed preferred; use_legacy_endpoint toggle; 30s unconditional per DI-009 / BC-2.14.004).
ADR-017 Decision 2 (Embeddings trait surface, dyn-safety via #[async_trait] + &self, dimensionality contract, E-EMBED-001 authority).

---

### ChatPromptTemplate and PromptValue Surface

**Source:** ADR-015; ferrochain-prompts: prompts::template.

```rust
// ferrochain-prompts: prompts::template

/// Trust classification of a template variable at injection time.
/// Distinct from `ProvenanceTag` (SS-11 ingress boundary struct).
/// `None` trust_level in a TemplateVar is treated as `Trusted` by injection_guard.
/// BC anchor: BC-2.18.004 PC2 (TrustLevel::Untrusted triggers E-TMPL-001),
/// BC-2.18.002 INV-2 (TrustLevel severity ordering: Untrusted > UserInput > Trusted)
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TrustLevel {
    /// Content from an untrusted external source (e.g., MCP tool result, RAG chunk without guardrail).
    Untrusted,
    /// Content from an end-user (e.g., user chat input) — less trusted than internal but not fully untrusted.
    UserInput,
    /// Content from a trusted source (e.g., hard-coded system prompt). Default when trust_level is None.
    Trusted,
}

impl TrustLevel {
    /// Returns true only for `TrustLevel::Untrusted`.
    /// BC anchor: BC-2.18.004 PC2 (injection_guard fail-closed predicate)
    pub fn is_untrusted(&self) -> bool {
        matches!(self, Self::Untrusted)
    }
}

/// A template variable value with its trust classification.
/// `trust_level: None` is treated as `TrustLevel::Trusted` by `injection_guard`.
/// BC anchor: BC-2.18.004 PC2 (trust_level: Some(TrustLevel::Untrusted) triggers E-TMPL-001),
/// BC-2.18.002 PC1–PC2 (MessageProvenance.highest_trust_level = max trust_level across slot vars)
pub struct TemplateVar {
    /// The string value to substitute into the template.
    pub value: String,
    /// Trust classification. `None` is treated as `TrustLevel::Trusted`.
    pub trust_level: Option<TrustLevel>,
}

/// Controls whether a named template slot may receive untrusted input.
/// BC anchor: BC-2.18.002 PC4 (slot_trust_policy recorded in MessageProvenance per rendered slot),
/// BC-2.18.004 PC5 (injection_guard checks TrustLevel::Untrusted against TrustRequired slots → E-TMPL-001),
/// BC-2.18.005 PC1–PC5 (TrustAll on SystemMessage slot rejected at construction → E-TMPL-002; TrustAll on non-System slots accepted)
#[derive(Debug, Clone, PartialEq)]
pub enum SlotTrustPolicy {
    /// Slot accepts any TemplateVar, including untrusted provenance.
    TrustAll,
    /// Slot requires `TrustLevel::Trusted` or `None` (absent `trust_level` treated as Trusted).
    /// `trust_level: Some(TrustLevel::Untrusted)` → E-TMPL-001 (injection_guard fail-closed; VP-006 Kani candidate).
    TrustRequired,
}

impl ChatPromptTemplate {
    /// Construct from a list of (role, template_string, trust_policy) tuples.
    /// Raises E-TMPL-002 if TrustAll is specified for a SystemMessage role (prohibited).
    /// BC anchor: BC-2.18.002 PC1 (ChatPromptTemplate construction via from_messages, returns Result per DI-008),
    /// BC-2.18.005 PC1 (TrustAll on SystemMessage → E-TMPL-002 at construction time; fail-closed)
    pub fn from_messages(
        messages: Vec<(MessageRole, &str, SlotTrustPolicy)>,
    ) -> Result<Self, FerrochainError> { ... }

    /// Render the template with the provided variable bindings.
    /// Runs injection_guard on each slot. Raises E-TMPL-001 (fail-closed) if an untrusted
    /// var is bound to a TrustRequired slot. Raises E-TMPL-003 if a required slot has no binding.
    /// BC anchor: BC-2.18.002 PC1–PC2 (format_messages multi-message rendering semantics, PromptValue output),
    /// BC-2.18.004 PC3–PC5 (injection_guard call site; fail-closed; TrustLevel drives decision),
    /// BC-2.18.001 PC2 (strict-undefined variable reference → E-TMPL-003)
    pub fn format_messages(
        &self,
        vars: HashMap<String, TemplateVar>,
    ) -> Result<PromptValue, FerrochainError> { ... }
}

/// The rendered output of ChatPromptTemplate::format_messages.
/// Each message carries its MessageProvenance for downstream trust decisions.
/// BC anchor: BC-2.18.002 PC2 (PromptValue.messages: Vec<(Message, MessageProvenance)>; one entry per slot in declaration order)
#[non_exhaustive]
pub struct PromptValue {
    pub messages: Vec<(Message, MessageProvenance)>,
}

/// Provenance metadata attached to each rendered message.
/// BC anchor: BC-2.18.002 PC3–PC4 (highest_trust_level aggregation per slot; slot_trust_policy reflection),
/// BC-2.18.004 PC1 (TrustLevel::Untrusted in highest_trust_level drives injection_guard fail-closed decision)
#[non_exhaustive]
pub struct MessageProvenance {
    /// Highest-severity TrustLevel observed across all TemplateVar values substituted into this slot.
    /// `None` = all variables had `trust_level: None` (treated as Trusted by injection_guard).
    pub highest_trust_level: Option<TrustLevel>,
    pub slot_trust_policy: SlotTrustPolicy,
}
```

**BC anchor:**
BC-2.18.001 (PromptTemplate — f-string rendering, partial binding, variable detection, strict-undefined guard → E-TMPL-003; engine-neutral; single-message surface),
BC-2.18.002 (ChatPromptTemplate — from_messages construction, format_messages multi-message rendering, PromptValue output, per-slot MessageProvenance),
BC-2.18.003 (MessagesPlaceholder Vec<Message> in-place expansion; FewShotPromptTemplate few-shot composition),
BC-2.18.004 (injection_guard — TrustLevel::Untrusted on TrustRequired slot → E-TMPL-001 fail-closed; VP-006 Kani candidate),
BC-2.18.005 (SlotTrustPolicy::TrustAll on SystemMessage slot → E-TMPL-002 at construction time; fail-closed construction guard).
ADR-015 Decision 1 (ChatPromptTemplate surface), Decision 2 (SlotTrustPolicy enum), Decision 3 (injection_guard fail-closed semantics), Decision 4 (TrustLevel enum — engine-neutral; both f-string and jinja2 raise E-TMPL-003 on undefined variable).

---

### LcSerializable and Reviver Surface

**Source:** ADR-016; ferrochain-core: core::serializable.

```rust
// ferrochain-core: core::serializable

/// Implemented by types that participate in the lc-JSON serialization protocol.
/// Registration via inventory::submit! at link time (see BC-2.19.003).
/// BC anchor: BC-2.19.001 PC1–PC3 (round-trip contract via Serialized::Constructor),
/// BC-2.19.002 PC1–PC3 (lc_secrets exclusion from Constructor kwargs → Serialized::Secret)
pub trait LcSerializable: Send + Sync {
    /// The lc_id path (e.g., &["langchain", "schema", "document", "Document"]).
    /// Used as the registry key in Reviver's HashMap.
    /// BC anchor: BC-2.19.001 PC1 (lc_id is the allowlist key for revive dispatch)
    fn lc_id() -> &'static [&'static str] where Self: Sized;

    /// Secret field names — excluded from Serialized::Constructor kwargs.
    /// BC anchor: BC-2.19.002 PC1 (secrets produce Serialized::Secret, not Constructor)
    fn lc_secrets(&self) -> &'static [&'static str] { &[] }

    /// Non-secret serializable attributes. Default: empty map.
    /// BC anchor: BC-2.19.001 PC2 (Constructor::kwargs sourced from lc_attributes)
    fn lc_attributes(&self) -> serde_json::Map<String, serde_json::Value> {
        serde_json::Map::new()
    }

    /// True if this type participates in round-trip serialization.
    /// BC anchor: BC-2.19.001 INV-1 (types returning false produce Serialized::NotImplemented)
    fn is_lc_serializable() -> bool where Self: Sized { false }
}

/// Wire envelope produced by lc_serialize(). One of three variants.
/// BC anchor: BC-2.19.001 PC2 (Constructor variant shape — lc field, id, kwargs),
/// BC-2.19.002 PC2 (Secret variant shape — lc field, id; no kwargs),
/// BC-2.19.001 INV-1 (NotImplemented for types with is_lc_serializable() == false)
#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Serialized {
    Constructor {
        lc: u8,
        id: Vec<String>,
        kwargs: serde_json::Map<String, serde_json::Value>,
    },
    Secret {
        lc: u8,
        id: Vec<String>,
    },
    NotImplemented {
        lc: u8,
        id: Vec<String>,
        repr: Option<String>,
    },
}

/// Link-time registry entry. Submitted via inventory::submit! in each type's module.
/// BC anchor: BC-2.19.003 PC2 (LcEntry struct shape: lc_id + constructor fn),
/// BC-2.19.003 INV-1 (registry is append-only at link time; OnceLock safe)
pub struct LcEntry {
    pub lc_id: &'static [&'static str],
    /// Deserializes kwargs back into a boxed Any. Called by Reviver::revive.
    /// BC anchor: BC-2.19.005 PC2 (Reviver dispatches to this constructor fn)
    pub constructor: fn(
        serde_json::Map<String, serde_json::Value>,
    ) -> Result<Box<dyn Any + Send + Sync>, FerrochainError>,
}

inventory::collect!(LcEntry);

/// Reconstructs types from their Serialized representations.
/// Backed by a OnceLock<HashMap<Vec<String>, ConstructorFn>> initialized from
/// inventory::iter::<LcEntry>() at startup.
/// BC anchor: BC-2.19.003 PC3–PC4 (OnceLock singleton, thread-safe concurrent initialization),
/// BC-2.19.005 PC1–PC3 (allowlist containment — unregistered id → E-SRLZ-001 fail-closed; VP-010 Kani candidate),
/// BC-2.19.006 PC1–PC2 (langchain-monolith ids → E-SRLZ-002 structured error)
pub struct Reviver { /* OnceLock<HashMap<Vec<String>, ConstructorFn>> */ }

impl Reviver {
    /// Initialize or return the cached registry. Thread-safe via OnceLock.
    /// BC anchor: BC-2.19.003 PC2 (HashMap from inventory::iter), BC-2.19.003 PC3 (OnceLock idempotent)
    pub fn new() -> Self { ... }

    /// Reconstruct a value from a Serialized envelope.
    /// Raises E-SRLZ-001 if type id is not in the allowlist registry (fail-closed).
    /// Raises E-SRLZ-002 if id matches a known langchain-monolith type.
    /// BC anchor: BC-2.19.005 PC2–PC3 (fail-closed revive; allowlist check precedes dispatch),
    /// BC-2.19.006 PC2 (E-SRLZ-002 for monolith ids — structured error, not silent None)
    pub fn revive(
        &self,
        s: Serialized,
    ) -> Result<Box<dyn Any + Send + Sync>, FerrochainError> { ... }

    /// Return the count of registered entries. Used for CI smoke-test assertions.
    /// BC anchor: BC-2.19.003 PC5 (registry_size used in TV-001/TV-002 relational assertions)
    pub fn registry_size(&self) -> usize { ... }
}
```

**BC anchor:**
BC-2.19.001 (LcSerializable — round-trip via Serialized::Constructor; lc_id, lc_attributes, is_lc_serializable),
BC-2.19.002 (lc_secrets exclusion from Constructor kwargs → Serialized::Secret variant),
BC-2.19.003 (inventory-based type registry — LcEntry, link-time submit!, feature-gated partner entries, OnceLock, Reviver::registry_size smoke-test),
BC-2.19.004 (legacy namespace remapping — alias entries added to same registry at startup),
BC-2.19.005 (Reviver allowlist containment — unregistered id → E-SRLZ-001, fail-closed; VP-010 Kani candidate),
BC-2.19.006 (langchain-monolith type ids → E-SRLZ-002, structured error — not silent None or E-SRLZ-001).
ADR-016 Decision 1 (LcSerializable trait), Decision 2 (Serialized enum), Decision 3 (lc_secrets), Decision 4 (inventory crate 0.3.24, dtolnay; OnceLock initialization), Decision 5 (Reviver allowlist containment).

---

## ferrochain-server HTTP API

### Base URL

All endpoints are relative to the server's configured base URL.
Default port: `7437` (configurable via `server.port` in `ferrochain-server.toml`).

### Canonical Pagination Convention (F-P31-01, ADV-P1D-PASS-31)

All list and aggregate GET endpoints accept uniform pagination query parameters:

| Parameter | Type | Default | Max | Out-of-range |
|-----------|------|---------|-----|--------------|
| `limit` | integer | 10 | 100 | Values > 100 are **silently clamped** to 100 — no validation error (E-CORE) is returned. Decision: clamp (not reject). |
| `offset` | integer | 0 | — | No upper bound. |

Results are ordered by `created_at` **descending** (most-recently created first) unless a
specific endpoint declares a different ordering (e.g., `/history` is ordered newest
checkpoint first, which is also descending by creation sequence). Each list-endpoint
row below cites F-P31-01 where pagination applies. Any endpoint that deviates carries
an explicit documented exemption.

**BC anchors:** BC-2.12.001 PC8 (threads list), BC-2.12.001 PC17 (history), BC-2.12.002 PC21-PC23 (assistants list), BC-2.12.003 PC18 (runs list), BC-2.12.004 PC7 (schedule-runs aggregate).

### Threads

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads` | Create a new thread | BC-2.12.001 |
| GET | `/threads/{thread_id}` | Get thread metadata | BC-2.12.001 |
| GET | `/threads` | List threads; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC) — F-P31-01 | BC-2.12.001 |
| DELETE | `/threads/{thread_id}` | Delete thread and all associated checkpoints | BC-2.12.001 |
| GET | `/threads/{thread_id}/state` | Latest checkpoint state: `{ values: GraphState, checkpoint: CheckpointId, next: [NodeId] }` | BC-2.12.001 |
| POST | `/threads/{thread_id}/state` | Apply state delta `{ values: Map<String,Value>, as_node?: NodeId }` → returns `{ checkpoint: CheckpointId }` | BC-2.12.001 |
| GET | `/threads/{thread_id}/history` | Checkpoint history list, newest-first; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; values > 100 clamped) — F-P31-01 | BC-2.12.001 |

### Assistants

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/assistants` | Create an assistant (named agent config + graph reference) | BC-2.12.002 |
| GET | `/assistants/{assistant_id}` | Get assistant config (resolves via latest-version pointer) | BC-2.12.002 |
| GET | `/assistants` | List assistants; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC) — F-P31-01 | BC-2.12.002 |
| PATCH | `/assistants/{assistant_id}` | Sparse update (new immutable version created; previous accessible via /versions) | BC-2.12.002 |
| DELETE | `/assistants/{assistant_id}` | Delete assistant | BC-2.12.002 |
| GET | `/assistants/{assistant_id}/versions` | List all immutable version snapshots; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; values > 100 silently clamped); **ordering exemption**: results ordered `version` **ascending** (lowest version first) — version ASC is intentional for historical replay and deviates from the default `created_at` DESC canon; exemption declared per F-P32-03, BC-2.12.002 PC20 | BC-2.12.002 |
| POST | `/assistants/{assistant_id}/set_latest` | Update latest-version pointer to `{ version: N }` → HTTP 200 with Assistant at version N; 404 if N not found | BC-2.12.002 |

### Runs

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads/{thread_id}/runs` | Create and start a run (async; returns 202 with `run_id`); run-supplied `config`/`metadata`/`context` deep-merge over the Assistant's stored values, run wins at leaf key (BC-2.12.003 §Run-Config Merge Precedence Invariant, F-P33-02) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs` | List runs for a thread; `?status=queued\|in_progress\|completed\|failed\|interrupted\|cancelled\|summary_halt` filter + canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC) — F-P31-01 | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}` | Get run status and result | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}/stream` | Stream run output as server-sent events (SSE; happy path emits run_start, node_start/stream/end, run_end; **run_end is emitted on completion only** — interrupted runs terminate with interrupt envelope as terminal frame, failed runs terminate with error SSE event; neither emits run_end; BC-2.06.001 PC2+EC-005, BC-2.12.007 EC-001/EC-003). **Guardrail decisions (F-P99-01):** `guardrail_decision` events are emitted for non-Pass guardrail outcomes (Fail/Transform only — Pass not streamed); fire within the tool lifecycle window (before `tool_end`) for ToolResult boundary, and within the node lifecycle window for RAG/Memory boundaries; see §StreamEvent for complete taxonomy and ordering. **ToolEnd content semantics:** `tool_end.data` carries POST-guardrail content — raw rejected payloads are never emitted in any SSE event (BC-2.11.005 INV-5). BC-2.11.002/003/004 PC3/PC4 (per-boundary), ADR-006 rev-3. **Tool approval events (D23/ADR-018):** `tool_approval_request` is emitted BEFORE the run is suspended into `interrupted` state when `pre_tool_dispatch` returns `PreToolDecision::PendingHumanApproval`; it carries `run_id`, `tool_name`, `tool_args`, `action_risk`, and `prompt`. `tool_approval_resolved` is emitted AFTER the interrupt is consumed and BEFORE the decision is applied, on `Command(resume=PreToolDecision)` delivery; it carries `run_id`, `tool_name`, `decision`, `reason`, and `modified_args`. Both events fire within the NodeStart/NodeEnd window, before the ToolStart window for the same tool call; see §PreToolCallHook and BC-2.06.004/005. **Compaction event (D23/ADR-019):** `compaction_event` is emitted after a compaction cycle completes and the compacted checkpoint is durably written (step 6 of BC-2.10.006 7-step sequence); it carries `run_id`, `trigger`, `compacted_turns`, `summary_token_count`, and `tokens_remaining_after`; fires after StepEnd and before the next StepStart; see §Compaction and BC-2.06.006. | BC-2.12.007 |
| POST | `/threads/{thread_id}/runs/{run_id}/resume` | Deliver resume value to interrupted run | BC-2.05.004 |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | Cancel a queued or in_progress run (transitions to cancelled) | BC-2.12.003 |
| DELETE | `/threads/{thread_id}/runs/{run_id}` | Delete a terminal run record (completed/failed/cancelled/summary_halt; HTTP 409 if queued, in_progress, or interrupted — cancel or resume-to-complete/summary_halt first) | BC-2.12.003 |

### Cron Schedules

Schedules are **assistant-owned** (not thread-owned). Each firing creates a **fresh
`thread_id`** — no prior thread context is shared unless `RunnableConfig.thread_id`
is explicitly set by the operator (BC-2.12.004). Paths are flat (not thread-nested).

> **No list-all-schedules endpoint (OBS-P32-1, ADV-P1D-PASS-32):** No list-all-schedules
> endpoint in v1 — schedules are addressed individually by cron_id; the flat
> `GET /runs?schedule_id={cron_id}` aggregate is the only schedule-scoped listing surface
> (URL-scheme canon, ADV-P1D-PASS-23).

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/schedules` | Create a cron schedule (assistant_id + cron expression + config) | BC-2.12.004 |
| GET | `/schedules/{cron_id}` | Get schedule (current `enabled` state, `last_fired_at`) | BC-2.12.004 |
| PATCH | `/schedules/{cron_id}` | Enable/disable schedule (`{ "enabled": false }`; in-flight Run continues) | BC-2.12.004 |
| DELETE | `/schedules/{cron_id}` | Delete schedule; halts all future firings (`204 No Content`) | BC-2.12.004 |

**Cross-thread aggregate query (flat, read-only):**

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| GET | `/runs?schedule_id={cron_id}` | List all Runs fired by a given schedule across all threads (read-only aggregate; canonical pagination: `?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC — ordering canon declared in BC-2.12.004 PC7; F-P31-01) | BC-2.12.004 |

> **Note:** This is the only flat `/runs` endpoint. All other Run CRUD paths are
> thread-scoped (`/threads/{thread_id}/runs/...`). This endpoint exists because
> cron-fired Runs each have distinct `thread_id` values — a thread-scoped query
> cannot enumerate all Runs for a schedule. Decision source: F-P23-01.

### HTTP Status Codes

| Code | Meaning | Error Source |
|------|---------|-------------|
| 200 | Success with response body | — |
| 201 | Created (new resource; body contains created object) | — |
| 202 | Accepted (async run created; polling required) | — |
| 204 | No Content (delete success; no response body) | — |
| 400 | Validation error | E-CORE-001, E-CORE-002, E-CORE-003, E-CORE-005 (VAL — ferrochain-core input validation), E-CRON-002 (InvalidCronExpression); E-PROV-005 (StructuredOutputParseError, VAL) and E-PROV-006 (ContextLengthExceeded, VAL) — categorical VAL→400; surfaced embedded in Run.error, not as direct HTTP response codes (OBS-3; BC-2.08.003, BC-2.08.004). **Note:** E-CORE-004 (INTERNAL) excluded — see E-CORE-004 omission note below (F-P69-01). |
| 401 | Authentication failure (categorical fallback) | E-PROV-004 (ProviderAuthFailed, AUTH) — categorical fallback only; no v1 server endpoint emits 401 as a direct terminal HTTP status; surfaced embedded in Run.error. Server-side authentication middleware is out of v1 scope (F-P26-05; F-P25-02: E-SERVER-004 recategorized AUTH→POLICY → 403) |
| 403 | Policy enforcement (debug route, role gate) | E-SERVER-004 (DebugRouteUnauthorized), E-GRAPH-013 (InsufficientApproverRole — SECURITY; direct HTTP 403 on `POST /threads/{thread_id}/runs/{run_id}/resume` when caller role is insufficient for the interrupt's risk tier; BC-2.05.006 PC3-PC4, EC-001; F-P27-04) — **NOTE (F-P66-03, ADV-P1D-PASS-66):** E-SERVER-005 (CorsRejected) REMOVED from this row; CORS denial is silent header-omission per BC-2.12.005 PC2/TV-001 and never produces a direct HTTP 403 error body; code retired unraised. |
| 404 | Resource not found | E-SERVER-002 (RunNotFound), E-SERVER-003 (ThreadNotFound), E-SERVER-006 (ScheduleNotFound), E-SERVER-009 (AssistantNotFound — direct resource lookup), E-SERVER-010 (AssistantVersionNotFound) |
| 409 | Conflict (duplicate resource or state conflict) | E-SERVER-007 (ThreadAlreadyExists), E-SERVER-008 (ThreadStateConflict — POLICY→409 per-endpoint override; BC-2.14.002 PC3; F-P26-01), E-SERVER-012 (ConcurrentRun), E-SERVER-015 (RunAlreadyExecuting) |
| 422 | Semantic validation failure (VAL-category on body content) and per-endpoint POLICY→422 overrides (request valid but current state makes processing impossible) | E-GRAPH-003 (UnknownRoutingTarget), E-GRAPH-004 (DuplicateBarrierWrite), E-GRAPH-007 (UnknownChannelKey), E-GRAPH-008 (UnreachableGraph), E-GRAPH-009 (DuplicateNodeName), E-GRAPH-010 (UnknownBarrierWriter), E-GRAPH-012 (UnmappedRouteKey), E-GRAPH-015 (NoParentGraph); E-SERVER-009 (AssistantNotFound in run body — invalid assistant_id reference at run creation; context-dependent: same code, 404 at direct lookup), E-SERVER-011 (GraphNotFound — graph_id in assistant body not registered); E-GRAPH-002 (NoActiveInterrupt — POLICY→422 per-endpoint override on resume endpoint: run exists and caller is authorized, but no interrupt slot is active; BC-2.14.002 PC3 9th override; F-P27-01). INTERNAL/DURABILITY E-GRAPH codes (E-GRAPH-006, E-GRAPH-011) and DURABILITY/INTERNAL E-CHKPT codes (E-CHKPT-001, -002, -003, -004, -006, -007) go to the 500 row; E-CHKPT-005 (TENANCY) is library-level embedded — see omission note below. (OBS-1; narrowed from E-GRAPH-*/E-CHKPT-* wildcards — F-P26-01; F-P27-01 adds E-GRAPH-002; F-P27-03 corrects E-CHKPT-* over-broad text) |
| 429 | Rate limited | E-PROV-001 |
| 500 | Internal error | E-GRAPH-006 (BspDeterminismViolation, INTERNAL), E-GRAPH-011 (ConditionalEdgePanic, INTERNAL); E-CHKPT-001 (CheckpointWriteFailed, DURABILITY), E-CHKPT-002 (MonotonicClockRegression, INTERNAL), E-CHKPT-003 (CheckpointReadFailed, DURABILITY), E-CHKPT-004 (EncryptionKeyRotationFailed, INTERNAL — F-P27-02/03: category corrected SECURITY→INTERNAL; added to 500 row), E-CHKPT-006 (SerializationFailed, INTERNAL), E-CHKPT-007 (CipherHeaderMissing, INTERNAL — unencrypted legacy blob read in encrypted store; BC-2.04.007 EC-004); E-SERVER-014 (RunStoreFailed) |
| 502 | Bad Gateway (provider transport failure) | E-PROV-003 (StreamInterrupted), E-PROV-008 (ProviderHttpError — generic provider HTTP 5xx / unparseable error body; BC-2.08.004 EC-004/EC-005) — categorical fallback only; no v1 endpoint emits 502 as a direct terminal HTTP status; surfaced embedded in Run.error |
| 503 | Service temporarily unavailable (retryable store/lock timeout) | E-SERVER-016 (IdempotencyLockTimeout); Retry-After header present; per-endpoint override over categorical Timeout→504 (F-P25-01; BC-2.12.006 EC-002; BC-2.14.002 PC3 carve-out) |
| 504 | Gateway Timeout (provider response timeout) | E-PROV-002 (ProviderTimeout) — categorical fallback only; no v1 endpoint emits 504 as a direct terminal HTTP status; surfaced embedded in Run.error |

**BC anchor:** BC-2.12.001 through BC-2.12.007

> **Async error intentional omissions (OBS-2, ADV-P1D-PASS-26):** E-CRON-001 (AssistantNotFoundAtFiring) and E-CRON-003 (ScheduleQueueFull) are async firing-time errors surfaced in schedule/run state, never as a direct HTTP response — intentionally omitted from this table.

> **Graph execution errors embedded in Run.error (F-P27-04, ADV-P1D-PASS-27; F-P49-02, ADV-P1D-PASS-49):** E-GRAPH-001 (InvalidUpdateError, CONCURRENCY — BC-2.03.002; concurrent BSP write failure surfaces as a run failure, embedded in Run.error.type), E-GRAPH-014 (InterruptApprovalTimeout, POLICY — BC-2.05.006 EC-005; timeout causes run transition to `failed`, embedded in Run.error), E-GRAPH-016 (InterruptWithoutCheckpointer, POLICY — BC-2.05.001 EC-001, BC-2.10.004; raised when interrupt() is called without a CheckpointSaver, surfaces as a run failure), and E-GRAPH-017 (GraphRecursionLimitExceeded, POLICY — BC-2.03.001 PC5; raised when the BSP super-step count for the current invocation segment exceeds `config.recursion_limit` (default 25); the run transitions to `failed`; primary infinite-loop guard for cyclic graphs) are graph execution errors that appear embedded in Run.error, never as direct terminal HTTP status codes. Categorical mappings: CONCURRENCY→409, POLICY→403 (apply only if ever surfaced directly — not in v1).

> **E-CHKPT-005 library-level omission (F-P27-03, ADV-P1D-PASS-27):** E-CHKPT-005 (SessionAddressCollision, TENANCY — BC-2.04.006) is a checkpoint library-level error enforcing the session triple-address uniqueness invariant (NE-12). TENANCY→409 is the categorical mapping. In v1 this error is raised within the checkpoint layer before any HTTP response is sent, surfacing as a run failure embedded in Run.error, not as a direct terminal HTTP 409 response. Intentionally omitted from the 409 row for the same reason as the E-PROV categorical-fallback codes.

> **E-PROV-007 embedded omission (OBS-P28-3, ADV-P1D-PASS-28):** E-PROV-007 (StructuredOutputRefused, POLICY — BC-2.08.003) is emitted when the OpenAI Responses API rejects a `json_schema` structured output request via a safety-filter refusal. POLICY→403 is the categorical mapping. In v1 this error surfaces as a run failure embedded in Run.error — the server cannot distinguish a refusal from a valid LLM response until the response body is deserialized post-stream. No v1 server endpoint emits HTTP 403 directly for this code. Intentionally omitted from the 403 row; the 403 row lists only codes that produce a direct terminal HTTP 403 response (E-SERVER-004, E-GRAPH-013). (E-SERVER-005 previously listed here — RETIRED F-P66-03, ADV-P1D-PASS-66.)

> **E-SERVER-013 startup-only omission (F-P55-01, ADV-P1D-PASS-55):** E-SERVER-013 (InvalidDebugRouteKey, VAL — BC-2.12.005 EC-005/TV-007) is raised during server configuration validation at startup (debug_route_key must be non-empty when debug routes are enabled). VAL→400 is the categorical mapping. In v1 this error halts startup before any HTTP listener is bound; it is never surfaced as a terminal HTTP response. Intentionally omitted from the 400 row; same treatment as E-CHKPT-005.

> **E-CORE-004 library-layer omission (F-P69-01, ADV-P1D-PASS-69):** E-CORE-004 (INTERNAL — BC-2.01.004 PC5) is raised when a type-erased `DynRunnable` pipeline detects a type boundary mismatch between adjacent stages at the first `invoke` call. INTERNAL→500 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError { category: INTERNAL, code: E-CORE-004 })` return from the `RunnableSequence::invoke` call site in library code; it is never emitted as a terminal HTTP response by ferrochain-server (if ever propagated to a server-side run, it would surface embedded in Run.error, not as a direct HTTP 500). Intentionally omitted from the HTTP status table; same treatment as E-CORE-006 and E-CORE-007.

> **E-CORE-006 library-layer omission (F-P56-01, ADV-P1D-PASS-56):** E-CORE-006 (RecursionLimitExceeded, INTERNAL — BC-2.01.003 PC5) is raised by the ferrochain-core Runnable-layer when nested `invoke`/`stream` call depth exceeds `config.recursion_limit` (default 25). INTERNAL→500 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from the `invoke`/`stream` call site in library code; it is never emitted as a terminal HTTP response by ferrochain-server (if it ever propagates to a server-side run, it would surface embedded in Run.error, not as a direct HTTP 500). Intentionally omitted from the HTTP status table; same treatment as E-MCP-*, E-SPLIT-*, and other library-layer errors.

> **E-CORE-007 library-layer omission (ADV-P1D-PASS-56-COMPLETION):** E-CORE-007 (GuardrailHookPanic, INTERNAL — BC-2.11.002 / BC-2.11.003 / BC-2.11.004) is raised when a `GuardrailHook::evaluate` call panics at any content-ingress boundary (tool-result, RAG chunk, or memory item). INTERNAL→500 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from the guardrail ingress pipeline in library code; it is never emitted as a terminal HTTP response by ferrochain-server (if ever propagated to a server-side run, it would surface embedded in Run.error). Fail-closed semantics: content that triggered the panic is treated as rejected and does not enter the model context. Intentionally omitted from the HTTP status table; same treatment as E-CORE-006.

> **E-CORE-008 library-layer omission (burst-226/F-P131-01/2026-07-21):** E-CORE-008 (GuardrailCriticalRejection, SECURITY — BC-2.20.002 PC2) is raised by `GuardedDocuments::rag_ingress` when any document receives `GuardrailResult::Fail { severity: GuardrailSeverity::Critical }`. SECURITY→403 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from `GuardedDocuments::rag_ingress` in library code; it is never emitted as a terminal HTTP response by ferrochain-server (if ever propagated to a server-side run, it would surface embedded in Run.error, not as a direct HTTP 403). Fail-closed semantics: the entire batch is aborted; no `GuardedDocuments` is produced. Intentionally omitted from the HTTP status table; same treatment as E-CORE-007.

> **E-CHKPT-008 library-layer omission (D20 sub-burst 2; raise-timing corrected F-P82-02):** E-CHKPT-008 (FtsLimitZero, VAL) covers two distinct sub-cases with different raise times: **(1) `FtsSearchConfig.limit = 0`** — raised at **`FtsSearchConfig` construction time** (DI-008 construction-result contract; BC-2.04.008 PC6/EC-004); **(2) malformed FTS5 query string** — raised at **`fts_search` call time** when SQLite FTS5 fails to parse the query string passed as the standalone `query: &str` first parameter (SQLite FTS5 parse error propagation; BC-2.04.008 EC-002). Note: `query` is a standalone first parameter to `fts_search`, NOT a field of `FtsSearchConfig`. VAL→400 is the categorical mapping. In v1 both sub-cases surface as a direct `Err(FerrochainError)` return from library code; neither is emitted as a terminal HTTP response by ferrochain-server (no FTS search endpoint in v1; if ever surfaced via server, it would appear embedded in Run.error). Intentionally omitted from the HTTP status table.

> **E-CHKPT-009 library-layer omission (D20 sub-burst 2):** E-CHKPT-009 (Fts5Unavailable, INTERNAL — BC-2.04.008 EC-006) is raised at `CheckpointSaver::new()` construction time when FTS is requested but the SQLite build does not include the FTS5 extension. INTERNAL→500 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from `CheckpointSaver::new()` in library code; it is never emitted as a terminal HTTP response by ferrochain-server (server startup with a bad FTS5 config fails before any listener is bound). Intentionally omitted from the HTTP status table; same treatment as E-CHKPT-005 and E-SERVER-013 (startup-time library errors).

> **E-PROV-009 library-layer omission (D20 sub-burst 2):** E-PROV-009 (ToolCallDialectParseError, VAL — BC-2.08.013 PC8/PC9/EC-002) is raised when `ToolCallDialect::deserialize_tool_calls` fails to parse model-output content. VAL→400 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from the dialect dispatch layer in library code; it propagates as Run.error on the server side (same treatment as E-PROV-005, E-PROV-006). Never a direct HTTP terminal response. Intentionally omitted from the HTTP status table.

> **E-PROV-010 library-layer omission (D20 sub-burst 2):** E-PROV-010 (ProviderChainExhausted, POLICY — BC-2.08.014 PC5/EC-004) is raised when all providers in the `ProviderFallbackPolicy` chain have been tried and all failed. POLICY→403 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from the provider dispatch layer in library code; it propagates as Run.error on the server side (same treatment as E-PROV-007 StructuredOutputRefused). Never a direct HTTP terminal response. Intentionally omitted from the HTTP status table.

> **Library/execution-layer codes — blanket omission (OBS-P29-1, ADV-P1D-PASS-29; F-P30-01, ADV-P1D-PASS-30; D21/2026-07-20; D23/2026-07-22):** All remaining library and execution-layer error codes — E-MCP-* (BC-2.09.x, TOOL/TRANSPORT/VAL), E-SBXD-* (BC-2.13.x, SECURITY/POLICY/INTERNAL), E-RETRY-* (BC-2.16.x, POLICY/VAL), E-BUDGET-* (BC-2.10.x, POLICY/DURABILITY), E-MEMORY-* (BC-2.15.x, VAL/POLICY/DURABILITY/SECURITY), E-SPLIT-* (BC-2.07.x, VAL), E-TMPL-* (BC-2.18.x, SECURITY/VAL), E-SRLZ-* (BC-2.19.x, VAL), E-VS-* (BC-2.20.x/BC-2.21.x, VAL), E-EMBED-* (BC-2.22.x, VAL), E-TOOLS-* (BC-2.23.x, SECURITY/VAL/TIMEOUT) — surface embedded in Run.error or as library `Err` return values. None has a direct HTTP row in this table. Categorical fallbacks apply if ever surfaced directly (TOOL→422, TRANSPORT→502, SECURITY→403, POLICY→403, DURABILITY→500, INTERNAL→500, VAL→400, TIMEOUT→503) but in v1 these codes are not emitted as terminal HTTP responses by any endpoint. Spot-checked: E-MCP-001 (BC-2.09.004 — embedded in run as tool failure), E-SBXD-001 (BC-2.13.005 — sandbox security violation embedded in run), E-MEMORY-001 (BC-2.15.001 — memory store validation error embedded in run); all confirmed library-layer only. **D21 additions confirmed library-layer only:** E-TMPL-001 (BC-2.18.004 — prompt injection guard, ferrochain-prompts), E-SRLZ-001 (BC-2.19.005 — Reviver allowlist fail-closed, ferrochain-core::serializable), E-VS-001 (BC-2.21.003 — zero-norm cosine guard, ferrochain-vectorstores), E-EMBED-001 (BC-2.22.001 — dimensionality contract, ferrochain-core::embeddings); all library-layer Err returns. **D23 additions confirmed library-layer only:** E-TOOLS-001 (BC-2.23.001–006 — PathGuard confinement SECURITY), E-TOOLS-002/003/007 (VAL construction/call-time), E-TOOLS-004 (BashTool timeout TIMEOUT/Never), E-TOOLS-005/006 (informational payload fields — not raised Err; included for census completeness); all ferrochain-tools library-layer. **burst-233 additions confirmed library-layer only:** E-TOOLS-008 (BC-2.23.001–004/006 — OS-level I/O error TOOL/Maybe, wraps std::io::ErrorKind), E-TOOLS-009 (BC-2.23.006 — invalid regex pattern VAL/Never); both ferrochain-tools library-layer. **burst-240 addition confirmed library-layer only:** E-MCP-006 (BC-2.09.002 — McpContentUnsupported VAL/Never; raised by _convert_mcp_content_to_block for unsupported content block types such as AudioContent; ferrochain-mcp library-layer Err return; never direct HTTP terminal in v1). **Disposition census (burst-240/2026-07-22): 43 HTTP + 17 individual + 48 blanket = 108.** (+1 blanket: E-MCP-* 5→6 codes.) Blanket group breakdown: E-MCP-* 6 + E-SBXD-* 6 + E-RETRY-* 4 + E-BUDGET-* 2 + E-MEMORY-* 8 + E-SPLIT-* 2 + E-TMPL-* 3 + E-SRLZ-* 2 + E-VS-* 5 + E-EMBED-* 1 + E-TOOLS-* 9 = 48.

## Exit Code Semantics

ferrochain is a library — process exit codes do not apply. The embedded `ferrochain-server` uses standard HTTP status codes; see §HTTP Status Codes in the §ferrochain-server HTTP API section above. Library errors propagate as `FerrochainError` values per the error taxonomy.

## JSON Output Schema

Canonical JSON output shapes for `ferrochain-server` API responses. The primary response objects are defined in the sections below.

## Run Object Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["run_id", "thread_id", "assistant_id", "status", "created_at", "updated_at"],
  "properties": {
    "run_id": { "type": "string", "description": "Monotonic logical run identifier" },
    "thread_id": { "type": "string" },
    "assistant_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["queued", "in_progress", "interrupted", "completed", "failed", "cancelled", "summary_halt"],
      "description": "Run state machine: queued → in_progress → completed | failed | cancelled | summary_halt; in_progress ⇄ interrupted (resume via POST .../resume). summary_halt is a terminal state produced by the OnCeiling::Summarize budget path (BC-2.10.003 PC8(d)). Authority: BC-2.12.003 PC7-PC9 (v1.4). multitask_strategy='enqueue' creates the new run in 'queued' state; it transitions to 'in_progress' after the current run finishes. Use POST .../cancel to transition queued/in_progress→cancelled."
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time", "description": "Set on every Run state mutation (status transition, output/error write). Always present. Authority: BC-2.12.003 PC13." },
    "completed_at": { "type": ["string", "null"], "format": "date-time", "description": "Set only on terminal transition (status → completed | failed | cancelled | summary_halt). Null in all non-terminal states (queued, in_progress, interrupted). Distinct from updated_at — terminal-timestamp semantics. Authority: F-P24-01, BC-2.12.003 PC13 v1.4." },
    "output": { "description": "Final graph state; present only when status=completed or status=summary_halt. For summary_halt, output carries the summarize model response (BC-2.10.003 PC8(c)). Null in all other states." },
    "error": {
      "type": ["object", "null"],
      "description": "RFC-7807 problem detail; present only when status=failed",
      "properties": {
        "type": { "type": "string", "format": "uri" },
        "title": { "type": "string" },
        "detail": { "type": "string" },
        "extensions": { "type": "object" }
      }
    },
    "interrupt": {
      "type": ["object", "null"],
      "description": "Present only when status=interrupted. Reconciled F-P25-06 to match BCs (authoritative): BC-2.05.001 (InterruptPayload { value, interrupt_id }), BC-2.05.006 (HitlInterruptPayload { action_risk, action, context }), entities-server.md §Interrupt (interrupt_id, node_name, scratchpad).",
      "properties": {
        "interrupt_id": {
          "type": "string",
          "description": "Stable identifier for this interrupt (hash of checkpoint namespace at interrupt time). Used in Command(resume={interrupt_id: value}) targeted delivery. Authority: BC-2.05.001 TV-001, entities-server.md §Interrupt."
        },
        "node_name": {
          "type": "string",
          "description": "Name of the node that raised this interrupt. Canonical field name: node_name (per entities-server.md §Interrupt). Was incorrectly 'node_id' — fixed F-P25-06."
        },
        "super_step": { "type": "integer", "description": "Super-step index at the time the interrupt was raised." },
        "value": {
          "description": "The interrupt value surfaced to the caller (any serializable type; msgpack round-trip required per BC-2.05.001 PC4 TV-001). Authority: BC-2.05.001 PC4."
        },
        "action_risk": {
          "type": ["string", "null"],
          "enum": ["ReadOnly", "Low", "Medium", "High", null],
          "description": "Typed action-risk tier for Domain A HITL interrupts (BC-2.05.006 HitlInterruptPayload). Null for non-risk-tiered interrupts. Canonical field name: action_risk. Was incorrectly 'risk_tier' — fixed F-P25-06."
        },
        "action": {
          "type": ["string", "null"],
          "description": "Human-readable description of the action awaiting authorization (Domain A HITL; HitlInterruptPayload.action). Null for non-HITL-tier interrupts."
        },
        "context": {
          "description": "Optional structured context for the approver (Domain A HITL; HitlInterruptPayload.context). Null for non-HITL-tier interrupts."
        },
        "scratchpad": { "description": "Per-task scratchpad state at interrupt time. Authority: entities-server.md §Interrupt." }
      }
    }
  }
}
```

## Resume Request Schema

```json
{
  "type": "object",
  "required": ["resume_value"],
  "properties": {
    "resume_value": { "description": "The value delivered to the interrupted node (Command(resume=value))" },
    "approver_id": { "type": ["string", "null"], "description": "Optional approver identity for audit trail" }
  }
}
```

> **REST resume is FIFO-only (OBS-P48-1, ADV-P1D-PASS-48 — adjudicated D17-Q2 HITL contract):** REST resume delivers to the single active interrupt slot in FIFO order; it does not accept an `interrupt_id` field and cannot target a specific concurrent interrupt. Targeted delivery to a specific `interrupt_id` is library-API only: `Command(resume={interrupt_id: value})` submitted via `graph.invoke` / `graph.stream` (BC-2.05.004 EC-002). This is an intentional v1 limitation consistent with the D17-Q2 committed FIFO-resume HITL contract.

**BC anchor:** BC-2.05.004

## ferrochain-server Config File Schema

```toml
# ferrochain-server.toml
[server]
port = 7437                    # default; must be > 1023 for non-root
host = "127.0.0.1"             # default: loopback only
workers = 4                    # Tokio worker threads; default: num_cpus

[security]
# SecurityConfig::default() denies CORS and gates debug routes (NE-14, BC-2.12.005)
cors_allow_origins = []        # empty = deny all cross-origin requests (SECURE DEFAULT)
debug_route_key = ""           # empty string = debug routes disabled (SECURE DEFAULT)
                               # non-empty = enables /_debug route; gate requires
                               # Authorization: Bearer <key> (F-P26-04; BC-2.12.005 authoritative)

[checkpoint]
backend = "sqlite"             # "sqlite" | "memory"; postgres = stretch target
sqlite_path = "./ferrochain.db"

[sandbox]
backend = "wasm"               # "wasm" (default, enforcing) | "container" | "process"
                               # 'process' backend emits loud WARNING once per execute() invocation — NOT construction/startup (BC-2.13.002 PC2/EC-002)

[budget]
# Global budget policy (GraphConfig::budget_config default for all runs on this server).
# Per-run override: pass RunnableConfig { budget_config: Some(BudgetConfig { ... }), .. }
# to Runnable::invoke/stream. This is also the mechanism used by BudgetResume::Extend:
# the engine patches RunnableConfig::budget_config with the extended ceiling for only
# that resumed execution — GraphConfig is NOT mutated (BC-2.10.004 PC6, F-P92-02).
default_token_limit = null     # null = unlimited (operator must set a limit)
default_on_ceiling = "halt"    # "halt" | "escalate"
                               # "summarize" is config-API-only; requires a summarize_prompt
                               # payload and is not expressible as a bare-string default —
                               # use table form: [budget.on_ceiling] mode = "summarize"
                               #                 summarize_prompt = "Summarize your findings."
```

**BC anchor:** BC-2.12.005, BC-2.13.001, BC-2.13.002

## Cargo Feature Flags

| Feature | Default | Description | BC Anchor |
|---------|---------|-------------|-----------|
| `checkpoint-sqlite` | on | SQLite checkpoint backend | BC-2.04.001 |
| `checkpoint-memory` | off | In-memory checkpoint backend (testing only; not crash-safe) | BC-2.04.002 |
| `checkpoint-postgres` | off | Postgres checkpoint backend (stretch target) | — |
| `sandbox-wasm` | on | WASM sandbox backend (enforcing; default) | BC-2.13.001 |
| `sandbox-container` | off | Container sandbox backend | BC-2.13.001 |
| `sandbox-process` | off | Process backend (NOT enforcing; no filesystem/network/memory isolation); compiles `ProcessBackend` but does NOT make it a default — accessible ONLY via `Sandbox::unsafe_process_no_isolation()`; `SandboxBackend::default()` returns `Err(E-SBXD-003)` when no enforcing backend is compiled (BC-2.13.001 PC3/PC4) | BC-2.13.001, BC-2.13.002 |
| `server` | off | ferrochain-server HTTP server | BC-2.12.001 |
| `mcp` | off | ferrochain-mcp adapter | BC-2.09.001 |
| `budget` | on | Budget governance policy primitive | BC-2.10.001 |
| `guardrail` | on | Content provenance + guardrail hook | BC-2.11.001 |

## Flag Interactions

| Flag A | Flag B | Interaction |
|--------|--------|-------------|
| `checkpoint-memory` | `checkpoint-sqlite` | Mutually exclusive in production; memory is testing-only |
| `sandbox-wasm` | `sandbox-container` | Pick one enforcing backend; wasm takes precedence if both enabled |
| `server` | any checkpoint feature | Server requires exactly one checkpoint backend to be active |
| `sandbox-wasm` + `sandbox-container` both off | (none) | `SandboxBackend::default()` returns `Err(E-SBXD-003 SandboxInitFailed { reason: "no enforcing backend compiled in" })`; NO silent process fallback (BC-2.13.001 PC4/EC-002, DI-006, NE-01); process backend reachable ONLY via explicit `Sandbox::unsafe_process_no_isolation()` (BC-2.13.001 PC3) |
