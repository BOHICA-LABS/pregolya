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
id: HS-A-004
title: "Risk-Tiered Human Approval Gate Before Containment Action"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.05.001
  - BC-2.05.002
  - BC-2.11.001
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
input-hash: "7442088"
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
  - hitl
  - checkpoint_resume
  - graph_execution
---

# Holdout Scenario HS-A-004: Risk-Tiered Human Approval Gate Before Containment Action

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

An investigation concludes that a workstation should be isolated from the network to prevent ransomware spread. This is a high-risk containment action that must NEVER execute without explicit human approval. The run must durably park, survive a process termination, and resume only after an external approval signal arrives.

**Given** an investigation graph that has completed its analysis phase and determined that host isolation is warranted for `workstation-47`. The graph is configured to require human approval for any action classified as high-risk. A checkpoint backend (SQLite) is available. A DTU mock "containment service" is available.

**When** the graph reaches the containment action node.

**Then:**
1. The graph pauses execution and emits an approval-request signal identifying the pending action (isolate `workstation-47`, risk level: high).
2. The approval-request signal is persisted in the checkpoint store — the run is durably parked.
3. The process terminates (simulated).
4. A new process is launched. It detects the pending approval request for `workstation-47`.
5. The evaluator sends an approval signal for the pending action.
6. The graph resumes and dispatches the containment action to the DTU mock containment service.
7. The containment service call is recorded as having occurred AFTER the approval was received.
8. If instead a DENIAL signal is sent in step 5, the containment action must NOT be dispatched to the containment service, and the run records the denial in its output.
9. At no point does the containment service get called before the approval signal is received.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.05.001 | Graph execution pauses at interrupt point; durably persisted | Run parks at containment gate |
| BC-2.05.002 | Resume value delivered to the correct node on resume | Approval/denial signal resumes the correct pending action |
| BC-2.11.001 | Checkpoint written at interrupt; resumable from a fresh process | Durable park survives process termination |

---

## Verification Approach

1. Construct a graph with an investigation phase followed by a "containment decision" node that emits a HITL approval request when risk level is high.
2. Run the graph with the `workstation-47` incident until it parks at the approval gate. Observe the approval-request in the checkpoint store or returned interrupt value.
3. Terminate the process.
4. Restart, reload the checkpoint, and issue an APPROVE signal.
5. Assert the DTU containment service mock received a request for `workstation-47` AFTER the approval signal was issued. Verify the timestamp ordering (approval event timestamp < containment call timestamp).
6. Run a second variant: restart, issue a DENY signal. Assert the DTU containment service mock received NO request for `workstation-47`.
7. Both variants must exit cleanly.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Approval gate enforced | 0.40 | Containment action not dispatched before approval signal received |
| Durable park across process boundary | 0.25 | Approval-request survives process termination and is retrievable in fresh process |
| Denial path correctness | 0.20 | Denial signal prevents containment dispatch entirely |
| Audit ordering | 0.15 | Evidence of approval event preceding containment call in the run record |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- Approval signal arrives in the same process run (no restart): graph must still pause and wait for the signal before proceeding.
- Multiple pending approval requests queued for the same run: each must be approved or denied individually.
- Approval signal received for a run that has already completed: must be handled without panic (idempotent or explicit error).

---

## Failure Guidance

"HOLDOUT LOW: HS-A-004 (satisfaction: X.XX) — containment action was dispatched without human approval, or the run failed to resume correctly after receiving the approval signal."

---

## Category: real-world-corpus

Not applicable — this scenario uses synthetic incident fixtures and a DTU containment service mock. Category is `integration-boundaries`.
