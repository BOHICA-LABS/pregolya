---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 102
previous_review: pass-101.md
---

# Adversarial Review: ferrochain (Pass 102)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 101 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P101-01 | MED [process-gap] (BA) | RESOLVED | events.md v1.4→v1.5: GuardrailChecked Stream-surface ordering clause boundary-qualified. ToolResult: fires before enclosing tool_end, tool_call_id present; RagChunk/MemoryItem: fires within NodeStart/NodeEnd envelope, before inference, tool_call_id absent; per ADR-006 + BC-2.06.001 PC4. ToolInvoked stream-surface line correctly tool-scoped — sweep confirmed no change needed. Zero other unconditional ordering claims. |
| F-P101-02 | OBS (PO) | RESOLVED | BC-2.11.002 changelog rows v1.6/v1.5 reordered to ascending convention (pure metadata reorder; no content change; YAML valid; gate #28 Rule 3 satisfied). |

**Sibling-checks (burst-183 owed list):**

| Check | Result |
|-------|--------|
| events.md v1.5 boundary-qualified ordering clause coherent with ADR-006 causal ordering + BC-2.06.001 PC4 (ToolResult: before tool_end; RagChunk/MemoryItem: within NodeStart/NodeEnd) | PASS |
| BC-2.11.002 changelog ascending convention (v1.5 above v1.6) | PASS |
| Final radius grep — GuardrailDecision residue corpus-wide | PASS — zero further residue found |

**GuardrailDecision radius verdict (D18-P102-A prerequisite check):** All three sibling-checks PASS. The D18-P99-A three-burst propagation (burst-181/182/183) is confirmed FULLY CLOSED. No escalation warranted.

## Part B — New Findings

### LOW

#### F-P102-01: BC-2.11.005 Changelog Rows Transposed (1.0, 1.1, 1.3, 1.2)

- **Severity:** LOW
- **Owner:** PO
- **Category:** metadata-ordering (changelog convention)
- **Location:** BC-2.11.005 changelog section — rows v1.2 and v1.3
- **Description:** The BC-2.11.005 changelog section listed version 1.3 before 1.2, violating the ascending-order convention established for BC files (gate #28 Rule 3). The entry for v1.3 (F-P99-01, 2026-07-17) appeared above v1.2 (ADV-P1D-PASS-59) in the YAML list. Both rows were present with correct content; only the display order was inverted.
- **Evidence:** BC-2.11.005 changelog YAML list: [1.0, 1.1, 1.3, 1.2]. Expected order per gate #28 Rule 3 ascending convention for BC files: [1.0, 1.1, 1.2, 1.3]. This is the same class as F-P101-02 (BC-2.11.002) and F-P97-03 (BC-2.08.006) — changelog-transposition recurrence class.
- **Fix:** Reorder rows to ascending convention (1.0, 1.1, 1.2, 1.3). Pure metadata reorder — no content change, no version bump. Gate #28 Rule 3 satisfied.

### [process-gap] OBS

#### F-P102-OBS-A: Gate #28 Lacks VERSION-MONOTONICITY Sub-Check (3rd Recurrence — Codification Threshold Met)

- **Severity:** OBS [process-gap]
- **Owner:** PO (orchestrator codification decision — 3rd recurrence threshold met per lessons-codification.md)
- **Category:** process-gap (gate coverage gap)
- **Location:** bc-authoring-plan.md gate #28 — VERSION-MONOTONICITY rule absent
- **Description:** Gate #28 governs changelog-date monotonicity (Rules 1–5) but has no rule for version NUMBER ordering. F-P97-03 (BC-2.08.006), F-P101-02 (BC-2.11.002), and F-P102-01 (BC-2.11.005) are three consecutive instances of the same finding class: changelog rows with correct version numbers but wrong display order. Three recurrences of the same class — the class is structural, not accidental; manual spot-checks are demonstrably insufficient for the 124-file changelog corpus (confirmed by the first full census below). Codification is mandatory per the 3-recurrence threshold.
- **Fix (D18-P102-A — orchestrator codification decision):** Gate #28 gains RULE 6 VERSION-MONOTONICITY (CHANGELOG-MONOTONICITY). Direction is per file class: behavioral-contracts/ and architecture/ files ascend (oldest-to-newest); prd-supplements/ files descend (newest-at-top per D18-P64-B). Equal-version adjacent rows permitted (not a violation). The census command is section-scoped to read only the changelog YAML block, avoiding false positives from gate-prose content. Machine enforcement decision tree extended to rules 1–6 (DEFER-002). bc-authoring-plan v2.30 → v2.31. A first full corpus census was run and found 13 additional latent transposed files (invisible to 102 prior passes): api-surface.md, module-decomposition.md, BC-2.03.001, BC-2.05.006, BC-2.06.001, BC-2.08.002, BC-2.09.001, BC-2.09.005, BC-2.12.005, BC-2.12.007, BC-2.14.002 (all repaired ASCENDING per BC/architecture convention) + error-taxonomy.md (8 violations, repaired DESCENDING per supplement convention) + interface-definitions.md (22 violations, repaired DESCENDING per supplement convention). All 14 total transposed files repaired as pure reorders (no content changes, no version bumps). Post-census: 124 files scanned, 0 violations.

**Orchestrator correction note:** The first census repair pass incorrectly force-ascended error-taxonomy.md and interface-definitions.md. These are supplement files governed by D18-P64-B (descending/newest-at-top convention). The error was caught and reversed before commit. The census command was also corrected to be direction-aware so gate #28 Rule 6 does not institutionalize the ascending-only bias.

## Part C — Additional Probes

### Gate Checks

| Gate | Result |
|------|--------|
| Gate #28 Rules 1–5 on all changelog-bearing files touched in burst-183 | PASS |
| Gate #28 Rule 6 new census (post-fix): 124 files scanned, 0 violations | PASS |
| Gate #28 (SS-TBD) sub-check: zero live `SS-TBD` references in BC bodies | PASS |
| Gate #13 VP-uniqueness census: zero duplicate VP IDs corpus-wide | PASS |
| Gate #33 9-artifact sample reverse-verification | PASS |
| Hedge sweep (all five hedged-claim patterns) | PASS |

### Fresh Probes

| Probe | Result |
|-------|--------|
| ADR-006 rev-4 amendment completeness: all four downstream-amendment BCs (BC-2.11.002/003/004, BC-2.06.001) present and carry GuardrailDecision emission postconditions; scope note references all three boundaries | PASS |
| 12-variant StreamEvent count coherence: BC-2.06.001 PC2, ADR-006, interface-definitions §StreamEvent, events.md StreamEventEmitted trigger — all cite 12 variants | PASS |
| Streaming-surface field coherence: GuardrailDecision field shapes consistent across interface-definitions §StreamEvent ↔ BC-2.11.002/003/004 PC3/PC4 ↔ ADR-006 payload definition | PASS |

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 0 |
| LOW | 1 |
| OBS [process-gap] | 1 |
| **Total** | **2** |

**CLEAN (strict):** no (1 LOW + 1 OBS/process-gap)
**CLEAN (PR-merge):** yes (zero CRIT/HIGH/MED)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** LOW (same recurrence class as F-P97-03 and F-P101-02; no new axes)
**GuardrailDecision radius verdict:** FULLY CLOSED (all three sibling-checks PASS; 3/3 PASS incl. final radius grep; no escalation)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 102 |
| **New findings** | 1 |
| **Duplicate/variant findings** | 1 |
| **Novelty score** | LOW (F-P102-01 = 3rd recurrence of changelog-transposition class; F-P102-OBS-A = codification of the recurrence class, not a new axis) |
| **Median severity** | LOW |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2 |
| **CLEAN (strict)** | no (1 LOW + 1 OBS/process-gap) |
| **CLEAN (PR-merge)** | yes (zero CRIT/HIGH/MED) |
| **Verdict** | FINDINGS_REMAIN (NOT CLEAN strict); CLEAN (PR-merge) |
