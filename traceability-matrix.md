---
document_type: traceability-matrix
level: governance
version: "1.5"
status: active
producer: spec-steward
timestamp: 2026-09-18T00:00:00Z
phase: 3
traces_to: .factory/specs/behavioral-contracts/BC-INDEX.md
inputs:
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/stories/STORY-INDEX.md
input-hash: "43b7464"
baseline_event: "D-364/2026-09-17 — BC-INDEX §Changelog (D-364 SYS 14th-category addition). VP-INDEX §Changelog unchanged. STORY-INDEX §Changelog unchanged"
changelog:
  - "1.5 (D-364/2026-09-17, state-manager): input-hash recomputed after BC-INDEX §Changelog bump (D-364 SYS 14th-category fix-cascade). BC-INDEX is an input per §inputs list; combined three-input hash updated c14c505→43b7464. VP-INDEX §Changelog and STORY-INDEX §Changelog UNCHANGED. Census UNCHANGED: BC 149 / VP 43 / stories 53."
  - "1.4 (D-362/2026-09-18, spec-steward+state-manager): Corrective fix-burst — SS-24 VP over-count corrected: §VP-2.24 section heading '21 VPs' → '20 VPs'; §VP-Priority-Distribution SS-24 row '(21 VPs) | 21' → '(20 VPs) | 20'. Actual VP-2.24 table contains exactly 20 rows (VP-2.24.001-A..VP-2.24.008-B). Post-fix §VP-Priority-Distribution Total=43 (P0=7, P1=36) confirmed consistent with §VP-Status-Summary. Input-hash recomputed (c14c505) after genuine F1 STORY-INDEX body edit (S-6.01 Target-Crate fuzz token actually removed; D-361/v1.3 hash 1acd327 was based on STORY-INDEX with fuzz token still present — paper-fix recompute; D-362 recompute reflects genuine content change). STORY-INDEX now v2.01. Census UNCHANGED: BC 149 / VP 43 / stories 53."
  - "1.3 (D-361/2026-09-18, state-manager): input-hash recomputed post STORY-INDEX §Changelog D-361/C1 edit (fuzz-crate removal from S-6.01 §Wave-6-Story-Inventory Target-Crate cell). STORY-INDEX is an input per §inputs list; combined three-input hash updated to 1acd327. No VP/BC/story matrix content changed. Census UNCHANGED: BC 149 / VP 43 / stories 53."
  - "1.2 (D-361/2026-09-17, spec-steward): Confirmation-pass corrections — VP Traceability Chains table transposition errors fixed per VP-INDEX §VP Catalog (source of truth): VP-006 priority P0→P1; VP-007 priority/tool P0/Kani→P1/proptest; VP-009 priority/tool P1/proptest→P0/Kani; VP-010 priority/tool P1/proptest→P0/Kani; VP-2.24.002-A tool Kani→proptest. Forward Traceability VP-006 label P0→P1. VP Priority Distribution by Subsystem SS-16/17/18/other row corrected (P0 VP-009+VP-010; P1 VP-006+VP-006-B+VP-007+VP-008). P0=7/P1=36 aggregate confirmed correct after corrections. input-hash marked needs-refresh (state-manager to recompute on commit)."
  - "1.1 (D-360/2026-09-17, spec-steward): Input-hash refreshed post pre-Wave-1 reconciliation burst (7535fa6→c91d879). BC-INDEX §Changelog bumped (v4.60→v4.61; CV-1 Red-Gate annotation; CV-2 VP body-file count correction). STORY-INDEX §Changelog bumped (v1.98→v1.99; SS-2 SS-24 annotation; SS-3 BC-2.12.003 +S-console-10). VP-INDEX §Changelog (v1.60) unchanged. Census UNCHANGED: BC 149 / VP 43 / stories 53."
  - "1.0 (D-359/2026-09-17, spec-steward): Initial baseline traceability aggregation. Sourced from BC-INDEX §Changelog (v4.60), VP-INDEX §Changelog (v1.60), STORY-INDEX §Changelog (v1.98). Census: BC 149 / VP 43 / stories 53. Code drift: N/A (Phase-3 not started)."
---

# Traceability Matrix — pregolya

> **Purpose:** Aggregated BC → Story → VP → (proof harness / AC) traceability chain. This file is the spec-steward's governance-level view. Authoritative detail lives in the INDEX files it references — this matrix does not duplicate or replace them.
>
> **Authoritative sources:**
> - BC-to-Story links: `specs/behavioral-contracts/BC-INDEX.md` §BC-to-Story Coverage Map (source of truth for all 149 BC → story assignments)
> - VP-to-Story links: `stories/STORY-INDEX.md` §VP-to-Story Anchor Map (source of truth for all 43 VP → story assignments)
> - VP-to-BC links: `specs/verification-properties/VP-INDEX.md` §VP Catalog `bc_anchor` column (source of truth for VP → BC clause traceability)
>
> **Baseline census (D-359 / 2026-09-17):** BC 149 / VP 43 / EC 147 / TV 844 / stories 53 / pts 377 / ADR 31 / SS 24 / crates 22
>
> **TD-VSDD-091:** All citations use behavioral-anchor / ID form (BC-S.SS.NNN, VP-NNN, clause tags {PC-NNN}/{INV-NNN}). No file:line citations.

---

## Chain Coverage Census

| Layer | Count | Coverage | Status |
|-------|-------|----------|--------|
| L3 Behavioral Contracts | 149 | 149/149 (100%) stories assigned | Phase-2 CLOSED |
| L4 Verification Properties | 43 | 43/43 VP → BC anchored | Phase-2 CLOSED; Phase-6 not started |
| VP → Story links | 43 VP → 25 stories | 25 stories carry ≥1 VP anchor | STORY-INDEX §VP-to-Story Anchor Map |
| VP → Proof harness | 43 VP stubs authored | 0 harnesses executed (Phase-6) | draft status |
| BC → AC (test) links | 149 BC | All BCs traced via AC tables in story files | Phase-2 CLOSED |
| Code implementation | 0 / 53 stories | Phase-3 not started | N/A |

---

## VP Traceability Chains

The VP-INDEX §VP Catalog (source of truth) records the full bc_anchor, module, crate, and harness_fn for each VP. This table aggregates the chain summary; see VP-INDEX for per-VP property statements.

### VP-001 through VP-020 (Core + Praxist Layer)

| VP | Priority | Tool | BC Anchor | Module | Story |
|----|----------|------|-----------|--------|-------|
| VP-001 | P0 | Kani | VP-INDEX §bc_anchor | graph::bsp_engine | VP-INDEX §VP Catalog |
| VP-002 | P0 | Kani | VP-INDEX §bc_anchor | checkpoint::session_index | VP-INDEX §VP Catalog |
| VP-003 | P0 | Kani | BC-2.13.004 | sandbox::path_guard | VP-INDEX §VP Catalog |
| VP-004 | P1 | integration | VP-INDEX §bc_anchor | mcp::exception | VP-INDEX §VP Catalog |
| VP-005 | P1 | integration | VP-INDEX §bc_anchor | mcp::client | VP-INDEX §VP Catalog |
| VP-006 | P1 | Kani | BC-2.18.004 | prompts::injection_guard | S-2.05 |
| VP-006-B | P1 | proptest | BC-2.18.004 {PC-005} | prompts::injection_guard | S-2.05 |
| VP-007 | P1 | proptest | VP-INDEX §bc_anchor | core::serializable | VP-INDEX §VP Catalog |
| VP-008 | P1 | proptest | VP-INDEX §bc_anchor | core::embeddings | VP-INDEX §VP Catalog |
| VP-009 | P0 | Kani | VP-INDEX §bc_anchor | vectorstores::similarity | VP-INDEX §VP Catalog |
| VP-010 | P0 | Kani | VP-INDEX §bc_anchor | core::serializable | VP-INDEX §VP Catalog |
| VP-011 | P0 | Kani | BC-2.05.007 | graph::hitl | VP-INDEX §VP Catalog |
| VP-012 | P1 | Kani | BC-2.10.005 | core::budget | VP-INDEX §VP Catalog |
| VP-013 | P1 | Kani | BC-2.23.005 | tools::shell | VP-INDEX §VP Catalog |
| VP-014 | P1 | proptest | BC-2.01.005 + BC-2.01.006 | core::runnable::parallel | VP-INDEX §VP Catalog |
| VP-015 | P1 | unit | BC-2.09.007 {INV-003} | mcp::sanitize | S-2.11 |
| VP-016 | P1 | proptest | BC-2.09.008 {INV-001} | mcp::graph_tool | S-2.11 |
| VP-017 | P1 | proptest | BC-2.02.007 + BC-2.02.008 | graph::channels | S-1.28 |
| VP-018 | P1 | proptest | BC-2.04.011 {INV-001} | checkpoint::trajectory | S-2.12 |
| VP-019 | P1 | integration | BC-2.04.011 {INV-003} | checkpoint::trajectory | S-2.12 |
| VP-020 | P1 | proptest | BC-2.02.009 {INV-001}+{INV-002} | graph::channels | S-1.28 |

### VP-2.11.007-A/B (SS-11 GuardrailJournal)

| VP | Priority | Tool | BC Anchor | Module | Story |
|----|----------|------|-----------|--------|-------|
| VP-2.11.007-A | P0 | integration | BC-2.11.007 {INV-002} | graph::provenance | S-1.29 |
| VP-2.11.007-B | P1 | integration | BC-2.11.007 {INV-005} + BC-2.04.007 {INV-006} | checkpoint::serializer | S-1.29 |

### VP-2.24.001-A through VP-2.24.008-B (SS-24 Developer Console, 20 VPs)

| VP | Priority | Tool | BC Anchor | Module | Story |
|----|----------|------|-----------|--------|-------|
| VP-2.24.001-A | P1 | unit | BC-2.24.001 | spa_components::run_inspector? | S-console-01 |
| VP-2.24.001-B | P1 | unit | BC-2.24.001 | spa_components::run_inspector? | S-console-01 |
| VP-2.24.001-C | P1 | compile-fail | BC-2.24.001 | spa_components::run_inspector? | S-console-01 |
| VP-2.24.002-A | P1 | proptest | BC-2.24.002 | console::ring_buffer | S-console-02 |
| VP-2.24.002-B | P1 | proptest | BC-2.24.002 | console::ring_buffer | S-console-02 |
| VP-2.24.002-C | P1 | integration | BC-2.24.002 | server::debug_routes | S-console-03 |
| VP-2.24.002-D | P1 | unit | BC-2.24.002 | console::span_exporter | S-console-02/03 |
| VP-2.24.003-A | P1 | unit | BC-2.24.003 | graph::descriptor | S-console-04 |
| VP-2.24.003-B | P1 | Kani | BC-2.24.003 | graph::descriptor | S-console-04 |
| VP-2.24.003-C | P1 | unit | BC-2.24.003 | graph::descriptor | S-console-04 |
| VP-2.24.004-A | P1 | integration | BC-2.24.004 | spa_components::run_inspector | S-console-05/06 |
| VP-2.24.004-B | P1 | integration | BC-2.24.004 | spa_components::run_inspector | S-console-05/06 |
| VP-2.24.005-A | P1 | integration | BC-2.24.005 {INV-001} | spa_components::checkpoint_panel | S-console-07 |
| VP-2.24.005-B | P1 | integration | BC-2.24.005 {INV-002} | spa_components::checkpoint_panel | S-console-07 |
| VP-2.24.006-A | P1 | integration | BC-2.24.006 {INV-001} | spa_components::hitl_panel | S-console-08 |
| VP-2.24.006-B | P1 | integration | BC-2.24.006 {INV-001} | spa_components::hitl_panel | S-console-08 |
| VP-2.24.007-A | P1 | unit | BC-2.24.007 | spa_components::budget_panel | S-console-09 |
| VP-2.24.007-B | P1 | integration | BC-2.24.007 | spa_components::budget_panel | S-console-09 |
| VP-2.24.008-A | P1 | integration | BC-2.24.008 | spa_components::guardrail_panel | S-console-10 |
| VP-2.24.008-B | P1 | unit | BC-2.24.008 | spa_components::guardrail_panel | S-console-10 |

> For VP-2.24.* DI anchors, module/crate details, and harness_fn values see VP-INDEX §VP Catalog rows. SPA component VPs use `spa_components::<component>` module convention (DC-07). Crate: pregolya-console for console-namespace; pregolya-graph / pregolya-server for non-console VPs per VP-INDEX §VP Catalog.

---

## BC → Story Coverage Summary

BC-to-Story assignments live in `specs/behavioral-contracts/BC-INDEX.md` §BC-to-Story Coverage Map (24 subsystem sections, SS-01 through SS-24). All 149 BCs are assigned to at least one story. Representative confirmed chains from INDEX changelogs:

| BC (Representative) | Subsystem | Story | VP |
|--------------------|-----------|-------|----|
| BC-2.02.007 LedgerChannel Dedup-Idempotent Append | SS-02 | S-1.28 | VP-017 |
| BC-2.02.008 LedgerChannel First-Appearance Ordering | SS-02 | S-1.28 | VP-017 |
| BC-2.02.009 PromoteRetireChannel Promote/Retire Lifecycle | SS-02 | S-1.28 | VP-020 |
| BC-2.04.007 TrajectoryWriter Encryption-at-Rest | SS-04 | S-1.10 | VP-2.11.007-B |
| BC-2.04.011 Trajectory Compaction Isolation | SS-04 | S-2.12 | VP-018, VP-019 |
| BC-2.05.007 PreToolCallHook Fail-Closed Dispatch | SS-05 | VP-INDEX §VP Catalog | VP-011 |
| BC-2.09.007 MCP Response Credential Sanitization | SS-09 | S-2.11 | VP-015 |
| BC-2.09.008 GraphAgentTool State Isolation | SS-09 | S-2.11 | VP-016 |
| BC-2.10.005 BudgetWatermark Arithmetic Invariant | SS-10 | VP-INDEX §VP Catalog | VP-012 |
| BC-2.11.007 GuardrailJournal Completeness | SS-11 | S-1.29 | VP-2.11.007-A, VP-2.11.007-B |
| BC-2.12.001 Thread Resource CRUD | SS-12 | S-1.26, S-console-07 | — |
| BC-2.12.003 Run Lifecycle State Machine | SS-12 | S-1.26 | — |
| BC-2.13.004 Workspace Confinement (Sandbox) | SS-13 | VP-INDEX §VP Catalog | VP-003 |
| BC-2.14.005 Credential Newtype Policy | SS-14 | S-1.02, S-2.06 | — |
| BC-2.18.004 PromptTemplate Injection Guard | SS-18 | S-2.05 | VP-006, VP-006-B |
| BC-2.23.005 BashTool Risk Floor | SS-23 | VP-INDEX §VP Catalog | VP-013 |
| BC-2.24.001 through BC-2.24.008 (SS-24 Console) | SS-24 | S-console-01..10 | VP-2.24.001-A/B/C through VP-2.24.008-A/B |

> Full 149-row table: `specs/behavioral-contracts/BC-INDEX.md` §BC-to-Story Coverage Map. This representative set covers explicitly confirmed links from BC-INDEX and STORY-INDEX changelog evidence.

---

## Story → VP Anchor Summary

Stories with ≥1 VP anchor per STORY-INDEX §VP-to-Story Anchor Map (authoritative source, 43-row table):

- **S-1.28:** VP-017, VP-020 (pregolya-graph; graph::channels)
- **S-1.29:** VP-2.11.007-A, VP-2.11.007-B (pregolya-graph / pregolya-checkpoint)
- **S-2.05:** VP-006, VP-006-B (pregolya-prompts; prompts::injection_guard)
- **S-2.11:** VP-015, VP-016 (pregolya-mcp; mcp::sanitize / mcp::graph_tool)
- **S-2.12:** VP-018, VP-019 (pregolya-checkpoint; checkpoint::trajectory)
- **S-console-01:** VP-2.24.001-A/B/C
- **S-console-02:** VP-2.24.002-A/B (partial; VP-2.24.002-D shared with -03)
- **S-console-03:** VP-2.24.002-C (pregolya-server; server::debug_routes)
- **S-console-04:** VP-2.24.003-A/B/C (pregolya-graph; graph::descriptor)
- **S-console-05/06:** VP-2.24.004-A/B
- **S-console-07:** VP-2.24.005-A/B
- **S-console-08:** VP-2.24.006-A/B
- **S-console-09:** VP-2.24.007-A/B
- **S-console-10:** VP-2.24.008-A/B
- Other stories with VP anchors: see STORY-INDEX §VP-to-Story Anchor Map

> 25 stories with VP anchors / 53 total stories. Full 43-row VP-to-Story table lives in STORY-INDEX §VP-to-Story Anchor Map.

---

## Drift Status (Baseline)

| Layer | Drift Status | Notes |
|-------|-------------|-------|
| Spec ↔ Spec | CLEAN | D-356/D-357 cascade converged 3/3 CLEAN(strict) DC-69/70/71 on anchor d17c711 |
| Code ↔ Spec | N/A | Phase-3 not started; no crate implementations beyond compile-only scaffold |
| VP ↔ Harness | N/A | All VPs status: draft; Phase-6 formal hardening not started |
| Holdout ↔ Spec | N/A | Holdout sealed; Phase-4 not started |

Next drift detection run: after Wave-1 stories are delivered (Phase-3 wave-1 close gate).

---

## Forward Traceability (L1 → Proof)

> Traces from L1 Vision through L2 Domain Spec → L3 PRD / BCs → L4 VPs → proof harness.
>
> **Baseline note (D-359):** Phase-3 not started. Proof harnesses exist only as VP body-file stubs (draft status). The chain from L1 → L3 is complete and converged. L3 → L4 is seeded (43 VPs authored, all draft). L4 → proof harness: pending Phase-6.

| L1 Vision | L2 Domain Spec | L3 BC | L4 VP | Proof Harness | Status |
|-----------|---------------|-------|-------|---------------|--------|
| Fail-closed security | DI-014 Error Propagation / No Silent Swallowing | BC-2.18.004 PromptTemplate Injection Guard | VP-006 (Kani P1) | injection_guard_fewshot_fail_closed | draft — Phase-6 pending |
| Fail-closed security | DI-014 | BC-2.18.004 {PC-005} | VP-006-B (proptest P1) | injection_guard_multipair_fewshot_fail_closed | draft — Phase-6 pending |
| Workspace confinement | DI-010 MCP Tool Safety | BC-2.13.004 Workspace Confinement | VP-003 (Kani P0) | sandbox::path_guard harness | draft — Phase-6 pending |
| PreToolCallHook safety | DI-014 | BC-2.05.007 PreToolCallHook Fail-Closed | VP-011 (Kani P0) | graph::hitl harness | draft — Phase-6 pending |
| Durable graph state | DI-001 Pure-Core Immutability | BC-2.02.007 LedgerChannel Dedup-Idempotent Append | VP-017 (proptest P1) | ledger_channel_dedup_idempotency | draft — Phase-6 pending |
| Trajectory crash-safety | DI-002 Checkpoint Durability | BC-2.04.011 Trajectory Compaction Isolation {INV-001} | VP-018 (proptest P1) | trajectory_compaction_retention_integrity | draft — Phase-6 pending |
| Trajectory crash-safety | DI-002 | BC-2.04.011 {INV-003} | VP-019 (integration P1) | crash-isolation integration test | draft — Phase-6 pending |
| GuardrailJournal completeness | DI-012 GuardrailJournal Durable Append | BC-2.11.007 {INV-002} | VP-2.11.007-A (integration P0) | guardrail_journal_completeness harness | draft — Phase-6 pending |
| GuardrailJournal encryption | DI-012 | BC-2.11.007 {INV-005} + BC-2.04.007 {INV-006} | VP-2.11.007-B (integration P1) | guardrail_journal_encryption_at_rest harness | draft — Phase-6 pending |

> Full forward chain for all 43 VPs: see VP-INDEX §VP Catalog `bc_anchor` + ARCH-INDEX §Verification Properties for the L1 → L3 anchoring rationale per VP.

---

## Reverse Traceability (Proof → L1)

> Traces from proof harness backward through VP → BC → L3 PRD → L2 Domain Spec → L1 Vision.
>
> **Baseline note (D-359):** No proofs executed yet (Phase-6 not started). This section records the reverse-anchor structure established by spec authoring, not verified proof results.

| Proof Harness (planned) | VP | BC | Subsystem | L2 Anchor |
|------------------------|----|----|-----------|-----------|
| ledger_channel_dedup_idempotency | VP-017 | BC-2.02.007 {INV-002} | SS-02 graph::channels | DI-001 Pure-Core Immutability |
| promote_retire_channel_idempotency | VP-020 | BC-2.02.009 {INV-001}+{INV-002} | SS-02 graph::channels | DI-001 |
| trajectory_compaction_retention_integrity | VP-018 | BC-2.04.011 {INV-001} | SS-04 checkpoint::trajectory | DI-002 Checkpoint Durability |
| crash-isolation integration | VP-019 | BC-2.04.011 {INV-003} | SS-04 checkpoint::trajectory | DI-002 |
| credential_redaction_unit | VP-015 | BC-2.09.007 {INV-003} | SS-09 mcp::sanitize | SEC-BOUND-001 |
| graph_agent_tool_state_isolation | VP-016 | BC-2.09.008 {INV-001} | SS-09 mcp::graph_tool | DI-010 MCP Safety |
| injection_guard_fewshot_fail_closed | VP-006 | BC-2.18.004 | SS-18 prompts::injection_guard | DI-014 Error Propagation |
| injection_guard_multipair_fewshot_fail_closed | VP-006-B | BC-2.18.004 {PC-005} | SS-18 prompts::injection_guard | DI-014 |
| guardrail_journal_completeness | VP-2.11.007-A | BC-2.11.007 {INV-002} | SS-11 graph::provenance | DI-012 GuardrailJournal |
| guardrail_journal_encryption_at_rest | VP-2.11.007-B | BC-2.11.007 {INV-005}+BC-2.04.007 {INV-006} | SS-11/SS-04 checkpoint::serializer | DI-012 |
| SS-24 console VPs (20 harnesses) | VP-2.24.001-A through VP-2.24.008-B | BC-2.24.001 through BC-2.24.008 | SS-24 Developer Console | ADR-031 Developer Console Architecture |
| Remaining 10 Kani / proptest harnesses | VP-001..014 (excl. already listed) | See VP-INDEX §VP Catalog | SS-01 through SS-23 | See VP-INDEX §bc_anchor |

---

## VP Status Summary

> **Baseline (D-359 / 2026-09-17):** All 43 VPs are `status: draft`. Phase-6 formal hardening not started. No VP has `verification_lock: true`. No VP has been withdrawn.

| Category | Count |
|----------|-------|
| Total VPs | 43 |
| Status: draft | 43 |
| Status: verified | 0 |
| Status: withdrawn | 0 |
| verification_lock: true | 0 |
| Priority P0 | 7 |
| Priority P1 | 36 |
| Tool: Kani | 10 |
| Tool: proptest | 10 |
| Tool: integration | 14 |
| Tool: unit | 8 |
| Tool: compile-fail | 1 |

### VP Priority Distribution by Subsystem

| Subsystem | P0 VPs | P1 VPs | Total |
|-----------|--------|--------|-------|
| SS-01 core (graph execution) | — | VP-014 | 1 |
| SS-02 graph channels | — | VP-017, VP-020 | 2 |
| SS-04 checkpoint trajectory | — | VP-018, VP-019 | 2 |
| SS-05 HITL / pre-tool-hook | VP-011 | — | 1 |
| SS-09 MCP safety | — | VP-015, VP-016 | 2 |
| SS-10 budget | — | VP-012 | 1 |
| SS-11 GuardrailJournal | VP-2.11.007-A | VP-2.11.007-B | 2 |
| SS-13 sandbox | VP-003 | — | 1 |
| SS-16/17/18/other (injection, serializable, embeddings, vectorstores) | VP-009, VP-010 | VP-006, VP-006-B, VP-007, VP-008 | 6 |
| SS-23 tools::shell | — | VP-013 | 1 |
| SS-24 Developer Console | — | VP-2.24.001..008 (20 VPs) | 20 |
| Other (VP-001, VP-002, VP-004, VP-005) | VP-001, VP-002 | VP-004, VP-005 | 4 |

---

## Gap Register

> Records BCs with no VP anchor and VPs with unresolved prerequisite gaps.
>
> **Baseline note (D-359):** Gap detection is preliminary — a full BC-level VP coverage gap analysis runs as part of Phase-6 gating. The following gaps are structurally registered, not exhaustive.

### BCs Without VP Anchor (sampled; full list via BC-INDEX §Full Catalog VP column)

The majority of the 149 BCs do not have VP anchors. VP coverage is not required for all BCs — only for BCs whose properties require formal proof (per module-criticality.md and VP-INDEX §VP Seed BCs rationale). The following classes are expected non-VP BCs:

- P2-priority BCs (BC-2.XX.NNN with P2 designation)
- High-level behavioral BCs whose correctness is established via standard TDD integration tests (no formal proof required)
- Non-invariant BCs (precondition / postcondition only, no complex invariant)

BCs explicitly designated as VP-anchored "seed BCs" are listed in BC-INDEX §VP Seed BCs (17 unique BC anchors covering all non-SS-24 VPs; BC-INDEX §Full Catalog VP column is authoritative).

### VP Prerequisite Gaps Resolved

- VP-2.11.007-A: BC-Contradictions-Flagged RESOLVED (DC-34; {INV-003}→{INV-002} correction; graph::provenance canonical site)
- VP-2.11.007-B: BC-Contradictions-Flagged RESOLVED (DC-64; infallible &[u8;32] new(); EncryptedSerializer→Serializer seam)
- VP-016: BC-Contradictions-Flagged RESOLVED (round-5/6; seam Options A realizable; CompiledStateGraph non-generic)
- VP-019: BC-Contradictions-Flagged RESOLVED (VP-INDEX §Changelog (v1.38)/D-335; no conflict with VP-018 staging model)

### Active Prerequisite Flags

None as of D-359 baseline. All §BC-Contradictions-Flagged blocks in VP body files are marked RESOLVED.

---

## Withdrawn VP Impact

> Records all VP withdrawals and their cascade status.
>
> **Baseline (D-359):** No VPs have been withdrawn. This section is maintained for future use when Phase-6 formal hardening begins and harness results may necessitate VP retirement or replacement.

| VP ID | Withdrawal Date | Reason | Replacement VP | Cascade Status |
|-------|----------------|--------|----------------|----------------|
| (none) | — | — | — | — |

> When a VP is withdrawn: (1) the VP body file is updated with `lifecycle_status: withdrawn` and a withdrawal rationale; (2) any story AC referencing the VP is updated; (3) the proof harness is removed from the verification suite; (4) the convergence report reflects the withdrawal; (5) a replacement VP (new ID) is authored if the property still needs formal proof.
