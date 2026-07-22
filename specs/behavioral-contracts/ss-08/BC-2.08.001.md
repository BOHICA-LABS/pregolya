---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.001
version: "1.3"
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
  - "1.1 (ADV-P1D-PASS-56-COMPLETION): Gate #30 second-pass census — EC-003 had `Err(FerrochainError { category: TRANSPORT, … })` (Unicode-ellipsis form) without specifying a code in this BC. Added code: E-PROV-003 (StreamInterrupted) explicitly to EC-003 per gate #30 rule: ellipsis forms are exempt only if the BC itself specifies the code for that path. Code confirmed from cross-referenced BC-2.08.007 EC-001/TV-001."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-<provider> / ferrochain-standard-tests per module-decomposition.md v1.10."
  - "1.3 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. EC-003 carried `Err(FerrochainError { category: TRANSPORT, code: E-PROV-003, … })` with Unicode-ellipsis abbreviation; cross-BC reference to BC-2.08.007 does not satisfy PASS-ABBREV (same-BC requirement). Expanded `…` to explicit inline message template with `<provider>` and `<tokens>` placeholders; cross-BC reference retained as informational note."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
  - domain-spec/capabilities-p1-p2.md#CAP-011
  - domain-spec/invariants.md#DI-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/partners/behavioral-intent.md
  - .factory/semport/partners/test-inventory.md
input-hash: "4909a1e"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.001: Chat Model Streaming Completions Conformance

## Description

Every ferrochain provider chat model must pass the `ferrochain-standard-tests`
streaming conformance battery: `test_stream`, `test_astream`, `test_stream_events_v3`,
and `test_astream_events_v3`. The v3 content-block protocol stream must satisfy the
`stream_lifecycle` oracle: `message-start` opens the stream, `message-finish` closes
it, block indices are sequential unsigned integers starting from 0, and deltaable block
types accumulate cleanly to the `content-block-finish` payload. Concatenating all
streamed chunks must produce the same final `AiMessage` as a unary `invoke` call (DI-011).

## Preconditions

1. A ferrochain provider chat model (one of: `ChatOpenAI`, `ChatAnthropic`,
   `ChatOllama`, or a conforming third-party adapter) is constructed with valid
   credentials and a model that supports streaming.
2. `ferrochain-standard-tests` is added as a `[dev-dependency]` in the provider crate's
   `Cargo.toml`.
3. The provider crate's integration test wires the standard-tests streaming battery by
   implementing `StandardChatModelTests` and supplying the model fixture.
4. A record/replay HTTP fixture layer (e.g., `wiremock` or cassette middleware) is
   available so the suite runs in CI without live provider keys.

## Postconditions

1. `test_stream` and `test_astream` pass: the stream yields ≥ 1 `AiMessageChunk`;
   concatenating all chunks via the core merge function produces a non-empty `AiMessage`.
2. `test_stream_events_v3` and `test_astream_events_v3` pass against the
   `stream_lifecycle` oracle:
   - The first event is a `message-start` event.
   - The last event is a `message-finish` event.
   - Block indices in `content-block-start` events are sequential unsigned integers
     starting at 0; indices may interleave across block types but must not skip.
   - For every deltaable block type (`text`, `reasoning`, `tool_call_chunk`,
     `server_tool_call_chunk`), the concatenation of all delta events equals the
     `content-block-finish` accumulated payload exactly.
3. The final `AiMessage` reconstructed from the stream is equal to the response
   produced by a unary `invoke` call with identical inputs (DI-011 enforcement).
4. The provider passes `test_stream_time`: the first chunk arrives within 5 seconds for
   a single-sentence prompt on the fixture layer.

## Invariants

- **DI-011 (Streaming / Unary Run Equivalence):** The streaming path and the unary
  path invoke the same translation logic; no stub code path emits events without
  actually driving the provider response.
- Block indices in a v3 stream are a contiguous sequence `[0, 1, 2, …]`; a gap in
  indices is a conformance violation.
- `message-start` and `message-finish` are strictly the first and last events;
  receiving `message-finish` before `message-start`, or receiving content events outside
  this envelope, is a conformance violation.
- Deltaable blocks: accumulated deltas MUST equal the `content-block-finish` payload —
  under no circumstances may the finish payload carry extra tokens not present in deltas.

## Edge Cases

### EC-001: Empty text response in stream
**Scenario:** The provider returns a stream with a single `text` block containing an
empty string (e.g., tool-only response where no text is generated).
**Expected behavior:** `message-start` → `content-block-start{type:text,index:0}` →
`content-block-finish{accumulated:""}` → `message-finish`. The final `AiMessage.content`
contains a `ContentBlock::Text` with `text: ""`. No panic or deserialization error.

### EC-002: Multiple concurrent block types (text + tool_call)
**Scenario:** The provider streams a response that interleaves a `text` block
(index 0) with a `tool_call_chunk` block (index 1).
**Expected behavior:** Both block streams are tracked independently. Index 0
accumulates text deltas; index 1 accumulates tool call deltas. Final message
contains `[ContentBlock::Text(...), ContentBlock::ToolCall(...)]` in index order.

### EC-003: Stream terminated mid-block (transport error)
**Scenario:** The SSE stream is closed by the provider mid-delta for block index 0.
**Expected behavior:** The stream yields `Err(FerrochainError { category: TRANSPORT, code: E-PROV-003,
message: "StreamInterrupted: TCP connection to '<provider>' reset mid-stream after <tokens> tokens" })`
(where `<provider>` is the provider adapter name; `<tokens>` is the approximate token count at reset;
both available at the raise site). No partial `AiMessage` is returned as a success value. (See also BC-2.08.007 EC-004 for the authoritative full-form site.)

### EC-004: Fixture cassette replay in CI
**Scenario:** The integration test runs in CI without network access; the HTTP fixture
layer replays a pre-recorded cassette.
**Expected behavior:** All streaming conformance tests pass against the cassette.
The cassette must faithfully encode SSE framing (chunk-by-chunk) — not a buffered
single-response cassette that bypasses streaming logic.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `stream("Say hello")` via cassette | ≥1 chunk; concat = "Hello!" (or locale equivalent from cassette) | Happy path |
| TV-002 | v3 stream oracle applied to TV-001 stream | Oracle reports: PASS (message-start present, message-finish present, indices sequential, deltas consistent) | v3 protocol compliance |
| TV-003 | `stream("Say hello")` concat vs `invoke("Say hello")` unary | Texts are equal (DI-011) | Streaming/unary equivalence |
| TV-004 | Stream with 2 text blocks interleaved | Block 0 and block 1 indices non-overlapping; both accumulate independently | Multi-block streaming |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208001-01 | v3 stream oracle: message-start/finish envelope invariant | Integration test (stream_lifecycle oracle) | Wave 2 |
| VP-BC208001-02 | Streaming/unary equivalence: concat(stream chunks) == invoke result | Integration test (compare text content) | Wave 2 |
| VP-BC208001-03 | Block index sequence is 0-based contiguous unsigned integers | Property test (arbitrary stream with n blocks) | Wave 2 |

## Related BCs

- BC-2.08.002 — tool-call round-trip (depends on: streaming tool-call chunks follow same v3 protocol)
- BC-2.08.006 — SDK crate split (depends on: streaming transport lives in `ferrochain-<provider>-sdk`)
- BC-2.08.007 — transport error on interrupted stream (composes with: EC-003 above)
- BC-2.12.007 — streaming/unary run equivalence at server level (DI-011 enforced by both)

## Architecture Anchors

- `ferrochain-<provider>/src/chat_model.rs` — `stream()` + `astream()` implementation (to be created)
- `ferrochain-standard-tests/src/chat_models/streaming.rs` — streaming conformance battery (to be created)
- `ferrochain-standard-tests/src/utils/stream_lifecycle.rs` — v3 oracle port (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208001-01, VP-BC208001-02, VP-BC208001-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009, CAP-011 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the streaming conformance gate every provider interface implementation must pass; CAP-011 ("Provider Conformance Suite (Standard Tests)") per capabilities-p1-p2.md §CAP-011 — this BC is the direct behavioral expression of the streaming subset of ferrochain-standard-tests |
| L2 Domain Invariants | DI-011 (Streaming / Unary Run Equivalence) |
| NE References | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration, standard-tests streaming battery), PT (property test — block index) |
| Module | ferrochain-<provider> / ferrochain-standard-tests |
