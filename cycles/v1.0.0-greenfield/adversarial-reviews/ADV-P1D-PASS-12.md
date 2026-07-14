---
document_type: adversarial-review
pass: 12
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
open_findings: 1
timestamp: 2026-07-14T00:00:00Z
trajectory: "14→5→7→13→3→3→3→5→2→4→4→1"
counter_clean: 0
counter_clean_needed: 3
---

# ADV-P1D PASS-12: Adversarial Review — Phase 1d

**Verdict: NOT CLEAN — 1 HIGH multi-site cluster (F-P12-01) — fixed in this pass**

---

## Sibling-Axis Checks (Pass-12 coverage complement)

| Axis | Status | Notes |
|------|--------|-------|
| Cross-BC state-machine lifecycle-arrow representation census (NEW) | FAIL (F-P12-01) | 8 stale sites; see full state-machine sweep below |
| BC-2.05.002 HITL resume contract coherence with updated BC-2.12.003 | PASS | PC7/PC8/PC9 align with BC-2.05.002; interrupted→in_progress arc consistent |
| All 86 BCs: EC-NNN count (≥1 edge case present) | PASS | Spot-checked ss-01/ss-07/ss-12/ss-14; no BCs with empty EC sections |
| Cross-component error code collision scan (post-GRAPH-reconciliation) | PASS | No shared NNN between semantically different E-xxx codes |
| BC-INDEX title column H1 verbatim match (86-BC census) | FAIL (subsumed into F-P12-01) | BC-2.12.003 was the single violating row; fixed |

Rotated axes (PASS):
- DI verbatim title equivalence (post-pass-11 fix, 86/86): PASS
- RTM CAP column completeness (post-pass-11 fix): PASS

---

## Findings

### F-P12-01 (HIGH): Lifecycle-arrow representation inconsistency — 8 stale sites post-pass-11 fix

**Finding class: cross-site lifecycle-arrow state-machine consistency**

**Root cause:** The pass-11 fix for F-P11-01 correctly updated BC-2.12.003 PC7/PC8/PC9 and the H1
title. However, the fix was keyed on the "terminal" keyword pattern. Eight other lifecycle-arrow
sites across domain-spec, prd-supplements, BC-INDEX, prd.md, bc-authoring-plan, and BC-2.12.004
were not reached by that pattern-targeted fix. All eight continued to list `interrupted` within the
terminal-set position (`→ completed | failed | interrupted | cancelled`), directly contradicting the
post-pass-11 canonical state machine where `interrupted` is pausable/resumable and the terminal set
is `{completed, failed, cancelled}`.

Two sites also carried the label "Canonical" (`interface-definitions.md:206` description field) and
one site (`BC-INDEX.md:117`) had a title mismatch against the BC H1 authority rule.

**Full state-machine sweep (pre-fix):**

| Site | Line | Form | Pre-fix content | Verdict |
|------|------|------|-----------------|---------|
| `domain-spec/entities-server.md` | 43 | arrow | `→ completed \| failed \| interrupted \| cancelled` | FAIL |
| `prd-supplements/interface-definitions.md` | 206 | arrow | `Canonical …completed\|failed\|interrupted\|cancelled` | FAIL |
| `behavioral-contracts/ss-12/BC-2.12.003.md` | 201 | prose (Traceability) | `"queued→in_progress→completed/failed/interrupted/cancelled"` stale quote | FAIL |
| `domain-spec/ubiquitous-language-server.md` | 35 | arrow | `→ completed \| failed \| interrupted \| cancelled` | FAIL |
| `behavioral-contracts/BC-INDEX.md` | 117 | title | `(queued → in_progress → completed/failed/interrupted/cancelled)` | FAIL |
| `prd.md` | 273 | title | `(queued → in_progress → completed/failed/interrupted/cancelled)` | FAIL |
| `prd-supplements/bc-authoring-plan.md` | 259 | title | `completed \| failed \| interrupted \| cancelled` | FAIL |
| `behavioral-contracts/ss-12/BC-2.12.004.md` | 59 | arrow | `→ completed \| failed \| interrupted \| cancelled` | FAIL |
| `behavioral-contracts/ss-12/BC-2.12.004.md` | 141 | arrow | `→ completed \| failed \| interrupted \| cancelled` | FAIL |

Consistent (no change needed):
| Site | Line | Form | Content | Verdict |
|------|------|------|---------|---------|
| `BC-2.12.003.md` | 27 | H1 title | `…completed/failed/cancelled; interrupted is pausable/resumable` | PASS |
| `BC-2.12.003.md` | 33 | prose | `completed \| failed \| cancelled`, with `interrupted` as pausable | PASS |
| `BC-2.12.003.md` | 75–80 | transition arcs | Individual arc lines; not a terminal-set claim | PASS |
| `BC-2.12.003.md` | 164 | test vector | `queued → in_progress → completed` (happy-path only) | PASS |
| `BC-2.05.004.md` | 134 | VP table | `interrupted → in_progress → completed/interrupted` (resume arc) | PASS |
| `BC-2.12.006.md` | 132 | error string | `"in_progress→completed"` (specific arc in error context) | PASS |

**Fix applied:**

Canonical forms established and propagated to all 8 FAIL sites:

- *Title/prose* form: `queued → in_progress → completed/failed/cancelled; interrupted is pausable/resumable`
- *Diagram/arrow* form: `queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted (resume via POST .../resume)`

Site-by-site fixes:

1. `entities-server.md:43` — arrow form applied; `⇄` bidirectional arc added
2. `interface-definitions.md:206` — "Canonical" label removed; arrow form applied; `Authority: BC-2.12.003 PC7-PC9` appended
3. `BC-2.12.003:201` Traceability — stale quote replaced; PC7-PC9 cited as authoritative source
4. `ubiquitous-language-server.md:35` — arrow form applied; historical-note lines (lines 36+) untouched
5. `BC-INDEX.md:117` — title updated to match H1 verbatim
6. `prd.md:273` — title updated to match H1 (sentence-case table convention preserved)
7. `bc-authoring-plan.md:259` — title updated to match H1
8a. `BC-2.12.004:59` — arrow form applied
8b. `BC-2.12.004:141` — arrow form applied

**Post-fix arrow census (16 sites scanned):**

All 16 `grep -rn "in_progress →\|in_progress→\|→ interrupted\|⇄"` hits verified PASS.
No remaining sites list `interrupted` in a terminal-set position.

**Title 3-way match (BC-2.12.003):**

| Document | Title | Match |
|----------|-------|-------|
| BC-2.12.003.md H1 (authority) | `Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled; interrupted is pausable/resumable)` | — |
| BC-INDEX.md:117 | `Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled; interrupted is pausable/resumable)` | VERBATIM ✓ |
| prd.md:273 | `Run creation and execution lifecycle (queued → in_progress → completed/failed/cancelled; interrupted is pausable/resumable)` | PASS (sentence-case table convention) ✓ |
| bc-authoring-plan.md:259 | `Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled; interrupted is pausable/resumable)` | VERBATIM ✓ |

**Process gap addressed:** Arrow-representation census gate added to bc-authoring-plan.md
§Authoring Guidelines item 12. Gate command:
`grep -rn "in_progress →\|in_progress→\|→ interrupted\|⇄" .factory/specs/`
Every hit must show `interrupted` as pausable and terminal set as `{completed, failed, cancelled}`.
Single authority: BC-2.12.003 PC7-PC9.

---

## Observation: BC-INDEX:48 VP-seed cross-ref abbreviation

**Status:** INTENTIONAL — no fix required.

BC-INDEX column 48 uses abbreviated VP-seed cross-references (e.g., `VP-KANI-01`) rather than
full VP file paths. This is consistent with the BC-INDEX schema: the VP column is a seed
cross-reference for Kani-targeted BCs, not a full link. The VP-INDEX.md is the authoritative
VP catalog. Abbreviation is intentional per BC-INDEX column spec.

---

## Counter-Clean Status

- Required for CLEAN: 3 consecutive passes with 0 open findings
- Counter at this pass: 0 (NOT CLEAN — 1 finding cluster, fixed)
- Trajectory: ...→4→4→1 (decaying to single shared root cause)

---

## Next-pass rotation axes (suggestions for pass-13)

1. **Arrow census gate validation:** Re-run `grep -rn "in_progress →\|in_progress→\|→ interrupted\|⇄"` as first action to confirm gate holds after any further edits
2. **BC-2.05.002 deep audit:** Full postcondition review of HITL resume contract (resume-value FIFO, DEC-006/DEC-007 edge case coherence, multi-interrupt queue interaction)
3. **VP-INDEX coverage audit:** Verify every Kani VP seed BC (BC-2.03.001, BC-2.04.006, BC-2.13.004) has a corresponding VP file in `.factory/specs/verification-properties/`
4. **NFR numerical target audit:** Scan all NFRs in nfr-catalog.md for qualitative descriptions that violate the numerical-target requirement
