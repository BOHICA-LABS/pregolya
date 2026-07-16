---
document_type: adversarial-review
pass: 75
verdict: NOT CLEAN
finding_count: 1
finding_severity: [HIGH]
novelty: MEDIUM
novelty_class: temporal-integrity-partial-fix-propagation
novelty_notes: "pass-73 burst future-dated 2026-07-19 (temporally impossible — pass-72 and pass-74 artifacts, both 2026-07-15, bracket it). 4-file blast radius: prd.md frontmatter + v1.1 changelog entry, test-vectors.md frontmatter + v1.4 changelog row, bc-authoring-plan.md frontmatter + v2.14 changelog row, BC-INDEX.md frontmatter + v1.3 changelog row. The date INVERSIONS in BC-INDEX (v1.4/v2.15 rows dated 2026-07-15 sat above v1.3/v2.14 rows dated 2026-07-19) directly violated gate #28 sub-check 3 (monotonic, newest-at-top)."
sibling_checks: "5/5 PASS"
timestamp: 2026-07-15T00:00:00Z
phase: 1d
---

# Adversarial Review Pass 75

**Verdict:** NOT CLEAN — 1 HIGH + 2 OBS (1 process-gap addressed, 1 cosmetic deferred).

**Novelty:** MEDIUM — 3rd recurrence of future-dated-changelog class (F-P64-02, F-P65-01, F-P75-01); partially-applied fix left date inversions across 4 files.

---

## Findings

### F-P75-01 (HIGH)

**Location:** 4-file blast radius — prd.md (frontmatter + v1.1 changelog entry), test-vectors.md (frontmatter + v1.4 changelog row), bc-authoring-plan.md (frontmatter + v2.14 changelog row), BC-INDEX.md (frontmatter + v1.3 changelog row)

**Description:** The pass-73 burst (burst 152) future-dated its artifacts to 2026-07-19. This is temporally impossible: the canonical factory burst date is 2026-07-15, and pass-72 artifacts (burst 150) and pass-74 artifacts (burst 153) are both correctly dated 2026-07-15, bracketing the rogue 2026-07-19 stamp. The 4-file blast radius:

1. **prd.md:** frontmatter `timestamp: 2026-07-19T00:00:00Z` (should be 2026-07-15); inline changelog annotation `v1.1 F-P73 (2026-07-19)` (should be 2026-07-15).
2. **test-vectors.md:** frontmatter `timestamp: 2026-07-19T00:00:00Z` (should be 2026-07-15); changelog row `| 1.4 | 2026-07-19 |` (should be 2026-07-15).
3. **bc-authoring-plan.md:** frontmatter `timestamp: 2026-07-19T00:00:00Z` (should be 2026-07-15); changelog row `| 2.14 | 2026-07-19 |` (should be 2026-07-15).
4. **BC-INDEX.md:** frontmatter `timestamp: 2026-07-19T00:00:00Z` (should be 2026-07-15); changelog row `| 1.3 | 2026-07-19 |` (should be 2026-07-15). Critical inversion: v1.4 (2026-07-15) and v2.15 (2026-07-15) rows sat above v1.3 (2026-07-19) and v2.14 (2026-07-19) rows, violating gate #28 sub-check 3 (newest-at-top, non-increasing date sequence).

Gate #28 date-validity FAIL — specifically sub-check 3 (monotonic date ordering) and sub-check 2 (changelog dates ≤ burst date).

**Severity:** HIGH — date inversions in BC-INDEX directly violate gate #28 in a way detectable by any cross-burst comparison (v1.4 row dated 2026-07-15 "is older than" the v1.3 row dated 2026-07-19 per sort order — an inversion that could mislead any tool that trusts changelog date order). All four files have frontmatter timestamps that exceed the canonical burst date, making them non-monotonic with the pass-72 and pass-74 bracketing artifacts.

**Fix (PO):** prd.md, test-vectors.md, bc-authoring-plan.md — correct all 2026-07-19 occurrences to 2026-07-15 in both frontmatter and changelog entries.

**Fix (state-manager):** BC-INDEX.md — correct frontmatter `timestamp: 2026-07-19T00:00:00Z` → `timestamp: 2026-07-15T00:00:00Z`; correct changelog `| 1.3 | 2026-07-19 |` → `| 1.3 | 2026-07-15 |`. Verify monotonicity after fix: v1.4 (2026-07-15) ≥ v1.3 (2026-07-15) ✓.

**FIXED:** All 4 files corrected in same burst (burst 154). Zero 2026-07-19 residue in .factory/specs/ confirmed by post-fix grep. Monotonicity verified per-file. Frontmatter-currency verified (each frontmatter timestamp = newest changelog entry date = 2026-07-15 ✓).

---

## Observations (Non-Defects)

### OBS-P75-A [process-gap], ADDRESSED

**Location:** bc-authoring-plan.md gate #28 definition + manual burst discipline

**Description:** This is the 3rd recurrence of the future-dated-changelog class (F-P64-02: bc-authoring-plan + test-vectors dated 2026-07-16; F-P65-01: BC-2.07.002 body dated 2026-07-16; F-P75-01: four files dated 2026-07-19). The root cause is that gate #28 requires only that the newly added row is correctly dated — it does not mandate a temporal-neighbor sweep of all existing rows in the same file, nor a check that the frontmatter timestamp matches the newest changelog entry.

**Adjudication:** D18-P75-A — gate #28 extended with two new rules:

- **Rule 4 (TEMPORAL-NEIGHBOR SWEEP):** When any file is edited in a fix burst, ALL neighboring changelog rows in that file — not only the newly added row — must be date-audited in the same burst. Pass N dates may not exceed pass N+1 artifact dates. A row whose date exceeds an adjacent pass's canonical date is a gate failure.
- **Rule 5 (FRONTMATTER-CURRENCY):** Each document's frontmatter `timestamp:` must equal the date of the file's newest changelog entry. A frontmatter timestamp that exceeds the current burst date is a self-contradiction.

**Machine enforcement deferral:** Pre-commit hook and CI lint enforcement of Rules 4 and 5 deferred to Phase 3 CI hardening. Logged as DEFER-002 in STATE.md. Until machine enforcement, burst discipline governs — every PO burst touching a changelog file must manually run the date-validity sub-check per updated gate #28.

**Disposition:** bc-authoring-plan → v2.16 (gate #28 Rules 4+5 added; DEFER-002 noted).

---

### OBS-P75-B (cosmetic, DEFERRED)

**Location:** specs/prd-supplements/interface-definitions.md — changelog ordering

**Description:** interface-definitions.md changelog is not uniformly newest-at-top. Only version 2.23 (the most recent entry) honors newest-at-top ordering; historical entries follow oldest-first with local disorder (e.g., 2.4 before 2.3, 2.7 before 2.6, 2.21-2.22 before 2.19-2.20). All 28 entries are present and dates are internally consistent — this is NOT a gate #28 failure (the oldest-at-bottom pattern was consistent before the newest-at-top convention was formalized). Adjudicated deferred-cosmetic, non-resetting.

**Disposition:** DEFERRED — future cosmetic tidy. Do NOT re-report in pass 76.

---

## Clean Verifications

### Sibling Checks (5/5 PASS)

| # | Check | Result |
|---|-------|--------|
| 1 | BC-2.04.008 v1.2: CheckpointSaver::fts_search in Description; changelog newest-at-top | PASS |
| 2 | interface-definitions.md v2.23: line 543 CheckpointSaver::fts_search (corrected from v2.22); E-CHKPT-009 note unchanged | PASS |
| 3 | bc-authoring-plan v2.16: gate #19 pattern includes 5 retired shared-type names; domain-spec/ excluded; AIMessage context note; coverage-closure note; gate #28 Rules 4+5; D18-P75-A noted | PASS |
| 4 | BC-INDEX v1.4: note #5 forward pointer "(later grown to 95 via D20)"; changelog monotonic newest-at-top (v1.4/v1.3/v1.2/v1.1/v1.0 all 2026-07-15 or earlier); frontmatter-currency verified | PASS |
| 5 | gate #19 independent census (post-fix): zero live retired-type-name violations across .factory/specs/ (excluding domain-spec/ mapping tables and audit-trail changelog rows) | PASS |

---

### Census Rotation (7 gates)

| Gate | Check | Result |
|------|-------|--------|
| #12 | Lifecycle-arrows completeness in BCs | PASS |
| #14 | Harness function coverage completeness | PASS |
| #19 | Retired-identifier table enforcement (extended pattern) | PASS — ZERO live violations |
| #25 | Criticality-sibling coverage: arch-view 35 = 9/13/11/2; coverage-matrix 35 rows | PASS |
| #27 | Budget-split rule + core/budget carve-out + positive assertion | PASS |
| #28 | Date-validity across supplement changelogs (including Rules 4+5) | FAIL → F-P75-01 (fixed same burst) |
| #30 | Forward traceability: taxonomy codes → BC anchor | PASS |

---

### Free Probes

- **NFR-catalog currency:** NFR-003 Kani targets 3/3 entries match VP-INDEX Kani VPs (VP-001/002/003). CLEAN.
- **Frontmatter-vs-newest-changelog cross-cut (new probe):** All four files in F-P75-01 blast radius confirmed: frontmatter timestamp = newest changelog entry date post-fix. → F-P75-01 (this probe identified the inversion pattern).
- **Changelog ordering probe:** interface-definitions.md historical disorder → OBS-P75-B (deferred-cosmetic, non-resetting).
- **VP-INDEX ↔ architecture coherence:** 5 VPs (VP-001–003 Kani P0, VP-004–005 integration P1) consistent across VP-INDEX, BC-INDEX, and prd.md. CLEAN.
- **Baselines confirmed:** 95 BCs = 48/39/8 (P2 enumerated: BC-2.09.007/BC-2.17.002/BC-2.07.002/BC-2.04.006/BC-2.13.001/BC-2.03.001/BC-2.14.001/2); census 85 = 43+16+26; 6 RetryHint divergences; gate #31 24/28.

---

## IMPORTANT Baseline Correction (gate-count citation)

The bc-authoring-plan frontmatter reads `total_standing_gates: 33` (gates numbered 1–33). STATE.md's prior citations "41 gates" / "41 standing gates" / "Gates 41" were STALE state-manager entries — they were never accurate (the plan's frontmatter always said 33). Every "41 gates" / "41 standing gates" / "Gates 41" reference in STATE.md live sections has been corrected to 33 in this burst. Historical pass-report rows in cycle files (which recorded "Gates 41" at the time of each pass) are immutable audit trail and remain unchanged.

---

## Novelty Assessment

**MEDIUM** — Temporal-integrity class; third recurrence. Two novelty sub-classes: (1) partial-fix propagation failure (burst 152 corrected content correctly but did not date-sweep ALL files touched in same burst); (2) date-inversion exposure (later-versioned rows above earlier-versioned rows with higher dates). Gate #28 Rules 4+5 address both sub-classes for future bursts.

**Trajectory:** →1 (P1D-75). Convergence counter 0/3.
