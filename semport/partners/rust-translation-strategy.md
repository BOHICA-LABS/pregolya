---
artifact: semport/partners/rust-translation-strategy
project: ferrochain
port_target: langchain partner packages + standard-tests → ferrochain-{openai,anthropic,ollama,...} + ferrochain-standard-tests
analyzer_pass: 4
date: 2026-07-12
note: strategy only — NO Rust code committed; signatures are illustrative sketches
consistency: aligned with semport/core/rust-translation-strategy.md (async-first, dyn+boxed
  futures at plugin seams, serde-tagged enums for content blocks, ChatModel: Runnable trait)
  and semport/langchain/rust-translation-strategy.md, and CLAUDE.md (rustls-tls, credential
  newtypes, 30s timeout, no-unwrap, non_exhaustive public types).
---

# Partner Packages + standard-tests → Rust — Translation Strategy

Difficulty scale: 🟢 easy · 🟡 moderate · 🟠 hard · 🔴 very hard / research-grade.

The provider crates are **translation layers over `ferrochain-core`'s `ChatModel: Runnable`
trait**. Their hard problems are: (1) faithful content-block ↔ wire translation, (2) streaming
event decode with correct chunk-merge, (3) the shared HTTP infrastructure, and (4) the
conformance-suite crate. Everything else is registry/config glue.

## 1. Shared partner infrastructure — 🟠 (build FIRST)

A `ferrochain-partner-http` crate (name TBD at architecture) that every provider crate depends
on. This is where the vendor-SDK-equivalent transport lives, since we chose direct-HTTP:

```rust
// illustrative sketch
pub struct ProviderClient { http: reqwest::Client, base_url: Url, retry: RetryPolicy }

impl ProviderClient {
    pub fn builder() -> ProviderClientBuilder { /* rustls-tls, 30s timeout enforced */ }
    pub async fn post_json<Req: Serialize, Resp: DeserializeOwned>(
        &self, path: &str, body: &Req) -> Result<Resp, ProviderError> { /* backon retry */ }
    pub fn post_sse<Req: Serialize>(&self, path: &str, body: &Req)
        -> BoxStream<'_, Result<SseEvent, ProviderError>> { /* reqwest-eventsource */ }
    pub fn post_ndjson<Req: Serialize>(&self, path: &str, body: &Req)
        -> BoxStream<'_, Result<serde_json::Value, ProviderError>> { /* Ollama */ }
}
```
Owns, per CLAUDE.md:
- **reqwest client** `default-features=false, features=["rustls-tls"]`, `.timeout(30s)`.
- **retry/backoff** via **`backon`** (MAP) — replaces the vendor SDKs' built-in retry we gave
  up; match langchain's `max_retries` default semantics (openai None→SDK-default, anthropic 2).
- **credential newtypes** with redacted `Debug`: `OpenAiApiKey`, `AnthropicApiKey`,
  `AzureAdToken`, and — crucially for Ollama — the base_url-embedded credential must also be a
  redacted newtype (`OllamaBaseUrl` carrying optional Basic-auth). 🟡
- **env-var + base_url + proxy resolution**: a small resolver replicating
  `secret_from_env`/`from_env` precedence (explicit param → env var → default/error) and the
  base_url precedence chain (openai: `base_url` → `OPENAI_API_BASE` → `OPENAI_BASE_URL`).
- **typed error mapping** incl. per-provider `ContextOverflowError` (thiserror enum in the
  ferrochain error taxonomy).
- **per-chunk stream timeout** → `tokio::time::timeout` wrapping each stream item future,
  yielding a `StreamChunkTimeoutError` variant.

Open question: whether `tower` middleware (retry/timeout `Layer`s) is used here to stay
consistent with core's `Runnable`≈`tower::Service` direction. Recommend yes — retry/timeout as
tower layers composes with the core Runnable stack.

## 2. openai → ferrochain-openai — 🔴 (largest, highest leverage)

The keystone provider crate because 5 other providers ride its wire. Structure:

- **`openai-wire` module** — serde DTOs + translation for BOTH APIs:
  - **Chat Completions**: `_convert_message_to_dict`/`_convert_dict_to_message`,
    `_format_message_content`, `_convert_delta_to_message_chunk` → Rust fns over serde structs.
  - **Responses API**: `_construct_responses_api_payload`/`_input`,
    `_construct_lc_result_from_responses_api`, and the stateful streaming cursor
    `_convert_responses_chunk_to_generation_chunk` (`_advance(output_idx, sub_idx)`) → a small
    stateful `ResponsesStreamDecoder` struct. 🔴 (the stateful multi-index cursor is the
    trickiest single piece).
  - **routing**: `_use_responses_api(payload)` + `_model_prefers_responses_api(name)` → pure
    fns; routing is base_url-agnostic (users must explicitly set `use_responses_api=False` for non-OpenAI endpoints; there is no automatic gate). 🟡 <!-- [validation-corrected pass-8]: "`base_url` set disables Responses auto-routing" was inaccurate; `_use_responses_api` has no base_url check; only `stream_usage` auto-enabling is gated on base_url -->
- **`ChatOpenAI`** impls `ChatModel: Runnable<Input=LanguageModelInput, Output=AiMessage>`.
- **structured output** (3 methods) → `enum StructuredMethod { FunctionCalling, JsonMode,
  JsonSchema }`; `json_schema` uses schemars-generated schema (the **pydantic→schemars ADR**
  from core §6 — golden-test the emitted schema against fixtures); `OpenAIRefusalError` variant. 🟠
- **token counting** → `tiktoken-rs` (MAP) + PORT the image-tile formula (`_url_to_size`,
  `_count_image_tokens`, `_resize`) with golden tests. 🟠
- **embeddings** → len-safe chunked batching preserving order (NO silent empty per CLAUDE.md). 🟡
- **Azure** → `AzureChatOpenAI` as a config/credential variant: deployment routing, api_version,
  `azure_ad_token` + a `TokenProvider` trait (sync+async collapse to async). 🟡
- **deepseek / xai** → thin structs delegating to the openai-wire + `BaseChatOpenAI` equivalent;
  override model list, base_url, env var, and (deepseek) `reasoning_content` handling. 🟢 once
  the base exists.

`#[non_exhaustive]` on all public config/message/error types per CLAUDE.md.

## 3. anthropic → ferrochain-anthropic — 🟠

- **message translation** — `_format_messages` + `_merge_messages` (consecutive same-role
  merge) are the crux; must be byte-faithful (conformance `test_double_messages_conversation`
  locks it). 🟠
- **content blocks** — `_format_data_content_block`/`_format_image` (image/pdf/file) and the
  reverse (`text`/`thinking`/`redacted_thinking`/`tool_use` → v3 standard blocks); reuse
  core's serde-tagged `ContentBlock` enum. 🟠
- **thinking** — `thinking: Option<ThinkingConfig>` (`Enabled{budget_tokens}`|`Disabled`);
  streaming assembles `thinking_delta`+`signature_delta`; structured-output-with-thinking →
  clone model with thinking off (`_get_llm_for_structured_output_when_thinking_is_enabled`). 🟠
- **prompt caching** — `cache_control` data struct + a `PromptCachingMiddleware` (ties to
  ferrochain's middleware trait from semport/langchain §1/§6); tag last block / last tool /
  model_settings; surface cache tokens in usage metadata. 🟡
- **streaming decode** — `_make_message_chunk_from_anthropic_event` → a `match` over the
  Anthropic SSE event enum. 🟠
- **server tools** (bash/file-search/code-exec) → middleware impls; P2/P3. 🟠

## 4. ollama → ferrochain-ollama — 🟡 (also the DTU + CI path)

- **transport**: direct-HTTP NDJSON streaming (not SSE) via `post_ndjson`. 🟡
- **`parse_url_with_auth`** → PORT exactly (IPv6-safe, percent-decode, Basic-auth header);
  base_url becomes a redacted newtype. 🟡
- **`validate_model`** → GET `/api/tags`, error taxonomy for missing-model vs connect-fail vs
  API-error. 🟢
- **structured output** → `format` field (`"json"` | schema) via `_resolve_format_param`. 🟢
- **tool calls** → OpenAI-shaped; tolerant arg parse (`_parse_json_string`). 🟡
- The **DTU fake** (see dependency-disposition §3) mirrors this surface for keyless CI.

## 5. Inventory-level partners — PORT on demand, later waves
groq/fireworks/openrouter/perplexity: OpenAI-shaped wire reuse + provider quirks (perplexity
citations/reasoning parsers). mistralai: direct-HTTP + HF `tokenizers`. huggingface:
endpoint-only in v1 (defer local torch). chroma/qdrant: vectorstore crates, later wave (qdrant
MAP official Rust client). nomic/exa: trivial direct-HTTP. All bind the shared infra crate.

## 6. standard-tests → ferrochain-standard-tests — 🟠 (P0-adjacent; the differentiator)

This is the marquee mapping. Goal: a Rust crate that, like `langchain-tests`, lets a provider
crate subscribe to a conformance matrix and be forced to pass mandatory behaviors.

### 6a. Capability flags → trait with defaulted associated consts/methods
Python's `@property` feature flags (`supports_image_inputs`, `has_tool_calling`, ...) become a
**config trait** the subscriber implements, with conservative defaults matching Python:

```rust
// illustrative sketch
#[async_trait]
pub trait ChatModelConformance: Send + Sync {
    type Model: ChatModel;                       // the model under test
    fn build_model(&self, params: StandardParams) -> Self::Model;   // ≈ `model` fixture

    // capability flags — defaults mirror Python (most false; tool/struct auto-ish)
    fn has_tool_calling(&self) -> bool { false }
    fn has_tool_choice(&self) -> bool { false }
    fn has_structured_output(&self) -> bool { self.has_tool_calling() }
    fn supports_json_mode(&self) -> bool { false }
    fn supports_image_inputs(&self) -> bool { false }
    fn supports_image_urls(&self) -> bool { false }
    fn supports_pdf_inputs(&self) -> bool { false }
    fn supports_audio_inputs(&self) -> bool { false }
    fn returns_usage_metadata(&self) -> bool { true }
    fn supports_anthropic_inputs(&self) -> bool { false }
    fn supports_image_tool_message(&self) -> bool { false }
    fn supports_pdf_tool_message(&self) -> bool { false }
    fn supports_model_override(&self) -> bool { true }
    fn model_override_value(&self) -> Option<&str> { None }
    fn supported_usage_metadata_details(&self) -> UsageDetailSupport { Default::default() }
    fn structured_output_kwargs(&self) -> StructuredOutputKwargs { Default::default() }
    fn enable_vcr(&self) -> bool { false }
    fn standard_params(&self) -> StandardParams {
        StandardParams { temperature: 0.0, max_tokens: 100, timeout: 60, stop: vec![], max_retries: 2 }
    }
}
```

### 6b. Test matrix → declarative macro (the key design)
Rust has no pytest collection/skip mechanism, so we replace it with a **macro that generates
one `#[tokio::test]` per conformance behavior**, each guarded at runtime by the relevant
capability flag (skip = early-return, mirroring Python's gated skips):

```rust
// illustrative sketch — subscriber side
conformance_chat_model_integration!(TestChatOpenAI, ChatOpenAIConformance);
// expands to ~48 #[tokio::test] fns: test_invoke, test_stream, test_stream_events_v3, <!-- [validation-corrected pass-4]: ~62 was derived from the original inflated Python integration test count (~62); pass-1 corrected that count to ~48 def test_ occurrences / ~35-40 unique class methods; the Rust macro mirrors the Python suite, so estimate is ~48 -->
// test_tool_calling (if cfg.has_tool_calling() else return), test_image_inputs
// (if cfg.supports_image_inputs() else return), ...
```
Two macros: `conformance_chat_model_unit!` (no network; the `pytest-socket` guard → inject a
deny-all client) and `conformance_chat_model_integration!` (live or VCR). Additional macros
per suite: embeddings, tools, vectorstores, retrievers, cache, base_store, indexer.

**Why macro-generated rather than a `#[test]`-per-trait-default:** trait default methods can't
be collected as separate test cases by the Rust harness; a macro emits real, individually
named, individually reportable test functions — matching langchain's "each behavior is a named
test" property and giving per-behavior CI signal. 🟠

### 6c. The no-opt-out guard → compile-time + macro completeness
Python's `test_no_overrides_DO_NOT_OVERRIDE` (reflection: you can't delete/override a standard
test without `@pytest.mark.xfail(reason=...)`) maps to: the macro OWNS the full test list, so a
subscriber physically cannot omit one. To allow declared exceptions, the macro accepts an
`xfail = [test_name => "reason", ...]` argument that turns that generated test into a
`#[should_panic]`/documented-skip WITH a mandatory reason string (compile error if reason
absent). This preserves the "opt out only explicitly, with a reason" contract. 🟠

### 6d. The v3 stream-lifecycle validator → a reusable oracle fn
`utils/stream_lifecycle.py` → `pub fn assert_stream_lifecycle(events: impl IntoIterator<Item=ProtocolEvent>)`
that any provider's `stream_events(v3)` output is piped through. Asserts: message-start opens /
message-finish closes; block indices sequential uint from 0; deltaable types
(`text`/`reasoning`/`tool_call_chunk`/`server_tool_call_chunk`) accumulate to the finish
payload. **Highest-value single artifact — port first, it doubles as a core streaming test.** 🟡

### 6e. HTTP record/replay → VCR-equivalent
MAP `wiremock` or an `rvcr`/`vcr-cassette` layer so `enable_vcr()` conformance runs without
provider secrets in CI (see dependency-disposition §5). Snapshot serdes tests → `insta`
(replaces syrupy `.ambr`). Benchmarks (`test_init_time`/`test_stream_time`) → `criterion`, P2.

### 6f. Async duality
Python has mirrored sync+async conformance (`test_invoke`/`test_ainvoke`, sync+async vectorstore
suites). Ferrochain is async-first (CLAUDE.md), so the async variant IS the primary; the sync
"a"-less tests collapse to the same async test (or a thin `block_on` wrapper test if a sync
facade exists). This halves the vectorstore/cache/base_store/indexer suite sizes. 🟢

## Difficulty / risk summary

| Subsystem | Difficulty | Primary risk |
|---|---|---|
| ferrochain-partner-http (shared) | 🟠 | rustls-tls + timeout + backon retry parity with vendor SDK behavior; SSE + NDJSON streaming; credential newtypes incl. Ollama URL-embedded auth |
| openai (dual API + Responses stream cursor) | 🔴 | stateful Responses stream decoder; schemars vs OpenAI json_schema acceptance; tiktoken image-token formula parity |
| anthropic (merge + thinking + caching) | 🟠 | `_merge_messages` byte-fidelity (conformance-locked); thinking↔structured-output interaction |
| ollama + DTU fake | 🟡 | NDJSON streaming; URL-auth parsing; DTU-fake surface completeness |
| ferrochain-standard-tests | 🟠 | macro-generated matrix + no-opt-out guard + VCR record/replay; the differentiator |
| thin subclasses (deepseek/xai) | 🟢 | gated on openai base existing |
| vectorstores (chroma/qdrant) | 🟡 | later wave; idempotency/ordering invariants |

## Cross-cutting open design questions (candidate ADRs)

1. **ADR: vendor-SDK vs direct-HTTP** (recommendation: direct-HTTP for openai/anthropic/ollama;
   reject genai; async-openai as reference only) — formalize with the CLAUDE.md rustls-tls +
   credential-newtype + timeout constraints as the deciding evidence.
2. **ADR: pydantic→schemars JSON-schema boundary** (SHARED with core §6) — the emitted tool /
   structured-output schema must be provider-accepted; golden-test against pydantic fixtures.
   Blocks openai json_schema + anthropic tool schema + ollama format.
3. **ADR: conformance-suite shape** — macro-generated test matrix + capability trait + no-opt-out
   guard + VCR layer. Freeze the macro API before the first provider crate subscribes.
4. **ADR: ferrochain-partner-http surface** — retry (backon) semantics, per-chunk stream timeout,
   credential newtype set, base_url/proxy precedence; whether retry/timeout are `tower` layers.
5. **ADR: OpenAI-wire reuse** — one shared `openai-wire` module serving openai + deepseek + xai
   (+ groq/fireworks/openrouter where shaped) vs per-crate duplication.

## State Checkpoint
```yaml
pass: 4
artifact: rust-translation-strategy
status: complete
timestamp: 2026-07-12
```
