---
document_type: convergence-trajectory
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-14T15:30:00Z
cycle: v1.0.0-greenfield
inputs: [adversarial-reviews/]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Convergence Trajectory — v1.0.0-greenfield

## Finding Progression

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|---------|---------|
| P1D-1 | 2026-07-14 | 14 | 2 | 5 | 4 | 3 | HIGH | 0/3 | FINDINGS_REMAIN |
| P1D-2 | 2026-07-14 | 5 | 1 | 3 | 1 | 0 | HIGH | 0/3 | FINDINGS_REMAIN |
| P1D-3 | 2026-07-14 | 7 | 2 | 3 | 2 | 0 | HIGH | 0/3 | FINDINGS_REMAIN |
| P1D-4 | 2026-07-14 | 13 | 1 | 7 | 3 | 2 | HIGH | 0/3 | FINDINGS_REMAIN (re-baseline) |
| P1D-5 | 2026-07-14 | 3 | 0 | 1 | 1 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN (decaying) |
| P1D-6 | 2026-07-14 | 3 | 0 | 1 | 2 | 0 | LOW | 0/3 | FINDINGS_REMAIN |
| P1D-10 | 2026-07-14 | 4 | 0 | 2 | 2 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN |
| P1D-11 | 2026-07-14 | 4 | 0 | 1 | 3 | 0 | LOW | 0/3 | FINDINGS_REMAIN |
| P1D-12 | 2026-07-14 | 1 | 0 | 1 | 0 | 0 | LOW | 0/3 | FINDINGS_REMAIN (single root cause, decayed) |

## Trajectory Shorthand

`→14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12)`

## Per-Pass Details

### Pass P1D-1 (2026-07-14)

**Findings:** 14 (2 CRIT, 5 HIGH, 4 MED, 3 LOW)
**Novelty:** HIGH
**Convergence counter:** 0 of 3
**Coverage level:** Level 2 (partial — BCs and prd-supplements primary; deferred: brief, domain-spec shards, ADR bodies, VP bodies, architecture sections, holdout briefs)

Key findings:
- CRIT-1: E-GRAPH error code collisions — same structural class as E-SERVER; globally reconciled to 15 canonical E-GRAPH-xxx codes incl. E-GRAPH-013 SECURITY (approver-role authorization failure)
- CRIT-2: DELETE-vs-cancel contradiction — REST DELETE /runs/{id} vs server-side cancel semantics; POST /runs/{id}/cancel endpoint added
- HIGH-1: Canonical run state machine (queued→in_progress→completed|failed|interrupted|cancelled) not consistently propagated
- HIGH-2: SCHEDULED channel semport fix — verified against Python reference corpus
- HIGH-3..5: Additional HIGH findings across BC-2.04, BC-2.11, BC-2.13 subsystems

All 14 findings fixed across 36 files in Burst 77.

**Deferred for Pass 2:** brief, domain-spec shards, ADR bodies, VP bodies, architecture section files, holdout briefs. Also: verify pass-1 fixes landed (sibling check); investigate E-GRAPH-005 anchor linkage vs BC-2.10.003 and E-BUDGET-001 orphan observation.

---

### Pass P1D-2 (2026-07-14)

**Findings:** 5 (1 CRIT, 3 HIGH, 1 MED)
**Novelty:** HIGH
**Convergence counter:** 0 of 3
**Coverage level:** Level 3 (sibling check pass-1 fixes; brief, domain-spec, ADR bodies, VP bodies)

Key findings:
- CRIT-1: budget-namespace regression-escape — Component: BUDGET added to error taxonomy, E-GRAPH-005 tombstoned
- HIGH-1: RetryHint triple-vocabulary canonicalized to Never/Maybe/Later
- HIGH-2: run-state propagation completed (grep-zero)
- HIGH-3: brief +sandbox/memory crates (R6 now 14 crates)
- MED-1: 12-component enum in api-surface + ADR-010

All 5 findings fixed. Burst 78.

---

### Pass P1D-3 (2026-07-14)

**Findings:** 7 (2 CRIT, 3 HIGH, 2 MED)
**Novelty:** HIGH (new axis: crate-topology incoherence)
**Convergence counter:** 0 of 3
**Coverage level:** Level 3 (sibling check pass-2; architecture sections, ADR bodies)

Key findings:
- CRIT-1: SS-15 memory — 3 contradictory crate-homes → canonical ferrochain-memory/MemoryStore
- CRIT-2: ADR-007 modules-vs-crates CONTRADICTED human D17-Q5 → ADR revised to standalone -sdk
- Canonical 18-crate roster established in ARCH-INDEX (was 12/14 drift)

All 7 findings fixed. Burst 79.

---

### Pass P1D-4 (2026-07-14)

**Findings:** 13 (1 CRIT, 7 HIGH, 3 MED, 2 LOW) [re-baseline: new lint axes opened]
**Novelty:** HIGH (new axes: sibling-subsystem sweep, category-enum lint)
**Convergence counter:** 0 of 3
**Coverage level:** Level 3+ (sibling-subsystem sweep: all 17 subsystems; category-enum lint: 13 non-canonical categories)

Key findings:
- CRIT-1: burst-79 fix claim never landed in prd RTM — evidence discipline failure
- HIGH-1..4: sibling-subsystem sweep (SS-16 retry = same class as SS-15 memory → ferrochain-core per DAG merit)
- HIGH-5..7: category-enum lint (13 non-canonical categories canonicalized)

META: fix claims now require inline grep evidence; 17-subsystem coherence table verified 0 mismatches. 13/13 FIXED. Burst 80.

---

### Pass P1D-5 (2026-07-14)

**Findings:** 3 (0 CRIT, 1 HIGH, 1 MED, 1 process-gap)
**Novelty:** MEDIUM (single axis: category/component representation)
**Convergence counter:** 0 of 3
**Coverage level:** Level 3+ (sibling check pass-4; complement-assertion mandate adopted)

Key findings:
- HIGH-1 (F-P5-01): fictitious categories (CheckpointError/StateUpdateError/ToolError) → canonical + disambiguating codes (BC-2.04.001 DURABILITY/E-CHKPT-001, BC-2.04.003 INTERNAL/E-CHKPT-002, BC-2.04.004 VAL/E-GRAPH-007)
- MED-1 (F-P5-02): PascalCase drift + BC-2.14.001 dual-rendering now explicit
- process-gap (F-P5-03): pass-4 grep evidence false-negative → COMPLEMENT-ASSERTION mandate adopted (full distinct-value tables, 4 justified exceptions)

All 3 fixed. Burst 81. Trajectory DECAYING.

---

### Pass P1D-6 (2026-07-14)

**Findings:** 3 (0 CRIT, 1 HIGH, 2 MED)
**Novelty:** LOW (residual vocab escape + plan staleness + status rule gap)
**Convergence counter:** 0 of 3
**Coverage level:** Level 4 (sibling-check pass-5 complement tables; bc-authoring-plan.md full body; status-field split rule; 5/5 spot rotation; 14/14 DIs anchored)

Key findings:
- HIGH-1 (F-P6-01): running-vocab regression escape — 2 flagged in BC-2.05.004; complement sweep caught 3 more in BC-2.05.005 → zero running-tokens after fix
- MED-1 (F-P6-02): bc-authoring-plan.md staleness (canonical lifecycle + title/count/Red-Gate sync)
- MED-2 (F-P6-03): status-field split rule undefined → rule defined: active once in BC-INDEX, 86× status active normalized

Sibling checks ALL PASS. 5/5 spot rotation GREEN. 14/14 DIs anchored. 3/3 FIXED w/ complement evidence. Burst 82.

---

<!-- Append pass rows chronologically. Each pass gets a Per-Pass Details subsection. -->

### Pass P1D-10 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 4 findings (2 HIGH, 2 MED)
**Findings delta:** +2 vs pass 9 (2→4)
**Axes rotated:** DI-description fidelity (NEW CLASS); ARCH-INDEX SS range growth propagation; PRD §5 component set assertion
**Fix summary:** DI-description census 86/86 canonical (3 exceptions fixed: BC-2.08.010 DI-008, BC-2.09.005 DI-014, BC-2.12.007 DI-011); ARCH-INDEX SS-08 range + preamble count; PRD §5 8→12 components; BC-2.12.003 ordinals sequential. Bonus: BC-2.09.005, BC-2.12.007 DI description canonicalized.
**New standing gates:** ARCH-INDEX SS range gate (trigger: new BC file); PRD §5 component gate (trigger: new component in error-taxonomy.md)
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4
**Counter:** 0/3

---

### Pass P1D-11 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 4 findings (0 CRIT, 1 HIGH, 3 MED)
**Findings delta:** +0 vs pass 10 (4→4)
**Axes rotated:** cross-BC state-machine consistency (NEW CLASS); DI verbatim rule codification; RTM completeness (CAP-016); E-SBXD error-code completeness
**Fix summary:** BC-2.12.003 interrupted→pausable (HITL P0 fix); terminal-set={completed,failed,cancelled} censused; DI verbatim rule codified + 7 interface-definitions cells normalized, 86/86 census; RTM CAP-016 ×2 rows added; E-SBXD-004/005 added to error-taxonomy + BC-2.13.006 citations; Wave 0 registered in system-overview wave table with crate-wave vs story-wave distinction.
**New standing gates:** cross-BC state-machine sweep (trigger: new stateful subsystem); DI verbatim census (trigger: interface-definitions edit)
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4→4
**Counter:** 0/3

---

### Pass P1D-12 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 1 finding (0 CRIT, 1 HIGH, 0 MED, 0 LOW)
**Findings delta:** -3 vs pass 11 (4→1); single root-cause cluster
**Axes rotated:** lifecycle-arrow representation census (NEW); sibling-checks pass-11 (terminal-set, DI verbatim, RTM, E-SBXD); BC-2.05.002 HITL coherence with updated BC-2.12.003
**Fix summary:** F-P12-01 HIGH — pass-11 fix keyed on 'terminal' keyword; 8 lifecycle-arrow sites stale across 6 files incl. entities-server (source-of-truth domain entity) and 2 "Canonical"-labeled sites in interface-definitions.md. Full state-machine sweep all other subsystems (checkpoint lifecycle, budget escalation, circuit-breaker, graph) CONSISTENT. Fixed 9 occurrences across 8 sites; BC-2.12.003 title 3-way verbatim (BC-INDEX + prd.md + bc-authoring-plan) PASS. Arrow-census gate added to bc-authoring-plan.md §Authoring Guidelines as guideline #12 (16 hits PASS post-fix).
**New standing gates:** Arrow-representation census gate (guideline #12); trigger: any lifecycle or state-machine spec edit. Command: `grep -rn "in_progress →\|in_progress→\|→ interrupted\|⇄" .factory/specs/` — every hit must show interrupted as pausable, terminal={completed,failed,cancelled}.
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4→4→1
**Counter:** 0/3
