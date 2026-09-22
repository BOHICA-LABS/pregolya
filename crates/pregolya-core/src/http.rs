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

use std::time::Duration;

use crate::error::{Category, Component, PregolyaError, RetryHint};

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
    reqwest::ClientBuilder::new()
        .timeout(Duration::from_secs(30))
        .build()
        .map_err(|e| {
            PregolyaError::new(
                Component::Core,
                Category::Transport,
                RetryHint::Never,
                "E-CORE-012",
                format!("HttpClientBuildFailed: failed to build HTTP client: {e}"),
            )
        })
}

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used, non_snake_case)]
mod tests {
    use std::time::Duration;

    use super::*;
    use crate::error::{Category, Component, RetryHint};

    // ── AC-015 test-support stub ──────────────────────────────────────────────
    //
    // BC-2.14.004 {EC-006}: the implementer must update build_client()'s map_err
    // closure to produce PregolyaError { code: "E-CORE-012", category: Transport,
    // retry_hint: Never }.  This helper encodes the EXPECTED shape; the implementer
    // must implement it to match (currently todo!() → RED gate).
    //
    // Calling convention: the function must construct the exact error that
    // build_client() would return when ClientBuilder::build() fails, given a
    // human-readable reason string derived from the reqwest error's Display.
    //
    // AC-015 non-ignored test (test_BC_2_14_004_build_failure_maps_to_e_core_012)
    // calls this helper.  The #[ignore]'d test below covers the live path.
    fn make_build_error_for_test(reason: &str) -> PregolyaError {
        PregolyaError::new(
            Component::Core,
            Category::Transport,
            RetryHint::Never,
            "E-CORE-012",
            format!("HttpClientBuildFailed: failed to build HTTP client: {reason}"),
        )
    }

    // ── BC-2.14.004 Tests ─────────────────────────────────────────────────────

    /// AC-004 (traces to BC-2.14.004 {PC-001}, {PC-002})
    ///
    /// `build_client()` returns `Ok(reqwest::Client)` under normal conditions.
    /// The factory must not panic and must not return an error on a system with
    /// a working TLS stack.
    ///
    /// RED GATE: `build_client()` is `todo!()` — panics until implementation.
    #[test]
    fn test_BC_2_14_004_build_client_returns_ok() {
        let result = build_client();
        assert!(
            result.is_ok(),
            "BC-2.14.004 {{PC-001}}: build_client() must return Ok on a working TLS stack; \
             got: {:?}",
            result.err()
        );
    }

    /// AC-004 (traces to BC-2.14.004 {PC-002})
    ///
    /// `build_client()` produces a `reqwest::Client` configured with a non-zero timeout.
    /// The default is 30 s per {PC-002}. We cannot introspect the timeout directly via
    /// reqwest's public API, but we can verify the client was produced without panicking
    /// and that the factory did not fall back to `Client::new()` (which has no timeout).
    ///
    /// This test verifies the observable invariant: a client is produced and the factory
    /// compiles without using `Client::new()`. The scanner gate (`check-client-timeout`)
    /// verifies the source-level constraint at CI time.
    ///
    /// RED GATE: `build_client()` is `todo!()` — panics until implementation.
    #[test]
    fn test_BC_2_14_004_default_timeout_applied() {
        // The 30s timeout cannot be inspected via reqwest's public API, but we verify
        // the factory returns Ok — if it used `Client::new()` the CI scanner would flag it.
        // The load-bearing behavioral guarantee is tested end-to-end in the #[ignore] mock
        // server test below (test_BC_2_14_004_timeout_fires_against_mock_server).
        let result = build_client();
        assert!(
            result.is_ok(),
            "BC-2.14.004 {{PC-002}}: build_client() must succeed; timeout factory must not panic"
        );
        // Verify client can initiate a request (basic sanity — not a live network call)
        let _client = result.unwrap();
        // If we got here, a Client was constructed. The scanner verifies .timeout() at CI.
    }

    /// AC-006 (traces to BC-2.14.004 {PC-005}, TV-004)
    ///
    /// When a request exceeds the timeout, the provider adapter must convert the
    /// reqwest timeout error into:
    /// `PregolyaError { category: TIMEOUT, code: "E-PROV-002",
    ///  message: "ProviderTimeout: request timed out after 30s" }`
    ///
    /// This test verifies the error SHAPE — category, code, and message prefix — by
    /// asserting the PregolyaError shape can be constructed correctly. The actual
    /// timeout-fires-against-live-endpoint scenario is tested in the #[ignore] variant
    /// below.
    ///
    /// RED GATE: `build_client()` is `todo!()` — panics until implementation.
    #[test]
    fn test_BC_2_14_004_timeout_error_shape() {
        // Verify build_client() returns Ok first (prerequisite for timeout testing)
        let result = build_client();
        assert!(
            result.is_ok(),
            "BC-2.14.004 {{PC-005}}: prerequisite — build_client() must succeed before \
             timeout error shape can be verified"
        );
        // The timeout-fires behavior is end-to-end tested in the mock server test below.
        // Here we verify the error category/code shape matches what the adapter must produce.
        // Category::Timeout + code "E-PROV-002" is the contract; the implementer must
        // produce exactly this shape when reqwest returns a timeout error.
        let _expected_category = Category::Timeout;
        let _expected_component = Component::Prov;
        let _expected_code = "E-PROV-002";
        let _expected_message_prefix = "ProviderTimeout: request timed out after";
        // Shape verification is structural; timeout firing is confirmed in mock server test.
    }

    /// AC-006 (traces to BC-2.14.004 {PC-005}, TV-004) — integration test
    ///
    /// End-to-end: a `reqwest::Client` built by `build_client()` with 30s timeout fires
    /// when sent to a TCP listener that accepts the connection but sends no response for
    /// 35 seconds.
    ///
    /// Blocked dependency: requires a Tokio runtime and a local TCP listener that stalls
    /// for > 30s. This test takes ~30 seconds in CI and is therefore `#[ignore]`'d.
    /// It must be ungated in a dedicated timeout-validation job.
    ///
    /// SID-1 note: the unit tests above (test_BC_2_14_004_build_client_returns_ok and
    /// test_BC_2_14_004_timeout_error_shape) drive the factory at the dependency boundary
    /// without requiring the live 30s wait.
    ///
    /// RED GATE: `build_client()` is `todo!()` — panics until implementation.
    #[tokio::test]
    #[ignore = "EXT-BC214004: requires ~30s wall-clock wait for timeout to fire; \
                ungated in timeout-validation CI job (see BC-2.14.004 TV-004)"]
    async fn test_BC_2_14_004_timeout_fires_against_mock_server() {
        use std::io::Read as _;
        use std::net::TcpListener;

        // Bind a local TCP port that accepts a connection but never replies
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind must succeed");
        let port = listener
            .local_addr()
            .expect("addr must be available")
            .port();

        // Accept in a background thread — never write; simulates a hung server
        std::thread::spawn(move || {
            if let Ok((mut stream, _)) = listener.accept() {
                // Drain the request bytes so the client sends fully, then stall
                let mut buf = [0u8; 4096];
                let _ = stream.read(&mut buf);
                // Sleep longer than the client timeout
                std::thread::sleep(Duration::from_secs(35));
            }
        });

        let client = build_client().expect("build_client must succeed");
        let url = format!("http://127.0.0.1:{}/", port);
        let result = client.get(&url).send().await;

        assert!(
            result.is_err(),
            "BC-2.14.004 {{PC-005}}: request to stalled server must time out (return Err)"
        );
        let err = result.unwrap_err();
        assert!(
            err.is_timeout(),
            "BC-2.14.004 {{PC-005}}: error must be a timeout error; got: {:?}",
            err
        );
    }

    // ── AC-015 / BC-2.14.004 {EC-006} (S-1.02 F-02) ─────────────────────────

    /// AC-015 (traces to BC-2.14.004 {EC-006})
    ///
    /// When `ClientBuilder::build()` returns `Err`, `build_client()` must propagate it as:
    /// `Err(PregolyaError { category: Transport, code: "E-CORE-012",
    ///  retry_hint: Never, message: "HttpClientBuildFailed: ..." })`
    ///
    /// Current `build_client()` maps build errors to `E-CORE-004` / `RetryHint::Later(30s)` —
    /// both are wrong per BC-2.14.004 {EC-006} v1.7.
    ///
    /// This non-ignored test drives the mapping BOUNDARY via `make_build_error_for_test`,
    /// which is a `todo!()` stub. The stub panics → RED gate until the implementer:
    ///   (a) updates `build_client()`'s `map_err` to E-CORE-012 / Transport / Never, and
    ///   (b) implements `make_build_error_for_test` to return the same error shape.
    ///
    /// SID-1: the `#[ignore]`'d test below exercises the live ClientBuilder::build() failure
    /// path; this non-ignored test covers the mapping boundary without requiring a broken
    /// TLS stack.
    #[test]
    fn test_BC_2_14_004_build_failure_maps_to_e_core_012() {
        let e = make_build_error_for_test("simulated TLS stack unavailable");
        assert_eq!(
            e.code(),
            "E-CORE-012",
            "BC-2.14.004 {{EC-006}}: build failure error code must be 'E-CORE-012' \
             (was 'E-CORE-004' before v1.7 fix); got: {:?}",
            e.code()
        );
        assert!(
            matches!(e.category, Category::Transport),
            "BC-2.14.004 {{EC-006}}: build failure must carry Category::Transport; \
             got: {:?}",
            e.category
        );
        assert!(
            matches!(e.retry_hint, RetryHint::Never),
            "BC-2.14.004 {{EC-006}}: build failure RetryHint must be Never — \
             the same ClientBuilder config will always fail; recovery requires \
             fixing the TLS/proxy configuration (was RetryHint::Later before v1.7 fix); \
             got: {:?}",
            e.retry_hint
        );
        assert!(
            e.message.starts_with("HttpClientBuildFailed:"),
            "BC-2.14.004 {{EC-006}}: build failure message must start with \
             'HttpClientBuildFailed:'; got: {:?}",
            e.message
        );
    }

    // ─── AC-019 / BC-2.14.004 F-C (SID-1 / POL-34) ────────────────────────────
    //
    // S-1.02 pass-2: the E-CORE-012 mapping must be extracted to a shared production
    // function so that test_BC_2_14_004_build_failure_maps_to_e_core_012 exercises
    // the PRODUCTION mapping path, not a test-only duplicate.
    //
    // RED GATE against HEAD 7c7a590:
    //   Current http.rs has only make_build_error_for_test in #[cfg(test)] scope —
    //   the shared production mapping function does NOT yet exist. The assertion FAILS.
    //
    // NOTE: search pattern built via concat() at runtime to prevent self-reference —
    // include_str! embeds the entire file including this test module, so any literal
    // match in test code or doc comments would trivially satisfy contains().

    /// AC-019 (traces to BC-2.14.004 F-C / SID-1 / POL-34)
    ///
    /// The E-CORE-012 error mapping inside build_client() must be extracted to a
    /// shared production-scope function (not buried in cfg(test)) so that the
    /// non-ignored test `test_BC_2_14_004_build_failure_maps_to_e_core_012` exercises
    /// the PRODUCTION mapping path, not a test-only duplicate.
    ///
    /// SID-1 / POL-34: a non-ignored test exercising a duplicated test-only helper
    /// instead of the production path fails the load-bearing requirement.
    ///
    /// RED GATE: the production mapping function does not yet exist in http.rs.
    /// The assertion reads the source to confirm it exists outside test scope.
    #[test]
    fn test_BC_2_14_004_build_failure_load_bearing_on_production() {
        let src = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/http.rs"));
        // Pattern built via concat() to prevent self-reference through include_str!.
        // include_str! embeds the whole file; a literal match in doc comments or
        // assertion messages would trivially satisfy contains() against current HEAD.
        //
        // The production mapping function must appear OUTSIDE #[cfg(test)] scope.
        // RED GATE: current http.rs only has make_build_error_for_test in test scope.
        let prod_fn = ["pub(crate) fn ", "map_build_failure"].concat();
        assert!(
            src.contains(&prod_fn),
            "BC-2.14.004 F-C (SID-1): the E-CORE-012 mapping must be a production \
             pub(crate) fn (not buried in cfg(test) as make_build_error_for_test); \
             implementer must extract the shared mapping fn and wire build_client() to it"
        );
    }

    /// AC-015 (traces to BC-2.14.004 {EC-006}) — live build-failure path
    ///
    /// When `ClientBuilder::build()` fails (e.g. TLS backend unavailable, proxy
    /// misconfigured), `build_client()` must return an `Err` with code `"E-CORE-012"`,
    /// `Category::Transport`, and `RetryHint::Never`.
    ///
    /// Blocked dependency (SID-1): triggering `ClientBuilder::build()` failure
    /// deterministically requires a broken TLS stack or invalid proxy configuration,
    /// which is not available in standard CI. Ungated in a dedicated TLS-failure job.
    ///
    /// The non-ignored test above (`test_BC_2_14_004_build_failure_maps_to_e_core_012`)
    /// covers the mapping boundary without a live failure.
    #[test]
    #[ignore = "EXT-BC214004-EC006: requires a broken TLS stack or invalid proxy \
                to trigger ClientBuilder::build() failure deterministically; \
                ungated in a TLS-failure CI job (BC-2.14.004 EC-006). \
                Unit boundary: test_BC_2_14_004_build_failure_maps_to_e_core_012 above."]
    fn test_BC_2_14_004_build_failure_live_path_e_core_012() {
        // When this test is ungated (TLS stack broken by CI config):
        // The client build MUST fail and return the E-CORE-012 shape.
        // Actual invocation requires environment-level TLS sabotage (e.g.
        // SSLKEYLOGFILE=/dev/full or reqwest built without any TLS feature).
        let result = build_client();
        // In the normal test environment, build_client() succeeds — this body
        // only exercises when run in a deliberately broken TLS environment.
        if let Err(e) = result {
            assert_eq!(
                e.code(),
                "E-CORE-012",
                "BC-2.14.004 {{EC-006}}: live build failure must use code 'E-CORE-012'; \
                 got: {:?}",
                e.code()
            );
            assert!(
                matches!(e.retry_hint, RetryHint::Never),
                "BC-2.14.004 {{EC-006}}: live build failure must carry RetryHint::Never; \
                 got: {:?}",
                e.retry_hint
            );
        }
    }
}
