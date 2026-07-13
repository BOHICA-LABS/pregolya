---
artifact: semport/mcp/rust-translation-strategy
project: ferrochain
port_target: langchain-mcp-adapters (0.3.0) → ferrochain-mcp
analyzer_pass: 5
date: 2026-07-12
note: strategy only — NO Rust code committed; signatures are illustrative sketches
substrate: rmcp 2.2.0 (official Rust MCP SDK)
---

# langchain-mcp-adapters → Rust (ferrochain-mcp) Translation Strategy

Difficulty scale: 🟢 easy · 🟡 moderate · 🟠 hard · 🔴 very hard.

`ferrochain-mcp` is an **adapter crate**: it does NOT reimplement the MCP
protocol (rmcp owns that); it adapts rmcp client types ⇄ ferrochain-core
tool/message/Blob types. Async-first, Tokio, per CLAUDE.md.

## 1. Connection model — serde-tagged enum 🟢

```rust
#[serde(tag = "transport", rename_all = "snake_case")]
#[non_exhaustive]
pub enum Connection {
    Stdio(StdioConnection),
    Sse(SseConnection),
    #[serde(alias = "streamable-http", alias = "http")]
    StreamableHttp(StreamableHttpConnection),
    Websocket(WebsocketConnection),   // feature = "websocket", deferred
}
```
- `#[non_exhaustive]` per CLAUDE.md public-API rule; external matches need `_`.
- Defaults: SSE timeout 5s / sse_read 300s; streamable-http timeout 30s /
  sse_read 300s (already matches CLAUDE.md's 30s default).
- `${VAR}` braced-only expansion → a small helper over `std::env::var`; bare
  `$VAR` untouched; `tracing::warn!(event_type="mcp.env.unexpanded", ...)` on
  leftover refs (catalog row required).

## 2. Session creation + lifecycle → Rust ownership 🟠 (the key design problem)

Python's model: **a new `ClientSession` is created per tool call** (default
path in `MultiServerMCPClient`), via async context managers, and torn down when
the tool call returns. Tools carry the `Connection` config, not a live session.

Rust mapping:
```rust
pub enum SessionSource {
    Live(Arc<RunningService<RoleClient, ...>>),  // shared, borrowed across calls
    OnDemand(Connection),                        // create per call, drop after
}
```
- **On-demand (default):** each `call_tool` opens an rmcp client (stdio spawn /
  http connect), `initialize()`, calls, and drops it at scope end (RAII replaces
  Python's `async with`). No cross-call lifetime — clean ownership.
- **Live session:** wrap the rmcp running service in `Arc` so the generated tool
  closures can share it across calls without lifetime entanglement. The tool is
  `'static` (holds `Arc`, not a borrow) — this is the ferrochain answer to
  "client lifetimes across tool calls."
- **No connection pooling in the Python source** — each tool call is a fresh
  session on-demand. Do NOT invent pooling in wave 1 (would be a behavior
  change); if added later, surface as an explicit ADR (perf NFR), not a silent
  default. The `asyncio.gather` fan-out in `get_tools`/`get_resources` → Rust
  `futures::future::try_join_all` / `JoinSet` over per-server tasks.
- **Exception-capture-outside-CM workaround** (tools.py:458-487): a Python-SDK
  quirk. Verify rmcp propagates errors on disconnect; if it does, the workaround
  is unnecessary in Rust (drop it and document why).

## 3. Tool conversion → ferrochain-core `Tool` 🟠

```rust
pub fn convert_mcp_tool(
    source: SessionSource,
    tool: rmcp::model::Tool,
    opts: &ConvertOpts,      // callbacks, interceptors, server_name, prefix, handle_errors
) -> Arc<dyn ferrochain_core::Tool>
```
- **Schema:** MCP `inputSchema` is a JSON-Schema `Value`; pass through to the
  ferrochain tool's `args_schema` as `serde_json::Value` (mirrors Python passing
  the dict — no model synthesis MCP→core). This aligns with core's schema ADR
  (schemars) only on the reverse direction.
- **The generated tool is a closure** capturing `Arc`'d session-source,
  callbacks, interceptor chain, and the MCP tool name. Async `run(args)`:
  build `MCPToolCallRequest` → interceptor chain → rmcp `call_tool` → convert
  result.
- **Result → content_and_artifact:** ferrochain-core needs a tool-output shape
  that carries both content blocks AND an artifact (`structuredContent`). Verify
  ferrochain-core's `ToolMessage`/tool-output type supports the
  content+artifact pair (it must, for parity). Artifact = `MCPToolArtifact {
  structured_content: Map<String,Value> }`.

## 4. Content-block translation — 🟡 (byte-faithful mapping)

Port `_convert_mcp_content_to_lc_block` as a `match` over rmcp content:
```
TextContent            -> ContentBlock::Text
ImageContent           -> ContentBlock::Image { base64, mime_type }
ResourceLink(image/*)  -> Image { url }   ; else File { url }
EmbeddedResource text  -> Text
EmbeddedResource blob(image/*) -> Image{base64}; else File{base64}
AudioContent           -> Err(NotImplemented)   // preserve: audio not supported
unknown                -> Err(Value/Unsupported)
```
- These map onto ferrochain-core's `ContentBlock` enum (from core semport §2).
- **Error taxonomy:** only the MCP `isError=true` path is a "tool execution
  error" (recoverable → ToolMessage status=error when `handle_tool_errors`);
  content-conversion errors (audio, unknown) and transport failures ALWAYS
  propagate. Model this with distinct error variants so the `handle_tool_errors`
  gate applies to ONLY the execution-error variant — exactly as Python's
  `ToolException`-subclass discrimination does.

## 5. Error handling policy → thiserror variants 🟠

```rust
#[non_exhaustive]
pub enum McpError {
    ToolExecution { blocks: Vec<ContentBlock> },  // isError=true; recoverable
    ContentConversion(String),                    // audio/unknown; always propagates
    Transport(rmcp::Error),                        // always propagates
    Protocol(String),
}
```
- `handle_tool_errors: bool` (default true): `ToolExecution` → build a
  `ToolMessage{status: Error, content: blocks}` (empty blocks → single minimal
  text block fallback, per Python). All other variants `?`-propagate.
- **No silent empty returns** (CLAUDE.md): the empty-content fallback is the ONE
  sanctioned substitution and it is explicit + tested (`test_mcp_tool_error_
  empty_content_uses_fallback_message`).

## 6. Interceptors → trait + onion 🟡

```rust
#[async_trait]
pub trait ToolCallInterceptor: Send + Sync {
    async fn intercept(&self, req: McpToolCallRequest, next: Next<'_>) -> Result<McpToolCallResult, McpError>;
}
```
- `McpToolCallRequest { name, args, headers (modifiable); server_name, runtime (context) }`
  with a `.override()` that returns a clone (struct-update). Rust closures
  capture-by-move → the Python late-binding-default-arg fix is unnecessary; port
  as straightforward `Next` chaining (like tower/axum middleware).
- Header mutation for sse/http → clone the `Connection` with merged headers
  (never mutate shared config).

## 7. Callbacks → trait objects 🟡

`Callbacks { on_logging_message, on_progress, on_elicitation }` as
`Option<Arc<dyn ...Fn -> BoxFuture>>`; `CallbackContext { server_name,
tool_name }` injected as trailing arg; `to_mcp_format` adapts to rmcp's callback
signatures. **Blocked on rmcp elicitation support** (see dependency-disposition
open item) — if rmcp lacks elicitation, gate `on_elicitation` behind a feature
and document.

## 8. Prompts / resources — 🟢

- `load_mcp_prompt`: rmcp `get_prompt` → each message: text+user→HumanMessage,
  text+assistant→AiMessage, else `Err`. Direct map to ferrochain-core messages.
- `load_mcp_resources`: text→Blob(text), blob→base64-decode→Blob(bytes), else
  `Err`; `uris=None` lists all (dynamic resources skipped). `Blob` from
  ferrochain-core with `{mime_type, metadata: {"uri"}}`. `RuntimeError`-on-fetch
  → `McpError` with failing URI.

## 9. MultiServerMCPClient — 🟡

```rust
pub struct MultiServerMcpClient {
    connections: HashMap<String, Connection>,
    callbacks: Callbacks,
    tool_interceptors: Vec<Arc<dyn ToolCallInterceptor>>,
    tool_name_prefix: bool,
    handle_tool_errors: bool,
}
```
- `get_tools(server: Option<&str>)` — one server or fan-out via `JoinSet`.
- `session(server)` — returns a scoped rmcp session (RAII); NOT stored.
- Deliberately **not a Drop-based CM with hidden state** — Python raises on
  `__aenter__`; the Rust equivalent is simply: the struct is cheap, sessions are
  per-call. Document that `MultiServerMcpClient` holds no live connections.

## 10. to_fastmcp (LC→server) — DEFER 🟠

Requires synthesizing a server tool from a ferrochain tool (pydantic
`create_model` analog via schemars) and rejects injected args. Server-side
export; defer to a later wave with rmcp's `#[tool]` server macros.

## Difficulty / risk summary

| Subsystem | Difficulty | Primary risk |
|---|---|---|
| Session lifecycle → ownership | 🟠 | on-demand-per-call vs Arc'd live session; no pooling in v1 |
| Tool conversion | 🟠 | content+artifact output shape in ferrochain-core; interceptor closures |
| Content-block translation | 🟡 | exact 6-way mapping; audio=NotImplemented preserved |
| Error policy | 🟠 | execution-error (gated) vs conversion/transport (always propagate) |
| Callbacks/elicitation | 🟡 | rmcp elicitation support unverified |
| rmcp API parity | 🟡 | verify structuredContent/isError/pagination fields |
| Connection enum + env expansion | 🟢 | serde-tagged; braced-only ${VAR} |
| to_fastmcp | 🟠 | DEFER (server-side, pydantic) |

## Cross-cutting open design questions (candidate ADRs)

1. **ADR: rmcp adoption + capability audit** — pin rmcp version; audit
   elicitation / structuredContent / isError / cursor-pagination; decide
   feature-gating for websocket + elicitation.
2. **ADR: session ownership model** — SessionSource enum (OnDemand vs Arc'd
   Live); explicitly NO connection pooling in v1 (perf ADR if added later).
3. **ADR: tool-output content+artifact shape in ferrochain-core** — ensure core
   tool output carries both blocks and structured artifact (dependency on core).
4. **ADR: error taxonomy split** — which McpError variants are governed by
   `handle_tool_errors` vs always-propagate (must match Python's ToolException
   discrimination exactly).
5. **ADR: langgraph `Command` result routing** — feature-gate under a `graph`
   feature depending on ferrochain-graph.

## State Checkpoint
```yaml
pass: 5
artifact: rust-translation-strategy
package: langchain-mcp-adapters
crate: ferrochain-mcp
substrate: rmcp 2.2.0
status: complete
timestamp: 2026-07-12
```
