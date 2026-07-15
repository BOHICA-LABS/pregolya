---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.005
version: "1.1"
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
vp_id: VP-005
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-010
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/mcp/behavioral-intent.md
  - .factory/semport/mcp/test-inventory.md
  - .factory/semport/mcp/rust-translation-strategy.md
input-hash: "35288e587773df873fde5dc1b952d35dd075a99140fba82c703587e4b87713da"
changelog:
  - "1.0 (initial): base BC authored."
  - "1.1 (ADV-P1D-PASS-46): OBS-P46-1 — align VP-005 phrasing to sibling BC-2.09.004 VP-004 convention. 'compile+pass but network assertion fails' → 'compile+fail — test compiles and runs but the network-I/O assertion inside it fails'. Same semantic; consistent phrasing across both R11 Red Gate BCs."
---

# BC-2.09.005: MultiServerMcpClient Holds No Live Connections (Red Gate — R11)

> **Red Gate test required.** A test for this contract must compile and FAIL
> (i.e., the behavior is demonstrably absent) before the implementation of
> `MultiServerMcpClient` begins. This is a D17-Q9 Phase-1 mandatory Red Gate
> per R11: the upstream langchain-mcp-adapters test suite has NO lock test
> anywhere for `MultiServerMCPClient.__aenter__` raising `NotImplementedError`
> (the behavior exists in `MultiServerMCPClient.__aenter__` but is untested per
> semport/mcp/test-inventory.md `[validation-exhaustive]` note).
> The test must be authored first and checked into the repository in a failing state.

## Description

`MultiServerMcpClient` is a **configuration-only container** — it holds connection
configs and option flags, but it holds NO live network connections at any point in its
lifetime. This is the Rust translation of the Python contract where
`MultiServerMCPClient.__aenter__`/`__aexit__` explicitly raise `NotImplementedError`
(removed in 0.1.0 to block the `async with client:` usage pattern). In Rust, the
equivalent guarantee is: the struct has no `Drop` impl performing network teardown,
implements no "close all connections" or "shutdown" method, and is freely movable and
cloneable without connection state. Sessions are always created per-call (RAII,
`SessionSource::OnDemand`) and are never stored in the struct.

## Preconditions

1. A `MultiServerMcpClient` is constructed with a `HashMap<String, Connection>` of
   connection configs.

## Postconditions

1. Immediately after construction, no network connections are open. No TCP sockets,
   no spawned stdio processes, and no HTTP sessions are alive.
2. `MultiServerMcpClient` does NOT implement `Drop` with any network teardown behavior.
3. `MultiServerMcpClient` does NOT expose any `close()`, `shutdown()`, `disconnect()`,
   or `connect()` method at the public API level.
4. The struct is `Send + Sync + Clone` — cloning it produces an identical config
   container with zero network side effects.
5. When `session("server_name")` is called, it returns an RAII-scoped session handle
   (`McpSessionGuard`) that creates a new connection on entry and drops it on exit.
   The `McpSessionGuard` is NOT stored in `MultiServerMcpClient`.
6. A `MultiServerMcpClient` instance that is dropped without calling any methods
   causes ZERO network I/O and ZERO async executor interaction.
7. Attempting to use `MultiServerMcpClient` as a `Drop`-based scoped connection manager
   (i.e., storing a live connection in it and relying on `drop()` to close it) is
   structurally impossible: the type system prevents it.

## Invariants

- DI-014: No silent behavior is hidden in the lifecycle of this struct. Its construction
  and destruction are pure and side-effect-free.
- The struct is a value type (config bag), not a resource type (connection handle).
  The distinction is load-bearing: callers should not wrap it in `Arc<Mutex<...>>`.
- Every network interaction goes through `session()` or `get_tools()`, both of which
  create fresh sessions per call.

## Edge Cases

### EC-001: Struct dropped without any method calls — Red Gate vector
**Scenario:** `let client = MultiServerMcpClient::new(connections); drop(client);`
**Expected behavior:** Zero network I/O. Zero async tasks spawned. The drop is
a no-op from the network's perspective.
**This is the Red Gate vector** — a test that instruments network I/O and asserts
zero calls on construction+drop must FAIL (i.e., the struct accidentally initiates
a connection) before implementation.

### EC-002: Clone produces independent config container
**Scenario:** `let c2 = client.clone(); /* use c2 for get_tools, don't touch client */`
**Expected behavior:** `c2.get_tools(None)` works normally. `client` is unaffected.
The clone is structurally independent — no shared internal state.

### EC-003: Parallel get_tools calls on same client
**Scenario:** Two `tokio::spawn` tasks both call `client.get_tools(None)` concurrently.
**Expected behavior:** Each task creates its own sessions independently (`Send + Sync`
guarantees no data race). The tasks do not share session state.

### EC-004: session() guard dropped before next call
**Scenario:** `{ let _guard = client.session("math").await?; } client.session("math").await?;`
**Expected behavior:** First session is created and torn down in the first block.
Second session is a fresh creation. No connection is reused.

### EC-005: Arc<MultiServerMcpClient> (discouraged but legal)
**Scenario:** Caller wraps client in `Arc` to share across tasks.
**Expected behavior:** Works correctly — each task calling `get_tools` or `session`
creates its own per-call sessions. The `Arc` shares only the config map (no connection state).
Note: callers are better served by cloning (which is cheap) than by Arc-wrapping.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `MultiServerMcpClient::new(conns); drop(client)` | Zero network I/O, zero async spawns | **Red Gate vector — must FAIL before implementation** |
| TV-002 | `client.clone()` | Returns new independent config container; no network side effect | Clone is side-effect-free |
| TV-003 | `session("math")` called twice sequentially | Two separate connections created and torn down; no reuse | Per-call session lifecycle |
| TV-004 | Concurrent `get_tools(None)` from two tasks | Both complete independently; no panic, no data race | `Send + Sync` |
| TV-005 | Caller accesses `client.close()` | Compile error — method does not exist on the type | No shutdown method |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-005 | `MultiServerMcpClient` construction and drop cause no network I/O | Red Gate test (compile+fail — test compiles and runs but the network-I/O assertion inside it fails), then unit test post-implementation | Phase 3 (integration) (Red Gate authored Phase 1 per D17-Q9) |

## Related BCs

- BC-2.09.001 — depends on: `get_tools` is the primary method on this type; its session-per-call behavior flows from this BC
- BC-2.09.004 — sibling: both are R11 Red Gates covering the two untested MCP contract voids

## Architecture Anchors

- `ferrochain-mcp/src/client.rs` — `MultiServerMcpClient` struct definition (no `Drop` impl)
- `ferrochain-mcp/src/sessions.rs` — `McpSessionGuard` RAII type (the scoped resource, NOT the client)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-005

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-010 |
| Capability Anchor Justification | CAP-010 ("MCP Tool Adapter") per capabilities-p1-p2.md §CAP-010 — this BC specifies the session lifecycle ownership model of the multi-server client, which is the core design fact of the adapter (connection-on-demand, not connection-at-construction) and is an R11 Red Gate test void per semport/mcp/test-inventory.md |
| L2 Domain Invariants | DI-014 (Error Propagation (No Silent Swallowing) — the struct's lifecycle must not have hidden network side effects; no connection is opened or closed silently) |
| DEC Reference | — |
| Risk Source | R11 (upstream MCP test voids: `MultiServerMCPClient.__aenter__` NotImplementedError contract untested) |
| D17 Commitment | D17-Q9 — R11 Red Gate test required (`MultiServerMCPClient.__aenter__` NotImplementedError has no lock test in the upstream test suite) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), Red Gate |
| Module | [architect to assign — ferrochain-mcp] |
