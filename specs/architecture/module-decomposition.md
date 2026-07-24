---
document_type: architecture-section
level: L3
section: module-decomposition
version: "1.23"
status: active
producer: architect
timestamp: 2026-07-24T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/module-criticality.md
input-hash: "1f22e52"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7, D12, D13, D17, D20, D21, D23]
changelog:
  - "1.23 (FIX-BURST-252/2026-07-24): F-P151-01/02/05 compaction type-canon corrections. (1) core::budget row: `fraction: f32` → `fraction: f64` in check_watermark_trigger signature (F-P151-05). (2) D23 compaction additions note: `OnWatermark{fraction: f32}` → `OnWatermark{fraction: f64}` (F-P151-05); `CompactionSummary struct (summary_text: String, compacted_range: RangeInclusive<usize>)` → `(summary_text: String, compacted_start: usize, compacted_end: usize)` (F-P151-02 flat-fields adjudication). No module-universe count change."
  - "1.22 (burst-244/2026-07-23): F-P144-01/F-P144-02 — (1) ferrochain-tools section header MEDIUM → HIGH (tools-shell) / MEDIUM (tools-fs, tools-search); tools::shell module row MEDIUM → HIGH (VP-013 Kani P1; aligns with verification-coverage-matrix.md and module-criticality.md v1.6 adjudication). (2) Add core::budget module row to ferrochain-core base table (HIGH, VP-012 Kani P1, SS-10); update budget definitions note to remove stale no-row / no-execution-logic claim (core::budget now hosts check_watermark_trigger pure-core function, not only type definitions). Module universe 54→55 (+core::budget row)."
  - "1.21 (burst-240/2026-07-23): F-P140-01 layout-adjudication clarifications — expand four ferrochain-graph module row descriptions to make the canonical flat-layout file-path mapping unambiguous for BC sweep. (1) graph::bsp_engine: add WriteRecord/PregelTask types, reduce_super_step pure-function callout (VP-001 Kani target), apply_writes callout, ferrochain-graph/src/bsp_engine.rs path. (2) graph::scheduler: add orchestrator state-machine transition sequence, ExecutionContext {run_id, parent_ids} (propagated into nested invocations), CompiledGraph::run() entry point, ferrochain-graph/src/scheduler.rs path. (3) graph::event_emitter: explicitly name StreamEvent enum and tick/after_tick emission callsites, ferrochain-graph/src/event_emitter.rs path. (4) graph::hitl: add per-task interrupt bookkeeping (InterruptScratchpad, interrupt_counter) alongside interrupt queue, ferrochain-graph/src/hitl.rs path. Architecture-doc pregel Rust-path sweep: 0 stale pregel/ paths found in architecture/ layer; no architecture-doc changes required beyond this entry."
  - "1.20 (burst-238/2026-07-23): Stale-handoff sweep (continuation) — fix graph::scheduler description: remove stale '(decision pending ADR-001 D9 gate)' note; D9 gate passed 2026-07-14, Alternative B selected per D11.1 steering (ADR-001); update description to 'Outer orchestrator loop + actor-scheduler synthesis (ADR-001 Alternative B, D9 gate passed 2026-07-14)'."
  - "1.19 (burst-238/2026-07-23): Stale-handoff sweep — (1) Fix VP-010 label in core::serializable criticality note: 'VP-010 candidate' → 'VP-010 (Kani P0, seeded burst-223)'; VP-010 was seeded in burst-223 (D21, VP-INDEX v1.2). (2) Fix VP-006 label in prompts::injection_guard criticality note: 'VP-006 candidate' → 'VP-006 (Kani P1, seeded burst-223)'. (3) Fix stale BC-2.18.001–TBD anchor in prompts BC anchors note → BC-2.18.001–005 (BCs authored in D21 burst). (4) Fix stale BC-2.20.001–TBD / BC-2.21.001–TBD in vectorstores BC anchors note → BC-2.20.001–003 (Retriever) / BC-2.21.001–004 (VectorStore) (BCs authored in D21 burst)."
  - "1.18 (burst-235/F-P135-05/2026-07-22): Add missing `sandbox::process` module row to ferrochain-sandbox (SS-13) section — ProcessBackend is a full behavioral contract (BC-2.13.002) and must appear in module-decomposition per Iron Law. Module is MEDIUM criticality (Effectful Shell; explicitly non-default, opt-in only via `unsafe_process_no_isolation()`). DI-015 co-enforcement note added: ProcessBackend enforces subprocess timeout at the sandbox layer via `.kill_on_drop(true)` (defense-in-depth beneath BashTool's outer `tokio::time::timeout`). Module universe 53→54."
  - "1.17 (burst-234/2026-07-22): TD-VSDD-060 sibling sweep — update SS-23 E-TOOLS-* count note: '8 codes post-burst-233' → '9 codes post-burst-234'; add E-TOOLS-009 InvalidRegexPattern to cite. Input-hash refresh for upstream prd.md drift."
  - "1.16 (burst-233/2026-07-22): F-P133-07 — fix SS-23 VP anchor block: VP-011 corrected from 'candidate (Kani P0) graph::hitl' to 'VP-011 (Kani P0, seeded burst-232)'; VP-012 corrected from 'candidate (integration P1) interrupt/resume' to 'VP-012 (Kani P1, seeded burst-232) — OnWatermark arithmetic, BC-2.10.005, ferrochain-core, ADR-019'; VP-013 corrected from 'candidate (Kani P0)' to 'VP-013 (Kani P1, seeded burst-232)'. F-P133-08 — fix similar crate attribution: 'dtolnay' → 'mitsuhiko'; 'MIT/Apache-2.0' → 'Apache-2.0 single-licensed'; section renamed 'Dependency research flags' → 'Validated external dependencies'; both deps marked as confirmed (ADR-020 Decision 7 v1.1). BC anchors updated to reflect SS-23 BCs as authored (BC-2.23.001..006)."
  - "1.15 (D23/2026-07-22): Add ferrochain-tools crate #21 section (SS-23): tools::fs, tools::shell, tools::search (all MEDIUM). Extend graph::hitl row for ADR-018 PreToolCallHook types. Extend core::budget definitions note for D23 compaction types (CompactionTrigger, CompactionPolicy, ConversationSnapshot, CompactionSummary — ADR-019). Extend graph::budget row for compaction engine dispatch. Note Wave 1 promotions: core::retry (SS-16) and ferrochain-memory (SS-15) per D23 items 3+4. Module universe 50→53 (+tools::fs +tools::shell +tools::search; definitions-only additions follow no-criticality-row precedent per ADR-009)."
  - "1.14 (burst-226/2026-07-21): F-P131-05 sibling sweep — prompts::injection_guard row: replace 'untrusted ProvenanceTag in TrustRequired slot' with 'TrustLevel::Untrusted in TrustRequired slot'; add note that TrustLevel is SS-18-local type distinct from core::guardrail::ProvenanceTag (SS-11) per ADR-015 v1.3 adjudication."
  - "1.13 (burst-225/2026-07-21): F-P130-01 sibling sweep — correct core::guardrail comment block: GuardrailHook method updated from wrong sync `fn check` to canonical `async fn evaluate` per interface-definitions.md §GuardrailHook; full type list (GuardrailHook, GuardrailResult, IngressContent, GuardrailSeverity, BoundaryType); rag_ingress note updated: async per-document evaluate calls per BC-2.11.003 PC5."
  - "1.12 (burst-224/2026-07-21): F-P129-11 — add vectorstores::similarity module (shared cosine_similarity primitive, VP-009 Kani target); update vectorstores::mmr description to MMR-selection-only (no longer hosts cosine_similarity); update VP anchors note. F-P129-09 — add core::guardrail definitions module (GuardrailHook trait + BoundaryType enum, promoted to ferrochain-core consistent with trait-in-core precedent); add GuardedDocuments type note to core::retriever (rag_ingress enforcement gate). Module universe 49→50 (+vectorstores::similarity MEDIUM; core::guardrail definitions-only, no criticality row per ADR-009 precedent)."
  - "1.11 (D21/2026-07-20): ecosystem-parity scope expansion — add ferrochain-prompts section (SS-18: prompts::template, prompts::chat_template, prompts::few_shot, prompts::injection_guard); add ferrochain-vectorstores section (SS-20/SS-21: vectorstores::store, vectorstores::retriever, vectorstores::memory, vectorstores::mmr); add ferrochain-core new modules: core::documents, core::retriever, core::embeddings, core::serializable; add provider embedding modules in ferrochain-openai (openai::embeddings) and ferrochain-ollama (ollama::embeddings); ferrochain-anthropic explicitly excluded from SS-22 (no embedding API). Module universe 35→49 (+14 criticality-counted rows: 4 in ferrochain-core, 4 in ferrochain-prompts, 4 in ferrochain-vectorstores, 2 in provider crates). ADRs: ADR-014/015/016/017."
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
| `core::retry` | `ToolRetryPolicy` (keyed by tool_name; P-71 ADOPT), `CircuitBreaker` state machine, `RetryPolicy` with finite `global_limit: Option<NonZeroU32>`; shared combinator — provider crates and graph both route through this; **D23 item 4 (CAP-018): promoted from Wave 2 → Wave 1** | MEDIUM | SS-16 |
| `core::budget` | VP-012 Kani P1 target: pure-core `check_watermark_trigger(tokens_remaining: u64, ceiling: u64, fraction: f64) -> bool` (BC-2.10.005 watermark arithmetic — seeded burst-232; f64 precision per FIX-BURST-252 adjudication); type definitions: `BudgetPolicy` trait, `PolicyDecision` enum, `OnCeiling` enum, `BudgetConfig` struct, `TokenUsage` struct, `RunContext` struct (SS-10/ADR-009), `CompactionTrigger` enum, `CompactionPolicy` trait, `ConversationSnapshot` struct, `CompactionSummary` struct (D23/ADR-019); dispatch engine lives in `graph::budget` (ferrochain-graph); module path: `ferrochain-core/src/budget.rs` | HIGH | SS-10 |

> **Budget definitions (SS-10 — VP-012 elevation — ADR-009 Option 3):** ferrochain-core hosts
> the DEFINITIONS for budget governance: `BudgetPolicy` trait, `PolicyDecision` enum (Allow/Escalate/Deny),
> `OnCeiling` enum (Halt/Escalate/Summarize — BC-2.10.003 v1.2 + BC-2.10.004), `BudgetConfig` struct
> (soft_limit, hard_limit, on_ceiling — BC-2.10.001 TV-001–TV-003 + ADR-009), `TokenUsage` struct, and
> `RunContext` struct (fields: thread_id, run_id, sub-agent identity, budget_info per BC-2.10.001
> precondition 3). **F-P144-02 adjudication (burst-244):** `core::budget` has been elevated from definitions-only to HIGH criticality — VP-012 (Kani P1, seeded burst-232) requires `check_watermark_trigger` to live here as an executable pure-core function, not only type definitions. A criticality-counted module row now appears in the table above. The DISPATCH engine (`BudgetEngine`,
> `EvidenceJournal`) lives in ferrochain-graph::budget per the guardrail core-definitions/graph-dispatch
> split precedent. Module path: `ferrochain-core/src/budget.rs` (module `core::budget`).
> `RunnableConfig` (SS-01, `core::config`) gains `budget_config: Option<BudgetConfig>` — per-run
> budget override field (F-P92-02, OPTION A); `None` inherits `GraphConfig::budget_config`; `Some(bc)`
> overrides for that single run/resume. Used by `BudgetResume::Extend { new_ceiling }` to apply the
> extended ceiling without mutating the graph-level config (BC-2.10.004 PC6, BC-2.10.003 PC7/TV-004).
>
> **D23 compaction additions (ADR-019):** `core::budget` gains four new definitions-only types:
> `CompactionTrigger` enum (Disabled/OnWatermark{fraction: f64}/OnMessageCount{count: usize}/OnTokenCount{tokens: u64}),
> `CompactionPolicy` trait (async `compact(&ConversationSnapshot, &RunContext) -> Result<CompactionSummary, FerrochainError>`),
> `ConversationSnapshot` struct (turns: Vec<(usize, Message)>, token_estimate: u64), and `CompactionSummary`
> struct (summary_text: String, compacted_start: usize, compacted_end: usize). All definitions-only; execution
> lives in `graph::budget` (compaction engine). `BudgetConfig` gains two new fields:
> `compaction_trigger: CompactionTrigger` (default: Disabled) and
> `compaction_policy: Option<Arc<dyn CompactionPolicy>>` (None = DefaultSummarizationPolicy). No new
> criticality-counted module rows (definitions-only precedent per ADR-009 Option 3).

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
| `graph::bsp_engine` | Super-step executor: task dispatch, `versions_seen` map, task-identity sort (`sort_by_task_id`), `reduce_super_step` (VP-001 pure-function Kani target), `apply_writes`, `InvalidUpdateError`; task-identity types: `WriteRecord { task_id, channel_name, value }`, `PregelTask`; `_reapply_writes_to_succeeded_nodes`; super-step-end `finish()` dispatch on channels (`ferrochain-graph/src/bsp_engine.rs`) | CRITICAL | SS-03 |
| `graph::hitl` | Interrupt queue (FIFO), suspend/resume protocol, risk-tiered classification; per-task interrupt bookkeeping: `InterruptScratchpad`, `interrupt_counter` (per-task resume-slot index); `PreToolCallHook` trait + `ToolCallPreview` + `PreToolDecision` (Approve/Deny/Edit/PendingHumanApproval) + `ToolApprovalRequest` + `AlwaysApprovePolicy` (ADR-018); `pre_tool_dispatch` routing function — fail-closed Deny invariant (VP-011, Kani P0, seeded burst-232); `GraphConfig.pre_tool_hook: Option<Arc<dyn PreToolCallHook>>` hook registration (`ferrochain-graph/src/hitl.rs`) | CRITICAL | SS-05 |
| `graph::scheduler` | Outer orchestrator loop + actor-scheduler synthesis (ADR-001 Alternative B; D9 gate passed 2026-07-14); orchestrator state machine (`Idle→Dispatching→Collecting→Reducing→Checkpointing→Idle`); actor scheduler (Tokio MPSC, `Dispatch(task_id, future)` / `Completed(task_id, output)` messages); `ExecutionContext { run_id: Uuid, parent_ids: Vec<Uuid> }` propagated into nested invocations; `CompiledGraph::run()` top-level entry point; tick() Collecting phase: LLM-call / tool-invocation evaluation callsites for budget and UntrackedValue sanitization (`ferrochain-graph/src/scheduler.rs`) | CRITICAL | SS-03 |
| `graph::budget` | `BudgetEngine` dispatch (allow/escalate/deny via `BudgetPolicy` trait from ferrochain-core), `EvidenceJournal`, ceiling halt/escalate — trait definitions live in `core::budget` per ADR-009 Option 3; compaction engine: evaluates `CompactionTrigger` after each super-step, builds `ConversationSnapshot` via `CheckpointSaver::search_history` (BC-2.04.008), calls `CompactionPolicy::compact()`, applies mid-run message-window mutation, appends `CompactionEvent` to `EvidenceJournal`, emits `compaction_event` streaming event (ADR-019) | HIGH | SS-10 |
| `graph::provenance` | `ProvenanceTag` attachment at ingress boundaries, `GuardrailHook` dispatch | HIGH | SS-11 |
| `graph::event_emitter` | `StreamEvent` enum (RunStart/Stream/End, NodeStart/End, ToolStart/End, StepEnd); streaming event emission — emission callsites inside `tick()` (NodeStart/End, ToolStart/End) and `after_tick()` (StepEnd) are in `graph::scheduler`; run_id + parent_ids correlation; `StreamEvent` base fields: `run_id: Uuid`, `parent_ids: Vec<Uuid>` (`ferrochain-graph/src/event_emitter.rs`) | MEDIUM | SS-06 |

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
| `sandbox::process` | `ProcessBackend` — explicit non-default OS process execution; only accessible via `Sandbox::unsafe_process_no_isolation()`; provides `env_clear()` + wall-clock timeout (`tokio::process::Command` with `.kill_on_drop(true)`); WARN log on every `execute()` call; `BackendCapabilities { filesystem_isolated: false, network_isolated: false, memory_bounded: false }`; DI-015 co-enforcer at sandbox layer via `.kill_on_drop(true)` — ensures subprocess is killed on Future drop when BashTool's outer `tokio::time::timeout` fires (BC-2.13.002 / SS-13) | MEDIUM | SS-13 |
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
**D23 item 3 (CAP-017): promoted from Wave 2 → Wave 1.**

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

## ferrochain-core — D21 additions (SS-19, SS-20, SS-22)

> **New modules added in D21.** These extend ferrochain-core without adding new Cargo
> dependencies beyond `inventory` (for `core::serializable` registry) and `async-trait`
> (already present for existing async traits).

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `core::documents` | `Document { page_content, metadata, id }` type — carrier for all retrieval output; derives Serialize/Deserialize/JsonSchema; #[non_exhaustive] | MEDIUM | SS-20 |
| `core::retriever` | `Retriever` trait: async dyn-compatible `get_relevant_documents(&self, query: &str)`; `Arc<dyn Retriever>` seam for graph RAG nodes; `GuardedDocuments` newtype (no public constructor) + `GuardedDocuments::rag_ingress(docs, guardrail)` sole constructor enforcing DI-012 RAGRetrieval guardrail at call time (ADR-014 Decision 6) | MEDIUM | SS-20 |
| `core::embeddings` | `Embeddings` trait: async dyn-compatible `embed_documents` + `embed_query`; dimensionality contract (E-EMBED-001 on mismatch); no `ndarray` dep | MEDIUM | SS-22 |
| `core::serializable` | `LcSerializable` trait + `Serialized` wire enum + `Reviver` + `inventory`-based static registry (141 core entries); valid-namespace `OnceLock<HashSet>` derived from registry; E-SRLZ-001/002 error codes | HIGH | SS-19 |

> **core::serializable criticality (HIGH):** deserialization of external lc-JSON blobs is a
> security-sensitive surface (R12). The Reviver enforces an allowlist-by-registration safety
> property and must be formally tested for allowlist containment (VP-010 (Kani P0, seeded burst-223)). HIGH tier
> matches the security significance and cross-cutting nature of lc-JSON round-trip support.

> **NE anchors:** `core::documents` — #[non_exhaustive] required (public API type per workspace
> convention). `core::embeddings` — DI-009 timeout applies to provider impls; DI-014 no silent
> empty returns applies to batch operations. `core::serializable` — DI-010 secret opacity
> enforced via `lc_secrets()` stripping; DI-014 no silent None on unregistered types.

> **Guardrail definitions (SS-20, DI-012, definitions-only — ADR-014 Decision 6):** ferrochain-core
> hosts DEFINITIONS for the DI-012 guardrail interface promoted in burst-224 (F-P129-09). These are
> pure type and trait definitions with no execution logic — no criticality-counted module row per
> ADR-009 definitions-only precedent.
>
> - `core::guardrail` (`ferrochain-core/src/guardrail.rs`): `GuardrailHook` trait (canonical
>   `async fn evaluate(&self, content: IngressContent, provenance_tag: ProvenanceTag) -> GuardrailResult`
>   per interface-definitions.md §GuardrailHook — `#[async_trait]` desugared; definitions-only,
>   no execution logic in trait body); `GuardrailResult` enum (Pass | Fail{reason,severity} |
>   Transform{new_content}); `IngressContent` enum (ToolResult(ContentBlock) | RagChunk(Value) |
>   MemoryItem(Value)); `GuardrailSeverity` enum (Critical/High/Medium/Low); `BoundaryType` enum
>   (ToolResult | RAGRetrieval | MemoryIngress — 3 variants, PASS-58 canon; not extended).
>   Promoted from graph::provenance/mcp::ingress to ferrochain-core consistent with trait-in-core
>   precedent (BudgetPolicy → core::budget, MemoryWriteGuard → core::write_guard). Existing
>   dispatch modules (graph::provenance, mcp::ingress) import from ferrochain-core.
>
> `core::retriever` gains `GuardedDocuments` (private-field newtype wrapping `Vec<Document>` with
> no external constructor) and `GuardedDocuments::rag_ingress(docs, &dyn GuardrailHook) async →
> Result<GuardedDocuments, FerrochainError>` as the sole public constructor — per-document async
> `evaluate` calls per BC-2.11.003 PC5. Graph nodes that inject retrieved documents into context
> accept `&GuardedDocuments`, making bypass a compile-time type error
> (ADR-014 Decision 6 / BC-2.20.002 VP upgrade).

## ferrochain-prompts (SS-18) — MEDIUM

Responsibilities: prompt template construction (PromptTemplate, ChatPromptTemplate,
MessagesPlaceholder, FewShot*), f-string rendering engine, optional mustache/jinja2,
injection safety guard (pure-core blocker for untrusted content in system-position slots).

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `prompts::template` | `PromptTemplate`; f-string engine (in-house, no external dep); variable extraction at construction; `.partial()` builder | MEDIUM | SS-18 |
| `prompts::chat_template` | `ChatPromptTemplate` + `MessagesPlaceholder`; multi-message template; `PromptValue` output with per-message `MessageProvenance` | MEDIUM | SS-18 |
| `prompts::few_shot` | `FewShotPromptTemplate`; example selectors; snapshot-frozen golden fixture tests | MEDIUM | SS-18 |
| `prompts::injection_guard` | `SlotTrustPolicy` enum; SystemMessage-slot `TrustRequired` immutable enforcement; render-time `E-TMPL-001` blocker for `TrustLevel::Untrusted` in `TrustRequired` slot; pure-core, no I/O; `TrustLevel` is SS-18-local type distinct from `core::guardrail::ProvenanceTag` (SS-11) | HIGH | SS-18 |

> **prompts::injection_guard criticality (HIGH):** the injection blocker is a security-critical
> pure-core module. It must prevent untrusted content from reaching SystemMessage positions
> regardless of caller configuration. VP-006 (Kani P1, seeded burst-223): Kani proof that untrusted-tagged
> variable substitution into a TrustRequired slot always returns Err (never renders).
> Consistent with the production-grade default — security invariants enforced by construction.

> **BC anchors:** BC-2.18.001–005. ADR-015 governs the trust model and engine selection.

## ferrochain-vectorstores (SS-20, SS-21) — MEDIUM

Responsibilities: `VectorStore` trait (async dyn-compatible), `VectorStoreFactory` (Sized-bounded
constructor pattern), in-memory VectorStore backend, MMR selection algorithm, `VectorStoreRetriever`.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `vectorstores::store` | `VectorStore` trait (`add_texts`, `similarity_search`, `similarity_search_with_score`, `max_marginal_relevance_search`, `delete`, `as_retriever`); `VectorStoreFactory` trait; `MetadataFilter` type | MEDIUM | SS-21 |
| `vectorstores::retriever` | `VectorStoreRetriever<'_>` wrapping `&dyn VectorStore`; impl `Retriever`; `SearchType` enum (Similarity / SimilarityScoreThreshold / Mmr) | MEDIUM | SS-20 |
| `vectorstores::memory` | In-memory VectorStore backend; `Arc<dyn Embeddings>` injection via constructor; interior mutability via `RwLock`; `Vec<f32>` cosine similarity; no `ndarray` dep | MEDIUM | SS-21 |
| `vectorstores::similarity` | Shared cosine similarity primitive: `cosine_similarity(a: &[f32], b: &[f32]) → Result<f32, FerrochainError>`; zero-norm IEEE-754 guard (E-VS-001) before division; pure `Vec<f32>` inner product, no `ndarray`, no I/O; called by `vectorstores::memory`, `vectorstores::mmr`, and any future VectorStore backend | MEDIUM | SS-21 |
| `vectorstores::mmr` | Maximal Marginal Relevance selection algorithm; calls `vectorstores::similarity::cosine_similarity` for pairwise similarity + diversity penalty; `lambda_mult` ∈ [0.0, 1.0] parameter; pure math, no I/O | MEDIUM | SS-21 |

> **VP anchors:** `vectorstores::similarity` is VP-009 target (Kani P0 proof that `cosine_similarity`
> returns `Err(E-VS-001)` and never `Ok(f32::NAN)` when either vector norm is 0.0; BC-2.21.003).
> `vectorstores::memory` in-memory backend serves as the integration test double for
> VectorStore conformance tests (analogous to `checkpoint::memory` for checkpoint backends).

> **BC anchors:** BC-2.20.001–003 (Retriever), BC-2.21.001–004 (VectorStore). ADR-014 governs
> trait shapes, factory pattern, SS-15 boundary, and inventory extension seam.

## Provider Embeddings Modules (SS-22) — MEDIUM

Each embedding-capable provider crate gains a new `<provider>::embeddings` module.
ferrochain-anthropic is EXCLUDED — Anthropic provides no public embeddings API (ADR-017).

| Module | Crate | Responsibility | Criticality | SS |
|--------|-------|---------------|-------------|-----|
| `openai::embeddings` | ferrochain-openai | `EmbeddingsOpenAI` impl of `Embeddings` trait; `/v1/embeddings` endpoint; models: text-embedding-3-small/large, text-embedding-ada-002; `OpenAiApiKey` newtype; reqwest rustls-tls; 30s timeout | MEDIUM | SS-22 |
| `ollama::embeddings` | ferrochain-ollama | `EmbeddingsOllama` impl of `Embeddings` trait; `/api/embeddings` endpoint; model-configurable (nomic-embed-text, mxbai-embed-large, etc.); no API key; reqwest rustls-tls; 30s timeout | MEDIUM | SS-22 |

> **NE anchors (both embedding modules):** DI-009 (mandatory timeout); DI-010 (OpenAI key is
> `OpenAiApiKey` newtype with redacted Debug); DI-014 (batch failures return Err, not Vec::new()).
> xtask `deny-client-new` CI gate enforces the reqwest timeout requirement at the workspace level.

## ferrochain-tools (SS-23) — HIGH (tools-shell) / MEDIUM (tools-fs, tools-search)

Responsibilities: first-party file I/O, bash execution, and text-search tools;
implements the `Tool` trait (ferrochain-core) with sandbox path-guard integration
(ferrochain-sandbox) and risk-tier defaults (ferrochain-graph::hitl::ActionRisk).
Crate #21. **D23 item 5 / Wave 1.**

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `tools::fs` | `ReadFileTool`, `WriteFileTool`, `EditFileTool`, `ListDirTool` — all path-guarded via `sandbox::path_guard`; `ReadFileTool` enforces `max_bytes` limit (default 1 MiB; E-TOOLS-002 on excess); `EditFileTool` exact-string replace (E-TOOLS-003 on old_string not found); opt-in fuzzy fallback via `EditConfig::fuzzy_threshold` with `similar` crate; `WriteFileTool`/`EditFileTool` default `ActionRisk::High`; `ReadFileTool`/`ListDirTool` default `ActionRisk::ReadOnly` (ADR-020 / SS-23) | MEDIUM | SS-23 |
| `tools::shell` | `BashTool` — subprocess execution via ferrochain-sandbox backend (WASM or container); stdout/stderr/exit-code capture in `BashOutput`; `max_output_bytes` truncation with `BashOutput::truncated: bool` (E-TOOLS-005 advisory); 30s timeout default (E-TOOLS-004 on timeout); default `ActionRisk::High`; minimum risk floor `ActionRisk::Medium` — configuration error if caller attempts `ReadOnly` or `Low` (E-TOOLS-007) (ADR-020 / SS-23) | HIGH | SS-23 |
| `tools::search` | `GrepTool` — in-process regex search via `regex` crate; path-guarded directory traversal via `sandbox::path_guard`; `max_results` cap (E-TOOLS-006 advisory); default `ActionRisk::ReadOnly`; accepts `{pattern, path, recursive, case_insensitive, max_results}` (ADR-020 / SS-23) | MEDIUM | SS-23 |

**ADR anchor:** ADR-020 governs crate placement (separate from ferrochain-sandbox), dependency
graph (ferrochain-tools → ferrochain-sandbox/core/graph/macros, one-way; no reverse dep),
risk tier defaults, retry classification, and `E-TOOLS-*` error namespace.

**VP anchors:**
- VP-011 (Kani P0, seeded burst-232) — `graph::hitl::pre_tool_dispatch`: fail-closed Deny;
  Deny never allows tool invocation (ADR-018 Decision 3 / BC-2.05.007).
- VP-012 (Kani P1, seeded burst-232) — OnWatermark arithmetic: `on_watermark` never produces
  a token count exceeding the hard limit; no overflow; BC-2.10.005, ferrochain-core,
  core::budget (ADR-019 Decision 2).
- VP-013 (Kani P1, seeded burst-232) — `BashTool::set_risk(ReadOnly)` and `set_risk(Low)`
  always return `Err(E-TOOLS-007)`, never succeed (ADR-020 Decision 3 / BashTool risk floor /
  BC-2.23.005).

**Validated external dependencies (ADR-020 Decision 7):**
- `similar` crate (mitsuhiko) — fuzzy-match fallback for EditFileTool; pinned `"3"` (3.1.1,
  Apache-2.0 single-licensed, MSRV 1.85). Confirmed ADR-020 Decision 7 v1.1.
- `regex` crate — GrepTool in-process pattern engine; pinned `"1"` (1.13.1, MIT/Apache-2.0,
  linear-time DFA, net-new dep). Confirmed ADR-020 Decision 7 v1.1.

**BC anchors:** BC-2.23.001 (ReadFileTool), BC-2.23.002 (WriteFileTool), BC-2.23.003
(EditFileTool), BC-2.23.004 (ListDirTool), BC-2.23.005 (BashTool, VP-013 seed),
BC-2.23.006 (GrepTool). `E-TOOLS-*` error namespace: 9 codes post-burst-234
(E-TOOLS-008 FileIoError added burst-233; E-TOOLS-009 InvalidRegexPattern added burst-234).
