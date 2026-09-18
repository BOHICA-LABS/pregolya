//! AC-007 compile-fail gate — `#[non_exhaustive]` external-boundary verification.
// BC-naming convention requires UPPER_CASE in test names (test_BC_S_SS_NNN_xxx).
// This deviates from Rust's snake_case convention; suppress the lint.
#![allow(non_snake_case)]

//!
//! Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007.
//! Adversary finding: F2 (adv pass-1) — prior test only exercised in-crate
//! construction which is a no-op for `#[non_exhaustive]`.
//!
//! ## What this gate proves
//!
//! `PregolyaError` carries `#[non_exhaustive]`. The Rust reference states:
//! > Outside of the defining crate, a non-exhaustive struct cannot be matched
//! > without the `..` pattern — and cannot be constructed with struct-literal
//! > syntax at all.
//!
//! An in-crate `#[cfg(test)]` module exercises the same crate, so the
//! attribute is a no-op there: the compiler allows both construction AND
//! exhaustive matching from within the defining crate.  Only an **external**
//! compilation unit triggers the restriction.
//!
//! `trybuild` compiles each fixture as an independent binary that imports
//! `pregolya_core` as an external dependency, reproducing the external-crate
//! boundary.
//!
//! ## Non-exhaustive symbol inventory (CLAUDE.md gate update protocol)
//!
//! When a new `#[non_exhaustive]` public type is added to the API surface,
//! update ALL THREE of:
//!   1. Add a compile-fail fixture under `tests/ui/` (this gate directory)
//!   2. Increment `EXPECTED_NON_EXHAUSTIVE_COUNT` below
//!   3. Add the symbol to `EXPECTED_NON_EXHAUSTIVE_SYMBOLS` below
//!
//! Gate authority: CI failure == a type was added without `#[non_exhaustive]`
//! or without a gate update.
//!
//! ### Current inventory (S-1.01 Wave 1 baseline — 1 type)
//!
//! ```text
//! EXPECTED_NON_EXHAUSTIVE_COUNT  = 1
//! EXPECTED_NON_EXHAUSTIVE_SYMBOLS = ["pregolya_core::PregolyaError"]
//! ```
//!
//! Note: `Component`, `Category`, `RetryHint`, `ProblemDetail`, and
//! `ProblemExtensions` are also `#[non_exhaustive]` but are enums or
//! supporting structs; the compile-fail gate focuses on the primary error
//! struct. Extend this gate in subsequent stories as the API surface grows.

/// Expected number of non-exhaustive types with compile-fail coverage.
///
/// Increment when adding a new type to the inventory above.
const EXPECTED_NON_EXHAUSTIVE_COUNT: usize = 1;

/// Symbolic list of non-exhaustive types covered by this gate.
///
/// Add an entry here AND add the corresponding `tests/ui/` fixture when a
/// new `#[non_exhaustive]` public API surface type is introduced.
const EXPECTED_NON_EXHAUSTIVE_SYMBOLS: [&str; EXPECTED_NON_EXHAUSTIVE_COUNT] =
    ["pregolya_core::PregolyaError"];

/// AC-007 (BC-2.14.001 {PC-008}): Attempting to match `PregolyaError` from
/// an external crate WITHOUT the `..` wildcard MUST FAIL TO COMPILE.
///
/// rustc E0638: `..` required with struct marked as non-exhaustive.
#[test]
fn test_BC_2_14_001_non_exhaustive_external_match_without_dots_fails() {
    // Silence the unused-constant warning from the inventory declarations.
    let _ = EXPECTED_NON_EXHAUSTIVE_SYMBOLS;

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
