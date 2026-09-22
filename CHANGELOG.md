# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- **No-panic CI enforcement** (`cargo xtask check-no-panic`): AST-based scan of all `crates/` production source files that flags `unwrap()`, `expect()`, bare `assert!` without `# Panics` doc and BC-ID message, and wildcard `_ => unreachable!()` arms; exempts `debug_assert!`, exhaustive-match `unreachable!`, and programmer-error guards with compliant doc+message pattern (BC-2.14.003).
- **HTTP client timeout CI enforcement** (`cargo xtask check-client-timeout`): source scan that flags `reqwest::ClientBuilder` chains missing `.timeout(duration > 0)` before `.build()` and any bare `reqwest::Client::new()` in non-test production code (BC-2.14.004).
- **Credential structural safety CI gate** (`cargo xtask deny-bare-api-key`): structural scanner that flags public structs with credential-sentinel names (`key`, `token`, `secret`, `credential`, `auth`, `bearer`, `password`, `passphrase`) that auto-derive `Debug` (without a manual redacted impl), derive `Serialize`, derive `Deserialize` (bypasses `new()` validation), implement `Display`, or implement `Deref<Target=str/String>` (BC-2.14.005).
- **Error-code registry CI enforcement** (`cargo xtask check-error-code-registry`): parses `.factory/specs/prd-supplements/error-taxonomy.md` and fails the build if any `E-<COMPONENT>-<NNN>` code appears more than once; exits 1 with a descriptive error if zero codes are extracted (vacuity guard — detects taxonomy format changes); taxonomy path resolved via `FACTORY_DIR` env var (set by CI factory-artifacts checkout step) or `.factory/` relative fallback when `FACTORY_DIR` is absent or empty (BC-2.14.001, VP-BC214001-01).
- **`OpenAiApiKey` and `AnthropicApiKey` credential newtypes** in `pregolya-core`: private-field newtypes with manually-implemented redacted `Debug` (emits exactly `"<redacted>"`); fallible construction via `new() -> Result<Self, PregolyaError>`; infallible `From<String>`/`From<&str>` conversions are structurally forbidden and pinned by `static_assertions::assert_not_impl_any!` (BC-2.14.006 EC-005); no `Serialize`, `Deserialize`, `Display`, `Deref`, or `AsRef<str>`; compile-time `static_assertions` enforce all exclusions (BC-2.14.005, BC-2.14.006).
- **`build_client()` HTTP client factory** in `pregolya-core`: `reqwest::ClientBuilder` wrapper enforcing 30-second total timeout with `rustls-tls` backend; maps `ClientBuilder::build()` failure to `PregolyaError { category: TRANSPORT, code: "E-CORE-012", retry_hint: Never }` (BC-2.14.004).
- **Validation error propagation** (`E-CORE-005`): `OpenAiApiKey::new("")` and `::new("   ")` return `Err(PregolyaError { category: VAL, code: "E-CORE-005", message: "Validation failed for 'api_key': value must not be empty or whitespace-only", retry_hint: Never })`; no silent `None` or default returns (BC-2.14.006).
