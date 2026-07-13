---
artifact: semport/partners/module-inventory
project: ferrochain
port_target: langchain partner packages (15) + langchain-tests (standard-tests)
analyzer_pass: 4
date: 2026-07-12
reference: langchain==1.3.13 (tag); libs/partners/* + libs/standard-tests
note: analysis only — NO Rust code committed; signatures are illustrative sketches
standard_tests_placement: dedicated section in each of the five partners/ files
  (single coherent Pass 4 deliverable; a parallel partners/standard-tests/ dir was
  judged NOT cleaner because the conformance suite is consumed BY the partner crates
  and only makes sense alongside them).
---

# Partner Packages + standard-tests — Module Inventory

Depth per D3: DEEP for **openai, anthropic, ollama**; INVENTORY for the other 12 partners;
DEEP for **standard-tests** (becomes `ferrochain-standard-tests`, a P0-adjacent
differentiator per market-intel — it is the conformance gate every provider crate binds to).

LOC counts are non-test source only (excludes `tests/` and `scripts/`), measured on the
pinned corpus. "Test LOC" is the package's own `tests/` tree.

## Scale table — all 15 partners + standard-tests

| Package | src LOC | test LOC | src files | Primary class(es) | Kind | Upstream Python SDK dep | Depth |
|---|---:|---:|---:|---|---|---|---|
| **openai** | 13,597 | 16,658 | 23 | `ChatOpenAI`, `AzureChatOpenAI`, `OpenAI`/`AzureOpenAI` (completions), `OpenAIEmbeddings`/`AzureOpenAIEmbeddings` | chat+llm+embed+tools+middleware | `openai>=2.45`, `tiktoken>=0.7` | DEEP |
| **anthropic** | 5,664 | 8,941 | 15 | `ChatAnthropic`, `AnthropicLLM`, 4 middleware | chat+llm+middleware | `anthropic>=0.96`, `pydantic` | DEEP |
| **ollama** | 2,959 | 2,607 | 7 | `ChatOllama`, `OllamaLLM`, `OllamaEmbeddings` | chat+llm+embed | `ollama>=0.6.1` | DEEP |
| **openrouter** | 9,329 | 4,094 | 5 | `ChatOpenRouter` (own `BaseChatModel`) | chat | `openrouter>=0.9.2` | INV |
| **qdrant** | 3,832 | 2,965 | 7 | `QdrantVectorStore`, `Qdrant` (legacy), `FastEmbedSparse` | vectorstore | `qdrant-client>=1.15`, `pydantic` | INV |
| **huggingface** | 3,802 | 677 | 13 | `ChatHuggingFace`, `HuggingFaceEndpoint`, `HuggingFacePipeline`, `HuggingFaceEmbeddings`, `HuggingFaceEndpointEmbeddings` | chat+llm+embed | `huggingface-hub>=0.33`, `tokenizers>=0.19` | INV |
| **mistralai** | 2,499 | 1,565 | 7 | `ChatMistralAI`, `MistralAIEmbeddings` | chat+embed | `httpx`, `httpx-sse`, `tokenizers`, `pydantic` (direct HTTP; no vendor SDK) | INV |
| **fireworks** | 2,423 | 2,454 | 9 | `ChatFireworks`, `Fireworks` (LLM), `FireworksEmbeddings` | chat+llm+embed | `fireworks-ai`, `openai>=2`, `requests`, `aiohttp` | INV |
| **perplexity** | 2,283 | 2,801 | 11 | `ChatPerplexity`, `PerplexityEmbeddings`, `PerplexitySearchRetriever`, `PerplexitySearchResults` (tool), reasoning parsers | chat+embed+retriever+tool | `perplexityai>=0.34` | INV |
| **groq** | 2,083 | 2,689 | 7 | `ChatGroq` | chat | `groq>=0.30` | INV |
| **chroma** | 1,471 | 1,028 | 3 | `Chroma` (VectorStore) | vectorstore | `chromadb>=1.5.5`, `numpy` | INV |
| **xai** | 1,015 | 491 | 5 | `ChatXAI` (subclass of `BaseChatOpenAI`) | chat | `langchain-openai`, `requests`, `aiohttp` | INV |
| **deepseek** | 689 | 551 | 5 | `ChatDeepSeek` (subclass of `BaseChatOpenAI`) | chat | `langchain-openai` (no vendor SDK) | INV |
| **exa** | 391 | 146 | 5 | `ExaSearchRetriever`, `ExaSearchResults`, `ExaFindSimilarResults` (tools) | retriever+tool | `exa-py>=1.0.8` | INV |
| **nomic** | 158 | 78 | 3 | `NomicEmbeddings` | embed | `nomic>=3.5.3`, `pillow` | INV |
| **standard-tests** | 9,820 | — | 21 | 12 conformance base classes (see below) | test-harness | pytest, vcrpy, syrupy, httpx, numpy | DEEP |

Total partner src ≈ **52,193 LOC** across 15 packages; standard-tests adds **9,820 LOC**.

### Partner taxonomy (drives crate family + wave ordering)

1. **First-party-SDK chat providers** — openai, anthropic, ollama, groq, fireworks,
   openrouter, perplexity, mistralai. Each wraps (or reimplements) a provider REST API
   behind the `BaseChatModel` contract.
2. **OpenAI-compatible thin subclasses** — deepseek, xai (both `class Chat_ < BaseChatOpenAI`),
   and fireworks/openrouter (OpenAI-shaped wire, own base). These inherit ~all behavior
   from `ChatOpenAI` and override only model list, base_url, and a few param quirks.
   **This is the single most leverage-heavy pattern in the whole partner set**: once
   `ferrochain-openai`'s `BaseChatOpenAI` equivalent exists, deepseek+xai are <700 LOC each.
3. **Embeddings-only / embeddings-primary** — nomic; plus the embeddings classes inside
   openai/ollama/huggingface/mistralai/fireworks/perplexity.
4. **Vector stores** — chroma, qdrant. These target the `VectorStore` contract (a
   langchain-core abstraction) and bind to a storage SDK. Out of the chat critical path.
5. **Retrieval / search tools** — exa (search retriever + 2 tools), perplexity retriever.

---

## DEEP: openai (`langchain_openai`, 13,597 LOC / 23 files)

### Module map

| Module | LOC-ish | Purpose |
|---|---|---|
| `chat_models/base.py` | 5,248 | `BaseChatOpenAI` + `ChatOpenAI`. Contains BOTH the **Chat Completions** path and the **Responses API** path. ~80 module-level free functions for message↔dict conversion, both API shapes. |
| `chat_models/azure.py` | ~1,174 | `AzureChatOpenAI(BaseChatOpenAI)` — azure_endpoint / api_version / azure_ad_token(+provider, sync & async) / deployment routing. <!-- [validation-exhaustive]: ~900 was inaccurate; wc -l = 1,174 --> |
| `chat_models/_client_utils.py` | ~683 | httpx client builders (cached via `lru_cache`), TCP keepalive + `TCP_USER_TIMEOUT` socket tuning (Linux + Darwin constants), `_astream_with_chunk_timeout` per-chunk wall-clock bound, `StreamChunkTimeoutError`. NOTE: `_get_ssrf_safe_client` is in `chat_models/base.py` (L168), NOT in this file. <!-- [validation-exhaustive]: ~400 was inaccurate; wc -l = 683. SSRF guard location corrected; it was attributed to _client_utils.py but actually lives in base.py at line 168 --> |
| `chat_models/_compat.py` | — | v0↔v1 `output_version` bridge for content blocks. |
| `chat_models/codex.py` | — | Codex/ChatGPT-flavored variant. |
| `chatgpt_oauth.py` | — | OAuth credential flow for ChatGPT backend. |
| `llms/base.py`,`azure.py` | — | Legacy text-completions `OpenAI`/`AzureOpenAI`. |
| `embeddings/base.py`,`azure.py` | ~810 | `OpenAIEmbeddings` — tiktoken tokenization, len-safe chunked batching (`_get_len_safe_embeddings`), sync+async. |
| `output_parsers/tools.py` | — | OpenAI tool-call output parsing. |
| `tools/custom_tool.py` | — | `custom_tool` (Responses API custom-tool binding). |
| `middleware/openai_moderation.py` | — | Moderation-endpoint middleware. |
| `data/_profiles.py` | — | Per-model capability profiles (`ModelProfile`). |

### Notable behaviors (openai)
- **Dual API surface.** `_use_responses_api(payload)` + `_model_prefers_responses_api(name)`
  route between Chat Completions and the Responses API. The Responses path has its own
  payload builder (`_construct_responses_api_payload`/`_input`), result reconstructor
  (`_construct_lc_result_from_responses_api`), and streaming chunk converter
  (`_convert_responses_chunk_to_generation_chunk`, a stateful `_advance(output_idx, sub_idx)`
  cursor). Responses API is preferred automatically for reasoning models; routing is
  base_url-agnostic — third-party OpenAI-compatible endpoint users must explicitly set
  `use_responses_api=False` if needed. <!-- [validation-corrected pass-8]: "unless `base_url` is set" was inaccurate; `_use_responses_api` has no base_url check -->
- **Tool calling** both directions: `_lc_tool_call_to_openai_tool_call`,
  `_convert_delta_to_message_chunk`, plus `_is_builtin_tool` (server-side tools like
  web_search / computer_use in Responses).
- **Structured output** three ways via `with_structured_output` (630+ LOC): function_calling,
  json_mode, and native `json_schema` (`_convert_to_openai_response_format` +
  `_oai_structured_outputs_parser`, `OpenAIRefusalError`).
- **Usage metadata**: `_create_usage_metadata` (Chat) and `_create_usage_metadata_responses`
  (Responses) — includes reasoning tokens, cached input tokens, audio tokens.
- **Token counting**: `get_num_tokens_from_messages` with tiktoken + **image token
  estimation** (`_url_to_size`, `_count_image_tokens`, `_resize` — replicates OpenAI's
  tile-based image token formula).
- **Context overflow** mapped to typed errors (`OpenAIContextOverflowError` etc.).
- **SSRF guard** on the default httpx client (`_get_ssrf_safe_client`).

## DEEP: anthropic (`langchain_anthropic`, 5,664 LOC / 15 files)

### Module map

| Module | LOC-ish | Purpose |
|---|---|---|
| `chat_models.py` | 2,405 | `ChatAnthropic` + Messages API translation. |
| `_client_utils.py` | 81 | Cached sync/async httpx client wrappers (`__del__` auto-close), `ANTHROPIC_BASE_URL` default, `anthropic_proxy`. |
| `_compat.py` | — | v0↔v1 content-block bridge (thinking/redacted_thinking/tool_use). |
| `llms.py` | — | Legacy text-completion `AnthropicLLM`. |
| `output_parsers.py` | — | Tool-use output parsing. |
| `experimental.py` | — | Experimental surface. |
| `middleware/prompt_caching.py` | 262 | `AnthropicPromptCachingMiddleware` (see behaviors). |
| `middleware/anthropic_tools.py` | — | Server-tool (built-in) binding middleware. |
| `middleware/bash.py`,`file_search.py` | — | Bash tool + file-search server tools. |
| `data/_profiles.py` | — | Per-model profiles. |

### Notable behaviors (anthropic)
- **Message translation** is the crux: `_format_messages` (270+ LOC), `_merge_messages`
  (consecutive same-role merge required by the Messages API), `_format_image`,
  `_format_data_content_block` (image/pdf/file → Anthropic content blocks),
  `_normalize_tool_call_id` / `_normalize_block_tool_use_id`.
- **Thinking / extended reasoning**: `thinking` param (`{"type":"enabled","budget_tokens":N}`
  or `{"type":"disabled"}`); streaming handles `thinking_delta` + `signature_delta`;
  content-block types `thinking` and `redacted_thinking` round-tripped with `signature`.
  Special path `_get_llm_for_structured_output_when_thinking_is_enabled` (structured output
  is incompatible with thinking → falls back to a tool-strategy clone with thinking off).
- **Prompt caching**: `_apply_cache_control_to_last_eligible_block` +
  `AnthropicPromptCachingMiddleware` tags system message / last tool / model_settings with
  `cache_control={"type":"ephemeral","ttl":"5m"|"1h"}`. Cache-read/creation tokens surfaced
  in usage metadata (`_create_usage_metadata`).
- **Built-in / server tools**: `_is_builtin_tool`, code-execution block tracking
  (`_collect_code_execution_tool_ids`, `_is_code_execution_related_block`).
- **Tool use**: `convert_to_anthropic_tool` (public), `_lc_tool_calls_to_anthropic_tool_use_blocks`.
- **Streaming**: `_make_message_chunk_from_anthropic_event` decodes the Anthropic SSE event
  taxonomy (`message_start`/`content_block_start`/`content_block_delta`/`message_delta`/etc.).

## DEEP: ollama (`langchain_ollama`, 2,959 LOC / 7 files)

### Module map

| Module | LOC-ish | Purpose |
|---|---|---|
| `chat_models.py` | 1,794 | `ChatOllama`. |
| `llms.py` | — | `OllamaLLM` (generate endpoint). |
| `embeddings.py` | — | `OllamaEmbeddings` (`client.embed`). |
| `_utils.py` | ~155 | `validate_model` (checks model is pulled via `client.list()`), `parse_url_with_auth` (extracts `user:pass@host` → Basic auth header), `merge_auth_headers`, `_build_cleaned_url` (IPv6-safe). <!-- [validation-exhaustive]: ~180 was inaccurate; wc -l = 155 --> |
| `_compat.py` | — | content-block bridge. |

### Notable behaviors (ollama)
- **Local inference, no API key.** Talks to the `ollama` python client (which wraps the
  local HTTP server, default `http://localhost:11434`). This is ferrochain's **API-key-free
  CI/test path** — see dependency-disposition for the DTU-fake requirements.
- **Model presence validation (opt-in)**: `validate_model` calls `client.list()` and errors if the named model isn't pulled — a UX affordance absent from cloud providers. **Gated by `validate_model_on_init: bool = False`** (default off); validation only runs when `validate_model_on_init=True`. <!-- [validation-certification-5]: added opt-in note; default is False per chat_models.py:548 -->
- **URL auth extraction**: `parse_url_with_auth` supports `https://user:pass@host:port` and
  scheme-less `host:port` inputs, strips credentials from the URL and re-injects them as a
  `Authorization: Basic` header (this is the ONLY partner with embedded-URL-credential
  handling — relevant to the credential-newtype rule).
- **Structured output / format param**: `_resolve_format_param` / `_convert_response_format` /
  `_extract_json_schema` map `with_structured_output` to Ollama's `format` field (accepts
  `"json"` or a full JSON schema).
- **Tool calling**: `_get_tool_calls_from_response`, `_parse_arguments_from_tool_call`,
  `_parse_json_string` (tolerant), `_lc_tool_call_to_openai_tool_call` (Ollama uses
  OpenAI-shaped tool calls).
- **Streaming aggregation**: `_chat_stream_with_aggregation` / async twin, plus
  `_iterate_over_stream` / `_aiterate_over_stream`.
- **top_logprobs validation**, `keep_alive`, `num_predict`, `num_ctx` and other
  Ollama-specific options passed through `_chat_params`.

---

## INVENTORY: remaining 12 partners

### deepseek (689 LOC) — `ChatDeepSeek(BaseChatOpenAI)`
Thin subclass of `langchain-openai`'s `BaseChatOpenAI`. Overrides base_url (`DEEPSEEK_API_BASE`),
API key env (`DEEPSEEK_API_KEY`), and a `_set_deepseek_version` (renamed to avoid
shadowing base). Handles the `reasoning_content` field DeepSeek adds. No vendor SDK — rides
the `openai` SDK via the parent. **Depends entirely on ferrochain-openai's base existing.**
<!-- [validation-exhaustive]: `_set_deepseek_chat_version` was inaccurate; actual function name is `_set_deepseek_version` (confirmed at L229 of langchain_deepseek/chat_models.py) -->

### xai (1,015 LOC) — `ChatXAI(BaseChatOpenAI)`
Same pattern (Grok). `XAI_API_KEY`, base_url `https://api.x.ai/v1`. Adds `requests`/`aiohttp`
for a live-search feature and search-parameters passthrough. Also `langchain-openai` dependent.
Env-vars: `XAI_API_KEY` (key, secret), `XAI_API_BASE` (base_url override, default `https://api.x.ai/v1/`, `xai/chat_models.py:430`). <!-- [validation-certification-6]: added XAI_API_BASE env-var and default; pass-5 env-var sweep found omission -->

### fireworks (2,423 LOC) — `ChatFireworks(BaseChatModel)` + LLM + Embeddings
Own `BaseChatModel` impl (NOT a BaseChatOpenAI subclass) but OpenAI-shaped wire via `openai`
SDK + `fireworks-ai`. Has its own retry classification (`_RetryableHTTPStatusError`) and
`FireworksContextOverflowError`. `requests`+`aiohttp` for some paths.

### groq (2,083 LOC) — `ChatGroq(BaseChatModel)`
Wraps `groq` SDK. OpenAI-shaped chat completions + tool calling + json mode. Own context
overflow error. No embeddings.
Env-vars: `GROQ_API_KEY` (key, secret), `GROQ_API_BASE` (base_url override, default `None`, `groq/chat_models.py:440`), `GROQ_PROXY` (proxy URL, default `None`, `groq/chat_models.py:447`). <!-- [validation-certification-6]: added GROQ_API_BASE and GROQ_PROXY env-vars; pass-5 env-var sweep found both omissions -->

### openrouter (9,329 LOC — inflated by data tables) — `ChatOpenRouter(BaseChatModel)`
Own base. Aggregator that fronts many models; large per-model routing/data tables inflate LOC.
Wraps `openrouter` SDK. Notable: provider-preferences / model-routing params, and per-model
capability metadata.

### perplexity (2,283 LOC) — `ChatPerplexity` + embeddings + retriever + search tool
Wraps `perplexityai` SDK. Distinctive: **citations / search-results** surfaced in message
metadata; `ReasoningJsonOutputParser` / `ReasoningStructuredOutputParser` strip `<think>`
reasoning before parsing; `WebSearchOptions`/`UserLocation`/`MediaResponse` typed params;
`PerplexitySearchRetriever` + `PerplexitySearchResults` tool.

### mistralai (2,499 LOC) — `ChatMistralAI` + `MistralAIEmbeddings`
**No vendor SDK** — direct HTTP via `httpx` + `httpx-sse` (SSE streaming). Uses `tokenizers`
for token counting (`DummyTokenizer` fallback). This is the cleanest "direct-HTTP" reference
in the partner set — a useful template for ferrochain's direct-HTTP providers.

### huggingface (3,802 LOC) — chat + endpoint LLM + pipeline LLM + 2 embeddings
`ChatHuggingFace` wraps a TGI (text-generation-inference) endpoint or a local pipeline;
`HuggingFaceEndpoint`/`HuggingFacePipeline` LLMs; `HuggingFaceEmbeddings` (local
sentence-transformers — heavy, torch) + `HuggingFaceEndpointEmbeddings` (remote). The local
pipeline/embeddings paths pull the ML stack (torch/transformers) — **large port surface;
recommend endpoint-only in ferrochain v1, defer local inference.**

### chroma (1,471 LOC) — `Chroma(VectorStore)`
Wraps `chromadb`. Add/query/delete/get-by-id, metadata filtering, MMR. numpy for vector math.

### qdrant (3,832 LOC) — `QdrantVectorStore` + legacy `Qdrant` + `FastEmbedSparse`
Wraps `qdrant-client`. Dense + **sparse** + hybrid retrieval (`RetrievalMode` enum),
`SparseEmbeddings` abstraction, `FastEmbedSparse`. Two vectorstore classes (new + deprecated).

### nomic (158 LOC) — `NomicEmbeddings`
Smallest. Wraps `nomic` SDK; task-typed embeddings (`search_query`/`search_document`),
optional local (`pillow` for image embed). Trivial port surface.

### exa (391 LOC) — `ExaSearchRetriever` + 2 tools
Wraps `exa-py`. Neural search retriever + `ExaSearchResults`/`ExaFindSimilarResults` tools.
Pure search integration; no model inference.

---

## DEEP: standard-tests (`langchain_tests`, 9,820 LOC / 21 files)

Becomes **`ferrochain-standard-tests`** — the conformance suite that every provider crate
subscribes to. This is the P0-adjacent differentiator: a Rust port that ships a real
conformance matrix (not ad-hoc per-crate tests) is a market signal of production seriousness.

### Package structure

```
langchain_tests/
├── base.py                 (70)   BaseStandardTests — meta-test: no-override guard
├── conftest.py            (155)   VCR cassette serializer (gzip+YAML), custom persister
├── _langsmith_plugin.py    (91)   optional LangSmith test reporting plugin
├── unit_tests/
│   ├── chat_models.py    (1174)   ChatModelTests (base) + ChatModelUnitTests
│   ├── embeddings.py      (137)   EmbeddingsTests + EmbeddingsUnitTests
│   └── tools.py           (128)   ToolsTests + ToolsUnitTests
├── integration_tests/
│   ├── chat_models.py    (3593)   ChatModelIntegrationTests — 48 def test_ occurrences (~35-40 unique class-level methods; some are inner pydantic-compat overrides) <!-- [validation-corrected pass-5]: "60+ tests" was stale; grep -c "def test_" = 48 confirmed [validation-exhaustive]: reconfirmed 48 -->
│   ├── sandboxes.py      (1978)   SandboxIntegrationTests (deepagents-gated, 86 tests) <!-- [validation-exhaustive]: "100+" was inaccurate; grep -c "def test_" = 86 confirmed -->
│   ├── vectorstores.py    (842)   VectorStoreIntegrationTests (sync+async)
│   ├── indexer.py         (398)   Document{,Async}IndexerTestSuite
│   ├── base_store.py      (315)   BaseStore{Sync,Async}Tests (Generic[V])
│   ├── cache.py           (207)   {Sync,Async}CacheTestSuite
│   ├── retrievers.py      (182)   RetrieversIntegrationTests
│   ├── embeddings.py      (119)   EmbeddingsIntegrationTests
│   └── tools.py            (94)   ToolsIntegrationTests
└── utils/
    ├── stream_lifecycle.py(235)   v3 content-block protocol stream VALIDATOR
    └── pydantic.py         (14)   pydantic v1/v2 helper
```

### Conformance base-class hierarchy

```
BaseStandardTests                       # test_no_overrides_DO_NOT_OVERRIDE meta-guard
├── ChatModelTests (abstract)           # ~25 feature-flag @property toggles + fixtures
│   ├── ChatModelUnitTests              # no-network: init, env, serdes, standard params, bench
│   └── ChatModelIntegrationTests       # ~48 live/VCR behavior tests <!-- [validation-corrected pass-5]: "60+" stale; actual ~48 def test_ occurrences -->
├── EmbeddingsTests
│   ├── EmbeddingsUnitTests
│   └── EmbeddingsIntegrationTests
├── ToolsTests
│   ├── ToolsUnitTests
│   └── ToolsIntegrationTests
├── RetrieversIntegrationTests
├── VectorStoreIntegrationTests
├── BaseStoreSyncTests[V] / BaseStoreAsyncTests[V]
├── SyncCacheTestSuite / AsyncCacheTestSuite
├── Document IndexerTestSuite / AsyncDocumentIndexTestSuite
└── SandboxIntegrationTests             # deepagents-gated (86 file-op/exec tests) <!-- [validation-exhaustive]: "100+" was inaccurate; actual 86 -->
```

### The subscription mechanism (critical for the Rust mapping)
A provider package subscribes by (1) subclassing the base test class and (2) supplying the
`chat_model_class` fixture + `chat_model_params`, then (3) selectively overriding **capability
`@property` flags** to opt into optional behavior. The flags observed in `ChatModelTests`:

`has_tool_calling`, `has_tool_choice`, `has_structured_output`, `structured_output_kwargs`,
`supports_json_mode`, `supports_image_inputs`, `supports_image_urls`, `supports_pdf_inputs`,
`supports_audio_inputs`, `supports_video_inputs`, `returns_usage_metadata`,
`supports_anthropic_inputs`, `supports_image_tool_message`, `supports_pdf_tool_message`,
`enable_vcr_tests`, `supported_usage_metadata_details`, `supports_model_override`,
`model_override_value`, plus `standard_chat_model_params` (temperature=0, max_tokens=100,
timeout=60, stop=[], max_retries=2).

Defaults are conservative (most `supports_*` default `False`; `has_tool_calling`/`has_structured_output`
auto-detect via method-override introspection). A test whose gating flag is `False` is skipped
(via `pytest.mark.skipif`-style branches inside the test body). **`test_no_overrides_DO_NOT_OVERRIDE`**
uses reflection to forbid a subscriber from silently deleting or overriding a standard test
without an explicit `@pytest.mark.xfail(reason=...)` — i.e. you cannot quietly opt OUT of a
mandatory behavior; you must declare an xfail with a reason.

### Test harness dependencies
`pytest` + `pytest-asyncio` (async tests), `syrupy` (snapshot/serdes golden tests, `.ambr`),
`vcrpy` (`enable_vcr_tests` — records HTTP cassettes; custom gzip+YAML serializer in
`conftest.py`), `pytest-socket` (blocks network in unit tests), `pytest-benchmark`/`pytest-codspeed`
(`test_init_time`, `test_stream_time`), `numpy` (embeddings/vectorstore assertions), optional
`deepagents` (sandboxes) and `langsmith` (reporting plugin).

## State Checkpoint
```yaml
pass: 4
artifact: module-inventory
status: complete
partners_deep: [openai, anthropic, ollama]
partners_inventory: [openrouter, qdrant, huggingface, mistralai, fireworks, perplexity, groq, chroma, xai, deepseek, exa, nomic]
standard_tests: deep
timestamp: 2026-07-12
```
