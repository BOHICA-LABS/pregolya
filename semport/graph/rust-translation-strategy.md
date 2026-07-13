---
artifact: semport/graph/rust-translation-strategy
project: ferrochain
port_target: langgraph @ 1.2.9
analyzer_pass: 2
date: 2026-07-12
note: strategy only — NO Rust code committed. Per D9, this PRESENTS ALTERNATIVES for a
      human execution-model decision; it does NOT pick a single winner.
difficulty: 🟢 easy · 🟡 moderate · 🟠 hard · 🔴 research-grade
consistency: aligns with pass-1 core strategy (async-first, dyn+boxed futures at seams,
             serde-tagged enums, tokio::task_local config, tower::Service-shaped Runnable).
---

# LangGraph → Rust Translation Strategy

## 0. The keystone question (D9)
LangGraph is a **BSP/Pregel super-step engine** over a **channel reducer algebra** with
**durable checkpointing**. Porting the *data model* (channels, checkpoints, StateGraph
API) is mechanical-to-moderate. Porting the *execution model* — how a super-step's tasks
are scheduled, isolated, cancelled, retried, checkpointed, and streamed — is the hard,
opinion-bearing decision. This document sketches TWO viable shapes with production
trade-offs, then the invariants both must satisfy, then the data-model translation.

---

## 1. Invariants ANY execution model MUST preserve (non-negotiable)
Derived from behavioral-intent.md; these constrain both alternatives below.
1. **Write isolation within a super-step**: nodes see a frozen input snapshot and write to
   a private buffer; NO node observes another's writes until `apply_writes` at the step
   boundary. (`test_interleave_arrival_order.py` proves order-independence.)
2. **Deterministic merge order**: `apply_writes` sorts tasks by `path[:3]` before folding
   reducers; one monotonic `channel_version` per step.
3. **Deterministic, content-addressed task IDs** (`xxh3_128(ckpt_id ++ ns ++ step ++ name
   ++ PUSH/PULL ++ triggers)`) so replay/resume matches pending writes.
4. **Replay-on-resume**: interrupted/crashed nodes RE-EXECUTE from the top; committed-task
   writes are restored (skipping control signals: ERROR, ERROR_SOURCE_NODE, INTERRUPT, RESUME) so only uncommitted tasks re-run. <!-- [validation-certification-6]: original said "skipping ERROR/RESUME markers"; actual code skips 4 signals (pregel/_loop.py:746); ERROR_SOURCE_NODE and INTERRUPT omitted from prior description -->
5. **Three durability tiers** (sync / async / exit) at BOTH the per-task (`put_writes`) and
   step-boundary (`put`) persistence points.
6. **Recursion limit** (default **10007** via `LANGGRAPH_DEFAULT_RECURSION_LIMIT` env or `_internal/_config.py:DEFAULT_RECURSION_LIMIT`; NOT 25 — that is langchain-core's `RunnableConfig` default which LangGraph overrides) and cooperative **drain** at step boundaries. <!-- [validation-exhaustive]: corrected default from 25 to 10007 -->
7. **7 stream modes** emitted at the correct lifecycle points with a monotonic `seq`.

---

## 2. Execution-model ALTERNATIVE A — "Orchestrator loop + per-task tokio tasks"
*(Closest structural mirror of the Python `PregelLoop`/`PregelRunner`.)*

A single owning **orchestrator task** runs the super-step loop: it calls a pure
`prepare_next_tasks` over the current checkpoint+channels, then for each task spawns a
`tokio` task (or `spawn_blocking` for sync/CPU-bound nodes), collects their write-buffers
through a `JoinSet` / `mpsc` with a `FIRST_COMPLETED`-style `join_next` loop, and — after
all resolve (or an interrupt/error bubbles) — synchronously runs `apply_writes` and writes
the checkpoint. Channels + checkpoint are owned exclusively by the orchestrator (no shared
mutation); nodes get an immutable input snapshot and return `Vec<(channel, value)>`.
Cancellation uses a `CancellationToken` per step; timeouts wrap each task in
`tokio::time::timeout`. Streaming is an `mpsc` from tasks → orchestrator → a `StreamMux`.

**Production trade-offs.** (+) Simplest correctness story: the single-owner orchestrator
makes write-isolation and deterministic merge *structurally guaranteed* — no locks on
channels, borrow-checker enforces it. (+) Maps 1:1 to the Python tests, easing conformance.
(+) Checkpoint atomicity is trivial: the orchestrator is the only writer, so a step's
`put` is a single await at a known point; sync/async/exit modes are just *where* that await
(or its spawned future) sits. (−) **Backpressure**: a fast streaming producer inside a slow
consumer needs bounded `mpsc` + care, but it's localized. (−) **Multi-tenant fairness**:
one orchestrator per run means N concurrent threads/graphs = N orchestrators; fairness
across tenants requires an outer scheduler / global semaphore capping total in-flight node
tasks (`max_concurrency` maps to a `tokio::sync::Semaphore`). (−) The orchestrator is a
serialization point per run (fine — Python is too), but long `apply_writes`/serialization
can stall streaming; mitigate by moving serialization to `spawn_blocking`.

## 3. Execution-model ALTERNATIVE B — "Actor/event-loop scheduler with a channel bus"
*(A message-driven scheduler; nodes are actors, the step boundary is a barrier event.)*

Model the engine as a set of **actors** communicating over channels: a `Scheduler` actor
owns the checkpoint+channels and a work queue; `NodeRunner` actors pull tasks and push
`TaskDone{task_id, writes}` / `TaskStream{part}` / `Interrupt` / `Error` messages back on a
bus. The scheduler advances a **super-step barrier**: it dispatches the step's task set,
counts completions, and only crosses the barrier (apply_writes + checkpoint) when the
count is met or a drain/interrupt fires. This generalizes to a **distributed / multi-graph
executor**: the same message protocol can route tasks to a worker pool, other processes,
or (à la `RemotePregel`) remote nodes.

**Production trade-offs.** (+) **Multi-tenant fairness & backpressure are first-class**:
one scheduler can fair-queue tasks across many runs with a shared bounded work queue and
weighted round-robin; backpressure is natural (bounded channels propagate). (+) Natural
path to distributed execution and horizontal scale (the `Send`/PUSH task model is already
message-shaped). (+) Decouples node execution from the step driver → easier to add worker
pools, priorities, quotas. (−) **Correctness is harder to prove**: write-isolation and
deterministic merge now depend on protocol discipline, not the type system — the scheduler
must buffer writes and refuse to expose them mid-step; races are logic bugs, not compile
errors. (−) **Checkpoint atomicity** across the barrier needs explicit fencing (the
scheduler must ensure all `put_writes` for a step are durably acked before the barrier `put`
under `sync` durability) — more moving parts. (−) More machinery (actor lifecycles,
supervision, message enums) for the common single-run case; higher baseline complexity and
more `Arc`/message-clone overhead. (−) Cancellation/timeout semantics span actors →
`CancellationToken` propagation through the bus must be carefully designed.

## 4. Hybrid note (for the D9 conversation, not a recommendation)
The two are not mutually exclusive: **A as the intra-run engine, B as the inter-run
scheduler.** Alternative A's orchestrator could itself be a task scheduled by an
Alternative-B-style multi-tenant scheduler that owns the global `Semaphore`, fair-queues
runs, and applies per-tenant quotas — giving A's correctness with B's fairness. The human
decision in D9 is really: (a) start with A and defer multi-tenancy, or (b) invest in B's
protocol up front because Platform-scale multi-tenancy is a near-term product goal. This
should be weighed against whether ferrochain targets an embedded library (favors A) or a
hosted server (favors B or hybrid).

---

## 5. vsdd-factory prior-art assessment (inventory-level)
Read `/Users/jmagady/Dev/vsdd-factory` Cargo.toml + `crates/` listing +
`factory-dispatcher/src/executor.rs` (headers/signatures only). It is a **WASM plugin
dispatcher** (Claude Code hook events → wasmtime plugins) with telemetry sinks — NOT a
graph engine — but several patterns transfer:

**Applicable patterns:**
- **Tiered execution (`execute_tiers`)** with an `ExecutorInputs`/`TierExecutionSummary`
  shape is a direct analog of **super-steps**: staged batches of work with a summary per
  stage. The structure (prepare tier → run tier concurrently → summarize) maps onto
  tick → run → after_tick.
- **Structural sync/async partition** (ADR-019): sync-group plugins run via
  `spawn_blocking` and participate in gate decisions; async-group plugins are spawned via
  independent `tokio::spawn`, collected over a **channel**, with a **`tokio::select!` drain
  timer** for cooperative shutdown. This is precisely the pattern ferrochain needs for
  (a) isolating blocking node bodies from the async runtime and (b) LangGraph's cooperative
  **drain** at super-step boundaries (`GraphDrained`/SIGTERM). Reuse the drain-timer idiom.
- **Per-unit `spawn_blocking` isolation** so a heavy/blocking node never stalls the
  reactor — directly applicable to sync node bodies (Alternative A's `spawn_blocking` lane).
- **Sink router fan-out** (`sinks/router.rs`, mpsc to file/otel/datadog/honeycomb) is a
  clean template for the **stream-mode fan-out** (one event → N stream-mode consumers) and
  for callback/observability emission.
- **Fault isolation** (`resolver_error_isolation`, trap-string capture on `spawn_blocking`
  JoinError) mirrors LangGraph's node-panic isolation + `NodeError` handling.
- Workspace conventions: edition 2024, rust 1.95, `tokio`, `thiserror` (lib errors),
  `anyhow` (bins only), `serde`/`serde_json`, feature-gated sink crates — adopt these.

**Where production-best for ferrochain DIVERGES from vsdd-factory:**
- vsdd-factory is **fire-and-forget event dispatch**: plugins are largely independent, one
  pass, no shared mutable graph state, no durable checkpoint, no replay. ferrochain needs
  **stateful, resumable, checkpointed** execution with a strict write-isolation +
  deterministic-merge invariant — a fundamentally heavier correctness contract. Do NOT
  model nodes as independent fire-and-forget plugins.
- vsdd-factory uses **wasmtime sandboxing**; ferrochain nodes are in-process Rust
  closures / Runnables — no WASM boundary (unless untrusted-node execution becomes a goal;
  that would be a separate, later decision).
- vsdd-factory's "tiers" are statically ordered; ferrochain's super-steps are
  **dynamically discovered** each step from channel versions + Sends — the scheduler must
  re-plan every step, not run a fixed pipeline.
- vsdd-factory has no **backpressure/streaming-into-consumer** or **multi-tenant fairness**
  concerns at the graph level; ferrochain (esp. Alternative B) does.
- No **checkpoint atomicity / durability tiers** in vsdd-factory — the hardest part of
  ferrochain has no analog there.

Net: vsdd-factory is a useful *idiom library* (tiered-run + channel-collect + drain-timer +
spawn_blocking isolation + sink fan-out + error taxonomy) but NOT an architectural template
for the engine; the stateful/durable/replay core is greenfield.

---

## 6. Data-model translation (independent of execution shape)

### 6.1 Channels — 🟡
`trait Channel { type Value; type Update; fn get(&self)->Result<Value,Empty>;
fn update(&mut self, Vec<Update>)->Result<bool>; fn checkpoint(&self)->Value;
fn from_checkpoint(v)->Self; fn consume(&mut self)->bool; fn finish(&mut self)->bool;
fn is_available(&self)->bool; }`. Concrete types = enum or generic structs: `LastValue`,
`LastValueAfterFinish`, `BinaryOperatorAggregate<T, Reducer>`, `Topic<T>{accumulate}`,
`EphemeralValue`, `AnyValue`, `NamedBarrierValue`, `UntrackedValue`, `DeltaChannel`. The
reducer for BinOp is a `Box<dyn Fn(T,T)->T>` or an enum of known reducers. `Overwrite`
becomes an enum variant wrapping the value (must round-trip through serde: keep the
`{type:"__overwrite__", value}` shape). Golden-tested by `test_channels.py`. Object-safety:
channels need a `dyn Channel<Value=Value,Update=Value>` erased form for the channel map —
or a `ChannelValue` enum (serde_json::Value-like) at the map boundary. **Open Q:** typed
generic channels vs an erased `Value` channel map (mirrors pass-1 Runnable object-safety ADR).

### 6.2 Checkpoint + saver trait — 🟠
`trait CheckpointSaver: Send+Sync { async fn get_tuple(&self,cfg)->Option<CheckpointTuple>;
async fn list(...)->BoxStream<CheckpointTuple>; async fn put(...)->Config; async fn
put_writes(...); async fn delete_thread/copy_thread/prune/delete_for_runs(...); fn
get_next_version(...)->Version; }`. Async-first (drop the sync/async duality). `Checkpoint`
= a serde struct (`v/id/ts/channel_values/channel_versions/versions_seen/updated_channels`).
`Version` generic over int/str/float → an enum or a `Ord + Clone` bound. The trait MUST be
storage-shape-agnostic (single-blob sqlite vs normalized-blob postgres). Port
`checkpoint-conformance` FIRST as the acceptance gate. `dyn CheckpointSaver` at the seam
(async-trait / boxed futures).

### 6.3 Serialization — 🟠 (byte-faithful, golden-tested)
`rmp-serde` primary + lc-JSON fallback (reuse ferrochain-core reviver). Port the ext-type
dispatch (Pydantic v2 models, Pydantic v1 models, Enum, dataclasses, namedtuples,
datetime/uuid/decimal/set/deque/ip/path/tz/regex/messages/langgraph types, numpy) and the
`SAFE_MSGPACK_TYPES` allowlist + `LANGGRAPH_STRICT_MSGPACK` security gate. `test_jsonplus.py`
(1,237 LOC) is the golden spec. **Open Q (D9):** Python wire-compat vs Rust-native format.
<!-- [validation-corrected pass-4]: previous text omitted Pydantic (v1+v2), Enum, and dataclass
dispatch paths — these are the most important for graph state serialization; see behavioral-intent
§2.3 for full dispatch order with EXT type codes -->

### 6.4 StateGraph builder — 🟠
`StateGraph<S>` builder → `compile()` → `Pregel`. State-schema→channel derivation replaces
pydantic runtime reflection: a `#[derive(GraphState)]` proc-macro reads field types +
`#[reducer(...)]`/`Annotated`-equivalent attributes to emit the channel map at compile
time, OR a runtime builder registering `(key, Channel)` pairs. `add_node` (overloads →
builder methods + a `Node` enum: closure / Runnable / subgraph), `add_edge`,
`add_conditional_edges` (path fn → `Vec<Destination>` where `Destination = Node(name) |
Send | End`), `add_sequence`, entry/finish points. Node fn signatures `(state)`,
`(state, config)`, `(state, runtime)` → a `Node` trait with an injected `Runtime`.
**Open Q:** derive-macro state schema (ergonomic, compile-time) vs dynamic builder
(flexible, matches Python). Big ergonomics decision.

### 6.5 Command / Send / interrupt — 🟠
`Command { graph: Option<GraphTarget>, update: Option<StateUpdate>, resume:
Option<ResumeValue>, goto: Vec<Destination> }` (a `ToolOutput` too). `Send{node, arg,
timeout}`. `interrupt(value)` → needs task-local scratchpad access (interrupt counter +
resume-value slice); returns stored resume on replay or raises `GraphInterrupt`. Replay-
from-top semantics (§3.2 behavioral) must be reproduced — the scratchpad's
`interrupt_counter`/`resume` matching is exact and test-locked.

### 6.6 Streaming — 🟠 / 🔴 (v3)
7 modes as an enum; emit at the lifecycle points in behavioral §4 via a `StreamMux` that
tags each part with `ns` + monotonic `seq`. Use `futures::Stream` / `tokio_stream` +
bounded `mpsc`. The **v3 `StreamTransformer` framework** (sync/async lanes, before_builtins
ordering, `schedule()`) is 🔴 and evolving — **DEFER**; ship the 7 modes first. Async-first
collapses the sync/async transformer duality (one lane).

### 6.7 Runtime injection, retry, timeout — 🟡/🟠
`Runtime{store, previous, stream_writer, context, execution_info}` injected per task.
`RetryPolicy`/`TimeoutPolicy` map to a retry wrapper + `tokio::time::timeout` (run) + an
idle-timeout tracker refreshed on progress/heartbeat. `NodeCancelledError`/`NodeTimeoutError`
distinctions (user-raised cancel vs framework cancel) must be preserved for correct
retry/error reporting.

---

## 7. Difficulty / risk summary
| Subsystem | Difficulty | Primary risk |
|---|---|---|
| Execution model (super-step scheduler) | 🔴 | The D9 decision; write-isolation + determinism + replay + durability atomicity + fairness. |
| Serialization (msgpack + lc-JSON) | 🟠 | byte-faithful ext-types + security allowlist; Python wire-compat question. |
| Checkpoint saver trait + backends | 🟠 | storage-shape polymorphism; sqlx/rusqlite choice; DeltaChannel chain preservation. |
| StateGraph builder + schema→channels | 🟠 | derive-macro vs runtime builder ergonomics. |
| Command/Send/interrupt/replay | 🟠 | replay-from-top + scratchpad matching is exact/test-locked. |
| Streaming (7 modes) | 🟠 | lifecycle emission points + seq ordering. |
| Streaming v3 transformers | 🔴 | complex, evolving — DEFER. |
| Channels (reducer algebra) | 🟡 | Overwrite serde round-trip; object-safety of channel map. |
| Retry/timeout/Runtime | 🟡 | cancel-vs-timeout error taxonomy. |
| RemotePregel + SDK | 🟠 | proprietary Platform protocol — DEFER/maybe DROP. |

## 8. Open design questions for D9 (top 5)
1. **Execution-model shape**: Alternative A (orchestrator + tokio tasks) vs B (actor/bus
   scheduler) vs hybrid — driven by embedded-library vs hosted-multi-tenant-server target.
2. **Checkpoint wire-format**: Python-compatible (ormsgpack+lc-JSON byte-faithful) vs
   Rust-native. Determines cross-runtime resume + serde effort.
3. **State-schema mechanism**: `#[derive(GraphState)]` proc-macro (compile-time, ergonomic,
   less dynamic) vs runtime channel-map builder (matches Python's dynamism).
4. **Channel typing**: fully-generic typed channels vs an erased `Value` channel map — the
   same object-safety tension as the pass-1 Runnable ADR; they should be resolved together.
5. **Durability atomicity contract**: how sync/async/exit modes fence per-task `put_writes`
   against step-boundary `put` — trivial under A, needs explicit protocol under B; and
   whether `async` mode's "may lose last in-flight persist" is acceptable for ferrochain's
   production stance (CLAUDE.md production-grade rules were NOT found at repo root — confirm).

## State checkpoint
```yaml
pass: 2
artifact: rust-translation-strategy
status: complete
execution_alternatives_presented: 2 (+ hybrid note) — per D9, no single recommendation
timestamp: 2026-07-12
```
