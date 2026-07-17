---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.004
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
red_gate: true
red_gate_source: R11
vp_id: VP-004
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-010
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/mcp/behavioral-intent.md
  - .factory/semport/mcp/test-inventory.md
  - .factory/semport/mcp/rust-translation-strategy.md
input-hash: "41d734f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.09.004: MCP Bare ToolException Re-Raise Preserving Type Identity (Red Gate — R11)

> **Red Gate test required.** A test for this contract must compile and FAIL
> (i.e., the behavior is demonstrably absent) before the implementation of the
> `_handle_mcp_tool_error` path in `ferrochain-mcp` begins. This is a D17-Q9
> Phase-1 mandatory Red Gate per R11: the upstream langchain-mcp-adapters test
> suite has no dedicated lock test for the bare ToolException re-raise path
> (described in the `_handle_mcp_tool_error` docstring but not covered by any
> test per semport/mcp/test-inventory.md `[validation-exhaustive]` note).
> The test must be authored first and checked into the repository in a failing state.

## Description

The error-handling taxonomy in `ferrochain-mcp` discriminates between two classes
of MCP tool errors: (1) `McpError::ToolExecution` — an `isError=true` result
from the MCP server, which is governed by the `handle_tool_errors` flag; and (2)
a bare `ToolException` raised by the tool machinery outside the `isError` path
(e.g., by the rmcp SDK itself, or by an interceptor). When a bare `ToolException`
is raised, its error type identity MUST be preserved in the propagated
`FerrochainError` — the caller receives `FerrochainError { component: MCP,
category: TOOL, code: E-MCP-001 }`, not a generic `McpError::Internal` or opaque
error. This preserves the Python contract where a bare `ToolException`'s type
identity is retained when re-raised through `_handle_mcp_tool_error`.

## Preconditions

1. A MCP tool call is in progress via `McpTool::run`.
2. The tool machinery (rmcp SDK, interceptor chain, or connection lifecycle)
   raises a `ToolException` (or its Rust equivalent: `McpError::ToolExecution`
   raised outside the `isError=true` content-conversion path).
3. The exception is NOT an `isError=true` `CallToolResult` (that path is governed
   by `handle_tool_errors` per BC-2.09.002).
4. The `handle_tool_errors` flag value is irrelevant to this path.

## Postconditions

1. The `ToolException` type identity is preserved in the propagated error.
   The caller observes `Err(FerrochainError { component: MCP, category: TOOL,
   code: E-MCP-001, message: "ToolException: MCP server '<server>' raised
   ToolException for tool '<tool>': <message>" })`.
2. The error is NOT wrapped in `McpError::Transport` or `McpError::Internal`.
3. The `handle_tool_errors` flag does NOT suppress this path; the error always
   propagates as `Err(...)`.
4. The `FerrochainError::source` field retains the original `McpError::ToolExecution`
   for downstream introspection.

## Invariants

- DI-014: Validation failures (including tool errors) propagate as `Err(FerrochainError)`.
  No public API returns `None` or empty to represent this error.
- The bare `ToolException` path and the `isError=true` path are mutually exclusive:
  the `isError=true` path produces either a `ToolMessage{status: Error}` or
  `Err(McpError::ToolExecution)` depending on the flag; the bare path always produces
  `Err(FerrochainError { category: TOOL })`.
- Error type identity preservation is testable: a test can assert that
  `err.code() == "E-MCP-001"` and `err.category() == Category::Tool`.

## Edge Cases

### EC-001: Bare ToolException with non-empty message (Red Gate vector)
**Scenario:** The rmcp session raises a `ToolException("unauthorized: tool requires auth")`.
**Expected behavior:** The caller receives
`Err(FerrochainError { code: E-MCP-001, category: TOOL, message: "ToolException: MCP server 'fs' raised ToolException for tool 'read_file': unauthorized: tool requires auth" })`.
**This is the Red Gate vector** — this test must compile and FAIL (i.e., the error
is either swallowed, mapped to INTERNAL, or the code is not E-MCP-001) before implementation.

### EC-002: Bare ToolException with empty message
**Scenario:** `ToolException("")` is raised.
**Expected behavior:** `Err(FerrochainError { code: E-MCP-001, message: "ToolException: MCP server '<srv>' raised ToolException for tool '<tool>': (no message)" })`.
The empty message is replaced with the sentinel string `"(no message)"` — no panic,
no empty message in the error struct.

### EC-003: handle_tool_errors=false, bare ToolException
**Scenario:** `handle_tool_errors = false`; bare `ToolException` raised.
**Expected behavior:** Identical to EC-001 — the bare ToolException path ignores the
flag and always propagates as `Err(FerrochainError { code: E-MCP-001 })`.

### EC-004: Distinction from isError=true path
**Scenario:** `isError = true` result returned from MCP server (not a bare exception).
**Expected behavior:** Per BC-2.09.002: with `handle_tool_errors=true` → `Ok(ToolMessage{status:Error})`;
with `false` → `Err(McpError::ToolExecution)`. This path is DISTINCT from the
bare-ToolException path. A test for this BC MUST NOT accidentally pass by triggering
the isError path.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | rmcp raises `ToolException("auth failure")`, handle_tool_errors=true | `Err(FerrochainError { code: "E-MCP-001", category: TOOL })` | **Red Gate vector — must FAIL before implementation** |
| TV-002 | Same, handle_tool_errors=false | Identical `Err(FerrochainError { code: "E-MCP-001", ... })` — flag ignored | Flag irrelevance |
| TV-003 | `ToolException("")` | `Err(...)` with message `"...: (no message)"` | Empty message sentinel |
| TV-004 | `isError=true` (not bare ToolException) | `Ok(ToolMessage{status:Error,...})` or `Err(McpError::ToolExecution)` per BC-2.09.002 | Distinct path — not this BC |
| TV-005 | FerrochainError source chain | `err.source()` == `McpError::ToolExecution { ... }` | Type identity in source chain |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-004 | Bare ToolException propagates as E-MCP-001 TOOL category — flag does not suppress | Red Gate test (compile+fail), then unit test post-implementation | Phase 3 (integration) (Red Gate authored Phase 1 per D17-Q9) |

## Related BCs

- BC-2.09.002 — sibling: `isError=true` path is governed by `handle_tool_errors` flag; this BC is the distinct bare-exception path
- BC-2.09.005 — sibling: both are R11 Red Gates; together they cover both untested MCP contract voids

## Architecture Anchors

- `ferrochain-mcp/src/tools.rs` — `_handle_mcp_tool_error` (bare ToolException arm)
- `ferrochain-core/src/error.rs` — `FerrochainError { component: MCP, category: TOOL, code: E-MCP-001 }`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-004

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-010 |
| Capability Anchor Justification | CAP-010 ("MCP Tool Adapter") per capabilities-p1-p2.md §CAP-010 — this BC specifies error type identity preservation for the bare ToolException path, which is part of the adapter's tool-result routing behavior and is called out explicitly as an untested upstream void (R11) requiring a Red Gate test |
| L2 Domain Invariants | DI-014 (Error Propagation (No Silent Swallowing)) |
| DEC Reference | DEC-012 (MCP Bare ToolException Re-Raise — R11 upstream MCP test void) |
| Risk Source | R11 (upstream MCP test voids: bare ToolException re-raise path untested; `__aenter__` NotImplementedError contract untested) |
| D17 Commitment | D17-Q9 — R11 Red Gate test required (bare ToolException re-raise has no upstream lock test) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), Red Gate |
| Module | [architect to assign — ferrochain-mcp] |
