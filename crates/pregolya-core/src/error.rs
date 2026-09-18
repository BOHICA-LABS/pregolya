//! Error taxonomy for the pregolya library family.
//!
//! Defines [`PregolyaError`], the universal error type, along with the
//! [`Component`], [`Category`], and [`RetryHint`] orthogonal dimensions, and
//! the RFC-7807 [`ProblemDetail`] emission type.
//!
//! All function bodies in this module use `todo!()` per Red Gate discipline
//! (BC-5.38.001). The implementer writes real logic; this file provides
//! compilable shapes so the test-writer's failing tests compile before
//! implementation begins.

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
/// 13 variants as of ADR-010 §Category Axis Expansion (D26), which added
/// [`Category::Exec`] as the 13th category.
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
        _component: Component,
        _category: Category,
        _retry_hint: RetryHint,
        _code: impl Into<String>,
        _message: impl Into<String>,
    ) -> Self {
        todo!()
    }

    /// Produces an RFC-7807 [`ProblemDetail`] from this error.
    ///
    /// Synchronous — no Tokio runtime required. Safe to call in CLI tools and
    /// other non-async contexts.
    pub fn to_problem(&self) -> ProblemDetail {
        todo!()
    }

    /// Returns the categorical HTTP status code for this error's [`Category`].
    ///
    /// Maps each category to its default status code per BC-2.14.002 {PC-003}.
    /// Per-endpoint overrides (documented in BC-2.14.002 Known-overrides) are
    /// applied by `pregolya-server`, not here.
    pub fn http_status(&self) -> u16 {
        todo!()
    }
}

impl fmt::Display for PregolyaError {
    fn fmt(&self, _f: &mut fmt::Formatter<'_>) -> fmt::Result {
        todo!()
    }
}

impl std::error::Error for PregolyaError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        todo!()
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
