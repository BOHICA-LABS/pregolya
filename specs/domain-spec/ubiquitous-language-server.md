---
document_type: domain-spec-section
level: L2
section: ubiquitous-language-server
version: "1.2"
status: active
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/semport/reference-manifest.md
input-hash: "ecdcabd"
traces_to: L2-INDEX.md
decisions: [D2, D13, D17]
changelog:
  - "1.1 (initial active version)."
  - "1.2 (ADV-P1D-PASS-58): F-P58-03 — update §ProvenanceTag and §GuardrailHook to BC-authoritative terminology. ProvenanceTag: source_type/tool_name?/invocation_id?/timestamp → boundary_type (ToolResult|RAGRetrieval|MemoryIngress), ingress_id, sequence_position; removed User/Model per BC-2.11.001 EC-004. GuardrailHook: Accept/Reject/Redact retired → Pass/Fail{reason,severity}/Transform{new_content}; callable signature updated to match interface-definitions.md v2.13."
---

# Ubiquitous Language — Server, Policy/Safety, Error Terms, and Reconciliation

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> Core Primitives and Graph terms are in `ubiquitous-language-core.md`.

---

## Server Terms

**Assistant**
A named agent configuration hosted by ferrochain-server: a compiled graph reference plus
run configuration. Corresponds to LangGraph Platform's "assistant." No wire compatibility
with LangGraph Platform (D13).

**Run**
A single execution of an Assistant with a Thread. Status lifecycle:
`queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted (resume via POST .../resume)`.
(`requires_action` renamed to `interrupted` for HITL-parked runs; `expired` deferred — v1.0.0 maps timeout-expired interrupts to `failed` via E-GRAPH-014 InterruptApprovalTimeout.)
Streaming and unary Run endpoints drive the same execution engine (DI-011).

**CronSchedule**
A recurring run trigger registered on an Assistant. Each firing creates a new Run. Each Run
from a CronSchedule starts with a fresh session (no prior context carried over unless
explicitly configured). Corresponds to LangGraph Platform "crons."

**Streaming / Unary equivalence**
The guarantee that the streaming endpoint and the unary endpoint produce the same final
answer for the same inputs. The streaming endpoint is not a stub — it invokes the same
execution engine and emits typed StreamEvents as the graph progresses (DI-011, NE-13).

---

## Policy / Safety Terms

**BudgetPolicy**
A composable allow/escalate/deny policy evaluated against token and cost tallies for a Run.
Configured per Run via RunnableConfig. Multiple policies chain; first Deny wins.

**EvidenceJournal**
Append-only record of BudgetPolicy evaluations and usage events for one Run. Never modified;
only appended. Provides an audit trail for cost governance decisions.

**ProvenanceTag**
Metadata attached to content at ingress, recording `boundary_type` (ToolResult | RAGRetrieval | MemoryIngress),
`ingress_id` (unique per ingress event), and `sequence_position` (zero-indexed position within the event).
Used for forensic audit trails (Domain A SOC) and guardrail call context.
User messages and model scratch-pad are not tagged — they do not traverse the guardrail path (BC-2.11.001 EC-004).
Authority: entities-server.md §ProvenanceTag.

**GuardrailHook**
A registered callable that validates content at an ingress boundary (ToolResult, RAG chunk,
memory item) before it enters the model context. Outcome: `GuardrailResult::Pass` (forward
unchanged), `Fail { reason, severity: GuardrailSeverity }` (content blocked; error block
injected at content position; run continues unless severity == Critical), or
`Transform { new_content }` (sanitized replacement forwarded; original discarded).
There is no bypass code path (DI-012).
Authority: interface-definitions.md §GuardrailHook, BC-2.11.002–BC-2.11.005.

**Untrusted ingress**
Content that crosses an external trust boundary before entering the model context. Categories:
tool results (from any Tool including MCPTool), RAG chunks retrieved from vector stores, and
memory retrieved from external stores. Untrusted ingress must pass GuardrailHook.
This is the boundary that Domain A's prompt-injection isolation requirement defends.

**Sandbox enforcement**
The property that tool execution occurs inside an enforcing isolation backend (WASM or
container) by default. A non-enforcing backend (process-native execution) requires explicit
opt-in and emits a loud warning. "Sandbox enforcement" is the *enforcement* of the policy —
not just the presence of a sandbox configuration option (DI-006, NE-01).

**Workspace confinement**
The guarantee that every workspace file operation calls `canonicalize_beneath_root(base, path)`
at access time, and that no file operation can observe content outside the declared workspace
root. Symlink traversal that escapes returns `Err(WorkspaceEscape)` (DI-007, NE-02).

---

## Error Terms

**FerrochainError**
The 2D error type: `component` (which ferrochain crate raised the error) × `category` (what
class of error it is). Not derived from a Python exception hierarchy. Adopted from adk-rust
P-01/P-04 (CONFLICT-6). Every public ferrochain API returns `Result<T, FerrochainError>`.

**RetryHint**
A field on FerrochainError indicating whether the caller should retry: `Never`,
`Maybe`, or `Later(Duration)`. Allows callers to implement backoff without inspecting
internal error details.

**InvalidUpdateError**
The specific FerrochainError raised when two PregelTasks in the same super-step both write
to the same LastValue channel. Surfaced immediately during ReducersApplied; terminates the
Run with `status: failed`.

**PolicyNotEnforceable**
The FerrochainError returned by `Sandbox::execute` when a strict BudgetPolicy or sandbox
policy is applied against a non-enforcing backend. The caller cannot proceed; the error is
not retriable.

---

## Term Reconciliation Table (LangChain Python → ferrochain)

| LangChain Python term | ferrochain term | Change from Python |
|----------------------|-----------------|-------------------|
| `Runnable` | Runnable | Identical semantics; Rust async trait |
| `RunnableSequence` (`A \| B`) | RunnableSequence (via `\|` operator) | Identical composition semantics |
| `StateGraph` | StateGraph | Identical; BSP execution model from LangGraph |
| `interrupt()` | `interrupt()` | HITL semantics preserved; FIFO resume is ferrochain-native (CONFLICT-3) |
| `put_writes` | `put_writes` | Per-task durability; sync-default is ferrochain-native (CONFLICT-2) |
| `BaseCheckpointSaver` | CheckpointSaver | name preserved from LangGraph BaseCheckpointSaver; same interface |
| `RunnableConfig` | RunnableConfig | name preserved; no rename |
| `BaseMessage` | Message | Renamed; ContentBlock replaces raw string content |
| `HumanMessage`, `AIMessage`, `SystemMessage`, `ToolMessage` | Message enum: Ai(AiMessage) | Human(HumanMessage) | System(SystemMessage) | Tool(ToolMessage) | Variant instead of subclass |
| `ToolCall` / `ToolMessage` | ContentBlock::ToolCall / ToolMessage | Typed ContentBlock variants; tool-result: ToolMessage per BC-2.09.002 |
| `BaseException` hierarchy | FerrochainError 2D struct | Different structure; adk-rust P-01/P-04 adopted (CONFLICT-6) |
| Thread (LangGraph Platform) | Thread | Same concept; no wire compat with Platform |
| Assistant (LangGraph Platform) | Assistant | Same concept; no wire compat with Platform |
| `BaseStore` (LangGraph) | MemoryStore (long-horizon KV+vector) | Same concept; CAP-017 |
| `Send` (LangGraph) | `Send(node, state)` in SendEdge | Identical fan-out semantics |

---

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.2 | 2026-07-15 | F-P58-03 — §ProvenanceTag and §GuardrailHook updated to BC-authoritative terminology. ProvenanceTag: `source_type`/`tool_name?`/`invocation_id?`/`timestamp` → `boundary_type` (ToolResult|RAGRetrieval|MemoryIngress), `ingress_id`, `sequence_position`; User/Model removed per BC-2.11.001 EC-004. GuardrailHook: Accept/Reject/Redact retired → `Pass`/`Fail{reason,severity}`/`Transform{new_content}` with `GuardrailResult`; callable signature updated to match interface-definitions.md v2.13. | F-P58-03 |
| 1.1 | 2026-07-14 | Reconciliation table line 132: changed ferrochain identifier from `Store` to `MemoryStore` to match canonical Rust trait name per BC-2.15.001 Architecture Anchors and module-decomposition.md:149 (F-P39-01, ADV-P1D-PASS-39) | F-P39-01 |
