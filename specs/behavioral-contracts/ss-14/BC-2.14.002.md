---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.002
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-14
capability: CAP-016
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-016
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "6d5bd7a3f1412d4adef708bdd467bda1f6db6e05b19cf66168e832c3b89847ed"
---

# BC-2.14.002: RFC-7807 Compatible Problem Emission from FerrochainError

## Description

When `FerrochainError` values are surfaced via HTTP through `ferrochain-server`, they must be
serializable to an RFC-7807 (Problem Details for HTTP APIs) `application/problem+json` response.
The mapping from `FerrochainError` struct fields to RFC-7807 fields is fixed and documented in
error-taxonomy.md. Additionally, `FerrochainError` must provide a `to_problem()` method (or
`impl From<FerrochainError> for ProblemDetail`) that produces the RFC-7807 payload without
requiring the HTTP layer to reach into the error's internal fields directly.

## Preconditions

1. `ferrochain-core` defines `FerrochainError` (see BC-2.14.001).
2. `ferrochain-server` is handling an HTTP request that results in a `FerrochainError`.
3. The HTTP response will carry `Content-Type: application/problem+json` and a status code
   derived from the error's category.

## Postconditions

1. `ferrochain_err.to_problem()` returns a `ProblemDetail` struct with these fields:
   - `type_uri: "urn:ferrochain:error:<code>"` (e.g. `"urn:ferrochain:error:E-GRAPH-001"`)
   - `title: <humanized category name>` (e.g. `"Concurrency"` for `Category::Concurrency`)
   - `detail: <err.message>` — the human-readable message from `FerrochainError`
   - `extensions.retry_hint: "never" | "maybe" | "later:<seconds>"` — derived from `RetryHint`
   - `extensions.component: <lowercase component code>` (e.g. `"graph"`)
2. The `ProblemDetail` serializes to valid JSON conforming to RFC-7807 §3.
3. HTTP status code mapping:
   - `Category::Val` → 400
   - `Category::Auth` → 401
   - `Category::Policy` → 403
   - `Category::Rate` → 429
   - `Category::Timeout` → 504
   - `Category::Transport` → 502
   - `Category::Concurrency` → 409
   - `Category::Security` → 403
   - `Category::Tenancy` → 409
   - `Category::Durability` → 500
   - `Category::Internal` → 500
   - `Category::Tool` → 422
4. The `Content-Type` header of the response is `application/problem+json` (not
   `application/json`) when a `ProblemDetail` is emitted.
5. A `FerrochainError` without an HTTP context (e.g. raised in a CLI tool) can still call
   `to_problem()` — the method does not require an HTTP runtime to produce the payload.

## Invariants

- The `type_uri` format `urn:ferrochain:error:<code>` is the stable machine-readable identifier;
  monitoring rules and API clients must use `type_uri`, not `title` or `detail`, for error
  classification.
- `detail` may contain dynamic content (e.g. the invalid field name), but `type_uri` must not
  (it is always the static code like `E-CORE-001`).
- `retry_hint` in the extensions block uses the canonical string representation
  (`"never"`, `"maybe"`, `"later:<seconds>"`) for client machine readability.
- The HTTP status code mapping is defined once in ferrochain-server and must not diverge from
  the table above.

## Edge Cases

### EC-001: FerrochainError with RetryHint::Later in problem extension
**Scenario:** A rate-limited error `(Component::Prov, Category::Rate, retry_hint: Later(60s))` is
serialized to RFC-7807.
**Expected behavior:** `extensions.retry_hint` is `"later:60"` (seconds as integer string).
The HTTP response may additionally include a `Retry-After: 60` header.

### EC-002: ProblemDetail emitted outside HTTP context
**Scenario:** A CLI tool calls `err.to_problem()` to format an error for structured log output.
**Expected behavior:** `to_problem()` returns a `ProblemDetail` struct without panicking or
requiring a `tokio::Runtime`. The struct can be serialized to JSON with `serde_json::to_string`.

### EC-003: Nested FerrochainError source in problem detail
**Scenario:** A `FerrochainError` with a `source: Some(inner_err)` is converted to RFC-7807.
**Expected behavior:** The outer error's fields populate the top-level RFC-7807 fields. The inner
error is NOT recursively expanded in the problem detail (RFC-7807 does not specify a chain format).
If detailed debugging is needed, it is in the `extensions.detail_chain` field (optional, internal
only — not emitted in production mode).

### EC-004: Multiple errors from a batch operation
**Scenario:** `batch()` returns `[Ok(r), Err(e1), Err(e2)]`. The server needs to emit an error
response.
**Expected behavior:** The server emits a single RFC-7807 response for the first error encountered,
or a multi-error summary in `extensions.errors: [...]` if the API contract supports multi-error
responses. The contract for the specific endpoint governs which format is used; this BC covers
single-error problem emission only.

### EC-005: Unknown category in ProblemDetail (forward compatibility)
**Scenario:** Application code uses `Component::Custom("newcrate")` with a category not in the
standard set.
**Expected behavior:** `to_problem()` uses a generic `title: "Unknown"` and derives the `type_uri`
from the code string. The HTTP status code falls back to 500 for unknown categories.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `FerrochainError { component: Core, category: Val, code: "E-CORE-001", retry_hint: Never, message: "Invalid ContentBlock type 'x'" }.to_problem()` | `{ "type": "urn:ferrochain:error:E-CORE-001", "title": "Validation", "detail": "Invalid ContentBlock type 'x'", "extensions": { "retry_hint": "never", "component": "core" } }` | Happy path — VAL error |
| TV-002 | `FerrochainError { component: Prov, category: Rate, code: "E-PROV-001", retry_hint: Later(30s), message: "RateLimited" }.to_problem()` | HTTP status 429; `extensions.retry_hint: "later:30"` | Rate-limit with backoff |
| TV-003 | `ProblemDetail` serialized via `serde_json::to_string` | Valid JSON, no `null` fields except optional ones | RFC-7807 conformance |
| TV-004 | Response `Content-Type` header | `"application/problem+json"` | Correct MIME type |
| TV-005 | `FerrochainError { category: Internal, ... }.to_problem()` HTTP status | 500 | Internal error → 500 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC214002-01 | `ProblemDetail` output is valid RFC-7807 JSON (type_uri is a URI, title is a string, detail is present) | Unit test + JSON schema validation | Wave 0 |
| VP-BC214002-02 | HTTP status code mapping covers all 12 categories (no category returns 200) | Parameterized unit test over Category enum variants | Wave 0 |

## Related BCs

- BC-2.14.001 — FerrochainError 2D struct (depends on: ProblemDetail is derived from FerrochainError fields)
- BC-2.12.003 — Run creation lifecycle (composes with: server run errors are emitted as RFC-7807 responses)

## Architecture Anchors

- `ferrochain-core/src/error.rs` — `ProblemDetail` struct and `FerrochainError::to_problem()` method (to be created)
- `ferrochain-server/src/error_response.rs` — HTTP status code mapping and response serialization (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC214002-01, VP-BC214002-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (FerrochainError 2D Struct)") per capabilities-p1-p2.md §CAP-016 — CAP-016 explicitly includes "RFC-7807-compatible emission" as a required property of the error taxonomy surface; this BC implements that emission contract |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), I (integration) |
| Module | [architect to assign — ferrochain-core, ferrochain-server] |
