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
id: HS-D-004
title: "QD Diversity Allocation — Cohort Diversity Cap Enforcement"
category: edge-case-combinations
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.002
  - BC-2.03.001
  - BC-2.08.003
  - BC-2.02.006
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
  - structured_output
  - composition
changelog:
  - "1.0 (initial/2026-08-31): Domain D HS-D-004 authored for autonomous research orchestrator use case."
---

# Holdout Scenario HS-D-004: QD Diversity Allocation — Cohort Diversity Cap Enforcement

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A quality-diversity ("QD") allocator node distributes a set of candidate research plans into a cohort. The allocator enforces per-family caps to keep the cohort diverse: no single mechanism family (a categorical label attached to each candidate) may occupy more than its configured maximum slots in the output cohort. The allocator must be deterministic — the same input set with the same cap configuration always produces the same output cohort.

**Given:**
- A graph node that accepts: (a) a list of candidate plans, each with a `family` label and a `score` numeric value; (b) a configuration specifying a total cohort size and a maximum slots-per-family cap.
- A test fixture with N candidates spanning M distinct family labels. The fixture is arranged so that without the cap, one family would dominate the cohort.
- The allocated cohort is a typed structured record containing a list of selected candidates and a summary of per-family slot usage.

**Scenario A — cap enforcement with excess candidates in one family:**

N = 10 candidates; M = 2 families (`strategy-X`: 7 candidates, `strategy-Y`: 3 candidates); cohort size = 6; per-family cap = 3.

**When** the allocator runs on this fixture:

**Then:**
1. The output cohort contains exactly 6 candidates.
2. `strategy-X` occupies exactly 3 slots (not 6, which it would without the cap).
3. `strategy-Y` occupies exactly 3 slots (all available `strategy-Y` candidates are included).
4. All 6 selected candidates are distinct (no duplicates in the cohort).
5. Within each family, the candidates with the highest `score` values are selected (top-K per family).

**Scenario B — insufficient candidates (fewer candidates than cohort size):**

N = 4 candidates total (across all families); cohort size = 6; per-family cap = 3.

**When** the allocator runs on this fixture:

**Then:**
1. The output cohort contains all 4 available candidates (not 6 — it does not pad with nulls or repeat entries).
2. No error is raised. The run completes cleanly with a shorter-than-configured cohort.
3. The summary notes the actual cohort size (4) and why it is below the configured size.

**Scenario C — determinism across two runs with identical inputs:**

**When** the allocator runs twice on Scenario A's fixture with the same configuration:

**Then:**
1. Both runs produce cohorts with identical selected candidates in identical order.
2. No randomness or non-deterministic tie-breaking is observable between runs.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.002 | Append channel accumulates all candidate evaluations before allocator step | Allocator step begins only after all candidates are collected in the channel |
| BC-2.03.001 | BSP super-step determinism: identical inputs → identical execution | Scenario C: two runs on identical inputs produce identical cohorts |
| BC-2.08.003 | Structured output: cohort record typed and deserialized correctly | Allocator emits a typed cohort record with required fields populated |
| BC-2.02.006 | Send API fan-out: parallel candidate evaluators dispatch candidates into channel | Parallel evaluator nodes each contribute one candidate to the Append channel |

---

## Verification Approach

1. Build a graph where N parallel evaluator nodes each produce one candidate record (family label + score). All candidates feed into an Append-channel barrier.
2. After the barrier, an allocator node reads all candidates and applies the per-family cap configuration to select the output cohort.
3. Run Scenario A (10 candidates, 7 strategy-X / 3 strategy-Y, cohort size 6, cap 3). Assert the cohort has exactly 6 candidates. Assert strategy-X has exactly 3 slots. Assert strategy-Y has exactly 3 slots. Assert no duplicates in the cohort.
4. Within strategy-X, assert the 3 selected candidates are the top-3 by score among the 7 strategy-X candidates.
5. Run Scenario B (4 total candidates, cohort size 6). Assert the cohort has exactly 4 candidates. Assert no error is raised. Assert the summary notes the actual cohort size.
6. Run Scenario C: invoke the Scenario A fixture twice. Assert the two cohorts are identical (same selected candidates, same order).
7. Assert the allocator node emits a typed cohort record (not a raw list or string).
8. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Cap enforcement: no family exceeds its configured maximum | 0.30 | Scenario A: strategy-X has exactly 3 slots, strategy-Y has exactly 3 slots |
| Cohort size: exact count under normal conditions | 0.20 | Scenario A output cohort has exactly 6 candidates, all distinct |
| Graceful underflow: short cohort when candidates are insufficient | 0.20 | Scenario B: cohort has exactly 4 candidates, no error raised |
| Determinism: identical inputs → identical cohort | 0.20 | Scenario C: both runs produce identical cohorts |
| Typed output: allocator emits a structured record | 0.10 | Cohort is a typed record with required fields, not a raw list or string |

**Should-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

### EC-001: Per-family cap = 0 for one family
**Expected behavior:** The family with cap 0 receives zero slots. The cohort is filled entirely from other families up to the total cohort size. No error is raised for the capped-out family.

### EC-002: All candidates belong to a single family; cap < cohort size
**Expected behavior:** The cohort is limited to the cap value. The run completes cleanly. The summary notes that the cohort is smaller than the configured size because only one family was available and its cap was reached.

### EC-003: Two candidates from the same family have identical scores (tie)
**Expected behavior:** Tie-breaking is deterministic (e.g., by insertion order or lexicographic candidate ID). The allocator does not produce non-deterministic output on ties. Scenario C behavior holds: two runs with the same tie produce the same tiebreak.

### EC-004: Candidate list contains a record with a null family label
**Expected behavior:** The null-family candidate is either rejected with a structured validation error, or assigned to a special `unlabeled` family bucket with its own cap. It is not silently promoted into a named family's allocation slots.

### EC-005: Configured cohort size = 0
**Expected behavior:** The allocator returns an empty cohort list. No error is raised. The summary notes cohort size 0.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-004 (satisfaction: X.XX) — the QD diversity allocator did not correctly enforce per-family caps or maintain deterministic cohort selection. Likely failure modes:

- Cap violation fail: one family received more than its configured cap slots (e.g., strategy-X occupied 4 or more slots when cap = 3), meaning the allocator did not enforce per-family diversity.
- Cohort size fail: the output cohort had fewer or more candidates than expected under normal conditions (Scenario A should have exactly 6).
- Underflow fail: Scenario B raised an error or padded the cohort with null entries instead of returning the 4 available candidates cleanly.
- Determinism fail: two runs on Scenario A produced different cohorts or different orderings, indicating non-deterministic tie-breaking or random selection.
- Type fail: the allocator returned a raw list or unstructured string instead of a typed cohort record with the required fields."

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
