---
document_type: architecture-section
level: L3
section: verification-coverage-matrix
version: "2.8"
status: active
producer: architect
timestamp: 2026-07-26T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/module-criticality.md
input-hash: "pending-FIX-BURST-275"
traces_to: ARCH-INDEX.md
changelog:
  - "2.8 (FIX-BURST-275-REOPENED/Defect-2-mirror/2026-07-26): Mirror module-criticality.md v2.2 additions — add 3 Per-Module Coverage Status rows: `macros::tool` HIGH (ferrochain-macros; compile-time TokenStream→TokenStream proc-macro; no Kani VP; BC-2.08.010), `macros::entrypoint` HIGH (ferrochain-macros; compile-time proc-macro; no Kani VP; BC-2.08.011), `macros::task` HIGH (ferrochain-macros; compile-time proc-macro; no Kani VP; BC-2.08.012). Coverage-by-Criticality-Tier: HIGH 25 → 28. Per-module count 74 → 77. VP-to-Module table and VP totals unchanged (no new VPs; macros proc-macro modules have no Kani VP targets — compile-time code generation is integration-tested via expansion correctness tests)."
  - "2.7 (FIX-BURST-275/F-P172b-01+15+Iron-Law/2026-07-26): Mirror module-criticality.md v2.1 additions. F-P172b-01 mirror — add 7 Per-Module Coverage Status rows: `openai::embeddings` HIGH (ferrochain-openai, DI-009/DI-010, Integration DTU), `ollama::embeddings` HIGH (ferrochain-ollama, DI-009, Integration), `vectorstores::store` MEDIUM (ferrochain-vectorstores, Integration), `vectorstores::retriever` MEDIUM (ferrochain-vectorstores, Integration), `vectorstores::memory` MEDIUM (ferrochain-vectorstores, Unit+Integration), `tools::fs` MEDIUM (ferrochain-tools, Integration), `tools::search` MEDIUM (ferrochain-tools, Integration). F-P172b-15 mirror — update mcp::ingress Notes to reflect HIGH tier elevation (untrusted-ingress; BC-2.09.003; parity with graph::provenance HIGH). Iron Law mirror — add `eval::judge` MEDIUM row (ferrochain-standard-tests; async LLM judge; Integration DTU; BC-2.08.013/014). Coverage-by-Criticality-Tier: HIGH 22 → 25 (+openai::embeddings, +ollama::embeddings, mcp::ingress elevation); MEDIUM 30 → 35 (+vectorstores::store/retriever/memory, +tools::fs/search, +eval::judge, -mcp::ingress). Per-module count 66 → 74. VP-to-Module table and VP totals unchanged (no new VPs)."
  - "2.6 (FIX-BURST-274/module-universe-sweep/2026-07-26): Module-universe sweep mirror — add 18 Per-Module Coverage Status rows matching module-criticality.md v2.0 additions. CRITICAL +1: checkpoint::saver. HIGH +4: core::events, graph::definition, server::streaming, server::stores. MEDIUM +13: core::config, checkpoint::memory, checkpoint::postgres, server::cron, sandbox::container, sandbox::seatbelt, sandbox::process, splitters::parity, mcp::discovery, mcp::ingress, memory::sqlite, memory::in_memory, memory::search. Coverage-by-Criticality-Tier: CRITICAL 11→12, HIGH 18→22, MEDIUM 17→30. Per-module count 48→66. VP-to-Module table and VP totals unchanged (no new VPs)."
  - "2.5 (FIX-BURST-274/D21-definitions-sweep/2026-07-26): D21 Pure Core sweep — add 4 missing MEDIUM rows to match module-criticality.md v1.9 additions (core::retriever, prompts::template, prompts::chat_template, prompts::few_shot). Per-module count 44→48; Coverage-by-Criticality-Tier MEDIUM 13→17. Per-Module Coverage Status header updated."
  - "2.4 (FIX-BURST-273/gate-25-32/2026-07-25): Add tools::config MEDIUM row (ferrochain-tools SS-23) — gate #25 Part B/C sibling propagation; no Kani VP (VP-013 Kani P1 targets check_risk_floor in tools::shell); Integration: yes (construction-time validation tests for override_risk / ADR-020 Decision 3 / BC-2.23.005). Per-module count 43→44; Coverage-by-Criticality-Tier MEDIUM 12→13. Header note updated."
  - "2.3 (FIX-BURST-252/2026-07-24): Input-hash cascade refresh — module-decomposition.md v1.22→v1.23 (FIX-BURST-252 F-P151-02+05: fraction f32→f64 in core::budget, CompactionSummary flat fields). No VP-to-Module table or coverage-status changes (core-budget VP-012 mapping, tool, phase, priority, and Notes wording all unchanged — Notes 'OnWatermark arithmetic; Kani P1 (BC-2.10.005)' contains no predicate formula or type annotation requiring update)."
  - "2.2 (FIX-BURST-250/F-P149-03/2026-07-24): Add missing red_gate label to three Per-Module rows where VP is red_gate:true (VP-004/005/006) for parity with VP-009/VP-010 rows. injection_guard Notes: 'Kani P1 (BC-2.18.004)' → 'Kani P1 red_gate (BC-2.18.004)'. mcp-adapter Notes: 'ToolException fidelity' → 'ToolException type-identity; integration red_gate (BC-2.09.004)'. mcp-client Notes: 'Red Gate BCs' → 'integration red_gate (BC-2.09.005); no-live-connections'. Verified: VP-009 'Kani P0 red_gate (BC-2.21.003)' and VP-010 'Kani P0 red_gate (BC-2.19.005)' already correct. All 8 red_gate:false VP rows confirmed clean (no red_gate label)."
  - "2.1 (FIX-BURST-248/F-P147-01/2026-07-24): Remove stale 'red_gate' label from hitl row Notes — BC-2.05.007 is NOT Red-Gated (product-owner authority, burst-231; ADR-018 Decision 3 has no compile-and-fail mandate). Notes changed from 'Kani P0 red_gate (BC-2.05.007)' to 'Kani P0 (BC-2.05.007)'. No VP table, totals, or criticality tier changes."
  - "2.0 (burst-232/2026-07-22): D23 VP layer — add VP-011..013 to VP-to-Module table; update hitl row (VP-011 Kani P0); add core-budget row (VP-012 Kani P1); add tools-shell row (VP-013 Kani P1). Totals: 10→13 VPs, Kani 6→9. Coverage-by-Criticality-Tier: CRITICAL Kani VPs 5→6 (+VP-011; hitl is CRITICAL per module-criticality.md); HIGH Kani VPs 1→3 (+VP-012 core-budget, +VP-013 tools-shell; ferrochain-tools criticality tier deferred to module-criticality.md D23 content authoring burst). Per-module count 41→43 (+2 new rows). Input-hash refresh pending VP-INDEX.md v1.5."
  - "1.9 (burst-229/2026-07-22): Input-hash cascade refresh — module-decomposition.md v1.15 changed (D23: SS-23 ferrochain-tools + graph::hitl/budget D23 types) + module-criticality.md v1.5 cascade (ARCH-INDEX.md v1.6 + module-decomposition.md v1.15). Hash: 52d04b1 → 06eaf17. No VP table changes (D23 VP candidates not yet minted; pending PO BC authoring)."
  - "1.8 (burst-224/2026-07-21): Fix Coverage by Criticality Tier MEDIUM count: 11 → 12 (vectorstores-mmr reclassified CRITICAL → MEDIUM when VP-009 moved to vectorstores-similarity; F-P129-11 reclassification, not an addition). Fix tier membership description in header note. Refresh input-hash cascade: 8bc637f → 78d9c11 (module-decomposition.md v1.12) → c766473 final (module-criticality.md v1.4 D21+burst-224 backfill in same burst)."
  - "1.7 (burst-224/2026-07-21): F-P129-11 — VP-009 module renamed vectorstores-mmr → vectorstores-similarity in VP-to-Module table; Per-Module Coverage Status split into vectorstores-similarity (VP-009 Kani P0) + vectorstores-mmr (no Kani VP, caller of similarity). Totals unchanged (10 VPs, Kani 6). Propagates VP-INDEX v1.3 + module-decomposition v1.12."
  - "1.6 (burst-223/2026-07-21): D21 VP layer — add VP-006..010 to VP-to-Module table; add SS-18..22 module rows to Per-Module Coverage Status; update Totals 5→10 VPs, Kani 3→6, proptest 0→2; update Coverage by Criticality Tier to reflect new D21 modules."
  - "1.5 (provenance-fix-169/2026-07-17): cascade input-hash recompute (VP-INDEX.md v1.1 content change — column reorder for hook compatibility)."
  - "1.4 (provenance-fix-169/2026-07-17): cascade input-hash recompute (module-decomposition.md v1.8 content change); add [Section Content] template compliance fix."
  - "1.3 (gate #25 backfill + D20/CAP-021): F-backfill add write-guard enforcement HIGH row missing since ADR-012 D20 burst (matrix header was 33, module-criticality was 34 — drift corrected); add mcp-server MEDIUM row (CAP-021); header 33→35 (CRITICAL 9 / HIGH 13 / MEDIUM 11 / LOW 2); Coverage-by-Tier HIGH 12→13, MEDIUM 10→11."
  - "1.2 (ADV-P1D-PASS-45): F-P45-01 correct retry crate from ferrochain-graph to ferrochain-core per module-criticality.md line 64 (SS-16); relocate row from ferrochain-graph cluster into ferrochain-core cluster. Full 33-row crate-ownership diff against module-criticality.md — no other mismatches found."
  - "1.1 (ADV-P1D-PASS-37): F-P37-02 correct Coverage by Criticality Tier summary to CRITICAL 9 / HIGH 12 / MEDIUM 10 / LOW 2 = 33 (was stale 6/7/5/2=20); complete Per-Module Coverage Status table to all 33 architecture modules (was 27); added rows for ferrochain-macros (HIGH), sandbox-wasm (MEDIUM), ferrochain-standard-tests (MEDIUM), memory-store (MEDIUM), xtask (LOW), ferrochain-community (LOW)."
  - "1.0 (initial): base verification coverage matrix authored."
---

# Verification Coverage Matrix: ferrochain

## [Section Content]

> **VP-INDEX.md is the authoritative VP catalog.** This matrix derives from it.
> Arithmetic invariant: VP total (13) = P0 (6) + P1 (7) = Kani (9) + proptest (2) + integration (2). Status is updated per gate.

## VP-to-Module Mapping

| VP | Title | Module | Crate | Tool | BC Anchor | Phase | Status |
|----|-------|--------|-------|------|-----------|-------|--------|
| VP-001 | BSP Super-Step Determinism | bsp-engine (reducer stage) | ferrochain-graph | Kani | BC-2.03.001 | 6 | draft |
| VP-002 | Session Triple-Address Uniqueness | session-index | ferrochain-checkpoint | Kani | BC-2.04.006 | 6 | draft |
| VP-003 | Workspace Path Confinement | path-guard | ferrochain-sandbox | Kani | BC-2.13.004 | 6 | draft |
| VP-004 | MCP ToolException Type-Identity Preservation | mcp-adapter | ferrochain-mcp | integration | BC-2.09.004 | 3 | draft |
| VP-005 | MultiServerMcpClient Holds No Live Connections | mcp-client | ferrochain-mcp | integration | BC-2.09.005 | 3 | draft |
| VP-006 | injection_guard Fail-Closed | injection_guard | ferrochain-prompts | Kani | BC-2.18.004 | 6 | draft |
| VP-007 | LcSerializable Round-Trip | serializable | ferrochain-core | proptest | BC-2.19.001 | 3 | draft |
| VP-008 | Embeddings Dimensionality Contract | embeddings | ferrochain-core | proptest | BC-2.22.001 | 3 | draft |
| VP-009 | Zero-Norm Cosine Guard | vectorstores-similarity | ferrochain-vectorstores | Kani | BC-2.21.003 | 6 | draft |
| VP-010 | Reviver Allowlist Containment | serializable-reviver | ferrochain-core | Kani | BC-2.19.005 | 6 | draft |
| VP-011 | PreToolCallHook Fail-Closed | hitl | ferrochain-graph | Kani | BC-2.05.007 | 6 | draft |
| VP-012 | OnWatermark Arithmetic | core-budget | ferrochain-core | Kani | BC-2.10.005 | 6 | draft |
| VP-013 | BashTool Risk Floor | tools-shell | ferrochain-tools | Kani | BC-2.23.005 | 6 | draft |

**Totals: 13 VPs | Kani: 9 | proptest: 2 | fuzz: 0 | integration: 2**

## Per-Module Coverage Status

> This table covers all 77 architecture modules (74 from FIX-BURST-275 Wave B + 3 FIX-BURST-275-Reopened additions: macros::tool, macros::entrypoint, macros::task — all HIGH, ferrochain-macros).
> Tier groupings: CRITICAL 12 / HIGH 28 / MEDIUM 35 / LOW 2.

| Module | Crate | Kani | proptest | fuzz | Integration | Notes |
|--------|-------|------|---------|------|-------------|-------|
| bsp-engine | ferrochain-graph | VP-001 | yes (BC-2.03.003) | yes (BC-2.17.002) | yes | Core VP target |
| channels | ferrochain-graph | — | yes (BC-2.02.002) | — | yes | Reducer invariants via proptest |
| hitl | ferrochain-graph | VP-011 | — | — | yes | D23/SS-05; PreToolCallHook fail-closed; Kani P0 (BC-2.05.007) |
| scheduler | ferrochain-graph | — | — | — | yes | Pending ADR-001 |
| budget | ferrochain-graph | — | yes | — | yes | EvidenceJournal ordering |
| provenance | ferrochain-graph | — | — | — | yes | Hook dispatch |
| event_emitter | ferrochain-graph | — | — | — | yes | Streaming/unary equivalence |
| session-index | ferrochain-checkpoint | VP-002 | yes | — | yes | Core VP target |
| clock | ferrochain-checkpoint | — | yes | — | yes | Monotonic property |
| lineage | ferrochain-checkpoint | — | — | — | yes | Fork pointer |
| encryption | ferrochain-checkpoint | — | — | — | yes | Payload coverage |
| sqlite | ferrochain-checkpoint | — | — | yes (BC-2.17.002) | yes | Round-trip fuzz |
| path-guard | ferrochain-sandbox | VP-003 | — | — | yes | Core VP target |
| sandbox-policy | ferrochain-sandbox | — | — | — | yes | Err(PolicyNotEnforceable) |
| message | ferrochain-core | — | yes | — | yes | ContentBlock invariants |
| error | ferrochain-core | — | — | — | yes | RFC-7807 emission |
| credentials | ferrochain-core | — | — | — | yes | Redacted Debug |
| runnable | ferrochain-core | — | yes | — | yes | Pipe associativity |
| retry | ferrochain-core | — | yes | — | yes | Policy termination |
| server handlers | ferrochain-server | — | — | — | yes | CRUD lifecycle |
| server security | ferrochain-server | — | — | — | yes | SecurityConfig defaults |
| recursive splitter | ferrochain-splitters | — | yes | — | yes | Code-point boundaries |
| openai | ferrochain-openai | — | — | — | yes | Conformance suite |
| anthropic | ferrochain-anthropic | — | — | — | yes | Conformance suite |
| ollama | ferrochain-ollama | — | — | — | yes | Conformance suite |
| mcp client | ferrochain-mcp | — | — | — | yes | integration red_gate (BC-2.09.005); no-live-connections |
| mcp adapter | ferrochain-mcp | — | — | — | yes | ToolException type-identity; integration red_gate (BC-2.09.004) |
| mcp server | ferrochain-mcp | — | — | — | yes | Server-side tool exposure + inbound dispatch (CAP-021) |
| ferrochain-macros | ferrochain-macros | — | — | — | yes | crate-level roll-up; `#[tool]`/`#[entrypoint]`/`#[task]` expansion correctness |
| macros::tool | ferrochain-macros | — | — | — | yes | HIGH; `#[tool]` proc-macro ToolDefinition generation; compile-time TokenStream expansion; integration-tested via expansion correctness; BC-2.08.010 |
| macros::entrypoint | ferrochain-macros | — | — | — | yes | HIGH; `#[entrypoint]` proc-macro START-edge wiring; compile-time TokenStream expansion; integration-tested; BC-2.08.011 |
| macros::task | ferrochain-macros | — | — | — | yes | HIGH; `#[task]` proc-macro task-registration boilerplate; compile-time TokenStream expansion; integration-tested; BC-2.08.012 |
| sandbox-wasm | ferrochain-sandbox | — | — | — | yes | WASM execution backend |
| ferrochain-standard-tests | ferrochain-standard-tests | — | — | — | yes | Shared conformance harness; exercised via provider integrations |
| memory-store | ferrochain-memory | — | yes | — | yes | KV + vector ops; GDPR erasure protocol |
| write-guard enforcement | ferrochain-memory | — | — | — | yes | `WriteGuardDecision` enforcement; injection scanning dispatch (D20/ADR-012) |
| xtask | xtask | — | — | — | — | CI lint gates only; advisory ≥70% |
| ferrochain-community | ferrochain-community | — | — | — | — | Post-v1 placeholder; not in-tree at v1 |
| injection_guard | ferrochain-prompts | VP-006 | — | — | yes | D21/SS-18; prompt injection safety; Kani P1 red_gate (BC-2.18.004) |
| serializable | ferrochain-core | — | VP-007 | — | yes | D21/SS-19; LcSerializable round-trip; proptest P1 (BC-2.19.001) |
| serializable-reviver | ferrochain-core | VP-010 | — | — | yes | D21/SS-19; allowlist containment; Kani P0 red_gate (BC-2.19.005) |
| vectorstores-similarity | ferrochain-vectorstores | VP-009 | — | — | yes | D21/SS-21; shared cosine_similarity primitive; zero-norm guard; Kani P0 red_gate (BC-2.21.003) |
| vectorstores-mmr | ferrochain-vectorstores | — | — | — | yes | D21/SS-21; MMR selection algorithm; calls vectorstores::similarity::cosine_similarity |
| embeddings | ferrochain-core | — | VP-008 | — | yes | D21/SS-22; dimensionality contract; proptest P1 (BC-2.22.001) |
| core-budget | ferrochain-core | VP-012 | — | — | yes | D23/SS-10; OnWatermark arithmetic; Kani P1 (BC-2.10.005) |
| tools-shell | ferrochain-tools | VP-013 | — | — | yes | D23/SS-23; BashTool risk floor; Kani P1 (BC-2.23.005) |
| tools::config | ferrochain-tools | — | — | — | yes | D23/SS-23; ToolConfig risk-floor validator; pure construction-time validation (ADR-020 Decision 3 / BC-2.23.005) |
| core::retriever | ferrochain-core | — | — | — | yes | D21/SS-20; `rag_ingress` async guardrail routing gate; DI-012 RAGRetrieval boundary enforcement (ADR-014 Decision 6) |
| prompts::template | ferrochain-prompts | — | — | — | yes | D21/SS-18; f-string rendering engine; variable extraction and substitution (ADR-015) |
| prompts::chat_template | ferrochain-prompts | — | — | — | yes | D21/SS-18; multi-message template construction with MessageProvenance (ADR-015) |
| prompts::few_shot | ferrochain-prompts | — | — | — | yes | D21/SS-18; FewShotPromptTemplate assembly; snapshot-frozen golden fixture tests (ADR-015) |
| checkpoint::saver | ferrochain-checkpoint | — | — | — | yes | CheckpointSaver `put_writes` durability contract; integration-tested via backend implementations (sqlite/postgres/memory) |
| core::events | ferrochain-core | — | — | — | yes | StreamEvent taxonomy; BC-2.06.001; event construction tested in graph scheduler integration suite |
| graph::definition | ferrochain-graph | — | yes | — | yes | StateGraph builder; node/edge registration; property tests for topology invariants |
| server::streaming | ferrochain-server | — | — | — | yes | SSE streaming endpoint; same engine as unary (NE-13); integration + soak |
| server::stores | ferrochain-server | — | — | — | yes | IdempotencyStore/RateLimitStore/RunStore trait seams (NE-08); integration via server handler tests |
| core::config | ferrochain-core | — | — | — | yes | RunnableConfig/ChatConfig construction; env var reads; unit tests |
| checkpoint::memory | ferrochain-checkpoint | — | — | — | yes | In-memory checkpoint backend; deterministic HashMap; unit tests |
| checkpoint::postgres | ferrochain-checkpoint | — | — | — | yes | PostgreSQL checkpoint backend; integration tests (stretch feature) |
| server::cron | ferrochain-server | — | — | — | yes | CronSchedule parsing and proactive run triggering; integration tests |
| sandbox::container | ferrochain-sandbox | — | — | — | yes | Container execution backend (sandbox-container feature); integration tests |
| sandbox::seatbelt | ferrochain-sandbox | — | — | — | yes | macOS Seatbelt deny-by-default profile (NE-16); integration tests |
| sandbox::process | ferrochain-sandbox | — | — | — | yes | ProcessBackend OS subprocess execution; integration tests (BC-2.13.002) |
| splitters::parity | ferrochain-splitters | — | — | — | yes | Golden-vector parity tests vs Python reference (R8/BC-2.07.002); unit tests |
| mcp::discovery | ferrochain-mcp | — | — | — | yes | Tool discovery from MCP server at runtime (BC-2.09.001); integration tests |
| mcp::ingress | ferrochain-mcp | — | — | — | yes | HIGH tier (F-P172b-15 elevation); untrusted-ingress routing; DI-012 guardrail seam; external-input boundary (BC-2.09.003); parity with graph::provenance HIGH; unit + integration tests |
| memory::sqlite | ferrochain-memory | — | — | — | yes | SQLite durable backend for long-horizon memory; integration tests |
| memory::in_memory | ferrochain-memory | — | — | — | yes | Ephemeral in-memory backend for test/dev; unit tests |
| memory::search | ferrochain-memory | — | — | — | yes | Keyword, vector, and hybrid search; integration tests |
| openai::embeddings | ferrochain-openai | — | — | — | yes | HIGH tier; credential-bearing HTTP surface (DI-009/DI-010); EmbeddingsOpenAI impl; integration (DTU) |
| ollama::embeddings | ferrochain-ollama | — | — | — | yes | HIGH tier; Embeddings conformance contract; EmbeddingsOllama impl; integration |
| vectorstores::store | ferrochain-vectorstores | — | — | — | yes | VectorStore trait dispatch; VectorStoreFactory; integration |
| vectorstores::retriever | ferrochain-vectorstores | — | — | — | yes | VectorStoreRetriever bridge; Retriever impl; integration |
| vectorstores::memory | ferrochain-vectorstores | — | yes | — | yes | In-memory VectorStore backend; RwLock interior mutability; unit + integration |
| tools::fs | ferrochain-tools | — | — | — | yes | OS filesystem I/O tools; path-guard consumer; integration |
| tools::search | ferrochain-tools | — | — | — | yes | In-process regex search; directory traversal; path-guard consumer; integration |
| eval::judge | ferrochain-standard-tests | — | — | — | yes | LLM judge execution; emits eval.judge_infra_error event (observability.md); BC-2.08.013/014; integration (DTU) |

## Coverage by Criticality Tier

| Tier | Modules | Kani VPs | proptest | fuzz | Kill Rate Target |
|------|---------|---------|---------|------|-----------------|
| CRITICAL | 12 | 6 (VP-001, VP-002, VP-003, VP-009, VP-010, VP-011) | all | subset | ≥ 95% |
| HIGH | 28 | 3 (VP-006, VP-012, VP-013) | most + VP-007, VP-008 | subset | ≥ 90% |
| MEDIUM | 35 | 0 | some | — | ≥ 80% |
| LOW | 2 | 0 | — | — | n/a (xtask and ferrochain-community excluded from cargo-mutants per tooling-selection.md; advisory only) |

## Mutation Kill Rate Gates (cargo-mutants)

Kill rate gates are Phase-5 adversarial gates. Phase-3 per-story gates apply to CRITICAL modules only.

| Tier | Gate | Phase |
|------|------|-------|
| CRITICAL | ≥ 95% | Phase 3 (per story) + Phase 5 |
| HIGH | ≥ 90% | Phase 5 |
| MEDIUM | ≥ 80% | Phase 5 |
| LOW | ≥ 70% | Phase 5 advisory |
