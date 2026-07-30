---
artifact: semport/mcp/dependency-disposition
project: pregolya
port_target: langchain-mcp-adapters (0.3.0) → pregolya-mcp
analyzer_pass: 5
date: 2026-07-12
headline: the mcp python SDK → rmcp (official Rust MCP SDK), verified on crates.io
---

# langchain-mcp-adapters — Dependency Disposition

Disposition vocabulary: **PORT** · **MAP** · **DEFER** · **DROP**.

## The pivotal decision: the `mcp` Python SDK → Rust MCP SDK

### Rust MCP SDK landscape (verified with crates.io / GitHub evidence, 2026-07)

| Candidate | Evidence | Verdict |
|---|---|---|
| **`rmcp`** | crates.io: **v2.2.0, released 2026-07-08**; **15.5M total downloads** (8.0M recent). Repo `modelcontextprotocol/rust-sdk` — **the OFFICIAL Rust MCP SDK**. Features: client+server (default `macros`+`server`, optional `client`). Transports: **stdio / child-process / SSE (client+server) / streamable-HTTP (client via reqwest, incl. Unix socket + server w/ session support) / worker / async read-write**. Supports `list_tools`/`call_tool`, prompts (`#[prompt]`), resources (`list_resources`/`read_resource`), progress callbacks, logging. | **ADOPT (MAP)** — this is the substrate `pregolya-mcp` builds on. Matches every transport the Python adapter supports (stdio/SSE/streamable-http) and more. |
| `mcp-sdk` / `mcp_rust_sdk` / community forks | Older, far fewer downloads, unofficial, partial transport coverage | REJECT — rmcp supersedes; no reason to adopt a community fork over the official SDK. |
| Hand-roll MCP protocol | High effort, re-derives JSON-RPC framing + capability negotiation | REJECT — rmcp is official, mature (15M downloads), actively released. |

**Decision: MAP the `mcp` Python SDK to `rmcp` (official).** `pregolya-mcp`
becomes an adapter from rmcp's client types to pregolya-core's tool/message
abstractions — mirroring how langchain-mcp-adapters adapts the Python `mcp` SDK
to langchain-core. This is exactly the D1-amendment "first-class crate" shape.

### rmcp capability parity vs the Python adapter's needs

| Adapter need | Python `mcp` | `rmcp` | Parity |
|---|---|---|---|
| stdio transport | `stdio_client` | child-process / stdio transport | ✅ |
| SSE transport | `sse_client` | SSE client | ✅ |
| streamable-http | `streamable_http_client` | streamable-http client (reqwest) | ✅ (use rustls-tls per CLAUDE.md) |
| websocket | `mcp[ws]` extra | worker/async-rw; WS not first-class | ⚠️ DEFER websocket (matches Python's optional-extra status) |
| ClientSession init/list/call | `ClientSession` | rmcp service/peer client | ✅ |
| list_tools cursor pagination | manual loop | rmcp may expose paginated helpers | ⚠️ verify; port MAX_ITERATIONS bound regardless |
| structuredContent / artifacts | `CallToolResult.structuredContent` | rmcp `CallToolResult` | ✅ verify field |
| progress / logging / elicitation callbacks | SDK callback fns | progress + logging documented; **elicitation not confirmed in README** | ⚠️ **verify elicitation support in rmcp** (Python adapter has `on_elicitation` + a whole test file) |
| Command result (langgraph) | optional | N/A (pregolya-graph owns this) | route to pregolya-graph |

## Other dependencies

| Python dep | Used for | Disposition | Rust target | Notes |
|---|---|---|---|---|
| `langchain-core` | `BaseTool`/`StructuredTool`, `ToolMessage`, content blocks, `Blob`, messages | PORT (internal) | `pregolya-core` | The whole point is producing pregolya-core tool/message types. Depends on core semport landing tool + content-block types first. |
| `mcp` (>=1.9.2) | transports, `ClientSession`, wire types | **MAP → rmcp 2.2** | `rmcp` | See above. |
| `httpx` | SSE/HTTP client + `McpHttpClientFactory` protocol + `httpx.Auth` | MAP | `reqwest` (rustls-tls, 30s timeout) | CLAUDE.md mandates `default-features=false, features=["rustls-tls"]` and 30s timeout. rmcp's streamable-http uses reqwest already. Auth → reqwest middleware / bearer. |
| `typing-extensions` | TypedDict/NotRequired/Unpack | DROP | native Rust types | — |
| `langgraph` (optional) | `Command` tool-result variant + runtime | ROUTE | `pregolya-graph` | `Command` result handling belongs to pregolya-graph; feature-gate `pregolya-mcp`'s Command support behind a `graph` feature that depends on pregolya-graph. |
| `pydantic` | `to_fastmcp` server-side model synthesis | DEFER | `schemars`/`serde` | Only used by the reverse `to_fastmcp` path (LC→FastMCP server). Defer server-side export to a later wave. |
| build/test (`pytest*`, `ruff`, `mypy`, `websockets`, `dirty-equals`) | — | DROP | cargo + nextest | — |

## Security / correctness carry-overs (production-grade, non-deferrable)

- **`${VAR}` env expansion (braced-only)** — port faithfully; bare `$VAR` must
  stay literal (protects passwords). Warn on unexpanded refs (`tracing::warn!`).
- **reqwest rustls-tls + 30s timeout** — CLAUDE.md hard rule for the
  streamable-http/SSE transports; native-tls forbidden.
- **Auth headers / bearer tokens** transiting the HTTP client are credentials →
  if pregolya-mcp wraps any API key in a config type, apply the redacted
  newtype `Debug` rule.
- **Header-mutation-clones-connection** path (tools.py:441-456) — preserve; an
  interceptor changing headers must not mutate the shared connection.

## Disposition summary

- **MAP (HIGH confidence):** `mcp` → **rmcp 2.2.0 (official)**; `httpx` →
  `reqwest` (rustls-tls); langchain-core tool/message/Blob → pregolya-core.
- **PORT (adapter logic):** all 8 modules' translation + client + interceptor +
  callback logic.
- **DEFER:** websocket transport (matches Python optional status); `to_fastmcp`
  server-export (pydantic); elicitation IF rmcp lacks it (verify first).
- **ROUTE:** langgraph `Command` result → pregolya-graph feature.
- **DROP:** typing-extensions, deprecated `split_text_from_url` analogs (n/a),
  test tooling.

## Open verification items (do NOT leave as "TODO for architect" — resolve in Phase 1)
1. Confirm rmcp exposes **elicitation** client callback (Python has a full
   `on_elicitation` surface + `test_elicitation.py`). If absent, decide: DEFER
   elicitation or contribute upstream. (Answerable by reading rmcp 2.2 docs.)
2. Confirm rmcp `CallToolResult` exposes `structuredContent` and
   `isError` fields for artifact + error-policy parity.
3. Confirm rmcp cursor pagination shape for `list_tools`.

## State Checkpoint
```yaml
pass: 5
artifact: dependency-disposition
package: langchain-mcp-adapters
crate: pregolya-mcp
rust_mcp_sdk: rmcp 2.2.0 (official, crates.io verified)
map_high_confidence: [rmcp, reqwest]
verify_before_phase1: [elicitation, structuredContent/isError fields, pagination]
status: complete
timestamp: 2026-07-12
```
