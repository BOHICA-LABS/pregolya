---
document_type: domain-spec-section
level: L2
section: ubiquitous-language-core
version: "1.2"
status: active
producer: business-analyst
timestamp: 2026-07-19T00:00:00Z
changelog:
  - "1.1 (F-P120-01, fix burst 123, 2026-07-19): Correct §ResumeValue definition from 2-variant enum form 'Command::Resume(value)' to struct form aligned to BC-2.05.004: Command with independently-settable optional fields resume/update/goto/graph, combinable as compound commands (EC-001/TV-002/TV-003). TD-VSDD-060 sweep: this file:142 was the only Command-depiction site; fixed here."
  - "1.2 (F-P121-01/02, fix burst 124, 2026-07-19): §Message: 'The four roles are: Human/AI/System/Tool' expanded to note 4 primary + legacy Function (BC-2.01.002 PC7), Chat arbitrary-role discriminant, Remove history-control token (BC-2.01.002 EC-005). §ContentBlock: replaced 5-variant drifted list (Text/ImageUrl/ToolUse/ToolResult/Document with wrong fields) with canonical 14-variant reference per BC-2.01.001 PC2; ToolCall fields {id,name,args} per BC-2.08.002/013; NonStandard DI-008 passthrough; tool results → ToolMessage per BC-2.09.002. TD-VSDD-060 sweep: only Message and ContentBlock depiction sites in this file; both fixed."
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/semport/reference-manifest.md
input-hash: "ecdcabd"
traces_to: L2-INDEX.md
decisions: [D2, D17]
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
