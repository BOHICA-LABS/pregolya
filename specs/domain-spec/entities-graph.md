---
document_type: domain-spec-section
level: L2
section: entities-graph
version: "1.12"
status: active
producer: business-analyst
timestamp: 2026-07-25T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "148b6a2"
traces_to: L2-INDEX.md
decisions: [D11, D17, D21, D23]
changelog:
  - "v1.12 (F-P171a-14/burst-273/2026-07-25): Fix HITL Approval Hook Domain intro — dependency-kind word corrected 'runtime' → 'compile-time' (corroborating carriers: ADR-018 §Decision 1 'cross-crate compile-time consumer', ADR-020 §Decision 1 'does NOT depend on ferrochain-graph at compile time', dependency-graph.md crate-DAG annotation 'no ferrochain-graph compile-time dep'). Date-monotonicity repair: v1.9 changelog date 2026-07-22 → 2026-07-23 (burst-242; corroborating carrier: api-surface.md v1.9 burst-242/2026-07-23). TD-VSDD-060 temporal-neighbor sweep: no additional inversions found in this file."
  - "v1.11 (F-P170-16/burst-272/2026-07-25): Fix HITL Approval Hook Domain intro — retire stale ActionRisk location claim 'ferrochain-graph::hitl alongside ActionRisk'. ActionRisk relocated to ferrochain-core (core::action_risk); ferrochain-graph::hitl re-exports it. HITL hook entities and RiskGatePolicy remain in ferrochain-graph::hitl. Placement rationale narrowed to hook types only. TD-VSDD-060 sweep: sole ActionRisk location claim in this file."
  - "v1.10 (2026-07-24): Fix burst 252 BA — ADR-019 v1.4 compaction type canon applied. CompactionTrigger: `OnWatermark { fraction: f32 }` → `f64`; predicate `<` → `<=` (non-strict; strict < cannot fire at fraction=1.0); OnMessageCount/OnTokenCount descriptors → 'reaches or exceeds' phrasing. CompactionSummary fields: `compacted_range: RangeInclusive<usize>` → flat `compacted_start: usize, compacted_end: usize`; Application: `messages[compacted_range]` → `messages[compacted_start..=compacted_end]`; CompactionEvent struct updated to flat fields. Relationships Summary updated to flat-field form. TD-VSDD-060 sweep: zero compacted_range / RangeInclusive / fraction: f32 occurrences remain in this file's body text (changelog historical entries exempt)."
  - "v1.9 (2026-07-23): Fix burst 242 BA residual sweep — Command notation: 3 enum-variant form occurrences of `Command::Resume(PreToolDecision)` corrected to struct kwarg form `Command(resume=PreToolDecision)` per BC-2.05.004/F-P120-01 adjudication. Sites: §PreToolDecision PendingHumanApproval bullet, §ToolApprovalRequest Note, Relationships Summary. TD-VSDD-060 sweep: zero Command:: enum-form occurrences remain in this file's body text."
  - "v1.8 (2026-07-23): Fix burst-241 F-P141-01 (false-closure) — CompactionSummary §Application: genuinely apply the rename trigger_tokens_remaining → tokens_remaining_after. The v1.7 changelog entry claimed this rename was already applied ('sole occurrence') but the body retained the stale field name `trigger_tokens_remaining`. v1.7 was a false-closure; this entry is the genuine fix. TD-VSDD-060 sibling sweep: zero trigger_tokens_remaining occurrences remain in domain-spec/ body text (changelog historical entries and out-of-scope BC/ADR files exempted)."
  - "v1.7 (2026-07-22): Fix burst-234 BA sibling-sweep — CompactionSummary §Application: renamed CompactionEvent field trigger_tokens_remaining → tokens_remaining_after (canonical name per BC-2.10.006 v1.1 burst-233, ADR-019 Decision 3 v1.2 burst-234). TD-VSDD-060 sweep: sole occurrence; no other domain-spec files affected."
  - "v1.6 (2026-07-22): D23 entity additions (burst-230) — new section '## HITL Approval Hook Domain': PreToolCallHook, PreToolDecision, ToolCallPreview, ToolApprovalRequest (ferrochain-graph::hitl, ADR-018). New section '## Context Compaction Domain': CompactionTrigger, CompactionPolicy, ConversationSnapshot, CompactionSummary (ferrochain-core::budget + graph::budget, ADR-019). Tool entity updated: first-party subtypes from SS-23 added (ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, BashTool, GrepTool). Relationships Summary extended. D23 added to decisions list."
  - "v1.5 (2026-07-21): F-P131-05 adjudication (burst-226) — PromptValue entity: MessageProvenance field renamed tag: Option<ProvenanceTag> → highest_trust_level: Option<TrustLevel>; Invariant updated from '.tag is Untrusted' to '.highest_trust_level is Some(TrustLevel::Untrusted)'. TrustLevel entity added to Retrieval and Serialization Domain (ferrochain-prompts: prompts::template; 3 variants: Untrusted | UserInput | Trusted; severity ordering Untrusted > UserInput > Trusted; disambiguation from ProvenanceTag; authority ADR-015 §Decision 3 + CAP-022/023). Relationships Summary updated: ProvenanceTag line → TrustLevel. TD-VSDD-060 sibling sweep: no other ProvenanceTag trust-variant residue in this file."
  - "v1.4 (2026-07-20): D21 second-half entity additions — VectorStore (ferrochain-vectorstores, ADR-014), Embeddings (ferrochain-core core::embeddings, ADR-017), MetadataFilter (ferrochain-vectorstores, ADR-014), SearchType (ferrochain-vectorstores, ADR-014). Added to '## Retrieval and Serialization Domain'. Relationships Summary extended."
  - "v1.3 (2026-07-20): D21 entity additions — Document (ferrochain-core core::documents, ADR-014), PromptValue (ferrochain-prompts, ADR-015), Serialized (ferrochain-core core::serializable, ADR-016). New section '## Retrieval and Serialization Domain' added. Relationships Summary extended. D21 added to decisions list."
  - "v1.2 (F-P121-01/02, fix burst 124, 2026-07-19): ContentBlock: replace 5-variant drifted list (Text/ImageUrl/ToolUse/ToolResult/Document) with canonical 14-variant reference per BC-2.01.001 PC2; ToolCall fields {id,name,args} per BC-2.08.002/013; NonStandard DI-008 passthrough noted; tool results → ToolMessage per BC-2.09.002. Tool entity DI-012 invariant: 'ToolResult ContentBlocks' → canonical ToolMessage/IngressContent::ToolResult phrasing. Message roles: expand closed 4-variant (Human|AI|System|Tool) to note Function legacy (BC-2.01.002 PC7), Chat arbitrary-role, Remove history-control (BC-2.01.002 EC-005). Relationships summary: 'Tool returns ToolResult (ContentBlock subtype)' → ToolMessage per BC-2.09.002. TD-VSDD-060 sweep: all ContentBlock-depicting sites in this file fixed."
  - "v1.1 (2026-07-17): Provenance-integrity fix — STATE.md removed from inputs (D11/D17 decisions and CONFLICT-*/NE-* entity sources baked at authoring time from COMPARATIVE-ASSESSMENT.md, not live state); input-hash recomputed."
---

# Domain Entities — Core Primitives, Graph, and Checkpoint

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> Server, Policy/Governance, and Provider entities are in `entities-server.md`.

---

## Core Primitives

### ContentBlock
Typed union of content variants a message can carry.
- **Variants (BC-2.01.001 PC2 — 14 canonical):** Text, Reasoning, ToolCall, ToolCallChunk, InvalidToolCall, Image, Video, Audio, PlainText, File, ServerToolCall, ServerToolCallChunk, ServerToolResult, NonStandard. `ToolCall` carries `{ id, name, args }` (BC-2.08.002/BC-2.08.013). `NonStandard { value: Value }` is the DI-008 load-bearing passthrough for unrecognized provider-specific blocks.
- **Tool results:** Tool invocation results are carried as `ToolMessage` (BC-2.09.002), not as a ContentBlock variant. Tool result content passes `GuardrailHook` as `IngressContent::ToolResult(ContentBlock)` before entering the model context (DI-012).
- **Note:** No bare String message content; ContentBlock is the only way to attach content to a Message.

### Message
One turn in a conversation, always typed by role (BC-2.01.002).
- **Variants:** 4 primary — `Ai(AiMessage)`, `Human(HumanMessage)`, `System(SystemMessage)`, `Tool(ToolMessage)`; plus legacy `Function(FunctionMessage)` (type tag `"function"`, BC-2.01.002 PC7), arbitrary-role `Chat` discriminant, and `Remove(RemoveMessage { id })` history-control token (BC-2.01.002 EC-005, load-bearing).
- **Key fields (per variant):** content: Vec<ContentBlock>, id: Option<String>; AiMessage additionally carries tool_calls: Vec<ToolCall>, usage_metadata: Option<UsageMetadata>; ToolMessage requires tool_call_id: String (not Option).
- **Relationships:** Message 1→N ContentBlock. Thread 1→N Message.
- **Note:** Role drives how the message is placed in the model's context window.

### Runnable
The universal computation interface — anything that can be invoked asynchronously.
- **Interface:** `invoke(input, config) → Output`, `stream(input, config) → Stream<StreamEvent>`, `batch(inputs, config) → Vec<Output>`
- **Subtypes:** ChatModel, PromptTemplate, OutputParser, Tool, Chain (RunnableSequence), StateGraph, Node
- **Composition:** `A | B` produces a RunnableSequence; this is the primary composition primitive.
- **Relationships:** Node wraps a Runnable. ProviderClient implements ChatModel (a Runnable subtype).

### Tool
A Runnable with an associated schema — name, description, and JSON Schema for input.
- **Fields:** name: String, description: String, input_schema: JsonSchema, runnable: Runnable
- **Subtypes:** FunctionTool (Rust async fn), MCPTool (from MCP server), StructuredTool;
  and first-party (SS-23 / ADR-020): ReadFileTool (ReadOnly), WriteFileTool (High), EditFileTool
  (High, exact-match), ListDirTool (ReadOnly), BashTool (High, non-lowerable ≥ Medium floor,
  VP-013), GrepTool (ReadOnly, in-process regex).
- **Invariant (DI-012):** Content produced by any Tool returns as a `ToolMessage` (BC-2.09.002) and is untrusted ingress; it passes `GuardrailHook` as `IngressContent::ToolResult(ContentBlock)` before entering the model context.

---

## Graph Domain

### Channel
Named state slot with a reducer function. Defines one dimension of GraphState.
- **Subtypes and semantics:**
  - **LastValue:** Replace on write; concurrent write from two tasks in the same super-step → InvalidUpdateError (DI-001)
  - **Append:** Accumulate Vec; no conflict possible
  - **BarrierValue:** Waits for N writers to write before releasing; blocks until count reached
  - **NamedBarrierValue:** BarrierValue keyed by name; behavior when fewer-than-N writers arrive is BC-specified (DEC-003)
  - **EphemeralValue:** Value present only during the super-step it was written; cleared after ReducersApplied (DEC-004)
  - **BinaryOperatorAggregate:** User-supplied associative fold function

### GraphState
Snapshot of all channel values at a point in execution.
- **Fields:** values: Map<ChannelName, ChannelValue>
- **Relationships:** GraphState 1→N ChannelValue (one per Channel registered in the graph). Checkpoint wraps GraphState.
- **Note:** GraphState is not a user-defined struct; it is the composed value of all Channels.

### Node
A named Runnable registered in a StateGraph.
- **Fields:** name: NodeName (unique within the graph), runnable: Runnable
- **Behavior:** Reads a subset of GraphState as its typed input; returns a partial state update (Map<ChannelName, Value>) or a Command
- **Invariant (DI-002):** Node output written to CheckpointSaver via put_writes before the next super-step.

### Edge
A directed transition between two Nodes.
- **Subtypes:**
  - **Direct:** Always fires after source node completes
  - **Conditional:** Fires to different targets based on node output value (enables branch routing)
  - **SendEdge:** Carries a Send(node_name, state_payload) to create a new PregelTask for a target node at runtime (dynamic fan-out)

### StateGraph
The immutable definition of an agent graph (compiled before execution).
- **Fields:** nodes: Map<NodeName, Node>, channels: Map<ChannelName, Channel>, edges: Vec<Edge>, entry_point: NodeName, finish_points: Vec<NodeName>
- **Relationships:** StateGraph 1→N Node, 1→N Channel, 1→N Edge
- **Lifecycle:** Must be compiled (validated + type-checked) before execution; produces a CompiledGraph.

### PregelTask
A scheduled unit of node execution within a single super-step.
- **Fields:** id (content-addressed from task identity = node_name + incoming channel version vector), node_name, input: PartialState, writes: Vec<ChannelWrite>
- **Invariant (DI-002):** Output stored via put_writes before the next super-step begins.
- **Invariant (DI-001):** All PregelTask writes reduced in deterministic task-identity order.

---

## Checkpoint Domain

### Checkpoint
A serialized snapshot of GraphState + metadata at a super-step boundary.
- **Fields:** checkpoint_id: LogicalClockId (monotonically increasing, DI-004), thread_id, checkpoint_ns: NamespaceId, parent_checkpoint_id: Option<LogicalClockId>, state: GraphState, metadata: CheckpointMetadata, pending_sends: Vec<Send>
- **Wire format:** msgpack [D11.2 locked]
- **Relationships:** Checkpoint 1→1 Thread (owner). Checkpoint 0→1 parent Checkpoint (fork lineage via parent_checkpoint_id).

### PendingWrite
A task output recorded but not yet reduced into GraphState.
- **Fields:** task_id, channel: ChannelName, value: ChannelWrite
- **Relationships:** Checkpoint 0→N PendingWrite.

### CheckpointTuple
The full unit returned by CheckpointSaver.get_tuple: checkpoint + metadata + pending writes.
- **Fields:** config: RunnableConfig, checkpoint: Checkpoint, metadata: CheckpointMetadata, parent_config: Option<RunnableConfig>, pending_writes: Vec<PendingWrite>

### CheckpointSaver
Repository interface for checkpoint persistence.
- **Operations:** `get_tuple(config) → Option<CheckpointTuple>`, `put_writes(config, writes)`, `put(config, checkpoint, metadata)`, `list(config, filter) → Iterator<CheckpointTuple>`
- **Backends:** InMemory (default in tests), SQLite (default in production), Postgres (stretch)
- **Invariant (DI-005):** Every operation uses the triple (thread_id, checkpoint_ns, checkpoint_id) — no bare thread_id path.

---

## Retrieval and Serialization Domain

### Document
Pure data carrier returned by any Retriever implementation.
- **Fields:** page_content: String (the text content), metadata: Map<String, Value> (arbitrary
  key-value annotations — source URL, title, chunk index, etc.), id: Option<String> (stable
  document ID assigned by the VectorStore; None if not yet persisted)
- **Crate:** ferrochain-core, module `core::documents`; no I/O. Pure Core classification.
- **Invariant (DI-012):** Document values returned by any `Retriever` and entering graph context
  pass the `BoundaryType::RAGRetrieval` guardrail (BC-2.11.001) before being consumed by a
  graph node. This seam fires unconditionally.
- **Note:** Corresponds to LangChain's `Document { page_content, metadata }` type in
  langchain_core.documents.base (semport Corpus 1). `id` field is ferrochain's addition for
  VectorStore-managed document identity.

### PromptValue
Rendered output of a PromptTemplate or ChatPromptTemplate invocation; the carrier that
delivers a formatted prompt to a chat model call while preserving provenance.
- **Fields:** messages: Vec<(Message, MessageProvenance)> where MessageProvenance carries:
  highest_trust_level: Option<TrustLevel> (highest-severity TrustLevel from variables
  substituted into this message; None if no variables were substituted or all used
  developer-supplied values with no explicit trust_level), slot_trust_policy: SlotTrustPolicy
  (TrustAll | TrustRequired, inherited from the template slot)
- **Crate:** ferrochain-prompts, module `prompts::prompt_value`
- **Conversion:** `.into_messages()` extracts `Vec<Message>` for direct use in a model call;
  provenance data is discarded after this conversion.
- **Invariant:** If any MessageProvenance.highest_trust_level is Some(TrustLevel::Untrusted)
  and the corresponding slot policy is TrustRequired, `format_messages()` raises E-TMPL-001
  (SECURITY) before PromptValue is produced — a PromptValue with a
  TrustRequired/TrustLevel::Untrusted combination never exists.
- **Note:** Corresponds to LangChain's `PromptValue` type; ferrochain adds per-message
  MessageProvenance for security-critical provenance threading (ADR-015 Decision 3).
  `TrustLevel` (see §TrustLevel below) is the SS-18-local trust classifier — distinct from
  `ProvenanceTag` (SS-11 ingress-boundary audit struct, entities-server.md §ProvenanceTag).

### TrustLevel
Template-variable trust classifier for the SS-18 template composition layer; distinct from
and independent of `ProvenanceTag` (SS-11 ingress-boundary audit struct).
- **Variants (severity ordering: Untrusted > UserInput > Trusted):**
  - `Untrusted` — content derived from an external/adversarial source (e.g., a RAG retrieval
    result or an MCP tool output); substituting into a `TrustRequired` slot raises E-TMPL-001
    (SECURITY/InjectionAttempt) at render time
  - `UserInput` — content from a human operator; acceptable in `TrustRequired` slots when
    user trust is granted to the human principal
  - `Trusted` — developer-controlled content; always acceptable in any template slot
- **Crate:** ferrochain-prompts, module `prompts::template`
- **Usage:** `TemplateVar.trust_level: Option<TrustLevel>` — `None` is treated as `Trusted`
  (developer-supplied literal; no external origin). `MessageProvenance.highest_trust_level:
  Option<TrustLevel>` carries the maximum-severity TrustLevel across all variables substituted
  into a single message (`Untrusted > UserInput > Trusted` ordering). Only `Untrusted` triggers
  E-TMPL-001; `UserInput` and `Trusted` (or None) are always accepted.
- **Distinct from ProvenanceTag (ADR-015 §Decision 3):** `ProvenanceTag` (entities-server.md
  §ProvenanceTag) is the SS-11 ingress-boundary audit struct with fields `boundary_type:
  BoundaryType`, `ingress_id: Uuid`, `sequence_position: usize`. It records WHICH ingress event
  produced content and WHERE within that event. `TrustLevel` is the SS-18 composition-layer
  classifier for template-variable trust at render time. When a developer derives a template
  variable from a RAG result (which arrived at the ingress boundary with a ProvenanceTag), they
  translate that into `TrustLevel::Untrusted` for the composition step. The ingress ProvenanceTag
  record is captured in the guardrail audit log at ingress time and need not be threaded through
  template composition.
- **Authority:** ADR-015 §Decision 3; CAP-022/CAP-023.

### Serialized
The lc-JSON wire envelope for types implementing `LcSerializable`. The sum type that
represents a value in lc-JSON format.
- **Variants:**
  - `Constructor { lc: u8, id: Vec<String>, kwargs: Map<String, Value> }` — a constructable
    type; `id` is the namespace path; `kwargs` contains constructor arguments with credential
    fields stripped (lc_secrets() applied before serialization)
  - `Secret { lc: u8, id: Vec<String> }` — a credential-carrying type, serialized without
    value for safety (DI-010)
  - `NotImplemented { lc: u8, id: Vec<String>, repr: Option<String> }` — a type that is
    known but not serializable in this context
- **Crate:** ferrochain-core, module `core::serializable`
- **Relationships:** Produced by `LcSerializable::serialize()`. Consumed by `Reviver::revive()`.
  The Reviver looks up `Constructor.id` in the inventory-based `LcEntry` registry.
- **Note:** Corresponds to LangChain's `Serialized` TypedDict family in langchain_core.load.
  ferrochain's `Serialized` is a proper Rust enum (serde `#[serde(tag="type")]`) rather than
  duck-typed dicts, providing exhaustive match coverage.

### VectorStore
The abstract document-index trait; the dyn-compatible contract for all embedding-backed
document stores (ADR-014 Decision 2).
- **Instance methods (all &self, dyn-compatible):** add_texts (returns Vec<String> IDs),
  similarity_search(query, k), similarity_search_with_score(query, k), max_marginal_relevance_search
  (query, k, fetch_k, lambda_mult), delete(ids), as_retriever() → VectorStoreRetriever (concrete,
  non-opaque return — required for VectorStore dyn-compat)
- **Static constructors:** NOT on VectorStore trait. Live on `VectorStoreFactory` (separate
  Sized-bounded trait) to preserve E0038-safe `Arc<dyn VectorStore>`.
- **Crate:** ferrochain-vectorstores, module `vectorstores::store`
- **Relationships:** VectorStore 1→N Document (stores/indexes). VectorStoreRetriever wraps
  VectorStore. InMemoryVectorStore is the reference impl.
- **Note:** Corresponds to `VectorStore` abstract base class in LangChain v1
  (`langchain_core.vectorstores.base`). ferrochain separates factory methods onto
  `VectorStoreFactory` for Rust dyn-compat; Python does not have this constraint.

### Embeddings
The abstract text-to-vector conversion trait; the dyn-compatible seam used by VectorStore
backends and ferrochain-memory semantic search (ADR-017 Decision 1).
- **Methods:** `embed_documents(texts: Vec<String>) → Result<Vec<Vec<f32>>>` (batch),
  `embed_query(text: String) → Result<Vec<f32>>` (single)
- **Dimensionality contract:** all returned vectors same length; batch.len() == texts.len();
  embed_query length == embed_documents inner length. Violation → E-EMBED-001.
- **Crate:** ferrochain-core, module `core::embeddings`
- **Relationships:** InMemoryVectorStore holds Arc<dyn Embeddings>. ferrochain-memory may
  hold Arc<dyn Embeddings> for semantic search. EmbeddingsOpenAI and EmbeddingsOllama implement
  Embeddings (first-party v1 impls). ferrochain-anthropic has NO Embeddings impl (v1).
- **Note:** Corresponds to `Embeddings` abstract base class in LangChain v1
  (`langchain_core.embeddings.base`). ferrochain uses `Vec<f32>` not ndarray (semport §8).

### MetadataFilter
An optional pre/post-filter applied to VectorStore similarity searches based on Document
metadata field values (ADR-014 Decision 2 §Metadata filter surface).
- **Fields:** filters: Vec<FilterClause>
- **FilterClause variants (#[non_exhaustive]):**
  - `Eq { key: String, value: Value }` — metadata field equals value
  - `Ne { key: String, value: Value }` — metadata field not equal
  - `In { key: String, values: Vec<Value> }` — metadata field in set
- **Crate:** ferrochain-vectorstores, module `vectorstores::filter`
- **Dispatch:** native backend adapters dispatch MetadataFilter to the server as a pre-filter;
  InMemoryVectorStore applies it as a post-filter over the similarity result set.
- **Extensibility:** both MetadataFilter and FilterClause are `#[non_exhaustive]`;
  future clause types (Gte, Lt, Contains) can be added without breaking existing match arms.
- **Note:** No direct LangChain v1 equivalent as a named type (filtering is handled
  per-backend in Python). ferrochain promotes it to a named first-class domain type.

### SearchType
The VectorStoreRetriever retrieval mode selector; determines which VectorStore search method
fires when `get_relevant_documents` is called.
- **Variants:**
  - `Similarity` (default) — standard k-nearest similarity search
  - `SimilarityScoreThreshold { score_threshold: f32 }` — filter results below the score floor
  - `Mmr` — Maximal Marginal Relevance diversity-aware search using fetch_k + lambda_mult config
- **Crate:** ferrochain-vectorstores, module `vectorstores::retriever`
- **Relationships:** VectorStoreRetriever holds a SearchType. SearchType selects among
  VectorStore::similarity_search, similarity_search_with_score, and max_marginal_relevance_search.
- **Note:** Corresponds to `SearchType` enum in LangChain v1
  (`langchain_core.vectorstores.base`); ferrochain's enum is identical in semantics.

---

## HITL Approval Hook Domain

> D23 additions (ADR-018). HITL hook entities (`PreToolCallHook`, `PreToolDecision`,
> `ToolCallPreview`, `ToolApprovalRequest`) and `RiskGatePolicy` live in
> `ferrochain-graph::hitl`. Placement rationale: no dependency-inversion need — no crate
> requires these hook types without depending on ferrochain-graph (ADR-018 Decision 1).
> `ActionRisk` lives in `ferrochain-core` (`core::action_risk`); `ferrochain-graph::hitl`
> re-exports it (ferrochain-tools needs `ActionRisk` without a ferrochain-graph compile-time dep).

### PreToolCallHook
Async hook invoked by the graph engine immediately before every tool dispatch.
- **Interface:** `async fn pre_invoke(&self, preview: &ToolCallPreview, run_ctx: &RunContext) → PreToolDecision`
- **Registration:** `GraphConfig.pre_tool_hook: Option<Arc<dyn PreToolCallHook>>`
- **Default impl:** `AlwaysApprovePolicy` — always returns Approve without I/O; existing graphs unaffected.
- **Crate:** ferrochain-graph, module `graph::hitl`
- **Note:** Graph-scoped (not run-scoped): governs all runs on the graph, consistent with how `RiskGatePolicy` applies. ADR-018 Decision 2.

### PreToolDecision
The decision type returned by `PreToolCallHook::pre_invoke`; determines the tool dispatch outcome.
- **Variants (`#[non_exhaustive]`):**
  - `Approve` — proceed to tool execution unchanged
  - `Deny { reason: String }` — construct `ToolOutput::Error(reason)`; tool is NOT invoked (fail-closed; VP-011 Kani candidate)
  - `Edit { modified_args: serde_json::Value }` — replace tool_args with modified_args; proceed (engine validates modified_args is a valid JSON object before invocation)
  - `PendingHumanApproval { prompt: Option<String> }` — suspend via `interrupt()` (BC-2.05.001 machinery reused); on `Command(resume=PreToolDecision)` the decision is applied; hook is NOT re-called on the resumed dispatch ("skip-hook-on-resume" invariant — PO BC obligation for SS-05 extension)
- **Crate:** ferrochain-graph, module `graph::hitl`
- **Invariant:** `Deny` is fail-closed — the tool is never invoked when Deny is returned, regardless of code path. VP-011 Kani candidate.

### ToolCallPreview
Read-only snapshot of a pending tool invocation passed to `PreToolCallHook::pre_invoke`.
- **Fields (`#[non_exhaustive]`):** `tool_name: String`, `tool_args: serde_json::Value`, `action_risk: Option<ActionRisk>`
- **Crate:** ferrochain-graph, module `graph::hitl`
- **Note:** `action_risk` populated from `#[tool(action_risk = ...)]` macro annotation (ADR-018 Decision 6 / BC-2.08.010 amendment). `None` if tool was registered without an action_risk annotation.

### ToolApprovalRequest
Interrupt payload serialized to the checkpoint when `PreToolDecision::PendingHumanApproval` is returned.
- **Fields:** `preview: ToolCallPreview`, `prompt: Option<String>`
- **Crate:** ferrochain-graph, module `graph::hitl`
- **Note:** Serialized via msgpack to the existing checkpoint format (ADR-002). Survives process restart identically to standard BC-2.05.001 interrupts. Delivered via `Command(resume=PreToolDecision)` when the human provides their decision.

---

## Context Compaction Domain

> D23 additions (ADR-019). Type and trait definitions live in `core::budget` (definitions-only
> per ADR-009 Option 3 pattern — same as BudgetPolicy). Dispatch logic lives in `graph::budget`.

### CompactionTrigger
Configuration type that controls when the BudgetEngine initiates proactive context compaction.
- **Variants (`#[non_exhaustive]`):**
  - `Disabled` — no proactive compaction (default; backward compatible; OnCeiling behaviour unchanged)
  - `OnWatermark { fraction: f64 }` — trigger when `tokens_remaining / ceiling <= (1.0 - fraction)`; e.g. fraction=0.8 = trigger at 80% budget consumed; non-strict `<=` (strict `<` cannot fire at fraction=1.0); f64 arithmetic. VP-012 Kani candidate (pure arithmetic).
  - `OnMessageCount { count: usize }` — trigger when active message count reaches or exceeds threshold
  - `OnTokenCount { tokens: u64 }` — trigger when cumulative conversation token count reaches or exceeds threshold
- **Crate:** ferrochain-core, module `core::budget`; field of `BudgetConfig`
- **Note:** `Disabled` default means all existing graphs are unaffected (ADR-019 Decision 2).

### CompactionPolicy
Async trait that produces a `CompactionSummary` from a `ConversationSnapshot`.
- **Interface:** `async fn compact(&self, snapshot: &ConversationSnapshot, run_ctx: &RunContext) → Result<CompactionSummary, FerrochainError>`
- **Default impl:** `DefaultSummarizationPolicy` — prompts the model to produce a concise summary (same mechanism as `OnCeiling::Summarize`)
- **Registration:** `BudgetConfig.compaction_policy: Option<Arc<dyn CompactionPolicy>>` (None = DefaultSummarizationPolicy)
- **Crate:** ferrochain-core, module `core::budget`
- **Note:** Custom impls MAY also write CompactionSummary to MemoryStore (CAP-017) as project knowledge — the framework imposes no constraint on what `compact()` does beyond returning CompactionSummary (ADR-019 Decision 5 additive coupling).

### ConversationSnapshot
Read-only slice of recent conversation history assembled by the BudgetEngine from checkpoint FTS (BC-2.04.008).
- **Fields (`#[non_exhaustive]`):** `turns: Vec<(usize, Message)>` (ordered turn-index / Message pairs selected for compaction), `token_estimate: u64`
- **Crate:** ferrochain-core, module `core::budget`
- **Note:** Passed to `CompactionPolicy::compact()` as the compaction input. BudgetEngine selects which turns to include based on the active CompactionTrigger variant.

### CompactionSummary
Output produced by a `CompactionPolicy::compact()` call; applied to the active message window.
- **Fields (`#[non_exhaustive]`):** `summary_text: String` (injected as a SystemMessage), `compacted_start: usize` (first turn index replaced), `compacted_end: usize` (last turn index replaced, inclusive; slice form `messages[compacted_start..=compacted_end]`)
- **Crate:** ferrochain-core, module `core::budget`
- **Application:** BudgetEngine replaces `messages[compacted_start..=compacted_end]` with `SystemMessage(summary_text)` in the active conversation window. Original checkpoint records are NOT deleted (BC-2.04.001 immutable checkpoint history). A `CompactionEvent { compacted_start, compacted_end, summary_token_count, tokens_remaining_after }` is appended to EvidenceJournal; a `compaction_event` streaming event (15th variant) is emitted.

---

## Relationships Summary (This Section)

```
StateGraph 1——N Node
StateGraph 1——N Channel
StateGraph 1——N Edge
Node wraps Runnable
Runnable subtypes: ChatModel, Tool, Chain, StateGraph, Node, PromptTemplate, ChatPromptTemplate
Tool first-party subtypes (SS-23): ReadFileTool, WriteFileTool, EditFileTool, ListDirTool (tools::fs); BashTool (tools::shell, VP-013); GrepTool (tools::search)
PregelTask belongs-to Node (via node_name)
Checkpoint wraps GraphState
Checkpoint 0——N PendingWrite
Checkpoint 0——1 parent Checkpoint
CheckpointSaver owns N Checkpoint
Thread 1——N Checkpoint (via thread_id)
Message 1——N ContentBlock
Tool invocation produces ToolMessage (BC-2.09.002); content passes GuardrailHook as IngressContent::ToolResult before model context entry (DI-012)
PreToolCallHook::pre_invoke fires before every tool dispatch; PreToolDecision routes → Approve / Deny / Edit / PendingHumanApproval
ToolApprovalRequest persisted to checkpoint on PendingHumanApproval; Command(resume=PreToolDecision) delivers the decision
CompactionTrigger evaluated by BudgetEngine after each super-step; on trigger → ConversationSnapshot assembled from FTS → CompactionPolicy::compact() → CompactionSummary applied to active window
CompactionSummary applied: messages[compacted_start..=compacted_end] replaced by SystemMessage(summary_text); CompactionEvent { compacted_start, compacted_end, … } appended to EvidenceJournal; compaction_event emitted (15th streaming variant)
Retriever::get_relevant_documents returns Vec<Document>; Documents entering graph context pass BoundaryType::RAGRetrieval guardrail (DI-012)
VectorStoreRetriever implements Retriever; backed by &dyn VectorStore; SearchType selects similarity vs MMR
VectorStore 1——N Document (stores/indexes); VectorStoreRetriever wraps VectorStore
InMemoryVectorStore holds Arc<dyn Embeddings> + RwLock<Vec<(Document, Vec<f32>)>>
MetadataFilter optional on similarity_search_with_filter; FilterClause::Eq/Ne/In
Embeddings::embed_documents returns Vec<Vec<f32>> (one per input); embed_query returns Vec<f32>
Embeddings dimensionality invariant: all vectors same length (E-EMBED-001 on violation)
EmbeddingsOpenAI + EmbeddingsOllama implement Embeddings; ferrochain-anthropic has NO impl
ChatPromptTemplate::format_messages produces PromptValue (Vec<(Message, MessageProvenance)>)
PromptValue carries per-message TrustLevel (MessageProvenance.highest_trust_level) from substituted variables; TrustLevel::Untrusted in a TrustRequired slot → E-TMPL-001 (ADR-015 §Decision 3)
LcSerializable::serialize produces Serialized; Reviver::revive consumes Serialized → typed value
Serialized.Constructor.kwargs has credential fields stripped (lc_secrets() / DI-010)
```
