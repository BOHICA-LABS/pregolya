---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.004
version: "1.12"
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
timestamp: 2026-09-22T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-core (HTTP client factory) / xtask (lint gate) per module-decomposition.md v1.10."
  - "1.2 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. PC5, EC-003, and TV-004 all carried `Err(PregolyaError { category: TIMEOUT, code: \"E-PROV-002\" })` bare wrappers; E-PROV-002 has `<duration>` placeholder. Added inline `message:` template at all three sites; `<duration>` sourced from the configured HTTP client timeout value at the raise site."
  - "1.3 (burst-240/F-P140-02/2026-07-22): E-PROV-002 message generalized — PC5, EC-003, and TV-004 previously used 'ProviderTimeout: stream chunk timeout after <duration>' (stream-specific message); updated to 'ProviderTimeout: request timed out after <duration>' to match taxonomy E-PROV-002 v1.34. This BC covers unary HTTP request timeout (no stream, no chunk); the 'stream chunk' message was semantically wrong for this path. The generalized message is accurate: a unary HTTP client timeout IS a request timeout after the configured duration."
  - "1.4 (WAVE-B-B3/2026-07-29): Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon) + D-35 xtask rename (D-80). Notation: 5 CLASS3 VIOLATIONS corrected — PC5 multiline span added `, ..` before `}`; EC-003 multiline span added `, ..` before `}`; TV-004 Expected Output added `, ..`; Related BCs `PregolyaError { category: TIMEOUT }` added `, ..`; Traceability `PregolyaError { category: TIMEOUT }` added `, ..`. Xtask rename: 3 occurrences of `cargo xtask lint-no-timeout` → `cargo xtask check-client-timeout` in PC3, VP-DI009-01, Architecture Anchors. No behavioral change."
  - "1.5 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.02 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.6 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.7 (S-1.02-adv-pass-1/F-02+F-06/2026-09-22, product-owner): F-02 — EC-006 added for `ClientBuilder::build()` failure path citing E-CORE-012 (HttpClientBuildFailed, TRANSPORT, Never); E-CORE-012 minted in error-taxonomy.md §E-CORE-012 same burst. F-06 — Wave-0 scoped-coverage note added to {PRE-001} and §Description documenting that the xtask mechanical gate enforces the reqwest `ClientBuilder` surface only; non-reqwest HTTP clients (hyper, async-openai, etc.) are enforced by code-convention and adversarial review until a later wave introduces them and the gate is extended."
  - "1.8 (S-1.02-adv-pass-2/F-D/2026-09-22, product-owner): {PC-006} clarified — reqwest's total .timeout(duration) covers the full elapsed time including the TCP connection-establishment phase, so it satisfies DI-009 ('no indefinite hang') without requiring a separate .connect_timeout() call. Setting .connect_timeout() is recommended for faster failure-detection on providers with unreliable network paths, but is not required when a total .timeout(duration > 0) is already set. The prior text 'both must be set' was ambiguous about reqwest's semantics; the amended text aligns with the S-1.01 implementation (which sets .timeout() only) and the fundamental DI-009 guarantee."
  - "1.9 (S-1.02-adv-pass-4/F-06/2026-09-22, product-owner): {PC-005} pregolya-core scoping clarification added — build_client() satisfies DI-009 by setting .timeout(d > 0); the E-PROV-002 error-shape conversion is the provider adapter's responsibility (pregolya-openai/anthropic/ollama), verified in S-2.07 (unary invoke() path traces to this {PC-005}; streaming stall path is BC-2.08.007/AC-022 in S-2.07). TV-004 illustrative-path note added below Canonical Test Vectors table. pregolya-core does NOT produce E-PROV-002 directly."
  - "1.10 (S-1.02-adv-pass-15/F-P15-M04/2026-09-22, product-owner): EC-006 <reason> redefined to include mandatory credential-redaction and 200-char cap per DI-010 / BC-2.14.005 {INV-001} (CWE-209). The raw build() error string MUST NOT appear verbatim in the structured error; sanitize_error_message (or equivalent) must be applied before constructing the PregolyaError message field. Reference to BC-2.14.005 {INV-001} added to EC-006 Reference line."
  - "1.11 (F-P16-MED-004/2026-09-22, product-owner): EC-001 scoped-coverage note added: 'documented' qualifier enforced by {PC-002}/review, not by the mechanical gate (gate is comment-blind per token-stream parsing)."
  - "1.12 (F-PC006-scoped-coverage/2026-09-22, product-owner): {PC-006} scoped-coverage note added; conjunctive connect_timeout≤timeout constraint is review-enforced, not gate-enforced; gate extension deferred to first connect_timeout call site."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-009
  - NE-04
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "a8775d1"
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

Every outbound HTTP client construction in non-test pregolya code must call `.timeout(Duration::from_secs(30))`
(or a non-zero configured timeout) on the builder before building the client. Zero-argument
`Client::new()` (which uses no timeout) is prohibited outside test files. A CI lint gate
enforces this. This contract addresses NE-04 (adk-rust had 8+ sites calling `Client::new()` with
no `.timeout()`, causing indefinite hangs under network failure) and implements DI-009 (Outbound
Connection Timeout) uniformly.

> **Wave-0 scoped-coverage note (F-06/2026-09-22):** The mechanical gate (`cargo xtask check-client-timeout`)
> currently enforces the `reqwest::ClientBuilder` surface only. PRE-001 references "hyper, async-openai, or
> any other HTTP client crate" by intent, but the xtask AST scanner is bound to reqwest APIs in Wave 0.
> Non-reqwest HTTP clients are enforced by code-convention and adversarial review until a later wave
> introduces them and the gate is extended to cover those surfaces. Any Wave-0 story using a non-reqwest
> client must include an explicit timeout citation in its PR description as a manual gate substitute.

## Preconditions

1. {PRE-001} A pregolya crate is constructing an outbound HTTP client (via `reqwest`, `hyper`, `async-openai`,
   or any other HTTP client crate). **Wave-0 scoped-coverage:** the `cargo xtask check-client-timeout`
   mechanical gate enforces the reqwest `ClientBuilder` surface only; non-reqwest HTTP clients are covered
   by code convention and adversarial review until a later wave extends the gate.
2. {PRE-002} The construction is in non-test code (not `#[cfg(test)]` or `tests/` directory).
3. {PRE-003} The HTTP client will be used to make outbound calls to provider APIs, MCP servers, or
   external endpoints.

## Postconditions

1. {PC-001} Every `reqwest::ClientBuilder` (or equivalent from another HTTP crate) in non-test source
   must call `.timeout(duration)` with a `duration > Duration::ZERO` before `.build()`.
2. {PC-002} The recommended default timeout is `Duration::from_secs(30)`. Deviations from 30s must
   be documented with a comment citing the rationale (e.g. `// 5 min timeout for model inference`).
3. {PC-003} Zero-argument `Client::new()` (which bypasses the builder and applies no timeout) is absent
   from non-test library source. CI `cargo xtask check-client-timeout` (or equivalent custom clippy
   lint) causes the build to fail on any `Client::new()` call outside test files.
4. {PC-004} If the timeout duration is configurable at runtime (e.g. via `PregolyaConfig`), the default
   value in the config struct is `Duration::from_secs(30)` — not `Duration::ZERO` or `None`.
5. {PC-005} When the timeout fires, the HTTP client returns an error that the pregolya adapter converts
   to `Err(PregolyaError { category: TIMEOUT, code: "E-PROV-002",
   message: "ProviderTimeout: request timed out after <duration>", .. })`
   (where `<duration>` is the configured HTTP client timeout, e.g., "30s")
   — not a hang, not a panic.

   > **pregolya-core scoping note (F-06/2026-09-22):** pregolya-core's load-bearing obligation
   > under this postcondition is that `build_client()` configures `.timeout(d > 0)`, satisfying
   > DI-009. The conversion of the reqwest timeout error into E-PROV-002 error shape is the
   > responsibility of the provider adapter crates (`pregolya-openai`, `pregolya-anthropic`,
   > `pregolya-ollama`), verified in S-2.07. pregolya-core does NOT produce E-PROV-002 directly.

6. {PC-006} When the HTTP crate distinguishes connection timeout from total request timeout (as
   `reqwest` does via `.connect_timeout()` and `.timeout()` respectively), setting `.timeout(d > 0)`
   is sufficient to satisfy DI-009 — reqwest's `.timeout(duration)` measures total elapsed time
   from the start of the request including the connection-establishment phase, so a stuck TCP
   handshake is terminated once the total timeout fires. Setting a separate `.connect_timeout(d)`
   is recommended for faster failure detection on providers with unreliable network paths (e.g.
   multi-datacenter routing, high-latency upstreams), but is not required when a total
   `.timeout(duration > 0)` is already set. If both are configured, `.connect_timeout()` must also
   be a non-zero duration less than or equal to the total `.timeout()` (e.g.
   `.connect_timeout(Duration::from_secs(10)).timeout(Duration::from_secs(30))`).

   > **Scoped-coverage note (BC-2.14.004 {PC-006}):** The conjunctive constraint
   > (`.connect_timeout() > 0` AND `.connect_timeout() ≤ .timeout()`) is enforced by code
   > convention and PR review, NOT by `cargo xtask check-client-timeout`. The gate verifies
   > only that `.timeout(d > 0)` is called before `.build()` — it cannot compare two duration
   > values at AST-scan time. The gate will be extended to check `.connect_timeout()`
   > coordination when the first `.connect_timeout()` call site lands in the codebase.

## Invariants

- {INV-001} **DI-009 (Outbound Connection Timeout (Mandatory)):** No outbound call may hang indefinitely. Any code
  path that produces an outbound HTTP call must have a timeout enforced at the client level.
- {INV-002} **NE-04 enforcement:** The specific counter-example (adk-rust 8+ `Client::new()` sites) is
  the prototype for this CI gate.
- {INV-003} Zero-argument `Client::new()` in test files is explicitly permitted — tests may use default
  clients against local mock servers.
- {INV-004} A timeout of `None` (unlimited) is never the default in any pregolya config struct, even
  if the HTTP crate supports it.

## Edge Cases

### EC-001: Provider-specific client with longer streaming timeout
**Scenario:** A streaming model inference call may take 5 minutes for a large output. The standard
30s timeout would terminate it prematurely.
**Expected behavior:** The provider adapter constructs a streaming client with a longer timeout
(e.g. `Duration::from_secs(300)`) via a named constant or config field. The code includes a
comment: `// Extended timeout for streaming inference completions (default 300s)`. The CI lint
accepts non-default timeouts as long as they are non-zero and documented.

> **Scoped-coverage note:** The *non-zero* criterion is enforced mechanically by the token-parsing
> gate (which discards `//` source comments and cannot inspect inline documentation). The
> *documented* qualifier is a code-convention expectation enforced by peer review and {PC-002};
> it falls outside the mechanical gate's scope.

### EC-002: Client::new() in a test helper
**Scenario:** `#[cfg(test)] fn make_test_client() -> Client { Client::new() }`.
**Expected behavior:** The lint does not flag this. Test files and `#[cfg(test)]` blocks are
fully exempt from the `Client::new()` prohibition.

### EC-003: Timeout fires mid-streaming-response
**Scenario:** A streaming provider response begins but the connection goes silent after 5 chunks
for longer than the timeout duration.
**Expected behavior:** The client's timeout mechanism terminates the connection. The pregolya
adapter catches the timeout error from the HTTP client and yields
`Err(PregolyaError { category: TIMEOUT, code: "E-PROV-002",
message: "ProviderTimeout: request timed out after <duration>", .. })`
(where `<duration>` is the configured timeout, e.g., "30s") to the caller.
No partial output is silently promoted to a successful response.
**Reference:** error-taxonomy.md E-PROV-002.

### EC-004: Custom HTTP client passed in by the application
**Scenario:** Application code constructs its own `reqwest::Client` and passes it to a
pregolya provider constructor.
**Expected behavior:** pregolya accepts externally-provided clients. The CI lint applies only
to pregolya-internal client construction; the application is responsible for configuring its
externally-provided client appropriately. A warning is logged if a provided client appears to have
no timeout (detectable via a wrapper type that tracks timeout configuration).

### EC-005: ConnectionPool reuse across requests
**Scenario:** A single `Client` instance (with `.timeout(30s)`) is reused for all provider
requests over the lifetime of the application.
**Expected behavior:** Client reuse is the intended pattern — not creating a new client per
request. The timeout applies to each individual request, not the client's lifetime.

### EC-006: ClientBuilder::build() returns Err (TLS or proxy configuration failure)
**Scenario:** `reqwest::ClientBuilder::new().timeout(Duration::from_secs(30)).build()` returns
`Err(...)` at construction time — e.g., the TLS backend is unavailable on this platform, the
configured proxy URI has an unsupported scheme, or a required system certificate could not be
loaded.
**Expected behavior:** The HTTP client factory function propagates the build error as
`Err(PregolyaError { category: TRANSPORT, code: "E-CORE-012",
message: "HttpClientBuildFailed: failed to build HTTP client: <reason>", .. })`
where `<reason>` is the display string from the `build()` Err return, sanitized per
DI-010 / BC-2.14.005 {INV-001}: URL-embedded credentials redacted to `://***@host` and the
message capped at 200 characters to prevent credential leakage (CWE-209). The raw `build()`
error string MUST NOT appear verbatim in the structured error — `sanitize_error_message`
(or equivalent) must be applied before constructing the `PregolyaError` message field.
No `Client` is constructed; the operation fails before any outbound connection is attempted.
**RetryHint:** Never — the same `ClientBuilder` configuration will reproduce the build failure
immediately on retry; recovery requires fixing the TLS or proxy configuration.
**Reference:** error-taxonomy.md E-CORE-012; BC-2.14.005 {INV-001} (DI-010 Credential Opacity).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `ClientBuilder::new().timeout(Duration::from_secs(30)).build()` in production code | `Ok(Client { ... })` — lint passes | Happy path — correct builder pattern |
| TV-002 | `Client::new()` in `src/provider/openai.rs` (non-test) | CI lint error: "`Client::new()` in non-test code; use `ClientBuilder::new().timeout(...)` instead" | Lint enforcement |
| TV-003 | `ClientBuilder::new().build()` (no `.timeout()` call) | CI lint error: missing `.timeout()` call on `ClientBuilder` | Missing timeout |
| TV-004 | Mock server with 35s response delay; client timeout set to 30s | `Err(PregolyaError { category: TIMEOUT, code: "E-PROV-002", message: "ProviderTimeout: request timed out after 30s", .. })` received before server responds | Timeout fires correctly |
| TV-005 | `Client::new()` inside `#[cfg(test)]` block | CI lint passes — test exemption | Test code exempt |

> **TV-004 illustrative-path note (F-06/2026-09-22):** TV-004 illustrates the end-to-end path
> from client timeout through the provider adapter to the E-PROV-002 error shape. The load-bearing
> E-PROV-002 shape assertion belongs in S-2.07 (provider-crate story). S-1.02 verifies that the
> timeout fires on the client side (DI-009 compliance); the E-PROV-002 shape conversion is the
> provider adapter's responsibility, anchored in S-2.07 under BC-2.14.004 {PC-005} (unary path)
> and BC-2.08.007/AC-022 (streaming path).

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI009-01 | Zero `Client::new()` occurrences in non-test pregolya source across all crates | CI `cargo xtask check-client-timeout` | Wave 0 CI |
| VP-DI009-02 | All `ClientBuilder` usages in non-test code have `.timeout(d)` with `d > 0` | CI custom clippy lint | Wave 0 CI |

## Related BCs

- BC-2.14.001 — PregolyaError 2D struct (depends on: timeout errors propagate as PregolyaError { category: TIMEOUT, .. })
- BC-2.14.003 — Constructor Result contract (composes with: HTTP client construction is a fallible operation returning Result)
- BC-2.08.007 — Provider streaming transport error (composes with: timeout during streaming is surfaced as Err(Timeout))
- BC-2.09.001 — MCP server tool discovery (composes with: MCP server connections use timeout-enforced clients)

## Architecture Anchors

- All `pregolya-*/src/**/*.rs` non-test source files — `Client::new()` prohibition and `.timeout()` enforcement
- CI: `cargo xtask check-client-timeout` target (to be created)
- `pregolya-core/src/http.rs` — default HTTP client factory with timeout config (to be created)

## Story Anchor

S-1.02

## VP Anchors

- VP-DI009-01, VP-DI009-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (PregolyaError 2D Struct)") per capabilities-p0.md §CAP-016 — timeout enforcement is a mandatory component of the error taxonomy surface: a `PregolyaError { category: TIMEOUT, .. }` can only be reliably raised if all HTTP clients have non-zero timeouts; the capability's "Overflow §Security-PRD-Carry-Forward" covers NE-04 as a named Wave 0 enforcement item |
| L2 Domain Invariants | DI-009 (Outbound Connection Timeout (Mandatory)) |
| NE References | NE-04 (adk-rust 8+ sites with no `.timeout()` are the counter-example) |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | CI lint, I (integration with mock server) |
| Module | pregolya-core (HTTP client factory) / xtask (lint gate) |
