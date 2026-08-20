---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-19T00:00:00Z
phase: 2
domain: A
domain_name: Virtual SOC Analyst Agent
id: HS-A-003
title: "Durable Multi-Stage Investigation Surviving Process Restart"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.04.001
  - BC-2.04.005
  - BC-2.04.002
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
input-hash: "b45cace"
traces_to: .factory/planning/holdout-domains/domain-a-soc-analyst.md
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
  - providers
---

# Holdout Scenario HS-A-003: Durable Multi-Stage Investigation Surviving Process Restart

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A security investigation spans four sequential stages: (1) initial triage, (2) deep enrichment, (3) timeline reconstruction, and (4) verdict generation. The investigation is long enough that a process restart can realistically occur between stages.

**Given** a multi-stage investigation graph configured with a durable checkpoint backend (SQLite or in-memory store), and an alert representing a suspected multi-stage intrusion: `{ incident_id: "INC-2026-0847", initial_alert_type: "Lateral movement detected", affected_hosts: ["web-01", "db-02", "auth-03"] }`.

**When** the investigation is started and completes Stage 1 (initial triage) and Stage 2 (deep enrichment). At this point the process is forcibly terminated (simulated crash). A new process is launched, retrieves the checkpoint for `INC-2026-0847`, and resumes the investigation.

**Then:**
1. Stage 3 (timeline reconstruction) begins from exactly where Stage 2 left off — Stage 1 and Stage 2 are NOT re-executed.
2. The resumed investigation has access to the results produced by Stage 1 and Stage 2 (they are present in the restored state).
3. Stages 3 and 4 complete, producing a final verdict for `INC-2026-0847`.
4. The final verdict is identical to (or semantically equivalent to) the verdict that would have been produced by an uninterrupted run.
5. No stage is executed more than once.
6. The restored run exits cleanly with the completed verdict.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.04.001 | Checkpoint written after each super-step; resumable from stored state | Stage 1+2 results persisted; resume starts at Stage 3 |
| BC-2.04.005 | Graph execution resumes at correct node after checkpoint restore | Stage 3 is the next node, not Stage 1 or Stage 2 |
| BC-2.04.002 | Graph state survives process boundary | Resumed process has full prior-stage context |

---

## Verification Approach

1. Construct a four-stage investigation graph using pregolya's graph builder API. Stages produce structured output that feeds into the next stage.
2. Configure a persistent checkpoint store (SQLite backend or equivalent) keyed by `INC-2026-0847`.
3. Run the graph until Stage 2 completes. Observe that two checkpoints have been written (after Stage 1 and after Stage 2).
4. Terminate the running process (or simulate process exit; in a test context this can be a thread stop and state-reload).
5. Instantiate a new graph runner using the same checkpoint store. Resume for `INC-2026-0847`.
6. Assert Stage 1 and Stage 2 are not re-executed (instrument with a counter or observe the DTU mock request log).
7. Assert the resumed run reaches Stage 3 and Stage 4 and produces a final verdict record.
8. Assert the final verdict contains the `incident_id` and a non-empty `disposition` field.
9. Clean exit, no panic.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Correct resume point | 0.35 | Resumed run starts at Stage 3, not Stage 1 or 2 |
| No stage re-execution | 0.25 | Stage 1 and Stage 2 not invoked again; DTU mock logs confirm |
| Prior-stage state available | 0.20 | Resumed run has access to Stage 1 and Stage 2 outputs |
| Completion and output correctness | 0.20 | Final verdict produced with correct shape and non-empty content |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- Process restarted immediately after Stage 1 (before Stage 2 checkpoint is written): resume must start at Stage 2, not Stage 3.
- Checkpoint store is empty (first run, no prior state): graph runs from Stage 1 normally.
- Checkpoint store has a partial write (simulated disk-fault mid-checkpoint): graph must either resume from the last complete checkpoint or fail with a structured error — never produce corrupt output.

---

## Failure Guidance

"HOLDOUT LOW: HS-A-003 (satisfaction: X.XX) — investigation did not resume at the correct stage after process restart, or repeated already-completed stages."

---

## Category: real-world-corpus

Not applicable — this scenario uses a synthetic incident fixture, not a real-world corpus. No real-world corpus is required for this integration-boundaries test.
