---
artifact: comparative/adk-rust/dependency-disposition
pass: A1
constraint: D16 Rust-blindness — record their choices as INFORMATIVE input to ferrochain MAP
  decisions; do not treat "adk already chose X" as evidence for adopting X.
created: 2026-07-13
status: observe-only
---

# adk-rust — Dependency Disposition (Pass A1)

Source: workspace root `Cargo.toml` `[workspace.dependencies]` table (the authoritative
version-pin surface). This records what adk-rust chose and flags every point of
divergence from ferrochain's Code Conventions (CLAUDE.md), because those divergences are
exactly the MAP decisions ferrochain must make deliberately — not inherit.

## Toolchain baseline
- `edition = "2024"`, `resolver = "2"`, `rust-version = "1.94.0"`. Very recent MSRV
  (flagged in the manifest as not-yet-widely-deployed as of mid-2026). Ferrochain pins its
  own toolchain via `rust-toolchain.toml`; adk's 1.94 floor is aggressive.
- Release profile: `lto = true`, `opt-level = 3`, `strip = true`. A `ci` profile disables LTO;
  an `example-dev` profile maximizes codegen-units for fast example builds. Mature profile
  engineering.

## Async & core runtime
| Dep | Pin | Notes for ferrochain MAP |
|-----|-----|--------------------------|
| tokio | 1.40, `default-features = false` | Matches ferrochain's Tokio-multi-threaded, async-first convention. Default-features-off forces per-crate feature opt-in. |
| tokio-stream | 0.1 | Stream adapters. |
| async-trait | 0.1 | Every core trait is `#[async_trait]`. Ferrochain must decide async-trait vs native `async fn in trait` (stable since 1.75) — adk chose the macro (object-safety for `dyn` trait objects, which native AFIT does not yet give without extra crates). This is a genuine MAP decision, not a default. |
| futures | 0.3 | `Stream`, `StreamExt`, `join_all`. |
| async-stream | 0.3 | `stream!` macro drives Runner + agent streaming. Core to the streaming shape. |
| tokio-util | (per-crate) | `CancellationToken` for the interrupt/cancellation API in the runner. |

## Serialization
| Dep | Pin | Notes |
|-----|-----|-------|
| serde | 1.0 (derive) | Pervasive. |
| serde_json | 1.0 | `Value` is the tool arg/result lingua franca and the state value type. |
| toml | 0.8 | Config loading (AWP business context, etc.). |
| — | — | **No schemars.** adk builds JSON Schema by hand (`schema_utils`, `SchemaAdapter`). Ferrochain's D5 mandates a pydantic→serde/schemars ADR; adk's hand-rolled approach is a data point *against* assuming schemars is required, but also a maintenance-cost data point. |

## Error handling
| Dep | Pin | Notes |
|-----|-----|-------|
| thiserror | 2.0 | Available workspace-wide, but `adk-core::AdkError` is a **hand-written struct** (not `#[derive(Error)]`) to carry the component×category×retry×details envelope. Sub-crates (e.g. adk-guardrail `GuardrailError`, adk-skill `SkillError`) appear to use their own error types. |
| anyhow | 1.0 | Present workspace-wide. Ferrochain forbids `unwrap/expect` and mandates structured variants; anyhow in a *library* surface would conflict with that discipline. Deep pass must check whether anyhow leaks into public library signatures or is confined to binaries/tests. FLAG. |

## HTTP / TLS — **the sharpest divergence from ferrochain conventions**
| Dep | adk pin | Ferrochain rule | Disposition |
|-----|---------|-----------------|-------------|
| reqwest | 0.12, `default-features = false`, features `["json","stream","rustls-tls-native-roots","multipart"]` | `default-features = false, features = ["rustls-tls"]` + 30s timeout mandatory | adk correctly disables default-features (avoids native-tls) — GOOD and aligned. BUT it uses `rustls-tls-native-roots` (rustls backend reading the OS trust store) rather than `rustls-tls` (webpki-roots). Both are rustls crypto (no native-tls MITM path), so the security intent aligns; the root-store source differs. Ferrochain must consciously pick `rustls-tls` vs `-native-roots`. Timeout enforcement is per-client, not visible in the workspace table — deep pass must verify 30s timeouts. |
| rustls | 0.23, features `["aws-lc-rs"]` | (crypto provider unspecified in conventions) | adk **unifies on the `aws-lc-rs` crypto provider** workspace-wide and installs it process-wide via `adk_core::ensure_crypto_provider()` (a `std::sync::Once` that calls `aws_lc_rs::default_provider().install_default()`, ignoring the result to respect a parent app's prior choice). Clean handling of the rustls "multiple providers" footgun. Ferrochain should decide ring vs aws-lc-rs explicitly. |
| tokio-tungstenite | 0.28, `["rustls-tls-native-roots","connect"]` | — | WebSocket transport (OpenAI realtime ws_transport). rustls backend. |
| **livekit** | 0.7.36, `default-features = false`, features `["tokio","native-tls"]` | native-tls + aliases **forbidden workspace-wide** | **CONFLICT.** adk-realtime's LiveKit dependency pulls `native-tls`. Under ferrochain's convention this is a hard violation (macOS Keychain init cost + MITM interception path). If ferrochain ever ports realtime/LiveKit, this dep must be re-evaluated — LiveKit's rustls support (if any) or exclusion of the feature. FLAG for MAP. |
| livekit-api | 0.4.18, `["signal-client-tokio","services-tokio","access-token"]` | — | LiveKit control plane. |

## Observability
| Dep | Pin | Notes |
|-----|-----|-------|
| tracing | 0.1 | Structured logging throughout; `tracing::info_span!` with GCP-Vertex-style attributes in the runner (`gcp.vertex.agent.*`, `gen_ai.conversation.id`, `adk.*`). Aligned with ferrochain's tracing convention. `adk-telemetry` re-exports `warn!`/etc. as a facade (`adk_telemetry::warn!` used in adk-model::retry). |
| tracing-subscriber | 0.3 | Subscriber config. |
| opentelemetry | 0.31 | OTel export via adk-telemetry. Ferrochain's observability spec (Phase 1) should note adk uses OTel + gen_ai semantic conventions. |

## Identity / utility
| Dep | Pin | Notes |
|-----|-----|-------|
| uuid | 1.23 (v4, serde) | Event IDs, invocation IDs (`inv-{uuid}`). |
| chrono | 0.4.44 (serde) | Event timestamps (`DateTime<Utc>`), RFC-3339 in A2A. |
| regex | 1.10 | PII redaction (guardrail), parsing. |
| sha2 / hex | 0.10 / 0.4 | Content hashing (skill content-IDs, HMAC webhook signing in AWP). |
| flate2 / tar | 1.0 / 0.4 | Artifact/deploy packaging. |

## Internal dependency posture
- `adk-core`, `adk-tool`, `adk-server`, `adk-session`, and most crates take default features;
  `adk-agent`, `adk-model`, `adk-runner`, `adk-cli`, `adk-mistralrs`, `adk-managed` declare
  `default-features = false` in the workspace table — an intentional minimal-by-default
  composition model. Runner gates `artifacts`/`plugins`/`skills`/`context-compaction` behind
  features, so a lean build excludes them.

## Summary of MAP-relevant flags (for ferrochain architect, not conclusions)
1. **livekit → native-tls** is a hard conflict with ferrochain's rustls-only rule. (HIGH)
2. **reqwest `rustls-tls-native-roots` vs ferrochain's `rustls-tls`** — root-store choice diverges;
   both avoid native-tls. (MED — deliberate pick needed)
3. **anyhow present workspace-wide** — verify it does not leak into library public signatures
   (would violate ferrochain's structured-error discipline). (MED — deep-pass verify)
4. **aws-lc-rs unified crypto provider + process-wide install-once** — a clean pattern ferrochain
   could adopt for the rustls provider footgun; needs an explicit ring-vs-aws-lc-rs decision. (INFO)
5. **No schemars** — adk hand-rolls JSON Schema; informative against assuming schemars is mandatory,
   but a maintenance-cost counterpoint. (INFO — feeds D5 ADR)
6. **async-trait everywhere** — object-safety choice; ferrochain must pick async-trait vs native AFIT. (INFO)
7. **MSRV 1.94 / edition 2024** — adk rides the bleeding edge; ferrochain pins its own. (INFO)

---

# Pass A2 — cluster dependency disposition (state/persistence/orchestration)

New dependency facts observed while reading adk-graph / adk-session / adk-memory / adk-artifact.
Recorded as INFORMATIVE input to ferrochain MAP decisions (D16), not adoption evidence.

## Persistence / storage
| Dep | Where | Notes for ferrochain MAP |
|-----|-------|--------------------------|
| sqlx | adk-graph (`sqlite` feature), adk-session (postgres/sqlite/…), adk-memory | Backends use `sqlx::{SqlitePool,PgPool}` with `pool.begin()`/`tx.commit()` transactions. Ferrochain must pick sqlx vs sea-orm vs raw drivers, and decide whether graph checkpoints share the session DB layer (they don't in adk — P-27). |
| — | adk-graph checkpoint schema | Hand-rolled `CREATE TABLE graph_checkpoints (id, thread_id, state TEXT, step, pending_nodes TEXT, metadata, created_at TEXT)` + `idx(thread_id, created_at DESC)`. Whole-state JSON in a TEXT column; `created_at` string ordering (P-31). Informative anti-pattern: no monotonic sequence column. |
| serde_json | cluster-wide | State/checkpoint serialization is `serde_json::to_string` of the whole state map — no msgpack, no allowlist gate (contrast LangGraph's ormsgpack + `SAFE_MSGPACK_TYPES` RCE guard, semport/graph §2.3). Ferrochain's D5 serde/schemars ADR should note adk's plain-JSON choice AND the absence of a deserialization allowlist. |

## Cryptography (encryption-at-rest)
| Dep | Where | Notes |
|-----|-------|-------|
| aes-gcm | adk-session `encrypted.rs` | `Aes256Gcm` AEAD, `new_from_slice(&[u8;32])`. Correct AEAD choice. Ferrochain's encryption-at-rest NFR (Phase 1) — data point for AES-256-GCM vs ChaCha20-Poly1305. |
| rand (`rng().fill_bytes`) | adk-session | 96-bit nonce generation. Ferrochain must confirm a CSPRNG source; `rand::rng()` is thread-local. |
| base64 | adk-session | Envelope encoding of `[nonce‖ciphertext]`. |

## Delta / diff
| Dep | Where | Notes |
|-----|-------|-------|
| similar | adk-graph `delta.rs` (`delta-checkpoint` feature) | Character-level string diffs for `Diff for String`. Optional. Ferrochain: only relevant if a string-delta checkpoint channel is ported. |

## Time / identity
| Dep | Where | Notes |
|-----|-------|-------|
| chrono | cluster-wide | `Utc::now()` drives checkpoint `created_at` and event `timestamp` — and these are the ORDERING keys (P-31). MAP flag: ferrochain should not order history by wall-clock; use a monotonic per-thread sequence (LangGraph uses uuid6/logical versions). HIGH. |
| uuid | adk-graph | `Uuid::new_v4()` for checkpoint ids — random, not monotonic-sortable. Contrast LangGraph uuid6. MAP flag: pick uuid7/uuid6 or an explicit sequence for sortable ids. MED. |

## Async trait posture (cluster)
`Checkpointer`, `SessionService`, `MemoryService`, `ArtifactService`, `Diff`-adjacent traits are all
`#[async_trait]` `Send + Sync` object-safe — consistent with the A1 workspace-wide async-trait
choice. Reinforces the A1 async-trait-vs-native-AFIT MAP decision for ferrochain (still INFO).

## Summary of new MAP-relevant flags (cluster; for ferrochain architect, not conclusions)
1. **Wall-clock ordering of history** (checkpoint `created_at DESC`, session rewind by `timestamp`)
   — ferrochain should use a monotonic logical sequence, not `Utc::now()`. (HIGH)
2. **Plain-JSON checkpoint serialization with no deserialization allowlist** — contrast LangGraph's
   ormsgpack + `SAFE_MSGPACK_TYPES` RCE gate; feeds D5 and a security invariant. (MED)
3. **AES-256-GCM via aes-gcm crate** for at-rest state encryption — clean primitive; scope gap is
   events-not-encrypted (patterns P-32), a design decision not a dep choice. (INFO)
4. **UUIDv4 (random) checkpoint ids** vs sortable uuid6/uuid7 — pick a sortable id scheme. (MED)
5. **sqlx transactions used correctly** for session multi-table atomicity — informative positive
   for the ferrochain persistence layer's transaction discipline. (INFO)
6. **Two disjoint persistence dependency stacks** (graph checkpointer vs session service) — decide
   whether ferrochain unifies them on one storage abstraction. (INFO)

## State Checkpoint
```yaml
pass: A2
scope: dependency-disposition (state/persistence/orchestration cluster)
status: complete
timestamp: 2026-07-13
```

---

# Pass A3 — SERVER / PROTOCOL / AUTH cluster dependency disposition

Records the exposure cluster's dependency choices and RESOLVES two A1 open items
(reqwest-timeout sites; anyhow-in-public-signatures). D16 Rust-blindness — informative to
ferrochain MAP decisions; adk's choice is not evidence for adopting it.

## HTTP server & transport
| Dep | adk usage | Notes for ferrochain MAP |
|-----|-----------|--------------------------|
| axum | server framework | `Router`, `middleware::from_fn`, `DefaultBodyLimit`, extractors. `tower`/`tower-http` supply `CorsLayer`, `TimeoutLayer`, `SetResponseHeaderLayer`, `TraceLayer`. Mature HTTP stack. Ferrochain-server (D13, first-party) makes its own choice; adk is a reference for middleware composition (patterns A3 P-36). |
| tower / tower-http | middleware layers | Inbound `TimeoutLayer` (default 30s from `SecurityConfig.request_timeout`), body limit (10 MB), CORS, security headers. |
| async-stream | SSE run stream | Same `stream!` shape as the runner (A1). |

## Outbound HTTP — **RESOLVES A1 open item (reqwest timeout sites)**
| Site | Construction | Timeout? |
|------|-------------|----------|
| `adk-server::a2a::client` (RemoteA2aAgent) | `reqwest::Client::new()` ×5 | **NONE** |
| `adk-server::a2a::v1::push` (HttpPushNotificationSender) | `reqwest::Client::new()` | **NONE** (per-attempt retry/backoff, no per-request timeout) |
| `adk-auth::sso::jwks` (JWKS fetch) | `reqwest::Client::new()` | **NONE** |
| `adk-auth::sso::providers::oidc` (OIDC discovery) | `reqwest::Client::new()` | **NONE** |

Cluster-wide `grep "\.timeout("` across `adk-server`/`adk-auth`/`adk-awp`/`adk-acp`/`adk-managed`/
`adk-enterprise` `src/` → **0 hits**. Every outbound client is timeout-less; the inbound axum
`TimeoutLayer` does not bound outbound calls. **Disposition: HARD divergence from ferrochain's
mandatory-30s-timeout rule (patterns A3 P-42).** Ferrochain must set `.timeout()` on ALL outbound
clients — provider calls AND server-side push/JWKS/OIDC/remote-agent. adk is a counter-example. (HIGH)

## Error handling — **RESOLVES A1 open item (anyhow leak, this cluster)**
| Finding | Evidence | Disposition |
|---------|----------|-------------|
| `anyhow` NOT in any exposure-cluster library src | grep: 0 hits in `adk-server`/`adk-auth`/`adk-awp`/`adk-acp`/`awp-types`/`adk-telemetry`/`adk-managed`/`adk-enterprise` `src/`; declared in `adk-server`/`adk-deploy` Cargo.toml but unused in src; USED only in `adk-cli` + `cargo-adk` (binaries) | **A1 P-18 RESOLVED for this cluster** — anyhow is confined to binaries, exactly ferrochain's permitted carve-out; no library public signature leaks it. With A2's clean state-cluster finding, only the core-crate grep remains (out of scope). (RESOLVED) |
| Structured boundary errors | `A2aError`, `RequestContextError`/`AuthError`/`AccessDenied` are `thiserror`-derived; server maps `AdkError.category` → HTTP status | Aligned with ferrochain structured-error discipline. (INFO) |

## Credential handling — divergence flag
| API | adk choice | Ferrochain rule | Disposition |
|-----|-----------|-----------------|-------------|
| `SecretProvider::get_secret -> Result<String, AdkError>` | bare `String` (default Debug/Display) | newtype + redacted `Debug` mandatory | **Divergence (patterns A3 P-44).** Ferrochain's secret-service analog must return a redacted newtype. (MED) |
| Cloud secret backends | `aws-sdk-secretsmanager`/Azure Key Vault/GCP Secret Manager behind features | — | Reference for a pluggable secret-provider seam; ferrochain would wrap results in redacted newtypes. (INFO) |

## Protocol dependencies (new in this cluster)
| Dep | Crate | Role | ferrochain relevance |
|-----|-------|------|----------------------|
| `a2a-protocol-types` | adk-server::a2a::v1 | External A2A v1.0.0 wire types | A2A out of declared scope (D1 = MCP). Reference only. |
| `agent_client_protocol` | adk-acp | External ACP SDK (Zed) | ACP out of scope. |
| `awp-types` (in-workspace, zero adk deps) | adk-awp | AWP wire types | AWP out of scope; "dep-light wire-types crate" layering is the transferable idea. |
| `sha2`/`hex` | a2a push / AWP | HMAC-SHA256 webhook signing | Reference for signed-webhook delivery if ferrochain-server adds webhooks. |

## Observability
| Dep | adk usage | ferrochain relevance |
|-----|-----------|----------------------|
| `opentelemetry` (0.31) + `adk-telemetry` | `AdkSpanExporter` wired into `ServerConfig.span_exporter`; `semconv` exposes `gen_ai.*` OTel constants (request/usage/response) | adk uses OTel + gen_ai semconv end-to-end into the server. Ferrochain's observability spec (Phase 1) can reference `gen_ai.usage.*` for token telemetry. Token metering is telemetry-only — no budget gate (§16 / P-46). (INFO) |

## Summary of MAP-relevant flags added by A3
1. **Outbound reqwest clients have NO timeout cluster-wide** (a2a client/push, JWKS, OIDC). HARD
   divergence from ferrochain's 30s rule. (HIGH) — RESOLVES A1 open item.
2. **anyhow confined to binaries in this cluster** — no library-signature leak. (RESOLVED)
3. **Secrets flow as bare `String`** — divergence from newtype+redaction rule. (MED)
4. **axum + tower/tower-http middleware stack** — clean reference for ferrochain-server's inbound
   security posture (SSRF gate, security headers, request-id, body limit). (INFO)
5. **A2A/ACP/AWP each pull an external protocol dep** — all out of ferrochain's declared scope (D1). (INFO)

## State Checkpoint
```yaml
pass: A3
scope: dependency-disposition (server/protocol/auth cluster)
status: complete
a1_open_items_resolved: [reqwest-timeout-sites (GAP confirmed), anyhow-public-signatures (confined-to-binaries)]
timestamp: 2026-07-13
```
