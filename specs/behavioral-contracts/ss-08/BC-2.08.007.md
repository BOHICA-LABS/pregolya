---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.007
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
timestamp: 2026-07-22T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-56): OBS-P56-2 codeless-error census (gate #30 first run) — EC-001, EC-003, EC-004, TV-001, TV-003, TV-005 each had category-only FerrochainError constructions with no code field. Added code: E-PROV-002 (ProviderTimeout) to TIMEOUT constructions and code: E-PROV-003 (StreamInterrupted) to TRANSPORT constructions per error-taxonomy.md BC anchors."
  - "1.2 (2026-07-15, F-P78-SWEEP/D18-P78-A): E-PROV-002 message-prefix correction. PC1: added 'ProviderTimeout:' prefix per universal <ErrorName>: <detail> convention (D18-P78-A adjudication; BC lacked prefix). Message was 'stream chunk timeout after <duration>'; corrected to 'ProviderTimeout: stream chunk timeout after <duration>'. Taxonomy E-PROV-002 corrected simultaneously: dropped '<provider>' parameter and changed '<ms>ms' to '<duration>' (BC wins on content — no provider name in BC message; duration placeholder more precise than ms-specific)."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-<provider> / ferrochain-<provider>-sdk per module-decomposition.md v1.10."
  - "1.4 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. EC-004 and TV-003 carried `Err(FerrochainError { category: TRANSPORT, code: E-PROV-003 })` bare wrappers; E-PROV-003 has `<provider>` and `<tokens>` placeholders. Added inline `message:` template to both; EC-004 is the authoritative full-form site; TV-003 PASS-ABBREV via EC-004."
  - "1.5 (burst-240/F-P140-02/2026-07-22): E-PROV-002 message generalized. PC1 message was 'ProviderTimeout: stream chunk timeout after <duration>' (stream-specific); generalized to 'ProviderTimeout: request timed out after <duration>' to align with taxonomy E-PROV-002 v1.34, which covers both per-chunk streaming stalls (this BC) and unary HTTP request timeouts (BC-2.14.004). The 'stream chunk' qualifier was a BC-level artifact; the generalized form remains accurate for the streaming stall case because the stall IS a request timeout on the per-chunk level. EC-001 description updated to remove the unsupported claim about the message containing the number of chunks (the message format has only <duration>; no chunk count placeholder exists). PASS-ABBREV sites (EC-001/EC-003/TV-001/TV-005) unchanged — all are bare wrapper form citing code: E-PROV-002 without inline message, abbreviated via PC1 as authoritative full-form site."
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
input-hash: "0cabfcd"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.007: Provider Streaming Interrupted by Transport Error Surfaces Err(Timeout) or Err(Transport), Not Truncated Success

## Description

When an SSE stream from a provider is interrupted mid-response — by a per-chunk stall
timeout, a TCP reset, or any other transport-layer error — the streaming call must
return `Err(FerrochainError { category: TIMEOUT | TRANSPORT })`. It must never return
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
   returns `Err(FerrochainError { category: TIMEOUT, code: E-PROV-002, message: "ProviderTimeout: request timed out
   after <duration>", … })` (where `<duration>` is the configured per-chunk timeout, e.g., "30s").
   No partial `AiMessage` is returned as `Ok`.
2. **TCP reset / connection drop → `Err(Transport)`:** When the underlying TCP
   connection is reset mid-stream, the streaming call returns `Err(FerrochainError
   { category: TRANSPORT, … })`. No partial content is surfaced as success.
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

- **DI-014 (Error Propagation (No Silent Swallowing)):** A transport error during
  streaming NEVER produces `Ok(partial_message)`. The `Ok` variant signifies a
  complete, non-truncated response.
- **DI-009 (Outbound Connection Timeout (Mandatory)):** The streaming client builder
  MUST set a connection timeout. Zero-argument `Client::new()` is prohibited in
  non-test code.
- Per-chunk timeout and total request timeout are both set. Per-chunk timeout is the
  primary guard against stalled SSE streams; total request timeout is the backstop
  against unboundedly long complete responses.

## Edge Cases

### EC-001: Stream stalls after first chunk
**Scenario:** The fixture delivers `message-start` + one `text` delta, then goes silent
for 31 seconds.
**Expected behavior:** `Err(FerrochainError { category: TIMEOUT, code: E-PROV-002 })`. The partial text
delta is discarded. The error message includes the configured timeout duration (PASS-ABBREV via PC1).

### EC-002: Stream completes normally with slow final chunk
**Scenario:** The provider takes 28 seconds to deliver the final `message-finish` event.
The per-chunk timeout is 30 seconds.
**Expected behavior:** `Ok(AiMessage)` — the stream completes successfully because
each individual chunk arrived within the 30-second per-chunk window, even though the
total response took 28 seconds.

### EC-003: Stream stalls before message-start
**Scenario:** The HTTP connection is established but no SSE bytes arrive within the
chunk timeout.
**Expected behavior:** `Err(FerrochainError { category: TIMEOUT, code: E-PROV-002 })`. The error fires
on the first chunk wait, not only after partial content is received.

### EC-004: TCP RST during deltaable block accumulation
**Scenario:** The stream has delivered `message-start`, `content-block-start{text,0}`,
and 5 text delta events. The TCP connection is then reset.
**Expected behavior:** `Err(FerrochainError { category: TRANSPORT, code: E-PROV-003,
message: "StreamInterrupted: TCP connection to '<provider>' reset mid-stream after <tokens> tokens" })`
(where `<provider>` = the provider adapter name, e.g., "openai"; `<tokens>` = approximate token count
at time of reset; both available at the raise site from the stream context). The 5 accumulated text deltas are not returned to the caller.

### EC-005: Client constructed without timeout (non-test code)
**Scenario:** `reqwest::Client::new()` is called in non-test provider code.
**Expected behavior:** CI lint `cargo xtask check-client-timeout` reports a violation
and fails the build. No runtime behavior change — this is a static enforcement gate.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Stream fixture stalls after chunk 1, per-chunk timeout = 100ms | `Err(FerrochainError { category: TIMEOUT, code: E-PROV-002 })` — no partial Ok | Per-chunk timeout |
| TV-002 | Stream fixture delivers all chunks within 29s, timeout = 30s | `Ok(AiMessage)` — complete response | Normal slow stream |
| TV-003 | Stream fixture delivers 0 chunks then TCP RST | `Err(FerrochainError { category: TRANSPORT, code: E-PROV-003, message: "StreamInterrupted: TCP connection to 'openai' reset mid-stream after 0 tokens" })` | Connection drop |
| TV-004 | `reqwest::Client::new()` in production src/ | CI lint reports violation; build fails | EC-005 |
| TV-005 | Stream stalls before message-start event | `Err(FerrochainError { category: TIMEOUT, code: E-PROV-002 })` | EC-003 — early stall |

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
| L2 Domain Invariants | DI-009 (Outbound Connection Timeout (Mandatory)), DI-014 (Error Propagation (No Silent Swallowing)) |
| NE References | NE-04 (mandatory HTTP timeout; P-77 counter-example — streaming clients without per-chunk timeout; primary BC anchor is BC-2.14.004; this BC adds the streaming-specific per-chunk dimension) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration — stalled/dropped stream fixtures), CI (lint — deny-client-new) |
| Module | ferrochain-<provider> / ferrochain-<provider>-sdk |
