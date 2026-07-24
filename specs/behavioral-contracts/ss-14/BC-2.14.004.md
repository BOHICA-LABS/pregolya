---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.004
version: "1.3"
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
timestamp: 2026-07-22T00:00:00Z
changelog:
  - "1.3 (burst-240/F-P140-02/2026-07-22): E-PROV-002 message generalized — PC5, EC-003, and TV-004 previously used 'ProviderTimeout: stream chunk timeout after <duration>' (stream-specific message); updated to 'ProviderTimeout: request timed out after <duration>' to match taxonomy E-PROV-002 v1.34. This BC covers unary HTTP request timeout (no stream, no chunk); the 'stream chunk' message was semantically wrong for this path. The generalized message is accurate: a unary HTTP client timeout IS a request timeout after the configured duration."
  - "1.2 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. PC5, EC-003, and TV-004 all carried `Err(FerrochainError { category: TIMEOUT, code: \"E-PROV-002\" })` bare wrappers; E-PROV-002 has `<duration>` placeholder. Added inline `message:` template at all three sites; `<duration>` sourced from the configured HTTP client timeout value at the raise site."
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-core (HTTP client factory) / xtask (lint gate) per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-009
  - NE-04
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "e341da2"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.004: Every Outbound HTTP ClientBuilder Must Set .timeout(30s); Zero Client::new() Outside Tests

## Description

Every outbound HTTP client construction in non-test ferrochain code must call `.timeout(Duration::from_secs(30))`
(or a non-zero configured timeout) on the builder before building the client. Zero-argument
`Client::new()` (which uses no timeout) is prohibited outside test files. A CI lint gate
enforces this. This contract addresses NE-04 (adk-rust had 8+ sites calling `Client::new()` with
no `.timeout()`, causing indefinite hangs under network failure) and implements DI-009 (Outbound
Connection Timeout) uniformly.

## Preconditions

1. A ferrochain crate is constructing an outbound HTTP client (via `reqwest`, `hyper`, `async-openai`,
   or any other HTTP client crate).
2. The construction is in non-test code (not `#[cfg(test)]` or `tests/` directory).
3. The HTTP client will be used to make outbound calls to provider APIs, MCP servers, or
   external endpoints.

## Postconditions

1. Every `reqwest::ClientBuilder` (or equivalent from another HTTP crate) in non-test source
   must call `.timeout(duration)` with a `duration > Duration::ZERO` before `.build()`.
2. The recommended default timeout is `Duration::from_secs(30)`. Deviations from 30s must
   be documented with a comment citing the rationale (e.g. `// 5 min timeout for model inference`).
3. Zero-argument `Client::new()` (which bypasses the builder and applies no timeout) is absent
   from non-test library source. CI `cargo xtask lint-no-timeout` (or equivalent custom clippy
   lint) causes the build to fail on any `Client::new()` call outside test files.
4. If the timeout duration is configurable at runtime (e.g. via `FerrochainConfig`), the default
   value in the config struct is `Duration::from_secs(30)` — not `Duration::ZERO` or `None`.
5. When the timeout fires, the HTTP client returns an error that the ferrochain adapter converts
   to `Err(FerrochainError { category: TIMEOUT, code: "E-PROV-002",
   message: "ProviderTimeout: request timed out after <duration>" })`
   (where `<duration>` is the configured HTTP client timeout, e.g., "30s")
   — not a hang, not a panic.
6. Connection timeout and request timeout are both set (if the HTTP crate distinguishes them);
   a connection timeout without a request timeout still leaves the system vulnerable to slow
   responses, so both must be set to non-zero values.

## Invariants

- **DI-009 (Outbound Connection Timeout (Mandatory)):** No outbound call may hang indefinitely. Any code
  path that produces an outbound HTTP call must have a timeout enforced at the client level.
- **NE-04 enforcement:** The specific counter-example (adk-rust 8+ `Client::new()` sites) is
  the prototype for this CI gate.
- Zero-argument `Client::new()` in test files is explicitly permitted — tests may use default
  clients against local mock servers.
- A timeout of `None` (unlimited) is never the default in any ferrochain config struct, even
  if the HTTP crate supports it.

## Edge Cases

### EC-001: Provider-specific client with longer streaming timeout
**Scenario:** A streaming model inference call may take 5 minutes for a large output. The standard
30s timeout would terminate it prematurely.
**Expected behavior:** The provider adapter constructs a streaming client with a longer timeout
(e.g. `Duration::from_secs(300)`) via a named constant or config field. The code includes a
comment: `// Extended timeout for streaming inference completions (default 300s)`. The CI lint
accepts non-default timeouts as long as they are non-zero and documented.

### EC-002: Client::new() in a test helper
**Scenario:** `#[cfg(test)] fn make_test_client() -> Client { Client::new() }`.
**Expected behavior:** The lint does not flag this. Test files and `#[cfg(test)]` blocks are
fully exempt from the `Client::new()` prohibition.

### EC-003: Timeout fires mid-streaming-response
**Scenario:** A streaming provider response begins but the connection goes silent after 5 chunks
for longer than the timeout duration.
**Expected behavior:** The client's timeout mechanism terminates the connection. The ferrochain
adapter catches the timeout error from the HTTP client and yields
`Err(FerrochainError { category: TIMEOUT, code: "E-PROV-002",
message: "ProviderTimeout: request timed out after <duration>" })`
(where `<duration>` is the configured timeout, e.g., "30s") to the caller.
No partial output is silently promoted to a successful response.
**Reference:** error-taxonomy.md E-PROV-002.

### EC-004: Custom HTTP client passed in by the application
**Scenario:** Application code constructs its own `reqwest::Client` and passes it to a
ferrochain provider constructor.
**Expected behavior:** ferrochain accepts externally-provided clients. The CI lint applies only
to ferrochain-internal client construction; the application is responsible for configuring its
externally-provided client appropriately. A warning is logged if a provided client appears to have
no timeout (detectable via a wrapper type that tracks timeout configuration).

### EC-005: ConnectionPool reuse across requests
**Scenario:** A single `Client` instance (with `.timeout(30s)`) is reused for all provider
requests over the lifetime of the application.
**Expected behavior:** Client reuse is the intended pattern — not creating a new client per
request. The timeout applies to each individual request, not the client's lifetime.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `ClientBuilder::new().timeout(Duration::from_secs(30)).build()` in production code | `Ok(Client { ... })` — lint passes | Happy path — correct builder pattern |
| TV-002 | `Client::new()` in `src/provider/openai.rs` (non-test) | CI lint error: "`Client::new()` in non-test code; use `ClientBuilder::new().timeout(...)` instead" | Lint enforcement |
| TV-003 | `ClientBuilder::new().build()` (no `.timeout()` call) | CI lint error: missing `.timeout()` call on `ClientBuilder` | Missing timeout |
| TV-004 | Mock server with 35s response delay; client timeout set to 30s | `Err(FerrochainError { category: TIMEOUT, code: "E-PROV-002", message: "ProviderTimeout: request timed out after 30s" })` received before server responds | Timeout fires correctly |
| TV-005 | `Client::new()` inside `#[cfg(test)]` block | CI lint passes — test exemption | Test code exempt |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI009-01 | Zero `Client::new()` occurrences in non-test ferrochain source across all crates | CI `cargo xtask lint-no-timeout` | Wave 0 CI |
| VP-DI009-02 | All `ClientBuilder` usages in non-test code have `.timeout(d)` with `d > 0` | CI custom clippy lint | Wave 0 CI |

## Related BCs

- BC-2.14.001 — FerrochainError 2D struct (depends on: timeout errors propagate as FerrochainError { category: TIMEOUT })
- BC-2.14.003 — Constructor Result contract (composes with: HTTP client construction is a fallible operation returning Result)
- BC-2.08.007 — Provider streaming transport error (composes with: timeout during streaming is surfaced as Err(Timeout))
- BC-2.09.001 — MCP server tool discovery (composes with: MCP server connections use timeout-enforced clients)

## Architecture Anchors

- All `ferrochain-*/src/**/*.rs` non-test source files — `Client::new()` prohibition and `.timeout()` enforcement
- CI: `cargo xtask lint-no-timeout` target (to be created)
- `ferrochain-core/src/http.rs` — default HTTP client factory with timeout config (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-DI009-01, VP-DI009-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (FerrochainError 2D Struct)") per capabilities-p0.md §CAP-016 — timeout enforcement is a mandatory component of the error taxonomy surface: a `FerrochainError { category: TIMEOUT }` can only be reliably raised if all HTTP clients have non-zero timeouts; the capability's "Overflow §Security-PRD-Carry-Forward" covers NE-04 as a named Wave 0 enforcement item |
| L2 Domain Invariants | DI-009 (Outbound Connection Timeout (Mandatory)) |
| NE References | NE-04 (adk-rust 8+ sites with no `.timeout()` are the counter-example) |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | CI lint, I (integration with mock server) |
| Module | ferrochain-core (HTTP client factory) / xtask (lint gate) |
