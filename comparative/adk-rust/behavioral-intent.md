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
  matters. Confidence HIGH (`test_validate_state_key_path_traversal`, `_null_byte`).
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
  `_non_retryable_categories_default_false`). Confidence HIGH.
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
- **`RunConfig`** — 12-field run configuration with a fluent `RunConfigBuilder` and a
  `max_transfer_depth` guard (default 10) preventing infinite agent-transfer loops.

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
- 10 provider module families (openai has 14 sub-files incl. responses_client, background,
  conversations, ws_transport, pricing). openrouter is a full sub-provider with discovery,
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
  ferrochain's 750-line hard gate) is the flagship agent: owns the LLM turn loop, tool
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
AND no trailing code-exec result). 11 dedicated tests cover the truth table including the
trailing-function-response edge and text-after-response edge. Confidence HIGH.

## State Checkpoint
```yaml
pass: A1
scope: behavioral-intent (6 core crates)
status: complete
files_read_deep: [adk-core/{lib,agent,error,model,tool,context,event,schema_adapter},
                  adk-model/{provider,retry}, adk-runner/runner, adk-session/service]
timestamp: 2026-07-13
```
