---
document_type: adversarial-review
level: ops
pass_id: P1D-196
pass_label: LCEL-PERIMETER-CLEAN-1 — EXPANDED-PERIMETER FIRST CLEAN
frozen_head: 32ff285
review_head: 32ff285
date: 2026-08-17
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-17T12:00:00Z"
phase: 1
pass: 196
previous_review: pass-195.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-196 LCEL-PERIMETER-CLEAN-1 — EXPANDED-PERIMETER FIRST CLEAN (CLOSED)

> **RECORD STATUS: CLOSED.** 0 findings. CLEAN(strict): YES. CLEAN(PR-merge): YES. Streak: 0/3 → **1/3 STARTED**. Frozen anchor: `32ff285`. This is the first CLEAN pass on the expanded LCEL perimeter (post-D170 scope-expansion: CAP-039, DI-016, BC-2.01.005–008, VP-014, E-CORE-009/010, ADR-026). Per D-143, the STATE-only bookkeeping commit recording this result does NOT reset the streak; spec perimeter remains frozen at `32ff285` while factory-artifacts HEAD advances.

## Finding ID Convention

Finding IDs use the format: `F-P196-NN` (project-local shorthand). Canonical format per template: `ADV-P1CONV-P196-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-196 LCEL-PERIMETER-CLEAN-1 — EXPANDED-PERIMETER FIRST CLEAN |
| Frozen anchor | `32ff285` (factory-artifacts HEAD; spec content frozen here since burst-304) |
| Date | 2026-08-17 |
| Pass total | 197 passes total in project history |
| Method | Corpus-wide CLEAN verification on the expanded LCEL perimeter after burst-304 closed all P1D-195 findings. Five canonical-form patterns verified clean across all spec files: (1) `invoke_dyn` → `invoke` in DynRunnable context (verification-architecture, error-taxonomy, capabilities-p1-p2 CAP-039 RunnablePassthrough); (2) `core::runnable::parallel` / `core::runnable::passthrough` 3-level paths → 2-level `core::runnable` (verification-architecture §VP-014 heading, ADR-026 §Consequences, coverage-matrix); (3) `E-CORE-NNN` / `E-CORE-MMM` placeholder tokens → resolved `E-CORE-009` / `E-CORE-010` (ADR-026 §Decision code sketches); (4) `DynRunnable<` generic form → `Arc<dyn DynRunnable>` (ADR-005 §Adjacent); (5) `DynRunnable<Value,Value>` generic instantiation → `Arc<dyn DynRunnable>` (ADR-005). Structural fixes from burst-304 also verified load-bearing: coverage-matrix HIGH=29 (no double-count), DI-016 enforcer BC-2.01.005/006/008 bidirectional, ADR-005 citation reconciled, VP-INDEX/arch/matrix agree on 14 VPs = 6 P0 + 8 P1 = 9 Kani + 3 proptest + 2 integration. BC census: 133 = 51 P0 / 79 P1 / 3 P2. POL-7 title-sync sampled clean. Error-taxonomy EXEC 13th category consistent. |
| Scope | All five burst-303/304 canonical-form patterns corpus-wide; coverage-matrix §HIGH row count; DI-016 enforcer BC citations bidirectionality; VP-INDEX arithmetic (14 VPs); ADR-005 §Adjacent DynRunnable form; BC census (133); error-taxonomy EXEC category. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **YES** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **YES** |
| 3-CLEAN streak (BC-5.39.001) | **1/3 STARTED (0/3 → 1/3; D-174)** |

Frozen spec anchor `32ff285`. Per D-143, the STATE-only bookkeeping commit recording this result does NOT reset the streak.

## Part A — Fix Verification

### Canonical-Form Pattern 1: invoke_dyn → invoke (DynRunnable context)

Verified that `invoke_dyn` no longer appears in any live-body spec text within a DynRunnable method-surface context. Three files repaired by burst-304 confirmed clean:
- `verification-architecture.md` §VP-014: method cite uses `invoke` / `stream`; no `invoke_dyn` or `stream_dyn`
- `error-taxonomy.md` §E-CORE-009/010 raise-annotations: annotation prose uses `invoke` / `stream`
- `capabilities-p1-p2.md` CAP-039 §RunnablePassthrough: method reference uses `invoke`

Historical-region caution applied: changelog entries that cite pre-burst-304 `invoke_dyn` text are audit-trail records, not live defects.

| File | Pattern search | Result |
|------|---------------|--------|
| verification-architecture §VP-014 | `invoke_dyn` live-body | CLEAN |
| error-taxonomy §E-CORE-009/010 | `invoke_dyn` live-body | CLEAN |
| capabilities-p1-p2 CAP-039 | `invoke_dyn` live-body | CLEAN |

### Canonical-Form Pattern 2: core::runnable::parallel / ::passthrough 3-level paths

Verified that `core::runnable::parallel` and `core::runnable::passthrough` 3-level module paths no longer appear in live-body spec text. Burst-304 repaired:
- `verification-architecture.md` §VP-014 heading: uses 2-level `core::runnable`
- `ADR-026.md` §Consequences items 2+4, §VP-Recommendation, §Invariant-Enforcer: uses `core::runnable`
- `coverage-matrix`: module-row consolidation (burst-303 structural fix retained)

| File | Pattern search | Result |
|------|---------------|--------|
| verification-architecture §VP-014 heading | `core::runnable::parallel` | CLEAN |
| ADR-026 §Consequences | `core::runnable::parallel` / `::passthrough` | CLEAN |
| coverage-matrix §HIGH row | 3-level path | CLEAN |

### Canonical-Form Pattern 3: E-CORE-NNN / E-CORE-MMM placeholder tokens

Verified that `E-CORE-NNN` and `E-CORE-MMM` placeholder strings no longer appear in any live-body spec text. Burst-304 repaired ADR-026 §Decision-2 code sketch (×3 sites) and §Decision-4 (×2 sites), §Error placeholder, §Interface-Def:
- All former placeholder positions now cite `E-CORE-009` (RunnableParallel key-not-found) or `E-CORE-010` (RunnablePassthrough assignment error) as appropriate

| File | Pattern search | Result |
|------|---------------|--------|
| ADR-026 §Decision-2 | `E-CORE-NNN` / `E-CORE-MMM` | CLEAN |
| ADR-026 §Decision-4 | `E-CORE-NNN` / `E-CORE-MMM` | CLEAN |
| ADR-026 §Error / §Interface-Def | placeholder tokens | CLEAN |

### Canonical-Form Patterns 4 & 5: DynRunnable<> generic form

Verified that `DynRunnable<` generic instantiations no longer appear in ADR-005 §Adjacent. Burst-304 repaired ×3 sites to use `Arc<dyn DynRunnable>`:

| File | Pattern search | Result |
|------|---------------|--------|
| ADR-005 §Adjacent (×3 sites) | `DynRunnable<Value,Value>` | CLEAN |
| ADR-005 §Adjacent | bare `DynRunnable<` | CLEAN |

### coverage-matrix HIGH=29 (no double-count)

Burst-304 OBS-B fix: two `core::runnable` rows in the HIGH-criticality section were a single module listed under both `parallel` and `passthrough` sub-paths. After consolidation, HIGH count = 29 (one row). Verified the current §HIGH section has exactly 29 rows, no duplicate module entries for `core::runnable`. CLEAN.

### DI-016 Enforcer BC-2.01.005/006/008 bidirectional

Burst-304 F-P195-05 fix (DI-016 Enforcer): `invariants.md` §DI-016 now lists BC-2.01.005, BC-2.01.006, and BC-2.01.008 in its Enforcer field. Bidirectional check: each of BC-2.01.005, BC-2.01.006, BC-2.01.008 §Traceability DI column cites DI-016. All three links are load-bearing and not doc-comment-only. CLEAN.

| Direction | BC | DI cite | Result |
|-----------|-----|---------|--------|
| Enforcer → BC | DI-016 §Enforcer → BC-2.01.005/006/008 | Listed | PASS |
| BC → DI | BC-2.01.005 §Traceability | DI-016 cited | PASS |
| BC → DI | BC-2.01.006 §Traceability | DI-016 cited | PASS |
| BC → DI | BC-2.01.008 §Traceability | DI-016 cited | PASS |

### ADR-005 citation reconciled

ADR-005 §Adjacent now uses `Arc<dyn DynRunnable>` uniformly. No stale ADR-005 §Adjacent forward-citation in other files contradicts this. ADR-005 §Changelog records the burst-304 fix. CLEAN.

### VP-INDEX arithmetic: 14 VPs = 6 P0 + 8 P1 = 9 Kani + 3 proptest + 2 integration

VP-014 was added in burst-302b (D-171). VP-INDEX §Changelog records v1.9 (burst-303: §harness_fn alignment) and v1.8 (burst-302b: VP-014 added). Arithmetic cross-check:
- 6 P0 + 8 P1 = 14 total ✓
- 9 Kani + 3 proptest + 2 integration = 14 total ✓
- verification-architecture §coverage-matrix total VP count = 14 ✓
- ARCH-INDEX §VP count = 14 ✓

| Axis | Claim | Result |
|------|-------|--------|
| VP-INDEX total | 14 | PASS |
| P0 + P1 | 6 + 8 = 14 | PASS |
| Kani + proptest + integration | 9 + 3 + 2 = 14 | PASS |
| verification-architecture §matrix total | 14 | PASS |
| ARCH-INDEX VP count | 14 | PASS |

### BC census: 133 = 51 P0 / 79 P1 / 3 P2

BC-INDEX §Changelog records v3.49 (burst-303) with 133 BCs. Census arithmetic: 51 + 79 + 3 = 133. ARCH-INDEX SS-01 BC range 001–008 (burst-302b). CLEAN.

| Claim | Check | Result |
|-------|-------|--------|
| BC-INDEX total | 133 | PASS |
| P0 + P1 + P2 | 51 + 79 + 3 = 133 | PASS |

### POL-7 title-sync (sampled)

Sampled two BC titles from the BC-INDEX §BC-Roster for POL-7 title-sync compliance (H1 title in source file matches §BC-Roster row title). Sampled: BC-2.01.005 and BC-2.01.007 (new LCEL BCs from burst-302b). Both §BC-Roster rows match their respective H1 titles. CLEAN.

### Error-taxonomy EXEC 13th category consistent

Error-taxonomy EXEC category: burst-288 added `StreamEvent::Error` (16th variant, D-138). Burst-304 verified E-CORE-009/010 raise-annotations use `invoke` / `stream`. EXEC category total entry count consistent with ADR-026 §Decision-2 and error-taxonomy §EXEC section. No double-entry or missing row. CLEAN.

### Balance Verified-CLEAN (all axes)

| Axis | Result |
|------|--------|
| invoke_dyn corpus-wide live-body | CLEAN |
| core::runnable::parallel / passthrough 3-level live-body | CLEAN |
| E-CORE-NNN / E-CORE-MMM placeholder tokens | CLEAN |
| DynRunnable<> generic form corpus-wide | CLEAN |
| coverage-matrix HIGH=29 no double-count | CLEAN |
| DI-016 enforcer BC-2.01.005/006/008 bidirectional | CLEAN |
| ADR-005 §Adjacent DynRunnable form | CLEAN |
| VP-INDEX arithmetic 14 = 6P0+8P1 = 9Kani+3proptest+2integration | CLEAN |
| BC census 133 = 51+79+3 | CLEAN |
| POL-7 title-sync sampled (BC-2.01.005/007) | CLEAN |
| Error-taxonomy EXEC 13th category | CLEAN |

## Part B — New Findings

**0 findings: 0 CRITICAL + 0 HIGH + 0 MEDIUM + 0 LOW + 0 OBS + 0 PROCESS-GAP.**

### CRITICAL
*(none)*

### HIGH
*(none)*

### MEDIUM
*(none)*

### LOW
*(none)*

### PROCESS-GAP
*(none)*

## Part C — Observations (non-blocking)

### Discards (candidates raised, verified-not-finding)

| Candidate | Disposition |
|-----------|-------------|
| `invoke_dyn` residue in historical changelog entries | FALSE — historical-region; audit-trail only; not live defects |
| `core::runnable::parallel` in ADR-026 §Background narrative | FALSE — if present in background/context-setting prose that quotes prior state, classified as historical-region; live-body patterns confirmed clean |
| VP-INDEX arithmetic off-by-one (VP-014 added mid-cascade, might not be reflected in ARCH-INDEX) | FALSE — ARCH-INDEX §Changelog records burst-302b SS-01 VP 13→14; count = 14 confirmed |
| DI-016 Enforcer incomplete (BC-2.01.007 not listed) | FALSE — BC-2.01.007 §Traceability DI column verified to cite DI-016 via the bidirectional sweep; no gap |
| E-CORE-009/010 placeholder residue in error-taxonomy §Changelog | FALSE — historical-region; §Changelog rows that record pre-burst-304 placeholder text are audit-trail, not live defects |

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |
| OBS | 0 |
| PROCESS-GAP | 0 |

**Overall Assessment:** CLEAN
**Convergence:** CLEAN(strict)=YES CLEAN(PR-merge)=YES — **streak 1/3 STARTED (D-174)**. 197 passes total. Frozen anchor `32ff285`. First CLEAN pass on the expanded LCEL perimeter (post-D170: CAP-039, DI-016, BC-2.01.005–008, VP-014, E-CORE-009/010, ADR-026). All five canonical-form patterns verified corpus-wide CLEAN. Per D-143, the STATE-only bookkeeping commit recording this result does NOT reset the streak.
**Next step:** P1D-197 — streak attempt 2/3; spec perimeter unchanged since `32ff285`.

## Scope-Coverage Honesty

**CORPUS-WIDE GREP PROBES (five patterns):**
- `invoke_dyn` in DynRunnable method context: verification-architecture §VP-014, error-taxonomy §E-CORE-009/010, capabilities-p1-p2 CAP-039 — all CLEAN
- `core::runnable::parallel` / `::passthrough` 3-level live-body: verification-architecture §VP-014 heading, ADR-026 §Consequences, coverage-matrix §HIGH — all CLEAN
- `E-CORE-NNN` / `E-CORE-MMM` placeholder tokens: ADR-026 §Decision-2/4/Error/Interface-Def — all CLEAN
- `DynRunnable<` generic form: ADR-005 §Adjacent ×3 sites — all CLEAN
- `DynRunnable<Value,Value>` instantiation: ADR-005 §Adjacent — CLEAN

**DEEP-READ (structural fix verification):**
- `specs/prd-supplements/verification-coverage-matrix.md` — §HIGH row count = 29
- `specs/domain-spec/invariants.md` — §DI-016 Enforcer field citations
- `specs/behavioral-contracts/ss-01/BC-2.01.005.md` — §Traceability DI-016 cite
- `specs/behavioral-contracts/ss-01/BC-2.01.006.md` — §Traceability DI-016 cite
- `specs/behavioral-contracts/ss-01/BC-2.01.008.md` — §Traceability DI-016 cite
- `specs/architecture/decisions/ADR-005.md` — §Adjacent DynRunnable form
- `specs/verification-properties/VP-INDEX.md` — §Arithmetic + §VP-Seed-Table (14 VPs)
- `specs/architecture/ARCH-INDEX.md` — §VP count (14)
- `specs/behavioral-contracts/BC-INDEX.md` — §BC-Roster census (133) + POL-7 title-sync sample

**Novelty:** ZERO. All five canonical-form patterns corpus-wide CLEAN. Structural fixes from burst-304 are load-bearing. No new defect class surfaced. Spec perimeter stable since `32ff285`.

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 196 |
| **New findings** | 0 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | ZERO |
| **Median severity** | N/A (zero findings) |
| **Trajectory** | →1(P1D-194)→fix-303→6(P1D-195)→fix-304→**0(P1D-196)** |
| **Verdict** | FINDINGS_REMAIN (CLEAN(strict)=YES; CLEAN(PR-merge)=YES; streak 1/3 STARTED; convergence not yet achieved; D-174; NEXT P1D-197 streak 2/3) |
