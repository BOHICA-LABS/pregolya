//! CI lint gate: reject `.unwrap()`, `.expect()`, `assert!`, `assert_eq!`,
//! `assert_ne!`, and `panic!` in library source files.
//!
//! Implements `cargo xtask check-no-panic` (BC-2.14.003 {PC-004}/{PC-005}/{PC-006},
//! VP-DI008-01).
//!
//! # Scanning rules (BC-2.14.003 §EC-007 two-exemption discipline)
//!
//! ## Flagged patterns (in non-test, non-exempt scope):
//! - `.unwrap()` / `.expect(...)` calls
//! - bare `assert!`, `assert_eq!`, `assert_ne!`, `panic!` WITHOUT:
//!   - a `# Panics` doc section on the enclosing function, AND
//!   - a BC-ID (e.g. `BC-2.14.001`) in the assert message
//! - `_ => unreachable!()` wildcard match arms (latent panic under enum evolution)
//!
//! ## Exempt patterns:
//! - `unreachable!()` in a fully-enumerated NAMED match arm (no `_` wildcard arm)
//!   e.g. `Phase::Done => unreachable!(...)` — this is Exemption 1
//! - `assert!` / `assert_eq!` / `assert_ne!` where the enclosing function has a
//!   `# Panics` doc section AND the assert message contains a BC-ID
//! - `debug_assert!*` (compiles out in release; BC-2.14.003 {INV-003})
//! - `#[cfg(test)]` blocks, files under `tests/`, `*_test.rs`, `*_tests.rs`, `*/tests.rs`
//!
//! # File exemptions
//!
//! Files under `tests/` directories, files ending in `_test.rs`/`_tests.rs`,
//! and files ending in `/tests.rs` are fully exempt (BC-2.14.003 {INV-004}).

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
/// calls, bare `assert!`/`assert_eq!`/`assert_ne!`/`panic!` without documented
/// programmer-error-guard exemption, and `_ => unreachable!()` wildcard arms
/// outside `#[cfg(test)]` blocks.
///
/// # Two-exemption discipline (BC-2.14.003 §EC-007)
///
/// Exemption 1 — explicit named-arm unreachable: `unreachable!()` in a named
/// (non-wildcard) match arm pattern, e.g. `Phase::Done => unreachable!(...)`, is an
/// exhaustiveness witness and is NOT flagged. A wildcard `_ => unreachable!(...)` is
/// always flagged regardless of what precedes it (BC-2.14.003 §EC-004).
///
/// Exemption 2 — documented programmer-error-guard assert: `assert!`/`assert_eq!`/
/// `assert_ne!` where the enclosing function has a `# Panics` doc section AND the
/// assert message (any literal argument) contains a BC-ID (`BC-` followed by a digit)
/// is NOT flagged.
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
    walk_panic_tokens(
        ts.into_iter(),
        &mut findings,
        path,
        &mut 0u32,
        false, // fn_has_panics_doc: false at module level
    );
    findings
}

/// Panic-inducing macros flagged in non-test production code when used without
/// a documented programmer-error-guard exemption.
///
/// Excluded from this list:
/// - `debug_assert!*`: compiles out in release mode (BC-2.14.003 {INV-003})
/// - `unreachable!`: handled separately — only flagged for `_ =>` wildcard arms
/// - `todo!`, `unimplemented!`: not in scope for this gate
const FLAGGED_PANIC_MACROS: &[&str] = &["assert", "assert_eq", "assert_ne", "panic"];

/// Returns true if the bracket group `[...]` is a `doc` attribute whose
/// string literal contains the text `# Panics`.
///
/// Matches `#[doc = " # Panics"]` (emitted by `/// # Panics` doc comments).
fn doc_group_has_panics(g: &proc_macro2::Group) -> bool {
    use proc_macro2::TokenTree;
    let tokens: Vec<TokenTree> = g.stream().into_iter().collect();
    // Must be: doc = "..." where "..." contains "# Panics"
    if !matches!(tokens.first(), Some(TokenTree::Ident(id)) if id == "doc") {
        return false;
    }
    // tokens[1] should be "="
    if !matches!(tokens.get(1), Some(TokenTree::Punct(p)) if p.as_char() == '=') {
        return false;
    }
    // tokens[2] should be the string literal
    if let Some(TokenTree::Literal(lit)) = tokens.get(2) {
        lit.to_string().contains("# Panics")
    } else {
        false
    }
}

/// Returns true if the bracket group `[...]` is any `doc` attribute.
///
/// Used to distinguish doc attributes from other attributes (e.g. `#[allow(...)]`)
/// so that non-doc attributes between doc comments and a `fn` keyword do not reset
/// the pending-panics-doc state.
fn is_doc_group(g: &proc_macro2::Group) -> bool {
    use proc_macro2::TokenTree;
    matches!(
        g.stream().into_iter().next(),
        Some(TokenTree::Ident(id)) if id == "doc"
    )
}

/// Returns true if any literal in the macro-call argument group `(...)` contains
/// a BC-ID pattern: the text `"BC-"` immediately followed by an ASCII digit.
///
/// Used by the documented-assert exemption check (BC-2.14.003 §EC-007 Exemption 2).
fn args_contain_bc_id(g: &proc_macro2::Group) -> bool {
    use proc_macro2::TokenTree;
    for token in g.stream() {
        if let TokenTree::Literal(lit) = token {
            let s = lit.to_string();
            if let Some(pos) = s.find("BC-")
                && s[pos + 3..]
                    .bytes()
                    .next()
                    .map(|b| b.is_ascii_digit())
                    .unwrap_or(false)
            {
                return true;
            }
        }
    }
    false
}

/// Recursive token-tree walker for `scan_for_panics_in_source`.
///
/// Implements the two-exemption discipline (BC-2.14.003 §EC-007):
///
/// **FLAGS:**
/// - `.unwrap()` / `.expect(...)` method calls outside `#[cfg(test)]` blocks
/// - bare `assert!` / `assert_eq!` / `assert_ne!` / `panic!` where the assert
///   message does NOT contain a BC-ID OR the enclosing function has no `# Panics`
///   doc section
/// - `_ => unreachable!()` wildcard match arms (ALWAYS flagged; §EC-004)
/// - `unreachable!()` outside any match arm (let-else, if-block, etc.; §PC-006)
///
/// **EXEMPTS:**
/// - Exemption 1: `unreachable!()` in a named (non-wildcard) match arm
///   e.g. `Phase::Done => unreachable!(...)` — requires no wildcard `_` in the arm
/// - Exemption 2: `assert!` where `fn_has_panics_doc` is true AND message has BC-ID
/// - `debug_assert!*` (compile-out in release)
/// - `#[cfg(test)]` blocks (tracked via `in_test_depth`)
///
/// # Parameters
///
/// - `fn_has_panics_doc`: true when the immediately enclosing named function has a
///   `# Panics` doc section. Passed from the function-entry handler when recursing
///   into a function body; inherited unchanged for non-function brace groups (match
///   arms, if-else bodies, etc.).
#[allow(clippy::too_many_lines)]
fn walk_panic_tokens(
    iter: proc_macro2::token_stream::IntoIter,
    findings: &mut Vec<String>,
    path: &str,
    in_test_depth: &mut u32,
    fn_has_panics_doc: bool,
) {
    use proc_macro2::{Delimiter, TokenTree};

    let tokens: Vec<TokenTree> = iter.collect();
    let mut i = 0;
    // Tracks whether recent consecutive `#[doc = ...]` attributes contained
    // a `# Panics` section. Reset on any non-attribute, non-qualifier token;
    // consumed when a `fn` keyword is encountered.
    let mut pending_panics_doc = false;

    while i < tokens.len() {
        match &tokens[i] {
            // ── Attribute handling (`#[...]`) ────────────────────────────────
            TokenTree::Punct(p) if p.as_char() == '#' => {
                if let Some(TokenTree::Group(g)) = tokens.get(i + 1)
                    && g.delimiter() == Delimiter::Bracket
                {
                    if crate::is_cfg_test_group(g) {
                        // BC-2.14.003: cfg(test) block — recurse at elevated depth
                        pending_panics_doc = false;
                        let mut j = i + 2;
                        // Skip any intervening #[...] attributes between cfg(test) and block
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
                                    walk_panic_tokens(
                                        body.stream().into_iter(),
                                        findings,
                                        path,
                                        in_test_depth,
                                        false,
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
                    } else if is_doc_group(g) {
                        // Doc attribute: accumulate # Panics state
                        if doc_group_has_panics(g) {
                            pending_panics_doc = true;
                        }
                        // Do NOT reset if it's a doc line without # Panics
                        i += 2;
                        continue;
                    } else {
                        // Non-doc attribute (e.g. #[allow(...)], #[inline], #[must_use]):
                        // these can appear between doc comments and `fn`, so do NOT reset
                        // pending_panics_doc. Skip past the attribute.
                        i += 2;
                        continue;
                    }
                }
                // Bare `#` without bracket group — unlikely in valid Rust, reset state
                pending_panics_doc = false;
            }

            // ── Qualifier keywords that precede `fn` ─────────────────────────
            // `pub`, `async`, `unsafe`, `const`, `extern`, `default` can appear
            // between doc attrs and the `fn` keyword — do NOT reset pending_panics_doc.
            TokenTree::Ident(id)
                if matches!(
                    id.to_string().as_str(),
                    "pub" | "async" | "unsafe" | "const" | "extern" | "default"
                ) => {}

            // ── `fn` keyword: consume pending_panics_doc and recurse into body ──
            TokenTree::Ident(id) if id == "fn" && *in_test_depth == 0 => {
                let this_fn_panics_doc = pending_panics_doc;
                pending_panics_doc = false;
                // Scan forward past name, params, return type to find the body `{...}`
                let mut j = i + 1;
                let mut found_body = false;
                while j < tokens.len() {
                    match &tokens[j] {
                        TokenTree::Group(g) if g.delimiter() == Delimiter::Brace => {
                            // Function body found — recurse with fn_has_panics_doc
                            walk_panic_tokens(
                                g.stream().into_iter(),
                                findings,
                                path,
                                in_test_depth,
                                this_fn_panics_doc,
                            );
                            i = j; // advance outer cursor to brace position
                            found_body = true;
                            break;
                        }
                        TokenTree::Punct(p) if p.as_char() == ';' => {
                            // Abstract fn declaration (no body) — advance past `;`
                            i = j;
                            found_body = true;
                            break;
                        }
                        _ => {}
                    }
                    j += 1;
                }
                if !found_body {
                    // Reached end without finding body — no advance needed
                }
            }

            // ── Brace group NOT preceded by `fn` ─────────────────────────────
            // Recurse inheriting fn_has_panics_doc (match arms, if/else, impl, etc.)
            TokenTree::Group(g) if g.delimiter() == Delimiter::Brace => {
                pending_panics_doc = false;
                walk_panic_tokens(
                    g.stream().into_iter(),
                    findings,
                    path,
                    in_test_depth,
                    fn_has_panics_doc,
                );
            }

            // ── `_ => unreachable!()` wildcard arm detection ─────────────────
            // Wildcard arms are ALWAYS flagged as latent panic paths under enum
            // evolution (BC-2.14.003 §EC-004/EC-007). There is NO exemption for
            // wildcard arms regardless of whether qualified enum-variant arms
            // precede them — the presence of named-variant arms only proves current
            // exhaustiveness; it does NOT prove future-proof safety. A new variant
            // added downstream makes the `_` arm reachable and causes a production
            // panic.
            //
            // Exemption 1 applies ONLY to explicit named arms WITHOUT a wildcard:
            //   `Phase::Done => unreachable!(...)` — not `_ => unreachable!(...)`
            TokenTree::Ident(id) if id == "_" && *in_test_depth == 0 => {
                pending_panics_doc = false;
                // Check for the pattern: `_` `=` `>` `unreachable` `!` `(...)`
                if let (
                    Some(TokenTree::Punct(fat_eq)),
                    Some(TokenTree::Punct(fat_gt)),
                    Some(TokenTree::Ident(ur_id)),
                    Some(TokenTree::Punct(bang)),
                    Some(TokenTree::Group(args)),
                ) = (
                    tokens.get(i + 1),
                    tokens.get(i + 2),
                    tokens.get(i + 3),
                    tokens.get(i + 4),
                    tokens.get(i + 5),
                ) && fat_eq.as_char() == '='
                    && fat_gt.as_char() == '>'
                    && ur_id == "unreachable"
                    && bang.as_char() == '!'
                    && args.delimiter() == Delimiter::Parenthesis
                {
                    let line = ur_id.span().start().line;
                    findings.push(format!(
                        "{}:{}: wildcard-arm unreachable!() in non-test code \
                         (BC-2.14.003 EC-004/EC-007 violation: _ => unreachable! is a \
                         latent panic path under enum evolution; use explicit named arm \
                         unreachable! or documented assert!)",
                        path, line
                    ));
                }
            }

            // ── bare `unreachable!()` outside exhaustive-match named arms ─────
            // §PC-006: unreachable! is ONLY permitted in explicit named match arms
            // (e.g. `Phase::Done => unreachable!(...)`). Using it in let-else
            // else-blocks, if-blocks, or other non-arm contexts is a POL-31
            // violation — those call-sites ARE reachable on in-crate struct-literal
            // construction or future code paths.
            //
            // Detection: `unreachable` followed by `!` and `(...)`.
            //   - If immediately preceded by `=>` (tokens `=` `>`):
            //     - Named arm → Exemption 1 applies; EXEMPT.
            //     - Wildcard `_ =>` arm → already flagged by the `_` handler;
            //       skip to avoid duplicate finding.
            //   - Otherwise (not in a match arm position): ALWAYS FLAG.
            TokenTree::Ident(id) if id == "unreachable" && *in_test_depth == 0 => {
                pending_panics_doc = false;
                if matches!(tokens.get(i + 1), Some(TokenTree::Punct(p)) if p.as_char() == '!')
                    && matches!(
                        tokens.get(i + 2),
                        Some(TokenTree::Group(g)) if g.delimiter() == Delimiter::Parenthesis
                    )
                {
                    // Check if this `unreachable!` is immediately after `=>` (match arm).
                    // In a match body the token sequence around a match arm is:
                    //   <pattern> `=` `>` unreachable ...
                    // so tokens[i-1] == `>` and tokens[i-2] == `=` if in a match arm.
                    let in_match_arm_position = if i >= 2 {
                        matches!(tokens.get(i - 2), Some(TokenTree::Punct(p)) if p.as_char() == '=')
                            && matches!(tokens.get(i - 1), Some(TokenTree::Punct(p)) if p.as_char() == '>')
                    } else {
                        false
                    };
                    if !in_match_arm_position {
                        // Bare unreachable! outside any match arm — §PC-006 violation.
                        let line = id.span().start().line;
                        findings.push(format!(
                            "{}:{}: unreachable!() outside exhaustive-match named arm \
                             in non-test code (BC-2.14.003 §PC-006 violation: \
                             unreachable! is only permitted in explicit named match arms; \
                             use documented assert!() for programmer-error guards)",
                            path, line
                        ));
                    }
                    // If in_match_arm_position: either a named arm (Exemption 1 → EXEMPT)
                    // or the wildcard `_ =>` case (already flagged by the `_` handler above).
                }
            }

            // ── `.unwrap()` / `.expect(...)` detection ───────────────────────
            TokenTree::Punct(p) if p.as_char() == '.' && *in_test_depth == 0 => {
                pending_panics_doc = false;
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

            // ── Flagged panic macros: assert!, assert_eq!, assert_ne!, panic! ──
            // Exemption 2: assert! with fn_has_panics_doc AND BC-ID in message.
            TokenTree::Ident(id) if *in_test_depth == 0 => {
                let name = id.to_string();
                pending_panics_doc = false;
                if FLAGGED_PANIC_MACROS.contains(&name.as_str())
                    && matches!(
                        tokens.get(i + 1),
                        Some(TokenTree::Punct(p)) if p.as_char() == '!'
                    )
                    && matches!(
                        tokens.get(i + 2),
                        Some(TokenTree::Group(g)) if g.delimiter() == Delimiter::Parenthesis
                    )
                {
                    // Check Exemption 2: fn has # Panics doc AND message has BC-ID
                    let is_exempt = fn_has_panics_doc
                        && if let Some(TokenTree::Group(args)) = tokens.get(i + 2) {
                            args_contain_bc_id(args)
                        } else {
                            false
                        };
                    if !is_exempt {
                        let line = id.span().start().line;
                        findings.push(format!(
                            "{}:{}: {}!() in non-test code (BC-2.14.003 violation)",
                            path, line, name
                        ));
                    }
                }
            }

            // ── Other non-brace groups (parens, brackets) ────────────────────
            TokenTree::Group(g) => {
                pending_panics_doc = false;
                walk_panic_tokens(
                    g.stream().into_iter(),
                    findings,
                    path,
                    in_test_depth,
                    fn_has_panics_doc,
                );
            }

            // ── Any other token resets pending_panics_doc ────────────────────
            _ => {
                pending_panics_doc = false;
            }
        }
        i += 1;
    }
}
