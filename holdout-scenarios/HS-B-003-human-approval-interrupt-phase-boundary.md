---
document_type: holdout-scenario
level: ops
version: "1.1"
status: active
producer: product-owner
timestamp: 2026-08-19T00:00:00Z
phase: 2
domain: B
domain_name: Dark Factory / Autonomous Software Pipeline
id: HS-B-003
title: "Human Approval Interrupt at Phase Boundary — Cross-Process Resume"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.05.001
  - BC-2.05.002
  - BC-2.05.004
  - BC-2.04.005
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "0d02bf4"
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
  - hitl
  - checkpoint_resume
  - graph_execution
  - server
changelog:
  - "1.0 (initial, 2026-08-18): base scenario authored."
  - "1.1 (F-P2A003-02, P2A-003-fix-burst, 2026-08-19): BC-linkage re-anchoring sweep — 1 BC re-anchored in frontmatter behavioral_contracts and BC-linkage table to semantically-correct IDs verified against BC-INDEX."
---

# Holdout Scenario HS-B-003: Human Approval Interrupt at Phase Boundary — Cross-Process Resume

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A multi-phase pipeline pauses at a "phase gate" awaiting human sign-off before advancing from the planning phase to the implementation phase. The process terminates. Human approval arrives externally. A new process resumes the pipeline past the gate.

**Given** a two-phase pipeline: (1) Planning Phase produces a structured plan document; (2) Implementation Phase requires human approval before it starts. The pipeline is configured with an interrupt point between the two phases. A durable checkpoint backend (SQLite) is configured. Run ID: `PIPELINE-RUN-42`.

**When** the pipeline executes the Planning Phase, reaches the phase boundary, and emits an approval request. The process is then terminated.

**Then:**
1. The pipeline pauses at the phase boundary and emits a structured approval request containing at minimum: `run_id: "PIPELINE-RUN-42"`, `pending_action: "advance to implementation"`, and a summary of the plan produced in Phase 1.
2. The approval request is durably persisted in the checkpoint store and retrievable in a fresh process.
3. A new process loads the checkpoint, discovers the pending approval request, and waits for a resume signal.
4. The evaluator delivers an APPROVE signal with the resume value `{ approved: true, reviewer: "evaluator" }`.
5. The pipeline resumes at exactly the phase boundary and advances into the Implementation Phase.
6. The Implementation Phase has access to the plan produced in Phase 1.
7. The pipeline runs to completion and produces a final `completed` status record.
8. A DENY variant: if the evaluator delivers DENY instead of APPROVE, the pipeline records the denial and exits with a `denied` status — it does NOT advance to the Implementation Phase.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.05.001 | Graph pauses at interrupt; emits structured interrupt value | Pipeline parks at phase boundary with approval request |
| BC-2.05.002 | Resume value delivered to the correct pending node | Approval/denial signal routes to the phase gate node |
| BC-2.05.004 | Phase 1 state (plan) available to Phase 2 after resume | Implementation Phase reads Planning Phase output from restored state |
| BC-2.04.005 | Interrupt state persisted; resumable from fresh process | Approval request survives process termination |

---

## Verification Approach

1. Build a two-phase pipeline graph with an interrupt node at the phase boundary.
2. Run Planning Phase until the interrupt fires. Capture the approval request value.
3. Terminate the process (simulate crash or explicit exit).
4. Start a new process, load the checkpoint for PIPELINE-RUN-42. Verify the pending approval request is present.
5. Send an APPROVE signal with the resume value specified in the scenario.
6. Assert the pipeline advances to the Implementation Phase.
7. Assert the Implementation Phase has access to the Phase 1 plan (present in state).
8. Assert the final output has `status: "completed"` and `run_id: "PIPELINE-RUN-42"`.
9. Run a second variant: send DENY instead. Assert the final output has `status: "denied"` and the Implementation Phase is not executed.
10. Both variants exit cleanly.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Durable park across process boundary | 0.30 | Approval request retrievable in fresh process after restart |
| Correct resume on approval | 0.25 | Pipeline advances to Implementation Phase after APPROVE signal |
| Phase 1 state preserved | 0.20 | Implementation Phase can access the plan from Planning Phase |
| Denial path | 0.15 | DENY signal prevents Implementation Phase; status recorded as "denied" |
| Completion | 0.10 | Clean exit for both APPROVE and DENY variants |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- Approval signal arrives with a malformed resume value (missing fields): pipeline must return a structured error, not crash.
- Approval signal arrives for a run ID that does not exist in the checkpoint store: must return a structured error, not panic.
- Two pending approval requests for the same run (if the graph has two gates): each must be independently approved or denied.

---

## Failure Guidance

"HOLDOUT LOW: HS-B-003 (satisfaction: X.XX) — pipeline did not correctly resume after human approval across a process boundary, or advanced to Implementation Phase without receiving an approval signal."

---

## Category: real-world-corpus

Not applicable — this scenario uses a synthetic pipeline fixture. Category is `integration-boundaries`.
