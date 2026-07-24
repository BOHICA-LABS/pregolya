---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.001
version: "1.3"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-66): F-P66-01 — EC-006 and TV-008 added: JSON-RPC -32601 MethodNotFound when server does not implement tools/list → Err(E-MCP-003 McpNotImplemented). Re-anchor for E-MCP-003 from BC-2.09.005 (lifecycle scope) to this BC (discovery path — first MCP method invoked). (OBS-P28-2 class; gate #33 reverse-verification finding.)"
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-mcp per module-decomposition.md v1.10."
  - "1.3 (CENSUS-P109, 2026-07-18): Expand TV-004 E-MCP-002 McpTransportError struct from `{ server: \"math\", ... }` to `{ server: \"math\", transport_error: \"connection refused\" }` — `...` abbreviation failed PASS-ABBREV rule (no defining full-struct PC/EC site in BC; TV-004 was the sole struct site). TD-VSDD-060 sweep: no other E-MCP-002 struct sites in file."
origin: greenfield
priority: P1
subsystem: SS-09
capability: CAP-010
wave: 2
phase: 1a
red_gate: false
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-010
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/mcp/behavioral-intent.md
  - .factory/semport/mcp/test-inventory.md
  - .factory/semport/mcp/rust-translation-strategy.md
input-hash: "616f330"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.09.001: MCP Server Tool Discovery and Registration at Runtime

## Description

`MultiServerMcpClient` discovers the tool manifest from one or more MCP servers at
runtime by calling `list_tools()` on each server's session, following pagination cursors
until all tools are retrieved. Each discovered MCP `Tool` is converted into a
`Arc<dyn ferrochain_core::Tool>` whose `args_schema` carries the raw JSON-Schema
`Value` from `tool.inputSchema` verbatim — no schema synthesis. If multiple servers
are queried simultaneously (no `server_name` filter), the fan-out runs concurrently
via a `JoinSet` over per-server tasks, mirroring `asyncio.gather` semantics.

## Preconditions

1. A `MultiServerMcpClient` is constructed with at least one `Connection` entry
   (Stdio, SSE, StreamableHttp, or WebSocket).
2. The named MCP servers are reachable at their configured transports.
3. `get_tools(server_name: Option<&str>)` is called.

## Postconditions

1. For each targeted server, `list_tools()` is called with cursor following
   (`MAX_ITERATIONS=1000` pagination bound per upstream); all pages are consumed.
2. Each `rmcp::model::Tool` from the server is converted into
   `Arc<dyn ferrochain_core::Tool>` via `convert_mcp_tool`.
3. The tool's `args_schema` field is the raw `serde_json::Value` from
   `tool.inputSchema` — no pydantic/schemars model is synthesized.
4. When `server_name = Some("srv")`, only that server's tools are returned;
   tools from other servers are not included.
5. When `server_name = None`, tools from all registered servers are returned;
   the fan-out runs concurrently via `JoinSet` / `try_join_all`.
6. When `tool_name_prefix = true`, each tool name is prefixed `"{server_name}_{tool_name}"`.
   When `false`, tool names are used verbatim (name conflicts are caller's responsibility).
7. Transport failure connecting to any targeted server returns
   `Err(FerrochainError { component: MCP, category: TRANSPORT, code: E-MCP-002 })`.
8. A server that returns an empty tool list (`[]`) is not an error; an empty `Vec`
   is returned for that server.

## Invariants

- `args_schema` on any converted tool is the verbatim JSON-Schema `Value` from the
  MCP server; it is never synthesized, transformed, or validated by ferrochain-mcp.
- The session used for `list_tools` is created on-demand (RAII `OnDemand` session
  source) and torn down after the listing completes; no session is retained.
- `MAX_ITERATIONS=1000` is the hard pagination bound; if a server returns more than
  1,000 pages, the final page's cursor is dropped and the tool list is returned as-is.

## Edge Cases

### EC-001: Server returns empty tool list
**Scenario:** A reachable MCP server responds to `list_tools` with `tools: []`.
**Expected behavior:** An empty `Vec` is returned for that server; no error is raised.
This is valid — the server may expose only resources, not tools.

### EC-002: Pagination across multiple cursor pages
**Scenario:** Server has 250 tools, paginated across 3 cursor pages.
**Expected behavior:** All 3 pages are fetched; all 250 tools are returned. The
`nextCursor` is followed until absent. Total tool count = 250.

### EC-003: Tool name conflict across servers with prefix disabled
**Scenario:** Two servers both expose a tool named `"search"`, and `tool_name_prefix = false`.
**Expected behavior:** Both tools are returned; the later server's `"search"` entry
appears after the earlier one. There is no deduplication. Callers using routing by
name may get the wrong tool — this is the caller's risk when prefix is disabled.

### EC-004: Fan-out with one failing server
**Scenario:** `server_name = None` with 3 servers; one server's TCP connection is
refused.
**Expected behavior:** The `JoinSet` propagates the first error; the call returns
`Err(E-MCP-002 McpTransportError)`. No partial tool list is returned.

### EC-005: Transport alias normalisation
**Scenario:** `Connection` uses transport `"streamable-http"` or `"http"` alias
(not the canonical `"streamable_http"` serde tag).
**Expected behavior:** The alias resolves to `StreamableHttpConnection`; the tool
discovery proceeds normally with the 30 s timeout default.

### EC-006: Server returns JSON-RPC -32601 MethodNotFound for tools/list (E-MCP-003)
**Scenario:** A reachable MCP server responds to the `tools/list` JSON-RPC call with
error code `-32601 MethodNotFound` — the server does not implement the `tools/list`
method (e.g., a legacy MCP server exposing only resources, or a JSON-RPC endpoint that
is not an MCP tools server at all).
**Expected behavior:** Returns `Err(FerrochainError { component: MCP, category: VAL,
code: E-MCP-003, message: "McpNotImplemented: MCP server '<server>' does not implement
'tools/list'" })`. The server contributes no tools to the registry. Treated as a fatal
failure for that server — same propagation pattern as EC-004 transport failure
(`JoinSet` aborts on first error in multi-server fan-out). The caller must reconfigure
or remove the non-implementing server.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | 1 server with 3 tools, `server_name = None`, `tool_name_prefix = false` | `Ok(vec![tool_a, tool_b, tool_c])` | Happy-path single server |
| TV-002 | 2 servers (3 + 2 tools), `server_name = None` | `Ok(vec![5 tools])`, concurrent fan-out | Multi-server fan-out |
| TV-003 | `server_name = Some("math")`, other server irrelevant | `Ok(vec![math tools only])` | Server filter |
| TV-004 | Server unreachable (connection refused) | `Err(E-MCP-002 McpTransportError { server: "math", transport_error: "connection refused" })` | Transport error |
| TV-005 | `tool_name_prefix = true`, server "fs", tool "read_file" | tool name = `"fs_read_file"` | Prefix application |
| TV-006 | Server with 250 tools across 3 pages | `Ok(vec![250 tools])` | Cursor pagination |
| TV-007 | Server returns empty `tools: []` | `Ok(vec![])` | Empty server |
| TV-008 | 1 server; `list_tools` call returns JSON-RPC -32601 MethodNotFound | `Err(E-MCP-003 McpNotImplemented { server: "math", method: "tools/list" })` | EC-006: server does not implement MCP tools protocol |

## Verification Properties

_No Kani VP seed required for this BC. Unit tests and integration tests are sufficient._

## Related BCs

- BC-2.09.002 — depends on: tool handles produced here are routed for invocation in BC-2.09.002
- BC-2.09.003 — depends on: tool-result content from discovered tools is subject to DI-012 guardrail
- BC-2.09.004 — sibling: error handling policy for ToolException errors during invocation

## Architecture Anchors

- `ferrochain-mcp/src/client.rs` — `MultiServerMcpClient::get_tools`
- `ferrochain-mcp/src/tools.rs` — `convert_mcp_tool`, `_list_all_tools`
- `ferrochain-mcp/src/sessions.rs` — `create_session`, `Connection` enum

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

_[to be filled after verification-architecture phase]_

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-010 |
| Capability Anchor Justification | CAP-010 ("MCP Tool Adapter") per capabilities-p1-p2.md §CAP-010 — this BC specifies the runtime discovery and registration of MCP tools, which is the first behavioral surface of the adapter: "Discover tools from MCP servers at runtime, present them to a graph as standard ferrochain Tools" |
| L2 Domain Invariants | — |
| DEC Reference | — |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration, using in-process rmcp test servers) |
| Module | ferrochain-mcp |
