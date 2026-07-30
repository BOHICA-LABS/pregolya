---
document_type: module-criticality
level: L3
version: "2.9"
status: active
producer: architect
timestamp: 2026-07-27T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "710f965"
traces_to: ARCH-INDEX.md
lifecycle: "Mutable through Phase 5; frozen after Phase 5 gate passes."
note: "This is the architecture-view criticality. The prd-supplements/module-criticality.md is the PO draft; this file is authoritative post-Phase 1b."
changelog:
  - "2.9 (D-35-rename-sweep/2026-07-28): D-35 canonical xtask naming sweep — NE Catalog Enforcement Mechanism cells: `cargo xtask deny-client-new` → `cargo xtask check-client-timeout` (NE-04); `cargo xtask deny-expect-in-lib` → `cargo xtask check-no-panic` (NE-07). Superseded variant names forbidden; canonical `check-<subject>` form per D-35."
  - "2.8 (FIX-BURST-278-WAVE-A/F-P175-D212/2026-07-28): Iron Law — add `core::tool` HIGH row (pregolya-core SS-08; Tool/DynTool trait seam; DynTool blanket impl; ToolOutput variant mapping; no Kani VP; BC-2.08.010; no kill rate exception). Required by module-decomposition.md §core::tool row addition. Classification Summary: HIGH 28→29; Total 83→84. GATE-25 arithmetic post-fix: 84(total) − 77(module-level) = 7(crate-level) ✓."
  - "2.7 (FIX-BURST-278/F-P175-D111/2026-07-28): Ambiguity fix — `= 77 rows total` → `= 77 tiered rows` in Module/crate breakdown blockquote. The `| Total | 83 |` table row counts all rows; the `77` in the breakdown counts only tiered rows (CRITICAL/HIGH/MEDIUM/LOW); the prior phrasing was ambiguous. Aligned with verification-coverage-matrix.md wording."
  - "2.6 (FIX-BURST-277-WAVE-B/2026-07-28): Item 6 module census — add 6 definitions-only/exempt module rows: core::documents (definitions-only, D21/SS-20, ADR-014 Decision 2: pure data carrier, no execution methods), memory::skills (routing-overlay/exempt, D20/SS-15, ADR-012 Decision 4: structural decomposition row only), core::guardrail (definitions-only, SS-11, ADR-009/ADR-014 Decision 6), core::action_risk (definitions-only, SS-05, ADR-009/F-P170-06/ADR-020 Decision 3), core::context_mutation (definitions-only, D20/SS-01, ADR-009/ADR-012), core::write_guard (definitions-only, D20/SS-15, ADR-009/ADR-012). All have Tier=— (no kill rate obligation; not subject to Phase 5 gates). Total 77→83. Tiered count (CRITICAL 12 / HIGH 28 / MEDIUM 35 / LOW 2 = 77) unchanged. GATE-25 arithmetic check: 83 − 76 = 7 (crate-level rows; 6 new rows are module-level, now matched in decomp after FIX-BURST-277 module-decomposition additions)."
  - "2.5 (FIX-BURST-276-CHECK4/2026-07-27): CHECK4 canonicality closure — rename three crate-level BaseChatModel provider rows to full canonical crate names: `openai` → `pregolya-openai`, `anthropic` → `pregolya-anthropic`, `ollama` → `pregolya-ollama`. Aligns with established pattern: pregolya-macros, pregolya-standard-tests, xtask, pregolya-community all use the full crate name form recognized by ARCH-INDEX.md canonical-roster; purity-boundary-map.md already uses these full names (confirmed via verify-module-canonicality.sh SET-DIFF baseline). NE Catalog NE-04 and NE-07: replace aggregate-scope Module cells with `—` and append scope description to Enforcement Mechanism column (aggregate policy scope is not a module identifier; checker skips `—` cells per design). Column guide and Classification Summary updated to use full crate names. Census sextuple unchanged: (71, 69, 2, 77, 76, 69) — no rows added or removed from Module Classification table; all tier assignments unchanged."
  - "2.4 (FIX-BURST-276-TD091/2026-07-27): TD-VSDD-091 anti-volatile-pin repair — Iron Law gap note (eval::judge): replace live-body sibling-artifact version pin with stable section anchor. observability.md §Catalog (the Catalog table section that contains the eval.judge_infra_error row and its emitter attribution) replaces a specific version number. Sibling-sweep of this file live body: no additional version pins found."
  - "2.3 (FIX-BURST-276-WAVE-B1/F-P173-301+402/2026-07-27): F-P173-301/402 sibling sweep — fix eval::judge BC anchor in Iron Law gap note: `BC-2.08.013/014 scope the LLM judge conformance behavior` → `BC-2.08.008 scopes the judge score aggregation behavior`. Correct anchor: BC-2.08.008 = Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome (NE-15); BC-2.08.013/014 are provider-behavior BCs, not eval-scoring BCs. False closure claim corrected per TD-VSDD-059: the observability.md emitter linkage was restored by FIX-BURST-276-WAVE-C1 (concurrent PO fix to observability.md v1.7), not by the Iron Law entry addition in v2.1; v2.1 changelog claim 'this clears the observability.md pending note' was erroneous (historical record preserved; correction is in Iron Law gap note body text). TD-VSDD-060 sibling sweep: BC anchor also corrected in module-decomposition.md (v1.34), purity-boundary-map.md (v1.23), verification-coverage-matrix.md (v2.9) in same burst."
  - "2.2 (FIX-BURST-275-REOPENED/Defect-2+3+crate-row-audit/2026-07-26): Defect 2 — add three missing HIGH module rows for pregolya-macros proc-macros: `macros::tool` (SS-08, HIGH, #[tool] ToolDefinition generation per BC-2.08.010), `macros::entrypoint` (SS-08, HIGH, #[entrypoint] START-edge wiring per BC-2.08.011), `macros::task` (SS-08, HIGH, #[task] task-registration boilerplate per BC-2.08.012). All three are tiered HIGH rows in module-decomposition.md since v1.2 (ADV-P1D-PASS-37) but lacked individual registry rows; the crate-level pregolya-macros row masked their absence. pregolya-macros crate-level Qualifier updated: 'crate-level — #[tool] #[entrypoint] #[task]' → 'crate-level — proc-macro crate' (roll-up annotation; individual module rows are census-authoritative). Defect 3 — core::serializable duplicate Module cell (both rows share 'core::serializable' after F-P172b-06 normalization): rows are already uniquely identifiable via (Module, Qualifier) composite key ('Reviver — allowlist containment' vs 'LcSerializable round-trip'); column guide updated to document composite-key disambiguation for multi-aspect modules. Crate-level row audit (all 7 rows, per-row verification): (1) `openai` — BaseChatModel impl; openai::embeddings is a SEPARATE module row; annotation accurate. (2) `anthropic` — BaseChatModel impl; no module-level rows in decomp (Anthropic excluded from SS-22 per ADR-017); accurate. (3) `ollama` — BaseChatModel impl; ollama::embeddings is a SEPARATE module row; annotation accurate. (4) `pregolya-macros` — had 3 HIGH module rows in decomp (macros::tool/entrypoint/task) but no registry rows; DEFECT FIXED above. (5) `pregolya-standard-tests` — eval::judge module row added v2.1; crate-level row is supplementary; accurate. (6) `xtask` — no module-level rows in decomp (bulleted list only); accurate. (7) `pregolya-community` — no module-level rows; accurate. Classification Summary: HIGH 25 → 28 (+macros::tool/entrypoint/task); Total 74 → 77. Census quintuple (post-fix): decomposition_total_rows=71, decomposition_tiered_rows=69, exempt_count=2, registry_rows=77, matched_rows=69. Identity 1: 71=69+2 ✓. Identity 2: 69=69 ✓. Difference set (tiered decomp − registry module-level cells) = empty ✓."
  - "2.1 (FIX-BURST-275/F-P172b-01+02+06+15+18+Iron-Law/2026-07-26): F-P172b-01 — add 7 missing tiered-module rows (absent from registry but present as tiered rows in module-decomposition.md): `openai::embeddings` HIGH (credential-bearing HTTP surface, DI-009/DI-010 per ADR-017; analogous to openai BaseChatModel crate-level HIGH); `ollama::embeddings` HIGH (same conformance contract as ollama BaseChatModel; ADR-017 DI-009); `vectorstores::store` MEDIUM (VectorStore trait dispatch; no VP, no credential handling); `vectorstores::retriever` MEDIUM (VectorStoreRetriever bridge; no VP); `vectorstores::memory` MEDIUM (in-memory backend; no VP); `tools::fs` MEDIUM (path-guard consumer; VP-003 on `sandbox::path_guard` covers traversal); `tools::search` MEDIUM (path-guard consumer; same rationale). F-P172b-02 — replace phantom '56-row module-decomposition universe' with '70 (68 tiered + 2 exempt) module-decomposition universe' in §Module-universe sweep; correct NE-Catalog entry names to canonical form. F-P172b-06 — add Qualifier column to Module Classification table; normalize all Module cells to canonical `crate::module` form; annotate all 7 crate-level rows with crate-level Qualifier (openai/anthropic/ollama BaseChatModel, pregolya-macros, pregolya-standard-tests, xtask, pregolya-community); normalize Security Profile module names to canonical form; normalize NE-Catalog module names to canonical form. F-P172b-15 — elevate `mcp::ingress` MEDIUM → HIGH (external untrusted-input side of DI-012 guardrail-dispatch Boundary; parity with `graph::provenance` HIGH; Production-Grade Default: external-ingress must not have lower kill-rate than internal guardrail consumer; BC-2.09.003). F-P172b-18 adjudication — keep cargo-mutants exclusions for xtask/ and pregolya-community/ (not production runtime; exclusions in tooling-selection.md are correct); update Kill Rate cells to reflect exclusion status. Iron Law gap (pregolya-standard-tests / eval::judge) — add `eval::judge` MEDIUM module row (LLM judge execution; emits `eval.judge_infra_error` structured event per observability.md; BC-2.08.013/014 scope; Effectful Shell); this clears the observability.md pending note anchored to the missing Iron Law entry. TD-VSDD-060 sibling sweep: openai::embeddings and ollama::embeddings raised HIGH in registry → tier also corrected in module-decomposition.md Provider Embeddings section in same burst. Classification Summary: CRITICAL 12 (unchanged), HIGH 22 → 25 (+openai::embeddings, +ollama::embeddings, mcp::ingress elevation), MEDIUM 30 → 35 (+vectorstores::store/retriever/memory, +tools::fs/search, +eval::judge, -mcp::ingress), LOW 2 (unchanged). Total 66 → 74."
  - "2.0 (FIX-BURST-274/module-universe-sweep/2026-07-26): Full module-universe coverage sweep — 18 execution-logic modules lacking criticality rows identified by diffing the 56-row module-decomposition universe against the prior 48-row registry. The v1.0 base was scoped to the most prominent modules; v1.4 D21+burst-224 backfill covered only VP-bearing modules; neither pass covered checkpoint backends, server secondary modules, sandbox backends, or per-crate secondary modules. CRITICAL +1: checkpoint::saver (pregolya-checkpoint SS-04) — CheckpointSaver `put_writes` durability invariant; CRITICAL per tier definition 'durability invariants' criterion. HIGH +4: core::events (pregolya-core SS-06) BC-2.06.001 streaming event taxonomy parallel to core::message HIGH; graph::definition (pregolya-graph SS-02) StateGraph builder node/edge registration and conditional routing; server::streaming (pregolya-server SS-12) SSE streaming endpoint NE-13 same-engine constraint; server::stores (pregolya-server SS-12) IdempotencyStore/RateLimitStore/RunStore trait seams NE-08 constraint. MEDIUM +13: core::config (SS-01), checkpoint::memory (SS-04), checkpoint::postgres (SS-04), server::cron (SS-12), sandbox::container (SS-13), sandbox::seatbelt (SS-13), sandbox::process (SS-13), splitters::parity (SS-07), mcp::discovery (SS-09), mcp::ingress (SS-09), memory::sqlite (SS-15), memory::in_memory (SS-15), memory::search (SS-15). Classification Summary: CRITICAL 11→12, HIGH 18→22, MEDIUM 17→30, Total 48→66."
  - "1.9 (FIX-BURST-274/D21-definitions-sweep/2026-07-26): D21 Pure Core sweep — add 4 missing MEDIUM execution-logic rows excluded from the D21+burst-224 backfill (that backfill added only VP-bearing modules; execution modules without VPs were overlooked): (1) core::retriever (pregolya-core SS-20): Boundary Module with rag_ingress async execution logic and DI-012 RAGRetrieval enforcement; no standalone VP; MEDIUM consistent with sandbox-policy and core::retry precedent. (2) prompts::template (pregolya-prompts SS-18): Pure Core f-string rendering engine; variable substitution and .partial() builder; no VP. (3) prompts::chat_template (pregolya-prompts SS-18): Pure Core multi-message template construction with MessageProvenance output; no VP. (4) prompts::few_shot (pregolya-prompts SS-18): Pure Core FewShotPromptTemplate assembly with snapshot-frozen golden fixture tests; no VP. Classification Summary: MEDIUM 13→17, Total 44→48."
  - "1.8 (FIX-BURST-273/gate-25-32/2026-07-25): Add `tools::config` MEDIUM row (pregolya-tools SS-23) — gate #25 Part B sibling propagation completing burst-273 module-universe +1; MEDIUM tier: `override_risk` builder-consuming validator enforces per-tool risk-floor rules (ADR-020 Decision 3 / BC-2.23.005) but does not host a Kani VP (`check_risk_floor` Kani P1 target lives in tools::shell per VP-013); MEDIUM consistent with sandbox-policy precedent (supporting policy-enforcement module, not primary VP host). Classification Summary: MEDIUM 12→13, Total 43→44."
  - "1.7 (FIX-BURST-267/F-P165-05/2026-07-25): Narrow CRITICAL tier definition — 'Kani VP targets' → 'Kani P0 VP targets'; the previous wording made every Kani VP host CRITICAL, contradicting the established HIGH classification for Kani P1 hosts (injection_guard VP-006, core-budget VP-012, tools-shell VP-013). Add Kani P1 VP hosts clause to HIGH tier definition: 'Core business logic, conformance contracts, server lifecycle; Kani P1 VP hosts'. No module row changes — all tier assignments already correctly reflect P0/P1 distinction; this fixes only the tier-definition prose."
  - "1.6 (burst-244/2026-07-23): F-P144-02 adjudication — add core-budget (HIGH, VP-012 Kani P1, pregolya-core SS-10) and tools-shell (HIGH, VP-013 Kani P1, pregolya-tools SS-23) rows; removes deferred posture from v1.5. core-budget HIGH: VP-012 Kani P1 hosts check_watermark_trigger (pure-core arithmetic); established project pattern assigns HIGH to all Kani P1 VP hosts (injection_guard precedent); token watermark arithmetic is governance-correctness, not a security boundary — CRITICAL overclaims. tools-shell HIGH: VP-013 Kani P1 hosts check_risk_floor (pure-core enum comparison enforcing non-lowerable Medium risk floor per ADR-020 Decision 3 'framework safety invariant'); profile mirrors injection_guard (VP-006 Kani P1 HIGH — both are pure-core security invariants enforced by construction); CRITICAL requires direct security-boundary or durability role. Both assignments match pre-existing verification-coverage-matrix.md HIGH classification (F-P144-01 contradiction resolved). Classification Summary: HIGH 16→18, Total 41→43."
  - "1.5 (burst-229/2026-07-22): Input-hash cascade refresh — ARCH-INDEX.md v1.6 + module-decomposition.md v1.15 both changed in burst 229 (D23 architecture layer: ADR-018/019/020, SS-23 pregolya-tools crate #21, Wave-1 promotions SS-15/SS-16). No content rows added (pregolya-tools criticality rows deferred to architect D23 content authoring). Hash: ac2e35a → db6f656."
  - "1.4 (burst-224/2026-07-21): D21+burst-224 backfill — add 6 criticality rows missing since burst-223 (D21 module universe not propagated to this file). CRITICAL +2: serializable-reviver (VP-010 Kani P0 / SS-19), vectorstores-similarity (VP-009 Kani P0 / SS-21 / burst-224 final name after F-P129-11). HIGH +3: injection_guard (VP-006 Kani P1 / SS-18), serializable (VP-007 proptest P1 / SS-19), embeddings (VP-008 proptest P1 / SS-22). MEDIUM +1: vectorstores-mmr (SS-21; MMR-only after VP-009 relocated to vectorstores-similarity in burst-224). Summary 35→41. Definitions-only D21 artifacts (core::guardrail per ADR-014 Decision 6) excluded per no-row precedent."
  - "1.3 (D20/CAP-021): add mcp-server MEDIUM row (+1 execution module; CAP-021 MCP server role, inbound tool-call dispatch). Summary 34→35: MEDIUM 10→11 total."
  - "1.2 (D20/ADR-012): add memory::write_guard HIGH row (+1 execution module per ADR-012 Decision 4 gate #25 ruling; write-path injection scanning enforcement, security-significant). Summary 33→34: HIGH 12→13 total. Definitions-only D20 artifacts (core::context_mutation, core::write_guard, memory::skills) excluded per no-row precedent (ADR-009 Option 3 / D18-P61-C)."
  - "1.1 (ADV-P1D-PASS-32): F-P32-04 (LOW, adjudicated) add pregolya-macros HIGH-tier row to Module Inventory (consistent with OBS-P31-1 prd-supplements decision; orchestrator adjudication — #[tool]/#[entrypoint] affect P0 paths per ADR-008); add facade/SDK exclusion note mirroring prd-supplements/module-criticality.md. F-P32-01 (HIGH) recount all rows and rewrite Summary to match exactly (pre-fix summary was wrong: said HIGH 10 / MEDIUM 12, actual HIGH 11 / MEDIUM 10; +macros → CRITICAL 9 / HIGH 12 / MEDIUM 10 / LOW 2 = 33 total)."
---

# Module Criticality Classification: pregolya (Architecture View)

## Tier Definitions

| Tier | Kill Rate Target | Description |
|------|-----------------|-------------|
| CRITICAL | ≥ 95% | Kani P0 VP targets, security boundaries, durability invariants |
| HIGH | ≥ 90% | Core business logic, conformance contracts, server lifecycle; Kani P1 VP hosts |
| MEDIUM | ≥ 80% | Supporting functionality with correctness requirements |
| LOW | ≥ 70% | Build tooling, infrastructure, boilerplate |

## Module Classification

> **Column guide:** Module = canonical `crate::module` path (or crate name for crate-level rows). Qualifier = sub-component discriminator or crate-level annotation. Crate-level rows annotated `crate-level` (xtask, pregolya-community, pregolya-standard-tests, pregolya-openai/pregolya-anthropic/pregolya-ollama BaseChatModel, pregolya-macros) are excluded from exact 1:1 module census matching; the pregolya-macros crate-level row is a roll-up — its census-authoritative entries are the individual macros::tool/entrypoint/task module rows. Multi-aspect modules (core::serializable) with two rows use (Module, Qualifier) as the composite key for per-row identification; the census treats the module as matched when any registry row covers the Module cell.

| Module | Qualifier | Crate | SS | Tier | VP | Kill Rate | Phase Gate |
|--------|-----------|-------|-----|------|-----|-----------|-----------|
| `graph::bsp_engine` | reducer stage | pregolya-graph | SS-03 | CRITICAL | VP-001 | ≥ 95% | P3 per-story + P5 |
| `graph::scheduler` | — | pregolya-graph | SS-03 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| `graph::hitl` | — | pregolya-graph | SS-05 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| `checkpoint::session_index` | — | pregolya-checkpoint | SS-04 | CRITICAL | VP-002 | ≥ 95% | P3 per-story + P5 |
| `checkpoint::clock` | — | pregolya-checkpoint | SS-04 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| `checkpoint::encryption` | — | pregolya-checkpoint | SS-04 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| `sandbox::path_guard` | — | pregolya-sandbox | SS-13 | CRITICAL | VP-003 | ≥ 95% | P3 per-story + P5 |
| `core::credentials` | — | pregolya-core | SS-14 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| `core::error` | — | pregolya-core | SS-14 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| `graph::channels` | — | pregolya-graph | SS-02 | HIGH | — | ≥ 90% | P5 |
| `graph::budget` | — | pregolya-graph | SS-10 | HIGH | — | ≥ 90% | P5 |
| `graph::provenance` | — | pregolya-graph | SS-11 | HIGH | — | ≥ 90% | P5 |
| `core::runnable` | — | pregolya-core | SS-01 | HIGH | — | ≥ 90% | P5 |
| `core::message` | — | pregolya-core | SS-01 | HIGH | — | ≥ 90% | P5 |
| `server::handlers` | — | pregolya-server | SS-12 | HIGH | — | ≥ 90% | P5 |
| `server::security` | — | pregolya-server | SS-12 | HIGH | — | ≥ 90% | P5 |
| `pregolya-openai` | crate-level — BaseChatModel impl | pregolya-openai | SS-08 | HIGH | — | ≥ 90% | P5 |
| `pregolya-anthropic` | crate-level — BaseChatModel impl | pregolya-anthropic | SS-08 | HIGH | — | ≥ 90% | P5 |
| `pregolya-ollama` | crate-level — BaseChatModel impl | pregolya-ollama | SS-08 | HIGH | — | ≥ 90% | P5 |
| `checkpoint::lineage` | — | pregolya-checkpoint | SS-04 | HIGH | — | ≥ 90% | P5 |
| `pregolya-macros` | crate-level — proc-macro crate | pregolya-macros | — | HIGH | — | ≥ 90% | P5 |
| `macros::tool` | — | pregolya-macros | SS-08 | HIGH | — | ≥ 90% | P5 |
| `macros::entrypoint` | — | pregolya-macros | SS-08 | HIGH | — | ≥ 90% | P5 |
| `macros::task` | — | pregolya-macros | SS-08 | HIGH | — | ≥ 90% | P5 |
| `memory::write_guard` | — | pregolya-memory | SS-15 | HIGH | — | ≥ 90% | P5 |
| `checkpoint::sqlite` | — | pregolya-checkpoint | SS-04 | MEDIUM | — | ≥ 80% | P5 |
| `splitters::recursive` | — | pregolya-splitters | SS-07 | MEDIUM | — | ≥ 80% | P5 |
| `mcp::client` | — | pregolya-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| `mcp::adapter` | — | pregolya-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| `mcp::server` | — | pregolya-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| `sandbox::wasm` | — | pregolya-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| `sandbox::policy` | — | pregolya-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| `pregolya-standard-tests` | crate-level | pregolya-standard-tests | SS-08 | MEDIUM | — | ≥ 80% | P5 |
| `core::retry` | — | pregolya-core | SS-16 | MEDIUM | — | ≥ 80% | P5 |
| `memory::store` | — | pregolya-memory | SS-15 | MEDIUM | — | ≥ 80% | P5 |
| `graph::event_emitter` | — | pregolya-graph | SS-06 | MEDIUM | — | ≥ 80% | P5 |
| `xtask` | crate-level | xtask | SS-17 | LOW | — | n/a (excluded from cargo-mutants) | advisory |
| `pregolya-community` | crate-level | pregolya-community | — | LOW | — | n/a (excluded from cargo-mutants) | advisory |
| `core::serializable` | Reviver — allowlist containment | pregolya-core | SS-19 | CRITICAL | VP-010 | ≥ 95% | P3 per-story + P5 |
| `vectorstores::similarity` | — | pregolya-vectorstores | SS-21 | CRITICAL | VP-009 | ≥ 95% | P3 per-story + P5 |
| `prompts::injection_guard` | — | pregolya-prompts | SS-18 | HIGH | VP-006 | ≥ 90% | P3 per-story + P5 |
| `core::serializable` | LcSerializable round-trip | pregolya-core | SS-19 | HIGH | VP-007 | ≥ 90% | P5 |
| `core::embeddings` | — | pregolya-core | SS-22 | HIGH | VP-008 | ≥ 90% | P5 |
| `core::budget` | — | pregolya-core | SS-10 | HIGH | VP-012 | ≥ 90% | P3 per-story + P5 |
| `core::tool` | — | pregolya-core | SS-08 | HIGH | — | ≥ 90% | P5 |
| `tools::shell` | — | pregolya-tools | SS-23 | HIGH | VP-013 | ≥ 90% | P3 per-story + P5 |
| `vectorstores::mmr` | — | pregolya-vectorstores | SS-21 | MEDIUM | — | ≥ 80% | P5 |
| `tools::config` | — | pregolya-tools | SS-23 | MEDIUM | — | ≥ 80% | P5 |
| `core::retriever` | — | pregolya-core | SS-20 | MEDIUM | — | ≥ 80% | P5 |
| `prompts::template` | — | pregolya-prompts | SS-18 | MEDIUM | — | ≥ 80% | P5 |
| `prompts::chat_template` | — | pregolya-prompts | SS-18 | MEDIUM | — | ≥ 80% | P5 |
| `prompts::few_shot` | — | pregolya-prompts | SS-18 | MEDIUM | — | ≥ 80% | P5 |
| `checkpoint::saver` | — | pregolya-checkpoint | SS-04 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
| `core::events` | — | pregolya-core | SS-06 | HIGH | — | ≥ 90% | P5 |
| `graph::definition` | — | pregolya-graph | SS-02 | HIGH | — | ≥ 90% | P5 |
| `server::streaming` | — | pregolya-server | SS-12 | HIGH | — | ≥ 90% | P5 |
| `server::stores` | — | pregolya-server | SS-12 | HIGH | — | ≥ 90% | P5 |
| `core::config` | — | pregolya-core | SS-01 | MEDIUM | — | ≥ 80% | P5 |
| `checkpoint::memory` | — | pregolya-checkpoint | SS-04 | MEDIUM | — | ≥ 80% | P5 |
| `checkpoint::postgres` | — | pregolya-checkpoint | SS-04 | MEDIUM | — | ≥ 80% | P5 |
| `server::cron` | — | pregolya-server | SS-12 | MEDIUM | — | ≥ 80% | P5 |
| `sandbox::container` | — | pregolya-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| `sandbox::seatbelt` | — | pregolya-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| `sandbox::process` | — | pregolya-sandbox | SS-13 | MEDIUM | — | ≥ 80% | P5 |
| `splitters::parity` | — | pregolya-splitters | SS-07 | MEDIUM | — | ≥ 80% | P5 |
| `mcp::discovery` | — | pregolya-mcp | SS-09 | MEDIUM | — | ≥ 80% | P5 |
| `mcp::ingress` | — | pregolya-mcp | SS-09 | HIGH | — | ≥ 90% | P5 |
| `memory::sqlite` | — | pregolya-memory | SS-15 | MEDIUM | — | ≥ 80% | P5 |
| `memory::in_memory` | — | pregolya-memory | SS-15 | MEDIUM | — | ≥ 80% | P5 |
| `memory::search` | — | pregolya-memory | SS-15 | MEDIUM | — | ≥ 80% | P5 |
| `vectorstores::store` | — | pregolya-vectorstores | SS-21 | MEDIUM | — | ≥ 80% | P5 |
| `vectorstores::retriever` | — | pregolya-vectorstores | SS-20 | MEDIUM | — | ≥ 80% | P5 |
| `vectorstores::memory` | — | pregolya-vectorstores | SS-21 | MEDIUM | — | ≥ 80% | P5 |
| `openai::embeddings` | — | pregolya-openai | SS-22 | HIGH | — | ≥ 90% | P5 |
| `ollama::embeddings` | — | pregolya-ollama | SS-22 | HIGH | — | ≥ 90% | P5 |
| `tools::fs` | — | pregolya-tools | SS-23 | MEDIUM | — | ≥ 80% | P5 |
| `tools::search` | — | pregolya-tools | SS-23 | MEDIUM | — | ≥ 80% | P5 |
| `eval::judge` | — | pregolya-standard-tests | SS-08 | MEDIUM | — | ≥ 80% | P5 |
| `core::documents` | definitions-only | pregolya-core | SS-20 | — | — | — (no kill rate obligation) | — |
| `memory::skills` | routing-overlay/exempt | pregolya-memory | SS-15 | — | — | — (no kill rate obligation) | — |
| `core::guardrail` | definitions-only | pregolya-core | SS-11 | — | — | — (no kill rate obligation) | — |
| `core::action_risk` | definitions-only | pregolya-core | SS-05 | — | — | — (no kill rate obligation) | — |
| `core::context_mutation` | definitions-only | pregolya-core | SS-01 | — | — | — (no kill rate obligation) | — |
| `core::write_guard` | definitions-only | pregolya-core | SS-15 | — | — | — (no kill rate obligation) | — |

> **D21+burst-224 additions (v1.4):** `core::serializable` (Reviver) and `vectorstores::similarity` added as CRITICAL (Kani P0 proof obligations VP-010 and VP-009 respectively). `prompts::injection_guard`, `core::serializable` (LcSerializable), `core::embeddings` added as HIGH (Kani P1 and proptest P1 proof obligations VP-006/007/008). `vectorstores::mmr` added as MEDIUM (MMR-only selection algorithm; VP-009 relocated to vectorstores::similarity in burst-224). Definitions-only D21 artifacts (core::guardrail per ADR-014 Decision 6) excluded per no-row precedent.

> **F-P144-02 adjudication (burst-244/v1.6):** `core::budget` (pregolya-core SS-10) and `tools::shell` (pregolya-tools SS-23) added as HIGH. **core::budget HIGH:** VP-012 is a Kani P1 obligation for `check_watermark_trigger` — a pure-core arithmetic function computing the OnWatermark budget ceiling comparison. The established tier pattern assigns HIGH to all Kani P1 VP hosts (injection_guard precedent). Token watermark arithmetic is correctness-significant for budget governance but is not a security boundary (no cross-tenant isolation, no credential handling, no path traversal prevention) — CRITICAL would require one of those roles. **tools::shell HIGH:** VP-013 is a Kani P1 obligation for `check_risk_floor` — a pure-core enum comparison enforcing BashTool's non-lowerable Medium risk floor. ADR-020 Decision 3 names this a "framework safety invariant non-lowerable by application configuration." The property is security-relevant: bypassing the floor permits BashTool to execute shell commands without the minimum HITL risk-approval gate. This profile mirrors `prompts::injection_guard` (VP-006, Kani P1, HIGH): both are pure-core security checks enforced by construction that prevent a dangerous misconfiguration. CRITICAL would require a direct security-boundary role (credential handling, cross-tenant isolation, path traversal prevention) — `tools::shell` enforces a configuration gate, not a runtime isolation boundary. Phase Gate "P3 per-story + P5" for both: Kani P1 VP hosts inherit the `prompts::injection_guard` gate assignment.

> **Exclusion criteria (F-P32-04, ADV-P1D-PASS-32):** Facade/re-export and codegen-thin
> crates (`pregolya` #1, `pregolya-openai-sdk` #16, `pregolya-anthropic-sdk` #17,
> `pregolya-ollama-sdk` #18) carry no criticality-bearing modules of their own and are
> intentionally excluded from this inventory — they re-export from the implementation crates
> listed above and contain no independent logic paths. `xtask` is classified because its
> file-size-check and CI-lint logic gates all merges (SS-17). `pregolya-macros` is NOT
> excluded: `#[tool]` generates ToolDefinition plumbing for all P0 tool-calling paths
> (BC-2.09.001, BC-2.09.002) and `#[entrypoint]` gates graph composition entry points;
> incorrect macro expansion silently corrupts P0 execution without a clear runtime error.
> DECISION: `pregolya-macros` receives a HIGH-tier crate-level row (annotated Qualifier column).
> Consistent with OBS-P31-1 (prd-supplements/module-criticality.md) and orchestrator adjudication
> in ADV-P1D-PASS-32. `pregolya-community` retains a LOW row as a placeholder for post-v1
> third-party contributions; it is not in-tree at v1.
>
> **F-P172b-18 adjudication (v2.1):** `xtask` and `pregolya-community` excluded from
> cargo-mutants per tooling-selection.md Exclusions clause (not production runtime). Kill Rate
> column updated to `n/a (excluded from cargo-mutants)` to eliminate the ambiguity between
> a target of ≥ 70% that might be unmet vs. a target that explicitly does not apply.

> **D21 Pure Core sweep (v1.9):** The D21+burst-224 backfill (v1.4) added only VP-bearing
> modules; execution-logic modules without VPs were not added then. Four gaps closed here.
> **core::retriever** (Boundary Module, pregolya-core SS-20): `rag_ingress` async function
> dispatches per-document through an injected `&dyn GuardrailHook`; DI-012 RAGRetrieval
> boundary enforced at type level via `GuardedDocuments` newtype (ADR-014 Decision 6); no
> standalone VP-INDEX entry. MEDIUM tier consistent with `sandbox::policy` and `core::retry`
> precedent (Boundary Modules with enforcement logic but no Kani VP).
> **prompts::template** (Pure Core, SS-18): f-string variable-substitution rendering engine;
> `.partial()` builder returns a new pure value; no VP.
> **prompts::chat_template** (Pure Core, SS-18): `ChatPromptTemplate` multi-message
> construction producing `PromptValue` with per-message `MessageProvenance`; no VP.
> **prompts::few_shot** (Pure Core, SS-18): `FewShotPromptTemplate` example assembly and
> template rendering with snapshot-frozen golden fixture tests; no VP.
> All four are MEDIUM: correctness-required execution modules with no security-boundary role.

## Classification Summary

| Tier | Module Count |
|------|-------------|
| CRITICAL | 12 |
| HIGH | 29 |
| MEDIUM | 35 |
| LOW | 2 |
| — (definitions-only/exempt) | 6 |
| **Total** | **84** |

> Module/crate breakdown: 12 CRITICAL module-level + 25 HIGH module-level (incl. macros::tool, macros::entrypoint, macros::task added FIX-BURST-275-reopened; core::tool added FIX-BURST-278) + 4 HIGH crate-level (pregolya-openai/pregolya-anthropic/pregolya-ollama BaseChatModel + pregolya-macros crate-level roll-up) + 34 MEDIUM module-level + 1 MEDIUM crate-level (pregolya-standard-tests) + 2 LOW crate-level (xtask + pregolya-community) = 78 tiered rows.

## CRITICAL Module — Security Profile

| Module | Blast Radius | Security Sensitivity | VP |
|--------|-------------|---------------------|----|
| `graph::bsp_engine` | all graph runs | low (correctness) | VP-001 |
| `graph::scheduler` | all graph runs | low (correctness) | — |
| `graph::hitl` | all HITL scenarios | medium (auth gates in Domain A) | — |
| `checkpoint::session_index` | multi-tenant isolation | HIGH (cross-tenant data leak) | VP-002 |
| `checkpoint::clock` | all durable runs | medium (ordering) | — |
| `checkpoint::encryption` | all checkpoint state | HIGH (data at rest) | — |
| `sandbox::path_guard` | all tool execution | HIGH (path traversal, Domain C) | VP-003 |
| `core::credentials` | error observability | HIGH (credential leak) | — |
| `core::error` | API contract | HIGH (leaks in Debug output) | — |
| `core::serializable` (Reviver) | all lc-JSON deserialization paths | HIGH (unknown type deserialization bypasses allowlist → arbitrary constructor execution) | VP-010 |
| `vectorstores::similarity` | all similarity/MMR search paths | MEDIUM (IEEE-754 NaN corruption of ranking; data integrity, not direct auth bypass) | VP-009 |
| `checkpoint::saver` | all checkpoint write paths | HIGH (durability failure: `put_writes` contract violation corrupts durable session record; multi-tenant session integrity depends on correct write ordering and cross-backend consistency) | — |

## Anti-Patterns Enforced by Architecture (NE Catalog)

All 17 NE patterns from COMPARATIVE-ASSESSMENT are anchored. Architecture-specific enforcements:

| NE | Module | Enforcement Mechanism |
|----|--------|-----------------------|
| NE-01 | `sandbox::policy` | Enforcing backend default; `Err(PolicyNotEnforceable)` on mismatch |
| NE-02 | `sandbox::path_guard` | `canonicalize_beneath_root` mandatory; VP-003 Kani proof |
| NE-04 | — | `cargo xtask check-client-timeout` CI gate (scope: all provider + MCP modules) |
| NE-07 | — | `cargo xtask check-no-panic` CI gate (scope: workspace-wide, all crates) |
| NE-10 | `core::credentials` | Newtype enforcement; `cargo xtask` custom lint |
| NE-12 | `checkpoint::session_index` | Triple-address composite key; VP-002 Kani proof |
| NE-13 | `server::streaming` | Same engine for streaming + unary; SSE tap only |
| NE-14 | `server::security` | `SecurityConfig::default()` deny-CORS; debug route opt-in |
| NE-17 | `graph::bsp_engine` | Task-identity sort + VP-001 Kani proof |

> **Module-universe sweep (v2.0):** Closing all execution-logic gaps found by diffing the 70 (68 tiered + 2 exempt) module-decomposition universe against the prior 48-row criticality registry. Four structural patterns explain the 18 gaps: (1) v1.0 base was scoped to the most prominent modules only; (2) checkpoint backends and storage-tier modules (`checkpoint::memory`/`checkpoint::postgres`, `memory::sqlite`/`memory::in_memory`/`memory::search`) were systematically omitted alongside their primary modules; (3) server layer secondary modules (`server::streaming`, `server::stores`, `server::cron`) were omitted alongside `server::handlers` and `server::security`; (4) per-crate secondary modules (`sandbox::container`/`seatbelt`/`process`, `mcp::discovery`/`mcp::ingress`, `splitters::parity`) were omitted alongside their primaries.
>
> Tier adjudications: **`checkpoint::saver` CRITICAL** — tier definition includes 'durability invariants'; `put_writes` is the durability contract that all checkpoint backends (sqlite, postgres, memory) implement; module-decomposition CRITICAL classification. **`core::events` HIGH** — BC-2.06.001 behavioral contract governs StreamEvent variant set and field schema; parallel to `core::message` (HIGH) as a central data-model contract for its protocol. **`graph::definition` HIGH** — StateGraph builder (node/edge registration, conditional routing) is core business logic foundational to all graph execution; SS-02 scope. **`server::streaming` HIGH** — SSE streaming endpoint, NE-13 same-engine constraint, consistent with `server::handlers` and `server::security` HIGH tier. **`server::stores` HIGH** — IdempotencyStore/RateLimitStore/RunStore Boundary trait seams, NE-08 constraint, consistent with server layer HIGH profile. **MEDIUM ×13** — all are supporting correctness-required execution-logic modules with no security-boundary role and no Kani VP; tier consistent with `sandbox::policy`, `core::retry`, `mcp::client`, `graph::event_emitter`, `splitters::recursive` precedents.
>
> **F-P172b-15 elevation (v2.1):** `mcp::ingress` raised MEDIUM → HIGH. Rationale: `mcp::ingress` and `graph::provenance` are both DI-012 guardrail-dispatch Boundary modules implementing the same pattern (pure untrusted-ingress routing + effectful `GuardrailHook` dispatch). `graph::provenance` was classified HIGH at v2.0. `mcp::ingress` handles the EXTERNAL untrusted-input side (BC-2.09.003) — the entry point for tool invocations arriving from MCP clients. Under the Production-Grade Default, the external-ingress side must not have a lower kill-rate target than the internal guardrail consumer at the same protocol seam. No justification exists for the asymmetry.
>
> **Iron Law gap — eval::judge (v2.1):** `pregolya-standard-tests::eval::judge` added as MEDIUM module row. The `eval.judge_infra_error` structured event in observability.md identifies this module as the emitter (linkage restored in observability.md §Catalog via FIX-BURST-276-WAVE-C1, a concurrent PO fix; the emitter linkage was not yet present in observability.md when this Iron Law entry was added in v2.1 — see v2.1 changelog correction in v2.3). BC-2.08.008 scopes the judge score aggregation behavior (Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome, NE-15). The module executes LLM judge calls (async I/O, Effectful Shell), has a behavioral contract, and emits structured events — all three criteria that require an Iron Law entry in module-decomposition.md (see also purity-boundary-map.md Effectful Shell row added in same burst). The pre-existing `pregolya-standard-tests` crate-level row remains as a crate-level annotation; `eval::judge` is the module-level row that satisfies Iron Law for the specific module with observable behavior.
