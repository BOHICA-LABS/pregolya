---
document_type: adversarial-review-pass
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T00:00:00Z
cycle: v1.0.0-greenfield
pass: 89
burst: 171
phase: 1d
clean_strict: false
clean_pr_merge: false
finding_count: 4
finding_severity: "1 HIGH [process-gap] + 2 MED + 1 LOW"
novelty: MEDIUM
counter_before: 0
counter_after: 0
traces_to: STATE.md
---

# Adversarial Review — Pass 89 (Burst 171)

**Date:** 2026-07-17
**Pass:** P1D-89
**Verdict:** NOT CLEAN (strict) | NOT CLEAN (PR-merge)
**Finding count:** 4 (1 HIGH [process-gap] + 2 MED + 1 LOW)
**Novelty:** MEDIUM — all findings = propagation echo of bursts 168-170 provenance wave; substantive axes verified clean
**Convergence counter:** 0/3 (reset by 1 HIGH + 2 MED findings)

## Axes Rotated

- Gate #34 INPUT-HASH FORMAT CONSISTENCY census block audit (F-P89-01): embedded per-file hash values in gate text body
- bc-authoring-plan frontmatter hash chain verification: F-P89-02 (hash e786fea vs changelog e238778)
- nfr-catalog deferral language + hash currency audit: F-P89-03
- BC-2.08.006 SS-TBD clause sweep (class sweep from F-P88-04): F-P89-04
- D18-P88-A full-tree inputs: sweep: PASS (30-file closure verified)
- Error-code census 85 = 43+16+26: PASS
- Retired-name sweeps: PASS
- VP-INDEX arithmetic: PASS
- Verification-architecture v1.3 (hash 8091abc, six-BC inputs): PASS
- Hedge sweep: PASS
- Gate #28 scoped on all 07-17 files: PASS

## Findings

### F-P89-01 (HIGH [process-gap]) — Gate #34 Census Block Embeds Stale Per-File Hash Values

**Severity:** HIGH [process-gap]
**Owner:** PO
**Gate triggered:** Gate #34 (INPUT-HASH FORMAT CONSISTENCY)

**Finding:** The gate #34 census block in bc-authoring-plan recorded specific per-file hash values inline in the gate text body (e.g., `error-taxonomy: f766c52`). These values were stale after the bursts 168-170 wave. More critically, recording per-file hashes IN the gate text body creates a structural false-PASS class: the gate text asserts currency for files where the actual frontmatter hashes disagree.

**Structural fix:** Per-file hash values MUST NEVER be recorded in gate text. Gate #34 records only: census date, total count (e.g., "95/95 MATCH"), and explicitly non-authoritative date+count snapshots. The frontmatter `input-hash:` field is the single source of truth. Rule encoded in bc-authoring-plan → v2.25.

**Class sweep:** No other gate text in bc-authoring-plan records per-file hash values. Zero corpus-wide hash-in-gate-text residue.

**Status:** FIXED — bc-authoring-plan v2.25

---

### F-P89-02 (MED) — bc-authoring-plan Frontmatter Hash Chain Break

**Severity:** MED
**Owner:** PO
**Gate triggered:** Gate #34 (input-hash currency)

**Finding:** bc-authoring-plan frontmatter `input-hash: e786fea` did not match the hash that would be computed from the v2.24 inputs as recorded in the v2.24 changelog (e238778). The full chain: 90d28fa (pre-burst-168) → e238778 (burst 168, v2.24 changelog) → e786fea (burst 169, hash-only migration recorded) → 41c29d9 (current, recomputed post burst-170).

**Fix:** Full chain documented in bc-authoring-plan changelog. Frontmatter updated to 41c29d9 (recomputed against current inputs).

**Status:** FIXED

---

### F-P89-03 (MED) — nfr-catalog Deferral Language + Stale Pre-Removal Hash

**Severity:** MED
**Owner:** PO
**Gate triggered:** Gate #28 (FRONTMATTER-CURRENCY) + Gate #34 (input-hash currency)

**Finding:** nfr-catalog v1.1 changelog entry for the burst-169 hash-only migration contained "pending recomputation" deferral language — a production-grade violation (deferral forbidden when the work is doable in scope). The stored `input-hash: 2153125` was also stale against current inputs.

**Fix:** nfr-catalog → v1.2. Deferral language closed. The v1.1 changelog row preserved as audit trail (deferral annotation only). Hash: 2153125 → 0f05a12.

**Status:** FIXED

---

### F-P89-04 (LOW) — BC-2.08.006 Precondition 3 Stale SS-TBD Clause

**Severity:** LOW
**Owner:** PO
**Gate triggered:** Gate #28 (SS-TBD present-tense / historical-form sweep, class from F-P88-04)

**Finding:** BC-2.08.006 Precondition 3 still contained "(or SS-TBD is used as a placeholder)" — a live reference to the retired SS-TBD placeholder declared resolved at burst 168 (bc-authoring-plan v2.23 F-P88-04). BC-2.08.006 was not swept at that burst.

**Fix:** BC-2.08.006 → v1.2. Stale clause removed. Hash: 8095694 → 412902d.

**Class sweep:** No other BC contains live "(or SS-TBD" prose. Zero corpus-wide SS-TBD live references (changelog/audit-trail rows exempt per Gate #28).

**Status:** FIXED

---

## Gate Rotation Summary

| Gate | Verdict | Notes |
|------|---------|-------|
| #12 (input-hash census) | PASS | All 6 supplements + 95 BCs at 7-char MD5 |
| #28 (date monotonicity + currency) | PASS post-fix | F-P89-03 nfr-catalog; F-P89-04 SS-TBD clause sweep |
| #34 (input-hash format consistency) | PASS post-fix | F-P89-01 structural no-values rule; F-P89-02/03 hash refresh |
| D18-P88-A inputs: sweep | PASS | 30-file closure bursts 169-170 verified intact |
| Error-code census 85 | PASS | 85 = 43+16+26 MATCH; no changes |
| Retired-name sweeps | PASS | No Python class names, no SS-TBD live references |
| VP-INDEX arithmetic | PASS | VP-001–005; 5 entries match |
| Verification-architecture v1.3 | PASS | Hash 8091abc; six-BC inputs intact |
| Hedge sweep | PASS | No unquantified hedges |
| Gate #28 (all 07-17 files) | PASS | All supplement timestamps/changelogs date-valid |

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | P1D-89 |
| **Novelty score** | MEDIUM |
| **Trajectory** | →4 (P1D-89); cumulative tail →2→2→4→4 |
| **Verdict** | FINDINGS_REMAIN |

All 4 findings are propagation echoes of the bursts 168-170 provenance wave: the wave updated primary fields but did not propagate hash/language updates to all sibling files. F-P89-01 is MEDIUM novelty (the embedded-hash structural class was previously ungated); F-P89-02/03/04 are LOW novelty (same propagation failure class as F-P88-01). No new spec-content defects or spec logic gaps discovered. Post-sweep (D18-P89-A first execution) leaves corpus at TOTAL MATCH.

## Convergence Assessment

**CLEAN (strict):** no — 1 HIGH [process-gap] + 2 MED findings prevent strict-clean
**CLEAN (PR-merge):** no — HIGH finding present (even with [process-gap] annotation, severity = HIGH)
**Streak:** 0/3 (reset)
**Trajectory:** →4 (P1D-89); cumulative tail →2→2→4→4
**Next action:** dispatch adversary pass 90; PASS-90 sibling-checks: bc-authoring-plan v2.25 (gate #34 no-values rule + snapshot form), nfr-catalog v1.2, BC-2.08.006 v1.2, corpus-wide hash census TOTAL MATCH (post-sweep), D18-P89-A standing-step first execution verified
