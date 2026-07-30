---
artifact: semport/graph/dependency-disposition
project: pregolya
port_target: langgraph @ 1.2.9
analyzer_pass: 2
date: 2026-07-12
legend: PORT = reimplement in Rust; REPLACE = idiomatic Rust crate substitute;
        REUSE = existing pregolya crate; DROP = out of scope; DEFER = later phase.
---

# LangGraph Dependency Disposition

## 1. Python package dependencies → Rust disposition

### 1.1 `langgraph` (core runtime) deps
| Python dep | Version | Role | Disposition |
|---|---|---|---|
| `langchain-core` | >=1.4.7,<2 | `Runnable`, `RunnableConfig`, messages, callbacks — pervasive | **REUSE** pregolya-core (pass 1). HARD prerequisite. Every node is a Runnable; config threads everywhere. |
| `langgraph-checkpoint` | >=4.1,<5 | BaseCheckpointSaver + serde + store | **PORT** as `pregolya-checkpoint` crate (this pass, P0). |
| `langgraph-sdk` | >=0.4.2,<0.5 | Platform HTTP client (used by RemotePregel) | **DEFER** — needed only for `RemotePregel`; the core engine doesn't require it. |
| `langgraph-prebuilt` | >=1.1,<1.2 | react agent / ToolNode | **PORT** as `pregolya-prebuilt` (P1); note most agent logic migrated to `langchain` v1 pkg. |
| `xxhash` | >=3.5 | xxh3_128 for task-id + interrupt-id hashing | **REPLACE** with `xxhash-rust` (xxh3). MUST match hash output — task IDs are content-addressed and drive replay/idempotency. Byte-faithful requirement. |
| `pydantic` | >=2.7.4 | state-schema reflection, config models | **REPLACE** with `serde` + `schemars` (state-schema → channel derivation becomes a derive macro / builder, not runtime reflection). See rust-translation-strategy. |

### 1.2 `langgraph-checkpoint` (base) deps
| Python dep | Role | Disposition |
|---|---|---|
| `langchain-core` | serde reviver, messages | **REUSE** pregolya-core. |
| `ormsgpack` | primary checkpoint serialization | **REPLACE** with `rmp-serde` (msgpack). CRITICAL: must round-trip identically to ormsgpack for cross-impl checkpoint compatibility IF wire-compat with Python is a goal (D9 question). If pregolya checkpoints are Rust-only, a native serde format is acceptable but the conformance suite still pins the semantics. |
| `langchain_core.load.Reviver` | jsonplus (lc-JSON) fallback | **REUSE/PORT** the lc-JSON registry from pregolya-core pass-1 (§9 of core strategy). |

### 1.3 `langgraph-checkpoint-postgres` deps
| Python dep | Role | Disposition |
|---|---|---|
| `psycopg` (3.x) + `psycopg-pool` | async postgres driver + pooling | **REPLACE** with `sqlx` (postgres, compile-time-checked, async, built-in pool) OR `tokio-postgres` + `deadpool-postgres`. `sqlx` preferred for migrations + type-checking. pgvector via `pgvector` crate for store. |
| `orjson` | JSONB (de)serialize | **REPLACE** with `serde_json` (or `sonic-rs` for speed). |

### 1.4 `langgraph-checkpoint-sqlite` deps
| Python dep | Role | Disposition |
|---|---|---|
| `sqlite3` (stdlib) / `aiosqlite` | sync/async sqlite | **REPLACE** with `rusqlite` (sync) or `sqlx` (sqlite, async). Async-first port favors `sqlx`; but `rusqlite` + `spawn_blocking` matches Python's lock-based sync saver more directly. D9 sub-decision. |
| `sqlite-vec>=0.1.6` | vector search extension — `sqlite_vec.loadable_path()` + `sqlite_vec.serialize_float32()` used in `store/sqlite/aio.py` + `base.py` for the `store_vectors` table | **REPLACE** — options: (a) `rusqlite-vtab` extension loading + a vec ext, (b) pure-Rust cosine-similarity over BLOB columns (drop the extension dep), or (c) defer the vector-store path to a later wave. The raw saver (checkpoints table) does NOT require sqlite-vec; only the store/vector search path does. **[validation-corrected]** |

### 1.5 `langgraph-prebuilt` deps
| Python dep | Role | Disposition |
|---|---|---|
| `langchain-core` | ChatModel, tools, messages | **REUSE** pregolya-core. |
| `langgraph-checkpoint` | agent state persistence | **REUSE** pregolya-checkpoint. |

## 2. Standard-library / runtime primitive mappings

| Python primitive | Used for | Rust disposition |
|---|---|---|
| `asyncio` event loop + `asyncio.Task` | async node execution, cancellation, timeouts | **REPLACE** `tokio` (rt-multi-thread, `JoinSet`/`select!`, `CancellationToken`). |
| `concurrent.futures` (thread pool) | sync super-step task execution | **REPLACE** `tokio::task::spawn_blocking` / `rayon` for CPU-bound; async-first port likely collapses to tokio tasks. |
| `concurrent.futures.wait(FIRST_COMPLETED)` | super-step runner wait loop | **REPLACE** `tokio::task::JoinSet::join_next` / `FuturesUnordered`. |
| `threading.Lock` (sqlite saver, atomic counter) | thread-safety | **REPLACE** `tokio::sync::Mutex` / `std::sync::Mutex` / `AtomicU64`. |
| `itertools.count` atomic counter | interrupt/call/subgraph counters in scratchpad | **REPLACE** `AtomicU64`. |
| `ContextVar` (via langchain-core config) | implicit config propagation | **REPLACE** `tokio::task_local!` (per pass-1 core strategy §11) — note spawn does NOT inherit task-locals; re-scope explicitly per task (already a pass-1 ADR). |
| `uuid6` (custom, clock_seq=step) | monotonic sortable checkpoint IDs | **PORT** — implement uuid6 with the clock_seq=step trick; sortability is load-bearing (checkpoints sort by id). `uuid` crate has no v6-with-clock_seq control → hand-roll. |
| `xxh3_128_hexdigest` | task/interrupt IDs | **REPLACE** `xxhash-rust::xxh3`. Byte-faithful. |
| `sha1` (uuid5 for v1 checkpoints) | legacy task IDs | **REPLACE** `sha1` crate — only needed for pre-v2 checkpoint compat (likely DROP if not supporting v1 resume). |
| `ormsgpack` ext-hooks | typed object (de)serialization | **PORT** the ext-type dispatch (Pydantic v2 models, Pydantic v1 models, Enum, dataclasses, namedtuples, datetime/uuid/decimal/set/deque/ip/path/tz/regex/messages/langgraph types, numpy conditional) as rmp ext-types. <!-- [validation-corrected pass-4]: previous text omitted Pydantic (v1+v2), Enum, and dataclass dispatch — critical for graph state; Pydantic v2 is the FIRST real dispatch path in `_msgpack_default` --> Golden-tested by `test_jsonplus.py`. |

## 3. Sub-package disposition summary

| Package/subsystem | Disposition | Priority | Notes |
|---|---|---|---|
| `pregel/` engine (loop/algo/runner/retry) | **PORT** | P0 | The differentiator. Execution-model shape is D9. |
| `channels/` | **PORT** | P0 | Reducer algebra; small, well-specified, golden-tested. |
| `graph/state.py` StateGraph builder | **PORT** | P0 | State-schema→channel derivation via macro/builder (no pydantic reflection). |
| `graph/message.py` add_messages | **PORT** | P0 | Reuse pregolya-core message merge. |
| `checkpoint/base` + serde | **PORT** | P0 | Trait + InMemory + serde. |
| `checkpoint-sqlite` / `-postgres` | **PORT** | P1 | Behind the trait; sqlx/rusqlite. |
| `checkpoint-conformance` | **PORT FIRST** | P0 | Acceptance harness for the saver trait. |
| `stream/` (7 modes + v3 transformers) | **PORT** (modes P1; v3 transformers DEFER) | P1/P2 | v3 transformer framework is complex + evolving; port the 7 modes first, defer v3 extension API. |
| `func/` functional API | **DEFER** | P2 | Sugar over Pregel; add after StateGraph works. |
| `prebuilt/` react agent + ToolNode | **PORT** | P1 | ToolNode is high value; react agent partly superseded by langchain v1. |
| `runtime.py` Runtime injection | **PORT** | P1 | Per-task context (store/previous/stream_writer). |
| `store/` long-term memory (KV+vector) | **PORT** | P2 | Separate from checkpointer; needed for memory features. |
| `cache/` node cache | **DEFER** | P2 | Optimization. |
| `pregel/remote.py` RemotePregel + SDK | **DEFER / maybe DROP** | P3 | Proxies to proprietary Platform. Only if Platform-compat is a product goal. |
| `sdk-py` Platform client | **DEFER** (inventory only) | P2 | Wire protocol matters; deep pass later. |
| `cli` deploy tooling | **DROP** (mostly) | P3 | Docker/platform orchestration; keep only `langgraph.json` config concept if needed. |
| `managed/` (is_last_step, RemainingSteps) | **PORT** | P1 | Small; runtime-injected pseudo-channels. |

## 4. Cross-crate structure proposal (feeds workspace layout)
```
pregolya-core            (pass 1: Runnable, messages, RunnableConfig, callbacks, tools)
pregolya-checkpoint      (BaseCheckpointSaver trait, Checkpoint types, serde, InMemory, store)
  └─ pregolya-checkpoint-sqlite
  └─ pregolya-checkpoint-postgres
pregolya-graph           (channels, pregel engine, StateGraph, streaming, runtime, func)
pregolya-prebuilt        (react agent, ToolNode, HITL schema)
pregolya-conformance     (ported checkpoint-conformance harness; dev-dep)
[deferred] pregolya-sdk  (Platform client)
```
Dependency direction: graph → checkpoint → core; prebuilt → graph. Matches Python and
keeps the checkpointer trait storage-shape-agnostic.

## 5. Key risks flagged for disposition
1. **Wire-format compatibility with Python checkpoints** (ormsgpack + lc-JSON) is a
   binary D9 decision: full cross-runtime compat (heavy, byte-faithful serde) vs Rust-
   native format (lighter, but no Python interop). The conformance suite pins *semantics*
   either way.
2. **`sqlx` vs `rusqlite`/`tokio-postgres`**: sqlx gives compile-time SQL checking +
   migrations but its own async model; picking it early shapes the saver crates.
3. **uuid6 monotonicity** must be preserved exactly — checkpoint ordering depends on it.
4. **xxh3 task-id determinism** must match if any Python-produced checkpoint is ever
   resumed by Rust (and for internal replay it must be self-consistent).

## State checkpoint
```yaml
pass: 2
artifact: dependency-disposition
status: complete
timestamp: 2026-07-12
```
