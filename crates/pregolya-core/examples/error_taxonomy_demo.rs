//! Error taxonomy demo — S-1.01 per-AC visual evidence.
//!
//! Exercises the public `pregolya-core` error API across all 16 acceptance
//! criteria for story S-1.01.
//! AC-005 has two clauses: the `assert_impl_all!` compile-time assertion (no runtime
//! output) and the `Error::source` runtime clause — the latter is demonstrated in
//! the `construction` section via `std::error::Error::source(&outer).is_some()` on
//! an error built with `.with_source(Arc::clone(&inner_arc))`.
//! AC-006 (`assert_not_impl_any!(PregolyaError: Default)`) is now externally verified
//! here via `static_assertions::assert_not_impl_any!` — this example is an external
//! compilation unit, so the assertion proves the guarantee on the external API surface.
//!
//! | Section          | ACs covered                                                                         |
//! |------------------|-------------------------------------------------------------------------------------|
//! | module-level     | AC-005 (assert_impl_all — compile-time + external confirmation), AC-006 (assert_not_impl_any — compile-time + external confirmation) |
//! | `construction`   | AC-001 (struct/new), AC-005 (Error::source runtime clause), AC-007 (non_exhaustive::new), AC-008 (Arc clone) |
//! | `enums`          | AC-002 (Component), AC-003 (Category), AC-004 (RetryHint), AC-016 (Category::default_retry_hint — BC-2.14.001 {INV-004}) |
//! | `rfc7807`        | AC-009 (to_problem), AC-010 (JSON), AC-011 (http_status), AC-012 (content-type), AC-013 (sync), AC-014 (retry_hint fmt), AC-015 (code immutable) |
//!
//! Usage:
//! ```text
//! cargo run -p pregolya-core --example error_taxonomy_demo
//! cargo run -p pregolya-core --example error_taxonomy_demo -- construction
//! cargo run -p pregolya-core --example error_taxonomy_demo -- enums
//! cargo run -p pregolya-core --example error_taxonomy_demo -- rfc7807
//! ```

#![allow(clippy::print_stdout)]

use std::sync::Arc;
use std::time::Duration;

use pregolya_core::error::{
    Category, Component, PROBLEM_JSON_CONTENT_TYPE, PregolyaError, RetryHint,
};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // AC-006: PregolyaError does not implement Default.
    // Verified externally — this example is an external compilation unit, so this assertion
    // proves the guarantee on the external API surface (stronger than in-crate test).
    static_assertions::assert_not_impl_any!(pregolya_core::PregolyaError: Default);
    static_assertions::assert_impl_all!(pregolya_core::PregolyaError: std::error::Error, Send, Sync);
    println!("=== AC-005: PregolyaError: Error + Send + Sync ===");
    println!(
        "  assert_impl_all!(PregolyaError: std::error::Error, Send, Sync) — verified externally"
    );
    println!();
    println!("=== AC-006: PregolyaError: not Default ===");
    println!("  assert_not_impl_any!(PregolyaError: Default) — verified externally");
    println!();

    let section = std::env::args().nth(1);
    let run_all = section.is_none();
    let section_str = section.as_deref().unwrap_or("");

    if run_all || section_str == "construction" {
        demo_construction();
    }
    if run_all || section_str == "enums" {
        demo_enums();
    }
    if run_all || section_str == "rfc7807" {
        demo_rfc7807()?;
    }
    Ok(())
}

// ─── Section 1: Construction & Display & Arc Source Chain ───────────────────

fn demo_construction() {
    println!();
    println!("=== AC-001 / AC-007: Construction & Display ===");
    println!();

    // AC-001: struct-literal construction (valid within the crate; external callers use ::new)
    // This example crate is external to pregolya-core, so we use PregolyaError::new.
    let err = PregolyaError::new(
        Component::Core,
        Category::Val,
        RetryHint::Never,
        "E-CORE-001",
        "Invalid ContentBlock type 'x'",
    );

    // Display format: "[<code>] <message>"
    println!("Display:  {err}");
    println!("  .code:     {}", err.code());
    println!("  .message:  {}", err.message);
    println!("  .category: {:?}", err.category);
    println!("  .component:{:?}", err.component);
    println!("  .retry:    {:?}", err.retry_hint);
    println!(
        "  .source:   {:?}",
        std::error::Error::source(&err).is_some()
    );
    println!();

    // Second example: Sys/Maybe — the 14th Category (SYS per error-taxonomy.md §Error Categories)
    // E-SBXD-010 CanonicalizationFailed: SYS category, Component::Sbxd (per error-taxonomy.md)
    let sys_err = PregolyaError::new(
        Component::Sbxd,
        Category::Sys,
        RetryHint::Maybe,
        "E-SBXD-010",
        "CanonicalizationFailed: cannot resolve path '/tmp/link': EACCES: Permission denied",
    );
    println!("Sys (14th Category): {sys_err}");
    println!("  .category: {:?}", sys_err.category);
    println!("  .retry:    {:?}", sys_err.retry_hint);
    println!();

    // AC-008: Arc source chain + Clone semantics
    println!("=== AC-008: Arc Source Chain + Clone ===");
    println!();

    let inner = PregolyaError::new(
        Component::Chkpt,
        Category::Durability,
        RetryHint::Maybe,
        "E-CHKPT-001",
        "checkpoint write failed",
    );
    let inner_arc: Arc<dyn std::error::Error + Send + Sync> = Arc::new(inner);

    // ADR-010 Canon Class 1: use `.with_source(arc)` to chain a causal error.
    // Direct field assignment is not permitted from outside the crate.
    // E-GRAPH-001 InvalidUpdateError: CONCURRENCY category (concurrent writes to LastValue channel)
    let outer = PregolyaError::new(
        Component::Graph,
        Category::Concurrency,
        RetryHint::Never,
        "E-GRAPH-001",
        "concurrent writes to LastValue channel",
    )
    .with_source(Arc::clone(&inner_arc));

    println!("\n=== AC-005: Error + Send + Sync / Error::source runtime clause ===");
    println!("Outer:  {outer}");
    println!(
        "  source present: {}",
        std::error::Error::source(&outer).is_some()
    );
    println!(
        "  source message: {}",
        std::error::Error::source(&outer)
            .map(|s| s.to_string())
            .unwrap_or_default()
    );

    // Clone the outer error — Arc::clone increments refcount; inner need not be Clone
    let outer_cloned = outer.clone();
    println!(
        "  source preserved after clone: {}",
        std::error::Error::source(&outer_cloned).is_some()
    );
    println!();
}

// ─── Section 2: Enum Axes & RetryHint ───────────────────────────────────────

fn demo_enums() {
    println!("=== AC-002: Component Axis (18 named + Custom = 19 total) ===");
    println!();

    let named_variants = [
        Component::Core,
        Component::Graph,
        Component::Chkpt,
        Component::Traj,
        Component::Server,
        Component::Prov,
        Component::Mcp,
        Component::Split,
        Component::Sbxd,
        Component::Retry,
        Component::Cron,
        Component::Memory,
        Component::Budget,
        Component::Tmpl,
        Component::Srlz,
        Component::Vs,
        Component::Embed,
        Component::Tools,
    ];
    print!("  Named ({}): ", named_variants.len());
    for v in &named_variants {
        print!("{v:?} ");
    }
    println!();

    // AC-002: Custom variant — demonstrate actual construction and ProblemDetail emission
    let custom_comp = Component::Custom("newcrate".to_string());
    println!("  Custom:    {custom_comp:?}");
    let custom_err = PregolyaError::new(
        custom_comp,
        Category::Internal,
        RetryHint::Never,
        "E-newcrate-001",
        "custom component demo",
    );
    let custom_prob = custom_err.to_problem();
    println!(
        "  Custom component in ProblemDetail: component={:?}",
        custom_prob.component
    );
    println!(
        "  Total variants: {} (18 named + 1 Custom)",
        named_variants.len() + 1
    );
    println!();

    println!("=== AC-003: Category Axis (14 variants incl. Sys) ===");
    println!();

    let all_categories = [
        Category::Val,
        Category::Auth,
        Category::Rate,
        Category::Timeout,
        Category::Transport,
        Category::Internal,
        Category::Durability,
        Category::Policy,
        Category::Tool,
        Category::Concurrency,
        Category::Security,
        Category::Tenancy,
        Category::Exec,
        Category::Sys, // SYS per error-taxonomy.md §Error Categories
    ];
    print!("  All 14: ");
    for cat in &all_categories {
        print!("{cat:?} ");
    }
    println!();
    println!("  Sys is the 14th (INTERNAL-tier, HTTP 500, default RetryHint::Maybe)");
    println!();

    println!("=== AC-004: RetryHint Variants (3 total) ===");
    println!();

    let never = RetryHint::Never;
    let maybe = RetryHint::Maybe;
    let later_30 = RetryHint::Later(Duration::from_secs(30));
    let later_zero = RetryHint::Later(Duration::ZERO); // EC-002: zero is valid sentinel

    println!("  Never:         {never:?}");
    println!("  Maybe:         {maybe:?}");
    println!("  Later(30s):    {later_30:?}");
    println!("  Later(0s):     {later_zero:?}  (Duration::ZERO sentinel — retry immediately)");
    if let RetryHint::Later(d) = later_30 {
        println!("  Inner duration accessible: {}s", d.as_secs());
    }
    println!();

    // AC-016: Category::default_retry_hint() per BC-2.14.001 {INV-004}
    // Enumerate all 14 categories — matching AC-003/AC-011 exhaustive convention.
    println!("=== AC-016: Category::default_retry_hint() per BC-2.14.001 {{INV-004}} ===");
    println!();
    let hint_map: &[(Category, &str)] = &[
        (Category::Val, "Never"),
        (Category::Auth, "Maybe"), // AUTH=Maybe per error-taxonomy.md §Error Categories
        (Category::Rate, "Later"),
        (Category::Timeout, "Later"),
        (Category::Transport, "Later"),
        (Category::Internal, "Never"),
        (Category::Durability, "Maybe"),
        (Category::Policy, "Never"),
        (Category::Tool, "Maybe"), // TOOL=Maybe per error-taxonomy.md §Error Categories
        (Category::Concurrency, "Never"), // CONCURRENCY=Never per error-taxonomy.md §Error Categories
        (Category::Security, "Never"),
        (Category::Tenancy, "Never"),
        (Category::Exec, "Never"),
        (Category::Sys, "Maybe"),
    ];
    let mut correct_count: u32 = 0;
    for (cat, expected_kind) in hint_map {
        let hint = cat.default_retry_hint();
        let actual_kind = match &hint {
            RetryHint::Never => "Never",
            RetryHint::Maybe => "Maybe",
            RetryHint::Later(_) => "Later",
            _ => "Unknown",
        };
        let ok = if actual_kind == *expected_kind {
            "OK"
        } else {
            "FAIL"
        };
        if ok == "OK" {
            correct_count += 1;
        }
        println!("  {:12?} -> {:?}  [{}]", cat, hint, ok);
    }
    println!();
    println!("  AC-016: {correct_count}/14 categories correct");
    println!();
}

// ─── Section 3: RFC-7807 Emission, http_status, Content-Type, Sync, Immutability ─

fn demo_rfc7807() -> Result<(), Box<dyn std::error::Error>> {
    println!("=== AC-009 / AC-010 / AC-014: RFC-7807 to_problem() — Validation (Val/Never) ===");
    println!();

    let val_err = PregolyaError::new(
        Component::Core,
        Category::Val,
        RetryHint::Never,
        "E-CORE-001",
        "Invalid ContentBlock type 'x'",
    );
    let problem_val = val_err.to_problem();
    let json_val = serde_json::to_string_pretty(&problem_val)?;
    println!("ProblemDetail (Val / Never):");
    println!("{json_val}");
    println!();

    // Rate / Later(30s) — covers retry_hint canonical form "later:30"
    println!("=== AC-009 / AC-014: RFC-7807 to_problem() — Rate Limit (Rate/Later(30s)) ===");
    println!();

    let rate_err = PregolyaError::new(
        Component::Prov,
        Category::Rate,
        RetryHint::Later(Duration::from_secs(30)),
        "E-PROV-001",
        "Provider rate limited",
    );
    let problem_rate = rate_err.to_problem();
    let json_rate = serde_json::to_string_pretty(&problem_rate)?;
    println!("ProblemDetail (Rate / Later(30s)):");
    println!("{json_rate}");
    println!();

    // Sys / Maybe — 14th category (v1.12)
    println!("=== AC-003 / AC-009: RFC-7807 — System (Sys/Maybe, 14th Category) ===");
    println!();

    // E-SBXD-010 CanonicalizationFailed: SYS category, Component::Sbxd (per error-taxonomy.md)
    let sys_err = PregolyaError::new(
        Component::Sbxd,
        Category::Sys,
        RetryHint::Maybe,
        "E-SBXD-010",
        "CanonicalizationFailed: cannot resolve path '/tmp/link': EACCES: Permission denied",
    );
    let problem_sys = sys_err.to_problem();
    let json_sys = serde_json::to_string_pretty(&problem_sys)?;
    println!("ProblemDetail (Sys / Maybe — title must be \"System\"):");
    println!("{json_sys}");
    println!();

    // AC-011: HTTP status mapping — all 14 categories, no 200
    println!("=== AC-011: HTTP Status Mapping (all 14 categories, no 200) ===");
    println!();

    let status_map: &[(Category, u16)] = &[
        (Category::Val, 400),
        (Category::Auth, 401),
        (Category::Policy, 403),
        (Category::Security, 403),
        (Category::Rate, 429),
        (Category::Concurrency, 409),
        (Category::Tenancy, 409),
        (Category::Tool, 422),
        (Category::Transport, 502),
        (Category::Timeout, 504),
        (Category::Durability, 500),
        (Category::Internal, 500),
        (Category::Exec, 500),
        (Category::Sys, 500),
    ];

    let mut all_non_200 = true;
    for (cat, expected_status) in status_map {
        let err = PregolyaError::new(
            Component::Core,
            cat.clone(),
            RetryHint::Never,
            "E-CORE-001",
            "status check",
        );
        let status = err.http_status();
        let ok = if status == *expected_status {
            "OK"
        } else {
            "FAIL"
        };
        if status == 200 {
            all_non_200 = false;
        }
        println!("  {:12?} -> HTTP {:3}  [{}]", cat, status, ok);
    }
    println!();
    println!("  No category returns 200: {all_non_200}");
    println!();

    // AC-012: Content-Type constant
    println!("=== AC-012: Content-Type Constant ===");
    println!();
    println!("  PROBLEM_JSON_CONTENT_TYPE = \"{PROBLEM_JSON_CONTENT_TYPE}\"");
    let is_rfc7807 = PROBLEM_JSON_CONTENT_TYPE == "application/problem+json";
    println!("  is RFC-7807 value (not application/json): {is_rfc7807}");
    println!();

    // AC-013: Synchronous context — to_problem() needs no async runtime
    println!("=== AC-013: Synchronous Context (no async runtime) ===");
    println!();
    let sync_err = PregolyaError::new(
        Component::Core,
        Category::Val,
        RetryHint::Never,
        "E-CORE-001",
        "sync test",
    );
    let _ = sync_err.to_problem(); // called synchronously, no tokio::main needed
    println!("  to_problem() called without async runtime: OK");
    println!();

    // AC-015: Code immutability through to_problem()
    println!("=== AC-015: Code Immutability Through to_problem() ===");
    println!();
    let immutable_err = PregolyaError::new(
        Component::Core,
        Category::Val,
        RetryHint::Never,
        "E-CORE-001",
        "immutability check",
    );
    let original_code = immutable_err.code().to_owned();
    let problem = immutable_err.to_problem();
    let expected_uri = format!("urn:pregolya:error:{original_code}");
    let preserved = problem.type_uri == expected_uri;
    println!("  original code:  {original_code}");
    println!("  type_uri:       {}", problem.type_uri);
    println!("  code preserved: {preserved}");
    println!();
    Ok(())
}
