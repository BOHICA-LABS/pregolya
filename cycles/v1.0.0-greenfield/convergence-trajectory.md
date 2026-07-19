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
| P1D-86 | 2026-07-16 | 2 | 0 | 0 | 0 | 0 | LOW | 0/3 | FINDINGS_REMAIN (2 OBS: template-stub TODO markers + gate #28 Rule 5 document-type scope; both fixed same burst; D18-P86-A) |
| P1D-91 | 2026-07-17 | 4 | 0 | 1 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (budget-cluster content-layer: on_ceiling mis-anchor to BudgetPolicy TRAIT + BudgetConfig/OnCeiling undefined in interface-definitions + E-MEMORY-008 minted; D18-P91-A/B) |
| P1D-92 | 2026-07-17 | 2 | 0 | 1 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (budget-cluster echo: BudgetPolicy-owns-data TV/PC residue + RunnableConfig::budget_config field gap; D18-P92-A) |
| P1D-93 | 2026-07-17 | 5 | 0 | 2 | 2 | 0 | HIGH | 0/3 | FINDINGS_REMAIN (budget-cluster model-level: entities-server invented fields + HITL-trigger contradiction + VP collision class new; D18-P93-A/B) |
| P1D-94 | 2026-07-17 | 3 | 0 | 0 | 3 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (SS-10 burst-175 fix radius: TV-001b→TV-006 renumber + BC-2.10.001 Deny monolithic residue + BC-INDEX trailing annotation) |
| P1D-95 | 2026-07-17 | 5 | 0 | 0 | 2 | 2 | MEDIUM | 0/3 | FINDINGS_REMAIN (ADR eval-timing + gate #13 regex inert for multi-segment VPs + BC-2.10.004 PC lettered sub-numbering + CAP-012 three-mode omission; VP-SPLIT renumber) |
| P1D-96 | 2026-07-17 | 1 | 0 | 0 | 0 | 0 | LOW | 0/3 | FINDINGS_REMAIN strict; CLEAN PR-merge (59 BC Module placeholders [process-gap]) |
| P1D-97 | 2026-07-17 | 5 | 0 | 1 | 1 | 3 | HIGH | 0/3 | FINDINGS_REMAIN (semantic residue-class: burst-178 literal sweep missed semantic variant phrasing) |
| P1D-98 | 2026-07-17 | 1 | 0 | 0 | 0 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN strict; CLEAN PR-merge (bc-authoring-plan gate #27 claim-vs-artifact echo) |
| P1D-99 | 2026-07-17 | 1 | 0 | 0 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (OBS adjudicated substantive → D18-P99-A: GuardrailDecision StreamEvent scope expansion) |
| P1D-100 | 2026-07-17 | 3 | 0 | 0 | 2 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (D18-P99-A propagation echo: SS-11 RAG/Memory boundary symmetry gap + events.md vocabulary) |
| P1D-101 | 2026-07-17 | 2 | 0 | 0 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN strict (1 MED [process-gap] + 1 OBS; final D18-P99-A radius residue + BC-2.11.002 changelog order); CLEAN PR-merge |
| P1D-102 | 2026-07-17 | 2 | 0 | 0 | 0 | 1 | LOW | 0/3 | FINDINGS_REMAIN strict; CLEAN PR-merge (1 LOW F-P102-01 + 1 OBS/process-gap F-P102-OBS-A; gate #28 Rule 6 VERSION-MONOTONICITY minted; D18-P102-A; bc-authoring-plan v2.31) |
| P1D-103 | 2026-07-18 | 2 | 0 | 0 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge (1 MED F-P103-01 nfr-catalog direction + 1 OBS/process-gap OBS-P103-A gate #28 Rule 6 direction-blind census; five-class hook-aligned model adopted; D18-P103-A; bc-authoring-plan v2.32) |
| P1D-104 | 2026-07-18 | 1 | 0 | 0 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge (1 MED F-P104-01 ARCH-INDEX.md missing v1.1 changelog row; reconstructed from git history via burst-187; architect; changelog-completeness new class) |
| P1D-105 | 2026-07-19 | 1 | 0 | 0 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge (1 MED F-P105-01 SECURITY description omits 2/3 members + contradicts E-SBXD-002 POLICY; 2 OBS: OBS-P105-A adjudicated SECURITY/POLICY rule; OBS-P105-B Form-B self-correction process-gap; error-taxonomy v1.18→v1.19; bc-authoring-plan v2.32→v2.33) |

## Trajectory Shorthand

`→14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24) →2 (P1D-86) →2 (P1D-87) →4 (P1D-88) →4 (P1D-89) →1 (P1D-90, census-closure) →4 (P1D-91) →2 (P1D-92) →5 (P1D-93) →3 (P1D-94) →4 (P1D-95) →1 (P1D-96) →5 (P1D-97) →1 (P1D-98) →1 (P1D-99) →3 (P1D-100) →2 (P1D-101) →2 (P1D-102) →2 (P1D-103) →1 (P1D-104) →1 (P1D-105) →2 (P1D-112)`

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

---

### Pass P1D-86 Details

**Date:** 2026-07-16
**Verdict:** NOT CLEAN (strict) — 2 OBS findings, CLEAN (PR-merge) — zero CRIT/HIGH/MED
**Findings delta:** -2 vs pass 85 (4→2); all OBS, both fixed same burst
**Axes rotated:** template-stub sweep (test-vectors TODO markers); gate #28 Rule 5 document-type scope (D18-P86-A); purity-boundary-map v1.2 recount 58=22/28/8 + 3 anchor citations + 35-module completeness; test-vectors 512=503+9 recount; error-code census 85=43+16+26; gate #19 retired-name full-tree; gate #13 anchor-matrix spot; gate #28 Rules 1–5 on all touched files; sibling-checks 3/3
**Fix summary:** F-P86-01 OBS — test-vectors.md v1.6 carried 2 [TODO:] markers in Per-Subsystem Test Vectors and Cross-Subsystem Integration Vectors template-conformance stub sections; FIXED: authoritative forward-reference wording; test-vectors → v1.7. F-P86-02 OBS [process-gap] — gate #28 Rule 5 FRONTMATTER-CURRENCY as written contradicted BC-corpus timestamp convention; ADJUDICATED D18-P86-A Option B: scoped by document type (supplements = newest changelog date; BCs = v1.0 authoring date); FIXED: bc-authoring-plan → v2.19; module-criticality timestamp corrected 2026-07-14→2026-07-15; both supplements input-hashes normalized to 7-char form. Zero corpus violations under scoped rule (9-file verification).
**New standing gates:** none (Rule 5 narrowed in scope, not widened; gate count stays 33)
**Trajectory after:** →2 (P1D-86)
**Counter:** 0/3

### Pass P1D-87 Details

**Date:** 2026-07-17
**Verdict:** NOT CLEAN (strict) — 1 HIGH + 1 MED; NOT CLEAN (PR-merge) — HIGH present
**Findings delta:** same count as pass 86 (2 findings); severity escalated OBS→HIGH/MED
**Axes rotated:** gate #28 Rules 1–5 self-consistency check (F-P87-01 Rule 1 vs Rule 5 contradiction); input-hash corpus census (F-P87-02 format uniformity); gate #33 spot PASS; hedge sweep PASS; gates #19/#25/census-recompute/version-pin PASS; sibling-checks: test-vectors v1.7 PASS; bc-authoring-plan v2.19 PARTIAL (Rule-1 gap); module-criticality PARTIAL (hash format); gate #28 scoped PASS post-fix
**Fix summary:** F-P87-01 HIGH (PO) — gate #28 Rule 1 contradicted D18-P86-A Rule 5 BC-file scoping; FIXED: Rule 1 scoped supplements-only; 5-rule decision tree with `introduced:` entry predicate written for DEFER-002 linter; bc-authoring-plan → v2.20 (D18-P87-A). F-P87-02 MED (PO) — input-hash format split 7-char MD5 vs 64-char SHA; FIXED: canonical = 7-char MD5 declared; gate #34 INPUT-HASH FORMAT CONSISTENCY minted (zero-exception; `[live-index]` sole exception); corpus normalized 95/95 BCs + 6/6 supplements; bc-authoring-plan → v2.21→v2.22 (D18-P87-B).
**New standing gates:** gate #34 INPUT-HASH FORMAT CONSISTENCY (total 33→34)
**Incidental:** hook-forced template compliance on ~98 BC files (lifecycle frontmatter blocks added); error-taxonomy/interface-definitions section renames/additions (non-content-mutating)
**Trajectory after:** →2 (P1D-87)
**Counter:** 0/3

---

### P1D-88 — Pass 88 (2026-07-17, burst 168)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|---------|---------|
| P1D-88 | 2026-07-17 | 4 | 0 | 0 | 2 | 2 | MEDIUM | 0/3 | FINDINGS_REMAIN |

**Axes rotated:** gate #34 input-hash currency (F-P88-01 cascade); gate #28 Rules 1–5 rename-residue check (F-P88-02); bc-authoring-plan changelog completeness (F-P88-03); SS-TBD historical form (F-P88-04); gate #34 architecture-tree census (8 files; PASS); error-code census 85 (PASS); hedge sweep (PASS); gate #28 scoped on all 07-17 files (PASS); sibling-checks 5/5 (3 PASS, 2 → findings F-P88-01).
**Fix summary:** F-P88-01 MED (PO) — error-taxonomy + interface-definitions body-modified at burst 167 without version/changelog/timestamp propagation; FIXED: error-taxonomy → v1.17 (ts 07-17), interface-definitions → v2.28 (ts 07-17); cascade: BC-2.07.001 hash → 0e9aa46, BC-2.14.001/002 → 0a1320f. F-P88-02 MED (PO) — bc-authoring-plan gate prose had rename residue ("Error Category Codes table" → "Error Categories table" in gates #16/#22; "Flag Interaction Rules" → "Flag Interactions" in gate #29); FIXED: zero live old-name refs. F-P88-03 LOW (PO) — bc-authoring-plan v2.8/v2.9 changelog rows missing; RECONSTRUCTED from git archaeology (v2.8 = burst 143 gate #21 sub-check; v2.9 = burst 145 gate #20 AUTH/POLICY/INTERNAL widening). F-P88-04 LOW (PO) — ss_tbd_note frontmatter + guideline #1 in bc-authoring-plan still in present-tense assertion form; FIXED: rewritten to historical/RESOLVED form.
**Architecture tree (routed follow-through, complete):** 8-file hash census in architecture/ — api-surface e595e17, ARCH-INDEX e44c5e2, dependency-graph 8a78228, module-decomposition 41235f3, system-overview 90d28fa, tooling-selection aae3d13, verification-architecture 243128a, verification-coverage-matrix bdd28b4; purity-boundary-map already current (3bcecc0); ADRs carry no input-hash fields. Zero drift.
**Trajectory after:** →4 (P1D-88)
**Counter:** 0/3

---

### P1D-89 — Pass 89 (2026-07-17, burst 171)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|---------|---------|
| P1D-89 | 2026-07-17 | 4 | 0 | 1 | 2 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN |

**Axes rotated:** gate #34 census block audit (F-P89-01 structural no-values rule); bc-authoring-plan frontmatter hash chain verification (F-P89-02); nfr-catalog deferral language + hash currency (F-P89-03); BC-2.08.006 SS-TBD class sweep (F-P89-04); D18-P88-A full-tree inputs: sweep (PASS); error-code census 85 (PASS); retired-name sweeps (PASS); VP-INDEX arithmetic (PASS); verification-architecture v1.3 (PASS); hedge sweep (PASS); gate #28 scoped all 07-17 files (PASS).
**Fix summary:** F-P89-01 HIGH [process-gap] (PO) — gate #34 census block embedded stale per-file hash values asserting false PASS; STRUCTURAL FIX: per-file hash values NEVER in gate text; frontmatter = single source of truth; bc-authoring-plan → v2.25. F-P89-02 MED (PO) — bc-authoring-plan frontmatter hash e786fea contradicted v2.24 changelog (e238778); full chain documented (90d28fa→e238778→e786fea→41c29d9); frontmatter = 41c29d9. F-P89-03 MED (PO) — nfr-catalog "pending recomputation" deferral language + stale pre-removal hash; FIXED: v1.2, hash 2153125→0f05a12, deferral language closed. F-P89-04 LOW (PO) — BC-2.08.006 PC-3 stale "(or SS-TBD is used as a placeholder)" clause dropped; v1.2; hash 8095694→412902d.
**Corpus hash-currency sweep (D18-P89-A first execution):** 4/6 supplements DRIFT (error-taxonomy f766c52/c987193; interface-definitions cdce094/841e167; module-criticality 2ed30d9/68e4fbf; test-vectors 5c68c70/2154b7b) + 94/95 BCs STALE; ALL refreshed to TOTAL MATCH (coherence verified passes 88-89). D18-P89-A standing step codified.
**Trajectory after:** →4 (P1D-89); cumulative tail →2→2→4→4
**Counter:** 0/3

---

### P1D-90 — Pass 90 (2026-07-17, burst 172)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|---------|---------|
| P1D-90 | 2026-07-17 | 1 | 0 | 0 | 0 | 1 | LOW | 0/3 | FINDINGS_REMAIN (census-closure) |

**Adversary verdict (read-only):** CLEAN(strict) — all standard gates PASS; coverage caveat: D18-P89-A hash-currency census delegated to state-manager.
**State-manager census closure (D18-P89-A standing step):** ARCH-INDEX.md hash drift: stored=edabdee, computed=065003c. Root cause: burst-171 D18-P89-A sweep refreshed prd.md + module-criticality.md (both in ARCH-INDEX inputs:) without cascading to ARCH-INDEX itself (authority-split blind spot: D18-P89-A scope only covered directly-edited files, not files referencing them). ARCH-INDEX last touched burst 169 (1a915c6).
**D18-P90-A adjudication (orchestrator):** Hash-only refreshes are state-manager-executable corpus-wide regardless of content authority. D18-P89-A sweep scope EXTENDED: cascade to all files whose inputs: lists reference any edited file (transitive, until census TOTAL MATCH).
**Fix summary:** ARCH-INDEX.md input-hash refreshed (edabdee→065003c). Full post-fix census: supplements 6/6, BCs 95/95, arch 9/9, domain-spec 15/15, prd 1, product-brief 1 = TOTAL MATCH 126/126.
**Effective verdict:** NOT CLEAN (1 census-closure finding). Adversary spec-content verdict: CLEAN(strict).
**Trajectory after:** →1 (P1D-90, census-closure); cumulative tail →2→4→4→1
**Counter:** 0/3 (census-closure finding prevents streak advancement; effective NOT CLEAN per D14 strict-zero)

---

### P1D-91 — Pass 91 (2026-07-17, burst 173)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|---------|---------|
| P1D-91 | 2026-07-17 | 4 | 0 | 1 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (budget-cluster content-layer) |

**Axes rotated:** SS-10 BC trio + CAP-012 on_ceiling attribution audit (F-P91-01); interface-definitions completeness for budget types (F-P91-02); TOML default_on_ceiling Summarize exclusion (F-P91-03); BC-2.15.004 EC-004 error-code semantic (F-P91-04); retired-name sweeps (PASS); gate #33 9-code census (PASS); error-code census 85 (PASS); hedge sweep (PASS).
**Fix summary:** F-P91-01 HIGH (PO+BA) — SS-10 BC trio + CAP-012 attributed on_ceiling to BudgetPolicy TRAIT (impossible — pure trait carries no data field); canon = BudgetConfig STRUCT; FIXED: BC-2.10.001 v1.2, BC-2.10.003 v1.5, BC-2.10.004 v1.2, BC-2.06.003 v1.1, capabilities-p0 v1.2; post-fix corpus grep zero residual (TVs/PCs not swept — residue carried to P92). F-P91-02 MED (architect) — OnCeiling + BudgetConfig undefined in interface-definitions; FIXED: v2.29 adds full defs + engine-branches-on-config prose; siblings module-decomposition v1.9 + purity-boundary-map v1.4. F-P91-03 OBS (architect) — TOML Summarize omitted; ADJUDICATED: bare-string default intentionally excludes Summarize. F-P91-04 OBS (PO) — E-MEMORY-008 MemoryStoreReadFailed MINTED (DURABILITY/broken/Maybe); BC-2.15.004 v1.1; error-taxonomy v1.18; interface-definitions v2.30; census 85→86 = 43+16+27.
**D18-P91-A:** on_ceiling canon = BudgetConfig STRUCT. **D18-P91-B:** E-MEMORY-008 minted; census 86 = 43+16+27.
**Trajectory after:** →4 (P1D-91); cumulative tail →4→4→1→4
**Counter:** 0/3

---

### P1D-92 — Pass 92 (2026-07-17, burst 174)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|---------|---------|---------|
| P1D-92 | 2026-07-17 | 2 | 0 | 1 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (budget-cluster echo) |
| P1D-97 | 2026-07-17 | 5 | 0 | 1 | 1 | 3 | HIGH | 0/3 | FINDINGS_REMAIN (semantic residue-class: variant deferral-actor phrasing survived literal sweep) |

**Axes rotated:** SS-10 BC TV/PC residue audit (F-P92-01 partial-fix echo); RunnableConfig::budget_config field existence (F-P92-02 interface-gap); error-code census 86 = 43+16+27 recount (PASS); E-MEMORY-008 anchor (PASS); interface-definitions OnCeiling/BudgetConfig defs (PASS); module-decomposition/purity-map inventories (PASS); CAP-012 (PASS); NE-01/02/11/12/13/14 tracing (PASS); gate #33 9-code sample (PASS); no duplicate changelog rows.
**Fix summary:** F-P92-01 HIGH (PO) — BC-2.10.003 TV-001/007 + BC-2.10.004 PC6 still said "BudgetPolicy" in data-bearing forms; FIXED: TV-001 → "BudgetConfig halt", TV-007 → "BudgetConfig with token ceiling", PC6 → "patch RunnableConfig::budget_config"; exhaustive multi-pattern sweep terminal; BC-2.10.003 v1.6, BC-2.10.004 v1.3. F-P92-02 MED (architect+PO+BA — D18-P92-A) — RunnableConfig had no budget_config field despite BC-2.10.003 PC7 + BC-2.10.004 PC6 naming it as resume patch target; ADJUDICATED OPTION A: RunnableConfig gains `budget_config: Option<BudgetConfig>` (per-run override; None = inherit GraphConfig::budget_config); GraphConfig mutation rejected (concurrent-run race defect); FIXED: interface-definitions v2.32 (§RunnableConfig 4-field struct + BudgetResume::Extend prose), api-surface v1.4 (RunnableConfig row), module-decomposition v1.10 (budget note), entities-server v1.6 (BudgetConfig entity + trait split + ER line corrected); entities-graph swept clean.
**D18-P92-A:** RunnableConfig::budget_config: Option<BudgetConfig> — per-run override, None = inherit GraphConfig::budget_config; GraphConfig mutation rejected.
**Trajectory after:** →2 (P1D-92); cumulative tail →4→1→4→2
**Counter:** 0/3

---

### P1D-93 — Pass 93 (2026-07-17, burst 175)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-93 | 2026-07-17 | 5 | 0 | 2 | 2 | 0 | 1 | HIGH | 0/3 | FINDINGS_REMAIN (budget model-level cluster + VP ID collision class) |

**Axes rotated:** entities-server §BudgetConfig/§EvidenceJournal verbatim-canon (F-P93-01 BA drift); HITL trigger model coherence across interface-definitions + BC-2.10.004 + BC-2.10.001 (F-P93-02 contradiction); CAP-012 verbatim quote in BC-2.10.004 (F-P93-03 staleness); VP-BUDGET-05 ID collision BC-2.10.003 vs BC-2.10.004 (F-P93-04); gate #13/#14 BC-local VP uniqueness census gap (OBS-P93-01 process-gap).
**Fix summary:** F-P93-01 HIGH (BA) — entities-server v1.7 verbatim-canon transcription; BudgetConfig fields/OnCeiling variants/EvidenceEntry corrected; residue sweep zero. F-P93-02 HIGH (architect+PO — D18-P93-A) — Model A adopted: PolicyDecision::Escalate ALWAYS HITL unconditional; PolicyDecision::Deny branches on on_ceiling (Halt/Escalate→HITL/Summarize); 5-row decision table in interface-definitions v2.33; BC-2.10.004 v1.4 dual-path (PC1a/PC1b, PC2/PC2b, TV-001b); BC-INDEX title cite. F-P93-03 MED (PO) — CAP-012 quote updated to v1.2 verbatim in BC-2.10.004 v1.4. F-P93-04 MED (PO) — VP-BUDGET-05 collision: BC-2.10.004 keeps canonical; BC-2.10.003 VP-BUDGET-05→VP-BUDGET-07; BC-2.10.003 v1.7. OBS-P93-01 [process-gap] (PO) — gate #13 VP-uniqueness sub-check + census command; bc-authoring-plan v2.26; in-burst census caught VP-STREAM-02 collision (BC-2.06.001 vs BC-2.06.002) — BC-2.06.002 v1.1 VP-STREAM-02→VP-STREAM-04; corpus-wide census zero duplicates.
**D18-P93-A:** PolicyDecision::Escalate (soft-ceiling) → HITL ALWAYS unconditional; PolicyDecision::Deny (hard-ceiling) branches on on_ceiling (Halt/Escalate/Summarize). 5-row decision table in interface-definitions v2.33.
**D18-P93-B:** Cost-based ceilings NOT v1 scope; CAP-012 cost-metering satisfied by JournalEntry.token_usage.estimated_cost (BC-2.10.002 PC2); scope note in BC-2.10.001 v1.3 Traceability.
**Hash sweep:** 7/126 stale (api-surface.md + 6 BCs with entities-server.md in inputs); updated; 126/126 TOTAL MATCH.
**Trajectory after:** →5 (P1D-93); cumulative tail →4→1→4→2→5
**Counter:** 0/3

---

### P1D-94 — Pass 94 (2026-07-17, burst 176)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-94 | 2026-07-17 | 3 | 0 | 0 | 3 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (SS-10 burst-175 fix radius echo) |

**Axes rotated:** BC-2.10.004 TV-001b stale / lettered sub-vector anomaly (F-P94-02 PO); BC-2.10.001 Deny monolithic characterization without dispatch branching (F-P94-03 propagation echo); BC-INDEX byte-exact title sync broken by trailing italic annotation (F-P94-01 state-manager).
**Fix summary:** F-P94-02 MED (PO) — TV-001b RENAMED → TV-006 (eliminates only lettered sub-vector in corpus; zero special-case conventions); BC-2.10.004 v1.5; test-vectors v1.8 (row 5→6 + Notes; SS-10 subtotal 22→23; canonical TVs 503→504; GRAND TOTAL 512→513 = 504+9). F-P94-03 MED (PO) — BC-2.10.001 v1.4: Description + PC3 three-way dispatch block (Halt→BC-2.10.003 / Escalate→BC-2.10.004 PC1b+PC2b / Summarize→BC-2.10.003 PC8); Related-BCs dual-path; EC-004 "(with on_ceiling=Halt in this scenario)"; bonus: BC-2.10.002 v1.2 (TV-002 Note + Related-BCs "before engine dispatch"); events.md v1.2 (BudgetEvaluated Outcome dispatch-per-on_ceiling). F-P94-01 MED (state-manager) — BC-INDEX.md v1.5: BC-2.10.003 row trailing italic annotation deleted; byte-exact H1 match.
**Hash sweep:** BC-INDEX/STATE.md live-index/live-state exempted; no spec content staled by burst-176 edits; TOTAL MATCH.
**Trajectory after:** →3 (P1D-94); cumulative tail →1→4→2→5→3
**Counter:** 0/3

---

### P1D-95 — Pass 95 (2026-07-17, burst 177)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-95 | 2026-07-17 | 4 | 0 | 0 | 2 | 2 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN (ADR budget-placement reconciliation; gate #13 regex; BC PC restructure; CAP-012 three-mode) |

**Axes rotated:** ADR-001/009/012 budget evaluation "between super-steps" vs BC canon per-call-during-Collecting (F-P95-01 architect); gate #13 VP-census regex inert for multi-segment/digit-bearing IDs — 50 VPs invisible (F-P95-02 process-gap); BC-2.10.004 PC verbatim duplicate + malformed 1a/1b/2/2b numbering (F-P95-03); CAP-012 omitted D20 Summarize mode (F-P95-04 BA); VP-SPLIT 3-digit width (OBS-P95-A).
**Fix summary:** F-P95-01 MED (architect) — ADR-001 rev-2: four "between super-steps" sites corrected to per-call-during-Collecting model (evaluation within tick(); HALT lands at super-step boundary after in-flight settle; budget_info population is legitimate phase-boundary activity); template structure backfill (superseded_by/date/subsystems_affected frontmatter + Context/Alternatives/Rationale/Source sections). ADR-009 v1.3: 3 sites (budget_info population context); ADR-012 v1.3: 2 sites (analogy re-anchored from eval-timing to budget_info population). Architecture/BC/domain-spec confirmed clean. F-P95-02 MED (PO) — bc-authoring-plan v2.27: gate #13 regex → `VP-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]+`; verified all 4 shape classes; census re-run: **141 unique VP IDs** (was 71; 50 invisible); zero duplicates. F-P95-03 LOW (PO) — BC-2.10.004 v1.6: clean PC1..PC4 (verbatim duplicate removed; malformed 1a/1b/2b fixed); BC-2.10.001 v1.5: PC3 dispatch block + Related-BCs → "PC2 (hard-ceiling path)". F-P95-04 LOW (BA) — capabilities-p0 v1.3: three-mode (halt/escalate to HITL/summary_halt; OnCeiling::Halt|Escalate|Summarize); BC-2.10.004 v1.6 CAP-012 verbatim quote refreshed in-burst (cross-dependency closed). OBS-P95-A (PO) — VP-SPLIT-01..03 renumbered 3-digit→2-digit (blast radius 3 files; below >5 threshold; BC-2.07.001 v1.1/.002 v1.3/.003 v1.1; no VP-INDEX impact).
**D18-P89-A sweep:** capabilities-p0 v1.3 + ADR/BC edits cascade; iterative convergence: pass 1 = 72 updated, pass 2 = 112 updated, pass 3 = 10 updated, pass 4 = 2 updated, pass 5 = 0 (converged); **128/128 TOTAL MATCH**.
**Trajectory after:** →4 (P1D-95); cumulative tail →4→2→5→3→4
**Counter:** 0/3

---

### P1D-96 — Pass 96 (2026-07-17, burst 178)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-96 | 2026-07-17 | 1 | 0 | 0 | 0 | 0 | 1 | LOW | 0/3 | FINDINGS_REMAIN strict; CLEAN PR-merge (placeholder hygiene only) |

**Axes rotated:** 59 BC Traceability Module fields carrying vestigial `[architect to assign — <crate>]` placeholders (S-7.01 partial-fix: SS-10 resolved at pass 61; siblings in SS-01..SS-09/SS-11..SS-17 never propagated).
**Fix summary:** F-P96-01 OBS [process-gap] (PO) — all 59 BCs resolved declaratively from module-decomposition v1.10; dual-crate forms where BCs span trait/engine or lib/server splits; SS-17 → kani_proofs/ + fuzz/; zero ambiguous leftovers; each BC patch-bumped with changelog row; post-sweep grep = zero live placeholder hits; all 95 BC hashes MATCH (D18-P89-A sweep); bc-authoring-plan v2.27 → v2.28: gate #27 exemption for `[architect to assign]` class REMOVED — resolved crate assignment mandatory from authoring.
**D18-P89-A sweep:** bc-authoring-plan edit cascade; 36 additional BCs received input-hash-only refresh (transitive: bc-authoring-plan is in their inputs list); **all 95 BC hashes MATCH**.
**Trajectory after:** →1 (P1D-96); cumulative tail →5→3→4→1
**Counter:** 0/3

---

### P1D-99 — Pass 99 (2026-07-17, burst 181)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-99 | 2026-07-17 | 1 | 0 | 0 | 0 | 0 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN (OBS adjudicated substantive → scope expansion D18-P99-A: GuardrailDecision StreamEvent variant) |

**Axes rotated:** Gate #27 semantic sweep PASS; hedge sweep PASS; gates #28/#33/#34/#13 spot-checks PASS; VP-BUDGET collision drain confirmed PASS; RetryHint↔SS-16 coherence PASS; NFR↔BC harness-string agreement PASS; SS-04 crash-window semantics PASS; StreamEvent variant-count sibling-check 1/1 PASS (baseline 11; finding upgrades to 12). New cross-subsystem seam: SS-06↔SS-11 observability gap (guardrail ingress decisions unobservable in streaming taxonomy).
**Trajectory after:** →1 (P1D-99); cumulative tail →1→5→1→1
**Counter:** 0/3

---

### P1D-100 — Pass 100 (2026-07-17, burst 182)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-100 | 2026-07-17 | 3 | 0 | 0 | 2 | 0 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN (D18-P99-A propagation echo: SS-11 RAG/Memory boundary symmetry gap + events.md vocabulary) |

**Axes rotated:** ADR-006 rev-3 ↔ interface-definitions v2.34 ↔ BC-2.06.001 v1.3 triple-agreement (12-variant enum, fields, ordering) PASS. BC-2.11.002 v1.6 INV-5 + BC-2.11.005 v1.3 PC1 streaming-surface + BC-2.06.003 v1.3 stream-observer invariant all PASS. BC-INDEX byte-exact title sync PASS. EC-006 without TV convention PASS. test-vectors 513 PASS. Wire-token census PASS. Enum-mapping probes (IngressBoundary↔GuardrailOutcome↔GuardrailSeverity) PASS. DI-012 no-orphan PASS. prd.md staleness PASS. CAP-007 11-token scope: NOT STALE (false-positive discipline). SS-11 BC-2.11.003 + BC-2.11.004 PC3/PC4 emission postconditions (D18-P99-A propagation gap — F-P100-02). events.md Outcome contradictions (F-P100-01 + F-P100-03).
**Fix summary:** F-P100-01 MED (BA) — events.md v1.3→v1.4: StreamEventEmitted Outcome qualified (execution-lifecycle DI-011 equivalence; guardrail_decision stream-observer-only, unary observes via error blocks per BC-2.06.003). Sole occurrence. F-P100-02 MED (PO) — BC-2.11.003 v1.4→v1.5 + BC-2.11.004 v1.4→v1.5: PC3 Fail-emission + PC4 Transform-emission added per boundary (RagChunk/MemoryItem; NodeStart/NodeEnd window; tool_call_id: None; INV-5 cites). 9-dimension symmetry-triple verified: fully symmetric; one intentional asymmetry (emission window per ADR-006 ordering; design-correct); one consistent non-gap (no TV rows; mirrors BC-2.11.002). Architect follow-through: ADR-006 rev-3→rev-4 (downstream-amendments scope note + BC cite extended to 002/003/004). Interface-definitions v2.34→v2.35 (/stream row + §StreamEvent BC anchors per-boundary; remaining 002-only cites verified as type-definition authorities; correct). F-P100-03 OBS (BA) — events.md v1.4 (consolidated with F-P100-01): GuardrailChecked Outcome aligned Accept/Reject/Redact→Pass/Fail/Transform (F-P58-03 retirement record authority; Transform = strict superset of Redact; no semantic narrowing).
**D18-P89-A sweep:** interface-definitions v2.35 + events.md v1.4 edits stale: BC-2.06.001.md (events.md input), BC-2.06.002.md (events.md input), api-surface.md (interface-definitions input); all three refreshed via compute-input-hash --update; **126/126 TOTAL MATCH** (3 stale → 0 stale).
**Trajectory after:** →3 (P1D-100); cumulative tail →1→5→1→1→3
**Fix summary:** F-P99-01 OBS→adjudicated substantive (architect+PO+BA) — D18-P99-A scope expansion: ADD StreamEvent::GuardrailDecision (12th variant; Fail/Transform only, Pass not streamed; metadata-only payload: boundary IngressBoundary, decision, reason/severity [Fail only], ingress_id, tool_call_id [ToolResult only] + run_id/parent_ids). ToolEnd carries POST-guardrail content (zero-bytes isolation guarantee extended to streaming surface). GuardrailDecision fires BEFORE ToolEnd/within NodeStart-NodeEnd. Unary mode: no emission. Files: ADR-006 rev-3 + interface-definitions v2.34 + BC-2.06.001 v1.3 + BC-2.11.002 v1.6 + BC-2.11.005 v1.3 + BC-2.06.003 v1.3 + BC-INDEX title cell + events.md v1.3. test-vectors UNCHANGED 513.
**D18-P89-A sweep:** to be completed post-STATE.md write; census target files include all BCs + supplements whose inputs: reference ADR-006/interface-definitions/BC-2.06.001/BC-2.11.002/BC-2.11.005/BC-2.06.003/events.md.
**Trajectory after:** →1 (P1D-99); cumulative tail →1→5→1→1
**Counter:** 0/3

---

### P1D-98 — Pass 98 (2026-07-17, burst 180)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-98 | 2026-07-17 | 1 | 0 | 0 | 0 | 1 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN (fix-echo: burst-179 updated count in changelog row but not in live gate #27 body) |

**Axes rotated:** bc-authoring-plan gate #27 body count claim-vs-artifact (F-P98-01 LOW); burst-179 sibling-checks 5/5 PASS; SS-05↔SS-10 shared interrupt mechanism content probe PASS; BC-2.07.002 GTV-003 provenance PASS; BC H1↔INDEX 5-BC sample PASS; gate #27 semantic sweep re-run zero live PASS.
**Fix summary:** F-P98-01 LOW [claim-vs-artifact] (PO) — bc-authoring-plan v2.29→v2.30: gate #27 Exemptions prose "all 59 legacy placeholders resolved" → "all 60 legacy placeholders resolved — 59 literal + 1 semantic variant"; source reference extended F-P96-01 alone → F-P96-01 + F-P97-01; v2.30 changelog row added; v2.28/v2.29 historical rows untouched; post-fix grep for other live "59" placeholder-total references: zero additional hits.
**D18-P89-A sweep:** bc-authoring-plan inputs (prd.md, L2-INDEX.md) unchanged; no files list bc-authoring-plan in their inputs:; **126/126 TOTAL MATCH** (0 stale).
**Trajectory after:** →1 (P1D-98); cumulative tail →4→1→5→1
**Counter:** 0/3

---

### P1D-97 — Pass 97 (2026-07-17, burst 179)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-97 | 2026-07-17 | 5 | 0 | 1 | 1 | 3 | 0 | HIGH | 0/3 | FINDINGS_REMAIN (semantic residue-class: burst-178 literal sweep missed semantic variant phrasing) |

**Axes rotated:** BC-2.08.009 semantic Module placeholder variant (F-P97-01 HIGH); prd.md §10 deferred-actor parenthetical same class (F-P97-02 MED); BC-2.08.006 changelog monotonicity (F-P97-03 LOW); gate #27 literal-only scope [process-gap] (F-P97-04 LOW); BC-2.10.003 VP-table Phase column anomaly (F-P97-05 LOW); 95/95 SS-NN Module resolution re-verified; VP collision fixes propagated (PASS); VP-INDEX arithmetic (PASS); burst-178 YAML changelog insertions (PASS).
**Fix summary:** F-P97-01 HIGH (PO) — BC-2.08.009 v1.0→v1.1: Module field "ferrochain-macros [architect to confirm crate→subsystem in Phase 1b]" → "ferrochain-macros (re-exported ferrochain-core)" per module-decomposition v1.10 §ferrochain-macros; changelog section added (Group-A form); bc-authoring-plan v2.29 count row updated (60th placeholder incl. variant; v2.28 historical row preserved). F-P97-02 MED (PO) — prd.md v1.2→v1.3: §10 stale "(architect to confirm crate→subsystem mapping in Phase 1b)" parenthetical deleted. F-P97-03 LOW (PO) — BC-2.08.006 changelog rows reordered 1.3/1.2/1.1 (metadata-only; no version bump). F-P97-04 LOW [process-gap] (PO) — bc-authoring-plan v2.28→v2.29: gate #27 residue-class widened literal→semantic `architect to (assign|confirm|determine|resolve)`, scope ALL .factory/specs/; sweep command added; widened sweep run corpus-wide: 7 hits total, 2 fixed (F-P97-01/02), 5 changelog/gate-rule exempt; zero live after fixes; bonus sweeps ("PO to confirm/assign", "to be confirmed", "TBD by") all zero. F-P97-05 LOW (PO) — BC-2.10.003 v1.7→v1.8: VP-BUDGET-06/07 Phase column "Wave 1"→"Phase 1".
**D18-P89-A sweep (4-pass convergence):** prd.md v1.3 + BC-2.08.009 v1.1 + BC-2.10.003 v1.8 + bc-authoring-plan v2.29 triggered cascade; pass 1 = 95 updated; pass 2 = 111 updated; pass 3 = 3 updated; pass 4 = 0 stale; **126/126 TOTAL MATCH**.
**Trajectory after:** →5 (P1D-97); cumulative tail →3→4→1→5
**Counter:** 0/3

---

### P1D-101 — Pass 101 (2026-07-17, burst 183)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-101 | 2026-07-17 | 2 | 0 | 0 | 1 | 0 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN strict (1 MED [process-gap] + 1 OBS; CLEAN PR-merge) |

**Axes rotated (radius-closure directive):** SS-11 triple-symmetry BC-2.11.002 v1.6/.003 v1.5/.004 v1.5 9-dimension table PASS. ADR-006 rev-4 downstream-amendments scope note + BC cite 002/003/004 PASS. Interface-definitions v2.35 /stream row + §StreamEvent BC anchors per-boundary; remaining 002-only cites verified as type-definition authorities PASS. Zero Accept/Reject/Redact live vocabulary corpus-wide PASS. Gate #12 StreamEvent 12-variant census across BC-2.06.001/ADR-006/interface-definitions/events.md PASS. StreamEvent 12-variant triple-coherence PASS. Run-lifecycle state machine (NodeStart/NodeEnd/ToolInvoked/ToolEnd/GuardrailDecision ordering) coherent across all three boundary documents PASS. BC-INDEX subsystem sync: BC-2.11.003+.004 title cells post-v1.5 bump PASS. events.md GuardrailChecked Stream-surface ordering clause unconditional (F-P101-01 MED). BC-2.11.002 changelog rows display-inverted (F-P101-02 OBS).
**Fix summary:** F-P101-01 MED [process-gap] (BA) — events.md v1.4→v1.5: GuardrailChecked Stream-surface ordering clause boundary-qualified (ToolResult: fires before enclosing tool_end, tool_call_id present; RagChunk/MemoryItem: fires within NodeStart/NodeEnd envelope, before inference, tool_call_id absent; per ADR-006 + BC-2.06.001 PC4); sweep confirmed ToolInvoked stream-surface line correctly tool-scoped (no change); zero other unconditional ordering claims. F-P101-02 OBS (PO) — BC-2.11.002 changelog rows v1.6/v1.5 reordered to ascending convention (pure metadata reorder; no content change; YAML valid; gate #28 Rule 3 satisfied).
**Radius-closure verdict:** GuardrailDecision radius (D18-P99-A, burst-181/182/183 three-burst propagation) is NOW FULLY CLOSED. F-P101-01 was the final residue. If pass-102 finds further GuardrailDecision-radius residue, escalate severity one level for repeated propagation failure.
**D18-P89-A sweep:** events.md v1.5 edits — check files whose inputs: reference events.md. BC-2.06.001.md lists events.md in inputs; hash refreshed. BC-2.06.002.md lists events.md in inputs; hash refreshed (no content change from BC-2.11.002 reorder). Corpus-wide census after updates: TOTAL MATCH (0 stale).
**Trajectory after:** →2 (P1D-101); cumulative tail →5→1→1→3→2
**Counter:** 0/3

---

### P1D-102 — Pass 102 (2026-07-17, burst 184)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-102 | 2026-07-17 | 2 | 0 | 0 | 0 | 1 | 1 | LOW | 0/3 | FINDINGS_REMAIN strict; CLEAN PR-merge |

**Axes rotated (sibling-checks from burst 183):** events.md v1.5 boundary-qualified ordering clause coherent with ADR-006 + BC-2.06.001 PC4 PASS. BC-2.11.002 changelog ascending convention PASS. Final radius grep — zero GuardrailDecision residue corpus-wide PASS. GuardrailDecision radius confirmed FULLY CLOSED.
**Fix summary:** F-P102-01 LOW (PO) — BC-2.11.005 changelog rows reordered ascending (1.0, 1.1, 1.2, 1.3); pure metadata reorder; gate #28 Rule 3 satisfied. F-P102-OBS-A OBS [process-gap] (PO + orchestrator codification — D18-P102-A) — gate #28 gains Rule 6 VERSION-MONOTONICITY; bc-authoring-plan v2.30→v2.31; first full census: 14 total transposed files repaired (BC-2.11.005 + 13 additional latent: api-surface.md, module-decomposition.md, BC-2.03.001, BC-2.05.006, BC-2.06.001, BC-2.08.002, BC-2.09.001, BC-2.09.005, BC-2.12.005, BC-2.12.007, BC-2.14.002 [ascending/BC-convention] + error-taxonomy.md 8 violations + interface-definitions.md 22 violations [descending/supplement-convention per D18-P64-B]). Orchestrator correction: first census pass incorrectly force-ascended error-taxonomy + interface-definitions; caught and reversed before commit; census command corrected to be direction-aware.
**D18-P89-A sweep:** bc-authoring-plan v2.31 + 14 transposed-changelog repairs triggered cascade. Iterative convergence: pass 1 = 9 stale; pass 2 = 12 stale; pass 3 = 81 stale; pass 4 = 0 stale; **TOTAL MATCH 128/128**.
**Trajectory after:** →2 (P1D-102); cumulative tail →1→3→2→2
**Counter:** 0/3

---

### P1D-103 — Pass 103 (2026-07-18, burst 185)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-103 | 2026-07-18 | 2 | 0 | 0 | 1 | 0 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated:** gate #28 Rule 6 sibling-checks from burst-184 (14-file census re-verify, Rule 6 prose coherence, zero violations); GuardrailDecision 12-variant propagation spot-check (OBS-P103-B positive); nfr-catalog direction audit (F-P103-01 MED); gate #28 Rule 6 direction-blind census structural flaw (OBS-P103-A process-gap); hook-source audit of actual enforcement model.
**Fix summary:** F-P103-01 MED (PO) — nfr-catalog.md changelog rows swapped to descending order (supplement convention per D18-P64-B; pure reorder; no content change; no version bump). OBS-P103-A OBS [process-gap] (PO + orchestrator — D18-P103-A) — gate #28 Rule 6 census rewritten from internal-monotonicity-only to five-class hook-aligned direction-asserting model (prd-supplements/ desc; architecture/ Form A+B desc; behavioral-contracts/ Form A asc; behavioral-contracts/ Form B non-INDEX desc; BC-INDEX exempt); corpus re-run: 27 Form-A behavioral-contract files corrected desc→asc; 7 architecture Form-A files corrected asc→desc (ARCH-INDEX, api-surface, dependency-graph, module-decomposition, system-overview, tooling-selection, verification-coverage-matrix); purity-boundary-map retained desc; 3 Form-B ADRs retained desc; BC-INDEX retained desc (exempt); all pure reorders; verification-coverage-matrix hash cabbed8→6b6537d; bc-authoring-plan v2.31→v2.32. BC-INDEX edit blocker (validate-count-propagation): root cause = STATE.md hash census stale after burst-185 reorders (not yet committed); resolved by this burst-185 STATE.md write + D18-P89-A hash census TOTAL MATCH 126/126; [process-gap] engine-improvement candidate logged (hook's BC-count pattern matching is tight — see D18-P103-A notes).
**Hash sweep (D18-P89-A):** 3 files stale after burst-185 PO reorders: module-criticality.md + verification-architecture.md + 1 transitive; all refreshed; **TOTAL MATCH 126/126**.
**Trajectory after:** →2 (P1D-103); cumulative tail →3→2→2→2
**Counter:** 0/3

---

### P1D-104 — Pass 104 (2026-07-18, burst 187)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-104 | 2026-07-18 | 1 | 0 | 0 | 1 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (sibling-checks from burst-185 owed list — carried forward):** direction-asserting census corpus-wide PASS; 8 double-flip reorders spot-checked pure (row-SET audit confirmed no text lost); Rule 6 five-class coherence (prose↔census↔hook) PASS; BC-INDEX edit blocker RESOLVED (burst-185 commit + D18-P89-A sweep cleared hook's count-pattern matcher).
**Fix summary:** F-P104-01 MED (architect) — ARCH-INDEX.md v1.1 changelog row reconstructed from commit 8aebfcd (burst 86, 2026-07-14); v1.0 row reconstructed from commit ef41eda (burst 73, 2026-07-13); api-surface.md v1.0 row reconstructed from ef41eda; all annotated with NOTE markers per F-P88-03 precedent. No version bump/timestamp change (pure changelog-metadata reconstruction). Missing-level sweep all arch files + ADR-009/012/013 PASS. sidecar-learning.md 2026-07-18T16:53:31Z included.
**Hash sweep (D18-P89-A):** 2 stale (module-criticality.md + verification-architecture.md transitively); all refreshed; **TOTAL MATCH 128/128**. Pre-existing ARCH-INDEX + L2-INDEX drift flagged for burst-188 follow-up sweep.
**Trajectory after:** →1 (P1D-104); cumulative tail →3→2→2→1
**Counter:** 0/3

---

### P1D-105 — Pass 105 (2026-07-19, burst 189)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-105 | 2026-07-19 | 1 | 0 | 0 | 1 | 0 | 2 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-187/188 sibling-checks):** ARCH-INDEX changelog completeness (5 rows descending) PASS; api-surface changelog completeness (5 rows descending) PASS; reconstruction source commits (8aebfcd/ef41eda) CLOSED BY ORCHESTRATOR; missing-level sweep corpus-complete PASS; gate #28 completeness-axis spot-check PASS; hash-currency TOTAL MATCH CLOSED BY ORCHESTRATOR (burst-188 bookkeeping-only, 5/5 spot-diffs hash-field-only).
**Fix summary:** F-P105-01 MED (PO) — error-taxonomy.md SECURITY description corrected: was "Workspace escape, sandbox policy enforcement" (contradicted E-SBXD-002 POLICY; omitted 2/3 SECURITY members); corrected to "Workspace/sandbox escape; approver-role authorization failure; agent-memory write injection prevention" spanning all 3 SECURITY members (E-SBXD-001/E-GRAPH-013/E-MEMORY-007). Production-grade sibling sweep of all 11 other category descriptions: TIMEOUT/TRANSPORT/DURABILITY/CONCURRENCY descriptions broadened to span full member sets (same-class omission fix; TIMEOUT adds E-SERVER-016 IdempotencyLockTimeout; TRANSPORT adds E-PROV-008+E-MCP-005; DURABILITY adds E-MEMORY-002/005/008+E-SERVER-014+E-BUDGET-002; CONCURRENCY adds E-SERVER-007/012/015). error-taxonomy.md v1.18→v1.19. OBS-P105-A adjudicated: SECURITY/POLICY authorization-failure categorization rule documented as blockquote after Error Categories table (attack-vector→SECURITY; legitimate-caller privilege/access→POLICY; anchor BCs: BC-2.05.006/BC-2.15.002/BC-2.15.003). OBS-P105-B (process-gap) fixed: bc-authoring-plan v2.32→v2.33 — MANDATORY PRE-EMISSION CHECK block added to gate #28 (Form-A + Form-B union check before any "missing changelog" filing; known Form-B-only files enumerated).
**Hash sweep (D18-P89-A):** 3 BC files staled by error-taxonomy.md content change (BC-2.14.001.md 93b1aed→bf1eab4; BC-2.14.002.md 93b1aed→bf1eab4; BC-2.07.001.md d1dbee0→bb08508); all refreshed; full scan **TOTAL MATCH 126/126**. error-taxonomy.md and bc-authoring-plan.md own input-hashes unchanged (hashes computed from their inputs, which did not change).
**Trajectory after:** →1 (P1D-105); cumulative tail →2→2→1→1
**Counter:** 0/3

---

### P1D-106 — Pass 106 (2026-07-19, burst 190)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-106 | 2026-07-19 | 1 | 0 | 0 | 1 | 0 | 1 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-189 sibling-checks):** F-P105-01 RESOLVED (3 SECURITY members spanned; zero "sandbox policy enforcement" residue); OBS-P105-A RESOLVED (rule blockquote coherent with BC-2.05.006/BC-2.15.002/BC-2.15.003); OBS-P105-B PARTIALLY RESOLVED → F-P106-01; 12/12 category descriptions verified spanning membership (VAL/AUTH/RATE/TIMEOUT/TRANSPORT/INTERNAL/DURABILITY/POLICY/TOOL/CONCURRENCY/SECURITY/TENANCY — all PASS); test-vectors census 504+9=513 per-SS sums PASS; StreamEvent 12-variant coherence PASS; gate #33 E-CHKPT-002 spot PASS; burst-189 hash refreshes UNVERIFIABLE (adversary read-only) — mechanical, sanctioned.
**Fix summary (burst 190 — fix burst 110):** F-P106-01 MED [process-gap] (PO+orchestrator) — bc-authoring-plan v2.33→v2.34: BC-INDEX.md added to Known Form-B-only files list under new "Indexes:" bullet; catch-all broadened from "Any ADR or supplement" to "Any index, ADR, or supplement that uses a `## Changelog` body section"; difference-set verification: 11 Form-B-only files confirmed ({ADR-007, ADR-009, ADR-012, ADR-013, BC-INDEX.md, BC-2.07.002, BC-2.08.011, BC-2.08.012, bc-authoring-plan.md, test-vectors.md, verification-architecture.md}); zero omissions. OBS-P106-A (PO) — error-taxonomy.md v1.19→v1.20: E-MEMORY-006 message corrected to `InsufficientPrivilege: operation '<operation>' requires <required>` (1:1 struct-field mapping to BC-2.15.003 EC-005 {operation, required}; "AdminContext" hardcode and unfillable `<caller_privilege>` placeholder removed); 22-code struct-bearing sibling sweep: 21 PASS, 1 fixed (E-MEMORY-006); gate #33 BC-wins applied.
**Hash sweep (D18-P89-A):** 3 BC files staled by error-taxonomy.md content change (BC-2.07.001.md →b52167a; BC-2.14.001.md →4138081; BC-2.14.002.md →4138081); all refreshed; full scan **TOTAL MATCH 126/126**. bc-authoring-plan.md and error-taxonomy.md own input-hashes unchanged (computed from their inputs, which did not change).
**Trajectory after:** →1 (P1D-106); cumulative tail →2→1→1→1
**Counter:** 0/3

---

### P1D-107 — Pass 107 (2026-07-19, burst 191)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-107 | 2026-07-19 | 1 | 0 | 0 | 1 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-190 sibling-checks):** F-P106-01 RESOLVED (BC-INDEX.md in Known Form-B-only list; 11-file set complete); OBS-P106-A RESOLVED (E-MEMORY-006 message 1:1 struct-field match); 12/12 category descriptions checked; gate #33 reverse-census first formal pass (Steps A/B); hash sweeps UNVERIFIABLE (adversary read-only) — mechanical, sanctioned.
**Fix summary (burst 191 — fix burst 111):** F-P107-01 MED [process-gap] (PO) — 4 ss-02 BC structs corrected to match error-taxonomy placeholders: E-GRAPH-011 BC-2.02.005 v1.1→v1.2 `{source}` → `{source_node, message}`; E-GRAPH-007 BC-2.02.001 v1.1→v1.2 `{key}` → `{node_id, key}`; E-GRAPH-001 BC-2.02.002 v1.1→v1.2 `{channel}` → `{channel, task_ids, step}`; E-GRAPH-004 BC-2.02.003 v1.1→v1.2 `{channel, writer}` → `{channel, writer, step}`; error-taxonomy v1.20→v1.21 corrigendum (false "21 PASS" corrected to "5 FAIL/17 PASS"; root cause: EC-003 ambiguous "error source" phrasing); EC-003 "panic message as the error source" contradiction removed. D18-P89-A sweep: TOTAL MATCH (input hashes unchanged — error-taxonomy content change not present in BC inputs for these 4 files).
**Hash sweep (D18-P89-A):** TOTAL MATCH (input hashes unchanged for burst-191 scope; burst-192 follow-up sweep identified 3 stale BCs missed by burst-191 sweep — BC-2.07.001, BC-2.14.001, BC-2.14.002 all refreshed in burst-192).
**Trajectory after:** →1 (P1D-107); cumulative tail →1→1→1→1
**Counter:** 0/3

---

### P1D-108 — Pass 108 (2026-07-19, burst 193)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-108 | 2026-07-19 | 4 | 0 | 1 | 2 | 1 | 0 | MEDIUM-HIGH | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-191/192 sibling-checks):** F-P107-01 RESOLVED — 4 structs verified 1:1 against error-taxonomy placeholders (E-GRAPH-001/004/007/011 all v1.2); corrigendum in error-taxonomy v1.21 top entry; zero "panic message as the error source" residue corpus-wide; burst-192 hash-currency closure (3 stale BCs identified + refreshed; root cause: burst-191 sweep missed transitive D18-P90-A rule).
**Fix summary (burst 193 — fix burst 112):** F-P108-04 HIGH [process-gap] (PO+orchestrator) — gate #33 STRUCT-PLACEHOLDER PARITY CENSUS Steps A/B/C codified in bc-authoring-plan v2.35; first formal full census: 36 codes, 8 FAIL (E-MEMORY-006, E-GRAPH-011/007/001/004, E-PROV-010, E-CHKPT-004, E-PROV-009) all fixed in prior bursts; 28 PASS; zero remaining. F-P108-01 HIGH (PO) — BC-2.08.014 v1.2 EC-004/TV-005 expanded to 3-field struct `{providers_attempted, last_error_code, last_provider}`. F-P108-02 MED (PO) — BC-2.04.007 v1.5 PC4 `source→message` for intra-BC field consistency. F-P108-03 MED (PO) — BC-2.08.013 v1.2 EC-002 expanded to 4-field struct `{dialect, element, offset, parse_error}`. error-taxonomy v1.21→v1.22 corrigendum #2 (8 FAIL/28 PASS canon; v1.21 row preserved). F-P108-05 LOW (PO) — (E-PROV-009 offset↔`<n>` alias noted PASS-NOTE — semantic alias pre-dating alias registry).
**Hash sweep (D18-P89-A):** Run pending as of burst-193 commit; hash sweep incorporated into burst-194 (this burst).
**Trajectory after:** →4 (P1D-108); cumulative tail →1→1→1→4
**Counter:** 0/3

---

### P1D-109 — Pass 109 (2026-07-19, burst 194)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-109 | 2026-07-19 | 2 | 0 | 1 | 1 | 0 | 0 | MEDIUM-HIGH | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-193 sibling-checks):** gate #33 STRUCT-PLACEHOLDER PARITY CENSUS Steps A/B/C present in bc-authoring-plan v2.35 PASS; 3 BC struct fixes match taxonomy 1:1 (BC-2.08.014 v1.2, BC-2.04.007 v1.5, BC-2.08.013 v1.2) PASS; corrigendum #2 at top of error-taxonomy v1.22 changelog; v1.21 row NOT rewritten PASS; census tally 36/8-FAIL-all-fixed/28-PASS PASS; gate #33 Step-C TABLE format binding confirmed — independent census run (see F-P109-01): **census claim (e) FAILED** — E-GRAPH-002 falsely marked PASS in v1.22; 9/10 BC-2.05.005 sites missing thread_id; v1.22 used wrong BC anchor (BC-2.02.006 BarrierWaitTimeout instead of BC-2.05.005 NoActiveInterrupt); 3rd consecutive false census claim for this code.
**Fix summary (burst 194 — fix burst 113):** F-P109-01 HIGH [process-gap] (PO) — BC-2.05.005 v1.2→v1.3: thread_id added at 9 sites (EC-001/002/003/004, TV-001/002/003/004/005); PC1 already correct; canonical 2-field form `{thread_id, run_status}` now uniform across all 10 E-GRAPH-002 sites; alias `thread_id ↔ <run_id>` registered in bc-authoring-plan v2.36; PASS-ABBREV rule corollary added (TV-row `...` = FAIL when sole struct site). Full v2.36 census re-run: 30 codes (2 FPs excluded: E-CHKPT-008/E-BUDGET-001; 4 base-form excluded; net 30 vs 36 under v1.22 rules); 3 FAIL: E-GRAPH-002 (fixed v1.3), E-MCP-002 (BC-2.09.001 TV-004 sole-site `...` fixed v1.3), E-SBXD-001 (BC-2.13.005 TV-002/003 missing requested+root fields fixed v1.1); 27 PASS. F-P109-02 MED [process-gap] (PO) — bc-authoring-plan v2.35→v2.36: 4 aliases added (offset↔`<n>`, providers_attempted↔`<N>`, backend_error↔`<reason>`, message↔`<reason>` CODE-SPECIFIC E-CHKPT-004 do-not-generalize); context-sourced placeholder exception class defined (E-MEMORY-007 registered); PASS-ABBREV rule explicit with negative corollary. error-taxonomy v1.22→v1.23 corrigendum #3 (v1.22 row preserved).
**Hash sweep (D18-P89-A):** Run in burst-194 (this burst). Files edited: BC-2.05.005, BC-2.09.001, BC-2.13.005, bc-authoring-plan, error-taxonomy. Transitive cascade (D18-P90-A) applied. TOTAL MATCH confirmed (STALE=0 after --scan specs).
**Trajectory after:** →2 (P1D-109); cumulative tail →1→1→4→2
**Counter:** 0/3

---

### P1D-110 — Pass 110 (2026-07-19, burst 195)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-110 | 2026-07-19 | 2 | 0 | 1 | 1 | 0 | 0 | MEDIUM-HIGH | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-194 sibling-checks):** F-P109-01 RESOLVED — BC-2.05.005 v1.3 all 10 E-GRAPH-002 sites carry `{thread_id, run_status}`; alias thread_id↔`<run_id>` in gate #33 v2.36; PASS. F-P109-02 RESOLVED — bc-authoring-plan v2.36 alias registry 8 entries; context-sourced exception class; PASS-ABBREV corollary; PASS. Gate #33 v2.36 census 30 codes / 3 FAIL-all-fixed / 27 PASS independent re-run: FAILED census claim (e) — E-SBXD-001 BC-2.13.004 secondary anchor not swept (prior sweep in-file only); adversary 3rd safety grep found 4 genuinely newly-scoped codes (E-GRAPH-009 DuplicateNodeName, E-GRAPH-014 InterruptApprovalTimeout, E-CRON-002, E-SERVER-006). Net: 34 codes total (30 prior + 4 new).
**Fix summary (burst 195 — fix burst 114):** F-P110-02 HIGH [process-gap] (PO+orchestrator) — BC-2.13.004 v1.1→v1.2 TV-002 expanded to 3-field `{requested, resolved, root}`; bc-authoring-plan v2.36→v2.37 Step B check-1 cross-anchor scope — "ALL BCs in taxonomy BC-Anchor cell (primary AND secondary)"; full v2.37 census: 34 codes; 4 newly-scoped (E-GRAPH-009 PASS, E-GRAPH-014 FAIL→FIXED v1.4, E-CRON-002 PASS, E-SERVER-006 PASS); 2 FAIL-both-fixed; 32 PASS; ZERO remaining. F-P110-01 MED [process-gap] (PO) — error-taxonomy v1.23→v1.24 corrigendum #4: E-GRAPH-002 has ONE placeholder `<run_id>` (not two); run_status = extra diagnostic superset field; v1.23 row preserved. BC-2.05.006 v1.4: EC-005 E-GRAPH-014 run_id added (newly-scoped). total_standing_gates unchanged at 34.
**Hash sweep (D18-P89-A):** STALE=0 confirmed after `--scan specs`.
**Trajectory after:** →2 (P1D-110); cumulative tail →1→4→2→2
**Counter:** 0/3

---

### P1D-111 — Pass 111 (2026-07-19, burst 196)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-111 | 2026-07-19 | 1 | 0 | 0 | 1 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
| P1D-112 | 2026-07-19 | 2 | 0 | 0 | 2 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-195 sibling-checks):** F-P110-02 RESOLVED — BC-2.13.004 v1.2 TV-002 3-field `{requested, resolved, root}` confirmed; cross-anchor consistent with BC-2.13.005; PASS. F-P110-01 RESOLVED — error-taxonomy v1.24 corrigendum #4 ONE placeholder confirmed; run_status = superset diagnostic field; BC-2.05.006 v1.4 EC-005 run_id confirmed; PASS. Census v2.37 34 codes / 32 PASS / 2 FAIL-both-fixed PASS. Cross-anchor full sweep: E-SBXD-001 PASS, E-GRAPH-016 PASS, E-CORE-007 wrapper-form noted → F-P111-01. MAJOR: all four carry-forward Part-B axes exercised IN FULL and CLEAN — holdout-domains↔BC/CAP (Domains C+D fully dispositioned), purity-map(58)↔module-decomp(49 rows: 22P+28E+8B, +9 definitions-only) Iron Law holds 10/10 spot-check, CAP(21)↔BC(95) bidirectional zero orphans, DI(14) all cited, ss-16/ss-17 remainder sound.
**Fix summary (burst 196 — fix burst 115):** F-P111-01 MED [process-gap] (PO+orchestrator) — gate #33 v2.37→v2.38: Step-A Form 3 wrapper-form grep (patterns 3a + 3b false-positive check); wrapper-form discipline codified (bare {category, code} valid ONLY for placeholder-less codes; inline message: template / PASS-ABBREV / registered context-source required for codes with placeholders). E-CORE-007 resolved via context-sourced exception: `<boundary>` from ProvenanceTag.boundary_type, `<content_type>` from IngressContent variant discriminant; registered in gate #33; BC-2.11.002/003/004 v1.5→v1.6. E-RETRY-002 resolved via inline template: BC-2.16.002 v1.1→v1.2. Full Form-3 census: 17 codes / 27 violation sites across 17 BC files; all resolved; ZERO remaining. 15 additional BCs bumped: BC-2.16.001 v1.3, BC-2.01.001 v1.2, BC-2.14.004 v1.2, BC-2.08.007 v1.4, BC-2.08.001 v1.3, BC-2.15.004 v1.2, BC-2.03.001 v1.5, BC-2.04.001 v1.2, BC-2.04.004 v1.2, BC-2.04.006 v1.4, BC-2.09.002 v1.2, BC-2.17.002 v1.3, BC-2.08.004 v1.5. error-taxonomy v1.24→v1.25 (Form-3 census documented as new scope; no corrigendum needed). total_standing_gates unchanged at 34.
**Hash sweep (D18-P89-A):** Run this burst; STALE=0 confirmed after `--scan specs`.
**Trajectory after:** →1 (P1D-111); cumulative tail →4→2→2→1
**Counter:** 0/3

---

### P1D-112 — Pass 112 (2026-07-19, burst 197)

| Pass | Date | Total | CRIT | HIGH | MED | LOW | OBS | Novelty | Counter | Verdict |
|------|------|-------|------|------|-----|-----|-----|---------|---------|---------|
| P1D-112 | 2026-07-19 | 2 | 0 | 0 | 2 | 0 | 0 | MEDIUM | 0/3 | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |

**Axes rotated (burst-196 sibling-checks):** F-P111-01 RESOLVED — gate #33 v2.38 Form-3 procedure executable; E-CORE-007 context-sourced exception verified; E-RETRY-002 inline template `<global_limit>` confirmed; 6-site spot-verify PASS; 17/17 template verification PASS (PASS-WITH-NOTE on 3 E-CORE-007 sites — qualified form generates F-P112-01). VERSION NOTE: BC-2.11.002 found at v1.7 (not v1.6 in checkpoint) — brief-side staleness. Three clean axes: events.md/BC-2.06.x boundary-enum coherence CLEAN; E-PROV-003 cross-BC CLEAN; interface-definitions §error-handling CLEAN.
**Fix summary (burst 197 — fix burst 116):** F-P112-01 MED (PO) — E-CORE-007 `<content_type>` rendered-value adjudication; BARE variant name wins (interface-definitions §IngressContent pre-existing authority; supplements supersede BC prose per Source-of-Truth Precedence Rule 3); BC-2.11.002 v1.7→v1.8 (EC-001 + TV panic row: `"IngressContent::ToolResult"` → `"ToolResult"`; source note: "content variant discriminant" → "IngressContent variant discriminant"); BC-2.11.003 v1.6→v1.7 (symmetric; RagChunk); BC-2.11.004 v1.6→v1.7 (symmetric; MemoryItem); bc-authoring-plan gate #33 registry updated to v2.39 (bare-quoted values). F-P112-02 MED [process-gap] (PO) — E-CORE-005 polymorphic message adjudication; canonical format `Validation failed for '<field>': <reason>` is the SINGLE required shape; corpus census 8 BC files (5 FIXED: BC-2.04.002 'durability' v1.2→v1.3, BC-2.04.007 'key_material' v1.5→v1.6, BC-2.08.002 'model' v1.3→v1.4, BC-2.08.006 'timeout' v1.3→v1.4, BC-2.08.014 'ProviderFallbackPolicy.chain' v1.2→v1.3; 3 already-conforming: BC-2.04.006, BC-2.08.004, BC-2.14.006); bc-authoring-plan v2.39 census addendum; error-taxonomy v1.25→v1.26 adjudication row. No cross-owner routing. total_standing_gates unchanged at 34.
**Hash sweep (D18-P89-A):** Run this burst; STALE=0 confirmed after `compute-input-hash --scan specs --update`.
**Trajectory after:** →2 (P1D-112); cumulative tail →2→2→1→2
**Counter:** 0/3

---

## Frontmatter Fields (extracted from STATE.md)

<!-- When compacting STATE.md, adversary_pass_* frontmatter fields are
     converted to rows in the Finding Progression table above.
     Original field format: adversary_pass_N_findings: "description"
     Original field format: adversary_pass_N_date: "YYYY-MM-DD" -->
