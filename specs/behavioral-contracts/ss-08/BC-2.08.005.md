---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.005
version: "1.1"
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
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-<provider> / ferrochain-standard-tests per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
  - domain-spec/capabilities-p1-p2.md#CAP-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/partners/behavioral-intent.md
  - .factory/semport/partners/test-inventory.md
input-hash: "b6a1503"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.005: Chat Model Token-Usage Accounting Conformance

## Description

Every ferrochain provider chat model must populate a `UsageMetadata` struct in the
returned `AiMessage` when `returns_usage_metadata = true` (the default). The struct
must carry at minimum `input_tokens`, `output_tokens`, and `total_tokens`. Providers
that surface sub-detail counts (reasoning tokens, cache read/creation tokens, audio
tokens) must populate the relevant sub-fields and declare them in
`supported_usage_metadata_details`. Streaming usage must also be captured: the final
chunk in a streamed response must carry cumulative usage metadata when the provider
supports it.

## Preconditions

1. A ferrochain provider chat model is constructed with valid credentials and
   `returns_usage_metadata = true` (default).
2. The provider capability profile declares `supported_usage_metadata_details` as a
   set of sub-detail keys that this provider/model combination populates.
3. `ferrochain-standard-tests` is registered as a dev-dependency.
4. A record/replay HTTP fixture layer with pre-recorded usage metadata responses is
   available for CI.

## Postconditions

1. `test_usage_metadata` (gated by `returns_usage_metadata`): the `AiMessage` returned
   by `invoke` carries a non-None `usage_metadata: UsageMetadata` with:
   - `input_tokens: u64 > 0`
   - `output_tokens: u64 > 0`
   - `total_tokens == input_tokens + output_tokens` (unless the provider computes total
     differently, in which case the provider documents its formula and the test uses the
     provider's reported total)
2. `test_usage_metadata_streaming` (gated): the final `AiMessageChunk` in a streamed
   response carries cumulative `usage_metadata` equivalent to what the unary response
   would carry, when the provider supports streaming usage (negotiated via
   `stream_options: { include_usage: true }` for OpenAI).
3. Sub-detail fields declared in `supported_usage_metadata_details` are populated in
   the returned `UsageMetadata`:
   - `reasoning_tokens: Option<u64>` — non-None for Anthropic extended-thinking and
     OpenAI reasoning models.
   - `cache_read_input_tokens: Option<u64>` — non-None for Anthropic prompt-cache reads.
   - `cache_creation_input_tokens: Option<u64>` — non-None for Anthropic prompt-cache writes.
   - `audio_tokens: Option<u64>` — non-None for OpenAI audio input/output models.
4. Sub-detail fields NOT declared in `supported_usage_metadata_details` are `None`
   (not zero, not absent with default-zero behavior — callers must distinguish
   "not applicable" from "zero tokens used").

## Invariants

- `total_tokens` is always present when `input_tokens` and `output_tokens` are present.
  No provider adapter may return `input_tokens + output_tokens` without `total_tokens`.
- Sub-detail fields that the provider does not report are `None`, not `0`. Callers
  distinguish `None` ("this provider does not track this metric") from `Some(0)`
  ("zero tokens of this type were used this call").
- Streaming usage: the usage metadata on the final chunk is cumulative across the entire
  response — it is NOT per-chunk incremental usage.
- The `returns_usage_metadata` flag is `true` by default; a provider must explicitly set
  it to `false` only if the provider API does not support usage metadata at all.

## Edge Cases

### EC-001: Provider omits usage in streaming with stream_options
**Scenario:** OpenAI is called with streaming but `stream_options.include_usage` is not
negotiated (misconfigured provider).
**Expected behavior:** The final `AiMessageChunk.usage_metadata` is `None`. The test
`test_usage_metadata_streaming` fails explicitly (not silently passes with zeros).

### EC-002: Anthropic prompt cache read — cache_read_input_tokens populated
**Scenario:** An Anthropic request hits a prompt cache and returns
`"cache_read_input_tokens": 4000` in usage.
**Expected behavior:** `UsageMetadata { input_tokens: 10, output_tokens: 150,
total_tokens: 160, cache_read_input_tokens: Some(4000), … }`. The 4000 cached tokens
are NOT counted in `input_tokens` (they are a sub-detail).

### EC-003: OpenAI reasoning model — reasoning_tokens populated
**Scenario:** `o1` or `o3` model call returns `"reasoning_tokens": 800` in usage.
**Expected behavior:** `UsageMetadata { ..., reasoning_tokens: Some(800) }`. The
reasoning tokens are excluded from `output_tokens` (per OpenAI's definition) and
are tracked separately.

### EC-004: total_tokens mismatch with provider-reported value
**Scenario:** The provider reports `input: 100, output: 50, total: 160` (not 150).
This occurs when the provider bills differently (e.g., Anthropic rounds per-block).
**Expected behavior:** `total_tokens` is set to the provider-reported value (160), not
the computed `input + output` (150). The discrepancy is not silently corrected.

### EC-005: returns_usage_metadata = false
**Scenario:** Provider constructed with `returns_usage_metadata = false`.
**Expected behavior:** The `usage_metadata` field on the returned `AiMessage` is `None`.
No error is returned; the field is simply absent.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | invoke("Hello") via cassette with usage | `AiMessage { usage_metadata: Some(UsageMetadata { input_tokens: >0, output_tokens: >0, total_tokens: >0 }) }` | Basic usage accounting |
| TV-002 | stream("Hello") via cassette; final chunk | `AiMessageChunk { usage_metadata: Some(…) }` — cumulative | Streaming usage |
| TV-003 | Anthropic cassette with cache_read | `UsageMetadata { cache_read_input_tokens: Some(N) }` | Cache sub-detail |
| TV-004 | Provider with `returns_usage_metadata = false` | `AiMessage { usage_metadata: None }` | Opted-out |
| TV-005 | Provider total != input + output | `total_tokens` = provider value, not computed | EC-004 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208005-01 | total_tokens present whenever input/output present | Unit test (UsageMetadata constructor invariant) | Wave 2 |
| VP-BC208005-02 | Sub-detail None vs Some(0) distinction is preserved through deserialization | Unit test (serde round-trip — Option<u64> field) | Wave 2 |
| VP-BC208005-03 | Streaming final chunk carries cumulative (not per-chunk) usage | Integration test (sum chunks, compare to final) | Wave 2 |

## Related BCs

- BC-2.08.001 — streaming (streaming usage metadata arrives on the final chunk)
- BC-2.08.006 — SDK crate split (usage extraction lives in the SDK response translation)
- BC-2.08.008 — eval score aggregation (eval scoring may depend on usage metadata for cost tracking)

## Architecture Anchors

- `ferrochain-<provider>/src/usage_metadata.rs` — usage extraction and normalization (to be created)
- `ferrochain-standard-tests/src/chat_models/usage_metadata.rs` — usage accounting battery (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208005-01, VP-BC208005-02, VP-BC208005-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009, CAP-011 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the token-usage extraction and normalization requirement that every provider implementation must satisfy; CAP-011 ("Provider Conformance Suite (Standard Tests)") per capabilities-p1-p2.md §CAP-011 — this BC expresses the usage-accounting subset of ferrochain-standard-tests |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration, standard-tests usage battery), U (unit — serde round-trip, constructor invariant) |
| Module | ferrochain-<provider> / ferrochain-standard-tests |
