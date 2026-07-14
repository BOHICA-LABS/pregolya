---
document_type: adr
level: L3
adr_id: "008"
slug: proc-macro-attributes
title: "Proc-Macro Attributes: #[tool], #[entrypoint], #[task] (D17-Q6)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
gate: ADR-004
gate_note: "Gated on ADR-004 (serde/schemars). ADR-008 may not finalize until ADR-004 is accepted. The schemars derive is required for #[tool] schema generation."
traces_to: ARCH-INDEX.md
decisions: [D5, D17]
supersedes: []
---

# ADR-008: Proc-Macro Attributes

**Status:** Accepted — ADR-004 gate satisfied (D5 ✓); proc-macro BCs unblocked

## Context

D17-Q6: proc-macro attributes (#[tool], #[entrypoint], #[task]) are Phase 1/2 work
gated on D5 ADR resolution. ADR-004 (schemars) is the D5 gate; ADR-004 is accepted,
resolving that gate. This ADR specifies the proc-macro design now that the gate is cleared.

No proc-macro BCs are in the current BC authoring plan. The product-owner must explicitly
author or formally defer proc-macro BCs (#[tool], #[entrypoint], #[task]) before
Phase-2 story decomposition begins (see PRD OQR-4).

## Scope

`#[tool]` — converts a Rust async function or struct impl into a `Tool` implementor;
derives JSON Schema from parameter types via schemars.

`#[entrypoint]` — marks a `StateGraph` node as the start node for `START` edge wiring.

`#[task]` — marks an async function as a graph task; generates the task registration boilerplate.

## Preliminary Design

**`#[tool]` example:**

```rust
#[ferrochain::tool(name = "search_web", description = "Searches the web")]
async fn search_web(query: String, max_results: u32) -> Result<String, FerrochainError> {
    // implementation
}
// expands to: impl Tool for SearchWebTool { ... derive JsonSchema for args ... }
```

Requires: `schemars::JsonSchema` bound on all parameter types (ADR-004).

## Decision: Adopt proc-macro crate (ADR-004 accepted — gate satisfied)

ADR-004 accepted schemars (D5 gate resolved). Proceed with proc-macro crate:
- New crate: `ferrochain-macros` (proc-macro crate; not user-facing; re-exported from ferrochain-core)
- Phase: late Phase 1 or Phase 2 depending on BC authoring plan backlog

Manual `impl Tool` pattern remains valid for users who do not want the proc-macro
convenience layer. The macro is additive.

## Consequences

- `ferrochain-macros` proc-macro crate added to workspace if ADR-004 accepted.
- Phase-1b BC additions for `#[tool]`, `#[entrypoint]`, `#[task]` routed through product-owner after this ADR finalizes.
- xtask linting may need updating to recognize proc-macro-expanded code.
