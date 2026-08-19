---
document_type: story
level: ops
story_id: S-1.01
epic_id: E-01
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.001.md
  - .factory/specs/behavioral-contracts/ss-14/BC-2.14.002.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
  - .factory/specs/prd-supplements/error-taxonomy.md
input-hash: "4270699"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: []
blocks: [S-1.02, S-1.03, S-1.08, S-1.09]
behavioral_contracts: [BC-2.14.001, BC-2.14.002]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-core
subsystems: [SS-14]
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.01: PregolyaError 2D Struct and RFC-7807 Emission

## Narrative

- **As a** pregolya library author (and downstream crate implementer)
- **I want to** have a single well-typed `PregolyaError` struct with orthogonal Component × Category dimensions, RetryHint, and `to_problem()` for RFC-7807 emission
- **So that** every crate in the pregolya family can propagate structured errors that carry machine-readable codes, semantic retry guidance, and safe HTTP serialization — without exposing credentials, without panicking, and without ambiguous error shapes

## Acceptance Criteria

### AC-001 (traces to BC-2.14.001 postcondition 1)
`PregolyaError` with all five named fields (`component`, `category`, `retry_hint`, `code: String`, `message: String`) plus `source: Option<Arc<dyn std::error::Error + Send + Sync>>` constructs without error from within `pregolya-core` using struct-literal syntax. Verified by `test_BC_2_14_001_struct_construction()` which accesses each field by name.

### AC-002 (traces to BC-2.14.001 postcondition 2)
The `Component` enum has exactly 17 variants: Core, Graph, Chkpt, Server, Prov, Mcp, Split, Sbxd, Retry, Cron, Memory, Budget, Tmpl, Srlz, Vs, Embed, Tools — plus `Custom(String)`. An exhaustive match on all 18 cases (including Custom) compiles without a wildcard arm. Verified by `test_BC_2_14_001_component_axis()`.

### AC-003 (traces to BC-2.14.001 postcondition 3)
The `Category` enum has exactly 13 variants: Val, Auth, Rate, Timeout, Transport, Internal, Durability, Policy, Tool, Concurrency, Security, Tenancy, Exec. An exhaustive match on all 13 cases compiles without a wildcard arm. Verified by `test_BC_2_14_001_category_axis()`.

### AC-004 (traces to BC-2.14.001 postcondition 4)
`RetryHint` has exactly three variants: `Never`, `Maybe`, `Later(std::time::Duration)`. `RetryHint::Later(Duration::from_secs(30))` constructs and the inner duration is accessible. Verified by `test_BC_2_14_001_retry_hint()`.

### AC-005 (traces to BC-2.14.001 postcondition 6)
A `static_assertions::assert_impl_all!(PregolyaError: std::error::Error, Send, Sync)` compile-time assertion passes. `std::error::Error::source(&err)` returns `Some(&inner)` when the `source` field is `Some(arc_inner)`. Verified by `test_BC_2_14_001_error_trait()`.

### AC-006 (traces to BC-2.14.001 postcondition 7)
`PregolyaError::default()` fails to compile — `Default` is not derived. Verified by a `compile-fail` test or `static_assertions::assert_not_impl_any!(PregolyaError: Default)`.

### AC-007 (traces to BC-2.14.001 postcondition 8)
`PregolyaError` carries `#[non_exhaustive] #[derive(Debug, Clone)]`. External-crate code that attempts to match `PregolyaError { code, .. }` without the `..` wildcard fails to compile (validated by compile-fail test referencing external usage pattern). Internal (same-crate) struct-literal construction is permitted. `PregolyaError::new(component, category, retry_hint, code, message)` is the public external constructor. Verified by `test_BC_2_14_001_non_exhaustive()`.

### AC-008 (traces to BC-2.14.001 edge case EC-001)
The `source` field type is `Option<Arc<dyn std::error::Error + Send + Sync>>`. Cloning a `PregolyaError` with a populated source succeeds without requiring the inner error to be `Clone`. `Arc::clone` semantics are load-bearing. Verified by `test_BC_2_14_001_arc_source_clone()`.

### AC-009 (traces to BC-2.14.002 postcondition 1)
`pregolya_err.to_problem()` returns a `ProblemDetail` with:
- `type_uri: "urn:pregolya:error:E-CORE-001"` (format exactly `urn:pregolya:error:<code>`)
- `title`: humanized category name (e.g., `"Validation"` for `Category::Val`)
- `detail`: the error's `message` field
- `extensions.retry_hint`: `"never" | "maybe" | "later:<seconds>"`
- `extensions.component`: lowercase component code (e.g., `"core"`)

Verified by `test_BC_2_14_002_to_problem_val()` (TV-001) and `test_BC_2_14_002_to_problem_rate()` (TV-002).

### AC-010 (traces to BC-2.14.002 postcondition 2)
`serde_json::to_string(&problem_detail)` produces valid JSON conforming to RFC-7807 §3. No null fields for required RFC-7807 fields. Verified by `test_BC_2_14_002_rfc7807_json()` (TV-003).

### AC-011 (traces to BC-2.14.002 postcondition 3)
A parameterized unit test iterates all 13 `Category` variants and asserts their HTTP status codes: Val→400, Auth→401, Policy→403, Rate→429, Timeout→504, Transport→502, Concurrency→409, Security→403, Tenancy→409, Durability→500, Internal→500, Tool→422, Exec→500. No variant returns 200. Verified by `test_BC_2_14_002_status_codes_all_categories()`.

### AC-012 (traces to BC-2.14.002 postcondition 4)
The `Content-Type` header constant for RFC-7807 responses is `"application/problem+json"` (not `"application/json"`). Verified by `test_BC_2_14_002_content_type_constant()` asserting the string literal.

### AC-013 (traces to BC-2.14.002 postcondition 5)
`to_problem()` is a synchronous method — no `async`, no `tokio` dependency. It is callable without a Tokio runtime. Verified by `test_BC_2_14_002_sync_context()` running in a regular (non-async) `#[test]`.

### AC-014 (traces to BC-2.14.002 invariant)
The `type_uri` format `urn:pregolya:error:<code>` is stable. `extensions.retry_hint` uses canonical string form: `"never"`, `"maybe"`, `"later:30"` (not "30s" or `Duration` debug output). Verified by `test_BC_2_14_002_retry_hint_format()`.

### AC-015 (traces to BC-2.14.001 invariant — code immutability)
`PregolyaError.code` is a `String` that is set at construction and has no setter. A `PregolyaError` returned by `to_problem()` includes the original code unchanged. Verified by `test_BC_2_14_001_code_immutable()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `PregolyaError`, `Component`, `Category`, `RetryHint` | `pregolya-core/src/error.rs` (`core::error`) | pure-core |
| `ProblemDetail`, `to_problem()` | `pregolya-core/src/error.rs` | pure-core |
| `PROBLEM_JSON_CONTENT_TYPE` constant | `pregolya-core/src/error.rs` | pure-core |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/error.rs` | pure-core | No I/O, no async, no side effects. Deterministic struct construction and serialization. Error source chaining uses `Arc` for shared ownership, but no mutation and no runtime state. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Graph error wraps Chkpt error in source chain | Outer component is Graph; inner error preserved via `Arc<dyn Error + Send + Sync>` source chain; `source()` returns Some |
| EC-002 | `RetryHint::Later(Duration::ZERO)` | Valid; sentinel for "retry immediately"; no validation error at construction |
| EC-003 | `Component::Custom("newcrate")` | Accepted; code string `E-newcrate-001` valid; `to_problem()` returns `extensions.component: "newcrate"` |
| EC-004 | Duplicate error codes (E-CORE-001 claimed twice) | CI integration test (future S-1.02 scope) detects collision; build fails |
| EC-005 | `Category::Exec` HTTP status | Returns 500 via INTERNAL-tier fallback per ADR-010 §Category Axis Expansion (D26); no separate mapping row |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,500 |
| BC-2.14.001.md (~200 lines) | ~3,000 |
| BC-2.14.002.md (~230 lines) | ~3,500 |
| `module-decomposition.md` (SS-14 section, ~30 lines) | ~500 |
| `error-taxonomy.md` (SS-14 codes section) | ~1,500 |
| `error.rs` (to create, ~150 code lines) | ~2,000 |
| Test module (~100 lines) | ~1,500 |
| Tool outputs (cargo check, nextest runs) | ~500 |
| **Total** | **~16,000** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~8%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests — all ACs listed in Test Plan below (test-writer)
2. [ ] Verify Red Gate — `cargo nextest run -p pregolya-core` must show all new tests as compile errors or runtime failures (Red Gate ≥ 0.5 required)
3. [ ] Create `pregolya-core/src/error.rs` with `PregolyaError`, `Component`, `Category`, `RetryHint`, `ProblemDetail`, `to_problem()` — all `todo!()` bodies initially (implementer)
4. [ ] Implement `PregolyaError` struct and all enum variants (minimum code for AC-001 through AC-008)
5. [ ] Implement `to_problem()` and `ProblemDetail` serialization (AC-009 through AC-014)
6. [ ] Implement `http_status()` categorical mapping — all 13 arms (AC-011)
7. [ ] Add `static_assertions` assert and compile-fail tests (AC-005, AC-006)
8. [ ] Register module in `pregolya-core/src/lib.rs`
9. [ ] Run `cargo xtask check-file-size` — confirm `error.rs` < 500 code lines
10. [ ] Run `cargo clippy -p pregolya-core -D warnings` — zero warnings
11. [ ] Final `cargo nextest run -p pregolya-core` — all 15 AC tests pass

## Previous Story Intelligence (MANDATORY)

N/A — S-1.01 is the root story in Wave 1 batch 1a. No predecessors. This is the first story authored in the pregolya codebase; no established patterns to inherit yet.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `#[non_exhaustive]` on `PregolyaError` (public API surface type) | CLAUDE.md Code Conventions | Compile-fail test; `cargo check` from external test crate |
| `source` field is `Option<Arc<...>>` not `Option<Box<...>>` | BC-2.14.001 EC-001, ADR-010 §Decision | Code review; compile test that clones error with source |
| `Default` NOT implemented on `PregolyaError` | BC-2.14.001 postcondition 7 | `static_assertions::assert_not_impl_any!(PregolyaError: Default)` |
| No `println!` in `error.rs` | CLAUDE.md Code Conventions | `cargo clippy -D clippy::print_stdout` |
| No `unwrap()` / `expect()` in `error.rs` (non-test) | CLAUDE.md Code Conventions, BC-2.14.003 | `cargo xtask check-no-panic` (seeded by S-1.02) |
| `ProblemDetail` must `#[derive(Serialize)]` for RFC-7807 JSON | BC-2.14.002 postcondition 2 | `serde_json::to_string` unit test |
| `pregolya-core/src/error.rs` must NOT import `tokio` | Architecture boundary | `cargo tree -p pregolya-core` must not show tokio under error.rs |
| `Category::Exec` maps to HTTP 500 (INTERNAL fallback) per D26 | BC-2.14.002 Note (D26), ADR-010 §Category Axis Expansion | Parameterized status code test |

**Forbidden dependencies for `pregolya-core/src/error.rs`:** `tokio`, `reqwest`, `axum`, `hyper`, any `pregolya-*` crate. Only `std`, `serde`, `serde_json`, `static_assertions` (dev), `anyhow` (dev) are permitted.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `serde` | workspace pin | `#[derive(Serialize, Deserialize)]` on `ProblemDetail` |
| `serde_json` | workspace pin | `to_string` in unit tests; `Value` in extensions map |
| `static_assertions` | workspace pin (dev) | Compile-time trait bound assertions |
| `anyhow` | workspace pin (dev) | TV-004 compat test: wrap PregolyaError with anyhow context |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/error.rs` | CREATE | `PregolyaError`, `Component`, `Category`, `RetryHint`, `ProblemDetail` — `core::error` module |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod error;` and `pub use error::{PregolyaError, Component, Category, RetryHint, ProblemDetail};` |
