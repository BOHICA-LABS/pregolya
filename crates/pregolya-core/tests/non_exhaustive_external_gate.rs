//! AC-007 compile-fail gate — `#[non_exhaustive]` external-boundary verification.
// BC-naming convention requires UPPER_CASE in test names (test_BC_S_SS_NNN_xxx).
// This deviates from Rust's snake_case convention; suppress the lint.
#![allow(non_snake_case)]

//!
//! Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007.
//! Adversary findings: F1 (adv pass-2; POL-42 — extend gate to all 6 types),
//!                     OBS-1 (layout reconciliation note).
//!
//! ## What this gate proves
//!
//! Every public `#[non_exhaustive]` type introduced by S-1.01 has compile-fail
//! coverage from an external-crate perspective. The Rust reference states:
//!   - Non-exhaustive STRUCT: cannot be matched/destructured without `..` outside
//!     the defining crate (E0638).
//!   - Non-exhaustive ENUM: cannot be matched exhaustively without a wildcard `_`
//!     arm outside the defining crate (E0004).
//!
//! An in-crate `#[cfg(test)]` module is in the same crate, so the attribute is
//! a no-op there: the compiler permits both construction and exhaustive matching.
//! Only an **external** compilation unit triggers the restriction.
//!
//! `trybuild` compiles each fixture as an independent binary that imports
//! `pregolya_core` as an external dependency, reproducing the external-crate
//! boundary.
//!
//! ## Layout note (OBS-1 reconciliation)
//!
//! CLAUDE.md §`#[non_exhaustive] on public API surface types` documents the
//! gate pattern as `tests/external/<gate-name>/`. This crate uses trybuild's
//! idiomatic `tests/<runner>.rs` + `tests/ui/` layout (the runner file is this
//! file; the fixtures live in `tests/ui/`). These two layouts are functionally
//! equivalent: trybuild treats `tests/ui/` as its own `tests/external/`
//! namespace, compiling each fixture in isolation as an independent binary.
//! The `tests/ui/` layout is the concrete realization of the CLAUDE.md pattern
//! for this crate — no relocation required.
//!
//! ## Non-exhaustive symbol inventory (CLAUDE.md gate update protocol)
//!
//! When a new `#[non_exhaustive]` public type is added to the API surface,
//! update ALL THREE of:
//!   1. Add compile-fail + pass fixture pair(s) under `tests/ui/`
//!   2. Increment `EXPECTED_NON_EXHAUSTIVE_COUNT` below
//!   3. Add the symbol to `EXPECTED_NON_EXHAUSTIVE_SYMBOLS` below
//!
//! Gate authority: CI failure == a type was added without `#[non_exhaustive]`
//! or without a gate update.
//!
//! ### Current inventory (S-1.01 Wave 1 — 6 types; adv F1/POL-42 complete)
//!
//! ```text
//! EXPECTED_NON_EXHAUSTIVE_COUNT  = 6
//! EXPECTED_NON_EXHAUSTIVE_SYMBOLS = [
//!   "pregolya_core::PregolyaError",
//!   "pregolya_core::Component",
//!   "pregolya_core::Category",
//!   "pregolya_core::RetryHint",
//!   "pregolya_core::ProblemDetail",
//!   "pregolya_core::error::ProblemExtensions",
//! ]
//! ```

/// Expected number of non-exhaustive types with compile-fail coverage.
///
/// Increment when adding a new type to the inventory above.
const EXPECTED_NON_EXHAUSTIVE_COUNT: usize = 6;

/// Symbolic list of non-exhaustive types covered by this gate.
///
/// Add an entry here AND add the corresponding `tests/ui/` fixture pair when a
/// new `#[non_exhaustive]` public API surface type is introduced.
const EXPECTED_NON_EXHAUSTIVE_SYMBOLS: [&str; EXPECTED_NON_EXHAUSTIVE_COUNT] = [
    "pregolya_core::PregolyaError",
    "pregolya_core::Component",
    "pregolya_core::Category",
    "pregolya_core::RetryHint",
    "pregolya_core::ProblemDetail",
    "pregolya_core::error::ProblemExtensions",
];

// ── Inventory load-bearing runtime gate (F1) ─────────────────────────────────

/// Runtime gate: verifies that `EXPECTED_NON_EXHAUSTIVE_COUNT` and
/// `EXPECTED_NON_EXHAUSTIVE_SYMBOLS` match the actual source.
///
/// 1. Reads `crates/pregolya-core/src/error.rs` and counts `#[non_exhaustive]` occurrences.
/// 2. Asserts the count equals `EXPECTED_NON_EXHAUSTIVE_COUNT`.
/// 3. For each symbol in `EXPECTED_NON_EXHAUSTIVE_SYMBOLS`, asserts it is mentioned in the source.
/// 4. Asserts the number of `_fails.rs` fixtures in `tests/ui/` equals the count.
///
/// This makes the inventory constants load-bearing: adding a `#[non_exhaustive]` type
/// without updating the constants will fail this test.
#[test]
fn test_non_exhaustive_inventory_matches_source() {
    // Cargo runs integration tests with cwd = package root (crates/pregolya-core/).
    let source = std::fs::read_to_string("src/error.rs")
        .expect("src/error.rs must be readable for the non-exhaustive inventory gate");

    // Count #[non_exhaustive] occurrences on actual Rust attribute lines only.
    // Doc comment lines (starting with `///` or `//!`) are excluded — they may
    // mention `#[non_exhaustive]` in explanatory prose without being attributes.
    let actual_count = source
        .lines()
        .filter(|line| {
            let trimmed = line.trim();
            !trimmed.starts_with("///") && !trimmed.starts_with("//!")
        })
        .filter(|line| line.contains("#[non_exhaustive]"))
        .count();
    assert_eq!(
        actual_count, EXPECTED_NON_EXHAUSTIVE_COUNT,
        "EXPECTED_NON_EXHAUSTIVE_COUNT ({EXPECTED_NON_EXHAUSTIVE_COUNT}) does not match \
         actual #[non_exhaustive] attribute occurrences in error.rs ({actual_count}). \
         Update EXPECTED_NON_EXHAUSTIVE_COUNT and add a fixture pair."
    );

    // Verify each symbol in the inventory appears in the source
    for sym in &EXPECTED_NON_EXHAUSTIVE_SYMBOLS {
        // The symbol names are qualified (e.g. "pregolya_core::Component") —
        // strip to the bare type name for source-file lookup.
        let bare_name = sym.rsplit("::").next().unwrap_or(sym);
        assert!(
            source.contains(bare_name),
            "Inventory symbol '{sym}' (bare name: '{bare_name}') not found in error.rs source. \
             Update EXPECTED_NON_EXHAUSTIVE_SYMBOLS to match the actual public types."
        );
    }

    // Count _fails.rs fixtures in tests/ui/ — must equal the inventory count
    // Path is relative to the package root (crates/pregolya-core/).
    let ui_dir = std::fs::read_dir("tests/ui/").expect("tests/ui/ must be readable");
    let fails_count = ui_dir
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().ends_with("_fails.rs"))
        .count();
    assert_eq!(
        fails_count, EXPECTED_NON_EXHAUSTIVE_COUNT,
        "Number of _fails.rs fixtures in tests/ui/ ({fails_count}) does not match \
         EXPECTED_NON_EXHAUSTIVE_COUNT ({EXPECTED_NON_EXHAUSTIVE_COUNT}). \
         Add a compile-fail fixture for any new non-exhaustive type."
    );

    println!("non_exhaustive gate: {} types validated", actual_count);
}

// ── PregolyaError (struct) ────────────────────────────────────────────────────

/// AC-007 (BC-2.14.001 {PC-008}): Attempting to match `PregolyaError` from
/// an external crate WITHOUT the `..` wildcard MUST FAIL TO COMPILE.
///
/// rustc E0638: `..` required with struct marked as non-exhaustive.
#[test]
fn test_BC_2_14_001_non_exhaustive_external_match_without_dots_fails() {
    let t = trybuild::TestCases::new();
    // This fixture must produce a compile error (E0638).
    t.compile_fail("tests/ui/pregolya_error_match_without_dots_fails.rs");
}

/// AC-007 (BC-2.14.001 {PC-008}): Matching `PregolyaError` from an external
/// crate WITH the `..` wildcard MUST COMPILE SUCCESSFULLY.
///
/// Proves the boundary precisely: only the missing `..` causes the error.
#[test]
fn test_BC_2_14_001_non_exhaustive_external_match_with_dots_passes() {
    let t = trybuild::TestCases::new();
    // This fixture must compile without errors.
    t.pass("tests/ui/pregolya_error_match_with_dots_passes.rs");
}

// ── ProblemDetail (struct) ────────────────────────────────────────────────────

/// AC-007 (BC-2.14.001 {PC-008}): Attempting to match `ProblemDetail` from
/// an external crate WITHOUT the `..` wildcard MUST FAIL TO COMPILE.
///
/// rustc E0638: `..` required with struct marked as non-exhaustive.
#[test]
fn test_BC_2_14_001_non_exhaustive_problem_detail_without_dots_fails() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/ui/problem_detail_match_without_dots_fails.rs");
}

/// AC-007 (BC-2.14.001 {PC-008}): Matching `ProblemDetail` from an external
/// crate WITH the `..` wildcard MUST COMPILE SUCCESSFULLY.
#[test]
fn test_BC_2_14_001_non_exhaustive_problem_detail_with_dots_passes() {
    let t = trybuild::TestCases::new();
    t.pass("tests/ui/problem_detail_match_with_dots_passes.rs");
}

// ── ProblemExtensions (struct) ────────────────────────────────────────────────

/// AC-007 (BC-2.14.001 {PC-008}): Attempting to match `ProblemExtensions` from
/// an external crate WITHOUT the `..` wildcard MUST FAIL TO COMPILE.
///
/// rustc E0638: `..` required with struct marked as non-exhaustive.
/// `ProblemExtensions` is at `pregolya_core::error::ProblemExtensions`.
#[test]
fn test_BC_2_14_001_non_exhaustive_problem_extensions_without_dots_fails() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/ui/problem_extensions_match_without_dots_fails.rs");
}

/// AC-007 (BC-2.14.001 {PC-008}): Matching `ProblemExtensions` from an external
/// crate WITH the `..` wildcard MUST COMPILE SUCCESSFULLY.
#[test]
fn test_BC_2_14_001_non_exhaustive_problem_extensions_with_dots_passes() {
    let t = trybuild::TestCases::new();
    t.pass("tests/ui/problem_extensions_match_with_dots_passes.rs");
}

// ── Component (enum) ─────────────────────────────────────────────────────────

/// AC-007 (BC-2.14.001 {PC-008}): Attempting to match `Component` from
/// an external crate WITHOUT a wildcard `_ => {}` arm MUST FAIL TO COMPILE.
///
/// Even when all currently-defined variants are listed, the compiler requires
/// a wildcard for non-exhaustive enums outside the defining crate (E0004).
#[test]
fn test_BC_2_14_001_non_exhaustive_component_without_wildcard_fails() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/ui/component_match_without_wildcard_fails.rs");
}

/// AC-007 (BC-2.14.001 {PC-008}): Matching `Component` from an external crate
/// WITH a wildcard `_ => {}` arm MUST COMPILE SUCCESSFULLY.
#[test]
fn test_BC_2_14_001_non_exhaustive_component_with_wildcard_passes() {
    let t = trybuild::TestCases::new();
    t.pass("tests/ui/component_match_with_wildcard_passes.rs");
}

// ── Category (enum) ──────────────────────────────────────────────────────────

/// AC-007 (BC-2.14.001 {PC-008}): Attempting to match `Category` from
/// an external crate WITHOUT a wildcard `_ => {}` arm MUST FAIL TO COMPILE.
///
/// Even when all currently-defined variants are listed, the compiler requires
/// a wildcard for non-exhaustive enums outside the defining crate (E0004).
#[test]
fn test_BC_2_14_001_non_exhaustive_category_without_wildcard_fails() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/ui/category_match_without_wildcard_fails.rs");
}

/// AC-007 (BC-2.14.001 {PC-008}): Matching `Category` from an external crate
/// WITH a wildcard `_ => {}` arm MUST COMPILE SUCCESSFULLY.
#[test]
fn test_BC_2_14_001_non_exhaustive_category_with_wildcard_passes() {
    let t = trybuild::TestCases::new();
    t.pass("tests/ui/category_match_with_wildcard_passes.rs");
}

// ── RetryHint (enum) ─────────────────────────────────────────────────────────

/// AC-007 (BC-2.14.001 {PC-008}): Attempting to match `RetryHint` from
/// an external crate WITHOUT a wildcard `_ => {}` arm MUST FAIL TO COMPILE.
///
/// Even when all currently-defined variants are listed, the compiler requires
/// a wildcard for non-exhaustive enums outside the defining crate (E0004).
#[test]
fn test_BC_2_14_001_non_exhaustive_retry_hint_without_wildcard_fails() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/ui/retry_hint_match_without_wildcard_fails.rs");
}

/// AC-007 (BC-2.14.001 {PC-008}): Matching `RetryHint` from an external crate
/// WITH a wildcard `_ => {}` arm MUST COMPILE SUCCESSFULLY.
#[test]
fn test_BC_2_14_001_non_exhaustive_retry_hint_with_wildcard_passes() {
    let t = trybuild::TestCases::new();
    t.pass("tests/ui/retry_hint_match_with_wildcard_passes.rs");
}
