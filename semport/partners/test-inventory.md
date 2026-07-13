---
artifact: semport/partners/test-inventory
project: ferrochain
port_target: langchain partner packages + standard-tests
analyzer_pass: 4
date: 2026-07-12
note: analysis only — NO Rust code committed
---

# Partner Packages + standard-tests — Test Inventory

Tests are first-class spec inputs. For partner crates, the test story is unusual: **most of
the behavioral test surface lives in `standard-tests`, not in the partner's own `tests/` tree.**
A partner's own tests are mostly (a) a subclass wiring standard-tests to its model, plus
(b) provider-specific unit tests for the translation functions.

## 1. Partner own-test LOC (from scale table)

| Package | own test LOC | shape |
|---|---:|---|
| openai | 16,658 | Largest. Heavy VCR cassettes (Responses + Chat), translation unit tests, both API paths, azure. |
| anthropic | 8,941 | VCR cassettes, message-merge + thinking + caching unit tests, structured-output-with-thinking. |
| perplexity | 2,801 | citations, reasoning-parser tests. |
| groq | 2,689 | standard-tests subclass + VCR. |
| ollama | 2,607 | url-auth parsing, format param, tool-arg parsing, standard-tests subclass. |
| qdrant | 2,965 | vectorstore standard-tests + sparse/hybrid. |
| fireworks | 2,454 | retry classification + standard-tests. |
| mistralai | 1,565 | direct-HTTP + tokenizer tests. |
| chroma | 1,028 | vectorstore standard-tests. |
| huggingface | 677 | thin (endpoint mocked). |
| deepseek | 551 | reasoning_content + standard-tests subclass. |
| xai | 491 | live-search + standard-tests subclass. |
| nomic | 78 | trivial. |
| exa | 146 | retriever/tool tests. |

**Testing pattern to replicate in Rust:** each partner's `tests/{unit,integration}_tests/test_standard.py`
subclasses the standard-tests base and supplies the model fixture — that's the conformance
subscription. Provider-specific tests cover the translation free-functions.

## 2. VCR / cassette strategy (cross-cutting)

Cloud providers use `vcrpy` to record HTTP interactions into gzip+YAML cassettes (custom
serializer in `standard-tests/conftest.py`) so integration tests replay without live keys or
network. `pytest-socket` blocks network in unit tests. `enable_vcr_tests` flag opts a provider in.

**Rust implication:** ferrochain needs an equivalent record/replay HTTP fixture layer. Options:
`wiremock` (Rust mock server), a `vcr`-style cassette crate (`rvcr`, `vcr-cassette`), or a
custom `reqwest` middleware that serves recorded responses. This is the mechanism that lets
the conformance suite run in CI without provider secrets — **it is a prerequisite for
`ferrochain-standard-tests` being useful.**

## 3. standard-tests — full conformance test matrix

This is the crown jewel. Full enumerated test set (mandatory unless flagged gated):

### ChatModelUnitTests (9 class methods + 1 inherited = 10, no network) <!-- [validation-corrected: 9 not 7; grep -c "def test_" unit_tests/chat_models.py = 9] -->
`test_init`, `test_init_from_env`, `test_init_streaming`, `test_bind_tool_pydantic`,
`test_with_structured_output`, `test_standard_params`, `test_standard_params_model_override`,
`test_serdes` (syrupy snapshot), `test_init_time` (benchmark), plus inherited
`test_no_overrides_DO_NOT_OVERRIDE`.

### ChatModelIntegrationTests (~48 def test_ occurrences; ~35-40 unique class-level methods) <!-- [validation-corrected: ~62 was inflated; grep -c "def test_" integration_tests/chat_models.py = 48; some are inner-function pydantic-compat overrides not distinct test cases] -->
Core (ungated): `test_invoke`, `test_ainvoke`, `test_stream`, `test_astream`,
`test_stream_events_v3`, `test_astream_events_v3`, `test_batch`, `test_abatch`,
`test_conversation`, `test_double_messages_conversation`, `test_usage_metadata`,
`test_usage_metadata_streaming`, `test_stop_sequence`, `test_message_with_name`,
`test_agent_loop`, `test_stream_time`.
Model-override (gated `supports_model_override`, default True): `test_invoke_with_model_override`,
`test_ainvoke_with_model_override`, `test_stream_with_model_override`, `test_astream_with_model_override`.
Tool calling (gated): `test_tool_calling`, `test_tool_calling_async`, `test_tool_choice`,
`test_tool_calling_with_no_arguments`, `test_bind_runnables_as_tools`,
`test_tool_message_histories_string_content`, `test_tool_message_histories_list_content`,
`test_tool_message_error_status`, `test_unicode_tool_call_integration`.
Structured output (gated): `test_structured_output`, `test_structured_output_async`,
`test_structured_output_pydantic_2_v1`, `test_structured_output_optional_param`,
`test_structured_few_shot_examples`, `test_json_mode`.
Multimodal (gated): `test_image_inputs`, `test_image_tool_message`, `test_pdf_inputs`,
`test_pdf_tool_message`, `test_audio_inputs`, `test_anthropic_inputs`.

### EmbeddingsUnitTests (2) + EmbeddingsIntegrationTests (4)
`test_init`, `test_init_from_env`; `test_embed_query`, `test_embed_documents`,
`test_aembed_query`, `test_aembed_documents`.

### ToolsUnitTests (5) + ToolsIntegrationTests (4)
`test_init`, `test_init_from_env`, `test_has_name`, `test_has_input_schema`,
`test_input_schema_matches_invoke_params`; `test_invoke_matches_output_schema`,
`test_async_invoke_matches_output_schema`, `test_invoke_no_tool_call`, `test_async_invoke_no_tool_call`.

### VectorStoreIntegrationTests (24, sync+async mirrored: 12 sync + 12 async) <!-- [validation-exhaustive]: ~26 was inaccurate; grep -c "def test_" vectorstores.py = 24 confirmed -->
empty/add/still-empty/delete/delete-bulk/delete-missing/idempotent-add-by-id/
add-by-id-with-mutation/get-by-ids/get-by-ids-missing/add-documents/add-with-existing-ids —
each with an `_async` twin.

### RetrieversIntegrationTests (4)
`test_k_constructor_param`, `test_invoke_with_k_kwarg`, `test_invoke_returns_documents`,
`test_ainvoke_returns_documents`.

### Cache suites (7 each, Sync+Async)
empty → update → still-empty → clear → miss → hit → multiple-generations lifecycle.

### BaseStore suites (Generic[V], ~12 each, Sync+Async)
three-values / empty / set-and-get / still-empty / delete / delete-bulk / delete-missing /
idempotent-set / get-same-value / overwrite-by-key / yield-keys.

### Indexer suites (~11 each, Sync+Async)
upsert-no-ids / upsert-some-ids / upsert-overwrites / delete-missing / delete-semantics /
bulk-delete / delete-no-args / delete-missing-content / get-with-missing-ids / get-missing.

### SandboxIntegrationTests (86 tests, deepagents-gated) <!-- [validation-exhaustive]: ~110 was inaccurate; grep -c "def test_" sandboxes.py = 86 confirmed -->
File ops (write/read/edit/ls/glob/grep with unicode, offsets, limits, binary, large-file,
pagination, error cases), upload/download roundtrips, exec stdout offload. **DEFER — deepagents
is out of ferrochain v1 scope.**

### The v3 stream-lifecycle validator (`utils/stream_lifecycle.py`)
Standalone validator asserting content-block protocol conformance:
- `message-start` opens, `message-finish` closes.
- block indices are sequential uint from 0; blocks may interleave.
- for deltaable types (`text`, `reasoning`, `tool_call_chunk`, `server_tool_call_chunk`)
  accumulated deltas equal the `content-block-finish` payload.
**This is a reusable spec oracle** — port it as a Rust function that any provider's stream can
be piped through in tests. It is the single highest-value artifact in the whole suite.

## 4. Conformance coverage gaps (things NOT tested → LOW confidence in Rust port)
- Proxy paths and TCP socket-option tuning (openai `_client_utils`) are not exercised by
  standard-tests — provider-specific unit tests only. Rust port must add its own.
- Per-chunk stream timeout (`StreamChunkTimeoutError`) — openai-specific, not in the suite.
- Azure AD token-provider callbacks — azure-specific tests, not standard.
- Prompt-caching token accounting — anthropic-specific tests, not standard (though
  `supported_usage_metadata_details` includes `cache_read_input`/`cache_creation_input`).

## State Checkpoint
```yaml
pass: 4
artifact: test-inventory
status: complete
timestamp: 2026-07-12
```
