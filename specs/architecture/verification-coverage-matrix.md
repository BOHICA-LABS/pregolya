---
document_type: architecture-section
level: L3
section: verification-coverage-matrix
version: "3.6"
status: active
producer: architect
timestamp: 2026-08-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/module-criticality.md
input-hash: "861f2a9"
traces_to: ARCH-INDEX.md
changelog:
  - "3.6 (burst-302b/D-170/2026-08-17): Add VP-014 (proptest P1, core::runnable::parallel, pregolya-core, BC-2.01.005 + BC-2.01.006, DI-016). LCEL composition scope expansion (D-170). VP-to-Module table: add VP-014 row; Totals 13→14 VPs, proptest 2→3. Per-Module Coverage Status: add core::runnable::parallel row (HIGH tier, pregolya-core, proptest VP-014, D-170/SS-01; RunnableParallel key-completeness). Coverage by Criticality Tier HIGH proptest: 7 of 29 → 8 of 30 (new module added to HIGH tier; HIGH count 29→30 since core::runnable::parallel is a new HIGH-tier module; proptest count +1). Arithmetic invariant: total 13→14, P1 7→8, proptest 2→3. Preamble updated."
  - "3.5 (burst-288/F-P177-A04/2026-08-15): Fix stale coverage gap note: 'Actual proptest coverage is 3 of 12 CRITICAL and 7 of 28 HIGH' → '7 of 29 HIGH'. The HIGH tier count was bumped from 28 to 29 in §Coverage by Criticality Tier (core::tool added) and the tier table was correctly updated to 29, but the coverage gap prose note was not updated in the same burst. Tier table row HIGH '7 of 29' was already correct; only the prose note was stale."
  - "3.4 (FIX-BURST-278-WAVE-A/F-P175-D212/2026-07-28): Iron Law — add `core::tool` HIGH row (pregolya-core SS-08; Tool/DynTool trait seam; Arc<dyn DynTool> composition; BC-2.08.010; no Kani VP; Integration=yes). Required by module-decomposition.md §core::tool row addition. Coverage-by-Criticality-Tier: HIGH 28→29. Preamble updated 83→84, tiered 77→78. Coverage gap note updated 28→29 HIGH modules."
  - "3.3 (FIX-BURST-277-WAVE-B/2026-07-28): Item 6 module census — add 6 definitions-only/exempt rows to Per-Module Coverage Status table: core::documents (definitions-only, D21/SS-20, ADR-014 Decision 2), memory::skills (routing-overlay/exempt, D20/SS-15, ADR-012 Decision 4), core::guardrail (definitions-only, SS-11, ADR-014 Decision 6), core::action_risk (definitions-only, SS-05, F-P170-06/ADR-020), core::context_mutation (definitions-only, D20/SS-01, ADR-012), core::write_guard (definitions-only, D20/SS-15, ADR-012). All have Tier=— (no kill rate obligation), no VP targets, no Kani/proptest/fuzz. Preamble updated 77→83. Tiered count (CRITICAL 12 / HIGH 28 / MEDIUM 35 / LOW 2 = 77) unchanged — definitions-only/exempt rows are outside the tiered universe."
  - "3.2 (FIX-BURST-276-CHECK4/2026-07-27): CHECK4 canonicality closure — rename three crate-level BaseChatModel provider rows to full canonical crate names: `openai` → `pregolya-openai`, `anthropic` → `pregolya-anthropic`, `ollama` → `pregolya-ollama`. Aligns with established pattern: pregolya-macros and pregolya-standard-tests already use full crate names in this file; purity-boundary-map.md already uses these names generating the same expected SET-DIFF in-here-not-decomp WARNs (crate-level rows are not in module-decomp canonical set because the Provider Crates section is excluded from decomp scanning). Row Notes updated to remove stale 'no canonical crate::module name' wording; full crate names ARE canonical via ARCH-INDEX.md roster. No VP or coverage count changes; census sextuple unchanged."
  - "3.1 (FIX-BURST-276/F-P173-803/2026-07-27): F-P173-803 — correct Coverage by Criticality Tier proptest column. Actual proptest coverage is 3 of 12 CRITICAL (graph::bsp_engine, checkpoint::session_index, checkpoint::clock — derivation: counted proptest=yes/VP-NNN rows from per-module table, CRITICAL tier) and 7 of 28 HIGH (core::runnable, core::message, core::serializable/VP-007, core::embeddings/VP-008, graph::definition, graph::channels, graph::budget). Replace 'all' → '3 of 12 (explicit list)' and 'most + VP-007, VP-008' → '7 of 28 (explicit list)'. Add coverage-gap stated-obligation note. Update tooling-selection.md proptest gate from aspirational to actual (v1.4). No VP-to-Module count changes."
  - "3.0 (FIX-BURST-276/F-P173-307-801/2026-07-27): F-P173-307/801 — canonicalize all non-canonical Module cells. VP-to-Module table: 13 cells updated (bsp-engine (reducer stage)→graph::bsp_engine, session-index→checkpoint::session_index, path-guard→sandbox::path_guard, mcp-adapter→mcp::adapter, mcp-client→mcp::client, injection_guard→prompts::injection_guard, serializable→core::serializable, embeddings→core::embeddings, vectorstores-similarity→vectorstores::similarity, serializable-reviver→core::serializable, hitl→graph::hitl, core-budget→core::budget, tools-shell→tools::shell). Per-Module table: 36 cells updated (full list: bsp-engine→graph::bsp_engine, channels→graph::channels, hitl→graph::hitl, scheduler→graph::scheduler, budget→graph::budget, provenance→graph::provenance, event_emitter→graph::event_emitter, session-index→checkpoint::session_index, clock→checkpoint::clock, lineage→checkpoint::lineage, encryption→checkpoint::encryption, sqlite→checkpoint::sqlite, path-guard→sandbox::path_guard, sandbox-policy→sandbox::policy, message→core::message, error→core::error, credentials→core::credentials, runnable→core::runnable, retry→core::retry, server handlers→server::handlers, server security→server::security, recursive splitter→splitters::recursive, mcp client→mcp::client, mcp adapter→mcp::adapter, mcp server→mcp::server, sandbox-wasm→sandbox::wasm, memory-store→memory::store, write-guard enforcement→memory::write_guard, injection_guard→prompts::injection_guard, serializable→core::serializable, serializable-reviver→core::serializable, vectorstores-similarity→vectorstores::similarity, vectorstores-mmr→vectorstores::mmr, embeddings→core::embeddings, core-budget→core::budget, tools-shell→tools::shell). Total cells changed: 49 (13 VP table + 36 per-module table). No-canonical-counterpart entries (reported, not renamed): openai, anthropic, ollama (crate-level conformance; no explicit module name in module-decomp), pregolya-macros roll-up (superseded by macros::tool/entrypoint/task rows), pregolya-standard-tests roll-up (superseded by eval::judge row). Notes added to those 5 entries clarifying their status. Canonical source: module-decomposition.md module universe 71 total (69 tiered / 2 exempt: core::documents, memory::skills)."
  - "2.9 (FIX-BURST-276-WAVE-B1/F-P173-301+402/2026-07-27): F-P173-301/402 sibling sweep — fix eval::judge row Notes BC anchor: `BC-2.08.013/014` → `BC-2.08.008`. Correct anchor: BC-2.08.008 = Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome (NE-15); BC-2.08.013 = Pluggable Tool-Call Dialect Seam; BC-2.08.014 = Provider Failover Chain — both are provider-behavior BCs, not eval-scoring BCs. TD-VSDD-060 sibling sweep: same BC anchor corrected in module-decomposition.md (v1.34), module-criticality.md (v2.3), purity-boundary-map.md (v1.23) in same burst. No VP-to-Module table changes; no coverage count changes."
  - "2.8 (FIX-BURST-275-REOPENED/Defect-2-mirror/2026-07-26): Mirror module-criticality.md §Per-Module additions — add 3 Per-Module Coverage Status rows: `macros::tool` HIGH (pregolya-macros; compile-time TokenStream→TokenStream proc-macro; no Kani VP; BC-2.08.010), `macros::entrypoint` HIGH (pregolya-macros; compile-time proc-macro; no Kani VP; BC-2.08.011), `macros::task` HIGH (pregolya-macros; compile-time proc-macro; no Kani VP; BC-2.08.012). Coverage-by-Criticality-Tier: HIGH 25 → 28. Per-module count 74 → 77. VP-to-Module table and VP totals unchanged (no new VPs; macros proc-macro modules have no Kani VP targets — compile-time code generation is integration-tested via expansion correctness tests)."
  - "2.7 (FIX-BURST-275/F-P172b-01+15+Iron-Law/2026-07-26): Mirror module-criticality.md §Per-Module additions. F-P172b-01 mirror — add 7 Per-Module Coverage Status rows: `openai::embeddings` HIGH (pregolya-openai, DI-009/DI-010, Integration DTU), `ollama::embeddings` HIGH (pregolya-ollama, DI-009, Integration), `vectorstores::store` MEDIUM (pregolya-vectorstores, Integration), `vectorstores::retriever` MEDIUM (pregolya-vectorstores, Integration), `vectorstores::memory` MEDIUM (pregolya-vectorstores, Unit+Integration), `tools::fs` MEDIUM (pregolya-tools, Integration), `tools::search` MEDIUM (pregolya-tools, Integration). F-P172b-15 mirror — update mcp::ingress Notes to reflect HIGH tier elevation (untrusted-ingress; BC-2.09.003; parity with graph::provenance HIGH). Iron Law mirror — add `eval::judge` MEDIUM row (pregolya-standard-tests; async LLM judge; Integration DTU; BC-2.08.013/014). Coverage-by-Criticality-Tier: HIGH 22 → 25 (+openai::embeddings, +ollama::embeddings, mcp::ingress elevation); MEDIUM 30 → 35 (+vectorstores::store/retriever/memory, +tools::fs/search, +eval::judge, -mcp::ingress). Per-module count 66 → 74. VP-to-Module table and VP totals unchanged (no new VPs)."
  - "2.6 (FIX-BURST-274/module-universe-sweep/2026-07-26): Module-universe sweep mirror — add 18 Per-Module Coverage Status rows matching module-criticality.md v2.0 additions. CRITICAL +1: checkpoint::saver. HIGH +4: core::events, graph::definition, server::streaming, server::stores. MEDIUM +13: core::config, checkpoint::memory, checkpoint::postgres, server::cron, sandbox::container, sandbox::seatbelt, sandbox::process, splitters::parity, mcp::discovery, mcp::ingress, memory::sqlite, memory::in_memory, memory::search. Coverage-by-Criticality-Tier: CRITICAL 11→12, HIGH 18→22, MEDIUM 17→30. Per-module count 48→66. VP-to-Module table and VP totals unchanged (no new VPs)."
  - "2.5 (FIX-BURST-274/D21-definitions-sweep/2026-07-26): D21 Pure Core sweep — add 4 missing MEDIUM rows to match module-criticality.md v1.9 additions (core::retriever, prompts::template, prompts::chat_template, prompts::few_shot). Per-module count 44→48; Coverage-by-Criticality-Tier MEDIUM 13→17. Per-Module Coverage Status header updated."
  - "2.4 (FIX-BURST-273/gate-25-32/2026-07-25): Add tools::config MEDIUM row (pregolya-tools SS-23) — gate #25 Part B/C sibling propagation; no Kani VP (VP-013 Kani P1 targets check_risk_floor in tools::shell); Integration: yes (construction-time validation tests for override_risk / ADR-020 Decision 3 / BC-2.23.005). Per-module count 43→44; Coverage-by-Criticality-Tier MEDIUM 12→13. Header note updated."
  - "2.3 (FIX-BURST-252/2026-07-24): Input-hash cascade refresh — module-decomposition.md v1.22→v1.23 (FIX-BURST-252 F-P151-02+05: fraction f32→f64 in core::budget, CompactionSummary flat fields). No VP-to-Module table or coverage-status changes (core-budget VP-012 mapping, tool, phase, priority, and Notes wording all unchanged — Notes 'OnWatermark arithmetic; Kani P1 (BC-2.10.005)' contains no predicate formula or type annotation requiring update)."
  - "2.2 (FIX-BURST-250/F-P149-03/2026-07-24): Add missing red_gate label to three Per-Module rows where VP is red_gate:true (VP-004/005/006) for parity with VP-009/VP-010 rows. injection_guard Notes: 'Kani P1 (BC-2.18.004)' → 'Kani P1 red_gate (BC-2.18.004)'. mcp-adapter Notes: 'ToolException fidelity' → 'ToolException type-identity; integration red_gate (BC-2.09.004)'. mcp-client Notes: 'Red Gate BCs' → 'integration red_gate (BC-2.09.005); no-live-connections'. Verified: VP-009 'Kani P0 red_gate (BC-2.21.003)' and VP-010 'Kani P0 red_gate (BC-2.19.005)' already correct. All 8 red_gate:false VP rows confirmed clean (no red_gate label)."
  - "2.1 (FIX-BURST-248/F-P147-01/2026-07-24): Remove stale 'red_gate' label from hitl row Notes — BC-2.05.007 is NOT Red-Gated (product-owner authority, burst-231; ADR-018 Decision 3 has no compile-and-fail mandate). Notes changed from 'Kani P0 red_gate (BC-2.05.007)' to 'Kani P0 (BC-2.05.007)'. No VP table, totals, or criticality tier changes."
  - "2.0 (burst-232/2026-07-22): D23 VP layer — add VP-011..013 to VP-to-Module table; update hitl row (VP-011 Kani P0); add core-budget row (VP-012 Kani P1); add tools-shell row (VP-013 Kani P1). Totals: 10→13 VPs, Kani 6→9. Coverage-by-Criticality-Tier: CRITICAL Kani VPs 5→6 (+VP-011; hitl is CRITICAL per module-criticality.md); HIGH Kani VPs 1→3 (+VP-012 core-budget, +VP-013 tools-shell; pregolya-tools criticality tier deferred to module-criticality.md D23 content authoring burst). Per-module count 41→43 (+2 new rows). Input-hash refresh pending VP-INDEX.md v1.5."
  - "1.9 (burst-229/2026-07-22): Input-hash cascade refresh — module-decomposition.md v1.15 changed (D23: SS-23 pregolya-tools + graph::hitl/budget D23 types) + module-criticality.md v1.5 cascade (ARCH-INDEX.md v1.6 + module-decomposition.md v1.15). Hash: 52d04b1 → 06eaf17. No VP table changes (D23 VP candidates not yet minted; pending PO BC authoring)."
  - "1.8 (burst-224/2026-07-21): Fix Coverage by Criticality Tier MEDIUM count: 11 → 12 (vectorstores-mmr reclassified CRITICAL → MEDIUM when VP-009 moved to vectorstores-similarity; F-P129-11 reclassification, not an addition). Fix tier membership description in header note. Refresh input-hash cascade: 8bc637f → 78d9c11 (module-decomposition.md v1.12) → c766473 final (module-criticality.md v1.4 D21+burst-224 backfill in same burst)."
  - "1.7 (burst-224/2026-07-21): F-P129-11 — VP-009 module renamed vectorstores-mmr → vectorstores-similarity in VP-to-Module table; Per-Module Coverage Status split into vectorstores-similarity (VP-009 Kani P0) + vectorstores-mmr (no Kani VP, caller of similarity). Totals unchanged (10 VPs, Kani 6). Propagates VP-INDEX v1.3 + module-decomposition v1.12."
  - "1.6 (burst-223/2026-07-21): D21 VP layer — add VP-006..010 to VP-to-Module table; add SS-18..22 module rows to Per-Module Coverage Status; update Totals 5→10 VPs, Kani 3→6, proptest 0→2; update Coverage by Criticality Tier to reflect new D21 modules."
  - "1.5 (provenance-fix-169/2026-07-17): cascade input-hash recompute (VP-INDEX.md v1.1 content change — column reorder for hook compatibility)."
  - "1.4 (provenance-fix-169/2026-07-17): cascade input-hash recompute (module-decomposition.md v1.8 content change); add [Section Content] template compliance fix."
  - "1.3 (gate #25 backfill + D20/CAP-021): F-backfill add write-guard enforcement HIGH row missing since ADR-012 D20 burst (matrix header was 33, module-criticality was 34 — drift corrected); add mcp-server MEDIUM row (CAP-021); header 33→35 (CRITICAL 9 / HIGH 13 / MEDIUM 11 / LOW 2); Coverage-by-Tier HIGH 12→13, MEDIUM 10→11."
  - "1.2 (ADV-P1D-PASS-45): F-P45-01 correct retry crate from pregolya-graph to pregolya-core per module-criticality.md line 64 (SS-16); relocate row from pregolya-graph cluster into pregolya-core cluster. Full 33-row crate-ownership diff against module-criticality.md — no other mismatches found."
  - "1.1 (ADV-P1D-PASS-37): F-P37-02 correct Coverage by Criticality Tier summary to CRITICAL 9 / HIGH 12 / MEDIUM 10 / LOW 2 = 33 (was stale 6/7/5/2=20); complete Per-Module Coverage Status table to all 33 architecture modules (was 27); added rows for pregolya-macros (HIGH), sandbox-wasm (MEDIUM), pregolya-standard-tests (MEDIUM), memory-store (MEDIUM), xtask (LOW), pregolya-community (LOW)."
  - "1.0 (initial): base verification coverage matrix authored."
---

# Verification Coverage Matrix: pregolya

## [Section Content]

> **VP-INDEX.md is the authoritative VP catalog.** This matrix derives from it.
> Arithmetic invariant: VP total (14) = P0 (6) + P1 (8) = Kani (9) + proptest (3) + integration (2). Status is updated per gate.

## VP-to-Module Mapping

| VP | Title | Module | Crate | Tool | BC Anchor | Phase | Status |
|----|-------|--------|-------|------|-----------|-------|--------|
| VP-001 | BSP Super-Step Determinism | graph::bsp_engine | pregolya-graph | Kani | BC-2.03.001 | 6 | draft |
| VP-002 | Session Triple-Address Uniqueness | checkpoint::session_index | pregolya-checkpoint | Kani | BC-2.04.006 | 6 | draft |
| VP-003 | Workspace Path Confinement | sandbox::path_guard | pregolya-sandbox | Kani | BC-2.13.004 | 6 | draft |
| VP-004 | MCP ToolException Type-Identity Preservation | mcp::adapter | pregolya-mcp | integration | BC-2.09.004 | 3 | draft |
| VP-005 | MultiServerMcpClient Holds No Live Connections | mcp::client | pregolya-mcp | integration | BC-2.09.005 | 3 | draft |
| VP-006 | injection_guard Fail-Closed | prompts::injection_guard | pregolya-prompts | Kani | BC-2.18.004 | 6 | draft |
| VP-007 | LcSerializable Round-Trip | core::serializable | pregolya-core | proptest | BC-2.19.001 | 3 | draft |
| VP-008 | Embeddings Dimensionality Contract | core::embeddings | pregolya-core | proptest | BC-2.22.001 | 3 | draft |
| VP-009 | Zero-Norm Cosine Guard | vectorstores::similarity | pregolya-vectorstores | Kani | BC-2.21.003 | 6 | draft |
| VP-010 | Reviver Allowlist Containment | core::serializable | pregolya-core | Kani | BC-2.19.005 | 6 | draft |
| VP-011 | PreToolCallHook Fail-Closed | graph::hitl | pregolya-graph | Kani | BC-2.05.007 | 6 | draft |
| VP-012 | OnWatermark Arithmetic | core::budget | pregolya-core | Kani | BC-2.10.005 | 6 | draft |
| VP-013 | BashTool Risk Floor | tools::shell | pregolya-tools | Kani | BC-2.23.005 | 6 | draft |
| VP-014 | RunnableParallel Key-Completeness | core::runnable | pregolya-core | proptest | BC-2.01.005 + BC-2.01.006 | 3 | draft |

**Totals: 14 VPs | Kani: 9 | proptest: 3 | fuzz: 0 | integration: 2**

## Per-Module Coverage Status

> This table covers 85 architecture entries (84 from prior bursts + burst-302b core::runnable::parallel addition: D-170/SS-01 RunnableParallel sub-module, HIGH tier).
> Tiered groupings: CRITICAL 12 / HIGH 30 / MEDIUM 35 / LOW 2 = 79 tiered. Definitions-only/exempt: 6 (Tier=—; no kill rate obligation).

| Module | Crate | Kani | proptest | fuzz | Integration | Notes |
|--------|-------|------|---------|------|-------------|-------|
| graph::bsp_engine | pregolya-graph | VP-001 | yes (BC-2.03.003) | yes (BC-2.17.002) | yes | Core VP target |
| graph::channels | pregolya-graph | — | yes (BC-2.02.002) | — | yes | Reducer invariants via proptest |
| graph::hitl | pregolya-graph | VP-011 | — | — | yes | D23/SS-05; PreToolCallHook fail-closed; Kani P0 (BC-2.05.007) |
| graph::scheduler | pregolya-graph | — | — | — | yes | Pending ADR-001 |
| graph::budget | pregolya-graph | — | yes | — | yes | EvidenceJournal ordering |
| graph::provenance | pregolya-graph | — | — | — | yes | Hook dispatch |
| graph::event_emitter | pregolya-graph | — | — | — | yes | Streaming/unary equivalence |
| checkpoint::session_index | pregolya-checkpoint | VP-002 | yes | — | yes | Core VP target |
| checkpoint::clock | pregolya-checkpoint | — | yes | — | yes | Monotonic property |
| checkpoint::lineage | pregolya-checkpoint | — | — | — | yes | Fork pointer |
| checkpoint::encryption | pregolya-checkpoint | — | — | — | yes | Payload coverage |
| checkpoint::sqlite | pregolya-checkpoint | — | — | yes (BC-2.17.002) | yes | Round-trip fuzz |
| sandbox::path_guard | pregolya-sandbox | VP-003 | — | — | yes | Core VP target |
| sandbox::policy | pregolya-sandbox | — | — | — | yes | Err(PolicyNotEnforceable) |
| core::message | pregolya-core | — | yes | — | yes | ContentBlock invariants |
| core::error | pregolya-core | — | — | — | yes | RFC-7807 emission |
| core::credentials | pregolya-core | — | — | — | yes | Redacted Debug |
| core::runnable | pregolya-core | — | yes | — | yes | Pipe associativity |
| core::runnable | pregolya-core | — | VP-014/yes | — | yes | Pipe associativity + RunnableParallel key-completeness; VP-014 proptest P1 (BC-2.01.005/BC-2.01.006; D-170/SS-01). See note: burst-302b VP-014 absorbed into core::runnable (3-level path core::runnable::parallel non-canonical). |
| core::retry | pregolya-core | — | yes | — | yes | Policy termination |
| server::handlers | pregolya-server | — | — | — | yes | CRUD lifecycle |
| server::security | pregolya-server | — | — | — | yes | SecurityConfig defaults |
| splitters::recursive | pregolya-splitters | — | yes | — | yes | Code-point boundaries |
| pregolya-openai | pregolya-openai | — | — | — | yes | Conformance suite (crate-level BaseChatModel impl; canonical crate name per ARCH-INDEX.md roster; Provider Crates section excluded from module-decomp canonical set) |
| pregolya-anthropic | pregolya-anthropic | — | — | — | yes | Conformance suite (crate-level BaseChatModel impl; canonical crate name per ARCH-INDEX.md roster; Provider Crates section excluded from module-decomp canonical set) |
| pregolya-ollama | pregolya-ollama | — | — | — | yes | Conformance suite (crate-level BaseChatModel impl; canonical crate name per ARCH-INDEX.md roster; Provider Crates section excluded from module-decomp canonical set) |
| mcp::client | pregolya-mcp | — | — | — | yes | integration red_gate (BC-2.09.005); no-live-connections |
| mcp::adapter | pregolya-mcp | — | — | — | yes | ToolException type-identity; integration red_gate (BC-2.09.004) |
| mcp::server | pregolya-mcp | — | — | — | yes | Server-side tool exposure + inbound dispatch (CAP-021) |
| pregolya-macros | pregolya-macros | — | — | — | yes | crate-level roll-up; `#[tool]`/`#[entrypoint]`/`#[task]` expansion correctness (no canonical crate::module name for this roll-up — macros::tool/entrypoint/task are the canonical rows) |
| macros::tool | pregolya-macros | — | — | — | yes | HIGH; `#[tool]` proc-macro ToolDefinition generation; compile-time TokenStream expansion; integration-tested via expansion correctness; BC-2.08.010 |
| macros::entrypoint | pregolya-macros | — | — | — | yes | HIGH; `#[entrypoint]` proc-macro START-edge wiring; compile-time TokenStream expansion; integration-tested; BC-2.08.011 |
| macros::task | pregolya-macros | — | — | — | yes | HIGH; `#[task]` proc-macro task-registration boilerplate; compile-time TokenStream expansion; integration-tested; BC-2.08.012 |
| sandbox::wasm | pregolya-sandbox | — | — | — | yes | WASM execution backend |
| pregolya-standard-tests | pregolya-standard-tests | — | — | — | yes | Shared conformance harness; exercised via provider integrations (no canonical crate::module name for this roll-up — eval::judge is the canonical module row) |
| memory::store | pregolya-memory | — | yes | — | yes | KV + vector ops; GDPR erasure protocol |
| memory::write_guard | pregolya-memory | — | — | — | yes | `WriteGuardDecision` enforcement; injection scanning dispatch (D20/ADR-012) |
| xtask | xtask | — | — | — | — | CI lint gates only; advisory ≥70% |
| pregolya-community | pregolya-community | — | — | — | — | Post-v1 placeholder; not in-tree at v1 |
| prompts::injection_guard | pregolya-prompts | VP-006 | — | — | yes | D21/SS-18; prompt injection safety; Kani P1 red_gate (BC-2.18.004) |
| core::serializable | pregolya-core | — | VP-007 | — | yes | D21/SS-19; LcSerializable round-trip aspect; proptest P1 (BC-2.19.001) |
| core::serializable | pregolya-core | VP-010 | — | — | yes | D21/SS-19; Reviver allowlist containment aspect; Kani P0 red_gate (BC-2.19.005) |
| vectorstores::similarity | pregolya-vectorstores | VP-009 | — | — | yes | D21/SS-21; shared cosine_similarity primitive; zero-norm guard; Kani P0 red_gate (BC-2.21.003) |
| vectorstores::mmr | pregolya-vectorstores | — | — | — | yes | D21/SS-21; MMR selection algorithm; calls vectorstores::similarity::cosine_similarity |
| core::embeddings | pregolya-core | — | VP-008 | — | yes | D21/SS-22; dimensionality contract; proptest P1 (BC-2.22.001) |
| core::budget | pregolya-core | VP-012 | — | — | yes | D23/SS-10; OnWatermark arithmetic; Kani P1 (BC-2.10.005) |
| core::tool | pregolya-core | — | — | — | yes | SS-08; Tool/DynTool trait seam; Arc<dyn DynTool> composition; BC-2.08.010; ToolOutput::Error→Err(PregolyaError) per DI-014 |
| tools::shell | pregolya-tools | VP-013 | — | — | yes | D23/SS-23; BashTool risk floor; Kani P1 (BC-2.23.005) |
| tools::config | pregolya-tools | — | — | — | yes | D23/SS-23; ToolConfig risk-floor validator; pure construction-time validation (ADR-020 Decision 3 / BC-2.23.005) |
| core::retriever | pregolya-core | — | — | — | yes | D21/SS-20; `rag_ingress` async guardrail routing gate; DI-012 RAGRetrieval boundary enforcement (ADR-014 Decision 6) |
| prompts::template | pregolya-prompts | — | — | — | yes | D21/SS-18; f-string rendering engine; variable extraction and substitution (ADR-015) |
| prompts::chat_template | pregolya-prompts | — | — | — | yes | D21/SS-18; multi-message template construction with MessageProvenance (ADR-015) |
| prompts::few_shot | pregolya-prompts | — | — | — | yes | D21/SS-18; FewShotPromptTemplate assembly; snapshot-frozen golden fixture tests (ADR-015) |
| checkpoint::saver | pregolya-checkpoint | — | — | — | yes | CheckpointSaver `put_writes` durability contract; integration-tested via backend implementations (sqlite/postgres/memory) |
| core::events | pregolya-core | — | — | — | yes | StreamEvent taxonomy; BC-2.06.001; event construction tested in graph scheduler integration suite |
| graph::definition | pregolya-graph | — | yes | — | yes | StateGraph builder; node/edge registration; property tests for topology invariants |
| server::streaming | pregolya-server | — | — | — | yes | SSE streaming endpoint; same engine as unary (NE-13); integration + soak |
| server::stores | pregolya-server | — | — | — | yes | IdempotencyStore/RateLimitStore/RunStore trait seams (NE-08); integration via server handler tests |
| core::config | pregolya-core | — | — | — | yes | RunnableConfig/ChatConfig construction; env var reads; unit tests |
| checkpoint::memory | pregolya-checkpoint | — | — | — | yes | In-memory checkpoint backend; deterministic HashMap; unit tests |
| checkpoint::postgres | pregolya-checkpoint | — | — | — | yes | PostgreSQL checkpoint backend; integration tests (stretch feature) |
| server::cron | pregolya-server | — | — | — | yes | CronSchedule parsing and proactive run triggering; integration tests |
| sandbox::container | pregolya-sandbox | — | — | — | yes | Container execution backend (sandbox-container feature); integration tests |
| sandbox::seatbelt | pregolya-sandbox | — | — | — | yes | macOS Seatbelt deny-by-default profile (NE-16); integration tests |
| sandbox::process | pregolya-sandbox | — | — | — | yes | ProcessBackend OS subprocess execution; integration tests (BC-2.13.002) |
| splitters::parity | pregolya-splitters | — | — | — | yes | Golden-vector parity tests vs Python reference (R8/BC-2.07.002); unit tests |
| mcp::discovery | pregolya-mcp | — | — | — | yes | Tool discovery from MCP server at runtime (BC-2.09.001); integration tests |
| mcp::ingress | pregolya-mcp | — | — | — | yes | HIGH tier (F-P172b-15 elevation); untrusted-ingress routing; DI-012 guardrail seam; external-input boundary (BC-2.09.003); parity with graph::provenance HIGH; unit + integration tests |
| memory::sqlite | pregolya-memory | — | — | — | yes | SQLite durable backend for long-horizon memory; integration tests |
| memory::in_memory | pregolya-memory | — | — | — | yes | Ephemeral in-memory backend for test/dev; unit tests |
| memory::search | pregolya-memory | — | — | — | yes | Keyword, vector, and hybrid search; integration tests |
| openai::embeddings | pregolya-openai | — | — | — | yes | HIGH tier; credential-bearing HTTP surface (DI-009/DI-010); EmbeddingsOpenAI impl; integration (DTU) |
| ollama::embeddings | pregolya-ollama | — | — | — | yes | HIGH tier; Embeddings conformance contract; EmbeddingsOllama impl; integration |
| vectorstores::store | pregolya-vectorstores | — | — | — | yes | VectorStore trait dispatch; VectorStoreFactory; integration |
| vectorstores::retriever | pregolya-vectorstores | — | — | — | yes | VectorStoreRetriever bridge; Retriever impl; integration |
| vectorstores::memory | pregolya-vectorstores | — | yes | — | yes | In-memory VectorStore backend; RwLock interior mutability; unit + integration |
| tools::fs | pregolya-tools | — | — | — | yes | OS filesystem I/O tools; path-guard consumer; integration |
| tools::search | pregolya-tools | — | — | — | yes | In-process regex search; directory traversal; path-guard consumer; integration |
| eval::judge | pregolya-standard-tests | — | — | — | yes | LLM judge execution; emits eval.judge_infra_error event (observability.md); BC-2.08.008; integration (DTU) |
| core::documents | pregolya-core | — | — | — | — | Definitions-only; Tier=— (ADR-009/ADR-014 Decision 2): pure data carrier, no execution methods, no VP target; D21/SS-20 |
| memory::skills | pregolya-memory | — | — | — | — | Routing-overlay/exempt; Tier=— (ADR-012 Decision 4): structural decomposition row only; execution in memory::store/memory::search; D20/SS-15 |
| core::guardrail | pregolya-core | — | — | — | — | Definitions-only; Tier=— (ADR-009/ADR-014 Decision 6): GuardrailHook trait + supporting types, no execution logic; SS-11 |
| core::action_risk | pregolya-core | — | — | — | — | Definitions-only; Tier=— (ADR-009/ADR-020 Decision 3): ActionRisk enum definitions only; SS-05 |
| core::context_mutation | pregolya-core | — | — | — | — | Definitions-only; Tier=— (ADR-009/ADR-012 D20): ContextSourceSpec + ContextMutationConfig type definitions only; SS-01 |
| core::write_guard | pregolya-core | — | — | — | — | Definitions-only; Tier=— (ADR-009/ADR-012 D20): MemoryWriteRequest enum + MemoryWriteGuard trait definitions only; SS-15 |

## Coverage by Criticality Tier

| Tier | Modules | Kani VPs | proptest (actual current) | fuzz | Kill Rate Target |
|------|---------|---------|---------|------|-----------------|
| CRITICAL | 12 | 6 (VP-001, VP-002, VP-003, VP-009, VP-010, VP-011) | 3 of 12: graph::bsp_engine, checkpoint::session_index, checkpoint::clock | subset | ≥ 95% |
| HIGH | 30 | 3 (VP-006, VP-012, VP-013) | 8 of 30: core::runnable, core::runnable::parallel/VP-014, core::message, core::serializable/VP-007, core::embeddings/VP-008, graph::definition, graph::channels, graph::budget | subset | ≥ 90% |
| MEDIUM | 35 | 0 | some | — | ≥ 80% |
| LOW | 2 | 0 | — | — | n/a (xtask and pregolya-community excluded from cargo-mutants per tooling-selection.md; advisory only) |

> **Coverage gap — stated obligation:** Actual proptest coverage is 3 of 12 CRITICAL and 8 of 30 HIGH (derivation: counted proptest column = yes/VP-NNN from per-module table above, grouped by tier). Modules with Kani VPs have formal verification coverage at the proof level, which is stronger than proptest. Modules with only integration tests and no Kani VP are proptest coverage gaps. **Coverage obligation:** expand proptest to all 12 CRITICAL and 30 HIGH modules is a Phase 5/6 obligation; the gate in tooling-selection.md reflects current 11-module coverage (3 CRITICAL + 8 HIGH) with the obligation stated explicitly.

## Mutation Kill Rate Gates (cargo-mutants)

Kill rate gates are Phase-5 adversarial gates. Phase-3 per-story gates apply to CRITICAL modules only.

| Tier | Gate | Phase |
|------|------|-------|
| CRITICAL | ≥ 95% | Phase 3 (per story) + Phase 5 |
| HIGH | ≥ 90% | Phase 5 |
| MEDIUM | ≥ 80% | Phase 5 |
| LOW | ≥ 70% | Phase 5 advisory |
