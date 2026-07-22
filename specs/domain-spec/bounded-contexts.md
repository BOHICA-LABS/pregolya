---
document_type: domain-spec-section
level: L2
section: bounded-contexts
version: "1.2"
status: active
producer: business-analyst
timestamp: 2026-07-19T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "b14600a"
traces_to: L2-INDEX.md
decisions: [D1, D4, D6, D11, D13, D17]
changelog:
  - "1.0 (initial): base bounded contexts authored."
  - "1.1 (F-P121-01, fix burst 124, 2026-07-19): Context 6 MCP Adapter: 'conversion from MCP tool result to ToolResult ContentBlock' → 'ToolMessage (BC-2.09.002)'; translation seam: 'ToolResult from MCPTool' / 'ToolResult → GuardrailHook boundary' → canonical ToolMessage/IngressContent::ToolResult phrasing. TD-VSDD-060 sweep: only Context 6 had ToolResult ContentBlock vocabulary; fixed."
  - "1.2 (F-P122-01, fix burst 125, 2026-07-19): Context 8 Splitters translation seam: 'Splitters accept and return ContentBlocks (Document variant)' → 'Splitters accept plain UTF-8 String inputs and return Vec<String> chunk strings' per BC-2.07.001/002/003 preconditions. Document is not a canonical ContentBlock variant (BC-2.01.001 PC2 14-variant list). ContentBlock wrapping is caller responsibility."
---

# Bounded Contexts

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

For this pipeline-oriented framework, bounded contexts map to crate-level subsystems.
Each context has a clear model boundary and a translation seam where it meets others.

---

## Context 1: Core Primitives (ferrochain-core)

**Model:** Messages, ContentBlocks, Runnable trait, Tool schema traits, FerrochainError.
**What it owns:** The universal composition protocol; the error taxonomy; credential types.
**What it does NOT own:** Graph state; checkpointing; server routing; provider transports.
**Translation seam:** All other contexts depend on ferrochain-core types. The only
direction is inward — ferrochain-core does not depend on any other ferrochain crate.
**Key invariants:** DI-008 (constructor Result), DI-010 (credential opacity), DI-014
(error propagation), DI-009 (outbound timeout).

---

## Context 2: Graph Execution (ferrochain-graph)

**Model:** StateGraph, Node, Channel, GraphState, PregelTask, SuperStep, Send API,
conditional edges, HITL Interrupt, ResumeValue.
**What it owns:** The BSP execution model; channel reducer application; HITL lifecycle;
graph compilation and validation.
**What it does NOT own:** Checkpoint persistence (delegates to ferrochain-checkpoint);
server HTTP layer; provider transport.
**Translation seam with Core:** StateGraph nodes are Runnables from ferrochain-core.
**Translation seam with Checkpoint:** Graph execution calls `put_writes` on the
CheckpointSaver trait; the concrete implementation is injected (dependency inversion).
**Key invariants:** DI-001 (BSP determinism), DI-002 (per-task durability), DI-003
(HITL FIFO), DI-004 (monotonic clock), DI-012 (guardrail ingress coverage).

---

## Context 3: Checkpoint / Durability (ferrochain-checkpoint)

**Model:** Checkpoint, PendingWrite, CheckpointSaver trait, CheckpointTuple, delta
serialization, logical clock.
**What it owns:** The durability model; checkpoint ID generation; delta encoding;
msgpack serialization; SQLite and in-memory backends.
**What it does NOT own:** Graph execution logic; when to checkpoint (that is Context 2's
policy); network transport.
**Translation seam with Graph:** Exposes `CheckpointSaver` trait; graph execution holds
an Arc<dyn CheckpointSaver>.
**Translation seam with Server:** Server's Thread model is backed by CheckpointSaver
thread_id partitioning.
**Key invariants:** DI-002, DI-004, DI-005 (session triple-address).

---

## Context 4: Server (ferrochain-server)

**Model:** Thread, Assistant, Run, CronSchedule, StreamEvent, SecurityConfig.
**What it owns:** HTTP endpoint routing; run lifecycle management; cron scheduling;
streaming protocol; authentication; per-tenant isolation.
**What it does NOT own:** Graph execution semantics (delegates to Context 2); checkpoint
persistence (delegates to Context 3).
**Translation seam with Graph:** Server creates a CompiledGraph from an Assistant's
graph_id and invokes it for each Run.
**Translation seam with Checkpoint:** Server uses CheckpointSaver to persist/resume Run
state.
**Key invariants:** DI-005 (tenancy), DI-011 (streaming/unary equiv.), DI-013 (secure defaults).
**Excluded failure mode (FM-007):** streaming stub must not exist.
**Out-of-scope note:** No wire compatibility with LangGraph Platform (D13).

---

## Context 5: Providers (ferrochain-openai, ferrochain-anthropic, ferrochain-ollama)

**Model:** ProviderClient (ChatModel Runnable), ApiKey newtypes, streaming completions,
tool-call round-trips, structured output, token usage accounting.
**What it owns:** Provider-specific wire protocol; streaming event mapping; error
translation to FerrochainError; credential management.
**What it does NOT own:** Graph orchestration; checkpointing; server routing.
**Architecture:** Standalone SDK crate split (HS-6/D17-Q5): `ferrochain-<provider>-sdk`
(wire client) + `ferrochain-<provider>` (Runnable adapter). Final names in architecture ADR.
**Translation seam with Core:** Provider crates implement ChatModel Runnable from
ferrochain-core.
**Translation seam with Standard Tests:** ferrochain-standard-tests imports provider crates
and exercises the ChatModel interface.
**Key invariants:** DI-009 (outbound timeout), DI-010 (credential opacity).

---

## Context 6: MCP Adapter (ferrochain-mcp)

**Model:** MCPTool, MCP server connection, tool discovery protocol, untrusted ingress
boundary.
**What it owns:** MCP client transport; runtime tool capability discovery; conversion from
MCP tool call result to `ToolMessage` (BC-2.09.002); untrusted-ingress tagging.
**What it does NOT own:** Graph scheduling; guardrail evaluation (that is Context 2/Core).
**Translation seam with Core:** MCPTool implements the Tool Runnable interface.
**Translation seam with Graph:** The `ToolMessage` content produced by MCPTool passes through `GuardrailHook` as `IngressContent::ToolResult(ContentBlock)` before entering the model context (DI-012). The seam is the tool-result content → GuardrailHook boundary.
**Key invariants:** DI-012 (guardrail on tool-result ingress), DEC-012 (bare ToolException).

---

## Context 7: Standard Tests (ferrochain-standard-tests)

**Model:** Conformance test harness, test fixtures, scoring assertions.
**What it owns:** The conformance contract definition; pass/fail criteria for provider crates.
**What it does NOT own:** Actual provider implementations (those are in Context 5).
**Translation seam with Providers:** Standard tests exercise the ChatModel Runnable
interface from ferrochain-core; providers must implement that interface to pass.
**Note:** This is a dev-dependency crate; it ships as a library that provider crates
use in their test suites.

---

## Context 8: Splitters (ferrochain-splitters)

**Model:** TextSplitter, chunk boundary algorithm, code-point counting.
**What it owns:** Document chunking logic; boundary correctness (code-point not byte).
**What it does NOT own:** Embedding; vector store; model invocation.
**Translation seam with Core:** Splitters accept plain UTF-8 String inputs and return Vec<String> chunk strings (BC-2.07.001/BC-2.07.002/BC-2.07.003). ContentBlock wrapping (e.g., into ContentBlock::Text or ContentBlock::PlainText) is the caller's responsibility at the use site.
**Key invariants:** R-004 (code-point parity), DEC-001, DEC-002.

---

## Context Dependency Order

```
ferrochain-core
  ← ferrochain-splitters
  ← ferrochain-checkpoint
  ← ferrochain-graph
  ← ferrochain-server         (direct deps: ferrochain-graph + ferrochain-checkpoint)
  ← ferrochain-<provider>     (direct deps: ferrochain-core + ferrochain-<provider>-sdk)
  ← ferrochain-mcp
  ← ferrochain-standard-tests (dev-dep)

ferrochain-<provider>-sdk (standalone root; NO ferrochain-core dep [D17-Q5])
  ← ferrochain-<provider>
```

No circular dependencies; ferrochain-core has zero intra-workspace dependencies.
