---
document_type: adversarial-review
level: ops
pass_id: P1D-180
pass_label: FULL-PERIMETER
frozen_head: b682a70
date: 2026-08-16
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-16T14:00:00Z"
phase: 1
pass: 180
previous_review: pass-179.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-180 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** 8 findings (3H/3M/2L + 1 process-gap). CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak RESET 0/3 (was 1/3 after P1D-179). Dominant class: phantom / prohibited ADR §Named-Section citations — a class `verify-adr-anchor-citations.sh` reported as WARN but did NOT block (advisory mode; POL-19 carried ~10–12 known phantoms deferred under ADR-022 Decision 4). Fresh-context deep-read of the ADR-target anchor axis (previously only sampled in prior passes) surfaced the systemic backlog at the artifact level. Frozen HEAD: factory-artifacts `b682a70`. This is pass #181 total.

## Finding ID Convention

Finding IDs use the format: `F-180-NN` for this pass (project-local shorthand). Canonical format per template: `ADV-P1CONV-P180-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-180 FULL-PERIMETER |
| Frozen HEAD | `b682a70` |
| Date | 2026-08-16 |
| Pass total | 181 passes total in project history |
| Method | FULL-PERIMETER. All slices completed. Deep-read of ADR-target anchor axis — previously sampled only in prior passes. |
| Scope | A: ARCH-INDEX, ADRs, architecture sections, VPs. B: BCs SS-01..SS-12 + BC-INDEX. C: BCs SS-13..SS-23. D: PRD, prd-supplements, 15 domain-spec shards, product-brief. E: policies.yaml, hooks, planning, comparative, semport, CI. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **RESET 0/3 — P1D-179 streak of 1/3 wiped** |

## Part A — Fix Verification

Burst-289 fixes from P1D-178 verified. All 5 findings confirmed closed.

| Prior Finding | Status | Evidence |
|---------------|--------|---------|
| F-178-01 HIGH StreamEvent count propagation (15→16) | CONFIRMED CLOSED | 16 is the live-body count; all burst-289 sites read correctly |
| F-178-02 MED ADR-024 §Consumers stale citation | CONFIRMED CLOSED | 7 named BCs present |
| F-178-03 MED ADR-023 phantom anchor | CONFIRMED CLOSED | anchor now resolves to BC-2.06.001 §Postconditions |
| F-178-04 MED BC-2.10.003 phantom §recursion_limit_canon ×3 | CONFIRMED CLOSED | phantom removed at all 3 sites |
| F-178-05 LOW ADR-023 label ambiguous | CONFIRMED CLOSED | "17 pre-Error variants" is unambiguous |

## Part B — New Findings

**8 findings: 3 HIGH + 3 MED + 2 LOW + 1 PROCESS-GAP.**

### CRITICAL

*(none)*

### HIGH

**F-180-01 HIGH** — `api-surface.md` §Public Traits: chained double-§ citation `ADR-014 §Decision 2 §Object-safety`. This is a chained-§ form (two §-segments joined by space), which is the exact counter-example ADR-022 §Decision 5 used to illustrate prohibited Form C. ADR-022 was minted in burst-287 to prohibit this pattern. The citation has never been fixed at source since ADR-022 was minted. Correct form: split into `ADR-014 §Decision 2` + `ADR-005 §Adjacent Trait Object-Safety Adjudications` (or whichever section contains the object-safety adjudication text).

**F-180-02 HIGH** — `api-surface.md` §Error Type: Form-B phantom citation `ADR-010 §impl PregolyaError`. No heading `§impl PregolyaError` exists in ADR-010. The error-construction notation canon section is `§Error-Construction Notation Canon`. This is the bare-§ form (Form B) of a phantom anchor — `verify-adr-anchor-citations.sh` in advisory mode passed this because its regex was blind to bare-§ format.

**F-180-03 HIGH** — `BC-2.06.001.md` §Postconditions: Form-C phantom citation `ADR-023 §exhaustive-by-design`. No section `§exhaustive-by-design` exists in ADR-023. The correct anchor for the exhaustive-by-design policy is `ADR-023 §Exempt Enums` (the section that describes which enums are exempt from #[non_exhaustive]). This phantom was introduced in burst-287 when ADR-023 was minted and the BC was updated to reference it.

### MEDIUM

**F-180-04 MED** — `test-vectors.md` Red-Gate table: phantom citation `ADR-014 §DI-012`. No section `§DI-012` exists in ADR-014. The DI-012 mechanization is covered in `ADR-014 §Decision 6 — GuardedDocuments Typed Wrapper (DI-012 Mechanization)`. Additionally, `BC-INDEX.md` has an inconsistent citation form for the same BC — one reference uses long form, the peer reference uses short form — creating reader confusion about which is authoritative.

**F-180-05 MED** — `ADR-020 §Decision 5`: citation `ADR-010 §Category axis`. No heading `§Category axis` exists in ADR-010. The correct anchor for the component axis expansion content is `ADR-010 §Component Axis Expansion`.

**F-180-06 MED** — `ADR-010 §Class 3`: stale and factually false present-tense adjudication note. The note claimed (1) POL-17 was uncorrected and (2) hook gates still check for `FerrochainError`. Both claims are false at HEAD: POL-17 was corrected in the notation-canon rebuild (burst-288), and all hooks use `PregolyaError` since burst-284. A note that claims present-tense truth about artifact state when that state is false is worse than no note — it actively misleads.

### LOW

**F-180-07 LOW** — `api-surface.md`: citation `§Confinement-Proof` (hyphen). The actual heading in the referenced file is `§Confinement Proof — Phase 2` (space, not hyphen; has subtitle). The hyphenated form is a slugified pseudo-anchor (Form C prohibited variant) that does not resolve in a standard Markdown renderer.

**F-180-08 LOW** — `api-surface.md`: malformed citation `ADR-005 §Adjacent Adjudications corrected list`. No section `§Adjacent Adjudications corrected list` exists in ADR-005. The correct anchor is `§Adjacent Trait Object-Safety Adjudications` (or `§Adjudications` per ADR-005's actual heading). The phrase "corrected list" appears to be residual annotation text that was accidentally included in the anchor string.

### PROCESS-GAP

**F-180-PG** — `verify-adr-anchor-citations.sh` (advisory mode) is a false-green vector for the chained-§ and bare-§ phantom classes. The CITE_RE regex in the current script is blind to (1) chained double-§ forms like `ADR-NNN §Foo §Bar` and (2) bare-§ forms like `§impl PregolyaError` without a preceding ADR reference. Additionally, POL-19 carried ~10–12 known phantom WARNs as deferred items under ADR-022 Decision 4 without a human-authorized story anchor — this violates POL-29 (human authorization for deferral) and POL-31 (deferral must be attached to a specific future story). The advisory-only posture means 10+ live-body phantoms passed through at least 2 streak-eligible passes (P1D-179 included) without triggering a fix requirement. The gate must be promoted from advisory to BLOCKING and its regex extended to cover chained-§ and bare-§ forms.

## Balance / Confirmed-CLEAN Axes

The following axes were verified clean this pass (scope-coverage honesty: deep-read — not sampled):

- **BC census 129**: 51 P0 / 75 P1 / 3 P2 — matches BC-INDEX; count internally consistent
- **BC-H1↔BC-INDEX title sync**: clean on all 129 BC files
- **DI-001..DI-015**: all lifted per POL-2; zero orphans
- **VP-INDEX arithmetic**: 13 = P0(6) + P1(7) = Kani(9) + proptest(2) + integration(2); self-consistent
- **Enum/error-notation canon**: internally complete; no Class 1/Class 3 conflation
- **ADR count**: 25 matches ARCH-INDEX
- **ferrochain→pregolya rename**: complete in live hooks and all spec files
- **Changelog direction/monotonicity**: clean on burst-289 touched files

## Scope-Coverage Honesty

**Deep-read (exhaustive):** indexes (BC-INDEX, ARCH-INDEX, VP-INDEX, L2-INDEX, policies.yaml, ADR-010/018/020/022/023/024); the two anchor/error hooks (verify-adr-anchor-citations.sh, verify-error-notation-canon.sh); full ADR §-citation grep census across all 25 ADRs and 10 SS files; all 129 BC H1s.

**Sampled (residual risk):** most BC bodies (SS-01/02/03/05/07/10/11/12/15/16/17/19/21); most ADR full bodies (beyond §-citation axis); prd.md/error-taxonomy/nfr-catalog/observability/domain-spec Slice-D census counts; CI/planning.

**NOT read (out of scope this pass):** api-surface deep structural review (only §-citation axis audited), semport artifacts, comparative assessments.

**Novelty: MEDIUM-HIGH.** Prior passes sampled the ADR-target anchor axis; this pass was the first deep-read of the full citation corpus. The systemic backlog (10+ phantoms carried as advisory WARNs) was visible in the WARN count but not surfaced as individual findings until the deep-read. This confirms L-178 (rotate deep-read emphasis across streak passes rather than re-checking fixed items).

## Finding Summary

| ID | Severity | File | Description |
|----|----------|------|-------------|
| F-180-01 | HIGH | api-surface.md §Public Traits | Chained double-§ `ADR-014 §Decision 2 §Object-safety` (ADR-022 §Decision 5 counter-example) |
| F-180-02 | HIGH | api-surface.md §Error Type | Bare-§ phantom `ADR-010 §impl PregolyaError` (correct: `§Error-Construction Notation Canon`) |
| F-180-03 | HIGH | BC-2.06.001.md §Postconditions | Form-C phantom `ADR-023 §exhaustive-by-design` (correct: `§Exempt Enums`) |
| F-180-04 | MED | test-vectors.md Red-Gate + BC-INDEX | Phantom `ADR-014 §DI-012` (correct: `§Decision 6 — GuardedDocuments Typed Wrapper`); BC-INDEX citation form inconsistency |
| F-180-05 | MED | ADR-020 §Decision 5 | Phantom `ADR-010 §Category axis` (correct: `§Component Axis Expansion`) |
| F-180-06 | MED | ADR-010 §Class 3 | Stale/false present-tense adjudication note claiming POL-17 uncorrected + FerrochainError in hooks (both false at HEAD) |
| F-180-07 | LOW | api-surface.md | Hyphenated `§Confinement-Proof` vs real heading `§Confinement Proof — Phase 2` |
| F-180-08 | LOW | api-surface.md | Malformed `ADR-005 §Adjacent Adjudications corrected list` (residual annotation text in anchor) |
| F-180-PG | PROCESS-GAP | verify-adr-anchor-citations.sh | Advisory-only gate is false-green for chained-§ + bare-§ forms; 10+ POL-19-deferred phantoms lacked human-authorized story anchor |

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 3 |
| MEDIUM | 3 |
| LOW | 2 |
| PROCESS-GAP | 1 |
| **Total** | **8 + PG** |

**Overall Assessment:** FINDINGS REMAIN
**Convergence:** STREAK RESET 0/3 (P1D-179 streak of 1/3 wiped by this pass)
**Fix-burst:** burst-290 required — ADR §-citation phantom class corpus-sweep + gate promotion

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 180 |
| **New findings** | 8 + 1 process-gap |
| **Dominant class** | Phantom / prohibited ADR §Named-Section citations (chained-§, bare-§, pseudo-slug forms) |
| **Novelty score** | MEDIUM-HIGH — axis not previously deep-read despite WARN backlog being visible |
| **Median severity** | MED–HIGH |
| **Trajectory** | →256→189→160→60→5→0→8 |
| **Verdict** | FINDINGS_REMAIN (streak RESET 0/3) |

## Resolution

**Fix-burst 290 COMPLETE (2026-08-16).** All 8 findings + process-gap closed:

- F-180-01: `ADR-014 §Decision 2 §Object-safety` → split: `ADR-014 §Decision 2` + `ADR-005 §Adjacent Trait Object-Safety Adjudications`
- F-180-02: `ADR-010 §impl PregolyaError` → `ADR-010 §Error-Construction Notation Canon`
- F-180-03: `ADR-023 §exhaustive-by-design` → `ADR-023 §Exempt Enums`
- F-180-04: `ADR-014 §DI-012` → `ADR-014 §Decision 6 — GuardedDocuments Typed Wrapper (DI-012 Mechanization)`; BC-INDEX citation form normalized
- F-180-05: `ADR-010 §Category axis` → `ADR-010 §Component Axis Expansion`
- F-180-06: ADR-010 §Class 3 stale note rewritten to past-tense fact (POL-17 corrected burst-288; hooks use PregolyaError since burst-284)
- F-180-07: `§Confinement-Proof` → `§Confinement Proof — Phase 2`
- F-180-08: `ADR-005 §Adjacent Adjudications corrected list` → `ADR-005 §Adjacent Trait Object-Safety Adjudications`
- F-180-PG: `verify-adr-anchor-citations.sh` extended (chained-§ + bare-§ detection, 7 self-probes added) and PROMOTED advisory→BLOCKING (13→14 blocking validators); POL-19 migration sweep DISCHARGED; ADR-022 Decision 4 deferral CLOSED; 12→0 live-body phantoms in architecture/ files (architect: 13 fixes across api-surface.md + ADR-014/017/010/024/020; product-owner: 9 fixes across BC-2.06.001/BC-2.08.009/BC-2.13.004/BC-2.15.005 + test-vectors + BC-INDEX + error-taxonomy + interface-definitions). EXPECTED_BLOCKING_COUNT bumped 13→14.

D-144..D-146 added. L-178..L-179 minted.
