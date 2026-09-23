//! cargo xtask — workspace task runner for pregolya.
//!
//! Usage: `cargo xtask <subcommand>`
//!
//! Subcommands:
//!   check-file-size           Enforce production file size gates (CLAUDE.md §File size & module splitting)
//!   check-client-timeout      CI lint gate: reject reqwest Client::new() outside tests (BC-2.14.004)
//!   check-no-panic [--fixture-mode `<dir>`]
//!                             CI lint gate: reject unwrap/expect/bare-assert/panic!/wildcard-unreachable in non-test library code (BC-2.14.003 §EC-007)
//!   check-error-code-registry CI lint gate: verify all `E-<COMPONENT>-<NNN>` codes in error-taxonomy.md are unique and at least one code was extracted (BC-2.14.001 EC-004, VP-BC214001-01)
//!   deny-bare-api-key         CI lint gate: reject credential-sentinel-named public structs that derive Debug/Serialize/Deserialize, impl Display, or impl `Deref<Target=str/String>` (BC-2.14.005 {PC-006})
//!   deny-anyhow-in-lib        CI lint gate: reject anyhow imports in library crates
//!   deny-description-cache-key  CI lint gate: reject description-proxy cache-key usage

mod check_client_timeout;
mod check_error_code_registry;
mod check_no_panic;
mod deny_bare_api_key;

// Re-export scanner helpers so xtask unit tests (src/tests.rs) can call them
// without module-path qualification. Scanners are implemented (S-1.02 GREEN);
// this re-export provides module-path-free access in unit tests.
#[cfg(test)]
pub(crate) use check_client_timeout::scan_for_timeout_violations_in_source;
#[cfg(test)]
pub(crate) use check_no_panic::scan_for_panics_in_source;
#[cfg(test)]
pub(crate) use deny_bare_api_key::scan_for_bare_api_keys_in_source;

use std::process::{Command, exit};

/// Returns `Ok(())` when `files_analyzed > 0`, or `Err(message)` when all files were
/// exempted and the gate certified nothing (post-exemption vacuity, F-P9-M04).
///
/// Callers should print the error and call `exit(1)` when `Err` is returned.
/// Extracted as a testable helper so the vacuity condition can be verified by
/// unit tests without invoking `process::exit`.
pub(crate) fn check_post_exemption_vacuity(
    gate_name: &str,
    files_analyzed: usize,
) -> Result<(), String> {
    if files_analyzed == 0 {
        Err(format!(
            "ERROR: {gate_name} analyzed 0 non-exempt files — \
             post-exemption vacuity; gate cannot certify anything"
        ))
    } else {
        Ok(())
    }
}

/// Collect all Rust source files under `root_path`, excluding `target/` directories.
///
/// Returns `(files_found, unreadable_count)` where `unreadable_count` is the number
/// of directory entries that WalkDir could not access (permission error, broken symlink,
/// etc.). The caller should add `unreadable_count` to its `files_unreadable` counter
/// and fail-closed when it is non-zero.
///
/// This replaces POSIX `find crates/ -name "*.rs" -not -path "*/target/*"` across five
/// of the seven xtask lint gates (six call sites — `check-no-panic` invokes it for both
/// the normal scan and the `--fixture-mode` path), providing cross-platform portability
/// (Windows does not have `find`).
pub(crate) fn collect_rust_files(root_path: &str) -> (Vec<std::path::PathBuf>, usize) {
    use walkdir::WalkDir;
    let mut files = Vec::new();
    let mut unreadable = 0usize;
    for entry in WalkDir::new(root_path)
        .follow_links(false)
        .into_iter()
        .filter_entry(|e| {
            // Skip `target/` directories to avoid scanning build artifacts.
            e.file_name() != "target"
        })
    {
        match entry {
            Ok(e) if e.file_type().is_file() => {
                if e.path().extension().is_some_and(|x| x == "rs") {
                    files.push(e.path().to_path_buf());
                }
            }
            Ok(_) => {}
            Err(_) => unreadable += 1,
        }
    }
    (files, unreadable)
}

/// Pure verdict for extra-argument detection. Returns `Err(message)` when `args[2]`
/// is present (unrecognised argument), or `Ok(())` when no extra argument is present.
///
/// Extracted from `reject_extra_args` for testability — the `process::exit(1)`
/// side-effect lives in `reject_extra_args` (F-P10-L01 fix).
pub(crate) fn extra_args_verdict(subcommand: &str, args: &[String]) -> Result<(), String> {
    if let Some(extra) = args.get(2) {
        Err(format!(
            "unrecognised argument '{extra}' for {subcommand}\nusage: cargo xtask {subcommand}"
        ))
    } else {
        Ok(())
    }
}

/// Reject any extra arguments passed to a subcommand that accepts no arguments.
///
/// Prints an error message and exits with code 1 when `args[2]` is present.
/// Called at the start of each simple (no-argument) subcommand branch so that
/// mistyped invocations like `cargo xtask check-file-size --fixup` fail loudly
/// instead of silently ignoring the unknown flag (F-P9-L01 fix).
///
/// NOT called for `check-no-panic`, which has its own `--fixture-mode <dir>` handling.
fn reject_extra_args(subcommand: &str, args: &[String]) {
    if let Err(msg) = extra_args_verdict(subcommand, args) {
        eprintln!("error: {msg}");
        std::process::exit(1);
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let subcommand = args.get(1).map(String::as_str).unwrap_or("");
    match subcommand {
        "check-file-size" => {
            reject_extra_args("check-file-size", &args);
            check_file_size();
        }
        "check-client-timeout" => {
            reject_extra_args("check-client-timeout", &args);
            check_client_timeout::run();
        }
        "check-no-panic" => {
            if args.get(2).map(String::as_str) == Some("--fixture-mode") {
                let dir = match args.get(3).map(String::as_str) {
                    Some(d) => d,
                    None => {
                        eprintln!("error: --fixture-mode requires a <dir> argument");
                        eprintln!("usage: cargo xtask check-no-panic [--fixture-mode <dir>]");
                        std::process::exit(1);
                    }
                };
                check_no_panic::run_fixture_mode(dir);
            } else if let Some(flag) = args.get(2) {
                // Unrecognised second argument — fail loudly rather than silently
                // falling through to `check_no_panic::run()` (F-P8-L03 fix).
                eprintln!("error: unrecognised argument '{}' for check-no-panic", flag);
                eprintln!("usage: cargo xtask check-no-panic [--fixture-mode <dir>]");
                std::process::exit(1);
            } else {
                check_no_panic::run();
            }
        }
        "check-error-code-registry" => {
            reject_extra_args("check-error-code-registry", &args);
            check_error_code_registry::run();
        }
        "deny-bare-api-key" => {
            reject_extra_args("deny-bare-api-key", &args);
            deny_bare_api_key::run();
        }
        "deny-anyhow-in-lib" => {
            reject_extra_args("deny-anyhow-in-lib", &args);
            deny_anyhow_in_lib();
        }
        "deny-description-cache-key" => {
            reject_extra_args("deny-description-cache-key", &args);
            deny_description_cache_key();
        }
        _ => {
            eprintln!("Usage: cargo xtask <subcommand>");
            eprintln!("Subcommands:");
            eprintln!(
                "  check-file-size           File size gate (prod 500/750, test 1000/1500 code-lines)"
            );
            eprintln!(
                "  check-client-timeout      Lint: reqwest Client::new() outside tests is forbidden (BC-2.14.004)"
            );
            eprintln!(
                "  check-no-panic            Lint: no-panic gate: unwrap/expect/bare-assert/panic!/wildcard-unreachable in non-test library code (BC-2.14.003 §EC-007)"
            );
            eprintln!(
                "  check-error-code-registry Lint: error-code-registry uniqueness: verify all E-<COMPONENT>-<NNN> codes in error-taxonomy.md are unique and at least one code was extracted (BC-2.14.001 EC-004, VP-BC214001-01)"
            );
            eprintln!(
                "  deny-bare-api-key         Lint: reject credential-sentinel-named public structs that derive Debug/Serialize/Deserialize, impl Display, or impl Deref<Target=str/String> (BC-2.14.005 {{PC-006}})"
            );
            eprintln!(
                "  deny-anyhow-in-lib        Lint: anyhow usage (imports or qualified anyhow:: in production code)"
            );
            eprintln!("  deny-description-cache-key Lint: description-proxy cache-key usage");
            exit(1);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns true when `path` identifies a non-production test file.
///
/// Matches:
/// - Files named `tests.rs` (any directory depth, e.g. `src/tests.rs`)
/// - Files ending with `_test.rs` or `_tests.rs`
/// - Files under a `tests/` directory component (e.g. `crates/foo/tests/integration.rs`)
///
/// Does NOT exempt `examples/` or `benches/` — those are not enumerated in
/// BC-2.14.003 {INV-004} as exempt from the no-panic lint gate.
///
/// Does NOT use `.contains("test")` substring matching, which would
/// incorrectly suppress production files in crates whose names contain
/// "test" (e.g. `pregolya-standard-tests`).
///
/// Intentionally duplicated from `is_test_class_file` — predicate bodies are identical.
/// The functions are separate because they gate different subsystems (`BC-2.14.003 {INV-004}`
/// lint perimeter vs. file-size test-class threshold) that are expected to diverge when
/// `examples/`/`benches/` exemption policy splits between the two subsystems.
fn is_test_file(path: &str) -> bool {
    let path = path.replace('\\', "/");
    path.ends_with("/tests.rs")
        || path == "tests.rs"
        || path.contains("/tests/")
        || path.ends_with("_test.rs")
        || path.ends_with("_tests.rs")
}

/// Returns true for files exempt from lint scanners (test files only).
///
/// BC-2.14.003 {INV-004} enumerates only test files as exempt. `examples/` and
/// `benches/` are NOT exempt — they are not listed in the BC and no crate currently
/// contains them, so the exclusion was unsanctioned.
///
/// Used by: `check_no_panic`, `check_client_timeout`, `deny_anyhow_in_lib`,
/// `deny_bare_api_key`, `deny_description_cache_key`.
fn is_lint_exempt_file(path: &str) -> bool {
    is_test_file(path)
}

/// Returns true for files that qualify for TEST file-size thresholds (1000/1500 code-lines).
///
/// Only actual test files — NOT examples (demonstration programs use production thresholds)
/// and NOT benchmarks (which are tuning tools, not test suites).
///
/// Used by: `check_file_size`.
///
/// Intentionally duplicated from `is_test_file` — predicate bodies are identical.
/// See `is_test_file` doc for the divergence rationale.
fn is_test_class_file(path: &str) -> bool {
    let path = path.replace('\\', "/");
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
/// A warning is printed to stderr if the file cannot be read or parsed, so the
/// caller knows the returned count of 0 is unadjusted (not a genuine zero).
///
/// The subtraction of this count from tokei's `Code` metric gives the adjusted
/// production code line count per CLAUDE.md §File size: "#[cfg(test)] mod blocks
/// excluded from the count." The count includes the attribute line itself
/// (`#[cfg(test)]`) through the closing `}` of the mod block.
fn count_cfg_test_lines(path: &std::path::Path) -> usize {
    use proc_macro2::TokenStream;

    let Ok(source) = std::fs::read_to_string(path) else {
        eprintln!(
            "WARN: cfg(test) adjustment skipped for {} (read error) — reported count is unadjusted",
            path.display()
        );
        return 0;
    };
    let Ok(ts) = source.parse::<TokenStream>() else {
        eprintln!(
            "WARN: cfg(test) adjustment skipped for {} (parse error) — reported count is unadjusted",
            path.display()
        );
        return 0;
    };

    let lines: Vec<&str> = source.lines().collect();
    count_cfg_test_in_stream(ts.into_iter(), &lines)
}

/// Recursive helper for [`count_cfg_test_lines`].
///
/// Walks `iter` looking for `#[cfg(test)] mod ... { ... }` patterns and counting
/// their code lines. Also recurses into non-cfg-test mod blocks to find nested
/// cfg(test) blocks. The `lines` slice spans the entire source file so that
/// `proc_macro2` span line numbers (which are file-relative) map correctly.
fn count_cfg_test_in_stream(iter: proc_macro2::token_stream::IntoIter, lines: &[&str]) -> usize {
    use proc_macro2::{Delimiter, TokenTree};

    let tokens: Vec<TokenTree> = iter.collect();
    let mut total = 0usize;
    let mut i = 0;
    while i < tokens.len() {
        // Look for `#` followed by `[cfg(test)]` bracket group.
        // FIX-B: use is_cfg_test_group() instead of contains("cfg") && contains("test")
        // to prevent false matches on #[cfg(not(test))] and #[cfg(feature = "test-utils")].
        if let TokenTree::Punct(p) = &tokens[i]
            && p.as_char() == '#'
            && let Some(TokenTree::Group(attr_group)) = tokens.get(i + 1)
            && attr_group.delimiter() == Delimiter::Bracket
            && is_cfg_test_group(attr_group)
        {
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
            // tokens[j] = "mod", tokens[j+1] = mod name ident, tokens[j+2] = body Group
            if let Some(TokenTree::Ident(mod_kw)) = tokens.get(j)
                && mod_kw == "mod"
                && let Some(TokenTree::Group(mod_group)) = tokens.get(j + 2)
                && mod_group.delimiter() == Delimiter::Brace
            {
                // FIX-K: start counting from the `#` attribute line (tokens[i]) so that
                // the `#[cfg(test)]` line itself is included in the subtraction budget.
                let attr_start_line = tokens[i].span().start().line; // 1-based
                let end_line = mod_group.span().end().line; // 1-based
                // Count non-blank, non-comment-only lines
                // in [attr_start_line, end_line] (inclusive, 1-based).
                for line in lines[(attr_start_line - 1)..end_line.min(lines.len())].iter() {
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

        // FIX-K: Recurse into non-cfg(test) mod blocks looking for nested cfg(test) blocks.
        // A bare `mod <ident> { ... }` (without preceding #[cfg(test)]) may contain
        // nested cfg(test) blocks that also contribute to the adjustment budget.
        if let TokenTree::Ident(kw) = &tokens[i]
            && kw == "mod"
            && let Some(TokenTree::Group(mod_group)) = tokens.get(i + 2)
            && mod_group.delimiter() == Delimiter::Brace
        {
            total += count_cfg_test_in_stream(mod_group.stream().into_iter(), lines);
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
        // Normalize to forward slashes for cross-platform consistency (F-P40-MED-002):
        // tokei emits backslash-separated paths on Windows, so POSIX-only predicates
        // like "/target/" and "/tests/fixtures/" would silently miss exclusions without
        // this normalization. Pattern identical to AllowList::is_allowed and is_test_class_file.
        let name_n = name.replace('\\', "/");
        if name_n.contains("/target/")
            || name_n.contains("OUT_DIR")
            || name_n.ends_with(".gen.rs")
            || name_n.contains("/tests/fixtures/")
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

    if let Err(msg) = check_post_exemption_vacuity("check-file-size", files_measured) {
        eprintln!("{msg}");
        exit(1);
    }
    println!(
        "check-file-size PASSED ({} warnings, {files_measured} files measured, {files_skipped} allowlisted).",
        warnings.len()
    );
}

/// Returns true when `tokens[idx]` and `tokens[idx+1]` are both `:` puncts.
fn is_double_colon(tokens: &[proc_macro2::TokenTree], idx: usize) -> bool {
    use proc_macro2::TokenTree;
    matches!(tokens.get(idx), Some(TokenTree::Punct(p)) if p.as_char() == ':')
        && matches!(tokens.get(idx + 1), Some(TokenTree::Punct(p)) if p.as_char() == ':')
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
    let (rust_files, disc_unreadable) = collect_rust_files("crates/");
    if rust_files.is_empty() {
        eprintln!("ERROR: deny-anyhow-in-lib scanned 0 files — gate cannot certify anything");
        exit(1);
    }

    let mut all_findings: Vec<String> = Vec::new();
    let mut files_analyzed = 0usize;
    let mut files_exempt = 0usize;
    let mut files_unreadable = disc_unreadable;

    for path_buf in &rust_files {
        let file_path = path_buf.to_string_lossy();
        let file_path = file_path.as_ref();
        if is_lint_exempt_file(file_path) {
            files_exempt += 1;
            continue;
        }
        let content = match std::fs::read_to_string(path_buf) {
            Ok(c) => c,
            Err(_) => {
                files_unreadable += 1;
                continue;
            }
        };
        files_analyzed += 1;
        let findings = scan_for_anyhow_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if files_unreadable > 0 {
        eprintln!(
            "ERROR: deny-anyhow-in-lib could not read {files_unreadable} file(s) — gate cannot certify anything"
        );
        exit(1);
    }
    if let Err(msg) = check_post_exemption_vacuity("deny-anyhow-in-lib", files_analyzed) {
        eprintln!("{msg}");
        exit(1);
    }
    if !all_findings.is_empty() {
        eprintln!("ERROR: anyhow is banned from pregolya-* library crates (ADR-010 / NE-03):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!(
        "deny-anyhow-in-lib PASSED: {files_analyzed} analyzed, {files_exempt} exempt, 0 unreadable, 0 violations."
    );
}

/// Scan `src` for `use anyhow` patterns outside `#[cfg(test)]` scopes.
///
/// Uses proc_macro2 token-tree walking so that anyhow imports in test code
/// (which are legitimate for compatibility verification) are not flagged.
///
/// Returns a `Vec<String>` of `"path:line: use anyhow"` findings.
/// Returns empty when `path` is a test file (per `is_lint_exempt_file`).
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
            // Detect `anyhow` ident followed by `::` outside test scope.
            // Catches both `use anyhow::Foo` and `fn f() -> anyhow::Result<()>`
            // patterns (ADR-010 boundary violation). Using the bare-ident arm
            // instead of a `use`-keyword scan catches qualified usages like
            // return types and function signatures that do not start with `use`.
            TokenTree::Ident(id) if id == "anyhow" && *in_test_depth == 0 => {
                if is_double_colon(&tokens, i + 1) {
                    let line = id.span().start().line;
                    findings.push(format!(
                        "{}:{}: anyhow:: in non-test code (ADR-010 boundary violation)",
                        path, line
                    ));
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
    let (rust_files, disc_unreadable) = collect_rust_files("crates/");
    if rust_files.is_empty() {
        eprintln!(
            "ERROR: deny-description-cache-key scanned 0 files — gate cannot certify anything"
        );
        exit(1);
    }

    let mut all_findings: Vec<String> = Vec::new();
    let mut files_analyzed = 0usize;
    let mut files_exempt = 0usize;
    let mut files_unreadable = disc_unreadable;

    for path_buf in &rust_files {
        let file_path = path_buf.to_string_lossy();
        let file_path = file_path.as_ref();
        if is_lint_exempt_file(file_path) {
            files_exempt += 1;
            continue;
        }
        let content = match std::fs::read_to_string(path_buf) {
            Ok(c) => c,
            Err(_) => {
                files_unreadable += 1;
                continue;
            }
        };
        files_analyzed += 1;
        // FIX-E: use proc_macro2-based scanner to avoid false positives on doc comments
        // (e.g. `/// Gets the cache_key for the description` previously triggered the
        // old line-contains scan; proc_macro2 lowers `///` doc comments to #[doc = "..."]
        // attributes whose payload is a string literal — collect_idents walks Ident tokens
        // only, so doc text cannot match. Plain `//` comments are discarded by the lexer).
        let findings = scan_for_description_cache_key_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if files_unreadable > 0 {
        eprintln!(
            "ERROR: deny-description-cache-key could not read {files_unreadable} file(s) — gate cannot certify anything"
        );
        exit(1);
    }
    if let Err(msg) = check_post_exemption_vacuity("deny-description-cache-key", files_analyzed) {
        eprintln!("{msg}");
        exit(1);
    }
    if !all_findings.is_empty() {
        eprintln!("ERROR: description-proxy cache-key usage (ADR-011 / NE-05):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!(
        "deny-description-cache-key PASSED: {files_analyzed} analyzed, {files_exempt} exempt, 0 unreadable, 0 violations."
    );
}

/// Collect all `Ident` tokens from a token stream into a flat `(name, line)` list.
///
/// Recurses into all groups (brace, paren, bracket) so that idents inside
/// function bodies, attribute arguments, and macro invocations are all captured.
/// Used by `scan_for_description_cache_key_in_source`.
fn collect_idents(ts: proc_macro2::TokenStream) -> Vec<(String, usize)> {
    use proc_macro2::TokenTree;
    let mut out = Vec::new();
    for tt in ts {
        match tt {
            TokenTree::Ident(id) => {
                out.push((id.to_string(), id.span().start().line));
            }
            TokenTree::Group(g) => {
                out.extend(collect_idents(g.stream()));
            }
            _ => {}
        }
    }
    out
}

/// Scan `src` for description-proxy cache-key usage using proc_macro2 token-tree walking.
///
/// Looks for a `cache_key`, `CacheKey`, or `cache_key_for` ident within a window of
/// tokens before/after a `description` or `Description` ident. This is more precise
/// than line-by-line string matching because proc_macro2 lowers `///` doc comments to
/// `#[doc = "…"]` attributes whose payload is a string literal; `collect_idents` walks
/// `Ident` tokens only, so doc text cannot match. Plain `//` comments are discarded by
/// the lexer, so they cannot produce false positives either.
///
/// The adjacency window is set to 10 tokens on each side of the cache-key ident.
///
/// Returns empty when `path` is a test file (per `is_lint_exempt_file`).
fn scan_for_description_cache_key_in_source(src: &str, path: &str) -> Vec<String> {
    if is_lint_exempt_file(path) {
        return Vec::new();
    }

    use proc_macro2::TokenStream;
    let ts: TokenStream = match src.parse() {
        Ok(s) => s,
        Err(e) => return vec![format!("{}:0: FAILED TO LEX FILE: {}", path, e)],
    };

    let idents = collect_idents(ts);
    const WINDOW: usize = 10;
    let cache_key_names: &[&str] = &["cache_key", "CacheKey", "cache_key_for"];
    let description_names: &[&str] = &["description", "Description"];

    let mut findings = Vec::new();
    for (i, (name, line)) in idents.iter().enumerate() {
        if !cache_key_names.contains(&name.as_str()) {
            continue;
        }
        // Check the surrounding window for a description ident.
        let start = i.saturating_sub(WINDOW);
        let end = (i + WINDOW + 1).min(idents.len());
        let has_description = idents[start..end]
            .iter()
            .any(|(n, _)| description_names.contains(&n.as_str()));
        if has_description {
            findings.push(format!(
                "{}:{}: cache_key ident adjacent to description ident (ADR-011 / NE-05)",
                path, line
            ));
        }
    }
    findings
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
    let path = path.replace('\\', "/");
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
