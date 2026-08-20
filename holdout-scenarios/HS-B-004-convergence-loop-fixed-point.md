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
id: HS-B-004
title: "Convergence Loop Terminates at Fixed Point — Streak Resets on New Finding"
category: edge-case-combinations
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.005
  - BC-2.04.001
  - BC-2.04.004
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
changelog:
  - "1.0 (initial, 2026-08-18): base scenario authored."
  - "1.1 (F-P2A003-02, P2A-003-fix-burst, 2026-08-19): BC-linkage re-anchoring sweep — 2 BCs re-anchored in frontmatter behavioral_contracts and BC-linkage table to semantically-correct IDs verified against BC-INDEX."
---

# Holdout Scenario HS-B-004: Convergence Loop Terminates at Fixed Point — Streak Resets on New Finding

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A review-fix cycle is modeled as a cyclic subgraph. The cycle terminates when three consecutive iterations pass with no new findings. If a new finding is injected between iterations, the clean-streak counter resets to zero.

**Given** a cyclic subgraph implementing a review → fix → review loop. The loop carries a convergence state: `{ clean_streak: u32, total_iterations: u32, findings: Vec<Finding> }`. The loop terminates when `clean_streak == 3`. A test fixture controls which iterations inject findings and which pass clean. Checkpoint is written after each iteration.

**Scenario A (converging):** Iterations 1 and 2 pass clean. Iteration 3 injects a new finding (streak resets to 0). Iterations 4 and 5 pass clean. Iteration 6 passes clean. With streak = 3 at the end of iteration 6, the loop terminates.

**Scenario B (non-converging with finding reinjection):** Iterations 1 and 2 pass clean. Iteration 3 injects a finding. Iterations 4 and 5 pass clean. Iteration 6 ALSO injects a finding (streak resets again). The loop does NOT terminate after iteration 6 and must continue.

**When** Scenario A runs, **Then:**
1. The loop runs exactly 6 iterations and then terminates.
2. The final state has `clean_streak: 3` and `total_iterations: 6`.
3. The final `findings` list is empty (the finding from iteration 3 was resolved).
4. A convergence record is emitted with `status: "converged"`.

**When** Scenario B runs (up to iteration 6), **Then:**
5. After iteration 6, the loop does NOT terminate (clean_streak ≠ 3).
6. The state has `clean_streak: 0` and `total_iterations: 6` (streak was reset by the finding in iteration 6).
7. The run can be externally stopped after iteration 6 for test purposes; at that point status must be `running`, not `converged`.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.005 | Conditional edge routes to loop-continue vs. loop-exit based on state | Streak < 3 → continue; streak == 3 → exit |
| BC-2.04.004 | Cyclic subgraph executes bounded iterations; per-iteration checkpoint written | Each iteration checkpointed; state accumulates across iterations |
| BC-2.04.001 | Checkpoint written per iteration; state available on resume | convergence state (clean_streak, total_iterations) persisted |

---

## Verification Approach

1. Build a cyclic subgraph where a "review" node returns a findings list (empty or non-empty, controlled by the test fixture), and a "convergence check" node evaluates the clean streak.
2. Configure Scenario A injection pattern: iterations 1, 2 → no findings; iteration 3 → one finding; iterations 4, 5, 6 → no findings.
3. Run the loop. Assert it terminates after exactly 6 iterations with `clean_streak: 3`.
4. Configure Scenario B injection pattern: iterations 1, 2 → no findings; iteration 3 → finding; iterations 4, 5 → no findings; iteration 6 → finding.
5. Run the loop up to 6 iterations. Assert it has not terminated (status is not `converged`).
6. Assert `clean_streak` is 0 after iteration 6 in Scenario B.
7. Both scenarios exit cleanly (Scenario B can be stopped with a max-iterations guard).

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Correct termination in Scenario A | 0.40 | Loop exits at iteration 6 with clean_streak == 3 |
| Streak reset on finding in Scenario A | 0.25 | Iteration 3 finding causes streak to reset; loop continues |
| Non-termination in Scenario B | 0.20 | Loop does not terminate at iteration 6 when streak was reset by iteration 6 finding |
| Per-iteration state persistence | 0.15 | clean_streak and total_iterations correctly maintained across all iterations |

**Threshold for should-pass:** weighted average ≥ 0.55.

---

## Edge Conditions

- Streak reaches 3 on the very first three iterations (no findings at all): loop terminates after exactly 3 iterations.
- Finding injected on the third consecutive clean iteration (streak was at 2): streak resets to 0, not to 1.
- Maximum iteration limit configured lower than convergence point: loop halts with a structured error (not `converged`), not a panic.

---

## Failure Guidance

"HOLDOUT LOW: HS-B-004 (satisfaction: X.XX) — convergence loop did not terminate at the correct iteration, or did not reset the streak correctly when a finding was injected."

---

## Category: real-world-corpus

Not applicable — this scenario uses a synthetic convergence fixture. Category is `edge-case-combinations`.
