---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-15T00:00:00Z
phase: 1d
pass: 84
verdict: NOT_CLEAN
finding_count: 1
finding_severity: [MED]
novelty: MEDIUM
novelty_class: index-count-header-row-overcount
sibling_checks: "3/3 PASS"
cycle: v1.0.0-greenfield
traces_to: STATE.md
---

# Adversarial Review — Pass 84 (Phase 1d)

**Verdict:** NOT CLEAN — 1 finding (MED). FIXED (PO-half). OBS-P84-C OPEN (architect dispatch pending).

---

## F-P84-01 (MED — FIXED)

**Target:** test-vectors.md — SS-11 inventory table row counts

**Finding:** The SS-11 section of test-vectors.md overcounted every BC by exactly +1. Root cause: the markdown table HEADER row (`| Input | Expected Output | Category |`) was being counted as a test vector row. SS-11 BCs use unlabelled tables (no TV-NNN identifiers), unlike most other subsystems which use the TV-NNN row format where the header is clearly a structural element.

The adversary probed further and found the class was wider. The same header-row overcount affected:
- SS-04: 6 of 7 BCs miscounted (BC-2.04.001–006 and BC-2.04.007; BC-2.04.005/BC-2.04.008 have TV-NNN rows so their header does not inflate)
- SS-11: all 6 BCs (BC-2.11.001–006)
- SS-13: all 6 BCs (BC-2.13.001–007, but BC-2.13.007 has TV-NNN rows; remaining 6 affected)

Control rows with TV-NNN format (SS-05/SS-06/SS-09, plus BC-2.04.005/008 and BC-2.13.007) were UNAFFECTED.

**Fix (PO — same burst):** test-vectors.md advanced to v1.5. 18 rows corrected across SS-04, SS-11, SS-13:
- SS-04: BC-2.04.001→4; BC-2.04.002→4; BC-2.04.003→4; BC-2.04.004→4; BC-2.04.006→4; BC-2.04.007→4 (6 BCs; BC-2.04.005/008 unchanged)
- SS-11: BC-2.11.001→4; BC-2.11.002→5; BC-2.11.003→4; BC-2.11.004→4; BC-2.11.005→4; BC-2.11.006→4 (all 6)
- SS-13: BC-2.13.001→4; BC-2.13.002→4; BC-2.13.003→5; BC-2.13.004→5; BC-2.13.005→5; BC-2.13.006→5 (6 BCs; BC-2.13.007 unchanged)

Total test vectors: 534 → 516.

---

## OBS-P84-A (FIXED)

**Target:** test-vectors.md — Format column labeling for unlabelled-table BCs

**Finding:** 19 rows in the Format column were labeled "narrative" but actually describe BCs using markdown tables without TV-NNN identifiers. The "narrative" label was inaccurate and masked the presence of structured test data.

**Fix (PO — same burst):** 19 rows relabeled "table (unlabelled)". Usage Note 3 rewritten to explain the schema distinction: TV-NNN rows (labeled "table (TV-NNN)") count the data rows only; unlabelled tables count the data rows only, explicitly excluding the header row.

---

## OBS-P84-B (FIXED — adjudicated D18-P84-A)

**Target:** BC-2.11.002, BC-2.11.003, BC-2.11.004 — Supplement citation style in BC bodies

**Finding:** BC-2.11.002 body contained "interface-definitions.md v2.13" version pin in multiple locations. BC-2.11.003 and BC-2.11.004 contained similar stale version-pinned citations to living supplement documents. Per project practice, living supplements are updated continuously; body-level version pins become stale immediately on any supplement revision.

**Adjudication (D18-P84-A):** Body citations to living supplements use SECTION ANCHORS ONLY — no version pins. Changelog pins (recording what version was current when a BC was written) remain exempt. Full grep of behavioral-contracts/: zero remaining body-level version pins after this fix.

**Fix (PO — same burst):** BC-2.11.002 → v1.5 (version pins removed from body, section anchors retained). BC-2.11.003 → v1.4. BC-2.11.004 → v1.4.

---

## OBS-P84-C [process-gap] (OPEN — NOT REMEDIATED)

**Target:** purity-boundary-map.md v1.0 — Iron Law module classification completeness

**Finding:** purity-boundary-map.md v1.0 declares an Iron Law: "every module in exactly one column." However, the current file contains unclassified modules that do not appear in any column:
- mcp::server
- memory::write_guard
- memory::skills
- server::stores
- sandbox::policy
- mcp::discovery

These modules ARE in the 35-module universe (several were added via D20 and ADR-013). Their absence from the purity-boundary-map violates the Iron Law that the document itself declares.

**Status:** Architect dispatch was interrupted before remediation. This is the FIRST action on session resume. Remedy: architect classifies ALL unclassified modules per Iron Law against the 35-module universe, with per-column semantics citing relevant BCs/ADRs. Explicit deferred-rows (with justification) are allowed if any module cannot be classified.

---

## Clean Verifications (adversary — this pass)

**Sibling-checks 3/3 PASS:**
1. ADR-013 v1.2 tools/list-vs-call method-name discriminators held: BC-2.09.006 governs tools/list advertisement/discovery; BC-2.09.007 governs tools/call invocation/dispatch. Context paragraph and BC Anchors table both correct. GREEN.
2. interface-definitions v2.27 anchors: ToolCallDialect PC1–PC9+PC10 confirmed; ProviderFallbackPolicy PC1–PC4+PC5 confirmed. Gate #28 currency verified on both files. GREEN.
3. Gate #28 currency on all files touched in recent passes: date-monotonicity and frontmatter-currency checked per Rules 4+5. GREEN.

**Architecture cross-checks (5 sections):** ARCH-INDEX v1.3 section references, module universe arithmetic (35 = 9/13/11/2), ADR cross-citations, subsystem boundary definitions, and VP anchor alignment all verified clean.

**ss-05/ss-06/ss-11 deep read:** Behavioral contract prose, preconditions, error classifications, and test vector rows audited. Found F-P84-01 in ss-11 (and class widened to ss-04/ss-13). ss-05/ss-06 CLEAN.

**Additional probes:** VP axis alignment (5 VPs vs architecture sections); census 85 = 43+16+26; RetryHint 6 divergences (BC-anchored); module-criticality dual-path coherence; CAP-021 mcp::server resolves to ADR-013 (not ADR-012); 10+ TV rows audited during the F-P84-01 sweep.

---

## Novelty Assessment

**MEDIUM.** F-P84-01 is a new finding class: markdown table header row counted as a test vector entry (index-count-header-row-overcount). This is a systematic methodology error affecting multiple subsystems using the "table (unlabelled)" format. The OBS findings are follow-on from the same root probe. D18-P84-A (section-anchor-only canon) codifies a practice that was implicit but unforced.

---

## Trajectory

→1 (P1D-84). Convergence counter: 0/3 (reset by F-P84-01).
