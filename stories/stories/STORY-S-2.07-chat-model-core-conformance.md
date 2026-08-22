---
document_type: story
level: ops
story_id: S-2.07
epic_id: E-19
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.003.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.005.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.007.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "db3c1d2"
traces_to: .factory/stories/STORY-INDEX.md
points: 13
depends_on: [S-2.06, S-1.07, S-1.06]
blocks: [S-2.08]
behavioral_contracts: [BC-2.08.001, BC-2.08.002, BC-2.08.003, BC-2.08.004, BC-2.08.005, BC-2.08.007]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: [pregolya-openai, pregolya-anthropic, pregolya-ollama]
subsystems: [SS-08]
estimated_days: 5
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: all 6 BCs active; no BC-TBD placeholders; status = draft per Spec-First Gate S-7.01
---

# S-2.07: Chat Model Core Conformance — Streaming, Tool-Call, Structured Output, Error Fidelity, Token Usage, Transport Error

## Narrative

- **As a** pregolya chat model consumer building agents and chains
- **I want to** have production-grade `BaseChatModel` implementations for OpenAI, Anthropic, and Ollama that pass the full core conformance battery — streaming lifecycle, tool-call round-trips, structured output extraction, error-type classification, token-usage accounting, and transport error propagation
- **So that** all three provider integrations behave identically on the contract surface, downstream graph nodes and agent loops can rely on uniform semantics, and failures surface as structured `PregolyaError` variants rather than silent partial results

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.08.001 | Chat Model Streaming Completions Conformance | P1 |
| BC-2.08.002 | Chat Model Tool-Call Round-Trip Conformance | P1 |
| BC-2.08.003 | Chat Model Structured Output Conformance | P1 |
| BC-2.08.004 | Chat Model Error-Type Fidelity | P1 |
| BC-2.08.005 | Chat Model Token-Usage Accounting | P1 |
| BC-2.08.007 | Transport Error Surfaces Err — Not Truncated Success | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.08.001 postcondition 2)
The `stream_lifecycle` oracle in `pregolya-standard-tests` validates that a streaming
invocation emits exactly: a `MessageStart` event at position 0, zero or more `ContentBlockDelta`
events, and a `MessageFinish` event as the final event. No extra lifecycle events appear between
`MessageStart` and `MessageFinish`. Verified by `test_BC_2_08_001_stream_lifecycle_oracle_openai()`,
`test_BC_2_08_001_stream_lifecycle_oracle_anthropic()`, and
`test_BC_2_08_001_stream_lifecycle_oracle_ollama()`.

### AC-002 (traces to BC-2.08.001 postcondition 2)
Content block indices in the stream are sequential starting at 0. Block index N+1 never appears
before block index N reaches `ContentBlockFinish`. Delta events for block K carry
`block_index: K` consistently across all deltas for that block. Verified by
`test_BC_2_08_001_sequential_block_indices()`.

### AC-003 (traces to BC-2.08.001 postcondition 2)
Concatenating all `ContentBlockDelta.text` values for block K equals the `text` field of the
`ContentBlockFinish` event for block K. Verified by
`test_BC_2_08_001_delta_accumulation_equals_finish_payload()`.

### AC-004 (traces to BC-2.08.001 invariant 1 — DI-011 streaming/unary equivalence)
For a deterministic prompt (temperature=0, seed=42 where supported), the text assembled from
streaming deltas equals the text returned by a non-streaming `invoke`. Tested via the
`streaming_unary_equivalence` shared test fixture in `pregolya-standard-tests`. Verified by
`test_BC_2_08_001_streaming_unary_equivalence_openai()` etc.

### AC-005 (traces to BC-2.08.001 edge case EC-003)
A stream that is interrupted mid-completion (transport layer closes connection before
`MessageFinish`) returns `Err(PregolyaError { code: "E-PROV-003", .. })` from the stream
iterator — no partial `Ok` is returned from a stream that did not reach `MessageFinish`.
Verified by `test_BC_2_08_001_stream_interrupted_returns_e_prov_003()`.

### AC-006 (traces to BC-2.08.002 postcondition 1)
`test_agent_loop()` in `pregolya-standard-tests` is NOT `#[ignore]` — it runs in CI
without a live provider. The test uses a mock provider that returns a pre-scripted tool
call followed by a final assistant message. Verified by inspecting the test attribute and
confirming `cargo nextest run -p pregolya-standard-tests` passes.

### AC-007 (traces to BC-2.08.002 postcondition 2)
Calling `bind_tools(&tools)` on a chat model whose `has_tool_calling()` returns `false`
returns `Err(PregolyaError { code: "E-CORE-005", .. })`. Verified by
`test_BC_2_08_002_bind_tools_without_tool_calling_returns_e_core_005()`.

### AC-008 (traces to BC-2.08.002 postcondition 3)
Tool call `arguments` in the returned `AIMessage` is always a `serde_json::Value::Object`.
A tool that expects no arguments receives `serde_json::json!({})` — never `null` or a
JSON string. Verified by `test_BC_2_08_002_tool_arguments_always_json_object()`.

### AC-009 (traces to BC-2.08.002 postcondition 4)
An agent loop configured with `recursion_limit: N` halts at step N+1 with
`Err(PregolyaError { code: "E-GRAPH-017", .. })`. Verified by
`test_BC_2_08_002_recursion_limit_exceeded_returns_e_graph_017()`.

### AC-010 (traces to BC-2.08.003 postcondition 1)
`with_structured_output::<T>()` where T implements `schemars::JsonSchema + serde::de::DeserializeOwned`
invokes the model with the JSON schema injected (via `json_schema` param for OpenAI,
`tools` extraction trick for Anthropic, `format` field for Ollama) and deserializes
the response into `T`. Verified by `test_BC_2_08_003_structured_output_roundtrip()`.

### AC-011 (traces to BC-2.08.003 postcondition 2)
When the OpenAI provider returns a structured-output refusal (`finish_reason: "content_filter"`
with no JSON body), the adapter returns `Err(PregolyaError { code: "E-PROV-007", .. })`.
Verified by `test_BC_2_08_003_structured_output_refusal_returns_e_prov_007()`.

### AC-012 (traces to BC-2.08.003 postcondition 3)
When the JSON response from any provider cannot be deserialized into the target type T,
the adapter returns `Err(PregolyaError { code: "E-PROV-005", .. })`. Verified by
`test_BC_2_08_003_parse_error_returns_e_prov_005()`.

### AC-013 (traces to BC-2.08.003 postcondition 4)
Anthropic `extended_thinking` is disabled automatically when `with_structured_output` is
active on the Anthropic adapter. Verified by `test_BC_2_08_003_anthropic_thinking_disabled_for_structured_output()`.

### AC-014 (traces to BC-2.08.004 postcondition 1)
A 401 HTTP response from any provider maps to `Err(PregolyaError { code: "E-PROV-004", .. })`.
No other error code is used for authentication failures. Verified by
`test_BC_2_08_004_auth_failure_returns_e_prov_004()`.

### AC-015 (traces to BC-2.08.004 postcondition 2)
A context-length validation failure (e.g., 400 with "context length exceeded" in body)
maps to `Err(PregolyaError { code: "E-PROV-006", .. })`. Verified by
`test_BC_2_08_004_context_overflow_returns_e_prov_006()`.

### AC-016 (traces to BC-2.08.004 postcondition 3)
A 429 HTTP response maps to `Err(PregolyaError { code: "E-PROV-001", .. })`. When a
`Retry-After` header is present, `retry_after_secs` is populated in the error metadata.
Verified by `test_BC_2_08_004_rate_limited_returns_e_prov_001_with_retry_after()`.

### AC-017 (traces to BC-2.08.004 postcondition 4)
A generic HTTP transport error (5xx, connection refused, DNS failure) maps to
`Err(PregolyaError { code: "E-PROV-008", .. })`. Verified by
`test_BC_2_08_004_transport_error_returns_e_prov_008()`.

### AC-018 (traces to BC-2.08.004 invariant 1 — DI-014)
The adapters do not swallow errors silently. A `?` propagation chain from reqwest
through the SDK to the adapter preserves the error classification. No match arm discards
an error variant and returns a default successful response. Verified by code review and
`test_BC_2_08_004_no_silent_error_swallowing()` (mock that injects all error types).

### AC-019 (traces to BC-2.08.005 postcondition 1)
`AIMessage` returned from `invoke` carries `usage_metadata: Some(UsageMetadata { input_tokens, output_tokens, total_tokens })`. `total_tokens == input_tokens + output_tokens`. Verified by
`test_BC_2_08_005_invoke_returns_usage_metadata()`.

### AC-020 (traces to BC-2.08.005 postcondition 2)
The final chunk of a streaming response carries `UsageMetadata` with cumulative token counts
across the entire completion. Earlier chunks carry `None` for usage. Verified by
`test_BC_2_08_005_streaming_final_chunk_carries_cumulative_usage()`.

### AC-021 (traces to BC-2.08.005 postcondition 3)
Sub-detail fields (`reasoning_tokens`, `cache_read_tokens`, `cache_creation_tokens`,
`audio_tokens`) are `Some(N)` when the provider returns them and `None` when absent.
`Some(0)` is distinct from `None` — a provider returning an explicit zero is preserved.
Verified by `test_BC_2_08_005_usage_sub_detail_some_zero_distinct_from_none()`.

### AC-022 (traces to BC-2.08.007 postcondition 1)
A per-chunk timeout (stream stalls for longer than the configured per-chunk timeout) returns
`Err(PregolyaError { code: "E-PROV-002", message: "ProviderTimeout: request timed out after <duration>", .. })`.
The message includes the actual elapsed duration. Verified by
`test_BC_2_08_007_per_chunk_stall_returns_e_prov_002()`.

### AC-023 (traces to BC-2.08.007 postcondition 2)
A TCP reset mid-stream (connection closed by peer after partial data) returns
`Err(PregolyaError { code: "E-PROV-003", .. })`. Verified by
`test_BC_2_08_007_tcp_reset_returns_e_prov_003()`.

### AC-024 (traces to BC-2.08.007 invariant 1 — DI-009/NE-04)
No stream path returns a partial `Ok` after a transport error has been observed. Once an
error event occurs, all subsequent poll results are `Err` or `Ready(None)` (stream terminated).
The `Ok` arm of the stream item type is never returned after the first `Err` item.
Verified by `test_BC_2_08_007_no_partial_ok_after_transport_error()`.

### AC-025 (traces to BC-2.08.001 postcondition 1)
`test_stream` and `test_astream` for each provider (OpenAI, Anthropic, Ollama) yield at least
one `AiMessageChunk` — the stream does not terminate immediately with zero chunks. Concatenating
all chunks via the core merge function produces a non-empty `AiMessage` with at least one
non-empty `ContentBlock::Text`. Verified by `test_BC_2_08_001_stream_yields_at_least_one_chunk_openai()`,
`test_BC_2_08_001_stream_yields_at_least_one_chunk_anthropic()`, and
`test_BC_2_08_001_stream_yields_at_least_one_chunk_ollama()` (cassette-backed).

### AC-026 (traces to BC-2.08.001 postcondition 4)
`test_stream_time` passes for each provider: from stream invocation to the arrival of the first
`AiMessageChunk`, elapsed time is less than 5 seconds when using the fixture cassette layer (the
cassette adds no artificial latency). This verifies the streaming implementation does not buffer
the entire response before emitting the first chunk. Verified by
`test_BC_2_08_001_stream_first_chunk_latency_openai()`,
`test_BC_2_08_001_stream_first_chunk_latency_anthropic()`, and
`test_BC_2_08_001_stream_first_chunk_latency_ollama()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `OpenAiChatModel` adapter | `pregolya-openai/src/chat.rs` | effectful (issues reqwest HTTP) |
| `AnthropicChatModel` adapter | `pregolya-anthropic/src/chat.rs` | effectful |
| `OllamaChatModel` adapter | `pregolya-ollama/src/chat.rs` | effectful |
| `stream_lifecycle` oracle | `pregolya-standard-tests/src/streaming.rs` | pure-core (test utility, no I/O) |
| `UsageMetadata` type | `pregolya-core/src/message.rs` | pure-core (data type) |
| Error classification | `pregolya-openai/src/error.rs` etc. | pure-core (mapping functions) |
| `StructuredOutputRequest` serializer | `pregolya-openai/src/structured.rs` etc. | pure-core |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `chat.rs` adapter (post-invoke) | effectful | Issues HTTP requests via reqwest SDK client; awaits I/O |
| `error.rs` classifiers | pure-core | Pure match/map from HTTP status codes + body to `PregolyaError` variants; no I/O |
| `stream_lifecycle` oracle | pure-core | Validates stream events in memory; called from tests with pre-recorded events |
| `structured.rs` serializers | pure-core | Pure schema injection logic; no I/O until `invoke` is called |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Provider returns `usage: null` in response | `usage_metadata: None` in `AIMessage` — not a panic or error |
| EC-002 | Anthropic returns extended_thinking block in non-structured-output mode | Block preserved as `ContentBlock::Thinking` in `AIMessage.content` |
| EC-003 | `with_structured_output` schema requires a field that model refuses to produce | `Err(E-PROV-005)` on deserialization failure |
| EC-004 | Tool arguments contain Unicode multi-codepoint characters (e.g., emoji cluster) | Arguments round-trip through JSON serialization intact; no truncation |
| EC-005 | Streaming response with zero content blocks (empty assistant message) | `MessageStart` followed immediately by `MessageFinish`; text is empty string |
| EC-006 | 429 with no `Retry-After` header | `Err(E-PROV-001)` with `retry_after_secs: None` |
| EC-007 | `recursion_limit: 0` | First invocation attempt returns `Err(E-GRAPH-017)` immediately |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~5,000 |
| BC files (6 BCs) | ~14,000 |
| `module-decomposition.md` SS-08 section | ~600 |
| Existing `pregolya-core/src/message.rs` | ~800 |
| Adapter source files (3 providers × chat.rs) | ~3,000 |
| Test file stubs | ~2,000 |
| Tool outputs (cargo nextest) | ~500 |
| **Total** | **~26,000** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~13%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-026 (test-writer step)
2. [ ] Confirm no Red Gate BCs in this story — proceed to implementation after test stubs
3. [ ] Add `UsageMetadata` sub-detail fields to `pregolya-core/src/message.rs`
4. [ ] Implement `OpenAiChatModel::stream` — stream lifecycle, block index tracking, delta accumulation
5. [ ] Implement `OpenAiChatModel` error classification: 401→E-PROV-004, 400→E-PROV-006, 429→E-PROV-001, 5xx→E-PROV-008
6. [ ] Implement `OpenAiChatModel::with_structured_output` — `json_schema` param injection
7. [ ] Implement per-chunk timeout stall detection → E-PROV-002; TCP reset → E-PROV-003
8. [ ] Implement `AnthropicChatModel::stream` — Anthropic SSE event format, thinking block handling
9. [ ] Implement `AnthropicChatModel` error classification and `with_structured_output` (disable thinking)
10. [ ] Implement `OllamaChatModel::stream` and `with_structured_output` (`format` field)
11. [ ] Add `stream_lifecycle` oracle and `streaming_unary_equivalence` fixture to `pregolya-standard-tests`
12. [ ] Add `test_agent_loop()` (non-ignored) to `pregolya-standard-tests`
13. [ ] Implement `bind_tools` guard: check `has_tool_calling()` before registering tools
14. [ ] Implement recursion limit guard in agent loop dispatch
15. [ ] Run `cargo nextest run -p pregolya-openai -p pregolya-anthropic -p pregolya-ollama -p pregolya-standard-tests` — all 26 ACs green

## Previous Story Intelligence (MANDATORY)

S-2.06 established the two-crate SDK split (`pregolya-openai-sdk` / `pregolya-openai`, etc.),
`OpenAiApiKey` and `AnthropicApiKey` newtypes with redacted Debug, and the reqwest
`rustls-tls` + 30s timeout conventions. This story builds directly on those foundations.
The adapter `chat.rs` files are the first production logic files in each provider crate.

S-1.07 established `pregolya-macros` proc-macro attributes. Use `#[tool]` attribute from
S-1.07 when wiring tool definitions in `bind_tools` tests — the tool-call AC-006 through
AC-009 tests use it to define mock tools.

S-1.06 established the `Tool` and `DynTool` traits. The `bind_tools` implementation
wraps registered tools as `Arc<dyn DynTool>` — not `Arc<dyn Tool>` (which is non-object-safe
per ADR-005 §Adjacent Trait Object-Safety Adjudications).

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| Provider adapters depend on `pregolya-core` + respective `-sdk` crate only | S-2.06 SDK split architecture contract; module-decomposition SS-08 | `cargo deny` dep check |
| No `unwrap()`/`expect()` in non-test code paths | CLAUDE.md Code Conventions | Clippy + code review |
| No `println!`/`eprintln!` in adapter crates | CLAUDE.md Code Conventions | Clippy |
| All public API surface types carry `#[non_exhaustive]` | CLAUDE.md Code Conventions | compile-fail gate |
| `reqwest::Client` produced by SDK builder uses `.timeout(Duration::from_secs(30))` | CLAUDE.md Code Conventions | Unit test + code review |
| Stream path returns `Err` (not partial `Ok`) on transport error | BC-2.08.007 invariant 1 — DI-009/NE-04 | AC-024 |
| Error classification functions are pure-core (no network I/O) | module-decomposition SS-08 purity boundary | Code review |

**Forbidden dependencies:** `pregolya-openai`, `pregolya-anthropic`, `pregolya-ollama` must NOT
depend on `pregolya-graph`, `pregolya-mcp`, `pregolya-vectorstores`, `pregolya-prompts`, or
`pregolya-server`. Provider adapter crates depend only on `pregolya-core` + their respective
`-sdk` crate. If a provider adapter crate gains a dependency on any of these, the build MUST
fail via `cargo deny`.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `reqwest` | workspace pin | HTTP streaming via `bytes` stream; `rustls-tls` feature mandatory |
| `tokio` | workspace pin | Async runtime; `#[tokio::test]` in tests |
| `serde` + `serde_json` | workspace pin | Request/response serialization |
| `schemars` | workspace pin | JSON schema generation for `with_structured_output` |
| `async-trait` | workspace pin | Object-safe async trait impl for `BaseChatModel` |
| `tracing` | workspace pin | Structured event emission per SAP-1 |
| `pregolya-standard-tests` | workspace path | Shared conformance test fixtures and oracles |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-openai/src/chat.rs` | CREATE | `OpenAiChatModel` — stream, invoke, bind_tools, with_structured_output |
| `pregolya-openai/src/error.rs` | CREATE | HTTP status → `PregolyaError` classification |
| `pregolya-openai/src/structured.rs` | CREATE | `json_schema` param injection for structured output |
| `pregolya-anthropic/src/chat.rs` | CREATE | `AnthropicChatModel` — same surface as OpenAI adapter |
| `pregolya-anthropic/src/error.rs` | CREATE | Anthropic error classification |
| `pregolya-ollama/src/chat.rs` | CREATE | `OllamaChatModel` — stream + `format` field injection |
| `pregolya-ollama/src/error.rs` | CREATE | Ollama error classification |
| `pregolya-standard-tests/src/streaming.rs` | CREATE | `stream_lifecycle` oracle, `streaming_unary_equivalence` fixture |
| `pregolya-standard-tests/src/agent_loop.rs` | CREATE | `test_agent_loop()` — non-ignored, mock-provider agent loop |
| `pregolya-core/src/message.rs` | MODIFY | Add `UsageMetadata` sub-detail fields |
