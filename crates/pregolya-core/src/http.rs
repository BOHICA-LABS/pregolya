//! HTTP client factory for the pregolya workspace.
//!
//! Provides [`build_client`] — the single authorised path for constructing an
//! outbound `reqwest::Client` in pregolya library code. Every client produced
//! by this factory carries a non-zero `.timeout()` (default 30 s per BC-2.14.004
//! {PC-001}, {PC-002}).
//!
//! # Prohibited patterns
//!
//! - `reqwest::Client::new()` is forbidden in non-test library source
//!   (BC-2.14.004 {PC-003}).  Use [`build_client`] instead.
//! - `reqwest::ClientBuilder::new().build()` without a `.timeout(d)` call where
//!   `d > Duration::ZERO` is forbidden (BC-2.14.004 {PC-001}).
//!
//! # Timeout behaviour
//!
//! When the timeout fires the HTTP client returns an error. The pregolya adapter
//! that calls the provider converts it to:
//! `Err(PregolyaError { category: TIMEOUT, code: "E-PROV-002",
//!  message: "ProviderTimeout: request timed out after 30s", .. })`
//! per BC-2.14.004 {PC-005}.

use crate::error::PregolyaError;

/// Constructs an outbound `reqwest::Client` with a 30-second request timeout.
///
/// This is the authorised HTTP client factory for pregolya library crates.
/// No provider or adapter crate may use `reqwest::Client::new()` or a
/// `ClientBuilder` without `.timeout(...)` in production code (BC-2.14.004).
///
/// # Default timeout
///
/// `Duration::from_secs(30)` per BC-2.14.004 {PC-002}. Deviations (e.g. extended
/// timeout for streaming inference) must be documented with a comment at the
/// call site citing the rationale.
///
/// # Errors
///
/// Returns `Err(PregolyaError { category: Transport })` if the underlying
/// `reqwest::ClientBuilder::build()` fails (rare; typically a TLS initialisation
/// error on misconfigured systems).
pub fn build_client() -> Result<reqwest::Client, PregolyaError> {
    todo!(
        "BC-2.14.004 PC-001 + PC-002: \
         ClientBuilder::new().timeout(Duration::from_secs(30)).build() \
         and map reqwest::Error to PregolyaError {{ category: Transport }}"
    )
}
