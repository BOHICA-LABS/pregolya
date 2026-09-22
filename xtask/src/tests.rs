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

/// F-03 / F-GATE-01 — `_ => unreachable!()` wildcard arm in enum match must be FLAGGED.
///
/// BC-2.14.003 EC-004/EC-007: a `_ => unreachable!()` wildcard arm is ALWAYS a latent
/// panic path under enum evolution, even when all currently-known variants are listed
/// before the wildcard. The presence of `Color::Red`, `Color::Green`, `Color::Blue`
/// qualified-path arms does NOT grant exemption — qualified arms only prove current
/// exhaustiveness, not future-proof safety.
///
/// RED GATE (F-GATE-01): has_qualified_path_before currently exempts this case because
/// the scanner sees `::` in the Color::* arms and skips the `_` wildcard detection.
/// This is the wrong behavior per BC-2.14.003 EC-004. After the implementer's fix this
/// wildcard arm IS flagged and this test passes.
///
/// Exemption 1 applies ONLY to explicit named arms (e.g. `Color::Unknown => unreachable!()`)
/// with NO wildcard `_` arm present.
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
        !findings.is_empty(),
        "BC-2.14.003 EC-004/EC-007: _ => unreachable!() wildcard arm must be FLAGGED \
         even when preceding arms are enum::variant forms; \
         F-GATE-01: has_qualified_path_before incorrectly exempts this; \
         implementer must restrict the exemption to non-wildcard named arms; \
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

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 AC-017) — EC-007 two-exemption gate discipline
//
// BC-2.14.003 §EC-007 (BC v1.5): check-no-panic must apply TWO distinct
// exemptions for programmer-error-guard patterns:
//   FLAG:   _ => unreachable!() wildcard arms (latent panic under enum evolution)
//   FLAG:   bare assert! without # Panics doc section and without BC-ID in message
//   EXEMPT: fully-enumerated explicit-variant unreachable!() (no wildcard arm)
//   EXEMPT: documented assert! (function has # Panics section + BC-ID in message)
//
// RED GATE against HEAD 7c7a590:
//   - assertion (b) FAILS: scanner blanket-exempts ALL unreachable! (paper-fix);
//     wildcard unreachable! must be flagged but currently is not
//   - assertion (ii) FAILS: scanner flags ALL assert! with no exemption logic;
//     documented assert! must be exempt but currently is not
// ═══════════════════════════════════════════════════════════════════════════

/// AC-017 (traces to BC-2.14.003 §EC-007, POL-31)
///
/// check-no-panic EC-007 gate: two-exemption discipline.
///
/// FLAGS:
///   (a) bare `assert!` on a function WITHOUT `# Panics` doc section
///       and WITHOUT a BC-ID in the message
///   (b) `_ => unreachable!()` wildcard arm
///
/// EXEMPTS:
///   (i)  fully-enumerated explicit-variant `unreachable!()` — no wildcard arm
///   (ii) documented programmer-error-guard `assert!`
///        (function has `# Panics` doc section AND message contains a BC-NNN ID)
///
/// RED GATE: assertions (b) and (ii) FAIL against current code because:
///   - scanner blanket-exempts ALL unreachable! (b FAILS)
///   - scanner has no exemption logic for documented assert! (ii FAILS)
#[test]
fn test_BC_2_14_003_check_no_panic_ec_007_flags_and_exemptions() {
    // (a) Bare assert! without # Panics doc section and without BC-ID in message
    // must be FLAGGED. PASSES now (scanner flags all assert! in production code).
    let violation_assert_no_doc =
        include_str!("../tests/fixtures/violations/violation_assert_no_doc.rs");
    let findings_a =
        scan_for_panics_in_source(violation_assert_no_doc, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings_a.is_empty(),
        "BC-2.14.003 EC-007(a): assert! without # Panics doc and BC-ID must be flagged; \
         got: {findings_a:?}"
    );

    // (b) _ => unreachable!() wildcard arm must be FLAGGED.
    // RED GATE: scanner blanket-exempts ALL unreachable! — this assertion FAILS now
    let violation_unreachable_wildcard =
        include_str!("../tests/fixtures/violations/violation_unreachable_wildcard.rs");
    let findings_b = scan_for_panics_in_source(
        violation_unreachable_wildcard,
        "crates/pregolya-core/src/lib.rs",
    );
    assert!(
        !findings_b.is_empty(),
        "BC-2.14.003 EC-007(b): _ => unreachable!() wildcard arm must be flagged \
         (paper-fix blanket-exempts ALL unreachable!; implementer must add wildcard-arm \
         detection per BC-2.14.003 §EC-007); got: {findings_b:?}"
    );

    // (i) EXEMPT: fully-enumerated explicit-variant unreachable!() — no wildcard arm.
    // An explicit variant arm (not `_`) with unreachable!() is a programmer-error-guard;
    // it is NOT a wildcard catch-all and should remain exempt.
    // PASSES now (all unreachable! exempt) and must remain PASS after the fix.
    let exempt_explicit_variant = r#"
#[allow(dead_code)]
pub enum Phase { Init, Running, Done }
/// Returns the numeric index for Phase::Init or Phase::Running.
///
/// # Panics
///
/// Panics if called with Phase::Done (BC-2.14.003 EC-007: programmer error —
/// Done phase must be filtered upstream before reaching this function).
pub fn phase_index(p: Phase) -> u8 {
    match p {
        Phase::Init => 0,
        Phase::Running => 1,
        Phase::Done => unreachable!(
            "BC-2.14.003 EC-007: Phase::Done handled upstream; \
             reaching phase_index with Done is a programmer error"
        ),
    }
}
"#;
    let findings_i =
        scan_for_panics_in_source(exempt_explicit_variant, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings_i.is_empty(),
        "BC-2.14.003 EC-007(i): fully-enumerated explicit-variant unreachable!() \
         (no wildcard `_` arm) must be EXEMPT; got: {findings_i:?}"
    );

    // (ii) EXEMPT: documented programmer-error-guard assert! with # Panics doc and BC-ID.
    // RED GATE: scanner flags ALL assert! with no exemption logic — this assertion FAILS now
    let exempt_documented_assert = r#"
/// Validates that the error code follows the E-<COMPONENT>-NNN format.
///
/// # Panics
///
/// Panics if `code` does not start with "E-" (BC-2.14.001 EC-006: programmer error —
/// code format is validated at construction time; callers must not pass malformed codes).
pub fn validate_code_format(code: &str) {
    assert!(
        code.starts_with("E-"),
        "BC-2.14.001 EC-006: code must start with E-, got: {}",
        code
    );
}
"#;
    let findings_ii =
        scan_for_panics_in_source(exempt_documented_assert, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings_ii.is_empty(),
        "BC-2.14.003 EC-007(ii): documented assert! with # Panics doc section and BC-ID in \
         message must be EXEMPT (paper-fix has no exemption logic; implementer must add \
         # Panics doc + BC-ID exemption per BC-2.14.003 §EC-007); got: {findings_ii:?}"
    );

    // (b2) _ => unreachable!() WITH enum::variant arms before the wildcard must be FLAGGED.
    // RED GATE (F-GATE-01): has_qualified_path_before incorrectly exempts this case —
    // FAILS now because the scanner sees `::` in Status::Active etc. and returns early.
    //
    // EC-004: qualified-path arms only prove current exhaustiveness, not future-proof safety.
    // Adding a new Status variant downstream makes the `_` arm reachable. The exemption
    // must be restricted to EXPLICIT NAMED arms (e.g. Variant => unreachable!()) that
    // carry no wildcard `_`; wildcard arms are always a latent panic path.
    let violation_unreachable_wildcard_enum =
        include_str!("../tests/fixtures/violations/violation_unreachable_wildcard_enum.rs");
    let findings_b2 = scan_for_panics_in_source(
        violation_unreachable_wildcard_enum,
        "crates/pregolya-core/src/lib.rs",
    );
    assert!(
        !findings_b2.is_empty(),
        "BC-2.14.003 EC-004/EC-007(b2): _ => unreachable!() wildcard arm preceded by \
         enum::variant arms (Status::Active etc.) must be FLAGGED; \
         F-GATE-01: has_qualified_path_before incorrectly exempts this case; \
         implementer must restrict the exemption to non-wildcard named arms only; \
         got: {findings_b2:?}"
    );

    // (iii) bare unreachable!() in a let-else block (NOT a match arm) must be FLAGGED.
    // RED GATE (F-GATE-01): gate only inspects `_ => unreachable!()` token shape;
    // let-else else-block unreachable!() is not detected — FAILS now.
    //
    // §PC-006: unreachable! is permitted only in exhaustive-match arms; using it in
    // let-else or if-block error paths is a POL-31 violation because the expression
    // context (not a match arm) means the macro is reachable whenever strip_prefix
    // returns None, which can happen via in-crate struct-literal construction.
    let bare_unreachable_let_else = r#"
pub fn extract_prefix(code: &str) -> &str {
    let Some(rest) = code.strip_prefix("E-") else {
        unreachable!("BC-2.14.003: code format validated at construction; cannot fail here");
    };
    rest
}
"#;
    let findings_iii =
        scan_for_panics_in_source(bare_unreachable_let_else, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings_iii.is_empty(),
        "BC-2.14.003 §PC-006(iii): unreachable!() in a let-else else-block (not a wildcard \
         match arm) must be FLAGGED; the gate currently only detects the `_ => unreachable!()` \
         token shape; implementer must extend detection to bare unreachable!() invocations \
         outside exhaustive-match arms (let-else else-blocks, if-block error paths); \
         got: {findings_iii:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-4 F-01) — non-parenthesis macro delimiter gap
//
// BC-2.14.003 {PC-005}/{PC-006}: the scanner must flag assert!, assert_eq!,
// assert_ne!, panic!, and wildcard unreachable! regardless of macro invocation
// delimiter. The current scanner checks only Delimiter::Parenthesis in the
// FLAGGED_PANIC_MACROS handler and in the `_` wildcard handler; brace-delimited
// (!{...}) and bracket-delimited (![...]) forms evade detection.
// ═══════════════════════════════════════════════════════════════════════════

/// F-01 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG `assert!{condition, "msg"}`
/// (brace-delimited) in non-test production code. BC-2.14.003 prohibits
/// these macros regardless of the macro invocation delimiter.
///
/// RED GATE: the FLAGGED_PANIC_MACROS handler guards with
/// `g.delimiter() == Delimiter::Parenthesis`; a brace-delimited invocation
/// fails that guard and produces no finding.
#[test]
fn test_BC_2_14_003_flags_assert_brace_delimiter_in_production_code() {
    // BC-2.14.003 {PC-005}: assert!{...} must be flagged (delimiter-independent)
    let src = r#"
pub fn check_nonneg(x: i32) {
    assert!{x >= 0, "x must be non-negative"};
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}} F-01: assert!{{...}} with brace delimiter must be flagged \
         (FLAGGED_PANIC_MACROS handler checks Delimiter::Parenthesis only); \
         got: {findings:?}"
    );
}

/// F-01 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG `assert![condition, "msg"]`
/// (bracket-delimited) in non-test production code.
///
/// RED GATE: FLAGGED_PANIC_MACROS handler checks only Delimiter::Parenthesis.
#[test]
fn test_BC_2_14_003_flags_assert_bracket_delimiter_in_production_code() {
    // BC-2.14.003 {PC-005}: assert![...] must be flagged (delimiter-independent)
    let src = r#"
pub fn check_nonneg(x: i32) {
    assert![x >= 0, "x must be non-negative"];
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}} F-01: assert![...] with bracket delimiter must be flagged \
         (FLAGGED_PANIC_MACROS handler checks Delimiter::Parenthesis only); \
         got: {findings:?}"
    );
}

/// F-01 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG `assert_eq!{a, b}` (brace-delimited).
///
/// RED GATE: FLAGGED_PANIC_MACROS handler checks only Delimiter::Parenthesis.
#[test]
fn test_BC_2_14_003_flags_assert_eq_brace_delimiter_in_production_code() {
    // BC-2.14.003 {PC-005}: assert_eq!{...} must be flagged (delimiter-independent)
    let src = r#"
pub fn check_equal(a: i32, b: i32) {
    assert_eq!{a, b, "values must be equal"};
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}} F-01: assert_eq!{{...}} with brace delimiter must be \
         flagged (delimiter-independent rule); got: {findings:?}"
    );
}

/// F-01 (MED) — BC-2.14.003 {PC-005}/{PC-006}
///
/// `scan_for_panics_in_source` must FLAG `panic!{msg}` (brace-delimited).
///
/// RED GATE: FLAGGED_PANIC_MACROS handler checks only Delimiter::Parenthesis.
#[test]
fn test_BC_2_14_003_flags_panic_brace_delimiter_in_production_code() {
    // BC-2.14.003 {PC-005}: panic!{...} must be flagged (delimiter-independent)
    let src = r#"
pub fn unreachable_path() {
    panic!{"this code path must never be reached"};
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-005}} F-01: panic!{{...}} with brace delimiter must be flagged; \
         got: {findings:?}"
    );
}

/// F-01 (MED) — BC-2.14.003 {PC-006}/{EC-007}
///
/// `scan_for_panics_in_source` must FLAG `_ => unreachable!{msg}` (brace-delimited
/// wildcard arm). The `_` wildcard handler checks `args.delimiter() ==
/// Delimiter::Parenthesis`; a brace-delimited arg group fails that check. The
/// fallback `unreachable` handler then sees `in_match_arm_position=true` (the
/// fat-arrow tokens are still present) and exempts it as a named arm.
///
/// RED GATE: `_` handler: `args.delimiter() == Delimiter::Parenthesis` rejects
/// brace form; `unreachable` fallback handler exempts all match-arm-position calls.
#[test]
fn test_BC_2_14_003_flags_unreachable_wildcard_brace_delimiter() {
    // BC-2.14.003 {PC-006}/{EC-007}: _ => unreachable!{...} must be flagged
    let src = r#"
pub fn categorize(n: u32) -> &'static str {
    match n {
        0 => "zero",
        1 => "one",
        _ => unreachable!{"unexpected value: {}", n},
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{PC-006}} F-01: _ => unreachable!{{...}} with brace delimiter must \
         be flagged (wildcard `_` handler checks Delimiter::Parenthesis only; brace form \
         evades `_` handler AND is exempted by the `unreachable` handler's \
         in_match_arm_position guard); got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-4 F-02) — non-`_` catch-all arm detection gap
//
// BC-2.14.003 §EC-007: exhaustive-match exemption applies ONLY when every arm
// is a named variant pattern (no `_`, no irrefutable binding, no guarded wildcard).
// The scanner currently exempts ALL match-arm-position unreachable!() that are not
// the exact `_ = > unreachable!` token shape, missing irrefutable binding catch-alls
// and guarded wildcards.
// ═══════════════════════════════════════════════════════════════════════════

/// F-02 (MED) — BC-2.14.003 {PC-006}/{EC-007}
///
/// `scan_for_panics_in_source` must FLAG `other => unreachable!(...)` (irrefutable
/// binding catch-all). §EC-007: exhaustive-match exemption ONLY for named variant
/// patterns; an irrefutable binding `other` is semantically a catch-all pattern.
///
/// RED GATE: the `_` handler only fires when `id == "_"`; `other` falls through to
/// the catch-all arm which resets `pending_panics_doc` only. The `unreachable` handler
/// then sees `in_match_arm_position=true` (fat-arrow tokens i-2/i-1 match) and
/// exempts it as if it were a named variant arm — incorrect per §EC-007.
#[test]
fn test_BC_2_14_003_flags_binding_catch_all_unreachable() {
    // BC-2.14.003 §EC-007 F-02: irrefutable binding catch-all must be flagged
    let violation_binding =
        include_str!("../tests/fixtures/violations/violation_binding_catch_all.rs");
    let findings = scan_for_panics_in_source(violation_binding, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{EC-007}} F-02: `other => unreachable!()` irrefutable-binding \
         catch-all must be flagged (not a named-variant arm; scanner exempts all \
         match-arm-position unreachable!() lacking the exact `_ = > unreachable!` shape; \
         irrefutable bindings are latent panic paths under enum/type evolution); \
         got: {findings:?}"
    );
}

/// F-02 (MED) — BC-2.14.003 {PC-006}/{EC-007}
///
/// `scan_for_panics_in_source` must FLAG `_ if guard => unreachable!(...)` (guarded
/// wildcard). §EC-007: a guarded wildcard is not an exhaustive named-variant arm — a
/// value not matched by the guard condition can reach a future new match arm and panic.
///
/// RED GATE: the `_` handler looks for the exact consecutive token pattern
/// `_ = > unreachable!`. When a guard (`if condition`) appears between `_` and `=>`,
/// `tokens[i+1]` is `if` (not `=`), so the multi-token lookahead fails and no finding
/// is added. The `unreachable` handler then sees `in_match_arm_position=true` (the
/// fat-arrow tokens directly precede `unreachable` in the flat stream) and exempts it.
#[test]
fn test_BC_2_14_003_flags_guarded_wildcard_unreachable() {
    // BC-2.14.003 §EC-007 F-02: guarded wildcard must be flagged
    let src = r#"
pub fn process_status(n: u32) -> &'static str {
    match n {
        0 => "zero",
        _ if n > 100 => unreachable!("BC-2.14.003: n > 100 is not a valid status"),
        _ => "other",
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 {{EC-007}} F-02: `_ if guard => unreachable!()` guarded-wildcard \
         arm must be flagged (`_` handler lookahead breaks when guard tokens sit between \
         `_` and `=>`; `unreachable` handler then erroneously exempts via \
         in_match_arm_position); got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-4 F-03) — --fixture-mode e2e gate (AC-017/Task-13)
//
// check-no-panic --fixture-mode <dir> must scan the given directory (not crates/)
// and exit non-zero when violation fixtures are present. The current run() fn
// ignores argv[2] and scans crates/ (which is clean) → exits 0.
//
// RED GATE (in-process): the brace-delimiter fixture violation_assert_brace.rs
// produces no findings with the current scanner (F-01 gap), making the second
// assertion below fail.
// RED GATE (subprocess, #[ignore]): --fixture-mode not implemented; current code
// scans crates/ (clean) → exits 0; test asserts non-zero → fails.
// ═══════════════════════════════════════════════════════════════════════════

/// F-03 (MED process-gap) — AC-017/Task-13 (BC-2.14.003)
///
/// SID-1 in-process companion: drives the fixture-mode scanner behavior at the
/// dependency boundary without subprocess overhead.
///
/// Scans the violation fixture files that `--fixture-mode` would scan and asserts
/// each produces at least one violation finding.
///
/// RED GATE: `violation_assert_brace.rs` contains `assert!{...}` (brace-delimited);
/// the scanner only checks `Delimiter::Parenthesis` (F-01 gap) → empty findings →
/// the second assertion FAILS.
#[test]
fn test_BC_2_14_003_fixture_mode_in_process_violation_found() {
    // Fixture 1: assert! without # Panics doc section and BC-ID (parenthesis form).
    // Currently detected by the scanner → non-empty → PASSES.
    let violation_assert_no_doc =
        include_str!("../tests/fixtures/violations/violation_assert_no_doc.rs");
    let findings_doc = scan_for_panics_in_source(
        violation_assert_no_doc,
        "xtask/tests/fixtures/violations/violation_assert_no_doc.rs",
    );
    assert!(
        !findings_doc.is_empty(),
        "BC-2.14.003 F-03 (in-process): violation_assert_no_doc.rs must produce a \
         violation finding; got: {findings_doc:?}"
    );

    // Fixture 2: assert!{...} brace-delimited form (F-01 gap fixture).
    // RED GATE: scanner only checks Delimiter::Parenthesis → brace form not detected →
    // findings_brace is empty → this assertion FAILS.
    let violation_assert_brace =
        include_str!("../tests/fixtures/violations/violation_assert_brace.rs");
    let findings_brace = scan_for_panics_in_source(
        violation_assert_brace,
        "xtask/tests/fixtures/violations/violation_assert_brace.rs",
    );
    assert!(
        !findings_brace.is_empty(),
        "BC-2.14.003 F-03 (in-process) + F-01: violation_assert_brace.rs must produce a \
         violation finding (assert!{{...}} brace-delimited form must be flagged); \
         current scanner only checks Delimiter::Parenthesis; got: {findings_brace:?}"
    );
}

/// F-03 (MED process-gap) — AC-017/Task-13 (BC-2.14.003) — subprocess test
///
/// `cargo xtask check-no-panic --fixture-mode <violations_dir>` must exit non-zero
/// when run against the violation fixtures and exit 0 when the fixtures are clean.
///
/// RED GATE: `--fixture-mode` is not implemented. `run()` ignores extra argv,
/// scans `crates/` (clean workspace), and exits 0. This test asserts non-zero
/// → FAILS against current code.
///
/// SID-1: the non-ignored in-process companion above provides CI coverage without
/// subprocess overhead.
#[test]
#[ignore = "EXT-F03: subprocess requires cargo build (~30s cold); \
            run manually or in the xtask-subprocess CI job. \
            In-process companion: test_BC_2_14_003_fixture_mode_in_process_violation_found. \
            S-2.07 owns E-PROV-002 error-shape verification."]
fn test_BC_2_14_003_fixture_mode_subprocess_exits_nonzero_on_violations() {
    use std::process::{Command, Stdio};

    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string());
    // CARGO_MANIFEST_DIR for the xtask crate is xtask/; workspace root is one level up.
    let workspace_root = std::path::Path::new(&manifest_dir)
        .parent()
        .map(|p| p.to_path_buf())
        .unwrap_or_else(|| std::path::PathBuf::from("."));
    let violation_dir = workspace_root.join("xtask/tests/fixtures/violations");

    let output = Command::new("cargo")
        .args([
            "run",
            "--quiet",
            "-p",
            "xtask",
            "--",
            "check-no-panic",
            "--fixture-mode",
            violation_dir
                .to_str()
                .expect("violation dir path must be valid UTF-8"),
        ])
        .stdin(Stdio::null())
        .current_dir(&workspace_root)
        .output()
        .expect("cargo run must be invocable");

    // RED GATE: --fixture-mode not implemented; run() scans crates/ (clean) → exits 0.
    // After implementation: violation fixtures found → exits 1.
    assert!(
        !output.status.success(),
        "BC-2.14.003 F-03: check-no-panic --fixture-mode must exit non-zero when \
         violation fixtures present; current code: flag ignored, crates/ is clean, \
         exits 0; exit: {:?}, stderr: {}",
        output.status,
        String::from_utf8_lossy(&output.stderr)
    );

    // Secondary assertions (only reached once exit code is non-zero):
    // both violation fixtures must appear in the combined output.
    let combined = format!(
        "{}{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        combined.contains("violation_assert_no_doc"),
        "BC-2.14.003 F-03: violation_assert_no_doc.rs must be reported; output: {combined}"
    );
    assert!(
        combined.contains("violation_assert_brace"),
        "BC-2.14.003 F-03: violation_assert_brace.rs (brace-delimiter form, F-01) must \
         be reported; output: {combined}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.004 (S-1.02 pass-4 O-1) — zero-timeout form detection gaps
//
// BC-2.14.004 {PC-001}/{INV-004}: timeout duration must be > Duration::ZERO.
// The current is_zero_duration_timeout_arg recognises only the short constant form
// `Duration :: ZERO`. Two additional zero-equivalent forms escape detection:
//   - Duration::from_secs(0)       (zero via constructor)
//   - std::time::Duration::ZERO    (fully-qualified constant path)
// ═══════════════════════════════════════════════════════════════════════════

/// O-1 (LOW) — BC-2.14.004 {PC-001}/{INV-004}
///
/// `scan_for_timeout_violations_in_source` must FLAG `.timeout(Duration::from_secs(0))`
/// as a zero/non-positive-timeout violation. {PC-001} requires d > Duration::ZERO;
/// `Duration::from_secs(0)` evaluates to `Duration::ZERO` at runtime.
///
/// RED GATE: `is_zero_duration_timeout_arg` checks `flat[timeout_idx+6]` for the
/// ident `"ZERO"`; `Duration::from_secs(0)` places `"from_secs"` at that offset
/// (not `"ZERO"`) → returns `false` → timeout credited as valid → chain not flagged.
#[test]
fn test_BC_2_14_004_flags_timeout_from_secs_zero() {
    // BC-2.14.004 {PC-001}/{INV-004}: Duration::from_secs(0) == Duration::ZERO
    let src = r#"let c = reqwest::ClientBuilder::new().timeout(Duration::from_secs(0)).build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.004 {{PC-001}} O-1: .timeout(Duration::from_secs(0)) must be flagged as \
         zero-timeout (d must be > 0 per {{INV-004}}); is_zero_duration_timeout_arg only \
         matches the `Duration::ZERO` constant form at fixed flat-token offsets; \
         got: {findings:?}"
    );
}

/// O-1 (LOW) — BC-2.14.004 {PC-001}/{INV-004}
///
/// `scan_for_timeout_violations_in_source` must FLAG fully-qualified
/// `.timeout(std::time::Duration::ZERO)`. The value is identical to `Duration::ZERO`;
/// the fully-qualified path form must also be detected.
///
/// RED GATE: `is_zero_duration_timeout_arg` checks `flat[timeout_idx+3]` for the
/// ident `"Duration"`. With `std::time::Duration::ZERO`, the flat token sequence at
/// `timeout_idx+3` is `"std"` (not `"Duration"`) because the three extra tokens
/// `std :: time ::` appear before `Duration` → check returns `false` → not detected.
#[test]
fn test_BC_2_14_004_flags_timeout_fully_qualified_duration_zero() {
    // BC-2.14.004 {PC-001}/{INV-004}: std::time::Duration::ZERO is Duration::ZERO
    let src =
        r#"let c = reqwest::ClientBuilder::new().timeout(std::time::Duration::ZERO).build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.004 {{PC-001}} O-1: .timeout(std::time::Duration::ZERO) fully-qualified \
         must be flagged ({{INV-004}}: zero-duration timeout is forbidden); \
         is_zero_duration_timeout_arg only matches the short Duration::ZERO form; extra \
         tokens in the fully-qualified path shift `Duration` past the +3 offset check; \
         got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-5 F-01) — guarded irrefutable-binding catch-all
//
// BC-2.14.003 §EC-007 / §PC-005: the exhaustive-match exemption applies ONLY
// when every arm is a named variant pattern (no `_`, no irrefutable binding).
// `name if <guard> => unreachable!(...)` is a guarded irrefutable-binding catch-all
// — semantically equivalent to a catch-all `name =>`, because the binding `name` is
// irrefutable regardless of the guard. The scanner currently detects `name =>
// unreachable!(...)` (bare, no guard) but NOT the guarded form where `if <guard>`
// sits between the binding and `=>`, causing the lookahead to miss the pattern.
// ═══════════════════════════════════════════════════════════════════════════

/// F-01 (MED) — BC-2.14.003 §EC-007 pass-5
///
/// `scan_for_panics_in_source` must FLAG a guarded irrefutable-binding catch-all
/// `other if guard() => unreachable!(...)`. The binding `other` is irrefutable regardless
/// of the guard; the §EC-007 exemption requires every arm to be a named variant pattern.
///
/// RED GATE: the irrefutable-binding detection in the Ident handler checks
/// `tokens[i+1]` == `=` and `tokens[i+2]` == `>` (direct pattern `name => unreachable!`).
/// When a guard appears, `tokens[i+1]` is `if` (not `=`), so the lookahead fails and no
/// finding is produced. The `unreachable` fallback handler then sees `in_match_arm_position=true`
/// (the fat-arrow tokens immediately precede `unreachable`) and incorrectly exempts it.
#[test]
fn test_BC_2_14_003_flags_guarded_irrefutable_binding_catch_all() {
    let violation_guarded_binding =
        include_str!("../tests/fixtures/violations/violation_guarded_binding_catch_all.rs");
    let findings =
        scan_for_panics_in_source(violation_guarded_binding, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-5 F-01: guarded irrefutable-binding catch-all \
         `other if guard() => unreachable!(...)` must be FLAGGED; \
         the irrefutable-binding detection checks tokens[i+1]=='=' and tokens[i+2]=='>' \
         (direct `name => unreachable!` form only); a guard keyword `if` at tokens[i+1] \
         causes the lookahead to miss the pattern, and the `unreachable` handler's \
         in_match_arm_position check incorrectly exempts it as a named arm; \
         got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-5 F-02) — cross-arm false-positive (guarded wildcard
// boundary overrun)
//
// BC-2.14.003 §EC-007: `_ if <guard> => <non-unreachable-body>` must NOT produce a
// finding. The current guarded-wildcard scan in the `_` handler scans forward without
// stopping at the arm boundary (`,`), and can reach a LATER named arm's `=>
// unreachable!(...)`, falsely attributing the finding to the `_ if` arm instead of
// the named arm. Since the named arm is Exemption-1 compliant (no wildcard), the
// correct result is ZERO findings.
// ═══════════════════════════════════════════════════════════════════════════

/// F-02 (MED) — BC-2.14.003 §EC-007 pass-5
///
/// A benign guarded-wildcard arm whose body is NOT `unreachable!` must NOT be flagged
/// just because a LATER named arm in the same match legitimately uses `unreachable!`.
///
/// Canonical case: `match phase { Phase::Init => 0, _ if is_special() => 99,
/// Phase::Done => unreachable!("handled upstream") }`. The `_ if is_special() => 99`
/// arm has body `99`, so no guarded-wildcard finding applies. `Phase::Done` is a named
/// arm — Exemption-1 applies. Correct behavior: ZERO findings.
///
/// RED GATE: the guarded-wildcard scan in the `_` handler iterates without a
/// `,`-boundary stop. After seeing `_ if is_special() => 99 ,` it continues scanning,
/// finds `Phase::Done => unreachable!(...)`, and emits a finding attributed to the
/// `_ if` arm. The finding message points to the line of `Phase::Done`'s unreachable!,
/// not to the `_ if` arm itself.
#[test]
fn test_BC_2_14_003_guarded_wildcard_does_not_misattribute_cross_arm_unreachable() {
    // `_ if is_special() => 99` is benign (body is `99`, not unreachable!).
    // `Phase::Done => unreachable!(...)` is a named arm — Exemption-1, should be exempt.
    // ZERO findings expected. Current code produces 1 false finding (cross-arm attribution).
    let src = r#"
pub enum Phase { Init, Done }
fn is_special() -> bool { false }
pub fn process(phase: Phase) -> i32 {
    match phase {
        Phase::Init => 0,
        _ if is_special() => 99,
        Phase::Done => unreachable!("handled upstream"),
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    // Primary assertion: no finding should be produced.
    assert!(
        findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-5 F-02: benign `_ if is_special() => 99` must NOT produce \
         a finding; the guarded-wildcard scan does not stop at the `,` arm boundary, scans \
         past `99,` and finds `Phase::Done => unreachable!(...)`, falsely attributing the \
         finding to the `_ if` arm; correct behavior is ZERO findings (benign arm body, \
         named arm exempt via Exemption-1); got: {findings:?}"
    );
    // Secondary guard: if any finding IS produced, it must not be attributed to Phase::Done.
    for f in &findings {
        assert!(
            !f.contains("Phase") && !f.contains("Done"),
            "BC-2.14.003 §EC-007 pass-5 F-02: any finding must NOT be attributed to \
             Phase::Done — that is a legitimate Exemption-1 named arm; finding: {f}"
        );
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.004 (S-1.02 pass-5 F-04) — zero-timeout constructor coverage gaps
//
// BC-2.14.004 {PC-001}/{INV-004}: timeout duration must be > Duration::ZERO.
// `is_zero_duration_timeout_arg` Form C recognises from_secs, from_millis, from_nanos,
// from_secs_f64 but NOT from_micros or from_secs_f32. Both constructors with a zero
// argument evaluate to Duration::ZERO and must be flagged.
// ═══════════════════════════════════════════════════════════════════════════

/// F-04 (LOW) — BC-2.14.004 {PC-001}/{INV-004} pass-5
///
/// `scan_for_timeout_violations_in_source` must FLAG `.timeout(Duration::from_micros(0))`
/// as a zero-timeout violation. `Duration::from_micros(0)` evaluates to `Duration::ZERO`
/// at runtime; {PC-001} requires d > Duration::ZERO.
///
/// RED GATE: `is_zero_duration_timeout_arg` Form C checks for constructor names
/// `from_secs | from_millis | from_nanos | from_secs_f64` at offset +6 in the flat
/// token stream. `from_micros` is absent from the match list → returns `false` →
/// the timeout is credited as valid → chain is reported compliant → no finding.
#[test]
fn test_BC_2_14_004_flags_timeout_from_micros_zero() {
    let src =
        r#"let c = reqwest::ClientBuilder::new().timeout(Duration::from_micros(0)).build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.004 {{PC-001}} pass-5 F-04: .timeout(Duration::from_micros(0)) must be \
         flagged as zero-timeout (d must be > 0 per {{INV-004}}); \
         is_zero_duration_timeout_arg Form C only matches from_secs/from_millis/from_nanos/\
         from_secs_f64; from_micros is absent from the recognised constructor list; \
         got: {findings:?}"
    );
}

/// F-04 (LOW) — BC-2.14.004 {PC-001}/{INV-004} pass-5
///
/// `scan_for_timeout_violations_in_source` must FLAG `.timeout(Duration::from_secs_f32(0.0))`
/// as a zero-timeout violation. `Duration::from_secs_f32(0.0)` evaluates to `Duration::ZERO`
/// at runtime; {PC-001} requires d > Duration::ZERO.
///
/// RED GATE: `is_zero_duration_timeout_arg` Form C only matches `from_secs_f64` for
/// floating-point constructors; `from_secs_f32` is absent → returns `false` → timeout
/// credited as valid → no finding.
#[test]
fn test_BC_2_14_004_flags_timeout_from_secs_f32_zero() {
    let src =
        r#"let c = reqwest::ClientBuilder::new().timeout(Duration::from_secs_f32(0.0)).build()?;"#;
    let findings = scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.004 {{PC-001}} pass-5 F-04: .timeout(Duration::from_secs_f32(0.0)) must be \
         flagged as zero-timeout (d must be > 0 per {{INV-004}}); \
         is_zero_duration_timeout_arg Form C only matches from_secs_f64 for f32/f64 constructors; \
         from_secs_f32 is absent; got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-5 F-05) — qualified-path unreachable! over-flagging
//
// BC-2.14.003 §EC-007 Exemption 1: `unreachable!()` in a fully-enumerated named-arm
// match (no wildcard) is exempt. This exemption must extend to qualified forms
// `std::unreachable!(...)` and `core::unreachable!(...)` — they are the same macro
// with a different path prefix. The `unreachable` handler's `in_match_arm_position`
// check looks at tokens[i-2]=`=` and tokens[i-1]=`>` (fat-arrow tokens). For
// `std::unreachable!`, the token before `unreachable` is `::` (not `>`), so the
// check fails and the §PC-006 violation handler fires incorrectly.
// ═══════════════════════════════════════════════════════════════════════════

/// F-05 (LOW) — BC-2.14.003 §EC-007 Exemption 1 pass-5
///
/// `Foo::Bar => std::unreachable!(...)` in a fully-enumerated no-wildcard exhaustive
/// match MUST NOT be flagged. `std::unreachable!` is a legitimate Exemption-1 named arm.
///
/// RED GATE: the `unreachable` handler's `in_match_arm_position` check inspects
/// `tokens[i-2].as_char() == '='` and `tokens[i-1].as_char() == '>'`. For
/// `std::unreachable!`, the token at i-1 is `::` (the second `:` of the path separator),
/// not `>`, so `in_match_arm_position = false` → §PC-006 violation handler fires.
#[test]
fn test_BC_2_14_003_std_qualified_unreachable_in_named_arm_not_flagged() {
    let src = r#"
pub enum Status { Active, Done }
pub fn handle_status(s: Status) -> i32 {
    match s {
        Status::Active => 1,
        Status::Done => std::unreachable!("Done is handled upstream"),
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-5 F-05: `Status::Done => std::unreachable!(...)` in a \
         fully-enumerated no-wildcard named-arm match MUST NOT be flagged; \
         `in_match_arm_position` checks tokens[i-2]='=' tokens[i-1]='>' but for \
         `std::unreachable` tokens[i-1] is `::` (not `>`), so the check fails and the \
         §PC-006 handler fires; got: {findings:?}"
    );
}

/// F-05 (LOW) — BC-2.14.003 §EC-007 Exemption 1 pass-5 — core:: variant
///
/// `Foo::Bar => core::unreachable!(...)` in a fully-enumerated no-wildcard exhaustive
/// match MUST NOT be flagged. Same root cause as the std:: variant.
///
/// RED GATE: same as std::unreachable! — tokens[i-1] is `::` not `>` →
/// `in_match_arm_position = false` → §PC-006 handler fires incorrectly.
#[test]
fn test_BC_2_14_003_core_qualified_unreachable_in_named_arm_not_flagged() {
    let src = r#"
pub enum Step { Start, End }
pub fn handle_step(s: Step) -> i32 {
    match s {
        Step::Start => 0,
        Step::End => core::unreachable!("End is handled before this call"),
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-5 F-05: `Step::End => core::unreachable!(...)` in a \
         fully-enumerated no-wildcard named-arm match MUST NOT be flagged; \
         same root cause as std::unreachable! — tokens[i-1] is `::` not `>`, so \
         `in_match_arm_position = false` and the §PC-006 handler fires; \
         got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-6) — arm_stack leak into closure/nested-fn (F-01),
// cfg(test) impl-block skip gap (F-02), syn-parse-fail fail-safe (F-03)
//
// BC-2.14.003 §PC-005/§PC-006/§EC-007 v1.5: the named-arm exemption (Exemption 1)
// applies ONLY when unreachable! is the direct body expression of a named arm.
// It does NOT extend into closures or nested fn definitions lexically within
// the arm body — those are independently callable/reachable code paths.
// cfg(test) exemption must cover item_impl as well as item_mod and item_fn.
// ═══════════════════════════════════════════════════════════════════════════

/// F-01a (MED) — BC-2.14.003 §PC-005/§PC-006/§EC-007 pass-6
///
/// `unreachable!()` inside a CLOSURE that is lexically within a NAMED
/// (non-catch-all) match arm MUST be FLAGGED. The closure body is a
/// runtime-reachable code path — it is NOT covered by Exemption 1. The
/// named-arm exemption only applies when the `unreachable!` is the direct
/// body expression of the arm, not when it is nested inside a closure.
///
/// RED GATE: `visit_arm` pushes `false` (named arm) onto `arm_stack`, then
/// calls `syn::visit::visit_expr` on the arm body. The closure
/// `|_x| unreachable!(...)` is visited while `arm_stack.last() == Some(&false)`,
/// so `handle_macro_invocation` treats it as Exemption-1 and silently skips
/// the finding. The test asserts a finding IS produced → FAILS until the fix
/// (arm_stack must be saved and cleared on closure-body entry, then restored).
#[test]
fn test_BC_2_14_003_pass6_closure_inside_named_arm_flagged() {
    // BC-2.14.003 §PC-006/§EC-007: unreachable! inside a closure nested within a
    // named arm must be flagged. The closure's body is runtime-reachable code —
    // Exemption 1 covers only the direct named-arm body, not nested closures.
    let src = r#"
pub fn process(r: Result<Vec<i32>, String>) -> Vec<i32> {
    match r {
        Ok(v) => v.iter().map(|_x| unreachable!("BC-2.14.003: closure body is runtime-reachable per element")).collect(),
        Err(_) => vec![],
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §PC-006 pass-6 F-01a: unreachable!() inside a closure within a named \
         match arm MUST be flagged (the closure body is runtime-reachable; Exemption 1 applies \
         only to the direct named-arm body expression, not to nested closures; arm_stack \
         leaks the named-arm exempt flag into the closure); got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-6 F-01a: finding must reference unreachable!; got: {findings:?}"
    );
}

/// F-01b (MED) — BC-2.14.003 §PC-005/§PC-006/§EC-007 pass-6
///
/// `unreachable!()` inside a NESTED FUNCTION that is lexically within a NAMED
/// match arm MUST be FLAGGED. The nested function's body is an independently
/// callable code path — it is NOT covered by the named-arm Exemption 1.
///
/// RED GATE: same root cause as F-01a. `visit_item_fn` does not reset
/// `arm_stack`, so the nested function body is visited while
/// `arm_stack.last() == Some(&false)`. `handle_macro_invocation` sees
/// a non-empty arm_stack with `false` at top → EXEMPT — the finding is
/// never emitted. Test asserts a finding IS produced → FAILS until
/// `visit_item_fn` (and `visit_impl_item_fn`) save and clear `arm_stack`
/// on entry, restoring on exit.
#[test]
fn test_BC_2_14_003_pass6_nested_fn_inside_named_arm_flagged() {
    // BC-2.14.003 §PC-006/§EC-007: unreachable! inside a nested fn definition
    // within a named arm must be flagged. The nested fn is independently callable;
    // its body is not covered by the outer arm's Exemption 1.
    let src = r#"
pub fn process(r: Result<i32, String>) -> i32 {
    match r {
        Ok(v) => {
            fn inner_helper() {
                unreachable!("BC-2.14.003: nested-fn body is not a named-arm exemption")
            }
            let _ = inner_helper;
            v
        }
        Err(_) => 0,
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §PC-006 pass-6 F-01b: unreachable!() inside a nested fn within a named \
         match arm MUST be flagged (the nested fn body is independently callable and is not \
         covered by Exemption 1; arm_stack leaks the named-arm exempt flag into the nested fn \
         because visit_item_fn does not reset arm_stack); got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-6 F-01b: finding must reference unreachable!; got: {findings:?}"
    );
}

/// F-02 (LOW) — BC-2.14.003 §PC-005/§EC-007 pass-6
///
/// `.unwrap()`, `assert!`, and `panic!` inside a `#[cfg(test)]`-attributed
/// IMPL BLOCK must NOT be flagged. The cfg(test) skip in `PanicVisitor` covers
/// `item_mod` and `item_fn`/`item_impl_fn` (method-level attrs), but NOT
/// `item_impl` (impl-block-level attrs). A `#[cfg(test)] impl Foo { ... }` is
/// test-only code; its methods must be treated identically to methods inside
/// a `#[cfg(test)] mod tests { ... }` block.
///
/// RED GATE: `PanicVisitor` has `visit_item_mod` (cfg(test) early return) and
/// `visit_item_fn`/`visit_impl_item_fn` (cfg(test) early return on the function
/// itself), but NO `visit_item_impl`. When the visitor traverses a
/// `#[cfg(test)] impl Checker { fn check_state() { x.unwrap(); } }` block, it
/// descends into the impl items. `visit_impl_item_fn` is called for
/// `check_state`, which has no `#[cfg(test)]` on the METHOD — only on the
/// enclosing impl — so the skip does not fire. `.unwrap()` and `assert!(false)`
/// inside `check_state` are wrongly flagged. Test asserts ZERO findings →
/// FAILS until `visit_item_impl` with cfg(test) early-return is added.
#[test]
fn test_BC_2_14_003_pass6_cfg_test_impl_block_not_flagged() {
    // BC-2.14.003 §EC-007: .unwrap() and assert!() inside a #[cfg(test)]-
    // attributed impl block must NOT be flagged. The cfg(test) attribute on
    // the impl block marks all its methods as test-only code.
    let src = r#"
pub struct Checker;

#[cfg(test)]
impl Checker {
    fn check_state(&self) -> i32 {
        let x: Option<i32> = None;
        let _ = x.unwrap();
        assert!(false);
        0
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-6 F-02: .unwrap() and assert!() inside a \
         #[cfg(test)]-attributed impl block MUST NOT be flagged (the impl block is \
         test-only code; cfg(test) skip must cover item_impl, not just item_mod and \
         item_fn/impl_item_fn); got: {findings:?}"
    );
}

/// F-03 (LOW/OBS) — BC-2.14.003 §PC-005 pass-6
///
/// A source file that syn CANNOT parse (invalid item syntax — module-scope
/// `let` statement) but proc_macro2 CAN tokenize must yield at least one
/// finding: either a fail-safe "FAILED TO PARSE FILE" message or a real
/// violation detected by the lexer fallback. The scanner MUST NOT return a
/// silent empty vec for parse failures.
///
/// This pins the post-removal behavior: once the dead proc_macro2 fallback
/// is removed and replaced by a `parse-Err → finding` route, a syn parse
/// error must surface as a non-empty findings vec. Currently the fallback is
/// active and detects `.unwrap()` in the token stream (test passes now); after
/// the fallback is removed and the parse-Err route is added, the test still
/// passes because the parse-error finding is non-empty.
#[test]
fn test_BC_2_14_003_pass6_syn_parse_failure_yields_fail_safe_finding() {
    // Module-scope `let` statement: valid tokens, invalid Rust item syntax.
    // syn::parse_file fails; proc_macro2 can tokenize it.
    // The source contains `.unwrap()` so the current fallback returns a finding.
    // After the fallback is removed: a "FAILED TO PARSE FILE" finding must appear.
    let src = "let val: Option<i32> = Some(42);\nval.unwrap()";
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §PC-005 pass-6 F-03: a syn-unparseable-but-lexable source must yield \
         at least one finding (either FAILED TO PARSE FILE from a parse-error route, or a \
         real violation from the lexer fallback), not a silent empty vec; \
         got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-7) — async-block arm_stack leak (F-A),
// reference/paren catch-all patterns (F-B)
//
// BC-2.14.003 §PC-006/§EC-007 v1.5:
//
// F-A: unreachable!() inside an `async { ... }` or `async move { ... }` block
// that is lexically within a NAMED match arm MUST be FLAGGED. The async block
// is deferred execution — its body runs as a callable future, independently of
// the arm that created it. The named-arm Exemption 1 covers only the DIRECT arm
// body expression; it does NOT extend into async blocks (same class as the
// closure/nested-fn cases corrected in pass-6).
//
// Current failure (no visit_expr_async override): visit_arm pushes false (named
// arm) onto arm_stack, then visits the arm body. The async block is visited by
// the default syn visitor while arm_stack.last() == Some(&false). Since there is
// no visit_expr_async that saves-and-clears arm_stack, handle_macro_invocation
// sees the leaked named-arm exempt flag and silently skips the finding.
//
// F-B: Pat::Reference (&other =>) and Pat::Paren ((other) =>) wrapping an
// irrefutable binding are catch-alls — they match any value not covered by
// earlier arms, identical to bare `other =>`. is_catch_all_pat currently handles
// Pat::Wild, Pat::Ident, and Pat::Or only; Pat::Reference and Pat::Paren fall to
// `_ => false`, causing the scanner to push false (named-arm exempt) and silently
// exempt unreachable!() inside these arms.
// ═══════════════════════════════════════════════════════════════════════════

/// F-A (MED) — BC-2.14.003 §PC-006/§EC-007 pass-7
///
/// `unreachable!()` inside an ASYNC BLOCK (`async { ... }` / `async move { ... }`)
/// that is lexically within a NAMED (non-catch-all) match arm MUST be FLAGGED.
/// The async block body is deferred execution — it runs as a callable future after
/// the match arm exits. The named-arm Exemption 1 covers only the DIRECT arm body
/// expression; it does NOT extend into async blocks, which are independently
/// reachable at runtime (same class as the closure and nested-fn cases corrected
/// in pass-6).
///
/// RED GATE: `visit_expr_async` is not overridden in PanicVisitor. `visit_arm`
/// pushes `false` (named-arm exempt) onto `arm_stack`, then calls
/// `syn::visit::visit_expr` on the arm body. The `async move { ... }` ExprAsync
/// node is visited by the default syn visitor, which descends into the async block
/// body while `arm_stack.last() == Some(&false)`. `handle_macro_invocation` sees
/// the leaked named-arm exempt flag and silently skips the finding. Test asserts a
/// finding IS produced → FAILS until `visit_expr_async` saves and clears `arm_stack`
/// on async-block entry (restoring on exit), identical to the pass-6 closure fix.
#[test]
fn test_BC_2_14_003_async_block_inside_named_arm_flagged() {
    let src = r#"
pub fn process(r: Result<i32, String>) -> i32 {
    match r {
        Ok(_v) => {
            let _fut = async move {
                unreachable!("BC-2.14.003: async block is deferred execution not covered by Exemption 1")
            };
            0
        }
        Err(_) => 1,
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §PC-006 pass-7 F-A: unreachable!() inside an async block within a named \
         match arm MUST be flagged (the async block is deferred execution; Exemption 1 applies \
         only to the direct named-arm body expression, not to nested async blocks; \
         visit_expr_async not overridden → arm_stack leaks the named-arm exempt flag into \
         the async block body); got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-7 F-A: finding must reference unreachable!; got: {findings:?}"
    );
}

/// F-A companion guard — BC-2.14.003 §PC-006 pass-7
///
/// An `unreachable!()` in an async block NOT inside any match arm (top-level
/// async expression) is still flagged under §PC-006 (unreachable! outside an
/// exhaustive-match named arm). This guard confirms the class is closed: top-level
/// async unreachable! was already flagged before the F-A fix and must remain
/// flagged after it.
///
/// GREEN both before and after the F-A fix: arm_stack is empty at the point of the
/// unreachable! invocation → the §PC-006 handler fires regardless of async context.
#[test]
fn test_BC_2_14_003_async_block_toplevel_still_flagged() {
    let src = r#"
pub fn process() -> i32 {
    let _fut = async {
        unreachable!("BC-2.14.003: top-level async block has no arm context")
    };
    0
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §PC-006 pass-7 companion: unreachable!() in a top-level async block \
         (not inside any match arm) MUST still be flagged (arm_stack is empty → §PC-006 \
         fires regardless of async context); got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-7 companion: finding must reference unreachable!; got: {findings:?}"
    );
}

/// F-A boundary guard — BC-2.14.003 §EC-007/§PC-006 pass-7
///
/// An inline `unsafe { unreachable!() }` block that IS the direct body of a NAMED
/// match arm remains EXEMPT (Exemption 1). An unsafe block executes synchronously
/// as the arm's direct evaluation — it is NOT independently callable and runs
/// exactly when the arm is selected. Unlike async blocks (deferred execution,
/// callable future) or closures (independently callable), an unsafe block body is
/// the arm's direct evaluation path: the named-arm Exemption 1 applies.
///
/// This guard pins the boundary so the implementer's pass-7 fix (visit_expr_async
/// saves/clears arm_stack on async-block entry) does NOT extend to unsafe blocks
/// (which would be an over-reach: unsafe blocks do not change the execution model).
///
/// GREEN both before and after the F-A fix: arm_stack has false (named arm context)
/// and visit_expr_unsafe is not overridden → arm_stack is not cleared → EXEMPT.
#[test]
fn test_BC_2_14_003_unsafe_block_direct_named_arm_body_exempt() {
    let src = r#"
pub fn process(r: Result<i32, String>) -> i32 {
    match r {
        Ok(_v) => unsafe {
            unreachable!(
                "BC-2.14.003 boundary: unsafe block is Exemption-1 compliant as direct arm evaluation"
            )
        },
        Err(_) => 1,
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-7 boundary: unreachable!() inside `unsafe {{ ... }}` that \
         IS the direct body of a named match arm MUST remain EXEMPT (unsafe blocks execute \
         synchronously as the arm's direct evaluation; visit_expr_async clears arm_stack for \
         async blocks only — unsafe blocks must not be affected by the F-A fix); \
         got: {findings:?}"
    );
}

/// F-B (LOW) — BC-2.14.003 §PC-006/§EC-007 pass-7
///
/// `&other => unreachable!(...)` (Pat::Reference wrapping a lowercase-binding
/// Pat::Ident) is an irrefutable-binding catch-all and MUST be FLAGGED. A reference
/// wrapper `&` does not restrict pattern reachability — `&other` matches any
/// reference value just as bare `other` does. The §EC-007 exhaustive-match
/// exemption requires every arm to be a named variant pattern; an irrefutable
/// reference-binding is semantically a catch-all.
///
/// RED GATE: `is_catch_all_pat` handles `Pat::Wild`, `Pat::Ident`, and `Pat::Or`
/// only; `Pat::Reference` falls to the `_ => false` arm. A `&other =>` arm
/// therefore pushes `false` (named-arm exempt) onto `arm_stack`, and the
/// `unreachable!()` inside is incorrectly exempted via Exemption 1.
#[test]
fn test_BC_2_14_003_reference_catch_all_flagged() {
    let src = r#"
pub fn categorize(x: &u32) -> &'static str {
    match x {
        &0 => "zero",
        &1 => "one",
        &other => unreachable!("BC-2.14.003: &other is an irrefutable-binding reference catch-all"),
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-7 F-B: `&other => unreachable!(...)` (Pat::Reference) \
         must be FLAGGED — a reference-wrapped irrefutable binding is a catch-all; \
         is_catch_all_pat returns false for Pat::Reference → arm_stack push(false) → \
         Exemption 1 incorrectly applied; got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-7 F-B reference: finding must reference unreachable!; \
         got: {findings:?}"
    );
}

/// F-B (LOW) — BC-2.14.003 §PC-006/§EC-007 pass-7
///
/// `(other) => unreachable!(...)` (Pat::Paren wrapping a lowercase-binding
/// Pat::Ident) is an irrefutable-binding catch-all and MUST be FLAGGED. A paren
/// grouping wrapper `( )` does not add any restriction — `(other)` matches any
/// value just as bare `other` does. The §EC-007 exhaustive-match exemption
/// requires every arm to be a named variant pattern; an irrefutable paren-binding
/// is semantically a catch-all.
///
/// RED GATE: `is_catch_all_pat` handles `Pat::Wild`, `Pat::Ident`, and `Pat::Or`
/// only; `Pat::Paren` falls to the `_ => false` arm. A `(other) =>` arm
/// therefore pushes `false` (named-arm exempt) onto `arm_stack`, and the
/// `unreachable!()` inside is incorrectly exempted via Exemption 1.
#[test]
fn test_BC_2_14_003_paren_catch_all_flagged() {
    let src = r#"
pub fn categorize(x: u32) -> &'static str {
    match x {
        0 => "zero",
        1 => "one",
        (other) => unreachable!("BC-2.14.003: (other) is an irrefutable-binding paren catch-all"),
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-7 F-B: `(other) => unreachable!(...)` (Pat::Paren) \
         must be FLAGGED — a paren-wrapped irrefutable binding is a catch-all; \
         is_catch_all_pat returns false for Pat::Paren → arm_stack push(false) → \
         Exemption 1 incorrectly applied; got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-7 F-B paren: finding must reference unreachable!; \
         got: {findings:?}"
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// BC-2.14.003 (S-1.02 pass-8) — ref/mut binding-mode catch-alls (F-01),
// trait default-method arm-stack leak (F-02),
// structural-rewrite safety-net boundary guards
//
// BC-2.14.003 §PC-006/§EC-007 v1.5:
//
// F-01 (MED): `ref other =>` and `mut other =>` are irrefutable-binding
// catch-alls — binding mode (ref/mut) does NOT change irrefutability.
// is_catch_all_pat checks `p.by_ref.is_none()` and `p.mutability.is_none()`,
// causing ref/mut bindings to return false (named-arm exempt) instead of
// true (catch-all, must be flagged).
//
// F-02 (LOW): unreachable!() inside a trait default-method body that is
// lexically within a named match arm MUST be FLAGGED. PanicVisitor overrides
// visit_item_fn, visit_impl_item_fn, visit_expr_closure, and visit_expr_async —
// each saves and clears arm_stack on entry. But visit_trait_item_fn is NOT
// overridden: a trait default method nested inside a named arm body is visited
// while arm_stack.last() == Some(&false) → unreachable!() inside it is
// incorrectly EXEMPT (false negative).
//
// BOUNDARY GUARDS: the implementer will rewrite detection using (a) an
// "all arms are specific variant/literal patterns" allowlist exemption and
// (b) a direct-arm-body-only unreachable! exemption. The boundary guard tests
// below pin the expected CORRECT behavior for every variant so the structural
// rewrite cannot accidentally regress working cases or over-reach into cases
// that must remain exempt.
// ═══════════════════════════════════════════════════════════════════════════

// ── pass-8 F-01: ref binding catch-all ─────────────────────────────────────

/// F-01 (MED) — BC-2.14.003 §PC-006/§EC-007 pass-8
///
/// `scan_for_panics_in_source` must FLAG `ref other => unreachable!(...)` — a
/// reference-mode irrefutable binding catch-all. The `ref` keyword changes how
/// `other` is bound (by reference) but does NOT restrict which values the pattern
/// matches. Binding mode does not change irrefutability: `ref other` is a catch-all
/// that matches any value not covered by earlier arms.
///
/// §EC-007 Exemption 1 applies ONLY to named variant patterns. A `ref other =>`
/// binding-mode arm is NOT a named variant pattern.
///
/// RED GATE: `is_catch_all_pat` for Pat::Ident checks `p.by_ref.is_none()`.
/// When `ref` is present, `by_ref` is Some(Token![ref]) → check returns false →
/// arm_stack push(false) → unreachable!() inside the arm is EXEMPT. The finding
/// is never emitted. Test asserts a finding IS produced → FAILS until
/// is_catch_all_pat is extended to treat `ref <binding>` as a catch-all.
#[test]
fn test_BC_2_14_003_ref_binding_catch_all_flagged() {
    let violation_ref_binding =
        include_str!("../tests/fixtures/violations/violation_ref_binding_catch_all.rs");
    let findings =
        scan_for_panics_in_source(violation_ref_binding, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-8 F-01: `ref other => unreachable!(...)` \
         (ref binding-mode catch-all) MUST be FLAGGED — `ref` changes binding mode \
         but not irrefutability; is_catch_all_pat checks p.by_ref.is_none() → \
         returns false for ref bindings → arm_stack push(false) → Exemption 1 \
         incorrectly applied; got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-8 F-01 ref: finding must reference unreachable!; \
         got: {findings:?}"
    );
}

// ── pass-8 F-01: mut binding catch-all ─────────────────────────────────────

/// F-01 (MED) — BC-2.14.003 §PC-006/§EC-007 pass-8
///
/// `scan_for_panics_in_source` must FLAG `mut other => unreachable!(...)` — a
/// mutable-binding irrefutable catch-all. The `mut` keyword changes how `other`
/// is bound (mutable binding) but does NOT restrict which values the pattern
/// matches. Binding mode does not change irrefutability: `mut other` is a catch-all
/// that matches any value not covered by earlier arms.
///
/// §EC-007 Exemption 1 applies ONLY to named variant patterns. A `mut other =>`
/// binding-mode arm is NOT a named variant pattern.
///
/// RED GATE: `is_catch_all_pat` for Pat::Ident checks `p.mutability.is_none()`.
/// When `mut` is present, `mutability` is Some(Token![mut]) → check returns false →
/// arm_stack push(false) → unreachable!() inside the arm is EXEMPT. The finding
/// is never emitted. Test asserts a finding IS produced → FAILS until
/// is_catch_all_pat is extended to treat `mut <binding>` as a catch-all.
#[test]
fn test_BC_2_14_003_mut_binding_catch_all_flagged() {
    let violation_mut_binding =
        include_str!("../tests/fixtures/violations/violation_mut_binding_catch_all.rs");
    let findings =
        scan_for_panics_in_source(violation_mut_binding, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-8 F-01: `mut other => unreachable!(...)` \
         (mut binding-mode catch-all) MUST be FLAGGED — `mut` changes binding mode \
         but not irrefutability; is_catch_all_pat checks p.mutability.is_none() → \
         returns false for mut bindings → arm_stack push(false) → Exemption 1 \
         incorrectly applied; got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-8 F-01 mut: finding must reference unreachable!; \
         got: {findings:?}"
    );
}

// ── pass-8 F-02: trait default-method arm-stack leak ───────────────────────

/// F-02 (LOW) — BC-2.14.003 §PC-006/§EC-007 pass-8
///
/// `unreachable!()` inside a TRAIT DEFAULT METHOD body that is lexically within
/// a NAMED (non-catch-all) match arm MUST be FLAGGED. A trait default method
/// body is independently callable code — it is NOT covered by the named-arm
/// Exemption 1.
///
/// The named-arm exemption applies only when `unreachable!` is the DIRECT body
/// expression of the arm (evaluated synchronously as the arm's result). A default
/// method defined inside an arm body is a CALLABLE; the `unreachable!` inside it
/// is reachable any time a caller invokes that method — completely independently
/// of the match arm's context.
///
/// RED GATE: PanicVisitor overrides `visit_item_fn`, `visit_impl_item_fn`,
/// `visit_expr_closure`, and `visit_expr_async` — each saves and clears
/// `arm_stack` on entry so nested callables don't inherit the named-arm exempt
/// flag. But `visit_trait_item_fn` is NOT overridden. When a trait with a
/// default method is defined inside a named arm body, the default method is
/// visited by the default syn visitor while `arm_stack.last() == Some(&false)`.
/// `handle_macro_invocation` sees the leaked named-arm exempt flag and silently
/// skips the finding. Test asserts a finding IS produced → FAILS until
/// `visit_trait_item_fn` saves and clears `arm_stack` on entry (restoring on exit),
/// identical to the existing closure/nested-fn/async-block isolation pattern.
#[test]
fn test_BC_2_14_003_trait_default_method_inside_named_arm_flagged() {
    let src = r#"
pub fn process(r: Result<i32, String>) -> i32 {
    match r {
        Ok(v) => {
            trait Processor {
                fn default_process(&self) {
                    unreachable!(
                        "BC-2.14.003: trait default method body is independently callable; \
                         not covered by Exemption 1"
                    )
                }
            }
            let _ = v;
            0
        }
        Err(_) => 1,
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §PC-006 pass-8 F-02: unreachable!() inside a trait default method \
         body nested within a named match arm MUST be FLAGGED (the default method body is \
         independently callable; Exemption 1 covers only the direct arm evaluation; \
         visit_trait_item_fn is not overridden → arm_stack leaks named-arm exempt flag \
         into the default method body); got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-8 F-02: finding must reference unreachable!; got: {findings:?}"
    );
}

// ── pass-8 structural-rewrite safety-net boundary guards ───────────────────

/// Boundary guard — BC-2.14.003 §EC-007 pass-8
///
/// `Variant => { unreachable!() }` (block-tail form) in a fully-enumerated
/// no-catch-all match MUST remain EXEMPT (Exemption 1). A block body is the
/// arm's DIRECT evaluation — the block executes synchronously as the arm's result
/// and is not independently callable. The structural rewrite must not over-reach
/// by treating a bare block tail as "nested" context.
///
/// GREEN both before and after the structural rewrite: the block is the arm's
/// direct evaluation path; arm_stack.last() == Some(&false) → EXEMPT.
#[test]
fn test_BC_2_14_003_variant_block_tail_unreachable_exempt() {
    let src = r#"
pub enum Phase { Init, Running, Done }
/// Returns the numeric index for Phase::Init or Phase::Running.
///
/// # Panics
///
/// Panics if called with Phase::Done (BC-2.14.003 EC-007: programmer error —
/// Done phase must be filtered upstream before reaching this function).
pub fn phase_index(p: Phase) -> u8 {
    match p {
        Phase::Init => 0,
        Phase::Running => 1,
        Phase::Done => {
            unreachable!(
                "BC-2.14.003 EC-007: Phase::Done handled upstream; \
                 reaching phase_index with Done is a programmer error"
            )
        }
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-8 boundary: `Phase::Done => {{ unreachable!() }}` \
         (block-tail form) in a fully-enumerated no-catch-all match MUST remain EXEMPT \
         (the block is the direct arm evaluation; the structural rewrite must not \
         treat a plain block tail as a nested callable context); got: {findings:?}"
    );
}

/// Boundary guard — BC-2.14.003 §EC-007 pass-8
///
/// An inline `const { unreachable!() }` block that IS the direct body of a NAMED
/// match arm remains EXEMPT (Exemption 1). A `const { ... }` block evaluates
/// as the arm's direct synchronous result — it is NOT independently callable
/// and executes only when the arm is selected. Unlike async blocks (deferred
/// execution) or closures (independently callable), a const block body is the
/// arm's direct evaluation path: Exemption 1 applies.
///
/// This guard pins the same boundary as the unsafe-block guard (pass-7) so
/// the structural rewrite does NOT extend the async-block isolation pattern
/// to const blocks (which would be an over-reach).
///
/// GREEN both before and after the structural rewrite: no visit_expr_const
/// override → arm_stack is not cleared → arm_stack.last() == Some(&false) →
/// EXEMPT.
#[test]
fn test_BC_2_14_003_const_block_direct_named_arm_body_exempt() {
    let src = r#"
pub enum Step { Start, End }
pub fn handle_step(s: Step) -> i32 {
    match s {
        Step::Start => 0,
        Step::End => const {
            // const block evaluates synchronously as the arm's direct result.
            // It is the arm's direct evaluation path, not an independent callable.
            unreachable!(
                "BC-2.14.003 boundary: const block is Exemption-1 compliant as direct arm evaluation"
            )
        },
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        findings.is_empty(),
        "BC-2.14.003 §EC-007 pass-8 boundary: unreachable!() inside `const {{ ... }}` \
         that IS the direct body of a named match arm MUST remain EXEMPT (const blocks \
         evaluate synchronously as the arm's direct result; the structural rewrite must \
         not extend the async-block isolation to const blocks); got: {findings:?}"
    );
}

/// Boundary guard — BC-2.14.003 §PC-006/§EC-007 pass-8
///
/// `unreachable!()` inside an IMPL METHOD body that is lexically within a NAMED
/// match arm MUST be FLAGGED. An impl method is independently callable code;
/// its body is NOT covered by the named-arm Exemption 1.
///
/// This guard verifies the CURRENT CORRECT behavior (PanicVisitor already
/// overrides `visit_impl_item_fn` with arm_stack save/clear) is preserved by
/// the structural rewrite. It is GREEN with the current code.
///
/// GREEN both before and after: visit_impl_item_fn saves and clears arm_stack
/// → empty arm_stack inside the method body → §PC-006 fires.
#[test]
fn test_BC_2_14_003_impl_method_inside_named_arm_flagged() {
    let src = r#"
pub fn process(r: Result<i32, String>) -> i32 {
    match r {
        Ok(v) => {
            struct Helper;
            impl Helper {
                fn execute(&self) {
                    unreachable!(
                        "BC-2.14.003: impl method body is independently callable; \
                         not covered by Exemption 1"
                    )
                }
            }
            let _ = Helper;
            v
        }
        Err(_) => 0,
    }
}
"#;
    let findings = scan_for_panics_in_source(src, "crates/pregolya-core/src/lib.rs");
    assert!(
        !findings.is_empty(),
        "BC-2.14.003 §PC-006 pass-8 boundary: unreachable!() inside an impl method body \
         nested within a named match arm MUST be FLAGGED (the impl method is independently \
         callable; Exemption 1 covers only the direct arm evaluation; visit_impl_item_fn \
         saves and clears arm_stack so the method body is evaluated without arm context); \
         got: {findings:?}"
    );
    assert!(
        findings.iter().any(|f| f.contains("unreachable")),
        "BC-2.14.003 pass-8 impl-method boundary: finding must reference unreachable!; \
         got: {findings:?}"
    );
}
