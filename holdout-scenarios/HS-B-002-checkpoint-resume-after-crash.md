---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-19T00:00:00Z
phase: 2
domain: B
domain_name: Dark Factory / Autonomous Software Pipeline
id: HS-B-002
title: "Checkpoint Resume After Simulated Crash Mid-Wave"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.04.001
  - BC-2.04.005
  - BC-2.03.003
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "5e990da"
traces_to: .factory/planning/holdout-domains/domain-b-dark-factory.md
lifecycle_status: active
introduced: v1.0.0-phase-2
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - checkpoint_resume
  - graph_execution
---

# Holdout Scenario HS-B-002: Checkpoint Resume After Simulated Crash Mid-Wave

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A wave of five parallel work-units is launched. After three complete, the process is forcibly terminated. A new process resumes. The resumed run must not re-execute the three already-completed units and must complete the remaining two, producing a correct final aggregate output.

**Given** a graph that fans out over five work-units (`WU-1` through `WU-5`). Each work-unit produces a structured result `{ unit_id, status: "done", artifact: "<string>" }`. A persistent checkpoint store (SQLite) is configured. Work-units `WU-1`, `WU-2`, `WU-3` complete successfully and their checkpoints are flushed to disk. The process terminates before `WU-4` and `WU-5` complete.

**When** a new process is started and the pipeline is resumed for the same run ID.

**Then:**
1. The resumed run detects that `WU-1`, `WU-2`, and `WU-3` are already complete and does NOT re-execute them.
2. `WU-4` and `WU-5` are executed and complete successfully.
3. The final aggregate output contains exactly five work-unit results — one for each of `WU-1` through `WU-5`.
4. The final output is identical in structure to the output that would have been produced by an uninterrupted run.
5. No work-unit is executed more than once across the two process runs combined.
6. The resumed run exits cleanly.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.04.001 | Checkpoint persisted after each super-step; resumable | WU-1/2/3 state survives process termination |
| BC-2.04.005 | Resume starts at the correct pending super-step; no double-execution | WU-4 and WU-5 are the only units executed in the resumed run |
| BC-2.03.003 | Fan-out results aggregated correctly at join | Final output has all five unit results |

---

## Verification Approach

1. Build a fan-out graph over five work-unit nodes using pregolya's Send API or equivalent parallel dispatch.
2. Instrument each work-unit node with a side-effect counter (e.g., an atomic counter or a mock log) to detect re-execution.
3. Run the graph. After WU-3 completes (observe its checkpoint entry), terminate the process.
4. Start a new process, load the checkpoint for the same run ID, and resume.
5. Assert the execution counters for WU-1, WU-2, WU-3 each read exactly 1 (executed once total across both process runs).
6. Assert the execution counters for WU-4 and WU-5 each read exactly 1 (executed in resumed run).
7. Assert the final aggregate output contains five `unit_id` values: WU-1 through WU-5.
8. Assert the status for all five units is "done".
9. Clean exit.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| No re-execution of completed units | 0.40 | WU-1, WU-2, WU-3 each executed exactly once total |
| Correct resume point | 0.25 | Resumed run starts at WU-4 and WU-5 (pending units only) |
| Complete aggregate output | 0.20 | Final output has all five unit results |
| Output equivalence | 0.15 | Output structure matches what an uninterrupted run would produce |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- Process terminates after zero work-units complete (crash immediately after fan-out dispatch): all five must execute in the resumed run.
- Checkpoint store corrupted for WU-2 only: the resumed run must either re-execute from WU-2 or fail with a structured error — never silently skip WU-2.
- All five work-units complete before process termination: resumed run sees all five as done and produces the aggregate output without executing anything.

---

## Failure Guidance

"HOLDOUT LOW: HS-B-002 (satisfaction: X.XX) — resumed run re-executed already-completed work-units, or failed to produce the complete aggregate output."

---

## Category: real-world-corpus

Not applicable — this scenario uses synthetic work-unit fixtures. Category is `integration-boundaries`.
