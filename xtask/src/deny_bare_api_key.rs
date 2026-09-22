//! CI lint gate: reject bare API key string literals in library source files.
//!
//! Implements `cargo xtask deny-bare-api-key` (BC-2.14.005 {PC-006},
//! VP-DI010-02).
//!
//! # Scanning rules
//!
//! - Scans `crates/**/*.rs` for string literals matching provider key prefixes
//!   such as `sk-` (OpenAI), `sk-ant-` (Anthropic), and similar patterns in
//!   non-test source code (BC-2.14.005 {PC-006}).
//! - Files under `tests/` directories and `#[cfg(test)]` blocks are exempt
//!   (test fixtures may reference synthetic key strings for verification).
//! - Exits non-zero when any bare key pattern is found; exits 0 on a clean scan.

use std::process::exit;

/// Entry point for `cargo xtask deny-bare-api-key`.
///
/// Scans `crates/**/*.rs` for bare API key string literals matching known
/// provider prefixes (`sk-`, `sk-ant-`, etc.) in non-test source. Exits non-zero
/// on any violation (BC-2.14.005 {PC-006}).
pub fn run() {
    let output = std::process::Command::new("find")
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
        eprintln!("ERROR: deny-bare-api-key scanned 0 files — gate cannot certify anything");
        exit(1);
    }

    let mut all_findings: Vec<String> = Vec::new();
    let mut files_analyzed = 0usize;
    let mut files_exempt = 0usize;
    let mut files_unreadable = 0usize;

    for file_path in files_str.lines() {
        if crate::is_lint_exempt_file(file_path) {
            files_exempt += 1;
            continue;
        }
        let content = match std::fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(_) => {
                files_unreadable += 1;
                continue;
            }
        };
        files_analyzed += 1;
        let findings = scan_for_bare_api_keys_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if files_unreadable > 0 {
        eprintln!(
            "ERROR: deny-bare-api-key could not read {files_unreadable} file(s) — gate cannot certify anything"
        );
        exit(1);
    }
    if !all_findings.is_empty() {
        eprintln!("ERROR: bare API key string literals in non-test code (BC-2.14.005 {{PC-006}}):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!(
        "deny-bare-api-key PASSED: {files_analyzed} analyzed, {files_exempt} exempt, 0 unreadable, 0 violations."
    );
}

/// Scans a single Rust source file for bare API key string literals outside
/// `#[cfg(test)]` blocks.
///
/// Detects string literals that start with known provider key prefixes:
/// - `sk-` (OpenAI)
/// - `sk-ant-` (Anthropic — a subset, but caught by `sk-` prefix check)
///
/// Returns a `Vec<String>` of violation messages. Returns empty when clean.
///
/// Used by `run()` and exposed `pub(crate)` for unit tests.
pub(crate) fn scan_for_bare_api_keys_in_source(src: &str, path: &str) -> Vec<String> {
    if crate::is_lint_exempt_file(path) {
        return Vec::new();
    }

    use proc_macro2::TokenStream;
    let ts: TokenStream = match src.parse() {
        Ok(s) => s,
        Err(e) => return vec![format!("{}:0: FAILED TO LEX FILE: {}", path, e)],
    };

    let mut findings = Vec::new();
    walk_for_bare_api_keys(ts.into_iter(), &mut findings, path, &mut 0u32);
    findings
}

/// Known API key prefixes. A string literal that starts with any of these is a violation.
const API_KEY_PREFIXES: &[&str] = &["sk-", "sk-ant-"];

fn walk_for_bare_api_keys(
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
            // Detect `#[cfg(test)]` — skip the body
            TokenTree::Punct(p) if p.as_char() == '#' => {
                if let Some(TokenTree::Group(g)) = tokens.get(i + 1)
                    && g.delimiter() == Delimiter::Bracket
                    && crate::is_cfg_test_group(g)
                {
                    let mut j = i + 2;
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
                    let mut found = false;
                    while j < tokens.len() {
                        match &tokens[j] {
                            TokenTree::Group(body) if body.delimiter() == Delimiter::Brace => {
                                *in_test_depth += 1;
                                walk_for_bare_api_keys(
                                    body.stream().into_iter(),
                                    findings,
                                    path,
                                    in_test_depth,
                                );
                                *in_test_depth -= 1;
                                i = j;
                                found = true;
                                break;
                            }
                            TokenTree::Punct(p2) if p2.as_char() == ';' => {
                                i = j;
                                found = true;
                                break;
                            }
                            _ => {}
                        }
                        j += 1;
                    }
                    if found {
                        i += 1;
                        continue;
                    }
                }
            }
            // Brace group NOT cfg(test) — recurse at same depth
            TokenTree::Group(g) if g.delimiter() == Delimiter::Brace => {
                walk_for_bare_api_keys(g.stream().into_iter(), findings, path, in_test_depth);
            }
            // Check string literals for API key prefixes
            TokenTree::Literal(lit) if *in_test_depth == 0 => {
                let s = lit.to_string();
                // proc_macro2 Literal::to_string() for string literals includes the
                // surrounding quotes: `"sk-abc123"`. Strip the outer quotes and check prefixes.
                if let Some(inner) = s.strip_prefix('"').and_then(|s| s.strip_suffix('"')) {
                    for prefix in API_KEY_PREFIXES {
                        if inner.starts_with(prefix) {
                            let line = lit_line(lit);
                            findings.push(format!(
                                "{}:{}: bare API key literal starting with {:?} (BC-2.14.005 {{PC-006}})",
                                path, line, prefix
                            ));
                            break;
                        }
                    }
                }
            }
            // Other groups (parens, brackets) — recurse at same depth
            TokenTree::Group(g) => {
                walk_for_bare_api_keys(g.stream().into_iter(), findings, path, in_test_depth);
            }
            _ => {}
        }
        i += 1;
    }
}

fn lit_line(lit: &proc_macro2::Literal) -> usize {
    lit.span().start().line
}
