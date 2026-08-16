---
document_type: adr
level: L3
adr_id: "004"
slug: serde-schemars-schema-generation
title: "Schema Generation: serde + schemars (pydantic→serde/schemars port decision)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
date: "2026-07-14"
subsystems_affected: ["all"]
supersedes: []
superseded_by: null
version: "1.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D5, D17]
gate: D5
gate_note: "D5 mandates this ADR before any proc-macro BCs (#[tool], #[entrypoint]) can unblock. ADR-004 is the D5 gate resolution for the pydantic→serde/schemars dependency disposition."
changelog:
  - "1.1 (burst-288/F-P177-LOW-date/2026-08-15): Add missing frontmatter fields (date, subsystems_affected, superseded_by); add Rationale, Alternatives Considered, Source / Origin sections per ADR template (LOW finding: date boundary conditions)."
  - "1.0 (D5/D17/2026-07-14): Initial ADR — adopt serde + schemars 1.x for JSON Schema generation; resolves D5 gate (pydantic→serde/schemars disposition)."
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

## Decision

Adopt `serde` (universal serialization) and `schemars` (JSON Schema generation) as the pydantic replacement:

- **serde:** Universal. All structs that cross a serialization boundary use `serde::Serialize + serde::Deserialize`. serde is the Rust standard.
- **schemars 1.x:** Pydantic's `model_json_schema()` maps to `schemars::schema_for!(<Type>)`. Required for tool argument schemas, structured output schemas, and the `#[tool]` proc-macro (ADR-008).
- **Version pin:** schemars 1.x (verified 1.2.1, 2026-02). Use `schemars::Schema` (1.x path), NOT `schemars::schema::RootSchema` (deprecated 0.8 path).

## Rationale

schemars 1.x is the production-grade Rust analog of pydantic's `model_json_schema()`:
1. Tool argument schemas are passed to LLM `tools` parameter — must be generated from Rust types at compile time.
2. Structured output schemas are passed to LLM `response_format` parameter — same requirement.
3. The `#[tool]` proc-macro (ADR-008) derives `schemars::JsonSchema` on the annotated struct.
4. serde is the Rust serialization standard with no viable alternative.
5. schemars 1.x provides a stable API (`schemars::Schema`) with `#[derive(JsonSchema)]` ergonomics comparable to pydantic's `BaseModel`.

## Consequences

- All tool definition types and structured output types derive `schemars::JsonSchema`.
- `ToolDefinition` in pregolya-core contains a `schema: schemars::Schema` field
  (NOT `schemars::schema::RootSchema` — that is the deprecated 0.8 path).
- The `BaseChatModel::with_structured_output<T>()` bound requires `T: schemars::JsonSchema + serde::DeserializeOwned`.
- schemars becomes a direct dependency of pregolya-core (not just a dev-dep).
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
numpy→ndarray and pandas→polars decisions are NOT in scope for pregolya (no ML data pipeline; those are python-only concerns). D5 disposition for all dependencies:

| Python dep | Rust analog | Disposition | ADR |
|-----------|-------------|-------------|-----|
| pydantic | serde + schemars | ADOPT | ADR-004 (this) |
| numpy | — | N/A (not in scope) | — |
| pandas | — | N/A (not in scope) | — |
| httpx / requests | reqwest | ADOPT (standard) | — |
| asyncio | tokio | ADOPT (standard) | — |

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| JSON Schema hand-authored | Fragile; no compile-time sync with Rust types; every type change requires manual schema update. REJECT. |
| typify / openapiv3 | Generates Rust types from OpenAPI schemas (wrong direction — we need the reverse: Rust types → JSON Schema). REJECT. |
| validator crate | Runtime validation library; supplements schemars but does not generate JSON Schemas. May be added as optional dep post-v1 for advanced validation use cases. |
| schemars 0.8 | Deprecated path (`schemars::schema::RootSchema`); 1.x is the stable API. REJECT in favor of 1.x. |

## Source / Origin

- **Decision mandate:** D5 — pydantic→serde/schemars disposition ADR required before proc-macro BCs unblock.
- **Downstream unblocked:** ADR-008 (proc-macro attributes), BC-2.08.003 (structured output conformance), BC-2.08.009 (tool schema naming stability).
- **Authoring context:** D5/D17 design session (2026-07-14); pregolya Phase 1a.
