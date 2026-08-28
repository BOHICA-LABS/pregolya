---
document_type: story
level: ops
story_id: S-2.10
epic_id: E-21
version: "1.4"
status: draft
producer: story-writer
timestamp: 2026-08-28T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.001.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.002.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.003.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.004.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.005.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "1c0a7f9"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.19, S-1.04, S-1.22]
blocks: [S-2.11]
behavioral_contracts: [BC-2.09.001, BC-2.09.002, BC-2.09.003, BC-2.09.004, BC-2.09.005]
verification_properties: [VP-004, VP-005]
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-mcp
subsystems: [SS-09]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: all 5 BCs active; BC-2.09.004 (VP-004, R11) and BC-2.09.005 (VP-005, R11) are Red Gate BCs; status = draft per Spec-First Gate S-7.01
changelog:
  - "1.4 (round-26/F-P2A115-01+F-P2A115-02+O-P2A115-05+O-P2A115-06/2026-08-28): EC-005 corrected to fail-closed: first server timeout/failure aborts whole call as Err(E-MCP-002); no partial tool list returned (BC-2.09.001 EC-004/{PC-005}). AC-013 fallback text aligned to BC-2.09.002 EC-001/TV-006 canonical: ToolMessage{status:Error, content:[\"MCP tool '<name>' returned an error with no content\"]}. EC-003 guardrail-reject fallback aligned to BC-2.09.003 EC-003 canonical: \"Tool result from '<server>/<tool>' was blocked by guardrail policy.\". AC-019 mechanism description corrected: bare ToolException is raised OUTSIDE the isError content-conversion path (not isError=false with metadata in content) per BC-2.09.004 {PRE-002}/{PRE-003}; E-MCP-001 outcome unchanged. Input-hash updated."
  - "1.3 (round-25/F-P2A108-01+F-P2A111-03+F-P2A111-06/2026-08-28): §Behavioral Contracts table: 4 titles synced to BC-INDEX canonical — BC-2.09.001 '...at Runtime', BC-2.09.002 '...Transport', BC-2.09.004 '...Preserving Type Identity (Red Gate — R11)', BC-2.09.005 '...Holds No Live Connections (Red Gate — R11)'. §Architecture Mapping + §File Structure Requirements + §Tasks: `tool.rs` → `discovery.rs`; `guardrail.rs` → `ingress.rs` (DI-012 seam; canonical module names per module-decomposition.md §pregolya-mcp). Input-hash updated."
  - "1.2 (round-24/F-P2A104-01/2026-08-28): AC-026 mirrored from BC-2.09.001 §Description/{PC-003}/{INV-001} (F-P2A104-01) — phantom field on `Arc<dyn DynTool>` replaced by `schema()` accessor; schema surface type corrected from `serde_json::Value` to `schemars::Schema`; test renamed `test_BC_2_09_001_schema_verbatim_passthrough`; `schemars` added to §Library & Framework Requirements. Input-hash updated per BC-2.09.001 §Description/{PC-003}/{INV-001} authoritative input."
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors."
---

# S-2.10: MCP Client — Tool Discovery, Invocation Routing, and Untrusted Ingress

## Narrative

- **As a** pregolya agent developer connecting to external tool providers via MCP
- **I want to** have a `MultiServerMcpClient` that discovers tools from one or more MCP servers, routes invocations through an interceptor chain with guardrails, handles bare `ToolException` re-raises correctly, and holds no live network connections in its config-only structure
- **So that** agents can dynamically acquire tool capabilities from MCP servers, all tool results are treated as untrusted ingress with provenance tagging, bare ToolException signals are never silently swallowed, and the client struct is safe to clone and store without hidden network resources

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.09.001 | MCP Server Tool Discovery and Registration at Runtime | P1 |
| BC-2.09.002 | ToolInvocation Routing to Correct MCP Server Transport | P1 |
| BC-2.09.003 | Tool-Result Content Treated as Untrusted Ingress | P1 |
| BC-2.09.004 | MCP Bare ToolException Re-Raise Preserving Type Identity (Red Gate — R11) | P1 |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections (Red Gate — R11) | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.09.001 PC-001)
`MultiServerMcpClient::get_tools(server_name: Option<&str>) -> Result<Vec<Arc<dyn DynTool>>, PregolyaError>`
returns all tools from the named server. Each tool is an `Arc<dyn DynTool>` constructed
via `convert_mcp_tool`. Verified by `test_BC_2_09_001_get_tools_single_server()`.

### AC-002 (traces to BC-2.09.001 PC-001 + INV-003 + EC-007)
`list_tools()` cursor pagination respects a `MAX_ITERATIONS = 1000` guard. A server that
requires more than 1000 paginated calls is aborted fail-closed with
`Err(PregolyaError { code: "E-MCP-008", .. })` (McpPaginationLimitExceeded; POLICY category)
to prevent infinite loops. Silent truncation is not permitted. The error message form is:
`McpPaginationLimitExceeded: server '<server>' exceeded MAX_ITERATIONS=1000 pagination calls`.
Verified by `test_BC_2_09_001_pagination_max_iterations_guard()`.

### AC-003 (traces to BC-2.09.001 PC-005)
`get_tools(None)` (all servers) uses `tokio::task::JoinSet` to fan out discovery concurrently
across all configured servers. Results from all servers are merged into a single flat list.
Verified by `test_BC_2_09_001_get_tools_all_servers_joinset_fanout()`.

### AC-004 (traces to BC-2.09.001 PC-006)
When `tool_name_prefix: true` is configured, each discovered tool's name is prefixed with
the server name: `"<server_name>_<original_name>"`. Verified by
`test_BC_2_09_001_tool_name_prefix_flag()`.

### AC-005 (traces to BC-2.09.001 PC-007 + EC-006)
A transport-level failure during discovery returns `Err(PregolyaError { code: "E-MCP-002", .. })`.
A JSON-RPC -32601 response (method not found, e.g., server doesn't support `tools/list`)
returns `Err(PregolyaError { code: "E-MCP-003", .. })`. Verified by
`test_BC_2_09_001_transport_error_returns_e_mcp_002()` and
`test_BC_2_09_001_method_not_found_returns_e_mcp_003()`.

### AC-006 (traces to BC-2.09.002 PC-001)
The interceptor chain processes in correct onion order: the outermost interceptor sees the
request first and the response last. A test with three interceptors records invocation order
and verifies: interceptor 1 pre → interceptor 2 pre → interceptor 3 pre → handler → interceptor 3 post → interceptor 2 post → interceptor 1 post. Verified by
`test_BC_2_09_002_interceptor_chain_onion_order()`.

### AC-007 (traces to BC-2.09.002 PC-002)
Each tool invocation creates a new `McpSessionGuard` (RAII) via the `OnDemand` lifecycle.
The session is dropped after the invocation completes. No session is stored in the client.
Verified by `test_BC_2_09_002_on_demand_session_created_and_dropped_per_call()`.

### AC-008 (traces to BC-2.09.002 PC-004)
With `handle_tool_errors: true` (the default), when the MCP server returns `isError: true`
in the `CallToolResult`, the client returns
`Ok(ToolMessage { status: ToolMessageStatus::Error, .. })`. No `Err` is returned.
Verified by `test_BC_2_09_002_handle_tool_errors_true_returns_ok_tool_message_error()`.

### AC-009 (traces to BC-2.09.002 PC-004)
With `handle_tool_errors: false`, when the MCP server returns `isError: true`, the client
returns `Err(PregolyaError { code: "E-MCP-007", .. })`. Verified by
`test_BC_2_09_002_handle_tool_errors_false_returns_e_mcp_007()`.

### AC-010 (traces to BC-2.09.002 PC-005)
A transport-level error (connection refused, timeout, serialization failure) ALWAYS
propagates as `Err(PregolyaError { code: "E-MCP-002", .. })` regardless of the
`handle_tool_errors` flag. The flag does not suppress transport errors. Verified by
`test_BC_2_09_002_transport_error_always_propagates()`.

### AC-011 (traces to BC-2.09.002 PC-006)
A content-conversion error (unsupported content type in the MCP response) ALWAYS propagates
as `Err(PregolyaError { code: "E-MCP-006", .. })` regardless of `handle_tool_errors`.
Verified by `test_BC_2_09_002_content_conversion_error_always_propagates()`.

### AC-012 (traces to BC-2.09.002 PC-007)
`structuredContent` in the `CallToolResult` is converted to `MCPToolArtifact` and included
in the `ToolMessage`. Verified by `test_BC_2_09_002_structured_content_to_mcp_tool_artifact()`.

### AC-013 (traces to BC-2.09.002 PC-004 + EC-001)
When the MCP server returns `isError: true` with an empty content array, the client
synthesizes `ToolMessage { status: ToolMessageStatus::Error, content: [ContentBlock::Text { text: "MCP tool '<name>' returned an error with no content" }] }` — BC-2.09.002 EC-001/TV-006 canonical form where `<name>` is the actual tool name from the invocation.
Verified by `test_BC_2_09_002_empty_error_content_fallback_text_block()`.

### AC-014 (traces to BC-2.09.003 PC-001)
A registered `GuardrailHook` is called on every non-error tool result before the result is
returned to the caller. The guardrail fires AFTER the tool executes and BEFORE the result
is returned. Verified by `test_BC_2_09_003_guardrail_fires_on_non_error_result()`.

### AC-015 (traces to BC-2.09.003 PC-001)
The tool result passed to the guardrail carries a `ProvenanceTag` with
`boundary_type: BoundaryType::ToolResult`, a unique `ingress_id` (UUID), and
`sequence_position: 0`. Verified by `test_BC_2_09_003_provenance_tag_fields()`.

### AC-016 (traces to BC-2.09.003 PC-003)
When the guardrail rejects a result, the caller receives
`Ok(ToolMessage { status: ToolMessageStatus::Error, content: [rejection_block] })`.
The rejection reason from the guardrail is included in the rejection block text. Verified by
`test_BC_2_09_003_guardrail_reject_returns_tool_message_error()`.

### AC-017 (traces to BC-2.09.003 PC-004)
When no `GuardrailHook` is registered and `handle_tool_errors: true`:
- The tool result is returned as-is (default-permit).
- `tracing::warn!(event_type = "guardrail.unregistered_passthrough", boundary_type = "ToolResult", ingress_id = %ingress_id, item_count = %count, timestamp = %ts, server_name = %server, tool_name = %tool)` is emitted.
- The event type `"guardrail.unregistered_passthrough"` is registered in the Canonical Structured Event Catalog (SAP-1).
Verified by `test_BC_2_09_003_no_guardrail_emits_unregistered_passthrough_warning()`.

### AC-018 (traces to BC-2.09.003 PRE-001 + EC-004)
The `GuardrailHook` is NOT called when the tool result has `isError: true`. The guardrail
only fires on successful results. Verified by
`test_BC_2_09_003_guardrail_not_called_on_is_error_true()`.

### AC-019 (traces to BC-2.09.004 PC-001 — RED GATE VP-004)
**Red Gate (VP-004):** The test `test_BC_2_09_004_bare_tool_exception_reraise` asserts that
a bare `ToolException` raised OUTSIDE the `isError` content-conversion path (it is NOT an
`isError=false` `CallToolResult` carrying metadata; per BC-2.09.004 {PRE-002}/{PRE-003}, the
`ToolException` is a distinct signal from the `CallToolResult` structure) is re-raised by
the client as `Err(PregolyaError { code: "E-MCP-001", .. })`.
This test MUST compile and FAIL before the bare-ToolException detection logic is implemented.

**SID-1 compliance (GAP-003):** The live-server integration test for VP-004 is:
```rust
#[tokio::test]
#[ignore]
// EXT-001: requires live MCP server with a ToolException-raising tool;
// ungated in CI after MCP server provisioning
async fn test_BC_2_09_004_bare_tool_exception_reraise_live() { ... }
```
A non-ignored in-process mock substitute MUST also exist:
`test_BC_2_09_004_bare_tool_exception_reraise_unit_mock()` — uses an in-process MCP stub
that returns a bare ToolException payload, exercises the same code path without a live server.

### AC-020 (traces to BC-2.09.004 PC-003)
A bare `ToolException` (Python-side exception propagated via MCP) produces
`Err(PregolyaError { code: "E-MCP-001", .. })` regardless of the `handle_tool_errors`
flag. The flag controls `isError: true` results; bare ToolException is a distinct path.
Verified by `test_BC_2_09_004_bare_tool_exception_ignores_handle_tool_errors_flag()`.

### AC-021 (traces to BC-2.09.004 PC-004)
The `PregolyaError` source chain for E-MCP-001 preserves the `ToolException` type identity.
The original exception type name is present in `PregolyaError::source()` or the error message.
Verified by `test_BC_2_09_004_error_source_chain_preserves_type_identity()`.

### AC-022 (traces to BC-2.09.005 PC-006 — RED GATE VP-005)
**Red Gate (VP-005):** The test `test_BC_2_09_005_drop_client_zero_network_io` asserts that
dropping a `MultiServerMcpClient` produces zero network I/O. This test MUST compile and FAIL
before the no-live-connections invariant is enforced (a naive implementation might create
connections eagerly on construction).

**SID-1 compliance (GAP-003):** The live-monitoring integration test for VP-005 is:
```rust
#[tokio::test]
#[ignore]
// EXT-002: validates zero network I/O on Drop via network packet monitoring;
// ungated in CI after network monitoring probe provisioning
async fn test_BC_2_09_005_drop_client_zero_network_io_live() { ... }
```
A non-ignored in-process unit test MUST also exist:
`test_BC_2_09_005_no_live_connections_unit()` — constructs a `MultiServerMcpClient` with
a mock server config, verifies no connection was attempted (using a mock transport that fails
if `connect()` is called), and drops the client.

### AC-023 (traces to BC-2.09.005 PC-001)
`MultiServerMcpClient::new(config: MultiServerMcpConfig)` creates a config-only container.
No TCP connections, no TLS handshakes, no authentication exchanges occur at construction time.
Verified by `test_BC_2_09_005_construction_is_config_only()`.

### AC-024 (traces to BC-2.09.005 PC-003)
`MultiServerMcpClient` has NO `close()` or `connect()` public methods. Calling
`client.close()` is a compile-time error (`method not found`). This is BC-2.09.005 TV-005.
Verified by compile-fail test `test_BC_2_09_005_no_close_method_compile_fail()`.

### AC-025 (traces to BC-2.09.005 PC-004)
`MultiServerMcpClient` implements `Send + Sync + Clone`. It can be stored in an `Arc`,
shared across tasks, and cloned without duplicating network resources (there are none).
Verified by `test_BC_2_09_005_client_is_send_sync_clone()`.

### AC-026 (traces to BC-2.09.001 PC-003 + INV-001)
`convert_mcp_tool` produces an `Arc<dyn DynTool>` whose `schema()` method returns the
server's `tool.inputSchema` wrapped verbatim as a `schemars::Schema` — no synthesis and
no `schema_for!` re-derivation are performed by `pregolya-mcp`. If the server provides no
`inputSchema`, `schema()` returns an empty/`Value::Null`-backed `Schema`. Verified by
`test_BC_2_09_001_schema_verbatim_passthrough()`.

### AC-027 (traces to BC-2.09.001 PC-008)
A server that returns an empty tool list (`tools: []`) for any valid transport is not an
error. `get_tools` returns `Ok(vec![])` for that server. Verified by
`test_BC_2_09_001_empty_tool_list_ok()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `MultiServerMcpClient` config container | `pregolya-mcp/src/client.rs` | pure-core (config-only) |
| `McpSessionGuard` RAII session | `pregolya-mcp/src/session.rs` | effectful (connects on creation, drops on drop) |
| `convert_mcp_tool` adapter | `pregolya-mcp/src/discovery.rs` | pure-core (converts MCP schema → DynTool) |
| Interceptor chain executor | `pregolya-mcp/src/interceptor.rs` | effectful (runs interceptors around tool call) |
| `GuardrailHook` dispatcher | `pregolya-mcp/src/ingress.rs` | effectful (calls guardrail hook; DI-012 seam) |
| Bare ToolException detector | `pregolya-mcp/src/exception.rs` | pure-core (inspects content for exception metadata) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `MultiServerMcpClient` (struct, config, Clone) | pure-core | No I/O; holds only deserialized config |
| `McpSessionGuard` | effectful | Connects to MCP server on creation; drops (disconnects) on Drop |
| `convert_mcp_tool` | pure-core | Pure transformation of JSON schema to DynTool; no network |
| Interceptor chain | effectful | Dispatches HTTP calls through the interceptor pipeline |
| Bare ToolException detector | pure-core | Pure inspection of `CallToolResult.content` fields |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | `get_tools(Some("nonexistent_server"))` (traces to BC-2.09.001 PC-009 + EC-008) | `Err(PregolyaError { code: "E-MCP-009", .. })` (McpServerNotConfigured; VAL) — message: `McpServerNotConfigured: no MCP server named '<server>' is configured` |
| EC-002 | Tool invocation with `McpSessionGuard` that fails to connect | `Err(E-MCP-002)` from session creation; no tool code executed |
| EC-003 | Guardrail returns `Reject` with empty reason string | `ToolMessage{status:Error, content: [text: "Tool result from '<server>/<tool>' was blocked by guardrail policy."]}` — BC-2.09.003 EC-003 canonical fallback |
| EC-004 | `tool_name_prefix: true` with server name containing `__` | Prefix uses `"<server_name>_<tool>"` verbatim — no escaping of the separator |
| EC-005 | JoinSet fan-out where one server times out | The first server transport failure or timeout aborts the whole call with `Err(PregolyaError { code: "E-MCP-002", .. })`; no partial tool list is returned — BC-2.09.001 EC-004/{PC-005} fail-closed; matches S-2.10 AC-005 and AC-003 |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~4,500 |
| BC files (5 BCs) | ~11,000 |
| `module-decomposition.md` SS-09 section | ~500 |
| `pregolya-mcp/src/` (new module, 6 files) | ~3,000 |
| Test file stubs (AC-001 to AC-027) | ~3,200 |
| SID-1 mock test infrastructure | ~1,000 |
| Tool outputs | ~500 |
| **Total** | **~23,700** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~12%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-027 (test-writer step)
2. [ ] **Red Gate check AC-019:** confirm `test_BC_2_09_004_bare_tool_exception_reraise_unit_mock()` FAILS before implementation
3. [ ] **Red Gate check AC-022:** confirm `test_BC_2_09_005_no_live_connections_unit()` FAILS before implementation (if naive impl connects eagerly)
4. [ ] Create `pregolya-mcp/src/client.rs` — `MultiServerMcpClient`, `MultiServerMcpConfig` (config-only, no connections)
5. [ ] Create `pregolya-mcp/src/session.rs` — `McpSessionGuard` RAII (connect on create, drop on drop)
6. [ ] Implement `get_tools` with cursor pagination (MAX_ITERATIONS=1000) and JoinSet fan-out
7. [ ] Implement `convert_mcp_tool` — MCP ToolDefinition → `Arc<dyn DynTool>`
8. [ ] Create `pregolya-mcp/src/interceptor.rs` — interceptor chain with onion execution order
9. [ ] Create `pregolya-mcp/src/ingress.rs` — `GuardrailHook` dispatcher, provenance tagging (canonical module per module-decomposition.md §pregolya-mcp; DI-012 seam)
10. [ ] Implement bare ToolException detection and E-MCP-001 re-raise
11. [ ] Add `tracing::warn!(event_type = "guardrail.unregistered_passthrough", ...)` and register in Catalog (SAP-1)
12. [ ] Write compile-fail test for AC-024 (`client.close()` must not compile)
13. [ ] Write SID-1 mock tests: `test_BC_2_09_004_bare_tool_exception_reraise_unit_mock()` and `test_BC_2_09_005_no_live_connections_unit()` (non-ignored)
14. [ ] Register `guardrail.unregistered_passthrough` in Canonical Structured Event Catalog (SAP-1)
15. [ ] Run `cargo nextest run -p pregolya-mcp` — all ACs green

## Previous Story Intelligence (MANDATORY)

S-1.19 established the `GuardrailHook` interface and `BoundaryType` in `pregolya-core`. The
`MultiServerMcpClient` uses `GuardrailHook` directly — import from `pregolya-core`, do not
re-define it in `pregolya-mcp`.

S-1.22 established the `BashTool` in `pregolya-tools` and the general `DynTool` object-safe
seam. `convert_mcp_tool` wraps MCP tool schemas as `Arc<dyn DynTool>`. Use the same `DynTool`
trait from S-1.06/S-1.22; do not create a new trait.

S-1.04 established `Runnable`, `RunnableConfig`, and the `?` error propagation pattern. The
interceptor chain uses `RunnableConfig` for context threading.

The `McpSessionGuard` RAII model is inspired by the Python `__aenter__`/`__aexit__` lifecycle
(R11 upstream finding — `__aenter__` must not raise `NotImplementedError`). In Rust, this
becomes `McpSessionGuard::new()` must not panic; connection failures return `Err(E-MCP-002)`.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `MultiServerMcpClient` holds NO network resources (no sessions, connections, sockets) | BC-2.09.005 INV-002 | Red Gate test AC-022; compile test AC-024 |
| `DynTool` not `Tool` for vtable dispatch (object-safe) | ADR-005 §Adjacent Trait Object-Safety Adjudications | Compile test |
| Bare ToolException → E-MCP-001 regardless of `handle_tool_errors` flag | BC-2.09.004 PC-003 | Test AC-020 |
| Transport errors ALWAYS propagate (never suppressed by `handle_tool_errors`) | BC-2.09.002 PC-005 | Test AC-010 |
| Guardrail NOT called on `isError: true` results | BC-2.09.003 INV-001 + EC-004 | Test AC-018 |
| `guardrail.unregistered_passthrough` registered in Structured Event Catalog | SAP-1 | Pre-PR catalog row |
| `client.close()` is a compile-time error | BC-2.09.005 TV-005 | Compile-fail test AC-024 |
| SID-1: `#[ignore]` live tests have companion non-ignored mock unit tests | SID-1; GAP-003 | ACs AC-019, AC-022 |

**Forbidden dependencies:** `pregolya-mcp` must NOT depend on `pregolya-graph`, `pregolya-server`,
`pregolya-vectorstores`, `pregolya-prompts`, or `pregolya-standard-tests`. It depends on
`pregolya-core` (for `DynTool`, `GuardrailHook`, `RunnableConfig`, `PregolyaError`) and the
`rmcp` SDK crate (MCP protocol). If `pregolya-mcp` gains a dependency on `pregolya-graph` or
`pregolya-server`, the build MUST fail.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `rmcp` | workspace pin | MCP protocol SDK — `list_tools()` cursor, `call_tool()`, transport |
| `tokio` | workspace pin | `JoinSet` for fan-out; `#[tokio::test]` |
| `uuid` | workspace pin | `ingress_id` UUID generation for `ProvenanceTag` |
| `tracing` | workspace pin | `tracing::warn!` for unregistered passthrough (SAP-1) |
| `async-trait` | workspace pin | `GuardrailHook` async method dispatch |
| `schemars` | workspace pin | `schemars::Schema` type for `DynTool::schema()` verbatim-passthrough return value |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-mcp/src/client.rs` | CREATE | `MultiServerMcpClient`, `MultiServerMcpConfig` |
| `pregolya-mcp/src/session.rs` | CREATE | `McpSessionGuard` RAII |
| `pregolya-mcp/src/discovery.rs` | CREATE | `convert_mcp_tool`, `McpDynTool` wrapper |
| `pregolya-mcp/src/interceptor.rs` | CREATE | Interceptor chain, onion order executor |
| `pregolya-mcp/src/ingress.rs` | CREATE | Guardrail dispatch, provenance tagging (DI-012 seam; `ingress.rs` is the canonical module name per module-decomposition.md §pregolya-mcp) |
| `pregolya-mcp/src/exception.rs` | CREATE | Bare ToolException detection logic |
| `pregolya-mcp/src/lib.rs` | CREATE | Re-export-only root |
| `pregolya-mcp/Cargo.toml` | CREATE | Dependencies: pregolya-core, rmcp, tokio, uuid, tracing |
| `pregolya-mcp/tests/compile_fail/no_close_method.rs` | CREATE | Compile-fail test for AC-024 |
