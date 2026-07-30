---
artifact: semport/platform/module-inventory
project: pregolya
port_target: langgraph-sdk @ 1.2.9 + langgraph-cli @ 1.2.9
analyzer_pass: 6
date: 2026-07-12
note: module + endpoint inventory. The §2 endpoint catalog is the DTU-clone spec input for
      P1-06 holdout testing. All shapes read directly from source; no inference.
---

# Platform SDK + CLI — Module & Endpoint Inventory

## 1. Module manifest

### 1.1 SDK (langgraph_sdk, 18,728 LOC source-only) <!-- [validation-corrected: "total incl. tests/integration" label was wrong; 18,728 is source-only; tests add ~15,711 LOC for a true total of ~34,439] -->

| Module | LOC | Priority | Purpose |
|---|---|---|---|
| `_async/stream.py` | 1,993 | HIGH | v3 thread-stream projections (values/messages/tool_calls/subgraphs) |
| `_sync/stream.py` | 1,629 | MED | sync mirror of above (collapses to async in pregolya) |
| `_async/runs.py` | 1,190 | HIGH | Runs client: stream/create/wait/list/get/cancel/join/batch |
| `_sync/runs.py` | 1,171 | MED | sync mirror |
| `auth/types.py` | 1,162 | DROP | server-side auth type protocols (BaseUser, AuthContext, ...) |
| `schema.py` | 975 | HIGH | all wire DTOs (TypedDicts) + Literals — the type spec |
| `auth/__init__.py` | 875 | DROP | server-side `Auth` decorator framework |
| `_async/threads.py` | 830 | HIGH | Threads client: CRUD + state ops + v3 stream/join |
| `_sync/threads.py` | 808 | MED | sync mirror |
| `_async/assistants.py` | 740 | HIGH | Assistants client: CRUD + versions + schemas + subgraphs |
| `_sync/assistants.py` | 738 | MED | sync mirror |
| `_async/cron.py` | 534 | HIGH | Crons client |
| `_sync/cron.py` | 521 | MED | sync mirror |
| `encryption/__init__.py` | 466 | DROP | server-side at-rest encryption |
| `stream/controller.py` | 398 | HIGH | v3 subscription registry + fan-out + rotation + reconnect |
| `stream/decoders.py` | 359 | HIGH | v3 per-channel event→object state machines |
| `stream/sync_controller.py` | 342 | MED | sync mirror |
| `_async/store.py` | 313 | HIGH | Store client (cross-thread KV) |
| `_sync/store.py` | 313 | MED | sync mirror |
| `_async/http.py` | 312 | HIGH | httpx wrapper: encode/decode/error-map/stream/reconnect |
| `_sync/http.py` | 303 | MED | sync mirror |
| `_shared/utilities.py` | 251 | HIGH | api-key resolution, headers, path-quote, origin guard, tz |
| `runtime.py` | 238 | DROP | server-side ServerRuntime/AccessContext |
| `errors.py` | 231 | HIGH | typed HTTP error taxonomy (400→429, 500) |
| `stream/transport/ws.py` | 223 | MED | v3 WebSocket transport |
| `stream/subscription.py` | 208 | MED | v3 subscription matching/union/covers logic |
| `stream/transport/http.py` | 199 | HIGH | v3 SSE transport (commands + filtered events) |
| `_async/client.py` | 178 | HIGH | `get_client` + `LangGraphClient` top-level |
| `sse.py` | 157 | HIGH | WHATWG SSE decoder + incremental line decoder |
| `stream/transport/sync_ws.py` | 153 | LOW | sync WS |
| `encryption/types.py` | 147 | DROP | encryption types |
| `cache.py` | 143 | LOW | client response cache helper |
| `stream/transport/sync_http.py` | 136 | LOW | sync SSE transport |
| `_sync/client.py` | 127 | MED | sync top-level client |
| `stream/transport/base.py` | 79 | HIGH | EventStreamHandle + url/body builders |
| `stream/multi_cursor_buffer.py` | 71 | MED | v3 multi-cursor replay buffer |
| `auth/exceptions.py` | 59 | DROP | server auth exceptions |
| `client.py` | 55 | HIGH | public re-export facade |
| `_shared/types.py` | small | HIGH | TimeoutTypes alias |

External dependency-injected type source: `langchain-protocol>=0.0.15` provides v3
`Event`/`SubscribeParams`. `langchain-core>=1.4.0` + `langgraph` (dev) for RemoteGraph glue.

### 1.2 CLI (langgraph_cli, 8,383 LOC source-only) <!-- [validation-exhaustive: "total incl. tests" label was wrong; 8,383 is langgraph_cli/ source only; tests add 7,208 LOC (tests/) + 1,614 LOC (examples/generate_schema.py) for a full package total of 17,205 LOC] -->

| Module | LOC | Priority | Purpose |
|---|---|---|---|
| `deploy.py` | 2,076 | LOW(SaaS) | deploy group: build+push+create/update via host backend |
| `config.py` | 1,780 | MED | langgraph.json schema handling + Dockerfile/compose generation |
| `cli.py` | 1,043 | MED | click command definitions (up/build/dockerfile/dev/validate/new) |
| `uv_lock.py` | 1,039 | LOW | uv.lock → Docker pip install translation |
| `schemas.py` | 788 | MED | the config TypedDict schema (Config + Store/Auth/Http/... configs) |
| `docker.py` | 406 | LOW | docker capability probe + compose dict generation |
| `host_backend.py` | 205 | LOW(SaaS) | `/v2/deployments` control-plane REST client |
| `templates.py` | 186 | LOW | project template fetch/unpack |
| `exec.py` | 174 | LOW | subprocess runner |
| `dependency_tracking.py` | 141 | LOW | tracked-package detection |
| `archive.py` | 138 | LOW | tarball creation for remote build |
| `_ignore.py` | 124 | LOW | .dockerignore/gitignore matching |
| `progress.py` | 107 | LOW | terminal progress spinner |
| `analytics.py` | 105 | DROP | usage telemetry (log_command decorator) |
| `util.py` | 50 | LOW | misc (distro warning) |

## 2. REST + STREAMING ENDPOINT CATALOG (the DTU-clone spec for P1-06)

Base URL = deployment root. All requests carry `x-api-key` + `User-Agent`. JSON bodies are
orjson-encoded. Sparse payloads: only non-None fields are transmitted. Path params are
percent-encoded with `safe=""` (dots in bare `.`/`..` segments escaped to `%2E`).

### 2.1 Assistants
| Method | Path | Request body / query | Response |
|---|---|---|---|
| GET | `/assistants/{id}` | — | `Assistant` |
| GET | `/assistants/{id}/graph` | `?xray=int\|bool` | `{nodes[], edges[]}` |
| GET | `/assistants/{id}/schemas` | — | `GraphSchema` |
| GET | `/assistants/{id}/subgraphs` | `?recurse=bool` | `Subgraphs` |
| GET | `/assistants/{id}/subgraphs/{ns}` | `?recurse=bool` | `Subgraphs` |
| POST | `/assistants` | `{graph_id, config?, context?, metadata?, assistant_id?, if_exists?, name?, description?}` | `Assistant` |
| PATCH | `/assistants/{id}` | `{graph_id?, config?, context?, metadata?, name?, description?}` | `Assistant` |
| DELETE | `/assistants/{id}` | `?delete_threads=bool` | 204 |
| POST | `/assistants/search` | `{limit, offset, metadata?, graph_id?, name?, sort_by?, sort_order?, select?}` | `list[Assistant]` + `X-Pagination-Next` header |
| POST | `/assistants/count` | `{metadata?, graph_id?, name?}` | `int` |
| POST | `/assistants/{id}/versions` | `{limit, offset, metadata?}` | `list[AssistantVersion]` |
| POST | `/assistants/{id}/latest` | `{version:int}` | `Assistant` |

### 2.2 Threads
| Method | Path | Request body / query | Response |
|---|---|---|---|
| GET | `/threads/{id}` | `?include=csv` | `Thread` |
| POST | `/threads` | `{thread_id?, metadata?, if_exists?, supersteps?, ttl?}` | `Thread` |
| PATCH | `/threads/{id}` | `{metadata, ttl?}`; `Prefer: return=minimal` → 204 | `Thread`\|204 |
| DELETE | `/threads/{id}` | — | 204 |
| POST | `/threads/search` | `{limit, offset, metadata?, values?, ids?, status?, sort_by?, sort_order?, select?, extract?}` | `list[Thread]` |
| POST | `/threads/count` | `{metadata?, values?, status?}` | `int` |
| POST | `/threads/{id}/copy` | — | 204 |
| POST | `/threads/prune` | `{thread_ids[], strategy?}` | `{pruned_count}` |
| GET | `/threads/{id}/state` | `?subgraphs=bool` | `ThreadState` |
| GET | `/threads/{id}/state/{checkpoint_id}` | `?subgraphs=bool` | `ThreadState` |
| POST | `/threads/{id}/state/checkpoint` | `{checkpoint, subgraphs}` | `ThreadState` |
| POST | `/threads/{id}/state` | `{values, as_node?, checkpoint?, checkpoint_id?}` | `{checkpoint}` |
| POST | `/threads/{id}/history` | `{limit, before?, metadata?, checkpoint?}` | `list[ThreadState]` |
| GET (SSE) | `/threads/{id}/stream` | `?stream_mode=...`; `Last-Event-ID` header | SSE `StreamPart` (v3 thread join) |

### 2.3 Runs
| Method | Path | Request body / query | Response |
|---|---|---|---|
| POST (SSE) | `/threads/{id}/runs/stream` or `/runs/stream` | run payload (see §2.6) | SSE `StreamPart` |
| POST | `/threads/{id}/runs` or `/runs` | run payload | `Run` (+`Content-Location` header) |
| POST | `/runs/batch` | `list[RunCreate]` | `list[Run]` |
| POST (reconnect) | `/threads/{id}/runs/wait` or `/runs/wait` | run payload | final state dict (or `{__error__}`) |
| GET | `/threads/{id}/runs` | `?limit,offset,status,select` | `list[Run]` |
| GET | `/threads/{id}/runs/{run_id}` | — | `Run` |
| POST | `/threads/{id}/runs/{run_id}/cancel` | `?wait=0\|1&action=interrupt\|rollback` | 204 |
| POST | `/runs/cancel` | `{thread_id?, run_ids?, status?}` `?action=` | 204 |
| GET (reconnect) | `/threads/{id}/runs/{run_id}/join` | — | final state dict |
| GET (SSE) | `/threads/{id}/runs/{run_id}/stream` | `?cancel_on_disconnect,stream_mode`; `Last-Event-ID` | SSE `StreamPart` |
| DELETE | `/threads/{id}/runs/{run_id}` | — | 204 |

### 2.4 Crons
| Method | Path | Request body | Response |
|---|---|---|---|
| POST | `/threads/{id}/runs/crons` | cron payload (schedule, input, ...) | `Run` |
| POST | `/runs/crons` | cron payload (+`on_run_completed`) | `Run` |
| PATCH | `/runs/crons/{cron_id}` | cron update fields | `Cron` |
| DELETE | `/runs/crons/{cron_id}` | — | 204 |
| POST | `/runs/crons/search` | `{assistant_id?, thread_id?, enabled?, metadata?, limit, offset, sort_by?, sort_order?, select?}` | `list[Cron]` |
| POST | `/runs/crons/count` | `{assistant_id?, thread_id?, metadata?}` | `int` |

### 2.5 Store
| Method | Path | Request body / query | Response |
|---|---|---|---|
| PUT | `/store/items` | `{namespace[], key, value, index?, ttl?}` | 204 |
| GET | `/store/items` | `?namespace=dotted&key=&refresh_ttl=` | `Item` |
| DELETE | `/store/items` | `{namespace, key}` | 204 |
| POST | `/store/items/search` | `{namespace_prefix[], filter?, limit, offset, query?, refresh_ttl?}` | `{items: SearchItem[]}` |
| POST | `/store/namespaces` | `{prefix?, suffix?, max_depth?, limit, offset}` | `{namespaces: [[str]]}` |

### 2.6 Shared run payload vocabulary (POST run body)
`{input?, command?, assistant_id, config?, context?, metadata?, stream_mode?,
stream_subgraphs?, stream_resumable?, interrupt_before?, interrupt_after?, feedback_keys?,
webhook?, checkpoint?, checkpoint_id?, checkpoint_during?(deprecated), multitask_strategy?,
if_not_exists?, on_disconnect?, on_completion?, after_seconds?, durability?,
langsmith_tracer?}`. `input` and `command` are mutually exclusive. Command sub-fields are
sparse-filtered.

### 2.7 v3 protocol endpoints (thread-centric streaming)
| Method | Path | Notes |
|---|---|---|
| POST | `/threads/{id}/commands` | JSON `{id, method, params}` → `{id, ...}` or 202/204 |
| POST (SSE) | `/threads/{id}/stream/events` | `SubscribeParams` body → filtered event SSE; `since` cursor in body (not header) |
| WS | `/threads/{id}/stream/events` | WebSocket; initial subscribe wrapped in `subscription.subscribe` command envelope |

### 2.8 Host backend control-plane (CLI deploy — separate proprietary API)
| Method | Path | Purpose |
|---|---|---|
| POST | `/v2/deployments` | create deployment |
| GET | `/v2/deployments?name_contains=` | list |
| GET/DELETE | `/v2/deployments/{id}` | get / delete |
| PATCH | `/v2/deployments/{id}` | update (image or source revision) |
| POST | `/v2/deployments/{id}/push-token` | docker registry push token |
| POST | `/v2/deployments/{id}/upload-url` | signed GCS upload URL |
| GET | `/v2/deployments/{id}/revisions?limit=` | list revisions |
| GET | `/v2/deployments/{id}/revisions/{rid}` | get revision |
| POST | `/v1/projects/{pid}/revisions/{rid}/build_logs` | build logs |
| POST | `/v1/projects/{pid}[/revisions/{rid}]/deploy_logs` | deploy logs |

## 3. Wire DTO catalog (schema.py — the type spec)

TypedDicts: `Config, Checkpoint, GraphSchema, AssistantBase, AssistantVersion, Assistant,
AssistantsSearchResponse, Interrupt, Thread, ThreadTask, ThreadState,
ThreadUpdateStateResponse, Run, Cron, CronUpdate, RunCreate, Item, ListNamespaceResponse,
SearchItem, SearchItemsResponse, StreamPart(NamedTuple), Send, Command, RunCreateMetadata`,
plus v2 stream parts (`ValuesStreamPart, UpdatesStreamPart, MessagesPartial/Complete/Metadata/Tuple,
CustomStreamPart, CheckpointsStreamPart, TasksStreamPart, DebugStreamPart, MetadataStreamPart`),
debug payloads (`TaskPayload, TaskResultPayload, CheckpointTaskPayload, CheckpointPayload`).

Literals (enums): `RunStatus`(6), `ThreadStatus`(4), `ThreadStreamMode`(3), `StreamMode`(9),
`DisconnectMode`(2), `MultitaskStrategy`(4), `OnConflictBehavior`(2), `OnCompletionBehavior`(2),
`Durability`(3), `All`(1, `Literal["*"]`), `IfNotExists`(2), `PruneStrategy`(2), `CancelAction`(2),
`BulkCancelRunsStatus`(3), `AssistantSortBy`(5), `ThreadSortBy`(5), `CronSortBy`(7),
`SortOrder`(2), `StreamVersion`(2), plus `*SelectField` field-allowlists per resource.
<!-- [validation-exhaustive: prose enumeration previously listed 18 named Literals and omitted `All = Literal["*"]`; correct count of 19 now reflected in enumeration] -->

`Input`/`Context` are structural `TypeAlias`es (TypedDict-like | dataclass-like |
BaseModel-like | JSON map) — the polymorphic input surface. In Rust these become
`serde_json::Value` at the wire boundary (schemars-typed at the graph-state layer).

## 4. Endpoint-catalog completeness assessment (special attention #2)

**Verdict: the SDK is SUFFICIENT to spec a DTU clone of the LangGraph Server API for
holdout testing — with three named caveats.**

- ✅ **Every REST endpoint** (paths, verbs, request bodies, query params, response types)
  is fully recoverable from the SDK source (§2.1–2.6). The 61 endpoints <!-- [validation-certification-12]: corrected from "50+ endpoints"; consistent with rest_endpoints: 61 in YAML field corrected in cert-11 --> above are the
  complete client-visible surface at 1.2.9.
- ✅ **Every wire DTO** is declared in `schema.py` as a TypedDict with field docs (§3). A
  DTU clone's serde structs can be generated 1:1.
- ✅ **Error taxonomy** (status→shape) is explicit (`errors.py`).
- ⚠️ **Caveat 1 — server-authoritative semantics are opaque.** The SDK encodes *request*
  shapes but the server owns behavior: multitask reconciliation, cron scheduling, run
  status transitions, store search ranking, `supersteps` replay. A DTU clone must
  *reimplement* these from the local engine's semantics (semport/graph), not from the SDK.
  The SDK tells you the API surface, not the state machine behind it.
- ⚠️ **Caveat 2 — v3 protocol events are partially external.** `Event`/`SubscribeParams`
  live in `langchain-protocol` (a separate pinned dep, 0.0.15). The full v3 event grammar
  must be read from that package, not sdk-py. For a DTU clone, v3 should be DEFERRED (match
  semport/graph §6.6 DEFER on the local v3 transformer).
- ⚠️ **Caveat 3 — pagination/header side-channels.** `X-Pagination-Next`,
  `Content-Location` (run metadata), `Location` (SSE reconnect), `Prefer: return=minimal`
  are behavioral contracts carried in headers, easy to miss in a naive clone. Cataloged
  above; must be in the DTU spec.

Net: a DTU clone built from §2 + §3 will exercise the pregolya client correctly for
**request/response conformance**; it will NOT validate engine semantics (that's the local
engine's holdout scope). Recommend the DTU clone be a **stateful fake** seeded with the
local engine, not a pure request-echo, so run/thread/checkpoint lifecycles are realistic.

## 5. State checkpoint
```yaml
pass: 6
artifact: module-inventory
status: complete
rest_endpoints: 61 <!-- [validation-certification-11]: corrected from 50+ (approximation); EXHAUSTIVE-SWEEP exact recount §2.1(12)+§2.2(14)+§2.3(11)+§2.4(6)+§2.5(5)+§2.7(3)+§2.8(10)=61 -->
wire_dtos: 44 <!-- [validation-certification-11]: corrected from 40+ (approximation); 48 class definitions in schema.py minus 4 Protocol stubs (_TypedDictLikeV1/_V2, _DataclassLike, _BaseModelLike) = 44 actual wire DTOs -->
literals_enums: 19
dtu_clone_sufficiency: sufficient-with-3-caveats
timestamp: 2026-07-12
```
