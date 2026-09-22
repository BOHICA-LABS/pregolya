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
#[allow(dead_code)] // field read only via expose_secret(); todo!() until S-1.02 implemented
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
    pub fn new(_key: impl Into<String>) -> Result<Self, PregolyaError> {
        todo!(
            "BC-2.14.005 PC-001 + BC-2.14.006 PC-001: \
             validate non-empty key and return Err(E-CORE-005) for empty input"
        )
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
        todo!("BC-2.14.005 PC-005: return &self.0 for explicit secret access")
    }
}

// ─── AnthropicApiKey ──────────────────────────────────────────────────────────

/// API key for the Anthropic (Claude) provider.
///
/// Same invariants as [`OpenAiApiKey`]: `Debug` emits `"<redacted>"`, no
/// `Serialize`, no `Deref<Target=str>`, no `AsRef<str>`.
#[non_exhaustive]
#[allow(dead_code)] // field read only via expose_secret(); todo!() until S-1.02 implemented
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
    pub fn new(_key: impl Into<String>) -> Result<Self, PregolyaError> {
        todo!(
            "BC-2.14.005 PC-001 + BC-2.14.006 PC-001: \
             validate non-empty key and return Err(E-CORE-005) for empty input"
        )
    }

    /// Returns a reference to the inner key string.
    ///
    /// This is the ONLY intentional exposure path for the key value (BC-2.14.005 {PC-005}).
    pub fn expose_secret(&self) -> &str {
        todo!("BC-2.14.005 PC-005: return &self.0 for explicit secret access")
    }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used, non_snake_case)]
mod tests {
    use super::*;

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
}
