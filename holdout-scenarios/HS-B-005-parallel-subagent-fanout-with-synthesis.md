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
id: HS-B-005
title: "Parallel Sub-Agent Fan-Out with Context Isolation and Result Synthesis"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.002
  - BC-2.02.006
  - BC-2.08.003
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
  - graph_execution
  - composition
  - providers
changelog:
  - "1.0 (initial, 2026-08-18): base scenario authored."
  - "1.1 (F-P2A003-02, P2A-003-fix-burst, 2026-08-19): BC-linkage re-anchoring sweep — 3 BCs re-anchored in frontmatter behavioral_contracts and BC-linkage table to semantically-correct IDs verified against BC-INDEX."
---

# Holdout Scenario HS-B-005: Parallel Sub-Agent Fan-Out with Context Isolation and Result Synthesis

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

Three specialist sub-agents are spawned in parallel. Each receives a disjoint work-unit context. Each produces a structured finding report. A join node synthesizes the three reports into a unified summary. Context from one sub-agent must NOT appear in another sub-agent's execution context.

**Given** a pipeline that dispatches three parallel sub-agents:
- Sub-Agent 1 (Documentation Reviewer): receives `{ work_unit: "docs", artifact: "README content A" }`. Should return a finding report about documentation quality.
- Sub-Agent 2 (Security Reviewer): receives `{ work_unit: "security", artifact: "Code snippet B" }`. Should return a finding report about security posture.
- Sub-Agent 3 (Performance Reviewer): receives `{ work_unit: "performance", artifact: "Benchmark data C" }`. Should return a finding report about performance characteristics.

A DTU mock chat provider returns a plausible finding report for each specialist's artifact when invoked. Each sub-agent uses the same DTU mock provider but with different prompt context.

**When** the pipeline is invoked.

**Then:**
1. All three sub-agents execute concurrently.
2. Sub-Agent 1's response references `artifact: "README content A"` — NOT "Code snippet B" or "Benchmark data C". Its context does not contain the other artifacts.
3. Sub-Agent 2's response references `artifact: "Code snippet B"` — NOT the documentation or benchmark artifacts.
4. Sub-Agent 3's response references `artifact: "Benchmark data C"` — NOT the documentation or code artifacts.
5. The join node receives three distinct finding reports, one per work_unit.
6. The synthesized summary contains a reference to all three work_units: `docs`, `security`, `performance`.
7. The pipeline completes without crash.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.006 | Fan-out dispatches sub-agents in parallel with isolated state | Three sub-agents run concurrently; each gets disjoint state |
| BC-2.02.002 | Fan-in join collects all sub-agent results | Three reports aggregated at join node |
| BC-2.08.003 | Each sub-agent chat model call produces typed structured output | Finding reports are typed records, not raw strings |

---

## Verification Approach

1. Build a StateGraph with a fan-out node that dispatches three sub-agent invocations using pregolya's parallel dispatch (Send API or equivalent). Each sub-agent receives only its own `work_unit` context.
2. Configure the DTU mock provider to return a finding report that echoes back the artifact content it received (so the evaluator can verify context isolation).
3. Run the pipeline.
4. Inspect Sub-Agent 1's finding report: assert it mentions "README content A" and does NOT mention "Code snippet B" or "Benchmark data C".
5. Inspect Sub-Agent 2's finding report: assert it mentions "Code snippet B" and does NOT mention the other artifacts.
6. Inspect Sub-Agent 3's finding report: assert it mentions "Benchmark data C" and does NOT mention the other artifacts.
7. Inspect the synthesized summary: assert it references all three work_units.
8. Clean exit.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Context isolation | 0.40 | Each sub-agent's DTU invocation contains only its own artifact |
| Concurrent execution | 0.20 | Sub-agents run in parallel, not sequentially |
| Fan-in synthesis | 0.25 | Synthesized summary references all three work_unit types |
| Stability | 0.15 | Clean exit; no panic when aggregating three concurrent results |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- One sub-agent's DTU call returns an error: the other two sub-agents must still complete; the join node receives two results and one error indicator.
- Two sub-agents produce conflicting findings (e.g., both flag the same issue): the synthesis node must not crash — it should aggregate both findings.
- Sub-agent count is 1 (degenerate fan-out): single-sub-agent execution must still work without the fan-out machinery panicking.

---

## Failure Guidance

"HOLDOUT LOW: HS-B-005 (satisfaction: X.XX) — sub-agent context isolation failed (artifacts from one sub-agent appeared in another), or fan-in synthesis did not aggregate all three results."

---

## Category: real-world-corpus

Not applicable — this scenario uses synthetic work-unit artifacts. Category is `integration-boundaries`.
