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
id: HS-D-006
title: "Budget and Guardrail Gating — Structured Refusal and Ceiling Enforcement"
category: edge-case-combinations
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.10.001
  - BC-2.10.002
  - BC-2.10.003
  - BC-2.10.004
  - BC-2.04.001
  - BC-2.05.007
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
  - "1.0 (initial/2026-08-31): Domain D HS-D-006 authored for autonomous research orchestrator use case."
---

# Holdout Scenario HS-D-006: Budget and Guardrail Gating — Structured Refusal and Ceiling Enforcement

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A research orchestrator run is governed by a budget policy and a per-tool action guardrail. The budget policy enforces a maximum resource consumption ceiling. The guardrail policy classifies certain actions as disallowed. When either limit is exceeded or a disallowed action is attempted, the run is refused further execution — producing a structured, credential-safe refusal record rather than panicking, silently halting, or continuing past the limit.

**Given:**
- A graph configured with: (a) a budget policy specifying a low ceiling (e.g., 5 token units); (b) an action guardrail that disallows one specific tool category (`write-classified`); (c) a checkpoint backend so partial results are preserved.
- A test fixture that drives the graph to intentionally exceed the budget ceiling and to intentionally attempt a disallowed action.
- The budget policy is configured for two variants: `halt-on-ceiling` (run stops when ceiling reached) and `escalate-on-ceiling` (run pauses and requests human input when ceiling reached).
- DTU mock providers are used. No real API keys are present. The DTU mock's configured response bodies do not contain any credential material.

**Scenario A — budget ceiling halt:**

The graph runs nodes that each consume 2 budget units. The ceiling is 5 units. The third node would push consumption to 6 units.

**When** the graph runs under the `halt-on-ceiling` policy:

**Then:**
1. The first two nodes execute (consuming 4 units total). Before the third node begins, the budget policy fires.
2. The third node is NOT executed. Execution halts cleanly.
3. The run terminates with a structured halt status that includes the current consumption count and the ceiling value. The status is a typed record, not a raw error string.
4. The partial results from the first two nodes are accessible via the checkpoint — the run's intermediate state is preserved and retrievable.
5. The budget evaluation log records at least two entries (one per executed node) and the ceiling-triggered halt.

**Scenario B — disallowed action refused before external call:**

A node in the graph attempts to call a `write-classified` tool. The guardrail policy disallows this class of action.

**When** the node reaches the point of tool invocation:

**Then:**
1. The guardrail fires before the external call is dispatched. The `write-classified` tool is NOT invoked. No external side effect occurs.
2. The run surfaces a structured refusal record specifying that the action was refused. The record includes the action class that was refused and a human-readable reason.
3. The refusal record does not contain any API key material, internal module path, or credential value in any field.
4. The run may either halt at the refusal or route to an error-handling branch, depending on graph configuration. In both cases, the refusal record is accessible in the run's output.

**Scenario C — escalate-on-ceiling emits a human-approval request:**

The same ceiling configuration as Scenario A, but the policy is set to `escalate-on-ceiling`.

**When** the budget ceiling is reached:

**Then:**
1. Instead of halting, the run transitions to a pending-human-approval state.
2. The pending-approval state is durable: if the process restarts at this point, the new process loads the checkpoint and finds the run in pending-approval state.
3. The run does NOT proceed past the ceiling without explicit approval.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.10.001 | BudgetPolicy allow/escalate/deny evaluation per run | Budget policy fires before third node; third node denied |
| BC-2.10.002 | Append-only EvidenceJournal records every budget evaluation | Budget evaluation log records at least two entries + ceiling halt |
| BC-2.10.003 | Graceful halt when budget ceiling reached (on_ceiling = halt \| summarize); remaining-budget exposed | Scenario A: run halts with typed status including consumption count and ceiling |
| BC-2.10.004 | Budget escalation to HITL interrupt (escalate path) | Scenario C: run transitions to pending-human-approval at ceiling |
| BC-2.04.001 | Per-task checkpoint write; partial results preserved at halt | Partial results from first two nodes accessible after ceiling halt |
| BC-2.05.007 | PreToolCallHook dispatch — Approve/Deny; fail-closed deny | Scenario B: guardrail fires before external call; write-classified tool not invoked |

---

## Verification Approach

1. Build a graph with four sequential nodes. Each node logs a "consumed 2 units" event and calls the DTU mock once.
2. Configure a budget policy with ceiling = 5 units and policy = `halt-on-ceiling`.
3. Run Scenario A. After the first two nodes complete (4 units consumed), assert the third node is not called. Assert the run status is a typed halt record with `consumed = 4`, `ceiling = 5`.
4. Assert the checkpoint contains the outputs of the first two nodes. Load the checkpoint in a fresh process and verify the outputs are accessible.
5. Inspect the budget evaluation log. Assert at least two evaluation entries (one per executed node) and a ceiling-exceeded entry.
6. Reconfigure the graph to include a node that calls a `write-classified` tool. Configure the guardrail to deny `write-classified` actions. Run the graph. Assert the tool is never invoked (no call recorded on the DTU mock or external MCP server). Assert a structured refusal record is produced.
7. Assert the refusal record's fields contain no API key material (inspect all string fields for the DTU mock's configured API key value — it must not appear).
8. Configure the budget policy for Scenario C (ceiling = 5, policy = `escalate-on-ceiling`). Run the graph to the ceiling. Assert the run transitions to pending-human-approval, not a halt. Simulate process restart; assert the run is still in pending-human-approval after restart.
9. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Scenario A: ceiling halt blocks third node; partial results preserved | 0.30 | Third node not called; typed halt status with consumption/ceiling; checkpoint accessible |
| Scenario B: disallowed action refused before external call; credential-safe refusal | 0.30 | Write-classified tool not invoked; structured refusal record with no credential material |
| Scenario C: escalate path transitions to pending-human-approval durably | 0.25 | Run enters pending-approval state; state survives process restart |
| Budget log: evaluation entries recorded | 0.15 | At least two budget evaluation log entries + ceiling-exceeded entry in Scenario A |

**Should-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

### EC-001: Budget ceiling is exactly at a node boundary (consumption hits ceiling precisely)
**Expected behavior:** The node that causes consumption to equal the ceiling is the last node allowed to execute (not the next one). The policy fires at the boundary. No off-by-one behavior: a run consuming exactly 5 units against a ceiling of 5 is allowed to complete that last node.

### EC-002: Disallowed action attempted on the first node
**Expected behavior:** The guardrail fires on the very first node. The run never executes any node. The refusal record is produced immediately. No partial output exists in the checkpoint.

### EC-003: Budget ceiling of 0
**Expected behavior:** No node is allowed to execute. The run produces a typed halt status immediately (consumed = 0, ceiling = 0). The budget evaluation log records the initial ceiling check.

### EC-004: Escalate policy with no human present — run waits indefinitely
**Expected behavior:** The run enters pending-approval state and remains there. It does not auto-approve, auto-halt, or loop. The run's pending state is observable and the run can be resumed when approval is eventually delivered.

### EC-005: Multiple disallowed actions in the same node (two write-classified tool calls)
**Expected behavior:** The guardrail fires on the first disallowed tool call. The second call is not attempted. The refusal record covers the first blocked call only (or summarizes both if the full node is refused as a unit).

---

## Failure Guidance

"HOLDOUT LOW: HS-D-006 (satisfaction: X.XX) — the budget and guardrail gating did not correctly enforce ceiling limits or refuse disallowed actions. Likely failure modes:

- Ceiling enforcement fail: the third node executed even though the budget ceiling (5 units) was already reached after two nodes (4 units); the run continued silently past the ceiling.
- Partial-result loss fail: the checkpoint did not preserve the outputs from the first two nodes after the ceiling halt, making intermediate results inaccessible.
- Guardrail bypass fail: the write-classified tool was invoked despite the guardrail policy denying it; the external call was made before the refusal record was produced.
- Credential leak fail: the structured refusal record contained API key material, internal module paths, or other credential-adjacent data in any field.
- Escalation fail: the escalate-on-ceiling policy did not transition the run to pending-human-approval; it halted or continued instead; or the pending-approval state was lost after a process restart."

---

## Information Asymmetry Confirmation

**Evaluator-facing sections confirmed FREE of internal traceability identifiers (BC IDs, VP IDs, error code identifiers, and internal module-path identifiers):**
- §Scenario (Scenarios A, B, C)
- §Verification Approach
- §Evaluation Rubric (table rows and should-pass threshold)
- §Failure Guidance
- §Edge Conditions

**Exempted non-evaluator metadata sections (legitimately retain traceability IDs):**
- §Behavioral Contract Linkage (BC-ID traceability table — orchestrator metadata only)

---

## Category: real-world-corpus

Not applicable — this scenario's category is `edge-case-combinations` (see the frontmatter `category:` field). No real-world corpus is required for this `edge-case-combinations` test.
