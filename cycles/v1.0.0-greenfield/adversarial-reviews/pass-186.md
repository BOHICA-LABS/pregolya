---
document_type: adversarial-review
level: ops
pass_id: P1D-186
pass_label: FULL-PERIMETER
frozen_head: 15837ea
date: 2026-08-16
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-16T20:00:00Z"
phase: 1
pass: 186
previous_review: pass-185.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-186 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** 3 findings (1 MED + 2 LOW). CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak 0/3 (NOT CLEAN; 0 advancement; per D-143 — bookkeeping commit does not affect streak). Route: product-owner (F-186-01 BC-2.23.002 §PC-3 ferroctmp brand-residue; F-186-02 product-brief.md ferrograph); architect (F-186-01 ADR-024 ferroctmp ×3; F-186-03 ADR-010 Wave-TBD). Frozen HEAD: factory-artifacts `15837ea`. This is pass #187 total.

## Finding ID Convention

Finding IDs use the format: `F-186-NN` (project-local shorthand). Canonical format per template: `ADV-P1CONV-P186-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-186 FULL-PERIMETER |
| Frozen HEAD | `15837ea` (spec content frozen at `15837ea`) |
| Date | 2026-08-16 |
| Pass total | 187 passes total in project history |
| Method | FULL-PERIMETER. Security-adjacent deep-read axis: SS-13 (7/7 BCs), SS-23 (6/6 BCs), SS-05 BC-2.05.006/007, SS-08 BC-2.08.013/014. Supporting: POL-7 title sync, POL-17 notation, error-taxonomy SBXD anchors. 3 findings (1 MED + 2 LOW). STREAK 0/3 (NOT CLEAN). |
| Scope | SS-13 (7 BCs deep-read), SS-23 (6 BCs deep-read), SS-05 (BC-2.05.006/007 deep-read), SS-08 (BC-2.08.013/014 deep-read). Supporting: product-brief.md, ADR-010, ADR-024. NOT reviewed: SS-03/04/06/09/10/11/12/14/15/18/20/21/22 bodies + SS-05 001-004/008 + SS-08 001-012. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — NOT CLEAN (3 findings; no advancement; D-143)** |

## Part A — Fix Verification

burst-294 closed P1D-185 F-185-01+F-185-02. Both fixes verified sound.

| Prior Finding | Status | Evidence |
|---------------|--------|---------|
| F-185-01 MED BC-2.19.004 §EC-005+Invariant 3 raise-panic mandate (burst-294) | VERIFIED SOUND | EC-005 now requires a startup validation unit test mirroring BC-2.19.006 EC-001 pattern; `#[cfg(test)] mod tests` block asserts no OLD_CORE_NAMESPACES_MAPPING key maps to a value that is itself a key; test fails in CI; no runtime panic!; no new error-taxonomy code; resolves DI-008/ADR-016 §Decision 3 Property 4 contradiction |
| F-185-02 LOW BC-2.01.003 placeholder "at depth N" (burst-294) | VERIFIED SOUND | BC-2.01.003 §layer-disambiguation Invariant now reads "at depth `<depth>`", matching PC5 canonical placeholder form |

## Part B — New Findings

**3 findings: 0 CRITICAL + 0 HIGH + 1 MED + 2 LOW.**

### CRITICAL
*(none)*

### HIGH
*(none)*

### MEDIUM

#### F-186-01 (MED) — Stale ferrochain-era brand token `.ferroctmp_<random>` in live normative specs (BC-2.23.002 + ADR-024)

- **Severity:** MED
- **Category:** stale-brand-residue
- **Location:** `.factory/specs/behavioral-contracts/ss-23/BC-2.23.002.md` §PC-3 (atomic-write temp-file prefix) + `.factory/specs/architecture/decisions/ADR-024.md` (×3 occurrences at lines 310/313/315)
- **Description:** Four occurrences of `.ferroctmp_<random>` remain as the canonical atomic-write temp-file prefix in live normative code-bearing spec text. BC-2.23.002 §PC-3 (line 98) defines `.ferroctmp_<random>` as the Precondition for atomic-write temp-file naming — this is a normative code-bearing precondition that an implementer would use to materialize temp files in a pregolya-* crate with dead-brand filenames. ADR-024 references the same token in three locations (lines 310, 313, 315). This residue was missed by burst-284 (D-103 rename sweep): the `.ferroctmp_` prefix pattern was not in the rename manifest, which targeted identifiers and module names, not embedded string-literal patterns in spec preconditions. Canonical replacement token: `.pregolyatmp_<random>`.
- **Proposed Fix:** BC-2.23.002 §PC-3 — replace `.ferroctmp_<random>` → `.pregolyatmp_<random>`. ADR-024 — replace all three occurrences `.ferroctmp_` → `.pregolyatmp_` (×3). Additionally, devops-engineer should extend records-lint.sh with a narrow dead-brand-token check to prevent recurrence (D-157).
- **Route:** product-owner (BC-2.23.002), architect (ADR-024), devops-engineer (records-lint extension).

---

### LOW

#### F-186-02 (LOW) — Stale ferrochain-era graph-runtime brand token `ferrograph` in product-brief.md §Market Intelligence Summary

- **Severity:** LOW
- **Category:** stale-brand-residue
- **Location:** `.factory/specs/product-brief.md` §Market Intelligence Summary (D7 GO-conditions record, approximately line 315)
- **Description:** One occurrence of `ferrograph` (ferrochain-era name for what is now `pregolya-graph`) in product-brief.md §Market Intelligence Summary, quoting a D7 GO-conditions record. product-brief.md is in specs/ (live normative), not planning/. The text cites `ferrograph` as a current module name in a GO-condition context, which a reader would interpret as the authoritative brand. Normalize to `pregolya-graph`; a historical clarifier `(formerly 'ferrograph')` is appropriate if the text is quoting the literal D7 decision verbatim.
- **Proposed Fix:** product-brief.md §Market Intelligence Summary — replace `ferrograph` → `pregolya-graph` (add `(formerly 'ferrograph')` if quoting D7 literally).
- **Route:** product-owner.

---

#### F-186-03 (LOW) — ADR-010 §#[non_exhaustive]-gate-update-requirement cites `Wave TBD` for pregolya-tools/SS-23 (determinable as Wave 1)

- **Severity:** LOW
- **Category:** stale-placeholder
- **Location:** `.factory/specs/architecture/decisions/ADR-010.md` §#[non_exhaustive]-gate-update-requirement (approximately line 567)
- **Description:** ADR-010 §#[non_exhaustive]-gate-update-requirement cites `Wave TBD` for the pregolya-tools/SS-23 entry. All SS-23 BCs carry `wave: 1` in their frontmatter — the wave assignment is determinable from the BC corpus without additional architecture decisions. CLAUDE.md Rule 6 forbids "pending architect review" placeholders for questions answerable in current scope. Fix: `Wave TBD` → `Wave 1`.
- **Proposed Fix:** ADR-010 §#[non_exhaustive]-gate-update-requirement — replace `Wave TBD` → `Wave 1` for the pregolya-tools/SS-23 entry.
- **Route:** architect.

---

### PROCESS-GAP
*(none)*

## Part C — Observations (non-blocking)

*(none — all candidates confirmed findings or discarded per balance section)*

## Discards (candidates raised, verified-not-finding)

| Candidate | Disposition |
|-----------|-------------|
| ferrochain/ferro-brand in planning/ files (decisions-archive-pre-p1d.md, naming-decision-study.md, rename-constraint-spec.md [ferroloom/ferronode/ferrolink/ferroweave/ferroflow candidate names], rename-sweep-manifest.md, repo-initialization-log.md, naming-decision-pregolya.md, market-intel.md) | FALSE — legitimate historical rename documentation (D-103/burst-284); intentionally reference old brand to document ferrochain→pregolya rename; NOT residue and must NOT be swept |
| ADR-010 §corrective-note (lines 19/179, FerrochainError) | FALSE — legitimate historical rename documentation; corrective-note section exists to document the pre-rename error name; NOT residue |
| BC-2.13.007 casing/anchor forms | FALSE — valid per ADR-010 Direction B conventions |
| BC-2.23.006 doubled-verb phrasing | FALSE — acceptable prose form; not an ambiguity finding |
| BC-2.08.014 error-code-minted field | FALSE — field correctly present per error-taxonomy |
| BC-2.05.006/007 ActionRisk #[non_exhaustive], Deny/hook-panic fail-closed | FALSE — clean; correct per ADR-010/spec |
| BC-2.08.013/014 security-adjacent contracts | FALSE — clean; correct per architecture |
| SS-13 7/7 BCs: fail-closed backend, PolicyNotEnforceable, canonicalize_beneath_root, symlink-escape, Seatbelt deny-by-default, env strip | FALSE — all verified clean |
| SS-23 6/6: DI-014 no-silent-swallow all tools, ADR-024 PC-3/4/5 traceability (aside from F-186-01 ferroctmp) | FALSE — all other SS-23 traceability verified clean |
| POL-17 notation (BC-2.13.007 full-field form valid) | FALSE — clean |
| error-taxonomy SBXD anchors | FALSE — clean |

## Balance Verified-CLEAN

| Axis | Result |
|------|--------|
| SS-13 (7/7 BCs): fail-closed backend, PolicyNotEnforceable, canonicalize_beneath_root, symlink-escape, Seatbelt deny-by-default, env strip | CLEAN |
| SS-23 (6/6 BCs): DI-014 no-silent-swallow-all-tools, ADR-024 PC-3/4/5 traceability (excluding F-186-01 ferroctmp) | CLEAN |
| SS-05 BC-2.05.006/007: ActionRisk #[non_exhaustive], Deny/hook-panic fail-closed | CLEAN |
| SS-08 BC-2.08.013/014 | CLEAN |
| POL-7 title sync | CLEAN |
| POL-17 notation (BC-2.13.007 full-field form valid) | CLEAN |
| error-taxonomy SBXD anchors | CLEAN |

**Important balance note (record to prevent re-flagging in future passes):** ferrochain/ferro-brand references in planning/ files (decisions-archive-pre-p1d.md, naming-decision-study.md, rename-constraint-spec.md, rename-sweep-manifest.md, repo-initialization-log.md, naming-decision-pregolya.md, market-intel.md) and ADR-010 §corrective-note (lines 19/179 FerrochainError) are LEGITIMATE HISTORICAL rename documentation — they intentionally reference the old brand to document the ferrochain→pregolya rename (D-103/burst-284). These are NOT residue and must NOT be swept. Only live NORMATIVE code-bearing/current-tense uses in specs/ (F-186-01/F-186-02) are defects.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 1 |
| LOW | 2 |

**Overall Assessment:** NOT CLEAN
**Convergence:** FINDINGS_REMAIN (streak 0/3; 3 findings; fix burst-295 queued; per D-143 does not affect streak)
**Readiness:** Dispatch burst-295 (architect ADR-024/ADR-010; product-owner BC-2.23.002/product-brief; devops records-lint brand-token check), then dispatch P1D-187.

## Scope-Coverage Honesty

**DEEP-READ (21 BCs this pass):**
- `specs/behavioral-contracts/ss-13/` BC bodies (7 BCs) — full bodies
- `specs/behavioral-contracts/ss-23/` BC bodies (6 BCs) — full bodies
- `specs/behavioral-contracts/ss-05/` BC-2.05.006 + BC-2.05.007 — full bodies
- `specs/behavioral-contracts/ss-08/` BC-2.08.013 + BC-2.08.014 — full bodies

**NOT REVIEWED (deferred to later streak passes):** SS-03/04/06/09/10/11/12/14/15/18/20/21/22 bodies + SS-05 001-004/008 + SS-08 001-012.

**Novelty:** MODERATE — F-186-01 is a burst-284 rename miss (`.ferroctmp_` pattern was not in rename manifest; code-bearing precondition in BC-2.23.002 §PC-3 + ADR-024 ×3). F-186-02 is a stale brand token in live normative doc (product-brief.md in specs/). F-186-03 is a stale `Wave TBD` placeholder answerable from BC frontmatter. Machine-gated classes (§-anchors, StreamEvent, census) all CLEAN.

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 186 |
| **New findings** | 3 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (3 new / (3 new + 0 duplicate)) |
| **Median severity** | LOW-MED (1 MED + 2 LOW) |
| **Trajectory** | →160→60→5→0→8→0→1→4→5→2→3 |
| **Verdict** | FINDINGS_REMAIN (streak 0/3; fix burst-295 queued; per D-143 does not affect streak) |
