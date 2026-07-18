---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.006
version: "1.1"
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
changelog:
  - "1.1 (pass-72 fix, 2026-07-15): OBS-P72 fix — Architecture Anchors: ADR-012 citation replaced with ADR-013. ADR-012 governs self-improvement primitives (SkillStore, write_guard, context_mutation); it has no MCP content. CAP-021 / BC-2.09.006 (MCP server role) is governed by ADR-013 minted by architect in this burst."
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

# BC-2.09.006: MCP Server Tool Advertisement (tools/list; mcp::server)

## Description

`ferrochain-mcp` provides an MCP server role (`mcp::server` module) that starts a server
endpoint and advertises all tools registered in the ferrochain tool registry to external
MCP clients via the `tools/list` JSON-RPC method. This is the server-direction complement to
the existing MCP client (CAP-010 / SS-09 / BC-2.09.001–005). The server supports at minimum
two transports: stdio (for local subprocess MCP usage) and SSE (for HTTP-based MCP clients).
This BC covers the advertisement path only; invocation is specified in BC-2.09.007.

> **Error code minted here (E-MCP-005).** `E-MCP-005 McpServerBindFailed` is introduced by
> this BC. Category: TRANSPORT. Severity: broken. RetryHint: Never.
> Taxonomy row registration: sub-burst 2.

## Preconditions

1. A ferrochain `ToolRegistry` is initialized and contains at least one registered `Tool`.
2. `McpServerConfig` is provided with `transport: McpServerTransport` (either
   `McpServerTransport::Stdio` or `McpServerTransport::Sse { bind_addr: SocketAddr }`) and
   `tool_registry: Arc<ToolRegistry>`.
3. `McpServer::start(config: McpServerConfig) -> Result<McpServerHandle, FerrochainError>`
   is called to start the server.

## Postconditions

1. `McpServer::start` binds to the configured transport endpoint:
   - Stdio: begins reading JSON-RPC messages from stdin and writing to stdout.
   - SSE: binds to `bind_addr` and begins accepting HTTP SSE connections.
   If binding fails, `Err(FerrochainError { component: MCP, category: TRANSPORT,
   code: "E-MCP-005", message: "McpServerBindFailed: cannot bind to <transport>: <reason>",
   retry_hint: Never })` is returned. (DI-008.)
2. On receiving a `tools/list` JSON-RPC request from any connected MCP client:
   - The server reads the current set of registered tools from `tool_registry`.
   - Each `Tool` is serialized to an MCP `ToolDefinition` object: `{ "name": tool.name(),
     "description": tool.description(), "inputSchema": tool.input_schema() }`.
   - The server responds with `{ "tools": [<definitions>] }` as the JSON-RPC result.
3. The tool list reflects the state of `tool_registry` at the time of the `tools/list`
   request. Tools registered after `McpServer::start` but before a `tools/list` request
   are included in the response. (The registry is read on each request, not snapshotted
   at startup.)
4. `McpServerHandle` provides a `shutdown()` method that gracefully closes all open
   connections and stops the server. After `shutdown()`, new connections are refused.
5. A tool registry with zero registered tools returns `{ "tools": [] }` — an empty tools
   list is not an error.

## Invariants

- **Protocol conformance:** the MCP server conforms to the MCP specification's `tools/list`
  method contract. The JSON-RPC method name is `"tools/list"` exactly. Response includes
  the `"tools"` array at the top level of the `result` object.
- **Read-only advertisement:** the `tools/list` handler does not invoke any tool, modify
  the registry, or produce side effects. It is a pure read of the registry state.
- **Concurrent clients:** the server handles multiple simultaneous MCP clients correctly.
  Each `tools/list` request from any client is answered independently. No cross-client
  state sharing.
- **Transport independence:** the tool advertisement behavior is identical on stdio and SSE
  transports. Transport selection affects only the connection mechanism, not the MCP
  message semantics.
- The MCP server module is `mcp::server` in `ferrochain-mcp` — distinct from the MCP client
  (`mcp::client` / `MultiServerMcpClient`). The two modules do not share state.

## Edge Cases

### EC-001: SSE bind address already in use
**Scenario:** `McpServerTransport::Sse { bind_addr: "0.0.0.0:9000" }` but port 9000 is
already in use by another process.
**Expected behavior:** `Err(E-MCP-005 McpServerBindFailed { transport: "SSE:0.0.0.0:9000",
reason: "address already in use (EADDRINUSE)" })`. No server starts. (DI-008.)

### EC-002: tools/list with empty tool registry
**Scenario:** `ToolRegistry` is initialized with zero tools; client sends `tools/list`.
**Expected behavior:** Server responds with `{ "tools": [] }`. No error. MCP protocol allows
empty tool lists.

### EC-003: Tool registered after server start; client queries tools/list
**Scenario:** Server starts with 2 tools registered; a 3rd tool is registered dynamically;
client sends `tools/list`.
**Expected behavior:** Response includes all 3 tools. The registry is read on each request.

### EC-004: Client sends unrecognized JSON-RPC method (e.g., resources/list)
**Scenario:** Connected MCP client sends a method that is not implemented by ferrochain's
MCP server in v1 (e.g., `resources/list`).
**Expected behavior:** Server responds with a JSON-RPC error: `{ "code": -32601,
"message": "Method not found" }`. This reuses the same JSON-RPC -32601 semantics as
E-MCP-003 (McpNotImplemented) on the client side. No E-MCP-005 raised.

### EC-005: Server shutdown while client connection is open
**Scenario:** `McpServerHandle::shutdown()` is called while an MCP client has an active
SSE connection.
**Expected behavior:** The active connection is gracefully closed (SSE stream terminated).
Pending `tools/list` requests that arrived before shutdown return their responses if
in-flight; no new requests are accepted after shutdown begins.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Start stdio server; MCP client sends `tools/list`; registry has 2 tools | JSON-RPC response `{ "tools": [<def1>, <def2>] }` | Happy-path stdio |
| TV-002 | Start SSE server on port 9001; connect MCP client; send `tools/list` | Same tools array via SSE transport | SSE transport |
| TV-003 | Register 2 tools; start server; register 3rd tool; `tools/list` | Response includes all 3 tools | Dynamic registry read |
| TV-004 | SSE bind with port already in use | `Err(E-MCP-005 McpServerBindFailed)` | Bind failure |
| TV-005 | tools/list on empty registry | `{ "tools": [] }` | Empty registry valid |
| TV-006 | Client sends `resources/list` (unimplemented) | JSON-RPC error `{ "code": -32601 }` | Unimplemented method |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-MCPSRV-01 | MCP client can discover all registered ferrochain tools via tools/list | Integration test: start server; connect real MCP client; assert tool count and names | Wave 2 |
| VP-MCPSRV-02 | tools/list response is valid MCP protocol JSON (tools array, each with name/description/inputSchema) | Schema validation test against MCP spec | Wave 2 |

## Related BCs

- BC-2.09.007 — composes with: tool invocation is the execution-direction complement to this advertisement BC
- BC-2.09.001 — related to: client tools/list discovery (this BC mirrors it from the server side); E-MCP-003 (McpNotImplemented) is the same JSON-RPC -32601 pattern used for server-side unimplemented methods
- BC-2.09.005 — related to: MultiServerMcpClient holds no live connections; the server must handle connect/disconnect cleanly

## Architecture Anchors

- `ferrochain-mcp/src/server.rs` (`mcp::server`) — `McpServer`, `McpServerConfig`, `McpServerHandle`, `McpServerTransport` definitions; `tools/list` handler; transport binding (per ADR-013 §Consequences — MCP server role placement in ferrochain-mcp, mcp::server module; ADR-012 has no MCP content and is not the governing ADR for CAP-021)
- `ferrochain-mcp/src/registry.rs` (or shared with client) — `ToolRegistry` read by `tools/list` handler

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-MCPSRV-01, VP-MCPSRV-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-021 |
| Capability Anchor Justification | CAP-021 ("MCP Server Role (Expose Registered Tools as MCP Server Endpoint)") per capabilities-p1-p2.md §CAP-021 — this BC specifies the `tools/list` advertisement path of the MCP server role: server startup, transport binding, and responding to client discovery requests, which is the foundational "expose registered tools" surface CAP-021 defines |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — McpServer::start returns Err on bind failure; E-MCP-005 not panic), DI-014 (Error Propagation — bind errors propagate as Err; empty tool list is Ok not error) |
| Error Code Minted | E-MCP-005 McpServerBindFailed — TRANSPORT, broken, Never. MCP namespace had 4 live codes (E-MCP-001 through E-MCP-004); E-MCP-005 is next. Taxonomy row: sub-burst 2. |
| Domain D Forcing Function | domain-d-hermes-agent.md req 11 — "[NEW framework-scope] MCP server role — ferrochain exposing its tools and resources via the MCP protocol so that other LLM applications can connect as clients — entirely absent from all BCs and capabilities" |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration) |
| Module | ferrochain-mcp (`mcp::server`) |
