---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.007
version: "1.0"
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
timestamp: 2026-07-15T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-021
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "5aa612a"
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

When an external MCP client sends a `tools/call` JSON-RPC request to the ferrochain MCP
server, the server routes the call to the registered ferrochain `Tool` matching the requested
tool name, executes it with the provided arguments, and returns the result as an MCP
`CallToolResult` response. This BC covers the full invocation path: request parsing, tool
lookup, execution dispatch, result serialization, and error response formatting. The server
executes the tool synchronously within its request handler — there is no async streaming
of intermediate tool results in v1 (the MCP `tools/call` response is a single result message).

## Preconditions

1. The MCP server (BC-2.09.006) is started and has at least one tool registered.
2. An external MCP client has connected and sends a `tools/call` JSON-RPC request with:
   `{ "method": "tools/call", "params": { "name": "<tool_name>", "arguments": {…} } }`.
3. The `arguments` object is a valid JSON object (may be empty `{}`).

## Postconditions

1. The server parses the `tools/call` request and looks up `<tool_name>` in the
   `ToolRegistry`. If found, the registered `Tool` is executed with the provided `arguments`
   JSON parsed to the tool's input schema.
2. On **successful execution:** the server responds with:
   `{ "content": [{ "type": "text", "text": "<result_text>" }], "isError": false }`.
   The `result_text` is the tool's `ToolOutput` serialized as a JSON string or plain text.
3. On **tool execution error** (the ferrochain `Tool::invoke` returns `Err`): the server
   responds with:
   `{ "content": [{ "type": "text", "text": "<error_message>" }], "isError": true }`.
   The `isError: true` flag is the MCP protocol signal for tool-level failures. The response
   is a valid MCP response (not a JSON-RPC protocol error); the JSON-RPC result layer
   carries `isError: true` in the content.
4. On **tool not found** (`<tool_name>` is not in the registry): the server responds with
   a JSON-RPC error: `{ "code": -32602, "message": "Tool not found: <tool_name>" }`.
   (JSON-RPC -32602 = InvalidParams — the tool name is an invalid parameter for this server.)
5. On **argument schema validation failure** (arguments do not conform to the tool's input
   schema): the server responds with:
   `{ "code": -32602, "message": "Invalid arguments for tool '<tool_name>': <schema_error>" }`.
6. The invocation is executed under the server's `ExecutionContext`, which includes the
   `RunnableConfig` and any configured `BudgetPolicy` attached to the server instance.
   If the tool invocation exceeds its budget, the standard `E-BUDGET-001` applies and the
   server responds with `isError: true`.

## Invariants

- **Synchronous execution in v1:** the server executes `Tool::invoke` synchronously and
  awaits the result before responding to the MCP client. Streaming intermediate results from
  long-running tools is deferred to v2.
- **isError semantics:** `isError: true` in the `CallToolResult` means the tool returned
  an error, but the MCP protocol transaction itself succeeded. The JSON-RPC layer returns
  `result` (not `error`) in both the success and tool-error cases. JSON-RPC `error` is only
  used for protocol-level failures (unknown method, invalid params, parse error).
- **No credential leakage:** if a tool returns an error that includes sensitive information
  (e.g., a provider credential), the server is responsible for sanitizing the error message
  before including it in the MCP response. (DI-010.) In v1 this is best-effort; implementors
  must not construct error messages that embed credential values from known sources.
- **One invocation per request:** a single `tools/call` request invokes exactly one tool
  exactly once. No fan-out, no retry within the server handler.

## Edge Cases

### EC-001: Tool not found
**Scenario:** Client sends `tools/call` with `name: "nonexistent_tool"`.
**Expected behavior:** JSON-RPC error response `{ "code": -32602, "message": "Tool not
found: nonexistent_tool" }`. No tool execution attempted.

### EC-002: Tool returns an error (Err result)
**Scenario:** The ferrochain `Tool::invoke` returns `Err(FerrochainError { … })` (e.g., the
tool made a failing HTTP request).
**Expected behavior:** MCP response: `{ "content": [{ "type": "text", "text":
"<FerrochainError message>" }], "isError": true }`. JSON-RPC result is a success (the MCP
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
semantics as BC-2.09.006 PC-3 for `tools/list`).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `tools/call { name: "echo", arguments: { "text": "hello" } }`; `echo` tool registered and returns "hello" | `{ "content": [{ "type": "text", "text": "hello" }], "isError": false }` | Happy-path invocation |
| TV-002 | `tools/call { name: "fail_tool" }`; tool returns `Err(…)` | `{ "content": [{ "type": "text", "text": "<error message>" }], "isError": true }` | Tool execution error |
| TV-003 | `tools/call { name: "unknown_tool" }` | JSON-RPC error `{ "code": -32602, "message": "Tool not found: unknown_tool" }` | Tool not found |
| TV-004 | `tools/call { name: "get_weather", arguments: { "city": "Paris" } }` (wrong schema) | JSON-RPC error `{ "code": -32602, "message": "Invalid arguments…" }` | Schema validation |
| TV-005 | Two simultaneous `tools/call` requests for different tools | Both return correct results independently | Concurrent invocations |
| TV-006 | Tool registered after server start; client invokes it | `isError: false` response with tool result | Dynamic registry |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-MCPCALL-01 | External MCP client can successfully invoke a registered ferrochain tool via tools/call and receive the correct result | Integration test: start server; connect MCP client library; invoke tool; assert result content | Wave 2 |
| VP-MCPCALL-02 | Tool execution error surfaces as `isError: true` in MCP response (not as a JSON-RPC protocol error) | Unit test: mock tool returning Err; assert response has isError: true and result-layer success | Wave 2 |

## Related BCs

- BC-2.09.006 — depends on: tool advertisement (tools/list) is the discovery path; this BC is the execution path that follows discovery
- BC-2.09.004 — related to: MCP client ToolException (E-MCP-001) is the client-side equivalent of the tool-error signal; MCP server uses isError: true for the same semantics in server-direction
- BC-2.10.001 — related to: budget governance applies to tool invocations dispatched through the MCP server

## Architecture Anchors

- `ferrochain-mcp/src/server.rs` (`mcp::server`) — `tools/call` request handler: parse arguments, look up tool in `ToolRegistry`, call `Tool::invoke`, serialize `ToolOutput` to `CallToolResult`, format JSON-RPC responses for success / tool-error / protocol-error cases
- `ferrochain-mcp/src/registry.rs` — `ToolRegistry::get(name: &str) -> Option<Arc<dyn Tool>>` used by the invocation handler

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-MCPCALL-01, VP-MCPCALL-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-021 |
| Capability Anchor Justification | CAP-021 ("MCP Server Role (Expose Registered Tools as MCP Server Endpoint)") per capabilities-p1-p2.md §CAP-021 — this BC specifies the `tools/call` invocation path: routing an external MCP client's tool-call request to the registered ferrochain Tool and returning the result, which is the core "invoke ferrochain tools via MCP protocol" behavior CAP-021 defines |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — parse failures and tool-not-found return JSON-RPC error responses, not panics), DI-010 (Credential Opacity — error messages must not embed credential values), DI-014 (Error Propagation — tool execution errors surface as isError: true; protocol errors surface as JSON-RPC error; no silent swallowing) |
| Domain D Forcing Function | domain-d-hermes-agent.md req 11 — "ferrochain exposes its own tools and resources via the MCP protocol so that other LLM applications can connect as clients"; `tools/call` is the execution surface that makes this useful |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration) |
| Module | ferrochain-mcp (`mcp::server`) |
