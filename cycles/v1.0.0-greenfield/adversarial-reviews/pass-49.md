---
pass: 49
date: 2026-07-15
verdict: NOT-CLEAN
novelty: MEDIUM
finding_count: 1
rejected_count: 1
producer: product-owner
burst: fix-burst-p49
---

# Adversarial Review Pass 49 — Fix Burst Report

## Verdict: NOT CLEAN — 1 substantive finding (F-P49-02, MED-HIGH) + 1 REJECTED false positive. Novelty MEDIUM.

---

## F-P49-01 — REJECTED (false positive)

**Adversary claim:** BC-2.08.011/012 + BC-2.07.002 at v1.1 lack changelogs.

**Rejection basis:** Adversary checked ONLY frontmatter `changelog:` keys (Step 1 of gate #28). All three BCs carry `## Changelog` BODY TABLES — the alternate permitted form per gate #28. Verified line locations: BC-2.08.011 line 138, BC-2.08.012 line 145, BC-2.07.002 line 196.

**Root cause:** Gate #28 census command text did not EXPLICITLY spell out the two-form check — the instruction "verify a `changelog:` frontmatter key or `## Changelog` body section exists" was present in prose but the census *command* was Step-1-only (frontmatter grep), giving no machine guidance to run Step 2 (body `^## Changelog` grep). A two-step census with explicit union rule was missing.

**Fix:** Gate #28 census command updated to explicit two-form in bc-authoring-plan.md v1.9 (Task 3, this burst). Motivating instance F-P49-01 cited in the gate.

---

## F-P49-02 — ACCEPTED (MED-HIGH, fixed this burst)

**Title:** Graph super-step ceiling unported.

**Finding:** BC-2.03.001 invariant (≈line 88) and VP-BC208002-01 (≈line 135) reference a "configurable step limit" defined nowhere. The primary infinite-loop guard in LangGraph is `config.recursion_limit` (default 10007 upstream; ferrochain aligns to 25 per langchain-core RunnableConfig defaults) which bounds Pregel super-steps and raises `GraphRecursionError` when exhausted. Evidence: `semport/graph/behavioral-intent.md §1.3` — formula `stop = step + recursion_limit + 1`; `tick()` sets status `out_of_steps` when `step > stop`; outer loop raises `GraphRecursionError`. In ferrochain: BC-2.01.003 PC5 scopes `recursion_limit` ONLY to nested Runnable call depth (INTERNAL, depth-26). The BSP loop (BC-2.03.001) and cycle-creating conditional edges (BC-2.02.005) had NO documented super-step ceiling — a cyclic graph without a defined halt error iterates forever.

**Fix applied this burst:**
1. E-GRAPH-017 (GraphRecursionLimitExceeded, POLICY, Never, broken, BC-2.03.001) minted in error-taxonomy.md v1.6.
2. BC-2.03.001 v1.1: PC5-PC6 (super-step ceiling + resume semantics), EC-006 (ceiling exceeded), TV-006 (cyclic graph test vector).
3. BC-2.01.003 v1.1: cross-reference note in Invariants distinguishing the two `recursion_limit` layers (Runnable-depth vs graph-super-step).
4. BC-2.08.002 v1.1: "configurable step limit" wired to explicit `config.recursion_limit` + BC-2.03.001 + E-GRAPH-017. VP-BC208002-01 updated.
5. interface-definitions.md v2.8: RunnableConfig dual-interpretation note; E-GRAPH-017 added to embedded Run.error blockquote.

---

## OBS-P49-1 — ADJUDICATED (not a defect)

**Adversary note:** Module-criticality arch view lists ferrochain-macros SS="—" while decomposition/BC-INDEX use SS-08.

**Adjudication:** CONFIRMED INTENTIONAL. ferrochain-macros is a cross-cutting proc-macro crate that SUPPORTS SS-08 functionality but does not OWN a subsystem. The "—" in the arch criticality view correctly reflects that the crate's scope is cross-cutting (Batch 13 BCs BC-2.08.010/011/012 are SS-08 BCs whose macro implementations live in ferrochain-macros). This is not drift — it is the intentional distinction between "owns a subsystem" (SS-NN assignment) and "implements cross-cutting support for a subsystem." Future adversary passes: known non-defect, do not re-flag.

---

## Sibling-Check Results

- **Interface-definitions v2.7 PASS:** 6 namespace annotations verified, FIFO note present.
- **Gate #25 (anchor-matrix census) FULL A+B+C PASS:** 33=9/12/10/2 recounted; 4-doc tier coherence incl. P37 fixes; per-row crate diff zero divergent; retry=core holds.
- **Gate #21 PASS:** 12+9 exact.
- **Gate #26 PASS.**
- **Gate #27 PASS.**
- **Gate #28 arithmetic PASS (distribution EXACT 53×1.0+23×1.1+8×1.2+2×1.3=86)** — changelog sub-check produced the rejected false positive F-P49-01; root cause fixed (Task 3).
- **Gate #29 PASS:** all checked seams corroborate incl. P47 sandbox fixes.

---

## Novel Probes

**(a) Negative-space probe → F-P49-02** (Send API, subgraph checkpoint_ns, Runnable recursion_limit all covered; message-trimming utilities absent but plausibly out-of-v1 [E-PROV-006 path] — not flagged).

**(b) TV executable-precision:** 15 sampled — all deterministic, no finding.

**(d) L2→BC fidelity spot:** No weakening detected.

---

## Novelty: MEDIUM
