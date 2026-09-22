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
    /// A paren group (call-site arguments) — represented as a marker with line.
    ParenGroup(usize),
    /// A brace group — used to reset chain state between statements.
    BraceGroup(usize),
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
            | FlatToken::BraceGroup(l)
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
                    match g.delimiter() {
                        Delimiter::Parenthesis => out.push(FlatToken::ParenGroup(line)),
                        Delimiter::Brace => out.push(FlatToken::BraceGroup(line)),
                        _ => {}
                    }
                    // Recurse into paren and brace groups for nested calls
                    flatten_tokens_no_test(g.stream().into_iter(), out, in_test_depth);
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
/// **KNOWN-LIMITATION 1 — `use`-import false positives:** Pattern 2 (bare `Client::new()`)
/// flags unqualified calls conservatively. If a crate uses `use some_sdk::Client;` and then
/// calls `Client::new()`, the scanner cannot distinguish it from a reqwest `Client::new()`.
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
                if has_build_without_timeout(flat, i, chain_end) {
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
                if has_build_without_timeout(flat, i, chain_end) {
                    findings.push(format!(
                        "{}:{}: reqwest::ClientBuilder::new() without .timeout() (BC-2.14.004)",
                        path, line
                    ));
                }
                i = chain_end;
                continue;
            }
        }

        // Pattern 2: bare Client :: new ( ) — but NOT if preceded by a non-reqwest qualifier
        // The B-4 test: use reqwest::Client; ... Client::new() should be flagged
        // The B-5 test: OpenAiClient::new() should NOT be flagged (name differs)
        // The S-3 test: mcp_sdk::Client::new() should NOT be flagged (preceded by mcp_sdk::)
        //
        // KNOWN-LIMITATION: Pattern 2 (bare Client::new()) only detects inline-qualified calls
        // (e.g., reqwest::Client::new() or some::Client::new()). If a module uses
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
            let preceded_by_non_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && if let FlatToken::Ident(prev, _) = &flat[i - 3] {
                    prev != "reqwest"
                } else {
                    false
                };
            if !preceded_by_non_reqwest {
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
        if let FlatToken::Ident(name, _) = &flat[i]
            && name == "ClientBuilder"
            && matches_double_colon(flat, i + 1)
            && matches_ident(flat, i + 3, "new")
        {
            let line = flat[i].line();
            let chain_end = find_chain_end(flat, i);
            if has_build_without_timeout(flat, i, chain_end) {
                findings.push(format!(
                    "{}:{}: ClientBuilder::new() without .timeout() (BC-2.14.004)",
                    path, line
                ));
            }
            i = chain_end;
            continue;
        }

        // Pattern 4: Client :: builder ... .build() without .timeout() (unqualified)
        if let FlatToken::Ident(name, _) = &flat[i]
            && name == "Client"
            && matches_double_colon(flat, i + 1)
            && matches_ident(flat, i + 3, "builder")
        {
            // Only flag bare Client::builder() — not SomeOtherClient::builder()
            // Check it's not preceded by a non-reqwest qualifier
            let preceded_by_non_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && if let FlatToken::Ident(prev, _) = &flat[i - 3] {
                    prev != "reqwest"
                } else {
                    false
                };
            // Also skip if preceded by reqwest:: (handled in the reqwest block above)
            let preceded_by_reqwest = i >= 3
                && matches_double_colon(flat, i - 2)
                && matches_ident(flat, i - 3, "reqwest");
            if !preceded_by_non_reqwest && !preceded_by_reqwest {
                let line = flat[i].line();
                let chain_end = find_chain_end(flat, i);
                if has_build_without_timeout(flat, i, chain_end) {
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

/// Find the end of a method chain starting at `start`.
///
/// A chain continues as long as we see `.`, ident, paren-group sequences.
/// Returns the index just past the last token in the chain.
fn find_chain_end(flat: &[FlatToken], start: usize) -> usize {
    let n = flat.len();
    let mut i = start;
    // Skip past any initial token sequence for the base (e.g. reqwest::Client::builder())
    // We just advance until we can't see a `.method(` continuation.
    // First skip past the initial expression up to and including the first `()`
    while i < n {
        if matches!(flat[i], FlatToken::ParenGroup(_)) {
            i += 1;
            break;
        }
        i += 1;
    }
    // Now consume `.method(args)` chains
    loop {
        // A chain step: `.` ident `(` `)` — the paren group
        if i + 2 < n
            && matches!(&flat[i], FlatToken::Punct('.', _))
            && matches!(&flat[i + 1], FlatToken::Ident(_, _))
            && matches!(&flat[i + 2], FlatToken::ParenGroup(_))
        {
            i += 3;
        } else {
            break;
        }
    }
    i
}

/// Check if a chain from `start` calls `.build()` without a prior valid `.timeout()`.
///
/// Scans forward from `start` in the full `flat` list, stopping at the first `;`
/// or `BraceGroup` boundary. The `_end` hint produced by `find_chain_end` is
/// intentionally ignored: when method arguments are present, `find_chain_end`
/// truncates at the first argument token (which is inlined by
/// `flatten_tokens_no_test` immediately after the `ParenGroup` marker), placing
/// the subsequent `.build()` call beyond the `_end` boundary.
///
/// Returns `true` if `.build()` is present and no valid `.timeout(d)` where
/// `d > Duration::ZERO` precedes it. `.timeout(Duration::ZERO)` is treated as
/// absent (BC-2.14.004 {PC-001}, {INV-004}).
fn has_build_without_timeout(flat: &[FlatToken], start: usize, _end: usize) -> bool {
    let n = flat.len();
    let mut found_build = false;
    let mut found_timeout_before_build = false;
    let mut i = start;
    while i < n {
        // Statement/block boundaries terminate the chain scan.
        match &flat[i] {
            FlatToken::BraceGroup(_) => break,
            FlatToken::Punct(c, _) if *c == ';' => break,
            FlatToken::Punct(c, _) if *c == '.' => {
                if let Some(FlatToken::Ident(name, _)) = flat.get(i + 1) {
                    if name == "timeout" {
                        // Only credit a timeout whose argument is not Duration::ZERO.
                        if !is_zero_duration_timeout_arg(flat, i) {
                            found_timeout_before_build = true;
                        }
                    } else if name == "build"
                        && matches!(flat.get(i + 2), Some(FlatToken::ParenGroup(_)))
                    {
                        // build() call found — was there a valid timeout before it?
                        found_build = true;
                        if found_timeout_before_build {
                            return false; // compliant
                        }
                    }
                }
            }
            _ => {}
        }
        i += 1;
    }
    found_build && !found_timeout_before_build
}

/// Returns `true` if a zero-duration literal matches the zero-literal normalisation rules.
///
/// Strips underscores (for `0_u64`, `0_u32`, etc.) and also recognises hex/binary/octal
/// zero forms (`0x0`, `0b0`, `0o0`) which are equivalent to the integer zero at compile time.
fn is_zero_literal(s: &str) -> bool {
    let normalized = s.replace('_', "");
    if matches!(
        normalized.as_str(),
        "0" | "0u64"
            | "0u32"
            | "0u128"
            | "0usize"
            | "0i64"
            | "0i32"
            | "0.0"
            | "0.0f64"
            | "0.0f32"
            // Hex/binary/octal zero forms
            | "0x0"
            | "0b0"
            | "0o0"
    ) {
        return true;
    }
    false
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
/// `from_nanos(0)` / `from_secs_f64(0.0)`** (offsets +3..+8):
/// ```text
/// +2  ParenGroup       (outer paren marker)
/// +3  Ident("Duration")
/// +4  Punct(':')  +5  Punct(':')
/// +6  Ident("from_secs"|"from_millis"|"from_nanos"|"from_secs_f64")
/// +7  ParenGroup       (inner paren marker for constructor args)
/// +8  Literal("0"|"0u64"|"0u32"|"0i64"|"0usize"|"0.0"|"0.0f64"|"0.0f32"|"0x0"|"0b0"|"0o0")
/// ```
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
        if let Some(FlatToken::Literal(s, _)) = flat.get(dur_offset + 5)
            && is_zero_literal(s)
        {
            return true;
        }
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
}
