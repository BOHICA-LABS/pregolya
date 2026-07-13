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

---

# Pass A2 — STATE / PERSISTENCE / ORCHESTRATION cluster (adk-graph, adk-session, adk-memory, adk-artifact)

Same D16 constraint: quality tags judge production-grade merit only; no adoption verdicts.
Evidence cited by function/type + behavioral anchor. Fifteen new patterns (P-20…P-34).
Primary mapping target: `.factory/semport/graph/behavioral-intent.md` (LangGraph §1–§6) and
D9 (execution model) / D11 (durability).

## STRONG patterns

### P-20 — Transactional multi-table session writes (session + state + events atomic)
Every SQL session backend wraps a create / append_event across the `sessions`, `app_states`,
`user_states`, and `events` tables in a single `pool.begin()` … `tx.commit()` transaction; an
early-return error path drops `tx` (RAII rollback). `temp:`-prefixed state keys are stripped
before persistence (`state_delta.retain(|k,_| !k.starts_with(KEY_PREFIX_TEMP))`).
- Evidence: `adk-session::postgres` `create` (tx around app/user/session upserts + commit),
  `append_event` (tx: session `updated_at` bump + event INSERT + optional state UPSERT);
  same shape in `sqlite`, `mongodb`, `neo4j`, `redis`, `firestore`.
- Quality: **STRONG** — an appended event and its induced state delta commit or roll back
  together, so a crash can never leave state advanced past the event that produced it. This is
  the atomicity guarantee ferrochain's D11 checkpoint-atomicity concern asks for.
- Ferrochain concern: durability/checkpoint atomicity (semport/graph §2, §5.1; D11). Contrast:
  adk-**graph**'s checkpointer does NOT have this two-phase discipline (see P-29).

### P-21 — AEAD envelope encryption wrapper with key rotation
`EncryptedSession<S>` wraps ANY `SessionService`, encrypting state with AES-256-GCM under a
random 96-bit nonce, storing `base64([12-byte nonce ‖ ciphertext])` under `__encrypted_state`.
Decryption tries `current_key`, then each `previous_keys` in order; on a previous-key hit it
lazily re-encrypts with the current key (`decrypt_state_with_rotation` → `needs_reencrypt`).
- Evidence: `adk-session::encrypted` `encrypt_bytes`/`decrypt_bytes` (AEAD), `EncryptedSession::get`
  rotation branch, `ENCRYPTED_STATE_KEY` const.
- Quality: **STRONG (crypto core)** — AEAD (not raw AES) gives integrity+confidentiality; random
  per-write nonce is correct; wrap-any-backend composition and staged key rotation are the right
  shape for at-rest encryption with rolling keys. (Two real gaps demote the *completeness* — see
  P-32 — but the primitive and rotation design are sound.)
- Ferrochain concern: encryption-at-rest NFR (Phase 1 nfr-catalog); credential/PII safety.
  LangGraph's `EncryptedSerializer` (semport/graph §2.3) is the direct analog.

### P-22 — DeltaCheckpointer as a composable storage-compression wrapper
`DeltaCheckpointer<C: Checkpointer>` wraps any checkpointer: full snapshot at step 0 and every
`full_snapshot_interval` (default 10), otherwise a `MapDelta { added, removed, modified }` of the
whole-state map with the base state field emptied; `load` finds the nearest full snapshot and
replays deltas forward, bounding reconstruction cost. The `Diff` trait carries an explicit
round-trip contract (`apply(s1, diff(s1,s2)) == s2`) exercised by property tests.
- Evidence: `adk-graph::delta` `DeltaCheckpointer::{save,load,reconstruct_state}`,
  `is_full_snapshot_step`, `impl Diff for HashMap<String,Value>`; `delta_property_tests.rs`.
- Quality: **STRONG (as storage compression)** — turns O(steps × state) growth into O(state +
  Σdeltas) with a snapshot-bounded replay; drop-in via the same trait; the round-trip invariant
  is stated and tested. Distinct in shape from LangGraph's per-channel `DeltaChannel` (P-25).
- Ferrochain concern: checkpoint storage-shape polymorphism + snapshot/prune (semport/graph §1.4
  DeltaChannel, §2.1 prune). A cleaner *layering* than LangGraph's channel-level deltas, but
  coarser granularity (P-25).

### P-23 — Write isolation within a super-step via per-node state clone + deferred apply
`execute_super_step` snapshots state into each node's `NodeContext::new(self.state.clone(), …)`,
runs all pending nodes concurrently (`buffer_unordered`), collects every node's `output.updates`
into `all_updates`, and applies them through reducers only AFTER all nodes resolve. Nodes never
observe each other's writes mid-step.
- Evidence: `adk-graph::executor::PregelExecutor::execute_super_step` (clone → run → collect →
  apply); `test_sequential_execution`, `test_conditional_routing`.
- Quality: **STRONG (the core BSP invariant)** — this is exactly LangGraph's write-isolation
  guarantee (semport/graph §1.1 step 3): effects isolated until an apply phase. The isolation
  half is right. (The *ordering* half of the invariant is not — see P-28.)
- Ferrochain concern: BSP isolation invariant (semport/graph §1.1, cross-cutting note 1; D9).

### P-24 — Property-based test suite over the graph runtime (proptest-driven, not smoke)
The graph crate's 14 integration files are dominated by property tests: `action_switch`,
`action_error_mode`, `cache`, `deferred`, `delta`, `time_travel`, `timeout`, and
`workflow_schema` all carry `*_property_tests.rs`. 208 test fns crate-wide; the `Diff` round-trip,
switch routing, deferred fan-in, and timeout laws are checked over generated inputs.
- Evidence: `adk-graph/tests/*_property_tests.rs` (8 of 14 files), `delta.rs`/`typed_reducer.rs`
  in-crate truth tables.
- Quality: **STRONG** — property tests over a state-machine runtime encode invariants
  (round-trip, routing totality, fan-in completeness) a re-implementer can lift as a conformance
  suite. This is the highest-value test-as-spec form for an execution engine.
- Ferrochain concern: test-as-spec / verification-properties (Phase 6 VP files); D9/D11 invariants
  are exactly the kind that want property + Kani coverage.

## NEUTRAL patterns

### P-25 — Delta granularity is whole-state map, not per-channel
`DeltaCheckpointer` diffs the entire `HashMap<String,Value>` state (`MapDelta` of added/removed/
modified keys), whereas LangGraph's `DeltaChannel` stores incremental deltas per channel with its
own snapshot cadence and parent-chain walk.
- Evidence: `impl Diff for HashMap<String,Value>` (the only map-level Diff wired into the wrapper);
  LangGraph semport/graph §1.4.
- Quality: **NEUTRAL** — map-level diff is simpler and backend-agnostic, but it recomputes the
  whole-state diff each step and cannot express channel-local semantics (e.g. an append-only
  channel's deltas independent of unrelated keys). Adequate; not a fidelity match.
- Ferrochain concern: checkpoint delta strategy (semport/graph §1.4). Ferrochain must decide
  channel-level vs state-level delta explicitly.

### P-26 — Memory visibility = global ∪ project overlay (additive project scope)
`InMemoryMemoryService::search` returns *global* entries when `project_id=None`; when
`project_id=Some(pid)` it returns `project_id.is_none() || project_id == pid` — i.e. global PLUS
that one project. `user_id`/`app_name` always partition; `validate_project_id` bounds the id
(non-empty, ≤256). Deletes are scope-aware (`delete_project`, `delete_entries_in_project`).
- Evidence: `adk-memory::inmemory::search` scope match, `add_session_to_project`,
  `service::validate_project_id`; `MemoryServiceAdapter::{search,search_in_project,add_to_project}`.
- Quality: **NEUTRAL** — clean cross-project isolation (project A cannot read project B) and firm
  user partitioning, but global entries deliberately bleed into every project view. Correct for a
  "shared org memory + project overlay" model; a "strictly personal, never-shared" memory needs
  the global tier disabled or a user-private scope.
- Ferrochain concern: Domain C (OpenClaw) personal memory — see the dedicated behavioral-intent
  A2 mapping. The additive-global default is the key decision point.

### P-27 — Graph checkpointing and session persistence are two unrelated subsystems
`adk-graph::Checkpointer` (thread_id → Checkpoint) and `adk-session::SessionService` (identity →
Session/Events) are independent traits with independent backends, IDs, and durability properties.
No bridge type couples a graph thread to a session.
- Evidence: `adk-graph::checkpoint::Checkpointer` vs `adk-session::service::SessionService` —
  disjoint trait hierarchies; no cross-crate import.
- Quality: **NEUTRAL** — clean separation of "agent conversation persistence" from "graph
  execution persistence," but it means two durability stories with divergent guarantees (session
  = transactional multi-table; graph = single-blob step-boundary) coexist in one framework.
- Ferrochain concern: architecture layering (semport/graph vs a future session/thread store).
  Ferrochain should decide whether graph checkpoints and conversation threads share one store.

## WEAK / concerning observations

### P-28 — Nondeterministic reducer application order (violates the BSP merge-order invariant)
Parallel node outputs are collected via `stream::iter(futures).buffer_unordered(n).collect()`,
which yields in COMPLETION order; `all_updates` is then folded through reducers in that order.
For non-commutative reducers (`Reducer::Append`, custom) the merged result depends on node
finish timing. There is no task-path sort (contrast LangGraph's `apply_writes` deterministic
`task_path_str(path[:3])` ordering) and no "one writer per step" / `InvalidUpdateError` guard —
`Overwrite` silently last-write-wins in nondeterministic order.
- Evidence: `adk-graph::executor::execute_super_step` (`buffer_unordered` → `all_updates` fold);
  `state::StateSchema::apply_update` (no concurrent-write detection); LangGraph semport/graph
  §1.2, §1.4 (LastValue → InvalidUpdateError).
- Quality: **WEAK (correctness)** — directly contradicts the D9 cross-cutting invariant
  "preserve deterministic merge order regardless of execution shape." Two runs of the same graph
  with an Append channel and two concurrent writers can produce different list orders; replay is
  not bit-reproducible. A ferrochain port must impose a deterministic write order (sort by node
  identity/path) and add concurrent-write detection for last-value channels.
- Ferrochain concern: determinism/replay (semport/graph §1.2, §1.4, cross-cutting note 1; D9).

### P-29 — Step-boundary-only durability: no per-task pending writes, no durability modes
`save_checkpoint` persists the WHOLE state + `pending_nodes` + `step` AFTER each super-step. There
is no `put_writes`-equivalent per-task intermediate persist, no `ERROR/RESUME/INTERRUPT` write
markers, and no `sync|async|exit` durability knob. A crash mid-step (after k of n concurrent nodes
finished) loses the entire step; on restart ALL `pending_nodes` re-run — at-least-once for the
whole step, with zero per-task credit.
- Evidence: `adk-graph::executor::{run, save_checkpoint}` (save after `execute_super_step`);
  `checkpoint::Checkpoint` shape (state/step/pending_nodes only); no `put_writes` method on the
  `Checkpointer` trait. Contrast LangGraph semport/graph §2.4, §5.1–§5.2.
- Quality: **WEAK (durability granularity)** — coarser crash-recovery than the port target.
  Acceptable for cheap nodes; wasteful/incorrect-under-side-effects for expensive or non-idempotent
  nodes, since all in-flight work of a partially-completed step re-executes. No knob to trade
  latency for durability.
- Ferrochain concern: durability modes + pending-writes crash-safety (semport/graph §2.4, §5.1–§5.3,
  cross-cutting notes 3 & 5; D11). A ferrochain port needs the per-task write channel.

### P-30 — Impoverished interrupt/resume: no resume-value injection, no re-execute-from-start contract
`Interrupt` is `Before(node) | After(node) | Dynamic { message, data }`. On interrupt the executor
saves a checkpoint and returns `GraphError::Interrupted`. Resume just restores state and re-runs
`pending_nodes`. There is NO `Command(resume=value)` mechanism, NO per-task scratchpad interrupt
counter matching multiple `interrupt()` calls to resume values by order, and NO documented
"node re-executes from start; prior interrupt() returns its stored value" idempotent-replay
contract — the single most surprising, load-bearing LangGraph HITL semantic (semport/graph §3.1–§3.2).
- Evidence: `adk-graph::interrupt::Interrupt` (3 variants, `Dynamic` carries data but no resume
  path); `executor::run` interrupt branch (save + return Err); no resume-value type. Contrast
  LangGraph semport/graph §3.1–§3.5.
- Quality: **WEAK (behavioral fidelity)** — the HITL surface is a notification ("we stopped, here's
  a message") not a resumable dialogue ("inject this human decision, continue the node"). Dynamic
  interrupts cannot carry a human's answer back into the interrupted node. A ferrochain port
  targeting LangGraph parity must build the resume-value scratchpad + replay contract from scratch.
- Ferrochain concern: interrupts & HITL (semport/graph §3, cross-cutting note 2; D9). Also relates
  to P-07 (adk-runner cancellation) — different subsystem, different depth.

### P-31 — Wall-clock ordering for "latest" and for rewind (no monotonic logical clock)
Checkpoint IDs are random UUIDv4; "latest" is `ORDER BY created_at DESC` (`chrono::Utc::now()`),
and session `rewind` deletes events by `timestamp > target` plus a same-timestamp
`id != target` sweep. Ordering therefore relies on wall-clock monotonicity, not a logical
sequence/version.
- Evidence: `adk-graph::checkpoint::SqliteCheckpointer::load` (`created_at DESC LIMIT 1`),
  `state::Checkpoint::new` (`Uuid::new_v4`); `adk-session::sqlite::rewind` (timestamp delete +
  `id != target` tie-break). Contrast LangGraph uuid6 monotonic-sortable checkpoint IDs
  (semport/graph §2.2) and content-addressed task IDs (§1.2).
- Quality: **WEAK (correctness under concurrency/skew)** — two checkpoints or events in the same
  clock tick have ambiguous order; a clock adjustment can reorder history; rewind's same-timestamp
  tie-break by id is arbitrary. LangGraph deliberately uses monotonic logical IDs to avoid exactly
  this. A ferrochain port should use a monotonic per-thread sequence, not wall-clock.
- Ferrochain concern: determinism, time-travel/fork, rewind correctness (semport/graph §1.2, §2.6,
  §5; D11).

### P-32 — Encryption covers only session STATE, not event content; re-encrypt is best-effort/swallowed
`EncryptedSession` encrypts only the state map. `append_event` and `list` delegate straight through
— event `llm_response`/`actions` (the actual conversation content) are stored PLAINTEXT. The
rotation re-encrypt on read is `let _ = self.inner.create(update_req).await` — errors silently
discarded — and reuses `create()` as an upsert (dubious semantics).
- Evidence: `adk-session::encrypted::EncryptedSession::{append_event (delegates), list (delegates),
  get (best-effort `let _ =` re-encrypt)}`; only `create`/`get` touch `encrypt_state`.
- Quality: **WEAK** — "encryption at rest" that leaves message bodies in cleartext is a partial
  guarantee likely to surprise; and the swallowed re-encryption error violates the no-silent-failure
  rule (CLAUDE.md "No silent empty returns / surface partial failures"). A ferrochain design must
  encrypt event payloads too (or document the boundary explicitly) and propagate rotation failures.
- Ferrochain concern: encryption-at-rest completeness + no-silent-swallow discipline (CLAUDE.md;
  Phase 1 nfr-catalog / error-taxonomy).

### P-33 — Hand-written `unsafe impl Send/Sync` on PhantomData reducers where a safe form exists
`ReplaceReducer<T>`/`AppendReducer<T>` carry `PhantomData<T>` and add `unsafe impl<T> Send`/`Sync`
unconditionally, despite the `TypedReducer` impls already bounding `T: Send + Sync`.
- Evidence: `adk-graph::functional::typed_reducer` (`unsafe impl<T> Send for ReplaceReducer<T>` etc).
- Quality: **WEAK (unnecessary unsafe)** — `PhantomData<fn() -> T>` (or deriving from bounded T)
  yields unconditional `Send+Sync` with zero `unsafe`. Reaching for `unsafe` to paper over a
  variance/marker choice is a code smell in an otherwise safe crate; ferrochain forbids gratuitous
  `unsafe` without a soundness note.
- Ferrochain concern: unsafe-code discipline / production-grade default (CLAUDE.md).

### P-34 — `append_event_for_identity` default collapses the identity triple to bare session_id
The typed-identity append default is `self.append_event(req.identity.session_id.as_ref(), req.event)`
— it discards `app_name` and `user_id`. Backends must OVERRIDE to actually use the triple; the SQL
backends' `append_event(session_id, …)` then resolves the row by `WHERE session_id = ?` alone,
guarded only by an "ambiguous session_id" runtime error.
- Evidence: `adk-session::service::SessionService::append_event_for_identity` default;
  `postgres::append_event` (`SELECT … WHERE session_id = $1` + `len() > 1` ambiguity error).
- Quality: **WEAK (tenancy)** — the P-06 typed-identity investment (STRONG) is undercut at the
  append boundary unless every backend overrides; the default silently narrows a cross-tenant-safe
  triple to a globally-non-unique key and leans on a runtime ambiguity check instead of the type.
- Ferrochain concern: session/thread identity + multi-tenancy isolation (semport/graph §2.5 thread
  namespacing; parallels P-06). Ferrochain should make triple-addressed append the ONLY path.

## Cross-cutting note (informative, not a conclusion) — Pass A2
The cluster's strengths are in *storage discipline* — transactional session writes (P-20), AEAD
envelope encryption (P-21), composable delta compression (P-22), and a property-test-heavy graph
suite (P-24) — and the graph engine correctly isolates writes within a step (P-23). Its weaknesses
cluster around *execution-model fidelity to Pregel*: nondeterministic merge order (P-28), coarse
step-boundary-only durability with no per-task writes or durability modes (P-29), a notification-
only interrupt model lacking the resume-value/replay contract (P-30), and wall-clock rather than
logical-clock ordering (P-31). Net: adk-graph is a competent edge-following graph runner dressed in
Pregel vocabulary, not a Pregel/BSP engine with LangGraph's determinism-and-replay guarantees. Any
influence on ferrochain is deferred to the post-validation comparative assessment per D16.

## State Checkpoint
```yaml
pass: A2
scope: patterns-observed (state/persistence/orchestration cluster)
patterns_A1: 19 (10 STRONG, 4 NEUTRAL, 5 WEAK)
patterns_A2: 15 (5 STRONG, 3 NEUTRAL, 7 WEAK)  # P-20..P-34
patterns_total: 34
status: complete
timestamp: 2026-07-13
```

---

# Pass A3 — SERVER / PROTOCOL / AUTH cluster (adk-server, A2A v1, awp/acp, adk-auth, telemetry)

Deep scope: `adk-server` (20,752 LOC), A2A v1.0.0, `adk-awp`/`awp-types`/`adk-acp`,
`adk-auth`, `adk-telemetry`, `adk-managed` usage, + `adk-cli`/`adk-deploy`/`cargo-adk` at
inventory depth. Same D16 Rust-blindness constraint — production-grade merit only,
observe-do-not-conclude. New patterns numbered P-35+ (A2 claimed P-20..P-34). Primary
mapping targets: `.factory/semport/platform/module-inventory.md` (61-endpoint catalog),
D13 (first-party server), Domain-B budget-governance gap, CLAUDE.md credential/timeout rules.

## STRONG patterns

### P-35 — SSRF-hardened outbound webhook delivery (push notifications)
`HttpPushNotificationSender::send_with_retry` calls `validate_webhook_url` BEFORE every
delivery, rejecting private IPv4 ranges (10/8, 172.16/12, 192.168/16), loopback (127/8, ::1),
and `localhost`; then bounded retry (3 attempts, 1s/2s/4s backoff), structured warn/error per
attempt, and a terminal `A2aError::PushDeliveryFailed` (no silent success).
- Evidence: `adk-server::a2a::v1::push::{validate_webhook_url, HttpPushNotificationSender::send_with_retry}`.
- Quality: **STRONG** — server-initiated HTTP to a user-supplied URL is a classic SSRF sink;
  validating the destination up front is the correct production-grade default, and delivery
  failure is surfaced rather than swallowed.
- Ferrochain concern: any ferrochain-server webhook/push surface (Domain-B run-completion
  callbacks; LangGraph `webhook`/`on_run_completed` run fields, platform §2.6) must carry the
  same SSRF gate. Maps to security-review. NOTE: the delivery client has NO reqwest timeout (P-42).

### P-36 — Defense-in-depth default middleware stack on the axum app
`create_app`/`ServerBuilder::build_inner` layer uniformly on every route: request-id middleware
(validates inbound `x-request-id` as ≤128-char UUID else generates one, and echoes it back),
`TraceLayer` span with method/path/request-id, inbound `TimeoutLayer`
(`SecurityConfig.request_timeout`, default 30s), `DefaultBodyLimit` (10 MB default), CORS with
explicit method + header allowlists, and three static security headers (nosniff / X-Frame DENY /
XSS block).
- Evidence: `adk-server::rest::{request_id_middleware, validate_request_id, build_cors_layer}`
  + the shared `ServiceBuilder` stack in `create_app_with_a2a` and `ServerBuilder::build_inner`.
- Quality: **STRONG** — secure defaults applied by construction, not opt-in; request-id
  correlation is wired into tracing spans. Production-grade HTTP posture. (CAVEAT: CORS falls
  back to `AllowOrigin::any()` when `allowed_origins` is empty — see P-45.)
- Ferrochain concern: ferrochain-server inbound middleware + observability spec (Phase 1). The
  request-id-into-span pattern aligns with the Canonical Structured Event Catalog discipline.

### P-37 — Exhaustive A2A input validation with explicit size bounds
`validate_message`/`validate_id`: message has ≥1 part; message/task IDs non-empty-after-trim
and ≤256 chars; metadata JSON ≤64 KB. Each bound has a dedicated rejection test. Plus tested
INPUT_REQUIRED multi-turn resume: a follow-up whose `contextId` maps to a non-terminal
`InputRequired` task resumes that task (Working→Completed) instead of forking a new one.
- Evidence: `adk-server::a2a::v1::request_handler::{validate_message, validate_id}`,
  `message_send` contextId-resume branch; `find_task_by_context` (excludes terminal states) + tests.
- Quality: **STRONG** — untrusted protocol input bounded at the boundary with individually-tested
  limits (the 64 KB metadata cap blocks an unbounded-allocation vector); the resume contract is a
  clean, tested state-machine transition.
- Ferrochain concern: ferrochain-server request-DTO validation + error taxonomy (Phase 1), and
  the run/thread resume design (platform §2.3 runs, §2.2 thread state). A holdout should assert
  size-bound rejections and context-resume idempotency.

### P-38 — Auth-as-injected-trait boundary (protocol/policy separation)
The server ships NO baked-in authentication. `RequestContextExtractor` (Send+Sync async trait)
is the single seam: operators inject a token→`RequestContext(user_id, scopes, metadata)`
extractor; `auth_middleware` maps its three error variants to 401/401/500 and inserts
`Option<RequestContext>` into request extensions, from which scopes reach tools via
`ToolContext::user_scopes()`. `adk-auth` supplies a concrete `JwtRequestContextExtractor`
(feature `auth-bridge`) + RBAC (`Permission`/`Role`/`AccessControl`), `ScopeGuard` tool
authorization, `AuditSink` (File/InMemory/OTLP/Postgres), and SSO/OIDC (Okta/Auth0/Azure/
Google/generic OIDC via JWKS with rotation).
- Evidence: `adk-server::auth_bridge::{RequestContextExtractor, RequestContextError}`,
  `rest::auth_middleware`, `adk-auth::{AccessControl, ScopeGuard, sso, auth_bridge}`.
- Quality: **STRONG** (as a seam) — cleanly separates transport (extract identity) from policy
  (RBAC/scope); the RBAC/audit/SSO surface is enterprise-grade and feature-gated.
- Ferrochain concern: ferrochain-server auth model + Domain-B "agent identity/provenance"
  governance primitive. The extractor-trait + scope-into-context flow is a strong reference for
  how authenticated identity should reach tool execution. See P-44 for the `get_secret -> String`
  credential-type concern.

## NEUTRAL patterns

### P-39 — Uniform cross-provider usage normalization (`UsageReport` / `SessionUsageTracker`)
`adk-managed::usage` normalizes every provider's token counts (Gemini prompt/candidates,
OpenAI prompt/completion, Anthropic input/output) into one `UsageReport` (input/output/total +
optional thinking/cache-read/cache-write), clamps negatives to 0, auto-computes total when the
provider omits it, and `SessionUsageTracker::record_turn` accumulates cumulative + last-turn.
`adk-telemetry::semconv` exposes matching OTel `gen_ai.usage.*` attribute constants.
- Evidence: `adk-managed::usage::{UsageReport::from_usage_metadata, SessionUsageTracker}`;
  `adk-telemetry::semconv::GEN_AI_USAGE_*`.
- Quality: **NEUTRAL** — clean, well-tested accounting, but *measurement only*: no dollar cost
  here (cost lives on `adk-core::UsageMetadata`), no ceiling, and nothing reads the tracker to
  gate execution. See P-46 (budget gap).
- Ferrochain concern: Domain-B budget metering. This is the accounting substrate a ferrochain
  budget-governance primitive would sit ON TOP of — not the primitive itself.

### P-40 — `awp-types`: zero-adk-dependency pure-wire-types crate
`awp-types` (1,171 LOC) holds all AWP protocol types (`AwpVersion`, `TrustLevel`,
`RequesterType`, `AwpRequest/Response`, `A2aMessage`, `CapabilityManifest`, `BusinessContext`,
`PaymentIntent`/`PaymentPolicy`) with zero `adk-*` deps and camelCase serde, so any Rust
project can depend on the wire contract without the framework. Its `a2a` module means AWP
carries A2A messages as one payload type (AWP is the outer web/trust/consent layer; A2A the
inner agent-RPC).
- Evidence: `awp-types::lib` re-export surface; `awp-types::a2a::{A2aMessage, A2aMessageType}`.
- Quality: **NEUTRAL** — good layering (wire-types crate separate from server impl `adk-awp`),
  but AWP itself is outside ferrochain's declared protocol scope; the transferable idea is
  "split wire types from transport," not AWP.
- Ferrochain concern: if ferrochain ever exposes a public wire contract, a dep-light types crate
  mirrors this. Otherwise informational. See protocol-landscape finding.

## WEAK / concerning observations

### P-41 — A2A `message_stream` is a state-transition stub (streaming ≠ send)
`message_send` runs the real ADK Runner (`run_agent`) and records LLM output as an artifact;
`message_stream` does NOT — it emits `Task → Working → Completed` status events with the
in-code note "Transition to COMPLETED (placeholder — Runner integration later)" and "actual
Runner streaming integration comes later." The streaming transport yields NO model output.
- Evidence: `adk-server::a2a::v1::request_handler::{message_send (run_agent), message_stream}`.
- Quality: **WEAK** — the two transports for the same operation diverge behaviorally; the
  streaming path is a defer-pattern ("later"). Under the production-grade default this is the
  "ship partial now, wire later" smell.
- Ferrochain concern: ferrochain-server SSE/streaming run contract (platform §2.3 `/runs/stream`)
  MUST make streaming and unary runs behaviorally equivalent (both drive the engine). A holdout
  should assert the streaming path produces real output, not just status transitions.

### P-42 — Outbound `reqwest::Client` built without timeout across the whole cluster
Every outbound HTTP client in the cluster is `reqwest::Client::new()` with NO `.timeout(...)`:
A2A push sender (`push.rs`), A2A client (`a2a/client.rs`, 5 sites), JWKS fetch
(`adk-auth::sso::jwks`), OIDC discovery (`adk-auth::sso::providers::oidc`). A cluster-wide grep
for `.timeout(` in server/auth/awp/acp/managed/enterprise `src/` returns ZERO hits. (The inbound
axum `TimeoutLayer` in P-36 is a server-side *request* timeout, unrelated to the outbound client.)
- Evidence: `grep -rn "reqwest::Client::new()"` → 7 sites vs `grep -rn "\.timeout("` → 0 sites
  across `adk-server/src`, `adk-auth/src`, `adk-awp/src`, `adk-acp/src`, `adk-managed/src`,
  `adk-enterprise/src`.
- Quality: **WEAK** — a hung webhook receiver, JWKS endpoint, or remote A2A agent blocks the
  delivery/validation task indefinitely (bounded only by OS TCP timeouts). Exactly the failure
  ferrochain's mandatory-30s-timeout convention prevents.
- Ferrochain concern: RESOLVES A1 open item (reqwest timeout sites). Every ferrochain outbound
  client — provider calls AND server-side push/JWKS/remote-agent — must set
  `.timeout(Duration::from_secs(30))` (or NFR override). adk-rust is a counter-example here,
  not a template.

### P-43 — Non-durable, unbounded in-memory state in the request path
Multiple request-path stores are `RwLock<HashMap>`-only, no persistence, no eviction: the A2A
idempotency map (`messageId→taskId`, grows unbounded, lost on restart — so idempotency AND
INPUT_REQUIRED resume break across a process bounce), the default `InMemoryTaskStore`, the
token-bucket `buckets` map in `RateLimitInterceptor` (one entry per caller_id, never evicted),
and the background `RunStore`. `TaskStore`/`RunStore` are traits (durable impl possible), but the
idempotency map and rate-limit buckets are hard-wired in-memory with NO trait seam.
- Evidence: `RequestHandler.idempotency_map: RwLock<HashMap<..>>`; `InMemoryTaskStore`;
  `RateLimitInterceptor.buckets: Arc<Mutex<HashMap<..>>>`; `background::RunStore`.
- Quality: **WEAK** — Domain B needs "multi-day durable runs surviving process restarts"; the
  idempotency + rate-limit state have no durability seam at all, and unbounded maps are a slow
  memory leak under many distinct caller/message IDs.
- Ferrochain concern: ferrochain-server idempotency + rate-limit + run/task state need a
  persistence seam from v1 (checkpointer/store-backed), not an in-memory afterthought. Relates to
  A2's P-29 (graph step-boundary durability).

### P-44 — Secrets flow as bare `String` (no redacted newtype)
`SecretProvider::get_secret(&self, name) -> Result<String, AdkError>` and the
`SecretServiceAdapter`→`adk_core::SecretService` bridge both return a plain `String`; the trait
doc example does `println!("...length {}", api_key.len())`. No redacted newtype wraps the
retrieved secret.
- Evidence: `adk-auth::secrets::provider::{SecretProvider, SecretServiceAdapter}`.
- Quality: **WEAK** — a `String` secret has default `Debug`/`Display` and can be logged or
  captured in a span/error verbatim; nothing at the type level prevents leakage.
- Ferrochain concern: DIRECT divergence from CLAUDE.md "Newtype + redacted Debug for
  credentials." Ferrochain's `SecretService`-analog must return a redacted newtype
  (`impl Debug` → `<redacted>`), not `String`.

### P-45 — Permissive-by-default posture toggles
`SecurityConfig::default()` leaves `allowed_origins` empty, which `build_cors_layer` maps to
`AllowOrigin::any()`; and the `/debug/trace/{event_id}` route is exposed whenever
`request_context_extractor.is_none()` (auth unconfigured) OR `expose_admin_debug` is set.
`::production(...)` and `::development()` presets exist, but `default()` is dev-shaped.
- Evidence: `adk-server::config::SecurityConfig::default`; `rest::build_cors_layer`; the
  `expose_admin_debug` gate on the debug router.
- Quality: **WEAK** — secure-by-default is the production-grade posture; a `default()` that is
  CORS-open and (when auth is absent) debug-trace-exposed inverts it.
- Ferrochain concern: ferrochain-server config should be secure-by-default (deny CORS unless
  configured; never expose trace/debug without explicit opt-in). Maps to security-review.

### P-46 — No budget/cost-ceiling enforcement anywhere in the cluster (Domain-B gap)
There is token *accounting* (P-39), request-*rate* limiting (token bucket, P-43), commerce spend
policy (`adk-payments::guardrail::amount_policy` — for PAYMENTS, a different domain), and OTel
token attributes — but NOTHING that (a) converts tokens→cost against a budget, (b) sets a
per-run or per-sub-agent ceiling, or (c) halts/degrades a run at a ceiling. `RunConfig` has
`max_transfer_depth` (loop guard) but no token/cost budget field; `SessionUsageTracker` is never
read to gate execution.
- Evidence: absence — `adk-managed::usage` (measure only), `a2a::rate_limit` (request-rate only),
  `adk-payments::guardrail::amount_policy` (commerce), no budget field on `adk-core::RunConfig`.
- Quality: **WEAK** (gap, not a defect) — the same budget-governance gap ferrochain's Domain B
  flagged as NEW. adk-rust does NOT close it; it stops at accounting + rate-limiting.
- Ferrochain concern: confirms the Domain-B budget-metering capability is genuinely novel — no
  reference-corpus prior art. A ferrochain budget-governance primitive (per-run/per-agent
  token+cost ceiling with halt-or-degrade) must be designed, layered on a `UsageReport`-style
  accounting substrate, and made a first-class run-config + engine gate.

## Pass A3 cross-cutting note (informative, not a conclusion)
The server cluster's strengths are HTTP-boundary hygiene (SSRF gate P-35, security-header stack
P-36, exhaustive A2A input validation P-37, auth-as-injected-trait P-38) and enterprise auth/
audit depth. Its weaknesses cluster around *unfinished execution seams* (streaming stub P-41,
background-run placeholder — see module-inventory A3), *non-durable in-memory request-path state*
(P-43), and *credential/CORS posture defaults* (P-44, P-45) that diverge from ferrochain
conventions — plus the cluster-wide missing outbound reqwest timeout (P-42). Budget governance is
absent (P-46), confirming Domain B's gap is real. Any influence on ferrochain is deferred to the
post-validation comparative assessment per D16.

## State Checkpoint
```yaml
pass: A3
scope: patterns-observed (server/protocol/auth cluster)
patterns_added: 12 (P-35..P-46 — 4 STRONG, 2 NEUTRAL, 6 WEAK)
patterns_total: 46
open_items_resolved: [reqwest-timeout-sites (P-42), anyhow-public-signatures (see dependency-disposition A3)]
status: complete
timestamp: 2026-07-13
```
