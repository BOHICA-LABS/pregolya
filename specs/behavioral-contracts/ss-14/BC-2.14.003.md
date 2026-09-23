---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.003
version: "1.6"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-14
capability: CAP-016
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-* (all crates) / xtask (lint gate) per module-decomposition.md v1.10."
  - "1.2 (WAVE-B-B3/2026-07-29): Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon) + D-35 xtask rename (D-80). Notation: EC-002 `PregolyaError { ... }` — replaced `...` with `..` (CLASS3_ASCII_ELLIPSIS_VIOLATION); TV-002 Expected Output — added `, ..` (CLASS3 VIOLATION, 2/5 fields). Xtask rename (D-35/D-80): 5 occurrences of `cargo xtask lint-no-panic` → `cargo xtask check-no-panic` in PC4, TV-003, TV-004, VP-DI008-01, Architecture Anchors. No behavioral change."
  - "1.3 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.02 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.4 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.5 (S-1.02-adv-pass-2/CRITICAL-F-A+F-B/2026-09-22, product-owner): CRITICAL-F-A — BC↔BC contradiction adjudicated (Option A: fail-fast governs). {PC-005} revised to carve a narrow programmer-error-guard exception; EC-006 added defining the programmer-error-guard-assertion policy and the precise boundary between programmer-error (panic) and runtime-data-error (Result). {PC-006} revised to enumerate both permitted panic paths and to explicitly state that an unconditional unreachable!() exemption does NOT exist in this contract. EC-004 clarified: the _other => unreachable!() wildcard form is NOT the exempt form; only the fully-enumerated no-wildcard form is exempt. F-B — EC-007 added specifying the exact check-no-panic gate discipline for the two narrow exemptions (exhaustive-match unreachable! and programmer-error-guard assert); records the implementer error-of-record (an unconditional unreachable! exemption was falsely cited as BC-2.14.003 product-owner guidance; no such guidance exists in this BC)."
  - "1.6 (INV-004-sibling-sweep/2026-09-23, product-owner): {INV-004} expanded to enumerate the full test-code exemption perimeter, sibling-swept from BC-2.14.004 §{INV-003} (INV-003-clause-a-predicate-fix). Both BCs share the same `is_test_file` predicate in `cargo xtask check-no-panic`. Prior text cited only '#[cfg(test)] and tests/ directory', omitting the filename forms (tests.rs, _test.rs, _tests.rs) and the #[test]-family attribute exemption. Corrected to three-clause enumeration matching the gate implementation: (a) test files by path/filename, (b) #[cfg(test)]-attributed items, (c) #[test]-family function attributes. No behavioral change to the xtask gate — spec corrected to match code per Source-of-Truth Precedence Rule 7."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-008
  - NE-07
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "a8775d1"
extracted_from: null
modified: ["2026-09-23"]
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.003: All Library Constructors Return Result; No .unwrap()/.expect()/assert! in Non-Test Code

## Description

Every public library constructor across all pregolya crates returns `Result<T, PregolyaError>`
when construction can fail. The `Default` trait must not delegate to a fallible constructor.
`.unwrap()`, `.expect("...")`, and bare `assert!` / `assert_eq!` macros are prohibited in
non-test library code. A CI lint gate enforces this prohibition crate-wide. This contract
addresses NE-07 (adk-rust's `.expect()` in WASM engine init panics in production) and
implements DI-008 (Library Constructor Result Contract) uniformly.

## Preconditions

1. {PRE-001} A pregolya crate defines a public constructor (`new`, `build`, `from_config`, `try_new`, etc.)
   for a library type.
2. {PRE-002} The construction process can fail (e.g. invalid config, missing required field, parse error,
   I/O during init).
3. {PRE-003} The code is in non-test scope (not inside `#[cfg(test)]` or integration test files).

## Postconditions

1. {PC-001} Any fallible public constructor is declared as `pub fn new(...) -> Result<T, PregolyaError>`,
   NOT as `pub fn new(...) -> T`.
2. {PC-002} Infallible constructors (constructors that provably cannot fail) may return `T` directly;
   the CI lint does not flag them.
3. {PC-003} `impl Default for T` does NOT call a fallible constructor. If `Default` is needed on a type
   whose construction can fail, it is explicitly NOT derived and a comment explains the deviation.
4. {PC-004} The codebase contains zero occurrences of `.unwrap()` or `.expect(...)` in non-test library
   source files. CI `cargo xtask check-no-panic` (or equivalent custom clippy lint) causes the
   build to fail on any violation.
5. {PC-005} Bare `assert!` and `assert_eq!` macros are absent from non-test library code, with one
   narrow exception: programmer-error guard assertions in constructor-validation functions that
   enforce a documented API precondition on a programmer-supplied value that cannot be expressed
   as a compile-time type constraint (see EC-006 for the full policy and boundary definition).
   `debug_assert!` is permitted without restriction ({INV-003}).
6. {PC-006} `panic!` is absent from non-test library code except:
   (a) in an `unreachable!()` arm of a match expression that enumerates every runtime-reachable
       variant explicitly — with NO wildcard arm — such that the compiler enforces exhaustiveness
       without the `unreachable!()` sentinel (see EC-004); and
   (b) in programmer-error guard assertions satisfying the policy in EC-006.
   An unconditional `unreachable!()` exemption (exempting all `unreachable!` calls regardless
   of match context) does NOT exist in this contract. A `_ => unreachable!()` wildcard arm
   is not a statically-unreachable path — it is trivially reachable by adding a new enum
   variant — and is NOT exempt. See EC-004 for the correct form and EC-007 for gate discipline.

## Invariants

- {INV-001} **DI-008 (Library Constructor Result Contract):** Constructors that can fail return `Result`;
  panics in library code are a bug, not a recovery mechanism.
- {INV-002} **NE-07 enforcement:** The specific counter-example (adk-rust WASM engine init `.expect()`)
  is the prototype for this CI gate. Any code path reachable from a public API surface that
  contains `.expect` or `.unwrap` is a violation.
- {INV-003} `debug_assert!` is exempt from the lint (release builds do not execute it).
- {INV-004} `.unwrap()`, `.expect()`, and `assert!` / `assert_eq!` are fully exempt in the
  following test-code contexts:
  (a) **Test files** — source files whose path contains a `/tests/` directory component, or whose
  filename is exactly `tests.rs`, or whose filename ends with `_test.rs` or `_tests.rs`;
  (b) **`#[cfg(test)]`-attributed items** — any item, `impl` block, function, trait function, or
  item macro that carries a `#[cfg(test)]` attribute (directly or via an enclosing `#[cfg(test)]`
  module);
  (c) **`#[test]`-family function attributes** — any function whose attribute list includes an
  attribute whose final path segment is `test` (e.g., `#[test]`, `#[tokio::test]`,
  `#[async_std::test]`, `#[rstest]`, `#[parameterized_test]`, and any future `#[*::test]`
  variants).
  Test code in any of these contexts may use `.unwrap()` and `assert!` freely.

## Edge Cases

### EC-001: Default implementation on a type that was previously fallible
**Scenario:** A developer derives `#[derive(Default)]` on a type whose fields have no sensible
zero-value (e.g. `PregolyaError::default()` with empty strings).
**Expected behavior:** `derive(Default)` on a type whose `Default` would call a fallible path is
caught by the CI lint. The developer must either (a) not derive `Default`, (b) provide a safe
`Default` that produces a sentinel/"uninitialized" state, or (c) use a builder pattern.
**Reference:** DI-008 — "Default must not delegate to a fallible constructor."

### EC-002: Third-party crate used inside pregolya returns panicking code
**Scenario:** A dependency's function panics on invalid input (e.g. `url::Url::parse` panics on
certain inputs in some crate versions).
**Expected behavior:** The pregolya wrapper code calls the dependency via `.map_err(|e| PregolyaError { .. })?`
and does NOT call `.unwrap()` on the result. The dependency's internal panics are a dependency
upgrade concern, not a pregolya code violation.

### EC-003: .unwrap() found inside a macro expansion
**Scenario:** A derive macro generated by a third-party crate includes `.unwrap()` in its
expanded output.
**Expected behavior:** The CI lint is configured to operate on pregolya-authored source files
only (not macro-generated code or `OUT_DIR`). Macro-generated panics are a separate concern
tracked via fuzz testing (CAP-019).

### EC-004: unreachable!() in exhaustive match
**Scenario:** `match category { Category::Val => ..., ... /* all 14 arms covered */ _other => unreachable!() }`.
**Expected behavior:** The `_ => unreachable!()` form shown above is NOT exempt. The wildcard
arm is trivially reachable at compile time (adding a new `Category` variant compiles fine and
silently falls into the wildcard), which means the panic path is NOT statically unreachable —
the compiler does not enforce exhaustiveness on `_`.
**Exempt (correct) form:** `match category { Category::Val => ..., Category::Auth => ...,
... /* all variants enumerated explicitly, no wildcard */ }`. When all variants are explicitly
named, adding a new variant produces a compile error at every match site — the compiler
enforces exhaustiveness without an `unreachable!()` sentinel. In this form `unreachable!()` is
not needed and should be omitted. If a legacy match requires a fallback arm, prefer returning
`Result::Err` or a defined default value over `unreachable!()`.
**Gate implication:** `cargo xtask check-no-panic` must flag `_ => unreachable!()` as a
violation. Only match arms where every named variant appears explicitly (verifiable via the
compiler's exhaustiveness check) satisfy the static-unreachability requirement. See EC-007.

### EC-005: Test-only panic via expect
**Scenario:** `#[cfg(test)] fn setup_test_graph() -> Graph { Graph::new(...).expect("test setup") }`.
**Expected behavior:** The lint does not flag this — test code is explicitly exempt. The function
is in `#[cfg(test)]` scope.

### EC-006: Programmer-error guard assertions in constructor-validation functions
**Scenario:** A library constructor validates an API precondition that is the caller's
responsibility to satisfy — for example, `PregolyaError::new()` checking that `code` matches
the `E-<COMPONENT>-NNN` format (BC-2.14.001 EC-006) or that `code`'s COMPONENT segment matches
the supplied `component` variant (BC-2.14.001 EC-007), or that a `Component::Custom` name does
not collide with a named component identifier (BC-2.14.001 EC-002).
**Policy:** A bare `assert!` macro is permitted in non-test library code ONLY when ALL FIVE
conditions are met:
  1. **Programmer-supplied precondition, not runtime data.** The assertion guards a value that
     the calling programmer is responsible to supply correctly — not a value read from external
     input, a config file, a network response, or any source where failure is a normal runtime
     outcome. Example: an error code string supplied as a string literal in the calling module
     is programmer-supplied; a config string read from a file at runtime is not.
  2. **Not expressible as a compile-time type constraint.** If the constraint could be enforced
     by the type system (e.g., a newtype wrapper that validates at construction, or an enum
     variant), that compile-time form is preferred. The assert is only justified when the
     value's correctness invariant spans multiple arguments or requires cross-field validation
     that the type system cannot express (e.g., code↔component binding, Custom-name charset).
  3. **A fallible return creates infinite regress.** Returning `Err(PregolyaError)` is
     semantically impossible when the error is "the PregolyaError being constructed is malformed"
     — the returned PregolyaError itself would need a valid code, creating infinite regress.
     This condition is specific to error-infrastructure types; it does NOT apply to ordinary
     library constructors, which must return `Result` per {PC-001}.
  4. **Documented `# Panics` section in the function's doc comment.** The function must include
     an explicit Rust doc comment `# Panics` section listing each exact precondition that
     triggers the assert, worded as "Panics if [precondition]."
  5. **Assert message cites the BC-ID and EC-ID.** The `assert!` message must cite the
     originating behavioral contract:
     `assert!(well_formed, "BC-2.14.001 EC-006: code must match E-<COMPONENT>-NNN; got {code}")`.
**Boundary — programmer-error vs runtime-data error:**
  - `PregolyaError::new("CORE-001", ...)` — `"CORE-001"` is structurally malformed → programmer
    error → assert! (all 5 conditions met per BC-2.14.001 EC-006).
  - `Config::new("")` — `""` is structurally valid UTF-8, just semantically empty → runtime data
    failure → must return `Err(PregolyaError { category: VAL, .. })`, never panic.
  - `parse_url_from_config(config_value)` — config_value comes from a file at runtime → runtime
    data failure → must return `Err`, never panic.
**Canonical examples per BC-2.14.001:**
  - BC-2.14.001 EC-002: Custom-name lowercased collision check in `PregolyaError::new()`.
  - BC-2.14.001 EC-006: Code format (`E-<COMPONENT>-NNN`) check in `PregolyaError::new()`.
  - BC-2.14.001 EC-007: Code↔component binding check in `PregolyaError::new()` and `to_problem()`.

### EC-007: check-no-panic gate discipline (unreachable! scope and programmer-error-guard scope)
**Gate requirements under this contract:**
`cargo xtask check-no-panic` must implement exactly TWO narrow exemptions — and must add a
live-violation fixture (per POL-31) confirming both exemptions and both violation forms are
correctly identified:

**Exemption 1 — exhaustive-match unreachable!():**
Permitted only in a match arm where every runtime-reachable variant is explicitly enumerated
without any wildcard arm, and the compiler's exhaustiveness check fires on a missing variant.
The gate must detect and flag `_ => unreachable!()` (wildcard arm) as a violation — this form
does not satisfy {PC-006}(a). Implementation: AST-walk to verify that in the same match block,
every arm is a named pattern (not `_` or `..`), and the enum has `#[non_exhaustive]` absent
or all variants present.

**Exemption 2 — programmer-error-guard assert!:**
Permitted only in functions whose doc comment contains a `# Panics` section AND whose `assert!`
message string literal contains a BC-ID in the form `BC-N.NN.NNN`. The gate grants the
exemption only when both syntactic conditions are verifiable from the AST; if either is absent,
the `assert!` is flagged as a violation.

**Live-violation fixture requirement (POL-31):** The `check-no-panic` xtask must ship two
test fixtures:
  - `fixtures/violation_assert_no_doc.rs`: bare `assert!` in non-test code without `# Panics`
    doc and without BC-ID message → gate must flag as violation.
  - `fixtures/violation_unreachable_wildcard.rs`: `_ => unreachable!()` wildcard form → gate
    must flag as violation.
The gate's own test suite verifies that both fixtures produce non-zero exit codes.

**Implementer error-of-record (S-1.02 pass-2 cascade):** The implementer cited "BC-2.14.003
product-owner guidance" for an unconditional `unreachable!()` exemption (exempting ALL
`unreachable!` calls regardless of match context). No such guidance exists in this BC. The
unconditional exemption is broader than {PC-006}(a) and the gate must be narrowed accordingly.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `Config::new("valid_input")` | `Ok(Config { ... })` | Happy path — fallible constructor returns Ok |
| TV-002 | `Config::new("")` where empty string is invalid | `Err(PregolyaError { category: VAL, code: "E-CORE-005", .. })` | Invalid input → Err, not panic |
| TV-003 | `cargo xtask check-no-panic` on a crate with `.unwrap()` in `src/` | Exit code non-zero; error message names the file/function | CI lint gate enforcement |
| TV-004 | `cargo xtask check-no-panic` on a crate with `.unwrap()` only in `tests/` | Exit code zero — test files are exempt | Test exemption |
| TV-005 | `Config::default()` on a type that cannot safely produce a zero-value | Compile error (`Default` not derived or implemented) | No-default enforcement |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI008-01 | Zero `.unwrap()` / `.expect()` occurrences in non-test `src/` files across all crates | CI `cargo xtask check-no-panic` | Wave 0 CI |
| VP-DI008-02 | All fallible public constructors return `Result<T, PregolyaError>` (not `T`) | CI `cargo xtask audit-constructors` or custom clippy lint | Wave 0 CI |

## Related BCs

- BC-2.14.001 — PregolyaError 2D struct (depends on: all fallible constructors propagate PregolyaError)
- BC-2.14.006 — Validation failure propagation (composes with: validation failures must use Err, not None)
- BC-2.01.001 — Typed ContentBlock construction (depends on: ContentBlock construction returns Result)
- BC-2.01.002 — Message type-safety (depends on: Message construction returns Result on invalid role)
- BC-2.04.001 — Per-task durability (depends on: checkpoint constructors return Result)

## Architecture Anchors

- All `pregolya-*/src/**/*.rs` non-test source files — `.unwrap()` / `.expect()` prohibition
- CI: `cargo xtask check-no-panic` target (to be created)

## Story Anchor

S-1.02

## VP Anchors

- VP-DI008-01, VP-DI008-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (PregolyaError 2D Struct)") per capabilities-p0.md §CAP-016 — CAP-016 explicitly states "No `.unwrap()` or `.expect()` in non-test code; CI lint gate enforces this. All library constructors return `Result`." This BC is the direct enforcement mechanism for that statement |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract) |
| NE References | NE-07 (adk-rust `.expect()` panic in WASM engine init is the counter-example) |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | CI lint, U (unit) |
| Module | pregolya-* (all crates) / xtask (lint gate) |
