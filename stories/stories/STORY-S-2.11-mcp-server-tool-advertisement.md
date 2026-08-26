---
document_type: story
level: ops
story_id: S-2.11
epic_id: E-21
version: "1.6"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.006.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.007.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.008.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "3b41502"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-2.10]
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
# BC status: all 3 BCs active; BC-2.09.006 mints E-MCP-005; BC-2.09.008 mints E-MCP-010; no BC-TBD placeholders; status = draft per Spec-First Gate S-7.01
changelog:
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors."
  - "1.2 (2026-08-24): P2A-043 F-04: old-form ordinal cross-refs converted to stable tags"
  - "1.3 (BC-2.09.006 + BC-2.09.007 / 2026-08-26): BC-2.09.006 (burst-B-SS09-11 EC-006/-32700, EC-007/-32600 wire-protocol responses). BC-2.09.007 (burst-B-SS09-11: INV-003 redact_credentials mandatory+3-pattern sub+source restriction; PC-002 result_text JSON-vs-plaintext selection rule; VP-MCPCALL-03 renamed VP-015). Story changes: AC-013 updated to Red Gate — mandatory redact_credentials applied to PregolyaError::message only (source restriction); 3 substitution patterns (sk-*, sk-ant-*, 64-char token); validates VP-015. AC-014 added: BC-2.09.006 EC-006 + BC-2.09.007 EC-007 — malformed JSON → -32700 Parse error (wire-protocol only, no PregolyaError). AC-015 added: BC-2.09.006 EC-007 + BC-2.09.007 EC-008 — invalid JSON-RPC → -32600 Invalid Request (wire-protocol only). AC-016 added: BC-2.09.007 PC-002 — result_text selection (ToolOutput::Structured→compact JSON, ToolOutput::Text→verbatim). verification_properties updated to [VP-015]. BC table version column added. Tasks updated to AC-001–AC-016."
  - "1.4 (BC-2.09.008/ADR-029/GAP-01/2026-08-26): Add BC-2.09.008 StateGraph-as-MCP-Tool coverage; GraphAgentTool; mcp::graph_tool; AC-017–AC-028 (PC-001–PC-006, INV-001–INV-003 Red Gates, EC-001/EC-004/EC-007 Red Gates); VP-016 added; points 5→8; pregolya-graph dep now allowed in pregolya-mcp; E-MCP-010 cited throughout (not E-MCP-006)."
  - "1.5 (BC-2.09.008-v1.1/BC-2.09.007-v1.9/ADR-029-v1.2/SEC-001/005/006/007/008/2026-08-26): Security hardening propagation. AC-022 corrected: ForceApproveHooks overrides ONLY PendingHumanApproval (not ALL decisions); Deny passthrough per BC-2.09.008 {PC-006}. AC-029: {PC-006} Deny passthrough (SEC-007). AC-030: {INV-004}/EC-009 ActionRisk block — action_risk>=Medium emits E-MCP-011 ForceApproveWriteBlocked+CRITICAL log (SEC-006). AC-031: {INV-001}/TV-009 error-path UUID sanitization — sanitize_internal_ids chained after redact_credentials on isError paths (SEC-005). AC-032: {INV-005}/TV-010 extract_output credential opacity — success path not framework-sanitized; DI-010 caller obligation (SEC-001). AC-033: EC-010/TV-011 extract_output panic — UnwindSafe catch yields static 'internal error'; server continues (SEC-008). AC-034: BC-2.09.007 {PC-002}/TV-009 success-path credential boundary — error paths only sanitized by framework (SEC-001). Frontmatter changelog reordered ascending. sanitize.rs extended with sanitize_internal_ids. sanitize.rs File Structure entry updated."
  - "1.6 (F-057-01/F-057-02/OBS/2026-08-26): Round-2 BC-2.09.008 security corrections. AC-030: ActionRisk gate extended — None (un-annotated, fail-closed per {INV-004}) added alongside Some(>=Medium); TV-012 (None path) and TV-008 (Some(High) path) cited; second test test_BC_2_09_008_force_approve_hooks_action_risk_none_fails_closed_emits_e_mcp_011() added. AC-021: BoundaryApprovalHook::Deny path corrected — graph CONTINUES to own terminal; valid terminal → Ok({PC-004}); error terminal → graph own Err (NOT E-MCP-010); E-MCP-010 scoped to node-level interrupt() parking only; test renamed to test_BC_2_09_008_pending_approval_under_deny_continues_to_terminal(). AC-024: Binary-interrupt invariant scoped to node-level interrupt() parking (RunStatus::Interrupted) only; Deny path explicitly excluded (graph continues to own terminal). OBS: all BC-2.09.008 and BC-2.09.007 AC heading traces normalized from §{CLAUSE} to plain CLAUSE form consistent with sibling BC-2.09.006 trace format; Task 33, EC-011, Arch Compliance Rules ActionRisk and binary-interrupt rows updated."
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
`ToolDefinition` format: `{ "name": tool.name(), "description": tool.description(), "inputSchema": tool.input_schema() }`.
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
`DynTool::invoke`. On success, responds with
`{ "content": [{ "type": "text", "text": "<result>" }], "isError": false }`.
Verified by `test_BC_2_09_007_tools_call_success_response()`.

### AC-009 (traces to BC-2.09.007 PC-003)
When the registered `DynTool::invoke` returns `Err(PregolyaError { .. })`, the server
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
determined by the `ToolOutput` variant returned by `Tool::invoke`:
- `ToolOutput::Structured { value: serde_json::Value }` → `result_text = serde_json::to_string(&value)`
  (compact JSON, no pretty-printing). A `serde_json::Value::Null` serializes to the string `"null"`.
- `ToolOutput::Text { text: String }` → `result_text = text` verbatim (no JSON-encoding or
  additional escaping applied to the string contents).
An `ToolOutput::Text { text: "".to_string() }` produces `result_text = ""`. The `Tool`
implementation controls which variant is returned; the server applies the corresponding
serialization rule without re-interpreting or re-encoding the value. Verified by
`test_BC_2_09_007_result_text_structured_uses_compact_json()` (ToolOutput::Structured with
nested object; assert compact JSON, no newlines), `test_BC_2_09_007_result_text_text_verbatim()`
(ToolOutput::Text with plain string; assert no escaping), and
`test_BC_2_09_007_result_text_null_value_is_string_null()` (ToolOutput::Structured with
`Value::Null`; assert `result_text == "null"`).

### AC-017 (traces to BC-2.09.008 PC-001)
`GraphAgentTool::from_graph(name, description, graph, extract_output)` constructs a
`GraphAgentTool` where `graph: Arc<CompiledGraph<S>>` and
`S: GraphState + for<'de> Deserialize<'de> + JsonSchema + Send + Sync + 'static`.
At construction time, `schemars::schema_for!(S)` is called to derive the `RootSchema` for `S`.
This schema is stored internally and returned by `DynTool::schema()` for advertisement in
`tools/list` responses per BC-2.09.006 {PC-002}. Construction returns a value (not `Err`);
all precondition bounds are enforced by the type system at the call site. Verified by
`test_BC_2_09_008_from_graph_derives_schema_at_construction_time()`.

### AC-018 (traces to BC-2.09.008 PC-002)
The constructed `GraphAgentTool` implements `DynTool` (object-safe dispatch seam per
ADR-005 §Adjacent Trait Object-Safety Adjudications) and may be registered in a `ToolRegistry`
via the standard registration API. After registration, the MCP server advertises the tool in
`tools/list` responses — name, description, and inputSchema (the `RootSchema` derived at
`from_graph` time via `schemars::schema_for!(S)`) are exposed verbatim per BC-2.09.006
{PC-002}. Verified by
`test_BC_2_09_008_graph_agent_tool_registered_appears_in_tools_list()`.

### AC-019 (traces to BC-2.09.008 PC-003)
On `tools/call` invocation for a `GraphAgentTool`:
- If call arguments do not conform to `DynTool::schema()`, the server returns JSON-RPC
  `{ "code": -32602, "message": "Invalid arguments for tool '<name>': <schema_error>" }` BEFORE
  `invoke_dyn` is called; the graph is NOT invoked.
- If schema validation passes but `serde_json::from_value::<S>(arguments)` fails (custom
  `Deserialize` logic rejects a structurally-valid JSON object), `GraphAgentTool::invoke_dyn`
  returns `Err(PregolyaError { .. })`; the server surfaces this as `isError: true` per
  BC-2.09.007 {PC-003}; credential redaction applies per {INV-003}.
Verified by `test_BC_2_09_008_schema_validation_fail_returns_32602()` and
`test_BC_2_09_008_deserialize_fail_returns_is_error_true_with_redaction()`.

### AC-020 (traces to BC-2.09.008 PC-004)
On successful graph execution: `GraphRunner::run` runs the graph to a terminal state, calls
`extract_output(&final_state)`, and `GraphAgentTool::invoke_dyn` returns
`Ok(ToolOutput::Structured { value: extract_output_result })`. The server serializes this per
BC-2.09.007 {PC-002} (`result_text = serde_json::to_string(&extract_output_result)`).
If `extract_output` returns `Value::Null`, `result_text = "null"` — no error raised; {PC-004}
holds. Verified by `test_BC_2_09_008_successful_graph_run_returns_structured_output()` and
`test_BC_2_09_008_extract_output_null_result_is_valid()`.

### AC-021 (traces to BC-2.09.008 PC-005)
Under `GraphToolApprovalPolicy::DenyInterrupts` (default):
- **Node-level `interrupt()`:** When a graph node calls `interrupt()` during execution,
  `GraphRunner::run` detects `RunStatus::Interrupted` and `GraphAgentTool::invoke_dyn` returns
  `Err(PregolyaError { code: "E-MCP-010", category: EXEC, message: "graph agent tool invocation
  interrupted at MCP boundary: HITL approval not supported for synchronous tools/call; configure
  the graph to not interrupt, or register with GraphToolApprovalPolicy::ForceApproveHooks if
  read-only", retry_hint: Never })`. The interrupted run is NOT persisted to durable checkpoint.
- **`PreToolCallHook::PendingHumanApproval`:** When received, `BoundaryApprovalHook` converts
  `PendingHumanApproval` → `Deny { reason: "HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY" }`; the tool
  is NOT invoked; the node receives `ToolOutput::Error`; the graph CONTINUES executing. If the
  graph reaches a valid terminal state, {PC-004} applies and `invoke_dyn` returns
  `Ok(ToolOutput::Structured)`. If the graph reaches an error terminal, `invoke_dyn` returns
  `Err(PregolyaError)` with the graph's OWN error — `E-MCP-010` is NOT raised on the
  `BoundaryApprovalHook::Deny` path.
Verified by `test_BC_2_09_008_node_interrupt_under_deny_returns_e_mcp_010()` (node-level
interrupt → E-MCP-010; Red Gate) and
`test_BC_2_09_008_pending_approval_under_deny_continues_to_terminal()` (Deny → graph
continues → valid terminal → `Ok(ToolOutput::Structured)` per {PC-004}; or error terminal →
graph's own `Err`, NOT `E-MCP-010`).

### AC-022 (traces to BC-2.09.008 PC-006)
Under `GraphToolApprovalPolicy::ForceApproveHooks`, `BoundaryApprovalHook` overrides ONLY
`PreToolDecision::PendingHumanApproval` to `Approve` (subject to the `ActionRisk` check in
{INV-004}); `PreToolDecision::Deny` and all other decision variants pass through to the graph
UNCHANGED — `ForceApproveHooks` does not override security-based `Deny` decisions. Node-level
`interrupt()` calls STILL produce `Err(E-MCP-010)` — `ForceApproveHooks` does NOT override
node-level interrupt semantics; {INV-002} holds under `ForceApproveHooks`. Verified by
`test_BC_2_09_008_force_approve_hooks_overrides_pending_approval()` and
`test_BC_2_09_008_force_approve_hooks_does_not_suppress_node_interrupt()`.

### AC-023 (traces to BC-2.09.008 INV-001 — Red Gate, validates VP-016)
**Red Gate / Mandatory (STATE-ISOLATION):** `GraphAgentTool::invoke_dyn` on successful graph
completion returns ONLY the `serde_json::Value` produced by `extract_output(&final_state)`.
The following are NEVER included in the `ToolOutput` unless `extract_output` explicitly
constructs a `Value` containing them: checkpoint IDs, run IDs, internal execution identifiers,
intermediate node outputs, accumulated message history, tool call history, graph metadata, and
execution statistics. The `extract_output` closure is the sole data-exit path at the
`GraphRunner` boundary. DI-010 Credential Opacity is a structural corollary: credentials in
input fields, intermediate fields, or model reasoning cannot appear in the output if
`extract_output` is correctly scoped to output fields only. This is a Red Gate: without
STATE-ISOLATION enforcement, internal graph state including credential-bearing fields could leak
to external MCP clients. VP-016 proptest harness `graph_agent_tool_state_isolation` generates
arbitrary `S` instances with extra fields and verifies that ONLY selected fields appear in the
`invoke_dyn` result. Verified by
`test_BC_2_09_008_state_isolation_only_extract_output_in_result()` ({INV-001} / VP-016 anchor).

### AC-024 (traces to BC-2.09.008 INV-002 — Red Gate)
**Red Gate / Binary interrupt invariant (fail-closed, node-level interrupt() only):** The
binary interrupt invariant applies to node-level `interrupt()` PARKING (`RunStatus::Interrupted`)
only. Under `GraphToolApprovalPolicy::DenyInterrupts`, exactly one of two outcomes is possible
for the node-level interrupt path:
- Terminal state reached → `Ok(ToolOutput::Structured { value: extract_output_result })`
- Node-level `interrupt()` parking (`RunStatus::Interrupted`) → `Err(E-MCP-010)`
The `BoundaryApprovalHook::Deny` path does NOT raise `E-MCP-010`; the graph continues to its
own terminal (`Ok` per {PC-004} or the graph's own `Err`). There is NO `Ok` code path that
returns a result when the graph reached `RunStatus::Interrupted`. Under `ForceApproveHooks`,
the `PreToolCallHook` path is overridden to `Approve`, but the node-level interrupt invariant
holds in both policies; {INV-002} is satisfied under `ForceApproveHooks` as well. Verified by
`test_BC_2_09_008_binary_interrupt_invariant_no_ok_on_interrupt()` (EC-004 and EC-006 combined;
node-level interrupt() only; Deny-path continues to own terminal, not E-MCP-010).

### AC-025 (traces to BC-2.09.008 INV-003 — Red Gate)
**Red Gate / Mandatory credential redaction on all `GraphAgentTool` isError paths:** All
`isError: true` paths from `GraphAgentTool` invocations — including `E-MCP-010`
interrupt-denied errors and any `Err(PregolyaError)` propagated from graph execution — pass
through `pregolya_mcp::sanitize::redact_credentials` before the MCP server populates
`content[0].text`. Only `PregolyaError::message` is used as the text source; the `.source()`
chain, `Debug` output, and `Display` output of the error are NEVER included in the MCP
response text. This obligation is unconditional per BC-2.09.007 {INV-003} extended to all
`GraphAgentTool` error paths. Verified by
`test_BC_2_09_008_graph_agent_error_paths_credential_redaction()` (mock graph returning
`Err(PregolyaError { message: "failed: sk-ant-abc123XYZabc123XYZ1234567890123456", .. })`;
assert `content[0].text` contains `<redacted>`, not the key material).

### AC-026 (traces to BC-2.09.008 EC-004 — Red Gate)
**Red Gate / Node interrupt under DenyInterrupts → E-MCP-010:** When a graph node calls
`interrupt()` during execution with `approval_policy = DenyInterrupts` (default, constructed
via `from_graph` without `.with_approval_policy`), `GraphRunner::run` detects
`RunStatus::Interrupted` and the server returns
`{ "content": [{ "type": "text", "text": "graph agent tool invocation interrupted at MCP boundary: HITL approval not supported for synchronous tools/call; configure the graph to not interrupt, or register with GraphToolApprovalPolicy::ForceApproveHooks if read-only" }], "isError": true }`.
The error code is `E-MCP-010` (GraphAgentInterruptDenied — NOT E-MCP-006, which is
McpContentUnsupported, a distinct error minted in burst-240). The interrupted run is NOT
persisted to durable checkpoint. Credential redaction applies per {INV-003}. {INV-002} holds.
Verified by `test_BC_2_09_008_ec004_node_interrupt_deny_policy_e_mcp_010()`.

### AC-027 (traces to BC-2.09.008 EC-007 — Red Gate, validates VP-016)
**Red Gate / STATE-ISOLATION — extra fields excluded from output:** When `GraphState S` has
fields `answer: String`, `internal_checkpoint_id: String`, and
`accumulated_messages: Vec<serde_json::Value>`, and
`extract_output = |s: &S| json!({ "answer": s.answer })`, a successful graph run produces
`ToolOutput::Structured { value: json!({"answer": "<final>"}) }`. The fields
`internal_checkpoint_id` and `accumulated_messages` do NOT appear anywhere in the MCP
response. {INV-001} STATE-ISOLATION holds. VP-016 proptest verifies this property over
arbitrary `S` instances with additional fields. Verified by
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
**Red Gate / Mandatory ActionRisk runtime gate under ForceApproveHooks (fail-closed on None):**
Under `GraphToolApprovalPolicy::ForceApproveHooks`, when a `PreToolCallHook` returns
`PendingHumanApproval`, `BoundaryApprovalHook` checks `preview.action_risk`
(`Option<ActionRisk>`) BEFORE overriding. If `preview.action_risk` is `None` (un-annotated
tool — fail-closed, per the fail-closed default in {INV-004}) OR `Some(r)` where
`r >= ActionRisk::Medium` (e.g., `ActionRisk::High`), the hook MUST return `Deny` (not
`Approve`) and:
- emit `E-MCP-011 ForceApproveWriteBlocked` (NOT `E-MCP-010`, which is `GraphAgentInterruptDenied`);
- log at CRITICAL level with structured key `mcp.graph_tool.force_approve_write_blocked`;
- NOT invoke the tool.
`None` (undeclared risk) fails closed identically to `Some(>= Medium)` — undeclared tools
require the highest gate per {INV-004}. If `preview.action_risk` is `Some(r)` where
`r < ActionRisk::Medium`, the override proceeds to `Approve`. Both the `None` case (TV-012:
un-annotated tool → `Deny` + `E-MCP-011`) and the `Some(High)` case (TV-008:
`ActionRisk::High` → `Deny` + `E-MCP-011`) must be tested. This is a Red Gate: without the
`ActionRisk` check, `ForceApproveHooks` would permit write-class tools and un-annotated tools
to execute at an MCP boundary without any human approval gate. Verified by
`test_BC_2_09_008_force_approve_hooks_action_risk_medium_emits_e_mcp_011_not_invoked()`
(TV-008, `Some(High)` path) and
`test_BC_2_09_008_force_approve_hooks_action_risk_none_fails_closed_emits_e_mcp_011()`
(TV-012, `None`/undeclared path).

### AC-031 (traces to BC-2.09.008 INV-001 — error-path UUID sanitization, Red Gate)
**Red Gate / Mandatory UUID sanitization on all isError paths (STATE-ISOLATION — error-path
extension):** On any `isError: true` MCP response from a `GraphAgentTool` invocation,
`content[0].text` must NOT contain UUID v4 values (format:
`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`) which may represent checkpoint IDs, run IDs, or thread
IDs that leak internal graph execution context. The STATE-ISOLATION guarantee ({INV-001})
extends to error paths. The framework applies two unconditional sanitization passes to
`isError: true` responses: (1) `redact_credentials` (existing, AC-025); (2)
`sanitize_internal_ids` — UUID v4 pattern removal chained after `redact_credentials`. Node
implementations must not rely on framework sanitization — error messages must exclude internal
IDs at the authoring site. BC-2.09.008 TV-009 verifies: a graph node returning
`Err(PregolyaError { message: "operation failed for run <example-run-id>",
.. })` produces a response where `content[0].text` does NOT contain the UUID. This is a Red
Gate: without `sanitize_internal_ids`, internal graph execution identifiers would leak to
external MCP clients via error messages. Verified by
`test_BC_2_09_008_error_path_uuid_sanitization_strips_internal_ids()`.

### AC-032 (traces to BC-2.09.008 INV-005 — extract_output credential opacity)
**extract_output success-path is NOT framework-sanitized (caller/DI-010 obligation):** The
`extract_output` closure is the sole data-exit path on the success path ({INV-001}). The
framework does NOT apply `redact_credentials` or `sanitize_internal_ids` to the success-path
result of `extract_output`. A caller providing
`extract_output = |s: &S| json!({ "api_key": s.api_key })` with `api_key = "sk-abc123"` in
the final graph state will receive a response where `content[0].text` contains
`"api_key":"sk-abc123"` VERBATIM — the framework does not strip it post-hoc. The DI-010
Credential Opacity obligation is the CALLER's responsibility: `extract_output` must not select
credential-bearing fields. BC-2.09.008 TV-010 verifies this boundary: the success path asserts
the leaking output IS preserved (framework does not sanitize it). Verified by
`test_BC_2_09_008_extract_output_success_path_framework_does_not_sanitize()`.

### AC-033 (traces to BC-2.09.008 EC-010 — extract_output panic recovery, Red Gate)
**Red Gate / extract_output panic caught via UnwindSafe boundary — static response:** When the
`extract_output` closure provided to `GraphAgentTool::from_graph` panics during execution after
successful graph completion (a programming error in the caller-supplied closure), the MCP
server's `UnwindSafe` boundary catches the panic. The response MUST be:
`{ "content": [{ "type": "text", "text": "internal error" }], "isError": true }`.
The response text is the static string `"internal error"` — no panic message, backtrace, or
internal state is forwarded to the external MCP client. Server availability is preserved: a
subsequent valid `tools/call` to a different (non-panicking) tool still returns `isError: false`.
BC-2.09.008 TV-011 verifies this scenario. This is a Red Gate: without `UnwindSafe` handling,
a panicking `extract_output` closure would crash the server process, causing a denial-of-service
at the MCP boundary. Verified by
`test_BC_2_09_008_ec010_extract_output_panic_caught_unwindsafe_static_response()`.

### AC-034 (traces to BC-2.09.007 PC-002 — success-path credential boundary)
**BC-2.09.007 success-path: framework does NOT sanitize ToolOutput success variants (DI-010
caller obligation):** The framework applies `redact_credentials` to **error paths only** (see
BC-2.09.007 {INV-003} and AC-013). Success-path `result_text` — whether from
`ToolOutput::Structured { value }` or `ToolOutput::Text { text }` — is NOT framework-sanitized.
Tool implementations MUST NOT embed credential material in success `ToolOutput` variants; the
DI-010 Credential Opacity obligation binds every `DynTool` implementation (caller/registration
obligation, not server obligation). BC-2.09.007 TV-009 verifies this boundary: a `MockTool`
returning `ToolOutput::Text { text: "key=sk-abc123XYZabc123XYZabc" }` on the success path
produces a response where `content[0].text` equals `"key=sk-abc123XYZabc123XYZabc"` verbatim
— the key material is preserved; the framework does not strip it. Verified by
`test_BC_2_09_007_success_path_credential_boundary_framework_does_not_sanitize()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `McpServer` | `pregolya-mcp/src/server.rs` | effectful (binds transport, accepts connections) |
| `McpServerConfig` | `pregolya-mcp/src/server.rs` | pure-core (config struct) |
| `McpServerHandle` | `pregolya-mcp/src/server.rs` | effectful (shutdown triggers I/O) |
| `ToolRegistry` | `pregolya-mcp/src/registry.rs` | pure-core (Arc-wrapped HashMap; thread-safe reads) |
| `tools/list` handler | `pregolya-mcp/src/server.rs` | pure-core (reads registry, serializes; no I/O beyond response) |
| `tools/call` handler | `pregolya-mcp/src/server.rs` | effectful (invokes registered `DynTool`) |
| `GraphAgentTool<S>` | `pregolya-mcp/src/graph_tool.rs` | effectful (invokes `GraphRunner::run`; LLM + tool I/O) |
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
| `tools/call` handler | effectful | Invokes `DynTool::invoke` which may perform I/O |
| `GraphAgentTool<S>` | effectful | Calls `GraphRunner::run` which performs LLM API I/O and tool invocations |
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
| EC-009 | `GraphAgentTool`: `ForceApproveHooks` + node `interrupt()` | PreToolCallHook overridden to Approve; node interrupt still → E-MCP-010 — BC-2.09.008 EC-006, {INV-002} |
| EC-010 | `GraphAgentTool`: `extract_output` returns `Value::Null` | `result_text = "null"`, `isError: false` — BC-2.09.008 EC-008 |
| EC-011 | `GraphAgentTool`: `ForceApproveHooks` + tool with `ActionRisk::High` (TV-008) or un-annotated `action_risk = None` (TV-012) — PendingHumanApproval received | `Deny` + `E-MCP-011` + CRITICAL log at `mcp.graph_tool.force_approve_write_blocked`; tool NOT invoked; `None` fails closed identically to `Some(>=Medium)` — BC-2.09.008 EC-009, {INV-004} |
| EC-012 | `GraphAgentTool`: `extract_output` closure panics after successful graph completion | `isError: true`, `content[0].text == "internal error"` (static); server continues serving subsequent requests — BC-2.09.008 EC-010 |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~5,800 |
| BC files (3 BCs; BC-2.09.006, BC-2.09.007, BC-2.09.008) | ~10,400 |
| `module-decomposition.md` SS-09 section | ~400 |
| `pregolya-mcp/src/server.rs` (new) | ~1,200 |
| `pregolya-mcp/src/registry.rs` (new) | ~500 |
| `pregolya-mcp/src/graph_tool.rs` (new) | ~1,800 |
| `pregolya-mcp/src/sanitize.rs` (new; includes `sanitize_internal_ids`) | ~550 |
| Test files (~200 lines; AC-001–AC-034 + 11 Red Gates) | ~3,000 |
| Tool outputs | ~600 |
| **Total** | **~24,250** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~12%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-034, including Red Gates: AC-013 (credential redaction VP-015), AC-023 (STATE-ISOLATION VP-016), AC-024 (binary interrupt invariant), AC-025 (GraphAgentTool error paths redaction), AC-026 (node interrupt → E-MCP-010), AC-027 (extra fields excluded VP-016), AC-028 (invalid input → -32602), AC-029 (Deny passthrough under ForceApproveHooks), AC-030 (ActionRisk block → E-MCP-011), AC-031 (error-path UUID sanitization), AC-033 (extract_output panic → static 'internal error') (test-writer step)
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
15. [ ] Implement `ToolOutput::Structured → serde_json::to_string` / `ToolOutput::Text → verbatim` result_text selection in tools/call handler (AC-016 / BC-2.09.007 {PC-002})
16. [ ] Run `cargo nextest run -p pregolya-mcp` — AC-001–AC-016 green (server + registry baseline)
17. [ ] Create `pregolya-mcp/src/graph_tool.rs` — `GraphAgentTool<S>` struct, `GraphToolApprovalPolicy` enum, `BoundaryApprovalHook` internal struct, `GraphRunner` type-erased trait
18. [ ] Implement `GraphAgentTool::from_graph` — accept `name`, `description`, `Arc<CompiledGraph<S>>`, `extract_output` closure; call `schemars::schema_for!(S)` at construction time; store `RootSchema` for `DynTool::schema()` (AC-017 / BC-2.09.008 PC-001)
19. [ ] Implement `DynTool` for `GraphAgentTool` — `name()`, `description()`, `schema()` returning stored `RootSchema`, `invoke_dyn()` dispatching graph execution (AC-018 / BC-2.09.008 PC-002)
20. [ ] **Red Gate check (AC-023):** confirm `test_BC_2_09_008_state_isolation_only_extract_output_in_result()` FAILS before STATE-ISOLATION enforcement is implemented (extra fields leak to `ToolOutput` without explicit exclusion)
21. [ ] **Red Gate check (AC-026):** confirm `test_BC_2_09_008_ec004_node_interrupt_deny_policy_e_mcp_010()` FAILS before E-MCP-010 interrupt-denied path is implemented
22. [ ] Implement `BoundaryApprovalHook` — DenyInterrupts path: override `PendingHumanApproval` → `Deny { reason: "HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY" }`; ForceApproveHooks path: override ONLY `PendingHumanApproval` to `Approve` (subject to ActionRisk check — tasks 31/33); `Deny` passes through unchanged (AC-021, AC-022, AC-029 / BC-2.09.008 PC-005/PC-006)
23. [ ] Implement STATE-ISOLATION enforcement — `invoke_dyn` returns ONLY `extract_output(&final_state)` result; no checkpoint IDs, run IDs, intermediate outputs, or graph metadata in output (AC-023, AC-027 / BC-2.09.008 INV-001; VP-016 proptest `graph_agent_tool_state_isolation` harness)
24. [ ] Register `E-MCP-010 GraphAgentInterruptDenied` in error taxonomy (EXEC, broken, Never) — note: NOT E-MCP-006 (that code is McpContentUnsupported, minted burst-240; PO-authoritative mint is E-MCP-010 per ADR-029 §Decision 5)
25. [ ] Extend `pregolya_mcp::sanitize::redact_credentials` usage to cover all `GraphAgentTool` isError paths — E-MCP-010 interrupt error and `Err(PregolyaError)` from graph execution (AC-025 / BC-2.09.008 INV-003)
26. [ ] Add `schemars` dependency to `pregolya-mcp/Cargo.toml` (workspace pin)
27. [ ] Add `pregolya-graph` dependency to `pregolya-mcp/Cargo.toml` (workspace pin; BC-2.09.008/ADR-029 dep edge — pregolya-mcp now depends on pregolya-graph for GraphAgentTool)
28. [ ] Update `pregolya-mcp/src/lib.rs` — re-export `GraphAgentTool`, `GraphToolApprovalPolicy`; expose `graph_tool` module
29. [ ] Run `cargo nextest run -p pregolya-mcp` — AC-001–AC-028 green (pre-security-hardening baseline; run again after tasks 30–39)
30. [ ] **Red Gate check (AC-029):** confirm `test_BC_2_09_008_force_approve_hooks_deny_passes_through_unchanged()` FAILS before Deny-passthrough enforcement is implemented (Deny would be incorrectly converted to Approve)
31. [ ] Implement Deny-passthrough in `BoundaryApprovalHook` under `ForceApproveHooks` — verify `PreToolDecision::Deny` is not converted to `Approve`; only `PendingHumanApproval` is eligible for override (AC-029 / BC-2.09.008 PC-006)
32. [ ] **Red Gate check (AC-030):** confirm `test_BC_2_09_008_force_approve_hooks_action_risk_medium_emits_e_mcp_011_not_invoked()` FAILS before `ActionRisk` gate is implemented (write-class tool would be invoked without the check)
33. [ ] Implement `ActionRisk` runtime gate in `BoundaryApprovalHook` — check `preview.action_risk` before overriding `PendingHumanApproval`; if `None` (un-annotated tool, fail-closed) OR `>= ActionRisk::Medium` return `Deny` + emit `E-MCP-011 ForceApproveWriteBlocked` + CRITICAL log at `mcp.graph_tool.force_approve_write_blocked`; `None` fails closed identically to `Some(>= Medium)` per {INV-004}; register `E-MCP-011` in error taxonomy; implement two test paths: TV-008 (`Some(High)`) and TV-012 (`None`/undeclared) (AC-030 / BC-2.09.008 INV-004, EC-009)
34. [ ] **Red Gate check (AC-031):** confirm `test_BC_2_09_008_error_path_uuid_sanitization_strips_internal_ids()` FAILS before `sanitize_internal_ids` is implemented (UUID v4 leaks to response text on isError paths)
35. [ ] Implement `sanitize_internal_ids(text: &str) -> Cow<str>` in `pregolya_mcp::sanitize` — UUID v4 pattern removal (`[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}`, case-insensitive); chain after `redact_credentials` on all `GraphAgentTool` `isError: true` paths (AC-031 / BC-2.09.008 INV-001)
36. [ ] **Red Gate check (AC-033):** confirm `test_BC_2_09_008_ec010_extract_output_panic_caught_unwindsafe_static_response()` FAILS before `UnwindSafe` is implemented (unhandled panic crashes the handler, no `isError` response)
37. [ ] Implement `UnwindSafe` boundary for `extract_output` invocation — catch panic → `isError: true`, `content[0].text == "internal error"` (static; no panic message or backtrace forwarded); ensure server continues serving subsequent requests (AC-033 / BC-2.09.008 EC-010)
38. [ ] Write boundary test confirming success-path `ToolOutput` is NOT framework-sanitized: `MockTool` returning `ToolOutput::Text { text: "key=sk-abc123XYZabc123XYZabc" }` → assert `content[0].text` equals the raw string verbatim (AC-034 / BC-2.09.007 PC-002)
39. [ ] Write boundary test confirming `extract_output` success-path result is NOT framework-sanitized: closure selecting `api_key` field → assert success response preserves value verbatim (AC-032 / BC-2.09.008 INV-005)
40. [ ] Run `cargo nextest run -p pregolya-mcp` — all 34 ACs green (AC-001–AC-034)

## Previous Story Intelligence (MANDATORY)

S-2.10 established `MultiServerMcpClient`, `McpSessionGuard`, and the `pregolya-mcp` crate
structure (files: `client.rs`, `session.rs`, `tool.rs`, `interceptor.rs`, `guardrail.rs`,
`exception.rs`, `lib.rs`). S-2.10 does NOT create `registry.rs` or `ToolRegistry`.
S-2.11 introduces `ToolRegistry` for the first time (task 4 creates
`pregolya-mcp/src/registry.rs`). S-2.11 adds the complementary server role in the same crate,
with `ToolRegistry` serving both the server's `tools/list` handler and (via shared access)
the client-side tool resolution.

S-1.06 established `DynTool` as the object-safe dispatch seam. The `tools/call` handler
calls `DynTool::invoke(args)`. Use `ToolRegistry::get(name: &str) -> Option<Arc<dyn DynTool>>`
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
| `ToolOutput::Structured` → `serde_json::to_string` (compact); `ToolOutput::Text` → verbatim | BC-2.09.007 {PC-002} | Tests AC-016 |
| No `unwrap()`/`expect()` in server handlers | CLAUDE.md Code Conventions | Clippy |
| Registry read on each `tools/list` request (no startup snapshot) | BC-2.09.006 {PC-003} | Test AC-004 |
| `GraphAgentTool::from_graph` calls `schemars::schema_for!(S)` at construction time; schema stored for `DynTool::schema()` | BC-2.09.008 PC-001 | Test AC-017 |
| `GraphAgentTool::invoke_dyn` on success returns ONLY `extract_output(&final_state)` result (STATE-ISOLATION) | BC-2.09.008 INV-001; VP-016 | Test AC-023 Red Gate |
| Node-level `interrupt()` parking under DenyInterrupts → `Err(E-MCP-010)`; `BoundaryApprovalHook::Deny` continues to own terminal (NOT E-MCP-010); NO `Ok` when `RunStatus::Interrupted` | BC-2.09.008 INV-002 binary interrupt invariant | Test AC-024 Red Gate |
| `E-MCP-010` (not E-MCP-006) is the error code for `GraphAgentInterruptDenied` | BC-2.09.008 §Error Codes; ADR-029 §Decision 5 | Error taxonomy; test AC-026 |
| All `GraphAgentTool` isError paths apply `redact_credentials` on `PregolyaError::message` | BC-2.09.008 INV-003 | Test AC-025 Red Gate |
| `ForceApproveHooks` overrides ONLY `PreToolDecision::PendingHumanApproval` (subject to `ActionRisk` check); `Deny` passes through UNCHANGED; node-level `interrupt()` still → E-MCP-010 | BC-2.09.008 PC-006, INV-002, INV-004 | Tests AC-022, AC-029, AC-030 |
| `preview.action_risk` is `None` (un-annotated, fail-closed per {INV-004}) or `>= ActionRisk::Medium` under `ForceApproveHooks` → `Deny` + `E-MCP-011 ForceApproveWriteBlocked` (NOT `E-MCP-010`) + CRITICAL log at `mcp.graph_tool.force_approve_write_blocked`; `None` fails closed identically to `Some(>= Medium)` | BC-2.09.008 INV-004, EC-009 | Tests AC-030 Red Gate (TV-008 Some(High); TV-012 None) |
| `isError: true` error paths apply two unconditional sanitization passes: (1) `redact_credentials`, (2) `sanitize_internal_ids` (UUID v4 removal), in that order | BC-2.09.008 INV-001 | Test AC-031 Red Gate |
| `extract_output` success-path result is NOT framework-sanitized; DI-010 credential opacity is caller/registration obligation | BC-2.09.008 INV-005; BC-2.09.007 PC-002 | Tests AC-032, AC-034 |
| `extract_output` panic caught via `UnwindSafe`; response is static `"internal error"` (`isError: true`); server continues serving | BC-2.09.008 EC-010 | Test AC-033 Red Gate |

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
| `schemars` | workspace pin | `schema_for!(S)` inputSchema derivation in `GraphAgentTool::from_graph` (BC-2.09.008 PC-001) |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-mcp/src/server.rs` | CREATE | `McpServer`, `McpServerConfig`, `McpServerHandle`, `McpServerTransport` |
| `pregolya-mcp/src/registry.rs` | CREATE or MODIFY | `ToolRegistry` — shared with client side (extract if needed) |
| `pregolya-mcp/src/sanitize.rs` | CREATE | `pub fn redact_credentials(text: &str) -> Cow<str>` — 3 pattern substitutions (AC-013; BC-2.09.007 {INV-003}); `pub fn sanitize_internal_ids(text: &str) -> Cow<str>` — UUID v4 removal chained after `redact_credentials` on `isError: true` paths (AC-031; BC-2.09.008 INV-001) |
| `pregolya-mcp/src/graph_tool.rs` | CREATE | `GraphAgentTool<S>`, `GraphToolApprovalPolicy`, `BoundaryApprovalHook`, `GraphRunner` — STATE-ISOLATION enforcement; E-MCP-010 interrupt-denied path (BC-2.09.008; ADR-029) |
| `pregolya-mcp/src/lib.rs` | MODIFY | Re-export `McpServer`, `McpServerConfig`, `McpServerHandle`; expose `sanitize` module; re-export `GraphAgentTool`, `GraphToolApprovalPolicy`; expose `graph_tool` module |

## Changelog

- **1.3 (BC-2.09.006 + BC-2.09.007 / 2026-08-26):** BC-2.09.006 (EC-006 malformed JSON → -32700 Parse error; EC-007 invalid JSON-RPC → -32600 Invalid Request; wire-protocol responses, no E-MCP-* raised). BC-2.09.007 (INV-003 mandatory `redact_credentials` with source restriction + 3-pattern substitution; PC-002 result_text JSON-vs-plaintext selection rule; VP-MCPCALL-03 renamed VP-015). Story changes: (1) AC-013 updated to Red Gate — mandatory `pregolya_mcp::sanitize::redact_credentials` applied to `PregolyaError::message` only (source restriction); 3 patterns (sk-*, sk-ant-*, 64-char token); validates VP-015. (2) AC-014 added: BC-2.09.006 EC-006 + BC-2.09.007 EC-007 — -32700 Parse error wire-protocol response, no PregolyaError. (3) AC-015 added: BC-2.09.006 EC-007 + BC-2.09.007 EC-008 — -32600 Invalid Request wire-protocol response, no PregolyaError. (4) AC-016 added: BC-2.09.007 PC-002 — result_text selection rule (Structured→compact JSON, Text→verbatim). (5) `verification_properties` updated to `[VP-015]`. (6) `sanitize.rs` added to File Structure; Arch Compliance Rules table extended with 3 new rows. (7) Tasks updated to AC-016 and tasks 12–16 added. (8) BC table version column added.
- **1.4 (BC-2.09.008 / ADR-029 / GAP-01 / 2026-08-26):** Add BC-2.09.008 StateGraph-as-MCP-Tool coverage (GraphAgentTool; mcp::graph_tool). Story changes: (1) BC-2.09.008 added to `behavioral_contracts`; VP-016 added to `verification_properties`; `points` bumped 5→8. (2) AC-017–AC-022: BC-2.09.008 PC-001–PC-006 (from_graph + schemars schema derivation; DynTool + ToolRegistry + tools/list advertisement; schema-validate → -32602 / deserialize-fail → isError + redaction; terminal → Ok(ToolOutput::Structured); DenyInterrupts node interrupt → E-MCP-010; ForceApproveHooks hook-override + node-interrupt-still-E-MCP-010). (3) AC-023–AC-025: Red Gate INV ACs (INV-001 STATE-ISOLATION VP-016 proptest anchor; INV-002 binary interrupt invariant; INV-003 mandatory credential redaction on all isError paths). (4) AC-026–AC-028: Red Gate EC ACs (EC-004 node interrupt → E-MCP-010; EC-007 STATE-ISOLATION extra fields excluded VP-016; EC-001 invalid input → -32602 before invoke). (5) E-MCP-010 (GraphAgentInterruptDenied) cited throughout — NOT E-MCP-006 (McpContentUnsupported). (6) Architecture Mapping + Purity Classification + Edge Cases + Token Budget + Tasks + Arch Compliance Rules + Library Requirements + File Structure updated for graph_tool module. (7) Forbidden dependencies updated: pregolya-graph now ALLOWED in pregolya-mcp (BC-2.09.008/ADR-029 dep edge). (8) schemars added to Library Requirements. (9) graph_tool.rs added to File Structure.
- **1.5 (BC-2.09.008-v1.1 / BC-2.09.007-v1.9 / ADR-029-v1.2 / 2026-08-26):** Security hardening propagation (SEC-001/005/006/007/008). (1) AC-022 corrected: ForceApproveHooks overrides ONLY PendingHumanApproval (not ALL decisions); Deny passthrough per BC-2.09.008 {PC-006}. (2) AC-029 added: {PC-006} Deny-passthrough — PreToolDecision::Deny passes through unchanged under ForceApproveHooks (SEC-007). (3) AC-030 added: {INV-004}/EC-009 ActionRisk block — action_risk>=Medium emits E-MCP-011 ForceApproveWriteBlocked + CRITICAL log at mcp.graph_tool.force_approve_write_blocked (SEC-006). (4) AC-031 added: {INV-001}/TV-009 error-path UUID sanitization — sanitize_internal_ids chained after redact_credentials on isError paths (SEC-005). (5) AC-032 added: {INV-005}/TV-010 extract_output credential opacity — success path not framework-sanitized; DI-010 caller obligation (SEC-001). (6) AC-033 added: EC-010/TV-011 extract_output panic — UnwindSafe catch → static 'internal error'; server continues (SEC-008). (7) AC-034 added: BC-2.09.007 {PC-002}/TV-009 success-path credential boundary — framework sanitizes error paths only (SEC-001). (8) Edge Cases EC-011 (ActionRisk block) and EC-012 (extract_output panic) added. (9) Tasks 30–40 added (security hardening implementation sequence; Red Gate checks). (10) Arch Compliance Rules: existing ForceApproveHooks row corrected; 5 new rows added. (11) sanitize.rs File Structure entry extended with sanitize_internal_ids. (12) Token Budget updated. (13) Frontmatter changelog reordered to ascending order.
- **1.6 (F-057-01 / F-057-02 / OBS / 2026-08-26):** Round-2 BC-2.09.008 security corrections propagated. (1) AC-030 (F-057-01): ActionRisk gate is now fail-closed on `None` — `preview.action_risk` is `None` (un-annotated tool, fail-closed per {INV-004}) OR `Some(r >= Medium)` → `Deny` + `E-MCP-011 ForceApproveWriteBlocked` + CRITICAL log; `None` fails closed identically to `Some(>=Medium)`; TV-012 cited for `None` path (TV-008 for `Some(High)` path); second test function `test_BC_2_09_008_force_approve_hooks_action_risk_none_fails_closed_emits_e_mcp_011()` added. (2) AC-021 (F-057-02): `BoundaryApprovalHook::Deny` path corrected — graph CONTINUES executing after Deny; valid terminal → `Ok(ToolOutput::Structured)` per {PC-004}; error terminal → graph's OWN `Err(PregolyaError)` (NOT `E-MCP-010`); `E-MCP-010` raised ONLY on node-level `interrupt()` parking (`RunStatus::Interrupted`); test renamed to `test_BC_2_09_008_pending_approval_under_deny_continues_to_terminal()`. (3) AC-024 (F-057-02): Binary-interrupt invariant scoped to node-level `interrupt()` PARKING only; `BoundaryApprovalHook::Deny` path explicitly excluded (graph continues to own terminal, NOT `E-MCP-010`); test clarified. (4) OBS: all BC-2.09.008 and BC-2.09.007 AC heading traces normalized from `§{CLAUSE}` to plain `CLAUSE` form consistent with sibling BC-2.09.006 trace format throughout; Task 33 updated for `None` case; EC-011 updated to cover both TV-012 (`None`) and TV-008 (`Some(High)`) cases; Arch Compliance Rules binary-interrupt and ActionRisk rows updated.
