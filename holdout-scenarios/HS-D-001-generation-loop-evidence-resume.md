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
id: HS-D-001
title: "Generation Loop Persistence and Evidence Resume"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.04.001
  - BC-2.04.005
  - BC-2.04.003
  - BC-2.02.005
  - BC-2.06.001
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
  - providers
changelog:
  - "1.0 (initial/2026-08-31): Domain D HS-D-001 authored for autonomous research orchestrator use case."
---

# Holdout Scenario HS-D-001: Generation Loop Persistence and Evidence Resume

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A multi-generation research orchestrator is built using the framework's cyclic graph and checkpoint primitives. The orchestrator executes a series of research generation steps, accumulating an evidence ledger as it advances from one generation to the next. A generation boundary is a discrete, durable checkpoint — after the boundary is committed, a process restart must resume exactly from that boundary without losing any accumulated evidence or re-executing completed work.

**Given:**
- A cyclic graph where each cycle represents one research generation.
- The graph carries a typed state value containing: `generation_index` (a monotonically increasing integer), `evidence_ledger` (an append-only list of findings from prior generations), and a `status` field (`running` or `complete`).
- A durable checkpoint backend is configured so that each generation boundary is committed before the next generation begins.
- A test fixture controls the total number of generations to run and injects a simulated process interruption between two specific generation boundaries.

**When** the orchestrator runs for N generations:
1. The orchestrator completes generation 1. The evidence ledger has exactly the entries from generation 1.
2. The checkpoint backend records a durable boundary after generation 1 completes.
3. A simulated process termination occurs before generation 2 begins.
4. A fresh process loads the checkpoint and resumes the orchestrator.

**Then:**
1. The resumed orchestrator correctly identifies `generation_index` as 1 (one generation already complete).
2. Generation 1 is NOT re-executed. The evidence ledger still contains exactly the entries from generation 1 — no duplicate entries, no missing entries.
3. The orchestrator continues and completes the remaining N − 1 generations. The final evidence ledger has exactly N entries (one per generation, no duplicates).
4. Generation IDs are monotonically increasing with no gaps: the sequence `[0, 1, 2, … N−1]` (or `[1, 2, … N]`) is preserved exactly across the resume boundary.
5. At least one streaming event is emitted per generation boundary, observable by a subscriber attached before the run begins. The events emitted during resumed execution carry a correlation identifier consistent with the original run.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.04.001 | Per-task write completes before next super-step begins; durable per-boundary | Generation boundary committed before next generation begins |
| BC-2.04.005 | Completed super-steps not re-executed after process restart | Generation 1 not re-run after resume |
| BC-2.04.003 | Monotonic logical-clock checkpoint IDs; wall-clock UUIDs rejected | Generation index sequence strictly monotonic; no gap or duplicate across resume |
| BC-2.02.005 | Conditional edge routing: loop-continue vs. loop-exit | Orchestrator continues if incomplete; exits when all N generations done |
| BC-2.06.001 | Typed streaming events emitted per phase; run_id correlation | Streaming events emitted per generation boundary; correlation consistent post-resume |

---

## Verification Approach

1. Build a cyclic graph with a "generation node" that appends one entry per generation to the evidence ledger and increments `generation_index`. Configure a conditional edge: if `generation_index < N` → loop; else → exit.
2. Configure a durable checkpoint backend (SQLite or in-memory with simulated persistence).
3. Start the run. After the first generation commits its boundary checkpoint, simulate process termination (drop the runtime handle; do not call graceful shutdown).
4. In a fresh process, load the persisted checkpoint. Verify that `generation_index` equals 1 (first generation complete) and the evidence ledger contains exactly one entry.
5. Resume the run in the fresh process. Assert that generation 1 is not re-run (the ledger entry from generation 1 is not duplicated).
6. Let the run complete all N generations. Assert the final ledger has exactly N entries, each entry unique, and `generation_index` equals N.
7. Assert `generation_index` advanced monotonically without gaps from 0 (or 1) through N.
8. Attach a streaming subscriber before the run and collect all events. Assert at least one event per generation boundary. After the resume, assert the post-resume events carry the same top-level run correlation identifier as pre-interruption events.
9. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Must-Pass? | Passing Signal |
|-----------|--------|------------|----------------|
| Durability: boundary committed before next generation | 0.30 | yes | Generation 1 boundary survives simulated process termination |
| Resume correctness: no re-execution of completed generation | 0.25 | yes | Evidence ledger has no duplicate entries after resume |
| Ledger integrity: N entries, monotonic generation IDs | 0.20 | yes | Final ledger length equals N; ID sequence strictly monotonic without gaps |
| Streaming continuity: correlation consistent post-resume | 0.15 | yes | Post-resume events carry same run-level correlation identifier |
| Terminal condition: run completes cleanly | 0.10 | yes | Run exits with status `complete` after N generations; no hang |

**Must-pass threshold (all five dimensions):** weighted average ≥ 0.70.

---

## Edge Conditions

### EC-001: Interruption exactly at the checkpoint write boundary
**Expected behavior:** If the process terminates after the write begins but before it commits, the resumed run detects an incomplete checkpoint and re-executes the interrupted generation (not a duplicate — the previous incomplete write is overwritten). The evidence ledger is not corrupted; total final entries remain exactly N.

### EC-002: N = 1 (single generation, no loop continuation)
**Expected behavior:** The orchestrator runs one generation, commits the boundary, and exits cleanly with status `complete`. No loop-back occurs. The evidence ledger has exactly one entry.

### EC-003: Evidence ledger accumulation with large payloads per entry
**Expected behavior:** The orchestrator handles large per-entry payloads without truncating or discarding evidence. Each entry in the final ledger is complete. If the storage backend enforces a size limit, a structured error is surfaced rather than a silent truncation.

### EC-004: Resuming from the final generation boundary (generation N already complete)
**Expected behavior:** The resumed run detects that the terminal condition is already satisfied. It exits cleanly with status `complete` without starting a new generation. No additional evidence entries are appended.

### EC-005: Resume with a stale checkpoint (checkpoint namespace mismatch)
**Expected behavior:** The framework surfaces a structured error when the loaded checkpoint does not match the graph schema or namespace. The run does not proceed silently with mismatched state.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-001 (satisfaction: X.XX) — the generation loop did not correctly persist and resume across a process boundary. Likely failure modes:

- Durability fail: the generation boundary was not committed before the process was terminated; the resumed run lost evidence from generation 1 or re-executed it from scratch.
- Duplicate-entry fail: the evidence ledger contains a duplicate entry for generation 1 after resume, indicating the generation was re-run.
- Ledger integrity fail: the final evidence ledger has fewer or more than N entries, or the generation ID sequence has a gap or a repeat.
- Streaming correlation fail: post-resume streaming events carry a different top-level run identifier than pre-interruption events, making the audit trail discontinuous.
- Terminal condition fail: after resume, the run did not exit cleanly when N generations were complete — it looped indefinitely or panicked."

---

## Information Asymmetry Confirmation

**Evaluator-facing sections confirmed FREE of internal traceability identifiers (BC IDs, VP IDs, error code identifiers, and internal module-path identifiers):**
- §Scenario
- §Verification Approach
- §Evaluation Rubric (table rows and must-pass threshold)
- §Failure Guidance
- §Edge Conditions

**Exempted non-evaluator metadata sections (legitimately retain traceability IDs):**
- §Behavioral Contract Linkage (BC-ID traceability table — orchestrator metadata only)

---

## Category: real-world-corpus

Not applicable — this scenario's category is `integration-boundaries` (see the frontmatter `category:` field). No real-world corpus is required for this `integration-boundaries` test.
