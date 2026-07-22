---
document_type: verification-property-index
level: L3
version: "1.5"
status: active
producer: architect
timestamp: 2026-07-22T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
changelog:
  - "1.5 (burst-232/2026-07-22): D23 VP layer — add VP-011..013 (3 Kani P0/P1); total 10→13, P0 5→6, P1 5→7, Kani 6→9. VP-011 (Kani P0, BC-2.05.007, graph::hitl): PreToolCallHook fail-closed dispatch. VP-012 (Kani P1, BC-2.10.005, core-budget): OnWatermark arithmetic. VP-013 (Kani P1, BC-2.23.005, tools-shell): BashTool risk floor."
  - "1.4 (burst-225/2026-07-21): F-P130-05 (MED) — correct VP-006 DI column: DI-008 → DI-014. Rationale: VP-006 proves the fail-closed property (injection detected → Err returned, no PromptValue produced); the semantically correct invariant is DI-014 (Error Propagation / No Silent Swallowing), not DI-008 (Library Constructor Result Contract). Siblings VP-009 and VP-010 both anchor DI-014 for the same class of proof. Arithmetic invariant unchanged (10 VPs, same tool/phase/priority distribution)."
  - "1.3 (burst-224/2026-07-21): F-P129-11 — update VP-009 module from vectorstores-mmr to vectorstores-similarity; cosine_similarity is the shared primitive in the renamed module; MMR selection algorithm (vectorstores::mmr) is a separate caller of cosine_similarity."
  - "1.2 (burst-223/2026-07-21): D21 VP layer — add VP-006..010 (3 Kani + 2 proptest); total 5→10, P0 3→5, P1 2→5, Kani 3→6, proptest 0→2."
  - "1.1 (provenance-fix-169/2026-07-17): reorder VP Catalog columns so Tool is at awk $5 (validate-vp-consistency hook compatibility); remove 'Tool: ' prefix from Summary metric labels so declared label normalizes to bare tool name matching VP row normalization."
  - "1.0 (initial): VP catalog authored with 5 VPs (3 Kani P0 + 2 integration P1)."
---

# VP-INDEX: ferrochain Verification Properties

> **Source of truth** for VP IDs, modules, tools, phases, and counts.
> All changes to VP-INDEX MUST propagate to `verification-architecture.md`
> (Provable Properties Catalog + P0 list) and `verification-coverage-matrix.md`
> (VP-to-Module table + Totals row) in the same burst.
>
> Arithmetic invariant: total (13) = P0 (6) + P1 (7) = Kani (9) + proptest (2) + integration (2).

## Summary

| Metric | Count |
|--------|-------|
| Total VPs | 13 |
| Priority P0 | 6 |
| Priority P1 | 7 |
| Kani | 9 |
| proptest | 2 |
| fuzz | 0 |
| integration | 2 |
| Status: draft | 13 |
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
| VP-006 | BC-2.18.004 | injection_guard | Kani | 6 | P1 | draft | DI-014 | ferrochain-prompts | `injection_guard_fail_closed` | VP-006.md |
| VP-007 | BC-2.19.001 | serializable | proptest | 3 | P1 | draft | DI-008 | ferrochain-core | n/a (proptest) | VP-007.md |
| VP-008 | BC-2.22.001 | embeddings | proptest | 3 | P1 | draft | DI-014 | ferrochain-core | n/a (proptest) | VP-008.md |
| VP-009 | BC-2.21.003 | vectorstores-similarity | Kani | 6 | P0 | draft | DI-014 | ferrochain-vectorstores | `zero_norm_guard_fail_closed` | VP-009.md |
| VP-010 | BC-2.19.005 | serializable-reviver | Kani | 6 | P0 | draft | DI-014 | ferrochain-core | `allowlist_rejects_unregistered_id` | VP-010.md |
| VP-011 | BC-2.05.007 | hitl | Kani | 6 | P0 | draft | DI-014 | ferrochain-graph | `deny_excludes_tool_invocation` | VP-011.md |
| VP-012 | BC-2.10.005 | core-budget | Kani | 6 | P1 | draft | DI-014 | ferrochain-core | `watermark_arithmetic_harness` | VP-012.md |
| VP-013 | BC-2.23.005 | tools-shell | Kani | 6 | P1 | draft | DI-014 | ferrochain-tools | `risk_floor_rejects_below_medium` | VP-013.md |
