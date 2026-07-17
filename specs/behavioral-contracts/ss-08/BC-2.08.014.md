---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.014
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-009
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (ADV-P81-01): F-P81-01 — TV-007 had fabricated PascalCase variant name `E-CORE-005 ValidationFailed`; no such variant exists in error-taxonomy.md (E-CORE-005 message is plain prose). Fixed to canonical bare-code form matching sibling BC-2.08.002 TV-005: `Err(FerrochainError { category: VAL, code: E-CORE-005 })`."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "6792fad"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.014: Provider Failover Chain (ProviderFallbackPolicy; Ordered Fallback on 429/5xx/Auth)

## Description

`ChatConfig.fallback_policy: Option<ProviderFallbackPolicy>` configures an ordered list of
alternative provider credentials to attempt when the primary provider returns a retriable
error (HTTP 429, any 5xx, or auth failure). On trigger, ferrochain optionally attempts a
credential refresh for the failing provider first; if the refresh fails or is not configured,
it falls over to the next provider in the ordered list. The run continues transparently on
the fallback provider — the graph never sees the underlying provider error. If all providers
in the chain are exhausted, `Err(E-PROV-010 ProviderChainExhausted)` is returned. This
contract is distinct from per-tool retry (SS-16 / CAP-018): that governs tool-level retries
on the same provider; this governs provider-level failover to a different provider.

> **Error code minted here (E-PROV-010).** `E-PROV-010 ProviderChainExhausted` is
> introduced by this BC. Category: POLICY. Severity: broken. RetryHint: Never.
> Taxonomy row registration: sub-burst 2.

## Preconditions

1. `ChatConfig` is constructed with a non-empty `fallback_policy: Some(ProviderFallbackPolicy {
   chain: Vec<ProviderCredential>, credential_refresh: Option<CredentialRefreshConfig> })`.
2. The primary provider is configured and a model call is in flight.
3. The primary provider returns a response with HTTP status 429, any HTTP 5xx, or an auth
   failure (HTTP 401/403 interpreted as `E-PROV-004 ProviderAuthFailed`).

## Postconditions

1. On receiving a **429 (rate limit)** from the primary provider:
   - ferrochain skips the credential-refresh step (rate limiting is not a credential problem).
   - ferrochain retries the call on the first available fallback provider in `chain`.
   - The graph call (`invoke` / `stream`) receives the fallback provider's response as if
     it were the primary's response. No error is surfaced to the graph for the 429.

2. On receiving a **5xx** from the primary provider:
   - ferrochain skips credential refresh.
   - ferrochain retries the call on the first available fallback provider.
   - Same transparent-continuation semantics as PC-1.

3. On receiving an **auth failure** (E-PROV-004) from the primary provider:
   - If `credential_refresh` is configured: ferrochain first attempts to refresh the
     primary provider's credentials. If refresh succeeds, the call is retried on the
     **primary** provider with the refreshed credentials.
   - If refresh fails or is not configured: ferrochain falls over to the first available
     fallback provider in `chain`.
   - The graph call continues transparently (no E-PROV-004 surfaced if a fallback succeeds).

4. **Ordered chain semantics:** fallback providers in `chain` are attempted in declaration
   order. If provider at index `i` also fails with a trigger condition, ferrochain moves to
   provider at index `i+1`.

5. **Chain exhausted:** if all providers in `chain` (and the primary) have been attempted
   and all returned trigger errors, ferrochain returns:
   `Err(FerrochainError { component: PROV, category: POLICY, code: "E-PROV-010",
   message: "ProviderChainExhausted: all <N> providers in fallback chain failed; last error:
   <last_error_code>/<last_provider>", retry_hint: Never })`.
   `N` is the total number of providers attempted (1 primary + `chain.len()` fallbacks).

6. **Non-trigger errors are not followed by failover:** if the primary provider returns a
   non-trigger error (VAL, TIMEOUT, TRANSPORT DNS failure unrelated to auth), the error is
   surfaced directly to the caller without attempting fallback. Failover is only for 429,
   5xx, and auth failures.

7. Credential values are never logged during failover (DI-010 Credential Opacity).

## Invariants

- **Failover is transparent to the graph:** the `StateGraph` node that issued the model
  call does not observe the failover; it receives the response as `Ok(AiMessage)` if any
  provider in the chain succeeds.
- **Each provider is attempted at most once per call** in a single failover sequence: the
  chain does not cycle (no round-robin retry back to the primary within one failover sequence).
- **ProviderFallbackPolicy is distinct from RetryPolicy (SS-16):** SS-16 governs per-tool
  retry with circuit breaking on the same provider. BC-2.08.014 governs provider-level
  failover to a different provider. The two policies compose: a retry policy may trigger
  before failover is considered; once retries are exhausted, failover kicks in.
- `ProviderFallbackPolicy.chain` must be non-empty at construction time.
  `ProviderFallbackPolicy { chain: vec![] }` is a VAL error (caught at config validation,
  not at runtime).
- No credentials from the fallback chain appear in log lines, error messages, or
  `FerrochainError.message` fields (DI-010).

## Edge Cases

### EC-001: Primary returns 429; fallback provider returns 200
**Scenario:** Primary provider returns HTTP 429. One fallback provider in chain returns HTTP 200.
**Expected behavior:** Graph receives the 200 response as if primary succeeded. No error
surfaced. One `DEBUG` log: `"Provider failover: <primary> → <fallback> (reason: 429)"`.

### EC-002: Primary auth fails; credential refresh succeeds; retry on primary succeeds
**Scenario:** Primary returns auth failure. `credential_refresh` is configured. Refresh call
succeeds. Retry on primary with refreshed credential returns HTTP 200.
**Expected behavior:** Graph receives 200. No error surfaced. No fallback provider in chain
is contacted. Debug log: `"Provider failover: auth refresh succeeded for <primary>; retrying"`.

### EC-003: Primary auth fails; refresh fails; fallback succeeds
**Scenario:** Primary auth failure. Refresh attempt fails. First fallback in chain returns 200.
**Expected behavior:** Graph receives 200 from fallback. No error surfaced. Debug log:
`"Provider failover: <primary> auth refresh failed; falling over to <fallback>"`.

### EC-004: All providers exhausted
**Scenario:** Primary returns 5xx. Chain has 2 fallbacks; both return 5xx.
**Expected behavior:** `Err(E-PROV-010 ProviderChainExhausted { providers_attempted: 3,
last_error: "E-PROV-008/provider-b" })`. `N = 3`.

### EC-005: Primary returns TIMEOUT; no failover triggered
**Scenario:** Primary returns `E-PROV-002 ProviderTimeout`.
**Expected behavior:** `Err(E-PROV-002 ProviderTimeout)` surfaced directly to caller.
Fallback chain is NOT attempted. TIMEOUT is not a failover trigger condition.

### EC-006: Empty fallback chain at config construction
**Scenario:** `ProviderFallbackPolicy { chain: vec![] }` passed to `ChatConfig`.
**Expected behavior:** `Err(FerrochainError { category: VAL, code: E-CORE-005,
message: "ProviderFallbackPolicy.chain must not be empty" })` at config construction time.
No runtime failover attempt occurs. (DI-008.)

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Primary returns 429; fallback-A returns 200 | Graph receives 200 response; no error | Happy-path failover on rate limit |
| TV-002 | Primary auth failure; `credential_refresh` configured and succeeds; retry on primary returns 200 | Graph receives 200; fallback never contacted | Credential refresh succeeds |
| TV-003 | Primary auth failure; refresh disabled; fallback-A returns 200 | Graph receives 200; fallback contacted once | Auth failure → immediate failover |
| TV-004 | Primary 5xx; fallback-A 5xx; fallback-B 200 | Graph receives fallback-B 200 | Chain depth 2 |
| TV-005 | Primary 5xx; fallback-A 5xx; fallback-B 5xx | `Err(E-PROV-010 ProviderChainExhausted)` with `providers_attempted: 3` | All exhausted |
| TV-006 | Primary TIMEOUT; failover configured | `Err(E-PROV-002 ProviderTimeout)` — no failover | TIMEOUT is not a trigger |
| TV-007 | `ProviderFallbackPolicy { chain: [] }` | `Err(FerrochainError { category: VAL, code: E-CORE-005 })` at construction | Empty chain is VAL error |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-FAILOVER-01 | Graph receives transparent response on failover (no E-PROV-001 or E-PROV-008 surfaced to graph) | Integration test with mock providers: primary returns 429, fallback returns 200; assert graph result is Ok | Wave 2 |
| VP-FAILOVER-02 | Credential values absent from all log lines and error messages during failover | Log capture test: trigger failover; assert no credential substring in logs | Wave 2 |

## Related BCs

- BC-2.16.001 — related to: per-tool retry (same provider, SS-16) is distinct from provider failover (different provider, this BC); policies compose
- BC-2.08.004 — depends on: PROV error codes (E-PROV-001, E-PROV-004, E-PROV-008) are the trigger conditions for failover; E-PROV-010 is minted here as the chain-exhausted signal

## Architecture Anchors

- `ferrochain-core/src/config.rs` — `ProviderFallbackPolicy { chain: Vec<ProviderCredential>, credential_refresh: Option<CredentialRefreshConfig> }`; `ChatConfig.fallback_policy: Option<ProviderFallbackPolicy>` (definitions in ferrochain-core following ADR-009 Option 3 split pattern)
- `ferrochain-<provider>/src/failover.rs` (or `ferrochain-<provider>/src/chat_model.rs`) — failover dispatch: intercepts trigger responses, attempts credential refresh (if configured), iterates fallback chain, surfaces E-PROV-010 on exhaustion

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-FAILOVER-01, VP-FAILOVER-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies provider-level failover semantics (ordered fallback chain on 429/5xx/auth) which extends the "provider abstraction" surface of CAP-009; as stated in CAP-009: "Architecture uses standalone SDK crate split (HS-6/D17-Q5)" — failover is a conformance-level concern about how ferrochain-<provider> handles multi-provider scenarios |
| L2 Domain Invariants | DI-008 (constructors return Result; empty chain is Err not panic), DI-009 (Outbound Connection Timeout — each provider call in the chain must set a connection timeout; BC-2.08.014 does not override DI-009), DI-010 (Credential Opacity — credentials from the fallback chain never appear in logs or error messages), DI-014 (Error Propagation — E-PROV-010 propagates as Err) |
| Error Code Minted | E-PROV-010 ProviderChainExhausted — POLICY, broken, Never. PROV namespace had 9 live codes after E-PROV-009 (from BC-2.08.013); E-PROV-010 is next. Taxonomy row: sub-burst 2. |
| Domain D Forcing Function | domain-d-hermes-agent.md req 10 — "[PARTIAL CAP-018/SS-16 + CAP-009/SS-08] … provider-level ordered fallback chain — retrying a DIFFERENT provider on 429/5xx/auth, with optional credential-refresh before failover — is not specified in any BC" |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-core (ProviderFallbackPolicy types) / ferrochain-<provider> (failover dispatch) |
