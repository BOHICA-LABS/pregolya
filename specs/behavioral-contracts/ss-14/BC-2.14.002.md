---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.002
version: "1.4"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-14
changelog:
  - "1.1 (ADV-P1D-PASS-25): F-P25-01 PC3 add per-endpoint override block (E-SERVER-016→503); OBS-1 invariant precedence carve-out added."
  - "1.2 (ADV-P1D-PASS-26): F-P26-01 PC3 Known-overrides enumeration expanded to all 8 per-endpoint override classes; E-SERVER-004 removed from invariant divergence-example list (POLICY→403 is the categorical default, not a divergence)."
  - "1.3 (ADV-P1D-PASS-27): F-P27-01 add 9th Known-override: E-GRAPH-002 POLICY→422 on resume endpoint; canon: pass-23 deliberately set 422 (semantic state validation failure — no active interrupt slot); POLICY→403 categorical default does not apply because 'no active interrupt' is an unprocessable-entity condition, not a policy rejection."
  - "1.4 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-core / ferrochain-server per module-decomposition.md v1.10."
capability: CAP-016
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "6842386"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
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
3. HTTP status code mapping (categorical defaults; see per-endpoint overrides below):
   - `Category::Val` → 400
   - `Category::Auth` → 401
   - `Category::Policy` → 403
   - `Category::Rate` → 429
   - `Category::Timeout` → 504 *(categorical default)*
   - `Category::Transport` → 502 *(categorical default)*
   - `Category::Concurrency` → 409
   - `Category::Security` → 403
   - `Category::Tenancy` → 409
   - `Category::Durability` → 500
   - `Category::Internal` → 500
   - `Category::Tool` → 422

   **Per-endpoint status overrides (F-P25-01 — OBS-1 carve-out):** A resource BC may specify
   a status code that differs from the categorical default above. The per-endpoint status takes
   precedence; the categorical map is the fallback for errors with no per-endpoint specification.
   Known overrides as of v1.0.0 (complete enumeration — F-P26-01):
   - `E-SERVER-002 (RunNotFound)` → **404** despite `Category::Val` → 400.
     Rationale: "not found" responses use 404 per REST convention; 400 is for input-shape errors.
     Source: BC-2.12.003; interface-definitions.md §HTTP Status Codes 404 row.
   - `E-SERVER-003 (ThreadNotFound)` → **404** despite `Category::Val` → 400.
     Source: BC-2.12.001; interface-definitions.md §HTTP Status Codes 404 row.
   - `E-SERVER-006 (ScheduleNotFound)` → **404** despite `Category::Val` → 400.
     Source: BC-2.12.004; interface-definitions.md §HTTP Status Codes 404 row.
   - `E-SERVER-008 (ThreadStateConflict)` → **409** despite `Category::Policy` → 403.
     Rationale: the conflict is a state-machine constraint (active run present), not a
     security or permission gate — 409 Conflict is semantically correct.
     Source: BC-2.12.001; interface-definitions.md §HTTP Status Codes 409 row.
   - `E-SERVER-009 (AssistantNotFound)` — context-dependent dual override:
     - Direct lookup (`GET /assistants/{id}`) → **404** despite `Category::Val` → 400.
     - Run creation body (invalid `assistant_id` in POST body) → **422** despite `Category::Val` → 400.
     Source: BC-2.12.002, BC-2.12.003 PC3; interface-definitions.md §HTTP Status Codes 404 + 422 rows.
   - `E-SERVER-010 (AssistantVersionNotFound)` → **404** despite `Category::Val` → 400.
     Source: BC-2.12.002; interface-definitions.md §HTTP Status Codes 404 row.
   - `E-SERVER-011 (GraphNotFound)` → **422** despite `Category::Val` → 400.
     Rationale: graph_id in assistant creation body is a semantic (not structural) validation
     failure — the body is well-formed but references an unregistered resource.
     Source: BC-2.12.002 EC-005; interface-definitions.md §HTTP Status Codes 422 row.
   - `E-SERVER-016 (IdempotencyLockTimeout)` → **503** despite `Category::Timeout` → 504.
     Rationale: the lock timeout is a transient server-side serialization delay, not a
     provider/upstream timeout — 503 is the correct retryable-service-unavailable code.
     `RetryHint::Later` + `Retry-After` header are emitted. Source: BC-2.12.006 EC-002;
     interface-definitions.md §HTTP Status Codes 503 row; F-P25-01.
   - `E-GRAPH-002 (NoActiveInterrupt)` → **422** despite `Category::Policy` → 403.
     Rationale: the resume endpoint (`POST /threads/{thread_id}/runs/{run_id}/resume`)
     receives a well-formed request for a run with no active interrupt slot — this is a
     semantic state validation failure (422 Unprocessable Entity: the request cannot be
     processed because the entity's current state makes it impossible), not a policy
     rejection (403 would mean "you are not permitted to perform this action"). 422
     conveys "the run exists and you are authorized, but there is nothing to resume."
     Canon established pass-23; prior 409 entry retired. Source: BC-2.05.005 TV-003;
     interface-definitions.md §HTTP Status Codes 422 row; F-P27-01.
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
- The HTTP status code mapping is defined once in ferrochain-server. A per-endpoint status
  specified in a resource BC overrides the categorical default; the categorical map is the
  fallback for errors with no per-endpoint specification. Legitimate per-endpoint divergences
  (e.g., E-SERVER-016 TIMEOUT→503, E-SERVER-009 VAL→404 for direct lookup,
  E-SERVER-008 POLICY→409 for thread state conflict, E-GRAPH-002 POLICY→422 on resume
  endpoint) must be documented in PC3 and interface-definitions.md §HTTP Status Codes.
  Note: E-SERVER-004 POLICY→403 is NOT a divergence — POLICY→403 is the categorical
  default and requires no carve-out.
  The categorical map itself must not diverge; per-endpoint overrides must be explicit.
  Source: F-P25-01, OBS-1, ADV-P1D-PASS-25; F-P26-01, ADV-P1D-PASS-26; F-P27-01, ADV-P1D-PASS-27.

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
| TV-001 | `FerrochainError { component: CORE, category: VAL, code: "E-CORE-001", retry_hint: Never, message: "Invalid ContentBlock type 'x'" }.to_problem()` | `{ "type": "urn:ferrochain:error:E-CORE-001", "title": "Validation", "detail": "Invalid ContentBlock type 'x'", "extensions": { "retry_hint": "never", "component": "core" } }` | Happy path — VAL error |
| TV-002 | `FerrochainError { component: PROV, category: RATE, code: "E-PROV-001", retry_hint: Later(30s), message: "RateLimited" }.to_problem()` | HTTP status 429; `extensions.retry_hint: "later:30"` | Rate-limit with backoff |
| TV-003 | `ProblemDetail` serialized via `serde_json::to_string` | Valid JSON, no `null` fields except optional ones | RFC-7807 conformance |
| TV-004 | Response `Content-Type` header | `"application/problem+json"` | Correct MIME type |
| TV-005 | `FerrochainError { category: INTERNAL, ... }.to_problem()` HTTP status | 500 | Internal error → 500 |

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
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (FerrochainError 2D Struct)") per capabilities-p0.md §CAP-016 — CAP-016 explicitly includes "RFC-7807-compatible emission" as a required property of the error taxonomy surface; this BC implements that emission contract |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-core / ferrochain-server |
