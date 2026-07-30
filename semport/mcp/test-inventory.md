---
artifact: semport/mcp/test-inventory
project: pregolya
port_target: langchain-mcp-adapters (0.3.0)
analyzer_pass: 5
date: 2026-07-12
purpose: identify tests that LOCK the adapter's behavioral contracts → Red-Gate vectors for pregolya-mcp
---

# langchain-mcp-adapters — Test Inventory

## Test corpus scale

| File | LOC | Focus |
|---|---|---|
| `tests/test_tools.py` | 1,469 | Tool conversion, content translation, error policy, interceptors, transports — **primary contract** |
| `tests/test_client.py` | 353 | MultiServerMCPClient (get_tools, session, parallel) + stdio session env-var expansion (`test_stdio_session_*`) [validation-exhaustive] |
| `tests/test_interceptors.py` | 323 | Interceptor onion, override, retry/short-circuit |
| `tests/test_resources.py` | 275 | Resource → Blob (text/blob/errors) |
| `tests/test_elicitation.py` | 164 | Elicitation callback round-trip |
| `tests/test_callbacks.py` | 143 | Logging/progress/elicitation callback wiring + context injection |
| `tests/test_prompts.py` | 82 | Prompt message → Human/AI message |
| `tests/test_import.py` | 9 | Import smoke |
| `tests/servers/{math,weather,time}_server.py` | 70 | FastMCP test servers (fixtures) |
| `tests/conftest.py`, `tests/utils.py` | 168 | fixtures |

Total test LOC **3,056** (1.6× production). Tests use real in-process FastMCP
servers over stdio/http → pregolya should build equivalent rmcp test servers.

## Contract-LOCKING tests (Red-Gate vectors for pregolya-mcp)

### Content-block translation (the 6-way mapping — port exactly)
- `test_convert_empty_text_content`, `test_convert_single_text_content`,
  `test_convert_multiple_text_contents` — text mapping.
- `test_convert_image_content` — ImageContent → image block (base64+mime).
- `test_convert_resource_link` / `_image` / `_image_jpeg` / `_text` /
  `_no_mime_type` — ResourceLink branching (image/* → image url; else file url;
  mime fallbacks).
- `test_convert_embedded_resource_blob_image` / `_blob_file` — embedded blob →
  image vs file by mime prefix.
- `test_convert_audio_content_raises` — **AudioContent → NotImplementedError**
  (lock the "not supported" contract; pregolya must raise, not silently drop).
- `test_convert_with_structured_content` / `test_convert_mixed_content_with_
  structured_content` — artifact extraction alongside content.

### Error-handling policy (the handle_tool_errors gate — critical)
- `test_convert_with_error` — isError=true path builds error content.
- `test_mcp_tool_error_returns_failed_tool_message` — default: isError →
  `ToolMessage(status="error")`, run does NOT crash.
- `test_mcp_tool_success_returns_successful_tool_message` — happy path.
- `test_mcp_tool_success_returns_artifact_through_ainvoke` — artifact surfaced
  via invoke, content_and_artifact response_format.
- `test_mcp_tool_error_raises_with_opt_out_flag` — `handle_tool_errors=False`
  → ToolException raised (legacy).
- `test_transport_failure_still_raises` — transport error ALWAYS propagates
  regardless of flag. **Locks the error-taxonomy split.**
- `test_adapter_bug_still_raises` — AudioContent conversion (`NotImplementedError`) propagates even when `isError=True` and `handle_tool_errors=True`; content-conversion errors bypass `_handle_mcp_tool_error` entirely (they are not `ToolException` subclasses) and always propagate. The "bare ToolException re-raise" path in `_handle_mcp_tool_error` is described in the docstring but has no dedicated lock test in the suite. [validation-exhaustive]
- `test_mcp_tool_error_empty_content_uses_fallback_message` — empty error
  content → single minimal text block (the ONE sanctioned fallback).
- `test_mcp_tool_error_preserves_non_text_content` — image/file error blocks
  preserved verbatim (locks the `handle_tool_error` list-return type hack).
- `test_mcp_tool_error_non_text_only_passes_through` — non-text-only error path.
- `test_load_mcp_tools_threads_handle_tool_errors` /
  `test_multi_server_client_threads_handle_tool_errors` — the flag threads from
  client → load → convert. **Sibling-sweep lock.**

### Tool conversion + loading + metadata
- `test_convert_mcp_tool_to_langchain_tool` — end-to-end single tool.
- `test_load_mcp_tools` — list + convert all (pagination behavior).
- `test_convert_mcp_tool_metadata_variants` — annotations + `_meta` → metadata.
- `test_load_mcp_tools_with_annotations` — annotation passthrough.
- `test_get_tools_with_name_conflict` — tool_name_prefix disambiguation.

### Transports (session-on-demand + factories)
- `test_load_mcp_tools_with_http_variations` (parametrized transport) — http /
  streamable-http / sse aliases all work.
- `test_load_mcp_tools_with_custom_httpx_client_factory` / `_sse` — the
  `McpHttpClientFactory` protocol → pregolya reqwest-factory (rustls-tls).
- `test_parallel_tool_invocation_across_multiple_servers` — asyncio.gather
  fan-out → Rust JoinSet/try_join_all parity.

### Interceptors (test_interceptors.py + test_tools.py)
- `test_mcp_tools_with_agent_and_command_interceptor` — interceptor returning a
  langgraph `Command`; onion composition; header mutation. Route Command to
  pregolya-graph.
- test_interceptors.py (323 LOC): override immutability, multi-call (retry),
  skip (short-circuit/cache), first=outermost ordering.

### FastMCP reverse (server-side — DEFER)
- `test_convert_langchain_tool_to_fastmcp_tool` (parametrized) +
  `_with_injection` (rejects injected args). Locks the deferred `to_fastmcp`.

### Client (test_client.py)
- MultiServerMCPClient get_tools (one/all, `test_multi_server_mcp_client`),
  session CM (`test_multi_server_connect_methods`), parallel fan-out.
- Stdio session env-var expansion (`test_stdio_session_expands_env_vars`,
  `test_stdio_session_bare_dollar_not_expanded`,
  `test_stdio_session_warns_on_undefined_env_var`, etc.) — these tests live
  in test_client.py, NOT in a dedicated sessions test file.
- **`test_get_tools_with_name_conflict`** is in `test_tools.py`, not here.
- **`MultiServerMCPClient.__aenter__` NotImplementedError has NO lock test
  anywhere in the Python suite** (the behavior exists in `MultiServerMCPClient.__aenter__`
  but is untested). pregolya-mcp must add this test. [validation-exhaustive]

### Prompts (test_prompts.py)
- user→Human, assistant→AI, unsupported role/content → ValueError.

### Resources (test_resources.py)
- text→Blob, blob→base64-decode Blob, unsupported→TypeError, uris=None lists
  all, fetch error → RuntimeError with URI.

### Elicitation (test_elicitation.py)
- Server-initiated elicitation → `on_elicitation` callback → ElicitResult.
  **Gates on rmcp elicitation support** (dependency-disposition open item #1).

### Callbacks (test_callbacks.py)
- Logging/progress/elicitation callbacks fire with injected `CallbackContext`
  (server_name/tool_name).

## Coverage / parity notes
- Tests rely on live FastMCP servers → pregolya needs equivalent **rmcp-based
  test servers** (math/weather/time) as fixtures; the assertions (tool outputs,
  error shapes) become the parity oracle.
- `pytest-socket` gates network; pregolya uses `#[ignore]` + in-process rmcp
  servers per SID-1 (drive behavior without external network).
- **Gap:** websocket transport has no substantive behavioral test (matches its
  optional-extra status) → DEFER websocket with a documented dependency.

## State Checkpoint
```yaml
pass: 5
artifact: test-inventory
package: langchain-mcp-adapters
crate: pregolya-mcp
test_loc: 3056
red_gate_vector_families: 10
gates_on_rmcp: [elicitation]
status: complete
timestamp: 2026-07-12
```
