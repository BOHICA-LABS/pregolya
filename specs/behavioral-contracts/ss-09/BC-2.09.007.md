---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.007
version: "2.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-09
capability: CAP-021
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-26T00:00:00Z
changelog:
  - "1.0 (2026-07-15, initial): base BC authored — MCP server tool call dispatch via ToolRegistry."
  - "1.1 (FIX-BURST-277-WAVE-B-errata/2026-07-28): Architecture Anchors — ToolRegistry type corrected: `Option<Arc<dyn Tool>>` → `Option<Arc<dyn DynTool>>` (architect scope — planned implementation signature; dyn Tool is non-object-safe per ADR-005 §Adjacent Trait Object-Safety Adjudications; ToolRegistry must use DynTool for vtable dispatch)."
  - "1.2 (WAVE-B-NOTATION-SWEEP/2026-07-29): (1) EC-002 §Scenario: CLASS3_UNICODE_ELLIPSIS_VIOLATION — `PregolyaError { … }` corrected to `PregolyaError { .. }` per ADR-010 §Error-Construction Notation Canon Class 3 (discriminator sub-class CLASS3_UNICODE_ELLIPSIS_VIOLATION: U+2026 in brace-whitespace field-elision position). (2) v1.1 frontmatter entry: de-pinned volatile ADR-005 version pin to section anchor `ADR-005 §Adjacent Trait Object-Safety Adjudications` per TD-VSDD-091."
  - "1.3 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.11 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.4 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.5 (P2A-044 F-06/2026-08-24): compressed-ordinal citations normalized to stable tags."
  - "1.6 (burst-B-SS09-11/bc-scan-hardening/2026-08-26): (1) MED+SECURITY gap — INV-003 credential-message sanitization: removed 'best-effort v1' hedge; specified mandatory `pregolya_mcp::sanitize::redact_credentials` step with pattern rules and source-restriction (PregolyaError::message only, not .source() chain or Debug). PC-003 updated to reference {INV-003} redaction. VP-MCPCALL-03 added. TV-007 added (fake key pattern → `<redacted>`). (2) LOW gap — PC-002 result_text JSON-vs-plaintext selection rule specified (`ToolOutput::Structured` → compact JSON via `serde_json::to_string`; `ToolOutput::Text` → verbatim). (3) LOW gap — EC-007 (-32700 parse error) and EC-008 (-32600 invalid request) added with wire-protocol JSON-RPC response specification. TV-008 added. ADR-027 stable clause anchors {EC-007}, {EC-008}."
  - "1.7 (B-SS09-11-arch-adjudication/2026-08-26): VP-MCPCALL-03 renamed to VP-015 everywhere in BC body — architect registered this property as formal VP-015 in Phase-2 BC-completeness reconciliation. TD-VSDD-060 sibling-sweep applied: all VP-MCPCALL-03 occurrences replaced (§Verification Properties table and §VP Anchors). No behavioral or semantic change."
  - "1.8 (D-260-header-norm/2026-08-26): EC subsection headers normalized to D-260 canonical ### EC-NNN form (braces removed); verify-ac-pc-trace resolution fix; no semantic change."
  - "1.9 (B-SS09-sec-adjudication/ADR-029-SEC-001-SEC-002/2026-08-26): (1) SEC-001 — {PC-002} extended with success-path credential boundary obligation: Tool implementations MUST NOT embed credentials in ToolOutput success variants; framework sanitizes error paths only; DI-010 obligation binds every DynTool. TV-009 added (MockTool success-path asserts framework does NOT strip success-path content — boundary belongs to the Tool, not the server). (2) SEC-002 — {INV-003} extended with pluggable pattern registry note: three patterns cover first-party providers; partner crates SHOULD register additional patterns for new key formats; mandatory error-path behavior unchanged."
  - "2.0 (round-10/GAP-01-type-grounding/2026-08-27): Type-grounding reconciliation — `DynTool::invoke_dyn` return type corrected per ADR-029 §Symbol Grounding (architect symbol-existence audit): returns `Result<serde_json::Value, PregolyaError>` (NOT `ToolOutput`). {PC-002} result_text selection rule rewritten: rule now operates on the `serde_json::Value` returned by `invoke_dyn` directly — `Value::Null` → `\"null\"`, `Value::String(s)` → `s` verbatim, other `Value` types (Object/Array/Bool/Number) → `serde_json::to_string(&value)` (compact JSON). Success-path credential boundary note updated: credential material must not be embedded in the `serde_json::Value` returned by `invoke_dyn`. TV-009 updated: `ToolOutput::Text{ text }` → `Ok(Value::String(text))`. Zero residual `ToolOutput::Structured` in live body text post-edit."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-021
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "a403241"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.09.007: MCP Server Tool Invocation (tools/call; External Client Executes Registered Tool)

## Description

When an external MCP client sends a `tools/call` JSON-RPC request to the pregolya MCP
server, the server routes the call to the registered pregolya `Tool` matching the requested
tool name, executes it with the provided arguments, and returns the result as an MCP
`CallToolResult` response. This BC covers the full invocation path: request parsing, tool
lookup, execution dispatch, result serialization, and error response formatting. The server
executes the tool synchronously within its request handler — there is no async streaming
of intermediate tool results in v1 (the MCP `tools/call` response is a single result message).

## Preconditions

1. {PRE-001} The MCP server (BC-2.09.006) is started and has at least one tool registered.
2. {PRE-002} An external MCP client has connected and sends a `tools/call` JSON-RPC request with:
   `{ "method": "tools/call", "params": { "name": "<tool_name>", "arguments": {…} } }`.
3. {PRE-003} The `arguments` object is a valid JSON object (may be empty `{}`).

## Postconditions

1. {PC-001} The server parses the `tools/call` request and looks up `<tool_name>` in the
   `ToolRegistry`. If found, the registered `Tool` is executed with the provided `arguments`
   JSON parsed to the tool's input schema.
2. {PC-002} On **successful execution:** the server responds with:
   `{ "content": [{ "type": "text", "text": "<result_text>" }], "isError": false }`.
   **result_text selection rule:** `result_text` is determined by the `serde_json::Value`
   returned by `DynTool::invoke_dyn`:
   - `Value::Null` → `result_text = "null"`.
   - `Value::String(s)` → `result_text = s` verbatim. No JSON-encoding or additional
     escaping is applied.
   - All other `Value` types (Object, Array, Bool, Number) → `result_text =
     serde_json::to_string(&value)` (compact JSON; no pretty-printing).
   The `DynTool` implementation determines the `Value` shape; the server applies the
   corresponding serialization rule.
   **Success-path credential boundary (DI-010):** `DynTool` implementations MUST NOT embed
   credential material (API keys, access tokens, secrets) in the `serde_json::Value`
   returned by `invoke_dyn`. The framework applies `redact_credentials` to **error
   paths only** (see {INV-003}); success-path `result_text` is **NOT** framework-sanitized.
   This obligation derives from DI-010 (Credential Opacity) and binds every `DynTool`
   implementation.
3. {PC-003} On **tool execution error** (the pregolya `Tool::invoke` returns `Err`): the server
   responds with:
   `{ "content": [{ "type": "text", "text": "<error_message>" }], "isError": true }`.
   The `isError: true` flag is the MCP protocol signal for tool-level failures. The response
   is a valid MCP response (not a JSON-RPC protocol error); the JSON-RPC result layer
   carries `isError: true` in the content.
   **Mandatory sanitization:** before populating `<error_message>`, the server applies the
   credential redaction step specified in {INV-003}: only `PregolyaError::message` is used
   as the source string (never `.source()`, `Debug`, or `Display`), and that string is passed
   through `pregolya_mcp::sanitize::redact_credentials` before inclusion in the response.
4. {PC-004} On **tool not found** (`<tool_name>` is not in the registry): the server responds with
   a JSON-RPC error: `{ "code": -32602, "message": "Tool not found: <tool_name>" }`.
   (JSON-RPC -32602 = InvalidParams — the tool name is an invalid parameter for this server.)
5. {PC-005} On **argument schema validation failure** (arguments do not conform to the tool's input
   schema): the server responds with:
   `{ "code": -32602, "message": "Invalid arguments for tool '<tool_name>': <schema_error>" }`.
6. {PC-006} The invocation is executed under the server's `ExecutionContext`, which includes the
   `RunnableConfig` and any configured `BudgetPolicy` attached to the server instance.
   If the tool invocation exceeds its budget, the standard `E-BUDGET-001` applies and the
   server responds with `isError: true`.

## Invariants

- {INV-001} **Synchronous execution in v1:** the server executes `Tool::invoke` synchronously and
  awaits the result before responding to the MCP client. Streaming intermediate results from
  long-running tools is deferred to v2.
- {INV-002} **isError semantics:** `isError: true` in the `CallToolResult` means the tool returned
  an error, but the MCP protocol transaction itself succeeded. The JSON-RPC layer returns
  `result` (not `error`) in both the success and tool-error cases. JSON-RPC `error` is only
  used for protocol-level failures (unknown method, invalid params, parse error).
- {INV-003} **Mandatory credential redaction (DI-010):** Tool execution error messages included
  in MCP `CallToolResult` responses MUST be sanitized before transmission. This invariant is
  mandatory — there is no "best-effort" variant. The concrete redaction step:
  (a) **Source restriction:** only `PregolyaError::message` is used as the text source. The
      `.source()` chain, `Debug` output, and `Display` output of the error are NEVER included
      in the MCP response text.
  (b) **Redaction function:** `pregolya_mcp::sanitize::redact_credentials(text: &str) ->
      Cow<str>` applies the following substitution rules in order:
      1. OpenAI key pattern `sk-[A-Za-z0-9_\-]{20,}` → `"<redacted>"`
      2. Anthropic key pattern `sk-ant-[A-Za-z0-9_\-]{32,}` → `"<redacted>"`
      3. Generic long alphanumeric token `[A-Za-z0-9]{64,}` → `"<redacted>"`
  (c) The sanitized string (post-substitution) is placed in `content[0].text`.
  Rationale: untrusted tool output (e.g., from MCP-dispatched tools) may propagate error
  messages that embed provider API key material from the tool's own configuration. The server
  MUST apply redaction before transmitting any error detail to an external MCP client.
  (invariants.md §DI-010: Credential Opacity)
  **Pluggable pattern registry:** the three patterns above cover the first-party providers
  (OpenAI `sk-`, Anthropic `sk-ant-`, generic 64+ alphanumeric token). Partner crates that
  introduce new API key formats (e.g., a provider with a distinct key prefix or length) SHOULD
  register additional patterns in `redact_credentials` via the pluggable pattern registry.
  Extending the registry does not alter the mandatory error-path redaction behavior —
  additional patterns add coverage without weakening the invariant.
- {INV-004} **One invocation per request:** a single `tools/call` request invokes exactly one tool
  exactly once. No fan-out, no retry within the server handler.

## Edge Cases

### EC-001: Tool not found
**Scenario:** Client sends `tools/call` with `name: "nonexistent_tool"`.
**Expected behavior:** JSON-RPC error response `{ "code": -32602, "message": "Tool not
found: nonexistent_tool" }`. No tool execution attempted.

### EC-002: Tool returns an error (Err result)
**Scenario:** The pregolya `Tool::invoke` returns `Err(PregolyaError { .. })` (e.g., the
tool made a failing HTTP request).
**Expected behavior:** MCP response: `{ "content": [{ "type": "text", "text":
"<PregolyaError message>" }], "isError": true }`. JSON-RPC result is a success (the MCP
transaction succeeded); the tool result carries `isError: true`.

### EC-003: Arguments fail schema validation
**Scenario:** Tool `get_weather` expects `{ "location": string }` but client sends
`{ "city": "Paris" }` (wrong key name).
**Expected behavior:** JSON-RPC error `{ "code": -32602, "message": "Invalid arguments for
tool 'get_weather': missing required property 'location'" }`. Tool not invoked.

### EC-004: Tool invocation exceeds budget
**Scenario:** Server has a `BudgetPolicy` configured; the tool invocation triggers
`E-BUDGET-001 BudgetCeilingReached`.
**Expected behavior:** MCP response: `{ "content": [{ "type": "text",
"text": "run halted: budget ceiling reached" }], "isError": true }`.

### EC-005: Multiple concurrent tools/call requests
**Scenario:** Two MCP clients simultaneously send `tools/call` requests for different tools.
**Expected behavior:** Both invocations execute concurrently (the server handles them as
separate async tasks). Neither invocation observes the other's state. Results are returned
independently to each client.

### EC-006: Tool registered after server start; client invokes it
**Scenario:** Tool "new_tool" is registered after `McpServer::start`. Client sends
`tools/call { name: "new_tool" }`.
**Expected behavior:** Invocation succeeds — the registry is read on each request (same
semantics as BC-2.09.006 PC-003 for `tools/list`).

### EC-007: Malformed JSON — parse error on server receive
**Scenario:** A connected MCP client sends bytes that are not valid JSON (e.g., a
truncated message, binary data, or `"not json{{"`).
**Expected behavior:** The server responds with a JSON-RPC protocol error:
`{ "jsonrpc": "2.0", "id": null, "error": { "code": -32700, "message": "Parse error" } }`.
JSON-RPC -32700 is the standard parse-error code; this is a wire-protocol response, not a
`PregolyaError` — no `E-MCP-*` code is raised. The connection remains open; subsequent
well-formed requests are processed normally. (Per Burst A error-taxonomy v1.58 reuse
decision: JSON-RPC -32700/-32600 on server-receive are wire-protocol responses cited
directly.)

### EC-008: Invalid JSON-RPC request structure
**Scenario:** A connected MCP client sends valid JSON that is not a well-formed JSON-RPC
request (e.g., missing `"jsonrpc"` version field, missing `"method"` field, or `"id"` is
not a string/number/null).
**Expected behavior:** The server responds with a JSON-RPC protocol error:
`{ "jsonrpc": "2.0", "id": null, "error": { "code": -32600, "message": "Invalid Request" } }`.
JSON-RPC -32600 is the standard invalid-request code; wire-protocol response only, no
`PregolyaError` raised. The connection remains open.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `tools/call { name: "echo", arguments: { "text": "hello" } }`; `echo` tool registered and returns "hello" | `{ "content": [{ "type": "text", "text": "hello" }], "isError": false }` | Happy-path invocation |
| TV-002 | `tools/call { name: "fail_tool" }`; tool returns `Err(…)` | `{ "content": [{ "type": "text", "text": "<error message>" }], "isError": true }` | Tool execution error |
| TV-003 | `tools/call { name: "unknown_tool" }` | JSON-RPC error `{ "code": -32602, "message": "Tool not found: unknown_tool" }` | Tool not found |
| TV-004 | `tools/call { name: "get_weather", arguments: { "city": "Paris" } }` (wrong schema) | JSON-RPC error `{ "code": -32602, "message": "Invalid arguments…" }` | Schema validation |
| TV-005 | Two simultaneous `tools/call` requests for different tools | Both return correct results independently | Concurrent invocations |
| TV-006 | Tool registered after server start; client invokes it | `isError: false` response with tool result | Dynamic registry |
| TV-007 | `tools/call { name: "api_tool" }`; tool returns `Err(PregolyaError { message: "request failed: key=sk-abc123XYZabc123XYZabc", .. })` | MCP response `{ "content": [{ "type": "text", "text": "request failed: key=<redacted>" }], "isError": true }` — OpenAI-pattern key replaced by `<redacted>` | Credential redaction (INV-003) |
| TV-008 | Client sends non-JSON bytes (e.g., `"not json{{"`) via `tools/call` path | JSON-RPC response `{ "error": { "code": -32700, "message": "Parse error" } }` | Malformed JSON — parse error (EC-007) |
| TV-009 | `tools/call { name: "mock_tool" }`; MockTool returns `Ok(Value::String("key=sk-abc123XYZabc123XYZabc".to_string()))` (success path) | MCP response `{ "content": [{ "type": "text", "text": "key=sk-abc123XYZabc123XYZabc" }], "isError": false }` — key material is preserved verbatim (Value::String → verbatim rule); success-path content is NOT framework-sanitized | Success-path credential boundary: framework does NOT strip; Tool implementation bears sole obligation ({PC-002} DI-010) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-MCPCALL-01 | External MCP client can successfully invoke a registered pregolya tool via tools/call and receive the correct result | Integration test: start server; connect MCP client library; invoke tool; assert result content | Wave 2 |
| VP-MCPCALL-02 | Tool execution error surfaces as `isError: true` in MCP response (not as a JSON-RPC protocol error) | Unit test: mock tool returning Err; assert response has isError: true and result-layer success | Wave 2 |
| VP-015 | Credential redaction: MCP response `content[0].text` has API key patterns replaced with `<redacted>` before transmission | Unit test: mock tool returning `Err` with fake OpenAI/Anthropic key pattern in `PregolyaError::message`; assert response text contains `<redacted>` and not the key material | Wave 2 |

## Related BCs

- BC-2.09.006 — depends on: tool advertisement (tools/list) is the discovery path; this BC is the execution path that follows discovery
- BC-2.09.004 — related to: MCP client ToolException (E-MCP-001) is the client-side equivalent of the tool-error signal; MCP server uses isError: true for the same semantics in server-direction
- BC-2.10.001 — related to: budget governance applies to tool invocations dispatched through the MCP server

## Architecture Anchors

- `pregolya-mcp/src/server.rs` (`mcp::server`) — `tools/call` request handler: parse arguments, look up tool in `ToolRegistry`, call `Tool::invoke`, serialize `ToolOutput` to `CallToolResult`, format JSON-RPC responses for success / tool-error / protocol-error cases
- `pregolya-mcp/src/registry.rs` — `ToolRegistry::get(name: &str) -> Option<Arc<dyn DynTool>>` used by the invocation handler (DynTool is the object-safe dispatch seam; ADR-005 §Adjacent Trait Object-Safety Adjudications)

## Story Anchor

S-2.11

## VP Anchors

- VP-MCPCALL-01, VP-MCPCALL-02, VP-015

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-021 |
| Capability Anchor Justification | CAP-021 ("MCP Server Role (Expose Registered Tools as MCP Server Endpoint)") per capabilities-p1-p2.md §CAP-021 — this BC specifies the `tools/call` invocation path: routing an external MCP client's tool-call request to the registered pregolya Tool and returning the result, which is the core "invoke pregolya tools via MCP protocol" behavior CAP-021 defines |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — parse failures and tool-not-found return JSON-RPC error responses, not panics), DI-010 (Credential Opacity — error messages must not embed credential values), DI-014 (Error Propagation — tool execution errors surface as isError: true; protocol errors surface as JSON-RPC error; no silent swallowing) |
| Domain D Forcing Function | domain-d-hermes-agent.md req 11 — "pregolya exposes its own tools and resources via the MCP protocol so that other LLM applications can connect as clients"; `tools/call` is the execution surface that makes this useful |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration) |
| Module | pregolya-mcp (`mcp::server`) |
