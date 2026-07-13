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
- Evidence: `adk-core::event::Event::is_final_response` + 9-test suite. <!-- [comparative-sweep] CORRECTION: "11-case test truth table" → 9 distinct fn test_is_final_response_* functions (grep -c "fn test_is_final_response" adk-core/src/event.rs = 9). Quality tag unaffected. -->
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
`workflow_schema` all carry `*_property_tests.rs`. 262 test fns crate-wide (attribute-only: `grep -rE '#\[(test|tokio::test)\]' adk-graph/`; [comparative-cert-1] canonical methodology replaces prior "208" which used double-counting and "197/223" which used fn-name grep); the `Diff` round-trip,
switch routing, deferred fan-in, and timeout laws are checked over generated inputs.
- Evidence: `adk-graph/tests/*_property_tests.rs` (8 of 14 files), `delta.rs`/`typed_reducer.rs`
  in-crate truth tables.
- Quality: **STRONG** — property tests over a state-machine runtime encode invariants
  (round-trip, routing totality, fan-in completeness) a re-implementer can lift as a conformance
  suite. This is the highest-value test-as-spec form for an execution engine. <!-- [comparative-sweep] CORRECTION: "208 test fns crate-wide" → actual `fn test_*` count = 197 (grep -rn "fn test_" adk-graph/ --include="*.rs" | wc -l); proptest fns (fn prop_*) bring the all-function total to 223; 208 matches neither. Quality tag unaffected. -->
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

Deep scope: `adk-server` (22,373 LOC src/ <!-- [comparative-sweep] CORRECTION: "20,752 LOC" → 22,373 (find adk-server/src -name "*.rs" | xargs wc -l); delta = +1,621 -->), A2A v1.0.0, `adk-awp`/`awp-types`/`adk-acp`,
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
`awp-types` (1,537 LOC <!-- [comparative-sweep] CORRECTION: "1,171 LOC" → 1,537 (find awp-types/ -name "*.rs" | xargs wc -l); delta = +366. Quality tag unaffected. -->) holds all AWP protocol types (`AwpVersion`, `TrustLevel`,
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
- Evidence: `grep -rn "reqwest::Client::new()"` → 8 sites (without adk-enterprise) <!-- [comparative-sweep] CORRECTION: "7 sites" → actual 8 in {adk-server,adk-auth,adk-awp,adk-acp,adk-managed}/src combined (5 in a2a/client.rs, 1 in push.rs, 1 in sso/jwks.rs, 1 in sso/providers/oidc.rs). Including adk-enterprise/src (as evidence text states) adds 36 more sites = 44 total — evidence scope claim is contradicted by the "7" figure. The zero `.timeout(` result is independently verified correct. --> vs `grep -rn "\.timeout("` → 0 sites
  across `adk-server/src`, `adk-auth/src`, `adk-awp/src`, `adk-acp/src`, `adk-managed/src`.
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

---

# Pass A4 — SAFETY / QUALITY cluster (guardrail, sandbox, eval, retry-reflect, skill, plugin, code, browser)

Same D16 Rust-blindness constraint: quality tags judge production-grade merit ONLY; observe,
do not conclude adoption. Evidence cited by function/type + behavioral anchor. Twenty new
patterns (P-47…P-66). Primary mapping targets: Domain A untrusted-content-isolation, Domain C
inverted-security-posture + sandboxing demands, Domain B quality-gate / holdout-evaluation
machinery, and CLAUDE.md safety conventions (no-unwrap, credential safety, no-silent-swallow).

Cluster sizes (in-workspace `.rs` LOC): adk-eval 8,226 · adk-code 9,081 (host-local Rust exec +
container + WASM guest) · adk-sandbox 7,521 · adk-browser 5,160 · adk-plugin 3,653 · adk-skill
2,325 · adk-retry-reflect 1,031 · adk-guardrail 1,015.

## STRONG patterns

### P-47 — WASM backend: full in-process isolation with a truthful capability descriptor
`WasmBackend` (feature `wasm`) executes WASM/WAT via `wasmtime`: no filesystem preopens, no
network, memory bound via `StoreLimitsBuilder`, wall-clock timeout via epoch-interruption (an OS
timer thread calls `increment_epoch`), run on `spawn_blocking`. `capabilities()` reports
`EnforcedLimits { timeout, memory, network_isolation, filesystem_isolation, environment_isolation }`
all `true` — and this is the ONE backend where all five are honestly `true`.
- Evidence: `adk-sandbox::wasm::{WasmBackend::execute_sync, capabilities}`; `WasmStoreData`
  (WASI + StoreLimits); `test_timeout_enforcement`, `test_memory_limit_enforcement`,
  `test_nonzero_exit_code`.
- Quality: **STRONG** — this is genuine capability-based isolation (deny-by-default: the guest
  can only touch what WASI is linked to, and only stdin/stdout/stderr are linked). Timeout via
  epoch interruption is the correct wasmtime idiom.
- Ferrochain concern: Domain C sandboxing (untrusted code execution). WASM is the strongest
  isolation primitive in the corpus; a ferrochain code-exec story should treat WASM (or a
  container) as the default enforcing backend, not the process backend (P-61). See P-66 for the
  `.expect()` panic-on-init nit.

### P-48 — Linux bubblewrap enforcer: deny-by-default namespace isolation
`LinuxEnforcer` wraps the child as `bwrap <args> -- <program> <args>`; args always include
`--die-with-parent` and `--unshare-pid`, add `--unshare-net` unless network is allowed,
`--new-session` unless process-spawn is allowed, and expose ONLY the policy's allowed paths via
`--ro-bind`/`--bind`. `probe()` verifies both the `bwrap` binary and that unprivileged user
namespaces actually work. Policy paths are `canonicalize`d (symlink warn) before wrapping.
- Evidence: `adk-sandbox::sandbox::linux::{LinuxEnforcer::generate_args_from_paths, wrap_command,
  probe}`; `canonicalize_paths`; `test_generate_args_deny_all` (asserts unshare-net + new-session).
- Quality: **STRONG** — bubblewrap gives real kernel-enforced filesystem/network/pid isolation
  with a nothing-visible-unless-bound default, without root. This is the correct shape for a
  Linux code sandbox.
- Ferrochain concern: Domain C sandboxing on Linux. Contrast the macOS enforcer, which is
  allow-by-default (P-60) — the two platforms give materially different guarantees under the
  same `SandboxPolicy`.

### P-49 — Truthful backend-capability descriptor (honesty over false security)
Every sandbox backend reports what it actually enforces via `BackendCapabilities`/`EnforcedLimits`,
and the docs are blunt: `ProcessBackend` "enforces timeout and environment isolation but not
memory or network isolation"; the memory-limit request on the process backend logs
`"memory limit not enforced by process backend"` rather than pretending. adk-code repeats the
pattern with `BackendCapabilities.enforce_filesystem_policy`.
- Evidence: `adk-sandbox::backend::{BackendCapabilities, EnforcedLimits}`;
  `ProcessBackend::{capabilities, execute}` debug log; `adk-code::types::BackendCapabilities`.
- Quality: **STRONG (as a design principle)** — a security component that lies about its
  guarantees is worse than one that is honest; exposing enforced-vs-declared lets a caller refuse
  a non-enforcing backend. NOTE the double edge: honesty does not *force* enforcement — nothing
  stops a caller from running untrusted code on a backend whose limits are all `false` (P-61/P-62).
- Ferrochain concern: Domain C. A ferrochain sandbox trait should carry this truthful-capability
  descriptor AND a policy gate that refuses to run untrusted code on a backend that cannot enforce
  the requested isolation (turn honesty into a hard precondition).

### P-50 — Retry-&-reflect via `after_tool_call` reflection injection (not blind re-execution)
On a tool result that looks like an error (`{"error":…}` / `{"isError":true}` / `"Error:"`-prefixed
string), the plugin does NOT re-invoke the tool. It increments a per-`(tool,args-hash)` counter,
sleeps a computed backoff, and REPLACES the tool result with `{"reflection": "<templated prompt>"}`
so the agent self-corrects on the next turn. Termination is bounded by three opt-in layers:
per-tool `effective_limit`, invocation-wide `global_limit`, and a cross-invocation circuit-breaker
(`GlobalRetryTracker::is_circuit_broken`); on exhaustion the original error is passed through.
- Evidence: `adk-retry-reflect::plugin::RetryReflectPlugin::after_tool_call` (9-step flow);
  `detection::is_error_result`; `backoff::compute_backoff` (saturating exponential, ceiling);
  `tracker::{RetryTracker, GlobalRetryTracker}`; `template::render_reflection`.
- Quality: **STRONG (mechanism & backoff)** — reflection-injection is a smarter recovery than
  blind retry (the model gets structured error+args+guidance and can change its approach); backoff
  uses saturating arithmetic (no overflow); exhaustion surfaces the real error rather than swallowing.
  The per-tool *bound* has a hole — see P-63.
- Ferrochain concern: reliability/self-correction; the tool-failure analog of adk-model's
  transport retry (P-03). A ferrochain tool-retry story should hook at the equivalent
  after-tool-call seam and keep the "surface real error on exhaustion" discipline.

### P-51 — Skill ContextCoordinator: phantom-tool prevention as an atomic instruction+tools unit
The coordinator explicitly names the "Phantom Tool" failure (a skill body says "use tool X" but X
isn't bound → the LLM hallucinates the call) and prevents it: selection → VALIDATION of the skill's
`allowed-tools` against a host `ToolRegistry` (with a `ValidationMode`) → a `SkillContext` that
delivers the system instruction and the resolved `Vec<Arc<dyn Tool>>` as ONE atomic
`ResolvedContext`. An agent never receives instructions referencing an unbound tool.
- Evidence: `adk-skill::coordinator::{ContextCoordinator, SkillContext, CoordinatorConfig,
  ValidationMode}`; `adk_core::{ResolvedContext, ToolRegistry}`.
- Quality: **STRONG** — binding the cognitive frame (prompt) and the physical capability (tools)
  atomically is the correct way to keep skill instructions and tool availability in sync; the
  named-failure-mode-driven design is disciplined.
- Ferrochain concern: skill/capability model. If ferrochain adopts a SKILL.md-style model, this
  instruction↔tool-binding validation is the load-bearing safety property. NOTE: this validates
  capability wiring, NOT skill content — there is no scan of the skill body for injected/malicious
  instructions (skills are trusted markdown; see cross-cutting note).

### P-52 — Priority-ordered plugin hook pipeline with short-circuit and documented priority bands
`EnhancedPlugin` exposes `before/after_{tool,model}_call` hooks with `Continue | ShortCircuit`
before-semantics and `Continue`-only after-semantics; plugins run in ascending `priority()`
(lower first, ties by registration order) with a documented band convention (0–25 security,
26–50 caching, 51–75 transformation, 76–100 logging, 100+ app). `Err` stops the pipeline and
propagates; `ShortCircuit` skips the underlying op and halts the chain.
- Evidence: `adk-plugin::enhanced_plugin::EnhancedPlugin` (priority table in doc);
  `hook_result::{BeforeToolCallResult, AfterToolCallResult, BeforeModelCallResult,
  AfterModelCallResult}`.
- Quality: **STRONG** — a clean, composable extension seam with explicit ordering and
  well-defined short-circuit vs continue vs error semantics; the priority bands make security
  plugins run first by convention.
- Ferrochain concern: cross-cutting extensibility (callbacks/middleware). The before/after +
  short-circuit + priority model is a solid reference for a ferrochain plugin/middleware seam,
  including where guardrails and budget-gates (Domain B) would hook. See P-58 for the two-model
  duplication concern.

### P-53 — Evaluation harness: declarative datasets + multi-criteria scoring, all criteria wired
`.test.json`/`.evalset.json` datasets (`TestFile`→`EvalCase`→`Turn` with `user_content`,
`final_response`, `intermediate_data.tool_uses`) drive an `Evaluator` that applies EVERY declared
criterion: tool-trajectory (ordered/unordered, strict/partial args), text similarity (Exact,
Contains, Levenshtein, Jaccard, ROUGE-1/2/L with a Unicode/CJK-aware tokenizer), LLM-judge semantic
match, rubric-weighted quality, safety, hallucination, structured typed verdicts, plus optional
cost-tracker / trace-analyzer / embedding / conversation scorers. The LLM judge runs at
temperature 0.0 for determinism.
- Evidence: `adk-eval::schema::{TestFile, EvalCase, Turn, ToolUse}`;
  `scoring::{ToolTrajectoryScorer, ResponseScorer}` (DP Levenshtein/LCS, `unicode_tokenize`);
  `evaluator::Evaluator::score_turn` (all of tool_trajectory/response_similarity/semantic_match/
  rubric_quality **and** safety_score@L626 + hallucination_score@L665 are dispatched);
  `llm_judge::LlmJudgeConfig { temperature: 0.0 }`; `structured_judge::StructuredVerdict`.
- Quality: **STRONG (breadth & test-as-spec value)** — a genuinely comprehensive harness; the
  trajectory/similarity scorers are deterministic and unit-tested, which makes them liftable as a
  conformance suite. (Two scoring-correctness bugs demote *rigor* — see P-64 — but the criterion
  coverage is real and each criterion is actually invoked, verified against the source.)
- Ferrochain concern: DIRECT map to holdout-evaluation machinery + Domain-B quality gates. The
  declarative dataset shape and the deterministic (non-LLM) scorers are the reusable core; the
  LLM-judge pieces need the P-65 infra-failure-vs-quality-failure fix.

### P-54 — Browser: defensive JS-string escaping for selector interpolation
`escape_js_string` escapes `\ ' " \` \n \r \0` and, notably, `<`/`>` to `\x3c`/`\x3e` so a
user-supplied CSS selector interpolated into a `document.querySelector('…')` JS payload cannot
break out of the string literal or inject `</script>`. Tested against an explicit injection
attempt (`'); document.cookie='stolen'; ('`).
- Evidence: `adk-browser::escape::escape_js_string`; `test_escape_injection_attempt`,
  `test_escape_script_tags`.
- Quality: **STRONG (small but correct)** — treating LLM/user-derived selectors as untrusted
  before splicing them into an eval'd JS string is exactly the right defense-in-depth for a
  browser-automation tool surface.
- Ferrochain concern: any ferrochain tool that interpolates model/user text into an executable
  substrate (JS, shell, SQL) must escape at the boundary. Contrast the sandbox `Language::Command`
  path (P-61) which splices code straight into `sh -c` with no escaping (different trust model,
  but the asymmetry is worth noting).

## NEUTRAL patterns

### P-55 — Guardrail trait model: Pass / Fail / Transform with a severity ladder
`Guardrail::validate(&Content) -> GuardrailResult{ Pass | Fail{reason,severity} | Transform{new_content} }`;
`GuardrailExecutor::run` partitions guardrails into parallel (`join_all`) and sequential (for
content-transforming ones like PII), early-exits only on `Severity::Critical` + `fail_fast`, and
computes `passed = failures.empty() || all-Low`. `Severity` = Low/Medium/High/Critical.
- Evidence: `adk-guardrail::{traits::Guardrail, executor::GuardrailExecutor::run, ExecutionResult}`;
  `PiiRedactor` (Transform, `run_parallel=false`), `ContentFilter`, `SchemaValidator`.
- Quality: **NEUTRAL** — the trait shape (three-way result, parallel/sequential split, severity
  ladder) is clean and composable; but the built-in filters are naive (P-59) and enforcement is
  opt-in + caller-dependent (P-59 evidence). The *framework* is fine; the *policy* is thin.
- Ferrochain concern: Domain A/C content-validation seam. The Pass/Fail/Transform + severity model
  is worth mirroring; the built-in checks are not.

### P-56 — Content-addressed skill identity + layered discovery with precedence
Skills carry an `id = name + SHA256(content)` and a `hash`; discovery walks `.skills/` and
`.claude/skills/` (plus optional global `~/.config/adk/skills` and extra dirs), merges convention
files (`AGENTS.md`, `CLAUDE.md`, `SOUL.md`, …) parsed leniently, dedupes, and sorts.
Project-local skills take precedence over global on name collision. Selection is weighted lexical
overlap (name +4.0, desc +2.5, tag +2.0, body +1.0, normalized by √body-tokens), tag include/exclude.
- Evidence: `adk-skill::{model::SkillDocument.id/hash, discovery::discover_instruction_files_with_extras,
  parser::parse_instruction_markdown, select::{select_skills, score_skill}}`.
- Quality: **NEUTRAL** — content-addressed IDs (change detection, dedupe) and layered precedence
  are sound; lexical-overlap selection is a reasonable no-embeddings default but is keyword-bag
  matching, not semantic (an embedding scorer exists elsewhere in the corpus but isn't wired here).
- Ferrochain concern: skill discovery/precedence if ferrochain adopts a SKILL.md model. The
  `.skills/` + `.claude/skills/` + convention-file scan closely parallels OpenClaw's model.

### P-57 — adk-code declarative SandboxPolicy: strict-by-default with truthful capability flags
`adk-code::SandboxPolicy::default() == strict_rust()` (no network, no filesystem, no env, 30s
timeout, 1 MB limits); a separate `dev_local()` preset documents that host-local backends CANNOT
enforce network/fs and executed code has host access. `BackendCapabilities.enforce_filesystem_policy`
tells a caller whether the chosen backend honors the policy.
- Evidence: `adk-code::types::{SandboxPolicy::strict_rust/dev_local/default, FilesystemPolicy::None,
  BackendCapabilities}`.
- Quality: **NEUTRAL** — the DEFAULT policy is correctly deny-all and the capability flag is
  honest; but the flagship backend does not enforce it (P-62), so a safe-looking `default()` +
  default executor combination is not actually isolated.
- Ferrochain concern: Domain C. Strict-by-default policy is the right instinct; the gap is that
  policy strictness and backend enforcement are decoupled with no gate binding them.

### P-58 — Two parallel plugin models and two parallel SandboxPolicy types (drift surface)
`adk-plugin` ships BOTH a closure-based `Plugin`/`PluginConfig`/`PluginManager` (adk-go parity;
`on_user_message`, used by the skill injector) AND a trait-based `EnhancedPlugin`/
`EnhancedPluginManager` (used by retry-reflect). Separately, `adk-sandbox::SandboxPolicy` and
`adk-code::SandboxPolicy` are distinct types modeling the same concept.
- Evidence: `adk-plugin::{plugin::Plugin, enhanced_plugin::EnhancedPlugin}`;
  `adk-sandbox::sandbox::SandboxPolicy` vs `adk-code::types::SandboxPolicy`.
- Quality: **NEUTRAL (leaning WEAK)** — two extension models and two policy types invite drift and
  "which do I use?" ambiguity (same shape as A1's P-16 provider duplication). Justifiable as a
  migration (closure→trait) but undocumented as such.
- Ferrochain concern: ferrochain should pick ONE plugin/middleware model and ONE sandbox-policy
  type. This is a defer-pattern smell if the duplication is "consolidate later."

## WEAK / concerning observations

### P-59 — Guardrails are keyword/regex filters, not a policy engine, and never see tool/RAG content
The built-in guardrails are: a keyword blocklist (`ContentFilter::harmful_content` = SIX words:
kill/murder/bomb/terrorist/malware/ransomware, word-boundary regex), required-topic/length checks,
regex PII redaction, and JSON-schema validation. There is NO prompt-injection detection, NO
semantic classification, NO policy/rule engine. Enforcement is feature-gated (`guardrails` feature;
disabled = no-op `enforce_guardrails`) AND runs ONLY on the initial `user_content` (input) and the
final generated `content` (output). Tool results, RAG/retrieval output, and memory content entering
the model context are NEVER passed through any guardrail. The executor's `passed` flag treats
Medium/High as fail but only Critical+fail_fast hard-errors — everything else depends on the caller
inspecting `ExecutionResult.passed`.
- Evidence: `adk-guardrail::content::ContentFilter::harmful_content` (6-word list);
  `adk-agent::guardrails::enforce_guardrails` (feature-gated; else clone-through);
  `adk-agent::llm_agent::{apply_input_guardrails (on `ctx.user_content()`), apply_output_guardrails}`;
  no guardrail call on tool-result/RAG ingestion paths.
- Quality: **WEAK** — for Domain A "untrusted-content-isolation," the critical surface is content
  that ENTERS the context from tools/retrieval/memory (the classic indirect-prompt-injection
  vector), and that surface is entirely unguarded here. The harmful-content list is trivially
  bypassed (obfuscation, translation, encoding, synonyms). This is a filter, not a defense.
- Ferrochain concern: Domain A untrusted-content-isolation + Domain C inverted-security-posture.
  A ferrochain design must (a) tag/isolate untrusted content by provenance, (b) run
  validation on the INGRESS of tool/RAG/memory content, not just user input + final output, and
  (c) not rely on keyword blocklists as the primary defense. adk-rust is a counter-example here.

### P-60 — macOS Seatbelt enforcer is allow-by-default: file READS are unrestricted
The generated Seatbelt profile is `(version 1)(deny default)(allow default)` — the later
`(allow default)` wins, so the baseline is ALLOW-everything, then it selectively denies
`network*` (unless allowed), `file-write*` (re-allowing only policy paths), and `process-fork`.
It never denies `file-read*`. The code comments call this "more practical than a pure whitelist."
Consequence: sandboxed untrusted code on macOS can READ any file the user can — SSH keys,
`~/.aws/credentials`, `/etc`, browser cookies — regardless of `allowed_paths`.
- Evidence: `adk-sandbox::sandbox::macos::MacOsEnforcer::generate_profile_from_paths`
  (`(allow default)` then `(deny file-write*)` but no `(deny file-read*)`);
  `test_generate_profile_read_only_path` asserts only read-allow + write-absence.
- Quality: **WEAK (isolation gap)** — read confinement is half of filesystem isolation, and the
  half that matters most for credential/secret exfiltration. The same `SandboxPolicy` yields
  deny-by-default reads on Linux (P-48) but allow-all reads on macOS — a silent per-platform
  security asymmetry.
- Ferrochain concern: Domain C sandboxing. A ferrochain macOS sandbox must be deny-by-default for
  reads too (enumerate allowed read subpaths under `(deny default)`), accepting the syscall-
  enumeration cost, OR document macOS as a non-isolating platform and refuse untrusted exec there.

### P-61 — Default `ProcessBackend` provides no fs/network/memory isolation; `Command` = raw `sh -c`
The default feature is `process`; a bare `ProcessBackend::default()` has NO enforcer, so
`EnforcedLimits` is `{ timeout:true, memory:false, network_isolation:false,
filesystem_isolation:false, environment_isolation:true }` — only `env_clear()` + a tokio timeout.
`Language::Command` runs the code verbatim as `sh -c "<code>"` (or `cmd /C` on Windows). The OS
enforcers (bubblewrap/Seatbelt/AppContainer) and the WASM backend are ALL opt-in via feature flags
and (for OS enforcers) require external binaries present at runtime.
- Evidence: `adk-sandbox::process::{ProcessBackend::default, capabilities, execute_command
  (`sh -c`)}`; `Cargo.toml [features] default = ["process"]`; `get_enforcer()` returns
  `EnforcerUnavailable` unless a `sandbox-*` feature is compiled in.
- Quality: **WEAK (default posture)** — the out-of-the-box "sandbox" is not a sandbox: it is a
  child process with a cleared env and a timeout, able to open sockets, read/write the whole
  filesystem, and (via `Command`) run arbitrary shell. Secure isolation is strictly opt-in.
- Ferrochain concern: Domain C. Secure-by-default is the production-grade posture; a ferrochain
  code-exec surface should default to an ENFORCING backend (WASM/container) and make the
  no-isolation process backend an explicit, loud opt-in. Parallels A3's P-45 permissive defaults.

### P-62 — adk-code phase-1 RustSandboxExecutor is host-local: `strict_rust` policy is unenforced
The "flagship Rust-authored" executor compiles user Rust with `rustc` and runs the binary as a
host-local process (documented "phase 1"). It restricts the SOURCE model (single `run()` fn, only
`serde_json` linked, rejects user `fn main()`), but the runtime has full host network + filesystem
access — the `strict_rust()` policy's "no network / no filesystem" is declarative and NOT enforced
by this backend. Only the container backend (bollard/Docker, opt-in) or the WASM guest isolate.
- Evidence: `adk-code::rust_sandbox` module doc ("host-local process approach (phase 1)",
  "the backend is honest about its capabilities"); `adk-code::types::SandboxPolicy::dev_local`
  ("host-local backends … cannot enforce network or filesystem restrictions").
- Quality: **WEAK (policy/enforcement decoupling)** — a caller who builds `strict_rust()` and runs
  it on the default Rust executor gets a policy object that promises isolation the backend does not
  deliver, with only a capability flag (that nothing forces them to check) as the tell.
- Ferrochain concern: Domain C. Same root issue as P-49/P-57: policy strictness must be bound to
  backend enforcement by a hard precondition, or "strict" is theater. A ferrochain executor must
  refuse to run under a strict policy on a backend whose `enforce_*` flags are false.

### P-63 — retry-reflect per-tool limit is keyed by args-hash → an arg-changing agent bypasses it
The retry counter key is `"{tool_name}:{hash(args)}"`. But the injected reflection prompt explicitly
instructs the model to "retry the tool call with corrected arguments." A model that changes args
each attempt (the intended behavior) produces a NEW hash each time, so `effective_limit` (default 3)
is checked against a counter that keeps resetting to 0 — the per-tool bound is effectively unbounded
for a self-correcting agent. The only real bounds are the opt-in `global_limit` (default `None` =
unlimited) and the opt-in global circuit-breaker (`global_tracking=false` by default).
- Evidence: `adk-retry-reflect::plugin::after_tool_call` (`call_id = hash(args.to_string())`,
  `tracker_key = "{tool_name}:{call_id}"`, checked vs `effective_limit`); `config::RetryReflectConfig`
  defaults (`global_limit: None`, `global_tracking: false`).
- Quality: **WEAK (termination guarantee)** — the headline "per-tool retry limit" does not bound
  the loop under the plugin's own intended usage; runaway protection requires explicitly enabling
  a global limit or circuit-breaker, neither of which is on by default.
- Ferrochain concern: reliability/termination. A ferrochain retry primitive must key its bound on
  `(tool)` or `(tool, call-site)` — NOT on argument content — and default to a finite global bound.

### P-64 — Eval multi-turn score merge is order-dependent; judge failure conflates with quality
Merging per-turn scores uses `entry.and_modify(|s| *s = (*s + score) / 2.0)` — a pairwise running
"average" that weights later turns exponentially more and is NOT the mean of the turns (3 turns of
1.0,1.0,0.0 → 0.25, not 0.667). Separately, when the structured/safety/hallucination judge call
FAILS (e.g. API outage), the code inserts score `0.0` / a `Fail` verdict — so a judge INFRASTRUCTURE
failure is indistinguishable from the agent producing an unsafe/wrong answer. And with a cost-tracker
or trace-analyzer configured, `collect_case_events` RE-RUNS the agent (a second nondeterministic
execution) beyond the per-turn runs.
- Evidence: `adk-eval::evaluator::evaluate_case` (score merge @ ~L278; structured-judge fallback
  `StructuredVerdict{ score:0.0, Verdict::Fail }` @ ~L322; `collect_case_events` re-run @ ~L290,
  gated on cost/trace configured @ ~L377).
- Quality: **WEAK (scoring rigor)** — an evaluation harness whose aggregate score is order-dependent
  and whose "fail" can be a masked infra error is unreliable as a quality gate; the extra agent
  run adds nondeterminism and cost.
- Ferrochain concern: holdout-evaluation + Domain-B quality gates. A ferrochain harness must (a)
  aggregate turn scores with a defined, order-independent reduction, (b) distinguish
  judge-infrastructure-error from quality-fail (a third outcome, not score 0.0), and (c) run the
  agent once per case and reuse the event stream.

### P-65 — Workspace path safety is string-only (no symlink resolution)
`validate_relative_path` rejects empty/absolute/drive-letter paths and `..` components that escape
root by tracking depth on the STRING — it never touches the filesystem, so a symlink that lives
inside the workspace but points outside it passes validation. The enforcers `canonicalize` the
policy's allowlist entries (and warn on symlink divergence) but that is a build-time check of the
allowlist, not a runtime check of the path a workspace file operation resolves to.
- Evidence: `adk-sandbox::workspace::path_safety::validate_relative_path` (pure string depth
  tracking; doc "Paths with `..` that stay within bounds are allowed"); no `canonicalize`/
  `symlink_metadata` in the validator.
- Quality: **WEAK (symlink-escape / TOCTOU)** — string-level traversal defense is necessary but
  insufficient; without resolving symlinks (or opening with `O_NOFOLLOW`/`openat2(RESOLVE_BENEATH)`)
  a workspace client that follows symlinks can read/write outside the root.
- Ferrochain concern: Domain C workspace/file-tool isolation. A ferrochain workspace boundary must
  resolve+verify the real path is beneath root at access time (canonicalize under the root, or use
  a beneath-root open), not only string-validate the requested path.

### P-66 — `WasmBackend::new()` uses `.expect()` on engine init (panic in a production constructor)
`WasmBackend::new()` calls `Engine::new(&config).expect("failed to create wasmtime engine …")` and
is invoked by `Default`. Engine construction failure (e.g. bad config on a platform) panics rather
than returning a `Result`.
- Evidence: `adk-sandbox::wasm::WasmBackend::new`.
- Quality: **WEAK (minor)** — a panic path in a library constructor; diverges from ferrochain's
  "no unwrap/expect in non-test code" rule. Low likelihood, but a sandbox is exactly where you do
  not want an unhandled panic on init.
- Ferrochain concern: CLAUDE.md no-unwrap/expect discipline. A ferrochain WASM backend constructor
  must return `Result` and propagate engine-init failure via the error taxonomy.

## Pass A4 cross-cutting note (informative, not a conclusion)
The cluster's strongest work is the WASM/bubblewrap isolation primitives (P-47, P-48), the
truthful-capability principle (P-49), the reflection-injection recovery loop (P-50), the
phantom-tool-preventing skill coordinator (P-51), the priority-ordered plugin seam (P-52), the
broad evaluation harness (P-53), and small correct defenses like JS-escaping (P-54). Its
weaknesses cluster in exactly the two places ferrochain's holdout domains probe hardest:
(1) **untrusted-content isolation is essentially absent** — guardrails are keyword/regex filters
that only see user input + final output and never the tool/RAG/memory content that carries
indirect prompt injection (P-59); and (2) **the DEFAULT sandbox posture does not isolate** — the
default process backend has no fs/net/memory isolation and runs raw `sh -c` (P-61), macOS is
allow-by-default for reads (P-60), the flagship Rust executor is unenforced host-local (P-62), and
workspace path safety is symlink-blind (P-65). Enforcement is consistently opt-in and decoupled
from policy strictness. Budget/cost governance remains absent here too (consistent with A3's P-46).
Any influence on ferrochain is deferred to the post-validation comparative assessment per D16.

## State Checkpoint
```yaml
pass: A4
scope: patterns-observed (safety/quality cluster)
patterns_added: 20 (P-47..P-66 — 8 STRONG, 4 NEUTRAL, 8 WEAK)
patterns_total: 66
open_items_resolved:
  - anyhow-in-cluster (only a doc-comment example in adk-browser; no public-signature leak)
  - reqwest-in-cluster (none; adk-browser uses thirtyfour/WebDriver)
status: complete
timestamp: 2026-07-13
```

---

# Pass A5 — PROVIDER / CAPABILITY cluster (adk-model providers, adk-anthropic, adk-gemini, adk-mistralrs, adk-realtime, adk-rag, adk-audio, adk-payments, adk-action, adk-bench, adk-rust-macros)

Same D16 Rust-blindness constraint — production-grade merit only; observe, do not conclude
adoption. New patterns numbered **P-67+** (A4 consumed P-47..P-66; this pass continues from P-67
to avoid collision). Primary mapping targets: `.factory/semport/partners/*`, CLAUDE.md credential /
timeout / rustls / no-unwrap conventions, D5 (pydantic→serde/schemars ADR), and the Domain-B
budget-governance gap (P-46).

## HEADLINE — P-16 RESOLUTION (A1 open item closed)

**A1's WEAK-2 / P-16 characterized the two Anthropic (and Gemini) surfaces as "duplicated provider
surfaces … two code paths that invite drift." The deep read REFUTES the duplication framing.** The
relationship is a **layered SDK + adapter stack, not parallel reimplementations**:

- `adk-anthropic` (19,658 LOC src/, 133 files <!-- [comparative-sweep] CORRECTION: "17,263 LOC" → 19,658 (find adk-anthropic/src -name "*.rs" | xargs wc -l); file count 133 (all .rs including tests) is correct. Delta LOC = +2,395. Quality tag unaffected. -->) and `adk-gemini` (13,141 LOC src/ <!-- [comparative-sweep] CORRECTION: "14,141 LOC" → 13,141 (find adk-gemini/src -name "*.rs" | xargs wc -l); delta = -1,000. Quality tag unaffected. -->) are **standalone,
  self-publishing vendor SDKs**. Evidence: `adk-anthropic/Cargo.toml` has **ZERO `adk-*`
  dependencies** (only reqwest/serde/tokio/bytes/base64/url/time/regex/hmac/sha2/hex); it publishes
  to `docs.rs/adk-anthropic` with its own README/examples. It is a full Anthropic API binding —
  wire types (`types/` ~60 files), HTTP client (`client.rs`), SSE decoder (`sse.rs`),
  `accumulating_stream.rs`, batch, files API, managed-agents API, citations, pricing, tool-search,
  observability. Same shape for `adk-gemini` (generateContent + Interactions API + `schema_adapter`).
- `adk-model/src/anthropic/*` and `adk-model/src/gemini/*` are the **ADK `Llm`-trait ADAPTERS** that
  WRAP those SDKs. Evidence: `adk-model/Cargo.toml` gates them behind features that pull the SDK as
  a dependency — `anthropic = ["dep:adk-anthropic"]`, `gemini = ["dep:adk-gemini"]` (gemini is the
  DEFAULT feature). The adapter `client.rs` exposes `fn inner(&self) -> &adk_anthropic::Anthropic`
  ("Access the underlying `adk_anthropic::Anthropic` HTTP client") and consumes SDK types
  throughout (`adk_anthropic::{MessageCreateParams, MessageParam, ContentBlock, Error, Usage,
  ThinkingConfig, MessageRole, ToolUnionParam, …}`). `convert.rs` maps adk-core `LlmRequest`/
  `LlmResponse` ↔ SDK wire types; `convert_anthropic_error(e: adk_anthropic::Error) -> AdkError`
  maps the SDK error taxonomy into `AdkError`. The gemini adapter likewise `use adk_gemini::Gemini`
  + `adk_gemini::schema_adapter::GeminiSchemaAdapter` and matches on `adk_gemini::Part`/`FinishReason`.

**Canonical determination:** the SDK crate is canonical for **wire/protocol** (there is exactly ONE
Anthropic HTTP implementation — in `adk-anthropic`; the adapter does NOT re-open a reqwest client to
Anthropic, it delegates through `adk_anthropic::Anthropic`). The `adk-model` module is canonical for
the **ADK trait binding**. **Drift risk is LOW, not the HIGH A1 assumed**: the adapter imports SDK
types at compile time, so an SDK type change forces an adapter update (it won't build otherwise).
The CHANGELOG confirms lockstep evolution — e.g. "Claude Opus 4.7 Support (`adk-anthropic`,
`adk-model`)" adds the wire variant in the SDK AND the adapter in the SAME release entry; Opus 4.8
the same. Git per-file history is unavailable (the pinned `.reference` is a single squashed commit
`a6c79b6`), so the lockstep evidence is the CHANGELOG + the compile-time type coupling, not blame.

**Residual (legitimate) concerns after resolution:** (a) the SDK+adapter split is **undocumented at
the workspace level** — nothing tells a consumer "use `adk-model`'s `AnthropicClient` for agents,
`adk-anthropic` directly for raw API access" (ergonomics ambiguity, not drift); (b) the adapter
`client.rs` files are large (anthropic 64 KB, gemini 94 KB + `interactions_convert.rs` 85 KB) —
would blow ferrochain's 750-line gate; the bulk is conversion + streaming-accumulation + tests, not
duplicated transport. **Net: P-16 downgraded from WEAK "drift risk" to a documentation/file-size
observation.** The wider provider architecture is intentionally MIXED (see module-inventory A5):
first-party SDK+adapter (anthropic, gemini), external-SDK+adapter (openai→`async-openai`,
bedrock→`aws-sdk-bedrockruntime`, ollama→`ollama-rs`), and direct-reqwest-in-adapter (groq,
deepseek, azure_ai, openrouter, openai_compatible).

## STRONG patterns

### P-67 — Standalone-vendor-SDK + thin-trait-adapter provider layering
Vendor integrations are split into a dependency-light standalone SDK crate (raw wire types, HTTP,
streaming — zero framework deps, independently publishable) and a small `Llm`-trait adapter in
`adk-model` that wraps it. See the P-16 resolution above for the full evidence.
- Evidence: `adk-anthropic` (no `adk-*` dep) + `adk-model::anthropic` (`fn inner() -> &adk_anthropic::Anthropic`, feature `anthropic = ["dep:adk-anthropic"]`); `adk-gemini` + `adk-model::gemini` (`use adk_gemini::Gemini`, default feature `gemini`).
- Quality: **STRONG** — the wire contract lives ONCE and is reusable outside the framework; the
  adapter cannot silently drift from the SDK because it is compile-time-coupled to its types; a
  non-ADK consumer can depend on the SDK alone. This is a cleaner layering than a single monolithic
  provider module. (The file-size of the adapters and the missing "which do I use" doc are the only
  demerits — both structural, not correctness.)
- Ferrochain concern: partner-crate architecture (semport/partners). A ferrochain `ferrochain-anthropic`
  could mirror this (a wire-SDK core + a trait-adapter) to keep the provider surface reusable and to
  satisfy the file-size gate by construction. Directly informs the "ONE provider surface per vendor"
  goal — here it IS one implementation, layered, not two.

### P-68 — Text-tag tool-call parser for backends without native tool-calling
`adk-model::tool_call_parser` detects and parses tool calls emitted as TEXT tags (for models served
without native `tool_calls` support — e.g. HuggingFace TGI, local OSS models) and converts them to
`Part::FunctionCall`. Supports Qwen/Hermes `<tool_call>{json}</tool_call>`, Qwen function-tag,
Llama `<|python_tag|>`, Mistral Nemo `[TOOL_CALLS]`, DeepSeek fenced-json + `<｜tool▁call▁end｜>`,
Gemma 4 `<|tool_call>call:NAME{...}`, and generic action tags. `contains_tool_call_tag` gates the
work; format parsers are tried in order and preserve surrounding `Part::Text`.
- Evidence: `adk-model::tool_call_parser::{contains_tool_call_tag, parse_text_tool_calls,
  parse_qwen_format, parse_llama_format, parse_mistral_nemo_format, parse_deepseek_format,
  parse_gemma4_format}`; 22 unit tests (per-format + text-before + multiple-calls + no-match +
  streaming-buffer emit-immediately).
- Quality: **STRONG** — a genuinely production-grade compatibility layer that makes the agent tool
  loop work across serving backends that differ in tool-call encoding; each format is a tested
  contract (test-as-spec).
- Ferrochain concern: DIRECTLY relevant to `ferrochain-ollama` (our Ollama-analog) and any
  local/OSS-model path — Ollama-served models frequently emit text-tag tool calls. This parser's
  format table + test suite is a reusable behavioral reference. Maps to Tools (semport/core §6).

### P-69 — DoS-hardened SSE decoder with idle-chunk timeout and TTFB observability
`adk-anthropic::sse::process` converts a byte stream into `MessageStreamEvent`s with production
hardening: `MAX_BUFFER_SIZE` 1 MB and `MAX_EVENT_SIZE` 64 KB allocation caps, a 30 s inter-chunk
`CHUNK_TIMEOUT` (idle detection between chunks, distinct from the whole-request timeout), and
observability counters (`STREAM_BYTES/EVENTS/ERRORS/DURATION/TTFB`, incl. time-to-first-byte).
- Evidence: `adk-anthropic::sse` — `SseState { buffer, last_activity, total_bytes_processed, start,
  first_byte }`, the `MAX_BUFFER_SIZE`/`MAX_EVENT_SIZE`/`CHUNK_TIMEOUT` consts.
- Quality: **STRONG** — streaming decoders are a classic unbounded-allocation and hang sink; capping
  buffer/event size and enforcing an idle timeout up front is the correct production default, and
  TTFB metering is exactly the streaming NFR signal a provider layer should emit.
- Ferrochain concern: partner streaming decoders (`ferrochain-anthropic`/`-openai`/`-ollama` SSE) —
  the buffer/event caps + idle-chunk timeout + TTFB metric are a strong reference. Note the CONTRAST
  with the adapter-layer timeout gap (P-77): the SDK stream decoder is hardened even though the
  adapter-layer HTTP clients often are not.

### P-70 — AccumulatingStream: pass-through streaming + build-final-message without double-buffering
`adk-anthropic::accumulating_stream::AccumulatingStream` wraps a `Stream<MessageStreamEvent>` and
forwards each event to the live consumer WHILE simultaneously folding events into a complete
`Message` (per-content-block builders); when the stream drains, the assembled `Message` is delivered
via a `tokio::oneshot`. The caller gets live tokens AND the final message with no second buffer.
- Evidence: `adk-anthropic::accumulating_stream::AccumulatingStream { inner, message_tx: oneshot,
  message, content_blocks: Vec<ContentBlockBuilder> }`.
- Quality: **STRONG** — solves the common "I want to stream to the user but also need the final
  aggregated message (for persistence / turn-completion)" problem without buffering the stream
  twice; the oneshot cleanly signals completion.
- Ferrochain concern: streaming aggregation (semport/core §1 astream + message accumulation). A
  ferrochain streaming provider needs exactly this dual role (yield deltas to the caller; hand the
  runner the final assembled message for the event log). Reference shape.

### P-71 — Shared retry combinator integrated across 9 of 12 providers; 3 documented exceptions
The `adk-model::retry` combinator (P-03) is not just defined once — it is WIRED into the dominant
provider path: each wired provider holds a `retry_config: RetryConfig` (with `with_retry_config`/
`set_retry_config`/`retry_config` accessors) and calls
`execute_with_retry(&cfg, is_retryable_model_error, || fut)`.
- Evidence: `execute_with_retry` called in `adk-model::{gemini/client, anthropic/client,
  openai/client, openai/responses_client, groq/client, deepseek/client,
  azure_ai/client, openrouter/adapter, openai_compatible}` (9 providers); `RetryConfig` stored (not combinator called) in `openai/ws_transport` (implements its own manual retry loop, lines 160-201) and `bedrock/client` (stores RetryConfig but delegates retry to `aws-sdk-bedrockruntime`); `ollama` delegates entirely to `ollama-rs` which owns its retry. Gemini carries its own retry tests (retryable/non-retryable/disabled).
- Quality: **STRONG** — [comparative-cert-1 TAG-REVIEW RULING: STRONG STANDS with corrected scope. 9 of 12 providers share one combinator. The 3 exceptions each have architectural grounding: bedrock's AWS SDK owns retry internally (external SDK ownership — arguably better than re-implementing it); ws_transport uses a manual loop for WebSocket semantics (different concurrency model); ollama delegates to ollama-rs (external library ownership). The core merit claim — "a centralized retry combinator is the dominant pattern enabling uniform policy tuning" — is substantiated by 9/12. The original "every provider" framing was overstated but the pattern's production-grade value is undiminished. NEUTRAL would require the combinator to be fragile or the exceptions to be ad-hoc; neither is the case.] A single classification+backoff policy shared across 9 providers means retry behavior is centrally-tunable for the majority path rather than re-invented per provider. The 3 exceptions are architecturally justified (see above).
- Ferrochain concern: reliability/NFR (retry) + rate limiters (semport/core §9). The
  "dominant providers share ONE retry combinator" discipline is the reference; ferrochain's partner
  crates should likewise route through one retry policy, not per-crate ad-hoc loops.

### P-72 — `#[tool]` / `#[entrypoint]` / `#[task]` proc-macros for zero-boilerplate wiring
`adk-rust-macros` (963 LOC, single `lib.rs`) exposes three attribute macros. `#[tool]` turns an
`async fn(args: T) -> Result<Value, AdkError>` into a zero-sized PascalCase struct implementing
`adk_tool::Tool`: the doc-comment becomes the tool description, the JSON schema is derived from `T`
via `schemars::schema_for!`, the tool name is the snake_case fn name, and optional attrs
`read_only` / `concurrency_safe` / `long_running` set the corresponding capability-predicate methods
(the ergonomic override for P-12's defaulted `false`). `#[entrypoint]` and `#[task]` back the
functional-graph API — `#[entrypoint]` generates a wrapper with
`fn new(checkpointer: Arc<dyn adk_graph::checkpoint::Checkpointer>)` (auto-checkpointing);
`#[task]` marks checkpointed task nodes with typed reducers.
- Evidence: `adk-rust-macros::{tool (l.76), entrypoint (l.398), task (l.646)}`; `[lib] proc-macro = true`;
  dev-deps include `schemars = "1.0"`.
- Quality: **STRONG (ergonomics)** — collapses the Tool-impl boilerplate to one attribute while
  keeping the schema derivation honest (schemars from the real arg type), and the capability attrs
  give a typed, discoverable way to override the P-12 defaults. The functional-graph macros are a
  clean LangGraph-`@task`/`@entrypoint` analog with checkpointing baked in.
- Ferrochain concern: Tools ergonomics (semport/core §6) + a possible ferrochain functional-graph
  surface. ALSO a D5 data point (see P-75): the macro path uses schemars for tool-arg schema even
  though the provider layer hand-rolls JSON Schema — so schemars IS in play for the tool surface.

### P-73 — Composable payment-policy guardrail: allow/escalate/deny + integer Money + append-only journal
`adk-payments` models agentic commerce with a production-grade governance core. `PaymentPolicyGuardrail`
is a composable trait (`evaluate(record, protocol) -> PaymentPolicyDecision`); `PaymentPolicyDecision`
is a **three-state** verdict — `allow()` / `escalate()` (soft, human-review) / `deny()` (hard-stop) —
each carrying `PaymentPolicyFinding { name, message, Severity }` (reusing `adk_guardrail::Severity`).
Concrete policies: `AmountThresholdGuardrail { review_threshold_minor, hard_limit_minor }`,
`currency_policy`, `merchant_policy`, `intervention_policy`, `protocol_version`, `redaction`. `Money`
is `{ currency: String, amount_minor: i64, scale: u32 }` — integer minor-units, explicitly to avoid
float drift. A `journal/` subsystem (evidence_store, memory_index, session_state, store) is an
append-only audit trail; `auth/` adds mandate `binding` + `scopes` + `audit`; `kernel/` is the
command/correlator/service processing core. Protocol-neutral: ACP + AP2 baselines, feature-gated.
- Evidence: `adk-payments::guardrail::{policy::{PaymentPolicyGuardrail, PaymentPolicyDecision,
  PaymentPolicyFinding}, amount_policy::AmountThresholdGuardrail}`; `domain::money::Money`;
  `journal/`, `auth/`, `kernel/`, `protocol/{acp,ap2}`.
- Quality: **STRONG (as a governance-engine reference)** — the allow/escalate/deny + severity +
  findings decision shape, the composable-policy trait, the integer-money discipline, and the
  append-only evidence journal are all production-grade governance primitives. (Payments itself is a
  scope anomaly for ferrochain — no LangChain/LangGraph analog — so this is a *pattern* reference,
  not a scope endorsement.)
- Ferrochain concern: the Domain-B **budget-governance gap (P-46)**. adk-rust has NO token/cost
  budget gate, but its PAYMENT guardrail is exactly the *shape* a token/cost ceiling wants:
  a composable policy trait returning allow/escalate/deny with severity, backed by an append-only
  journal. A ferrochain budget-governance primitive could adopt this three-state policy architecture
  (different domain: LLM token-$ vs commerce-$).

## NEUTRAL patterns

### P-74 — Feature-gated backend polymorphism across capability crates
Capability crates expose one trait + many feature-gated backend impls: `adk-rag` `VectorStore` +
`{inmemory, lancedb(feat), pgvector(feat, sqlx), qdrant(feat), surrealdb(feat)}` and embedding
providers `{gemini(feat), openai(feat)}`; `adk-audio` TTS/STT/music/fx/vad/onnx/mlx backends behind
features; `adk-model` `all-providers` composing 9 provider features. A lean build pulls only what it
enables.
- Evidence: `adk-rag/Cargo.toml` features (`qdrant`/`lancedb`/`pgvector`/`surrealdb`/`full`);
  `adk-audio/Cargo.toml` (`tts`/`stt`/`onnx`/`mlx`/`kokoro`/`vad`/…); `adk-model` provider features.
- Quality: **NEUTRAL** — good binary-size/opt-in economics and a clean trait+impl seam, but (echoing
  P-14) a large feature matrix multiplies the build/test-coverage combinations and makes "what does
  build X actually contain" a compile-time variable. Also the vehicle for the native-tls / hf-hub
  ingress (P-79).
- Ferrochain concern: partner/backend composition + NFR (feature matrix, file-size). Ferrochain
  should decide which backends are core vs feature-gated and bound the test matrix.

### P-75 — schemars in the tool macro vs hand-rolled JSON Schema in providers (internal inconsistency)
The `#[tool]` macro (P-72) derives tool-arg schemas via `schemars::schema_for!`, but the provider
layer builds provider request/response JSON Schema BY HAND (`SchemaAdapter`, `schema_utils`,
per-provider `schema_adapter.rs`) with NO schemars dependency (A1 dependency-disposition: "No
schemars" at the workspace level — it is an OPTIONAL dep, on only for `adk-model`'s `ollama` feature
and used by the macro crate). So the codebase uses two schema strategies for two surfaces.
- Evidence: `adk-rust-macros` dev-dep + macro body `schema_for!`; `adk-model` `schemars` is
  `optional = true`, `ollama = [... "dep:schemars"]`; providers' `schema_adapter.rs` hand-roll.
- Quality: **NEUTRAL/observational** — defensible (tool-arg schema is developer-authored Rust types
  → schemars is ergonomic; provider wire schema is externally-fixed → hand-rolling gives control),
  but it IS an internal inconsistency worth naming.
- Ferrochain concern: D5 (pydantic→serde/schemars ADR). Concrete data point: adk uses schemars where
  the schema derives from owned Rust types (tools) and hand-rolls where it mirrors an external wire
  contract (providers). Informs *where* ferrochain should mandate schemars vs hand-authored schema.

## WEAK / concerning observations

### P-76 — Bare-`String`, `#[derive(Debug)]` API keys workspace-wide (credential leak surface)
NO provider config or SDK client wraps its API key in a redacted newtype. Every provider config is
`#[derive(Debug, …)] struct { pub api_key: String, … }` and the standalone SDK client structs do the
same with a private-but-Debug-derived field.
- Evidence: `adk-model::anthropic::config` (`#[derive(Debug, Clone, Serialize, Deserialize)]`,
  `pub api_key: String`); `adk-model::openai::config` (multiple `pub api_key: String` on
  Debug-derived structs, also `Serialize`); `adk-model::gemini::client` (`api_key: impl Into<String>`);
  `adk-anthropic::client` (`#[derive(Debug, Clone)] pub struct Anthropic { api_key: String, … }`);
  `adk-auth::secrets` returns bare `String` (A3 P-44). NO `redact`/`<redacted>`/manual `Debug` impl
  anywhere in `adk-model/src`.
- Quality: **WEAK** — `#[derive(Debug)]` prints the key (private fields included) in any
  `{:?}`/span/error capture; several configs also `Serialize` the key to JSON. This is precisely the
  leak ferrochain's newtype+redacted-Debug rule prevents, and it is WORKSPACE-WIDE (configs + SDKs),
  not a single site. Extends and generalizes A3 P-44 from `adk-auth` to the entire provider stack.
- Ferrochain concern: DIRECT divergence from CLAUDE.md "Newtype + redacted Debug for credentials."
  Every ferrochain provider key type (`OpenAiApiKey`, `AnthropicApiKey`, …) must be a redacted
  newtype; adk-rust is a workspace-wide counter-example here, not a template.

### P-77 — Inconsistent outbound-timeout discipline across the provider stack
Timeout hygiene is applied unevenly. The `adk-anthropic` MAIN client is exemplary
(`ReqwestClient::builder().timeout(DEFAULT_TIMEOUT).pool_max_idle_per_host(10)
.pool_idle_timeout(90s).tcp_keepalive(60s)`, plus `with_timeout`). But: `adk-anthropic`'s
`managed_agents/client.rs` and `files/client.rs` use bare `reqwest::Client::new()` (no timeout);
`adk-gemini`'s builder uses `ClientBuilder::default()` with no default timeout; and the `adk-model`
DIRECT-reqwest providers — `openai/client`, `openai/responses_client`, `openai/conversations`,
`openai_compatible` — all use `reqwest::Client::new()` with no `.timeout()`. `openrouter/client`
builds via `ClientBuilder` but sets only default headers, no timeout. (ollama defers entirely to
`ollama-rs`; async-openai/bedrock manage their own clients.)
- Evidence: `adk-anthropic::client` `.timeout(DEFAULT_TIMEOUT)` (l.148,214) vs
  `adk-anthropic::{managed_agents,files}::client` `reqwest::Client::new()`;
  `adk-model::{openai/client:112, openai/responses_client:99, openai/conversations:45,
  openai_compatible:236}` all `reqwest::Client::new()`.
- Quality: **WEAK** — a hung provider/endpoint blocks the calling task indefinitely on the
  timeout-less clients (bounded only by OS TCP). The one crate that does it right (anthropic main
  client) proves the team knows the pattern; it is just not applied uniformly. Extends A3 P-42
  (server cluster) into the PROVIDER cluster.
- Ferrochain concern: CLAUDE.md mandatory 30 s outbound timeout. Every ferrochain provider client
  must set `.timeout()`; adk's anthropic main client (timeout + pooling + keepalive) is the positive
  reference, the rest are counter-examples.

### P-78 — `MistralRsError::Other(#[from] anyhow::Error)` — the sole genuine anyhow public-signature leak
The ONLY place `anyhow` reaches a library public signature in the entire provider/capability cluster
is `adk-mistralrs`: its public error enum has `Other(#[from] anyhow::Error)`. Everything else is a
doc-comment example (`//! async fn main() -> anyhow::Result<()>`), and `adk-model` DECLARES `anyhow`
in Cargo.toml but never references it in `src` (a dead dependency).
- Evidence: `adk-mistralrs::error::MistralRsError::Other(#[from] anyhow::Error)` (error.rs:277);
  `adk-mistralrs::{lib.rs:36, multimodel.rs:13}` are `//!` doctest examples only; `adk-model` `src`
  has zero `anyhow::` references despite the Cargo.toml entry.
- Quality: **WEAK (localized)** — the `Other(anyhow::Error)` escape hatch erases component/category
  structure at the boundary (the exact anti-pattern A1 P-18 feared), but it is a single catch-all
  variant on an otherwise well-structured `thiserror` enum (with `ModelLoad{model_id,reason,
  suggestion}`, `ModelNotFound{path,suggestion}` — good actionable variants), in ONE local-inference
  crate. See dependency-disposition A5 for the full workspace verdict.
- Ferrochain concern: CLAUDE.md structured-error discipline forbids an `anyhow` escape variant on a
  public error enum. A ferrochain local-inference crate must give every failure mode a structured
  variant, no `Other(anyhow)` catch-all.

### P-79 — Multiple native-tls ingress chains via optional model/voice features (rustls-rule conflict)
A1 flagged ONE native-tls path (livekit). The cluster read finds at least THREE, all
feature-gated/optional: (1) `adk-realtime` `livekit` feature → `livekit 0.7.x` → `async-native-tls`/
webrtc stack → `native-tls`; (2) `adk-mistralrs` → `mistralrs 0.8` (candle) → `hf-hub 0.4.3` (HF
model download) → `native-tls`; (3) `adk-audio` `onnx`/`mlx`/`kokoro`/`qwen3-tts` features →
`hf-hub 0.5` → `native-tls`. Plus a `hyper-tls` occurrence in the lockfile. The DEFAULT builds of
adk-realtime (`default = []`; OpenAI-Realtime/Gemini-Live run over `tokio-tungstenite` with rustls)
and adk-mistralrs/adk-audio do NOT necessarily pull it — it rides the optional heavyweight features.
- Evidence: Cargo.lock `native-tls` pulled by `livekit`, `hf-hub 0.4.3` (deps list includes
  `native-tls`), and `hf-hub 0.5`; `adk-realtime` `livekit = ["dep:livekit", …]`;
  `adk-mistralrs` `mistralrs = "0.8"`; `adk-audio` `onnx/mlx/qwen3-tts = [… "dep:hf-hub"]`.
- Quality: **WEAK** — the rustls-only rule (macOS Keychain cost + MITM interception path) conflicts
  with the local-model-download (`hf-hub`) and LiveKit transports. It is contained to optional
  features, but any ferrochain port of local inference (mistralrs-style) or LiveKit voice inherits
  the conflict. NEW beyond A1 (which saw only livekit).
- Ferrochain concern: CLAUDE.md rustls-only. If ferrochain adopts local-model inference, the
  `hf-hub`→native-tls chain must be resolved (hf-hub rustls feature, or a rustls model downloader).
  This is a keyless-CI-adjacent concern too: local inference drags a heavy, native-tls-tainted
  dependency tree that a lightweight HTTP-daemon Ollama-analog avoids.

## Pass A5 cross-cutting note (informative, not a conclusion)
The provider/capability cluster's strengths are in the **vendor-integration substrate**: a clean
standalone-SDK + trait-adapter layering (P-67, resolving the P-16 "duplication" fear), a robust
text-tag tool-call parser for tool-callingless backends (P-68, directly Ollama-relevant), a
DoS-hardened SSE decoder + pass-through-accumulate streaming (P-69/P-70), one retry combinator wired
across all providers (P-71), ergonomic tool/graph proc-macros (P-72), and a genuinely production-grade
composable policy+journal governance engine in payments (P-73 — a shape reference for the Domain-B
budget gap). Its weaknesses are **credential and dependency hygiene**: workspace-wide bare-String
Debug-derived API keys (P-76), uneven outbound-timeout discipline (P-77, the anthropic main client
being the lone exemplar), one localized `anyhow` leak in the local-inference crate (P-78), and
multiple optional native-tls ingress chains via model-download/voice features (P-79). Whether any
of these influences ferrochain is deferred to the post-validation comparative assessment per D16.

## State Checkpoint
```yaml
pass: A5
scope: patterns-observed (provider/capability cluster)
patterns_added: 13 (P-67..P-79 — 7 STRONG, 2 NEUTRAL, 4 WEAK)  # P-67..P-73 STRONG, P-74/P-75 NEUTRAL, P-76..P-79 WEAK
patterns_total: 79
a1_open_items_resolved:
  - P-16 (adk-model vs standalone provider crates) — RESOLVED: SDK+adapter layering, NOT duplication; low drift risk; SDK canonical for wire, adapter canonical for trait
  - P-18/anyhow (final workspace verdict) — see dependency-disposition A5
status: complete
timestamp: 2026-07-13
```

---

# Pass A6 deepening — convergence exhaustion (P-80..P-87)

> Scope: the residual open/deferred items named in ANALYSIS-STATE + A4/A5 returns, worked
> highest-spec-impact first. Observe-only per D16; Rust-blindness applies. Append-only; pattern
> numbers P-80+. Behavioral anchors cite function/type names, not line numbers (TD-VSDD-091).

## P-80 — Realtime provider-agnostic context-mutation FSM ("Phantom Reconnect") — STRONG

- **Where:** `adk-realtime` — `runner.rs` (`RunnerState`, `RealtimeRunner::update_session_with_bridge`,
  `execute_resumption`, `check_resumption_queue`, `merge_config`); `session.rs`
  (`ContextMutationOutcome`, `RealtimeSession::mutate_context`); `openai/protocol.rs` +
  `gemini/session.rs` (per-provider `mutate_context`).
- **Observation:** A 4-state runner FSM — `Idle` / `Generating` / `ExecutingTool` /
  `PendingResumption{config, bridge_message, attempts}` — governs whether a mid-session config
  swap (instruction/tools/voice/temperature/extra) can be applied. Providers answer
  `mutate_context()` with one of two outcomes: `Applied` (OpenAI natively hot-swaps over the live
  WebSocket) or `RequiresResumption(config)` (Gemini requires transport teardown + rebuild — the
  "Phantom Reconnect"). The runner NEVER tears the socket down while `Generating` or
  `ExecutingTool`; it queues the resumption and executes it on the next `ResponseDone`
  (`check_resumption_queue`). Canonical config is accumulated in `self.config` via `merge_config`
  so a later phantom reconnect inherits all prior hot-swaps plus immutable transport params.
- **Reliability specifics:** (1) single-slot queue with explicit **last-write-wins** semantics
  (a newer pending resumption overwrites an older one — "desired end state, not a command queue");
  (2) **3-attempt retry budget** on reconnect failure, after which the queued mutation is
  DROPPED (state forced to `Idle`) to prevent hot-looping; (3) reconnect errors are reported to
  `event_handler.on_error` but deliberately NOT returned as `Err` from `run()`, so a transient
  network failure never kills the event loop; (4) Gemini `sessionResumptionUpdate` tokens are
  captured from `SessionUpdated` events into `config.extra["resumeToken"]` so a rebuild resumes
  server-side state; (5) all lock guards are dropped before every `.await` network op (documented
  deadlock-avoidance discipline).
- **Quality:** **STRONG** — a genuinely production-grade abstraction over two structurally
  different provider models (native mutability vs static-config-with-resumption), with explicit
  teardown-safety gating, bounded retries, and fail-open event-loop survival. Domain C (voice)
  directly relevant: this is the shape a ferrochain realtime layer would need if it targets both
  an OpenAI-style and a Gemini-style live backend.
- **NEW vs A5** (A5 was surface-only on adk-realtime).

## P-81 — Barge-in / turn-taking delegated to server-side VAD; client-driven interrupt is manual-only — NEUTRAL

- **Where:** `adk-realtime` — `agent.rs` `RealtimeAgent::run` event loop; `runner.rs`
  `RealtimeRunner::handle_event`; `config.rs` (`VadConfig`, `InterruptionDetection`); provider
  `interrupt()` (`openai/protocol.rs` → `response.cancel`; `gemini/session.rs` → `clear_audio` +
  no-op "Gemini handles interruption via VAD").
- **Observation:** Turn-taking is configured, not orchestrated client-side. `VadConfig` defaults to
  `ServerVad` with `interrupt_response: Some(true)` and `silence_duration_ms: 500`; barge-in is
  therefore enacted by the *provider* cancelling its own in-flight response when server VAD detects
  user speech. The `RealtimeAgent::run` loop handles `ServerEvent::SpeechStarted` ONLY by invoking
  the optional `on_speech_started` callback — it does **not** call `session.interrupt()`. Likewise
  `RealtimeRunner::handle_event` forwards `SpeechStarted` to the handler and never auto-interrupts.
  `session.interrupt()` exists and is exposed on the runner, but is a **manual** control the
  embedder must call. `InterruptionDetection` defaults to `Manual`. Gemini explicitly DROPS a
  manual `ResponseCancel` (logs a warning) because it manages interruption internally.
- **Quality:** **NEUTRAL** — a reasonable delegation (server VAD is the low-latency path), but the
  framework provides no built-in client-side barge-in state machine; an embedder wanting
  deterministic local barge-in (e.g., push-to-talk cancel) must wire `interrupt()` themselves, and
  the two providers disagree on whether manual cancel is even honored. Domain C observation: a
  ferrochain voice layer must decide whether barge-in is a framework guarantee or an
  embedder responsibility — adk-rust chose the latter.
- **NEW.**

## P-82 — Windows AppContainer enforcer is a hard-fail stub; no working Windows sandbox path — WEAK

- **Where:** `adk-sandbox` — `sandbox/windows.rs` (`WindowsEnforcer::configure_command`),
  `sandbox/mod.rs` (`get_enforcer`), `process.rs` (`run_command`).
- **Observation:** On Windows, `WindowsEnforcer::wrap_command` returns the program unchanged and
  `configure_command` returns `Err(SandboxError::EnforcerFailed { … "Windows AppContainer
  configuration not yet implemented … deferred to a Windows-specific implementation pass" })` — a
  documented TODO listing the intended CreateAppContainerProfile / SetNamedSecurityInfo /
  UpdateProcThreadAttribute steps that are not written. `process.rs::run_command` calls
  `configure_command` and propagates its error, so with an enforcer configured a sandboxed process
  on Windows **cannot spawn** (fail-closed); with no enforcer configured, the process runs
  **unsandboxed** (the `else` branch spawns the raw command — this confirms A4 P-61 default-no-isolation
  workspace-wide). Net: there is **no functional Windows sandbox** — the only outcomes are
  "unsandboxed" or "hard error." Contrast Linux (`linux.rs`: real `bwrap` with
  `--die-with-parent`/`--unshare-pid`/`--unshare-net`/`--ro-bind`/`--bind`) and macOS
  (seatbelt, real) enforcers, which are implemented.
- **Quality:** **WEAK** — a production-grade sandbox story that silently excludes an entire OS.
  Domain A/C: a ferrochain analyst/factory sandbox targeting Windows agents would inherit a
  no-op-or-error posture. Note it is at least fail-closed (no false sense of enforcement) rather
  than fail-open-silent.
- **NEW** (A4 covered macOS/default posture; Windows was unverified at depth).

## P-83 — adk-code Docker backend: per-request SandboxPolicy is ignored, and no resource/privilege hardening — WEAK

- **Where:** `adk-code` — `container.rs` (`DockerExecutor` behind `docker` feature;
  `ContainerCommandExecutor` CLI fallback).
- **Observation (two distinct sub-findings):**
  1. **Capability claim vs behavior mismatch.** `DockerExecutor::capabilities()` advertises
     `enforce_network_policy / enforce_filesystem_policy / enforce_environment_policy = true`, but
     `DockerExecutor::execute()` reads only `request.sandbox.timeout`, `.max_stdout_bytes`, and
     `.max_stderr_bytes` from the per-request `SandboxPolicy`. Network/filesystem/env isolation come
     from the `DockerConfig` fixed at construction (`network_disabled`, `bind_mounts`,
     `environment`), NOT from the request. So the advertised "enforce_*_policy" is true only w.r.t.
     the static config; a caller varying `request.sandbox.filesystem`/`.network`/`.environment`
     per call has NO effect on the persistent-container backend. The CLI `ContainerCommandExecutor`,
     by contrast, DOES translate the per-request `SandboxPolicy` (`build_run_args` maps
     `NetworkPolicy`/`FilesystemPolicy`/`EnvironmentPolicy` to `--network=none`/`-v …:ro|rw`/`--env`).
  2. **No hardening flags.** Neither backend sets `--user` (code runs as root inside the
     container), `--read-only` rootfs, `--memory` / `--cpus` / `--pids-limit`, or
     `--cap-drop`/seccomp/apparmor. Isolation rests on default Docker namespacing + `network=none`
     (default) + bind-mount scoping + a wall-clock `tokio::time::timeout`. Resource-exhaustion DoS
     (fork bomb, memory balloon, disk fill on a rw mount) is bounded only by the timeout.
     `FilesystemPolicy::Paths` in the CLI backend binds host paths at the *same* container path,
     which can surface host locations into the guest.
- **Quality:** **WEAK** — the network-off-by-default + bind-mount + timeout baseline is sane, but
  the capability-vs-behavior gap (sub-finding 1) is a correctness/observability hazard (a policy the
  caller believes is enforced is silently ignored on the persistent backend), and the absence of
  resource caps makes it unsuitable as a strong isolation boundary for untrusted Domain-A code.
- **NEW** (A4 examined adk-code Rust exec / proptest rigor, not the Docker execute path).

## P-84 — InMemoryVectorStore ignores declared dimensions; RAG backend contracts diverge; thin-test confirmed — WEAK

- **Where:** `adk-rag` — `vectorstore.rs` (`VectorStore` trait), `inmemory.rs`
  (`InMemoryVectorStore`, `cosine_similarity`), backend impls `surrealdb.rs` / `pgvector.rs` /
  `qdrant.rs` / `lancedb.rs`, `pipeline.rs`.
- **Observation:** The `VectorStore` trait's `create_collection(name, dimensions)` is honored
  differently per backend. Real backends bind the dimension into their engine schema — surrealdb
  `HNSW DIMENSION {n} DIST COSINE`, pgvector `vector({n})`, qdrant `VectorParamsBuilder::new(n, Cosine)`
  — so a wrong-dimension upsert fails DB-side. But `InMemoryVectorStore::create_collection` takes
  `_dimensions` and **discards it**; neither `upsert` nor `search` validates embedding length, and
  `cosine_similarity` zips `a.iter().zip(b.iter())` (truncating to the shorter vector) — so a
  mismatched-dimension query silently returns a garbage-but-plausible score instead of erroring.
  Behavioral contract for dimension enforcement therefore **diverges across backends** (DB-enforced
  vs silently-ignored). Search contract is otherwise uniform: collection-missing → `VectorStoreError`,
  results sorted descending by score with `partial_cmp … Equal` NaN fallback, truncated to `top_k`.
- **Thin-test claim (VERIFIED at depth):** dedicated tests exist only for `chunking.rs` (5),
  `inmemory` (unit + `inmemory_tests.rs`), and `surrealdb_tests.rs` (6, live/integration-gated). The
  `qdrant`, `pgvector`, and `lancedb` backends have **zero** unit or integration tests — 4 of 6
  store backends ship untested. Confirms the A1 WEAK "thin-test" flag.
- **Quality:** **WEAK** — the trait is clean and the pipeline wires `embedding_provider.dimensions()`
  into `create_collection`, but the in-memory (default/dev) store's silent dimension-agnosticism is a
  correctness trap that only manifests in production against a real backend, and 4/6 backends are
  unverified.
- **NEW detail** (A1/A2 flagged thin-test generically; the dimension-contract divergence is new).

## P-85 — RemoteA2aAgent surfaces ALL transport/RPC failures as error *events*, never stream `Err` — NEUTRAL

- **Where:** `adk-server` — `a2a/remote_agent.rs` (`RemoteA2aAgent::run`,
  `create_error_event`; and the `a2a-v1` `v1_remote::RemoteA2aV1Agent::run`, `create_v1_error_event`).
- **Observation:** Both remote-agent generations wrap every failure — card resolution, HTTP
  transport, RPC error, response-parse error, streaming chunk error — as `yield Ok(create_error_event(…))`
  where the event carries `llm_response.error_message = Some(...)` and `turn_complete = true`. The
  `run()` `EventStream` therefore effectively never yields `Err`; a downstream consumer sees a
  *completed turn that happens to carry an error string*, not a failed stream. Streaming success
  path maps `TaskArtifactUpdate`→partial content events and final `TaskStatusUpdate`→turn-complete;
  a completed task with no message and no artifacts produces **zero** events (tested).
- **Quality:** **NEUTRAL** — consistent and stream-survivable (one flaky sub-agent won't
  `Err`-abort a parent orchestration), but it collapses the error channel into the content channel:
  callers cannot pattern-match on `Result::Err` and must inspect `error_message`, and a partial
  remote failure looks identical to a normal terminal turn. Domain A/B multi-agent relevance: error
  propagation semantics for remote sub-agents are a deliberate design choice a ferrochain port must
  make explicitly.
- **UPGRADES A3** (which read the a2a client at signature-depth only).

## P-86 — Dual A2A client generations (legacy `A2aClient` + feature-gated `A2aV1Client`) — WEAK

- **Where:** `adk-server` — `a2a/client.rs` (legacy `A2aClient`; `#[cfg(feature = "a2a-v1")]`
  `v1_client::A2aV1Client`), `a2a/remote_agent.rs` (parallel `RemoteA2aAgent` / `v1_remote`).
- **Observation:** Two full client stacks coexist. Legacy `A2aClient`: `/.well-known/agent.json`,
  JSON-RPC `message/send` + SSE `message/stream`, no retry, no version header, hand-rolled SSE
  buffer parser. v1 `A2aV1Client`: `/.well-known/agent-card.json`, sends `A2A-Version: 1.0` on every
  request, all 11 v1 operations over JSON-RPC AND an optional REST binding, structured
  `V1ClientError` (thiserror) with version-negotiation parsing (`-32009` → supported-version
  extraction), agent-card caching with ETag/If-None-Match/Last-Modified/304, and exponential-backoff
  retry (`RetryConfig` default 3 attempts / 1s base, retrying 429 + 5xx + timeouts). Interface
  selection prefers `JSONRPC` then falls back to `HTTP+JSON`. The SSE parse loop is duplicated across
  legacy client, legacy remote-agent, and v1 remote-agent.
- **Test asymmetry:** v1 has HIGH-confidence unit tests for the *pure* functions (error parsing,
  version-error parsing, interface selection, header construction, card storage) but the retry /
  caching / transport paths themselves are untested (would need a mock HTTP server; the live path is
  `a2a_live_integration_test.rs`).
- **Quality:** **WEAK** — dual-maintenance + duplicated SSE parsing = drift surface <!-- [comparative-cert-3] CORRECTION: "triplicated" → "duplicated": source confirms only TWO SSE parse implementations exist — (1) legacy A2aClient::send_streaming_message inline loop + parse_sse_data (client.rs:186); (2) v1_remote::run inline loop + parse_sse_data_line (remote_agent.rs:699). The legacy RemoteA2aAgent::run delegates entirely to A2aClient::send_streaming_message, receiving a typed event stream — it has NO separate SSE parse loop and is NOT a third copy. -->; the v1 client
  is clearly the production-grade one (retry, version negotiation, caching) while legacy lags. A
  ferrochain port would consolidate on one client with the v1 feature set.
- **UPGRADES A3.**

## P-87 — Skill ContextCoordinator: phantom-tool prevention is real, but strict-mode errors are swallowed — NEUTRAL

- **Where:** `adk-skill` — `coordinator.rs` (`ContextCoordinator::build_context`,
  `try_resolve`, `resolve`; `ValidationMode` from `adk_core`).
- **Observation:** The coordinator's stated purpose — never hand the LLM an instruction to use a
  tool that isn't bound ("Phantom Tool") — is enforced by resolving `allowed_tools` against the
  `ToolRegistry` and building `system_instruction` from only the *resolved* `active_tools`
  (`engineer_instruction(max_chars, &active_tools)`), so neither mode leaks an unbound tool into the
  prompt. Negative-path behavior by mode: **Strict** → `try_resolve` returns
  `SkillError::Validation` listing missing tools, but `build_context` maps that to
  `Err(_) => continue` and tries the next-ranked candidate, ultimately returning `None` — the
  validation error is **swallowed**, so a caller cannot distinguish "no skill matched the query"
  from "the best skill matched but its tools are unregistered." **Permissive** → missing tools are
  **silently omitted** from `active_tools` (a code comment concedes consumers must monitor
  `provenance.skill.allowed_tools` vs `active_tools` to detect the gap). Both modes are covered by
  HIGH-confidence unit tests (`strict_mode_rejects_missing_tools`, `permissive_mode_binds_available_tools`,
  `no_tools_skill_returns_empty_active_tools`, `resolve_cascades_through_strategies`).
- **Quality:** **NEUTRAL** — the phantom-tool guarantee is genuine and well-tested (a STRONG core
  idea), but the strict-mode error-swallowing costs diagnosability, and permissive-mode's silent
  degradation shifts a safety obligation onto the embedder. Domain B/skill relevance: a ferrochain
  skill layer should preserve the atomic instruction+tools unit while surfacing *why* a skill was
  rejected.
- **CLOSES the item as verified** (strict + permissive both source- and test-confirmed).

## Ignored-vs-runnable integration-test census (attribute-only, per guardrail #12)

Workspace-wide counts over `adk-*/**/*.rs` (attribute lines, not resolved test bodies):

| Metric | Count |
|--------|-------|
| `#[test]` + `#[tokio::test]` (+ rstest/test_case) attributes | 4,803 |
| `proptest!` macro invocations | 150 |
| `#[ignore]` attributes | 126 |
| Test files referencing live-API env vars (GOOGLE/GEMINI/OPENAI/ANTHROPIC/OPENROUTER keys) | 19 |

- **Runnable-by-default ratio:** ~126 / 4,803 ≈ **2.6% of test attributes carry `#[ignore]`** — i.e.
  ~97% of the suite runs without opt-in. This reconciles with (does not contradict) prior per-cluster
  figures (A4 safety cluster ~617; A5 provider cluster ~1,849) — those are cluster subsets of the
  workspace total.
- **`#[ignore]` concentration:** adk-anthropic 38, adk-mistralrs 18, adk-model 16, adk-realtime 14,
  adk-sandbox 11, adk-tool 8, adk-code 6, adk-agent 6, adk-server 5, adk-enterprise 4, adk-bench 3,
  adk-session 1. The ignore reasons cluster into: **live-API credentials** (GOOGLE/GEMINI/OPENAI/
  OpenRouter keys, Vertex ADC), **model downloads** (HuggingFace auth, ~3GB weights — adk-mistralrs),
  and **external tooling** (npx/Node for MCP lifecycle — adk-tool; live Vertex session service).
  Most ignored tests carry an explicit reason string or comment citing the blocking dependency —
  consistent with (though not identical to) ferrochain SID-1's citation discipline.
- **Interpretation:** the ignored set is dominated by genuinely-external dependencies (keys, weights,
  daemons), not by disabled-because-broken tests. The high-rigor in-process suites (proptest across
  sandbox/code/mistralrs/audio; SDK wire round-trips in anthropic) run in CI without opt-in.

## Pass A6 cross-cutting note (informative, not a conclusion)

The residual-item sweep surfaces one architecturally strong pattern (P-80, the realtime
context-mutation FSM — arguably the most sophisticated single mechanism in the corpus and a direct
Domain-C reference) and a cluster of **enforcement-vs-advertisement gaps** on the safety perimeter:
Windows sandbox is non-functional (P-82), the adk-code Docker backend ignores the per-request policy
it advertises and ships no resource caps (P-83), barge-in is an embedder responsibility rather than a
framework guarantee (P-81), and the default in-memory vector store silently ignores dimensions
(P-84). None of these is a conclusion about ferrochain; per D16 the adoption question is deferred to
post-validation comparative assessment.

## State Checkpoint
```yaml
pass: A6
scope: patterns-observed (convergence deepening of residual open items)
patterns_added: 8 (P-80..P-87 — 1 STRONG, 3 NEUTRAL, 4 WEAK)  # P-80 STRONG; P-81/P-85/P-87 NEUTRAL; P-82/P-83/P-84/P-86 WEAK
patterns_total: 87
items_worked: [realtime-bidi-FSM, sandbox-windows+docker, ignore-census, rag-vectorstore, skill-coordinator, a2a-client, residual-open]
status: complete
timestamp: 2026-07-13
```

## Pass A7 deepening (P-88..P-97)

Function-level read of the four A6-named residual threads (gemini/session.rs internals; avatar
providers + keep-alive; livekit bridge; a2a-v1 retry/caching dynamic behavior) plus closure of the
one remaining A6-named unread path (openai/webrtc.rs). Rust-blindness held: observations only; no
adoption conclusions. Patterns numbered P-88+.

### Thread 1 — Gemini Live session internals (Phantom Reconnect teardown/rebuild, resumption)

**P-88 — Gemini teardown/rebuild is deterministic and resumption-token-carried, but drops
in-flight buffered audio.** *(NEUTRAL)*
- **Where:** `adk-realtime` — `gemini/session.rs` (`GeminiRealtimeSession::connect`, `close`,
  `send_setup`, `translate_gemini_event`, `mutate_context`) + `runner.rs`
  (`execute_resumption`, `handle_event` `SessionUpdated` arm).
- **Observation (depth-confirms P-80's Phantom Reconnect):** `mutate_context` unconditionally
  returns `ContextMutationOutcome::RequiresResumption(config)` — Gemini has no native mid-flight
  swap. The runner's `execute_resumption` takes the old session out under the write lock, then
  `close()`s it *without holding the lock across `.await`*, then `model.connect(new_config)` builds
  a fresh socket. `close()` is deterministic: it flips `connected=false`, routes a `Message::Close`
  through the *same* single-writer mpsc channel as normal writes (ordering preserved), then `await`s
  the writer `JoinHandle` so teardown does not return until the sink is released. The resumption
  token is threaded end-to-end: server emits `sessionResumptionUpdate.resumptionToken` → translated
  to `ServerEvent::SessionUpdated { session: {"resumeToken": …} }` → runner stores it into
  `config.extra["resumeToken"]` → `send_setup` reads `extra["resumeToken"]` into
  `SessionResumptionConfig.handle`. There is a **documented protocol asymmetry**: client sends the
  field as `handle`, server returns it as `resumptionToken`. The merged config (P-80's
  `merge_config`) means a rebuild inherits all prior hot-swaps (instruction/tools/voice/temp/extra).
- **NEW subtlety:** the session's `audio_buffer` (a `BytesMut` accumulating sub-40ms chunks) is
  **not flushed before `close()`** during a resumption — teardown drops any buffered-but-unsent PCM.
  `interrupt()` and `clear_audio()` also *discard* the buffer rather than flush it. So a mid-flight
  context swap or a manual interrupt can silently lose the trailing <40ms of captured audio. The
  flush threshold is format-aware (`flush_threshold_bytes` = `bytes_per_second·40ms`, e.g. 1280 B
  for PCM16/16 kHz), corrected from a hardcoded-16k assumption.
- **Quality:** **NEUTRAL** — the teardown ordering + token threading is a genuinely careful mechanism
  (deterministic close, lock-discipline around `.await`); the un-flushed-audio-on-teardown is a small
  correctness edge a ferrochain realtime port should decide explicitly (flush-before-close vs
  discard).

**P-89 — Gemini event translation is best-effort and lossy on three axes.** *(NEUTRAL)*
- **Where:** `gemini/session.rs::translate_gemini_event`.
- **Observation:** (a) **Silent audio-decode failure** — base64 audio is decoded with
  `.decode(data).unwrap_or_default()`; corrupt base64 yields an *empty* `AudioDelta` with no error
  surfaced (divergence from the no-silent-empty-return posture). (b) **Multi-call truncation** —
  `toolCall.functionCalls` reads only `calls.first()`; if the server batches ≥2 function calls in one
  frame, calls `2..n` are dropped. (c) **Unknown-frame collapse** — any unrecognized frame maps to
  `ServerEvent::Unknown` (fail-open, consistent with P-80's fail-open loop). Response IDs/item IDs are
  synthesized as empty strings (`String::new()`), so downstream correlation by id is unavailable for
  Gemini (unlike OpenAI which carries real ids).
- **Quality:** **NEUTRAL** — pragmatic translation; the multi-call drop and silent-empty-audio are
  the spec-relevant divergences.

### Thread 2 — Avatar providers + keep-alive mechanics

**P-90 — The `AvatarProvider` trait abstracts two fundamentally different topologies; keep-alive is
fail-closed.** *(NEUTRAL)*
- **Where:** `adk-realtime` — `avatar/mod.rs` (`AvatarProvider`, `spawn_keep_alive`),
  `avatar/heygen/mod.rs`, `avatar/did/mod.rs`.
- **Observation:** `spawn_keep_alive` spawns a `tokio::interval` loop that **skips the first
  immediate tick**, then each period checks `is_active()` (break if false) and calls `keep_alive()`
  (break on `Err`). It is **fail-CLOSED** (any keep-alive error stops the task) — the opposite of the
  realtime event loop's fail-open posture (P-80). The two shipped providers realize opposite
  transport topologies behind the same trait: **HeyGen = server-relay** — creates a session via
  REST (`/v1/streaming.new`), connects a LiveKit `Room`, publishes agent audio through a
  `NativeAudioSource`; `send_audio` pushes PCM16 frames (24 kHz mono) into the room; `keep_alive`
  POSTs `/v1/streaming.task` with empty text. **D-ID = client-direct** — creates a chat session via
  REST, returns the SDP offer + ICE servers so the *client* establishes WebRTC directly with D-ID;
  `send_audio` is a **no-op** (D-ID renders from its own TTS) and `keep_alive` is a **no-op** (WebRTC
  manages timeout). So `send_audio`/`keep_alive` semantics are provider-defined, not trait-guaranteed.
- **Quality:** **NEUTRAL** — a clean pluggable abstraction, but the trait promises (`send_audio`,
  `keep_alive`) are honored very differently per provider; a ferrochain avatar port must not assume
  `send_audio` actually transports audio.

**P-91 — Avatar provider HTTP clients are timeout-less and constructors panic on non-HTTPS.**
*(WEAK)*
- **Where:** `avatar/heygen/mod.rs` + `avatar/did/mod.rs` (`::new`, `secure_url`).
- **Observation:** both providers build `reqwest::Client::new()` with **no `.timeout()`** (same
  systemic pattern as C1). Both `::new` constructors `assert!(api_base_url.starts_with("https://"))`
  — a **panic in a library constructor** (documented under `# Panics`), plus a redundant runtime
  `secure_url` guard returning `Err`. Credential handling is otherwise strong: `secrecy::SecretString`
  fields, redacted `Debug` (`"[REDACTED]"`/`<locked>`), `ExposeSecret` only at the header-set call
  site. Auth-failure mapping is explicit (401/403 → `AuthError`).
- **Quality:** **WEAK** — mixed posture: good secret hygiene, but library-constructor panics and
  timeout-less clients both conflict with ferrochain rules (no-panic-in-lib, mandatory timeout).

### Thread 3 — LiveKit bridge (sole native-tls ingress)

**P-92 — The LiveKit bridge is a thin, well-isolated, feature-gated adapter with fail-open audio and
a typestate builder.** *(NEUTRAL)*
- **Where:** `adk-realtime/src/livekit/{mod,bridge,handler,builder,config,error}.rs` (~600 LOC, 6
  files), gated behind the `livekit` Cargo feature.
- **Observation:** the module re-exports the subset of `livekit`/`livekit-api` types a voice agent
  needs (Room, tracks, `NativeAudioSource`, `AccessToken`, `VideoGrants`) so downstream crates depend
  only on `adk-realtime`. `bridge_input`/`bridge_gemini_input` read a `RemoteAudioTrack` via
  `NativeAudioStream`, buffer through `SmartAudioBuffer` (40 ms), and feed base64 PCM to the runner
  (24 kHz default, 16 kHz Gemini variant — LiveKit does the resample). `LiveKitEventHandler` wraps any
  inner `EventHandler`, delegates all non-audio callbacks verbatim, and on `on_audio` casts bytes→i16
  (zero-copy `bytemuck` fast path + odd-alignment fallback) then `capture_frame`s into a
  `NativeAudioSource` — **fail-open**: capture errors are `warn!`-logged, never propagated (matches
  P-80). `LiveKitRoomBuilder<Missing|Present>` is a **typestate builder** enforcing "identity before
  connect" at compile time; `connect` also runtime-guards empty identity/room and auto-generates a
  UUID room name. `LiveKitConfig` uses `SecretString` + redacted Debug + URL validation.
- **Isolation:** delegation is **proptest-covered** (`livekit_delegation_tests.rs`, 6 property tests <!-- [comparative-cert-2] CORRECTION: "7 property tests" → grep confirms 6 fn prop_* functions in livekit_delegation_tests.rs (prop_on_text, prop_on_transcript, prop_on_speech_started, prop_on_speech_stopped, prop_on_response_done, prop_on_error); matches the 6 non-audio callbacks in the EventHandler trait; "7" was off-by-one -->
  on the non-audio callbacks), but the actual WebRTC FFI audio path and `Room::connect` live in
  `#[ignore]`-gated integration tests requiring `LIVEKIT_URL`/`LIVEKIT_API_KEY`/`LIVEKIT_API_SECRET`.
- **Quality:** **NEUTRAL** — a clean, contained bridge; the only ferrochain-relevant friction is the
  native-tls transport it pulls (see P-93) and the untested live FFI path.

**P-93 — native-tls ingress reconciliation: livekit is the sole *first-party explicit* opt-in.**
*(WEAK / MAP-note)*
- **Where:** root `Cargo.toml` — `livekit = { version = "0.7.36", default-features = false,
  features = ["tokio", "native-tls"] }`.
- **Observation:** a workspace-wide scan of every first-party `Cargo.toml` for the literal
  `native-tls` returns **exactly one hit** — the `livekit` dependency in the root manifest. The other
  two "native-tls chains" recorded by A5 (mistralrs/hf-hub, audio/hf-hub) are **transitive** (pulled
  via third-party crate default features — `mistralrs`/`hf-hub`/`candle` stack), not first-party
  feature declarations: `adk-mistralrs` and `adk-audio` both consume the workspace `reqwest`
  (`default-features = false, rustls-tls-native-roots`), so their native-tls exposure is upstream, not
  declared. Crates that pull `livekit`: `adk-realtime` (feature `livekit`), `adk-audio`, and the
  `adk-rust` aggregator. So: **within adk-realtime, livekit is the sole native-tls ingress**, and
  **it is the sole first-party explicit native-tls opt-in in the whole workspace.** This *clarifies*
  (does not contradict) A5's "three chains," which counts transitive exposure. Corroborates C2:
  adk-realtime defaults to rustls (`rustls` w/ aws-lc-rs; `google-cloud-auth` default-rustls-provider;
  WS transports over tokio-tungstenite+rustls); native-tls rides only the optional `livekit` feature.
- **Quality:** **WEAK / informative** — the feature isolation is genuine and the ingress is a single,
  optional, first-party toggle; a ferrochain realtime-analog can adopt the LiveKit topology while
  substituting a rustls transport, since native-tls here is livekit-the-crate's own default, not an
  adk design requirement.

### Thread 4 — a2a-v1 retry / caching / version negotiation (dynamic behavior)

Confirmations of P-86's static reads, with three NEW behavioral refinements and explicit
UNVERIFIABLE-without-runtime flags. **Grep confirms zero `wiremock`/`mockito`/`httpmock`/`MockServer`
usage anywhere in `adk-server`** — so every transport path below is exercised only by pure unit tests
over helper functions; the wire round-trips are untested.

**P-94 — a2a-v1 client retry is JSON-RPC-unary-only and its timeout-retry branch is near-dormant.**
*(WEAK — refines P-86)*
- **Where:** `adk-server/src/a2a/client.rs` → `v1_client::A2aV1Client::{send_with_retry,
  jsonrpc_call, rest_post, rest_get, rest_delete, send_streaming_message, subscribe_to_task}`.
- **Observation (SOURCE-CONFIRMED, structure):** `send_with_retry` is invoked **only** by
  `jsonrpc_call`. The 8 REST-binding methods and the 2 streaming ops (`send_streaming_message`,
  `subscribe_to_task`) call `http_client.<verb>(…).send()` **directly — single-shot, no retry**. So
  "configurable retry" covers the 9 JSON-RPC unary operations but NOT the REST binding nor streaming.
  Backoff = `base_delay · 2^(attempt-1)` (default 1 s → 1 s/2 s/4 s), **no jitter, no cap, no
  `Retry-After` honoring**. Retry triggers: HTTP status `429` or `≥500` (while `attempt <
  max_retries`), OR a transport `Err` where `e.is_timeout()`. **NEW:** because the client is
  `reqwest::Client::new()` with **no `.timeout()`** (C1), no client-side read timeout fires, so
  `is_timeout()` is essentially only reachable via connect-level timeouts — the timeout-retry branch
  is structurally near-dormant; in practice retry covers 429/5xx only.
- **Quality:** **WEAK** — the retry is real and unit-covered for config storage, but its scope
  asymmetry (unary-only) and the dormant timeout branch are spec-relevant if a ferrochain a2a-analog
  wants uniform retry across bindings.

**P-95 — a2a-v1 "card caching" is conditional-revalidation, not a value cache; the stored card body
is write-only.** *(WEAK — refines P-86)*
- **Where:** client `resolve_agent_card_cached` + `CachedCard`; server
  `adk-server/src/a2a/v1/card.rs::CachedAgentCard`.
- **Observation (SOURCE-CONFIRMED):** client sends `If-None-Match` (etag) + `If-Modified-Since`
  (last_modified) from `cached_card`; on `304 NOT_MODIFIED` returns `Ok(None)`; on success caches
  `etag`+`last_modified`+`card`. **NEW:** the stored `cache.card` is **write-only** — it is set but
  never read back (only `cache.etag`/`cache.last_modified` are consumed to build conditional headers;
  `agent_card()` returns the *constructor* card, and 304→`None` hands the caller nothing). So the
  mechanism is HTTP conditional *revalidation*, not a served value cache. Server side emits a real
  ETag = `DefaultHasher` (SipHash, deterministic across processes — the doc-comment under-claims
  "within a single process build") over serialized card JSON, plus `Last-Modified`; `matches_etag`
  handles quoted/unquoted/`*` wildcard; `modified_since` is strict `>`. Both sides are unit-tested
  (server: 13 tests; client: `cached_card_starts_empty` only).
- **Quality:** **WEAK** — the conditional-request logic is correct and cross-consistent between
  client and server, but "caching" oversells it; a ferrochain port wanting a true card cache must add
  the cache-hit read path.

**P-96 — Two divergent retry implementations coexist in a2a-v1; the server push path adds SSRF
defense.** *(NEUTRAL — NEW)*
- **Where:** client `send_with_retry` (client.rs) vs server
  `adk-server/src/a2a/v1/push.rs::HttpPushNotificationSender::send_with_retry`.
- **Observation (SOURCE-CONFIRMED):** the server push sender retries on **any** non-success status
  **and** any send error (not just 429/5xx), with a fixed `RETRY_DELAYS = [1,2,4]` s table and
  `MAX_RETRIES = 3`, and — critically — calls `validate_webhook_url(url)` **once before the retry loop begins** (not repeated per attempt; URL is fixed) <!-- [comparative-cert-2] CORRECTION: "before every attempt" → source shows validate_webhook_url called at line 100, before the `for attempt in 0..=MAX_RETRIES` loop at line 102; called once per delivery, not per retry iteration --> to
  reject private IP ranges / localhost (SSRF prevention) for webhook delivery. On exhaustion it
  surfaces `A2aError::PushDeliveryFailed`. This is the more defensive of the two retry paths; the
  client path is narrower (429/5xx/timeout). So the corpus ships **two different retry policies** for
  the same protocol family.
- **Quality:** **NEUTRAL** — the SSRF guard on outbound push is a genuine security control worth
  mirroring; the policy divergence between the two senders is an internal inconsistency a unified
  ferrochain a2a-analog would want to reconcile.

**Version negotiation (SOURCE-CONFIRMED, no new pattern):** server `v1/version.rs::negotiate_version`
— `SUPPORTED_VERSIONS = ["0.3","1.0"]`; `None`/empty → default `"0.3"`; unsupported →
`A2aError::VersionNotSupported` with `json_rpc_code = -32009`, `http_status = 400`; response header
`a2a-version` echoes the negotiated version. Client always sends `a2a-version: 1.0`; on `400` with
`error.code == -32009` it parses supported versions from `data[].metadata.supported` (comma-space
split). Both directions are pure-unit-tested against **assumed** JSON shapes; the shapes are never
wired together.

**UNVERIFIABLE-without-runtime (explicit, per task item 4):** the following a2a-v1 dynamic behaviors
CANNOT be confirmed from source alone — no mock server / integration harness exists anywhere in
`adk-server` (grep-confirmed), and no wire round-trip test drives them. The LOGIC is present and
internally consistent; the RUNTIME behavior is unproven:
  1. Actual exponential-backoff sleep timing / total elapsed under repeated 429/5xx.
  2. Actual `304 → Ok(None)` conditional-request round-trip (client `If-None-Match` vs server ETag
     match).
  3. Actual `-32009` version-negotiation round-trip — specifically whether the server's emitted
     `data[].metadata.supported` shape matches the client's parser (each side unit-tests its own
     assumed shape; the coupling is untested).
  4. Actual push-notification SSRF-rejection + retry-then-`PushDeliveryFailed` delivery outcome.
These are **validation-phase** (mock-server / live-integration) concerns, not closable by further
static analysis.

### Thread 5 — remaining A6-named unread path (closure)

**P-97 — openai/webrtc.rs is a full alternate transport governed by the same runner FSM; no new
mechanism.** *(INFO / LOW)*
- **Where:** `adk-realtime/src/openai/webrtc.rs` (696 LOC), feature `openai-webrtc`.
- **Observation:** ships `OpusCodec` (PCM16 ↔ Opus via `audiopus`, C-lib build → requires cmake) and
  `OpenAIWebRTCSession` (Sans-IO WebRTC via `str0m`, `SdpAnswer`/offer handling), implementing the
  same `RealtimeSession` trait as the WS and Gemini sessions. Because it satisfies the identical
  contract, it is governed identically by the runner state machine (P-80) — mutation, resumption,
  tool dispatch, and event routing are transport-agnostic. `str0m` is Sans-IO (no native-tls;
  rustls-compatible). Feature-gated and cmake-dependent, so it is an opt-in low-latency alternative,
  not a default path.
- **Quality:** **INFO / LOW** — characterized and closed; introduces no governing mechanism beyond
  the RealtimeSession contract already modeled. Thread 5 has no residual depth gap.

### Pass A7 novelty trajectory (informative)

A6 produced **HIGH** novelty on realtime FSM (P-80/P-81) and a2a client (P-85/P-86) because it was
the *first* function-level read of those subsystems. A7's re-reads produced **MED** refinements on
threads 1/2/4 and **LOW** on threads 3/5 — new behavioral detail (audio-loss-on-teardown P-88, lossy
translation P-89, two-topology avatar abstraction P-90, retry-scope asymmetry P-94, write-only card
cache P-95, dual-retry+SSRF P-96) but **no new subsystem, no new governing mechanism, and no
overturned model.** Every A6-named residual thread is now read at depth and closed to an explicit
verdict. The only remaining unknowns are the four UNVERIFIABLE-without-runtime a2a-v1 items, which no
further static pass can close (they require a mock/live harness → validation phase). This is textbook
novelty decay.

## Pass A7 cross-cutting note (informative, not a conclusion)

Two recurring postures crystallize across the realtime/avatar/livekit surface: (1) **fail-open on the
audio hot path** (P-80 event loop, P-92 LiveKit capture, P-89 unknown-frame collapse) vs
**fail-closed on the control/lifecycle path** (P-90 keep-alive stops on error, P-88 deterministic
close-await); and (2) **strong secret hygiene** (SecretString + redacted Debug across livekit/avatar
configs) sitting alongside **library-constructor panics** (P-91) and **systemic timeout-less clients**
(P-91, P-94 — the same C1 pattern). Per D16 the adoption question is deferred; these are observations
for the eventual comparative assessment.

## State Checkpoint
```yaml
pass: A7
scope: patterns-observed (convergence deepening round 2 — A6-named residual threads to depth)
patterns_added: 10 (P-88..P-97 — 0 STRONG, 5 NEUTRAL, 4 WEAK, 1 INFO)
patterns_total: 97
threads_worked: [gemini-session-internals, avatar-providers+keepalive, livekit-bridge, a2a-v1-dynamic, openai-webrtc-closure]
novelty: MED-trending-LOW (refinements within A6-surfaced subsystems; no new subsystem/mechanism)
unverifiable_without_runtime: [a2a-backoff-timing, a2a-304-roundtrip, a2a-32009-roundtrip, push-ssrf-retry-outcome]
status: complete
timestamp: 2026-07-13
```
