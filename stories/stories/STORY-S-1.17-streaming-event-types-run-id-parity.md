---
document_type: story
level: ops
story_id: S-1.17
epic_id: E-09
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "4997925"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.14, S-1.04]
blocks: [S-1.20, S-1.23, S-1.24]
behavioral_contracts: [BC-2.06.001, BC-2.06.002, BC-2.06.003]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-06]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

> **tdd_mode:** strict — full TDD Iron Law enforced.

> **Execute:** `/vsdd-factory:deliver-story S-1.17`

# S-1.17: Streaming Event Types, Causal Ordering, and Unary/Streaming Parity

## Narrative

- **As a** graph runtime developer building the pregolya-graph event emission system
- **I want to** define the 16-variant `StreamEvent` enum with causal ordering, correlate every event with `run_id` and `parent_ids`, and guarantee that streaming and unary execution paths produce identical final answers
- **So that** consumers can observe graph execution via a typed event stream, events are causally ordered and correlated, and the streaming path is not a second-class implementation (DI-011 / NE-13)

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.06.001 | 16 StreamEvent Variants with Causal Ordering | AC-001..AC-006 |
| BC-2.06.002 | run_id + parent_ids Correlation on Every Event | AC-007..AC-009 |
| BC-2.06.003 | Streaming/Unary Identical Final Answer (DI-011 / NE-13) | AC-010..AC-012 |

## Acceptance Criteria

### AC-001 (traces to BC-2.06.001 postcondition 1 — 16 StreamEvent variants defined)
`StreamEvent` is an enum with exactly 16 variants: `RunStart`, `RunStream`, `RunEnd`, `StepStart`, `StepEnd`, `NodeStart`, `NodeStream`, `NodeEnd`, `ToolStart`, `ToolStream`, `ToolEnd`, `GuardrailDecision`, `ToolApprovalRequest`, `ToolApprovalResolved`, `CompactionEvent`, and `Error`. The enum carries `#[non_exhaustive]`. Verified by `test_BC_2_06_001_stream_event_has_16_variants()`.

### AC-002 (traces to BC-2.06.001 postcondition 2 — causal ordering invariants)
Events maintain causal order: `RunStart` precedes all other run events; `StepStart` precedes `NodeStart` for nodes in that step; `NodeStart` precedes `NodeStream` and `NodeEnd` for the same node; `ToolStart` precedes `ToolStream` and `ToolEnd` for the same tool call. `StepEnd` has no `Stream` variant. Verified by `test_BC_2_06_001_causal_ordering_invariants()`.

### AC-003 (traces to BC-2.06.001 postcondition 3 — ToolEnd is always terminal for tool events)
`ToolEnd` is always the last event emitted for a tool call invocation. No tool events are emitted after `ToolEnd` for the same tool call ID. Verified by `test_BC_2_06_001_tool_end_is_terminal()`.

### AC-004 (traces to BC-2.06.001 postcondition 4 — GuardrailDecision carries only Fail or Transform)
`StreamEvent::GuardrailDecision.decision` is either `Fail` or `Transform` only — `Pass` decisions do not emit a `GuardrailDecision` event. Verified by `test_BC_2_06_001_guardrail_decision_only_fail_or_transform()`.

### AC-005 (traces to BC-2.06.001 postcondition 5 — StreamEvent::Error as 16th variant)
`StreamEvent::Error { run_id, error: PregolyaError, .. }` is the 16th variant. It can be emitted at any point during execution when an unrecoverable error occurs. Verified by `test_BC_2_06_001_error_variant_emittable()`.

### AC-006 (traces to BC-2.06.001 postcondition 6 — RunEnd only for completed and summary_halt)
`RunEnd` is emitted only when the run transitions to `completed` or `summary_halt` final states. Runs that end in `failed`, `cancelled`, or `interrupted` states do NOT emit `RunEnd`. Verified by `test_BC_2_06_001_run_end_only_for_completed_or_summary_halt()`.

### AC-007 (traces to BC-2.06.002 postcondition 1 — every event carries run_id)
Every `StreamEvent` variant carries a `run_id: Uuid` field. No event is emitted without a `run_id`. Verified by `test_BC_2_06_002_every_event_carries_run_id()`.

### AC-008 (traces to BC-2.06.002 postcondition 2 — fan-out PUSH tasks share parent run_id)
Events emitted by PUSH tasks spawned via the Send API carry the parent run's `run_id` in their `parent_ids` array (not as the event's own `run_id`). Verified by `test_BC_2_06_002_fanout_tasks_share_parent_run_id()`.

### AC-009 (traces to BC-2.06.002 postcondition 3 — parent_ids enables causal chain reconstruction)
For a subtask spawned by `Send("worker", arg)`, its events have `parent_ids: [parent_run_id]`. The full causal chain (grandparent → parent → child) is reconstructable by following `parent_ids`. Verified by `test_BC_2_06_002_parent_ids_enables_causal_chain()`.

### AC-010 (traces to BC-2.06.003 postcondition 1 — streaming and unary final answers identical)
For the same graph, same inputs, and same checkpointed state, the final answer returned by unary execution (`run()`) equals the final answer reconstructed from streaming events (`stream()` → collect → extract final message). Verified by `test_BC_2_06_003_streaming_unary_identical_final_answer()`.

### AC-011 (traces to BC-2.06.003 invariant 1 — DI-011 no stub streaming path)
The streaming path uses the same BSP engine and the same node execution logic as the unary path. There is no `if streaming { stub_logic } else { real_logic }` conditional. Verified by `test_BC_2_06_003_streaming_uses_same_engine_as_unary()` (code inspection — assert no separate streaming stub path).

### AC-012 (traces to BC-2.06.003 invariant 2 — GuardrailDecision not in unary final answer)
`StreamEvent::GuardrailDecision` events are stream-observer notifications only. The unary `run()` path does not return `GuardrailDecision` objects in its final answer. Verified by `test_BC_2_06_003_guardrail_decision_not_in_unary_answer()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| `StreamEvent` enum definition | `pregolya-graph/src/event.rs` | Pure (type definition) |
| Event emission in BSP engine | `pregolya-graph/src/bsp_engine.rs` | Effectful (sends to event channel) |
| Event emission in scheduler | `pregolya-graph/src/scheduler.rs` | Effectful (run lifecycle events) |
| `run()` unary executor | `pregolya-graph/src/scheduler.rs` | Effectful |
| `stream()` streaming executor | `pregolya-graph/src/scheduler.rs` | Effectful (tokio channel + yield) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `event.rs` (`StreamEvent` enum) | pure-core | Type definitions + `#[non_exhaustive]`; no execution logic |
| `bsp_engine.rs` (event emission sites) | effectful-shell | Sends events to unbounded tokio channel |
| `scheduler.rs` (run/stream dispatch) | effectful-shell | Orchestrates async execution; no pure-fn extraction needed for this story |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Graph run errors mid-stream | `StreamEvent::Error` emitted; stream yields the error event then closes |
| EC-002 | `RunEnd` attempted on `failed` run | Not emitted; `RunEnd` reserved for `completed`/`summary_halt` |
| EC-003 | Two nested Send fan-outs (grandparent → parent → child) | Each level carries its parent's `run_id` in `parent_ids`; chain is reconstructable |
| EC-004 | GuardrailDecision Fail with Critical severity | `StreamEvent::GuardrailDecision { decision: Fail, .. }` emitted; then `StreamEvent::Error`; `RunEnd` not emitted |
| EC-005 | StepEnd attempted with Stream variant | Not valid; `StepEnd` has no `Stream` variant per BC-2.06.001 postcondition 2 |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,000 |
| BC files (3 BCs) | ~4,500 |
| S-1.14 context (StateGraph, channels) | ~1,500 |
| `event.rs` new file | ~800 |
| `bsp_engine.rs` event emission additions | ~1,000 |
| `scheduler.rs` run/stream additions | ~1,500 |
| Test files | ~2,500 |
| **Total** | **~14,800** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~7.4%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for all 12 ACs in `pregolya-graph/tests/streaming_events.rs`
2. [ ] Create `pregolya-graph/src/event.rs` — `StreamEvent` enum with 16 variants, `#[non_exhaustive]`, `run_id` + `parent_ids` fields
3. [ ] Add `StreamEvent` emission sites to `pregolya-graph/src/bsp_engine.rs` — NodeStart/NodeEnd/NodeStream per node execution
4. [ ] Add `StreamEvent` emission to `pregolya-graph/src/scheduler.rs` — RunStart/RunEnd/StepStart/StepEnd
5. [ ] Implement `run()` unary executor and `stream()` streaming executor in `scheduler.rs` — same BSP engine, different output shape
6. [ ] Register all `event_type` values in Canonical Structured Event Catalog (SAP-1)
7. [ ] Run `cargo nextest run -p pregolya-graph --no-fail-fast` — all tests green

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.14 | Channel + reducer foundation; `bsp_engine.rs` reduce logic | `mod.rs` re-export only | Streaming path MUST use the same `reduce_super_step` as unary — no separate implementation |
| S-1.04 | `PregolyaError` struct with category + code | All errors structured | `StreamEvent::Error` carries `PregolyaError` directly |

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `StreamEvent` carries `#[non_exhaustive]` | CLAUDE.md §`#[non_exhaustive]` on public API surface types | Non-exhaustive gate crate; wildcard arm required in all match sites |
| No separate streaming stub path — DI-011 | BC-2.06.003 invariant 1 (NE-13) | Code review: no `if cfg!(feature = "streaming")` or equivalent |
| All `event_type` values in Canonical Structured Event Catalog | CLAUDE.md §Structured event catalog discipline (SAP-1) | Adversary SAP-1 probe on every PR touching this story |
| `RunEnd` emitted only for `completed`/`summary_halt` | BC-2.06.001 postcondition 6 | Unit test + run state enum exhaustive match |
| `GuardrailDecision` carries `Fail`/`Transform` only | BC-2.06.001 postcondition 4 | Match arm compilation with exhaustive variants |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `tokio` | workspace-pinned | Async event channel (`tokio::sync::mpsc` for streaming) |
| `uuid` | workspace-pinned | `run_id` and `parent_ids` UUIDs |
| `tracing` | workspace-pinned | Structured log emission alongside `StreamEvent` |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-graph/src/event.rs` | create | `StreamEvent` enum (16 variants), `#[non_exhaustive]`, `run_id`, `parent_ids` |
| `pregolya-graph/src/bsp_engine.rs` | modify | Node-level `StreamEvent` emission (NodeStart/Stream/End) |
| `pregolya-graph/src/scheduler.rs` | modify | Run/step-level events; `run()` unary + `stream()` streaming executors |
| `pregolya-graph/src/lib.rs` | modify | Re-export `StreamEvent` from `event` module |
| `pregolya-graph/tests/streaming_events.rs` | create | AC-001..AC-012 tests |
