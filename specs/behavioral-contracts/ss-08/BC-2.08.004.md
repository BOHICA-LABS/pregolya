---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.004
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-009
wave: 2
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
  - domain-spec/capabilities-p1-p2.md#CAP-011
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/partners/behavioral-intent.md
  - .factory/semport/partners/test-inventory.md
input-hash: "ae89c62b019d905ca0e99acb7494c237c97cd0f81a8aa1142b7521d68afff2d1"
---

# BC-2.08.004: Chat Model Error-Type Fidelity Conformance

## Description

Every ferrochain provider chat model must map provider-specific HTTP error responses to
typed `FerrochainError` variants with the correct `category` field — ensuring that
context overflow, rate limiting, authentication failures, and provider-side validation
errors are each distinguishable by the caller without string parsing. No provider error
may be silently swallowed or returned as a non-error success value (DI-014). The
standard-tests battery exercises the minimal set of error categories every provider must
support.

## Preconditions

1. A ferrochain provider chat model is constructed for a model that returns HTTP error
   responses (4xx/5xx) under the conditions tested.
2. `ferrochain-standard-tests` is registered as a dev-dependency and the provider
   implements the error-fidelity conformance fixture.
3. A record/replay HTTP fixture layer can inject pre-recorded error responses (HTTP 400,
   401, 429, 503) for the provider's error JSON envelope format.
4. `FerrochainError` is defined with at minimum the following `category` variants:
   Auth, Validation, ContextOverflow, RateLimit, Provider, Timeout, Refusal, Internal.

## Postconditions

1. A provider 401/403 response maps to `Err(FerrochainError { category: Auth, … })`.
   The error message does NOT contain the raw API key value (DI-010 / NFR-005).
2. A provider "context length exceeded" / "too many tokens" 400 response maps to
   `Err(FerrochainError { category: ContextOverflow, … })`. The category is
   `ContextOverflow`, not the generic `Provider` category, so callers can distinguish
   this specific failure and apply summarization/trim middleware.
3. A provider 429 (rate limit) response maps to
   `Err(FerrochainError { category: RateLimit, retry_hint: Later(Duration) })`.
   The `retry_hint` field carries the `Retry-After` header value when present.
4. A provider 5xx response maps to `Err(FerrochainError { category: Provider, … })`.
5. A provider-side validation error (e.g., invalid model name, unsupported parameter)
   maps to `Err(FerrochainError { category: Validation, … })` — not silently returning
   an empty or stub `AiMessage`.
6. No error variant causes a panic in non-test code.

## Invariants

- **DI-014 (Error Propagation — No Silent Swallowing):** All provider error responses
  propagate as `Err(FerrochainError)`. A provider HTTP 4xx/5xx never produces `Ok(msg)`
  with a truncated or empty content.
- `FerrochainError::category` is always populated; the generic `Provider` category is
  a fallback used ONLY when no more specific category applies.
- The `ContextOverflow` category is reserved exclusively for the "too many tokens"
  semantic — providers must not map other 400 errors to `ContextOverflow`.
- `retry_hint: RetryHint::Later(Duration)` is only set when the provider response
  actually specifies a retry delay; otherwise `RetryHint::Maybe` or `RetryHint::Never`.

## Edge Cases

### EC-001: Auth error must not reveal API key
**Scenario:** A 401 error response is returned while the `ApiKey` newtype is in scope.
**Expected behavior:** `FerrochainError { category: Auth, message: "authentication failed" }`.
The message and `Debug` representation do NOT include the raw key string.
The `{:?}` format of the associated credential shows `"<redacted>"`.

### EC-002: Context overflow vs generic validation error
**Scenario:** The provider returns HTTP 400 with body `{"error": {"type": "invalid_request_error",
"message": "This model's maximum context length is 128000 tokens."}}`.
**Expected behavior:** `Err(FerrochainError { category: ContextOverflow, … })` — not
`Err(FerrochainError { category: Validation, … })`.

### EC-003: Rate limit with Retry-After header
**Scenario:** The provider returns HTTP 429 with `Retry-After: 60` header.
**Expected behavior:** `Err(FerrochainError { category: RateLimit, retry_hint:
RetryHint::Later(Duration::from_secs(60)) })`.

### EC-004: Provider 500 internal error
**Scenario:** The provider returns HTTP 500 with an HTML error page.
**Expected behavior:** `Err(FerrochainError { category: Provider, message: "provider
returned HTTP 500", source: Some(…) })`. The raw HTML is captured as `source`, not
as the `message` (avoid multi-KB error messages in the primary field).

### EC-005: Unknown error format (JSON but unexpected schema)
**Scenario:** The provider returns HTTP 400 with a JSON body that does not match the
known provider error schema.
**Expected behavior:** `Err(FerrochainError { category: Provider, message: "unknown error
format: <first 256 chars>" })`. No panic. The partial body is included for diagnostics.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Cassette: HTTP 401 | `Err(FerrochainError { category: Auth })` — key not in message | Auth error |
| TV-002 | Cassette: HTTP 400 "context length exceeded" | `Err(FerrochainError { category: ContextOverflow })` | Context overflow |
| TV-003 | Cassette: HTTP 429 with `Retry-After: 30` | `Err(FerrochainError { category: RateLimit, retry_hint: Later(30s) })` | Rate limit |
| TV-004 | Cassette: HTTP 500 | `Err(FerrochainError { category: Provider })` | Provider 5xx |
| TV-005 | Cassette: HTTP 400 unknown JSON body | `Err(FerrochainError { category: Provider })` — no panic | Unknown format |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208004-01 | Auth error does not contain API key in message or Debug output | Unit test (credential redaction audit) | Wave 2 |
| VP-BC208004-02 | ContextOverflow is distinguishable from generic Validation category | Integration test (cassette: 400 context length) | Wave 2 |
| VP-BC208004-03 | All provider HTTP 4xx/5xx produce Err, never Ok | Property test (fuzz error body shapes) | Wave 2 |

## Related BCs

- BC-2.08.007 — transport error (timeout/stream interruption — distinct error category)
- BC-2.14.004 — mandatory HTTP timeout (DI-009; timeout errors flow through this contract)
- BC-2.14.005 — credential opacity (DI-010; auth error must not reveal key)
- BC-2.14.006 — no silent None for validation failures (DI-014 co-enforcer)

## Architecture Anchors

- `ferrochain-<provider>/src/error_mapping.rs` — provider HTTP status → FerrochainError (to be created)
- `ferrochain-standard-tests/src/chat_models/error_fidelity.rs` — error fidelity battery (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208004-01, VP-BC208004-02, VP-BC208004-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009, CAP-011 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the typed error mapping requirement for every provider implementation; CAP-011 ("Provider Conformance Suite (Standard Tests)") per capabilities-p1-p2.md §CAP-011 — this BC expresses the error-fidelity subset of ferrochain-standard-tests |
| L2 Domain Invariants | DI-014 (Error Propagation — No Silent Swallowing) |
| NE References | NE-03 (no silent None for validation failure — co-enforced with BC-2.14.006) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration, error cassette battery), U (unit — category discrimination, key redaction), PT (property test — fuzz error shapes) |
| Module | [architect to assign — ferrochain-<provider>, ferrochain-standard-tests] |
