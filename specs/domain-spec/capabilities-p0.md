---
document_type: domain-spec-section
level: L2
section: capabilities-p0
version: "1.0"
status: active
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/STATE.md
input-hash: "f6a9de5f38547412b42b12dbd19c3733ab48c3741c91c3cacad08519057dee21"
traces_to: L2-INDEX.md
decisions: [D1, D7, D8, D11, D13, D17]
---

# Domain Capabilities — P0 (Must-Have for Release)

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> Continued in `capabilities-p1-p2.md` (P1 and P2 capabilities).

Each capability is grounded in the product brief. IDs are stable from this spec forward.

---

## P0 — Core Primitives and Graph Runtime (Wave 0 / Wave 1)

### CAP-001: Type-Safe Message and Content Primitive Construction

Construct typed messages (AiMessage, HumanMessage, SystemMessage, ToolMessage) whose content
is a sequence of typed ContentBlocks (text, image_url, tool_use, tool_result, document).
Guarantee that no caller can observe raw untyped content where a typed variant is expected.

**Grounding:** product-brief.md §Scope Wave 0 — `ferrochain-core` typed message/content
primitives (Runnable, Message, ContentBlock).
**Anchor justification:** CAP-001 covers typed content construction because the brief mandates
`ferrochain-core` typed ContentBlock as the API-surface root primitive and market
differentiator #4 (product-brief §Overflow Competitive Differentiator Traceability).

### CAP-002: Runnable Trait Abstraction (Compose, Pipe, Chain)

Express any computation — model call, prompt template, output parser, tool, graph — as a
Runnable that can be invoked, streamed, batched, and composed via `|` pipe into chains.
Provides the universal composition protocol across all ferrochain crates.

**Grounding:** product-brief.md §Scope Wave 0 — "Runnable" is the core LangChain v1 semantic
primitive (reference-manifest.md, semport Corpus 1 langchain==1.3.13). The brief lists
`(Runnable, Message, ContentBlock)` as Wave 0 foundation.
**Anchor justification:** CAP-002 covers Runnable composition because the product-brief names
it explicitly in Wave 0 and it is the composition primitive that all higher capabilities
(chains, graphs, providers) depend on.

### CAP-003: StateGraph Definition (Nodes, Edges, Channels, Reducers)

Define directed agent graphs: add typed nodes (Runnables), channel-typed state slots with
reducer functions (LastValue, Append, BarrierValue, NamedBarrierValue, EphemeralValue,
BinaryOperatorAggregate), typed edges including conditional edges, and Send API for
dynamic fan-out.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-graph` LangGraph StateGraph engine,
BSP scheduling, Send API fan-out, conditional edges.
**Anchor justification:** CAP-003 covers graph definition because the brief names StateGraph and
the LangGraph port as the P0 lead differentiator (D7).

### CAP-004: BSP Graph Execution with Deterministic Reducer Order

Execute a StateGraph via the Bulk-Synchronous Parallel scheduling model: in each super-step,
all scheduled PregelTasks execute; then all channel reducers apply in deterministic
task-identity-sorted order. Concurrent writes to the same LastValue channel raise
InvalidUpdateError rather than silently racing.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-graph` BSP scheduling with
deterministic reducer order (CONFLICT-1/NE-17/D17); brief §Scope "BSP scheduling with
deterministic reducer order (CONFLICT-1/NE-17)."
**Anchor justification:** CAP-004 covers BSP execution because it is the execution model the
brief mandates by name, tracing to CONFLICT-1 and D17 HYBRID outcome.

### CAP-005: Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)

Persist graph state at three durability tiers — sync (crash-safe default, writes before
returning), async (background), exit-only — using per-task `put_writes` so each PregelTask's
output is stored before the next super-step begins. Checkpoint IDs use a monotonic logical
clock, not wall-clock. Backends: SQLite (default), in-memory; msgpack wire format [D11.2].
Postgres stretch target.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-checkpoint` three-tier durable
checkpointing, per-task put_writes (CONFLICT-2/D11.3/D17-Q3), monotonic logical-clock
checkpoint IDs (CONFLICT-4), msgpack wire format [locked: D11.2], SQLite + in-memory
backends [locked: D11.3].
**Anchor justification:** CAP-005 covers three-tier checkpointing because the brief names
it explicitly and D11.3 locks the three-tier model with sync default. Domain B
dark-factory multi-day runs cannot function without this.

### CAP-006: HITL Interrupt / Resume with FIFO Resume-Value Delivery

Pause graph execution at any node boundary via `interrupt()`. Persist the interrupted
state durably. Accept one or more resume values externally (human decision, approval
command, or correction). Deliver resume values in strict FIFO order to the interrupted
node, which re-executes from the start of its super-step with the resume value available.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-graph` full HITL interrupt/resume
contract per CONFLICT-3/D17-Q2: "per-task scratchpad, FIFO resume-value delivery,
node-re-executes-from-start, Command(resume=value) API."
**Anchor justification:** CAP-006 covers HITL because it is explicitly named as a Phase-1 BC
in D17-Q2 and the brief states "cannot be retrofitted post-graph-design." Both Domain A
(risk-tiered approval gates) and Domain B (pipeline approval gates) force this.

### CAP-007: Structured Streaming Event Taxonomy

Emit typed per-phase streaming events: run_start / run_stream / run_end, step_start /
step_end, node_start / node_stream / node_end, tool_start / tool_stream / tool_end — each
carrying a run_id, parent_ids chain, and phase-specific payload. Streaming and unary runs
drive the same engine and produce identical final answers.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-server` streaming and unary run
equivalence (NE-13/D17), CONFLICT-5 typed per-phase event taxonomy. Brief §Scope "streaming
and unary run equivalence (NE-13/D17)."
**Anchor justification:** CAP-007 covers structured streaming because NE-13 (streaming stub
must not exist) and CONFLICT-5 (typed taxonomy) are both named in the brief's scope section.

### CAP-008: Text Splitting with Code-Point Boundary Correctness

Split documents into chunks that respect the configured chunk size as a count of Unicode
code points (not bytes), with configurable overlap. On non-ASCII text, chunk boundaries
must be identical to the reference LangChain Python implementation (which also uses
code-point counts, not byte counts). Provide explicit test vectors for emoji and CJK inputs.

**Grounding:** product-brief.md §Scope Wave 0 — `ferrochain-splitters` with "explicit BC for
code-point vs byte-length boundary parity on non-ASCII input (R8/D17-Q9)."
**Anchor justification:** CAP-008 covers splitters because the brief names R8 as a High risk
and D17-Q9 mandates it as a Phase-1 BC backlog item. The code-point/byte-length distinction
is explicitly called out by name.
