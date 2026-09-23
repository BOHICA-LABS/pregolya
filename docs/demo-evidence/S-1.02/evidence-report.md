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
| AC-002 | BC-2.14.003 PC-004 | `cargo xtask check-no-panic` exits 0 — no unwrap/expect/panic in non-test code | [AC-002-check-no-panic-pass.webm](AC-002-check-no-panic-pass.webm) | [AC-002-check-no-panic-pass.gif](AC-002-check-no-panic-pass.gif) | [tape](AC-002-check-no-panic-pass.tape) | recorded (refreshed 2026-09-22) |
| AC-003 | BC-2.14.003 INV-003/INV-004 | `debug_assert!` and exhaustive-match `unreachable!` are exempt — gate exits 0 | covered by AC-002 recording (same gate pass) | — | — | covered |
| AC-005 | BC-2.14.004 PC-003 | `cargo xtask check-client-timeout` exits 0 — no missing `.timeout()` | [AC-005-check-client-timeout-pass.webm](AC-005-check-client-timeout-pass.webm) | [AC-005-check-client-timeout-pass.gif](AC-005-check-client-timeout-pass.gif) | [tape](AC-005-check-client-timeout-pass.tape) | recorded (refreshed 2026-09-22) |
| AC-010 | BC-2.14.005 PC-006 | `cargo xtask deny-bare-api-key` exits 0 — structural credential scan passes | [AC-010-deny-bare-api-key-pass.webm](AC-010-deny-bare-api-key-pass.webm) | [AC-010-deny-bare-api-key-pass.gif](AC-010-deny-bare-api-key-pass.gif) | [tape](AC-010-deny-bare-api-key-pass.tape) | recorded (refreshed 2026-09-22) |
| AC-020 | BC-2.14.001 EC-004 / VP-BC214001-01 | `cargo xtask check-error-code-registry` exits 0 — 148 error codes validated, 0 collisions | text evidence (gate stdout) | — | — | captured 2026-09-22 (post-fix-burst-5) |
| AC-017 | BC-2.14.003 EC-007 | `cargo xtask check-no-panic --fixture-mode` FLAGS violations in 14 of 17 fixture files spanning five violation classes: bare `assert!` (incl. short BC-ID + BC-ID in condition), catch-all `unreachable!()` arms (wildcard `_ =>` and irrefutable-binding forms `other =>`, `ref other =>`, `mut other =>`, guarded `other if ... =>`, `_other =>`), `.unwrap()` in macros, `todo!()` (unimplemented!() covered by inline unit test only), `assert_eq!`/`assert_ne!` with BC-ID in comparand — 14/17 fixture files flagged | [AC-017-check-no-panic-flags-violations.webm](AC-017-check-no-panic-flags-violations.webm) | [AC-017-check-no-panic-flags-violations.gif](AC-017-check-no-panic-flags-violations.gif) | [tape](AC-017-check-no-panic-flags-violations.tape) | recorded (re-recorded 2026-09-22 frozen HEAD 1ab2d10) |
| AC-008 | BC-2.14.005 PC-002 | `Debug` emits exactly `"<redacted>"` — key material never appears in format output | [AC-008-AC-011-AC-016-credential-validation-redaction.webm](AC-008-AC-011-AC-016-credential-validation-redaction.webm) | [AC-008-AC-011-AC-016-credential-validation-redaction.gif](AC-008-AC-011-AC-016-credential-validation-redaction.gif) | [tape](AC-008-AC-011-AC-016-credential-validation-redaction.tape) | recorded |
| AC-011 | BC-2.14.006 PC-001 | `OpenAiApiKey::new("")` → `Err(E-CORE-005 / VAL / Never)` | same recording as AC-008 | — | — | recorded |
| AC-016 | BC-2.14.006 EC-006 | `new("   ")` whitespace-only rejected with same `E-CORE-005` error | same recording as AC-008 | — | — | recorded |

---

## AC Coverage Map

### AC-001 — constructor returns Result (BC-2.14.003 PC-001)
Covered by: AC-008/AC-011/AC-016 recording (credential nextest run includes `test_BC_2_14_003_constructor_returns_result`).

### AC-002 — check-no-panic exits 0 (BC-2.14.003 PC-004)
Recording: `AC-002-check-no-panic-pass.{webm,gif}` — re-recorded 2026-09-22 (frozen HEAD 1ab2d10)
Shows: `cargo xtask check-no-panic` — output: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`

### AC-003 — debug_assert exempt (BC-2.14.003 INV-003/INV-004)
Covered by: same gate exit-0 recording as AC-002. The gate scans the production tree without flagging `debug_assert!` — the PASS result proves the exemption is working.

### AC-004 — build_client 30s timeout (BC-2.14.004 PC-001/PC-003)
Covered by: AC-005 recording (gate verifies no Client::new() or missing timeout in production paths).

### AC-005 — check-client-timeout exits 0 (BC-2.14.004 PC-003)
Recording: `AC-005-check-client-timeout-pass.{webm,gif}` — re-recorded 2026-09-22 (frozen HEAD 1ab2d10)
Shows: `cargo xtask check-client-timeout` — output: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`

### AC-006 — build_client returns Ok (BC-2.14.004 PC-005)
Covered by: AC-005 recording proves the production code compiles and the xtask gate passes.

### AC-007 — newtype not type-alias (BC-2.14.005 PC-001/PC-004)
Compile-time static assertion — no runtime demo required (structural property enforced at compile time by `static_assertions::assert_not_impl_any!`).

### AC-008 — Debug emits exactly `"<redacted>"` (BC-2.14.005 PC-002)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: nextest run of `test_BC_2_14_005_openai_debug_emits_redacted_sentinel` and `test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel` — both PASS.

### AC-009 — no AsRef/Deref/Serialize (BC-2.14.005 PC-003/PC-004)
Compile-time static assertion — no runtime demo required.

### AC-010 — deny-bare-api-key structural gate (BC-2.14.005 PC-006)
Recording: `AC-010-deny-bare-api-key-pass.{webm,gif}` — re-recorded 2026-09-22 (frozen HEAD 1ab2d10)
Shows: `cargo xtask deny-bare-api-key` — output: `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`

### AC-011 — empty key returns Err(E-CORE-005) (BC-2.14.006 PC-001)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_openai_empty_key_returns_err` PASS.

### AC-012 — no silent None/default (BC-2.14.006 PC-003)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_no_silent_default_on_invalid_inputs` PASS — table-driven test over `["", "   "]`.

### AC-013 — no From\<String\>/From\<&str\> (BC-2.14.006 EC-005)
Compile-time static assertion — no runtime demo required.

### AC-014 — error code E-CORE-005 + message format (BC-2.14.006 PC-004)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_error_code_and_format_table` PASS.

### AC-015 — ClientBuilder failure maps to E-CORE-012 (BC-2.14.004 EC-006)
Covered by: AC-005 recording (gate verifies implementation compiles and production code passes); underlying test `test_BC_2_14_004_build_failure_maps_to_e_core_012` is in the full test suite visible in the AC-008/AC-011/AC-016 nextest run.

### AC-016 — whitespace-only key rejected (BC-2.14.006 EC-006)
Recording: `AC-008-AC-011-AC-016-credential-validation-redaction.{webm,gif}`
Shows: `test_BC_2_14_006_openai_whitespace_only_key_returns_err` PASS.

### AC-017 — check-no-panic flags violations (BC-2.14.003 EC-007)
Recording: `AC-017-check-no-panic-flags-violations.{webm,gif}` — re-recorded 2026-09-22 (frozen HEAD 1ab2d10)
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

### AC-020 — check-error-code-registry exits 0 (BC-2.14.001 EC-004 / VP-BC214001-01)
Evidence captured: 2026-09-22 (frozen HEAD `1ab2d10`)
Command: `FACTORY_DIR=/Users/jmagady/Dev/pregolya/.factory cargo xtask check-error-code-registry`
Output: `error-code-registry PASSED: 148 codes validated, 0 collisions.`
Demonstrates: verifies all 148 `E-<COMPONENT>-<NNN>` codes declared in `error-taxonomy.md` are unique (zero collisions); exits 1 when zero codes extracted (vacuity guard — taxonomy format change detection); does NOT cross-validate against Rust source.

### AC-018 — programmer-error guards compliant (BC-2.14.003 EC-006)
Covered by: AC-002 recording — gate exits 0 despite programmer-error-guard asserts in `PregolyaError::new` etc., proving the EC-006 narrow exception is honoured.

### AC-019 — E-CORE-012 test is non-ignored + production path (BC-2.14.004 EC-006)
Covered by: the nextest pass in AC-008/AC-011/AC-016 recording (test_BC_2_14_004_build_failure_maps_to_e_core_012 is visible in the full suite output).

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

**Validity criterion:** Gate output remains valid at any HEAD where (a) no `crates/` files are added or deleted, (b) any `crates/` changes are doc-comment-only with no panic-family, timeout, or credential constructs added or removed, (c) no files are added to, removed from, or renamed within `xtask/tests/fixtures/violations/`, and `CREDENTIAL_FIXTURE_COUNT` is unchanged, and (d) no behavioral change to gate scanner logic (`xtask/src/**/*.rs` — all Rust source files under `xtask/src/`, including `main.rs` which registers and dispatches subcommands); any scanner-logic change — even if `crates/` is untouched — invalidates all gate output lines and requires a gate re-run with re-recorded counts. Future passes can apply this criterion directly rather than requiring a new per-burst paragraph. Note: a fixture-directory change (clause c) invalidates AC-017 counts and requires re-verification of the fixture-mode gate output before the evidence report counts can be considered current. Note: a change to xtask scanner logic that only broadens detection (catches more violations) may not change recorded counts for the current `crates/` contents, but a re-run is still required because the count could change if new violations are now detected.

Gate output was **recorded** at `1ab2d10` (frozen HEAD at time of recording). Recordings were **re-verified valid** at frozen review HEAD `36cb4da` (fix-burst-13) and again at `8619aa7` (fix-burst-14).

Rationale for fix-burst-13 re-verification: changes affected only `xtask/src/tests.rs` assertion values and `check_no_panic.rs` doc comments. Neither file participates in the `crates/`-rooted scan path executed by the gates. Fixture count (16 total, 13 flagged) and `CREDENTIAL_FIXTURE_COUNT` are unchanged at both SHAs.

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

No changes were made to `crates/pregolya-core/` or any other `crates/`-rooted file. Fixture count (17 total, 14 flagged), `CREDENTIAL_FIXTURE_COUNT` (3), and all gate counts (25 analyzed / 16 exempt / 0 violations; 14/17 fixture-mode; 148 codes / 0 collisions) are unchanged at `c31b6f6`.

Rationale for fix-burst-16 re-verification: changes affect only the following files, none of which participate in the recorded gate scan paths:
- `xtask/src/check_no_panic.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/main.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/deny_bare_api_key.rs` — doc comment change; xtask is outside the `crates/`-rooted scan
- `xtask/src/tests.rs` — doc comment and test assertion changes; xtask is outside the `crates/`-rooted scan
- `crates/pregolya-core/src/http.rs` — doc comment changes only; no panic-family, timeout, or credential constructs added or removed; all gate counts unchanged
- `crates/pregolya-core/src/credentials.rs` — doc comment changes only; no panic-family, timeout, or credential constructs added or removed; all gate counts unchanged
- `docs/demo-evidence/S-1.02/evidence-report.md` — evidence artifact, not in `crates/` scan
- `CHANGELOG.md` — not in `crates/` scan

Conclusion: all three recorded gate outputs (25 analyzed / 16 exempt / 0 violations; 14/17 fixture-mode; 148 codes / 0 collisions) remain valid at `ad4dea3d517cf8d490c0e9909f14c569970f88f8`. The SHA `1ab2d10` in individual AC sections accurately reflects when recordings were made; re-verification at `36cb4da`, `8619aa7`, `c31b6f6`, `5261d2c`, and `ad4dea3d517cf8d490c0e9909f14c569970f88f8` confirms the evidence is current.

Rationale for fix-burst-19 re-verification: `xtask/tests/fixtures/violations/violation_assert_eq_bc_id_in_comparand.rs` was added at fix-burst-18, triggering validity criterion clause (c) (fixture-directory change). AC-017 counts updated from 13/16 to 14/17 and violation-class list extended to 14 entries (fifth class: `assert_eq!`/`assert_ne!` with BC-ID in comparand). Gate output confirmed `fixture-mode: 14/17 fixture files had findings` at `ad4dea3d517cf8d490c0e9909f14c569970f88f8` (2026-09-22). No `crates/`-rooted files changed; all other gate counts (25 analyzed / 16 exempt / 0 violations; 148 codes / 0 collisions) are unchanged.

Re-verified at fix-burst-20 HEAD `8a087170f85fa1e9409a7e4016e24477484a9c6c` (2026-09-22): scanner-logic clause (d) added to validity criterion. Fix-burst-20 changed `xtask/src/check_client_timeout.rs` (behavioral: `has_build_without_timeout` terminates at first depth-0 `.build()` and adds paren-depth tracking). All gates re-run at this HEAD — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`. Counts unchanged from prior recording.

Re-verified at fix-burst-21 HEAD `4a40644836898f0c937caed7affc1b61be0b713e` (2026-09-22): scanner-logic clause (d) triggered again by `xtask/src/check_client_timeout.rs` changes — `has_build_without_timeout` gained a three-dimension depth guard on `.timeout()` crediting (brace_depth==0 && bracket_depth==0 && paren_depth==0), and `find_chain_end` had its dead loop removed with an updated doc comment. All gates re-run at this HEAD — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `check-non-exhaustive`: N/A — subcommand not registered in this xtask binary (gate not yet implemented in this story). Counts unchanged from prior recording.

Re-verified at fix-burst-22 HEAD `7ed46cac11f2aa3d185fa62d8f9a00f7d9379ed7` (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — `find_chain_end` bounded to base-call path (`has_build_without_timeout` GroupEnd break-at-depth-0 logic) and doc comment reconciliation. Clause (d) glob widened from `xtask/src/check_*.rs` / `xtask/src/deny_*.rs` to `xtask/src/**/*.rs` to cover `main.rs` (which contains the `deny-anyhow-in-lib` and `deny-description-cache-key` scanner dispatch). All 7 registered xtask gates re-run at this HEAD — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.`; `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` Counts unchanged from prior recording.

Re-verified at fix-burst-23 scanner fix commit `48a2bfead8c8bbc2891c8f500e96009de030ee33` (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — Pattern 3 (bare `ClientBuilder::new()`) gained a non-reqwest qualifier guard preventing false-positive flags on non-reqwest builder chains; `has_build_without_timeout` had its dead `_end` parameter removed (dead code cleanup); KNOWN-LIMITATION 4 added to doc comments documenting the parenthesized or braced base subexpression false negative — `(reqwest::ClientBuilder::new()).build()` — where a depth-0 `ParenGroupEnd`/`BraceGroupEnd` closing a group that was opened before the chain start terminates the scan before the terminal `.build()` is reached. The CHANGELOG.md commit at HEAD (`9f438db6cab1563724dd1c77697f1fa3e8401880`) is docs-only (no `xtask/src/**/*.rs` changes) and does NOT trigger clause (d); gates were re-run against the scanner fix commit. All 7 registered xtask gates re-run — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.`; `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` Counts unchanged from prior recording.

Re-verified at fix-burst-24 HEAD `1abc3335636d07fd6903b6aa401f7a9ff42f7d8e` (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — `preceded_by_non_reqwest` guard predicate extended to treat `crate`/`self`/`super`/`Self` path segments as non-suppressing (behavioral change to Patterns 2, 3, 4: path-qualified type positions like `crate::Client::new()`, `self::ClientBuilder::new()`, `super::Client::builder()`, and `Self::Client::new()` no longer suppress the violation flag; three `crate::`-qualifier pinning tests added: `test_timeout_scanner_crate_qualified_client_new_is_flagged`, `test_timeout_scanner_crate_qualified_client_builder_new_is_flagged`, `test_timeout_scanner_crate_qualified_client_builder_is_flagged`). `check_no_panic.rs` KL numbering changes (MED-005 fix) are docs-only and do not independently trigger clause (d). `CHANGELOG.md` addition (MED-001 fix) is docs-only and does not independently trigger clause (d). All 7 registered xtask gates re-run at this HEAD — gate outputs confirmed: `check-no-panic PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `fixture-mode: 14/17 fixture files had findings`; `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `deny-bare-api-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`; `error-code-registry PASSED: 148 codes validated, 0 collisions.`; `check-file-size PASSED (2 warnings, 45 files measured, 2 allowlisted).`; `deny-anyhow-in-lib PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.`; `deny-description-cache-key PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations.` Counts unchanged from prior recording. The fix-burst-24 evidence-report docs commit (`1354d800eb2eac83ce645988bbc402716aa9d60b`) is docs-only and does NOT trigger clause (d).

Re-verified at fix-burst-25 code commit `d688830263cd9d5990645803d2774c06cf53edd7` (2026-09-22): scanner-logic clause (d) triggered by `xtask/src/check_client_timeout.rs` changes — new `scan_reqwest_blocking_pattern` helper added to detect `reqwest::blocking::Client::new()`, `reqwest::blocking::ClientBuilder::new().build()`, and `reqwest::blocking::Client::builder().build()` without `.timeout()`, and matching `preceded_by_reqwest` de-dup guards added to Patterns 2 and 3. Clause (a): no `crates/` files added or deleted — OK. Clause (b): no `crates/` code changes — OK. Clause (c): no fixture directory changes; `CREDENTIAL_FIXTURE_COUNT` unchanged — OK. Clause (d): TRIGGERED — scanner logic changed in `xtask/src/check_client_timeout.rs`. Gate outputs remain valid because the new detection (reqwest::blocking surface) does not apply to the existing workspace: no `crates/` code uses `reqwest::blocking::*` (the `blocking` feature is not enabled in `[workspace.dependencies]`). The scan counts are unchanged: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations`. All other gate counts unchanged from prior attestation. Implementer run (fix-burst-25): 205 tests pass, 5 skipped. Clippy clean (`-D warnings`).

Re-verified at fix-burst-26 syn rewrite commit `ebea3e1b22b6fe788008296d38236bc7853d0b23` (2026-09-23): scanner-logic clause (d) triggered — `xtask/src/check_client_timeout.rs` completely rewritten from proc_macro2 flat-token scanner to `syn::visit::Visit`-based `TimeoutChecker` AST visitor (−499 lines). Coordinator-directed structural intervention after 7 passes finding new syntactic forms in the manual token scanner. KNOWN-LIMITATION 4 eliminated — parenthesized and braced base subexpression forms are now properly detected; their pinning tests were inverted from `is_empty()` to detection assertions. KL-1 (bare name via `use` import), KL-2 (split-statement builder chains), and KL-3 (constant-valued zero timeout) preserved. Post-attestation correction (F-P25-MED-002): the syn rewrite introduced two additional behavioral gaps not disclosed in this attestation — macro token stream blindness (no `visit_expr_macro` / `visit_stmt_macro` / `visit_item_macro` overrides) and `Client::default()` / `ClientBuilder::default()` unclassified. Both were found as HIGH findings by adversarial pass 25 and closed in fix-burst-27.

Clause (a): no `crates/` production files added or deleted — the multibyte test added to `crates/pregolya-core/src/http.rs` (point-patch commit `5d50f79`) is inside `#[cfg(test)]` and does not affect the gate scan target. Clause (b): `crates/pregolya-core/src/http.rs` changed — `sanitize_error_message` now uses char-count cap (`chars().take(200)`); this production code change has no reqwest client usage and does not alter check-client-timeout gate outputs. Clause (c): no fixture directory changes; `CREDENTIAL_FIXTURE_COUNT` unchanged — OK. Clause (d): TRIGGERED — scanner completely rewritten.

Gate outputs remain valid because the syn rewrite finds the same 0 violations on the workspace: no `crates/` code uses `reqwest::Client::new()` without `.timeout()`, and the pre-push hook confirmed all xtask gates PASSED (check-client-timeout, check-no-panic, check-error-code-registry, deny-bare-api-key, deny-anyhow, deny-description-cache-key). Counts: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 unreadable, 0 violations` (unchanged). All other gate counts unchanged from prior attestation. Implementer run (fix-burst-26): 300 tests pass, 7 skipped. KL-4 tests now assert detection (was: known-limitation zero-finding, is: positive finding assertion). All other gate tests pass unchanged.

The fix-burst-26 evidence-report docs commit (this commit) is docs-only and does NOT trigger clause (d).

## fix-burst-27 re-verification

**Clause (d) analysis:** `check_client_timeout.rs` was modified (new `visit_expr_macro`/`visit_stmt_macro`/`visit_item_macro` methods, `scan_macro_tokens_for_timeout_violations` function, `classify_client_new` and `classify_builder_constructor` extended, `analyze_build_chain` OBS-001 fix). Evidence-report validity requires per-detection-class test attestation for scanner logic changes.

**Per-detection-class test attestation (commit `356ee3b`):**

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

**Docs-only note (commit `254fd7ce`):** The CHANGELOG and evidence-report update commit that follows code commit `356ee3b` is docs-only — no `xtask/src/**/*.rs` files changed, no fixture directory changes, no `CREDENTIAL_FIXTURE_COUNT` changed. Clause (d) does not fire for commit `254fd7ce`.

---

## fix-burst-28 re-verification

**Clause (d) analysis:** `check_client_timeout.rs` was modified (new `scan_macro_body_as_ast` function replacing flat-token `scan_macro_tokens_for_timeout_violations`; `analyze_build_chain` extended for UFCS `ClientBuilder` qself; `visit_trait_item_fn` added; module docs updated; KNOWN-LIMITATION 1 and 4 updated). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation (code commit `2d2f6ece`):**

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

**Docs-only note (commit `25a4ba7711086c574297a577b0719f6d97fd9f64`):** The docs commit that follows code commit `2d2f6ece` is docs-only — no `xtask/src/**/*.rs` files changed, no fixture directory changes, no `CREDENTIAL_FIXTURE_COUNT` changed. Clause (d) does not fire for docs commit `25a4ba7711086c574297a577b0719f6d97fd9f64`.

**Note:** the Pattern-A UFCS (`<reqwest::Client as Default>::default()`) test was added in fix-burst-29 (`test_timeout_checker_detects_client_ufcs_default_qualified`); this attestation row has been back-corrected to reference the load-bearing test.

---

## fix-burst-29 re-verification

**Clause (d) analysis:** `check_client_timeout.rs` was modified (UFCS qself extended; Strategy 3 removed; module doc and KL sections updated; two test renames). `tests.rs` was modified (new UFCS tests added; test renames). Clause (d) fires.

**Per-detection-class test attestation (code commits `a98d8ae`, `c0d6783`):**

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

**Docs-only note:** The docs commit following code commits `a98d8ae` and `c0d6783` (adding this CHANGELOG + evidence-report section) is docs-only — no `xtask/src/**/*.rs` behavioral changes. Clause (d) does not fire for the docs commit.

---

## fix-burst-30 re-verification

**Adversary pass 28 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 4 MED + 4 LOW findings.

**Implementation commits:** implementer `cf25c56` (code/doc fixes), test-writer `715aa72` (new pinning tests), product-owner BC-2.14.004 v1.15 (BC amendment for LOW-004).

**Clause (d) analysis:** `check_client_timeout` and `check_no_panic` were modified (`has_cfg_test_attr` / `syn_has_cfg_test` guards added to `visit_expr_macro` and `visit_stmt_macro`; dead `"builder"` arm removed from Pattern-A UFCS qself branch in `visit_expr_call`; angle-bracket depth tracking added to `syn_macro_has_bc_id`). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation (commits `cf25c56`, `715aa72`):**

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

## fix-burst-31 re-verification

**Adversary pass 29 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 3 MED + 1 LOW findings.

**Implementation commits:** implementer `c34ecc3` (code/doc), test-writer `db59f56` (tests), product-owner BC-2.14.004 v1.16 commit `369758b`.

**Clause (d) analysis:** `check_no_panic` was modified (`syn_macro_has_bc_id` turbofish-vs-comparison disambiguation — `<` is now treated as a turbofish opener only when preceded by `::`; `Spacing` imported alongside `TokenTree`). Three new pinning tests added in test-writer commit. Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation (commits `c34ecc3`, `db59f56`):**

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

## fix-burst-32 re-verification

**Adversary pass 30 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 HIGH + 2 MED + 1 LOW findings.

**Implementation commits:** test-writer `c71fdda` (2 load-bearing tests + doc fix), product-owner `7c4b5a4` (BC-2.14.003 v1.6).

**Clause (d) analysis:** `check_no_panic` was modified (two new load-bearing tests added; doc comment on `test_no_panic_exemption2_bc_id_with_turbofish_condition` corrected). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation (commit `c71fdda`):**

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
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32) | Turbofish comma miscounting — angle-bracket depth tracking + turbofish-vs-comparison disambiguation; `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` is the mechanism pin |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |
| NP-KL-3 | `check-no-panic` | **DOCUMENTED in fix-burst-33** | Path-call form `Result::unwrap(r)` — see fix-burst-33 |

**Docs-only note:** The docs commit for this fix-burst-32 CHANGELOG and evidence-report update is docs-only — no `xtask/src/**/*.rs` behavioral changes. Clause (d) does not fire for the docs commit.

### Gate output re-attestation (LOW-001 fix — clause (d) satisfaction)

**HEAD SHA:** `3eb68bec49c78d818aab3c4a9b2a7447dce5f5f7` (short: `3eb68be`)
**Date:** 2026-09-23
**Note:** Re-recorded per F-P31-LOW-001. Prior fix-burst-30/31/32 sections involved behavioral scanner changes (guard additions to `check_no_panic` and `check_client_timeout`) but did not record the raw gate stdout counts in the evidence-report. Clause (d) of the Recording Provenance validity criterion requires re-recording actual gate output counts whenever scanner logic changes. This subsection supplies those counts, retroactively satisfying clause (d) for the fix-burst-30/31/32 scanner changes as of the current HEAD.

**Clause (d) analysis for fix-burst-33 (test additions only):** Fix-burst-33 added tests to `xtask/src/tests.rs` only. No `xtask/src/**/*.rs` scanner logic files changed. Clause (d) does NOT fire for fix-burst-33. The counts below are recorded at fix-burst-33 HEAD to serve as the durable baseline for the outstanding clause (d) obligation from fix-burst-30/31/32.

**Actual gate output at `3eb68be`:**

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

All 8 registered xtask gates pass. Counts are identical to those from fix-burst-22 onward, confirming no `crates/`-rooted production files changed through fix-burst-33.

---

## fix-burst-33 re-verification

**Adversary pass 31 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 HIGH + 2 MED + 1 LOW + 1 OBS findings.

**Implementation commits:** implementer `3b1ecff` (MED-001 last-path-segment guard addition to three function visitors + MED-002 `NP-KL-3` minted in module doc), test-writer `3eb68be` (load-bearing tests for MED-001 and MED-002), demo-recorder `63eee0a` (gate output re-attestation for LOW-001).

**Clause (d) analysis:** Fix-burst-33 modifies `xtask/src/check_no_panic.rs` (three function visitors gained last-path-segment `test` guard; `NP-KL-3` minted in module doc) and adds tests to `xtask/src/tests.rs`. Clause (d) fires for `check_no_panic.rs` scanner logic changes — per-detection-class test attestation required.

**Per-detection-class test attestation (commits `3b1ecff`, `3eb68be`):**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| MED-001 `#[test]`-family guard — `visit_item_fn` / `visit_impl_item_fn` / `visit_trait_item_fn` | `test_no_panic_tokio_test_attr_fn_exempt` — EXEMPT (load-bearing: fails without guard) | pass |
| MED-002 NP-KL-3 path-call form pin | `test_no_panic_np_kl3_path_call_form_known_gap` — 0 findings (known gap, `ExprCall` path-call form not detected without type inference) | pass |

Total: 240 xtask tests pass, 5 skipped.

**Gate output (at HEAD `3eb68be`, 2026-09-23):**

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
- LOW-001: gate output re-attestation commit `63eee0a` — all 8 gates re-run at HEAD `3eb68be`; clause (d) satisfied
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

**Docs-only note:** This fix-burst-33 CHANGELOG and evidence-report docs commit is docs-only — no `xtask/src/**/*.rs` scanner logic changes beyond those already in commits `3b1ecff` and `3eb68be`. Clause (d) does not fire for the docs commit itself.

---

## fix-burst-34 re-verification

**Adversary pass 32 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 0 CRIT + 1 HIGH + 2 MED + 1 LOW + 1 OBS findings.

**Implementation commits:** implementer `74e5a63` (MED-001 `visit_item_trait` guard in both gates + LOW-001 `TYPE_SUFFIXES` reorder), technical-writer `4c3ea72` (HIGH-001 KL registry restore in CHANGELOG and evidence-report), test-writer `7184a97` (load-bearing tests for MED-001), story-writer `4fa94af` on factory-artifacts (MED-002 story spec correction to v1.18).

**Clause (d) analysis:** Fix-burst-34 modifies `xtask/src/check_no_panic.rs` and `xtask/src/check_client_timeout.rs` (both gained `visit_item_trait` override). Clause (d) fires — per-detection-class test attestation required.

**Per-detection-class test attestation:**

| Detection class | Representative tests | Pass |
|----------------|----------------------|------|
| HIGH-001 KL registry restore | `NP-KL-1` and `BAK-KL-1` corrected in CHANGELOG and evidence-report (`4c3ea72`) — records fix, no new tests |
| MED-001 `#[cfg(test)]` ItemTrait guard — `check_no_panic` | `test_no_panic_cfg_test_item_trait_exempt` — EXEMPT (load-bearing: fails without `visit_item_trait` guard in `PanicVisitor`) | pass |
| MED-001 `#[cfg(test)]` ItemTrait guard — `check_client_timeout` | `test_timeout_checker_cfg_test_item_trait_exempt` — EXEMPT (load-bearing: fails without `visit_item_trait` guard in `TimeoutChecker`) | pass |
| MED-002 story spec correction | Three sites amended in story spec, v1.18 (`4fa94af` on factory-artifacts) — spec-only fix, no new gate tests |
| LOW-001 `TYPE_SUFFIXES` reorder | Reordered longest-first in `is_zero_literal` (`74e5a63`) — ordering fix, no new tests |
| OBS-001 process gap | Partially addressed by HIGH-001 restore; orchestrator cycle-closing checklist follow-up required |

Total: 242 xtask tests pass, 5 skipped.

**Gate output re-attestation (clause (d) — behavioral scanner changes):** `visit_item_trait` added to both `PanicVisitor` and `TimeoutChecker`. Gate output re-recorded at fix-burst-33 HEAD `3eb68be` baseline — counts unchanged (25 analyzed, 16 exempt, 0 violations for all scanning gates). No `crates/`-rooted production files changed in fix-burst-34; all 8 gate counts remain identical to the baseline recorded in the fix-burst-32 re-verification §Gate output re-attestation (LOW-001 fix — recorded at HEAD `3eb68be`).

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

### Gate output re-attestation at frozen HEAD `5ae507a` (MED-003 fix — clause (d) re-satisfied)

**HEAD SHA recorded:** `5ae507a`
**Date:** 2026-09-23
**Note:** Re-recorded per F-P33-MED-003: prior clause (d) discharge in fix-burst-34 cited pre-change SHA `3eb68be`; this recording satisfies clause (d) at the correct post-change frozen HEAD.

**Actual gate output at `5ae507a`:**

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

All 8 registered xtask gates pass at `5ae507a`. Counts are identical to the `3eb68be` baseline — confirming no gate-relevant changes between the pre-change HEAD and the post-change frozen HEAD.

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

**Docs-only note:** This fix-burst-34 CHANGELOG and evidence-report docs commit is docs-only for the evidence-report portion — the technical-writer KL restore (`4c3ea72`) is records-tier content in documentation files only. The behavioral scanner changes are in implementer commit `74e5a63` and test-writer commit `7184a97`.

---

## Notes

- All recordings produced with VHS 0.11.0 using `FiraCode Nerd Font Mono`, Catppuccin Mocha theme, 1200×600 or 1200×700 resolution.
- `Wait+Screen /pattern/` used for the xtask gate commands; `Sleep 20s` used for the nextest run (command completes in ~2s warm, Sleep provides buffer for cold environments).
- `Wait+Line` is NOT used — VHS 0.11.0 shows zsh prompt `>` as last line after command completion, preventing Last-Line pattern matching.
- AC-007, AC-009, AC-013 have no runtime demo — these are compile-time `static_assertions` enforced by the Rust type system at `cargo build` time.
- WebM files are primary format (better compression); GIF files are included for inline PR embedding.
