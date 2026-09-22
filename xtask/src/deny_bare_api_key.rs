//! CI lint gate: reject bare API key string literals in library source files.
//!
//! Implements `cargo xtask deny-bare-api-key` (BC-2.14.005 {PC-006},
//! VP-DI010-02).
//!
//! # Scanning rules
//!
//! - Scans `crates/**/*.rs` for string literals matching provider key prefixes
//!   such as `sk-` (OpenAI), `sk-ant-` (Anthropic), and similar patterns in
//!   non-test source code (BC-2.14.005 {PC-006}).
//! - Files under `tests/` directories and `#[cfg(test)]` blocks are exempt
//!   (test fixtures may reference synthetic key strings for verification).
//! - Exits non-zero when any bare key pattern is found; exits 0 on a clean scan.

/// Entry point for `cargo xtask deny-bare-api-key`.
///
/// Scans `crates/**/*.rs` for bare API key string literals matching known
/// provider prefixes (`sk-`, `sk-ant-`, etc.) in non-test source. Exits non-zero
/// on any violation (BC-2.14.005 {PC-006}).
pub fn run() {
    todo!(
        "BC-2.14.005 PC-006: \
         implement file-by-file scan for bare API key string literals \
         (sk-, sk-ant-, and similar prefixes) in non-test source; \
         exit non-zero on violations"
    )
}
