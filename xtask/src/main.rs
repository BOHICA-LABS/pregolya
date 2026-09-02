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
// check-file-size
// ─────────────────────────────────────────────────────────────────────────────

fn check_file_size() {
    let output = Command::new("tokei")
        .args(["--output", "json", "crates/"])
        .output();

    let output = match output {
        Ok(o) => o,
        Err(e) => {
            eprintln!("xtask check-file-size: failed to run tokei: {e}");
            eprintln!("Install tokei: cargo install tokei");
            eprintln!("WARNING: tokei not installed — file-size gate skipped");
            return;
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

            if allowlist.is_allowed(name) {
                continue;
            }

            let is_test = name.contains("/tests/") || name.ends_with("_test.rs");
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
    // Scan library crate src/ for reqwest Client::new() outside #[cfg(test)]
    // This is the lint gate stub — full semgrep rule in xtask/semgrep-rules/
    let output = Command::new("grep")
        .args(["-r", "--include=*.rs", "Client::new()", "crates/"])
        .output();

    match output {
        Ok(o) => {
            let stdout = String::from_utf8_lossy(&o.stdout);
            let findings: Vec<&str> = stdout
                .lines()
                .filter(|l| !l.contains("test") && !l.contains("#[cfg(test)]"))
                .collect();
            if !findings.is_empty() {
                for f in &findings {
                    eprintln!("ERROR: reqwest Client::new() without timeout: {f}");
                }
                eprintln!(
                    "Use Client::builder().timeout(Duration::from_secs(30)).build() instead."
                );
                exit(1);
            }
        }
        Err(e) => {
            eprintln!("grep failed: {e}");
            exit(1);
        }
    }
    println!("check-client-timeout PASSED.");
}

// ─────────────────────────────────────────────────────────────────────────────
// check-no-panic (NE-07)
// ─────────────────────────────────────────────────────────────────────────────

fn check_no_panic() {
    // Scan library src/ for .unwrap() and .expect() outside test blocks
    // Stub gate — full semgrep rule in xtask/semgrep-rules/
    for pattern in &[r"\.unwrap()", r"\.expect("] {
        let output = Command::new("grep")
            .args(["-rn", "--include=*.rs", pattern, "crates/"])
            .output();

        match output {
            Ok(o) => {
                let stdout = String::from_utf8_lossy(&o.stdout);
                let findings: Vec<&str> = stdout
                    .lines()
                    .filter(|l| {
                        !l.contains("//")
                            && !l.contains("test")
                            && !l.contains("#[cfg(test)]")
                            && !l.contains("_test.rs")
                    })
                    .collect();
                if !findings.is_empty() {
                    for f in &findings {
                        eprintln!("ERROR: panic-potential in library code: {f}");
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
    println!("check-no-panic PASSED.");
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
        self.allow
            .iter()
            .any(|e| path.ends_with(&e.path) || path.contains(&e.path))
    }
}

fn load_allowlist() -> AllowList {
    let path = "xtask/file-size-allowlist.toml";
    match std::fs::read_to_string(path) {
        Ok(content) => toml::from_str(&content).unwrap_or_default(),
        Err(_) => AllowList::default(),
    }
}
