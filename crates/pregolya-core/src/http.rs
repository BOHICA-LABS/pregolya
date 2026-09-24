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

/// Default HTTP client timeout in seconds (BC-2.14.004 {PC-002}).
///
/// This constant is used by [`build_client`] and referenced in tests to assert
/// the timeout is observable in the built client's debug representation.
/// Changing this value propagates to the factory; `test_BC_2_14_004_default_timeout_applied`
/// derives its assertion string from this constant via `format!()` to remain coupled.
pub(crate) const HTTP_CLIENT_TIMEOUT_SECS: u64 = 30;

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
        .timeout(Duration::from_secs(HTTP_CLIENT_TIMEOUT_SECS))
        .build()
        .map_err(|e| map_build_failure(&e.to_string()))
}

/// Maps a `reqwest::ClientBuilder::build()` failure to the canonical E-CORE-012 error.
///
/// This is the shared production mapping function for HTTP client build failures.
/// Called by `build_client()` via `map_err` and used in tests to assert the error shape
/// without requiring a live broken TLS stack (BC-2.14.004 {EC-006}, SID-1).
///
/// The `reason` string is sanitized before inclusion in the error message —
/// URL-embedded credentials (e.g. proxy `://user:password@host`) are redacted to
/// `://***@host`. The sanitized reason portion is capped at 200 characters (see
/// `sanitize_error_message`) for defense-in-depth
/// (BC-2.14.004 {EC-006}, BC-2.14.005 {INV-001} DI-010, CWE-209).
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
/// API responses (BC-2.14.004 {EC-006}, BC-2.14.005 {INV-001} DI-010, CWE-209).
pub(crate) fn sanitize_error_message(s: &str) -> String {
    let sanitized = redact_url_credentials(s);
    // Cap at 200 characters (char count, not byte count) per BC-2.14.004 {EC-006}.
    sanitized.chars().take(200).collect()
}

/// Replace URL-embedded credential patterns `://userinfo@host` with `://***@host`.
///
/// Handles multiple occurrences and nested `://` sequences. The `@` search is
/// bounded to the authority component (up to the first `/`, `?`, `#`, whitespace,
/// or end-of-string) so that `@` characters in unrelated text after the URL
/// (e.g. `admin@corp.example` in an error description) are not treated as
/// credential delimiters.
///
/// Does not require the `regex` crate — pure string scanning.
fn redact_url_credentials(s: &str) -> String {
    let mut result = String::with_capacity(s.len());
    let mut remaining = s;

    while let Some(scheme_end) = remaining.find("://") {
        // Include everything up to and including `://`
        result.push_str(&remaining[..scheme_end + 3]);
        remaining = &remaining[scheme_end + 3..];

        // Bound the authority component: stop at the first `/`, `?`, `#`,
        // whitespace, or end of string. Only look for `@` within this boundary
        // to avoid redacting `@` characters in email addresses or other text
        // that appears after the URL (MED-1 over-redaction fix).
        let authority_end = remaining
            .find(|c: char| c == '/' || c == '?' || c == '#' || c.is_whitespace())
            .unwrap_or(remaining.len());
        let authority = &remaining[..authority_end];

        if let Some(at_pos) = authority.rfind('@') {
            // Credentials (userinfo) occupy the span before `@` in the authority.
            result.push_str("***@");
            result.push_str(&authority[at_pos + 1..]);
        } else {
            // No `@` in authority component — no credentials; emit as-is.
            result.push_str(authority);
        }
        remaining = &remaining[authority_end..];
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
    /// `build_client()` produces a `reqwest::Client` configured with the `HTTP_CLIENT_TIMEOUT_SECS`
    /// timeout. We verify the timeout is present by inspecting reqwest's `Debug` output —
    /// `reqwest 0.12.x` includes the configured total timeout in `{:?}` (e.g. `"30s"`).
    ///
    /// If `.timeout()` were removed from `build_client`, the `Debug` output would no longer
    /// contain `"30s"` and this assertion would fail, making the test load-bearing.
    ///
    /// GREEN: `build_client()` uses `Duration::from_secs(HTTP_CLIENT_TIMEOUT_SECS)` →
    /// the `Debug` output contains `"30s"`.
    #[test]
    fn test_BC_2_14_004_default_timeout_applied() {
        let result = build_client();
        assert!(
            result.is_ok(),
            "BC-2.14.004 {{PC-002}}: build_client() must succeed; timeout factory must not panic"
        );
        let client = result.unwrap();
        // reqwest 0.12.x exposes the configured total timeout in the `Debug` representation
        // of the Client. Asserting "30s" appears here ties the test to the actual
        // HTTP_CLIENT_TIMEOUT_SECS constant — removing .timeout() from build_client()
        // would remove "30s" from the Debug output and break this assertion.
        let debug_repr = format!("{:?}", client);
        let expected_timeout_str = format!("{HTTP_CLIENT_TIMEOUT_SECS}s");
        assert!(
            debug_repr.contains(&expected_timeout_str),
            "BC-2.14.004 {{PC-002}}: reqwest Client Debug output must contain '{expected_timeout_str}' \
             confirming the timeout is configured; if this fails, .timeout() may have \
             been removed from build_client(); debug repr: {debug_repr}"
        );
    }

    /// DI-009 (BC-2.14.004 {PC-001}/{INV-001}) + build-failure error-shape (BC-2.14.004 {EC-006})
    ///
    /// Two assertions combined in one test:
    ///
    /// 1. DI-009: `build_client()` must return `Ok(reqwest::Client)` with a
    ///    positive-timeout client. S-1.02 scope: the builder succeeds and returns a
    ///    usable client handle. E-PROV-002 end-to-end timeout-fires verification is
    ///    owned by S-2.07 (provider error-mapping layer against a mock server).
    ///
    /// 2. Build-failure error-shape (EC-006 / SID-1): when `ClientBuilder::build()`
    ///    fails (e.g. TLS misconfiguration), `map_build_failure` must produce a
    ///    `PregolyaError` with `Category::Transport`, code `"E-CORE-012"`, and
    ///    `RetryHint::Never`. This is the **build-failure** error shape
    ///    (E-CORE-012 / Transport). The **timeout-fires** error shape (E-PROV-002 /
    ///    Category::TIMEOUT) is a separate code path owned by S-2.07.
    ///    Exercised here via `map_build_failure` to avoid requiring a broken TLS stack.
    ///
    /// NOTE: This test intentionally shares assertion patterns with
    /// `test_BC_2_14_004_build_failure_maps_to_e_core_012` and
    /// `test_BC_2_14_004_build_failure_production_path_invariant`. Each serves a
    /// distinct invariant: AC-015 (error-code mapping), AC-019 (production-scope
    /// accessibility), EC-006+DI-009 (combined Ok+build-failure shape). Do not
    /// de-duplicate — removing either would leave its specific invariant uncovered.
    ///
    /// GREEN: `build_client()` is implemented and `map_build_failure` produces the
    /// correct E-CORE-012 / Transport / Never shape.
    #[test]
    fn test_BC_2_14_004_build_client_ok_and_build_failure_ec006() {
        // Part 1 — DI-009: build_client() must succeed (returns Ok with a
        // positive-timeout client). The 30-second timeout *value* is pinned by
        // `test_BC_2_14_004_default_timeout_applied`. The `check-client-timeout`
        // xtask gate verifies only that a non-zero `.timeout()` is present at
        // production call sites — it cannot discriminate 30s from 1s and is
        // non-load-bearing for the 30s value.
        let result = build_client();
        assert!(
            result.is_ok(),
            "BC-2.14.004 DI-009: build_client() must return Ok(reqwest::Client); \
             got: {result:?}"
        );

        // Part 2 — Error-shape (BC-2.14.004 {EC-006}, SID-1): when the builder fails,
        // the error must carry Category::Transport, code "E-CORE-012", RetryHint::Never,
        // and a message starting with "HttpClientBuildFailed:". Exercised via
        // map_build_failure (production code path) without requiring a broken TLS stack.
        let err = map_build_failure("simulated timeout-related build failure");
        assert_eq!(
            err.code(),
            "E-CORE-012",
            "BC-2.14.004 {{EC-006}}: ClientBuilder-failure must use code 'E-CORE-012'; \
             got: {:?}",
            err.code()
        );
        assert!(
            matches!(err.category, Category::Transport),
            "BC-2.14.004 {{EC-006}}: build-failure must carry \
             Category::Transport; got: {:?}",
            err.category
        );
        assert!(
            matches!(err.retry_hint, RetryHint::Never),
            "BC-2.14.004 {{EC-006}}: build-failure must carry \
             RetryHint::Never; got: {:?}",
            err.retry_hint
        );
        assert!(
            err.message.starts_with("HttpClientBuildFailed:"),
            "BC-2.14.004 {{EC-006}}: build-failure message must start with \
             'HttpClientBuildFailed:'; got: {:?}",
            err.message
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
    /// Deferred to S-2.07 per BC-2.14.004 {PC-005}.
    ///
    /// SID-1 note: `test_BC_2_14_004_default_timeout_applied` is the SID-1 substitute for
    /// BC-2.14.004 {PC-002} (30-second timeout configured) — it drives the factory at the
    /// dependency boundary without requiring the live 30s wait.
    /// `test_BC_2_14_004_build_client_returns_ok` and
    /// `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` verify the Ok-return and
    /// build-failure shape respectively (different concerns, not the PC-002 substitute).
    ///
    /// GREEN: `build_client()` is implemented — the client is constructed and the timeout
    /// fires as expected against a stalled server.
    #[tokio::test]
    #[ignore = "PERF-BC214004: ~30 s wall-clock (client timeout fires at 30 s; inline stall \
                server sleeps 35 s on a detached thread); unit substitute that verifies timeout \
                is configured without the live wait: test_BC_2_14_004_default_timeout_applied \
                (BC-2.14.004 {PC-002}); ungated in CI when S-2.07 integration suite runs with \
                timing budget"]
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
    /// This non-ignored test drives the mapping BOUNDARY via `map_build_failure` directly.
    /// The production mapping path is exercised directly — not a test-only duplicate
    /// (AC-019: no separate test-only mapping helper is introduced).
    ///
    /// SID-1: the `#[ignore]`'d test below exercises the live ClientBuilder::build() failure
    /// path; this non-ignored test covers the mapping boundary without requiring a broken
    /// TLS stack.
    ///
    /// NOTE: This test intentionally shares assertion patterns with
    /// `test_BC_2_14_004_build_failure_production_path_invariant` and
    /// `test_BC_2_14_004_build_client_ok_and_build_failure_ec006`. Each serves a
    /// distinct invariant: AC-015 (error-code mapping), AC-019 (production-scope
    /// accessibility), EC-006+DI-009 (combined Ok+build-failure shape). Do not
    /// de-duplicate — removing either would leave its specific invariant uncovered.
    #[test]
    fn test_BC_2_14_004_build_failure_maps_to_e_core_012() {
        let e = map_build_failure("simulated TLS stack unavailable");
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

    // ─── AC-019 / BC-2.14.004 {EC-006} (SID-1) ─────────────────────────────────

    /// AC-019 (traces to BC-2.14.004 {EC-006} / SID-1)
    ///
    /// The production invariant: `map_build_failure` must exist as a `pub(crate)` function
    /// and must produce the E-CORE-012 shape. This test calls `map_build_failure` directly
    /// with a synthetic reason string, verifying it is accessible from the test module
    /// (i.e., it is production-scope, not buried in `#[cfg(test)]`).
    ///
    /// This test directly calls `map_build_failure`, which is defined in production code.
    /// If `map_build_failure` were moved into `#[cfg(test)]`, this call would fail to
    /// compile — making the test a load-bearing production-scope invariant.
    ///
    /// NOTE: This test intentionally shares assertion patterns with
    /// `test_BC_2_14_004_build_failure_maps_to_e_core_012` and
    /// `test_BC_2_14_004_build_client_ok_and_build_failure_ec006`. Each serves a
    /// distinct invariant: AC-015 (error-code mapping), AC-019 (production-scope
    /// accessibility), EC-006+DI-009 (combined Ok+build-failure shape). Do not
    /// de-duplicate — removing either would leave its specific invariant uncovered.
    ///
    /// GREEN: `map_build_failure` is `pub(crate)` outside any `#[cfg(test)]` block.
    #[test]
    fn test_BC_2_14_004_build_failure_production_path_invariant() {
        // Calling map_build_failure directly — this would fail to compile if the
        // function were moved into #[cfg(test)] scope, making the test load-bearing.
        let e = map_build_failure("synthetic: build failed for production-path test");
        assert_eq!(
            e.code(),
            "E-CORE-012",
            "BC-2.14.004 {{EC-006}} (SID-1): direct call to map_build_failure must yield \
             E-CORE-012 code; got: {:?}",
            e.code()
        );
        assert!(
            matches!(e.category, Category::Transport),
            "BC-2.14.004 {{EC-006}}: map_build_failure must yield Category::Transport; got: {:?}",
            e.category
        );
        assert!(
            e.message
                .starts_with("HttpClientBuildFailed: failed to build HTTP client:"),
            "BC-2.14.004 {{EC-006}}: message must begin with canonical prefix; got: {:?}",
            e.message
        );
    }

    // ─── BC-2.14.004 {EC-006} / CWE-209 — sanitize_error_message tests ───────

    /// BC-2.14.004 {EC-006} / CWE-209:URL-embedded credentials in a build-failure reason must be redacted.
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

    /// MED-1 regression: `@` outside the URL authority component must NOT be redacted.
    ///
    /// `"proxy https://proxy.corp.local:8080 failed; contact admin@corp.example"` has
    /// an `@` in an email address after a space (outside any URL authority component).
    /// Before the MED-1 fix, `redact_url_credentials` found `://` then searched for ANY
    /// `@` in the remainder, redacting `proxy.corp.local:8080 failed; contact admin` —
    /// revealing that the proxy host AND email address were incorrectly clobbered.
    ///
    /// After the fix, the authority component is bounded at whitespace (` `), so the `@`
    /// in `admin@corp.example` is outside the authority and is not treated as a credential
    /// delimiter.
    #[test]
    fn test_sanitize_error_message_does_not_over_redact_email_after_url() {
        let raw = "proxy https://proxy.corp.local:8080 failed; contact admin@corp.example for help";
        let sanitized = sanitize_error_message(raw);
        assert!(
            sanitized.contains("proxy.corp.local:8080"),
            "MED-1: proxy host must not be redacted (no credentials in authority); got: {:?}",
            sanitized
        );
        assert!(
            sanitized.contains("admin@corp.example"),
            "MED-1: email address after URL must not be redacted; got: {:?}",
            sanitized
        );
        assert!(
            !sanitized.contains("***@corp.example"),
            "MED-1: email address must not be treated as a URL credential; got: {:?}",
            sanitized
        );
    }

    /// BC-2.14.004 {EC-006} / CWE-209:Error messages with no URL-embedded credentials must pass through unchanged.
    #[test]
    fn test_sanitize_error_message_passthrough_when_no_credentials() {
        let raw = "TLS handshake failed: certificate verify failed";
        let sanitized = sanitize_error_message(raw);
        assert_eq!(
            sanitized, raw,
            "sanitize_error_message must not alter messages without credentials"
        );
    }

    /// BC-2.14.004 {EC-006} / CWE-209:Error messages longer than 200 chars must be capped.
    #[test]
    fn test_sanitize_error_message_caps_at_200_chars() {
        let raw = "x".repeat(300);
        let sanitized = sanitize_error_message(&raw);
        assert!(
            sanitized.chars().count() <= 200,
            "sanitize_error_message must cap output at 200 chars; got len: {}",
            sanitized.chars().count()
        );
    }

    /// F-P24-LOW-005 — `sanitize_error_message` caps at 200 chars (char count, not byte count).
    ///
    /// A 201-char string of multi-byte characters must be truncated to exactly 200 chars.
    /// '©' (U+00A9) is 2 bytes in UTF-8: 201 × '©' = 201 chars = 402 bytes.
    /// Char-based cap: result is 200 chars = 400 bytes.
    /// Byte-based cap (at 200 bytes): result would be 100 chars — proving the two approaches differ.
    #[test]
    fn test_sanitize_error_message_caps_at_200_chars_multibyte() {
        // '©' (copyright sign, U+00A9) is 2 bytes in UTF-8.
        // 201 × '©' = 201 chars = 402 bytes.
        // Char-based cap: 200 chars = 400 bytes.
        // Byte-based cap (wrong): 100 chars (only 100 × 2-byte chars fit in 200 bytes).
        let raw = "\u{00A9}".repeat(201);
        let sanitized = sanitize_error_message(&raw);
        assert_eq!(
            sanitized.chars().count(),
            200,
            "sanitize_error_message must cap at 200 chars (char count, not byte count); \
             got {} chars",
            sanitized.chars().count()
        );
    }

    /// BC-2.14.004 {EC-006} / CWE-209:Proxy URL credentials flow through map_build_failure and are absent from the
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

    /// BC-2.14.004 {EC-006} / CWE-209:Error reason with no URL must pass through map_build_failure unaltered.
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
    /// which is not available in standard CI. This test must only be ungated in an
    /// environment where ClientBuilder::build() is forced to fail (e.g. TLS stack
    /// sabotaged); the error-mapping logic is covered non-ignored by
    /// test_BC_2_14_004_build_failure_maps_to_e_core_012 and
    /// test_BC_2_14_004_build_failure_production_path_invariant.
    #[test]
    #[ignore = "EXT-BC214004-LIVE: requires a TLS configuration that forces \
                ClientBuilder::build() to fail in a real environment; \
                the E-CORE-012 mapping is covered non-ignored in \
                test_BC_2_14_004_build_failure_maps_to_e_core_012 and \
                test_BC_2_14_004_build_failure_production_path_invariant"]
    fn test_BC_2_14_004_build_failure_live_path_e_core_012() {
        // When this test is ungated (TLS stack broken by CI config):
        // The client build MUST fail and return the E-CORE-012 shape.
        // Actual invocation requires environment-level TLS sabotage (e.g.
        // SSLKEYLOGFILE=/dev/full or reqwest built without any TLS feature).
        let result = build_client();
        assert!(
            result.is_err(),
            "BC-2.14.004 {{EC-006}}: this test must only be ungated in an environment where \
             ClientBuilder::build() is forced to fail (e.g., TLS stack sabotaged); \
             got Ok — the sabotage precondition was not applied"
        );
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
