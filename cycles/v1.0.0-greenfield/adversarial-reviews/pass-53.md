---
pass: 53
verdict: NOT CLEAN
findings: 1
severity_distribution: MED=1
novelty: LOW-MEDIUM
confidence: HIGH
reviewer: adversary
date: 2026-07-15
---

# Adversarial Review — Pass 53

## Verdict: NOT CLEAN

1 finding (MED, confidence HIGH). Novelty LOW-MEDIUM.

---

## F-P53-01 (MED) — §9 NE Rollup Undercounts BC + CI Lint Gate Category

**Location:** `prd.md` §9 NE Requirement Disposition Table — summary line (line ~606)

**Finding:**

The summary line reads:

> "17/17 NEs anchored. 15 → BC; 1 → BC + CI lint gate (NE-04); 1 → CI lint gate only (NE-05)"

This contradicts its own table. THREE rows carry disposition "BC + CI lint gate":

| NE    | BC          | Lint gate command                          |
|-------|-------------|--------------------------------------------|
| NE-04 | BC-2.14.004 | `cargo xtask lint-no-timeout` (deny-client-new) |
| NE-07 | BC-2.14.003 | `cargo xtask lint-no-panic` (deny-expect-in-lib) |
| NE-10 | BC-2.14.005 | `cargo xtask deny-bare-api-key`            |

Correct partition (re-derived from all 17 rows):
- **13 → BC** (incl. 3 VP-seed: NE-02/12/17): NE-01, NE-02, NE-03, NE-06, NE-08, NE-09, NE-11, NE-12, NE-13, NE-14, NE-15, NE-16, NE-17
- **3 → BC + CI lint gate**: NE-04, NE-07, NE-10
- **1 → CI lint gate only**: NE-05
- Total: 17 ✓

Summary undercounted CI-gate NEs by 2 — a consumer reading the rollup misses two security/robustness CI gates (NE-07: no-panic in library constructors; NE-10: credential opacity). This is a partial-fix signature: rows were upgraded to "BC + CI lint gate" in the table but the rollup was never re-derived.

**Blast radius:** 1 line in prd.md §9. The `bc-authoring-plan.md` NE table has no rollup — unaffected (OBS-P53-2).

---

## Observations

**OBS-P53-1:** VP 3-doc propagation (VP-INDEX, verification-architecture.md, verification-coverage-matrix.md) fully coherent. No drift detected.

**OBS-P53-2:** Defect isolated to prd.md §9 rollup. The `bc-authoring-plan.md` NE table carries no summary sentence; it is unaffected.

---

## Census Results

| Gate | Surface | Result |
|------|---------|--------|
| #13 (anchor consistency) | §9 NE table | FAIL — rollup misclassifies NE-07 and NE-10 as plain BC |
| #24 (cross-diff) | sampled | PARTIAL — no additional contradiction observed, not exhaustively cross-diffed |
| #25 (retry-core) | full | PASS |
| #27 (roster derivation) | 9+2+1+2+1+3=18 | PASS |
| #28 (sampled BCs) | sampled | PASS |
| #29 (recursion, SSE, FIFO, sandbox, E-GRAPH-017) | full | PASS |

---

## Free Probes

- **/stream SSE authn posture:** No defect. Deployment-layer auth is consistent with single-service topology.
- **POST idempotency:** Covered — BC-2.12.006 + E-SERVER-016.
- **Write-race concurrency:** Uniform coverage — E-SERVER-007/008/012/015 + `multitask_strategy`.

---

## Coverage Caveat

SS-14 cluster read in full. Grep-level censuses elsewhere. Finding fully grounded in table rows.

---

## Novelty Assessment

LOW-MEDIUM — summary-vs-table partition inconsistency on a heavily-probed surface. The individual rows were correct; only the rollup was wrong.
