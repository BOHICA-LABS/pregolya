---
document_type: architecture-section
level: L3
section: module-decomposition
version: "1.10"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/module-criticality.md
input-hash: "0426dd1"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7, D12, D13, D17, D20]
changelog:
  - "1.10 (F-P92-02, 2026-07-17): budget definitions note extended — RunnableConfig (core::config, SS-01) gains budget_config: Option<BudgetConfig> per OPTION A adjudication (BC-2.10.004 PC6 / BC-2.10.003 PC7/TV-004). Parallel to the context_mutations addition in the self-improvement definitions note. No new module rows — BudgetConfig is already a pure-core type in core::budget; the field addition does not change core::config's module boundary or criticality tier."
  - "1.9 (F-P91-02 sibling sweep, 2026-07-17): update budget definitions note to include OnCeiling enum and BudgetConfig struct (both newly defined in interface-definitions.md v2.29); note now lists all six core::budget types: BudgetPolicy, PolicyDecision, OnCeiling, BudgetConfig, TokenUsage, RunContext."
  - "1.8 (provenance-fix-169/2026-07-17): remove .factory/STATE.md from inputs (not a genuine spec-content input; D-NNN decisions are baked-in stable facts per PO corpus adjudication)."
  - "1.7 (F-P72-04/ADR-013): correct mcp::server attribution from ADR-012 to ADR-013; ADR-012 contains no MCP server content."
  - "1.6 (D20/CAP-021+CAP-020): add mcp::server (MEDIUM) to ferrochain-mcp for CAP-021 MCP server role; add BC anchors note to ferrochain-mcp section; update ferrochain-memory BC anchors to BC-2.15.001–006 for CAP-020. Universe 34→35 (+mcp::server MEDIUM execution row, gate #25)."
  - "1.5 (D20/ADR-012): add ferrochain-core self-improvement definitions note (core::context_mutation + core::write_guard, definitions-only, no new rows per ADR-009 precedent); add memory::skills (MEDIUM) and memory::write_guard (HIGH) module rows to ferrochain-memory per ADR-012 placements. Universe 33→34 (+memory::write_guard HIGH execution row, gate #25)."
  - "1.4 (ADV-P1D-PASS-62): F-P62-01 add deny-anyhow-in-lib (ADR-010/NE-03/DI-014) and deny-description-cache-key (ADR-011/NE-05) to xtask inventory; add non-exhaustive qualifier citing behavioral-contracts/ as authoritative subcommand registry."
  - "1.3 (ADV-P1D-PASS-61): F-P61-01 add ferrochain-core budget definitions note per ADR-009 Option 3; qualify graph::budget row to clarify trait lives in core; rename BudgetContext → RunContext per pass-61 adjudication."
  - "1.2 (ADV-P1D-PASS-37): F-P37-01 reconcile criticality column drift against authoritative module-criticality.md — core::message CRITICAL→HIGH; graph::channels CRITICAL→HIGH; graph::event_emitter HIGH→MEDIUM; ferrochain-macros section heading MEDIUM→HIGH; macros::tool/entrypoint/task all MEDIUM→HIGH."
  - "1.1 (ADV-P1D-PASS-29): F-P29-04 correct core::events description from past-tense (RunStarted/Ended, NodeStarted/Ended) to imperative canon (RunStart/Stream/End, NodeStart/Stream/End) per BC-2.06.001 authority."
  - "1.0 (initial): base module decomposition authored."
---

# Module Decomposition: ferrochain

## [Section Content]

> Per the criticality classification in `.factory/specs/module-criticality.md`.
> This file maps subsystems to internal crate modules and their responsibilities.

## ferrochain-core (SS-01, SS-06, SS-14) — CRITICAL

Responsibilities: universal composition protocol, typed message model, error taxonomy,
credential security primitives, streaming event types.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `core::runnable` | `Runnable<I,O>` trait + `RunnableSequence` pipe combinator | HIGH | SS-01 |
| `core::message` | `Message` enum (AiMessage/HumanMessage/SystemMessage/ToolMessage), ContentBlock | HIGH | SS-01 |
| `core::error` | `FerrochainError` 2D struct (Component × Category), RFC-7807 emission | CRITICAL | SS-14 |
| `core::credentials` | API key newtypes with redacted Debug; no Serialize; no Deref<Target=str> | CRITICAL | SS-14 |
| `core::events` | Streaming event taxonomy types (RunStart/Stream/End, NodeStart/Stream/End, etc.) | HIGH | SS-06 |
| `core::config` | `RunnableConfig`, `ChatConfig` structs | MEDIUM | SS-01 |
| `core::retry` | `ToolRetryPolicy` (keyed by tool_name; P-71 ADOPT), `CircuitBreaker` state machine, `RetryPolicy` with finite `global_limit: Option<NonZeroU32>`; shared combinator — provider crates and graph both route through this | MEDIUM | SS-16 |

> **Budget definitions (SS-10, trait-definitions-only — ADR-009 Option 3):** ferrochain-core hosts
> the DEFINITIONS for budget governance: `BudgetPolicy` trait, `PolicyDecision` enum (Allow/Escalate/Deny),
> `OnCeiling` enum (Halt/Escalate/Summarize — BC-2.10.003 v1.2 + BC-2.10.004), `BudgetConfig` struct
> (soft_limit, hard_limit, on_ceiling — BC-2.10.001 TV-001–TV-003 + ADR-009), `TokenUsage` struct, and
> `RunContext` struct (fields: thread_id, run_id, sub-agent identity, budget_info per BC-2.10.001
> precondition 3). These are pure types with no execution logic — no criticality-counted module row
> is added (module universe remains 33; tier counts unchanged). The DISPATCH engine (`BudgetEngine`,
> `EvidenceJournal`) lives in ferrochain-graph::budget per the guardrail core-definitions/graph-dispatch
> split precedent. Module path: `ferrochain-core/src/budget.rs` (module `core::budget`).
> `RunnableConfig` (SS-01, `core::config`) gains `budget_config: Option<BudgetConfig>` — per-run
> budget override field (F-P92-02, OPTION A); `None` inherits `GraphConfig::budget_config`; `Some(bc)`
> overrides for that single run/resume. Used by `BudgetResume::Extend { new_ceiling }` to apply the
> extended ceiling without mutating the graph-level config (BC-2.10.004 PC6, BC-2.10.003 PC7/TV-004).

> **Self-improvement definitions (SS-01/SS-15, trait-definitions-only — ADR-012 D20):** ferrochain-core
> hosts DEFINITIONS for the three D20 self-improvement primitives. These are pure types and traits with
> no execution logic — no criticality-counted module rows are added for these definitions. Execution
> modules (`memory::skills`, `memory::write_guard`) live in ferrochain-memory per the
> definitions-in-core / enforcement-in-storage precedent.
>
> - `core::context_mutation` (`ferrochain-core/src/context_mutation.rs`): `ContextSourceSpec`
>   (namespace + key), `ContextMutationConfig` (Vec<ContextSourceSpec>). `RunnableConfig` (SS-01)
>   gains `context_mutations: Option<ContextMutationConfig>`. Loaded by `graph::scheduler` at run
>   start (frozen-snapshot semantics — context assembled once before first super-step; writes during
>   the run are visible at next run start only; preserves prompt-prefix caching per ADR-011/ADR-012
>   Decision 3).
>
> - `core::write_guard` (`ferrochain-core/src/write_guard.rs`): `MemoryWriteRequest` enum
>   (Add/Replace/Remove), `MemoryWriteGuard` trait (pure synchronous validation:
>   `fn validate(&self, req: &MemoryWriteRequest) -> WriteGuardDecision`), `WriteGuardDecision`
>   (Allow / Deny{reason} / Transform{sanitized}). This is the write-path analog to `GuardrailHook`
>   (ingress path). `BoundaryType` is NOT extended — write-path safety is a separate seam
>   (PASS-58 canon unchanged; BoundaryType = ToolResult|RAGRetrieval|MemoryIngress, 3 variants).

**NE anchors enforced:** NE-07 (constructor Result), NE-10 (credential opacity), NE-03 (no silent None)

## ferrochain-graph (SS-02, SS-03, SS-05, SS-10, SS-11) — CRITICAL

Responsibilities: StateGraph definition, BSP execution, HITL, budget governance,
content provenance.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `graph::definition` | `StateGraph` builder, node/edge registration, conditional routing | HIGH | SS-02 |
| `graph::channels` | LastValue / Append / BarrierValue / NamedBarrierValue / EphemeralValue reducers | HIGH | SS-02 |
| `graph::bsp_engine` | Super-step executor: task dispatch, versions_seen / task-identity sort, InvalidUpdateError | CRITICAL | SS-03 |
| `graph::hitl` | Interrupt queue (FIFO), suspend/resume protocol, risk-tiered classification | CRITICAL | SS-05 |
| `graph::scheduler` | Orchestrator loop and/or actor-scheduler (decision pending ADR-001 D9 gate) | CRITICAL | SS-03 |
| `graph::budget` | `BudgetEngine` dispatch (allow/escalate/deny via `BudgetPolicy` trait from ferrochain-core), `EvidenceJournal`, ceiling halt/escalate — trait definitions live in `core::budget` per ADR-009 Option 3 | HIGH | SS-10 |
| `graph::provenance` | `ProvenanceTag` attachment at ingress boundaries, `GuardrailHook` dispatch | HIGH | SS-11 |
| `graph::event_emitter` | Streaming event emission; run_id + parent_ids correlation | MEDIUM | SS-06 |

**VP anchor:** `graph::bsp_engine` is VP-001 target (BSP determinism Kani harness).

## ferrochain-checkpoint (SS-04) — CRITICAL

Responsibilities: durable per-task checkpointing, monotonic clock, fork lineage, encryption.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `checkpoint::saver` | `CheckpointSaver` trait + `put_writes` contract | CRITICAL | SS-04 |
| `checkpoint::session_index` | Triple-address (thread_id, checkpoint_ns, checkpoint_id) enforcement | CRITICAL | SS-04 |
| `checkpoint::clock` | Monotonic logical clock; rejects wall-clock UUIDs | CRITICAL | SS-04 |
| `checkpoint::lineage` | Fork via parent_checkpoint_id; no state copy on fork | HIGH | SS-04 |
| `checkpoint::encryption` | At-rest encryption covering state AND event payloads; rotation error propagation | CRITICAL | SS-04 |
| `checkpoint::sqlite` | SQLite backend (default Cargo feature `checkpoint-sqlite`) | MEDIUM | SS-04 |
| `checkpoint::memory` | In-memory backend for tests (`checkpoint-memory` feature) | MEDIUM | SS-04 |
| `checkpoint::postgres` | PostgreSQL backend (stretch; `checkpoint-postgres` feature) | MEDIUM | SS-04 |

**VP anchors:** `checkpoint::session_index` is VP-002 target (session tenancy Kani harness).

## ferrochain-server (SS-12) — HIGH

Responsibilities: Axum HTTP server, resource CRUD, cron scheduler, security defaults.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `server::handlers` | Thread/Assistant/Run/Schedule CRUD routes | HIGH | SS-12 |
| `server::security` | `SecurityConfig::default()` deny-CORS, debug route opt-in (DI-013) | HIGH | SS-12 |
| `server::streaming` | SSE streaming endpoint; same engine as unary (DI-011) | HIGH | SS-12 |
| `server::stores` | `IdempotencyStore` / `RateLimitStore` / `RunStore` trait seams (NE-08) | HIGH | SS-12 |
| `server::cron` | CronSchedule parsing and proactive run triggering | MEDIUM | SS-12 |

## ferrochain-sandbox (SS-13) — CRITICAL (path-guard) / MEDIUM (backends)

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `sandbox::path_guard` | `canonicalize_beneath_root(base, path)`; `Err(FerrochainError { code: "E-SBXD-001" })` on workspace escape | CRITICAL | SS-13 |
| `sandbox::wasm` | WASM execution backend (default `sandbox-wasm` feature) | MEDIUM | SS-13 |
| `sandbox::container` | Container execution backend (`sandbox-container` feature) | MEDIUM | SS-13 |
| `sandbox::seatbelt` | macOS Seatbelt deny-by-default profile (NE-16) | MEDIUM | SS-13 |
| `sandbox::policy` | `SandboxPolicy` enforcement; Err(PolicyNotEnforceable) on mismatch | MEDIUM | SS-13 |

**VP anchor:** `sandbox::path_guard` is VP-003 target (workspace confinement Kani harness).

## ferrochain-splitters (SS-07) — MEDIUM

| Module | Responsibility | Criticality |
|--------|---------------|-------------|
| `splitters::recursive` | Recursive character splitter; Unicode code-point boundary counting | MEDIUM |
| `splitters::parity` | Golden-vector parity tests vs Python reference (R8 Red Gate coverage) | MEDIUM |

## Provider Crates and Standard Tests (SS-08) — HIGH

Each provider is split into **two separate Cargo crates** per D17-Q5 / ADR-007 / BC-2.08.006:

| Crate | Role | ferrochain-core dep |
|-------|------|---------------------|
| `ferrochain-openai-sdk` | OpenAI wire client (HTTP, SSE, types) | NO |
| `ferrochain-openai` | `impl BaseChatModel` for ChatOpenAI; translation | YES |
| `ferrochain-anthropic-sdk` | Anthropic wire client | NO |
| `ferrochain-anthropic` | `impl BaseChatModel` for ChatAnthropic | YES |
| `ferrochain-ollama-sdk` | Ollama wire client | NO |
| `ferrochain-ollama` | `impl BaseChatModel` for ChatOllama (no API key newtype) | YES |
| `ferrochain-standard-tests` | Shared conformance test suite; all adapter crates as dev-dep | YES |

The SDK crates have no ferrochain-core dep and are publishable standalone. Enforced by CI:
`cargo check -p ferrochain-<provider>-sdk` must succeed without ferrochain-core in Cargo.lock.

## ferrochain-mcp (SS-09) — MEDIUM

| Module | Responsibility | Criticality |
|--------|---------------|-------------|
| `mcp::client` | `MultiServerMcpClient`; no live connections until invoke (R11) | MEDIUM |
| `mcp::discovery` | Tool discovery and registration from MCP server at runtime | MEDIUM |
| `mcp::adapter` | `ToolInvocation` routing; ToolException re-raise with type identity (R11) | MEDIUM |
| `mcp::ingress` | Untrusted-ingress routing; DI-012 guardrail seam | MEDIUM |
| `mcp::server` | MCP server endpoint: exposes registered tools to external MCP clients; accepts inbound tool-call requests, dispatches to registered tools, and returns serialized responses (CAP-021/D20/ADR-013) | MEDIUM |

**BC anchors:** BC-2.09.001–007 (CAP-021: BCs 006–007 cover server-side tool exposure and response serialization contracts).

**VP anchors:** `mcp::adapter` is VP-004 target; `mcp::client` is VP-005 target (both integration-tier, Phase 3).

## ferrochain-memory (SS-15) — MEDIUM

Responsibilities: long-horizon memory persistence (KV + vector), GDPR erasure protocol,
search (keyword / vector / hybrid). Canonical trait: `MemoryStore`.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `memory::store` | `MemoryStore` trait (KV + vector ops, GDPR erasure) | MEDIUM | SS-15 |
| `memory::sqlite` | SQLite durable backend implementation | MEDIUM | SS-15 |
| `memory::in_memory` | Ephemeral in-memory backend (test/dev) | MEDIUM | SS-15 |
| `memory::search` | Keyword, vector, and hybrid search implementations | MEDIUM | SS-15 |
| `memory::skills` | `SkillStore` trait + `SkillDescriptor`; routing/discovery overlay over `MemoryStore` KV; load-on-demand skill documents by name/tags (D20/ADR-012) | MEDIUM | SS-15 |
| `memory::write_guard` | Guarded write enforcement engine: calls `MemoryWriteGuard::validate()` (from `core::write_guard`) before committing writes; injection scanning dispatch; blocks or sanitizes writes per `WriteGuardDecision`; security-significant write-path seam (D20/ADR-012) | HIGH | SS-15 |

**BC anchors:** BC-2.15.001–006 (CAP-020: BCs 004–006 cover self-improvement primitives — `SkillStore` routing overlay, `MemoryWriteGuard` execution enforcement, and `ContextMutationConfig` assembly). Canonical trait name: `MemoryStore` per BC-2.15.001 Architecture Anchors.

> **Self-improvement execution note (D20/ADR-012):** `memory::skills` provides `SkillStore`
> trait + `SkillDescriptor` types as a routing overlay over `MemoryStore`. Skill documents are
> ordinary KV entries under a skills namespace; `SkillStore` adds naming, tagging, and
> load-on-demand semantics. Write path for skill documents passes through `memory::write_guard`
> (guarded write enforcement). `memory::write_guard` is the execution counterpart of
> `core::write_guard` (definitions-only, ferrochain-core) — same split as ADR-009 Option 3
> (BudgetPolicy trait in core / BudgetEngine dispatch in graph). Universe updated to 34 (gate #25):
> +1 HIGH execution row (`memory::write_guard`); definitions-only entries (`core::context_mutation`,
> `core::write_guard`) and routing-overlay entry (`memory::skills`) follow the no-criticality-row
> precedent — `memory::skills` has a structural decomposition row here but no criticality-counted
> row (ADR-012 Decision 4). Universe further updated to 35 in v1.6 (gate #25): +1 MEDIUM execution
> row (`mcp::server`, CAP-021/D20/ADR-013).

## ferrochain-macros (ADR-008) — HIGH

Responsibilities: proc-macro crate for `#[tool]`, `#[entrypoint]`, `#[task]`.
Re-exported from ferrochain-core.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `macros::tool` | `#[tool]` proc-macro: `Tool` implementor with JSON Schema derivation | HIGH | SS-08 |
| `macros::entrypoint` | `#[entrypoint]` proc-macro: START edge wiring for StateGraph nodes | HIGH | SS-08 |
| `macros::task` | `#[task]` proc-macro: task registration boilerplate | HIGH | SS-08 |

**BC anchors:** BC-2.08.010, BC-2.08.011, BC-2.08.012 (all active, authored Phase 1b).

## xtask (SS-17 support) — LOW

> **Inventory scope (non-exhaustive):** This list covers subcommands explicitly cited in
> architecture/ ADRs and the NE Disposition Table (PRD §9) as sole enforcement mechanisms.
> The authoritative registry for all CI lint gate contracts — including exact subcommand
> names and their acceptance criteria — is the behavioral-contracts/ directory
> (BC-2.14.003–006, BC-2.08.007) and individual ADRs. Naming variants across sources
> (e.g. `deny-expect-in-lib` / `lint-no-panic` for the same NE-07 gate) are resolved at
> implementation time against the governing BC or ADR, not this inventory.

- `check-file-size`: file line-count gate (D12); reads allowlist.toml
- `deny-client-new`: CI lint gate; rejects `Client::new()` outside tests (NE-04)
- `deny-expect-in-lib`: CI lint gate; rejects `.expect()` and `.unwrap()` in library code (NE-07)
- `deny-anyhow-in-lib`: CI lint gate; scans library crate `src/` for `anyhow` imports; sole enforcement of NE-03 / DI-014 anyhow confinement — `anyhow` is banned from all `ferrochain-*` library crates (ADR-010)
- `deny-description-cache-key`: CI lint gate; scans `cache_key` / `CacheKey` / `cache_key_for` call sites in `ferrochain-*` library crates for description-proxy usage; sole enforcement of NE-05 content-hash cache-key contract (ADR-011)
