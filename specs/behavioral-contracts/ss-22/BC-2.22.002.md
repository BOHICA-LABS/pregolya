---
document_type: behavioral-contract
level: L3
bc_id: BC-2.22.002
version: "1.5"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-22
capability: CAP-032
crate: pregolya-openai
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-008, DI-009, DI-010, DI-014]
red_gate: true
red_gate_source: "DI-010 Credential Opacity — OpenAiApiKey must implement redacted Debug that emits '<redacted>' not the key value; test must COMPILE and FAIL (revealing the key via derived Debug) before the redacted impl is written"
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-22 Embeddings; SECURITY: OpenAiApiKey credential opacity"
  - "1.1 (F-P130-09/2026-07-21): Add DI-009 to di_anchors — PC2/INV-5 specify the mandatory 30s timeout but did not cite DI-009; add BC-2.14.004 cross-reference in PC2 and INV-5 prose."
  - "1.2 (WAVE-B-B3/2026-07-29): Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon) + D-35 xtask rename (D-80). Notation: 6 CLASS3_ASCII_ELLIPSIS_VIOLATION corrected — PC6, INV-4, EC-003, EC-004, EC-005, TV-004 each had `Err(PregolyaError { ... })` — replaced `...` with `..` in all six. Xtask rename: VP-2.22.002-C `deny-client-new` → `check-client-timeout`. No behavioral change."
  - "1.3 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.09 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.4 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.5 (B-SS19-23/HIGH-provider-error-codes/2026-08-26): HIGH gap closure — provider HTTP-status error codes added. PC-006: 429/5xx→E-PROV-008, 401→E-PROV-004, connection-failure→E-PROV-012 cited. EC-003 (HTTP 429) and EC-004 (5xx): bare Err→E-PROV-008 full cite. EC-005 (timeout): bare Err→E-PROV-012. NEW EC-007: HTTP 401→E-PROV-004 ProviderAuthFailed (credential opacity per DI-010). NEW EC-008: connection refused/DNS/TLS failure→E-PROV-012. TV-004: E-PROV-008 cited. NEW TV-006: auth-failure TV (E-PROV-004). NEW TV-007: connection-refused TV (E-PROV-012). Reuses existing E-PROV-004/008/012 codes — no new E-code minted."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-032
  - architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-009
  - domain-spec/invariants.md#DI-010
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

# BC-2.22.002: EmbeddingsOpenAI — text-embedding-3-small/large/ada-002-legacy; OpenAiApiKey Redacted-Debug Credential Opacity (DI-010); reqwest/rustls-tls/.timeout(30s); Batch Partial-Failure as Err

> **Red Gate test required** — DI-010 Credential Opacity: the test that asserts
> `format!("{:?}", OpenAiApiKey("sk-test".to_string()))` == `"<redacted>"` must
> COMPILE and FAIL (producing `OpenAiApiKey("sk-test")` via derived Debug) before
> the hand-written redacted `Debug` impl is added. This prevents a regression where
> `#[derive(Debug)]` is accidentally added or the newtype wrapper is removed.

## Description

`EmbeddingsOpenAI` is a first-party `Embeddings` implementation in `pregolya-openai:
openai::embeddings`, calling the OpenAI `/v1/embeddings` endpoint. The model name is a
configurable `String` field (not an enum) to support future models without breaking changes;
the default is `"text-embedding-3-small"` (current recommended model as of crates.io/2026-07-20).
The API key is accepted as `OpenAiApiKey(String)` — a newtype with a hand-written `Debug`
implementation that emits `"<redacted>"`, never the key value (DI-010). The `reqwest::Client`
is configured with `default-features = false, features = ["rustls-tls"]` and
`.timeout(Duration::from_secs(30))` (mandatory per workspace convention). Batch partial failure
returns `Err` for the whole call, never a truncated vector (DI-014).

## Preconditions

1. {PRE-001} `EmbeddingsOpenAI` is constructed with a valid `OpenAiApiKey` and a model name.
2. {PRE-002} The `reqwest::Client` is built with `rustls-tls` and `.timeout(Duration::from_secs(30))`
   (DI-009 — 30s HTTP timeout mandatory; see BC-2.14.004 for the workspace-wide invariant).
3. {PRE-003} The OpenAI `/v1/embeddings` endpoint is reachable from the runtime environment.

## Postconditions

1. {PC-001} `embed_documents(texts)` sends a single `/v1/embeddings` request with all texts in the
   `input` field (batch semantics). Returns `Ok(vecs)` where `vecs.len() == texts.len()` and
   all vectors have the same length.
2. {PC-002} `embed_query(text)` sends a `/v1/embeddings` request with the single text in the `input`
   field. Returns `Ok(vec)` with the model's embedding dimension.
3. {PC-003} **Model names:**
   - `"text-embedding-3-small"` — default; 1536-dimensional output; recommended.
   - `"text-embedding-3-large"` — 3072-dimensional output; higher quality.
   - `"text-embedding-ada-002"` — 1536-dimensional output; legacy; still supported by OpenAI
     but superseded by the 3-series. Constructing `EmbeddingsOpenAI` with this model name
     emits a `tracing::warn!(event_type = "embeddings.legacy_model_warning")` at construction.
4. {PC-004} **Credential opacity (DI-010):**
   - `format!("{:?}", api_key)` produces `"<redacted>"` — NOT `OpenAiApiKey("sk-actual-key")`.
   - The `Debug` impl is hand-written: `impl fmt::Debug for OpenAiApiKey { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { f.write_str("<redacted>") } }`.
   - `Display` is NOT implemented on `OpenAiApiKey` — only `Debug` (redacted form).
   - `OpenAiApiKey` does NOT implement `Serialize` or `Deserialize` — the key never enters
     the lc-JSON serialization surface (`lc_secrets()` per ADR-016 if LcSerializable is added).
5. {PC-005} **HTTP client discipline:**
   - `reqwest` dep in `pregolya-openai/Cargo.toml`: `default-features = false, features = ["rustls-tls"]`.
   - `reqwest::Client` is built with `.timeout(Duration::from_secs(30))` — never `reqwest::Client::new()`.
   - The `native-tls` / `default-tls` / `native-tls-alpn` / `native-tls-vendored` features are ABSENT.
6. {PC-006} **Batch partial failure (DI-014):** if the OpenAI API returns a rate-limit error
   (HTTP 429 → E-PROV-008), service error (5xx → E-PROV-008), authentication failure
   (HTTP 401 → E-PROV-004), or connection failure (connection refused / DNS / TLS failure →
   E-PROV-012), the entire `embed_documents` call returns `Err(PregolyaError { .. })`.
   No partial vector list is returned.

## Invariants

1. {INV-001} `OpenAiApiKey` is a newtype `struct OpenAiApiKey(String)`. No `pub` field access.
   The inner `String` is accessible only through the `AsRef<str>` impl used by the HTTP
   client — it is never returned or logged elsewhere.
2. {INV-002} `EmbeddingsOpenAI` is `Send + Sync` — the `reqwest::Client` is `Clone + Send + Sync`.
3. {INV-003} The legacy `ada-002` warning is emitted once at construction — not on every API call.
4. {INV-004} Model name validation is NOT enforced at construction (the field is a free `String`) —
   an invalid model name fails at the first API call with an `Err(PregolyaError { .. })`
   from the HTTP response.
5. {INV-005} The 30-second timeout applies to each individual HTTP request (not the total batch session),
   per DI-009 / BC-2.14.004 (workspace-wide 30s HTTP timeout invariant). A provider that
   responds slowly on a large batch triggers the timeout per-request.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `OpenAiApiKey` printed via `{:?}` format | Output is exactly `"<redacted>"` — key value never appears |
| EC-002 | `EmbeddingsOpenAI` constructed with `"text-embedding-ada-002"` | `Ok(impl)` constructed; `tracing::warn!(event_type = "embeddings.legacy_model_warning")` emitted at construction |
| EC-003 | OpenAI API returns HTTP 429 (rate limit) | `Err(PregolyaError { code: "E-PROV-008", .. })` — `ProviderHttpError: provider returned HTTP 429`; whole call fails; no partial result |
| EC-004 | OpenAI API returns HTTP 5xx on second text in a batch of 10 | `Err(PregolyaError { code: "E-PROV-008", .. })` — `ProviderHttpError: provider returned HTTP <status>`; already-received vectors discarded; Err for whole call |
| EC-005 | `embed_documents` request times out (reqwest `.timeout(30s)` fires before HTTP response received) | `Err(PregolyaError { code: "E-PROV-012", .. })` — `ProviderConnectionError: cannot connect to provider 'https://api.openai.com': connection timed out`; no HTTP response received |
| EC-006 | `EmbeddingsOpenAI` used from multiple Tokio tasks concurrently | Safe — `reqwest::Client` is `Clone + Send + Sync`; `EmbeddingsOpenAI` is `Send + Sync` |
| EC-007 | OpenAI API returns HTTP 401 (invalid or revoked API key) | `Err(PregolyaError { code: "E-PROV-004", .. })` — `ProviderAuthFailed: authentication failed`; key value never appears in the error (credential opacity per DI-010) |
| EC-008 | OpenAI API endpoint unreachable (connection refused, DNS failure, TLS handshake failure) | `Err(PregolyaError { code: "E-PROV-012", .. })` — `ProviderConnectionError: cannot connect to provider 'https://api.openai.com': <transport_error>` |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 (Red Gate) | `format!("{:?}", OpenAiApiKey("sk-test-123".to_string()))` | `"<redacted>"` — NOT `OpenAiApiKey("sk-test-123")` | security (credential opacity Red Gate) |
| TV-002 | `embed_documents(vec!["hello", "world"])` with `text-embedding-3-small` mock | `Ok(vec![[f32; 1536], [f32; 1536]])` — 1536-dim vectors | happy-path |
| TV-003 | `embed_query("hello")` with `text-embedding-3-small` mock | `Ok([f32; 1536])` | happy-path (single query) |
| TV-004 | `embed_documents(vec!["a"; 3])` when mock returns HTTP 429 | `Err(PregolyaError { code: "E-PROV-008", .. })` | error-case (rate limit, E-PROV-008) |
| TV-005 | Cargo.toml: `reqwest` has `default-features = false, features = ["rustls-tls"]` | Compiles; no `native-tls` dep in dependency tree | compile-time / cargo check |
| TV-006 | `embed_documents(vec!["a"])` when mock returns HTTP 401 | `Err(PregolyaError { code: "E-PROV-004", .. })` — `ProviderAuthFailed: authentication failed`; key not in error message | error-case (auth failure, E-PROV-004) |
| TV-007 | `embed_documents(vec!["a"])` when no server is listening at the endpoint (connection refused) | `Err(PregolyaError { code: "E-PROV-012", .. })` — `ProviderConnectionError: cannot connect to provider '...': connection refused` | error-case (connection failure, E-PROV-012) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.22.002-A | `format!("{:?}", OpenAiApiKey(any_key_value))` always produces `"<redacted>"` | unit test — assert format output == "<redacted>" for multiple key values |
| VP-2.22.002-B | `reqwest` dep in `pregolya-openai` uses `default-features = false, features = ["rustls-tls"]` | `cargo tree` CI check; xtask `deny-native-tls` gate |
| VP-2.22.002-C | HTTP client is constructed with `.timeout(Duration::from_secs(30))` | unit test — assert client has timeout set (via reqwest `ClientBuilder` inspection); CI `check-client-timeout` gate |

## Related BCs

- BC-2.22.001 — depends on: EmbeddingsOpenAI implements the Embeddings trait defined in BC-2.22.001; all dimensionality-contract postconditions from BC-2.22.001 apply

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-22, `openai::embeddings` module in pregolya-openai
- `architecture/decisions/ADR-017-embeddings-trait-provider-integration.md` — Decision 3 (pregolya-openai gains embeddings, model currency, OpenAiApiKey DI-010, batch failure DI-014, reqwest constraints)
- `CLAUDE.md` §Code Conventions — `reqwest TLS backend — rustls-tls mandatory`, `HTTP client timeout`, `Newtype + redacted Debug for credentials`

## Story Anchor

S-2.09

## VP Anchors

- VP-2.22.002-A, VP-2.22.002-B, VP-2.22.002-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-032 |
| Capability Anchor Justification | CAP-032 ("EmbeddingsOpenAI — text-embedding-3-small/large; OpenAiApiKey Newtype; Batch Semantics; reqwest/rustls-tls") per capabilities-p1-p2.md §CAP-032 — this BC specifies the EmbeddingsOpenAI implementation with model currency (3-small/3-large/ada-002-legacy), OpenAiApiKey redacted-Debug credential opacity, reqwest/rustls-tls/30s HTTP constraints, and DI-014 batch partial-failure semantics that CAP-032 names as the BC surface distinct from the abstract Embeddings trait |
| L2 Domain Invariants | DI-008 (embed_documents/embed_query return Result; no .unwrap()), DI-009 (reqwest client built with .timeout(Duration::from_secs(30)) — no raw Client::new(); per BC-2.14.004), DI-010 (OpenAiApiKey redacted Debug — credential values never transit AI context or logs), DI-014 (batch partial-failure propagates as Err for entire call; no truncated result) |
| Architecture Authority | ADR-017 Decision 3 (pregolya-openai scope, model names, OpenAiApiKey, batch failure, reqwest constraints) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-openai / openai::embeddings |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (Red Gate credential opacity) + cargo check (rustls-tls dep gate) |
