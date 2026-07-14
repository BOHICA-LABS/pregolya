---
document_type: verification-property-index
level: L3
version: "1.0"
status: active
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
---

# VP-INDEX: ferrochain Verification Properties

> **Source of truth** for VP IDs, modules, tools, phases, and counts.
> All changes to VP-INDEX MUST propagate to `verification-architecture.md`
> (Provable Properties Catalog + P0 list) and `verification-coverage-matrix.md`
> (VP-to-Module table + Totals row) in the same burst.
>
> Arithmetic invariant: total (3) = P0 (3) + P1 (0) = Kani (3).

## Summary

| Metric | Count |
|--------|-------|
| Total VPs | 3 |
| Priority P0 | 3 |
| Priority P1 | 0 |
| Tool: Kani | 3 |
| Tool: proptest | 0 |
| Tool: fuzz | 0 |
| Tool: integration | 0 |
| Status: draft | 3 |
| Status: active | 0 |
| Status: passed | 0 |

## VP Catalog

| VP | Title | BC Anchor | DI | Module | Crate | Tool | Phase | Priority | Status | File |
|----|-------|-----------|-----|--------|-------|------|-------|----------|--------|------|
| VP-001 | BSP Super-Step Determinism | BC-2.03.001 | DI-001 | bsp-engine | ferrochain-graph | Kani | 6 | P0 | draft | VP-001.md |
| VP-002 | Session Triple-Address Uniqueness | BC-2.04.006 | DI-005 | session-index | ferrochain-checkpoint | Kani | 6 | P0 | draft | VP-002.md |
| VP-003 | Workspace Path Confinement | BC-2.13.004 | DI-007 | path-guard | ferrochain-sandbox | Kani | 6 | P0 | draft | VP-003.md |
