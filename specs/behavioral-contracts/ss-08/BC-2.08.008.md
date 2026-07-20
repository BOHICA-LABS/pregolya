---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.008
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-011
wave: 2
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-standard-tests per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "38116f5"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.008: Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome (NE-15)

## Description

The ferrochain evaluation framework (the component of `ferrochain-standard-tests`
responsible for LLM-as-judge scoring) must aggregate scores using the arithmetic mean
— not order-dependent merges, exponential moving averages, or other stateful aggregations.
`JudgeResult` is a three-variant enum with `Pass`, `Fail`, and `InfraError`; `InfraError`
represents a judge infrastructure failure (e.g., judge LLM unavailable, timeout, or
invalid response) and is never treated as a quality failure of the agent under evaluation.
Each eval case is run by a single agent in sequence, not in parallel batches, to prevent
concurrency from making scores order-dependent.

## Preconditions

1. One or more `EvalCase` objects with expected behavior have been assembled (from
   domain holdout scenarios or the standard-tests battery).
2. A judge model (an LLM implementing `ChatModel`) is available to evaluate each case.
3. The eval runner is invoked with a list of `EvalCase` entries and a judge model.

## Postconditions

1. **Arithmetic mean aggregation:** The aggregate eval score over N cases is computed as:
   `score = sum(case_scores) / count(Pass + Fail cases)`.
   `InfraError` cases are excluded from both numerator and denominator.
   The result is a `f64` in `[0.0, 1.0]` where 1.0 = all judged cases passed.
2. **JudgeResult three-outcome enum:**
   - `JudgeResult::Pass` — the judge evaluated the agent's response as correct.
   - `JudgeResult::Fail` — the judge evaluated the agent's response as incorrect.
   - `JudgeResult::InfraError { reason: String }` — the judge infrastructure failed
     (judge LLM returned an error, timed out, or returned an unparseable response).
3. **InfraError isolation:** `JudgeResult::InfraError` on a case does NOT decrement
   the aggregate score. It does NOT count as a `Fail`. The infra error is logged at
   WARN level with the `reason` field, and the eval suite continues.
4. **Single agent run per eval case:** Each eval case is executed once, in sequence.
   No parallel fan-out per case. This prevents non-determinism from concurrent
   execution from producing order-dependent score merges (P-64 counter-example).
5. **Score invariant:** If all N judged cases return `Pass`, the aggregate score is
   exactly `1.0`. If all return `Fail`, the aggregate score is exactly `0.0`.
   If all return `InfraError`, the runner returns `Err(EvalError::AllCasesInfraError)` —
   it does not return `1.0` or `0.0`.

## Invariants

- The arithmetic mean formula must be applied exactly: `sum / count`, not
  `sum / total_cases` (which would penalize infra failures as implicit zeros).
- `JudgeResult` has exactly three variants. No additional variants may be added
  without a BC revision. Callers exhaustively match on all three variants.
- Per-case execution is sequential; the judge is called once per case, not once
  per case per judge replica.
- Aggregate score is a `f64`; precision is preserved to ≥ 4 significant figures
  for reporting. Score is never rounded to an integer before reporting.

## Edge Cases

### EC-001: All cases return InfraError
**Scenario:** The judge LLM is unavailable and all N eval cases return `InfraError`.
**Expected behavior:** The eval runner returns `Err(EvalError::AllCasesInfraError)`
rather than reporting a score of `0.0` or `1.0`. The caller can detect this and
surface an infra-outage alert rather than a quality regression.

### EC-002: Mix of Pass, Fail, InfraError
**Scenario:** 10 cases: 6 Pass, 2 Fail, 2 InfraError.
**Expected behavior:** `score = 6 / (6 + 2) = 0.75`. The 2 InfraError cases are
excluded from both numerator and denominator. The report notes 2 infra failures.

### EC-003: Single-case eval returning InfraError
**Scenario:** 1 eval case, judge returns InfraError.
**Expected behavior:** `Err(EvalError::AllCasesInfraError)` — score is undefined.
Not `0.0`, not `1.0`.

### EC-004: Judge response unparseable (not valid JudgeResult JSON)
**Scenario:** The judge LLM returns free-form prose instead of a structured verdict.
**Expected behavior:** The eval runner maps this to `JudgeResult::InfraError
{ reason: "judge returned non-parseable response: <first 256 chars>" }`. The
eval case is not counted as Pass or Fail.

### EC-005: Concurrent eval cases (accidental parallelism)
**Scenario:** An implementer accidentally spawns eval cases with `tokio::spawn` or
`join_all`.
**Expected behavior:** The eval runner's API must be sequential (e.g., returns an
iterator or processes in a `for` loop with `await`). If parallel execution is
attempted, the runner must document that scores may be non-deterministic and
the conformance suite must enforce sequential execution via a single-task executor.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | 5 Pass, 0 Fail, 0 InfraError | `score = 1.0` | All pass |
| TV-002 | 3 Pass, 2 Fail, 0 InfraError | `score = 0.6` | Arithmetic mean |
| TV-003 | 6 Pass, 2 Fail, 2 InfraError | `score = 0.75` (8 judged cases) | EC-002 |
| TV-004 | 0 Pass, 0 Fail, 3 InfraError | `Err(EvalError::AllCasesInfraError)` | EC-001 |
| TV-005 | Judge returns prose instead of verdict | `JudgeResult::InfraError { reason: "…" }` — not Fail | EC-004 |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208008-01 | Arithmetic mean formula: sum(Pass) / count(Pass+Fail) with InfraError excluded | Unit test (parameterized with TV-001 through TV-004) | Wave 2 |
| VP-BC208008-02 | AllCasesInfraError returns Err, not Ok(0.0) or Ok(1.0) | Unit test (EC-001 and EC-003) | Wave 2 |
| VP-BC208008-03 | JudgeResult has exactly 3 variants — no 4th variant added | Compile-time exhaustive match in tests | Wave 2 |

## Related BCs

- BC-2.08.001 — streaming conformance (eval may run streaming tests)
- BC-2.08.005 — usage accounting (eval may track cost via usage metadata)
- BC-2.17.001 — Kani harness (formal verification uses separate VP mechanism, not eval scoring)

## Architecture Anchors

- `ferrochain-standard-tests/src/eval/judge.rs` — JudgeResult enum + eval runner (to be created)
- `ferrochain-standard-tests/src/eval/scoring.rs` — arithmetic mean aggregation (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208008-01, VP-BC208008-02, VP-BC208008-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-011 |
| Capability Anchor Justification | CAP-011 ("Provider Conformance Suite (Standard Tests)") per capabilities-p1-p2.md §CAP-011 — this BC specifies the eval scoring correctness requirements of ferrochain-standard-tests, closing the NE-15 (adk-rust P-64) must-not-inherit pattern for order-dependent score merging and missing infra-error distinction |
| L2 Domain Invariants | — |
| NE References | NE-15 (P-64 counter-example: multi-turn score merge is order-dependent; judge infra failure = quality fail — this BC mandates arithmetic mean + InfraError third outcome) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit — scoring formula, AllCasesInfraError, exhaustive match), CT (compile-time — exhaustive JudgeResult match) |
| Module | ferrochain-standard-tests |
