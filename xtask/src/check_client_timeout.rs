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
//! - `reqwest::blocking::Client/ClientBuilder` patterns are detected via the
//!   same qualifier classification logic as the async surface.  Bare
//!   `blocking::Client/ClientBuilder` (use-imported head form, e.g.
//!   `use reqwest::blocking; blocking::Client::new()`) are flagged
//!   conservatively by the path-relative guard.
//! - Files under `tests/` directories, `#[cfg(test)]` blocks, and files ending
//!   in `_test.rs`/`_tests.rs` are fully exempt (BC-2.14.004 {INV-003}).
//! - Exits non-zero when any violation is found; exits 0 on a clean scan.
//! - Uses `syn` AST-based scanning (`syn::visit::Visit`) for accurate detection
//!   that correctly handles parenthesized and braced base subexpressions.
//!
//! # Known Limitations
//!
//! **KNOWN-LIMITATION 1 — use-import false positives:** Bare `Client::new()`,
//! `ClientBuilder::new()`, and `Client::builder()` without a visible reqwest
//! qualifier are flagged conservatively. If the type was `use`-imported from a
//! non-reqwest crate (e.g., `use mcp_sdk::Client`), the gate will flag it. The
//! workaround is to use the fully-qualified form or to add the file to the
//! lint-exempt allowlist.
//!
//! **KNOWN-LIMITATION 2 — split-statement builder chains:** If a `ClientBuilder`
//! is stored in a `let` binding and `.build()` is called on that binding in a
//! separate statement, the gate cannot trace the chain across the statement
//! boundary and will not detect the missing `.timeout()`.
//!
//! **KNOWN-LIMITATION 3 — constant-valued zero timeout:** If the zero timeout is
//! a named constant (e.g., `const NO_TIMEOUT: Duration = Duration::ZERO;
//! .timeout(NO_TIMEOUT)`), the gate will not detect it as zero-valued. The gate
//! only inspects the syntactic form of the timeout argument.

use std::process::exit;
use syn::visit::Visit;

/// Entry point for `cargo xtask check-client-timeout`.
///
/// Scans `crates/**/*.rs` using syn AST-based analysis to detect `Client::new()`
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
    if let Err(msg) = crate::check_post_exemption_vacuity("check-client-timeout", files_analyzed) {
        eprintln!("{msg}");
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

    // Try to parse as a complete Rust source file.
    if let Ok(file) = syn::parse_file(src) {
        let mut checker = TimeoutChecker {
            path,
            findings: Vec::new(),
            in_test_context: false,
        };
        syn::visit::visit_file(&mut checker, &file);
        return checker.findings;
    }

    // Fallback: wrap in a synthetic function for fragment sources (e.g., bare let-statements
    // or bare expressions used in tests). Real production files always parse as complete files.
    let wrapped = format!("fn __fragment__() {{\n{src}\n}}");
    if let Ok(file) = syn::parse_file(&wrapped) {
        let mut checker = TimeoutChecker {
            path,
            findings: Vec::new(),
            in_test_context: false,
        };
        syn::visit::visit_file(&mut checker, &file);
        return checker.findings;
    }

    // Fail-closed: neither parse attempt succeeded; emit a blocking finding rather than
    // certifying unparseable source as clean.
    use proc_macro2::TokenStream;
    match src.parse::<TokenStream>() {
        Err(lex_err) => vec![format!("{}:0: FAILED TO LEX FILE: {}", path, lex_err)],
        Ok(_) => vec![format!("{}:0: FAILED TO PARSE FILE AS RUST SOURCE", path)],
    }
}

// ── Path qualifier classification ─────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Eq)]
enum QualifierKind {
    /// Definitively reqwest — flag unconditionally.
    Reqwest,
    /// Ambiguous bare or path-relative qualifier — flag conservatively
    /// (KNOWN-LIMITATION 1: may be a non-reqwest import).
    Conservative,
    /// Definitively non-reqwest — suppress.
    NonReqwest,
}

fn is_path_relative(s: &str) -> bool {
    matches!(s, "crate" | "self" | "super" | "Self")
}

/// Classify a BUILDER CONSTRUCTOR path for Pattern B (chain ending in `.build()`).
///
/// Recognizes paths ending with `Client::builder`, `ClientBuilder::new`, or
/// `ClientBuilder::default`.
/// Does NOT recognize `Client::new` or `Client::default` (Pattern A — direct construction).
fn classify_builder_constructor(segments: &[&str]) -> QualifierKind {
    if segments.len() < 2 {
        return QualifierKind::NonReqwest;
    }
    let last = segments[segments.len() - 1];
    let type_name = segments[segments.len() - 2];

    // Pattern B builder entries: ClientBuilder::new, ClientBuilder::default, OR Client::builder.
    // Client::new and Client::default are Pattern A (direct construction, no .build() required).
    let is_builder_entry = matches!(
        (type_name, last),
        ("Client", "builder") | ("ClientBuilder", "new") | ("ClientBuilder", "default")
    );
    if !is_builder_entry {
        return QualifierKind::NonReqwest;
    }

    let head = segments[0];
    match head {
        "reqwest" => QualifierKind::Reqwest,
        h if is_path_relative(h) => QualifierKind::Conservative,
        // bare `blocking::Client::builder` or `blocking::ClientBuilder::new` (use-imported head)
        "blocking" if segments.len() == 3 => QualifierKind::Conservative,
        // bare `Client::builder` or `ClientBuilder::new`
        _ if segments.len() == 2 => QualifierKind::Conservative,
        // other_sdk::Client::builder or other_sdk::ClientBuilder::new — suppress
        _ => QualifierKind::NonReqwest,
    }
}

/// Classify a DIRECT CONSTRUCTION path for Pattern A (`Client::new()`, `Client::default()`).
///
/// Recognizes paths ending with `Client::(new|default)`.
fn classify_client_new(segments: &[&str]) -> QualifierKind {
    if segments.len() < 2 {
        return QualifierKind::NonReqwest;
    }
    let last = segments[segments.len() - 1];
    let type_name = segments[segments.len() - 2];
    if (last != "new" && last != "default") || type_name != "Client" {
        return QualifierKind::NonReqwest;
    }

    let head = segments[0];
    match head {
        "reqwest" => QualifierKind::Reqwest,
        h if is_path_relative(h) => QualifierKind::Conservative,
        // bare `blocking::Client::new` (use-imported head)
        "blocking" if segments.len() == 3 => QualifierKind::Conservative,
        // bare `Client::new`
        _ if segments.len() == 2 => QualifierKind::Conservative,
        // other_sdk::blocking::Client::new or other_sdk::Client::new — suppress
        _ => QualifierKind::NonReqwest,
    }
}

// ── Zero-duration detection ────────────────────────────────────────────────────

/// Returns `true` if the expression is a zero numeric literal, handling
/// negation (e.g., `-0.0` is `Unary(Neg, Lit(0.0))`).
fn is_zero_literal_expr(expr: &syn::Expr) -> bool {
    match expr {
        syn::Expr::Lit(l) => match &l.lit {
            syn::Lit::Int(i) => is_zero_literal(&i.to_string()),
            syn::Lit::Float(f) => is_zero_literal(&f.to_string()),
            _ => false,
        },
        // Handle negative-zero forms: `-0.0`, `-0.`, `-0e0`, etc.
        syn::Expr::Unary(u) if matches!(u.op, syn::UnOp::Neg(_)) => is_zero_literal_expr(&u.expr),
        _ => false,
    }
}

/// Returns `true` when the expression is a zero-valued `Duration` argument.
///
/// Detected forms (mirrors the flat-token forms A–F):
/// - **Form A/B:** `Duration::ZERO`, `std::time::Duration::ZERO`, `core::time::Duration::ZERO`
/// - **Form C/D:** `Duration::from_secs(0)`, `std::time::Duration::from_millis(0)`, etc.
///   (all zero-literal constructors including hex, octal, float, and suffix forms)
/// - **Form E:** `Duration::new(0, 0)` (both secs and nanos must be zero)
/// - **Form F:** `Duration::default()` (always zero)
fn is_zero_duration_arg(arg: &syn::Expr) -> bool {
    match arg {
        // Form A/B: Duration::ZERO, std::time::Duration::ZERO, core::time::Duration::ZERO
        syn::Expr::Path(p) => {
            let segs: Vec<String> = p
                .path
                .segments
                .iter()
                .map(|s| s.ident.to_string())
                .collect();
            segs.last().map(|s| s.as_str()) == Some("ZERO")
                && segs.iter().rev().nth(1).map(|s| s.as_str()) == Some("Duration")
        }
        syn::Expr::Call(c) => {
            let syn::Expr::Path(p) = &*c.func else {
                return false;
            };
            let segs: Vec<String> = p
                .path
                .segments
                .iter()
                .map(|s| s.ident.to_string())
                .collect();
            // Must reference a Duration type somewhere in the path.
            if !segs.iter().any(|s| s == "Duration") {
                return false;
            }
            let last = segs.last().map(|s| s.as_str()).unwrap_or("");
            match last {
                // Form F: Duration::default() is always zero.
                "default" => true,
                // Form C/D: zero-literal constructors.
                "from_secs" | "from_millis" | "from_nanos" | "from_micros" | "from_secs_f64"
                | "from_secs_f32" => c.args.first().map(is_zero_literal_expr).unwrap_or(false),
                // Form E: Duration::new(secs, nanos) — both must be zero.
                "new" => {
                    let mut it = c.args.iter();
                    let secs_zero = it.next().map(is_zero_literal_expr).unwrap_or(false);
                    let nanos_zero = it.next().map(is_zero_literal_expr).unwrap_or(false);
                    secs_zero && nanos_zero
                }
                _ => false,
            }
        }
        _ => false,
    }
}

// ── Builder chain analysis ─────────────────────────────────────────────────────

struct ChainResult {
    has_valid_timeout: bool,
    line: usize,
    constructor_name: String,
}

/// Walk a builder chain from a `.build()` call's receiver back to the base constructor.
///
/// Returns `Some(ChainResult)` when the chain base looks like a reqwest or conservative
/// client constructor. Returns `None` when the base is definitively non-reqwest or
/// cannot be identified (e.g., a local variable).
///
/// Correctly unwraps parenthesized expressions (`(expr).build()`) and block expressions
/// (`{ expr }.build()`), eliminating KNOWN-LIMITATION 4 from the prior token scanner.
fn analyze_build_chain(expr: &syn::Expr) -> Option<ChainResult> {
    match expr {
        syn::Expr::MethodCall(mc) => {
            let method = mc.method.to_string();
            let inner = analyze_build_chain(&mc.receiver)?;
            if method == "timeout" {
                // A zero-duration timeout does not satisfy BC-2.14.004 {INV-004}.
                // Use the LAST `.timeout()` call's validity — the runtime honours
                // the last-set value, so a later `.timeout(Duration::ZERO)` revokes
                // a previously-set valid timeout ({INV-004} correctness).
                let is_zero = mc.args.first().map(is_zero_duration_arg).unwrap_or(false);
                Some(ChainResult {
                    has_valid_timeout: !is_zero,
                    ..inner
                })
            } else {
                // Other method call — pass through.
                Some(inner)
            }
        }
        syn::Expr::Call(call) => {
            let syn::Expr::Path(p) = &*call.func else {
                return None;
            };
            let seg_strings: Vec<String> = p
                .path
                .segments
                .iter()
                .map(|s| s.ident.to_string())
                .collect();
            let seg_refs: Vec<&str> = seg_strings.iter().map(|s| s.as_str()).collect();
            if classify_builder_constructor(&seg_refs) == QualifierKind::NonReqwest {
                return None;
            }
            let line = p
                .path
                .segments
                .first()
                .map(|s| s.ident.span().start().line)
                .unwrap_or(0);
            Some(ChainResult {
                has_valid_timeout: false,
                line,
                constructor_name: seg_strings.join("::"),
            })
        }
        // Unwrap parenthesized expressions: (reqwest::ClientBuilder::new()).build()
        syn::Expr::Paren(p) => analyze_build_chain(&p.expr),
        // Unwrap block tail expressions: { reqwest::ClientBuilder::new() }.build()
        syn::Expr::Block(b) => {
            if let Some(syn::Stmt::Expr(e, None)) = b.block.stmts.last() {
                analyze_build_chain(e)
            } else {
                None
            }
        }
        // Variable, path, or other expression — cannot trace to a constructor.
        _ => None,
    }
}

// ── Macro token-stream scanner ────────────────────────────────────────────────

/// Flat-token scan of a macro invocation's token stream for timeout violations.
///
/// Called from [`TimeoutChecker::visit_expr_macro`], [`TimeoutChecker::visit_stmt_macro`],
/// and [`TimeoutChecker::visit_item_macro`] for macro bodies that are opaque to the syn
/// AST visitor (e.g. `thread_local!{}`, `lazy_static!{}`).
///
/// Only fully-qualified forms whose path head is `reqwest` are detected.
/// Bare/use-imported forms cannot be distinguished from non-reqwest types in a flat
/// token scan and are outside this scanner's reach (KNOWN-LIMITATION 1 applies here
/// too — the fully-qualified form is the detection trigger).
///
/// # Detected patterns
///
/// - **Pattern A (unconditional):** `reqwest :: Client :: (new|default|builder)` and
///   `reqwest :: blocking :: Client :: (new|default|builder)` are flagged without
///   further chain tracing — in a macro body we cannot safely trace the builder chain.
///
/// - **Pattern B (chain scan):** `reqwest :: ClientBuilder :: (new|default)` and
///   `reqwest :: blocking :: ClientBuilder :: (new|default)` trigger a forward scan of
///   the remaining flat tokens. A finding is emitted when `.build()` appears before
///   `.timeout(...)` in the flat sequence.
fn scan_macro_tokens_for_timeout_violations(
    tokens: &proc_macro2::TokenStream,
    path: &str,
) -> Vec<String> {
    fn flatten_into(stream: proc_macro2::TokenStream, out: &mut Vec<proc_macro2::TokenTree>) {
        for tt in stream {
            match tt {
                proc_macro2::TokenTree::Group(g) => flatten_into(g.stream(), out),
                other => out.push(other),
            }
        }
    }

    /// Returns `true` when `flat[i]` and `flat[i+1]` form a `::` separator.
    fn is_sep(flat: &[proc_macro2::TokenTree], i: usize) -> bool {
        match (flat.get(i), flat.get(i + 1)) {
            (Some(proc_macro2::TokenTree::Punct(p1)), Some(proc_macro2::TokenTree::Punct(p2))) => {
                p1.as_char() == ':'
                    && p1.spacing() == proc_macro2::Spacing::Joint
                    && p2.as_char() == ':'
            }
            _ => false,
        }
    }

    /// Returns the ident string at `flat[i]`, or `None`.
    fn ident_str(flat: &[proc_macro2::TokenTree], i: usize) -> Option<String> {
        if let Some(proc_macro2::TokenTree::Ident(id)) = flat.get(i) {
            Some(id.to_string())
        } else {
            None
        }
    }

    /// Returns `true` when `.build()` appears before `.timeout(...)` scanning
    /// forward from `start` in the flat token list.
    fn build_before_timeout(flat: &[proc_macro2::TokenTree], start: usize) -> bool {
        let mut k = start;
        while k < flat.len() {
            if let (proc_macro2::TokenTree::Punct(p), Some(proc_macro2::TokenTree::Ident(id))) =
                (&flat[k], flat.get(k + 1))
                && p.as_char() == '.'
            {
                match id.to_string().as_str() {
                    "build" => return true,
                    "timeout" => return false,
                    _ => {}
                }
            }
            k += 1;
        }
        false // No .build() found — no violation.
    }

    let mut flat: Vec<proc_macro2::TokenTree> = Vec::new();
    flatten_into(tokens.clone(), &mut flat);
    let n = flat.len();
    let mut findings = Vec::new();
    let mut i = 0;

    while i < n {
        // Look for `reqwest` as path head.
        if ident_str(&flat, i).as_deref() != Some("reqwest") {
            i += 1;
            continue;
        }
        let line = if let proc_macro2::TokenTree::Ident(id) = &flat[i] {
            id.span().start().line
        } else {
            0
        };
        let mut j = i + 1;

        // Require `::` after `reqwest`.
        if !is_sep(&flat, j) {
            i += 1;
            continue;
        }
        j += 2;

        let seg1 = match ident_str(&flat, j) {
            Some(s) => s,
            None => {
                i += 1;
                continue;
            }
        };
        j += 1;

        // Parse: reqwest :: [blocking ::] TypeName :: method
        let (type_seg, method_seg, full_path_str, after_path) = if seg1 == "blocking" {
            if !is_sep(&flat, j) {
                i += 1;
                continue;
            }
            j += 2;
            let ts = match ident_str(&flat, j) {
                Some(s) => s,
                None => {
                    i += 1;
                    continue;
                }
            };
            j += 1;
            if !is_sep(&flat, j) {
                i += 1;
                continue;
            }
            j += 2;
            let ms = match ident_str(&flat, j) {
                Some(s) => s,
                None => {
                    i += 1;
                    continue;
                }
            };
            j += 1;
            let fp = format!("reqwest::blocking::{}::{}", ts, ms);
            (ts, ms, fp, j)
        } else {
            // seg1 is the TypeName.
            if !is_sep(&flat, j) {
                i += 1;
                continue;
            }
            j += 2;
            let ms = match ident_str(&flat, j) {
                Some(s) => s,
                None => {
                    i += 1;
                    continue;
                }
            };
            j += 1;
            let fp = format!("reqwest::{}::{}", seg1, ms);
            (seg1, ms, fp, j)
        };

        match (type_seg.as_str(), method_seg.as_str()) {
            // Pattern A: direct construction — always flag in macro context (chain
            // tracing is not possible across opaque token streams).
            ("Client", "new") | ("Client", "default") | ("Client", "builder") => {
                findings.push(format!(
                    "{}:{}: {}() without .timeout() — use build_client() (BC-2.14.004)",
                    path, line, full_path_str
                ));
            }
            // Pattern B: builder chain — scan forward for .build() before .timeout().
            ("ClientBuilder", "new") | ("ClientBuilder", "default")
                if build_before_timeout(&flat, after_path) =>
            {
                findings.push(format!(
                    "{}:{}: {}() without .timeout() (BC-2.14.004)",
                    path, line, full_path_str
                ));
            }
            _ => {}
        }

        i += 1;
    }

    findings
}

// ── Syn AST visitor ───────────────────────────────────────────────────────────

/// Check whether an item has a `#[cfg(test)]` attribute.
///
/// Intentionally duplicated from `check_no_panic::syn_has_cfg_test`.
/// Bodies are identical at time of writing. They are kept separate because
/// they gate different subsystems (HTTP-client timeout enforcement vs. panic
/// prevention) and are expected to diverge if one gate needs to extend to
/// additional `cfg` attributes (e.g., `#[cfg(any(test, feature = "test-utils"))`).
fn has_cfg_test_attr(attrs: &[syn::Attribute]) -> bool {
    attrs.iter().any(|a| {
        a.path().is_ident("cfg")
            && matches!(&a.meta, syn::Meta::List(l) if l.tokens.to_string().trim() == "test")
    })
}

struct TimeoutChecker<'a> {
    path: &'a str,
    findings: Vec<String>,
    in_test_context: bool,
}

impl<'ast> Visit<'ast> for TimeoutChecker<'_> {
    // Skip entire #[cfg(test)] modules — no timeout obligation inside them.
    fn visit_item_mod(&mut self, node: &'ast syn::ItemMod) {
        if !has_cfg_test_attr(&node.attrs) {
            syn::visit::visit_item_mod(self, node);
        }
    }

    // Skip entire #[cfg(test)] impl blocks.
    fn visit_item_impl(&mut self, node: &'ast syn::ItemImpl) {
        if !has_cfg_test_attr(&node.attrs) {
            syn::visit::visit_item_impl(self, node);
        }
    }

    // Skip #[cfg(test)] functions; mark test functions as test context.
    // Recognises `#[test]`, `#[tokio::test]`, `#[async_std::test]`, `#[rstest]`
    // and any other attribute whose last path segment is `test`.
    fn visit_item_fn(&mut self, node: &'ast syn::ItemFn) {
        if has_cfg_test_attr(&node.attrs) {
            return;
        }
        let old = self.in_test_context;
        if node
            .attrs
            .iter()
            .any(|a| a.path().segments.last().is_some_and(|s| s.ident == "test"))
        {
            self.in_test_context = true;
        }
        syn::visit::visit_item_fn(self, node);
        self.in_test_context = old;
    }

    // Skip #[cfg(test)] impl methods; mark test methods as test context.
    // Same last-segment matching as visit_item_fn.
    fn visit_impl_item_fn(&mut self, node: &'ast syn::ImplItemFn) {
        if has_cfg_test_attr(&node.attrs) {
            return;
        }
        let old = self.in_test_context;
        if node
            .attrs
            .iter()
            .any(|a| a.path().segments.last().is_some_and(|s| s.ident == "test"))
        {
            self.in_test_context = true;
        }
        syn::visit::visit_impl_item_fn(self, node);
        self.in_test_context = old;
    }

    // Pattern A: `Client::new()` / `Client::default()` — direct Client construction is
    // always a violation because reqwest::Client::new() and ::default() provide no timeout.
    fn visit_expr_call(&mut self, node: &'ast syn::ExprCall) {
        if !self.in_test_context
            && let syn::Expr::Path(p) = &*node.func
        {
            let seg_strings: Vec<String> = p
                .path
                .segments
                .iter()
                .map(|s| s.ident.to_string())
                .collect();
            let seg_refs: Vec<&str> = seg_strings.iter().map(|s| s.as_str()).collect();

            // Standard path form: reqwest::Client::new() / reqwest::Client::default() / Client::new()
            if classify_client_new(&seg_refs) != QualifierKind::NonReqwest {
                let line = p
                    .path
                    .segments
                    .first()
                    .map(|s| s.ident.span().start().line)
                    .unwrap_or(0);
                self.findings.push(format!(
                    "{}:{}: {}() without .timeout() — use build_client() (BC-2.14.004)",
                    self.path,
                    line,
                    seg_strings.join("::")
                ));
            }

            // UFCS form: `<reqwest::Client as Default>::default()` — an ExprPath with a
            // QSelf carries the reqwest Client type in the qself, not in the path segments.
            // Emit a conservative violation unless the qself type is clearly non-reqwest.
            if let Some(qself) = &p.qself {
                let last_method = seg_strings.last().map(|s| s.as_str()).unwrap_or("");
                if last_method == "default"
                    && let syn::Type::Path(tp) = &*qself.ty
                {
                    let qself_segs: Vec<String> = tp
                        .path
                        .segments
                        .iter()
                        .map(|s| s.ident.to_string())
                        .collect();
                    // Append "default" to the qself path to reuse classify_client_new.
                    let mut lookup: Vec<String> = qself_segs.clone();
                    lookup.push("default".to_string());
                    let lookup_refs: Vec<&str> = lookup.iter().map(|s| s.as_str()).collect();
                    if classify_client_new(&lookup_refs) != QualifierKind::NonReqwest {
                        let line = tp
                            .path
                            .segments
                            .first()
                            .map(|s| s.ident.span().start().line)
                            .unwrap_or(0);
                        let name = format!("<{}>::default", qself_segs.join("::"));
                        self.findings.push(format!(
                            "{}:{}: {}() without .timeout() — use build_client() (BC-2.14.004)",
                            self.path, line, name
                        ));
                    }
                }
            }
        }
        // Always recurse into arguments to catch nested violations.
        syn::visit::visit_expr_call(self, node);
    }

    // Pattern B: builder chains ending in `.build()` without a valid `.timeout()`.
    fn visit_expr_method_call(&mut self, node: &'ast syn::ExprMethodCall) {
        if !self.in_test_context
            && node.method == "build"
            && node.args.is_empty()
            && let Some(result) = analyze_build_chain(&node.receiver)
            && !result.has_valid_timeout
        {
            self.findings.push(format!(
                "{}:{}: {}() without .timeout() (BC-2.14.004)",
                self.path, result.line, result.constructor_name
            ));
        }
        // Always recurse to catch violations inside arguments and receiver chains.
        syn::visit::visit_expr_method_call(self, node);
    }

    // Macro invocations are opaque to the syn AST visitor. Scan their token streams
    // for reqwest client constructions that `visit_expr_call` / `visit_expr_method_call`
    // would not see (e.g. `reqwest::Client::new()` inside `thread_local!{}`).
    fn visit_expr_macro(&mut self, node: &'ast syn::ExprMacro) {
        if !self.in_test_context {
            self.findings
                .extend(scan_macro_tokens_for_timeout_violations(
                    &node.mac.tokens,
                    self.path,
                ));
        }
        syn::visit::visit_expr_macro(self, node);
    }

    fn visit_stmt_macro(&mut self, node: &'ast syn::StmtMacro) {
        if !self.in_test_context {
            self.findings
                .extend(scan_macro_tokens_for_timeout_violations(
                    &node.mac.tokens,
                    self.path,
                ));
        }
        syn::visit::visit_stmt_macro(self, node);
    }

    fn visit_item_macro(&mut self, node: &'ast syn::ItemMacro) {
        // Skip `#[cfg(test)]` item macros (e.g. a `thread_local!` in a test module).
        if has_cfg_test_attr(&node.attrs) {
            return;
        }
        if !self.in_test_context {
            self.findings
                .extend(scan_macro_tokens_for_timeout_violations(
                    &node.mac.tokens,
                    self.path,
                ));
        }
        syn::visit::visit_item_macro(self, node);
    }
}

// ── Zero literal normalisation ────────────────────────────────────────────────

/// Returns `true` when a literal string representation is numerically zero.
///
/// Handles: underscore separators (`0_u64`), type suffixes (`0f64`), hex (`0x0`),
/// binary (`0b0`), octal (`0o0`), float (`0.0`, `0e0`, `0.`), and leading minus
/// (negative-zero forms like `-0.0`). All are recognised as zero.
fn is_zero_literal(s: &str) -> bool {
    // Handle negative-zero forms: "-0.0", "-0.", "-0", "-0e0", etc.
    let s = s.strip_prefix('-').unwrap_or(s);

    // Step 1: strip underscore separators.
    let no_underscores = s.replace('_', "");

    // Step 2: strip trailing type suffix (longest first to avoid partial strips).
    const TYPE_SUFFIXES: &[&str] = &[
        "u128", "u64", "u32", "u16", "u8", "usize", "i128", "i64", "i32", "i16", "i8", "isize",
        "f64", "f32",
    ];
    let stripped: &str = {
        let mut result: &str = no_underscores.as_str();
        for suffix in TYPE_SUFFIXES {
            if let Some(base) = result.strip_suffix(suffix) {
                result = base;
                break;
            }
        }
        result
    };

    // Step 3: parse by radix.
    if let Some(hex_digits) = stripped
        .strip_prefix("0x")
        .or_else(|| stripped.strip_prefix("0X"))
    {
        // Hex zero: all digits after the prefix must be '0'.
        return !hex_digits.is_empty() && hex_digits.chars().all(|c| c == '0');
    }
    if let Some(bin_digits) = stripped
        .strip_prefix("0b")
        .or_else(|| stripped.strip_prefix("0B"))
    {
        // Binary zero: all digits after the prefix must be '0'.
        return !bin_digits.is_empty() && bin_digits.chars().all(|c| c == '0');
    }
    if let Some(oct_digits) = stripped
        .strip_prefix("0o")
        .or_else(|| stripped.strip_prefix("0O"))
    {
        // Octal zero: all digits after the prefix must be '0'.
        return !oct_digits.is_empty() && oct_digits.chars().all(|c| c == '0');
    }

    // Float or decimal integer.
    if stripped.contains('.') || stripped.contains('e') || stripped.contains('E') {
        // Float form (includes exponential notation such as `0e0`).
        stripped.parse::<f64>().map(|v| v == 0.0).unwrap_or(false)
    } else {
        // Decimal integer form.
        stripped.parse::<u128>().map(|v| v == 0).unwrap_or(false)
    }
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

    /// F-P6-L03 (LOW) — BC-2.14.004 {PC-001}/{INV-004}
    ///
    /// `from_secs_f64(0f64)` must be flagged: `0f64` is the float zero literal with explicit
    /// type suffix (no decimal point). `is_zero_literal` must recognise this suffix form.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_zero_float() {
        let src = r#"
pub fn build_client() -> reqwest::Client {
    reqwest::ClientBuilder::new()
        .timeout(std::time::Duration::from_secs_f64(0f64))
        .build()
        .unwrap()
}
"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f64(0f64) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P6-L03 (LOW) — BC-2.14.004 {PC-001}/{INV-004}
    ///
    /// `from_secs_f32(0.)` must be flagged: `0.` is the bare trailing-dot float literal
    /// (shorthand for `0.0`). `is_zero_literal` must recognise this form.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f32_zero_dot() {
        let src = r#"
pub fn build_client() -> reqwest::Client {
    reqwest::ClientBuilder::new()
        .timeout(Duration::from_secs_f32(0.))
        .build()
        .unwrap()
}
"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f32(0.) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `00` decimal double-zero must be flagged.
    ///
    /// `00` is a valid Rust decimal literal evaluating to 0; the numeric normalisation in
    /// `is_zero_literal` (parse as u128 decimal) must recognise it as zero.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_double_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs(00)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs(00) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `0.00` float zero must be flagged.
    ///
    /// `0.00` is a float literal evaluating to 0.0; the numeric normalisation in
    /// `is_zero_literal` (parse as f64) must recognise it as zero.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_zero_point_zero_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs_f64(0.00)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f64(0.00) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `0x00` hex zero must be flagged.
    ///
    /// `0x00` is a hex integer literal evaluating to 0; the numeric normalisation in
    /// `is_zero_literal` (all hex post-prefix digits are `0`) must recognise it.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_hex_double_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs(0x00)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs(0x00) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    /// F-P7-M02 — BC-2.14.004 {PC-001}/{INV-004}: `0e0` exponential float zero must be flagged.
    ///
    /// `0e0` is a float literal in exponential notation evaluating to 0.0; the numeric
    /// normalisation in `is_zero_literal` (contains 'e' → parse as f64) must recognise it.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_exp_zero() {
        let src = "pub fn f() -> reqwest::Client { reqwest::ClientBuilder::new().timeout(Duration::from_secs_f64(0e0)).build().unwrap() }";
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "from_secs_f64(0e0) must be flagged as zero-duration timeout; got: {findings:?}"
        );
    }

    // ── F-P8-M01: Duration::new and Duration::default ────────────────────────

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `Duration::new(0, 0)` must be flagged.
    ///
    /// `Duration::new(0, 0)` is semantically identical to `Duration::ZERO`; both secs
    /// and nanos being zero literals must be detected as a zero-duration timeout.
    #[test]
    fn test_bc_2_14_004_flags_timeout_duration_new_zero_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::new(0, 0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-M01: .timeout(Duration::new(0, 0)) must be flagged \
             as zero-timeout; got: {findings:?}"
        );
    }

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `std::time::Duration::new(0, 0)` must be flagged.
    ///
    /// Fully-qualified `std::time::Duration::new(0, 0)` is semantically identical to
    /// `Duration::new(0, 0)` — the fully-qualified path form must also be detected.
    #[test]
    fn test_bc_2_14_004_flags_timeout_std_duration_new_zero_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(std::time::Duration::new(0, 0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-M01: .timeout(std::time::Duration::new(0, 0)) must be \
             flagged as zero-timeout; got: {findings:?}"
        );
    }

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `Duration::default()` must be flagged.
    ///
    /// `Duration::default()` always evaluates to `Duration::ZERO`; an explicit
    /// `Duration::default()` call as a timeout argument must be detected as zero.
    #[test]
    fn test_bc_2_14_004_flags_timeout_duration_default() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::default()).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-M01: .timeout(Duration::default()) must be flagged \
             as zero-timeout; got: {findings:?}"
        );
    }

    /// F-P8-M01 — BC-2.14.004 {PC-001}/{INV-004}: `Duration::new(30, 0)` must NOT be flagged.
    ///
    /// `Duration::new(30, 0)` is a valid 30-second timeout and must not be falsely flagged.
    /// The detection must require BOTH secs and nanos to be zero literals.
    #[test]
    fn test_bc_2_14_004_does_not_flag_duration_new_30_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::new(30, 0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            findings.is_empty(),
            "BC-2.14.004 F-P8-M01: .timeout(Duration::new(30, 0)) must NOT be flagged \
             (30-second timeout is valid); got: {findings:?}"
        );
    }

    // ── F-P8-L01: negative zero float ────────────────────────────────────────

    /// F-P8-L01 — BC-2.14.004 {PC-001}/{INV-004}: `from_secs_f64(-0.0)` must be flagged.
    ///
    /// `-0.0` parses as `Unary(Neg, Lit(0.0))` in the syn AST. The scanner must handle
    /// the case where the literal is wrapped in a unary negation.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f64_negative_zero() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::from_secs_f64(-0.0)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-L01: .timeout(Duration::from_secs_f64(-0.0)) must be \
             flagged as zero-timeout (negative zero is zero); got: {findings:?}"
        );
    }

    /// F-P8-L01 — BC-2.14.004 {PC-001}/{INV-004}: `from_secs_f32(-0.)` must be flagged.
    ///
    /// `-0.` is the bare trailing-dot float negative zero literal; the scanner must
    /// recognise it as zero through the negative zero handling path.
    #[test]
    fn test_bc_2_14_004_flags_timeout_from_secs_f32_negative_zero_dot() {
        let src = r#"pub fn f() -> reqwest::Client {
    reqwest::ClientBuilder::new().timeout(Duration::from_secs_f32(-0.)).build().unwrap()
}"#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "BC-2.14.004 {{PC-001}} F-P8-L01: .timeout(Duration::from_secs_f32(-0.)) must be \
             flagged as zero-timeout (negative zero is zero); got: {findings:?}"
        );
    }

    /// F-P16-MED-002 — BC-2.14.004 {PC-001}: brace-group argument in a builder chain must
    /// not terminate the scan before `.build()` is reached.
    ///
    /// When a builder method takes a brace-group argument (e.g. `.default_headers({…})`),
    /// the previous `BraceGroup => break` would stop scanning before `.build()`, causing a
    /// false-negative: the missing `.timeout()` was not reported.  The fix changes the arm
    /// to `{}` (continue) so the `;` boundary arm still terminates cross-statement
    /// contamination while brace-group method arguments no longer interrupt the scan.
    #[test]
    fn test_timeout_scanner_brace_group_in_builder_chain_does_not_break_scan() {
        // BC-2.14.004 {PC-001}: brace-group arguments in a builder chain must not
        // terminate the scan before .build() is reached.
        let src = r#"
        fn build_client() -> reqwest::Client {
            reqwest::ClientBuilder::new()
                .default_headers({
                    let mut h = ::reqwest::header::HeaderMap::new();
                    h
                })
                .build()
                .unwrap()
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "builder chain with brace-group arg and no .timeout() must be flagged"
        );
    }

    #[test]
    fn test_timeout_scanner_bracket_group_in_builder_chain_does_not_break_scan() {
        // BC-2.14.004 PC-001: vec!-repeat expressions containing `;` inside a builder
        // chain must not terminate the scan before `.build()` is reached.
        let src = r#"
        use std::net::SocketAddr;
        fn build_client(addr: SocketAddr) -> reqwest::Client {
            reqwest::ClientBuilder::new()
                .resolve_to_addrs("host", &vec![addr; 2])
                .build()
                .unwrap()
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "builder chain with vec![..;n] arg and no .timeout() must be flagged"
        );
    }

    #[test]
    fn test_timeout_scanner_paren_group_in_builder_chain_does_not_break_scan() {
        // BC-2.14.004 PC-001: paren-delimited vec! repeat must not terminate the scan.
        let src = r#"
        use std::net::SocketAddr;
        fn build_client(addr: SocketAddr) -> reqwest::Client {
            reqwest::ClientBuilder::new()
                .resolve_to_addrs("host", &vec!(addr; 2))
                .build()
                .unwrap()
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "builder chain with vec!(..;n) arg and no .timeout() must be flagged"
        );
    }

    #[test]
    fn test_timeout_scanner_match_arms_violation_first_is_flagged() {
        // BC-2.14.004 PC-001: a violating chain in a match arm must be flagged even
        // when a later arm has a compliant chain (cross-chain verdict leakage).
        let src = r#"
        fn build_client(fast: bool) -> reqwest::Client {
            match fast {
                true  => reqwest::ClientBuilder::new().build().unwrap(),
                false => reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .build()
                    .unwrap(),
            }
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "violating chain in first match arm must be flagged even when second arm is compliant"
        );
    }

    #[test]
    fn test_timeout_scanner_match_arms_compliant_first_is_not_flagged() {
        // The reverse ordering: compliant chain first, violating chain second.
        // The scan should still flag the violating arm.
        let src = r#"
        fn build_client(fast: bool) -> reqwest::Client {
            match fast {
                true  => reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .build()
                    .unwrap(),
                false => reqwest::ClientBuilder::new().build().unwrap(),
            }
        }
    "#;
        let findings = scan_for_timeout_violations_in_source(src, "test.rs");
        assert!(
            !findings.is_empty(),
            "violating chain in second match arm must be flagged even when first arm is compliant"
        );
    }

    // ── Depth-asymmetry false-negative regression tests ──────────────────────
    //
    // The syn AST visitor naturally handles depth correctly: each `.build()` call is
    // analyzed by walking its own receiver chain. A nested inner builder inside an
    // argument is a separate subexpression tree and does not affect the outer chain.

    /// Depth-asymmetry false-negative — paren-nested inner builder.
    ///
    /// Outer chain has no `.timeout()`.  Inner chain (inside `.proxy(make_proxy(…))`)
    /// has `.timeout()`.  The syn visitor must not credit the inner timeout to the
    /// outer chain; each chain is analyzed independently.
    ///
    /// Expected: outer chain is flagged (at least 1 finding).
    #[test]
    fn test_timeout_scanner_nested_inner_builder_in_paren_outer_missing_timeout_is_flagged() {
        let src = r#"
            fn build_client() -> reqwest::Client {
                reqwest::ClientBuilder::new()
                    .proxy(make_proxy(
                        reqwest::ClientBuilder::new()
                            .timeout(std::time::Duration::from_secs(30))
                            .build()
                            .unwrap()
                    ))
                    .build()
                    .unwrap()
            }
        "#;
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
        assert!(
            !findings.is_empty(),
            "outer chain with no .timeout() should be flagged even when a nested inner builder \
             has .timeout(); inner timeout must not credit the outer chain"
        );
    }

    /// Depth-asymmetry false-negative — brace-nested inner builder.
    ///
    /// Outer chain has no `.timeout()`.  Inner chain inside a brace-group argument
    /// (`.default_headers({{ … }})`) has `.timeout()`.  The syn visitor must not credit
    /// the inner timeout to the outer chain.
    ///
    /// Expected: outer chain is flagged (at least 1 finding).
    #[test]
    fn test_timeout_scanner_nested_inner_builder_in_brace_outer_missing_timeout_is_flagged() {
        let src = r#"
            fn build_client() -> reqwest::Client {
                reqwest::ClientBuilder::new()
                    .default_headers({
                        let _ = reqwest::ClientBuilder::new()
                            .timeout(std::time::Duration::from_secs(30))
                            .build()
                            .unwrap();
                        Default::default()
                    })
                    .build()
                    .unwrap()
            }
        "#;
        let findings =
            scan_for_timeout_violations_in_source(src, "crates/pregolya-core/src/http.rs");
        assert!(
            !findings.is_empty(),
            "outer chain with no .timeout() should be flagged even when a brace-nested inner \
             builder has .timeout(); inner timeout must not credit the outer chain"
        );
    }

    /// Depth-asymmetry stability test — outer depth-0 `.timeout()` is still credited
    /// after the syn rewrite.
    ///
    /// Outer chain: compliant — `.timeout(30s)` at depth 0 before `.build()`.
    /// Inner chain inside `.proxy(make_proxy(…))`: `reqwest::ClientBuilder::new().build()`
    /// with no `.timeout()`.
    ///
    /// Expected: exactly 1 finding — only the inner non-compliant chain is flagged.
    /// The outer compliant chain must NOT produce an additional finding.
    #[test]
    fn test_timeout_scanner_outer_has_depth_zero_timeout_inner_missing_is_not_flagged() {
        // Outer chain: compliant (.timeout(30s) + .build()).
        // Inner chain: reqwest::ClientBuilder::new().build() — no timeout, has .build().
        // Expected: exactly 1 finding (inner chain); outer chain must not produce a finding.
        let src = r#"
            fn f() {
                reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .proxy(make_proxy(
                        reqwest::ClientBuilder::new()
                            .build()
                            .unwrap()
                    ))
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert_eq!(
            findings.len(),
            1,
            "outer chain with depth-0 .timeout() must not produce an additional finding; \
             inner chain without .timeout() must produce exactly 1 finding; got: {findings:?}"
        );
    }

    // ── F-P20-HIGH-001: function-reference base call ──────────────────────────

    /// F-P20-HIGH-001 regression — function-reference base call must not suppress
    /// detection of a following statement's violation.
    ///
    /// `reqwest::ClientBuilder::new` without call parens is a function reference
    /// (an `ExprPath` in the syn AST, not an `ExprCall`). The syn visitor processes
    /// each statement independently so the following `Client::builder().build()` is
    /// not skipped.
    ///
    /// Expected: `Client::builder().build()` with no `.timeout()` is flagged.
    #[test]
    fn test_timeout_scanner_function_reference_does_not_skip_following_violation() {
        // reqwest::ClientBuilder::new without call-parens is a function reference.
        // The syn visitor must not confuse it with a call or skip the following statement.
        // The Client::builder() chain that follows has no .timeout() → must be flagged.
        let src = r#"
            fn a() {
                let _ctor = reqwest::ClientBuilder::new;
                reqwest::Client::builder()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "a.rs");
        assert!(
            !findings.is_empty(),
            "Client::builder() with no .timeout() must be flagged even when a preceding \
             function-reference base call appears; got: {:?}",
            findings
        );
    }

    /// F-P20-HIGH-002 regression — inner builder with no .build() must not produce a
    /// false-positive by claiming the outer chain's .build().
    ///
    /// Outer chain is fully compliant: `.timeout(30s)` + `.build()`.
    /// Inner chain inside `.proxy(make_proxy(…))` argument: `reqwest::ClientBuilder::new()`
    /// with NO `.timeout()` and NO `.build()` of its own.
    /// BC-2.14.004 {PC-001} only requires `.timeout()` BEFORE `.build()`; an inner builder
    /// with no `.build()` has no timeout obligation.
    /// Expected: ZERO findings (no false positive on the inner builder).
    #[test]
    fn test_timeout_scanner_nested_inner_builder_no_build_does_not_false_positive() {
        // Outer chain: compliant (.timeout(30s) + .build()).
        // Inner chain inside proxy() arg: reqwest::ClientBuilder::new() with NO .timeout()
        // and NO .build().
        // The inner chain has no .build() obligation (BC-2.14.004 {PC-001} requires
        // .timeout() BEFORE .build()).
        // Expected: zero violations (the inner chain must NOT claim the outer .build()).
        let src = r#"
            fn f() {
                reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .proxy(make_proxy(reqwest::ClientBuilder::new()))
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            findings.is_empty(),
            "compliant outer chain with non-completing nested inner builder must not produce \
             a false-positive violation; got: {:?}",
            findings
        );
    }

    /// F-P20-HIGH-002 non-regression — outer chain with no .timeout() is still detected
    /// even when a nested inner builder inside a proxy argument has .timeout().
    ///
    /// Outer chain: NON-compliant (no `.timeout()`, has `.build()`).
    /// Inner chain inside `.proxy(make_proxy(…))`: has `.timeout()` but no `.build()`.
    /// The outer chain must be flagged regardless of the inner builder's timeout.
    #[test]
    fn test_timeout_scanner_outer_missing_timeout_with_nested_inner_is_flagged() {
        // Outer chain: NON-compliant (no .timeout(), has .build()).
        // Inner chain inside proxy() arg: has .timeout() at inner depth, no .build().
        // The outer chain must be flagged.
        let src = r#"
            fn g() {
                reqwest::ClientBuilder::new()
                    .proxy(make_proxy(reqwest::ClientBuilder::new()
                        .timeout(std::time::Duration::from_secs(30))))
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "g.rs");
        assert!(
            !findings.is_empty(),
            "outer chain with no .timeout() must be flagged even with a nested inner builder \
             that has .timeout(); got: {:?}",
            findings
        );
    }

    /// F-P21-MED-001 — non-reqwest ClientBuilder::new() must NOT be flagged.
    ///
    /// `mcp_sdk::ClientBuilder::new()` is not a reqwest builder; `classify_builder_constructor`
    /// returns `NonReqwest` and the syn visitor skips it.
    #[test]
    fn test_timeout_scanner_does_not_flag_non_reqwest_client_builder_new() {
        // mcp_sdk::ClientBuilder::new() is not a reqwest builder — must not be flagged.
        let src = r#"
            fn f() {
                mcp_sdk::ClientBuilder::new()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            findings.is_empty(),
            "non-reqwest ClientBuilder::new() must not be flagged; got: {:?}",
            findings
        );
    }

    /// Parenthesized base subexpression is now correctly detected (KNOWN-LIMITATION 4
    /// eliminated by the syn AST visitor).
    ///
    /// A parenthesized base subexpression — `(reqwest::ClientBuilder::new()).build()` —
    /// is represented as `ExprMethodCall { receiver: ExprParen { .. }, method: "build" }`.
    /// The syn visitor unwraps `ExprParen` when walking the chain, so the violation is
    /// correctly detected.
    #[test]
    fn test_timeout_scanner_parenthesized_base_subexpr_known_limitation() {
        // KL-4 eliminated: the syn AST visitor unwraps ExprParen when analyzing the chain.
        // (reqwest::ClientBuilder::new()).build() is now correctly flagged.
        let src = r#"
            fn f() {
                let c = (reqwest::ClientBuilder::new()).build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "parenthesized base subexpression (reqwest::ClientBuilder::new()).build() \
             must be flagged (KNOWN-LIMITATION 4 eliminated by syn AST visitor); got: {findings:?}"
        );
    }

    /// F-P22-MED-004 — `crate::Client::new()` must be flagged (Pattern A: direct construction).
    ///
    /// `crate` is a path-relative qualifier, not a third-party crate name.
    /// `classify_client_new` returns `Conservative` (not `NonReqwest`) for
    /// `crate::Client::new()` paths, so the violation is emitted.
    #[test]
    fn test_timeout_scanner_crate_qualified_client_new_is_flagged() {
        let src = r#"
            fn f() {
                crate::Client::new()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "crate::Client::new() must be flagged; got: {:?}",
            findings
        );
    }

    /// F-P22-MED-004 — `crate::ClientBuilder::new()` must be flagged (Pattern B: builder chain).
    ///
    /// `crate` is a path-relative qualifier, not a third-party crate name.
    /// `classify_builder_constructor` returns `Conservative` for `crate::ClientBuilder::new()`
    /// paths, so the violation is emitted.
    #[test]
    fn test_timeout_scanner_crate_qualified_client_builder_new_is_flagged() {
        let src = r#"
            fn f() {
                crate::ClientBuilder::new()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "crate::ClientBuilder::new() must be flagged; got: {:?}",
            findings
        );
    }

    /// F-P22-MED-004 — `crate::Client::builder()` must be flagged (Pattern B: builder chain).
    ///
    /// `crate` is a path-relative qualifier, not a third-party crate name.
    /// `classify_builder_constructor` returns `Conservative` for `crate::Client::builder()`
    /// paths, so the violation is emitted.
    #[test]
    fn test_timeout_scanner_crate_qualified_client_builder_is_flagged() {
        let src = r#"
            fn f() {
                crate::Client::builder()
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "crate::Client::builder() must be flagged; got: {:?}",
            findings
        );
    }

    /// Braced base subexpression is now correctly detected (KNOWN-LIMITATION 4
    /// eliminated by the syn AST visitor).
    ///
    /// `{ reqwest::ClientBuilder::new() }.build()` is represented as
    /// `ExprMethodCall { receiver: ExprBlock { stmts: [Expr(ExprCall, None)] }, method: "build" }`.
    /// The syn visitor unwraps the block's tail expression, so the violation is correctly detected.
    #[test]
    fn test_timeout_scanner_braced_base_subexpr_known_limitation() {
        // KL-4 eliminated: the syn AST visitor unwraps the block tail expression.
        // { reqwest::ClientBuilder::new() }.build() is now correctly flagged.
        let src = r#"
            fn f() {
                let c = { reqwest::ClientBuilder::new() }.build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "f.rs");
        assert!(
            !findings.is_empty(),
            "braced base subexpression {{ reqwest::ClientBuilder::new() }}.build() \
             must be flagged (KNOWN-LIMITATION 4 eliminated by syn AST visitor); got: {findings:?}"
        );
    }

    // ── F-P23-HIGH-001: reqwest::blocking surface detection ──────────────────

    /// F-P23-HIGH-001 — `reqwest::blocking::Client::new()` must be flagged.
    ///
    /// `classify_client_new` returns `Reqwest` when the path is `reqwest::blocking::Client::new()` —
    /// the syn visitor walks `ExprCall` and detects the full path including the `blocking`
    /// module segment.
    #[test]
    fn test_timeout_scanner_blocking_client_new_flagged() {
        let src = r#"
            fn f() -> reqwest::blocking::Client {
                reqwest::blocking::Client::new()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "reqwest::blocking::Client::new() must produce exactly 1 finding; got: {findings:?}"
        );
    }

    /// F-P23-HIGH-001 — `reqwest::blocking::ClientBuilder::new().build()` without
    /// `.timeout()` must be flagged.
    ///
    /// `classify_builder_constructor` returns `Reqwest` for `reqwest::blocking::ClientBuilder::new()`;
    /// `analyze_build_chain` confirms the chain lacks a valid `.timeout()` call.
    #[test]
    fn test_timeout_scanner_blocking_client_builder_no_timeout_flagged() {
        let src = r#"
            fn f() -> reqwest::blocking::Client {
                reqwest::blocking::ClientBuilder::new()
                    .build()
                    .unwrap()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "reqwest::blocking::ClientBuilder::new().build() without .timeout() must produce 1 finding; \
             got: {findings:?}"
        );
    }

    /// F-P23-HIGH-001 — `reqwest::blocking::Client::builder().build()` without
    /// `.timeout()` must be flagged.
    ///
    /// `classify_builder_constructor` returns `Reqwest` for `reqwest::blocking::Client::builder()`;
    /// `analyze_build_chain` confirms the chain lacks a valid `.timeout()` call.
    #[test]
    fn test_timeout_scanner_blocking_client_builder_flagged() {
        let src = r#"
            fn f() -> reqwest::blocking::Client {
                reqwest::blocking::Client::builder()
                    .build()
                    .unwrap()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "reqwest::blocking::Client::builder().build() without .timeout() must produce 1 finding; \
             got: {findings:?}"
        );
    }

    /// F-P23-HIGH-001 negative — `other_sdk::blocking::Client::new()` must NOT be flagged.
    ///
    /// The `blocking` module segment in a non-reqwest path must not be misidentified as
    /// reqwest. `classify_client_new` and `classify_builder_constructor` return `NonReqwest`
    /// when the path head is `other_sdk` (a definitive third-party crate ident), so the
    /// syn visitor skips it.
    #[test]
    fn test_timeout_scanner_other_sdk_blocking_not_flagged() {
        let src = r#"
            fn f() {
                other_sdk::blocking::Client::new();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            findings.is_empty(),
            "other_sdk::blocking::Client::new() must NOT be flagged; got: {findings:?}"
        );
    }

    // ── F-P24-HIGH-001: use-imported blocking head form detection ───────────

    /// F-P24-HIGH-001 — bare `blocking::Client::new()` (use-imported head form) must be flagged.
    ///
    /// When code does `use reqwest::blocking; blocking::Client::new()`, the path starts with
    /// `blocking`. `classify_client_new` returns `Conservative` for a bare `blocking` head
    /// (it could be a `use reqwest::blocking;` re-export), so the syn visitor emits a finding.
    #[test]
    fn test_timeout_scanner_blocking_head_client_new_flagged() {
        let src = r#"
            fn f() {
                blocking::Client::new()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "blocking::Client::new() (use-imported head form) must produce exactly 1 finding; \
             got: {findings:?}"
        );
    }

    /// F-P24-HIGH-001 — bare `blocking::ClientBuilder::new().build()` (use-imported head form)
    /// without `.timeout()` must be flagged.
    ///
    /// `classify_builder_constructor` returns `Conservative` for a bare `blocking` head;
    /// `analyze_build_chain` confirms the missing `.timeout()`, so the finding is emitted.
    #[test]
    fn test_timeout_scanner_blocking_head_client_builder_new_flagged() {
        let src = r#"
            fn f() {
                blocking::ClientBuilder::new()
                    .build()
                    .unwrap()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "blocking::ClientBuilder::new().build() without .timeout() must produce exactly 1 finding; \
             got: {findings:?}"
        );
    }

    /// F-P24-HIGH-001 — bare `blocking::Client::builder().build()` (use-imported head form)
    /// without `.timeout()` must be flagged.
    ///
    /// `classify_builder_constructor` returns `Conservative` for a bare `blocking` head;
    /// `analyze_build_chain` confirms the missing `.timeout()`, so the finding is emitted.
    #[test]
    fn test_timeout_scanner_blocking_head_client_builder_flagged() {
        let src = r#"
            fn f() {
                blocking::Client::builder()
                    .build()
                    .unwrap()
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "blocking::Client::builder().build() without .timeout() must produce exactly 1 finding; \
             got: {findings:?}"
        );
    }

    // ── F-P23-MED-005: self::/super::/Self:: qualifier pinning tests ─────────

    /// F-P23-MED-005 — `self::Client::new()` must be flagged (Pattern A: direct construction).
    ///
    /// `self` is a path-relative qualifier, not a third-party crate name.
    /// `classify_client_new` returns `Conservative` for `self::Client::new()` paths.
    /// This test pins the `self::` form to prevent regression.
    #[test]
    fn test_timeout_scanner_self_qualified_client_new_flagged() {
        let src = r#"
            fn f() {
                self::Client::new();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "self::Client::new() must be flagged (Pattern A: direct construction); got: {findings:?}"
        );
    }

    /// F-P23-MED-005 — `super::ClientBuilder::new().build()` without `.timeout()` must be
    /// flagged (Pattern B: builder chain).
    ///
    /// `super` is a path-relative qualifier. `classify_builder_constructor` returns
    /// `Conservative` for `super::ClientBuilder::new()` paths. Pins the `super::` form
    /// to prevent regression.
    #[test]
    fn test_timeout_scanner_super_qualified_client_builder_new_flagged() {
        let src = r#"
            fn f() {
                super::ClientBuilder::new().build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "super::ClientBuilder::new().build() without .timeout() must be flagged (Pattern B: builder chain); \
             got: {findings:?}"
        );
    }

    /// F-P23-MED-005 — `Self::Client::builder().build()` without `.timeout()` must be
    /// flagged (Pattern B: builder chain).
    ///
    /// `Self` is a path-relative qualifier (associated item resolution).
    /// `classify_builder_constructor` returns `Conservative` for `Self::Client::builder()`
    /// paths. Test name uses `self_type` (snake-case) to satisfy the non_snake_case lint;
    /// the fixture uses `Self::` (capital).
    #[test]
    fn test_timeout_scanner_self_type_qualified_client_builder_flagged() {
        let src = r#"
            fn f() {
                Self::Client::builder().build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert_eq!(
            findings.len(),
            1,
            "Self::Client::builder().build() without .timeout() must be flagged (Pattern B: builder chain); \
             got: {findings:?}"
        );
    }

    // ── F-P25-HIGH-001: macro body scanning ──────────────────────────────────

    /// F-P25-HIGH-001 — `reqwest::Client::new()` inside `thread_local!{}` must be flagged.
    ///
    /// `thread_local!` is opaque to the syn AST visitor; `visit_item_macro` delegates
    /// to `scan_macro_tokens_for_timeout_violations` which scans the flat token stream.
    /// Pattern A (direct construction) is always flagged in macro context.
    #[test]
    fn test_timeout_checker_detects_reqwest_client_in_thread_local() {
        let src = r#"
            thread_local! {
                static CLIENT: reqwest::Client = reqwest::Client::new();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "reqwest::Client::new() inside thread_local!{{}} must be flagged; got: {findings:?}"
        );
    }

    /// F-P25-HIGH-001 — `reqwest::ClientBuilder::new().build()` inside `lazy_static!{}` without
    /// `.timeout()` must be flagged.
    ///
    /// `lazy_static!` is opaque to the syn AST visitor; the macro scanner detects Pattern B
    /// (builder chain) when `.build()` appears before `.timeout()` in the token stream.
    #[test]
    fn test_timeout_checker_detects_builder_in_lazy_static() {
        let src = r#"
            lazy_static::lazy_static! {
                static ref CLIENT: reqwest::Client =
                    reqwest::ClientBuilder::new().build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "reqwest::ClientBuilder::new().build() inside lazy_static!{{}} must be flagged; got: {findings:?}"
        );
    }

    /// F-P25-HIGH-001 negative — `reqwest::ClientBuilder::new().timeout(...).build()` inside
    /// `lazy_static!{}` must NOT be flagged.
    ///
    /// The macro scanner finds `.timeout()` before `.build()` in the token stream and correctly
    /// suppresses the finding.
    #[test]
    fn test_timeout_checker_detects_builder_with_timeout_in_lazy_static() {
        let src = r#"
            lazy_static::lazy_static! {
                static ref CLIENT: reqwest::Client =
                    reqwest::ClientBuilder::new()
                        .timeout(std::time::Duration::from_secs(30))
                        .build()
                        .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            findings.is_empty(),
            "reqwest::ClientBuilder::new().timeout(...).build() inside lazy_static!{{}} \
             must NOT be flagged; got: {findings:?}"
        );
    }

    // ── F-P25-HIGH-002: Client::default() and ClientBuilder::default() detection ──

    /// F-P25-HIGH-002 — `reqwest::Client::default()` must be flagged.
    ///
    /// `classify_client_new` returns `Reqwest` for `reqwest::Client::default()` paths;
    /// `visit_expr_call` emits a finding (Pattern A: direct construction).
    #[test]
    fn test_timeout_checker_detects_client_default_qualified() {
        let src = r#"
            fn f() {
                let _c = reqwest::Client::default();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "reqwest::Client::default() must be flagged; got: {findings:?}"
        );
    }

    /// F-P25-HIGH-002 — bare `Client::default()` (use-imported) must be flagged conservatively.
    ///
    /// `classify_client_new` returns `Conservative` for a bare 2-segment `Client::default()`
    /// path; `visit_expr_call` emits a finding.
    #[test]
    fn test_timeout_checker_detects_client_default_bare() {
        let src = r#"
            fn f() {
                let _c = Client::default();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "bare Client::default() must be flagged conservatively; got: {findings:?}"
        );
    }

    /// F-P25-HIGH-002 — `reqwest::ClientBuilder::default().build()` without `.timeout()` must
    /// be flagged.
    ///
    /// `classify_builder_constructor` returns `Reqwest` for `reqwest::ClientBuilder::default()`;
    /// `analyze_build_chain` finds no valid `.timeout()` and emits a finding.
    #[test]
    fn test_timeout_checker_detects_builder_default_qualified() {
        let src = r#"
            fn f() {
                let _c = reqwest::ClientBuilder::default().build().unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "reqwest::ClientBuilder::default().build() without .timeout() must be flagged; \
             got: {findings:?}"
        );
    }

    /// F-P25-HIGH-002 negative — `reqwest::ClientBuilder::default().timeout(...).build()` must
    /// NOT be flagged.
    ///
    /// `analyze_build_chain` finds a valid non-zero `.timeout()` before `.build()` and suppresses
    /// the finding.
    #[test]
    fn test_timeout_checker_detects_builder_default_with_timeout() {
        let src = r#"
            fn f() {
                let _c = reqwest::ClientBuilder::default()
                    .timeout(std::time::Duration::from_secs(30))
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            findings.is_empty(),
            "reqwest::ClientBuilder::default().timeout(...).build() must NOT be flagged; \
             got: {findings:?}"
        );
    }

    // ── F-P25-LOW-003: tokio::test attribute recognition ─────────────────────

    /// F-P25-LOW-003 — functions annotated with `#[tokio::test]` must not have their
    /// body scanned for violations.
    ///
    /// `visit_item_fn` checks whether the last segment of each attribute path is `"test"`,
    /// which covers both `#[test]` and `#[tokio::test]` (and `#[async_std::test]`, etc.).
    #[test]
    fn test_timeout_checker_ignores_tokio_test_fns() {
        let src = r#"
            #[tokio::test]
            async fn my_test() {
                let _c = reqwest::Client::new();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            findings.is_empty(),
            "#[tokio::test] fn body must not be scanned for violations; got: {findings:?}"
        );
    }

    // ── F-P25-OBS-001: last .timeout() wins (monotonic-OR fix) ───────────────

    /// F-P25-OBS-001 — a `.timeout(Duration::ZERO)` appearing after a valid `.timeout()`
    /// must revoke the previously-set valid timeout.
    ///
    /// `analyze_build_chain` uses `has_valid_timeout: !is_zero` (last-wins semantics),
    /// not `has_valid_timeout || !is_zero` (monotonic-OR). The runtime honours the last-set
    /// value, so the chain `new().timeout(30s).timeout(ZERO).build()` is a violation.
    #[test]
    fn test_timeout_checker_last_zero_timeout_overrides_valid() {
        let src = r#"
            fn f() {
                let _c = reqwest::ClientBuilder::new()
                    .timeout(std::time::Duration::from_secs(30))
                    .timeout(std::time::Duration::ZERO)
                    .build()
                    .unwrap();
            }
        "#;
        let findings = scan_for_timeout_violations_in_source(src, "crates/lib.rs");
        assert!(
            !findings.is_empty(),
            "last .timeout(Duration::ZERO) must revoke a prior valid .timeout(); \
             chain must be flagged; got: {findings:?}"
        );
    }
}
