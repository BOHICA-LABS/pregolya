---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.001
version: "1.11"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-66): F-P66-01 — EC-006 and TV-008 added: JSON-RPC -32601 MethodNotFound when server does not implement tools/list → Err(E-MCP-003 McpNotImplemented). Re-anchor for E-MCP-003 from BC-2.09.005 (lifecycle scope) to this BC (discovery path — first MCP method invoked). (OBS-P28-2 class; gate #33 reverse-verification finding.)"
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-mcp per module-decomposition.md v1.10."
  - "1.3 (CENSUS-P109, 2026-07-18): Expand TV-004 E-MCP-002 McpTransportError struct from `{ server: \"math\", ... }` to `{ server: \"math\", transport_error: \"connection refused\" }` — `...` abbreviation failed PASS-ABBREV rule (no defining full-struct PC/EC site in BC; TV-004 was the sole struct site). TD-VSDD-060 sweep: no other E-MCP-002 struct sites in file."
  - "1.4 (FIX-BURST-277-WAVE-C/ADR-005-DynTool/2026-07-28): Description + PC2: migrate Arc<dyn pregolya_core::Tool> -> Arc<dyn DynTool> per ADR-005 §Adjacent Trait Object-Safety Adjudications (dyn Tool is non-object-safe; DynTool is the object-safe seam; blanket impl auto-implements DynTool for T: Tool + Send + Sync + 'static; definition in interface-definitions.md §DynTool)."
  - "1.5 (WAVE-B-NOTATION-SWEEP/2026-07-29): Class 3 notation sweep — two violations corrected: (1) PC7 `PregolyaError { component: MCP, category: TRANSPORT, code: E-MCP-002 }` had 3/5 fields; added `, ..`. (2) EC-006 §Expected behavior multiline span (4/5 fields, missing retry_hint); added `, ..` per ADR-010 §Error-Construction Notation Canon Class 3."
  - "1.6 (P2A029-fix/2026-08-22): Two adjudications from adversary pass P2A-029. (1) P2A029-01 (HIGH) — fail-closed pagination overflow: Invariant 3 amended from ok-truncated (silent drop of discovered tools) to Err fail-closed, applying the CANONICAL PRINCIPLE no-silent-partial-result rule. PC1 clarified to reflect the abort path. EC-007 and TV-009 added for the >1000-page overflow scenario. New code: E-MCP-008 McpPaginationLimitExceeded (POLICY, broken), minted in error-taxonomy.md same burst. (2) P2A029-02 (MED) — unknown-server discovery error: PC9 added (authoritative full-form site for E-MCP-009 gate #33); EC-008 and TV-010 added. New code: E-MCP-009 McpServerNotConfigured (VAL, broken), minted in error-taxonomy.md same burst. Story-writer handoff: re-anchor S-2.10 AC-002 from stale E-MCP-002 to E-MCP-008; re-anchor S-2.10 EC-001 from stale E-MCP-004 to E-MCP-009."
  - "1.7 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.10 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.8 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.9 (P2A-044 F-06/2026-08-24): compressed-ordinal citations normalized to stable tags."
  - "1.10 (P2A-052 F-052-01/2026-08-25): ## VP Anchors section corrected from duplicated Story-Anchor story-ID to 'None' (BC has no Kani VP seed; see §Verification Properties)."
  - "1.11 (round-24/F-P2A104-01/2026-08-28): F-P2A104-01 [HIGH] — phantom `args_schema` accessor purged. §Description, {PC-003}, and {INV-001} referenced `args_schema` as if it were a field/method on `Arc<dyn DynTool>`, but `Arc<dyn DynTool>` (a trait object) has no fields and DynTool exposes no `args_schema`; the canonical schema accessor is `schema()`. Separately, the type was stated as `serde_json::Value` but `DynTool::schema()` returns `schemars::Schema`. Fix: all three sites rewritten to use `schema()` accessor and `schemars::Schema` return type; verbatim-passthrough intent preserved (schemars 1.0 `Schema` losslessly wraps the server-supplied `serde_json::Value`). Client-side mirror of server-side fix applied to S-2.11 §AC-026 (input_schema()→schema()). Story-writer propagation: S-2.10 AC-026 and test renamed `test_BC_2_09_001_schema_verbatim_passthrough`; `schemars` added to §Library."
origin: greenfield
priority: P1
subsystem: SS-09
capability: CAP-010
wave: 2
phase: 1a
red_gate: false
producer: product-owner
timestamp: 2026-08-28T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-010
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/mcp/behavioral-intent.md
  - .factory/semport/mcp/test-inventory.md
  - .factory/semport/mcp/rust-translation-strategy.md
input-hash: "cdbeeb3"
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
until all tools are retrieved. Each discovered MCP `Tool` is converted into an
`Arc<dyn DynTool>` via `convert_mcp_tool`; the resulting tool's `schema()` returns the
server's `tool.inputSchema` wrapped verbatim as a `schemars::Schema` — no synthesis,
no `schema_for!` re-derivation; an absent `inputSchema` yields an empty/`Value::Null`-backed
`Schema`. (`DynTool` is the object-safe dispatch seam for tool collections; direct
`dyn Tool` is non-object-safe per ADR-005 §Adjacent Trait Object-Safety Adjudications.)
If multiple servers are queried simultaneously (no `server_name` filter), the fan-out
runs concurrently via a `JoinSet` over per-server tasks, mirroring `asyncio.gather`
semantics.

## Preconditions

1. {PRE-001} A `MultiServerMcpClient` is constructed with at least one `Connection` entry
   (Stdio, SSE, StreamableHttp, or WebSocket).
2. {PRE-002} The named MCP servers are reachable at their configured transports.
3. {PRE-003} `get_tools(server_name: Option<&str>)` is called.

## Postconditions

1. {PC-001} For each targeted server, `list_tools()` is called with cursor following until either
   all pages are retrieved (cursor absent) or `MAX_ITERATIONS=1000` is reached; on the
   success path (≤1000 pages), all pages are consumed. If `MAX_ITERATIONS` is reached
   before the server signals completion, the call returns
   `Err(PregolyaError { component: MCP, category: POLICY, code: E-MCP-008, .. })`
   per EC-007; no partial tool list is returned (fail-closed).
2. {PC-002} Each `rmcp::model::Tool` from the server is converted into
   `Arc<dyn DynTool>` via `convert_mcp_tool`. (`DynTool` is the object-safe dispatch
   seam per ADR-005 §Adjacent Trait Object-Safety Adjudications; `convert_mcp_tool`
   returns `Arc<dyn DynTool>`.)
3. {PC-003} `convert_mcp_tool` produces an `Arc<dyn DynTool>` whose `schema()` returns
   the server's `tool.inputSchema` wrapped verbatim as a `schemars::Schema` — no
   synthesis / no `schema_for!` re-derivation; absent `inputSchema` → an
   empty/`Value::Null`-backed `Schema`.
4. {PC-004} When `server_name = Some("srv")`, only that server's tools are returned;
   tools from other servers are not included.
5. {PC-005} When `server_name = None`, tools from all registered servers are returned;
   the fan-out runs concurrently via `JoinSet` / `try_join_all`.
6. {PC-006} When `tool_name_prefix = true`, each tool name is prefixed `"{server_name}_{tool_name}"`.
   When `false`, tool names are used verbatim (name conflicts are caller's responsibility).
7. {PC-007} Transport failure connecting to any targeted server returns
   `Err(PregolyaError { component: MCP, category: TRANSPORT, code: E-MCP-002, .. })`.
8. {PC-008} A server that returns an empty tool list (`[]`) is not an error; an empty `Vec`
   is returned for that server.
9. {PC-009} When `server_name = Some(name)` and `name` is not in the configured server set,
   returns `Err(PregolyaError { component: MCP, category: VAL, code: E-MCP-009,
   message: "McpServerNotConfigured: no MCP server named 'name' is configured", .. })`
   (where `'name'` = the unknown server name from the caller's argument). This is the
   authoritative full-form site for E-MCP-009 gate #33; EC-008 and TV-010 PASS-ABBREV
   via this PC-009.

## Invariants

- {INV-001} The `schema()` of any converted tool returns a `schemars::Schema` wrapping the
  verbatim JSON-Schema from the MCP server's `tool.inputSchema`; it is never synthesized,
  transformed, or validated by pregolya-mcp.
- {INV-002} The session used for `list_tools` is created on-demand (RAII `OnDemand` session
  source) and torn down after the listing completes; no session is retained.
- {INV-003} `MAX_ITERATIONS=1000` is the hard pagination bound; if a server returns more than
  1,000 pages, the listing aborts and returns
  `Err(PregolyaError { component: MCP, category: POLICY, code: E-MCP-008,
  message: "McpPaginationLimitExceeded: server '<server>' exceeded MAX_ITERATIONS=1000
  pagination calls", .. })`. No partial tool list is returned; fail-closed semantics apply
  (silently returning a truncated set would drop discovered tools without signalling the
  caller — a silent-partial-result violation of the production-grade default).

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
**Expected behavior:** Returns `Err(PregolyaError { component: MCP, category: VAL,
code: E-MCP-003, message: "McpNotImplemented: MCP server '<server>' does not implement
'tools/list'", .. })`. The server contributes no tools to the registry. Treated as a fatal
failure for that server — same propagation pattern as EC-004 transport failure
(`JoinSet` aborts on first error in multi-server fan-out). The caller must reconfigure
or remove the non-implementing server.

### EC-007: Pagination overflow — server exceeds MAX_ITERATIONS=1000 (E-MCP-008)
**Scenario:** A reachable MCP server responds to repeated `list_tools` cursor requests
returning a non-null `nextCursor` on every response, never signalling completion. On the
1000th page retrieval, `MAX_ITERATIONS` is reached without the server returning a null
cursor.
**Expected behavior:** Returns `Err(PregolyaError { component: MCP, category: POLICY,
code: E-MCP-008, message: "McpPaginationLimitExceeded: server 'math' exceeded
MAX_ITERATIONS=1000 pagination calls", .. })`. No partial tool list is returned; any tools
discovered across the first 999 pages are discarded (fail-closed semantics — returning
a truncated set would silently drop tools, violating the production-grade no-silent-partial
rule). This is the authoritative full-form site for E-MCP-008 gate #33; TV-009
PASS-ABBREV via this EC-007.

### EC-008: Filter by unknown server name (E-MCP-009)
**Scenario:** `get_tools(Some("nonexistent_server"))` where `"nonexistent_server"` is
not in the configured server set (no `Connection` entry with that name exists).
**Expected behavior:** Returns `Err(PregolyaError { component: MCP, category: VAL,
code: E-MCP-009, message: "McpServerNotConfigured: no MCP server named
'nonexistent_server' is configured", .. })` per PC-009. No MCP network call is made;
the check is local against the configured server map. TV-010 PASS-ABBREV via PC-009.

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
| TV-009 | Server returns non-null cursor on 1000th `list_tools` response | `Err(E-MCP-008 McpPaginationLimitExceeded { server: "math" })` | EC-007: pagination overflow — fail-closed (PASS-ABBREV via EC-007) |
| TV-010 | `get_tools(Some("nonexistent_server"))` | `Err(E-MCP-009 McpServerNotConfigured { server: "nonexistent_server" })` | EC-008: unknown server filter (PASS-ABBREV via PC-009) |

## Verification Properties

_No Kani VP seed required for this BC. Unit tests and integration tests are sufficient._

## Related BCs

- BC-2.09.002 — depends on: tool handles produced here are routed for invocation in BC-2.09.002
- BC-2.09.003 — depends on: tool-result content from discovered tools is subject to DI-012 guardrail
- BC-2.09.004 — sibling: error handling policy for ToolException errors during invocation

## Architecture Anchors

- `pregolya-mcp/src/client.rs` — `MultiServerMcpClient::get_tools`
- `pregolya-mcp/src/tools.rs` — `convert_mcp_tool`, `_list_all_tools`
- `pregolya-mcp/src/sessions.rs` — `create_session`, `Connection` enum

## Story Anchor

S-2.10

## VP Anchors

None

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-010 |
| Capability Anchor Justification | CAP-010 ("MCP Tool Adapter") per capabilities-p1-p2.md §CAP-010 — this BC specifies the runtime discovery and registration of MCP tools, which is the first behavioral surface of the adapter: "Discover tools from MCP servers at runtime, present them to a graph as standard pregolya Tools" |
| L2 Domain Invariants | — |
| DEC Reference | — |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration, using in-process rmcp test servers) |
| Module | pregolya-mcp |
