---
document_type: adversarial-review
level: ops
pass_id: P1D-188
pass_label: FULL-PERIMETER
frozen_head: 3a1bf42
date: 2026-08-16
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-16T23:50:00Z"
phase: 1
pass: 188
previous_review: pass-187.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-188 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** 2 findings (1 MED + 1 LOW). CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak RESET 1/3 → 0/3 (findings found; D-160). Frozen HEAD: factory-artifacts `3a1bf42`. This is pass #189 total.

## Finding ID Convention

Finding IDs use the format: `F-P188-NN` (project-local shorthand). Canonical format per template: `ADV-P1CONV-P188-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-188 FULL-PERIMETER |
| Frozen HEAD | `3a1bf42` (spec content frozen at `3a1bf42`) |
| Date | 2026-08-16 |
| Pass total | 189 passes total in project history |
| Method | FULL-PERIMETER. Deep-read axis: BC-2.05.001-004 (SS-05 HITL shards), BC-2.19.001/002/003 (SS-19 Reviver shards), BC-2.14.001/003 (SS-14 Component/Category), BC-2.08.004/013/014 (SS-08 PROV shards), BC-2.20.001 (SS-20), BC-2.21.002 (SS-21), BC-2.10.005 (SS-10 watermark), BC-2.18.001 (SS-18). 17 BC bodies deep-read. 3 discard candidates (SS-14); 2 findings confirmed. STREAK RESET. |
| Scope | SS-05 BCs 001-004; SS-19 BCs 001/002/003; SS-14 BCs 001/003; SS-08 BCs 004/013/014; SS-20 BC-001; SS-21 BC-002; SS-10 BC-005; SS-18 BC-001. Title-swept only: remaining 112 BCs. Not body-read this pass: SS-09/12/13/15/16/23 bodies + ADR bodies (machine-gated). |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — RESET (1/3 → 0/3; findings found; D-160)** |

## Part A — Fix Verification

burst-295 → P1D-187 CLEAN(strict) verified sound in P1D-187. No prior open findings entering P1D-188.

| Prior Finding | Status | Evidence |
|---------------|--------|---------|
| *(no open findings from prior pass — P1D-187 was CLEAN)* | N/A | N/A |

## Part B — New Findings

**2 findings: 0 CRITICAL + 0 HIGH + 1 MED + 1 LOW.**

### CRITICAL
*(none)*

### HIGH
*(none)*

### MEDIUM

**F-P188-01 (MED): BC-2.19.003 Traceability DI-008 cell attributes Result return to Reviver::new() — contradicts PC2, VP-007, and verification-architecture.**

- **Location:** BC-2.19.003 Traceability §L2-Domain-Invariants DI-008 cell (approximately line 146).
- **Finding:** The DI-008 cell reads "Reviver::new() returns Result; no panic on registry initialization." This directly contradicts:
  1. BC-2.19.003 own PC2 (approximately line 71): `Reviver::new()` returns a `Reviver` value, infallible — no `Result` wrapper.
  2. VP-007 (lines 146, 161, 178) and verification-architecture line 460: both bind `let reviver = Reviver::new();` with no unwrap or `?` — the binding would be build-breaking if `Reviver::new()` returned a `Result`.
  3. Sibling BCs BC-2.19.004, BC-2.19.005, BC-2.19.006 all correctly attribute `Result` to the fallible `revive` operation (their DI-008 cells reference the `revive` method, not the constructor).
- **Root cause:** Sibling-drift propagation — the DI-008 cell text conflates the constructor (infallible) with the operation (fallible `revive`). This is the same propagation/sibling-drift class as F-185-01.
- **Impact:** MED. The cell text is normatively incorrect and could mislead implementers into wrapping `Reviver::new()` in `?` or `unwrap()`, triggering a compile error (and violating BC-5.39.001 Red Gate discipline).
- **Route:** product-owner.
- **Fix:** DI-008 Traceability cell in BC-2.19.003 → "revive returns Result; Reviver::new() is infallible; no panic on registry initialization." (Matches sibling pattern in BC-2.19.004/005/006.)

### LOW

**F-P188-02 (LOW): BC-2.08.014 Traceability "Error Code Minted" row and intro callout omit E-PROV-011.**

- **Location:** BC-2.08.014 intro callout (approximately lines 53-55) and Traceability "Error Code Minted" row (approximately line 199).
- **Finding:** BC-2.08.014 mints error code `E-PROV-011` (`FallbackChainEmpty`) — the code appears in the BC body (Invariant, EC-006, TV-007) and is the sole taxonomy anchor for this code per error-taxonomy line 214. However, the intro callout block (which summarizes minted error codes) and the Traceability §Error-Code-Minted row list only `E-PROV-010`, omitting `E-PROV-011`.
- **Root cause:** Incomplete update when E-PROV-011 was introduced — the body was updated but the summary callout and Traceability row were not synchronized. Standard Error-Code-Minted completeness drift.
- **Impact:** LOW. The code is anchored in the body; the omission only affects discoverability via the callout/Traceability row, not normative correctness.
- **Route:** product-owner.
- **Fix:** Add `E-PROV-011` to the "Error Code Minted" Traceability row and the intro callout (alongside `E-PROV-010`).

### PROCESS-GAP
*(none)*

## Part C — Observations (non-blocking)

*(none)*

## Discards (candidates raised, verified-not-finding)

| Candidate | Disposition |
|-----------|-------------|
| SS-14 BC-2.14.001 Component enum count — candidate: api-surface gate checks for 18 variants vs body text 17+Custom | FALSE — Component enum has 17 named variants + the `Custom(String)` open-ended variant; api-surface gate counts `Custom` as the 18th slot; body text "17+Custom" and gate "18" are consistent representations of the same definition; no contradiction |
| SS-14 BC-2.14.001 EC-002/EC-004 error notation — candidate: EC-002/EC-004 illustrative examples use slightly different notation than canonical Class-3 | FALSE — EC-002/EC-004 are explicitly marked illustrative; the canonical notation standard applies to normative error-code bodies, not illustrative examples; no violation |
| SS-14 BC-2.14.003 TV-001 field `<hash>` — candidate: hash field described as a digest type but typed as string | FALSE — `<hash>` is a placeholder angle-bracket token (per TD-VSDD-091 canonical form), not a type assertion; the BC body uses angle-bracket placeholders for variable content consistently; not a type contradiction |

## Balance Verified-CLEAN

| Axis | Result |
|------|--------|
| POL-7: all 129 H1 titles match BC-INDEX entries | CLEAN |
| BC-2.14.001 Component enum 17+Custom / Category 12 vs api-surface 18-gate | CLEAN (consistent representations) |
| PROV census E-PROV-009/010/011 anchored + "11 live codes" in error-taxonomy | CLEAN |
| DI-008 grounding in invariants.md (no-panic-on-init) | CLEAN (excluding F-P188-01 Traceability cell) |
| Error-notation Class-3 sampling (SS-05/08/14/18/19/20/21) | CLEAN |
| SS-05 HITL 001-004 body coherence | CLEAN |
| BC-2.10.005 watermark arithmetic | CLEAN |
| Machine-gated axes (POL-16 casing, error-notation, signature-canon, changelog-direction) | CLEAN (spot-check) |

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 1 |
| LOW | 1 |

**Overall Assessment:** NOT CLEAN
**Convergence:** CLEAN(strict)=NO CLEAN(PR-merge)=NO — 0/3 (streak RESET from 1/3; D-160). 2 propagation/sibling-drift defects in newly-body-read shards.
**Next step:** burst-297: product-owner fixes F-P188-01 (BC-2.19.003 DI-008 cell Reviver::new()-returns-Result contradiction) + F-P188-02 (BC-2.08.014 Error-Code-Minted row/callout E-PROV-011 omission). Per D-160: burst-297 also sweeps the two drift classes corpus-wide (all 129 BCs — DI-008 constructor-vs-revive attribution, Error-Code-Minted completeness) to front-load the tail and enable a clean 3-streak. Then P1D-189.

## Scope-Coverage Honesty

**DEEP-READ (BCs this pass — 17 bodies):**
- `specs/behavioral-contracts/ss-05/` BC-2.05.001/002/003/004 — full bodies (HITL shards)
- `specs/behavioral-contracts/ss-19/` BC-2.19.001/002/003 — full bodies (Reviver shards)
- `specs/behavioral-contracts/ss-14/` BC-2.14.001/003 — full bodies (Component/Category)
- `specs/behavioral-contracts/ss-08/` BC-2.08.004/013/014 — full bodies (PROV shards)
- `specs/behavioral-contracts/ss-20/` BC-2.20.001 — full body
- `specs/behavioral-contracts/ss-21/` BC-2.21.002 — full body
- `specs/behavioral-contracts/ss-10/` BC-2.10.005 — full body (watermark)
- `specs/behavioral-contracts/ss-18/` BC-2.18.001 — full body

**TITLE-VERIFIED-ONLY (not body-deep-read this pass):**
- Remaining 112 BCs (SS-01..SS-23 shards not listed above). Not body-read: SS-09/12/13/15/16/23 bodies + ADR bodies (machine-gated spot-check only).

**Novelty:** LOW-MEDIUM. Both findings are propagation/sibling-drift artifacts in newly-body-read BC shards — the same defect class as F-185-01 (burst-277 FC-2 propagation miss). No new defect class introduced. The corpus remains highly converged; the tail is thinning as deep-reads complete.

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 188 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | LOW-MEDIUM |
| **Median severity** | LOW (1 MED + 1 LOW) |
| **Trajectory** | →160→60→5→0→8→0→1→4→5→2→3→0→2 |
| **Verdict** | FINDINGS_REMAIN (CLEAN(strict)=NO; CLEAN(PR-merge)=NO; streak RESET 1/3→0/3; D-160; route burst-297 product-owner) |
