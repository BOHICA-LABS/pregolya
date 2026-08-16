---
document_type: adr
level: L3
adr_id: "008"
slug: proc-macro-attributes
title: "Proc-Macro Attributes: #[tool], #[entrypoint], #[task] (D17-Q6)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
date: "2026-07-14"
subsystems_affected: ["all"]
supersedes: []
superseded_by: null
phase: 1b
gate: ADR-004
gate_note: "Gated on ADR-004 (serde/schemars). ADR-008 may not finalize until ADR-004 is accepted. The schemars derive is required for #[tool] schema generation."
traces_to: ARCH-INDEX.md
decisions: [D5, D17]
version: "1.2"
changelog:
  - "1.2 (burst-288/F-P177-LOW-date/2026-08-15): Add missing frontmatter fields (date, subsystems_affected, superseded_by); add Rationale, Alternatives Considered, Source / Origin sections per ADR template (LOW finding: date boundary conditions)."
  - "1.1 (FIX-BURST-273/F-P171a-09/2026-07-25): Add Decision 2 — `action_risk` attribute parameter, emitted absolute path, and proc-macro hygiene rule. At original authoring, no `action_risk` attribute existed; ADR-018 Decision 6 and ADR-020 Decision 3 subsequently introduced the attribute (D23). Decision 2 records the emitted-path contract (::pregolya_core::action_risk::ActionRisk) so Phase 3 implementers do not re-derive it. Also introduce version/changelog frontmatter fields absent at original authoring."
  - "1.0 (D17-Q6/2026-07-14): Initial ADR — proc-macro attributes adopted; gate: ADR-004 accepted."
---

# ADR-008: Proc-Macro Attributes

**Status:** Accepted — ADR-004 gate satisfied (D5 ✓); proc-macro BCs unblocked

## Context

D17-Q6: proc-macro attributes (#[tool], #[entrypoint], #[task]) are Phase 1/2 work
gated on D5 ADR resolution. ADR-004 (schemars) is the D5 gate; ADR-004 is accepted,
resolving that gate. This ADR specifies the proc-macro design now that the gate is cleared.

~~No proc-macro BCs are in the current BC authoring plan.~~ **Stale — superseded by
Phase 1b authoring.** BC-2.08.010 (#[tool] schema generation), BC-2.08.011 (#[entrypoint]
start-node wiring), and BC-2.08.012 (#[task] boilerplate) are authored and **active** as of
Phase 1b. The product-owner has fulfilled the formal-defer obligation noted in PRD OQR-4.
Phase-2 story decomposition may reference BC-2.08.010–012 without a gate. (ADV-P1D-PASS-3 F-P3-05)

## Scope

`#[tool]` — converts a Rust async function or struct impl into a `Tool` implementor;
derives JSON Schema from parameter types via schemars.

`#[entrypoint]` — marks a `StateGraph` node as the start node for `START` edge wiring.

`#[task]` — marks an async function as a graph task; generates the task registration boilerplate.

## Preliminary Design

**`#[tool]` example:**

```rust
#[pregolya::tool(name = "search_web", description = "Searches the web")]
async fn search_web(query: String, max_results: u32) -> Result<String, PregolyaError> {
    // implementation
}
// expands to: impl Tool for SearchWebTool { ... derive JsonSchema for args ... }
```

Requires: `schemars::JsonSchema` bound on all parameter types (ADR-004).

## Decision: Adopt proc-macro crate (ADR-004 accepted — gate satisfied)

ADR-004 accepted schemars (D5 gate resolved). Proceed with proc-macro crate:
- New crate: `pregolya-macros` (proc-macro crate; not user-facing; re-exported from pregolya-core)
- Phase: late Phase 1 or Phase 2 depending on BC authoring plan backlog

Manual `impl Tool` pattern remains valid for users who do not want the proc-macro
convenience layer. The macro is additive.

## Decision 2 — `action_risk` Attribute Parameter and Emitted Absolute Path

The `#[tool]` proc-macro gains an optional `action_risk` attribute parameter introduced by
ADR-018 Decision 6 and ADR-020 Decision 3 (D23):

```rust
#[pregolya::tool(name = "bash", action_risk = ActionRisk::High, description = "...")]
async fn bash(...) -> ...
```

**Emitted absolute path:** The macro expansion MUST use the fully-qualified path
`::pregolya_core::action_risk::ActionRisk` when emitting `action_risk` values into the
annotated crate's token stream. The expansion must NOT assume that `ActionRisk` is in scope
in the annotated crate — proc-macro expansions inject into the caller's scope, not the
macro crate's scope. The caller may not have `ActionRisk` in its use declarations.

**Hygiene rule:** All emitted variant references take the form
`::pregolya_core::action_risk::ActionRisk::<Variant>` (e.g.,
`::pregolya_core::action_risk::ActionRisk::High`). This is safe because every crate that
can use `#[tool]` must already depend on `pregolya-core` (which provides the `Tool` trait
and `PregolyaError`); the absolute path is always resolvable.

**Absent attribute:** If `action_risk = ...` is omitted from `#[tool(…)]`, the expansion
populates `ToolCallPreview.action_risk` as `None` at dispatch time (ADR-018 Decision 6).
The macro must not emit a default variant — the absence vs presence distinction is load-bearing
for risk-tier visibility in `ToolCallPreview`.

**BC-2.08.010 obligation:** The `action_risk` parameter was added to BC-2.08.010 (amended
burst-229). The postcondition that the `action_risk` field is correctly populated in
`ToolCallPreview` at dispatch time is covered by BC-2.08.010 §Postconditions.

## Rationale

- D17-Q6 mandates proc-macro ergonomics for tool registration (`#[tool]`), graph entrypoint wiring (`#[entrypoint]`), and task registration (`#[task]`).
- The proc-macro crate (`pregolya-macros`) is a standard Rust pattern for deriving boilerplate from attribute annotations; no other mechanism provides compile-time schema generation from user-defined argument types.
- ADR-004 accepted schemars as the schema generation backend; `#[tool]` derives `schemars::JsonSchema` on the annotated struct, so ADR-008 is unblocked only after ADR-004 is accepted.
- Manual `impl Tool` pattern remains valid for users who do not want proc-macro ergonomics — `#[tool]` is additive, not required.

## Consequences

- `pregolya-macros` proc-macro crate added to workspace (ADR-004 accepted — gate satisfied).
- Phase-1b BC additions for `#[tool]`, `#[entrypoint]`, `#[task]` routed through product-owner after this ADR finalizes.
- xtask linting may need updating to recognize proc-macro-expanded code.
- Decision 2 (D23): `#[tool]` macro implementer must use `::pregolya_core::action_risk::ActionRisk::<Variant>` in all emitted tokens for `action_risk`; no bare `ActionRisk::High` in the expansion output.

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Manual `impl Tool` only (no proc-macro) | Valid ergonomically but D17-Q6 mandates proc-macro support; the two patterns coexist (additive). |
| build.rs code generation | Harder to compose with serde/schemars derives; lacks attribute syntax ergonomics; more complex for users. |
| Derive macros only (no attribute macros) | Derive macros cannot annotate individual functions; `#[tool]` must annotate async `fn` signatures, which requires an attribute macro. |

## Source / Origin

- **Decision mandate:** D17-Q6 — proc-macro attribute design gated on D5 (ADR-004 accepted).
- **Gate resolution:** ADR-004 accepted (schemars 1.x) satisfies the D5 gate; ADR-008 finalizes.
- **Authoring context:** D5/D17 design session (2026-07-14); pregolya Phase 1a.
