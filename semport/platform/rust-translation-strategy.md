---
artifact: semport/platform/rust-translation-strategy
project: pregolya
port_target: langgraph-sdk @ 1.2.9 + langgraph-cli @ 1.2.9 → pregolya-platform-client (+ pregolya-cli)
analyzer_pass: 6
date: 2026-07-12
note: strategy only — NO Rust code committed; signatures are illustrative sketches.
consistency: aligns with semport/partners/rust-translation-strategy.md §1 (the
      pregolya-partner-http direct-HTTP pattern applies here) and semport/graph
      rust-translation-strategy.md §7 (RemotePregil+SDK marked DEFER/maybe-DROP) and D11
      (hybrid execution, Rust-native checkpoint format).
difficulty: 🟢 easy · 🟡 moderate · 🟠 hard · 🔴 research-grade
---

# LangGraph Platform SDK + CLI → Rust — Translation Strategy

## 0. Framing: is this even in the near-term port?

Per semport/graph §7 the SDK/RemotePregel row is **DEFER / maybe DROP**. This strategy
therefore presents the shape *if/when* built, and — more importantly — establishes the
**scope boundary** so downstream planning doesn't over-invest. Two independent artifacts:
1. `pregolya-platform-client` — a Rust client for a LangGraph-Server-compatible API. Only
   valuable if pregolya (a) wants interop with existing LangGraph deployments, or (b)
   ships its own hosted server that this client talks to. **Gated on D9/D11 server decision.**
2. `pregolya-cli` — a project CLI. Only the `validate` + config-schema slice ports; the
   rest is Docker/Python-packaging/SaaS (dependency-disposition §4.1). **Small, optional.**

Neither is on the critical path (D7: core → graph → partners). Recommend both as **late
waves, explicitly gated**.

## 1. `pregolya-platform-client` shape — 🟠

### 1.1 Reuse pregolya-partner-http (the key consistency win)
The SDK's transport needs are a SUBSET of what `pregolya-partner-http` (semport/partners
§1) already provides: rustls reqwest client, 30s (here: long-read override) timeout,
credential newtype, SSE streaming, typed error mapping. The platform client should **depend
on `pregolya-partner-http`**, not re-implement transport. Divergences to add there or
layer on top:
- **read timeout override**: the SDK uses `read=300s` for long runs; expose a per-request
  timeout override (pregolya default 30s must NOT apply to `runs.wait`/`join`/stream).
- **SSE reconnect with Last-Event-ID + Location follow + cross-origin guard** — richer than
  the provider SSE (which never reconnects mid-stream). Add as a `resumable_sse` mode.
- **`request_reconnect`** (Location-follow long-poll) — a distinct helper.

```rust
// illustrative sketch
pub struct PlatformClient { http: ProviderClient /* from pregolya-partner-http */, base_url: Url }
impl PlatformClient {
    pub fn assistants(&self) -> Assistants<'_>;
    pub fn threads(&self) -> Threads<'_>;
    pub fn runs(&self) -> Runs<'_>;
    pub fn crons(&self) -> Crons<'_>;
    pub fn store(&self) -> Store<'_>;
}
```

### 1.2 Credential + resolver — 🟢
`LangGraphApiKey(String)` redacted-`Debug` newtype (CLAUDE.md). Resolver replicating
`LANGGRAPH_API_KEY → LANGSMITH_API_KEY → LANGCHAIN_API_KEY` precedence, `NOT_PROVIDED` vs
`None` distinction becomes `Option<Option<...>>` or a small `ApiKeyArg` enum
(`Explicit(key) | Disabled | FromEnv`). Reserved-header guard on `x-api-key`.

### 1.3 Wire DTOs — 🟡
Direct serde translation of `schema.py` TypedDicts → `#[derive(Serialize, Deserialize)]`
structs, `#[non_exhaustive]` per CLAUDE.md. Literals → serde-tagged enums. Sparse payloads:
use `#[serde(skip_serializing_if = "Option::is_none")]` to reproduce the "only non-None
fields sent" behavior — golden-test request bodies against captured fixtures. `Input`/
`Context` polymorphic aliases → `serde_json::Value` at the boundary. Header side-channels
(`X-Pagination-Next`, `Content-Location`, `Location`, `Prefer: return=minimal`) modeled
explicitly as response-header reads / request-header writes.

### 1.4 Resource clients — 🟡
Five modules mirroring §2 endpoint catalog. Each method = one `async fn` returning a typed
DTO or a `BoxStream`. Async-only (drop the sync tree; sync facade via `block_on` only if a
port spec demands). `on_run_created`/`on_response` callbacks → return the parsed metadata in
the result type or accept an `impl Fn` hook.

### 1.5 v1/v2 SSE streaming — 🟠
PORT `sse.py` as a `SseDecoder` (WHATWG state machine) + incremental `BytesLineDecoder`.
`Stream<Item = Result<StreamPart, PlatformError>>`. The reconnect loop (Last-Event-ID,
Location-follow, `max_reconnect_attempts=5`, content-type check, cross-origin guard) is the
tricky part — golden-test against `tests/streaming/test_transport_http.py` +
`assert_transport_replays.py`. `_sse_to_v2_dict` (pipe-split `type|ns...`, `__interrupt__`
pop) → a pure fn. 9 `StreamMode`s as an enum aligned with the local engine's stream modes
(semport/graph §6.6).

### 1.6 v3 thread-centric streaming — 🔴 DEFER
The `stream/` subsystem (controller/decoders/transport, 2,210 LOC <!-- [validation-certification-11]: corrected from ~2,000; find stream/ -name "*.py" | xargs wc -l = 2,210 -->) + `langchain-protocol`
event grammar + WebSocket transport. This parallels the local engine's v3 StreamTransformer
which semport/graph §6.6 already marked 🔴 DEFER. **Inherit the DEFER.** If built later:
`tokio-tungstenite` for WS, a `StreamController` actor (subscription registry, filter-union
rotation, LRU dedup, seq-cursor `since` reconnect, bounded-mpsc fan-out, backoff+jitter),
per-channel decoders as state machines. This is the single hardest piece and has no
near-term product justification.

### 1.7 Error taxonomy — 🟡
PORT `errors.py` status→variant map into the pregolya error taxonomy
(`.factory/specs/prd-supplements/error-taxonomy.md` at Phase 1). thiserror enum; capture
`x-request-id`; best-effort body message extraction (`message`/`detail`/`error`/nested
`error.message`). No `unwrap`.

## 2. RemoteGraph drop-in — 🟠 DEFER (conditional)
IF the "remote graph as local graph" pattern is wanted: a `RemoteGraph` type in
`pregolya-graph` implementing the same `Runnable`/graph trait the local `Pregel` exposes,
delegating to `pregolya-platform-client`. Mirrors `langgraph.pregel.remote.RemoteGraph`:
- implement `invoke/stream/stream_events/get_state/get_state_history/update_state/get_graph`
  by mapping to `runs.wait/stream`, `threads.get_state/get_history/update_state`,
  `assistants.get_graph`.
- config sanitization (`_sanitize_config_value`) → recursive primitive filter.
- SDK-StreamPart → local stream-mode output; `__interrupt__` → `GraphInterrupt` equivalent.
Gated on: (a) `pregolya-platform-client` existing, (b) the D9/D11 server strategy. This is
the ONLY platform component with a clean parity argument to the local engine — but still a
late, optional wave.

## 3. `pregolya-cli` — the portable slice only — 🟢/🟡

Port **only** `validate` + the `langgraph.json` schema. Everything else (dependency-
disposition §4.1) is DROP/DEFER.

### 3.1 Project config schema — 🟡
The `schemas.Config` TypedDict → a pregolya project-config struct (name TBD:
`pregolya.toml` preferred over JSON for Rust ecosystem fit; support both via serde).
Fields that survive the port: `graphs` (`{id: "crate::path::to::graph"}` — Rust path, not
`module:attr`), `env`, `store`, `checkpointer` (ties to D11 Rust-native checkpoint format),
`dependencies` (→ Cargo, likely dropped or repurposed). Fields that DON'T port:
`python_version`, `node_version`, `pip_config_file`, `pip_installer`, `dockerfile_lines`,
`uv` source — Python/packaging-specific. `auth`/`http`/`webhooks`/`ui` port only if a
hosted server exists.

```rust
// illustrative sketch — pregolya project config
#[derive(Deserialize)] #[non_exhaustive]
pub struct PregolyaConfig {
    pub graphs: BTreeMap<String, String>,     // id -> "crate::module::GRAPH"
    #[serde(default)] pub env: EnvSpec,        // map | path
    #[serde(default)] pub store: Option<StoreConfig>,
    #[serde(default)] pub checkpointer: Option<CheckpointerConfig>, // D11 Rust-native
    // http/auth/webhooks/ui: only if hosted-server product path
}
```

### 3.2 `validate` command — 🟢
`clap` subcommand: parse config, validate against the schema, report unknown keys (mirror
`get_unknown_keys` warning behavior), count graphs. Clean, high-value, low-risk.

### 3.3 `new` (template scaffolding) — 🟡 DEFER
Portable mechanism (fetch tarball, unpack) but template *content* must be re-authored for
pregolya graph crates. DEFER to a DX wave.

### 3.4 Everything else — DROP
`up`/`dev`/`build`/`dockerfile`/`deploy` are Docker/Python-packaging/SaaS-bound. A future
pregolya `dev`/`serve` command would launch a pregolya server binary (net-new, gated on
the hosted-server decision), NOT a port of these.

## 4. Difficulty / risk summary

| Subsystem | Difficulty | Disposition | Primary risk |
|---|---|---|---|
| pregolya-partner-http reuse for transport | 🟢 | build-on | read-timeout override for long runs |
| credential + resolver | 🟢 | PORT | env precedence + reserved-header guard |
| wire DTOs (serde) | 🟡 | PORT | sparse-payload fidelity; header side-channels |
| resource clients (5) | 🟡 | PORT | endpoint parity vs §2 catalog |
| v1/v2 SSE + reconnect | 🟠 | PORT | Last-Event-ID/Location/cross-origin reconnect fidelity |
| error taxonomy | 🟡 | PORT | status→variant map |
| v3 stream subsystem | 🔴 | DEFER | evolving protocol; langchain-protocol grammar; WS |
| RemoteGraph drop-in | 🟠 | DEFER | gated on server strategy + platform-client |
| pregolya.toml schema | 🟡 | PORT | which fields survive Python→Rust |
| `validate` cmd | 🟢 | PORT | — |
| CLI up/dev/build/deploy | — | DROP | Docker/packaging/SaaS, no port value |

## 5. Top open design questions (feeds architect / P1-06)

1. **Build the platform client at all?** Gated on D9/D11: is there a hosted pregolya
   server, or interop-with-LangGraph-deployments demand? If neither, DROP entirely — this is
   the biggest scope lever.
2. **Conformance oracle** (dependency-disposition §6): confirm DTU = stateful fake seeded
   from the local engine, NOT live SaaS. Scope conformance to REST + v1/v2 SSE; DEFER v3.
3. **Transport crate boundary**: does `pregolya-partner-http` grow the resumable-SSE +
   Location-follow + long-read-timeout features, or does a `pregolya-platform-transport`
   layer sit on top? (Recommend: extend partner-http; the SSE reconnect is reusable.)
4. **`pregolya.toml` vs `pregolya.json`**: config format + which `langgraph.json` fields
   survive the Python→Rust translation (§3.1). Ties to D11 checkpointer config.
5. **RemoteGraph parity depth**: if built, full `PregelProtocol` surface or a reduced
   invoke/stream/get_state subset? (Recommend reduced-first, gated.)

## 6. State checkpoint
```yaml
pass: 6
artifact: rust-translation-strategy
status: complete
platform_client_disposition: DEFER-gated-on-server-strategy
cli_portable_slice: validate + config-schema only
v3_streaming: DEFER (inherits graph §6.6)
timestamp: 2026-07-12
```
