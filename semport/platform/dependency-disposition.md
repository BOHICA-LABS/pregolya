---
artifact: semport/platform/dependency-disposition
project: ferrochain
port_target: langgraph-sdk @ 1.2.9 + langgraph-cli @ 1.2.9
analyzer_pass: 6
date: 2026-07-12
note: per D5 — MAP (use a Rust crate) / PORT (reimplement in ferrochain) / DROP (out of
      scope) / DEFER (later wave). Covers both packages. Consistent with
      semport/partners/dependency-disposition.md (reqwest+rustls, backon, tokio patterns).
---

# Platform SDK + CLI — Dependency Disposition (D5)

## 1. SDK runtime dependencies

| Python dep | Version | Role | Disposition | Rust target |
|---|---|---|---|---|
| `httpx` | >=0.25.2 | async+sync HTTP + ASGI transport | **MAP** | `reqwest` (default-features=false, rustls-tls, per CLAUDE.md) |
| `orjson` | >=3.11.5 | fast JSON encode/decode (off-thread) | **MAP** | `serde_json` (+ `simd-json` if bench-justified) |
| `websockets` | >=14,<17 | v3 WS transport | **MAP / DEFER** | `tokio-tungstenite` — DEFER with v3 |
| `langchain-protocol` | >=0.0.15 | v3 `Event`/`SubscribeParams` types | **PORT / DEFER** | ferrochain protocol types — DEFER with v3 |
| `langchain-core` | >=1.4.0,<2 | v3 message projections (`AsyncChatModelStream`/`ChatModelStream` in `_async/stream.py` and `_sync/stream.py`) — RemoteGraph is NOT in sdk-py <!-- [validation-exhaustive: prior "mostly for RemoteGraph glue" was inaccurate; RemoteGraph lives in langgraph core, not sdk-py; sdk-py imports langchain-core for chat model stream types used in v3 message projection] --> | **PORT** (already in scope) | `ferrochain-core` |

Notable ABSENCES vs the partner crates: there is **no vendor SDK, no retry library, no auth
library** in the SDK's deps. Retry is httpx transport-level (`retries=5`) + the SSE reconnect
loop; auth is a bare header. This makes the SDK's transport mapping *simpler* than the
provider crates (no `backon` parity worries at the request level — though we should add
`backon` for the SSE reconnect backoff which the SDK hand-rolls with jitter).

### 1.1 In-package infrastructure to PORT (no external dep)
- **SSE decoder** (`sse.py`) — **PORT** exactly (WHATWG spec state machine). Candidate MAP:
  `eventsource-stream` / `reqwest-eventsource`, but the SDK's decoder has custom
  reconnect+Last-Event-ID+Location semantics; PORT is safer, golden-test against
  `tests/streaming/test_decoders.py`.
- **Typed error taxonomy** (`errors.py`) — **PORT** into the ferrochain error taxonomy
  (thiserror enum: `PlatformError { BadRequest, Unauthorized, Forbidden, NotFound, Conflict,
  Unprocessable, RateLimited, ServerError, Connection, Timeout }`); status→variant map is
  load-bearing.
- **Cross-origin reconnect guard** (`_validate_reconnect_location`) — **PORT** (security).
- **Path-param quoting** (`_quote_path_param`, incl. dot-segment escaping) — **PORT**
  (security; httpx-specific `.`/`..` collapse defense, must replicate for reqwest/`url`).
- **API-key resolution precedence** (`_get_api_key`) — **PORT** as a resolver
  (`LANGGRAPH → LANGSMITH → LANGCHAIN`), key wrapped in a **redacted newtype** per CLAUDE.md.

## 2. SDK server-side modules → DROP (not client surface)

| Module | Disposition | Rationale |
|---|---|---|
| `auth/` (__init__, types, exceptions) | **DROP** | deployment-author auth framework; server concern. Re-scope to a `ferrochain-server-auth` crate only IF ferrochain ships a hosted server (no product mandate). |
| `runtime.py` (`ServerRuntime`) | **DROP** | server graph-factory injection; overlaps semport/graph `Runtime`. |
| `encryption/` | **DROP** | server at-rest encryption plugin. |
| `cache.py` | **DEFER** | small client cache helper; add if perf demands. |
| `_sync/*` (all sync mirrors) | **DROP as separate code** | ferrochain is async-first; a sync facade is generated only if a port spec requires it (single source, not a parallel tree). |

## 3. SDK test-infra dependencies

| Python dep | Disposition | Rust target |
|---|---|---|
| `pytest`, `pytest-asyncio`, `pytest-mock` | **MAP** | `#[tokio::test]` + `mockito`/`wiremock` |
| streaming fake server (`tests/streaming/_fake_server.py`) | **PORT** | this IS the DTU-clone seed for P1-06 (see test-inventory §3) |
| integration stack @ localhost:2024 | **DROP for CI** | requires proprietary `langgraph-api`; replace with the DTU fake |

## 4. CLI dependencies + portability disposition (special attention #3)

| Python dep / concern | Role | Disposition |
|---|---|---|
| `click` | CLI framework | **MAP** → `clap` (derive) |
| `httpx` (host_backend) | control-plane REST | **MAP** → reqwest (but DROP the endpoints — SaaS) |
| `python-dotenv` | .env parsing | **MAP** → `dotenvy` |
| `docker` (subprocess) | image build/run | **DROP** — Docker orchestration is not a Rust library concern |
| `uv`/`pip`/`pyproject.toml`/`uv.lock` parsing (`uv_lock.py`, `dependency_tracking.py`) | Python packaging | **DROP** — Python-specific; a Rust port uses Cargo, no analog |
| GCS signed-url upload, push-token, `HostBackendClient` | LangSmith control plane | **DROP** — proprietary SaaS |
| template fetch/unpack (`templates.py`, `archive.py`) | scaffolding | **DEFER** — nice-to-have `ferrochain new` |
| `langgraph.json` schema (`schemas.py::Config`) | project config | **PORT** — the one high-value CLI artifact (see rust-translation-strategy §3) |
| config validation (`validate` cmd) | correctness | **PORT** — pairs with the schema port |

### 4.1 CLI portability verdict per command group

| Command group | Portable to Rust? | Verdict |
|---|---|---|
| `validate` | ✅ YES | PORT — pure config-schema validation; the cleanest port |
| `new` | ⚠️ PARTIAL | DEFER — template fetch/unpack is portable; template *content* is Python-graph-specific, re-author for ferrochain graphs |
| `dockerfile` | ⚠️ RE-SCOPE | Dockerfile generation is Python-packaging-bound (pip/uv install lines, langgraph-api base image). A ferrochain equivalent would generate a Rust-binary Dockerfile — net-new, DEFER |
| `build` | ❌ NO (as-is) | Docker + Python-packaging; re-scope to `cargo build --release` + optional container packaging, later |
| `up` | ❌ NO | docker-compose orchestration of the proprietary stack; DROP |
| `dev` | ❌ NO | pure launcher for closed-source `langgraph-api` in-mem server; DROP. A ferrochain `dev` would launch a ferrochain server binary — net-new, gated on ferrochain shipping a server |
| `deploy` (+ list/revisions/delete/logs) | ❌ NO | fully SaaS-bound (LangSmith host backend `/v2/deployments`); DROP |

**Bottom line:** of the 7 CLI command groups, exactly **one (`validate`) is a clean port**,
one (`new`) is a partial defer, and **five are Docker/Python-packaging/SaaS-bound with no
port value** unless ferrochain adopts a hosted-server product strategy. The CLI's genuine
reusable IP is the `langgraph.json` schema + validation (~2,500 LOC of `schemas.py` +
`config.py` validation), which ports to a `ferrochain-cli validate` + a project-config
schema. The remaining ~5,900 LOC (deploy, uv_lock, docker, host_backend) is out of scope.

## 5. RemoteGraph disposition (langgraph core, consumes SDK)

| Concern | Disposition |
|---|---|
| `RemoteGraph(PregelProtocol)` drop-in | **DEFER / conditional PORT** — only if "call a remote ferrochain server as a local graph" becomes a goal. Depends on a `ferrochain-platform-client` crate + a hosted server. Gated on the same server-vs-library decision as D9/D11. |
| config sanitization (`_sanitize_config_value`) | PORT-with-RemoteGraph |
| SDK-StreamPart → local StreamMode mapping | PORT-with-RemoteGraph |

## 6. API-churn / conformance risk feed to DTU assessment (special attention #5)

**Risk: HIGH — the LangGraph Platform is a proprietary SaaS with no public versioned spec.**

- **No pinnable contract.** There is no published OpenAPI schema versioned to 1.2.9. The
  SDK source at tag 1.2.9 is the *only* artifact we can pin. Server behavior can (and per
  the docstrings, does) drift: `search` `response_format` default is documented to flip;
  `checkpoint_during`→`durability` migration; version-gated fields ("available for
  langgraph-api server version>=0.0.45", "Added in Agent Server version 0.9.0"). The client
  and server version independently.
- **Licensing gates.** Crons "not supported on all licenses" — some endpoints only exist on
  some tiers. A conformance run against the real service is tier-dependent.
- **What "conformance" means for a client of an unpinnable service:** conformance CANNOT
  mean "matches the live LangGraph Platform" (we can't pin it, and it's proprietary). It
  must mean **"matches the SDK-at-1.2.9 request/response contract"** — i.e., the ferrochain
  client, given the same inputs, emits byte-equivalent requests and correctly parses the
  1.2.9 response shapes. The **DTU clone (a stateful fake seeded from the local engine) is
  the conformance oracle**, not the SaaS. This decouples ferrochain's client conformance
  from LangSmith's release cadence.
- **Recommendation to the DTU/architect track:** (a) treat the 1.2.9 SDK source as a frozen
  contract snapshot, version it in reference-manifest; (b) build the DTU clone as a stateful
  fake (§4 module-inventory), NOT a request-echo; (c) scope conformance to REST+v1/v2 SSE,
  DEFER v3; (d) do NOT attempt live-SaaS conformance — flag it as out of scope with the
  churn+licensing rationale; (e) if a hosted ferrochain server is ever built, ITS API
  becomes the contract and the SDK becomes a design reference, not a spec to match.

## 7. Disposition summary

| Bucket | Items |
|---|---|
| **MAP** | httpx→reqwest, orjson→serde_json, websockets→tokio-tungstenite(defer), click→clap, dotenv→dotenvy |
| **PORT** | SSE decoder, error taxonomy, origin guard, path-quote, api-key resolver, langgraph.json schema + validate |
| **DROP** | auth/, runtime.py, encryption/, sync mirrors, deploy/host_backend, uv_lock, docker orchestration, up/dev/build/deploy commands, analytics |
| **DEFER** | v3 stream subsystem (+langchain-protocol, websockets), RemoteGraph drop-in, cache.py, `new`/`dockerfile` re-scope |

## 8. State checkpoint
```yaml
pass: 6
artifact: dependency-disposition
status: complete
cli_command_groups_portable: 1of7 (validate)
api_churn_risk: HIGH (proprietary, unpinnable)
conformance_oracle: DTU-stateful-fake (not live SaaS)
timestamp: 2026-07-12
```
