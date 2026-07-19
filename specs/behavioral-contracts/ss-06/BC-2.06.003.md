---
document_type: behavioral-contract
level: L3
bc_id: BC-2.06.003
version: "1.3"
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
changelog:
  - "1.1 (F-P91-01, 2026-07-17): EC-005 sweep fix — 'BudgetPolicy with on_ceiling = halt' → 'BudgetConfig with on_ceiling = OnCeiling::Halt'. on_ceiling is a field of BudgetConfig (interface-definitions v2.29 §BudgetConfig); BudgetPolicy::evaluate is pure and data-free. Part of the full SS-10 + corpus sweep for BudgetPolicy::on_ceiling mis-attributions."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-server / ferrochain-graph per module-decomposition.md v1.10."
  - "1.3 (F-P99-01, 2026-07-17): Architect GuardrailDecision amendments (ADR-006 rev-3). New invariant added: GuardrailDecision is a stream-observer notification only — not emitted in unary mode; GuardrailHook::evaluate fires on both paths per DI-012; absence from unary output is NOT a DI-011 violation (execution-path vs stream-observer equivalence)."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-007
  - domain-spec/invariants.md#DI-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "945187b"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.06.003: Streaming and Unary Run Produce Identical Final Answer (NE-13)

## Description

A graph executed via the streaming endpoint and the same graph executed via the unary endpoint
must produce the same final `GraphState` given identical inputs and starting checkpoint. There
is no stub streaming path that emits synthetic events without invoking the real execution engine
(DI-011). NE-13 calls out the adk-rust streaming stub — which emits task-state events without
running the graph — as the counter-example ferrochain must reject. Every guardrail hook, reducer,
and checkpoint write that fires on the unary path must also fire on the streaming path.

## Preconditions

1. A `StateGraph` is compiled and registered with `ferrochain-server`.
2. Two identically-configured Runs are created: Run A via the streaming endpoint, Run B via
   the unary endpoint, both targeting the same `assistant_id`, `thread_id`, and starting checkpoint.
3. Any node functions in the graph are deterministic given the same random seed (or the same
   LLM mock is used in tests).
4. Neither run has been interrupted or resumed before execution begins.

## Postconditions

1. Run A's `final_output` (the `GraphState` at the terminal node) is byte-identical to
   Run B's `final_output` when node functions are deterministic.
2. Run A and Run B execute the same set of nodes in the same topological order, producing
   the same `put_writes` records to the checkpoint store.
3. Every guardrail hook, reducer, and budget policy evaluation that fires in Run B also fires
   in Run A (no code path is bypassed on the streaming path).
4. Run A's event stream contains a `RunEnd` event whose `final_output` field matches Run B's
   returned output.
5. If Run A's stream consumer disconnects before `RunEnd`, the run continues to completion in
   the background (default behavior); the checkpoint records the same final state as Run B.

## Invariants

- **DI-011 (Streaming / Unary Run Equivalence):** The streaming and unary endpoints must
  invoke the same underlying `execute_run(graph, config, checkpoint_saver)` function. Any
  code path that takes a streaming-only shortcut (e.g., emitting cached events, bypassing the
  Pregel loop) is a hard violation of DI-011.
- Both endpoints share the same guardrail invocation points (DI-012: guardrails fire at
  tool-result, RAG, and memory ingress regardless of call path).
- Both endpoints share the same budget evaluation points (BC-2.10.001: BudgetPolicy
  evaluates after each LLM call and each tool invocation regardless of call path).
- **GuardrailDecision is a stream-observer notification only (F-P99-01):** `StreamEvent::GuardrailDecision`
  is not emitted in unary mode. The underlying `GuardrailHook::evaluate` call fires on BOTH
  streaming and unary execution paths per DI-012 — the guardrail decision itself is
  execution-path equivalent. The absence of `GuardrailDecision` events from the unary response
  is NOT a DI-011 violation: DI-011 mandates execution-path equivalence (same engine, same
  guardrail calls, same final output), not stream-observer equivalence (both surfaces emitting
  identical events). Unary callers observe guardrail outcomes through the final output shape
  (error blocks in graph state), not real-time events (ADR-006 rev-3 §Consequences).

## Edge Cases

### EC-001: Non-deterministic node (LLM with temperature > 0, no fixed seed)
**Scenario:** The graph contains an LLM node with `temperature=0.7` and no fixed random seed.
**Expected behavior:** Run A and Run B may produce different token content (non-deterministic
LLM outputs). The BC guarantees code-path equivalence (same nodes executed, same guardrails
called, same checkpoint writes), not token-level output identity under different random seeds.
Test environments must use deterministic LLM mocks to assert full output equality.

### EC-002: Streaming endpoint with SSE consumer disconnection (default behavior)
**Scenario:** The stream consumer disconnects after receiving `StepStart` for step 2. The
server observes the disconnection.
**Expected behavior:** By default (`cancel_on_disconnect = false`), the graph continues to
completion. The final checkpoint state equals what a completed unary run would produce.
No events are delivered to the dropped consumer, but the run's final state is preserved.

### EC-003: Streaming endpoint with `cancel_on_disconnect = true` (explicit opt-in)
**Scenario:** Server config sets `cancel_on_disconnect = true`. Consumer disconnects mid-run.
**Expected behavior:** The run is cancelled at the next safe super-step boundary. The final
state is the checkpoint from the last completed super-step — the same state a cancelled
unary run would reach at that same boundary. This is a deliberate, documented deviation from
the full-completion default. DI-011 equivalence holds up to the cancellation point.

### EC-004: GuardrailHook rejects tool result on streaming path
**Scenario:** A tool returns content that `GuardrailHook` rejects. The streaming endpoint is used.
**Expected behavior:** The guardrail fires identically on the streaming path and on the unary
path (DI-012). The rejected content does not enter the model context in either path. The final
answer (error or fallback content) is the same in both runs.

### EC-005: Budget ceiling reached during streaming run
**Scenario:** A `BudgetConfig` with `on_ceiling = OnCeiling::Halt` (BC-2.10.003) is configured. The
ceiling is reached during the streaming run.
**Expected behavior:** Both the streaming run and a hypothetical equivalent unary run halt at
the same step with the same error. The event stream for the streaming run ends with an error
event; the unary run returns the error in the response body. Final checkpoint state is
equivalent in both.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Two-node ReAct graph (reason → tool → reason) with deterministic LLM mock; streaming vs unary | Final answer strings byte-identical; `put_writes` records match; same nodes traversed | Happy path — DI-011 core assertion |
| TV-002 | Graph with `GuardrailHook` that rejects a tool result; streaming vs unary | Both final answers reflect the guardrail rejection error; guardrail called same number of times | DI-012 consistency across call paths |
| TV-003 | Graph with `interrupt()` + resume; streaming vs unary post-resume | Post-resume final answers are identical; interrupted checkpoint state is the same | Interrupt + resume does not fork execution paths |
| TV-004 | Streaming endpoint, consumer disconnects after step 1 (default behavior) | Run completes; final checkpoint equals same graph run via unary | Default: no cancellation on disconnect |
| TV-005 | Budget ceiling hit mid-run (BC-2.10.003); streaming vs unary | Both halt at same super-step; both checkpoint identical final state; streaming emits error event | Budget governance applies equally to both paths |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-STREAM-03 | Streaming endpoint and unary endpoint produce identical final `GraphState` for identical inputs and deterministic node functions | Integration test — execute same graph via both endpoints; compare final checkpoint state (msgpack bytes) | Phase 1 |

## Related BCs

- BC-2.06.001 — composes with: event taxonomy is trustworthy only because this BC guarantees the events are emitted by the real engine
- BC-2.12.007 — related to: the server-level streaming / unary equivalence for ferrochain-server is the server-side analog of this graph-level BC
- BC-2.05.001 — related to: interrupt on the streaming path must not produce a different checkpoint than the unary path
- BC-2.10.003 — related to: budget halt behavior must be the same on both paths (covered by EC-005 above)

## Architecture Anchors

- `ferrochain-server/src/run_handler.rs` — streaming and unary endpoints must call the same underlying `execute_run(graph, config, checkpoint_saver)` function; no streaming-specific branch in execution logic
- `ferrochain-graph/src/pregel/mod.rs` — single `Pregel::execute` or equivalent function used by both paths; streaming is a presentation layer concern, not an execution logic difference

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-STREAM-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-007 |
| Capability Anchor Justification | CAP-007 ("Structured Streaming Event Taxonomy") per capabilities-p0.md §CAP-007 — this BC enforces the "Streaming and unary runs drive the same engine and produce identical final answers" clause stated verbatim in CAP-007 |
| L2 Domain Invariants | DI-011 (Streaming / Unary Run Equivalence) |
| D17 Commitment | NE-13 (adk-rust streaming stub that emits task-state events without invoking the graph engine is the counter-example; see part-3-conflicts-negative-evidence.md CONFLICT-5) |
| CONFLICT Reference | CONFLICT-5 |
| NE Reference | NE-13 |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | I (integration) |
| Module | ferrochain-server / ferrochain-graph |
