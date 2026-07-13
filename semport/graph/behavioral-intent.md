---
artifact: semport/graph/behavioral-intent
project: ferrochain
port_target: langgraph @ 1.2.9
analyzer_pass: 2
date: 2026-07-12
audience: feeds human design conversation D9 (execution-model decision)
confidence: HIGH = read directly from source; MED = inferred from source + tests; LOW = docstring-only
---

# LangGraph Behavioral Intent (runtime + persistence)

This document captures *what LangGraph promises to do*, structured for the D9 design
conversation. Six deep areas per the pass brief, each with the exact semantics observed
in source at tag 1.2.9.

---

## 1. Pregel execution model (super-step semantics)

LangGraph is a **Bulk Synchronous Parallel (Pregel/BSP)** engine. Execution is a sequence
of discrete **super-steps**. Confidence HIGH (read `_loop.py:tick/after_tick`,
`_algo.py:apply_writes/prepare_next_tasks`).

### 1.1 The super-step cycle (one `tick` → run → `after_tick`)
1. **`tick()` — plan.** Call `prepare_next_tasks(checkpoint, pending_writes, nodes,
   channels, ...)`. A task is created for a node when it is *triggered*: `_triggers()`
   returns true iff any of the node's subscribed channels `is_available()` AND its
   `channel_versions[chan] > versions_seen[node][chan]` (i.e. the channel was written
   since this node last saw it). Two task kinds:
   - **PULL tasks**: nodes triggered by channel writes (normal edges).
   - **PUSH tasks**: `Send(node, arg)` packets sitting in the `TASKS` Topic channel —
     dynamic fan-out, executed in the step *after* they were emitted.
   Candidate-node selection is optimized: if `updated_channels` + `trigger_to_nodes`
   are known, only nodes subscribed to updated channels are considered (not all nodes).
2. **Halt checks (before run):** if no tasks → status `done`, stop. If a drain was
   requested (`RunControl.request_drain()`, e.g. on SIGTERM) → status `draining`, stop
   cooperatively at the boundary with checkpoint saved. If `interrupt_before` matches →
   raise `GraphInterrupt`.
3. **Run.** `PregelRunner.tick()` executes ALL tasks of the super-step **concurrently**
   (asyncio tasks / thread-pool futures), waiting `FIRST_COMPLETED` in a loop. Each
   node runs inside `_retry` (retry policy + timeout). Nodes read a *frozen snapshot* of
   channel values (input computed in `_proc_input` at plan time) and accumulate their
   outputs into a private `writes` deque via `CONFIG_KEY_SEND` — **they do NOT mutate
   shared channels directly**. This is the BSP isolation guarantee.
4. **`after_tick()` — apply.** Collect all tasks' writes. `apply_writes()`:
   - sorts tasks by `path[:3]` for **deterministic** update order;
   - updates `versions_seen` for each task's triggers;
   - computes ONE `next_version` (monotonic, default integer +1) for the whole step;
   - `consume()`s read channels; groups writes by channel; calls `channel.update(vals)`
     per channel; bumps `channel_versions[chan]` to `next_version` for updated channels;
   - notifies **unwritten** available channels of the step (`update(EMPTY_SEQ)`), and if
     the step is (tentatively) terminal (`updated_channels.isdisjoint(trigger_to_nodes)`),
     calls `finish()` on all channels (this is how `*AfterFinish` channels release).
5. **Checkpoint** (`_put_checkpoint({"source":"loop"})`) — see §2/§5.
6. **Halt check (after run):** `interrupt_after` match → `GraphInterrupt`.

### 1.2 Determinism guarantees
- Update application order is deterministic (`task_path_str(path[:3])` sort).
- Task IDs are content-addressed: `xxh3_128(checkpoint_id ++ checkpoint_ns ++ step ++
  name ++ PULL/PUSH ++ triggers)` (checkpoint v>1) — so the same graph state produces the
  same task IDs, enabling **replay/idempotency** and pending-write matching.
- Channel versions are monotonically increasing; a single `next_version` per step means
  all channels written in a step share a version.
- Within a super-step, node execution ORDER is nondeterministic (concurrent), but node
  *effects* are isolated until `apply_writes`, so the observable outcome is order-
  independent EXCEPT where a reducer is non-commutative — LastValue enforces ≤1 write/step
  to sidestep this; BinaryOperatorAggregate folds in the deterministic sorted order.

### 1.3 Halting conditions & recursion limit
- **Natural halt:** a super-step produces no triggered tasks.
- **Recursion limit:** `recursion_limit` (default **10007**, from LangGraph's own
  `DEFAULT_RECURSION_LIMIT = int(getenv("LANGGRAPH_DEFAULT_RECURSION_LIMIT", "10007"))` in
  `_internal/_config.py`; LangGraph's `ensure_config()` injects this default, overriding
  langchain-core's `RunnableConfig` default of 25). The loop tracks `step`/`stop`
  (`stop = step + recursion_limit + 1`); `tick()` sets status `out_of_steps` when `step > stop`
  and returns `False`; the outer invoke loop in `main.py` then raises `GraphRecursionError`
  after checking `loop.status == "out_of_steps"`. `tick()` itself does NOT raise
  `GraphRecursionError`. This is the primary infinite-loop guard.
  <!-- [validation-corrected pass-5]: original said tick() "raises GraphRecursionError"; tick()
  only sets status and returns False; the error is raised in main.py lines 3002-3011 /
  3483-3492, not inside tick(). Also corrected "+1" elision (exact formula is
  recursion_limit + 1, not approximately recursion_limit). -->
  <!-- [validation-exhaustive]: corrected default from 25 to 10007; the 25 is langchain-core's
  RunnableConfig default but LangGraph overrides it at _internal/_config.py:32 with
  DEFAULT_RECURSION_LIMIT = int(getenv("LANGGRAPH_DEFAULT_RECURSION_LIMIT", "10007")), injected
  via ensure_config() at _internal/_config.py:335. -->
- **Interrupt halt:** `interrupt_before`/`interrupt_after` (static, per-node or `"*"`) or
  dynamic `interrupt()` (see §3).
- **Drain halt:** cooperative shutdown at a boundary (`GraphDrained`).

### 1.4 Channel type semantics (the reducer algebra) — HIGH
See module-inventory §1.2. Key behavioral contracts:
- **`LastValue`**: `update([])`→no-op; `update([v])`→store; `update([v1,v2])`→
  `InvalidUpdateError` (INVALID_CONCURRENT_GRAPH_UPDATE). "One writer per step."
- **`BinaryOperatorAggregate`**: folds `value = op(value, v)` over sorted writes; first
  write when empty seeds the value; an `Overwrite(v)` bypasses the reducer (≤1 per step
  else error). Backs `Annotated[list, operator.add]`-style state.
- **`Topic(accumulate)`**: list pubsub; `accumulate=False` clears at start of each update
  (per-step semantics); flattens list-valued updates. Backs `Send`/`TASKS`.
- **`NamedBarrierValue`**: available only once all named upstream writers have written —
  synchronization/join.
- **`EphemeralValue`**: one-step lifetime, not persisted meaningfully across steps.
- **`UntrackedValue`**: explicitly excluded from checkpoints (sanitized from writes and
  from nested `Send.arg`). Runtime-only.
- **`DeltaChannel`** (beta): stores incremental deltas with periodic snapshot blobs;
  history reconstructed by walking the checkpoint parent chain — imposes strong
  constraints on saver copy/prune/delete (must preserve ancestor chains).
  Snapshot is force-triggered when accumulated updates reach `snapshot_frequency` OR
  when total supersteps since last snapshot reaches `DELTA_MAX_SUPERSTEPS_SINCE_SNAPSHOT`
  (default **5000**, env-tunable via `LANGGRAPH_DELTA_MAX_SUPERSTEPS_SINCE_SNAPSHOT`,
  defined at `pregel/_internal/_config.py:34`). <!-- [validation-certification-5]: env-var and snapshot-boundary omission corrected; test file `test_delta_channel_supersteps_bound.py` (195 LOC) covers this boundary. -->

---

## 2. Checkpointing contract

Confidence HIGH (read `checkpoint/base/__init__.py`, `_loop.py:_put_checkpoint/put_writes`,
sqlite/postgres schemas, `serde/jsonplus.py`+`_msgpack.py`).

### 2.1 `BaseCheckpointSaver[V]` interface
Sync + async twins for every method:
- `get_tuple(config) -> CheckpointTuple | None` / `aget_tuple`
- `list(config, *, filter, before, limit) -> Iterator[CheckpointTuple]` / `alist`
- `put(config, checkpoint, metadata, new_versions) -> RunnableConfig` / `aput` — persist a
  checkpoint; returns config with the new `checkpoint_id`.
- `put_writes(config, writes: Seq[(channel, value)], task_id, task_path="")` / `aput_writes`
  — persist **pending/intermediate writes** of a single task BEFORE the super-step
  completes. Critical for crash-recovery (§5).
- `delete_thread`, `copy_thread`, `prune(strategy="keep_latest"|"delete")`,
  `delete_for_runs` (+ async) — lifecycle mgmt (DeltaChannel-aware; must preserve chains).
- `get_delta_channel_history(config, channels)` (beta) — walk parent chain, return
  per-channel `{writes, seed}`.
- `get_next_version(current, channel) -> V` — versioning strategy (default int +1; may be
  str/int/float, must be monotonic).
- `config_specs`, `with_allowlist(...)` (derive a msgpack-allowlisted clone).

### 2.2 `Checkpoint` shape (v=4 current, `LATEST_VERSION=4`) <!-- [validation-certification-5]: "v=2 current, LATEST_VERSION=2" was inaccurate. The active runtime in `pregel/_checkpoint.py:23` defines `LATEST_VERSION = 4`; all new checkpoints created by `pregel/_loop.py` use `empty_checkpoint()` from `pregel/_checkpoint.py` (v=4). The value `LATEST_VERSION=2` at `checkpoint/base/__init__.py:811` is in that file's deprecated section ("deprecated utilities used by past versions of LangGraph") and does NOT govern new checkpoint creation. Exhaustive sweep verified the deprecated file, not the active pregel runtime. -->
`{v, id (uuid6, monotonic sortable), ts (ISO8601), channel_values: {chan: snapshot},
channel_versions: {chan: version}, versions_seen: {node: {chan: version}},
updated_channels: [chan] | None}`. `CheckpointMetadata` = `{source:
input|loop|update|fork, step (-1 for first input, 0 first loop), parents: {ns:id}, run_id,
counters_since_delta_snapshot}`.

### 2.3 Serialization format
- **Primary: `ormsgpack`** (msgpack) via `JsonPlusSerializer.dumps_typed` → `(type, bytes)`
  where type is `"msgpack"` or `"json"`. Typed ext-hooks encode (in dispatch order):
  `_DeltaSnapshot`, Pydantic v2 models (any `model_dump`-bearing object → EXT_PYDANTIC_V2),
  Pydantic SecretStr (via `get_secret_value`), Pydantic v1 models (any `dict`-bearing object
  → EXT_PYDANTIC_V1), NamedTuples (via `_asdict`), pathlib.Path, compiled regex (re.Pattern),
  UUID, Decimal, set/frozenset/deque, IPv4/6 addr/iface/network, datetime/date/time/
  timedelta/timezone, ZoneInfo, Enum (any enum subclass → EXT_CONSTRUCTOR_SINGLE_ARG),
  SendProtocol (Send), Python dataclasses, langgraph store `Item`, numpy ndarray (conditional),
  and langgraph types (Command/Interrupt/TimeoutPolicy → @dataclass dispatch;
  StateSnapshot/PregelTask → NamedTuple dispatch; Send → specific SendProtocol check).
  <!-- [validation-corrected pass-4]: original list omitted the dispatch categories for Pydantic
  models v1+v2 (the primary path for user-defined graph state), Enum, dataclasses, NamedTuples,
  _DeltaSnapshot, and store Item. `_msgpack_default` in jsonplus.py dispatches in this order;
  Pydantic v2 is the FIRST real dispatch (after _DeltaSnapshot), making it the primary path for
  user-defined Pydantic graph state. The named langgraph types (Command/Interrupt/TimeoutPolicy)
  are @dataclass and use the generic dataclass dispatch — NOT a special langgraph path.
  A Rust port must replicate all dispatch branches generically. -->
- **Fallback: jsonplus** ("json+" / lc-JSON) via `langchain_core.load.Reviver
  (allowed_objects="core")` — the LangChain serializable protocol (constructor/secret/
  not_implemented tagged objects). Old "json" checkpoints resume via `SAFE_MSGPACK_TYPES`.
- **Security:** `LANGGRAPH_STRICT_MSGPACK=true` restricts deserialization to the
  `SAFE_MSGPACK_TYPES` allowlist (else arbitrary importable callables execute on load —
  explicit RCE warning in source). Optional `pickle_fallback`. `EncryptedSerializer`
  wraps with a cipher. **Port must replicate the allowlist gate as a security invariant.**

### 2.4 Pending-writes semantics (the heart of crash-safety)
- As EACH task finishes, `PregelLoop.put_writes(task_id, writes)` is called. If
  `durability != "exit"`, it immediately `submit()`s `checkpointer.put_writes(config,
  writes, task_id, task_path)` — persisting that task's output linked to the CURRENT
  checkpoint id, BEFORE the super-step's `apply_writes`/new-checkpoint.
- Writes to special channels (`ERROR`, `SCHEDULED`, `INTERRUPT`, `RESUME`) map to NEGATIVE
  indices (`WRITES_IDX_MAP = {ERROR:-1, SCHEDULED:-2, INTERRUPT:-3, RESUME:-4}`) so they
  never collide with regular writes. Special-channel writes dedup last-write-wins.
- `NULL_TASK_ID` writes (graph input, resume values) accumulate rather than replace.
- On resume, `tick()` calls `_reapply_writes_to_succeeded_nodes` (restore successful task
  writes from `checkpoint_pending_writes`, SKIPPING ERROR/RESUME markers so failed/
  interrupted tasks re-execute) and `_resume_error_handlers_if_applicable` (re-route
  previously-failed tasks to their error handlers instead of re-running the node).

### 2.5 Thread / checkpoint namespacing
- `thread_id` (required in `config.configurable`) is the primary key/partition.
- `checkpoint_ns` namespaces subgraphs: `parent_ns + NS_SEP(|) + node`, and a task's own
  ns is `checkpoint_ns + NS_END(:) + task_id`. Nested graphs → nested ns.
- `checkpoint_id` selects a specific checkpoint (for time-travel/fork). `checkpoint_map`
  in config maps ns→id for the whole subgraph tree.

### 2.6 Time-travel & forking
- `get_state(config)` → `StateSnapshot`; `get_state_history(config)` → iterate all
  checkpoints of a thread (via `list`).
- **Fork:** `update_state(config_with_checkpoint_id, values, as_node=...)` writes a NEW
  checkpoint whose `parent` is the specified historical checkpoint → a branch. Metadata
  `source="update"` (or `"fork"`). Resuming from an old `checkpoint_id` re-runs forward
  from that point (replay). `bulk_update_state` batches multiple updates.

---

## 3. Interrupts & human-in-the-loop

Confidence HIGH (read `types.py:interrupt/Command/Interrupt`, `_algo.py:_scratchpad`,
`_loop.py:_suppress_interrupt`).

### 3.1 Dynamic `interrupt(value)` semantics
- Called from inside a node. On first hit with no resume value available, it raises
  `GraphInterrupt(Interrupt(value, id=xxh3(checkpoint_ns)))` — halting the graph and
  surfacing `value` to the caller (emitted as `{"__interrupt__": (Interrupt,)}`).
- **Requires a checkpointer** (state must persist to resume).
- The interrupt `id` is a stable hash of the checkpoint namespace → resume can target a
  specific interrupt.
- Multiple `interrupt()` calls in one node are matched to resume values BY ORDER via a
  per-task `scratchpad.interrupt_counter()`. Resume values are scoped per-task, not shared.

### 3.2 Resume via `Command`
- `Command(resume=value)` or `Command(resume={interrupt_id: value})` resumes. On resume,
  **the node RE-EXECUTES FROM THE START** — all logic before the `interrupt()` runs again;
  prior `interrupt()` calls return their stored resume values instead of raising (idempotent
  replay). Nodes before the interrupt boundary must therefore be side-effect-tolerant or
  guarded. (This is a critical, surprising contract the Rust port must preserve.)
- `Command` also carries `update` (state update), `goto` (node name(s) / `Send`(s) to
  navigate to — dynamic routing), and `graph` (`None`=current, `Command.PARENT`=escape to
  parent graph, raised as `ParentCommand`). `Command` is a `ToolOutputMixin` so tools can
  return it.

### 3.3 Static interrupts
- `interrupt_before=[nodes]|"*"` and `interrupt_after=[nodes]|"*"` at compile/invoke:
  breakpoints gated on "any channel updated since last interrupt" (`should_interrupt`).

### 3.4 Prebuilt HITL schema
`prebuilt/interrupt.py`: `HumanInterrupt{action_request, config: HumanInterruptConfig
(allow_ignore/respond/edit/accept), description}` + `HumanResponse{type:
accept|ignore|response|edit, args}` — the standard review UX payload.

### 3.5 Durability across process restart
Because interrupt state lives in the checkpoint (pending writes include the RESUME/INTERRUPT
markers), an interrupted graph survives a full process restart: reload the checkpointer,
resume with `Command(resume=...)` on the same `thread_id`.

---

## 4. Streaming modes

Confidence HIGH (read `types.py` StreamMode + StreamPart TypedDicts, `stream/_types.py`,
`_loop.py:_emit`). 7 modes; multiple can be requested simultaneously (`stream_mode=[...]`).

| Mode | Emitted when | Payload | Ordering semantics |
|---|---|---|---|
| `values` | after each super-step (`after_tick`), incl. interrupts | full state (`read_channels()` of `output_keys`) + `interrupts` | one per step; emitted only if output channels changed. In functional API, once at end. |
| `updates` | after each step | `{node_name: node_output}`; may add `__interrupt__`, `__metadata__` | one per node-update; if multiple nodes update in a step, emitted separately. |
| `messages` | during node exec | `(BaseMessage/AIMessageChunk, metadata)` | token-by-token LLM streaming; metadata has `langgraph_node/step/triggers`. Taps `langchain_core` callbacks inside nodes. |
| `custom` | when node calls `StreamWriter` | arbitrary user value | node-driven; no-op unless `custom` requested. |
| `checkpoints` | on checkpoint creation | `CheckpointPayload{config, metadata, values, next, parent_config, tasks}` | same shape as `get_state()`. |
| `tasks` | task start & finish | `TaskPayload{id,name,input,triggers}` / `TaskResultPayload{id,name,error,interrupts,result}` | start before run, result after. |
| `debug` | = `checkpoints` + `tasks` | wrapped `DebugPayload` discriminated on `type` (checkpoint/task/task_result) with `step`+`timestamp` | superset for debugging. |

- Every stream part carries `type` (discriminator) and `ns` (namespace tuple → which
  subgraph). The `StreamMux` assigns a monotonic `seq` for total ordering across root
  events (wall-clock `timestamp` is NOT monotonic).
- **v3 `stream_events`** (`stream/_types.py`): a `StreamTransformer` extension framework —
  transformers observe `ProtocolEvent`s and build typed projections (StreamChannels,
  promises). Sync vs async lanes; `before_builtins` ordering hook for content-mutating
  transformers (PII redaction etc.); `schedule()` for decoupled async work. This is the
  modern, extensible streaming layer and is notably complex (`transformers.py` 1,039 LOC,
  `_mux.py` 523 LOC).
- **`astream`/sync `stream` duality:** many transformers require a running event loop and
  fail-fast at registration under sync `stream()`. The Rust port being async-first
  simplifies this (one lane).

---

## 5. Durability / persistence guarantees

Confidence HIGH (read `types.py:Durability`, `_loop.py:put_writes/_put_checkpoint`,
`_suppress_interrupt`).

### 5.1 Three durability modes (`Durability = "sync"|"async"|"exit"`)
- **`sync`**: channel/write changes persisted **synchronously before the next super-step
  starts**. Strongest crash guarantee, highest latency.
- **`async`** (default-ish): changes persisted **asynchronously while the next step
  executes** — `put_writes`/`put` are `submit()`ed as futures and the loop proceeds; the
  futures are joined later. Better throughput; a crash may lose the very last in-flight
  persist.
- **`exit`**: changes persisted **only when the graph exits** (`do_checkpoint` gated on
  `exiting or durability != "exit"`; `put_writes` skipped entirely mid-run). No mid-run
  durability; fastest, no crash recovery within a run.

### 5.2 What survives a crash mid-super-step
- With `sync`/`async` + a checkpointer: **completed tasks' writes are persisted via
  `put_writes` as they finish** (linked to the current checkpoint_id with the task_id).
  On restart, `_reapply_writes_to_succeeded_nodes` restores those, and only INCOMPLETE
  tasks (empty writes, no RESUME) re-execute. So a crash after N of M tasks in a step
  resumes with N done, M-N re-run — **at-least-once node execution for uncommitted tasks,
  exactly-once effect for committed ones** (assuming node side-effects are idempotent
  under replay, which LangGraph does NOT guarantee — the user must ensure it).
- The super-step boundary is the atomic-ish unit: `apply_writes` + `create_checkpoint`
  produce the next checkpoint only after all tasks resolve (or interrupt/error).
- ERROR / ERROR_SOURCE_NODE markers persisted per failed task drive error-handler
  re-routing on resume.

### 5.3 Idempotency expectations
- Task IDs are deterministic hashes → replay produces the same IDs → pending-write matching
  and dedup work. But **node bodies are re-executed on resume/interrupt** (§3.2, §5.2), so
  LangGraph's contract is: *nodes should tolerate re-execution.* No automatic effect
  dedup. This is the single biggest correctness footgun and a first-class port concern.

---

## 6. StateGraph API surface

Confidence HIGH (read `graph/state.py` signatures + `types.py`).

### 6.1 Builder (`StateGraph(state_schema, context_schema?, input_schema?, output_schema?)`)
- **`add_node`** (5 overloads): by callable (name inferred), by (name, callable), with
  `RunnableCallable`, plus options: `metadata`, `input_schema`, `retry_policy`,
  `cache_policy`, `destinations` (declared static routing targets for viz), `defer`
  (run after all other triggered nodes — join), `error_handler` (node-level recovery →
  `NodeError` injected). Node fn signature: `(state) | (state, config) | (state,
  runtime)` → state-update dict / `Command` / `None`.
- **`add_edge(start, end)`**: static edge; `start` may be a list (all-of fan-in). `START`
  and `END` sentinels.
- **`add_conditional_edges(source, path_fn, path_map?)`**: dynamic routing; `path_fn(state)`
  → node name(s) / `Send`(s) / `END`. Backs branching and Send fan-out.
- **`add_sequence([...])`**: sugar for a linear chain.
- **`set_entry_point`/`set_conditional_entry_point`/`set_finish_point`**: START/END wiring.
- **`compile(checkpointer?, store?, interrupt_before?, interrupt_after?, cache?,
  name?, ...)`** → `CompiledStateGraph` (a `Pregel`). Validates the graph
  (`_validate`), derives channels from the state schema.

### 6.2 State schema → channels (the reducer inference) — MED/HIGH
- Each state-schema key becomes a channel. Plain key → `LastValue`. `Annotated[T,
  reducer]` → `BinaryOperatorAggregate(T, reducer)` (or a custom channel if the annotation
  IS a `BaseChannel`). `add_messages` is the canonical reducer for message lists
  (dedup/merge by id, handle `RemoveMessage`). Managed values (e.g. `RemainingSteps`,
  `is_last_step`) are runtime-injected pseudo-channels.
- Separate **input_schema / output_schema** allow the external I/O shape to differ from
  internal state (filtered channel projection).

### 6.3 Send API (dynamic fan-out / map-reduce)
- A `path_fn` returning `[Send("worker", arg_i) for ...]` pushes N tasks into the `TASKS`
  Topic; each runs `worker` with its own `arg` (which may differ from graph state) in the
  next super-step, in parallel. Results fan back in via reducer channels. `Send.arg` is
  sanitized of `UntrackedValue`s before checkpointing.

### 6.4 Subgraphs
- A compiled graph can be `add_node`'d into a parent (it implements `PregelProtocol`).
  Subgraph gets its own `checkpoint_ns`; its checkpoints nest under the parent thread.
  `Checkpointer` type per-subgraph: `True` (own persistence), `False` (disabled), `None`
  (inherit parent). `Command(graph=Command.PARENT)` escapes a subgraph to the parent.

### 6.5 Functional API (`func/`)
- `@task` (a unit of work, cached/retried) + `@entrypoint(checkpointer=...)` build a Pregel
  graph implicitly; `entrypoint.final` returns value + saves separate state. Same runtime,
  imperative surface.

---

## Cross-cutting behavioral notes for D9
1. **BSP isolation is the core invariant**: nodes never see each other's writes within a
   step; all merging happens in `apply_writes` via channel reducers. The Rust model must
   preserve write-isolation + deterministic merge order regardless of execution shape.
2. **Replay-on-resume is a semantic, not an optimization**: interrupts and crash-recovery
   BOTH re-run node bodies. Any Rust scheduler must reproduce deterministic task IDs and
   the "skip committed / re-run uncommitted" reapply logic exactly.
3. **Durability mode is a first-class knob** with three tiers; the persistence layer must
   support fire-and-persist-per-task (sync), background-persist (async), and defer-to-exit.
4. **The checkpointer trait is storage-shape-polymorphic** (single-blob sqlite vs
   normalized-blob postgres vs shallow) — the abstraction must not leak either shape.
5. **Two checkpoint-write channels of durability**: `put` (whole checkpoint at step
   boundary) and `put_writes` (per-task intermediate). Both need sync+async paths.
