---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.005
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-14
capability: CAP-016
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-core per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-010
  - NE-10
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "c41a075"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.005: API Key Newtype with Redacted Debug; No Serialize; No Deref<Target=str>

## Description

Every API key or secret credential type in ferrochain must be a newtype struct (not a bare
`String` or `&str`). The `Debug` implementation must emit the literal `"<redacted>"` and
never expose the key value. The type must not `#[derive(Serialize)]` and must not
`impl Deref<Target = str>`. CI lint enforces this. This contract addresses NE-10
(adk-rust's bare-String API keys with `#[derive(Debug)]` that leak secrets to logs).

## Preconditions

1. A ferrochain crate defines a type intended to carry an API key or secret credential value.
2. The type is declared in non-test code (`!#[cfg(test)]` scope).
3. The implementing engineer is writing or modifying the key type definition.

## Postconditions

1. The key type is a newtype struct: `pub struct FooApiKey(String)` (or `Arc<str>` variant) — not a type alias.
2. `impl fmt::Debug for FooApiKey` emits exactly `"<redacted>"` — no substring of the actual key value appears in any format specifier.
3. The type does NOT `#[derive(Serialize)]` (serde serialization is explicitly absent or gated behind an internal-use-only feature).
4. The type does NOT `impl Deref<Target = str>` or `impl Deref<Target = String>`.
5. The type provides an `.as_str()` or `.expose_secret()` method (or similar) for the narrow use-case of passing the value to an HTTP client; calling sites are explicit opt-in.
6. CI lint gate (`cargo xtask deny-bare-api-key` or equivalent custom lint) causes the build to fail if any public struct carrying "key", "token", "secret", or "credential" in its name derives `Debug` without a manual impl, derives `Serialize`, or impls `Deref<Target=str>`.

## Invariants

- **DI-010 (Credential Opacity):** Credentials never appear in log output, error messages, serialized artifacts, or formatted strings under any execution path.
- The redacted string literal must be exactly `"<redacted>"` (matching the ferrochain-standard log-scrubber pattern so automated log scanning tools can detect accidental exposures).
- Inner value is only accessible via an explicit `expose_secret()` / `inner()` call — never via trait auto-deref.

## Edge Cases

### EC-001: Accidentally serialized key via serde
**Scenario:** A type containing `FooApiKey` is serialized with `serde_json::to_string`. The `FooApiKey` field does not derive `Serialize`.
**Expected behavior:** Compilation error — the parent struct's `#[derive(Serialize)]` fails if `FooApiKey` does not implement `Serialize`. The key cannot be silently serialized.
**Reference:** NE-10; DI-010.

### EC-002: Debug format in error context
**Scenario:** `anyhow::Error` or `FerrochainError` wraps a value containing a `FooApiKey` and is formatted via `{:?}`.
**Expected behavior:** The formatted output contains `"<redacted>"` for the key field, never the actual key bytes.

### EC-003: Log macro with API key struct
**Scenario:** `tracing::debug!("{:?}", api_key)` is called with a key instance.
**Expected behavior:** The log record contains the string `FooApiKey(<redacted>)` (or similar `<redacted>` output), never the key value.

### EC-004: Clone does not expose inner value
**Scenario:** A `FooApiKey` is `Clone`'d for use across threads.
**Expected behavior:** `Clone` is permitted and does not involve `Debug` or `Display` output. The cloned value retains opacity.

### EC-005: Comparison in tests uses expose_secret
**Scenario:** A unit test asserts that a parsed config contains the correct API key.
**Expected behavior:** Test calls `api_key.expose_secret() == "expected-value"` explicitly. The assertion does not rely on `Debug` or `PartialEq` with the raw string.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `format!("{:?}", FooApiKey::new("sk-real-secret"))` | `"FooApiKey(<redacted>)"` (or `"<redacted>"`) | Happy path — debug output is opaque |
| TV-002 | `serde_json::to_string(&FooApiKey::new("sk-real-secret"))` | Compilation error (`Serialize` not impl'd) | Key type must not be serializable |
| TV-003 | Attempt `let s: &str = &api_key` via `Deref` | Compilation error (`Deref` not impl'd) | No silent deref to str |
| TV-004 | `api_key.expose_secret()` returns `"sk-real-secret"` | `"sk-real-secret"` — explicit access works | Explicit opt-in path |
| TV-005 | CI lint runs on crate containing `pub struct OpenAiApiKey(String)` with `#[derive(Debug)]` | Lint error: `"OpenAiApiKey" carries credential name; manual Debug impl required` | Lint gate enforcement |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI010-01 | `Debug` output of any `*ApiKey` / `*Token` / `*Secret` type contains `<redacted>` literal | Property test (proptest over random key strings) | Phase 1 |
| VP-DI010-02 | No `Serialize` impl on credential newtypes (compile-time) | CI lint / `cargo check` | Wave 0 CI |
| VP-DI010-03 | No `Deref<Target=str>` on credential newtypes (compile-time) | CI lint | Wave 0 CI |

## Related BCs

- BC-2.14.001 — FerrochainError 2D struct (composes with: error type that wraps credentials must also redact)
- BC-2.14.003 — Constructor Result contract (depends on: key construction returns `Result<FooApiKey, FerrochainError>`, not panic)
- BC-2.14.006 — Validation failure propagation (depends on: empty/malformed key string → `Err`, not `None`)

## Architecture Anchors

- `ferrochain-core/src/credentials.rs` (to be created)
- CI: `cargo xtask deny-bare-api-key` lint target

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-DI010-01, VP-DI010-02, VP-DI010-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (FerrochainError 2D Struct)") per capabilities-p0.md §CAP-016 — credential opacity is a direct sub-requirement of the error taxonomy surface; specifically the NE-10 counter-example (adk-rust bare-String API keys) is explicitly listed under CAP-016's grounding |
| L2 Domain Invariants | DI-010 (Credential Opacity) |
| NE References | NE-10 |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CI lint |
| Module | ferrochain-core |
