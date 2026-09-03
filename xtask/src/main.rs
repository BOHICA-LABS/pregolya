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

/// Returns true when `path` identifies a test-only file.
///
/// Matches:
/// - Files named `tests.rs` (any directory depth, e.g. `src/tests.rs`)
/// - Files ending with `_test.rs` or `_tests.rs`
/// - Files under a `tests/` directory component (e.g. `crates/foo/tests/integration.rs`)
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
}

// ─────────────────────────────────────────────────────────────────────────────
// check-file-size
// ─────────────────────────────────────────────────────────────────────────────

fn check_file_size() {
    // NOTE: tokei counts ALL code-lines in a file (including #[cfg(test)] blocks
    // that are inline in production files).  The test-file thresholds (1000/1500)
    // apply only to files under `tests/` or ending with `_test.rs` / `_tests.rs`.
    // Inline test modules contribute to the production file's code count — this is
    // intentional: a production file whose inline tests push it over the
    // production hard gate (750 lines) should be split anyway.
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

    if let Some(rust) = json.get("Rust")
        && let Some(reports) = rust.get("reports").and_then(|r| r.as_array())
    {
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
                continue;
            }

            let is_test = is_test_file(name);
            let (soft, hard) = if is_test {
                (test_soft, test_hard)
            } else {
                (prod_soft, prod_hard)
            };

            if code > hard {
                violations.push(format!(
                    "HARD GATE FAIL: {name} has {code} code lines (limit: {hard})"
                ));
            } else if code > soft {
                warnings.push(format!(
                    "soft warning: {name} has {code} code lines (soft limit: {soft})"
                ));
            }
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

    println!("check-file-size PASSED ({} warnings).", warnings.len());
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

    let files_str = String::from_utf8_lossy(&files_output.stdout);
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
    println!("check-client-timeout PASSED.");
}

/// Returns true when `needle` appears in `line` at a word-boundary position —
/// i.e., NOT immediately preceded by an identifier character (`a-z`, `A-Z`,
/// `0-9`, `_`) or `:`.
///
/// Used to distinguish standalone `Client::new()` (reqwest import) from
/// compound names like `OpenAiClient::new()` or `mcp_sdk::Client::new()`.
fn needle_has_standalone_occurrence(line: &str, needle: &str) -> bool {
    let bytes = line.as_bytes();
    let needle_bytes = needle.as_bytes();
    let mut i = 0;
    while i + needle_bytes.len() <= bytes.len() {
        if bytes[i..i + needle_bytes.len()] == *needle_bytes {
            let before = if i > 0 { bytes[i - 1] } else { 0 };
            if !before.is_ascii_alphanumeric() && before != b'_' && before != b':' {
                return true;
            }
        }
        i += 1;
    }
    false
}

/// Returns true when `line` contains a `reqwest::Client::new()` violation.
///
/// Flags fully-qualified `reqwest::Client::new()` and unqualified `Client::new()`
/// (from `use reqwest::Client;` imports) while excluding compound names such as
/// `OpenAiClient::new()` and namespace-prefixed `mcp_sdk::Client::new()`.
fn is_reqwest_client_new_violation(line: &str) -> bool {
    line.contains("reqwest::Client::new()")
        || needle_has_standalone_occurrence(line, "Client::new()")
}

/// Returns true when `line` contains a `Client::builder()` call that is NOT
/// part of a compound type name (e.g., `OpenAiClient::builder()` is excluded).
fn contains_standalone_client_builder(line: &str) -> bool {
    line.contains("reqwest::Client::builder()")
        || needle_has_standalone_occurrence(line, "Client::builder()")
}

/// Scan `src` for `reqwest::Client::new()` and `Client::builder().build()`
/// patterns outside test files that lack a `.timeout()` call.
///
/// Returns a `Vec<String>` of `"path:line_num: trimmed_line"` findings.
/// Returns empty when `path` is a test file (per `is_test_file`).
///
/// This is the testable core extracted from `check_client_timeout`.
fn scan_for_timeout_violations_in_source(src: &str, path: &str) -> Vec<String> {
    if is_test_file(path) {
        return Vec::new();
    }

    let mut findings = Vec::new();
    // F-3: track multi-line Client::builder() chains.
    let mut in_builder_chain = false;
    let mut builder_chain_has_timeout = false;

    for (line_idx, line) in src.lines().enumerate() {
        let line_num = line_idx + 1;
        let trimmed = line.trim();
        // Skip comment lines.
        if trimmed.starts_with("//") {
            continue;
        }

        // Flag reqwest::Client::new() violations — both fully-qualified and
        // unqualified (from `use reqwest::Client;` imports).
        // F-2 fix: removed the redundant `!line.contains("//")` guard — the early
        // `continue` above already handles pure-comment lines, and the old guard
        // incorrectly suppressed lines whose URL strings contain `//`.
        // B-4 fix: also detect unqualified `Client::new()` that is NOT preceded by
        // a different namespace prefix (e.g., `mcp_sdk::Client::new()` is skipped).
        if is_reqwest_client_new_violation(line) {
            findings.push(format!("{}:{}: {}", path, line_num, trimmed));
        }

        // Builder-chain tracking (F-3 fix): detect Client::builder().build()
        // without an intervening .timeout(), even across multiple lines.
        // B-5 fix: use word-boundary check so SomethingClient::builder() is excluded.
        if contains_standalone_client_builder(line) {
            in_builder_chain = true;
            builder_chain_has_timeout = false;
        }
        if in_builder_chain {
            if line.contains(".timeout(") {
                builder_chain_has_timeout = true;
            }
            if line.contains(".build()") {
                if !builder_chain_has_timeout {
                    findings.push(format!("{}:{}: {}", path, line_num, trimmed));
                }
                in_builder_chain = false;
            } else if line.contains(';') && !line.contains(".build()") {
                // Statement ended without a .build() — reset chain tracking.
                // The conjunct `!(line.contains("Client::builder()") && line.contains(".build()"))`
                // was always true here: if .build() were present, the branch above would have
                // already closed the chain before this else-if is reached. Simplified to
                // just `!line.contains(".build()")` (S-4 fix).
                //
                // Covers two cases (S-1 fix):
                //   (a) `;` on a line that has nothing to do with Client::builder()
                //   (b) `Client::builder()` stored in a variable (`;` present, but
                //       `.build()` absent) — the stored builder's eventual .build()
                //       call cannot be tracked statically; reset to avoid arming the
                //       chain for unrelated .build() calls on subsequent lines.
                in_builder_chain = false;
                builder_chain_has_timeout = false;
            }
        }
    }
    findings
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

    let files_str = String::from_utf8_lossy(&files_output.stdout);
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
    println!("check-no-panic PASSED.");
}

/// Scan `src` for `.unwrap()` and `.expect(` patterns outside `#[cfg(test)]` blocks.
///
/// Returns a `Vec<String>` of `"path:line_num: trimmed_line"` findings.
/// Returns empty when `path` is a test file (per `is_test_file`).
///
/// ## Inline `#[cfg(test)]` block handling
///
/// Uses brace-depth tracking to identify test module boundaries.  Only INLINE
/// test blocks (with `{`) are suppressed — file-module declarations of the form
/// `#[cfg(test)] mod tests;` (semicolon-terminated, body in a separate file) do
/// NOT latch the scanner.  This prevents the gate-bypass where a production
/// `.unwrap()` immediately following such a declaration was incorrectly skipped.
fn scan_for_panics_in_source(src: &str, path: &str) -> Vec<String> {
    // Entire-file exclusion for known test file paths.
    if is_test_file(path) {
        return Vec::new();
    }

    let mut findings = Vec::new();
    let mut brace_depth: i32 = 0;
    let mut in_test_block = false;
    let mut test_block_target: i32 = -1; // depth at which the test block was entered
    let mut pending_cfg_test = false; // true after `#[cfg(test)]`; waiting for the opening `{`

    for (line_idx, line) in src.lines().enumerate() {
        let line_num = line_idx + 1;

        // Detect `#[cfg(test)]` — but only latch when this is NOT:
        //   (a) inside a `//` comment (`// #[cfg(test)]` must not latch), or
        //   (b) a semicolon-terminated file-module declaration (`#[cfg(test)] mod tests;`).
        //       A semicolon-terminated form means the module body lives in a separate file;
        //       there is no inline block to skip.
        // B-6 fix: use find() directly so we have the position for the comment
        // check without a separate `.unwrap()`.
        if let Some(cfg_pos) = line.find("#[cfg(test)]") {
            let is_commented = line[..cfg_pos].contains("//");
            if !is_commented {
                let trimmed_line = line.trim();
                // B-8 fix: any semicolon-terminated line (mod decl, use stmt,
                // const, type alias, etc.) has no following `{` block — never
                // latch.  The old `is_file_module_decl` check only tested for
                // `contains("mod ")`, so `#[cfg(test)] use …;` fell through and
                // incorrectly set `pending_cfg_test = true`.
                if !trimmed_line.ends_with(';') {
                    pending_cfg_test = true;
                }
            }
        }

        // Walk characters to track brace depth and test-block entry/exit.
        // Uses an index-based loop so escape sequences (`\\`, `\"`, `\'`) can
        // be skipped by advancing the index by 2, which correctly handles:
        //
        //   B-2a: `"C:\\"` — the double-backslash is one escape (`\\`); the
        //          subsequent `"` is the real string terminator, not an escaped
        //          quote.  The old `prev_char != '\\'` test misidentified it.
        //
        //   B-2b: `'{'` — a brace inside a char literal must not increment
        //          `brace_depth`; handled by the `in_char_literal` state.
        //
        //   B-2c: `'"'` — a double-quote inside a char literal must not toggle
        //          `in_string_literal`; also handled by `in_char_literal`.
        //
        // All state is per-line (declared inside this loop iteration).
        // Non-raw string literals cannot span lines; raw strings are unhandled
        // (workspace crates don't use spanning raw literals in production code).
        let mut in_string_literal = false;
        let mut in_char_literal = false;
        let chars: Vec<char> = line.chars().collect();
        let mut i = 0;
        while i < chars.len() {
            let ch = chars[i];

            if in_string_literal {
                if ch == '\\' {
                    i += 2; // skip the escaped character
                    continue;
                }
                if ch == '"' {
                    in_string_literal = false;
                }
                i += 1;
                continue;
            }

            if in_char_literal {
                if ch == '\\' {
                    i += 2; // skip the escaped character
                    continue;
                }
                if ch == '\'' {
                    in_char_literal = false;
                }
                i += 1;
                continue;
            }

            // Not inside any literal — stop at `//` line comments before
            // processing any structural characters. B-6 fix: braces inside a
            // `//` comment must not affect brace_depth.
            // B-7 fix: use chars.get() (char-index) not line.as_bytes().get()
            // (byte-index) so that non-ASCII chars before `//` don't corrupt
            // the lookahead — char index and byte index diverge for multi-byte
            // code points.
            if ch == '/' && !in_string_literal && !in_char_literal && chars.get(i + 1) == Some(&'/')
            {
                break; // rest of line is a comment
            }

            // Not inside any literal — track structural characters.
            match ch {
                '"' => {
                    in_string_literal = true;
                }
                '\'' => {
                    // Lookahead to distinguish a char literal from a lifetime annotation.
                    //
                    // Char literals have the form:
                    //   '\\' <escape_char> '   — e.g. '\n', '\\', '\''
                    //   '<single_char>'         — e.g. 'a', '{', '"'
                    //
                    // Lifetime annotations have the form:
                    //   '<ident_or_underscore>  — e.g. 'a, 'static, '_
                    // They have NO closing apostrophe on the same lexical unit.
                    //
                    // Rule: enter char-literal mode only when the closing `'` is
                    // visible at lookahead distance (i+2 for plain chars, i+3 for
                    // escape sequences). Otherwise treat as a lifetime and skip.
                    let next = chars.get(i + 1).copied();
                    let after_next = chars.get(i + 2).copied();
                    let is_char_lit = match next {
                        Some('\\') => true, // escape sequence: '\n', '\\', '\'' — enter mode
                        Some(_) => after_next == Some('\''), // plain char: closing ' is at i+2
                        None => false,
                    };
                    if is_char_lit {
                        in_char_literal = true;
                    }
                    // else: lifetime annotation ('a, 'static, '_) — do NOT enter char-literal mode
                }
                '{' => {
                    brace_depth += 1;
                    if pending_cfg_test {
                        in_test_block = true;
                        test_block_target = brace_depth;
                        pending_cfg_test = false;
                    }
                }
                '}' => {
                    if in_test_block && brace_depth == test_block_target {
                        in_test_block = false;
                        test_block_target = -1;
                    }
                    brace_depth -= 1;
                }
                _ => {}
            }
            i += 1;
        }

        // Skip lines inside test blocks and comment lines.
        if in_test_block {
            continue;
        }
        let trimmed = line.trim();
        if trimmed.starts_with("//") {
            continue;
        }

        // Flag panic-potential patterns.
        // F-2 fix: removed redundant `!line.contains("//")` guard — the early
        // `continue` above already handles pure-comment lines, and the old guard
        // incorrectly suppressed lines with `//` inside URL string literals.
        let has_unwrap = line.contains(".unwrap()");
        let has_expect = line.contains(".expect(");
        if has_unwrap || has_expect {
            findings.push(format!("{}:{}: {}", path, line_num, trimmed));
        }
    }

    findings
}

// ─────────────────────────────────────────────────────────────────────────────
// deny-anyhow-in-lib (NE-03 / DI-014 / ADR-010)
// ─────────────────────────────────────────────────────────────────────────────

fn deny_anyhow_in_lib() {
    let output = Command::new("grep")
        .args(["-rn", "--include=*.rs", "use anyhow", "crates/"])
        .output();

    match output {
        Ok(o) => {
            let stdout = String::from_utf8_lossy(&o.stdout);
            if !stdout.trim().is_empty() {
                eprintln!(
                    "ERROR: anyhow is banned from pregolya-* library crates (ADR-010 / NE-03):"
                );
                for line in stdout.lines() {
                    eprintln!("  {line}");
                }
                exit(1);
            }
        }
        Err(e) => {
            eprintln!("grep failed: {e}");
            exit(1);
        }
    }
    println!("deny-anyhow-in-lib PASSED.");
}

// ─────────────────────────────────────────────────────────────────────────────
// deny-description-cache-key (NE-05 / ADR-011)
// ─────────────────────────────────────────────────────────────────────────────

fn deny_description_cache_key() {
    for pattern in &["cache_key", "CacheKey", "cache_key_for"] {
        let output = Command::new("grep")
            .args(["-rn", "--include=*.rs", pattern, "crates/"])
            .output();

        match output {
            Ok(o) => {
                let stdout = String::from_utf8_lossy(&o.stdout);
                // Only flag if it looks like description-proxy usage
                let findings: Vec<&str> = stdout
                    .lines()
                    .filter(|l| l.contains("description") || l.contains("Description"))
                    .collect();
                if !findings.is_empty() {
                    for f in &findings {
                        eprintln!(
                            "ERROR: description-proxy cache-key usage (ADR-011 / NE-05): {f}"
                        );
                    }
                    exit(1);
                }
            }
            Err(e) => {
                eprintln!("grep failed: {e}");
                exit(1);
            }
        }
    }
    println!("deny-description-cache-key PASSED.");
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
    fn is_allowed(&self, path: &str) -> bool {
        // Use ends_with only — contains() would match substrings (e.g.,
        // "pregolya-core" matching "pregolya-core-extra"), causing false negatives.
        self.allow.iter().any(|e| path.ends_with(&e.path))
    }
}

fn load_allowlist() -> AllowList {
    let path = "xtask/file-size-allowlist.toml";
    match std::fs::read_to_string(path) {
        Ok(content) => toml::from_str(&content).unwrap_or_default(),
        Err(_) => AllowList::default(),
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unit tests (file-module form — body lives in tests.rs)
// ─────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests;
