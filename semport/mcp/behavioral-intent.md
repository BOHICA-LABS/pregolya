---
artifact: semport/mcp/behavioral-intent
project: pregolya
port_target: langchain-mcp-adapters (0.3.0) → pregolya-mcp
analyzer_pass: 5
date: 2026-07-12
disposition_note: elevated to first-class by D1 amendment (was a thin adapter, now a pregolya-mcp crate)
note: analysis only — NO Rust code committed; signatures are illustrative sketches
---

# langchain-mcp-adapters — Behavioral Intent

## What this package is for

Bridge the **Model Context Protocol (MCP)** — Anthropic's open protocol for
exposing tools/prompts/resources from external servers — into the LangChain
tool/message abstractions, so a LangChain/LangGraph agent can call MCP-server
tools as if they were native LangChain tools. It is a thin *adapter* over the
Python `mcp` SDK: the SDK owns transports, sessions, and wire types; this
package owns the **translation layer** (MCP types ⇄ LangChain types) and a
**multi-server convenience client**.

For pregolya (`pregolya-mcp`, first-class per D1 amendment), the port
target is the same adapter behavior, but sitting on top of the **official Rust
MCP SDK `rmcp`** instead of the Python `mcp` SDK (see dependency-disposition).

## The five behavioral surfaces

### 1. Tool conversion (`tools.py`, 685 LOC — the core)

`convert_mcp_tool_to_langchain_tool(session, tool, ...)` wraps an MCP `Tool`
into a LangChain `StructuredTool` whose `coroutine` calls the MCP tool over a
session and converts the result. Key contracts:

- **Schema translation:** `args_schema = tool.inputSchema` (a raw JSON-Schema
  dict) is passed straight through to `StructuredTool` — LangChain accepts a
  dict schema. No pydantic model is synthesized for MCP→LC.
- **Result content handling** (`_convert_mcp_content_to_lc_block`): maps each
  MCP content block to a LangChain content block:
  - `TextContent` → text block
  - `ImageContent` → image block (base64 + mime)
  - `ResourceLink` (mime `image/*`) → image block (url); else file block (url)
  - `EmbeddedResource` text → text block; blob (image/*) → image; blob other →
    file block (base64)
  - `AudioContent` → **raises `NotImplementedError`** (not yet supported)
  - unknown → `ValueError`
- **Artifacts:** `CallToolResult.structuredContent` → `MCPToolArtifact`
  TypedDict `{structured_content}`; returned via `response_format="content_and_artifact"`.
- **Error handling policy** (`handle_tool_errors`, default True): an MCP
  `CallToolResult(isError=True)` → `_MCPToolExecutionError` (a `ToolException`
  subclass carrying the converted blocks) → routed through `handle_tool_error`
  callback → surfaced to the model as a `ToolMessage(status="error")` so the
  agent self-corrects. If `False`, the exception propagates (legacy). **Only
  `isError=True` is governed by the flag**; transport/session failures and
  content-conversion errors (`NotImplementedError`/`ValueError`) ALWAYS
  propagate (they are not `ToolException` subclasses).
- **Pagination:** `_list_all_tools` loops `session.list_tools(cursor=...)`
  following `nextCursor` (spec 2025-06-18), bounded at `MAX_ITERATIONS=1000`.
- **Session-on-demand:** if no live `session`, a new one is created per tool
  call from the `connection` config (`create_session`), initialized, called,
  torn down. A workaround captures exceptions inside the async-CM and re-raises
  outside it (the MCP SDK may suppress exceptions on client disconnect).
- **Interceptor chain:** `_build_interceptor_chain` composes
  `ToolCallInterceptor`s in an onion (first = outermost) around the base tool
  call — enables retry/caching/rate-limit/header-mutation.
- **Header mutation:** an interceptor may set `request.headers`; for
  sse/http/streamable transports the connection is cloned with merged headers.
- **Name prefixing:** `tool_name_prefix` → `"{server}_{tool}"`.
- **Metadata:** MCP `tool.annotations` (+ `_meta`) → LC tool `metadata`.
- **Reverse direction:** `to_fastmcp(lc_tool)` converts a LangChain tool INTO a
  FastMCP server tool (requires pydantic BaseModel args_schema; rejects injected
  args). Server-side; likely out-of-scope for pregolya wave 1.

### 2. Multi-server client (`client.py`, 302 LOC)

`MultiServerMCPClient(connections: dict[name, Connection])`:
- `get_tools(server_name=None)` — loads tools from one or ALL servers; all-server
  path fans out with `asyncio.gather` over per-server `load_mcp_tools` tasks.
- `session(server_name)` — async-CM yielding an initialized `ClientSession`.
- `get_prompt(server, name, arguments)` / `get_resources(server=None, uris=...)`.
- **Connection lifecycle model:** by default a **new session is created per tool
  call** (stateless; the returned tools carry the `connection` config, not a live
  session). This is the crucial ownership fact for the Rust port.
- **NOT a context manager:** `__aenter__`/`__aexit__` raise `NotImplementedError`
  (removed in 0.1.0) — deliberate anti-pattern block.

### 3. Sessions / transports (`sessions.py`, 477 LOC)

`Connection` = tagged union (TypedDict on `transport`) of:
- **`StdioConnection`** — command/args/env/cwd/encoding; env values expand
  `${VAR}` (braced only; bare `$VAR` left literal to protect passwords);
  unexpanded refs → `logger.warning`.
- **`SSEConnection`** — url/headers/timeout(5s)/sse_read_timeout(300s)/auth.
- **`StreamableHttpConnection`** — url/headers/timeout(30s)/sse_read_timeout(300s)/
  terminate_on_close/auth; accepts `float | timedelta`.
- **`WebsocketConnection`** — url only; requires `mcp[ws]` extra.
`create_session(connection)` dispatches on `transport` (aliases:
`streamable_http`/`streamable-http`/`http` all map to streamable HTTP), validates
required params, injects logging/elicitation callbacks into `session_kwargs`.

### 4. Prompts (`prompts.py`, 59 LOC)

`load_mcp_prompt(session, name, arguments)` → `session.get_prompt` → each
`PromptMessage` converted: text content + role `user`→`HumanMessage`,
`assistant`→`AIMessage`; other roles / non-text content → `ValueError`.

### 5. Resources (`resources.py`, 103 LOC)

`load_mcp_resources(session, uris=None)` → `TextResourceContents`→Blob(text),
`BlobResourceContents`→Blob(base64-decoded bytes), else `TypeError`. `uris=None`
lists all resources (dynamic/param resources are skipped by the SDK). Wraps a
`Blob.from_data(mime_type, metadata={"uri"})`. Errors → `RuntimeError` with the
failing URI.

### Supporting: callbacks (`callbacks.py`, 141) & interceptors (`interceptors.py`, 141)

- **Callbacks**: `Callbacks{on_logging_message, on_progress, on_elicitation}` —
  LangChain-flavored wrappers that inject a `CallbackContext{server_name,
  tool_name}` as the trailing arg, then `to_mcp_format()` adapts to the raw MCP
  SDK callback signatures.
- **Interceptors**: `ToolCallInterceptor` Protocol
  `(request, handler) -> result`; `MCPToolCallRequest` is a dataclass with
  modifiable `{name, args, headers}` and read-only context `{server_name,
  runtime}`, plus an immutable `.override(**)` (dataclasses.replace). Onion
  composition. Result union includes LangGraph `Command` when langgraph present.

## Ubiquitous language

| Term | Meaning |
|---|---|
| Connection | Transport-tagged config to reach one MCP server |
| Session (`ClientSession`) | A live, initialized connection to one server; owns request/response |
| CallToolResult | MCP wire result: `content[]`, `isError`, `structuredContent` |
| content block | MCP: Text/Image/Audio/ResourceLink/EmbeddedResource; LC: text/image/file dict |
| artifact | `structuredContent` surfaced alongside human-readable content |
| interceptor | Middleware wrapping a tool call (onion order) |
| elicitation | Server-initiated request for structured user input mid-call |

## Scale

Production **1,914 LOC** across 8 modules (tools 685, sessions 477, client 302,
interceptors 141, callbacks 141, resources 103, prompts 59). Tests **3,056 LOC**
(test_tools 1,469). Runtime deps: `langchain-core`, `mcp>=1.9.2`,
`typing-extensions`; optional `langgraph` (enables `Command` results).

## State Checkpoint
```yaml
pass: 5
artifact: behavioral-intent
package: langchain-mcp-adapters
crate: pregolya-mcp
status: complete
timestamp: 2026-07-12
```
