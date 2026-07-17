---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T20:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 96
previous_review: pass-95.md
---

# Adversarial Review: ferrochain (Pass 96)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 95 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P95-01 | MED | RESOLVED | ADR-001 rev-2 / ADR-009 v1.3 / ADR-012 v1.3 — zero "between super-steps" / "live evaluation" placement residue; EVALUATION per-call during Collecting; HALT at super-step boundary confirmed at all 6 sites. |
| F-P95-02 | MED [process-gap] | RESOLVED | bc-authoring-plan v2.27 gate #13 regex VP-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]+; census recount 141 unique VP IDs; VP-STREAM + VP-BUDGET domains disjoint; zero duplicates. |
| F-P95-03 | LOW | RESOLVED | BC-2.10.004 v1.6 PC1..PC4 clean (verbatim duplicate removed; 1a/1b/2b numbering eliminated); BC-2.10.001 v1.5 Related-BCs cite updated. |
| F-P95-04 | LOW | RESOLVED | capabilities-p0 v1.3 CAP-012 three-mode (halt + HITL + summarize); BC-2.10.004 v1.6 CAP-012 verbatim quote refreshed in-burst. |
| OBS-P95-A | OBS | RESOLVED | VP-SPLIT-01..08 digit renumber applied in BC-2.07.001 v1.1 / BC-2.07.002 v1.3 / BC-2.07.003 v1.1; no VP-INDEX impact (SPLIT VPs are BC-local). |

Sibling-checks verified PASS (5/5): budget-model reconciliation; gate #13 census 141 IDs, VP-STREAM/VP-BUDGET disjoint; BC-2.10.004 v1.6 PC1..PC4 + CAP-012 verbatim quote; VP-SPLIT-01..08 renumber; VP-INDEX ↔ coverage-matrix ↔ verification-architecture triple-agreement; BC H1 ↔ BC-INDEX sync (15+ sample); SS-01 / SS-14 / SS-17 content probes.

## Part B — New Findings

### CRITICAL
_None._

### HIGH
_None._

### MEDIUM
_None._

### LOW
_None._

### OBS

#### F-P96-01: Vestigial `[architect to assign — <crate>]` placeholders in 59 BC Traceability Module fields

- **Severity:** OBS [process-gap]
- **Category:** spec-fidelity
- **Location:** 59 BC files across SS-01..SS-17 (Traceability section `| Module |` row)
- **Owner:** PO (orchestrator adjudicated option (a) resolve per CLAUDE.md Rule 6)
- **Description:** 59 behavioral contracts carried vestigial `[architect to assign — <crate>]` text in their Traceability Module fields. SS-10 had been resolved at pass 61 (burst ~130); siblings in all other subsystem groups never received the propagation fix (S-7.01 partial-fix recurrence).
- **Evidence:** Representative pre-fix sample — `BC-2.01.001: | Module | [architect to assign — ferrochain-core] |`; `BC-2.07.001: | Module | [architect to assign — ferrochain-splitters] |`; `BC-2.09.003: | Module | [architect to assign — ferrochain-mcp] |`. Full grep: `grep -r "\[architect to assign" .factory/specs/behavioral-contracts/` returned 59 hits across 59 files before fix.
- **Proposed Fix:** Resolve all 59 placeholders declaratively from module-decomposition v1.10; patch-bump each BC with changelog row; update bc-authoring-plan gate #27 to remove the placeholder exemption class.

**Fix applied in burst 178:**
All 59 BCs resolved from module-decomposition v1.10. Resolution spans SS-01..SS-17; dual-crate assignments where BCs span trait/engine split (e.g., ferrochain-core + ferrochain-graph) or lib/server split (e.g., ferrochain-server + ferrochain-core); SS-17 → `kani_proofs/` + `fuzz/`. Zero ambiguous leftovers. Each BC patch-bumped with changelog row. Post-sweep: `grep -r "\[architect to assign" .factory/specs/behavioral-contracts/` → zero hits. All 95 BC hashes MATCH (D18-P89-A sweep). bc-authoring-plan v2.27 → v2.28: gate #27 exemption for `[architect to assign]` class REMOVED — resolved crate assignment mandatory from authoring (F-P96-01, 2026-07-17).

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |
| OBS | 1 |

**Overall Assessment:** pass-with-findings (1 OBS only)
**Convergence:** FINDINGS_REMAIN (strict — 1 OBS finding present; fixed in burst 178)
**Readiness:** CLEAN (PR-merge) — zero CRIT+HIGH+MED findings; ready for pass 97 on burst-178 HEAD

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 96 |
| **New findings** | 1 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (1 new, 0 duplicate) |
| **Median severity** | OBS [process-gap] (below LOW; placeholder hygiene) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1 |
| **Verdict** | FINDINGS_REMAIN (NOT CLEAN strict); CLEAN (PR-merge) |
