---
artifact: semport/graph/test-inventory
project: ferrochain
port_target: langgraph @ 1.2.9
analyzer_pass: 2
date: 2026-07-12
note: tests are FIRST-CLASS spec inputs. The Rust port should port the highest-value
      suites as a conformance harness. LOC below are the authoritative behavioral spec.
---

# LangGraph Test Inventory (spec-source ranking)

## 0. Scale
- Core runtime tests (`libs/langgraph/tests`): **49 test files, ~62–63k LOC** — larger
  than ALL deep-scope source combined. This is the real specification.
- Checkpoint base tests: 6 files, ~3.8k LOC.
- Prebuilt tests: 10 files, ~8.2k LOC.
- **`libs/checkpoint-conformance`**: a dedicated, reusable conformance framework
  (`validate.py`, `capabilities.py`, `initializer.py`, `report.py`, `spec/test_*.py`)
  that ANY checkpoint saver must pass. Postgres/sqlite tests invoke it. THIS is the
  single most important artifact to port to Rust — it defines the saver contract
  operationally.

## 1. Core runtime — highest-value suites (port priority order)

| Test file | LOC | What it locks down | Port value |
|---|---|---|---|
| `test_pregel.py` / `test_pregel_async.py` | 9,677 / 9,729 | The master super-step engine spec: node triggering, channels, edges, conditional edges, Send fan-out, subgraphs, interrupts, state updates, streaming — sync+async mirror. | P0 — golden acceptance |
| `test_large_cases.py` / `_async.py` | 6,986 / 4,056 | Complex realistic graphs (map-reduce, nested subgraphs, mixed reducers). Integration-level determinism. | P0 |
| `test_time_travel.py` / `_async.py` | 3,966 / 3,211 | `get_state_history`, fork, resume-from-checkpoint, `update_state`, `bulk_update_state`. Time-travel semantics. | P0 — persistence correctness |
| `test_retry.py` | 2,943 | RetryPolicy (attempts/backoff/jitter/retry_on), TimeoutPolicy (idle/run), NodeCancelled/NodeTimeout, per-task retry loop. | P1 |
| `test_channels.py` | 803 | Per-channel-type behavioral contract (LastValue, BinOp fold+Overwrite, Topic accumulate, untracked exclusion, DeltaChannel). NOTE: `NamedBarrierValue` and `EphemeralValue` are **not tested here** — `EphemeralValue` has limited coverage in `test_state.py` (3 assert lines); `NamedBarrierValue` has no dedicated unit test in the reference corpus. <!-- [validation-corrected pass-4]: original cited "barrier availability, ephemeral lifetime" as behaviors covered by test_channels.py; exhaustive grep of all test function names in the file (31 functions: test_last_value, test_topic, test_topic_accumulate, test_binop, test_untracked_value, test_delta_channel_*) confirms zero barrier or ephemeral tests. --> | P0 — channel algebra |
| `test_interleave_arrival_order.py` | 359 | Concurrent task arrival-order independence within a super-step (BSP isolation proof). | P0 — validates the invariant |
| `test_state.py` (373) + `test_messages_state.py` (369) + `test_pydantic.py` (362) | ~1.1k | State-schema → channel derivation, reducer inference, `add_messages`, pydantic/dataclass state. | P0 — StateGraph API |
| `test_runtime.py` | 1,220 | `Runtime` injection (store/previous/stream_writer/context/ExecutionInfo), managed values. | P1 |
| `test_graph_callbacks.py` | 344 | langchain-core callback propagation through the run tree. | P1 |
| `test_runnable.py` (414) + `test_utils.py` (799) | ~1.2k | Private RunnableCallable/RunnableSeq behavior, config merge/patch, utils. | P1 |

## 2. Streaming test suites (v3 transformer framework)

| Test file | LOC | Locks down |
|---|---|---|
| `test_pregel_stream_events_v3.py` (1,780) + `test_stream_events_v3.py` (1,180) + `_e2e.py` (808) | ~3.8k | v3 `stream_events` protocol: event envelope, `seq` ordering, transformer projections. |
| `test_stream_messages_transformer.py` (940) | | `messages` mode token streaming + metadata. |
| `test_stream_subgraph_transformer.py` (856) | | namespace/subgraph event routing. |
| `test_stream_lifecycle_transformer.py` (712), `test_stream_data_transformers.py` (707), `test_stream_before_builtins.py` (296) | ~1.7k | lifecycle events, data projections, before-builtins ordering hook (PII-redaction-style mutation ordering). |

Streaming has ~7k LOC of tests — the v3 transformer framework is heavily specified and
is the riskiest/most-complex streaming surface (see rust-translation-strategy §streaming).

## 3. Persistence / checkpoint suites

| Test file | LOC | Locks down |
|---|---|---|
| `test_checkpoint_migration.py` (1,727) | | checkpoint format v1→v2 migration; old-format resume. |
| `test_subgraph_persistence.py` / `_async.py` (687/709) | | nested-thread checkpoint namespacing across subgraphs. |
| `test_delta_channel_migration.py` (618), `_exit_mode.py` (391), `_update_state.py` (340), `_benchmark.py` (321) | ~1.7k | DeltaChannel (beta): snapshot frequency, ancestor-walk history, exit-mode accumulation, prune/copy chain preservation. |
| `checkpoint/tests/test_jsonplus.py` (1,237) | | **serialization round-trip golden spec** — every typed object (Pydantic models, Enum, dataclasses, datetime/uuid/decimal/set/deque/ip/path/messages/langgraph types, numpy/pandas), msgpack + jsonplus fallback, strict allowlist. MUST be byte-faithful in Rust. <!-- [validation-corrected pass-4]: previous list omitted Pydantic models, Enum, dataclasses, and numpy/pandas from the covered types; all are explicitly tested in test_jsonplus.py (test_msgpack_pydantic_warns_by_default, test_serde_jsonplus_numpy_array, test_serde_jsonplus_pandas_dataframe, etc.) --> |
| `checkpoint/tests/test_memory.py` (680) | | InMemorySaver reference behavior (the conformance baseline). |
| `checkpoint/tests/test_encrypted.py` (446) | | EncryptedSerializer wrapping. |
| `checkpoint/tests/test_store.py` (1,046) | | BaseStore (long-term memory) semantics. |

## 4. The conformance framework (`libs/checkpoint-conformance`) — TOP PORT PRIORITY

- `langgraph/checkpoint/conformance/validate.py` + `capabilities.py` + `initializer.py`
  + `spec/test_*.py` (test_list, test_delta_channel_history, test_delete_thread, ...).
- A capability-gated, reusable test battery that sqlite/postgres/memory savers all run
  against. It operationally DEFINES `BaseCheckpointSaver`.
- **Recommendation:** port this suite FIRST as the acceptance gate for the Rust
  `CheckpointSaver` trait + InMemory/SQLite/Postgres impls. It is the cheapest way to
  guarantee behavioral parity of the persistence layer.

## 5. Backend saver tests
- `checkpoint-postgres/tests`: test_sync/test_async/test_store/test_async_store (invoke
  conformance) — validate the normalized-blob schema, migrations, blob dedup.
- `checkpoint-sqlite/tests`: test_sqlite/test_aiosqlite + delta conformance + ttl +
  store — validate single-blob schema, WAL, delta migration.

## 6. Prebuilt tests
| Test | LOC | Locks down |
|---|---|---|
| `test_tool_node.py` (2,430) | | ToolNode: tool-call execution, error handling, injected state/store, parallel tool calls. |
| `test_react_agent.py` (2,156) + `test_react_agent_graph.py` (52) | | create_react_agent loop, structured response, interrupts. |
| `test_on_tool_call.py` (1,473) + interceptor/validation suites (~1.7k) | | tool-call interception, validation-error filtering, tool-call transformer. |

## 7. Extraction guidance (BC drafting)
- Treat `test_channels.py`, `test_jsonplus.py`, and the conformance `spec/` as
  **byte-faithful golden specs** — assertions map directly to Rust unit tests.
- Treat `test_pregel*.py` + `test_time_travel*.py` + `test_interleave_arrival_order.py`
  as the **engine acceptance suite** — port as integration tests once the scheduler exists.
- Coverage gaps to watch: `RemotePregel`/`test_remote_graph*.py` (Platform protocol) and
  the v3 transformer framework are the least-stable, most-complex; confidence that the
  Rust port must match them exactly is LOWER (they are evolving) — flag for D9.

## State checkpoint
```yaml
pass: 2
artifact: test-inventory
status: complete
core_test_files: 49
core_test_loc: ~62000
conformance_framework: libs/checkpoint-conformance (PORT FIRST)
timestamp: 2026-07-12
```
