//! CI lint gate: reject `reqwest::Client::new()` and `ClientBuilder` without
//! `.timeout()` in library source files.
//!
//! Implements `cargo xtask check-client-timeout` (BC-2.14.004 {PC-003},
//! VP-DI009-01).
//!
//! # Scanning rules
//!
//! - Scans `crates/**/*.rs` for `reqwest::Client::new()` (fully qualified) and
//!   `Client::new()` (unqualified) in non-test source.
//! - Also scans for `ClientBuilder` chains that call `.build()` without a
//!   preceding `.timeout(d)` call where `d > Duration::ZERO`
//!   (BC-2.14.004 {PC-001}, {INV-004}).
//! - `.timeout(Duration::ZERO)` is treated as a missing timeout and flagged —
//!   a zero duration is not a valid request timeout.
//! - Files under `tests/` directories, `#[cfg(test)]` blocks, and files ending
//!   in `_test.rs`/`_tests.rs` are fully exempt (BC-2.14.004 {INV-003}).
//! - Exits non-zero when any violation is found; exits 0 on a clean scan.

use std::process::exit;

/// Entry point for `cargo xtask check-client-timeout`.
///
/// Scans `crates/**/*.rs` using token-tree analysis to detect `Client::new()`
/// and `ClientBuilder` chains missing `.timeout(...)`. Exits non-zero on any
/// violation (BC-2.14.004 {PC-003}).
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
        eprintln!("ERROR: check-client-timeout scanned 0 files — gate cannot certify anything");
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
        let findings = scan_for_timeout_violations_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if files_unreadable > 0 {
        eprintln!(
            "ERROR: check-client-timeout could not read {files_unreadable} file(s) — gate cannot certify anything"
        );
        exit(1);
    }
    if let Err(msg) = crate::check_post_exemption_vacuity("check-client-timeout", files_analyzed) {
        eprintln!("{msg}");
        exit(1);
    }
    if !all_findings.is_empty() {
        eprintln!(
            "ERROR: reqwest Client without .timeout() in non-test library code (BC-2.14.004):"
        );
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!(
        "check-client-timeout PASSED: {files_analyzed} analyzed, {files_exempt} exempt, 0 unreadable, 0 violations."
    );
}

/// Scans a single Rust source file (as a string) for `Client::new()` or
/// `ClientBuilder` chains that call `.build()` without a preceding `.timeout(d)`.
///
/// Returns a `Vec<String>` of human-readable violation messages. Returns an
/// empty `Vec` when the source is clean.
///
/// Called by `run()` per-file and exposed as `pub(crate)` so unit tests in
/// `xtask/src/tests.rs` can verify scanner behavior directly.
pub(crate) fn scan_for_timeout_violations_in_source(src: &str, path: &str) -> Vec<String> {
    if crate::is_test_file(path) {
        return Vec::new();
    }

    use proc_macro2::TokenStream;
    let ts: TokenStream = match src.parse() {
        Ok(s) => s,
        Err(e) => return vec![format!("{}:0: FAILED TO LEX FILE: {}", path, e)],
    };

    let mut findings = Vec::new();
    // Flatten all tokens into a list for pattern matching, suppressing cfg(test) blocks.
    let mut flat: Vec<FlatToken> = Vec::new();
    flatten_tokens_no_test(ts.into_iter(), &mut flat, &mut 0u32);
    scan_flat_for_timeout_violations(&flat, path, &mut findings);
    findings
}

/// A flattened token with its kind and source line.
#[derive(Debug, Clone)]
enum FlatToken {
    /// An identifier: the name and line number.
    Ident(String, usize),
    /// A punctuation character and line.
    Punct(char, usize),
    /// A paren group open marker — emitted before inlining the group's contents.
    /// Pairs with `ParenGroupEnd` so chain scanners can track nesting depth and skip
    /// `;` tokens inside paren-typed method arguments (e.g. the `vec!(addr; 2)` macro
    /// repeat expression inside `.resolve_to_addrs("host", &vec!(addr; 2))`)
    /// without terminating the chain scan before `.build()` is reached.
    ParenGroup(usize),
    /// A paren group close marker — emitted after inlining the group's contents.
    ParenGroupEnd(usize),
    /// A brace group open marker — emitted before inlining the group's contents.
    /// Pairs with `BraceGroupEnd` so chain scanners can track nesting depth and skip
    /// `;` tokens inside brace-typed method arguments without terminating the chain scan.
    BraceGroup(usize),
    /// A brace group close marker — emitted after inlining the group's contents.
    BraceGroupEnd(usize),
    /// A bracket group open marker — emitted before inlining the group's contents.
    /// Pairs with `BracketGroupEnd` so chain scanners can track nesting depth and
    /// skip `;` tokens inside bracket-typed method arguments (e.g. the `vec![v; n]`
    /// array-repeat expression inside `.resolve_to_addrs("host", &vec![addr; 2])`)
    /// without terminating the chain scan before `.build()` is reached.
    BracketGroup(usize),
    /// A bracket group close marker — emitted after inlining the group's contents.
    BracketGroupEnd(usize),
    /// A literal (integer, float, string, etc.) with its string representation and line.
    /// Preserved so zero-literal forms like `Duration::from_secs(0)` can be detected
    /// (BC-2.14.004 {PC-001}/{INV-004} — O-1 zero-timeout detection).
    Literal(String, usize),
}

impl FlatToken {
    fn line(&self) -> usize {
        match self {
            FlatToken::Ident(_, l)
            | FlatToken::Punct(_, l)
            | FlatToken::ParenGroup(l)
            | FlatToken::ParenGroupEnd(l)
            | FlatToken::BraceGroup(l)
            | FlatToken::BraceGroupEnd(l)
            | FlatToken::BracketGroup(l)
            | FlatToken::BracketGroupEnd(l)
            | FlatToken::Literal(_, l) => *l,
        }
    }
}

/// Flatten the token stream into `FlatToken` entries, suppressing `#[cfg(test)]` blocks.
fn flatten_tokens_no_test(
    iter: proc_macro2::token_stream::IntoIter,
    out: &mut Vec<FlatToken>,
    in_test_depth: &mut u32,
) {
    use proc_macro2::{Delimiter, TokenTree};

    let tokens: Vec<TokenTree> = iter.collect();
    let mut i = 0;
    while i < tokens.len() {
        match &tokens[i] {
            TokenTree::Punct(p) if p.as_char() == '#' => {
                if let Some(TokenTree::Group(g)) = tokens.get(i + 1)
                    && g.delimiter() == Delimiter::Bracket
                    && crate::is_cfg_test_group(g)
                {
                    // Scan forward to the brace body or semicolon
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
                                // Skip the test body — do not add to flat list
                                *in_test_depth += 1;
                                let mut inner = Vec::new();
                                flatten_tokens_no_test(
                                    body.stream().into_iter(),
                                    &mut inner,
                                    in_test_depth,
                                );
                                // inner is suppressed (not added to out)
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
                // Not cfg(test) — emit as punct
                let line = tokens[i].span().start().line;
                if let TokenTree::Punct(p) = &tokens[i] {
                    out.push(FlatToken::Punct(p.as_char(), line));
                }
            }
            TokenTree::Ident(id) => {
                if *in_test_depth == 0 {
                    out.push(FlatToken::Ident(id.to_string(), id.span().start().line));
                }
            }
            TokenTree::Punct(p) => {
                if *in_test_depth == 0 {
                    out.push(FlatToken::Punct(p.as_char(), p.span().start().line));
                }
            }
            TokenTree::Group(g) => {
                if *in_test_depth == 0 {
                    let line = g.span().start().line;
                    let is_brace = g.delimiter() == Delimiter::Brace;
                    let is_bracket = g.delimiter() == Delimiter::Bracket;
                    let is_paren = g.delimiter() == Delimiter::Parenthesis;
                    match g.delimiter() {
                        Delimiter::Parenthesis => out.push(FlatToken::ParenGroup(line)),
                        Delimiter::Brace => out.push(FlatToken::BraceGroup(line)),
                        Delimiter::Bracket => out.push(FlatToken::BracketGroup(line)),
                        _ => {}
                    }
                    // Recurse into all groups for nested calls
                    flatten_tokens_no_test(g.stream().into_iter(), out, in_test_depth);
                    // Emit close markers after paren, brace, and bracket groups so chain
                    // scanners can track nesting depth and skip ';' tokens inside method
                    // arguments (e.g. `.default_headers({ … })`,
                    // `.resolve_to_addrs("h", &vec![v; n])`, or `vec!(addr; 2)`).
                    if is_paren {
                        out.push(FlatToken::ParenGroupEnd(line));
                    }
                    if is_brace {
                        out.push(FlatToken::BraceGroupEnd(line));
                    }
                    if is_bracket {
                        out.push(FlatToken::BracketGroupEnd(line));
                    }
                }
            }
            TokenTree::Literal(lit) => {
                if *in_test_depth == 0 {
                    // Preserve the literal value so zero-form detectors can inspect it
                    // (e.g. Duration::from_secs(0) — BC-2.14.004 {PC-001} O-1 fix).
                    out.push(FlatToken::Literal(lit.to_string(), lit.span().start().line));
                }
            }
        }
        i += 1;
    }
}

/// Scans a `reqwest::blocking::` path starting at cursor position `i` (the `reqwest` token)
/// for Client/ClientBuilder timeout violations.
///
/// Returns `Some(new_i)` with the updated cursor position when a blocking pattern is matched
/// (regardless of whether a finding was emitted — the `.blocking.` module segment was
/// definitively consumed). Returns `None` when no blocking pattern matches (the caller should
/// continue with non-blocking or fallthrough pattern matching).
///
/// Token layout for the blocking path (offsets relative to `i`):
/// ```text
/// reqwest [i] :: [i+1,i+2] blocking [i+3] :: [i+4,i+5] <Type> [i+6]
///   :: [i+7,i+8] new|builder [i+9] () [i+10]
/// ```
fn scan_reqwest_blocking_pattern(
    flat: &[FlatToken],
    i: usize,
    path: &str,
    findings: &mut Vec<String>,
) -> Option<usize> {
    // Require: reqwest :: blocking ::
    if !matches_double_colon(flat, i + 1)
        || !matches_ident(flat, i + 3, "blocking")
        || !matches_double_colon(flat, i + 4)
    {
        return None;
    }

    // reqwest :: blocking :: Client :: new ( ) — always a violation.
    if matches_ident(flat, i + 6, "Client")
        && matches_double_colon(flat, i + 7)
        && matches_ident(flat, i + 9, "new")
        && matches!(flat.get(i + 10), Some(FlatToken::ParenGroup(_)))
    {
        let line = flat[i].line();
        findings.push(format!(
            "{}:{}: reqwest::blocking::Client::new() without .timeout() — use build_client() (BC-2.14.004)",
            path, line
        ));
        return Some(i + 11);
    }

    // reqwest :: blocking :: Client :: builder ... .build() without .timeout()
    if matches_ident(flat, i + 6, "Client")
        && matches_double_colon(flat, i + 7)
        && matches_ident(flat, i + 9, "builder")
    {
        let line = flat[i].line();
        let chain_end = find_chain_end(flat, i);
        if has_build_without_timeout(flat, i) {
            findings.push(format!(
                "{}:{}: reqwest::blocking::Client::builder() without .timeout() (BC-2.14.004)",
                path, line
            ));
        }
        return Some(chain_end);
    }

    // reqwest :: blocking :: ClientBuilder :: new ... .build() without .timeout()
    if matches_ident(flat, i + 6, "ClientBuilder")
        && matches_double_colon(flat, i + 7)
        && matches_ident(flat, i + 9, "new")
    {
        let line = flat[i].line();
        let chain_end = find_chain_end(flat, i);
        if has_build_without_timeout(flat, i) {
            findings.push(format!(
                "{}:{}: reqwest::blocking::ClientBuilder::new() without .timeout() (BC-2.14.004)",
                path, line
            ));
        }
        return Some(chain_end);
    }

    None
}

/// Scan the flat token list for timeout violations.
///
/// Patterns detected:
/// 1. `reqwest :: Client :: new ( )` — always a violation
/// 2. `Client :: new ( )` (not preceded by non-reqwest qualifier) — violation
///    - `reqwest :: Client :: new ( )` is covered above
///    - `mcp_sdk :: Client :: new ( )` is NOT a violation
///    - `OpenAiClient :: new ( )` is NOT a violation (name is "OpenAiClient" not "Client")
/// 3. `ClientBuilder :: new ... .build ()` without intervening `.timeout (` — violation
/// 4. `Client :: builder ... .build ()` without intervening `.timeout (` — violation
///
/// Non-reqwest `Client::new()` detection (B-4 / B-5 regressions):
/// - Flag bare `Client::new()` only if NOT preceded by a `::` that names a non-reqwest module.
/// - Specifically: if the token before `Client` is `::`  and the token before that is an Ident
///   that is NOT "reqwest", do NOT flag it.
///
/// # Known Limitations
///
/// **KNOWN-LIMITATION 1 — `use`-import false positives:** Patterns 2, 3, and 4 (bare
/// `Client::new()`, bare `ClientBuilder::new()`, bare `Client::builder()`) flag unqualified
/// calls conservatively. If a crate uses `use some_sdk::Client;` or
/// `use some_sdk::ClientBuilder;` and then calls `Client::new()`, `ClientBuilder::new()`,
/// or `Client::builder()`, the scanner cannot distinguish them from their reqwest equivalents.
/// Full fix requires tracking `use` imports at file scope (not implemented).
///
/// **KNOWN-LIMITATION 2 — split-statement builder chains:** A `ClientBuilder` stored in a
/// variable and then used in a subsequent statement is not detected as a timeout violation.
/// Example: `let b = reqwest::ClientBuilder::new(); let c = b.build()?;` would NOT be
/// flagged because `has_build_without_timeout` terminates the chain scan at `;`. Full fix
/// requires cross-statement binding-flow analysis (not implemented). The test
/// `test_timeout_scanner_split_statement_false_negative_known_limitation` documents this.
///
/// **KNOWN-LIMITATION 3 — constant-valued zero timeout:** `.timeout(Duration::from_secs(CONST))`
/// where `CONST` is a named constant evaluating to 0 at runtime is credited as a valid positive
/// timeout (the literal form would be caught as Form C zero-timeout, but a constant is not a
/// literal). Full mitigation requires const-evaluation. At present, `HTTP_CLIENT_TIMEOUT_SECS = 30`
/// is enforced via code review; `test_timeout_scanner_constant_zero_false_negative_known_limitation`
/// pins this accepted false-negative.
///
/// **KNOWN-LIMITATION 4 — parenthesized or braced base subexpression:** A parenthesized
/// **or braced** base subexpression causes a depth-0 `ParenGroupEnd` **or `BraceGroupEnd`**
/// to fire before the terminal `.build()`, so the violation is not reported.
/// Example forms: `(reqwest::ClientBuilder::new()).build()` (depth-0 `ParenGroupEnd`
/// terminator) and `{ reqwest::ClientBuilder::new() }.build()` (depth-0 `BraceGroupEnd`
/// terminator). Pinned by:
/// `test_timeout_scanner_parenthesized_base_subexpr_known_limitation` (paren form) and
/// `test_timeout_scanner_braced_base_subexpr_known_limitation` (brace form)
/// (BC-2.14.004 {PC-001}).
fn scan_flat_for_timeout_violations(flat: &[FlatToken], path: &str, findings: &mut Vec<String>) {
    let n = flat.len();
    let mut i = 0;
    while i < n {
        // Pattern 1: reqwest :: Client :: new ( )
        // Indices: [reqwest][::][Client][::][new][ParenGroup]
        if let FlatToken::Ident(name, _) = &flat[i]
            && name == "reqwest"
        {
            if matches_double_colon(flat, i + 1)
                && matches_ident(flat, i + 3, "Client")
                && matches_double_colon(flat, i + 4)
                && matches_ident(flat, i + 6, "new")
                && matches!(flat.get(i + 7), Some(FlatToken::ParenGroup(_)))
            {
                let line = flat[i].line();
                findings.push(format!(
                    "{}:{}: reqwest::Client::new() without .timeout() — use build_client() (BC-2.14.004)",
                    path, line
                ));
                i += 8;
                continue;
            }
            // Pattern: reqwest :: Client :: builder ... .build() without .timeout()
            if matches_double_colon(flat, i + 1)
                && matches_ident(flat, i + 3, "Client")
                && matches_double_colon(flat, i + 4)
                && matches_ident(flat, i + 6, "builder")
            {
                let line = flat[i].line();
                let chain_end = find_chain_end(flat, i);
                if has_build_without_timeout(flat, i) {
                    findings.push(format!(
                        "{}:{}: reqwest::Client::builder() without .timeout() (BC-2.14.004)",
                        path, line
                    ));
                }
                i = chain_end;
                continue;
            }
            // Pattern: reqwest :: ClientBuilder :: new ... .build() without .timeout()
            if matches_double_colon(flat, i + 1)
                && matches_ident(flat, i + 3, "ClientBuilder")
                && matches_double_colon(flat, i + 4)
                && matches_ident(flat, i + 6, "new")
            {
                let line = flat[i].line();
                let chain_end = find_chain_end(flat, i);
                if has_build_without_timeout(flat, i) {
                    findings.push(format!(
                        "{}:{}: reqwest::ClientBuilder::new() without .timeout() (BC-2.14.004)",
                        path, line
                    ));
                }
                i = chain_end;
                continue;
            }
            // reqwest::blocking::* patterns — extracted to keep this function within the
            // clippy::too_many_lines threshold.
            if let Some(new_i) = scan_reqwest_blocking_pattern(flat, i, path, findings) {
                i = new_i;
                continue;
            }
        }

        // Pattern 2: bare Client :: new ( ) — but NOT if preceded by a non-reqwest qualifier
        // The B-4 test: use reqwest::Client; ... Client::new() should be flagged
        // The B-5 test: OpenAiClient::new() should NOT be flagged (name differs)
        // The S-3 test: mcp_sdk::Client::new() should NOT be flagged (preceded by mcp_sdk::)
        //
        // Pattern 2 matches `Client::new()` with or without qualification; bare unqualified
        // calls are flagged conservatively (KNOWN-LIMITATION 1). If a module uses
        // `use reqwest::Client;` and then calls `Client::new()`, Pattern 2 cannot distinguish
        // it from a non-reqwest Client::new(). False positives are possible for crates that
        // `use` other Client types with the same name. Conservative behavior: flag and require
        // manual suppression. Full fix requires tracking use-imports at file scope.
        if let FlatToken::Ident(name, _) = &flat[i]
            && name == "Client"
            && matches_double_colon(flat, i + 1)
            && matches_ident(flat, i + 3, "new")
            && matches!(flat.get(i + 4), Some(FlatToken::ParenGroup(_)))
        {
            // Check if preceded by `:: something ::` (a module qualifier other than reqwest)
            // If i >= 2 and flat[i-1] is '::' double-colon, check flat[i-2]
            // crate/self/super/Self are path-relative qualifiers that do NOT identify a
            // non-reqwest crate — `crate::Client::new()` must still be flagged.
            let preceded_by_non_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && if let FlatToken::Ident(prev, _) = &flat[i - 3] {
                    prev != "reqwest"
                        && !matches!(prev.as_str(), "crate" | "self" | "super" | "Self")
                } else {
                    false
                };
            // De-duplication guard: prevents double-reporting of `reqwest::Client::new()`
            // already reported by Pattern 1's reqwest block. If Pattern 1's cursor advance
            // logic ever changes and this case reaches Pattern 2, this guard ensures we fall
            // through rather than emit a duplicate finding.
            let preceded_by_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && matches_ident(flat, i - 3, "reqwest");
            if !preceded_by_non_reqwest && !preceded_by_reqwest {
                let line = flat[i].line();
                findings.push(format!(
                    "{}:{}: Client::new() without .timeout() — use build_client() (BC-2.14.004)",
                    path, line
                ));
                i += 5;
                continue;
            }
        }

        // Pattern 3: ClientBuilder :: new ... .build() without .timeout()
        // (unqualified or qualified — qualified already handled above)
        // Only flag bare ClientBuilder::new() — not mcp_sdk::ClientBuilder::new() or other
        // non-reqwest qualifiers. If preceded by a non-reqwest module qualifier, skip.
        if let FlatToken::Ident(name, _) = &flat[i]
            && name == "ClientBuilder"
            && matches_double_colon(flat, i + 1)
            && matches_ident(flat, i + 3, "new")
        {
            // Check if preceded by `:: something ::` (a module qualifier other than reqwest)
            // If i >= 3 and flat[i-1..i-2] are '::' double-colon, check flat[i-3]
            // crate/self/super/Self are path-relative qualifiers that do NOT identify a
            // non-reqwest crate — `crate::ClientBuilder::new()` must still be flagged.
            let preceded_by_non_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && if let FlatToken::Ident(prev, _) = &flat[i - 3] {
                    prev != "reqwest"
                        && !matches!(prev.as_str(), "crate" | "self" | "super" | "Self")
                } else {
                    false
                };
            // De-duplication guard: prevents double-reporting of `reqwest::ClientBuilder::new()`
            // already reported by Pattern 1's reqwest block. If Pattern 1's cursor advance
            // logic ever changes and this case reaches Pattern 3, this guard ensures we fall
            // through rather than emit a duplicate finding.
            let preceded_by_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && matches_ident(flat, i - 3, "reqwest");
            if !preceded_by_non_reqwest && !preceded_by_reqwest {
                let line = flat[i].line();
                let chain_end = find_chain_end(flat, i);
                if has_build_without_timeout(flat, i) {
                    findings.push(format!(
                        "{}:{}: ClientBuilder::new() without .timeout() (BC-2.14.004)",
                        path, line
                    ));
                }
                i = chain_end;
                continue;
            }
        }

        // Pattern 4: Client :: builder ... .build() without .timeout() (unqualified)
        if let FlatToken::Ident(name, _) = &flat[i]
            && name == "Client"
            && matches_double_colon(flat, i + 1)
            && matches_ident(flat, i + 3, "builder")
        {
            // Only flag bare Client::builder() — not SomeOtherClient::builder()
            // Check it's not preceded by a non-reqwest qualifier.
            // crate/self/super/Self are path-relative qualifiers that do NOT identify a
            // non-reqwest crate — `crate::Client::builder()` must still be flagged.
            let preceded_by_non_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && if let FlatToken::Ident(prev, _) = &flat[i - 3] {
                    prev != "reqwest"
                        && !matches!(prev.as_str(), "crate" | "self" | "super" | "Self")
                } else {
                    false
                };
            // De-duplication guard: prevents double-reporting of `reqwest::Client::builder()`
            // already reported by Pattern 1's reqwest block. If Pattern 1's cursor advance
            // logic ever changes and this case reaches Pattern 4, this guard ensures we fall
            // through rather than emit a duplicate finding.
            let preceded_by_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && matches_ident(flat, i - 3, "reqwest");
            if !preceded_by_non_reqwest && !preceded_by_reqwest {
                let line = flat[i].line();
                let chain_end = find_chain_end(flat, i);
                if has_build_without_timeout(flat, i) {
                    findings.push(format!(
                        "{}:{}: Client::builder() without .timeout() (BC-2.14.004)",
                        path, line
                    ));
                }
                i = chain_end;
                continue;
            }
        }

        i += 1;
    }
}

/// Returns true if `flat[idx]` and `flat[idx+1]` are both `:` punctuation (double colon).
fn matches_double_colon(flat: &[FlatToken], idx: usize) -> bool {
    matches!(flat.get(idx), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(idx + 1), Some(FlatToken::Punct(':', _)))
}

/// Returns true if `flat[idx]` is an Ident with the given name.
fn matches_ident(flat: &[FlatToken], idx: usize, name: &str) -> bool {
    matches!(flat.get(idx), Some(FlatToken::Ident(n, _)) if n == name)
}

/// Returns the index just past the base call's [`FlatToken::ParenGroup`] if one is
/// immediately present after the ident path (e.g., `new()` or `builder()`), or just
/// past the ident path itself if no `ParenGroup` follows (function-reference form,
/// e.g., `new` without call parens).
///
/// This is a conservative hint used by callers to advance the outer scan cursor past
/// the base call without scanning ahead into unrelated tokens.  The return value
/// intentionally does not span the full chain — callers use [`has_build_without_timeout`]
/// to scan the full chain from `start`.
///
/// Scanning advances through consecutive [`FlatToken::Ident`] and
/// [`FlatToken::Punct`]`(':')` tokens to consume the ident path (e.g.
/// `reqwest :: ClientBuilder :: new`), then stops at the first token that is neither
/// an `Ident` nor a `':'`.  If that token is a [`FlatToken::ParenGroup`], it is the
/// base call's argument list and is consumed; if it is anything else (`;`, `.`,
/// a brace/bracket group, etc.), the function returns without advancing further.
///
/// This ensures that a function-reference base call (no call parens) does **not**
/// advance the cursor past the enclosing statement boundary or into a following
/// statement's [`FlatToken::ParenGroup`] (F-P20-HIGH-001 fix).
fn find_chain_end(flat: &[FlatToken], start: usize) -> usize {
    let n = flat.len();
    let mut i = start;
    // Advance past the base-call ident path: sequences of Ident and Punct(':').
    // Stops at the first token that is neither an Ident nor a ':'.
    while i < n {
        match &flat[i] {
            FlatToken::Ident(_, _) | FlatToken::Punct(':', _) => {
                i += 1;
            }
            _ => break,
        }
    }
    // If the very next token is a ParenGroup (the base call's argument list, e.g. `new()`),
    // advance past it.  If not present (function-reference form with no call parens), return
    // the current position without scanning ahead into unrelated tokens.
    if matches!(flat.get(i), Some(FlatToken::ParenGroup(_))) {
        i += 1;
    }
    i
}

/// Check if a chain from `start` calls `.build()` without a prior valid `.timeout()`.
///
/// Scans forward from `start` in the full `flat` list, stopping at the first top-level
/// `;` (a statement boundary at all depths zero).
///
/// **Terminates at the first `.build()` encountered at nesting depth zero.**
/// `.build()` calls at depth > 0 (inside method arguments) are attributed to inner
/// builders and ignored. This prevents cross-chain verdict leakage: a compliant second
/// chain in a `match` arm cannot credit an uncompliant first chain's `.build()`.
///
/// Both `.timeout()` crediting and `.build()` recognition are depth-gated: tokens
/// inside nested paren/brace/bracket groups (depth > 0) are attributed to inner
/// builders and not credited to the outer chain. A `.timeout()` call belonging to
/// a nested inner builder (e.g. inside a `.proxy(make_proxy(…))` argument) is
/// therefore NOT credited to the outer chain.
///
/// Brace-typed method arguments (e.g. `.default_headers({...})`),
/// bracket-typed method arguments (e.g. `.resolve_to_addrs("host", &vec![addr; 2])`), and
/// paren-typed method arguments (e.g. `.resolve_to_addrs("host", &vec!(addr; 2))`)
/// are transparent: `BraceGroup`/`BraceGroupEnd`, `BracketGroup`/`BracketGroupEnd`,
/// and `ParenGroup`/`ParenGroupEnd` depth counters suppress `;` tokens inside those
/// argument bodies from terminating the scan prematurely (a `vec![v; n]` or
/// `vec!(v; n)` array-repeat expression contains a `;` that must not be treated as
/// a statement boundary).
///
/// **`*GroupEnd` at depth-0 terminates the scan** (F-P20-HIGH-002 fix).  When a
/// `ParenGroupEnd`, `BraceGroupEnd`, or `BracketGroupEnd` token arrives while the
/// corresponding depth counter is already 0, the scan breaks immediately — the chain
/// has exited its enclosing group.  This prevents the scanner from escaping into an
/// outer context and claiming the outer chain's `.build()` as belonging to an inner
/// nested builder that has no `.build()` of its own.  A `*GroupEnd` at depth-0 means
/// the scan has exited a group that was opened before `start`, which is treated as
/// chain-end.  Unlike `;`, this can fire before a terminal `.build()` in
/// explicitly-grouped base subexpressions — see KNOWN-LIMITATION 4.
///
/// Returns `true` if `.build()` is present at depth zero and no valid `.timeout(d)` where
/// `d > Duration::ZERO` precedes it. `.timeout(Duration::ZERO)` is treated as
/// absent (BC-2.14.004 {PC-001}, {INV-004}).
fn has_build_without_timeout(flat: &[FlatToken], start: usize) -> bool {
    let n = flat.len();
    let mut found_timeout_before_build = false;
    // Track brace nesting so that ';' tokens inside brace-typed method arguments
    // (e.g. `.default_headers({ let mut h = Header::new(); h })`) do NOT terminate
    // the chain scan.  Each `BraceGroup` marker increments the depth; the matching
    // `BraceGroupEnd` marker decrements it.
    let mut brace_depth = 0u32;
    // Track bracket nesting so that ';' tokens inside bracket-typed method arguments
    // (e.g. `&vec![addr; 2]` — the array-repeat ';' inside the bracket group) do NOT
    // terminate the chain scan.
    let mut bracket_depth = 0u32;
    // Track paren nesting so that ';' tokens inside paren-typed method arguments
    // (e.g. `&vec!(addr; 2)` — the array-repeat ';' inside the paren group) do NOT
    // terminate the chain scan.  A ';' is a chain terminator only when ALL three
    // depths are zero (top-level statement boundary).
    let mut paren_depth = 0u32;
    let mut i = start;
    while i < n {
        match &flat[i] {
            FlatToken::BraceGroup(_) => brace_depth += 1,
            FlatToken::BraceGroupEnd(_) => {
                if brace_depth == 0 {
                    break; // exited the chain's own brace group — stop scanning
                }
                brace_depth -= 1;
            }
            FlatToken::BracketGroup(_) => bracket_depth += 1,
            FlatToken::BracketGroupEnd(_) => {
                if bracket_depth == 0 {
                    break; // exited the chain's own bracket group — stop scanning
                }
                bracket_depth -= 1;
            }
            FlatToken::ParenGroup(_) => paren_depth += 1,
            FlatToken::ParenGroupEnd(_) => {
                if paren_depth == 0 {
                    break; // exited the chain's own paren group — stop scanning
                }
                paren_depth -= 1;
            }
            FlatToken::Punct(c, _) if *c == ';' => {
                if brace_depth == 0 && bracket_depth == 0 && paren_depth == 0 {
                    break; // top-level statement boundary — terminate scan
                }
                // Inner ';' inside a brace, bracket, or paren argument — do not break.
            }
            FlatToken::Punct(c, _) if *c == '.' => {
                if let Some(FlatToken::Ident(name, _)) = flat.get(i + 1) {
                    if name == "timeout" {
                        if brace_depth == 0 && bracket_depth == 0 && paren_depth == 0 {
                            // Only credit a timeout at top-level depth (depth 0).
                            // A .timeout() inside a nested paren/brace/bracket argument
                            // (depth > 0) belongs to an inner builder and must NOT be
                            // credited to the outer chain (F-P19-HIGH-001 depth-asymmetry fix).
                            if !is_zero_duration_timeout_arg(flat, i) {
                                found_timeout_before_build = true;
                            }
                        }
                    } else if name == "build"
                        && matches!(flat.get(i + 2), Some(FlatToken::ParenGroup(_)))
                    {
                        // At nesting depth zero: this is the chain's terminal .build() call.
                        // Terminate immediately — a compliant chain later in the same
                        // statement (e.g. a match arm) must NOT credit this chain's build.
                        if brace_depth == 0 && bracket_depth == 0 && paren_depth == 0 {
                            return !found_timeout_before_build;
                        }
                        // At depth > 0: this .build() belongs to an inner builder
                        // (e.g. inside a closure or method argument) — ignore it.
                    }
                }
            }
            _ => {}
        }
        i += 1;
    }
    // No .build() was encountered at depth zero — not a violation.
    false
}

/// Returns `true` if the literal string `s` represents the value zero under Rust literal
/// normalisation:
///
/// 1. Strip underscore separators (`0_u64` → `"0u64"`, `0_0` → `"00"`).
/// 2. Strip a trailing integer or float type suffix (`u8`, `u16`, `u32`, `u64`, `u128`,
///    `usize`, `i8`, `i16`, `i32`, `i64`, `i128`, `isize`, `f32`, `f64`) from the end.
///    Longest-suffix-first to avoid stripping `u32` from `u128` prematurely.
/// 3. Parse by detected radix:
///    - `0x…` / `0X…` → hex integer; zero iff all post-prefix digits are `'0'`
///    - `0b…` / `0B…` → binary integer; zero iff all post-prefix digits are `'0'`
///    - `0o…` / `0O…` → octal integer; zero iff all post-prefix digits are `'0'`
///    - contains `'.'`, `'e'`, or `'E'` → parse as `f64`, check `== 0.0`
///    - otherwise → parse as decimal `u128`, check `== 0`
///
/// Handles: `0`, `00`, `0_0`, `0x0`, `0x00`, `0b0`, `0b00`, `0o0`, `0o00`,
/// `0.0`, `0.00`, `0.`, `0f64`, `0f32`, `0.0f64`, `0.0f32`, `0e0`, `0.0e0`,
/// and their underscore-separated variants.
fn is_zero_literal(s: &str) -> bool {
    // Handle negative-zero forms: "-0.0", "-0.", "-0", "-0e0", etc. (all mathematically zero).
    // These arise when proc_macro2 emits the literal part of a negative literal separately
    // (the `-` is a `Punct` token, not part of the literal string), but callers may also
    // pass the combined form directly.  Stripping a leading `-` and checking the remainder
    // is sufficient because negative zero equals positive zero in every numeric type.
    let s = s.strip_prefix('-').unwrap_or(s);

    // Step 1: strip underscore separators.
    let no_underscores = s.replace('_', "");

    // Step 2: strip trailing type suffix (longest first to avoid partial strips).
    const TYPE_SUFFIXES: &[&str] = &[
        "u128", "u64", "u32", "u16", "u8", "usize", "i128", "i64", "i32", "i16", "i8", "isize",
        "f64", "f32",
    ];
    let stripped: &str = {
        let mut result: &str = no_underscores.as_str();
        for suffix in TYPE_SUFFIXES {
            if let Some(base) = result.strip_suffix(suffix) {
                result = base;
                break;
            }
        }
        result
    };

    // Step 3: parse by radix.
    if let Some(hex_digits) = stripped
        .strip_prefix("0x")
        .or_else(|| stripped.strip_prefix("0X"))
    {
        // Hex zero: all digits after the prefix must be '0'.
        return !hex_digits.is_empty() && hex_digits.chars().all(|c| c == '0');
    }
    if let Some(bin_digits) = stripped
        .strip_prefix("0b")
        .or_else(|| stripped.strip_prefix("0B"))
    {
        // Binary zero: all digits after the prefix must be '0'.
        return !bin_digits.is_empty() && bin_digits.chars().all(|c| c == '0');
    }
    if let Some(oct_digits) = stripped
        .strip_prefix("0o")
        .or_else(|| stripped.strip_prefix("0O"))
    {
        // Octal zero: all digits after the prefix must be '0'.
        return !oct_digits.is_empty() && oct_digits.chars().all(|c| c == '0');
    }

    // Float or decimal integer.
    if stripped.contains('.') || stripped.contains('e') || stripped.contains('E') {
        // Float form (includes exponential notation such as `0e0`).
        stripped.parse::<f64>().map(|v| v == 0.0).unwrap_or(false)
    } else {
        // Decimal integer form.
        stripped.parse::<u128>().map(|v| v == 0).unwrap_or(false)
    }
}

/// Returns `true` if the `.timeout(...)` call at `timeout_idx` uses a zero duration
/// as its argument (BC-2.14.004 {PC-001}/{INV-004}).
///
/// `flatten_tokens_no_test` pushes a `ParenGroup` marker then inlines the paren
/// group's contents immediately after it. Detected forms:
///
/// **Form A — short constant `Duration::ZERO`** (offsets +3..+6):
/// ```text
/// +2  ParenGroup
/// +3  Ident("Duration")
/// +4  Punct(':')  +5  Punct(':')
/// +6  Ident("ZERO")
/// ```
///
/// **Form B — fully-qualified `std::time::Duration::ZERO` / `core::time::Duration::ZERO`**
/// (offsets +3..+12):
/// ```text
/// +2  ParenGroup
/// +3  Ident("std"|"core")
/// +4  Punct(':')  +5  Punct(':')
/// +6  Ident("time")
/// +7  Punct(':')  +8  Punct(':')
/// +9  Ident("Duration")
/// +10 Punct(':')  +11 Punct(':')
/// +12 Ident("ZERO")
/// ```
///
/// **Form C — zero-literal constructor `Duration::from_secs(0)` / `from_millis(0)` /
/// `from_nanos(0)` / `from_secs_f64(0.0)` / `from_micros(0)` / `from_secs_f32(0.0)`**
/// (offsets +3..+8):
/// ```text
/// +2  ParenGroup       (outer paren marker)
/// +3  Ident("Duration")
/// +4  Punct(':')  +5  Punct(':')
/// +6  Ident("from_secs"|"from_millis"|"from_nanos"|"from_secs_f64"|"from_micros"|"from_secs_f32")
/// +7  ParenGroup       (inner paren marker for constructor args)
/// +8  Literal(<any zero literal per is_zero_literal normalisation>)
/// ```
///
/// The `is_zero_literal` function applies a three-step normalisation: strip underscores,
/// strip type suffix, then parse by radix (hex `0x…`, binary `0b…`, octal `0o…`, float
/// with `'.'`/`'e'`/`'E'`, or decimal integer). This covers `00`, `0.00`, `0x00`, `0e0`,
/// `0.0e0`, `0_u64`, etc. without an enumerated allowlist.
///
/// **Form D — fully-qualified zero-literal constructor `std::time::Duration::from_secs(0)` /
/// `core::time::Duration::from_millis(0)` etc.** (offsets +3..+13):
/// ```text
/// +2  ParenGroup       (outer paren marker)
/// +3  Ident("std"|"core")
/// +4  Punct(':')  +5  Punct(':')
/// +6  Ident("time")
/// +7  Punct(':')  +8  Punct(':')
/// +9  Ident("Duration")
/// +10 Punct(':')  +11 Punct(':')
/// +12 Ident("from_secs"|"from_millis"|...)
/// +13 ParenGroup       (inner paren marker for constructor args)
/// +14 Literal("0"|...)
/// ```
///
/// Forms A–D are all detected by first optionally consuming the `std :: time ::` or
/// `core :: time ::` qualifier prefix (4 tokens), then applying the Duration::ZERO and
/// Duration::from_*(0) checks at the resulting offset.
fn is_zero_duration_timeout_arg(flat: &[FlatToken], timeout_idx: usize) -> bool {
    if !matches!(flat.get(timeout_idx + 2), Some(FlatToken::ParenGroup(_))) {
        return false;
    }

    // Detect and skip an optional `std :: time ::` or `core :: time ::` qualifier prefix.
    // If present, the prefix occupies 4 tokens: Ident("std"|"core"), ':', ':', Ident("time"),
    // followed by another ':', ':' before "Duration". We check for the qualifier pattern and
    // set `dur_offset` to where "Duration" appears.
    let base = timeout_idx + 3; // first token inside the outer paren group
    let dur_offset = if matches!(flat.get(base), Some(FlatToken::Ident(n, _)) if n == "std" || n == "core")
        && matches!(flat.get(base + 1), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(base + 2), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(base + 3), Some(FlatToken::Ident(n, _)) if n == "time")
        && matches!(flat.get(base + 4), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(base + 5), Some(FlatToken::Punct(':', _)))
    {
        // Qualifier found — Duration starts at base + 6
        base + 6
    } else {
        // No qualifier — Duration starts at base
        base
    };

    // Form A / Form B-ZERO: Duration :: ZERO
    if matches!(flat.get(dur_offset), Some(FlatToken::Ident(n, _)) if n == "Duration")
        && matches!(flat.get(dur_offset + 1), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 2), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 3), Some(FlatToken::Ident(n, _)) if n == "ZERO")
    {
        return true;
    }

    // Form C / Form D: Duration :: from_secs|from_millis|... ( zero_literal )
    if matches!(flat.get(dur_offset), Some(FlatToken::Ident(n, _)) if n == "Duration")
        && matches!(flat.get(dur_offset + 1), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 2), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 3), Some(FlatToken::Ident(n, _)) if matches!(
            n.as_str(),
            "from_secs" | "from_millis" | "from_nanos" | "from_secs_f64"
                | "from_micros" | "from_secs_f32"
        ))
        && matches!(flat.get(dur_offset + 4), Some(FlatToken::ParenGroup(_)))
    {
        // Check the first inlined argument is a zero literal.
        // Handle normal zero: `from_secs(0)` — literal at dur_offset+5.
        if let Some(FlatToken::Literal(s, _)) = flat.get(dur_offset + 5)
            && is_zero_literal(s)
        {
            return true;
        }
        // Handle negative zero: `from_secs(-0.0)` — the `-` is a separate Punct token
        // at dur_offset+5, and the literal is at dur_offset+6 (F-P8-L01 fix).
        if matches!(flat.get(dur_offset + 5), Some(FlatToken::Punct('-', _)))
            && let Some(FlatToken::Literal(s, _)) = flat.get(dur_offset + 6)
            && is_zero_literal(s)
        {
            return true;
        }
    }

    // Form E: Duration :: new ( zero_secs , zero_nanos )
    // `Duration::new(0, 0)` is zero; `Duration::new(30, 0)` is NOT zero.
    // Both secs and nanos must be zero literals (F-P8-M01 fix).
    if matches!(flat.get(dur_offset), Some(FlatToken::Ident(n, _)) if n == "Duration")
        && matches!(flat.get(dur_offset + 1), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 2), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 3), Some(FlatToken::Ident(n, _)) if n == "new")
        && matches!(flat.get(dur_offset + 4), Some(FlatToken::ParenGroup(_)))
    {
        // Flat layout after ParenGroup: Literal(secs), Punct(','), Literal(nanos)
        if let Some(FlatToken::Literal(secs_s, _)) = flat.get(dur_offset + 5)
            && matches!(flat.get(dur_offset + 6), Some(FlatToken::Punct(',', _)))
            && let Some(FlatToken::Literal(nanos_s, _)) = flat.get(dur_offset + 7)
            && is_zero_literal(secs_s)
            && is_zero_literal(nanos_s)
        {
            return true;
        }
    }

    // Form F: Duration :: default ()
    // `Duration::default()` is always Duration::ZERO (F-P8-M01 fix).
    if matches!(flat.get(dur_offset), Some(FlatToken::Ident(n, _)) if n == "Duration")
        && matches!(flat.get(dur_offset + 1), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 2), Some(FlatToken::Punct(':', _)))
        && matches!(flat.get(dur_offset + 3), Some(FlatToken::Ident(n, _)) if n == "default")
        && matches!(flat.get(dur_offset + 4), Some(FlatToken::ParenGroup(_)))
    {
        return true;
    }

    false
}

#[cfg(test)]
mod tests {
    use super::scan_for_timeout_violations_in_source;

    /// BC-2.14.004 {PC-001}/{INV-004} — Form D: fully-qualified from_secs(0) must be flagged.
    ///
    /// `std::time::Duration::from_secs(0)` is semantically identical to Duration::ZERO;
    /// the fully-qualified path + constructor form must be detected (F-P5-M02).
    #[test]
    fn test_bc_2_14_004_flags_timeout_fully_qualified_from_secs_zero() {
        let src = r#"let c = reqwest::ClientBuilder::new()
            .timeout(std::time::Duration::from_secs(0))
            .build()?;"#;
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P5-M02 Form D: \
             .timeout(std::time::Duration::from_secs(0)) must be flagged as zero-timeout; \
             got: {findings:?}"
        );
    }

    /// BC-2.14.004 {PC-001}/{INV-004} — Form D: core::time::Duration::from_millis(0) must be flagged.
    ///
    /// `core::time::Duration::from_millis(0)` is also a zero duration via fully-qualified path.
    #[test]
    fn test_bc_2_14_004_flags_timeout_core_qualified_from_millis_zero() {
        let src = r#"let c = reqwest::ClientBuilder::new()
            .timeout(core::time::Duration::from_millis(0))
            .build()?;"#;
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P5-M02 Form D: \
             .timeout(core::time::Duration::from_millis(0)) must be flagged as zero-timeout; \
             got: {findings:?}"
        );
    }

    /// BC-2.14.004 {PC-001}/{INV-004} — hex literal zero: Duration::from_secs(0x0) must be flagged.
    ///
    /// `0x0` is the integer zero in hexadecimal form; it is equivalent to the literal `0`
    /// and must be treated as a zero-timeout argument.
    #[test]
    fn test_bc_2_14_004_flags_timeout_duration_zero_hex_literal() {
        let src =
            r#"let c = reqwest::ClientBuilder::new().timeout(Duration::from_secs(0x0)).build()?;"#;
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P5-M02: .timeout(Duration::from_secs(0x0)) must be \
             flagged as zero-timeout (hex zero is zero); got: {findings:?}"
        );
    }

    /// F-P6-L03 (LOW) — BC-2.14.004 {PC-001}/{INV-004}
    ///
    /// `from_secs_f64(0f64)` must be flagged: `0f64` is the float zero literal with explicit
    /// type suffix (no decimal point). `is_zero_literal` must recognise this suffix form.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_zero_float() {
        let src = r#"
pub fn build_client() -> reqwest::Client {
    reqwest::ClientBuilder::new()
        .timeout(std::time::Duration::from_secs_f64(0f64))
        .build()
        .unwrap()
}
"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f64(0f64) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P6-L03 (LOW) — BC-2.14.004 {PC-001}/{INV-004}
    ///
    /// `from_secs_f32(0.)` must be flagged: `0.` is the bare trailing-dot float literal
    /// (shorthand for `0.0`). `is_zero_literal` must recognise this form.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f32_zero_dot() {
        let src = r#"
pub fn build_client() -> reqwest::Client {
    reqwest::ClientBuilder::new()
        .timeout(Duration::from_secs_f32(0.))
        .build()
        .unwrap()
}
"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f32(0.) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `00` decimal double-zero must be flagged.
    ///
    /// `00` is a valid Rust decimal literal evaluating to 0; the numeric normalisation in
    /// `is_zero_literal` (parse as u128 decimal) must recognise it as zero.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_double_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs(00)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs(00) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `0.00` float zero must be flagged.
    ///
    /// `0.00` is a float literal evaluating to 0.0; the numeric normalisation in
    /// `is_zero_literal` (parse as f64) must recognise it as zero.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_zero_point_zero_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs_f64(0.00)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f64(0.00) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `0x00` hex zero must be flagged.
    ///
    /// `0x00` is a hex integer literal evaluating to 0; the numeric normalisation in
    /// `is_zero_literal` (all hex post-prefix digits are `0`) must recognise it.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_hex_double_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs(0x00)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs(0x00) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `0e0` exponential float zero must be flagged.
    ///
    /// `0e0` is a float literal in exponential notation evaluating to 0.0; the numeric
    /// normalisation in `is_zero_literal` (contains 'e' → parse as f64) must recognise it.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_exp_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs_f64(0e0)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f64(0e0) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    // ── F-P8-M01: Duration::new and Duration::default ────────────────────────

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `Duration::new(0, 0)` must be flagged.
    ///
    /// `Duration::new(0, 0)` is semantically identical to `Duration::ZERO`; both secs
    /// and nanos being zero literals must be detected as a zero-duration timeout.
    #[test]
    fn test_bc_2_14_004_flags_timeout_duration_new_zero_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::new(0, 0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-M01: .timeout(Duration::new(0, 0)) must be flagged \
             as zero-timeout; got: {findings:?}"
        );
    }

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `std::time::Duration::new(0, 0)` must be flagged.
    ///
    /// Fully-qualified `std::time::Duration::new(0, 0)` is semantically identical to
    /// `Duration::new(0, 0)` — the fully-qualified path form must also be detected.
    #[test]
    fn test_bc_2_14_004_flags_timeout_std_duration_new_zero_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(std::time::Duration::new(0, 0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-M01: .timeout(std::time::Duration::new(0, 0)) must be \
             flagged as zero-timeout; got: {findings:?}"
        );
    }

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `Duration::default()` must be flagged.
    ///
    /// `Duration::default()` always evaluates to `Duration::ZERO`; an explicit
    /// `Duration::default()` call as a timeout argument must be detected as zero.
    #[test]
    fn test_bc_2_14_004_flags_timeout_duration_default() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::default()).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-M01: .timeout(Duration::default()) must be flagged \
             as zero-timeout; got: {findings:?}"
        );
    }

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `Duration::new(30, 0)` must NOT be flagged.
    ///
    /// `Duration::new(30, 0)` is a valid 30-second timeout and must not be falsely flagged.
    /// The detection must require BOTH secs and nanos to be zero literals.
    #[test]
    fn test_bc_2_14_004_does_not_flag_duration_new_30_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::new(30, 0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            findings.is_empty(),
            "BC-2.14.004 F-P8-M01: .timeout(Duration::new(30, 0)) must NOT be flagged \
             (30-second timeout is valid); got: {findings:?}"
        );
    }

    // ── F-P8-L01: negative zero float ────────────────────────────────────────

    /// F-P8-L01 — BC-2.14.004 {PC-001}/{INV-004}: `from_secs_f64(-0.0)` must be flagged.
    ///
    /// `-0.0` lexes as `Punct('-')` + `Literal("0.0")`. The scanner must handle the
    /// case where the literal position is offset by one due to the preceding `-` sign.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_negative_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::from_secs_f64(-0.0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-L01: .timeout(Duration::from_secs_f64(-0.0)) must be \
             flagged as zero-timeout (negative zero is zero); got: {findings:?}"
        );
    }

    /// F-P8-L01 — BC-2.14.004 {PC-001}/{INV-004}: `from_secs_f32(-0.)` must be flagged.
    ///
    /// `-0.` is the bare trailing-dot float negative zero literal; the scanner must
    /// recognise it as zero through the negative zero handling path.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f32_negative_zero_dot() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::from_secs_f32(-0.)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-L01: .timeout(Duration::from_secs_f32(-0.)) must be \
             flagged as zero-timeout (negative zero is zero); got: {findings:?}"
        );
    }

    /// F-P16-MED-002 — BC-2.14.004 {PC-001}: brace-group argument in a builder chain must
    /// not terminate the scan before `.build()` is reached.
    ///
    /// When a builder method takes a brace-group argument (e.g. `.default_headers({…})`),
    /// the previous `BraceGroup => break` would stop scanning before `.build()`, causing a
    /// false-negative: the missing `.timeout()` was not reported.  The fix changes the arm
    /// to `{}` (continue) so the `;` boundary arm still terminates cross-statement
    /// contamination while brace-group method arguments no longer interrupt the scan.
    #[test]
    fn test_timeout_scanner_brace_group_in_builder_chain_does_not_break_scan() {
        // BC-2.14.004 {PC-001}: brace-group arguments in a builder chain must not
        // terminate the scan before .build() is reached.
        let src = r#"
        fn build_client() -> reqwest::Client {
            reqwest::ClientBuilder::new()
                .default_headers({
                    let mut h = ::reqwest::header::HeaderMap::new();
                    h
                })
                .build()
                .unwrap()
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "builder chain with brace-group arg and no .timeout() must be flagged"
        );
    }

    #[test]
    fn test_timeout_scanner_bracket_group_in_builder_chain_does_not_break_scan() {
        // BC-2.14.004 PC-001: vec!-repeat expressions containing `;` inside a builder
        // chain must not terminate the scan before `.build()` is reached.
        let src = r#"
        use std::net::SocketAddr;
        fn build_client(addr: SocketAddr) -> reqwest::Client {
            reqwest::ClientBuilder::new()
                .resolve_to_addrs("host", &vec![addr; 2])
                .build()
                .unwrap()
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "builder chain with vec![..;n] arg and no .timeout() must be flagged"
        );
    }

    #[test]
    fn test_timeout_scanner_paren_group_in_builder_chain_does_not_break_scan() {
        // BC-2.14.004 PC-001: paren-delimited vec! repeat must not terminate the scan.
        let src = r#"
        use std::net::SocketAddr;
        fn build_client(addr: SocketAddr) -> reqwest::Client {
            reqwest::ClientBuilder::new()
                .resolve_to_addrs("host", &vec!(addr; 2))
                .build()
                .unwrap()
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "builder chain with vec!(..;n) arg and no .timeout() must be flagged"
        );
    }

    #[test]
    fn test_timeout_scanner_match_arms_violation_first_is_flagged() {
        // BC-2.14.004 PC-001: a violating chain in a match arm must be flagged even
        // when a later arm has a compliant chain (cross-chain verdict leakage).
        let src = r#"
        fn build_client(fast: bool) -> reqwest::Client {
            match fast {
                true  => reqwest::ClientBuilder::new().build().unwrap(),
                false => reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .build()
                    .unwrap(),
            }
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "violating chain in first match arm must be flagged even when second arm is compliant"
        );
    }

    #[test]
    fn test_timeout_scanner_match_arms_compliant_first_is_not_flagged() {
        // The reverse ordering: compliant chain first, violating chain second.
        // The scan should still flag the violating arm.
        let src = r#"
        fn build_client(fast: bool) -> reqwest::Client {
            match fast {
                true  => reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .build()
                    .unwrap(),
                false => reqwest::ClientBuilder::new().build().unwrap(),
            }
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "violating chain in second match arm must be flagged even when first arm is compliant"
        );
    }

    // ── Depth-asymmetry false-negative regression tests ──────────────────────
    //
    // Fix-burst-20 made `.build()` recognition depth-aware (only the depth-0
    // `.build()` terminates the outer chain scan) but left `.timeout()` crediting
    // depth-blind.  If a *nested inner* builder (inside a paren/brace/bracket
    // argument) calls `.timeout()`, that credit is wrongly attributed to the
    // *outer* chain, causing the outer chain's missing `.timeout()` to go
    // unreported.  Tests 1 and 2 pin this false-negative; Test 3 pins the
    // complementary true-negative (outer with depth-0 `.timeout()` must not be
    // falsely flagged after the depth-aware fix).

    /// Depth-asymmetry false-negative — paren-nested inner builder.
    ///
    /// Outer chain has no `.timeout()`.  Inner chain (inside `.proxy(make_proxy(…))`)
    /// has `.timeout()`.  Under the bug, `has_build_without_timeout` credits the
    /// inner timeout to the outer chain and returns `false` (no violation).
    /// After the fix the credit is rejected (inner timeout is at paren depth > 0)
    /// and the outer chain is correctly flagged.
    ///
    /// FAILS before fix, PASSES after fix.
    #[test]
    fn test_timeout_scanner_nested_inner_builder_in_paren_outer_missing_timeout_is_flagged() {
        let src = r#"
            fn build_client() -> reqwest::Client {
                reqwest::ClientBuilder::new()
                    .proxy(make_proxy(
                        reqwest::ClientBuilder::new()
                            .timeout(std::time::Duration::from_secs(30))
                            .build()
                            .unwrap()
                    ))
                    .build()
                    .unwrap()
            }
        "#;
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
        assert!(
            !findings.is_empty(),
            "outer chain with no .timeout() should be flagged even when a nested inner builder \
             has .timeout(); inner timeout must not credit the outer chain"
        );
    }

    /// Depth-asymmetry false-negative — brace-nested inner builder.
    ///
    /// Outer chain has no `.timeout()`.  Inner chain inside a brace-group argument
    /// (`.default_headers({{ … }})`) has `.timeout()`.  Under the bug the inner
    /// timeout (at brace depth > 0) is wrongly credited to the outer chain.
    /// After the fix the credit is rejected and the outer chain is correctly flagged.
    ///
    /// FAILS before fix, PASSES after fix.
    #[test]
    fn test_timeout_scanner_nested_inner_builder_in_brace_outer_missing_timeout_is_flagged() {
        let src = r#"
            fn build_client() -> reqwest::Client {
                reqwest::ClientBuilder::new()
                    .default_headers({
                        let _ = reqwest::ClientBuilder::new()
                            .timeout(std::time::Duration::from_secs(30))
                            .build()
                            .unwrap();
                        Default::default()
                    })
                    .build()
                    .unwrap()
            }
        "#;
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
        assert!(
            !findings.is_empty(),
            "outer chain with no .timeout() should be flagged even when a brace-nested inner \
             builder has .timeout(); inner timeout must not credit the outer chain"
        );
    }

    /// Depth-asymmetry stability test — outer depth-0 `.timeout()` is still credited
    /// after the depth-aware fix.
    ///
    /// Outer chain has `.timeout()` at depth 0 (before any paren/brace nesting).
    /// Inner chain inside `.proxy(make_proxy(…))` has NO `.timeout()`.
    /// `has_build_without_timeout` is called directly here so that the inner
    /// chain's independent non-compliance does not pollute the outer-chain verdict.
    ///
    /// Expected: `has_build_without_timeout` returns `false` (outer is compliant).
    /// The depth-aware fix must not accidentally un-credit depth-0 `.timeout()` calls.
    ///
    /// PASSES both before and after fix (no regression introduced by the fix).
    #[test]
    fn test_timeout_scanner_outer_has_depth_zero_timeout_inner_missing_is_not_flagged() {
        // Source contains only the builder expression (no fn wrapper) so that
        // flat[0] is the outer `reqwest` token and start = 0 is correct.
        let src = r#"
            reqwest::ClientBuilder::new()
                .timeout(std::time::Duration::from_secs(30))
                .proxy(make_proxy(
                    reqwest::ClientBuilder::new()
                        .build()
                        .unwrap()
                ))
                .build()
                .unwrap()
        "#;
        let ts: proc_macro2::TokenStream = src.parse().unwrap();
        let mut flat = Vec::new();
        super::flatten_tokens_no_test(ts.into_iter(), &mut flat, &mut 0u32);
        assert!(
            !super::has_build_without_timeout(&flat, 0),
            "outer chain with depth-0 .timeout() should NOT be flagged regardless of inner \
             builder state; depth-aware fix must not un-credit a valid depth-0 timeout"
        );
    }

    // ── F-P20-HIGH-001: find_chain_end over-advance on function-reference base call ──
    //
    // When a base call appears as a function reference (no call parens), find_chain_end
    // scans past the function-reference token and consumes the first ParenGroup it finds
    // anywhere in the flat stream — which may belong to a completely different statement's
    // base call.  The outer scanner then sets i = chain_end, skipping that second statement
    // entirely.  The following test pins this false-negative.

    /// F-P20-HIGH-001 regression — function-reference base call must not consume a
    /// following statement's ParenGroup.
    ///
    /// `reqwest::ClientBuilder::new` without call parens is a function reference.
    /// `find_chain_end` must NOT advance past the semicolon boundary and consume the
    /// `ParenGroup` of the immediately-following `reqwest::Client::builder()` call.
    /// The `Client::builder()` chain that follows has no `.timeout()` and must be flagged.
    ///
    /// FAILS before fix (false-negative: second chain is silently skipped).
    /// PASSES after fix (second chain is correctly flagged).
    #[test]
    fn test_timeout_scanner_function_reference_does_not_skip_following_violation() {
        // reqwest::ClientBuilder::new without call-parens is a function reference.
        // find_chain_end must NOT consume the following statement's ParenGroup.
        // The Client::builder() chain that follows has no .timeout() → must be flagged.
        let src = r#"
            fn a() {
                let _ctor = reqwest::ClientBuilder::new;
                reqwest::Client::builder()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "a.rs");
        assert!(
            !findings.is_empty(),
            "Client::builder() with no .timeout() must be flagged even when a preceding \
             function-reference base call appears; got: {:?}",
            findings
        );
    }

    // ── F-P20-HIGH-002: saturating_sub on GroupEnd at depth-0 escapes chain boundary ──
    //
    // When has_build_without_timeout is called on a nested inner builder that has no
    // .build() of its own, the saturating_sub on ParenGroupEnd tokens that arrive while
    // paren_depth is already 0 keeps the depth at 0 instead of signalling "we have left
    // the inner builder's enclosing paren group".  The scan therefore escapes the inner
    // chain's enclosing group and claims the OUTER chain's .build() as the inner chain's
    // .build(), producing a false-positive violation on the inner builder.

    /// F-P20-HIGH-002 regression — inner builder with no .build() must not produce a
    /// false-positive by claiming the outer chain's .build().
    ///
    /// Outer chain is fully compliant: `.timeout(30s)` + `.build()`.
    /// Inner chain inside `.proxy(make_proxy(…))` argument: `reqwest::ClientBuilder::new()`
    /// with NO `.timeout()` and NO `.build()` of its own.
    /// BC-2.14.004 {PC-001} only requires `.timeout()` BEFORE `.build()`; an inner builder
    /// with no `.build()` has no timeout obligation.
    /// Expected: ZERO findings (no false positive on the inner builder).
    ///
    /// FAILS before fix (false-positive: inner builder incorrectly flagged).
    /// PASSES after fix (inner builder correctly not flagged).
    #[test]
    fn test_timeout_scanner_nested_inner_builder_no_build_does_not_false_positive() {
        // Outer chain: compliant (.timeout(30s) + .build()).
        // Inner chain inside proxy() arg: reqwest::ClientBuilder::new() with NO .timeout()
        // and NO .build().
        // The inner chain has no .build() obligation (BC-2.14.004 {PC-001} requires
        // .timeout() BEFORE .build()).
        // Expected: zero violations (the inner chain must NOT claim the outer .build()).
        let src = r#"
            fn f() {
                reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .proxy(make_proxy(reqwest::ClientBuilder::new()))
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            findings.is_empty(),
            "compliant outer chain with non-completing nested inner builder must not produce \
             a false-positive violation; got: {:?}",
            findings
        );
    }

    /// F-P20-HIGH-002 non-regression — outer chain with no .timeout() is still detected
    /// even when a nested inner builder inside a proxy argument has .timeout().
    ///
    /// Outer chain: NON-compliant (no `.timeout()`, has `.build()`).
    /// Inner chain inside `.proxy(make_proxy(…))`: has `.timeout()` but no `.build()`.
    /// The outer chain must be flagged regardless of the inner builder's timeout.
    /// This guards against a fix for F-P20-HIGH-002 accidentally suppressing outer-chain
    /// violation detection.
    ///
    /// PASSES both before and after fix (outer violation is detected via the existing
    /// depth-aware .timeout() crediting from fix-burst-19 / F-P19-HIGH-001).
    #[test]
    fn test_timeout_scanner_outer_missing_timeout_with_nested_inner_is_flagged() {
        // Outer chain: NON-compliant (no .timeout(), has .build()).
        // Inner chain inside proxy() arg: has .timeout() at inner depth, no .build().
        // The outer chain must be flagged.
        let src = r#"
            fn g() {
                reqwest::ClientBuilder::new()
                    .proxy(make_proxy(reqwest::ClientBuilder::new()
                        .timeout(std::time::Duration::from_secs(30))))
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "g.rs");
        assert!(
            !findings.is_empty(),
            "outer chain with no .timeout() must be flagged even with a nested inner builder \
             that has .timeout(); got: {:?}",
            findings
        );
    }

    /// F-P21-MED-001 — non-reqwest ClientBuilder::new() must NOT be flagged.
    ///
    /// `mcp_sdk::ClientBuilder::new()` is not a reqwest builder; Pattern 3 must
    /// apply the same non-reqwest qualifier guard as Patterns 2 and 4 to suppress it.
    #[test]
    fn test_timeout_scanner_does_not_flag_non_reqwest_client_builder_new() {
        // mcp_sdk::ClientBuilder::new() is not a reqwest builder — must not be flagged.
        let src = r#"
            fn f() {
                mcp_sdk::ClientBuilder::new()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            findings.is_empty(),
            "non-reqwest ClientBuilder::new() must not be flagged; got: {:?}",
            findings
        );
    }

    /// F-P21-MED-002 — KNOWN-LIMITATION 4: parenthesized base subexpression is a known
    /// false negative.
    ///
    /// A parenthesized base subexpression — `(reqwest::ClientBuilder::new()).build()` —
    /// causes a depth-0 `ParenGroupEnd` to fire before the terminal `.build()`, so the
    /// violation is not reported.  This test pins the accepted false-negative behavior.
    #[test]
    fn test_timeout_scanner_parenthesized_base_subexpr_known_limitation() {
        // KNOWN-LIMITATION 4: parenthesized base subexpression causes depth-0 ParenGroupEnd
        // to fire before terminal .build(), so the violation is not reported.
        let src = r#"
            fn f() {
                let c = (reqwest::ClientBuilder::new()).build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            findings.is_empty(),
            "KNOWN-LIMITATION 4: parenthesized base subexpression is a known false negative; \
             if this test fails, the limitation has been fixed and this test should be updated"
        );
    }

    /// F-P22-MED-004 — `crate::Client::new()` must be flagged (Pattern 2).
    ///
    /// `crate` is a path-relative qualifier, not a third-party crate name. The
    /// `preceded_by_non_reqwest` guard must NOT suppress detection when the qualifier
    /// is `crate`, `self`, `super`, or `Self`.
    #[test]
    fn test_timeout_scanner_crate_qualified_client_new_is_flagged() {
        let src = r#"
            fn f() {
                crate::Client::new()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "crate::Client::new() must be flagged; got: {:?}",
            findings
        );
    }

    /// F-P22-MED-004 — `crate::ClientBuilder::new()` must be flagged (Pattern 3).
    ///
    /// `crate` is a path-relative qualifier, not a third-party crate name. The
    /// `preceded_by_non_reqwest` guard must NOT suppress detection for Pattern 3.
    #[test]
    fn test_timeout_scanner_crate_qualified_client_builder_new_is_flagged() {
        let src = r#"
            fn f() {
                crate::ClientBuilder::new()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "crate::ClientBuilder::new() must be flagged; got: {:?}",
            findings
        );
    }

    /// F-P22-MED-004 — `crate::Client::builder()` must be flagged (Pattern 4).
    ///
    /// `crate` is a path-relative qualifier, not a third-party crate name. The
    /// `preceded_by_non_reqwest` guard must NOT suppress detection for Pattern 4.
    #[test]
    fn test_timeout_scanner_crate_qualified_client_builder_is_flagged() {
        let src = r#"
            fn f() {
                crate::Client::builder()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "crate::Client::builder() must be flagged; got: {:?}",
            findings
        );
    }

    /// F-P22-LOW-006 — KNOWN-LIMITATION 4 braced form: braced base subexpression is a known
    /// false negative.
    ///
    /// `{ reqwest::ClientBuilder::new() }.build()` causes a depth-0 `BraceGroupEnd` to fire
    /// before the terminal `.build()`, so the violation is not reported. This test pins the
    /// accepted false-negative behavior for the braced form alongside the parenthesized form.
    #[test]
    fn test_timeout_scanner_braced_base_subexpr_known_limitation() {
        // KNOWN-LIMITATION 4: braced base subexpression — { reqwest::ClientBuilder::new() }.build()
        // The depth-0 BraceGroupEnd fires before the terminal .build(), so the violation is not reported.
        let src = r#"
            fn f() {
                let c = { reqwest::ClientBuilder::new() }.build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            findings.is_empty(),
            "KNOWN-LIMITATION 4: braced base subexpression is a known false negative; \
             if this test fails, the limitation has been fixed and this test should be updated"
        );
    }

    // ── F-P23-HIGH-001: reqwest::blocking surface detection ──────────────────

    /// F-P23-HIGH-001 — `reqwest::blocking::Client::new()` must be flagged.
    ///
    /// Pattern 1 is extended to handle the optional `blocking ::` module segment between
    /// `reqwest ::` and the type ident. Without this fix, the blocking qualifier at offset
    /// +3 causes Pattern 1 to fall through, and `preceded_by_non_reqwest` in Pattern 2
    /// then suppresses detection (blocking is not in the path-relative exclusion set).
    #[test]
    fn test_timeout_scanner_blocking_client_new_flagged() {
        let src = r#"
            fn f() -> reqwest::blocking::Client {
                reqwest::blocking::Client::new()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "reqwest::blocking::Client::new() must produce exactly 1 finding; got: {findings:?}"
        );
    }

    /// F-P23-HIGH-001 — `reqwest::blocking::ClientBuilder::new().build()` without
    /// `.timeout()` must be flagged.
    ///
    /// The `reqwest::blocking::` module segment is detected by Pattern 1's extended
    /// blocking sub-pattern, which calls `has_build_without_timeout` to verify the chain
    /// is missing `.timeout()`.
    #[test]
    fn test_timeout_scanner_blocking_client_builder_no_timeout_flagged() {
        let src = r#"
            fn f() -> reqwest::blocking::Client {
                reqwest::blocking::ClientBuilder::new()
                    .build()
                    .unwrap()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "reqwest::blocking::ClientBuilder::new().build() without .timeout() must produce 1 finding; \
             got: {findings:?}"
        );
    }

    /// F-P23-HIGH-001 — `reqwest::blocking::Client::builder().build()` without
    /// `.timeout()` must be flagged.
    ///
    /// The `reqwest::blocking::` module segment is detected by Pattern 1's extended
    /// blocking sub-pattern for the `Client::builder()` form.
    #[test]
    fn test_timeout_scanner_blocking_client_builder_flagged() {
        let src = r#"
            fn f() -> reqwest::blocking::Client {
                reqwest::blocking::Client::builder()
                    .build()
                    .unwrap()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "reqwest::blocking::Client::builder().build() without .timeout() must produce 1 finding; \
             got: {findings:?}"
        );
    }

    /// F-P23-HIGH-001 negative — `other_sdk::blocking::Client::new()` must NOT be flagged.
    ///
    /// The `blocking` module segment in a non-reqwest path must not be misidentified as
    /// reqwest. Pattern 1 only fires when `reqwest` is confirmed at the start of the path;
    /// Pattern 2's `preceded_by_non_reqwest` guard correctly suppresses `blocking::Client`.
    #[test]
    fn test_timeout_scanner_other_sdk_blocking_not_flagged() {
        let src = r#"
            fn f() {
                other_sdk::blocking::Client::new();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            findings.is_empty(),
            "other_sdk::blocking::Client::new() must NOT be flagged; got: {findings:?}"
        );
    }

    // ── F-P23-MED-005: self::/super::/Self:: qualifier pinning tests ─────────

    /// F-P23-MED-005 — `self::Client::new()` must be flagged (Pattern 2 path).
    ///
    /// `self` is a path-relative qualifier, not a third-party crate name. The
    /// `preceded_by_non_reqwest` guard excludes `self` from the non-reqwest suppression
    /// set (alongside `crate`, `super`, `Self`), so Pattern 2 emits a finding.
    /// This test pins the `self::` form to prevent regression if the exclusion set is
    /// ever narrowed back to `"crate"` alone.
    #[test]
    fn test_timeout_scanner_self_qualified_client_new_flagged() {
        let src = r#"
            fn f() {
                self::Client::new();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "self::Client::new() must be flagged (Pattern 2 path); got: {findings:?}"
        );
    }

    /// F-P23-MED-005 — `super::ClientBuilder::new().build()` without `.timeout()` must be
    /// flagged (Pattern 3 path).
    ///
    /// `super` is a path-relative qualifier. The `preceded_by_non_reqwest` guard excludes
    /// it from suppression, so Pattern 3 emits a finding. Pins the `super::` form for
    /// `ClientBuilder` to prevent regression.
    #[test]
    fn test_timeout_scanner_super_qualified_client_builder_new_flagged() {
        let src = r#"
            fn f() {
                super::ClientBuilder::new().build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "super::ClientBuilder::new().build() without .timeout() must be flagged (Pattern 3 path); \
             got: {findings:?}"
        );
    }

    /// F-P23-MED-005 — `Self::Client::builder().build()` without `.timeout()` must be
    /// flagged (Pattern 4 path).
    ///
    /// `Self` is a path-relative qualifier (associated item resolution). The
    /// `preceded_by_non_reqwest` guard excludes it from suppression, so Pattern 4 emits a
    /// finding. Pins the `Self::` form for `Client::builder()` to prevent regression if the
    /// exclusion set is ever narrowed back to `"crate"` alone. Test name uses `self_type`
    /// (snake-case) to satisfy the non_snake_case lint; the fixture uses `Self::` (capital).
    #[test]
    fn test_timeout_scanner_self_type_qualified_client_builder_flagged() {
        let src = r#"
            fn f() {
                Self::Client::builder().build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "Self::Client::builder().build() without .timeout() must be flagged (Pattern 4 path); \
             got: {findings:?}"
        );
    }
}
