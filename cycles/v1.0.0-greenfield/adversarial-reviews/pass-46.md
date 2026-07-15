---
document_type: adversarial-review
pass: 46
verdict: NOT_CLEAN
severity: MEDIUM
novelty: MEDIUM
phase: 1d
timestamp: 2026-07-14T00:00:00Z
findings_count: 1
observations_count: 1
---

# Adversarial Review — Pass 46

## Verdict: NOT CLEAN — 1 finding (MED, confidence HIGH). Novelty MEDIUM.

---

## Findings

### F-P46-01 (MED): Streaming × interrupt seam contradiction between BC-2.06.001 and BC-2.12.007

**Location:**
- BC-2.12.007 TV-005 line 133: `"SSE emits {"__interrupt__": [...]} event; run_end.status = interrupted"`
- BC-2.12.007 EC-003 lines 107-109: `"stream ends with status: interrupted"`
- BC-2.12.007 EC-001 lines 92-93: `"the stream closes with no run_end event (or a run_end with status: 'failed')"`

**Finding:** BC-2.06.001 (the streaming taxonomy AUTHORITY, as declared by BC-2.12.007's own changelog entry at 1.1) has TV-004 explicitly: "RunEnd not emitted for interrupted run | Interrupt truncates event stream at boundary." Its PC2 states `RunEnd` is emitted "once at run completion" — a completion-only invariant.

BC-2.12.007 TV-005 asserts `run_end.status = interrupted`, directly contradicting BC-2.06.001 TV-004. BC-2.12.007 EC-003 asserts "stream ends with `status: interrupted`," implying a `run_end` SSE event carrying that status. These are mutually unsatisfiable conformance assertions: an implementation cannot simultaneously (a) emit no `run_end` for interrupted runs (BC-2.06.001 TV-004) and (b) emit `run_end.status = interrupted` (BC-2.12.007 TV-005/EC-003).

Secondary tension: BC-2.12.007 EC-001 hedges with `(or a run_end with status: "failed")` — the same author-model that a terminal `run_end` event may carry non-completed status. BC-2.06.001 has no explicit failed-run termination edge case (no EC for this scenario), leaving the hedge unresolved by any authority text.

**Corroboration:** `domain-spec/events.md` lines 87-90 confirm `run_end` fires only when the frontier is empty AND no interrupts are pending. Event-Ordering-Rule 6 is consistent with a completion-only `RunEnd`. The interrupt envelope `{"__interrupt__": [...]}` is already defined as the terminal SSE frame in BC-2.05.001.

**Fix:** BC-2.12.007 TV-005 — remove `run_end.status = interrupted`; expected behavior = interrupt envelope is the terminal SSE frame; stream truncates; no `run_end` emitted; resume produces a new `RunStart` sequence per BC-2.06.001 Related-BCs. BC-2.12.007 EC-003 — fix "stream ends with `status: interrupted`" to "stream truncates after interrupt envelope; no `run_end` emitted; run status queryable via REST." BC-2.12.007 EC-001 — resolve the hedge: stream closes with NO `run_end` on failure (error via `error` SSE event only); `RunEnd` is reserved for the completion path. BC-2.06.001 — add EC-005 adjudicating failed-run termination (stream closes after `error` SSE event; no `RunEnd`) to make the authority explicit.

**Fix owner:** product-owner (this burst) — BC-2.12.007 TV-005 / EC-003 / EC-001; BC-2.06.001 EC-005 adjudication.

---

## Observations

### OBS-P46-1: BC-2.09.005 VP row — Red Gate phrasing drift from sibling

**Location:** BC-2.09.005 line 132 (VP-005 row): `"Red Gate test (compile+pass but network assertion fails)"`
vs BC-2.09.004 line 131 (VP-004 row): `"Red Gate test (compile+fail), then unit test post-implementation"`

**Observation:** Same conceptual intent (the test compiles but the behavioral assertion inside it fails), expressed with phrasing drift. Not a defect — both accurately describe a Red Gate test. Phrasing alignment recommended to avoid misread as two distinct test states. **Routed to product-owner for alignment in same burst.**

---

## Regression Spot-Checks

1. **Coverage-matrix retry=core + gate #25 Part C full 33-row crate diff** — ZERO divergent rows; tier summary 9/12/10/2 PASS.
2. **BC-2.05.006 v1.2 base-mechanism line** — PASS; BC-2.10.004 unchanged-coherent.
3. **Wave-0 note** — PARTIAL (not re-read; no contradiction surfaced).

## Census Results

- **Census #22 (error registry):** PASS — exactly 5 entries; E-RETRY-002 Never = POLICY default, not a 6th divergence.
- **Census #23 (interrupt variants):** PASS — 11 variants; `interrupt_raised` retired confirmed.
- **Census #21 (12-category map):** PASS; 9-override recount PARTIAL (not reached).
- **Census #26:** PARTIAL (not reached this pass).
- **Census #27:** PASS (sampled).
- **Census #28:** PASS (sampled ~20 artifacts).

## Seam Probes

- **Retry × circuit-breaker × tool:** PASS — 3 termination layers coherent; OPEN state doesn't consume global budget; ToolException counts to threshold.
- **Checkpoint × tenancy:** PASS — triple-address authority respected; within-thread recovery; E-CHKPT-005 guard; VP-002 consistent.
- **Streaming × interrupt:** FAIL → F-P46-01 (see above).

---

## Novelty Assessment

**MEDIUM** — F-P46-01 is a genuine cross-BC seam contradiction at the streaming taxonomy authority boundary. The seam (BC-2.06.001 completion-only RunEnd × BC-2.12.007 interrupted-status run_end) was not probed in prior passes. The secondary EC-001 hedge (failed-run terminal event ambiguity) adds a second dimension to the same seam. Fresh-context compounding value confirmed.

**NOTE for pass 47:** Run gates #21 (9-override recount), #26 (full), #27/#28 (full) — all marked PARTIAL this pass. Priority for next pass.

---

## Routing

| Finding | Owner | Status |
|---------|-------|--------|
| F-P46-01 | product-owner (this burst) | Fix BC-2.12.007 TV-005/EC-003/EC-001; adjudicate BC-2.06.001 EC-005 |
| OBS-P46-1 | product-owner (this burst) | Align BC-2.09.005 VP-005 phrasing to sibling convention |
