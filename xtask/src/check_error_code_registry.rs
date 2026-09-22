//! CI lint gate: error-code-registry uniqueness check (BC-2.14.001 EC-007, VP-BC214001-01).
//!
//! Parses `.factory/specs/prd-supplements/error-taxonomy.md` and verifies:
//! 1. Every `E-<COMPONENT>-<NNN>` code appears exactly once (no collision).
//!
//! ## Exit semantics
//! - Exit 0: gate passed — N codes validated, 0 collisions.
//! - Exit 1: gate failed — M collision(s) found or taxonomy file unreadable.
//!
//! ## Taxonomy file location
//! Resolved in order:
//! 1. `FACTORY_DIR` env var (set by CI via the factory-artifacts checkout step).
//! 2. `.factory/` relative to the current working directory.
//! 3. `../../.factory/` relative to the current working directory (worktree layout).

use std::collections::HashMap;
use std::path::PathBuf;

fn taxonomy_path() -> PathBuf {
    taxonomy_path_with_factory_dir(std::env::var("FACTORY_DIR").ok().as_deref())
}

pub(crate) fn taxonomy_path_with_factory_dir(factory_dir: Option<&str>) -> PathBuf {
    if let Some(dir) = factory_dir
        && !dir.trim().is_empty()
    {
        return PathBuf::from(dir).join("specs/prd-supplements/error-taxonomy.md");
    }
    let local = PathBuf::from(".factory/specs/prd-supplements/error-taxonomy.md");
    if local.exists() {
        return local;
    }
    PathBuf::from("../../.factory/specs/prd-supplements/error-taxonomy.md")
}

pub fn run() {
    let path = taxonomy_path();
    let content = match std::fs::read_to_string(&path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!(
                "error-code-registry FAILED: cannot read taxonomy file {}: {}",
                path.display(),
                e
            );
            eprintln!("Hint: set FACTORY_DIR env var to the path of your .factory/ directory,");
            eprintln!("      or check out the factory-artifacts branch to .factory/.");
            std::process::exit(1);
        }
    };

    let mut code_locations: HashMap<String, Vec<usize>> = HashMap::new();
    for (line_idx, line) in content.lines().enumerate() {
        if let Some(code) = extract_error_code(line) {
            code_locations.entry(code).or_default().push(line_idx + 1);
        }
    }

    let total = code_locations.len();
    if total == 0 {
        eprintln!(
            "error-code-registry FAILED: extracted 0 codes from {} — gate cannot certify anything (taxonomy table format may have changed)",
            path.display()
        );
        std::process::exit(1);
    }
    let mut collisions: Vec<(&String, &Vec<usize>)> = code_locations
        .iter()
        .filter(|(_, lines)| lines.len() > 1)
        .collect();
    // Sort for deterministic output
    collisions.sort_by_key(|(code, _)| code.as_str());

    if !collisions.is_empty() {
        for (code, lines) in &collisions {
            eprintln!(
                "error-code-registry COLLISION: {} appears {} times (lines: {:?})",
                code,
                lines.len(),
                lines
            );
        }
        eprintln!(
            "error-code-registry FAILED: {} collision(s) found in {} codes",
            collisions.len(),
            total
        );
        std::process::exit(1);
    }

    println!(
        "error-code-registry PASSED: {} codes validated, 0 collisions.",
        total
    );
}

/// Extracts an `E-<COMPONENT>-<NNN>` code from a markdown table row.
/// Returns `None` if the line is not a table row starting with a code.
pub(crate) fn extract_error_code(line: &str) -> Option<String> {
    let line = line.trim();
    if !line.starts_with("| E-") {
        return None;
    }
    // Table row: `| E-COMPONENT-NNN | ...`
    let after_pipe = line.strip_prefix("| ")?;
    let code_end = after_pipe.find(" |")?;
    let code = &after_pipe[..code_end];
    // Validate shape: E-<UPPERCASE>-<DIGITS>
    if is_valid_error_code(code) {
        Some(code.to_string())
    } else {
        None
    }
}

pub(crate) fn is_valid_error_code(s: &str) -> bool {
    // E-<COMPONENT>-<NNN>: starts with E-, then uppercase/digits component, dash, digits
    if !s.starts_with("E-") {
        return false;
    }
    let rest = &s[2..];
    let Some(dash_pos) = rest.rfind('-') else {
        return false;
    };
    let component = &rest[..dash_pos];
    let number = &rest[dash_pos + 1..];
    !component.is_empty()
        && component
            .chars()
            .all(|c| c.is_ascii_uppercase() || c.is_ascii_digit())
        && !number.is_empty()
        && number.chars().all(|c| c.is_ascii_digit())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_error_code_valid() {
        assert_eq!(
            extract_error_code("| E-CORE-001 | VAL | broken | BC-2.01.001 | `msg` |"),
            Some("E-CORE-001".to_string())
        );
        assert_eq!(
            extract_error_code("| E-MCP-012 | IO | transient | BC-3.01.002 | `err` |"),
            Some("E-MCP-012".to_string())
        );
    }

    #[test]
    fn test_extract_error_code_not_a_row() {
        assert_eq!(extract_error_code("## Section"), None);
        assert_eq!(extract_error_code("| Header | Category |"), None);
        assert_eq!(extract_error_code(""), None);
        // lowercase component — not valid
        assert_eq!(
            extract_error_code("| E-core-001 | VAL | broken | BC-2.01.001 | `msg` |"),
            None
        );
    }

    #[test]
    fn test_is_valid_error_code() {
        assert!(is_valid_error_code("E-CORE-001"));
        assert!(is_valid_error_code("E-MCP-012"));
        assert!(is_valid_error_code("E-GRAPH-099"));
        assert!(!is_valid_error_code("E-core-001")); // lowercase component
        assert!(!is_valid_error_code("ERROR-001")); // no E- prefix
        assert!(!is_valid_error_code("E-CORE-")); // no number
        assert!(!is_valid_error_code("E--001")); // empty component
        assert!(!is_valid_error_code("E-CORE-ABC")); // non-digit suffix
    }

    #[test]
    fn test_uniqueness_check_no_collisions() {
        let content = "| E-CORE-001 | VAL | broken | BC-2.01.001 | `msg` |\n\
                       | E-CORE-002 | IO | transient | BC-2.01.001 | `msg` |\n\
                       | E-MCP-001 | VAL | broken | BC-3.01.001 | `msg` |\n";
        let mut code_locations: std::collections::HashMap<String, Vec<usize>> =
            std::collections::HashMap::new();
        for (line_idx, line) in content.lines().enumerate() {
            if let Some(code) = extract_error_code(line) {
                code_locations.entry(code).or_default().push(line_idx + 1);
            }
        }
        assert_eq!(code_locations.len(), 3);
        assert!(code_locations.values().all(|v| v.len() == 1));
    }

    #[test]
    fn test_error_code_registry_zero_codes_is_error() {
        // A taxonomy with no | E- rows must not produce a vacuous pass.
        // This test exercises the zero-count guard path via the extracted logic.
        let content = "## Error Taxonomy\n\nNo codes here.\n\n| Header | Category |\n|--------|----------|\n| sometext | val |\n";
        let mut code_locations: std::collections::HashMap<String, Vec<usize>> =
            std::collections::HashMap::new();
        for (line_idx, line) in content.lines().enumerate() {
            if let Some(code) = extract_error_code(line) {
                code_locations.entry(code).or_default().push(line_idx + 1);
            }
        }
        let total = code_locations.len();
        // The zero-count guard fires when total == 0.
        assert_eq!(
            total, 0,
            "no valid E-* codes should be extracted from this content"
        );
    }

    #[test]
    fn test_taxonomy_path_empty_factory_dir_uses_fallback() {
        // FACTORY_DIR="" must NOT use the empty string as a path prefix.
        // It must fall through to the .factory/ or ../../.factory/ fallbacks.
        let path = taxonomy_path_with_factory_dir(Some(""));
        let path_str = path.to_string_lossy();
        assert!(
            path_str.contains(".factory"),
            "empty FACTORY_DIR must use .factory/ fallback, got: {path_str}"
        );
        assert!(
            !path_str.starts_with("specs/"),
            "empty FACTORY_DIR must NOT produce a bare relative path starting with specs/, got: {path_str}"
        );
    }

    #[test]
    fn test_taxonomy_path_whitespace_factory_dir_uses_fallback() {
        let path = taxonomy_path_with_factory_dir(Some("   "));
        let path_str = path.to_string_lossy();
        assert!(
            path_str.contains(".factory"),
            "whitespace-only FACTORY_DIR must use .factory/ fallback, got: {path_str}"
        );
    }

    #[test]
    fn test_taxonomy_path_valid_factory_dir_is_used() {
        let path = taxonomy_path_with_factory_dir(Some("/tmp/my-factory"));
        assert_eq!(
            path,
            std::path::PathBuf::from("/tmp/my-factory/specs/prd-supplements/error-taxonomy.md")
        );
    }

    #[test]
    fn test_uniqueness_check_detects_collision() {
        let content = "| E-CORE-001 | VAL | broken | BC-2.01.001 | `msg` |\n\
                       | E-CORE-002 | IO | transient | BC-2.01.001 | `msg` |\n\
                       | E-CORE-001 | IO | transient | BC-2.01.002 | `duplicate` |\n";
        let mut code_locations: std::collections::HashMap<String, Vec<usize>> =
            std::collections::HashMap::new();
        for (line_idx, line) in content.lines().enumerate() {
            if let Some(code) = extract_error_code(line) {
                code_locations.entry(code).or_default().push(line_idx + 1);
            }
        }
        let collisions: Vec<_> = code_locations
            .iter()
            .filter(|(_, lines)| lines.len() > 1)
            .collect();
        assert_eq!(collisions.len(), 1);
        let (code, lines) = collisions[0];
        assert_eq!(code, "E-CORE-001");
        assert_eq!(lines.len(), 2);
    }
}
