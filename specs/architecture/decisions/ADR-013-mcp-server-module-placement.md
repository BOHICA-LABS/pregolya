---
document_type: adr
level: L3
adr_id: "013"
slug: mcp-server-module-placement
title: "MCP Server Module Placement in ferrochain-mcp (CAP-021)"
status: accepted
producer: architect
timestamp: 2026-07-15T00:00:00Z
version: "1.0"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D19, D20]
---

# ADR-013: MCP Server Module Placement in ferrochain-mcp

**Status:** Accepted — D19/D20 authority; orchestrator adoption of architect recommendation (pass-61-style)

## Context

CAP-021 (D20 capability addition) introduces an MCP **server** role for ferrochain: the
framework must be able to expose its own registered tools to external MCP clients, not only
consume external MCP servers as a client. This is distinct from the existing client-side
responsibilities of ferrochain-mcp (`mcp::client`, `mcp::adapter`, `mcp::discovery`,
`mcp::ingress`).

The architectural question: where does the `mcp::server` execution module live?

Two options exist:
1. A new dedicated crate (e.g., `ferrochain-mcp-server`)
2. A new module in the existing `ferrochain-mcp` crate (`mcp::server`)

Behavioral contracts BC-2.09.006 and BC-2.09.007 define the server-side contracts:
- BC-2.09.006: server-side tool exposure — accepting inbound tool-call requests and
  dispatching to registered ferrochain tools
- BC-2.09.007: response serialization — MCP-compliant serialization of tool results
  returned to external clients

Supported transports (from BC-2.09.006/007): stdio (standard MCP transport) and SSE
(Server-Sent Events, consistent with ferrochain-server's streaming model).

---

## Decision — Module Placement

**Chosen:** `mcp::server` module in the existing `ferrochain-mcp` crate
(`ferrochain-mcp/src/server.rs`).

**Module universe:** 34 → **35** (+1 MEDIUM execution row; MEDIUM tier consistent with
`mcp::client` and `mcp::adapter` classification — server-side inbound dispatch is
correctness-important but not a Kani VP target at v1).

**Crate roster:** 18 published crates — **unchanged**. `mcp::server` is a new module
within the existing `ferrochain-mcp` crate; no new crate is introduced.

**Transport support:** stdio + SSE, consistent with BC-2.09.006/007.

### Rationale

1. **Cohesion:** All MCP protocol handling (client, adapter, ingress, discovery, server)
   belongs in one crate. Client and server share MCP type definitions, serialization
   helpers, and transport abstractions. Splitting into two crates would require extracting
   a shared MCP types crate or duplicating protocol types — neither of which is warranted
   for the v1 scope.

2. **Roster freeze:** ADR-007 establishes the canonical 18-crate roster. Adding a 19th
   crate for a single server endpoint module would require a roster amendment with
   broad downstream impact (cargo workspace, CI, publish-all.sh, dependency-graph.md,
   system-overview.md). The benefit does not justify the churn.

3. **Precedent:** `ferrochain-server` (SS-12) hosts both `server::handlers` and
   `server::security` in the same crate. Similarly, `ferrochain-mcp` hosts both
   `mcp::client` (outbound) and `mcp::server` (inbound) — the name refers to the
   protocol family, not a single directionality.

4. **Criticality tier (MEDIUM):** `mcp::server` provides inbound tool-call dispatch but
   is not a security boundary in the same class as `path-guard` or `session-index`. It is
   analogous to `mcp::adapter` (outbound dispatch, MEDIUM) — correctness matters but Kani
   proof is not warranted at v1.

### Module Interface

```rust
// ferrochain-mcp/src/server.rs
pub struct McpServer { /* ... */ }

impl McpServer {
    /// Exposes the registered tool set to external MCP clients.
    /// Accepts inbound tool-call requests via stdio or SSE transport.
    pub async fn serve(
        &self,
        transport: McpTransport,
        registry: Arc<dyn ToolRegistry>,
    ) -> Result<(), FerrochainError>;
}

pub enum McpTransport {
    Stdio,
    Sse { port: u16, path: String },
}
```

The `ToolRegistry` is the same registry used by `mcp::adapter` for outbound dispatch,
ensuring the exposed tool set is always consistent with the registered tool set.

---

## Alternatives Considered

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| New `ferrochain-mcp-server` crate (#19) | **REJECT** | 18-crate roster is frozen per ADR-007; adding a 19th crate requires a roster amendment. Server module is cohesive with ferrochain-mcp — no technical reason to split. |
| `mcp::server` module in existing `ferrochain-mcp` crate | **ADOPT** | Roster unchanged; MCP protocol cohesion maintained; consistent with ADR-007 topology decisions. |

---

## Consequences

### Module-Decomposition Changes

`ferrochain-mcp` gains one new module row in module-decomposition.md:
- `mcp::server` (MEDIUM, SS-09): MCP server endpoint — exposes registered tools to
  external MCP clients; accepts inbound tool-call requests via stdio/SSE, dispatches to
  registered tools, returns serialized responses (CAP-021).

### Module-Criticality Changes

Module universe 34 → **35**:
- MEDIUM count 10 → 11 (+`mcp::server`)
- Final partition: 9 CRITICAL + 13 HIGH + 11 MEDIUM + 2 LOW = 35

### BC Anchors

| BC | Contract |
|----|---------|
| BC-2.09.006 | Server-side tool exposure: accept and dispatch inbound tool-call requests |
| BC-2.09.007 | Response serialization: MCP-compliant serialization of tool results |

### Attribution Note (F-P72-04)

Prior attribution of `mcp::server` to ADR-012 in module-decomposition.md (v1.6) and
BC-2.09.006 was incorrect — ADR-012 contains no MCP server content. The correct
authority is this ADR (ADR-013). Attribution in module-decomposition.md is corrected
in v1.7. BC-2.09.006 attribution correction is deferred to PO (spec-owner of BC files).

---

## Changelog

| Version | Date | Author | References | Summary |
|---------|------|--------|------------|---------|
| 1.0 | 2026-07-15 | architect | D19, D20, CAP-021, F-P72-04 | Initial decision: mcp::server module in ferrochain-mcp (not a new crate); MEDIUM tier; stdio+SSE transports; universe 34→35; corrects false ADR-012 attribution in module-decomposition.md. |
