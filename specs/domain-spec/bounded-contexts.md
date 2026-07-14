---
document_type: domain-spec-section
level: L2
section: bounded-contexts
version: "1.0"
status: active
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "96a97c892cfd894c1e3b2d9df10121c70d1b282157e5d6d8dcb5a139c887f694"
traces_to: L2-INDEX.md
decisions: [D1, D4, D6, D11, D13, D17]
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
CheckpointStore trait; the concrete implementation is injected (dependency inversion).
**Key invariants:** DI-001 (BSP determinism), DI-002 (per-task durability), DI-003
(HITL FIFO), DI-004 (monotonic clock), DI-012 (guardrail ingress coverage).

---

## Context 3: Checkpoint / Durability (ferrochain-checkpoint)

**Model:** Checkpoint, PendingWrite, CheckpointStore trait, CheckpointTuple, delta
serialization, logical clock.
**What it owns:** The durability model; checkpoint ID generation; delta encoding;
msgpack serialization; SQLite and in-memory backends.
**What it does NOT own:** Graph execution logic; when to checkpoint (that is Context 2's
policy); network transport.
**Translation seam with Graph:** Exposes `CheckpointStore` trait; graph execution holds
an Arc<dyn CheckpointStore>.
**Translation seam with Server:** Server's Thread model is backed by CheckpointStore
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
**Translation seam with Checkpoint:** Server uses CheckpointStore to persist/resume Run
state.
**Key invariants:** DI-005 (tenancy), DI-011 (streaming/unary equiv.), DI-013 (secure
defaults), FM-007 (streaming stub must not exist).
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
MCP tool result to ToolResult ContentBlock; untrusted-ingress tagging.
**What it does NOT own:** Graph scheduling; guardrail evaluation (that is Context 2/Core).
**Translation seam with Core:** MCPTool implements the Tool Runnable interface.
**Translation seam with Graph:** ToolResult from MCPTool must pass GuardrailHook before
entering model context (DI-012). The seam is the ToolResult → GuardrailHook boundary.
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
**Translation seam with Core:** Splitters accept and return ContentBlocks (Document variant).
**Key invariants:** R-004 (code-point parity), DEC-001, DEC-002.

---

## Context Dependency Order

```
ferrochain-core
  ← ferrochain-splitters
  ← ferrochain-checkpoint
      ← ferrochain-graph
          ← ferrochain-server
  ← ferrochain-<provider>-sdk
      ← ferrochain-<provider>
  ← ferrochain-mcp
  ← ferrochain-standard-tests (dev-dep)
```

No circular dependencies; ferrochain-core has zero intra-workspace dependencies.
