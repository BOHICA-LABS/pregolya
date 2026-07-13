---
artifact: comparative/assessment-parts/part-3-conflicts-negative-evidence
assessment: D16 comparative best-patterns assessment — Part 3 of 4
scope: cross-corpus design conflicts + negative evidence catalog
constraint: >
  D16 RUST-BLINDNESS: language carries zero evidentiary weight; production-grade merit only.
  Anti-sunk-cost: no inherited decisions from either corpus. Binding prior decisions (D9, D11,
  D13, D7, D8) constrain recommendations but do not over-ride production-grade analysis.
corpus_1: LangChain/LangGraph @ langchain==1.3.13 / langgraph==1.2.9 (.factory/semport/)
corpus_5: adk-rust v1.0.0 SHA a6c79b6f (.factory/comparative/adk-rust/)
produced_by: architect
date: 2026-07-13
status: complete
---

# D16 Comparative Assessment — Part 3: Cross-Corpus Design Conflicts + Negative Evidence

---

## Preamble

Parts 1 and 2 extracted the strongest patterns from each corpus independently under the
D16 Rust-blindness constraint. This part answers the harder question: where the two corpora
materially disagree on design, which body of evidence wins, and which adk-rust patterns
ferrochain must actively reject regardless of their Rust fluency.

Evidence is cited by pattern ID (P-NNN from patterns-observed.md / behavioral-intent.md)
and semport section (§N from behavioral-intent.md graph/).

---

## Section A — Cross-Corpus Design Conflicts

Ten conflict sites identified. Ordered by binding constraint strength, then stakes.

---

### CONFLICT-1 — Graph execution model: BSP channel-version-triggered vs edge-following walker

**What Corpus 1 (LangGraph) does.**
The execution engine is a strict Bulk Synchronous Parallel (Pregel) engine with
version-triggered scheduling. On each super-step `tick()`:
- A node fires iff ANY subscribed channel has `channel_versions[chan] > versions_seen[node][chan]`
  — i.e. was written since the node last ran. Stale channels do not re-trigger a node.
- Task IDs are content-addressed: `xxh3_128(checkpoint_id ‖ ns ‖ step ‖ name ‖ PULL/PUSH ‖ triggers)`.
  Same graph state → same task IDs → replay is idempotent by construction.
- After all tasks complete, `apply_writes()` folds updates in `task_path_str(path[:3])`
  SORTED ORDER — deterministic regardless of how long tasks took.
- `LastValue` channel raises `InvalidUpdateError` on more than one write per step. "One writer
  per step" is a hard invariant, not a soft convention.
Evidence: semport/graph/behavioral-intent.md §1.1, §1.2, §1.4.

**What Corpus 5 (adk-rust) does.**
The engine is an edge-following graph walker with a barrier-apply phase. Super-steps:
- Next nodes = `graph.get_next_nodes(executed_nodes, state)` — pure conditional-edge following.
  There is NO `versions_seen`, NO `channel_versions`, NO version-triggered scheduling.
- Tasks have no content-addressed IDs; nodes are keyed by name only.
- After all concurrent nodes resolve via `stream::iter(futures).buffer_unordered(n)`, updates are
  folded in COMPLETION ORDER — nondeterministic for non-commutative reducers.
- `Reducer::Overwrite` silently takes the last write in nondeterministic order. No concurrent-write
  detection, no `InvalidUpdateError` analog.
Evidence: behavioral-intent.md §7.1–§7.2; patterns-observed.md P-23, P-28.

**Production trade-offs.**
LangGraph's BSP model adds implementation complexity (channel-version bookkeeping, monotonic
per-step version counter) but gives three correctness guarantees adk-rust lacks:
(a) Determinism — two runs of the same graph with the same inputs produce the same output
    regardless of wall-clock task durations.
(b) Replay idempotency — content-addressed task IDs allow a crashed-and-resumed run to skip
    tasks whose writes were already persisted.
(c) Safe concurrent write detection — the LastValue→InvalidUpdateError invariant prevents
    silent last-write-wins when more than one node writes to the same channel in a step.
adk-rust's write-isolation (per-node state clone + deferred apply) is correct; its ORDERING
guarantee is not.

**D-decision constraint.** D11.1 mandates a HYBRID engine (orchestrator-loop per run + actor-
style outer scheduler). D9 mandates a design-conversation gate before any execution-model ADR.
The execution model ADR must explicitly address the three missing LangGraph guarantees.

**Recommendation.**
Build the versions_seen/channel_versions mechanism and content-addressed task IDs (or a
structurally equivalent monotonic-sequence scheme). Apply writes in deterministic sorted order
keyed on task identity. Enforce one-writer-per-step at the channel level with a structured
error (not silent last-write-wins). adk-rust's nondeterministic completion-order folding is a
counter-example to adopt here, not a template.

---

### CONFLICT-2 — Checkpoint durability model: per-task pending writes vs step-boundary whole-state

**What Corpus 1 (LangGraph) does.**
Three-tier durability model:
- `sync` (default): `put_writes` per-task intermediate persist; `put_checkpoint` after step.
  A crash mid-step: tasks whose writes were PUT survive; uncommitted tasks re-run (at-least-once
  for uncommitted, effectively-once for committed).
- `async`: checkpoint writes happen in background; lower latency, possible loss on crash.
- `exit`: checkpoints only on shutdown; cheapest, suitable for ephemeral graphs.
Checkpoint IDs are uuid6 (monotonic-sortable). "Latest" = `ORDER BY checkpoint_id DESC`, safe
under concurrent writers. Checkpoint shape includes `pending_writes` per-task records.
Evidence: semport/graph/behavioral-intent.md §2.4, §5.1–§5.3.

**What Corpus 5 (adk-rust) does.**
Single-tier: `save_checkpoint` persists the WHOLE state + `pending_nodes` + `step` AFTER each
super-step. No `put_writes`-equivalent per-task intermediate persist. No ERROR/RESUME/INTERRUPT
markers. No durability mode selector. Checkpoint IDs are `Uuid::new_v4()` (random); "latest" is
`ORDER BY created_at DESC` — ambiguous under same-tick writes or clock skew/adjustment.
Evidence: patterns-observed.md P-29, P-31; behavioral-intent.md §8.1.

**Production trade-offs.**
Per-task pending writes meaningfully change crash-recovery granularity for expensive or
non-idempotent nodes. With step-boundary-only checkpoints, a 10-node step where 9 completed
and 1 crashed forces ALL 10 to re-run; with per-task writes, the 9 committed tasks skip and
only the crashed task re-runs. For cheap idempotent nodes the difference is latency; for
expensive/non-idempotent nodes (LLM calls, external API mutations) it is correctness.
The wall-clock "latest" ordering is a latent correctness bug: two checkpoints written in the
same millisecond under any concurrent writer pattern have ambiguous order.

**D-decision constraint.** D11.2 mandates RUST-NATIVE msgpack checkpoint format. D11.3 mandates
ALL THREE durability tiers ported; ferrochain DEFAULTS to sync (crash-safe). These D11 steers
are binding and confirm the LangGraph model is the reference.

**Recommendation.**
Implement all three durability tiers with sync as default. Implement a `put_writes` equivalent
for per-task intermediate persist. Use a monotonic logical sequence (not wall-clock) for
checkpoint ordering. adk-rust's step-boundary-only model is insufficient for D11.3.

---

### CONFLICT-3 — Interrupt/resume (HITL): resumable-dialogue vs notification-only

**What Corpus 1 (LangGraph) does.**
`interrupt(value)` called inside a node pushes `value` onto a per-task scratchpad. The node
raises `NodeInterrupt` and execution halts with checkpoint saved. On resume with
`Command(resume=value)`, the graph rewinds the interrupted task's checkpoint and re-executes
the node FROM THE START. Prior calls to `interrupt()` within the node return their stored
values in FIFO order (the scratchpad counts them by position). This means:
- A node calling `interrupt()` three times requires three separate `Command(resume=...)` invocations.
- The human can inject structured data (not just a signal) into the node's flow.
- The node is fully re-executed; the interrupt contract is that repeated execution is idempotent
  up to the interrupt point.
Evidence: semport/graph/behavioral-intent.md §3.1–§3.5.

**What Corpus 5 (adk-rust) does.**
`Interrupt { Before(node) | After(node) | Dynamic { message, data } }`. On interrupt the
executor saves a checkpoint and returns `GraphError::Interrupted`. Resume restores state and
re-runs `pending_nodes`. There is NO resume-value injection type, NO per-task scratchpad, NO
"node re-executes from start" idempotent-replay contract. `Dynamic` carries data but there is
no path to inject it back into the interrupted node's execution flow.
Evidence: patterns-observed.md P-30; behavioral-intent.md §10.

**Production trade-offs.**
LangGraph's resume-value scratchpad is the foundational mechanism for HITL workflows that need
human decisions to affect in-flight logic (e.g. "approve this plan?", "which tool should I use?",
"validate this extraction"). Without it, an interrupt is a stop signal; with it, an interrupt is
a two-way dialogue. This distinction is non-trivial to retrofit.

**D-decision constraint.** Domain A (SOC analyst) and Domain B (dark factory) are design forcing
functions (D8). Both require HITL where human decisions flow back into agent logic — exactly the
resume-value scratchpad use case. adk-rust's notification-only model fails both domains.

**Recommendation.**
Implement the full LangGraph HITL contract: per-task scratchpad, FIFO resume-value delivery,
node-re-executes-from-start replay contract, `Command(resume=value)` API. This is a ferrochain-
original implementation; there is no adk-rust reference to adapt.

---

### CONFLICT-4 — Logical clock vs wall-clock checkpoint ordering

**What Corpus 1 (LangGraph) does.**
Checkpoint IDs are uuid6 (time-sortable). A single monotonic `next_version` (default integer
+1) is computed per step and shared across all channels written in that step. Channel versions
are monotonically increasing per-namespace. "Latest" = sort by checkpoint_id (monotonic),
not wall-clock timestamp. Fork creates a new checkpoint with a `parent` pointer preserving
lineage; replay walks the parent chain.
Evidence: semport/graph/behavioral-intent.md §1.2, §2.2, §2.6.

**What Corpus 5 (adk-rust) does.**
`Uuid::new_v4()` (random, not time-sortable) for checkpoint IDs. "Latest" = `ORDER BY
created_at DESC` (wall-clock). Same-timestamp tie-break by id is arbitrary. Session rewind
uses `timestamp > target` deletion + same-timestamp `id != target` sweep — fragile under clock
adjustments or clock skew in distributed deployments. Fork is implemented as a copy (new UUID,
no parent pointer), losing branch lineage entirely.
Evidence: patterns-observed.md P-31; behavioral-intent.md §8.1, §8.3.

**Production trade-offs.**
Wall-clock ordering fails under three real scenarios: (a) NTP adjustment reverses apparent
time; (b) two writers in the same millisecond; (c) distributed deployment with imperfect clock
sync. Logical monotonic ordering fails only if the sequence counter overflows or is corrupted —
a much narrower failure mode. Fork-by-copy vs fork-by-parent-pointer is a correctness
distinction for time-travel: without a lineage tree, branch comparison and branch-aware replay
are impossible.

**D-decision constraint.** D11.2 (Rust-native msgpack checkpoint format) leaves clock choice
open; D11.3 (all three durability tiers) implies per-task writes which compound the ordering
problem if wall-clock is used.

**Recommendation.**
Use a monotonic logical clock (per-thread or per-namespace sequence counter) for checkpoint
IDs. Implement fork via parent-pointer lineage (checkpoint references its parent, not a
full copy). adk-rust is the explicit counter-example on both points.

---

### CONFLICT-5 — Streaming/event model: astream_events v2 typed taxonomy vs flattened Event envelope

**What Corpus 1 (LangGraph) does.**
`astream_events v2` (semport/core §1, behavioral-intent.md §5 via langchain-core) exposes:
- 7-field shape: `{event, name, run_id, parent_ids, tags, metadata, data}`.
- 20+ `on_<type>_<phase>` combos (on_chain_start/stream/end, on_chat_model_start/stream/end,
  on_tool_start/end/error, on_retriever_start/end, …).
- Start-before-end guarantee: an `on_*_start` event is yielded before the underlying operation
  runs (via `tee(inputs,2)` + eager first-pull of the generator).
- `ls_*` run-metadata fields (`ls_provider`, `ls_model_name`) for observability.
- `tool_call_id` on `on_tool_error` for correlation.
- Cancellation + cleanup contract: on stream drop, pending events flush in defined order.
Evidence: semport/core/ANALYSIS-STATE.md pass-7 item 2, behavioral-intent.md §5.

**What Corpus 5 (adk-rust) does.**
`Event { #[serde(flatten)] llm_response, id, timestamp, invocation_id, branch, author,
EventActions { state_delta, artifact_delta, skip_summarization, transfer_to_agent, escalate,
tool_confirmation, compaction, route } }`. Events are agent-turn lifecycle units, not a typed
streaming event taxonomy. `is_final_response()` is the turn-completion predicate. No `on_*_start/
end` taxonomy, no `run_id` correlation tree, no `ls_*` metadata, no streaming-event schema.
The flatten coupling (P-11) ties Event's JSON schema to LlmResponse's.
Evidence: patterns-observed.md P-11; behavioral-intent.md §1 (event model).

**Production trade-offs.**
The astream_events taxonomy enables fine-grained observability (trace each model call, each tool
invocation, each retriever query independently) and composable callbacks (instrument any phase
without modifying agent code). The flat Event envelope is simpler to produce and sufficient
for turn-level lifecycle, but inadequate for phase-level tracing across nested agent calls.
For Domain A (SOC analyst) the astream_events style enables real-time audit of each reasoning
step; for Domain B (dark factory) it enables per-step cost attribution.

**D-decision constraint.** D13 (no LangGraph Platform wire compat) means ferrochain's event
schema does not need to mirror astream_events v2 exactly. But the TAXONOMY (typed per-phase
events with run_id correlation and parent_ids) is a production-grade design independent of
the specific wire format.

**Recommendation.**
Design ferrochain's streaming event model around a typed per-phase taxonomy (start/stream/end
per operation type, with a run_id correlation tree and parent_ids). The wire format is
ferrochain-native (not langchain wire compat). Do not adopt adk-rust's flattened Event envelope
as the observation model for external consumers; retain it only as an internal persistence unit.

---

### CONFLICT-6 — Error taxonomy: Python exception hierarchy vs 2D component×category struct

**What Corpus 1 (LangChain) does.**
Python exception class hierarchy (LangChainException → LangChainError → OutputParserException,
etc.). Retryability is encoded per-exception-class by convention, not by a testable contract.
No structured machine code, no HTTP-status mapping, no retry-hint co-travel.
Evidence: semport/core/behavioral-intent.md §error handling.

**What Corpus 5 (adk-rust) does.**
`AdkError` is a struct with orthogonal `ErrorComponent` (14 subsystems) × `ErrorCategory`
(10 failure kinds) dimensions. Retryability derives from category via a total, exhaustively-
tested mapping (P-01, P-04). `code: &'static str` is machine-processable. `RetryHint` co-
travels with the error. `http_status_code()` is a total mapping. `to_problem_json()` emits
RFC-7807 Problem Details. `RetryHint::for_category` has a truth-table unit test across all
10 categories; `http_status_code` similarly.
Evidence: patterns-observed.md P-01, P-04; behavioral-intent.md §1.

**Production trade-offs.**
The 2D struct model is unambiguously stronger than a Python exception hierarchy for Rust:
(a) Total mappings (category→retry, category→HTTP status) eliminate per-call-site if-chains.
(b) Machine codes enable metric aggregation across subsystems without string matching.
(c) Retry hint co-travel (P-04) eliminates the "re-parse the error string to decide retry" anti-
    pattern. (d) RFC-7807 emission is a first-class method, not an afterthought.
The Python hierarchy does not translate to Rust structurally.

**D-decision constraint.** D5 (pydantic→serde/schemars ADR required). No decision yet on error
taxonomy structure, but ferrochain CLAUDE.md mandates structured errors.

**Recommendation.**
Adopt the adk-rust 2D component×category architecture for ferrochain's `FerrochainError`.
Rename components to ferrochain crate names (Core/Graph/Checkpoint/Provider/Server/etc.).
Carry a machine code, RetryHint, and an HTTP-status total mapping. This is the one conflict
where Corpus 5 is DECISIVELY STRONGER and should take priority.

---

### CONFLICT-7 — Memory service: no built-in service vs user/app/project layered scope model

**What Corpus 1 (LangChain/LangGraph) does.**
No built-in MemoryService in langchain-core. LangGraph stores conversation state via
checkpointing (`BaseCheckpointSaver`); semantic memory is delegated to external LangMem /
third-party vector stores. No standard user-partitioning, project-scoping, or GDPR-erasure
contract in the core.
Evidence: semport/core behavioral-intent §8 (absence); semport/graph §2.

**What Corpus 5 (adk-rust) does.**
`MemoryService` trait with user/app/project three-scope model: global (bleeds into all project
views), per-project (global ∪ project), per-user+app always-partition. Keyword-intersection
default (not embeddings). GDPR erasure `delete_user`. 8 backends. `MemoryServiceAdapter` binds
`(app_name, user_id, project_id?)` at construction. Project-scope isolation is real (cross-project
read is blocked) but global tier deliberately bleeds into every project view (P-26). In-memory
search ignores `search_in_project` override risk (P-19).
Evidence: patterns-observed.md P-26, P-19; behavioral-intent.md §9.

**Production trade-offs.**
Domain C (OpenClaw personal memory) requires user-private, per-user durable recall — exactly
the opposite of the "global tier bleeds into every project" default in adk-rust. The adk-rust
model's firm user/app partitioning and GDPR erasure contract are correct and valuable; its
additive-global-default is the wrong default for strictly-personal memory.

**D-decision constraint.** D8 Domain C forces the personal-memory design as a Phase-1 checklist
item.

**Recommendation.**
Build a MemoryService trait with user/app/session partitioning (borrowing adk-rust's structure)
but invert the scope default: user-private memory must NOT bleed into any other scope by
default. Global tier is an explicit opt-in. GDPR erasure must be a first-class required method
(not a default-error optional). The adk-rust global-overlay default is the anti-pattern to
avoid.

---

### CONFLICT-8 — Agent composition: graph-as-agent vs composite-agent-tree

**What Corpus 1 (LangGraph) does.**
Agents ARE graphs. `create_react_agent` returns a compiled `StateGraph` with dedicated nodes
(`call_llm`, `execute_tools`, `should_continue` routing). `AgentState` carries
`messages: Annotated[list, operator.add]` as the canonical state channel. Tool execution is
a graph node, not a method call. Multi-agent patterns (supervisor, swarm, handoff) are graph
topologies — one graph transfers control to another graph.
Evidence: semport/graph/behavioral-intent.md §4; semport/core §6.

**What Corpus 5 (adk-rust) does.**
`Agent` trait with `sub_agents() -> &[Arc<dyn Agent>]` — a composite tree. `SequentialAgent
= LoopAgent(1)` (certified C22); `DEFAULT_LOOP_MAX_ITERATIONS = 1000`. Multi-agent is a tree
of cooperating `Arc<dyn Agent>` objects. Workflow agents (Sequential, Parallel, Loop, Conditional)
are composites, not graph topologies. Transfer is driven by an event action, not a graph edge.
Evidence: behavioral-intent.md §4 (adk-agent); patterns-observed.md P-15.

**Production trade-offs.**
"Agent IS a graph" cleanly unifies the tool-execution model and the routing model under one
abstraction. The composite-tree approach is more ergonomic for building simple sequences but
requires a separate API surface for complex routing (branching, fan-out, fan-in). LangGraph's
approach is harder to learn but avoids the proliferation of special-purpose agent types
(SequentialAgent, LoopAgent, ConditionalAgent). For ferrochain targeting LangGraph semantics
(D7), the graph-as-agent model is structurally required.

**D-decision constraint.** D7 (core → graph → partners priority; LangGraph runtime is the P0
differentiator). D11.1 (HYBRID engine).

**Recommendation.**
Agents that need complex routing should be expressed as StateGraph instances. A lightweight
high-level API (analogous to `create_react_agent`) builds a standard graph topology from
declarative parameters. adk-rust's composite-tree agent types inform the ergonomic API surface
but should not replace the graph-centric execution model.

---

### CONFLICT-9 — Delta checkpoint granularity: per-channel vs whole-state map

**What Corpus 1 (LangGraph) does.**
`DeltaChannel` stores per-channel deltas with a parent-pointer lineage walk. Each channel has
its own snapshot cadence and can express channel-local semantics (e.g. an append-only channel's
deltas independent of unrelated keys). Fork is parent-pointer (preserves lineage tree).
Evidence: semport/graph/behavioral-intent.md §1.4, §2.6.

**What Corpus 5 (adk-rust) does.**
`DeltaCheckpointer<C: Checkpointer>` wraps any checkpointer with whole-state `MapDelta`
(added/removed/modified keys of the entire `HashMap<String,Value>`). Full snapshot at step 0
and every `full_snapshot_interval` (default 10). Round-trip `Diff` contract is property-tested.
Fork by copy (P-31).
Evidence: patterns-observed.md P-22, P-25.

**Production trade-offs.**
Whole-state diff is simpler and backend-agnostic. Per-channel diff matches the LangGraph
abstraction boundary (each channel tracks its own history) and enables channel-local branching.
For a small state (few keys), the difference is negligible. For a large state with many
independent channels (common in production multi-agent graphs), per-channel deltas can
significantly reduce checkpoint size.

**D-decision constraint.** D11.2 (Rust-native msgpack format) — neither corpus's delta format
applies directly.

**Recommendation.**
Design delta checkpointing at the channel boundary in the msgpack checkpoint format. adk-rust's
composable `DeltaCheckpointer` wrapper pattern is sound and transferable; the granularity
should be per-channel (matching LangGraph semantics), not per-whole-state. The `Diff` round-trip
property-test pattern (P-22) should be replicated as a VP.

---

### CONFLICT-10 — Server surface: platform-style resource model vs A2A-centric protocol server

**What Corpus 1 (LangGraph Platform) does.**
61-endpoint REST catalog: thread CRUD, run lifecycle (create/get/cancel/join/stream/list), run
background callbacks (webhook `on_run_completed`), cron jobs, assistant management, stateful
namespace (namespace:thread_id:checkpoint_ns). Run-id is a first-class resource. Streaming
runs and unary runs are behaviorally equivalent (both drive the engine).
Evidence: semport/platform/module-inventory.md.

**What Corpus 5 (adk-rust) does.**
A2A v1.0.0 protocol focus: 11 JSON-RPC operations, SSRF-hardened push (P-35), defense-in-depth
HTTP middleware (P-36), exhaustive input validation (P-37), auth-as-injected-trait (P-38).
BUT: `message_stream` is a behavioral stub — it emits task-state transitions only, never drives
the engine (P-41). Background run execution is also a placeholder (P-43). Durable task/run/
idempotency state is in-memory-only with no persistence trait seam (P-43).
Evidence: patterns-observed.md P-35–P-38, P-41, P-43; behavioral-intent.md §13, §17.

**Production trade-offs.**
The LangGraph Platform resource model (thread, run, assistant, cron as first-class REST
resources with lifecycle management) serves Domain B (multi-day durable runs surviving
restarts). adk-rust's HTTP hygiene layer (SSRF gate, security headers, input size bounds,
auth-as-trait) is production-grade and directly portable. adk-rust's streaming stub and
placeholder run execution are explicit gaps — counter-examples ferrochain must not inherit.

**D-decision constraint.** D13 (ferrochain-server first-party; no LangGraph Platform wire compat).
ferrochain-server's resource model is independently designed but the LangGraph endpoint catalog
is the design reference for thread/run semantics.

**Recommendation.**
Build ferrochain-server's HTTP boundary with adk-rust's defensive middleware stack (borrow
P-35/P-36/P-37/P-38 patterns directly). Design the resource model (thread, run) from the
LangGraph Platform endpoint catalog as the semantic reference, not the wire format. Streaming
and unary runs must be behaviorally equivalent from day 1 — no stubs.

---

## Section B — Negative Evidence Catalog

Seventeen adk-rust patterns that ferrochain must actively NOT inherit. Each entry: verified
source (P-NNN), description, and the ferrochain requirement it implies.

---

### NE-01 — Default sandbox provides no isolation; honest-capability principle does not force enforcement

**Source:** P-61, P-49, P-62.
**Finding:** The DEFAULT sandbox (ProcessBackend) enforces only `env_clear()` + wall-clock
timeout. No filesystem, network, or memory isolation. Feature `process` is the Cargo default;
secure backends (bubblewrap, WASM) are ALL opt-in behind feature flags and external binaries.
`BackendCapabilities` is honest about enforcement (`EnforcedLimits` all-false for ProcessBackend)
but nothing FORCES a caller to check before running untrusted code. The phase-1 Rust executor
(`RustSandboxExecutor`) has a strict policy declaration but no enforcement; the Docker backend
advertises per-request policy enforcement that it silently ignores (P-83).

**Ferrochain requirement (Domain C / BC candidate):**
`ferrochain-sandbox` MUST default to an ENFORCING backend (WASM or container). The
non-isolating process backend must be an explicit, loud opt-in (`Sandbox::unsafe_process_no_isolation()`).
Policy strictness must be bound to backend capability by a hard precondition: a `Sandbox::execute`
call under a strict policy on a non-enforcing backend must return `Err(SandboxError::PolicyNotEnforceable)`,
not proceed silently. This is a BC candidate for Phase-2.

---

### NE-02 — String-only workspace path safety (symlink escape)

**Source:** P-65.
**Finding:** `validate_relative_path` does pure string-depth tracking (counts `..` segments).
Never touches the filesystem; no `canonicalize`, no symlink resolution, no `openat2 RESOLVE_BENEATH`.
A symlink that lives inside the workspace but resolves outside it passes validation cleanly.

**Ferrochain requirement (Domain C / VP candidate):**
All workspace file operations must resolve the real path (canonicalize, verify beneath root)
at access time, not only string-validate the requested path. A VP should assert that no
file operation can observe content outside the declared workspace root regardless of symlink
structure. The implementation should use `canonicalize_beneath_root(base, path) -> Result<PathBuf>`
and refuse if the canonical path escapes.

---

### NE-03 — Skill coordinator strict-mode silently swallows validation errors

**Source:** P-87.
**Finding:** `ContextCoordinator::build_context` in strict mode calls `try_resolve` which
returns `SkillError::Validation` listing missing tools, then maps that error via `Err(_) => continue`
— the error is swallowed and the coordinator tries the next candidate. Final return: `None`.
A caller receives `None` and cannot distinguish "no skill matched the query" from "the best-
ranked skill matched but its required tools are not registered." Permissive mode silently omits
missing tools from `active_tools` without surfacing which tools were dropped.

**Ferrochain requirement:**
Skill/context resolution failures must propagate with structured cause. No `Err(_) => continue`
swallowing on a validation error. Strict mode must return `Err(SkillError::ValidationFailed { skill,
missing_tools })` — callable code that detects the gap and can surface it upstream (e.g. as a
BC violation or a monitoring alert). Silent omission of required tools in permissive mode must
at minimum emit a structured warning with the tool names.

---

### NE-04 — Outbound reqwest clients without timeout (systemic, 8+ call sites)

**Source:** P-42 (server cluster), P-77 (provider cluster), P-91 (avatar constructors), P-94 (a2a-v1).
**Finding:** Every `reqwest::Client::new()` in the corpus (8 sites in server cluster alone, plus
provider adapter clients, avatar constructors, A2A client) is built without `.timeout()`.
The sole exception is `adk-anthropic`'s main HTTP client (DEFAULT_TIMEOUT + pool_idle_timeout +
tcp_keepalive), which proves the team knows the pattern. The a2a-v1 client's timeout-retry branch
is effectively dormant because no client-side read timeout fires (P-94). A hung external endpoint
(webhook receiver, JWKS server, remote A2A agent, LLM provider) blocks the calling task
indefinitely.

**Ferrochain requirement (CLAUDE.md mandatory convention):**
Every outbound `reqwest::ClientBuilder` in ferrochain MUST call `.timeout(Duration::from_secs(30))`
(or an NFR-documented override). This applies to: provider HTTP clients, server-side push/JWKS/
OIDC/remote-agent clients, and any future webhook senders. Use the `adk-anthropic` main client
(timeout + pool_max_idle + pool_idle_timeout + tcp_keepalive) as the positive reference.
This is a lint/CI gate candidate: `grep -rn "Client::new()" --include="*.rs" ferrochain-*/src/`
should produce zero results outside test files.

---

### NE-05 — Cache-key proxy using description instead of resolved instruction hash

**Source:** P-17.
**Finding:** The runner's context-cache keys on `agent.description()` as a "reasonable proxy"
(source comment) for the resolved system instruction, and caches with `tools = HashMap::new()`.
The full instruction is computed inside the agent and is not available at the runner's cache-key
boundary. Two agents with identical descriptions but different resolved instructions/tools can
collide. A changed instruction under a stable description serves a stale cache.

**Ferrochain requirement:**
Prompt cache keys must be computed from a hash of the RESOLVED (instruction bytes, sorted tools
set). If the instruction is not available at the cache-key site, compute it eagerly or derive
the key from the canonical inputs that would produce the same instruction. No description-proxy
cache keys. A test should assert that two agents with identical descriptions but different
instructions produce different cache keys (VP candidate).

---

### NE-06 — Guardrails cover only user-input and model-output paths; tool/RAG/memory ingress is unguarded

**Source:** P-59.
**Finding:** Built-in guardrails run at two points: `apply_input_guardrails` on `ctx.user_content()`
BEFORE the first model call; `apply_output_guardrails` on each generated content event. Tool
results, RAG/retrieval output, and memory content entering the model context are NEVER passed
through any guardrail. The built-in `ContentFilter` is a six-word keyword blocklist (trivially
bypassed by synonyms/encoding). No prompt-injection detection, no semantic classification.

**Ferrochain requirement (Domain A — BC/holdout candidate):**
Content entering the model context from UNTRUSTED sources (tool results, RAG output, external
memory entries) must be tagged by provenance and validated at INGRESS. Ferrochain's content-
validation hook must fire on tool-result ingress, not only on user-input + model-output. Keyword
blocklists are not a security control; they are a UX convenience. Domain A holdout scenario
must assert that indirect prompt injection via a tool result does not bypass ferrochain's
content validation.

---

### NE-07 — `.expect()` panic in a library constructor (WASM engine init)

**Source:** P-66.
**Finding:** `WasmBackend::new()` calls `Engine::new(&config).expect("failed to create wasmtime
engine …")` and implements `Default` via `WasmBackend::new()`. A bad configuration or
platform-incompatible WASM engine panics the process rather than returning a `Result`.

**Ferrochain requirement (CLAUDE.md no-unwrap/expect in non-test code):**
All ferrochain library constructors must return `Result`. `WasmBackend::new() -> Result<Self,
SandboxError>`. The `Default` impl must NOT delegate to a fallible constructor. This is a CI-
enforceable rule (clippy `manual_unwrap_or_default` + custom deny-expect-in-lib lint).

---

### NE-08 — Hard-wired in-memory idempotency map and rate-limit buckets (no durability seam)

**Source:** P-43.
**Finding:** The A2A idempotency map (`messageId → taskId`), rate-limit token buckets (`caller_id →
bucket`), and background `RunStore` are all `RwLock<HashMap<..>>` with no persistence trait.
Idempotency and INPUT_REQUIRED resume break silently on process restart (no durable state →
the same `messageId` creates a NEW task after restart). Rate-limit buckets never evict → slow
O(unique callers) memory leak in long-running servers.

**Ferrochain requirement (Domain B — multi-day durable runs):**
Idempotency state, rate-limit state, and run/task state must each be backed by a durable
trait (e.g. `IdempotencyStore`, `RateLimitStore`, `RunStore`) with in-memory as one
implementation. The durable-backed implementations must be first-class in ferrochain-server
v1, not optional extensions. LRU eviction with a TTL must be the default for in-memory
idempotency and rate-limit stores. adk-rust's hard-wired maps are a direct counter-example.

---

### NE-09 — Per-tool retry bound keyed by args-hash; no effective global bound by default

**Source:** P-63.
**Finding:** `after_tool_call` retry counter key is `"{tool_name}:{hash(args)}"`. The reflection
prompt instructs the model to retry with DIFFERENT arguments. A self-correcting agent that
changes args each attempt produces a new hash → counter resets to 0 → `effective_limit` (default 3)
is never reached. `global_limit: None` default means no fallback global bound. The per-tool
limit is effectively unbounded under the plugin's own intended usage pattern.

**Ferrochain requirement:**
Tool-retry/reflection bounds must be keyed on `(tool_name)` or `(tool_name, call_site)` — NOT
on argument content. A finite `global_limit` must be a non-None default (recommended: 15 or
configurable via TOML). A runaway-protection circuit-breaker must be ON by default with a
sensible max_invocation_total. A property test should assert that a simulated self-correcting
agent (changing args each call) terminates within the configured bound.

---

### NE-10 — Workspace-wide bare-String Debug-derived API keys (credential leak surface)

**Source:** P-76, P-44.
**Finding:** Every provider config in adk-rust (adk-model, adk-anthropic, adk-gemini, adk-auth)
uses `#[derive(Debug, Clone, Serialize, Deserialize)] pub api_key: String`. Several also derive
`Serialize`, serializing the key to JSON. `SecretProvider::get_secret` returns a bare `String`.
`{:?}` formatting prints the key in full. Any span/error/log capture that includes the config
struct leaks the credential.

**Ferrochain requirement (CLAUDE.md "Newtype + redacted Debug for credentials"):**
Every API key type in ferrochain MUST be a newtype with:
- `impl Debug for AnthropicApiKey { fn fmt(&self, f: &mut Formatter) -> Result { write!(f, "<redacted>") } }`
- NO `#[derive(Serialize)]` on the newtype (keys are NEVER serialized to wire/log/span).
- `impl From<String>` for construction; `impl Deref<Target=str>` blocked (prevents accidental use
  as a plain string argument).
adk-rust is the workspace-wide counter-example for this requirement.

---

### NE-11 — Encryption covers only session STATE, not event content; rotation errors swallowed

**Source:** P-32.
**Finding:** `EncryptedSession` encrypts only the state map (`__encrypted_state` key). `append_event`
and `list` delegate straight through — event payloads (LLM responses, tool calls, conversation
content) are stored PLAINTEXT. Lazy re-encryption on read is `let _ = self.inner.create(update_req).await`
— errors silently discarded.

**Ferrochain requirement (security/NFR):**
Ferrochain's at-rest encryption wrapper must encrypt BOTH state AND event payloads. "Encryption
at rest" that leaves conversation content cleartext is a partial guarantee that violates the
spirit of the control. Key-rotation re-encryption errors must propagate (never `let _ = ...`);
a rotation failure is a storage-integrity signal that must be surfaced. Both boundaries are VP
candidates.

---

### NE-12 — Identity triple collapsed to bare session_id at the append boundary

**Source:** P-34.
**Finding:** `SessionService::append_event_for_identity` default impl narrows the `(app_name,
user_id, session_id)` triple to `self.append_event(req.identity.session_id.as_ref(), req.event)`.
Backends that do not override receive a single-key lookup; SQL backends rely on a runtime
"ambiguous session_id" error check as the cross-tenant guard. The typed-identity investment
(P-06, STRONG) is undercut at the most critical write boundary.

**Ferrochain requirement (session tenancy invariant):**
Triple-addressed session operations (app_name × user_id × session_id) must be the ONLY path
for append, get, and delete. No default-to-bare-session_id fallback. The triple must flow from
the trait method signature to the SQL `WHERE` clause; the tenancy invariant must be a VP with
a Kani proof harness asserting that the three-part key uniquely partitions session rows.

---

### NE-13 — Streaming run endpoint is a behavioral stub (task-states only, no engine invocation)

**Source:** P-41.
**Finding:** `message_stream` in the A2A handler emits `Task → Working → Completed` status
transitions only, with the in-code comment "placeholder — Runner integration later." It does
NOT invoke the agent runner; the streaming transport produces zero model output. The unary
`message_send` path (which DOES invoke the runner) and the streaming path are behaviorally
non-equivalent — a split that makes the A2A streaming contract untrustworthy.

**Ferrochain requirement (ferrochain-server BC / Domain B holdout):**
Streaming and unary run endpoints MUST be behaviorally equivalent from day 1 — both drive the
same engine, both produce real model output. This is a non-negotiable BC; a placeholder-then-
wire-later pattern would break the holdout evaluation. A holdout scenario must assert that the
streaming endpoint produces the same final answer as the unary endpoint for an identical input.

---

### NE-14 — Permissive-by-default CORS and debug-trace exposure

**Source:** P-45.
**Finding:** `SecurityConfig::default()` leaves `allowed_origins` empty → `build_cors_layer`
maps to `AllowOrigin::any()`. Debug-trace route is exposed when `request_context_extractor.is_none()`
(no auth configured) OR `expose_admin_debug` is set. The `default()` constructor is dev-shaped;
`::production(...)` exists but is not the default.

**Ferrochain requirement (ferrochain-server security posture):**
`SecurityConfig::default()` must be secure: `allowed_origins` empty → CORS DENIED (not any).
Debug/trace/admin endpoints must NEVER be exposed by default; they require an explicit boolean
opt-in. The `::development()` preset can be permissive but must be visibly distinct from the
production default. A security-review gate at Phase 3 must assert that a default-configured
`ferrochain-server` returns 403 on debug routes and has no wildcard CORS.

---

### NE-15 — Eval multi-turn score merge is order-dependent; judge failure conflates with quality fail

**Source:** P-64.
**Finding:** Multi-turn score merge: `*s = (*s + score) / 2.0` — a running pairwise "average"
that weights later turns exponentially more. Three turns of scores 1.0/1.0/0.0 yield 0.25, not
the correct mean of 0.667. When the LLM judge call fails (API outage), code inserts score `0.0`
and `Verdict::Fail` — infrastructure failure is indistinguishable from agent-produced zero
quality.

**Ferrochain requirement (holdout harness / Domain B quality gates):**
(a) Multi-turn score aggregation must use arithmetic mean (Σscores / n), not a pairwise running
average. (b) Judge infrastructure failure (HTTP error, timeout, parse error) must produce a
third outcome `JudgeResult::InfraError { reason }` that is counted separately from
`Verdict::Fail` (quality zero). Aggregate metrics must show the infra-error count alongside the
pass/fail breakdown. (c) The agent must run exactly once per eval case; event streams must be
reused across scorers (no double-run).

---

### NE-16 — macOS Seatbelt sandbox is allow-by-default for file reads

**Source:** P-60.
**Finding:** The generated macOS Seatbelt profile uses `(allow default)` as the base, then
selectively denies `network*`, `file-write*` (re-allowing policy paths), and `process-fork`.
It never adds `(deny file-read*)`. Sandboxed untrusted code on macOS can read any file the
process user can access — SSH keys, `~/.aws/credentials`, browser cookies, `/etc/hosts`.

**Ferrochain requirement (Domain C macOS sandboxing):**
macOS sandbox profile must be deny-by-default (remove `(allow default)`, rely on `(deny default)`
as base, enumerate `(allow file-read* (subpath <allowed>))` for each permitted read path).
If the required allow-list is too large to be practical, ferrochain must document macOS as a
"no-isolation" platform for untrusted code execution and refuse to run untrusted code there
without an explicit override flag (`--allow-no-sandbox`). The asymmetry (Linux deny-by-default
reads via bubblewrap, macOS allow-all reads) must not exist silently.

---

### NE-17 — Nondeterministic reducer application order in concurrent super-steps

**Source:** P-28.
**Finding:** `execute_super_step` collects concurrent node outputs via
`stream::iter(futures).buffer_unordered(n).collect()`, which yields in COMPLETION ORDER.
`all_updates` is then folded through reducers in that order. For non-commutative reducers
(Append, custom fold) two runs of the same graph with the same inputs but different task
durations can produce different output lists. No task-path sort, no `InvalidUpdateError`
on concurrent LastValue writes.

**Ferrochain requirement (VP candidate — determinism invariant):**
ferrochain-graph MUST apply writes in deterministic sorted order keyed on task identity (e.g.
`task_path_str` analog or a stable sort key derived from node name + trigger). This must be a
Kani/proptest VP: "for any set of concurrent node outputs, the final reduced state is identical
regardless of the order those outputs arrived." adk-rust's completion-order folding is the
explicit counter-example this VP protects against.

---

## Summary

| Section | Count | Top 5 by Stakes |
|---------|-------|-----------------|
| A — Cross-corpus conflicts | 10 | CONFLICT-1 (graph execution model), CONFLICT-2 (checkpoint durability), CONFLICT-3 (HITL interrupt/resume), CONFLICT-4 (logical clock ordering), CONFLICT-5 (streaming event taxonomy) |
| B — Negative evidence items | 17 | NE-04 (reqwest timeout systemic), NE-01 (sandbox defaults), NE-06 (guardrail input-only), NE-10 (credential bare-String), NE-08 (idempotency no durability seam) |

**Section A conflict count: 10**
**Section B negative-evidence item count: 17**

---

## Cross-cutting note for Part 4

One meta-pattern emerges from both sections: **adk-rust systematically separates declaration from
enforcement** (honest capabilities that don't force compliance, per-tool limits that don't bound,
strict policies on non-enforcing backends, truthful-disclaimer vs mandatory-precondition). This
is a coherent design philosophy — never fail silently, but also never refuse in advance. For
ferrochain's VSDD verification approach, the opposite choice is correct: declarations MUST be
enforced by construction (typestate builders, compile-time policy-backend binding, required trait
methods with no safe default). The positive patterns from Part 3 (P-01/P-04 error taxonomy,
P-23 write isolation, P-35–P-38 HTTP hygiene, P-50 reflection-injection, P-51 phantom-tool
prevention, P-52 priority plugin seam) are all declaration=enforcement wins. Where the two corpora
agree is in the Part-1/Part-2 strong-adopt column; where they diverge — especially on
graph execution model and durability — LangGraph is the behavioral reference and adk-rust is
the instructive counter-example.
