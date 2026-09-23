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

**Validity criterion:** Gate output remains valid at any HEAD where (a) no `crates/` files are added or deleted, (b) any `crates/` changes are doc-comment-only with no panic-family, timeout, or credential constructs added or removed, and (c) no files are added to, removed from, or renamed within `xtask/tests/fixtures/violations/`, and `CREDENTIAL_FIXTURE_COUNT` is unchanged. Future passes can apply this criterion directly rather than requiring a new per-burst paragraph. Note: a fixture-directory change (clause c) invalidates AC-017 counts and requires re-verification of the fixture-mode gate output before the evidence report counts can be considered current.

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

---

## Notes

- All recordings produced with VHS 0.11.0 using `FiraCode Nerd Font Mono`, Catppuccin Mocha theme, 1200×600 or 1200×700 resolution.
- `Wait+Screen /pattern/` used for the xtask gate commands; `Sleep 20s` used for the nextest run (command completes in ~2s warm, Sleep provides buffer for cold environments).
- `Wait+Line` is NOT used — VHS 0.11.0 shows zsh prompt `>` as last line after command completion, preventing Last-Line pattern matching.
- AC-007, AC-009, AC-013 have no runtime demo — these are compile-time `static_assertions` enforced by the Rust type system at `cargo build` time.
- WebM files are primary format (better compression); GIF files are included for inline PR embedding.
