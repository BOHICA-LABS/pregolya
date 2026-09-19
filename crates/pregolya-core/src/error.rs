//! Error taxonomy for the pregolya library family.
//!
//! This module implements the two-dimensional error model at the heart of
//! pregolya: every error is a [`PregolyaError`] characterized by two orthogonal
//! axes — [`Component`] (which crate emitted the error) and [`Category`] (the
//! error class). Together they uniquely locate an error in the 17 × 14
//! taxonomy grid defined by ADR-010.
//!
//! # Key types
//!
//! - [`PregolyaError`] — the universal struct; holds component, category,
//!   [`RetryHint`], a stable `code` string (`E-<COMPONENT>-<NNN>`), a human
//!   message, and an optional `Arc`-wrapped causal source chain.
//! - [`ProblemDetail`] — the RFC-7807 `application/problem+json` projection.
//!   Produced by [`PregolyaError::to_problem`]; safe to serialize into HTTP
//!   responses. Excludes the source chain so internal errors never leak.
//! - [`RetryHint`] — semantic retry guidance: `Never` (caller must fix input),
//!   `Maybe` (transient; one retry is reasonable), or `Later(Duration)` (rate-
//!   limited; wait the given duration before retrying).
//!
//! # Redaction and source-chain design
//!
//! The `source` field uses `Option<Arc<dyn Error + Send + Sync>>` (not `Box`)
//! so that `#[derive(Clone)]` compiles without requiring the wrapped error to
//! implement `Clone` — `Arc::clone` increments a reference count.
//! `ProblemDetail` deliberately omits the source chain; HTTP responses only
//! carry `type_uri`, `title`, `detail`, and the `extensions` block.
//!
//! # RFC-7807 profile
//!
//! `type_uri` is a stable `urn:pregolya:error:<code>` URN. Monitoring rules
//! and API clients MUST key on `type_uri`, not `title` or `detail`.
//! `PROBLEM_JSON_CONTENT_TYPE` (`"application/problem+json"`) is exported for
//! use in `Content-Type` headers.

use std::fmt;
use std::sync::Arc;

use serde::{Deserialize, Serialize};

// ─── Constants ───────────────────────────────────────────────────────────────

/// Content-Type header value for RFC-7807 `application/problem+json` responses.
///
/// Use this constant wherever a `Content-Type: application/problem+json` header
/// must be set (e.g. `pregolya-server` error responses).
pub const PROBLEM_JSON_CONTENT_TYPE: &str = "application/problem+json";

// ─── Component ───────────────────────────────────────────────────────────────

/// Identifies which pregolya crate emitted the error.
///
/// 17 named variants cover the standard component set (as of ADR-010 D23).
/// [`Component::Custom`] provides forward-compatibility for new crates not yet
/// in the taxonomy.
#[non_exhaustive]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Component {
    /// `pregolya-core` (SS-01, SS-14, SS-19, SS-22)
    Core,
    /// `pregolya-graph` (SS-02)
    Graph,
    /// `pregolya-checkpoint` (SS-04)
    Chkpt,
    /// `pregolya-server` (SS-12)
    Server,
    /// Provider crates: `pregolya-openai`, `pregolya-anthropic`, `pregolya-ollama` (SS-03)
    Prov,
    /// `pregolya-mcp` (SS-09)
    Mcp,
    /// `pregolya-splitters` (SS-07)
    Split,
    /// `pregolya-sandbox` (SS-13)
    Sbxd,
    /// Retry subsystem (SS-16)
    Retry,
    /// Cron / scheduler subsystem (SS-17)
    Cron,
    /// `pregolya-memory` (SS-15)
    Memory,
    /// Budget governance (SS-10)
    Budget,
    /// Template / prompt subsystem — `pregolya-prompts` (SS-18)
    Tmpl,
    /// Serializable subsystem (SS-19)
    Srlz,
    /// Vector store subsystem (SS-21)
    Vs,
    /// Embeddings subsystem (SS-22)
    Embed,
    /// `pregolya-tools` (SS-08, SS-23)
    Tools,
    /// Forward-compatibility catch-all for crates not in the standard taxonomy.
    Custom(String),
}

// ─── Category ────────────────────────────────────────────────────────────────

/// Identifies the error class, independent of the originating component.
///
/// 14 variants as of BC-2.14.001/002 v1.12, which added [`Category::Sys`]
/// as the 14th category (OS-level syscall failure).
#[non_exhaustive]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Category {
    /// Validation failure — caller input or configuration error.
    Val,
    /// Authentication / authorization failure.
    Auth,
    /// Rate limit exceeded.
    Rate,
    /// Operation timed out.
    Timeout,
    /// Transport / network layer failure.
    Transport,
    /// Internal invariant violation — bug in library code.
    Internal,
    /// Durable storage failure.
    Durability,
    /// Policy violation — operation not permitted by configured policy.
    Policy,
    /// Tool execution failure.
    Tool,
    /// Concurrent operation conflict.
    Concurrency,
    /// Security gate violation.
    Security,
    /// Tenant isolation violation.
    Tenancy,
    /// Concurrent branch or subtask execution failure (library-layer only; added by D26).
    Exec,
    /// OS-level syscall failure (path resolution, process control, IPC).
    Sys,
}

// ─── RetryHint ───────────────────────────────────────────────────────────────

/// Semantic retry guidance carried by every [`PregolyaError`].
#[non_exhaustive]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RetryHint {
    /// Do not retry; the caller must fix their input or configuration.
    Never,
    /// Retry once; transient condition only.
    Maybe,
    /// Rate-limited; wait the given [`std::time::Duration`] then retry.
    Later(std::time::Duration),
}

impl Category {
    /// Returns the taxonomy-default [`RetryHint`] for this category.
    ///
    /// Authoritative source: `error-taxonomy.md §Error Categories` (Default RetryHint column).
    /// Per BC-2.14.001 {INV-004}, per-code divergence from these defaults must be
    /// documented explicitly; implementors must not invent new hint-category pairings.
    pub fn default_retry_hint(&self) -> RetryHint {
        match self {
            Category::Val => RetryHint::Never,
            Category::Auth => RetryHint::Maybe,
            Category::Rate => RetryHint::Later(std::time::Duration::from_secs(60)),
            Category::Timeout => RetryHint::Later(std::time::Duration::from_secs(30)),
            Category::Transport => RetryHint::Later(std::time::Duration::from_secs(30)),
            Category::Internal => RetryHint::Never,
            Category::Durability => RetryHint::Maybe,
            Category::Policy => RetryHint::Never,
            Category::Tool => RetryHint::Maybe,
            Category::Concurrency => RetryHint::Never,
            Category::Security => RetryHint::Never,
            Category::Tenancy => RetryHint::Never,
            Category::Exec => RetryHint::Never,
            Category::Sys => RetryHint::Maybe,
        }
    }
}

// ─── PregolyaError ───────────────────────────────────────────────────────────

/// Universal error type for the pregolya library family.
///
/// Every error emitted by a pregolya crate is an instance of `PregolyaError`
/// with two orthogonal dimensions (`component` × `category`), a retry hint,
/// a machine-readable code string, a human-readable message, and an optional
/// causal source chain.
///
/// # Construction
///
/// Code within `pregolya-core` may use struct-literal syntax (the `#[non_exhaustive]`
/// attribute does **not** restrict construction within the defining crate). External
/// callers must use [`PregolyaError::new`].
///
/// # Clone semantics
///
/// The `source` field is `Option<Arc<dyn Error + Send + Sync>>` (not `Box`), which
/// is what makes `#[derive(Clone)]` compile: `Arc::clone` increments a reference
/// count without requiring the inner error to implement `Clone`.
#[non_exhaustive]
#[derive(Debug, Clone)]
pub struct PregolyaError {
    /// The originating crate / component.
    pub component: Component,
    /// The error class.
    pub category: Category,
    /// Semantic retry guidance for the caller.
    pub retry_hint: RetryHint,
    /// Machine-readable error code following `E-<COMPONENT>-<NNN>` format
    /// (e.g. `"E-CORE-001"`). Immutable once assigned.
    pub code: String,
    /// Human-readable error description. MUST NOT contain credentials or
    /// API key material (DI-010).
    pub message: String,
    /// Optional causal error chain. Uses `Arc` — not `Box` — so that
    /// `#[derive(Clone)]` compiles without requiring `T: Clone`.
    /// MUST NOT be serialized into HTTP responses.
    pub source: Option<Arc<dyn std::error::Error + Send + Sync>>,
}

impl PregolyaError {
    /// Constructs a `PregolyaError`.
    ///
    /// This is the public external constructor. Code within `pregolya-core` may
    /// also use struct-literal syntax.
    pub fn new(
        component: Component,
        category: Category,
        retry_hint: RetryHint,
        code: impl Into<String>,
        message: impl Into<String>,
    ) -> Self {
        let code = code.into();
        let message = message.into();
        debug_assert!(
            {
                let parts: Vec<&str> = code.splitn(3, '-').collect();
                parts.len() == 3
                    && parts[0] == "E"
                    && !parts[1].is_empty()
                    && parts[1]
                        .chars()
                        .all(|c| c.is_ascii_uppercase() || c.is_ascii_digit())
                    && parts[2].len() == 3
                    && parts[2].chars().all(|c| c.is_ascii_digit())
            },
            "error code must follow E-COMPONENT-NNN format (uppercase alnum component, 3-digit numeric suffix), got: {code:?}"
        );
        Self {
            component,
            category,
            retry_hint,
            code,
            message,
            source: None,
        }
    }

    /// Produces an RFC-7807 [`ProblemDetail`] from this error.
    ///
    /// Synchronous — no Tokio runtime required. Safe to call in CLI tools and
    /// other non-async contexts.
    pub fn to_problem(&self) -> ProblemDetail {
        ProblemDetail {
            type_uri: format!("urn:pregolya:error:{}", self.code),
            title: category_title(&self.category).to_string(),
            detail: self.message.clone(),
            extensions: ProblemExtensions {
                retry_hint: retry_hint_str(&self.retry_hint),
                component: component_lowercase(&self.component),
            },
        }
    }

    /// Returns the categorical HTTP status code for this error's [`Category`].
    ///
    /// Maps each category to its default status code per BC-2.14.002 {PC-003}.
    /// Per-endpoint overrides (documented in BC-2.14.002 Known-overrides) are
    /// applied by `pregolya-server`, not here.
    pub fn http_status(&self) -> u16 {
        match self.category {
            Category::Val => 400,
            Category::Auth => 401,
            Category::Policy => 403,
            Category::Security => 403,
            Category::Rate => 429,
            Category::Concurrency => 409,
            Category::Tenancy => 409,
            Category::Tool => 422,
            Category::Transport => 502,
            Category::Timeout => 504,
            Category::Durability => 500,
            Category::Internal => 500,
            Category::Exec => 500, // D26: INTERNAL-tier fallback per ADR-010 §Category Axis Expansion
            Category::Sys => 500,  // BC-2.14.001/002 v1.12: INTERNAL-tier; OS syscall failure
        }
    }
}

impl fmt::Display for PregolyaError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "[{}] {}", self.code, self.message)
    }
}

impl std::error::Error for PregolyaError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        self.source
            .as_ref()
            .map(|arc| arc.as_ref() as &(dyn std::error::Error + 'static))
    }
}

// ─── ProblemDetail ───────────────────────────────────────────────────────────

/// RFC-7807 Problem Details for HTTP APIs.
///
/// Produced by [`PregolyaError::to_problem`]. Serializes to valid
/// `application/problem+json` JSON per RFC-7807 §3.
#[non_exhaustive]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProblemDetail {
    /// URN-format machine-readable type identifier: `urn:pregolya:error:<code>`.
    /// Stable; monitoring rules and API clients MUST use this field for error
    /// classification — not `title` or `detail`.
    #[serde(rename = "type")]
    pub type_uri: String,
    /// Humanized category name (e.g. `"Validation"` for [`Category::Val`]).
    pub title: String,
    /// Human-readable detail from [`PregolyaError::message`].
    pub detail: String,
    /// Extension fields required by the pregolya RFC-7807 profile.
    pub extensions: ProblemExtensions,
}

/// Extension fields for RFC-7807 problem detail responses.
#[non_exhaustive]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProblemExtensions {
    /// Canonical retry hint: `"never"`, `"maybe"`, or `"later:<seconds>"`.
    pub retry_hint: String,
    /// Lowercase component code (e.g. `"core"`, `"graph"`).
    pub component: String,
}

// ─── Private helpers ─────────────────────────────────────────────────────────

/// Returns the lowercase component code string for RFC-7807 `extensions.component`.
fn component_lowercase(component: &Component) -> String {
    match component {
        Component::Core => "core".to_string(),
        Component::Graph => "graph".to_string(),
        Component::Chkpt => "chkpt".to_string(),
        Component::Server => "server".to_string(),
        Component::Prov => "prov".to_string(),
        Component::Mcp => "mcp".to_string(),
        Component::Split => "split".to_string(),
        Component::Sbxd => "sbxd".to_string(),
        Component::Retry => "retry".to_string(),
        Component::Cron => "cron".to_string(),
        Component::Memory => "memory".to_string(),
        Component::Budget => "budget".to_string(),
        Component::Tmpl => "tmpl".to_string(),
        Component::Srlz => "srlz".to_string(),
        Component::Vs => "vs".to_string(),
        Component::Embed => "embed".to_string(),
        Component::Tools => "tools".to_string(),
        Component::Custom(s) => s.to_lowercase(),
    }
}

/// Returns the humanized category name for RFC-7807 `title`.
///
/// Authoritative source: `error-taxonomy.md §Error Categories` (Category column).
/// BC-2.14.002 {PC-001} specifies the field contract (`title: <humanized category name>`);
/// the concrete title strings are defined in the taxonomy.
///
/// | `Category` variant | Returned title |
/// |---------------------|----------------|
/// | `Val`          | `"Validation"` |
/// | `Auth`         | `"Authentication"` |
/// | `Rate`         | `"Rate Limit"` |
/// | `Timeout`      | `"Timeout"` |
/// | `Transport`    | `"Transport"` |
/// | `Internal`     | `"Internal"` |
/// | `Durability`   | `"Durability"` |
/// | `Policy`       | `"Policy"` |
/// | `Tool`         | `"Tool"` |
/// | `Concurrency`  | `"Concurrency"` |
/// | `Security`     | `"Security"` |
/// | `Tenancy`      | `"Tenancy"` |
/// | `Exec`         | `"Execution"` |
/// | `Sys`          | `"System"` |
fn category_title(category: &Category) -> &'static str {
    match category {
        Category::Val => "Validation",
        Category::Auth => "Authentication",
        Category::Rate => "Rate Limit",
        Category::Timeout => "Timeout",
        Category::Transport => "Transport",
        Category::Internal => "Internal",
        Category::Durability => "Durability",
        Category::Policy => "Policy",
        Category::Tool => "Tool",
        Category::Concurrency => "Concurrency",
        Category::Security => "Security",
        Category::Tenancy => "Tenancy",
        Category::Exec => "Execution",
        Category::Sys => "System",
    }
}

/// Encodes [`RetryHint`] as the canonical string form for RFC-7807 extensions.
///
/// - [`RetryHint::Never`] → `"never"`
/// - [`RetryHint::Maybe`] → `"maybe"`
/// - [`RetryHint::Later(d)`] → `"later:<whole_seconds>"` (e.g. `"later:30"`)
fn retry_hint_str(hint: &RetryHint) -> String {
    match hint {
        RetryHint::Never => "never".to_string(),
        RetryHint::Maybe => "maybe".to_string(),
        RetryHint::Later(d) => {
            // Ceiling-round non-zero sub-second durations so that Duration::ZERO
            // remains the sole source of "later:0" (the retry-immediately sentinel).
            // A 900ms wait would truncate to "later:0" without this fix (F3).
            let secs = if d.subsec_nanos() > 0 {
                d.as_secs().saturating_add(1)
            } else {
                d.as_secs()
            };
            format!("later:{secs}")
        }
    }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

#[cfg(test)]
#[allow(clippy::unwrap_used, clippy::expect_used, non_snake_case)]
mod tests {
    use super::*;
    use std::sync::Arc;
    use std::time::Duration;

    // ── Compile-time assertions (BC-2.14.001 {PC-006}, {PC-007}) ──────────────
    //
    // AC-005 (VP-BC214001-02): PregolyaError must implement Error + Send + Sync.
    // This assertion fails to COMPILE if the impl block is missing or incomplete.
    static_assertions::assert_impl_all!(PregolyaError: std::error::Error, Send, Sync);
    //
    // AC-006 (BC-2.14.001 {PC-007}): Default must NOT be implemented.
    // This assertion FAILS TO COMPILE if `#[derive(Default)]` is ever added.
    // No runtime test is needed — the compile-time assertion is the enforcement.
    static_assertions::assert_not_impl_any!(PregolyaError: Default);

    // ── BC-2.14.001 Tests ─────────────────────────────────────────────────────

    /// AC-001 (traces to BC-2.14.001 {PC-001}, TV-001)
    ///
    /// Verifies struct-literal construction within the defining crate; all five
    /// named fields and `source` are accessible by name. Then calls `to_string()`
    /// to verify `Display` outputs the expected message.
    #[test]
    fn test_BC_2_14_001_struct_construction() {
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Val,
            retry_hint: RetryHint::Never,
            code: "E-CORE-001".into(),
            message: "Invalid ContentBlock type 'x'".into(),
            source: None,
        };
        // Field access must work
        assert_eq!(err.code, "E-CORE-001");
        assert_eq!(err.message, "Invalid ContentBlock type 'x'");
        // TV-001: to_string() must contain the message
        let s = err.to_string();
        assert!(
            s.contains("Invalid ContentBlock type 'x'"),
            "Display must include the message"
        );
    }

    /// AC-001 (traces to BC-2.14.001 {PC-001}) — public constructor path
    ///
    /// `PregolyaError::new()` is the public external constructor; this test
    /// verifies it builds the struct without panicking and returns control.
    #[test]
    fn test_BC_2_14_001_new_constructor() {
        let err = PregolyaError::new(
            Component::Core,
            Category::Val,
            RetryHint::Never,
            "E-CORE-001",
            "Invalid ContentBlock type",
        );
        // F4 fix: assert all fields are assigned correctly by new()
        // Use distinguishable literals so code/message transposition fails
        assert_eq!(
            err.code, "E-CORE-001",
            "new() must assign code as first string arg"
        );
        assert_eq!(
            err.message, "Invalid ContentBlock type",
            "new() must assign message as second string arg"
        );
        assert_eq!(err.component, Component::Core);
        assert_eq!(err.category, Category::Val);
        assert!(matches!(err.retry_hint, RetryHint::Never));
        assert!(err.source.is_none(), "new() must set source to None");
    }

    /// AC-002 (traces to BC-2.14.001 {PC-002})
    ///
    /// Exhaustive match on all 18 `Component` variants (17 named + `Custom(String)`).
    /// Compiles without a wildcard arm — if any variant is added or removed the
    /// closure fails to compile. `#[non_exhaustive]` does NOT restrict exhaustive
    /// matching within the defining crate.
    #[test]
    fn test_BC_2_14_001_component_axis() {
        // Closure forces exhaustive match at compile time; closure is never called.
        let _verify_exhaustive = |c: Component| -> u8 {
            match c {
                Component::Core => 0,
                Component::Graph => 1,
                Component::Chkpt => 2,
                Component::Server => 3,
                Component::Prov => 4,
                Component::Mcp => 5,
                Component::Split => 6,
                Component::Sbxd => 7,
                Component::Retry => 8,
                Component::Cron => 9,
                Component::Memory => 10,
                Component::Budget => 11,
                Component::Tmpl => 12,
                Component::Srlz => 13,
                Component::Vs => 14,
                Component::Embed => 15,
                Component::Tools => 16,
                Component::Custom(_) => 17,
            }
        };
        // Spot-check first and last ordinals
        assert_eq!(_verify_exhaustive(Component::Core), 0);
        assert_eq!(_verify_exhaustive(Component::Custom("x".into())), 17);
        // 17 named variants (0–16) + 1 Custom = 18 total
    }

    /// AC-003 (traces to BC-2.14.001 {PC-003})
    ///
    /// Exhaustive match on all 14 `Category` variants (including `Exec` added by D26
    /// and `Sys` added by BC-2.14.001/002 v1.12).
    #[test]
    fn test_BC_2_14_001_category_axis() {
        let _verify_exhaustive = |c: Category| -> u8 {
            match c {
                Category::Val => 0,
                Category::Auth => 1,
                Category::Rate => 2,
                Category::Timeout => 3,
                Category::Transport => 4,
                Category::Internal => 5,
                Category::Durability => 6,
                Category::Policy => 7,
                Category::Tool => 8,
                Category::Concurrency => 9,
                Category::Security => 10,
                Category::Tenancy => 11,
                Category::Exec => 12, // D26 addition
                Category::Sys => 13,  // BC-2.14.001/002 v1.12 addition
            }
        };
        assert_eq!(_verify_exhaustive(Category::Val), 0);
        assert_eq!(_verify_exhaustive(Category::Exec), 12); // 13th variant (0-indexed)
        assert_eq!(_verify_exhaustive(Category::Sys), 13); // 14th variant (0-indexed)
    }

    /// AC-004 (traces to BC-2.14.001 {PC-004})
    ///
    /// `RetryHint` has exactly 3 variants. `Later(Duration)` constructs and the
    /// inner value is accessible. `Duration::ZERO` is valid (EC-003 sentinel).
    #[test]
    fn test_BC_2_14_001_retry_hint() {
        // Three-variant exhaustive match
        let _verify = |h: RetryHint| -> u8 {
            match h {
                RetryHint::Never => 0,
                RetryHint::Maybe => 1,
                RetryHint::Later(_) => 2,
            }
        };
        assert_eq!(_verify(RetryHint::Never), 0);
        assert_eq!(_verify(RetryHint::Maybe), 1);

        // Later with 30s backoff — inner Duration is accessible
        let later = RetryHint::Later(Duration::from_secs(30));
        if let RetryHint::Later(d) = later {
            assert_eq!(d, Duration::from_secs(30));
        } else {
            panic!("Expected RetryHint::Later");
        }

        // Duration::ZERO sentinel is valid (BC-2.14.001 EC-003)
        assert!(matches!(
            RetryHint::Later(Duration::ZERO),
            RetryHint::Later(_)
        ));
    }

    /// AC-005 (traces to BC-2.14.001 {PC-006}, VP-BC214001-02)
    ///
    /// `static_assertions::assert_impl_all!` compile-time assertion is at module
    /// level above. Runtime: `Error::source()` returns `Some(&inner)` when the
    /// `source` field is `Some(arc_inner)` — verifies the source chain is wired.
    #[test]
    fn test_BC_2_14_001_error_trait() {
        use std::error::Error;
        let inner: Arc<dyn Error + Send + Sync> = Arc::new(std::io::Error::other("inner"));
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Internal,
            retry_hint: RetryHint::Never,
            code: "E-CORE-002".into(),
            message: "wrapped error".into(),
            source: Some(Arc::clone(&inner)),
        };
        // Error::source() must return Some when source field is populated
        let src = Error::source(&err);
        assert!(
            src.is_some(),
            "source() must return Some when source field is populated"
        );
    }

    /// AC-007 (traces to BC-2.14.001 {PC-008})
    ///
    /// `PregolyaError` is `#[non_exhaustive]`. Struct-literal construction is
    /// permitted within the defining crate. `PregolyaError::new()` is the public
    /// external constructor; both paths are exercised here.
    #[test]
    fn test_BC_2_14_001_non_exhaustive() {
        // Within the defining crate: struct-literal construction is valid
        let _err = PregolyaError {
            component: Component::Graph,
            category: Category::Policy,
            retry_hint: RetryHint::Never,
            code: "E-GRAPH-001".into(),
            message: "test".into(),
            source: None,
        };
        // External-facing API: PregolyaError::new() must construct correctly
        let _err2 = PregolyaError::new(
            Component::Graph,
            Category::Policy,
            RetryHint::Never,
            "E-GRAPH-001",
            "test",
        );
    }

    /// AC-008 (traces to BC-2.14.001 EC-001)
    ///
    /// `source` field is `Option<Arc<dyn Error + Send + Sync>>`. `#[derive(Clone)]`
    /// compiles because `Arc::clone` increments a refcount — the inner error need
    /// not be `Clone`. Runtime: `source()` on the clone confirms the chain is preserved.
    #[test]
    fn test_BC_2_14_001_arc_source_clone() {
        use std::error::Error;
        let inner: Arc<dyn Error + Send + Sync> = Arc::new(std::io::Error::other("original"));
        let err = PregolyaError {
            component: Component::Graph,
            category: Category::Durability,
            retry_hint: RetryHint::Maybe,
            code: "E-GRAPH-002".into(),
            message: "chkpt error".into(),
            source: Some(Arc::clone(&inner)),
        };
        // Clone must succeed — Arc::clone increments refcount without T: Clone
        let err2 = err.clone();
        assert!(err2.source.is_some(), "cloned error must retain source");
        let _ = Error::source(&err2);
    }

    // ── BC-2.14.002 Tests ─────────────────────────────────────────────────────

    /// AC-009 (traces to BC-2.14.002 {PC-001}, TV-001)
    ///
    /// `to_problem()` for a `Val` error maps to the correct `ProblemDetail` fields:
    /// `type_uri`, `title: "Validation"`, `detail`, `extensions.retry_hint: "never"`,
    /// `extensions.component: "core"`.
    #[test]
    fn test_BC_2_14_002_to_problem_val() {
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Val,
            retry_hint: RetryHint::Never,
            code: "E-CORE-001".into(),
            message: "Invalid ContentBlock type 'x'".into(),
            source: None,
        };
        let problem = err.to_problem();
        assert_eq!(problem.type_uri, "urn:pregolya:error:E-CORE-001");
        assert_eq!(problem.title, "Validation");
        assert_eq!(problem.detail, "Invalid ContentBlock type 'x'");
        assert_eq!(problem.extensions.retry_hint, "never");
        assert_eq!(problem.extensions.component, "core");
    }

    /// AC-009 (traces to BC-2.14.002 {PC-001}, TV-002)
    ///
    /// `to_problem()` for a `Rate` error with `Later(30s)` produces
    /// `extensions.retry_hint: "later:30"` and HTTP status 429 (via `http_status()`).
    /// The `title` field is `"Rate Limit"` (grounded in `Category::Rate` doc:
    /// "Rate limit exceeded").
    #[test]
    fn test_BC_2_14_002_to_problem_rate() {
        let err = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::from_secs(30)),
            code: "E-PROV-001".into(),
            message: "RateLimited".into(),
            source: None,
        };
        let problem = err.to_problem();
        assert_eq!(problem.type_uri, "urn:pregolya:error:E-PROV-001");
        assert_eq!(problem.title, "Rate Limit");
        assert_eq!(problem.detail, "RateLimited");
        assert_eq!(problem.extensions.retry_hint, "later:30");
        assert_eq!(problem.extensions.component, "prov");
        assert_eq!(err.http_status(), 429);
    }

    /// AC-010 (traces to BC-2.14.002 {PC-002}, TV-003)
    ///
    /// `serde_json::to_string(&problem_detail)` produces valid JSON.
    /// Required RFC-7807 fields (`type`, `title`, `detail`) must be present with
    /// no null values.
    #[test]
    fn test_BC_2_14_002_rfc7807_json() {
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Internal,
            retry_hint: RetryHint::Never,
            code: "E-CORE-099".into(),
            message: "internal error".into(),
            source: None,
        };
        let problem = err.to_problem();
        let json = serde_json::to_string(&problem).expect("ProblemDetail must serialize to JSON");

        // Parse and validate structure (VP-BC214002-01: JSON schema validation)
        let v: serde_json::Value =
            serde_json::from_str(&json).expect("serialized JSON must be parseable");
        let obj = v
            .as_object()
            .expect("RFC-7807 response must be a JSON object");

        // Required RFC-7807 fields must be non-null strings
        assert!(
            obj.get("type")
                .and_then(serde_json::Value::as_str)
                .is_some(),
            "RFC-7807: 'type' must be a non-null string"
        );
        assert!(
            obj.get("title")
                .and_then(serde_json::Value::as_str)
                .is_some(),
            "RFC-7807: 'title' must be a non-null string"
        );
        assert!(
            obj.get("detail")
                .and_then(serde_json::Value::as_str)
                .is_some(),
            "RFC-7807: 'detail' must be a non-null string"
        );

        // Extension fields must be present and be strings
        let exts = obj
            .get("extensions")
            .and_then(serde_json::Value::as_object)
            .expect("extensions must be a JSON object");
        assert!(
            exts.get("retry_hint")
                .and_then(serde_json::Value::as_str)
                .is_some(),
            "extensions.retry_hint must be a string"
        );
        assert!(
            exts.get("component")
                .and_then(serde_json::Value::as_str)
                .is_some(),
            "extensions.component must be a string"
        );

        // No field in the top-level object is null
        for (key, val) in obj {
            assert!(!val.is_null(), "RFC-7807 field '{}' must not be null", key);
        }
    }

    /// BC-2.14.001 MUST-NOT + BC-2.14.002 EC-003 regression:
    /// The source chain MUST NOT appear in `to_problem()` JSON output.
    /// A future `detail_chain` extension would leak internal errors without this test failing.
    #[test]
    fn test_BC_2_14_002_source_chain_not_leaked() {
        use std::error::Error;
        const SENTINEL: &str = "LEAK-SENTINEL-DO-NOT-EMIT-7f3a9b1c";
        let inner_err = std::io::Error::other(SENTINEL);
        let err = PregolyaError {
            component: Component::Graph,
            category: Category::Durability,
            retry_hint: RetryHint::Never,
            code: "E-GRAPH-001".into(),
            message: "outer message".into(),
            source: Some(Arc::new(inner_err) as Arc<dyn Error + Send + Sync>),
        };
        let problem = err.to_problem();
        let json = serde_json::to_string(&problem).expect("ProblemDetail must serialize");
        assert!(
            !json.contains(SENTINEL),
            "source chain sentinel MUST NOT appear in ProblemDetail JSON (BC-2.14.001 MUST-NOT, BC-2.14.002 EC-003)"
        );
        // The outer message IS in the JSON (detail field)
        assert!(
            json.contains("outer message"),
            "outer message must be in detail"
        );
    }

    /// AC-011 (traces to BC-2.14.002 {PC-003}, VP-BC214002-02)
    ///
    /// Parameterized: every `Category` variant maps to the correct categorical
    /// HTTP status code. No variant returns 200.
    ///
    /// Mapping per BC-2.14.002 {PC-003} (including Exec→500 D26 fallback).
    #[test]
    fn test_BC_2_14_002_status_codes_all_categories() {
        let cases: &[(Category, u16)] = &[
            (Category::Val, 400),
            (Category::Auth, 401),
            (Category::Policy, 403),
            (Category::Rate, 429),
            (Category::Timeout, 504),
            (Category::Transport, 502),
            (Category::Concurrency, 409),
            (Category::Security, 403),
            (Category::Tenancy, 409),
            (Category::Durability, 500),
            (Category::Internal, 500),
            (Category::Tool, 422),
            (Category::Exec, 500), // D26: INTERNAL-tier fallback
            (Category::Sys, 500),  // BC-2.14.001/002 v1.12: INTERNAL-tier; OS syscall failure
        ];
        assert_eq!(
            cases.len(),
            14,
            "parameterized test must cover all 14 Category variants"
        );
        for (category, expected_status) in cases {
            let err = PregolyaError {
                component: Component::Core,
                category: category.clone(),
                retry_hint: RetryHint::Never,
                code: "E-CORE-001".into(),
                message: "parameterized status test".into(),
                source: None,
            };
            let status = err.http_status();
            assert_eq!(
                status, *expected_status,
                "Category::{:?} must map to HTTP {}",
                category, expected_status
            );
            assert_ne!(status, 200, "no Category variant may return 200");
        }
    }

    /// AC-012 (traces to BC-2.14.002 {PC-004}, TV-004)
    ///
    /// `PROBLEM_JSON_CONTENT_TYPE` constant equals `"application/problem+json"`
    /// (not `"application/json"`).
    #[test]
    fn test_BC_2_14_002_content_type_constant() {
        assert_eq!(
            PROBLEM_JSON_CONTENT_TYPE, "application/problem+json",
            "RFC-7807 Content-Type must be 'application/problem+json'"
        );
    }

    /// AC-013 (traces to BC-2.14.002 {PC-005})
    ///
    /// `to_problem()` is synchronous. Running in a plain `#[test]` (not
    /// `#[tokio::test]`) proves no async runtime is required.
    #[test]
    fn test_BC_2_14_002_sync_context() {
        // Not marked #[tokio::test] — verifies to_problem() needs no async runtime
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Val,
            retry_hint: RetryHint::Never,
            code: "E-CORE-001".into(),
            message: "sync test".into(),
            source: None,
        };
        let _problem = err.to_problem();
    }

    /// AC-014 (traces to BC-2.14.002 {INV-001}, {INV-003})
    ///
    /// `type_uri` uses stable `urn:pregolya:error:<code>` format.
    /// `extensions.retry_hint` uses canonical string representations:
    /// `"never"`, `"maybe"`, `"later:<seconds>"` (not `"30s"` or debug output).
    #[test]
    fn test_BC_2_14_002_retry_hint_format() {
        // "never"
        let err_never = PregolyaError {
            component: Component::Core,
            category: Category::Val,
            retry_hint: RetryHint::Never,
            code: "E-CORE-001".into(),
            message: "never".into(),
            source: None,
        };
        let p = err_never.to_problem();
        assert_eq!(p.extensions.retry_hint, "never");
        assert_eq!(p.type_uri, "urn:pregolya:error:E-CORE-001");

        // "maybe"
        let err_maybe = PregolyaError {
            component: Component::Core,
            category: Category::Transport,
            retry_hint: RetryHint::Maybe,
            code: "E-CORE-002".into(),
            message: "maybe".into(),
            source: None,
        };
        let p2 = err_maybe.to_problem();
        assert_eq!(p2.extensions.retry_hint, "maybe");

        // "later:30" — not "30s", not Duration debug repr
        let err_later = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::from_secs(30)),
            code: "E-PROV-001".into(),
            message: "later".into(),
            source: None,
        };
        let p3 = err_later.to_problem();
        assert_eq!(
            p3.extensions.retry_hint, "later:30",
            "canonical form is 'later:<seconds>' not '30s' or debug format"
        );

        // BC-2.14.002 EC-001: 60-second Later
        let err_60 = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::from_secs(60)),
            code: "E-PROV-002".into(),
            message: "rate 60".into(),
            source: None,
        };
        let p4 = err_60.to_problem();
        assert_eq!(p4.extensions.retry_hint, "later:60");

        // F3 regression: sub-second durations ceiling-round so they don't collide
        // with the "later:0" sentinel (Duration::ZERO = retry immediately).
        let err_subsec = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::from_millis(1)),
            code: "E-PROV-003".into(),
            message: "subsec".into(),
            source: None,
        };
        let p5 = err_subsec.to_problem();
        assert_eq!(
            p5.extensions.retry_hint, "later:1",
            "sub-second duration must ceiling-round to 1, not 0"
        );

        let err_subsec2 = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::from_millis(1500)),
            code: "E-PROV-004".into(),
            message: "subsec2".into(),
            source: None,
        };
        let p6 = err_subsec2.to_problem();
        assert_eq!(
            p6.extensions.retry_hint, "later:2",
            "1500ms must ceiling-round to 2 seconds"
        );

        // Duration::ZERO must still produce "later:0" (the retry-immediately sentinel)
        let err_zero2 = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::ZERO),
            code: "E-PROV-005".into(),
            message: "zero sentinel".into(),
            source: None,
        };
        let p7 = err_zero2.to_problem();
        assert_eq!(
            p7.extensions.retry_hint, "later:0",
            "Duration::ZERO must still produce 'later:0'"
        );
    }

    /// HIGH-001 regression: Duration::MAX must not overflow with saturating_add.
    ///
    /// Before the fix, `d.as_secs() + 1` on Duration::MAX panicked in debug mode.
    /// After the fix, `saturating_add(1)` on `u64::MAX` returns `u64::MAX`.
    #[test]
    fn test_BC_2_14_002_retry_hint_duration_max_no_overflow() {
        // Duration::MAX: as_secs() = u64::MAX = 18446744073709551615, subsec_nanos() = 999_999_999
        // saturating_add(1) on u64::MAX must return u64::MAX (not wrap to 0)
        let err = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::MAX),
            code: "E-PROV-099".into(),
            message: "duration max test".into(),
            source: None,
        };
        let prob = err.to_problem();
        let hint = &prob.extensions.retry_hint;
        assert_eq!(
            hint, "later:18446744073709551615",
            "Duration::MAX must produce later:u64::MAX (saturating_add), not wrap to 0"
        );
        assert_ne!(
            hint, "later:0",
            "Duration::MAX must not collide with retry-immediately sentinel"
        );
    }

    /// AC-015 (traces to BC-2.14.001 {INV-003})
    ///
    /// `err.code` is preserved immutably through `to_problem()`. The `type_uri`
    /// in the problem detail must equal `urn:pregolya:error:<original_code>`.
    #[test]
    fn test_BC_2_14_001_code_immutable() {
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Val,
            retry_hint: RetryHint::Never,
            code: "E-CORE-001".into(),
            message: "test".into(),
            source: None,
        };
        let original_code = err.code.clone();
        let problem = err.to_problem();
        assert_eq!(
            problem.type_uri,
            format!("urn:pregolya:error:{original_code}"),
            "type_uri must embed the original code unchanged"
        );
    }

    // ── Edge Case Tests ───────────────────────────────────────────────────────

    /// EC-001 (BC-2.14.001 EC-001, story edge case)
    ///
    /// Graph error wraps Chkpt error via `Arc` source chain. `Error::source()`
    /// on the outer error must return `Some`, confirming the source chain works.
    #[test]
    fn test_BC_2_14_001_ec001_arc_source_chain() {
        use std::error::Error;
        let inner_err = PregolyaError {
            component: Component::Chkpt,
            category: Category::Durability,
            retry_hint: RetryHint::Never,
            code: "E-CHKPT-001".into(),
            message: "checkpoint write failed".into(),
            source: None,
        };
        let outer_err = PregolyaError {
            component: Component::Graph,
            category: Category::Durability,
            retry_hint: RetryHint::Never,
            code: "E-GRAPH-001".into(),
            message: "graph persistence failed".into(),
            source: Some(Arc::new(inner_err) as Arc<dyn Error + Send + Sync>),
        };
        // source() must return Some
        let src = Error::source(&outer_err);
        assert!(
            src.is_some(),
            "outer error must chain to inner via source()"
        );
    }

    /// EC-002 (BC-2.14.001 EC-003): `RetryHint::Later(Duration::ZERO)` is valid.
    ///
    /// Sentinel for "retry immediately"; no construction error at zero duration.
    #[test]
    fn test_BC_2_14_001_ec002_retry_later_zero() {
        let hint = RetryHint::Later(Duration::ZERO);
        if let RetryHint::Later(d) = hint {
            assert_eq!(d.as_secs(), 0, "Duration::ZERO is a valid retry sentinel");
        } else {
            panic!("Expected RetryHint::Later");
        }
    }

    /// EC-003 (BC-2.14.001 EC-002): `Component::Custom("newcrate")` is accepted.
    ///
    /// `to_problem()` returns `extensions.component: "newcrate"`.
    /// The code field uses the canonical uppercase format `E-NEWCRATE-001`.
    #[test]
    fn test_BC_2_14_001_ec003_custom_component() {
        let err = PregolyaError {
            component: Component::Custom("newcrate".into()),
            category: Category::Internal,
            retry_hint: RetryHint::Never,
            code: "E-NEWCRATE-001".into(),
            message: "custom component error".into(),
            source: None,
        };
        let problem = err.to_problem();
        // component_lowercase("newcrate") = "newcrate" — Custom value is the display name
        assert_eq!(problem.extensions.component, "newcrate");
        // type_uri uses the code field verbatim (uppercase)
        assert_eq!(problem.type_uri, "urn:pregolya:error:E-NEWCRATE-001");
    }

    /// BC-2.14.001 TV-004: `anyhow` compatibility.
    ///
    /// `PregolyaError` wraps with `anyhow::Context`; `downcast_ref::<PregolyaError>()`
    /// must succeed after wrapping with `anyhow::Context`.
    #[test]
    fn test_BC_2_14_001_anyhow_compat() {
        use anyhow::Context as _;
        let pregolya_err = PregolyaError::new(
            Component::Core,
            Category::Val,
            RetryHint::Never,
            "E-CORE-001",
            "original error",
        );
        let wrapped: anyhow::Result<()> = Err(pregolya_err).context("additional context");
        let anyhow_err = wrapped.unwrap_err();
        assert!(
            anyhow_err.downcast_ref::<PregolyaError>().is_some(),
            "downcast to PregolyaError must succeed after anyhow wrap"
        );
    }

    /// BC-2.14.002 {INV-001} invariant: no `Category` variant returns HTTP 200.
    ///
    /// Invariant property test complementing `test_BC_2_14_002_status_codes_all_categories`.
    /// Verifies `http_status()` never returns 200 for any variant.
    #[test]
    fn test_BC_2_14_002_invariant_no_200_status() {
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
            Category::Sys,
        ];
        assert_eq!(
            all_categories.len(),
            14,
            "must cover all 14 Category variants"
        );
        for cat in &all_categories {
            let err = PregolyaError {
                component: Component::Core,
                category: cat.clone(),
                retry_hint: RetryHint::Never,
                code: "E-CORE-001".into(),
                message: "invariant check".into(),
                source: None,
            };
            let status = err.http_status();
            assert_ne!(status, 200, "Category {:?} must not return 200", cat);
        }
    }

    /// BC-2.14.001 {INV-004}: table-driven test for all 14 Category default RetryHints.
    ///
    /// Authoritative source: `error-taxonomy.md §Error Categories` (Default RetryHint column).
    #[test]
    fn test_BC_2_14_001_inv004_category_default_retry_hints() {
        let cases: &[(Category, &str)] = &[
            (Category::Val, "never"),
            (Category::Auth, "maybe"),
            (Category::Rate, "later"),
            (Category::Timeout, "later"),
            (Category::Transport, "later"),
            (Category::Internal, "never"),
            (Category::Durability, "maybe"),
            (Category::Policy, "never"),
            (Category::Tool, "maybe"),
            (Category::Concurrency, "never"),
            (Category::Security, "never"),
            (Category::Tenancy, "never"),
            (Category::Exec, "never"),
            (Category::Sys, "maybe"),
        ];
        assert_eq!(cases.len(), 14, "must cover all 14 Category variants");
        for (cat, expected_prefix) in cases {
            let hint = cat.default_retry_hint();
            let hint_str = match &hint {
                RetryHint::Never => "never",
                RetryHint::Maybe => "maybe",
                RetryHint::Later(_) => "later",
            };
            assert_eq!(
                hint_str, *expected_prefix,
                "Category::{cat:?} default_retry_hint() must be {expected_prefix}"
            );
        }
    }

    /// MED-003: debug_assert rejects malformed code — "E-" only has no component segment.
    #[test]
    #[should_panic(expected = "error code must follow E-COMPONENT-NNN format")]
    #[cfg(debug_assertions)]
    fn test_debug_assert_rejects_malformed_code() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-",
            "test",
        );
    }

    /// MED-003: debug_assert rejects lowercase component segment.
    #[test]
    #[should_panic(expected = "error code must follow E-COMPONENT-NNN format")]
    #[cfg(debug_assertions)]
    fn test_debug_assert_rejects_lowercase_component() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-core-001",
            "test",
        );
    }

    /// MED-005: debug_assert rejects two-digit numeric suffix.
    #[test]
    #[should_panic(expected = "error code must follow E-COMPONENT-NNN format")]
    #[cfg(debug_assertions)]
    fn test_debug_assert_rejects_two_digit_suffix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-01",
            "test",
        );
    }

    /// MED-005: debug_assert rejects four-digit numeric suffix.
    #[test]
    #[should_panic(expected = "error code must follow E-COMPONENT-NNN format")]
    #[cfg(debug_assertions)]
    fn test_debug_assert_rejects_four_digit_suffix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-1000",
            "test",
        );
    }

    /// MED-005: debug_assert rejects non-numeric suffix.
    #[test]
    #[should_panic(expected = "error code must follow E-COMPONENT-NNN format")]
    #[cfg(debug_assertions)]
    fn test_debug_assert_rejects_non_numeric_suffix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-ABC",
            "test",
        );
    }

    /// MED-005: debug_assert rejects wrong prefix letter.
    #[test]
    #[should_panic(expected = "error code must follow E-COMPONENT-NNN format")]
    #[cfg(debug_assertions)]
    fn test_debug_assert_rejects_wrong_prefix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "X-CORE-001",
            "test",
        );
    }

    /// MED-005: debug_assert accepts a valid code with a different component label.
    #[test]
    #[cfg(debug_assertions)]
    fn test_debug_assert_accepts_valid_code() {
        // Must not panic — "E-PROV-042" is a valid code
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-PROV-042",
            "test",
        );
    }

    /// MED-002: Exhaustive table-driven test for all 18 Component variants → expected
    /// `extensions.component` string emitted by `component_lowercase`.
    #[test]
    fn test_BC_2_14_002_component_mapping_exhaustive() {
        use std::collections::HashSet;
        // Table: (Component, expected extensions.component string)
        let cases: &[(Component, &str)] = &[
            (Component::Core, "core"),
            (Component::Graph, "graph"),
            (Component::Chkpt, "chkpt"),
            (Component::Server, "server"),
            (Component::Prov, "prov"),
            (Component::Mcp, "mcp"),
            (Component::Split, "split"),
            (Component::Sbxd, "sbxd"),
            (Component::Retry, "retry"),
            (Component::Cron, "cron"),
            (Component::Memory, "memory"),
            (Component::Budget, "budget"),
            (Component::Tmpl, "tmpl"),
            (Component::Srlz, "srlz"),
            (Component::Vs, "vs"),
            (Component::Embed, "embed"),
            (Component::Tools, "tools"),
            (Component::Custom("newcrate".to_string()), "newcrate"),
        ];
        assert_eq!(cases.len(), 18, "must cover all 18 Component variants");
        let mut seen: HashSet<&str> = HashSet::new();
        for (comp, expected) in cases {
            let err = PregolyaError {
                code: "E-TEST-001".to_string(),
                component: comp.clone(),
                category: Category::Internal,
                message: "test".to_string(),
                retry_hint: RetryHint::Never,
                source: None,
            };
            let prob = err.to_problem();
            assert_eq!(
                prob.extensions.component, *expected,
                "Component::{comp:?} must map to {expected:?}"
            );
            assert!(seen.insert(*expected), "duplicate mapping: {expected:?}");
        }
    }

    /// MED-002: Exhaustive table-driven test for all 14 Category variants → expected
    /// `title` string emitted by `category_title`.
    #[test]
    fn test_BC_2_14_002_category_title_exhaustive() {
        use std::collections::HashSet;
        // Table: (Category, expected problem.title string)
        let cases: &[(Category, &str)] = &[
            (Category::Val, "Validation"),
            (Category::Auth, "Authentication"),
            (Category::Rate, "Rate Limit"),
            (Category::Timeout, "Timeout"),
            (Category::Transport, "Transport"),
            (Category::Internal, "Internal"),
            (Category::Durability, "Durability"),
            (Category::Policy, "Policy"),
            (Category::Tool, "Tool"),
            (Category::Concurrency, "Concurrency"),
            (Category::Security, "Security"),
            (Category::Tenancy, "Tenancy"),
            (Category::Exec, "Execution"),
            (Category::Sys, "System"),
        ];
        assert_eq!(cases.len(), 14, "must cover all 14 Category variants");
        let mut seen: HashSet<&str> = HashSet::new();
        for (cat, expected) in cases {
            let err = PregolyaError {
                code: "E-TEST-001".to_string(),
                component: Component::Core,
                category: cat.clone(),
                message: "test".to_string(),
                retry_hint: RetryHint::Never,
                source: None,
            };
            let prob = err.to_problem();
            assert_eq!(
                prob.title, *expected,
                "Category::{cat:?} must map to title {expected:?}"
            );
            assert!(seen.insert(*expected), "duplicate title: {expected:?}");
        }
    }

    /// BC-2.14.001/002 v1.12 — Sys category: `to_problem()` yields title "System"
    /// and `http_status()` yields 500 (INTERNAL-tier; INV-001 no-200 guarantee).
    #[test]
    fn test_BC_2_14_001_002_sys_category() {
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Sys,
            retry_hint: RetryHint::Maybe,
            code: "E-CORE-014".into(),
            message: "syscall failed: ENOENT".into(),
            source: None,
        };
        // http_status must be 500 (INTERNAL-tier); must NOT be 200 (INV-001)
        let status = err.http_status();
        assert_eq!(status, 500, "Category::Sys must map to HTTP 500");
        assert_ne!(status, 200, "Category::Sys must not return 200 (INV-001)");
        // to_problem() title must be "System"
        let problem = err.to_problem();
        assert_eq!(
            problem.title, "System",
            "Category::Sys title must be 'System'"
        );
        assert_eq!(problem.type_uri, "urn:pregolya:error:E-CORE-014");
        assert_eq!(problem.extensions.retry_hint, "maybe");
    }
}
