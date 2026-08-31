---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-31T00:00:00Z
phase: 2
domain: D
domain_name: Autonomous Research Orchestrator
id: HS-D-007
title: "Durable Audit-Grade Trajectory Replay"
category: edge-case-combinations
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.04.001
  - BC-2.04.005
  - BC-2.04.003
  - BC-2.03.001
  - BC-2.06.001
  - BC-2.06.002
inputs:
  - .factory/specs/prd.md
input-hash: "b7af049"
traces_to: .factory/specs/prd.md
lifecycle_status: active
introduced: v1.0.0-phase-2-newuc
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - graph_execution
  - checkpoint_resume
  - streaming
changelog:
  - "1.0 (initial/2026-08-31): Domain D HS-D-007 authored for autonomous research orchestrator use case."
---

# Holdout Scenario HS-D-007: Durable Audit-Grade Trajectory Replay

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A research orchestrator completes a multi-step run and its full event and trajectory record is persisted in a durable checkpoint store. A subsequent replay operation in a fresh process loads the persisted trajectory and re-executes the run's decision sequence using the stored data — without making new external calls — producing a reconstructed event log. The scenario verifies that the replay is deterministic: it reproduces the same node execution sequence, the same output values at each node, and the same terminal result as the original run. The replay must terminate cleanly; it must not loop indefinitely on a run that already reached its terminal condition.

**Given:**
- A graph with at least four sequential nodes, each producing a typed output record written to the checkpoint.
- A durable checkpoint backend (SQLite) configured to write the full trajectory: node outputs, channel states, and streaming events after every super-step.
- The graph uses DTU mock providers. The DTU mock is configured to return deterministic responses for the specific fixture inputs.
- After the original run completes, the DTU mock is taken offline (connections refused). The replay must succeed without making new provider calls.

**Check 1 — Original run completes and trajectory is fully persisted**

**When** the graph is invoked with a fixture input and runs to completion:

**Then:**
1. The run terminates with status `complete`.
2. The checkpoint store contains an entry for every super-step (at least four entries for a four-node graph).
3. Each checkpoint entry contains the node output record for that step.
4. The full ordered sequence of node execution steps is recoverable from the checkpoint store (step 1 → step 2 → step 3 → step 4).
5. At least one streaming event per node is recorded in the event log, each carrying the run-level correlation identifier.

**Check 2 — Replay from checkpoint reproduces the same node sequence and outputs**

**When** a fresh process loads the completed run's checkpoint and initiates a replay (DTU mock offline):

**Then:**
1. The replay traverses the same node sequence as the original run: step 1 → step 2 → step 3 → step 4, in the same order.
2. The output value at each node in the replay is identical to the output value recorded in the checkpoint for that step. No new inference calls are made to any provider (DTU mock is offline; any attempt would produce a connection error).
3. The replay terminates cleanly with status `complete`. It does not loop, hang, or attempt to advance past the terminal condition.
4. The replay produces a reconstructed event log. The events carry the original run's run-level correlation identifier (or a new replay-run identifier with a reference to the original run identifier in the ancestry chain).

**Check 3 — Replay is deterministic across two replay invocations**

**When** the replay is invoked twice against the same completed checkpoint (DTU mock offline for both):

**Then:**
1. Both replay invocations traverse the identical node sequence.
2. Both replay invocations produce identical output values at each step.
3. Both replays terminate with status `complete` after the same number of steps.
4. The reconstructed event logs from both replays have the same structure and content (same sequence of event types in the same order).

**Check 4 — Replay terminates; does not re-trigger the loop condition**

**When** the replayed run is a graph with a conditional loop (as in HS-D-001 style):

**Then:**
1. The replay reads the final generation index from the checkpoint. Because the terminal condition is already met (`generation_index == N`), the replay exits the loop immediately.
2. The replay does NOT start a new generation (it does not re-execute the loop body).
3. The replay run terminates in one traversal pass without looping.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.04.001 | Per-task checkpoint write completes before next super-step; full trajectory persisted | Check 1: four checkpoint entries written, one per node |
| BC-2.04.005 | Completed super-steps not re-executed after process restart | Check 2: replay reads node outputs from checkpoint; does not re-invoke provider |
| BC-2.04.003 | Monotonic logical-clock checkpoint IDs; ordered sequence recoverable | Check 1: ordered step sequence recoverable from checkpoint store |
| BC-2.03.001 | BSP super-step execution determinism: identical inputs → identical outputs | Check 3: two replay invocations on same checkpoint produce identical results |
| BC-2.06.001 | Typed streaming events per super-step; run_id correlation | Check 1: streaming events with run_id recorded per node; Check 2: replay produces event log |
| BC-2.06.002 | run_id + parent_ids correlation across all streaming events | Check 2: replay events carry original run correlation identifier or correct ancestry chain |

---

## Verification Approach

1. Build a four-node sequential graph. Each node reads its input, appends a typed output record, and increments a step counter. Configure a DTU mock to return a deterministic response at each step.
2. Configure a SQLite checkpoint backend with full trajectory persistence.
3. Invoke the original run. Assert it completes with status `complete`. Assert four checkpoint entries exist (one per node). Assert the ordered sequence is step 1 → 2 → 3 → 4. Assert streaming events were emitted per step with a stable run_id.
4. Take the DTU mock offline (configure it to refuse connections).
5. In a fresh process, load the checkpoint for the completed run. Invoke the replay operation. Assert the replay traverses steps 1 → 2 → 3 → 4. Assert no new provider calls are attempted (mock is offline; any call would cause a connection error that would fail the test). Assert each step's output matches the original checkpoint entry.
6. Assert the replay terminates with status `complete` after step 4. Assert it does not loop back to step 1.
7. Invoke the replay a second time. Assert both replay invocations produce identical output records and identical event log sequences (Check 3 determinism).
8. Extend the graph to a loop variant (conditional edge: continue if `generation_index < N`). Run the original loop to completion. Then replay. Assert the replay exits the loop on the first pass (does not re-enter the loop body).
9. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Check 1: full trajectory persisted; ordered sequence recoverable | 0.25 | Four checkpoint entries; ordered step sequence; streaming events with run_id |
| Check 2: replay reads from checkpoint; no new provider calls; correct output values | 0.30 | Replay produces same outputs as original; DTU mock offline causes no failures |
| Check 3: deterministic replay across two invocations | 0.25 | Both replays produce identical output records and event log sequences |
| Check 4: replay terminates immediately on met terminal condition | 0.20 | Loop-variant replay exits without re-entering loop; terminates in one pass |

**Should-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

### EC-001: Replay of a run that was interrupted mid-step (incomplete checkpoint)
**Expected behavior:** The replay loads the last fully committed checkpoint entry. It does not attempt to reconstruct the incomplete step from partial data. It starts the replay from the last complete step boundary. If the incomplete step's output is needed by a downstream step, the replay surfaces a structured error rather than proceeding with missing data.

### EC-002: Checkpoint store is read-only during replay
**Expected behavior:** The replay succeeds in read-only mode (no new writes to the checkpoint store are required to replay a completed run). If the replay framework needs to write intermediate replay state, it uses a separate replay-scoped namespace that does not mutate the original trajectory.

### EC-003: Replay with a graph that has been modified after the original run
**Expected behavior:** If the graph definition no longer matches the checkpoint schema (a node was renamed or removed), the replay surfaces a structured incompatibility error rather than proceeding with a mismatched graph. It does not silently skip nodes or corrupt the replay output.

### EC-004: Very large trajectory (100+ steps)
**Expected behavior:** The replay handles large trajectories without memory exhaustion or timeout. It processes steps sequentially from the checkpoint store. Performance may degrade gracefully; a structured error is acceptable if an explicit limit is exceeded, but a silent hang or out-of-memory crash is not.

### EC-005: Two concurrent replays of the same completed run
**Expected behavior:** Both replays complete independently. The checkpoint store is not corrupted by concurrent reads. Both replays produce identical output (determinism holds under concurrent access).

---

## Failure Guidance

"HOLDOUT LOW: HS-D-007 (satisfaction: X.XX) — the durable audit-grade trajectory replay did not correctly persist the full trajectory, reproduce the original output sequence, or terminate cleanly. Likely failure modes:

- Trajectory persistence fail: one or more checkpoint entries were missing after the original run; the ordered step sequence was not recoverable or had gaps.
- Replay non-compliance fail: the replay made new provider calls despite the DTU mock being offline, indicating the framework did not read from the checkpoint for completed steps; or replay output values differed from the original checkpoint entries.
- Non-determinism fail: two replay invocations on the same checkpoint produced different output records or different event log sequences.
- Loop re-entry fail: the loop-variant replay re-entered the loop body after loading a checkpoint where the terminal condition was already met; the replay did not terminate after one pass.
- Streaming fail: streaming events from the replay did not carry the original run's correlation identifier (or a correct ancestry reference), making the audit trail discontinuous."

---

## Information Asymmetry Confirmation

**Evaluator-facing sections confirmed FREE of internal traceability identifiers (BC IDs, VP IDs, error code identifiers, and internal module-path identifiers):**
- §Scenario (Check 1 through Check 4)
- §Verification Approach
- §Evaluation Rubric (table rows and should-pass threshold)
- §Failure Guidance
- §Edge Conditions

**Exempted non-evaluator metadata sections (legitimately retain traceability IDs):**
- §Behavioral Contract Linkage (BC-ID traceability table — orchestrator metadata only)

---

## Category: real-world-corpus

Not applicable — this scenario's category is `edge-case-combinations` (see the frontmatter `category:` field). No real-world corpus is required for this `edge-case-combinations` test.
