---
artifact: semport/platform/behavioral-intent
project: pregolya
port_target: langgraph-sdk @ 1.2.9 (libs/sdk-py, 18,728 LOC) + langgraph-cli @ 1.2.9 (libs/cli, 8,383 LOC)
analyzer_pass: 6
date: 2026-07-12
scope: D1 "everything incl. platform clients" — the LangGraph Platform SDK client and CLI.
note: analysis only — NO Rust code committed. RemoteGraph lives in langgraph core
      (libs/langgraph/langgraph/pregel/remote.py), NOT in sdk-py; it is the SDK's
      keystone consumer and is analyzed here for the drop-in question.
consistency: aligns with semport/graph/rust-translation-strategy.md (§7 row "RemotePregel
      + SDK — proprietary Platform protocol — DEFER/maybe DROP") and
      semport/partners/rust-translation-strategy.md (§1 direct-HTTP + pregolya-partner-http
      pattern applies to the SDK transport too).
---

# LangGraph Platform SDK + CLI — Behavioral Intent

## 0. What these two packages ARE (and are not)

`langgraph-sdk` (sdk-py) is a **thin, hand-written HTTP client** for the **LangGraph
Server / LangSmith Deployment REST+streaming API**. It is NOT a graph engine — it holds
no channels, no checkpoints, no super-step loop. It is the network mirror of the local
`Pregel` interface: everything the local engine does in-process (create thread, start run,
stream super-step output, read/update state, schedule crons, read/write the cross-thread
store) is exposed here as REST calls against a remote server that runs the actual engine.

`langgraph-cli` (cli) is a **project-scaffolding, local-dev-server, Docker-build, and
deploy tool**. It is almost entirely **SaaS/Docker/Python-packaging plumbing**: it reads a
`langgraph.json` config, generates a Dockerfile, launches `docker compose`, runs an
in-memory dev server (delegated to the closed-source `langgraph-api` package), and pushes
images to the LangSmith host backend. Very little of it is portable engine logic.

The two are joined by one crucial fact for pregolya: **the SDK's REST/streaming surface
IS the de-facto specification of the proprietary LangGraph Platform**. There is no public
versioned OpenAPI contract we can pin. The SDK's request/response shapes are the closest
thing to a spec, which is why the D-decision to catalog them (feeding P1-06 DTU clone) is
sound — but see the API-churn risk in §7 and dependency-disposition §6.

## 1. SDK top-level client model

`get_client(url, api_key, headers, timeout) -> LangGraphClient` (async) and
`get_sync_client(...) -> SyncLangGraphClient`. Both wrap a single `httpx.AsyncClient` /
`httpx.Client` and expose **five sub-clients** on the top-level object:

| Sub-client | Resource | Backing REST prefix |
|---|---|---|
| `client.assistants` | versioned graph configurations | `/assistants` |
| `client.threads` | persistent multi-run state containers | `/threads` |
| `client.runs` | single graph invocations (stateful or stateless) | `/threads/{id}/runs`, `/runs` |
| `client.crons` | scheduled recurring runs | `/runs/crons`, `/threads/{id}/runs/crons` |
| `client.store` | cross-thread key/value document store | `/store` |

The sync client is a **mechanically-generated mirror** of the async one (`_async/` vs
`_sync/` directories are near-identical; a code-gen step, see `test_api_parity.py`, keeps
them in lock-step). This async/sync duality collapses to **async-only** in pregolya
(CLAUDE.md Tokio async-first; sync facade only if a port spec demands it).

### 1.1 Auth model (client side)
Auth is a **single `x-api-key` header**. Key resolution precedence
(`_shared/utilities._get_api_key`): explicit string arg → `LANGGRAPH_API_KEY` →
`LANGSMITH_API_KEY` → `LANGCHAIN_API_KEY`. `api_key=None` explicitly disables env loading;
a sentinel `NOT_PROVIDED` object distinguishes "not passed" from "explicitly None".
`x-api-key` is a **reserved header** — passing it in `headers=` raises `ValueError`. A
`User-Agent: langgraph-sdk-py/{version}` is always added. There is NO OAuth/token-refresh
on the client — the server-side `auth/` module (see §5) is a different thing entirely.

### 1.2 In-process (loopback) transport
`url=None` triggers an **ASGI in-process transport**: the client tries to import
`langgraph_api.server.app` and talk to it via `httpx.ASGITransport` with no network hop.
This is how a graph node running *inside* a deployed server calls back into its own API
(sub-agent pattern). Deferred registration via `_registered_transports` +
`configure_loopback_transports(app)` handles the case where the client is built before the
app is initialized. **pregolya analog:** a "local" client variant that dispatches to an
in-process server handler rather than reqwest — relevant only if pregolya ships a hosted
server; DEFER.

### 1.3 HTTP layer behavior (`_async/http.py`, 312 LOC — the transport crux)
`HttpClient` wraps httpx with typed error raising and orjson encode/decode:
- **encode**: `orjson.dumps` off-thread (`run_in_executor`) with `OPT_SERIALIZE_NUMPY |
  OPT_NON_STR_KEYS` and an `_orjson_default` that calls pydantic `.model_dump()`/`.dict()`
  and coerces sets→lists. Sets `Content-Length` + `Content-Type: application/json`.
- **decode**: `orjson.loads` off-thread; empty body → `None`.
- **methods**: `get/post/put/patch/delete` + two streaming specials:
  - `request_reconnect(path, method, reconnect_limit=5)` — issues a streaming request,
    and if the response carries a `Location` header, **follows it (GET) on failure** to
    reconnect to a long-poll result. Used by `runs.wait`, `runs.join`, `runs.cancel(wait)`.
  - `stream(path, method)` — the **SSE consumer** (see §3).
- **error mapping** (`errors.py`): non-2xx → typed exceptions by status: 400
  `BadRequestError`, 401 `AuthenticationError`, 403 `PermissionDeniedError`, 404
  `NotFoundError`, 409 `ConflictError`, 422 `UnprocessableEntityError`, 429
  `RateLimitError`, ≥500 `InternalServerError`; all subclass `APIStatusError <- APIError <-
  (httpx.HTTPStatusError, LangGraphError)`. Body best-effort JSON-decoded; message pulled
  from `message`/`detail`/`error` (or nested `error.message`). `x-request-id` captured.
- **timeout defaults**: `connect=5, read=300, write=300, pool=5` (note the 300s read for
  long runs — pregolya's 30s default MUST be overridden here per NFR-catalog).
- **transport retries**: `httpx.AsyncHTTPTransport(retries=5)` at the connection layer.

## 2. Resource semantics (behavioral contracts by sub-client)

### 2.1 Assistants — versioned graph configs
- `get`, `get_graph(xray)`, `get_schemas`, `get_subgraphs(namespace, recurse)` — read.
- `create(graph_id, config, context, metadata, assistant_id, if_exists, name, description)`
  — `if_exists ∈ {raise, do_nothing}`; only non-None fields are sent (sparse payload).
- `update` (PATCH, sparse), `delete(delete_threads)`.
- `search(metadata, graph_id, name, limit, offset, sort_by, sort_order, select,
  response_format)` — `response_format="object"` returns `{assistants, next}` where `next`
  comes from an **`X-Pagination-Next` response header** captured via an `on_response`
  callback; `"array"` returns a bare list. Default is `"array"` (documented to flip to
  `"object"` in future — an API-churn flag).
- `count`, `get_versions`, `set_latest(version)`.
- **Invariant:** an assistant is a `(graph_id, config, context, version)` tuple; versions
  are immutable snapshots; `set_latest` re-points the pointer.

### 2.2 Threads — persistent state containers
- CRUD: `get(include=["ttl"])`, `create(metadata, thread_id, if_exists, supersteps,
  graph_id, ttl)`, `update(metadata, ttl, return_minimal)`, `delete`, `search`, `count`,
  `copy`, `prune(thread_ids, strategy)`.
- `supersteps` on create is the **thread-copy-between-deployments** mechanism: a list of
  `{updates: [{values, command, as_node}]}` replayed to reconstruct state.
- `ttl` accepts int minutes or `{ttl, strategy}` (strategy defaults `"delete"`).
- `return_minimal=True` sends `Prefer: return=minimal` → server returns 204 (no body).
- **State ops** (the checkpoint bridge):
  - `get_state(checkpoint | checkpoint_id[deprecated], subgraphs)` — POST to
    `/state/checkpoint` when a full `Checkpoint` obj is given, else GET `/state` or
    `/state/{checkpoint_id}`.
  - `update_state(values, as_node, checkpoint)` → returns `{checkpoint}`.
  - `get_history(limit, before, metadata, checkpoint)` → `list[ThreadState]`.
- **v3 thread-centric streaming**: `stream(thread_id, assistant_id, transport)` returns an
  `AsyncThreadStream` (see §4); `join_stream(thread_id, last_event_id, stream_mode)` resumes
  a thread event feed over SSE GET `/threads/{id}/stream`.

### 2.3 Runs — the execution surface (largest, 1,190 LOC)
- `stream(...)` — POST `/threads/{id}/runs/stream` (or `/runs/stream` stateless) returning
  an **SSE iterator of `StreamPart`**. `version="v1"` yields raw `StreamPart(event, data,
  id)`; `version="v2"` wraps each via `_sse_to_v2_dict` into `{type, ns, data, interrupts}`
  (the `event` string is `type|ns1|ns2...` pipe-split into namespace path; `values` events
  pop `__interrupt__`).
- `create(...)` — POST background run, returns a `Run`. `create_batch(list[RunCreate])` —
  POST `/runs/batch` stateless bulk.
- `wait(...)` — POST `/runs/wait` (or thread-scoped) via `request_reconnect`; returns final
  state dict. `raise_error=True` raises if the response contains `__error__`.
- `list(status, select)`, `get`, `delete`.
- `cancel(wait, action)` — `action ∈ {interrupt, rollback}`; `wait=True` uses
  `request_reconnect`. `cancel_many(thread_id, run_ids, status, action)` bulk cancel.
- `join(thread_id, run_id)` — block for final state via `request_reconnect`.
- `join_stream(thread_id, run_id, cancel_on_disconnect, stream_mode, last_event_id)` — SSE
  GET on an existing run.
- Large shared param vocabulary (see domain glossary §6): `input` XOR `command`,
  `stream_mode` (9 modes), `stream_subgraphs`, `stream_resumable`, `interrupt_before/after`,
  `multitask_strategy`, `if_not_exists`, `on_disconnect`, `on_completion`, `after_seconds`,
  `durability` (sync/async/exit — replaces deprecated `checkpoint_during`),
  `langsmith_tracing`, `feedback_keys`, `webhook`, `checkpoint`.
- `on_run_created` callback fires when the `Content-Location` header yields run metadata
  (regex-parsed `/threads/{tid}/runs/{rid}` in `_get_run_metadata_from_response`).

### 2.4 Crons — scheduled runs
- `create_for_thread`, `create` (stateless), `update`, `delete`, `search`, `count`.
- Cron `schedule` is standard cron syntax; `timezone` accepts IANA string or `tzinfo`
  (resolved to string via `_resolve_timezone`, reading `.key` then `tzname`).
- `on_run_completed ∈ {delete, keep}` for stateless crons; `end_time`, `enabled`.
- **Licensing note in docstring:** crons "not supported on all licenses" — a SaaS gate.

### 2.5 Store — cross-thread memory
- `put_item(namespace, key, value, index, ttl)` PUT `/store/items` — namespace labels
  **must not contain `.`** (client-side ValueError). `index=False` disables search indexing,
  `list[str]` selects field paths.
- `get_item(namespace, key, refresh_ttl)` GET (namespace `.`-joined in query).
- `delete_item`, `search_items(namespace_prefix, filter, limit, offset, query, refresh_ttl)`
  POST `/store/items/search` (query = natural-language semantic search; returns `SearchItem`
  with optional `score`), `list_namespaces(prefix, suffix, max_depth, limit, offset)`.
- Mirrors the local `BaseStore` contract (semport/graph) over HTTP.

## 3. v1/v2 streaming protocol (SSE) — `sse.py` + `http.stream`

The classic run stream is **Server-Sent Events**. `SSEDecoder` is a faithful port of the
WHATWG SSE spec (`event:`/`data:`/`id:`/`retry:` fields, `:`-comment skip, multi-line data
accumulation, blank-line dispatch). `BytesLineDecoder` splits on `\n`/`\r`/`\r\n`
incrementally. `data` is orjson-parsed. Key behaviors:
- **`Accept: text/event-stream` + `Cache-Control: no-store`** forced on stream requests.
- **Reconnection**: tracks `Last-Event-ID`; on a `Location` header the server signals a
  resumable stream and the client reconnects (GET) with `Last-Event-ID`, up to
  `max_reconnect_attempts=5`. Transient `httpx.HTTPError` mid-stream retries only after a
  reconnect path is established (else re-raises). Content-Type must contain
  `text/event-stream` or a `TransportError` is raised.
- **Cross-origin guard**: `_validate_reconnect_location` refuses to follow a `Location`
  that changes scheme/host/port (credential-leak prevention). **PORT THIS** — security-load-
  bearing.
- **Stream modes** (`StreamMode`, 9): `values, messages, updates, events, tasks,
  checkpoints, debug, custom, messages-tuple`. These mirror the local engine's stream modes
  (semport/graph §7-invariant "7 stream modes" — the SDK exposes 9, incl. `messages-tuple`
  and split `messages`). Each v2 part is a typed dict discriminated on `type`.

## 4. v3 thread-centric streaming protocol — `stream/` subsystem (2,210 LOC <!-- [validation-certification-11]: corrected from ~2,000; find stream/ -name "*.py" | xargs wc -l = 2,210 (delta +210) -->)

This is a **newer, richer, bidirectional-ish** protocol distinct from the v1/v2 run SSE.
It is the highest-complexity subsystem in the SDK and depends on the external
`langchain-protocol` package for `Event`/`SubscribeParams` types. Shape:

- **Transport abstraction** (`stream/transport/`): `AsyncProtocolTransport` with two
  implementations — `ProtocolSseTransport` (commands via `POST
  /threads/{id}/commands`, events via filtered `POST /threads/{id}/stream/events` SSE) and
  `ProtocolWebSocketTransport` (commands still HTTP POST, events via WebSocket
  `/threads/{id}/stream/events`, initial subscribe wrapped in a `subscription.subscribe`
  command envelope with id=1; ping_interval/timeout=20s). The WS transport carefully
  scopes cookies to base_url+path to avoid cross-origin cookie leak.
- **Command model**: a command is a JSON `{id, method, params}` envelope; responses are
  `{id, ...}` or 202/204 (no body). `run.start` is issued; the v3 response carries only
  `run_id`, never `thread_id` — so the SDK **mints the thread UUID client-side** when the
  caller passes `thread_id=None` (the server lazily creates the row on first `run.start`).
- **Controller** (`controller.py`): one shared event stream, many subscriptions. Manages a
  subscription registry, **filter union computation + stream rotation** (open-new-before-
  close-old so buffered server events replay onto the new stream), **event-id dedup** via a
  bounded LRU (`_SeenEventIds`, 10k cap), **cursor tracking** (`seq` monotonic → `since`
  reconnect param), **fan-out** from the shared stream to per-subscription bounded queues
  (1024), and **reconnect with exponential backoff + jitter** (base 0.1s, cap 2s, 5 tries).
- **Decoders** (`decoders.py`): per-channel event→object state machines: `DataDecoder`
  (values/updates/checkpoints/tasks — emit payload), `MessagesDecoder` (one chat-model
  stream per `message-start`, route by message_id), `ToolCallsDecoder` (per `tool-started`
  handle, delta/finish/error), `SubgraphsDecoder` (discover child subgraph handles by
  namespace prefix, terminal status from tasks-result), `ExtensionsDecoder` (named custom
  channel). `interleave_projections` drives many decoders from one subscription.
- **Projections** (`_async/stream.py`, 1,993 LOC — the single largest file): high-level
  `AsyncThreadStream` API with `.values()`, `.messages()`, `.tool_calls()`, `.subgraphs()`,
  extension projections, lifecycle watcher. This is a **client-side reconstruction of the
  local streaming semantics** over the wire protocol.

**Assessment:** v3 is evolving (`test_remote_graph_v3.py`, `assert_transport_replays.py`,
replay-conformance tests). It parallels the local engine's own "v3 StreamTransformer
framework" which semport/graph §6.6 already marked 🔴 DEFER. The SDK v3 client should
inherit that DEFER.

## 5. Server-side modules bundled in the SDK (NOT client surface)

Three modules in sdk-py are **server-authoring frameworks**, not client code:
- `auth/` (875 + 1,162 + 59 LOC) — the `Auth` object for deployment authors: `@auth.authenticate`
  handler, `@auth.on` authorization rules, `BaseUser`/`Authenticated`/`MinimalUser`
  protocols, exceptions (`HTTPException`), typed `AuthContext`/`BaseAuthContext`. Consumed
  by `langgraph-api` server, not by API callers. **DROP for the client port**; re-scope as a
  server-auth concern only if pregolya ships a hosted server.
- `runtime.py` (238 LOC) — `ServerRuntime`/`AccessContext` injected into graph-builder
  factories inside the deployed server (execution vs read vs introspection contexts). Server
  concept. **DROP for client**; relates to semport/graph's `Runtime` injection.
- `encryption/` (466 + 147 LOC) — pluggable at-rest encryption for checkpoints/store on the
  server. Server concern. **DROP for client.**
- `cache.py` (143 LOC) — a small client-side response cache helper. Keep-if-needed, low
  priority.

## 6. Ubiquitous language (platform glossary)

- **Assistant** — a named, versioned `(graph_id, config, context)` binding. The unit you
  `create` then `run`.
- **Thread** — a persistent state container; accumulates checkpoints across runs.
- **Run** — one invocation of an assistant on a thread (or stateless). Has a `RunStatus`
  (`pending/running/error/success/timeout/interrupted`) and a `MultitaskStrategy`.
- **Cron** — a schedule that spawns runs.
- **Store item** — a `(namespace, key, value)` document with TTL and optional search index.
- **Durability** — `sync`/`async`/`exit` checkpoint persistence timing (same 3 tiers as the
  local engine, semport/graph invariant §1.5). `checkpoint_during` is the deprecated bool.
- **StreamMode** — one of 9 output projections of a run.
- **Multitask strategy** — `reject/interrupt/rollback/enqueue` — how concurrent runs on one
  thread are reconciled.
- **Checkpoint** — `{thread_id, checkpoint_ns, checkpoint_id, checkpoint_map}` — the wire
  handle to a persisted engine checkpoint.
- **Command** — `{goto, update, resume}` — control-flow directive (v1/v2 run payload) OR the
  v3 `{id, method, params}` protocol envelope (name collision; disambiguate by context).
- **Interrupt** — `{value, id}` — a paused-execution marker; resume by `Command{resume}`.

## 7. RemoteGraph — the Pregel drop-in (in langgraph core, consumes the SDK)

`langgraph.pregel.remote.RemoteGraph` (NOT in sdk-py) is the keystone consumer and answers
special-attention-#1: **is the remote client a graph drop-in? YES.** `RemoteGraph(PregelProtocol)`
implements the full local `Pregel` interface against the SDK client:
`invoke/ainvoke`, `stream/astream`, `stream_events/astream_events`, `get_state/aget_state`,
`get_state_history/aget_state_history`, `update_state/aupdate_state`, `bulk_update_state`,
`get_graph/aget_graph`, `with_config`, `copy`. It:
- translates local `RunnableConfig` → SDK thread/checkpoint/assistant params (sanitizing to
  primitives via `_sanitize_config_value`, dropping internal `CONF` keys);
- maps SDK `StreamPart`/v3 events → local `StreamMode` output + `GraphInterrupt`/`ParentCommand`;
- reconstructs a drawable `Graph` (nodes/edges) from `get_graph`.

**pregolya implication:** if pregolya wants "call a remote pregolya-server as if it
were a local graph," `RemoteGraph` is the pattern — a `pregolya-graph` type implementing
the same `Runnable`/graph trait, delegating to a `pregolya-platform-client` crate. This is
the ONLY part of the platform work with a clean parity story to the local engine. Everything
else (assistants/threads/crons/store CRUD, deploy, CLI) is net-new surface with no local
analog and no product mandate yet.

## 8. CLI behavioral intent (command inventory)

Top-level `langgraph` command (click group). Commands:
- **`dev`** — run the in-mem dev server. **Delegates entirely to `langgraph_api.cli.run_server`**
  (the closed-source `langgraph-cli[inmem]` extra). Options: host/port, reload, config,
  n-jobs, browser-open, debug-port/wait-for-client (debugpy), studio-url, allow-blocking,
  tunnel (Cloudflare), log-level, SSL cert/key. **Portable? NO** — it's a launcher for a
  proprietary server. The *config parsing* is portable; the server is not.
- **`up`** — launch the full stack via `docker compose` (postgres + redis + api). Generates
  a compose file to stdin. **Docker-bound; not portable.**
- **`build`** — build the API server Docker image from `langgraph.json`. **Docker + Python-
  packaging-bound.** Validates install/build commands against a disallowed-content filter.
- **`dockerfile <save_path>`** — generate a Dockerfile (+ optional docker-compose.yml, .env,
  .dockerignore) from config. **Docker/packaging-bound.**
- **`validate`** — validate `langgraph.json` against the schema; report unknown keys. **The
  most portable command** — pure config validation.
- **`new [path] --template`** — scaffold a project from a GitHub template (downloads a
  tarball). Portable-ish (template fetch + unpack).
- **`deploy`** (beta group) — build+push image to the LangSmith host backend and create/
  update a deployment. Subcommands: `deploy` (default), `deploy list`, `deploy revisions
  list`, `deploy delete`, `deploy logs`. Talks to a proprietary control-plane REST API
  (`/v2/deployments`, `/v1/projects/.../build_logs`) via `HostBackendClient`. **Fully
  SaaS-bound.**

The CLI's real IP is in `config.py` (1,780 LOC — the `langgraph.json` schema + Dockerfile
generation) and `deploy.py` (2,076 LOC — the deploy orchestration). Both are deeply tied to
Python packaging (uv/pip, pyproject.toml, uv.lock parsing in `uv_lock.py` 1,039 LOC) and
Docker. See dependency-disposition §4 for the portability verdict per command group.

## 9. langgraph.json config schema (portable surface)

`schemas.Config` (TypedDict, total=False) top-level keys: `python_version`, `node_version`,
`api_version`, `base_image`, `image_distro`, `pip_config_file`, `pip_installer`, `source`,
`dockerfile_lines`, `dependencies`, `graphs` (`{id: "module:attr"}`), `env` (dict or path),
`store` (StoreConfig: index/embed/dims/ttl), `checkpointer` (CheckpointerConfig: ttl/serde),
`auth` (AuthConfig: path/openapi-security/studio-auth), `encryption`, `http` (HttpConfig:
per-resource disable flags, cors, configurable headers), `webhooks`, `ui`, `keep_pkg_tools`.
This schema is the **pregolya-project-config analog candidate** — the one CLI artifact
with genuine port value (a `pregolya.toml`/`pregolya.json` describing graphs, deps, env,
store, checkpointer). See rust-translation-strategy §3.

## 10. State checkpoint
```yaml
pass: 6
artifact: behavioral-intent
status: complete
sdk_subclients_cataloged: 5
rest_endpoints_cataloged: 61 # [validation-certification-11]: corrected from 50+; exact count from EXHAUSTIVE-SWEEP §2.1(12)+§2.2(14)+§2.3(11)+§2.4(6)+§2.5(5)+§2.7(3)+§2.8(10)=61; sibling propagation from module-inventory.md correction
cli_command_groups: 7
remote_graph_is_drop_in: true (PregelProtocol)
timestamp: 2026-07-12
```
