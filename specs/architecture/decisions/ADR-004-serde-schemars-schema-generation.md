---
document_type: adr
level: L3
adr_id: "004"
slug: serde-schemars-schema-generation
title: "Schema Generation: serde + schemars (pydantic→serde/schemars port decision)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D5, D17]
gate: D5
gate_note: "D5 mandates this ADR before any proc-macro BCs (#[tool], #[entrypoint]) can unblock. ADR-004 is the D5 gate resolution for the pydantic→serde/schemars dependency disposition."
supersedes: []
---

# ADR-004: Schema Generation (serde + schemars)

**Status:** Accepted — D5 gate resolved; ADR-008 and proc-macro BCs unblocked

## Context

LangGraph Python uses `pydantic` for both data validation and JSON schema generation
(tool argument schemas, structured output schemas, model-level validation).
D5 mandates a dedicated ADR before any pydantic→serde/schemars dependency decision
propagates into BCs.

In Rust the analogous role is split:
- **serde**: serialization/deserialization (runtime values ↔ JSON/msgpack)
- **schemars**: compile-time JSON Schema generation from Rust types (for tool argument schemas)
- **validator** (optional): runtime validation beyond type-level constraints

## Decision: serde (required) + schemars (required for tool/structured output schemas)

**serde:** Universal. All structs that cross a serialization boundary use `serde::Serialize + serde::Deserialize`. No alternatives considered; serde is the Rust standard.

**schemars (for JSON Schema):**
Pydantic's `model_json_schema()` functionality maps to `schemars::schema_for!(<Type>)`.
This is required for:
1. Tool argument schema generation (passed to LLM `tools` parameter)
2. Structured output schema generation (passed to LLM `response_format` parameter)
3. The `#[tool]` proc-macro attribute (ADR-008) — tool schemas derived at compile time

**Rejected alternatives:**
- **JSON Schema hand-authored:** Fragile; no compile-time sync with Rust types. REJECT.
- **typify / openapiv3:** Generates Rust types from OpenAPI schemas (wrong direction). REJECT.
- **validator crate:** Runtime validation library; supplements schemars but does not replace it. May be added as an optional dep post-v1.

**Recommendation: ADOPT schemars.**

**Version pin:** schemars 1.x (verified 1.2.1, 2026-02). Breaking change from 0.8:
`schemars::schema::RootSchema` (0.8-era path) is replaced by `schemars::Schema`
(idiomatic 1.x type). All code and BCs must use the 1.x path.

## Consequences

- All tool definition types and structured output types derive `schemars::JsonSchema`.
- `ToolDefinition` in ferrochain-core contains a `schema: schemars::Schema` field
  (NOT `schemars::schema::RootSchema` — that is the deprecated 0.8 path).
- The `BaseChatModel::with_structured_output<T>()` bound requires `T: schemars::JsonSchema + serde::DeserializeOwned`.
- schemars becomes a direct dependency of ferrochain-core (not just a dev-dep).
- BC-2.08.003 (structured output conformance) can now be authored: it is gated on this ADR.
- ADR-008 (proc-macros) can proceed: `#[tool]` derives `schemars::JsonSchema` on the annotated struct.
- **Schema naming stability (snapshot test obligation):** Tool schemas are public API —
  a schema rename is a breaking change for downstream users. Each public tool type
  that derives `schemars::JsonSchema` MUST have a snapshot test (insta or similar)
  asserting the generated JSON Schema output. These snapshot tests are a Phase 3 BC
  anchor obligation and must be referenced in the story that implements the `#[tool]`
  proc-macro. (See BC-2.08.009: Tool Schema Naming Stability — OBS-P16-02.)

## D5 Gate Resolution

This ADR constitutes the D5 gate resolution for pydantic→serde/schemars.
numpy→ndarray and pandas→polars decisions are NOT in scope for ferrochain (no ML data pipeline; those are python-only concerns). D5 disposition for all dependencies:

| Python dep | Rust analog | Disposition | ADR |
|-----------|-------------|-------------|-----|
| pydantic | serde + schemars | ADOPT | ADR-004 (this) |
| numpy | — | N/A (not in scope) | — |
| pandas | — | N/A (not in scope) | — |
| httpx / requests | reqwest | ADOPT (standard) | — |
| asyncio | tokio | ADOPT (standard) | — |
