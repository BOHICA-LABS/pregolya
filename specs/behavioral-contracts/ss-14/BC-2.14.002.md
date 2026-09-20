---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.002
version: "1.19"
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
  - "1.4 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-core / pregolya-server per module-decomposition.md v1.10."
  - "1.5 (FIX-BURST-280-WAVE-C/F-P175-A25-T2/2026-07-28): Task 2 — explicit annotation added above TV table. TV-001/TV-002/TV-005 use ALL-CAPS prose shorthand notation (`component: CORE, category: VAL`, etc.) which is BC-2.14.001 rendering convention for table cells — NOT compilable Rust. Actual test construction uses PregolyaError::new(...). No behavioral change."
  - "1.6 (WAVE-B-B3/2026-07-29): Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon). One CLASS3_ASCII_ELLIPSIS_VIOLATION corrected: TV-005 Input `PregolyaError { category: INTERNAL, ... }` — replaced `...` with `..`. TV-001 and TV-002 are Class 3 VALID (all 5 non-source fields present; Class 4 defining-crate annotations from v1.5 remain accurate). No behavioral change."
  - "1.7 (F-P177-C-LOW-SS14, burst-288, 2026-08-15): Remove phantom §Named-Section anchors in PC3 Known-overrides block. Nine `interface-definitions.md §HTTP Status Codes NNN row` references used row-number qualifiers as part of the §-anchor name (e.g., `§HTTP Status Codes 404 row`) — but the actual section heading is `§HTTP Status Codes`; row numbers are not headings. Fixed by parenthesizing each row qualifier: `§HTTP Status Codes (404 row)`, `§HTTP Status Codes (409 row)`, `§HTTP Status Codes (422 row)`, `§HTTP Status Codes (503 row)`, `§HTTP Status Codes (404 + 422 rows)`. Nine sites corrected; no behavioral change."
  - "1.8 (BURST-308/D26-EXEC-propagation/2026-08-17): Category axis expanded 12→13 per ADR-010 §Category Axis Expansion (D26). PC3 categorical table: `Category::Exec → 500` added as 13th entry (library-layer-only; INTERNAL-tier fallback at pregolya-server). VP-BC214002-02 description: '12 categories' → '13 categories (EXEC included; no category returns 200)'. §Notes section added: EXEC library-layer-only disposition; no Known-overrides row per architect D26 decision; parameterized test accepts EXEC→500 via INTERNAL-tier fallback. No behavioral change to RFC-7807 emission."
  - "1.9 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.01 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.10 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.11 (P2A-044 F-06/2026-08-24): compressed-ordinal citations normalized to stable tags."
  - "1.12 (S-1.01 adv pass-1 F1/2026-09-17): Align to error-taxonomy v1.59 SYS 14th-category. {PC-003} categorical HTTP-status table: `Category::Sys → 500` added as 14th entry (INTERNAL-tier fallback at pregolya-server; rationale: SYS = OS-level syscall failure — EACCES/ELOOP/EIO are unexpected infrastructure failures, not caller input errors and not network transport issues; 500 is the correct HTTP response; does NOT return 200, satisfying {INV-001}; no Known-overrides row presently — E-SBXD-010 CanonicalizationFailed, the first SYS code, is library-layer/blanket and does not reach the HTTP surface directly). VP-BC214002-02 description updated: '13 categories (EXEC included; no category returns 200)' → '14 categories (EXEC and SYS included; no category returns 200)'. §Notes SYS paragraph added mirroring EXEC disposition note. TD-VSDD-060 sibling sweep: all three category-count sites in BC-2.14.002 live body updated ({PC-003} table length, VP-BC214002-02 description, §Notes). No behavioral change to RFC-7807 emission."
  - "1.13 (S-1.01 LOCAL adv pass OBS-1/2026-09-17): EC-005 restated — compile-time exhaustiveness replaces the stale runtime 'Unknown'/500 fallback. The closed 14-variant #[non_exhaustive] Category enum with no wildcard match arm means adding a new Category variant is a source-breaking change detected at compile time at every mapping site (http_status, category_title). No reachable code path yields title: 'Unknown' or HTTP 500 for an unknown category because no unknown category can exist at runtime. This is strictly stronger than a runtime fallback. Records-only hygiene; no behavioral change."
  - "1.14 (S-1.01 LOCAL adv OBS-1/2026-09-18): BC-prose precision fix only — {INV-004} and §Architecture Anchors corrected to reflect actual layering per S-1.01 implementation. {INV-004}: 'defined once in pregolya-server' → 'defined once in pregolya-core::error::PregolyaError::http_status()'; pregolya-server role restated as per-endpoint overrides + RFC-7807 response serialization delegating to core::http_status() rather than re-declaring the categorical table. §Architecture Anchors: pregolya-core/src/error.rs bullet adds http_status() to the method list; pregolya-server/src/error_response.rs bullet drops 'HTTP status code mapping' and gains delegation clause. INV-004 'defined once' guarantee now correctly identifies the site. No behavioral change; code is correct — this is spec-prose alignment only."
  - "1.15 (S-1.01-adv-pass-8/2026-09-20): {INV-003} — add ceiling-round clause for sub-second Later durations; Duration::ZERO produces later:0 (retry-immediately sentinel per BC-2.14.001 EC-003); saturation at u64::MAX is the overflow behavior. Anchors Rate/Timeout/Transport Later default durations (60 s / 30 s / 30 s) in error-taxonomy §Error Categories. {PC-001}/{PC-002}/TV-001/TV-002 — flatten extension members to RFC-7807 §3.2 top-level; remove extensions wrapper; document implementer action required. Implementer action: merge/flatten ProblemExtensions into ProblemDetail using #[serde(flatten)] or direct fields; remove extensions: ProblemExtensions field; update all wire-shape tests."
  - "1.16 (S-1.01-adv-pass-9/2026-09-20): {PC-001} contradictory implementation sentences resolved — option ii ratified: ProblemExtensions removed; retry_hint and component are direct top-level fields on ProblemDetail (RFC-7807 §3.2). {INV-003} wire-path corrected from 'extensions block' to 'top-level member'. EC-001 wire-path corrected from extensions.retry_hint to retry_hint (top-level per RFC-7807 §3.2)."
  - "1.17 (S-1.01-adv-pass-10): {PC-001} implementer-action paragraph replaced with declarative postcondition — ProblemExtensions removal and field lowering is completed work, not a directive. EC-003 'extensions.detail_chain' → 'detail_chain (optional, internal-only top-level field)'. EC-004 'extensions.errors: [...]' → 'errors: [...] (top-level field)'. Per {PC-002} §RFC-7807 §3.2 all extension members are top-level."
  - "1.18 (S-1.01-adv-pass-12): EC-002 panic carve-out added for contract-violation case."
  - "1.19 (S-1.01-adv-pass-16/MED-001): EC-003/EC-004 aligned with PC-001 five-field closure; detail_chain orphan reference removed; errors:[] re-scoped to pregolya-server envelope; cross-refs to {PC-001} added."
capability: CAP-016
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-09-17T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "79d6343"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.002: RFC-7807 Compatible Problem Emission from PregolyaError

## Description

When `PregolyaError` values are surfaced via HTTP through `pregolya-server`, they must be
serializable to an RFC-7807 (Problem Details for HTTP APIs) `application/problem+json` response.
The mapping from `PregolyaError` struct fields to RFC-7807 fields is fixed and documented in
error-taxonomy.md. Additionally, `PregolyaError` must provide a `to_problem()` method (or
`impl From<PregolyaError> for ProblemDetail`) that produces the RFC-7807 payload without
requiring the HTTP layer to reach into the error's internal fields directly.

## Preconditions

1. {PRE-001} `pregolya-core` defines `PregolyaError` (see BC-2.14.001).
2. {PRE-002} `pregolya-server` is handling an HTTP request that results in a `PregolyaError`.
3. {PRE-003} The HTTP response will carry `Content-Type: application/problem+json` and a status code
   derived from the error's category.

## Postconditions

1. {PC-001} `pregolya_err.to_problem()` returns a `ProblemDetail` struct with these fields:
   - `type_uri: "urn:pregolya:error:<code>"` (e.g. `"urn:pregolya:error:E-GRAPH-001"`)
   - `title: <humanized category name>` (e.g. `"Concurrency"` for `Category::Concurrency`)
   - `detail: <err.message>` — the human-readable message from `PregolyaError`
   - `retry_hint: "never" | "maybe" | "later:<seconds>"` — derived from `RetryHint`; emitted as a **top-level member** of the problem details object per RFC-7807 §3.2
   - `component: <lowercase component code>` (e.g. `"graph"`); emitted as a **top-level member** of the problem details object per RFC-7807 §3.2

   `ProblemDetail` has exactly five public fields (in serialization order):
   `type_uri` (serialized as `"type"`), `title`, `detail`, `retry_hint`, `component`.
   No wrapper sub-struct (`ProblemExtensions` was removed in S-1.01). All five fields
   are required members — none is optional in the wire encoding.
2. {PC-002} Emits valid `application/problem+json` conforming to RFC-7807 §3. Extension members `retry_hint` and `component` are emitted as **top-level members** of the problem details object per RFC-7807 §3.2 — not nested under an `extensions` wrapper.
3. {PC-003} HTTP status code mapping (categorical defaults; see per-endpoint overrides below):
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
   - `Category::Exec` → 500 *(library-layer-only; INTERNAL-tier fallback at pregolya-server per ADR-010 §Category Axis Expansion (D26); no Known-overrides row)*
   - `Category::Sys` → 500 *(INTERNAL-tier fallback at pregolya-server; SYS = OS-level syscall failure — EACCES/ELOOP/EIO are unexpected infrastructure failures that are neither caller input errors nor network transport errors; no Known-overrides row; E-SBXD-010 CanonicalizationFailed is the first SYS code and is library-layer/blanket — does not reach the HTTP surface directly; does NOT return 200, satisfying {INV-001})*

   **Per-endpoint status overrides (F-P25-01 — OBS-1 carve-out):** A resource BC may specify
   a status code that differs from the categorical default above. The per-endpoint status takes
   precedence; the categorical map is the fallback for errors with no per-endpoint specification.
   Known overrides as of v1.0.0 (complete enumeration — F-P26-01):
   - `E-SERVER-002 (RunNotFound)` → **404** despite `Category::Val` → 400.
     Rationale: "not found" responses use 404 per REST convention; 400 is for input-shape errors.
     Source: BC-2.12.003; interface-definitions.md §HTTP Status Codes (404 row).
   - `E-SERVER-003 (ThreadNotFound)` → **404** despite `Category::Val` → 400.
     Source: BC-2.12.001; interface-definitions.md §HTTP Status Codes (404 row).
   - `E-SERVER-006 (ScheduleNotFound)` → **404** despite `Category::Val` → 400.
     Source: BC-2.12.004; interface-definitions.md §HTTP Status Codes (404 row).
   - `E-SERVER-008 (ThreadStateConflict)` → **409** despite `Category::Policy` → 403.
     Rationale: the conflict is a state-machine constraint (active run present), not a
     security or permission gate — 409 Conflict is semantically correct.
     Source: BC-2.12.001; interface-definitions.md §HTTP Status Codes (409 row).
   - `E-SERVER-009 (AssistantNotFound)` — context-dependent dual override:
     - Direct lookup (`GET /assistants/{id}`) → **404** despite `Category::Val` → 400.
     - Run creation body (invalid `assistant_id` in POST body) → **422** despite `Category::Val` → 400.
     Source: BC-2.12.002, BC-2.12.003 {PC-003}; interface-definitions.md §HTTP Status Codes (404 + 422 rows).
   - `E-SERVER-010 (AssistantVersionNotFound)` → **404** despite `Category::Val` → 400.
     Source: BC-2.12.002; interface-definitions.md §HTTP Status Codes (404 row).
   - `E-SERVER-011 (GraphNotFound)` → **422** despite `Category::Val` → 400.
     Rationale: graph_id in assistant creation body is a semantic (not structural) validation
     failure — the body is well-formed but references an unregistered resource.
     Source: BC-2.12.002 EC-005; interface-definitions.md §HTTP Status Codes (422 row).
   - `E-SERVER-016 (IdempotencyLockTimeout)` → **503** despite `Category::Timeout` → 504.
     Rationale: the lock timeout is a transient server-side serialization delay, not a
     provider/upstream timeout — 503 is the correct retryable-service-unavailable code.
     `RetryHint::Later` + `Retry-After` header are emitted. Source: BC-2.12.006 EC-002;
     interface-definitions.md §HTTP Status Codes (503 row); F-P25-01.
   - `E-GRAPH-002 (NoActiveInterrupt)` → **422** despite `Category::Policy` → 403.
     Rationale: the resume endpoint (`POST /threads/{thread_id}/runs/{run_id}/resume`)
     receives a well-formed request for a run with no active interrupt slot — this is a
     semantic state validation failure (422 Unprocessable Entity: the request cannot be
     processed because the entity's current state makes it impossible), not a policy
     rejection (403 would mean "you are not permitted to perform this action"). 422
     conveys "the run exists and you are authorized, but there is nothing to resume."
     Canon established pass-23; prior 409 entry retired. Source: BC-2.05.005 TV-003;
     interface-definitions.md §HTTP Status Codes (422 row); F-P27-01.
4. {PC-004} The `Content-Type` header of the response is `application/problem+json` (not
   `application/json`) when a `ProblemDetail` is emitted.
5. {PC-005} A `PregolyaError` without an HTTP context (e.g. raised in a CLI tool) can still call
   `to_problem()` — the method does not require an HTTP runtime to produce the payload.

## Invariants

- {INV-001} The `type_uri` format `urn:pregolya:error:<code>` is the stable machine-readable identifier;
  monitoring rules and API clients must use `type_uri`, not `title` or `detail`, for error
  classification.
- {INV-002} `detail` may contain dynamic content (e.g. the invalid field name), but `type_uri` must not
  (it is always the static code like `E-CORE-001`).
- {INV-003} `retry_hint` top-level member uses the canonical string representation
  (`"never"`, `"maybe"`, `"later:<seconds>"`) for client machine readability.
  Sub-second `Duration` values ceiling-round to the next whole second (a 900 ms backoff hint emits `later:1`, not `later:0`). `Duration::ZERO` is the sole producer of `later:0` (retry-immediately / yield-to-scheduler sentinel per BC-2.14.001 EC-003). Saturation at `u64::MAX` is the overflow behavior — no panic.
- {INV-004} The categorical default Category→HTTP status mapping is defined once in
  `pregolya-core::error::PregolyaError::http_status()` (the "defined once" site).
  `pregolya-server` applies per-endpoint overrides and RFC-7807 response serialization on top
  of that categorical default, delegating the categorical mapping to `core::http_status()`
  rather than re-declaring the categorical table. A per-endpoint status specified in a resource
  BC overrides the categorical default; the categorical map is the fallback for errors with no
  per-endpoint specification. Legitimate per-endpoint divergences (e.g., E-SERVER-016
  TIMEOUT→503, E-SERVER-009 VAL→404 for direct lookup, E-SERVER-008 POLICY→409 for thread
  state conflict, E-GRAPH-002 POLICY→422 on resume endpoint) must be documented in {PC-003}
  and interface-definitions.md §HTTP Status Codes. Note: E-SERVER-004 POLICY→403 is NOT a
  divergence — POLICY→403 is the categorical default and requires no carve-out.
  The categorical map itself must not diverge; per-endpoint overrides must be explicit.
  Source: F-P25-01, OBS-1, ADV-P1D-PASS-25; F-P26-01, ADV-P1D-PASS-26; F-P27-01, ADV-P1D-PASS-27.

## Edge Cases

### EC-001: PregolyaError with RetryHint::Later in problem extension
**Scenario:** A rate-limited error `(Component::Prov, Category::Rate, retry_hint: Later(60s))` is
serialized to RFC-7807.
**Expected behavior:** `retry_hint` (top-level per RFC-7807 §3.2) is `"later:60"` (seconds as integer string).
The HTTP response may additionally include a `Retry-After: 60` header.

### EC-002: ProblemDetail emitted outside HTTP context
**Scenario:** A CLI tool calls `err.to_problem()` to format an error for structured log output.
**Expected behavior:** `to_problem()` is non-panicking under correct use — it returns a `ProblemDetail`
struct without requiring a `tokio::Runtime`. The struct can be serialized to JSON with `serde_json::to_string`.
`to_problem()` panics only on contract violation — specifically, when `self.component` has been assigned
a `Component::Custom` that violates BC-2.14.001 EC-002 rules after construction (e.g., a name that,
when lowercased, collides with a named component's identifier). This panic is intentional: it surfaces
the programmer error before a malformed URN reaches an RFC-7807 response. Callers should use only
well-formed `Component::Custom` names that pass the construction-time guard.

### EC-003: Nested PregolyaError source in problem detail
**Scenario:** A `PregolyaError` with a `source: Some(inner_err)` is converted to RFC-7807.
**Expected behavior:** The outer error's fields populate the top-level RFC-7807 fields. The inner
error is NOT recursively expanded in the problem detail (RFC-7807 does not specify a chain format).
For in-process debugging, the causal chain is accessible via `PregolyaError::source_arc()` (and
`std::error::Error::source`) — this access is in-process only and does not require any wire-format
change. The source chain is deliberately absent from `ProblemDetail`;
`test_BC_2_14_002_source_chain_not_leaked` verifies this non-emission property.

**{PC-001} authority:** {PC-001} closes the `ProblemDetail` wire shape at exactly five required
fields (`type_uri`, `title`, `detail`, `retry_hint`, `component`). There is no `detail_chain` field
on `ProblemDetail` — the causal chain is intentionally excluded from the wire encoding.
Future implementors: mechanical rewording of this edge case must not reintroduce a `detail_chain`
field name or any other name not listed in {PC-001}.

### EC-004: Multiple errors from a batch operation
**Scope note:** This edge case concerns `pregolya-server`-level response envelope design for batch
results — it does NOT describe a field of `ProblemDetail` itself. See {PC-001} for the closed
five-field `ProblemDetail` wire shape; `errors: [...]` is not one of those five fields.

**Scenario:** `batch()` returns `[Ok(r), Err(e1), Err(e2)]`. The server needs to emit an error
response.
**Expected behavior:** The server emits a single RFC-7807 `ProblemDetail` response for the first
error encountered. When the API contract for a specific endpoint supports multi-error responses, the
server may wrap multiple `ProblemDetail` objects in a `pregolya-server`-owned multi-error response
envelope (e.g., `{ "errors": [ ... ] }`) — this envelope is a server-layer concern, not a member of
`ProblemDetail` itself. The contract for the specific endpoint governs which format is used.

**This BC covers single-error problem emission only** (one `ProblemDetail` per response). Multi-error
envelope design is out of scope for this BC.

**{PC-001} authority:** {PC-001} closes the `ProblemDetail` wire shape at exactly five required
fields (`type_uri`, `title`, `detail`, `retry_hint`, `component`). Future implementors: mechanical
rewording of this edge case must not introduce an `errors` field or any other name not listed in
{PC-001} as a member of `ProblemDetail`.

### EC-005: Forward-compatibility guarantee for Category variants (compile-time exhaustiveness)
**Scenario:** A new `Category` variant is introduced in a future error-taxonomy iteration (e.g., a
15th category beyond the current 14: Val/Auth/Policy/Rate/Timeout/Transport/Concurrency/Security/
Tenancy/Durability/Internal/Tool/Exec/Sys).
**Expected behavior:** Every `match` mapping site that dispatches on `Category` —
specifically the categorical HTTP status map and the `category_title` mapping in
`pregolya-core`/`pregolya-server` — fails to compile. Because `Category` is a closed
`#[non_exhaustive]` enum with no wildcard arm in any of its match mappings, adding a new variant
is a source-breaking change caught at build time at every mapping site. There is no reachable
runtime path that yields `title: "Unknown"` or HTTP 500 for an "unknown" category; no unknown
category can exist at runtime. Compile-time exhaustiveness is the production-grade forward-compat
mechanism — strictly stronger than a runtime `title: "Unknown"` / 500 fallback. External crates
cannot introduce new Category variants (non_exhaustive prevents external enum construction).

## Canonical Test Vectors

_TV-001/TV-002/TV-005 use BC-2.14.001 rendering convention (ALL-CAPS taxonomy codes for component/category, e.g., `CORE`, `VAL`, `Never`) in table cells — this is prose shorthand, not compilable Rust. The actual test code constructs errors via `PregolyaError::new(...)` per BC-2.14.001 {PC-008}. This notation is intentional and should not be converted to `::new()` form._

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `PregolyaError { component: CORE, category: VAL, code: "E-CORE-001", retry_hint: Never, message: "Invalid ContentBlock type 'x'" }.to_problem()` | `{ "type": "urn:pregolya:error:E-CORE-001", "title": "Validation", "detail": "Invalid ContentBlock type 'x'", "retry_hint": "never", "component": "core" }` | Happy path — VAL error; extension members are top-level per RFC-7807 §3.2 |
| TV-002 | `PregolyaError { component: PROV, category: RATE, code: "E-PROV-001", retry_hint: Later(30s), message: "RateLimited" }.to_problem()` | HTTP status 429; `retry_hint: "later:30"` (top-level field per RFC-7807 §3.2) | Rate-limit with backoff |
| TV-003 | `ProblemDetail` serialized via `serde_json::to_string` | Valid JSON, no `null` fields except optional ones | RFC-7807 conformance |
| TV-004 | Response `Content-Type` header | `"application/problem+json"` | Correct MIME type |
| TV-005 | `PregolyaError { category: INTERNAL, .. }.to_problem()` HTTP status | 500 | Internal error → 500 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC214002-01 | `ProblemDetail` output is valid RFC-7807 JSON (type_uri is a URI, title is a string, detail is present) | Unit test + JSON schema validation | Wave 0 |
| VP-BC214002-02 | HTTP status code mapping covers all 14 categories (EXEC and SYS included; no category returns 200) | Parameterized unit test over Category enum variants | Wave 0 |

## Notes

- **EXEC category (D26):** `Category::Exec` is a library-layer-only error category added by D26 per ADR-010 §Category Axis Expansion (D26). At the `pregolya-server` HTTP layer, `EXEC` errors receive the categorical fallback `INTERNAL → 500`; there is no dedicated Known-overrides row for `EXEC` in {PC-003}. The parameterized test (VP-BC214002-02) must map `Category::Exec` to 500 via the INTERNAL-tier fallback — `EXEC` does not return 200 and the VP passes for this variant.

- **SYS category (error-taxonomy v1.59):** `Category::Sys` is the OS-level syscall failure category (EACCES, ELOOP, EIO — path resolution, process control, IPC) introduced in error-taxonomy v1.59 per burst-A2-error-coord/2026-08-26. At the `pregolya-server` HTTP layer, `SYS` errors receive the categorical default `500`; there is no dedicated Known-overrides row for `SYS` in {PC-003}. `E-SBXD-010 CanonicalizationFailed` is the first SYS code and is currently library-layer/blanket (does not reach the HTTP surface directly); however the categorical default of 500 is established so that any future SYS codes that do surface at HTTP have a defined mapping. The parameterized test (VP-BC214002-02) must map `Category::Sys` to 500 — `SYS` does not return 200 and the VP passes for this variant. Default RetryHint is `Maybe` (SYS default per error-taxonomy §Error Categories).

## Related BCs

- BC-2.14.001 — PregolyaError 2D struct (depends on: ProblemDetail is derived from PregolyaError fields)
- BC-2.12.003 — Run creation lifecycle (composes with: server run errors are emitted as RFC-7807 responses)

## Architecture Anchors

- `pregolya-core/src/error.rs` — `ProblemDetail` struct, `PregolyaError::to_problem()` method, and `PregolyaError::http_status()` categorical default mapping (the INV-004 "defined once" site) (to be created)
- `pregolya-server/src/error_response.rs` — per-endpoint override application and RFC-7807 response serialization; delegates categorical HTTP status mapping to `pregolya-core::error::PregolyaError::http_status()` rather than re-declaring the categorical table (to be created)

## Story Anchor

S-1.01

## VP Anchors

- VP-BC214002-01, VP-BC214002-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (PregolyaError 2D Struct)") per capabilities-p0.md §CAP-016 — CAP-016 explicitly includes "RFC-7807-compatible emission" as a required property of the error taxonomy surface; this BC implements that emission contract |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), I (integration) |
| Module | pregolya-core / pregolya-server |
