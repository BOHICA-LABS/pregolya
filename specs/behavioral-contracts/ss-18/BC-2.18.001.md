---
document_type: behavioral-contract
level: L3
bc_id: BC-2.18.001
version: "1.6"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-18
capability: CAP-022
crate: ferrochain-prompts
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008, DI-014]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-18 Prompt Templates"
  - "1.1 (burst-227/F-P132-04/2026-07-21): Description ¶1: remove 'in strict-undefined mode (jinja2 engine or explicit f-string strict mode)' qualifier — E-TMPL-003 is unconditional and engine-neutral per INV-3/PC4/ADR-015 Decision 4; description now states the raise is unconditional in both f-string and jinja2 engines."
  - "1.2 (FIX-BURST-269/F-P167-01/2026-07-25): Fix Category::VALIDATION → Category::VAL in PC-4 code block (E-TMPL-003 Err struct). VALIDATION is not in the canonical 12-member Category enum; E-TMPL-003 is VAL per error-taxonomy.md §E-TMPL-003. D23 sibling-sweep."
  - "1.3 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B): Component::TMPL → Component::Tmpl, Category::VAL → Category::Val in PC-4 code block. Taxonomy code-string column stays SCREAMING as documentation shorthand; only typed Rust enum paths change."
  - "1.4 (fix-burst-279/F-P175-B201+B204/ADR-015-D3-Amendment/2026-07-28): THREE changes. (1) INV-5 (new): PromptTemplate::format is explicitly unguarded — output is a bare String with no MessageProvenance; callers MUST NOT place this output in a system-role position without routing through ChatPromptTemplate::format_messages (B201 CRIT; ADR-015 Decision 3 Amendment). (2) INV-1 fix (B204): was self-contradictory ('infallible only if ... returns Err'); corrected to proper fallible statement — construction is fallible, unparseable templates return Err(E-TMPL-004) at construction time. (3) E-TMPL-004 MalformedTemplate: minted for construction-time parse failures; EC-007/EC-008/EC-009 added for unbalanced-brace and empty-brace inputs (highest-risk input class for the in-house f-string parser); TV-007 added. E-TMPL-* census 3→4; total census 110→111."
  - "1.5 (fix-burst-280/F-P175-A25/2026-07-28): PC4 E-TMPL-003 construction example converted from struct-literal form to canonical FerrochainError::new(Component::Tmpl, Category::Val, RetryHint::Never, ...) form. Struct-literal is barred for external-crate callers by #[non_exhaustive]; test-writers outside ferrochain-core must use ::new(). TD-VSDD-060 sibling sweep: TV-004 and TV-007 use abbreviated {code, message}-only shorthand — those are verification-field descriptions, not compilable construction expressions; classified (c) and left as-is."
  - "1.6 (wave-b-b7-notation-sweep/2026-07-29): ADR-010 §Class 3 notation sweep — 3 CLASS3_MISSING_DOTDOT violations corrected. (1) Description ¶1 E-TMPL-003 inline cite: add `, ..` field-elision marker. (2) TV-004 expected-output cell: add `, ..` field-elision marker. (3) TV-007 expected-output cell: add `, ..` field-elision marker; `...` inside message-string value is inside a quoted string (not field-elision position) and is left as-is. No security semantics or VP anchors altered."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-022
  - architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "352f3dd"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.18.001: PromptTemplate F-String Rendering, Partial Binding, Variable Detection, and Strict-Undefined Guard

## Description

`PromptTemplate` renders a single-message prompt by substituting named variables into an
f-string template using Python `str.format` semantics: `{variable}` substitution, `{{` and
`}}`  as literal-brace escapes, and no nested attribute access in v1. Partial variable binding
pre-fills a subset of variables at template-construction time; call-time variables are merged
in and override partial bindings on key collision. Required variable names are detected at
construction time (static introspection, before any render call). An undefined variable raises
`Err(FerrochainError { code: "E-TMPL-003", .. })` unconditionally — in both the f-string engine and
the jinja2 engine — rather than silently substituting an empty string. There is no lenient mode;
E-TMPL-003 is engine-neutral and not gated on any configuration flag (ADR-015 Decision 4).

## Preconditions

1. A `PromptTemplate` has been constructed via `PromptTemplate::from_template(template_str)`
   or `PromptTemplate::from_template_with_partials(template_str, partial_vars)` — both return
   `Result<Self, FerrochainError>` per DI-008.
2. For rendering, a `HashMap<String, TemplateVar>` of call-time variables is available.
3. The template string uses only `{variable}` and `{{` / `}}` syntax (f-string engine default).
   Jinja2 engine requires `feature = "jinja2"` enabled at compile time.

## Postconditions

1. `PromptTemplate::format(&self, vars: HashMap<String, TemplateVar>) → Result<String, FerrochainError>`
   returns `Ok(rendered_string)` when all required variables are supplied.
2. Partial bindings are merged with call-time vars before rendering; call-time vars win on
   key collision.
3. `PromptTemplate::input_variables(&self) → &[String]` returns the complete set of variable
   names required at call time (partial-bound names excluded).
4. An undefined variable (present in template but absent from merged var map) returns
   `Err(FerrochainError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-003",
   "UndefinedVariable: variable '{var_name}' is not defined in the template context"))`
   — no silent empty substitution under any rendering mode.
5. `{{` and `}}` render as literal `{` and `}` respectively; they are NOT counted as substitution
   points and do NOT appear in `input_variables()`.
6. Nested attribute access (`{x.y}`) is treated as a single flat variable name `x.y` (not
   deep access) in f-string mode — the caller must pre-compute the value.

## Invariants

1. `PromptTemplate` construction is fallible — templates with unbalanced braces, stray close
   braces, empty variable slots (`{}`), or other parse errors return
   `Err(FerrochainError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-004",
   "MalformedTemplate: <parse_error>"))` at construction time per DI-008. The same malformed
   template string always fails; the error is deterministic given the input.
2. `input_variables()` returns identical results on every call regardless of how many times
   `format()` has been invoked (pure, idempotent computation).
3. E-TMPL-003 is unconditional — the f-string engine does NOT substitute an empty string for
   undefined variables under any call path, including when `strict_undefined` is not explicitly
   configured (default behavior is strict).
4. Partial bindings are immutable once set at construction; they are not modifiable after the
   template is built (builder returns a new `PromptTemplate` value, not mutation in place).
5. The output of `PromptTemplate::format` is a bare `String` with no `MessageProvenance` and
   no injection guard. Callers MUST NOT use this output directly as system-role content in any
   LLM call or `ChatPromptTemplate` without routing it through
   `ChatPromptTemplate::format_messages` for a `TrustLevel` check.
   (ADR-015 Decision 3 Amendment — `PromptTemplate::format` explicitly unguarded; the injection
   guard (E-TMPL-001) fires ONLY in `format_messages`. Placing raw `format()` output in a
   system position is an injection risk with no automatic backstop.)

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Template string is `""` (empty) | Construction succeeds; `input_variables()` returns `[]`; `format({})` returns `Ok("")` |
| EC-002 | All variables are partial-bound; call-time `vars` is empty `HashMap` | Renders successfully with partial values; call-time empty map does not override partials |
| EC-003 | Template has `{{literal}}` — two braces on each side | `{{literal}}` renders as `{literal}` (literal string, not a substitution); `input_variables()` does NOT include `"literal"` |
| EC-004 | Template has `{x}` but `x` is absent from merged vars | Returns `Err(E-TMPL-003 UndefinedVariable)` for `x`; does NOT return `""` for `x` |
| EC-005 | Call-time `vars` contains a key matching a partial binding | Call-time value wins; partial binding is shadowed for this render call |
| EC-006 | Template has `{x.y}` (apparent nested access) | `x.y` is treated as a single flat variable name; `input_variables()` includes `"x.y"`; caller must supply `"x.y"` as a key |
| EC-007 | Template string `"Hello, {name"` — unbalanced open brace | `PromptTemplate::from_template("Hello, {name")` returns `Err(FerrochainError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-004", "MalformedTemplate: unclosed variable brace starting near 'name'"))` — construction fails; no render |
| EC-008 | Template string `"a } b"` — stray close brace | `PromptTemplate::from_template("a } b")` returns `Err(E-TMPL-004 MalformedTemplate)` — stray `}` without matching `{{` is a parse error; construction fails |
| EC-009 | Template string `"{}"` — empty variable slot | `PromptTemplate::from_template("{}")` returns `Err(E-TMPL-004 MalformedTemplate)` — `{}` has no variable name and is not a valid `{variable}` placeholder; construction fails |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `template = "Hello, {name}! You have {count} messages."`, `vars = {"name": "Alice", "count": "3"}` | `Ok("Hello, Alice! You have 3 messages.")` | happy-path |
| TV-002 | `template = "Hello, {name}!"`, partial `name = "Bob"`, call-time `vars = {}` | `Ok("Hello, Bob!")` | happy-path (partial binding) |
| TV-003 | `template = "Curly: {{not_a_var}}"`, `vars = {}` | `Ok("Curly: {not_a_var}")` — literal braces | edge-case (brace escaping) |
| TV-004 | `template = "Hello, {name}!"`, `vars = {}` (name absent) | `Err(FerrochainError { code: "E-TMPL-003", message: "UndefinedVariable: variable 'name' is not defined in the template context", .. })` | error-case (undefined variable) |
| TV-005 | `template = "Hi {name}"`, partial `name = "Charlie"`, call-time `vars = {"name": "Dave"}` | `Ok("Hi Dave")` — call-time overrides partial | edge-case (partial override) |
| TV-006 | `PromptTemplate::from_template("Hello, {name}!")` → call `input_variables()` | `["name"]` | happy-path (variable detection) |
| TV-007 | `PromptTemplate::from_template("Hello, {name")` (unbalanced open brace) | `Err(FerrochainError { code: "E-TMPL-004", message: "MalformedTemplate: ...", .. })` — construction fails at parse time | error-case (malformed template; EC-007) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.18.001-A | For any template and any var map, `format()` never returns `Ok(s)` where `s` contains a bare `{var_name}` placeholder that was not in `vars` | unit test — fuzz over template shapes |
| VP-2.18.001-B | `input_variables()` returns the same set across repeated calls with no side effects | unit test — idempotency check |

## Related BCs

- BC-2.18.002 — composes with: ChatPromptTemplate builds on the same f-string engine and partial-binding semantics
- BC-2.18.004 — NOTE: injection_guard does NOT fire during the `PromptTemplate::format` path this BC specifies. The guard fires ONLY in `ChatPromptTemplate::format_messages` (BC-2.18.004). Output of `PromptTemplate::format` is unguarded; see INV-5 for the prohibition on system-position use without re-routing through `format_messages`. (ADR-015 Decision 3 Amendment, B201 CRIT.)
- BC-2.18.005 — depends on: construction-time policy check (E-TMPL-002) is a precondition for BC-2.18.001's construction postconditions

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-18 module decomposition, `prompts::template` module
- `architecture/decisions/ADR-015-prompt-template-injection-safety.md` — Decision 4 (f-string engine, in-house ~100 LOC, Python str.format semantics, strict-undefined)
- `architecture/purity-boundary-map.md` — `ferrochain-prompts / prompts::template` classification (Pure Core — no I/O)

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-18 story]_

## VP Anchors

- VP-2.18.001-A, VP-2.18.001-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-022 |
| Capability Anchor Justification | CAP-022 ("PromptTemplate and ChatPromptTemplate as Runnable (f-string Default, Jinja2 Optional)") per capabilities-p1-p2.md §CAP-022 — this BC specifies the single-message PromptTemplate rendering contract, partial binding, variable detection, and strict-undefined guard that CAP-022 identifies as the f-string default rendering surface for ferrochain-prompts |
| L2 Domain Invariants | DI-008 (construction returns Result; no .unwrap()/.expect() in non-test code), DI-014 (E-TMPL-003 propagates as Err; no silent None or empty substitution) |
| Architecture Authority | ADR-015 Decision 4 (f-string engine semantics, strict-undefined, in-house implementation) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-prompts / prompts::template |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core, no I/O) |
