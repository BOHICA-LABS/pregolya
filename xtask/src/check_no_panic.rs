//! CI lint gate: reject `.unwrap()` and `.expect()` in library source files.
//!
//! Implements `cargo xtask check-no-panic` (BC-2.14.003 {PC-004}, VP-DI008-01).
//!
//! # Scanning rules
//!
//! - Scans `crates/**/*.rs` for `.unwrap()` and `.expect(...)` outside
//!   `#[cfg(test)]` scopes.
//! - Files under `tests/` directories, files ending in `_test.rs`/`_tests.rs`,
//!   and files ending in `/tests.rs` are fully exempt (BC-2.14.003 {INV-004}).
//! - `debug_assert!()` is NOT flagged — it compiles out in release mode
//!   (BC-2.14.003 {INV-003}).
//! - Exits non-zero when any violation is found; exits 0 on a clean scan.

use std::process::exit;

/// Entry point for `cargo xtask check-no-panic`.
///
/// Scans `crates/**/*.rs` using token-tree analysis to detect `.unwrap()` and
/// `.expect(...)` calls outside `#[cfg(test)]` blocks. Exits non-zero on any
/// violation (BC-2.14.003 {PC-004}).
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
        eprintln!("ERROR: check-no-panic scanned 0 files — gate cannot certify anything");
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
        let findings = scan_for_panics_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if files_unreadable > 0 {
        eprintln!(
            "ERROR: check-no-panic could not read {files_unreadable} file(s) — gate cannot certify anything"
        );
        exit(1);
    }
    if !all_findings.is_empty() {
        eprintln!("ERROR: .unwrap()/.expect() in non-test library code (BC-2.14.003):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!(
        "check-no-panic PASSED: {files_analyzed} analyzed, {files_exempt} exempt, 0 unreadable, 0 violations."
    );
}

/// Scans a single Rust source file (as a string) for `.unwrap()` / `.expect(...)`
/// calls outside `#[cfg(test)]` blocks.
///
/// Returns a `Vec<String>` of human-readable violation messages, one per
/// detected call site. Returns an empty `Vec` when the source is clean.
///
/// Called by `run()` per-file and exposed as `pub(crate)` so unit tests in
/// `xtask/src/tests.rs` can verify scanner behavior directly.
pub(crate) fn scan_for_panics_in_source(src: &str, path: &str) -> Vec<String> {
    if crate::is_test_file(path) {
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
///
/// Detects `.unwrap()` and `.expect(...)` method calls outside `#[cfg(test)]`
/// blocks. Skips `debug_assert!` (compiles out in release; BC-2.14.003 {INV-003}).
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
            // Detect `#[cfg(test)]` attribute — track whether next token is a
            // brace-delimited group (inline block) or semicolon-terminated decl.
            TokenTree::Punct(p) if p.as_char() == '#' => {
                if let Some(TokenTree::Group(g)) = tokens.get(i + 1)
                    && g.delimiter() == Delimiter::Bracket
                    && crate::is_cfg_test_group(g)
                {
                    // Scan forward past optional intervening `#[...]` attributes
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
                    // Skip to the brace body or semicolon terminator
                    let mut found = false;
                    while j < tokens.len() {
                        match &tokens[j] {
                            TokenTree::Group(body) if body.delimiter() == Delimiter::Brace => {
                                // Recurse into the cfg(test) block at elevated depth
                                *in_test_depth += 1;
                                walk_panic_tokens(
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
                            // Semicolon-terminated: `#[cfg(test)] mod tests;`
                            // No block follows — just advance past the semicolon.
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
                // Not a cfg(test) attribute — fall through to default handling
            }
            // Brace group NOT preceded by cfg(test) — recurse at same depth
            TokenTree::Group(g) if g.delimiter() == Delimiter::Brace => {
                walk_panic_tokens(g.stream().into_iter(), findings, path, in_test_depth);
            }
            // Detect `.unwrap()` or `.expect(...)` — Punct('.') followed by
            // Ident("unwrap"/"expect") followed by Group(Paren)
            TokenTree::Punct(p) if p.as_char() == '.' && *in_test_depth == 0 => {
                if let Some(TokenTree::Ident(id)) = tokens.get(i + 1) {
                    let name = id.to_string();
                    if (name == "unwrap" || name == "expect")
                        && matches!(
                            tokens.get(i + 2),
                            Some(TokenTree::Group(g)) if g.delimiter() == Delimiter::Parenthesis
                        )
                    {
                        let line = id.span().start().line;
                        findings.push(format!(
                            "{}:{}: .{}() in non-test code (BC-2.14.003 violation)",
                            path, line, name
                        ));
                    }
                }
            }
            // Other non-brace groups (parens, brackets) — recurse at same depth
            TokenTree::Group(g) => {
                walk_panic_tokens(g.stream().into_iter(), findings, path, in_test_depth);
            }
            _ => {}
        }
        i += 1;
    }
}
