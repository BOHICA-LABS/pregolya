---
document_type: adversarial-review
level: ops
pass_id: P1D-183
pass_label: FULL-PERIMETER
frozen_head: 11c89f1
date: 2026-08-16
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-16T23:00:00Z"
phase: 1
pass: 183
previous_review: pass-182.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-183 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** 4 findings (1 HIGH + 3 MED). CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak RESET: 0/3 (restart pass 1/3 found findings — no advancement). Route: architect (F1, F2, F3, F4). Frozen HEAD: factory-artifacts `11c89f1` (spec content frozen at `11c89f1` since burst-291). This is pass #184 total.

## Finding ID Convention

Finding IDs use the format: `F-P1D183-NN` (project-local shorthand). Canonical format per template: `ADV-P1CONV-P183-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-183 FULL-PERIMETER |
| Frozen HEAD | `11c89f1` (spec content unchanged since burst-291) |
| Date | 2026-08-16 |
| Pass total | 184 passes total in project history |
| Method | FULL-PERIMETER. Deep-read axis expanded to cover residual coverage debt from P1D-182: ADR full bodies (ADR-025 + others); module-decomposition; verification-architecture; dependency-graph; tooling-selection; BC bodies sampled. 4 findings (1 HIGH + 3 MED). STREAK RESET 0/3. |
| Scope | A: ARCH-INDEX, ADRs (ADR-001/009/010/016/018/019/020/025 deep-read; ADR-002/003/004/005/006/007/008/011/012/013/014/015/017/021/022/023/024 sampled), architecture sections, VPs. B: BCs SS-01..SS-12 + BC-INDEX. C: BCs SS-13..SS-23. D: PRD, prd-supplements (module-decomposition full-body, tooling-selection full-body, purity-boundary-map, verification-architecture, verification-coverage-matrix), 15 domain-spec shards, product-brief. E: policies.yaml, hooks, planning, comparative, semport, CI. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — STREAK RESET (restart required); 4 findings** |

## Part A — Fix Verification

burst-291 closed F-P1D182-01 and swept the entire non-ADR phantom §-anchor class corpus-wide. The generalized gate (B2 192 cites 0 phantom) was validated. Regression surface clean on that axis.

| Prior Finding | Status | Evidence |
|---------------|--------|---------|
| F-P1D182-01 phantom BC-2.23.005 §Category (burst-291) | VERIFIED SOUND | verify-adr-anchor-citations.sh PASS; B1 60 + B2 192 = 252 cites 0 phantom; 14 self-probes pass |
| burst-291 non-ADR §-anchor corpus sweep (~54 fixes) | VERIFIED SOUND | Gate generalized; no regression detected this pass |

## Part B — New Findings

**4 findings: 1 HIGH + 3 MED.**

### CRITICAL
*(none)*

### HIGH

#### F2 (HIGH) — ADR-025 internal contradiction: grounded-rule-set-count drift (S1-omission)

**Description:** ADR-025 contains an internal contradiction on which rule-set membership the ADR grounds. The Context section and the Decision intro cite "S2, S3, S4" (omitting S1), while the Consequences section, the Source/Origin section, and the full §as_retriever body ("Rule origin: S1") all assert "S1, S2, S3, S4". A reader cannot determine from ADR-025 alone whether the `as_retriever` receiver rule (S1) is ADR-grounded.

**Affected locations within ADR-025:**

| Location | Current Text | Expected |
|----------|-------------|---------|
| Context section (approx. line 46) | "…grounds S2, S3, S4" | "…grounds S1, S2, S3, S4" |
| Decision intro (approx. line 65) | "…for S2, S3, S4" | "…for S1, S2, S3, S4" |
| Consequences section (approx. line 260) | "S1, S2, S3, S4" | already correct |
| Source/Origin section (approx. line 287) | "S1, S2, S3, S4" | already correct |
| §as_retriever body ("Rule origin: S1") | "S1, S2, S3, S4" | already correct |

**Fix:** Update Context (approx. line 46) and Decision intro (approx. line 65) to read "S1, S2, S3, S4".

**Route:** architect (ADR-025 owner).

**Defect class:** "grounded-rule-set-count drift" — Context/Decision and Consequences/body disagree on which rules the ADR grounds. Sibling of F3 below. New class; not previously encountered.

---

### MEDIUM

#### F3 (MED) — ARCH-INDEX registry row for ADR-025 omits S1

**Description:** ARCH-INDEX.md line 182, ADR-025 registry row, lists the rule set as "S2/S3/S4" — omitting S1. This contradicts both the ADR-025 body (Consequences + Source/Origin + §as_retriever all say S1/S2/S3/S4) AND the ARCH-INDEX's own v1.26 changelog entry which records "S1/S2/S3/S4". Sibling of F2.

**Fix:** ARCH-INDEX ADR-025 registry row rule-set field → "S1/S2/S3/S4".

**Route:** architect (ARCH-INDEX owner) + state-manager for row sync if needed.

---

#### F1 (MED) — module-decomposition VP-012 anchor mischaracterizes property

**Description:** module-decomposition.md lines 453-455, the §pregolya-tools VP-012 anchor, states that VP-012 "proves never produces a token count exceeding the hard limit." This is wrong. `check_watermark_trigger` returns `bool`; VP-012 proves the property "trigger fires iff (tokens_remaining / ceiling) <= (1 - fraction)" — a boolean trigger-condition property, not a token-count ceiling property. Per VP-012.md, BC-2.10.005, and verification-architecture (approx. line 525), the property is the trigger-fires-iff condition.

**Fix:** module-decomposition VP-012 anchor prose → describe the boolean trigger-condition property accurately (trigger fires iff ratio condition holds), not a token-count ceiling.

**Route:** architect (module-decomposition owner + VP-012 traceability).

---

#### F4 (MED) — tooling-selection fuzz-target file names drift from BC-2.17.002

**Description:** tooling-selection.md line 92 lists fuzz target file names as `checkpoint_roundtrip.rs` and `graph_engine_boundary.rs`. BC-2.17.002 (the authoritative source per CLAUDE.md Source-of-Truth Precedence) specifies `fuzz_checkpoint_serde.rs` and `fuzz_graph_execution.rs`. The same authoritative names appear in verification-architecture approx. lines 617-618. tooling-selection is a non-authoritative reference; it must match the BC.

**Fix:** tooling-selection.md line 92 fuzz-target names → `fuzz_checkpoint_serde.rs` and `fuzz_graph_execution.rs` (per BC-2.17.002).

**Route:** architect (tooling-selection owner; BC-2.17.002 is SoT, code must align).

---

### LOW
*(none)*

### PROCESS-GAP
*(none)*

## Part C — Observations (non-blocking)

#### OBS-P183-01 (LOW) — tooling-selection Kani async trio vs verification-architecture 5-module set

tooling-selection lists three Kani proof targets (reduce_super_step, storage_address, get_next_version). verification-architecture specifies a 5-module set. The tooling-selection commentary is prefixed "See verification-architecture" — it is an illustrative legacy list, not a normative enumeration. verification-architecture is the authoritative source. No fix required; confirming no hidden SoT conflict.

## Discards (candidates raised, all verified-not-finding)

| Slice | Candidate | Disposition |
|-------|-----------|-------------|
| A | VP-002..VP-012 bodies (6 bodies full-read) | DISCARDED — all clean; no property mischaracterization beyond F1 (VP-012 separately filed) |
| A | Purity-boundary-map census (34 pure + 38 impure + 12 bridge = 84) | DISCARDED — exact; consistent with module-criticality 84 |
| A | dependency-graph facade DAG | DISCARDED — all edges consistent; no orphan nodes |
| A | ADR count 25 across ARCH-INDEX/ADR-directory/VP-INDEX traceability | DISCARDED — 25=25=25 exact |
| D | StreamEvent taxonomy count chain 12→14→15 (BC-2.06.001 SoT) | DISCARDED — internally consistent; 16th variant (::Error) properly tracked |
| C | BC-2.16.001 PC5 Class-3 struct-literal pattern | DISCARDED — candidate raised; post-ADR-010 Direction B (PascalCase retraction per burst-268/P1D-168) re-examined; PC5 is canon-compliant under Direction B; false-positive |
| A | §-anchor classes (verify-adr-anchor-citations.sh generalized gate) | DISCARDED — B1 60 cites 0 phantom; B2 192 cites 0 phantom; 14 self-probes pass; all CLEAN post-burst-291 |

## Balance Verified-CLEAN

| Axis | Result |
|------|--------|
| VP-002/003/004/005/006/007/008/010/012 bodies | CLEAN — no mischaracterization (VP-012 F1 separately filed) |
| Purity-boundary-map census 34+38+12=84 | CLEAN — exact |
| dependency-graph facade DAG | CLEAN — no orphan nodes or incorrect edges |
| ADR count 25 (ARCH-INDEX registry / ADR directory / VP-INDEX traceability) | CLEAN — exact match |
| StreamEvent taxonomy chain 12→14→15 | CLEAN — internally consistent across BC-2.06.001/interface-definitions/L2 domain spec |
| BC-2.16.001 PC5 Class-3 struct-literal (candidate) | CLEAN — post-Direction B (ADR-010 §Consequences, Direction B) re-examination confirms canon-compliant; false-positive discarded |
| §-anchor classes (all targets post-burst-291) | CLEAN — 252 total cites 0 phantom; gate PASS 14/14 |

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 0 |

**Overall Assessment:** NOT CLEAN
**Convergence:** FINDINGS_REMAIN (streak RESET 0/3; 4 findings; fix burst-292 queued)
**Readiness:** Dispatch burst-292 (architect fixes F1 F2 F3 F4), then dispatch P1D-184 (streak restart).

## Scope-Coverage Honesty

**DEEP-READ (exhaustive this pass):**
- `specs/architecture/ARCH-INDEX.md` — full body including ADR registry rows
- `specs/architecture/decisions/ADR-001.md`, `ADR-009.md`, `ADR-010.md`, `ADR-016.md`, `ADR-018.md`, `ADR-019.md`, `ADR-020.md`, `ADR-025.md` — full bodies
- `specs/architecture/module-decomposition.md` — full body including VP anchor rows
- `specs/architecture/verification-architecture.md` — full body (approx. lines 500-650 for Kani/fuzz target inventory)
- `specs/architecture/verification-coverage-matrix.md` — full body
- `specs/architecture/purity-boundary-map.md` — full body (census: 34+38+12=84)
- `specs/architecture/dependency-graph.md` — full body
- `specs/prd-supplements/tooling-selection.md` — full body including fuzz-target names
- `specs/verification-properties/VP-002.md`, `VP-003.md`, `VP-004.md`, `VP-005.md`, `VP-006.md`, `VP-007.md`, `VP-008.md`, `VP-010.md`, `VP-012.md` — full bodies
- `specs/behavioral-contracts/ss-16/BC-2.05.007.md`, `ss-16/BC-2.10.005.md`, `ss-16/BC-2.16.001.md`, `ss-17/BC-2.17.002.md`, `ss-19/BC-2.19.005.md`, `ss-21/BC-2.21.003.md` — full bodies (targeted by finding hypotheses)

**SAMPLED (not full body):**
- ADR full bodies: ADR-002/003/004/005/006/007/008/011/012/013/014/015/017/021/022/023/024
- VP-001/009/011/013 bodies
- api-surface.md
- BC bodies SS-01/02/07/11/12/15 + remainder of SS-16/17/19

**RESIDUAL COVERAGE DEBT (next-pass target P1D-184):**
- ADR full bodies: ADR-002/003/004/005/006/007/008/011/012/013/014/015/017/021/022/023/024
- VP-001/009/011/013 bodies
- api-surface.md
- BC bodies SS-01/02/07/11/12/15 + remainder of SS-16/17/19

**Novelty:** MEDIUM-HIGH — "grounded-rule-set-count drift" (F2/F3) is a new defect class not previously encountered: ADR Context/Decision and ADR Consequences/body disagree on which rules the ADR grounds. This suggests an authoring pattern where the initial scope was narrowed mid-write but the intro and conclusions were not updated consistently. Also surfaced: VP anchor prose mischaracterization (F1) and BC-authoritative-vs-reference filename drift (F4) — both in less-recently-touched architecture files newly reached by deep-read.

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 183 |
| **New findings** | 4 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 0.7 (new defect class grounded-rule-set-count drift; 3 sibling content-consistency defects in less-recently-touched files) |
| **Median severity** | MEDIUM |
| **Trajectory** | →160→60→5→0→8→0→1→4 |
| **Verdict** | FINDINGS_REMAIN (streak RESET 0/3; fix burst-292 queued) |
