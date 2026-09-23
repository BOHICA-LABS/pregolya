# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- **No-panic CI enforcement** (`cargo xtask check-no-panic`): AST-based scan of all `crates/` production source files that flags `unwrap()`, `expect()`, bare `assert!` / `assert_eq!` / `assert_ne!` / `assert_matches!` without `# Panics` doc and BC-ID message, `todo!` / `unimplemented!` (unconditionally flagged — no exemption applies; mark incomplete work), `panic!`, named-arm `unreachable!` where the match has an unguarded catch-all sibling, and wildcard `_ => unreachable!()` arms; exempts `debug_assert!`, exhaustive-match `unreachable!` in fully-named arms, and programmer-error guards with compliant doc+message pattern (BC-2.14.003).
- **HTTP client timeout CI enforcement** (`cargo xtask check-client-timeout`): source scan that flags `reqwest::ClientBuilder` chains missing `.timeout(duration > 0)` before `.build()` and any bare `reqwest::Client::new()` in non-test production code (BC-2.14.004).
- **Credential structural safety CI gate** (`cargo xtask deny-bare-api-key`): structural scanner that flags public structs with credential-sentinel names (`key`, `token`, `secret`, `credential`, `auth`, `bearer`, `password`, `passphrase`) that auto-derive `Debug` (without a manual redacted impl), derive `Serialize`, derive `Deserialize` (bypasses `new()` validation), implement `Display`, or implement `Deref<Target=str/String>` (BC-2.14.005).
- **Error-code registry CI enforcement** (`cargo xtask check-error-code-registry`): parses `.factory/specs/prd-supplements/error-taxonomy.md` and fails the build if any `E-<COMPONENT>-<NNN>` code appears more than once; exits 1 with a descriptive error if zero codes are extracted (vacuity guard — detects taxonomy format changes); taxonomy path resolved via `FACTORY_DIR` env var (set by CI factory-artifacts checkout step) or `.factory/` relative fallback when `FACTORY_DIR` is absent or empty (BC-2.14.001, VP-BC214001-01).
- **`OpenAiApiKey` and `AnthropicApiKey` credential newtypes** in `pregolya-core`: private-field newtypes with manually-implemented redacted `Debug` (emits exactly `"<redacted>"`); fallible construction via `new() -> Result<Self, PregolyaError>`; infallible `From<String>`/`From<&str>` conversions are structurally forbidden and pinned by `static_assertions::assert_not_impl_any!` (BC-2.14.006 EC-005); no `Serialize`, `Deserialize`, `Display`, `Deref`, or `AsRef<str>`; compile-time `static_assertions` enforce all exclusions (BC-2.14.005, BC-2.14.006).
- **`build_client()` HTTP client factory** in `pregolya-core`: `reqwest::ClientBuilder` wrapper enforcing 30-second total timeout with `rustls-tls` backend; maps `ClientBuilder::build()` failure to `PregolyaError { category: TRANSPORT, code: "E-CORE-012", retry_hint: Never }` (BC-2.14.004).
- **Validation error propagation** (`E-CORE-005`): `OpenAiApiKey::new("")` and `::new("   ")` return `Err(PregolyaError { category: VAL, code: "E-CORE-005", message: "Validation failed for 'api_key': value must not be empty or whitespace-only", retry_hint: Never })`; no silent `None` or default returns (BC-2.14.006).

### Fixed (fix-burst-17, 2026-09-22)

- **F-P15-M01** — Separated `panic!` from the Exemption-2 group in `pub fn run()` doc (`check_no_panic.rs`): `panic!`/`todo!`/`unimplemented!` are now documented as unconditionally flagged; the Exemption-2 qualifier "(without `# Panics` doc + BC-ID exemption)" now applies only to the assert-family; `assert_matches!` added to the assert-family list in the `run()` doc.
- **F-P15-M02** — Complete sweep of retired scanner internals in `tests.rs`: converted all 8 present-tense claims about former `FLAGGED_PANIC_MACROS` handler, `in_match_arm_position` check, and `Delimiter::Parenthesis` guard to past-tense provenance framing ("the former handler checked/used/saw…"); deleted the self-contradictory "current scanner only checks Delimiter::Parenthesis" fragment from the `test_BC_2_14_003_fixture_mode_in_process_violation_found` assertion message.
- **F-P15-M03** — Fixed mis-anchor in `test_BC_2_14_006_error_code_and_format_table` comment (`credentials.rs`): replaced wrong `{EC-005}` clause with `{EC-004}/{PC-004}` (empty-string input returns Err); narrowed claim from "empty string and whitespace-only" to "empty-string input only"; added cross-reference to whitespace-only test for `{EC-006}`.
- **F-P15-M04** — Added `BC-2.14.005 {INV-001} DI-010` citation alongside existing `{EC-006}` and `CWE-209` in `map_build_failure` and `sanitize_error_message` doc comments (`http.rs`); `{INV-001}` is the governing invariant for credential sanitization behavior.
- **F-P15-L01** — Added `assert_matches!` to the "## Exempt patterns" Exemption-2 bullet in the module doc (`check_no_panic.rs`); extended the module summary line to enumerate all flagged panic-family constructs including `todo!`, `unimplemented!`, and conditional `unreachable!()` patterns.
- **F-P15-L02** — Fixed `scan_for_anyhow_in_source` doc predicate citation in `main.rs`: changed "`is_test_file`" to "`is_lint_exempt_file`" to match the actual code path.

### Fixed (fix-burst-16, 2026-09-22)

- **F-P14-M07** — Split `"panic"` out of the Exemption-2 guard arm in `handle_macro_invocation` (`check_no_panic.rs`): `panic!()` is now unconditionally flagged via its own dedicated arm (no `fn_has_panics_doc && syn_macro_has_bc_id` guard); Exemption-2 guard now applies only to assert-family macros (`assert!`, `assert_eq!`, `assert_ne!`, `assert_matches!`). Updated `handle_macro_invocation` doc, `scan_for_panics_in_source` doc, and module-level "## Flagged patterns" doc to reflect the behavioral change.
- **F-P14-L01** — Added `todo!()`, `unimplemented!()`, and `assert_matches!` to the "## Flagged patterns" module doc in `check_no_panic.rs`; clarified `panic!()` as unconditionally flagged with no exemption.
- **F-P14-M01** — Changed present-tense scanner-behavior claims to past-tense provenance framing in two assertion messages in `tests.rs`: "checks…fires" → "checked…fired" in `test_BC_2_14_003_std_qualified_unreachable_in_named_arm_not_flagged`; "fires" → "fired" in `test_BC_2_14_003_core_qualified_unreachable_in_named_arm_not_flagged`.
- **F-P14-M02** — Extended `is_lint_exempt_file` "Used by:" list in `main.rs` to include `deny_bare_api_key` and `deny_description_cache_key`.
- **F-P14-M03** — Removed "or examples" / "/ examples" from three doc sites: `scan_for_anyhow_in_source` doc in `main.rs`, `scan_for_description_cache_key_in_source` doc in `main.rs`, and `test_description_cache_key_scanner_skips_test_files` doc in `tests.rs`.
- **F-P14-M04** — Replaced phantom `SEC-004` anchor with `BC-2.14.005 {PC-004}/{INV-003}` in `impl_body_has_target_str` doc (`deny_bare_api_key.rs`); replaced all `SEC-007` occurrences in `http.rs` with `BC-2.14.004 {EC-006}` (retaining `CWE-209`): `map_build_failure` doc, `sanitize_error_message` doc, test section header, and four test doc comments.
- **F-P14-M05** — Replaced "struct-literal" with "`from_raw_for_tests`" in three test doc comments in `credentials.rs`: `test_BC_2_14_005_openai_debug_emits_redacted_sentinel`, `test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel`, and `test_BC_2_14_005_debug_does_not_leak_key_material`.
- **F-P14-L02** — Removed `check-no-panic` from the timeout test parenthetical in `test_BC_2_14_004_timeout_error_shape` (`http.rs`); comment now reads "(check-client-timeout)" only.
- **F-P14-L03** — Replaced stale "Table: (constructor, input, must_be_err) / Only empty string is a guaranteed failure ... may be added by the implementer." comment in `test_BC_2_14_006_error_code_and_format_table` with accurate comment describing direct assertions over `OpenAiApiKey::new("")` / `AnthropicApiKey::new("")`.

### Fixed (fix-burst-15, 2026-09-22)

- **F-P13-M02** — Extended `test_check_post_exemption_vacuity_gate_names_are_distinct` to include `"check-file-size"` in the gates array (six gates, not five); updated doc comment accordingly.
- **F-P13-M02** — Extended `test_check_post_exemption_vacuity_wiring_present_in_all_scanners` to assert `check_post_exemption_vacuity("check-file-size"` is present in `main.rs`; updated doc comment to "six gates across four source files".
- **F-P13-M03** — Replaced permanently-green `let _ = findings;` in `test_timeout_scanner_split_statement_false_negative_known_limitation` with a load-bearing `assert!(findings.is_empty(), "KNOWN-LIMITATION 2: …")` so the test will fail if cross-statement tracking is ever implemented.
- **F-P13-M04** — Removed stale reference to `assert!` in `check_file_size` from `check_no_panic::run()` scan-root comment; replaced with accurate statement that xtask production code contains no panic-family constructs and surfaces failures via stderr + non-zero exit.
- **F-P13-OBS01** — Added cross-reference paragraphs to `is_test_file` and `is_test_class_file` doc comments in `main.rs` making the intentional predicate duplication explicit and documenting the expected divergence rationale.

### Fixed (fix-burst-14, 2026-09-22)

- **F-P12-M01** — Removed duplicate test `test_bc_2_14_003_panic_family_detected_in_token_stream` from `xtask/src/check_no_panic.rs`; it was byte-identical to `test_bc_2_14_003_panic_in_macro_arg_detected_by_panic_family`.
- **F-P12-M02** — Rewrote `scan_method_calls_in_tokens` doc comment to accurately describe both call paths (primary syn path via `handle_macro_invocation`, and syn parse-failure fallback) and state that exemption logic is not applied on either path.
- **F-P12-M03** — Fixed test doc in `test_bc_2_14_003_panic_in_macro_arg_detected_by_panic_family`: replaced incorrect label "KNOWN-LIMITATION 4" with the correct label "Residual detection gap" for the token-pasting gap paragraph.
- **F-P12-M04** — Fixed three dangling anchors in `crates/pregolya-core/src/http.rs` doc comments: replaced phantom `make_build_error_for_test` coupling description with the actual compile-time coupling mechanism; replaced adversary finding ID `F-C` with BC clause `{EC-006}`; replaced non-existent `POL-34` with `SID-1`.
- **F-P12-M05** — Fixed incorrect `AC-010` references in `crates/pregolya-core/src/credentials.rs`: `test_BC_2_14_005_openai_expose_secret_returns_inner_value` and `test_BC_2_14_005_anthropic_expose_secret_returns_inner_value` trace to `AC-009` (the only-intentional-exposure-path AC), not `AC-010` (the structural gate AC).
- **F-P12-M06** — Fixed `{INV-004}` → `{INV-001}` in `test_BC_2_14_004_timeout_error_shape` doc: INV-001 is the outbound connection timeout invariant that DI-009 covers; INV-004 was wrong.
- **F-P12-L01** — Fixed `xtask/tests/fixtures/violations/violation_todo_stub.rs`: corrected header comment to say "detects `todo!()`" only (removed false claim of `unimplemented!()` coverage); renamed `unimplemented_function` to `todo_stub_function` to remove the false implication.
- **F-P12-L03** — Fixed self-contradicting Pattern-2 inline comment in `xtask/src/check_client_timeout.rs`: removed the false claim that Pattern 2 "only detects inline-qualified calls"; replaced with accurate description that bare unqualified `Client::new()` calls are flagged conservatively per KNOWN-LIMITATION 1.
- **F-P12-L05** — Replaced `assert!` panic in `check_file_size()` (`xtask/src/main.rs`) with `check_post_exemption_vacuity` structured error path; vacuity condition now produces stderr message + exit code 1 (not exit code 101 from panic).

### Fixed (fix-burst-18, 2026-09-22)
- F-P16-MED-001: `syn_macro_has_bc_id` made arity-aware — `assert_eq!`/`assert_ne!`/`assert_matches!` now require BC-ID in message (3rd argument), not comparand; new violation fixture and test added
- F-P16-MED-002: `has_build_without_timeout` brace-depth tracking via `BraceGroupEnd` variant prevents brace-group arguments from terminating the scan before `.build()` is reached
- F-P16-MED-005: `test_BC_2_14_003_programmer_error_guards_compliant` assertion message corrected — `panic!()` removed as an acceptable guard form (it is unconditionally flagged with no Exemption-2 path)
- F-P16-LOW-006: `check_impl_deref` and `check_impl_display_in_tokens` post-`for` ident-collection loops stop at `where` clause boundary; two regression tests added

### Fixed (fix-burst-19, 2026-09-22)
- F-P17-MED-001/MED-002: evidence-report.md AC-017 counts updated to 14/17, 14th violation class added, validity criterion extended with fixture-directory clause (c)
- F-P17-MED-003: BracketGroup/BracketGroupEnd depth tracking in has_build_without_timeout — vec![..;n] repeat `;` no longer terminates chain scan
- F-P17-MED-004: Leading `::` skip before post-`for` ident collection in check_impl_deref and check_impl_display_in_tokens
- F-P17-LOW-005: Exempt-direction tests for assert_eq!/assert_ne!/assert_matches! 3-arg form with BC-ID in message
- F-P17-LOW-006: CREDENTIAL_FIXTURE_COUNT doc comment ratio updated to 14/17
- F-P17-OBS-007: KNOWN-LIMITATION added to syn_macro_has_bc_id for turbofish comma counting
