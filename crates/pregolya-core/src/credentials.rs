//! Credential newtypes for the pregolya workspace.
//!
//! Every API key or secret credential in pregolya is a newtype struct (not a
//! bare `String` or type alias). The [`fmt::Debug`] implementation emits exactly
//! `"<redacted>"` — no substring of the actual key value ever appears in any
//! format specifier (BC-2.14.005 {PC-002}, {INV-002}).
//!
//! # Invariants
//!
//! - No `#[derive(Serialize)]` — credential values must not appear in API responses
//!   or log artifacts (BC-2.14.005 {PC-003}).
//! - No `impl Deref<Target=str>` or `impl AsRef<str>` — access to the inner value
//!   is gated behind the explicit `.expose_secret()` method (BC-2.14.005 {PC-004},
//!   {INV-003}).
//! - Empty key strings are rejected at construction time — `new("")` returns
//!   `Err(PregolyaError { category: VAL, code: "E-CORE-005" })` (BC-2.14.006 {PC-001}).
//! - All public key types carry `#[non_exhaustive]` to prevent external struct-literal
//!   construction; callers must use `FooApiKey::new()` (CLAUDE.md `#[non_exhaustive]` rule).

use std::fmt;

use crate::error::PregolyaError;

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
pub struct OpenAiApiKey(pub(crate) String);

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
    /// message: "Validation failed for 'api_key': value must not be empty" })` when
    /// `key` is an empty string (BC-2.14.006 {PC-001}, BC-2.14.005 EC-004).
    pub fn new(key: impl Into<String>) -> Result<Self, PregolyaError> {
        let key = key.into();
        if key.is_empty() {
            return Err(PregolyaError::new(
                crate::error::Component::Core,
                crate::error::Category::Val,
                crate::error::RetryHint::Never,
                "E-CORE-005",
                "Validation failed for 'api_key': value must not be empty",
            ));
        }
        Ok(Self(key))
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

// ─── AnthropicApiKey ──────────────────────────────────────────────────────────

/// API key for the Anthropic (Claude) provider.
///
/// Same invariants as [`OpenAiApiKey`]: `Debug` emits `"<redacted>"`, no
/// `Serialize`, no `Deref<Target=str>`, no `AsRef<str>`.
#[non_exhaustive]
pub struct AnthropicApiKey(pub(crate) String);

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
    /// message: "Validation failed for 'api_key': value must not be empty" })` when
    /// `key` is an empty string (BC-2.14.006 {PC-001}, BC-2.14.005 EC-004).
    pub fn new(key: impl Into<String>) -> Result<Self, PregolyaError> {
        let key = key.into();
        if key.is_empty() {
            return Err(PregolyaError::new(
                crate::error::Component::Core,
                crate::error::Category::Val,
                crate::error::RetryHint::Never,
                "E-CORE-005",
                "Validation failed for 'api_key': value must not be empty",
            ));
        }
        Ok(Self(key))
    }

    /// Returns a reference to the inner key string.
    ///
    /// This is the ONLY intentional exposure path for the key value (BC-2.14.005 {PC-005}).
    pub fn expose_secret(&self) -> &str {
        &self.0
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

    // AC-009: No Serialize impl (serde_json::to_string would fail to compile if present).
    // Note: serde::Serialize assertion is not needed here — the type simply doesn't
    // derive Serialize, so any attempt to serialize it fails at compile time.

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
    /// RED GATE: `OpenAiApiKey::new` is `todo!()` — panics until implementation.
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
    /// RED GATE: `new()` is `todo!()` — panics until implementation.
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
    /// RED GATE: `new()` is `todo!()` — panics until implementation.
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
    /// GREEN-BY-DESIGN: the `Debug` implementation is already in the stub; this test does NOT
    /// call `new()` and therefore does NOT red-gate on the todo!() constructor.
    #[test]
    fn test_BC_2_14_005_openai_debug_emits_redacted_sentinel() {
        // Construct directly within the crate (struct-literal allowed inside the defining crate
        // even though the type is non_exhaustive externally).
        // This avoids calling the todo!() new() constructor.
        let key = OpenAiApiKey("sk-real-secret-value".to_string());
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
    /// GREEN-BY-DESIGN: same rationale as the OpenAI variant above.
    #[test]
    fn test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel() {
        let key = AnthropicApiKey("sk-ant-real-secret-value".to_string());
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
    /// GREEN-BY-DESIGN: does NOT call the todo!() constructor.
    #[test]
    fn test_BC_2_14_005_debug_does_not_leak_key_material() {
        let sentinel = "LEAK_SENTINEL_ABC123_DO_NOT_LOG";
        let key = OpenAiApiKey(sentinel.to_string());
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

    /// AC-010 (traces to BC-2.14.005 {PC-005}, TV-004)
    ///
    /// `expose_secret()` is the ONLY intentional path to the inner key value.
    /// It returns the exact string passed to `new()`.
    ///
    /// RED GATE: `new()` is `todo!()` — panics until implementation.
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

    /// AC-010 (traces to BC-2.14.005 {PC-005}, TV-004)
    ///
    /// `AnthropicApiKey::expose_secret()` returns the exact inner value.
    ///
    /// RED GATE: `new()` is `todo!()` — panics until implementation.
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
    /// RED GATE: `new()` is `todo!()` — panics until implementation.
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
    /// RED GATE: `new()` is `todo!()` — panics until implementation.
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
    /// RED GATE: `new("")` is `todo!()` — panics until implementation.
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
    /// RED GATE: current implementation emits the narrower message
    /// `"value must not be empty"` (no "or whitespace-only") — the
    /// `contains("whitespace-only")` assertion fails until the implementer
    /// widens the message per BC-2.14.006 PC-004 v1.6 / EC-006.
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
    /// RED GATE: `new("")` is `todo!()` — panics until implementation.
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
    /// A property-style table test over known invalid inputs asserts all return `Err(...)`.
    /// Additionally, valid inputs return `Ok(T)` where the inner value is accessible
    /// (not a silent empty/default).
    ///
    /// RED GATE: `new()` is `todo!()` — panics until implementation.
    #[test]
    fn test_BC_2_14_006_no_silent_default_on_invalid_inputs() {
        // All of these must return Err — no silent None, no empty default
        let invalid_inputs = ["", "   "];
        // Note: whitespace-only may or may not be valid depending on implementation;
        // empty string is the canonical BC-2.14.006 EC-004 case.
        let empty_result = OpenAiApiKey::new(invalid_inputs[0]);
        assert!(
            empty_result.is_err(),
            "BC-2.14.006 {{PC-003}}: empty string must return Err, not None or Ok(default)"
        );

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
    /// Five distinct invalid inputs across credential types all return `Err` with
    /// code `"E-CORE-005"` and message format `"Validation failed for '<field>': <reason>"`.
    ///
    /// RED GATE: `new("")` is `todo!()` — panics until implementation.
    #[test]
    fn test_BC_2_14_006_error_code_and_format_table() {
        // Table: (constructor, input, must_be_err)
        // Only empty string is a guaranteed failure per the current BCs;
        // other patterns may be added by the implementer.
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
    /// RED GATE: current implementation only checks `key.is_empty()`. A string of
    /// spaces passes the empty check and `new("   ")` returns `Ok(...)` instead of
    /// `Err(...)` — the assertion `result.is_err()` fails until the implementer
    /// adds `.trim()` + empty check per BC-2.14.006 PC-004 v1.6 / EC-006.
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
    /// RED GATE: same as OpenAI — current `is_empty()` check misses whitespace-only.
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
    /// RED GATE: `new("   ")` currently returns `Ok(...)` so `unwrap_err()` panics,
    /// failing this test even before the field assertions are reached.
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

    /// AC-016 (traces to BC-2.14.006 {PC-004} v1.6 / TV-005 update)
    ///
    /// The empty-key error message must ALSO contain "whitespace-only" now that
    /// BC-2.14.006 PC-004 v1.6 widens the message to
    /// `"value must not be empty or whitespace-only"`.
    ///
    /// RED GATE: current error message is `"value must not be empty"` (no
    /// "whitespace-only") — fails until the implementer widens both the message
    /// AND the validation check per BC-2.14.006 PC-004 v1.6.
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
