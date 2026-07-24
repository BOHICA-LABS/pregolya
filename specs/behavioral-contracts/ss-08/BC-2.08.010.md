---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.010
version: "1.2"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-002
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-002
  - architecture/decisions/ADR-004-serde-schemars-schema-generation.md
  - architecture/decisions/ADR-008-proc-macro-attributes.md
  - architecture/decisions/ADR-018-per-tool-call-approval-hook.md
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-004-serde-schemars-schema-generation.md
  - .factory/specs/architecture/decisions/ADR-008-proc-macro-attributes.md
  - .factory/specs/architecture/decisions/ADR-018-per-tool-call-approval-hook.md
input-hash: "a4b78f1"
changelog:
  - "1.2 (burst-234/F-P134-03/2026-07-22): Fix mis-anchor — replace both BC-2.05.004 references with BC-2.05.007. PC-1 body and Related BCs both cited BC-2.05.004 (Command-resume API) for the PreToolCallHook / ToolCallPreview / pre_tool_dispatch contract; that contract lives in BC-2.05.007 (PreToolCallHook Dispatch). BC-2.05.004 is the Command(resume=value) programmatic-resume API — unrelated to pre_tool_dispatch. Verified: BC-2.05.007 §Preconditions PC-3 explicitly defines ToolCallPreview construction and §Invariants Retry-ordering clause confirms pre_tool_dispatch dispatch. Reciprocal link added to BC-2.05.007 Related BCs. TD-VSDD-060 sibling sweep: one PC-1 site + one Related BCs site — both corrected in this burst."
  - "1.1 (D23/2026-07-22): Add optional `action_risk` attribute parameter (`action_risk = ActionRisk::High`) per ADR-018 Decision 6. PC3 updated to document optional attribute; PC1 extended with `action_risk()` method on generated struct; `ToolCallPreview.action_risk` carries the value when `pre_tool_dispatch` hook is called. New EC-005: omitting `action_risk` defaults to `None` (no risk tier constraint). Related BCs: BC-2.05.004 and BC-2.23.005 forward refs added."
  - "1.0 (initial): base BC authored."
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.010: `#[tool]` Attribute Macro — async fn to Tool Implementor via schemars::JsonSchema

## Description

The `#[ferrochain::tool]` proc-macro attribute converts an annotated async function into a
struct that implements the `Tool` trait (including `Runnable<ToolInput, ToolOutput>`). The
macro derives `schemars::JsonSchema` on the generated argument struct, wires the function
body as the `invoke` implementation, and registers the tool name and description as static
metadata. Manual `impl Tool` remains valid — this macro is purely additive. The generated
type MUST have a committed snapshot test per BC-2.08.009 (schema naming stability).

## Preconditions

1. The annotated function is `async fn` returning `Result<T, FerrochainError>` where `T: serde::Serialize`.
2. All parameter types implement `schemars::JsonSchema + serde::DeserializeOwned`.
3. The `#[ferrochain::tool(name = "...", description = "...")]` attribute is present with both
   `name` and `description` specified. An optional `action_risk` attribute key (e.g.,
   `action_risk = ActionRisk::High`) may be included to declare the tool's risk tier; if
   omitted, the generated struct's `action_risk()` returns `None` and `ToolCallPreview.action_risk`
   is `None` when the `pre_tool_dispatch` hook is called.
4. `ferrochain-macros` is available as a direct or transitive dependency (re-exported from
   `ferrochain-core`).

## Postconditions

1. The macro expansion generates a zero-sized struct `<PascalCaseName>Tool` (derived from the
   function name) implementing:
   - `Tool` trait with `name()` returning the supplied `name` literal
   - `description()` returning the supplied `description` literal
   - `schema()` returning `schemars::schema_for!(<ArgStruct>)` as `schemars::Schema`
   - `action_risk()` returning `Option<ActionRisk>` — `Some(ActionRisk::<Tier>)` when the
     `action_risk` attribute is present; `None` when omitted. This value is carried into
     `ToolCallPreview.action_risk` when the `pre_tool_dispatch` hook is invoked (BC-2.05.007).
   - `Runnable<ToolInput, ToolOutput>` with `invoke` delegating to the annotated function body
2. A private `<PascalCaseName>Args` struct is generated with one field per function parameter;
   the struct derives `serde::Deserialize + schemars::JsonSchema`.
3. The generated `<PascalCaseName>Tool` struct is `Send + Sync` (Rust async tool requirement).
4. The macro enforces DI-008 at the call site: the annotated function must return
   `Result<T, FerrochainError>` (see EC-003 for compile-time rejection). No generated code
   uses `.unwrap()` or `.expect()` in non-test contexts.
5. The expansion compiles without any `#[allow(unused)]` suppressions in non-test code.

## Invariants

- DI-008 (Library Constructor Result Contract): The generated `invoke` delegates to the
  annotated function, which must return `Result<T, FerrochainError>`. Macro expansion does
  not use `.expect()` or `.unwrap()` in generated non-test code. EC-003 enforces this at
  compile time.
- The macro is additive; it does not modify the annotated function's signature or behavior.
- **Related invariant — DI-010 (Credential Opacity):** API key types used as tool parameters
  must follow the DI-010 newtype pattern (no `#[derive(Debug)]` or `Serialize` on secret
  types). This constraint is enforced by BC-2.14.005, not by this BC. Callers are responsible
  for using opaque newtypes as parameter types rather than raw `String` for secrets.
- Schema naming stability: the generated `<PascalCaseName>Args` struct name is stable and
  constitutes a public API surface per BC-2.08.009 snapshot obligation.

## Edge Cases

### EC-001: Parameter type does not implement schemars::JsonSchema
**Scenario:** `#[ferrochain::tool] async fn search(query: MyCustomType) -> ...` where
`MyCustomType` does not derive `schemars::JsonSchema`.
**Expected behavior:** Compile-time error from schemars bounds check. Error message cites
the missing `JsonSchema` impl on `MyCustomType`. No runtime failure.

### EC-002: Duplicate tool name in the same crate
**Scenario:** Two `#[ferrochain::tool(name = "search_web")]` annotations in the same module.
**Expected behavior:** The generated struct names differ (based on function names), but the
runtime `name()` string is duplicated. Duplicate tool names in a single `MultiServerMcpClient`
config produce an `Err(ToolRegistrationError::DuplicateName)` at registration time, not at
compile time.

### EC-003: Function returns non-FerrochainError error type
**Scenario:** `#[ferrochain::tool] async fn op() -> Result<String, std::io::Error>`
**Expected behavior:** Compile-time error: the macro requires `Result<T, FerrochainError>`.
Error message must guide the user to wrap with `FerrochainError`.

### EC-004: Missing name or description attribute
**Scenario:** `#[ferrochain::tool]` with no arguments (no `name`, no `description`).
**Expected behavior:** Compile-time error specifying both fields are required. The macro
MUST NOT fall back to using the function name as the tool name silently (explicit contract).

### EC-005: `action_risk` omitted from attribute
**Scenario:** `#[ferrochain::tool(name = "search_web", description = "Searches the web")]` with no `action_risk` key.
**Expected behavior:** Compiles successfully. `SearchWebTool::default().action_risk()` returns `None`.
When the `pre_tool_dispatch` hook is called, `ToolCallPreview.action_risk` is `None`. The hook
retains full discretion to approve, deny, or edit — no risk tier constraint is applied by the framework
on the caller's behalf.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `#[ferrochain::tool(name="search_web", description="Searches")]` on valid `async fn` | Compiles; `SearchWebTool::default().name() == "search_web"` | Happy path |
| TV-002 | `SearchWebTool::default().schema()` | Returns `schemars::Schema` matching `schema_for!(SearchWebArgs)` | Schema is schemars-derived |
| TV-003 | Annotated function body invoked via `tool.invoke(args)` | Async result from original function body returned unchanged | Runnable delegation |
| TV-004 | Missing `schemars::JsonSchema` on parameter type | Compile error with descriptive message | Bound check |
| TV-005 | `#[ferrochain::tool]` with no `name` attribute | Compile error: "name is required" | Explicit contract |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208010-01 | `#[tool]`-generated struct passes snapshot test for its JSON Schema output | Snapshot test (insta); BC-2.08.009 obligation | Phase 3 |

## Related BCs

- BC-2.08.009 — composes with: snapshot test obligation for any `#[tool]`-generated schema
- BC-2.08.011 — sibling: `#[entrypoint]` macro (same proc-macro crate, different attribute)
- BC-2.08.012 — sibling: `#[task]` macro (same proc-macro crate)
- BC-2.01.003 — depends on: Runnable trait invocation contract governs invoke dispatch
- BC-2.05.007 — composes with: `action_risk()` value is carried into `ToolCallPreview.action_risk` for `PreToolCallHook` evaluation; hook sees the declared risk tier before deciding to approve/deny/edit
- BC-2.23.005 — example: BashTool sets `action_risk = ActionRisk::Medium` as a risk floor; illustrates the `action_risk` attribute in practice

## Architecture Anchors

- `ferrochain-macros/src/tool.rs` — `#[tool]` proc-macro implementation
- `ferrochain-core/src/tool.rs` — `Tool` trait definition re-exporting from `ferrochain-macros`
- `architecture/decisions/ADR-004-serde-schemars-schema-generation.md` — schemars 1.x pin
- `architecture/decisions/ADR-008-proc-macro-attributes.md` — proc-macro design rationale

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208010-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-002 |
| Capability Anchor Justification | CAP-002 ("Runnable Trait Abstraction (Compose, Pipe, Chain)") per capabilities-p0.md §CAP-002 — the `#[tool]` macro creates a `Runnable`-compatible `Tool` implementor, directly realizing the universal composition protocol that CAP-002 defines; this is the macro ergonomics layer on top of the `Runnable` trait |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — macro-generated `invoke` wraps the annotated function, which must return `Result<T, FerrochainError>`; EC-003 enforces this at compile time) |
| DEC Reference | — |
| Risk Source | ADR-004 acceptance (D5 gate resolved); ADR-008 proc-macro design |
| D17 Commitment | D17-Q6 — proc-macro BCs gated on D5 ADR; ADR-004 accepted unblocks this BC |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), snapshot |
| Module | ferrochain-macros (re-exported ferrochain-core) |
