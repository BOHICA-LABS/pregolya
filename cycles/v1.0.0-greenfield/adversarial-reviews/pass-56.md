---
pass: 56
verdict: NOT CLEAN
findings: 1
severity_distribution: MED=1
novelty: MEDIUM
confidence: HIGH
reviewer: adversary
date: 2026-07-15
---

# Adversarial Review — Pass 56

## Verdict: NOT CLEAN

1 finding (MED). Novelty MEDIUM.

---

## F-P56-01 (MED) — Runnable-Layer Recursion-Limit Error Is Codeless

**Location:** `BC-2.01.003` PC5, invariant §layer-disambiguation, EC-004, TV-004; `interface-definitions.md` §RunnableConfig dual-layer table Runnable-layer row

**Finding:**

The graph-engine-layer recursion halt received E-GRAPH-017 in pass 49. The Runnable-layer counterpart (BC-2.01.003 PC5 + invariant disambiguation text + EC-004 + TV-004) returns:

```
Err(FerrochainError { category: INTERNAL, message: "recursion limit exceeded at depth N" })
```

with NO `code:` field in any of the four sites. The interface-definitions.md dual-layer table Runnable-layer row also has no code. All FerrochainError constructions must carry a catalogued code per error-taxonomy.md line 30 convention (`all errors are FerrochainError { component, category, retry_hint, code, message }`).

The graph-layer counterpart (E-GRAPH-017) was minted in pass 49 but the core-layer error was overlooked. The 75-code disposition census counts only catalogued codes; a codeless construction is invisible to the census.

**Fix:** Mint E-CORE-006 (RecursionLimitExceeded, INTERNAL, broken, BC-2.01.003). Update BC-2.01.003 four sites. Update interface-definitions.md dual-layer table. Recount disposition census 75→76.

---

## OBS-P56-1 (verification required) — 10007 Default Claim in BC-2.03.001 and interface-definitions.md

**Location:** `BC-2.03.001` Reference Evidence §super-step ceiling (lines 96-98); `interface-definitions.md` §RunnableConfig dual-layer table note (line ~81)

**Observation:**

Both documents state: "LangGraph upstream uses 10007 as its graph-layer default via `DEFAULT_RECURSION_LIMIT` env var."

The adversary could not verify this claim from public documentation (well-documented LangGraph default is 25). Potential confusion between langchain-core's `DEFAULT_RECURSION_LIMIT = 25` (Runnable-layer) and a separate LangGraph-level constant.

**Verdict (resolved this burst):** VERIFIED. `.reference/langgraph/libs/langgraph/langgraph/_internal/_config.py:32` contains:

```python
DEFAULT_RECURSION_LIMIT = int(getenv("LANGGRAPH_DEFAULT_RECURSION_LIMIT", "10007"))
```

This is a code constant (not itself an env var) that reads from the `LANGGRAPH_DEFAULT_RECURSION_LIMIT` environment variable with a default of 10007. The 10007 claim is accurate.

The langchain-core (`RunnableConfig`) default of 25 is in `.reference/langchain/libs/core/langchain_core/runnables/config.py:171`: `DEFAULT_RECURSION_LIMIT = 25`.

**Fix:** Tighten wording in BC-2.03.001 Reference Evidence and interface-definitions.md to precisely name the constant, its source file, and the env var name — distinguishing it from langchain-core's `DEFAULT_RECURSION_LIMIT = 25`.

---

## OBS-P56-2 (process-gap) — Disposition Census Structurally Blind to Codeless Error Paths

**Observation:**

The disposition census at pass 55 (75 codes) counts only catalogued error codes. Codeless FerrochainError constructions in BC bodies escape the census entirely. A new standing gate should mandate that every concrete `Err(FerrochainError { ... })` construction in a BC body carries a `code:` field.

**Fix:** Add gate #30 "codeless-error census" to bc-authoring-plan.md. Run a first-pass census this burst and fix all constructions with clear taxonomy mappings.

---

## Passing Censuses

- **Sibling-check:** Disposition census re-run PASS. 75 = 43 + 9 + 23 exact bucket-by-bucket. E-SERVER-013 note at line 280 (pass-55 fix confirmed present). Zero uncovered.
- **Census #16 PASS:** 75 unique variant/code combinations; E-SERVER-001 (PolicyNotEnforceable) retired; near-collision E-SERVER-001/E-SBXD-002 adjudicated safe (E-SERVER-001 tombstoned with no live references).
- **Census #21 PASS:** 12 + 9.
- **Census #22 PASS:** 5 intentional divergences in known-divergences table, all BC-anchored.
- **Census #23 PASS:** Zero flat run-path escapes.
- **Census #26 PASS:** Canonical constants correct — port 7437, recursion 25, pagination default 10 / max 100, secure defaults, sandbox no-fallback.
- **Free probes:**
  - Recursion-shard arithmetic CLEAN: pass-50 fix (N × (recursion_limit + 1) formula) holds across all 4 occurrences verified.
  - Dual-layer cross-refs: F-P56-01 (Runnable-layer codeless) + OBS-P56-1 (10007 claim, verified accurate).
  - VP anchors CLEAN: VP-BSP-DET-01/02/03, VP-001, VP-BC201003-01/02 all cited correctly.
  - BC count re-derivation CLEAN: 86 BCs across 13 batches.
- **Novelty: MEDIUM.**
