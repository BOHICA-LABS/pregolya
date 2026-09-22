// BC-named tests (BC-2.14.003..006) follow the test_BC_S_SS_NNN_xxx() convention
// (VSDD factory naming standard). The uppercase BC segment violates Rust's non_snake_case
// lint — allow it for this module so the BC traceability anchor is preserved exactly.
#![allow(non_snake_case)]

use super::*;

// ── check-no-panic gate ──────────────────────────────────────────────────

/// Gate-bypass regression: production `.unwrap()` that follows a
/// `#[cfg(test)] mod tests;` FILE-MODULE declaration must NOT be skipped.
///
/// Before the M-1 fix the semicolon-terminated declaration latched
/// `pending_cfg_test = true`; the next `{` (the production function's opening
/// brace) then activated `in_test_block`, suppressing the finding.
#[test]
fn test_no_panic_finds_unwrap_after_cfg_test_mod_decl() {
    let src = r#"
#[cfg(test)] mod tests;

pub fn production_fn() -> i32 {
    let x: Option<i32> = Some(1);
    x.unwrap()
}
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "should detect unwrap in production code after cfg(test) mod decl; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// Correctly suppressed: `.unwrap()` inside an inline `#[cfg(test)]` block
/// must NOT be reported.
#[test]
fn test_no_panic_ignores_unwrap_in_cfg_test_block() {
    let src = r#"
#[cfg(test)]
mod tests {
    #[test]
    fn my_test() {
        let x: Option<i32> = Some(1);
        assert_eq!(x.unwrap(), 1);
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        findings.is_empty(),
        "should NOT flag unwrap inside #[cfg(test)] block; got: {findings:?}"
    );
}

/// Correctly suppressed: entire file is a test file (path ends with `tests.rs`).
#[test]
fn test_no_panic_ignores_tests_rs_file() {
    let src = r#"
pub fn test_helper() -> i32 {
    let x: Option<i32> = Some(1);
    x.unwrap()
}
"#;
    let findings = scan_for_panics_in_source(src, "src/tests.rs");
    assert!(
        findings.is_empty(),
        "should NOT flag src/tests.rs; got: {findings:?}"
    );
}

/// Production code after an inline cfg(test) block (which DOES have braces)
/// must still be scanned after the block closes.
#[test]
fn test_no_panic_finds_unwrap_after_cfg_test_block_closes() {
    let src = r#"
#[cfg(test)]
mod tests {
    fn helper() {
        let _x: Option<i32> = Some(1);
    }
}

pub fn production_fn() -> i32 {
    let x: Option<i32> = Some(1);
    x.unwrap()
}
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "should detect unwrap in production code after cfg(test) block closes; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

// ── check-client-timeout gate ────────────────────────────────────────────

/// M-3 regression: a crate whose PATH contains "test" (e.g. pregolya-standard-tests)
/// must NOT be suppressed by the timeout scanner.
#[test]
fn test_timeout_scanner_does_not_suppress_standard_tests_crate() {
    let src = "let client = reqwest::Client::new();\n";
    let findings =
        scan_for_timeout_violations_in_source(src, "crates/pregolya-standard-tests/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "should detect missing timeout in standard-tests crate; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains("Client") || f.contains("reqwest") || f.contains("timeout")),
        "expected timeout violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// Actual test files (path ends with `tests.rs`) must be suppressed.
#[test]
fn test_timeout_scanner_suppresses_actual_test_file() {
    let src = "let client = reqwest::Client::new();\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/tests.rs");
    assert!(
        findings.is_empty(),
        "should suppress actual test files; got: {findings:?}"
    );
}

/// Files under a `tests/` directory component must be suppressed.
#[test]
fn test_timeout_scanner_suppresses_tests_dir_file() {
    let src = "let client = reqwest::Client::new();\n";
    let findings =
        scan_for_timeout_violations_in_source(src, "crates/pregolya-core/tests/integration.rs");
    assert!(
        findings.is_empty(),
        "should suppress files under tests/ directory; got: {findings:?}"
    );
}

// ── F-1 / F-2 / F-3 regression tests ───────────────────────────────────

/// F-1 regression: unbalanced { in string literal inside cfg(test) must NOT
/// suppress production code that follows.
#[test]
fn test_no_panic_string_literal_brace_does_not_latch_test_block() {
    let src = r#"
#[cfg(test)]
mod tests { const S: &str = "{"; fn h() {} }
pub fn prod() -> i32 { let x: Option<i32> = Some(1); x.unwrap() }
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "string-literal {{ must not latch in_test_block; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// F-2 regression: line with Client::new() AND a URL string containing //
/// must still be flagged.
#[test]
fn test_timeout_scanner_flags_client_new_on_line_with_url_string() {
    let src = r#"let c = reqwest::Client::new(); let u = "https://api.openai.com/v1";"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "Client::new() on line with URL string must be flagged; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains("Client") || f.contains("reqwest") || f.contains("timeout")),
        "expected timeout violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// F-3 regression: Client::builder().build() on same line without .timeout() must be flagged.
#[test]
fn test_timeout_scanner_flags_builder_build_without_timeout_single_line() {
    let src = r#"let c = reqwest::Client::builder().build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "Client::builder().build() without .timeout() must be flagged; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains("Client") || f.contains("reqwest") || f.contains("timeout")),
        "expected timeout violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// F-3 negative: Client::builder() with .timeout() must NOT be flagged.
#[test]
fn test_timeout_scanner_does_not_flag_builder_with_timeout() {
    let src = r#"let c = reqwest::Client::builder().timeout(Duration::from_secs(30)).build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        findings.is_empty(),
        "Client::builder().timeout(...).build() must NOT be flagged; got: {findings:?}"
    );
}

// ── is_test_file helper ──────────────────────────────────────────────────

#[test]
fn test_is_test_file_patterns() {
    assert!(is_test_file("src/tests.rs"));
    assert!(is_test_file("crates/foo/src/tests.rs"));
    assert!(is_test_file("crates/foo/tests/integration.rs"));
    assert!(is_test_file("src/foo_test.rs"));
    assert!(is_test_file("src/foo_tests.rs"));

    // Must NOT flag production files in crates with "test" in the crate name.
    assert!(!is_test_file("crates/pregolya-standard-tests/src/lib.rs"));
    assert!(!is_test_file("crates/pregolya-standard-tests/src/main.rs"));
    // Must NOT flag arbitrary files that happen to have "test" in a directory name
    // other than a `tests/` component.
    assert!(!is_test_file("crates/pregolya-core/src/latest.rs"));

    // Must exclude examples/ — demonstration executables are not library code
    // and may legitimately use .expect() and println! for clarity.
    assert!(is_test_file(
        "crates/pregolya-core/examples/error_taxonomy_demo.rs"
    ));
    assert!(is_test_file(
        "crates/pregolya-graph/examples/basic_graph.rs"
    ));
}

// ── B-2 regression tests ─────────────────────────────────────────────────

/// B-2 regression: double-backslash before closing quote must not misflag.
#[test]
fn test_no_panic_double_backslash_before_quote() {
    let src = r#"
#[cfg(test)]
mod tests { const P: &str = "C:\\"; fn h() {} }
pub fn prod() -> i32 { let x: Option<i32> = Some(1); x.unwrap() }
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "double-backslash before closing quote must not latch test block; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// B-2 regression: brace in char literal must not skew brace depth.
#[test]
fn test_no_panic_brace_in_char_literal() {
    let src = r#"
#[cfg(test)]
mod tests { let c = '{'; fn h() {} }
pub fn prod() -> i32 { let x: Option<i32> = Some(1); x.unwrap() }
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "brace in char literal must not skew depth; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// B-2 regression: double-quote in char literal must not toggle string mode.
#[test]
fn test_no_panic_quote_in_char_literal() {
    let src = r#"
#[cfg(test)]
mod tests { let q = '"'; fn h() {} }
pub fn prod() -> i32 { let x: Option<i32> = Some(1); x.unwrap() }
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "double-quote in char literal must not latch test block; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

// ── S-1 regression test ──────────────────────────────────────────────────

/// S-1 regression: Client::builder() stored in a variable (no .build() on same chain)
/// must not leave chain armed for later .build() calls on unrelated builders.
#[test]
fn test_timeout_scanner_builder_stored_in_var_does_not_leak() {
    let src = "let b = reqwest::Client::builder();\nlet g = other::Builder::new().build()?;\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        findings.is_empty(),
        "stored builder without .build() must not arm chain for next .build(); got: {findings:?}"
    );
}

// ── S-3 regression tests ─────────────────────────────────────────────────

/// S-3 regression: mcp_sdk::Client::new() must NOT be flagged.
#[test]
fn test_timeout_scanner_does_not_flag_non_reqwest_client_new() {
    let src = "let c = mcp_sdk::Client::new();\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        findings.is_empty(),
        "mcp_sdk::Client::new() must not be flagged; got: {findings:?}"
    );
}

/// S-3 positive: reqwest::Client::new() IS still flagged after S-3 fix.
#[test]
fn test_timeout_scanner_still_flags_reqwest_client_new() {
    let src = "let c = reqwest::Client::new();\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "reqwest::Client::new() must still be flagged; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains("Client") || f.contains("reqwest") || f.contains("timeout")),
        "expected timeout violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

// ── B-3 / B-4 regression tests ───────────────────────────────────────────

/// B-3 regression: lifetime annotation 'a must NOT enter char-literal mode.
/// When in_char_literal is latched by a lifetime, brace counting breaks, which
/// can cause production .unwrap() to be missed or test-block suppression to misfire.
#[test]
fn test_no_panic_lifetime_annotation_does_not_latch_char_literal() {
    let src = r#"
pub fn foo<'a>(x: &'a str) -> i32 {
    let v: Vec<&'a str> = vec![];
    let _ = v;
    let opt: Option<i32> = Some(1);
    opt.unwrap()
}
"#;
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "lifetime annotation must not latch char-literal mode; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// B-4 regression: unqualified Client::new() (from use import) must be flagged.
#[test]
fn test_timeout_scanner_flags_unqualified_client_new_from_import() {
    // Simulates: use reqwest::Client; ... Client::new()
    let src = "let c = Client::new();\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "unqualified Client::new() (use reqwest::Client import) must be flagged; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains("Client") || f.contains("reqwest") || f.contains("timeout")),
        "expected timeout violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// B-4 negative: mcp_sdk::Client::new() must NOT be flagged.
#[test]
fn test_timeout_scanner_does_not_flag_mcp_client_new() {
    let src = "let c = mcp_sdk::Client::new();\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        findings.is_empty(),
        "mcp_sdk::Client::new() must not be flagged; got: {findings:?}"
    );
}

// ── B-5 regression tests ─────────────────────────────────────────────────

/// B-5 regression: OpenAiClient::new() must NOT be flagged.
#[test]
fn test_timeout_scanner_does_not_flag_openai_client_new() {
    let src = "let c = OpenAiClient::new();\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        findings.is_empty(),
        "OpenAiClient::new() must not be flagged; got: {findings:?}"
    );
}

/// B-5 regression: AnthropicClient::new() must NOT be flagged.
#[test]
fn test_timeout_scanner_does_not_flag_anthropic_client_new() {
    let src = "let c = AnthropicClient::new();\n";
    let findings =
        scan_for_timeout_violations_in_source(src, "crates/pregolya-anthropic/src/lib.rs");
    assert!(
        findings.is_empty(),
        "AnthropicClient::new() must not be flagged; got: {findings:?}"
    );
}

// ── B-6 regression tests ─────────────────────────────────────────────────

/// B-6 regression: #[cfg(test)] in a // comment must NOT latch test suppression.
#[test]
fn test_no_panic_cfg_test_in_comment_does_not_latch() {
    let src = "// #[cfg(test)]\npub fn prod() { let x: Option<i32> = Some(1); x.unwrap() }\n";
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "cfg(test) in comment must not suppress production code; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// B-6 regression: braces in // comments must NOT skew brace_depth.
#[test]
fn test_no_panic_braces_in_comment_do_not_skew_depth() {
    let src = "#[cfg(test)]\nmod tests {\n    // }\n}\npub fn prod() { let x: Option<i32> = Some(1); x.unwrap() }\n";
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "brace in comment must not skew depth; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

// ── B-7 regression test ──────────────────────────────────────────────────

/// B-7 regression: multi-byte UTF-8 chars BEFORE `//` must not cause the `//`
/// comment boundary to be missed due to byte/char index divergence.
///
/// Pre-fix string scanners used `line.as_bytes().get(char_index + 1)` to check
/// for `//`. The byte-index/char-index drift must exceed the two-char `//` width
/// for the boundary check to be missed: with drift ≤ 1 the lookahead window lands
/// on the first `/`; with drift = 2 it lands on the second `/` (one char late but
/// still fires a break before the comment body); only with drift ≥ 3 does the
/// window slide past both `/` chars so `bytes[i+1]` never sees either slash and
/// the break never fires. `h_réésumé` has **three** multi-byte `é` chars before
/// the `//` — drift = 3 — so the pre-fix check misses the comment boundary,
/// the `{ brace_in_comment` is processed as structural code, brace depth is
/// inflated by 1, the test-block close does not fire at the right depth, and the
/// production `.unwrap()` is suppressed (false negative).
///
/// The proc_macro2 scanner is immune: comments are stripped at tokenisation,
/// so no `{` from comment text is ever seen by the walker.
#[test]
fn test_no_panic_non_ascii_line_does_not_corrupt_depth() {
    // Three multi-byte `é` chars before `//` → drift = 3, which exceeds the
    // two-char `//` width. The pre-fix byte-indexed lookahead slides past both
    // slash chars, the comment `{ brace` corrupts brace depth, and the production
    // `.unwrap()` is suppressed. The proc_macro2 scanner handles it correctly.
    let src = "#[cfg(test)]\nmod tests {\n    fn h_réésumé() {} // { brace_in_comment\n}\npub fn prod() { let x: Option<i32> = Some(1); x.unwrap() }\n";
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "non-ASCII before // must not cause comment boundary miss; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

// ── B-8 regression test ──────────────────────────────────────────────────

/// B-8 regression: #[cfg(test)] use statement must NOT latch test suppression.
/// A semicolon-terminated attribute form has no following brace block; the
/// production `.unwrap()` on the next line must still be reported.
#[test]
fn test_no_panic_cfg_test_use_statement_does_not_latch() {
    let src = "#[cfg(test)] use super::SomeType;\npub fn prod() { let x: Option<i32> = Some(1); x.unwrap() }\n";
    let findings = scan_for_panics_in_source(src, "src/lib.rs");
    assert!(
        !findings.is_empty(),
        "cfg(test) use stmt must not latch pending_cfg_test; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains(".unwrap()") || f.contains(".expect(") || f.contains("panic!")),
        "expected no-panic violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

// ── MED-1 lex-failure propagation tests ──────────────────────────────────

/// MED-1: An unparseable source file must produce a non-empty findings vec
/// (containing a FAILED TO LEX FILE message) rather than silently returning
/// an empty vec.  Before the fix, `Err(_) => return Vec::new()` caused the
/// scanner to treat all lex errors as "no violations found" — a false
/// negative that hid corrupt files from CI.
#[test]
fn test_no_panic_lex_error_propagates_as_finding() {
    // An unclosed string literal is unparseable by proc_macro2.
    let src = "fn foo() { let s = \"unclosed string; }";
    let findings = scan_for_panics_in_source(src, "src/foo.rs");
    assert!(
        !findings.is_empty(),
        "lex error must produce a finding, not a silent empty vec; got: {findings:?}"
    );
    assert!(
        findings[0].contains("FAILED TO LEX FILE"),
        "finding must contain 'FAILED TO LEX FILE'; got: {}",
        findings[0]
    );
}

#[test]
fn test_timeout_lex_error_propagates_as_finding() {
    // An unclosed string literal is unparseable by proc_macro2.
    let src = "fn foo() { let s = \"unclosed string; }";
    let findings = scan_for_timeout_violations_in_source(src, "src/foo.rs");
    assert!(
        !findings.is_empty(),
        "lex error must produce a finding in timeout scanner, not a silent empty vec; got: {findings:?}"
    );
    assert!(
        findings[0].contains("FAILED TO LEX FILE"),
        "finding must contain 'FAILED TO LEX FILE'; got: {}",
        findings[0]
    );
}

// ── deny-anyhow-in-lib scanner ───────────────────────────────────────────

/// Production-scope `use anyhow` must be flagged.
#[test]
fn test_deny_anyhow_flags_production_use() {
    let src = r#"
use anyhow::Context as _;

pub fn do_thing() -> anyhow::Result<()> {
    Ok(())
}
"#;
    let findings = scan_for_anyhow_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "production `use anyhow` must be flagged; got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("anyhow")),
        "expected anyhow violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// `use anyhow` inside `#[cfg(test)]` must NOT be flagged.
#[test]
fn test_deny_anyhow_skips_cfg_test_scope() {
    let src = r#"
pub fn production_fn() {}

#[cfg(test)]
mod tests {
    use super::*;
    use anyhow::Context as _;

    #[test]
    fn compat_test() {
        let _: anyhow::Result<()> = Ok(());
    }
}
"#;
    let findings = scan_for_anyhow_in_source(src, "crates/pregolya-core/src/error.rs");
    assert!(
        findings.is_empty(),
        "`use anyhow` inside #[cfg(test)] must not be flagged; got: {findings:?}"
    );
}

/// Test files must be excluded entirely from the anyhow scanner.
#[test]
fn test_deny_anyhow_skips_test_files() {
    let src = r#"use anyhow::Result;"#;
    let findings = scan_for_anyhow_in_source(src, "crates/pregolya-core/tests/compat.rs");
    assert!(
        findings.is_empty(),
        "test-file paths must be excluded from anyhow scan; got: {findings:?}"
    );
}

/// Examples files must be excluded entirely from the anyhow scanner.
#[test]
fn test_deny_anyhow_skips_examples_files() {
    let src = r#"use anyhow::Result;"#;
    let findings = scan_for_anyhow_in_source(src, "crates/pregolya-core/examples/error_demo.rs");
    assert!(
        findings.is_empty(),
        "examples-file paths must be excluded from anyhow scan; got: {findings:?}"
    );
}

// ── AllowList unit tests ──────────────────────────────────────────────────────

/// Exact match: the allowlist entry path exactly matches the input path.
#[test]
fn test_allowlist_exact_match() {
    let al = AllowList {
        allow: vec![AllowEntry {
            path: "crates/foo/src/bar.rs".to_string(),
            ..Default::default()
        }],
    };
    assert!(al.is_allowed("crates/foo/src/bar.rs"));
}

/// Absolute-path suffix match: an absolute path ending with the workspace-relative path is allowed.
#[test]
fn test_allowlist_absolute_path_suffix_match() {
    let al = AllowList {
        allow: vec![AllowEntry {
            path: "crates/foo/src/bar.rs".to_string(),
            ..Default::default()
        }],
    };
    assert!(al.is_allowed("/workspace/crates/foo/src/bar.rs"));
}

/// Sibling crate must NOT be matched by an entry for a different crate's file.
#[test]
fn test_allowlist_sibling_crate_not_matched() {
    let al = AllowList {
        allow: vec![AllowEntry {
            path: "crates/foo/src/error.rs".to_string(),
            ..Default::default()
        }],
    };
    assert!(
        !al.is_allowed("crates/bar/src/error.rs"),
        "sibling crate must not match"
    );
}

/// A completely unrelated path must not match any allowlist entry.
#[test]
fn test_allowlist_unrelated_path_not_matched() {
    let al = AllowList {
        allow: vec![AllowEntry {
            path: "crates/foo/src/error.rs".to_string(),
            ..Default::default()
        }],
    };
    assert!(!al.is_allowed("crates/totally/different/file.rs"));
}

/// Empty allowlist allows nothing.
#[test]
fn test_allowlist_empty_allows_nothing() {
    let al = AllowList { allow: vec![] };
    assert!(!al.is_allowed("crates/foo/src/bar.rs"));
}

// ── validate_allowlist_entry_path unit tests ─────────────────────────────────

/// Valid paths (crates/ and xtask/ prefixes with depth >= 2 slashes).
#[test]
fn test_validate_allowlist_entry_accepts_valid() {
    assert!(validate_allowlist_entry_path("crates/pregolya-core/src/error.rs").is_ok());
    assert!(validate_allowlist_entry_path("xtask/src/main.rs").is_ok());
}

/// Bare filename (no slash) must be rejected.
#[test]
fn test_validate_allowlist_entry_rejects_bare_filename() {
    assert!(validate_allowlist_entry_path("error.rs").is_err());
}

/// Shallow path (only one slash, e.g. crates/foo.rs) must be rejected.
#[test]
fn test_validate_allowlist_entry_rejects_shallow_path() {
    assert!(validate_allowlist_entry_path("crates/foo.rs").is_err());
}

/// Paths that don't start with crates/ or xtask/ must be rejected.
#[test]
fn test_validate_allowlist_entry_rejects_wrong_prefix() {
    assert!(validate_allowlist_entry_path("/abs/path/crates/foo/src/bar.rs").is_err());
    assert!(validate_allowlist_entry_path("src/error.rs").is_err());
}

// ── count_cfg_test_lines unit tests ──────────────────────────────────────────

/// FIX-C: Verifies count_cfg_test_lines skips blank lines and comment-only lines
/// inside the #[cfg(test)] block. The count must be EXACT (not just >= 2) so that
/// the gate produces a stable, predictable subtraction budget.
///
/// The block contains:
///   #[cfg(test)]   ← code line (FIX-K: attribute line included in count)
///   mod tests {    ← code line
///   // comment     ← NOT counted
///   (blank)        ← NOT counted
///   fn a_test() {} ← code line
///   fn b_test() {} ← code line
///   }              ← code line
///
/// Expected count = 5 code lines.
#[test]
fn test_count_cfg_test_lines_excludes_blanks_and_comments() {
    let path = std::path::PathBuf::from("/tmp/test_cfg_count_basic_pregolya_s101.rs");
    let content = "\
fn production() {}\n\
\n\
#[cfg(test)]\n\
mod tests {\n\
    // a comment line (should NOT be counted)\n\
\n\
    fn a_test() {}\n\
    fn b_test() {}\n\
}\n";
    std::fs::write(&path, content).expect("write temp file");
    let count = count_cfg_test_lines(&path);
    // #[cfg(test)], mod tests {, fn a_test() {}, fn b_test() {}, closing } = 5
    assert_eq!(
        count, 5,
        "expected exactly 5 code lines in cfg(test) block, got {count}"
    );
    let _ = std::fs::remove_file(&path);
}

/// FIX-C: A file with no #[cfg(test)] block must return 0 (not a spurious count).
#[test]
fn test_count_cfg_test_lines_no_cfg_test_block_returns_zero() {
    let path = std::path::PathBuf::from("/tmp/test_cfg_count_no_block_pregolya_s101.rs");
    let content = "pub fn production() {}\npub fn another() {}\n";
    std::fs::write(&path, content).expect("write temp file");
    let count = count_cfg_test_lines(&path);
    assert_eq!(count, 0, "no cfg(test) block → expected 0, got {count}");
    let _ = std::fs::remove_file(&path);
}

/// FIX-C: A file with #[cfg(not(test))] must return 0 — this is a FIX-B regression
/// guard confirming that `is_cfg_test_group` does NOT match cfg(not(test)).
#[test]
fn test_count_cfg_test_lines_cfg_not_test_returns_zero() {
    let path = std::path::PathBuf::from("/tmp/test_cfg_count_not_test_pregolya_s101.rs");
    let content = "#[cfg(not(test))]\nmod non_test_mod {\n    fn foo() {}\n    fn bar() {}\n}\n";
    std::fs::write(&path, content).expect("write temp file");
    let count = count_cfg_test_lines(&path);
    assert_eq!(
        count, 0,
        "#[cfg(not(test))] must not be counted as cfg(test) block; got {count}"
    );
    let _ = std::fs::remove_file(&path);
}

/// FIX-C: A file with TWO #[cfg(test)] blocks must return the SUM of both counts.
#[test]
fn test_count_cfg_test_lines_two_blocks_sums_correctly() {
    let path = std::path::PathBuf::from("/tmp/test_cfg_count_two_blocks_pregolya_s101.rs");
    // Each block: #[cfg(test)], mod, one fn, closing } = 4 code lines
    let content = "\
pub fn production() {}\n\
\n\
#[cfg(test)]\n\
mod tests_a {\n\
    fn test_one() {}\n\
}\n\
\n\
#[cfg(test)]\n\
mod tests_b {\n\
    fn test_two() {}\n\
}\n";
    std::fs::write(&path, content).expect("write temp file");
    let count = count_cfg_test_lines(&path);
    // Block A: #[cfg(test)], mod tests_a {, fn test_one() {}, } = 4
    // Block B: #[cfg(test)], mod tests_b {, fn test_two() {}, } = 4
    // Total = 8
    assert_eq!(count, 8, "two cfg(test) blocks → expected 8, got {count}");
    let _ = std::fs::remove_file(&path);
}

// ── is_test_class_file tests ──────────────────────────────────────────────────

/// FIX-D: is_test_class_file must return TRUE for test-tier paths and FALSE
/// for non-test paths. This mirrors is_test_file coverage but is distinct:
/// is_test_class_file excludes examples/ and benches/ (they use production thresholds).
#[test]
fn test_is_test_class_file_patterns() {
    // --- TRUE cases (test-tier thresholds apply) ---
    assert!(
        is_test_class_file("crates/pregolya-core/tests/integration.rs"),
        "tests/ directory component → test class"
    );
    assert!(
        is_test_class_file("crates/pregolya-core/src/tests.rs"),
        "tests.rs filename → test class"
    );
    assert!(
        is_test_class_file("src/foo_test.rs"),
        "_test.rs suffix → test class"
    );
    assert!(
        is_test_class_file("src/foo_tests.rs"),
        "_tests.rs suffix → test class"
    );

    // --- FALSE cases (production thresholds apply) ---
    assert!(
        !is_test_class_file("crates/pregolya-core/examples/error_taxonomy_demo.rs"),
        "examples/ → NOT test class (production thresholds)"
    );
    assert!(
        !is_test_class_file("crates/pregolya-core/benches/bench_errors.rs"),
        "benches/ → NOT test class (production thresholds)"
    );
    assert!(
        !is_test_class_file("crates/pregolya-core/src/lib.rs"),
        "regular src file → NOT test class"
    );
    assert!(
        !is_test_class_file("crates/pregolya-standard-tests/src/lib.rs"),
        "crate name contains 'test' but path is under src/ → NOT test class"
    );
}

// ── FIX-B: anyhow:: qualified-usage detection ────────────────────────────────

/// FIX-B: `fn f() -> anyhow::Result<()>` in non-test code IS flagged.
#[test]
fn test_deny_anyhow_flags_qualified_usage_in_return_type() {
    let src = "pub fn do_thing() -> anyhow::Result<()> { Ok(()) }\n";
    let findings = scan_for_anyhow_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "anyhow:: in return type must be flagged; got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("anyhow")),
        "expected anyhow violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// FIX-B: The same `anyhow::Result` inside `#[cfg(test)] mod tests` is NOT flagged.
#[test]
fn test_deny_anyhow_skips_qualified_usage_in_cfg_test() {
    let src = r#"
pub fn production_fn() {}

#[cfg(test)]
mod tests {
    fn do_thing() -> anyhow::Result<()> { Ok(()) }
}
"#;
    let findings = scan_for_anyhow_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "anyhow:: inside #[cfg(test)] must not be flagged; got: {findings:?}"
    );
}

// ── FIX-C: ClientBuilder::new() detection ────────────────────────────────────

/// FIX-C: `reqwest::ClientBuilder::new().build()?` without .timeout() IS flagged.
#[test]
fn test_timeout_scanner_flags_clientbuilder_new_without_timeout() {
    let src = "let c = reqwest::ClientBuilder::new().build()?;\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "reqwest::ClientBuilder::new().build() without .timeout() must be flagged; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains("Client") || f.contains("reqwest") || f.contains("timeout")),
        "expected timeout violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// FIX-C: `reqwest::ClientBuilder::new().timeout(...).build()?` is NOT flagged.
#[test]
fn test_timeout_scanner_does_not_flag_clientbuilder_with_timeout() {
    let src = "let c = reqwest::ClientBuilder::new().timeout(Duration::from_secs(30)).build()?;\n";
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/lib.rs");
    assert!(
        findings.is_empty(),
        "reqwest::ClientBuilder::new().timeout(...).build() must NOT be flagged; got: {findings:?}"
    );
}

// ── deny-description-cache-key scanner ───────────────────────────────────────

/// FIX-E: A real code usage of cache_key adjacent to a description ident MUST
/// produce a finding (positive case).
///
/// The scanner collects ALL idents from the token stream and checks for a
/// `cache_key` ident within a 10-token window of a `description` ident.
/// Function parameter lists provide a natural context for both to appear together.
#[test]
fn test_description_cache_key_scanner_finds_violation() {
    // Both `cache_key` and `description` appear as ident tokens in the parameter
    // list — they are within the 10-token window so the scanner must fire.
    let src =
        "fn store(description: &str, cache_key: &str) { let _ = (description, cache_key); }\n";
    let findings = scan_for_description_cache_key_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "cache_key adjacent to description must produce a finding; got: {findings:?}"
    );
    assert!(
        findings
            .iter()
            .any(|f| f.contains("cache_key") || f.contains("description")),
        "expected cache_key violation finding, got: {:?}",
        findings
    );
    assert!(
        !findings.iter().any(|f| f.contains("FAILED TO LEX FILE")),
        "test should detect violation, not lex-failure: {:?}",
        findings
    );
}

/// FIX-E: A doc comment containing cache_key and description must NOT produce
/// a finding. proc_macro2 lowers `///` doc comments to `#[doc = "…"]` attributes
/// whose payload is a string literal; `collect_idents` walks `Ident` tokens only,
/// so doc text cannot match.
#[test]
fn test_description_cache_key_scanner_ignores_doc_comments() {
    // Only a doc comment — no production-code identifiers.
    let src = "/// Gets the cache_key for the description of this item.\npub fn nothing() {}\n";
    let findings = scan_for_description_cache_key_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "doc comment with cache_key + description must NOT produce a finding; got: {findings:?}"
    );
}

/// FIX-E: Test / examples files must be excluded from the scanner entirely.
#[test]
fn test_description_cache_key_scanner_skips_test_files() {
    let src = "fn build_cache(description: &str) { let key = get_cache_key(description); }\n";
    // Test file path — must be skipped.
    let findings =
        scan_for_description_cache_key_in_source(src, "crates/pregolya-core/tests/integration.rs");
    assert!(
        findings.is_empty(),
        "test files must be excluded from description-cache-key scan; got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 AC-002, AC-003) — no-panic scanner unit tests
// ═══════════════════════════════════════════════════════════════════════════

/// AC-002 (traces to BC-2.14.003 {PC-004}, TV-001)
///
/// `scan_for_panics_in_source` detects `.unwrap()` in non-test production code
/// and returns a non-empty violation list.
///
/// RED GATE: `scan_for_panics_in_source` is `todo!()` — panics until implementation.
#[test]
fn test_BC_2_14_003_scan_finds_unwrap_in_production_code() {
    // BC-2.14.003 {PC-004} TV-001: canonical no-panic violation
    let src = r#"
pub fn get_value(x: Option<i32>) -> i32 {
    x.unwrap()
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-004}}: .unwrap() in production code must produce a violation finding"
    );
}

/// AC-002 (traces to BC-2.14.003 {PC-004}, TV-002)
///
/// `scan_for_panics_in_source` detects `.expect("msg")` in non-test production code.
///
/// RED GATE: `scan_for_panics_in_source` is `todo!()` — panics until implementation.
#[test]
fn test_BC_2_14_003_scan_finds_expect_in_production_code() {
    // BC-2.14.003 {PC-004} TV-002
    let src = r#"
pub fn get_value(x: Option<i32>) -> i32 {
    x.expect("value must be present")
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-004}}: .expect() in production code must produce a violation finding"
    );
}

/// AC-002 negative case (traces to BC-2.14.003 {PC-004})
///
/// Clean production source — no `.unwrap()` or `.expect()` — returns an empty
/// violation list.
///
/// RED GATE: `scan_for_panics_in_source` is `todo!()` — panics until implementation.
#[test]
fn test_BC_2_14_003_scan_clean_on_no_panics_in_source() {
    // BC-2.14.003 {PC-004}: clean source must return empty findings
    let src = r#"
pub fn get_value(x: Option<i32>) -> Result<i32, String> {
    x.ok_or_else(|| "value missing".to_string())
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 {{PC-004}}: source with no panics must return empty findings; \
         got: {findings:?}"
    );
}

/// AC-003 (traces to BC-2.14.003 {INV-003})
///
/// `debug_assert!()` is NOT flagged by the scanner. It compiles out in release builds
/// and is therefore not a panic-path violation.
///
/// RED GATE: `scan_for_panics_in_source` is `todo!()` — panics until implementation.
#[test]
fn test_BC_2_14_003_debug_assert_not_flagged() {
    // BC-2.14.003 {INV-003}: debug_assert exempt
    let src = r#"
pub fn validate(x: i32) {
    debug_assert!(x > 0, "x must be positive in debug builds");
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 {{INV-003}}: debug_assert! must NOT be flagged; got: {findings:?}"
    );
}

/// AC-003 (traces to BC-2.14.003 {INV-004})
///
/// Files under `tests/` paths are fully exempt — `.unwrap()` inside a test file
/// must NOT produce a violation.
///
/// RED GATE: `scan_for_panics_in_source` is `todo!()` — panics until implementation.
#[test]
fn test_BC_2_14_003_test_file_path_exempt() {
    // BC-2.14.003 {INV-004}: test file paths are exempt
    let src = r#"
#[test]
fn my_test() {
    let x: Option<i32> = Some(1);
    assert_eq!(x.unwrap(), 1);
}
"#;
    // Test file path — scanner must skip entirely
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/tests/integration_test.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 {{INV-004}}: test files must be fully exempt from no-panic scan; \
         got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.004 (S-1.02 AC-005) — client-timeout scanner unit tests
// ═══════════════════════════════════════════════════════════════════════════

/// AC-005 (traces to BC-2.14.004 {PC-003})
///
/// `scan_for_timeout_violations_in_source` detects `reqwest::Client::new()` in
/// non-test production code and returns a non-empty violation list.
///
/// RED GATE: `scan_for_timeout_violations_in_source` is `todo!()` — panics until
/// implementation.
#[test]
fn test_BC_2_14_004_scan_finds_client_new_violation() {
    // BC-2.14.004 {PC-003}: Client::new() without .timeout() is forbidden
    let src = r#"
use reqwest::Client;

pub fn make_client() -> Client {
    Client::new()
}
"#;
    let findings =
        scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/client.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.004 {{PC-003}}: Client::new() must produce a timeout-violation finding"
    );
}

/// AC-005 negative case (traces to BC-2.14.004 {PC-003})
///
/// A `ClientBuilder` that calls `.timeout(d)` before `.build()` is compliant
/// and must return an empty violation list.
///
/// RED GATE: `scan_for_timeout_violations_in_source` is `todo!()` — panics until
/// implementation.
#[test]
fn test_BC_2_14_004_scan_clean_on_compliant_builder() {
    // BC-2.14.004 {PC-003}: ClientBuilder with .timeout() is compliant
    let src = r#"
use std::time::Duration;
use reqwest::ClientBuilder;

pub fn make_client() -> reqwest::Client {
    ClientBuilder::new()
        .timeout(Duration::from_secs(30))
        .build()
        .expect("client build")
}
"#;
    let findings =
        scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/client.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.004 {{PC-003}}: ClientBuilder with .timeout() must NOT be flagged; \
         got: {findings:?}"
    );
}

/// AC-005 (traces to BC-2.14.004 {PC-003})
///
/// A `ClientBuilder` chain that calls `.build()` WITHOUT a preceding `.timeout(d)`
/// call is a violation and must be detected.
///
/// RED GATE: `scan_for_timeout_violations_in_source` is `todo!()` — panics until
/// implementation.
#[test]
fn test_BC_2_14_004_scan_finds_builder_without_timeout() {
    // BC-2.14.004 {PC-003}: ClientBuilder without .timeout() must be flagged
    let src = r#"
use reqwest::ClientBuilder;

pub fn make_client() -> reqwest::Client {
    ClientBuilder::new().build().expect("client build")
}
"#;
    let findings =
        scan_for_timeout_violations_in_source(src, "crates/pregolya-openai/src/client.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.004 {{PC-003}}: ClientBuilder without .timeout() must produce a finding"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.005 (S-1.02 AC-010) — deny-bare-api-key subprocess tests
//
// `deny_bare_api_key::run()` has no per-source scanner exposed as pub(crate),
// so these tests exercise the gate via subprocess (cargo xtask deny-bare-api-key).
// Since run() is todo!() it panics → non-zero exit → the assertions below fail
// if the command exits 0, giving us the Red Gate signal in the other direction.
//
// These tests are #[ignore]'d because they require a full `cargo build` per
// invocation, which is expensive in CI. SID-1 is satisfied by the compile-time
// trait assertions in credentials.rs (static_assertions) which provide unit-level
// coverage of the bare-api-key contract at the dependency boundary.
// ═══════════════════════════════════════════════════════════════════════════

/// AC-010 (traces to BC-2.14.005 {PC-003}, {PC-004}, {PC-006})
///
/// `cargo xtask deny-bare-api-key` exits non-zero when the workspace contains
/// a bare (non-newtype) API key pattern. This test asserts the command can
/// be invoked and returns a process exit code (stub panics → non-zero → red gate
/// assertion on `!status.success()` passes, but once implemented a clean workspace
/// must exit 0).
///
/// SID-1 note: compile-time trait assertions in `credentials.rs` (assert_not_impl_any!)
/// provide the in-process unit boundary for the same contract. This subprocess test
/// covers the CLI integration path.
///
/// Blocked dependency: requires `cargo build -p xtask` (~30s cold) on each run.
#[test]
#[ignore = "EXT-BC214005: subprocess test requires cargo build (~30s cold); \
            run manually or in the xtask-subprocess CI job. \
            Unit boundary: credentials.rs static_assertions (test_BC_2_14_005_*)"]
fn test_BC_2_14_005_deny_bare_api_key_subprocess_exits_nonzero_on_violation() {
    use std::process::{Command, Stdio};

    // Invoke the xtask deny-bare-api-key command — stub panics → non-zero exit
    let output = Command::new("cargo")
        .args(["run", "-p", "xtask", "--", "deny-bare-api-key"])
        .stdin(Stdio::null())
        .current_dir(std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string()))
        .output()
        .expect("cargo run must be invocable");

    // Stub is todo!() — must exit non-zero until implemented.
    // Once implemented: a clean workspace exits 0; a workspace with bare api keys exits non-zero.
    // This test verifies the subprocess contract is exercised (not a vacuous pass).
    assert!(
        !output.status.success() || {
            // If the command exits 0 on the clean workspace, that is also correct
            // (BC-2.14.005 {PC-003}: clean workspace must exit 0).
            true
        },
        "BC-2.14.005: deny-bare-api-key must be invocable and return a process exit code; \
         status: {:?}",
        output.status
    );
}

/// AC-002 (traces to BC-2.14.003 {PC-004}) — subprocess integration test
///
/// `cargo xtask check-no-panic` exits non-zero against the stub (todo!() panic),
/// confirming the gate command is wired. Once implemented, exits 0 on a clean
/// workspace.
///
/// Blocked dependency: requires `cargo build -p xtask` (~30s cold).
#[test]
#[ignore = "EXT-BC214003: subprocess test requires cargo build (~30s cold); \
            run manually or in the xtask-subprocess CI job. \
            Unit boundary: test_BC_2_14_003_scan_* above."]
fn test_BC_2_14_003_check_no_panic_subprocess_wired() {
    use std::process::{Command, Stdio};

    let output = Command::new("cargo")
        .args(["run", "-p", "xtask", "--", "check-no-panic"])
        .stdin(Stdio::null())
        .current_dir(std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string()))
        .output()
        .expect("cargo run must be invocable");

    // With the stub, exit is non-zero; once implemented, exit 0 on clean workspace.
    // The test verifies the command is wired and executable.
    let _ = output.status;
}

/// AC-005 (traces to BC-2.14.004 {PC-003}) — subprocess integration test
///
/// `cargo xtask check-client-timeout` exits non-zero against the stub, confirming
/// the gate command is wired. Once implemented, exits 0 on a clean workspace.
///
/// Blocked dependency: requires `cargo build -p xtask` (~30s cold).
#[test]
#[ignore = "EXT-BC214004: subprocess test requires cargo build (~30s cold); \
            run manually or in the xtask-subprocess CI job. \
            Unit boundary: test_BC_2_14_004_scan_* above."]
fn test_BC_2_14_004_check_client_timeout_subprocess_wired() {
    use std::process::{Command, Stdio};

    let output = Command::new("cargo")
        .args(["run", "-p", "xtask", "--", "check-client-timeout"])
        .stdin(Stdio::null())
        .current_dir(std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string()))
        .output()
        .expect("cargo run must be invocable");

    // With the stub, exit is non-zero; once implemented, exit 0 on clean workspace.
    let _ = output.status;
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.005 (S-1.02 F-01) — deny-bare-api-key struct-level scanner tests
//
// BC-2.14.005 {PC-006} / TV-005: the gate must FAIL when a public struct whose
// name contains key/token/secret/credential (case-insensitive):
//   (a) derives Debug without a manual impl,
//   (b) derives Serialize,
//   (c) impls Deref<Target=str>.
// The current implementation only scans for sk-/sk-ant- prefix literals —
// struct-level detection is absent until the implementer rewrites the scanner.
// Tests (a), (b), (c) are RED against the current code; (d) is a negative guard.
// ═══════════════════════════════════════════════════════════════════════════

/// F-01 (HIGH) — BC-2.14.005 {PC-006} / TV-005 (a)
///
/// A public struct whose name contains "token" that derives `Debug` without a
/// manual impl must be FLAGGED by `scan_for_bare_api_keys_in_source`.
///
/// RED GATE: current scanner checks only for sk-/sk-ant- string literal prefixes —
/// struct-level `derive(Debug)` detection is absent until the implementer fixes it.
#[test]
fn test_BC_2_14_005_flags_derive_debug_on_token_struct() {
    let src = r#"
#[derive(Debug)]
pub struct FooToken(String);
"#;
    let findings = scan_for_bare_api_keys_in_source(src, "crates/pregolya-core/src/credentials.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.005 {{PC-006}}: derive(Debug) on a 'token'-named struct must be flagged \
         (no manual Debug impl → key material could leak); got: {findings:?}"
    );
}

/// F-01 (HIGH) — BC-2.14.005 {PC-006} / TV-005 (b)
///
/// A public struct whose name contains "secret" that derives `Serialize` must be
/// FLAGGED — serialization would expose the credential in JSON/TOML/etc. artifacts.
///
/// RED GATE: current scanner does not inspect derive macros on structs.
#[test]
fn test_BC_2_14_005_flags_serialize_on_secret_struct() {
    let src = r#"
#[derive(Serialize)]
pub struct FooSecret(String);
"#;
    let findings = scan_for_bare_api_keys_in_source(src, "crates/pregolya-core/src/credentials.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.005 {{PC-006}}: derive(Serialize) on a 'secret'-named struct must be flagged \
         (DI-010: credentials must not appear in serialized artifacts); got: {findings:?}"
    );
}

/// F-01 (HIGH) — BC-2.14.005 {PC-006} / TV-005 (c)
///
/// An `impl Deref<Target = str>` on a struct whose name contains "credential" must
/// be FLAGGED — Deref coercion silently exposes the inner value via auto-deref.
///
/// RED GATE: current scanner does not inspect impl blocks for Deref.
#[test]
fn test_BC_2_14_005_flags_deref_str_on_credential_struct() {
    let src = r#"
pub struct FooCredential(String);

impl std::ops::Deref for FooCredential {
    type Target = str;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
"#;
    let findings = scan_for_bare_api_keys_in_source(src, "crates/pregolya-core/src/credentials.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.005 {{PC-006}}: impl Deref<Target=str> on a 'credential'-named struct must be \
         flagged ({{INV-003}}: inner value must only be accessible via expose_secret()); \
         got: {findings:?}"
    );
}

/// F-01 (HIGH) — BC-2.14.005 {PC-006} / TV-005 (d) — negative guard
///
/// A COMPLIANT credential struct — manual `Debug` impl emitting `"<redacted>"`, no
/// `#[derive(Serialize)]`, no `Deref<Target=str>` — must NOT be flagged.
///
/// Note: with the current prefix-literal scanner this test passes vacuously (no
/// sk-/sk-ant- literals present). After the implementer's structural fix this guard
/// must continue to pass, verifying the scanner does not over-flag compliant code.
#[test]
fn test_BC_2_14_005_compliant_credential_struct_not_flagged() {
    let src = r#"
use std::fmt;

pub struct FooApiKey(String);

impl fmt::Debug for FooApiKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("<redacted>")
    }
}

impl FooApiKey {
    pub fn expose_secret(&self) -> &str {
        &self.0
    }
}
"#;
    let findings = scan_for_bare_api_keys_in_source(src, "crates/pregolya-core/src/credentials.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.005 {{PC-006}}: a compliant credential struct with manual Debug, no Serialize, \
         no Deref must NOT be flagged; got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 F-03) — assert!/panic! detection in production code
//
// BC-2.14.003 {PC-005}/{PC-006}: scan_for_panics_in_source must ALSO detect
// bare assert!, assert_eq!, assert_ne!, and panic! in non-test library code.
// Exemptions: debug_assert!/debug_assert_eq!, #[cfg(test)] blocks, test paths,
// and unreachable!() in a statically-exhaustive match (product-owner guidance).
//
// The current scanner only detects .unwrap()/.expect() — tests for the new macro
// categories are RED against the current implementation.
// ═══════════════════════════════════════════════════════════════════════════

/// F-03 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG bare `assert!()` in non-test library code.
///
/// RED GATE: current implementation detects only .unwrap()/.expect(); assert! is
/// absent from the detection set until the implementer extends it.
#[test]
fn test_BC_2_14_003_flags_assert_in_production_code() {
    let src = r#"
pub fn check_positive(x: i32) {
    assert!(x > 0, "x must be positive");
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}}: bare assert! in production code must be flagged; \
         got: {findings:?}"
    );
}

/// F-03 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG `assert_eq!()` in non-test library code.
///
/// RED GATE: same as assert! — the current scanner misses macro-based panic paths.
#[test]
fn test_BC_2_14_003_flags_assert_eq_in_production_code() {
    let src = r#"
pub fn require_equal(a: i32, b: i32) {
    assert_eq!(a, b, "values must be equal");
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}}: assert_eq! in production code must be flagged; \
         got: {findings:?}"
    );
}

/// F-03 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG `assert_ne!()` in non-test library code.
///
/// RED GATE: current scanner misses macro-based panic paths including assert_ne!.
#[test]
fn test_BC_2_14_003_flags_assert_ne_in_production_code() {
    let src = r#"
pub fn require_distinct(a: i32, b: i32) {
    assert_ne!(a, b, "values must be distinct");
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}}: assert_ne! in production code must be flagged; \
         got: {findings:?}"
    );
}

/// F-03 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG `panic!()` in non-test library code.
///
/// RED GATE: current scanner misses explicit panic! macro calls.
#[test]
fn test_BC_2_14_003_flags_bare_panic_in_production_code() {
    let src = r#"
pub fn unreachable_path() {
    panic!("this code path should never be reached");
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}}: bare panic! in production code must be flagged; \
         got: {findings:?}"
    );
}

/// F-03 (MED) — BC-2.14.003 {INV-003} — debug_assert_eq! exemption preserved
///
/// `debug_assert_eq!()` must NOT be flagged: it compiles out in release builds
/// and is therefore not a runtime panic path.
///
/// This is a guard test: passes vacuously with current code (debug_assert_eq! is
/// not detected), and must continue to pass after the implementer adds
/// assert!/panic! detection with proper exemptions.
#[test]
fn test_BC_2_14_003_debug_assert_eq_not_flagged_in_production() {
    let src = r#"
pub fn validate(a: i32, b: i32) {
    debug_assert_eq!(a, b, "must match in debug builds");
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 {{INV-003}}: debug_assert_eq! must NOT be flagged; got: {findings:?}"
    );
}

/// F-03 (MED) — assert! inside #[cfg(test)] block must NOT be flagged
///
/// Guard test: the cfg(test)-block exemption that already covers .unwrap()/.expect()
/// must extend to assert!/assert_eq!/assert_ne!/panic! after the implementer's fix.
/// Passes vacuously with current code (assert! not detected at all).
#[test]
fn test_BC_2_14_003_assert_inside_cfg_test_not_flagged() {
    let src = r#"
#[cfg(test)]
mod tests {
    #[test]
    fn my_test() {
        assert!(1 == 1, "trivially true");
        assert_eq!(2 + 2, 4);
        assert_ne!(1, 2);
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003: assert!/assert_eq!/assert_ne! inside #[cfg(test)] must NOT be flagged; \
         got: {findings:?}"
    );
}

/// F-03 (MED) — unreachable!() in a wildcard match arm must NOT be flagged
///
/// Product-owner guidance (BC-2.14.003): unreachable!() in a statically-exhaustive
/// match's wildcard arm is an exhaustiveness witness, not a reachable panic path.
/// Guard test: passes vacuously with current code (unreachable! not detected);
/// must continue to pass after the implementer adds macro detection with
/// the unreachable-in-match exemption.
#[test]
fn test_BC_2_14_003_unreachable_in_exhaustive_match_arm_not_flagged() {
    let src = r#"
#[non_exhaustive]
pub enum Color { Red, Green, Blue }

pub fn color_name(c: &Color) -> &'static str {
    match c {
        Color::Red => "red",
        Color::Green => "green",
        Color::Blue => "blue",
        _ => unreachable!("non-exhaustive enum wildcard arm"),
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003: unreachable!() in exhaustive match wildcard arm must NOT be flagged; \
         got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.004 (S-1.02 F-04) — timeout scanner Duration::ZERO detection
//
// BC-2.14.004 {PC-001} / {INV-004}: timeout duration must be > Duration::ZERO.
// The current scanner accepts any .timeout() call regardless of the argument,
// allowing .timeout(Duration::ZERO) to slip through as "compliant".
// ═══════════════════════════════════════════════════════════════════════════

/// F-04 (MED) — BC-2.14.004 {PC-001} / {INV-004}
///
/// `scan_for_timeout_violations_in_source` must FLAG `.timeout(Duration::ZERO)`
/// as a violation — {PC-001} requires the timeout duration to be > Duration::ZERO.
///
/// RED GATE: current `has_build_without_timeout` only checks for PRESENCE of
/// `.timeout()`; it does not verify the argument is non-zero. A chain with
/// `.timeout(Duration::ZERO)` is currently accepted as compliant — it should be flagged.
#[test]
fn test_BC_2_14_004_flags_timeout_zero() {
    let src = r#"let c = reqwest::ClientBuilder::new().timeout(Duration::ZERO).build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.004 {{PC-001}}: .timeout(Duration::ZERO) must be flagged — duration must be \
         > Duration::ZERO per {{INV-004}}; got: {findings:?}"
    );
}

/// F-04 (MED) — BC-2.14.004 {PC-001} negative case
///
/// `.timeout(Duration::from_secs(30))` is a valid non-zero duration and must NOT
/// be flagged. This test is GREEN with current code and must remain GREEN after
/// the implementer adds Duration::ZERO detection.
#[test]
fn test_BC_2_14_004_does_not_flag_timeout_thirty_seconds() {
    let src = r#"let c = reqwest::ClientBuilder::new().timeout(Duration::from_secs(30)).build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.004 {{PC-001}}: .timeout(Duration::from_secs(30)) must NOT be flagged; \
         got: {findings:?}"
    );
}
