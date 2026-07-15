---
document_type: adversarial-review-pass
phase: 1d
pass: 38
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 1
low_count: 0
observations_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "...→0→0→0"
timestamp: 2026-07-14T00:00:00Z
new_class: "stale-count residue (prose/heading vs table count drift)"
novelty: LOW
routed_to_po: 0
routed_to_architect: 1
---

# Adversarial Review Pass 38 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (MED). 1 non-blocking observation. Novelty: LOW. Convergence counter **reset to 0/3**.

---

## Findings

### F-P38-01 (MED) — verification-architecture.md §Committed VP Obligations Intro Contradicts Table Row Count and Own Total Line

**Location:** `.factory/specs/architecture/verification-architecture.md` — §Committed VP Obligations (D17-Q7), line 52.

**Claim in prose/heading:** Intro reads "Three VPs committed before v1.0 release (NFR-003):" and leads directly into a 5-row table (VP-001..VP-005).

**Authoritative count:** VP-INDEX = 5 VPs; doc's own line-62 total reads "5 VPs — 3 P0 / 2 P1 | Kani ×3, integration ×2".

**Discrepancy:** The intro/heading says "Three" but the immediately following table contains 5 rows (VP-001, VP-002, VP-003, VP-004, VP-005). The doc's own summary line (line 62) correctly states 5. The heading-level claim ("Three VPs committed before v1.0 release") is stale residue from before VP-004 and VP-005 (R11-origin integration VPs, not D17-Q7) were added to the table.

**Cross-check (all CLEAN — drift localized to this line):**
- `system-overview.md:93` — "All 3 Kani VPs" ✓ (refers to Kani subset, not total)
- `prd.md:365` — correct ✓
- `nfr-catalog.md:32` — NFR-003 = 3 Kani ✓ (refers to Kani subset, not total)

**Root cause:** Same class as gate #25-A / #26 count-vs-table drift seen in passes 25/26. VP-004 and VP-005 were added to the table in a later burst; the intro prose/heading was not updated to reflect the new total. NFR-003 governs only the 3 Kani VPs — the 2 integration VPs (VP-004, VP-005) have a different origin (R11) — so the sentence is also semantically misleading in that it conflates total VP commitment with the NFR-003 Kani obligation.

**Fix:** Update the intro to read "Five VPs committed before v1.0 release (3 Kani per NFR-003, 2 integration per R11):" or equivalent wording that matches the 5-row table and line-62 summary.

**Routing:** Architect.

---

## Observations (non-blocking)

### OBS-P38-1 [intentional-design] — Error Taxonomy Codes Referenced by Category in Anchor BCs

Several taxonomy codes (E-PROV-002/003/004, E-CHKPT-003, E-SERVER-005, E-MCP-003) are described by CATEGORY in their anchor BCs rather than by E-code string. This is consistent intentional design: codes live in the taxonomy registry; BCs reference categories except where a specific E-code carries semantic distinction meaningful to the contract. Not a defect.

---

## Sibling-Checks Performed (All PASS)

1. **module-decomposition v1.2 full row diff vs authoritative registry:** PASS — message/channels HIGH, event_emitter MEDIUM, macros heading + tool/entrypoint/task HIGH; decomposition-only modules have no conflicting registry rows.
2. **verification-coverage-matrix v1.1:** PASS — 33 rows counted; 9/12/10/2=33; Kani-VP count 3; totals row coherent.
3. **Gate #25 Part-B 4-doc census FIRST FULL RUN:** PASS — every module has identical tier across all four documents where present.
4. **GTV mirror:** PASS — 9/9 byte-identical including annotations and PROVISIONAL marker.

---

## Census Results

- **Gate #22 RetryHint:** PASS — registry exactly 5 divergences, agree in both docs; E-RETRY-004 correctly excluded.
- **Gate #23 streaming:** PASS — 11 variants, node_stream, envelope consistent; no astream_events claims.
- **Gate #26 privileged-line:** PASS with F-P38-01 as sole exception — all other retired canons have zero live hits; ADR-006 heading holds.
- **Arithmetic:** PASS — 86 BCs; 48/30/8; 5 VPs; 18 crates; 26 endpoints; CAPs 11/5/3=19.

---

## Novel Probes

**(b) VP-001..005 content integrity:** CLEAN — property statements match anchoring BC invariants (DI-001/DI-005/DI-007); harness_fn registry consistent 4 ways; Kani no-async honored; D17-Q7 top-3 = the 3 committed Kani VPs.

**(d) Error-taxonomy completeness:** CLEAN — ~297 BC E-code hits all exist; no tombstone use; every code BC-anchored.

**(a) Holdout domains B & C:** CLEAN — all [P]/[CORE]/[COVERED] items trace; [NEW] items explicitly application-layer, consistent with framework scope; Domain B budget-metering gap since adopted via D17-Q4 — spec exceeds brief.

**(c) Canonical type-name census:** CLEAN — zero live violations; hits confined to exempt reconciliation/registry/semport contexts.

---

## Novelty Assessment

**LOW** — single narrow prose-count drift; same class as gate #25-A/#26 count-vs-table findings from passes 25/26. Package is otherwise at convergence. Recommend fix and re-run.
