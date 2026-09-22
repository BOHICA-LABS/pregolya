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
/// Scans `crates/**/*.rs` using syn AST analysis to detect `.unwrap()`,
/// `.expect(...)`, bare `assert!`/`assert_eq!`/`assert_ne!`/`panic!` (without
/// `# Panics` doc + BC-ID exemption), and wildcard/irrefutable-binding
/// `unreachable!()` arms outside `#[cfg(test)]` blocks (BC-2.14.003 §EC-007).
/// Exits non-zero on any violation (BC-2.14.003 {PC-004}/{PC-005}/{PC-006}).
pub fn run() {
    // Scan root is "crates/" only — xtask itself is excluded.
    // BC-2.14.003 {PC-004}/{PC-005} binds "non-test library code" in crates/;
    // xtask is a build-tool binary crate operating outside that scope.
    // xtask programmer-error guards (assert! in check_file_size etc.) are
    // intentionally exempt from the no-panic library rule.
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
        eprintln!(
            "ERROR: no-panic violations (unwrap/expect/bare-assert/panic!/wildcard-unreachable) in non-test library code (BC-2.14.003 §EC-007):"
        );
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
/// `_` wildcard, irrefutable binding (e.g. `other`, `ref other`, `mut other`),
/// `..` rest pattern, or an or-pattern containing any catch-all sub-pattern.
/// Named-variant arms (e.g. `Phase::Done`, `Ok(v)`) are NOT catch-alls.
///
/// **Safe-by-default**: any pattern not positively recognised as a
/// specific-variant/literal returns `true` (catch-all ⇒ deny Exemption 1).
/// This prevents new `syn::Pat` variants introduced in future syn releases
/// from silently opening false exemptions.
///
/// Binding mode does NOT change irrefutability: `ref other`, `mut other`, and
/// `ref mut other` are all irrefutable bindings that match every value not
/// covered by earlier arms (BC-2.14.003 §EC-007 pass-8 F-01).
fn is_catch_all_pat(pat: &syn::Pat) -> bool {
    match pat {
        // Definite catch-alls.
        syn::Pat::Wild(_) => true,
        syn::Pat::Rest(_) => true,

        // Pat::Ident is a catch-all iff it is a plain binding with no sub-pattern.
        // `by_ref` and `mutability` change binding mode but NOT irrefutability —
        // `ref other`, `mut other`, `ref mut other` are all catch-alls.
        // Only a sub-pattern (e.g. `name @ Variant`) makes the arm specific.
        // Uppercase-initial identifiers are enum/const names, not bindings.
        //
        // ACCEPTED FALSE NEGATIVE: uppercase-initial bare identifiers in pattern position
        // (e.g., `Category` in `match x { Category => unreachable!() }`) are exempted as
        // probable imported unit variants rather than catch-all bindings. This avoids
        // false positives when unqualified unit variants are used (e.g., `Val => ...`).
        // Consequence: a bare catch-all binding named `Other` (uppercase) evades the gate.
        // Accepted because: (a) Rust convention strongly associates uppercase identifiers
        // with types/variants, not bindings; (b) the false-negative risk is narrow
        // (would require an intentionally deceptive binding name). Pinned by test
        // test_BC_2_14_003_uppercase_binding_is_accepted_false_negative.
        //
        // Underscore-prefixed identifiers (`_other`, `_unused`) ARE catch-alls:
        // `_other =>` is irrefutable (matches any remaining value) even though the
        // `_` prefix suppresses the unused-variable warning. BC-2.14.003 EC-004
        // explicitly says `_other => unreachable!()` is NOT exempt.
        syn::Pat::Ident(p) => {
            p.subpat.is_none()
                && p.ident
                    .to_string()
                    .chars()
                    .next()
                    .map(|c| c == '_' || c.is_ascii_lowercase())
                    .unwrap_or(false)
                && !matches!(p.ident.to_string().as_str(), "true" | "false")
        }

        // Or-patterns: catch-all if ANY sub-pattern is a catch-all.
        syn::Pat::Or(p) => p.cases.iter().any(is_catch_all_pat),

        // Wrapper patterns that do not restrict the matched value set.
        syn::Pat::Reference(r) => is_catch_all_pat(&r.pat),
        syn::Pat::Paren(p) => is_catch_all_pat(&p.pat),

        // Positively recognised specific-variant/literal patterns — NOT catch-alls.
        syn::Pat::Path(_) => false,        // e.g. Phase::Done
        syn::Pat::TupleStruct(_) => false, // e.g. Ok(v), Err(e)
        syn::Pat::Struct(_) => false,      // e.g. Foo { field }
        syn::Pat::Lit(_) => false,         // e.g. 0, "str"
        syn::Pat::Tuple(_) => false,       // e.g. (a, b)
        syn::Pat::Range(_) => false,       // e.g. 0..=10
        syn::Pat::Slice(_) => false,       // e.g. [a, b]

        // Safe-by-default: any unrecognised pattern variant is conservatively
        // treated as a catch-all so the exemption is denied rather than granted.
        _ => true,
    }
}

/// Returns `true` if `s` contains a well-formed BC-ID matching `BC-\d+\.\d{2}\.\d{3}`.
///
/// Requires:
/// - `"BC-"` literal prefix
/// - one or more major-version decimal digits (`\d+`)
/// - literal `'.'`
/// - **exactly two** minor-version decimal digits (`\d{2}`)
/// - literal `'.'`
/// - **exactly three** patch decimal digits (`\d{3}`)
///
/// Implemented with char iteration — no external `regex` crate required.
pub(crate) fn is_valid_bc_id(s: &str) -> bool {
    let mut remaining = s;
    while let Some(pos) = remaining.find("BC-") {
        let after_prefix = &remaining[pos + 3..];
        if check_bc_id_shape(after_prefix) {
            return true;
        }
        remaining = &remaining[pos + 3..];
    }
    false
}

/// Validate the BC-ID shape starting immediately after the `"BC-"` prefix.
fn check_bc_id_shape(s: &str) -> bool {
    let mut chars = s.chars();

    // \d+ — one or more major-version digits
    let mut major_count = 0usize;
    loop {
        match chars.as_str().chars().next() {
            Some(c) if c.is_ascii_digit() => {
                chars.next();
                major_count += 1;
            }
            _ => break,
        }
    }
    if major_count == 0 {
        return false;
    }

    // literal '.'
    if chars.next() != Some('.') {
        return false;
    }

    // \d{2} — exactly two minor digits
    let m1 = chars.next();
    let m2 = chars.next();
    if !m1.is_some_and(|c| c.is_ascii_digit()) {
        return false;
    }
    if !m2.is_some_and(|c| c.is_ascii_digit()) {
        return false;
    }
    // Reject a third minor digit (would be \d{3}, not \d{2})
    if chars
        .as_str()
        .chars()
        .next()
        .is_some_and(|c| c.is_ascii_digit())
    {
        return false;
    }

    // literal '.'
    if chars.next() != Some('.') {
        return false;
    }

    // \d{3} — exactly three patch digits
    let p1 = chars.next();
    let p2 = chars.next();
    let p3 = chars.next();
    if !p1.is_some_and(|c| c.is_ascii_digit()) {
        return false;
    }
    if !p2.is_some_and(|c| c.is_ascii_digit()) {
        return false;
    }
    if !p3.is_some_and(|c| c.is_ascii_digit()) {
        return false;
    }
    // Reject a fourth patch digit (would be \d{4}, not \d{3})
    if chars
        .as_str()
        .chars()
        .next()
        .is_some_and(|c| c.is_ascii_digit())
    {
        return false;
    }

    true
}

/// Returns `true` when the assert/panic macro has a BC-ID in its **message argument**
/// (after the first top-level comma) that satisfies `BC-\d+\.\d{2}\.\d{3}`.
///
/// # Why message-only?
///
/// BC-2.14.003 EC-007 requires the BC-ID in the assert MESSAGE, not the condition.
/// `assert!(code.starts_with("BC-2.14.003"), "no id in msg")` must be FLAGGED —
/// the BC-ID is in the condition expression, not the message string.
///
/// # Top-level comma detection
///
/// The macro token stream is iterated at the TOP level only (proc_macro2 groups
/// parens/brackets/braces as `Group` tokens, so `foo(a, b)` in the condition
/// has no top-level commas). The first top-level `Punct(',')` separates the
/// condition from the message.
fn syn_macro_has_bc_id(mac: &syn::Macro) -> bool {
    use proc_macro2::TokenTree;
    let tokens_vec: Vec<TokenTree> = mac.tokens.clone().into_iter().collect();

    // Find the index of the first top-level comma (separates condition from message).
    let Some(comma_idx) = tokens_vec.iter().enumerate().find_map(|(i, tt)| {
        if let TokenTree::Punct(p) = tt
            && p.as_char() == ','
        {
            return Some(i);
        }
        None
    }) else {
        return false; // no comma → no message argument
    };

    // Stringify the message argument tokens (everything after the first comma).
    let message: String = tokens_vec[comma_idx + 1..]
        .iter()
        .map(|tt| tt.to_string())
        .collect::<Vec<_>>()
        .join("");

    is_valid_bc_id(&message)
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

    fn visit_trait_item_fn(&mut self, node: &'ast syn::TraitItemFn) {
        if syn_has_cfg_test(&node.attrs) {
            return;
        }
        let old_doc = self.fn_has_panics_doc;
        // A trait default method body is independently callable — the method may be
        // invoked at any time by any implementor, completely independently of the match
        // arm's evaluation context.  Save and clear arm_stack so that unreachable!
        // inside a trait default method nested within a named arm is evaluated without
        // match-arm context (BC-2.14.003 §PC-006 / §EC-007 pass-8 F-02).
        let old_arm_stack = std::mem::take(&mut self.arm_stack);
        self.fn_has_panics_doc = syn_has_panics_doc(&node.attrs);
        syn::visit::visit_trait_item_fn(self, node);
        self.fn_has_panics_doc = old_doc;
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
    }

    fn visit_stmt_macro(&mut self, node: &'ast syn::StmtMacro) {
        self.handle_macro_invocation(&node.mac);
    }

    fn visit_item_macro(&mut self, mac: &'ast syn::ItemMacro) {
        // Skip #[cfg(test)] item macros so that e.g. a thread_local! inside
        // a test module is not flagged.
        if syn_has_cfg_test(&mac.attrs) {
            return;
        }
        // KNOWN-LIMITATION: macro_rules! definition bodies are opaque token
        // streams; this scanner walks the tokens of the invocation but cannot
        // expand the macro at this point.  Complex nested macro patterns (e.g.
        // a macro_rules! arm whose output contains .unwrap()) are checked at
        // the call site (visit_expr_macro / visit_stmt_macro), not here.  Item
        // macros such as thread_local! and lazy_static! are scanned below.
        self.handle_macro_invocation(&mac.mac);
        syn::visit::visit_item_macro(self, mac);
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

        // MED-4: scan the macro's token stream for .unwrap()/.expect() method calls.
        // Macro arguments are opaque to syn's AST visitor — e.g. `.unwrap()` inside
        // `format!("{}", opt.unwrap())` is invisible to `visit_expr_method_call`.
        //
        // Coverage vs clippy: clippy's `unwrap_used` lint catches most of these.
        // The gate catches `.unwrap()`/`.expect()` in macro arguments in cases
        // clippy may not cover under all configurations, providing defense in depth.
        // Both gates are kept because they serve different enforcement roles.
        scan_method_calls_in_tokens(
            mac.tokens.clone().into_iter(),
            &mut self.findings,
            self.path,
        );
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
/// panic-path violations using the same scanner as the normal gate.
///
/// Purpose: verify that planted violation fixtures are correctly detected by
/// the gate (AC-017/Task-13, POL-31). Since violation fixtures intentionally
/// contain violations, a zero-violations result indicates the scanner is broken.
///
/// Called by `main()` when `argv == ["check-no-panic", "--fixture-mode", <dir>]`.
///
/// # Exit semantics
///
/// - Exit 0: scanner healthy — ≥1 fixture file had findings (violations found in fixtures).
/// - Exit 1: scanner broken — 0 fixture files had findings, no fixtures found,
///   or ≥1 fixture file could not be read (gate cannot certify scanner coverage).
///
/// CI self-test (plain call under `set -e`):
/// ```text
/// cargo xtask check-no-panic --fixture-mode <violations-dir>
/// ```
/// (exits 0 when the scanner correctly detects violations in the fixture directory).
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

    if !files_output.status.success() {
        eprintln!(
            "ERROR: file discovery command failed with status {}",
            files_output.status
        );
        exit(1);
    }

    let files_str = String::from_utf8_lossy(&files_output.stdout);
    let fixture_files: Vec<&str> = files_str.lines().collect();
    if fixture_files.is_empty() {
        eprintln!(
            "ERROR: check-no-panic --fixture-mode {dir}: \
             scanned 0 fixture files — gate cannot certify scanner coverage"
        );
        exit(1);
    }

    let total_fixtures = fixture_files.len();
    let mut all_findings: Vec<String> = Vec::new();
    let mut files_with_findings = 0usize;
    let mut files_unreadable = 0usize;

    for file_path in &fixture_files {
        let content = match std::fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(e) => {
                eprintln!(
                    "ERROR: check-no-panic --fixture-mode could not read fixture file {}: {}",
                    file_path, e
                );
                files_unreadable += 1;
                continue;
            }
        };
        // scan_for_panics_in_source exempts tests/ files EXCEPT fixtures/violations/.
        // For paths under the fixture dir that happen to contain tests/ (e.g.
        // xtask/tests/fixtures/violations/), the exceptions in scan_for_panics_in_source
        // ensure they are scanned.
        let findings = scan_for_panics_in_source(&content, file_path);
        if !findings.is_empty() {
            files_with_findings += 1;
        }
        all_findings.extend(findings);
    }

    if files_unreadable > 0 {
        eprintln!(
            "ERROR: check-no-panic --fixture-mode could not read {} fixture file(s) — \
             gate cannot certify scanner coverage",
            files_unreadable
        );
        std::process::exit(1);
    }

    // Compute the expected minimum: all fixture files except the known credential-only
    // fixtures (CREDENTIAL_FIXTURE_COUNT = 3) which are scanned by deny-bare-api-key,
    // not check-no-panic, and correctly produce no findings here.
    let min_expected = total_fixtures.saturating_sub(CREDENTIAL_FIXTURE_COUNT);
    match fixture_mode_verdict(total_fixtures, files_with_findings, Some(min_expected)) {
        Ok(msg) => {
            // Scanner healthy: violations found in fixtures as expected.
            // Exit 0 so CI can use a plain call under `set -e`.
            println!("check-no-panic --fixture-mode {dir}: violations found (BC-2.14.003):");
            for f in &all_findings {
                println!("  {f}");
            }
            println!("{msg}");
            std::process::exit(0);
        }
        Err(err) => {
            // Scanner broken: no violations found in violation fixtures.
            // Exit 1 to signal failure under `set -e`.
            eprintln!(
                "ERROR: 0/{total_fixtures} fixture files had findings — no-panic scanner is BROKEN \
                 (detected no violations in violation fixtures)."
            );
            eprintln!("{err}");
            std::process::exit(1);
        }
    }
}

/// Number of fixture files in the violations directory that are NOT no-panic violations
/// (e.g., credential-only fixtures scanned by `deny-bare-api-key`, not `check-no-panic`).
/// These files are legitimately skipped by the no-panic scanner and must not be counted
/// toward the expected minimum.
///
/// Kept as a named constant so a drop from 12/15 to e.g. 1/15 still trips the gate
/// while still allowing the 3 credential-only fixtures to remain in the same directory.
pub(crate) const CREDENTIAL_FIXTURE_COUNT: usize = 3;

/// Pure verdict helper for fixture-mode: returns `Ok(msg)` when the scanner is healthy,
/// or `Err(msg)` when it is broken.
///
/// - 0 files had findings → `Err` (scanner broken).
/// - `files_with_findings < min_expected` (when `min_expected` is `Some(n)`) → `Err`
///   (regression: fewer files than expected have findings, scanner may have regressed).
/// - Otherwise → `Ok`.
///
/// Extracted for testability — the exit(1) side-effect lives in `run_fixture_mode`.
pub(crate) fn fixture_mode_verdict(
    total_fixtures: usize,
    files_with_findings: usize,
    min_expected: Option<usize>,
) -> Result<String, String> {
    if files_with_findings == 0 {
        return Err(format!(
            "0/{total_fixtures} fixture files had findings — scanner BROKEN"
        ));
    }
    if let Some(min) = min_expected
        && files_with_findings < min
    {
        return Err(format!(
            "{files_with_findings}/{total_fixtures} fixture files had findings, \
             but expected at least {min} — scanner may have regressed"
        ));
    }
    Ok(format!(
        "fixture-mode: {files_with_findings}/{total_fixtures} fixture files had findings"
    ))
}

#[cfg(test)]
mod tests {
    use super::{CREDENTIAL_FIXTURE_COUNT, fixture_mode_verdict, scan_for_panics_in_source};

    /// F-P6-M01 (MED) — BC-2.14.003
    ///
    /// Lower-bound guard Err path: when the scanner finds fewer files with findings
    /// than the expected minimum, `fixture_mode_verdict` must return `Err` citing
    /// the expected minimum. This exercises the scanner-regression detection path.
    #[test]
    fn test_bc_2_14_003_fixture_mode_verdict_lower_bound_regression_detected() {
        // When scanner finds only 1/15 files with violations but minimum is 12,
        // the lower-bound guard must fire (scanner-regression scenario).
        let result = fixture_mode_verdict(15, 1, Some(12));
        assert!(
            result.is_err(),
            "1/15 with min=12 must be Err; got: {:?}",
            result
        );
        let msg = result.unwrap_err();
        assert!(
            msg.contains("expected at least 12") || msg.contains("12"),
            "error must cite expected minimum; got: {msg}"
        );
    }

    /// F-P6-M01 (MED) — BC-2.14.003
    ///
    /// Lower-bound guard Ok path: when `files_with_findings` exactly meets `min_expected`,
    /// `fixture_mode_verdict` must return `Ok` (boundary-satisfied).
    #[test]
    fn test_bc_2_14_003_fixture_mode_verdict_lower_bound_at_minimum_is_ok() {
        let result = fixture_mode_verdict(15, 12, Some(12));
        assert!(
            result.is_ok(),
            "12/15 with min=12 must be Ok; got: {:?}",
            result
        );
    }

    /// F-P6-M01 (MED) — BC-2.14.003
    ///
    /// CREDENTIAL_FIXTURE_COUNT coupling assertion — ensures the constant stays in sync
    /// with the actual credential-only fixtures in the violations directory. Adding a new
    /// credential-only fixture without updating the constant would cause the lower-bound
    /// guard to fire incorrectly (scanner falsely reported as regressed).
    ///
    /// `include_str!` causes a compile error if any fixture file is missing or renamed,
    /// making CREDENTIAL_FIXTURE_COUNT a compile-time constant coupled to the filesystem.
    /// Each fixture is also verified to produce zero no-panic findings, confirming it is
    /// truly a credential-only fixture and not a no-panic fixture.
    #[test]
    fn test_bc_2_14_003_credential_fixture_count_matches_fixture_dir() {
        // include_str! causes a compile error if any file is missing/renamed,
        // pinning CREDENTIAL_FIXTURE_COUNT to the actual filesystem state.
        // Each file is also verified to produce zero no-panic findings
        // (confirming it's truly a credential-only fixture, not a no-panic fixture).
        let fixtures: &[(&str, &str)] = &[
            (
                include_str!("../tests/fixtures/violations/violation_pub_crate_debug_derive.rs"),
                "violation_pub_crate_debug_derive.rs",
            ),
            (
                include_str!("../tests/fixtures/violations/violation_derive_deserialize.rs"),
                "violation_derive_deserialize.rs",
            ),
            (
                include_str!("../tests/fixtures/violations/violation_impl_display.rs"),
                "violation_impl_display.rs",
            ),
        ];
        assert_eq!(
            CREDENTIAL_FIXTURE_COUNT,
            fixtures.len(),
            "CREDENTIAL_FIXTURE_COUNT must equal number of credential-only fixtures"
        );
        for (content, name) in fixtures {
            let findings = scan_for_panics_in_source(content, name);
            assert!(
                findings.is_empty(),
                "credential-only fixture {name} must produce zero no-panic findings; got: {findings:?}"
            );
        }
    }

    /// F-P7-M01 — BC-2.14.003
    ///
    /// `visit_item_macro` override: `.unwrap()` inside a `thread_local!` item macro
    /// (or any other item-position macro such as `lazy_static!`) must be flagged.
    /// Previously, `PanicVisitor` had no `visit_item_macro` override so the token
    /// stream of item-position macros was never scanned.
    #[test]
    fn test_bc_2_14_003_item_macro_unwrap_is_flagged() {
        let src = r#"
thread_local! {
    static FOO: i32 = {
        let x: Option<i32> = None;
        x.unwrap()
    };
}
"#;
        let findings = scan_for_panics_in_source(src, "src/lib.rs");
        assert!(
            !findings.is_empty(),
            "unwrap in thread_local! item macro must be flagged; got: {findings:?}"
        );
    }
}
