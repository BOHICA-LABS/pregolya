---
document_type: adr
level: L3
adr_id: "013"
slug: mcp-server-module-placement
title: "MCP Server Module Placement in pregolya-mcp (CAP-021)"
status: accepted
producer: architect
timestamp: 2026-07-15T00:00:00Z
date: "2026-07-15"
subsystems_affected: ["SS-09"]
supersedes: []
superseded_by: null
version: "1.6"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D19, D20]
changelog:
  - "1.6 (INVESTIGATE-RECONCILE/2026-08-21): Rename `mcp::adapter` → `mcp::exception` across all live references (module listing, criticality tier comparison, ToolRegistry shared-registry reference). Story S-2.10 creates no `adapter.rs`; the outbound exception handling lives in `mcp::exception`. ToolRegistry shared-registry reference (line 129) updated to `mcp::client` (correct consumer of the registry for outbound dispatch). Decision and Rationale are unchanged; this is a canonical module name propagation."
  - "1.5 (burst-288/F-P177-LOW-date/2026-08-15): Add missing frontmatter fields (date, subsystems_affected, superseded_by); add Rationale, Source / Origin sections per ADR template (LOW finding: date boundary conditions)."
  - "1.4 (FIX-BURST-276/F-P173-706/2026-07-27): Forward-amend all three 18-crate roster references to 21-crate: (1) Decision crate-roster count; (2) Rationale item 2 roster-freeze statement; (3) Alternatives Considered table reject rationale. Update \"19th crate\" references to \"22nd crate\" (current roster is 21; a new mcp-server crate would be #22). Add forward-amendment blockquote after Decision crate-roster statement. The \"no new crate\" decision holds unchanged; mcp::server remains in pregolya-mcp. Roster expanded from 18 to 21 by D21+D23 — see ARCH-INDEX.md §Canonical Crate Roster."
  - "1.3 (FIX-BURST-274/TD-VSDD-091/2026-07-26): De-pin BC version citation in Attribution Note: `BC-2.09.006 v1.1` → `BC-2.09.006` per TD-VSDD-091 BC-pin variant. Completes the intended burst-262 de-pin fix where only the frontmatter version was bumped (1.2→1.3) without applying the body change."
  - "1.2 (F-P83-03/OBS-P83-B/2026-07-15): Correct BC-2.09.006/007 responsibility swap: BC-2.09.006 = tools/list advertisement (discovery only, exposes tool definitions); BC-2.09.007 = tools/call invocation (accept + dispatch + serialize). Fix Context description and BC Anchors table. Annotate Attribution Note: BC-2.09.006 v1.1 completed. Widen behavioral authority note to name both BC-2.09.006 and BC-2.09.007 as authoritative signature carriers; update inline comment to BC-2.09.006/007."
  - "1.1 (OBS-P77-A/BC-2.09.006/2026-07-15): Reconcile Module Interface sketch to BC-2.09.006 canonical shapes: rename McpTransport→McpServerTransport; serve(&self, transport, registry)→start(config: McpServerConfig); return type ()→McpServerHandle; Sse { port, path }→Sse { bind_addr: SocketAddr }. Add behavioral authority note (BC wins over ADR sketch)."
  - "1.0 (D19/D20/CAP-021/F-P72-04/2026-07-15): Initial decision: mcp::server module in pregolya-mcp (not a new crate); MEDIUM tier; stdio+SSE transports; universe 34→35; corrects false ADR-012 attribution in module-decomposition.md."
---

# ADR-013: MCP Server Module Placement in pregolya-mcp

**Status:** Accepted — D19/D20 authority; orchestrator adoption of architect recommendation (pass-61-style)

## Context

CAP-021 (D20 capability addition) introduces an MCP **server** role for pregolya: the
framework must be able to expose its own registered tools to external MCP clients, not only
consume external MCP servers as a client. This is distinct from the existing client-side
responsibilities of pregolya-mcp (`mcp::client`, `mcp::exception`, `mcp::discovery`,
`mcp::ingress`).

The architectural question: where does the `mcp::server` execution module live?

Two options exist:
1. A new dedicated crate (e.g., `pregolya-mcp-server`)
2. A new module in the existing `pregolya-mcp` crate (`mcp::server`)

Behavioral contracts BC-2.09.006 and BC-2.09.007 define the server-side contracts:
- BC-2.09.006: tools/list advertisement and discovery — exposing registered tool
  definitions to external MCP clients (discovery only; does not dispatch requests)
- BC-2.09.007: tools/call invocation — accepting inbound tool-call requests,
  dispatching to registered pregolya tools, and MCP-compliant serialization of results

Supported transports (from BC-2.09.006/007): stdio (standard MCP transport) and SSE
(Server-Sent Events, consistent with pregolya-server's streaming model).

---

## Decision

**Chosen:** `mcp::server` module in the existing `pregolya-mcp` crate
(`pregolya-mcp/src/server.rs`).

**Module universe:** 34 → **35** (+1 MEDIUM execution row; MEDIUM tier consistent with
`mcp::client` and `mcp::exception` classification — server-side inbound dispatch is
correctness-important but not a Kani VP target at v1).

**Crate roster:** 21 published crates — **unchanged by ADR-013**. `mcp::server` is a
new module within the existing `pregolya-mcp` crate; no new crate is introduced.

> **Forward Amendment (FIX-BURST-276, 2026-07-27):** The roster at ADR-013 acceptance
> time was 18 published crates. The roster has since expanded to **21 published crates**
> by D21 (+pregolya-prompts [#19], +pregolya-vectorstores [#20]) and D23
> (+pregolya-tools [#21]). If a new `pregolya-mcp-server` crate were added today, it
> would be crate #22 (not #19). The "no new crate" decision holds under the 21-crate
> roster. **See ARCH-INDEX.md §Canonical Crate Roster as the authoritative source of truth.**

**Transport support:** stdio + SSE, consistent with BC-2.09.006/007.

## Rationale

1. **Cohesion:** All MCP protocol handling (client, exception, ingress, discovery, server)
   belongs in one crate. Client and server share MCP type definitions, serialization
   helpers, and transport abstractions. Splitting into two crates would require extracting
   a shared MCP types crate or duplicating protocol types — neither of which is warranted
   for the v1 scope.

2. **Roster currency:** ADR-007 establishes the canonical crate roster (currently 21 crates;
   expanded from 18 by D21+D23). Adding a 22nd crate for a single server endpoint module
   would require a roster amendment with broad downstream impact (cargo workspace, CI,
   publish-all.sh, dependency-graph.md, system-overview.md). The benefit does not justify
   the churn.

3. **Precedent:** `pregolya-server` (SS-12) hosts both `server::handlers` and
   `server::security` in the same crate. Similarly, `pregolya-mcp` hosts both
   `mcp::client` (outbound) and `mcp::server` (inbound) — the name refers to the
   protocol family, not a single directionality.

4. **Criticality tier (MEDIUM):** `mcp::server` provides inbound tool-call dispatch but
   is not a security boundary in the same class as `path-guard` or `session-index`. It is
   analogous to `mcp::exception` (error-detection in outbound path, MEDIUM) — correctness matters but Kani
   proof is not warranted at v1.

### Module Interface

> **Behavioral authority note:** BC-2.09.006 and BC-2.09.007 are the authoritative signature carriers for
> `McpServer`. Interface definitions in BCs and `interface-definitions.md` take precedence
> over ADR sketches per the behavioral authority rule. The sketch below is reconciled to
> BC-2.09.006's canonical shapes and is kept for architectural context only.

```rust
// pregolya-mcp/src/server.rs
pub struct McpServer { /* ... */ }

impl McpServer {
    /// Exposes the registered tool set to external MCP clients.
    /// Accepts inbound tool-call requests via stdio or SSE transport.
    /// Configuration (transport selection, bind address, etc.) is supplied via
    /// McpServerConfig; returns a McpServerHandle for lifecycle management.
    /// Canonical signature per BC-2.09.006/007.
    pub async fn start(
        config: McpServerConfig,
    ) -> Result<McpServerHandle, PregolyaError>;
}

pub enum McpServerTransport {
    Stdio,
    Sse { bind_addr: SocketAddr },
}
```

The `ToolRegistry` is the same registry used by `mcp::client` for outbound dispatch,
ensuring the exposed tool set is always consistent with the registered tool set.
`McpServerConfig` wraps `McpServerTransport` alongside any additional server-lifecycle
options; `McpServerHandle` provides a handle for graceful shutdown and health querying.

---

## Alternatives Considered

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| New `pregolya-mcp-server` crate (#22 under current 21-crate roster) | **REJECT** | 21-crate roster is current per ADR-007 (expanded from 18 by D21+D23); adding a 22nd crate requires a roster amendment. Server module is cohesive with pregolya-mcp — no technical reason to split. |
| `mcp::server` module in existing `pregolya-mcp` crate | **ADOPT** | Roster unchanged; MCP protocol cohesion maintained; consistent with ADR-007 topology decisions. |

---

## Consequences

### Module-Decomposition Changes

`pregolya-mcp` gains one new module row in module-decomposition.md:
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
| BC-2.09.006 | Tool advertisement (tools/list): expose registered tool definitions to external MCP clients |
| BC-2.09.007 | Tool invocation (tools/call): accept and dispatch inbound tool-call requests; MCP-compliant serialization of results |

### Attribution Note (F-P72-04)

Prior attribution of `mcp::server` to ADR-012 in module-decomposition.md (v1.6) and
BC-2.09.006 was incorrect — ADR-012 contains no MCP server content. The correct
authority is this ADR (ADR-013). Attribution in module-decomposition.md is corrected
in v1.7. BC-2.09.006 attribution correction is deferred to PO (spec-owner of BC files). [completed — BC-2.09.006]

## Source / Origin

- **Decision mandate:** D19/D20 — CAP-021 MCP server role placement; CAP-020 MCP client/adapter.
- **BC traceability:** BC-2.09.006 (tools/list advertisement), BC-2.09.007 (tools/call invocation).
- **Authoring context:** D19/D20 design session (2026-07-15); pregolya Phase 1a (F-P72-04 attribution correction).

---

