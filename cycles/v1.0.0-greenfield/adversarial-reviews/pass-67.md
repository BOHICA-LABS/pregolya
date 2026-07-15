---
document_type: adversarial-review-pass
phase: 1d
pass: 67
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 1
low_count: 0
observations_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "→ Cross-row routing-enumeration completeness lens — inter-row enumerations in the HTTP status table diffed against target-row contents; 1 stale 5-code set found; 10 passes survived undetected"
timestamp: 2026-07-15T00:00:00Z
novelty: MEDIUM
new_class: "stale inter-row routing enumeration (introduced v2.11 / pass-56-completion; gate #21 §17-C code→row MEMBERSHIP checks do not cover inter-row enumeration completeness)"
routing: "F-P67-01 → product-owner (422 row enumeration + gate #21 sub-check)"
sibling_checks:
  - "SC-1 tombstone/re-anchor (pass-66 fixes) PASS"
  - "SC-2 disposition census EXACT 78 = 44+11+23 PASS (independently recomputed)"
  - "SC-3 BC-2.04.005 EC-006 + BC-2.09.001 EC-006/TV-008 coherent PASS"
  - "SC-4 gate #33 full re-run 78/78 zero orphans raise-conditions verified PASS"
censuses:
  - "#33 78/78 PASS"
  - "#23-A URL-scheme PASS"
  - "#12 lifecycle 15 hits PASS"
  - "#18 shared-type PASS"
  - "#19 retired PASS"
  - "#16 collision spot PASS"
  - "#30 codeless PASS"
free_probes:
  - "cross-row routing-enumeration completeness (NEW) → F-P67-01"
  - "post-re-anchor orphan check on vacated BC-2.09.005 (NEW) CLEAN"
  - "RetryHint coherence of the 3 mints (NEW) CLEAN"
---

# Adversarial Review Pass 67 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (0 HIGH, 1 MED, 0 LOW). Counter reset: 0/3 consecutive clean. Novelty: MEDIUM.

---

## F-P67-01 [MED] — 422 Row Cross-Reference Enumeration Omits E-CHKPT-007 (Contradicts 500 Row)

**Finding class:** Stale inter-row routing enumeration — the 422 row's definitive "(E-CHKPT-001, -002, -003, -004, -006) go to the 500 row" enumeration omits E-CHKPT-007 (CipherHeaderMissing, INTERNAL), which IS in the 500 row.

**Scope:**
- `interface-definitions.md` §HTTP Status Codes, 422 row (line 372): definitive cross-reference enumeration of DURABILITY/INTERNAL E-CHKPT codes routed to the 500 row
- `interface-definitions.md` §HTTP Status Codes, 500 row (line 374): live code list includes E-CHKPT-007

**Finding:** The 422 row contains the following routing note:

> "DURABILITY/INTERNAL E-CHKPT codes (E-CHKPT-001, -002, -003, -004, -006) go to the 500 row"

The 500 row's actual CHKPT code set is: E-CHKPT-001, E-CHKPT-002, E-CHKPT-003, E-CHKPT-004, E-CHKPT-006, **E-CHKPT-007**.

E-CHKPT-007 (CipherHeaderMissing, INTERNAL — unencrypted legacy blob read in encrypted store; BC-2.04.007 EC-004) was added to the 500 row at v2.11 (ADV-P1D-PASS-56-COMPLETION) without updating the 422 row's sibling enumeration. The enumeration uses definitive (non-"e.g.") phrasing and contains an explicit E-CHKPT-005 carve-out, which means a reader receives a 5-code set that contradicts the 500 row's 6-code set.

**Severity justification (MED):** The phrasing is definitive, not hedged with "e.g." — a reader following the 422 row's enumeration as an exhaustive list would expect only 5 CHKPT codes in the 500 row. The 500 row is authoritative and correct; the 422 row cross-reference is stale. No behavioral contract or test is affected (the 500 row already has E-CHKPT-007 correctly placed); the harm is reader confusion and incomplete routing documentation.

**Root cause:** Gate #21 (§17-C census) checks whether each code appears in the correct row (code→row MEMBERSHIP). It does not check whether inter-row routing enumerations in one row correctly enumerate all codes in the target row. The gap opened when E-CHKPT-007 was added to the 500 row in v2.11 and the 422 row's cross-reference was not updated.

**Introduced:** v2.11 (ADV-P1D-PASS-56-COMPLETION). Survived 10 passes (P57–P66). Gate #21's §17-C census checks code→row MEMBERSHIP, not inter-row routing enumeration completeness.

**Adjudication:** Fix 422 row enumeration: "(E-CHKPT-001, -002, -003, -004, -006)" → "(E-CHKPT-001, -002, -003, -004, -006, -007)". Add cross-row routing-enumeration completeness sub-check to gate #21.

**Fix route:** Product-owner (prd-supplements scope).

---

## OBS-P67-1 [process-gap] — Gate #21 Lacks Cross-Row Routing-Enumeration Completeness Sub-Check

**Observation:** Gate #21 (bc-authoring-plan.md) currently defines a §17-C census re-run trigger for code→row membership. It does not define a sub-check for inter-row routing enumeration completeness (i.e., when row A says "codes X, Y, Z go to row B," that enumeration must be kept in sync with row B's actual contents).

**Recommendation:** Widen gate #21 with a cross-row routing-enumeration completeness sub-check: extract all inter-row enumerations, diff against target-row contents, fix any discrepancy in the same burst.

**Motivating instance:** F-P67-01 (above).

---

## Sibling Checks (All Pass)

1. **SC-1 — Tombstone + re-anchor (pass-66 fixes):** E-SERVER-005 tombstone in error-taxonomy.md v1.9 confirmed present; BC-2.09.001 EC-006/TV-008 re-anchor confirmed correct. PASS.
2. **SC-2 — Disposition census EXACT 78 = 44+11+23:** Independently recomputed per-status breakdown: 44 HTTP table rows + 11 individual omission notes + 23 blanket library-layer coverage = 78. No uncovered codes. PASS.
3. **SC-3 — BC-2.04.005 EC-006 + BC-2.09.001 EC-006/TV-008 coherence:** Both EC-006 entries and the TV-008 vector in BC-2.09.001 are internally consistent with the E-CHKPT-003 and E-MCP-003 re-anchoring applied in pass-66. PASS.
4. **SC-4 — Gate #33 full re-run 78/78, zero orphans, raise-conditions verified:** All 78 live codes have a declared raise condition. Zero orphan codes. PASS.

## Censuses (All Pass)

| Census | Result |
|--------|--------|
| #33 — disposition completeness | 78/78 PASS |
| #23-A — URL-scheme | PASS |
| #12 — lifecycle 15 hits | PASS |
| #18 — shared-type | PASS |
| #19 — retired identifiers | PASS |
| #16 — collision spot-check | PASS |
| #30 — codeless rows | PASS |

## Free Probes

| Probe | Result |
|-------|--------|
| Cross-row routing-enumeration completeness (NEW) | F-P67-01 (422 row omits E-CHKPT-007) |
| Post-re-anchor orphan check on vacated BC-2.09.005 (NEW) | CLEAN — no dangling references |
| RetryHint coherence of the 3 mints (NEW) | CLEAN — all 3 mints have consistent RetryHint values |

---

## Proposed Decisions Log Entry

**D18-P67-A:** Gate #21 widened with cross-row routing-enumeration completeness sub-check per OBS-P67-1. Any code added to or removed from a status row now requires an in-burst sweep of all other rows' "go to the X row" / "see the Y row" enumerations that reference the modified row, diffing inline enumerations against target-row contents and fixing discrepancies before burst close. Motivating instance: F-P67-01 — E-CHKPT-007 added to 500 row at v2.11 without updating 422 row's 5-code CHKPT cross-reference enumeration; gap survived 10 passes. Source: bc-authoring-plan.md v2.8, gate #21 sub-check.
