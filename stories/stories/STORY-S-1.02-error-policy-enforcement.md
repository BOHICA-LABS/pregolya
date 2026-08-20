---
document_type: story
level: ops
story_id: S-1.02
epic_id: E-01
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.003.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.004.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.005.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "13bd5c7"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.01]
blocks: [S-1.04, S-1.06, S-1.09, S-1.10, S-1.12, S-2.01, S-2.04, S-2.09]
behavioral_contracts: [BC-2.14.003, BC-2.14.004, BC-2.14.005, BC-2.14.006]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-core
subsystems: [SS-14]
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.02: Error Policy Enforcement — No-Panic, HTTP Timeout, Credential Newtypes, Validation Propagation

## Narrative

- **As a** pregolya library author
- **I want to** have CI-enforced policies that prevent panics in production code, require HTTP client timeouts, protect API key material from leaking via Debug, and mandate Result propagation for validation failures
- **So that** every crate in the pregolya family has uniform safety guarantees — no surprise panics in production, no hanging HTTP calls, no credential leakage, and no silent null-coercion for invalid input

## Acceptance Criteria

### AC-001 (traces to BC-2.14.003 postcondition 1)
Every fallible public constructor in `pregolya-core` returns `Result<T, PregolyaError>` rather than panicking. A compile-fail test verifies that calling an example fallible constructor that previously panicked now returns `Err`. Verified by `test_BC_2_14_003_constructor_returns_result()`.

### AC-002 (traces to BC-2.14.003 postcondition 2)
`cargo xtask check-no-panic` exits 0 on the initial `pregolya-core/src/` tree (no `unwrap()` or `expect()` in non-test code paths). The xtask itself is created as part of this story. Verified by the xtask executing successfully in CI.

### AC-003 (traces to BC-2.14.003 postcondition 3)
`debug_assert!()`, `unreachable!()` in exhaustive match arms, and test files are exempt from the no-panic xtask scan. The xtask grep pattern excludes `#[cfg(test)]` blocks and the three documented exemptions. Verified by `test_BC_2_14_003_exemptions_respected()` which places a `debug_assert!` in a non-test context and confirms the xtask still exits 0.

### AC-004 (traces to BC-2.14.004 postcondition 1)
A `reqwest::ClientBuilder`-based helper in `pregolya-core` (utility for provider crates) calls `.timeout(Duration::from_secs(30))` by default. `reqwest::Client::new()` is NOT used in any production path in `pregolya-core`. Verified by `test_BC_2_14_004_default_timeout_applied()`.

### AC-005 (traces to BC-2.14.004 postcondition 2)
`cargo xtask check-client-timeout` scans `crates/` for `reqwest::Client::new()` and `ClientBuilder` patterns missing `.timeout(...)`, and exits non-zero if any are found. The xtask is created as part of this story. Verified by the xtask executing successfully in CI.

### AC-006 (traces to BC-2.14.004 postcondition 3)
A `reqwest` client timeout fires and the error is returned as `Err(PregolyaError { category: TIMEOUT, code: "E-PROV-002", message: "ProviderTimeout: request timed out after 30s", .. })`. Verified by `test_BC_2_14_004_timeout_error_shape()` using a mock server that never responds within the configured timeout.

### AC-007 (traces to BC-2.14.005 postcondition 1)
`OpenAiApiKey`, `AnthropicApiKey`, and any other API key types in `pregolya-core` are newtypes (`pub struct FooApiKey(String)`), NOT type aliases. `static_assertions::assert_not_impl_any!(OpenAiApiKey: Clone)` — or if Clone is needed for config snapshots, `derive(Clone)` is allowed but `Deref<Target=str>` is NOT allowed. Verified by `test_BC_2_14_005_newtype_not_alias()`.

### AC-008 (traces to BC-2.14.005 postcondition 2)
`format!("{:?}", OpenAiApiKey("sk-real".to_string()))` returns exactly `"<redacted>"` — no substring of the key value. `format!("{:?}", AnthropicApiKey("sk-ant-real".to_string()))` returns exactly `"<redacted>"`. Verified by `test_BC_2_14_005_debug_redacted()`.

### AC-009 (traces to BC-2.14.005 postcondition 3)
No `#[derive(Serialize)]` on API key newtypes (they must not appear in API responses). No `impl Deref<Target=str>` or `impl AsRef<str>` that exposes the inner value (the `.as_str()` or `.expose_secret()` method is the only intentional exposure path). Verified by compile-fail test or `static_assertions::assert_not_impl_any!(OpenAiApiKey: AsRef<str>)`.

### AC-010 (traces to BC-2.14.005 postcondition 4)
`cargo xtask deny-bare-api-key` scans `crates/` for string literals matching `sk-`, `sk-ant-`, and similar provider key prefixes in non-test source, and exits non-zero if found. Verified by the xtask executing successfully in CI.

### AC-011 (traces to BC-2.14.006 postcondition 1)
A validation failure on a public constructor — e.g., `Message::human("")` with an empty content body — returns `Err(PregolyaError { category: VAL, retry_hint: Never, code: "E-CORE-005", message: "Validation failed for 'content': must not be empty", .. })`. Verified by `test_BC_2_14_006_validation_failure_returns_err()`.

### AC-012 (traces to BC-2.14.006 postcondition 2)
Validation failures NEVER return `None`, empty `Vec::new()`, or zero-value defaults to signal an error. A property test over known invalid inputs asserts all return `Err(...)`. Verified by `test_BC_2_14_006_no_silent_default()`.

### AC-013 (traces to BC-2.14.006 postcondition 3)
`TryFrom<T>` is used for fallible conversions (not `From<T>`). A compile-fail test confirms that implementing `From<EmptyContent>` for `HumanMessage` would produce a type error (because such a conversion must be fallible). Verified by `test_BC_2_14_006_try_from_required()`.

### AC-014 (traces to BC-2.14.006 invariant)
Validation error code is always `E-CORE-005` and message format is always `"Validation failed for '<field>': <reason>"`. A table-driven test exercises five different invalid inputs across three message types and asserts code and message format. Verified by `test_BC_2_14_006_error_code_and_format()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `cargo xtask check-no-panic` | `xtask/src/check_no_panic.rs` | effectful (subprocess, file scan) |
| `cargo xtask check-client-timeout` | `xtask/src/check_client_timeout.rs` | effectful (file scan) |
| `cargo xtask deny-bare-api-key` | `xtask/src/deny_bare_api_key.rs` | effectful (file scan) |
| `OpenAiApiKey`, `AnthropicApiKey` | `pregolya-core/src/credentials.rs` (`core::credentials`) | pure-core |
| `reqwest::ClientBuilder` helper | `pregolya-core/src/http.rs` | effectful (I/O) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/credentials.rs` | pure-core | Newtype structs with no I/O. `Debug` impl is a pure string transformation. |
| `pregolya-core/src/http.rs` | effectful | Builds `reqwest::Client` which opens TCP sockets; async I/O dependency. |
| `xtask/src/check_no_panic.rs` | effectful | File system scan using `grep`/`ripgrep` subprocess. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | `unwrap()` in `#[cfg(test)]` block | `check-no-panic` xtask does NOT flag it; exemption logic required |
| EC-002 | `debug_assert!()` in production code | Exempt per BC-2.14.003; xtask pattern excludes `debug_assert!` |
| EC-003 | API key is a zero-length string | Returns `Err(PregolyaError { category: VAL, code: "E-CORE-005" })` — not an empty newtype |
| EC-004 | `reqwest::Client::new()` in `#[cfg(test)]` | Exempt from `check-client-timeout` scan; test-only clients do not need production timeout |
| EC-005 | Validation field name contains special chars | Message escapes/sanitizes field name; no format injection |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,500 |
| BC-2.14.003.md through BC-2.14.006.md (4 files, ~150 lines each) | ~10,000 |
| `module-decomposition.md` (SS-14 section) | ~500 |
| `credentials.rs` + `http.rs` (to create, ~80 lines each) | ~2,000 |
| `xtask/src/` (3 new xtask modules, ~60 lines each) | ~2,000 |
| Test files (~120 lines) | ~1,800 |
| Tool outputs | ~500 |
| **Total** | **~20,300** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~10%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-014 (test-writer)
2. [ ] Verify Red Gate — all new tests fail or error at start
3. [ ] Create `pregolya-core/src/credentials.rs` — `OpenAiApiKey`, `AnthropicApiKey` newtypes with redacted Debug
4. [ ] Create `pregolya-core/src/http.rs` — `build_client()` with 30s timeout, no `Client::new()`
5. [ ] Add `pub mod credentials;` and `pub mod http;` to `pregolya-core/src/lib.rs`
6. [ ] Create `xtask/src/check_no_panic.rs` — grep scan for `unwrap()`/`expect()` outside test/exempt contexts
7. [ ] Create `xtask/src/check_client_timeout.rs` — grep scan for `Client::new()` and missing `.timeout()`
8. [ ] Create `xtask/src/deny_bare_api_key.rs` — grep scan for bare API key string patterns
9. [ ] Wire three new xtask subcommands into `xtask/src/main.rs`
10. [ ] Add static-assertions for credential type constraints
11. [ ] Run `cargo xtask check-no-panic && cargo xtask check-client-timeout && cargo xtask deny-bare-api-key` — all exit 0
12. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.01 established `PregolyaError` with `Component::Prov`, `Category::TIMEOUT`, and `Category::VAL`. S-1.02 uses these directly in error construction for AC-006, AC-011. The `code: "E-PROV-002"` and `code: "E-CORE-005"` values must be consistent with the error taxonomy authored in S-1.01 scope.

Pattern established in S-1.01: pure-core modules (`error.rs`, `credentials.rs`) have no tokio dependency; this pattern must continue in S-1.02.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `credentials.rs` must NOT implement `Deref<Target=str>` on any key newtype | BC-2.14.005 postcondition 3 | `static_assertions::assert_not_impl_any!(OpenAiApiKey: AsRef<str>)` |
| `debug_assert!` exempt from no-panic scan | BC-2.14.003 postcondition 3 | Xtask grep pattern; test by placing `debug_assert!(true)` in prod code |
| No `reqwest::Client::new()` in `http.rs` production path | BC-2.14.004 postcondition 1 | `cargo xtask check-client-timeout` |
| Xtask crate must NOT be in `workspace.members` as a publishable crate | Architecture convention | `Cargo.toml` `xtask` entry has `publish = false` |

**Forbidden dependencies for `pregolya-core/src/credentials.rs`:** `tokio`, `reqwest`, `serde` (no derive Serialize on key types). Only `std`.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `reqwest` | workspace pin | `default-features = false, features = ["rustls-tls"]` — HTTP client with rustls |
| `static_assertions` | workspace pin (dev) | Trait bound assertions for credential types |
| `tokio` | workspace pin (dev) | Async test runtime for timeout test |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/credentials.rs` | CREATE | `OpenAiApiKey`, `AnthropicApiKey` newtypes |
| `pregolya-core/src/http.rs` | CREATE | `build_client()` returning `reqwest::Client` with 30s timeout |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod credentials;`, `pub mod http;` |
| `xtask/src/check_no_panic.rs` | CREATE | CI xtask: no-unwrap/expect scan |
| `xtask/src/check_client_timeout.rs` | CREATE | CI xtask: reqwest timeout gate |
| `xtask/src/deny_bare_api_key.rs` | CREATE | CI xtask: bare API key string scan |
| `xtask/src/main.rs` | MODIFY | Wire three new xtask subcommands |
