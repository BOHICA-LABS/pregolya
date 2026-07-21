---
document_type: architecture-section
level: L3
section: api-surface
version: "1.6"
status: active
producer: architect
timestamp: 2026-07-20T00:00:00Z
changelog:
  - "1.6 (D21/Batch-3b-i/2026-07-20): Component enum expanded 12→16 per ADR-010 v1.1. Added TMPL (ferrochain-prompts), SRLZ (ferrochain-core::serializable), VS (ferrochain-vectorstores), EMBED (ferrochain-core::embeddings) to Component list. #[non_exhaustive] gate count 13→17 (16 named variants + Custom = 17). Implementer updates ALL three gate locations (gate crate, expected count constant, expected symbol list) when creating ferrochain-core/src/error.rs at Wave 0 per CLAUDE.md non-exhaustive gate rule."
  - "1.5 (F-P115-02 ripple, 2026-07-19): Extend CheckpointSaver BC anchor range from BC-2.04.001–006 to BC-2.04.001–007. BC-2.04.007 is now a live anchor because the `put` method (added to the trait per F-P115-02 adjudication) carries BC-2.04.007 PC1/INV-1 encryption-parity obligations. Sweep: no method-count enumerations or get_next_version absence claims present in this file — api-surface.md delegates all signatures to interface-definitions.md."
  - "1.4 (F-P92-02, 2026-07-17): Add §ferrochain-core Public Types table. RunnableConfig gains budget_config: Option<BudgetConfig> (OPTION A — BC-2.10.004 PC6 / BC-2.10.003 PC7/TV-004). Row documents all four known RunnableConfig fields (recursion_limit, thread_id, budget_config, context_mutations)."
  - "1.3 (provenance-fix-169/2026-07-17): hash-currency refresh — prd.md updated to v1.2 in same burst; add [Section Content] template compliance fix. No spec content changes."
  - "1.2 (ADV-P1D-PASS-64): F-P64-01 adjudication — default port 7437 is mandated; replaced 'no default port mandated' with authoritative default per interface-definitions.md §Base URL."
  - "1.1 (ADV-P1D-PASS-25): F-P25-04 to_problem_detail()→to_problem() method name correction."
  - "1.0 (initial / 2026-07-13): initial API surface authored — ferrochain-core Public Traits, ferrochain-server HTTP endpoint catalog, and ferrochain-server Public Types. NOTE (F-P104-01, 2026-07-18): reconstructed from commit ef41eda (burst 73, 2026-07-13) — no initial changelog row was written at authoring."
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/interface-definitions.md
input-hash: "71e7d77"
traces_to: ARCH-INDEX.md
decisions: [D13, D17]
---

# API Surface: ferrochain

> Full signatures in `prd-supplements/interface-definitions.md`. This file is the
> architecture-level summary: which traits belong to which crate/subsystem, and
> the HTTP endpoint catalog for ferrochain-server.

## [Section Content]

This file documents ferrochain's public API surface: the public Rust traits by crate/subsystem, and the HTTP endpoint catalog for ferrochain-server. It is the architecture-level summary; full signatures live in `prd-supplements/interface-definitions.md`.

## Public Rust Traits (ferrochain-core)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `Runnable<Input, Output>` | ferrochain-core | SS-01 | BC-2.01.003, BC-2.01.004 |
| `BaseChatModel` | ferrochain-core | SS-08 | BC-2.08.001–005 |
| `GuardrailHook` | ferrochain-core | SS-11 | BC-2.11.002–004 |
| `BudgetPolicy` | ferrochain-core | SS-10 | BC-2.10.001 |
| `Tool` | ferrochain-core | SS-09 | BC-2.09.002 |

## ferrochain-core Public Types

| Type | Role | SS | BC Anchors |
|------|------|----|-----------|
| `RunnableConfig` | Per-invocation config: `recursion_limit` (default 25), `thread_id`, `budget_config: Option<BudgetConfig>` (per-run budget override — `None` inherits `GraphConfig::budget_config`; `Some` overrides for that run; used by `BudgetResume::Extend`), `context_mutations: Option<ContextMutationConfig>` | SS-01 | BC-2.01.003 PC5, BC-2.10.003 PC7/TV-004, BC-2.10.004 PC6, BC-2.15.006 PC1 |

## Public Traits (ferrochain-memory)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `MemoryStore` | ferrochain-memory | SS-15 | BC-2.15.001–003 |

## Public Traits (ferrochain-checkpoint)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `CheckpointSaver` | ferrochain-checkpoint | SS-04 | BC-2.04.001–007 |

## Public Traits (ferrochain-server)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `IdempotencyStore` | ferrochain-server | SS-12 | BC-2.12.006 |
| `RateLimitStore` | ferrochain-server | SS-12 | BC-2.12.006 |
| `RunStore` | ferrochain-server | SS-12 | BC-2.12.006 |

## ferrochain-graph Public Types

| Type | Role | SS | BC Anchors |
|------|------|----|-----------|
| `StateGraph<State>` | Graph builder: nodes, edges, channels | SS-02 | BC-2.02.001–006 |
| `GraphConfig` | Execution config: checkpoint_saver, interrupt_before/after | SS-03 | BC-2.03.001 |
| `Command` | HITL resume carrier: `Command::resume(value)` | SS-05 | BC-2.05.004 |
| `StreamEvent` | Streaming event enum; run_id + parent_ids | SS-06 | BC-2.06.001–002 |
| `BudgetConfig` | Budget ceiling + on_ceiling policy | SS-10 | BC-2.10.001 |
| `ProvenanceTag` | Content source tag; attached at every ingress | SS-11 | BC-2.11.001 |

## ferrochain-server HTTP Endpoints

Base URL: configurable; default port 7437 (server.port in ferrochain-server.toml — see interface-definitions.md §Base URL).

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads` | Create thread | BC-2.12.001 |
| GET | `/threads/{thread_id}` | Read thread | BC-2.12.001 |
| GET | `/threads` | List threads | BC-2.12.001 |
| DELETE | `/threads/{thread_id}` | Delete thread | BC-2.12.001 |
| GET | `/threads/{thread_id}/state` | Latest checkpoint state (`{ values, checkpoint, next }`) | BC-2.12.001 |
| POST | `/threads/{thread_id}/state` | Apply state delta (`{ values, as_node? }` → `{ checkpoint }`) | BC-2.12.001 |
| GET | `/threads/{thread_id}/history` | Checkpoint history, newest-first (`?limit=N`) | BC-2.12.001 |
| POST | `/assistants` | Create assistant (named agent config) | BC-2.12.002 |
| GET | `/assistants` | List assistants | BC-2.12.002 |
| GET | `/assistants/{assistant_id}` | Read assistant (resolves via latest-version pointer) | BC-2.12.002 |
| PATCH | `/assistants/{assistant_id}` | Sparse update; creates immutable new version | BC-2.12.002 |
| DELETE | `/assistants/{assistant_id}` | Delete assistant | BC-2.12.002 |
| GET | `/assistants/{assistant_id}/versions` | List immutable version snapshots (ascending) | BC-2.12.002 |
| POST | `/assistants/{assistant_id}/set_latest` | Set latest-version pointer (`{ version: N }`) | BC-2.12.002 |
| POST | `/threads/{thread_id}/runs` | Create and start run (async; 202 Accepted) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs` | List runs for thread (`?status=`) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}` | Read run status and result | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}/stream` | SSE streaming run output | BC-2.12.007 |
| POST | `/threads/{thread_id}/runs/{run_id}/resume` | Deliver HITL resume value | BC-2.05.004 |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | Cancel queued/in_progress run (→ cancelled) | BC-2.12.003 |
| DELETE | `/threads/{thread_id}/runs/{run_id}` | Delete terminal run record (409 if non-terminal) | BC-2.12.003 |
| POST | `/schedules` | Create cron schedule (assistant-owned; flat path) | BC-2.12.004 |
| GET | `/schedules/{cron_id}` | Read schedule (enabled state, last_fired_at) | BC-2.12.004 |
| PATCH | `/schedules/{cron_id}` | Enable/disable schedule (`{ "enabled": false }`) | BC-2.12.004 |
| DELETE | `/schedules/{cron_id}` | Delete schedule; halts future firings | BC-2.12.004 |
| GET | `/runs?schedule_id={cron_id}` | Cross-thread aggregate: list all Runs for a schedule (read-only; flat) | BC-2.12.004 |

**URL scheme (F-P23-01):** Runs are thread-nested (`/threads/{thread_id}/runs/...`). Schedules are
flat (`/schedules/{cron_id}`). The one flat `/runs?schedule_id=` endpoint is a read-only
cross-thread aggregate query for schedule-fired runs only.

**Wire format:** JSON for HTTP responses. msgpack for checkpoint state (ADR-002).

**Security:** `SecurityConfig::default()` denies CORS. Debug route requires opt-in key (BC-2.12.005).

## Cargo Feature Flags

| Feature | Default | Description | BC Anchor |
|---------|---------|-------------|-----------|
| `checkpoint-sqlite` | YES | SQLite checkpoint backend | BC-2.04.002 |
| `checkpoint-memory` | NO | In-memory backend (tests) | — |
| `checkpoint-postgres` | NO | PostgreSQL backend (stretch) | — |
| `sandbox-wasm` | YES | WASM execution backend (enforcing default) | BC-2.13.001 |
| `sandbox-container` | NO | Container execution backend | BC-2.13.001 |
| `server` | NO | Include ferrochain-server in binary | BC-2.12.001 |

## Error Type

`FerrochainError { component: Component, category: Category, retry_hint: RetryHint, code: &'static str }`

Authoritative list lives in `error-taxonomy.md` §Components; enum reproduced here for the FerrochainError type definition:
`Component` = CORE | GRAPH | CHKPT | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET | TMPL | SRLZ | VS | EMBED (16 components as of D21; `#[non_exhaustive]` gate count 13→17: 16 named + `Custom`).
Full catalog: `prd-supplements/error-taxonomy.md`.
RFC-7807 serialization: `FerrochainError::to_problem()` (BC-2.14.002). Note: corrected from `to_problem_detail()` (F-P25-04; BC-2.14.002 is authoritative for method name).
