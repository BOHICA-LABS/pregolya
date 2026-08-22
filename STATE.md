---
document_type: pipeline-state
level: ops
version: "5.43"
status: in-progress
producer: state-manager
timestamp: "2026-08-21T22:33:00Z"
phase: 2
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: pregolya
mode: greenfield+semport
current_step: "P2A-023 NOT CLEAN (1M) fix-burst COMPLETE (D-230; 2026-08-21): VP-013 fn-name/module alignment check_risk_floor pure-core in tools::shell; S-1.22 aligned. trajectory-tail →2→5→2→1. Census 133 BC/14 VP. Streak 0/3. NEXT: fresh P2A-024."
current_cycle: v1.0.0-greenfield
convergence_status: "Phase-1 CLOSED (burst-325; D-197; 2026-08-18). 3/3 CONVERGED on frozen anchor 79eb2f3 (D-195). Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..023 (sample) fix-bursts COMPLETE D-208..D-230 (sample). D-230 P2A-023 fix-burst COMPLETE 2026-08-21 (VP-013 fn-name/module alignment check_risk_floor; streak 0/3). NEXT: Phase-2 adversarial P2A-024. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md."
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "DIRECTIVE 1 (2026-07-13): Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes. DIRECTIVE 2 (2026-07-29): fix-in-scope is the DEFAULT posture; deferral requires explicit per-case human permission; CLAUDE.md Canonical Principle Rule 3 UNCHANGED. Agents may NOT self-authorize deferrals. Orchestrator may PROPOSE deferrals but default action is to fix."
---

<!-- STATE.md SIZE BUDGET: 185 lines (wc-l) | margin from soft-target (200L): 15 lines | margin from actual: 15 lines | v5.43 (2026-08-21): D-230 P2A-023 fix-burst. NEXT: P2A-024. -->

# Pipeline State: pregolya

## Project Metadata

| Field | Value |
|-------|-------|
| **Product** | pregolya (renamed from ferrochain; D-103 supersedes D6 — D6 records original name choice as historical truth; container rename COMPLETE per D-116) |
| **Repository** | /Users/jmagady/Dev/pregolya |
| **Mode** | greenfield + semport (Python→Rust semantic port) |
| **Language** | Rust (target), Python (reference corpus) |
| **Target Workspace** | Single Cargo workspace (D4) |
| **Reference Corpus** | .reference/ (gitignored) — langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2, langchain-mcp-adapters==0.3.0, adk-rust==1.0.0 (Corpus 5 per D16). Full version pins + commit SHAs recorded in semport/reference-manifest.md |
| **Started** | 2026-07-12 |
| **Last Updated** | 2026-08-21 — v5.43; D-230 minted (P2A-023 1M closed; VP-013 fn-name/module alignment check_risk_floor). trajectory-tail →2→5→2→1. NEXT: Phase-2 adversarial P2A-024. |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | COMPLETE | 2026-07-14 | 2026-08-18 | 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195); input-hash drift resolved (D-196); Phase-1 gate CLOSED (D-197; burst-325). ~215 adversarial passes total. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md | trajectory-tail →1→0→0→0; 3/3 CONVERGED |
| 2: Story Decomposition | IN PROGRESS | 2026-08-18 | | Structural decomp COMPLETE (D-198); per-story authoring COMPLETE 39/39 D-199..D-206 (sample); holdout scenarios COMPLETE 14/14 (D-207; SEALED). P2A-001..023 (sample) fix-bursts COMPLETE D-208..D-230 (sample). NEXT: P2A-024. | trajectory-tail →3→0→2→5→2→1; 0/3. NEXT: P2A-024. |
| 2: passes P2A-012..P2A-018 (sample; archived to burst-log 2026-08-21) | COMPLETE | 2026-08-20 | 2026-08-21 | P2A-012..016: 17 findings (2H/7M/7L/1OBS) ALL CLOSED; P2A-017: 3 findings (2M/1L) CLOSED (D-225); P2A-018: CLEAN(strict)=YES streak 1/3. Census 133 BC/14 VP throughout. Full: cycles/v1.0.0-greenfield/convergence-trajectory.md + burst-log.md. | compressed; detail in trajectory+burst-log |
| 2: adversary pass-19 (P2A-019) | COMPLETE | 2026-08-21 | 2026-08-21 | CLEAN(strict)=YES CLEAN(PR-merge)=YES; 0 findings; streak 2/3. All prior fixes HELD. | trajectory-tail →3→0→0; streak 2/3 |
| 2: adversary pass-20 (P2A-020) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 2 findings (1M/1L); streak RESET 0/3; fix-burst dispatched (D-226). F-P2A020-01 (MED,POL-4/46) scheduler.rs ownership conflict; 4 stories inconsistent/false claims. F-P2A020-02 (LOW) S-1.16→S-1.13 rationale absent. | trajectory-tail →0→0→2; streak RESET 0/3 |
| 2: fix burst (post-pass-20 P2A-020) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-020: all 2 findings closed (D-226). F-P2A020-01 CLOSED: scheduler.rs ownership model (S-1.15 creates; S-1.17 run/stream; S-1.13/S-1.18/S-1.16 layer); 5 new DAG edges; Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts. F-P2A020-02 CLOSED: S-1.16→S-1.13 rationale documented. Census 133 BC/14 VP; DAG acyclic. Streak 0/3. NEXT P2A-021. | trajectory-tail →0→0→2; 0/3 → NEXT P2A-021 |
| 2: adversary pass-21 (P2A-021) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 5 findings (1H/3M/1L); streak RESET 0/3; fix-burst dispatched (D-227). P2A021-01 (HIGH): VectorStore trait ordering inversion; S-2.02/S-2.03 delivery reorder. P2A021-02/03/04 (MED): orphaned-methods BC-2.21.001 PC-2 + S-2.03 ACs; S-1.25 scheduler.rs traceability; wave-schedule max-parallelism 4→6. P2A021-05 (LOW): S-1.16 PSI reworded. add_texts→add_documents rename swept corpus-wide (TD-VSDD-060). | trajectory-tail →0→0→2→5; streak RESET 0/3 |
| 2: fix burst (post-pass-21 P2A-021) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-021: all 5 findings closed (D-227). BC anchor fills: BC-2.20.003/BC-2.21.001/002/003/004 → S-2.03. Census 133 BC / 14 VP; DAG edges UNCHANGED; no renumber. Streak 0/3. NEXT P2A-022. | trajectory-tail →0→0→2→5; 0/3 → NEXT P2A-022 |
| 2: VP-anchor fix-burst (pre-P2A-022; D-228) | COMPLETE | 2026-08-21 | 2026-08-21 | 7 VP harness-path divergences closed corpus-wide: VP-004 mcp::adapter→mcp::exception; VP-007/010 serializable submodule split; VP-009 cosine_guard→zero_norm_guard; VP-012 ambiguous clause removed; VP-013 shell→shell/bash; +ADR-013/arch docs sweep. S-2.03 cosine/zero-norm→similarity.rs (VP-009 vehicle). S-2.05 injection_guard→prompts/src/injection_guard.rs (VP-006 vehicle). VP-INDEX arithmetic UNCHANGED (14 VP). Census 133 BC/14 VP. Phase-6-blocking class closed. Streak 0/3. NEXT: fresh P2A-022. | trajectory-tail →0→0→2→5; 0/3; NEXT P2A-022 |
| 2: adversary pass-22 (P2A-022) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 2 findings (1H/1M); streak RESET 0/3; fix-burst dispatched (D-229). P2A022-01 (HIGH,POL-4/9/6): VP-008 anchor drift — S-2.09 proptest in pregolya-standard-tests using mock-comparison pattern VP-008 rejects; production validate_embedding_batch validator omitted. P2A022-02 (MED,POL-4/9): VP-012 harness basename watermark_arithmetic.rs vs watermark.rs. | trajectory-tail →0→2→5→2; streak RESET 0/3 |
| 2: fix burst (post-pass-22 P2A-022) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-022: all 2 findings closed (D-229). BC-2.22.001 Invariant 6 added (validate_embedding_batch single-enforcement-point); S-2.09 aligned to VP-008 (validator pregolya-core/src/embeddings.rs; proptest in-crate #[cfg(test)] 5 families A–E; AC-017 traces Inv 6; pregolya-standard-tests removed); VP-012 basename watermark.rs. Census 133 BC/14 VP; DAG UNCHANGED. | trajectory-tail →0→2→5→2; 0/3 → NEXT P2A-023 |
| 2: adversary pass-23 (P2A-023) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 1 finding (1M); streak RESET 0/3; fix-burst dispatched (D-230). P2A023-01 (MED,POL-4/9): VP-013 fn-name/module divergence — VP-013.md canonical check_risk_floor in tools::shell; S-1.22 named override_risk/validate_risk in tools::config, never built check_risk_floor. Residual of D-228 partial fix (corrected file path only, not fn name/module). | trajectory-tail →0→2→5→2→1; streak RESET 0/3 |
| 2: fix burst (post-pass-23 P2A-023) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-023: all 1 finding closed (D-230). S-1.22 aligned to VP-013: check_risk_floor pure-core fn in tools::shell/bash.rs; override_risk delegates to check_risk_floor; AC-013 references check_risk_floor with Ok/Err-at-Medium + E-TOOLS-007. BC-consistency verified (BC-2.23.005 governs public override_risk; VP-013 governs extracted pure check_risk_floor; different layers, no conflict). VP-013.md + arch docs unchanged (already canonical). Census 133 BC/14 VP; DAG UNCHANGED. | trajectory-tail →0→2→5→2→1; 0/3 → NEXT P2A-024 |
| 3: TDD Implementation | not-started | | | | — |
| 4: Holdout Evaluation | not-started | | | | — |
| 5: Adversarial Refinement | not-started | | | | — |
| 6: Formal Hardening | not-started | | | | — |
| 7: Convergence | not-started | | | | — |

## Current Phase Steps

<!-- Keep last 5 rows only. Older rows archived to cycles/v1.0.0-greenfield/burst-log.md. -->
| Step | Agent | Status | Output |
|------|-------|--------|--------|
| VP-anchor fix-burst (D-228; 2026-08-21) — 7 VP harness-path divergences closed corpus-wide: VP-004 mcp::adapter→mcp::exception; VP-007 serializable.rs→serializable/traits.rs; VP-009 cosine_guard.rs→zero_norm_guard.rs; VP-010 serializable.rs→serializable/reviver.rs; VP-012 ambiguous clause removed; VP-013 shell.rs→shell/bash.rs; ADR-013/arch sweep. S-2.03: cosine/zero-norm→vectorstores/src/similarity.rs (VP-009 vehicle). S-2.05: injection_guard→prompts/src/injection_guard.rs (VP-006 vehicle). Census 133 BC/14 VP. Phase-6-blocking class closed. | vsdd-factory:architect + story-writer | COMPLETE | 16 specialist files + STATE.md + trajectory. Census 133 BC/14 VP. Streak 0/3. NEXT: fresh P2A-022. |
| P2A-022 NOT CLEAN pass (2026-08-21) — 2 findings (1H/1M). P2A022-01 (HIGH,POL-4/9/6) VP-008 anchor drift — S-2.09 proptest in pregolya-standard-tests using mock-comparison pattern VP-008 rejects; production validate_embedding_batch validator omitted. P2A022-02 (MED,POL-4/9) VP-012 harness basename watermark_arithmetic.rs vs watermark.rs. D-229 minted. Fix-burst dispatched. Streak RESET 0/3. | vsdd-factory:adversary | COMPLETE | 2 findings. Streak RESET 0/3. |
| P2A-022 fix-burst (2026-08-21) — all 2 findings closed (D-229). BC-2.22.001 Invariant 6 added (validate_embedding_batch single-enforcement-point, Err(E-EMBED-001)); S-2.09 aligned to VP-008 (validator pregolya-core/src/embeddings.rs; proptest in-crate #[cfg(test)] 5 families A–E; AC-017 traces Inv 6; pregolya-standard-tests removed); VP-012 basename watermark.rs. Census 133 BC/14 VP; DAG UNCHANGED. | state-manager | COMPLETE | 3 specialist files + STATE.md + trajectory. Census 133 BC/14 VP. Streak 0/3. NEXT: P2A-023. |
| P2A-023 NOT CLEAN pass (2026-08-21) — 1 finding (1M). P2A023-01 (MED,POL-4/9) VP-013 fn-name/module divergence — VP-013.md canonical check_risk_floor in tools::shell; S-1.22 named override_risk/validate_risk in tools::config, never built check_risk_floor. Residual of D-228 partial fix (file path shell→shell/bash corrected; fn name/module not). D-230 minted. Fix-burst dispatched. Streak RESET 0/3. | vsdd-factory:adversary | COMPLETE | 1 finding. Streak RESET 0/3. |
| P2A-023 fix-burst (2026-08-21) — all 1 finding closed (D-230). S-1.22 aligned to VP-013: check_risk_floor pure-core fn in tools::shell/bash.rs; override_risk delegates to check_risk_floor; AC-013 references check_risk_floor with Ok/Err-at-Medium + E-TOOLS-007; ToolConfig::override_risk now delegates to check_risk_floor; internal AC↔Tasks name split resolved; input-hash refreshed. BC-consistency verified (BC-2.23.005 governs public override_risk; VP-013 governs extracted pure check_risk_floor; different layers, no conflict). Census 133 BC/14 VP; DAG UNCHANGED. | state-manager | COMPLETE | 1 story file + STATE.md + trajectory. Census 133 BC/14 VP. Streak 0/3. NEXT: P2A-024. |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D-1..D-55 (sample) | *Compressed — pre-pipeline + early Phase 1 (pre-p1d). See `.factory/planning/decisions-archive-pre-p1d.md` (D1–D17) + git history. Key: StreamEvent::GuardrailDecision 12th variant; ecosystem-parity + Domain-E expansion (D21–D23); ActionRisk/ToolConfig/DynTool/as_retriever API canon; TD-VSDD-091 enforcement.* | | pre-1 + Phase 1 | 2026-07-12..07-28 | various |
| D-56..D-135 (sample) | *Compressed — Phase 1 (P1D passes + ops). Git history. Key: D-61 SS-15 tenancy; D-65 TrustLevel severity ordering; D-76 BC count 170; D-93 rename to pregolya; D-103 D-93 supersedes D6; D-109 P1D-176 COMPLETE (160 findings/5 CRITs); D-116 container rename COMPLETE; D-118 factory-artifacts default_branch; D-126 5 CRITs CLOSED; D-127 ADR-025+POL-46/47.* | | Phase 1 | 2026-07-28..08-01 | various |
| D-136..D-194 (sample) | *Compressed — Phase 1 convergence cascade (archive: cycles/v1.0.0-greenfield/burst-log.md). Key: D-143 3-CLEAN streak over spec content; D-149 non-ADR §-anchor closed corpus-wide; D-158 ferro-residue+records-lint L12; D-167 Phase-1d CONVERGED 3/3 on 1262ebe; D-170 LCEL scope expansion (human-directed); D-171 LCEL COMPLETE (BC 129→133; VP 13→14); D-178 EXEC 13th error category; D-185 coverage audit; D-189..D-194 (sample) passes streak progression.* | | Phase 1/ops | 2026-08-15..08-18 | various |
| D-195..D-207 (sample) | *Compressed — Phase-1 gate + Phase-2 structural (full text archived to burst-log 2026-08-21). Key: D-195 Phase-1 3/3 CONVERGED on 79eb2f3 (P1-pass-211/212/213); D-196 input-hash = bookkeeping metadata (human ruling; extends D-143); D-197 Phase-1 GATE CLOSED burst-325 (133 BC/39 CAP/16 DI/14 VP/26 ADR/114 EC); D-198 Phase-2 structural COMPLETE (39/22/294pts; 133/133 BC; DAG acyclic; 14/14 VP); D-207 holdout 14/14 SEALED burst-335 (9 must-pass=64%).* | | Phase 1→2 | 2026-08-18..08-19 | state-manager/orchestrator/product-owner |
| D-208..D-225 (sample) | *Compressed — Phase-2 adversarial passes P2A-001..017 + fix-bursts (full text archived to burst-log 2026-08-21). Key: D-208..D-218 (sample) P2A-001..011 ALL CLOSED; D-219 P2A-012 2H (mod.rs+error-type); D-220 wrap+TDIV-009 waiver (human); D-221 P2A-013 1H/3M/1L (target_module); D-222 P2A-014 1M/1L/1OBS (Wave-2 target); D-223 P2A-015 1H/1M/3L (SDK-split D17-Q5); D-224 P2A-016 2M/1L (dep-graph+facade); D-225 P2A-017 2M/1L (Primary-Crate SS-10+SS-06). Census 133 BC/14 VP throughout.* | | Phase 2 | 2026-08-19..08-21 | various |
| D-226 | **Phase-2 adversarial P2A-020 NOT CLEAN (1M/1L) ALL CLOSED. STREAK HISTORY: P2A-018 CLEAN(strict)=YES streak 1/3; P2A-019 CLEAN(strict)=YES streak 2/3; P2A-020 NOT CLEAN streak RESET 0/3. F-P2A020-01 (MED, POL-4/46) CLOSED: scheduler.rs ownership ambiguity — 4 same-batch stories (S-1.13/S-1.15/S-1.17/S-1.18) made mutually-inconsistent claims incl. false ones (S-1.18 credited S-1.14 with a scheduler skeleton it never builds; S-1.13 falsely claimed first-touch). Architect ruling: S-1.15 CREATES scheduler.rs skeleton; S-1.17 adds run()/stream(); S-1.13 adds ContextMutationConfig pre-loop loader; S-1.18 adds per-super-step budget eval; S-1.16 adds ceiling/run_id checks. New DAG edges: S-1.17 dep S-1.15; S-1.13/S-1.18/S-1.16 dep S-1.17; S-1.16 dep S-1.18. batch-1e split into sequential chain S-1.15→S-1.17→{S-1.13∥S-1.18}→S-1.16 (Wave-1 10→12 batches; DAG acyclic; critical path 10→12 stories/69→82 pts). F-P2A020-02 (LOW) CLOSED: S-1.16 depends_on S-1.13 rationale absent → documented via PSI rows. D-221 S-1.16↔S-1.13 edge CONFIRMED. No BC/VP/story renumber (POL-1); census 133 BC/14 VP; DAG ACYCLIC; no ADR change. Content defect (not process-gap). Streak 0/3. NEXT P2A-021.** | Phase-2 adversarial pass 20; 2 findings closed (1M/1L); scheduler.rs ownership model + 5 new DAG edges; streak history P2A-018/019 CLEAN then P2A-020 reset | Phase 2 | 2026-08-21 | architect/story-writer/state-manager |
| D-227 | **Phase-2 adversarial P2A-021 NOT CLEAN (1H/3M/1L) ALL CLOSED. P2A021-01 (HIGH): VectorStore trait ordering inversion — VectorStoreRetriever + as_retriever delivery moved S-2.02→S-2.03; S-2.02 scope→pregolya-core (2 BCs, 5 pts); S-2.03 absorbs whole pregolya-vectorstores crate (5 BCs incl BC-2.20.003, 10 pts, +MMR/as_retriever ACs); "forward declaration or stub" language removed. P2A021-02 (MED): orphaned methods VectorStoreRetriever::similarity_search_with_score + as_retriever added to BC-2.21.001 PC-2 + S-2.03 ACs (AC-019 MMR, AC-020 as_retriever). P2A021-03 (MED): S-1.25 scheduler.rs traceability added (File Structure + Architecture Mapping + coordination note; batch 1l, no new DAG edge). P2A021-04 (MED): wave-schedule Max-parallelism corrected 4→6 (sub-batch 1d). P2A021-05 (LOW): S-1.16 PSI reworded ("run() body established by S-1.17"). CONTRACT-NAME RENAME (TD-VSDD-060 sibling-sweep): add_texts→add_documents corpus-wide (capabilities-p1-p2.md CAP-028/029, entities-graph.md, BC-2.21.001/002, module-decomposition.md, ADR-014, purity-boundary-map.md, S-2.03 ACs); zero live add_texts remain. BC ANCHOR FILLS: BC-2.20.003, BC-2.21.001/002/003/004 anchors → S-2.03. No BC/VP/story renumber (POL-1); DAG edges UNCHANGED; census 133 BC / 14 VP; no new ADR. Streak 0/3. NEXT P2A-022.** | Pass 21; 5 findings (1H/3M/1L) closed; VectorStore ordering; add_documents rename sweep; BC anchor fills | Phase 2 | 2026-08-21 | architect/product-owner/business-analyst/story-writer/state-manager |
| D-228 | **Phase-2 proactive fix-burst: VP-anchor module-path reconciliation (pre-P2A-022). Surfaced during P2A-022 attempts — two runs died to API connection errors mid-investigation; both independently flagged the same VP-harness-path class before terminating. Architect verified + resolved corpus-wide. 7 VP harness-path divergences closed: VP-004 module mcp::adapter→mcp::exception (propagated: VP-INDEX, verification-architecture, coverage-matrix, module-decomposition [pure 34→35 / shell 38→37; total 84 UNCHANGED], purity-boundary-map, ARCH-INDEX, module-criticality, ADR-013); VP-007 target serializable.rs→serializable/traits.rs; VP-010 serializable.rs→serializable/reviver.rs; VP-009 harness comment cosine_guard.rs→zero_norm_guard.rs; VP-012 removed ambiguous "(or core/budget.rs)" clause; VP-013 shell.rs→shell/bash.rs. Story follow-ups: S-2.05 extracted injection_guard into standalone prompts/src/injection_guard.rs (VP-006 Kani vehicle; chat_template.rs now delegates); S-2.03 moved cosine_similarity+zero-norm to standalone vectorstores/src/similarity.rs (VP-009 vehicle; removed store/cosine.rs; in_memory imports crate::similarity) — canonical shared-primitive per F-P129-11. VP-INDEX arithmetic UNCHANGED (14 = 6 P0 + 8 P1 = 9 Kani + 3 proptest + 2 integration; no VP added/removed/reclassified). Census 133 BC / 14 VP; no ADR change; DAG edges UNCHANGED (acyclic); no BC/VP/story renumber (POL-1). Phase-6-blocking class: harnesses must import proof vehicles at declared paths; now closed corpus-wide. Streak 0/3. NEXT: fresh P2A-022.** | Phase-2 proactive fix-burst; VP harness-path reconciliation; 7 VP divergences + 2 story extractions; Phase-6-blocking class closed | Phase 2 | 2026-08-21 | architect/story-writer/state-manager |
| D-229 | **Phase-2 adversarial P2A-022 NOT CLEAN (1H/1M) ALL CLOSED. P2A022-01 (HIGH, POL-4/9/6): VP-008 anchor drift — S-2.09 built VP-008 proptest in pregolya-standard-tests using mock-comparison pattern VP-008 explicitly rejects; production validate_embedding_batch validator omitted entirely. FIXED: BC-2.22.001 Invariant 6 added (validate_embedding_batch single-enforcement-point contract: sole validator for count-mismatch/zero-len/inconsistent-len, returns Err(E-EMBED-001)); S-2.09 aligned to VP-008 (production validator in pregolya-core/src/embeddings.rs; proptest in-crate #[cfg(test)] with 5 property families A–E feeding raw mock outputs into the production validator; AC-017 traces BC-2.22.001 Invariant 6; pregolya-standard-tests harness row removed — was never in target_module). VP-008 itself unchanged (was already canonical). P2A022-02 (MED, POL-4/9): VP-012 harness basename watermark_arithmetic.rs does not match watermark.rs used by S-1.25 and S-6.01 (D-228 left this occurrence). FIXED: VP-012 basename corrected to watermark.rs (sole occurrence); harness_fn watermark_arithmetic_harness unchanged. No BC/VP/story renumber (POL-1); S-2.09 bcs set unchanged — Token Budget BC count (3) unaffected; DAG edges UNCHANGED (acyclic); census 133 BC / 14 VP. Streak 0/3. NEXT: P2A-023.** | Phase-2 adversarial pass 22; 2 findings closed (1H/1M); BC-2.22.001 Invariant 6 + S-2.09 VP-008 alignment + VP-012 basename | Phase 2 | 2026-08-21 | product-owner/architect/story-writer/state-manager |
| D-230 | **Phase-2 adversarial P2A-023 NOT CLEAN (1M) ALL CLOSED. P2A023-01 (MED, POL-4/9): VP-013 function-name/module divergence — VP-013.md canonical proof vehicle is check_risk_floor (pure-core fn) in tools::shell; anchor story S-1.22 had named override_risk/validate_risk in tools::config and never built check_risk_floor. This was a residual of D-228's VP-013 fix, which corrected only the file path (shell.rs→shell/bash.rs) but not the fn name/module. FIXED: S-1.22 aligned — check_risk_floor is the pure-core VP-013 proof vehicle in tools::shell/bash.rs; ToolConfig::override_risk delegates to check_risk_floor; AC-013 references check_risk_floor with Ok/Err-at-Medium + E-TOOLS-007; input-hash refreshed. BC-consistency verified (BC-2.23.005 governs public override_risk call-site / E-TOOLS-007; VP-013 governs extracted pure check_risk_floor; different layers, no conflict; AC-013 trace to BC-2.23.005 Inv 1 unchanged). VP-013.md + verification-architecture + coverage-matrix were already canonical/consistent — no VP or arch-doc change needed. Adversary confirmed other 13 VP anchors + DAG + wave + census + POL-8 all CLEAN — VP-013 was the lone residual. No BC/VP/story renumber (POL-1); census 133 BC / 14 VP — UNCHANGED; DAG UNCHANGED (acyclic). Streak 0/3. NEXT: P2A-024. Note: third consecutive VP-anchor residual cascade (D-228+D-229+D-230); reinforces PROCESS-GAP-CANDIDATE for a mechanical VP-anchor-consistency validator (DEFER-004 class; human authorization required).** | Phase-2 adversarial pass 23; 1 finding (1M) closed; VP-013 fn-name/module alignment check_risk_floor; D-228 partial-fix residual | Phase 2 | 2026-08-21 | story-writer/state-manager |

## Risk Register

<!-- Resolved risks R1–R5, R7, R9 archived to cycles/v1.0.0-greenfield/blocking-issues-resolved.md. Open risks only. -->
| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R6 | `pregolya-*` crates.io names verified free but NOT reserved (D-103). publish-all.sh regenerated. | High | pre-1 | Pending human action: `cargo login` → `cd .factory/namespace-reservation && bash publish-all.sh`. 21 crates unreserved. |
| R8 | Splitters code-point vs byte-length parity: GTV-010/011 grapheme-discriminating vectors added (burst 253); all 11 GTVs verified. Full byte-level parity coverage lands Phase 3. | High | Phase 1/3 | CRITICAL parity risk. Route to product-owner at Phase 1. |
| R10 | Upstream coverage gap: NamedBarrierValue has NO dedicated unit test. EphemeralValue only 3 assert lines. | Medium | Phase 1 | Route to product-owner at Phase 1 |
| R11 | MCP upstream test voids: mcp bare-ToolException re-raise path untested; mcp `__aenter__` NotImplementedError untested. | Medium | Phase 1/3 | Route to product-owner at Phase 1 |
| R12, R13 | Phase-1d scope expansion risks (D21/D23): re-convergence cost + new attack surface. RESOLVED — re-convergence CLOSED (D-195); Phase-1d CASCADE CLOSED. | Closed | Phase 1 | Resolved. Archived to git history. |
| R-009 | No v1 migration path for Python LangGraph checkpoint stores. Traced to CAP-005, ASM-007, ADR-002 §Consequences. | Medium | Phase 3/4 | Registered D-73. Route to architect at Phase 3. |

## Skip Log

| Step | Skipped? | Justification |
|------|----------|---------------|
| Phase 0: Codebase Ingestion | yes | Greenfield — no existing Rust codebase to ingest. Replaced by semport-analyze of Python reference corpus. |

## Blocking Issues

| ID | Issue | Severity | Blocking Phase | Owner | Resolution |
|----|-------|----------|----------------|-------|------------|
| B1 | direnv not allowed — .envrc present but unenabled; 4 AWS/Anthropic key names declared | Low | pre-1 | human | Run `direnv allow .` from project root |
| TDIV-008 | spec-steward output paths guard INERT confirmed (D-94). `validate-artifact-path` exits 0 on every invocation — engine `path_allow` resolves relative to engine directory. `[process-gap]` | High | Phase 1+ | human+engine-vendor | Engine-level path_allow fix requires engine version bump (vendor action). |
| E013 | Repository `default_branch` is `factory-artifacts` (D-118). A fresh clone checks out `.factory/` bookkeeping instead of Rust workspace. | Medium | pre-1 | human | Set default_branch to `main` via GitHub repo settings |
| TDIV-009-VENDOR | Engine holdout-scenario-template.md mandates `## Category: real-world-corpus` as a required (non-conditional) H2 section. 12/14 pregolya scenarios non-real-world-corpus. Human-WAIVED P2A-006; mitigated in-project. Durable fix = engine-vendor template change. Future adversary passes: do NOT re-flag. | Low | none (waived) | engine-vendor | Vendor template patch. |

## Drift / Deferrals

| ID | Item | Target | Reason |
|----|------|--------|--------|
| DEFER-003 | Resume procedure should detect+quiesce orphaned prior-session background agents (L-182; D-168) | Phase-1-gate close / first self-improvement wave | Engine/session-management concern; authorized per D-168 |
| DEFER-004 | PROPOSED mechanical grep-lint (devops-engineer) for canonical-form drift detection. | Awaiting human/devops prioritization | DIRECTIVE 2 — proposal only; human must authorize devops scope |
| OBS-1 | No validator enforces story-frontmatter `blocks:` ↔ DAG reverse(depends_on) reciprocity. P2A-005 SW-1 found 20 divergent sites. Mechanical check REQUIRED before Phase-2 gate close (S-7.02). | Phase-2-gate / first self-improvement wave | OPEN — awaiting devops-engineer story OR human-authorized deferral per DIRECTIVE 2. |
| PGAP-MSGDRIFT | No mechanical gate diffs story AC error-message strings against error-taxonomy.md §Message Format. Content instances SWEPT CORPUS-WIDE (P2A-011, D-218; 10 instances fixed). Mechanical gate STILL REQUIRED before Phase-2 gate close. | Phase-2-gate / first self-improvement wave | OPEN — awaiting follow-up story OR human-authorized deferral per DIRECTIVE 2. |

## Concurrent Cycles

None active. Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..023 (sample) fix-bursts COMPLETE + D-230 P2A-023 fix-burst COMPLETE. NEXT: P2A-024. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Convergence Status

Counter: **Phase-1 CLOSED (burst-325; D-197; 2026-08-18)**: 3/3 CONVERGED on frozen anchor 79eb2f3 (D-195). Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..023 (sample) fix-bursts COMPLETE. P2A-022 NOT CLEAN (1H/1M; D-229; fix-burst COMPLETE 2026-08-21) streak RESET 0/3. P2A-023 NOT CLEAN (1M; D-230; fix-burst COMPLETE 2026-08-21) streak RESET 0/3. NEXT: Phase-2 adversarial P2A-024. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Session Resume Checkpoint

<!-- v5.43 checkpoint replaces v5.42 — v5.42 archived to cycles/v1.0.0-greenfield/session-checkpoints.md. Keep ONLY the latest checkpoint here. -->

### RESUME IN ONE BREATH
Pregolya (Rust semantic port of langchain/langgraph), greenfield+semport, /Users/jmagady/Dev/pregolya. Phase 1 CLOSED. Phase 2 Story Decomposition: content COMPLETE (39 story specs, 133/133 BC coverage, 14 holdout scenarios SEALED). Currently in Phase-2 adversarial story-decomposition convergence (BC-5.39.001 3-CLEAN); streak **0/3**. Adversary passes P2A-001..P2A-023 run; P2A-018/019 CLEAN(strict) (streak 1/3→2/3); P2A-020 NOT CLEAN (1M/1L; D-226; scheduler.rs ownership); P2A-021 NOT CLEAN (1H/3M/1L; D-227; VectorStore ordering + add_documents rename + BC anchors); P2A-022 NOT CLEAN (1H/1M; D-229; VP-008 anchor drift + VP-012 basename); P2A-023 NOT CLEAN (1M; D-230; VP-013 fn-name/module alignment check_risk_floor) — streak RESET 0/3. NEXT: dispatch a FRESH `vsdd-factory:adversary` pass **P2A-024** on current factory-artifacts HEAD.

### HEADS
- develop `644d1ad` — clean, PUSHED, untouched.
- factory-artifacts: run `git -C .factory log -1 --format='%h'` for the current HEAD. PUSHED to origin. (Per TD-VSDD-053, do NOT pin the SHA literally here — git is source of truth.)
- Worktrees: NONE. Open PRs: NONE.

### CURRENT WORKSTREAM — Phase-2 adversarial story convergence
- Streak **0/3** (BC-5.39.001). P2A-023 RESET (VP-013 fn-name/module alignment check_risk_floor).
- Finding trajectory P2A-001..023: 8→3→7→3→8→2→3→4→8→10→4→2→5→3→5→3→3→0→0→2→5→2→1. Axes swept: VP anchors; subsystem-name canon; error-code categories; error-message strings; DAG reciprocity; holdout BC-linkage; purity; VP-011; error-type semantics; mod.rs layout; BC-table priority; target-crate frontmatter; DAG S-1.16→S-1.13; version-literal pins; Wave-2 target-crate; STORY-INDEX subsystem; SDK-split D17-Q5; dep-graph 10-batch; pregolya facade; SS-10/SS-06 (D-225); scheduler.rs ownership (D-226); VectorStore ordering S-2.02→S-2.03 (D-227); add_documents rename corpus-wide (D-227); VP harness-path reconciliation corpus-wide (D-228); VP-008 anchor drift + validate_embedding_batch production validator (D-229); VP-012 watermark.rs basename (D-229); VP-013 fn-name/module check_risk_floor in tools::shell (D-230).
- **RESUME NEXT-ACTION:** dispatch `vsdd-factory:adversary` **P2A-024**, fresh context, Read/Grep/Glob only, Form-B verbatim evidence, FULL POL rubric (POL-1..31 + POL-46/47). ACCEPTED/DO-NOT-REFLAG: (1) F-02/TDIV-009 vendor-template limitation waived (D-220); (2) OBS-1 + PGAP-MSGDRIFT open gaps — report NEW instances only; (3) Primary Crate(s) convention swept ALL 23 SS rows (D-225) — do NOT re-flag absent NEW concrete BC-homing divergence; (4) scheduler.rs ownership model ESTABLISHED (D-226) — do NOT re-flag; (5) add_documents is the canonical VectorStore ingestion method (D-227) — do NOT re-flag; (6) VP-anchor module paths reconciled corpus-wide (D-228) — do NOT re-flag VP harness-path locations; injection_guard in prompts/src/injection_guard.rs; cosine/zero-norm in vectorstores/src/similarity.rs; VP-004 mcp module is mcp::exception; (7) VP-008 validate_embedding_batch production-validator design canonical: validator in pregolya-core/src/embeddings.rs; proptest in-crate #[cfg(test)] 5 families A–E feeding raw mock outputs into production validator; BC-2.22.001 Invariant 6 is the enforcement-point contract (D-229) — do NOT re-flag; (8) VP-012 watermark harness basename is watermark.rs; harness_fn watermark_arithmetic_harness unchanged (D-229) — do NOT re-flag; (9) VP-013 proof vehicle = check_risk_floor (pure-core fn, tools::shell/bash.rs); ToolConfig::override_risk delegates to check_risk_floor; AC-013 references check_risk_floor with Ok/Err-at-Medium + E-TOOLS-007; BC-2.23.005 governs public override_risk call-site; VP-013 governs extracted pure check_risk_floor — different layers, canonical (D-230) — do NOT re-flag. Dual CLEAN(strict)/CLEAN(PR-merge) verdict, frozen-HEAD baseline. CLEAN(strict) → streak 1/3 → P2A-025/026 on SAME HEAD to 3/3.
- **PROCESS-GAP CANDIDATE (Phase-2 gate):** Three consecutive VP-anchor residual cascades (D-228+D-229+D-230) strongly suggest a missing mechanical gate asserting each VP's declared harness path/fn-name/module matches its anchor-story-built path. Propose a devops validator (DEFER-004 class; human authorization required — do NOT self-authorize).
- **OPS LEARNING (this session):** (a) `sidecar-learning.md` session-hook re-dirties the tree after every agent stop — a streak-transparent `chore:` hygiene commit needed before each adversary dispatch (adversary/wave-gate dispatches BLOCKED on dirty tree; fix-burst dispatches are not); (b) PROPOSED: gitignore `sidecar-learning.md` in `.factory/.gitignore` — DEFER-004 class; requires human authorization before implementing; (c) P2A-022 adversary died twice to API connection errors mid-run; retry P2A-024 until a full verdict is obtained before recording a pass result.

### PENDING USER-APPROVED WORK
None pending (Phase 2→3 autonomous per DIRECTIVE 1). **F-02/TDIV-009 WAIVED** (vendor-template limitation; D-220).

### OPEN ITEMS FOR PHASE-2 GATE
- TDIV-009-VENDOR (human-waived; durable fix = vendor template change).
- OBS-1 — DAG reciprocity validator pending devops scope authorization.
- PGAP-MSGDRIFT — mechanical gate pending devops scope authorization.
- Human actions: E013 (default_branch→main), R6/R14 (cargo login + publish-all.sh), B1 (direnv allow .), TDIV-008 (vendor). WORKSPACE INIT incomplete (Phase-3 prerequisite).

### DECISION DELTA (this session)
D-226 minted (P2A-020; scheduler.rs ownership). D-227 minted (P2A-021; VectorStore ordering + add_documents rename + BC anchor fills). D-228 minted (VP-anchor module-path reconciliation; 7 VP harness-path divergences + 2 story extractions; Phase-6-blocking class closed corpus-wide). D-229 minted (P2A-022; VP-008 anchor drift + VP-012 basename; BC-2.22.001 Invariant 6 added; S-2.09 VP-008 alignment; streak 0/3). D-230 minted (P2A-023; VP-013 fn-name/module alignment check_risk_floor; S-1.22 aligned; streak 0/3). P2A-018/019 CLEAN(strict); P2A-020/021/022/023 RESET. Human F-02/TDIV-009 waiver in effect (D-220).

### PENDING HUMAN ACTIONS
1. **E013 (Medium)** — `gh repo edit --default-branch main`.
2. **R14/R6 (HIGH)** — `cargo login` → `cd .factory/namespace-reservation && bash publish-all.sh`.
3. B1 — `direnv allow .`
4. **TDIV-008** — engine `path_allow` fix requires vendor action.

## Historical Content

| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–343; Phase-2 per-story authoring + holdout scenarios; P2A-001..023 (sample) fix-bursts + session wrap D-220) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| Adversary pass details (~215 Phase-1 passes; Phase-2 P2A-001..P2A-023; D-228+D-229+D-230 fix-bursts) | `cycles/v1.0.0-greenfield/convergence-trajectory.md` |
| Session checkpoints (v4.45..v5.42 archived; v5.42 replaced 2026-08-21) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (188+ lessons) | `cycles/v0.0.0-pre-pipeline/lessons.md` + `cycles/v1.0.0-greenfield/lessons.md` |
| Resolved blockers (R1–R5, R7, R9) | `cycles/v1.0.0-greenfield/blocking-issues-resolved.md` |
| Spec artifacts (133 BCs; 14 VPs; 26 ADRs; PRD; L2 domain spec; architecture) | `.factory/specs/` |
| Phase-2 story specs (39 stories; epics; DAG; wave schedule; sprint state) | `.factory/stories/` |
| Holdout scenarios (14 scenarios; SEALED) | `.factory/holdout-scenarios/` |
| Planning artifacts (DTU assessment; semport analysis; market intel; naming; policies.yaml) | `.factory/planning/` + `.factory/semport/` + `.factory/policies.yaml` |
