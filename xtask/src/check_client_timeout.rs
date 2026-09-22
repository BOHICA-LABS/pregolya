//! CI lint gate: reject `reqwest::Client::new()` and `ClientBuilder` without
//! `.timeout()` in library source files.
//!
//! Implements `cargo xtask check-client-timeout` (BC-2.14.004 {PC-003},
//! VP-DI009-01).
//!
//! # Scanning rules
//!
//! - Scans `crates/**/*.rs` for `reqwest::Client::new()` (fully qualified) and
//!   `Client::new()` (unqualified) in non-test source.
//! - Also scans for `ClientBuilder` chains that call `.build()` without a
//!   preceding `.timeout(d)` call where `d > Duration::ZERO`.
//! - Files under `tests/` directories, `#[cfg(test)]` blocks, and files ending
//!   in `_test.rs`/`_tests.rs` are fully exempt (BC-2.14.004 {INV-003}).
//! - Exits non-zero when any violation is found; exits 0 on a clean scan.

/// Entry point for `cargo xtask check-client-timeout`.
///
/// Scans `crates/**/*.rs` using token-tree analysis to detect `Client::new()`
/// and `ClientBuilder` chains missing `.timeout(...)`. Exits non-zero on any
/// violation (BC-2.14.004 {PC-003}).
pub fn run() {
    todo!(
        "BC-2.14.004 PC-003: \
         implement file-by-file proc_macro2 token scan for Client::new() \
         and ClientBuilder chains missing .timeout(); exit non-zero on violations"
    )
}

/// Scans a single Rust source file (as a string) for `Client::new()` or
/// `ClientBuilder` chains that call `.build()` without a preceding `.timeout(d)`.
///
/// Returns a `Vec<String>` of human-readable violation messages. Returns an
/// empty `Vec` when the source is clean.
///
/// Called by `run()` per-file and exposed as `pub(crate)` so unit tests in
/// `xtask/src/tests.rs` can verify scanner behavior directly.
#[allow(dead_code)] // called only from tests.rs via main.rs #[cfg(test)] re-export; todo!() stub until S-1.02 implemented
pub(crate) fn scan_for_timeout_violations_in_source(_src: &str, _path: &str) -> Vec<String> {
    todo!(
        "BC-2.14.004 PC-003: \
         implement proc_macro2 token-tree scan for Client::new() and \
         ClientBuilder chains missing .timeout(); return Vec<String> of violations"
    )
}
