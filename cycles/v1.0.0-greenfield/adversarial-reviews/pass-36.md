---
document_type: adversarial-review-pass
phase: 1d
pass: 36
verdict: NOT CLEAN
findings_count: 3
high_count: 1
med_count: 2
low_count: 0
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→1→0"
timestamp: 2026-07-16T00:00:00Z
new_class: "structurally-privileged-line blind spot (OBS-P36-2)"
---

# Adversarial Review Pass 36 — Phase 1d

**Verdict: NOT CLEAN** — 3 findings (1 HIGH, 2 MED). 2 non-blocking observations. Novelty: MEDIUM. Convergence counter **reset to 0/3**.

---

## Findings

### F-P36-01 (HIGH) — ADR-006 Decision Heading Contradicts Ferrochain-Native Wire Body

**Location:** `architecture/decisions/ADR-006-streaming-event-taxonomy.md` line 30, `## Decision:` heading.

**Claim in heading:** "JSON-serialized to LangGraph format over HTTP"

**Body:** Lines 59 and 67–71 specify ferrochain-native wire format per D13. The body is correct; the heading is a partial-fix residue of F-P29-05, which updated the body but left the heading unchanged. This heading was never re-read by prior passes.

**Why HIGH:** The `## Decision:` heading is structurally privileged — it appears in navigation, diff summaries, and is typically the first line read by reviewers. A heading that contradicts the authoritative body is first-class misleading documentation. Any reviewer skimming the ADR will absorb an incorrect decision.

**Fix:** Change heading to state ferrochain-native wire format, matching the body.

**Routing: Architect.**

---

### F-P36-02 (MED) — ADR-001 DI-003 Interrupt-Queue Check Placement Contradictory

**Location:** `architecture/decisions/ADR-001.md` line ~102 (responsibilities item 6) and line ~163 (Consequences section).

**Contradiction:** Responsibilities item 6 places the DI-003 interrupt-queue check "after reduction"; the Consequences section places it "in the Collecting→Reducing transition." These are opposite sides of the Reducing phase.

**Why MED:** This placement is material for HITL correctness given BC-2.05.003 node-re-executes semantics (an interrupted node re-executes from the start of its super-step on resume). Placing the check on the wrong side of Reducing would allow incorrect state to be committed before the interrupt is caught.

**Fix:** Adjudicate the correct placement and make both references agree.

**Routing: Architect.**

---

### F-P36-03 (MED) — test-vectors.md GTV-008 Placeholder Drifted from BC-2.07.002 Authoritative Value

**Location:** `prd-supplements/test-vectors.md` line 164 (GTV-008 row) and lines 167–169 (note).

**Drift:**
- `test-vectors.md` GTV-008 Expected Chunks column: "Verify against Python reference before writing test" (placeholder)
- `BC-2.07.002.md` line 111 GTV-008 Expected Chunks: `["abc🎉🎉", "🎉🎉🎉x", "yz"]` (concrete value)
- `test-vectors.md` self-describes as a "read-only copy" (lines 133–135) but does not copy the concrete value from the source of truth.
- Additional contradiction: test-vectors.md lines 167–169 note says "Do not hard-code these without verification" while BC-2.07.002 carries a hard-coded value (provisionally, with line-114 caveat).

**Sibling check:** GTV-001..007 and GTV-009 match exactly between both files. Only GTV-008 drifted.

**Fix (safe resolution):** Make both artifacts carry the same content. Keep the concrete value in BC-2.07.002, clearly marked PROVISIONAL. Sync test-vectors.md GTV-008 row to the same concrete value with the same PROVISIONAL marker. Reconcile the "Do not hard-code these without verification" note so it no longer contradicts the presence of provisional values.

**Routing: Product Owner.**

---

## Observations

### OBS-P36-1 [provisional-by-note, non-blocking] — BC-2.07.002 GTV-008 Provisional Status Implicit

`BC-2.07.002.md` GTV-008 carries the concrete value `["abc🎉🎉", "🎉🎉🎉x", "yz"]` alongside a note at line 114 that it must be verified against the Python reference before the Red Gate test is written. The provisional status is conveyed by note only — it is not marked PROVISIONAL explicitly in the table cell.

After the F-P36-03 fix makes both files carry the same concrete value with the same PROVISIONAL marker, OBS-P36-1 is addressed as a byproduct. Reconcile in the same fix burst.

---

### OBS-P36-2 [process-gap] — Structurally-Privileged-Line Blind Spot

This is the **second** instance (after F-P27-02) of a fix that updated body prose but did not re-read structurally-privileged lines. In both cases the heading or summary line retained the retired claim after the body was corrected:
- F-P27-02: a prior fix left a stale claim in a summary line.
- F-P36-01: the F-P29-05 fix updated ADR-006 body to ferrochain-native wire format but left `## Decision:` heading stating "JSON-serialized to LangGraph format over HTTP".

**Proposed standing gate:** Any fix that retires a canon claim MUST grep structurally-privileged lines — markdown H1/H2/H3 headings (especially `## Decision:` in ADRs), Summary cells/blocks, and index/registry rows — across the affected document AND its citing documents for the retired claim, not just body prose.

**Action:** Codify as gate #26 in `bc-authoring-plan.md` (Product Owner scope).

---

## Regression Checks

| Gate | Probe | Result |
|------|-------|--------|
| E-RETRY-004/003 separation | E-RETRY-004 = InvalidRetryLimit (VAL, Never) in error-taxonomy v1.5 + BC-2.16.001 v1.1; E-RETRY-003 = CircuitBreakerOpen sole owner of BC-2.16.003 | PASS |
| Gate #16 two-form census | Space-delimited and colon-delimited E-code↔variant pairings; zero collisions | PASS |
| Gate #24 six-surface pagination | 6/6 pagination surfaces verified | PASS |

---

## Censuses

### Census #21 — Categorical-Token Census

12 categories + exactly 9 known overrides. E-GRAPH-013 SECURITY→403 categorical (not a VAL 422 override). **PASS.**

### Census #22 — RetryHint Coherence

5 intentional divergences: E-RETRY-003 (`Later`), E-CRON-003 (`Later`), E-MEMORY-002 (`Never`), E-MEMORY-005 (`Never`), E-BUDGET-002 (`Never`). All 5 present with rationale in bc-authoring-plan.md divergence table. **PASS.**

### Census #23 — Streaming-Event-Name Coherence

11 StreamEvent variants verified. Envelope consistent across BC-2.05.001, BC-2.05.002, BC-2.10.004, BC-2.12.007. **PASS.**

### Census #25 — Summary-Arithmetic Census

| Counter | Expected | Verified | Status |
|---------|----------|----------|--------|
| Arch-view criticality | 33 modules | 9C / 12H / 10M / 2L = 33 | PASS |
| PO-draft criticality | 20 rows | 6P0+8P1+4P2+2L = 20 | PASS |
| BCs (catalog) | 86 | P0 48 + P1 30 + P2 8 = 86 | PASS |
| VPs | 5 | VP-001..VP-005 | PASS |
| Crates | 18 | per ARCH-INDEX roster | PASS |
| Endpoints | 26 | §17-B invariant + bc-authoring-plan lines 407–411 | PASS |

**PASS.**

---

## Novel Probes

### Axis (a) — test-vectors.md Supplement vs BC-Embedded TV Cross-Validation

**Probe:** Diff GTV-001..009 between `prd-supplements/test-vectors.md` and `behavioral-contracts/ss-07/BC-2.07.002.md`. Verify all GTV counts agree. Check for orphan TVs.

**Result:**
- GTV-001..007, GTV-009: byte-identical expected values in both files. ✓
- GTV-008: **DRIFT** — see F-P36-03 above.
- GTV total count: 9 in each file (matching inventory rows). ✓
- TV counts (separate from GTVs): test-vectors.md inventory row for BC-2.07.002 shows "3 TV + 9 GTV"; BC-2.07.002 body shows TV-001/TV-002/TV-003 (3 TVs) + 9 GTVs — reconciles. ✓
- "~475" total vector approximation in test-vectors.md line 125: acceptable (no precise count claim). ✓
- No orphan TVs. ✓

**Verdict:** One finding (F-P36-03). Otherwise CLEAN.

### Axis (b) — ADR-001..011 Pairwise Sweep

**Probe:** Read all 11 ADRs for pairwise contradiction in: wire format (D13), CheckpointId type (u64), schemars version (1.x), 18-crate roster, BUDGET trait placement, status field values.

**Results:**
- ADR-006 `## Decision:` heading: **FINDING** — F-P36-01 above.
- ADR-001 DI-003 interrupt-queue check placement: **FINDING** — F-P36-02 above.
- All cross-ADR pins consistent: msgpack ✓, u64 CheckpointId ✓, schemars 1.x ✓, 18-crate roster ✓, BUDGET trait placement ✓.
- All status fields accepted and match ARCH-INDEX registry. ✓

**Verdict:** Two findings (F-P36-01, F-P36-02). Cross-ADR pins otherwise CLEAN.

---

## Novelty Assessment

**Classification: MEDIUM.**

Three substantive new cross-artifact contradictions: (1) structurally-privileged-heading vs body (F-P36-01), (2) intra-ADR responsibility placement ambiguity (F-P36-02), (3) read-only-copy supplement drift from authoritative BC (F-P36-03). The structurally-privileged-line blind spot identified in OBS-P36-2 introduces a new process gate class (gate #26). Two prior clean-pass axes (test-vectors supplement, ADR pairwise sweep) were unprobed and yielded findings on first probe — confirming MEDIUM novelty.

All standing gates #1–#25 pass. No regressions from P25–P35 fixes.

---

## Fix Records

### F-P36-03 Fix (Product Owner scope)

**BC-2.07.002.md v1.1:**
- GTV-008 table row: added `(PROVISIONAL — verify against Python reference before Red Gate test)` marker to expected value `["abc🎉🎉", "🎉🎉🎉x", "yz"]`.
- Note below table: updated to state GTV-008 is PROVISIONAL; values marked PROVISIONAL must be Python-verified before Red Gate test is written.

**test-vectors.md v1.1:**
- GTV-008 row: synced to concrete value `["abc🎉🎉", "🎉🎉🎉x", "yz"]` with PROVISIONAL marker (was: placeholder "Verify against Python reference before writing test").
- Note on GTV-003 and GTV-008: updated to say values marked PROVISIONAL must be Python-verified before Red Gate test; removed "Do not hard-code these without verification" language that contradicted the presence of provisional values.

### Gate #26 Codification (Product Owner scope)

`bc-authoring-plan.md` updated with:
- Standing gate #26 "Structurally-Privileged-Line Canon Check" added with census commands, trigger, scope, and two motivating instances (F-P27-02, F-P36-01).
- `total_standing_gates: 26` added to frontmatter.
- Changelog updated.
