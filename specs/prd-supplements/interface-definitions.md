---
document_type: prd-supplement-interface-definitions
level: L3
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
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
pub trait BaseChatModel: Runnable<Vec<Message>, AIMessage> + Send + Sync {
    fn model_name(&self) -> &str;
    async fn stream_chat(&self, messages: Vec<Message>, config: Option<ChatConfig>)
        -> Result<impl Stream<Item = Result<AIMessageChunk, FerrochainError>>, FerrochainError>;
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

### Assistants

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/assistants` | Create an assistant (named agent config + graph reference) | BC-2.12.002 |
| GET | `/assistants/{assistant_id}` | Get assistant config | BC-2.12.002 |
| GET | `/assistants` | List assistants | BC-2.12.002 |
| PUT | `/assistants/{assistant_id}` | Update assistant config | BC-2.12.002 |
| DELETE | `/assistants/{assistant_id}` | Delete assistant | BC-2.12.002 |

### Runs

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads/{thread_id}/runs` | Create and start a run (async) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}` | Get run status and result | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}/stream` | Get run result as server-sent events | BC-2.12.007 |
| POST | `/threads/{thread_id}/runs/{run_id}/resume` | Deliver resume value to interrupted run | BC-2.05.004 |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | Cancel a queued or in_progress run (transitions to cancelled) | BC-2.12.003 |
| DELETE | `/threads/{thread_id}/runs/{run_id}` | Delete a terminal run record (completed/failed/cancelled only; HTTP 409 if queued, in_progress, or interrupted — cancel or resume-to-complete first) | BC-2.12.003 |

### Cron Schedules

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads/{thread_id}/schedules` | Create a cron schedule for proactive runs | BC-2.12.004 |
| GET | `/threads/{thread_id}/schedules/{schedule_id}` | Get schedule | BC-2.12.004 |
| DELETE | `/threads/{thread_id}/schedules/{schedule_id}` | Delete schedule | BC-2.12.004 |

### HTTP Status Codes

| Code | Meaning | Error Source |
|------|---------|-------------|
| 200 | Success with response body | — |
| 202 | Accepted (async run created; polling required) | — |
| 400 | Validation error | E-CORE-001 through E-CORE-005 |
| 401 | Authentication required | E-SERVER-004 |
| 403 | Policy enforcement (CORS, debug route) | E-SERVER-004, E-SERVER-005 |
| 404 | Resource not found | E-SERVER-002, E-SERVER-003 |
| 409 | Conflict (duplicate resource) | E-SERVER-* |
| 422 | Semantic validation failure | E-GRAPH-*, E-CHKPT-* |
| 429 | Rate limited | E-PROV-001 |
| 500 | Internal error | E-GRAPH-006, E-CHKPT-* |

**BC anchor:** BC-2.12.001 through BC-2.12.007

## Run Object Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["run_id", "thread_id", "assistant_id", "status", "created_at"],
  "properties": {
    "run_id": { "type": "string", "description": "Monotonic logical run identifier" },
    "thread_id": { "type": "string" },
    "assistant_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["queued", "in_progress", "interrupted", "completed", "failed", "cancelled"],
      "description": "Canonical run state machine: queued→in_progress→completed|failed|interrupted|cancelled. multitask_strategy='enqueue' creates the new run in 'queued' state; it transitions to 'in_progress' after the current run finishes. Use POST .../cancel to transition queued/in_progress→cancelled."
    },
    "created_at": { "type": "string", "format": "date-time" },
    "completed_at": { "type": ["string", "null"], "format": "date-time" },
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
      "description": "Present only when status=interrupted",
      "properties": {
        "node_id": { "type": "string" },
        "super_step": { "type": "integer" },
        "risk_tier": {
          "type": ["string", "null"],
          "description": "Typed action-risk level for Domain A (BC-2.05.006)"
        },
        "scratchpad": { "description": "Per-task scratchpad for HITL context" }
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
                               # non-empty = enables /debug/* routes if X-Debug-Key matches

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
