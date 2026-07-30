---
artifact: comparative/adk-rust/behavioral-intent
pass: A1 — DEEP on framework heart
crates: adk-core, adk-agent, adk-model, adk-tool, adk-runner, adk-session
constraint: D16 Rust-blindness — behavioral contracts on production-grade merit only
created: 2026-07-13
status: observe-only
---

# adk-rust — Behavioral Intent of the Core Crates (Pass A1)

Evidence is cited by function/type name + behavioral anchor (per TD-VSDD-091), not line
numbers. Confidence: HIGH = grounded in a test assertion; MEDIUM = grounded in code;
LOW = inferred from docs.

## 1. adk-core — the abstraction hub

### Trait design & object-safety choices
- **`Agent`** (`#[async_trait] Send + Sync`): `name()`, `description()`, `sub_agents() -> &[Arc<dyn Agent>]`,
  `async run(Arc<dyn InvocationContext>) -> Result<EventStream>`. Object-safe by design;
  every agent is a trait object. `sub_agents()` returns a slice of `Arc<dyn Agent>`, encoding
  the composite/tree structure at the trait level — multi-agent is a first-class core concept,
  not a runtime bolt-on.
- **`Llm`** (`#[async_trait]`): `name()`, `async generate_content(LlmRequest, stream: bool) -> Result<LlmResponseStream>`,
  plus two defaulted capability-probe methods: `schema_adapter() -> &dyn SchemaAdapter`
  (default `GenericSchemaAdapter`) and `uses_interactions_api() -> bool` (default false).
  The `bool stream` parameter unifies streaming and non-streaming under one method returning
  a stream — a non-streaming call yields a single-item stream.
- **`Tool`** (`#[async_trait]`): rich defaulted surface — `declaration()` (builds the provider
  JSON tool decl from name/description/parameters_schema/response_schema), `enhanced_description()`,
  `is_long_running()`, `is_builtin()`, `required_scopes() -> &[&str]`, `is_read_only()`,
  `is_concurrency_safe()`, and the single required `async execute(Arc<dyn ToolContext>, Value) -> Result<Value>`.
  The read-only + concurrency-safe flags are consumed by `ToolExecutionStrategy::Auto`.
- **Streaming shape**: `EventStream = Pin<Box<dyn Stream<Item = Result<Event>> + Send>>` and
  `LlmResponseStream = Pin<Box<dyn Stream<Item = Result<LlmResponse>> + Send>>`. Every result
  item in a stream is a `Result`, so mid-stream failures are first-class (contrast with a
  stream that terminates silently). Used with `async_stream::stream!` in the runner.

### Context trait hierarchy (a supertrait ladder)
`ReadonlyContext` → `CallbackContext: ReadonlyContext` → `InvocationContext: CallbackContext`,
with `ToolContext: CallbackContext` as a sibling branch. This layering means a function that
only needs identity takes `&dyn ReadonlyContext`; a callback takes `CallbackContext`; the
agent body takes the full `InvocationContext`. Progressive capability disclosure at the type
level. `ReadonlyContext` also provides typed-identity accessors (`try_app_name()`,
`try_user_id()`, `try_session_id()`, `try_invocation_id()`, `try_identity()`,
`try_execution_identity()`) that parse raw strings into validated newtypes.

### State model & invariants (HIGH)
- **`validate_state_key`** enforces: non-empty, ≤256 bytes (`MAX_STATE_KEY_LEN`), no `/`, `\`,
  `..`, or null bytes. Directly tested for path-traversal (`../etc/passwd`, `foo/bar`,
  `foo\bar`, `..`) and null-byte injection. This is a **security invariant** on the state
  keyspace — states are persisted to SQL/Redis/filesystem backends, so key sanitization
  matters. Confidence HIGH (`test_validate_state_key_path_traversal`, `test_validate_state_key_null_byte`). <!-- [comparative-cert-17] C17-01: `_null_byte` is an editorial `_`-prefix shorthand, not a verbatim function name; actual test: `test_validate_state_key_null_byte` at adk-core/src/context.rs:980 -->
- **State scope prefixes**: `user:` (persists across sessions), `app:` (application-wide),
  `temp:` (cleared each turn) — as public consts `KEY_PREFIX_USER/APP/TEMP`.

### Error taxonomy discipline (HIGH — strongest single artifact in the core)
`AdkError` is a **struct**, not an enum (migrated from an enum in 0.4.x — migration docs
inline). Two orthogonal dimensions:
- `component: ErrorComponent` (14 variants: Agent/Model/Tool/Session/Artifact/Memory/Graph/
  Realtime/Code/Server/Auth/Guardrail/Eval/Deploy) — "the origin, not the boundary it surfaces
  through" (explicit doc guidance).
- `category: ErrorCategory` (10 variants: InvalidInput/Unauthorized/Forbidden/NotFound/
  RateLimited/Timeout/Unavailable/Cancelled/Internal/Unsupported).
Plus: `code: &'static str` (machine code e.g. `"model.openai.rate_limited"`), `message: String`,
`retry: RetryHint { should_retry, retry_after_ms, max_attempts }`, `details: Box<ErrorDetails>`
(upstream_status_code, request_id, provider, metadata map), and a private boxed `source`.
Behavioral contracts:
- **BC: retryability derives from category by default.** `RetryHint::for_category` sets
  `should_retry = true` for RateLimited/Unavailable/Timeout, false otherwise; overridable via
  `with_retry`. Tested exhaustively across all 10 categories (`test_retryable_categories_default_true`,
  `test_non_retryable_categories_default_false`). Confidence HIGH. <!-- [comparative-cert-17] C17-01: `_non_retryable_categories_default_false` is an editorial shorthand; actual test: `test_non_retryable_categories_default_false` at adk-core/src/error.rs:668 -->
- **BC: category → HTTP status is a total mapping** (400/401/403/404/429/408/503/499/500/501).
  Tested for all 10 (`test_http_status_code_mapping`). Confidence HIGH.
- **BC: `to_problem_json` emits RFC-7807-style Problem Details** with camelCase keys and null
  optionals when absent. Confidence HIGH.
- **BC: Send+Sync guaranteed** via a `const _` compile-time assertion block AND a runtime test.
- Legacy constructors (`AdkError::model/agent/tool/...`) produce `*.legacy` codes for migration;
  a test asserts every legacy code ends with `.legacy`.
- Custom `Debug` on `AdkError` renders `source` via `format_args!` (avoids requiring `Debug`
  on the boxed source). `Display` is `"{component}.{category}: {message}"`.

### Other notable core contracts
- **`SchemaAdapter`** trait normalizes raw MCP JSON Schema per-provider; default
  `normalize_tool_name` truncates >64-byte names at a UTF-8 boundary. Separation of concern:
  MCP toolsets return schemas verbatim; each model adapter normalizes at request time.
- **`ToolConfirmationPolicy`** (Never/Always/PerTool(BTreeSet)) — built-in HITL authorization;
  `requires_confirmation(name)` + `with_tool()` builder. Emits `ToolConfirmationRequest` events.
- **`ToolConcurrencyConfig`** — global `max_concurrency`, `per_tool` overrides, and a
  `BackpressurePolicy` (Queue default / Fail-fast). Enforced via `tool_concurrency` semaphore module.
- **`RunConfig`** — 11-field run configuration with a fluent `RunConfigBuilder` and a
  `max_transfer_depth` guard (default 10) preventing infinite agent-transfer loops. <!-- [comparative-cert-9] CORRECTION: "12-field" → 11; `awk '/^pub struct RunConfig/,/^\}/' context.rs | grep "^    pub " | wc -l` = 11 (streaming_mode, tool_confirmation_decisions, cached_content, transfer_targets, parent_agent, auto_cache, history_max_events, tool_concurrency, record_payloads, trace_payload_max_bytes, max_transfer_depth); off-by-one in original claim -->

## 2. adk-model — provider abstraction (27.9k LOC, 505 unit tests)

- **`ModelProvider`** enum (Gemini/Openai/Anthropic/Deepseek/Groq/Ollama) carries metadata as
  `const fn`: `as_str`, `default_model`, `env_var`, `alt_env_var` (Gemini has GEMINI_API_KEY
  fallback), `requires_key` (false only for Ollama), `display_name`. `FromStr` round-trips
  (tested). This is the canonical provider registry.
- **Retry subsystem** (`retry.rs`, 408 LOC): `RetryConfig` (enabled, max_retries=3,
  initial_delay=250ms, max_delay=5s, backoff_multiplier=2.0) with a fluent builder.
  `execute_with_retry` / `execute_with_retry_hint` are generic combinators over any
  `FnMut() -> Future<Result<T>>` with an injected `classify_error` predicate.
  - **BC: retry delay precedence** = (1) structured `AdkError.retry.retry_after()`, then
    (2) server `retry-after` hint (first attempt only), then (3) exponential backoff. Tested.
  - **BC: HTTP 529 (overloaded) is retryable** — `is_retryable_status_code` includes 408/429/
    500/502/503/504/529; `is_retryable_error_message` scans for RATE LIMIT/OVERLOADED/
    RESOURCE_EXHAUSTED/DEADLINE_EXCEEDED/etc. End-to-end 529 retry test present. Confidence HIGH.
  - **BC: disabled config short-circuits** to a single attempt (tested).
  - Exponential backoff has a **timing-based test** asserting gap2 ≥ 2×gap1 with tolerance —
    genuine behavioral verification, not just call-count.
- `LlmRequest`/`LlmResponse`/`GenerateContentConfig`/`UsageMetadata` are serde types with
  extensive `skip_serializing_if` discipline and an `extensions` escape hatch
  (`serde_json::Map`) for provider-specific request options keyed by provider namespace.
  `UsageMetadata` tracks cache-read/cache-creation/thinking/audio-in/audio-out tokens + cost
  + is_byok + provider_usage. Round-trip serde tests present for citations, provider_metadata,
  extensions.
- 10 provider module families (openai has 13 sub-files incl. responses_client, background,
  conversations, ws_transport, pricing <!-- [comparative-cert-6] CORRECTION: "14 sub-files" → 13; find adk-model/src/openai -name "*.rs" | wc -l = 13 (background, client, compaction, config, conversations, convert, file_input, mod, pricing, responses_client, responses_convert, schema_adapter, ws_transport); off-by-one in original claim -->). openrouter is a full sub-provider with discovery,
  chat vs responses conversion, streaming. `mock.rs` provides a test double.

## 3. adk-tool — tool ecosystem (10.8k LOC, 197 unit tests)

- Re-exports and extends core `Tool`/`Toolset`/`ToolContext`. Concrete tool types:
  `FunctionTool`, `AgentTool` (wrap an agent as a tool), `StatefulTool`.
- **MCP client** is a first-class subsystem (`mcp/`): `manager/` (config, entry, status,
  toolset_impl), `auth`, `elicitation`, `http`, `reconnect`, `task`, `toolset`. Reconnection
  logic and elicitation (MCP interactive prompts) are implemented — mature MCP support.
- Builtin server-side tools: google_search, url_context, web_search, load_artifacts, plus
  provider-specific (anthropic, openai, gemini_extra) and `exit_loop`, `bypass`.
- Code-execution tools (python/javascript/frontend). Vendor toolsets: bigquery, slack, spanner.
- `memory/` submodule: load_memory + preload_memory tools with format helpers.
- `toolset/compose.rs` — toolset composition.

## 4. adk-agent — agent implementations (9.4k LOC)

- **`LlmAgent`** (`llm_agent.rs`, 2,712 lines — the largest single file; would exceed
  pregolya's 750-line hard gate) is the flagship agent: owns the LLM turn loop, tool
  dispatch, transfer logic, output_key → state_delta emission, guardrails, compaction hooks,
  and the `transfer_to_agent` tool injection with `disallow_transfer_to_parent/peers` policy.
- **Workflow agents** (`workflow/`): `SequentialAgent`, `ParallelAgent` (with
  `shared_state_context` for cross-agent coordination via `SharedState`), `LoopAgent` (466 LOC,
  iteration with exit conditions), `ConditionalAgent` + `LlmConditionalAgent` (routing).
- **Ambient agents** (`ambient/`): event-sourced triggers — `cron_trigger`, `file_watch_trigger`,
  `webhook_trigger` behind an `event_source` abstraction. Agents that wake on external events.
- `compaction.rs`, `guardrails.rs`, `skill_shim.rs`, `tool_call_markup.rs`, `custom_agent.rs`.

## 5. adk-runner — execution runtime (6.2k LOC, 127 unit + 12 test files/4,216 LOC)

The `Runner::run` method (~800 lines inside one `async_stream::stream!`) is the behavioral
spine. Observed contracts:
- **BC: typestate builder enforces required fields.** `Runner::builder()` returns a builder
  parameterized on `NoAppName/NoAgent/NoSessionService` phantom states; `build()` is only
  callable once all three are set — compile-time construction safety. Confidence MEDIUM (code).
- **BC: session get-or-create then agent resolution.** `find_agent_to_run` walks recent session
  events in reverse to resume the last responding agent (honoring transfer), defaulting to root.
- **BC: state_delta applied to mutable session immediately** as events stream, so downstream
  sequential agents read fresh state via `session().state().get()`. Explicitly commented as
  "the key fix for state propagation between sequential agents."
- **BC: partial streaming chunks are NOT persisted** — only `partial == false` events are
  appended to the session service (chunks share an event ID; persisting each would violate the
  PK constraint). The final chunk carries accumulated content.
- **BC: multi-hop transfer loop with depth guard.** `transfer_to_agent` actions drive a loop
  computing `(parent, peers)` transfer targets per hop; `DEFAULT_MAX_TRANSFER_DEPTH = 10`
  (overridable) breaks runaway chains with a warning.
- **BC: cooperative cancellation & interrupt API.** Per-session `CancellationToken` registered
  in `active_sessions`; a global token is combined with the session token via spawned watchers.
  `interrupt(session_id)` cancels mid-stream; a `SessionCleanup` Drop guard removes the token
  even on early return. `active_session_ids()` lists running sessions.
- **BC: cache lifecycle is non-fatal.** Context-cache create/delete failures log
  `tracing::warn!` and proceed without cache — degradation without failure, but surfaced.
- **BC: three compaction strategies** — background events-compaction (interval + overlap window),
  intra-invocation compaction (pre-run token estimate), and context-compaction (token-budget
  overflow with retry-on-token-limit-error, feature-gated). All log outcomes.
- Plugin hooks (`run_before_run`, `run_on_user_message`, `run_on_event`, `run_after_run`) are
  invoked at every boundary and `run_after_run` fires on every early-return error path — no
  leaked lifecycle. Feature-gated (`plugins`).

## 6. adk-session — persistence (8.1k LOC, 50 unit + 13 test files)

- **`SessionService`** trait: create/get/list/delete/append_event, plus typed-identity variants
  (`get_for_identity`, `delete_for_identity`, `append_event_for_identity`) that default-delegate
  but let composite-key backends override. Preferred addressing is the full
  `AdkIdentity (app_name, user_id, session_id)` triple — "eliminating ambiguity when a bare
  session_id is not globally unique."
- **BC: rewind / time-travel.** `rewind(session_id, target_event_id)` and `rewind_steps(n)`
  remove subsequent events and rebuild state from remaining events' state deltas. Default impls
  return a structured "not supported by this backend" `AdkError::session` — honest capability
  signaling rather than silent no-op.
- **BC: GDPR erasure.** `delete_all_sessions(app, user)` for right-to-erasure; default errors.
- **BC: health_check** for k8s readiness probes; default Ok (in-memory).
- **8 backends**: inmemory, sqlite, postgres, redis, mongodb, neo4j, firestore, vertex — plus
  `encrypted.rs` + `encryption_key.rs` (an encryption wrapper over any backend) and
  `migration.rs`. Request DTOs (`CreateRequest`, `GetRequest`, `ListRequest`, `DeleteRequest`,
  `AppendEventRequest`) each expose `try_identity()` typed accessors.

## Event model (adk-core::event) — cross-cutting
`Event` embeds `LlmResponse` via `#[serde(flatten)]` (mirrors adk-go), carrying id/timestamp/
invocation_id/branch/author + `EventActions` (state_delta, artifact_delta, skip_summarization,
transfer_to_agent, escalate, tool_confirmation(+decision), compaction, and a graph `route`
field). `is_final_response()` is a genuine state predicate: final iff skip_summarization OR
long_running_tool_ids present OR (no function calls AND no function responses AND not partial
AND no trailing code-exec result). 9 dedicated tests cover the truth table <!-- [comparative-cert-5] CORRECTION: stale sibling of [comparative-sweep] correction in ANALYSIS-STATE.md line 25; SWEEP-test-deps noted the ANALYSIS-STATE fix but did not propagate to behavioral-intent.md; 9 fn test_is_final_response_* confirmed by grep in adk-core/src/event.rs --> including the
trailing-function-response edge and text-after-response edge. Confidence HIGH.

---

# Pass A2 — STATE / PERSISTENCE / ORCHESTRATION cluster behavioral intent

Deep read: `adk-graph::{executor, state, checkpoint, delta, interrupt, time_travel, functional/
typed_reducer}`, `adk-session::{service, encrypted, postgres, sqlite}`, `adk-memory::{service,
adapter, inmemory}`, `adk-artifact::service`. Mapped against `.factory/semport/graph/
behavioral-intent.md` (LangGraph §1–§6). Confidence tags as before.

## 7. adk-graph execution model — STRUCTURAL comparison to Pregel super-steps

The docstrings say "Pregel super-steps," but the mechanism is an **edge-following graph walk with
a per-step isolated apply phase** — NOT LangGraph's channel-version-triggered BSP. Point-by-point
against semport/graph §1:

### 7.1 Super-step cycle (`PregelExecutor::run` / `execute_super_step`) — MED/HIGH
- **Plan.** Next nodes come from `graph.get_next_nodes(executed_nodes, state)` — pure edge/
  conditional-edge following. There is NO `versions_seen`, NO `channel_versions`, NO
  "triggered iff channel written since node last saw it." LangGraph's version-based trigger
  (semport/graph §1.1 step 1) is absent; this is classic dataflow scheduling, not Pregel triggering.
- **Run.** All `pending_nodes` execute concurrently via `stream::iter(futures).buffer_unordered(n)`.
  Each node gets `NodeContext::new(self.state.clone(), …)` — a frozen snapshot. **Write isolation
  holds** (nodes cannot see each other's writes mid-step). Confidence HIGH (code + tests).
- **Apply.** After all nodes resolve, `all_updates` is folded through `StateSchema::apply_update`
  per (key,value). Confidence HIGH.
- **Checkpoint.** `save_checkpoint` persists the whole state after the step. Confidence HIGH.

### 7.2 Determinism — the critical divergence (maps to semport/graph §1.2, cross-cutting note 1)
- **Update ORDER is nondeterministic.** `buffer_unordered` yields in completion order, so
  `all_updates` (and thus reducer folding) is timing-dependent. LangGraph sorts tasks by
  `task_path_str(path[:3])` for a deterministic apply order. For `Reducer::Append`/`Custom`
  (non-commutative) two runs can diverge. **This breaks the D9 "deterministic merge order
  regardless of execution shape" invariant.** (patterns-observed P-28.) Confidence HIGH (code).
- **No content-addressed task IDs.** LangGraph's `xxh3_128(checkpoint_id ‖ ns ‖ step ‖ name ‖
  kind ‖ triggers)` (semport/graph §1.2) has no analog. Nodes are keyed by name only; there is no
  replay-idempotency key or pending-write matching.
- **No "one writer per step" guard.** `Reducer::Overwrite` silently takes the last write in
  nondeterministic order; LangGraph's `LastValue` raises `InvalidUpdateError` on >1 write/step
  (semport/graph §1.4). adk has no concurrent-write detection at all.

### 7.3 Write isolation — the part that DOES match (maps to semport/graph §1.1 step 3, note 1)
Per-node `state.clone()` + deferred `apply_writes`-equivalent gives true BSP write isolation.
This half of the invariant is correctly implemented (patterns-observed P-23). Confidence HIGH.

### 7.4 Halting & recursion (maps to semport/graph §1.3)
- Natural halt: `pending_nodes` empty. Recursion guard: `step >= config.recursion_limit` →
  `GraphError::RecursionLimitExceeded` (test `test_recursion_limit`, limit 10). No env-driven
  default like LangGraph's 10007; the limit is a per-config field. Confidence HIGH.
- **Deferred nodes / fan-in join** (`filter_deferred_nodes`, `FanInTracker`): a genuine addition —
  a deferred node waits until all upstream paths complete, with an optional `fan_in_timeout` that
  proceeds on partial results (with `tracing::warn!`) or errors `FanInTimedOut` if zero arrived.
  This is the `defer=True`/`NamedBarrierValue` join analog (semport/graph §1.4, §6.1), implemented
  as scheduler state rather than a channel. Confidence HIGH.

### 7.5 Replay-on-resume (maps to semport/graph §1.2, §5.2, cross-cutting note 2)
`try_resume_from_checkpoint` restores `state`/`pending_nodes`/`step` and merges input on top, then
re-runs `pending_nodes`. Because checkpoints are whole-state at step boundaries, resume re-runs an
entire step's pending nodes. There is NO `_reapply_writes_to_succeeded_nodes` (skip committed,
re-run uncommitted) — adk has no per-task write records to reapply. Coarser than LangGraph's
"exactly-once for committed tasks, at-least-once for uncommitted" (semport/graph §5.2). Confidence
HIGH.

**Structural verdict (observation, not conclusion):** adk-graph reproduces BSP *write isolation*
but not BSP *deterministic ordering*, *version-triggered scheduling*, *content-addressed task
identity*, or *per-task replay*. It is a parallel edge-walker with a barrier-apply phase.

## 8. Durability guarantees — what actually survives a crash

### 8.1 adk-graph checkpointing (maps to semport/graph §2, §5) — HIGH
- **Granularity:** whole-state snapshot + `pending_nodes` + `step`, saved AFTER each super-step.
  No `put_writes`/per-task intermediate persist; no `ERROR/RESUME/INTERRUPT` markers; no
  `sync|async|exit` durability modes. (patterns-observed P-29.)
- **Atomicity:** `SqliteCheckpointer::save` is a single-row INSERT — atomic per checkpoint, but
  there is no transaction spanning state-mutation + checkpoint (state is in-memory, so N/A) and no
  two-phase put/put_writes. Interrupt path also saves a checkpoint before returning `Interrupted`.
- **Crash-recovery contract:** crash mid-step ⇒ whole step lost ⇒ on restart all `pending_nodes`
  re-execute (at-least-once for the entire step; no per-task credit). Node side-effect idempotency
  is the user's problem, same caveat as LangGraph §5.3 but at coarser grain.
- **"Latest" selection:** `ORDER BY created_at DESC` (wall-clock) with UUIDv4 ids — NOT a monotonic
  logical clock (patterns-observed P-31; contrast LangGraph uuid6 §2.2). Ambiguous under same-tick
  writes / clock skew.
- **Delta compression:** `DeltaCheckpointer` wrapper (P-22/P-25) gives linear storage via
  whole-state `MapDelta` + periodic full snapshots; round-trip `Diff` contract property-tested.

### 8.2 adk-session persistence (maps to semport/graph §2 durability shape, §5) — HIGH
- **Atomicity (STRONG):** every SQL backend wraps create/append_event in `pool.begin()`…
  `tx.commit()` across `sessions`/`app_states`/`user_states`/`events`; error paths RAII-rollback.
  An event and its state delta commit together — the atomicity property adk-graph lacks
  (patterns-observed P-20). `temp:`-keys stripped pre-persist. Confidence HIGH.
- **Rewind / time-travel semantics** (`sqlite::rewind`, `rewind_steps`; default = structured
  "not supported" error): transactional; deletes events with `timestamp > target` PLUS a
  same-timestamp `id != target` sweep, then rebuilds state by replaying remaining events' state
  deltas in `ORDER BY timestamp`. **Timestamp-ordered, not sequence-ordered** — same fragility as
  §8.1 (patterns-observed P-31). Only `inmemory` + `sqlite` implement rewind; postgres/redis/mongo/
  neo4j/firestore/vertex fall to the default error (honest capability signaling, per A1 P-12).
  Confidence HIGH (grep of `async fn rewind` = inmemory, sqlite, service-default only).
- **Encryption at rest** (`EncryptedSession`, patterns-observed P-21/P-32): AES-256-GCM AEAD over
  the state map only, key rotation via previous_keys + lazy re-encrypt. **Event content is NOT
  encrypted** (append_event/list delegate through); re-encrypt errors are swallowed (`let _ =`).
  Confidence HIGH.

### 8.3 Graph fork vs LangGraph fork (maps to semport/graph §2.6) — HIGH
`TimeTravelHandle::fork_at(step, new_thread_id)` COPIES the checkpoint under a new thread_id with a
fresh UUID — fork-by-copy, not parent-pointer branching. LangGraph forks by writing a new
checkpoint whose `parent` points at the historical checkpoint (a lineage tree). adk loses the
branch lineage. `replay(from,to)` despite its docstring ("re-executes") merely filters and returns
stored states — a doc/impl mismatch worth flagging. `resume_from` genuinely re-invokes. Confidence
HIGH (code).

## 9. Memory model vs Domain C (OpenClaw) personal memory — MED

- **Trait surface:** `MemoryService` = `add_session`/`search` required; `add_entry`,
  `delete_user` (GDPR), `delete_session`, `delete_entries`, project-scoped twins, `delete_project`
  defaulted (mostly to "not implemented" errors — A1 P-12 honest-default, but see A1 P-19 risk).
- **Scope model:** `search(project_id=None)` → global only; `search(project_id=Some(p))` →
  global ∪ project p; `user_id`+`app_name` always partition (patterns-observed P-26). Default
  in-memory search is **keyword intersection** (`has_intersection(words, query_words)`), not
  embeddings; `min_score`/`limit` supported; embedding + vector backends exist (postgres/neo4j/
  redis/mongodb + `embedding.rs`) but are not the default.
- **Domain C mapping:** OpenClaw personal memory wants *per-user, durable, private* recall.
  adk gives firm user partitioning (good) and cross-project isolation (good), but its "global tier
  bleeds into every project view" default is the opposite of "strictly personal." For Domain C,
  pregolya would either disable the global tier or model personal memory as a user-private scope
  with NO global overlay. GDPR erasure (`delete_user`) is a first-class method — aligned with a
  personal-memory right-to-be-forgotten requirement. `MemoryServiceAdapter` binds
  `(app_name,user_id,project_id?)` at construction to satisfy `adk_core::Memory::search(&str)` —
  a clean DI seam, but `search_in_project` is a real override here (not the A1 P-19 silent-global
  fallback), so THIS adapter is safe; the risk is only for backends that forget to override.

## 10. Test-as-spec quality for the cluster (maps to test-inventory A2) — HIGH

- **adk-graph:** 14 integration files, 262 test fns crate-wide [comparative-sweep: recount from `#[test]`+`#[tokio::test]` annotations; claimed 208, verified 262], 8 `*_property_tests.rs`. Property
  coverage on switch routing, error modes, cache, deferred fan-in, delta round-trip, time-travel,
  timeout, workflow schema. `delta.rs` alone carries ~40 in-crate unit tests incl. the
  `apply(diff)==new` round-trip across append/modify/remove/unicode/multiline. This is genuine
  executable specification for the storage layer.
- **Gap vs claims:** the property suite validates *storage and routing* laws thoroughly, but the
  determinism gap (P-28) is NOT caught — there is no test asserting reducer-apply order is
  independent of node completion order (there cannot be, because it isn't). The interrupt/resume
  replay contract (P-30) is not tested because it does not exist. So the tests faithfully spec what
  the engine does; they do not spec the LangGraph invariants the engine omits.
- **adk-session:** transactional writes + rewind are covered; encryption round-trip + rotation are
  tested. The "events not encrypted" boundary (P-32) is not asserted either way.

## 11. A1 open items resolved in this cluster
- **P-16 (provider duplication):** out of cluster — remains open for the provider deep pass.
- **P-18 (anyhow leak):** within this cluster, NO anyhow in public signatures — adk-graph uses
  `GraphError`/`Result`, adk-session/memory/artifact use `adk_core::Result`. Cluster is clean;
  the workspace-wide `anyhow` verdict still needs the core/CLI grep (out of cluster).
- **A1 "adk-graph 14 integration test files (3,185 LOC) — verify strength":** CONFIRMED STRONG —
  property-test-dominant (patterns-observed P-24).
- **A1 P-12/P-19 (defaulted capabilities masking behavior):** for MEMORY specifically, the
  in-tree `MemoryServiceAdapter` DOES override `search_in_project`/`add_to_project` (no silent
  global fallback), so the A1 P-19 cross-project-bleed risk is NOT realized in the shipped adapter;
  it remains a latent risk only for third-party `MemoryService` impls that forget to override.
  Session `rewind` default-errors (honest) rather than silent no-op — A1 P-12 mitigation confirmed.
- **New open items (A2):** (a) does adk-graph's checkpointer ever integrate with adk-session, or
  are they permanently disjoint (P-27)? — confirmed disjoint at v1.0.0. (b) `replay()` doc/impl
  mismatch (claims re-execution, filters stored states) — flag for their maintainers, informative
  for pregolya. (c) postgres/redis/etc rewind unimplemented — is rewind a first-class contract or
  sqlite-only convenience? Their default-error says "not a universal contract."

## State Checkpoint
```yaml
pass: A2
scope: behavioral-intent (state/persistence/orchestration cluster)
status: complete
files_read_deep: [adk-graph/{executor,state,checkpoint,delta,interrupt,time_travel,
                  functional/typed_reducer}, adk-session/{service,encrypted,postgres,sqlite},
                  adk-memory/{service,adapter,inmemory}, adk-artifact/service]
a1_scope: behavioral-intent (6 core crates)
timestamp: 2026-07-13
```

---

# Pass A3 — SERVER / PROTOCOL / AUTH behavioral intent

Deep scope: `adk-server` (REST + A2A v1), `adk-auth`, `adk-managed::usage`, `adk-telemetry`.
Evidence by function/type + behavioral anchor (TD-VSDD-091). Confidence: HIGH = test-grounded,
MED = code-grounded, LOW = inferred. D16 Rust-blindness — observe only.

## 12. adk-server run model & session lifecycle — MED

- **Composition root:** `create_app_with_a2a(config, a2a_base_url)` (and `ServerBuilder`) build
  one axum `Router`. `ServerConfig` carries `Arc<dyn AgentLoader>`, `Arc<dyn SessionService>`,
  optional `ArtifactService`/`Memory`/`CacheCapable`/`EventsCompactionConfig`/`ContextCacheConfig`/
  `AdkSpanExporter`/`RequestContextExtractor`. Arc-DI throughout (aligned with CLAUDE.md Arc-DI).
- **Run endpoint:** `POST /api/run/{app}/{user}/{session}` (and `/run_sse` with session in body) →
  `controllers::runtime::run_sse` streams an SSE event feed. The run is addressed by the
  `(app_name,user_id,session_id)` triple; there is no first-class `run_id` resource in core (the
  `background` feature adds a thin one). Confidence MED (code).
- **Health contract:** `GET /api/health` calls `health_check()` on session (+ optional memory,
  artifact) services; returns 200 `healthy` iff session is healthy AND memory/artifact are not
  `unhealthy` (a `not_configured` optional service does not fail health). Structured per-component
  JSON. Maps to k8s readiness. Confidence HIGH (deterministic handler).
- **Graceful shutdown:** `ShutdownHandle` combines Ctrl-C / SIGTERM / programmatic /
  `POST /api/shutdown` via a `CancellationToken`; `signal()` feeds
  `axum::serve().with_graceful_shutdown()`. Clean drain contract. Confidence MED.

## 13. A2A v1.0.0 behavioral contracts (11 JSON-RPC operations) — HIGH (test-grounded)

`RequestHandler` is the shared dispatch layer for both JSON-RPC (`POST /a2a`) and REST transports.

- **BC: message_send creates→works→completes a task, running the real agent.** With a
  `RunnerConfig`, `message_send` ensures a session (`a2a-{context_id}` user, `context_id` session),
  converts A2A parts → `adk_core::Content`, builds a `Runner` (threading every optional service),
  runs it, concatenates response text, and records it as an `Artifact`; on agent error it
  `fail_task`s and returns the failed task. State machine: SUBMITTED→WORKING→COMPLETED (or FAILED).
  Confidence HIGH (`message_send_creates_and_completes_task`, resume/idempotency tests).
- **BC: messageId idempotency.** An in-memory `idempotency_map: RwLock<HashMap<messageId,taskId>>`
  returns the existing task for a repeated messageId; stale entries (task since deleted) are evicted
  and reprocessed. Confidence HIGH (`message_send_idempotent_same_message_id`). **Concern:** the map
  is in-memory + unbounded + non-durable (patterns P-43) — idempotency and resume break on restart.
- **BC: INPUT_REQUIRED multi-turn resume.** A follow-up whose `contextId` maps (via
  `find_task_by_context`, which excludes terminal states) to an `InputRequired` task RESUMES that
  task (Working→Completed) rather than forking a new one; terminal-context or no-context → new task.
  Confidence HIGH (`message_send_resumes_input_required_task`, `message_send_creates_new_task_for_terminal_context`). <!-- [comparative-cert-17] C17-01: `_creates_new_task_for_terminal_context` is an editorial shorthand; actual test: `message_send_creates_new_task_for_terminal_context` at adk-server/src/a2a/v1/request_handler.rs:1176 -->
- **BC: input validation.** ≥1 part; message/task id non-empty-after-trim and ≤256 chars; metadata
  ≤64 KB. Each individually tested (patterns P-37). Confidence HIGH.
- **BC: tasks_cancel rejects terminal tasks** (`TaskNotCancelable`); transitions non-terminal →
  CANCELED via the executor state machine. Confidence HIGH.
- **BC: push-config lifecycle** (create/get/list/delete) — server assigns a UUID config id; **but
  create/delete re-persist via `delete_task` + `create_task`** because `TaskStore` has no atomic
  push-config update (patterns — non-atomic, race window). Confidence HIGH (`push_config_lifecycle`).
- **BC: message_stream is a STUB.** Unlike `message_send`, `message_stream` does NOT invoke the
  runner — it emits `Task → Working → Completed` status events with in-code "placeholder — Runner
  integration later". Streaming yields NO model output (patterns P-41). Confidence HIGH (code + the
  `message_stream_yields_events` test asserts only status transitions, no content).
- **BC: task-store trait + in-memory impl.** `TaskStore` (create/get/update_status/add_artifact/
  add_history_message/find_task_by_context/list_tasks/delete_task) with `InMemoryTaskStore`
  (`RwLock<HashMap>`). `TaskStoreEntry` = id/context_id/status/artifacts/history/metadata/
  push_configs/created_at/updated_at. Durable impls possible via the trait; default is non-durable.

## 14. A2A rate limiting (interceptor) — HIGH

`RateLimitInterceptor` = per-`caller_id` token bucket (fractional tokens, elapsed-time refill,
capped at `burst`); no-caller_id requests share a `"__global__"` bucket; rejection is JSON-RPC
`-32002 "rate limit exceeded"`. Tested for burst, refill-over-time, per-client isolation,
global-bucket, burst=0. Confidence HIGH. **Concern:** `buckets` map is in-memory + never evicted
(patterns P-43). This is REQUEST-RATE limiting, NOT token/cost budget (see §16).

## 15. Auth model (adk-auth) & credential discipline (question 4) — HIGH

- **Auth is BYO-injected.** `adk-server::auth_bridge::RequestContextExtractor` (Send+Sync async
  trait) is the ONLY auth seam: `extract(&Parts) -> Result<RequestContext, RequestContextError>`.
  `auth_middleware` maps `MissingAuth`→401, `InvalidToken`→401, `ExtractionFailed`→500, and inserts
  `Option<RequestContext>` into request extensions; scopes then reach tools via
  `ToolContext::user_scopes()`. Confidence HIGH (code).
- **adk-auth enterprise surface:** RBAC (`Permission` = Tool/Agent/AllTools/AllAgents; `Role` with
  allow/deny; `AccessControl` check), `ScopeGuard`/`ScopedTool` declarative tool authorization,
  `AuditSink` (File/InMemory/OTLP/Postgres), SSO/OIDC (`JwtRequestContextExtractor` +
  Okta/Auth0/Azure/Google/generic OIDC via JWKS with previous-key rotation), and cloud secret
  providers (AWS/Azure/GCP + a `cached` wrapper). Feature-gated (`sso`, `auth-bridge`,
  `*-secrets`, `*-audit`). Confidence HIGH (module surface).
- **BC: SecretProvider returns a bare `String`.** `SecretProvider::get_secret(name) -> Result<String,
  AdkError>` and `SecretServiceAdapter` → `adk_core::SecretService` both surface the secret VALUE as
  a plain `String` (the trait doc even `println!`s its length). **Divergence from pregolya's
  newtype+redacted-Debug credential rule** (patterns P-44): a `String` secret has default
  `Debug`/`Display` and is leak-prone in logs/spans/errors. Confidence HIGH (signature).
- **BC: A2A push auth** — `TaskPushNotificationConfig` carries Bearer `credentials` + a
  `a2a-notification-token`; `HttpPushNotificationSender` adds both headers. The credential is a
  `String` field on the config (same bare-string concern). SSRF validation gates the URL first
  (patterns P-35). Confidence HIGH (code).
- **Error mapping:** `RequestContextError` is `thiserror`-derived (not `anyhow`) — structured at the
  boundary. Confidence HIGH.

## 16. Budget / metering / cost governance (question 3) — HIGH (by absence)

- **Token accounting exists:** `adk-managed::usage::UsageReport` normalizes provider token counts
  (input/output/total + optional thinking/cache-read/cache-write; negatives clamped to 0; total
  auto-computed) and `SessionUsageTracker::record_turn` accumulates cumulative + last-turn. Doc
  states the platform uses this "for billing, monitoring, and cost tracking." Confidence HIGH
  (11 unit tests incl. cross-provider uniformity, serde round-trip).
- **Cost (dollars) lives on `adk-core::UsageMetadata`** (A1 §2: cost + is_byok + provider_usage), and
  `adk-telemetry::semconv` exposes OTel `gen_ai.usage.*` token attributes for export.
- **NO budget-governance primitive.** There is no tokens→cost-against-budget conversion, no per-run
  or per-sub-agent ceiling, and no halt/degrade-at-ceiling anywhere in the cluster. `RunConfig` has
  `max_transfer_depth` (a loop guard) but no budget field; `SessionUsageTracker` is never read to
  gate execution; `RateLimitInterceptor` bounds request RATE, not spend; `adk-payments::guardrail::
  amount_policy` is a COMMERCE spend policy (paying merchants), not an LLM-run budget. Confidence
  HIGH (absence confirmed by grep across telemetry/auth/server/managed/enterprise + RunConfig read).
- **Domain-B mapping:** this is exactly the budget-governance gap Domain B flagged as NEW
  (`domain-b-dark-factory.md` items §186/§231/§208 — "checkpointer stores usage but no
  budget-governance primitive planned"). adk-rust does NOT close it; it stops at accounting +
  rate-limiting. A pregolya budget primitive (per-run/per-agent token+cost ceiling with
  halt-or-degrade) is genuine net-new design with no reference prior art, but `UsageReport`/
  `SessionUsageTracker` is a clean accounting substrate to build ON.

## 17. Background runs & cron (feature) — MED

- **BC: background run lifecycle** — `POST /runs` → `RunStatus::Queued`, spawns a tokio task,
  Queued→Running, timeout+cancel via `tokio::select!`, retry (re-queue up to `max_retries`),
  terminal Completed/Failed/Cancelled/TimedOut. `GET /runs/{id}` reports status + retries-remaining;
  `DELETE /runs/{id}` cancels non-terminal via `CancellationToken`. Confidence MED.
- **BC: run EXECUTION is a placeholder.** `run_with_timeout`'s work future is commented "actual
  workflow execution is a placeholder … For now, we simulate immediate completion" returning an
  empty JSON object. The lifecycle/retry/timeout scaffolding is real; the workflow invocation is
  NOT wired. `RunStore` is in-memory only (no durability across restarts — Domain-B durability gap,
  patterns P-43). Confidence HIGH (code + comment).
- **Cron:** `validate_cron_expression` + job CRUD + pause/resume + `start_cron_scheduler`,
  `ConcurrencyPolicy`. Inventory-depth only.

## 18. A1 / A2 open items resolved in this cluster
- **P-18 (anyhow leak) — RESOLVED for the whole exposure cluster.** Cluster-wide grep: `anyhow`
  appears in ZERO source files of `adk-server`/`adk-auth`/`adk-awp`/`adk-acp`/`awp-types`/
  `adk-telemetry`/`adk-managed`/`adk-enterprise`. It is declared in `adk-server/Cargo.toml` and
  `adk-deploy/Cargo.toml` but not used in their `src/`; it is USED only in `adk-cli` and `cargo-adk`
  (binaries) — precisely the "confined to binaries/tests" carve-out pregolya permits. **No anyhow
  in any library public signature in this cluster.** Combined with A2's finding (state cluster also
  clean), the only remaining anyhow check is the core-crate grep (out of this cluster's scope).
- **reqwest timeout construction sites — RESOLVED (as a GAP).** Every outbound client is
  `reqwest::Client::new()` with NO `.timeout()`: `a2a/client.rs` (×5), `a2a/v1/push.rs`,
  `adk-auth::sso::jwks`, `adk-auth::sso::providers::oidc`. Cluster-wide grep for `.timeout(` = 0
  hits. The inbound axum `TimeoutLayer` (default 30s) is a server-request timeout, unrelated to the
  outbound clients. This is a divergence from pregolya's mandatory-30s rule (patterns P-42);
  pregolya must set `.timeout()` on ALL outbound clients incl. server-side push/JWKS/remote-agent.
- **New open items (A3):** (a) does any durable `TaskStore`/`RunStore` impl ship, or only in-memory?
  — only in-memory ships at v1.0.0; the traits exist for external durable impls. (b) `message_stream`
  and `background`-run execution are both placeholders — are they wired in a later ADK version? (out
  of scope at pinned v1.0.0). (c) `a2a/client.rs` (RemoteA2aAgent) — the A2A CLIENT side (calling out
  to peer agents) read at signature depth only; deep behavioral pass deferred if needed.

## State Checkpoint
```yaml
pass: A3
scope: behavioral-intent (server/protocol/auth cluster)
status: complete
files_read_deep: [adk-server/{lib,config,rest/mod,auth_bridge}, adk-server/a2a/v1/{request_handler,
                  task_store, mod}, adk-server/a2a/rate_limit, adk-server/a2a/v1/push,
                  adk-server/background/mod, adk-auth/{lib,secrets/provider}, adk-managed/usage,
                  adk-telemetry/semconv]
a1_scope: behavioral-intent (6 core crates); a2_scope: state/persistence/orchestration cluster
timestamp: 2026-07-13
```

---

# Pass A4 — SAFETY / QUALITY cluster behavioral intent
(adk-guardrail, adk-sandbox, adk-eval, adk-retry-reflect, adk-skill, adk-plugin, adk-code, adk-browser)

D16 Rust-blindness holds. This section records the *intended behavior* of each subsystem and maps
it to pregolya's holdout domains. Cross-refs to patterns P-47..P-66.

## 1. Guardrail subsystem — what is actually enforced, where it hooks (Q1)
**Intent:** validate/transform agent input and output. **Reality:** four built-in checks —
(a) `ContentFilter` keyword blocklist (word-boundary regex; `harmful_content` = 6 words) + required
topics + length; (b) `PiiRedactor` regex redaction of email/phone/ssn/credit-card/ip (Transform);
(c) `SchemaValidator` JSON-schema on output (extracts JSON from markdown fences); (d) severity ladder
Low/Medium/High/Critical.

**Hook points (in `adk-agent::llm_agent`):**
- INPUT: `apply_input_guardrails` runs once on `ctx.user_content()` BEFORE the first model call
  (`enforce_guardrails(..,"input")`). On `!passed` → `AdkError::agent("input guardrails blocked…")`.
- OUTPUT: `apply_output_guardrails` runs on each generated `content` event (two call sites — main
  and a streaming branch).
- Execution: `GuardrailExecutor::run` runs parallel guardrails via `join_all`, then sequential
  (transform-capable) ones in order; early hard-error ONLY on `Critical`+`fail_fast`; Medium/High
  set `passed=false` (blocking) but Low passes. Feature-gated behind `guardrails`; disabled = no-op.

**Bypass resistance / gaps (Domain A + C):**
- NO prompt-injection detection, NO policy/rule engine, NO semantic classification.
- Untrusted content entering context from TOOLS / RAG / MEMORY is NEVER guardrailed — only the
  initial user message and the final model output. This is the exact indirect-prompt-injection
  surface Domain A cares about, and it is unguarded (P-59).
- Keyword blocklist is trivially bypassed (obfuscation/translation/encoding).
- Enforcement depends on the `guardrails` feature being on AND on the agent loop checking `passed`
  (which it does, but only at the two hook points).
- **Domain A untrusted-content-isolation:** UNMET. **Domain C inverted-security-posture:** filters
  present but not a posture — no provenance tagging, no ingress validation, no default-deny.

## 2. Sandbox subsystem — isolation mechanism, escapes, default posture, limits (Q2)
Three isolation tiers, ascending strength:
- **ProcessBackend** (default feature `process`): `tokio::process` child; enforces `env_clear()` +
  wall-clock timeout ONLY. No memory/network/fs isolation. `Language::Command` = raw `sh -c "<code>"`.
  Output truncated to 1 MB (UTF-8-boundary-safe). DEFAULT and does not isolate (P-61).
- **OS enforcers** (opt-in features + external binaries): Linux bubblewrap = deny-by-default
  namespaces (pid/net unshare, bind-mount only allowed paths) — STRONG (P-48). macOS Seatbelt =
  allow-by-default profile that denies write/network/fork but NOT reads — reads unrestricted (P-60).
  Windows AppContainer (via `configure_command`, not read at depth). `get_enforcer()` probes at
  startup; per-domain network allowlist only enforced on macOS (Linux/Windows ignore + warn).
- **WasmBackend** (opt-in `wasm`): wasmtime, no WASI fs preopen, no net, memory via StoreLimits,
  epoch-interruption timeout — full isolation, all `EnforcedLimits` true (P-47).

**Escapes / caveats:** default process backend → everything (fs, net, spawn); macOS enforcer → all
file reads (credential exfiltration); workspace `validate_relative_path` is string-only, so
intra-workspace symlinks can escape (P-65). **Limits:** timeout everywhere; memory only on WASM; env
isolation on process + enforcers. **Default-on vs opt-in:** isolation is opt-in; secure backends
need feature flags (and OS enforcers need `bwrap`/`sandbox-exec` present). The truthful-capability
principle (P-49) lets a caller detect non-enforcement but does not force it. **Domain C sandboxing:**
primitives (WASM, bubblewrap) strong; DEFAULT posture not.

**adk-code layer:** higher-level exec substrate on top of adk-sandbox with its OWN `SandboxPolicy`
(strict-by-default) + backends: phase-1 `RustSandboxExecutor` (host-local `rustc`, policy UNENFORCED —
full host access, P-62), container (Docker/bollard, opt-in, isolating), WASM guest, embedded JS (boa).
Duplicate policy type vs adk-sandbox (P-58).

## 3. Eval subsystem — harness design (Q3)
**Datasets:** `.test.json` (`TestFile`→`EvalCase`→`Turn{user_content, final_response,
intermediate_data.tool_uses}`) and `.evalset.json` (`EvalSet` referencing files/inline cases).
**Criteria (all dispatched in `score_turn`/`evaluate_case`):** tool-trajectory (ordered/unordered ×
strict/partial args), text similarity (Exact/Contains/Levenshtein/Jaccard/ROUGE-1/2/L, CJK-aware
tokenizer), LLM-judge semantic match, rubric-weighted quality, safety, hallucination, typed
`StructuredVerdict`, plus optional cost-tracker, trace-analyzer, embedding, conversation scorers.
**LLM-judge:** free-text prompt → parsed (`SAFE: YES` / `SCORE: 0.8`) at temperature 0.0;
`StructuredJudge` is the typed alternative. **CI:** JUnit XML (feature `ci-helpers`), A/B comparator
with Wilcoxon (feature `statistics`), baseline/regression store.
**Weaknesses (P-64):** order-dependent multi-turn score merge `(a+b)/2`; judge infra-failure → score
0.0 (conflated with quality-fail); optional agent double-run when cost/trace configured.
**Map:** DIRECT to pregolya holdout-evaluation + Domain-B quality gates. Reusable core = declarative
datasets + deterministic non-LLM scorers; LLM-judge aggregation/fallback needs hardening.

## 4. retry-reflect — self-reflection loop semantics, termination, hook (Q4)
Hooks at `EnhancedPlugin::after_tool_call`. On a tool result detected as an error, it does NOT re-run
the tool: it increments a per-`(tool, args-hash)` counter, sleeps a saturating exponential/fixed
backoff (ceiling), and REPLACES the result with `{"reflection": "<templated error+args+guidance>"}`
so the agent self-corrects next turn (P-50). **Termination:** per-tool limit (default 3), invocation
`global_limit` (default None=unlimited), cross-invocation circuit-breaker (default off); on exhaustion
the real error is passed through (no swallow). **Termination hole (P-63):** the per-tool counter is
keyed by args-hash, so an agent that changes args each attempt (as the reflection asks) resets the
counter — the per-tool bound is effectively unbounded unless the opt-in global bound/circuit-breaker
is on. **Map:** pregolya must key the bound on tool identity, not argument content, and default to a
finite global bound.

## 5. Skills / plugins vs SKILL.md / MCP (Q5)
**Skill model (adk-skill):** SKILL.md-like — YAML-frontmatter markdown in `.skills/` and
`.claude/skills/` (+ optional global + convention files AGENTS.md/CLAUDE.md/SOUL.md). Frontmatter:
`name, description, version, license, compatibility, tags, allowed-tools, references, trigger, triggers`.
**Identity:** content-addressed `name + SHA256`. **Discovery/precedence:** project-local over global,
sorted+deduped. **Selection:** weighted lexical overlap (name 4.0 / desc 2.5 / tag 2.0 / body 1.0,
√body-token normalized), tag include/exclude, top-k (P-56). **Injection:** `[skill:name]…[/skill]`
prompt block prepended to the user message (closure `Plugin::on_user_message`), truncated to
`max_injected_chars` (default 2000). **Binding:** `ContextCoordinator` validates the skill's
`allowed-tools` against a host `ToolRegistry` and delivers instruction+resolved-tools atomically —
prevents the "phantom tool" hallucination (P-51). **Security scanning:** NONE — skill bodies are
trusted markdown; `allowed-tools` is capability-wiring, not a body scan. **vs MCP:** skills are a
static prompt-injection mechanism, orthogonal to MCP dynamic tool servers; the coordinator bridges
them. **Plugin model:** two parallel systems — closure `Plugin`/`PluginManager` (adk-go parity; skill
injector) and trait `EnhancedPlugin`/`EnhancedPluginManager` (retry-reflect); priority-ordered
before/after hooks with Continue/ShortCircuit + documented priority bands (P-52); duplication is a
drift surface (P-58). **vs OpenClaw SKILL.md:** the `.skills/` + `.claude/skills/` + convention-file
scan closely parallels OpenClaw; pregolya would need to add the body-content security scanning
adk-rust omits.

## 6. In-cluster open items resolved (Q6)
- **anyhow:** grep across all eight cluster crates' `src/` = ONE hit, a doc-comment example in
  `adk-browser/src/lib.rs`. NO public-signature leak in the cluster. RESOLVED (clean).
- **reqwest:** ZERO in the cluster — adk-browser drives WebDriver via `thirtyfour`; sandbox/eval/
  skill/plugin make no outbound HTTP. The A3 reqwest-timeout gap does not extend here.
- **unwrap/expect (non-test):** notable production panic path = `WasmBackend::new()` `.expect()` on
  engine init (P-66); most raw counts in adk-sandbox/adk-code are inside `#[cfg(test)]`.

## State Checkpoint
```yaml
pass: A4
scope: behavioral-intent (safety/quality cluster)
status: complete
subsystems: [guardrail, sandbox(process/os-enforcer/wasm), adk-code-exec, eval, retry-reflect,
             skill, plugin, browser]
holdout_map:
  domainA: untrusted-content-isolation UNMET (P-59)
  domainC: sandbox primitives strong but default posture weak (P-60,P-61,P-62,P-65)
  domainB: eval harness broad but scoring-rigor gaps (P-64)
timestamp: 2026-07-13
```

---

# Pass A5 — PROVIDER / CAPABILITY cluster behavioral intent

D16 Rust-blindness — observe, no adoption verdict. Behavioral-intent notes for the provider substrate
and the deep-scope capability crates, plus resolution of A1 open item P-16.

## Provider substrate — what the model layer PROMISES
- **Uniform LLM contract:** every backend implements adk-core's `Llm` trait; the adapter's job is
  `LlmRequest → provider wire → provider response → LlmResponse`, mapping the provider error taxonomy
  into `AdkError` (component=Model). The intent: provider-neutral agent code (`is_final_response`,
  tool loop) works regardless of backend.
- **Resilience by default (mostly):** 9 of 12 `adk-model` providers route generation through the shared
  `execute_with_retry` combinator (P-71) with `is_retryable_model_error` classification — retry policy
  is centralized for the dominant path. Server-provided `retry-after` is honored over local backoff (P-03/
  P-04 carried through). Behavioral gaps: <!-- [comparative-cert-1] corrected from "all providers" + "only ollama" exception; certification verified 3 non-wired providers via grep --> ollama (external ollama-rs) does not participate; bedrock/client stores RetryConfig but delegates retry to `aws-sdk-bedrockruntime`; openai/ws_transport stores RetryConfig but implements a manual retry loop (lines 160-201). And outbound timeouts are non-uniform (P-77).
- **Tool-call robustness across serving backends:** `tool_call_parser` (P-68) makes the tool loop work
  even when a backend emits tool calls as TEXT (Qwen/Llama/Mistral/DeepSeek/Gemma). The promise: an
  agent's tool contract is backend-encoding-agnostic — directly the property pregolya-ollama needs.
- **Streaming that also yields a final message:** the anthropic SDK's `AccumulatingStream` (P-70) +
  DoS-hardened SSE decoder (P-69) deliver live deltas AND a fully-assembled `Message` (for the event
  log / turn completion) without double-buffering, with idle-chunk timeout + TTFB metering.

## P-16 resolution — behavioral relationship of the two Anthropic surfaces (A1 open item CLOSED)
The behavioral relationship is **layered, not parallel**: `adk-anthropic` OWNS the Anthropic wire
behavior (auth, headers, SSE decoding, batch/files/managed-agents, cache-control, tool-search, token
counting, rate-limit tracking); `adk-model::anthropic` OWNS the ADK-trait behavior (request/response
conversion, `Llm` impl, schema adaptation, ADK error mapping) and DELEGATES all transport to
`adk_anthropic::Anthropic` via `fn inner()`. There is ONE Anthropic HTTP behavior in the workspace.
The adapter cannot behaviorally diverge from the SDK because it is built from the SDK's types
(compile-time coupling); the CHANGELOG shows new-model support landing in both in the same release.
Canonical: SDK for wire behavior, adapter for trait behavior. Drift risk LOW (was A1-assumed HIGH).
Full evidence: patterns-observed A5 headline. Same shape for gemini (adapter over `adk_gemini::Gemini`).

## Local-LLM behavioral story (Q4)
- **Ollama** (`ollama-rs` adapter): behaviorally an HTTP client to a local daemon; keyless; the daemon
  owns inference. Text-tag tool-call parsing (P-68) covers Ollama models without native tool-calling.
  Keyless-CI-friendly (mock the HTTP boundary). This is the pregolya-ollama behavioral target.
- **mistral.rs** (`adk-mistralrs`): behaviorally IN-PROCESS inference (text+vision+speech+diffusion+
  embedding) over candle; keyless but weight-download-dependent (hf-hub → native-tls, P-79), heavy
  build. `MistralRsError` gives actionable variants (ModelLoad/ModelNotFound with `suggestion`) —
  good UX — but leaks an `Other(anyhow)` escape (P-78). Behaviorally an ALTERNATIVE to a daemon, not
  a lightweight keyless-CI path.

## Payments commerce behavioral model (deep-scope inventory)
`adk-payments` implements agentic commerce as a **policy-gated, journaled transaction pipeline**:
a `TransactionRecord` (cart + actors + protocol descriptor) flows through composable
`PaymentPolicyGuardrail`s each returning `allow / escalate(human-review) / deny(hard-stop)` with
`Severity`-tagged findings; `AmountThresholdGuardrail` enforces a soft `review_threshold_minor` and a
hard `hard_limit_minor` on integer-minor-unit `Money`. Every step is written to an append-only
`journal/` (evidence_store) for audit; `auth/` binds a mandate + scopes. Protocol-neutral over ACP +
AP2 baselines (feature-gated). Behaviorally this is the closest thing in adk-rust to a
budget-governance engine — but for COMMERCE dollars, not LLM token/cost. It CONFIRMS the Domain-B
budget-governance gap (P-46) is real (no token/cost ceiling exists) while providing the exact policy
SHAPE (allow/escalate/deny + severity + journal) a pregolya token-budget primitive would want.

## New open items (A5) / carried
- The SDK+adapter split (P-16) is behaviorally sound but **undocumented at the workspace level** —
  a consumer isn't told when to use the raw SDK vs the adapter. Doc gap, not behavior gap.
- The realtime DEFAULT transports (OpenAI-Realtime/Gemini-Live over rustls WS) were read at
  dependency depth; deep behavioral read of the bidi audio state machine (VAD, barge-in) deferred —
  out of the core provider scope for this pass.

## State Checkpoint
```yaml
pass: A5
scope: behavioral-intent (provider/capability cluster)
status: complete
subsystems: [model-adapters, retry, tool-call-parser, streaming(sse/accumulate), anthropic-sdk,
             gemini-sdk, mistralrs-local, payments-commerce, realtime(dep-depth)]
a1_open_items_resolved:
  - P-16 — SDK+adapter layering (one wire behavior per vendor; adapter delegates); drift LOW
mappings: [pregolya-ollama (P-68 tool-parse + keyless-CI), Domain-B budget (P-73 shape vs P-46 gap)]
timestamp: 2026-07-13
```
