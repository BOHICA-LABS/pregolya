---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.009
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-009
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P97-01, 2026-07-17): Module field resolved from variant-phrasing placeholder 'ferrochain-macros, ferrochain-core [architect to confirm crate→subsystem in Phase 1b]' to sibling-canonical 'ferrochain-macros (re-exported ferrochain-core)' per BC-2.08.010/011/012 and module-decomposition.md v1.10 §ferrochain-macros. Phase 1b closed 2026-07-14; placeholder class no longer accepted (F-P96-01)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
  - architecture/decisions/ADR-004-serde-schemars-schema-generation.md
  - architecture/decisions/ADR-008-proc-macro-attributes.md
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-004-serde-schemars-schema-generation.md
  - .factory/specs/architecture/decisions/ADR-008-proc-macro-attributes.md
input-hash: "0bd9726"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.009: Tool Schema Naming Stability (Snapshot Test Anchor)

## Description

Every public Rust type that derives `schemars::JsonSchema` as part of the ferrochain tool
definition surface (i.e., any type whose generated JSON Schema is embedded in a
`ToolDefinition` passed to an LLM provider) must have a committed insta snapshot test. The
snapshot asserts that `schemars::schema_for!(T)` serialized to canonicalized JSON has not
changed since the last committed snapshot. Any change to the snapshot output constitutes a
public-API breaking change and requires a semver-major bump before merge. Field reordering
within a Rust struct does NOT break the snapshot because canonicalized comparison sorts
object keys alphabetically; all other schema mutations (field rename, field addition of a
required field, type change, `additionalProperties` addition/removal) DO break the snapshot.

## Preconditions

1. A public Rust type `T` in a ferrochain crate derives `schemars::JsonSchema` and is used
   as the argument schema for a tool definition (directly or via `#[tool]` proc-macro
   expansion per ADR-008).
2. schemars ≥ 1.x (version-pinned per ADR-004 §Version pin: schemars 1.x, verified 1.2.1,
   2026-02) is a direct dependency of ferrochain-core. The 1.x `schemars::Schema` type is
   used — NOT the deprecated 0.8-era `schemars::schema::RootSchema`.
3. An insta snapshot file for `T` exists at the expected path (e.g.,
   `ferrochain-macros/tests/snapshots/schema__<type_name>.snap` or equivalent). If no
   snapshot file exists, the snapshot test fails with an "unreviewed snapshot" error on
   first run and is not silently skipped.
4. The snapshot comparison function serializes `schemars::schema_for!(T)` to a JSON string
   with all object keys sorted alphabetically (canonical form) before comparison.

## Postconditions

1. For any ferrochain release tagged as patch (`x.y.Z+1`) or minor (`x.Y+1.0`), executing
   the snapshot test suite produces zero snapshot diffs for all registered public tool
   types. The CI build fails if any snapshot diff is detected.
2. Any PR that would change a committed snapshot file MUST be accompanied by a semver-major
   version bump (`X+1.0.0`) merged before or together with the schema-changing PR. A PR
   that changes a snapshot without a semver-major bump is rejected by CI.
3. A public tool type added to any ferrochain crate without a corresponding committed
   snapshot file causes the snapshot CI step to fail (insta's `--force-update-snapshots`
   is not enabled in CI; snapshots must be reviewed locally and committed).
4. Rust struct field reorder (declaration order in source) alone does NOT produce a
   snapshot diff, because the canonical serialization sorts `"properties"` keys
   alphabetically. CI passes without requiring a version bump in this case.
5. Adding a new **optional** field (`Option<T>` or with `#[schemars(default)]`) to an
   existing tool type changes the snapshot. The test fails; this change requires a
   semver-major bump even though the change is additive, because downstream JSON-Schema
   validators may reject previously valid instances when the schema is re-fetched.

## Invariants

- **Snapshot files are immutable artifacts.** Snapshot files are committed to source
  control. They are never auto-updated in CI. An update requires a local `cargo insta
  review` session followed by an explicit commit.
- **Canonical form is alphabetically sorted JSON.** The snapshot compares the
  `serde_json::to_string_pretty` output of the schemars-generated schema after all
  object keys are sorted by Unicode code point. Array elements are NOT reordered.
- **schemars 1.x path only.** Any snapshot generated with `schemars::schema::RootSchema`
  (0.8-era deprecated type) is invalid and must be regenerated with `schemars::Schema`.
- **Scope: public tool types only.** Internal types not exposed through `ToolDefinition`
  are exempt. The boundary is: if `schemars::schema_for!(T)` is ever passed to a provider
  via a `ToolDefinition`, `T` is in scope.

## Edge Cases

### EC-001: Schema Field Rename (Always Breaking)
**Scenario:** A public tool argument struct has field `pub query: String` renamed to
`pub search_query: String`.
**Expected behavior:** The snapshot diff shows `"query"` replaced by `"search_query"` in
`"properties"`. The CI snapshot step fails. A semver-major bump is required before this PR
can merge. The existing snapshot file must be updated and committed after the bump decision
is approved.

### EC-002: Field Reorder — Not Breaking with Canonicalized Comparison
**Scenario:** A public tool argument struct reorders its field declarations in source (e.g.,
`pub query: String; pub max_results: u32` becomes `pub max_results: u32; pub query:
String`).
**Expected behavior:** Canonical serialization sorts `"properties"` alphabetically:
`"max_results"` and `"query"` appear in alphabetical order regardless of struct declaration
order. The snapshot is **unchanged**. CI passes. No version bump required.
**Rationale:** schemars 1.x emits properties in struct-declaration order by default, but
the snapshot harness applies a post-serialization key sort before comparison, making
declaration-order differences invisible.

### EC-003: `additionalProperties` Drift
**Scenario:** A developer adds `#[schemars(deny_unknown_fields)]` to an existing public
tool type (or removes it from a type that had it). This causes `"additionalProperties":
false` to appear in (or disappear from) the generated schema.
**Expected behavior:** The snapshot diff detects the addition or removal of
`"additionalProperties"`. The CI snapshot step fails. A semver-major bump is required.
This is a behavioral change for downstream tools that used the schema for validation.

### EC-004: schemars Version Bump Changing Output Format
**Scenario:** ferrochain-core upgrades schemars from 1.2.1 to a future 1.x.y release that
changes the generated JSON Schema format (e.g., emits `"type": ["string", "null"]` instead
of `{"anyOf": [{"type": "string"}, {"type": "null"}]}` for `Option<String>`).
**Expected behavior:** All snapshot files whose types include `Option<T>` fields now
produce diffs. The CI snapshot step fails across multiple types simultaneously. The correct
resolution is: (a) update all snapshots locally after reviewing the schemars changelog to
confirm the change is intentional, (b) bump ferrochain-core semver-major if the project is
already at v1+, (c) commit updated snapshots, (d) merge. Pre-v1 projects may treat this as
a minor bump with a changelog entry.

### EC-005: New Required Field Added to Existing Type
**Scenario:** A new required (non-`Option`) field `pub context: String` is added to an
existing public tool type.
**Expected behavior:** The generated schema's `"required"` array gains `"context"` and
`"properties"` gains the corresponding entry. Snapshot diff detected, CI fails. Requires
semver-major bump. Downstream callers that previously called the tool without providing
`context` will have their calls rejected by schema validation — this is a breaking change.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `schemars::schema_for!(SearchWebArgs)` where `struct SearchWebArgs { query: String, max_results: u32 }` | Canonicalized JSON with `"properties": { "max_results": { "type": "integer", ... }, "query": { "type": "string" } }`, `"required": ["max_results", "query"]` | Happy path — alphabetical order |
| TV-002 | Same `SearchWebArgs` after renaming `query` → `search_query` | Snapshot diff: `"query"` → `"search_query"` in `"properties"` and `"required"` | EC-001: field rename = CI failure |
| TV-003 | `SearchWebArgs` field order swapped in source: `max_results` declared first | Canonicalized JSON identical to TV-001 (alphabetical sort applied post-gen) | EC-002: reorder is not breaking |
| TV-004 | `#[schemars(deny_unknown_fields)]` added to `SearchWebArgs` | Snapshot diff: `"additionalProperties": false` appears in output | EC-003: additionalProperties drift |
| TV-005 | Type with `Option<String>` field, schemars upgraded to hypothetical 1.3.0 with format change | Snapshot diff on `Option<String>` representation | EC-004: version bump drift |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208009-01 | Field rename produces snapshot diff and CI failure | Unit test: generate schema before/after rename, assert diff detected | Wave 2 |
| VP-BC208009-02 | Field reorder with canonicalized comparison produces no snapshot diff | Unit test: two structs with fields in opposite declaration order, assert identical canonicalized output | Wave 2 |
| VP-BC208009-03 | Missing snapshot file causes CI failure (not skip) | Negative test: run insta suite without snapshot file present, assert non-zero exit | Wave 2 |

## Related BCs

- BC-2.08.002 — tool-call round-trip conformance (consumes `ToolDefinition` which carries the schema generated here)
- BC-2.08.003 — structured output conformance (uses `schemars::JsonSchema` via `with_structured_output`; same schemars 1.x path)

## Architecture Anchors

- `architecture/decisions/ADR-004-serde-schemars-schema-generation.md` §Schema naming stability (snapshot test obligation)
- `architecture/decisions/ADR-008-proc-macro-attributes.md` §`#[tool]` expansion (the proc-macro that triggers snapshot obligation)
- `ferrochain-macros/tests/snapshots/` — snapshot directory (to be created in Phase 3)
- `ferrochain-core/src/tool.rs` — `ToolDefinition { schema: schemars::Schema, ... }` field (per ADR-004 Consequences)

## Story Anchor

_[to be filled after story decomposition — anchored to the `#[tool]` proc-macro story per ADR-008]_

## VP Anchors

- VP-BC208009-01, VP-BC208009-02, VP-BC208009-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the schema stability obligation for public tool types whose generated JSON Schema is embedded in `ToolDefinition` and passed to provider chat model interfaces; a schema rename without a semver-major bump silently breaks downstream tool registration and provider-facing API contracts |
| Architecture Decision References | ADR-004 (D5 gate resolution: schemars ADOPT; snapshot obligation §Schema naming stability); ADR-008 (#[tool] proc-macro; schema generation trigger) |
| D5 Gate | Resolved by ADR-004 — schemars ADOPT disposition confirmed. This BC is a Phase-1b addition per OQR-4 and the bc-authoring-plan.md Proc-Macro BCs gate resolution. |
| L2 Domain Invariants | — (no DI-NNN directly covers schema naming stability; enforcement is through CI snapshot gate) |
| NE References | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit — snapshot diff detection, canonicalized comparison, missing-snapshot CI failure) |
| Module | ferrochain-macros (re-exported ferrochain-core) |
