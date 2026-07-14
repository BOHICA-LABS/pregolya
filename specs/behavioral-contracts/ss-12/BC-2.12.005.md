---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.005
version: "1.3"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-12
capability: CAP-014
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
  - domain-spec/invariants.md#DI-013
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/platform/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
input-hash: "b506940d5471ef7d546044ca7eaa600c281dac7c933cddffe52f1914f4be2ae7"
changelog:
  - "1.1 (ADV-P1D-PASS-26): F-P26-04 removed debug_route_path reference from invariant — debug route is fixed at /_debug (minimal config surface decision; TVs do not depend on a configurable path)."
  - "1.2 (ADV-P1D-PASS-27): F-P27-05 removed stale '(or the configured debug route path)' parenthetical from PC4 — residue of the pre-P26-04 configurable-path design; path is fixed at /_debug."
  - "1.3 (ADV-P1D-PASS-28): OBS-P28-1 removed inline fix-annotation residue from PC4 body — the F-P27-05 inline parenthetical '(F-P27-05: removed ...) was annotation residue in the postcondition text; correction is preserved only in the changelog."
---

# BC-2.12.005: SecurityConfig::default() Denies CORS; Debug Route Gated on Explicit Opt-In Key (NE-14)

## Description

`SecurityConfig::default()` in `ferrochain-server` must be **secure by default**: no
CORS wildcard is emitted, and the debug/introspection route (`/_debug` or equivalent)
is inaccessible without an explicit opt-in key in the server configuration. This
contract is the direct correction of the adk-rust counter-example (P-45), where
`SecurityConfig::default()` produced a CORS-open server with an unauthenticated debug
route. Any request to the debug route without a configured key returns `403 Forbidden`
— not `200`, `404`, or any other status code that could leak information or silently pass.

## Preconditions

1. `ferrochain-server` is started with `SecurityConfig::default()` (no custom config
   provided).
2. An HTTP client sends a cross-origin request with an `Origin` header.
3. An HTTP client sends a request to the debug/introspection route (`/_debug`).

Separately, for the opt-in path:
4. `SecurityConfig` is constructed with `debug_route_key: Some("non-empty-key")`.
5. A request is made to `/_debug` with `Authorization: Bearer <key>` matching the
   configured key.

## Postconditions

**CORS default:**
1. No `Access-Control-Allow-Origin: *` header appears in any response from a server
   using `SecurityConfig::default()`.
2. Preflight `OPTIONS` requests with an `Origin` header that is not in the
   `allowed_origins` list receive a response with no `Access-Control-Allow-Origin`
   header (cross-origin request silently denied at the CORS layer).
3. Same-origin requests (no `Origin` header) are not affected by CORS settings.

**Debug route default:**
4. `GET /_debug` with no `Authorization` header returns `403 Forbidden` with body
   `E-SERVER-004 DebugRouteUnauthorized`.
5. `GET /_debug` with a `Authorization: Bearer <wrong-key>` also returns `403`.
6. `GET /_debug` with a `Authorization: Bearer <correct-key>` (matching
   `debug_route_key` in config) returns `200 OK` with the introspection payload.
7. `GET /_debug` when `debug_route_key` is `None` (default) returns `403` regardless
   of any supplied `Authorization` header — there is no bypass.

## Invariants

- **DI-013 (Secure Server Defaults):** `SecurityConfig::default()` sets `allowed_origins`
  to an empty list (CORS denied); `debug_route_key` is `None` (debug route inaccessible);
  unauthenticated access to the debug route returns `403`, never `200` or `404`.
- The debug route path is fixed at `/_debug` and cannot be served without the key
  regardless of middleware ordering. `debug_route_path` is NOT a config option — the
  path is a fixed constant. (F-P26-04: removed configurable-path reference; decision:
  minimal config surface + secure-default simplicity; TVs all use `/_debug` hardcoded.)
- Constructing `SecurityConfig` with an explicit `allowed_origins: [AllowOrigin::Any]`
  (CORS wildcard) is permitted for local-dev use cases, but the server emits a `WARN`
  log on startup: `"SecurityConfig: CORS wildcard configured — do not use in production"`.

## Edge Cases

### EC-001: Explicitly allowed CORS origin passes
**Scenario:** `SecurityConfig` is configured with `allowed_origins: ["https://app.example.com"]`.
An `OPTIONS` request arrives with `Origin: https://app.example.com`.
**Expected behavior:** `Access-Control-Allow-Origin: https://app.example.com` is
returned; the preflight succeeds. Other origins are still rejected.

### EC-002: Debug route with wrong key returns 403, not 404
**Scenario:** Server configured with `debug_route_key: Some("correct-key")`. Request:
`GET /_debug` with `Authorization: Bearer wrong-key`.
**Expected behavior:** `403 Forbidden` with `E-SERVER-004 DebugRouteUnauthorized`. The
`404` response must NOT be returned (returning `404` would leak whether the route
exists; `403` is the correct secure response in both cases: key absent and key wrong).

### EC-003: CORS wildcard config emits startup warning
**Scenario:** `SecurityConfig { allowed_origins: [AllowOrigin::Any], .. }` is passed
at server startup.
**Expected behavior:** Server starts (it is not a fatal error), but a `WARN`-level log
line is emitted at startup: `"SecurityConfig: CORS wildcard configured — do not use in
production"`. The warning fires on every startup, not just first-run.

### EC-004: Default config; non-debug route not affected
**Scenario:** `SecurityConfig::default()`; `GET /threads` (a standard API route).
**Expected behavior:** `200 OK` (assuming authentication passes for this route). The
debug-route gate does not apply to non-debug routes.

### EC-005: Empty `debug_route_key` string treated as None
**Scenario:** Operator accidentally sets `debug_route_key: Some("")` (empty string).
**Expected behavior:** The server rejects this at startup with `E-SERVER-013
InvalidDebugRouteKey { reason: "debug_route_key must be non-empty" }`. An empty string
would effectively disable the gate — this must not be permitted.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Default config; `OPTIONS /_debug` with `Origin: https://evil.com` | No `Access-Control-Allow-Origin` header in response; status `403` | CORS wildcard absent — NE-14 counter-example corrected |
| TV-002 | Default config; `GET /_debug` with no `Authorization` | `403 Forbidden`, body contains `E-SERVER-004 DebugRouteUnauthorized` | Debug gate: no key configured, no access |
| TV-003 | Default config; `GET /_debug` with `Authorization: Bearer anything` | `403 Forbidden` | Debug gate: no key configured = no bypass |
| TV-004 | Config with `debug_route_key = "s3cr3t"`; `GET /_debug` with `Authorization: Bearer s3cr3t` | `200 OK` with introspection JSON payload | Opt-in path: correct key succeeds |
| TV-005 | Config with `debug_route_key = "s3cr3t"`; `GET /_debug` with `Authorization: Bearer wrong` | `403 Forbidden`, body `E-SERVER-004` | Wrong key → same 403 as no key |
| TV-006 | Default config; `GET /threads` (non-debug route) | `200 OK` (no interference from debug gate) | Debug gate does not affect normal routes |
| TV-007 | Config `debug_route_key: Some("")`; server startup | Startup `Err(E-SERVER-013 InvalidDebugRouteKey)` | Empty key rejected at config validation |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-SEC-01 | `SecurityConfig::default()` produces zero CORS wildcard headers across all response paths | Unit test + integration test (header assertion on every route for default config) | Phase 3 (security gate) |
| VP-SEC-02 | Debug route returns `403` for absent and wrong keys; returns `200` only for correct key | Unit test (parametrized over: no key, wrong key, correct key) | Phase 3 (security gate) |

## Related BCs

- BC-2.12.006 — related to: store trait seams form the other half of "secure-by-default" server infrastructure
- BC-2.13.001 — related to: DI-006 (enforcing sandbox default) is the parallel "secure-by-default" invariant for tool execution
- BC-2.11.002 — related to: DI-012 guardrail-on-ingress is a complementary defence-in-depth requirement

## Architecture Anchors

- `ferrochain-server/src/security.rs` — `SecurityConfig` struct and `Default` implementation
- `ferrochain-server/src/middleware/cors.rs` — CORS middleware consuming `SecurityConfig.allowed_origins`
- `ferrochain-server/src/routes/debug.rs` — `/_debug` route handler with `debug_route_key` gate

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-SEC-01, VP-SEC-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — ferrochain-server's security posture is a first-class property of the server itself; `SecurityConfig` is a server-level config struct named within the CAP-014 design scope |
| L2 Domain Invariants | DI-013 (Secure Server Defaults) |
| NE Reference | NE-14 — P-45 REJECT: `SecurityConfig::default()` → CORS wildcard + unauthenticated debug route is the adk-rust counter-example |
| CONFLICT Reference | P-36 ADOPT: ferrochain adopts the defence-in-depth default middleware stack and overrides the P-45 CORS-open default with deny-unless-configured posture |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | [architect to assign — ferrochain-server] |
