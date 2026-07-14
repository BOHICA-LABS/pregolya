---
document_type: adversarial-review
pass: 13
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
open_findings: 1
timestamp: 2026-07-14T00:00:00Z
trajectory: "14→5→7→13→3→3→3→5→2→4→4→1→1"
counter_clean: 0
counter_clean_needed: 3
---

# ADV-P1D PASS-13: Adversarial Review — Phase 1d

**Verdict: NOT CLEAN — 1 HIGH (F-P13-01 topology inversion, fixed this pass) + 2 LOW observations (fixed this pass)**

---

## Sibling-Axis Checks (Pass-13 coverage complement)

| Axis | Status | Notes |
|------|--------|-------|
| Topology census: domain-spec↔dependency-graph.md edge table (NEW gate) | FAIL (F-P13-01 + ancillary) | 2 FAIL edges, 1 missing edge; all fixed; see census below |
| Arrow census (guideline #12 gate re-run) | PASS | `grep -rn "in_progress →\|in_progress→\|→ interrupted\|⇄"` — all hits show interrupted as pausable; terminal set {completed, failed, cancelled} unchanged |
| BC-INDEX title 3-way match (BC-2.12.003) | PASS | Verbatim match confirmed across BC-INDEX, prd.md, bc-authoring-plan |
| de-Canonical audit (no doc claims "Canonical" for lifecycle arrow) | PASS | interface-definitions.md:206 "Canonical" label removed in pass-12; no new "Canonical" claims |
| E-code crate-roster collision scan | PASS | No shared NNN between semantically different E-xxx codes across GRAPH/SERVER/MCP subsystems |
| VP-seed cross-ref abbreviation (BC-INDEX:48) | PASS | Intentional; VP-INDEX.md is authoritative VP catalog |

---

## Finding F-P13-01 (HIGH): Dependency diagram inverts SDK-split topology and misroutes graph→checkpoint edge

**Finding class: topology consistency — domain-spec↔dependency-graph.md**

**Scope:** `bounded-contexts.md` lines 141–153 (pre-fix), Context Dependency Order diagram.

### Root cause

The diagram had three topology errors vs. the dependency-graph.md edge table (authoritative):

1. **`ferrochain-<provider>-sdk` was shown as a dependent of `ferrochain-core`**
   (`ferrochain-core ← ferrochain-<provider>-sdk`), implying sdk→core.
   Edge table states explicitly: `ferrochain-openai-sdk | (none) — Standalone: reqwest + serde only; no ferrochain-core [D17-Q5]` (and identically for anthropic-sdk, ollama-sdk).
   This is BC-2.08.006 EC-001's exact must-fail edge.

2. **`ferrochain-<provider>` adapter's `core` edge was missing from the diagram.**
   The adapter was shown only as depending on its sdk (nested under sdk). Edge table has
   `ferrochain-openai | ferrochain-core | runtime | BaseChatModel + FerrochainError` — adapter
   depends on BOTH core and its sdk. The missing core edge directly contradicts Context 5's
   own prose ("Provider crates implement ChatModel Runnable from ferrochain-core").

3. **`ferrochain-graph` was shown as a dependent of `ferrochain-checkpoint`**
   (nesting: `ferrochain-checkpoint ← ferrochain-graph`), implying graph→checkpoint.
   Edge table has NO `ferrochain-graph | ferrochain-checkpoint` edge. Graph depends only on
   core and sandbox. The graph/checkpoint relationship is via DIP: `CheckpointSaver` trait
   is defined in `ferrochain-core`; graph holds `Arc<dyn CheckpointStore>` bound against the
   core trait — no direct Cargo dep on ferrochain-checkpoint. The dependency-graph.md Crate
   DAG visual nests checkpoint under graph misleadingly; the edge table is the canonical source.

Additionally: the server→checkpoint direct edge was only implied transitively through the
wrong graph→checkpoint chain. Server's direct checkpoint dependency (edge table:
`ferrochain-server | ferrochain-checkpoint | runtime`) was not made visible.

### Fix applied (`bounded-contexts.md` lines 141–157 post-fix)

Old diagram:
```
ferrochain-core
  ← ferrochain-splitters
  ← ferrochain-checkpoint
      ← ferrochain-graph
          ← ferrochain-server
  ← ferrochain-<provider>-sdk
      ← ferrochain-<provider>
  ← ferrochain-mcp
  ← ferrochain-standard-tests (dev-dep)
```

New diagram:
```
ferrochain-core
  ← ferrochain-splitters
  ← ferrochain-checkpoint
  ← ferrochain-graph
  ← ferrochain-server         (direct deps: ferrochain-graph + ferrochain-checkpoint)
  ← ferrochain-<provider>     (direct deps: ferrochain-core + ferrochain-<provider>-sdk)
  ← ferrochain-mcp
  ← ferrochain-standard-tests (dev-dep)

ferrochain-<provider>-sdk (standalone root; NO ferrochain-core dep [D17-Q5])
  ← ferrochain-<provider>
```

Footer (`No circular dependencies; ferrochain-core has zero intra-workspace dependencies.`) verified
still true — no cycles introduced; ferrochain-core remains root.

---

## LOW Observation 1: `events.md:111` — Dangling DI reference in BudgetEvaluated

**Pre-fix:** `- **EvidenceJournal:** Entry appended with outcome (DI per append-only)`

`"DI per append-only"` is not a resolvable identifier. No DI-NNN in invariants.md describes
an append-only journal rule; the concrete behavioral contract is BC-2.10.002.

**Fix:** `(DI per append-only)` → `(BC-2.10.002: append-only journal)`

---

## LOW Observation 2: `bounded-contexts.md:82` — FM-007 listed in Key invariants

**Pre-fix:** `**Key invariants:** DI-005 (tenancy), DI-011 (streaming/unary equiv.), DI-013 (secure defaults), FM-007 (streaming stub must not exist).`

FM-007 is a failure mode identifier, not an invariant (DI-NNN). Mixing failure modes into
the invariants list breaks the type system for readers and tooling.

**Fix:** FM-007 separated onto its own labeled line:
```
**Key invariants:** DI-005 (tenancy), DI-011 (streaming/unary equiv.), DI-013 (secure defaults).
**Excluded failure mode (FM-007):** streaming stub must not exist.
```

---

## Topology Census (NEW gate — domain-spec↔dependency-graph.md edge table)

All topology assertions extracted from every domain-spec shard, diffed against
`dependency-graph.md` edge table (authoritative).

| Assertion | Source | Edge Table Verdict |
|-----------|--------|--------------------|
| ferrochain-core has zero intra-workspace deps | bounded-contexts.md:33,157 | PASS — no outgoing core edges |
| ferrochain-splitters depends on core | bounded-contexts.md:144 | PASS |
| ferrochain-checkpoint depends on core | bounded-contexts.md:145 | PASS |
| ferrochain-graph depends on ferrochain-checkpoint (pre-fix nesting) | bounded-contexts.md:146 (pre-fix) | FAIL — no graph→checkpoint edge in edge table; FIXED |
| ferrochain-server depends on ferrochain-graph | bounded-contexts.md:147 | PASS |
| ferrochain-server→checkpoint direct edge | bounded-contexts.md:148 (post-fix annotation) | PASS — explicit annotation added |
| ferrochain-<provider>-sdk depends on ferrochain-core (pre-fix) | bounded-contexts.md:148 (pre-fix) | FAIL — edge table: sdk standalone; FIXED |
| ferrochain-<provider> adapter depends on ferrochain-<provider>-sdk | bounded-contexts.md:149 | PASS |
| ferrochain-<provider> adapter→core edge (pre-fix: missing) | bounded-contexts.md:149 (pre-fix) | MISSING — edge table has adapter→core; FIXED (post-fix annotation + standalone block) |
| ferrochain-mcp depends on ferrochain-core | bounded-contexts.md:150 | PASS |
| ferrochain-standard-tests depends on ferrochain-core | bounded-contexts.md:151 | PASS |
| SDK crate split: ferrochain-<provider>-sdk standalone wire client | capabilities-p1-p2.md:31–32 | PASS — text correctly states standalone; consistent with edge table D17-Q5 |
| ferrochain-<provider> implements ChatModel Runnable from ferrochain-core (adapter→core prose) | bounded-contexts.md:98–99 | PASS (prose consistent with edge table) |
| graph execution holds Arc<dyn CheckpointStore> | bounded-contexts.md:63–64 | CONSISTENT — doesn't assert a Cargo dep edge; CheckpointSaver trait defined in core; no contradiction |

Census result: **2 FAILs + 1 MISSING — all fixed in this pass.** All other assertions: PASS.

---

## Process Gap

**New gate registered:** domain-spec↔dependency-graph topology census.

Gate command (add to systematic sweep):
```
# For each topology claim (← arrows, "depends on", "zero deps") in domain-spec shards:
# diff against dependency-graph.md §Edge Table.
# Every sdk crate must show as standalone; every adapter must show dual root (core + sdk).
# ferrochain-core must show zero outgoing edges.
grep -rn "← ferro\|depends on ferro\|standalone.*dep\|zero.*dep" .factory/specs/domain-spec/
```

Authority: `dependency-graph.md` §Edge Table (producer: architect, phase: 1b).
Frequency: run whenever bounded-contexts.md or any domain-spec section is modified.

---

## Counter-Clean Status

- Required for CLEAN: 3 consecutive passes with 0 open findings
- Counter at this pass: 0 (NOT CLEAN — 1 HIGH finding + 2 LOW observations, all fixed)
- Trajectory: ...→4→4→1→1 (zero new structural bugs; existing topology inversion corrected)

---

## Next-pass rotation axes (suggestions for pass-14)

1. **Topology census re-run:** Confirm zero domain-spec↔edge-table mismatches post-fix
2. **BC-2.05.002 deep audit:** Full postcondition review of HITL resume contract (DEC-006/DEC-007 edge case coherence, multi-interrupt queue interaction)
3. **VP-INDEX coverage audit:** Verify every Kani VP seed BC (BC-2.03.001, BC-2.04.006, BC-2.13.004) has a corresponding VP file in `.factory/specs/verification-properties/`
4. **NFR numerical target audit:** Scan all NFRs in nfr-catalog.md for qualitative descriptions that violate the numerical-target requirement
