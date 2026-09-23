# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- **No-panic CI enforcement** (`cargo xtask check-no-panic`): AST-based scan of all `crates/` production source files that flags `unwrap()`, `expect()`, bare `assert!` / `assert_eq!` / `assert_ne!` / `assert_matches!` without `# Panics` doc and BC-ID message, `todo!` / `unimplemented!` (unconditionally flagged — no exemption applies; mark incomplete work), `panic!`, named-arm `unreachable!` where the match has an unguarded catch-all sibling, and wildcard `_ => unreachable!()` arms; exempts `debug_assert!`, exhaustive-match `unreachable!` in fully-named arms, and programmer-error guards with compliant doc+message pattern (BC-2.14.003).
- **HTTP client timeout CI enforcement** (`cargo xtask check-client-timeout`): source scan that flags `reqwest::ClientBuilder` chains missing `.timeout(duration > 0)` before `.build()` and any bare `reqwest::Client::new()` in non-test production code (BC-2.14.004), including `Client::default()` / `ClientBuilder::default()` constructions, UFCS `<reqwest::Client as Default>::default()` forms, `reqwest::blocking::*` surfaces, and macro-body constructions via recursive syn AST parsing.
- **Credential structural safety CI gate** (`cargo xtask deny-bare-api-key`): structural scanner that flags public structs with credential-sentinel names (`key`, `token`, `secret`, `credential`, `auth`, `bearer`, `password`, `passphrase`) that auto-derive `Debug` (without a manual redacted impl), derive `Serialize`, derive `Deserialize` (bypasses `new()` validation), implement `Display`, or implement `Deref<Target=str/String>` (BC-2.14.005).
- **Error-code registry CI enforcement** (`cargo xtask check-error-code-registry`): parses `.factory/specs/prd-supplements/error-taxonomy.md` and fails the build if any `E-<COMPONENT>-<NNN>` code appears more than once; exits 1 with a descriptive error if zero codes are extracted (vacuity guard — detects taxonomy format changes); taxonomy path resolved via `FACTORY_DIR` env var (set by CI factory-artifacts checkout step) or `.factory/` relative fallback when `FACTORY_DIR` is absent or empty (BC-2.14.001, VP-BC214001-01).
- **`OpenAiApiKey` and `AnthropicApiKey` credential newtypes** in `pregolya-core`: private-field newtypes with manually-implemented redacted `Debug` (emits exactly `"<redacted>"`); fallible construction via `new() -> Result<Self, PregolyaError>`; infallible `From<String>`/`From<&str>` conversions are structurally forbidden and pinned by `static_assertions::assert_not_impl_any!` (BC-2.14.006 EC-005); no `Serialize`, `Deserialize`, `Display`, `Deref`, or `AsRef<str>`; compile-time `static_assertions` enforce all exclusions (BC-2.14.005, BC-2.14.006).
- **`build_client()` HTTP client factory** in `pregolya-core`: `reqwest::ClientBuilder` wrapper enforcing 30-second total timeout with `rustls-tls` backend; maps `ClientBuilder::build()` failure to `PregolyaError { category: TRANSPORT, code: "E-CORE-012", retry_hint: Never }` (BC-2.14.004).
- **Validation error propagation** (`E-CORE-005`): `OpenAiApiKey::new("")` and `::new("   ")` return `Err(PregolyaError { category: VAL, code: "E-CORE-005", message: "Validation failed for 'api_key': value must not be empty or whitespace-only", retry_hint: Never })`; no silent `None` or default returns (BC-2.14.006).

## fix-burst-31 (pass-29 findings)

### xtask check_no_panic / check_client_timeout / deny_bare_api_key — turbofish-vs-comparison disambiguation, KL namespace canonicalization, defense-in-depth annotations

**HIGH-001 — `syn_macro_has_bc_id` incorrectly increments `angle_depth` for bare comparison `<`:** The NP-KL-2 fix in fix-burst-30 incremented `angle_depth` on ANY `<` punct token. A bare comparison operator (`assert!(a < b, "BC-2.14.003 ...")`) inflated `angle_depth` to 1, hiding the message-argument comma from the top-level scan and causing `syn_macro_has_bc_id` to return `false` even when the message contained a valid BC-ID — a fully-compliant programmer-error guard was flagged as a violation. Fixed: `<` is now treated as a turbofish opener ONLY when preceded by `::` (tokens_vec[i-2] = `:` Joint, tokens_vec[i-1] = `:`). Bare comparison `<` (no `::` prefix) no longer increments `angle_depth`. Import updated from `use proc_macro2::TokenTree` to `use proc_macro2::{Spacing, TokenTree}`. NP-KL-2 fully resolved; module doc updated to `[RESOLVED in fix-burst-30/fix-burst-31]`.

**MED-001 — `syn_macro_has_bc_id` paper-fix closure for NP-KL-2 required additional tests:** ADV-P28-MED-004 NP-KL-2 closure was a paper-fix — `syn_macro_has_bc_id`'s angle-bracket depth fix was untested and its implementation was incorrect (HIGH-001), and the evidence-report attestation table had no row for the Exemption-2 BC-ID detection class. Closed by: (1) HIGH-001 fix above makes the implementation correct; (2) three new pinning tests added: `test_no_panic_exemption2_bc_id_with_turbofish_condition` (Exemption-2 + turbofish condition — EXEMPT), `test_no_panic_exemption2_bc_id_with_comparison_condition` (Exemption-2 + comparison condition — EXEMPT, regression pin for HIGH-001), `test_no_panic_comparison_condition_no_bc_id_flagged` (no BC-ID — FLAGGED, negative control); (3) evidence-report fix-burst-31 re-verification section adds the Exemption-2 BC-ID detection class attestation row; `NP-KL-2` confirmed RESOLVED (both turbofish and comparison regression tests pass).

**MED-002 — BC-2.14.004 `{INV-003}` clause (a) misdescribed test-file exemption perimeter:** BC-2.14.004 `{INV-003}` clause (a) declared `test/` (singular) as exempt when `is_test_file` only checks `/tests/` (directory form), and omitted the `tests.rs` / `_test.rs` / `_tests.rs` filename forms. Closed by: product-owner amended BC-2.14.004 to v1.16 (commit `369758b`) — clause (a) now reads: "source files whose path contains a `/tests/` directory component, or whose filename is exactly `tests.rs`, or whose filename ends with `_test.rs` or `_tests.rs`". No behavioral change to the gate itself.

**MED-003 — Source module docs used generic `KNOWN-LIMITATION N` IDs colliding across modules:** Renamed all Known Limitation IDs in module docs to canonical namespaced form: `KNOWN-LIMITATION 1/2/3` → `CT-KL-1/2/3` in `check_client_timeout`; `KL-macro` → `CT-KL-macro` throughout `check_client_timeout` (module doc, `scan_macro_body_as_ast` doc, inline comment, `analyze_build_chain` doc, and five test-body sites); `CT-KL-4` retirement note added (RETIRED in fix-burst-26; renumbered to avoid reusing retired number); `KNOWN-LIMITATION 5` → `CT-KL-5` (module doc, test doc, two test body sites); `KNOWN-LIMITATION 1/2` → `NP-KL-1/NP-KL-2` in `check_no_panic` module doc, with NP-KL-2 moved to a `## Resolved Limitations` sub-section; `KNOWN-LIMITATION` → `BAK-KL-1` in `deny_bare_api_key` module doc.

**LOW-001 — `visit_expr_macro` cfg-test guards undocumented as defense-in-depth:** Added inline doc comment before the `#[cfg(test)]` guard in `visit_expr_macro` in both `check_client_timeout` and `check_no_panic` explaining that the guard is defense-in-depth: stable Rust cannot express `#[cfg(test)]` as an outer attribute on an expression-position macro call, so the guard is not reachable by compliant code but is retained for future-proofing.

### Known limitations after fix-burst-31

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30 implementation + fix-burst-31 tests) | Turbofish comma miscounting — angle-bracket depth tracking + turbofish-vs-comparison disambiguation both implemented |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |

Test count: 236 xtask tests pass, 5 skipped.

## fix-burst-30 (pass-28 findings, code commits `cf25c56`, `715aa72`, BC-2.14.004 v1.15)

### xtask check_client_timeout / check_no_panic / deny_bare_api_key — cfg-test guards, Strategy 2 positive detection, dead arm removal, KL namespace, NP-KL-2 resolution

**ADV-P28-HIGH-001 — `KNOWN-LIMITATION 4` identifier collision resolved:** Module doc heading renamed to `KL-macro`; `scan_macro_body_as_ast` doc updated from `KNOWN-LIMITATION 4` to `KL-macro`; two `assert!` message strings in `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` updated from "KNOWN-LIMITATION 4 eliminated" to "formerly KL-4 of the flat-token scanner — eliminated".

**ADV-P28-HIGH-002 — `#[cfg(test)]` guard missing from `visit_expr_macro` and `visit_stmt_macro`:** Added `has_cfg_test_attr` / `syn_has_cfg_test` guards as first statement in `visit_expr_macro` and `visit_stmt_macro` in both `check_client_timeout` and `check_no_panic`; all four previously-unguarded methods now skip macro calls inside `#[cfg(test)]`-gated contexts. Two pinning tests added: `test_timeout_checker_cfg_test_stmt_macro_not_flagged` (`check_client_timeout`) and `test_no_panic_cfg_test_stmt_macro_not_flagged` (`check_no_panic`); the expression-position `visit_expr_macro` guard is defense-in-depth (stable Rust cannot express `#[cfg(test)]` on an expression-position macro — see inline comment).

**ADV-P28-MED-001 — Strategy 2 of `scan_macro_body_as_ast` had no positive-detection test:** Added `test_timeout_checker_strategy2_detects_statement_macro_violation` exercising the `fn __macro_fragment__()` wrapper path; evidence-report attestation row corrected to cite one test per strategy (S1/S2/S3).

**ADV-P28-MED-002 — Three test doc comments referenced deleted `scan_macro_tokens_for_timeout_violations`:** Updated to reference `scan_macro_body_as_ast` Strategy 1 / Strategy 3 as appropriate.

**ADV-P28-MED-003 — Dead `"builder"` arm in `visit_expr_call` Pattern-A UFCS qself branch:** Narrowed guard from `matches!(last_method, "default" | "new" | "builder")` to `matches!(last_method, "default" | "new")`; inline doc corrected (Pattern-A does not handle `<reqwest::Client>::builder()`; that is Pattern B via `analyze_build_chain`).

**ADV-P28-MED-004 — `check_no_panic` and `deny_bare_api_key` KL disclosures absent from story records; NP-KL-2 sound fix implemented:** `KNOWN-LIMITATION 2` in `check_no_panic` (turbofish comma miscounting in `syn_macro_has_bc_id`) had a documented sound fix not yet applied — implemented angle-bracket depth tracking (`u32` with `saturating_sub`) in `syn_macro_has_bc_id`; NP-KL-2 is now resolved.

**ADV-P28-LOW-001 — Three doc sites in `check_client_timeout` enumerated only `<reqwest::Client as Default>::default()` UFCS form:** Expanded to include `<reqwest::Client>::new()`, `<reqwest::ClientBuilder>::new().build()`, and `<reqwest::Client>::builder().build()`.

**ADV-P28-LOW-002 — `KL-macro` was the only known limitation with no pinning test:** Added `test_timeout_checker_unparseable_macro_body_known_limitation` asserting zero findings for an opaque macro body failing all three strategies.

**ADV-P28-LOW-003 — Correction to fix-burst-29 `F-P27-MED-002` attribution:** (See fix-burst-29 section below — "Six" corrected to "Four".)

**ADV-P28-LOW-004 — BC-2.14.004 `{INV-003}` test-code exemption perimeter:** BC-2.14.004 `{INV-003}` expanded to enumerate full test-code exemption perimeter; handled by product-owner (BC-2.14.004 v1.15).

### Known limitations after fix-burst-30

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **RESOLVED in fix-burst-30** | Turbofish comma miscounting — angle-bracket depth tracking implemented |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |

Note: CT-KL-4 was retired (parenthesized/braced base subexpression eliminated by syn AST visitor in fix-burst-26; renumbered in fix-burst-28/29 → now CT-KL-macro for the opaque-macro limitation).

Test count: 233 xtask tests pass, 5 skipped.

## fix-burst-29 (pass-27 findings, code commits `a98d8ae`, `c0d6783`)

### xtask check_client_timeout — UFCS extension, dead-code removal, KL corrections

**F-P27-MED-002 — UFCS qself extended to `new` and `builder`:** `visit_expr_call` qself branch and `analyze_build_chain` UFCS branch both previously guarded on `last_method == "default"` only. Extended to `matches!(last_method, "default" | "new" | "builder")`, enabling detection of `<reqwest::Client>::new()`, `<reqwest::Client>::builder().build()`, and `<reqwest::ClientBuilder>::new().build()` without `.timeout()`. Four new pinning tests cover qualified and clean forms.

**F-P27-MED-004 — Strategy 3 (dead code) removed:** `scan_macro_body_as_ast` previously described four progressive parse strategies; Strategy 3 (`syn::parse2::<syn::Expr>`) was logically dead because any token stream it accepts is also accepted by Strategy 2's `fn __macro_fragment__()` wrapper. Strategy 3 removed; all four documentation sites updated to say "three strategies."

**F-P27-HIGH-001 + F-P27-MED-003 — KL-1 module doc corrected:** KNOWN-LIMITATION 1 in the module doc now explicitly labels bare-name detection as a conservative false POSITIVE (not false negative). The workaround corrected from "use `reqwest::Client::new()`" (unconditional violation — wrong) to "qualify with owning-crate path (e.g., `other_sdk::Client::new()`)".

**F-P27-MED-008 — KNOWN-LIMITATION 5 added:** Documents the module-alias re-export false negative: `http::Client::new()` (where `http` re-exports `reqwest::Client`) is suppressed because the gate classifies non-reqwest head segments as non-reqwest. Pinned by `test_timeout_checker_module_alias_false_negative_known_limitation`.

**F-P27-HIGH-002 + F-P27-MED-001 — Pattern-A UFCS test added:** `test_timeout_checker_detects_client_ufcs_default_qualified` pins the `visit_expr_call` qself branch for `<reqwest::Client as Default>::default()`; `test_timeout_checker_ufcs_non_reqwest_client_as_default_clean` pins the non-reqwest negative.

**F-P27-LOW-001 — blocking arm doc fixed:** Module doc `# Scanning rules` previously attributed bare `blocking::` detection to "the path-relative guard"; now correctly names "the `blocking`-head segment arm in `classify_client_new` / `classify_builder_constructor`."

**F-P27-LOW-002 — stale KL-4 refs updated:** `analyze_build_chain` doc updated from "eliminating KNOWN-LIMITATION 4" to "parenthesized/braced base subexpression (formerly KL-4 of the flat-token scanner)". Tests renamed: `test_timeout_scanner_parenthesized_base_subexpr_known_limitation` → `..._handled_by_syn`; `test_timeout_scanner_braced_base_subexpr_known_limitation` → `..._handled_by_syn`.

**F-P27-OBS-001 — check_error_code_registry doc fixed:** Module doc now says "every code declared in the canonical registry table (one code per leading `| E-` table cell)" instead of overstating coverage.

### Known limitations after fix-burst-29

| ID | Description | Status |
|----|-------------|--------|
| KL-1 | Bare `Client::new()` without a qualifying module path — conservative **false positive**: gate cannot distinguish reqwest vs other SDK clients, flags conservatively. Workaround: qualify with owning-crate path (e.g., `other_sdk::Client::new()`) | Preserved (now false-positive, per-syn-rewrite clarification) |
| KL-2 | Split-statement builder chains (builder on line 1, `.build()` on line N via variable) | Preserved |
| KL-3 | `.timeout(SOME_CONST_ZERO)` — constant-valued zero not detected | Preserved |
| KL-4/macro | Macro bodies failing all three parse strategies are skipped | Preserved (renumbered from 4 to KL-macro, three strategies after Strategy-3 removal) |
| KL-5 | Module-alias re-export (`http::Client::new()` where `http` re-exports reqwest) — false negative; head segment treated as non-reqwest | New |

Test count: 229 passing (xtask), 5 skipped.

## fix-burst-28 (pass-26 findings, commit `2d2f6ece`)

### xtask check_client_timeout — recursive macro AST, ClientBuilder UFCS, doc hygiene

**F-P26-HIGH-001 + F-P26-MED-001 — Recursive macro AST scanner:** Replaced the flat-token `scan_macro_tokens_for_timeout_violations` with `scan_macro_body_as_ast`, which uses four progressive parse strategies to obtain a `syn` AST and re-run `TimeoutChecker` recursively on macro body tokens: (1) `syn::parse2::<syn::File>` (direct parse — works for `thread_local!`), (2) `fn __macro_fragment__() { … }` wrapper parse (works for statement/expression bodies), (3) `syn::parse2::<syn::Expr>` (bare expression), (4) `extract_initializer_exprs_from_tokens` (splits at top-level `;`, extracts the initializer expression — works for `lazy_static!`-style `static ref NAME: TYPE = EXPR;` bodies). Macro bodies that fail all four strategies are skipped rather than flagged conservatively. The recursive approach eliminates the depth-blind false-negative (any `.timeout` token in a flat stream had suppressed violations) and the false-positive for `reqwest::Client::builder()` (previously in Pattern A arm, now correctly classified as Pattern B via chain tracing).

**F-P26-MED-002 — Module-level docs updated:** `//!` module doc, `run()`, and `scan_for_timeout_violations_in_source` now mention `Client::default()` / `ClientBuilder::default()`, recursive macro AST scanning, and UFCS qself handling.

**F-P26-MED-003 — KNOWN-LIMITATION 4 added:** Documents that macro bodies failing all four parse strategies are skipped.

**F-P26-MED-004 — UFCS `<reqwest::ClientBuilder as Default>::default()` detection:** `analyze_build_chain` Call branch extended — when path segments are `["Default", "default"]` and qself type is `reqwest::ClientBuilder` or bare `ClientBuilder`, treats as a builder entry point.

**F-P26-MED-005 — KNOWN-LIMITATION 1 workaround corrected:** Removed nonexistent "lint-exempt allowlist" workaround claim; the correct escape is to use the fully-qualified form `reqwest::Client::new()`.

**F-P26-LOW-001 — `visit_trait_item_fn` added:** `TimeoutChecker` now has the same `#[cfg(test)]` / `#[test]` guard for trait default methods as `PanicVisitor`.

### Known limitations after fix-burst-28

| ID | Description | Status |
|----|-------------|--------|
| KL-1 | Bare `Client::new()` without a qualifying module path — **conservative false positive**: the gate cannot determine whether `Client` refers to `reqwest::Client` or another SDK's client, so it flags conservatively. (Qualifying with a non-reqwest head segment suppresses the alarm.) Workaround: qualify with owning-crate path (e.g., `other_sdk::Client::new()`); reqwest-qualified forms are unconditional violations. | Conservative false positive |
| KL-2 | Split-statement builder chains (builder on line 1, `.build()` on line N via variable) | Preserved |
| KL-3 | `.timeout(SOME_CONST_ZERO)` — constant-valued zero not detected | Preserved |
| KL-macro | Macro bodies failing all four parse strategies (not valid as item sequence, wrapped-fn, expression, or initializer extraction) are skipped | Preserved (narrowed scope from fix-burst-27) |

Test count: 222 passing (xtask), 5 skipped (pre-existing ignored tests requiring live API keys).

## fix-burst-27 (pass-25 findings, commit `356ee3b`)

### xtask check_client_timeout — macro scanning and Default constructor

**F-P25-HIGH-001 — macro token stream scanning:** Added `visit_expr_macro`, `visit_stmt_macro`, and `visit_item_macro` overrides to `TimeoutChecker`. Each override delegates to `scan_macro_tokens_for_timeout_violations`, a flat-token scanner that detects the following qualified `reqwest::*` forms inside macro invocation bodies: `reqwest::Client::new`, `reqwest::Client::builder`, `reqwest::Client::default`, `reqwest::ClientBuilder::new`, `reqwest::ClientBuilder::default`, `reqwest::blocking::Client::new`, `reqwest::blocking::Client::builder`, `reqwest::blocking::Client::default`, `reqwest::blocking::ClientBuilder::new`, and `reqwest::blocking::ClientBuilder::default`. Reqwest client constructions inside `thread_local!{}`, `lazy_static!{}`, and arbitrary macro bodies are now detected. Three new pinning tests cover this path. Note: this flat-token scanner is replaced in fix-burst-28 by `scan_macro_body_as_ast`, a recursive AST approach that reuses `TimeoutChecker` on the macro body tokens — detection is performed via `classify_client_new` and `classify_builder_constructor` rather than flat-token matching.

**F-P25-HIGH-002 — `Client::default()` / `ClientBuilder::default()` unclassified:** `classify_client_new` extended to match `Client::default` in addition to `Client::new` and `Client::builder`; `classify_builder_constructor` extended to include `ClientBuilder::default`. The UFCS qself form `<reqwest::Client as Default>::default()` is handled conservatively in the `ExprCall` visitor path. Four new pinning tests cover qualified and bare forms.

**F-P25-MED-001 — stale doc comments:** 16 doc-comment sites in `check_client_timeout` and `tests` referencing deleted symbols (`scan_reqwest_blocking_pattern`, `preceded_by_non_reqwest`, `has_build_without_timeout`, flat-index notation, Pattern 1/2/3/4 numbering) updated to reference current symbols and Pattern A/B terminology.

**F-P25-LOW-001 — `has_cfg_test_attr` divergence rationale:** Divergence-rationale doc added explaining intentional separation from `check_no_panic::syn_has_cfg_test`.

**F-P25-LOW-002 — `map_build_failure` doc:** Doc comment updated to cite `sanitize_error_message` for the 200-char cap.

**F-P25-LOW-003 — `#[tokio::test]` not recognized:** Test-attribute detection changed from `is_ident("test")` to last-path-segment matching, covering `#[tokio::test]`, `#[async_std::test]`, `#[rstest]`, etc.

**F-P25-OBS-001 — monotonic-OR in `analyze_build_chain`:** Fixed — `has_valid_timeout` now reflects the last `.timeout()` call rather than any previous valid call, matching reqwest's own last-wins semantics.

### Known limitations after fix-burst-27

| ID | Description | Status |
|----|-------------|--------|
| KL-1 | Bare `Client::new()` without a qualifying module path — **conservative false positive**: the gate cannot determine whether `Client` refers to `reqwest::Client` or another SDK's client, so it flags conservatively. (Qualifying with a non-reqwest head segment suppresses the alarm.) | Conservative false positive |
| KL-2 | Split-statement builder chains (builder on line 1, `.build()` on line N) | Preserved |
| KL-3 | `.timeout(SOME_CONST_ZERO)` — constant-valued zero not detected (inline `Duration::ZERO` now caught by OBS-001 fix) | Preserved |
| KL-macro | Macro token stream scanning is best-effort flat-token; deeply nested or aliased macro constructions may evade detection | New |

Test count: 309 passing, 7 skipped (pre-existing ignored tests requiring live API keys).

### Fixed (fix-burst-26)

- **F-P24-HIGH-001** (`xtask/src/check_client_timeout.rs`) — Head-anchored blocking detection: `blocking::Client::new()` (use-imported form where `blocking` is the path head) now flagged conservatively; `other_sdk::blocking::Client::new()` still suppressed (head `other_sdk` is non-reqwest). Implemented via `preceded_by_non_reqwest_qualifier` helper (point-patch commit `5d50f79`), then structurally eliminated by the syn rewrite below.
- **F-P24-MED-002** (`xtask/src/check_client_timeout.rs`) — Module doc `# Scanning rules` and `scan_flat_for_timeout_violations` Patterns detected list updated to include blocking patterns.
- **F-P24-MED-003** (`xtask/src/check_client_timeout.rs`) — Updated `scan_flat_for_timeout_violations` doc summary paragraph from pre-fix-burst-24 suppression rule to current head-anchored rule.
- **F-P24-LOW-004** (`xtask/src/check_client_timeout.rs`) — Corrected blocking test doc comments: `scan_reqwest_blocking_pattern` sibling helper, not "Pattern 1 extension".
- **F-P24-LOW-005** (`crates/pregolya-core/src/http.rs`) — `sanitize_error_message` now uses char-count cap (`chars().take(200)`) to match spec BC-2.14.004 {EC-006}; added multibyte pinning test.
- **Structural refactor** (`xtask/src/check_client_timeout.rs`) — Rewrote entire timeout gate from proc_macro2 flat-token scanner to `syn::visit::Visit`-based `TimeoutChecker` AST visitor (commit `ebea3e1`). Coordinator-directed structural intervention after 7 passes finding new syntactic forms in the manual token scanner. KNOWN-LIMITATION 4 (parenthesized/braced base subexpression GroupEnd false-negative) is **eliminated** — its tests inverted from `is_empty()` to detection assertions. KL-1 (bare name via `use` import) and KL-3 (constant-valued zero timeout) preserved. Net: −499 lines.

### Fixed (fix-burst-25)

- **F-P23-HIGH-001** (`xtask/src/check_client_timeout.rs`) — Added `scan_reqwest_blocking_pattern` helper to detect `reqwest::blocking::Client::new()`, `reqwest::blocking::ClientBuilder::new().build()`, and `reqwest::blocking::Client::builder().build()` without `.timeout()`; previously evaded detection via `preceded_by_non_reqwest` treating `blocking` as non-reqwest. Added four pinning tests (three positive, one negative for `other_sdk::blocking`).
- **F-P23-MED-005** (`xtask/src/check_client_timeout.rs`) — Added three qualifier pinning tests for `self::Client::new()`, `super::ClientBuilder::new().build()`, and `Self::Client::builder().build()`; confirms `crate|self|super|Self` exclusion flags all four qualifier forms.
- **F-P23-LOW-006** (`xtask/src/check_client_timeout.rs`) — Updated KNOWN-LIMITATION 4 paragraph to name both `ParenGroupEnd` and `BraceGroupEnd` terminators and cite both pinning tests.
- **F-P23-LOW-007** (`xtask/src/check_client_timeout.rs`) — Rewrote Pattern 4 comment to accurately describe de-duplication (not catching); added matching `preceded_by_reqwest` de-dup guard to Patterns 2 and 3 for symmetry.

### Fixed (fix-burst-24)

- **F-P22-MED-001** (`CHANGELOG.md`) — Added missing fix-burst-23 section documenting F-P21-MED-001, F-P21-MED-002, and F-P21-LOW-001; reordered `### Fixed` sections to descending fix-burst order.
- **F-P22-MED-002** (`docs/demo-evidence/S-1.02/evidence-report.md`) — Corrected fix-burst-23 attestation paragraph wording; accurately describes KNOWN-LIMITATION 4 (`ParenGroupEnd` depth-0 break) and Pattern 3 label.
- **F-P22-MED-003** (`xtask/src/check_client_timeout.rs`) — Updated KNOWN-LIMITATION 1 scope statement to cover Patterns 2, 3, and 4 (was previously scoped to Pattern 2 only).
- **F-P22-MED-004** (`xtask/src/check_client_timeout.rs`) — Extended `preceded_by_non_reqwest` guard in Patterns 2, 3, and 4 to exclude `"crate" | "self" | "super" | "Self"` from suppression; path-relative qualifiers now treated as ambiguous and flagged conservatively. Added three `crate::`-qualifier pinning tests.
- **F-P22-MED-005** (`xtask/src/check_no_panic.rs`) — Renumbered KNOWN-LIMITATION labels: KL-1 (`scan_method_calls_in_tokens` exemption-blind macro-arg scan) and KL-2 (`syn_macro_has_bc_id` turbofish comma counting); added `# Known Limitations` module-doc index.
- **F-P22-LOW-006** (`xtask/src/check_client_timeout.rs`) — Added `test_timeout_scanner_braced_base_subexpr_known_limitation` pinning test for KNOWN-LIMITATION 4 braced form.
- **F-P22-LOW-007** (`xtask/src/check_client_timeout.rs`) — Added defense-in-depth comment to Pattern 4's `preceded_by_reqwest` guard; guard is currently unreachable but intentional as future-proofing.

### Fixed (fix-burst-23, 2026-09-22)
- F-P21-MED-001: Pattern 3 (`ClientBuilder::new()`) gained a `preceded_by_non_reqwest` qualifier guard matching Patterns 2 and 4; suppresses false positives for non-reqwest types named `ClientBuilder`.
- F-P21-MED-002: Added KNOWN-LIMITATION 4 to `has_build_without_timeout` documenting the parenthesized/braced base subexpression false negative (`(reqwest::ClientBuilder::new()).build()` is not flagged); added pinning test.
- F-P21-LOW-001: Removed dead `_end: usize` parameter from `has_build_without_timeout`; all 5 call sites updated (TD-VSDD-059).

### Fixed (fix-burst-22, 2026-09-22)
- F-P20-HIGH-001: `find_chain_end` bounded forward scan to base-call ident path; function-reference base call no longer skips following statements
- F-P20-HIGH-002: `has_build_without_timeout` `*GroupEnd` at depth-0 now terminates scan (`break`) instead of clamping (`saturating_sub`); inner builder no longer claims outer chain's `.build()`
- F-P20-MED-001: doc comments reconciled; added 3 regression tests

### Fixed (fix-burst-21, 2026-09-22)
- F-P19-HIGH-001: `has_build_without_timeout` added depth guard (brace/bracket/paren depth-0 check) on `.timeout()` crediting; nested inner builder's `.timeout()` no longer credited to outer chain; added 3 regression tests

### Fixed (fix-burst-20, 2026-09-22)
- F-P18-HIGH-001: has_build_without_timeout now terminates at first depth-0 .build() — eliminates cross-chain verdict leakage where a compliant chain's timeout credited a violating chain
- F-P18-MED-002: ParenGroupEnd variant added to FlatToken; paren_depth counter prevents vec!(x;n) semicolons from terminating the chain scan

### Fixed (fix-burst-19, 2026-09-22)
- F-P17-MED-001/MED-002: evidence-report.md AC-017 counts updated to 14/17, 14th violation class added, validity criterion extended with fixture-directory clause (c)
- F-P17-MED-003: BracketGroup/BracketGroupEnd depth tracking in has_build_without_timeout — vec![..;n] repeat `;` no longer terminates chain scan
- F-P17-MED-004: Leading `::` skip before post-`for` ident collection in check_impl_deref and check_impl_display_in_tokens
- F-P17-LOW-005: Exempt-direction tests for assert_eq!/assert_ne!/assert_matches! 3-arg form with BC-ID in message
- F-P17-LOW-006: CREDENTIAL_FIXTURE_COUNT doc comment ratio updated to 14/17
- F-P17-OBS-007: KNOWN-LIMITATION added to syn_macro_has_bc_id for turbofish comma counting

### Fixed (fix-burst-18, 2026-09-22)
- F-P16-MED-001: `syn_macro_has_bc_id` made arity-aware — `assert_eq!`/`assert_ne!`/`assert_matches!` now require BC-ID in message (3rd argument), not comparand; new violation fixture and test added
- F-P16-MED-002: `has_build_without_timeout` brace-depth tracking via `BraceGroupEnd` variant prevents brace-group arguments from terminating the scan before `.build()` is reached
- F-P16-MED-005: `test_BC_2_14_003_programmer_error_guards_compliant` assertion message corrected — `panic!()` removed as an acceptable guard form (it is unconditionally flagged with no Exemption-2 path)
- F-P16-LOW-006: `check_impl_deref` and `check_impl_display_in_tokens` post-`for` ident-collection loops stop at `where` clause boundary; two regression tests added

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
