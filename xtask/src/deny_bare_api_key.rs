//! CI lint gate: reject credential struct definitions that violate
//! the pregolya key-safety invariants.
//!
//! Implements `cargo xtask deny-bare-api-key` (BC-2.14.005 {PC-006},
//! VP-DI010-02).
//!
//! # Scanning rules
//!
//! Scans `crates/**/*.rs` for STRUCTURAL violations on public structs whose
//! names contain a credential sentinel (`key`, `token`, `secret`,
//! `credential` — case-insensitive):
//!
//! 1. **`#[derive(Debug)]` without a manual `impl Debug`** — auto-derived
//!    `Debug` would emit the raw inner value and leak key material.
//! 2. **`#[derive(Serialize)]`** — serialization exposes credentials in
//!    JSON/TOML artifacts (BC-2.14.005 {PC-003}).
//! 3. **`impl Deref for NAME` with `type Target = str`** — Deref coercion
//!    silently exposes the inner value via auto-deref ({INV-003}).
//!
//! Compliant pattern: manual `impl fmt::Debug` emitting `"<redacted>"`,
//! no `Serialize` derive, access only via `expose_secret()`.
//!
//! - Files under `tests/` directories and `#[cfg(test)]` blocks are exempt.
//! - Exits non-zero when any violation is found; exits 0 on a clean scan.

use std::process::exit;

/// Entry point for `cargo xtask deny-bare-api-key`.
///
/// Scans `crates/**/*.rs` for structural credential safety violations
/// (BC-2.14.005 {PC-006}). Exits non-zero on any violation.
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
        eprintln!("ERROR: credential struct safety violations (BC-2.14.005 {{PC-006}}):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!(
        "deny-bare-api-key PASSED: {files_analyzed} analyzed, {files_exempt} exempt, 0 unreadable, 0 violations."
    );
}

/// Scans a single Rust source file for structural credential safety violations.
///
/// Detects three violation patterns on public structs with sentinel names
/// (`key`, `token`, `secret`, `credential` — case-insensitive):
///
/// 1. `#[derive(Debug)]` — auto-derived Debug leaks key material.
/// 2. `#[derive(Serialize)]` — exposes credentials in serialized artifacts.
/// 3. `impl Deref for NAME { type Target = str; }` — auto-deref exposes inner value.
///
/// Returns `Vec<String>` of violation messages. Returns empty when clean.
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
    walk_for_credential_violations(ts.into_iter(), path, &mut findings, &mut 0u32);
    findings
}

/// Lowercase substrings that identify credential/key/secret struct names.
const CREDENTIAL_SENTINELS: &[&str] = &["key", "token", "secret", "credential"];

/// Returns true if `name` (a struct identifier) contains any credential sentinel.
fn struct_name_has_sentinel(name: &str) -> bool {
    let lower = name.to_lowercase();
    CREDENTIAL_SENTINELS.iter().any(|s| lower.contains(s))
}

/// Harvest derive names from a consecutive run of `#[…]` attributes starting at `i`.
///
/// Returns `(derives, end_j)` where `end_j` is the index after the last consumed
/// `#[…]` token pair.
fn collect_derives(tokens: &[proc_macro2::TokenTree], start: usize) -> (Vec<String>, usize) {
    use proc_macro2::{Delimiter, TokenTree};
    let n = tokens.len();
    let mut derives = Vec::new();
    let mut j = start;

    while j + 1 < n {
        if let TokenTree::Punct(p2) = &tokens[j]
            && p2.as_char() == '#'
            && let Some(TokenTree::Group(ag)) = tokens.get(j + 1)
            && ag.delimiter() == Delimiter::Bracket
        {
            let attr_toks: Vec<TokenTree> = ag.stream().into_iter().collect();
            if let Some(TokenTree::Ident(first)) = attr_toks.first()
                && first == "derive"
                && let Some(TokenTree::Group(dg)) = attr_toks.get(1)
            {
                for tt in dg.stream().into_iter() {
                    if let TokenTree::Ident(id) = tt {
                        derives.push(id.to_string());
                    }
                }
            }
            j += 2;
        } else {
            break;
        }
    }
    (derives, j)
}

/// Check a `pub struct NAME` declaration that follows a derive attribute run.
///
/// Appends violation messages to `findings` when the struct name contains a
/// credential sentinel and has a dangerous derive (`Debug` or `Serialize`).
fn check_struct_derives(
    tokens: &[proc_macro2::TokenTree],
    derives: &[String],
    j: usize,
    path: &str,
    findings: &mut Vec<String>,
) {
    use proc_macro2::TokenTree;
    let is_pub = matches!(tokens.get(j), Some(TokenTree::Ident(id)) if id == "pub");
    let struct_kw_j = if is_pub { j + 1 } else { j };

    if matches!(tokens.get(struct_kw_j), Some(TokenTree::Ident(id)) if id == "struct")
        && let Some(TokenTree::Ident(struct_name_tok)) = tokens.get(struct_kw_j + 1)
    {
        let sname = struct_name_tok.to_string();
        let line = struct_name_tok.span().start().line;

        if is_pub && struct_name_has_sentinel(&sname) {
            if derives.iter().any(|d| d == "Debug") {
                findings.push(format!(
                    "{}:{}: BC-2.14.005 {{PC-006}}: pub struct '{}' derives Debug \
                     without manual impl — key material could leak via auto-derived \
                     Debug output",
                    path, line, sname
                ));
            }
            if derives.iter().any(|d| d == "Serialize") {
                findings.push(format!(
                    "{}:{}: BC-2.14.005 {{PC-006}}: pub struct '{}' derives Serialize \
                     — credentials must not appear in serialized artifacts \
                     (BC-2.14.005 {{PC-003}})",
                    path, line, sname
                ));
            }
        }
    }
}

/// Scan an `impl … Deref for NAME { … }` block for `type Target = str`.
///
/// Returns the index after the impl body brace group, or `start` unchanged if
/// this is not a recognised Deref impl.
fn check_impl_deref(
    tokens: &[proc_macro2::TokenTree],
    start: usize,
    path: &str,
    findings: &mut Vec<String>,
    in_test_depth: &mut u32,
) -> usize {
    use proc_macro2::{Delimiter, TokenTree};
    let n = tokens.len();
    let mut j = start;
    let mut deref_found = false;
    let mut for_found = false;
    let mut struct_name = String::new();
    let mut struct_line = 0usize;

    while j < n {
        match &tokens[j] {
            TokenTree::Ident(id) if id == "Deref" && !for_found => {
                deref_found = true;
                j += 1;
            }
            TokenTree::Ident(id) if id == "for" && deref_found => {
                for_found = true;
                j += 1;
                if let Some(TokenTree::Ident(sname)) = tokens.get(j) {
                    struct_name = sname.to_string();
                    struct_line = sname.span().start().line;
                    j += 1;
                }
            }
            TokenTree::Group(body) if body.delimiter() == Delimiter::Brace => {
                if deref_found
                    && for_found
                    && struct_name_has_sentinel(&struct_name)
                    && impl_body_has_target_str(body)
                {
                    findings.push(format!(
                        "{}:{}: BC-2.14.005 {{PC-006}}: impl Deref<Target=str> for '{}' \
                         — inner value exposed via auto-deref \
                         ({{INV-003}}: use expose_secret() instead)",
                        path, struct_line, struct_name
                    ));
                }
                walk_for_credential_violations(
                    body.stream().into_iter(),
                    path,
                    findings,
                    in_test_depth,
                );
                j += 1;
                return j;
            }
            TokenTree::Punct(p) if p.as_char() == ';' => {
                return j;
            }
            _ => {
                j += 1;
            }
        }
    }
    j
}

/// Recursive walker that detects credential struct safety violations.
fn walk_for_credential_violations(
    iter: proc_macro2::token_stream::IntoIter,
    path: &str,
    findings: &mut Vec<String>,
    in_test_depth: &mut u32,
) {
    use proc_macro2::{Delimiter, TokenTree};

    let tokens: Vec<TokenTree> = iter.collect();
    let n = tokens.len();
    let mut i = 0;

    while i < n {
        // ── #[cfg(test)] — skip the body ─────────────────────────────────────
        if let TokenTree::Punct(p) = &tokens[i]
            && p.as_char() == '#'
            && let Some(TokenTree::Group(g)) = tokens.get(i + 1)
            && g.delimiter() == Delimiter::Bracket
            && crate::is_cfg_test_group(g)
        {
            i = skip_cfg_test_body(&tokens, i + 2, path, findings, in_test_depth);
            continue;
        }

        if *in_test_depth > 0 {
            if let TokenTree::Group(g) = &tokens[i] {
                walk_for_credential_violations(
                    g.stream().into_iter(),
                    path,
                    findings,
                    in_test_depth,
                );
            }
            i += 1;
            continue;
        }

        // ── Pattern 1 & 2: #[derive(Debug|Serialize)] pub struct NAME ────────
        if let TokenTree::Punct(p) = &tokens[i]
            && p.as_char() == '#'
            && let Some(TokenTree::Group(attr_g)) = tokens.get(i + 1)
            && attr_g.delimiter() == Delimiter::Bracket
        {
            let (derives, j) = collect_derives(&tokens, i);
            check_struct_derives(&tokens, &derives, j, path, findings);
            i += 1;
            continue;
        }

        // ── Pattern 3: impl [path] Deref for NAME { type Target = str; } ─────
        if let TokenTree::Ident(kw) = &tokens[i]
            && kw == "impl"
        {
            i = check_impl_deref(&tokens, i + 1, path, findings, in_test_depth);
            continue;
        }

        // ── Recurse into any other groups ─────────────────────────────────────
        if let TokenTree::Group(g) = &tokens[i] {
            walk_for_credential_violations(g.stream().into_iter(), path, findings, in_test_depth);
        }

        i += 1;
    }
}

/// Skip past a `#[cfg(test)]` body, recursing at elevated test depth.
///
/// Returns the index to resume scanning from after the cfg(test) block.
fn skip_cfg_test_body(
    tokens: &[proc_macro2::TokenTree],
    start: usize,
    path: &str,
    findings: &mut Vec<String>,
    in_test_depth: &mut u32,
) -> usize {
    use proc_macro2::{Delimiter, TokenTree};
    let n = tokens.len();
    let mut j = start;

    // Skip any intervening #[…] attributes before the brace body.
    while j + 1 < n {
        if let TokenTree::Punct(p2) = &tokens[j]
            && p2.as_char() == '#'
            && let TokenTree::Group(_) = &tokens[j + 1]
        {
            j += 2;
            continue;
        }
        break;
    }

    while j < n {
        match &tokens[j] {
            TokenTree::Group(body) if body.delimiter() == Delimiter::Brace => {
                *in_test_depth += 1;
                walk_for_credential_violations(
                    body.stream().into_iter(),
                    path,
                    findings,
                    in_test_depth,
                );
                *in_test_depth -= 1;
                return j + 1;
            }
            TokenTree::Punct(p2) if p2.as_char() == ';' => {
                return j + 1;
            }
            _ => {}
        }
        j += 1;
    }
    j
}

/// Returns `true` if the impl body group contains `type Target = str ;`.
fn impl_body_has_target_str(body: &proc_macro2::Group) -> bool {
    use proc_macro2::TokenTree;
    let toks: Vec<TokenTree> = body.stream().into_iter().collect();
    let n = toks.len();
    for i in 0..n {
        if matches!(&toks[i], TokenTree::Ident(id) if id == "type")
            && matches!(toks.get(i + 1), Some(TokenTree::Ident(id)) if id == "Target")
            && matches!(toks.get(i + 2), Some(TokenTree::Punct(p)) if p.as_char() == '=')
            && matches!(toks.get(i + 3), Some(TokenTree::Ident(id)) if id == "str")
        {
            return true;
        }
    }
    false
}
