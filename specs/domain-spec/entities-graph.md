---
document_type: domain-spec-section
level: L2
section: entities-graph
version: "1.4"
status: active
producer: business-analyst
timestamp: 2026-07-20T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "efb7ba1"
traces_to: L2-INDEX.md
decisions: [D11, D17, D21]
changelog:
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
- **Subtypes:** FunctionTool (Rust async fn), MCPTool (from MCP server), StructuredTool
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
  tag: Option<ProvenanceTag> (highest-severity tag from variables substituted into this
  message; None if no variables were substituted), slot_trust_policy: SlotTrustPolicy
  (TrustAll | TrustRequired, inherited from the template slot)
- **Crate:** ferrochain-prompts, module `prompts::prompt_value`
- **Conversion:** `.into_messages()` extracts `Vec<Message>` for direct use in a model call;
  provenance data is discarded after this conversion.
- **Invariant:** If any MessageProvenance.tag is Untrusted and the corresponding slot policy
  is TrustRequired, `format_messages()` raises E-TMPL-001 (SECURITY) before PromptValue
  is produced — a PromptValue with a TrustRequired/Untrusted combination never exists.
- **Note:** Corresponds to LangChain's `PromptValue` type; ferrochain adds per-message
  MessageProvenance for security-critical provenance threading (ADR-015 Decision 3).

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

## Relationships Summary (This Section)

```
StateGraph 1——N Node
StateGraph 1——N Channel
StateGraph 1——N Edge
Node wraps Runnable
Runnable subtypes: ChatModel, Tool, Chain, StateGraph, Node, PromptTemplate, ChatPromptTemplate
PregelTask belongs-to Node (via node_name)
Checkpoint wraps GraphState
Checkpoint 0——N PendingWrite
Checkpoint 0——1 parent Checkpoint
CheckpointSaver owns N Checkpoint
Thread 1——N Checkpoint (via thread_id)
Message 1——N ContentBlock
Tool invocation produces ToolMessage (BC-2.09.002); content passes GuardrailHook as IngressContent::ToolResult before model context entry (DI-012)
Retriever::get_relevant_documents returns Vec<Document>; Documents entering graph context pass BoundaryType::RAGRetrieval guardrail (DI-012)
VectorStoreRetriever implements Retriever; backed by &dyn VectorStore; SearchType selects similarity vs MMR
VectorStore 1——N Document (stores/indexes); VectorStoreRetriever wraps VectorStore
InMemoryVectorStore holds Arc<dyn Embeddings> + RwLock<Vec<(Document, Vec<f32>)>>
MetadataFilter optional on similarity_search_with_filter; FilterClause::Eq/Ne/In
Embeddings::embed_documents returns Vec<Vec<f32>> (one per input); embed_query returns Vec<f32>
Embeddings dimensionality invariant: all vectors same length (E-EMBED-001 on violation)
EmbeddingsOpenAI + EmbeddingsOllama implement Embeddings; ferrochain-anthropic has NO impl
ChatPromptTemplate::format_messages produces PromptValue (Vec<(Message, MessageProvenance)>)
PromptValue carries per-message ProvenanceTag from substituted variables
LcSerializable::serialize produces Serialized; Reviver::revive consumes Serialized → typed value
Serialized.Constructor.kwargs has credential fields stripped (lc_secrets() / DI-010)
```
