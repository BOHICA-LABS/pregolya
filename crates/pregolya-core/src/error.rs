//! Error taxonomy for the pregolya library family.
//!
//! This module implements the two-dimensional error model at the heart of
//! pregolya: every error is a [`PregolyaError`] characterized by two orthogonal
//! axes — [`Component`] (which crate emitted the error) and [`Category`] (the
//! error class). Together they uniquely locate an error in the 18 × 14
//! taxonomy grid (ADR-010 §Component Axis Expansion (ADR-030), ADR-010 §Category Axis Expansion (SYS)).
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
//! carry `type_uri`, `title`, `detail`, and the top-level `retry_hint` / `component`
//! extension members (RFC-7807 §3.2).
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
/// 18 named variants cover the standard component set (as of ADR-010 §Component Axis Expansion (ADR-030)).
/// [`Component::Custom`] provides forward-compatibility for new crates not yet
/// in the taxonomy.
#[non_exhaustive]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Component {
    /// `pregolya-core` (SS-01, SS-14)
    Core,
    /// `pregolya-graph` (SS-02)
    Graph,
    /// `pregolya-checkpoint` (SS-04)
    Chkpt,
    /// `pregolya-checkpoint / checkpoint::trajectory` (SS-04)
    Traj,
    /// `pregolya-server` (SS-12)
    Server,
    /// Provider crates: `pregolya-openai`, `pregolya-anthropic`, `pregolya-ollama` (SS-08)
    Prov,
    /// `pregolya-mcp` (SS-09)
    Mcp,
    /// `pregolya-splitters` (SS-07)
    Split,
    /// `pregolya-sandbox` (SS-13)
    Sbxd,
    /// Retry subsystem (SS-16)
    Retry,
    /// Cron / scheduler subsystem (SS-12)
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
    /// `pregolya-tools` (SS-23)
    Tools,
    /// Forward-compatibility catch-all for crates not in the standard taxonomy.
    Custom(String),
}

// ─── Category ────────────────────────────────────────────────────────────────

/// Identifies the error class, independent of the originating component.
///
/// 14 variants as of ADR-010 §Category Axis Expansion (SYS), which added [`Category::Sys`]
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
    /// Authoritative source for variant kinds: `error-taxonomy.md §Error Categories`
    /// (Default RetryHint column). `error-taxonomy.md §Error Categories` pins the
    /// Rate / Timeout / Transport `Later` defaults at 60 s / 30 s / 30 s and anchors
    /// them to this function (§Error Categories footnote F8-04); callers may pass a
    /// context-specific `RetryHint::Later(d)`, and per-code catalog rows override the
    /// category default per the RetryHint precedence rule.
    /// Per BC-2.14.001 {INV-004}, per-code divergence must be documented explicitly;
    /// implementors must not invent new hint-category pairings.
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
/// callers must use [`PregolyaError::new`] — struct-literal construction by external
/// crates is compiler-rejected (`E0639`; `#[non_exhaustive]` guarantee) — and chain a
/// causal source via [`PregolyaError::with_source`]. Direct field assignment to `source`
/// is not permitted from outside the crate (ADR-010 §Decision).
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
    /// (e.g. `"E-CORE-001"`). Immutable once assigned. Private to enforce
    /// immutability via the [`PregolyaError::code()`] accessor.
    code: String,
    /// Human-readable error description. MUST NOT contain credentials or
    /// API key material (DI-010).
    pub message: String,
    /// Optional causal error chain. Uses `Arc` — not `Box` — so that
    /// `#[derive(Clone)]` compiles without requiring `T: Clone`.
    /// Set via [`PregolyaError::with_source`]; read via [`std::error::Error::source`].
    /// MUST NOT be serialized into HTTP responses.
    source: Option<Arc<dyn std::error::Error + Send + Sync>>,
}

/// The 18 lowercase identifiers emitted by [`component_lowercase()`] for named variants.
/// Used by the Custom-collision guard in [`PregolyaError::new`] and its test.
/// Must be kept in sync with [`component_lowercase()`].
const NAMED_COMPONENT_LOWERCASE: [&str; 18] = [
    "core",   // Component::Core
    "graph",  // Component::Graph
    "chkpt",  // Component::Chkpt
    "traj",   // Component::Traj
    "server", // Component::Server
    "prov",   // Component::Prov
    "mcp",    // Component::Mcp
    "split",  // Component::Split
    "sbxd",   // Component::Sbxd
    "retry",  // Component::Retry
    "cron",   // Component::Cron
    "memory", // Component::Memory
    "budget", // Component::Budget
    "tmpl",   // Component::Tmpl
    "srlz",   // Component::Srlz
    "vs",     // Component::Vs
    "embed",  // Component::Embed
    "tools",  // Component::Tools
];

impl PregolyaError {
    /// Constructs a `PregolyaError`.
    ///
    /// This is the public external constructor. Code within `pregolya-core` may
    /// also use struct-literal syntax.
    ///
    /// # Panics
    ///
    /// Panics if `code` does not match the `E-<COMPONENT>-NNN` format (uppercase letter prefix,
    /// component segment of ASCII alphanumerics, hyphens, and underscores (`[A-Za-z0-9_-]`) with
    /// no leading/trailing/consecutive separators, exactly three-digit numeric suffix).
    ///
    /// Also panics if `component` is `Component::Custom(name)` and:
    /// - `name` is empty, contains non-ASCII-alphanumeric characters other than `-` or `_`,
    ///   or has leading/trailing/consecutive separator characters (`is_valid_component_segment` fails); or
    /// - `name` lowercased aliases a named component identifier (BC-2.14.001 EC-002).
    ///
    /// Also panics if the COMPONENT segment of `code` does not match `component` (case-insensitive).
    ///
    /// These are programmer-error invariants; they indicate a bug in the calling code.
    ///
    /// Note: construction does NOT validate `code`↔`category` consistency against the error
    /// taxonomy. Each `E-<COMPONENT>-NNN` code maps to a single category in the taxonomy, but
    /// that constraint is enforced by the code-registry CI gate in story S-1.02
    /// (VP-BC214001-01), not at construction time.
    pub fn new(
        component: Component,
        category: Category,
        retry_hint: RetryHint,
        code: impl Into<String>,
        message: impl Into<String>,
    ) -> Self {
        let code = code.into();
        let message = message.into();
        if !(code.starts_with("E-")
            && code[2..].rsplit_once('-').is_some_and(|(mid, suffix)| {
                is_valid_component_segment(mid)
                    && suffix.len() == 3
                    && suffix.chars().all(|c| c.is_ascii_digit())
            }))
        {
            unreachable!(
                "BC-2.14.001 EC-006: code must follow E-<COMPONENT>-NNN format where COMPONENT may contain alphanumeric, hyphen, underscore; got: {}",
                code
            );
        }
        // BC-2.14.001 EC-002: Custom names must be valid segments and must not alias named
        // component identifiers when lowercased (e.g. Custom("Core") → "core" aliases
        // Component::Core on wire). Both checks share the is_valid_component_segment predicate.
        if let Component::Custom(ref name) = component {
            if !is_valid_component_segment(name) {
                unreachable!(
                    "BC-2.14.001 EC-002: Component::Custom name '{}' is not a valid component segment \
                    (must be non-empty, [A-Za-z0-9_-] only, no leading/trailing/consecutive -/_)",
                    name,
                );
            }
            if NAMED_COMPONENT_LOWERCASE.contains(&name.to_lowercase().as_str()) {
                unreachable!(
                    "BC-2.14.001 EC-002: Component::Custom name '{}' collides with named component '{}' when lowercased",
                    name,
                    name.to_lowercase()
                );
            }
        }
        // BC-2.14.001 EC-007: code COMPONENT segment must match component_lowercase(&component).
        // Prevents URN namespace aliasing: Custom("newcrate") with code "E-CORE-001" would emit
        // `urn:pregolya:error:E-CORE-001` with `component: "newcrate"` — conflicting attribution.
        let code_component = code[2..].rsplit_once('-').map(|(mid, _)| mid).unwrap_or("");
        if !code_component.eq_ignore_ascii_case(&component_lowercase(&component)) {
            unreachable!(
                "BC-2.14.001 EC-007: code COMPONENT segment '{}' does not match component identifier '{}'; \
                code must follow E-<COMPONENT>-NNN where COMPONENT matches the component field",
                code_component,
                component_lowercase(&component),
            );
        }
        Self {
            component,
            category,
            retry_hint,
            code,
            message,
            source: None,
        }
    }

    /// Chains a causal error onto this `PregolyaError`.
    ///
    /// ADR-010 §Class 1: use `.with_source(arc)` to chain a
    /// causal error from a lower subsystem. Implements [`std::error::Error::source`].
    pub fn with_source(self, source: Arc<dyn std::error::Error + Send + Sync>) -> Self {
        Self {
            source: Some(source),
            ..self
        }
    }

    /// Returns a reference to the `Arc` wrapping the causal error.
    ///
    /// Unlike [`std::error::Error::source`] (which returns `&dyn Error`), this preserves
    /// the `Arc` for direct re-chaining via `.with_source(Arc::clone(src))` in
    /// EC-001 re-emission patterns without re-allocating.
    /// Returns `None` if no source was chained via [`PregolyaError::with_source`].
    pub fn source_arc(&self) -> Option<&Arc<dyn std::error::Error + Send + Sync>> {
        self.source.as_ref()
    }

    /// Returns the error code string (e.g. `"E-CORE-001"`).
    ///
    /// BC-2.14.001 {INV-003}: the code is immutable once assigned.
    pub fn code(&self) -> &str {
        &self.code
    }

    /// Produces an RFC-7807 [`ProblemDetail`] from this error.
    ///
    /// Synchronous — no Tokio runtime required. Can be called in CLI tools and other
    /// non-async contexts.
    ///
    /// # Panics
    ///
    /// Panics if `self.component` has been assigned a `Component::Custom(name)` after
    /// construction that violates the EC-002 name rules (invalid chars or named-component alias).
    /// This cannot occur if `component` is set only via `PregolyaError::new()`, which validates
    /// at construction time; it is reachable if the public `component` field is reassigned
    /// post-construction (BC-2.14.001 EC-002 emission-time guard).
    ///
    /// Additionally panics if `self.component` (of any variant — named or Custom) has been
    /// reassigned post-construction such that the `code` field's COMPONENT segment no longer
    /// case-insensitively matches `component_lowercase(&self.component)`. This fires the
    /// emit-time binding assert at the head of this function (BC-2.14.001 EC-007,
    /// BC-2.14.002 EC-002 path 2). Example: constructing with `Component::Core` and
    /// `"E-CORE-001"`, then setting `err.component = Component::Graph` before calling
    /// `to_problem()`.
    ///
    /// Additionally panics if `self.code` does not start with `"E-"` (BC-2.14.001 EC-006
    /// format violation). This cannot occur if constructed via [`PregolyaError::new`], which
    /// validates the code format at construction time, but is reachable via in-crate
    /// struct-literal construction (allowed in `pregolya-core` per BC-2.14.001 {PC-008}).
    ///
    /// Note: the emit-time assert validates `code`↔COMPONENT binding only. Code↔category
    /// taxonomy consistency is enforced by the code-registry gate (S-1.02, VP-BC214001-01).
    pub fn to_problem(&self) -> ProblemDetail {
        // BC-2.14.001 EC-007: emission-time parity — component field may be reassigned post-construction
        // (it is `pub`), so verify the code↔component binding holds at emission time.
        // BC-2.14.001 EC-006: guard against in-crate struct-literal construction that bypasses
        // new() validation — strip_prefix panics with a BC-citing message rather than a raw
        // byte-offset panic if self.code is shorter than 2 bytes or lacks the "E-" prefix.
        let Some(code_suffix) = self.code.strip_prefix("E-") else {
            unreachable!(
                "BC-2.14.001 EC-006: code must follow E-<COMPONENT>-NNN format; \
                 got {:?} — cannot strip 'E-' prefix in to_problem()",
                self.code
            )
        };
        let code_component_emit = code_suffix
            .rsplit_once('-')
            .map(|(mid, _)| mid)
            .unwrap_or("");
        if !code_component_emit.eq_ignore_ascii_case(&component_lowercase(&self.component)) {
            unreachable!(
                "BC-2.14.001 EC-007: code COMPONENT segment '{}' does not match component identifier '{}' at emission time; \
                component field may have been reassigned after construction",
                code_component_emit,
                component_lowercase(&self.component),
            );
        }
        ProblemDetail {
            type_uri: format!("urn:pregolya:error:{}", self.code),
            title: category_title(&self.category).to_string(),
            detail: self.message.clone(),
            retry_hint: retry_hint_str(&self.retry_hint),
            component: component_lowercase(&self.component),
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
            Category::Exec => 500, // D26: INTERNAL-tier fallback per ADR-010 §Category Axis Expansion (D26)
            Category::Sys => 500,  // BC-2.14.002 {PC-003}: INTERNAL-tier; OS syscall failure
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
///
/// The `retry_hint` and `component` fields are RFC-7807 §3.2 extension members
/// carried as direct top-level fields — no nested wrapper type.
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
    /// Canonical retry hint per RFC-7807 §3.2 extension member.
    /// Values: `"never"`, `"maybe"`, or `"later:<seconds>"`.
    pub retry_hint: String,
    /// Lowercase component code per RFC-7807 §3.2 extension member.
    /// (e.g. `"core"`, `"graph"`).
    pub component: String,
}

// ─── Private helpers ─────────────────────────────────────────────────────────

/// Returns `true` if `s` is a valid component-segment identifier:
/// non-empty, ASCII alphanumeric + `-` + `_` only, no leading/trailing `-`/`_`,
/// no consecutive `-`/`_` sequences (including mixed `-_` / `_-`).
///
/// Used by the code-format `assert` in [`PregolyaError::new`] (validates the
/// `COMPONENT` segment of `E-<COMPONENT>-NNN`) and by the Custom-name guard
/// (validates `Component::Custom` names before the collision check).
fn is_valid_component_segment(s: &str) -> bool {
    !s.is_empty()
        && s.chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
        && !s.starts_with(['-', '_'])
        && !s.ends_with(['-', '_'])
        && !s.contains("--")
        && !s.contains("__")
        && !s.contains("-_")
        && !s.contains("_-")
}

/// Returns the lowercase component code string for RFC-7807 top-level `component` member.
///
/// # Panics (internal)
///
/// Panics on `Component::Custom` if the name violates EC-002 rules (called from `to_problem()`).
fn component_lowercase(component: &Component) -> String {
    match component {
        Component::Core => "core".to_string(),
        Component::Graph => "graph".to_string(),
        Component::Chkpt => "chkpt".to_string(),
        Component::Traj => "traj".to_string(),
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
        Component::Custom(name) => {
            if !is_valid_component_segment(name) {
                unreachable!(
                    "BC-2.14.001 EC-002: Component::Custom name '{}' contains invalid characters at emission time",
                    name
                );
            }
            if NAMED_COMPONENT_LOWERCASE.contains(&name.to_lowercase().as_str()) {
                unreachable!(
                    "BC-2.14.001 EC-002: Component::Custom name '{}' aliases named component '{}' at emission time",
                    name,
                    name.to_lowercase()
                );
            }
            name.to_lowercase()
        }
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

/// Encodes [`RetryHint`] as the canonical string form for RFC-7807 top-level `retry_hint` member.
///
/// - [`RetryHint::Never`] → `"never"`
/// - [`RetryHint::Maybe`] → `"maybe"`
/// - [`RetryHint::Later`] → `"later:<whole_seconds>"` (e.g. `"later:30"`)
fn retry_hint_str(hint: &RetryHint) -> String {
    match hint {
        RetryHint::Never => "never".to_string(),
        RetryHint::Maybe => "maybe".to_string(),
        RetryHint::Later(d) => {
            // Ceiling-round non-zero sub-second durations so that Duration::ZERO
            // remains the sole source of "later:0" (the retry-immediately sentinel).
            // BC-2.14.002 {INV-003} — ceiling-round regression: 900ms would truncate to "later:0" without this fix (F3 provenance)
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
        // BC-2.14.001 {PC-001} — new() field-assignment assertion: code/message must not transpose (F4 provenance)
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
    /// Exhaustive match on all 19 `Component` variants (18 named + `Custom(String)`).
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
                Component::Traj => 3,
                Component::Server => 4,
                Component::Prov => 5,
                Component::Mcp => 6,
                Component::Split => 7,
                Component::Sbxd => 8,
                Component::Retry => 9,
                Component::Cron => 10,
                Component::Memory => 11,
                Component::Budget => 12,
                Component::Tmpl => 13,
                Component::Srlz => 14,
                Component::Vs => 15,
                Component::Embed => 16,
                Component::Tools => 17,
                Component::Custom(_) => 18,
            }
        };
        // Spot-check first and last ordinals
        assert_eq!(_verify_exhaustive(Component::Core), 0);
        assert_eq!(_verify_exhaustive(Component::Custom("x".into())), 18);
        // 18 named variants (0–17) + 1 Custom = 19 total
    }

    /// AC-003 (traces to BC-2.14.001 {PC-003})
    ///
    /// Exhaustive match on all 14 `Category` variants (including `Exec` added by D26
    /// and `Sys` added by ADR-010 §Category Axis Expansion (SYS)).
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
                Category::Sys => 13,  // BC-2.14.001 {PC-003} addition
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
            code: "E-CORE-004".into(),
            message: "wrapped error".into(),
            source: Some(Arc::clone(&inner)),
        };
        // Error::source() must return Some when source field is populated
        let src = std::error::Error::source(&err).expect("source must be Some per TV-003");
        assert_eq!(
            src.to_string(),
            "inner",
            "source chain must point to the exact wrapped error"
        );
    }

    /// ADR-010 §Class 1: `.with_source()` builder chains
    /// a causal error; `std::error::Error::source()` returns `Some` afterward.
    #[test]
    fn test_BC_2_14_001_with_source_builder() {
        let inner: Arc<dyn std::error::Error + Send + Sync> =
            Arc::new(std::io::Error::other("inner error"));
        let err = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-001",
            "test",
        )
        .with_source(Arc::clone(&inner));
        let src =
            std::error::Error::source(&err).expect("source must be Some after .with_source()");
        assert_eq!(src.to_string(), "inner error");
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
            category: Category::Concurrency,
            retry_hint: RetryHint::Never,
            code: "E-GRAPH-001".into(),
            message: "test".into(),
            source: None,
        };
        // External-facing API: PregolyaError::new() must construct correctly
        let _err2 = PregolyaError::new(
            Component::Graph,
            Category::Concurrency,
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
            category: Category::Policy,
            retry_hint: RetryHint::Never,
            code: "E-GRAPH-002".into(),
            message: "chkpt error".into(),
            source: Some(Arc::clone(&inner)),
        };
        // Clone must succeed — Arc::clone increments refcount without T: Clone
        let err2 = err.clone();
        assert!(err2.source.is_some(), "cloned error must retain source");
        let src2 =
            std::error::Error::source(&err2).expect("cloned error must preserve source chain");
        assert_eq!(
            src2.to_string(),
            "original",
            "clone preserves source chain identity"
        );
    }

    // ── BC-2.14.002 Tests ─────────────────────────────────────────────────────

    /// AC-009 (traces to BC-2.14.002 {PC-001}, TV-001)
    ///
    /// `to_problem()` for a `Val` error maps to the correct `ProblemDetail` fields:
    /// `type_uri`, `title: "Validation"`, `detail`, `retry_hint: "never"`,
    /// `component: "core"` (all top-level RFC-7807 §3.2 members).
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
        assert_eq!(problem.retry_hint, "never");
        assert_eq!(problem.component, "core");
    }

    /// AC-009 (traces to BC-2.14.002 {PC-001}, TV-002)
    ///
    /// `to_problem()` for a `Rate` error with `Later(30s)` produces
    /// `retry_hint: "later:30"` (top-level RFC-7807 §3.2 member) and HTTP status 429 (via `http_status()`).
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
        assert_eq!(problem.retry_hint, "later:30");
        assert_eq!(problem.component, "prov");
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

        // VP-BC214002-01: structural conformance assertions — serde_json::Value field presence/absence checks
        // over the closed five-field wire shape ({PC-001}). Not a JSON Schema validator; no jsonschema dep.
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

        // RFC-7807 §3.2: extension members are top-level (no "extensions" wrapper key).
        // retry_hint and component are direct top-level fields on ProblemDetail
        // per BC-2.14.002 {PC-001} option ii.
        assert!(
            obj.get("retry_hint")
                .and_then(serde_json::Value::as_str)
                .is_some(),
            "RFC-7807 §3.2: 'retry_hint' must be a top-level string (flattened, not nested)"
        );
        assert!(
            obj.get("component")
                .and_then(serde_json::Value::as_str)
                .is_some(),
            "RFC-7807 §3.2: 'component' must be a top-level string (flattened, not nested)"
        );
        // Verify no "extensions" wrapper key exists — RFC-7807 §3.2 conformance
        assert!(
            obj.get("extensions").is_none(),
            "RFC-7807 §3.2: no 'extensions' wrapper key must exist — members are top-level"
        );

        // No field in the top-level object is null
        for (key, val) in obj {
            assert!(!val.is_null(), "RFC-7807 field '{}' must not be null", key);
        }

        // Round-trip: verify Deserialize direction (including rename = "type")
        let rt: ProblemDetail =
            serde_json::from_str(&json).expect("ProblemDetail must round-trip from JSON");
        assert_eq!(rt.type_uri, problem.type_uri);
        assert_eq!(rt.title, problem.title);
        assert_eq!(rt.detail, problem.detail);
        assert_eq!(rt.retry_hint, problem.retry_hint);
        assert_eq!(rt.component, problem.component);
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
            (Category::Sys, 500),  // BC-2.14.002 {PC-003}: INTERNAL-tier; OS syscall failure
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
    /// `retry_hint (top-level per RFC-7807 §3.2)` uses canonical string representations:
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
        assert_eq!(p.retry_hint, "never");
        assert_eq!(p.type_uri, "urn:pregolya:error:E-CORE-001");

        // "maybe"
        let err_maybe = PregolyaError {
            component: Component::Core,
            category: Category::Transport,
            retry_hint: RetryHint::Maybe,
            code: "E-CORE-004".into(),
            message: "maybe".into(),
            source: None,
        };
        let p2 = err_maybe.to_problem();
        assert_eq!(p2.retry_hint, "maybe");

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
            p3.retry_hint, "later:30",
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
        assert_eq!(p4.retry_hint, "later:60");

        // BC-2.14.002 {INV-003} — F3 regression: sub-second durations ceiling-round so they don't collide
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
            p5.retry_hint, "later:1",
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
            p6.retry_hint, "later:2",
            "1500ms must ceiling-round to 2 seconds"
        );

        // Duration::ZERO must still produce "later:0" (the retry-immediately sentinel)
        let err_zero2 = PregolyaError {
            component: Component::Prov,
            category: Category::Rate,
            retry_hint: RetryHint::Later(Duration::ZERO),
            code: "E-PROV-003".into(),
            message: "zero sentinel".into(),
            source: None,
        };
        let p7 = err_zero2.to_problem();
        assert_eq!(
            p7.retry_hint, "later:0",
            "Duration::ZERO must still produce 'later:0'"
        );
    }

    /// BC-2.14.002 {INV-003} HIGH-001 regression: Duration::MAX must not overflow with saturating_add.
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
        let hint = &prob.retry_hint;
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
            retry_hint: RetryHint::Maybe,
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
        // source() must return Some and point to the exact inner error
        let src = std::error::Error::source(&outer_err)
            .expect("outer error must chain to inner via source()");
        assert_eq!(
            src.to_string(),
            "[E-CHKPT-001] checkpoint write failed",
            "source chain must point to the exact wrapped error"
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
    /// `to_problem()` returns `component (top-level per RFC-7807 §3.2): "newcrate"`.
    /// The code field uses the lowercase format `E-newcrate-001` per EC-003 spec.
    #[test]
    fn test_BC_2_14_001_ec003_custom_component() {
        let err = PregolyaError::new(
            Component::Custom("newcrate".into()),
            Category::Internal,
            RetryHint::Never,
            "E-newcrate-001",
            "custom component error",
        );
        let problem = err.to_problem();
        // component_lowercase("newcrate") = "newcrate" — Custom value is the display name
        assert_eq!(problem.component, "newcrate");
        // type_uri uses the code field verbatim (lowercase per EC-003)
        assert_eq!(problem.type_uri, "urn:pregolya:error:E-newcrate-001");
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
    /// Also asserts exact `Later(...)` durations for the three later-categories
    /// (Rate=60s, Timeout=30s, Transport=30s) per the crate-defined defaults
    /// documented in `Category::default_retry_hint` doc comment.
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
            // For Later variants, also assert the exact duration.
            if let RetryHint::Later(d) = &hint {
                let expected_d = match cat {
                    Category::Rate => Duration::from_secs(60),
                    Category::Timeout => Duration::from_secs(30),
                    Category::Transport => Duration::from_secs(30),
                    _ => panic!("unexpected Later variant for {:?}", cat),
                };
                assert_eq!(d, &expected_d, "Category::{cat:?} Later duration mismatch");
            }
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

    /// BC-2.14.001 EC-006: rejects malformed code — "E-" only has no component segment.
    #[test]
    #[should_panic(expected = "code must follow E-<COMPONENT>-NNN format")]
    fn test_code_format_rejects_malformed_code() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-",
            "test",
        );
    }

    /// BC-2.14.001 EC-002 / EC-006 (story EC-003): lowercase alphanumeric component segment is valid — new crate name Custom component accepted.
    ///
    /// Story spec §Edge Cases EC-003 specifies `E-newcrate-001` as a valid code
    /// (lowercase custom component). The assert must NOT panic for this input.
    #[test]
    fn test_code_format_accepts_lowercase_component() {
        // Must not panic — "E-newcrate-001" is valid (lowercase alphanumeric per EC-003)
        let _ = PregolyaError::new(
            Component::Custom("newcrate".into()),
            Category::Internal,
            RetryHint::Never,
            "E-newcrate-001",
            "custom component demo",
        );
    }

    /// BC-2.14.001 EC-006: rejects two-digit numeric suffix — NNN must be exactly three digits.
    #[test]
    #[should_panic(expected = "code must follow E-<COMPONENT>-NNN format")]
    fn test_code_format_rejects_two_digit_suffix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-01",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects four-digit numeric suffix — NNN must be exactly three digits.
    #[test]
    #[should_panic(expected = "code must follow E-<COMPONENT>-NNN format")]
    fn test_code_format_rejects_four_digit_suffix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-1000",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects non-numeric suffix — NNN must be all ASCII digits.
    #[test]
    #[should_panic(expected = "code must follow E-<COMPONENT>-NNN format")]
    fn test_code_format_rejects_non_numeric_suffix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-ABC",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects wrong prefix letter — code must start with "E-".
    #[test]
    #[should_panic(expected = "code must follow E-<COMPONENT>-NNN format")]
    fn test_code_format_rejects_wrong_prefix() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "X-CORE-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: assert accepts a valid code format with consistent component.
    #[test]
    fn test_code_format_accepts_valid_format() {
        // Must not panic — "E-CORE-042" is a valid code format, Component::Core matches CORE segment
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-042",
            "test",
        );
    }

    /// BC-2.14.001 EC-007: rejects code↔component mismatch for named component — PROV ≠ core.
    #[test]
    #[should_panic(expected = "code COMPONENT segment")]
    fn test_code_format_rejects_component_code_mismatch_named() {
        // Component::Core with E-PROV-042 must panic — code segment PROV ≠ component identifier "core"
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-PROV-042",
            "test",
        );
    }

    /// BC-2.14.001 EC-007: rejects code↔component mismatch for Custom component — CORE ≠ newcrate.
    #[test]
    #[should_panic(expected = "code COMPONENT segment")]
    fn test_code_format_rejects_component_code_mismatch_custom() {
        // Custom("newcrate") with E-CORE-001 must panic — code segment CORE ≠ "newcrate"
        let _ = PregolyaError::new(
            Component::Custom("newcrate".to_string()),
            Category::Internal,
            RetryHint::Never,
            "E-CORE-001",
            "test",
        );
    }

    /// BC-2.14.002 {PC-001}: Exhaustive table-driven test for all 19 Component variants → expected top-level component string emitted by component_lowercase per RFC-7807 top-level member.
    #[test]
    fn test_BC_2_14_002_component_mapping_exhaustive() {
        use std::collections::HashSet;
        // Table: (Component, expected top-level component string)
        let cases: &[(Component, &str)] = &[
            (Component::Core, "core"),
            (Component::Graph, "graph"),
            (Component::Chkpt, "chkpt"),
            (Component::Traj, "traj"),
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
        assert_eq!(
            cases.len(),
            19,
            "must cover all 19 Component variants (18 named + Custom)"
        );
        let mut seen: HashSet<&str> = HashSet::new();
        for (comp, expected) in cases {
            let code = format!("E-{}-001", expected.to_ascii_uppercase());
            let err = PregolyaError {
                code,
                component: comp.clone(),
                category: Category::Internal,
                message: "test".to_string(),
                retry_hint: RetryHint::Never,
                source: None,
            };
            let prob = err.to_problem();
            assert_eq!(
                prob.component, *expected,
                "Component::{comp:?} must map to {expected:?}"
            );
            assert!(seen.insert(*expected), "duplicate mapping: {expected:?}");
        }
    }

    /// BC-2.14.002 {PC-001}: Exhaustive table-driven test for all 14 Category variants → expected title string emitted by category_title per RFC-7807 title field.
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
                code: "E-CORE-001".to_string(),
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

    /// BC-2.14.001 EC-002: CUSTOM_NAME may contain hyphens (real crate names).
    /// `E-my-crate-001` must be accepted by the assert without panicking.
    #[test]
    fn test_code_format_accepts_hyphenated_custom_component() {
        // BC-2.14.001 EC-002: CUSTOM_NAME may contain hyphens (real crate names)
        let _ = PregolyaError::new(
            Component::Custom("my-crate".into()),
            Category::Internal,
            RetryHint::Never,
            "E-my-crate-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-002: CUSTOM_NAME may contain underscores.
    /// `E-my_crate-001` must be accepted by the assert without panicking.
    #[test]
    fn test_code_format_accepts_underscored_custom_component() {
        let _ = PregolyaError::new(
            Component::Custom("my_crate".into()),
            Category::Internal,
            RetryHint::Never,
            "E-my_crate-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects leading hyphen in component segment (E--CORE-001 is malformed).
    #[test]
    #[should_panic(expected = "code must follow")]
    fn test_code_format_rejects_leading_hyphen_in_component() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E--CORE-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects doubled hyphen in component segment (E-CORE--001 is malformed).
    #[test]
    #[should_panic(expected = "code must follow")]
    fn test_code_format_rejects_doubled_hyphen_in_component() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE--001",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects trailing separator in component segment (E-CORE_-001 is malformed).
    #[test]
    #[should_panic(expected = "code must follow")]
    fn test_code_format_rejects_trailing_hyphen_in_component() {
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE_-001",
            "test",
        );
    }

    /// ADR-010 §Decision: `source_arc()` returns the `Arc`
    /// wrapping the causal error — preserving re-chain capability without re-allocating.
    #[test]
    fn test_BC_2_14_001_source_arc_accessor() {
        let inner: Arc<dyn std::error::Error + Send + Sync> =
            Arc::new(std::io::Error::other("inner"));
        let err = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-001",
            "outer",
        )
        .with_source(Arc::clone(&inner));
        // source_arc() returns the same Arc (pointer equality)
        let arc_ref = err
            .source_arc()
            .expect("source_arc must be Some after with_source");
        assert!(Arc::ptr_eq(arc_ref, &inner));
        // re-chain without re-wrapping
        let outer2 = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-004",
            "re-chain",
        )
        .with_source(Arc::clone(arc_ref));
        assert!(outer2.source_arc().is_some());
    }

    /// BC-2.14.001 EC-002: Custom name is lowercased on wire via component_lowercase.
    ///
    /// `Component::Custom("MyCrate")` → `component == "mycrate"` (top-level) on the
    /// ProblemDetail. `type_uri` preserves the original code casing.
    #[test]
    fn test_BC_2_14_001_custom_wire_normalization() {
        // BC-2.14.001 EC-002: Custom name is lowercased on wire (via component_lowercase).
        let err = PregolyaError::new(
            Component::Custom("MyCrate".into()),
            Category::Internal,
            RetryHint::Never,
            "E-MyCrate-001",
            "test",
        );
        let pd = err.to_problem();
        // component on wire is lowercased
        assert_eq!(pd.component, "mycrate");
        // type_uri preserves original casing
        assert!(pd.type_uri.contains("E-MyCrate-001"));
    }

    /// BC-2.14.001 EC-002: table-driven collision test — all 18 named component lowercase
    /// identifiers MUST trigger a collision panic; legitimate names MUST NOT panic.
    ///
    /// Uses `std::panic::catch_unwind` to verify each case individually without
    /// requiring one `#[should_panic]` test per identifier.
    #[test]
    fn test_BC_2_14_001_custom_collision_all_named() {
        // All 18 named component lowercase identifiers must trigger a collision panic.
        for &lower_name in super::NAMED_COMPONENT_LOWERCASE.iter() {
            let result = std::panic::catch_unwind(|| {
                let _ = PregolyaError::new(
                    Component::Custom(lower_name.to_string()),
                    Category::Internal,
                    RetryHint::Never,
                    format!("E-{lower_name}-001"),
                    "collision table test",
                );
            });
            assert!(
                result.is_err(),
                "Component::Custom({lower_name:?}) must panic with collision error (BC-2.14.001 EC-002)"
            );
        }
        // Legitimate names (not in NAMED_COMPONENT_LOWERCASE) must NOT panic.
        for &ok_name in &["newcrate", "my-crate", "my_crate"] {
            let result = std::panic::catch_unwind(|| {
                let _ = PregolyaError::new(
                    Component::Custom(ok_name.to_string()),
                    Category::Internal,
                    RetryHint::Never,
                    format!("E-{ok_name}-001"),
                    "non-collision test",
                );
            });
            assert!(
                result.is_ok(),
                "Component::Custom({ok_name:?}) must NOT panic (legitimate non-colliding name)"
            );
        }
    }

    /// BC-2.14.001 EC-002: construction-time collision guard is case-insensitive —
    /// the spec's canonical example `Custom("Core")` must panic at `new()`, not at emit time.
    /// Closes the mutation-survivability gap: `to_lowercase()` in `new()` must fold the name
    /// before the NAMED_COMPONENT_LOWERCASE lookup, so `Custom("Core")` ≡ `Custom("core")`.
    #[test]
    #[should_panic(expected = "collides with named component")]
    fn test_BC_2_14_001_custom_collision_mixed_case_at_construction() {
        let _ = PregolyaError::new(
            Component::Custom("Core".into()),
            Category::Internal,
            RetryHint::Never,
            "E-Core-001",
            "mixed-case collision must panic at construction, not at emit time",
        );
    }

    /// BC-2.14.001 EC-002 MED-003: assert rejects empty Custom name.
    #[test]
    #[should_panic(expected = "valid component segment")]
    fn test_BC_2_14_001_custom_empty_name_panic() {
        // Use a valid code so the code-format assert passes; only the charset assert fires.
        let _ = PregolyaError::new(
            Component::Custom("".into()),
            Category::Internal,
            RetryHint::Never,
            "E-valid-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-002 MED-003: assert rejects Custom name with trailing space.
    ///
    /// "Core " passes the collision check (not in NAMED_COMPONENT_LOWERCASE after
    /// lowercase + space), but fails the charset check (space is not `[A-Za-z0-9_-]`).
    #[test]
    #[should_panic(expected = "valid component segment")]
    fn test_BC_2_14_001_custom_whitespace_name_panic() {
        let _ = PregolyaError::new(
            Component::Custom("Core ".into()), // trailing space fails charset
            Category::Internal,
            RetryHint::Never,
            "E-Core-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-002 F1 regression: emit-time guard in `component_lowercase` blocks
    /// post-construction bypass of the Custom collision check.
    ///
    /// `component` is `pub`, so callers can bypass `new()` guards by reassigning after
    /// construction. `component_lowercase` must assert at emission time so that
    /// `to_problem()` never silently aliases a named component identifier.
    #[test]
    #[should_panic(expected = "aliases named component")]
    fn test_BC_2_14_001_ec002_emit_time_guard_blocks_alias() {
        let mut err = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-001",
            "test",
        );
        // Post-construction bypass: set an aliasing Custom name
        err.component = Component::Custom("Core".into());
        // to_problem() calls component_lowercase, which must assert at emission time
        let _ = err.to_problem();
    }

    /// BC-2.14.001 EC-002 F1 regression: emit-time charset guard rejects invalid Custom name
    /// even when set post-construction.
    #[test]
    #[should_panic(expected = "contains invalid characters at emission time")]
    fn test_BC_2_14_001_ec002_emit_time_guard_blocks_invalid_chars() {
        let mut err = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-001",
            "test",
        );
        // Post-construction bypass: set an invalid-charset Custom name
        err.component = Component::Custom("has space".into());
        // to_problem() must assert at emission time
        let _ = err.to_problem();
    }

    /// BC-2.14.002 {PC-001} / {PC-003} — Sys category: `to_problem()` yields title "System"
    /// and `http_status()` yields 500 (INTERNAL-tier; INV-001 no-200 guarantee).
    #[test]
    fn test_BC_2_14_001_002_sys_category() {
        let err = PregolyaError {
            component: Component::Sbxd,
            category: Category::Sys,
            retry_hint: RetryHint::Maybe,
            code: "E-SBXD-010".into(),
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
        assert_eq!(problem.type_uri, "urn:pregolya:error:E-SBXD-010");
        assert_eq!(problem.retry_hint, "maybe");
    }

    /// BC-2.14.001 EC-002: `NAMED_COMPONENT_LOWERCASE` must equal the set of strings
    /// `component_lowercase` returns for the 18 named variants. TD-VSDD-059: doc-comment-only
    /// invariants are not closures. This test is the load-bearing assertion.
    #[test]
    fn test_NAMED_COMPONENT_LOWERCASE_sync_with_component_lowercase() {
        use std::collections::HashSet;

        // Enumerate all 18 named variants explicitly.
        // If a new variant is added to Component, the exhaustive-match closure in
        // test_BC_2_14_001_component_axis will fail to compile (ensuring this list is updated).
        let named_variants: [Component; 18] = [
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

        let from_fn: HashSet<String> = named_variants
            .iter()
            .map(super::component_lowercase)
            .collect();

        let from_const: HashSet<String> = super::NAMED_COMPONENT_LOWERCASE
            .iter()
            .map(|s| s.to_string())
            .collect();

        assert_eq!(
            from_fn,
            from_const,
            "NAMED_COMPONENT_LOWERCASE is out of sync with component_lowercase. \
            Const has {:?} but function returns {:?}",
            from_const.difference(&from_fn).collect::<Vec<_>>(),
            from_fn.difference(&from_const).collect::<Vec<_>>(),
        );
        assert_eq!(
            super::NAMED_COMPONENT_LOWERCASE.len(),
            18,
            "Expected 18 named component identifiers"
        );
    }

    /// BC-2.14.001 EC-006: rejects consecutive underscores in component segment (E-A__B-001 is malformed).
    #[test]
    #[should_panic(expected = "code must follow")]
    fn test_code_format_rejects_double_underscore_segment() {
        // is_valid_component_segment blocks __ (consecutive underscores, BC-2.14.001 EC-002 charset)
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-A__B-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects mixed hyphen-underscore separator in component segment (E-A-_B-001 is malformed).
    #[test]
    #[should_panic(expected = "code must follow")]
    fn test_code_format_rejects_hyphen_underscore_segment() {
        // is_valid_component_segment blocks -_ (mixed consecutive separator, BC-2.14.001 EC-002 charset)
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-A-_B-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-006: rejects mixed underscore-hyphen separator in component segment (E-A_-B-001 is malformed).
    #[test]
    #[should_panic(expected = "code must follow")]
    fn test_code_format_rejects_underscore_hyphen_segment() {
        // is_valid_component_segment blocks _- (mixed consecutive separator, BC-2.14.001 EC-002 charset)
        let _ = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-A_-B-001",
            "test",
        );
    }

    /// BC-2.14.001 EC-007: emit-time code↔component mismatch — to_problem() detects binding violation when pub field reassigned post-construction.
    #[test]
    #[should_panic(expected = "code COMPONENT segment")]
    fn test_BC_2_14_001_ec007_emit_time_code_component_mismatch() {
        // Reassigning the pub component field post-construction creates a mismatch that
        // to_problem() must detect at emission time.
        let mut err = PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-001",
            "x",
        );
        err.component = Component::Graph; // bypass construction-time assert via pub field
        let _ = err.to_problem(); // must panic
    }

    /// BC-2.14.001 EC-006 / BC-2.14.002 {PC-002} path 3 — MED-001:
    /// `to_problem()` EC-006 strip_prefix guard fires when `self.code` lacks the "E-" prefix.
    ///
    /// Struct-literal construction (BC-2.14.001 {PC-008} clause 1) bypasses `new()` validation,
    /// so a code without the "E-" prefix is reachable. `to_problem()` must panic with a
    /// BC-citing message at emission time, not produce a silently malformed URN.
    #[test]
    #[should_panic(expected = "cannot strip 'E-' prefix in to_problem()")]
    fn test_BC_2_14_002_ec002_path3_emit_time_ec006_strip_prefix_guard() {
        // Struct-literal construction bypasses new() validation (BC-2.14.001 {PC-008} clause 1).
        // A code without the "E-" prefix triggers the EC-006 strip_prefix guard in to_problem().
        let err = PregolyaError {
            component: Component::Core,
            category: Category::Internal,
            retry_hint: RetryHint::Never,
            code: "CORE-001".into(), // valid format for new() but lacks "E-" prefix entirely
            message: "test EC-006 emit guard".into(),
            source: None,
        };
        let _ = err.to_problem();
    }
}
