---
document_type: adversarial-review
phase: 1d
pass: 3
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
finding_count: 7
critical_count: 2
high_count: 2
medium_count: 2
low_count: 1
timestamp: 2026-07-14T00:00:00Z
---

# Adversarial Review — Phase 1d Pass 3

**Verdict: NOT CLEAN — 7 findings (2 CRITICAL, 2 HIGH, 2 MEDIUM, 1 LOW)**

---

## Sibling Check: 4/6 landed

Pass-3 arrived with Pass-2 fixes applied. Four of six sibling-check items landed
cleanly.

| Item | Status |
|------|--------|
| Budget namespace incoherence (F-P2-01) | RESOLVED — `BUDGET` component section added to error-taxonomy.md |
| `requires_action` → `interrupted` in BCs (F-P2-03) | RESOLVED — BC run-state naming now matches entities-server.md |
| Session triple-address VP seed (F-P2-04) | RESOLVED — VP-002 registered with BC-2.04.006 |
| Error taxonomy machine-code format (F-P2-05) | RESOLVED — E-xxx-NNN format enforced across taxonomy |
| F-P3-02 (BC-2.08.006 vs ADR-007 sdk split) | RESOLVED — ADR-007 revised to standalone -sdk crates per D17-Q5 |
| F-P3-04 (topology omits memory/macros, 12→14 drift) | RESOLVED — 18-crate canonical roster added to ARCH-INDEX §Canonical Crate Roster (authoritative) |

---

## New Axis: Crate Topology Coherence

Pass 3 introduced a new audit axis: **crate-roster coherence** — do all spec
artifacts agree on the workspace crate count and enumeration? This axis was absent
from prior passes. Five of the seven findings below originate from this axis.

---

## F-P3-01 CRITICAL — Memory Crate Has Three Competing Homes

**File:** Multiple — `specs/behavioral-contracts/ss-15/`, `specs/prd.md`, `specs/product-brief.md`
**Scope:** product-owner

Three specifications independently described the memory subsystem with inconsistent
crate/trait naming:

1. `ss-15/BC-2.15.001/002/003` frontmatter: `wave: post-v1` — contradicts ARCH-INDEX
   canonical roster which assigns wave 2 to ferrochain-memory.
2. `BC-2.15.001/002/003` Traceability rows: `| Wave | Post-v1 |` — same contradiction.
3. `specs/prd.md` RTM rows (lines 541–543): `module = ferrochain-graph` for all three
   BC-2.15.x entries — should be `ferrochain-memory` (SS-15 home).

**Required fix:** BC-2.15.001/002/003 frontmatter `wave: post-v1` → `wave: 2`; Traceability
rows updated to match; product-owner scope.

---

## F-P3-02 CRITICAL — BC-2.08.006 vs ADR-007 SDK Crate Architecture

**File:** `specs/behavioral-contracts/ss-08/BC-2.08.006.md`, `specs/architecture/decisions/ADR-007-crate-topology-sdk-split.md`
**Scope:** architect / product-owner

**STATUS: RESOLVED.** ADR-007 was revised to align with BC-2.08.006's standalone
-sdk crate model per D17-Q5. The BC-2.08.006 contract is now ADR-aligned and requires
no change.

---

## F-P3-03 HIGH — `expired` Terminal State in BC-2.12.004 PC2b

**File:** `specs/behavioral-contracts/ss-12/BC-2.12.004.md:59`
**Scope:** product-owner

Postcondition PC2b specifies the Run lifecycle as:
```
queued → in_progress → completed | failed | expired
```

`entities-server.md:44` explicitly deprecates `expired` as a v1.0.0 terminal state:
> "`expired` deferred — v1.0.0 uses `failed` with E-GRAPH-014 InterruptApprovalTimeout
> for timeout-expired runs; a dedicated `expired` state may be added in a future version"

The canonical v1.0.0 lifecycle is:
```
queued → in_progress → completed | failed | interrupted | cancelled
```

Additionally, the Related-BCs section (line 141) abbreviates the lifecycle as
`queued→completed/failed`, omitting `interrupted` and `cancelled`.

**Required fix:** PC2b lifecycle string → canonical; Related-BCs line 141 → full canonical set.

---

## F-P3-04 HIGH — Crate Topology Omits ferrochain-macros and Three -sdk Crates

**File:** `specs/product-brief.md:144–147`; `specs/prd.md:541–543`
**Scope:** product-owner / architect

**STATUS: RESOLVED** for the architecture layer. ARCH-INDEX §Canonical Crate Roster now
lists 18 published crates authoritatively. However, `specs/product-brief.md` workspace
topology section still enumerates only 14 crates (missing ferrochain-macros +
ferrochain-openai-sdk + ferrochain-anthropic-sdk + ferrochain-ollama-sdk), and R6 risk
row still says "14 crates".

`specs/prd.md` RTM module column for BC-2.15.x rows says `ferrochain-graph` (should be
`ferrochain-memory`). Not a count error but a naming error from the same topology
confusion.

**Required fix:** product-brief.md crate enumeration updated to 18 crates citing
ARCH-INDEX §Canonical Crate Roster; R6 note updated.

---

## F-P3-05 MEDIUM — ADR-008 Stale; proc-macro BCs Not Cross-Referenced

**File:** `specs/architecture/decisions/ADR-008-proc-macro-crate.md`
**Scope:** architect

ADR-008 was referenced in BC-2.08.010/011/012 (batch 13, added at Phase 1 Step D)
but the ADR-008 document predates the batch-13 BC creation. ADR-008 does not reference
BC-2.08.010/011/012 in its Consequences or Traceability section; the BCs reference
ADR-008 but ADR-008 is not bidirectionally linked. Medium severity — no behavioral
inconsistency, but the ADR becomes orphaned from the BC it motivated.

**Required fix:** architect to add BC-2.08.010/011/012 cross-references to ADR-008
Consequences/Traceability section.

---

## F-P3-06 MEDIUM — BC-2.15.001/002/003 Wave Drift (post-v1 vs Wave 2)

**File:** `specs/behavioral-contracts/ss-15/BC-2.15.001/002/003.md` frontmatter
**Scope:** product-owner

All three SS-15 BCs have `wave: post-v1` in frontmatter. The ARCH-INDEX canonical
roster assigns ferrochain-memory to `wave: 2`. The `post-v1` designation predates
the architect's wave-assignment and is stale.

**Required fix:** Frontmatter `wave: post-v1` → `wave: 2` on all three; Traceability
`| Wave | Post-v1 |` → `| Wave | Wave 2 |`. (Subsumed in F-P3-01 fix scope.)

---

## F-P3-07 LOW — VP-003 References Error Type Three Ways

**File:** `specs/behavioral-contracts/ss-13/BC-2.13.004.md`, `specs/architecture/verification-architecture.md`
**Scope:** architect / product-owner

VP-003 (workspace-escape Kani VP) references the error type inconsistently:
- BC-2.13.004 body: `Err(WorkspaceEscape)`
- BC-2.13.004 postconditions: `E-SANDBOX-004 WorkspaceEscape`
- verification-architecture.md VP-003 row: `WorkspaceEscapeError`

Three names for the same type in three files. Low severity (no behavioral impact
until implementation), but creates ambiguity for the implementer.

**Required fix:** architect to canonicalize to `FerrochainError` variant name in
verification-architecture.md; BC-2.13.004 postconditions and body use the error
taxonomy code `E-SANDBOX-004` as the authoritative public identifier.

---

## Trajectory

| Pass | Findings | Critical | High | Medium | Low |
|------|----------|----------|------|--------|-----|
| Pass 1 | 14 | 3 | 5 | 4 | 2 |
| Pass 2 | 5 | 1 | 3 | 1 | 0 |
| Pass 3 | 7 | 2 | 2 | 2 | 1 |

**Novelty:** HIGH — Pass 3 introduced crate-topology coherence as a new audit axis,
surfacing findings that prior passes did not check. Two of seven findings are
RESOLVED before the report was finalized (F-P3-02, F-P3-04 architecture layer).

---

## Process Gap Observation (S-7.02 Cycle-Closing Checklist)

No crate-roster-coherence lint currently enforces that all spec artifacts agree on
the workspace crate count. This gap allowed a 14-crate count to persist in
`product-brief.md` after the architect added four crates to ARCH-INDEX. A
`cargo xtask check-crate-roster` CI step that cross-validates ARCH-INDEX
§Canonical Crate Roster against `product-brief.md`, `prd.md`, and
`publish-all.sh` would prevent this class of drift.

**Follow-up story candidate for Phase 2 backlog:** "Add crate-roster-coherence
lint (xtask check-crate-roster) — cargo xtask CI step comparing ARCH-INDEX canonical
roster against product-brief.md topology section, prd.md workspace-topology NFR, and
namespace-reservation/publish-all.sh." Record per cycle-closing checklist S-7.02.
