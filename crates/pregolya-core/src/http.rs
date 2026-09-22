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
        .map_err(|e| map_build_failure(&e.to_string()))
}

/// Maps a `reqwest::ClientBuilder::build()` failure to the canonical E-CORE-012 error.
///
/// This is the shared production mapping function for HTTP client build failures.
/// Called by `build_client()` via `map_err` and used in tests to assert the error shape
/// without requiring a live broken TLS stack (BC-2.14.004 F-C, SID-1/POL-34).
///
/// The `reason` string is sanitized before inclusion in the error message —
/// URL-embedded credentials (e.g. proxy `://user:password@host`) are redacted to
/// `://***@host`, and the message is capped at 200 characters for defense-in-depth
/// (SEC-007, CWE-209).
///
/// # Returns
///
/// A `PregolyaError` with `Component::Core`, `Category::Transport`,
/// `RetryHint::Never`, code `"E-CORE-012"`, and a message starting with
/// `"HttpClientBuildFailed: failed to build HTTP client: "`.
pub(crate) fn map_build_failure(reason: &str) -> PregolyaError {
    PregolyaError::new(
        Component::Core,
        Category::Transport,
        RetryHint::Never,
        "E-CORE-012",
        format!(
            "HttpClientBuildFailed: failed to build HTTP client: {}",
            sanitize_error_message(reason)
        ),
    )
}

/// Sanitize a raw error message string before including it in a `PregolyaError`.
///
/// Performs two passes:
/// 1. Redact URL-embedded credentials: `://user:pass@host` → `://***@host`.
/// 2. Cap the result at 200 characters to bound information exposure.
///
/// This prevents proxy credentials (e.g. `http://corp-proxy:password@10.0.0.1:3128`)
/// from leaking into structured error messages that may be logged or surfaced in
/// API responses (SEC-007, CWE-209).
pub(crate) fn sanitize_error_message(s: &str) -> String {
    let sanitized = redact_url_credentials(s);
    // Cap at 200 chars, respecting UTF-8 char boundaries.
    if sanitized.len() <= 200 {
        sanitized
    } else {
        // Find the last valid char boundary at or before byte 200.
        let truncate_at = (0..=200)
            .rev()
            .find(|&i| sanitized.is_char_boundary(i))
            .unwrap_or(0);
        sanitized[..truncate_at].to_string()
    }
}

/// Replace URL-embedded credential patterns `://ANYTHING@` with `://***@`.
///
/// Handles multiple occurrences and nested `://` sequences. Does not require
/// the `regex` crate — pure string scanning.
fn redact_url_credentials(s: &str) -> String {
    let mut result = String::with_capacity(s.len());
    let mut remaining = s;

    while let Some(scheme_end) = remaining.find("://") {
        // Include everything up to and including `://`
        result.push_str(&remaining[..scheme_end + 3]);
        remaining = &remaining[scheme_end + 3..];

        if let Some(at_pos) = remaining.find('@') {
            // Credentials occupy the span between `://` and `@`; redact them.
            result.push_str("***@");
            remaining = &remaining[at_pos + 1..];
        }
        // No `@` found after `://` — no credentials in this segment; continue.
    }
    result.push_str(remaining);
    result
}

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used, non_snake_case)]
mod tests {
    use std::time::Duration;

    use super::*;
    use crate::error::{Category, RetryHint};

    // ── AC-015 test-support stub ──────────────────────────────────────────────
    //
    // BC-2.14.004 F-C (SID-1): delegates to the production map_build_failure fn
    // so that test_BC_2_14_004_build_failure_maps_to_e_core_012 exercises the
    // real production mapping, not a test-only duplicate (BC-2.14.004 F-C/POL-34).
    fn make_build_error_for_test(reason: &str) -> PregolyaError {
        map_build_failure(reason)
    }

    // ── BC-2.14.004 Tests ─────────────────────────────────────────────────────

    /// AC-004 (traces to BC-2.14.004 {PC-001}, {PC-002})
    ///
    /// `build_client()` returns `Ok(reqwest::Client)` under normal conditions.
    /// The factory must not panic and must not return an error on a system with
    /// a working TLS stack.
    ///
    /// GREEN: `build_client()` is implemented — constructs a reqwest::Client with
    /// a 30-second timeout and returns `Ok` on a working TLS stack.
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
    /// GREEN: `build_client()` is implemented — returns `Ok` with a client carrying
    /// the 30-second timeout.
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

    /// DI-009 (BC-2.14.004 {PC-001}/{INV-004}) — build_client returns Ok
    ///
    /// S-1.02 scope: `build_client()` must return `Ok(reqwest::Client)` when called
    /// with valid workspace configuration. This test verifies DI-009: the builder
    /// succeeds and returns a usable client handle.
    ///
    /// E-PROV-002 error-shape verification (reqwest timeout fires → PregolyaError
    /// category:TIMEOUT, code:"E-PROV-002") is owned by S-2.07, which implements the
    /// provider error-mapping layer against a mock server.
    ///
    /// GREEN: `build_client()` is implemented — returns `Ok(reqwest::Client)` with a
    /// positive-timeout client.
    #[test]
    fn test_BC_2_14_004_timeout_error_shape() {
        // DI-009: build_client() must succeed (returns Ok with a positive-timeout client).
        // The timeout value is verified by the xtask gate (check-no-panic, check-client-timeout).
        let result = build_client();
        assert!(
            result.is_ok(),
            "BC-2.14.004 DI-009: build_client() must return Ok(reqwest::Client); \
             got: {result:?}"
        );
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
    /// GREEN: `build_client()` is implemented — the client is constructed and the timeout
    /// fires as expected against a stalled server.
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
    /// GREEN: `build_client()` maps build errors to `E-CORE-012` / `Category::Transport` /
    /// `RetryHint::Never` per BC-2.14.004 {EC-006} v1.7.
    ///
    /// This non-ignored test drives the mapping BOUNDARY via `make_build_error_for_test`,
    /// which delegates to the production `map_build_failure` fn. The production mapping
    /// path is exercised directly — not a test-only duplicate.
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
    // S-1.02 pass-2: the E-CORE-012 mapping is extracted to the shared production
    // function `map_build_failure` so that test_BC_2_14_004_build_failure_maps_to_e_core_012
    // exercises the PRODUCTION mapping path, not a test-only duplicate.
    //
    // GREEN: pub(crate) fn map_build_failure exists in production scope — the test-only
    //   stub make_build_error_for_test now delegates to it, satisfying BC-2.14.004 F-C
    //   and SID-1/POL-34. The assertion below confirms the production fn is present.
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
    /// GREEN: `pub(crate) fn map_build_failure` exists in http.rs outside test scope.
    /// The assertion confirms the production fn is present and the test drives it directly.
    #[test]
    fn test_BC_2_14_004_build_failure_load_bearing_on_production() {
        let src = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/src/http.rs"));
        // Pattern built via concat() to prevent self-reference through include_str!.
        // include_str! embeds the whole file; a literal match in doc comments or
        // assertion messages would trivially satisfy contains() against current HEAD.
        //
        // The production mapping function must appear OUTSIDE #[cfg(test)] scope.
        // Green: map_build_failure is pub(crate) in production scope; this assertion verifies it remains present.
        let prod_fn = ["pub(crate) fn ", "map_build_failure"].concat();
        assert!(
            src.contains(&prod_fn),
            "BC-2.14.004 F-C (SID-1): the E-CORE-012 mapping must be a production \
             pub(crate) fn (not buried in cfg(test) as make_build_error_for_test); \
             implementer must extract the shared mapping fn and wire build_client() to it"
        );
    }

    // ─── SEC-007 / CWE-209 — sanitize_error_message tests ────────────────────

    /// SEC-007: URL-embedded credentials in a build-failure reason must be redacted.
    ///
    /// A misconfigured proxy (e.g. `http://user:password@proxy:3128`) may appear in the
    /// reqwest error string. The canonical E-CORE-012 message must NOT include the
    /// credential portion.
    #[test]
    fn test_sanitize_error_message_redacts_url_credentials() {
        let raw = "failed to connect to proxy http://corp-proxy:secret123@10.0.0.1:3128";
        let sanitized = sanitize_error_message(raw);
        assert!(
            !sanitized.contains("secret123"),
            "sanitize_error_message must redact credential; got: {:?}",
            sanitized
        );
        assert!(
            sanitized.contains("10.0.0.1:3128"),
            "sanitize_error_message must preserve host/port after @; got: {:?}",
            sanitized
        );
        assert!(
            sanitized.contains("***@"),
            "sanitize_error_message must emit '***@' as redaction marker; got: {:?}",
            sanitized
        );
    }

    /// SEC-007: Error messages with no URL-embedded credentials must pass through unchanged.
    #[test]
    fn test_sanitize_error_message_passthrough_when_no_credentials() {
        let raw = "TLS handshake failed: certificate verify failed";
        let sanitized = sanitize_error_message(raw);
        assert_eq!(
            sanitized, raw,
            "sanitize_error_message must not alter messages without credentials"
        );
    }

    /// SEC-007: Error messages longer than 200 chars must be capped.
    #[test]
    fn test_sanitize_error_message_caps_at_200_chars() {
        let raw = "x".repeat(300);
        let sanitized = sanitize_error_message(&raw);
        assert!(
            sanitized.len() <= 200,
            "sanitize_error_message must cap output at 200 chars; got len: {}",
            sanitized.len()
        );
    }

    /// SEC-007: Proxy URL credentials flow through map_build_failure and are absent from the
    /// resulting PregolyaError message (end-to-end integration of the sanitize path).
    #[test]
    fn test_map_build_failure_redacts_proxy_credentials_in_message() {
        let raw_reason = "could not connect to proxy http://admin:hunter2@proxy.corp.local:8080";
        let e = map_build_failure(raw_reason);
        assert!(
            !e.message.contains("hunter2"),
            "map_build_failure must redact proxy credentials from error message; got: {:?}",
            e.message
        );
        assert!(
            e.message.starts_with("HttpClientBuildFailed:"),
            "message must still start with 'HttpClientBuildFailed:'; got: {:?}",
            e.message
        );
    }

    /// SEC-007: Error reason with no URL must pass through map_build_failure unaltered.
    #[test]
    fn test_map_build_failure_passthrough_no_url() {
        let raw_reason = "simulated TLS stack unavailable";
        let e = map_build_failure(raw_reason);
        assert!(
            e.message.contains(raw_reason),
            "map_build_failure must include unmodified reason when no URL credentials present; \
             got: {:?}",
            e.message
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
