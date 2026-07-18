---
document_type: domain-spec-section
level: L2
section: entities-graph
version: "1.1"
status: active
producer: business-analyst
timestamp: 2026-07-17T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "fba49e3"
traces_to: L2-INDEX.md
decisions: [D11, D17]
changelog:
  - "v1.1 (2026-07-17): Provenance-integrity fix — STATE.md removed from inputs (D11/D17 decisions and CONFLICT-*/NE-* entity sources baked at authoring time from COMPARATIVE-ASSESSMENT.md, not live state); input-hash recomputed."
---

# Domain Entities — Core Primitives, Graph, and Checkpoint

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> Server, Policy/Governance, and Provider entities are in `entities-server.md`.

---

## Core Primitives

### ContentBlock
Typed union of content variants a message can carry.
- **Variants:** Text(content: String), ImageUrl(url, detail?), ToolUse(tool_name, tool_call_id, input: Value), ToolResult(tool_call_id, content: Vec<ContentBlock>, is_error: bool), Document(source, metadata)
- **Invariant:** ToolResult content is always untrusted ingress. Must pass GuardrailHook before entering the model context (DI-012).
- **Note:** No bare String message content; ContentBlock is the only way to attach content to a Message.

### Message
One turn in a conversation, always typed by role.
- **Fields:** role: Role (Human | AI | System | Tool), content: Vec<ContentBlock>, id: Option<String>, usage_metadata: Option<UsageMetadata>
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
- **Invariant (DI-012):** ToolResult ContentBlocks produced by any Tool are untrusted ingress.

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

## Relationships Summary (This Section)

```
StateGraph 1——N Node
StateGraph 1——N Channel
StateGraph 1——N Edge
Node wraps Runnable
Runnable subtypes: ChatModel, Tool, Chain, StateGraph, Node
PregelTask belongs-to Node (via node_name)
Checkpoint wraps GraphState
Checkpoint 0——N PendingWrite
Checkpoint 0——1 parent Checkpoint
CheckpointSaver owns N Checkpoint
Thread 1——N Checkpoint (via thread_id)
Message 1——N ContentBlock
Tool returns ToolResult (ContentBlock subtype)
```
