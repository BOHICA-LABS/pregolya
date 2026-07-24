---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.002
version: "1.3"
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
timestamp: 2026-07-22T00:00:00Z
changelog:
  - "1.3 (burst-240/F-P140-03/F-P140-04/2026-07-22): Two defect fixes. (1) F-P140-03: PC5/EC-004/TV-004 restated public error type as FerrochainError — previously surfaced raw McpError::Transport as the public type, contradicting error-taxonomy.md ('All errors are FerrochainError{...}'), BC-2.09.001 PC7 (transport failure → FerrochainError E-MCP-002), and BC-2.09.004 PC1 (McpError in .source only). Transport failures now return FerrochainError{component:MCP, category:TRANSPORT, code:E-MCP-002} with McpError::Transport preserved in .source(). EC-004 is the authoritative full-form site; TV-004 PASS-ABBREV via EC-004. (2) F-P140-04: PC6/TV-005 restated public error type — previously surfaced raw McpError::ContentConversion('audio content not supported'), with no E-MCP code and no FerrochainError wrapper. Minted E-MCP-006 McpContentUnsupported (VAL, broken) in error-taxonomy.md v1.34 same burst. Content-conversion errors now return FerrochainError{component:MCP, category:VAL, code:E-MCP-006} with McpError::ContentConversion in .source(). PC6 is the authoritative full-form site; TV-005 PASS-ABBREV via PC6. Gate #33 forward (E-MCP-006): both placeholders covered — <tool> = ToolInvocation.tool_name, <content_type> = content block variant name; both available at the raise site."
  - "1.2 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. PC8 had bare `Err(FerrochainError { code: E-MCP-004 ToolNotFound })` without message; E-MCP-004 has <tool_name> placeholder. Added inline message template; <tool_name> is available from the ToolInvocation at the raise site."
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-mcp per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-010
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/mcp/behavioral-intent.md
  - .factory/semport/mcp/test-inventory.md
  - .factory/semport/mcp/rust-translation-strategy.md
input-hash: "73a9187"
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
5. Transport failures (e.g., TCP reset, connection refused) ALWAYS return
   `Err(FerrochainError { component: MCP, category: TRANSPORT, code: E-MCP-002,
   message: "McpTransportError: cannot connect to MCP server '<server>': <transport_error>" })`
   regardless of flag (where `<server>` = server name from the tool's `SessionSource`;
   `<transport_error>` = transport failure description, e.g., "connection reset by peer").
   The underlying `McpError::Transport` is preserved in `.source()`. See EC-004 for the
   authoritative full-form struct.
6. Content-conversion errors (unsupported content block types returned by the MCP tool,
   e.g., `AudioContent`) ALWAYS return
   `Err(FerrochainError { component: MCP, category: VAL, code: E-MCP-006,
   message: "McpContentUnsupported: MCP tool '<tool>' returned unsupported content type '<content_type>'" })`
   regardless of flag (where `<tool>` = tool name from `ToolInvocation.tool_name`;
   `<content_type>` = content block variant name, e.g., `"AudioContent"`; both available at
   the raise site). The underlying `McpError::ContentConversion` is preserved in `.source()`.
   This is the authoritative full-form site for E-MCP-006 gate #33; TV-005 PASS-ABBREV via this PC6.
7. `structuredContent` from `CallToolResult` is surfaced as `MCPToolArtifact { structured_content }`
   alongside the content blocks (content+artifact response format).
8. Tool not found in routing table: `Err(FerrochainError { code: E-MCP-004 ToolNotFound, message: "ToolNotFound: tool '<tool_name>' is not registered with any MCP server" })`
   (where `<tool_name>` is available from the `ToolInvocation.tool_name` field at the raise site).

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
**Expected behavior:** `Err(FerrochainError { component: MCP, category: TRANSPORT,
code: E-MCP-002, message: "McpTransportError: cannot connect to MCP server '<server>':
<transport_error>" })` (where `<server>` = server name from the tool's `SessionSource`;
`<transport_error>` = e.g., "connection reset by peer") — the flag does not suppress
transport errors even in legacy mode. McpError::Transport is preserved in `.source()`.
TV-004 PASS-ABBREV via this EC-004 full-form site.

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
| TV-004 | TCP reset mid-call | `Err(FerrochainError { component: MCP, category: TRANSPORT, code: E-MCP-002 })` regardless of handle_tool_errors flag. PASS-ABBREV via EC-004. | Transport always propagates (E-MCP-002) |
| TV-005 | AudioContent in result | `Err(FerrochainError { component: MCP, category: VAL, code: E-MCP-006 })` regardless of flag. PASS-ABBREV via PC6. | Conversion always propagates (E-MCP-006) |
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
| Module | ferrochain-mcp |
