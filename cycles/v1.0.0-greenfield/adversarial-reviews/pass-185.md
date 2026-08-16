---
document_type: adversarial-review
level: ops
pass_id: P1D-185
pass_label: FULL-PERIMETER
frozen_head: 79651f6
date: 2026-08-16
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-17T00:00:00Z"
phase: 1
pass: 185
previous_review: pass-184.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-185 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** 2 findings (1 MED + 1 LOW). CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak 0/3 (NOT CLEAN; 0 advancement; D-143 — bookkeeping commit does not affect streak). Route: product-owner (F-185-01 MED raise-panic DI-008 contradiction; F-185-02 LOW placeholder inconsistency). Frozen HEAD: factory-artifacts `79651f6`. This is pass #186 total.

## Finding ID Convention

Finding IDs use the format: `F-185-NN` (project-local shorthand). Canonical format per template: `ADV-P1CONV-P185-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-185 FULL-PERIMETER |
| Frozen HEAD | `79651f6` (spec content frozen at `79651f6`) |
| Date | 2026-08-16 |
| Pass total | 186 passes total in project history |
| Method | FULL-PERIMETER. Deep-read axis targeting last un-deep-read rosters: SS-01/SS-02/SS-07/SS-16/SS-17/SS-19 (24 BCs) + BC-INDEX + invariants.md + ADR-016. Completes the full-perimeter deep-read across the recent streak. 2 findings (1 MED + 1 LOW). STREAK 0/3 (NOT CLEAN). |
| Scope | SS-01 (4 BCs), SS-02 (6 BCs), SS-07 (3 BCs), SS-16 (3 BCs), SS-17 (2 BCs), SS-19 (6 BCs) = 24 BCs; BC-INDEX; invariants.md; ADR-016. Sampled/spot-checked: ~105 BCs outside priority rosters. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — NOT CLEAN (2 findings; no advancement)** |

## Part A — Fix Verification

burst-293 closed P1D-184 F-01..F-05. All five fixes verified sound.

| Prior Finding | Status | Evidence |
|---------------|--------|---------|
| F-P1D184-01 HIGH RunnableConfig non_exhaustive posture ADR-021↔ADR-023 (burst-293 ADJUDICATED) | VERIFIED SOUND | ADR-023 §governance authoritative (CLAUDE.md tiebreaker); ADR-021 §rationale corrected; interface-definitions §RunnableConfig adds `#[non_exhaustive]` + explicit `impl Default` (recursion_limit=25); external callers use `::default()` |
| F-P1D184-02 MED ADR-014 §Consequences/§PO-Obligations carry-method contradiction (burst-293) | VERIFIED SOUND | ADR-014 §Consequences and §PO-Obligations now read "carried in message string via key=value pairs" per Decision 5 ×2 sites |
| F-P1D184-03 MED ADR-023 §Decision-3 GuardedDocuments anchor rag_ingress→core::retriever (burst-293) | VERIFIED SOUND | ADR-023 §Decision-3 Exempt Structs table now cites `core::retriever` |
| F-P1D184-04 MED BC-INDEX §VP-Seed-Table VP-011 anchor ADR-018 Decision 1→3 (burst-293) | VERIFIED SOUND | BC-INDEX §VP-Seed-Table VP-011 row now cites "ADR-018 Decision 3" |
| F-P1D184-05 LOW ADR-011 §Source gate check-client-timeout→deny-description-cache-key (burst-293) | VERIFIED SOUND | ADR-011 §Source/Origin cites `deny-description-cache-key` |

## Part B — New Findings

**2 findings: 0 CRITICAL + 0 HIGH + 1 MED + 1 LOW.**

### CRITICAL
*(none)*

### HIGH
*(none)*

### MEDIUM

#### F-185-01 (MED) — BC-2.19.004 EC-005 + Invariant 3 mandate raise-panic; contradicts DI-008 / ADR-016 / sibling BCs / own Traceability row

- **Severity:** MED
- **Category:** contradictions
- **Location:** `.factory/specs/behavioral-contracts/ss-19/BC-2.19.004.md` EC-005 + Invariant 3
- **Description:** BC-2.19.004 EC-005 and Invariant 3 mandate a RAISED startup `panic!` (`RemapChainDetected`), directly contradicting: DI-008 (no panic/unwrap in non-test lib code; NE-07 counter-example); ADR-016 §Decision 3 Property 4 ("structured error … not a panic"); BC-2.19.004's own Traceability row ("DI-008: revive returns Result; no panic"); sibling BC-2.19.003 EC-003 (last-write-wins + CI assertion `registry_size()==EXPECTED_COUNT`, remediated burst-277 FC-2); and sibling BC-2.19.006 EC-001 (startup validation test, no panic). Additionally, VP-2.19.004-B frames the check as a CI test while EC-005 mandates a runtime panic — internal contradiction within the same spec. Corpus-wide grep confirms BC-2.19.004 EC-005 is the SOLE raise-panic spec mandate in all 129 BCs. This is a sibling-sweep miss: burst-277 FC-2 fixed BC-2.19.003 but did NOT propagate the no-panic correction to BC-2.19.004.
- **Proposed Fix:** Replace raised panic mandate with fail-closed `Reviver::new()→Result` OR a CI/unit-test check mirroring BC-2.19.006 (no new code path needed); architect consult only if a new error-taxonomy code is required.
- **Route:** product-owner.

---

### LOW

#### F-185-02 (LOW) — BC-2.01.003 message-template placeholder inconsistency: "at depth N" vs "at depth `<depth>`"

- **Severity:** LOW
- **Category:** ambiguous-language
- **Location:** `.factory/specs/behavioral-contracts/ss-01/BC-2.01.003.md`
- **Description:** Invariant §layer-disambiguation uses "at depth N" while PC5 uses canonical "at depth `<depth>`". Changelog v1.3 claims all-sites-uniform — this is inaccurate (POL-21-adjacent). One-token fix: `N` → `<depth>`.
- **Proposed Fix:** BC-2.01.003 Invariant §layer-disambiguation — replace `N` with `<depth>` to match PC5 canonical placeholder form.
- **Route:** product-owner.

---

### PROCESS-GAP
*(none)*

## Part C — Observations (non-blocking)

*(none — all candidates either confirmed findings or discarded)*

## Discards (candidates raised, all verified-not-finding)

| Candidate | Disposition |
|-----------|-------------|
| SS-16 component:RETRY ALL-CAPS taxonomy convention per BC-2.14.001 | FALSE — convention is correct per taxonomy |
| SS-02 E-GRAPH variant shorthand | FALSE — shorthand is established canon |
| xxh3_128 mechanism not digest | FALSE — mechanism description is accurate |
| SS-07 langchain corpus SHA | FALSE — legit pinned-corpus reference |
| SS-17 Related-BCs advisory | FALSE — advisory flag is valid cross-reference |

## Balance Verified-CLEAN

| Axis | Result |
|------|--------|
| POL-7 H1↔BC-INDEX title sync (all 24 deep-read BCs) | CLEAN |
| Census (129 = 51 P0 / 75 P1 / 3 P2) | CLEAN |
| POL-14/15 changelog direction+dates | CLEAN |
| VP↔BC↔DI spot-checks (BC-2.17.001 9-VP scope; VP-INDEX 13) | CLEAN |
| ADR-018/014 decision anchors (BC-2.16.001→ADR-018 Decision 6) | CLEAN |
| §-anchor existence spot-checks (P-63 removed; §Component: SRLZ correct) | CLEAN |
| DI-008/010/014 propagation coherence | CLEAN |

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 1 |
| LOW | 1 |

**Overall Assessment:** NOT CLEAN
**Convergence:** FINDINGS_REMAIN (streak 0/3; 2 findings; fix burst-294 queued)
**Readiness:** Dispatch burst-294 (product-owner fixes F-185-01 + F-185-02; full cascade), then dispatch P1D-186.

## Scope-Coverage Honesty

**DEEP-READ (24 BCs this pass):**
- `specs/behavioral-contracts/ss-01/` BC bodies (4 BCs) — full bodies
- `specs/behavioral-contracts/ss-02/` BC bodies (6 BCs) — full bodies
- `specs/behavioral-contracts/ss-07/` BC bodies (3 BCs) — full bodies
- `specs/behavioral-contracts/ss-16/` BC bodies (3 BCs) — full bodies
- `specs/behavioral-contracts/ss-17/` BC bodies (2 BCs) — full bodies
- `specs/behavioral-contracts/ss-19/` BC bodies (6 BCs) — full bodies
- `specs/behavioral-contracts/BC-INDEX.md` — full body
- `specs/domain-spec/invariants.md` — full body
- `specs/architecture/decisions/ADR-016.md` — full body

**RESIDUAL COVERAGE DEBT:** NONE — this pass completes the full-perimeter BC-body deep-read. All BC bodies now deep-read ≥1× across the recent streak (SS-01/02/07/16/17/19 were the last un-deep-read rosters). Remaining findings are isolated content defects; the tail is thinning. Sampled/spot-checked only: ~105 BCs outside priority rosters (relied on validators and recent passes).

**Novelty:** MODERATE — F-185-01 is a sibling-sweep miss (burst-277 FC-2 fixed BC-2.19.003 but not BC-2.19.004; the raise-panic mandate is the SOLE such mandate in all 129 BCs). F-185-02 is a placeholder inconsistency (LOW-impact; one-token fix). Machine-gated classes (§-anchors, StreamEvent, census) all CLEAN.

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 185 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (2 new / (2 new + 0 duplicate); both are class-specific to SS-19/SS-01 residual coverage) |
| **Median severity** | LOW-MED (1 MED + 1 LOW) |
| **Trajectory** | →160→60→5→0→8→0→1→4→5→2 |
| **Verdict** | FINDINGS_REMAIN (streak 0/3; fix burst-294 queued; perimeter deep-read now COMPLETE) |
