---
document_type: behavioral-contract
level: L3
bc_id: BC-2.06.001
version: "1.4"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-06
capability: CAP-007
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-007
  - domain-spec/invariants.md#DI-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/events.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "c00caaf"
changelog:
  - "1.0 (initial): base BC authored."
  - "1.1 (ADV-P1D-PASS-46): F-P46-01 adjudication — add EC-005 (failed-run stream termination). BC-2.06.001 PC2 states RunEnd emits 'once at run completion' (completion-only contract) but had no explicit edge case for failed runs. EC-005 makes the authority explicit: stream closes after error SSE event; no RunEnd emitted on failure. This resolves EC-001 hedge in BC-2.12.007 and establishes the source-of-truth for failure-termination across the streaming surface."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph / ferrochain-server per module-decomposition.md v1.10."
  - "1.3 (F-P99-01, 2026-07-17): Architect GuardrailDecision amendments (ADR-006 rev-3). (a) PC2 — added GuardrailDecision bullet (12th variant) after ToolEnd; updated ToolEnd bullet to reference post-guardrail content semantics per interface-definitions §StreamEvent. (b) PC4 causal ordering updated with GuardrailDecision[RagChunk|MemoryItem]* and GuardrailDecision[ToolResult]* positions. (c) New EC-006: N ContentBlocks K rejected → K GuardrailDecision events in evaluation order before ONE ToolEnd with post-guardrail output. H1 title updated to include guardrail_decision."
  - "1.4 (F-P117-01, fix burst 120, 2026-07-19): EC-005 — clarify summary_halt (budget OnCeiling::Summarize terminal state) DOES emit RunEnd with the summarize model response as output (like completed, not like failed). Updated EC-005 final rule sentence to enumerate output-producing states (completed + summary_halt → RunEnd emitted) vs. non-output terminal states (failed, cancelled) and paused state (interrupted) → stream ends without RunEnd."
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.06.001: Typed Per-Phase Event Taxonomy (run/step/node/tool start-stream-end; guardrail_decision)

## Description

The graph execution engine emits a strictly typed `StreamEvent` for every phase transition
during a run. Events are grouped into four lifecycle categories — Run, Step, Node, Tool —
each with Start / Stream / End variants carrying phase-specific typed payloads. CONFLICT-5
mandates this typed taxonomy; the adk-rust flat `Event` envelope (agent-turn lifecycle only,
no `run_id` correlation tree, no per-phase Start/End pairs) is the rejected counter-example.
Wire format is ferrochain-native (not LangChain astream_events v2 wire compat) per D13.

## Preconditions

1. A compiled `StateGraph` is executing (a `Run` is in `in_progress` status).
2. A consumer has subscribed to the run's event stream (streaming endpoint or callback listener).
3. Each node in the graph is a `Runnable`.
4. The execution engine is the same engine used by both streaming and unary runs (DI-011 —
   no stub streaming path may exist).

## Postconditions

1. For every phase transition that occurs during the run, exactly one typed `StreamEvent`
   variant is emitted in the ordering specified below.
2. The emitted event set covers all of the following variants when the corresponding phase
   occurs during the run:
   - `StreamEvent::RunStart` — once at run beginning; carries `run_id`, `config`
   - `StreamEvent::RunStream` — once per output chunk surfaced at the run boundary
   - `StreamEvent::RunEnd` — once at run completion; carries `run_id`, `status`, `final_output`
   - `StreamEvent::StepStart` — once per super-step; carries `run_id`, `step_count`, scheduled tasks
   - `StreamEvent::StepEnd` — once per super-step after all reducers applied; carries `updated_channels`
   - `StreamEvent::NodeStart` — once per node execution; carries `run_id`, `node_name`, frozen input
   - `StreamEvent::NodeStream` — once per token / chunk yielded by a streaming node
   - `StreamEvent::NodeEnd` — once per node execution at completion; carries `node_name`, output
   - `StreamEvent::ToolStart` — once per tool invocation; carries `run_id`, `tool_name`, `tool_call_id`, input
   - `StreamEvent::ToolStream` — once per chunk from a streaming tool (if tool streams)
   - `StreamEvent::ToolEnd` — once per tool invocation at completion; carries `tool_call_id`, post-guardrail output — see interface-definitions §StreamEvent ToolEnd content semantics (F-P99-01)
   - `StreamEvent::GuardrailDecision` — zero or more per boundary phase; emitted for Fail and Transform outcomes only (Pass is never streamed); carries `boundary` (IngressBoundary: ToolResult/RagChunk/MemoryItem), `decision` (GuardrailDecisionKind: Fail/Transform), `reason` (Option<String>, Some for Fail only), `severity` (Option<GuardrailSeverityWire>, Some for Fail only), `ingress_id` (Uuid), `tool_call_id` (Option<String>, Some for ToolResult boundary only); emits BEFORE ToolEnd (ToolResult boundary) or within NodeStart/NodeEnd before inference (RAG/Memory boundaries)
3. Each event carries `run_id` (UUID) and `parent_ids` (ordered ancestry list) per BC-2.06.002.
4. Events are emitted in the following causal ordering (updated F-P99-01):
   ```
   RunStart
     → (StepStart
         → (NodeStart
             → GuardrailDecision[RagChunk|MemoryItem]*   // RAG/Memory boundary: within NodeStart/NodeEnd; before inference
             → (ToolStart
                 → GuardrailDecision[ToolResult]*         // ToolResult boundary: within ToolStart/ToolEnd; before ToolEnd
                 → ToolEnd                                // always the final event in its window
               )*
             → NodeEnd
           )*
         → StepEnd
       )*
   → RunEnd
   ```
   `GuardrailDecision*` = zero or more — one per non-Pass ContentBlock/chunk/item. `ToolEnd` is always the final event in its window.
5. No event is emitted from a code path that bypasses actual graph execution.

## Invariants

- **DI-011 (Streaming / Unary Run Equivalence):** The streaming event emission path is driven
  by the same execution engine as the unary path. A stub that emits synthetic events without
  executing the graph is a hard violation.
- Start-before-end: every `*Start` event for a phase unit is emitted before the corresponding
  `*End` event for that same unit (sourced from semport/core/behavioral-intent.md §D-2).
- `StreamEvent` variants are typed enum members, not stringly-typed JSON blobs with a dynamic
  `"event"` string key. The consumer can exhaustively match on variant without string comparison.
- An event for a phase that does not occur (e.g., `ToolStart` when no tool is called) is
  NOT emitted — the taxonomy is exhaustive only over phases that actually execute.

## Edge Cases

### EC-001: Empty super-step (no tasks triggered)
**Scenario:** A super-step produces zero tasks (graph frontier is empty from the start — a
natural halt condition).
**Expected behavior:** `StepStart` is NOT emitted for a zero-task step. `RunEnd` is emitted
after the last productive `StepEnd`. No ghost `StepStart/StepEnd` pair is emitted.

### EC-002: Non-streaming node (synchronous Runnable)
**Scenario:** A node function returns a complete output synchronously (no internal streaming).
**Expected behavior:** `NodeStart` and `NodeEnd` are emitted with zero intervening `NodeStream`
events. Consumers must tolerate a `NodeStart`/`NodeEnd` pair with no `NodeStream` in between.

### EC-003: Consumer drops stream mid-run
**Scenario:** The stream consumer disconnects after `NodeStart` but before `NodeEnd`.
**Expected behavior:** By default, graph execution continues to completion (stream cancellation
does not cancel the underlying run). No partial event sequences are delivered to a dropped
consumer; the run's final state is preserved in the checkpoint.

### EC-004: Nested subgraph emits its own events
**Scenario:** A node invokes a subgraph (nested `StateGraph` execution).
**Expected behavior:** Subgraph events carry a distinct `run_id` with the parent run's `run_id`
in `parent_ids`. No subgraph event is swallowed; consumers reconstruct the nested call tree
by traversing `parent_ids` (see BC-2.06.002).

### EC-005: Node raises error mid-run (failed-run stream termination — adjudicated from PC2)
**Scenario:** A node function returns `Err(FerrochainError)` during execution.
**Expected behavior:** The execution engine emits an `error` SSE event carrying the
`FerrochainError` payload; the event stream then closes. `RunEnd` is NOT emitted for
a failed run — `RunEnd` is reserved for the completion path (PC2: "once at run completion").
The run record transitions to `failed` status, queryable via `GET /threads/{thread_id}/runs/{run_id}`.
No partial or ghost `RunEnd` event with `status: "failed"` is emitted.
**Adjudication note (F-P46-01, ADV-P1D-PASS-46):** PC2's completion-only `RunEnd` contract
did not previously have an explicit failed-run EC. This EC makes the rule unambiguous and is
the authority cited by BC-2.12.007 EC-001 (failure path) and BC-2.12.007 EC-003 (interrupt path).
The minimal coherent rule consistent with PC2: `RunEnd` fires for every terminal state that
produces a final output — `completed` (graph reaches END) and `summary_halt` (budget
OnCeiling::Summarize path; BC-2.10.003 PC8 — model response IS the final output). Non-output
terminal states (`failed`, `cancelled`) and the paused state (`interrupted`) end the stream
without `RunEnd`. Authority for summary_halt: BC-2.10.003 PC8(c)(d); BC-2.12.003 PC8 v1.4.

### EC-006: Multiple ContentBlocks with partial rejection at ToolResult boundary (F-P99-01)
**Scenario:** A single tool invocation produces N ContentBlocks. K of them (0 < K ≤ N) are
rejected or transformed by the `GuardrailHook` evaluation.
**Expected behavior:** K `GuardrailDecision` events are emitted in evaluation order (one per
rejected/transformed ContentBlock, preserving the order in which the hook evaluated each block)
BEFORE the single enclosing `ToolEnd`. Exactly ONE `ToolEnd` is then emitted, carrying the
post-guardrail output (error blocks substituted at the positions of rejected ContentBlocks;
passed/transformed content included). Zero bytes of the K rejected ContentBlocks appear in any
`StreamEvent` payload — including the K `GuardrailDecision` events themselves, which carry
metadata only (reason, severity, ingress_id, tool_call_id). The batch-then-single-ToolEnd
structure ensures the ToolEnd always remains the terminal event in the ToolStart/ToolEnd window.
**Phase-3 test obligation:** A test for this EC should exercise a multi-ContentBlock tool result
with at least one rejection to verify the ordering invariant (K events before 1 ToolEnd) and
the zero-bytes guarantee on all emitted events.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Single-node graph, non-streaming node | `RunStart → StepStart → NodeStart → NodeEnd → StepEnd → RunEnd` (6 events total) | Happy path — minimal linear trace |
| TV-002 | Single-node graph with streaming LLM node producing 3 token chunks | `RunStart → StepStart → NodeStart → NodeStream × 3 → NodeEnd → StepEnd → RunEnd` (8 events) | Streaming token sequence preserved |
| TV-003 | Two-node graph; node B calls one tool | `RunStart → StepStart(1) → NodeStart(A) → NodeEnd(A) → StepEnd(1) → StepStart(2) → NodeStart(B) → ToolStart → ToolEnd → NodeEnd(B) → StepEnd(2) → RunEnd` | Tool events nested inside Node execution |
| TV-004 | Graph interrupted via `interrupt()` after `NodeStart(B)` | `RunStart → StepStart → NodeStart(A) → NodeEnd(A) → StepStart(2) → NodeStart(B) → (interrupt halts stream)` — `RunEnd` not emitted for interrupted run | Interrupt truncates event stream at boundary |
| TV-005 | Subgraph invoked from node B | Parent events carry `parent_ids = []`; subgraph events carry `parent_ids = [parent_run_id]` | Parent_ids nesting per BC-2.06.002 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-STREAM-01 | Start-before-end ordering holds for every (Start, End) pair in all 4 event groups | Property test (proptest) — generate random graph configs; verify ordering invariant on collected event sequence | Phase 1 |
| VP-STREAM-02 | All events for a run share the same `run_id`; subgraph events carry correct `parent_ids` | Integration test — collect and validate UUID shape + parent chain | Phase 1 |

## Related BCs

- BC-2.06.002 — composes with: `run_id` + `parent_ids` correlation is specified there; this BC specifies the event types themselves
- BC-2.06.003 — depends on: streaming equivalence requires this taxonomy to be emitted by the real engine (no stub)
- BC-2.10.001 — related to: `BudgetEvaluated` is an internal engine event; it is not a `StreamEvent` variant but co-occurs with these phase boundaries
- BC-2.05.001 — related to: an interrupt halts the event stream at `NodeStart`; the resume produces a new `RunStart` sequence

## Architecture Anchors

- `ferrochain-graph/src/pregel/events.rs` — `StreamEvent` enum definition with all phase variants
- `ferrochain-graph/src/pregel/loop.rs` — emission points inside `tick()` (NodeStart/End, ToolStart/End) and `after_tick()` (StepEnd)
- `ferrochain-server/src/streaming.rs` — SSE / streaming endpoint that yields `StreamEvent` to callers

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-STREAM-01, VP-STREAM-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-007 |
| Capability Anchor Justification | CAP-007 ("Structured Streaming Event Taxonomy") per capabilities-p0.md §CAP-007 — this BC specifies the exact typed per-phase event variants (Run/Step/Node/Tool × Start/Stream/End) that constitute the "typed per-phase streaming events" named in CAP-007 |
| L2 Domain Invariants | DI-011 (Streaming / Unary Run Equivalence) |
| D17 Commitment | CONFLICT-5 — typed per-phase event taxonomy (Start/Stream/End per operation type) is the design mandate; adk-rust flat `Event` envelope is the rejected counter-example |
| CONFLICT Reference | CONFLICT-5 (adk-rust flattened Event envelope vs. astream_events v2 typed taxonomy per semport/core/behavioral-intent.md §D-2) |
| NE Reference | NE-13 (streaming stub must not exist; see BC-2.06.003) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit / property), I (integration) |
| Module | ferrochain-graph / ferrochain-server |
