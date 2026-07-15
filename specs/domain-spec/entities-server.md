---
document_type: domain-spec-section
level: L2
section: entities-server
version: "1.4"
status: active
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-25): F-P25-03 FerrochainError.code changed from u32 to String."
  - "1.2 (ADV-P1D-PASS-30): OBS-P30-1 add Timestamp UTC canon under Server Domain — all Timestamp values RFC 3339 UTC at construction; wire serialization preserves UTC form."
  - "1.3 (ADV-P1D-PASS-58): F-P58-03 — rewrite §ProvenanceTag and §GuardrailHook to BC-authoritative shapes. ProvenanceTag: source_type/IngressSource/tool_name/invocation_id/timestamp retired → boundary_type: BoundaryType (ToolResult|RAGRetrieval|MemoryIngress), ingress_id: Uuid, sequence_position: usize (BC-2.11.001 PC1–PC3); User/Model variants removed per BC-2.11.001 EC-004. GuardrailHook: action_fn/GuardrailAction/Accept/Reject/Redact retired → evaluate(content: IngressContent, provenance_tag: ProvenanceTag) → GuardrailResult (Pass/Fail{reason,severity: GuardrailSeverity}/Transform{new_content}); authority interface-definitions.md v2.13 §GuardrailHook, BC-2.11.002 PC1–PC4."
  - "1.4 (ADV-P1D-PASS-59): F-P59-02 — add Transform same-boundary rule to §GuardrailHook: new_content must be the same IngressContent variant as the evaluated content (ToolResult stays ToolResult, RagChunk stays RagChunk, MemoryItem stays MemoryItem); inner payload may change freely per BC-2.11.002 EC-003."
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/STATE.md
input-hash: "3f4fe9a8c015bc918f167f893ba8e1b2392e6b5cd44460b7bd780c5c5fd72500"
traces_to: L2-INDEX.md
decisions: [D11, D13, D17]
---

# Domain Entities — Server, Policy/Governance, and Provider

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> Core Primitives, Graph, and Checkpoint entities are in `entities-graph.md`.

---

## Server Domain

> **Canonical Timestamp semantics (OBS-P30-1):** All Timestamp values are RFC 3339 date-time normalized to UTC (offset +00:00 / Z) at construction; wire serialization preserves UTC form. Applies to all `created_at`, `updated_at`, `completed_at`, `last_fired_at`, and `timestamp` fields throughout this section.

### Thread
A named, durable sequence of checkpoints representing one conversation or pipeline run lineage.
- **Fields:** thread_id: Uuid, metadata: Map<String, Value>, created_at: Timestamp, updated_at: Timestamp, status: ThreadStatus
- **ThreadStatus:** `idle` (no active run on this thread), `busy` (a run is queued or in_progress on this thread), `interrupted` (the most recent active run is interrupted; awaiting HITL resume), `error` (the most recent run failed and no other run is active). Derived from the state of the most recent active Run on the thread. Source: BC-2.12.001 PC5.
- **Relationships:** Thread 1→N Run. Thread 1→N Checkpoint (via thread_id in CheckpointSaver).
- **Note:** Corresponds to LangGraph Platform "thread." All Runs sharing a Thread share a checkpoint history.

### Assistant
A named agent configuration hosted by ferrochain-server.
- **Fields:** assistant_id: Uuid, graph_id: GraphId (references a registered CompiledGraph), config: RunnableConfig, context: Option<Value>, metadata: Map<String, Value>, name: Option<String>, description: Option<String>, version: u32, created_at: Timestamp
- **version semantics:** Starts at 1. Each `PATCH` creates a new immutable version snapshot (N+1); the `latest` pointer is mutable. Source: BC-2.12.002 PC3/PC10.
- **Relationships:** Assistant 1→N Run.
- **Note:** No wire compatibility with LangGraph Platform (D13). ferrochain-server is first-party.

### Run
A single execution of an Assistant with a Thread.
- **Fields:** run_id: Uuid, thread_id: Uuid, assistant_id: Uuid, status: RunStatus, config: RunnableConfig, created_at: Timestamp, updated_at: Timestamp, completed_at: Option<Timestamp>, output: Option<Value>
- **updated_at semantics:** Set on every state mutation (status transition, output/error write). Always present. Source: BC-2.12.003 PC13.
- **completed_at semantics:** Set only on terminal transition (to `completed`, `failed`, or `cancelled`); `None` in non-terminal states (`queued`, `in_progress`, `interrupted`). Operationally distinct from updated_at — provides a clean terminal-timestamp without noise from intermediate mutations. Source: F-P24-01.
- **RunStatus lifecycle:** queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted (resume via POST .../resume)
  (F-03 alignment: `requires_action` renamed to `interrupted` for HITL-parked runs; `expired` deferred — v1.0.0 uses `failed` with E-GRAPH-014 InterruptApprovalTimeout for timeout-expired runs; a dedicated `expired` state may be added in a future version)
- **Relationships:** Run belongs-to Thread and Assistant. Run 1→N StreamEvent emitted. Run 0→N Interrupt.

### CronSchedule
A recurring proactive run trigger registered on an Assistant.
- **Fields:** cron_id: Uuid, assistant_id: Uuid, schedule: CronExpression, config: RunnableConfig, enabled: bool, last_fired_at: Option<Timestamp>
- **last_fired_at semantics:** Set when the most recent schedule firing completes Run creation; `None` until the first firing. Exposed in `GET /schedules/{cron_id}` response per BC-2.12.004 PC3.
- **Behavior:** Each firing creates a new Run with a fresh session (no prior thread context unless explicitly configured). Corresponds to LangGraph Platform "crons."

### Interrupt
A suspended execution point within a Run, awaiting an external ResumeValue.
- **Fields:** interrupt_id: Uuid, run_id: Uuid, node_name: NodeName, scratchpad: Option<Value>, created_at: Timestamp
- **Invariant (DI-003):** Interrupts are consumed in strict FIFO order. The interrupted node re-executes from the start of its super-step with the dequeued resume value.
- **Relationships:** Interrupt belongs-to Run. Interrupt 0——1 pending ResumeValue.

### ResumeValue
The external value injected to resume a pending Interrupt.
- **Fields:** interrupt_id: Uuid, value: Command
- **Command variants:** `Command::Resume(value: Value)`, `Command::Goto(node: NodeName)`
- **Invariant (DI-003):** Delivery is strictly FIFO; injection into an empty interrupt queue returns `Err(NoActiveInterrupt)`.

---

## Policy / Governance Domain

### BudgetPolicy
A composable allow/escalate/deny policy evaluated against token and cost tallies for a Run.
- **Fields:** token_ceiling: Option<u64>, cost_ceiling_usd: Option<Decimal>, on_ceiling: PolicyOutcome (Allow | Escalate | Deny)
- **Composition:** Policies form a chain; first Deny outcome wins. Composable via the `BudgetPolicy` trait.
- **Source:** D17-Q4, HS-4/HS-9, domain-b dark-factory.

### EvidenceJournal
Append-only log of BudgetPolicy evaluations and usage events for a single Run.
- **Fields:** run_id: Uuid, entries: Vec<EvidenceEntry>
- **EvidenceEntry fields:** timestamp, tokens_used: u64, cost_usd: Decimal, policy_outcome: PolicyOutcome, node_name: NodeName
- **Invariant:** Append-only — no entry may be modified or deleted after writing.

### ProvenanceTag
Metadata attached to content at an ingress boundary, recording its origin.
- **Fields:** boundary_type: BoundaryType (ToolResult | RAGRetrieval | MemoryIngress), ingress_id: Uuid, sequence_position: usize
- **Note (BC-2.11.001 EC-004):** BoundaryType covers exactly ToolResult, RAGRetrieval, and MemoryIngress. User messages and model scratch-pad do not receive a ProvenanceTag and do not traverse the guardrail path.
- **Relationships:** ProvenanceTag attached to every content unit at an ingress boundary before GuardrailHook fires or the content is forwarded to model context (BC-2.11.001 PC1–PC3).

### GuardrailHook
A registered callable that validates content at an ingress boundary before model context entry.
- **Callable:** `evaluate(content: IngressContent, provenance_tag: ProvenanceTag) → GuardrailResult` — authority: interface-definitions.md §GuardrailHook, BC-2.11.002 PC1.
- **GuardrailResult variants:** `Pass`, `Fail { reason: String, severity: GuardrailSeverity }`, `Transform { new_content: IngressContent }` — authority: BC-2.11.002 PC2–PC4.
- **Transform same-boundary rule:** `new_content` must be the same `IngressContent` variant as the evaluated content (ToolResult stays ToolResult, RagChunk stays RagChunk, MemoryItem stays MemoryItem); the inner payload may change freely — e.g. a different `ContentBlock` variant within `ToolResult` is permitted (BC-2.11.002 EC-003). Cross-boundary transforms are not authorized.
- **GuardrailSeverity values:** Critical (run transitions to `failed`; inference halted) | High | Medium | Low (error block substituted; run continues) — BC-2.11.002 INV-3, BC-2.11.005 PC4/PC5.
- **Invariant (DI-012):** There is no code path through which ToolResult, RAG, or memory content bypasses a registered GuardrailHook before entering the model context.

---

## Provider Domain

### ProviderClient
A connection to a model provider implementing the ChatModel Runnable interface.
- **Fields:** provider: ProviderId (openai | anthropic | ollama | …), model_id: String, credentials: ApiKey (newtype), config: ProviderConfig
- **Architecture:** Standalone SDK crate split (HS-6/D17-Q5): `ferrochain-<provider>-sdk` owns the wire client; `ferrochain-<provider>` is the Runnable adapter.
- **Invariant (DI-010):** ApiKey implements `Debug` → `"<redacted>"`. No `#[derive(Serialize)]`. No `Deref<Target = str>`.

### FerrochainError
The 2D error type for all ferrochain crates.
- **Fields:** component: FerrochainComponent (enum covering all ferrochain crate names), category: ErrorCategory (Authentication | Validation | RateLimit | Timeout | Transport | Internal | Durability | Policy | Tool | Concurrency | Security | Tenancy), retry_hint: RetryHint (Never | Maybe | Later(Duration)), code: String (wire representation; Rust: `&'static str` per api-surface.md — e.g. `"E-CORE-001"`; fixed F-P25-03 from incorrect `u32`), message: String, source: Option<Box<dyn StdError>>
- **Source:** CONFLICT-6 — adk-rust P-01/P-04 adopted; Python exception hierarchy does not translate to Rust.
- **RFC-7807:** FerrochainError supports serialization to RFC-7807 Problem Details JSON for HTTP error responses.

### MCPTool
A Tool whose schema and invocation semantics are discovered from an external MCP server.
- **Fields:** server_id: String, tool_name: String, description: String, input_schema: JsonSchema, transport: MCPTransport (Stdio | HTTP | WebSocket)
- **Behavior:** MCPTool implements the Tool Runnable interface. ToolResult produced by MCPTool is always tagged as untrusted ingress.
- **Error:** Bare ToolException from MCP server must be preserved and wrapped as `FerrochainError { category: TOOL, … }` (DEC-012).

---

## Relationships Summary (This Section)

```
Thread 1——N Run
Thread 1——N Checkpoint (cross-reference to entities-graph.md)
Run belongs-to Thread and Assistant
Run 0——N Interrupt
Run 0——N StreamEvent
Interrupt 0——1 pending ResumeValue
Assistant 1——N Run
CronSchedule belongs-to Assistant
EvidenceJournal belongs-to Run (1——1)
BudgetPolicy is injected into RunnableConfig (0——1)
GuardrailHook 0——N registered on IngressBoundary
ProviderClient implements ChatModel (Runnable)
MCPTool implements Tool (Runnable)
FerrochainError emitted by all ferrochain crates
```

## Cross-Section Relationships

- `Node` (entities-graph.md) invokes `Tool` (entities-graph.md) → produces `ToolResult` → `GuardrailHook` fires → content enters `Message` (entities-graph.md)
- `Run` (this section) uses `CheckpointSaver` (entities-graph.md) via `thread_id`
- `ProviderClient` (this section) produces `Message` (entities-graph.md) containing `ContentBlock`
