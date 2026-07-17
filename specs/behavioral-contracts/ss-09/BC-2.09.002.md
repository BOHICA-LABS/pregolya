---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.002
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
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
input-hash: "9d6479b"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.09.002: ToolInvocation Routing to Correct MCP Server Transport

## Description

When a `ToolInvocation` is submitted for an MCP-backed tool, the ferrochain-mcp adapter
routes it to the MCP server identified in the tool's `SessionSource`, applies the
interceptor chain, calls `rmcp::call_tool`, and converts the `CallToolResult` into a
ferrochain `ToolMessage`. The `handle_tool_errors` flag governs whether `isError=true`
results are converted to a `ToolMessage{status: Error}` (default, enabling agent
self-correction) or propagated as `Err(McpError::ToolExecution)` (legacy opt-out).
Transport failures and content-conversion errors always propagate regardless of the flag.

## Preconditions

1. A `Arc<dyn ferrochain_core::Tool>` was produced by `convert_mcp_tool`
   (see BC-2.09.001), carrying a `SessionSource` referencing the target MCP server.
2. A `ToolInvocation` with a valid args payload conforming to `tool.inputSchema` is submitted.
3. The interceptor chain (possibly empty) is configured on the tool.

## Postconditions

1. The interceptor chain is applied in onion order (first registered = outermost wrapper)
   around the base `rmcp::call_tool` invocation. Each interceptor receives a
   `McpToolCallRequest { name, args, headers (mutable); server_name, runtime (context) }`.
2. For `SessionSource::OnDemand(connection)`: a new rmcp client session is created
   (stdio spawn / http connect), `initialize()` called, the tool call performed, and
   the session dropped at scope end (RAII). No session is retained across calls.
3. For `SessionSource::Live(arc)`: the shared Arc'd session is used for the call.
4. The `CallToolResult` is converted:
   - `isError = false`: content blocks converted via the 6-way mapping (BC-2.09.003
     anchors untrusted-ingress guardrail); returns `Ok(ToolMessage{status: Success, content})`.
   - `isError = true`, `handle_tool_errors = true` (default): content blocks converted;
     returns `Ok(ToolMessage{status: Error, content})`. Empty content uses a single
     minimal text fallback block.
   - `isError = true`, `handle_tool_errors = false`: returns
     `Err(McpError::ToolExecution { blocks })`. (Legacy opt-out — agent sees the error.)
5. Transport failures (`McpError::Transport`) ALWAYS return `Err(...)` regardless of flag.
6. Content-conversion errors (`McpError::ContentConversion`, e.g., AudioContent) ALWAYS
   return `Err(...)` regardless of flag.
7. `structuredContent` from `CallToolResult` is surfaced as `MCPToolArtifact { structured_content }`
   alongside the content blocks (content+artifact response format).
8. Tool not found in routing table: `Err(FerrochainError { code: E-MCP-004 ToolNotFound })`.

## Invariants

- The `handle_tool_errors` flag applies ONLY to `McpError::ToolExecution` (the `isError=true`
  path). Transport and content-conversion errors bypass the flag and always propagate.
- The interceptor chain does not modify the `SessionSource`; it may only mutate
  `name`, `args`, and `headers` on `McpToolCallRequest`.
- Header mutations by interceptors for SSE/HTTP transports create a cloned `Connection`
  with merged headers; the shared config is never mutated.
- No connection pooling exists in v1; `OnDemand` sessions are always fresh per call.

## Edge Cases

### EC-001: Empty error content with handle_tool_errors=true
**Scenario:** `isError=true`, `content = []`, `handle_tool_errors = true`.
**Expected behavior:** A single minimal text fallback block is substituted:
`ToolMessage { status: Error, content: ["MCP tool '<name>' returned an error with no content"] }`.
This is the one sanctioned substitution — not a silent empty return (DI-008).

### EC-002: Interceptor short-circuits (cache hit)
**Scenario:** An interceptor returns a cached result without calling the next handler.
**Expected behavior:** The cached `McpToolCallResult` is returned directly; no MCP server
call is made. The caller cannot distinguish this from a live call.

### EC-003: Interceptor mutates headers for SSE transport
**Scenario:** An interceptor sets `request.headers["Authorization"] = "Bearer token"`.
**Expected behavior:** The SSE `Connection` is cloned with the merged headers; the
original `Connection` in the client's map is unchanged.

### EC-004: handle_tool_errors=false, transport error (not isError)
**Scenario:** `handle_tool_errors = false`; server TCP connection reset mid-call.
**Expected behavior:** `Err(McpError::Transport(...))` propagates — the flag does not
suppress transport errors even in legacy mode.

### EC-005: structuredContent present alongside text content
**Scenario:** `CallToolResult` has `content: [TextContent("summary")]` and
`structuredContent: {"key": "value"}`.
**Expected behavior:** Returned as content+artifact:
`ToolMessage { status: Success, content: ["summary"], artifact: MCPToolArtifact { structured_content: {"key": "value"} } }`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | OnDemand, isError=false, text result | `Ok(ToolMessage{status: Success, content: [text]})` | Happy-path tool call |
| TV-002 | isError=true, handle_tool_errors=true (default) | `Ok(ToolMessage{status: Error, content: [err_text]})` | Error → agent self-correction |
| TV-003 | isError=true, handle_tool_errors=false | `Err(McpError::ToolExecution{...})` | Legacy opt-out |
| TV-004 | TCP reset mid-call | `Err(McpError::Transport(...))` regardless of handle_tool_errors flag | Transport always propagates |
| TV-005 | AudioContent in result | `Err(McpError::ContentConversion("audio content not supported"))` regardless of flag | Conversion always propagates |
| TV-006 | isError=true, content=[], handle_tool_errors=true | `Ok(ToolMessage{status: Error, content: ["MCP tool ... returned an error with no content"]})` | Fallback minimal block |
| TV-007 | structuredContent present | ToolMessage carries `MCPToolArtifact { structured_content }` alongside content | Artifact surfaced |

## Verification Properties

_No Kani VP seed required for this BC. Unit and integration tests are sufficient._

## Related BCs

- BC-2.09.001 — depends on: tools routed here are discovered and registered there
- BC-2.09.003 — composes with: untrusted-ingress guardrail fires on successful tool result content
- BC-2.09.004 — sibling: bare ToolException re-raise path is a distinct error subtype

## Architecture Anchors

- `ferrochain-mcp/src/tools.rs` — `McpTool::run`, `_convert_mcp_content_to_block`, `_handle_mcp_tool_error`
- `ferrochain-mcp/src/interceptors.rs` — `ToolCallInterceptor`, `_build_interceptor_chain`
- `ferrochain-mcp/src/sessions.rs` — `SessionSource::OnDemand` RAII lifecycle

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

_[to be filled after verification-architecture phase]_

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-010 |
| Capability Anchor Justification | CAP-010 ("MCP Tool Adapter") per capabilities-p1-p2.md §CAP-010 — this BC specifies the routing of ToolInvocation requests to the correct MCP server transport, which is exactly what CAP-010 describes: "route ToolInvocation requests to the correct MCP server transport" |
| L2 Domain Invariants | — |
| DEC Reference | — |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration, using in-process rmcp test servers) |
| Module | [architect to assign — ferrochain-mcp] |
