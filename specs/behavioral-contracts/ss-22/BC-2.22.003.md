---
document_type: behavioral-contract
level: L3
bc_id: BC-2.22.003
version: "1.6"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-22
capability: CAP-033
crate: pregolya-ollama
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-008, DI-009, DI-014]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-22 Embeddings"
  - "1.1 (F-P130-09/2026-07-21): Add DI-009 to di_anchors — PC4/INV-2 specify the mandatory 30s timeout (including localhost) but did not cite DI-009; add BC-2.14.004 cross-reference in PC4 and INV-2 prose."
  - "1.2 (WAVE-B-B3/2026-07-29): Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon). 9 CLASS3_ASCII_ELLIPSIS_VIOLATION corrected — PC2, PC5, EC-001, EC-002, EC-003, EC-004, EC-005, TV-004, TV-005 each had `Err(PregolyaError { ... })` — replaced `...` with `..` in all nine. No behavioral change."
  - "1.3 (P2A030-03/2026-08-22): EC-003 amended — replace bare generic `Err(PregolyaError { .. })` with full-form E-PROV-012 ProviderConnectionError citation. A connection-refused failure has no HTTP status, so E-PROV-008 (ProviderHttpError) cannot render for this path; E-PROV-012 was minted in error-taxonomy.md same burst to cover pre-response provider connection failures. EC-003 is the authoritative full-form gate #33 site for E-PROV-012. Story-writer handoff: re-anchor S-2.09 EC-003 from E-PROV-008 to E-PROV-012."
  - "1.4 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.09 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (B-SS19-23/HIGH-provider-error-codes/2026-08-26): HIGH gap closure — Ollama provider HTTP-status error codes added. EC-001 (404 /api/embed), EC-002 (500 serial), EC-004 (404 model-not-found): bare Err→E-PROV-008. EC-005 (timeout): bare Err→E-PROV-012. EC-003 (connection-refused) already carries E-PROV-012 from v1.3 — no change. TV-004 (404 no-fallback): E-PROV-008 cited. Reuses existing E-PROV-008/012 codes — no new E-code minted."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-033
  - architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-009
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "1953e2c"
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

`EmbeddingsOllama` is a first-party `Embeddings` implementation in `pregolya-ollama:
ollama::embeddings` for local Ollama deployments. The model name is fully configurable
with no default (callers must specify the locally-pulled model, e.g., `"nomic-embed-text"`
or `"mxbai-embed-large"`). No API key is required — Ollama is a local service authenticated
only by network access. The implementation prefers `POST /api/embed` (newer Ollama endpoint,
`input` field, supports batch); `use_legacy_endpoint: bool = false` toggles to
`POST /api/embeddings` (legacy, `prompt` field, single-text only) for Ollama deployments that
predate `/api/embed`. The `reqwest::Client` uses `rustls-tls` and `.timeout(30s)` — this is
unconditional and applies even for `localhost` targets.

## Preconditions

1. {PRE-001} `EmbeddingsOllama` is constructed with a `model: String` and an Ollama `base_url: String`
   (e.g., `"http://localhost:11434"`).
2. {PRE-002} `use_legacy_endpoint: bool` is set at construction (default `false`).
3. {PRE-003} The Ollama process is running and the model has been pulled (`ollama pull <model>`).

## Postconditions

1. {PC-001} **Default endpoint (`use_legacy_endpoint: false`):**
   - `embed_documents(texts)`: sends `POST <base_url>/api/embed` with body
     `{ "model": "<model>", "input": [<texts>] }`.
     Returns `Ok(vecs)` where `vecs.len() == texts.len()`.
   - `embed_query(text)`: sends `POST <base_url>/api/embed` with body
     `{ "model": "<model>", "input": ["<text>"] }` (single-element array).
     Returns `Ok(vec)`.
2. {PC-002} **Legacy endpoint (`use_legacy_endpoint: true`):**
   - `embed_documents(texts)`: sends one `POST <base_url>/api/embeddings` request per text
     (serial), with body `{ "model": "<model>", "prompt": "<text>" }`. Returns `Ok(vecs)` with
     one vector per text. If any single-text call fails, the whole `embed_documents` call
     returns `Err(PregolyaError { .. })` — no partial result (DI-014).
   - `embed_query(text)`: sends `POST <base_url>/api/embeddings` with
     `{ "model": "<model>", "prompt": "<text>" }`. Returns `Ok(vec)`.
3. {PC-003} **No API key:** `EmbeddingsOllama` has no `api_key` field. No `Authorization` header is set.
4. {PC-004} **HTTP client:** `reqwest` dep uses `default-features = false, features = ["rustls-tls"]`.
   Client is built with `.timeout(Duration::from_secs(30))` (DI-009 — 30s timeout mandatory;
   see BC-2.14.004). This applies for `localhost` targets — the timeout is unconditional and
   not disabled for local connections.
5. {PC-005} **Model validation:** not enforced at construction — invalid or unpulled model names fail
   at the first API call with `Err(PregolyaError { .. })` from the HTTP response body.

## Invariants

1. {INV-001} **Legacy endpoint is opt-in, not auto-detected.** `EmbeddingsOllama` never silently falls
   back to `/api/embed` if `/api/embeddings` fails, or vice versa. The endpoint is fixed at
   construction via `use_legacy_endpoint`. Auto-detection by probing both endpoints is
   explicitly forbidden (it creates unpredictable behavior and masks misconfiguration).
2. {INV-002} **rustls-tls unconditional for localhost.** The 30-second timeout and rustls-tls apply even
   when `base_url` is `localhost` or `127.0.0.1`, per DI-009 / BC-2.14.004 (workspace-wide
   30s HTTP timeout invariant). There is no `if localhost { skip_tls }` branch.
   This is consistent with the workspace convention: reqwest configuration is uniform, not
   environment-conditional.
3. {INV-003} **Batch DI-014 compliance for legacy endpoint.** When `use_legacy_endpoint: true` and a
   batch of N texts is submitted, if any of the N serial requests fails, the error propagates
   immediately as `Err(...)` for the whole `embed_documents` call. Already-received embeddings
   are NOT returned as a partial list.
4. {INV-004} `EmbeddingsOllama` is `Send + Sync` — the `reqwest::Client` is `Clone + Send + Sync`.
5. {INV-005} `use_legacy_endpoint` is immutable after construction — it cannot be changed at runtime.
   Callers needing both endpoints construct two separate `EmbeddingsOllama` instances.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `use_legacy_endpoint: false`, Ollama binary predates `/api/embed` (returns 404) | `Err(PregolyaError { code: "E-PROV-008", .. })` — `ProviderHttpError: provider returned HTTP 404`; no silent fallback to `/api/embeddings` |
| EC-002 | `use_legacy_endpoint: true`, batch of 5 texts; 3rd request returns 500 | `Err(PregolyaError { code: "E-PROV-008", .. })` — `ProviderHttpError: provider returned HTTP 500`; first 2 embeddings discarded; Err for whole call |
| EC-003 | Ollama process not running (connection refused) | `Err(PregolyaError { component: PROV, category: TRANSPORT, code: E-PROV-012, message: "ProviderConnectionError: cannot connect to provider 'http://localhost:11434': connection refused", .. })` — no retry; reqwest OS-level error is in `.source()`. This is the authoritative full-form gate #33 site for E-PROV-012; any future TV for this failure path PASS-ABBREVs via this EC-003. |
| EC-004 | Model not pulled locally (Ollama returns 404 with body `"model not found"`) | `Err(PregolyaError { code: "E-PROV-008", .. })` — `ProviderHttpError: provider returned HTTP 404`; body/model context in `.source()` chain if safe to surface |
| EC-005 | Request takes > 30 seconds (slow local model, reqwest `.timeout(30s)` fires) | `Err(PregolyaError { code: "E-PROV-012", .. })` — `ProviderConnectionError: cannot connect to provider '<base_url>': connection timed out`; 30s applies even for localhost |
| EC-006 | `embed_documents(vec![])` with legacy endpoint | `Ok(vec![])` — zero requests sent; not an error |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `embed_documents(vec!["hello"])` with `use_legacy_endpoint: false`, mock `/api/embed` returning 768-dim vector | `Ok(vec![[f32; 768]])` | happy-path (default endpoint) |
| TV-002 | `embed_query("hello")` with `use_legacy_endpoint: false` | `Ok([f32; 768])` | happy-path (default endpoint, single query) |
| TV-003 | `embed_documents(vec!["hello"])` with `use_legacy_endpoint: true`, mock `/api/embeddings` | `Ok(vec![[f32; 768]])` | happy-path (legacy endpoint) |
| TV-004 | `use_legacy_endpoint: false`; Ollama returns 404 for `/api/embed` | `Err(PregolyaError { code: "E-PROV-008", .. })` — no fallback to `/api/embeddings` | error-case (no auto-fallback, E-PROV-008) |
| TV-005 | `use_legacy_endpoint: true`; 2-text batch; second request returns 500 | `Err(PregolyaError { .. })` — first embedding discarded | error-case (DI-014 partial-failure) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.22.003-A | `use_legacy_endpoint: false` sends exactly one `/api/embed` request regardless of batch size | unit test with mock HTTP server — assert single request for batch of 5 |
| VP-2.22.003-B | `use_legacy_endpoint: true` sends exactly N serial `/api/embeddings` requests for N texts | unit test with mock HTTP server — assert request count |
| VP-2.22.003-C | No auto-fallback: a 404 on `/api/embed` does not trigger a request to `/api/embeddings` | unit test — mock `/api/embed` as 404; assert no request to `/api/embeddings` |

## Related BCs

- BC-2.22.001 — depends on: EmbeddingsOllama implements the Embeddings trait defined in BC-2.22.001; all dimensionality-contract postconditions apply

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-22, `ollama::embeddings` module in pregolya-ollama
- `architecture/decisions/ADR-017-embeddings-trait-provider-integration.md` — Decision 3 (pregolya-ollama gains embeddings, no API key, `/api/embed` preferred, `use_legacy_endpoint` toggle for `/api/embeddings`, reqwest constraints) and v1.1 (endpoint preference and toggle details)
- `CLAUDE.md` §Code Conventions — `reqwest TLS backend — rustls-tls mandatory`, `HTTP client timeout`

## Story Anchor

S-2.09

## VP Anchors

- VP-2.22.003-A, VP-2.22.003-B, VP-2.22.003-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-033 |
| Capability Anchor Justification | CAP-033 ("EmbeddingsOllama — Model-Configurable; /api/embed (Default); use_legacy_endpoint Toggle; No API Key") per capabilities-p1-p2.md §CAP-033 — this BC specifies the EmbeddingsOllama implementation with no-API-key local deployment, POST /api/embed preferred endpoint with use_legacy_endpoint toggle for /api/embeddings, reqwest/rustls-tls/30s unconditional (including localhost), and DI-014 batch partial-failure semantics that CAP-033 defines as a BC surface distinct from EmbeddingsOpenAI |
| L2 Domain Invariants | DI-008 (embed_documents/embed_query return Result; no .unwrap()), DI-009 (reqwest client built with .timeout(Duration::from_secs(30)) — unconditional including localhost; per BC-2.14.004), DI-014 (legacy endpoint batch partial-failure propagates as Err for entire call; already-received embeddings are NOT returned as partial list) |
| Architecture Authority | ADR-017 Decision 3 and v1.1 (pregolya-ollama scope, /api/embed preferred, use_legacy_endpoint, no API key, reqwest constraints) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-ollama / ollama::embeddings |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (mock HTTP server — endpoint selection, batch serialization, no auto-fallback) |
