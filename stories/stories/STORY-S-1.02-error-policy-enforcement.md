---
document_type: story
level: ops
story_id: S-1.02
epic_id: E-01
version: "1.13"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors."
  - "1.2 (round-79/F-P2A251-02 verify-pass (byte-exact H1 escaping)/2026-09-02): BC-2.14.005 table title cell corrected from escaped Deref\\<Target=str\\> to unescaped Deref<Target=str> to byte-match canonical H1."
  - "1.3 (POL-8 bc_array_changes_propagate_to_body_and_acs/2026-09-22): AC-015 added tracing BC-2.14.004 EC-006 (HttpClientBuildFailed, E-CORE-012, Category TRANSPORT, RetryHint Never); AC-016 added tracing BC-2.14.006 EC-006 (whitespace-only credential rejection, E-CORE-005, Category VAL, RetryHint Never). bcs frontmatter array unchanged (4 BCs)."
  - "1.4 (POL-8 pass-2-adjudication/2026-09-22): AC-017 added tracing BC-2.14.003 EC-007 (check-no-panic FLAGS bare assert! without # Panics doc or BC-ID message and FLAGS wildcard unreachable!; EXEMPTS exhaustive-match unreachable! and documented programmer-error-guard assert!; two POL-31 live-violation fixtures); AC-018 added tracing BC-2.14.003 EC-006 (PregolyaError::new/to_problem/component_lowercase programmer-error guards compliant under narrow EC-006 exception — assert! with # Panics doc + BC-ID message, no unreachable!); AC-019 added tracing BC-2.14.004 EC-006 (E-CORE-012 build-failure test is non-ignored and exercises same production mapping path as build_client(), no duplicated test-only helper). bcs frontmatter array unchanged (4 BCs)."
  - "1.5 (pass-4/F-04-F-05-F-06/2026-09-22): F-04 (HIGH) — Verified-by test symbol pointers corrected to match actual implemented test names: AC-003 now cites test_BC_2_14_003_debug_assert_not_flagged; AC-007 now cites static_assertions::assert_not_impl_any! mechanism (no dedicated test exists); AC-008 now cites test_BC_2_14_005_openai_debug_emits_redacted_sentinel and test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel; AC-010 verified-by extended to cite unit tests; AC-011 now cites test_BC_2_14_006_openai_empty_key_returns_err; AC-012 now cites test_BC_2_14_006_no_silent_default_on_invalid_inputs; AC-013 now cites static_assertions::assert_not_impl_any!(OpenAiApiKey: From<String>) mechanism; AC-014 now cites test_BC_2_14_006_error_code_and_format_table; AC-015+019 now cite test_BC_2_14_004_build_failure_maps_to_e_core_012; AC-016 now cites test_BC_2_14_006_openai_whitespace_only_key_returns_err. F-05 (MED) — AC-010 body prose corrected from literal-prefix scanning to structural detection (sentinel-named public structs auto-deriving Debug/Serialize or implementing Deref<Target=str>). F-06 (MED) — AC-006 rescoped: S-1.02 verifies only DI-009 timeout-is-configured compliance; E-PROV-002 adapter-level error shape deferred to S-2.07 (BC-2.14.004 PC-005); mock-server-never-responds claim removed from S-1.02. bcs frontmatter array unchanged (4 BCs)."
  - "1.6 (pass-8/F-03-records/2026-09-22): AC-017 prose corrected for spec-body accuracy drift (F-03 LOW): reworded to state the two POL-31-mandated fixtures (bare assert! without # Panics doc or BC-ID message, and _ => unreachable!() wildcard arm, per BC-2.14.003 EC-007) are REQUIRED minimums that must be detected; additional regression fixtures may reside alongside them under xtask/tests/fixtures/violations/ without prescribing an exact count. Verified-by test symbol (test_BC_2_14_003_check_no_panic_ec_007_flags_and_exemptions) unchanged. No other AC, BC-body table, or frontmatter field changed."
  - "1.7 (pass-15/F-01-F-02-sweep/2026-09-22): F-01 (MED) — AC-014 body corrected: removed false claim of 'five different invalid inputs across three message types'; actual test exercises empty-string input across OpenAiApiKey and AnthropicApiKey (two credential newtypes), asserting code E-CORE-005, Category::Val, and canonical message prefix 'Validation failed for'. F-02 (LOW) — AC-012 body corrected: 'property test' reworded to 'table-driven test' (fixed input array, not randomized). Full sweep additional corrections: AC-001 body corrected from 'compile-fail test' to 'unit test' with accurate description of Ok/Err paths; AC-011 body corrected example from Message::human('') with S-1.03-scope 'content' field (out of S-1.02 scope) to OpenAiApiKey::new('') with actual error message. bcs frontmatter array unchanged (4 BCs)."
  - "1.8 (adversary-pass-1-MED-7/2026-09-22): AC-006 #[ignore] reason corrected — removed false citation of non-existent timeout-validation CI job; deferral now cites S-2.07 per BC-2.14.004 {PC-005}."
  - "1.9 (adversary-pass-3-H02/2026-09-22): Added BC-2.14.001 + VP-BC214001-01 to deliver the error-code-registry CI gate anchored here from STORY-S-1.01. Gate implemented: cargo xtask check-error-code-registry."
  - "1.10 (adversary-pass-4-H01-M07/2026-09-22): H01 — Added BC-2.14.001 row to body §Behavioral Contracts table; authored AC-020 tracing BC-2.14.001 EC-007 / VP-BC214001-01 for check-error-code-registry gate. M07 — Swept xtask/src/check_error_code_registry.rs into §Architecture Mapping, §Purity Classification, §File Structure Requirements; corrected Task 9 count from three to four subcommands; extended Task 14 CHANGELOG topics to include registry gate."
  - "1.11 (adversary-pass-5-M01-M03/2026-09-22): M01 — AC-010 updated to reflect full deny-bare-api-key implementation: 5 patterns (derive(Debug), derive(Serialize), derive(Deserialize), impl Display, impl Deref<Target=str|String>) and 8 sentinel keywords (key, token, secret, credential, auth, bearer, password, passphrase); added missing Verified-by test symbols test_BC_2_14_005_impl_display_flagged, test_BC_2_14_005_derive_deserialize_flagged, test_BC_2_14_005_pub_crate_debug_derive_fixture_detected; Task 8 prose expanded to match. M03 — AC-020 Verified-by corrected from non-load-bearing test_error_code_registry_zero_codes_is_error to load-bearing test_registry_verdict_zero_codes_returns_err (calls registry_verdict(&HashMap::new()) and asserts Err) plus test_registry_verdict_collision_returns_err (load-bearing collision guard)."
  - "1.12 (adversary-pass-7-M05-L01-L02/2026-09-22): M05 — File Structure Requirements: deny_bare_api_key.rs Purpose cell corrected from 'bare API key string scan' to 'structural credential-struct safety scan (8 sentinels × 5 patterns; no string-literal matching)' (AC-010 explicitly states the gate does not scan string literals). L01 — Task 1 range extended from AC-019 to AC-020 (AC-020 was added in v1.10 but Task 1 was not swept). L02 — Architecture Compliance Rules: Enforcement cell for credentials.rs Deref prohibition corrected from assert_not_impl_any!(OpenAiApiKey: AsRef<str>) to assert_not_impl_any!(OpenAiApiKey: std::ops::Deref) and assert_not_impl_any!(AnthropicApiKey: std::ops::Deref) (both newtypes; matches actual static_assertions enforcement)."
  - "1.13 (adversary-pass-9-L03/2026-09-22): L03 — §Purity Classification: added missing rows for check_client_timeout.rs and deny_bare_api_key.rs (both effectful/file-scan; were in §Architecture Mapping but absent from §Purity Classification)."
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.003.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.004.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.005.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "595f384"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.01]
blocks: [S-1.04, S-1.06, S-1.09, S-1.10, S-1.12, S-2.01, S-2.04, S-2.09]
behavioral_contracts:
  - id: BC-2.14.001
  - id: BC-2.14.003
  - id: BC-2.14.004
  - id: BC-2.14.005
  - id: BC-2.14.006
verification_properties:
  - id: VP-BC214001-01
    status: delivered
    gate: cargo xtask check-error-code-registry
    notes: "Wired in ci.yml lint-extra via factory-artifacts checkout; taxonomy path resolved via FACTORY_DIR env var or .factory/ fallback"
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

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.14.001 | Error-code registry uniqueness gate (VP-BC214001-01) | AC-020 |
| BC-2.14.003 | All Library Constructors Return Result; No .unwrap()/.expect()/assert! in Non-Test Code | AC-001..AC-003, AC-017, AC-018 |
| BC-2.14.004 | Every Outbound HTTP ClientBuilder Must Set .timeout(30s); Zero Client::new() Outside Tests | AC-004..AC-006, AC-015, AC-019 |
| BC-2.14.005 | API Key Newtype with Redacted Debug; No Serialize; No Deref<Target=str> | AC-007..AC-010 |
| BC-2.14.006 | Validation Failures Propagate Err(PregolyaError); No Silent None | AC-011..AC-014, AC-016 |

## Acceptance Criteria

### AC-001 (traces to BC-2.14.003 PC-001)
Every fallible public constructor in `pregolya-core` returns `Result<T, PregolyaError>` rather than panicking. A unit test verifies that `OpenAiApiKey::new` returns `Ok(OpenAiApiKey)` for valid non-empty key input and `Err(PregolyaError)` for empty key input — neither path panics. Verified by `test_BC_2_14_003_constructor_returns_result()`.

### AC-002 (traces to BC-2.14.003 PC-004)
`cargo xtask check-no-panic` exits 0 on the initial `pregolya-core/src/` tree (no `unwrap()` or `expect()` in non-test code paths). The xtask itself is created as part of this story. Verified by the xtask executing successfully in CI.

### AC-003 (traces to BC-2.14.003 INV-003 and INV-004)
`debug_assert!()`, `unreachable!()` in exhaustive match arms, and test files are exempt from the no-panic xtask scan. The xtask grep pattern excludes `#[cfg(test)]` blocks and the three documented exemptions. Verified by `test_BC_2_14_003_debug_assert_not_flagged()` which places a `debug_assert!` in a non-test context and confirms the xtask still exits 0.

### AC-004 (traces to BC-2.14.004 PC-001 and PC-003)
A `reqwest::ClientBuilder`-based helper in `pregolya-core` (utility for provider crates) calls `.timeout(Duration::from_secs(30))` by default. `reqwest::Client::new()` is NOT used in any production path in `pregolya-core`. Verified by `test_BC_2_14_004_default_timeout_applied()`.

### AC-005 (traces to BC-2.14.004 PC-003)
`cargo xtask check-client-timeout` scans `crates/` for `reqwest::Client::new()` and `ClientBuilder` patterns missing `.timeout(...)`, and exits non-zero if any are found. The xtask is created as part of this story. Verified by the xtask executing successfully in CI.

### AC-006 (traces to BC-2.14.004 PC-005)
The `reqwest::Client` produced by `build_client()` has a positive total `.timeout()` configured (DI-009 compliance). This story verifies the timeout is correctly set at construction time and that `build_client()` succeeds. The full E-PROV-002 error code and message shape produced by the provider adapter when the timeout fires at the HTTP boundary is verified in S-2.07 (BC-2.14.004 {PC-005}). Verified by `test_BC_2_14_004_timeout_error_shape()` (confirms `build_client()` succeeds and documents the expected error shape contract; the live timeout-fires-against-mock-server scenario is an `#[ignore]`'d integration test deferred to S-2.07 per BC-2.14.004 {PC-005}).

### AC-007 (traces to BC-2.14.005 PC-001 and PC-004)
`OpenAiApiKey`, `AnthropicApiKey`, and any other API key types in `pregolya-core` are newtypes (`pub struct FooApiKey(String)`), NOT type aliases. `derive(Clone)` is allowed for config snapshots but `Deref<Target=str>` and `std::ops::Deref` are NOT allowed. Verified by `static_assertions::assert_not_impl_any!(OpenAiApiKey: std::ops::Deref)` and `static_assertions::assert_not_impl_any!(AnthropicApiKey: std::ops::Deref)` — compile-time enforcement; no dedicated runtime test exists for newtype-vs-alias distinction since this is a structural property enforced at compile time.

### AC-008 (traces to BC-2.14.005 PC-002)
`format!("{:?}", OpenAiApiKey("sk-real".to_string()))` returns exactly `"<redacted>"` — no substring of the key value. `format!("{:?}", AnthropicApiKey("sk-ant-real".to_string()))` returns exactly `"<redacted>"`. Verified by `test_BC_2_14_005_openai_debug_emits_redacted_sentinel()` and `test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel()`.

### AC-009 (traces to BC-2.14.005 PC-003 and PC-004)
No `#[derive(Serialize)]` on API key newtypes (they must not appear in API responses). No `impl Deref<Target=str>` or `impl AsRef<str>` that exposes the inner value (the `.as_str()` or `.expose_secret()` method is the only intentional exposure path). Verified by compile-fail test or `static_assertions::assert_not_impl_any!(OpenAiApiKey: AsRef<str>)`.

### AC-010 (traces to BC-2.14.005 PC-006)
`cargo xtask deny-bare-api-key` performs STRUCTURAL detection: it scans `crates/` for public structs whose names contain a credential sentinel (`key`, `token`, `secret`, `credential`, `auth`, `bearer`, `password`, `passphrase` — case-insensitive, 8 sentinels) and flags any that (1) `#[derive(Debug)]` without a manual `impl Debug` (auto-derived Debug would emit the raw inner value), (2) `#[derive(Serialize)]` (credentials must not appear in serialized artifacts per PC-003), (3) `#[derive(Deserialize)]` (credentials must not be reconstructed from untrusted data), (4) `impl Display for NAME` (Display exposes the inner value via `{}` formatting), or (5) `impl Deref for NAME { type Target = str; }` or `impl Deref for NAME { type Target = String; }` (Deref coercion silently exposes the inner value). The gate does NOT scan for string literals matching key prefixes such as `sk-` or `sk-ant-`. Files under `tests/` directories and `#[cfg(test)]` blocks are exempt. Exits non-zero when any structural violation is found; exits 0 on a clean scan. Verified by `test_BC_2_14_005_flags_derive_debug_on_token_struct()`, `test_BC_2_14_005_flags_serialize_on_secret_struct()`, `test_BC_2_14_005_flags_deref_str_on_credential_struct()`, `test_BC_2_14_005_compliant_credential_struct_not_flagged()`, `test_BC_2_14_005_deny_bare_api_key_subprocess_exits_nonzero_on_violation()`, `test_BC_2_14_005_impl_display_flagged()`, `test_BC_2_14_005_derive_deserialize_flagged()`, and `test_BC_2_14_005_pub_crate_debug_derive_fixture_detected()`.

### AC-011 (traces to BC-2.14.006 PC-001)
A validation failure on a credential constructor — e.g., `OpenAiApiKey::new("")` with an empty key string — returns `Err(PregolyaError { category: VAL, retry_hint: Never, code: "E-CORE-005", message: "Validation failed for 'api_key': value must not be empty or whitespace-only", .. })`. Verified by `test_BC_2_14_006_openai_empty_key_returns_err()`.

### AC-012 (traces to BC-2.14.006 PC-003)
Validation failures NEVER return `None`, empty `Vec::new()`, or zero-value defaults to signal an error. A table-driven test over known invalid inputs asserts all return `Err(...)`. Verified by `test_BC_2_14_006_no_silent_default_on_invalid_inputs()`.

### AC-013 (traces to BC-2.14.006 EC-005)
`TryFrom<T>` is used for fallible conversions (not `From<T>`). `From<String>` and `From<&str>` are NOT implemented on API key newtypes — such a conversion cannot fail cleanly, so it is structurally forbidden. Verified by `static_assertions::assert_not_impl_any!(OpenAiApiKey: From<String>)`, `static_assertions::assert_not_impl_any!(OpenAiApiKey: From<&'static str>)`, `static_assertions::assert_not_impl_any!(AnthropicApiKey: From<String>)`, and `static_assertions::assert_not_impl_any!(AnthropicApiKey: From<&'static str>)` — compile-time enforcement; these are structural constraints with no dedicated runtime test function.

### AC-014 (traces to BC-2.14.006 PC-004)
Validation error code is always `E-CORE-005` and message format is always `"Validation failed for '<field>': <reason>"`. A table-driven test exercises the empty-string input across both credential newtypes (`OpenAiApiKey` and `AnthropicApiKey`), asserting code `E-CORE-005`, `Category::Val`, and the canonical message prefix `"Validation failed for"` for each. Verified by `test_BC_2_14_006_error_code_and_format_table()`.

### AC-015 (traces to BC-2.14.004 EC-006)
When `reqwest::ClientBuilder::build()` fails (e.g., due to an invalid TLS configuration or unsupported feature), `build_client()` returns `Err(PregolyaError { category: TRANSPORT, retry_hint: Never, code: "E-CORE-012", .. })`. The error message communicates that the HTTP client could not be constructed. Verified by `test_BC_2_14_004_build_failure_maps_to_e_core_012()`.

### AC-016 (traces to BC-2.14.006 EC-006)
`OpenAiApiKey::new("   ")` and `AnthropicApiKey::new("   ")` (whitespace-only strings) return `Err(PregolyaError { category: VAL, retry_hint: Never, code: "E-CORE-005", message: "value must not be empty or whitespace-only", .. })` — identical rejection semantics to an empty string. Whitespace-only values are never accepted as valid credentials. Verified by `test_BC_2_14_006_openai_whitespace_only_key_returns_err()`.

### AC-017 (traces to BC-2.14.003 EC-007)
`cargo xtask check-no-panic` enforces the programmer-error-guard gate per BC-2.14.003 EC-007: it FLAGS any `assert!` or `assert_eq!` call whose enclosing function doc comment lacks a `# Panics` section, and FLAGS any `_ => unreachable!(...)` wildcard match arm. It EXEMPTS a `unreachable!()` that appears only in fully-enumerated exhaustive match arms (every variant explicitly named; no wildcard `_` arm present in the same match expression), and EXEMPTS an `assert!` whose enclosing function has a `# Panics` doc section and whose assert message string contains a BC-ID matching the pattern `BC-\d+\.\d{2}\.\d{3}`. The two POL-31-mandated live-violation fixtures MUST reside under `xtask/tests/fixtures/violations/`: one containing a bare `assert!` (no `# Panics` doc or BC-ID message) and one containing `_ => unreachable!()` — both are required to be detected and reported when `cargo xtask check-no-panic --fixture-mode` is invoked. Additional regression fixtures for the same gate may reside alongside these two mandated fixtures; the exact count of fixtures in that directory is not prescribed. Verified by `test_BC_2_14_003_check_no_panic_ec_007_flags_and_exemptions()`.

### AC-018 (traces to BC-2.14.003 EC-006)
The programmer-error-guard asserts in `PregolyaError::new`, `PregolyaError::to_problem`, and `component_lowercase` satisfy the EC-006 narrow exception and are NOT flagged by `check-no-panic`: each enclosing function carries a `# Panics` doc section, and each assert message string contains a BC-ID (BC-2.14.001 and/or BC-2.14.003). These functions do NOT use `unreachable!()` macros in place of programmer-error guards, and contain NO bare asserts. Consequently, `cargo xtask check-no-panic` exits 0 on the completed `pregolya-core` crate tree despite these always-on programmer-error-guard asserts. Verified by `test_BC_2_14_003_programmer_error_guards_compliant()`.

### AC-019 (traces to BC-2.14.004 EC-006)
The test verifying the `E-CORE-012` build-failure mapping (AC-015) is NOT annotated `#[ignore]` and invokes the identical production error-mapping code path exercised by `build_client()` at runtime — no separate test-only mapping helper is introduced. The test must break if the production mapping path changes without a corresponding test update. Verified by `test_BC_2_14_004_build_failure_maps_to_e_core_012()` (same test name as AC-015; this AC adds non-ignore and production-path constraints to AC-015's verifiable scope).

### AC-020 (traces to BC-2.14.001 EC-007 / VP-BC214001-01)
`cargo xtask check-error-code-registry` exits 0 when every `E-<COMPONENT>-<NNN>` code in `error-taxonomy.md` is unique and at least one code was extracted (non-zero validated count), and exits 1 when any code appears more than once or when zero codes are extracted (vacuity guard — taxonomy format change detection). Verified by `test_registry_verdict_zero_codes_returns_err()` (load-bearing vacuity guard — calls `registry_verdict(&HashMap::new())` and asserts `Err`) + `test_registry_verdict_collision_returns_err()` (load-bearing collision guard) and the CI lint-extra gate wired in `.github/workflows/ci.yml` with factory-artifacts checkout.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `cargo xtask check-no-panic` | `xtask/src/check_no_panic.rs` | effectful (subprocess, file scan) |
| `cargo xtask check-client-timeout` | `xtask/src/check_client_timeout.rs` | effectful (file scan) |
| `cargo xtask deny-bare-api-key` | `xtask/src/deny_bare_api_key.rs` | effectful (file scan) |
| `OpenAiApiKey`, `AnthropicApiKey` | `pregolya-core/src/credentials.rs` (`core::credentials`) | pure-core |
| `reqwest::ClientBuilder` helper | `pregolya-core/src/http.rs` | effectful (I/O) |
| `cargo xtask check-error-code-registry` | `xtask/src/check_error_code_registry.rs` | effectful (file scan) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/credentials.rs` | pure-core | Newtype structs with no I/O. `Debug` impl is a pure string transformation. |
| `pregolya-core/src/http.rs` | effectful | Builds `reqwest::Client` which opens TCP sockets; async I/O dependency. |
| `xtask/src/check_no_panic.rs` | effectful | File system scan using `grep`/`ripgrep` subprocess. |
| `xtask/src/check_client_timeout.rs` | effectful | token-stream scan over crates/**/*.rs via find subprocess |
| `xtask/src/deny_bare_api_key.rs` | effectful | token-stream scan over crates/**/*.rs via find subprocess |
| `xtask/src/check_error_code_registry.rs` | effectful | Reads `.factory/specs/prd-supplements/error-taxonomy.md` from disk; filesystem I/O dependency. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | `unwrap()` in `#[cfg(test)]` block | `check-no-panic` xtask does NOT flag it; exemption logic required |
| EC-002 | `debug_assert!()` in production code | Exempt per BC-2.14.003; xtask pattern excludes `debug_assert!` |
| EC-003 | API key is a zero-length string | Returns `Err(PregolyaError { category: VAL, code: "E-CORE-005" })` — not an empty newtype |
| EC-004 | `reqwest::Client::new()` in `#[cfg(test)]` | Exempt from `check-client-timeout` scan; test-only clients do not need production timeout |
| EC-005 | Validation field name contains special chars | Message escapes/sanitizes field name; no format injection |
| EC-006a | `ClientBuilder::build()` fails (BC-2.14.004) | Returns `Err(PregolyaError { category: TRANSPORT, code: "E-CORE-012", retry_hint: Never })`; build failure never panics |
| EC-006b | Whitespace-only credential string, e.g. `"   "` (BC-2.14.006) | Rejected with same `Err(PregolyaError { category: VAL, code: "E-CORE-005", message: "value must not be empty or whitespace-only" })` as empty string |
| EC-007 | Bare `assert!` in production function without `# Panics` doc section | `check-no-panic` FLAGS it; bare assert does not satisfy the EC-007 narrow exception |
| EC-008 | `_ => unreachable!(...)` wildcard arm in a match expression | `check-no-panic` FLAGS it; wildcard-arm `unreachable!` is never exempt regardless of context |
| EC-009 | Programmer-error-guard `assert!` with `# Panics` doc + BC-ID in assert message, on a function whose precondition is not runtime-data-derived | `check-no-panic` EXEMPTS it; exits 0 for this pattern per BC-2.14.003 EC-007 narrow exception |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~4,200 |
| BC-2.14.003.md through BC-2.14.006.md (4 files, ~150 lines each) | ~10,000 |
| `module-decomposition.md` (SS-14 section) | ~500 |
| `credentials.rs` + `http.rs` (to create, ~80 lines each) | ~2,000 |
| `xtask/src/` (3 new xtask modules, ~60 lines each) | ~2,000 |
| Test files (~120 lines) | ~1,800 |
| Tool outputs | ~500 |
| **Total** | **~21,000** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~11%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-020 (test-writer)
2. [ ] Verify Red Gate — all new tests fail or error at start
3. [ ] Create `pregolya-core/src/credentials.rs` — `OpenAiApiKey`, `AnthropicApiKey` newtypes with redacted Debug
4. [ ] Create `pregolya-core/src/http.rs` — `build_client()` with 30s timeout, no `Client::new()`
5. [ ] Add `pub mod credentials;` and `pub mod http;` to `pregolya-core/src/lib.rs`
6. [ ] Create `xtask/src/check_no_panic.rs` — grep scan for `unwrap()`/`expect()` outside test/exempt contexts
7. [ ] Create `xtask/src/check_client_timeout.rs` — grep scan for `Client::new()` and missing `.timeout()`
8. [ ] Create `xtask/src/deny_bare_api_key.rs` — structural scan: flags public credential-sentinel structs (name contains any of 8 sentinels: key/token/secret/credential/auth/bearer/password/passphrase, case-insensitive) with any of 5 patterns: auto-derived Debug, Serialize, or Deserialize; or impl Display; or impl Deref<Target=str|String>
9. [ ] Wire four new xtask subcommands into `xtask/src/main.rs`
10. [ ] Add static-assertions for credential type constraints
11. [ ] Run `cargo xtask check-no-panic && cargo xtask check-client-timeout && cargo xtask deny-bare-api-key` — all exit 0
12. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass
13. [ ] Add two POL-31 live-violation fixtures under `xtask/tests/fixtures/violations/` (bare `assert!` without `# Panics` doc; `_ => unreachable!()` wildcard arm) and confirm `cargo xtask check-no-panic --fixture-mode` detects both
14. [ ] Add CHANGELOG entry under [Unreleased] > Added describing shipped no-panic enforcement, HTTP timeout policy, credential newtype redaction, validation propagation behavior, and error-code-registry uniqueness gate before creating the PR
15. [ ] Implement `cargo xtask check-error-code-registry` gate (VP-BC214001-01): parses error-taxonomy.md, asserts code uniqueness, wired to CI lint-extra

## Previous Story Intelligence (MANDATORY)

S-1.01 established `PregolyaError` with `Component::Prov`, `Category::TIMEOUT`, and `Category::VAL`. S-1.02 uses these in error construction for AC-011 (`E-CORE-005`) and documents the `E-PROV-002` shape that provider adapters must produce (verified in S-2.07, not in S-1.02's pregolya-core layer). The `code: "E-CORE-005"` value must be consistent with the error taxonomy authored in S-1.01 scope. The `code: "E-PROV-002"` shape is documented in AC-006 as the adapter-level contract; S-1.02's `build_client()` only configures the timeout — the error code is produced by S-2.07's provider adapters.

Pattern established in S-1.01: pure-core modules (`error.rs`, `credentials.rs`) have no tokio dependency; this pattern must continue in S-1.02.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `credentials.rs` must NOT implement `Deref<Target=str>` on any key newtype | BC-2.14.005 PC-004 | `static_assertions::assert_not_impl_any!(OpenAiApiKey: std::ops::Deref)` and `static_assertions::assert_not_impl_any!(AnthropicApiKey: std::ops::Deref)` (both newtypes) |
| `debug_assert!` exempt from no-panic scan | BC-2.14.003 INV-003 | Xtask grep pattern; test by placing `debug_assert!(true)` in prod code |
| No `reqwest::Client::new()` in `http.rs` production path | BC-2.14.004 PC-003 | `cargo xtask check-client-timeout` |
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
| `xtask/src/deny_bare_api_key.rs` | CREATE | CI xtask: structural credential-struct safety scan (8 sentinels × 5 patterns; no string-literal matching) |
| `xtask/src/check_error_code_registry.rs` | CREATE | CI xtask: error-code-registry uniqueness gate (BC-2.14.001, VP-BC214001-01) |
| `xtask/src/main.rs` | MODIFY | Wire four new xtask subcommands |
