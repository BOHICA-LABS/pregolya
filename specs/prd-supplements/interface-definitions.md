---
document_type: prd-supplement-interface-definitions
level: L3
version: "2.6"
status: active
producer: product-owner
timestamp: 2026-07-14T00:00:00Z
phase: 1d
changelog:
  - "1.6 (ADV-P1D-PASS-25): F-P25-01 add 503 row (E-SERVER-016 IdempotencyLockTimeout per-endpoint override); F-P25-02 recategorize 401→reserved, 403 now E-SERVER-004 POLICY + E-SERVER-005; F-P25-06 reconcile Run.interrupt sub-fields (interrupt_id, node_name, value, action_risk, action, context added; node_id→node_name, risk_tier→action_risk renamed); F-P25-07 add 201 and 204 rows, add E-CRON-002 to 400 row; OBS-2 add 502 and 504 categorical fallback rows."
  - "1.7 (ADV-P1D-PASS-26): F-P26-04 config comment X-Debug-Key+/debug/*→Authorization:Bearer+/_debug; F-P26-05 rewrite 401 row with E-PROV-004 categorical-fallback; OBS-1 narrow 422 wildcard to enumerated VAL E-GRAPH codes; OBS-2 add E-CRON-001/003 intentional-omission note; OBS-3 add E-PROV-005/006 to 400 row with embedded-in-Run.error annotation."
  - "1.8 (ADV-P1D-PASS-27): F-P27-01 add E-GRAPH-002 (POLICY→422 per-endpoint override) to 422 row; F-P27-02/03 replace 'all E-CHKPT-*' over-broad text with specific enumeration, add E-CHKPT-004 (INTERNAL) to 500 row, add E-CHKPT-005 omission note; F-P27-04 add E-GRAPH-013 (SECURITY) to 403 row, add E-GRAPH-001/014/016 embedded omission notes; 422 row description updated to note POLICY→422 overrides."
  - "1.9 (ADV-P1D-PASS-28): OBS-P28-3 add E-PROV-007 (StructuredOutputRefused, POLICY) omission note — categorical POLICY→403 fallback only; surfaced embedded in Run.error, not as a direct terminal HTTP status."
  - "2.0 (ADV-P1D-PASS-29): F-P29-03 fix SSE description on /stream row: node_start/delta/end → node_start/stream/end (node_delta was never canonical; BC-2.06.001 is the streaming taxonomy authority). OBS-P29-1 add blanket omission note for library/execution-layer codes (E-MCP-*, E-SBXD-*, E-RETRY-*, E-BUDGET-*, E-MEMORY-*, E-SPLIT-*) confirming none has a direct HTTP row."
  - "2.1 (ADV-P1D-PASS-30): F-P30-01 blanket omission note: TOOL→N/A corrected to TOOL→422 (BC-2.14.002 PC3 categorical authority); full 12-category token diff applied — added TRANSPORT→502 and INTERNAL→500 (both present in family labels but absent from summary); corrected VAL→400/422 to VAL→400 (categorical default; 422 requires per-endpoint override decision, not applicable to library-layer fallback)."
  - "2.2 (ADV-P1D-PASS-31): F-P31-01 add §Canonical Pagination Convention section; propagate limit (default 10, max 100, silently clamped if > 100) + offset (default 0) + created_at DESC ordering to GET /threads (explicit defaults), GET /threads/{id}/history (declare default 10/max 100 on existing limit), GET /assistants (add limit/offset), GET /threads/{id}/runs (add limit/offset alongside status filter), GET /runs?schedule_id={cron_id} (add limit/offset, declare created_at DESC). Out-of-range canon: clamp (not reject). BC anchors: BC-2.12.001 PC8/PC17, BC-2.12.003 PC18, BC-2.12.004 PC7."
  - "2.4 (ADV-P1D-PASS-33): F-P33-01 add BC-2.12.002 PC21-PC23 to §Canonical Pagination Convention BC anchors list (list-assistants anchor). F-P33-02 add run-config merge precedence note to POST /threads/{thread_id}/runs row description (deep-merge over Assistant config, run wins at leaf key; BC-2.12.003 §Run-Config Merge Precedence Invariant)."
  - "2.5 (ADV-P1D-PASS-46): F-P46-01 — clarify /stream row description: run_end is emitted on completion only; interrupt and failure paths truncate stream without run_end (BC-2.06.001 PC2 + EC-005 authority; BC-2.12.007 v1.2)."
  - "2.6 (ADV-P1D-PASS-47): F-P47-01 (CRITICAL) fix Flag Interaction Rules row for sandbox-wasm+container-both-off — remove silent-process-fallback claim, replace with SandboxBackend::default()→Err(E-SBXD-003 SandboxInitFailed) per BC-2.13.001 PC4/EC-002/DI-006/NE-01; F-P47-02 fix [sandbox] config comment 'process emits WARNING on startup'→'once per execute() invocation — NOT construction/startup' per BC-2.13.002 PC2/EC-002; OBS-P47-1 add sandbox-process row to Cargo Feature Flags table with NOT-enforcing/explicit-constructor-only semantics per BC-2.13.001 PC3/PC4."
  - "2.3 (ADV-P1D-PASS-32): F-P32-03 add canonical pagination to GET /assistants/{id}/versions row (limit default 10 max 100 clamped / offset / ordering exemption: version ASC — deviates from created_at DESC default); BC-2.12.002 PC20 added as anchor. OBS-P32-1 add no-list-schedules note in §Cron Schedules."
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

### Canonical Pagination Convention (F-P31-01, ADV-P1D-PASS-31)

All list and aggregate GET endpoints accept uniform pagination query parameters:

| Parameter | Type | Default | Max | Out-of-range |
|-----------|------|---------|-----|--------------|
| `limit` | integer | 10 | 100 | Values > 100 are **silently clamped** to 100 — no validation error (E-CORE) is returned. Decision: clamp (not reject). |
| `offset` | integer | 0 | — | No upper bound. |

Results are ordered by `created_at` **descending** (most-recently created first) unless a
specific endpoint declares a different ordering (e.g., `/history` is ordered newest
checkpoint first, which is also descending by creation sequence). Each list-endpoint
row below cites F-P31-01 where pagination applies. Any endpoint that deviates carries
an explicit documented exemption.

**BC anchors:** BC-2.12.001 PC8 (threads list), BC-2.12.001 PC17 (history), BC-2.12.002 PC21-PC23 (assistants list), BC-2.12.003 PC18 (runs list), BC-2.12.004 PC7 (schedule-runs aggregate).

### Threads

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads` | Create a new thread | BC-2.12.001 |
| GET | `/threads/{thread_id}` | Get thread metadata | BC-2.12.001 |
| GET | `/threads` | List threads; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC) — F-P31-01 | BC-2.12.001 |
| DELETE | `/threads/{thread_id}` | Delete thread and all associated checkpoints | BC-2.12.001 |
| GET | `/threads/{thread_id}/state` | Latest checkpoint state: `{ values: GraphState, checkpoint: CheckpointId, next: [NodeId] }` | BC-2.12.001 |
| POST | `/threads/{thread_id}/state` | Apply state delta `{ values: Map<String,Value>, as_node?: NodeId }` → returns `{ checkpoint: CheckpointId }` | BC-2.12.001 |
| GET | `/threads/{thread_id}/history` | Checkpoint history list, newest-first; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; values > 100 clamped) — F-P31-01 | BC-2.12.001 |

### Assistants

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/assistants` | Create an assistant (named agent config + graph reference) | BC-2.12.002 |
| GET | `/assistants/{assistant_id}` | Get assistant config (resolves via latest-version pointer) | BC-2.12.002 |
| GET | `/assistants` | List assistants; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC) — F-P31-01 | BC-2.12.002 |
| PATCH | `/assistants/{assistant_id}` | Sparse update (new immutable version created; previous accessible via /versions) | BC-2.12.002 |
| DELETE | `/assistants/{assistant_id}` | Delete assistant | BC-2.12.002 |
| GET | `/assistants/{assistant_id}/versions` | List all immutable version snapshots; canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; values > 100 silently clamped); **ordering exemption**: results ordered `version` **ascending** (lowest version first) — version ASC is intentional for historical replay and deviates from the default `created_at` DESC canon; exemption declared per F-P32-03, BC-2.12.002 PC20 | BC-2.12.002 |
| POST | `/assistants/{assistant_id}/set_latest` | Update latest-version pointer to `{ version: N }` → HTTP 200 with Assistant at version N; 404 if N not found | BC-2.12.002 |

### Runs

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/threads/{thread_id}/runs` | Create and start a run (async; returns 202 with `run_id`); run-supplied `config`/`metadata`/`context` deep-merge over the Assistant's stored values, run wins at leaf key (BC-2.12.003 §Run-Config Merge Precedence Invariant, F-P33-02) | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs` | List runs for a thread; `?status=queued\|in_progress\|completed\|failed\|interrupted\|cancelled` filter + canonical pagination (`?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC) — F-P31-01 | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}` | Get run status and result | BC-2.12.003 |
| GET | `/threads/{thread_id}/runs/{run_id}/stream` | Stream run output as server-sent events (SSE; happy path emits run_start, node_start/stream/end, run_end; **run_end is emitted on completion only** — interrupted runs terminate with interrupt envelope as terminal frame, failed runs terminate with error SSE event; neither emits run_end; BC-2.06.001 PC2+EC-005, BC-2.12.007 EC-001/EC-003) | BC-2.12.007 |
| POST | `/threads/{thread_id}/runs/{run_id}/resume` | Deliver resume value to interrupted run | BC-2.05.004 |
| POST | `/threads/{thread_id}/runs/{run_id}/cancel` | Cancel a queued or in_progress run (transitions to cancelled) | BC-2.12.003 |
| DELETE | `/threads/{thread_id}/runs/{run_id}` | Delete a terminal run record (completed/failed/cancelled only; HTTP 409 if queued, in_progress, or interrupted — cancel or resume-to-complete first) | BC-2.12.003 |

### Cron Schedules

Schedules are **assistant-owned** (not thread-owned). Each firing creates a **fresh
`thread_id`** — no prior thread context is shared unless `RunnableConfig.thread_id`
is explicitly set by the operator (BC-2.12.004). Paths are flat (not thread-nested).

> **No list-all-schedules endpoint (OBS-P32-1, ADV-P1D-PASS-32):** No list-all-schedules
> endpoint in v1 — schedules are addressed individually by cron_id; the flat
> `GET /runs?schedule_id={cron_id}` aggregate is the only schedule-scoped listing surface
> (URL-scheme canon, ADV-P1D-PASS-23).

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| POST | `/schedules` | Create a cron schedule (assistant_id + cron expression + config) | BC-2.12.004 |
| GET | `/schedules/{cron_id}` | Get schedule (current `enabled` state, `last_fired_at`) | BC-2.12.004 |
| PATCH | `/schedules/{cron_id}` | Enable/disable schedule (`{ "enabled": false }`; in-flight Run continues) | BC-2.12.004 |
| DELETE | `/schedules/{cron_id}` | Delete schedule; halts all future firings (`204 No Content`) | BC-2.12.004 |

**Cross-thread aggregate query (flat, read-only):**

| Method | Path | Description | BC Anchor |
|--------|------|-------------|-----------|
| GET | `/runs?schedule_id={cron_id}` | List all Runs fired by a given schedule across all threads (read-only aggregate; canonical pagination: `?limit=N` default 10 max 100, `?offset=N`; `created_at` DESC — ordering canon declared in BC-2.12.004 PC7; F-P31-01) | BC-2.12.004 |

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
| 403 | Policy enforcement (CORS, debug route, role gate) | E-SERVER-004 (DebugRouteUnauthorized), E-SERVER-005 (CorsRejected), E-GRAPH-013 (InsufficientApproverRole — SECURITY; direct HTTP 403 on `POST /threads/{thread_id}/runs/{run_id}/resume` when caller role is insufficient for the interrupt's risk tier; BC-2.05.006 PC3-PC4, EC-001; F-P27-04) |
| 404 | Resource not found | E-SERVER-002 (RunNotFound), E-SERVER-003 (ThreadNotFound), E-SERVER-006 (ScheduleNotFound), E-SERVER-009 (AssistantNotFound — direct resource lookup), E-SERVER-010 (AssistantVersionNotFound) |
| 409 | Conflict (duplicate resource or state conflict) | E-SERVER-007 (ThreadAlreadyExists), E-SERVER-008 (ThreadStateConflict — POLICY→409 per-endpoint override; BC-2.14.002 PC3; F-P26-01), E-SERVER-012 (ConcurrentRun), E-SERVER-015 (RunAlreadyExecuting) |
| 422 | Semantic validation failure (VAL-category on body content) and per-endpoint POLICY→422 overrides (request valid but current state makes processing impossible) | E-GRAPH-003 (UnknownRoutingTarget), E-GRAPH-004 (DuplicateBarrierWrite), E-GRAPH-007 (UnknownChannelKey), E-GRAPH-008 (UnreachableGraph), E-GRAPH-009 (DuplicateNodeName), E-GRAPH-010 (UnknownBarrierWriter), E-GRAPH-012 (UnmappedRouteKey), E-GRAPH-015 (NoParentGraph); E-SERVER-009 (AssistantNotFound in run body — invalid assistant_id reference at run creation; context-dependent: same code, 404 at direct lookup), E-SERVER-011 (GraphNotFound — graph_id in assistant body not registered); E-GRAPH-002 (NoActiveInterrupt — POLICY→422 per-endpoint override on resume endpoint: run exists and caller is authorized, but no interrupt slot is active; BC-2.14.002 PC3 9th override; F-P27-01). INTERNAL/DURABILITY E-GRAPH codes (E-GRAPH-006, E-GRAPH-011) and DURABILITY/INTERNAL E-CHKPT codes (E-CHKPT-001, -002, -003, -004, -006) go to the 500 row; E-CHKPT-005 (TENANCY) is library-level embedded — see omission note below. (OBS-1; narrowed from E-GRAPH-*/E-CHKPT-* wildcards — F-P26-01; F-P27-01 adds E-GRAPH-002; F-P27-03 corrects E-CHKPT-* over-broad text) |
| 429 | Rate limited | E-PROV-001 |
| 500 | Internal error | E-GRAPH-006 (BspDeterminismViolation, INTERNAL), E-GRAPH-011 (ConditionalEdgePanic, INTERNAL); E-CHKPT-001 (CheckpointWriteFailed, DURABILITY), E-CHKPT-002 (MonotonicClockRegression, INTERNAL), E-CHKPT-003 (CheckpointReadFailed, DURABILITY), E-CHKPT-004 (EncryptionKeyRotationFailed, INTERNAL — F-P27-02/03: category corrected SECURITY→INTERNAL; added to 500 row), E-CHKPT-006 (SerializationFailed, INTERNAL); E-SERVER-014 (RunStoreFailed) |
| 502 | Bad Gateway (provider transport failure) | E-PROV-003 (StreamInterrupted) — categorical fallback only; no v1 endpoint emits 502 as a direct terminal HTTP status; surfaced embedded in Run.error |
| 503 | Service temporarily unavailable (retryable store/lock timeout) | E-SERVER-016 (IdempotencyLockTimeout); Retry-After header present; per-endpoint override over categorical Timeout→504 (F-P25-01; BC-2.12.006 EC-002; BC-2.14.002 PC3 carve-out) |
| 504 | Gateway Timeout (provider response timeout) | E-PROV-002 (ProviderTimeout) — categorical fallback only; no v1 endpoint emits 504 as a direct terminal HTTP status; surfaced embedded in Run.error |

**BC anchor:** BC-2.12.001 through BC-2.12.007

> **Async error intentional omissions (OBS-2, ADV-P1D-PASS-26):** E-CRON-001 (AssistantNotFoundAtFiring) and E-CRON-003 (ScheduleQueueFull) are async firing-time errors surfaced in schedule/run state, never as a direct HTTP response — intentionally omitted from this table.

> **Graph execution errors embedded in Run.error (F-P27-04, ADV-P1D-PASS-27):** E-GRAPH-001 (InvalidUpdateError, CONCURRENCY — BC-2.03.002; concurrent BSP write failure surfaces as a run failure, embedded in Run.error.type), E-GRAPH-014 (InterruptApprovalTimeout, POLICY — BC-2.05.006 EC-005; timeout causes run transition to `failed`, embedded in Run.error), and E-GRAPH-016 (InterruptWithoutCheckpointer, POLICY — BC-2.05.001 EC-001, BC-2.10.004; raised when interrupt() is called without a CheckpointSaver, surfaces as a run failure) are graph execution errors that appear embedded in Run.error, never as direct terminal HTTP status codes. Categorical mappings: CONCURRENCY→409, POLICY→403 (apply only if ever surfaced directly — not in v1).

> **E-CHKPT-005 library-level omission (F-P27-03, ADV-P1D-PASS-27):** E-CHKPT-005 (SessionAddressCollision, TENANCY — BC-2.04.006) is a checkpoint library-level error enforcing the session triple-address uniqueness invariant (NE-12). TENANCY→409 is the categorical mapping. In v1 this error is raised within the checkpoint layer before any HTTP response is sent, surfacing as a run failure embedded in Run.error, not as a direct terminal HTTP 409 response. Intentionally omitted from the 409 row for the same reason as the E-PROV categorical-fallback codes.

> **E-PROV-007 embedded omission (OBS-P28-3, ADV-P1D-PASS-28):** E-PROV-007 (StructuredOutputRefused, POLICY — BC-2.08.003) is emitted when the OpenAI Responses API rejects a `json_schema` structured output request via a safety-filter refusal. POLICY→403 is the categorical mapping. In v1 this error surfaces as a run failure embedded in Run.error — the server cannot distinguish a refusal from a valid LLM response until the response body is deserialized post-stream. No v1 server endpoint emits HTTP 403 directly for this code. Intentionally omitted from the 403 row; the 403 row lists only codes that produce a direct terminal HTTP 403 response (E-SERVER-004, E-SERVER-005, E-GRAPH-013).

> **Library/execution-layer codes — blanket omission (OBS-P29-1, ADV-P1D-PASS-29; F-P30-01, ADV-P1D-PASS-30):** All remaining library and execution-layer error codes — E-MCP-* (BC-2.09.x, TOOL/TRANSPORT/VAL), E-SBXD-* (BC-2.13.x, SECURITY/POLICY/INTERNAL), E-RETRY-* (BC-2.16.x, POLICY), E-BUDGET-* (BC-2.10.x, POLICY/DURABILITY), E-MEMORY-* (BC-2.15.x, VAL/POLICY/DURABILITY), E-SPLIT-* (BC-2.07.x, VAL) — surface embedded in Run.error or as library `Err` return values. None has a direct HTTP row in this table. Categorical fallbacks apply if ever surfaced directly (TOOL→422, TRANSPORT→502, SECURITY→403, POLICY→403, DURABILITY→500, INTERNAL→500, VAL→400) but in v1 these codes are not emitted as terminal HTTP responses by any endpoint. Spot-checked: E-MCP-001 (BC-2.09.004 — embedded in run as tool failure), E-SBXD-001 (BC-2.13.005 — sandbox security violation embedded in run), E-MEMORY-001 (BC-2.15.001 — memory store validation error embedded in run); all confirmed library-layer only.

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
                               # 'process' backend emits loud WARNING once per execute() invocation — NOT construction/startup (BC-2.13.002 PC2/EC-002)

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
| `sandbox-process` | off | Process backend (NOT enforcing; no filesystem/network/memory isolation); compiles `ProcessBackend` but does NOT make it a default — accessible ONLY via `Sandbox::unsafe_process_no_isolation()`; `SandboxBackend::default()` returns `Err(E-SBXD-003)` when no enforcing backend is compiled (BC-2.13.001 PC3/PC4) | BC-2.13.001, BC-2.13.002 |
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
| `sandbox-wasm` + `sandbox-container` both off | (none) | `SandboxBackend::default()` returns `Err(E-SBXD-003 SandboxInitFailed { reason: "no enforcing backend compiled in" })`; NO silent process fallback (BC-2.13.001 PC4/EC-002, DI-006, NE-01); process backend reachable ONLY via explicit `Sandbox::unsafe_process_no_isolation()` (BC-2.13.001 PC3) |
