---
artifact: semport/platform/test-inventory
project: pregolya
port_target: langgraph-sdk @ 1.2.9 + langgraph-cli @ 1.2.9
analyzer_pass: 6
date: 2026-07-12
note: tests are first-class behavioral spec inputs. The SDK streaming fake server is the
      DTU-clone seed for P1-06.
---

# Platform SDK + CLI — Test Inventory

## 1. Scale

| Package | Test files | Test LOC | Src LOC | Test:src |
|---|---|---|---|---|
| sdk-py | 57 | 13,652 | 18,728 | 0.73 |
| cli | 11 | 7,102 <!-- [validation-certification-4]: corrected from 7,208; `find tests -name "test_*.py" | xargs wc -l` = 7,102 total --> | 8,383 | 0.85 |

High test density in both — the SDK is well-specified by tests, which is fortunate given
the proprietary-server opacity (dependency-disposition §6). Tests are the second-best
contract source after the SDK source itself.

## 2. SDK test suites (tests/)

### 2.1 Unit / client tests (run by default; `-m 'not integration'`)
| File | Behavioral coverage → port target |
|---|---|
| `test_assistants_client.py` | assistants CRUD/search/versions request+response shapes |
| `test_threads_client.py` | threads CRUD/state/history request shapes |
| `test_crons_client.py` | crons create/update/search shapes |
| `test_client_stream.py` | run stream v1/v2 wrapping (`_sse_to_v2_dict`) |
| `test_client_exports.py` | public surface / re-export stability (parity of `__all__`) |
| `test_api_parity.py` | **async↔sync mirror parity** — proves the two trees are lock-step; in pregolya this collapses (async-only) |
| `test_serde.py`, `test_serde_schema.py` | orjson encode/decode incl. pydantic model_dump, sets, non-str keys — PORT as serde golden tests |
| `test_errors.py` | status→typed-error mapping — PORT as error-taxonomy tests |
| `test_path_encoding.py` | `_quote_path_param` incl. dot-segment escaping — PORT (security) |
| `test_cache.py` | client cache helper (DEFER) |
| `test_encryption.py` | server encryption (DROP) |
| `test_langsmith_tracing.py` | `langsmith_tracing` run param plumbing |
| `test_skip_auto_load_api_key.py` | `api_key=None` vs NOT_PROVIDED behavior — PORT (resolver) |

### 2.2 Streaming suite (tests/streaming/, ~30 files) — the v3 spec
| File | Coverage |
|---|---|
| `_fake_server.py`, `_sync_fake_server.py` | **in-process fake LangGraph server** — the DTU-clone seed (§3) |
| `_events.py` | canonical v3 event fixtures — the event-grammar source |
| `assert_transport_replays.py`, `test_replay_conformance.py` | reconnect/replay determinism — the reconnect contract |
| `test_decoders.py` | per-channel decoder state machines (values/messages/tool_calls/subgraphs/extensions) |
| `test_controller.py` | subscription registry, filter union, rotation, dedup, fan-out, backoff |
| `test_subscription.py` | `matches_subscription`/`filter_covers`/`compute_union_filter` |
| `test_multi_cursor_buffer.py` | multi-cursor replay buffer |
| `test_transport_http.py`, `test_transport_ws.py` | SSE + WS transport behavior |
| `test_transport_path_encoding.py` | v3 path encoding |
| `test_*_projection.py` (values/messages/tool_calls/extensions) | high-level projection APIs |
| `test_shared_stream.py`, `test_thread_stream.py`, `test_scoped_handles.py`, `test_lifecycle_watcher.py`, `test_output.py` | AsyncThreadStream integration |
| `test_sync_*` (7 files) | sync mirrors (collapse in pregolya) |

**All v3 streaming tests are DEFER-scope** (rust-translation-strategy §1.6). They become the
acceptance suite IF v3 is built.

### 2.3 Integration tests (tests/integration/, marked `integration`, need live stack)
`test_assistants/threads_crud/runs/crons/store/cancel/concurrent/subgraphs/tools/messages/
values/update_state/lifecycle/reconnect/websocket/extensions/factory_graph/remote_graph_v3`.
These require `langgraph-api` @ localhost:2024 (proprietary) — **DROP for CI; replace with
the DTU stateful fake.** They are, however, the **best behavioral spec for full
request→run→stream→state lifecycles** and should be read as the DTU-clone acceptance
scenarios for P1-06.

## 3. The streaming fake server = DTU-clone seed (special attention #2/#5)

`tests/streaming/_fake_server.py` is an in-process ASGI fake that answers the v3 protocol.
Its existence is strong evidence that **a DTU clone is feasible** — LangGraph already ships
a testable fake for the streaming surface. For P1-06:
- Extend the fake's *conceptual* model (thread rows, run lifecycle, event emission) into a
  Rust `pregolya-platform-dtu` stateful fake covering REST + v1/v2 SSE.
- Seed run/thread/checkpoint state from the local pregolya engine (so lifecycles are
  realistic), NOT a request-echo — per dependency-disposition §6 recommendation.
- Use `_events.py` fixtures as the event-grammar golden set (DEFER v3 portion).

## 4. CLI test suites (tests/)

| File | Coverage → port relevance |
|---|---|
| `unit_tests/test_config.py` | **langgraph.json schema validation** — PORT (pairs with `validate` + schema port) |
| `unit_tests/test_docker.py` | compose/dockerfile generation (DROP) |
| `unit_tests/test_deploy_helpers.py`, `test_host_backend.py`, `test_logs_helpers.py` | deploy/host-backend (DROP, SaaS) |
| `unit_tests/test_dependency_tracking.py` | uv/pip package tracking (DROP) |
| `unit_tests/test_archive.py` | tarball creation (DROP) |
| `unit_tests/test_util.py`, `test_templates.py` | misc + template scaffolding (DEFER `new`) |
| `unit_tests/cli/test_cli.py`, `test_templates.py` | click command wiring (MAP→clap for `validate`/`new`) |
| `integration_tests/test_cli.py` | end-to-end CLI (mostly DROP) |

Only `test_config.py` (schema validation) maps to the portable CLI slice. The rest tests
Docker/packaging/SaaS behavior with no port target.

## 5. Golden-test priorities for the pregolya port (if built)

1. **Request-body fidelity** — sparse payloads (skip-None), path encoding, header
   side-channels. Golden fixtures from `test_*_client.py`. HIGH.
2. **Error taxonomy** — status→variant. From `test_errors.py`. HIGH.
3. **SSE decode + v1/v2 wrapping + reconnect** — from `test_decoders.py` (v1 subset) +
   `test_client_stream.py` + `assert_transport_replays.py`. HIGH.
4. **API-key resolution** — from `test_skip_auto_load_api_key.py`. MED.
5. **Config schema validation** — from `test_config.py`. MED (CLI slice).
6. **v3 everything** — DEFER.

## 6. State checkpoint
```yaml
pass: 6
artifact: test-inventory
status: complete
sdk_test_files: 57
cli_test_files: 11
dtu_seed: tests/streaming/_fake_server.py (feasibility evidence)
v3_tests: DEFER-scope
timestamp: 2026-07-12
```
