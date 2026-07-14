---
document_type: prd-supplement-interface-definitions
level: L3
version: "1.7"
status: active
producer: product-owner
timestamp: 2026-07-14T00:00:00Z
phase: 1d
changelog:
  - "1.6 (ADV-P1D-PASS-25): F-P25-01 add 503 row (E-SERVER-016 IdempotencyLockTimeout per-endpoint override); F-P25-02 recategorize 401→reserved, 403 now E-SERVER-004 POLICY + E-SERVER-005; F-P25-06 reconcile Run.interrupt sub-fields (interrupt_id, node_name, value, action_risk, action, context added; node_id→node_name, risk_tier→action_risk renamed); F-P25-07 add 201 and 204 rows, add E-CRON-002 to 400 row; OBS-2 add 502 and 504 categorical fallback rows."
  - "1.7 (ADV-P1D-PASS-26): F-P26-04 config comment X-Debug-Key+/debug/*→Authorization:Bearer+/_debug; F-P26-05 rewrite 401 row with E-PROV-004 categorical-fallback; OBS-1 narrow 422 wildcard to enumerated VAL E-GRAPH codes; OBS-2 add E-CRON-001/003 intentional-omission note; OBS-3 add E-PROV-005/006 to 400 row with embedded-in-Run.error annotation."
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
input-hash: "4513c08bec419d649699ab043220d57416534c354f94b95838760bcc6313788d"
traces_to: prd.md
primary_consumers: [implementer, test-writer, devops-engineer]
note: "ferrochain is a Rust library framework, not a CLI tool. 'Interface' covers public Rust traits/types, ferrochain-server HTTP API, Cargo feature flags, and config schemas."
---

# Interface Definitions: ferrochain

> PRD supplement — extracted from PRD Section 3.
> ferrochain is a library crate workspace, not a CLI application.
> The public interface is the set of public Rust traits, types, and the
> ferrochain-server HTTP API.

## Public Rust Trait Signatures (ferrochain-core)

### Runnable\<Input, Output\>

```rust
pub trait Runnable<Input, Output>: Send + Sync {
    /// Invoke the runnable synchronously (blocks async task).
    async fn invoke(&self, input: Input, config: Option<RunnableConfig>)
        -> Result<Output, FerrochainError>;

    /// Invoke and stream output chunks.
    async fn stream(&self, input: Input, config: Option<RunnableConfig>)
        -> Result<impl Stream<Item = Result<Output, FerrochainError>>, FerrochainError>;

    /// Invoke in batch; returns results in input order.
    async fn batch(&self, inputs: Vec<Input>, config: Option<RunnableConfig>)
        -> Result<Vec<Result<Output, FerrochainError>>, FerrochainError>;

    /// Pipe this runnable into another: self | other.
    fn pipe<NextOutput>(self, next: impl Runnable<Output, NextOutput>)
        -> impl Runnable<Input, NextOutput>
    where
        Self: Sized;
}
```

**BC anchor:** BC-2.01.003, BC-2.01.004

### BaseChatModel

```rust
pub trait BaseChatModel: Runnable<Vec<Message>, AiMessage> + Send + Sync {
    fn model_name(&self) -> &str;
    async fn stream_chat(&self, messages: Vec<Message>, config: Option<ChatConfig>)
        -> Result<impl Stream<Item = Result<AiMessageChunk, FerrochainError>>, FerrochainError>;
    async fn bind_tools(&self, tools: Vec<ToolDefinition>) -> impl BaseChatModel;
    fn with_structured_output<T: DeserializeOwned>(&self) -> impl Runnable<Vec<Message>, T>;
}
```

**BC anchor:** BC-2.08.001 through BC-2.08.005

### CheckpointSaver

```rust
pub trait CheckpointSaver: Send + Sync {
    /// Persist task outputs before the next super-step.
    async fn put_writes(
        &self,
        config: CheckpointConfig,
        writes: &[(ChannelName, ChannelValue)],
        task_id: TaskId,
    ) -> Result<(), FerrochainError>;

    /// Load the most recent checkpoint matching the config.
    async fn get_tuple(&self, config: &CheckpointConfig)
        -> Result<Option<CheckpointTuple>, FerrochainError>;

    /// List checkpoints for a thread (newest first).
    async fn list(&self, config: &CheckpointConfig, limit: Option<usize>)
        -> Result<impl Stream<Item = Result<CheckpointTuple, FerrochainError>>, FerrochainError>;
}
```

**BC anchor:** BC-2.04.001 through BC-2.04.006

### GuardrailHook

```rust
pub trait GuardrailHook: Send + Sync {
    /// Called at ingress boundary before content enters model context.
    /// Returns Ok(content) to pass, Ok(replacement) to redact, Err to reject.
    async fn on_ingress(
        &self,
        content: IngressContent,
        provenance: ProvenanceTag,
    ) -> Result<IngressContent, GuardrailError>;
}
```

**BC anchor:** BC-2.11.001 through BC-2.11.006

### BudgetPolicy

```rust
pub trait BudgetPolicy: Send + Sync {
    /// Evaluate whether this invocation is within budget.
    async fn evaluate(
        &self,
        run_id: RunId,
        usage: TokenUsage,
        journal: &dyn EvidenceJournal,
    ) -> BudgetDecision; // allow | escalate | deny
}

pub enum BudgetDecision {
    Allow,
    Escalate { reason: String },
    Deny { reason: String },
}
```

**BC anchor:** BC-2.10.001, BC-2.10.002

## ferrochain-server HTTP API

### Base URL

All endpoints are relative to the server's configured base URL.
Default port: `7437` (configurable via `server.port` in `ferrochain-server.toml`).

### Threads

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads` | Create a new thread | BC-2.12.001 |
| GET | `/threads/{thread_id}` | Get thread metadata | BC-2.12.001 |
| GET | `/threads` | List threads (paginated, `?limit=&offset=`) | BC-2.12.001 |
| DELETE | `/threads/{thread_id}` | Delete thread and all associated checkpoints | BC-2.12.001 |
| GET | `/threads/{thread_id}/state` | Latest checkpoint state: `{ values: GraphState, checkpoint: CheckpointId, next: [NodeId] }` | BC-2.12.001 |
| POST | `/threads/{thread_id}/state` | Apply state delta `{ values: Map<String,Value>, as_node?: NodeId }` → returns `{ checkpoint: CheckpointId }` | BC-2.12.001 |
| GET | `/threads/{thread_id}/history` | Checkpoint history list, newest-first (`?limit=N`) | BC-2.12.001 |

### Assistants

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/assistants` | Create an assistant (named agent config + graph reference) | BC-2.12.002 |
| GET | `/assistants/{assistant_id}` | Get assistant config (resolves via latest-version pointer) | BC-2.12.002 |
| GET | `/assistants` | List assistants | BC-2.12.002 |
| PATCH | `/assistants/{assistant_id}` | Sparse update (new immutable version created; previous accessible via /versions) | BC-2.12.002 |
| DELETE | `/assistants/{assistant_id}` | Delete assistant | BC-2.12.002 |
| GET | `/assistants/{assistant_id}/versions` | List all immutable version snapshots, ordered by version ascending | BC-2.12.002 |
| POST | `/assistants/{assistant_id}/set_latest` | Update latest-version pointer to `{ version: N }` → HTTP 200 with Assistant at version N; 404 if N not found | BC-2.12.002 |

### Runs

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads/{thread_id}/runs` | Create and start a run (async; returns 202 with `run_id`) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs` | List runs for a thread (`?status=queued\|in_progress\|completed\|failed\|interrupted\|cancelled`) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}` | Get run status and result | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}/stream` | Stream run output as server-sent events (SSE; emits run_start, node_start/delta/end, run_end) | BC-2.12.007 |
| POST | `/threads/{thread_id}/runs/{run_id}/resume` | Deliver resume value to interrupted run | BC-2.05.004 |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | Cancel a queued or in_progress run (transitions to cancelled) | BC-2.12.003 |
| DELETE | `/threads/{thread_id}/runs/{run_id}` | Delete a terminal run record (completed/failed/cancelled only; HTTP 409 if queued, in_progress, or interrupted — cancel or resume-to-complete first) | BC-2.12.003 |

### Cron Schedules

Schedules are **assistant-owned** (not thread-owned). Each firing creates a **fresh
`thread_id`** — no prior thread context is shared unless `RunnableConfig.thread_id`
is explicitly set by the operator (BC-2.12.004). Paths are flat (not thread-nested).

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/schedules` | Create a cron schedule (assistant_id + cron expression + config) | BC-2.12.004 |
| GET | `/schedules/{cron_id}` | Get schedule (current `enabled` state, `last_fired_at`) | BC-2.12.004 |
| PATCH | `/schedules/{cron_id}` | Enable/disable schedule (`{ "enabled": false }`; in-flight Run continues) | BC-2.12.004 |
| DELETE | `/schedules/{cron_id}` | Delete schedule; halts all future firings (`204 No Content`) | BC-2.12.004 |

**Cross-thread aggregate query (flat, read-only):**

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| GET | `/runs?schedule_id={cron_id}` | List all Runs fired by a given schedule across all threads (read-only aggregate; not scoped to a single thread) | BC-2.12.004 |

> **Note:** This is the only flat `/runs` endpoint. All other Run CRUD paths are
> thread-scoped (`/threads/{thread_id}/runs/...`). This endpoint exists because
> cron-fired Runs each have distinct `thread_id` values — a thread-scoped query
> cannot enumerate all Runs for a schedule. Decision source: F-P23-01.

### HTTP Status Codes

| Code | Meaning | Error Source |
|------|---------|-------------|
| 200 | Success with response body | — |
| 201 | Created (new resource; body contains created object) | — |
| 202 | Accepted (async run created; polling required) | — |
| 204 | No Content (delete success; no response body) | — |
| 400 | Validation error | E-CORE-001 through E-CORE-005, E-CRON-002 (InvalidCronExpression); E-PROV-005 (StructuredOutputParseError, VAL) and E-PROV-006 (ContextLengthExceeded, VAL) — categorical VAL→400; surfaced embedded in Run.error, not as direct HTTP response codes (OBS-3; BC-2.08.003, BC-2.08.004) |
| 401 | Authentication failure (categorical fallback) | E-PROV-004 (ProviderAuthFailed, AUTH) — categorical fallback only; no v1 server endpoint emits 401 as a direct terminal HTTP status; surfaced embedded in Run.error. Server-side authentication middleware is out of v1 scope (F-P26-05; F-P25-02: E-SERVER-004 recategorized AUTH→POLICY → 403) |
| 403 | Policy enforcement (CORS, debug route) | E-SERVER-004 (DebugRouteUnauthorized), E-SERVER-005 (CorsRejected) |
| 404 | Resource not found | E-SERVER-002 (RunNotFound), E-SERVER-003 (ThreadNotFound), E-SERVER-006 (ScheduleNotFound), E-SERVER-009 (AssistantNotFound — direct resource lookup), E-SERVER-010 (AssistantVersionNotFound) |
| 409 | Conflict (duplicate resource or state conflict) | E-SERVER-007 (ThreadAlreadyExists), E-SERVER-008 (ThreadStateConflict — POLICY→409 per-endpoint override; BC-2.14.002 PC3; F-P26-01), E-SERVER-012 (ConcurrentRun), E-SERVER-015 (RunAlreadyExecuting) |
| 422 | Semantic validation failure (VAL-category on body content) | E-GRAPH-003 (UnknownRoutingTarget), E-GRAPH-004 (DuplicateBarrierWrite), E-GRAPH-007 (UnknownChannelKey), E-GRAPH-008 (UnreachableGraph), E-GRAPH-009 (DuplicateNodeName), E-GRAPH-010 (UnknownBarrierWriter), E-GRAPH-012 (UnmappedRouteKey), E-GRAPH-015 (NoParentGraph); E-SERVER-009 (AssistantNotFound in run body — invalid assistant_id reference at run creation; context-dependent: same code, 404 at direct lookup), E-SERVER-011 (GraphNotFound — graph_id in assistant body not registered). INTERNAL/DURABILITY E-GRAPH codes (E-GRAPH-006, E-GRAPH-011) and all E-CHKPT-* codes go to the 500 row. (OBS-1; narrowed from E-GRAPH-*/E-CHKPT-* wildcards — F-P26-01) |
| 429 | Rate limited | E-PROV-001 |
| 500 | Internal error | E-GRAPH-006 (BspDeterminismViolation, INTERNAL), E-GRAPH-011 (ConditionalEdgePanic, INTERNAL); E-CHKPT-001 (CheckpointWriteFailed, DURABILITY), E-CHKPT-002 (MonotonicClockRegression, INTERNAL), E-CHKPT-003 (CheckpointReadFailed, DURABILITY), E-CHKPT-006 (SerializationFailed, INTERNAL); E-SERVER-014 (RunStoreFailed) |
| 502 | Bad Gateway (provider transport failure) | E-PROV-003 (StreamInterrupted) — categorical fallback only; no v1 endpoint emits 502 as a direct terminal HTTP status; surfaced embedded in Run.error |
| 503 | Service temporarily unavailable (retryable store/lock timeout) | E-SERVER-016 (IdempotencyLockTimeout); Retry-After header present; per-endpoint override over categorical Timeout→504 (F-P25-01; BC-2.12.006 EC-002; BC-2.14.002 PC3 carve-out) |
| 504 | Gateway Timeout (provider response timeout) | E-PROV-002 (ProviderTimeout) — categorical fallback only; no v1 endpoint emits 504 as a direct terminal HTTP status; surfaced embedded in Run.error |

**BC anchor:** BC-2.12.001 through BC-2.12.007

> **Async error intentional omissions (OBS-2, ADV-P1D-PASS-26):** E-CRON-001 (AssistantNotFoundAtFiring) and E-CRON-003 (ScheduleQueueFull) are async firing-time errors surfaced in schedule/run state, never as a direct HTTP response — intentionally omitted from this table.

## Run Object Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["run_id", "thread_id", "assistant_id", "status", "created_at", "updated_at"],
  "properties": {
    "run_id": { "type": "string", "description": "Monotonic logical run identifier" },
    "thread_id": { "type": "string" },
    "assistant_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["queued", "in_progress", "interrupted", "completed", "failed", "cancelled"],
      "description": "Run state machine: queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted (resume via POST .../resume). Authority: BC-2.12.003 PC7-PC9. multitask_strategy='enqueue' creates the new run in 'queued' state; it transitions to 'in_progress' after the current run finishes. Use POST .../cancel to transition queued/in_progress→cancelled."
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time", "description": "Set on every Run state mutation (status transition, output/error write). Always present. Authority: BC-2.12.003 PC13." },
    "completed_at": { "type": ["string", "null"], "format": "date-time", "description": "Set only on terminal transition (status → completed | failed | cancelled). Null in all non-terminal states (queued, in_progress, interrupted). Distinct from updated_at — terminal-timestamp semantics. Authority: F-P24-01." },
    "output": { "description": "Final graph state; present only when status=completed" },
    "error": {
      "type": ["object", "null"],
      "description": "RFC-7807 problem detail; present only when status=failed",
      "properties": {
        "type": { "type": "string", "format": "uri" },
        "title": { "type": "string" },
        "detail": { "type": "string" },
        "extensions": { "type": "object" }
      }
    },
    "interrupt": {
      "type": ["object", "null"],
      "description": "Present only when status=interrupted. Reconciled F-P25-06 to match BCs (authoritative): BC-2.05.001 (InterruptPayload { value, interrupt_id }), BC-2.05.006 (HitlInterruptPayload { action_risk, action, context }), entities-server.md §Interrupt (interrupt_id, node_name, scratchpad).",
      "properties": {
        "interrupt_id": {
          "type": "string",
          "description": "Stable identifier for this interrupt (hash of checkpoint namespace at interrupt time). Used in Command(resume={interrupt_id: value}) targeted delivery. Authority: BC-2.05.001 TV-001, entities-server.md §Interrupt."
        },
        "node_name": {
          "type": "string",
          "description": "Name of the node that raised this interrupt. Canonical field name: node_name (per entities-server.md §Interrupt). Was incorrectly 'node_id' — fixed F-P25-06."
        },
        "super_step": { "type": "integer", "description": "Super-step index at the time the interrupt was raised." },
        "value": {
          "description": "The interrupt value surfaced to the caller (any serializable type; msgpack round-trip required per BC-2.05.001 PC4 TV-001). Authority: BC-2.05.001 PC4."
        },
        "action_risk": {
          "type": ["string", "null"],
          "enum": ["ReadOnly", "Low", "Medium", "High", null],
          "description": "Typed action-risk tier for Domain A HITL interrupts (BC-2.05.006 HitlInterruptPayload). Null for non-risk-tiered interrupts. Canonical field name: action_risk. Was incorrectly 'risk_tier' — fixed F-P25-06."
        },
        "action": {
          "type": ["string", "null"],
          "description": "Human-readable description of the action awaiting authorization (Domain A HITL; HitlInterruptPayload.action). Null for non-HITL-tier interrupts."
        },
        "context": {
          "description": "Optional structured context for the approver (Domain A HITL; HitlInterruptPayload.context). Null for non-HITL-tier interrupts."
        },
        "scratchpad": { "description": "Per-task scratchpad state at interrupt time. Authority: entities-server.md §Interrupt." }
      }
    }
  }
}
```

## Resume Request Schema

```json
{
  "type": "object",
  "required": ["resume_value"],
  "properties": {
    "resume_value": { "description": "The value delivered to the interrupted node (Command(resume=value))" },
    "approver_id": { "type": ["string", "null"], "description": "Optional approver identity for audit trail" }
  }
}
```

**BC anchor:** BC-2.05.004

## ferrochain-server Config File Schema

```toml
# ferrochain-server.toml
[server]
port = 7437                    # default; must be > 1023 for non-root
host = "127.0.0.1"             # default: loopback only
workers = 4                    # Tokio worker threads; default: num_cpus

[security]
# SecurityConfig::default() denies CORS and gates debug routes (NE-14, BC-2.12.005)
cors_allow_origins = []        # empty = deny all cross-origin requests (SECURE DEFAULT)
debug_route_key = ""           # empty string = debug routes disabled (SECURE DEFAULT)
                               # non-empty = enables /_debug route; gate requires
                               # Authorization: Bearer <key> (F-P26-04; BC-2.12.005 authoritative)

[checkpoint]
backend = "sqlite"             # "sqlite" | "memory"; postgres = stretch target
sqlite_path = "./ferrochain.db"

[sandbox]
backend = "wasm"               # "wasm" (default, enforcing) | "container" | "process"
                               # "process" emits loud WARNING on startup (BC-2.13.002)

[budget]
# Global budget policy — overridable per run
default_token_limit = null     # null = unlimited (operator must set a limit)
default_on_ceiling = "halt"    # "halt" | "escalate"
```

**BC anchor:** BC-2.12.005, BC-2.13.001, BC-2.13.002

## Cargo Feature Flags

| Feature | Default | Description | BC Anchor |
|---------|---------|-------------|-----------|
| `checkpoint-sqlite` | on | SQLite checkpoint backend | BC-2.04.001 |
| `checkpoint-memory` | off | In-memory checkpoint backend (testing only; not crash-safe) | BC-2.04.002 |
| `checkpoint-postgres` | off | Postgres checkpoint backend (stretch target) | — |
| `sandbox-wasm` | on | WASM sandbox backend (enforcing; default) | BC-2.13.001 |
| `sandbox-container` | off | Container sandbox backend | BC-2.13.001 |
| `server` | off | ferrochain-server HTTP server | BC-2.12.001 |
| `mcp` | off | ferrochain-mcp adapter | BC-2.09.001 |
| `budget` | on | Budget governance policy primitive | BC-2.10.001 |
| `guardrail` | on | Content provenance + guardrail hook | BC-2.11.001 |

## Flag Interaction Rules

| Flag A | Flag B | Interaction |
|--------|--------|-------------|
| `checkpoint-memory` | `checkpoint-sqlite` | Mutually exclusive in production; memory is testing-only |
| `sandbox-wasm` | `sandbox-container` | Pick one enforcing backend; wasm takes precedence if both enabled |
| `server` | any checkpoint feature | Server requires exactly one checkpoint backend to be active |
| `sandbox-wasm` + `sandbox-container` both off | (none) | `ferrochain-sandbox` defaults to process backend; emits WARNING |
