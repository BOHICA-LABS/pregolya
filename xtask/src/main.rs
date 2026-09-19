//! cargo xtask — workspace task runner for pregolya.
//!
//! Usage: cargo xtask <subcommand>
//!
//! Subcommands:
//!   check-file-size   Enforce production file size gates (CLAUDE.md §File size & module splitting)
//!   check-client-timeout  CI lint gate: reject reqwest Client::new() outside tests
//!   check-no-panic    CI lint gate: reject .expect()/.unwrap() in library src/
//!   deny-anyhow-in-lib    CI lint gate: reject anyhow imports in library crates
//!   deny-description-cache-key  CI lint gate: reject description-proxy cache-key usage

use std::process::{Command, exit};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let subcommand = args.get(1).map(String::as_str).unwrap_or("");
    match subcommand {
        "check-file-size" => check_file_size(),
        "check-client-timeout" => check_client_timeout(),
        "check-no-panic" => check_no_panic(),
        "deny-anyhow-in-lib" => deny_anyhow_in_lib(),
        "deny-description-cache-key" => deny_description_cache_key(),
        _ => {
            eprintln!("Usage: cargo xtask <subcommand>");
            eprintln!("Subcommands:");
            eprintln!(
                "  check-file-size           File size gate (prod 500/750, test 1000/1500 code-lines)"
            );
            eprintln!(
                "  check-client-timeout      Lint: reqwest Client::new() outside tests is forbidden"
            );
            eprintln!(
                "  check-no-panic            Lint: .expect()/.unwrap() in library src/ is forbidden"
            );
            eprintln!(
                "  deny-anyhow-in-lib        Lint: anyhow imports in pregolya-* library crates"
            );
            eprintln!("  deny-description-cache-key Lint: description-proxy cache-key usage");
            exit(1);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns true when `path` identifies a non-production file (tests or examples).
///
/// Matches:
/// - Files named `tests.rs` (any directory depth, e.g. `src/tests.rs`)
/// - Files ending with `_test.rs` or `_tests.rs`
/// - Files under a `tests/` directory component (e.g. `crates/foo/tests/integration.rs`)
/// - Files under an `examples/` directory component (demonstration executables, not
///   library code; permitted to use `.expect()` and `println!` for clarity)
///
/// Does NOT use `.contains("test")` substring matching, which would
/// incorrectly suppress production files in crates whose names contain
/// "test" (e.g. `pregolya-standard-tests`).
fn is_test_file(path: &str) -> bool {
    path.ends_with("/tests.rs")
        || path == "tests.rs"
        || path.contains("/tests/")
        || path.ends_with("_test.rs")
        || path.ends_with("_tests.rs")
        || path.contains("/examples/")
}

/// Returns true for files exempt from lint scanners: test files, examples, and benchmarks.
///
/// Extends `is_test_file` to also cover `/benches/` (benchmark harnesses are not
/// library code). Examples produce standalone binaries and may legitimately use
/// `.expect()` and `println!` for demonstration clarity.
///
/// Used by: `check_no_panic`, `check_client_timeout`, `deny_anyhow_in_lib`.
fn is_lint_exempt_file(path: &str) -> bool {
    is_test_file(path) || path.contains("/benches/")
}

/// Returns true for files that qualify for TEST file-size thresholds (1000/1500 code-lines).
///
/// Only actual test files — NOT examples (demonstration programs use production thresholds)
/// and NOT benchmarks (which are tuning tools, not test suites).
///
/// Used by: `check_file_size`.
fn is_test_class_file(path: &str) -> bool {
    path.ends_with("/tests.rs")
        || path == "tests.rs"
        || path.contains("/tests/")
        || path.ends_with("_test.rs")
        || path.ends_with("_tests.rs")
}

// ─────────────────────────────────────────────────────────────────────────────
// check-file-size
// ─────────────────────────────────────────────────────────────────────────────

/// Count code lines (non-blank, non-comment-only) inside `#[cfg(test)] mod` blocks.
///
/// Uses proc_macro2 span information to locate the block boundaries, then applies
/// tokei-compatible line counting (skipping blank lines and lines whose first
/// non-whitespace token is `//`).
///
/// Returns 0 if the file cannot be parsed or has no cfg(test) block.
///
/// The subtraction of this count from tokei's `Code` metric gives the adjusted
/// production code line count per CLAUDE.md §File size: "#[cfg(test)] mod blocks
/// excluded from the count."
fn count_cfg_test_lines(path: &std::path::Path) -> usize {
    use proc_macro2::{Delimiter, TokenStream, TokenTree};

    let Ok(source) = std::fs::read_to_string(path) else {
        return 0;
    };
    let Ok(ts) = source.parse::<TokenStream>() else {
        return 0;
    };

    let lines: Vec<&str> = source.lines().collect();
    let mut total = 0usize;

    // Walk top-level token stream looking for:
    //   #[cfg(test)]
    //   <optional intervening #[...] attributes>
    //   mod <ident> { ... }   ← count the Group's line span
    let tokens: Vec<TokenTree> = ts.into_iter().collect();
    let mut i = 0;
    while i < tokens.len() {
        // Look for `#` followed by `[cfg(test)]` bracket group.
        // Edition 2024 let-chains collapse nested ifs without sacrificing readability.
        if let TokenTree::Punct(p) = &tokens[i]
            && p.as_char() == '#'
            && let Some(TokenTree::Group(attr_group)) = tokens.get(i + 1)
            && attr_group.delimiter() == Delimiter::Bracket
        {
            let attr_str = attr_group.to_string();
            if attr_str.contains("cfg") && attr_str.contains("test") {
                // Scan forward past optional intervening attributes
                // (e.g. `#[allow(clippy::unwrap_used)]`) then find `mod <ident> { ... }`
                let mut j = i + 2;
                // Skip intervening `#[...]` attributes
                while j + 1 < tokens.len() {
                    if let TokenTree::Punct(p2) = &tokens[j]
                        && p2.as_char() == '#'
                        && let TokenTree::Group(_) = &tokens[j + 1]
                    {
                        j += 2;
                        continue;
                    }
                    break;
                }
                // Expect `mod <ident> { ... }`
                // tokens[j+1] = mod name ident, tokens[j+2] = body Group
                if let Some(TokenTree::Ident(mod_kw)) = tokens.get(j)
                    && mod_kw == "mod"
                    && let Some(TokenTree::Group(mod_group)) = tokens.get(j + 2)
                    && mod_group.delimiter() == Delimiter::Brace
                {
                    let span = mod_group.span();
                    let start_line = span.start().line; // 1-based
                    let end_line = span.end().line; // 1-based
                    // Count non-blank, non-comment-only lines
                    // in [start_line, end_line] (inclusive, 1-based).
                    for line in lines[(start_line - 1)..end_line.min(lines.len())].iter() {
                        let trimmed = line.trim();
                        if !trimmed.is_empty() && !trimmed.starts_with("//") {
                            total += 1;
                        }
                    }
                    // Advance past the mod block
                    i = j + 3;
                    continue;
                }
            }
        }
        i += 1;
    }
    total
}

fn check_file_size() {
    // Implements CLAUDE.md §File size: "#[cfg(test)] mod blocks...excluded from the count."
    // For production files, the raw tokei Code count is adjusted by subtracting
    // lines inside `#[cfg(test)] mod` blocks (see count_cfg_test_lines).
    // Test files (under tests/ or ending with _test.rs/_tests.rs) use the higher
    // test-file thresholds (1000/1500) without adjustment.
    //
    // Exclusions (auto-skipped in post-processing):
    //   *.gen.rs          — generated code, not subject to size gate
    //   paths with /target/ or OUT_DIR  — build artifacts
    //   paths with /tests/fixtures/     — test fixture data
    //
    // Scan paths: crates/ + xtask/src/ (both are workspace members).
    let output = Command::new("tokei")
        .args([
            "--output",
            "json",
            "--exclude",
            "*.gen.rs",
            "--exclude",
            "*/tests/fixtures/*",
            "crates/",
            "xtask/src/",
        ])
        .output();

    let output = match output {
        Ok(o) => o,
        Err(_) => {
            eprintln!("ERROR: tokei not found on PATH. Install with: cargo install tokei --locked");
            eprintln!("The file-size gate requires tokei to measure code lines.");
            eprintln!("Run 'just setup' to install all required tools.");
            exit(1);
        }
    };

    if !output.status.success() {
        eprintln!("tokei failed: {}", String::from_utf8_lossy(&output.stderr));
        exit(1);
    }

    let json: serde_json::Value = match serde_json::from_slice(&output.stdout) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Failed to parse tokei output: {e}");
            exit(1);
        }
    };

    let allowlist = load_allowlist();
    let prod_soft: u64 = 500;
    let prod_hard: u64 = 750;
    let test_soft: u64 = 1000;
    let test_hard: u64 = 1500;

    let mut violations: Vec<String> = Vec::new();
    let mut warnings: Vec<String> = Vec::new();
    let mut files_measured: usize = 0;
    let mut files_skipped: usize = 0;

    // F2 fix: exit with diagnostic when tokei found no Rust files or has empty reports.
    let rust = match json.get("Rust") {
        Some(r) => r,
        None => {
            eprintln!(
                "ERROR: tokei found no Rust files — gate cannot certify anything. \
                 Is the scan path correct?"
            );
            exit(1);
        }
    };
    let reports = match rust.get("reports").and_then(|r| r.as_array()) {
        Some(r) if !r.is_empty() => r,
        Some(_) => {
            eprintln!("ERROR: tokei returned empty reports array — gate cannot certify anything.");
            exit(1);
        }
        None => {
            eprintln!(
                "ERROR: tokei output missing 'reports' array — gate cannot certify anything."
            );
            exit(1);
        }
    };

    for report in reports {
        let name = report
            .get("name")
            .and_then(|n| n.as_str())
            .unwrap_or("<unknown>");
        let code = report
            .get("stats")
            .and_then(|s| s.get("code"))
            .and_then(|c| c.as_u64())
            .unwrap_or(0);

        // Skip generated code, build artifacts, and fixture data.
        if name.contains("/target/")
            || name.contains("OUT_DIR")
            || name.ends_with(".gen.rs")
            || name.contains("/tests/fixtures/")
        {
            continue;
        }

        if allowlist.is_allowed(name) {
            files_skipped += 1;
            continue;
        }

        files_measured += 1;

        let is_test = is_test_class_file(name);
        let (soft, hard) = if is_test {
            (test_soft, test_hard)
        } else {
            (prod_soft, prod_hard)
        };

        // For production files, subtract inline #[cfg(test)] block lines from the
        // tokei Code count per CLAUDE.md §File size: "#[cfg(test)] mod blocks...
        // excluded from the count."  Test files already use the test thresholds so
        // no adjustment is applied to them.
        let adjusted_code = if !is_test {
            let cfg_test_lines = count_cfg_test_lines(std::path::Path::new(name));
            code.saturating_sub(cfg_test_lines as u64)
        } else {
            code
        };

        if adjusted_code > hard {
            violations.push(format!(
                "HARD GATE FAIL: {name} has {adjusted_code} code lines (limit: {hard})"
            ));
        } else if adjusted_code > soft {
            warnings.push(format!(
                "soft warning: {name} has {adjusted_code} code lines (soft limit: {soft})"
            ));
        }
    }

    for w in &warnings {
        eprintln!("WARN: {w}");
    }

    if !violations.is_empty() {
        for v in &violations {
            eprintln!("ERROR: {v}");
        }
        eprintln!(
            "File size gate FAILED. Add an allowlist entry to xtask/file-size-allowlist.toml or split the file."
        );
        exit(1);
    }

    assert!(
        files_measured > 0,
        "check-file-size: scanned 0 files — gate is vacuously true; check that crates/ exists and contains Rust source files"
    );
    println!(
        "check-file-size PASSED ({} warnings, {files_measured} files measured, {files_skipped} allowlisted).",
        warnings.len()
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// check-client-timeout (NE-04 / DI-009)
// ─────────────────────────────────────────────────────────────────────────────

fn check_client_timeout() {
    // Scan library crate src/ for reqwest Client::new() outside test files.
    // Uses file-by-file scanning (same as check-no-panic) so that path-based
    // exclusions are applied correctly — grep line filtering with contains("test")
    // would incorrectly suppress production code in crates whose path contains
    // "test" (e.g. pregolya-standard-tests).
    let output = Command::new("find")
        .args(["crates/", "-name", "*.rs", "-not", "-path", "*/target/*"])
        .output();

    let files_output = match output {
        Ok(o) => o,
        Err(e) => {
            eprintln!("find failed: {e}");
            exit(1);
        }
    };

    // F2 fix: check subprocess exit status
    if !files_output.status.success() {
        eprintln!(
            "ERROR: file discovery command failed with status {}",
            files_output.status
        );
        exit(1);
    }

    let files_str = String::from_utf8_lossy(&files_output.stdout);
    // F2 fix: count files scanned; exit if zero (gate cannot certify anything)
    let files_scanned = files_str.lines().count();
    if files_scanned == 0 {
        eprintln!("ERROR: check-client-timeout scanned 0 files — gate cannot certify anything");
        exit(1);
    }

    let mut all_findings: Vec<String> = Vec::new();

    for file_path in files_str.lines() {
        let content = match std::fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(_) => continue,
        };
        let findings = scan_for_timeout_violations_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if !all_findings.is_empty() {
        for f in &all_findings {
            eprintln!("ERROR: reqwest::Client::new() without timeout: {f}");
        }
        eprintln!("Use Client::builder().timeout(Duration::from_secs(30)).build() instead.");
        exit(1);
    }
    println!("check-client-timeout PASSED: {files_scanned} files scanned, 0 violations.");
}

/// Scan `src` for reqwest client timeout violations using `proc_macro2` token-tree walking.
///
/// Detects:
///   - `reqwest::Client::new()` (fully qualified)
///   - `Client::new()` (unqualified, from `use reqwest::Client`)
///   - `Client::builder().build()` or `reqwest::Client::builder()...build()` without `.timeout()`
///
/// Uses token-level scanning so string literals, comments, and char literals
/// (which were the source of F-2, B-5, and related false positive/negative bugs)
/// are handled correctly by the lexer.
fn scan_for_timeout_violations_in_source(src: &str, path: &str) -> Vec<String> {
    if is_lint_exempt_file(path) {
        return Vec::new();
    }

    use proc_macro2::TokenStream;

    let ts: TokenStream = match src.parse() {
        Ok(s) => s,
        Err(e) => return vec![format!("{}:0: FAILED TO LEX FILE: {}", path, e)],
    };

    let mut findings = Vec::new();
    walk_timeout_tokens(ts.into_iter(), &mut findings, path);
    findings
}

/// Recursive token-tree walker for `scan_for_timeout_violations_in_source`.
fn walk_timeout_tokens(
    iter: proc_macro2::token_stream::IntoIter,
    findings: &mut Vec<String>,
    path: &str,
) {
    use proc_macro2::{Delimiter, TokenTree};

    let tokens: Vec<TokenTree> = iter.collect();
    let mut i = 0;
    while i < tokens.len() {
        // Recurse into any group (brace, paren, bracket).
        if let TokenTree::Group(g) = &tokens[i] {
            walk_timeout_tokens(g.stream().into_iter(), findings, path);
            i += 1;
            continue;
        }

        // Try to match: reqwest :: Client :: new ( ... )
        // Token sequence: Ident("reqwest") Punct(":") Punct(":") Ident("Client")
        //                 Punct(":") Punct(":") Ident("new") Group(Paren)
        if matches!(&tokens[i], TokenTree::Ident(id) if id == "reqwest") {
            if is_double_colon(&tokens, i + 1)
                && matches!(tokens.get(i + 3), Some(TokenTree::Ident(id)) if id == "Client")
                && is_double_colon(&tokens, i + 4)
                && matches!(tokens.get(i + 6), Some(TokenTree::Ident(id)) if id == "new")
                && matches!(tokens.get(i + 7), Some(TokenTree::Group(g)) if g.delimiter() == Delimiter::Parenthesis)
            {
                let line = if let Some(TokenTree::Ident(id)) = tokens.get(i + 6) {
                    id.span().start().line
                } else {
                    0
                };
                findings.push(format!("{}:{}: reqwest::Client::new()", path, line));
                i += 8;
                continue;
            }
            // Also check reqwest :: Client :: builder() chain
            if is_double_colon(&tokens, i + 1)
                && matches!(tokens.get(i + 3), Some(TokenTree::Ident(id)) if id == "Client")
                && is_double_colon(&tokens, i + 4)
                && matches!(tokens.get(i + 6), Some(TokenTree::Ident(id)) if id == "builder")
            {
                if let Some(finding) = check_builder_chain_violation(&tokens, i, path) {
                    findings.push(finding);
                }
                i += 1;
                continue;
            }
        }

        // Try to match standalone Client :: new ( ... ) — NOT preceded by `:`.
        // Preceding `:` means this Client is part of a qualified path (mcp_sdk::Client),
        // which must not be flagged.
        if matches!(&tokens[i], TokenTree::Ident(id) if id == "Client") {
            let prev_is_colon =
                i > 0 && matches!(&tokens[i - 1], TokenTree::Punct(p) if p.as_char() == ':');
            if !prev_is_colon {
                // Check for Client :: new ( ... )
                if is_double_colon(&tokens, i + 1)
                    && matches!(tokens.get(i + 3), Some(TokenTree::Ident(id)) if id == "new")
                    && matches!(tokens.get(i + 4), Some(TokenTree::Group(g)) if g.delimiter() == Delimiter::Parenthesis)
                {
                    let line = if let Some(TokenTree::Ident(id)) = tokens.get(i + 3) {
                        id.span().start().line
                    } else {
                        0
                    };
                    findings.push(format!("{}:{}: Client::new()", path, line));
                    i += 5;
                    continue;
                }
                // Check for Client :: builder chain
                if is_double_colon(&tokens, i + 1)
                    && matches!(tokens.get(i + 3), Some(TokenTree::Ident(id)) if id == "builder")
                {
                    if let Some(finding) = check_builder_chain_violation(&tokens, i, path) {
                        findings.push(finding);
                    }
                    i += 1;
                    continue;
                }
            }
        }

        i += 1;
    }
}

/// Returns true when `tokens[idx]` and `tokens[idx+1]` are both `:` puncts.
fn is_double_colon(tokens: &[proc_macro2::TokenTree], idx: usize) -> bool {
    use proc_macro2::TokenTree;
    matches!(tokens.get(idx), Some(TokenTree::Punct(p)) if p.as_char() == ':')
        && matches!(tokens.get(idx + 1), Some(TokenTree::Punct(p)) if p.as_char() == ':')
}

/// Scan forward from `start` to find a `.build()` call in a builder chain.
/// Returns a finding if `.build()` is reached without `.timeout()`.
/// Stops at `;` (end of statement) without returning a finding.
fn check_builder_chain_violation(
    tokens: &[proc_macro2::TokenTree],
    start: usize,
    path: &str,
) -> Option<String> {
    use proc_macro2::TokenTree;
    let mut has_timeout = false;
    let mut i = start;
    while i < tokens.len() {
        match &tokens[i] {
            TokenTree::Punct(p) if p.as_char() == ';' => return None,
            TokenTree::Punct(p) if p.as_char() == '.' => {
                if let Some(TokenTree::Ident(id)) = tokens.get(i + 1) {
                    let name = id.to_string();
                    if name == "timeout" {
                        has_timeout = true;
                    }
                    if name == "build" {
                        let line = id.span().start().line;
                        if !has_timeout {
                            return Some(format!(
                                "{}:{}: Client::builder().build() without .timeout()",
                                path, line
                            ));
                        } else {
                            return None;
                        }
                    }
                }
            }
            _ => {}
        }
        i += 1;
    }
    None
}

// ─────────────────────────────────────────────────────────────────────────────
// check-no-panic (NE-07)
// ─────────────────────────────────────────────────────────────────────────────

fn check_no_panic() {
    // Scan library src/ for .unwrap() and .expect() outside #[cfg(test)] blocks.
    // Uses a file-level scanner to track test-block boundaries via brace depth,
    // avoiding false positives on legitimate test code (CLAUDE.md §SID-1).
    let output = Command::new("find")
        .args(["crates/", "-name", "*.rs", "-not", "-path", "*/target/*"])
        .output();

    let files_output = match output {
        Ok(o) => o,
        Err(e) => {
            eprintln!("find failed: {e}");
            exit(1);
        }
    };

    // F2 fix: check subprocess exit status
    if !files_output.status.success() {
        eprintln!(
            "ERROR: file discovery command failed with status {}",
            files_output.status
        );
        exit(1);
    }

    let files_str = String::from_utf8_lossy(&files_output.stdout);
    // F2 fix: count files scanned; exit if zero (gate cannot certify anything)
    let files_scanned = files_str.lines().count();
    if files_scanned == 0 {
        eprintln!("ERROR: check-no-panic scanned 0 files — gate cannot certify anything");
        exit(1);
    }

    let mut all_findings: Vec<String> = Vec::new();

    for file_path in files_str.lines() {
        let content = match std::fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(_) => continue,
        };
        let findings = scan_for_panics_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if !all_findings.is_empty() {
        for f in &all_findings {
            eprintln!("ERROR: panic-potential in library code: {f}");
        }
        eprintln!("Use ? propagation with structured error variants instead.");
        exit(1);
    }
    println!("check-no-panic PASSED: {files_scanned} files scanned, 0 violations.");
}

/// Scan `src` for `.unwrap()` and `.expect(` patterns outside `#[cfg(test)]` scopes.
///
/// Uses `proc_macro2` token-tree walking so that string literals, char literals,
/// and comments are handled at the lexer level rather than via ad-hoc string
/// scanning. This eliminates the entire class of F-1/B-2/B-3/B-6/B-7/B-8 edge
/// cases.
///
/// Returns a `Vec<String>` of `"path:line_num: .method()"` findings.
/// Returns empty when `path` is a test file (per `is_test_file`).
fn scan_for_panics_in_source(src: &str, path: &str) -> Vec<String> {
    if is_lint_exempt_file(path) {
        return Vec::new();
    }

    use proc_macro2::TokenStream;

    let ts: TokenStream = match src.parse() {
        Ok(s) => s,
        Err(e) => return vec![format!("{}:0: FAILED TO LEX FILE: {}", path, e)],
    };

    let mut findings = Vec::new();
    walk_panic_tokens(ts.into_iter(), &mut findings, path, &mut 0u32);
    findings
}

/// Recursive token-tree walker for `scan_for_panics_in_source`.
fn walk_panic_tokens(
    iter: proc_macro2::token_stream::IntoIter,
    findings: &mut Vec<String>,
    path: &str,
    in_test_depth: &mut u32,
) {
    use proc_macro2::{Delimiter, TokenTree};

    let tokens: Vec<TokenTree> = iter.collect();
    let mut i = 0;
    while i < tokens.len() {
        match &tokens[i] {
            // Detect `#` followed by a `[...]` group — could be `#[cfg(test)]`.
            TokenTree::Punct(p) if p.as_char() == '#' => {
                if let Some(TokenTree::Group(g)) = tokens.get(i + 1)
                    && g.delimiter() == Delimiter::Bracket
                    && is_cfg_test_group(g)
                {
                    // Look ahead past the attribute to find the body.
                    // A brace body → walk it with incremented depth.
                    // A semicolon → semicolon-terminated form (use, mod decl, etc.),
                    //   do NOT increment depth (no inline block to suppress).
                    let mut j = i + 2;
                    while j < tokens.len() {
                        match &tokens[j] {
                            TokenTree::Group(body) if body.delimiter() == Delimiter::Brace => {
                                *in_test_depth += 1;
                                walk_panic_tokens(
                                    body.stream().into_iter(),
                                    findings,
                                    path,
                                    in_test_depth,
                                );
                                *in_test_depth -= 1;
                                i = j; // advance past the body
                                break;
                            }
                            TokenTree::Punct(p2) if p2.as_char() == ';' => {
                                i = j; // advance past the semicolon
                                break;
                            }
                            // Skip ident tokens (mod, fn, tests, etc.) and other attrs
                            _ => {}
                        }
                        j += 1;
                    }
                    i += 1;
                    continue;
                }
            }
            // Brace group NOT preceded by cfg(test) — walk it at current depth.
            TokenTree::Group(g) if g.delimiter() == Delimiter::Brace => {
                walk_panic_tokens(g.stream().into_iter(), findings, path, in_test_depth);
            }
            // Detect `.unwrap` or `.expect` when not inside a test scope.
            TokenTree::Punct(p) if p.as_char() == '.' && *in_test_depth == 0 => {
                if let Some(TokenTree::Ident(id)) = tokens.get(i + 1) {
                    let name = id.to_string();
                    if name == "unwrap" || name == "expect" {
                        let line = id.span().start().line;
                        findings.push(format!("{}:{}: .{}()", path, line, name));
                    }
                }
            }
            // Other non-brace groups (parens, brackets) — walk them too.
            TokenTree::Group(g) => {
                walk_panic_tokens(g.stream().into_iter(), findings, path, in_test_depth);
            }
            _ => {}
        }
        i += 1;
    }
}

/// Returns true when the token-tree group `g` (contents of `[...]`) represents
/// `cfg(test)` — i.e., the bracket stream is exactly `cfg ( test )`.
fn is_cfg_test_group(g: &proc_macro2::Group) -> bool {
    use proc_macro2::{Delimiter, TokenTree};
    let tokens: Vec<TokenTree> = g.stream().into_iter().collect();
    // Expect exactly: Ident("cfg") Group(Paren, [Ident("test")])
    if tokens.len() != 2 {
        return false;
    }
    let is_cfg = matches!(&tokens[0], TokenTree::Ident(id) if id == "cfg");
    let is_test_inner = if let TokenTree::Group(inner) = &tokens[1] {
        if inner.delimiter() == Delimiter::Parenthesis {
            let inner_toks: Vec<TokenTree> = inner.stream().into_iter().collect();
            inner_toks.len() == 1 && matches!(&inner_toks[0], TokenTree::Ident(id) if id == "test")
        } else {
            false
        }
    } else {
        false
    };
    is_cfg && is_test_inner
}

// ─────────────────────────────────────────────────────────────────────────────
// deny-anyhow-in-lib (NE-03 / DI-014 / ADR-010)
// ─────────────────────────────────────────────────────────────────────────────

fn deny_anyhow_in_lib() {
    // Use token-tree walking (proc_macro2) so that `use anyhow` inside
    // `#[cfg(test)]` blocks is not flagged. The blunt `grep` approach fires
    // even when the import is legitimately scoped to test code.
    let output = Command::new("find")
        .args(["crates/", "-name", "*.rs", "-not", "-path", "*/target/*"])
        .output();

    let files_output = match output {
        Ok(o) => o,
        Err(e) => {
            eprintln!("find failed: {e}");
            exit(1);
        }
    };

    // F2 fix: check subprocess exit status
    if !files_output.status.success() {
        eprintln!(
            "ERROR: file discovery command failed with status {}",
            files_output.status
        );
        exit(1);
    }

    let files_str = String::from_utf8_lossy(&files_output.stdout);
    // F2 fix: count files scanned; exit if zero (gate cannot certify anything)
    let files_scanned = files_str.lines().count();
    if files_scanned == 0 {
        eprintln!("ERROR: deny-anyhow-in-lib scanned 0 files — gate cannot certify anything");
        exit(1);
    }

    let mut all_findings: Vec<String> = Vec::new();

    for file_path in files_str.lines() {
        let content = match std::fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(_) => continue,
        };
        let findings = scan_for_anyhow_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if !all_findings.is_empty() {
        eprintln!("ERROR: anyhow is banned from pregolya-* library crates (ADR-010 / NE-03):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!("deny-anyhow-in-lib PASSED: {files_scanned} files scanned, 0 violations.");
}

/// Scan `src` for `use anyhow` patterns outside `#[cfg(test)]` scopes.
///
/// Uses proc_macro2 token-tree walking so that anyhow imports in test code
/// (which are legitimate for compatibility verification) are not flagged.
///
/// Returns a `Vec<String>` of `"path:line: use anyhow"` findings.
/// Returns empty when `path` is a test or examples file (per `is_test_file`).
fn scan_for_anyhow_in_source(src: &str, path: &str) -> Vec<String> {
    if is_lint_exempt_file(path) {
        return Vec::new();
    }

    use proc_macro2::TokenStream;
    let ts: TokenStream = match src.parse() {
        Ok(s) => s,
        Err(e) => return vec![format!("{}:0: FAILED TO LEX FILE: {}", path, e)],
    };

    let mut findings = Vec::new();
    walk_anyhow_tokens(ts.into_iter(), &mut findings, path, &mut 0u32);
    findings
}

/// Recursive token-tree walker for `scan_for_anyhow_in_source`.
fn walk_anyhow_tokens(
    iter: proc_macro2::token_stream::IntoIter,
    findings: &mut Vec<String>,
    path: &str,
    in_test_depth: &mut u32,
) {
    use proc_macro2::{Delimiter, TokenTree};

    let tokens: Vec<TokenTree> = iter.collect();
    let mut i = 0;
    while i < tokens.len() {
        match &tokens[i] {
            // Detect `#[cfg(test)]` — skip the body.
            TokenTree::Punct(p) if p.as_char() == '#' => {
                if let Some(TokenTree::Group(g)) = tokens.get(i + 1)
                    && g.delimiter() == Delimiter::Bracket
                    && is_cfg_test_group(g)
                {
                    let mut j = i + 2;
                    while j < tokens.len() {
                        match &tokens[j] {
                            TokenTree::Group(body) if body.delimiter() == Delimiter::Brace => {
                                *in_test_depth += 1;
                                walk_anyhow_tokens(
                                    body.stream().into_iter(),
                                    findings,
                                    path,
                                    in_test_depth,
                                );
                                *in_test_depth -= 1;
                                i = j;
                                break;
                            }
                            TokenTree::Punct(p2) if p2.as_char() == ';' => {
                                i = j;
                                break;
                            }
                            _ => {}
                        }
                        j += 1;
                    }
                    i += 1;
                    continue;
                }
            }
            // Brace group NOT preceded by cfg(test) — walk it at current depth.
            TokenTree::Group(g) if g.delimiter() == Delimiter::Brace => {
                walk_anyhow_tokens(g.stream().into_iter(), findings, path, in_test_depth);
            }
            // Detect `use` keyword when not inside a test scope.
            TokenTree::Ident(id) if id == "use" && *in_test_depth == 0 => {
                let line = id.span().start().line;
                // Scan forward in the same token list until `;` to find `anyhow`.
                let mut j = i + 1;
                while j < tokens.len() {
                    match &tokens[j] {
                        TokenTree::Ident(id2) if id2 == "anyhow" => {
                            findings.push(format!("{}:{}: use anyhow", path, line));
                            break;
                        }
                        TokenTree::Punct(p) if p.as_char() == ';' => break,
                        // A brace group ends the use tree (e.g. `use foo::{a, b}`)
                        TokenTree::Group(_) => break,
                        _ => {}
                    }
                    j += 1;
                }
            }
            // Other non-brace groups (parens, brackets) — walk them too.
            TokenTree::Group(g) => {
                walk_anyhow_tokens(g.stream().into_iter(), findings, path, in_test_depth);
            }
            _ => {}
        }
        i += 1;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// deny-description-cache-key (NE-05 / ADR-011)
// ─────────────────────────────────────────────────────────────────────────────

fn deny_description_cache_key() {
    // Use file-by-file scanning (same pattern as check-no-panic and check-client-timeout)
    // so that the PASSED message reports the number of files scanned — not grep match counts
    // which are 0 in a clean codebase, making it impossible to distinguish a vacuous pass
    // from a genuine scan.
    let output = Command::new("find")
        .args(["crates/", "-name", "*.rs", "-not", "-path", "*/target/*"])
        .output();

    let files_output = match output {
        Ok(o) => o,
        Err(e) => {
            eprintln!("find failed: {e}");
            exit(1);
        }
    };

    if !files_output.status.success() {
        eprintln!(
            "ERROR: file discovery command failed with status {}",
            files_output.status
        );
        exit(1);
    }

    let files_str = String::from_utf8_lossy(&files_output.stdout);
    let files_scanned = files_str.lines().count();
    if files_scanned == 0 {
        eprintln!(
            "ERROR: deny-description-cache-key scanned 0 files — gate cannot certify anything"
        );
        exit(1);
    }

    let mut all_findings: Vec<String> = Vec::new();

    for file_path in files_str.lines() {
        let content = match std::fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(_) => continue,
        };
        // Scan for description-proxy cache-key patterns: lines containing a cache-key
        // identifier AND a description reference indicate description-proxy cache-key usage.
        for (line_num, line) in content.lines().enumerate() {
            let has_cache_key = line.contains("cache_key")
                || line.contains("CacheKey")
                || line.contains("cache_key_for");
            let has_description = line.contains("description") || line.contains("Description");
            if has_cache_key && has_description {
                all_findings.push(format!("{}:{}: {}", file_path, line_num + 1, line.trim()));
            }
        }
    }

    if !all_findings.is_empty() {
        eprintln!("ERROR: description-proxy cache-key usage (ADR-011 / NE-05):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!("deny-description-cache-key PASSED: {files_scanned} files scanned, 0 violations.");
}

// ─────────────────────────────────────────────────────────────────────────────
// Allowlist support
// ─────────────────────────────────────────────────────────────────────────────

#[derive(serde::Deserialize, Default)]
struct AllowList {
    #[serde(default)]
    allow: Vec<AllowEntry>,
}

#[derive(serde::Deserialize)]
#[cfg_attr(test, derive(Default))]
struct AllowEntry {
    path: String,
    #[allow(dead_code)]
    reason: String,
    #[allow(dead_code)]
    approver: String,
    #[allow(dead_code)]
    date: String,
}

impl AllowList {
    // Allowlist entries MUST use workspace-relative paths (e.g. "crates/pregolya-core/src/error.rs")
    // to prevent over-broad matching. A bare filename like "error.rs" would match every crate's
    // error.rs — use the full path from workspace root instead.
    fn is_allowed(&self, path: &str) -> bool {
        self.allow.iter().any(|e| {
            // Anchor: the allowlist path must match the full workspace-relative path exactly.
            // Normalize both paths to forward slashes for cross-platform consistency.
            let normalized_entry = e.path.replace('\\', "/");
            let normalized_path = path.replace('\\', "/");
            // Exact suffix match anchored at a path separator boundary
            normalized_path == normalized_entry
                || normalized_path.ends_with(&format!("/{normalized_entry}"))
        })
    }
}

/// Validates that an allowlist entry path is workspace-relative and sufficiently deep.
///
/// Returns `Ok(())` if the path is valid, or `Err(String)` with a diagnostic message.
///
/// Rules:
/// - Path MUST start with `"crates/"` or `"xtask/"` (prevents over-broad bare-filename matches).
/// - Path MUST have at least 2 slashes (at least 3 components: prefix/crate/file.rs).
fn validate_allowlist_entry_path(path: &str) -> Result<(), String> {
    if !path.starts_with("crates/") && !path.starts_with("xtask/") {
        return Err(format!(
            "path {path:?} must start with 'crates/' or 'xtask/' (bare filenames match multiple crates)"
        ));
    }
    if path.matches('/').count() < 2 {
        return Err(format!(
            "path {path:?} is too shallow (bare filename would match multiple crates \
             — use a full workspace-relative path)"
        ));
    }
    Ok(())
}

fn load_allowlist() -> AllowList {
    match std::fs::read_to_string("xtask/file-size-allowlist.toml") {
        Ok(content) => match toml::from_str::<AllowList>(&content) {
            Ok(a) => {
                // Validate all entry paths to prevent over-broad matching.
                for entry in &a.allow {
                    if let Err(msg) = validate_allowlist_entry_path(&entry.path) {
                        eprintln!("ERROR: file-size-allowlist.toml: {msg}");
                        exit(1);
                    }
                }
                a
            }
            Err(e) => {
                eprintln!(
                    "ERROR: xtask/file-size-allowlist.toml is malformed and cannot be parsed: {e}"
                );
                exit(1);
            }
        },
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => AllowList::default(),
        Err(e) => {
            eprintln!("ERROR: cannot read xtask/file-size-allowlist.toml: {e}");
            exit(1);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unit tests (file-module form — body lives in tests.rs)
// ─────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests;
