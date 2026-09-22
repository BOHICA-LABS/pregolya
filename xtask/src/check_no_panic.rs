//! CI lint gate: reject `.unwrap()` and `.expect()` in library source files.
//!
//! Implements `cargo xtask check-no-panic` (BC-2.14.003 {PC-004}, VP-DI008-01).
//!
//! # Scanning rules
//!
//! - Scans `crates/**/*.rs` for `.unwrap()` and `.expect(...)` outside
//!   `#[cfg(test)]` scopes.
//! - Files under `tests/` directories, files ending in `_test.rs`/`_tests.rs`,
//!   and files ending in `/tests.rs` are fully exempt (BC-2.14.003 {INV-004}).
//! - `debug_assert!()` is NOT flagged — it compiles out in release mode
//!   (BC-2.14.003 {INV-003}).
//! - Exits non-zero when any violation is found; exits 0 on a clean scan.

/// Entry point for `cargo xtask check-no-panic`.
///
/// Scans `crates/**/*.rs` using token-tree analysis to detect `.unwrap()` and
/// `.expect(...)` calls outside `#[cfg(test)]` blocks. Exits non-zero on any
/// violation (BC-2.14.003 {PC-004}).
pub fn run() {
    todo!(
        "BC-2.14.003 PC-004: \
         implement file-by-file proc_macro2 token scan for .unwrap()/.expect() \
         outside #[cfg(test)] blocks; exit non-zero on violations"
    )
}

/// Scans a single Rust source file (as a string) for `.unwrap()` / `.expect(...)`
/// calls outside `#[cfg(test)]` blocks.
///
/// Returns a `Vec<String>` of human-readable violation messages, one per
/// detected call site. Returns an empty `Vec` when the source is clean.
///
/// Called by `run()` per-file and exposed as `pub(crate)` so unit tests in
/// `xtask/src/tests.rs` can verify scanner behavior directly.
#[allow(dead_code)] // called only from tests.rs via main.rs #[cfg(test)] re-export; todo!() stub until S-1.02 implemented
pub(crate) fn scan_for_panics_in_source(_src: &str, _path: &str) -> Vec<String> {
    todo!(
        "BC-2.14.003 PC-004: \
         implement proc_macro2 token-tree scan for .unwrap()/.expect() \
         outside #[cfg(test)] groups; return Vec<String> of violation lines"
    )
}
