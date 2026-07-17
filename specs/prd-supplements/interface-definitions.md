---
document_type: prd-supplement-interface-definitions
level: L3
version: "2.33"
status: active
producer: product-owner
timestamp: 2026-07-17T00:00:00Z
phase: 1d
changelog:
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
  - "1.6 (ADV-P1D-PASS-25): F-P25-01 add 503 row (E-SERVER-016 IdempotencyLockTimeout per-endpoint override); F-P25-02 recategorize 401→reserved, 403 now E-SERVER-004 POLICY + E-SERVER-005; F-P25-06 reconcile Run.interrupt sub-fields (interrupt_id, node_name, value, action_risk, action, context added; node_id→node_name, risk_tier→action_risk renamed); F-P25-07 add 201 and 204 rows, add E-CRON-002 to 400 row; OBS-2 add 502 and 504 categorical fallback rows."
  - "1.7 (ADV-P1D-PASS-26): F-P26-04 config comment X-Debug-Key+/debug/*→Authorization:Bearer+/_debug; F-P26-05 rewrite 401 row with E-PROV-004 categorical-fallback; OBS-1 narrow 422 wildcard to enumerated VAL E-GRAPH codes; OBS-2 add E-CRON-001/003 intentional-omission note; OBS-3 add E-PROV-005/006 to 400 row with embedded-in-Run.error annotation."
  - "1.8 (ADV-P1D-PASS-27): F-P27-01 add E-GRAPH-002 (POLICY→422 per-endpoint override) to 422 row; F-P27-02/03 replace 'all E-CHKPT-*' over-broad text with specific enumeration, add E-CHKPT-004 (INTERNAL) to 500 row, add E-CHKPT-005 omission note; F-P27-04 add E-GRAPH-013 (SECURITY) to 403 row, add E-GRAPH-001/014/016 embedded omission notes; 422 row description updated to note POLICY→422 overrides."
  - "1.9 (ADV-P1D-PASS-28): OBS-P28-3 add E-PROV-007 (StructuredOutputRefused, POLICY) omission note — categorical POLICY→403 fallback only; surfaced embedded in Run.error, not as a direct terminal HTTP status."
  - "2.0 (ADV-P1D-PASS-29): F-P29-03 fix SSE description on /stream row: node_start/delta/end → node_start/stream/end (node_delta was never canonical; BC-2.06.001 is the streaming taxonomy authority). OBS-P29-1 add blanket omission note for library/execution-layer codes (E-MCP-*, E-SBXD-*, E-RETRY-*, E-BUDGET-*, E-MEMORY-*, E-SPLIT-*) confirming none has a direct HTTP row."
  - "2.1 (ADV-P1D-PASS-30): F-P30-01 blanket omission note: TOOL→N/A corrected to TOOL→422 (BC-2.14.002 PC3 categorical authority); full 12-category token diff applied — added TRANSPORT→502 and INTERNAL→500 (both present in family labels but absent from summary); corrected VAL→400/422 to VAL→400 (categorical default; 422 requires per-endpoint override decision, not applicable to library-layer fallback)."
  - "2.2 (ADV-P1D-PASS-31): F-P31-01 add §Canonical Pagination Convention section; propagate limit (default 10, max 100, silently clamped if > 100) + offset (default 0) + created_at DESC ordering to GET /threads (explicit defaults), GET /threads/{id}/history (declare default 10/max 100 on existing limit), GET /assistants (add limit/offset), GET /threads/{id}/runs (add limit/offset alongside status filter), GET /runs?schedule_id={cron_id} (add limit/offset, declare created_at DESC). Out-of-range canon: clamp (not reject). BC anchors: BC-2.12.001 PC8/PC17, BC-2.12.003 PC18, BC-2.12.004 PC7."
  - "2.4 (ADV-P1D-PASS-33): F-P33-01 add BC-2.12.002 PC21-PC23 to §Canonical Pagination Convention BC anchors list (list-assistants anchor). F-P33-02 add run-config merge precedence note to POST /threads/{thread_id}/runs row description (deep-merge over Assistant config, run wins at leaf key; BC-2.12.003 §Run-Config Merge Precedence Invariant)."
  - "2.5 (ADV-P1D-PASS-46): F-P46-01 — clarify /stream row description: run_end is emitted on completion only; interrupt and failure paths truncate stream without run_end (BC-2.06.001 PC2 + EC-005 authority; BC-2.12.007 v1.2)."
  - "2.7 (ADV-P1D-PASS-48): F-P48-01 fix E-RETRY-* blanket omission annotation — E-RETRY-004 (VAL, minted P34) expands namespace to POLICY/VAL; annotation corrected from POLICY to POLICY/VAL. OBS-P48-1 (adjudicated D17-Q2 FIFO-resume contract) add FIFO-only documentation line to Resume Request Schema: REST resume delivers to single active interrupt slot FIFO; targeted delivery by interrupt_id is library-API only (Command(resume={interrupt_id: value}), BC-2.05.004 EC-002)."
  - "2.6 (ADV-P1D-PASS-47): F-P47-01 (CRITICAL) fix Flag Interaction Rules row for sandbox-wasm+container-both-off — remove silent-process-fallback claim, replace with SandboxBackend::default()→Err(E-SBXD-003 SandboxInitFailed) per BC-2.13.001 PC4/EC-002/DI-006/NE-01; F-P47-02 fix [sandbox] config comment 'process emits WARNING on startup'→'once per execute() invocation — NOT construction/startup' per BC-2.13.002 PC2/EC-002; OBS-P47-1 add sandbox-process row to Cargo Feature Flags table with NOT-enforcing/explicit-constructor-only semantics per BC-2.13.001 PC3/PC4."
  - "2.3 (ADV-P1D-PASS-32): F-P32-03 add canonical pagination to GET /assistants/{id}/versions row (limit default 10 max 100 clamped / offset / ordering exemption: version ASC — deviates from created_at DESC default); BC-2.12.002 PC20 added as anchor. OBS-P32-1 add no-list-schedules note in §Cron Schedules."
  - "2.8 (ADV-P1D-PASS-49): F-P49-02 — add RunnableConfig recursion_limit dual-interpretation note (§Runnable trait); add E-GRAPH-017 (GraphRecursionLimitExceeded, POLICY — BC-2.03.001 PC5) to the graph execution errors embedded-in-Run.error blockquote. No HTTP status table row change (E-GRAPH-017 surfaces embedded in Run.error, never as a direct terminal HTTP status; POLICY→403 categorical fallback applies only if ever surfaced directly — not in v1)."
  - "2.9 (ADV-P1D-PASS-55): F-P55-01 — add E-SERVER-013 (InvalidDebugRouteKey, VAL — BC-2.12.005 EC-005/TV-007) startup-only omission note; raised at boot before any HTTP listener is bound, never surfaced as a terminal HTTP response (same treatment as E-CHKPT-005). Full disposition census: 75 live codes — 43 HTTP table rows, 9 explicit individual omission notes, 23 blanket library-layer coverage, 0 uncovered."
  - "2.10 (ADV-P1D-PASS-56): F-P56-01 — add E-CORE-006 (RecursionLimitExceeded, INTERNAL — BC-2.01.003 PC5) to dual-layer table Runnable-layer row; add E-CORE-006 individual omission note (INTERNAL, library-layer Err return, never direct HTTP response in v1; INTERNAL→500 categorical fallback). OBS-P56-1 resolved: tighten 10007 text in dual-layer note to cite `DEFAULT_RECURSION_LIMIT` constant in `langgraph._internal._config` (reads from `LANGGRAPH_DEFAULT_RECURSION_LIMIT` env var) and distinguish from langchain-core `DEFAULT_RECURSION_LIMIT = 25`. Disposition census 75→76: 43 HTTP table rows, 10 individual omission notes (+E-CORE-006), 23 blanket library-layer coverage, 0 uncovered."
  - "2.11 (ADV-P1D-PASS-56-COMPLETION): Gate #30 drain — three new codes from error-taxonomy.md v1.8. (1) E-PROV-008 (ProviderHttpError, TRANSPORT) added to 502 row alongside E-PROV-003 — categorical fallback, surfaced embedded in Run.error. (2) E-CHKPT-007 (CipherHeaderMissing, INTERNAL) added to 500 row alongside other CHKPT INTERNAL codes. (3) E-CORE-007 (GuardrailHookPanic, INTERNAL) individual omission note added — library-layer INTERNAL error, never direct HTTP terminal in v1; INTERNAL→500 categorical fallback. Disposition census 76→79: 45 HTTP table rows (+E-PROV-008 +E-CHKPT-007), 11 individual omission notes (+E-CORE-007), 23 blanket library-layer coverage, 0 uncovered."
  - "2.12 (ADV-P1D-PASS-57): F-P57-01 (HIGH) — fix GuardrailHook trait signature trilateral contradiction (authority-deference D18-P47-A: BCs win). (1) Method name on_ingress → evaluate (all 6 ss-11 BC postconditions + E-CORE-007 taxonomy message are uniform). (2) Return type Result<IngressContent, GuardrailError> → GuardrailResult enum with Pass / Fail{reason,severity} / Transform{new_content} variants (BC-2.11.002 PC2-PC4). (3) Second parameter renamed provenance → provenance_tag per BC-2.11.002 INV-4. (4) GuardrailResult enum definition added to §GuardrailHook block with Fail/Transform variant bodies. (5) Panic path moved to doc-comment citing E-CORE-007 and BC-2.11.002 EC-001 (panic is a non-return code path; the trait method return type is GuardrailResult not Result). (6) GuardrailError type removed — not defined in spec corpus; was incorrect. BC anchor enumeration expanded to cite all 6 BCs by role."
  - "2.13 (ADV-P1D-PASS-58): F-P58-02 (HIGH) + F-P58-01 (MED) — define IngressContent and GuardrailSeverity inline in §GuardrailHook block. (1) IngressContent enum: ToolResult(ContentBlock) / RagChunk(Value) / MemoryItem(Value) — BC-2.11.002 PC1 / BC-2.11.003 PC1,PC5 / BC-2.11.004 PC1,PC5; E-CORE-007 content_type placeholder resolved to IngressContent variant name. (2) GuardrailSeverity enum: Critical/High/Medium/Low — authority BC-2.11.002 INV-3, BC-2.11.005 PC4/PC5. (3) Minimal type notes added for ChatConfig (BaseChatModel) and CheckpointConfig (CheckpointSaver) per gate #31 census — both flagged corpus-unresolved for architect. Gate #31 census: 20/22 types resolved; ChatConfig and CheckpointConfig flagged."
  - "2.14 (ADV-P1D-PASS-59): F-P59-01 (HIGH) — fix GuardrailSeverity::Critical authority mis-citations. BC-2.11.003 INV-2 (ordering invariant) → BC-2.11.003 PC3 (Critical severity rule); BC-2.11.004 INV-4 (ordering invariant) → BC-2.11.004 PC3 (Critical severity rule). Correct authority: BC-2.11.002 INV-3, BC-2.11.003 PC3, BC-2.11.004 PC3, BC-2.11.005 PC4. F-P59-02 (HIGH) — fix Transform doc-comment cross-boundary claim: replace 'any IngressContent variant, including a different variant from the original' with same-boundary rule (new_content must be same IngressContent variant; inner payload may change freely — e.g. different ContentBlock variant within ToolResult per BC-2.11.002 EC-003). No BC authorizes cross-boundary transforms (e.g. ToolResult→RagChunk)."
  - "2.15 (ADV-P1D-PASS-60): F-P60-01 (HIGH) + F-P60-02 (MED) + F-P60-03 (HIGH) — rewrite §BudgetPolicy block per orchestrator adjudication D18-P60-A (authority-deference: BC-2.10.001–004 are behavioral authority). (1) Rename BudgetDecision → PolicyDecision (BC-2.10.001 PC3 — three-variant contract is the canonical name); BudgetDecision retired per gate #19. (2) Add current_usage: TokenUsage payload to Escalate and Deny variants (BC-2.10.001 PC3, TV-002, TV-003 — F-P60-02). (3) Rewrite evaluate signature: remove async (pure/sync per BC-2.10.001 INV + ADR-009); remove run_id param; remove journal param (journal writes are caller responsibility per BC-2.10.001 INV + ADR-009); add context: &BudgetContext second param (BC-2.10.001 PC1/PC2 two-param canon) — F-P60-03. (4) BudgetContext flagged implementer-scope (shape not enumerated in spec corpus; BC-2.10.001 PC3/INV provides contextual description — same treatment as ChatConfig). (5) BC anchors corrected: BC-2.10.001 PC3 + TV-001–TV-003 + BC-2.10.002 INV."
  - "2.16 (ADV-P1D-PASS-61): F-P61-02 (MED) + F-P61-01 (HIGH, partial) — §BudgetPolicy context param corrected per orchestrator canon D18-P61-A. (1) Rename context param &BudgetContext → &RunContext: BC-2.10.001 precondition 3 names RunContext (thread_id, run_id, sub-agent identity) as the context type; BudgetContext was minted without corpus search (gate #31 near-name blindspot); BudgetContext RETIRED per gate #19. (2) RunContext implementer-scope note replaced with RESOLVED note: precondition 3 fully enumerates fields (thread_id, run_id, sub-agent identity) → RunContext is RESOLVED, not implementer-scope. Citation corrected: BC-2.10.001 precondition 3 (NOT PC3/INV — those sections describe PolicyDecision and purity, not context contents). (3) BC anchor note updated: precondition 3 authority added."
  - "2.17 (ADV-P1D-PASS-66): F-P66-03 — remove E-SERVER-005 (CorsRejected, POLICY) from 403 row; code RETIRED (tombstone in error-taxonomy.md v1.9). BC-2.12.005 PC2/TV-001 specifies CORS denial as silent header-omission — no error body is ever emitted; listing E-SERVER-005 in the 403 row misled implementers toward building explicit CORS error bodies. 403 row description updated to remove 'CORS'. E-PROV-007 omission note updated to remove E-SERVER-005 from the list of direct-403 codes. Disposition census 79→78: 44 HTTP table rows (−E-SERVER-005), 11 individual omission notes, 23 blanket library-layer coverage, 0 uncovered. Gates #20 POLICY census + gate #21 §17-C re-run: all remaining POLICY codes correctly mapped (E-SERVER-004 → 403 direct; E-GRAPH-013 → 403 direct; others library-layer or per-endpoint overrides). PASS."
  - "2.18 (ADV-P1D-PASS-67): F-P67-01 — fix 422 row cross-reference enumeration: DURABILITY/INTERNAL E-CHKPT codes listed as routed to the 500 row omitted E-CHKPT-007 (CipherHeaderMissing, INTERNAL), which IS in the 500 row. Enumeration corrected from (E-CHKPT-001, -002, -003, -004, -006) to (E-CHKPT-001, -002, -003, -004, -006, -007). Gate #21 cross-row routing-enumeration completeness sub-check applied — all inter-row enumerations verified. Disposition census unchanged: 44 HTTP table rows, 11 individual omission notes, 23 blanket library-layer coverage, 0 uncovered."
  - "2.21 (D20 TOUCH-UP burst): Residue 1 — §BudgetPolicy RunContext inline note updated: added field `budget_info: Option<BudgetInfo>` (BC-2.10.003 v1.2 PC5/INV); `BudgetInfo` struct defined inline with fields `tokens_remaining: Option<i64>` and `steps_remaining: Option<u32>` (gate #31 RESOLVED). BC anchor updated to cite BC-2.10.003. Disposition census unchanged: 43 HTTP table rows, 16 individual omission notes, 26 blanket library-layer coverage entries = 85. CORRIGENDUM (Residue 2): This document's split (43 HTTP + 16 individual + 26 blanket = 85) is the verified correct partition; error-taxonomy.md v1.11 erroneously stated 44 HTTP + 15 individual + 26 blanket = 85 — the split error arose because the E-CORE-004 move (HTTP table → individual omission note, interface-definitions.md v2.19) was not reflected in error-taxonomy.md v1.10 census; corrected in error-taxonomy.md v1.12."
  - "2.22 (pass-72 fix, 2026-07-15): F-P72-01 + F-P72-06 — fix SkillStore trait signatures to BC/ADR-authoritative name-keyed + tag-filtered forms (load_skill/skill_exists take name: &str; list_skills takes tags: &[String]) per BC-2.15.004 PC1-PC3 + ADR-012 Decision 1 Primitive A; name→(namespace,key) storage mapping is impl-internal (BC-2.15.004 Invariant). Fix Replace.old_value from Value to Option<Value> per ADR-012 Decision 1 Primitive C (None=unconditional replace; Some(v)=match-based replace) + BC-2.15.005 PC2. Gate #31 SkillStore row stays RESOLVED with corrected shapes; MemoryWriteRequest RESOLVED note unchanged (variant structure correct, type corrected). D18-P72-A + D18-P72-B adjudicated."
  - "2.20 (D20 INTEGRATE sub-burst 2): Four new §Public Rust Trait Signatures added: §ToolCallDialect (BC-2.08.013 — object-safe dialect seam for tool-call serialization; built-ins NativeOpenAiJson/NativeAnthropic/HermesChatMlXml), §ProviderFallbackPolicy (BC-2.08.014 — ordered fallback chain struct; ProviderCredential/CredentialRefreshConfig flagged UNRESOLVED implementer-scope for architect), §SkillStore (BC-2.15.004 — async trait with SkillDescriptor inline struct), §MemoryWriteGuard (BC-2.15.005 — pure sync guard with MemoryWriteRequest + WriteGuardDecision inline enums). Blanket omission MEMORY annotation: VAL/POLICY/DURABILITY → VAL/POLICY/DURABILITY/SECURITY (+E-MEMORY-007 SECURITY). Four individual omission notes added: E-CHKPT-008 (VAL), E-CHKPT-009 (INTERNAL), E-PROV-009 (VAL), E-PROV-010 (POLICY) — all library-layer Err, never direct HTTP terminal. Gate #31 census: 19/21 → 25/28 resolved (+ToolCall, SkillDescriptor, MemoryWriteRequest, WriteGuardDecision all RESOLVED; ProviderCredential, CredentialRefreshConfig UNRESOLVED). Disposition census 78→85: 43 HTTP table rows, 16 individual omission notes (+4), 26 blanket library-layer coverage entries (+3: E-MCP-005 in MCP blanket, E-SBXD-006 in SBXD blanket, E-MEMORY-007 in MEMORY blanket)."
  - "2.19 (ADV-P1D-PASS-69): F-P69-01 — fix 400 row range-shorthand category mismatch: 'E-CORE-001 through E-CORE-005' silently included E-CORE-004 (INTERNAL, not VAL). (1) 400 row: range replaced with explicit VAL enumeration 'E-CORE-001, E-CORE-002, E-CORE-003, E-CORE-005' — each verified VAL in error-taxonomy.md (lines 68-70, 72). (2) E-CORE-004 (INTERNAL — BC-2.01.004 PC5, pipe-composition type-boundary mismatch) given individual omission note mirroring E-CORE-006/E-CORE-007 (library-layer Err return, never direct HTTP terminal; INTERNAL→500 categorical fallback). (3) Range sweep: 'E-CORE-001 through E-CORE-005' was the only range expression in the status table rows — no other ranges found. Disposition census 78→78: 43 HTTP table rows (−E-CORE-004 from 400 row), 12 individual omission notes (+E-CORE-004 library-layer note), 23 blanket library-layer coverage, 0 uncovered."
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
input-hash: "4c7330b"
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
        -> Result<impl Stream<Item = Result<CheckpointTuple, FerrochainError>>, FerrochainError>;
}
```

**BC anchor:** BC-2.04.001 through BC-2.04.006

> **Gate #31 type note — `CheckpointConfig`, `ChannelName`, `ChannelValue`, `TaskId`, `CheckpointTuple`:** `CheckpointConfig` is the checkpoint-addressing config; not formally enumerated as a spec-level struct — logically derived from BC-2.04.006 triple-address invariant (`thread_id: Uuid`, `checkpoint_ns: NamespaceId`, `checkpoint_id: Option<LogicalClockId>`); flagged corpus-unresolved for architect. `ChannelName` and `ChannelValue` are defined in entities-graph.md §GraphState (`Map<ChannelName, ChannelValue>`). `TaskId` is defined in VP-001.md (Kani harness: `TaskId(i as u64)` newtype around u64). `CheckpointTuple` is defined in entities-graph.md §CheckpointTuple.

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
| GET | `/threads/{thread_id}/runs` | List runs for a thread; `?status=queued\|in_progress\|completed\|failed\|interrupted\|cancelled` filter + canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC) — F-P31-01 | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}` | Get run status and result | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}/stream` | Stream run output as server-sent events (SSE; happy path emits run_start, node_start/stream/end, run_end; **run_end is emitted on completion only** — interrupted runs terminate with interrupt envelope as terminal frame, failed runs terminate with error SSE event; neither emits run_end; BC-2.06.001 PC2+EC-005, BC-2.12.007 EC-001/EC-003) | BC-2.12.007 |
| POST | `/threads/{thread_id}/runs/{run_id}/resume` | Deliver resume value to interrupted run | BC-2.05.004 |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | Cancel a queued or in_progress run (transitions to cancelled) | BC-2.12.003 |
| DELETE | `/threads/{thread_id}/runs/{run_id}` | Delete a terminal run record (completed/failed/cancelled only; HTTP 409 if queued, in_progress, or interrupted — cancel or resume-to-complete first) | BC-2.12.003 |

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

> **E-CHKPT-008 library-layer omission (D20 sub-burst 2; raise-timing corrected F-P82-02):** E-CHKPT-008 (FtsLimitZero, VAL) covers two distinct sub-cases with different raise times: **(1) `FtsSearchConfig.limit = 0`** — raised at **`FtsSearchConfig` construction time** (DI-008 construction-result contract; BC-2.04.008 PC6/EC-004); **(2) malformed FTS5 query string** — raised at **`fts_search` call time** when SQLite FTS5 fails to parse the query string passed as the standalone `query: &str` first parameter (SQLite FTS5 parse error propagation; BC-2.04.008 EC-002). Note: `query` is a standalone first parameter to `fts_search`, NOT a field of `FtsSearchConfig`. VAL→400 is the categorical mapping. In v1 both sub-cases surface as a direct `Err(FerrochainError)` return from library code; neither is emitted as a terminal HTTP response by ferrochain-server (no FTS search endpoint in v1; if ever surfaced via server, it would appear embedded in Run.error). Intentionally omitted from the HTTP status table.

> **E-CHKPT-009 library-layer omission (D20 sub-burst 2):** E-CHKPT-009 (Fts5Unavailable, INTERNAL — BC-2.04.008 EC-006) is raised at `CheckpointSaver::new()` construction time when FTS is requested but the SQLite build does not include the FTS5 extension. INTERNAL→500 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from `CheckpointSaver::new()` in library code; it is never emitted as a terminal HTTP response by ferrochain-server (server startup with a bad FTS5 config fails before any listener is bound). Intentionally omitted from the HTTP status table; same treatment as E-CHKPT-005 and E-SERVER-013 (startup-time library errors).

> **E-PROV-009 library-layer omission (D20 sub-burst 2):** E-PROV-009 (ToolCallDialectParseError, VAL — BC-2.08.013 PC8/PC9/EC-002) is raised when `ToolCallDialect::deserialize_tool_calls` fails to parse model-output content. VAL→400 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from the dialect dispatch layer in library code; it propagates as Run.error on the server side (same treatment as E-PROV-005, E-PROV-006). Never a direct HTTP terminal response. Intentionally omitted from the HTTP status table.

> **E-PROV-010 library-layer omission (D20 sub-burst 2):** E-PROV-010 (ProviderChainExhausted, POLICY — BC-2.08.014 PC5/EC-004) is raised when all providers in the `ProviderFallbackPolicy` chain have been tried and all failed. POLICY→403 is the categorical mapping. In v1 this error surfaces as a direct `Err(FerrochainError)` return from the provider dispatch layer in library code; it propagates as Run.error on the server side (same treatment as E-PROV-007 StructuredOutputRefused). Never a direct HTTP terminal response. Intentionally omitted from the HTTP status table.

> **Library/execution-layer codes — blanket omission (OBS-P29-1, ADV-P1D-PASS-29; F-P30-01, ADV-P1D-PASS-30):** All remaining library and execution-layer error codes — E-MCP-* (BC-2.09.x, TOOL/TRANSPORT/VAL), E-SBXD-* (BC-2.13.x, SECURITY/POLICY/INTERNAL), E-RETRY-* (BC-2.16.x, POLICY/VAL), E-BUDGET-* (BC-2.10.x, POLICY/DURABILITY), E-MEMORY-* (BC-2.15.x, VAL/POLICY/DURABILITY/SECURITY), E-SPLIT-* (BC-2.07.x, VAL) — surface embedded in Run.error or as library `Err` return values. None has a direct HTTP row in this table. Categorical fallbacks apply if ever surfaced directly (TOOL→422, TRANSPORT→502, SECURITY→403, POLICY→403, DURABILITY→500, INTERNAL→500, VAL→400) but in v1 these codes are not emitted as terminal HTTP responses by any endpoint. Spot-checked: E-MCP-001 (BC-2.09.004 — embedded in run as tool failure), E-SBXD-001 (BC-2.13.005 — sandbox security violation embedded in run), E-MEMORY-001 (BC-2.15.001 — memory store validation error embedded in run); all confirmed library-layer only.

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
      "enum": ["queued", "in_progress", "interrupted", "completed", "failed", "cancelled"],
      "description": "Run state machine: queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted (resume via POST .../resume). Authority: BC-2.12.003 PC7-PC9. multitask_strategy='enqueue' creates the new run in 'queued' state; it transitions to 'in_progress' after the current run finishes. Use POST .../cancel to transition queued/in_progress→cancelled."
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time", "description": "Set on every Run state mutation (status transition, output/error write). Always present. Authority: BC-2.12.003 PC13." },
    "completed_at": { "type": ["string", "null"], "format": "date-time", "description": "Set only on terminal transition (status → completed | failed | cancelled). Null in all non-terminal states (queued, in_progress, interrupted). Distinct from updated_at — terminal-timestamp semantics. Authority: F-P24-01." },
    "output": { "description": "Final graph state; present only when status=completed" },
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
