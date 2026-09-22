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

// ── Syn AST-based scanner ────────────────────────────────────────────────────
// Primary scan path: syn handles qualified paths (std::unreachable!/core::unreachable!)
// and match-arm context correctly by construction, closing the token-scanner edge-case
// class (F-01 guarded irrefutable binding, F-02 cross-arm misattribution, F-05 qualified
// path). When syn cannot parse a file a fail-safe finding is emitted rather than silently
// certifying an unparseable source as clean.

struct PanicVisitor<'a> {
    path: &'a str,
    findings: Vec<String>,
    fn_has_panics_doc: bool,
    /// Stack of `is_catch_all` flags for nested match-arm bodies.
    /// Empty = not inside any match-arm body; unreachable! there is §PC-006.
    /// true = catch-all arm (wildcard or irrefutable binding); unreachable! → FLAG.
    /// false = named-variant arm; unreachable! → EXEMPT (Exemption 1).
    arm_stack: Vec<bool>,
}

fn syn_has_cfg_test(attrs: &[syn::Attribute]) -> bool {
    attrs.iter().any(|a| {
        a.path().is_ident("cfg")
            && matches!(&a.meta, syn::Meta::List(l) if l.tokens.to_string().trim() == "test")
    })
}

fn syn_has_panics_doc(attrs: &[syn::Attribute]) -> bool {
    attrs.iter().any(|a| {
        if !a.path().is_ident("doc") {
            return false;
        }
        if let syn::Meta::NameValue(nv) = &a.meta
            && let syn::Expr::Lit(syn::ExprLit {
                lit: syn::Lit::Str(s),
                ..
            }) = &nv.value
        {
            return s.value().contains("# Panics");
        }
        false
    })
}

/// Returns true if the match-arm pattern is a catch-all:
/// `_` wildcard, irrefutable lowercase binding (e.g. `other`), or an or-pattern
/// containing any catch-all sub-pattern. Named-variant arms (e.g. `Phase::Done`,
/// `Done`) are NOT catch-alls.
fn is_catch_all_pat(pat: &syn::Pat) -> bool {
    match pat {
        syn::Pat::Wild(_) => true,
        syn::Pat::Ident(p) => {
            p.by_ref.is_none()
                && p.mutability.is_none()
                && p.subpat.is_none()
                && p.ident
                    .to_string()
                    .chars()
                    .next()
                    .map(|c| c.is_ascii_lowercase())
                    .unwrap_or(false)
                && !matches!(p.ident.to_string().as_str(), "true" | "false")
        }
        syn::Pat::Or(p) => p.cases.iter().any(is_catch_all_pat),
        // Wrapper patterns that do not restrict the set of matched values:
        // `&other =>` and `(other) =>` are irrefutable-binding catch-alls.
        syn::Pat::Reference(r) => is_catch_all_pat(&r.pat),
        syn::Pat::Paren(p) => is_catch_all_pat(&p.pat),
        _ => false,
    }
}

fn syn_macro_has_bc_id(mac: &syn::Macro) -> bool {
    let s = mac.tokens.to_string();
    if let Some(pos) = s.find("BC-") {
        s[pos + 3..]
            .chars()
            .next()
            .map(|c| c.is_ascii_digit())
            .unwrap_or(false)
    } else {
        false
    }
}

impl<'ast> syn::visit::Visit<'ast> for PanicVisitor<'_> {
    fn visit_item_mod(&mut self, node: &'ast syn::ItemMod) {
        if !syn_has_cfg_test(&node.attrs) {
            syn::visit::visit_item_mod(self, node);
        }
    }

    fn visit_item_impl(&mut self, node: &'ast syn::ItemImpl) {
        // Skip the entire impl block when it carries #[cfg(test)].
        // This mirrors visit_item_mod's treatment of cfg(test) modules: all methods
        // inside a `#[cfg(test)] impl Foo { ... }` block are test-only code and must
        // not be flagged, even when the individual methods lack their own #[cfg(test)].
        if !syn_has_cfg_test(&node.attrs) {
            syn::visit::visit_item_impl(self, node);
        }
    }

    fn visit_item_fn(&mut self, node: &'ast syn::ItemFn) {
        if syn_has_cfg_test(&node.attrs) {
            return;
        }
        let old_doc = self.fn_has_panics_doc;
        // A nested fn definition is an independent callable — its body is NOT covered
        // by the outer match arm's Exemption 1.  Save and clear arm_stack so that any
        // unreachable! inside the nested fn is evaluated without match-arm context.
        let old_arm_stack = std::mem::take(&mut self.arm_stack);
        self.fn_has_panics_doc = syn_has_panics_doc(&node.attrs);
        syn::visit::visit_item_fn(self, node);
        self.fn_has_panics_doc = old_doc;
        self.arm_stack = old_arm_stack;
    }

    fn visit_impl_item_fn(&mut self, node: &'ast syn::ImplItemFn) {
        if syn_has_cfg_test(&node.attrs) {
            return;
        }
        let old_doc = self.fn_has_panics_doc;
        // Same save/restore as visit_item_fn: a method body is independently callable.
        let old_arm_stack = std::mem::take(&mut self.arm_stack);
        self.fn_has_panics_doc = syn_has_panics_doc(&node.attrs);
        syn::visit::visit_impl_item_fn(self, node);
        self.fn_has_panics_doc = old_doc;
        self.arm_stack = old_arm_stack;
    }

    fn visit_expr_closure(&mut self, node: &'ast syn::ExprClosure) {
        // A closure body is runtime-reachable code — it is NOT covered by the outer
        // named-arm Exemption 1.  Save and clear arm_stack so that unreachable! inside
        // a closure nested within a named arm is evaluated without arm context.
        let old_arm_stack = std::mem::take(&mut self.arm_stack);
        syn::visit::visit_expr_closure(self, node);
        self.arm_stack = old_arm_stack;
    }

    fn visit_expr_async(&mut self, node: &'ast syn::ExprAsync) {
        // An async block body is deferred execution (a Future) — it does NOT run as the
        // arm's direct synchronous evaluation.  Save and clear arm_stack so that
        // unreachable! inside an async / async move block nested within a named arm is
        // evaluated without any match-arm context (BC-2.14.003 §PC-006 / §EC-007).
        let old_arm_stack = std::mem::take(&mut self.arm_stack);
        syn::visit::visit_expr_async(self, node);
        self.arm_stack = old_arm_stack;
    }

    /// Push arm context before visiting the arm body; pop after.
    /// Guard expressions are visited WITHOUT arm context (unreachable! in a guard
    /// is not "inside the arm body" and triggers §PC-006).
    fn visit_arm(&mut self, node: &'ast syn::Arm) {
        if let Some((_, g)) = &node.guard {
            syn::visit::visit_expr(self, g);
        }
        self.arm_stack.push(is_catch_all_pat(&node.pat));
        syn::visit::visit_expr(self, &node.body);
        self.arm_stack.pop();
    }

    fn visit_expr_method_call(&mut self, node: &'ast syn::ExprMethodCall) {
        let m = node.method.to_string();
        if m == "unwrap" || m == "expect" {
            let line = node.method.span().start().line;
            self.findings.push(format!(
                "{}:{}: .{}() in non-test code (BC-2.14.003 violation)",
                self.path, line, m
            ));
        }
        syn::visit::visit_expr_method_call(self, node);
    }

    fn visit_expr_macro(&mut self, node: &'ast syn::ExprMacro) {
        self.handle_macro_invocation(&node.mac);
        // Macro token streams are opaque in syn; we don't recurse into them.
    }

    fn visit_stmt_macro(&mut self, node: &'ast syn::StmtMacro) {
        self.handle_macro_invocation(&node.mac);
        // Macro token streams are opaque in syn; we don't recurse into them.
    }
}

impl PanicVisitor<'_> {
    /// Core macro-invocation checker — called for both expression-context and
    /// statement-context macro invocations (`ExprMacro` and `StmtMacro`).
    /// `unreachable!` is checked against the current arm-stack context;
    /// `panic!`/`assert!`/`assert_eq!`/`assert_ne!` are flagged unless
    /// Exemption 2 (§PC-005: `# Panics` doc + BC-ID in message) applies.
    fn handle_macro_invocation(&mut self, mac: &syn::Macro) {
        let Some(seg) = mac.path.segments.last() else {
            return;
        };
        let name = seg.ident.to_string();
        let line = seg.ident.span().start().line;
        match name.as_str() {
            "unreachable" => {
                if self.arm_stack.is_empty() {
                    self.findings.push(format!(
                        "{}:{}: unreachable!() outside exhaustive-match named arm \
                         in non-test code (BC-2.14.003 §PC-006 violation: \
                         unreachable! is only permitted in explicit named match arms; \
                         use documented assert!() for programmer-error guards)",
                        self.path, line
                    ));
                } else if *self.arm_stack.last().unwrap_or(&false) {
                    self.findings.push(format!(
                        "{}:{}: wildcard-arm unreachable!() in non-test code \
                         (BC-2.14.003 EC-004/EC-007 violation: _ => unreachable! is a \
                         latent panic path under enum evolution; use explicit named arm \
                         unreachable! or documented assert!())",
                        self.path, line
                    ));
                }
                // Named arm (arm_stack.last() == Some(&false)): EXEMPT (Exemption 1)
            }
            n @ ("panic" | "assert" | "assert_eq" | "assert_ne")
                if !(self.fn_has_panics_doc && syn_macro_has_bc_id(mac)) =>
            {
                self.findings.push(format!(
                    "{}:{}: {}!() in non-test code (BC-2.14.003 violation)",
                    self.path, line, n
                ));
            }
            _ => {} // debug_assert!* and everything else: exempt
        }
    }
}

/// Syn AST-based scan. Returns `Ok(findings)` on success, `Err(syn::Error)` if syn
/// cannot parse the source (invalid Rust syntax — e.g. module-scope `let` statements).
fn scan_with_syn(src: &str, path: &str) -> Result<Vec<String>, syn::Error> {
    let file = syn::parse_file(src)?;
    let mut v = PanicVisitor {
        path,
        findings: Vec::new(),
        fn_has_panics_doc: false,
        arm_stack: Vec::new(),
    };
    syn::visit::visit_file(&mut v, &file);
    Ok(v.findings)
}

/// Scans a single Rust source file (as a string) for `.unwrap()` / `.expect(...)`
/// calls, bare `assert!`/`assert_eq!`/`assert_ne!`/`panic!` without documented
/// programmer-error-guard exemption, and wildcard/irrefutable-binding
/// `unreachable!()` arms outside `#[cfg(test)]` blocks.
///
/// # Two-exemption discipline (BC-2.14.003 §EC-007)
///
/// Exemption 1 — explicit named-arm unreachable: `unreachable!()` in a named
/// (non-wildcard, non-irrefutable-binding) match arm is NOT flagged. Applies to
/// qualified paths (`std::unreachable!`, `core::unreachable!`) via last-segment
/// matching. A wildcard `_ => unreachable!(...)` or irrefutable-binding arm
/// `other => unreachable!(...)` or guarded form `other if guard => unreachable!(...)`
/// is ALWAYS flagged (BC-2.14.003 §EC-004).
///
/// Exemption 2 — documented programmer-error-guard assert: `assert!`/`assert_eq!`/
/// `assert_ne!` where the enclosing function has a `# Panics` doc section AND the
/// assert message contains a BC-ID is NOT flagged.
///
/// Returns a `Vec<String>` of human-readable violation messages.
///
/// Called by `run()` per-file and exposed as `pub(crate)` for unit tests.
pub(crate) fn scan_for_panics_in_source(src: &str, path: &str) -> Vec<String> {
    // Fixture violation files contain intentional violations for gate coverage testing.
    if crate::is_test_file(path) && !path.contains("fixtures/violations") {
        return Vec::new();
    }

    // Primary: syn AST-based scan (handles qualified paths and match-arm context
    // correctly by construction — F-01/F-02/F-05 correct by construction).
    match scan_with_syn(src, path) {
        Ok(findings) => findings,
        Err(syn_err) => {
            // syn failed to parse the file (e.g. module-scope `let` statement in a
            // test fixture).  Attempt a proc_macro2 lex so we can distinguish a genuine
            // tokenisation error from a pure syntax error, and run a minimal method-call
            // scan rather than silently returning an empty vec.
            use proc_macro2::TokenStream;
            match src.parse::<TokenStream>() {
                Err(lex_err) => {
                    // Genuine tokenisation failure — emit the lex-error finding.
                    vec![format!("{}:0: FAILED TO LEX FILE: {}", path, lex_err)]
                }
                Ok(ts) => {
                    // syn failed but proc_macro2 succeeded.  Run a minimal recursive
                    // scan for `.unwrap()` / `.expect()` method calls in the raw token
                    // tree.  This surfaces violations in syntactically-invalid-but-
                    // tokenizable sources (e.g. test fixtures with module-scope `let`).
                    let mut findings = Vec::new();
                    scan_method_calls_in_tokens(ts.into_iter(), &mut findings, path);
                    if findings.is_empty() {
                        // No method violations found; emit a fail-safe parse-error
                        // finding so the file is not silently certified as clean.
                        vec![format!("{}:0: FAILED TO PARSE FILE: {}", path, syn_err)]
                    } else {
                        findings
                    }
                }
            }
        }
    }
}

/// Minimal recursive proc_macro2 token-tree scan used ONLY when `syn::parse_file`
/// fails.  Finds `.unwrap()` and `.expect()` method calls at any nesting depth.
///
/// Does NOT apply cfg(test) exemptions — callers hit this path only for
/// syntactically invalid Rust (e.g. test fixtures), where exemption tracking
/// cannot be guaranteed correct without a full parse.
fn scan_method_calls_in_tokens(
    iter: proc_macro2::token_stream::IntoIter,
    findings: &mut Vec<String>,
    path: &str,
) {
    use proc_macro2::TokenTree;
    let tokens: Vec<TokenTree> = iter.collect();
    let mut i = 0;
    while i < tokens.len() {
        match &tokens[i] {
            TokenTree::Punct(p) if p.as_char() == '.' => {
                if let Some(TokenTree::Ident(id)) = tokens.get(i + 1) {
                    let name = id.to_string();
                    if (name == "unwrap" || name == "expect")
                        && matches!(tokens.get(i + 2), Some(TokenTree::Group(_)))
                    {
                        let line = id.span().start().line;
                        findings.push(format!(
                            "{}:{}: .{}() in non-test code (BC-2.14.003 violation)",
                            path, line, name
                        ));
                    }
                }
            }
            TokenTree::Group(g) => {
                scan_method_calls_in_tokens(g.stream().into_iter(), findings, path);
            }
            _ => {}
        }
        i += 1;
    }
}

/// Entry point for `cargo xtask check-no-panic --fixture-mode <dir>`.
///
/// Scans all `*.rs` files under `dir` (not recursing into `target/`) for
/// panic-path violations using the same scanner as the normal gate. Exits
/// non-zero if any violation is found.
///
/// Purpose: verify that planted violation fixtures are correctly detected by
/// the gate (AC-017/Task-13, POL-31). Since violation fixtures intentionally
/// contain violations, a clean exit (0) from this mode indicates the scanner
/// is broken and failing to detect them.
///
/// Called by `main()` when `argv == ["check-no-panic", "--fixture-mode", <dir>]`.
pub fn run_fixture_mode(dir: &str) {
    let output = std::process::Command::new("find")
        .args([dir, "-name", "*.rs", "-not", "-path", "*/target/*"])
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
        // scan_for_panics_in_source exempts tests/ files EXCEPT fixtures/violations/.
        // For paths under the fixture dir that happen to contain tests/ (e.g.
        // xtask/tests/fixtures/violations/), the exceptions in scan_for_panics_in_source
        // ensure they are scanned.
        let findings = scan_for_panics_in_source(&content, file_path);
        all_findings.extend(findings);
    }

    if !all_findings.is_empty() {
        eprintln!("check-no-panic --fixture-mode {dir}: violations found (BC-2.14.003):");
        for f in &all_findings {
            eprintln!("  {f}");
        }
        exit(1);
    }
    println!("check-no-panic --fixture-mode {dir}: 0 violations found.");
}
