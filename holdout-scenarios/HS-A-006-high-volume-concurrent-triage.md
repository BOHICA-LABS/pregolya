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
id: HS-A-006
title: "High-Volume Concurrent Alert Triage — Scheduler Fairness Under Load"
category: edge-case-combinations
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.006
  - BC-2.03.001
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
  - graph_execution
  - providers
  - streaming
---

# Holdout Scenario HS-A-006: High-Volume Concurrent Alert Triage — Scheduler Fairness Under Load

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

Twenty alerts arrive simultaneously and must be triaged in parallel. No alert should be starved or dropped. The scheduler must handle the burst without deadlock, livelock, or OOM.

**Given** twenty distinct alert records, each with a unique `alert_id` and a different severity level (a mix of low, medium, and high). A DTU mock provider is configured to respond to each request with a 30ms simulated delay. The pregolya runtime is configured with its default multi-thread scheduler.

**When** all twenty alerts are submitted to the triage system simultaneously (or near-simultaneously).

**Then:**
1. All twenty alerts are triaged and produce a structured verdict.
2. No alert is lost (exactly twenty distinct `alert_id` values appear in the output).
3. All twenty complete within a wall-clock time that is less than 5× the single-alert round-trip time (i.e., parallelism is observable — not 20× sequential).
4. No high-severity alert waits indefinitely behind a queue of low-severity alerts (fairness property — high-severity alerts must not be systematically last to complete).
5. No panic, no deadlock, no OOM; the process exits cleanly.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.006 | Fan-out over a dynamic collection executes concurrently | Twenty triage runs dispatched in parallel |
| BC-2.03.001 | Scheduler does not starve low-priority runs | All twenty alerts complete regardless of severity ordering |

---

## Verification Approach

1. Prepare twenty alert fixtures with unique IDs and mixed severity levels (7 low, 7 medium, 6 high).
2. Submit all twenty alerts as parallel graph runs to the pregolya runtime.
3. Collect all twenty verdict outputs.
4. Assert exactly twenty distinct `alert_id` values appear in the outputs.
5. Measure wall-clock elapsed time. Assert it is less than 5× the mock provider round-trip time (30ms × 5 = 150ms expected ceiling; add tolerance for test infrastructure overhead).
6. Assert no high-severity alert's completion timestamp is later than the maximum low-severity completion timestamp by more than 2× the mock round-trip time (fairness check).
7. Assert the process exits cleanly.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Completeness | 0.35 | All twenty alerts produce verdicts; no alert dropped |
| Parallelism observable | 0.30 | Wall-clock time < 5× single-alert time |
| Fairness | 0.20 | High-severity alerts not consistently last to complete |
| Stability | 0.15 | Clean exit; no panic, deadlock, or memory spike |

**Threshold for should-pass:** weighted average ≥ 0.55.

---

## Edge Conditions

- All twenty alerts have identical content (degenerate case): all twenty verdicts must still be individually produced.
- One alert's DTU mock call times out: the remaining nineteen must complete; the one timeout surfaces as a structured partial-failure.
- Runtime configured with a single thread (non-default): test must be documented to only run on the default multi-thread configuration.

---

## Failure Guidance

"HOLDOUT LOW: HS-A-006 (satisfaction: X.XX) — concurrent triage did not complete all alerts or showed sequential (non-parallel) execution patterns under the 20-alert burst."

---

## Category: real-world-corpus

Not applicable — this scenario's category is `edge-case-combinations` (see the frontmatter `category:` field). No real-world corpus is required for this `edge-case-combinations` test.
