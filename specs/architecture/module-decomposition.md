---
document_type: architecture-section
level: L3
section: module-decomposition
version: "1.0"
status: draft
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/STATE.md
input-hash: "1268b7a2425859ea"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7, D12, D13, D17]
---

# Module Decomposition: ferrochain

> Per the criticality classification in `.factory/specs/module-criticality.md`.
> This file maps subsystems to internal crate modules and their responsibilities.

## ferrochain-core (SS-01, SS-06, SS-14) — CRITICAL

Responsibilities: universal composition protocol, typed message model, error taxonomy,
credential security primitives, streaming event types.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `core::runnable` | `Runnable<I,O>` trait + `RunnableSequence` pipe combinator | HIGH | SS-01 |
| `core::message` | `Message` enum (AIMessage/HumanMessage/SystemMessage/ToolMessage), ContentBlock | CRITICAL | SS-01 |
| `core::error` | `FerrochainError` 2D struct (Component × Category), RFC-7807 emission | CRITICAL | SS-14 |
| `core::credentials` | API key newtypes with redacted Debug; no Serialize; no Deref<Target=str> | CRITICAL | SS-14 |
| `core::events` | Streaming event taxonomy types (RunStarted/Ended, NodeStarted/Ended, etc.) | HIGH | SS-06 |
| `core::config` | `RunnableConfig`, `ChatConfig` structs | MEDIUM | SS-01 |

**NE anchors enforced:** NE-07 (constructor Result), NE-10 (credential opacity), NE-03 (no silent None)

## ferrochain-graph (SS-02, SS-03, SS-05, SS-10, SS-11, SS-15, SS-16) — CRITICAL

Responsibilities: StateGraph definition, BSP execution, HITL, budget governance,
content provenance, memory seams, tool retry.

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `graph::definition` | `StateGraph` builder, node/edge registration, conditional routing | HIGH | SS-02 |
| `graph::channels` | LastValue / Append / BarrierValue / NamedBarrierValue / EphemeralValue reducers | CRITICAL | SS-02 |
| `graph::bsp_engine` | Super-step executor: task dispatch, versions_seen / task-identity sort, InvalidUpdateError | CRITICAL | SS-03 |
| `graph::hitl` | Interrupt queue (FIFO), suspend/resume protocol, risk-tiered classification | CRITICAL | SS-05 |
| `graph::scheduler` | Orchestrator loop and/or actor-scheduler (decision pending ADR-001 D9 gate) | CRITICAL | SS-03 |
| `graph::budget` | `BudgetPolicy` eval (allow/escalate/deny), EvidenceJournal, ceiling halt/escalate | HIGH | SS-10 |
| `graph::provenance` | `ProvenanceTag` attachment at ingress boundaries, `GuardrailHook` dispatch | HIGH | SS-11 |
| `graph::event_emitter` | Streaming event emission; run_id + parent_ids correlation | HIGH | SS-06 |
| `graph::memory_seam` | `BaseMemory` trait seam (KV + vector); GDPR erasure protocol | MEDIUM | SS-15 |
| `graph::retry` | Per-tool retry policy (keyed by tool_name), circuit breaker, finite global_limit | MEDIUM | SS-16 |

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
| `sandbox::path_guard` | `canonicalize_beneath_root(base, path)`; Err(WorkspaceEscape) on escape | CRITICAL | SS-13 |
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

- **ferrochain-openai:** `OpenAI: BaseChatModel`; streaming, tool-call, structured output, error fidelity
- **ferrochain-anthropic:** `Anthropic: BaseChatModel`; streaming, tool-call
- **ferrochain-ollama:** `Ollama: BaseChatModel`; local-first, no API key newtype needed
- **ferrochain-standard-tests:** shared conformance test suite; all providers dev-dep

Each provider crate has one `sdk` module (the generated/standalone SDK type layer) and
one `adapter` module (the ferrochain-core `BaseChatModel` impl) per D17-Q5 / ADR-007.

## ferrochain-mcp (SS-09) — MEDIUM

| Module | Responsibility | Criticality |
|--------|---------------|-------------|
| `mcp::client` | `MultiServerMcpClient`; no live connections until invoke (R11) | MEDIUM |
| `mcp::discovery` | Tool discovery and registration from MCP server at runtime | MEDIUM |
| `mcp::adapter` | `ToolInvocation` routing; ToolException re-raise with type identity (R11) | MEDIUM |
| `mcp::ingress` | Untrusted-ingress routing; DI-012 guardrail seam | MEDIUM |

## xtask (SS-17 support) — LOW

- `check-file-size`: file line-count gate (D12); reads allowlist.toml
- `deny-client-new`: CI lint gate; rejects `Client::new()` outside tests (NE-04)
- `deny-expect-in-lib`: CI lint gate; rejects `.expect()` and `.unwrap()` in library code (NE-07)
