---
document_type: behavioral-contract
level: L3
bc_id: BC-2.22.003
version: "1.0"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-22
capability: CAP-033
crate: ferrochain-ollama
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008, DI-014]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-22 Embeddings"
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-033
  - architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "96557c2"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.22.003: EmbeddingsOllama — No API Key; POST /api/embed Preferred; use_legacy_endpoint Toggle for /api/embeddings; reqwest/rustls-tls/.timeout(30s) Unconditional

## Description

`EmbeddingsOllama` is a first-party `Embeddings` implementation in `ferrochain-ollama:
ollama::embeddings` for local Ollama deployments. The model name is fully configurable
with no default (callers must specify the locally-pulled model, e.g., `"nomic-embed-text"`
or `"mxbai-embed-large"`). No API key is required — Ollama is a local service authenticated
only by network access. The implementation prefers `POST /api/embed` (newer Ollama endpoint,
`input` field, supports batch); `use_legacy_endpoint: bool = false` toggles to
`POST /api/embeddings` (legacy, `prompt` field, single-text only) for Ollama deployments that
predate `/api/embed`. The `reqwest::Client` uses `rustls-tls` and `.timeout(30s)` — this is
unconditional and applies even for `localhost` targets.

## Preconditions

1. `EmbeddingsOllama` is constructed with a `model: String` and an Ollama `base_url: String`
   (e.g., `"http://localhost:11434"`).
2. `use_legacy_endpoint: bool` is set at construction (default `false`).
3. The Ollama process is running and the model has been pulled (`ollama pull <model>`).

## Postconditions

1. **Default endpoint (`use_legacy_endpoint: false`):**
   - `embed_documents(texts)`: sends `POST <base_url>/api/embed` with body
     `{ "model": "<model>", "input": [<texts>] }`.
     Returns `Ok(vecs)` where `vecs.len() == texts.len()`.
   - `embed_query(text)`: sends `POST <base_url>/api/embed` with body
     `{ "model": "<model>", "input": ["<text>"] }` (single-element array).
     Returns `Ok(vec)`.
2. **Legacy endpoint (`use_legacy_endpoint: true`):**
   - `embed_documents(texts)`: sends one `POST <base_url>/api/embeddings` request per text
     (serial), with body `{ "model": "<model>", "prompt": "<text>" }`. Returns `Ok(vecs)` with
     one vector per text. If any single-text call fails, the whole `embed_documents` call
     returns `Err(FerrochainError { ... })` — no partial result (DI-014).
   - `embed_query(text)`: sends `POST <base_url>/api/embeddings` with
     `{ "model": "<model>", "prompt": "<text>" }`. Returns `Ok(vec)`.
3. **No API key:** `EmbeddingsOllama` has no `api_key` field. No `Authorization` header is set.
4. **HTTP client:** `reqwest` dep uses `default-features = false, features = ["rustls-tls"]`.
   Client is built with `.timeout(Duration::from_secs(30))`. This applies for `localhost`
   targets — the timeout is unconditional and not disabled for local connections.
5. **Model validation:** not enforced at construction — invalid or unpulled model names fail
   at the first API call with `Err(FerrochainError { ... })` from the HTTP response body.

## Invariants

1. **Legacy endpoint is opt-in, not auto-detected.** `EmbeddingsOllama` never silently falls
   back to `/api/embed` if `/api/embeddings` fails, or vice versa. The endpoint is fixed at
   construction via `use_legacy_endpoint`. Auto-detection by probing both endpoints is
   explicitly forbidden (it creates unpredictable behavior and masks misconfiguration).
2. **rustls-tls unconditional for localhost.** The 30-second timeout and rustls-tls apply even
   when `base_url` is `localhost` or `127.0.0.1`. There is no `if localhost { skip_tls }` branch.
   This is consistent with the workspace convention: reqwest configuration is uniform, not
   environment-conditional.
3. **Batch DI-014 compliance for legacy endpoint.** When `use_legacy_endpoint: true` and a
   batch of N texts is submitted, if any of the N serial requests fails, the error propagates
   immediately as `Err(...)` for the whole `embed_documents` call. Already-received embeddings
   are NOT returned as a partial list.
4. `EmbeddingsOllama` is `Send + Sync` — the `reqwest::Client` is `Clone + Send + Sync`.
5. `use_legacy_endpoint` is immutable after construction — it cannot be changed at runtime.
   Callers needing both endpoints construct two separate `EmbeddingsOllama` instances.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `use_legacy_endpoint: false`, Ollama binary predates `/api/embed` (returns 404) | `Err(FerrochainError { ... })` — 404 propagates; no silent fallback to `/api/embeddings` |
| EC-002 | `use_legacy_endpoint: true`, batch of 5 texts; 3rd request returns 500 | `Err(FerrochainError { ... })` — first 2 embeddings discarded; Err for whole call |
| EC-003 | Ollama process not running (connection refused) | `Err(FerrochainError { ... })` wrapping the reqwest connection error; no retry |
| EC-004 | Model not pulled locally (Ollama returns 404 with body `"model not found"`) | `Err(FerrochainError { ... })` — error message includes model name if safe to include |
| EC-005 | Request takes > 30 seconds (slow local model) | `Err(FerrochainError { ... })` wrapping the reqwest timeout; 30s applies even for localhost |
| EC-006 | `embed_documents(vec![])` with legacy endpoint | `Ok(vec![])` — zero requests sent; not an error |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `embed_documents(vec!["hello"])` with `use_legacy_endpoint: false`, mock `/api/embed` returning 768-dim vector | `Ok(vec![[f32; 768]])` | happy-path (default endpoint) |
| TV-002 | `embed_query("hello")` with `use_legacy_endpoint: false` | `Ok([f32; 768])` | happy-path (default endpoint, single query) |
| TV-003 | `embed_documents(vec!["hello"])` with `use_legacy_endpoint: true`, mock `/api/embeddings` | `Ok(vec![[f32; 768]])` | happy-path (legacy endpoint) |
| TV-004 | `use_legacy_endpoint: false`; Ollama returns 404 for `/api/embed` | `Err(FerrochainError { ... })` — no fallback to `/api/embeddings` | error-case (no auto-fallback) |
| TV-005 | `use_legacy_endpoint: true`; 2-text batch; second request returns 500 | `Err(FerrochainError { ... })` — first embedding discarded | error-case (DI-014 partial-failure) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.22.003-A | `use_legacy_endpoint: false` sends exactly one `/api/embed` request regardless of batch size | unit test with mock HTTP server — assert single request for batch of 5 |
| VP-2.22.003-B | `use_legacy_endpoint: true` sends exactly N serial `/api/embeddings` requests for N texts | unit test with mock HTTP server — assert request count |
| VP-2.22.003-C | No auto-fallback: a 404 on `/api/embed` does not trigger a request to `/api/embeddings` | unit test — mock `/api/embed` as 404; assert no request to `/api/embeddings` |

## Related BCs

- BC-2.22.001 — depends on: EmbeddingsOllama implements the Embeddings trait defined in BC-2.22.001; all dimensionality-contract postconditions apply

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-22, `ollama::embeddings` module in ferrochain-ollama
- `architecture/decisions/ADR-017-embeddings-trait-provider-integration.md` — Decision 3 (ferrochain-ollama gains embeddings, no API key, `/api/embed` preferred, `use_legacy_endpoint` toggle for `/api/embeddings`, reqwest constraints) and v1.1 (endpoint preference and toggle details)
- `CLAUDE.md` §Code Conventions — `reqwest TLS backend — rustls-tls mandatory`, `HTTP client timeout`

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-22 story]_

## VP Anchors

- VP-2.22.003-A, VP-2.22.003-B, VP-2.22.003-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-033 |
| Capability Anchor Justification | CAP-033 ("EmbeddingsOllama — Model-Configurable; /api/embed (Default); use_legacy_endpoint Toggle; No API Key") per capabilities-p1-p2.md §CAP-033 — this BC specifies the EmbeddingsOllama implementation with no-API-key local deployment, POST /api/embed preferred endpoint with use_legacy_endpoint toggle for /api/embeddings, reqwest/rustls-tls/30s unconditional (including localhost), and DI-014 batch partial-failure semantics that CAP-033 defines as a BC surface distinct from EmbeddingsOpenAI |
| L2 Domain Invariants | DI-008 (embed_documents/embed_query return Result; no .unwrap()), DI-014 (legacy endpoint batch partial-failure propagates as Err for entire call; already-received embeddings are NOT returned as partial list) |
| Architecture Authority | ADR-017 Decision 3 and v1.1 (ferrochain-ollama scope, /api/embed preferred, use_legacy_endpoint, no API key, reqwest constraints) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-ollama / ollama::embeddings |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (mock HTTP server — endpoint selection, batch serialization, no auto-fallback) |
