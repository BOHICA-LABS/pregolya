---
document_type: pipeline-state
level: ops
version: "3.78"
status: in-progress
producer: state-manager
timestamp: 2026-07-22T15:13:33Z
phase: 1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "P1D-136 complete (6 findings: 3H/2M/1L — interface-def crate/module placement-marker class incl. one compile-impossible core→graph circular dep [F-P136-03]) + fix-burst 236 complete (all closed; PreToolDecision variants corrected; tokens_remaining_after→Option<i64>; purity-map v1.13 run_ctx); trajectory-tail →10→7→6→6, decaying; 0/3. NEXT: adversary pass P1D-137 on new frozen HEAD."
current_cycle: v1.0.0-greenfield
convergence_status: "0/3 — P1D-136 NOT CLEAN (6 findings: 0C/3H/2M/1L); fix-burst 236 COMPLETE (all 6 closed); 136 passes total, 136 fix bursts total (128 pre-D21 + 8 post-D21+D23)"
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes." (verbatim, 2026-07-13)
---

<!-- STATE.md SIZE BUDGET: 200-line soft limit / 500-line hard limit. ~184 lines (wc-l); margin from soft-target: ~16 lines; margin from actual: ~16 lines. Burst-236 full: P1D-136 6 findings ALL CLOSED; crate/module placement-markers + circular-dep; purity-map v1.13 run_ctx; interface-defs v2.48; hash sweep STALE=0. -->
# Pipeline State: ferrochain

## Project Metadata

| Field | Value |
|-------|-------|
| **Product** | ferrochain (RESOLVED D6 — formerly working name langchain-rs; physical rename pending repo-init B2) |
| **Repository** | /Users/jmagady/Dev/ferrochain |
| **Mode** | greenfield + semport (Python→Rust semantic port) |
| **Language** | Rust (target), Python (reference corpus) |
| **Target Workspace** | Single Cargo workspace (D4) |
| **Reference Corpus** | .reference/ (gitignored) — langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (curated-subset), langchain-mcp-adapters==0.3.0 (SHA a61c783a), adk-rust v1.0.0 (SHA a6c79b6f, Corpus 5 per D16). Full pins: semport/reference-manifest.md v1.4.0 |
| **Started** | 2026-07-12 |
| **Last Updated** | 2026-07-22 — burst 236 COMPLETE (all agents): interface-definitions v2.48 (F-P136-01..05: GuardedDocuments core::retriever; PreToolCallHook graph::hitl+pre_invoke+run_ctx; Compaction types core::budget circular-dep fix; CompactionEvent.tokens_remaining_after Option<i64>; BC-2.05.004→BC-2.05.007 anchor; PreToolDecision variant-shape); purity-boundary-map v1.13 (pre_invoke +run_ctx: &RunContext); BC-2.05.007 v1.2; BC-2.10.005 v1.1; BC-2.06.006 v1.2; BC-2.10.006 v1.3; hash sweep STALE=0; trajectory-tail →10→7→6→6; 0/3. NEXT: P1D-137. |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | IN PROGRESS — D21+D23 scope expansion | 2026-07-14 | | D21 ecosystem-parity expansion APPROVED (burst 216); D23 authoring COMPLETE (bursts 229-232): ADR-018/019/020, ADR-010 v1.5, SS-23, roster 21, module-decomp v1.18, ARCH-INDEX v1.8, universe 54, SS-15/SS-16 Wave-1, CAP-034..038, CAP-017/018 Wave-1, L2-INDEX v1.10, census 38, BC-INDEX v2.3 (129 BCs = 51/75/3), VP-INDEX v1.5 (13 VPs); P1D-136 fix-burst 236 COMPLETE (all 6 closed; crate/module placement-markers + circular-dep F-P136-03); 0/3; NEXT: adversary cascade P1D-137 | →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24) →7 (P1D-25) →5 (P1D-26) →6 (P1D-27) →1 (P1D-28) →6 (P1D-29) →1 (P1D-30) →1 (P1D-31) →4 (P1D-32) →2 (P1D-33) →3 (P1D-34) →0 (P1D-35 CLEAN) →3 (P1D-36, reset) →2 (P1D-37) →1 (P1D-38) →2 (P1D-39) →1 (P1D-40) →0 (P1D-41 CLEAN) →1 (P1D-42, reset) →1 (P1D-43) →0 (P1D-44 CLEAN) →2 (P1D-45, reset) →1 (P1D-46) →2 (P1D-47) →1 (P1D-48) →1 (P1D-49; 1 rejected FP) →1 (P1D-50) →0 (P1D-51 CLEAN) →0 (P1D-52 CLEAN) →1 (P1D-53, reset) →0 (P1D-54 CLEAN) →1 (P1D-55, reset) →1 (P1D-56) →1 (P1D-57) →3 (P1D-58) →2 (P1D-59) →3 (P1D-60) →2 (P1D-61) →1 (P1D-62) →1 (P1D-63) →2 (P1D-64) →1 (P1D-65) →3 (P1D-66) →1 (P1D-67) →0 (P1D-68 CLEAN) →1 (P1D-69, reset) →2 (P1D-70) →0 (P1D-71 CLEAN) →[D20 expansion: +9 new-BC files +2 CAPs +ADR-012] →8 (P1D-72, D20-content scrutiny) →2 (P1D-73) →1 (P1D-74) →1 (P1D-75) →0 (P1D-76 CLEAN) →1 (P1D-77, reset) →4 (P1D-78) →2 (P1D-79) →1 (P1D-80) →1 (P1D-81) →2 (P1D-82) →3 (P1D-83) →1 (P1D-84) →4 (P1D-85) →2 (P1D-86) →2 (P1D-87) →4 (P1D-88) →4 (P1D-89) →1 (P1D-90, census-closure) →4 (P1D-91) →2 (P1D-92) →5 (P1D-93) →3 (P1D-94) →4 (P1D-95) →1 (P1D-96) →5 (P1D-97) →1 (P1D-98) →1 (P1D-99) →3 (P1D-100) →2 (P1D-101) →2 (P1D-102) →2 (P1D-103) →1 (P1D-104) →1 (P1D-105) →1 (P1D-106) →1 (P1D-107) →4 (P1D-108) →2 (P1D-109) →2 (P1D-110) →1 (P1D-111) →2 (P1D-112) →0 (P1D-113 CLEAN) →1 (P1D-114 CRIT) →2 (P1D-115) →1 (P1D-116) →1 (P1D-117) →3 (P1D-118) →1 (P1D-119) →1 (P1D-120) →3 (P1D-121) →5 (P1D-122) →3 (P1D-123) →2 (P1D-124) →1 (P1D-125) →0 (P1D-126 CLEAN) →0 (P1D-127 CLEAN) →0 (P1D-128 CLEAN — CONVERGED on pre-expansion perimeter) →[D21 expansion burst 216: 5 subsystems (40 to 80 new behavioral-contract files, estimated) ~3 ADRs +2-3 crates; 0/3 RESET] →12 (P1D-129, expanded-perimeter pass 1, NOT CLEAN: 3H/7M/2L) →9 (P1D-130, expanded-perimeter pass 2, NOT CLEAN: 1C/3H/2M+1PG/3L) →7 (P1D-131, expanded-perimeter pass 3, NOT CLEAN: 1C/3H/3M) →8 (P1D-132, expanded-perimeter pass 4, NOT CLEAN: 4H/1M/3L) →[D23 expansion burst 228: per-tool HITL hook + rolling compaction + CAP-017/CAP-018 Wave-1 + first-party tools; 5 capabilities; 0/3 RESET; new perimeter] →10 (P1D-133, D21+D23 first pass, NOT CLEAN: 3H/5M/2L) →7 (P1D-134, D21+D23 second pass, NOT CLEAN: 0C/3H/1M/3L — anchor/propagation residue; fix-burst 234 COMPLETE) →6 (P1D-135, D21+D23 third pass, NOT CLEAN: 0C/2H/4M — §7 RTM CAP/DI mis-anchor [RTM never-opened surface] + DI-015 split-enforcement + events.md D23; fix-burst 235 COMPLETE) →6 (P1D-136, D21+D23 fourth pass, NOT CLEAN: 0C/3H/2M/1L — crate/module placement-marker class incl. compile-impossible core→graph circular dep [F-P136-03]; fix-burst 236 COMPLETE) |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |
| Adversary pass-125 complete; fix burst 128 complete | complete | 2026-07-19 | 2026-07-19 | counter 0/3 (P125: NOT CLEAN 1M; F-P125-01 RESOLVED [MED VP-003 BC Traceability cell BC-2.13.004 Red Gate to Kani VP Seed]: VP-003 v1.1→v1.2) | trajectory-tail →5→3→2→1; 0/3 |
| Adversary pass-126 complete | complete | 2026-07-19 | 2026-07-19 | counter 1/3 STREAK ACTIVE (P126: CLEAN strict; no fix burst required) | trajectory-tail →3→2→1→0; 1/3 |
| Adversary pass-127 complete | complete | 2026-07-19 | 2026-07-19 | counter 2/3 STREAK ACTIVE (P127: CLEAN strict; no fix burst required) | trajectory-tail →2→1→0→0; 2/3 |
| Phase 1d cascade CLOSED | complete | 2026-07-19 | 2026-07-19 | pass-128 CLEAN(strict)/CLEAN(PR-merge) — 3/3 CONVERGED; BC-5.39.001 3-CLEAN satisfied on frozen HEAD 02d8ccd; CASCADE CLOSED | trajectory tail →1→0→0→0; 3/3 CONVERGED |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/v1.0.0-greenfield/burst-log.md. (Bursts 194–201 archived burst-206; burst-202 archived burst-207; burst-203 archived burst-208; burst-204 archived burst-209; burst-205 archived burst-210; burst-206 archived burst-211; burst-207 archived burst-212; burst-208 archived burst-213; burst-209 archived burst-214; burst-210 archived burst-215; burst-211 archived burst-216; burst-212 archived burst-217; burst-213 archived burst-218; burst-214 archived burst-219; burst-215 archived burst-220; burst-216 archived burst-222; burst-217 archived burst-223; burst-218 archived burst-224; burst-220 archived burst-225; burst-223 archived burst-227; burst-224 archived burst-229; burst-225 archived burst-230; burst-226 archived burst-231; burst-227 archived burst-232; burst-229 archived burst-233; burst-230 archived burst-234; burst-231 archived burst-236.) -->
| Step | Agent | Status | Output |
|------|-------|--------|--------|
| Burst 232 — D23 VP layer + ADR-010 v1.3 + PO micro-fix COMPLETE: VP-011/012/013 v1.0 minted; VP-INDEX v1.5 (13 VPs); ARCH-INDEX v1.8; verification-architecture v2.1; verification-coverage-matrix v2.0; ADR-010 v1.3; BC-2.23.001/003/005 v1.1; hash sweep STALE=0; burst-227 row archived | architect + product-owner + state-manager | COMPLETE | VP-011.md v1.0 (Kani P0, graph::hitl). VP-012.md v1.0 (Kani P1, core-budget). VP-013.md v1.0 (Kani P1, tools-shell). VP-INDEX v1.5 (13 VPs). ARCH-INDEX v1.8. verification-architecture v2.1. verification-coverage-matrix v2.0. ADR-010 v1.3 (TOOLS component 17). BC-2.23.001/003/005 v1.1 (Category→VAL). Hash sweep STALE=0 (specs/ 174 MATCH=174). Burst 232. |
| Burst 233 — P1D-133 fix-burst ALL AGENTS COMPLETE (F-P133-01..10 all closed; E-TOOLS-008/009 minted, census 107; BC-INDEX v2.2 triple 51/75/3; hash sweep 153 STALE=0; burst-229 row archived); 0/3. NEXT: P1D-134. | architect + BA + product-owner + state-manager | COMPLETE | F-P133-01 ADR-020 E-SANDBOX→E-TOOLS Decision 2+5 (v1.3→v1.4). F-P133-02 BC-2.16.001/002/003 P2→P1 Wave-1 (v1.5/v1.3/v1.2). F-P133-03 ARCH-INDEX stale contradiction resolved (v1.8). F-P133-04 BC-2.23.x I/O→TOOL + E-TOOLS-008 FileIoError (v1.2). F-P133-05 BC-2.23.x VALIDATION→VAL + E-TOOLS-009 InvalidRegexPattern minted (error-taxonomy v1.32). F-P133-06 verification-architecture stale VP-013 note resolved (v2.2). F-P133-07 module-decomposition VP anchor labels corrected; mitsuhiko attribution; E-TOOLS-009 (v1.17). F-P133-08 similar crate dtolnay→mitsuhiko (module-decomp v1.17). F-P133-09 VP-013 ADR-020 Decision 3 anchor added (v1.2; hash 629e0db). F-P133-10 BC-2.10.006 tokens_remaining_after rename (v1.1). CAP-036 minted; L2-INDEX v1.9; capabilities-p1-p2 v1.8; BC-INDEX v2.2; prd v1.10; interface-definitions v2.47; bc-authoring-plan v2.43; ADR-010 v1.5; VP-012 v1.1 (hash 344dbb8). Burst 233. |
| Burst 234 — P1D-134 fix-burst ALL AGENTS COMPLETE (F-P134-01..07 all closed; DI-015 minted; E-TOOLS-008 GrepTool gate #33 real; TVs 669→670; ADR-019 v1.2/ADR-020 v1.6; entities-graph v1.7; invariants v1.2; hash sweep 6 passes STALE=0; burst-230 row archived); 0/3. NEXT: P1D-135. | architect + BA + product-owner + state-manager | COMPLETE | F-P134-01 BC-2.23.006 E-TOOLS-008 OS-error gate #33 both-direction anchor (v1.1→v1.2; TV-006; TVs 669→670). F-P134-02 ADR-020 GrepTool label two-step normalize (v1.4→v1.6; BC-2.23.006). F-P134-03 BC-2.08.010 BC-2.05.004→BC-2.05.007 ×2 reference correction (v1.1→v1.2). F-P134-04 ADR-019 trigger_tokens_remaining→tokens_remaining_after Decision 3 step 5 (v1.1→v1.2); entities-graph sibling (v1.6→v1.7; hash 0dac18e). F-P134-05 BC-2.06.006 ADR-018 removed from traces_to+inputs (v1.0→v1.1; hash ee8a02b). F-P134-06 invariants.md DI-015 Subprocess Execution Timeout minted (v1.1→v1.2; enforcer BC-2.23.005; L2-INDEX v1.9→v1.10 census 14→15; BC-2.23.005 di_anchors [DI-014]→[DI-014,DI-015] v1.1→v1.2; hash 835edd0). F-P134-07 BC-2.10.006 compaction×PendingHumanApproval non-interaction invariant (v1.1→v1.2). Hash sweep: 6 passes, 384 files updated, STALE=0. VP-012 refreshed (d582172 → final stable hash). Burst 234. |
| Burst 235 — P1D-135 fix-burst ALL AGENTS COMPLETE (F-P135-01..06 all closed; DI-015 split-enforcement BC-2.13.002; TVs 670→671; universe 53→54; events.md v1.7; hash sweep 7 passes STALE=0); 0/3. NEXT: P1D-136. | architect + BA + product-owner + state-manager | COMPLETE | F-P135-01 prd.md §7 RTM 13-BC CAP anchors corrected (v1.10→v1.11). F-P135-02 prd.md §2+§7 DI cols DI-014 all 13 + DI-015 for BC-2.23.005; DI-008 unbacked citation removed. F-P135-03 BC-INDEX v2.3 BC-2.23.005 DI column (v2.2→v2.3). F-P135-04 prd.md §2.15 header + 3 SS-15 rows P2→P1. F-P135-05 ADR-020 v1.7 (tools::shell timeout wraps sandbox.execute()); module-decomposition v1.18 (+sandbox::process MEDIUM, universe 54); purity-boundary-map v1.12 (+sandbox::process Effectful Shell, 79 total); invariants.md v1.3 (DI-015 split-enforcement, co-enforcer BC-2.13.002); BC-2.13.002 v1.2 (DI-015 co-enforcement: kill_on_drop PC-6+INV-6; +kill-on-drop TV-5; hash 6c6933f); BC-2.23.005 v1.3 (tokio::process phrasing; hash 8c9a68b). F-P135-06 events.md v1.7 (+D23 StreamEvents 13/14/15; ToolApprovalRaised/Resolved+CompactionExecuted; ordering rules 7-8; decisions +D21,D23); L2-INDEX events-count ripple. test-vectors v2.4 (670→671; hash 56bdcb9). 2 API-error recoveries (BA events.md + PO prd §7). Hash sweep: 7 passes STALE=0. Burst 235. |
| Burst 236 — P1D-136 fix-burst ALL AGENTS COMPLETE (F-P136-01..05+OBS all closed; crate/module placement-marker class; circular-dep F-P136-03 fixed; PreToolDecision variants corrected; tokens_remaining_after Option<i64>; hash sweep STALE=0; burst-231 row archived); 0/3. NEXT: P1D-137. | architect + product-owner + state-manager | COMPLETE | F-P136-01 interface-definitions GuardedDocuments core::guardrail→core::retriever (v2.47→v2.48). F-P136-02 PreToolCallHook graph::approval→graph::hitl + pre_tool_dispatch→pre_invoke + run_ctx: &RunContext restored; purity-boundary-map v1.13 sibling (pre_invoke +run_ctx; hash 0cc61fd). F-P136-03 CompactionConfig/Policy/Trigger graph::budget→core::budget (compile-impossible circular-dep fix). F-P136-04 CompactionEvent.tokens_remaining_after u64→Option<i64>; BC-2.06.006 v1.2; BC-2.10.006 v1.3. F-P136-05 BC-2.05.004→BC-2.05.007 anchor + BC-2.05.007 v1.2 sole-authority + VP-011 OBS. OBS: BC-2.10.005 v1.1 VP-012 assigned prose. Bonus: PreToolDecision Deny{reason}/Edit{named}/PendingHumanApproval{prompt} variant-shape. Hash sweep: 4 transitive STALE=0. Burst 236. |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D-1–D-17, D18-P46-A–D18-P61-A | *Archived — see `.factory/planning/decisions-archive-pre-p1d.md`* | | pre-1 / phase-1d passes 46-61 | 2026-07-12 to 2026-07-18 | various |
| D18-P61-B | gate #31 near-name extension (step 4 widened): any UNRESOLVED type in a trait signature census must be checked against near-name corpus concepts; minting a new type name requires a near-name corpus search first (name-drift = HIGH). | F-P61-02 BudgetContext as near-name to RunContext | phase-1d | 2026-07-18 | adversary+PO |
| D18-P61-C | architect propagation: module-decomposition v1.3 adds core-definitions note (core/src/budget.rs hosts BudgetPolicy/PolicyDecision/TokenUsage/RunContext; graph::budget hosts dispatch [engine/journal]; guardrail-split precedent; no new criticality row, universe stays 33); ADR-009 v1.2 RunContext canon; BC-2.10.001..004 v1.1 anchors corrected. | F-P61-01 propagation via module-decomposition + BC anchors | phase-1d | 2026-07-18 | architect |
| D18-P62-A | xtask inventory = non-exhaustive + authoritative pointer (BCs BC-2.14.003-006/BC-2.08.007 + ADRs are the lint-gate registry; naming variants across sources (e.g. `deny-expect-in-lib` / `lint-no-panic` for the same NE-07 gate) are resolved at implementation time against the governing BC or ADR, not this inventory). deny-anyhow-in-lib + deny-description-cache-key added. Universe stays 33. | F-P62-01 via gate #32 first run | phase-1d | 2026-07-18 | adversary+architect |
| D18-P63-A | Fuzz-target canon: BC-2.17.002 defines exactly TWO cargo-fuzz targets (fuzz_checkpoint_serde, fuzz_graph_execution); splitter robustness = proptest + GTV Red Gate (BC-2.07.002) in v1; any post-v1 fuzz addition updates BC + coverage-matrix in the same burst. | F-P63-01: verification-architecture was the outlier vs BC + matrix | phase-1d | 2026-07-18 | adversary+architect |
| D18-P64-A | Default port 7437 mandated (server.port in ferrochain-server.toml); api-surface "no default" claim retired; interface-definitions §Base URL + config schema are the port authority. | F-P64-01 | phase-1d | 2026-07-18 | adversary+architect |
| D18-P64-B | Supplement body-changelog date monotonicity = mandatory check on every supplement-changelog edit (newest-at-top non-increasing; ≤ frontmatter timestamp). Root cause: F-P36-03 edits future-dated by 2 days in two files. | F-P64-02 | phase-1d | 2026-07-18 | adversary+PO |
| D18-P65-A | Gate #28 extended with Rule 4 TEMPORAL-NEIGHBOR SWEEP + Rule 5 FRONTMATTER-CURRENCY. Machine enforcement DEFERRED to Phase 3 CI hardening — logged as DEFER-002. bc-authoring-plan → v2.16. | F-P64-02 + F-P65-01: sweeps that don't enumerate the sibling set leave residue | phase-1d | 2026-07-18 | adversary+PO |
| D18-P66-A | E-SERVER-005 tombstoned — CORS denial = silent header-omission per BC-2.12.005 (no 403, no error body; removed from 403 row; disposition census 78 = 44+11+23; error-taxonomy v1.9; interface v2.17). | F-P66-03 HIGH — CORS rejection contradicted BC-2.12.005's silent denial canon | phase-1d | 2026-07-18 | adversary+PO |
| D18-P66-B | E-CHKPT-003 home = BC-2.04.005 EC-006+TV-008; E-MCP-003 re-anchored BC-2.09.001 EC-006/TV-008. | F-P66-02 + F-P66-01 orphan taxonomy codes given BC anchor homes | phase-1d | 2026-07-18 | adversary+PO |
| D18-P66-C | GATE #33 minted — taxonomy anchor reverse-verification; post-fix census 78/78 anchored; bc-authoring-plan v2.7. | OBS-P66-1 [process-gap]: forward+reverse traceability both now gated (#30 forward, #33 reverse) | phase-1d | 2026-07-18 | adversary+PO |
| D18-P67-A | Gate #21 cross-row routing-enumeration completeness sub-check: any code added/removed from a status row requires in-burst sweep of every other row's enumerations referencing that row. | F-P67-01: E-CHKPT-007 500-row add never propagated to the 422-row enumeration | phase-1d | 2026-07-18 | adversary+PO |
| D18-P69-A | Range notation banned in HTTP status rows — explicit enumeration required; gate #20 gains INTERNAL→500 axis + range-expansion rule. Census 78 = 43+12+23. | F-P69-01: range shorthand hid a category mismatch from every membership census | phase-1d | 2026-07-19 | adversary+PO |
| D18-P70-A | Gate #32 ADR-propagation scope INCLUDES gate enforcement commands in bc-authoring-plan. Gate #27 = budget-split rule + core/budget carve-out + positive assertion. | F-P70-01: pass-61 updated carriers but not the enforcement command | phase-1d | 2026-07-19 | adversary+PO |
| D18-P70-B | Gate #29 scope INCLUDES taxonomy notes referencing interface-definitions row content. 401 note = categorical-fallback phrasing. | F-P70-02: P25-accurate note went stale at P26 | phase-1d | 2026-07-19 | adversary+PO |
| D18-P72-A | SkillStore public API is name-keyed + tag-filtered (fn get_skill(name: &str) → Skill + fn list_skills(tag: Option<&str>) → Vec<SkillRef>). interface-definitions v2.22 corrected. | F-P72-01 HIGH: SkillStore (namespace,key)-keyed vs BC/ADR name-keyed+tag-filtered | phase-1d | 2026-07-19 | adversary+architect |
| D18-P72-B | Replace.old_value type = Option<Value> (not Value). None = unconditional replace; Some(v) = match-based replace. interface-definitions v2.22. | F-P72-02 MED: Replace old_value bare Value vs conditional-replace semantics | phase-1d | 2026-07-19 | adversary+PO |
| D18-P72-C | memory::skills has no criticality row in either registry. Criticality governed by ferrochain-memory row (MEDIUM/HIGH split per write_guard). | OBS-P72 gate #32 review: memory::skills not in either registry | phase-1d | 2026-07-19 | adversary+PO |
| D18-P72-D | ADR-013 is the sole authority for mcp::server placement decisions. Final universe = 35 = ADR-012 scope (34) + mcp::server via ADR-013. ARCH-INDEX v1.8. | F-P72-02 HIGH: mcp::server falsely attributed to ADR-012; ADR-013 minted to close the attribution gap | phase-1d | 2026-07-19 | adversary+architect |
| D18-P74-A | Gate #19 census command extended with retired shared-type names; whole-tree traversal now covers interface-definitions.md on the retired-spelling axis. | F-P74-01 twin in interface-definitions survived because no census covered it | phase-1d | 2026-07-15 | adversary+PO |
| D18-P75-A | Gate #28 extended with Rule 4 TEMPORAL-NEIGHBOR SWEEP + Rule 5 FRONTMATTER-CURRENCY. bc-authoring-plan → v2.16. | F-P75-01: 3rd recurrence of future-dated-changelog class; manual gate #28 sweep demonstrably insufficient | phase-1d | 2026-07-15 | adversary+PO |
| D18-P77-A | "ADR-012 DI-001" renamed → "ADR-012 INV-1"; propagated to BC-2.15.006 v1.1 + capabilities-p1-p2 v1.2; zero live "ADR-012 DI-001" residue. | OBS-P77-C: DI-001 globally = BSP Reducer Determinism; ADR-local squatting creates reference ambiguity | phase-1d | 2026-07-15 | adversary+architect |
| D18-P77-B | Gate #33 SEMANTIC-AGREEMENT sub-check steps 7–10: taxonomy Message Format template + raise-condition annotation must agree with anchor BC message text + EC/TV predicates; BC wins on any divergence; bc-authoring-plan → v2.17. | F-P77-01 survived name/presence-only gates #20+#33 — semantic axis was ungated | phase-1d | 2026-07-15 | adversary+PO |
| D18-P78-A | Universal `<ErrorName>: <message-prefix>` message-prefix convention wins over BC message bodies lacking it; 12 contract files lacked prefix corrections applied. | F-P78-04 + gate #33 first full sweep — previously implicit convention; 12 contract files lacked prefix | phase-1d | 2026-07-15 | adversary+PO |
| D18-P78-B | Gate #33 step 11 added: omission-note anchor citations in interface-definitions must point at a raising PC/EC; success-path citations are violations; plan v2.18. | F-P78-02/03 copy-paste success-path citations survived all prior passes; no gate checked citation semantics | phase-1d | 2026-07-15 | adversary+PO |
| D18-P84-A | Body citations to living supplements use section anchors only — no version pins; changelog pins exempt. Stale version pins removed from BC-2.11.002/003/004 bodies. | OBS-P84-B: stale version pins in SS-11 BC bodies survived all prior passes | phase-1d | 2026-07-15 | adversary+PO |
| D18-P86-A | Gate #28 Rule 5 (FRONTMATTER-CURRENCY) scoped by document type: supplement — `timestamp:` must equal newest changelog date; BC files — `timestamp:` frozen at v1.0 authoring date. bc-authoring-plan → v2.19. | F-P86-02 [process-gap]: Rule 5 as written contradicted consistent BC-corpus convention | phase-1d | 2026-07-16 | adversary+PO |
| D18-P87-A | Gate #28 Rule 1 scoped to supplement documents only (BC files exempt per D18-P86-A); 5-rule decision tree keyed on `introduced:` presence; bc-authoring-plan → v2.20. | F-P87-01: D18-P86-A Rule-5 scoping created a live Rule-1 contradiction one layer up | phase-1d | 2026-07-17 | adversary+PO |
| D18-P87-B | Input-hash canonical format = 7-char truncated MD5 for ALL spec artifacts; gate #34 minted (INPUT-HASH FORMAT CONSISTENCY); corpus normalized — all 95 BC files + all 6 supplements (100%). bc-authoring-plan → v2.22. | F-P87-02: 3-format split was oscillating without a declared canon; tool is deterministic authority | phase-1d | 2026-07-17 | adversary+PO |
| D18-P88-A | Live/mutable files under state-manager authority must NOT appear in any spec artifact's frontmatter `inputs:` list. INTERPRETATION (burst 170): versioned changelog-bearing spec indexes (ARCH-INDEX, L2-INDEX) ARE legitimate inputs. Corpus closure: 30 files total. | burst-168 process note: STATE.md-as-input re-drifted nfr-catalog/module-criticality hashes on every state write | phase-1d | 2026-07-17 | orchestrator+PO+BA+architect |
| D18-P89-A | END-OF-BURST HASH-CURRENCY SWEEP: every state-manager burst commit is preceded by a corpus-wide input-hash census; any file staled by the burst's edits gets `compute-input-hash --update` in the SAME commit. | F-P89-01/02/03: bursts 168-170 updated primary fields but not siblings; 94/95 behavioral-contract files + 4/6 supplements staled silently | phase-1d | 2026-07-17 | adversary+PO+state-manager |
| D18-P90-A | Mechanical hash-only refreshes are state-manager-executable corpus-wide under the D18-P90-A standing sweep. D18-P90-A sweep scope EXTENDED: refresh ALL files whose `inputs:` lists reference an edited file (transitive, until census TOTAL MATCH). | burst-172 verify census: ARCH-INDEX.md staled by burst-171 PO-scope sweep; authority split created blind spot | phase-1d | 2026-07-17 | orchestrator+state-manager |
| D18-P91-A | on_ceiling canon: BudgetConfig struct owns on_ceiling/soft_limit/hard_limit; BudgetPolicy trait stays pure+data-free (evaluate() only); OnCeiling + BudgetConfig defined in interface-definitions §BudgetPolicy. | F-P91-01/02/03: SS-10 trio + CAP-012 attributed a data field to a pure trait; interface surface was incomplete | phase-1d | 2026-07-17 | adversary+architect+PO+BA |
| D18-P91-B | E-MEMORY-008 MemoryStoreReadFailed minted (DURABILITY/broken/Maybe; anchor BC-2.15.004 EC-004+TV-008). Error-code census 85→86 = 43+16+27. | F-P91-04: MEMORY namespace had no read/IO-failure code; StorageFull was semantically wrong for reads | phase-1d | 2026-07-17 | adversary+PO |
| D18-P92-A | RunnableConfig gains `budget_config: Option(BudgetConfig)` — per-run override, None = inherit GraphConfig::budget_config; §RunnableConfig struct now fully defined in interface-definitions v2.32 (4 fields). | F-P92-02: resume-path sites named RunnableConfig as ceiling-patch target but field was undefined | phase-1d | 2026-07-17 | adversary+architect+PO+BA |
| D18-P93-A | Model A HITL trigger canon: PolicyDecision::Escalate ALWAYS fires HITL unconditionally; PolicyDecision::Deny branches on on_ceiling. Complete 5-row decision table in interface-definitions v2.33 §OnCeiling. | F-P93-02: three-way contradiction; Model A chosen: BC-2.10.001 PC3 is sole Escalate canon | phase-1d | 2026-07-17 | adversary+architect+PO |
| D18-P93-B | Cost-based ceilings are NOT v1 scope; CAP-012 is fully satisfied by JournalEntry.token_usage.estimated_cost (read-only cost tracking only); no E-BUDGET cost-ceiling enforcement codes in v1. | F-P93-01 fix: entities-server v1.7 rewrite revealed cost_ceiling_usd was an invented field | phase-1d | 2026-07-17 | adversary+PO |
| D18-P99-A | ADD StreamEvent::GuardrailDecision (12th variant; Fail/Transform only, Pass not streamed); ToolEnd carries POST-guardrail content; GuardrailDecision fires BEFORE ToolEnd (ToolResult). | F-P99-01: SS-06↔SS-11 observability seam — no gate covers cross-BC behavioral-observability contracts | phase-1d | 2026-07-17 | adversary+architect+PO+BA |
| D18-P102-A | Gate #28 Rule 6 VERSION-MONOTONICITY minted; first census: 14 total transposed files repaired. bc-authoring-plan v2.30→v2.31. total_standing_gates stays 34. | F-P102-01 + F-P97-03 + F-P101-02 recurrence; manual spot-checks demonstrably insufficient for a 124-file corpus | phase-1d | 2026-07-17 | adversary+PO+orchestrator |
| D18-P103-A | Gate #28 Rule 6 census rewritten to five-class hook-aligned direction-asserting model. Corpus re-run: 27 Form-A contract files corrected desc→asc; 7 arch Form-A files corrected asc→desc. bc-authoring-plan v2.31→v2.32. total_standing_gates stays 34. | F-P103-01 + OBS-P103-A: burst-184 Rule 6 "BCs+architecture ascend" was partly wrong — hook source audit revealed architecture/ is hook-enforced desc | phase-1d | 2026-07-18 | adversary+PO+orchestrator |
| D21 | Ecosystem-Parity v1 Scope Expansion (human directive, 2026-07-20): ALL FIVE previously-excluded/partially-covered langchain-core subsystems promoted to v1 scope. | Ecosystem parity + library-consumer completeness | Phase 1 | 2026-07-20 | human+orchestrator |
| D22 | Domain E Holdout: ferrochain must be capable of building an agentic coding assistant (Claude Code / Codex clone pattern). Brief COMPLETE burst 228; D-23 scope expansion APPROVED. | Human directive 2026-07-21. | Phase 1 | 2026-07-21 | human+orchestrator |
| D-23 | Domain E Full-Parity v1 Scope Expansion. FULL PARITY EXPANSION: HITL hook + compaction + CAP-017/018 Wave-1 + first-party tools. Architecture-first per D21 precedent. | Human reviewed 0 forced gaps, 5 degraded; chose full-5. | Phase 1 | 2026-07-22 | human+orchestrator |

## Risk Register

<!-- Resolved risks R1–R5, R7, R9 archived to cycles/v1.0.0-greenfield/blocking-issues-resolved.md. Open risks only. -->
| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R6 | crates.io names verified available; publish-all.sh prepped — human has NOT yet run it. Roster finalized at 21 crates; publish-all.sh must be regenerated. | High | pre-1 | Pending human action: `cargo login` + regenerate publish-all.sh for 21 crates + run |
| R8 | Splitters code-point vs byte-length parity: upstream `len()` calls on text are code-point counts. NOT covered by any upstream test. | High | Phase 1/3 | CRITICAL parity risk. Route to product-owner at Phase 1. |
| R10 | Upstream coverage gap: NamedBarrierValue has NO dedicated unit test. EphemeralValue only 3 assert lines. | Medium | Phase 1 | Route to product-owner at Phase 1 |
| R11 | MCP upstream test voids: (1) mcp bare-ToolException re-raise path untested; (2) mcp `__aenter__` NotImplementedError contract untested. | Medium | Phase 1/3 | Route to product-owner at Phase 1 |
| R12 | D21 scope expansion introduces largest single scope delta (~9,600 ref LOC, 5 subsystems). Risk: re-convergence cost + new attack surface. | High | Phase 1 (re-convergence) | Architecture-first: injection-safety ADR + deserialization-safety ADR before BC authoring |
| R13 | D-23 scope expansion: second scope delta during Phase 1d re-convergence. D23 authoring COMPLETE (burst 232). 0/3 streak continues on new larger perimeter. | High | Phase 1 (re-convergence) | D23 authoring COMPLETE; P1D-136 CLOSED fix-burst 236 (all 6); crate/module placement-markers + circular-dep; 0/3 AWAITING P1D-137. Owner: orchestrator |

## Skip Log

| Step | Skipped? | Justification |
|------|----------|---------------|
| Phase 0: Codebase Ingestion | yes | Greenfield — no existing Rust codebase to ingest. Replaced by semport-analyze of Python reference corpus. |

## Blocking Issues

| ID | Issue | Severity | Blocking Phase | Owner | Resolution |
|----|-------|----------|----------------|-------|------------|
| B1 | direnv not allowed — .envrc present but unenabled; 4 AWS/Anthropic key names declared | Low | pre-1 | human | Run `direnv allow .` from project root |

## Drift / Deferrals
| ID | Item | Target | Reason |
|----|------|--------|--------|
| DEFER-002 | Machine enforcement of gate #28 date-validity | Phase 3 CI hardening | 3rd manual-sweep failure (F-P64-02/F-P65-01/F-P75-01); gate #28 Rules 4+5 prose-only until Phase 3. |
## Concurrent Cycles
None active (D23 authoring COMPLETE bursts 229-232; burst-236 fix-burst COMMITTED; 0/3 AWAITING adversary cascade P1D-137 on D21+D23 expanded perimeter). Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md.
## Convergence Status
Counter: 0/3 RESET — P1D-136 NOT CLEAN (6 findings: 0C/3H/2M/1L); fix-burst 236 COMPLETE (all 6 closed); 136 passes total, 136 fix bursts total (128 pre-D21 + 8 post-D21+D23). Full metrics: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Session Resume Checkpoint
<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v1.0.0-greenfield/session-checkpoints.md. -->
### RESUME IN ONE BREATH
"ferrochain Phase 1 REOPENED by D21+D-23 scope expansion. D23 authoring COMPLETE (bursts 229-232). Burst-236 fix-burst ALL AGENTS COMMITTED to factory-artifacts. All 6 P1D-136 findings closed. Primary class: crate/module placement-markers on D21/D23 trait blocks (F-P136-01..03); compile-impossible core→graph circular dep fixed (F-P136-03: CompactionConfig/Policy/Trigger graph::budget→core::budget); PreToolCallHook graph::hitl+pre_invoke+run_ctx restored; purity-boundary-map v1.13; interface-definitions v2.48; tokens_remaining_after Option<i64>; PreToolDecision variant-shape corrected; hash sweep STALE=0; trajectory-tail →10→7→6→6; 0/3. NEXT: adversary pass P1D-137 on FROZEN HEAD (D21+D23 expanded perimeter)."
### COMMITTED (through burst 236):
- Burst 236 (last committed): P1D-136 fix-burst: interface-definitions v2.48; purity-boundary-map v1.13 (hash 0cc61fd); BC-2.05.007 v1.2; BC-2.10.005 v1.1; BC-2.06.006 v1.2; BC-2.10.006 v1.3; sidecar-learning.md; hash sweep 4 transitive STALE=0.
### NEXT-ACTIONS (exact, ordered):
1. Adversary pass P1D-137 on FROZEN HEAD (D21+D23 expanded perimeter; full scope; streak 0/3).
2. PRIORITY COVERAGE NOTE per P1D-136 coverage statement: census axes still not fully recounted — 129-BC 51/75/3 split, 671 TV count, 38 CAP count, 15-DI orphan sweep, 20-ADR/21-crate/54-module full recount, 23 groups, SS-01..04 core BC bodies line-by-line. These are priority targets for P1D-137.
3. After 3/3 CLEAN(strict): /vsdd-factory:check-input-drift → fresh consistency audit → Phase 1 HUMAN GATE.
### PENDING: B1 direnv allow; R6 publish-all.sh REGENERATE for 21 crates; #[non_exhaustive] gate (Phase 3).
### HEADS: develop d018d3f (clean, pushed). factory-artifacts: burst-236 commit (see git -C .factory log -1).
### WRAP METADATA: Date 2026-07-22 | Cycle v1.0.0-greenfield | Burst 236 | Phase 1 IN PROGRESS — burst-236 COMMITTED; NEXT: P1D-137 | NEXT: adversary cascade P1D-137

## Historical Content
| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–74 + archived bursts 171–236) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| 129 Behavioral Contracts + BC-INDEX.md v2.3 COMPLETE: 129 total = 51 P0 / 75 P1 / 3 P2 | `.factory/specs/behavioral-contracts/ss-NN/` + `BC-INDEX.md` |
| L3 PRD v1.11 COMPLETE | `.factory/specs/prd.md` |
| PRD supplements: bc-authoring-plan v2.43, error-taxonomy v1.32 (107 codes; E-TOOLS-001..009 minted), nfr-catalog v1.4, module-criticality v1.5, interface-definitions v2.48, test-vectors v2.4 (671 TVs), api-surface v1.7, product-brief v1.4, observability.md v1.1 | `.factory/specs/prd-supplements/` |
| L2 domain spec (15-shard) — L2-INDEX v1.10 (38 CAPs; DI-015 minted, 15 invariants); capabilities-p1-p2 v1.8; entities-graph v1.7; events.md v1.7; ubiquitous-language-core v1.6 | `.factory/specs/domain-spec/L2-INDEX.md` (+ 14 section shards) |
| Validation report archive (passes 1–10, 3,478 lines) | `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` |
| Session checkpoints bursts 5–78, bursts 176–235 pre-commit (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (24 lessons, 24 codified guardrails) | `cycles/v0.0.0-pre-pipeline/lessons.md` + `cycles/v1.0.0-greenfield/lessons.md` |
| Holdout domain briefs A–E | `.factory/planning/holdout-domains/domain-{a,b,c,d,e}-*.md` |
| Reference corpus manifest (v1.4.0) | `.factory/semport/reference-manifest.md` |
| Semport pass 1 analysis state | `.factory/semport/core/ANALYSIS-STATE.md` |
| D16 comparative assessment | `.factory/comparative/COMPARATIVE-ASSESSMENT.md` (+ `assessment-parts/`) |
| Architecture core: ARCH-INDEX v1.8 + 9 section files (module-decomposition v1.18, purity-boundary-map v1.13, verification-architecture v2.2, verification-coverage-matrix v2.0) + ADRs 006 rev-4 + 005 rev-4 + 010..020 (ADR-014 v1.5/ADR-015 v1.4/ADR-016 v1.2/ADR-017 v1.2/ADR-018 v1.1/ADR-019 v1.2/ADR-020 v1.7; ADR-010 v1.5), 20 ADRs | `.factory/specs/architecture/` + `decisions/` |
| VP-INDEX v1.5 + VP-001..013 (VP-001..005 original; VP-006..010 D21 expansion; VP-011..013 D23 expansion: VP-011 Kani P0 hitl/VP-012 v1.1 Kani P1 core-budget/VP-013 v1.2 Kani P1 tools-shell; input-hashes refreshed burst-236) | `.factory/specs/verification-properties/` |
| DTU assessment (DTU_REQUIRED: true; 3 cassette clone sets) — v1.0 | `.factory/planning/dtu-assessment.md` |
| ADR tech validation (similar 3.1.1, regex 1.13.1; mustache/fuzzy-matcher REJECTED) — v1.2.0 | `.factory/planning/adr-tech-validation.md` |
| Module criticality assessment (41 modules, v1.5) | `.factory/specs/module-criticality.md` |
| CI/CD setup log | `.factory/planning/cicd-setup.md` |
