---
document_type: story
level: ops
story_id: S-2.11
epic_id: E-21
version: "1.2"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.006.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.007.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "14c8781"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-2.10]
blocks: []
behavioral_contracts: [BC-2.09.006, BC-2.09.007]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-mcp
subsystems: [SS-09]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: both BCs active; BC-2.09.006 mints E-MCP-005; no BC-TBD placeholders; status = draft per Spec-First Gate S-7.01
changelog:
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors."
  - "1.2 (2026-08-24): P2A-043 F-04: old-form ordinal cross-refs converted to stable tags"
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

### AC-013 (traces to BC-2.09.007 INV-003)
Error messages returned in `isError: true` responses do not embed credential values.
The server does not construct error messages by formatting `PregolyaError` fields that
contain known credential types (`OpenAiApiKey`, `AnthropicApiKey`). Verified by
`test_BC_2_09_007_error_messages_no_credential_leakage()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `McpServer` | `pregolya-mcp/src/server.rs` | effectful (binds transport, accepts connections) |
| `McpServerConfig` | `pregolya-mcp/src/server.rs` | pure-core (config struct) |
| `McpServerHandle` | `pregolya-mcp/src/server.rs` | effectful (shutdown triggers I/O) |
| `ToolRegistry` | `pregolya-mcp/src/registry.rs` | pure-core (Arc-wrapped HashMap; thread-safe reads) |
| `tools/list` handler | `pregolya-mcp/src/server.rs` | pure-core (reads registry, serializes; no I/O beyond response) |
| `tools/call` handler | `pregolya-mcp/src/server.rs` | effectful (invokes registered `DynTool`) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `McpServerConfig` | pure-core | Configuration data only; no I/O |
| `ToolRegistry` | pure-core | Thread-safe in-memory map behind `Arc<RwLock<...>>`; read-only in list handler |
| `tools/list` handler | pure-core | Reads registry (in-memory), serializes to JSON; no outbound I/O |
| `McpServer::start` | effectful | Binds TCP/stdio; effectful from the first syscall |
| `tools/call` handler | effectful | Invokes `DynTool::invoke` which may perform I/O |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | SSE bind address already in use | `Err(E-MCP-005 McpServerBindFailed)` — BC-2.09.006 EC-001 |
| EC-002 | Tool registered after server start; `tools/list` called | New tool included — registry read on each request |
| EC-003 | `tools/call` with tool registered after server start | Invocation succeeds — same dynamic read semantics |
| EC-004 | `McpServerHandle::shutdown()` during active `tools/call` in-flight | In-flight call completes; response is sent; no new requests accepted |
| EC-005 | Tool invocation exceeds `BudgetPolicy` limit | `isError: true` with message "run halted: budget ceiling reached" — BC-2.09.007 EC-004 |
| EC-006 | Two concurrent `tools/call` for different tools | Both complete independently; no cross-call state |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~2,800 |
| BC files (2 BCs) | ~5,000 |
| `module-decomposition.md` SS-09 section | ~400 |
| `pregolya-mcp/src/server.rs` (new) | ~1,200 |
| `pregolya-mcp/src/registry.rs` (new) | ~500 |
| Test files (~80 lines) | ~1,200 |
| Tool outputs | ~400 |
| **Total** | **~11,500** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~6%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-013 (test-writer step)
2. [ ] No Red Gate BCs in this story — proceed to implementation after test stubs
3. [ ] Register `E-MCP-005 McpServerBindFailed` in error taxonomy (TRANSPORT, broken, Never)
4. [ ] Create `pregolya-mcp/src/registry.rs` — `ToolRegistry` with `Arc<RwLock<HashMap<String, Arc<dyn DynTool>>>>`
5. [ ] Create `pregolya-mcp/src/server.rs` — `McpServer`, `McpServerConfig`, `McpServerHandle`, `McpServerTransport` enum
6. [ ] Implement `McpServer::start` — bind stdio or SSE; return `Err(E-MCP-005)` on failure
7. [ ] Implement `tools/list` handler — read registry on each request; serialize to MCP ToolDefinition
8. [ ] Implement `tools/call` handler — look up tool in registry; invoke; format CallToolResult
9. [ ] Implement JSON-RPC error responses for tool-not-found (-32602) and invalid-params (-32602)
10. [ ] Implement `McpServerHandle::shutdown()` — graceful connection teardown
11. [ ] Verify `DynTool` object safety in server context (same seam as S-2.10)
12. [ ] Run `cargo nextest run -p pregolya-mcp` — all 13 ACs green (combined with S-2.10 ACs)

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
| `isError: true` is in the JSON-RPC `result` layer — not `error` | BC-2.09.007 INV-002 | Test AC-012 |
| `E-MCP-005` category: TRANSPORT, severity: broken, retry_hint: Never | BC-2.09.006 §Error code minted | Error taxonomy registration |
| Error messages do not embed credential values | BC-2.09.007 INV-003 | Test AC-013 |
| No `unwrap()`/`expect()` in server handlers | CLAUDE.md Code Conventions | Clippy |
| Registry read on each `tools/list` request (no startup snapshot) | BC-2.09.006 PC-003 | Test AC-004 |

**Forbidden dependencies:** `pregolya-mcp` (both `mcp::client` from S-2.10 and `mcp::server`
from this story) must NOT depend on `pregolya-graph`, `pregolya-server`, `pregolya-vectorstores`,
or `pregolya-standard-tests`. The `mcp::client` and `mcp::server` modules do NOT share mutable
state per BC-2.09.006 INV-005. If `pregolya-mcp` gains a dependency on `pregolya-graph`
or `pregolya-server`, the build MUST fail.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `rmcp` | workspace pin | MCP protocol SDK — `tools/list` and `tools/call` server-side handlers |
| `tokio` | workspace pin | Async server task; `RwLock` for registry |
| `serde_json` | workspace pin | `ToolDefinition` serialization; `CallToolResult` formatting |
| `tracing` | workspace pin | Structured logging for server lifecycle events (SAP-1) |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-mcp/src/server.rs` | CREATE | `McpServer`, `McpServerConfig`, `McpServerHandle`, `McpServerTransport` |
| `pregolya-mcp/src/registry.rs` | CREATE or MODIFY | `ToolRegistry` — shared with client side (extract if needed) |
| `pregolya-mcp/src/lib.rs` | MODIFY | Re-export `McpServer`, `McpServerConfig`, `McpServerHandle` |
