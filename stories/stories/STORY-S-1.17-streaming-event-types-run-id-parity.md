---
document_type: story
level: ops
story_id: S-1.17
epic_id: E-09
version: "1.5"
status: draft
producer: story-writer
timestamp: 2026-08-24T12:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.001.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.002.md
  - .factory/specs/behavioral-contracts/ss-06/BC-2.06.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "70c134c"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.14, S-1.04, S-1.15]
blocks: [S-1.13, S-1.16, S-1.18, S-1.20, S-1.23, S-1.24]
behavioral_contracts: [BC-2.06.001, BC-2.06.002, BC-2.06.003]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: [pregolya-core, pregolya-graph]
subsystems: [SS-06]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
changelog:
  - "1.5 (round-48/R06-xref/2026-08-30): R06 gate — add cross-reference note after AC-005: StreamEvent::Error.error_message sanitized at emission per ADR-029 SEC-BOUND-001 / BC-2.12.007 {INV-004}; this story defines the StreamEvent type shape; sanitization guarantee owned by SSE emission boundary (S-1.27). No new ACs or TVs. input-hash refreshed (70c134c)."
  - "1.4 (P2-bc-completeness-burst-B/2026-08-26): BC-2.06.002 {EC-001}: AC-013 added — resume-run parent_ids copied verbatim from interrupted run; interrupted run_id NOT appended. BC table version bumped."
  - "1.3 (P2A-043 F-04/2026-08-24): old-form ordinal cross-refs converted to stable tags"
  - "1.2 (ADR-027 M3c/2026-08-24): escalation-resolution AC corrections — AC-008/AC-009 corrected to WITHIN-RUN (same run_id, unchanged parent_ids) per BC-2.06.002 INV-005+EC-002+TV-005; EC-003 swept (TD-VSDD-060)"
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors"
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
| BC-2.06.002 | run_id + parent_ids Correlation on Every Event | AC-007..AC-009, AC-013 |
| BC-2.06.003 | Streaming/Unary Identical Final Answer (DI-011 / NE-13) | AC-010..AC-012 |

## Acceptance Criteria

### AC-001 (traces to BC-2.06.001 PC-002 — 16 StreamEvent variants defined in core::events)
`StreamEvent` is an enum with exactly 16 variants: `RunStart`, `RunStream`, `RunEnd`, `StepStart`, `StepEnd`, `NodeStart`, `NodeStream`, `NodeEnd`, `ToolStart`, `ToolStream`, `ToolEnd`, `GuardrailDecision`, `ToolApprovalRequest`, `ToolApprovalResolved`, `CompactionEvent`, and `Error`. The enum is defined in `pregolya-core/src/events.rs` (`core::events`) and carries `#[non_exhaustive]`. Verified by `test_BC_2_06_001_stream_event_has_16_variants()`.

### AC-002 (traces to BC-2.06.001 PC-004 — causal ordering invariants)
Events maintain causal order: `RunStart` precedes all other run events; `StepStart` precedes `NodeStart` for nodes in that step; `NodeStart` precedes `NodeStream` and `NodeEnd` for the same node; `ToolStart` precedes `ToolStream` and `ToolEnd` for the same tool call. `StepEnd` has no `Stream` variant. Verified by `test_BC_2_06_001_causal_ordering_invariants()`.

### AC-003 (traces to BC-2.06.001 PC-004 — ToolEnd is always terminal for tool events)
`ToolEnd` is always the last event emitted for a tool call invocation. No tool events are emitted after `ToolEnd` for the same tool call ID. Verified by `test_BC_2_06_001_tool_end_is_terminal()`.

### AC-004 (traces to BC-2.06.001 PC-002 — GuardrailDecision carries only Fail or Transform)
`StreamEvent::GuardrailDecision.decision` is either `Fail` or `Transform` only — `Pass` decisions do not emit a `GuardrailDecision` event. Verified by `test_BC_2_06_001_guardrail_decision_only_fail_or_transform()`.

### AC-005 (traces to BC-2.06.001 PC-002 — StreamEvent::Error as 16th variant)
`StreamEvent::Error { run_id, error: PregolyaError, .. }` is the 16th variant. It can be emitted at any point during execution when an unrecoverable error occurs. Verified by `test_BC_2_06_001_error_variant_emittable()`.

> **Sanitization cross-reference (R06 gate):** `StreamEvent::Error.error_message` content is sanitized at emission per ADR-029 SEC-BOUND-001 (SEC-BOUND-001 External-Boundary Error-Sanitization). This story defines the `StreamEvent` type shape only; the sanitization guarantee is owned by the SSE emission boundary in S-1.27.

### AC-006 (traces to BC-2.06.001 EC-005 — RunEnd only for completed and summary_halt)
`RunEnd` is emitted only when the run transitions to `completed` or `summary_halt` final states. Runs that end in `failed`, `cancelled`, or `interrupted` states do NOT emit `RunEnd`. Verified by `test_BC_2_06_001_run_end_only_for_completed_or_summary_halt()`.

### AC-007 (traces to BC-2.06.002 PC-001 — every event carries run_id)
Every `StreamEvent` variant carries a `run_id: Uuid` field. No event is emitted without a `run_id`. Verified by `test_BC_2_06_002_every_event_carries_run_id()`.

### AC-008 (traces to BC-2.06.002 INV-005 + EC-002 + TV-005 — PUSH tasks are WITHIN-RUN, same run_id)
Events emitted by PUSH tasks spawned via the Send API carry the SAME `run_id` as the enclosing run (not a new or different `run_id`). `parent_ids` is UNCHANGED — identical to the enclosing run's `parent_ids`; it is NOT set to `[parent_run_id]`. Send-API fan-outs are within-run dispatches, not sub-runs (BC-2.06.002 INV-005; EC-002 and TV-005 are canonical test evidence). Verified by `test_BC_2_06_002_push_task_carries_same_run_id()`.

### AC-009 (traces to BC-2.06.002 INV-005 + TV-005 — Send subtask has same run_id, unchanged parent_ids)
For a subtask spawned by `Send("worker", arg)`, its events have `run_id` equal to the enclosing run's `run_id` (no new sub-run is created) and `parent_ids` is unchanged — NOT set to `[parent_run_id]`. This is consistent with AC-008: PUSH tasks are within-run (BC-2.06.002 INV-005; TV-005 is the canonical test vector). Verified by `test_BC_2_06_002_send_subtask_within_run_id()`.

### AC-010 (traces to BC-2.06.003 PC-001 — streaming and unary final answers identical)
For the same graph, same inputs, and same checkpointed state, the final answer returned by unary execution (`run()`) equals the final answer reconstructed from streaming events (`stream()` → collect → extract final message). Verified by `test_BC_2_06_003_streaming_unary_identical_final_answer()`.

### AC-011 (traces to BC-2.06.003 INV-001 — DI-011 no stub streaming path)
The streaming path uses the same BSP engine and the same node execution logic as the unary path. There is no `if streaming { stub_logic } else { real_logic }` conditional. Verified by `test_BC_2_06_003_streaming_uses_same_engine_as_unary()` (code inspection — assert no separate streaming stub path).

### AC-012 (traces to BC-2.06.003 INV-004 — GuardrailDecision not in unary final answer)
`StreamEvent::GuardrailDecision` events are stream-observer notifications only. The unary `run()` path does not return `GuardrailDecision` objects in its final answer. Verified by `test_BC_2_06_003_guardrail_decision_not_in_unary_answer()`.

### AC-013 (traces to BC-2.06.002 §{EC-001} + §{INV-001} + §{INV-002} — resume-run parent_ids copied verbatim; interrupted run_id NOT appended)
When a run is interrupted (via `interrupt()`) and the server creates a new `Run` record for the resumed execution: the resumed run receives a NEW `run_id` (per {INV-001} — it does not reuse the interrupted run's `run_id`). The resumed run's `parent_ids` is **copied verbatim** from the interrupted run's `parent_ids` at interrupt time; the interrupted run's `run_id` is NOT added to the resume run's `parent_ids`. A resume run is a continuation at the same nesting level, not a child run. Correlation between interrupted and resumed runs is via `parent_checkpoint_id` in checkpoint metadata (checkpoint-lineage contract in ss-04), not through `parent_ids`. Verified by `test_BC_2_06_002_resume_run_parent_ids_copied_not_appended()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| `StreamEvent` enum definition (16 variants, `Serialize`/`Deserialize`, `run_id`/`parent_ids`) | `pregolya-core/src/events.rs` (`core::events`) | Pure (type definition; per ADR-006 §Consequences) |
| Event emission abstraction | `pregolya-graph/src/event_emitter.rs` (`graph::event_emitter`) | Effectful (emits `StreamEvent` values; type defined in `core::events`) |
| Event emission in BSP engine | `pregolya-graph/src/bsp_engine.rs` | Effectful (sends to event channel) |
| Event emission in scheduler — NodeStart/NodeEnd/ToolStart/ToolEnd (`tick()`), StepEnd (`after_tick()`) | `pregolya-graph/src/scheduler.rs` (`graph::scheduler`) | Effectful (emits `StreamEvent` values; type defined in `core::events`) |
| `run()` unary executor | `pregolya-graph/src/scheduler.rs` | Effectful |
| `stream()` streaming executor | `pregolya-graph/src/scheduler.rs` | Effectful (tokio channel + yield) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/events.rs` (`StreamEvent` enum, `core::events`) | pure-core | Type definitions + `#[non_exhaustive]`; no execution logic; canonical home per ADR-006 §Consequences |
| `pregolya-graph/src/event_emitter.rs` (event emission abstraction) | effectful-shell | Emits `StreamEvent` values (type defined in `core::events`) to tokio channel |
| `bsp_engine.rs` (event emission sites) | effectful-shell | Sends events to unbounded tokio channel |
| `scheduler.rs` (run/stream dispatch) | effectful-shell | Orchestrates async execution; no pure-fn extraction needed for this story |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Graph run errors mid-stream | `StreamEvent::Error` emitted; stream yields the error event then closes |
| EC-002 | `RunEnd` attempted on `failed` run | Not emitted; `RunEnd` reserved for `completed`/`summary_halt` |
| EC-003 | Two nested Send fan-outs (grandparent → parent → child) | All levels share the same `run_id` (within-run; BC-2.06.002 INV-005); `parent_ids` is unchanged at each level — not appended. The causal chain topology is flat within a single run. |
| EC-004 | GuardrailDecision Fail with Critical severity | `StreamEvent::GuardrailDecision { decision: Fail, .. }` emitted; then `StreamEvent::Error`; `RunEnd` not emitted |
| EC-005 | StepEnd attempted with Stream variant | Not valid; `StepEnd` has no `Stream` variant per BC-2.06.001 PC-002 |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,000 |
| BC files (3 BCs) | ~4,500 |
| S-1.14 context (StateGraph, channels) | ~1,500 |
| `pregolya-core/src/events.rs` new file (enum definition) | ~600 |
| `pregolya-graph/src/event_emitter.rs` new file (emission abstraction) | ~400 |
| `bsp_engine.rs` event emission additions | ~1,000 |
| `scheduler.rs` run/stream additions | ~1,500 |
| Test files | ~2,500 |
| **Total** | **~15,000** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~7.4%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for all 12 ACs in `pregolya-graph/tests/streaming_events.rs`
2. [ ] Create `pregolya-core/src/events.rs` — `StreamEvent` enum with all 16 variants, `#[non_exhaustive]`, `Serialize`/`Deserialize` derives, `run_id` + `parent_ids` base correlation fields (per ADR-006 §Consequences)
3. [ ] Create `pregolya-graph/src/event_emitter.rs` — event emission abstraction that emits `StreamEvent` values (type from `core::events`) to tokio channel
4. [ ] Add `StreamEvent` emission sites to `pregolya-graph/src/bsp_engine.rs` — NodeStart/NodeEnd/NodeStream per node execution
5. [ ] Add `StreamEvent` emission to `pregolya-graph/src/scheduler.rs` — RunStart/RunEnd/StepStart/StepEnd; NodeStart/NodeEnd/ToolStart/ToolEnd in `tick()`, StepEnd in `after_tick()`
6. [ ] Implement `run()` unary executor and `stream()` streaming executor in `scheduler.rs` — same BSP engine, different output shape
7. [ ] Register all `event_type` values in Canonical Structured Event Catalog (SAP-1)
8. [ ] Write failing test `test_BC_2_06_002_resume_run_parent_ids_copied_not_appended()` for AC-013 (test-writer)
9. [ ] Run `cargo nextest run -p pregolya-core -p pregolya-graph --no-fail-fast` — all tests green

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.14 | Channel + reducer foundation; `bsp_engine.rs` partial creation (reduce phase, finish dispatch) | `mod.rs` re-export only | Streaming path MUST use the same `reduce_super_step` as unary — no separate implementation |
| S-1.15 | Conditional edges + Send API; `scheduler.rs` skeleton created — PUSH task queue, TASKS topic, `ctx.send()` | `scheduler.rs` file exists; S-1.17 adds `run()`/`stream()` executors and event emission | Confirm `scheduler.rs` exists and load its skeleton context before adding `run()` executor |
| S-1.04 | `PregolyaError` struct with category + code | All errors structured | `StreamEvent::Error` carries `PregolyaError` directly |

**Coordination note:** Coordinate `pregolya-graph/src/scheduler.rs` changes between S-1.13 (pre-super-step `ContextMutationConfig` initialization — before the super-step loop) and S-1.18 (per-super-step budget evaluation — inside the loop). Both depend on S-1.17's `run()` executor skeleton. The second PR to merge must rebase on the first.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `StreamEvent` carries `#[non_exhaustive]` | CLAUDE.md §`#[non_exhaustive]` on public API surface types | Non-exhaustive gate crate; wildcard arm required in all match sites |
| No separate streaming stub path — DI-011 | BC-2.06.003 INV-001 (NE-13) | Code review: no `if cfg!(feature = "streaming")` or equivalent |
| All `event_type` values in Canonical Structured Event Catalog | CLAUDE.md §Structured event catalog discipline (SAP-1) | Adversary SAP-1 probe on every PR touching this story |
| `RunEnd` emitted only for `completed`/`summary_halt` | BC-2.06.001 EC-005 | Unit test + run state enum exhaustive match |
| `GuardrailDecision` carries `Fail`/`Transform` only | BC-2.06.001 PC-002 | Match arm compilation with exhaustive variants |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `tokio` | workspace-pinned | Async event channel (`tokio::sync::mpsc` for streaming) |
| `uuid` | workspace-pinned | `run_id` and `parent_ids` UUIDs |
| `tracing` | workspace-pinned | Structured log emission alongside `StreamEvent` |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/events.rs` | create | `StreamEvent` enum (all 16 variants), `Serialize`/`Deserialize` derives, `run_id`/`parent_ids` base correlation fields per BC-2.06.002; `#[non_exhaustive]` |
| `pregolya-graph/src/event_emitter.rs` | create | Event emission abstraction; emits `StreamEvent` values (type defined in `core::events`) to tokio channel |
| `pregolya-graph/src/bsp_engine.rs` | modify | Node-level `StreamEvent` emission (NodeStart/Stream/End) |
| `pregolya-graph/src/scheduler.rs` | modify | Run/step-level events; `run()` unary + `stream()` streaming executors; NodeStart/NodeEnd/ToolStart/ToolEnd emitted in `tick()`, StepEnd in `after_tick()` |
| `pregolya-core/src/lib.rs` | modify | Re-export `StreamEvent` from `events` module |
| `pregolya-graph/src/lib.rs` | modify | Re-export `event_emitter` module; re-export `StreamEvent` via `pregolya-core` |
| `pregolya-graph/tests/streaming_events.rs` | create | AC-001..AC-012 tests |
