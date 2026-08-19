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
id: HS-B-006
title: "Budget-Bounded Run — Graceful Ceiling Handling with No Silent Overrun"
category: edge-case-combinations
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.10.001
  - BC-2.10.002
  - BC-2.10.003
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
  - checkpoint_resume
---

# Holdout Scenario HS-B-006: Budget-Bounded Run — Graceful Ceiling Handling with No Silent Overrun

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A pipeline run is configured with a token budget ceiling. When cumulative token usage reaches the ceiling, the run must halt or degrade gracefully — NOT silently continue over budget. The output must clearly signal that budget exhaustion occurred.

**Given** a five-stage pipeline (Parse → Plan → Implement → Review → Output). Each stage consumes a known token amount via the DTU mock provider (configured to report usage in its response). The pipeline run is given a budget of 400 tokens. The first two stages (Parse and Plan) consume 100 tokens each (200 total); Stage 3 (Implement) would consume 300 tokens (pushing total to 500, over the 400-token ceiling).

**When** the pipeline is invoked with the 400-token budget.

**Then:**
1. Stages 1 (Parse) and 2 (Plan) complete successfully, consuming 200 tokens total.
2. Before Stage 3 begins, the budget governance layer evaluates whether the ceiling would be exceeded.
3. The run halts (or degrades) at the Stage 3 boundary — Stage 3 does NOT execute.
4. The run does NOT silently consume 500 tokens and then complete.
5. The final output contains a structured record indicating: `status: "budget_exhausted"`, `tokens_consumed: 200`, `tokens_limit: 400`, and a reference to which stage triggered the halt.
6. The run exits cleanly (no panic).

**Graceful-degradation variant:** If the pipeline is configured with a `on_ceiling: summarize` policy instead of `on_ceiling: halt`, Stage 3 is replaced with a summary step that produces a compact output without exceeding the remaining budget. The final output has `status: "completed_degraded"`.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.10.001 | Budget governance evaluates ceiling before each stage | Ceiling check fires before Stage 3 |
| BC-2.10.002 | On-ceiling halt policy: run halts and emits budget-exhausted status | halt variant produces `status: "budget_exhausted"` |
| BC-2.10.003 | On-ceiling summarize policy: degraded-mode stage executes within remaining budget | summarize variant produces `status: "completed_degraded"` |

---

## Verification Approach

1. Build a five-stage pipeline configured with a budget of 400 tokens and `on_ceiling: halt` policy.
2. Configure DTU mock to report `usage: { total_tokens: 100 }` for Stage 1 and Stage 2 responses, and `usage: { total_tokens: 300 }` for what Stage 3 would consume.
3. Run the pipeline. Assert Stage 3 is NOT invoked (verify DTU mock received no Stage 3 request).
4. Assert the final output record has `status: "budget_exhausted"` and `tokens_consumed: 200`.
5. Repeat with `on_ceiling: summarize` policy. Assert Stage 3 is replaced by a summary operation. Assert final output has `status: "completed_degraded"`.
6. Both variants exit cleanly.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| No silent overrun | 0.40 | Stage 3 not executed when it would exceed the 400-token ceiling (halt variant) |
| Correct halt status | 0.25 | Output contains `status: "budget_exhausted"` with accurate token counts (halt variant) |
| Graceful degradation (summarize variant) | 0.20 | Degraded output produced within remaining budget; status is `completed_degraded` |
| Stability | 0.15 | Clean exit for both variants; no panic on ceiling hit |

**Threshold for should-pass:** weighted average ≥ 0.55.

---

## Edge Conditions

- Budget ceiling set to zero: Stage 1 must immediately halt with `budget_exhausted` status before executing.
- Budget ceiling set very high (effectively unlimited): all five stages execute normally; `status: "completed"` (no budget exhaustion path triggered).
- Budget ceiling hit exactly on the last token of a stage (boundary): the next stage halts, the completed stage is preserved.

---

## Failure Guidance

"HOLDOUT LOW: HS-B-006 (satisfaction: X.XX) — pipeline silently exceeded the token budget without halting, or did not emit a structured budget-exhausted status when the ceiling was reached."

---

## Category: real-world-corpus

Not applicable — this scenario uses synthetic pipeline stages with controlled token usage. Category is `edge-case-combinations`.
