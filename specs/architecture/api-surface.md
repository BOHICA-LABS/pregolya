---
document_type: architecture-section
level: L3
section: api-surface
version: "1.0"
status: draft
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/prd-supplements/interface-definitions.md
input-hash: "9ba0fe73e5a4178c"
traces_to: ARCH-INDEX.md
decisions: [D13, D17]
---

# API Surface: ferrochain

> Full signatures in `prd-supplements/interface-definitions.md`. This file is the
> architecture-level summary: which traits belong to which crate/subsystem, and
> the HTTP endpoint catalog for ferrochain-server.

## Public Rust Traits (ferrochain-core)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `Runnable<Input, Output>` | ferrochain-core | SS-01 | BC-2.01.003, BC-2.01.004 |
| `BaseChatModel` | ferrochain-core | SS-08 | BC-2.08.001–005 |
| `GuardrailHook` | ferrochain-core | SS-11 | BC-2.11.002–004 |
| `BudgetPolicy` | ferrochain-core | SS-10 | BC-2.10.001 |
| `Tool` | ferrochain-core | SS-09 | BC-2.09.002 |

## Public Traits (ferrochain-memory)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `MemoryStore` | ferrochain-memory | SS-15 | BC-2.15.001–003 |

## Public Traits (ferrochain-checkpoint)

| Trait | Crate | SS | BC Anchors |
|-------|-------|----|-----------|
| `CheckpointSaver` | ferrochain-checkpoint | SS-04 | BC-2.04.001–006 |

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

Base URL: configurable; no default port mandated.

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads` | Create thread | BC-2.12.001 |
| GET | `/threads/{thread_id}` | Read thread | BC-2.12.001 |
| GET | `/threads` | List threads | BC-2.12.001 |
| DELETE | `/threads/{thread_id}` | Delete thread | BC-2.12.001 |
| POST | `/assistants` | Create assistant (named agent config) | BC-2.12.002 |
| GET | `/assistants/{assistant_id}` | Read assistant | BC-2.12.002 |
| PUT | `/assistants/{assistant_id}` | Update assistant | BC-2.12.002 |
| DELETE | `/assistants/{assistant_id}` | Delete assistant | BC-2.12.002 |
| POST | `/runs` | Create and start run | BC-2.12.003 |
| GET | `/runs/{run_id}` | Read run status | BC-2.12.003 |
| GET | `/runs/{run_id}/stream` | SSE streaming run output | BC-2.12.007 |
| POST | `/runs/{run_id}/resume` | Deliver HITL resume value | BC-2.05.004 |
| POST | `/schedules` | Create cron schedule | BC-2.12.004 |
| GET | `/schedules/{schedule_id}` | Read schedule | BC-2.12.004 |
| DELETE | `/schedules/{schedule_id}` | Delete schedule | BC-2.12.004 |

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
`Component` = CORE | GRAPH | CHKPT | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET (12 components).
Full catalog: `prd-supplements/error-taxonomy.md`.
RFC-7807 serialization: `FerrochainError::to_problem_detail()` (BC-2.14.002).
