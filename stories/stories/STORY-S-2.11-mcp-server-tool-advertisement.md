---
document_type: story
level: ops
story_id: S-2.11
epic_id: E-21
version: "1.28"
status: draft
producer: story-writer
timestamp: 2026-08-29T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.006.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.007.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.008.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "078e856"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-2.10, S-1.14]
blocks: []
behavioral_contracts: [BC-2.09.006, BC-2.09.007, BC-2.09.008]
verification_properties: [VP-015, VP-016]
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-mcp
subsystems: [SS-09]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: BC-2.09.006 + BC-2.09.007 active; BC-2.09.008 draft (auto-promotes draft→active at S-2.11 PR merge per POL-27); BC-2.09.006 mints E-MCP-005; BC-2.09.008 mints E-MCP-010 + E-MCP-011; no BC-TBD placeholders; status = draft per Spec-First Gate S-7.01
changelog:
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors."
  - "1.2 (2026-08-24): P2A-043 F-04: old-form ordinal cross-refs converted to stable tags"
  - "1.3 (BC-2.09.006 + BC-2.09.007 / 2026-08-26): BC-2.09.006 (burst-B-SS09-11 EC-006/-32700, EC-007/-32600 wire-protocol responses). BC-2.09.007 (burst-B-SS09-11: INV-003 redact_credentials mandatory+3-pattern sub+source restriction; PC-002 result_text JSON-vs-plaintext selection rule; VP-MCPCALL-03 renamed VP-015). Story changes: AC-013 updated to Red Gate — mandatory redact_credentials applied to PregolyaError::message only (source restriction); 3 substitution patterns (sk-*, sk-ant-*, 64-char token); validates VP-015. AC-014 added: BC-2.09.006 EC-006 + BC-2.09.007 EC-007 — malformed JSON → -32700 Parse error (wire-protocol only, no PregolyaError). AC-015 added: BC-2.09.006 EC-007 + BC-2.09.007 EC-008 — invalid JSON-RPC → -32600 Invalid Request (wire-protocol only). AC-016 added: BC-2.09.007 PC-002 — result_text selection (ToolOutput::Structured→compact JSON, ToolOutput::Text→verbatim). verification_properties updated to [VP-015]. BC table version column added. Tasks updated to AC-001–AC-016."
  - "1.4 (BC-2.09.008/ADR-029/GAP-01/2026-08-26): Add BC-2.09.008 StateGraph-as-MCP-Tool coverage; GraphAgentTool; mcp::graph_tool; AC-017–AC-028 (PC-001–PC-006, INV-001–INV-003 Red Gates, EC-001/EC-004/EC-007 Red Gates); VP-016 added; points 5→8; pregolya-graph dep now allowed in pregolya-mcp; E-MCP-010 cited throughout (not E-MCP-006)."
  - "1.5 (BC-2.09.008-v1.1/BC-2.09.007-v1.9/ADR-029-v1.2/SEC-001/005/006/007/008/2026-08-26): Security hardening propagation. AC-022 corrected: ForceApproveHooks overrides ONLY PendingHumanApproval (not ALL decisions); Deny passthrough per BC-2.09.008 {PC-006}. AC-029: {PC-006} Deny passthrough (SEC-007). AC-030: {INV-004}/EC-009 ActionRisk block — action_risk>=Medium emits E-MCP-011 ForceApproveWriteBlocked+CRITICAL log (SEC-006). AC-031: {INV-001}/TV-009 error-path UUID sanitization — sanitize_internal_ids chained after redact_credentials on isError paths (SEC-005). AC-032: {INV-005}/TV-010 extract_output credential opacity — success path not framework-sanitized; DI-010 caller obligation (SEC-001). AC-033: EC-010/TV-011 extract_output panic — UnwindSafe catch yields static 'internal error'; server continues (SEC-008). AC-034: BC-2.09.007 {PC-002}/TV-009 success-path credential boundary — error paths only sanitized by framework (SEC-001). Frontmatter changelog reordered ascending. sanitize.rs extended with sanitize_internal_ids. sanitize.rs File Structure entry updated."
  - "1.6 (F-057-01/F-057-02/OBS/2026-08-26): Round-2 BC-2.09.008 security corrections. AC-030: ActionRisk gate extended — None (un-annotated, fail-closed per {INV-004}) added alongside Some(>=Medium); TV-012 (None path) and TV-008 (Some(High) path) cited; second test test_BC_2_09_008_force_approve_hooks_action_risk_none_fails_closed_emits_e_mcp_011() added. AC-021: BoundaryApprovalHook::Deny path corrected — graph CONTINUES to own terminal; valid terminal → Ok({PC-004}); error terminal → graph own Err (NOT E-MCP-010); E-MCP-010 scoped to node-level interrupt() parking only; test renamed to test_BC_2_09_008_pending_approval_under_deny_continues_to_terminal(). AC-024: Binary-interrupt invariant scoped to node-level interrupt() parking (RunStatus::Interrupted) only; Deny path explicitly excluded (graph continues to own terminal). OBS: all BC-2.09.008 and BC-2.09.007 AC heading traces normalized from §{CLAUSE} to plain CLAUSE form consistent with sibling BC-2.09.006 trace format; Task 33, EC-011, Arch Compliance Rules ActionRisk and binary-interrupt rows updated."
  - "1.7 (F-058-02/2026-08-26): AC-021 and AC-026: E-MCP-010 remedy text corrected — dropped ForceApproveHooks-recovery clause; message updated to 'restructure the graph so it does not call interrupt() during a synchronous tools/call invocation' per orchestrator mandate. AC traces unchanged."
  - "1.8 (F3/round-5/2026-08-26): AC-003: `tool.input_schema()` corrected to `tool.schema()` — `schema()` is the canonical method name on `DynTool`; `input_schema()` is a field name, not a callable method. `depends_on` updated to [S-2.10, S-1.14] — S-1.14 (StateGraph Nodes + Channels) delivers `CompiledGraph<S>` required by `GraphAgentTool::from_graph`; BC-2.09.008 PRE-001 Arc<CompiledGraph<S>> precondition."
  - "1.9 (BLOCKER-2/F-064-03/round-6/2026-08-26): Four remaining RootSchema live-body sites replaced with schemars::Schema (schemars 1.0 canonical per ADR-004 version pin; matches BC-2.09.008 PC-001). Changelog-history mentions of RootSchema preserved as historical record. Zero live RootSchema references remain outside the changelog."
  - "1.10 (F-P2A066-01/F-P2A066-02/F-P2A068-01/GATE-READY-OBS/round-7/2026-08-26): STATE-ISOLATION seam (Task 23 + Arch-Compliance rule) updated to ADR-029 §Decision 3 canonical form: ConcreteGraphRunner::run calls extract_output inside run(); invoke_dyn wraps without re-filtering. GraphAgentTool<S>→GraphAgentTool rename at 4 drifted sites (Architecture Mapping, Purity Classification, Task 17, File Structure). AC-035 added: testable {INV-005} caller-obligation credential-key scoping test (DI-010); Tasks 1/40/41 updated. input-hash updated to 46bec3d."
  - "1.11 (GAP-01-nongeneric/F-P2A073-01/round-10/2026-08-27): Non-generic re-ground (TASK 1): from_graph non-generic; Arc<CompiledStateGraph> replaces Arc<CompiledGraph<S>>; input_schema: schemars::Schema caller-derived; extract_output receives &serde_json::Value; S: GraphState + Deserialize + JsonSchema bounds removed; from_value::<S> eliminated; ToolOutput::Structured eliminated throughout (invoke_dyn returns serde_json::Value). AC-016 (Value::String→verbatim; other Value→compact JSON). AC-017 (non-generic signature). AC-018 (schema caller-passed). AC-019 (CompiledStateGraph::invoke accepts Value directly). AC-020/AC-021/AC-024/AC-027/AC-034/AC-035 updated (ToolOutput::Structured→serde_json::Value; &S→&serde_json::Value). Tasks 15/17/18/23 updated. File Structure + Arch Compliance updated (no from_value::<S> rule added). F-P2A073-01 (TASK 3): BC status annotation corrected (BC-2.09.008 draft, auto-promotes at PR merge per POL-27). input-hash updated to 431c9f7."
  - "1.12 (schema_for!(S)-sweep/round-10/2026-08-27): Two schema_for!(S) stragglers eliminated. (1) Arch Compliance table: from_graph no longer calls schema_for!(S) at construction time; rewritten to caller-supplied input_schema: schemars::Schema parameter (no schema_for! inside from_graph). (2) Library Requirements schemars row: schema_for!(S) inputSchema derivation claim removed; rewritten to schemars::Schema type for caller-supplied input_schema parameter; caller derives via schema_for! at call site. AC-017 body was already correct (schema_for!(StateType) cited as a call-site example, not inside from_graph) — no AC-017 change needed."
  - "1.13 (GAP-01-type-grounding/round-12/2026-08-27): AC-032 closure re-grounded: |s: &S| json!({api_key: s.api_key}) replaced with |s: &serde_json::Value| using s[api_key] JSON index access. Task-41 re-grounded: TestGraphState struct construction replaced with json!({}) value; s.answer struct field access replaced with s[answer] JSON index. Zero live-body |s: &S| or struct-field-access phantoms remain. input-hash updated to 0f081e1."
  - "1.14 (F-P2A079-01/round-14/2026-08-27): Task 38 stale ToolOutput::Text syntax corrected to Ok(Value::String(...)) canonical invoke_dyn return form. Arch Compliance from_value::<S> prohibition Source column corrected to BC-2.09.008 {PC-003}. Changelog 1.11 item (3) bare BC-ID rephrased to non-generic seam design. input-hash updated (state-manager recomputes)."
  - "1.15 (F-P2A084-01/round-18/2026-08-27): AC-023 and Task 20: last two live-body ToolOutput residues corrected — serde_json::Value returned by invoke_dyn replaces ToolOutput as the output type name. Zero remaining live-body stale ToolOutput, CompiledGraph<, StateGraph<S>, |s: &S|, schema_for!(S) (non-call-site), or from_value::<S> (non-prohibition) references."
  - "1.16 (F-P2A087-01/F-P2A087-02/round-19/2026-08-27): Symbol-canon propagation from BC-2.09.008 {PC-005}/EC-005 PreToolDecision rename and DynTool object-safe interface. (1) AC-008: DynTool::invoke → DynTool::invoke_dyn (object-safe dispatch seam method; no DynTool::invoke exists). (2) AC-009: DynTool::invoke → DynTool::invoke_dyn. (3) Purity Classification tools/call handler row: DynTool::invoke → DynTool::invoke_dyn. (4) Previous Story Intelligence: DynTool::invoke(args) → DynTool::invoke_dyn(args). (5) AC-021: PreToolCallHook::PendingHumanApproval → PreToolDecision::PendingHumanApproval (BC-2.09.008 {PC-005}/EC-005 enum rename; matches AC-022/AC-029 canonical form already in place). input-hash updated to 3b82473."
  - "1.17 (round-21/F-P2A093-01/2026-08-28): Task-27 updated — pregolya-graph now wired in two Cargo.toml sections: `[dependencies]` (workspace pin, for GraphAgentTool production code) AND `[dev-dependencies]` with `features = [\"test-util\"]` (so VP-016 proptest harness can call CompiledStateGraph::stub_terminal cross-crate). Body Changelog entry added."
  - "1.18 (round-22/F-P2A096-01/F-P2A097-01/F-P2A099-02/F-P2A096-03/F-P2A097-02/2026-08-28): Exhaustive security sweep. (1) AC-031: sanitizer scope corrected — retired v4-specific regex replaced with version-agnostic `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; 'checkpoint IDs' removed from scope (framework covers run_id + server-layer thread_id only; u64 CheckpointId is NOT UUID-shaped); fixture now requires a non-v4 UUID to prevent false-green regression. (2) AC-036 added: BC-2.09.008 {INV-001}/TV-013 — u64 CheckpointId passthrough unchanged through sanitize_internal_ids. (3) AC-033: panic recovery corrected to FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy))) INSIDE invoke_dyn; synchronous std::panic::catch_unwind marked INADEQUATE; Red Gate test must drive panic through .await polling. (4) AC-037 added: SEC-008 panic=unwind release-profile obligation (devops-engineer Phase-3). (5) Tasks 34/35/36/37 updated. (6) Tasks 42-44 added. (7) Arch Compliance rows updated. (8) File Structure and Token Budget updated. input-hash recomputed (BC-2.09.008 input file updated through rounds 19–22 security corrections)."
  - "1.19 (round-26/F-P2A113-02+F-P2A115-03+confirm-registry/2026-08-28): Four log-level corrections CRITICAL→ERROR (`tracing::error!`) per BC-2.09.008 {INV-004} (Rust tracing has no CRITICAL level): AC-030 body, EC-011, Task 33, Arch Compliance ActionRisk row. File Structure registry.rs de-hedged: 'CREATE or MODIFY / shared with client side (extract if needed)' → 'CREATE / standalone mcp::registry module (SS-09; architect OPTION A); Arc<ToolRegistry> injection'. Previous Story Intelligence de-hedged: 'via shared access' → explicit Arc<ToolRegistry> injection. Historical changelog 1.5/1.6 CRITICAL mentions preserved as immutable records per story-change convention."
  - "1.20 (R28/F-P2A121-01-propagation/2026-08-28): AC-031 extended with TV-014 simple-form UUID positive fixture (Uuid::simple() 32-contiguous-hex rendering — MUST be stripped by pattern (2) `\\b[0-9a-f]{32}\\b`); Task-35 description updated from single hyphenated-pattern to two-pattern union (pattern 1: canonical hyphenated form; pattern 2: simple no-hyphen `\\b[0-9a-f]{32}\\b`; both case-insensitive; `\\b` word-boundary prevents 64-hex-split and underscore-flanked-strip). Mirrors BC-2.09.008 §Changelog {INV-001} two-pattern extension and TV-014/TV-015/TV-016 additions."
  - "1.21 (R29/F-P2A125-01+F-P2A127-01+O-P2A124-01/2026-08-28): Round-29 propagation sweep. (1) §Architecture Compliance Rules sanitizer row updated to two-pattern union (both case-insensitive): pattern (1) canonical hyphenated `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; pattern (2) simple no-hyphen `\\b[0-9a-f]{32}\\b`; scope: `run_id` and server-layer `thread_id` only; `u64` CheckpointId passes through unchanged (F-P2A125-01). (2) §File Structure sanitize.rs purpose column updated to two-pattern union + BC-2.09.008 INV-001/TV-013/TV-014 cite (F-P2A125-01). (3) §File Structure registry.rs `Arc<RwLock<HashMap<String, Arc<dyn DynTool>>>>` surplus fifth `>` corrected to 4 angle-brackets (F-P2A127-01). (4) BC status frontmatter comment: BC-2.09.008 mint annotation augmented with E-MCP-011 alongside E-MCP-010 (O-P2A124-01). input-hash unchanged — no BC input file changes in round-29."
  - "1.22 (R30/F-P2A129-02+F-P2A131-01+F-P2A129-01-propagation/2026-08-28): Round-30 three-finding sweep. (1) F-P2A129-02 [MED]: AC-031 normative statement rewritten to TWO-PATTERN UNION verbatim-mirroring BC-2.09.008 {INV-001} — opening description changed from single-pattern (hyphenated only) to explicit pattern (1) canonical hyphenated `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` + pattern (2) simple no-hyphen `\\b[0-9a-f]{32}\\b`; sanitize_internal_ids description in the framework-passes sentence changed from 'UUID (any version) pattern removal' to explicit two-pattern union; 'pattern (2)' reference in the fixture description now has proper antecedent; resolves same-document contradiction with §Architecture Compliance Rules row and BC-2.09.008 {INV-001}. (2) F-P2A131-01 [MED]: §Previous Story Intelligence and §File Structure registry.rs row aligned to architect canonical consumer/registrar set from module-decomposition.md §mcp::registry row: mcp::server reads (for tools/list + tools/call dispatch); mcp::client populates at session startup via mcp::discovery conversion; previously both sites said 'shared between ... and ...' without the reads/writes role distinction. (3) F-P2A129-01 propagation [POL-8]: Task-35 TV-015 reference corrected — 'prevents matching within 64-char SHA-256 digests per TV-015' replaced with 'prevents over-matching within 64-char SHA-256 digests at the isolation layer per TV-017 (sanitize_internal_ids alone does not strip a 64-char hex sequence; TV-015 verifies the full pipeline: redact_credentials catches it first)'; TV-015/TV-017 added to Task-35 end citation. input-hash updated (BC-2.09.008 §Changelog round-30 update)."
  - "1.23 (R31/F-P2A135-01/2026-08-28): mcp::registry registrar attribution corrected in §Previous Story Intelligence and §File Structure registry.rs row. R30 phantom 'mcp::client (populates at session startup via mcp::discovery conversion)' replaced at both live-body sites with canonical attribution corroborated against BC-2.09.006 {PRE-001} + BC-2.09.008 {PC-002} + S-2.10 wiring: read by mcp::server (tools/list + tools/call dispatch; BC-2.09.006 {PC-002}); populated by the application/caller layer via the standard ToolRegistry registration API (BC-2.09.006 {PRE-001} + BC-2.09.008 {PC-002}); typical flow: caller calls client.get_tools() then caller registers returned tools via registry.register(name, tool); mcp::client does NOT write the registry. BC-2.09.008 clause verified: standard-registration-API text lives at {PC-002}; arch-doc citation ({PC-001}) is a mismatch — escalated for architect correction (story-writer scope does not include arch docs). input-hash updated (module-decomposition.md R31 edit)."
  - "1.24 (R33/F-P2A143-02/2026-08-29): v1.23 {PC-001}/{PC-002} anchor mismatch escalation RESOLVED — architect corrected module-decomposition.md in R31 (v1.57 cites {PC-002}); story-writer {PC-002} usage confirmed correct (F-P2A135-01 closed). Records-tier resolution note only; no live-body content changed."
  - "1.25 (R36/F-P2A155-01/2026-08-29): AC-019 seam-collapse corrected per BC-2.09.008 {PC-003} — OLD: invoke_dyn called CompiledStateGraph::invoke directly (collapsed 3-layer seam). NEW: invoke_dyn delegates to runner.run(arguments, policy) via Arc<dyn GraphRunner>; GraphRunner::run (ConcreteGraphRunner<S>::run) calls CompiledStateGraph::invoke internally. Exhaustive call-direction sweep: AC-020 (GraphRunner::run wraps CompiledStateGraph::invoke; invoke_dyn wraps run), Task-23, Arch-Compliance STATE-ISOLATION row — all correct; AC-019 was the sole seam-collapse in S-2.11. input-hash refreshed (BC-2.09.008 updated in R36)."
  - "1.26 (R37/O-P2A157-01/2026-08-29): O-P2A157-01 [OBS] BC-2.09.008 {INV-003} (v2.9→v3.0) symmetric MUST-language propagation. AC-025 body: all GraphAgentTool isError paths MUST pass through redact_credentials; Only PregolyaError::message MUST be used as text source; .source()/Debug/Display MUST NOT be used. §Architecture Compliance Rules row BC-2.09.008 INV-003 (sweep find): source-restriction aligned to AC-025 canon — .source()/Debug/Display MUST NOT be used on GraphAgentTool isError paths; '(mandatory, no hedge)' qualifier added matching BC-2.09.007 {INV-003} row pattern. No other live-body {INV-003} references required MUST-language alignment (parenthetical cross-references at AC-019/AC-026 are citations, not normative definitions). input-hash unchanged (no BC input file changes in R37)."
  - "1.27 (R39/F-P2A165-01+F-P2A167-01+F-P2A167-02/2026-08-29): BC-2.09.008 unconditional pre-hook gate propagated (ITEM B): AC-022/AC-030/EC-011/Task-22/Task-33/Arch-Compliance ForceApproveHooks row updated — ActionRisk gate runs BEFORE invoking inner PreToolCallHook; None/Some(>=Medium) denied WITHOUT calling inner hook (covers AlwaysApprovePolicy/no-hook default); TV-018 cited throughout. Tools/call collapsed attribution corrected at two live-body sites (ITEM C, F-P2A167-01 [MED, POL-4]): §Previous Story Intelligence and §File Structure registry.rs row changed from tools/list+tools/call collapsed to split '(tools/list dispatch: BC-2.09.006 {PC-002}; tools/call dispatch: BC-2.09.007 {PC-001})'. Phantom S-2.10 filenames corrected (ITEM D, F-P2A167-02 [LOW, POL-4]): §Previous Story Intelligence tool.rs→discovery.rs, guardrail.rs→ingress.rs per round-25 canonical rename."
  - "1.28 (round-40/F-P2A169-02/2026-08-29): F-P2A169-02 [MED, CWE-862/POL-46] — BC-2.09.008 EC-006/TV-005 action_risk precondition propagated to three live-body sites. AC-022 test descriptions: both fixtures now specify action_risk = Some(ActionRisk::ReadOnly) for gate-approved path; second test adds None/>=Medium gate-denied note. AC-024 ForceApproveHooks path: action_risk = Some(ActionRisk::ReadOnly) precondition added (gate approves, ReadOnly < Medium); None/>=Medium gate-denied WITHOUT inner hook per EC-009 note added; test description updated with EC-006 path precondition. Edge-case EC-009 scenario: action_risk = Some(ActionRisk::ReadOnly) precondition added; None/>=Medium gate-denied note added. BC-2.09.008 {PC-006}/{INV-004}/EC-006/TV-005 are the authoritative canon (R40). input-hash refreshed (BC-2.09.008 {PC-006} updated R40)."
---

# S-2.11: MCP Server — Tool Advertisement and External Client Invocation

## Narrative

- **As a** pregolya platform engineer exposing registered tools to external MCP-capable LLM applications
- **I want to** run an `McpServer` within `pregolya-mcp` that advertises all tools from the `ToolRegistry` via the `tools/list` JSON-RPC method and dispatches `tools/call` requests to the matching registered tool
- **So that** any external MCP client (another agent framework, a Claude Desktop instance, a VSCode extension) can discover and invoke pregolya tools through the standard MCP protocol, using either stdio or SSE transport

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.09.006 | MCP Server Tool Advertisement (tools/list; mcp::server) | P1 |
| BC-2.09.007 | MCP Server Tool Invocation (tools/call; External Client Executes Registered Tool) | P1 |
| BC-2.09.008 | StateGraph-as-MCP-Tool Wrapping (GraphAgentTool; mcp::graph_tool) | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.09.006 PC-001)
`McpServer::start(config: McpServerConfig)` returns `Ok(McpServerHandle)` when the transport
binds successfully. The config carries `transport: McpServerTransport` and
`tool_registry: Arc<ToolRegistry>`. Verified by `test_BC_2_09_006_start_returns_handle_on_success()`.

### AC-002 (traces to BC-2.09.006 PC-001)
Binding failure (e.g., SSE port already in use, stdio not available) returns
`Err(PregolyaError { code: "E-MCP-005", message: "McpServerBindFailed: cannot bind to <transport>: <reason>", .. })`.
`E-MCP-005` category is `TRANSPORT`, severity `broken`, retry_hint `Never`. This error code
is minted by BC-2.09.006 — register it in the error taxonomy if not already present.
Verified by `test_BC_2_09_006_bind_failure_returns_e_mcp_005()`.

### AC-003 (traces to BC-2.09.006 PC-002)
On `tools/list` JSON-RPC request, the server serializes each registered `DynTool` to MCP
`ToolDefinition` format: `{ "name": tool.name(), "description": tool.description(), "inputSchema": tool.schema() }`.
Response is `{ "tools": [<definitions>] }`. Verified by
`test_BC_2_09_006_tools_list_returns_all_registered_tools()`.

### AC-004 (traces to BC-2.09.006 PC-003)
The `ToolRegistry` is read on each `tools/list` request — not snapshotted at server startup.
A tool registered after `McpServer::start` is included in a subsequent `tools/list` response.
Verified by `test_BC_2_09_006_dynamic_registry_read_on_each_request()`.

### AC-005 (traces to BC-2.09.006 PC-004)
`McpServerHandle::shutdown()` gracefully closes all active connections and stops accepting
new ones. After `shutdown()`, new `tools/list` requests are not served. Verified by
`test_BC_2_09_006_shutdown_closes_connections()`.

### AC-006 (traces to BC-2.09.006 PC-005)
A `ToolRegistry` with zero registered tools returns `{ "tools": [] }` on `tools/list` — this
is a valid MCP response, not an error. Verified by
`test_BC_2_09_006_empty_registry_returns_empty_tools_array()`.

### AC-007 (traces to BC-2.09.006 EC-004)
When a connected MCP client sends an unimplemented JSON-RPC method (e.g., `resources/list`),
the server responds with the JSON-RPC error `{ "code": -32601, "message": "Method not found" }`.
No `E-MCP-005` is raised; this is a protocol-level not-implemented response. Verified by
`test_BC_2_09_006_unimplemented_method_returns_32601()`.

### AC-008 (traces to BC-2.09.007 PC-001 + PC-002)
`tools/call` with a valid tool name and conforming arguments dispatches to the registered
`DynTool::invoke_dyn`. On success, responds with
`{ "content": [{ "type": "text", "text": "<result>" }], "isError": false }`.
Verified by `test_BC_2_09_007_tools_call_success_response()`.

### AC-009 (traces to BC-2.09.007 PC-003)
When the registered `DynTool::invoke_dyn` returns `Err(PregolyaError { .. })`, the server
responds with `{ "content": [{ "type": "text", "text": "<error_message>" }], "isError": true }`.
The JSON-RPC result layer carries `result` (not `error`) — the MCP protocol transaction
succeeded; only the tool invocation failed. Verified by
`test_BC_2_09_007_tool_error_returns_is_error_true()`.

### AC-010 (traces to BC-2.09.007 PC-004)
When `<tool_name>` is not in the `ToolRegistry`, the server responds with the JSON-RPC error
`{ "code": -32602, "message": "Tool not found: <tool_name>" }`. No tool execution is attempted.
Verified by `test_BC_2_09_007_tool_not_found_returns_32602()`.

### AC-011 (traces to BC-2.09.007 PC-005)
When the `arguments` object does not conform to the tool's input schema, the server responds
with `{ "code": -32602, "message": "Invalid arguments for tool '<tool_name>': <schema_error>" }`.
Tool is not invoked. Verified by `test_BC_2_09_007_invalid_arguments_returns_32602()`.

### AC-012 (traces to BC-2.09.007 INV-002)
`isError: true` in the `CallToolResult` means the tool returned an error but the MCP
protocol transaction succeeded. JSON-RPC `error` (not `result`) is only returned for
protocol-level failures (tool not found, invalid params, parse error). Verified by
`test_BC_2_09_007_is_error_semantics_vs_jsonrpc_error()`.

### AC-013 (traces to BC-2.09.007 INV-003 — Red Gate, validates VP-015)
**Red Gate / Mandatory:** When a registered tool returns
`Err(PregolyaError { message: "request failed: key=sk-abc123XYZabc123XYZabc", .. })`,
the MCP response `content[0].text` MUST be `"request failed: key=<redacted>"` — NOT the raw
message with the key value exposed. This is a **mandatory** sanitization (no "best-effort"
variant). The server applies `pregolya_mcp::sanitize::redact_credentials(text: &str) -> Cow<str>`
to `PregolyaError::message` before placing it in the response. The redaction function applies
the following three substitution rules in order:
1. OpenAI key pattern `sk-[A-Za-z0-9_\-]{20,}` → `"<redacted>"`
2. Anthropic key pattern `sk-ant-[A-Za-z0-9_\-]{32,}` → `"<redacted>"`
3. Generic long alphanumeric token `[A-Za-z0-9]{64,}` → `"<redacted>"`
**Source restriction:** only `PregolyaError::message` is used as the text source. The
`.source()` chain, `Debug` output, and `Display` output of the error are NEVER included in
the MCP response text. This test is a Red Gate: without `redact_credentials`, the raw message
containing key material would reach the external MCP client. Verified by
`test_BC_2_09_007_error_message_credential_redaction_applies_3_patterns()` (mock tool returning
`Err(PregolyaError { message: "key=sk-abc123XYZabc123XYZabc", .. })`; assert response
`content[0].text` equals `"key=<redacted>"`).

### AC-014 (traces to BC-2.09.006 EC-006 + BC-2.09.007 EC-007)
When the MCP server receives bytes on a connection that cannot be parsed as valid JSON (e.g.,
a truncated message, binary garbage, or `"not json{{"`), the server responds with the
standard JSON-RPC wire-protocol error:
`{ "jsonrpc": "2.0", "id": null, "error": { "code": -32700, "message": "Parse error" } }`.
This is a **wire-protocol response only** — no `PregolyaError` is constructed and no
`E-MCP-*` error code is raised internally for this path. The connection remains open;
subsequent well-formed requests are processed normally. This behavior applies on both the
`tools/list` request path (BC-2.09.006 EC-006) and the `tools/call` request path
(BC-2.09.007 EC-007). Verified by `test_BC_2_09_006_malformed_json_returns_32700_parse_error()`
and `test_BC_2_09_007_malformed_json_returns_32700_parse_error()`.

### AC-015 (traces to BC-2.09.006 EC-007 + BC-2.09.007 EC-008)
When the MCP server receives valid JSON that is not a well-formed JSON-RPC request object
(e.g., missing `"jsonrpc"` version field, missing `"method"` field, or `"id"` is not a
string/number/null), the server responds with:
`{ "jsonrpc": "2.0", "id": null, "error": { "code": -32600, "message": "Invalid Request" } }`.
This is a **wire-protocol response only** — no `PregolyaError` or `E-MCP-*` code is raised
internally. The connection remains open; subsequent well-formed requests are processed
normally. Applies on both `tools/list` (BC-2.09.006 EC-007) and `tools/call`
(BC-2.09.007 EC-008) paths. Verified by
`test_BC_2_09_006_invalid_jsonrpc_returns_32600_invalid_request()` and
`test_BC_2_09_007_invalid_jsonrpc_returns_32600_invalid_request()`.

### AC-016 (traces to BC-2.09.007 PC-002)
The `result_text` field in a successful `tools/call` response (`isError: false`) is
determined by the `serde_json::Value` returned by `DynTool::invoke_dyn`:
- `Value::String(s)` → `result_text = s` verbatim (no additional JSON-encoding applied to
  the string contents). `Value::String("".to_string())` produces `result_text = ""`.
- Any other `Value` variant (Object, Array, Number, Bool, Null) →
  `result_text = serde_json::to_string(&value)` (compact JSON, no pretty-printing).
  `Value::Null` serializes to the string `"null"`.
The `DynTool` implementation controls the `Value` variant returned; the server applies the
corresponding rule without re-interpreting or re-encoding. Verified by
`test_BC_2_09_007_result_text_structured_uses_compact_json()` (Object value; assert compact
JSON, no newlines), `test_BC_2_09_007_result_text_text_verbatim()` (String value; assert
verbatim, no extra quoting), and `test_BC_2_09_007_result_text_null_value_is_string_null()`
(`Value::Null`; assert `result_text == "null"`).

### AC-017 (traces to BC-2.09.008 PC-001)
`GraphAgentTool::from_graph(name, description, graph, input_schema, extract_output)` constructs a
`GraphAgentTool` where `graph: Arc<CompiledStateGraph>`,
`input_schema: schemars::Schema` (caller-derived, e.g. `schemars::schema_for!(StateType)`),
and `extract_output: impl Fn(&serde_json::Value) -> serde_json::Value + Send + Sync + 'static`.
The `from_graph` constructor is non-generic; the caller derives the schema before calling
`from_graph` and passes it as a concrete `schemars::Schema` value. The schema is stored
internally and returned by `DynTool::schema()` for advertisement in `tools/list` responses
per BC-2.09.006 {PC-002}. Construction returns a value (not `Err`); all inputs are concrete
types. Verified by `test_BC_2_09_008_from_graph_stores_schema_from_parameter()`.

### AC-018 (traces to BC-2.09.008 PC-002)
The constructed `GraphAgentTool` implements `DynTool` (object-safe dispatch seam per
ADR-005 §Adjacent Trait Object-Safety Adjudications) and may be registered in a `ToolRegistry`
via the standard registration API. After registration, the MCP server advertises the tool in
`tools/list` responses — name, description, and inputSchema (the `schemars::Schema` passed by
the caller as the `input_schema` parameter to `from_graph`) are exposed verbatim per
BC-2.09.006 {PC-002}. Verified by
`test_BC_2_09_008_graph_agent_tool_registered_appears_in_tools_list()`.

### AC-019 (traces to BC-2.09.008 PC-003)
On `tools/call` invocation for a `GraphAgentTool`:
- If call arguments do not conform to `DynTool::schema()`, the server returns JSON-RPC
  `{ "code": -32602, "message": "Invalid arguments for tool '<name>': <schema_error>" }` BEFORE
  `invoke_dyn` is called; the graph is NOT invoked.
- If schema validation passes, `GraphAgentTool::invoke_dyn` delegates to
  `runner.run(arguments, policy)` via `Arc<dyn GraphRunner>`; `GraphRunner::run`
  (`ConcreteGraphRunner<S>::run` at the concrete layer, where `S` is statically known)
  calls `CompiledStateGraph::invoke(arguments, config)` internally — which takes
  `serde_json::Value` directly; there is no separate type-parameterized deserialization
  step. If `CompiledStateGraph::invoke` returns
  `Err(PregolyaError { .. })`, the error propagates through `GraphRunner::run`;
  `invoke_dyn` surfaces it; the server surfaces this as `isError: true` per
  BC-2.09.007 {PC-003}; credential redaction applies per {INV-003}.
Verified by `test_BC_2_09_008_schema_validation_fail_returns_32602()` and
`test_BC_2_09_008_deserialize_fail_returns_is_error_true_with_redaction()`.

### AC-020 (traces to BC-2.09.008 PC-004)
On successful graph execution: `CompiledStateGraph::invoke` returns `serde_json::Value`.
`ConcreteGraphRunner::run` calls `extract_output(&final_state: &serde_json::Value)` and
returns the result. `GraphAgentTool::invoke_dyn` returns
`Ok(extract_output_result: serde_json::Value)`. The server serializes this per
BC-2.09.007 {PC-002} (`result_text = serde_json::to_string(&extract_output_result)`).
If `extract_output` returns `Value::Null`, `result_text = "null"` — no error raised; {PC-004}
holds. Verified by `test_BC_2_09_008_successful_graph_run_returns_structured_output()` and
`test_BC_2_09_008_extract_output_null_result_is_valid()`.

### AC-021 (traces to BC-2.09.008 PC-005)
Under `GraphToolApprovalPolicy::DenyInterrupts` (default):
- **Node-level `interrupt()`:** When a graph node calls `interrupt()` during execution,
  `GraphRunner::run` detects `RunStatus::Interrupted` and `GraphAgentTool::invoke_dyn` returns
  `Err(PregolyaError { code: "E-MCP-010", category: EXEC, message: "graph agent tool invocation
  interrupted at MCP boundary: HITL approval not supported for synchronous tools/call; restructure
  the graph so it does not call interrupt() during a synchronous tools/call invocation",
  retry_hint: Never })`. The interrupted run is NOT persisted to durable checkpoint.
- **`PreToolDecision::PendingHumanApproval`:** When received, `BoundaryApprovalHook` converts
  `PendingHumanApproval` → `Deny { reason: "HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY" }`; the tool
  is NOT invoked; the node receives `ToolOutput::Error`; the graph CONTINUES executing. If the
  graph reaches a valid terminal state, {PC-004} applies and `invoke_dyn` returns
  `Ok(serde_json::Value)` (the `extract_output` result). If the graph reaches an error
  terminal, `invoke_dyn` returns `Err(PregolyaError)` with the graph's OWN error —
  `E-MCP-010` is NOT raised on the `BoundaryApprovalHook::Deny` path.
Verified by `test_BC_2_09_008_node_interrupt_under_deny_returns_e_mcp_010()` (node-level
interrupt → E-MCP-010; Red Gate) and
`test_BC_2_09_008_pending_approval_under_deny_continues_to_terminal()` (Deny → graph
continues → valid terminal → `Ok(serde_json::Value)` per {PC-004}; or error terminal →
graph's own `Err`, NOT `E-MCP-010`).

### AC-022 (traces to BC-2.09.008 PC-006)
Under `GraphToolApprovalPolicy::ForceApproveHooks`, `BoundaryApprovalHook` runs the `ActionRisk`
gate BEFORE invoking the inner `PreToolCallHook` (per {INV-004}). Tools with
`preview.action_risk` of `None` (undeclared) OR `Some(r)` where `r >= ActionRisk::Medium` are
denied WITHOUT calling the inner hook — this covers `AlwaysApprovePolicy` / no-hook default
`Approve` paths (not only `PendingHumanApproval`). When the gate approves (`preview.action_risk`
is `Some(r)` where `r < ActionRisk::Medium`): the inner hook is invoked; if the inner hook
returns `PreToolDecision::PendingHumanApproval`, the hook overrides it to `Approve`;
`PreToolDecision::Deny` and all other decision variants from the inner hook pass through to the
graph UNCHANGED — `ForceApproveHooks` does not override security-based `Deny` decisions.
Node-level `interrupt()` calls STILL produce `Err(E-MCP-010)` — `ForceApproveHooks` does NOT
override node-level interrupt semantics; {INV-002} holds under `ForceApproveHooks`. Verified by
`test_BC_2_09_008_force_approve_hooks_overrides_pending_approval()` (tool with
`action_risk = Some(ActionRisk::ReadOnly)`, gate approves, `ReadOnly < Medium`;
`PendingHumanApproval` overridden to `Approve`) and
`test_BC_2_09_008_force_approve_hooks_does_not_suppress_node_interrupt()` (tool with
`action_risk = Some(ActionRisk::ReadOnly)`, gate approves, `ReadOnly < Medium`; node interrupt
still → `Err(E-MCP-010)`; `action_risk = None` or `>= Medium` → gate-denied per EC-009
without calling inner hook — BC-2.09.008 EC-006, {INV-002}).

### AC-023 (traces to BC-2.09.008 INV-001 — Red Gate, validates VP-016)
**Red Gate / Mandatory (STATE-ISOLATION):** `GraphAgentTool::invoke_dyn` on successful graph
completion returns ONLY the `serde_json::Value` produced by `extract_output(&final_state)`.
The following are NEVER included in the `serde_json::Value` returned by `invoke_dyn` unless `extract_output` explicitly
constructs a `Value` containing them: checkpoint IDs, run IDs, internal execution identifiers,
intermediate node outputs, accumulated message history, tool call history, graph metadata, and
execution statistics. The `extract_output` closure is the sole data-exit path at the
`GraphRunner` boundary. DI-010 Credential Opacity is a structural corollary: credentials in
input fields, intermediate fields, or model reasoning cannot appear in the output if
`extract_output` is correctly scoped to output fields only. This is a Red Gate: without
STATE-ISOLATION enforcement, internal graph state including credential-bearing fields could leak
to external MCP clients. VP-016 proptest harness `graph_agent_tool_state_isolation` generates
arbitrary `serde_json::Value` objects with extra keys and verifies that ONLY selected keys
appear in the `invoke_dyn` result. Verified by
`test_BC_2_09_008_state_isolation_only_extract_output_in_result()` ({INV-001} / VP-016 anchor).

### AC-024 (traces to BC-2.09.008 INV-002 — Red Gate)
**Red Gate / Binary interrupt invariant (fail-closed, node-level interrupt() only):** The
binary interrupt invariant applies to node-level `interrupt()` PARKING (`RunStatus::Interrupted`)
only. Under `GraphToolApprovalPolicy::DenyInterrupts`, exactly one of two outcomes is possible
for the node-level interrupt path:
- Terminal state reached → `Ok(extract_output_result: serde_json::Value)`
- Node-level `interrupt()` parking (`RunStatus::Interrupted`) → `Err(E-MCP-010)`
The `BoundaryApprovalHook::Deny` path does NOT raise `E-MCP-010`; the graph continues to its
own terminal (`Ok` per {PC-004} or the graph's own `Err`). There is NO `Ok` code path that
returns a result when the graph reached `RunStatus::Interrupted`. Under `ForceApproveHooks` for a tool with `action_risk = Some(ActionRisk::ReadOnly)`
(gate approves, `ReadOnly < Medium`), the inner `PreToolCallHook` is invoked and
`PendingHumanApproval` overridden to `Approve`; the node-level interrupt invariant still holds.
{INV-002} is satisfied under `ForceApproveHooks` as well. **Note:** a tool with
`action_risk = None` (undeclared) or `>= Medium` would be gate-denied WITHOUT calling the inner
hook per EC-009 ({INV-004}); the interrupt path via `PendingHumanApproval`-override is
unreachable for that tool (BC-2.09.008 EC-006 is the authoritative precondition). Verified by
`test_BC_2_09_008_binary_interrupt_invariant_no_ok_on_interrupt()` (EC-004 and EC-006 combined;
EC-006 path uses `action_risk = Some(ActionRisk::ReadOnly)` — gate approves, inner hook invoked,
interrupt still → `Err(E-MCP-010)`; `action_risk = None` or `>= Medium` → gate-denied per EC-009).

### AC-025 (traces to BC-2.09.008 INV-003 — Red Gate)
**Red Gate / Mandatory credential redaction on all `GraphAgentTool` isError paths:** All
`isError: true` paths from `GraphAgentTool` invocations — including `E-MCP-010`
interrupt-denied errors and any `Err(PregolyaError)` propagated from graph execution — MUST
pass through `pregolya_mcp::sanitize::redact_credentials` before the MCP server populates
`content[0].text` (unconditional, per BC-2.09.007 {INV-003}). Only `PregolyaError::message`
MUST be used as the text source; `.source()`, `Debug`, and `Display` output MUST NOT be used.
Verified by
`test_BC_2_09_008_graph_agent_error_paths_credential_redaction()` (mock graph returning
`Err(PregolyaError { message: "failed: sk-ant-abc123XYZabc123XYZ1234567890123456", .. })`;
assert `content[0].text` contains `<redacted>`, not the key material).

### AC-026 (traces to BC-2.09.008 EC-004 — Red Gate)
**Red Gate / Node interrupt under DenyInterrupts → E-MCP-010:** When a graph node calls
`interrupt()` during execution with `approval_policy = DenyInterrupts` (default, constructed
via `from_graph` without `.with_approval_policy`), `GraphRunner::run` detects
`RunStatus::Interrupted` and the server returns
`{ "content": [{ "type": "text", "text": "graph agent tool invocation interrupted at MCP boundary: HITL approval not supported for synchronous tools/call; restructure the graph so it does not call interrupt() during a synchronous tools/call invocation" }], "isError": true }`.
The error code is `E-MCP-010` (GraphAgentInterruptDenied — NOT E-MCP-006, which is
McpContentUnsupported, a distinct error minted in burst-240). The interrupted run is NOT
persisted to durable checkpoint. Credential redaction applies per {INV-003}. {INV-002} holds.
Verified by `test_BC_2_09_008_ec004_node_interrupt_deny_policy_e_mcp_010()`.

### AC-027 (traces to BC-2.09.008 EC-007 — Red Gate, validates VP-016)
**Red Gate / STATE-ISOLATION — extra fields excluded from output:** When the graph state
is a `serde_json::Value` object with keys `answer`, `internal_checkpoint_id`, and
`accumulated_messages`, and
`extract_output = |s: &serde_json::Value| json!({ "answer": s["answer"] })`, a successful
graph run produces `invoke_dyn` result `serde_json::Value = json!({"answer": "<final>"})`.
The keys `internal_checkpoint_id` and `accumulated_messages` do NOT appear anywhere in the
MCP response. {INV-001} STATE-ISOLATION holds. VP-016 proptest verifies this property over
arbitrary `serde_json::Value` objects with additional keys. Verified by
`test_BC_2_09_008_ec007_state_isolation_extra_fields_excluded()`.

### AC-028 (traces to BC-2.09.008 EC-001 — Red Gate)
**Red Gate / Invalid input schema rejected before graph invocation:** When `tools/call`
arguments do not conform to the derived inputSchema for `S` (e.g., a required field is absent,
or a field has the wrong JSON type), the `mcp::server` validates call arguments against
`DynTool::schema()` per BC-2.09.007 {PC-005} BEFORE calling `invoke_dyn`. The server returns
JSON-RPC `{ "code": -32602, "message": "Invalid arguments for tool '<name>': <schema_error>" }`.
`GraphAgentTool::invoke_dyn` is never called; the graph is not invoked. Verified by
`test_BC_2_09_008_ec001_invalid_input_schema_rejected_before_graph_invoke()`.

### AC-029 (traces to BC-2.09.008 PC-006 — Deny-passthrough, Red Gate)
**Red Gate / Deny-passthrough under ForceApproveHooks:** Under
`GraphToolApprovalPolicy::ForceApproveHooks`, when a `PreToolCallHook` returns
`PreToolDecision::Deny` (a security-based or policy-based denial), `BoundaryApprovalHook`
passes the `Deny` through to the graph UNCHANGED. The tool is NOT invoked. `ForceApproveHooks`
overrides ONLY `PreToolDecision::PendingHumanApproval`; it does not convert security-based
`Deny` decisions to `Approve`. This is a Red Gate: without Deny-passthrough enforcement, a
hook that denies an unsafe tool invocation could be silently overridden to `Approve` under
`ForceApproveHooks`, bypassing the hook's security intent. Verified by
`test_BC_2_09_008_force_approve_hooks_deny_passes_through_unchanged()`.

### AC-030 (traces to BC-2.09.008 INV-004 + EC-009 — ActionRisk block, Red Gate)
**Red Gate / Mandatory ActionRisk runtime gate under ForceApproveHooks (unconditional pre-hook gate, fail-closed on None):**
Under `GraphToolApprovalPolicy::ForceApproveHooks`, `BoundaryApprovalHook` runs the `ActionRisk`
gate BEFORE invoking the inner `PreToolCallHook`. If `preview.action_risk` is `None` (un-annotated
tool — fail-closed, per the fail-closed default in {INV-004}) OR `Some(r)` where
`r >= ActionRisk::Medium` (e.g., `ActionRisk::High`), the hook MUST return `Deny` WITHOUT calling
the inner hook — this covers `AlwaysApprovePolicy` / no-hook default `Approve` paths (not only
`PendingHumanApproval`) — and:
- emit `E-MCP-011 ForceApproveWriteBlocked` (NOT `E-MCP-010`, which is `GraphAgentInterruptDenied`);
- log at ERROR level (`tracing::error!`) with structured key `mcp.graph_tool.force_approve_write_blocked`;
- NOT invoke the tool.
`None` (undeclared risk) fails closed identically to `Some(>= Medium)` — undeclared tools
require the highest gate per {INV-004}. If `preview.action_risk` is `Some(r)` where
`r < ActionRisk::Medium`, the inner `PreToolCallHook` is invoked normally. The gate fires
regardless of what the inner hook would have returned — including `AlwaysApprovePolicy` /
no-hook default `Approve` paths. Both the `None` case (TV-012: un-annotated tool →
`Deny` + `E-MCP-011`) and the `Some(High)` case (TV-008: `ActionRisk::High` →
`Deny` + `E-MCP-011`) must be tested, along with the `AlwaysApprovePolicy` inner hook case
(TV-018: `AlwaysApprovePolicy` + `Some(ActionRisk::High)` → `Deny` WITHOUT calling inner hook).
This is a Red Gate: without the `ActionRisk` check firing before the inner hook, `ForceApproveHooks`
would permit write-class tools and un-annotated tools to execute at an MCP boundary without any
human approval gate — even when the inner hook would unconditionally approve. Verified by
`test_BC_2_09_008_force_approve_hooks_action_risk_medium_emits_e_mcp_011_not_invoked()`
(TV-008, `Some(High)` path),
`test_BC_2_09_008_force_approve_hooks_action_risk_none_fails_closed_emits_e_mcp_011()`
(TV-012, `None`/undeclared path), and
`test_BC_2_09_008_force_approve_hooks_action_risk_gate_fires_before_inner_hook_tv018()`
(TV-018, `AlwaysApprovePolicy` inner hook + `Some(ActionRisk::High)` → `Deny` WITHOUT calling inner hook).

### AC-031 (traces to BC-2.09.008 INV-001 — error-path UUID sanitization, Red Gate)
**Red Gate / Mandatory UUID sanitization on all isError paths (STATE-ISOLATION — error-path
extension):** On any `isError: true` MCP response from a `GraphAgentTool` invocation,
`content[0].text` must NOT contain UUID-shaped values — two-pattern union, both
case-insensitive: pattern (1) canonical hyphenated form
`[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; pattern (2) simple
no-hyphen form `\b[0-9a-f]{32}\b` (covers `Uuid::simple()` 32-contiguous-hex rendering).
These may represent run IDs or server-layer thread IDs (both `Uuid` types) leaking internal
graph execution context. The `sanitize_internal_ids` pass covers UUID-shaped IDs ONLY:
`run_id` (`Uuid`) and server-layer `thread_id` (`Uuid`). It does NOT cover `u64`
`CheckpointId` values (per BC-2.09.008 {INV-001}/TV-013 — `u64` passes through unsanitized;
authoring-site convention is the sole guarantee for `CheckpointId` safety; see AC-036). The
STATE-ISOLATION guarantee ({INV-001}) extends to error paths. The framework applies two
unconditional sanitization passes to `isError: true` responses: (1) `redact_credentials`
(existing, AC-025); (2) `sanitize_internal_ids` — two-pattern union (both case-insensitive):
pattern (1) hyphenated `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`;
pattern (2) simple no-hyphen `\b[0-9a-f]{32}\b`; chained after `redact_credentials`.
Node implementations must not rely on framework sanitization — error messages must exclude
internal IDs at the authoring site. BC-2.09.008 TV-009 verifies: a graph node returning
`Err(PregolyaError { message: "operation failed for run <example-run-id>", .. })`
produces a response where `content[0].text` does NOT contain the UUID. The Red Gate test
fixture MUST include at least one non-v4 UUID (e.g., a UUID with version nibble ≠ 4,
such as a v7-format UUID) to ensure the test FAILS against a v4-only regex and
prevents false-green regression. In addition, the fixture MUST include a simple-form
(no-hyphen, 32 contiguous hex digits) `run_id` matching pattern `[0-9a-f]{32}`
(`Uuid::simple()` rendering) to verify that pattern (2) `\b[0-9a-f]{32}\b` strips the
no-hyphen form — POSITIVE fixture per BC-2.09.008 TV-014: input message containing a
`{SIMPLE-UUID}` (32-char no-hyphen hex value) in `"operation failed for run {SIMPLE-UUID}"` →
`content[0].text` MUST NOT contain the `{SIMPLE-UUID}` value.
This is a Red Gate: without `sanitize_internal_ids`, internal
graph execution identifiers would leak to external MCP clients via error messages. Verified by
`test_BC_2_09_008_error_path_uuid_sanitization_strips_internal_ids()`.

### AC-032 (traces to BC-2.09.008 INV-005 — extract_output credential opacity)
**extract_output success-path is NOT framework-sanitized (caller/DI-010 obligation):** The
`extract_output` closure is the sole data-exit path on the success path ({INV-001}). The
framework does NOT apply `redact_credentials` or `sanitize_internal_ids` to the success-path
result of `extract_output`. A caller providing
`extract_output = |s: &serde_json::Value| json!({ "api_key": s["api_key"] })` with `api_key = "sk-abc123"` in
the final graph state will receive a response where `content[0].text` contains
`"api_key":"sk-abc123"` VERBATIM — the framework does not strip it post-hoc. The DI-010
Credential Opacity obligation is the CALLER's responsibility: `extract_output` must not select
credential-bearing fields. BC-2.09.008 TV-010 verifies this boundary: the success path asserts
the leaking output IS preserved (framework does not sanitize it). Verified by
`test_BC_2_09_008_extract_output_success_path_framework_does_not_sanitize()`.

### AC-033 (traces to BC-2.09.008 EC-010 — extract_output panic recovery, Red Gate)
**Red Gate / extract_output panic caught via `FutureExt::catch_unwind` inside `invoke_dyn` —
static response:** When the `extract_output` closure provided to `GraphAgentTool::from_graph`
panics during execution after successful graph completion (a programming error in the
caller-supplied closure), the panic occurs during `.await` polling of
`runner.run(input, policy)` inside `GraphAgentTool::invoke_dyn`. The recovery mechanism MUST
be `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy)))`
applied INSIDE `GraphAgentTool::invoke_dyn` at the awaited call site. Synchronous
`std::panic::catch_unwind` is INADEQUATE for this path — because `extract_output` fires during
`.await` polling, a synchronous catch placed outside the async call chain does not intercept
the panic. The response MUST be:
`{ "content": [{ "type": "text", "text": "internal error" }], "isError": true }`.
The response text is the static string `"internal error"` — no panic message, backtrace, or
internal state is forwarded to the external MCP client. Server availability is preserved: a
subsequent valid `tools/call` to a different (non-panicking) tool still returns `isError: false`.
BC-2.09.008 TV-011 verifies this scenario. The Red Gate test MUST drive the panic through
`.await` polling (the panic is injected inside the async future body such that a
synchronous-only `std::panic::catch_unwind` placed outside the future would fail to catch it).
This is a Red Gate: without `FutureExt::catch_unwind` wrapping, a panicking `extract_output`
closure propagates through the async runtime, crashing the server process (remote DoS,
CWE-248). See also AC-037 for the SEC-008 `panic = "unwind"` build-profile prerequisite.
Verified by `test_BC_2_09_008_ec010_extract_output_panic_caught_unwindsafe_static_response()`.

### AC-034 (traces to BC-2.09.007 PC-002 — success-path credential boundary)
**BC-2.09.007 success-path: framework does NOT sanitize `DynTool::invoke_dyn` success results (DI-010
caller obligation):** The framework applies `redact_credentials` to **error paths only** (see
BC-2.09.007 {INV-003} and AC-013). Success-path `result_text` (from `DynTool::invoke_dyn`
returning `Ok(serde_json::Value)`) is NOT framework-sanitized.
`DynTool` implementations MUST NOT embed credential material in success results; the
DI-010 Credential Opacity obligation binds every `DynTool` implementation (caller/registration
obligation, not server obligation). BC-2.09.007 TV-009 verifies this boundary: a `MockTool`
returning `Ok(Value::String("key=sk-abc123XYZabc123XYZabc"))` on the success path
produces a response where `content[0].text` equals `"key=sk-abc123XYZabc123XYZabc"` verbatim
— the key material is preserved; the framework does not strip it. Verified by
`test_BC_2_09_007_success_path_credential_boundary_framework_does_not_sanitize()`.

### AC-035 (traces to BC-2.09.008 INV-005 + DI-010 — caller-obligation credential-key scoping, validates {INV-005} Phase-3 obligation)
**Testable {INV-005} caller obligation — correct `extract_output` excludes credential keys:** A
`serde_json::Value` representing graph state is constructed as
`json!({ "answer": "hello", "api_key": "sk-abc123XYZabc123XYZabc" })`. An `extract_output`
closure scoped to `|s: &serde_json::Value| json!({ "answer": s["answer"] })` is provided to
`GraphAgentTool::from_graph` along with a caller-derived `input_schema`. After a successful
graph run producing this final state, the MCP response
`content[0].text` MUST equal `"{\"answer\":\"hello\"}"` — the `api_key` key MUST NOT appear
in the output. This test demonstrates that credential safety on the success path is a **CALLER
obligation** (DI-010): when `extract_output` is correctly scoped to non-credential output keys,
credential material does not reach the MCP client. The framework provides no runtime backstop;
the closure author bears the full DI-010 obligation. This makes the standing {INV-005}
risk-acceptance item a testable Phase-3 obligation. Verified by
`test_BC_2_09_008_inv005_credential_opacity_correct_closure_excludes_credentials()`.

### AC-036 (traces to BC-2.09.008 INV-001 + TV-013 — u64 CheckpointId passthrough, correctness boundary)
**Correctness boundary — `u64` `CheckpointId` values are NOT UUID-shaped and MUST NOT be
stripped by `sanitize_internal_ids`:** When a graph-node returns
`Err(PregolyaError { message: "failed to load checkpoint 42", .. })` on an error path, the
`sanitize_internal_ids` pass leaves the message UNCHANGED — `content[0].text` MUST equal
`"failed to load checkpoint 42"` verbatim after sanitization. The decimal integer `42` is
not UUID-shaped and does not match the version-agnostic pattern
`[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`. The
`sanitize_internal_ids` pass covers UUID-shaped IDs ONLY (`run_id` and server-layer
`thread_id`, both `Uuid` types); the `u64` `CheckpointId` passes through unsanitized.
Authoring-site convention — not embedding checkpoint IDs in error messages — is the SOLE
guarantee for `CheckpointId` safety; the framework provides no backstop (per
BC-2.09.008 {INV-001}/TV-013). BC-2.09.008 TV-013 verifies this boundary. Verified by
`test_BC_2_09_008_tv013_u64_checkpoint_id_passes_through_sanitize_unchanged()`.

### AC-037 (traces to BC-2.09.008 EC-010 — SEC-008 panic-profile build obligation)
**Build-profile prerequisite (SEC-008) — `panic = "unwind"` required in release profile:**
The workspace `Cargo.toml` release profile MUST pin `panic = "unwind"`. If the release
profile sets `panic = "abort"`,
`futures::future::FutureExt::catch_unwind(AssertUnwindSafe(...))` is voided — the process
aborts on panic instead of unwinding, bypassing the catch and exposing a remote
denial-of-service (CWE-248). This is a Phase-3 devops-engineer obligation (workspace
`Cargo.toml` authoring). The pregolya-mcp story-level obligation: the implementing engineer
MUST add a `// SEC-008: panic = "unwind" required — FutureExt::catch_unwind voids under abort`
comment in `pregolya-mcp/Cargo.toml` or at the `invoke_dyn` call site to document the
dependency. The devops-engineer asserts the workspace profile at Phase-3 workspace init.
Verified by devops-engineer at Phase-3; implementer obligation is the comment annotation.
(See AC-033 for the `catch_unwind` mechanism; see BC-2.09.008 EC-010/TV-011.)

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `McpServer` | `pregolya-mcp/src/server.rs` | effectful (binds transport, accepts connections) |
| `McpServerConfig` | `pregolya-mcp/src/server.rs` | pure-core (config struct) |
| `McpServerHandle` | `pregolya-mcp/src/server.rs` | effectful (shutdown triggers I/O) |
| `ToolRegistry` | `pregolya-mcp/src/registry.rs` | pure-core (Arc-wrapped HashMap; thread-safe reads) |
| `tools/list` handler | `pregolya-mcp/src/server.rs` | pure-core (reads registry, serializes; no I/O beyond response) |
| `tools/call` handler | `pregolya-mcp/src/server.rs` | effectful (invokes registered `DynTool`) |
| `GraphAgentTool` | `pregolya-mcp/src/graph_tool.rs` | effectful (invokes `GraphRunner::run`; LLM + tool I/O) |
| `GraphToolApprovalPolicy` | `pregolya-mcp/src/graph_tool.rs` | pure-core (enum; DenyInterrupts / ForceApproveHooks) |
| `BoundaryApprovalHook` | `pregolya-mcp/src/graph_tool.rs` | pure-core (intercepts PreToolCallHook; no I/O; returns Approve or Deny) |
| `sanitize::redact_credentials` | `pregolya-mcp/src/sanitize.rs` | pure-core (regex substitution; shared with server.rs error paths) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `McpServerConfig` | pure-core | Configuration data only; no I/O |
| `ToolRegistry` | pure-core | Thread-safe in-memory map behind `Arc<RwLock<...>>`; read-only in list handler |
| `tools/list` handler | pure-core | Reads registry (in-memory), serializes to JSON; no outbound I/O |
| `McpServer::start` | effectful | Binds TCP/stdio; effectful from the first syscall |
| `tools/call` handler | effectful | Invokes `DynTool::invoke_dyn` which may perform I/O |
| `GraphAgentTool` | effectful | Calls `GraphRunner::run` which performs LLM API I/O and tool invocations |
| `GraphToolApprovalPolicy` | pure-core | Enum discriminating interrupt handling policy; no I/O |
| `BoundaryApprovalHook` | pure-core | Intercepts `PreToolCallHook`; returns `Approve` or `Deny { reason }`; no I/O |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | SSE bind address already in use | `Err(E-MCP-005 McpServerBindFailed)` — BC-2.09.006 EC-001 |
| EC-002 | Tool registered after server start; `tools/list` called | New tool included — registry read on each request |
| EC-003 | `tools/call` with tool registered after server start | Invocation succeeds — same dynamic read semantics |
| EC-004 | `McpServerHandle::shutdown()` during active `tools/call` in-flight | In-flight call completes; response is sent; no new requests accepted |
| EC-005 | Tool invocation exceeds `BudgetPolicy` limit | `isError: true` with message "run halted: budget ceiling reached" — BC-2.09.007 EC-004 |
| EC-006 | Two concurrent `tools/call` for different tools | Both complete independently; no cross-call state |
| EC-007 | `GraphAgentTool`: node `interrupt()` under DenyInterrupts | `isError: true`, E-MCP-010, interrupted run NOT persisted — BC-2.09.008 EC-004, {INV-002} |
| EC-008 | `GraphAgentTool`: `extract_output` selects subset of fields | Only selected fields in response; extra fields excluded — BC-2.09.008 EC-007, {INV-001} |
| EC-009 | `GraphAgentTool`: `ForceApproveHooks` + node `interrupt()`; tool has `action_risk = Some(ActionRisk::ReadOnly)` (gate approves, `ReadOnly < Medium`) | Inner hook invoked; `PendingHumanApproval` overridden to `Approve`; node interrupt still → E-MCP-010. Note: `action_risk = None` or `>= Medium` → gate-denied WITHOUT calling inner hook per EC-011 ({INV-004}) — BC-2.09.008 EC-006, {INV-002} |
| EC-010 | `GraphAgentTool`: `extract_output` returns `Value::Null` | `result_text = "null"`, `isError: false` — BC-2.09.008 EC-008 |
| EC-011 | `GraphAgentTool`: `ForceApproveHooks` + tool with `ActionRisk::High` (TV-008) or un-annotated `action_risk = None` (TV-012) — `ActionRisk` gate fires BEFORE invoking inner hook (covers `AlwaysApprovePolicy`/no-hook default `Approve` paths, not only `PendingHumanApproval`); TV-018 (`AlwaysApprovePolicy` + `Some(ActionRisk::High)`) | `Deny` + `E-MCP-011` + ERROR log (`tracing::error!`) at `mcp.graph_tool.force_approve_write_blocked`; inner hook NOT called; tool NOT invoked; `None` fails closed identically to `Some(>=Medium)` — BC-2.09.008 EC-009, {INV-004} |
| EC-012 | `GraphAgentTool`: `extract_output` closure panics after successful graph completion | `isError: true`, `content[0].text == "internal error"` (static); server continues serving subsequent requests — BC-2.09.008 EC-010 |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~6,200 |
| BC files (3 BCs; BC-2.09.006, BC-2.09.007, BC-2.09.008) | ~10,400 |
| `module-decomposition.md` SS-09 section | ~400 |
| `pregolya-mcp/src/server.rs` (new) | ~1,200 |
| `pregolya-mcp/src/registry.rs` (new) | ~500 |
| `pregolya-mcp/src/graph_tool.rs` (new) | ~1,800 |
| `pregolya-mcp/src/sanitize.rs` (new; includes `sanitize_internal_ids`) | ~550 |
| Test files (~220 lines; AC-001–AC-037 + 12 Red Gates) | ~3,200 |
| Tool outputs | ~600 |
| **Total** | **~24,850** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~12%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-037, including Red Gates: AC-013 (credential redaction VP-015), AC-023 (STATE-ISOLATION VP-016), AC-024 (binary interrupt invariant), AC-025 (GraphAgentTool error paths redaction), AC-026 (node interrupt → E-MCP-010), AC-027 (extra fields excluded VP-016), AC-028 (invalid input → -32602), AC-029 (Deny passthrough under ForceApproveHooks), AC-030 (ActionRisk block → E-MCP-011), AC-031 (error-path UUID sanitization — fixture MUST include a non-v4 UUID), AC-033 (extract_output panic via `.await` polling → static 'internal error'); AC-035 is a passing test (not a Red Gate — tests that correct closure excludes credentials); AC-036 is a correctness-boundary test (u64 passthrough); AC-037 is a build-profile annotation obligation (devops-engineer Phase-3) (test-writer step)
2. [ ] **Red Gate check (AC-013):** confirm `test_BC_2_09_007_error_message_credential_redaction_applies_3_patterns()` FAILS before `pregolya_mcp::sanitize::redact_credentials` is implemented (raw key material reaches response text)
3. [ ] Register `E-MCP-005 McpServerBindFailed` in error taxonomy (TRANSPORT, broken, Never)
4. [ ] Create `pregolya-mcp/src/registry.rs` — `ToolRegistry` with `Arc<RwLock<HashMap<String, Arc<dyn DynTool>>>>`
5. [ ] Create `pregolya-mcp/src/server.rs` — `McpServer`, `McpServerConfig`, `McpServerHandle`, `McpServerTransport` enum
6. [ ] Implement `McpServer::start` — bind stdio or SSE; return `Err(E-MCP-005)` on failure
7. [ ] Implement `tools/list` handler — read registry on each request; serialize to MCP ToolDefinition
8. [ ] Implement `tools/call` handler — look up tool in registry; invoke; format CallToolResult
9. [ ] Implement JSON-RPC error responses for tool-not-found (-32602) and invalid-params (-32602)
10. [ ] Implement `McpServerHandle::shutdown()` — graceful connection teardown
11. [ ] Verify `DynTool` object safety in server context (same seam as S-2.10)
12. [ ] Implement `pregolya_mcp::sanitize::redact_credentials(text: &str) -> Cow<str>` — 3 pattern substitutions (sk-*, sk-ant-*, 64-char token → `<redacted>`); source-restrict to `PregolyaError::message` in `tools/call` error handler (AC-013 / BC-2.09.007 {INV-003})
13. [ ] Implement JSON-RPC -32700 parse-error response for non-JSON bytes on both tools/list and tools/call paths (AC-014 / BC-2.09.006 EC-006 + BC-2.09.007 EC-007)
14. [ ] Implement JSON-RPC -32600 invalid-request response for malformed-but-valid-JSON requests (AC-015 / BC-2.09.006 EC-007 + BC-2.09.007 EC-008)
15. [ ] Implement `result_text` selection in `tools/call` handler: `Value::String(s)` → `result_text = s` verbatim; other `Value` variants → `result_text = serde_json::to_string(&value)` (compact JSON) (AC-016 / BC-2.09.007 {PC-002})
16. [ ] Run `cargo nextest run -p pregolya-mcp` — AC-001–AC-016 green (server + registry baseline)
17. [ ] Create `pregolya-mcp/src/graph_tool.rs` — `GraphAgentTool` struct (non-generic; runner erased via `Arc<dyn GraphRunner>`), `GraphToolApprovalPolicy` enum, `BoundaryApprovalHook` internal struct, `GraphRunner` type-erased trait; non-generic `from_graph` constructor (no type parameters; caller passes `Arc<CompiledStateGraph>`, `schemars::Schema`, and `extract_output: impl Fn(&serde_json::Value) -> serde_json::Value`)
18. [ ] Implement `GraphAgentTool::from_graph` — accept `name`, `description`, `Arc<CompiledStateGraph>`, `input_schema: schemars::Schema` (caller-derived), `extract_output: impl Fn(&serde_json::Value) -> serde_json::Value` closure; store `input_schema` directly for `DynTool::schema()` (AC-017 / BC-2.09.008 PC-001)
19. [ ] Implement `DynTool` for `GraphAgentTool` — `name()`, `description()`, `schema()` returning stored `schemars::Schema`, `invoke_dyn()` dispatching graph execution (AC-018 / BC-2.09.008 PC-002)
20. [ ] **Red Gate check (AC-023):** confirm `test_BC_2_09_008_state_isolation_only_extract_output_in_result()` FAILS before STATE-ISOLATION enforcement is implemented (extra fields leak into the `serde_json::Value` returned by `invoke_dyn` without explicit exclusion)
21. [ ] **Red Gate check (AC-026):** confirm `test_BC_2_09_008_ec004_node_interrupt_deny_policy_e_mcp_010()` FAILS before E-MCP-010 interrupt-denied path is implemented
22. [ ] Implement `BoundaryApprovalHook` — DenyInterrupts path: override `PendingHumanApproval` → `Deny { reason: "HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY" }`; ForceApproveHooks path: run `ActionRisk` gate BEFORE calling inner hook (task 33); if `None` or `>= ActionRisk::Medium` → `Deny` + `E-MCP-011` WITHOUT calling inner hook (covers `AlwaysApprovePolicy`/no-hook default `Approve`); if `< ActionRisk::Medium` → call inner hook; if inner hook returns `PendingHumanApproval` → override to `Approve` (task 31); `Deny` from inner hook passes through unchanged (AC-021, AC-022, AC-029 / BC-2.09.008 PC-005/PC-006)
23. [ ] Implement `ConcreteGraphRunner::run` to call `(self.extract_output)(&final_state: &serde_json::Value)` INSIDE `run()` before returning `serde_json::Value` to `invoke_dyn`. `invoke_dyn` receives the `serde_json::Value` returned by `run()` and returns it as `Ok(value: serde_json::Value)` without re-filtering. An inline comment is required at the `extract_output` call site (see VP-016 §Proof Obligations Canonical Seam Statement obligation). (AC-023, AC-027 / BC-2.09.008 INV-001; ADR-029 §Decision 3; VP-016 proptest `graph_agent_tool_state_isolation` harness)
24. [ ] Register `E-MCP-010 GraphAgentInterruptDenied` in error taxonomy (EXEC, broken, Never) — note: NOT E-MCP-006 (that code is McpContentUnsupported, minted burst-240; PO-authoritative mint is E-MCP-010 per ADR-029 §Decision 5)
25. [ ] Extend `pregolya_mcp::sanitize::redact_credentials` usage to cover all `GraphAgentTool` isError paths — E-MCP-010 interrupt error and `Err(PregolyaError)` from graph execution (AC-025 / BC-2.09.008 INV-003)
26. [ ] Add `schemars` dependency to `pregolya-mcp/Cargo.toml` (workspace pin)
27. [ ] Add `pregolya-graph` to `pregolya-mcp/Cargo.toml` in two places: (a) `[dependencies]` entry with workspace pin — required for `GraphAgentTool` non-test production code (`Arc<CompiledStateGraph>` usage; BC-2.09.008/ADR-029 dep edge); (b) `[dev-dependencies]` entry with `features = ["test-util"]` — required so the VP-016 proptest harness (`graph_agent_tool_state_isolation`) can call `CompiledStateGraph::stub_terminal` cross-crate; `stub_terminal` is gated under pregolya-graph's `test-util` feature and is invisible to the linker unless that feature is activated in a dev build. Both entries are necessary: the `[dependencies]` entry alone does not activate `test-util`, and the `[dev-dependencies]` entry alone does not expose pregolya-graph to non-test production code.
28. [ ] Update `pregolya-mcp/src/lib.rs` — re-export `GraphAgentTool`, `GraphToolApprovalPolicy`; expose `graph_tool` module
29. [ ] Run `cargo nextest run -p pregolya-mcp` — AC-001–AC-028 green (pre-security-hardening baseline; run again after tasks 30–39)
30. [ ] **Red Gate check (AC-029):** confirm `test_BC_2_09_008_force_approve_hooks_deny_passes_through_unchanged()` FAILS before Deny-passthrough enforcement is implemented (Deny would be incorrectly converted to Approve)
31. [ ] Implement Deny-passthrough in `BoundaryApprovalHook` under `ForceApproveHooks` — verify `PreToolDecision::Deny` is not converted to `Approve`; only `PendingHumanApproval` is eligible for override (AC-029 / BC-2.09.008 PC-006)
32. [ ] **Red Gate check (AC-030):** confirm `test_BC_2_09_008_force_approve_hooks_action_risk_medium_emits_e_mcp_011_not_invoked()` FAILS before `ActionRisk` gate is implemented (write-class tool would be invoked without the check)
33. [ ] Implement `ActionRisk` runtime gate in `BoundaryApprovalHook` — run the gate BEFORE invoking the inner `PreToolCallHook` (unconditional gate; covers `AlwaysApprovePolicy`/no-hook default `Approve` paths, not only `PendingHumanApproval`); if `None` (un-annotated tool, fail-closed) OR `>= ActionRisk::Medium` return `Deny` + emit `E-MCP-011 ForceApproveWriteBlocked` + ERROR log (`tracing::error!`) at `mcp.graph_tool.force_approve_write_blocked` WITHOUT calling the inner hook; `None` fails closed identically to `Some(>= Medium)` per {INV-004}; register `E-MCP-011` in error taxonomy; implement three test paths: TV-008 (`Some(High)`), TV-012 (`None`/undeclared), and TV-018 (`AlwaysApprovePolicy` inner hook + `Some(ActionRisk::High)` → `Deny` WITHOUT calling inner hook) (AC-030 / BC-2.09.008 INV-004, EC-009)
34. [ ] **Red Gate check (AC-031):** confirm the AC-031 Red Gate test FAILS before `sanitize_internal_ids` is implemented (UUID — any version — leaks to response text on isError paths; the fixture MUST include a non-v4 UUID (version nibble ≠ 4) so the test also fails against a v4-only regex, preventing false-green regression)
35. [ ] Implement `sanitize_internal_ids(text: &str) -> Cow<str>` in `pregolya_mcp::sanitize` — two-pattern union (both case-insensitive): (1) canonical hyphenated form `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; (2) simple no-hyphen form `\b[0-9a-f]{32}\b` (covers `Uuid::simple()` rendering — 32 contiguous hex digits; `\b` word-boundary prevents over-matching within 64-char SHA-256 digests at the isolation layer per TV-017 (`sanitize_internal_ids` alone does not strip a 64-char hex sequence; TV-015 verifies the full pipeline: `redact_credentials` catches it first → `"digest: <redacted>"`) and underscore-flanked tokens per TV-016); together these cover all standard uuid-crate rendering forms including Display (hyphenated) and simple() (contiguous hex). Covers `run_id` and server-layer `thread_id` (both `Uuid` types); does NOT strip `u64` decimal integers (AC-036 correctness boundary); chain after `redact_credentials` on all `GraphAgentTool` `isError: true` paths (AC-031, AC-036 / BC-2.09.008 INV-001/TV-013/TV-014/TV-015/TV-017)
36. [ ] **Red Gate check (AC-033):** confirm `test_BC_2_09_008_ec010_extract_output_panic_caught_unwindsafe_static_response()` FAILS when only synchronous `std::panic::catch_unwind` is used (unhandled panic crashes the handler because `extract_output` panics during `.await` polling — synchronous catch is INADEQUATE for this async path; no `isError` response is produced)
37. [ ] Implement panic recovery for `extract_output` invocation inside `GraphAgentTool::invoke_dyn`: use `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy)))` at the `.await` call site (NOT `std::panic::catch_unwind` — that is synchronous and inadequate for this async path); catch yields `isError: true`, `content[0].text == "internal error"` (static; no panic message or backtrace forwarded); ensure server continues serving subsequent requests; add `futures` to `pregolya-mcp/Cargo.toml` `[dependencies]` with workspace pin if not already present; `AssertUnwindSafe` is `std::panic::AssertUnwindSafe` (AC-033, AC-037 / BC-2.09.008 EC-010/SEC-008)
38. [ ] Write boundary test confirming success-path `serde_json::Value` result is NOT framework-sanitized: `MockTool` returning `Ok(Value::String("key=sk-abc123XYZabc123XYZabc".to_string()))` → assert `content[0].text` equals `"key=sk-abc123XYZabc123XYZabc"` verbatim (AC-034 / BC-2.09.007 PC-002)
39. [ ] Write boundary test confirming `extract_output` success-path result is NOT framework-sanitized: closure selecting `api_key` field → assert success response preserves value verbatim (AC-032 / BC-2.09.008 INV-005)
40. [ ] Run `cargo nextest run -p pregolya-mcp` — all 37 ACs green (AC-001–AC-037)
41. [ ] Write passing test for AC-035 — `test_BC_2_09_008_inv005_credential_opacity_correct_closure_excludes_credentials()`: construct state value `json!({ "answer": "hello", "api_key": "sk-abc123XYZabc123XYZabc" })`; provide closure `|s: &serde_json::Value| json!({ "answer": s["answer"] })`; assert MCP response `content[0].text == "{\"answer\":\"hello\"}"` — no `api_key` field in output (AC-035 / BC-2.09.008 INV-005, DI-010)
42. [ ] Write boundary test for AC-036 — `test_BC_2_09_008_tv013_u64_checkpoint_id_passes_through_sanitize_unchanged()`: construct graph returning `Err(PregolyaError { message: "failed to load checkpoint 42", .. })`; assert `content[0].text == "failed to load checkpoint 42"` verbatim after `sanitize_internal_ids` (u64 decimal integer is not UUID-shaped; no stripping applied; BC-2.09.008 TV-013)
43. [ ] Verify `sanitize_internal_ids` does NOT over-strip `u64` CheckpointId values — run `test_BC_2_09_008_tv013_u64_checkpoint_id_passes_through_sanitize_unchanged()` both before and after implementing `sanitize_internal_ids`; both runs must pass (AC-036 correctness boundary; if this test fails after implementation, the regex is over-aggressive and strips non-UUID decimal content — fix the pattern)
44. [ ] Add SEC-008 comment annotation in `pregolya-mcp/Cargo.toml` or at the `FutureExt::catch_unwind` call site in `invoke_dyn`: `// SEC-008: panic = "unwind" required in release profile — FutureExt::catch_unwind is voided under panic = "abort"; devops-engineer asserts workspace profile at Phase-3 init` (AC-037 / BC-2.09.008 EC-010)

## Previous Story Intelligence (MANDATORY)

S-2.10 established `MultiServerMcpClient`, `McpSessionGuard`, and the `pregolya-mcp` crate
structure (files: `client.rs`, `session.rs`, `discovery.rs`, `interceptor.rs`, `ingress.rs`,
`exception.rs`, `lib.rs`). S-2.10 does NOT create `registry.rs` or `ToolRegistry`.
S-2.11 introduces `ToolRegistry` for the first time (task 4 creates
`pregolya-mcp/src/registry.rs`). S-2.11 adds the complementary server role in the same crate, introducing `ToolRegistry` as
a standalone `mcp::registry` module (SS-09, architect OPTION A). The registry is read by
`mcp::server` (tools/list dispatch: BC-2.09.006 {PC-002}; tools/call dispatch: BC-2.09.007 {PC-001}); populated by the
application/caller layer via the standard `ToolRegistry` registration API
(BC-2.09.006 {PRE-001} + BC-2.09.008 {PC-002}); typical flow: caller calls `client.get_tools()`
→ caller registers returned tools via `registry.register(name, tool)`; `mcp::client` does NOT
write the registry. Injected via `Arc<ToolRegistry>` — not embedded in either module and there
is no "extract if needed" hedge.

S-1.06 established `DynTool` as the object-safe dispatch seam. The `tools/call` handler
calls `DynTool::invoke_dyn(args)`. Use `ToolRegistry::get(name: &str) -> Option<Arc<dyn DynTool>>`
as specified in BC-2.09.007 Architecture Anchors — `Option<Arc<dyn DynTool>>`, NOT
`Option<Arc<dyn Tool>>` (which is non-object-safe per ADR-005 §Adjacent Trait Object-Safety Adjudications).

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `ToolRegistry::get` returns `Option<Arc<dyn DynTool>>` (not `dyn Tool`) | ADR-005 §Adjacent Trait Object-Safety Adjudications; BC-2.09.007 Architecture Anchors | Compile check |
| `McpServer` in `mcp::server` module — distinct from `mcp::client` | ADR-013 §Consequences; BC-2.09.006 Architecture Anchors | Module structure |
| `isError: true` is in the JSON-RPC `result` layer — not `error` | BC-2.09.007 {INV-002} | Test AC-012 |
| `E-MCP-005` category: TRANSPORT, severity: broken, retry_hint: Never | BC-2.09.006 §Error code minted | Error taxonomy registration |
| `pregolya_mcp::sanitize::redact_credentials` applied to `PregolyaError::message` before MCP response; source-restriction: never `.source()`/`Debug`/`Display` | BC-2.09.007 {INV-003} (mandatory, no hedge) | Test AC-013 Red Gate |
| Malformed JSON bytes → JSON-RPC `-32700 Parse error` (wire-protocol only, no PregolyaError) | BC-2.09.006 EC-006, BC-2.09.007 EC-007 | Tests AC-014 |
| Invalid JSON-RPC structure → JSON-RPC `-32600 Invalid Request` (wire-protocol only) | BC-2.09.006 EC-007, BC-2.09.007 EC-008 | Tests AC-015 |
| `DynTool::invoke_dyn` returns `serde_json::Value`; `Value::String(s)` → verbatim `result_text`; other variants → `serde_json::to_string` (compact) | BC-2.09.007 {PC-002} | Test AC-016 |
| No `from_value::<S>` call anywhere in `mcp::graph_tool`; `CompiledStateGraph::invoke` accepts `serde_json::Value` directly — no generic deserialization step (non-generic `GraphAgentTool` seam) | BC-2.09.008 {PC-003}; non-generic `GraphAgentTool` design | Code review; `from_value::<` must not appear in `graph_tool.rs` |
| No `unwrap()`/`expect()` in server handlers | CLAUDE.md Code Conventions | Clippy |
| Registry read on each `tools/list` request (no startup snapshot) | BC-2.09.006 {PC-003} | Test AC-004 |
| `GraphAgentTool::from_graph` accepts a caller-supplied `input_schema: schemars::Schema` parameter (no `schema_for!` call inside `from_graph`); the schema is stored for `DynTool::schema()` | BC-2.09.008 {PC-001} | Test AC-017 |
| STATE-ISOLATION is enforced by `GraphRunner::run` via `extract_output(&final_state)`; `invoke_dyn` performs no re-filtering (ADR-029 §Decision 3 canonical seam statement). If `invoke_dyn` applies any output filtering of its own, this violates the seam contract. | BC-2.09.008 INV-001; VP-016; ADR-029 §Decision 3 | Test AC-023 Red Gate |
| Node-level `interrupt()` parking under DenyInterrupts → `Err(E-MCP-010)`; `BoundaryApprovalHook::Deny` continues to own terminal (NOT E-MCP-010); NO `Ok` when `RunStatus::Interrupted` | BC-2.09.008 INV-002 binary interrupt invariant | Test AC-024 Red Gate |
| `E-MCP-010` (not E-MCP-006) is the error code for `GraphAgentInterruptDenied` | BC-2.09.008 §Error Codes; ADR-029 §Decision 5 | Error taxonomy; test AC-026 |
| All `GraphAgentTool` isError paths MUST pass through `redact_credentials`; source-restriction: only `PregolyaError::message` MUST be used as text source; `.source()`/`Debug`/`Display` MUST NOT be used | BC-2.09.008 INV-003 (mandatory, no hedge) | Test AC-025 Red Gate |
| `ForceApproveHooks` `BoundaryApprovalHook` runs `ActionRisk` gate BEFORE invoking inner `PreToolCallHook`; `None`/`>= ActionRisk::Medium` denied WITHOUT calling inner hook (covers `AlwaysApprovePolicy`/no-hook default `Approve`); `< ActionRisk::Medium` → inner hook called; `PendingHumanApproval` from inner hook overridden to `Approve`; `Deny` from inner hook passes through UNCHANGED; node-level `interrupt()` still → E-MCP-010 | BC-2.09.008 PC-006, INV-002, INV-004 | Tests AC-022, AC-029, AC-030 |
| `preview.action_risk` is `None` (un-annotated, fail-closed per {INV-004}) or `>= ActionRisk::Medium` under `ForceApproveHooks` → `Deny` + `E-MCP-011 ForceApproveWriteBlocked` (NOT `E-MCP-010`) + ERROR log (`tracing::error!`) at `mcp.graph_tool.force_approve_write_blocked`; `None` fails closed identically to `Some(>= Medium)` | BC-2.09.008 INV-004, EC-009 | Tests AC-030 Red Gate (TV-008 Some(High); TV-012 None) |
| `isError: true` error paths apply two unconditional sanitization passes: (1) `redact_credentials`, (2) `sanitize_internal_ids` — two-pattern union (both case-insensitive): pattern (1) hyphenated `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; pattern (2) simple no-hyphen `\b[0-9a-f]{32}\b` (covers `Uuid::simple()` rendering; `\b` prevents 64-hex-split and underscore-flanked-strip); covers `run_id` and server-layer `thread_id` only; `u64` `CheckpointId` is NOT UUID-shaped and passes through unchanged; in that order | BC-2.09.008 INV-001 | Tests AC-031 Red Gate (TV-013/TV-014), AC-036 correctness boundary |
| `extract_output` success-path result is NOT framework-sanitized; DI-010 credential opacity is caller/registration obligation | BC-2.09.008 INV-005; BC-2.09.007 PC-002 | Tests AC-032, AC-034 |
| `extract_output` panic caught via `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy)))` INSIDE `GraphAgentTool::invoke_dyn` at the `.await` call site; synchronous `std::panic::catch_unwind` is INADEQUATE (panic occurs during `.await` polling); response is static `"internal error"` (`isError: true`); server continues serving; SEC-008: workspace release profile MUST pin `panic = "unwind"` | BC-2.09.008 EC-010; SEC-008 | Tests AC-033 Red Gate, AC-037 build obligation |

**Forbidden dependencies:** `pregolya-mcp` (including `mcp::client` from S-2.10, `mcp::server`,
and `mcp::graph_tool` from this story) must NOT depend on `pregolya-server`,
`pregolya-vectorstores`, or `pregolya-standard-tests`. Note: `pregolya-mcp` DOES depend on
`pregolya-graph` — this dependency is intentionally introduced by BC-2.09.008
`GraphAgentTool` wrapping (ADR-029 dep edge; task 27). The `mcp::client` and `mcp::server`
modules do NOT share mutable state per BC-2.09.006 {INV-005}. If `pregolya-mcp` gains a
dependency on `pregolya-server`, `pregolya-vectorstores`, or `pregolya-standard-tests`, the
build MUST fail.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `rmcp` | workspace pin | MCP protocol SDK — `tools/list` and `tools/call` server-side handlers |
| `tokio` | workspace pin | Async server task; `RwLock` for registry |
| `serde_json` | workspace pin | `ToolDefinition` serialization; `CallToolResult` formatting |
| `tracing` | workspace pin | Structured logging for server lifecycle events (SAP-1) |
| `schemars` | workspace pin | `schemars::Schema` type for the caller-supplied `input_schema` parameter of `GraphAgentTool::from_graph`; caller derives via `schemars::schema_for!` at the call site (BC-2.09.008 {PC-001}) |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-mcp/src/server.rs` | CREATE | `McpServer`, `McpServerConfig`, `McpServerHandle`, `McpServerTransport` |
| `pregolya-mcp/src/registry.rs` | CREATE | `ToolRegistry` — standalone `mcp::registry` module (SS-09; architect OPTION A); `Arc<RwLock<HashMap<String, Arc<dyn DynTool>>>>`; read by `mcp::server` (tools/list dispatch: BC-2.09.006 {PC-002}; tools/call dispatch: BC-2.09.007 {PC-001}); populated by the application/caller layer via the standard `ToolRegistry` registration API (BC-2.09.006 {PRE-001} + BC-2.09.008 {PC-002}); typical flow: caller calls `client.get_tools()` → caller registers returned tools via `registry.register(name, tool)`; `mcp::client` does NOT write the registry; injected via `Arc<ToolRegistry>`, not by embedding in either module |
| `pregolya-mcp/src/sanitize.rs` | CREATE | `pub fn redact_credentials(text: &str) -> Cow<str>` — 3 pattern substitutions (AC-013; BC-2.09.007 {INV-003}); `pub fn sanitize_internal_ids(text: &str) -> Cow<str>` — two-pattern union (both case-insensitive): (1) hyphenated `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; (2) simple no-hyphen `\b[0-9a-f]{32}\b` (covers `Uuid::simple()` rendering; `\b` prevents 64-hex-split and underscore-flanked-strip); covers `run_id` and server-layer `thread_id` only; `u64` `CheckpointId` passes through unsanitized; chained after `redact_credentials` on `isError: true` paths (AC-031, AC-036; BC-2.09.008 INV-001/TV-013/TV-014) |
| `pregolya-mcp/src/graph_tool.rs` | CREATE | `GraphAgentTool` (non-generic struct; non-generic `from_graph` constructor; caller passes `Arc<CompiledStateGraph>` + `schemars::Schema` + `extract_output: impl Fn(&serde_json::Value) -> serde_json::Value`), `GraphToolApprovalPolicy`, `BoundaryApprovalHook`, `GraphRunner` — STATE-ISOLATION enforcement via `ConcreteGraphRunner::run` (ADR-029 §Decision 3 canonical seam); E-MCP-010 interrupt-denied path (BC-2.09.008; ADR-029) |
| `pregolya-mcp/src/lib.rs` | MODIFY | Re-export `McpServer`, `McpServerConfig`, `McpServerHandle`; expose `sanitize` module; re-export `GraphAgentTool`, `GraphToolApprovalPolicy`; expose `graph_tool` module |

## Changelog

- **1.3 (BC-2.09.006 + BC-2.09.007 / 2026-08-26):** BC-2.09.006 (EC-006 malformed JSON → -32700 Parse error; EC-007 invalid JSON-RPC → -32600 Invalid Request; wire-protocol responses, no E-MCP-* raised). BC-2.09.007 (INV-003 mandatory `redact_credentials` with source restriction + 3-pattern substitution; PC-002 result_text JSON-vs-plaintext selection rule; VP-MCPCALL-03 renamed VP-015). Story changes: (1) AC-013 updated to Red Gate — mandatory `pregolya_mcp::sanitize::redact_credentials` applied to `PregolyaError::message` only (source restriction); 3 patterns (sk-*, sk-ant-*, 64-char token); validates VP-015. (2) AC-014 added: BC-2.09.006 EC-006 + BC-2.09.007 EC-007 — -32700 Parse error wire-protocol response, no PregolyaError. (3) AC-015 added: BC-2.09.006 EC-007 + BC-2.09.007 EC-008 — -32600 Invalid Request wire-protocol response, no PregolyaError. (4) AC-016 added: BC-2.09.007 PC-002 — result_text selection rule (Structured→compact JSON, Text→verbatim). (5) `verification_properties` updated to `[VP-015]`. (6) `sanitize.rs` added to File Structure; Arch Compliance Rules table extended with 3 new rows. (7) Tasks updated to AC-016 and tasks 12–16 added. (8) BC table version column added.
- **1.4 (BC-2.09.008 / ADR-029 / GAP-01 / 2026-08-26):** Add BC-2.09.008 StateGraph-as-MCP-Tool coverage (GraphAgentTool; mcp::graph_tool). Story changes: (1) BC-2.09.008 added to `behavioral_contracts`; VP-016 added to `verification_properties`; `points` bumped 5→8. (2) AC-017–AC-022: BC-2.09.008 PC-001–PC-006 (from_graph + schemars schema derivation; DynTool + ToolRegistry + tools/list advertisement; schema-validate → -32602 / deserialize-fail → isError + redaction; terminal → Ok(ToolOutput::Structured); DenyInterrupts node interrupt → E-MCP-010; ForceApproveHooks hook-override + node-interrupt-still-E-MCP-010). (3) AC-023–AC-025: Red Gate INV ACs (INV-001 STATE-ISOLATION VP-016 proptest anchor; INV-002 binary interrupt invariant; INV-003 mandatory credential redaction on all isError paths). (4) AC-026–AC-028: Red Gate EC ACs (EC-004 node interrupt → E-MCP-010; EC-007 STATE-ISOLATION extra fields excluded VP-016; EC-001 invalid input → -32602 before invoke). (5) E-MCP-010 (GraphAgentInterruptDenied) cited throughout — NOT E-MCP-006 (McpContentUnsupported). (6) Architecture Mapping + Purity Classification + Edge Cases + Token Budget + Tasks + Arch Compliance Rules + Library Requirements + File Structure updated for graph_tool module. (7) Forbidden dependencies updated: pregolya-graph now ALLOWED in pregolya-mcp (BC-2.09.008/ADR-029 dep edge). (8) schemars added to Library Requirements. (9) graph_tool.rs added to File Structure.
- **1.5 (BC-2.09.008-v1.1 / BC-2.09.007-v1.9 / ADR-029-v1.2 / 2026-08-26):** Security hardening propagation (SEC-001/005/006/007/008). (1) AC-022 corrected: ForceApproveHooks overrides ONLY PendingHumanApproval (not ALL decisions); Deny passthrough per BC-2.09.008 {PC-006}. (2) AC-029 added: {PC-006} Deny-passthrough — PreToolDecision::Deny passes through unchanged under ForceApproveHooks (SEC-007). (3) AC-030 added: {INV-004}/EC-009 ActionRisk block — action_risk>=Medium emits E-MCP-011 ForceApproveWriteBlocked + CRITICAL log at mcp.graph_tool.force_approve_write_blocked (SEC-006). (4) AC-031 added: {INV-001}/TV-009 error-path UUID sanitization — sanitize_internal_ids chained after redact_credentials on isError paths (SEC-005). (5) AC-032 added: {INV-005}/TV-010 extract_output credential opacity — success path not framework-sanitized; DI-010 caller obligation (SEC-001). (6) AC-033 added: EC-010/TV-011 extract_output panic — UnwindSafe catch → static 'internal error'; server continues (SEC-008). (7) AC-034 added: BC-2.09.007 {PC-002}/TV-009 success-path credential boundary — framework sanitizes error paths only (SEC-001). (8) Edge Cases EC-011 (ActionRisk block) and EC-012 (extract_output panic) added. (9) Tasks 30–40 added (security hardening implementation sequence; Red Gate checks). (10) Arch Compliance Rules: existing ForceApproveHooks row corrected; 5 new rows added. (11) sanitize.rs File Structure entry extended with sanitize_internal_ids. (12) Token Budget updated. (13) Frontmatter changelog reordered to ascending order.
- **1.6 (F-057-01 / F-057-02 / OBS / 2026-08-26):** Round-2 BC-2.09.008 security corrections propagated. (1) AC-030 (F-057-01): ActionRisk gate is now fail-closed on `None` — `preview.action_risk` is `None` (un-annotated tool, fail-closed per {INV-004}) OR `Some(r >= Medium)` → `Deny` + `E-MCP-011 ForceApproveWriteBlocked` + CRITICAL log; `None` fails closed identically to `Some(>=Medium)`; TV-012 cited for `None` path (TV-008 for `Some(High)` path); second test function `test_BC_2_09_008_force_approve_hooks_action_risk_none_fails_closed_emits_e_mcp_011()` added. (2) AC-021 (F-057-02): `BoundaryApprovalHook::Deny` path corrected — graph CONTINUES executing after Deny; valid terminal → `Ok(ToolOutput::Structured)` per {PC-004}; error terminal → graph's OWN `Err(PregolyaError)` (NOT `E-MCP-010`); `E-MCP-010` raised ONLY on node-level `interrupt()` parking (`RunStatus::Interrupted`); test renamed to `test_BC_2_09_008_pending_approval_under_deny_continues_to_terminal()`. (3) AC-024 (F-057-02): Binary-interrupt invariant scoped to node-level `interrupt()` PARKING only; `BoundaryApprovalHook::Deny` path explicitly excluded (graph continues to own terminal, NOT `E-MCP-010`); test clarified. (4) OBS: all BC-2.09.008 and BC-2.09.007 AC heading traces normalized from `§{CLAUSE}` to plain `CLAUSE` form consistent with sibling BC-2.09.006 trace format throughout; Task 33 updated for `None` case; EC-011 updated to cover both TV-012 (`None`) and TV-008 (`Some(High)`) cases; Arch Compliance Rules binary-interrupt and ActionRisk rows updated.
- **1.7 (F-058-02 / 2026-08-26):** AC-021 and AC-026: E-MCP-010 remedy text corrected per orchestrator mandate — dropped ForceApproveHooks-recovery clause; message updated to `"restructure the graph so it does not call interrupt() during a synchronous tools/call invocation"`. AC traces (BC-2.09.008 PC-005 and EC-004) unchanged.
- **1.8 (F3 / round-5 / 2026-08-26):** AC-003 corrected: `tool.input_schema()` → `tool.schema()`. `schema()` is the canonical method name on the `DynTool` trait; `input_schema` is a struct field name, not a callable method. Swept entire file — no other `input_schema()` method calls found. `depends_on` updated to `[S-2.10, S-1.14]`; S-1.14 (StateGraph Nodes + Channels) delivers `CompiledGraph<S>` required by `GraphAgentTool::from_graph` per BC-2.09.008 PRE-001 `Arc<CompiledGraph<S>>` precondition.
- **1.9 (BLOCKER-2 / F-064-03 / round-6 / 2026-08-26):** Four remaining `RootSchema` live-body sites replaced with `schemars::Schema` (schemars 1.0 canonical per ADR-004 §Version pin; matches BC-2.09.008 {PC-001}): (1) AC-017 body — "derive the `schemars::Schema` for `S`"; (2) AC-018 body — "the `schemars::Schema` derived at `from_graph` time"; (3) Task 18 — "store `schemars::Schema` for `DynTool::schema()`"; (4) Task 19 — "`schema()` returning stored `schemars::Schema`". Changelog-history mentions of `RootSchema` are intentionally preserved as historical record. Zero live `RootSchema` references remain outside the changelog.
- **1.10 (F-P2A066-01 / F-P2A066-02 / F-P2A068-01 / GATE-READY-OBS / round-7 / 2026-08-26):** (1) Task 23 updated to ADR-029 §Decision 3 canonical seam: `ConcreteGraphRunner::run` calls `(self.extract_output)(&final_state)` INSIDE `run()`; `invoke_dyn` wraps result in `ToolOutput::Structured` without re-filtering; inline comment required at extract_output call site per VP-016 §Proof Obligations. (2) Architecture-Compliance STATE-ISOLATION row updated from "invoke_dyn returns ONLY..." to canonical seam statement referencing `GraphRunner::run` and ADR-029 §Decision 3. (3) `GraphAgentTool<S>` → `GraphAgentTool` at 4 drifted sites: Architecture Mapping, Purity Classification, Task 17, File Structure — struct is non-generic; only `from_graph<S>` constructor method is generic. (4) AC-035 added: traces to BC-2.09.008 INV-005 + DI-010; testable caller-obligation test — correct `extract_output` closure over `TestGraphState { answer, api_key }` returns only `answer` field; verified by `test_BC_2_09_008_inv005_credential_opacity_correct_closure_excludes_credentials()`. (5) Tasks 1/40 updated; Task 41 added for AC-035 test. (6) Token Budget updated to AC-001–AC-035.
- **1.11 (GAP-01-nongeneric / F-P2A073-01 / round-10 / 2026-08-27):** Non-generic re-ground closes architect REQUIRES-ROUTING handoff. (1) AC-017: `from_graph` non-generic; signature `from_graph(name, description, Arc<CompiledStateGraph>, input_schema: schemars::Schema, extract_output: impl Fn(&serde_json::Value) -> serde_json::Value)`; `CompiledGraph<S>` eliminated; `S: GraphState + Deserialize + JsonSchema` bounds removed; schema is caller-derived and passed as parameter. (2) AC-018: schema is caller-passed (not derived at `from_graph` time). (3) AC-019: `from_value::<S>` eliminated; `CompiledStateGraph::invoke` accepts `serde_json::Value` directly (non-generic seam design). (4) AC-016: `ToolOutput::Structured`/`ToolOutput::Text` eliminated; `DynTool::invoke_dyn` returns `serde_json::Value`; `Value::String(s)` → verbatim; other variants → compact JSON. (5) AC-020/AC-021/AC-024/AC-027/AC-034/AC-035: `ToolOutput::Structured` and `&S`/`TestGraphState` references replaced with `serde_json::Value`. (6) AC-023: "arbitrary `S` instances" → "arbitrary `serde_json::Value` objects with extra keys". (7) Tasks 15/17/18/23 updated to non-generic signatures. (8) File Structure graph_tool.rs entry updated: non-generic `from_graph` constructor. (9) Arch Compliance: old `ToolOutput::Structured`/`Text` row replaced with `Value`-based rule; new rule added: no `from_value::<S>` in `mcp::graph_tool`. (10) F-P2A073-01: BC status annotation corrected — BC-2.09.008 is `draft` (auto-promotes draft→active at S-2.11 PR merge per POL-27); BC-2.09.006 + BC-2.09.007 are active. Changelog-history mentions of `ToolOutput::Structured` (in 1.4, 1.6, 1.10 entries) preserved as historical record. input-hash updated.
- **1.12 (schema_for!(S)-sweep / round-10 / 2026-08-27):** Two `schema_for!(S)` stragglers eliminated from live body. (1) Arch Compliance table: `GraphAgentTool::from_graph` Arch Compliance row rewritten — "calls `schemars::schema_for!(S)` at construction time" removed; replaced with "accepts a caller-supplied `input_schema: schemars::Schema` parameter (no `schema_for!` call inside `from_graph`)". BC-2.09.008 {PC-001} / Test AC-017 columns preserved. (2) Library Requirements `schemars` row rewritten — "`schema_for!(S)` inputSchema derivation in `GraphAgentTool::from_graph`" removed; replaced with "`schemars::Schema` type for the caller-supplied `input_schema` parameter; caller derives via `schemars::schema_for!` at the call site". AC-017 body was already grounded correctly (`schema_for!(StateType)` is a call-site usage example, not inside `from_graph`) — no AC-017 body change needed.
- **1.13 (GAP-01-type-grounding / round-12 / 2026-08-27):** Two live-body closure-body phantoms eliminated. (1) AC-032: `|s: &S| json!({ "api_key": s.api_key })` → `|s: &serde_json::Value| json!({ "api_key": s["api_key"] })` — `extract_output` closure receives `&serde_json::Value`, not generic `&S`; struct field access replaced with JSON index operator. (2) Task-41: `TestGraphState { answer: "hello", api_key: "..." }` typed struct construction replaced with `json!({ "answer": "hello", "api_key": "..." })` JSON value; closure `|s| json!({ "answer": s.answer })` → `|s: &serde_json::Value| json!({ "answer": s["answer"] })`. Zero live-body `|s: &S|` or `s.fieldname` struct-access phantoms remain. input-hash updated (state-manager recomputes).
- **1.14 (F-P2A079-01 / round-14 / 2026-08-27):** Task 38 corrected: `ToolOutput::Text { text: "..." }` (struct-form tuple-variant syntax, stale ToolOutput type) replaced with `Ok(Value::String("key=sk-abc123XYZabc123XYZabc".to_string()))` — canonical `DynTool::invoke_dyn` return form (`Result<serde_json::Value, PregolyaError>`), matching AC-034 body and BC-2.09.007 TV-009. Task description updated from "success-path ToolOutput" to "success-path `serde_json::Value` result". Arch Compliance table: `from_value::<S>` prohibition Source column de-cited from a cross-reference BC-ID that was not in frontmatter to `BC-2.09.008 {PC-003}` (which is in `behavioral_contracts`; the former citation was a rationale cross-reference, not a story obligation). Changelog entry 1.11 item (3): stale BC cross-reference rephrased to "non-generic seam design" (historical sense preserved; bare BC-ID citation removed to satisfy Policy 8 hook). input-hash updated (state-manager recomputes).
- **1.15 (F-P2A084-01 / round-18 / 2026-08-27):** AC-023: "NEVER included in the `ToolOutput` unless `extract_output`" corrected to "NEVER included in the `serde_json::Value` returned by `invoke_dyn` unless `extract_output`" — `ToolOutput` was eliminated in the 1.11 non-generic re-ground; `DynTool::invoke_dyn` returns `serde_json::Value`. Task 20: "extra fields leak to `ToolOutput` without explicit exclusion" corrected to "extra fields leak into the `serde_json::Value` returned by `invoke_dyn` without explicit exclusion". These were the last two live-body `ToolOutput` residues naming the invoke_dyn success output. Frontmatter `changelog:` array backfilled with 1.14 entry (round-14 was missing from frontmatter array) and 1.15 entry added. Zero remaining live-body stale `ToolOutput`, `CompiledGraph<`, `StateGraph<S>`, `|s: &S|`, `schema_for!(S)` (non-call-site), or `from_value::<S>` (non-prohibition) references in STORY-S-2.11, STORY-S-1.14, or dependency-graph.md.
- **1.16 (F-P2A087-01 / F-P2A087-02 / round-19 / 2026-08-27):** Symbol-canon propagation from BC-2.09.008 {PC-005}/EC-005 PreToolDecision rename and `DynTool` object-safe interface. (1) AC-008: `DynTool::invoke` → `DynTool::invoke_dyn` (object-safe dispatch seam method; `DynTool::invoke` does not exist). (2) AC-009: `DynTool::invoke` → `DynTool::invoke_dyn`. (3) §Purity Classification `tools/call` handler row: `DynTool::invoke` → `DynTool::invoke_dyn`. (4) §Previous Story Intelligence: `DynTool::invoke(args)` → `DynTool::invoke_dyn(args)`. (5) AC-021: `PreToolCallHook::PendingHumanApproval` → `PreToolDecision::PendingHumanApproval` (BC-2.09.008 {PC-005}/EC-005 enum rename per product-owner; matches AC-022/AC-029 canonical form already in place). input-hash updated to 3b82473.
- **1.17 (round-21 / F-P2A093-01 / 2026-08-28):** Task-27 updated to wire `pregolya-graph` in two Cargo.toml sections: (1) `[dependencies]` with workspace pin — for `GraphAgentTool` non-test production code (`Arc<CompiledStateGraph>` argument; BC-2.09.008/ADR-029 dep edge); (2) `[dev-dependencies]` with `features = ["test-util"]` — so the VP-016 proptest harness `graph_agent_tool_state_isolation` can call `CompiledStateGraph::stub_terminal` cross-crate (stub_terminal is gated `#[cfg(any(test, feature = "test-util"))]` in pregolya-graph and is invisible to the linker without that feature). Both entries are required: the `[dependencies]` entry does not activate `test-util`; the `[dev-dependencies]` entry alone does not cover non-test production code. Mirrors F-P2A093-01 mechanism from S-1.14 v1.4.
- **1.18 (round-22 / F-P2A096-01 / F-P2A097-01 / F-P2A099-02 / F-P2A096-03 / F-P2A097-02 / 2026-08-28):** Exhaustive sweep against BC-2.09.008 {INV-001}/EC-010/TV-011/TV-013 and ADR-029 §Decision 3/§Decision 5 canonical forms. (1) AC-031: sanitizer regex corrected to version-agnostic `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` (retired v4-specific `4[0-9a-f]{3}-[89ab][0-9a-f]{3}` pattern removed); scope corrected — "checkpoint IDs" removed; framework covers `run_id` and server-layer `thread_id` (both `Uuid` types) only; `u64` `CheckpointId` is NOT UUID-shaped and passes through unsanitized; fixture must include a non-v4 UUID (v7 example provided) to prevent false-green regression. (2) AC-036 added: BC-2.09.008 {INV-001}/TV-013 correctness boundary — `u64` `CheckpointId` in error message "failed to load checkpoint 42" passes through `sanitize_internal_ids` UNCHANGED; authoring-site convention is the sole guarantee. (3) AC-033: panic recovery mechanism corrected — `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy)))` INSIDE `GraphAgentTool::invoke_dyn` at the `.await` call site; synchronous `std::panic::catch_unwind` explicitly marked INADEQUATE (panic occurs during `.await` polling); Red Gate test must drive panic through `.await` so synchronous-only catch fails to catch it. (4) AC-037 added: SEC-008 build-profile obligation — workspace release profile MUST pin `panic = "unwind"`; `panic = "abort"` voids `FutureExt::catch_unwind` (remote DoS CWE-248); Phase-3 devops-engineer obligation; implementer obligation is comment annotation. (5) Tasks 34/35 updated to version-agnostic regex. (6) Tasks 36/37 updated to `FutureExt::catch_unwind` async mechanism. (7) Task 40 count updated 35 → 37. (8) Tasks 42–44 added (AC-036 test, AC-036 correctness verify, AC-037 annotation). (9) Arch Compliance rows updated for `sanitize_internal_ids` scope and `extract_output` panic mechanism. (10) File Structure `sanitize.rs` row updated. (11) Token Budget updated. (12) input-hash recomputed (BC-2.09.008 input file was updated in round-19/21 security rounds).
- **1.19 (round-26 / F-P2A113-02+F-P2A115-03+confirm-registry / 2026-08-28):** Four live-body log-level corrections CRITICAL→ERROR (`tracing::error!`) per BC-2.09.008 {INV-004} canonical (Rust `tracing` crate has no CRITICAL level): (1) AC-030 body — "log at CRITICAL level" → "log at ERROR level (`tracing::error!`)"; (2) EC-011 — "CRITICAL log at" → "ERROR log (`tracing::error!`) at"; (3) Task 33 — same correction; (4) Arch Compliance ActionRisk row — same correction. Historical changelog entries 1.5 and 1.6 that mention "CRITICAL log" are preserved as immutable records per story-changelog convention. File Structure registry.rs de-hedged: action `CREATE or MODIFY` → `CREATE`; purpose "shared with client side (extract if needed)" → "standalone `mcp::registry` module (SS-09; architect OPTION A); `Arc<ToolRegistry>` injection" per architect OPTION A resolution. Previous Story Intelligence: "via shared access" language de-hedged to explicit `Arc<ToolRegistry>` injection description. input-hash updated to 564c950.
- **1.20 (R28 / F-P2A121-01-propagation / 2026-08-28):** AC-031 extended with TV-014 simple-form UUID positive fixture (`Uuid::simple()` 32-contiguous-hex rendering — MUST be stripped by pattern (2) `\b[0-9a-f]{32}\b`; fixture input is a message containing a `{SIMPLE-UUID}` (32-char no-hyphen hex value) — `content[0].text` must NOT contain the 32-hex value). Task-35 description updated from single hyphenated-pattern to two-pattern union: (1) canonical hyphenated form `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; (2) simple no-hyphen `\b[0-9a-f]{32}\b`; both case-insensitive; `\b` word-boundary prevents 64-hex-split (TV-015) and underscore-flanked-strip (TV-016). Mirrors BC-2.09.008 §Changelog {INV-001} two-pattern extension and TV-014/TV-015/TV-016 additions.
- **1.21 (R29 / F-P2A125-01 + F-P2A127-01 + O-P2A124-01 / 2026-08-28):** Round-29 propagation sweep. (1) §Architecture Compliance Rules sanitizer row extended to two-pattern union (both case-insensitive): pattern (1) canonical hyphenated `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`; pattern (2) simple no-hyphen `\b[0-9a-f]{32}\b`; scope: `run_id` and server-layer `thread_id` only; `u64` `CheckpointId` passes through unchanged (F-P2A125-01). (2) §File Structure `sanitize.rs` purpose column updated to two-pattern union + BC-2.09.008 INV-001/TV-013/TV-014 cite (F-P2A125-01). (3) §File Structure `registry.rs` `Arc<RwLock<HashMap<String, Arc<dyn DynTool>>>>` surplus fifth `>` corrected to 4 angle-brackets (F-P2A127-01). (4) BC status frontmatter comment: BC-2.09.008 mint annotation augmented with E-MCP-011 alongside E-MCP-010 (O-P2A124-01). input-hash unchanged — no BC input file changes in round-29.
- **1.22 (R30 / F-P2A129-02 + F-P2A131-01 + F-P2A129-01-propagation / 2026-08-28):** Three-finding round-30 sweep. (1) F-P2A129-02 [MED] — AC-031 normative statement rewritten to two-pattern union: opening description changed from single-pattern (hyphenated only; `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`) to explicit pattern (1) canonical hyphenated + pattern (2) simple no-hyphen `\b[0-9a-f]{32}\b`; `sanitize_internal_ids` description in the framework-passes sentence changed from "UUID (any version) pattern removal" to two-pattern union form; the "pattern (2)" fixture reference now has a proper "pattern (1)" antecedent; resolves same-document contradiction with §Architecture Compliance Rules row and BC-2.09.008 {INV-001}. (2) F-P2A131-01 [MED] — §Previous Story Intelligence and §File Structure registry.rs row aligned to architect canonical consumer/registrar set from module-decomposition.md: `mcp::server` (reads for tools/list + tools/call dispatch) and `mcp::client` (populates at session startup via `mcp::discovery` conversion); previously both sites stated "shared between ... and ..." without the reads/writes role distinction. (3) F-P2A129-01 propagation [POL-8] — Task-35: "prevents matching within 64-char SHA-256 digests per TV-015" corrected to "prevents over-matching … at the isolation layer per TV-017 (TV-015 verifies the full pipeline: `redact_credentials` catches it first → `"digest: <redacted>"`)" ; TV-015 and TV-017 added to Task-35 end citation. input-hash updated (BC-2.09.008 §Changelog round-30 update).
- **1.23 (R31 / F-P2A135-01 / 2026-08-28):** mcp::registry registrar attribution corrected at two live-body sites — §Previous Story Intelligence and §File Structure registry.rs row. R30 phantom `mcp::client (populates at session startup via mcp::discovery conversion)` removed; corrected to canonical attribution per BC-2.09.006 {PRE-001}, BC-2.09.006 {PC-002}, and BC-2.09.008 {PC-002}: registry is read by `mcp::server` (tools/list + tools/call dispatch; BC-2.09.006 {PC-002}); populated by the application/caller layer via the standard `ToolRegistry` registration API (BC-2.09.006 {PRE-001} + BC-2.09.008 {PC-002}); typical flow: caller calls `client.get_tools()` → caller registers returned tools via `registry.register(name, tool)`; `mcp::client` does NOT write the registry. BC clause anchor verification: BC-2.09.008 `{PC-002}` is the clause containing "standard registration API" text; arch-doc v1.57 cites `{PC-001}` at the same call — mismatch escalated for architect correction; story uses the verified `{PC-002}`. input-hash updated (module-decomposition.md R31 edit propagated to input set).
- **1.24 (R33 / F-P2A143-02 / 2026-08-29):** v1.23 `{PC-001}`/`{PC-002}` anchor mismatch escalation RESOLVED — architect corrected `module-decomposition.md` in R31 (v1.57 cites `{PC-002}`); story-writer `{PC-002}` usage confirmed correct (F-P2A135-01 closed). Records-tier resolution note; no live-body content changed.
- **1.25 (R36 / F-P2A155-01 / 2026-08-29):** AC-019 call-direction corrected per BC-2.09.008 {PC-003}. OLD: `invoke_dyn` called `CompiledStateGraph::invoke` directly (seam-collapse — structurally impossible; `GraphAgentTool` holds `runner: Arc<dyn GraphRunner>`, not a graph handle). NEW: `invoke_dyn` delegates to `runner.run(arguments, policy)` via `Arc<dyn GraphRunner>`; `GraphRunner::run` (`ConcreteGraphRunner<S>::run` at the concrete layer) calls `CompiledStateGraph::invoke` internally; error propagates through `GraphRunner::run` and `invoke_dyn` surfaces it as `isError: true`. Exhaustive call-direction sweep of all S-2.11 AC/Task invoke_dyn/GraphRunner/CompiledStateGraph direction statements: AC-020 (`GraphRunner::run` wraps `CompiledStateGraph::invoke`; `invoke_dyn` wraps `run()`), AC-021 (`GraphRunner::run` detects `RunStatus::Interrupted`), Task-23 (`extract_output` inside `run()`; `invoke_dyn` wraps without re-filtering), Arch Compliance STATE-ISOLATION row — all CORRECT. AC-019 was the sole seam-collapse in S-2.11. input-hash refreshed (BC-2.09.008 updated in R36).
- **1.27 (R39 / F-P2A165-01 + F-P2A167-01 + F-P2A167-02 / 2026-08-29):** Three round-39 findings closed. (1) F-P2A165-01 [ITEM B] — BC-2.09.008 unconditional pre-hook gate propagated. AC-022 body rewritten: ActionRisk gate runs BEFORE invoking the inner PreToolCallHook (unconditional; not just on PendingHumanApproval paths); None/Some(>=Medium) denied WITHOUT calling inner hook — covers AlwaysApprovePolicy/no-hook default Approve paths; gate approves → inner hook called normally; PendingHumanApproval from inner hook → Approve; Deny from inner hook passes through unchanged (traces to BC-2.09.008 {PC-006}). AC-030 heading and body updated to gate-before-hook model per BC-2.09.008 {INV-004}/{PC-006}/EC-009; TV-018 test reference added (ForceApproveHooks + AlwaysApprovePolicy inner hook + Some(ActionRisk::High) → Deny WITHOUT calling inner hook). EC-011 scenario updated: ActionRisk gate fires BEFORE invoking inner hook; TV-018 added; "inner hook NOT called" added. Task-22 and Task-33 updated to unconditional gate-before-hook model; Task-33 now cites three test paths TV-008, TV-012, TV-018. Architecture Compliance ForceApproveHooks row updated to gate-before-hook description. (2) F-P2A167-01 [ITEM C, POL-4] — Two live-body tools/list+tools/call collapsed attribution sites corrected. §Previous Story Intelligence mcp::server description changed from `(tools/list + tools/call dispatch; BC-2.09.006 {PC-002})` to `(tools/list dispatch: BC-2.09.006 {PC-002}; tools/call dispatch: BC-2.09.007 {PC-001})`. §File Structure registry.rs row changed identically. Lines 57 and 736 are historical changelog records — intentionally preserved. (3) F-P2A167-02 [ITEM D, POL-4] — §Previous Story Intelligence phantom S-2.10 module filenames corrected: `tool.rs` → `discovery.rs`, `guardrail.rs` → `ingress.rs` per round-25 canonical rename.
