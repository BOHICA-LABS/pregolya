---
artifact: comparative/adk-rust/patterns-observed
pass: A1
constraint: >
  D16 Rust-blindness. Quality tags (STRONG/NEUTRAL/WEAK) judge each pattern on
  production-grade architectural merit ONLY — not on the fact that it is idiomatic Rust,
  compiles, or would save porting effort. This pass OBSERVES; it does not conclude that
  ferrochain should adopt or reject anything. The comparative assessment comes after this
  corpus passes its own validation cascade.
created: 2026-07-13
status: observe-only
---

# adk-rust — Distinctive Design Patterns Observed (Pass A1)

Each pattern: description, evidence (function/type + behavioral anchor), preliminary quality
tag with one-line rationale, and the ferrochain concern it maps to (citing our semport docs
where the same concern exists).

---

## STRONG patterns

### P-01 — Two-dimensional structured error envelope (component × category)
`AdkError` is a struct carrying orthogonal `ErrorComponent` (14 subsystems) and `ErrorCategory`
(10 failure kinds) axes, plus a machine `code: &'static str`, a `RetryHint`, and boxed
`ErrorDetails` (upstream status, request_id, provider, metadata). Category→retryability and
category→HTTP-status are total, tested mappings.
- Evidence: `adk-core::error` — `RetryHint::for_category`, `http_status_code`, `to_problem_json`;
  ~35 tests incl. all-category truth tables.
- Quality: **STRONG** — the retry hint and HTTP mapping are derived once from category and
  exhaustively tested, so error handling is data-driven rather than ad-hoc per call site.
- Ferrochain concern: error-taxonomy (`.factory/specs/prd-supplements/error-taxonomy.md`, Phase 1;
  CLAUDE.md "Error handling" + "No silent empty returns"). Also parallels langchain-core's need
  for structured errors across subsystems.

### P-02 — Supertrait context ladder with progressive capability disclosure
`ReadonlyContext → CallbackContext → InvocationContext`, with `ToolContext` branching off
`CallbackContext`. A function requests exactly the capability tier it needs; typed-identity
accessors (`try_identity`, `try_execution_identity`) live at the readonly base.
- Evidence: `adk-core::context` — the four traits + `ToolCallbackContext` delegating wrapper.
- Quality: **STRONG** — encodes least-privilege at the type level; a memory-search helper cannot
  accidentally end the invocation because it only holds `ToolContext`, not `InvocationContext`.
- Ferrochain concern: Runnables/config propagation (semport/core §1 Runnables — RunnableConfig
  threading), Callbacks (semport/core §7). Ferrochain's `RunConfig`/callback context design.

### P-03 — Retry as a generic combinator with layered delay precedence
`execute_with_retry_hint` is generic over any `FnMut() -> Future<Result<T>>` + injected
`classify_error` predicate; delay precedence is (1) structured `AdkError.retry_after`, then
(2) server `retry-after` header hint (first attempt), then (3) exponential backoff with a cap.
Includes HTTP 529 (overloaded) and a timing-verified backoff test.
- Evidence: `adk-model::retry` — `RetryConfig`, `execute_with_retry`, `is_retryable_status_code`,
  `exponential_backoff_without_retry_after` (measures inter-attempt gaps).
- Quality: **STRONG** — separates policy (config), classification (predicate), and mechanism
  (combinator); respects server timing over local guessing; genuinely tested for timing.
- Ferrochain concern: Rate limiters (semport/core §9), reliability/NFR (retry logic). Also
  informs the ferrochain-graph retry-edge / partner-crate provider-call story.

### P-04 — Structured retry hint co-located with the error (single source of truth)
Retryability travels *with* the error value (`AdkError.retry.should_retry` + `retry_after_ms`),
so any layer can make a retry decision without re-parsing messages. Legacy `.legacy`-coded
errors fall back to message-substring scanning during migration only.
- Evidence: `is_retryable_model_error` prefers `error.retry.should_retry`, message-scan only
  for `.legacy` codes.
- Quality: **STRONG** — eliminates the classic "re-parse the error string to decide retry"
  anti-pattern; the migration fallback is explicitly scoped and time-bounded.
- Ferrochain concern: error-taxonomy + rate limiters. Reinforces P-01.

### P-05 — `is_final_response()` as an explicit, fully-tested turn-completion predicate
Instead of scattering "is the agent done?" logic, one predicate combines skip_summarization,
long-running-tool presence, function-call/response presence, partial flag, and trailing
code-exec result — with an 11-case test truth table.
- Evidence: `adk-core::event::Event::is_final_response` + tests.
- Quality: **STRONG** — turn-boundary detection is the crux of any agent loop; centralizing and
  exhaustively testing it prevents subtle streaming/tool-loop bugs.
- Ferrochain concern: message/content-block semantics (semport/core §2), agent loop / graph
  node completion (semport/graph). langchain's AIMessage tool_calls detection is the analog.

### P-06 — Typed-identity newtypes with validation + typed addressing
`AppName`/`UserId`/`SessionId`/`InvocationId` newtypes (`TryFrom<&str>` validating) compose into
`AdkIdentity` and `ExecutionIdentity`. `SessionService` offers `*_for_identity` methods using the
full triple to eliminate bare-session-id ambiguity.
- Evidence: `adk-core::identity`, `adk-session::service` (`get_for_identity`, `AppendEventRequest`).
- Quality: **STRONG** — parse-don't-validate; the triple prevents cross-tenant session collisions
  that a bare string key invites.
- Ferrochain concern: domain-spec entities/invariants (Phase 1 L2 domain spec). Session/thread
  identity in langgraph checkpoint (semport/graph checkpoint namespace = thread_id + checkpoint_ns).

### P-07 — Cooperative cancellation + interrupt API with Drop-guaranteed cleanup
Per-session `CancellationToken` registered in an `active_sessions` map; a global token is combined
with the session token via spawned watchers; `interrupt(session_id)` cancels mid-stream; a
`SessionCleanup` struct with `impl Drop` removes the token on every exit path including early error
returns.
- Evidence: `adk-runner::runner::run` (effective_token combine, SessionCleanup Drop), `interrupt`,
  `active_session_ids`.
- Quality: **STRONG** — the Drop guard makes cleanup exception-safe across the streaming state
  machine; combining tokens gives both global shutdown and targeted interrupt.
- Ferrochain concern: reliability/NFR (graceful shutdown, cancellation), streaming (semport/core
  §1 astream). langgraph interrupt/resume (semport/graph HITL) is the closest analog.

### P-08 — Non-fatal degradation that is surfaced, not swallowed
Context-cache create/delete failures, intra-compaction failures, and proactive compaction
failures all `tracing::warn!` with the error and proceed — never a silent `Vec::new()`/`None`.
Persistence and agent-run errors are propagated via `yield Err(e)` through the `Result`-item stream.
- Evidence: `adk-runner::run` cache lifecycle + compaction blocks (warn-and-proceed) vs
  session-append (`yield Err`).
- Quality: **STRONG** — the distinction between "optimization failed, degrade + log" and
  "correctness failed, propagate" is drawn deliberately and consistently.
- Ferrochain concern: CLAUDE.md "No silent empty returns where partial-failure should propagate";
  logging discipline. Directly aligned with a ferrochain production-grade rule.

### P-09 — Typestate builder enforcing required construction fields at compile time
`Runner::builder()` returns a builder parameterized on `NoAppName/NoAgent/NoSessionService`
phantom states; `build()` is only in scope once all three transition to their "set" state.
- Evidence: `adk-runner::runner::Runner::builder` signature + `adk-runner::builder`.
- Quality: **STRONG** — makes "constructed a Runner without a session service" unrepresentable,
  the correct production-grade guarantee (vs a runtime `Result` from `build()`).
- Ferrochain concern: interface-definitions (Phase 1); Arc-DI wiring convention (CLAUDE.md).

### P-10 — Provider-aware schema normalization boundary (SchemaAdapter)
MCP toolsets return raw JSON Schema verbatim; each `Llm` exposes a `schema_adapter()` that
normalizes at request time (default `GenericSchemaAdapter`; providers override). Tool-name
truncation at a UTF-8 boundary for 64-byte limits is a default method.
- Evidence: `adk-core::schema_adapter::SchemaAdapter`, `adk-core::model::Llm::schema_adapter`,
  per-provider `schema_adapter.rs` (openai/anthropic).
- Quality: **STRONG** — keeps tool discovery provider-agnostic and localizes each provider's
  schema quirks; the capability is discovered through the trait rather than branched on a
  provider enum at call sites.
- Ferrochain concern: Tools (semport/core §6 tool schema generation), MCP adapters (semport/mcp).
  langchain-mcp-adapters' schema conversion is the direct analog.

---

## NEUTRAL patterns

### P-11 — `Event` embeds `LlmResponse` via `#[serde(flatten)]` (adk-go parity)
Event carries the LLM response fields flattened into its own JSON, mirroring adk-go's design.
- Evidence: `adk-core::event::Event { #[serde(flatten)] llm_response }`.
- Quality: **NEUTRAL** — convenient wire compatibility, but flatten couples Event's schema to
  LlmResponse's and can cause field-collision surprises; parity with adk-go is a compatibility
  goal, not an architectural virtue on its own merit.
- Ferrochain concern: message/content-block modeling (semport/core §2). Ferrochain should decide
  composition vs flatten independently.

### P-12 — Capability discovery via defaulted trait methods returning `false`/`None`
`Llm::uses_interactions_api`, `Tool::is_builtin/is_read_only/is_concurrency_safe`,
`CallbackContext::shared_state`, `Memory::add/delete` (default = "not implemented" error).
- Evidence: `adk-core::{model,tool,context}` default methods.
- Quality: **NEUTRAL** — ergonomic and backward-compatible, but a defaulted `false`/`Ok(None)`
  can silently hide an unimplemented capability (e.g. a memory backend that "works" but never
  persists). Mitigated where the default returns a structured error (session `rewind`, memory
  `add`) rather than a benign value.
- Ferrochain concern: capability gating (CLAUDE.md "Doc comment claiming capability X with no
  capability check"). Ferrochain should prefer default-errors over default-false for
  correctness-bearing capabilities.

### P-13 — `serde_json::Value` as the universal tool arg/result and state value type
Tool `execute(args: Value) -> Result<Value>`, `State::get/set` on `Value`, `extensions` maps.
- Evidence: `adk-core::tool::Tool::execute`, `context::State`.
- Quality: **NEUTRAL** — maximal flexibility and provider-neutrality, but pushes schema
  enforcement to runtime (SchemaAdapter/guardrail) rather than the type system. Reasonable for
  an LLM tool boundary; not a type-safety win.
- Ferrochain concern: Tools (semport/core §6), D5 pydantic→serde/schemars ADR.

### P-14 — Feature-flag-gated optional subsystems in the composition root
Runner fields for artifacts/plugins/skills/context-compaction are `#[cfg(feature=…)]`, producing
different struct shapes per feature set.
- Evidence: `adk-runner::runner::{RunnerConfig, Runner}` cfg-gated fields.
- Quality: **NEUTRAL** — good for binary size / opt-in cost, but heavy `#[cfg]` interleaving in a
  single 800-line `run` method raises the cost of reasoning about any single build's behavior and
  complicates test-matrix coverage.
- Ferrochain concern: NFR (build/feature composition), file-size & cohesion convention.

---

## WEAK / concerning observations

### P-15 — Monolithic `LlmAgent` file (2,712 lines) and 800-line `Runner::run`
`adk-agent/src/llm_agent.rs` is 2,712 lines; `Runner::run` is one ~800-line `async_stream::stream!`
block with deeply nested cfg-gated error paths.
- Evidence: `wc -l adk-agent/src/llm_agent.rs`; `adk-runner::runner::run`.
- Quality: **WEAK** — both would blow ferrochain's 750-line production hard gate and
  `clippy::too_many_lines`. The runner's single-function turn+transfer+cache+compaction+plugin
  state machine is hard to unit-test in isolation; each concern (cache lifecycle, transfer loop,
  compaction) is inlined rather than extracted behind a testable seam. Cohesion is real but the
  size signals under-decomposition of independently-verifiable behaviors.
- Ferrochain concern: file-size & module-splitting convention (CLAUDE.md; file-size-standard-study).
  A ferrochain port must decompose these into seams (turn-executor, transfer-resolver,
  cache-lifecycle) to satisfy the gate AND to make the contracts individually testable.

### P-16 — Duplicated provider surfaces (in-tree adk-model modules vs standalone provider crates)
Anthropic and Gemini exist both as `adk-model::{anthropic,gemini}` modules AND as standalone
`adk-anthropic` (17k LOC) / `adk-gemini` (14k LOC) crates.
- Evidence: `adk-model/src/anthropic/*`, `adk-model/src/gemini/*` vs `adk-anthropic/`, `adk-gemini/`.
- Quality: **WEAK** — two code paths for the same vendor invite drift (a bug fixed in one may not
  reach the other) and ambiguous "which do I use?" ergonomics. The relationship/layering is
  undocumented at the workspace level. Deep pass must determine if one wraps the other or they
  diverge.
- Ferrochain concern: partners (semport/partners) — ferrochain should have ONE provider surface
  per vendor. This is a defer-pattern smell if the duplication is "we'll consolidate later."

### P-17 — Cache-key proxy uses agent description, acknowledged as imperfect
The runner's context-cache keys on `agent.description()` as a "reasonable proxy" for the system
instruction (which is actually resolved deeper inside the agent), and caches with an empty tools map.
- Evidence: `adk-runner::run` cache block comment: "the full instruction is resolved inside the
  agent … the description provides a reasonable proxy for cache keying"; `tools = HashMap::new()`.
- Quality: **WEAK** — caching on a proxy key rather than the actual cached content (instruction +
  tools) risks cache-key/content mismatch: two agents with identical descriptions but different
  resolved instructions/tools could collide, or a changed instruction under a stable description
  could serve a stale cache. The empty-tools map means tool definitions are not part of the cache
  identity at all.
- Ferrochain concern: correctness of prompt-caching NFR. A ferrochain design should key caches on
  the resolved (instruction, tools) content hash, not a description proxy.

### P-18 — `anyhow` available workspace-wide alongside the structured `AdkError`
`anyhow = "1.0"` is in the workspace dependency table.
- Evidence: root `Cargo.toml` `[workspace.dependencies]`.
- Quality: **WEAK (pending verification)** — if `anyhow::Error` appears in any *library* public
  signature it undercuts the whole structured-error investment (P-01) by erasing component/category
  at the boundary. Acceptable only if confined to binaries (cli, cargo-adk) and tests.
- Ferrochain concern: CLAUDE.md structured-error discipline; ferrochain forbids this leakage. Deep
  pass must grep public signatures for `anyhow::`.

### P-19 — Capability defaults that can mask missing behavior (correctness-bearing subset)
Related to P-12 but called out as a risk: `Tool::is_concurrency_safe` defaults `false` (safe), but
`Memory::search_in_project` defaults to global-only `search`, and `shared_state()` defaults `None`.
A parallel-agent tool relying on shared state gets `None` silently if wiring is missed.
- Evidence: `adk-core::context::CallbackContext::shared_state` (default None),
  `Memory::search_in_project` (delegates to global search).
- Quality: **WEAK** — silent `None`/global-fallback for coordination/isolation primitives can
  produce correct-looking but semantically wrong behavior (cross-project memory bleed if a backend
  forgets to override `search_in_project`).
- Ferrochain concern: memory project-scope isolation (a security/tenancy invariant); parallel-agent
  coordination. Ferrochain should make isolation-bearing methods required, not defaulted.

---

## Cross-cutting note (informative, not a conclusion)
adk-rust's strongest work is concentrated in the error/retry/turn-completion/identity core —
exactly the behavioral-contract surface ferrochain cares most about — while its weaknesses are
structural (file size, provider duplication) and a few correctness-risk defaults (cache-key proxy,
silent capability fallbacks). Whether any of these patterns should influence ferrochain is
explicitly deferred to the post-validation comparative assessment per D16.

## State Checkpoint
```yaml
pass: A1
scope: patterns-observed
patterns: 19 (10 STRONG, 4 NEUTRAL, 5 WEAK)
status: complete
timestamp: 2026-07-13
```
