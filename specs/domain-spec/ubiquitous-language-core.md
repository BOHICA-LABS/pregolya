---
document_type: domain-spec-section
level: L2
section: ubiquitous-language-core
version: "1.7"
status: active
producer: business-analyst
timestamp: 2026-07-22T00:00:00Z
changelog:
  - "1.7 (2026-07-22): Fix burst 242 BA residual sweep — Command notation: 1 enum-variant form occurrence of `Command::Resume(PreToolDecision)` corrected to struct kwarg form `Command(resume=PreToolDecision)` per BC-2.05.004/F-P120-01 adjudication. Site: §PreToolDecision definition block. TD-VSDD-060 sweep: zero Command:: enum-form occurrences remain in this file's body text (changelog history exempt)."
  - "1.6 (2026-07-22): D23 ubiquitous-language additions (burst-230) — new section 'D23 Additions (HITL Approval Hook, Context Compaction, and First-Party Tools)': PreToolCallHook, PreToolDecision, CompactionTrigger, CompactionPolicy, ConversationSnapshot, CompactionSummary (ADR-018/ADR-019); ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, BashTool, BashOutput, GrepTool (ADR-020 / SS-23). 13 new terms; total D23 + prior: 16 (D21) + 13 (D23) = 29 terms in this file. D23 added to decisions list."
  - "1.5 (2026-07-21): F-P131-05 adjudication (burst-226) — TrustLevel term added to D21 section (ferrochain-prompts: prompts::template; 3 variants: Untrusted | UserInput | Trusted; severity ordering Untrusted > UserInput > Trusted; distinct from ProvenanceTag; authority ADR-015 §Decision 3). D21 total terms: 15 → 16."
  - "1.4 (2026-07-20): D21 second-half ubiquitous-language additions — 6 new terms: VectorStore, InMemoryVectorStore, MetadataFilter, Embeddings, EmbeddingsOpenAI, EmbeddingsOllama. Appended to D21 section. Total D21 terms: 15."
  - "1.3 (2026-07-20): D21 ubiquitous-language additions — 9 new terms: PromptTemplate, ChatPromptTemplate, MessagesPlaceholder, FewShotPromptTemplate, LcSerializable, Reviver, Retriever, Document, VectorStoreRetriever. New section '## Prompts, Serialization, and Retrieval Terms (D21 Additions)' appended. D21 added to decisions list."
  - "1.2 (F-P121-01/02, fix burst 124, 2026-07-19): §Message: 'The four roles are: Human/AI/System/Tool' expanded to note 4 primary + legacy Function (BC-2.01.002 PC7), Chat arbitrary-role discriminant, Remove history-control token (BC-2.01.002 EC-005). §ContentBlock: replaced 5-variant drifted list (Text/ImageUrl/ToolUse/ToolResult/Document with wrong fields) with canonical 14-variant reference per BC-2.01.001 PC2; ToolCall fields {id,name,args} per BC-2.08.002/013; NonStandard DI-008 passthrough; tool results → ToolMessage per BC-2.09.002. TD-VSDD-060 sweep: only Message and ContentBlock depiction sites in this file; both fixed."
  - "1.1 (F-P120-01, fix burst 123, 2026-07-19): Correct §ResumeValue definition from 2-variant enum form 'Command::Resume(value)' to struct form aligned to BC-2.05.004: Command with independently-settable optional fields resume/update/goto/graph, combinable as compound commands (EC-001/TV-002/TV-003). TD-VSDD-060 sweep: this file:142 was the only Command-depiction site; fixed here."
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/semport/reference-manifest.md
input-hash: "c72e28a"
traces_to: L2-INDEX.md
decisions: [D2, D17, D21, D23]
---

# Ubiquitous Language — Core Primitives and Graph Terms

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> Server, Policy/Safety, Error terms and Reconciliation Table are in
> `ubiquitous-language-server.md`.

The ferrochain vocabulary for all agents. LangChain semantics are the API-surface authority
(D17 HYBRID outcome). This file covers Core and Graph terms.

---

## Core Terms

**Runnable**
The universal composition interface. Any unit of computation — a model call, a prompt,
a parser, a tool, a chain, or a compiled graph — is a Runnable. Supports `invoke`,
`stream`, and `batch`. In ferrochain, this becomes a Rust async trait. Corresponds to
`Runnable` in LangChain v1 (langchain==1.3.13 semport, Corpus 1).

**Chain**
A sequence of Runnables composed via the pipe operator (`|`). `A | B | C` passes A's output
to B, then B's output to C. In ferrochain, `|` on Runnables produces a RunnableSequence
(itself a Runnable). No separate struct; composition is the primitive. Corresponds to
`RunnableSequence` in LangChain v1.

**Message**
One turn in a conversation, always carrying a role. Four primary roles: Human (user), AI (assistant), System (system instruction), Tool (tool result turn — requires `tool_call_id`). Additionally: legacy `Function` role (type tag `"function"`, backward-compat deserialization per BC-2.01.002 PC7), arbitrary-role `Chat` discriminant, and `Remove` history-control token (removes a message by id from conversation history, BC-2.01.002 EC-005). Message content is always `Vec<ContentBlock>`. The role determines how the message is placed in the model context window.

**ContentBlock**
A typed content variant. Fourteen canonical variants per BC-2.01.001 PC2: Text, Reasoning, ToolCall, ToolCallChunk, InvalidToolCall, Image, Video, Audio, PlainText, File, ServerToolCall, ServerToolCallChunk, ServerToolResult, NonStandard. Never a bare String.
- `ToolCall` carries `{ id, name, args }` — the model's request to invoke a tool (BC-2.08.002/BC-2.08.013).
- `NonStandard { value: Value }` is the DI-008 load-bearing passthrough for unrecognized provider-specific blocks; it deserializes rather than errors.
- Tool results return as `ToolMessage` (BC-2.09.002), not as a ContentBlock variant. Tool result content is untrusted ingress: it passes `GuardrailHook` as `IngressContent::ToolResult(ContentBlock)` before entering the model context (DI-012).

**UsageMetadata**
Token accounting attached to an AI Message: `input_tokens`, `output_tokens`, `total_tokens`.
Used by BudgetPolicy evaluation and EvidenceJournal entries.

---

## Graph Terms

**StateGraph**
The immutable definition of an agent graph: nodes, channels, edges, entry point, finish
points. Corresponds to `StateGraph` in LangGraph (langgraph==1.2.9 semport, Corpus 1).
Must be compiled (type-checked, validated) before execution. The compiled form is a
CompiledGraph.

**Node**
A named Runnable registered in a StateGraph. Reads a subset of GraphState as input; returns
partial state updates (writes to one or more Channels) or a Command. Node names are unique
within a graph.

**Channel**
A named dimension of GraphState with a reducer function that determines how concurrent writes
are merged. The reducer defines the channel's semantics:
- **LastValue:** Replace; concurrent write from two tasks → `InvalidUpdateError` (DI-001)
- **Append:** Accumulate into a Vec; no conflict possible
- **BarrierValue:** Collects N writes; releases once N are received
- **NamedBarrierValue:** Like BarrierValue but keyed by name (see DEC-003 for partial-write edge case)
- **EphemeralValue:** Present only during the super-step it was written; cleared after ReducersApplied (see DEC-004)
- **BinaryOperatorAggregate:** User-supplied associative fold function

**GraphState**
The accumulated value across all channels at a point in execution. GraphState is not a
user-defined struct — it is the composition of all Channel values at a given super-step.
A Checkpoint wraps a GraphState.

**Super-step**
One round of BSP (Bulk-Synchronous Parallel) execution. All PregelTasks for the current
frontier execute concurrently; then all channel reducers apply in deterministic task-identity
order (DI-001). Super-step is the atomicity unit for checkpointing (DI-002). After all
reducers fire, the new GraphState is checkpointed.

**PregelTask**
A unit of scheduled node execution within a super-step. Content-addressed by task identity
(node name + incoming channel version vector). Corresponds to LangGraph's internal pregel
task concept. Output is durably recorded via put_writes before the next super-step (DI-002).

**Send API**
The mechanism for dynamic fan-out: a Node or conditional edge can construct `Send(node_name,
state_payload)` objects, each of which creates a new PregelTask targeting the given node with
the given partial state. This enables map-style parallel execution over a dynamic collection.
Corresponds to LangGraph's `Send` API.

**Conditional Edge**
An edge that routes to different target nodes based on the output of the source node. The
routing function inspects the node's output and returns a target node name (or END). Enables
branching logic such as verdict-driven routing (close | escalate | hunt | contain).

**Checkpoint**
A serialized snapshot of GraphState + pending writes + metadata at a super-step boundary.
Stored in msgpack format [D11.2 locked]. Identified by a monotonic logical-clock ID — not
wall-clock. Has a parent_checkpoint_id pointer for fork lineage tracking (DI-004).

**CheckpointSaver**
The repository that persists and retrieves Checkpoints. Operations: `get_tuple`, `put_writes`,
`put`, `list`. Backends: InMemory, SQLite, Postgres (stretch). Every operation is triple-
addressed by (thread_id, checkpoint_ns, checkpoint_id) — no bare thread_id path (DI-005).

**put_writes**
The CheckpointSaver operation that durably records a PregelTask's output before the next
super-step begins. Central to DI-002 (per-task durability, sync-default). Corresponds to
LangGraph's `put_writes`.

**Thread**
A named, durable sequence of Checkpoints representing one conversation or pipeline run.
All Runs that share a Thread share a checkpoint history. Corresponds to LangGraph's Thread
concept, analogous to a chat session or pipeline instance.

**Checkpoint fork**
When a Thread branches: two Runs both start from the same Checkpoint. Each fork receives a
distinct monotonically increasing checkpoint_id; both reference the shared parent via
`parent_checkpoint_id`. Parent state is never copied (pointer-linked only) per DI-004.

**Interrupt**
A programmatic suspension of graph execution at a node boundary, waiting for an external
actor to provide a ResumeValue. Raised by a node calling `interrupt()`. The Run transitions
to `interrupted` and is durably persisted.

**ResumeValue**
The external value injected to resume an Interrupt. Structured as a `Command` — a struct
with independently-settable optional fields: `resume` (value delivered to the interrupted
task's scratchpad), `update` (state side-load applied to graph channels before re-execution),
`goto` (routing override to one or more nodes or `Send`s), and `graph` (scope selector;
`Command.PARENT` escapes to a parent graph). Fields are freely combinable: a single `Command`
can simultaneously resume a value, side-load state, and redirect routing (BC-2.05.004
EC-001/TV-002/TV-003). Authority: BC-2.05.004.
Delivered strictly FIFO if multiple Interrupts are stacked (DI-003). The interrupted node
re-executes from the start of its super-step with the dequeued resume value in its scratchpad.

**HITL (Human-in-the-Loop)**
The pattern of using Interrupts and ResumeValues to route execution through a human approval
gate. The human (or an automated approval system) provides a ResumeValue; the interrupted
node re-executes from start with that value available.

**Risk-tiered authorization** (Domain A extension)
An application-layer pattern for SOC-analyst-style approval gates: action-risk levels
(read-only, low, medium, high) that route Interrupt delivery to different approver roles.
Not a core LangGraph primitive — built as a graph pattern on top of ferrochain's HITL
contract. See domain-a-soc-analyst.md §5.

---

## Prompts, Serialization, and Retrieval Terms (D21 Additions)

> D21 (burst 216) promoted SS-18 (Prompt Templates), SS-19 (LC Serialization), and
> SS-20 (Document Retrieval) to full v1 scope. The terms below cover the ubiquitous language
> for these three subsystems. Reference-corpus column gives the LangChain v1 origin term.

**PromptTemplate**
A single-message template that substitutes named variables into a string to produce a
formatted prompt. Variables are declared at construction time; required variables not supplied
at render time produce E-TMPL-003 (strict-undefined). Renders to a `PromptValue`. Implements
`Runnable`. Corresponds to `PromptTemplate` in LangChain v1 (`langchain_core.prompts.prompt`).
In ferrochain: `ferrochain-prompts::PromptTemplate`, f-string engine by default.

**ChatPromptTemplate**
A multi-message template that produces a `Vec<Message>` (wrapped as `PromptValue`) from a
sequence of role-labelled message slots, each with its own `SlotTrustPolicy`. SystemMessage
slots are hard-coded `TrustRequired` — this constraint is architectural, not configurable.
Implements `Runnable`. Corresponds to `ChatPromptTemplate` in LangChain v1
(`langchain_core.prompts.chat`). In ferrochain: `ferrochain-prompts::ChatPromptTemplate`.

**MessagesPlaceholder**
A chat template slot that expands a `Vec<Message>` variable in-place (rather than substituting
a scalar string). Used to inject conversation history, agent scratchpad, or tool-result
sequences at a fixed position in a ChatPromptTemplate. Corresponds to `MessagesPlaceholder`
in LangChain v1 (`langchain_core.prompts.chat`).

**FewShotPromptTemplate** (also: **FewShot**)
A template type that formats a list of `(input, output)` example pairs as alternating
Human/AI message turns and injects them before the user-turn slot in a ChatPromptTemplate.
Enables dynamic few-shot prompting without manually constructing example messages. Corresponds
to `FewShotChatMessagePromptTemplate` in LangChain v1.

**LcSerializable**
The opt-in trait a type implements to participate in the lc-JSON round-trip protocol.
Methods: `lc_id()` (namespace path as `&[&str]`), `lc_secrets()` (credential field names
stripped from serialized output, DI-010), `lc_attributes()` (extra metadata), and
`is_lc_serializable()` (opt-in gate). Types that implement `LcSerializable` can be serialized
to a `Serialized::Constructor` envelope and reconstructed via Reviver. Corresponds to
`Serializable` base class in LangChain v1 (`langchain_core.load.serializable`).

**Reviver**
The deserializer that reconstructs typed values from `Serialized::Constructor` envelopes using
the `inventory`-based static type registry. The Reviver looks up the `id` in the registered
`LcEntry` set — unknown types produce E-SRLZ-001; langchain-monolith types produce E-SRLZ-002;
legacy namespace aliases are remapped transparently. No path-based loading exists. Corresponds
to the `Reviver` function / `loads()` entrypoint in LangChain v1
(`langchain_core.load.load`). In ferrochain: `ferrochain_core::serializable::Reviver`.

**Retriever**
The dyn-compatible async trait for document retrieval: given a query string, returns a ranked
`Vec<Document>`. Held as `Arc<dyn Retriever>` in graph nodes. Object-safe via `&self` receiver
and `#[async_trait]` desugaring (no generic type params). All documents returned by any
Retriever and entering graph context pass `BoundaryType::RAGRetrieval` guardrail (DI-012).
Corresponds to `BaseRetriever` in LangChain v1 (`langchain_core.retrievers`). In ferrochain:
`ferrochain_core::retriever::Retriever`.

**Document**
A pure data carrier returned by Retriever implementations: `page_content: String` (the text),
`metadata: Map<String, Value>` (annotations), `id: Option<String>` (VectorStore-assigned ID).
RAG pipeline output. All Documents entering graph context pass the DI-012 guardrail at
`BoundaryType::RAGRetrieval`. Corresponds to `Document` in LangChain v1
(`langchain_core.documents.base`). In ferrochain: `ferrochain_core::documents::Document`.

**VectorStoreRetriever**
A concrete `Retriever` backed by a `&dyn VectorStore`, configured with a `SearchType`
(Similarity | SimilarityScoreThreshold | Mmr), `k` (final document count), `fetch_k`
(MMR candidate pool), and `lambda_mult` (MMR diversity parameter, 0.0–1.0). Constructed
via `VectorStore::as_retriever()`. Can be type-erased to `Arc<dyn Retriever>`. Corresponds
to `VectorStoreRetriever` in LangChain v1 (`langchain_core.vectorstores.base`). In
ferrochain: `ferrochain_vectorstores::retriever::VectorStoreRetriever`.

**VectorStore**
The abstract document-index trait: a content store that can be queried by vector similarity.
Core operations: add texts (returns document IDs), k-nearest similarity search, MMR search,
delete by ID, and `as_retriever()` (returns a concrete `VectorStoreRetriever`). All instance
methods use `&self` (dyn-compatible); static constructors live on the separate
`VectorStoreFactory` trait (E0038-safe). `Arc<dyn VectorStore>` is the seam for community
adapters (Qdrant, Chroma, pgvector, etc.). Corresponds to `VectorStore` abstract base class
in LangChain v1 (`langchain_core.vectorstores.base`). In ferrochain: ferrochain-vectorstores,
`vectorstores::store::VectorStore`.

**InMemoryVectorStore**
The reference `VectorStore` implementation: an in-memory document index backed by
`RwLock<Vec<(Document, Vec<f32>)>>`, constructed with an injected `Arc<dyn Embeddings>`.
Stores pre-computed `Vec<f32>` embedding vectors alongside documents. Computes cosine similarity
at query time. Enforces the zero-norm guard (E-VS-001) before any cosine division to prevent NaN
score corruption. Suitable for testing, small corpora, and unit tests of graph nodes that
perform RAG. Not persistence-backed. Corresponds roughly to
`InMemoryVectorStore` in LangChain v1 (`langchain_core.vectorstores.in_memory`). In
ferrochain: `ferrochain_vectorstores::memory::InMemoryVectorStore`.

**MetadataFilter**
An optional filter applied to VectorStore similarity searches based on Document metadata field
values. Expressed as a list of `FilterClause` predicates: `Eq` (field equals value), `Ne`
(not equal), `In` (field in a set of values). Community adapters may push MetadataFilter to
the backend as a server-side pre-filter; InMemoryVectorStore applies it as a post-filter.
Both `MetadataFilter` and `FilterClause` are `#[non_exhaustive]` for forward extensibility.
No direct LangChain v1 equivalent as a named type; ferrochain promotes it to a first-class
domain type. In ferrochain: `ferrochain_vectorstores::filter::MetadataFilter`.

**Embeddings**
The abstract text-to-vector conversion trait: given one or more text strings, returns
`Vec<f32>` embedding vectors of consistent dimensionality. Two methods: `embed_documents`
(batch — one vector per input text) and `embed_query` (single query). The dimensionality
contract guarantees all returned vectors have the same length and batch.len() == texts.len();
violations return E-EMBED-001. Batch failures return `Err` — no silent partial results
(DI-014). Held as `Arc<dyn Embeddings>` by VectorStore backends and ferrochain-memory.
Corresponds to `Embeddings` abstract base class in LangChain v1
(`langchain_core.embeddings.base`). In ferrochain: `ferrochain_core::embeddings::Embeddings`.

**EmbeddingsOpenAI**
The first-party OpenAI embedding implementation. Default model: `text-embedding-3-small`;
also supports `text-embedding-3-large` and legacy `text-embedding-ada-002`. API key accepted
as `OpenAiApiKey` newtype with redacted Debug (DI-010). Batch failure returns `Err` (DI-014).
reqwest/rustls-tls mandatory; 30-second timeout (DI-009). Corresponds to
`OpenAIEmbeddings` in LangChain v1 (`langchain_openai`). In ferrochain:
`ferrochain_openai::embeddings::EmbeddingsOpenAI`.

**EmbeddingsOllama**
The first-party Ollama local-embedding implementation. No default model (caller provides a
locally-pulled model name). No API key required. Default endpoint: `POST /api/embed`
(`input` field); `use_legacy_endpoint: bool` opt-in for `POST /api/embeddings` (`prompt`
field) for older Ollama deployments. reqwest/rustls-tls; 30-second timeout (DI-009) even for
localhost. ferrochain-anthropic has NO `Embeddings` impl (Anthropic provides no public
embedding API). Corresponds to `OllamaEmbeddings` in LangChain v1 (`langchain_ollama`). In
ferrochain: `ferrochain_ollama::embeddings::EmbeddingsOllama`.

**TrustLevel**
Template-variable trust classifier for the SS-18 template composition layer
(`ferrochain-prompts: prompts::template`). **Distinct from and independent of `ProvenanceTag`**
(SS-11 ingress-boundary audit struct — see ubiquitous-language-server.md §ProvenanceTag and
entities-server.md §ProvenanceTag). Three variants with severity ordering
`Untrusted > UserInput > Trusted`:
- `Untrusted` — content derived from an external/adversarial source (e.g., a RAG retrieval
  result or an MCP tool output); substituting into a `TrustRequired` slot raises E-TMPL-001
  (SECURITY/InjectionAttempt) at render time
- `UserInput` — content from a human operator; acceptable in `TrustRequired` slots when
  user trust is granted to the human principal
- `Trusted` — developer-controlled content; always acceptable in any template slot
`TemplateVar.trust_level: Option<TrustLevel>` — `None` is treated as `Trusted` (developer-
supplied literal; no external origin). `MessageProvenance.highest_trust_level: Option<TrustLevel>`
carries the maximum-severity TrustLevel across all variables substituted into a message.
**Distinct from ProvenanceTag:** `ProvenanceTag` records ingress-boundary origin
(`boundary_type: BoundaryType` / `ingress_id: Uuid` / `sequence_position: usize`); it has no
trust-level dimension. `TrustLevel` classifies template-variable trust at composition time.
When a developer derives a template variable from a RAG result (which arrived with a
ProvenanceTag), they translate the ingress provenance into `TrustLevel::Untrusted` for the
composition step. The ingress ProvenanceTag record is captured in the guardrail audit log at
ingress time and need not be threaded through template composition. Authority: ADR-015 §Decision 3.

---

## D23 Additions — HITL Approval Hook, Context Compaction, and First-Party Tools

> D23 (burst 230, 2026-07-22) added: (1) per-tool-call approval hook (ADR-018 / CAP-034),
> (2) rolling context compaction (ADR-019 / CAP-035), and (3) first-party tool library
> (ADR-020 / CAP-036..038 / SS-23). Reference-corpus column for tool library terms:
> Claude Code (Anthropic) public documentation — the canonical Domain E exemplar.

**PreToolCallHook**
An async hook registered in `GraphConfig.pre_tool_hook: Option<Arc<dyn PreToolCallHook>>`,
invoked by the graph engine immediately before every tool dispatch. Returns a `PreToolDecision`
determining whether the tool proceeds, is denied, has its arguments edited, or is held pending
human approval. Default implementation: `AlwaysApprovePolicy` (always approves; no I/O;
backward compatible). Crate: ferrochain-graph, `graph::hitl`. Authority: ADR-018 / CAP-034.

**PreToolDecision**
The four-variant decision type returned by `PreToolCallHook::pre_invoke` (`#[non_exhaustive]`):
`Approve` (proceed unchanged), `Deny { reason }` (fail-closed — tool NOT invoked; VP-011
Kani candidate), `Edit { modified_args }` (proceed with modified arguments), and
`PendingHumanApproval { prompt }` (suspend via `interrupt()`, reusing BC-2.05.001 machinery;
resumed via `Command(resume=PreToolDecision)`; hook NOT re-called on resume —
"skip-hook-on-resume" invariant, PO BC obligation). Crate: ferrochain-graph, `graph::hitl`.
Authority: ADR-018 / CAP-034.

**CompactionTrigger**
A `#[non_exhaustive]` configuration enum in `BudgetConfig.compaction_trigger` that controls
when the BudgetEngine initiates proactive context compaction. Variants: `Disabled` (default;
backward compatible), `OnWatermark { fraction: f32 }` (fires when `tokens_remaining / ceiling
< (1.0 - fraction)`; VP-012 Kani candidate — pure arithmetic), `OnMessageCount { count }`,
`OnTokenCount { tokens }`. Crate: ferrochain-core, `core::budget`. Authority: ADR-019 / CAP-035.

**CompactionPolicy**
An async trait whose single method `compact(&self, snapshot: &ConversationSnapshot, run_ctx)
→ Result<CompactionSummary>` produces a compact representation of recent conversation history.
Default impl: `DefaultSummarizationPolicy` (prompts the model; same mechanism as
`OnCeiling::Summarize`). Registered as `BudgetConfig.compaction_policy: Option<Arc<dyn
CompactionPolicy>>`. Custom impls MAY additionally write the summary to MemoryStore (CAP-017)
as project knowledge — framework imposes no constraint beyond returning `CompactionSummary`
(ADR-019 Decision 5). Crate: ferrochain-core, `core::budget`. Authority: ADR-019 / CAP-035.

**ConversationSnapshot**
A read-only ordered slice of recent conversation history assembled by the BudgetEngine from
checkpoint FTS (BC-2.04.008) when a CompactionTrigger fires. Fields: `turns: Vec<(usize,
Message)>` (turn-index / Message pairs) + `token_estimate: u64`. Passed to
`CompactionPolicy::compact()` as the compaction input. Crate: ferrochain-core, `core::budget`.
Authority: ADR-019 / CAP-035.

**CompactionSummary**
The output of a `CompactionPolicy::compact()` invocation. Fields: `summary_text: String`
(injected as a `SystemMessage` into the active conversation window) + `compacted_range:
RangeInclusive<usize>` (turn indices replaced). Applied mid-run (contrast with
`frozen-snapshot`, which takes effect on the NEXT run). Original checkpoint records are NOT
deleted (BC-2.04.001 immutability). Triggers a `compaction_event` streaming event (15th
variant) and appends a `CompactionEvent` to `EvidenceJournal`. Crate: ferrochain-core,
`core::budget`. Authority: ADR-019 / CAP-035.

**ReadFileTool**
First-party `Tool` in `ferrochain-tools::tools::fs` (SS-23, crate #21). Reads file contents
at a PathGuard-confined path. `ActionRisk::ReadOnly`. Enforces a `max_bytes` limit (default
1 MiB; E-TOOLS-002 on excess). VP-003 path-confinement coverage applies. Authority: ADR-020 / CAP-036.

**WriteFileTool**
First-party `Tool` in `ferrochain-tools::tools::fs` (SS-23). Creates or overwrites a file at a
PathGuard-confined path. `ActionRisk::High`. Non-idempotent; no auto-retry. E-TOOLS-001 on
out-of-guard path. Requires re-approval before retry via PreToolCallHook. Authority: ADR-020 / CAP-036.

**EditFileTool**
First-party `Tool` in `ferrochain-tools::tools::fs` (SS-23). Applies an exact-string replacement
(`old_string → new_string`) to an existing file. `ActionRisk::High`. E-TOOLS-003 if `old_string`
is not found. Opt-in fuzzy-match fallback via `EditConfig::fuzzy_threshold` (`similar` crate).
Conditional retry is safe when E-TOOLS-003 fires (old_string mismatch is a structural no-op).
Authority: ADR-020 / CAP-036.

**ListDirTool**
First-party `Tool` in `ferrochain-tools::tools::fs` (SS-23). Lists directory entries at a
PathGuard-confined path. `ActionRisk::ReadOnly`. No size limit. Authority: ADR-020 / CAP-036.

**BashTool**
First-party `Tool` in `ferrochain-tools::tools::shell` (SS-23). Executes arbitrary shell
commands via the ferrochain-sandbox WASM/container backend (BC-2.13.001–003; enforcing sandbox
mandatory). `ActionRisk::High` (default). Risk tier CANNOT be lowered below `ActionRisk::Medium`
— a framework safety invariant, not an application convention (VP-013 Kani candidate). Retry must
be explicitly enrolled per-`tool_name` (BC-2.16.001); each retry flows through PreToolCallHook
independently (ADR-018 Decision 6). Authority: ADR-020 / CAP-037.

**BashOutput**
The structured output of a `BashTool` invocation. Fields: `stdout: String`, `stderr: String`,
`exit_code: i32`, `truncated: bool`. `max_output_bytes` limit (default 256 KiB); exceeding it
returns first 256 KiB with `truncated = true` (E-TOOLS-005 informational; non-fatal).
`max_duration` timeout (default 30s; E-TOOLS-004 on breach). Authority: ADR-020 / CAP-037.

**GrepTool**
First-party `Tool` in `ferrochain-tools::tools::search` (SS-23). In-process regex pattern
matching using the `regex` crate (NOT shelling out to system grep — hermetic; unit-testable
without system tool availability). `ActionRisk::ReadOnly`. `max_results` cap (default 100;
E-TOOLS-006 `SearchResultsCapped` informational). Returns matches with file path and line number.
Path validated by PathGuard for directory scoping. No sandbox execution — reads in-process.
Authority: ADR-020 / CAP-038.
