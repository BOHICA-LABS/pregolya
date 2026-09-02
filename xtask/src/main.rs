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
            eprintln!("ERROR: reqwest Client::new() without timeout: {f}");
        }
        eprintln!("Use Client::builder().timeout(Duration::from_secs(30)).build() instead.");
        exit(1);
    }
    println!("check-client-timeout PASSED.");
}

/// Scan `src` for `reqwest::Client::new()` patterns outside test files.
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
    for (line_idx, line) in src.lines().enumerate() {
        let line_num = line_idx + 1;
        let trimmed = line.trim();
        // Skip comment lines.
        if trimmed.starts_with("//") {
            continue;
        }
        // Flag Client::new() that isn't already commented out.
        if line.contains("Client::new()") && !line.contains("//") {
            findings.push(format!("{}:{}: {}", path, line_num, trimmed));
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

        // Detect `#[cfg(test)]` — but only latch when this is NOT a semicolon-terminated
        // file-module declaration (`#[cfg(test)] mod tests;`).  A semicolon-terminated form
        // means the module body lives in a separate file; there is no inline block to skip.
        if line.contains("#[cfg(test)]") {
            let trimmed_line = line.trim();
            let is_file_module_decl = trimmed_line.contains("mod ") && trimmed_line.ends_with(';');
            if !is_file_module_decl {
                pending_cfg_test = true;
            }
        }

        // Walk characters to track brace depth and test-block entry/exit.
        for ch in line.chars() {
            match ch {
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
        let has_unwrap = line.contains(".unwrap()");
        let has_expect = line.contains(".expect(");
        if (has_unwrap || has_expect) && !line.contains("//") {
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
// Unit tests
// ─────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    // ── check-no-panic gate ──────────────────────────────────────────────────

    /// Gate-bypass regression: production `.unwrap()` that follows a
    /// `#[cfg(test)] mod tests;` FILE-MODULE declaration must NOT be skipped.
    ///
    /// Before the M-1 fix the semicolon-terminated declaration latched
    /// `pending_cfg_test = true`; the next `{` (the production function's opening
    /// brace) then activated `in_test_block`, suppressing the finding.
    #[test]
    fn test_no_panic_finds_unwrap_after_cfg_test_mod_decl() {
        let src = r#"
#[cfg(test)] mod tests;

pub fn production_fn() -> i32 {
    let x: Option<i32> = Some(1);
    x.unwrap()
}
"#;
        let findings = scan_for_panics_in_source(src, "src/lib.rs");
        assert!(
            !findings.is_empty(),
            "should detect unwrap in production code after cfg(test) mod decl; got: {findings:?}"
        );
    }

    /// Correctly suppressed: `.unwrap()` inside an inline `#[cfg(test)]` block
    /// must NOT be reported.
    #[test]
    fn test_no_panic_ignores_unwrap_in_cfg_test_block() {
        let src = r#"
#[cfg(test)]
mod tests {
    #[test]
    fn my_test() {
        let x: Option<i32> = Some(1);
        assert_eq!(x.unwrap(), 1);
    }
}
"#;
        let findings = scan_for_panics_in_source(src, "src/lib.rs");
        assert!(
            findings.is_empty(),
            "should NOT flag unwrap inside #[cfg(test)] block; got: {findings:?}"
        );
    }

    /// Correctly suppressed: entire file is a test file (path ends with `tests.rs`).
    #[test]
    fn test_no_panic_ignores_tests_rs_file() {
        let src = r#"
pub fn test_helper() -> i32 {
    let x: Option<i32> = Some(1);
    x.unwrap()
}
"#;
        let findings = scan_for_panics_in_source(src, "src/tests.rs");
        assert!(
            findings.is_empty(),
            "should NOT flag src/tests.rs; got: {findings:?}"
        );
    }

    /// Production code after an inline cfg(test) block (which DOES have braces)
    /// must still be scanned after the block closes.
    #[test]
    fn test_no_panic_finds_unwrap_after_cfg_test_block_closes() {
        let src = r#"
#[cfg(test)]
mod tests {
    fn helper() {
        let _x: Option<i32> = Some(1);
    }
}

pub fn production_fn() -> i32 {
    let x: Option<i32> = Some(1);
    x.unwrap()
}
"#;
        let findings = scan_for_panics_in_source(src, "src/lib.rs");
        assert!(
            !findings.is_empty(),
            "should detect unwrap in production code after cfg(test) block closes; got: {findings:?}"
        );
    }

    // ── check-client-timeout gate ────────────────────────────────────────────

    /// M-3 regression: a crate whose PATH contains "test" (e.g. pregolya-standard-tests)
    /// must NOT be suppressed by the timeout scanner.
    #[test]
    fn test_timeout_scanner_does_not_suppress_standard_tests_crate() {
        let src = "let client = reqwest::Client::new();\n";
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-standard-tests/src/lib.rs");
        assert!(
            !findings.is_empty(),
            "should detect missing timeout in standard-tests crate; got: {findings:?}"
        );
    }

    /// Actual test files (path ends with `tests.rs`) must be suppressed.
    #[test]
    fn test_timeout_scanner_suppresses_actual_test_file() {
        let src = "let client = reqwest::Client::new();\n";
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/tests.rs");
        assert!(
            findings.is_empty(),
            "should suppress actual test files; got: {findings:?}"
        );
    }

    /// Files under a `tests/` directory component must be suppressed.
    #[test]
    fn test_timeout_scanner_suppresses_tests_dir_file() {
        let src = "let client = reqwest::Client::new();\n";
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/tests/integration.rs");
        assert!(
            findings.is_empty(),
            "should suppress files under tests/ directory; got: {findings:?}"
        );
    }

    // ── is_test_file helper ──────────────────────────────────────────────────

    #[test]
    fn test_is_test_file_patterns() {
        assert!(is_test_file("src/tests.rs"));
        assert!(is_test_file("crates/foo/src/tests.rs"));
        assert!(is_test_file("crates/foo/tests/integration.rs"));
        assert!(is_test_file("src/foo_test.rs"));
        assert!(is_test_file("src/foo_tests.rs"));

        // Must NOT flag production files in crates with "test" in the crate name.
        assert!(!is_test_file("crates/pregolya-standard-tests/src/lib.rs"));
        assert!(!is_test_file("crates/pregolya-standard-tests/src/main.rs"));
        // Must NOT flag arbitrary files that happen to have "test" in a directory name
        // other than a `tests/` component.
        assert!(!is_test_file("crates/pregolya-core/src/latest.rs"));
    }
}
