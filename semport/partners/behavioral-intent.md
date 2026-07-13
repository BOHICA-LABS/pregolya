---
artifact: semport/partners/behavioral-intent
project: ferrochain
port_target: langchain partner packages + standard-tests
analyzer_pass: 4
date: 2026-07-12
note: analysis only — NO Rust code committed
---

# Partner Packages + standard-tests — Behavioral Intent

What each package *promises* to do behind the `BaseChatModel` / `Embeddings` / `VectorStore` /
`BaseRetriever` / `BaseTool` contracts, and the cross-partner behaviors that become shared
`ferrochain` partner-infrastructure.

## 0. The universal partner contract

Every chat provider implements the same core promise (inherited from langchain-core's
`BaseChatModel`, analyzed in semport/core): given `Vec<Message>` + params, produce an
`AiMessage` (or stream of `AiMessageChunk`), with `bind_tools`, `with_structured_output`,
`invoke`/`stream`/`batch` + async twins, and usage metadata. A partner crate's job is to
translate **the langchain-core content-block model ↔ the provider wire format**, and back.
The behavioral surface is therefore ~90% *translation fidelity* and ~10% transport.

Intent hierarchy per provider:
1. **Request translation** — `Vec<Message>` + tools + structured-output spec → provider JSON.
2. **Response translation** — provider JSON → `AiMessage` with typed content blocks.
3. **Streaming translation** — provider SSE events → `AiMessageChunk` stream, with correct
   chunk merge semantics (test-locked in core's `merge_content`/`add_ai_message_chunks`).
4. **Usage metadata extraction** — tokens (input/output/reasoning/cached/audio).
5. **Error mapping** — provider errors → typed errors (esp. context-overflow).
6. **Capability declaration** — which optional behaviors the model supports (drives the
   conformance flags).

## 1. openai — behavioral intent (DEEP)

### BC-DRAFT-OAI-001: Chat Completions vs Responses API auto-routing
**Precondition:** model configured, payload built.
**Behavior:** `_use_responses_api(payload)` returns true when the payload contains
Responses-only features (built-in server tools, `previous_response_id`, reasoning config) OR
`_model_prefers_responses_api(model_name)` is true (reasoning-family models) AND no
third-party `base_url` is set. When true, the request goes through the Responses payload
builder + result reconstructor; otherwise Chat Completions.
**Postcondition:** identical `AiMessage` output shape regardless of path.
**Evidence:** `_use_responses_api`, `_model_prefers_responses_api`, dual `_get_request_payload`
paths, `_construct_lc_result_from_responses_api`. **Confidence: HIGH** (both paths fully coded + tested).

### BC-DRAFT-OAI-002: streaming usage metadata
Streaming includes usage only when `stream_options={"include_usage":true}` is negotiated
(`_should_stream_usage`). Reasoning/cached/audio token sub-counts are surfaced when present.
**Evidence:** `_should_stream_usage`, `_create_usage_metadata{,_responses}`. **HIGH.**

### BC-DRAFT-OAI-003: structured output — three methods
`with_structured_output(schema, method=...)` supports `function_calling` (bind a tool +
parse tool call), `json_mode` (response_format json_object + parse text), and `json_schema`
(native structured outputs via `response_format:{type:json_schema,strict:true}` +
`_oai_structured_outputs_parser`, raising `OpenAIRefusalError` on refusal).
**Evidence:** `with_structured_output` (L2311), `_convert_to_openai_response_format`. **HIGH.**

### BC-DRAFT-OAI-004: image token accounting
`get_num_tokens_from_messages` estimates image tokens by decoding image dimensions and
applying OpenAI's tile formula (`_url_to_size`, `_resize`, `_count_image_tokens`).
**Evidence:** functions L3953–4012. **Confidence: MEDIUM** (formula is an approximation of a
provider-internal rule; golden-test against fixtures).

### BC-DRAFT-OAI-005: streaming per-chunk timeout
Async SSE streams are wrapped so a stall > configured bound raises `StreamChunkTimeoutError`
rather than hanging (`_astream_with_chunk_timeout`). Aligns with CLAUDE.md's clientless-timeout
prohibition. **Evidence:** `_client_utils.py`. **HIGH.**

### Azure variant intent
`AzureChatOpenAI` swaps the credential + endpoint model: `azure_endpoint`, `api_version`
(`OPENAI_API_VERSION`), deployment-name routing, and `azure_ad_token` / `azure_ad_token_provider`
(sync) / `azure_ad_async_token_provider` (async callable) for Entra-ID auth. Everything else
inherits `BaseChatOpenAI`. **Intent: a credential-strategy variant, not a behavior variant.**

### Embeddings intent
`OpenAIEmbeddings` batches inputs into token-bounded chunks (`_get_len_safe_embeddings`) using
tiktoken so no single request exceeds the model's token limit, then re-assembles in order.
**Do-not-silently-drop:** ordering must be preserved (relevant to CLAUDE.md no-silent-empty rule).

## 2. anthropic — behavioral intent (DEEP)

### BC-DRAFT-ANT-001: consecutive-role message merge
The Messages API forbids consecutive same-role messages; `_merge_messages` merges them
(concatenating content blocks) before send. Tool results must be attached to the correct
role. **Evidence:** `_merge_messages`, `_format_messages`. **HIGH** (heavily tested).

### BC-DRAFT-ANT-002: content-block ↔ v3-standard translation
`_format_data_content_block` maps standard image/pdf/file blocks → Anthropic
`{type:image, source:{...}}` etc.; `_format_image` handles base64/URL. Reverse direction maps
Anthropic `text`/`thinking`/`redacted_thinking`/`tool_use` → v3 standard content blocks.
**Evidence:** `_format_data_content_block`, streaming decoder L1515+. **HIGH.**

### BC-DRAFT-ANT-003: thinking / extended reasoning
`thinking={"type":"enabled","budget_tokens":N}` produces `thinking` + `redacted_thinking`
content blocks carrying a `signature`; streaming assembles `thinking_delta` + `signature_delta`.
**Structured output is incompatible with thinking** → `_get_llm_for_structured_output_when_thinking_is_enabled`
clones the model with thinking disabled for the schema-enforcing call.
**Evidence:** `thinking` field L1003, L1821, streaming L1629–1660. **HIGH.**

### BC-DRAFT-ANT-004: prompt caching
`cache_control={"type":"ephemeral","ttl":"5m"|"1h"}` is applied to the last eligible content
block (`_apply_cache_control_to_last_eligible_block`) and, via
`AnthropicPromptCachingMiddleware`, to the system message's last block, the last tool
definition, and model_settings. Cache-read/creation tokens are surfaced in usage metadata.
**Evidence:** `middleware/prompt_caching.py` (`_cache_control`, `_tag_system_message`,
`_tag_tools`), `_create_usage_metadata`. **HIGH.**

### BC-DRAFT-ANT-005: built-in server tools
Code-execution / bash / file-search server tools are recognized (`_is_builtin_tool`) and their
result blocks tracked across the message list (`_collect_code_execution_tool_ids`).
**Evidence:** middleware/{anthropic_tools,bash,file_search}.py. **MEDIUM** (feature-rich, evolving).

## 3. ollama — behavioral intent (DEEP)

### BC-DRAFT-OLL-001: model-presence validation
On configuration, `validate_model` calls `client.list()` and raises a friendly error if the
named model isn't pulled locally (distinguishing connection failure vs missing model vs API
error). **Evidence:** `_utils.validate_model`. **HIGH.**

### BC-DRAFT-OLL-002: embedded-URL credentials → Basic auth header
`parse_url_with_auth` accepts `https://user:pass@host:port` and scheme-less `host:port`,
strips credentials from the URL, percent-decodes them, and injects `Authorization: Basic ...`
(IPv6-safe reconstruction). **This is the only partner with URL-embedded credentials** — the
credential-newtype rule must cover the *base_url* here, not just an API key.
**Evidence:** `_utils.parse_url_with_auth`, `merge_auth_headers`. **HIGH.**

### BC-DRAFT-OLL-003: structured output via `format`
`with_structured_output` maps to Ollama's `format` request field, accepting `"json"` or a
full JSON schema (`_resolve_format_param`/`_convert_response_format`/`_extract_json_schema`).
**Evidence:** those methods. **HIGH.**

### BC-DRAFT-OLL-004: OpenAI-shaped tool calls, tolerant arg parsing
Ollama returns OpenAI-shaped tool calls; `_parse_arguments_from_tool_call` +
`_parse_json_string` tolerate stringified/loose JSON arguments.
**Evidence:** `_get_tool_calls_from_response`. **HIGH.**

### Intent as the API-key-free test path
Because ChatOllama needs no cloud credential, it is the natural CI conformance target that
runs without secrets — provided a local Ollama (or a DTU fake of it) is reachable. See
dependency-disposition §DTU for exactly what a fake must serve.

## 4. Cross-partner shared behaviors → ferrochain partner-infrastructure

These recur across ≥3 providers and MUST become a shared `ferrochain-partner-core` (name TBD
at architecture) rather than being reimplemented per crate:

| Shared behavior | Where seen | Intent |
|---|---|---|
| **API-key env-var + SecretStr** | all: `secret_from_env("OPENAI_API_KEY")`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`, `XAI_API_KEY`, `GROQ_API_KEY`, ... | Resolve key from explicit param → env var → error; wrap in redacted secret. |
| **base_url override** | openai (`base_url`/`OPENAI_API_BASE`/`OPENAI_BASE_URL`), anthropic (`ANTHROPIC_BASE_URL`), ollama (`base_url`), all thin subclasses | Point at proxies / emulators / compatible endpoints. Presence of base_url disables OpenAI Responses auto-routing. |
| **proxy support** | openai (`OPENAI_PROXY`), anthropic (`ANTHROPIC_PROXY`) | Route through an HTTP proxy. NOTE: intersects CLAUDE.md rustls-tls mandate (MITM-proxy concern). |
| **max_retries → SDK-delegated backoff** | openai (`max_retries`, default None→SDK default), anthropic (`max_retries=2`), groq, fireworks | Retry transient errors with exponential backoff. **Currently delegated to the vendor SDK's built-in retry** — this is the single biggest thing a direct-HTTP port must reimplement (see rust-translation-strategy). |
| **timeout (request + per-chunk stream)** | openai (`timeout`, `_astream_with_chunk_timeout`), anthropic (`default_request_timeout`), standard params `timeout=60` | Bound total request and per-SSE-chunk wall-clock. Aligns with CLAUDE.md 30s client timeout rule. |
| **cached httpx client** | openai + anthropic `_client_utils.py` (`lru_cache`) | Reuse connection pools across model instances. |
| **context-overflow typed error** | openai/anthropic/groq/fireworks each define `*ContextOverflowError` | Map provider "too many tokens" 400s to a typed, catchable error (used by summarization/trim middleware). |
| **model capability profiles** | openai/anthropic `data/_profiles.py` | Static per-model capability metadata (drives auto-routing + conformance flags). |
| **usage metadata normalization** | all | Provider token fields → the core `UsageMetadata` shape (input/output/total + reasoning/cache/audio details). |

## 5. Vector store / retriever / tool intent (inventory-level)

- **chroma / qdrant** implement the `VectorStore` contract: `add_documents` (idempotent by id),
  `delete`, `get_by_ids`, similarity + MMR search, metadata filtering. Qdrant adds sparse +
  hybrid retrieval (`RetrievalMode`). Idempotency + ordering are the test-locked invariants
  (see standard-tests vectorstores). **Out of the chat critical path — later wave.**
- **exa / perplexity retrievers** implement `BaseRetriever.invoke → Vec<Document>` and expose
  search tools returning structured results with citations.

## 6. standard-tests — behavioral intent (what conformance MEANS)

The suite encodes the *definition of a correct provider*. Behaviors every conforming chat
provider MUST pass (unit + always-on integration, no capability flag gating them):

**Unit (no network) — mandatory for ALL chat providers:**
- `test_init` — constructs with standard params.
- `test_init_from_env` — reads API key from the documented env var.
- `test_init_streaming` — constructs with `streaming=True`.
- `test_standard_params` / `test_standard_params_model_override` — the model reports a
  standard `ls_params` set (model name, temperature, max_tokens, etc.).
- `test_serdes` — round-trips through lc-serialization (syrupy snapshot).
- `test_bind_tool_pydantic` — `bind_tools` accepts a schema.
- `test_init_time` — construction is fast (benchmark gate).

**Integration — mandatory (ungated) core behaviors:**
- `test_invoke` / `test_ainvoke` — returns a non-empty `AIMessage` string.
- `test_stream` / `test_astream` — yields ≥1 chunk; chunks concatenate to a full message.
- `test_batch` / `test_abatch` — ordered results.
- `test_conversation` / `test_double_messages_conversation` — multi-turn works, incl. two
  consecutive human messages (this is what forces anthropic's `_merge_messages`).
- `test_usage_metadata` / `test_usage_metadata_streaming` — usage present when
  `returns_usage_metadata` (default True); sub-details checked per `supported_usage_metadata_details`.
- `test_stop_sequence` — stop param honored.
- `test_message_with_name` — named messages accepted.
- `test_agent_loop` — a tool-calling agent loop terminates correctly.
- `test_stream_events_v3` / `test_astream_events_v3` — the **v3 content-block protocol
  stream** validates against `utils/stream_lifecycle.py` (message-start opens, message-finish
  closes, block indices sequential from 0, deltaable-block deltas accumulate to the finish
  payload). **This is the single most valuable + hardest conformance behavior to port.**

**Integration — capability-flag-gated (opt-in) behaviors:**
- Tool calling: `test_tool_calling{,_async}`, `test_tool_choice`,
  `test_tool_calling_with_no_arguments`, `test_bind_runnables_as_tools`,
  `test_tool_message_histories_{string,list}_content`, `test_tool_message_error_status`,
  `test_unicode_tool_call_integration` (gated by `has_tool_calling`/`has_tool_choice`).
- Structured output: `test_structured_output{,_async}`, `test_structured_output_pydantic_2_v1`,
  `test_structured_output_optional_param`, `test_structured_few_shot_examples`, `test_json_mode`
  (gated by `has_structured_output`/`supports_json_mode`).
- Multimodal: `test_image_inputs`, `test_image_urls`, `test_pdf_inputs`, `test_audio_inputs`,
  `test_image_tool_message`, `test_pdf_tool_message` (gated by respective `supports_*`).
- Provider-specific: `test_anthropic_inputs` (gated by `supports_anthropic_inputs`).
- Model override: `test_{,a}invoke_with_model_override`, `test_{,a}stream_with_model_override`
  (gated by `supports_model_override`, default True).
- Timing: `test_stream_time` (benchmark).

**The no-opt-out invariant** (`test_no_overrides_DO_NOT_OVERRIDE`): a subscriber cannot
delete or silently override a mandatory test — only declare `@pytest.mark.xfail(reason=...)`.
This is the mechanism that makes the suite a *contract* rather than a menu. **Porting this
guard is essential** — without it, ferrochain provider crates could quietly weaken conformance.

Other suite intents (later waves): embeddings (query/documents, sync+async, dimensionality),
tools (name/input-schema/invoke-matches-schema), vectorstores (idempotent add-by-id, delete
semantics, get-by-id, sync+async parity), cache (empty→update→hit→clear lifecycle),
base_store (KV CRUD + yield_keys, Generic over value type), indexer (upsert/delete/get
semantics), retrievers (k-param constructor + kwarg, returns Documents), sandboxes (deepagents
file-op/exec conformance — DEFER, deepagents is out of ferrochain v1 scope).

## State Checkpoint
```yaml
pass: 4
artifact: behavioral-intent
status: complete
timestamp: 2026-07-12
```
