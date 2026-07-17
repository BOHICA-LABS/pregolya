---
document_type: verification-property-index
level: L3
version: "1.1"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
changelog:
  - "1.0 (initial): VP catalog authored with 5 VPs (3 Kani P0 + 2 integration P1)."
  - "1.1 (provenance-fix-169/2026-07-17): reorder VP Catalog columns so Tool is at awk $5 (validate-vp-consistency hook compatibility); remove 'Tool: ' prefix from Summary metric labels so declared label normalizes to bare tool name matching VP row normalization."
---

# VP-INDEX: ferrochain Verification Properties

> **Source of truth** for VP IDs, modules, tools, phases, and counts.
> All changes to VP-INDEX MUST propagate to `verification-architecture.md`
> (Provable Properties Catalog + P0 list) and `verification-coverage-matrix.md`
> (VP-to-Module table + Totals row) in the same burst.
>
> Arithmetic invariant: total (5) = P0 (3) + P1 (2) = Kani (3) + integration (2).

## Summary

| Metric | Count |
|--------|-------|
| Total VPs | 5 |
| Priority P0 | 3 |
| Priority P1 | 2 |
| Kani | 3 |
| proptest | 0 |
| fuzz | 0 |
| integration | 2 |
| Status: draft | 5 |
| Status: active | 0 |
| Status: passed | 0 |

## VP Catalog

| VP | BC Anchor | Module | Tool | Phase | Priority | Status | DI | Crate | harness_fn | File |
|----|-----------|--------|------|-------|----------|--------|----|-------|------------|------|
| VP-001 | BC-2.03.001 | bsp-engine | Kani | 6 | P0 | draft | DI-001 | ferrochain-graph | `bsp_determinism_harness` | VP-001.md |
| VP-002 | BC-2.04.006 | session-index | Kani | 6 | P0 | draft | DI-005 | ferrochain-checkpoint | `session_tenancy_harness` | VP-002.md |
| VP-003 | BC-2.13.004 | path-guard | Kani | 6 | P0 | draft | DI-007 | ferrochain-sandbox | `workspace_confinement_harness` | VP-003.md |
| VP-004 | BC-2.09.004 | mcp-adapter | integration | 3 | P1 | draft | DI-014 | ferrochain-mcp | n/a (integration test) | VP-004.md |
| VP-005 | BC-2.09.005 | mcp-client | integration | 3 | P1 | draft | DI-014 | ferrochain-mcp | n/a (integration test) | VP-005.md |
