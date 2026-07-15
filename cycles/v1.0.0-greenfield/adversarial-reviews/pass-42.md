---
document_type: adversarial-review
pass: 42
verdict: NOT_CLEAN
severity: HIGH
novelty: MEDIUM
phase: 1d
timestamp: 2026-07-14T06:00:00Z
findings_count: 1
observations_count: 2
---

# Adversarial Review — Pass 42

## Verdict: NOT CLEAN — 1 finding (HIGH, mis-anchor, blast radius 2). Novelty MEDIUM.

---

## Findings

### F-P42-01 (HIGH): BC-2.08.011 / BC-2.08.012 Architecture Anchors Cite Wrong Crate for StateGraph Builder

**Location:** `specs/behavioral-contracts/ss-08/BC-2.08.011.md` line 112;
`specs/behavioral-contracts/ss-08/BC-2.08.012.md` line 119

**Defect:** Both BCs' Architecture Anchors sections cite
`ferrochain-core/src/graph/builder.rs` as the home of the StateGraph builder
(`add_edge`/`add_node` API). This is a wrong-crate assignment. The StateGraph builder
is authoritatively owned by `ferrochain-graph` per three converging authorities:

| Authority | Evidence |
|-----------|----------|
| ADR-007 crate roster (§Full Crate Roster) | `ferrochain-core` = "Core traits, types, error taxonomy"; `ferrochain-graph` = "StateGraph BSP engine, HITL, budget, provenance" |
| module-decomposition.md line ~52 | `graph::definition` — `StateGraph` builder, node/edge registration — listed under `ferrochain-graph (SS-02, SS-03, SS-05, SS-10, SS-11)`; `ferrochain-core` module list has NO graph or definition module |
| BC-2.02.001 line 130 (Architecture Anchors) | `ferrochain-graph/src/graph/state.rs — StateGraph builder (add_node, add_edge, compile)` — the authoritative sibling BC for the StateGraph builder API |

**BC-2.08.011** cites `ferrochain-core/src/graph/builder.rs — StateGraph builder START edge wiring`.
The `#[entrypoint]` macro generates `add_edge(START, ...)` — that call targets the builder in
`ferrochain-graph`, not `ferrochain-core`.

**BC-2.08.012** cites `ferrochain-core/src/graph/builder.rs — add_node API that the generated code calls`.
The `#[task]` macro generates `add_node(...)` — that call also targets `ferrochain-graph`.

The path `ferrochain-core/src/graph/builder.rs` resolves to no workspace artifact — no such
module exists under ferrochain-core per module-decomposition.md or ADR-007 — and would misdirect
`#[entrypoint]`/`#[task]` implementers and story-writer agents to the wrong crate.

**Not covered by the "to be created" exemption:** The paths carry no `(to be created)` marker.
More importantly, the exemption only covers files that don't yet exist in a correct crate; it
does not cover assignments to the wrong crate. Wrong-crate is a semantic error regardless of
whether the file exists.

**Blast radius:** BC-2.08.011 (line 112) + BC-2.08.012 (line 119) — exactly 2 hits.
`grep -rn "ferrochain-core/src/graph" .factory/specs/behavioral-contracts/` confirms exactly
these 2 occurrences and no others.

**Fix:** Re-anchor both BCs to `ferrochain-graph/src/graph/state.rs` (matching BC-2.02.001 line 130),
keeping each line's descriptive suffix accurate to the macro's actual API call.

**[process-gap]:** The five-way anchor-matrix census (gate #13) covers anchor COLUMNS in
BC body Traceability tables (CAP, DI, NE, R, ADR, VP). It does not cover the free-text
`## Architecture Anchors` bullet section, where crate paths are written in prose without a
cross-verified column format. F-P42-01 survived 41 passes because no standing gate systematically
extracted and verified crate names from Architecture Anchor bullets. Recommending new standing
gate #27: crate-resolution census (every `ferrochain-<crate>/src/...` and `xtask/` path in BC
Architecture Anchors must name a crate from the ADR-007 18-crate roster + xtask, and must assign
the module to the crate that owns it per module-decomposition.md / ADR-007 responsibilities).

---

## Observations

### OBS-P42-1: E-GRAPH-014 Message Template Placeholder Not a Retired Identifier Risk

**Location:** `specs/prd-supplements/error-taxonomy.md` — E-GRAPH-014 message template

E-GRAPH-014's message template contains `(tier '<tier>')` where `<tier>` is a display placeholder
(angle-bracket substitution syntax). This is not a use of the retired identifier `risk_tier`; it is
a message-format placeholder for a tier-level string that uses a different label. The message
template is rendering a `BudgetPolicy` tier name at runtime, not the `risk_tier` field from
`Run.interrupt`. Defensible. No finding.

### OBS-P42-2: BC-2.08.010 Tool Trait Anchored to ferrochain-core — Defensible

**Location:** `specs/behavioral-contracts/ss-08/BC-2.08.010.md` Architecture Anchors

`ferrochain-core/src/tool.rs` is cited as the `Tool` trait definition, re-exported from
`ferrochain-macros`. Per ADR-007: "ferrochain-macros is re-exported from ferrochain-core via
`pub use ferrochain_macros::*`." A re-export anchor in ferrochain-core/src/tool.rs is architecturally
correct — the consumer-facing definition lives in ferrochain-core even though the macro
implementation is in ferrochain-macros. This is analogous to how `core::runnable` defines
`Runnable<I,O>` in ferrochain-core. No finding.

---

## Regression Spot-Checks

1. **Batch-table cells (F-P40-01 fix):** BC-2.08.007 DI cell = `DI-009, DI-014`; BC-2.08.001–005 CAP = `CAP-009`; BC-2.10.004 CAP = `CAP-012`; BC-2.05.006 DI = `DI-003`. All five-way carriers consistent. **PASS.**
2. **E-RETRY-003 separation (F-P34-03 fix):** error-taxonomy.md `E-RETRY-003` variant name `InvalidRetryLimit` confirmed. No space-only regex gap. **PASS.**
3. **ADR-006 and ADR-001 headings (F-P36-01 fix):** ADR-006 `## Decision:` heading reads "ferrochain-native streaming wire format"; ADR-001 heading consistent. **PASS.**
4. **Derived criticality docs (F-P37-01/02 fix):** module-decomposition.md `core::message = HIGH`, `graph::channels = HIGH`, `graph::event_emitter = MEDIUM`, `ferrochain-macros = HIGH`; all match module-criticality.md authoritative registry. **PASS.**

---

## Standing Gate Censuses

### Census #21 — Anchor-Matrix (PASS)
Five-way consistency check across all 86 BCs × {CAP, DI, NE, R, ADR, VP} axes:
BC body ↔ BC-INDEX ↔ PRD §2/§7/§9 ↔ authoritative registry ↔ bc-authoring-plan batch-table.
Zero drifts found.

### Census #22 — RetryHint Coherence (PASS)
Exactly 5 codes with intentional divergences as documented. No orphan divergences found.

### Census #23 — Streaming Event Names (PASS)
11 imperative tokens + envelope confirmed. Zero retired names (`RunStarted`, `node_delta`, etc.)
in non-exempt files.

### Census #26 — Structurally-Privileged-Line Canon Check (PASS)
Zero live retired canon claims in H1/H2/H3 headings across checked artifacts.

---

## Novel Probes

### Probe A — L2 DEC Register (CLEAN)
13/13 domain edge cases (DEC-001 through DEC-013) resolved to at least one BC with explicit DEC
citation or equivalent edge-case coverage. No contradictions between DEC expected behavior and
BC edge-case postconditions.

### Probe B — ASM Register (CLEAN)
9/9 assumptions (ASM-001 through ASM-009) in assumptions.md are active (none retired). ASM-005
and ASM-006 carry documented confidence flags and trigger conditions. No orphan assumptions.

---

## Novelty Assessment: MEDIUM

New carrier class discovered: **free-text Architecture Anchor crate paths** (`## Architecture Anchors`
bullet lines containing `ferrochain-<crate>/src/...` paths) are not covered by any standing gate.
Gate #13 (anchor-matrix census) covers structured Traceability column cells, not free-text bullet
paths. F-P42-01 (BC-2.08.011/012 citing `ferrochain-core/src/graph/builder.rs` instead of the
correct `ferrochain-graph/src/graph/state.rs`) survived 41 passes under this blind spot.
Recommending gate #27 (crate-resolution census) to make Architecture Anchor crate paths
machine-verifiable going forward.

---

## Fix Burst Summary (Phase 1d)

Applied in this burst:

- **F-P42-01 fix:** BC-2.08.011 line 112: `ferrochain-core/src/graph/builder.rs — StateGraph builder START edge wiring` → `ferrochain-graph/src/graph/state.rs — StateGraph builder START edge wiring (add_edge API the macro calls)`. Version bumped 1.0→1.1; changelog added.
- **F-P42-01 fix:** BC-2.08.012 line 119: `ferrochain-core/src/graph/builder.rs — add_node API that the generated code calls` → `ferrochain-graph/src/graph/state.rs — add_node API that the generated code calls`. Version bumped 1.0→1.1; changelog added.
- **Gate #27 minted + full census run:** bc-authoring-plan.md gate #27 "architecture-anchor crate-resolution census" added. Full census run across all 86 BCs × 187 Architecture Anchor crate paths: 16 distinct crate names found (all valid per ADR-007 roster). Wrong-crate anchors: exactly 2 (both fixed above). Zero remaining wrong-crate anchors after fixes. `total_standing_gates` 26→27; version v1.4→v1.5; changelog entry added.
