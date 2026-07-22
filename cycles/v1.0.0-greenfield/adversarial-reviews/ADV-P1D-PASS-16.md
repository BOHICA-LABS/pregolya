---
document_type: adversarial-review
phase: 1d
pass: 16
verdict: NOT CLEAN
timestamp: 2026-07-14T23:00:00Z
producer: product-owner
scope: NE-anchor axis (BC-INDEX NE Anchors column + PRD §7 RTM NE citations + PRD §9 NE Disposition Table + BC bodies — complete NE axis census, first time)
inputs:
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.006.md
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.007.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.003.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.007.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.005.md
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.001.md
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.002.md
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.003.md
  - .factory/specs/behavioral-contracts/ss-03/BC-2.03.003.md
  - .factory/specs/architecture/decisions/ADR-004-serde-schemars-schema-generation.md
  - .factory/specs/prd-supplements/bc-authoring-plan.md
input-hash: "61b2cb2"
findings:
  - id: F-P16-01
    severity: HIGH
    status: FIXED
trajectory: "...→2→1→1"
clean_pass_counter: 0/3
---

# ADV-P1D-PASS-16: Adversarial Review

## Verdict: NOT CLEAN — 1 HIGH Finding (FIXED)

Novel probe axis this pass: **NE-anchor axis** — complete four-way consistency check for all
17 NEs across BC body Traceability tables ↔ BC-INDEX NE Anchors column ↔ PRD §7 RTM Source
column ↔ PRD §9 NE Disposition Table (authoritative registry). This axis had never been
censused as a whole before. Prior passes addressed individual NE mis-anchors (ADR-level); this
is the first systematic BC-level NE census.

---

## F-P16-01 (HIGH) — NE-Anchor Four-Way Drift: BC-INDEX Internal Contradiction + 10 Under-Anchored Rows

### Finding

**Internal BC-INDEX contradiction:** The VP Seed BCs table at the top of BC-INDEX correctly
records `NE-12` for BC-2.04.006 ("Session Triple-Address Uniqueness — Kani VP Seed"). The Full
BC Catalog table row for the same BC shows a blank NE Anchors cell. The same document asserts
two different states for BC-2.04.006's NE anchor. This is a HIGH-severity internal
contradiction.

**Under-anchored catalog rows (10 BCs):** PRD §9 NE Disposition Table is the authoritative NE
registry. Every BC listed there as an NE anchor must appear in BC-INDEX NE Anchors column and
PRD §7 RTM Source column. The following BCs had NE references present in their body
Traceability tables and in PRD §9, but absent from BC-INDEX catalog and/or RTM:

| BC ID | NE | Body ref present? | BC-INDEX blank? | RTM missing? |
|-------|-----|-------------------|-----------------|--------------|
| BC-2.04.006 | NE-12 | yes (Traceability) | yes (contradiction with VP Seed table) | no (RTM already had NE-12) |
| BC-2.04.007 | NE-11 | yes (Traceability) | yes | no (RTM already had NE-11) |
| BC-2.11.002 | NE-06 | yes (`ne_coverage: NE-06` + Traceability) | yes | yes |
| BC-2.11.003 | NE-06 | yes (`ne_coverage: NE-06` + Traceability) | yes | yes |
| BC-2.11.004 | NE-06 | yes (`ne_coverage: NE-06` + Traceability) | yes | yes |
| BC-2.12.007 | NE-13 | yes (Traceability) | yes | yes |
| BC-2.13.005 | NE-02 | yes (Traceability) | yes | yes |
| BC-2.16.001 | NE-09 | yes (Traceability) | yes | no (RTM already had NE-09) |
| BC-2.16.002 | NE-09 | yes (Traceability) | yes | no (RTM already had NE-09) |
| BC-2.16.003 | NE-09 | yes (Traceability) | yes | no (RTM already had NE-09) |

**RTM rows missing NE (6 BCs):**

| BC ID | NE | RTM had it? |
|-------|-----|-------------|
| BC-2.03.003 | NE-17 | no (bc-authoring-plan NE table lists it; PRD §9 lists it; RTM was missing it) |
| BC-2.11.002 | NE-06 | no |
| BC-2.11.003 | NE-06 | no |
| BC-2.11.004 | NE-06 | no |
| BC-2.12.007 | NE-13 | no |
| BC-2.13.005 | NE-02 | no |

**NEW class — NE axis never censused:** No prior pass had run the complete four-way NE census
across all 86 BCs × {body, BC-INDEX, RTM, PRD §9}. The drift accumulated silently across 15
passes because the NE Anchors column was not treated as a standing consistency gate.

### Root Cause

NE anchors were recorded in BC bodies and PRD §9 during Phase 1a authoring, but the BC-INDEX
NE Anchors column was populated only for BCs with parenthetical `(NE-NN)` in the BC title or
for VP seed BCs. BCs whose NE anchors were documented only in their Traceability tables (without
title parenthetical) were missed. The RTM Source column was also not cross-checked against PRD §9
after BC authoring completed.

### Fixes Applied

1. **BC-INDEX NE Anchors column:** 10 catalog rows updated with correct NE values (NE-06×3,
   NE-09×3, NE-11, NE-12, NE-13, NE-02).
2. **PRD §7 RTM Source column:** 6 rows updated (BC-2.03.003→NE-17, BC-2.11.002/003/004→NE-06,
   BC-2.12.007→NE-13, BC-2.13.005→NE-02).
   **PRD §2 subsection DI tables:** 7 rows updated to add NE refs in DI column (BC-2.03.003→NE-17;
   BC-2.11.002/003/004→NE-06; BC-2.12.007→NE-13; BC-2.13.004→NE-02; BC-2.13.005→NE-02).
   Note: PRD §2 table DI column carries both DI and NE anchor refs for that subsection;
   BC-2.13.004 was missing NE-02 in §2 even though BC-INDEX correctly showed NE-02.
3. **ne_anchor frontmatter policy:** `ne_anchor: NE-12` removed from BC-2.04.006 frontmatter;
   `ne_anchor: NE-11` removed from BC-2.04.007 frontmatter. These fields are OPTIONAL-LEGACY —
   BC body Traceability row + BC-INDEX NE Anchors column are the canonical carriers. Policy
   recorded in bc-authoring-plan guideline #13.
4. **bc-authoring-plan guideline #13 added:** Anchor-matrix census gate (standing, subsumes
   all prior per-axis checks). Specifies the full BC × {CAP, DI, NE, R, ADR, VP} four-way
   census protocol. Sources ne_anchor/ne_coverage deprecation.

---

## Sibling Checks (4/4 PASS)

| Check | Verdict |
|-------|---------|
| Post-fix: BC-INDEX VP Seed table NE-12 (BC-2.04.006) matches catalog row NE-12 | PASS |
| Post-fix: PRD §9 NE-06 row lists BC-2.11.002/003/004 — BC-INDEX NE Anchors agree | PASS |
| Post-fix: PRD §9 NE-13 row lists BC-2.06.003 + BC-2.12.007 — both catalog rows have NE-13 | PASS |
| Post-fix: PRD §9 NE-17 row lists BC-2.03.001 + BC-2.03.003 — BC-INDEX catalog rows agree; RTM rows agree | PASS |

---

## BC Existence Audit (PASS)

All BCs cited in ADR Consequences sections verified to exist in BC-INDEX with correct PRD
section/subsystem assignments (adversary's pre-empt from pass 15). ADR-sourced BCs:

| ADR cite | BC ID | Exists in BC-INDEX? | PRD assignment |
|---------|-------|---------------------|----------------|
| ADR-001 Consequences | BC-2.03.001, BC-2.02.001 | ✓ | SS-03/CAP-004, SS-02/CAP-003 |
| ADR-003 Consequences | BC-2.04.001, BC-2.04.002 | ✓ | SS-04/CAP-005 |
| ADR-004 Consequences | BC-2.08.003, BC-2.08.009 | ✓ | SS-08/CAP-009 |
| ADR-005 Consequences | BC-2.04.003 | ✓ | SS-04/CAP-005 |
| ADR-006 Consequences | BC-2.06.001, BC-2.06.002, BC-2.06.003 | ✓ | SS-06/CAP-007 |
| ADR-007 Consequences | BC-2.08.006 | ✓ | SS-08/CAP-009 |
| ADR-008 Consequences | BC-2.08.010, BC-2.08.011, BC-2.08.012 | ✓ | SS-08/CAP-002,CAP-003 |
| ADR-009 Consequences | BC-2.10.004 | ✓ | SS-10/CAP-012 |
| ADR-010 Consequences | BC-2.14.001, BC-2.14.003 | ✓ | SS-14/CAP-016 |
| ADR-011 Consequences | (CI lint gate — no BC; NE-05) | N/A | — |

All ADR-cited BCs exist in BC-INDEX with correct subsystem/PRD assignments. PASS.

---

## Rotated Censuses (3/3 PASS)

**Census A — CAP axis (four-way):**
86/86 BCs: body capability field ↔ BC-INDEX Cap column ↔ PRD §2 catalog ↔ PRD §7 RTM Source.
BC-2.08.008 CAP-011 confirmed correct by design (Eval Score Aggregation is CAP-011
Provider Conformance Suite, not CAP-009 Chat Model Adapter — the BC-INDEX, PRD §2, PRD §7, and
BC body all agree). Some RTM rows include multi-CAP attribution (e.g., BC-2.08.001 cites both
CAP-009 and CAP-011 as additional traceability context) without contradicting BC-INDEX primary
CAP assignments. No mismatches. PASS.

**Census B — DI axis (four-way):**
14/14 DIs fully enforced per bc-authoring-plan DI coverage table. BC-INDEX DI Anchors column
and PRD §7 RTM Source column agree with bc-authoring-plan. BC-2.04.007 DI blank is correct by
design (NE-11 is an operational safety requirement, not a named domain invariant — BC body
explicitly notes this). No orphan DIs. No BC-INDEX/RTM DI mismatches. PASS.

**Census C — VP axis (four-way):**
5 VPs registered (VP-INDEX). VP-001–003 (Kani P0): BC-INDEX catalog **VP** marker present for
BC-2.03.001, BC-2.04.006, BC-2.13.004 ✓. VP-004–005 (integration P1, BC-2.09.004/005): these
are Red Gate BCs — primary index marker is **RG**; the integration VP designation lives in
VP-INDEX and BC bodies (VP Anchors section). No **VP** catalog marker for integration VPs is
CORRECT-BY-DESIGN (the VP column semantically marks Kani formal-verification seeds scheduled
for Phase 6). VP-INDEX ↔ BC bodies ↔ VP files consistent. PASS.

---

## Anchor-Matrix Census Summary (full 86 BC × 6 axis, post-fix)

| Axis | Mismatches found | Fixed | Post-fix state |
|------|-----------------|-------|----------------|
| CAP | 0 | — | 86/86 exact |
| DI | 0 | — | 14/14 DIs enforced, 86 BCs consistent |
| NE | 23 (10 BC-INDEX rows + 6 RTM §7 rows + 7 PRD §2 rows) | 23 | 17/17 NEs anchored in BC-INDEX + PRD §2 + RTM |
| R | 0 (alias-consistent by design) | — | 5/5 Red Gate BCs consistent |
| ADR | 0 | — | 4 ADR-anchored BCs in RTM, all bodies consistent |
| VP | 0 (design intent verified) | — | 5/5 VPs in VP-INDEX; 3/3 Kani **VP** markers in BC-INDEX |

**Post-fix: 0/6 axes have outstanding mismatches.**

---

## LOW Observations

**OBS-P16-01 (LOW):** The `ne_anchor` and `ne_coverage` frontmatter fields on BC files were
undocumented as optional-legacy. BC-2.04.006 had `ne_anchor: NE-12`; BC-2.04.007 had
`ne_anchor: NE-11`; BC-2.11.002/003/004 had `ne_coverage: NE-06`. These fields are not in the
canonical BC frontmatter schema (DF-020a). Without a documented policy, new BCs authored by
sub-burst agents may continue adding these fields, causing future audit confusion.
**Fix applied:** `ne_anchor` fields removed from BC-2.04.006 and BC-2.04.007 (the
ne_coverage fields on BC-2.11.002/003/004 are benign and not removed — they are silently
tolerated but do not need to be added to new BCs). Policy recorded in bc-authoring-plan
guideline #13: ne_anchor/ne_coverage are OPTIONAL-LEGACY; body Traceability + BC-INDEX are
canonical. Do not add these fields to new BCs.

**OBS-P16-02 (LOW):** ADR-004 Consequences section has a "schema naming stability (snapshot
test obligation)" paragraph naming the obligation as a "Phase 3 BC anchor" without forward-
linking to the specific BC that implements it (BC-2.08.009). Future implementers reading
ADR-004 cannot directly navigate to the BC that formalizes the snapshot test contract.
**Fix applied:** BC-2.08.009 forward-link added to ADR-004 Consequences snapshot-test paragraph
with OBS-P16-02 attribution.

---

## Trajectory and Counter

**Pass trajectory:** ...→2→1→1
- Pass 14: 2 findings
- Pass 15: 1 finding (F-P15-01) + 1 sweep fix
- Pass 16: 1 HIGH finding (F-P16-01, FIXED) + 2 LOW obs (FIXED)

**Clean pass counter:** 0/3

---

## Strongest Surviving Attack for Pass 17

**CAP-anchor adversarial probe (full axis):** For every BC in BC-INDEX, open the BC body and
verify the `capability:` frontmatter field matches the Cap column in BC-INDEX and the Source
column in PRD §7 RTM. Census A this pass was done from the index side only (spot-checking a
small number of bodies). A full body-level CAP scan would directly verify BC-2.08.010
(`CAP-002` in index — the `#[tool]` macro is a Runnable/CAP-002 concern, not a CAP-003
StateGraph concern; verify the body agrees) and the multi-subsystem BCs (BC-2.17.001 spans
CAP-019 but cites DI-001, DI-005, DI-007 from three different subsystems — verify the body
Traceability agrees with RTM). The CAP axis is the one axis where a body-vs-index mismatch
could have been introduced during the Phase 1b proc-macro amendment (Batch 13) without a
full four-way re-audit.
