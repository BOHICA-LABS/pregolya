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
id: HS-B-001
title: "Spec-Driven Pipeline Phase Traversal with Quality Gate"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.04.001
  - BC-2.04.003
  - BC-2.08.001
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
  - graph_execution
  - composition
  - structured_output
  - providers
---

# Holdout Scenario HS-B-001: Spec-Driven Pipeline Phase Traversal with Quality Gate

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A developer uses pregolya to build a minimal autonomous software pipeline. The pipeline accepts a specification, advances through phases automatically, routes based on a quality gate outcome, and produces structured phase output.

**Given** a four-phase pipeline graph: (1) Parse Spec, (2) Generate Plan, (3) Validate Plan, (4) Produce Output. The Validate Plan phase acts as a conditional gate: if the plan is valid, the pipeline advances to Produce Output; if invalid, it routes to a fix sub-path (a "generate revised plan" node) and retries validation. A DTU mock chat provider is configured to return a VALID plan response for the initial run.

Input specification: `{ spec_id: "SPEC-001", description: "A function that computes the Fibonacci sequence up to N", language: "rust", constraints: ["no recursion", "return Vec<u64>"] }`.

**When** the pipeline is invoked with SPEC-001.

**Then:**
1. All four phases execute in order: Parse → Plan → Validate → Output.
2. The Validate Plan phase receives the generated plan and evaluates it against the constraints.
3. Since the DTU mock returns a valid plan, the pipeline takes the "valid" branch and proceeds to Produce Output.
4. The final output is a structured record containing: the original `spec_id`, a `plan_summary` string, and a `status` of `completed`.
5. The pipeline completes without manual intervention — no human input is required between phases.
6. The total run produces a structured output record (not a raw string), and the run exits cleanly.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.04.001 | StateGraph executes nodes in specified order | Parse → Plan → Validate → Output sequential execution |
| BC-2.04.003 | Conditional edge routes based on node output | "valid" branch taken when Validate returns valid |
| BC-2.08.001 | Chat model produces typed structured output | Plan and output records are typed, not raw strings |

---

## Verification Approach

1. Build a StateGraph with four nodes (ParseSpec, GeneratePlan, ValidatePlan, ProduceOutput) and a conditional edge from ValidatePlan routing to either ProduceOutput (valid) or a ReviseAndRetry sub-node (invalid).
2. Configure the DTU mock provider to return a structurally valid plan for the first invocation.
3. Run the graph with SPEC-001 as input state.
4. Assert nodes executed in order: observe execution trace or node output presence.
5. Assert the ValidatePlan node did NOT route to ReviseAndRetry (DTU mock returned valid).
6. Assert final output record contains `spec_id: "SPEC-001"`, non-empty `plan_summary`, `status: "completed"`.
7. Clean exit.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Phase traversal order correct | 0.35 | All four phases execute; trace shows Parse → Plan → Validate → Output |
| Conditional routing correct | 0.30 | "valid" branch taken; ReviseAndRetry not executed on valid input |
| Structured output conformance | 0.25 | Output record contains required fields with correct types |
| Autonomous execution | 0.10 | No human input required between phases; pipeline self-advances |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- DTU mock returns an INVALID plan (alternate variant): the pipeline must route to ReviseAndRetry, not silently continue to Produce Output.
- DTU mock returns an empty response: ValidatePlan must treat this as INVALID and route to fix path, not crash.
- Pipeline configured with a maximum retry limit (e.g., 3): if Validate fails K times, the pipeline must halt with a structured error, not loop forever.

---

## Failure Guidance

"HOLDOUT LOW: HS-B-001 (satisfaction: X.XX) — pipeline did not traverse phases in the correct order, or conditional routing to quality gate branches did not work correctly."

---

## Category: real-world-corpus

Not applicable — this scenario uses a synthetic specification fixture. Category is `integration-boundaries`.
