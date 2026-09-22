//! AC-007 compile-fail gate — `#[non_exhaustive]` external-boundary verification.
//!
//! Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007.
//! BC-2.14.001 {PC-008} — adversary findings: F1 (adv pass-2; POL-42 — extend gate to all 6 types),
//!                     OBS-1 (layout reconciliation note).
//!
//! ## What this gate proves
//!
//! Every public `#[non_exhaustive]` type introduced by S-1.01 has compile-fail
//! coverage from an external-crate perspective. The Rust reference states:
//!   - Non-exhaustive STRUCT: cannot be matched/destructured without `..` outside
//!     the defining crate (E0638).
//!   - Non-exhaustive ENUM: cannot be matched exhaustively without a wildcard `_`
//!     arm outside the defining crate (E0004).
//!
//! An in-crate `#[cfg(test)]` module is in the same crate, so the attribute is
//! a no-op there: the compiler permits both construction and exhaustive matching.
//! Only an **external** compilation unit triggers the restriction.
//!
//! `trybuild` compiles each fixture as an independent binary that imports
//! `pregolya_core` as an external dependency, reproducing the external-crate
//! boundary.
//!
//! ## Layout note (BC-2.14.001 {PC-008} OBS-1 reconciliation)
//!
//! CLAUDE.md §`#[non_exhaustive] on public API surface types` documents the
//! gate pattern as `tests/external/<gate-name>/`. This crate uses trybuild's
//! idiomatic `tests/<runner>.rs` + `tests/ui/` layout (the runner file is this
//! file; the fixtures live in `tests/ui/`). These two layouts are functionally
//! equivalent: trybuild treats `tests/ui/` as its own `tests/external/`
//! namespace, compiling each fixture in isolation as an independent binary.
//! The `tests/ui/` layout is the concrete realization of the CLAUDE.md pattern
//! for this crate — no relocation required.
//!
//! ## Non-exhaustive symbol inventory (CLAUDE.md gate update protocol)
//!
//! When a new `#[non_exhaustive]` public type is added to the API surface,
//! update ALL THREE of:
//!   1. Add compile-fail + pass fixture pair(s) under `tests/ui/`
//!   2. Increment `EXPECTED_NON_EXHAUSTIVE_COUNT` below
//!   3. Add the symbol to `EXPECTED_NON_EXHAUSTIVE_SYMBOLS` below
//!
//! Gate authority: CI failure == a type was added without `#[non_exhaustive]`
//! or without a gate update.
//!
//! ### Current inventory (BC-2.14.001 {PC-008} S-1.01 Wave 1 — 5 types; pass-9b: ProblemExtensions removed per BC-2.14.002 {PC-001} option ii)
//!
//! ```text
//! EXPECTED_NON_EXHAUSTIVE_COUNT  = 5
//! EXPECTED_NON_EXHAUSTIVE_SYMBOLS = [
//!   "pregolya_core::PregolyaError",
//!   "pregolya_core::Component",
//!   "pregolya_core::Category",
//!   "pregolya_core::RetryHint",
//!   "pregolya_core::ProblemDetail",
//! ]
//! ```

/// Expected number of non-exhaustive types with compile-fail coverage.
///
/// Increment when adding a new type to the inventory above.
const EXPECTED_NON_EXHAUSTIVE_COUNT: usize = 5;

/// Number of compile-fail fixtures testing struct-literal construction restriction
/// (BC-2.14.001 {PC-008} clause 1). Separate from EXPECTED_NON_EXHAUSTIVE_COUNT
/// which counts per-type match-exhaustiveness fixtures.
const CONSTRUCTION_FAIL_FIXTURE_COUNT: usize = 1;
const CONSTRUCTION_FAIL_FIXTURES: [&str; CONSTRUCTION_FAIL_FIXTURE_COUNT] =
    ["pregolya_error_struct_literal_construction_fails"];

/// Symbolic list of non-exhaustive types covered by this gate.
///
/// Add an entry here AND add the corresponding `tests/ui/` fixture pair when a
/// new `#[non_exhaustive]` public API surface type is introduced.
const EXPECTED_NON_EXHAUSTIVE_SYMBOLS: [&str; EXPECTED_NON_EXHAUSTIVE_COUNT] = [
    "pregolya_core::PregolyaError",
    "pregolya_core::Component",
    "pregolya_core::Category",
    "pregolya_core::RetryHint",
    "pregolya_core::ProblemDetail",
];

// ── BC-2.14.001 {PC-008} inventory load-bearing runtime gate (F1 provenance) ──────────────────

/// Runtime gate: verifies that `EXPECTED_NON_EXHAUSTIVE_COUNT` and
/// `EXPECTED_NON_EXHAUSTIVE_SYMBOLS` match the actual source.
///
/// 1. Reads all `.rs` files under `src/` recursively and counts `#[non_exhaustive]` occurrences.
/// 2. Asserts the count equals `EXPECTED_NON_EXHAUSTIVE_COUNT`.
/// 3. For each symbol in `EXPECTED_NON_EXHAUSTIVE_SYMBOLS`, asserts it is mentioned in the source.
/// 4. Asserts the number of `_fails.rs` fixtures in `tests/ui/` equals the count.
///
/// This makes the inventory constants load-bearing: adding a `#[non_exhaustive]` type
/// without updating the constants will fail this test.
#[test]
fn test_non_exhaustive_inventory_matches_source() {
    // Cargo runs integration tests with cwd = package root (crates/pregolya-core/).
    // Walk all src/*.rs recursively and concatenate into one string for search.
    fn read_all_src_files() -> String {
        let mut all = String::new();
        fn walk(dir: &std::path::Path, out: &mut String) {
            for entry in std::fs::read_dir(dir).expect("read src/") {
                let entry = entry.expect("entry");
                let p = entry.path();
                if p.is_dir() {
                    walk(&p, out);
                } else if p.extension().is_some_and(|e| e == "rs") {
                    out.push_str(&std::fs::read_to_string(&p).unwrap_or_default());
                }
            }
        }
        walk(std::path::Path::new("src"), &mut all);
        all
    }

    let source = read_all_src_files();
    assert!(
        !source.is_empty(),
        "src/ must contain at least one .rs file for the non-exhaustive inventory gate"
    );

    // Count #[non_exhaustive] occurrences on actual Rust attribute lines only.
    // Doc comment lines (starting with `///` or `//!`) are excluded — they may
    // mention `#[non_exhaustive]` in explanatory prose without being attributes.
    let actual_count = source
        .lines()
        .filter(|line| {
            let trimmed = line.trim();
            !trimmed.starts_with("///") && !trimmed.starts_with("//!")
        })
        .filter(|line| line.contains("#[non_exhaustive]"))
        .count();
    assert_eq!(
        actual_count, EXPECTED_NON_EXHAUSTIVE_COUNT,
        "EXPECTED_NON_EXHAUSTIVE_COUNT ({EXPECTED_NON_EXHAUSTIVE_COUNT}) does not match \
         actual #[non_exhaustive] attribute occurrences across src/ ({actual_count}). \
         Update EXPECTED_NON_EXHAUSTIVE_COUNT and add a fixture pair."
    );

    // Verify each symbol in the inventory appears in the source
    for sym in &EXPECTED_NON_EXHAUSTIVE_SYMBOLS {
        // The symbol names are qualified (e.g. "pregolya_core::Component") —
        // strip to the bare type name for source-file lookup.
        let bare_name = sym.rsplit("::").next().unwrap_or(sym);
        assert!(
            source.contains(bare_name),
            "Inventory symbol '{sym}' (bare name: '{bare_name}') not found in src/ source. \
             Update EXPECTED_NON_EXHAUSTIVE_SYMBOLS to match the actual public types."
        );
    }

    // Count _fails.rs fixtures in tests/ui/:
    //   - EXPECTED_NON_EXHAUSTIVE_COUNT per-type match-exhaustiveness fixtures
    //   - CONSTRUCTION_FAIL_FIXTURE_COUNT struct-literal construction fixtures (BC-2.14.001 {PC-008} clause 1)
    let expected_fails = EXPECTED_NON_EXHAUSTIVE_COUNT + CONSTRUCTION_FAIL_FIXTURE_COUNT;
    // Path is relative to the package root (crates/pregolya-core/).
    let ui_dir = std::fs::read_dir("tests/ui/").expect("tests/ui/ must be readable");
    let fails_count = ui_dir
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().ends_with("_fails.rs"))
        .count();
    assert_eq!(
        fails_count, expected_fails,
        "Number of _fails.rs fixtures in tests/ui/ ({fails_count}) does not match \
         expected ({expected_fails} = {EXPECTED_NON_EXHAUSTIVE_COUNT} per-type + \
         {CONSTRUCTION_FAIL_FIXTURE_COUNT} construction). \
         Add a compile-fail fixture for any new non-exhaustive type or construction pattern."
    );

    // Count _passes.rs fixtures in tests/ui/ — must equal the inventory count (symmetric).
    // Bidirectional enforcement: the registry is authoritative in both directions — a fixture
    // on disk without a registry entry AND a registry entry without a fixture are both errors.
    // No pass counterpart for construction restriction fixtures (external construction is always barred).
    let ui_dir2 = std::fs::read_dir("tests/ui/").expect("tests/ui/ must be readable");
    let passes_count = ui_dir2
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().ends_with("_passes.rs"))
        .count();
    assert_eq!(
        passes_count, EXPECTED_NON_EXHAUSTIVE_COUNT,
        "Number of _passes.rs fixtures in tests/ui/ ({passes_count}) does not match \
         EXPECTED_NON_EXHAUSTIVE_COUNT ({EXPECTED_NON_EXHAUSTIVE_COUNT}). \
         Add a compile-pass fixture for any new non-exhaustive type."
    );

    println!(
        "non_exhaustive gate: {} types validated ({} fails [{} per-type + {} construction], {} passes)",
        actual_count,
        fails_count,
        EXPECTED_NON_EXHAUSTIVE_COUNT,
        CONSTRUCTION_FAIL_FIXTURE_COUNT,
        passes_count
    );
}

// ── BC-2.14.001 {PC-008} MED-007: Glob-based gate — every pub type must have #[non_exhaustive] ─────

/// BC-2.14.001 {PC-008} MED-007: Walks `src/` to find all `pub enum` and `pub struct` declarations
/// and asserts each one is immediately preceded by `#[non_exhaustive]`.
///
/// This is stronger than the count-based `test_non_exhaustive_inventory_matches_source`:
/// the count gate detects adding a `#[non_exhaustive]` attribute without updating the
/// constant, but it cannot detect adding a `pub struct`/`pub enum` WITHOUT the
/// `#[non_exhaustive]` attribute. This glob-based gate closes that gap.
#[test]
fn test_all_pub_types_have_non_exhaustive() {
    use std::path::Path;

    let mut violations: Vec<String> = Vec::new();
    let mut pub_types_found = 0usize;

    fn walk_src(dir: &Path, violations: &mut Vec<String>, count: &mut usize) {
        let entries = std::fs::read_dir(dir).expect("read src/");
        for entry in entries {
            let entry = entry.expect("dir entry");
            let path = entry.path();
            if path.is_dir() {
                walk_src(&path, violations, count);
            } else if path.extension().is_some_and(|e| e == "rs") {
                check_file_for_non_exhaustive(&path, violations, count);
            }
        }
    }

    fn check_file_for_non_exhaustive(path: &Path, violations: &mut Vec<String>, count: &mut usize) {
        let content = std::fs::read_to_string(path).expect("read file");
        let lines: Vec<&str> = content.lines().collect();
        for (i, line) in lines.iter().enumerate() {
            let trimmed = line.trim();
            if trimmed.starts_with("pub enum ") || trimmed.starts_with("pub struct ") {
                *count += 1;
                // Walk backwards through preceding non-blank lines to find #[non_exhaustive]
                let has_attr = (0..i)
                    .rev()
                    .map(|j| lines[j].trim())
                    .take_while(|l| !l.is_empty())
                    .any(|l| l == "#[non_exhaustive]" || l.starts_with("#[non_exhaustive]"));
                if !has_attr {
                    violations.push(format!(
                        "{}:{}: `{}` lacks #[non_exhaustive]",
                        path.display(),
                        i + 1,
                        trimmed
                    ));
                }
            }
        }
    }

    // Cargo runs integration tests with cwd = package root (crates/pregolya-core/).
    walk_src(Path::new("src"), &mut violations, &mut pub_types_found);

    assert_eq!(
        pub_types_found, EXPECTED_NON_EXHAUSTIVE_COUNT,
        "found {pub_types_found} pub types in src/, expected {}; \
         CI failure = a type was added without #[non_exhaustive] or count was not updated",
        EXPECTED_NON_EXHAUSTIVE_COUNT
    );
    assert!(
        violations.is_empty(),
        "pub types missing #[non_exhaustive] (CI failure = type added without attribute):\n{}",
        violations.join("\n")
    );
}

// ── AC-007 compile-fail / compile-pass trybuild fixtures ─────────────────────
//
// BC-2.14.001 {PC-008} — all 11 fixture registrations consolidated into a single `ui()` test to
// avoid spawning 11 independent trybuild processes (LOW-001 adv pass-2 provenance).
// The `TestCases` object batches all fixtures into one compilation run.
//
// Per-type documentation preserved as comments for AC-007 traceability.

/// AC-007 (BC-2.14.001 {PC-008}): Compile-fail and compile-pass gate for all
/// 5 `#[non_exhaustive]` types in `pregolya-core`.
///
/// Fixtures are registered in type order: PregolyaError → ProblemDetail →
/// Component → Category → RetryHint (+ struct-literal construction).
/// (`ProblemExtensions` removed in pass-9b per BC-2.14.002 {PC-001} option ii.)
///
/// - Structs: `..` wildcard required from external crate (E0638)
/// - Enums: wildcard `_` arm required from external crate (E0004)
///
/// Trybuild compiles each fixture as an independent binary importing
/// `pregolya_core` as an external dependency, reproducing the external-crate
/// boundary.
#[test]
fn ui() {
    // BC-2.14.001 {PC-008}: all EXPECTED_NON_EXHAUSTIVE_COUNT × 2 + CONSTRUCTION_FAIL_FIXTURE_COUNT (= 11) fixtures registered.
    // The list is the authority — CI fails if a fixture is on disk but not here (or vice versa).
    const FAIL_FIXTURES: [&str; EXPECTED_NON_EXHAUSTIVE_COUNT] = [
        "tests/ui/pregolya_error_match_without_dots_fails.rs",
        "tests/ui/problem_detail_match_without_dots_fails.rs",
        "tests/ui/component_match_without_wildcard_fails.rs",
        "tests/ui/category_match_without_wildcard_fails.rs",
        "tests/ui/retry_hint_match_without_wildcard_fails.rs",
    ];
    const PASS_FIXTURES: [&str; EXPECTED_NON_EXHAUSTIVE_COUNT] = [
        "tests/ui/pregolya_error_match_with_dots_passes.rs",
        "tests/ui/problem_detail_match_with_dots_passes.rs",
        "tests/ui/component_match_with_wildcard_passes.rs",
        "tests/ui/category_match_with_wildcard_passes.rs",
        "tests/ui/retry_hint_match_with_wildcard_passes.rs",
    ];

    // Array type annotation [&str; EXPECTED_NON_EXHAUSTIVE_COUNT] is the compile-time enforcement mechanism;
    // this assert is redundant but harmless.
    const _: () = assert!(
        FAIL_FIXTURES.len() == EXPECTED_NON_EXHAUSTIVE_COUNT,
        "fail fixture count mismatch with EXPECTED_NON_EXHAUSTIVE_COUNT"
    );
    // Array type annotation [&str; EXPECTED_NON_EXHAUSTIVE_COUNT] is the compile-time enforcement mechanism;
    // this assert is redundant but harmless.
    const _: () = assert!(
        PASS_FIXTURES.len() == EXPECTED_NON_EXHAUSTIVE_COUNT,
        "pass fixture count mismatch with EXPECTED_NON_EXHAUSTIVE_COUNT"
    );

    let t = trybuild::TestCases::new();
    for path in FAIL_FIXTURES {
        t.compile_fail(path);
    }
    for path in PASS_FIXTURES {
        t.pass(path);
    }
    for fixture in CONSTRUCTION_FAIL_FIXTURES.iter() {
        t.compile_fail(format!("tests/ui/{}.rs", fixture));
    }

    let total_fails = FAIL_FIXTURES.len() + CONSTRUCTION_FAIL_FIXTURES.len();
    println!(
        "ui gate: {} fixtures registered ({} compile_fail [{} per-type + {} construction], {} pass)",
        total_fails + PASS_FIXTURES.len(),
        total_fails,
        FAIL_FIXTURES.len(),
        CONSTRUCTION_FAIL_FIXTURES.len(),
        PASS_FIXTURES.len()
    );
}
