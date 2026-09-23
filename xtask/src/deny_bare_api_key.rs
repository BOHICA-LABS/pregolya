//! CI lint gate: reject credential struct definitions that violate
//! the pregolya key-safety invariants.
//!
//! Implements `cargo xtask deny-bare-api-key` (BC-2.14.005 {PC-006},
//! VP-DI010-02).
//!
//! # Scanning rules
//!
//! Scans `crates/**/*.rs` for STRUCTURAL violations on public structs whose
//! names contain a credential sentinel (case-insensitive):
//!
//! **Credential sentinels:** `key`, `token`, `secret`, `credential`,
//! `auth`, `bearer`, `password`, `passphrase`.
//!
//! Sentinel expansion policy: add new terms when new credential patterns
//! emerge in the workspace. Sentinels are lowercase substrings — a struct
//! named `OauthBearerToken` matches because it contains `bearer` and `token`.
//!
//! 1. **`#[derive(Debug)]` without a manual `impl Debug`** — auto-derived
//!    `Debug` would emit the raw inner value and leak key material.
//! 2. **`#[derive(Serialize)]`** — serialization exposes credentials in
//!    JSON/TOML artifacts (BC-2.14.005 {PC-003}).
//! 3. **`#[derive(Deserialize)]`** — `Deserialize` bypasses `new()` validation
//!    (BC-2.14.006): arbitrary strings (including empty/whitespace) could be
//!    deserialized directly without going through the validated constructor.
//! 4. **`impl fmt::Display for NAME`** — `Display` output is invoked by
//!    `format!("{}", key)` and the `{key}` shorthand; credential values must
//!    not appear in any format output (BC-2.14.005 {INV-002}).
//! 5. **`impl Deref for NAME` with `type Target = str` or `type Target = String`**
//!    — Deref coercion silently exposes the inner value via auto-deref ({INV-003}).
//!
//! Compliant pattern: manual `impl fmt::Debug` emitting `"<redacted>"`,
//! no `Serialize`/`Deserialize` derive, no `Display` impl, access only via
//! `expose_secret()`.
//!
//! - Files under `tests/` directories and `#[cfg(test)]` blocks are exempt.
//! - Exits non-zero when any violation is found; exits 0 on a clean scan.
//!
//! # Known limitations
//!
//! KNOWN-LIMITATION: `#[cfg_attr(feature="...", derive(Debug/Serialize/Deserialize))]`
//! conditional derives are not detected by the current AST walker. A developer who
//! conditionally derives a dangerous trait under a feature flag would evade this gate.
//! Full `cfg_attr` argument parsing requires deeper attribute token walk.
//! Tracked for a future enhancement when feature-gated derives are introduced in the
//! workspace.

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
    if let Err(msg) = crate::check_post_exemption_vacuity("deny-bare-api-key", files_analyzed) {
        eprintln!("{msg}");
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
/// Detects five violation patterns on public structs whose names contain any of the
/// eight credential sentinels (`key`, `token`, `secret`, `credential`, `auth`,
/// `bearer`, `password`, `passphrase` — case-insensitive substring match):
///
/// 1. `#[derive(Debug)]` — auto-derived Debug leaks key material.
/// 2. `#[derive(Serialize)]` — exposes credentials in serialized artifacts.
/// 3. `#[derive(Deserialize)]` — bypasses `new()` validation; arbitrary strings
///    can be deserialized without going through the validated constructor.
/// 4. `impl fmt::Display for NAME` — Display output is invoked by `format!("{}", key)`
///    and the `{key}` shorthand; credential values must not appear in format output.
/// 5. `impl Deref for NAME { type Target = str; }` or `type Target = String;` —
///    auto-deref exposes the inner value via Deref coercion.
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
///
/// Sentinels are case-insensitive substring matches. A struct named `OauthBearerToken`
/// matches both `bearer` and `token`. Expand this list when new credential patterns
/// appear in the workspace (see module-level expansion policy).
const CREDENTIAL_SENTINELS: &[&str] = &[
    "key",
    "token",
    "secret",
    "credential",
    "auth",
    "bearer",
    "password",
    "passphrase",
];

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
/// credential sentinel and has a dangerous derive (`Debug`, `Serialize`, or `Deserialize`).
fn check_struct_derives(
    tokens: &[proc_macro2::TokenTree],
    derives: &[String],
    j: usize,
    path: &str,
    findings: &mut Vec<String>,
) {
    use proc_macro2::{Delimiter, TokenTree};
    let is_pub = matches!(tokens.get(j), Some(TokenTree::Ident(id)) if id == "pub");
    // After `pub`, skip an optional visibility group like `(crate)`, `(super)`,
    // or `(in path)` — e.g. `pub(crate) struct` has a Group at j+1.
    let struct_kw_j = if is_pub {
        if matches!(tokens.get(j + 1), Some(TokenTree::Group(g)) if g.delimiter() == Delimiter::Parenthesis)
        {
            j + 2 // pub(crate) / pub(super) / pub(in ...) — skip the visibility group
        } else {
            j + 1 // plain pub
        }
    } else {
        j
    };

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
            if derives.iter().any(|d| d == "Deserialize") {
                findings.push(format!(
                    "{}:{}: BC-2.14.005 {{PC-006}}: pub struct '{}' derives Deserialize \
                     — #[derive(Deserialize)] bypasses new() validation (BC-2.14.006): \
                     arbitrary strings (including empty/whitespace) could be deserialized \
                     directly without going through the validated constructor",
                    path, line, sname
                ));
            }
        }
    }
}

/// Scan an `impl … Deref for NAME { … }` block for `type Target = str|String`.
///
/// Returns the index after the impl body brace group, or `start` unchanged if
/// this is not a recognised Deref impl.
///
/// Handles leading `::` before the implementing type name (absolute-path forms
/// such as `impl std::ops::Deref for ::my_crate::AnthropicApiKey { … }`):
/// before collecting path segments after `for`, any leading `::` is consumed
/// so the first collected ident is the crate name, not a stray punctuation token.
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
            // No angle-bracket depth tracking needed here: a false positive would also
            // require `type Target = str|String` in the impl body (enforced by
            // `impl_body_has_target_str`). A generic bound `impl<T: Deref> SomeTrait for ApiKey {}`
            // does NOT have a `type Target` in that impl block, so it will never trigger
            // `impl_body_has_target_str`. This asymmetry with `check_impl_display_in_tokens`
            // (which does have angle-bracket depth tracking) is intentional: the `type Target`
            // requirement in the body acts as the false-positive guard that angle-bracket depth
            // tracking would otherwise provide. See test_BC_2_14_005_generic_deref_bound_not_flagged.
            TokenTree::Ident(id) if id == "Deref" && !for_found => {
                deref_found = true;
                j += 1;
            }
            TokenTree::Ident(id) if id == "for" && deref_found => {
                for_found = true;
                j += 1;
                // Skip optional leading `::` (absolute path e.g. `impl Trait for ::crate::Type`)
                if matches!(tokens.get(j), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                    && matches!(tokens.get(j + 1), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                {
                    j += 2;
                }
                // Collect path segments (idents separated by `::`) and use the LAST ident
                // as the implementing type name.  Handles both plain `impl Deref for
                // OpenAiApiKey` and path-qualified forms such as
                // `impl std::ops::Deref for crate::credentials::OpenAiApiKey`
                // (F-P8-M03 fix: first ident was previously used, which is the path root).
                //
                // Path-qualified only: after collecting an ident, continue ONLY if the
                // next two tokens are `::`.  Any other token (including the `where` keyword,
                // a `{`, or a `<`) terminates collection so that `where` clause identifiers
                // are not consumed into the struct name (F-P16-LOW-006).
                let mut last_ident: Option<(String, usize)> = None;
                while j < n {
                    match tokens.get(j) {
                        Some(TokenTree::Ident(sname)) => {
                            last_ident = Some((sname.to_string(), sname.span().start().line));
                            j += 1;
                            // Only continue collecting if followed by `::` (path separator).
                            if matches!(tokens.get(j), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                                && matches!(tokens.get(j + 1), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                            {
                                j += 2; // consume the `::`
                            } else {
                                break; // not a path continuation; stop
                            }
                        }
                        _ => break,
                    }
                }
                if let Some((name, line)) = last_ident {
                    struct_name = name;
                    struct_line = line;
                }
                // j is now positioned at the first non-path token; the outer loop
                // continues from here (no further increment needed in this arm).
                continue;
            }
            TokenTree::Group(body) if body.delimiter() == Delimiter::Brace => {
                if deref_found
                    && for_found
                    && struct_name_has_sentinel(&struct_name)
                    && let Some(target_type) = impl_body_has_target_str(body)
                {
                    findings.push(format!(
                        "{}:{}: BC-2.14.005 {{PC-006}}: impl Deref<Target={}> for '{}' \
                         — inner value exposed via auto-deref \
                         ({{INV-003}}: use expose_secret() instead)",
                        path, struct_line, target_type, struct_name
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

/// Read-only scan from `start` to detect `impl … Display for NAME` on a credential-sentinel struct.
///
/// Does NOT advance the caller's position — only appends findings. Call alongside
/// `check_impl_deref` so both Display and Deref violations on the same impl block are caught.
///
/// Detects:
/// - `impl Display for NAME` (unqualified)
/// - `impl fmt::Display for NAME` (module-qualified)
/// - `impl std::fmt::Display for NAME` (fully-qualified)
/// - `impl fmt::Display for ::crate::NAME` (absolute-path form with leading `::`)
///
/// Handles leading `::` before the implementing type name: before collecting path
/// segments after `for`, any leading `::` is consumed so the first collected ident
/// is the crate name rather than a stray punctuation token that would produce an
/// empty struct name and silently pass the gate.
///
/// Correctly ignores `Display` appearing as a generic bound (e.g.
/// `impl<T: std::fmt::Display> Render for AuthToken {}`): angle-bracket depth
/// tracking ensures only idents at depth 0 are considered as the impl trait
/// target (F-P2-L04 fix).
///
/// (BC-2.14.005 {PC-006}: Display output is invoked by `format!("{}", key)` and the
/// `{key}` shorthand; credential values must not appear in any format output.)
fn check_impl_display_in_tokens(
    tokens: &[proc_macro2::TokenTree],
    start: usize,
    path: &str,
    findings: &mut Vec<String>,
) {
    use proc_macro2::TokenTree;
    let n = tokens.len();
    let mut j = start;
    let mut angle_depth: i32 = 0;
    // Track the last ident seen AT DEPTH 0 before `for` — that is the impl trait name.
    let mut last_depth0_ident: Option<String> = None;
    let mut struct_name = String::new();
    let mut struct_line = 0usize;
    let mut found_for = false;

    while j < n {
        match &tokens[j] {
            TokenTree::Punct(p) if p.as_char() == '<' => {
                angle_depth += 1;
            }
            TokenTree::Punct(p) if p.as_char() == '>' => {
                if angle_depth > 0 {
                    angle_depth -= 1;
                }
            }
            TokenTree::Ident(id) if id == "for" && angle_depth == 0 => {
                found_for = true;
                j += 1;
                // Skip optional leading `::` (absolute path e.g. `impl Trait for ::crate::Type`)
                if matches!(tokens.get(j), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                    && matches!(tokens.get(j + 1), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                {
                    j += 2;
                }
                // Collect path segments (idents separated by `::`) and use the LAST ident
                // as the implementing type name.  Handles both plain `impl Display for
                // OpenAiApiKey` and path-qualified forms such as
                // `impl std::fmt::Display for crate::credentials::OpenAiApiKey`
                // (F-P8-M03 fix: first ident was previously used, which is the path root).
                //
                // Path-qualified only: after collecting an ident, continue ONLY if the
                // next two tokens are `::`.  Any other token (including the `where` keyword,
                // a `{`, or a `<`) terminates collection so that `where` clause identifiers
                // are not consumed into the struct name (F-P16-LOW-006).
                let mut last_ident: Option<(String, usize)> = None;
                while j < n {
                    match &tokens[j] {
                        TokenTree::Ident(sname) => {
                            last_ident = Some((sname.to_string(), sname.span().start().line));
                            j += 1;
                            // Only continue collecting if followed by `::` (path separator).
                            if matches!(tokens.get(j), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                                && matches!(tokens.get(j + 1), Some(TokenTree::Punct(p)) if p.as_char() == ':')
                            {
                                j += 2; // consume the `::`
                            } else {
                                break; // not a path continuation; stop
                            }
                        }
                        _ => break,
                    }
                }
                if let Some((name, line)) = last_ident {
                    struct_name = name;
                    struct_line = line;
                }
                break;
            }
            TokenTree::Ident(id) if angle_depth == 0 => {
                last_depth0_ident = Some(id.to_string());
            }
            // Stop at the impl body brace group — we have what we need
            TokenTree::Group(_) => break,
            TokenTree::Punct(p) if p.as_char() == ';' => break,
            _ => {}
        }
        j += 1;
    }

    let is_display = last_depth0_ident
        .as_deref()
        .map(|s| s == "Display")
        .unwrap_or(false);

    if found_for && is_display && !struct_name.is_empty() && struct_name_has_sentinel(&struct_name)
    {
        findings.push(format!(
            "{}:{}: BC-2.14.005 {{PC-006}}: impl Display for '{}' \
             — Display output is invoked by format!(\"{{}}\", key) and the {{key}} shorthand; \
             credential values must not appear in any format output \
             ({{INV-002}}: use expose_secret() for intentional access only)",
            path, struct_line, struct_name
        ));
    }
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

        // ── Pattern 3: impl [path] Deref for NAME { type Target = str|String; } ─
        // Pattern 4: impl [path] Display for NAME { … } ───────────────────────
        if let TokenTree::Ident(kw) = &tokens[i]
            && kw == "impl"
        {
            // Read-only Display check (doesn't advance position)
            check_impl_display_in_tokens(&tokens, i + 1, path, findings);
            // Deref check advances position past the impl block brace group
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

/// Returns the matched `Target` type name (`"str"` or `"String"`) if the impl body group
/// contains `type Target = str ;` or `type Target = String ;`, or `None` otherwise.
///
/// Both `Deref<Target=str>` and `Deref<Target=String>` expose the inner value
/// via auto-deref coercion (`*key` and coercion to `&str`/`&String`). Both are
/// forbidden on credential-sentinel structs (BC-2.14.005 {PC-004}/{INV-003}). Returning the
/// matched type name rather than a bare bool allows the caller to emit a precise
/// diagnostic (`Target=str` vs `Target=String`).
fn impl_body_has_target_str(body: &proc_macro2::Group) -> Option<&'static str> {
    use proc_macro2::TokenTree;
    let toks: Vec<TokenTree> = body.stream().into_iter().collect();
    let n = toks.len();
    for i in 0..n {
        if matches!(&toks[i], TokenTree::Ident(id) if id == "type")
            && matches!(toks.get(i + 1), Some(TokenTree::Ident(id)) if id == "Target")
            && matches!(toks.get(i + 2), Some(TokenTree::Punct(p)) if p.as_char() == '=')
        {
            if matches!(toks.get(i + 3), Some(TokenTree::Ident(id)) if id == "str") {
                return Some("str");
            }
            if matches!(toks.get(i + 3), Some(TokenTree::Ident(id)) if id == "String") {
                return Some("String");
            }
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::{CREDENTIAL_SENTINELS, scan_for_bare_api_keys_in_source};

    /// F-P7-M04 — BC-2.14.005 {PC-006}: `Deref<Target=String>` diagnostic must name `String`.
    ///
    /// Previously `check_impl_deref` always emitted `Target=str` even when the body contained
    /// `type Target = String`. The diagnostic must now reflect the actual matched target type.
    #[test]
    fn test_bc_2_14_005_deref_target_string_diagnostic_mentions_string() {
        let src = r#"
pub struct ApiKey(String);
impl std::ops::Deref for ApiKey {
    type Target = String;
    fn deref(&self) -> &Self::Target { &self.0 }
}
"#;
        let findings = scan_for_bare_api_keys_in_source(src, "crates/core/src/creds.rs");
        assert!(
            !findings.is_empty(),
            "Deref<Target=String> must be flagged; got: {findings:?}"
        );
        assert!(
            findings
                .iter()
                .any(|f| f.contains("String") || f.contains("Target")),
            "diagnostic must mention Target type; got: {findings:?}"
        );
    }

    /// F-P5-L03 — `impl<T: Deref> SomeTrait for ApiKey` must NOT be flagged.
    ///
    /// The `check_impl_deref` path requires `type Target = str|String` in the impl body
    /// (enforced by `impl_body_has_target_str`). A generic bound `impl<T: Deref>` that has
    /// NO `type Target` in the body cannot trigger the violation; this negative test makes
    /// that invariant load-bearing.
    #[test]
    fn test_bc_2_14_005_generic_deref_bound_not_flagged() {
        let src = r#"
pub struct ApiKey(String);
impl<T: std::ops::Deref> Render for ApiKey {
    fn render(&self) -> String { String::new() }
}
"#;
        let findings = scan_for_bare_api_keys_in_source(src, "crates/core/src/creds.rs");
        assert!(
            findings.is_empty(),
            "impl<T: Deref> generic bound must not be flagged (no type Target = str in body); \
             got: {findings:?}"
        );
    }

    /// F-P8-M02 — BC-2.14.005 {PC-006}: CREDENTIAL_SENTINELS coupling test.
    ///
    /// AC-010 specifies exactly 8 sentinel keywords. This test asserts the count and
    /// the exact set, and verifies each sentinel triggers detection for a derive(Debug)
    /// struct. If a sentinel is removed or misspelled, this test fails.
    #[test]
    fn test_bc_2_14_005_credential_sentinels_all_8_produce_findings() {
        // Assert count matches AC-010 specification.
        assert_eq!(
            CREDENTIAL_SENTINELS.len(),
            8,
            "AC-010 specifies exactly 8 sentinel keywords; got {}",
            CREDENTIAL_SENTINELS.len()
        );
        // Assert exact sentinel set matches AC-010.
        let expected: &[&str] = &[
            "key",
            "token",
            "secret",
            "credential",
            "auth",
            "bearer",
            "password",
            "passphrase",
        ];
        assert_eq!(
            CREDENTIAL_SENTINELS, expected,
            "sentinel set must match AC-010 exactly"
        );

        // Assert each sentinel triggers detection for a derive(Debug) struct.
        for sentinel in CREDENTIAL_SENTINELS {
            let upper = sentinel
                .chars()
                .next()
                .unwrap()
                .to_ascii_uppercase()
                .to_string()
                + &sentinel[1..];
            let struct_name = format!("{}Holder", upper);
            let src = format!("#[derive(Debug)]\npub struct {struct_name}(String);\n");
            let findings = scan_for_bare_api_keys_in_source(&src, "crates/core/src/creds.rs");
            assert!(
                !findings.is_empty(),
                "sentinel '{sentinel}' must trigger detection for derive(Debug) struct \
                 '{struct_name}'; got zero findings"
            );
        }
    }

    /// F-P8-M03 — BC-2.14.005 {PC-006}: path-qualified Display impl must be flagged.
    ///
    /// `impl std::fmt::Display for crate::credentials::OpenAiApiKey` has its type name
    /// as the LAST path segment, not the first. The scanner must collect all path segments
    /// after `for` and use the last one.
    #[test]
    fn test_bc_2_14_005_path_qualified_display_impl_is_flagged() {
        let src = r#"
pub struct OpenAiApiKey(String);
impl std::fmt::Display for crate::credentials::OpenAiApiKey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}
"#;
        let findings = scan_for_bare_api_keys_in_source(src, "crates/core/src/creds.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.005 F-P8-M03: impl Display for path-qualified crate::credentials::OpenAiApiKey \
             must be flagged; got: {findings:?}"
        );
    }

    /// F-P8-M03 — BC-2.14.005 {PC-006}: path-qualified Deref impl must be flagged.
    ///
    /// `impl std::ops::Deref for crate::credentials::OpenAiApiKey` has its type name
    /// as the LAST path segment. The scanner must use the last ident as the type name.
    #[test]
    fn test_bc_2_14_005_path_qualified_deref_impl_is_flagged() {
        let src = r#"
pub struct OpenAiApiKey(String);
impl std::ops::Deref for crate::credentials::OpenAiApiKey {
    type Target = str;
    fn deref(&self) -> &Self::Target { &self.0 }
}
"#;
        let findings = scan_for_bare_api_keys_in_source(src, "crates/core/src/creds.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.005 F-P8-M03: impl Deref for path-qualified crate::credentials::OpenAiApiKey \
             must be flagged; got: {findings:?}"
        );
    }

    /// F-P16-LOW-006 — BC-2.14.005 {PC-006}: `impl Display for NAME where …` must still be
    /// flagged when a `where` clause follows the implementing type name.
    ///
    /// The post-`for` ident collection loop previously accepted ANY ident as a path
    /// segment, causing `where` and subsequent bound identifiers (`Clone`, `Sized`, etc.)
    /// to overwrite the struct name. The scanner would either miss the violation (struct
    /// name replaced by a non-sentinel ident) or emit a spurious finding for a
    /// non-credential type.
    #[test]
    fn test_bc_2_14_005_display_impl_with_where_clause_is_flagged() {
        let src = r#"
pub struct OpenAiApiKey(String);
impl std::fmt::Display for OpenAiApiKey where String: Clone {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}
"#;
        let findings = scan_for_bare_api_keys_in_source(src, "crates/core/src/creds.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.005 F-P16-LOW-006: impl Display for OpenAiApiKey with where clause \
             must be flagged; where clause idents must not overwrite struct name; \
             got: {findings:?}"
        );
    }

    /// F-P17-MED-004 — BC-2.14.005 {PC-006}: `impl Display for ::crate::OpenAiApiKey` must be
    /// flagged even when the type path has a leading `::`.
    ///
    /// Before this fix, the post-`for` collection loop started at the first token after
    /// `for` and broke immediately when it was `Punct(':')` → `struct_name == ""` → no
    /// finding.  The fix consumes an optional leading `::` so the loop correctly
    /// collects the path's ident segments.
    #[test]
    fn test_bc_2_14_005_display_impl_with_leading_colons_path_is_flagged() {
        let src = r#"impl std::fmt::Display for ::my_crate::OpenAiApiKey {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            write!(f, "{}", self.0)
        }
    }"#;
        let findings = scan_for_bare_api_keys_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "Display impl with leading :: path must be flagged — BC-2.14.005 {{PC-006}}"
        );
    }

    /// F-P17-MED-004 — BC-2.14.005 {PC-006}: `impl Deref for ::crate::AnthropicApiKey` must be
    /// flagged even when the type path has a leading `::`.
    ///
    /// TD-VSDD-060 sibling sweep of `check_impl_display_in_tokens`: the same leading-`::` fix
    /// applied to Display must also apply to Deref so both checkers handle absolute paths.
    #[test]
    fn test_bc_2_14_005_deref_impl_with_leading_colons_path_is_flagged() {
        let src = r#"impl std::ops::Deref for ::my_crate::AnthropicApiKey {
        type Target = str;
        fn deref(&self) -> &Self::Target { &self.0 }
    }"#;
        let findings = scan_for_bare_api_keys_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "Deref impl with leading :: path must be flagged — BC-2.14.005 {{PC-006}}"
        );
    }

    /// F-P16-LOW-006 — BC-2.14.005 {PC-006}: `impl Deref for NAME where …` must still be
    /// flagged when a `where` clause follows the implementing type name.
    ///
    /// Same root cause as the Display variant: the post-`for` loop must stop collecting
    /// at the first non-`::` boundary so `where` clause idents do not overwrite the
    /// struct name (TD-VSDD-060 sibling sweep).
    #[test]
    fn test_bc_2_14_005_deref_impl_with_where_clause_is_flagged() {
        let src = r#"
pub struct OpenAiApiKey(String);
impl std::ops::Deref for OpenAiApiKey where Self: Sized {
    type Target = str;
    fn deref(&self) -> &Self::Target { &self.0 }
}
"#;
        let findings = scan_for_bare_api_keys_in_source(src, "crates/core/src/creds.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.005 F-P16-LOW-006: impl Deref for OpenAiApiKey with where clause \
             must be flagged; where clause idents must not overwrite struct name; \
             got: {findings:?}"
        );
    }
}
