---
document_type: demo-evidence-report
product: "pregolya-core (S-1.02)"
pipeline_run: "2026-09-22"
story_id: S-1.02
demo_type: "library"
recording_tool: "vhs"
status: complete
---

# Demo Evidence Report — S-1.02: Error Policy Enforcement

## Product: pregolya-core (S-1.02 — No-Panic, HTTP Timeout, Credential Newtypes, Validation Propagation)
## Pipeline Run: 2026-09-22
## Demo Type: library (CLI xtask gates + Rust nextest unit tests)

---

## Per-AC Demo Recordings

| AC | BC | Description | Recording (webm) | Recording (gif) | Tape | Status |
|----|----|-------------|------------------|-----------------|------|--------|
| AC-001 | BC-2.14.003 PC-001 | constructor returns Result | same recording as AC-008 | — | — | recorded |
| AC-002 | BC-2.14.003 PC-004 | `cargo xtask check-no-panic` exits 0 — no unwrap/expect/panic in non-test code | [AC-002-check-no-panic-pass.webm](AC-002-check-no-panic-pass.webm) | [AC-002-check-no-panic-pass.gif](AC-002-check-no-panic-pass.gif) | [tape](AC-002-check-no-panic-pass.tape) | recorded (refreshed 2026-09-22) |
| AC-003 | BC-2.14.003 INV-003/INV-004 | `debug_assert!` and exhaustive-match `unreachable!` are exempt — gate exits 0 | `test_BC_2_14_003_debug_assert_not_flagged` in `xtask::tests` — places synthetic `debug_assert!` in non-test scope; asserts gate returns Ok with 0 violations; discriminating (would fail if exemption was removed). Gate PASS is not itself load-bearing for the exemption since production tree contains zero `debug_assert!`/`unreachable!` sites. | — | — | covered |
| AC-004 | BC-2.14.004 PC-002/PC-003 | `build_client` 30s timeout — `HTTP_CLIENT_TIMEOUT_SECS` = 30 in reqwest `Client` `Debug` output | `test_BC_2_14_004_default_timeout_applied` in `crates/pregolya-core/src/http.rs` — asserts `HTTP_CLIENT_TIMEOUT_SECS` value `30` appears in reqwest `Client` `Debug` output; discriminating (catches 1s regression) | — | — | covered |
| AC-005 | BC-2.14.004 PC-003 | `cargo xtask check-client-timeout` exits 0 — no missing `.timeout()` | [AC-005-check-client-timeout-pass.webm](AC-005-check-client-timeout-pass.webm) | [AC-005-check-client-timeout-pass.gif](AC-005-check-client-timeout-pass.gif) | [tape](AC-005-check-client-timeout-pass.tape) | recorded (refreshed 2026-09-22) |
| AC-006 | BC-2.14.004 PC-005 | timeout configured at construction; `build_client()` succeeds (DI-009 scope) | `test_BC_2_14_004_build_client_returns_ok` in `crates/pregolya-core/src/http.rs` (non-`#[ignore]`; verifies Ok-return; SID-1 substitute for PC-002: `test_BC_2_14_004_default_timeout_applied`) | — | — | covered |
| AC-007 | BC-2.14.005 PC-001 | constructor returns Ok for valid key | `test_BC_2_14_005_openai_new_valid_key_returns_ok` and `test_BC_2_14_005_anthropic_new_valid_key_returns_ok` in `credentials.rs` (both labeled AC-007; assert `new()` returns `Ok` for non-empty key) | — | — | covered |
| AC-008 | BC-2.14.005 PC-002 | `Debug` emits exactly `"<redacted>"` — key material never appears in format output | [AC-008-AC-011-AC-016-credential-validation-redaction.webm](AC-008-AC-011-AC-016-credential-validation-redaction.webm) | [AC-008-AC-011-AC-016-credential-validation-redaction.gif](AC-008-AC-011-AC-016-credential-validation-redaction.gif) | [tape](AC-008-AC-011-AC-016-credential-validation-redaction.tape) | recorded |
| AC-009 | BC-2.14.005 PC-003/PC-004/PC-005 | no AsRef/Deref/Display/Serialize/Deserialize; `expose_secret` is ONLY access path | `test_BC_2_14_005_openai_expose_secret_returns_inner_value` + 10 `assert_not_impl_any!` invocations in `credentials.rs` `mod tests` (labeled AC-009) | — | — | covered |
| AC-010 | BC-2.14.005 PC-006 | `cargo xtask deny-bare-api-key` exits 0 — structural credential scan passes | [AC-010-deny-bare-api-key-pass.webm](AC-010-deny-bare-api-key-pass.webm) | [AC-010-deny-bare-api-key-pass.gif](AC-010-deny-bare-api-key-pass.gif) | [tape](AC-010-deny-bare-api-key-pass.tape) | recorded (refreshed 2026-09-22) |
| AC-011 | BC-2.14.006 PC-001 | `OpenAiApiKey::new("")` → `Err(E-CORE-005 / VAL / Never)` | same recording as AC-008 | — | — | recorded |
| AC-012 | BC-2.14.006 PC-003 | no silent None/default on invalid inputs | same recording as AC-008 | — | — | recorded |
| AC-013 | BC-2.14.006 EC-005 | no `From<String>`/`From<&'static str>` conversions — infallible From bypasses `new()` validation | 4 `assert_not_impl_any!` invocations in `credentials.rs` `mod tests` (labeled AC-013): `From<String>` and `From<&'static str>` for both `OpenAiApiKey` and `AnthropicApiKey` | — | — | covered |
| AC-014 | BC-2.14.006 PC-004 | error code E-CORE-005 + message format | same recording as AC-008 | — | — | recorded |
| AC-015 | BC-2.14.004 EC-006 | ClientBuilder failure maps to E-CORE-012 | `test_BC_2_14_004_build_failure_maps_to_e_core_012` in `crates/pregolya-core/src/http.rs` (non-`#[ignore]`; asserts code, category, retry_hint, message prefix) | — | — | covered |
| AC-016 | BC-2.14.006 EC-006 | `new("   ")` whitespace-only rejected with same `E-CORE-005` error | same recording as AC-008 | — | — | recorded |
| AC-017 | BC-2.14.003 EC-007 | `cargo xtask check-no-panic --fixture-mode` FLAGS violations in 14 of 17 fixture files spanning five violation classes: bare `assert!` (incl. short BC-ID + BC-ID in condition), catch-all `unreachable!()` arms (wildcard `_ =>` and irrefutable-binding forms `other =>`, `ref other =>`, `mut other =>`, guarded `other if ... =>`, `_other =>`), `.unwrap()` in macros, `todo!()` (unimplemented!() covered by inline unit test only), `assert_eq!`/`assert_ne!` with BC-ID in comparand — 14/17 fixture files flagged | [AC-017-check-no-panic-flags-violations.webm](AC-017-check-no-panic-flags-violations.webm) | [AC-017-check-no-panic-flags-violations.gif](AC-017-check-no-panic-flags-violations.gif) | [tape](AC-017-check-no-panic-flags-violations.tape) | recorded (re-recorded 2026-09-22) |
| AC-018 | BC-2.14.003 EC-006 | programmer-error guards compliant | same recording as AC-002 | — | — | recorded |
| AC-019 | BC-2.14.004 EC-006 | E-CORE-012 test is non-ignored + production path (SID-1) | `test_BC_2_14_004_build_failure_production_path_invariant` in `crates/pregolya-core/src/http.rs` (non-`#[ignore]`; asserts `map_build_failure` is in production scope; SID-1) | — | — | covered |
| AC-020 | BC-2.14.001 EC-004 / VP-BC214001-01 | `cargo xtask check-error-code-registry` exits 0 — 148 error codes validated, 0 collisions | text evidence (gate stdout) | — | — | captured 2026-09-22 (post-fix-burst-5) |

---

## AC Coverage Map

### AC-001 — constructor returns Result (BC-2.14.003 PC-001)
Covered by: AC-008/AC-011/AC-016 recording (credential nextest run includes `test_BC_2_14_003_constructor_returns_result`).

### AC-002 — check-no-panic exits 0 (BC-2.14.003 PC-004)
Recording: `AC-002-check-no-panic-pass.{webm,gif}` — re-recorded 2026-09-22
Shows: `cargo xtask check-no-panic` — output: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`

### AC-003 — debug_assert exempt (BC-2.14.003 INV-003/INV-004)
Covered by: `test_BC_2_14_003_debug_assert_not_flagged` in `xtask::tests` — places a synthetic `debug_assert!` call in non-test scope and asserts the gate returns Ok with 0 violations; discriminating (the test would fail if the `debug_assert!` exemption was removed). The gate PASS recording (AC-002) is not itself load-bearing for the exemption because the production tree contains zero `debug_assert!` or exhaustive-match `unreachable!` sites; a gate PASS on an empty scan set proves nothing about the exemption path.

### AC-004 — build_client 30s timeout (BC-2.14.004 PC-002/PC-003)
Covered by: `test_BC_2_14_004_default_timeout_applied` in `crates/pregolya-core/src/http.rs`. This test is the primary load-bearing artifact: it asserts that the `HTTP_CLIENT_TIMEOUT_SECS` constant value (`30`) appears in the reqwest `Client`'s `Debug` output, discriminating 30 seconds from any other non-zero timeout value. The check-client-timeout gate PASS (AC-005 recording) provides secondary confirmation that no production call site is missing a `.timeout()` call, but the gate cannot distinguish 30 s from 1 s and is therefore non-load-bearing for this AC.

### AC-005 — check-client-timeout exits 0 (BC-2.14.004 PC-003)
Recording: `AC-005-check-client-timeout-pass.{webm,gif}` — re-recorded 2026-09-22
Shows: `cargo xtask check-client-timeout` — output: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`

### AC-006 — timeout configured at construction; build_client() succeeds (BC-2.14.004 PC-005; DI-009 scope; E-PROV-002 firing deferred to S-2.07)
Primary code-labeled artifact: `test_BC_2_14_004_timeout_fires_against_mock_server` (labeled AC-006 in source, `#[ignore]`'d per PERF-BC214004 — ~30 s wall-clock (client timeout fires at 30 s; inline stall server sleeps 35 s on a detached thread); ungated in CI when S-2.07 integration suite runs with timing budget; full E-PROV-002 shape deferred to S-2.07). SID-1 non-ignored substitute for "timeout configured at construction" (PC-002): `test_BC_2_14_004_default_timeout_applied` (asserts `"30s"` in client Debug output). Additional Ok-return / DI-009 evidence: `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` (formerly `test_BC_2_14_004_timeout_error_shape`) and `test_BC_2_14_004_build_client_returns_ok` (not the SID-1 substitute — they verify Ok-return and build-failure shape respectively). Both are inside `#[cfg(test)]` in `http.rs`.

### AC-007 — constructor returns Ok for valid key (BC-2.14.005 PC-001)
Primary load-bearing tests: `test_BC_2_14_005_openai_new_valid_key_returns_ok` and `test_BC_2_14_005_anthropic_new_valid_key_returns_ok` (both labeled AC-007 in their doc comments in `credentials.rs`). Each asserts that `new()` with a non-empty key string returns `Ok(T)` — covering BC-2.14.005 {PC-001} (constructor returns `Result<T, PregolyaError>`). No compile-time assertion is claimed for this AC; the structural type-exclusion `assert_not_impl_any!` invocations are owned by AC-009 (AsRef/Deref/Display/Serialize/Deserialize) and AC-013 (From conversions).

### AC-008 — Debug emits exactly `"<redacted>"` (BC-2.14.005 PC-002)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: nextest run of `test_BC_2_14_005_openai_debug_emits_redacted_sentinel` and `test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel` — both PASS.

### AC-009 — no AsRef/Deref/Display/Serialize/Deserialize; expose_secret is ONLY access path (BC-2.14.005 PC-003/PC-004/PC-005)
Compile-time static assertions — all labeled `AC-009` in the `mod tests` block of `credentials.rs` (traces to BC-2.14.005 {PC-003}/{PC-004}/{INV-002}/{INV-003}):
- `assert_not_impl_any!(OpenAiApiKey: AsRef<str>)` — no auto-deref path to inner string
- `assert_not_impl_any!(AnthropicApiKey: AsRef<str>)` — no auto-deref path to inner string
- `assert_not_impl_any!(OpenAiApiKey: std::ops::Deref)` — no auto-deref to any target type
- `assert_not_impl_any!(AnthropicApiKey: std::ops::Deref)` — no auto-deref to any target type
- `assert_not_impl_any!(OpenAiApiKey: serde::Serialize)` — credential values must not appear in serialized artifacts (BC-2.14.005 {PC-003})
- `assert_not_impl_any!(AnthropicApiKey: serde::Serialize)` — same
- `assert_not_impl_any!(OpenAiApiKey: serde::de::Deserialize<'static>)` — Deserialize would bypass `new()` validation, allowing empty/whitespace keys (BC-2.14.006)
- `assert_not_impl_any!(AnthropicApiKey: serde::de::Deserialize<'static>)` — same
- `assert_not_impl_any!(OpenAiApiKey: std::fmt::Display)` — Display output invoked by `format!("{}", key)` must not expose key material (BC-2.14.005 {INV-002})
- `assert_not_impl_any!(AnthropicApiKey: std::fmt::Display)` — same

Runtime tests also labeled AC-009 (traces to BC-2.14.005 {PC-005}, TV-004): `test_BC_2_14_005_openai_expose_secret_returns_inner_value` and `test_BC_2_14_005_anthropic_expose_secret_returns_inner_value` — both assert that `expose_secret()` is the only intentional path to the inner value and returns the exact key string passed to `new()`.

### AC-010 — deny-bare-api-key structural gate (BC-2.14.005 PC-006)
Recording: `AC-010-deny-bare-api-key-pass.{webm,gif}` — re-recorded 2026-09-22
Shows: `cargo xtask deny-bare-api-key` — output: `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`

### AC-011 — empty key returns Err(E-CORE-005) (BC-2.14.006 PC-001)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_openai_empty_key_returns_err` PASS.

### AC-012 — no silent None/default (BC-2.14.006 PC-003)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_no_silent_default_on_invalid_inputs` PASS — table-driven test over `["", "   "]`.

### AC-013 — no From\<String\>/From\<&'static str\> (BC-2.14.006 EC-005)
Compile-time static assertions — all labeled `AC-013` in the `mod tests` block of `credentials.rs` (traces to BC-2.14.006 EC-005: fallible conversions must use `TryFrom`, not `From`; an infallible `From` cannot signal empty-key rejection):
- `assert_not_impl_any!(OpenAiApiKey: From<String>)` — `From<String>` would bypass `new()` validation
- `assert_not_impl_any!(OpenAiApiKey: From<&'static str>)` — `From<&'static str>` would bypass `new()` validation
- `assert_not_impl_any!(AnthropicApiKey: From<String>)` — same rationale for Anthropic type
- `assert_not_impl_any!(AnthropicApiKey: From<&'static str>)` — same rationale for Anthropic type

### AC-014 — error code E-CORE-005 + message format (BC-2.14.006 PC-004)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_error_code_and_format_table` PASS.

### AC-015 — ClientBuilder failure maps to E-CORE-012 (BC-2.14.004 EC-006)
Covered by: `test_BC_2_14_004_build_failure_maps_to_e_core_012` in `crates/pregolya-core/src/http.rs` (non-`#[ignore]`). This is the primary load-bearing artifact: it asserts code, category, retry_hint, and message prefix for the E-CORE-012 error, discriminating the full mapping contract. The AC-005 gate PASS (check-client-timeout exits 0) provides non-load-bearing secondary confirmation that production call sites compile cleanly; it is a static timeout-presence lint and proves nothing about the E-CORE-012 error mapping.

### AC-016 — whitespace-only key rejected (BC-2.14.006 EC-006)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_openai_whitespace_only_key_returns_err` PASS.

### AC-017 — check-no-panic flags violations (BC-2.14.003 EC-007)
Recording: `AC-017-check-no-panic-flags-violations.{webm,gif}` — re-recorded 2026-09-22
Shows: `cargo xtask check-no-panic --fixture-mode xtask/tests/fixtures/violations` — exits 0 (scanner-healthy verdict per BC-2.14.003 EC-007), reports `fixture-mode: 14/17 fixture files had findings`.
The 3 non-no-panic fixtures produce no findings here: `violation_pub_crate_debug_derive.rs`, `violation_derive_deserialize.rs`, and `violation_impl_display.rs` all target `deny-bare-api-key`, not `check-no-panic`.

Detected violation classes (14 fixture files):
1. `violation_assert_no_doc.rs` — bare `assert!()` in non-test code
2. `violation_assert_brace.rs` — bare `assert!()` in non-test code
3. `violation_unreachable_wildcard.rs` — wildcard-arm `_ => unreachable!()` in non-test code
4. `violation_unreachable_wildcard_enum.rs` — wildcard-arm `_ => unreachable!()` in non-test code
5. `violation_binding_catch_all.rs` — irrefutable-binding catch-all arm (`other => unreachable!()`) in non-test code
6. `violation_ref_binding_catch_all.rs` — irrefutable-binding catch-all arm (`ref other => unreachable!()`) in non-test code
7. `violation_mut_binding_catch_all.rs` — irrefutable-binding catch-all arm (`mut other => unreachable!()`) in non-test code
8. `violation_guarded_binding_catch_all.rs` — guarded irrefutable-binding catch-all arm (`other if ... => unreachable!()`) in non-test code
9. `violation_underscore_binding_catch_all.rs` — underscore-prefix binding catch-all arm (`_other => unreachable!()`) in non-test code (HIGH-1 fix-burst-3)
10. `violation_assert_bc_id_short.rs` — bare `assert!()` with short BC-ID (MED-2 fix-burst-3)
11. `violation_assert_bc_id_in_condition.rs` — bare `assert!()` with BC-ID in condition position (MED-2 fix-burst-3)
12. `violation_unwrap_in_format_macro.rs` — `.unwrap()` inside macro arguments (MED-4 fix-burst-3)
13. `violation_todo_stub.rs` — `todo!()` in production path (unimplemented!() covered by inline unit test only)
14. `violation_assert_eq_bc_id_in_comparand.rs` — `assert_eq!`/`assert_ne!` with BC-ID in right-hand comparand (not message); both macros flagged (BC-2.14.003 EC-007, Exemption-2 requires BC-ID in message argument)

Error path: demonstrates the gate detects all POL-31-mandated violation types; fix-burst 9 expanded coverage from 12 to 13 fixture files; fix-burst 18 added the 14th flagged fixture (`violation_assert_eq_bc_id_in_comparand.rs`, fifth violation class).

### AC-018 — programmer-error guards compliant (BC-2.14.003 EC-006)
Covered by: AC-002 recording — gate exits 0 despite programmer-error-guard asserts in `PregolyaError::new` etc., proving the EC-006 narrow exception is honoured.

### AC-019 — E-CORE-012 test is non-ignored + production path (BC-2.14.004 EC-006)
Covered by: `test_BC_2_14_004_build_failure_production_path_invariant` in `crates/pregolya-core/src/http.rs` (non-`#[ignore]`; doc comment: "AC-019 (traces to BC-2.14.004 {EC-006} / SID-1)"). This is the primary load-bearing artifact: it asserts the invariant that `map_build_failure` is accessible in the production code path, not only in `#[cfg(test)]` scope, satisfying SID-1 (no deferred-to-integration-test rationalization).

### AC-020 — check-error-code-registry exits 0 (BC-2.14.001 EC-004 / VP-BC214001-01)
Evidence captured: 2026-09-22
Command: `FACTORY_DIR=/Users/jmagady/Dev/pregolya/.factory cargo xtask check-error-code-registry`
Output: `error-code-registry PASSED: 148 codes validated, 0 collisions.`
Demonstrates: verifies all 148 `E-<COMPONENT>-<NNN>` codes declared in `error-taxonomy.md` are unique (zero collisions); exits 1 when zero codes extracted (vacuity guard — taxonomy format change detection); does NOT cross-validate against Rust source.

---

## Toolchain

| Tool | Version | Status |
|------|---------|--------|
| VHS | 0.11.0 | installed (`/opt/homebrew/bin/vhs`) |
| Playwright | N/A | not needed (CLI product) |
| ffmpeg | system | installed (used by VHS internally) |
| asciinema | present | available but not used (VHS preferred) |

---

## PR Embedding Snippet

```markdown
## Demo Evidence — S-1.02 Error Policy Enforcement

### AC-002: no-panic gate PASS
![AC-002 check-no-panic PASS](docs/demo-evidence/S-1.02/AC-002-check-no-panic-pass.gif)

### AC-017: no-panic gate FLAGS violations
![AC-017 check-no-panic flags violations](docs/demo-evidence/S-1.02/AC-017-check-no-panic-flags-violations.gif)

### AC-005: HTTP timeout gate PASS
![AC-005 check-client-timeout PASS](docs/demo-evidence/S-1.02/AC-005-check-client-timeout-pass.gif)

### AC-010: deny-bare-api-key structural gate PASS
![AC-010 deny-bare-api-key PASS](docs/demo-evidence/S-1.02/AC-010-deny-bare-api-key-pass.gif)

### AC-008 / AC-011 / AC-016: credential validation + redacted Debug
![AC-008/AC-011/AC-016 credential tests](docs/demo-evidence/S-1.02/AC-008-AC-011-AC-016-credential-validation-redaction.gif)
```

---

## Recording Provenance

**Validity criterion:** Gate output remains valid at any HEAD where (a) no `crates/` files are added or deleted, (b) any `crates/` changes are doc-comment-only with no panic-family, timeout, or credential constructs added or removed, (c) no files are added to, removed from, or renamed within `xtask/tests/fixtures/violations/`, and `CREDENTIAL_FIXTURE_COUNT` is unchanged, and (d) no behavioral change to gate scanner logic (`xtask/src/**/*.rs` — all Rust source files under `xtask/src/`, including `main.rs` which registers and dispatches subcommands); any scanner-logic change (guard additions, detection logic changes, new visitor methods) invalidates the gate output attestation and requires re-recording the gate counts (analyzed/exempt/violation counts, fixture-mode ratio) by running `cargo xtask <gate>` against `crates/`. The re-recorded counts are recorded by gate name and count value — not by commit SHA — because counts are stable across non-scanner commits. Future passes can apply this criterion directly rather than requiring a new per-burst paragraph. Note: a fixture-directory change (clause c) invalidates AC-017 counts and requires re-verification of the fixture-mode gate output before the evidence report counts can be considered current. Note: a change to xtask scanner logic that only broadens detection (catches more violations) may not change recorded counts for the current `crates/` contents, but a re-run is still required because the count could change if new violations are now detected.

Gate output was **recorded** at the initial recording point (2026-09-22). Recordings were **re-verified valid** through fix-burst-13 and again through fix-burst-14.

Rationale for fix-burst-13 re-verification: changes affected only `xtask/src/tests.rs` assertion values and `check_no_panic.rs` doc comments. Neither file participates in the `crates/`-rooted scan path executed by the gates. Fixture count (16 total, 13 flagged) and `CREDENTIAL_FIXTURE_COUNT` are unchanged.

Rationale for fix-burst-14 re-verification: changes affect only the following files, none of which participate in the recorded gate scan paths:
- `xtask/src/check_no_panic.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/check_client_timeout.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/main.rs` — replaced `assert!` with `check_post_exemption_vacuity` in `check_file_size`; xtask is outside the `crates/`-rooted scan
- `xtask/tests/fixtures/violations/violation_todo_stub.rs` — function renamed `unimplemented_function` → `todo_stub_function`; fixture is NOT in `crates/`; the gate scans for `todo!()` calls, not function names; detection result unchanged
- `crates/pregolya-core/src/http.rs` — doc comment changes only (replaced phantom fn ref, `F-C`→`{EC-006}`, `POL-34`→`SID-1`, `{INV-004}`→`{INV-001}`); no production panic-family, timeout, or credential constructs added or removed; all gate counts unchanged
- `crates/pregolya-core/src/credentials.rs` — doc comment change in test functions (`AC-010`→`AC-009`); no production code change; gate counts unchanged
- `docs/demo-evidence/S-1.02/evidence-report.md` — evidence artifact, not in `crates/` scan
- `CHANGELOG.md` — not in `crates/` scan

Rationale for fix-burst-15 re-verification: changes affect only the following files, none of which participate in the recorded gate scan paths:
- `xtask/src/tests.rs` — test assertion updates and doc comment changes; xtask is outside the `crates/`-rooted scan
- `xtask/src/check_no_panic.rs` — doc comment fix (stale `assert!` reference removed); xtask is outside the `crates/`-rooted scan
- `xtask/src/main.rs` — doc comment additions (cross-reference paragraphs on `is_test_file`/`is_test_class_file`); xtask is outside the `crates/`-rooted scan
- `docs/demo-evidence/S-1.02/evidence-report.md` — evidence artifact, not in `crates/` scan
- `CHANGELOG.md` — not in `crates/` scan

No changes were made to `crates/pregolya-core/` or any other `crates/`-rooted file. Fixture count (17 total, 14 flagged), `CREDENTIAL_FIXTURE_COUNT` (3), and all gate counts (25 analyzed / 16 exempt / 0 violations; 14/17 fixture-mode; 148 codes / 0 collisions) are unchanged.

Rationale for fix-burst-16 re-verification: changes affect only the following files, none of which participate in the recorded gate scan paths:
- `xtask/src/check_no_panic.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/main.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/deny_bare_api_key.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/tests.rs` — doc comment and test assertion changes; xtask is outside the `crates/`-rooted scan
- `crates/pregolya-core/src/http.rs` — doc comment changes only; no panic-family, timeout, or credential constructs added or removed; all gate counts unchanged
- `crates/pregolya-core/src/credentials.rs` — doc comment changes only; no panic-family, timeout, or credential constructs added or removed; all gate counts unchanged
- `docs/demo-evidence/S-1.02/evidence-report.md` — evidence artifact, not in `crates/` scan
- `CHANGELOG.md` — not in `crates/` scan

Conclusion: all three recorded gate outputs (25 analyzed / 16 exempt / 0 violations; 14/17 fixture-mode; 148 codes / 0 collisions) remain valid. Re-verification through fix-burst-26 confirms the evidence is current.

Rationale for fix-burst-19 re-verification: `xtask/tests/fixtures/violations/violation_assert_eq_bc_id_in_comparand.rs` was added at fix-burst-18, triggering validity criterion clause (c) (fixture-directory change). AC-017 counts updated from 13/16 to 14/17 and violation-class list extended to 14 entries (fifth class: `assert_eq!`/`assert_ne!` with BC-ID in comparand). Gate output confirmed `fixture-mode: 14/17 fixture files had findings` (2026-09-22). No `crates/`-rooted files changed; all other gate counts (25 analyzed / 16 exempt / 0 violations; 148 codes / 0 collisions) are unchanged.

Re-verified at fix-burst-20 (2026-09-22): scanner-logic clause (d) added to validity criterion. Fix-burst-20 changed `xtask/src/check_client_timeout.rs` (behavioral: `has_build_without_timeout` terminates at first depth-0 `.build()` and adds paren-depth tracking). All gates re-run — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`. Counts unchanged from prior recording.

Re-verified at fix-burst-21 (2026-09-22): scanner-logic clause (d) triggered again by `xtask/src/check_client_timeout.rs` changes — `has_build_without_timeout` gained a three-dimension depth guard on `.timeout()` crediting (brace_depth==0 && bracket_depth==0 && paren_depth==0), and `find_chain_end` had its dead loop removed with an updated doc comment. All gates re-run — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `check-non-exhaustive`: N/A — subcommand not registered in this xtask binary (gate not yet implemented in this story). Counts unchanged from prior recording.

Re-verified at fix-burst-22 (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — `find_chain_end` bounded to base-call path (`has_build_without_timeout` GroupEnd break-at-depth-0 logic) and doc comment reconciliation. Clause (d) glob widened from `xtask/src/check_*.rs` / `xtask/src/deny_*.rs` to `xtask/src/**/*.rs` to cover `main.rs` (which contains the `deny-anyhow-in-lib` and `deny-description-cache-key` scanner dispatch). All 7 registered xtask gates re-run — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.`; `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` Counts unchanged from prior recording.

Re-verified at fix-burst-23 scanner fix (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — Pattern 3 (bare `ClientBuilder::new()`) gained a non-reqwest qualifier guard preventing false-positive flags on non-reqwest builder chains; `has_build_without_timeout` had its dead `_end` parameter removed (dead code cleanup); KNOWN-LIMITATION 4 added to doc comments documenting the parenthesized or braced base subexpression false negative — `(reqwest::ClientBuilder::new()).build()` — where a depth-0 `ParenGroupEnd`/`BraceGroupEnd` closing a group that was opened before the chain start terminates the scan before the terminal `.build()` is reached. The CHANGELOG.md commit is docs-only (no `xtask/src/**/*.rs` changes) and does NOT trigger clause (d); gates were re-run against the scanner fix. All 7 registered xtask gates re-run — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.`; `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` Counts unchanged from prior recording.

Re-verified at fix-burst-24 (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — `preceded_by_non_reqwest` guard predicate extended to treat `crate`/`self`/`super`/`Self` path segments as non-suppressing (behavioral change to Patterns 2, 3, 4: path-qualified type positions like `crate::Client::new()`, `self::ClientBuilder::new()`, `super::Client::builder()`, and `Self::Client::new()` no longer suppress the violation flag; three `crate::`-qualifier pinning tests added: `test_timeout_scanner_crate_qualified_client_new_is_flagged`, `test_timeout_scanner_crate_qualified_client_builder_new_is_flagged`, `test_timeout_scanner_crate_qualified_client_builder_is_flagged`). `check_no_panic.rs` KL numbering changes (MED-005 fix) are docs-only and do not independently trigger clause (d). `CHANGELOG.md` addition (MED-001 fix) is docs-only and does not independently trigger clause (d). All 7 registered xtask gates re-run — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.`; `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` Counts unchanged from prior recording. The fix-burst-24 evidence-report docs commit is docs-only and does NOT trigger clause (d).

Re-verified at fix-burst-25 (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — new `scan_reqwest_blocking_pattern` helper added to detect `reqwest::blocking::Client::new()`, `reqwest::blocking::ClientBuilder::new().build()`, and `reqwest::blocking::Client::builder().build()` without `.timeout()`, and matching `preceded_by_reqwest` de-dup guards added to Patterns 2 and 3. Clause (a): no `crates/` files added or deleted — OK. Clause (b): no `crates/` code changes — OK. Clause (c): no fixture directory changes; `CREDENTIAL_FIXTURE_COUNT` unchanged — OK. Clause (d): TRIGGERED — scanner logic changed in `xtask/src/check_client_timeout.rs`. Gate outputs remain valid because the new detection (reqwest::blocking surface) does not apply to the existing workspace: no `crates/` code uses `reqwest::blocking::*` (the `blocking` feature is not enabled in `[workspace.dependencies]`). The scan counts are unchanged: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`. All other gate counts unchanged from prior attestation. Implementer run (fix-burst-25): 205 tests pass, 5 skipped. Clippy clean (`-D warnings`).

Re-verified at fix-burst-26 syn rewrite (2026-09-23): scanner-logic clause (d) triggered — `xtask/src/check_client_timeout.rs` completely rewritten from proc_macro2 flat-token scanner to `syn::visit::Visit`-based `TimeoutChecker` AST visitor (−499 lines). Coordinator-directed structural intervention after 7 passes finding new syntactic forms in the manual token scanner. KNOWN-LIMITATION 4 eliminated — parenthesized and braced base subexpression forms are now properly detected; their pinning tests were inverted from `is_empty()` to detection assertions. KL-1 (bare name via `use` import), KL-2 (split-statement builder chains), and KL-3 (constant-valued zero timeout) preserved. Post-attestation correction (F-P25-MED-002): the syn rewrite introduced two additional behavioral gaps not disclosed in this attestation — macro token stream blindness (no `visit_expr_macro` / `visit_stmt_macro` / `visit_item_macro` overrides) and `Client::default()` / `ClientBuilder::default()` unclassified. Both were found as HIGH findings by adversarial pass 25 and closed in fix-burst-27.

Clause (a): no `crates/` production files added or deleted — the multibyte test added to `crates/pregolya-core/src/http.rs` is inside `#[cfg(test)]` and does not affect the gate scan target. Clause (b): `crates/pregolya-core/src/http.rs` changed — `sanitize_error_message` now uses char-count cap (`chars().take(200)`); this production code change has no reqwest client usage and does not alter check-client-timeout gate outputs. Clause (c): no fixture directory changes; `CREDENTIAL_FIXTURE_COUNT` unchanged — OK. Clause (d): TRIGGERED — scanner completely rewritten.

Gate outputs remain valid because the syn rewrite finds the same 0 violations on the workspace: no `crates/` code uses `reqwest::Client::new()` without `.timeout()`, and the pre-push hook confirmed all xtask gates PASSED (check-client-timeout, check-no-panic, check-error-code-registry, deny-bare-api-key, deny-anyhow, deny-description-cache-key). Counts: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations` (unchanged). All other gate counts unchanged from prior attestation. Implementer run (fix-burst-26): 300 tests pass, 7 skipped. KL-4 tests now assert detection (was: known-limitation zero-finding, is: positive finding assertion). All other gate tests pass unchanged.

The fix-burst-26 evidence-report docs commit (this commit) is docs-only and does NOT trigger clause (d).

## fix-burst-60 re-verification

[Reviewed HEAD (adversary pass 58): 3d511a57884aed1a380b84114b75bda2d659a5c7]
[Re-verification HEAD (post-fix-burst-60): TBD — to be set in fix-burst-61]

**Test count:** 255 passed, 5 skipped (xtask); 92 passed, 2 skipped (pregolya-core). Clause (a): no `crates/` files added or deleted — OK. Clause (b): no `crates/` files changed — OK. Clause (c): no change within `xtask/tests/fixtures/violations/`; `CREDENTIAL_FIXTURE_COUNT` unchanged — OK. Clause (d): `xtask/src/tests.rs` changed — doc comment only; no gate-scanner logic, guard, or visitor behavior altered; gate counts remain valid — OK.

**Adversary pass 58 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 4 MED + 3 LOW + 2 OBS = 11 findings.

**Gate output (burst-parity normal mode):**
```
[BURST-PARITY PASS] fix-burst-60: 11 finding IDs matched; tally: 2H+2OBS+3L+4M.
```

**Gate output (burst-parity self-probe):**
```
[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch
[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch
[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected
[SELF-PROBE PASS] probe-4 (pass-number-divergent): divergent pass numbers (CHANGELOG Pass-94 vs evidence-report pass 93) correctly detected
[SELF-PROBE PASS] probe-5 (tally-line-absent): absent CHANGELOG tally correctly detected mismatch
[SELF-PROBE PASS] probe-6 (er-newest-burst-divergent): ER-newer-than-CHANGELOG correctly detected mismatch
[SELF-PROBE PASS] probe-7 (per-severity-histogram-divergent): histogram mismatch (2 HIGH declared, 1 actual) correctly detected
[SELF-PROBE PASS] probe-8 (duplicate-id-detected): duplicate finding ID (HIGH-001) in CHANGELOG correctly detected
[SELF-PROBE PASS] probe-9 (section-existence-missing): CHANGELOG newest burst missing from ER re-verification correctly detected
[SELF-PROBE PASS] probe-10 (heading-format-drift): non-canonical fix-burst heading correctly detected
[SELF-PROBE PASS] probe-11 (cl-ids-empty): empty CHANGELOG finding-ID extraction correctly detected
[SELF-PROBE PASS] probe-12 (er-ids-empty): empty ER finding-ID extraction correctly detected
```

| Finding | Severity | Disposition | Detection class | Load-bearing artifact |
|---------|----------|-------------|-----------------|----------------------|
| F-P58-HIGH-001 | HIGH | closed | probe-fires-wrong-guard | `run_self_probes` probe-1 in `check-burst-records-parity.sh` |
| F-P58-HIGH-002 | HIGH | closed | unprobed-guard-class (fifth recurrence) | `run_self_probes` probes 9–12 in `check-burst-records-parity.sh` |
| F-P58-MED-001 | MED | closed | er-gate-output-non-verbatim | gate output block in `## fix-burst-59 re-verification` in evidence-report.md |
| F-P58-MED-002 | MED | closed | re-verification-head-placeholder | `[Re-verification HEAD (post-fix-burst-59)]` annotation in evidence-report.md |
| F-P58-MED-003 | MED | closed | inverted-red-gate-doc-comment | block comment above `test_BC_2_14_003_fixture_mode_subprocess_exits_zero_when_scanner_healthy` in `xtask/src/tests.rs` |
| F-P58-MED-004 | MED | closed | changelog-section-wrong-order | `## fix-burst-59 (pass-57 findings)` section order in CHANGELOG.md |
| F-P58-LOW-001 | LOW | closed | sev-comment-inaccurate | SEV usage comment in `do_parity_check` in `check-burst-records-parity.sh` |
| F-P58-LOW-002 | LOW | closed | variable-not-local | `local tally_sum=0 n token` declaration in `do_parity_check` in `check-burst-records-parity.sh` |
| F-P58-LOW-003 | LOW | closed | test-count-paragraph-incomplete | `**Test count:**` paragraph in `## fix-burst-59 (pass-57 findings)` in CHANGELOG.md |
| F-P58-OBS-001 | OBS | closed | sev-no-single-source | `SEV_LIST` variable in `check-burst-records-parity.sh`; both histogram loops iterate `$SEV_LIST` |
| F-P58-OBS-002 | OBS | closed | missing-or-true-guard | `cl_declared` and `er_declared` extraction lines in `do_parity_check` in `check-burst-records-parity.sh` |

## fix-burst-59 re-verification

[Reviewed HEAD (adversary pass 57): 51a84eba9514cbde4b99f26f0839934c07de360e]
[Re-verification HEAD (post-fix-burst-59): 3d511a57884aed1a380b84114b75bda2d659a5c7]

**Test count:** 255 passed, 5 skipped (xtask); 92 passed, 2 skipped (pregolya-core). No production code logic changed. Clauses (a)–(d) remain valid (same rationale as CHANGELOG test-count paragraph above).

**Adversary pass 57 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 4 MED + 4 LOW + 4 OBS = 14 findings.

**Gate output (burst-parity normal mode):**
```
[BURST-PARITY PASS] fix-burst-59: 14 finding IDs matched; tally: 2H+4L+4M+4OBS.
```

**Gate output (burst-parity self-probe):**
```
[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch
[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch
[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected
[SELF-PROBE PASS] probe-4 (pass-number-divergent): divergent pass numbers (CHANGELOG Pass-94 vs evidence-report pass 93) correctly detected
[SELF-PROBE PASS] probe-5 (tally-line-absent): absent CHANGELOG tally correctly detected mismatch
[SELF-PROBE PASS] probe-6 (er-newest-burst-divergent): ER-newer-than-CHANGELOG correctly detected mismatch
[SELF-PROBE PASS] probe-7 (per-severity-histogram-divergent): histogram mismatch (2 HIGH declared, 1 actual) correctly detected
[SELF-PROBE PASS] probe-8 (duplicate-id-detected): duplicate finding ID (HIGH-001) in CHANGELOG correctly detected
```

| Finding | Severity | Disposition | Detection class | Load-bearing artifact |
|---------|----------|-------------|-----------------|----------------------|
| F-P57-HIGH-001 | HIGH | closed | script-self-probe (probe-coverage gap) | `run_self_probes` probe-6 in `check-burst-records-parity.sh` — `[SELF-PROBE PASS] probe-6 (er-newest-burst-divergent)` emitted on `--self-probe` |
| F-P57-HIGH-002 | HIGH | closed | script-self-probe (probe-coverage gap — fourth recurrence) | `run_self_probes` probe-7 (`per-severity-histogram-divergent`) and probe-8 (`duplicate-id-detected`) in `check-burst-records-parity.sh` |
| F-P57-MED-001 | MED | closed | script-logic (missing severity tokens) | `do_parity_check` histogram loop `sev` in `check-burst-records-parity.sh`; loop now `for sev in CRIT HIGH MED LOW OBS PROCESS-GAP` |
| F-P57-MED-002 | MED | closed | records-clause-walk (canonical (a)-(d) mis-mapping) | `**Test count:**` paragraph in fix-burst-57 and fix-burst-58 CHANGELOG and ER sections |
| F-P57-MED-003 | MED | closed | code-comment (inverted Red Gate provenance direction) | block comment above `test_BC_2_14_005_deny_bare_api_key_subprocess_exits_zero_on_clean_workspace` in `xtask/src/tests.rs` |
| F-P57-MED-004 | MED | closed | records-sha-annotation (two-commit SHA drift) | `[Re-verification HEAD (post-fix-burst-58)]` annotation updated to `51a84eba` SHA in `## fix-burst-58 re-verification` |
| F-P57-LOW-001 | LOW | closed | records-markup (unescaped pipe) | F-P55-OBS-001 row `\| head -1` in `## fix-burst-57 re-verification` findings table |
| F-P57-LOW-002 | LOW | closed | records-comment (stale hook description) | `check-burst-records-parity` step comment in `lefthook.yml`; probe count updated "six" → "eight" |
| F-P57-LOW-003 | LOW | closed | script-comment (fabricated awk rationale) | SEV loop comment in `do_parity_check` in `check-burst-records-parity.sh` |
| F-P57-LOW-004 | LOW | closed | records-completeness (missing AC rows) | `## Per-AC Demo Recordings` table — 7 rows added; row count now 20 (AC-001 through AC-020) |
| F-P57-OBS-001 | OBS | closed | script-scope (missing local declarations) | `local` declaration block in `do_parity_check` in `check-burst-records-parity.sh` |
| F-P57-OBS-002 | OBS | closed | script-guard-order (shadowed diagnostic) | `do_parity_check` guard order; probe-8 (`duplicate-id-detected`) verifies this path |
| F-P57-OBS-003 | OBS | deferred (documented rationale in CHANGELOG) | ci-gap (gate not in CI workflow) | pre-push hook enforcement at feature-branch push boundary |
| F-P57-OBS-004 | OBS | closed | records-order (non-monotonic headings) | `## fix-burst-57 (pass-55 findings)` heading order in CHANGELOG.md |

## fix-burst-58 re-verification

[Reviewed HEAD (adversary pass 56): 359e8e0c9db2da0f0c022c0c06ec317a20efe6ab]
[Re-verification HEAD (post-fix-burst-58): 51a84eba9514cbde4b99f26f0839934c07de360e]

**Test count:** 92 passed, 2 skipped (pregolya-core); 255 passed, 5 skipped (xtask). No production code logic changed. Clauses (a)–(d) remain valid (same rationale as CHANGELOG test-count paragraph above).

**Adversary pass 56 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 5 MED + 4 LOW + 2 OBS = 13 findings.

**Gate output (burst-parity normal mode):**
```
[BURST-PARITY PASS] fix-burst-58: 13 finding IDs matched; tally: 2H+2OBS+4L+5M.
```

**Gate output (burst-parity self-probe):**
```
[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch
[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch
[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected
[SELF-PROBE PASS] probe-4 (pass-number-divergent): divergent pass numbers (CHANGELOG Pass-94 vs evidence-report pass 93) correctly detected
[SELF-PROBE PASS] probe-5 (tally-line-absent): absent CHANGELOG tally correctly detected mismatch
[SELF-PROBE PASS] probe-6 (er-newest-burst-divergent): ER-newer-than-CHANGELOG correctly detected mismatch
```

| Finding | Severity | Disposition | Detection class | Load-bearing artifact |
|---------|----------|-------------|-----------------|----------------------|
| F-P56-HIGH-001 | HIGH | CLOSED | duplicate ID / per-severity tally false | merged `### HIGH-001` heading + `### OBS-002` heading added; ER table corrected (one `F-P55-HIGH-001` row, `F-P55-OBS-002` row added) |
| F-P56-HIGH-002 | HIGH | CLOSED | script structural gap (TD-VSDD-059) | per-severity histogram loop in `do_parity_check`; `sort \| uniq -d` duplicate-ID guard in `do_parity_check` |
| F-P56-MED-001 | MED | CLOSED | phantom symbol in closure record | `do_parity_check` substituted for phantom `check_pass_number_agreement` in HIGH-001 body |
| F-P56-MED-002 | MED | CLOSED | missing attestation (recurrence F-P55-HIGH-001 class) | `**Test count:**` + clause (a)–(d) walk added to `## fix-burst-57` |
| F-P56-MED-003 | MED | CLOSED | unprobed guard (recurrence F-P52-MED-002/F-P54-MED-001 class) | `run_self_probes` probe-5 (tally-line-absent) + probe-6 (er-newest-burst-divergent) added |
| F-P56-MED-004 | MED | CLOSED | false factual claim + wrong SID-1 (sibling of F-P55-MED-002; TD-VSDD-060) | false `pub(crate)` claim deleted; `/// SID-1 note:` re-pointed to `test_BC_2_14_005_flags_derive_debug_on_token_struct` and siblings |
| F-P56-MED-005 | MED | CLOSED | test name contradicts body (recurrence F-P52-MED-001 class) | renamed to `test_BC_2_14_005_deny_bare_api_key_subprocess_exits_zero_on_clean_workspace` |
| F-P56-LOW-001 | LOW | CLOSED | heading convention violation | `## fix-burst-57 (pass-55 findings)` |
| F-P56-LOW-002 | LOW | CLOSED | pre-declared streak position | `## fix-burst-57 re-verification` (parenthetical removed) |
| F-P56-LOW-003 | LOW | CLOSED | missing HEAD annotation | `[Reviewed HEAD (adversary pass 55)…]` + `[Re-verification HEAD (post-fix-burst-57)…]` added |
| F-P56-LOW-004 | LOW | CLOSED | incomplete table ("completed" overclaim) | `AC-018` row added to `## Per-AC Demo Recordings` |
| F-P56-OBS-001 | OBS | CLOSED | missing column (consistency) | `Detection class` column added to fix-burst-57 re-verification table |
| F-P56-OBS-002 | OBS | CLOSED | redundant guard conjuncts + guard order | `-n` conjuncts removed from pass-number comparison; empty-tally guard hoisted; addressed as part of HIGH-002 fix |

---

## fix-burst-57 re-verification
[Reviewed HEAD (adversary pass 55): 26384d58a4df7fd37f6e019b578736212c18ec04]
[Re-verification HEAD (post-fix-burst-57): 359e8e0c9db2da0f0c022c0c06ec317a20efe6ab]

**Test count:** 92 passed, 2 skipped (unchanged). The `#[ignore]` reason change in `test_BC_2_14_004_timeout_fires_against_mock_server` is text-only; no test logic or production code behavior changed. The script changes to `check-burst-records-parity.sh` are in `scripts/` (not `crates/`). Clause (a): no `crates/` files added or deleted — OK (http.rs changed but not added/deleted). Clause (b): http.rs change limited to `#[ignore]` reason text — no panic-family, timeout, or credential constructs added or removed — OK. Clause (c): no change within `xtask/tests/fixtures/violations/`; `CREDENTIAL_FIXTURE_COUNT` unchanged — OK. Clause (d): no change to `xtask/src/**/*.rs` — OK.

**Adversary pass 55 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 3 MED + 3 LOW + 3 OBS.

**Gate output (burst-parity normal mode):**
```
[BURST-PARITY PASS] fix-burst-57: 10 finding IDs matched; tally: 1H+3L+3M+3OBS.
```

**Gate output (burst-parity self-probe):**
```
[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch
[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch
[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected
[SELF-PROBE PASS] probe-4 (pass-number-divergent): divergent pass numbers (CHANGELOG Pass-94 vs evidence-report pass 93) correctly detected
[SELF-PROBE PASS] probe-5 (tally-line-absent): absent CHANGELOG tally correctly detected mismatch
[SELF-PROBE PASS] probe-6 (er-newest-burst-divergent): ER-newer-than-CHANGELOG correctly detected mismatch
```

| Finding | Severity | Disposition | Detection class | Load-bearing artifact |
|---------|----------|-------------|-----------------|-----------------------|
| F-P55-HIGH-001 | HIGH | CLOSED | dead code / paper-fix (TD-VSDD-059) | pre-existing empty-tally fail-closed guard in `check-burst-records-parity.sh`; unreachable guards deleted; CHANGELOG fix-burst-56 MED-002 and ER F-P54-MED-002 row corrected to cite empty-tally guard (records fix) |
| F-P55-MED-001 | MED | CLOSED | phantom symbol in closure record | AC-006 body + CHANGELOG MED-004 body corrected to cite `PERF-BC214004` |
| F-P55-MED-002 | MED | CLOSED | wrong SID-1 substitute (sibling of F-P54-MED-002) | AC-006 body now names `test_BC_2_14_004_default_timeout_applied` as PC-002 SID-1 substitute |
| F-P55-MED-003 | MED | CLOSED | ambiguous HEAD annotation | Two labeled lines distinguish reviewed HEAD (pass 54) from re-verification HEAD (post-fix-burst-56) |
| F-P55-LOW-001 | LOW | CLOSED | stale lefthook comment | `lefthook.yml` comments updated to enumerate four probes |
| F-P55-LOW-002 | LOW | CLOSED | missing table rows | Rows added for AC-001, AC-012, AC-014 (same recording as AC-008) in `## Per-AC Demo Recordings`; table reordered to monotonic AC number order (OBS-002 addressed here) |
| F-P55-LOW-003 | LOW | CLOSED | overstated wall-clock duration | `#[ignore]` reason on `test_BC_2_14_004_timeout_fires_against_mock_server` corrected to `~30 s wall-clock (client timeout fires at 30 s; inline stall server sleeps 35 s on a detached thread)` |
| F-P55-OBS-001 | OBS | CLOSED | missing head -1 guard | `\| head -1` appended to `cl_pass` and `er_pass` extraction pipelines |
| F-P55-OBS-002 | OBS | CLOSED | non-monotonic table row order | Per-AC Demo Recordings table reordered to monotonic AC number order |
| F-P55-OBS-003 | OBS | CLOSED | duplicate prose | Duplicate clause-walk text removed from fix-burst-55 re-verification `Gate output` bullet |

---

## fix-burst-56 re-verification
[Reviewed HEAD (adversary pass 54): 7643e0e141bcae6c769e19ead47bf2c1bdb37bea]
[Re-verification HEAD (post-fix-burst-56): 26384d58a4df7fd37f6e019b578736212c18ec04]

**Adversary pass 54 result:** 1 HIGH + 5 MED + 2 LOW + 3 OBS (11 findings)

| Finding | Severity | Status | Detection class | Load-bearing artifact |
|---------|----------|--------|-----------------|-----------------------|
| F-P54-HIGH-001 | HIGH | CLOSED | False attestation (Recording Provenance) | Clause walk in CHANGELOG `## fix-burst-55` `**Test count:**` and evidence-report `## fix-burst-55 re-verification` `**Gate output:**` — explicitly enumerates `http.rs` inside `#[cfg(test)]`, clauses a–d |
| F-P54-MED-001 | MED | CLOSED | Unprobed guard path (recurrence of F-P52-MED-002 class) | probe-4 in `run_self_probes` — `do_parity_check` exits non-zero on burst-95 (Pass-94 vs pass 93 divergence); `[SELF-PROBE PASS] probe-4 (pass-number-divergent)` |
| F-P54-MED-002 | MED | CLOSED | Overclaimed fail-closed | pre-existing empty-tally fail-closed guard in `check-burst-records-parity.sh` — format drift making pass-token absent also makes tally line un-extractable; empty-tally guard fires (unreachable guards deleted) |
| F-P54-MED-003 | MED | CLOSED | Incomplete sibling sweep (partial-fix regression) | `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` (formerly `test_BC_2_14_004_timeout_error_shape`) annotation in evidence-report F-P51-MED-002 row and CHANGELOG `### MED-001:` heading |
| F-P54-MED-004 | MED | CLOSED | AC-006 tri-directional mis-anchor | `### AC-006` header corrected; body now names `test_BC_2_14_004_timeout_fires_against_mock_server` (code-labeled, `#[ignore]`'d) + SID-1 substitutes; adjudicated per story spec v1.6 (pass-4/F-06) |
| F-P54-MED-005 | MED | CLOSED | Incorrect PC postcondition citation | `### AC-004` header `PC-002/PC-003`; `#[ignore]` reason in `test_BC_2_14_004_timeout_fires_against_mock_server` corrected to `{PC-002}` |
| F-P54-LOW-001 | LOW | CLOSED | Stale docblock (probe inventory) | `# ── Self-probe ──` docblock in `check-burst-records-parity.sh` updated to enumerate all 4 probes |
| F-P54-LOW-002 | LOW | CLOSED | Conflicting SID-1 substitute citations in adjacent lines | Doc comment SID-1 note in `test_BC_2_14_004_timeout_fires_against_mock_server` unified to cite `test_BC_2_14_004_default_timeout_applied` as authoritative PC-002 substitute |
| F-P54-OBS-001 | OBS | CLOSED | Probe heading parenthetical inconsistency | probe-2 and probe-3 `run_self_probes` headings updated to follow burst-N / pass-N-1 convention |
| F-P54-OBS-002 | OBS | CLOSED | ER newest-burst drift undetectable | `er_newest_burst` check added to `do_parity_check` in `check-burst-records-parity.sh` |
| F-P54-OBS-003 | OBS | CLOSED | Test assertion byte-length vs char-count contract mismatch | `test_sanitize_error_message_caps_at_200_chars` uses `sanitized.chars().count() <= 200` |

**Gate output (fix-burst-56):**
- `check-burst-records-parity` (normal mode): `[BURST-PARITY PASS] fix-burst-56: 11 finding IDs matched; tally: 1H+2L+3OBS+5M.`
- `check-burst-records-parity` (`--self-probe`): `[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch`; `[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch`; `[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected`; `[SELF-PROBE PASS] probe-4 (pass-number-divergent): divergent pass numbers (CHANGELOG Pass-94 vs evidence-report pass 93) correctly detected`

---

## fix-burst-55 re-verification

**Adversary pass 53 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 4 MED + 1 LOW + 2 OBS.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P53-HIGH-001 | HIGH | §AC Coverage Map AC-007 wrongly claimed compile-time assertion (actual: two runtime tests); AC-009 vacuous (no trait names or invocations cited); AC-013 vacuous (no From-variant names or invocations cited); AC-020 placed between AC-017 and AC-018 (monotonic ordering broken) | AC-007 → `test_BC_2_14_005_openai_new_valid_key_returns_ok` + `test_BC_2_14_005_anthropic_new_valid_key_returns_ok` (runtime, BC-2.14.005 {PC-001}); AC-009 → 10 named `assert_not_impl_any!` invocations (AsRef<str>, Deref, Serialize, Deserialize, Display for both types) + `test_BC_2_14_005_openai_expose_secret_returns_inner_value` + `test_BC_2_14_005_anthropic_expose_secret_returns_inner_value`; AC-013 → 4 named `assert_not_impl_any!` invocations (From<String>, From<&'static str> for both types); AC-020 moved after AC-019; all 20 entries verified |
| F-P53-HIGH-002 | HIGH | fix-burst-54 tally declared `1 HIGH + 3 MED + 2 LOW` (sum=6) but 4 MED findings enumerated (HIGH-001, MED-001 through MED-004, LOW-001, LOW-002 = 7 findings) | CHANGELOG + evidence-report `**Adversary pass 52 result:**` corrected to `1 HIGH + 4 MED + 2 LOW`; `check-burst-records-parity` gate output tally corrected to `1H+2L+4M` |
| F-P53-MED-001 | MED | burst-parity no tally-sum ↔ ID-count reconciliation; sum of tally tokens never verified against id_count, so two documents with identically wrong tallies both passed | `run_self_probes` probe-3 in `check-burst-records-parity.sh` — sum-mismatch (tally sums to 3, id_count=2) correctly exits non-zero; probe-3 SELF-PROBE PASS confirmed |
| F-P53-MED-002 | MED | F-P52-MED-002 Load-bearing artifact column cited pass-51 tally (`1H+3M+1L+1OBS`) — wrong pass; the fix was about making the tally runtime-computed, not citing a static old tally | Corrected to "runtime-computed tally shown in Gate output block below" |
| F-P53-MED-003 | MED | `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` Part 1 comment cited retired `check-client-timeout` gate attribution — recurrence of F-P51-MED-002 paper-fix pattern | Part 1 comment cites `test_BC_2_14_004_default_timeout_applied` as discriminating artifact; no vacuous gate reference |
| F-P53-MED-004 | MED | test named `test_BC_2_14_004_timeout_error_shape` asserted build-failure shape (E-CORE-012) while name and module doc implied fired-timeout error shape (E-PROV-002); four assertion messages cited "timeout-path" | `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` (renamed); assertion messages cite "build-failure"; `cargo nextest run -p pregolya-core` 92 passed, 2 skipped |
| F-P53-LOW-001 | LOW | burst-parity gate checked ID-set and tally parity but not pass-number agreement; CHANGELOG `Pass-N` vs evidence-report `Adversary pass N` mismatch was undetectable | Pass-number agreement guard in `check-burst-records-parity.sh` — if CHANGELOG `Pass-N` differs from evidence-report `Adversary pass N`, gate emits `[BURST-PARITY FAIL]` |
| F-P53-OBS-001 | OBS | three near-duplicate `map_build_failure` tests (AC-015 / AC-019 / EC-006+DI-009) lacked NOTE blocks; de-duplication sweep could remove one and leave its invariant uncovered | NOTE block in `test_BC_2_14_004_build_failure_maps_to_e_core_012`, `test_BC_2_14_004_build_failure_production_path_invariant`, `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` naming all three and their distinct invariants |
| F-P53-OBS-002 | OBS | AC-020 ordering: section placed between AC-017 and AC-018, violating monotonic scan order | AC-020 moved after AC-019 (addressed as part of F-P53-HIGH-001 fix) |

**Test count:** 92 passed, 2 skipped (pregolya-core nextest; 2 `#[ignore]`'d live-network tests). `crates/pregolya-core/src/http.rs` changed — test rename, assertion-message text, doc-comment NOTE blocks; all changes inside `#[cfg(test)]`. Clause (a): no `crates/` files added or deleted — OK. Clause (b): no panic-family, timeout constructs, or credential constructs added or removed — OK. Clause (c): no fixture-directory change — OK. Clause (d): no `xtask/src/**/*.rs` change — OK. Recorded gate outputs remain valid.

**Gate output:**
- See Test count above for clause walk.
- `check-burst-records-parity` → `[BURST-PARITY PASS] fix-burst-55: 9 finding IDs matched; tally: 1L+2H+2OBS+4M.`; `burst-parity-self-probe` → `[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch`; `[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch`; `[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected`
- Factory-dispatcher chain: `records-lint.sh` exits 0

**Known limitations:** none — all pass-53 findings closed by fix-burst-55.

---

## fix-burst-54 re-verification

**Adversary pass 52 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 4 MED + 2 LOW.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P52-HIGH-001 | HIGH | §AC Coverage Map AC-015 vacuous (timeout scanner cited for E-CORE-012 mapping); AC-019 mis-anchored to AC-015 test | AC-015 → `test_BC_2_14_004_build_failure_maps_to_e_core_012`; AC-019 → `test_BC_2_14_004_build_failure_production_path_invariant` |
| F-P52-MED-001 | MED | `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` (formerly `test_BC_2_14_004_timeout_error_shape`) body only asserted `is_ok()` while name promised error shape; AC-006 citation description wrong | Test body extended: now asserts E-CORE-012 `code`, `Category::Transport`, `RetryHint::Never`, `message` prefix via `map_build_failure`; test renamed; AC-006 description corrected |
| F-P52-MED-002 | MED | Burst-parity tally path unpinned; self-probe never reached it; PASS line unconditional "tally verified" | Second self-probe (identical IDs, divergent tally); fail-closed empty tally; runtime-computed tally shown in Gate output block below; both `[SELF-PROBE PASS]` |
| F-P52-MED-003 | MED | Collision HashMap case-sensitive; `E-CORE-012` ≠ `E-core-012` as keys despite being the same runtime code | HashMap keyed on `code.to_ascii_uppercase()`; `test_collision_detection_case_insensitive` added |
| F-P52-MED-004 | MED | `test_is_valid_error_code_coupling` doc claimed "coupling guarantee" it doesn't provide | Doc corrected: pins xtask grammar only; mirror drift with production predicate unguarded |
| F-P52-LOW-001 | LOW | Burst-parity fails open on `^## fix-burst-N` zero match (heading-format drift → silent skip) | Case-insensitive token presence check; exits 1 with `[BURST-PARITY FAIL] heading-format drift` on token-present/heading-absent |
| F-P52-LOW-002 | LOW | CHANGELOG fix-burst-53 test count baseline "up from 251" (should be 253) | Corrected to "up from 253 — `test_is_valid_error_code_coupling` added" |

**Test count:** 346 tests pass (workspace nextest), 7 skipped; xtask 255 (+1 `test_collision_detection_case_insensitive`), pregolya-core 92 (test body extended, no count change).

**Gate output:**
- Lefthook pre-push: `just check` PASSES; `check-burst-records-parity` → `[BURST-PARITY PASS] fix-burst-54: 7 finding IDs matched; tally: 1H+2L+4M.`; `burst-parity-self-probe` → both `[SELF-PROBE PASS]`
- Factory-dispatcher chain: `records-lint.sh` exits 0

**Known limitations:** none — all pass-52 findings closed by fix-burst-54.

---

## fix-burst-53 re-verification

**Adversary pass 51 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 3 MED + 1 LOW + 1 OBS.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P51-HIGH-001 | HIGH | Burst-parity hook inert (regexes never matched CHANGELOG bare headings or ER `result:**` tally format; false-green PASS on zero comparisons) | `scripts/check-burst-records-parity.sh` with fixed regexes; fail-closed empty extraction; self-probe (`--self-probe` flag) smoke test: `[SELF-PROBE PASS] burst-parity deliberately-divergent pair correctly detected mismatch` |
| F-P51-MED-001 | MED | PROCESS-GAP IDs with internal hyphen not matched by `[A-Z]+` in severity token | All severity patterns changed to `(CRIT\|HIGH\|MED\|LOW\|OBS\|PROCESS-GAP)` throughout both extraction paths |
| F-P51-MED-002 | MED | AC-004/AC-006 vacuous gate-PASS attributions (incomplete sibling sweep of F-P50-MED-002) | AC-004 → `test_BC_2_14_004_default_timeout_applied`; AC-006 → `test_BC_2_14_004_build_client_returns_ok` + `test_BC_2_14_004_build_client_ok_and_build_failure_ec006` (formerly `test_BC_2_14_004_timeout_error_shape`) |
| F-P51-MED-003 | MED | xtask `is_valid_error_code` rejected Custom-namespace codes; accepted unconstructible 2/4-digit suffix codes | `is_valid_component_segment_xtask` added; suffix exactly-3-digits enforced; `test_is_valid_error_code_coupling` added (9-row fixture) |
| F-P51-LOW-001 | LOW | `ID_COUNT` doubled on empty (`grep -c` exit-1 + `\|\| echo "0"` double-emission) | `printf '%s\n' "$cl_ids" \| wc -l \| tr -d ' '` |
| F-P51-OBS-001 | OBS | Adversary dispatch-brief paraphrase diverges from code (`display_message()`/`ApiKeyExposed` absent; `debug_assert!` polarity inverted; enum-variant notation for struct) | DISCARDED — code is correct; adversary prompt error, not product defect |

**Test count:** 345 tests pass (cargo nextest), 7 skipped (pregolya-core unchanged); xtask 254 tests pass (3 updated/added: `test_is_valid_error_code_coupling`, updated `test_is_valid_error_code`, updated `test_extract_error_code_not_a_row`).

**Gate output:**
- Lefthook pre-push: `just check` PASSES; `check-burst-records-parity` → `[BURST-PARITY PASS] fix-burst-53: 6 finding IDs matched; tally verified.`; `burst-parity-self-probe` → `[SELF-PROBE PASS] burst-parity deliberately-divergent pair correctly detected mismatch`
- Factory-dispatcher chain: `records-lint.sh` exits 0 on factory-artifacts branch

**Known limitations:** none — all pass-51 findings closed by fix-burst-53 (OBS-001 discarded per triage).

---

## fix-burst-52 re-verification

**Adversary pass 50 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 3 HIGH + 5 MED + 3 LOW + 2 OBS.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P50-HIGH-001 | HIGH | Three-way inventory contradiction (STATE.md D-422 said 9; CHANGELOG/evidence-report both said 13) | STATE.md D-422 corrected to "13 pass-49 findings closed" in Decisions Log, Current Phase Steps, and Convergence Status |
| F-P50-HIGH-002 | HIGH | records-lint.sh false-green (empty-`FROZEN_HEAD_SHA` silently passed) | `check_l13` empty-SHA path now emits blocking `[FAIL]`; probe J added (`frozen HEAD after push = TBD` → asserts FAIL) |
| F-P50-HIGH-003 | HIGH | error-taxonomy E-CORE-012 `<reason>` = verbatim build() Err (contradicts BC-2.14.004 §EC-006 sanitization mandate) | E-CORE-012 `<reason>` corrected: "sanitized builder error string — URL credentials redacted to `://***@host`, capped at 200 `char`s per DI-010/BC-2.14.005 {INV-001}; `sanitize_error_message` required" |
| F-P50-MED-001 | MED | Checkpoint staleness (6th+ recurrence) — frozen HEAD not recorded in STATE.md | Frozen HEAD `d96b686ca24bdcef1f4664ac86e9910d573e1d3d` recorded in all five STATE.md surfaces; D-422 marked COMPLETE |
| F-P50-MED-002 | MED | Vacuous AC-003 attestation (gate PASS on empty scan set proves nothing) | Coverage reattributed to `test_BC_2_14_003_debug_assert_not_flagged` (synthetic `debug_assert!`; discriminating) |
| F-P50-MED-003 | MED | Stale probe count "7 (A–G)" in fix-burst-50 CHANGELOG paragraph and evidence-report row | Updated to "all probes (A–I; probes H/I added fix-burst-51, probe J added fix-burst-52)" |
| F-P50-MED-004 | MED | story spec §File Structure Requirements missing `xtask/src/tests.rs` (MODIFY) and `xtask/tests/fixtures/violations/` (CREATE) | Both rows added in story spec v1.27 with AC/Task anchors |
| F-P50-MED-005 | MED | lefthook non-feature-branch path arbitrarily selected evidence report then hard-failed | Non-feature-branch path exits 0 with `[BURST-PARITY SKIP]`; `find` fallback removed |
| F-P50-LOW-001 | LOW | `NEWEST_BURST` by document order not numeric max | `sort -rn | head -1` (numeric max, order-independent) |
| F-P50-LOW-002 | LOW | probe G `_PROBE_G_CLEANUP_REF` not cleared after self-cleanup | `_PROBE_G_CLEANUP_REF=""` added after happy-path `update-ref -d` |
| F-P50-LOW-003 | LOW | Frozen-HEAD extraction filter rejected hyphen separator form (`frozen-HEAD <sha>`) | Filter changed to `grep -iE 'frozen[-[:space:]]+HEAD'`; probe H2 added |
| F-P50-OBS-001 | OBS | `check_l13` Step 1 comment claimed section scoping the implementation doesn't perform | Comment corrected to "corpus-wide scan ... by convention" |
| F-P50-OBS-002 | OBS | `check-burst-records-parity` checked section-presence only; three-way contradiction undetectable | Hook now extracts and compares finding-ID sets and declared tally counts; emits runtime-computed `[BURST-PARITY PASS] fix-burst-N: M IDs matched; tally verified` |

**Test count:** 345 tests pass (cargo nextest), 7 skipped (workspace) — unchanged from fix-burst-49; no Rust logic changed.

**Gate output:**
- Lefthook pre-push: `just check` PASSED; `check-burst-records-parity` PASSED
- Factory-dispatcher chain: `records-lint.sh` exits 0 on factory-artifacts branch (separate trigger)

**Known limitations:** none — all pass-50 findings closed by fix-burst-52.

---

## fix-burst-51 re-verification

**Adversary pass 49 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 6 MED + 3 LOW + 3 OBS.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P49-HIGH-001 | HIGH | Three-way inventory contradiction (STATE.md/CHANGELOG/evidence-report pass-48 tally diverged: 6 / 10 / 14) | STATE.md D-420 corrected to `1 HIGH + 4 MED + 5 LOW + 3 OBS + 1 PROCESS-GAP`; D-421 closure enumeration expanded to all 14 pass-48 findings; CHANGELOG/evidence-report reconciled from single adjudicated source |
| F-P49-MED-001 | MED | Phantom-symbol citation + mis-attribution in OBS attestation rows | evidence-report OBS-001 Detection-class corrected to `check_l13`; OBS-002 Load-bearing-artifact corrected to "L10/L11 hash-digest bans (`check_l9` already carried exclusion)" |
| F-P49-MED-002 | MED | Records contradiction: CHANGELOG and evidence-report cited different symbols for same HIGH finding, neither present in STATE.md D-419 | Both records rewritten to behavioral anchor: `check_l13 parameterized with optional path arg; swap-and-restore ELIMINATED; _L13_CHECK mirror RETIRED` |
| F-P49-MED-003 | MED | Inverted mechanism description + unapplied-claim in CHANGELOG HIGH-001 "What was fixed" | CHANGELOG HIGH-001 rewritten: actual D-419 correction described accurately; `grep -q "does not match live"` as primary guard |
| F-P49-MED-004 | MED | Stale test count (300/7 = fix-burst-26 figure, not fix-burst-49/50 figure) | Corrected to "345 tests pass (cargo nextest), 7 skipped (workspace) — unchanged from fix-burst-49" |
| F-P49-MED-005 | MED | Missing validity-criterion clause (a) attestation (fixture rename triggered clause) | Clause (a) paragraph added; gate counts confirmed unchanged: `25 analyzed, 16 exempt, 0 violations`; fixture-mode `14/17`; `148 codes / 0 collisions` |
| F-P49-MED-006 | MED | lefthook `check-burst-records-parity` hardcoded `S-1.02` path; missing-file exited 0 | Path derived from branch name via `STORY_ID` extraction from `feature/S-X.XX`; missing-file exits 1 (fail-closed) |
| F-P49-LOW-001 | LOW | records-lint.sh case-sensitive frozen-HEAD extraction | `check_l13` extraction changed to case-insensitive; probe H added (capitalized `**Frozen HEAD:**` form assertion) |
| F-P49-LOW-002 | LOW | records-lint.sh feature-branch resolution unanchored to frozen SHA line | Resolution anchored to co-located SHA line; probe I added (multi-branch decoy test) |
| F-P49-LOW-003 | LOW | evidence-report gate output conflated lefthook and factory-dispatcher chains | Gate output split into two distinct attestation lines |
| F-P49-OBS-001 | OBS | `--skip-self-probe` output byte-identical to validated run | `[SELF-PROBE SKIPPED]` banner + `probes=skipped` token on `RESULT:` line |
| F-P49-OBS-002 | OBS | credential `_blocked.rs` fixtures don't discriminate `#[non_exhaustive]` | No action — acknowledged by adversary; attribute coverage provided by `test_non_exhaustive_inventory_matches_source` and `test_all_pub_types_have_non_exhaustive` |
| F-P49-OBS-003 | OBS | STATE.md BRANCH STATE used 7-char SHA | Normalized to 40-char form |

**Test count:** 345 tests pass (cargo nextest), 7 skipped (workspace) — no Rust logic changed in fix-burst-51.

**Gate output:**
- Lefthook pre-push: `just check` PASSED; `check-burst-records-parity` PASSED
- Factory-dispatcher chain: `records-lint.sh` exits 0 on factory-artifacts branch (separate trigger)

**Known limitations:** none — all pass-49 findings closed by fix-burst-51 (OBS-002 explicitly no-action per adversary).

---

## fix-burst-50 re-verification

**Adversary pass 48 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 4 MED + 5 LOW + 3 OBS + 1 PROCESS-GAP.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P48-HIGH-001 | HIGH | Records fidelity (inverted mechanism description in D-419) | STATE.md D-419: "self-contained swap-and-restore" corrected to accurately describe `check_l13` parameterization with optional path arg; `_L13_CHECK` mirror RETIRED (0 calls remaining); swap-and-restore ELIMINATED; all probes (A–I; probes H/I added in fix-burst-51, probe J added in fix-burst-52) call `check_l13 "$PROBE_L13X"` with synthetic path directly; D-419 MED-001 attribution fixed; missing MED-002/MED-003 closures added. [Probe count updated in fix-burst-52; fix-burst-50 value was 7 (A–G).] |
| F-P48-MED-001 | MED | Records accuracy (`probe_must_fail` citation stale post-fix-burst-49) | CHANGELOG fix-burst-49 section and evidence-report fix-burst-49 re-verification: `probe_must_fail "L13-probe-G"` references corrected to inline grep guard description; no `probe_must_fail` call exists in any L13 probe post-parameterization |
| F-P48-MED-002 | MED | Records accuracy (CHANGELOG fix-burst-49 extraction-scope statement) | CHANGELOG fix-burst-49 section: extraction scope statement corrected to accurately describe `check_l13 [state_md_path]` parameterized invocation pattern; prior statement described a nonexistent internal helper |
| F-P48-MED-003 | MED | Records-vs-code fidelity (UI pass fixture names contradict bodies) | UI fixture files renamed `_match_with_dots_passes.rs` → `_expose_secret_passes.rs`; `PASS_FIXTURES` constant updated in `non_exhaustive_external_gate::ui()`; story spec v1.26 `PASS_FIXTURES` table rows updated to `_expose_secret_passes` |
| F-P48-MED-004 | MED | Records accuracy (D-419/D-420 MED-001 attribution contradiction) | STATE.md D-419/D-420 MED-001 entries reconciled; D-419 now correctly records all per-finding closures; D-420 description disambiguated |
| F-P48-LOW-001 | LOW | Records accuracy | CHANGELOG fix-burst-49 section: transient disposable branch name literal replaced with `<branch>` placeholder per TD-VSDD-091 behavioral-anchor convention |
| F-P48-LOW-002 | LOW | records-lint.sh probe G cleanup race | `_PROBE_G_CLEANUP_REF` EXIT trap sentinel added; PID-unique disposable ref deleted on both success and error exit paths via `git update-ref -d "$_PROBE_G_CLEANUP_REF"` |
| F-P48-LOW-003 | LOW | records-lint.sh probe G false-green gap (no positive assertion) | Probe G now asserts `grep -q "does not match live"` on `check_l13` output (primary) plus absence of `[PASS]` token (secondary); both must hold; inline exit guard fails on false-green |
| F-P48-LOW-004 | LOW | Records accuracy (story spec path normalization) | story spec file structure rows: 3 rows corrected from `pregolya-core/src/...` to `crates/pregolya-core/src/...` in §File Structure Requirements |
| F-P48-LOW-005 | LOW | Records accuracy | CHANGELOG fix-burst-49 section: `probe_must_fail` invocation description corrected to inline grep guard terminology consistent with shipped `records-lint.sh` |
| F-P48-OBS-001 | OBS | records-lint.sh `check_l13` MAX_D awk extraction fragility | `MAX_D` extraction now pipes through `awk -F'|' '{print $2}'` before `grep -oE '^[[:space:]]*D-[0-9]+'`; prevents matching `D-NNN` tokens in later table columns from inflating the max decision ID |
| F-P48-OBS-002 | OBS | records-lint.sh `check_l10`/`check_l11` false-positive on hooks files | `:!hooks/**` exclusion added to git diff path-specs in `check_l10` and `check_l11`; prevents hooks directory self-referential patterns from triggering the L10/L11 hash-digest bans (`check_l9` already carried the exclusion before this fix) |
| F-P48-OBS-003 | OBS | evidence-report historical section annotations | fix-burst-48 HIGH-001 and MED-002 rows annotated as superseded by fix-burst-49 closures; fix-burst-47 and earlier historical probe citations annotated as historical with supersession chain |
| F-P48-PROCESS-GAP-001 | PROCESS-GAP | Burst-parity check unenforced at push time | `check-burst-records-parity` bash command added to `lefthook.yml` pre-push section; asserts newest `## fix-burst-N` heading in CHANGELOG.md has a matching `## fix-burst-N re-verification` heading in evidence-report.md before any push proceeds |

**Validity-criterion clause (a):** Clause (a) triggered by rename of `open_ai_api_key_match_with_dots_passes.rs` → `open_ai_api_key_expose_secret_passes.rs` and the Anthropic sibling `anthropic_api_key_match_with_dots_passes.rs` → `anthropic_api_key_expose_secret_passes.rs`. Net change: renamed files remain `/tests/`-path-exempt; gate counts unchanged: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 violations`; fixture-mode `14/17`; `148 codes / 0 collisions` — all unchanged from fix-burst-49.

**Test count:** 345 tests pass (cargo nextest), 7 skipped (workspace) — unchanged from fix-burst-49; no Rust logic changed. All xtask gates PASSED (check-client-timeout, check-no-panic, check-error-code-registry, deny-bare-api-key, deny-anyhow, deny-description-cache-key).

**Gate output:**
- Lefthook pre-push: `just check` PASSED; `check-burst-records-parity` PASSED (BURST-PARITY PASS)
- Factory-dispatcher chain: `records-lint.sh` exits 0 on factory-artifacts branch (separate trigger)

**Known limitations:** none — all pass-48 findings closed by fix-burst-50.

---

## fix-burst-49 re-verification

**Adversary pass 47 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 4 MED + 5 LOW.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P47-HIGH-001 | HIGH | Structural regression (probe coupled to transient branch) | `run_self_probes` probe G now creates PID-unique `refs/heads/feature/records-lint-selfprobe-g-$$`; synthetic STATE.md references that branch with mismatched frozen HEAD `000...001`; `check_l13 "$PROBE_L13G"` resolves disposable ref to real HEAD (≠ `000...001`) → `check_l13` output contains no `[PASS]` token → inline negative guard exits 2 on false-green; throwaway ref deleted on both success and error paths; no `feature/S-1.02` reference anywhere in probe |
| F-P47-MED-001 | MED | Silent-skip detection gap | `check_l13` PASS line now emits `LIVE_HEAD_COVERAGE` suffix: `[live-HEAD: checked(<branch>=matched)]` (where `<branch>` is the feature branch name, runtime-derived from `§Session Resume Checkpoint`) when branch resolved and SHA matched, `[live-HEAD: skipped(branch-not-found)]` when unresolvable, `[live-HEAD: skipped(no-frozen-sha-in-checkpoint)]` when no frozen SHA; observable difference between executed and skipped paths |
| F-P47-MED-002 | MED | TD-VSDD-059 paper-fix (non-discriminating fixtures) | Fail fixtures renamed to `open_ai_api_key_external_field_access_blocked.rs` / `anthropic_api_key_external_field_access_blocked.rs`; `.stderr` files updated; `FAIL_FIXTURES` in `non_exhaustive_external_gate::ui()` updated; pass fixtures now call `expose_secret()` (discriminating: fails if `expose_secret` removed or made private); gate doc comment corrected to state E0532 mechanism; story spec v1.25 §File Structure Requirements rows updated |
| F-P47-MED-003 | MED | TD-VSDD-091 volatile-SHA citation | evidence-report fix-burst-48 MED-001 Load-bearing-artifact cell: SHA tokens `2d71869` and `489584d` removed; replaced with behavioral anchors describing the state-manager burst content |
| F-P47-MED-004 | MED | Structural defect (destructive backup in trap-deleted PROBE_TMP) | `check_l13` now accepts optional first arg `check_l13 [state_md_path]` defaulting to `${FACTORY_DIR}/STATE.md`; all 7 probes (A–G) call `check_l13 "$PROBE_L13X"` directly with synthetic file; `_L13_CHECK` mirror retired entirely (0 remaining calls); all 3 swap-and-restore windows eliminated; canonical STATE.md never overwritten by probes |
| F-P47-LOW-001 | LOW | Records accuracy | CHANGELOG fix-burst-48 HIGH-001: "§Session Resume Checkpoint §DEVELOP STATE" corrected to "§Session Resume Checkpoint section (whole awk-delimited section)" |
| F-P47-LOW-002 | LOW | Records accuracy (conflation) | evidence-report fix-burst-48 HIGH-001 row: Load-bearing-artifact split into two distinct assertions — `probe_must_fail "L13-probe-G"` (asserts on `_L13_CHECK` mirror) and `L13-probe-G-real` inline guard (swap-and-restore on shipped `check_l13`) |
| F-P47-LOW-003 | LOW | Rust semantics accuracy | CHANGELOG fix-burst-48 MED-004 and evidence-report fix-burst-47 re-verification LOW-002 row: "accessible within the crate" / "accessible within the crate's module tree" corrected to "accessible within the defining module and its descendants" |
| F-P47-LOW-004 | LOW | Records omission (missing §File Structure Requirements rows) | Story spec v1.24: `open_ai_api_key_match_with_dots_passes.rs` (CREATE), `anthropic_api_key_match_with_dots_passes.rs` (CREATE), `non_exhaustive_external_gate.rs` (MODIFY) rows added; v1.25: fail fixture rows updated to `_external_field_access_blocked` names, pass fixture descriptions corrected |
| F-P47-LOW-005 | LOW | Records ordering (non-monotonic) | evidence-report.md: all 22 `## fix-burst-N re-verification` sections reordered to strict descending order (48→27) |

**Test count (fix-burst-49):** 253 run: 253 passed, 5 skipped (xtask); 345 run: 345 passed, 7 skipped (workspace). No Rust logic changes; trybuild fixture rename maintains 8 compile_fail + 7 pass = 15 fixtures.

**Gate output:** unchanged — 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions. (No xtask gate logic changed in fix-burst-49.)

**Known limitations:** unchanged from fix-burst-48 — see fix-burst-48 re-verification KL table for active limitations.

---

## fix-burst-48 re-verification

**Adversary pass 46 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 4 MED + 1 OBS.

Fix-burst-48 closed all 5 non-OBS findings from adversary pass-46 (1 HIGH + 4 MED). Test counts unchanged: **253 run: 253 passed, 5 skipped** (xtask per-crate: `cargo nextest run -p xtask`). Full workspace: **345 run: 345 passed, 7 skipped** (`cargo nextest run --workspace`). No Rust code changes — records-only fixes plus `records-lint.sh` L13 live-HEAD check + probe G.

**Detection-class attestation:**

| Finding | Load-bearing artifact | Status |
|---------|----------------------|--------|
| HIGH-001 (L13 vacuous live-HEAD check) | *[Superseded by fix-burst-49: `_L13_CHECK`/`L13-probe-G-real`/swap-and-restore eliminated; probe G now calls parameterized `check_l13 "$PROBE_L13G"` with synthetic file]* `check_l13` Step 3.5 updated: live branch HEAD check via `git rev-parse --verify refs/heads/<branch>`; `probe_must_fail "L13-probe-G"` (asserts on `_L13_CHECK` mirror: synthetic frozen HEAD `000...001` != live branch HEAD → FAIL); `L13-probe-G-real` inline guard: swap-and-restore invokes real `check_l13` against same synthetic file and asserts FAIL output; `records-lint.sh` exits 0 | pass |
| MED-001 (STATE.md stale) | Self-resolved: state-manager burst that recorded D-415 COMPLETE (fix-burst-47 done) and D-416 IN FLIGHT (adversary pass-46 dispatched); no code action required in the feature branch | pass |
| MED-002 (probes exercised mirror not shipped) | *[Superseded by fix-burst-49: `_L13_CHECK`/`L13-probe-G-real`/swap-and-restore eliminated; probe G now calls parameterized `check_l13 "$PROBE_L13G"` with synthetic file]* Bundled: probe F extended to invoke real `check_l13` via swap-and-restore; listed with HIGH-001 | pass |
| MED-003 (banner "Five probes") | Bundled: `run_self_probes` L13 banner updated to "Seven probes (A–G)"; listed with HIGH-001 | pass |
| MED-004 (false Rust semantics in 3 artifacts) | Story spec AC-008 parenthetical corrected (v1.23); CHANGELOG fix-burst-47 LOW-002 paragraph corrected; evidence-report fix-burst-47 re-verification LOW-002 row corrected. Accurate claim: tests use `from_raw_for_tests()` because it is the explicit `#[cfg(test)]`-gated validation-bypass helper, not because the tuple-struct form is unavailable from within the crate | pass |

**Clause (d) analysis:** fix-burst-48 modifies `.factory/hooks/records-lint.sh` (live-HEAD check added to `check_l13` and `_L13_CHECK`; probe G added; probe F extended; banner updated). No `xtask/src/**/*.rs` scanner logic changed. Clause (d) does NOT fire. Gate output counts remain valid and unchanged.

*Note: fix-burst-49 retired `_L13_CHECK` entirely; the live-HEAD suffix `${LIVE_HEAD_COVERAGE}` is now appended directly in `check_l13`.*

**Gate output:** unchanged (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged from fix-burst-47. No new KL entries.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-47 re-verification

**Adversary pass 45 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 3 MED + 2 LOW.

Fix-burst-47 closed all 5 findings from adversary pass-45 (3 MED + 2 LOW). Test counts unchanged from fix-burst-46 plus one new xtask test: **253 run: 253 passed, 5 skipped** (xtask per-crate: `cargo nextest run -p xtask`). Full workspace: **345 run: 345 passed, 7 skipped** (`cargo nextest run --workspace`). Net change from fix-burst-46: +1 xtask test (`test_allowlist_is_allowed_entry_side_normalization`).

**Detection-class attestation:**

| Finding | Load-bearing artifact | Verification |
|---------|----------------------|--------------|
| MED-001 (evidence-report MED-004 probe direction inverted) | Record correction: fix-burst-46 MED-004 row updated from `probe_must_fail "L13-probe-E"` to `probe_must_not_fail "L13-probe-E"`; no code change required — record-only | pass |
| MED-002 (AllowList::is_allowed entry-side normalization unpinned) | New test `test_allowlist_is_allowed_entry_side_normalization`: reverting entry-side `let normalized_entry = e.path.replace('\\', "/")` in `AllowList::is_allowed` causes assertion failure; test is LOAD-BEARING | pass |
| MED-003 (L13 false-green via IN FLIGHT newest D-NNN row / frozen-HEAD SHA currency) | New `L13-probe-F` in `records-lint.sh`: synthetic STATE.md with §Session Resume Checkpoint frozen HEAD SHA absent from all COMPLETE rows → `probe_must_fail "L13-probe-F"` asserts FAIL *(historical: probe_must_fail form retired in fix-burst-49 structural refactor; probe F now calls parameterized check_l13 directly)*; `records-lint.sh` exits 0 on current STATE.md; `check_l13` function-header comment updated to document both "3/3 surfaces in sync" and "2/2 surfaces asserted (convergence SKIPPED)" PASS templates (LOW-001 bundled into this fix) | pass |
| LOW-001 (check_l13 function-header comment incomplete) | Records fix bundled with MED-003: function-header banner updated to document both PASS templates | pass |
| LOW-002 (AC-008 parenthetical correction) | AC-008 parenthetical corrected: `#[non_exhaustive]` restricts only external-crate construction; private field accessible within the defining module and its descendants; `from_raw_for_tests()` is `#[cfg(test)]`-gated validation-bypass helper — not because tuple form is unavailable; story spec version bumped to v1.22 | pass |

**Clause (d) analysis:** fix-burst-47 modifies `xtask/src/tests.rs` (new test `test_allowlist_is_allowed_entry_side_normalization`). The new test exercises an existing production code path (`AllowList::is_allowed` entry-side normalization) — scanner logic in `AllowList::is_allowed` was not changed. Clause (d) does NOT fire for a test-only addition that exercises no new detection behavior. Gate output counts remain valid and unchanged.

**Gate output:** unchanged (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged from fix-burst-46. No new KL entries.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-46 re-verification

**Adversary pass 44 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 1 HIGH + 6 MED + 0 LOW.

All pass-44 findings closed. See CHANGELOG fix-burst-46 for details.

**Test count: 252 run: 252 passed, 5 skipped (xtask per-crate: `cargo nextest run -p xtask`). Full workspace: 344 run: 344 passed, 7 skipped (`cargo nextest run --workspace`).**

**Clause (d) analysis:** fix-burst-46 makes code changes to `xtask/src/main.rs` (extraction of `is_size_gate_excluded`) and `xtask/src/tests.rs`. Clause (d) FIRES for `is_size_gate_excluded`. The check is affirmative: `is_size_gate_excluded` correctly returns `false` for production source files (no scanner regression), returns `true` only for files that SHOULD be excluded (`/target/`, `.gen.rs`, `/tests/fixtures/`). Verified by `test_is_size_gate_excluded_windows_paths` negative controls.

**Detection-class attestation:**

| Finding | Load-bearing artifact | Verification |
|---------|----------------------|--------------|
| HIGH-001 (CHANGELOG fix-burst-43 OBS-001 labels) | Text correction: "§Current Phase Steps rows carrying `\| COMPLETE \|`" and "Four self-probes (A/B/C/D)" | pass |
| MED-001 (fix-burst-45 test count basis) | Count corrected to "343 run: 343 passed, 7 skipped" with explicit workspace basis | pass |
| MED-002 (§Convergence Status duplication) | STATE.md §Convergence Status: duplicate paragraph removed, inline heading fragment removed; `records-lint.sh` exits 0 | pass |
| MED-003 (two normalization sites unpinned) | `test_is_size_gate_excluded_windows_paths` (3 positive backslash, 2 negative): reverting `replace('\\', "/")` in `is_size_gate_excluded` causes failures; `test_allowlist_exact_match` backslash assertion: reverting path-side normalization (`let normalized_path = path.replace('\\', "/")`) in `AllowList::is_allowed` causes failure; entry-side normalization (`let normalized_entry = e.path.replace('\\', "/")`) not yet pinned in fix-burst-46 — load-bearing test added in fix-burst-47 | pass |
| MED-004 (L13 "3/3" hardcoded) | `check_l13` runtime denominator + `probe_must_not_fail "L13-probe-E"` (convergence-absent path) *(historical: probe_must_not_fail form retired in fix-burst-49 structural refactor; probe E now calls parameterized check_l13 directly)*; `records-lint.sh` exits 0 | pass |
| MED-005 (STATE.md checkpoint stale) | D-412 COMPLETE + D-413 IN FLIGHT recorded; checkpoint re-stamped to D-412; `records-lint.sh` L13 3/3 in sync | pass |
| MED-006 (AC-009 phantom cite + AnthropicApiKey omission) | AC-009 Verified-by cites both `assert_not_impl_any!(OpenAiApiKey: AsRef<str>)` and `assert_not_impl_any!(AnthropicApiKey: AsRef<str>)`; phantom compile-fail removed; `.as_str()` removed | pass |

**Gate output:** unchanged (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-45 re-verification

**Adversary pass 43 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 1 HIGH + 1 MED + 1 LOW.

All pass-43 findings closed. See CHANGELOG fix-burst-45 for details.

**Test count: 343 run: 343 passed, 7 skipped (`cargo nextest run --workspace`; xtask per-crate: 251 run: 251 passed, 5 skipped).**

**Clause (d) analysis:** fix-burst-45 makes NO changes to `xtask/src/**/*.rs` scanner logic. Clause (d) does NOT fire. All changes are records-lint.sh header corrections (factory-artifacts) and CHANGELOG/evidence-report corrections (feature branch).

**Detection-class attestation:**

| Finding | Load-bearing artifact | Verification |
|---------|----------------------|--------------|
| HIGH-001 (records-lint.sh header + PGAP label) | `grep "Phase Progress\|Decision Log"` returns zero hits in entire records-lint.sh after devops-engineer fix; PGAP entry verified to read "newest COMPLETE D-NNN in §Current Phase Steps"; `records-lint.sh` exits 0 on current STATE.md | pass |
| MED-001 (header skip-conditions rewrite) | Header "Skip conditions" paragraph replaced with "Blocking FAIL" / "Genuine skip" taxonomy; `records-lint.sh` exits 0 on current STATE.md | pass |
| LOW-001 (evidence-report attestation table) | Two-row detection-class table added to `## fix-burst-44 re-verification` naming `L13-probe-D` as load-bearing artifact for MED-005 | pass |

**Gate output:** unchanged (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-44 re-verification

**Adversary pass 42 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 5 MED + 1 LOW.

All pass-42 findings closed. See CHANGELOG fix-burst-44 for details.

**Test count: 251 run: 251 passed, 5 skipped.**

**Clause (d) analysis:** fix-burst-44 makes NO changes to `xtask/src/**/*.rs` scanner logic. Clause (d) does NOT fire. All changes are CHANGELOG corrections (feature branch) and STATE.md/records-lint.sh updates (factory-artifacts).

### Detection-class attestation

| Finding | Load-bearing artifact | Verification |
|---------|----------------------|--------------|
| MED-003 (records-lint.sh L13 labels) | `grep` confirms zero "Phase Progress"/"Decision Log" occurrences inside `check_l13` function body and probe fixtures (15 sites corrected); 2 header-block sites deferred to fix-burst-45 | pass |
| MED-005 (vacuity FAIL guards) | `L13-probe-D`: synthetic STATE.md with valid §Current Phase Steps COMPLETE row and no §Session Resume Checkpoint section → `_L13_CHECK` returns 1 (empty `cp_max` branch) → `probe_must_fail "L13-probe-D"` asserts FAIL; `records-lint.sh` exits 0 on current STATE.md; four self-probes (A/B/C/D) all pass | pass |

**Gate output:** unchanged (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-43 re-verification

**Adversary pass 41 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 2 MED + 2 LOW + 1 OBS(process-gap).

All pass-41 findings closed. See CHANGELOG fix-burst-43 for details.

**Test count: 251 run: 251 passed, 5 skipped.**

**Clause (d) analysis:** fix-burst-43 changes `xtask/src/main.rs` (`validate_allowlist_entry_path` normalization added) and `xtask/src/tests.rs` (new test `test_validate_allowlist_entry_path_windows_separator`). Clause (d) FIRES for `main.rs`. The normalization is a no-op on POSIX-path inputs (existing tests cover those); 1 new test with 3 assertions covers backslash validation; `test_validate_allowlist_entry_path_windows_separator` is load-bearing (reverts to `is_err` for positive cases if normalization is removed).

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| `validate_allowlist_entry_path` POSIX-path inputs (unchanged — normalization is no-op on forward-slash paths) | All existing `validate_allowlist_entry_path` tests; gate output counts unchanged | pass |
| `validate_allowlist_entry_path` Windows-path normalization (LOW-002) | `test_validate_allowlist_entry_path_windows_separator` — 2 positive backslash cases return `Ok` (LOAD-BEARING: reverts to `is_err` if normalization removed); 1 negative control returns `is_err` (regression guard) | pass |
| MED-001 STATE.md checkpoint (records-only fix) | D-408 state-manager commit; no scanner logic change | pass |
| MED-002 / LOW-001 attestation corrections (records-only) | Prose corrections in CHANGELOG and evidence-report; no scanner logic change | pass |
| OBS-001 records-lint L13 parity check (devops-engineer extension) | Three self-probes validate false-green immunity; hook exit 0 on current STATE.md | pass |

**Gate output:** unchanged for POSIX inputs (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged from fix-burst-42. No new KL entries from these changes.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-42 re-verification

**Adversary pass 40 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 3 MED + 1 LOW findings.

All pass-40 findings closed. See CHANGELOG fix-burst-42 for details.

**Test count: 250 run: 250 passed, 5 skipped.**

**Clause (d) analysis:** fix-burst-42 changes `xtask/src/main.rs` (`check_file_size` loop: `name_n` normalization added to all four exclusion predicates) and `xtask/src/tests.rs` (discriminating test `test_scan_for_panics_violations_fixture_not_exempted_windows_path` added; `test_scan_for_panics_exempt_fixture_windows` renamed to `test_scan_for_panics_clean_source_windows_path_not_in_test_tree`). Clause (d) FIRES for the `main.rs` scanner change. The `name_n` normalization is a no-op on POSIX-path inputs (existing tests cover POSIX paths); the 1 new backslash discriminating test covers the regression path for the `scan_for_panics_in_source` fixture guard.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| `check_file_size` POSIX-path exclusion predicates (unchanged — `name_n` normalization is no-op on forward-slash paths) | All existing POSIX-path `check_file_size` tests; gate output counts unchanged | pass |
| `scan_for_panics_in_source` fixture guard — discriminating regression pin (MED-001) | `test_scan_for_panics_violations_fixture_not_exempted_windows_path` — NON-empty findings; LOAD-BEARING: FAILS if `normalized_path` reverts to raw `path` | pass |
| `scan_for_panics_in_source` renamed coverage test (MED-001) | `test_scan_for_panics_clean_source_windows_path_not_in_test_tree` — non-test-tree Windows path, clean source; asserts empty findings (unchanged coverage from renamed predecessor) | pass |

**Gate output:** unchanged for POSIX inputs (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**Updated KL table:** 10 rows, unchanged from fix-burst-41. No new KL entries.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-41 re-verification

**Adversary pass 39 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH before novelty assessment; adversary found 1 HIGH + 1 MED. Result: CLEAN(strict)=no, CLEAN(PR-merge)=no.

**Findings closed:** HIGH-001 (F-P39-HIGH-001) — path-separator normalization gap in exemption predicates closed with behavioral fix in `main.rs` and `check_no_panic.rs`, plus eight backslash-path test assertions. One additional function (`test_scan_for_panics_exempt_fixture_windows`) shipped non-load-bearing: the test path does not match any `is_test_file` predicate so `normalized_path` was never evaluated. That function was renamed and replaced with a discriminating pin in fix-burst-42 (F-P40-MED-001). MED-001 (F-P39-MED-001) — STATE.md checkpoint staleness fixed by state-manager (D-406).

**Test count: 249 run: 249 passed, 5 skipped.**

**Clause (d) analysis:** fix-burst-41 modifies `xtask/src/main.rs` (`is_test_file` and `is_test_class_file`) and `xtask/src/check_no_panic.rs` (`scan_for_panics_in_source`). Clause (d) fires for both files — per-detection-class re-verification required. The normalization change (`replace('\\', "/")`) is a no-op on POSIX strings containing only forward slashes; all existing gate tests on POSIX paths are unaffected. The 8 new backslash-path assertions extend the Windows-portability coverage. (One of the nine additions was renamed in fix-burst-42 and is no longer a Windows-portability assertion.)

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| `is_test_file` POSIX-path exemption (unchanged) | All existing POSIX-path cases in `test_is_test_file_patterns` — normalization is no-op on forward-slash paths; gate output counts unchanged | pass |
| `is_test_file` Windows-path normalization | Four positive backslash-path cases in `test_is_test_file_patterns` plus one negative control (`!is_test_file(r"crates\...\lib.rs")`) — LOAD-BEARING for the 4 positive cases: FAIL if normalization is removed; negative control passes under reversion and is a regression guard, not a reversion pin | pass |
| `is_test_class_file` Windows-path normalization | Two positive backslash-path cases in `test_is_test_class_file_patterns` plus one negative control: (1) `crates\pregolya-core\tests\integration.rs` (backslash `tests\` directory component → `contains("/tests/")` branch; LOAD-BEARING), (2) `crates\pregolya-core\src\tests.rs` (backslash `tests.rs` filename → `ends_with("/tests.rs")` branch; LOAD-BEARING), (3) negative control `crates\pregolya-core\src\lib.rs` → false (regression guard, passes under reversion). Note: `_test.rs` / `_tests.rs` suffix claim from the prior attestation was incorrect and is corrected here (LOW-001 F-P40-LOW-001) | pass |
| `scan_for_panics_in_source` fixture guard normalization | NOT load-bearing as shipped in fix-burst-41. Test path `xtask\src\fixtures\violations\test.rs` causes `is_test_file` to return false (no `/tests/` component, no `tests.rs` suffix match after normalization) — the `&&` short-circuits and `normalized_path` is never evaluated. Renamed to `test_scan_for_panics_clean_source_windows_path_not_in_test_tree` in fix-burst-42; discriminating regression pin `test_scan_for_panics_violations_fixture_not_exempted_windows_path` added (see fix-burst-42 F-P40-MED-001). | corrected (fix-burst-42) |

**Gate output:** unchanged for POSIX inputs (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions). Windows-backslash exemption paths now correctly handled via normalization.

**Updated KL table:** 10 rows, unchanged from fix-burst-40. The Windows-portability gap in `is_test_file`, `is_test_class_file`, and `scan_for_panics_in_source` was a defect, not a known limitation, and is now fully resolved; no new KL entries.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-40 re-verification

**Adversary pass 38 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 1 MED + 1 LOW + 1 OBS(process-gap).

All pass-38 findings closed. See CHANGELOG fix-burst-40 for details.

**Test count: 248 xtask tests pass, 5 skipped.**

**Clause-(d) analysis:** fix-burst-40 makes no changes to `xtask/src/**/*.rs` scanner logic. All changes are records-only (CHANGELOG corrections and evidence-report updates). Clause (d) does NOT fire.

**Per-detection-class attestation:**
- MED-001 (F-P38-MED-001): records corrections in CHANGELOG + STATE.md; no behavioral change.
- LOW-001 (F-P38-LOW-001): evidence-report/CHANGELOG OBS paragraph additions; no behavioral change.
- OBS-001 (F-P38-OBS-001): STATE.md OPEN SELF-IMPROVEMENT ITEMS update; no behavioral change.

**Gate output:** unchanged from fix-burst-39 (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged from fix-burst-39.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-39 re-verification

**Adversary pass 37 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 1 MED + 1 LOW + 2 OBS.

All pass-37 findings closed. See CHANGELOG fix-burst-39 for details.

**Test count: 248 xtask tests pass, 5 skipped.**

**Clause-(d) analysis:** fix-burst-39 LOW-001 modified a doc comment in `main.rs` — doc comment only, no scanner logic change. Clause (d) does NOT fire (doc comment changes are not behavioral changes to file-discovery or detection logic). Gate output counts remain valid.

**Per-detection-class attestation:**
- MED-001 (F-P37-MED-001): records-only (fix-burst-38 CHANGELOG + evidence-report sections added). No behavioral change.
- LOW-001 (F-P37-LOW-001): doc comment on `collect_rust_files` in `main.rs` updated. No behavioral change. No new tests (doc comment only).

**Gate output:** unchanged from fix-burst-38 (25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged from fix-burst-38.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-38 re-verification

**Adversary pass 36 result:** CLEAN(strict)=no, CLEAN(PR-merge)=yes — 0 CRIT + 0 HIGH + 0 MED + 1 LOW; RECORDS-ONLY per TD-RECORDS-MICRO-BURST-001.

All pass-36 findings closed. See CHANGELOG fix-burst-38 for details.

**Test count: 248 xtask tests pass, 5 skipped.**

**Clause-(d) analysis:** Records-only burst — no changes to `xtask/src/**/*.rs` scanner logic. Clause (d) does NOT fire. Gate output counts remain valid from fix-burst-37 re-verification.

**Per-detection-class attestation:**
- LOW-001 (F-P36-LOW-001): records-only text change in CHANGELOG fix-burst-36 MED-002 paragraph and story spec walkdir row. No behavioral change.

**Gate output:** unchanged from fix-burst-37 (all counts valid: 25 analyzed / 16 exempt / 0 violations per gate; 14/17 fixture-mode; 148 codes / 0 collisions).

**KL table:** 10 rows, unchanged from fix-burst-37.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-37 re-verification

**Adversary pass 35 result:** CLEAN(strict)=no, CLEAN(PR-merge)=yes — 0 CRIT + 0 HIGH + 1 MED + 1 LOW findings.

All pass-35 findings closed. See CHANGELOG fix-burst-37 for details.

**Test count: 248 xtask tests pass, 5 skipped.**

**Clause-(d) analysis:** fix-burst-37 LOW-001 added two negative-control test functions to `check_client_timeout.rs`. This is a test-only addition — no gate scanner logic changed. Gate output counts remain valid and unchanged (25 analyzed / 16 exempt / 0 violations per gate). Clause (d) does NOT fire (no scanner behavior changed; test additions to `check_client_timeout.rs` tests module are test-scope only).

**Per-detection-class attestation:**
- MED-001 (fix-burst-36 records added): records-only (CHANGELOG + evidence-report sections); no behavioral change.
- LOW-001 (bin/oct negative controls): `test_timeout_checker_bin_nonzero_literal_not_flagged` (binary `0b11110` NOT flagged; asserts `findings.is_empty()`; LOAD-BEARING) and `test_timeout_checker_oct_nonzero_literal_not_flagged` (octal `0o36` NOT flagged; asserts `findings.is_empty()`; LOAD-BEARING).

**Gate output (stable counts, unchanged from prior bursts):**

| Gate | Output |
|------|--------|
| check-no-panic | PASSED: 25 analyzed, 16 exempt, 0 violations |
| check-client-timeout | PASSED: 25 analyzed, 16 exempt, 0 violations |
| deny-bare-api-key | PASSED: 25 analyzed, 16 exempt, 0 violations |
| check-error-code-registry | PASSED: 148 codes validated, 0 collisions |
| deny-anyhow-in-lib | PASSED: 25 analyzed, 16 exempt, 0 violations |
| deny-description-cache-key | PASSED: 25 analyzed, 16 exempt, 0 violations |
| check-file-size | PASSED (2 warnings, 45 files measured, 2 allowlisted) |
| check-no-panic --fixture-mode | fixture-mode: 14/17 fixture files had findings |

**Updated KL table:** 10-row table — same as fix-burst-36. No new entries.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED in fix-burst-26** | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-36 re-verification

**Adversary pass 34 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 3 MED + 2 LOW + 1 OBS findings.

All pass-34 findings closed. See CHANGELOG fix-burst-36 for details.

**Test count: 246 xtask tests pass, 5 skipped.**

**Clause-(d) analysis:** fix-burst-36 OBS-001 (`INT_SUFFIXES` hoist) is a scanner-infrastructure refactor — behavior-preserving (no detection logic changed, only constant declaration site changed). Gate output counts remain valid (25 analyzed / 16 exempt / 0 violations per gate). Clause (d) fires for the scanner refactor; gate counts verified as unchanged from fix-burst-35.

Note: `INT_SUFFIXES` is now a single module-level const shared by the hex/bin/oct paths of `is_zero_literal`, superseding the "per-radix `INT_SUFFIXES`" phrasing in the fix-burst-35 LOW-001 note. The fix-burst-34 longest-first ordering invariant applies to this single shared const.

**Per-detection-class attestation:**
- MED-001/002/003 (story spec): records-only (Purity Classification text, Library Requirements table row, frontmatter VP list). No behavioral change in gates.
- LOW-001 (STATE.md D-398): records-only (symbol name correction in factory-artifacts).
- LOW-002 (CHANGELOG): records-only (constant rename note appended).
- OBS-001 (`INT_SUFFIXES` hoist): load-bearing behavioral change — `test_timeout_checker_bin_zero_literal_flagged` (binary zero is flagged; asserts `!findings.is_empty()`; LOAD-BEARING) and `test_timeout_checker_oct_zero_literal_flagged` (octal zero is flagged; same assertion; LOAD-BEARING).

**Gate output (stable counts, unchanged from prior bursts):**

| Gate | Output |
|------|--------|
| `check-no-panic` | PASSED: 25 analyzed, 16 exempt, 0 violations |
| `check-client-timeout` | PASSED: 25 analyzed, 16 exempt, 0 violations |
| `deny-bare-api-key` | PASSED: 25 analyzed, 16 exempt, 0 violations |
| `check-error-code-registry` | PASSED: 148 codes validated, 0 collisions |
| `deny-anyhow-in-lib` | PASSED: 25 analyzed, 16 exempt, 0 violations |
| `deny-description-cache-key` | PASSED: 25 analyzed, 16 exempt, 0 violations |
| `check-file-size` | PASSED (2 warnings, 45 files measured, 2 allowlisted) |
| `check-no-panic --fixture-mode` | fixture-mode: 14/17 fixture files had findings |

**Updated KL table:** 10-row table (CT-KL-1/2/3/4RETIRED/5/macro, NP-KL-1/2RESOLVED/3, BAK-KL-1) — same as fix-burst-35.

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED in fix-burst-26** | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

---

## fix-burst-35 re-verification

**Adversary pass 33 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 0 HIGH + 3 MED + 3 LOW + 1 OBS findings.

All pass-33 findings closed. See CHANGELOG fix-burst-35 for details.

**Test count: 244 xtask tests pass, 5 skipped.**

**Gate output (stable counts, unchanged from prior bursts):**

| Gate | Output |
|------|--------|
| `check-no-panic` | PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations |
| `check-client-timeout` | PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations |
| `deny-bare-api-key` | PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations |
| `check-error-code-registry` | PASSED: 148 codes validated, 0 collisions |
| `deny-anyhow-in-lib` | PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations |
| `deny-description-cache-key` | PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations |
| `check-file-size` | PASSED (2 warnings, 45 files measured, 2 allowlisted) |
| `check-no-panic --fixture-mode` | fixture-mode: 14/17 fixture files had findings |

**Per-detection-class attestation:**

- MED-001 (`{PC-001}` re-citation): behavioral anchor correction only — text change, no load-bearing test needed
- MED-002 (`walkdir` portability): behavioral change in file-discovery path (`collect_rust_files()` helper replaces `Command::new("find")`); gate output counts unchanged (25 analyzed / 16 exempt / 0 violations per scanning gate)
- MED-003 (clause (d) re-attestation): gate output recorded (see gate output table above); SHA-pin removed by TD-VSDD-091 sweep
- LOW-001 (hex radix fix): `test_timeout_checker_hex_literal_with_f64_suffix_not_zero` — NOT flagged (non-zero hex with `f64` suffix; LOAD-BEARING: fails without radix-first fix); `test_timeout_checker_hex_zero_literal_flagged` — flagged (hex zero still detected; negative control)
- LOW-002 (doc-comment count fix): `test_no_panic_tokio_test_attr_fn_exempt` and `test_no_panic_cfg_test_item_trait_exempt` doc-comments corrected; no behavioral change
- LOW-003 (cross-reference label fix): records-only; no behavioral change
- OBS-001: process gap — orchestrator follow-up required

**Clause-(d) analysis:** MED-002 (`walkdir` refactor) is a scanner-infrastructure change — clause (d) fires; gate output counts unchanged (25 analyzed / 16 exempt / 0 violations per gate output table above). Gate counts recorded by gate name and count value without SHA pins (per updated Recording Provenance clause (d)).

**Updated known limitations (10 entries, same as fix-burst-34):**

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED in fix-burst-26** | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

No new KL entries. `walkdir` portability fix (MED-002) closes the Windows-portability gap — not a KL, fully resolved.

---

## fix-burst-34 re-verification

**Adversary pass 32 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 1 HIGH + 2 MED + 1 LOW + 1 OBS findings.

**Clause (d) analysis:** Fix-burst-34 modifies `xtask/src/check_no_panic.rs` and `xtask/src/check_client_timeout.rs` (both gained `visit_item_trait` override). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| HIGH-001 KL registry restore | `NP-KL-1` and `BAK-KL-1` corrected in CHANGELOG and evidence-report — records fix, no new tests |
| MED-001 `#[cfg(test)]` ItemTrait guard — `check_no_panic` | `test_no_panic_cfg_test_item_trait_exempt` — EXEMPT (load-bearing: fails without `visit_item_trait` guard in `PanicVisitor`) | pass |
| MED-001 `#[cfg(test)]` ItemTrait guard — `check_client_timeout` | `test_timeout_checker_cfg_test_item_trait_exempt` — EXEMPT (load-bearing: fails without `visit_item_trait` guard in `TimeoutChecker`) | pass |
| MED-002 story spec correction | Three sites amended in story spec, v1.18 (on factory-artifacts) — spec-only fix, no new gate tests |
| LOW-001 `TYPE_SUFFIXES` reorder | Reordered longest-first in `is_zero_literal` — ordering fix, no new tests |
| OBS-001 process gap | Partially addressed by HIGH-001 restore; orchestrator cycle-closing checklist follow-up required |

Total: 242 xtask tests pass, 5 skipped.

**Gate output re-attestation (clause (d) — behavioral scanner changes):** `visit_item_trait` added to both `PanicVisitor` and `TimeoutChecker`. Gate output re-recorded at fix-burst-33 baseline — counts unchanged (25 analyzed, 16 exempt, 0 violations for all scanning gates). No `crates/`-rooted production files changed in fix-burst-34; all 8 gate counts remain identical to the baseline recorded in the fix-burst-32 re-verification.

| Gate | Stdout output |
|------|--------------|
| `check-no-panic` | `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `check-client-timeout` | `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `deny-bare-api-key` | `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `check-error-code-registry` | `error-code-registry PASSED: 148 codes validated, 0 collisions.` |
| `deny-anyhow-in-lib` | `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `deny-description-cache-key` | `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `check-file-size` | `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).` |
| `check-no-panic --fixture-mode xtask/tests/fixtures/violations` | `fixture-mode: 14/17 fixture files had findings` |

**Updated known limitations:**

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED in fix-burst-26** | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

**Docs-only note:** This fix-burst-34 CHANGELOG and evidence-report docs commit is docs-only for the evidence-report portion — the technical-writer KL restore is records-tier content in documentation files only. The behavioral scanner changes are in the implementer and test-writer commits for fix-burst-34.

---

## fix-burst-33 re-verification

**Adversary pass 31 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 HIGH + 2 MED + 1 LOW + 1 OBS findings.

**Clause (d) analysis:** Fix-burst-33 modifies `xtask/src/check_no_panic.rs` (three function visitors gained last-path-segment `test` guard; `NP-KL-3` minted in module doc) and adds tests to `xtask/src/tests.rs`. Clause (d) fires for `check_no_panic.rs` scanner logic changes — per-detection-class test attestation required.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| MED-001 `#[test]`-family guard — `visit_item_fn` / `visit_impl_item_fn` / `visit_trait_item_fn` | `test_no_panic_tokio_test_attr_fn_exempt` — EXEMPT (load-bearing: fails without guard) | pass |
| MED-002 NP-KL-3 path-call form pin | `test_no_panic_np_kl3_path_call_form_known_gap` — 0 findings (known gap, `ExprCall` path-call form not detected without type inference) | pass |

Total: 240 xtask tests pass, 5 skipped.

**Gate output (2026-09-23):**

| Gate | Stdout output |
|------|--------------|
| `check-no-panic` | `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `check-client-timeout` | `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `deny-bare-api-key` | `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `check-error-code-registry` | `error-code-registry PASSED: 148 codes validated, 0 collisions.` |
| `deny-anyhow-in-lib` | `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `deny-description-cache-key` | `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` |
| `check-file-size` | `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).` |
| `check-no-panic --fixture-mode xtask/tests/fixtures/violations` | `fixture-mode: 14/17 fixture files had findings` |

**Clause-(d) coverage summary:**
- MED-001: load-bearing test `test_no_panic_tokio_test_attr_fn_exempt` (fails without the last-path-segment guard in all three function visitors)
- MED-002: pinning test `test_no_panic_np_kl3_path_call_form_known_gap` pins zero-finding behavior for known-gap path-call form; any "fix" introducing false positives will break this test
- LOW-001: gate output re-attestation — all 8 gates re-run; clause (d) satisfied
- OBS-001: process gap — the dispatch prompt's mislabelled KL descriptions were NOT the cause of the artifact content (those descriptions were independently set by the technical-writer for fix-burst-33); the KL table descriptions in fix-burst-33 require correction per F-P32-HIGH-001

**Updated known limitations:**

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED in fix-burst-26** | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic (cfg(test), `# Panics` doc, arm-context) not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Turbofish comma miscounting — angle-bracket depth tracking + turbofish-vs-comparison disambiguation; `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` is the mechanism pin |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

**Docs-only note:** This fix-burst-33 CHANGELOG and evidence-report docs commit is docs-only — no `xtask/src/**/*.rs` scanner logic changes beyond those already in the fix-burst-33 code commits. Clause (d) does not fire for the docs commit itself.

---

## fix-burst-32 re-verification

**Adversary pass 30 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 HIGH + 2 MED + 1 LOW findings.

**Clause (d) analysis:** `check_no_panic` was modified (two new load-bearing tests added; doc comment on `test_no_panic_exemption2_bc_id_with_turbofish_condition` corrected). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| `angle_depth` mechanism positive — Exemption-2 fires with multi-arg turbofish (MED-002) | `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_exempt` — EXEMPT, zero findings | pass |
| `angle_depth` mechanism load-bearing pin — without `angle_depth` counter, returns EXEMPT instead of FLAGGED (MED-002) | `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` — FLAGGED, 1 finding; test FAILS if `angle_depth` tracking is removed | pass |
| BC-2.14.003 amendment (MED-001) | BC spec change only (v1.6), no new gate behavior, no new test required | pass |

Total: 238 xtask tests pass, 5 skipped.

**Clause-(d) coverage summary:**
- MED-001: BC-2.14.003 amended by product-owner (v1.6) to enumerate all three test-code contexts; no behavioral change to gate
- MED-002: two load-bearing tests added; `NP-KL-2` **CONFIRMED RESOLVED** — `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` is the mechanism pin for the `angle_depth` counter
- LOW-001: CT-KL-4 RETIRED row added to evidence-report fix-burst-31 KL table (records-only fix)

**Updated known limitations (namespaced IDs):**

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED in fix-burst-26** | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32) | Turbofish comma miscounting — angle-bracket depth tracking + turbofish-vs-comparison disambiguation; `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` is the mechanism pin |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |
| NP-KL-3 | `check-no-panic` | **DOCUMENTED in fix-burst-33** | Path-call form `Result::unwrap(r)` — see fix-burst-33 |

**Docs-only note:** The docs commit for this fix-burst-32 CHANGELOG and evidence-report update is docs-only — no `xtask/src/**/*.rs` behavioral changes. Clause (d) does not fire for the docs commit.

---

## fix-burst-31 re-verification

**Adversary pass 29 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 3 MED + 1 LOW findings.

**Clause (d) analysis:** `check_no_panic` was modified (`syn_macro_has_bc_id` turbofish-vs-comparison disambiguation — `<` is now treated as a turbofish opener only when preceded by `::`; `Spacing` imported alongside `TokenTree`). Three new pinning tests added in test-writer commit. Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| Pattern A — direct `Client::new` / `Client::default` construction | `test_timeout_scanner_still_flags_reqwest_client_new`, `test_timeout_checker_detects_client_default_qualified` | pass |
| Pattern A — UFCS `<reqwest::Client as Default>::default()` (qself) | `test_timeout_checker_detects_client_ufcs_default_qualified` (positive), `test_timeout_checker_ufcs_non_reqwest_client_as_default_clean` (negative) | pass |
| Pattern A — UFCS `<reqwest::Client>::new()` (qself) | `test_timeout_checker_detects_client_ufcs_new_qualified` | pass |
| Pattern B — builder chain via `analyze_build_chain` | `test_timeout_scanner_flags_builder_build_without_timeout_single_line`, `test_timeout_checker_detects_builder_default_qualified` | pass |
| Macro scanning — `scan_macro_body_as_ast` Strategy 1 | `test_timeout_checker_detects_reqwest_client_in_thread_local` | pass |
| Macro scanning — `scan_macro_body_as_ast` Strategy 2 | `test_timeout_checker_strategy2_detects_statement_macro_violation` | pass |
| Macro scanning — `scan_macro_body_as_ast` Strategy 3 | `test_timeout_checker_detects_builder_in_lazy_static` | pass |
| `#[cfg(test)]` stmt macro exempt — `check_client_timeout` | `test_timeout_checker_cfg_test_stmt_macro_not_flagged` | pass |
| `#[cfg(test)]` stmt macro exempt — `check_no_panic` | `test_no_panic_cfg_test_stmt_macro_not_flagged` | pass |
| Exemption-2 BC-ID detection (turbofish condition) | `test_no_panic_exemption2_bc_id_with_turbofish_condition` — EXEMPT, zero findings | pass |
| Exemption-2 BC-ID detection (comparison condition, HIGH-001 regression) | `test_no_panic_exemption2_bc_id_with_comparison_condition` — EXEMPT, zero findings | pass |
| Exemption-2 BC-ID negative control | `test_no_panic_comparison_condition_no_bc_id_flagged` — FLAGGED, 1 finding | pass |
| Test context suppression | `test_timeout_checker_ignores_tokio_test_fns`, `test_timeout_checker_ignores_cfg_test_trait_default_method` | pass |

Total: 236 xtask tests pass, 5 skipped.

**Clause-(d) coverage summary:**
- HIGH-001: load-bearing test `test_no_panic_exemption2_bc_id_with_comparison_condition`
- MED-001: three tests close the paper-fix; `NP-KL-2` confirmed RESOLVED; `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` (added fix-burst-32) is the mechanism pin for the `angle_depth` counter
- MED-002: BC amendment (v1.16), no code test needed (spec corrected to match code)
- MED-003: doc rename across 4 files; grepped clean (zero `KNOWN-LIMITATION` in source)
- LOW-001: defense-in-depth annotation; no test (stable Rust cannot express `#[cfg(test)]` on expr-position macro)

**Updated known limitations (namespaced IDs):**

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED in fix-burst-26** | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Turbofish comma miscounting — angle-bracket depth tracking + turbofish-vs-comparison disambiguation; `test_no_panic_exemption2_bc_id_with_turbofish_condition` and `test_no_panic_exemption2_bc_id_with_comparison_condition` validate the resolution |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |

**Docs-only note:** The docs commit for this fix-burst-31 CHANGELOG and evidence-report update is docs-only — no `xtask/src/**/*.rs` behavioral changes. Clause (d) does not fire for the docs commit.

---

## fix-burst-30 re-verification

**Adversary pass 28 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 4 MED + 4 LOW findings.

**Clause (d) analysis:** `check_client_timeout` and `check_no_panic` were modified (`has_cfg_test_attr` / `syn_has_cfg_test` guards added to `visit_expr_macro` and `visit_stmt_macro`; dead `"builder"` arm removed from Pattern-A UFCS qself branch in `visit_expr_call`; angle-bracket depth tracking added to `syn_macro_has_bc_id`). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| Pattern A — direct `Client::new` / `Client::default` construction | `test_timeout_scanner_still_flags_reqwest_client_new`, `test_timeout_checker_detects_client_default_qualified` | pass |
| Pattern A — UFCS `<reqwest::Client as Default>::default()` (qself) | `test_timeout_checker_detects_client_ufcs_default_qualified` (positive), `test_timeout_checker_ufcs_non_reqwest_client_as_default_clean` (negative) | pass |
| Pattern A — UFCS `<reqwest::Client>::new()` (qself) | `test_timeout_checker_detects_client_ufcs_new_qualified` | pass |
| Pattern B — builder chain via `analyze_build_chain` | `test_timeout_scanner_flags_builder_build_without_timeout_single_line`, `test_timeout_checker_detects_builder_default_qualified` | pass |
| Macro scanning — `scan_macro_body_as_ast` Strategy 1 | `test_timeout_checker_detects_reqwest_client_in_thread_local` | pass |
| Macro scanning — `scan_macro_body_as_ast` Strategy 2 positive detection | `test_timeout_checker_strategy2_detects_statement_macro_violation` | pass |
| Macro scanning — `scan_macro_body_as_ast` Strategy 3 | `test_timeout_checker_detects_builder_in_lazy_static` | pass |
| `#[cfg(test)]` stmt macro exempt — `check_client_timeout` | `test_timeout_checker_cfg_test_stmt_macro_not_flagged` | pass |
| `#[cfg(test)]` stmt macro exempt — `check_no_panic` | `test_no_panic_cfg_test_stmt_macro_not_flagged` | pass |
| Known-limitation pinning — CT-KL-macro (opaque macro body) | `test_timeout_checker_unparseable_macro_body_known_limitation` | pass |
| Test context suppression | `test_timeout_checker_ignores_tokio_test_fns`, `test_timeout_checker_ignores_cfg_test_trait_default_method` | pass |

Total: 233 xtask tests pass, 5 skipped.

**Updated known limitations (namespaced IDs):**

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **RESOLVED in fix-burst-30** | Turbofish comma miscounting — angle-bracket depth tracking implemented in `syn_macro_has_bc_id` |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |

**Clause-(d) coverage summary:** All HIGH and MED findings closed with load-bearing tests. LOW findings: LOW-001 closed with doc expansion (three doc sites updated); LOW-002 closed with `test_timeout_checker_unparseable_macro_body_known_limitation`; LOW-003 closed with doc correction (fix-burst-29 `F-P27-MED-002` attribution "Six" → "Four"); LOW-004 closed by product-owner BC amendment (BC-2.14.004 v1.15).

**Docs-only note:** The docs commit for this fix-burst-30 CHANGELOG and evidence-report update is docs-only — no `xtask/src/**/*.rs` behavioral changes. Clause (d) does not fire for the docs commit.

---

## fix-burst-29 re-verification

**Clause (d) analysis:** `check_client_timeout.rs` was modified (UFCS qself extended; Strategy 3 removed; module doc and KL sections updated; two test renames). `tests.rs` was modified (new UFCS tests added; test renames). Clause (d) fires.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| Pattern A — `Client::new` | `test_timeout_scanner_still_flags_reqwest_client_new` | pass |
| Pattern A — `Client::default` (plain path) | `test_timeout_checker_detects_client_default_qualified` | pass |
| Pattern A — UFCS `<reqwest::Client as Default>::default()` (qself) | `test_timeout_checker_detects_client_ufcs_default_qualified` | pass |
| Pattern A — UFCS `<reqwest::Client>::new()` | `test_timeout_checker_detects_client_ufcs_new_qualified` | pass |
| Pattern B — builder chain `analyze_build_chain` | `test_timeout_scanner_flags_builder_build_without_timeout_single_line` | pass |
| Pattern B — UFCS `<reqwest::ClientBuilder as Default>::default()` | `test_timeout_checker_detects_clientbuilder_ufcs_default_no_timeout` | pass |
| Pattern B — UFCS `<reqwest::ClientBuilder>::new()` | `test_timeout_checker_detects_clientbuilder_ufcs_new_no_timeout` | pass |
| Pattern B — UFCS `<reqwest::Client>::builder()` | `test_timeout_checker_detects_client_ufcs_builder_no_timeout` | pass |
| Macro scanning — `scan_macro_body_as_ast` (3 strategies) | `test_timeout_checker_detects_reqwest_client_in_thread_local`, `test_timeout_checker_detects_builder_in_lazy_static` | pass |
| Test context suppression | `test_timeout_checker_ignores_tokio_test_fns`, `test_timeout_checker_ignores_cfg_test_trait_default_method` | pass |
| Known-limitation pinning (KL-1, KL-2, KL-5) | `test_timeout_checker_detects_client_default_bare`, `test_timeout_scanner_split_statement_false_negative_known_limitation`, `test_timeout_checker_module_alias_false_negative_known_limitation` | pass |

Total: 229 xtask tests pass (approximately 320 workspace-wide per pre-push hook). 5 skipped.

**Known limitations after fix-burst-29:** KL-1 (bare name via use import — conservative false positive), KL-2 (split-statement builder chains), KL-3 (constant-valued ZERO), KL-macro (macro bodies failing all three parse strategies), KL-5 (module-alias re-export false negative).

**Docs-only note:** The docs commit following the fix-burst-29 code commits (adding this CHANGELOG + evidence-report section) is docs-only — no `xtask/src/**/*.rs` behavioral changes. Clause (d) does not fire for the docs commit.

---

## fix-burst-28 re-verification

**Clause (d) analysis:** `check_client_timeout.rs` was modified (new `scan_macro_body_as_ast` function replacing flat-token `scan_macro_tokens_for_timeout_violations`; `analyze_build_chain` extended for UFCS `ClientBuilder` qself; `visit_trait_item_fn` added; module docs updated; KNOWN-LIMITATION 1 and 4 updated). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| Pattern A — direct `Client::new` / `Client::default` construction | `test_timeout_scanner_still_flags_reqwest_client_new`, `test_timeout_checker_detects_client_default_qualified` | pass |
| Pattern A — UFCS `<reqwest::Client as Default>::default()` (qself) | `test_timeout_checker_detects_client_ufcs_default_qualified` (positive), `test_timeout_checker_ufcs_non_reqwest_client_as_default_clean` (negative) | pass |
| Pattern B — builder chain via `analyze_build_chain` | `test_timeout_scanner_flags_builder_build_without_timeout_single_line`, `test_timeout_checker_detects_builder_default_qualified` | pass |
| Pattern B — UFCS `<reqwest::ClientBuilder as Default>::default()` | `test_timeout_checker_detects_clientbuilder_ufcs_default_no_timeout` | pass |
| Macro scanning — recursive AST via `scan_macro_body_as_ast` | `test_timeout_checker_detects_reqwest_client_in_thread_local`, `test_timeout_checker_detects_builder_in_lazy_static`, `test_timeout_checker_macro_nested_config_timeout_suppressed_violation` | pass |
| Macro negative — `Client::builder().timeout().build()` in lazy_static | `test_timeout_checker_macro_client_builder_with_timeout_in_lazy_static` | pass |
| Test context suppression (including `#[tokio::test]`, trait `#[cfg(test)]`) | `test_timeout_checker_ignores_tokio_test_fns`, `test_timeout_checker_ignores_cfg_test_trait_default_method` | pass |
| Monotonic-OR / zero-timeout semantics | `test_timeout_checker_last_zero_timeout_overrides_valid` | pass |

All 222 xtask tests pass (314 workspace-wide per pre-push hook). 5 skipped (pre-existing `#[ignore]` tests requiring live API keys).

**Known limitations after fix-burst-28:** KL-1 (bare name via use import), KL-2 (split-statement builder chains), KL-3 (constant-valued ZERO timeout), KL-macro (macro bodies failing all four parse strategies skipped).

**Docs-only note:** The docs commit that follows the fix-burst-28 code commit is docs-only — no `xtask/src/**/*.rs` files changed, no fixture directory changes, no `CREDENTIAL_FIXTURE_COUNT` changed. Clause (d) does not fire for the docs commit.

**Note:** the Pattern-A UFCS (`<reqwest::Client as Default>::default()`) test was added in fix-burst-29 (`test_timeout_checker_detects_client_ufcs_default_qualified`); this attestation row has been back-corrected to reference the load-bearing test.

---

## fix-burst-27 re-verification

**Clause (d) analysis:** `check_client_timeout.rs` was modified (new `visit_expr_macro`/`visit_stmt_macro`/`visit_item_macro` methods, `scan_macro_tokens_for_timeout_violations` function, `classify_client_new` and `classify_builder_constructor` extended, `analyze_build_chain` OBS-001 fix). Evidence-report validity requires per-detection-class test attestation for scanner logic changes.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| Pattern A — direct `Client::new` / `Client::builder` | `test_timeout_scanner_still_flags_reqwest_client_new`, `test_timeout_scanner_flags_clientbuilder_new_without_timeout` | 8/8 |
| Pattern A — `Client::default` / UFCS | `test_timeout_checker_detects_client_default_qualified`, `test_timeout_checker_detects_client_default_bare` | 4/4 |
| Pattern B — builder chain via `analyze_build_chain` | `test_timeout_scanner_flags_builder_build_without_timeout_single_line`, `test_timeout_scanner_does_not_flag_builder_with_timeout` | 10/10 |
| Macro scanning — `scan_macro_tokens_for_timeout_violations` | `test_timeout_checker_detects_reqwest_client_in_thread_local`, `test_timeout_checker_detects_builder_in_lazy_static`, `test_timeout_checker_detects_builder_with_timeout_in_lazy_static` | 3/3 |
| Test context suppression (including `#[tokio::test]`) | `test_timeout_checker_ignores_tokio_test_fns` | 5/5 |
| Monotonic-OR / zero-timeout semantics | `test_timeout_checker_last_zero_timeout_overrides_valid` | 2/2 |

Total: 309 pass, 7 skipped (pre-existing `#[ignore]` tests requiring live API keys).

**Known limitations after fix-burst-27:** KL-1 (bare name via use import), KL-2 (split-statement builder chains), KL-3 (constant-valued ZERO timeout), KL-macro (best-effort flat-token macro scanning for complex nested bodies).

**Docs-only note:** The CHANGELOG and evidence-report update commit that follows the fix-burst-27 code commit is docs-only — no `xtask/src/**/*.rs` files changed, no fixture directory changes, no `CREDENTIAL_FIXTURE_COUNT` changed. Clause (d) does not fire for the docs commit.

---

## Notes

- All recordings produced with VHS 0.11.0 using `FiraCode Nerd Font Mono`, Catppuccin Mocha theme, 1200×600 or 1200×700 resolution.
- `Wait+Screen /pattern/` used for the xtask gate commands; `Sleep 20s` used for the nextest run (command completes in ~2s warm, Sleep provides buffer for cold environments).
- `Wait+Line` is NOT used — VHS 0.11.0 shows zsh prompt `>` as last line after command completion, preventing Last-Line pattern matching.
- AC-007, AC-009, AC-013 have no runtime demo — these are compile-time `static_assertions` enforced by the Rust type system at `cargo build` time.
- WebM files are primary format (better compression); GIF files are included for inline PR embedding.
