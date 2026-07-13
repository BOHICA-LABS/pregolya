---
artifact: semport/partners/dependency-disposition
project: ferrochain
port_target: langchain partner packages + standard-tests
analyzer_pass: 4
date: 2026-07-12
note: analysis only — NO Rust code committed. MAP/PORT/ELIMINATE dispositions +
  the MAP-vs-direct-HTTP decision per deep provider with evidence.
consistency: aligns with semport/core/dependency-disposition.md (serde+schemars for
  pydantic; backon for tenacity/retry) and CLAUDE.md (reqwest rustls-tls mandate,
  credential newtypes, 30s timeout, no-unwrap).
---

# Partner Packages + standard-tests — Dependency Disposition

Disposition legend: **MAP** = use a Rust crate; **PORT** = reimplement in Rust;
**ELIMINATE** = absorbed by the type system / out of scope.

## 0. The central decision: vendor SDK MAP vs direct-HTTP

Every Python partner wraps a vendor SDK (`openai`, `anthropic`, `ollama`, `groq`, ...) that
provides ONLY: HTTP transport, retry/backoff, auth, typed request/response DTOs, and SSE
parsing. **All the value langchain adds is translation** (content-block ↔ wire) — which we
must write regardless of transport choice.

### Decision framework (production-grade lens, per CLAUDE.md)

Three forces push the decision:

1. **Fidelity thesis of a semantic port.** We must reproduce langchain's exact translation +
   pass the conformance suite. An external Rust SDK imposes its *own* message model, inserting
   a third representation (their DTO ↔ our content block ↔ provider wire). That doubles the
   translation surface and couples ferrochain to the SDK author's design + release cadence.
2. **CLAUDE.md hard mandates.** reqwest MUST be `default-features=false, features=["rustls-tls"]`
   workspace-wide; `native-tls`/`default-tls` are forbidden (macOS Keychain + MITM-proxy risk);
   production clients MUST set a 30s timeout; credentials MUST be redacted newtypes; no
   `unwrap`/`expect`. **An external SDK manages its own reqwest client**, so we cannot
   guarantee the rustls-tls-only invariant transitively, cannot force the timeout, and its
   credential types are not our redacted newtypes. Compliance-by-transitive-feature is exactly
   the "silently enables native-tls" trap CLAUDE.md calls out.
3. **Feature completeness.** We need OpenAI's Responses API + Chat Completions dual routing,
   Anthropic thinking + prompt-caching + server tools, and Ollama's url-auth. Rust SDK
   coverage of these is partial and moving (see evidence).

### Evidence — candidate Rust crates (verified 2026-07)
- **`async-openai` (0.28.1):** supports the Responses API (`client.responses().create()`),
  has a `byot` ("bring your own types") feature for custom DTOs, supports Azure. TLS feature
  is named **`rustls`** (+`rustls-webpki-roots`), NOT `rustls-tls`; default features must be
  disabled to avoid native-tls. Uses reqwest. Verdict: usable as a *reference / optional
  Responses-types bootstrap*, but its message model ≠ our content blocks.
- **`genai` (jeremychone, 0.6.x):** multiprovider (OpenAI, Anthropic, Ollama, Groq, DeepSeek,
  xAI, Gemini, ...), has Anthropic thinking/reasoning-effort, prompt caching (Anthropic +
  OpenAI `prompt_cache_key`), an in-progress OpenAI Responses adapter, built-in tools, native
  Ollama protocol, custom auth/endpoint/headers. **It is a UNIFIED abstraction that hides
  provider detail** — precisely the opposite of what a fidelity port + conformance suite need.
  Verdict: **REJECT as a port dependency** (wrong abstraction level); note as prior art for
  adapter design and as a possible future "just-works facade" crate outside semport scope.
- **`ollama-rs`:** community crate over the local Ollama HTTP API; reasonable, but the API is
  tiny and we need `parse_url_with_auth` Basic-auth + rustls control + zero-surprise DTU path.

### RECOMMENDATION per deep provider

| Provider | Decision | Rationale (evidence) |
|---|---|---|
| **openai** | **DIRECT-HTTP** (own transport + own serde DTOs for Chat Completions AND Responses) | (a) Dual API + langchain's exact `_use_responses_api` routing must be reproduced; async-openai's Responses support exists but its DTOs aren't our content blocks. (b) Need rustls-tls + 30s timeout + SSRF guard + per-chunk stream timeout under our control. (c) **Maximum leverage**: deepseek, xai, groq, fireworks, openrouter all ride OpenAI-shaped wire → one owned `openai-wire` module serves 6 crates. Optionally consult async-openai's Responses types to bootstrap the schemas (reference, not dependency). |
| **anthropic** | **DIRECT-HTTP** | No mature official Rust SDK; must reproduce thinking / `redacted_thinking` / prompt-caching / server-tool fidelity; Messages API is small + stable; Python's own `langchain-mistralai` proves direct-HTTP (httpx) is clean for a provider of this size. reqwest+rustls + `reqwest-eventsource` for SSE. |
| **ollama** | **DIRECT-HTTP** (lightweight, ~250-350 LOC transport) | Tiny, stable local API; must reproduce `parse_url_with_auth` Basic-auth + `validate_model`; it is the API-key-free CI path (want zero external dep surprises). `ollama-rs` evaluated but rejected for control. |

**Unified consequence:** all provider crates depend on one shared **`ferrochain-partner-http`**
infra crate (name TBD at architecture) owning: the rustls-tls reqwest `Client` builder (30s
timeout, connection pool), retry/backoff (we **MAP `backon`** — this is the capability we LOSE
by not using the vendor SDKs, consistent with core strategy's tenacity→backon), SSE streaming
(`reqwest-eventsource` or `eventsource-stream`), NDJSON streaming (for Ollama), credential
newtypes, and base_url/proxy/env-var resolution. **This crate is the single highest-leverage
piece of partner infrastructure** and should be a Wave-early deliverable.

## 1. openai — dependency disposition

| Python dep | Disposition | Notes |
|---|---|---|
| `openai>=2.45` (SDK) | **DIRECT-HTTP** (see above) | transport + DTOs owned; async-openai as reference only |
| `tiktoken>=0.7` | **MAP → `tiktoken-rs`** | BPE tokenizer for token counting + len-safe embedding batching. Verify vocab/merge parity via golden tests. |
| httpx client tuning / SSRF / socket opts | **PORT** onto reqwest | `_client_utils.py`: TCP keepalive + `TCP_USER_TIMEOUT` → socket2 options; SSRF guard → validate resolved IP; per-chunk stream timeout → `tokio::time::timeout` around the SSE stream item future. |
| Azure AD auth | **PORT** | `azure_ad_token_provider` (sync) + async provider → a `TokenProvider` trait returning a future; credential newtype. |

## 2. anthropic — dependency disposition

| Python dep | Disposition | Notes |
|---|---|---|
| `anthropic>=0.96.0,<1.0.0` (SDK) <!-- [validation-certification-3]: added `<1.0.0` upper bound; pyproject.toml line 26: `anthropic>=0.96.0,<1.0.0` --> | **DIRECT-HTTP** | Messages API owned; `_client_utils.py` cached-client pattern → reqwest client cache. |
| `pydantic>=2.7.4` | **PORT → serde + schemars** | Same disposition as core (see core dependency-disposition; tool-schema golden-tested). |
| prompt-caching `cache_control` | **PORT** | Data-shape only (`{type:ephemeral,ttl}`); pure logic. |

## 3. ollama — dependency disposition

| Python dep | Disposition | Notes |
|---|---|---|
| `ollama>=0.6.1` (SDK) | **DIRECT-HTTP** | trivial local API. |
| `httpx` (transitive) | **MAP → reqwest (rustls-tls)** | + `parse_url_with_auth` Basic-auth header injection PORTED. |

### DTU fake for ollama (what the DTU-validator clone must serve)
Ollama is the API-key-free test path; a **DTU fake** (deterministic local server) must implement
the local Ollama HTTP surface that `ChatOllama`/`OllamaLLM`/`OllamaEmbeddings` call:
- `GET /api/tags` — returns `{"models":[{"model":"...","name":"..."}]}` (drives `validate_model`
  via `client.list()`; the fake must list whatever model name the test uses).
<!-- [validation-exhaustive]: `GET /api/version` entry REMOVED — the langchain-ollama package does NOT call this endpoint. `_set_ollama_version` (chat_models.py L926) only sets the Python package's own `__version__` metadata; it never makes an HTTP call to `/api/version`. No call to the Ollama version endpoint exists anywhere in langchain_ollama/ -->
- `POST /api/chat` — non-streaming returns `{"message":{"role":"assistant","content":"...",
  "tool_calls":[...]}, "done":true, "done_reason":"stop", "prompt_eval_count":N, "eval_count":M}`;
  streaming returns **newline-delimited JSON** (NDJSON, not SSE) — a sequence of partial
  `{"message":{"content":"..."},"done":false}` then a final `{"done":true, ...counts}`.
- `POST /api/generate` — analogous for `OllamaLLM`.
- `POST /api/embed` (and legacy `/api/embeddings`) — `{"embeddings":[[...floats...]]}`.
- Must honor: `format` param (`"json"` or a JSON-schema object) by returning schema-valid JSON;
  `options` (temperature, num_predict, num_ctx, top_logprobs, keep_alive); and an
  `Authorization: Basic ...` header when the base_url carried `user:pass@`.
This fake is small and deterministic → an excellent DTU-clone target validated by
`vsdd-factory:dtu-validator` against a real local Ollama.

## 4. Inventory-level partners — disposition summary

| Package | Vendor SDK | Disposition |
|---|---|---|
| deepseek, xai | (via `langchain-openai`) | **PORT as thin subclasses** of ferrochain's `BaseChatOpenAI` equivalent; reuse the owned OpenAI-wire transport. No new SDK. |
| groq, fireworks, openrouter, perplexity | `groq`, `fireworks-ai`, `openrouter`, `perplexityai` | **DIRECT-HTTP** on the shared OpenAI-shaped wire where applicable; perplexity adds citation/search-result parsing (PORT). Later wave. |
| mistralai | none (already httpx direct) | **DIRECT-HTTP** — trivial; `tokenizers` → **MAP `tokenizers` (HF Rust crate)**. |
| huggingface | `huggingface-hub`, `tokenizers` | Endpoint path: **DIRECT-HTTP** (TGI). Local pipeline/sentence-transformers: **DEFER** (pulls torch/transformers — out of v1). `tokenizers` → MAP HF Rust `tokenizers`. |
| chroma | `chromadb` | **MAP** a chroma Rust client or **DIRECT-HTTP** to chroma server; later wave (vectorstore). |
| qdrant | `qdrant-client` | **MAP → `qdrant-client` (official Rust crate exists)**; sparse/hybrid PORT; later wave. |
| nomic | `nomic` | **DIRECT-HTTP** (trivial); image embed (`pillow`) → `image` crate if kept. |
| exa | `exa-py` | **DIRECT-HTTP** (search REST); later wave. |

**numpy** (chroma/qdrant/mistralai/standard-tests) → **MAP `ndarray`** or plain `Vec<f32>` +
manual cosine; **pillow** (nomic) → **MAP `image`**; **aiohttp/requests** (fireworks/xai) →
**ELIMINATE** (subsumed by reqwest).

## 5. standard-tests — dependency disposition

| Python dep | Disposition | Notes |
|---|---|---|
| `pytest` + `pytest-asyncio` | **PORT → Rust test harness** | Rust `#[test]`/`#[tokio::test]` + a trait + declarative macro generating the test matrix (see rust-translation-strategy). |
| `vcrpy` (+ gzip/YAML cassette serializer) | **MAP → `wiremock` or `rvcr`/`vcr-cassette`** | Record/replay HTTP so conformance runs without provider secrets in CI. **Prerequisite for a useful `ferrochain-standard-tests`.** |
| `syrupy` (snapshot) | **MAP → `insta`** | For `test_serdes` golden snapshots (the `.ambr` analog → `.snap`). |
| `pytest-socket` (network block in unit) | **PORT** | Unit conformance must not touch network — enforce via a no-network client injection or a deny-all reqwest resolver in unit mode. |
| `pytest-benchmark`/`pytest-codspeed` (`test_init_time`, `test_stream_time`) | **MAP → `criterion`** or a lightweight timing gate | Benchmark conformance is P2. |
| `numpy` (embeddings/vectorstore assertions) | **MAP → `ndarray`** | |
| `deepagents` (sandboxes) | **ELIMINATE / DEFER** | Sandbox conformance out of ferrochain v1. |
| `langsmith` (reporting plugin) | **ELIMINATE from core** | Optional exporter, consistent with core disposition. |

## State Checkpoint
```yaml
pass: 4
artifact: dependency-disposition
status: complete
map_vs_direct_http:
  openai: direct-http
  anthropic: direct-http
  ollama: direct-http
  shared_infra: ferrochain-partner-http (rustls-tls reqwest + backon retry + SSE/NDJSON + credential newtypes)
  rejected_dependency: genai (wrong abstraction level for a fidelity port)
timestamp: 2026-07-12
```
