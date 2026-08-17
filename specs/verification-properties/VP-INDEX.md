---
document_type: verification-property-index
level: L3
version: "1.8"
status: active
producer: architect
timestamp: 2026-08-17T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
changelog:
  - "1.8 (burst-302b/D-170/2026-08-17): Add VP-014 — RunnableParallel key-completeness proptest P1 (BC-2.01.005 + BC-2.01.006, module core::runnable::parallel, crate pregolya-core, DI-016). LCEL composition scope expansion (D-170). Arithmetic: total 13→14 (P0 6→6 unchanged, P1 7→8); proptest 2→3; Kani/integration unchanged. Status:draft 13→14."
  - "1.7 (FIX-BURST-276/2026-07-27): CHECK4 closure — canonicalize all 13 Module cells in VP Catalog from hyphenated short forms to crate::module form. Canonical source: module-decomposition.md. Mappings: bsp-engine→graph::bsp_engine (graph::bsp_engine row), session-index→checkpoint::session_index (checkpoint::session_index row), path-guard→sandbox::path_guard (sandbox::path_guard row), mcp-adapter→mcp::adapter (mcp::adapter row), mcp-client→mcp::client (mcp::client row), injection_guard→prompts::injection_guard (prompts::injection_guard row), serializable→core::serializable (core::serializable LcSerializable round-trip aspect VP-007), embeddings→core::embeddings (core::embeddings row VP-008), vectorstores-similarity→vectorstores::similarity (vectorstores::similarity row VP-009), serializable-reviver→core::serializable (core::serializable Reviver aspect VP-010), hitl→graph::hitl (graph::hitl row VP-011), core-budget→core::budget (core::budget row VP-012), tools-shell→tools::shell (tools::shell row VP-013). Arithmetic invariant unchanged: 13 VPs, counts unmodified."
  - "1.6 (FIX-BURST-257/2026-07-24): OBS-P156-B — add VP priority clarification note: VP priority is the VERIFICATION-priority axis (proof criticality), distinct from the anchor BC's implementation priority; a P0 VP may anchor a P1 BC (examples: VP-003 Kani P0 anchors P1 BC-2.13.004; VP-011 Kani P0 anchors P1 BC-2.05.007). Note added in preamble blockquote and Summary section. No VP catalog rows changed; arithmetic invariant unchanged."
  - "1.5 (burst-232/2026-07-22): D23 VP layer — add VP-011..013 (3 Kani P0/P1); total 10→13, P0 5→6, P1 5→7, Kani 6→9. VP-011 (Kani P0, BC-2.05.007, graph::hitl): PreToolCallHook fail-closed dispatch. VP-012 (Kani P1, BC-2.10.005, core-budget): OnWatermark arithmetic. VP-013 (Kani P1, BC-2.23.005, tools-shell): BashTool risk floor."
  - "1.4 (burst-225/2026-07-21): F-P130-05 (MED) — correct VP-006 DI column: DI-008 → DI-014. Rationale: VP-006 proves the fail-closed property (injection detected → Err returned, no PromptValue produced); the semantically correct invariant is DI-014 (Error Propagation / No Silent Swallowing), not DI-008 (Library Constructor Result Contract). Siblings VP-009 and VP-010 both anchor DI-014 for the same class of proof. Arithmetic invariant unchanged (10 VPs, same tool/phase/priority distribution)."
  - "1.3 (burst-224/2026-07-21): F-P129-11 — update VP-009 module from vectorstores-mmr to vectorstores-similarity; cosine_similarity is the shared primitive in the renamed module; MMR selection algorithm (vectorstores::mmr) is a separate caller of cosine_similarity."
  - "1.2 (burst-223/2026-07-21): D21 VP layer — add VP-006..010 (3 Kani + 2 proptest); total 5→10, P0 3→5, P1 2→5, Kani 3→6, proptest 0→2."
  - "1.1 (provenance-fix-169/2026-07-17): reorder VP Catalog columns so Tool is at awk $5 (validate-vp-consistency hook compatibility); remove 'Tool: ' prefix from Summary metric labels so declared label normalizes to bare tool name matching VP row normalization."
  - "1.0 (initial): VP catalog authored with 5 VPs (3 Kani P0 + 2 integration P1)."
---

# VP-INDEX: pregolya Verification Properties

> **Source of truth** for VP IDs, modules, tools, phases, and counts.
> All changes to VP-INDEX MUST propagate to `verification-architecture.md`
> (Provable Properties Catalog + P0 list) and `verification-coverage-matrix.md`
> (VP-to-Module table + Totals row) in the same burst.
>
> Arithmetic invariant: total (14) = P0 (6) + P1 (8) = Kani (9) + proptest (3) + integration (2).
>
> **VP Priority vs BC Priority (OBS-P156-B):** The `Priority` column here is the
> **verification-priority axis** — it reflects proof criticality (how urgently this property
> needs formal verification) and determines Phase 6 Kani harness scheduling (P0 before P1).
> It is **not** the same as the anchor BC's implementation priority. A P0 VP may anchor a
> P1 BC when the underlying security or correctness property warrants early formal proof
> regardless of wave ordering. Examples: VP-003 (Kani P0) anchors BC-2.13.004 (P1 BC —
> workspace confinement must be formally proven even if the sandbox crate ships in Wave 1 P1
> scope); VP-011 (Kani P0) anchors BC-2.05.007 (P1 BC — PreToolCallHook fail-closed dispatch
> requires early Kani proof due to security significance). The mapping is VP priority → proof
> schedule; BC priority → implementation wave.

## Summary

> **Priority note:** P0/P1 below is verification-priority (proof criticality), not BC
> implementation priority. See preamble for the VP-priority vs BC-priority distinction.

| Metric | Count |
|--------|-------|
| Total VPs | 14 |
| Priority P0 (verification-priority) | 6 |
| Priority P1 (verification-priority) | 8 |
| Kani | 9 |
| proptest | 3 |
| fuzz | 0 |
| integration | 2 |
| Status: draft | 14 |
| Status: active | 0 |
| Status: passed | 0 |

## VP Catalog

| VP | BC Anchor | Module | Tool | Phase | Priority | Status | DI | Crate | harness_fn | File |
|----|-----------|--------|------|-------|----------|--------|----|-------|------------|------|
| VP-001 | BC-2.03.001 | graph::bsp_engine | Kani | 6 | P0 | draft | DI-001 | pregolya-graph | `bsp_determinism_harness` | VP-001.md |
| VP-002 | BC-2.04.006 | checkpoint::session_index | Kani | 6 | P0 | draft | DI-005 | pregolya-checkpoint | `session_tenancy_harness` | VP-002.md |
| VP-003 | BC-2.13.004 | sandbox::path_guard | Kani | 6 | P0 | draft | DI-007 | pregolya-sandbox | `workspace_confinement_harness` | VP-003.md |
| VP-004 | BC-2.09.004 | mcp::adapter | integration | 3 | P1 | draft | DI-014 | pregolya-mcp | n/a (integration test) | VP-004.md |
| VP-005 | BC-2.09.005 | mcp::client | integration | 3 | P1 | draft | DI-014 | pregolya-mcp | n/a (integration test) | VP-005.md |
| VP-006 | BC-2.18.004 | prompts::injection_guard | Kani | 6 | P1 | draft | DI-014 | pregolya-prompts | `injection_guard_fail_closed` | VP-006.md |
| VP-007 | BC-2.19.001 | core::serializable | proptest | 3 | P1 | draft | DI-008 | pregolya-core | n/a (proptest) | VP-007.md |
| VP-008 | BC-2.22.001 | core::embeddings | proptest | 3 | P1 | draft | DI-014 | pregolya-core | n/a (proptest) | VP-008.md |
| VP-009 | BC-2.21.003 | vectorstores::similarity | Kani | 6 | P0 | draft | DI-014 | pregolya-vectorstores | `zero_norm_guard_fail_closed` | VP-009.md |
| VP-010 | BC-2.19.005 | core::serializable | Kani | 6 | P0 | draft | DI-014 | pregolya-core | `allowlist_rejects_unregistered_id` | VP-010.md |
| VP-011 | BC-2.05.007 | graph::hitl | Kani | 6 | P0 | draft | DI-014 | pregolya-graph | `deny_excludes_tool_invocation` | VP-011.md |
| VP-012 | BC-2.10.005 | core::budget | Kani | 6 | P1 | draft | DI-014 | pregolya-core | `watermark_arithmetic_harness` | VP-012.md |
| VP-013 | BC-2.23.005 | tools::shell | Kani | 6 | P1 | draft | DI-014 | pregolya-tools | `risk_floor_rejects_below_medium` | VP-013.md |
| VP-014 | BC-2.01.005 + BC-2.01.006 | core::runnable | proptest | 3 | P1 | draft | DI-016 | pregolya-core | n/a (proptest) | VP-014.md |
