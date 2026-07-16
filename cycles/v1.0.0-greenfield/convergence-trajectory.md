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
| P1D-13 | 2026-07-14 | 1 | 0 | 1 | 0 | 2 | LOW | 0/3 | FINDINGS_REMAIN (topology census — all fixed this pass) |
| P1D-14 | 2026-07-14 | 2 | 0 | 1 | 1 | 0 | LOW | 0/3 | FINDINGS_REMAIN (bidirectional anchor audit; VP-label bridge) |
| P1D-23 | 2026-07-14 | 1 | 0 | 1 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (HTTP endpoint coherence; NEW CLASS) |
| P1D-24 | 2026-07-14 | 2 | 0 | 1 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (wire-object field-set: Run completed_at/updated_at semantics; ThreadStatus enum; NEW CLASS: wire-object completeness) |
| P1D-83 | 2026-07-15 | 3 | 0 | 1 | 2 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (semantic-mis-anchor-and-partial-fix-residue: ADR-013 tools/list-vs-call BC swap + ToolCallDialect/ProviderFallbackPolicy anchor PC mis-citations) |

## Trajectory Shorthand

`→14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24)`

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

---

### Pass P1D-13 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 1 HIGH + 2 LOW (all fixed this pass)
**Findings delta:** 0 open vs pass 12 (1→1 open; 3 total items fixed in pass)
**Axes rotated:** domain-spec↔dependency-graph topology census (NEW CLASS); arrow-census re-run (guideline #12); BC-INDEX title 3-way; de-Canonical audit; E-code crate-roster collision scan; VP-seed cross-ref abbreviation
**Fix summary:** F-P13-01 HIGH — bounded-contexts.md dependency diagram inverted SDK-split topology (3 errors: false sdk→core edge; missing adapter→core edge; false graph→checkpoint edge). Topology census: 14 assertions, 2 FAIL + 1 MISSING — all fixed, 11 PASS. LOW-1: events.md:111 BC-2.10.002 citation (dangling "DI per append-only" resolved). LOW-2: FM-007 label separated from DI invariants in bounded-contexts.md:82 (type-system split). All 4/4 sibling checks PASS; lifecycle-arrow census CONVERGED (guideline #12 re-run PASS).
**New standing gates:** domain-spec↔dependency-graph topology census (trigger: any domain-spec shard or dependency-graph.md edit); command: `grep -rn "← ferro\|depends on ferro\|standalone.*dep\|zero.*dep" .factory/specs/domain-spec/` vs dependency-graph.md §Edge Table.
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4→4→1→1
**Counter:** 0/3

---

### Pass P1D-14 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 2 findings (0 CRIT, 1 HIGH, 1 MED, 0 LOW)
**Findings delta:** +1 vs pass 13 (1→2); two independent root causes
**Axes rotated:** L2-INDEX Key-Anchors bidirectional audit (NEW CLASS: cross-ref index columns); VP-label orphan census; FM count propagation; VP-label collision census (86 BCs)
**Fix summary:**
- F-P14-01 HIGH — L2-INDEX Key-Anchors column: FM-007 and FM-010 anchors both pointed at failure-modes.md row 7 (double-use tell). 3 mis-anchors corrected. FM-013 (Sandbox-Without-Enforcement) and FM-014 (Constructor-Panics) authored to fill gaps. Full 14-row four-column bidirectional audit (L2-INDEX Key-Anchors ↔ failure-modes.md anchors ↔ DEC section ↔ FM label) = PASS. FM count propagated 12→14 across all index files.
- F-P14-02 MED — VP-MCP-04 orphan label in BC-2.09.004 and BC-2.09.005: vp_id field pointed at non-canonical label. VP-004 canonical label confirmed (VP-INDEX). vp_id bridges added to both BC-2.09.004 and BC-2.09.005. VP-label collision census: 86 BCs scanned, 1 collision found and resolved. Phase-3-integration column added to verification-coverage-matrix.md; full titles populated across coverage matrix.
**New standing gates:** L2-INDEX FM/DEC bidirectional audit (trigger: any failure-modes.md or L2-INDEX edit; command: verify Key-Anchors cross-refs are unique per row); VP-label collision census (trigger: any BC vp_id or VP-INDEX label change)
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4→4→1→1→2
**Counter:** 0/3

---

### Pass P1D-21 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 1 finding (0 CRIT, 1 HIGH, 0 MED, 0 LOW)
**Findings delta:** -2 vs pass 20 (3→1); new class resolved
**Axes rotated:** capability-tier ↔ BC-priority census (NEW CLASS); inputs-arrays frontmatter; holdout-vs-CAP coverage; prd §1-4 + brief prose fresh reads
**Fix summary:** F-P21-01 HIGH — CAP-012 (Observability & Monitoring), CAP-013 (Content Provenance & Safety Guardrails), CAP-016 (Structured Output & Streaming Compliance) stuck at P1/Wave-2 in L2-INDEX while D17 elevation made all constituent BCs P0. NEW CLASS: capability-tier ↔ BC-priority. CAPs elevated to P0 in L2-INDEX [P0 11 / P1 5 / P2 3]; relocated to capabilities-p0.md with D17-elevation notes; capabilities-p1-p2.md restructured. 19-row capability-tier census: 16 MATCH / 3 FIXED / 0 mismatch — class drained. All other censuses + 3 novel probes PASS (inputs-arrays, holdout-vs-CAP, prose reads converged). Orchestrator verified BC wave frontmatter unaffected [report artifact only].
**New standing gates:** capability-tier census (trigger: any L2-INDEX CAP priority or wave change; command: cross-check CAP priority/wave tier vs BC P-levels for all constituent BCs)
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1
**Counter:** 0/3

---

### Pass P1D-23 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 1 finding (0 CRIT, 1 HIGH, 0 MED, 0 LOW)
**Findings delta:** 0 vs pass 22 (1→1); NEW CLASS: HTTP endpoint coherence
**Axes rotated:** HTTP endpoint URL-scheme sweep (NEW CLASS); status-code↔E-code census (NEW CLASS); api-surface completeness probe
**Fix summary:** F-P23-01 HIGH — 8 files with flat `/runs/...` paths resolved to thread-nested. Adopted canon: RUNS = `/threads/{thread_id}/runs/...`; SCHEDULES = `/schedules/{cron_id}` (flat); `GET /runs?schedule_id=` = only intentional flat run path (cross-thread aggregate). interface-definitions §Cron Schedules fixed (nested→flat, PATCH added, cross-thread query row added). api-surface.md rebuilt (7 run rows + list + cancel + DELETE + PATCH schedules + GET /assistants list). prd.md §3 path summary updated. BC-2.05.005 HTTP 409→422 for E-GRAPH-002 (status-code census fix). Guideline #17 added to bc-authoring-plan.md.
**New standing gates:** HTTP endpoint census gate (guideline #17); trigger: any endpoint path change; command: grep for flat `/runs/` with no `threads/` prefix.
**Trajectory after:** ...→3→1→1→2→1→1→1→4→2→3→1→1→1
**Counter:** 0/3

---

### Pass P1D-22 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 1 finding (0 CRIT, 1 HIGH, 0 MED, 0 LOW)
**Findings delta:** 0 vs pass 21 (1→1); new dimension of pass-21 relocation
**Axes rotated:** reverse-anchor sweep (NEW CLASS: relocation must be followed by grep in both directions); sibling-check pass-21 (capability-tier census re-run); 4 standing census rotations
**Fix summary:** F-P22-01 HIGH — pass-21 relocation of CAP-012/013/016 to capabilities-p0.md covered the forward dimension (L2-INDEX CAP tier) but the 16 constituent P0 BCs across ss-10 (×4), ss-11 (×6), ss-14 (×6) still held traces_to/inputs/justification anchors pointing at capabilities-p1-p2.md. Reverse-anchor grep confirmed all 16 sites; each BC re-anchored to capabilities-p0.md; input-hashes refreshed (all 16 STALE→UPDATED, 0 FAILED). Zero residue confirmed: `grep -r "capabilities-p1-p2" .factory/specs/behavioral-contracts/ss-10 ss-11 ss-14` = empty.
**New standing gates:** reverse-anchor sweep (trigger: any CAP relocation between capabilities-p0/p1-p2/p2 files; command: grep all BC files for the old anchor path in both traces_to and inputs fields)
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1
**Counter:** 0/3

---

### Pass P1D-24 Details

**Date:** 2026-07-14
**Verdict:** NOT CLEAN — 2 findings + 3 observations (0 CRIT, 1 HIGH, 1 MED, 0 LOW)
**Findings delta:** +1 vs pass 23 (1→2); NEW CLASS: wire-object completeness
**Axes rotated:** wire-object field-set census (NEW CLASS: interface-definitions ↔ entities-server ↔ BCs three-way); status-code table E-SERVER exclusions; Thread.status/ThreadStatus enum presence; api-surface {cron_id} path params; bc-authoring-plan gate #18 wire-object
**Fix summary:** (1) F-P24-01 HIGH — Run completed_at/updated_at semantics three-way inconsistency: interface-definitions had `updated_at` as "last state transition timestamp" (wrong — that is completed_at's role); `completed_at` terminal-only semantics not annotated. Fixed: interface-definitions Run schema annotated (`updated_at` = last activity; `completed_at` = terminal states only, null while in-progress); entities-server Run struct completed_at field added with terminal-only semantics note. (2) F-P24-02 MED — Thread.status/ThreadStatus enum undefined in entities-server; Assistant fields not present; CronSchedule last_fired_at missing. Fixed: entities-server Thread.status: ThreadStatus added; ThreadStatus enum defined (idle/busy/interrupted); Assistant struct fields defined; CronSchedule last_fired_at added. (3) OBS-01 — BC-2.12.003 lacked wire-object completeness postcondition → PC13 added. (4) OBS-02 — api-surface {cron_id} path params missing in 3 endpoint rows → added. (5) OBS-03 — bc-authoring-plan gate 17C fix + gate #18 wire-object census added.
**Full wire-object census (21 rows):** PASS. Run/Thread/Assistant/CronSchedule/Message/ToolCall/ToolResult/Checkpoint all covered.
**Open probe for pass 25:** E-SERVER-016 HTTP status row missing from status-code table (observed but not gated yet).
**New standing gates:** wire-object census gate (gate #18; trigger: any new entity field addition; command: three-way cross-check interface-definitions ↔ entities-server ↔ BC wire-object postconditions).
**Trajectory after:** 14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2
**Counter:** 0/3
