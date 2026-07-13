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

## State Checkpoint
```yaml
pass: A1
scope: dependency-disposition
status: complete
timestamp: 2026-07-13
```
