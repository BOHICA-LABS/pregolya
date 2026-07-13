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
| livekit-api | 0.4.18, `default-features = false`, `["signal-client-tokio","services-tokio","access-token"]` | — | LiveKit control plane. | <!-- [comparative-sweep] workspace Cargo.toml has `default-features = false` for livekit-api; Cargo.lock resolves to 0.4.24 (semver minor bump from the 0.4.18 constraint) -->

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

---

# Pass A4 — SAFETY / QUALITY cluster dependency disposition

D16 Rust-blindness: adk's choices are INFORMATIVE input to ferrochain MAP decisions, not evidence
for adoption. Cross-refs P-47..P-66.

## Isolation / sandbox dependencies
| Dep | adk crate | Purpose | ferrochain relevance |
|-----|-----------|---------|----------------------|
| `wasmtime` 45 + `wasmtime-wasi` 44 | adk-sandbox (feature `wasm`), adk-code (wasm_guest) | In-process WASM isolation | STRONGEST isolation primitive in corpus (P-47). If ferrochain wants a default-isolating code backend, WASM (wasmtime) is the reference. Heavy dep; feature-gate it. |
| `bollard` 0.18 | adk-sandbox (feature `workspace-docker`), adk-code (feature `docker`) | Docker container exec | Container isolation (opt-in). Pulls Docker daemon dependency at runtime. |
| `tempfile` 3 | adk-sandbox, adk-code | Temp dirs for source/binary | Fine; ferrochain uses same pattern. |
| `windows-sys` 0.59 | adk-sandbox (feature `sandbox-windows`) | AppContainer Win32 APIs | Platform enforcer; ferrochain Windows sandbox would need equivalent. |
| `boa_engine` 0.20 | adk-code (feature `embedded-js`) | Embedded JS interpreter | Alternative to Node subprocess; pure-Rust JS. Optional. |
| (external binaries) `bwrap`, `sandbox-exec` | adk-sandbox OS enforcers | Runtime-probed, not deps | NOTE: Linux/macOS enforcers depend on external binaries present at runtime — not a cargo dep but a deploy-time requirement. ferrochain must handle absence gracefully (adk does, via `probe()`). |

## Eval / quality dependencies
| Dep | adk crate | Purpose | ferrochain relevance |
|-----|-----------|---------|----------------------|
| `quick-xml` 0.37 | adk-eval (feature `ci-helpers`) | JUnit XML output | Reference for CI-integration of holdout results. |
| `statrs` 0.18 | adk-eval (feature `statistics`) | Wilcoxon signed-rank for A/B | Reference for statistically-grounded regression detection (Domain B quality gates). |
| `proptest` (dev) | adk-eval, adk-code, adk-sandbox, adk-retry-reflect | Property tests | Aligns with ferrochain VP/property-test discipline (Phase 6). |

## Skill / plugin / browser dependencies
| Dep | adk crate | Purpose | ferrochain relevance |
|-----|-----------|---------|----------------------|
| `serde_yaml` 0.9 | adk-skill | Skill frontmatter parsing | serde_yaml is UNMAINTAINED upstream (archived). If ferrochain adopts a SKILL.md model, prefer a maintained YAML crate (e.g. `serde_yml`/`yaml-rust2`). (MED) |
| `walkdir` 2.5 | adk-skill | Skill discovery tree walk | Fine. |
| `sha2` 0.10 | adk-skill | Content-addressed skill IDs | Reuse for content-hash identity. |
| `regex` | adk-guardrail | Keyword/PII patterns | Fine; note ReDoS surface if patterns are user-supplied (adk's are static). |
| `jsonschema` 0.45 (feature `schema`) | adk-guardrail | Output schema validation | Reference for schema-guardrail; aligns with D5 schemars direction. |
| `thirtyfour` 0.35 | adk-browser | WebDriver client | Browser automation via WebDriver (Selenium). Out of ferrochain's declared scope; noted. NO reqwest in this crate. |
| `base64` 0.22, `url` 2.5 | adk-browser | Screenshot encoding, URL handling | Standard. |

## Open items resolved (A4, in-cluster)
1. **anyhow — RESOLVED (clean).** Grep across all eight cluster crates' `src/` = ONE hit, a
   `///` doc-comment example (`anyhow::Result`) in `adk-browser/src/lib.rs`. NO public-signature
   leak anywhere in the cluster. (This complements A3's "confined to binaries" finding; the
   remaining anyhow check is the core-crate grep, outside this cluster.)
2. **reqwest — N/A in cluster.** ZERO `reqwest` occurrences; adk-browser uses `thirtyfour`
   (WebDriver), the other seven crates make no outbound HTTP. The A3 no-timeout gap does not extend
   to this cluster.

## Summary of MAP-relevant flags added by A4
1. **`wasmtime` is the reference isolation dep** (P-47) — feature-gate, but it is the default-safe
   code-exec backend ferrochain should consider. (INFO/HIGH)
2. **`serde_yaml` is unmaintained** — if ferrochain adopts SKILL.md parsing, choose a maintained
   YAML crate. (MED)
3. **OS sandbox enforcers depend on external runtime binaries** (`bwrap`/`sandbox-exec`), probed not
   linked — ferrochain must probe + degrade gracefully. (INFO)
4. **`statrs` (Wilcoxon) + `quick-xml` (JUnit)** — good references for statistically-grounded,
   CI-integrated holdout evaluation (Domain B). (INFO)
5. **No credential/secret deps in cluster** — guardrail PII redaction is regex-only, not a
   secrets-management dep. (INFO)

## State Checkpoint
```yaml
pass: A4
scope: dependency-disposition (safety/quality cluster)
status: complete
open_items_resolved: [anyhow-in-cluster (clean, doc-example only), reqwest-in-cluster (none)]
new_flags: [wasmtime-reference-isolation, serde_yaml-unmaintained, os-enforcer-external-binaries]
timestamp: 2026-07-13
```

---

# Pass A5 — PROVIDER / CAPABILITY cluster dependency disposition

Records the provider/capability cluster's dependency choices and delivers the **FINAL workspace
anyhow verdict** (A1 open item P-18). D16 Rust-blindness — informative to ferrochain MAP, not
adoption evidence.

## FINAL anyhow-in-public-signatures verdict (A1 P-18 — CLOSED across all clusters)

Combining A2 (state cluster: clean), A3 (server cluster: confined to binaries), A4 (safety cluster:
doc-example only), and this A5 sweep of the provider/capability + core crates:

| Crate group | anyhow in library public signature? | Evidence |
|-------------|-------------------------------------|----------|
| `adk-core` | **NO** | `src` has zero `anyhow::` references; `AdkError` is the hand-written envelope (P-01) |
| `adk-model` | **NO (dead dep)** | declares `anyhow` in Cargo.toml but `src` never references it |
| `adk-anthropic`, `adk-gemini`, `adk-rag`, `adk-audio`, `adk-payments`, `adk-action`, `adk-bench`, `adk-rust-macros` | **NO** | zero `anyhow` in Cargo.toml AND src |
| `adk-mistralrs` | **YES — ONE variant** | `MistralRsError::Other(#[from] anyhow::Error)` (error.rs:277); the rest are `//!` doctest examples (lib.rs:36, multimodel.rs:13) |
| binaries (`adk-cli`, `cargo-adk`, `adk-deploy`) | binary-only (permitted) | A3 finding |

**VERDICT: anyhow is NOT a systemic library leak.** The structured-`AdkError` investment (P-01) is
intact across the entire library surface with a SINGLE exception — the `Other(#[from] anyhow::Error)`
catch-all variant on `adk-mistralrs`'s public error enum (P-78). This substantially downgrades A1's
P-18 WEAK concern: the fear was "anyhow erases component/category at library boundaries workspace-wide";
the reality is one localized escape-hatch variant in the local-inference crate + one dead Cargo.toml
entry in adk-model. Ferrochain forbids even the single `Other(anyhow)` variant on a public error enum;
otherwise adk-rust's structured-error discipline is a positive reference. (RESOLVED — GAP is one variant.)

## Provider HTTP / SDK dependencies
| Dep | Where | Notes for ferrochain MAP |
|-----|-------|--------------------------|
| `adk-anthropic` (workspace, in-tree) | `adk-model` optional `dep:adk-anthropic` | Standalone Anthropic SDK, ZERO adk deps; reqwest(rustls-native-roots)/bytes/base64/url/time/hmac/sha2. The adapter wraps it (P-67). Publishable independently. |
| `adk-gemini` (workspace, in-tree) | `adk-model` default `dep:adk-gemini` | Standalone Gemini SDK, zero-adk-dep; `vertex`/`interactions` features. |
| `async-openai 0.33` | `adk-model` `openai` feature | External OpenAI SDK, `default-features = false, features = ["rustls","chat-completion","responses"]` — rustls, good. |
| `ollama-rs 0.3.4` | `adk-model` `ollama` feature | `default-features = false, features = ["stream"]`. Owns its own client + timeout; does NOT wire the shared retry (P-71 exception). Our Ollama-analog reference. |
| `aws-sdk-bedrockruntime 1.128` | `adk-model` `bedrock` feature | `default-features = false`, `default-https-client` + `rt-tokio`. AWS SDK owns transport. | <!-- [comparative-sweep] added missing default-features=false; verbatim adk-model/Cargo.toml: `{ version = "1.128", optional = true, default-features = false, features = ["default-https-client", "rt-tokio"] }` -->
| `schemars 1.0` | `adk-model` OPTIONAL (`ollama` feature) + `adk-rust-macros` dev-dep | Used by the `#[tool]` macro + ollama structured output; providers hand-roll otherwise (P-75). D5 data point. |
| `mistralrs 0.8` | `adk-mistralrs` | In-process native inference (candle). Pulls `hf-hub` → `native-tls` (P-79). Accelerator features cuda/metal/mkl/… Heavy build. |

## Local-LLM story (Q4 — our Ollama plans + keyless CI)
adk-rust ships TWO local-model paths with very different weights:
- **Ollama** (`adk-model` `ollama` feature → `ollama-rs`): an HTTP client to a local Ollama daemon.
  Light dependency footprint; the daemon does inference out-of-process. Keyless (no API key). This is
  the shape ferrochain-ollama targets. Keyless-CI-friendly: the HTTP boundary is mockable (wiremock),
  and the reusable insight is the text-tag `tool_call_parser` (P-68) for Ollama models lacking native
  tool-calling. `ollama-rs` owns timeout — ferrochain would set its own.
- **mistral.rs** (`adk-mistralrs` → `mistralrs 0.8` / candle): IN-PROCESS native inference. Broad
  surface (text+vision+speech+diffusion+embedding), 50+ architectures, `publish = true`. BUT: heavy
  compile (candle + optional CUDA/Metal), model weights downloaded via `hf-hub` (→ native-tls, P-79),
  and `bench-inference` "requires model downloads." **NOT cleanly keyless-CI-friendly** — no API key,
  but real inference needs GB-scale cached weights + a heavy toolchain. Relevance to ferrochain:
  mistralrs is a reference for "native local inference as an ALTERNATIVE to an HTTP daemon," not a
  template for lightweight keyless CI. For keyless CI, the Ollama-analog (mock the HTTP boundary) is
  the better fit; mistralrs-style in-process inference would need weight-cache management and a
  native-tls resolution.

## native-tls ingress chains (extends A1's single livekit flag to THREE — MAP flag HIGH)
| Chain | Trigger | Path to native-tls |
|-------|---------|--------------------|
| LiveKit voice | `adk-realtime` `livekit` feature (optional; `full`/`heygen-avatar`) | `livekit 0.7.x` → `async-native-tls` / webrtc stack → `native-tls` |
| Local LLM weights | `adk-mistralrs` (mistralrs/candle) | `hf-hub 0.4.3` (deps incl. `native-tls`) |
| Audio ML weights | `adk-audio` `onnx`/`mlx`/`kokoro`/`qwen3-tts` features | `hf-hub 0.5` → `native-tls` |

All are OPTIONAL/feature-gated; DEFAULT builds (OpenAI/Gemini realtime over tokio-tungstenite-rustls;
adk-mistralrs/adk-audio without ML-download features) avoid native-tls. **Disposition:** any ferrochain
port of local inference or LiveKit voice inherits a native-tls conflict with the rustls-only rule; the
`hf-hub`→native-tls chain in particular gates BOTH local-LLM and audio-ML. Ferrochain must resolve via
hf-hub's rustls feature (if available) or a rustls-based model downloader. (HIGH — was A1 MED/single.)

## Credential typing (extends A3 P-44 to the whole provider stack)
| API | adk choice | Ferrochain rule | Disposition |
|-----|-----------|-----------------|-------------|
| all provider configs + SDK clients | `pub api_key: String` on `#[derive(Debug,…)]` (several also `Serialize`) | newtype + redacted `Debug` | **Divergence workspace-wide (P-76).** No redacted newtype anywhere; even `adk-anthropic::Anthropic` derives Debug over its `api_key`. Ferrochain must wrap every key. (MED→ pervasive) |

## Timeout discipline per provider (extends A3 P-42 into providers)
| Provider client | timeout? |
|-----------------|----------|
| `adk-anthropic::Anthropic` (main) | **YES** — `.timeout(DEFAULT_TIMEOUT)` + pool + keepalive (exemplar) |
| `adk-anthropic::{managed_agents,files}` sub-clients | NO (`reqwest::Client::new()`) |
| `adk-gemini` builder | NO default (`ClientBuilder::default()`; user may add) |
| `adk-model::{openai/*, openai_compatible, openrouter}` | NO (`reqwest::Client::new()` / headers-only builder) |
| `ollama-rs`, `async-openai`, aws-sdk | owned by the external crate |

**Disposition:** the anthropic MAIN client is the one production-grade exemplar; the rest are
timeout-less (P-77). Ferrochain must set `.timeout()` on every provider client — the anthropic main
client (timeout + `pool_max_idle_per_host` + `pool_idle_timeout` + `tcp_keepalive`) is the reference
construction. (HIGH)

## Summary of MAP-relevant flags added by A5
1. **anyhow FINAL VERDICT** — one leak variant (`adk-mistralrs::MistralRsError::Other`) + one dead
   dep (`adk-model`); otherwise clean library-wide. A1 P-18 CLOSED. (RESOLVED)
2. **THREE native-tls chains** (livekit + mistralrs/hf-hub + audio/hf-hub), all optional. (HIGH)
3. **Bare-String Debug-derived API keys workspace-wide** (configs + SDKs). (pervasive divergence)
4. **Uneven provider timeouts** — anthropic main client exemplary, rest timeout-less. (HIGH)
5. **schemars is optional** (tool macro + ollama only); providers hand-roll wire schema. Feeds D5.
6. **Local-LLM: Ollama (light, HTTP, keyless-CI-friendly) vs mistralrs (heavy, in-process, weight-
   download, native-tls)** — Ollama-analog is the better keyless-CI fit. (INFO)

## State Checkpoint
```yaml
pass: A5
scope: dependency-disposition (provider/capability cluster)
status: complete
a1_open_items_resolved:
  - P-18 anyhow-public-signatures — FINAL VERDICT: one variant (adk-mistralrs Other) + one dead dep (adk-model); library-wide otherwise clean
native_tls_chains: [livekit, mistralrs/hf-hub, audio/hf-hub]
timestamp: 2026-07-13
```

## Pass A7 deepening — native-tls chain reconciliation (MAP-refinement, P-93)

A7 scanned every first-party `Cargo.toml` for the literal `native-tls` feature string. Result:
**exactly one first-party explicit opt-in workspace-wide** — `livekit = { …, default-features =
false, features = ["tokio", "native-tls"] }` in the root `Cargo.toml`. The other two chains recorded
in the A5 summary (`mistralrs/hf-hub`, `audio/hf-hub`) are **TRANSITIVE** — pulled via the
`mistralrs`/`hf-hub`/`candle` stack's own default features, not declared in adk-* manifests
(`adk-mistralrs` and `adk-audio` consume the workspace `reqwest`, which is
`default-features = false, rustls-tls-native-roots` — no native-tls string). So the disposition
sharpens:

| native-tls exposure | Kind | Crates | Toggle |
|---------------------|------|--------|--------|
| `livekit` | **first-party explicit** | root Cargo.toml; used by adk-realtime (`livekit` feat), adk-audio, adk-rust aggregator | optional Cargo feature `livekit` |
| `mistralrs`/`hf-hub` | transitive (upstream default) | adk-mistralrs | optional `mistralrs` feature (weight-download crate) |
| `audio`/`hf-hub` | transitive (upstream default) | adk-audio | optional (candle/hf stack) |

**MAP consequence:** the livekit native-tls ingress is the only one a ferrochain realtime-analog
controls directly (it is livekit-the-crate's own default, not an adk design requirement) — a rustls
transport substitution is a crate-feature decision, not a rewrite. The two transitive chains would be
addressed at the upstream-dep-selection level (choosing rustls-configured forks/features of the
hf-hub/candle stack), not in adk-* code. This *clarifies* — does not contradict — the A5
`native_tls_chains: [livekit, mistralrs/hf-hub, audio/hf-hub]` entry (see ANALYSIS-STATE C4).

## State Checkpoint
```yaml
pass: A7
scope: dependency-disposition (native-tls chain reconciliation)
status: complete
finding: livekit is the sole first-party explicit native-tls opt-in; other two chains are transitive
timestamp: 2026-07-13
```
