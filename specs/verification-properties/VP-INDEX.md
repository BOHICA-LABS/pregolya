---
document_type: verification-property-index
level: L3
version: "1.27"
status: active
producer: architect
timestamp: 2026-08-27T00:00:00Z
phase: 1b
input-hash: "[live-index]"
traces_to: ARCH-INDEX.md
changelog:
  - "1.27 (round-18/F-P2A084-01+F-P2A084-02/D-288/2026-08-27): VP-016 body file bumped v1.9→v2.0 (exhaustive title/H1/frontmatter/table-cell/code-sketch sweep: frontmatter title and H1 'ToolOutput Contains Only extract_output-Selected Fields' → 'the Returned serde_json::Value Contains Only extract_output-Selected Fields' (F-P2A084-01); §Proof Method table Bounded? cell 'Unbounded over GraphState values' → 'Unbounded over serde_json::Value graph states'; Coverage cell 'For any generated S instance' → 'For any generated TestGraphState instance (as serde_json::Value)' (F-P2A084-02); TestGraphState struct doc, FALSE-GREEN GUARD prose, harness proptest macro doc, code-sketch inline comments and prop_assert! messages fully re-grounded on serde_json::Value). input-hash updated 2e9c2d7 → e57e95f. VP-INDEX catalog row UNCHANGED. VP census UNCHANGED: 17 total (6 P0 / 11 P1)."
  - "1.26 (round-14/semantic-reconciliation/F-P2A078..080/D-286/2026-08-27): VP-016 body file bumped v1.8→v1.9 (round-14 semantic re-read: F-P2A078-02 HIGH — §Property-Statement/§Corollary/§Proof-Method/§Feasibility 'GraphState S'/'ToolOutput returned by invoke_dyn' prose replaced with non-generic serde_json::Value; §BC-Traceability EC-TV-1 → TV-001 / EC-007 per F-P2A078-04 MED; verification-architecture.md harness struct fields re-grounded to output/checkpoint_id/run_id/accumulated_messages; dangling bare-form VP-016.md filename corrected to slug-form vp-016-graph-agent-tool-state-isolation.md per F-P2A078-03 MED). VP-INDEX catalog row UNCHANGED. VP census UNCHANGED: 17 total (6 P0 / 11 P1)."
  - "1.25 (round-12/GAP-01-straggler/D-285/2026-08-27): VP-016 body file bumped v1.7→v1.8 (round-12 straggler fixes: §Proof Obligations Stub Graph Obligation ROUTING FLAG→SATISFIED — S-1.14 AC-014 / Task 18 (round-10); §Realizability Trace Step 1 deserialization-framing removed — CompiledStateGraph::invoke takes serde_json::Value directly per BC-2.02.001 {PC-005}; Step 2 ConcreteGraphRunner(non-generic) + final_state[\"output\"] index form; §Feasibility async-concern row CompiledGraph::stub_terminal→CompiledStateGraph::stub_terminal; bare §AC-014 citations corrected to AC-014 in body). VP-INDEX catalog row unchanged. VP census UNCHANGED: 17 total (6 P0 / 11 P1)."
  - "1.24 (round-10/F-P2A072-01+F-P2A072-02+F-P2A072-03/D-284/2026-08-27): VP-016 body file bumped v1.5→v1.7 (round-10 type-grounding reconciliation: F-P2A072-02 eliminated ToolOutput::Structured phantom — invoke_dyn returns Result<serde_json::Value, PregolyaError> not ToolOutput; F-P2A072-01 eliminated as_value() phantom — resolved by F-P2A072-02 grounding; F-P2A072-03 eliminated CompiledGraph<S>/GraphState phantom — canon is non-generic CompiledStateGraph per BC-2.02.001 {PC-001}; §Realizability Trace updated; sibling-sweep §Feasibility Fn(&S)→Fn(&serde_json::Value) bound). VP-INDEX catalog row unchanged (BC-2.09.008 {INV-001} / proptest / P1 / draft unchanged). VP census UNCHANGED: 17 total (6 P0 / 11 P1)."
  - "1.23 (round-8/F-P2A069-01/D-283/2026-08-27): VP-016 body file bumped v1.4→v1.5 (F-P2A069-01 HIGH — prior harness was vacuous false-green: partial TestGraphState input → serde_json::from_value Err → prop_assert!() branches unreachable; architect rewrote holistically: input uses serde_json::to_value(&state) to guarantee round-trip success; hard prop_assert!(false) vacuous-Err guard added; §Realizability Trace section added). VP-INDEX catalog row unchanged (BC-2.09.008 {INV-001} / proptest / P1 / draft unchanged). VP census UNCHANGED: 17 total (6 P0 / 11 P1)."
  - "1.22 (round-7/F-P2A066-01/D-282/2026-08-26): VP-016 §Option-A-seam — Option-A realizable harness adopted (extract_output seam: isolation solely in GraphRunner::run; invoke_dyn passes state/output through without re-filtering; ADR-029 §Decision 3 canonical seam statement updated). CompiledGraph::stub_terminal seam added; POL-31 bypass recipe deleted; BC-2.09.008 {PC-004}/{INV-001} seam wording aligned. Census UNCHANGED: 17 total (6 P0 / 11 P1)."
  - "1.21 (round-6/P2A-063-065/D-281/2026-08-26): VP-016 body file bumped v1.2→v1.3 (F-064-02 HIGH triple-confirmed — harness relocated from non-compilable integration-test path to in-crate #[cfg(test)] mod tests inside pregolya-mcp/src/graph_tool.rs; three non-realizability defects fixed: from_runner seam, pub(crate) GraphRunner access E0603, Fn(&serde_json::Value)→Fn(&TestGraphState)->serde_json::Value; §Proof Obligations: §Test Seam Obligation added; O-063-02 OBS: invoke→invoke_dyn normalized in §Property Statement, formal property, §Source Contract, §Proof Method table, §Proof Obligations). VP-INDEX catalog row unchanged (BC-2.09.008 {INV-001} / proptest / P1 / draft unchanged). VP census unchanged: total 17."
  - "1.20 (P2A-060/061/062-round-5/2026-08-26): VP-016 body file bumped v1.1→v1.2 (F-P2A-061-01 HIGH harness fix: prior harness was tautological — rewritten to invoke production GraphAgentTool::invoke_dyn via MockGraphRunner + extract_output closure; Phase-6 POL-31 obligation recorded). VP-INDEX catalog row unchanged (BC-2.09.008 {INV-001} / proptest / P1 unchanged). VP census unchanged: total 17."
  - "1.19 (P2A-058-F058-04/2026-08-26): VP-006-B harness_fn confirmed as `injection_guard_multipair_fewshot_fail_closed` per F-058-04 convergence check (VP-INDEX §VP Catalog is source of truth; file was authored with canonical name; no rename required). VP-006-B bumped to v1.1. No catalog row delta. VP census unchanged: total 17."
  - "1.18 (B-SS18-SEC/SEC-003/ADR-029-v1.2/2026-08-26): VP-006-B added — injection_guard Multi-Pair FewShotExamples Fail-Closed; proptest P1; phase 3; module prompts::injection_guard; crate pregolya-prompts; bc_anchor BC-2.18.004 {PC-005}; di_anchor DI-014; status draft; harness_fn injection_guard_multipair_fewshot_fail_closed; file vp-006-b-injection-guard-multipair-fewshot.md. Belt-and-suspenders for VP-006 Kani {PC-005} arm — covers arbitrary Vec length and any-pair-index-untrusted patterns (TV-007 Red Gate: 4-pair middle-pair-only-untrusted). Arithmetic: total 16→17 (P0 6 unchanged, P1 10→11); proptest 4→5. Status:draft 16→17."
  - "1.17 (GAP-01-reconcile/2026-08-26): VP-016 BC Anchor clause tag corrected {INV-STATE-ISOLATION} → {INV-001} (stable-tag form per ADR-027; {INV-001} is the canonical STATE-ISOLATION invariant tag in BC-2.09.008). Arithmetic invariant note updated total(15)→total(16), P1(9)→P1(10), proptest(3)→proptest(4) to match Summary table. No VP catalog row additions."
  - "1.16 (GAP-01/ADR-029/2026-08-26): VP-016 added — GraphAgentTool state-isolation proptest P1 (BC-2.09.008 {INV-STATE-ISOLATION}, mcp::graph_tool, pregolya-mcp, DI-010, harness graph_agent_tool_state_isolation). Arithmetic: total 15→16 (P0 6→6 unchanged, P1 9→10); proptest 3→4. architecture-doc VP-015 tool-type discrepancy (D-273) also fixed in same burst: verification-architecture.md + verification-coverage-matrix.md corrected from 'integration' to 'unit' for VP-015 (VP-015.md authoritative; CLAUDE.md rule 4)."
  - "1.15 (BC-completeness-propagation/2026-08-26): VP-015 added — MCP Response Credential Redaction unit P1 (BC-2.09.007 {INV-003}, mcp::sanitize, pregolya-mcp, DI-010, harness credential_redaction_unit). VP-006 harness_fn updated: added `injection_guard_fewshot_fail_closed` (VP-006.md both-arm coverage of FewShotExamples arm). Arithmetic: total 14→15 (P0 6→6 unchanged, P1 8→9); unit 0→1 (new tool category); Kani/proptest/integration unchanged. NOTE: verification-architecture.md + verification-coverage-matrix.md list VP-015 tool as 'integration' — on-disk VP-015.md frontmatter is authoritative (tool: unit per CLAUDE.md rule 4 VP-file-supersedes); architecture docs carry a records-tier tool-type discrepancy (flagged D-273)."
  - "1.14 (INVESTIGATE-RECONCILE/2026-08-21): Fix VP-004 Module column: `mcp::adapter` → `mcp::exception`. Story S-2.10 creates no `adapter.rs`; VP-004 property (bare ToolException type-identity, R11) is implemented in `mcp::exception`. Arithmetic invariant UNCHANGED: total 14 (P0 6, P1 8) = Kani 9 + proptest 3 + integration 2. POL-9 cascade propagated same-burst to verification-architecture, verification-coverage-matrix, module-decomposition, purity-boundary-map, and VP-004.md."
  - "1.13 (burst-325/D-196/2026-08-18): input-hash: \"[live-index]\" sentinel added (metadata hygiene; Q2 alignment with BC-INDEX and ARCH-INDEX index convention; D-196 ruling: input-hash refresh is bookkeeping metadata, not normative spec content). VP-INDEX is an index document with no declared inputs field; sentinel marks it as live-index class per index convention. No VP catalog rows or arithmetic invariant changed."
  - "1.12 (burst-313/F-P204-01/2026-08-17): VP-014 (v1.2→v1.3) — §Source Contract ADR anchor corrected: split single ADR-026 §Decision 1 citation that mis-attributed JoinSet fan-out, completion-order collection, and re-insertion (§Decision 2 machinery) to §Decision 1 (type representation and key ordering only) into two single-§ citations per POL-19: §Decision 1 (type representation and key ordering) and §Decision 2 (concurrent execution and error handling). Mirrors burst-312 fix applied to sibling BC-2.01.005. Arithmetic invariant UNCHANGED: total 14 (P0 6, P1 8) = Kani 9 + proptest 3 + integration 2."
  - "1.11 (burst-311/OBS-P202-B/2026-08-17): VP-014 (v1.1→v1.2) — formal invariant aligned to canonical new() argument type Vec<(String, Arc<dyn DynRunnable>)> per BC-2.01.005 PC1 and ADR-026 §Decision 1 (OBS-P202-B). IndexMap is the internal container built by new(), not the argument type. Harness skeleton and Proof Obligations were already correct (Vec-of-pairs form); formal invariant now matches. Key-completeness property preserved. Arithmetic invariant UNCHANGED: total 14 (P0 6, P1 8) = Kani 9 + proptest 3 + integration 2."
  - "1.10 (burst-308/D26-EXEC-propagation/2026-08-17): VP-013 (v1.14→v1.15) — §BC Contradictions Flagged RESOLVED block: '12-category axis' → '13-category axis' per ADR-010 §Category Axis Expansion (D26). EXEC is the 13th category added by D26; the prior `Category::CONFIGURATION` label was non-canonical both before and after D26 expansion. Arithmetic invariant UNCHANGED: total 14 (P0 6, P1 8) = Kani 9 + proptest 3 + integration 2."
  - "1.9 (burst-303/D-172/2026-08-17): VP-014 (v1.0→v1.1) — harness-text alignment: DynRunnable method-surface corrected from invoke_dyn/stream_dyn to invoke/stream + config Option<RunnableConfig> per ADR-026 §Decision 1 (F-P194-01). Arithmetic invariant UNCHANGED: total 14 (P0 6, P1 8) = Kani 9 + proptest 3 + integration 2."
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
> Arithmetic invariant: total (17) = P0 (6) + P1 (11) = Kani (9) + proptest (5) + integration (2) + unit (1).
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
| Total VPs | 17 |
| Priority P0 (verification-priority) | 6 |
| Priority P1 (verification-priority) | 11 |
| Kani | 9 |
| proptest | 5 |
| fuzz | 0 |
| integration | 2 |
| unit | 1 |
| Status: draft | 17 |
| Status: active | 0 |
| Status: passed | 0 |

## VP Catalog

| VP | BC Anchor | Module | Tool | Phase | Priority | Status | DI | Crate | harness_fn | File |
|----|-----------|--------|------|-------|----------|--------|----|-------|------------|------|
| VP-001 | BC-2.03.001 | graph::bsp_engine | Kani | 6 | P0 | draft | DI-001 | pregolya-graph | `bsp_determinism_harness` | VP-001.md |
| VP-002 | BC-2.04.006 | checkpoint::session_index | Kani | 6 | P0 | draft | DI-005 | pregolya-checkpoint | `session_tenancy_harness` | VP-002.md |
| VP-003 | BC-2.13.004 | sandbox::path_guard | Kani | 6 | P0 | draft | DI-007 | pregolya-sandbox | `workspace_confinement_harness` | VP-003.md |
| VP-004 | BC-2.09.004 | mcp::exception | integration | 3 | P1 | draft | DI-014 | pregolya-mcp | n/a (integration test) | VP-004.md |
| VP-005 | BC-2.09.005 | mcp::client | integration | 3 | P1 | draft | DI-014 | pregolya-mcp | n/a (integration test) | VP-005.md |
| VP-006 | BC-2.18.004 | prompts::injection_guard | Kani | 6 | P1 | draft | DI-014 | pregolya-prompts | `injection_guard_fail_closed`, `injection_guard_fewshot_fail_closed` | VP-006.md |
| VP-006-B | BC-2.18.004 {PC-005} | prompts::injection_guard | proptest | 3 | P1 | draft | DI-014 | pregolya-prompts | `injection_guard_multipair_fewshot_fail_closed` | vp-006-b-injection-guard-multipair-fewshot.md |
| VP-007 | BC-2.19.001 | core::serializable | proptest | 3 | P1 | draft | DI-008 | pregolya-core | n/a (proptest) | VP-007.md |
| VP-008 | BC-2.22.001 | core::embeddings | proptest | 3 | P1 | draft | DI-014 | pregolya-core | n/a (proptest) | VP-008.md |
| VP-009 | BC-2.21.003 | vectorstores::similarity | Kani | 6 | P0 | draft | DI-014 | pregolya-vectorstores | `zero_norm_guard_fail_closed` | VP-009.md |
| VP-010 | BC-2.19.005 | core::serializable | Kani | 6 | P0 | draft | DI-014 | pregolya-core | `allowlist_rejects_unregistered_id` | VP-010.md |
| VP-011 | BC-2.05.007 | graph::hitl | Kani | 6 | P0 | draft | DI-014 | pregolya-graph | `deny_excludes_tool_invocation` | VP-011.md |
| VP-012 | BC-2.10.005 | core::budget | Kani | 6 | P1 | draft | DI-014 | pregolya-core | `watermark_arithmetic_harness` | VP-012.md |
| VP-013 | BC-2.23.005 | tools::shell | Kani | 6 | P1 | draft | DI-014 | pregolya-tools | `risk_floor_rejects_below_medium` | VP-013.md |
| VP-014 | BC-2.01.005 + BC-2.01.006 | core::runnable | proptest | 3 | P1 | draft | DI-016 | pregolya-core | n/a (proptest) | VP-014.md |
| VP-015 | BC-2.09.007 {INV-003} | mcp::sanitize | unit | 3 | P1 | draft | DI-010 | pregolya-mcp | `credential_redaction_unit` | VP-015.md |
| VP-016 | BC-2.09.008 {INV-001} | mcp::graph_tool | proptest | 3 | P1 | draft | DI-010 | pregolya-mcp | `graph_agent_tool_state_isolation` | vp-016-graph-agent-tool-state-isolation.md |
