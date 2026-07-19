---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.004
version: "1.5"
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
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-56): OBS-P56-2 codeless-error census (gate #30 first run) — EC-001, EC-003, TV-001, TV-003 each had category-only FerrochainError constructions. Added code: E-PROV-004 (ProviderAuthFailed) to AUTH constructions; code: E-PROV-001 (RateLimited) to RATE construction. EC-004, EC-005, TV-004, TV-005 use TRANSPORT for generic 5xx/unknown format; placeholder code: E-PROV-008 — deferred mint pending adversary pass targeting TRANSPORT generic path."
  - "1.2 (ADV-P1D-PASS-56-COMPLETION): Gate #30 drain — replaced E-PROV-008 placeholder with E-PROV-008 (ProviderHttpError, TRANSPORT) in EC-004, EC-005, TV-004, TV-005. Both sites (HTTP 5xx and unparseable error body) share TRANSPORT category; one code is correct per task-1 discipline. E-PROV-008 minted in error-taxonomy.md v1.8 this burst."
  - "1.3 (2026-07-15, F-P78-SWEEP/D18-P78-A): Three message-prefix corrections. (1) E-PROV-004 EC-001: added 'ProviderAuthFailed:' prefix. Taxonomy E-PROV-004 detail corrected from \"'<provider>' rejected API key — check credentials\" to 'authentication failed' (BC wins on content). (2) E-PROV-008 EC-004: added 'ProviderHttpError:' prefix (5xx case). (3) E-PROV-008 EC-005: added 'ProviderHttpError:' prefix (unparseable body case). Taxonomy E-PROV-008 updated to show both message forms."
  - "1.4 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-<provider> / ferrochain-standard-tests per module-decomposition.md v1.10."
  - "1.5 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. (1) PC3 had bare `Err(FerrochainError { category: RATE, code: E-PROV-001, retry_hint: Later(Duration) })` without message; added inline message template. (2) PC5 had `Err(FerrochainError { category: VAL, code: E-CORE-005, … })` with Unicode-ellipsis; expanded to full message template. (3) EC-002 had `Err(FerrochainError { category: VAL, code: E-PROV-006, … })` with Unicode-ellipsis; expanded to full message template; TV-002 PASS-ABBREV via EC-002. (4) EC-003 had bare `Err(FerrochainError { category: RATE, code: E-PROV-001, retry_hint: RetryHint::Later(…) })` without message; added inline message template; TV-003 PASS-ABBREV via EC-003."
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
input-hash: "3fd00ea"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
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
4. `FerrochainError` is defined with at minimum the following `category` variants
   (using canonical taxonomy codes from error-taxonomy.md):
   AUTH, VAL (including E-PROV-006 ContextLengthExceeded subtype), RATE, TRANSPORT (provider 5xx), TIMEOUT, POLICY (refusal), INTERNAL.

## Postconditions

1. A provider 401/403 response maps to `Err(FerrochainError { category: AUTH, … })`.
   The error message does NOT contain the raw API key value (DI-010 / NFR-005).
2. A provider "context length exceeded" / "too many tokens" 400 response maps to
   `Err(FerrochainError { category: VAL, … })`. The `code` field must be set to a
   context-overflow-specific error code so callers can distinguish this VAL subtype
   from other validation errors and apply summarization/trim middleware.
3. A provider 429 (rate limit) response maps to
   `Err(FerrochainError { category: RATE, code: E-PROV-001, retry_hint: Later(Duration),
   message: "RateLimited: provider '<provider>' returned 429; retry after <retry_after>s" })`
   (where `<provider>` is the provider adapter name; `<retry_after>` is the `Retry-After` header value in seconds when present, or 0 when absent; both available at the error mapping site).
   The `retry_hint` field carries the `Retry-After` header value when present.
4. A provider 5xx response maps to `Err(FerrochainError { category: TRANSPORT, … })`.
5. A provider-side validation error (e.g., invalid model name, unsupported parameter)
   maps to `Err(FerrochainError { category: VAL, code: E-CORE-005,
   message: "Validation failed for 'request': <provider_error>" })`
   (where `<provider_error>` is the provider's error message text, available from the HTTP error response body)
   — not silently returning an empty or stub `AiMessage`.
   (Provider-specific subtypes may use more specific VAL codes; E-CORE-005 is the minimum fallback for unrecognized provider validation errors without a dedicated code.)
6. No error variant causes a panic in non-test code.

## Invariants

- **DI-014 (Error Propagation (No Silent Swallowing)):** All provider error responses
  propagate as `Err(FerrochainError)`. A provider HTTP 4xx/5xx never produces `Ok(msg)`
  with a truncated or empty content.
- `FerrochainError::category` is always populated; `TRANSPORT` is the fallback for
  generic provider 5xx responses when no more specific category applies.
- Context-overflow (too many tokens) errors use `category: VAL` with `code: E-PROV-006`
  (ContextLengthExceeded); this distinguishes the subtype from other VAL errors —
  providers must not map other 400 errors to E-PROV-006.
- `retry_hint: RetryHint::Later(Duration)` is only set when the provider response
  actually specifies a retry delay; otherwise `RetryHint::Maybe` or `RetryHint::Never`.

## Edge Cases

### EC-001: Auth error must not reveal API key
**Scenario:** A 401 error response is returned while the `ApiKey` newtype is in scope.
**Expected behavior:** `FerrochainError { category: AUTH, code: E-PROV-004, message: "ProviderAuthFailed: authentication failed" }`.
The message and `Debug` representation do NOT include the raw key string.
The `{:?}` format of the associated credential shows `"<redacted>"`.

### EC-002: Context overflow vs generic validation error
**Scenario:** The provider returns HTTP 400 with body `{"error": {"type": "invalid_request_error",
"message": "This model's maximum context length is 128000 tokens."}}`.
**Expected behavior:** `Err(FerrochainError { category: VAL, code: E-PROV-006,
message: "ContextLengthExceeded: provider '<provider>' rejected request — context length <actual> exceeds maximum <limit> tokens" })`
(where `<provider>` is the provider adapter name; `<actual>` and `<limit>` are parsed from the 400 error body; all available at the error mapping site)
— not a generic VAL error; E-PROV-006 (ContextLengthExceeded) distinguishes context overflow from other VAL subtypes so callers can apply summarization/trim middleware.
TV-002 PASS-ABBREV via this EC-002 full-form site.

### EC-003: Rate limit with Retry-After header
**Scenario:** The provider returns HTTP 429 with `Retry-After: 60` header.
**Expected behavior:** `Err(FerrochainError { category: RATE, code: E-PROV-001, retry_hint: RetryHint::Later(Duration::from_secs(60)),
message: "RateLimited: provider '<provider>' returned 429; retry after 60s" })`
(where `<provider>` is the provider adapter name; `60` comes from `Retry-After: 60` header; both available at the error mapping site).
TV-003 PASS-ABBREV via this EC-003 full-form site.

### EC-004: Provider 500 internal error
**Scenario:** The provider returns HTTP 500 with an HTML error page.
**Expected behavior:** `Err(FerrochainError { category: TRANSPORT, code: E-PROV-008, message: "ProviderHttpError: provider
returned HTTP 500", source: Some(…) })`. The raw HTML is captured as `source`, not
as the `message` (avoid multi-KB error messages in the primary field).

### EC-005: Unknown error format (JSON but unexpected schema)
**Scenario:** The provider returns HTTP 400 with a JSON body that does not match the
known provider error schema.
**Expected behavior:** `Err(FerrochainError { category: TRANSPORT, code: E-PROV-008, message: "ProviderHttpError: unknown error
format: <first 256 chars>" })`. No panic. The partial body is included for diagnostics.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Cassette: HTTP 401 | `Err(FerrochainError { category: AUTH, code: E-PROV-004 })` — key not in message | Auth error |
| TV-002 | Cassette: HTTP 400 "context length exceeded" | `Err(FerrochainError { category: VAL, code: E-PROV-006 })` | Context overflow (E-PROV-006 ContextLengthExceeded). PASS-ABBREV via EC-002. |
| TV-003 | Cassette: HTTP 429 with `Retry-After: 30` | `Err(FerrochainError { category: RATE, code: E-PROV-001, retry_hint: Later(30s) })` | Rate limit. PASS-ABBREV via EC-003. |
| TV-004 | Cassette: HTTP 500 | `Err(FerrochainError { category: TRANSPORT, code: E-PROV-008 })` | Provider 5xx — code deferred |
| TV-005 | Cassette: HTTP 400 unknown JSON body | `Err(FerrochainError { category: TRANSPORT, code: E-PROV-008 })` — no panic | Unknown format — code deferred |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208004-01 | Auth error does not contain API key in message or Debug output | Unit test (credential redaction audit) | Wave 2 |
| VP-BC208004-02 | Context overflow (VAL + specific code) is distinguishable from generic VAL errors at runtime | Integration test (cassette: 400 context length) | Wave 2 |
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
| L2 Domain Invariants | DI-014 (Error Propagation (No Silent Swallowing)) |
| NE References | NE-03 (no silent None for validation failure — co-enforced with BC-2.14.006) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration, error cassette battery), U (unit — category discrimination, key redaction), PT (property test — fuzz error shapes) |
| Module | ferrochain-<provider> / ferrochain-standard-tests |
