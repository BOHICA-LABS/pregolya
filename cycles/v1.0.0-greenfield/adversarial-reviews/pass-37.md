---
document_type: adversarial-review-pass
phase: 1d
pass: 37
verdict: NOT CLEAN
findings_count: 2
high_count: 1
med_count: 1
low_count: 0
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→0→0"
timestamp: 2026-07-14T00:00:00Z
new_class: "architecture criticality cross-coherence (OBS-P37-1)"
novelty: MEDIUM-HIGH
routed_to_po: 0
routed_to_architect: 2
---

# Adversarial Review Pass 37 — Phase 1d

**Verdict: NOT CLEAN** — 2 findings (1 HIGH pattern, 1 MED). 2 non-blocking observations. Novelty: MEDIUM-HIGH. Convergence counter **reset to 0/3**.

---

## Findings

### F-P37-01 (HIGH, pattern) — module-decomposition.md Criticality Column Contradicts module-criticality.md for 4 Modules

**Location:** `.factory/specs/architecture/module-decomposition.md` — Criticality column and structurally-privileged module-tier headings.

**Claim in module-decomposition.md:** graph::channels=CRITICAL, core::message=CRITICAL, graph::event_emitter=HIGH, ferrochain-macros=MEDIUM (including the structurally-privileged `## ferrochain-macros — MEDIUM` section heading).

**Authoritative value (module-criticality.md):** graph::channels=HIGH, core::message=HIGH, graph::event_emitter=MEDIUM, ferrochain-macros=HIGH.

**Discrepancy:** 4 modules are mis-tiered in the derived document relative to the authoritative registry:
- `graph::channels`: CRITICAL → should be HIGH
- `core::message`: CRITICAL → should be HIGH
- `graph::event_emitter`: HIGH → should be MEDIUM
- `ferrochain-macros`: MEDIUM → should be HIGH (including structurally-privileged heading)

**Root cause:** module-decomposition.md was last touched in pass 29 (doc v1.1). The criticality reconciliation performed in passes 31/32 propagated tier corrections to the two registry files (module-criticality.md arch-view and PO supplement) but never reached module-decomposition.md. Gate #25 Part B named only the two registry files as the sibling set — omitting the derived architecture docs — so this drift was invisible to all subsequent census checks in passes 31–36.

**Downstream impact:** The mutation-kill-rate gate applies thresholds of CRITICAL ≥ 95% / HIGH ≥ 90% / MEDIUM ≥ 80%. With graph::channels mis-tiered as CRITICAL, its actual HIGH threshold (90%) would be enforced at the CRITICAL rate (95%) — 5 pp over-strict — while core::message receives the same over-strict treatment. ferrochain-macros, if tiered MEDIUM (80%), would be under-strict by 10 pp relative to its authoritative HIGH (90%) tier. These are concrete gate mis-applications in the formal hardening phase.

**Routing:** Architect — fixes module-decomposition.md Criticality column and structurally-privileged headings.

---

### F-P37-02 (MED) — verification-coverage-matrix.md §Coverage by Criticality Tier Summary Contradicts Both Registry and Own Per-Module Table

**Location:** `.factory/specs/architecture/verification-coverage-matrix.md` — `§Coverage by Criticality Tier` summary row.

**Claim in summary:** 6/7/5/2=20 (CRITICAL/HIGH/MEDIUM/LOW total).

**Authoritative count (module-criticality.md arch-view):** 9/12/10/2=33.

**Doc's own per-module table:** 9 CRITICAL rows enumerated, 11 HIGH rows enumerated — the summary also contradicts the document's internal per-module table.

**Additional detail:** The LOW row count (2) counts modules absent from the per-module table, confirming that the per-module table intends to be full-universe. The Kani VP count of 3 in the same section is correct.

**Root cause:** Same as F-P37-01 — gate #25 Part B's sibling set omitted the derived architecture docs. The tier summary was never cross-checked against the registry or internal table in passes 31–36.

**Routing:** Architect — fixes §Coverage by Criticality Tier summary row (correct to 9/12/10/2=33) and reconciles HIGH row count in per-module table.

---

## Observations (non-blocking)

### OBS-P37-1 [process-gap] — Gate #25 Part B Sibling Set Omits Derived Architecture Docs

Gate #25 Part B (criticality-sibling coherence) names only two documents in its sibling set — `.factory/specs/module-criticality.md` (arch registry) and `.factory/specs/prd-supplements/module-criticality.md` (PO registry). It omits the two derived documents that also carry criticality data:

- `.factory/specs/architecture/module-decomposition.md` (per-module Criticality column + tier headings)
- `.factory/specs/architecture/verification-coverage-matrix.md` (per-tier summary + per-module table)

This is why F-P37-01 and F-P37-02 survived passes 31–36: every burst that touched the registry files performed the two-sibling census and closed clean, while the derived docs drifted unchecked.

**Fix:** Widen gate #25 Part B to enumerate all four criticality-bearing documents. Census rule: any change to a module's tier or to tier counts MUST be propagated to all four in the same burst; the census greps each module's tier across all four docs and diffs. **Routing:** PO — update bc-authoring-plan.md gate #25 Part B.

### OBS-P37-2 — GTV Mirror Non-Normative Annotation Cells Differ (Minor)

Two non-normative annotation cells differ between the authoritative BC file (`BC-2.07.002.md`) and the test-vectors.md mirror:

- **GTV-003 Expected-cell parenthetical:** BC has `(after separator split on space)`; test-vectors.md has `(separator split on space)` — missing the word "after".
- **GTV-008 Input-cell code-point note:** BC has `(3+5+3=11 code pts)`; test-vectors.md has `(11 code pts)` — missing the breakdown prefix.

All normative expected values and PROVISIONAL markers are byte-identical. This is a minor documentation drift with no functional impact on test authoring.

**Fix:** Copy BC's (authoritative) annotation text into test-vectors.md for GTV-003 and GTV-008 (and audit remaining rows for similar annotation drift). **Routing:** PO.

---

## Sibling-Checks Performed (All PASS)

1. **ADR-006 heading ferrochain-native + zero live LangGraph wire claims:** PASS — heading and body both read ferrochain-native; no live "LangGraph format" or "LangGraph wire" strings remain in `.factory/specs/`.
2. **ADR-001 interrupt rule consistency:** PASS — interrupt rule consistent across both references; BC-2.05.003 coherent.
3. **GTV-001..009 normative values + PROVISIONAL markers:** PASS — GTV-008 byte-identical PROVISIONAL both files; all GTV-001..009 normative expected values identical between BC-2.07.002.md and test-vectors.md.
4. **Gate #26 first census run (retired-canon):** PASS — zero live retired-canon hits across `.factory/specs/`: node_delta, after-reduction, past-tense LangGraph variants, E-RETRY-003 InvalidRetryLimit, LangGraph format, UNBOUNDED — all absent.

---

## Census Results

- **Gate #16 two-form:** PASS — zero collisions.
- **Gate #24:** PASS — no UNBOUNDED endpoints; no-list-all-schedules note present.
- **Gate #25 (enumerated targets):**
  - arch 33 = 9/12/10/2 ✓
  - PO 20 = 6/8/4/2 ✓
  - macros HIGH both ✓
  - 86 BCs ✓
  - 5 VPs ✓
  - 18 crates ✓
  - 26 endpoints ✓
  - Coverage-matrix tier summary NOT in gate #25's target list (OBS-P37-1 gap — now fixed by widening Part B).

---

## Novel Probes

**(a) Product-brief ↔ PRD ↔ L2 coherence:** CLEAN — 18-crate roster, tiers 11/5/3 per CAP-001..019 reconciled; 48/30/8 BC priority split consistent; VP obligations consistent.

**(c) Capability-tier vs BC-priority:** CLEAN — tallies sum exactly 48/30/8; no BC priority exceeds capability tier; 3 proc-macro P1 BCs on P0 caps are legitimate add-ons; all 86 `capability:` frontmatter values match BC-INDEX.

**(self-selected) Architecture criticality cross-coherence:** → F-P37-01, F-P37-02 (see above).

---

## Novelty Assessment

**MEDIUM-HIGH** — genuinely new probe axis (architecture criticality cross-coherence between registry and derived architecture docs) that has never been probed in passes 1–36. The two findings are substantive with concrete downstream impact: mutation-kill-rate gate thresholds would be mis-applied. The process gap (OBS-P37-1) explains why 5+ prior passes missed both findings.
