---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.007
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
  - domain-spec/invariants.md#DI-014
  - domain-spec/invariants.md#DI-009
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/partners/behavioral-intent.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "4bf3ed649311bea0978286c57d4e17f5332f8cb1edde7b67f13e73578e597e52"
---

# BC-2.08.007: Provider Streaming Interrupted by Transport Error Surfaces Err(Timeout) or Err(Transport), Not Truncated Success

## Description

When an SSE stream from a provider is interrupted mid-response — by a per-chunk stall
timeout, a TCP reset, or any other transport-layer error — the streaming call must
return `Err(FerrochainError { category: Timeout | Transport })`. It must never return
`Ok(AiMessage)` with a partial or truncated content as if the response were complete.
This contract closes the adk-rust P-77 pattern (NE-04) where streaming clients had no
per-chunk timeout, allowing indefinitely hung streams to silently produce incomplete
results.

## Preconditions

1. A ferrochain provider chat model is constructed with streaming enabled and a
   per-chunk timeout configured (recommended: `Duration::from_secs(30)` for each SSE
   chunk; separate from the total request timeout).
2. A test fixture can simulate a stalled stream: the fixture delivers the first N SSE
   chunks normally, then stops sending without closing the connection.
3. The provider's streaming HTTP client wraps the SSE reader with a per-chunk timeout
   guard (e.g., `tokio::time::timeout` applied around each `next()` call on the stream).

## Postconditions

1. **Per-chunk stall → `Err(Timeout)`:** When an SSE stream stalls (no bytes received)
   for longer than the configured per-chunk timeout, the streaming call terminates and
   returns `Err(FerrochainError { category: Timeout, message: "stream chunk timeout
   after <duration>", … })`. No partial `AiMessage` is returned as `Ok`.
2. **TCP reset / connection drop → `Err(Transport)`:** When the underlying TCP
   connection is reset mid-stream, the streaming call returns `Err(FerrochainError
   { category: Transport, … })`. No partial content is surfaced as success.
3. **Chunks received before interrupt are NOT returned as `Ok`:** There is no API shape
   that returns both accumulated partial content AND an error. The caller receives
   either a complete `Ok(AiMessage)` or a typed `Err`.
4. **Per-chunk timeout is independent of total request timeout:** The per-chunk timeout
   fires when no new SSE data arrives for the configured duration, even if the total
   elapsed time is below the total request timeout.
5. **Zero client timeouts are disallowed (DI-009 / NE-04):** Constructing the streaming
   HTTP client without specifying a timeout (zero-argument `Client::new()` or equivalent)
   is disallowed in non-test code. CI lint enforces this.

## Invariants

- **DI-014 (Error Propagation — No Silent Swallowing):** A transport error during
  streaming NEVER produces `Ok(partial_message)`. The `Ok` variant signifies a
  complete, non-truncated response.
- **DI-009 (Outbound Connection Timeout — Mandatory):** The streaming client builder
  MUST set a connection timeout. Zero-argument `Client::new()` is prohibited in
  non-test code.
- Per-chunk timeout and total request timeout are both set. Per-chunk timeout is the
  primary guard against stalled SSE streams; total request timeout is the backstop
  against unboundedly long complete responses.

## Edge Cases

### EC-001: Stream stalls after first chunk
**Scenario:** The fixture delivers `message-start` + one `text` delta, then goes silent
for 31 seconds.
**Expected behavior:** `Err(FerrochainError { category: Timeout })`. The partial text
delta is discarded. The error message includes the duration waited and the number of
chunks received before stall.

### EC-002: Stream completes normally with slow final chunk
**Scenario:** The provider takes 28 seconds to deliver the final `message-finish` event.
The per-chunk timeout is 30 seconds.
**Expected behavior:** `Ok(AiMessage)` — the stream completes successfully because
each individual chunk arrived within the 30-second per-chunk window, even though the
total response took 28 seconds.

### EC-003: Stream stalls before message-start
**Scenario:** The HTTP connection is established but no SSE bytes arrive within the
chunk timeout.
**Expected behavior:** `Err(FerrochainError { category: Timeout })`. The error fires
on the first chunk wait, not only after partial content is received.

### EC-004: TCP RST during deltaable block accumulation
**Scenario:** The stream has delivered `message-start`, `content-block-start{text,0}`,
and 5 text delta events. The TCP connection is then reset.
**Expected behavior:** `Err(FerrochainError { category: Transport })`. The 5
accumulated text deltas are not returned to the caller.

### EC-005: Client constructed without timeout (non-test code)
**Scenario:** `reqwest::Client::new()` is called in non-test provider code.
**Expected behavior:** CI lint `cargo xtask check-client-timeout` reports a violation
and fails the build. No runtime behavior change — this is a static enforcement gate.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Stream fixture stalls after chunk 1, per-chunk timeout = 100ms | `Err(FerrochainError { category: Timeout })` — no partial Ok | Per-chunk timeout |
| TV-002 | Stream fixture delivers all chunks within 29s, timeout = 30s | `Ok(AiMessage)` — complete response | Normal slow stream |
| TV-003 | Stream fixture delivers 0 chunks then TCP RST | `Err(FerrochainError { category: Transport })` | Connection drop |
| TV-004 | `reqwest::Client::new()` in production src/ | CI lint reports violation; build fails | EC-005 |
| TV-005 | Stream stalls before message-start event | `Err(FerrochainError { category: Timeout })` | EC-003 — early stall |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208007-01 | Per-chunk stall returns Err(Timeout), never Ok(partial) | Integration test (stalled stream fixture) | Wave 2 |
| VP-BC208007-02 | TCP reset during streaming returns Err(Transport), not Ok | Integration test (connection drop fixture) | Wave 2 |
| VP-BC208007-03 | Zero `Client::new()` calls in non-test provider code | CI lint (cargo xtask check-client-timeout) | Wave 2 |

## Related BCs

- BC-2.08.001 — streaming conformance (happy-path streaming; this BC covers the error path)
- BC-2.08.004 — error fidelity (Timeout and Transport are FerrochainError categories)
- BC-2.14.004 — mandatory HTTP timeout (DI-009; shared invariant — BC-2.14.004 covers the total-request timeout; this BC adds the per-chunk stream timeout)

## Architecture Anchors

- `ferrochain-<provider>/src/streaming.rs` — per-chunk timeout wrapper (to be created)
- `ferrochain-<provider>-sdk/src/http.rs` — client builder with mandatory timeout (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208007-01, VP-BC208007-02, VP-BC208007-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the streaming timeout and transport error propagation requirement for every provider implementation, closing the adk-rust P-77 must-not-inherit pattern |
| L2 Domain Invariants | DI-009 (Outbound Connection Timeout — Mandatory), DI-014 (Error Propagation — No Silent Swallowing) |
| NE References | NE-04 (mandatory HTTP timeout; P-77 counter-example — streaming clients without per-chunk timeout; primary BC anchor is BC-2.14.004; this BC adds the streaming-specific per-chunk dimension) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration — stalled/dropped stream fixtures), CI (lint — deny-client-new) |
| Module | [architect to assign — ferrochain-<provider>, ferrochain-<provider>-sdk] |
