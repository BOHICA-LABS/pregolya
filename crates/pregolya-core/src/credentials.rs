//! Credential newtypes for the pregolya workspace.
//!
//! Every API key or secret credential in pregolya is a newtype struct (not a
//! bare `String` or type alias). The [`fmt::Debug`] implementation emits exactly
//! `"<redacted>"` — no substring of the actual key value ever appears in any
//! format specifier (BC-2.14.005 {PC-002}, {INV-002}).
//!
//! # Invariants
//!
//! - No `#[derive(Serialize)]` or `#[derive(Deserialize)]` — credential values must not
//!   appear in API responses or log artifacts, and `Deserialize` would bypass `new()`
//!   validation (BC-2.14.005 {PC-003}, BC-2.14.006).
//! - No `impl fmt::Display` — `Display` output is invoked by `format!("{}", key)` and
//!   the `{key}` shorthand; key material must not appear in format output
//!   (BC-2.14.005 {INV-002}).
//! - No `impl Deref<Target=str>` or `impl AsRef<str>` — access to the inner value
//!   is gated behind the explicit `.expose_secret()` method (BC-2.14.005 {PC-004},
//!   {INV-003}).
//! - Empty key strings are rejected at construction time — `new("")` returns
//!   `Err(PregolyaError { category: VAL, code: "E-CORE-005" })` (BC-2.14.006 {PC-001}).
//! - All public key types carry `#[non_exhaustive]` to prevent external struct-literal
//!   construction; callers must use `FooApiKey::new()` (CLAUDE.md `#[non_exhaustive]` rule).

use std::fmt;

use crate::error::PregolyaError;

// ─── Shared validation ────────────────────────────────────────────────────────

/// Validates that an API key string is non-empty and non-whitespace-only.
///
/// Shared by all credential `new()` constructors. Returns `Err(PregolyaError)`
/// with code `"E-CORE-005"` and `Category::Val` when the key fails validation
/// (BC-2.14.006 {PC-001}, {PC-004} v1.6, EC-004, EC-006).
fn validate_api_key_non_empty(key: &str) -> Result<(), PregolyaError> {
    if key.trim().is_empty() {
        return Err(PregolyaError::new(
            crate::error::Component::Core,
            crate::error::Category::Val,
            crate::error::RetryHint::Never,
            "E-CORE-005",
            "Validation failed for 'api_key': value must not be empty or whitespace-only",
        ));
    }
    Ok(())
}

// ─── OpenAiApiKey ─────────────────────────────────────────────────────────────

/// API key for the OpenAI provider.
///
/// Newtype wrapping the raw key string. `Debug` emits `"<redacted>"` — never
/// the key value. No `Serialize`, no `Deref<Target=str>`, no `AsRef<str>`.
///
/// # Construction
///
/// Use [`OpenAiApiKey::new`], which validates that the key is non-empty:
///
/// ```ignore
/// let key = OpenAiApiKey::new("sk-real-key")?;
/// ```
///
/// # Accessing the inner value
///
/// Only via the explicit [`OpenAiApiKey::expose_secret`] method — never via
/// trait auto-deref.
#[non_exhaustive]
pub struct OpenAiApiKey(String);

impl fmt::Debug for OpenAiApiKey {
    /// Emits exactly `"<redacted>"` — the canonical log-scrubber sentinel.
    ///
    /// BC-2.14.005 {PC-002} / {INV-002}: the redacted literal is `"<redacted>"` so
    /// automated log-scanning tools can detect accidental exposures.
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("<redacted>")
    }
}

impl OpenAiApiKey {
    /// Constructs a new `OpenAiApiKey`, validating that the key is non-empty.
    ///
    /// # Errors
    ///
    /// Returns `Err(PregolyaError { category: VAL, retry_hint: Never, code: "E-CORE-005",
    /// message: "Validation failed for 'api_key': value must not be empty or whitespace-only" })`
    /// when `key` is empty or whitespace-only (BC-2.14.006 {PC-001}, {PC-004} v1.6, EC-004,
    /// EC-006). A whitespace-only key produces a malformed bearer token at the HTTP layer.
    pub fn new(key: impl Into<String>) -> Result<Self, PregolyaError> {
        let key = key.into();
        validate_api_key_non_empty(&key)?;
        // Trim after validation: validate_api_key_non_empty rejects whitespace-only inputs;
        // trimming here removes leading/trailing whitespace from otherwise-valid keys so that
        // `expose_secret()` never returns a value that would produce a malformed bearer token
        // (e.g. "Bearer sk-abc\n" is invalid; "Bearer sk-abc" is correct).
        Ok(Self(key.trim().to_string()))
    }

    /// Returns a reference to the inner key string.
    ///
    /// This is the ONLY intentional exposure path for the key value (BC-2.14.005 {PC-005}).
    /// Calling sites must explicitly opt in; there is no auto-deref path.
    ///
    /// # Usage
    ///
    /// ```ignore
    /// let bearer = format!("Bearer {}", api_key.expose_secret());
    /// ```
    pub fn expose_secret(&self) -> &str {
        &self.0
    }
}

/// Test-only constructor — bypasses `new()` validation to allow direct construction
/// in unit tests (e.g. to test `Debug` redaction without going through the validation path).
/// Only compiled in `#[cfg(test)]` context; `pub(crate)` so tests in `mod tests` can call it.
#[cfg(test)]
impl OpenAiApiKey {
    pub(crate) fn from_raw_for_tests(s: impl Into<String>) -> Self {
        Self(s.into())
    }
}

// ─── AnthropicApiKey ──────────────────────────────────────────────────────────

/// API key for the Anthropic (Claude) provider.
///
/// Same invariants as [`OpenAiApiKey`]: `Debug` emits `"<redacted>"`, no
/// `Serialize`, no `Deref<Target=str>`, no `AsRef<str>`.
#[non_exhaustive]
pub struct AnthropicApiKey(String);

impl fmt::Debug for AnthropicApiKey {
    /// Emits exactly `"<redacted>"` — the canonical log-scrubber sentinel.
    ///
    /// BC-2.14.005 {PC-002} / {INV-002}: the redacted literal is `"<redacted>"` so
    /// automated log-scanning tools can detect accidental exposures.
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("<redacted>")
    }
}

impl AnthropicApiKey {
    /// Constructs a new `AnthropicApiKey`, validating that the key is non-empty.
    ///
    /// # Errors
    ///
    /// Returns `Err(PregolyaError { category: VAL, retry_hint: Never, code: "E-CORE-005",
    /// message: "Validation failed for 'api_key': value must not be empty or whitespace-only" })`
    /// when `key` is empty or whitespace-only (BC-2.14.006 {PC-001}, {PC-004} v1.6, EC-004,
    /// EC-006). A whitespace-only key produces a malformed bearer token at the HTTP layer.
    pub fn new(key: impl Into<String>) -> Result<Self, PregolyaError> {
        let key = key.into();
        validate_api_key_non_empty(&key)?;
        // Trim after validation (same rationale as OpenAiApiKey::new).
        Ok(Self(key.trim().to_string()))
    }

    /// Returns a reference to the inner key string.
    ///
    /// This is the ONLY intentional exposure path for the key value (BC-2.14.005 {PC-005}).
    pub fn expose_secret(&self) -> &str {
        &self.0
    }
}

/// Test-only constructor — bypasses `new()` validation to allow direct construction
/// in unit tests (e.g. to test `Debug` redaction without going through the validation path).
/// Only compiled in `#[cfg(test)]` context; `pub(crate)` so tests in `mod tests` can call it.
#[cfg(test)]
impl AnthropicApiKey {
    pub(crate) fn from_raw_for_tests(s: impl Into<String>) -> Self {
        Self(s.into())
    }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used, non_snake_case)]
mod tests {
    use super::*;
    use crate::error::{Category, RetryHint};

    // ── Compile-time assertions (BC-2.14.005 {PC-003}, {PC-004}, {PC-006}) ──────

    // AC-009: OpenAiApiKey must NOT impl AsRef<str> (no auto-deref path).
    static_assertions::assert_not_impl_any!(OpenAiApiKey: AsRef<str>);
    // AC-009: AnthropicApiKey must NOT impl AsRef<str>.
    static_assertions::assert_not_impl_any!(AnthropicApiKey: AsRef<str>);

    // AC-009: OpenAiApiKey must NOT impl Deref (no auto-deref to str or String).
    static_assertions::assert_not_impl_any!(OpenAiApiKey: std::ops::Deref);
    static_assertions::assert_not_impl_any!(AnthropicApiKey: std::ops::Deref);

    // AC-009: No Serialize impl — credential values must not appear in serialized artifacts
    // (BC-2.14.005 {PC-003}). Assertion catches anyone adding #[derive(Serialize)].
    static_assertions::assert_not_impl_any!(OpenAiApiKey: serde::Serialize);
    static_assertions::assert_not_impl_any!(AnthropicApiKey: serde::Serialize);

    // AC-009: No Deserialize impl — #[derive(Deserialize)] would bypass new() validation
    // (BC-2.14.006): callers could deserialize arbitrary strings (including empty/whitespace)
    // without going through new() (SEC-002 / BC-2.14.006).
    static_assertions::assert_not_impl_any!(OpenAiApiKey: serde::de::Deserialize<'static>);
    static_assertions::assert_not_impl_any!(AnthropicApiKey: serde::de::Deserialize<'static>);

    // AC-009: No Display impl — Display output is invoked by format!("{}", key) and the
    // {key} shorthand; credential values must not appear in any format output
    // (BC-2.14.005 {INV-002}, SEC-003 / CWE-532).
    static_assertions::assert_not_impl_any!(OpenAiApiKey: std::fmt::Display);
    static_assertions::assert_not_impl_any!(AnthropicApiKey: std::fmt::Display);

    // AC-013 (traces to BC-2.14.006 EC-005): fallible conversions use TryFrom, not From.
    // From<String> / From<&str> must NOT be implemented — such a conversion cannot fail,
    // but construction CAN fail (empty string). If From were implemented the contract
    // would be violated: infallible API wrapping fallible construction.
    static_assertions::assert_not_impl_any!(OpenAiApiKey: From<String>);
    static_assertions::assert_not_impl_any!(OpenAiApiKey: From<&'static str>);
    static_assertions::assert_not_impl_any!(AnthropicApiKey: From<String>);
    static_assertions::assert_not_impl_any!(AnthropicApiKey: From<&'static str>);

    // ── BC-2.14.003 Tests ─────────────────────────────────────────────────────

    /// AC-001 (traces to BC-2.14.003 {PC-001}, TV-001)
    ///
    /// Every fallible public constructor returns `Result<T, PregolyaError>` — never
    /// panics. `OpenAiApiKey::new` is the canonical example of a fallible constructor
    /// in `pregolya-core`.
    ///
    /// GREEN: `OpenAiApiKey::new` is implemented — trims the input, rejects empty/whitespace-only
    /// strings with E-CORE-005, and returns `Ok(OpenAiApiKey)` for valid input.
    #[test]
    fn test_BC_2_14_003_constructor_returns_result() {
        // BC-2.14.003 {PC-001}: fallible constructor must return Result<T, PregolyaError>
        // Valid input → Ok; invalid input → Err. Neither path panics.
        let ok_result = OpenAiApiKey::new("sk-valid-key-for-test");
        assert!(
            ok_result.is_ok(),
            "BC-2.14.003 {{PC-001}}: valid input must return Ok; got: {:?}",
            ok_result.err()
        );

        let err_result = OpenAiApiKey::new("");
        assert!(
            err_result.is_err(),
            "BC-2.14.003 {{PC-001}}: invalid input (empty) must return Err, not panic"
        );
    }

    // ── BC-2.14.005 Tests ─────────────────────────────────────────────────────

    /// AC-007 (traces to BC-2.14.005 {PC-001})
    ///
    /// `OpenAiApiKey::new("sk-valid-key")` returns `Ok(OpenAiApiKey)` for a non-empty key.
    ///
    /// GREEN: `new()` is implemented — non-empty input returns `Ok(OpenAiApiKey)`.
    #[test]
    fn test_BC_2_14_005_openai_new_valid_key_returns_ok() {
        let result = OpenAiApiKey::new("sk-valid-key-for-test");
        assert!(
            result.is_ok(),
            "BC-2.14.005 {{PC-001}}: new() with non-empty key must return Ok; got: {:?}",
            result.err()
        );
    }

    /// AC-007 (traces to BC-2.14.005 {PC-001})
    ///
    /// `AnthropicApiKey::new("sk-ant-valid-key")` returns `Ok(AnthropicApiKey)`.
    ///
    /// GREEN: `new()` is implemented — non-empty input returns `Ok(AnthropicApiKey)`.
    #[test]
    fn test_BC_2_14_005_anthropic_new_valid_key_returns_ok() {
        let result = AnthropicApiKey::new("sk-ant-valid-key-for-test");
        assert!(
            result.is_ok(),
            "BC-2.14.005 {{PC-001}}: AnthropicApiKey::new() with non-empty key must return Ok; got: {:?}",
            result.err()
        );
    }

    /// AC-008 (traces to BC-2.14.005 {PC-002}, TV-001)
    ///
    /// `format!("{:?}", OpenAiApiKey("..."))` returns exactly `"<redacted>"` — the canonical
    /// log-scrubber sentinel per {INV-002}. No substring of the actual key value appears.
    ///
    /// Green-by-design: the `Debug` implementation is fully implemented and does not depend on
    /// `new()`; this test constructs via `from_raw_for_tests` to keep the Debug assertion
    /// independent of constructor validation logic.
    #[test]
    fn test_BC_2_14_005_openai_debug_emits_redacted_sentinel() {
        // Construct via the test-only helper (field is private; from_raw_for_tests bypasses new()
        // validation so the Debug assertion is independent of constructor validation logic).
        let key = OpenAiApiKey::from_raw_for_tests("sk-real-secret-value");
        let debug_output = format!("{:?}", key);
        assert_eq!(
            debug_output, "<redacted>",
            "BC-2.14.005 {{PC-002}}: Debug must emit exactly '<redacted>', not the key value; \
             got: {:?}",
            debug_output
        );
    }

    /// AC-008 (traces to BC-2.14.005 {PC-002}, TV-001)
    ///
    /// `format!("{:?}", AnthropicApiKey("..."))` returns exactly `"<redacted>"`.
    ///
    /// GREEN-BY-DESIGN: `Debug` is fully implemented and does not depend on `new()`;
    /// constructs via `from_raw_for_tests`, independent of constructor validation logic.
    #[test]
    fn test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel() {
        let key = AnthropicApiKey::from_raw_for_tests("sk-ant-real-secret-value");
        let debug_output = format!("{:?}", key);
        assert_eq!(
            debug_output, "<redacted>",
            "BC-2.14.005 {{PC-002}}: AnthropicApiKey Debug must emit exactly '<redacted>'; \
             got: {:?}",
            debug_output
        );
    }

    /// AC-008 (traces to BC-2.14.005 {PC-002}, {INV-002})
    ///
    /// The `Debug` output must NOT contain any substring of the actual key value.
    /// Verifies the redaction is structural — not just a prefix/suffix trim.
    ///
    /// Green-by-design: constructs via `from_raw_for_tests`, independent of constructor logic.
    #[test]
    fn test_BC_2_14_005_debug_does_not_leak_key_material() {
        let sentinel = "LEAK_SENTINEL_ABC123_DO_NOT_LOG";
        let key = OpenAiApiKey::from_raw_for_tests(sentinel);
        let debug_output = format!("{:?}", key);
        assert!(
            !debug_output.contains(sentinel),
            "BC-2.14.005 {{INV-002}}: Debug output must not contain any substring of the key; \
             sentinel found in: {:?}",
            debug_output
        );
        assert_eq!(
            debug_output, "<redacted>",
            "BC-2.14.005 {{PC-002}}: exact match required"
        );
    }

    /// AC-009 (traces to BC-2.14.005 {PC-005}, TV-004)
    ///
    /// `expose_secret()` is the ONLY intentional path to the inner key value.
    /// It returns the exact string passed to `new()`.
    ///
    /// GREEN: `new()` is implemented — `expose_secret()` returns the exact key string.
    #[test]
    fn test_BC_2_14_005_openai_expose_secret_returns_inner_value() {
        let secret = "sk-the-exact-secret-value";
        let key = OpenAiApiKey::new(secret).expect("valid key must succeed");
        assert_eq!(
            key.expose_secret(),
            secret,
            "BC-2.14.005 {{PC-005}}: expose_secret() must return the exact key string"
        );
    }

    /// AC-009 (traces to BC-2.14.005 {PC-005}, TV-004)
    ///
    /// `AnthropicApiKey::expose_secret()` returns the exact inner value.
    ///
    /// GREEN: `new()` is implemented — `expose_secret()` returns the exact key string.
    #[test]
    fn test_BC_2_14_005_anthropic_expose_secret_returns_inner_value() {
        let secret = "sk-ant-the-exact-secret-value";
        let key = AnthropicApiKey::new(secret).expect("valid key must succeed");
        assert_eq!(
            key.expose_secret(),
            secret,
            "BC-2.14.005 {{PC-005}}: AnthropicApiKey::expose_secret() must return the exact key string"
        );
    }

    // ── BC-2.14.006 Tests ─────────────────────────────────────────────────────

    /// AC-011 (traces to BC-2.14.006 {PC-001}, TV-005, EC-004)
    ///
    /// `OpenAiApiKey::new("")` returns `Err(PregolyaError { category: VAL, .. })`.
    /// Empty-string validation failure must propagate as `Err`, never panic,
    /// never return `None` or a default value.
    ///
    /// GREEN: `new()` is implemented — empty input returns `Err` with category VAL.
    #[test]
    fn test_BC_2_14_006_openai_empty_key_returns_err() {
        let result = OpenAiApiKey::new("");
        assert!(
            result.is_err(),
            "BC-2.14.006 {{PC-001}}: empty key must return Err(PregolyaError {{ category: VAL }});\
             must not panic or return Ok"
        );
    }

    /// AC-011 (traces to BC-2.14.006 {PC-001}, TV-005, EC-004)
    ///
    /// `AnthropicApiKey::new("")` returns `Err` — same contract as OpenAI.
    ///
    /// GREEN: `new()` is implemented — empty input returns `Err` with category VAL.
    #[test]
    fn test_BC_2_14_006_anthropic_empty_key_returns_err() {
        let result = AnthropicApiKey::new("");
        assert!(
            result.is_err(),
            "BC-2.14.006 {{PC-001}}: empty key must return Err; must not panic or return Ok"
        );
    }

    /// AC-014 (traces to BC-2.14.006 {PC-004}, TV-005)
    ///
    /// Validation error code is always `"E-CORE-005"` and the category is `Category::Val`.
    ///
    /// GREEN: `new("")` is implemented — returns `Err` with code `"E-CORE-005"` and `Category::Val`.
    #[test]
    fn test_BC_2_14_006_openai_error_code_is_e_core_005() {
        let err = OpenAiApiKey::new("").unwrap_err();
        assert_eq!(
            err.code(),
            "E-CORE-005",
            "BC-2.14.006 {{PC-004}}: validation error code must be 'E-CORE-005'; got: {:?}",
            err.code()
        );
        assert!(
            matches!(err.category, Category::Val),
            "BC-2.14.006 {{PC-001}}: category must be Val; got: {:?}",
            err.category
        );
    }

    /// AC-014 (traces to BC-2.14.006 {PC-004}, TV-005, v1.6)
    ///
    /// Validation error message format is `"Validation failed for '<field>': <reason>"`.
    /// Per BC-2.14.006 PC-004 v1.6, the reason must cover BOTH the empty-string and
    /// whitespace-only cases: `"value must not be empty or whitespace-only"`.
    ///
    /// GREEN: implementation emits the widened canonical message containing
    /// `"whitespace-only"` per BC-2.14.006 PC-004 v1.6 / EC-006.
    #[test]
    fn test_BC_2_14_006_openai_error_message_format() {
        let err = OpenAiApiKey::new("").unwrap_err();
        // BC-2.14.006 {PC-004}: message must start with "Validation failed for"
        assert!(
            err.message.starts_with("Validation failed for"),
            "BC-2.14.006 {{PC-004}}: message must start with 'Validation failed for'; got: {:?}",
            err.message
        );
        // Message must name the validated field (api_key or key)
        assert!(
            err.message.contains("api_key") || err.message.contains("key"),
            "BC-2.14.006 {{PC-004}}: message must name the field ('api_key' or 'key'); got: {:?}",
            err.message
        );
        // BC-2.14.006 {PC-004} v1.6 / EC-006: reason must cover the whitespace-only case.
        // The widened canonical form is "value must not be empty or whitespace-only".
        assert!(
            err.message.contains("whitespace-only"),
            "BC-2.14.006 {{PC-004}} v1.6: message reason must contain 'whitespace-only' \
             (a whitespace-only key produces a malformed bearer token — reject at construction); \
             got: {:?}",
            err.message
        );
    }

    /// AC-011 (traces to BC-2.14.006 {INV-003})
    ///
    /// `VAL` category always implies `retry_hint: Never` — the input must change;
    /// retrying the same empty key will never succeed.
    ///
    /// GREEN: `new("")` is implemented — returns `Err` with `RetryHint::Never`.
    #[test]
    fn test_BC_2_14_006_val_retry_hint_is_never() {
        let err = OpenAiApiKey::new("").unwrap_err();
        assert!(
            matches!(err.retry_hint, RetryHint::Never),
            "BC-2.14.006 {{INV-003}}: VAL errors must carry RetryHint::Never; got: {:?}",
            err.retry_hint
        );
    }

    /// AC-012 (traces to BC-2.14.006 {PC-003})
    ///
    /// Validation failures NEVER return `None`, empty `Vec`, or zero-value defaults.
    /// A table-driven test over ALL invalid inputs `["", "   "]` asserts each returns
    /// `Err(PregolyaError { code: "E-CORE-005", category: Val, retry_hint: Never })`
    /// for BOTH `OpenAiApiKey` and `AnthropicApiKey`.
    /// Additionally, valid inputs return `Ok(T)` where the inner value is accessible
    /// (not a silent empty/default).
    ///
    /// GREEN: `new()` is implemented — all invalid inputs return `Err` with the canonical
    /// error fields, and valid inputs return `Ok(T)`.
    #[test]
    fn test_BC_2_14_006_no_silent_default_on_invalid_inputs() {
        // All of these must return Err — no silent None, no empty default.
        // Both inputs are definitively rejected (E-CORE-005 / VAL / Never):
        // "" → EC-004 (empty string); "   " → EC-006 (whitespace-only, per BC-2.14.006 v1.6).
        let invalid_inputs = ["", "   "];

        for input in invalid_inputs {
            let openai_result = OpenAiApiKey::new(input);
            assert!(
                openai_result.is_err(),
                "BC-2.14.006 {{PC-003}}: OpenAiApiKey input {:?} must return Err, not None or Ok(default)",
                input
            );
            let openai_err = openai_result.unwrap_err();
            assert_eq!(
                openai_err.code(),
                "E-CORE-005",
                "BC-2.14.006 {{PC-003}}: OpenAiApiKey input {:?} must yield code 'E-CORE-005'; got: {:?}",
                input,
                openai_err.code()
            );
            assert!(
                matches!(openai_err.category, Category::Val),
                "BC-2.14.006 {{PC-003}}: OpenAiApiKey input {:?} must yield Category::Val; got: {:?}",
                input,
                openai_err.category
            );
            assert!(
                matches!(openai_err.retry_hint, RetryHint::Never),
                "BC-2.14.006 {{PC-003}}: OpenAiApiKey input {:?} must yield RetryHint::Never; got: {:?}",
                input,
                openai_err.retry_hint
            );

            let anthropic_result = AnthropicApiKey::new(input);
            assert!(
                anthropic_result.is_err(),
                "BC-2.14.006 {{PC-003}}: AnthropicApiKey input {:?} must return Err, not None or Ok(default)",
                input
            );
            let anthropic_err = anthropic_result.unwrap_err();
            assert_eq!(
                anthropic_err.code(),
                "E-CORE-005",
                "BC-2.14.006 {{PC-003}}: AnthropicApiKey input {:?} must yield code 'E-CORE-005'; got: {:?}",
                input,
                anthropic_err.code()
            );
            assert!(
                matches!(anthropic_err.category, Category::Val),
                "BC-2.14.006 {{PC-003}}: AnthropicApiKey input {:?} must yield Category::Val; got: {:?}",
                input,
                anthropic_err.category
            );
            assert!(
                matches!(anthropic_err.retry_hint, RetryHint::Never),
                "BC-2.14.006 {{PC-003}}: AnthropicApiKey input {:?} must yield RetryHint::Never; got: {:?}",
                input,
                anthropic_err.retry_hint
            );
        }

        // Valid input must return Ok(T) where expose_secret() returns a non-empty value
        let valid_result = OpenAiApiKey::new("sk-valid-key");
        assert!(
            valid_result.is_ok(),
            "BC-2.14.006 {{PC-003}}: valid input must return Ok(T)"
        );
        let key = valid_result.unwrap();
        assert!(
            !key.expose_secret().is_empty(),
            "BC-2.14.006 {{PC-003}}: Ok value must carry the actual non-empty key string"
        );
    }

    /// AC-014 (traces to BC-2.14.006 {PC-004}) — table-driven coverage
    ///
    /// Two credential newtypes (`OpenAiApiKey` and `AnthropicApiKey`), each supplied an
    /// empty-string input, both return `Err` with code `"E-CORE-005"` (category `VAL`)
    /// and a message starting with `"Validation failed for"`.
    ///
    /// GREEN: `new("")` is implemented — returns `Err` with code `"E-CORE-005"` and the canonical message format.
    #[test]
    fn test_BC_2_14_006_error_code_and_format_table() {
        // BC-2.14.006 {EC-005}: empty string and whitespace-only string return Err.
        // Asserts directly over OpenAiApiKey::new("") and AnthropicApiKey::new("").
        let openai_err = OpenAiApiKey::new("").unwrap_err();
        assert_eq!(openai_err.code(), "E-CORE-005");
        assert!(openai_err.message.starts_with("Validation failed for"));

        let anthropic_err = AnthropicApiKey::new("").unwrap_err();
        assert_eq!(anthropic_err.code(), "E-CORE-005");
        assert!(anthropic_err.message.starts_with("Validation failed for"));

        // Both errors must carry VAL category
        assert!(matches!(openai_err.category, Category::Val));
        assert!(matches!(anthropic_err.category, Category::Val));
    }

    // ── BC-2.14.006 v1.6 / EC-006 (S-1.02 AC-016 / F-07) — whitespace-only ────

    /// AC-016 (traces to BC-2.14.006 {EC-006}, TV-006, v1.6)
    ///
    /// `OpenAiApiKey::new("   ")` (whitespace-only string) must return
    /// `Err(PregolyaError { category: VAL, code: E-CORE-005, retry_hint: Never })`.
    /// A whitespace-only key produces `"Bearer   "` at the HTTP layer — a malformed
    /// bearer token that fails silently at the provider boundary.
    ///
    /// GREEN: implementation applies `.trim()` then empty-check — whitespace-only inputs
    /// are rejected with E-CORE-005 per BC-2.14.006 PC-004 v1.6 / EC-006.
    #[test]
    fn test_BC_2_14_006_openai_whitespace_only_key_returns_err() {
        let result = OpenAiApiKey::new("   ");
        assert!(
            result.is_err(),
            "BC-2.14.006 {{EC-006}}: whitespace-only key must return Err — would produce \
             malformed bearer token 'Bearer   ' at provider boundary; got: Ok"
        );
    }

    /// AC-016 (traces to BC-2.14.006 {EC-006}, TV-006, v1.6)
    ///
    /// `AnthropicApiKey::new("   ")` must return `Err` — same contract as OpenAI.
    ///
    /// GREEN: `.trim()` + empty-check applied — whitespace-only inputs are rejected.
    #[test]
    fn test_BC_2_14_006_anthropic_whitespace_only_key_returns_err() {
        let result = AnthropicApiKey::new("   ");
        assert!(
            result.is_err(),
            "BC-2.14.006 {{EC-006}}: AnthropicApiKey::new(\"   \") whitespace-only must return \
             Err; got: Ok"
        );
    }

    /// AC-016 (traces to BC-2.14.006 {EC-006} / {PC-004} v1.6, TV-006)
    ///
    /// The whitespace-only rejection error must carry:
    /// - `code: "E-CORE-005"`
    /// - `category: Category::Val`
    /// - `retry_hint: RetryHint::Never`
    /// - message containing "whitespace-only"
    ///
    /// GREEN: `new("   ")` returns `Err(...)` — `unwrap_err()` succeeds and
    /// all field assertions are reached.
    #[test]
    fn test_BC_2_14_006_whitespace_key_error_fields() {
        let err = OpenAiApiKey::new("   ").unwrap_err();
        assert_eq!(
            err.code(),
            "E-CORE-005",
            "BC-2.14.006 {{EC-006}}: whitespace-only rejection must use code 'E-CORE-005'; \
             got: {:?}",
            err.code()
        );
        assert!(
            matches!(err.category, Category::Val),
            "BC-2.14.006 {{EC-006}}: whitespace-only rejection must carry Category::Val; \
             got: {:?}",
            err.category
        );
        assert!(
            matches!(err.retry_hint, RetryHint::Never),
            "BC-2.14.006 {{EC-006}} / {{INV-003}}: VAL errors must carry RetryHint::Never; \
             got: {:?}",
            err.retry_hint
        );
        assert!(
            err.message.contains("whitespace-only"),
            "BC-2.14.006 {{EC-006}} / {{PC-004}} v1.6: message must contain 'whitespace-only'; \
             got: {:?}",
            err.message
        );
    }

    /// F-P3-L01 — BC-2.14.006 {PC-004} / credential safety
    ///
    /// `OpenAiApiKey::new("  sk-abc  ")` must trim the whitespace and store `"sk-abc"`.
    /// Without trimming, `expose_secret()` would return `"  sk-abc  "` which becomes
    /// `"Bearer   sk-abc  "` — a malformed HTTP Authorization header.
    ///
    /// The same trim is applied to `AnthropicApiKey::new()` (sibling sweep, TD-VSDD-060).
    #[test]
    fn test_BC_2_14_006_new_trims_whitespace() {
        let key = OpenAiApiKey::new("  sk-abc  ").expect("non-empty after trim must succeed");
        assert_eq!(
            key.expose_secret(),
            "sk-abc",
            "new() must trim leading/trailing whitespace before storing"
        );
        let anthropic_key =
            AnthropicApiKey::new("  sk-ant-xyz  ").expect("non-empty after trim must succeed");
        assert_eq!(
            anthropic_key.expose_secret(),
            "sk-ant-xyz",
            "AnthropicApiKey::new() must also trim leading/trailing whitespace"
        );
    }

    /// AC-016 (traces to BC-2.14.006 {PC-004} v1.6 / TV-005 update)
    ///
    /// The empty-key error message must ALSO contain "whitespace-only" now that
    /// BC-2.14.006 PC-004 v1.6 widens the message to
    /// `"value must not be empty or whitespace-only"`.
    ///
    /// GREEN: error message is `"value must not be empty or whitespace-only"` —
    /// the widened canonical form per BC-2.14.006 PC-004 v1.6 is in place.
    #[test]
    fn test_BC_2_14_006_empty_key_error_message_widened_to_whitespace() {
        let err = OpenAiApiKey::new("").unwrap_err();
        assert!(
            err.message.contains("whitespace-only"),
            "BC-2.14.006 {{PC-004}} v1.6: empty-key error message must include \
             'whitespace-only' (widened canonical form covers both empty and \
             whitespace-only inputs); got: {:?}",
            err.message
        );
        // Canonical full message per BC-2.14.006 PC-004 v1.6:
        assert!(
            err.message
                .contains("value must not be empty or whitespace-only"),
            "BC-2.14.006 {{PC-004}} v1.6 canonical message fragment not found; got: {:?}",
            err.message
        );
    }
}
