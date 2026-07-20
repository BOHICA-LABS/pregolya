---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 125
previous_review: pass-124.md
---

# Adversarial Review: ferrochain (Pass 125)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 124 produced two findings:
- F-P124-01: E-MEMORY-003 mis-anchored to memory_get in interface-definitions v2.39; BC-2.15.002 defines memory_get read path as Ok(None) isolation-by-invisibility; E-MEMORY-003 is a WRITE-class error (quota/capacity exceeded on write per BC-2.15.002 Invariant); memory_set lacked E-MEMORY-003; security-boundary mis-anchor creating owner-detection oracle risk
- F-P124-02: VP-001/003/004/005 remained at L3 template level while VP-002 advanced to L4 in burst-117; 1-vs-4 corpus split; absent proof_method/red_gate frontmatter fields; Phase 6 formal-verifier will encounter non-uniform VP contracts

Fix burst 127 was dispatched (BA: interface-definitions v2.39→v2.40 E-MEMORY-003 moved to memory_set; isolation-by-invisibility documented on memory_get; architect: VP-001/003/004/005 v1.0→v1.1 L4 conformance). Verification follows.

### F-P124-01 / F-P124-02 Verification — CLOSED

**PASS-125 sibling-checks verification (checks a–e from PASS-125 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) interface-definitions v2.40 E-MEMORY placement table (001/002/003/004) verified against BC-2.15.001/002 EC/TV raise sites | PASS — placement table present: 001 vector_search / 002+003 memory_set / 004 memory_get; all four codes anchor to correct method+class; E-MEMORY-003 raise site on memory_set correct (WRITE/quota; BC-2.15.002 Invariant); E-MEMORY-004 on memory_get correct (READ/IO; BC-2.15.004) |
| (b) memory_get isolation-by-invisibility text coherent with BC-2.15.002 PC1/TV-001/PC6 | PASS — memory_get §Errors in interface-definitions v2.40 documents isolation-by-invisibility: cross-owner reads return Ok(None) per BC-2.15.002 PC1/TV-001/PC6 storage-layer predicate; no E-MEMORY-003 raised on read path; text coherent |
| (c) all 5 VPs uniform L4 (section inventory + frontmatter), input-hash --check PASS | PASS — VP-001/002/003/004/005 all v1.1 L4; 37-field core frontmatter present; Source Contract / Proof Method / Lifecycle sections present; input-hash --check PASS all 5; uniform structure confirmed |
| (d) VP-INDEX level:L3 convention NOT churned | PASS — VP-INDEX all entries retain level: L3 per index-doc convention; L4 advancement is per-VP frontmatter only; no churn |
| (e) grep E-MEMORY-003 zero memory_get-anchored live sites | PASS — grep E-MEMORY-003 across specs/: zero hits on memory_get annotation; only memory_set sites present; isolation verified |

**F-P124-01 conclusion:** CLOSED — interface-definitions v2.40 E-MEMORY placement correct; memory_set carries E-MEMORY-002+003; memory_get carries E-MEMORY-004 only; isolation-by-invisibility note present; BC-2.15.002 PC1/TV-001/PC6 coherent; zero oracle-risk sites.

**F-P124-02 conclusion:** CLOSED — all 5 VPs structurally uniform L4; VP-001/003 proof_method kani; VP-004/005 proof_method manual, red_gate true (R11 provenance); VP-002 reference VP unchanged; VP-INDEX level:L3 convention intact.

**Carry-forward axes sweep (from pass-124):**

| Axis | Result |
|------|--------|
| ADR-008/ADR-010/ADR-011 soundness | PASS — reviewed; no new gaps or contradictions with current spec corpus |
| ss-14 ↔ nfr-catalog timeout (NFR-009) | PASS — BC-2.14.* performance contracts reviewed against NFR-009; timeout alignment confirmed |
| ss-06 ordering ↔ BC-2.12.007 | PASS — run ordering invariant in ss-06 reviewed against BC-2.12.007; consistent |
| ss-03 recursion arithmetic (carry-forward) | PASS — recursion depth arithmetic in ss-03 checked; no arithmetic defect found |
| RetryHint ↔ ss-16 (carry-forward) | PASS — RetryHint binding in ss-16 consistent with BC-2.16.* retry semantics |
| Gate inventory 34 (carry-forward) | PASS — gate count 34 confirmed in bc-authoring-plan; no phantom or duplicated gates |
| interface-definitions v2.40 §MemoryStore E-MEMORY placement (pass-124 NEW) | PASS — see sibling-check (a)(e) above; full placement table correct; CLOSED |
| VP corpus L4 uniformity (pass-124 NEW) | PASS — see sibling-check (c)(d) above; all 5 VPs L4 uniform; CLOSED |

**Axes NOT cleared (carry-forward to pass-126):**

| Axis | Status | Notes |
|------|--------|-------|
| Holdout-domain briefs C/D deep coherence | NOT CLEARED — deep-read deferred per burst sequencing | Domain C (OpenClaw) and Domain D brief internal coherence vs. L2 domain spec; not yet surfaced as finding; flagged for deep-read at next available pass |
| ss-02 channel BC trio deep-read (BC-2.02.002/003/004) | NOT CLEARED — trio not fully read in depth in any prior pass | BC-2.02.002 / BC-2.02.003 / BC-2.02.004 channel semantics; cross-BC coherence of send/receive/close invariants not adversarially verified |
| prd.md body ↔ supplements precedence conflicts | NOT CLEARED — precedence rule (supplements supersede prd.md prose) not exercised against live corpus | prd.md body references to supplement content not cross-checked for stale or contradictory claims |

---

## Part B — New Findings

### F-P125-01 — MED: VP-003 BC Traceability Cell Mislabels BC-2.13.004 Contribution as "Red Gate"

**Severity:** MED
**Scope:** `specs/verification-properties/VP-003.md` §BC Traceability table; BC-2.13.004 contribution cell

#### Evidence

VP-003 v1.1 (burst-127 L4 conformance version) introduced a BC Traceability table with a contribution cell for BC-2.13.004. The cell was labeled:

```
Primary VP obligation; Red Gate
```

This designation is incorrect on two grounds:

**1. BC-2.13.004 has no Red Gate designation.** Consulting BC-2.13.004 frontmatter and the VP Traceability matrix: BC-2.13.004 carries `vp_seed: true` and `kani_target: workspace-confinement`. There is no `red_gate: true` field. The Red Gate designation is reserved specifically for VP-004 and VP-005, which cover MCP-linked behaviors that are R11-class voids (upstream test gaps requiring a Red Gate harness). BC-2.13.004 is a path-confinement invariant, not an R11 void.

**2. The correct contribution label is "Kani VP Seed".** BC-2.13.004 is the primary BC feeding VP-003's Kani proof target (workspace-confinement). The contribution cell should read "Primary VP obligation; Kani VP Seed" to match:
- BC-2.13.004's `vp_seed: true` + `kani_target: workspace-confinement` frontmatter
- VP-003's proof_method: kani (not manual/red_gate)
- The parallel convention established in VP-001 (BC-2.01.* entries labeled "Primary VP obligation; Kani VP Seed")

**Siblings VP-001/002/004/005 do NOT share this defect:**
- VP-001: BC-2.01.* Kani VP Seed cells — correct Kani VP Seed labeling
- VP-002: BC-2.13.003 cell — correct Kani VP Seed labeling
- VP-004: BC-2.09.* cells — correctly labeled "Red Gate" (R11 provenance; manual proof_method)
- VP-005: BC-2.15.* cells — correctly labeled "Red Gate" (R11 provenance; manual proof_method)

VP-003 is the sole outlier: it incorrectly carries the VP-004/005 Red Gate label instead of the correct Kani VP Seed label.

**Root cause:** The burst-127 L4 conformance pass mechanically swept all 5 VPs to add BC Traceability table structure. The template for VP-003's contribution cell was sourced from VP-004/005 Red Gate context rather than the VP-001/002 Kani VP Seed context. The proof_method kani vs. manual distinction was correctly carried (VP-003 has proof_method kani) but the contribution cell was not aligned to that choice.

**Required fix:** VP-003 v1.1→v1.2: BC Traceability table cell for BC-2.13.004 changed from "Primary VP obligation; Red Gate" to "Primary VP obligation; Kani VP Seed". Full-file sweep: confirm zero remaining "Red Gate" strings in VP-003.md (VP-003 has no Red Gate-applicable behavior; any occurrence is a residue of the mislabeling).

---

## Carry-Forward Axes — No New Findings (for pass-126)

The following axes were swept in pass 125 and produced no new findings beyond F-P125-01. Carry forward for pass-126:

- **ADR-008/ADR-010/ADR-011 soundness:** PASS — no new gaps.
- **ss-14 ↔ nfr-catalog timeout (NFR-009):** PASS — consistent.
- **ss-06 ordering ↔ BC-2.12.007:** PASS — consistent.
- **VP-003 v1.2 BC Traceability cell (NEW — fixed by burst-128):** Carry forward to verify VP-003 v1.2 BC-2.13.004 contribution cell = "Primary VP obligation; Kani VP Seed"; zero stray "Red Gate" strings in VP-003.md; VP suite still structurally uniform L4 post-edit.
- **Holdout-domain briefs C/D deep coherence:** NOT YET CLEARED — carry forward.
- **ss-02 channel BC trio deep-read (BC-2.02.002/003/004):** NOT YET CLEARED — carry forward.
- **prd.md body ↔ supplements precedence conflicts:** NOT YET CLEARED — carry forward.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 (F-P125-01: VP-003 BC Traceability table cell for BC-2.13.004 mislabeled "Red Gate" instead of "Kani VP Seed"; VP-003 proof_method is kani; Red Gate is VP-004/005-only R11 designation; VP-003 is sole outlier among 5 VPs; introduced by burst-127 L4 conformance sweep sourcing template from wrong VP sibling) |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **1** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision

**CLEAN (strict):** no (1 MED; strict-zero requires ZERO findings of any severity)
**CLEAN (PR-merge):** no (1 MED finding present)

**Convergence counter:** 0/3 (counter unchanged — pass 125 NOT CLEAN strict; fix burst 128 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** LOW-MEDIUM (F-P125-01 is a label-class defect: the correct conceptual distinction (Kani VP Seed vs Red Gate) was established in prior passes; the wrong label is a local transcription error from the L4 conformance sweep sourcing template from VP-004/005 instead of VP-001/002; no new defect class; decaying severity trajectory 2→1, HIGH→MED; the sweep-class root cause (1-of-N template sweep without sibling-label alignment) is a known recurrence of F-P124-02's root cause applied one level lower in the same artifact family)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 125 |
| **New findings** | 1 (F-P125-01 MED) |
| **Cleared axes** | F-P124-01 CLOSED (E-MEMORY-003 placement verified correct on memory_set; isolation-by-invisibility documented on memory_get; zero oracle-risk sites); F-P124-02 CLOSED (5 VPs uniform L4; proof_method kani/manual correct per VP; red_gate correct per R11 provenance; VP-INDEX convention preserved) |
| **Novelty score** | LOW-MEDIUM — label transcription defect within the same VP conformance sweep that introduced F-P124-02; the conceptual Kani VP Seed vs Red Gate distinction was established in passes 117–124; this is the first VP-003-specific manifestation of the sweep-sourcing-from-wrong-sibling class; trajectory is decaying (2→1) and severity is declining (HIGH→MED) |
| **Median severity** | MED (F-P125-01 sole finding) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1→1→3→5→3→2→1 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1M; counter 0/3 unchanged; fix burst 128 dispatched; NEXT: pass 126 on new HEAD after fix burst 128) |
