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
pass: 126
previous_review: pass-125.md
---

# Adversarial Review: ferrochain (Pass 126)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 125 produced one finding:
- F-P125-01: VP-003 BC Traceability cell for BC-2.13.004 mislabeled "Primary VP obligation; Red Gate" — Red Gate designation is VP-004/VP-005-only (R11 provenance, manual proof_method); VP-003 has proof_method kani; correct label is "Primary VP obligation; Kani VP Seed" matching BC-2.13.004 vp_seed:true + kani_target:workspace-confinement + VP-001/VP-002 parallel convention; introduced by burst-127 L4 conformance sweep sourcing template from wrong VP sibling

Fix burst 128 was dispatched (architect: VP-003 v1.1→v1.2 — BC Traceability table cell BC-2.13.004 corrected; full-file sweep confirmed zero stray Red Gate). Verification follows.

### F-P125-01 Verification — CLOSED

**PASS-126 sibling-checks verification:**

| Check | Result |
|-------|--------|
| (a) VP-003 v1.2 BC-2.13.004 cell = "Primary VP obligation; Kani VP Seed" (not Red Gate) | PASS — BC Traceability table row for BC-2.13.004 reads "Primary VP obligation; Kani VP Seed"; Red Gate label absent; correct Kani VP Seed label confirmed |
| (b) Zero stray "Red Gate" strings in VP-003.md body | PASS — full-file sweep: zero occurrences of "Red Gate" anywhere in VP-003.md; Red Gate language is restricted to VP-004 and VP-005 which carry R11 manual-proof provenance; VP-003 is kani-based; sweep confirms zero residue |
| (c) VP suite structurally uniform L4 post-edit | PASS — all 5 VPs (VP-001/002/003/004/005) remain structurally uniform L4; VP-003 v1.2 edit was cell-only (BC Traceability table row text); no structural fields (frontmatter, Source Contract, Proof Method, Lifecycle sections) were disturbed; uniformity preserved |
| (d) Source Contract section coherence — VP-003 v1.2 Source Contract cites BC-2.13.004 correctly | PASS — VP-003 v1.2 Source Contract section cites BC-2.13.004 as primary tracing BC with kani_target:workspace-confinement; the sibling-line (proof_method: kani, kani_target: workspace-confinement) is coherent with the corrected BC Traceability cell; no internal contradiction between frontmatter and Source Contract narrative |

**F-P125-01 conclusion:** CLOSED — VP-003 v1.2 BC Traceability table cell for BC-2.13.004 = "Primary VP obligation; Kani VP Seed" confirmed; zero stray Red Gate strings in VP-003.md; VP suite uniform L4; Source Contract sibling-line coherent; sibling VPs VP-001/002 remain correct Kani VP Seed; VP-004/005 remain correct Red Gate. No residue.

---

## Part B — New Findings (Fresh Hunt + Cleared Carry-Forward Axes)

This pass conducted a fresh hunt across the corpus AND deep-read of the three multi-pass carry-forward axes from pass-125 (holdout domains C/D, ss-02 channel trio, prd.md↔supplements precedence). ZERO new findings.

### Carry-Forward Axis 1 — Holdout-Domain Briefs C/D Deep Coherence

**Axis:** Domain C (OpenClaw) and Domain D holdout-domain brief internal coherence vs. L2 domain spec and BC corpus. Carried forward from pass-123 (first flagged) through pass-125 (not yet cleared).

**Deep-read scope:** All BC anchors cited in domain briefs C and D; all CAP anchors cited; internal narrative coherence of each brief; cross-brief consistency; alignment with L2 domain spec entity/invariant definitions.

**Result:** ZERO findings.

| Check | Result |
|-------|--------|
| Domain C/D BC anchors — existence in BC corpus | PASS — all 9 BC anchors cited across domain briefs C and D resolve to existing BCs in the behavioral-contracts corpus; no phantom BC references; no stale or renamed BC IDs |
| Domain C/D CAP anchors — existence in capabilities corpus | PASS — both CAP anchors (2 total) cited in domain briefs C and D resolve to existing capability definitions; no phantom CAP references |
| Domain C brief internal coherence | PASS — narrative is internally consistent; no contradictions between brief premise, forcing functions, and acceptance criteria |
| Domain D brief internal coherence | PASS — narrative is internally consistent; no contradictions between brief premise, forcing functions, and acceptance criteria |
| Domain C/D alignment with L2 entity definitions | PASS — entity references in both briefs (Message, ToolCall, graph traversal, memory access) are coherent with L2 domain spec entity/invariant definitions as of current corpus state |

**Axis 1 conclusion:** CLEARED. Holdout-domain briefs C/D are coherent; all 9 BC + 2 CAP anchors existence-validated; no drift vs. L2 domain spec.

---

### Carry-Forward Axis 2 — ss-02 Channel BC Trio Deep-Read (BC-2.02.002/003/004)

**Axis:** BC-2.02.002 / BC-2.02.003 / BC-2.02.004 channel semantics; cross-BC coherence of send/receive/close invariants. Carried forward from pass-123 (first flagged) through pass-125 (not yet cleared).

**Deep-read scope:** Full body of BC-2.02.002 (send), BC-2.02.003 (receive), BC-2.02.004 (close); cross-BC invariant coherence (e.g., close-then-send behavior, buffering invariants, error code consistency across the trio); error struct definitions.

**Result:** ZERO findings.

| Check | Result |
|-------|--------|
| BC-2.02.002 (send) internal coherence | PASS — PCs, ECs, TVs, and error codes internally consistent; no circular references; send-path error codes all exist in error taxonomy with correct class/status/recover |
| BC-2.02.003 (receive) internal coherence | PASS — receive semantics (blocking/non-blocking variants, empty-channel behavior) internally consistent; timeout and empty return paths coherent; error codes verified in taxonomy |
| BC-2.02.004 (close) internal coherence | PASS — close semantics consistent; double-close behavior specified; idempotency/once semantics coherent |
| Cross-BC coherence: BC-2.02.002 send → BC-2.02.004 close interaction | PASS — close-then-send error path consistent: BC-2.02.004 close sets terminal state; BC-2.02.002 send-on-closed raises correct error code; no contradiction |
| Cross-BC coherence: BC-2.02.003 receive → BC-2.02.004 close interaction | PASS — BC-2.02.003 receive-on-closed returns Ok(None) or error per BC (closed-channel distinguishable from empty-channel); semantics consistent with BC-2.02.004 close postconditions |
| Error struct definitions: unnamed BarrierValue type — no-dup-error pattern | PASS — the unnamed BarrierValue (BarrierValue type used in ss-02 barrier/sync primitives) intentionally produces no duplicate-error on repeated barrier arrivals: the design uses idempotent semantics (arrival at an already-satisfied barrier is a no-op, not an error). This is consistent with the broader ferrochain error-taxonomy philosophy (only fatal or application-visible failures get error codes; silent no-op behavior on repeated idempotent operations is intentional). No finding. |
| Cross-BC error code namespace collision | PASS — error codes across BC-2.02.002/003/004 occupy distinct EC slots; no namespace collision; taxonomy census consistent |

**Axis 2 conclusion:** CLEARED. BC-2.02.002/003/004 channel trio is cross-BC coherent; send/receive/close invariants consistent; unnamed-BarrierValue no-dup-error behavior judged intentional (idempotent arrival semantics); error structs coherent.

---

### Carry-Forward Axis 3 — prd.md Body ↔ Supplements Precedence Conflicts

**Axis:** prd.md body references to supplement content cross-checked for stale or contradictory claims; supplements-supersede-prd.md prose rule (CLAUDE.md precedence rule 3) exercised against live corpus. Carried forward from pass-123 (first flagged) through pass-125 (not yet cleared).

**Deep-read scope:** prd.md body narrative sections referencing error codes, interface definitions, test vectors, and architectural decisions; cross-check against current versions of interface-definitions.md v2.40, error-taxonomy.md, test-vectors.md v1.9, nfr-catalog.md v1.2, bc-authoring-plan.md.

**Result:** ZERO findings.

| Check | Result |
|-------|--------|
| E-MEMORY-003 prd.md ↔ error-taxonomy consistency | PASS — prd.md body does not claim E-MEMORY-003 placement (prd.md defers to interface-definitions.md per precedence rule); interface-definitions.md v2.40 has E-MEMORY-003 on memory_set (correct per F-P124-01 fix); error-taxonomy has E-MEMORY-003 as DURABILITY/broken/WRITE-class (consistent); no contradiction. NOTE: the reference to "E-MEMORY-003 label" noted in pass-125 sibling-check context was a paraphrase issue in the pass-125 report prose (the report used "MemoryStoreFailed" as a colloquial description of E-MEMORY-003, which is the taxonomy category label rather than the BC error-code name); the corpus itself is consistent; this is a cleared candidate (pass-125 report paraphrase only, not a corpus defect). |
| summary_halt prd.md ↔ BCs propagation | PASS — prd.md references summary_halt as a graph halt sub-state; BC-2.05.005 v1.5 7-case guard (a-g) includes summary_halt at case (e); BC-2.05.004 v1.3 bidirectional delegation remains coherent; test-vectors.md v1.9 TV Count 8/SS-05 35/507/516 arithmetic confirmed; prd.md body description of summary_halt is consistent with BC-2.05.005 v1.5 normative text |
| BC count arithmetic: 95 = 48/39/8 | PASS — prd.md cites 95 BCs total; BC-INDEX.md census 48 P0 + 39 P1 + 8 P2 = 95 confirmed; no phantom or uncounted BCs; arithmetic correct |
| prd.md §error taxonomy deference | PASS — prd.md body defers to error-taxonomy.md for error code inventory; error-taxonomy v1.26 census 86 = 43+16+27 (E-SERVER / E-GRAPH / other); no prd.md body claim contradicts current error-taxonomy content |
| prd.md §interface surface deference | PASS — prd.md §Interface Surface defers to interface-definitions.md; prd.md body descriptions consistent with interface-definitions.md v2.40 current content; no stale claims about removed or renamed interfaces |

**Cleared candidate:** E-MEMORY-003 "label" discrepancy was a pass-125 report paraphrase issue only. The pass-125 report used "MemoryStoreFailed" (the taxonomy category label) when describing E-MEMORY-003 — this is a colloquial description in the report prose, not a corpus defect. The corpus (error-taxonomy.md, interface-definitions.md v2.40, BC-2.15.001/002) is consistent regarding E-MEMORY-003 semantics and placement.

**Axis 3 conclusion:** CLEARED. prd.md body is consistent with current supplement versions; no stale or contradictory claims found; E-MEMORY-003 label resolved as report-paraphrase issue (corpus consistent); summary_halt fully propagated; 95=48/39/8 arithmetic PASS.

---

## Carry-Forward Axes — All Cleared

**All four carry-forward axes entering pass-126 have been cleared. No axes carry forward to pass-127.**

| Axis | Status |
|------|--------|
| VP-003 v1.2 BC Traceability cell (NEW in pass-125) | CLEARED — confirmed "Kani VP Seed"; zero stray Red Gate; Source Contract coherent |
| Holdout-domain briefs C/D deep coherence | CLEARED — 9 BC + 2 CAP existence-validated; coherent vs. L2 domain spec |
| ss-02 channel BC trio deep-read (BC-2.02.002/003/004) | CLEARED — cross-BC coherent; BarrierValue no-dup intentional |
| prd.md body ↔ supplements precedence conflicts | CLEARED — consistent; summary_halt propagated; 95=48/39/8 PASS |

**Pass-127 is a fresh-hunt pass with no pre-loaded carry-forward axes.** The corpus is frozen at spec-state 02d8ccd (no spec edits until 3/3 or a new finding forces a fix burst). Fresh-hunt scope: any remaining gaps in the spec corpus not yet surfaced.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 0 |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **0** |

**Overall Assessment:** pass-clean
**Convergence:** FINDINGS_REMAIN — convergence not yet achieved; counter 1/3 STREAK ACTIVE (first CLEAN(strict) on frozen HEAD 02d8ccd per frozen-HEAD rule; 2 more consecutive CLEAN(strict) passes required for 3/3)
**Readiness:** clean — no revision required

**CLEAN (strict):** yes (ZERO findings of any severity)
**CLEAN (PR-merge):** yes (ZERO findings of any severity)

**Convergence counter:** 1/3 (counter advances from 0/3 — pass-126 is CLEAN(strict) on post-burst-128 HEAD 02d8ccd; BC-5.39.001 frozen-HEAD streak rule: this is the first CLEAN(strict) pass on the new frozen HEAD; streak now 1 of 3)
**Novelty:** ZERO (no new defect classes; no new findings; all carry-forward axes cleared; trajectory →0 appended; decaying trajectory continues)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 126 |
| **New findings** | 0 |
| **Cleared axes** | F-P125-01 CLOSED (VP-003 v1.2 confirmed Kani VP Seed cell; zero stray Red Gate); holdout C/D CLEARED (9 BC + 2 CAP coherent); ss-02 trio CLEARED (BarrierValue no-dup intentional); prd.md↔supplements CLEARED (E-MEMORY-003 consistent; summary_halt propagated; 95=48/39/8 PASS) |
| **Novelty score** | ZERO — no new findings; all four carry-forward axes cleared; corpus frozen at 02d8ccd; fresh-hunt yielded zero additional candidates |
| **Median severity** | N/A (zero findings) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1→1→3→5→3→2→1→0 |
| **CLEAN (strict)** | yes |
| **CLEAN (PR-merge)** | yes |
| **Verdict** | FINDINGS_REMAIN (0 findings this pass; convergence not yet achieved — counter 1/3 STREAK ACTIVE; 2 more consecutive CLEAN(strict) passes on 02d8ccd required; NEXT: pass 127 fresh-hunt only) |
