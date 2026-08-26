---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.010
version: "1.6"
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
timestamp: 2026-08-26T00:00:00Z
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
input-hash: "a76765b"
changelog:
  - "1.0 (initial): base BC authored."
  - "1.1 (D23/2026-07-22): Add optional `action_risk` attribute parameter (`action_risk = ActionRisk::High`) per ADR-018 Decision 6. PC3 updated to document optional attribute; PC1 extended with `action_risk()` method on generated struct; `ToolCallPreview.action_risk` carries the value when `pre_tool_dispatch` hook is called. New EC-005: omitting `action_risk` defaults to `None` (no risk tier constraint). Related BCs: BC-2.05.004 and BC-2.23.005 forward refs added."
  - "1.2 (burst-234/F-P134-03/2026-07-22): Fix mis-anchor — replace both BC-2.05.004 references with BC-2.05.007. PC-1 body and Related BCs both cited BC-2.05.004 (Command-resume API) for the PreToolCallHook / ToolCallPreview / pre_tool_dispatch contract; that contract lives in BC-2.05.007 (PreToolCallHook Dispatch). BC-2.05.004 is the Command(resume=value) programmatic-resume API — unrelated to pre_tool_dispatch. Verified: BC-2.05.007 §Preconditions PC-3 explicitly defines ToolCallPreview construction and §Invariants Retry-ordering clause confirms pre_tool_dispatch dispatch. Reciprocal link added to BC-2.05.007 Related BCs. TD-VSDD-060 sibling sweep: one PC-1 site + one Related BCs site — both corrected in this burst."
  - "1.3 (F-P171a-09+F-P171a-03sibling/burst-273/2026-07-25): (1) F-P171a-09: PC-1 action_risk() bullet extended with ADR-008 Decision 2 emitted-path contract: macro expansion emits ::pregolya_core::action_risk::ActionRisk::<Variant> (fully-qualified path); MUST NOT assume ActionRisk in annotated crate scope; omitting action_risk → ToolCallPreview.action_risk = None with no default variant applied by framework. (2) F-P171a-03 sibling: Related BCs BC-2.23.005 annotation corrected — 'BashTool sets action_risk = ActionRisk::Medium as a risk floor' was wrong on two counts: default annotation is ActionRisk::High (not Medium); Medium is the non-lowerable floor. Fixed to 'BashTool declares action_risk = ActionRisk::High and enforces a non-lowerable Medium floor'."
  - "1.4 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.07 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (burst-B-SS07-08/bc-completeness-scan-P2/2026-08-26): Resolve Phase-2 BC-completeness-scan gap SS-07..08: PC-006 added — tool-collection assembly DuplicateName → E-TOOLS-010 DuplicateToolName (VAL, broken, Never); EC-002 updated to cite E-TOOLS-010 explicitly with message template and first-registered-retained semantics; TV-006 added for duplicate-name assembly path. ANCHOR NOTE: error-taxonomy.md anchors E-TOOLS-010 to 'BC-2.08.010 PC-003' (the Send+Sync postcondition); actual owning clause is PC-006 (added this burst); anchor will need correction in a subsequent coordinator sweep."
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

The `#[pregolya::tool]` proc-macro attribute converts an annotated async function into a
struct that implements the `Tool` trait (including `Runnable<ToolInput, ToolOutput>`). The
macro derives `schemars::JsonSchema` on the generated argument struct, wires the function
body as the `invoke` implementation, and registers the tool name and description as static
metadata. Manual `impl Tool` remains valid — this macro is purely additive. The generated
type MUST have a committed snapshot test per BC-2.08.009 (schema naming stability).

## Preconditions

1. {PRE-001} The annotated function is `async fn` returning `Result<T, PregolyaError>` where `T: serde::Serialize`.
2. {PRE-002} All parameter types implement `schemars::JsonSchema + serde::DeserializeOwned`.
3. {PRE-003} The `#[pregolya::tool(name = "...", description = "...")]` attribute is present with both
   `name` and `description` specified. An optional `action_risk` attribute key (e.g.,
   `action_risk = ActionRisk::High`) may be included to declare the tool's risk tier; if
   omitted, the generated struct's `action_risk()` returns `None` and `ToolCallPreview.action_risk`
   is `None` when the `pre_tool_dispatch` hook is called.
4. {PRE-004} `pregolya-macros` is available as a direct or transitive dependency (re-exported from
   `pregolya-core`).

## Postconditions

1. {PC-001} The macro expansion generates a zero-sized struct `<PascalCaseName>Tool` (derived from the
   function name) implementing:
   - `Tool` trait with `name()` returning the supplied `name` literal
   - `description()` returning the supplied `description` literal
   - `schema()` returning `schemars::schema_for!(<ArgStruct>)` as `schemars::Schema`
   - `action_risk()` returning `Option<ActionRisk>` — `Some(ActionRisk::<Tier>)` when the
     `action_risk` attribute is present; `None` when omitted. This value is carried into
     `ToolCallPreview.action_risk` when the `pre_tool_dispatch` hook is invoked (BC-2.05.007).
     **ADR-008 Decision 2 emitted-path contract:** The macro expansion emits the value as the
     fully-qualified path `::pregolya_core::action_risk::ActionRisk::<Variant>` — it MUST NOT
     assume `ActionRisk` is in scope in the annotated crate. When `action_risk` is omitted from
     the attribute, `ToolCallPreview.action_risk` is `None`; no default variant is applied by
     the framework on the caller's behalf.
   - `Runnable<ToolInput, ToolOutput>` with `invoke` delegating to the annotated function body
2. {PC-002} A private `<PascalCaseName>Args` struct is generated with one field per function parameter;
   the struct derives `serde::Deserialize + schemars::JsonSchema`.
3. {PC-003} The generated `<PascalCaseName>Tool` struct is `Send + Sync` (Rust async tool requirement).
4. {PC-004} The macro enforces DI-008 at the call site: the annotated function must return
   `Result<T, PregolyaError>` (see EC-003 for compile-time rejection). No generated code
   uses `.unwrap()` or `.expect()` in non-test contexts.
5. {PC-005} The expansion compiles without any `#[allow(unused)]` suppressions in non-test code.
6. {PC-006} At tool-collection assembly time, if a second `Tool` implementor is registered under a
   name already occupied in the collection (i.e., two tools share the same `tool.name()` return
   value), the registration call returns
   `Err(PregolyaError { component: TOOLS, category: VAL, code: "E-TOOLS-010",
   message: "DuplicateToolName: tool name '<name>' is already registered", retry_hint: Never })`.
   The first-registered tool is retained; no partial or silent collection mutation occurs. Detection
   is at collection-assembly time, not at compile time (compile-time conflict produces different
   struct names; see EC-002). This postcondition applies to any tool-collection type that enforces
   name uniqueness (e.g., `ToolRegistry`, `MultiServerMcpClient` tool assembly). This is the
   **owning postcondition clause** for E-TOOLS-010 DuplicateToolName per error-taxonomy.md §Component: TOOLS (pregolya-tools).

## Invariants

- {INV-001} DI-008 (Library Constructor Result Contract): The generated `invoke` delegates to the
  annotated function, which must return `Result<T, PregolyaError>`. Macro expansion does
  not use `.expect()` or `.unwrap()` in generated non-test code. EC-003 enforces this at
  compile time.
- {INV-002} The macro is additive; it does not modify the annotated function's signature or behavior.
- {INV-003} **Related invariant — DI-010 (Credential Opacity):** API key types used as tool parameters
  must follow the DI-010 newtype pattern (no `#[derive(Debug)]` or `Serialize` on secret
  types). This constraint is enforced by BC-2.14.005, not by this BC. Callers are responsible
  for using opaque newtypes as parameter types rather than raw `String` for secrets.
- {INV-004} Schema naming stability: the generated `<PascalCaseName>Args` struct name is stable and
  constitutes a public API surface per BC-2.08.009 snapshot obligation.

## Edge Cases

### EC-001: Parameter type does not implement schemars::JsonSchema
**Scenario:** `#[pregolya::tool] async fn search(query: MyCustomType) -> ...` where
`MyCustomType` does not derive `schemars::JsonSchema`.
**Expected behavior:** Compile-time error from schemars bounds check. Error message cites
the missing `JsonSchema` impl on `MyCustomType`. No runtime failure.

### EC-002: Duplicate tool name at tool-collection assembly
**Scenario:** Two `#[pregolya::tool(name = "search_web")]` annotations (or any two `Tool`
implementors) produce the same `name()` return value. The generated struct names differ (based
on function names), so there is no compile-time conflict; the duplicate is detected only when
the tools are assembled into a collection.
**Expected behavior:** The tool-collection assembly call returns
`Err(PregolyaError { component: TOOLS, category: VAL, code: "E-TOOLS-010",
message: "DuplicateToolName: tool name 'search_web' is already registered",
retry_hint: Never })`. The first-registered tool is retained; the second registration attempt
returns the error and does not mutate the collection (definitive specification in PC-006).
Detection occurs at collection-assembly time, not at compile time.

### EC-003: Function returns non-PregolyaError error type
**Scenario:** `#[pregolya::tool] async fn op() -> Result<String, std::io::Error>`
**Expected behavior:** Compile-time error: the macro requires `Result<T, PregolyaError>`.
Error message must guide the user to wrap with `PregolyaError`.

### EC-004: Missing name or description attribute
**Scenario:** `#[pregolya::tool]` with no arguments (no `name`, no `description`).
**Expected behavior:** Compile-time error specifying both fields are required. The macro
MUST NOT fall back to using the function name as the tool name silently (explicit contract).

### EC-005: `action_risk` omitted from attribute
**Scenario:** `#[pregolya::tool(name = "search_web", description = "Searches the web")]` with no `action_risk` key.
**Expected behavior:** Compiles successfully. `SearchWebTool::default().action_risk()` returns `None`.
When the `pre_tool_dispatch` hook is called, `ToolCallPreview.action_risk` is `None`. The hook
retains full discretion to approve, deny, or edit — no risk tier constraint is applied by the framework
on the caller's behalf.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `#[pregolya::tool(name="search_web", description="Searches")]` on valid `async fn` | Compiles; `SearchWebTool::default().name() == "search_web"` | Happy path |
| TV-002 | `SearchWebTool::default().schema()` | Returns `schemars::Schema` matching `schema_for!(SearchWebArgs)` | Schema is schemars-derived |
| TV-003 | Annotated function body invoked via `tool.invoke(args)` | Async result from original function body returned unchanged | Runnable delegation |
| TV-004 | Missing `schemars::JsonSchema` on parameter type | Compile error with descriptive message | Bound check |
| TV-005 | `#[pregolya::tool]` with no `name` attribute | Compile error: "name is required" | Explicit contract |
| TV-006 | Assemble a tool collection registering two tools both with `name()` == `"search_web"` | `Err(E-TOOLS-010 DuplicateToolName { name: "search_web" })`; first-registered tool retained in collection | Duplicate-name fail (EC-002 / PC-006) |

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
- BC-2.23.005 — example: BashTool declares `action_risk = ActionRisk::High` as the default annotation and enforces a non-lowerable `Medium` risk floor via `ToolConfig::override_risk`; illustrates the `action_risk` attribute and floor enforcement in practice

## Architecture Anchors

- `pregolya-macros/src/tool.rs` — `#[tool]` proc-macro implementation
- `pregolya-core/src/tool.rs` — `Tool` trait definition re-exporting from `pregolya-macros`
- `architecture/decisions/ADR-004-serde-schemars-schema-generation.md` — schemars 1.x pin
- `architecture/decisions/ADR-008-proc-macro-attributes.md` — proc-macro design rationale

## Story Anchor

S-1.07

## VP Anchors

- VP-BC208010-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-002 |
| Capability Anchor Justification | CAP-002 ("Runnable Trait Abstraction (Compose, Pipe, Chain)") per capabilities-p0.md §CAP-002 — the `#[tool]` macro creates a `Runnable`-compatible `Tool` implementor, directly realizing the universal composition protocol that CAP-002 defines; this is the macro ergonomics layer on top of the `Runnable` trait |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — macro-generated `invoke` wraps the annotated function, which must return `Result<T, PregolyaError>`; EC-003 enforces this at compile time) |
| DEC Reference | — |
| Risk Source | ADR-004 acceptance (D5 gate resolved); ADR-008 proc-macro design |
| D17 Commitment | D17-Q6 — proc-macro BCs gated on D5 ADR; ADR-004 accepted unblocks this BC |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), snapshot |
| Module | pregolya-macros (re-exported pregolya-core) |
