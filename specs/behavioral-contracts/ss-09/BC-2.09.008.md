---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.008
version: "3.0"
status: draft
lifecycle_status: draft
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-09
capability: CAP-021
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-29T00:00:00Z
changelog:
  - "1.0 (GAP-01/ADR-029/2026-08-26): Initial — StateGraph-as-MCP-Tool wrapping contract; GraphAgentTool; mcp::graph_tool module in pregolya-mcp; inputSchema derivation via schemars; STATE-ISOLATION invariant {INV-001} (VP-016 proptest P1 proof target); fail-closed DenyInterrupts default; ForceApproveHooks explicit opt-in; E-MCP-010 GraphAgentInterruptDenied (ADR-029 §Decision 5; note: ADR-029 body incorrectly referenced E-MCP-006 — that code is taken by McpContentUnsupported; PO-authoritative mint is E-MCP-010). Human-approved v1 scope addition 2026-08-26 (GAP-01/HS-C-001)."
  - "1.1 (ADR-029-sec-hardening/SEC-006/007/008/005/001/2026-08-26): Security hardening per ADR-029 §Decision 3/4/5. SEC-007: {PC-006} rewritten — ForceApproveHooks overrides ONLY PreToolDecision::PendingHumanApproval (subject to {INV-004} ActionRisk check); PreToolDecision::Deny and other decision variants pass through unchanged; ForceApproveHooks does not override security-based Deny decisions. SEC-006: {INV-004} body replaced — BoundaryApprovalHook enforces read-only restriction at runtime via ActionRisk check; PendingHumanApproval overridden to Approve only when action_risk < ActionRisk::Medium; otherwise Deny + CRITICAL log at mcp.graph_tool.force_approve_write_blocked + E-MCP-011 ForceApproveWriteBlocked; EC-009 and TV-008 added. SEC-005: {INV-001} extended — STATE-ISOLATION guarantee covers error paths; two unconditional sanitization passes applied to isError:true responses (redact_credentials + sanitize_internal_ids UUID v4 removal); node implementations must exclude internal IDs at authoring site; TV-009 added. SEC-001: {INV-005} added — extract_output closure must not select credential-bearing fields; framework does not sanitize success-path extract_output result; caller obligation per DI-010; TV-010 added. SEC-008: EC-010 added — extract_output panic caught via UnwindSafe boundary; static 'internal error' response; server continues serving; TV-011 added."
  - "1.2 (ADR-029-v1.3/F-057-01/F-057-02/F-057-05/2026-08-26): Round-2 security fixes per ADR-029 §Decision 1, §Decision 4 architect adjudication. F-057-01 ({INV-004}): ActionRisk gate is now fail-closed on None — preview.action_risk (Option<ActionRisk> per BC-2.05.007 {PRE-003}) is None (undeclared, fail-closed per BC-2.05.006 EC-004/{INV-002}) OR Some(r >= Medium) → Deny + E-MCP-011; Some(r < Medium) → Approve. EC-009 heading updated to cover both None and Some(High) cases; TV-012 added for the None/undeclared path; note that both None and Some(High) must be tested. F-057-01 ({PC-006}): None case appended — None (undeclared) fails closed to Deny identically to Some(>= Medium), consistent with BC-2.05.006 EC-004/{INV-002}. F-057-02 ({PC-005}): BoundaryApprovalHook::Deny sub-bullet corrected — graph CONTINUES executing after Deny; if valid terminal reached, {PC-004} applies (Ok); if error terminal reached, Err carries graph's OWN error (NOT E-MCP-010); closing sentence 'In both cases invoke_dyn returns Err(E-MCP-010)' removed. F-057-02 ({INV-002}): binary interrupt invariant scoped to node-level interrupt() parking (RunStatus::Interrupted) only; BoundaryApprovalHook::Deny path explicitly excluded (graph continues to own terminal). EC-005 is the authority for the Deny-path behavior and was already correct — {PC-005} and {INV-002} reconciled to match EC-005. F-057-05: §Story Anchor set to S-2.11 (sibling BCs BC-2.09.006/007 both anchor S-2.11; S-2.11 covers BC-2.09.008)."
  - "1.3 (P2A-058/F-058-02/F-058-06/2026-08-26): F-058-02: E-MCP-010 ForceApproveHooks recovery clause dropped from {PC-005} and EC-004 message strings — node-level interrupt() fires E-MCP-010 under ForceApproveHooks identically to DenyInterrupts; ForceApproveHooks cannot resolve E-MCP-010 (interrupt() parking is orthogonal to tool approval policy); corrected remedy: restructure the graph so it does not call interrupt() during a synchronous tools/call invocation. F-058-06 (records): changelog v1.2 citation corrected from §Decision-1/§Decision-4 to §Decision 1, §Decision 4 per ADR-022 §Decision 5 citation conventions."
  - "1.4 (round-5/F-P2A-061-02+LOW-schemars+LOW-citation/2026-08-26): F-P2A-061-02 [MED]: E-MCP-011 ForceApproveWriteBlocked added to Traceability Error Codes row ({INV-004}/EC-009 anchor). LOW (schemars): {PC-001} 'RootSchema' → 'schemars::Schema' (schemars 1.0 canonical; architect fixes ADR-029 separately). LOW (citation): {INV-004}, {PC-006}, EC-009 citations of 'BC-2.05.006 EC-004/{INV-002}' reworded corroborative — None→Deny behavior is fully specified by {INV-004}; BC-2.05.006 cited for fail-closed principle consistency only."
  - "1.5 (round-7/F-P2A066-01/2026-08-26): Canonical seam wording appended per ADR-029 §Decision 3. {PC-004}: note appended — GraphRunner::run is the sole site where extract_output(&final_state) is called before the filtered serde_json::Value is returned; GraphAgentTool::invoke_dyn wraps the already-filtered result without re-filtering. {INV-001}: note appended — extract_output closure is called solely within GraphRunner::run, not within invoke_dyn; invoke_dyn wraps the result from run() without additional processing."
  - "1.6 (round-8/F-P2A069-02+F-P2A070-02/2026-08-26): F-P2A069-02 ({PC-003}): deserialization-location corrected per ADR-029 §Decision 2 — `serde_json::from_value::<S>(arguments)` runs inside `ConcreteGraphRunner<S>::run` (where `S` is statically known), not inside `invoke_dyn` (which erases `S` behind `Arc<dyn GraphRunner>`); `GraphRunner::run` returns the `Err`; `invoke_dyn` propagates it; routing unchanged (`isError: true`, NOT JSON-RPC -32602). F-P2A070-02 (POL-20): removed story-schema frontmatter fields `behavioral_contracts:` and `verification_properties:` — these are STORY-schema keys that no other of the 134 BCs carries; VP-016 traceability is preserved via §VP Anchors and VP-016.md `source_bc: BC-2.09.008`."
  - "1.7 (round-10/GAP-01-type-grounding/2026-08-27): Type-grounding reconciliation per ADR-029 §Symbol Grounding / BC-2.02.001 {PC-001}/{PC-005} (architect symbol-existence audit). {PRE-001}: `Arc<CompiledGraph<S>>` (generic) → `Arc<CompiledStateGraph>` (non-generic; `pregolya-graph/src/types.rs`; BC-2.02.001 {PC-001}); caller-supplied `input_schema: schemars::Schema` parameter added (derived via `schemars::schema_for!(StateType)` at call site). {PRE-002}: extract_output closure type `Fn(&S) -> serde_json::Value` → `Fn(&serde_json::Value) -> serde_json::Value` (S erased). {PC-001}: constructor signature updated to `from_graph(name, description, graph, input_schema, extract_output)`; schema derivation moved from `schemars::schema_for!(S)` at construction to caller-provided `input_schema`. {PC-003}: `serde_json::from_value::<S>` deserialization path eliminated — `CompiledStateGraph::invoke` takes `serde_json::Value` directly (BC-2.02.001 {PC-005}); error path is now: `CompiledStateGraph::invoke` returns `Err(PregolyaError)` → `isError: true`. {PC-004}: return type corrected `Ok(ToolOutput::Structured { value: extract_output_result })` → `Ok(extract_output_result)` where `extract_output_result: serde_json::Value`. {PC-005} BoundaryApprovalHook Deny sub-bullet: `Ok(ToolOutput::Structured)` → `invoke_dyn returns Ok(serde_json::Value from extract_output_result)`. {INV-002} terminal bullet: `Ok(ToolOutput::Structured { value: extract_output_result })` → `invoke_dyn returns Ok(serde_json::Value)`. EC-002: retitled and rewritten — `serde_json::from_value::<S>` path no longer exists; graph-level value errors surface via EC-003. EC-007: `ToolOutput::Structured { value: json!(...) }` → `invoke_dyn returns Ok(json!(...))`. EC-008: `ToolOutput::Structured { value: Value::Null }` → `invoke_dyn returns Ok(Value::Null)`. §Description: inputSchema derivation note updated. §VP-016 table: `ToolOutput` and `S instances` wording updated. §Architecture Anchors: `CompiledGraph<S>` → `CompiledStateGraph`. Zero residual `ToolOutput::Structured`, `CompiledGraph<`, `from_value::<S>`, `S: GraphState` in file post-edit."
  - "1.8 (round-12/GAP-01-type-grounding/2026-08-27): Remaining type-grounding propagation. EC-007: scenario prose re-grounded — typed-struct `GraphState S` fields replaced by channel-composed `serde_json::Value` key description; `extract_output` closure updated from `|s: &S| json!({ \"answer\": s.answer })` to `|s: &serde_json::Value| json!({ \"answer\": s[\"answer\"] })`. TV-001: closure updated from `|s| json!({\"result\": s.result})` to `|s: &serde_json::Value| json!({\"result\": s[\"result\"]})`. TV-010: closure updated from `|s: &S| json!({ \"api_key\": s.api_key })` to `|s: &serde_json::Value| json!({ \"api_key\": s[\"api_key\"] })`. {INV-005}: 'credential-bearing fields of `GraphState S`' → 'credential-bearing keys of the returned `serde_json::Value`'. Traceability CAJ: `StateGraph<S>` → `StateGraph` (non-generic). Zero residual `|s: &S|`, `s.answer`, `s.result`, `s.api_key`, `StateGraph<S>` in live body."
  - "1.9 (round-14/type-grounding-propagation/2026-08-27): §Description and Traceability CAJ: 'compiled `StateGraph`' / '`StateGraph`' → `CompiledStateGraph` (concrete non-generic Rust type per {PRE-001}; description and CAJ now use the same concrete type as the preconditions)."
  - "2.0 (round-19/F-P2A087-02+F-P2A088-01/2026-08-27): F-P2A087-02 [HIGH]: {PC-005} and EC-005 phantom-path corrected — `PreToolCallHook::PendingHumanApproval` → `PreToolDecision::PendingHumanApproval` at both live-body sites ({PC-005} sub-bullet heading, EC-005 scenario); `PendingHumanApproval` is a variant of `PreToolDecision` per BC-2.05.007 canonical H1 (Approve/Deny/Edit/PendingHumanApproval); `PreToolCallHook` has no `PendingHumanApproval` item — its only method is `pre_invoke`. F-P2A088-01 [MED/CWE-209/CWE-670]: {INV-001} error-path sanitizer-scope corrected per ADR-029 §Decision 3 / SEC-005 canonical text (verbatim mirror); incoherent '(UUID v4 format)' over-claim over checkpoint IDs removed — `CheckpointId` is a `u64` newtype (ADR-005 / BC-2.04.003), not UUID-shaped; `sanitize_internal_ids` regex covers UUID-shaped identifiers only; `u64` CheckpointId and arbitrary-string `thread_id` are NOT covered by the framework pass; authoring-site convention is their SOLE framework guarantee. TV-013 added: `u64` checkpoint ID in error message is NOT stripped by `sanitize_internal_ids` (not UUID-shaped); authoring-site convention ({INV-001}) is the sole protection boundary for `u64` IDs (CWE-670/CWE-209 test coverage)."
  - "2.1 (round-21/F-P2A094-01/F-P2A094-02/2026-08-28): F-P2A094-01 [MED]: {INV-001} server-layer thread_id characterization corrected per ADR-029 §Decision 3/SEC-005 v2.5 canonical mirror. REMOVED: 'arbitrary-string server-layer thread_id values (user-supplied strings; not guaranteed UUID-shaped) are NOT covered by the framework sanitize_internal_ids pass' — server-layer thread_id IS a Uuid (entities-server.md §Thread, §Run; §RunnableConfig thread_id: Option<Uuid>); sanitize_internal_ids UUID regex covers run_id (Uuid) AND server-layer thread_id (Uuid) identically. Authoring-site convention SOLE-guarantee now scoped exclusively to u64 CheckpointId (ADR-005 / BC-2.04.003 — not UUID-shaped; UUID regex cannot match it). Note added: FtsSearchConfig.thread_id: Option<&str> is an FTS query-filter parameter and never reaches a GraphAgentTool error-message path; it is outside this invariant's scope. TV-013 (u64-checkpoint exclusion test vector) remains valid and UNCHANGED. F-P2A094-02 [MED]: EC-010 description and TV-011 notes updated — panic-recovery mechanism is futures::future::FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy))) inside GraphAgentTool::invoke_dyn (async future catch during .await polling; a synchronous std::panic::catch_unwind around future-construction cannot catch it). SEC-008 build-profile invariant added: panic = 'abort' release profile voids the catch and causes process termination (remote DoS, CWE-248); pregolya-mcp release profile MUST pin panic = 'unwind' — devops asserts at Phase-3 workspace Cargo.toml authoring."
  - "2.2 (round-22/F-P2A098-01+F-P2A098-02/2026-08-28): F-P2A098-01 [MED]: {INV-001} §Framework sanitization pass scope — §RunnableConfig doc attribution corrected; §RunnableConfig is defined in interface-definitions.md §RunnableConfig (not entities-server.md); prior semicolon grouping '...§Thread, §Run; §RunnableConfig' replaced with explicit '...§Thread, §Run and interface-definitions.md §RunnableConfig (`thread_id: Option<Uuid>`)' attribution per ADR-029 §Decision 3 and §Decision 4 source-of-truth; no sanitizer-scope semantic change. F-P2A098-02 [LOW/records]: changelog v2.0 and v2.1 §Decision 3 hyphen-form citations corrected to space form per ADR-022 §Decision 5 citation convention."
  - "2.3 (round-23/O-P2A102-03/2026-08-28): O-P2A102-03 [LOW/records]: v2.2 changelog double-§ citation corrected — 'per ADR-029 §Decision 3 §Decision 4 source-of-truth' reworded to 'per ADR-029 §Decision 3 and §Decision 4 source-of-truth' per ADR-022 §Decision 5 no-chained-§ rule."
  - "2.4 (round-25/O-P2A111-08+O-P2A111-07/2026-08-28): O-P2A111-08 [OBS] — {INV-004} and EC-009: 'CRITICAL-level structured log' corrected to 'ERROR-level (highest severity) structured log (tracing::error!)'; Rust tracing crate has no CRITICAL level (levels are error/warn/info/debug/trace); ERROR is the highest severity; observability.md concretizes the intended level as tracing::error!. TV-008 and TV-012 'CRITICAL log' aligned to same terminology for consistency. O-P2A111-07 [OBS] — §Canonical Test Vectors: TV-012 moved to ascending-numeric position after TV-011 (was out-of-sequence between TV-008 and TV-009); append-only IDs preserved, ordering only."
  - "2.5 (round-26/P2A-113-OBS+POL-24-sibling-consistency/2026-08-28): P2A-113 [OBS] — {INV-001} `sanitize_internal_ids` UUID regex note updated: pattern is applied case-insensitively (consistent with S-2.11 Task-35 which mandates the case-insensitive flag). POL-24 — §Architecture Anchors registry.rs bullet annotated with `(mcp::registry standalone module, SS-09)` for sibling consistency with BC-2.09.006 §Architecture-Anchors (architect OPTION A: mcp::registry is a standalone module registered in module-decomposition and module-criticality)."
  - "2.6 (round-28/F-P2A121-01+O-P2A121-02/2026-08-28): F-P2A121-01 [MED, CWE-670/CWE-209]: {INV-001} §Framework sanitization pass scope extended to two-pattern union — added pattern (2) simple no-hyphen form `\\b[0-9a-f]{32}\\b` to cover `Uuid::simple()` rendering (32 contiguous hex digits); pattern (1) canonical hyphenated form retained; the `\\b` word-boundary prevents over-matching 64-char SHA-256 digests and hex sequences flanked by underscores; together the two patterns cover all standard uuid-crate rendering forms. Three new test vectors appended (append-only per POL-1): TV-014 (POSITIVE — simple-form run_id stripped), TV-015 (NEGATIVE — 64-char hex digest passes through unchanged), TV-016 (NEGATIVE — simple UUID flanked by underscores passes through unchanged). O-P2A121-02 [LOW/records]: Traceability §Error Codes row E-MCP-010 note reworded to past-tense draft-history framing — present-tense 'ADR-029 body incorrectly referenced' replaced with 'the initial ADR-029 draft cited ... corrected to E-MCP-010 in ADR-029 §Changelog'."
  - "2.7 (round-30/F-P2A129-01/2026-08-28): F-P2A129-01 [MED, CWE-209/spec-contradiction]: TV-015 full-pipeline expected output corrected. The mandatory pipeline (`sanitize_internal_ids(redact_credentials(message))` per ADR-029 §Decision 3 and Decision 5) applies `redact_credentials` FIRST; its rule `[A-Za-z0-9]{64,}` matches a 64-char lowercase hex SHA-256 digest token → `<redacted>`; `sanitize_internal_ids` then sees no UUID pattern in the already-redacted message. TV-015 corrected from 'content[0].text contains 64-char hex UNCHANGED' to `\"digest: <redacted>\"` (full-pipeline output). TV-017 added (append-only per POL-1): `sanitize_internal_ids` unit-isolation test — documents that pattern (2) `\\b[0-9a-f]{32}\\b` does NOT independently match a 64-char hex sequence (the `\\b` end-boundary guard; tests the non-over-match property at the correct isolation layer, not the full pipeline). {INV-001} §Framework sanitization pass scope: pipeline-interaction note added after the `\\b` non-over-match sentence — clarifies that in the full pipeline `redact_credentials` catches a 64-char lowercase hex token before `sanitize_internal_ids` runs (see TV-017 for unit-isolation test). OPTION CHOSEN: (b) — correct TV-015 as full-pipeline vector AND add TV-017 as isolation vector; provides complete coverage at both layers; story-writer to propagate TV-015/TV-017 reference updates to S-2.11 Task-35 body under bc_array_changes_propagate_to_body_and_acs. Architect note: ADR-029 §Decision 3 and Decision 5 already specify the chain; no ADR change required."
  - "2.8 (round-35/F-P2A151-01/2026-08-29): F-P2A151-01 [MED]: {PC-004} opening clause call-direction inversion corrected per ADR-029 §Decision 2 and §Decision 5 canonical seam. OLD opening: 'CompiledStateGraph::invoke runs the graph to a terminal state via GraphRunner::run, which calls extract_output(&final_state)' — inverted containment (made CompiledStateGraph::invoke the outer caller of GraphRunner::run). NEW opening: 'GraphRunner::run runs the graph to a terminal state via CompiledStateGraph::invoke, then calls extract_output(&final_state) on the returned serde_json::Value' — correct containment: invoke_dyn wraps GraphRunner::run which wraps CompiledStateGraph::invoke; extract_output is called inside GraphRunner::run on the value returned by CompiledStateGraph::invoke. Trailing note and all return-type semantics preserved unchanged. POL-24 sibling sweep: BC-2.09.006 and BC-2.09.007 contain no GraphRunner/CompiledStateGraph::invoke direction statements (BC-2.09.006 covers tools/list only; BC-2.09.007 covers invoke_dyn→DynTool seam only; neither references the internal graph execution containment); no sibling fixes required."
  - "2.9 (round-36/F-P2A155-01/2026-08-29): F-P2A155-01 [MED]: {PC-003} call-direction seam-collapse corrected. OLD text stated `GraphAgentTool::invoke_dyn` calls `CompiledStateGraph::invoke(arguments, config)` directly — collapsing the 3-layer seam. NEW text: `invoke_dyn` delegates to `runner.run(arguments, policy)` via `Arc<dyn GraphRunner>`; `GraphRunner::run` calls `CompiledStateGraph::invoke(arguments, config)` internally (statically in `ConcreteGraphRunner<S>::run`); error propagates through `run()` and `invoke_dyn` surfaces it as `isError: true`. Exhaustive call-direction sweep of all PC/INV/EC/TV clauses: {PC-003} was the ONLY seam-collapse; {PC-004}/{INV-001} correctly state GraphRunner::run wraps CompiledStateGraph::invoke and invoke_dyn wraps run(); {PC-005} correctly states GraphRunner::run detects RunStatus::Interrupted; all EC/TV clauses state correct layering. No sibling sweep required (BC-2.09.006 and BC-2.09.007 confirmed clean in round-35 sweep)."
  - "3.0 (round-37/O-P2A157-01/2026-08-29): O-P2A157-01 [OBS] — {INV-003}: invariant-strength phrasing brought to symmetric MUST-language consistent with sibling invariants {INV-001}/{INV-002}/{INV-004}. Descriptive 'pass through ... before' replaced with imperative 'MUST pass through'; 'Only ... is used' replaced with 'Only ... MUST be used / MUST NOT be used'; trailing 'This obligation is unconditional per ...' qualifier condensed into parenthetical per symmetric pattern. No semantic change — existing behavior mandate is preserved exactly."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-021
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-029-graph-agent-tool-wrapping.md
input-hash: "a175f88"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.09.008: StateGraph-as-MCP-Tool Wrapping (GraphAgentTool; mcp::graph_tool)

## Description

`GraphAgentTool` (in `mcp::graph_tool`, `pregolya-mcp`) wraps a `CompiledStateGraph`
as a `DynTool` so that it can be registered in the `ToolRegistry` and exposed to external
MCP clients via the existing `tools/list` advertisement (BC-2.09.006) and `tools/call`
execution (BC-2.09.007) paths. The contract specifies three surfaces: (1) construction —
the caller passes an explicit `input_schema: schemars::Schema` (derived via
`schemars::schema_for!(StateType)` at the call site) to `from_graph`; (2) output
isolation — the caller-supplied `extract_output` closure is the ONLY path through which
data exits the graph run (STATE-ISOLATION invariant {INV-001}); (3) interrupt policy —
`GraphToolApprovalPolicy::DenyInterrupts` (default, fail-closed) converts any internal
graph interrupt to `Err(E-MCP-010)`; `ForceApproveHooks` is an explicit opt-in that
overrides `PreToolCallHook` approval decisions only.

## Preconditions

1. {PRE-001} A compiled graph is available as `Arc<CompiledStateGraph>` (non-generic;
   `pregolya-graph/src/types.rs`; BC-2.02.001 {PC-001}). The caller also provides an explicit
   `input_schema: schemars::Schema` parameter derived via `schemars::schema_for!(StateType)`
   at the call site.
2. {PRE-002} The caller provides an `extract_output: Fn(&serde_json::Value) -> serde_json::Value + Send + Sync + 'static`
   closure that selects the fields of the final graph state (as a `serde_json::Value`) to
   expose to external MCP clients. The closure is the STATE-ISOLATION boundary; fields NOT
   selected by the closure are structurally excluded from the output.
3. {PRE-003} The caller provides a stable `name: impl Into<String>` and a `description: impl Into<String>`
   for the tool advertisement; `name` is the public MCP tool name and must be unique within
   the `ToolRegistry` it is registered in (BC-2.08.010 `DuplicateToolName` constraint).

## Postconditions

1. {PC-001} `GraphAgentTool::from_graph(name, description, graph, input_schema, extract_output)` constructs
   a `GraphAgentTool`. The `input_schema: schemars::Schema` passed by the caller (derived via
   `schemars::schema_for!(StateType)` at the call site) is stored internally and returned by
   `DynTool::schema()` for advertisement in `tools/list` responses per BC-2.09.006 {PC-002}.
2. {PC-002} The constructed `GraphAgentTool` implements `DynTool` (object-safe dispatch
   seam per ADR-005 §Adjacent Trait Object-Safety Adjudications) and may be registered in
   a `ToolRegistry` via the standard registration API. After registration, the MCP server
   advertises the tool in `tools/list` responses per BC-2.09.006 {PC-002} — name,
   description, and inputSchema are exposed verbatim from the `GraphAgentTool` fields.
3. {PC-003} On `tools/call` invocation: the `mcp::server` validates the call arguments
   against `DynTool::schema()` per BC-2.09.007 {PC-005}; if validation fails, the server
   returns JSON-RPC `-32602` ("Invalid arguments for tool '...': <schema_error>") before
   `invoke_dyn` is called. If schema validation passes, `GraphAgentTool::invoke_dyn` delegates
   to `runner.run(arguments, policy)` via `Arc<dyn GraphRunner>`; `GraphRunner::run`
   (`ConcreteGraphRunner<S>::run` at the concrete layer, where `S` is statically known) calls
   `CompiledStateGraph::invoke(arguments, config)` internally — which takes `serde_json::Value`
   directly (BC-2.02.001 {PC-005}); there is no separate type-parameterized deserialization step.
   If `CompiledStateGraph::invoke` returns `Err(PregolyaError { .. })`, the error propagates
   through `GraphRunner::run`; `invoke_dyn` surfaces it; the server surfaces this as `isError: true`
   per BC-2.09.007 {PC-003}; credential redaction applies per {INV-003}.
4. {PC-004} On successful graph execution: `GraphRunner::run` runs the graph to a terminal
   state via `CompiledStateGraph::invoke`, then calls `extract_output(&final_state)` on the
   returned `serde_json::Value` and returns ONLY that extracted `serde_json::Value`.
   `GraphAgentTool::invoke_dyn` returns
   `Ok(extract_output_result)` where `extract_output_result: serde_json::Value`.
   The server serializes this per BC-2.09.007 {PC-002} (`result_text =
   serde_json::to_string(&extract_output_result)`). If `extract_output` returns
   `Value::Null`, `result_text = "null"` per BC-2.09.007 {PC-002}; no error raised.
   Note: `GraphRunner::run` is the sole site where `extract_output(&final_state)` is called
   before the filtered `serde_json::Value` is returned; `GraphAgentTool::invoke_dyn` wraps
   the result without re-filtering (ADR-029 §Decision 3 canonical seam statement).
5. {PC-005} On graph interrupt under `GraphToolApprovalPolicy::DenyInterrupts` (default):
   - **Node-level `interrupt()`:** `GraphRunner::run` detects `RunStatus::Interrupted` and
     returns `Err(PregolyaError { code: "E-MCP-010", category: EXEC, message: "graph agent
     tool invocation interrupted at MCP boundary: HITL approval not supported for synchronous
     tools/call; restructure the graph so it does not call interrupt() during a synchronous
     tools/call invocation", retry_hint: Never, .. })`.
     The interrupted run is NOT persisted to durable checkpoint.
   - **`PreToolDecision::PendingHumanApproval`:** `BoundaryApprovalHook` converts
     `PendingHumanApproval` → `Deny`; the tool is not invoked; the graph CONTINUES executing.
     If the graph reaches a valid terminal state, {PC-004} applies (`invoke_dyn` returns
     `Ok(serde_json::Value)` from `extract_output_result`). If the graph reaches an error terminal,
     `GraphRunner::run` returns `Err(PregolyaError)` with the graph's OWN error (NOT
     `E-MCP-010`). `E-MCP-010` is NOT raised on the `BoundaryApprovalHook::Deny` path.
6. {PC-006} Under `GraphToolApprovalPolicy::ForceApproveHooks`: `BoundaryApprovalHook`
   overrides ONLY `PreToolDecision::PendingHumanApproval` to `Approve` (subject to the
   `ActionRisk` check in {INV-004}). `PreToolDecision::Deny` and all other decision variants
   pass through to the graph UNCHANGED. `ForceApproveHooks` does not override security-based
   `Deny` decisions. Node-level `interrupt()` calls STILL produce `Err(E-MCP-010)` — the
   `ForceApproveHooks` policy does NOT override node-level interrupt semantics. {INV-002}
   holds under `ForceApproveHooks`. `preview.action_risk` is `Option<ActionRisk>`; `None`
   (undeclared) fails closed to `Deny` identically to `Some(>= Medium)` — undeclared risk
   requires the highest gate (consistent with the fail-closed principle in BC-2.05.006
   EC-004/{INV-002}: absence/unknown risk is never treated as ReadOnly/Low; the None→Deny
   behavior is fully specified by {INV-004}).

## Invariants

- {INV-001} **STATE-ISOLATION (VP-016 proof target):** `GraphAgentTool::invoke_dyn` on
  successful graph completion returns ONLY the `serde_json::Value` produced by
  `extract_output(&final_state)`. The following are NEVER included in the output unless
  `extract_output` explicitly constructs a `Value` containing them:
  - Any checkpoint ID or durable storage key
  - Any run ID or internal execution identifier
  - Any intermediate node output accumulated during the run
  - Any message history or tool call history captured in graph channels
  - Any internal graph metadata or execution statistics
  The `extract_output` closure is the sole data-exit path at the `GraphRunner` boundary.
  The `extract_output` closure is called solely within `GraphRunner::run` — not within
  `invoke_dyn`. `invoke_dyn` wraps the already-filtered result from `run()` without
  additional processing (ADR-029 §Decision 3 canonical seam statement).
  DI-010 Credential Opacity is a structural corollary: credentials in input fields,
  intermediate fields, or model reasoning cannot appear in the output if `extract_output`
  is correctly scoped to output fields only.
  The STATE-ISOLATION guarantee extends to all output paths including error paths. The
  framework applies `redact_credentials` unconditionally to all `isError:true` responses
  (per {INV-003}). Scope of the `sanitize_internal_ids` pass and authoring-site
  obligations:

  **Authoring-site convention (primary defense — `u64` CheckpointId):** `u64` checkpoint
  IDs (`CheckpointId` is a `u64` newtype per ADR-005 / BC-2.04.003 — not UUID-shaped; a
  UUID regex cannot match it) are NOT covered by the framework `sanitize_internal_ids`
  pass. The authoring-site convention — enforced via BC-2.09.008 {INV-001} — is their
  SOLE framework guarantee. Node implementations MUST author error messages using only
  functional/behavioral descriptions and MUST NOT embed internal execution context of any
  identifier type.

  **Framework sanitization pass scope (`run_id` and server-layer `thread_id` — both
  `Uuid`):** The `sanitize_internal_ids` pass applies two patterns (union, case-insensitive): (1) the canonical hyphenated form `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; (2) the simple (no-hyphen) form `\b[0-9a-f]{32}\b`. Together these cover all standard uuid-crate rendering forms including Display (hyphenated) and simple() (contiguous hex). URN and braced forms contain the hyphenated substring and are covered by pattern (1). The `\b` word-boundary prevents splitting a 64-char SHA-256 digest and prevents stripping a 32-hex sequence embedded within a longer alphanumeric/underscore token. Note: in the full error-path pipeline (`sanitize_internal_ids(redact_credentials(message))` per ADR-029 §Decision 3 and Decision 5), a 64-char lowercase hex sequence (e.g., a SHA-256 digest) is caught by `redact_credentials` rule `[A-Za-z0-9]{64,}` before `sanitize_internal_ids` runs; the `\b` non-over-match property here is a unit-isolation property of `sanitize_internal_ids` (see TV-017). Both patterns are applied case-insensitively (consistent with S-2.11 Task-35 which mandates the case-insensitive flag so that mixed-case UUID representations are also redacted). The `sanitize_internal_ids` pass covers `run_id` (a `Uuid`) and server-layer
  `thread_id` (also a `Uuid` per entities-server.md §Thread, §Run and
  interface-definitions.md §RunnableConfig (`thread_id: Option<Uuid>`)) identically.
  Note: `FtsSearchConfig.thread_id: Option<&str>` is an FTS query-filter parameter (not a
  graph execution identifier) and never reaches a `GraphAgentTool` error-message path; it
  is outside the scope of this invariant.

- {INV-002} **Binary interrupt invariant (fail-closed default):** Exactly one of two
  outcomes is possible for any `GraphAgentTool::invoke_dyn` call under
  `GraphToolApprovalPolicy::DenyInterrupts`:
  - Terminal state reached → `invoke_dyn` returns `Ok(serde_json::Value)` (the result of `extract_output_result`)
  - Node-level `interrupt()` parking (`RunStatus::Interrupted`) → `Err(E-MCP-010)`
  The `BoundaryApprovalHook::Deny` path does NOT raise `E-MCP-010`; the graph continues
  to its own terminal (`Ok` per `{PC-004}` or the graph's own `Err`). The binary interrupt
  invariant (`interrupt()` → `Err(E-MCP-010)`) applies to node-level `interrupt()` PARKING
  (`RunStatus::Interrupted`) only. There is NO `Ok` code path that returns a result when
  the graph reached `RunStatus::Interrupted`. `ForceApproveHooks` overrides only the
  `PreToolCallHook` path; the node-level interrupt invariant holds under both policies.

- {INV-003} **Mandatory credential redaction (DI-010):** All `isError: true` paths from
  `GraphAgentTool` invocations — including `E-MCP-010` interrupt-denied errors and any
  `Err(PregolyaError)` propagated from graph execution — MUST pass through
  `pregolya_mcp::sanitize::redact_credentials` before the MCP server populates
  `content[0].text` (unconditional, per BC-2.09.007 {INV-003}). Only
  `PregolyaError::message` MUST be used as the text source; `.source()`, `Debug`, and
  `Display` output MUST NOT be used.

- {INV-004} **`ForceApproveHooks` ActionRisk runtime gate:**
  `ForceApproveHooks` is appropriate ONLY for read-only tool graphs (graphs composed
  exclusively of tools with `ActionRisk::ReadOnly` or `ActionRisk::Low`). The
  `ForceApproveHooks` policy's `BoundaryApprovalHook` enforces the read-only restriction
  at runtime. Before overriding `PendingHumanApproval` → `Approve`, the hook checks
  `preview.action_risk` (`Option<ActionRisk>` per BC-2.05.007 {PRE-003}). If
  `preview.action_risk` is `None` (undeclared; consistent with the fail-closed principle in
  BC-2.05.006 EC-004/{INV-002}: absence/unknown risk is never treated as ReadOnly/Low —
  None→Deny behavior is fully specified by {INV-004})
  OR `Some(r)` where `r >= ActionRisk::Medium`, the hook returns `Deny` (with an
  ERROR-level (highest severity) structured log (tracing::error!) at key `mcp.graph_tool.force_approve_write_blocked`) and
  emits `E-MCP-011 ForceApproveWriteBlocked`; the tool is NOT invoked. If
  `preview.action_risk` is `Some(r)` where `r < ActionRisk::Medium`, the override proceeds
  to `Approve`.

- {INV-005} **`extract_output` closure credential opacity (caller obligation):**
  The `extract_output` closure provided to `GraphAgentTool::from_graph` MUST NOT select
  credential-bearing keys of the returned `serde_json::Value` for inclusion in the output
  `serde_json::Value`. The framework does not apply credential sanitization to the
  success-path result of `extract_output`. Caller obligation, auditable at registration
  (DI-010).

## Edge Cases

### EC-001: JSON schema validation failure — args rejected before invoke_dyn
**Scenario:** tools/call arguments do not conform to the derived inputSchema for `S` (e.g.,
a required field is absent, or a field has the wrong JSON type).
**Expected behavior:** `mcp::server` validates call arguments against `DynTool::schema()`
per BC-2.09.007 {PC-005} BEFORE calling `invoke_dyn`. Server returns JSON-RPC
`{ "code": -32602, "message": "Invalid arguments for tool '<name>': <schema_error>" }`.
`GraphAgentTool::invoke_dyn` is never called; the graph is not invoked.

### EC-002: Graph-level execution error after schema validation passes (formerly: deserialization failure)
**Scenario:** Arguments pass JSON Schema validation but `CompiledStateGraph::invoke` returns
`Err(PregolyaError { .. })` during graph execution (e.g., a graph node rejects a value that
passes structural schema validation, or the graph logic fails for application-specific reasons).
**Note (type-grounding v1.7):** With `CompiledStateGraph::invoke(input: serde_json::Value, config)`
accepting the call arguments as a `serde_json::Value` directly (BC-2.02.001 {PC-005}), there is
no separate type-parameterized deserialization step. Application-level validation failures that
previously appeared at deserialization now surface as graph execution errors.
**Expected behavior:** `GraphAgentTool::invoke_dyn` returns `Err(PregolyaError { .. })`.
`mcp::server` surfaces this as `isError: true` per BC-2.09.007 {PC-003}. Credential
redaction applies per {INV-003}. See also EC-003 for the general graph execution error path.

### EC-003: Graph execution error — node returns Err(PregolyaError)
**Scenario:** Graph node logic returns `Err(PregolyaError)` (e.g., an LLM provider call
fails with E-PROV-002 ProviderTimeout).
**Expected behavior:** `GraphRunner::run` propagates the `Err(PregolyaError)`.
`GraphAgentTool::invoke_dyn` returns the error. `mcp::server` surfaces as `isError: true`
with redacted `PregolyaError::message` per BC-2.09.007 {PC-003} and {INV-003}. The
`E-MCP-010` code is NOT raised; the original graph error code is propagated.

### EC-004: Node-level interrupt() under DenyInterrupts (default)
**Scenario:** A graph node calls `interrupt()` during execution; `approval_policy =
DenyInterrupts` (default, constructed via `GraphAgentTool::from_graph` without `.with_approval_policy`).
**Expected behavior:** `GraphRunner::run` detects `RunStatus::Interrupted`;
returns `Err(PregolyaError { code: "E-MCP-010", category: EXEC, message: "graph agent tool
invocation interrupted at MCP boundary: HITL approval not supported for synchronous
tools/call; restructure the graph so it does not call interrupt() during a synchronous
tools/call invocation", retry_hint: Never, .. })`.
The interrupted run is NOT persisted to durable checkpoint. `mcp::server` surfaces as
`isError: true`. Credential redaction applies per {INV-003}. {INV-002} holds.

### EC-005: PreToolCallHook PendingHumanApproval under DenyInterrupts
**Scenario:** A tool call inside a node triggers `PreToolDecision::PendingHumanApproval`;
`BoundaryApprovalHook` is active because `approval_policy = DenyInterrupts`.
**Expected behavior:** `BoundaryApprovalHook::pre_invoke` returns `Deny { reason:
"HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY" }`. The tool is NOT invoked. The node receives
`ToolOutput::Error("HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY")`. The graph continues executing;
if this denial causes the graph to reach an error terminal state, `GraphRunner::run`
returns `Err(PregolyaError { .. })` for that terminal error, surfaced as `isError: true`.
If the graph reaches a valid terminal state despite the denial, {PC-004} applies. {INV-002}
holds.

### EC-006: ForceApproveHooks + node-level interrupt() — ForceApproveHooks does NOT apply
**Scenario:** `approval_policy = ForceApproveHooks`; a `PreToolCallHook` returns
`PendingHumanApproval` (overridden to `Approve`); later in the same run a node calls
`interrupt()`.
**Expected behavior:** The `PendingHumanApproval` is overridden to `Approve` — the tool
proceeds. The subsequent `interrupt()` call causes `RunStatus::Interrupted` →
`Err(E-MCP-010)`. `ForceApproveHooks` does NOT override node-level interrupt semantics;
the binary invariant {INV-002} holds even under `ForceApproveHooks`.

### EC-007: STATE-ISOLATION — extra fields in GraphState not in extract_output
**Scenario:** The graph's final state is a channel-composed `serde_json::Value` with keys
`"answer"`, `"internal_checkpoint_id"`, and `"accumulated_messages"`.
`extract_output = |s: &serde_json::Value| json!({ "answer": s["answer"] })`.
Graph runs successfully to terminal state.
**Expected behavior:** `invoke_dyn` returns `Ok(json!({ "answer": "<final>" }))`.
The fields `internal_checkpoint_id` and `accumulated_messages` do NOT appear in the output.
{INV-001} STATE-ISOLATION holds. VP-016 proptest verifies this property over arbitrary
graph states.

### EC-008: extract_output returns Value::Null
**Scenario:** `extract_output = |_| Value::Null`. Graph runs successfully.
**Expected behavior:** `invoke_dyn` returns `Ok(Value::Null)` → `result_text = "null"`
per BC-2.09.007 {PC-002} result_text selection rule. Server responds with
`{ "content": [{ "type": "text", "text": "null" }], "isError": false }`. No error raised.
{PC-004} holds. {INV-001} holds (Null output is a valid extract_output result).

### EC-009: ForceApproveHooks + ActionRisk>=Medium or None — E-MCP-011 emitted, tool not invoked
**Scenario:** `approval_policy = ForceApproveHooks`; a `PreToolCallHook` returns
`PendingHumanApproval` for a tool whose `preview.action_risk` is either `None`
(un-annotated tool, fail-closed) OR `Some(r)` where `r >= ActionRisk::Medium`
(e.g., a write-class tool with `ActionRisk::High`).
**Expected behavior:** `BoundaryApprovalHook` checks `preview.action_risk` before
overriding. Because `action_risk` is `None` (undeclared, fails closed) or
`>= ActionRisk::Medium`, the hook returns `Deny` and emits `E-MCP-011
ForceApproveWriteBlocked` with an ERROR-level (highest severity) structured log (tracing::error!) at key
`mcp.graph_tool.force_approve_write_blocked`. The tool is NOT invoked. {INV-004} enforces
this gate at runtime; the graph continues executing with the `Deny` result but the tool
never executes. Both the `None` case (un-annotated tool → `Deny` + `E-MCP-011`) and the
`Some(High)` case must be tested.

### EC-010: extract_output closure panics (caller contract violation)
**Scenario:** The `extract_output` closure provided to `GraphAgentTool::from_graph`
panics during execution after graph completion (programming error in the caller-supplied
closure).
**Expected behavior:** `GraphAgentTool::invoke_dyn` applies
`futures::future::FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy)))` —
the `catch_unwind` wraps the async future so that a panic occurring during `.await` polling
is caught as `Err(panic_value)`; a synchronous `std::panic::catch_unwind` around
future-construction cannot catch it because `extract_output` fires during the polled
future. The response is `isError:true`, `content[0].text == "internal error"` (static; no
panic message, backtrace, or internal state forwarded); the server continues serving
subsequent `tools/call` requests. A subsequent valid `tools/call` to a different
(non-panicking) tool still succeeds.
**SEC-008 build-profile invariant:** This recovery depends on `panic = "unwind"`. A
`panic = "abort"` release profile voids the catch and causes process termination on panic
(remote DoS, CWE-248). The pregolya-mcp release profile MUST pin `panic = "unwind"` —
devops asserts this at Phase-3 workspace `Cargo.toml` authoring.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `from_graph("agent", "desc", graph, `\|`s: &serde_json::Value`\|` json!({"result": s["result"]}))`; tools/call valid args; graph runs to terminal `result: "ok"` | `{ "content": [{ "type": "text", "text": "{\"result\":\"ok\"}" }], "isError": false }` | Happy-path STATE-ISOLATION (EC-007) |
| TV-002 | Same setup; graph node calls `interrupt()` under DenyInterrupts | `{ "content": [{ "type": "text", "text": "graph agent tool invocation interrupted at MCP boundary: ..." }], "isError": true }` | Interrupt denied (EC-004) |
| TV-003 | tools/call with args missing required field for `S`'s JSON Schema | JSON-RPC `{ "code": -32602, "message": "Invalid arguments for tool '...': ..." }` | Schema validation (EC-001) |
| TV-004 | `S` has `answer`, `internal_checkpoint_id`, `messages`; `extract_output` selects only `answer`; graph succeeds | Response contains ONLY `"answer"` key; `internal_checkpoint_id` and `messages` absent | STATE-ISOLATION (EC-007, {INV-001}) |
| TV-005 | `ForceApproveHooks` policy; PreToolCallHook returns `PendingHumanApproval`; later node calls `interrupt()` | `isError: true`, E-MCP-010 message — interrupt not suppressed by ForceApproveHooks | EC-006, {INV-002} |
| TV-006 | `extract_output = `\|`_`\|` Value::Null`; graph succeeds | `{ "content": [{ "type": "text", "text": "null" }], "isError": false }` | Null output valid (EC-008) |
| TV-007 | Graph returns `Err(PregolyaError { message: "failed: sk-ant-abc123XYZXYZXYZ12345678901234567", .. })` | `isError: true`, message contains `<redacted>` not the key material | Credential redaction ({INV-003}) |
| TV-008 | `approval_policy = ForceApproveHooks`; `PreToolCallHook` returns `PendingHumanApproval` for tool with `action_risk = ActionRisk::High` | `isError: true`, E-MCP-011 ForceApproveWriteBlocked message; tool NOT invoked; ERROR-level (highest severity) log (tracing::error!) emitted at `mcp.graph_tool.force_approve_write_blocked` | ActionRisk runtime gate — Some(High) path (EC-009, {INV-004}) |
| TV-009 | Graph node returns `Err(PregolyaError { message: "operation failed for run <example-run-id>", .. })` | `isError: true`; `content[0].text` does NOT contain `<example-run-id>` (UUID removed by `sanitize_internal_ids`) | Error-path UUID sanitization ({INV-001}) |
| TV-010 | `extract_output = `\|`s: &serde_json::Value`\|` json!({ "api_key": s["api_key"] })`; graph succeeds with `api_key = "sk-abc123"` in state | `isError: false`; `content[0].text` contains `"api_key":"sk-abc123"` (framework does NOT sanitize success-path `extract_output` result) | `extract_output` credential opacity boundary test ({INV-005}) — no post-hoc stripping |
| TV-011 | `extract_output = `\|`_`\|` panic!("boom")`; graph succeeds to terminal state; server receives `tools/call` | `{ "content": [{ "type": "text", "text": "internal error" }], "isError": true }`; a subsequent `tools/call` to a different (non-panicking) tool returns `isError: false` | extract_output panic recovery (EC-010); `FutureExt::catch_unwind(AssertUnwindSafe(...))` inside `invoke_dyn` catches panic during async future polling; SEC-008: requires `panic = "unwind"` |
| TV-012 | `approval_policy = ForceApproveHooks`; `PreToolCallHook` returns `PendingHumanApproval` for tool with `action_risk = None` (un-annotated tool) | `isError: true`, E-MCP-011 ForceApproveWriteBlocked message; tool NOT invoked; ERROR-level (highest severity) log (tracing::error!) emitted at `mcp.graph_tool.force_approve_write_blocked` (None fails closed identically to Some(>= Medium)) | ActionRisk runtime gate — None/undeclared path (EC-009, {INV-004}) |
| TV-013 | Graph node returns `Err(PregolyaError { message: "failed to load checkpoint 42", .. })` (`u64` checkpoint ID embedded in message; not UUID-shaped) | `isError: true`; `content[0].text` contains `"42"` — the bare `u64` integer is NOT matched by the `sanitize_internal_ids` regex `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` and passes through unsanitized by the framework pass; authoring-site convention ({INV-001}) is the SOLE framework guarantee for `u64` `CheckpointId` values — node implementations MUST NOT embed them in error messages | Framework `sanitize_internal_ids` scope — UUID-shaped identifiers only; `u64` `CheckpointId` (ADR-005 / BC-2.04.003) NOT covered by framework pass; authoring-site convention is sole protection boundary ({INV-001} primary defense); CWE-670/CWE-209 coverage |
| TV-014 | Graph node returns `Err(PregolyaError { message: "operation failed for run {SIMPLE-UUID}", .. })` where `{SIMPLE-UUID}` is a 32-char lowercase hex UUID with no hyphens (`Uuid::simple()` rendering, e.g. pattern `[0-9a-f]{32}`), space-delimited in message | `isError: true`; `content[0].text` does NOT contain the simple-form UUID value — the 32-hex no-hyphen value is stripped by `sanitize_internal_ids` pattern (2) `\b[0-9a-f]{32}\b` (case-insensitive; `\b` fires at space→hex boundary). POSITIVE / Red Gate: this input MUST fail (value present in output) before the two-pattern extension is implemented and PASS (value absent) after. | `Uuid::simple()` rendering coverage — simple-form run_id sanitization (F-P2A121-01; {INV-001} two-pattern union) |
| TV-015 | Graph node returns `Err(PregolyaError { message: "digest: {SHA256-DIGEST}", .. })` where `{SHA256-DIGEST}` is a 64-char lowercase hex SHA-256 digest (no hyphens, no word boundary at position 32), space-delimited in message | `isError: true`; `content[0].text` = `"digest: <redacted>"` — the mandatory pipeline is `sanitize_internal_ids(redact_credentials(message))` (ADR-029 §Decision 3 and Decision 5); `redact_credentials` runs FIRST and its rule `[A-Za-z0-9]{64,}` matches the 64-char lowercase hex token → `"<redacted>"`; `sanitize_internal_ids` then sees no UUID pattern in the already-redacted string. FULL-PIPELINE behavior: the SHA-256 digest IS redacted. The `sanitize_internal_ids` non-over-match property (pattern (2) does not independently strip a 64-char hex sequence) is documented at the unit-isolation layer in TV-017. | Full-pipeline composition — `redact_credentials` rule `[A-Za-z0-9]{64,}` catches 64-char lowercase hex token before `sanitize_internal_ids` runs; TV-017 is the isolation test for the `\b` non-over-match property (F-P2A129-01 correction; F-P2A121-01; {INV-001}/{INV-003}; ADR-029 §Decision 3 and Decision 5 chain) |
| TV-016 | Graph node returns `Err(PregolyaError { message: "key_{SIMPLE-UUID}_suffix", .. })` where `{SIMPLE-UUID}` is a 32-char lowercase hex UUID flanked by underscore characters on both sides (forming `key_{SIMPLE-UUID}_suffix`) | `isError: true`; `content[0].text` contains `"key_{SIMPLE-UUID}_suffix"` UNCHANGED — `\b` does not fire between an underscore (`_`) and a hex digit because underscore is a word character (`[A-Za-z0-9_]`); the 32-hex sequence is embedded within a continuous word-character run and is NOT matched by pattern (2). NEGATIVE control: documents an acceptable residual; authoring-site convention is the defense for underscore-flanked internal keys. | Underscore-flanked simple UUID passthrough — `\b` boundary semantics; underscore is a word char so no boundary fires (F-P2A121-01; {INV-001} two-pattern union; documented acceptable residual) |
| TV-017 | `sanitize_internal_ids` function called directly in isolation (unit-level; `redact_credentials` NOT applied) on input string `"digest: {SHA256-DIGEST}"` where `{SHA256-DIGEST}` is a 64-char lowercase hex SHA-256 digest | Output string is `"digest: {SHA256-DIGEST}"` UNCHANGED — pattern (1) requires hyphens (none present in a 64-char contiguous hex sequence); pattern (2) `\b[0-9a-f]{32}\b` checks for a word boundary after position 32 of the hex sequence, but position 33 is still a hex digit (word character), so no word boundary fires at position 32; neither pattern matches. NEGATIVE control for `sanitize_internal_ids` in isolation: the `\b` end-boundary guard prevents over-stripping SHA-256 digests at the sanitizer layer. Note: the FULL pipeline (`redact_credentials` applied first) DOES redact this input via the `[A-Za-z0-9]{64,}` rule — see TV-015 for the full-pipeline behavior. | `sanitize_internal_ids` unit-isolation — `\b` end-boundary non-over-match property at the correct isolation layer; TV-015 is the full-pipeline complement showing `redact_credentials` redacts the token first (F-P2A129-01; F-P2A121-01 complement; {INV-001} two-pattern union) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-016 | STATE-ISOLATION: `invoke_dyn` returns only `extract_output`-selected fields; no internal graph state, checkpoint IDs, message history, or metadata in output | proptest P1 — generate arbitrary graph states; verify ONLY selected fields appear in `invoke_dyn` result | Phase 3 |

## Related BCs

- BC-2.09.006 — depends on: `tools/list` advertisement path; `GraphAgentTool` registers in `ToolRegistry` and is advertised per BC-2.09.006 {PC-002}; inputSchema derived at `from_graph` time is the value advertised
- BC-2.09.007 — depends on: `tools/call` invocation path; `GraphAgentTool::invoke_dyn` is called by the `mcp::server` dispatch loop; argument schema validation ({PC-005}), isError semantics ({PC-002}/{PC-003}), credential redaction ({INV-003}) all apply
- BC-2.05.001 — related to: node-level `interrupt()` machinery; `RunStatus::Interrupted` detection per BC-2.05.001 is the trigger for the E-MCP-010 error path ({PC-005})
- BC-2.05.007 — related to: `BoundaryApprovalHook` implements `PreToolCallHook`; `Deny { reason }` path per BC-2.05.007 {PC-002} is used for the DenyInterrupts `PendingHumanApproval` conversion (EC-005)

## Architecture Anchors

- `pregolya-mcp/src/graph_tool.rs` (`mcp::graph_tool`) — `GraphAgentTool` struct implementing `DynTool`; `GraphToolApprovalPolicy` enum; `GraphRunner` type-erased trait; `BoundaryApprovalHook` internal struct; `from_graph` constructor; inputSchema derivation; `extract_output` state-isolation enforcement; E-MCP-010 interrupt-denied error path (ADR-029 §Decision 1, ADR-029 §Decision 2, ADR-029 §Decision 3, ADR-029 §Decision 4, ADR-029 §Decision 5)
- `pregolya-mcp/src/sanitize.rs` (`mcp::sanitize`) — `redact_credentials` function shared with `mcp::server` per BC-2.09.007 {INV-003}
- `pregolya-mcp/src/registry.rs` (mcp::registry standalone module, SS-09) — `ToolRegistry` into which `GraphAgentTool` is registered

## Story Anchor

S-2.11

## VP Anchors

- VP-016 ({INV-001} STATE-ISOLATION proof target — proptest P1, `graph_agent_tool_state_isolation` harness fn, Phase 3)

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-021 |
| Capability Anchor Justification | CAP-021 ("MCP Server Role (Expose Registered Tools as MCP Server Endpoint)") per capabilities-p1-p2.md §CAP-021 — this BC specifies how a pregolya `CompiledStateGraph` becomes a registered MCP tool, completing the MCP server role surface: graphs are the primary agent artifacts in pregolya, and exposing them as MCP tools is the core "expose registered tools" behavior CAP-021 defines for external LLM orchestrators |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — `GraphAgentTool::from_graph` returns a value, not `Err`; validation errors at construction time are caught by {PRE-001}/{PRE-002} bounds), DI-010 (Credential Opacity — {INV-001} STATE-ISOLATION structurally prevents credential-bearing internal state from leaking; {INV-003} redact_credentials applies to all error paths), DI-014 (Error Propagation — graph execution errors propagate as `Err`, not silent `Ok(empty)`; interrupt → `Err(E-MCP-010)` not `Ok(null)`) |
| Architecture ADR | ADR-029 (GraphAgentTool wrapping; `mcp::graph_tool` module; fail-closed interrupt policy; E-MCP-010 error code; VP-016 proptest P1) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration), P (property-based: VP-016 proptest) |
| Module | pregolya-mcp (`mcp::graph_tool`) |
| Error Codes | E-MCP-010 GraphAgentInterruptDenied (EXEC, broken, Never) — minted by this BC per ADR-029 §Decision 5; note: the initial ADR-029 draft cited E-MCP-006, which was already taken by McpContentUnsupported (minted burst-240); corrected to E-MCP-010 in ADR-029 §Changelog. E-MCP-011 ForceApproveWriteBlocked (EXEC, broken, Never) — minted by this BC ({INV-004}/EC-009; anchor F-P2A-061-02): emitted by BoundaryApprovalHook under ForceApproveHooks policy when action_risk is None or >= ActionRisk::Medium; library-layer Err return, never direct HTTP terminal in v1 |
