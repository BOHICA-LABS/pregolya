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
pass: 101
previous_review: pass-100.md
---

# Adversarial Review: ferrochain (Pass 101)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 100 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P100-01 | MED (BA) | RESOLVED | events.md v1.3→v1.4: StreamEventEmitted Outcome qualified — execution-lifecycle DI-011 equivalence retained; guardrail_decision stream-observer-only, unary observes via error blocks per BC-2.06.003. |
| F-P100-02 | MED (PO) | RESOLVED | BC-2.11.003 v1.4→v1.5 + BC-2.11.004 v1.4→v1.5: PC3 Fail-emission + PC4 Transform-emission added per boundary (RagChunk/MemoryItem, NodeStart/NodeEnd window, tool_call_id: None, INV-5 cites). ADR-006 rev-3→rev-4 (downstream-amendments scope note + BC cite extended 002/003/004). Interface-definitions v2.34→v2.35 (/stream row + §StreamEvent BC anchors per-boundary). |
| F-P100-03 | OBS (BA) | RESOLVED | events.md v1.4 (consolidated with F-P100-01): GuardrailChecked Outcome aligned Accept/Reject/Redact→Pass/Fail/Transform (F-P58-03 retirement authority; Transform = strict superset; no semantic narrowing). |

**Radius-closure directive (burst-182 owed list — GuardrailDecision radius):**

| Check | Result |
|-------|--------|
| SS-11 triple symmetry — BC-2.11.002 v1.6 / BC-2.11.003 v1.5 / BC-2.11.004 v1.5 — 9-dimension table fully symmetric (PC3/PC4 present; emission window asymmetry per ADR-006 = design-correct; no-TV consistent non-gap) | PASS |
| ADR-006 rev-4 downstream-amendments scope note + BC cite extended to 002/003/004 | PASS |
| Interface-definitions v2.35 /stream row updated + §StreamEvent BC anchors per-boundary; remaining BC-2.11.002-only cites verified as type-definition authorities (correct) | PASS |
| Zero remaining Accept/Reject/Redact live vocabulary corpus-wide (per F-P100-03 retirement) | PASS |
| Gate #12 lifecycle census — StreamEvent 12-variant count consistent across: BC-2.06.001 PC2, ADR-006, interface-definitions §StreamEvent table, events.md StreamEventEmitted trigger | PASS |
| StreamEvent 12-variant triple-coherence: BC-2.06.001 PC2 ↔ ADR-006 ↔ interface-definitions §StreamEvent all cite same 12 variants + same field shapes for GuardrailDecision | PASS |

**Additional radius probes (run-lifecycle state-machine, BC-INDEX subsystem sync):**

| Probe | Result |
|-------|--------|
| Run-lifecycle state machine (NodeStart→NodeEnd / ToolInvoked→ToolEnd / GuardrailDecision sequencing): coherent across BC-2.11.002/003/004, ADR-006 causal ordering, interface-definitions /stream ordering note | PASS |
| BC-INDEX subsystem sync: BC-2.11.003 + BC-2.11.004 title cells match H1 exactly (post-v1.5 bump) | PASS |

**Radius-closure verdict:** ONE residue found (F-P101-01 — events.md GuardrailChecked Stream-surface ordering clause unconditional). All other GuardrailDecision radius items verified closed.

## Part B — New Findings

### MED [process-gap]

#### F-P101-01: events.md GuardrailChecked Stream-surface Ordering Clause — Unconditional "fires before tool_end"

- **Severity:** MED [process-gap]
- **Owner:** BA
- **Category:** behavioral-observability (boundary-qualification completeness)
- **Location:** events.md §GuardrailChecked — Stream-surface subsection ordering clause
- **Description:** The events.md Stream-surface clause for GuardrailChecked stated "fires before the enclosing tool_end" unconditionally. This is correct for ToolResult boundaries (where tool_call_id is present and tool_end exists in the execution window), but incorrect for RagChunk and MemoryItem boundaries — those boundaries carry no tool_end event; GuardrailDecision fires within the NodeStart/NodeEnd envelope, not before a tool_end. The unconditional phrasing was a radius residue from D18-P99-A: burst-181 added the ToolResult-boundary ordering clause (fires before tool_end) but burst-182's fix to the RAG/Memory boundary emission did not update the ordering prose to qualify it by boundary type.
- **Evidence:** BC-2.06.001 PC4 and ADR-006 define two distinct ordering rules: (1) GuardrailDecision fires BEFORE tool_end when boundary = ToolResult; (2) GuardrailDecision fires WITHIN NodeStart/NodeEnd (before inference) when boundary = RagChunk or MemoryItem. events.md Stream-surface clause carried only rule (1) without the "ToolResult boundary only" qualifier, creating a false implication that rule (1) applies for all boundary types.
- **Fix (events.md v1.4→v1.5):** Ordering clause boundary-qualified: for ToolResult boundaries (tool_call_id present) — fires before the enclosing tool_end; for RagChunk/MemoryItem boundaries (tool_call_id absent) — fires within the NodeStart/NodeEnd envelope, before inference; per ADR-006 + BC-2.06.001 PC4. Sibling sweep: ToolInvoked stream-surface line correctly scoped to tool boundaries only (no change needed). No other unconditional ordering claims found in events.md. events.md v1.4 → v1.5.
- **Sweep:** Zero other unconditional ordering claims elsewhere in events.md. BC-2.06.001 PC4, ADR-006 ordering section, and interface-definitions ordering note all already boundary-qualified — no changes required in those files.

### OBS

#### F-P101-02: BC-2.11.002 Changelog Rows Display-Inverted (v1.6/v1.5 order)

- **Severity:** OBS
- **Owner:** PO
- **Category:** metadata-ordering (changelog convention)
- **Location:** BC-2.11.002 changelog section — rows v1.6 and v1.5
- **Description:** The BC-2.11.002 changelog section listed version 1.6 before 1.5, which is the correct newest-first ascending convention, but the rows themselves were display-inverted relative to the file's established ascending order convention (v1.0 at top, newest at bottom per the descending-row pattern used across the corpus). Both rows were present; the content was correct; only the display order was inverted vs the file's convention.
- **Evidence:** BC-2.11.002 changelog rows for v1.5 and v1.6 appeared in reverse order relative to the ascending convention used in all other BC files in the corpus (D18-P64-B + gate #28 Rule 3 changelog monotonicity requirement). The v1.6 row (burst-181 fix) was inserted above v1.5 (burst-179 baseline), creating a display-inversion that contradicts the ascending convention.
- **Fix:** Reordered rows to ascending convention (v1.5 above v1.6). Pure metadata reorder — no content change. YAML valid. Gate #28 Rule 3 satisfied.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 1 (process-gap) |
| LOW | 0 |
| OBS | 1 |

**Overall Assessment:** NOT CLEAN strict — 1 MED [process-gap] + 1 OBS, BOTH FIXED in burst 183.
**Convergence:** FINDINGS_REMAIN (strict — 1 MED + 1 OBS; fixed in burst 183)
**Readiness:** CLEAN (PR-merge) — zero CRIT+HIGH+MED findings prior to fix; MED is [process-gap] subtype

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 101 |
| **New findings** | 2 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | MEDIUM (F-P101-01 = final radius residue of D18-P99-A two-burst propagation; F-P101-02 = metadata ordering — both are bounded, non-systemic) |
| **Median severity** | MED [process-gap] |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2 |
| **CLEAN (strict)** | no (1 MED [process-gap] + 1 OBS finding) |
| **CLEAN (PR-merge)** | yes (zero CRIT+HIGH+MED findings prior to fix; [process-gap] subtype) |
| **Verdict** | FINDINGS_REMAIN (NOT CLEAN strict); CLEAN (PR-merge) |

## Radius-Closure Verdict (GuardrailDecision)

The GuardrailDecision radius introduced by D18-P99-A (burst-181) and partially propagated in burst-182 is **NOW FULLY CLOSED** after burst-183 fixes F-P101-01. The two-burst propagation sequence is complete:

- Burst-181: ToolResult boundary ordering + 12-variant enum + BC-2.11.002 emission postconditions
- Burst-182: RAG/Memory boundary emission + events.md vocabulary (vocabulary gaps, GuardrailChecked Outcome)
- Burst-183: events.md ordering clause boundary-qualification (final residue) + BC-2.11.002 changelog reorder

If pass-102 finds any further GuardrailDecision-radius residue, severity should be escalated one level for repeated propagation failure per the PASS-102 sibling-check mandate.
