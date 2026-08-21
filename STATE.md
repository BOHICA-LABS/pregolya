---
document_type: pipeline-state
level: ops
version: "5.38"
status: in-progress
producer: state-manager
timestamp: "2026-08-21T16:03:00Z"
phase: 2
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: pregolya
mode: greenfield+semport
current_step: "P2A-020 fix-burst COMPLETE (D-226; 2026-08-21): NOT CLEAN (1M/1L) ALL CLOSED — scheduler.rs ownership model established; 5 new DAG edges; Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts. P2A-018/019 CLEAN(strict) streak 1/3→2/3; streak RESET 0/3 by P2A-020. trajectory-tail →3→0→0→2. NEXT: P2A-021 on post-fix-burst HEAD."
current_cycle: v1.0.0-greenfield
convergence_status: "Phase-1 CLOSED (burst-325; D-197; 2026-08-18). 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195). Phase 2 IN PROGRESS: per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..020 (sample) fix-bursts COMPLETE. P2A-018 CLEAN(strict) streak 1/3; P2A-019 CLEAN(strict) streak 2/3; P2A-020 NOT CLEAN (1M/1L; D-226; fix-burst COMPLETE 2026-08-21) streak RESET 0/3. NEXT: Phase-2 adversarial P2A-021. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md."
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "DIRECTIVE 1 (2026-07-13): Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes. DIRECTIVE 2 (2026-07-29): fix-in-scope is the DEFAULT posture; deferral requires explicit per-case human permission; CLAUDE.md Canonical Principle Rule 3 UNCHANGED. Agents may NOT self-authorize deferrals. Orchestrator may PROPOSE deferrals but default action is to fix."
---

<!-- STATE.md SIZE BUDGET: 197 lines (wc-l) | margin from soft-target (200L): 3 lines | margin from actual: 0 lines | compact-state v5.38 (2026-08-21): P2A-020 fix-burst COMPLETE (D-226). P2A-018/019 CLEAN; P2A-020 streak-reset. NEXT: P2A-021. -->

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
| **Last Updated** | 2026-08-21 — compact-state v5.38; P2A-020 fix-burst COMPLETE (D-226); P2A-018/019 CLEAN(strict) streak 1/3→2/3; P2A-020 1M/1L ALL CLOSED; streak RESET 0/3; scheduler.rs ownership model; trajectory-tail →3→0→0→2. NEXT: Phase-2 adversarial P2A-021. |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | COMPLETE | 2026-07-14 | 2026-08-18 | 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195); input-hash drift resolved (D-196); Phase-1 gate CLOSED (D-197; burst-325). ~215 adversarial passes total. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md | trajectory-tail →1→0→0→0; 3/3 CONVERGED |
| 2: Story Decomposition | IN PROGRESS | 2026-08-18 | | Structural decomp COMPLETE (D-198); per-story authoring COMPLETE 39/39 D-199..D-206 (sample); holdout scenarios COMPLETE 14/14 (D-207; SEALED). P2A-001..020 (sample) fix-bursts COMPLETE D-208..D-226 (sample). NEXT: P2A-021. | trajectory-tail →3→3→0→0→2; 0/3. NEXT: P2A-021. |
| 2: passes P2A-012..P2A-016 + fix-bursts (COMPRESSED) | COMPLETE | 2026-08-20 | 2026-08-21 | P2A-012..016 + fix-bursts ALL COMPLETE (D-219..D-224). 17 findings (2H/7M/7L/1OBS) all closed: mod.rs-logic ×4 (P2A-012); target_module/BC-priority/DAG S-1.16→S-1.13 (P2A-013); Wave-2 target-crate sweep (P2A-014); D17-Q5 SDK-split corpus-wide (P2A-015); dep-graph 10-batch canonical (P2A-016). Census 133 BC/14 VP. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md. | compressed; detail in trajectory |
| 2: adversary pass-17 (P2A-017) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 3 findings (2M/1L); fix-burst dispatched (D-225). P2A017-01 (MED,POL-6/24) SS-10 Primary Crate(s) omitted pregolya-core; added. P2A017-02 (MED,POL-6/4) SS-06 StreamEvent CORE canonical per ADR-006 §Consequences; graph::event_emitter rescoped; S-1.17 triad synced. P2A017-03 (LOW) SS-08 core::tool scope confirmed correct; scope note added. EXHAUSTIVE SWEEP: all 23 SS rows verified; only SS-10 fixed (POL-24 satisfied). | trajectory-tail →3→5→3→5→3; 0/3 (NOT CLEAN; streak 0/3) |
| 2: fix burst (post-pass-17 P2A-017) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-017: all 3 findings closed (D-225); SS-10 Primary Crate(s) +pregolya-core; module-decomposition graph::event_emitter emission-only rescope; S-1.17 target_module→[pregolya-core,pregolya-graph] + core::events entry + AC-001 re-trace; ARCH-INDEX updated; module-decomposition updated; 23-SS Primary-Crate sweep exhausted class. Census 133 BC / 14 VP. Streak 0/3. NEXT P2A-018. | trajectory-tail →5→3→5→3→3; 0/3 → NEXT P2A-018 |
| 2: adversary pass-18 (P2A-018) | COMPLETE | 2026-08-21 | 2026-08-21 | CLEAN(strict)=YES CLEAN(PR-merge)=YES; 0 findings; streak 1/3. All prior fixes HELD; no new-dimension findings found. | trajectory-tail →3→3→0; streak 1/3 |
| 2: adversary pass-19 (P2A-019) | COMPLETE | 2026-08-21 | 2026-08-21 | CLEAN(strict)=YES CLEAN(PR-merge)=YES; 0 findings; streak 2/3. All prior fixes HELD. | trajectory-tail →3→0→0; streak 2/3 |
| 2: adversary pass-20 (P2A-020) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 2 findings (1M/1L); streak RESET 0/3; fix-burst dispatched (D-226). F-P2A020-01 (MED,POL-4/46) scheduler.rs ownership conflict; 4 stories inconsistent/false claims. F-P2A020-02 (LOW) S-1.16→S-1.13 rationale absent. | trajectory-tail →0→0→2; streak RESET 0/3 |
| 2: fix burst (post-pass-20 P2A-020) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-020: all 2 findings closed (D-226). F-P2A020-01 CLOSED: scheduler.rs ownership model (S-1.15 creates; S-1.17 run/stream; S-1.13/S-1.18/S-1.16 layer); 5 new DAG edges; Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts. F-P2A020-02 CLOSED: S-1.16→S-1.13 rationale documented. Census 133 BC/14 VP; DAG acyclic. Streak 0/3. NEXT P2A-021. | trajectory-tail →0→0→2; 0/3 → NEXT P2A-021 |
| 3: TDD Implementation | not-started | | | | — |
| 4: Holdout Evaluation | not-started | | | | — |
| 5: Adversarial Refinement | not-started | | | | — |
| 6: Formal Hardening | not-started | | | | — |
| 7: Convergence | not-started | | | | — |

## Current Phase Steps

<!-- Keep last 5 rows only. Older rows archived to cycles/v1.0.0-greenfield/burst-log.md. -->
| Step | Agent | Status | Output |
|------|-------|--------|--------|
| P2A-017 fix-burst (2026-08-21) — 3 findings closed (2M/1L): SS-10 Primary Crate(s) +pregolya-core; module-decomposition graph::event_emitter emission-only rescope + SS-06 StreamEvent CORE canonical (ADR-006 §Consequences); S-1.17 target_module→[pregolya-core,pregolya-graph] + core::events File Structure + AC-001 re-trace; ARCH-INDEX updated; module-decomposition updated; 23-SS Primary-Crate sweep exhausted class. D-225 minted. | state-manager | COMPLETE | ARCH-INDEX + module-decomp + 3 story-writer files + STATE.md + trajectory. Census 133 BC / 14 VP. Streak 0/3. NEXT: P2A-018. |
| P2A-018 CLEAN pass (2026-08-21) — 0 findings. CLEAN(strict)=YES CLEAN(PR-merge)=YES; all P2A-001..017 fixes HELD. Streak advances 0/3→1/3. | vsdd-factory:adversary | COMPLETE | 0 findings. Streak 1/3. |
| P2A-019 CLEAN pass (2026-08-21) — 0 findings. CLEAN(strict)=YES CLEAN(PR-merge)=YES; all prior fixes HELD. Streak advances 1/3→2/3. | vsdd-factory:adversary | COMPLETE | 0 findings. Streak 2/3. |
| P2A-020 NOT CLEAN pass (2026-08-21) — 2 findings (1M/1L). F-P2A020-01 (MED,POL-4/46) scheduler.rs ownership — 4 stories mutually-inconsistent incl. false claims. F-P2A020-02 (LOW) S-1.16→S-1.13 rationale absent. Streak RESET 0/3. D-226 minted. Fix-burst dispatched. | vsdd-factory:adversary | COMPLETE | 2 findings. Streak RESET 0/3. |
| P2A-020 fix-burst (2026-08-21) — all 2 findings closed (D-226). F-P2A020-01 CLOSED: scheduler.rs ownership model (S-1.15 creates; S-1.17 run/stream; S-1.13/S-1.18/S-1.16 layer); 5 new DAG edges (S-1.17 dep S-1.15; S-1.13/S-1.18/S-1.16 dep S-1.17; S-1.16 dep S-1.18); Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts. F-P2A020-02 CLOSED: S-1.16→S-1.13 rationale documented via PSI rows. D-221 S-1.16↔S-1.13 CONFIRMED. | state-manager | COMPLETE | 8 files + STATE.md + trajectory. Census 133 BC/14 VP. DAG acyclic. Streak 0/3. NEXT: P2A-021. |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D-1–D-17, D18-P46-A–D18-P93-B | *Archived — see `.factory/planning/decisions-archive-pre-p1d.md`* | | pre-1 / phase-1d passes 46-93 | 2026-07-12 to 2026-07-17 | various |
| D18-P99-A–D-55 | *Compressed — 38 rows in git history. Key: StreamEvent::GuardrailDecision 12th variant; ecosystem-parity + Domain-E expansion (D21–D23); ActionRisk/ToolConfig/DynTool/as_retriever API canon; TD-VSDD-091 enforcement. `git log --oneline --follow -- .factory/STATE.md`.* | | phase-1d + Phase 1 | 2026-07-17 to 2026-07-28 | various |
| D-56..D-74 (sample) | *Compressed — 19 rows in git history. Key: D-61 SS-15 tenancy bridge; D-65 TrustLevel severity ordering; D-71 L2-INDEX TDIV-001 divergence.* | | phase-1d + Phase 1 | 2026-07-28 | various |
| D-75..D-87 (sample) | *Compressed — 13 rows in git history. Key: D-76 BC error-notation count = 170; D-83 verify-error-notation-canon.sh minted; D-84 D-35 CLOSED 26/26.* | | Phase 1 | 2026-07-28..29 | various |
| D-88..D-120 (sample) | *Compressed — 33 rows in git history. Key: D-93 rename to pregolya; D-109 P1D-176 COMPLETE (160 findings, 5 CRITs); D-116 container rename COMPLETE; D-118 default_branch = factory-artifacts.* | | Phase 1 / ops | 2026-07-29..31 | various |
| D-121..D-135 (sample) | *Compressed — 15 rows in git history. Key: D-126 5 CRITs ALL CLOSED; D-127 ADR-025+POL-46/47 minted; D-134 partial-fix propagation remedy.* | | Phase 1 / ops | 2026-08-01..02 | various |
| D-136..D-152 (sample) | *Compressed — 37 rows in git history. Key: D-143 3-CLEAN streak over SPEC CONTENT; D-146 verify-adr-anchor-citations.sh BLOCKING #14; D-149 non-ADR §-anchor class closed corpus-wide.* | | Phase 1/ops | 2026-08-15..16 | state-manager/orchestrator |
| D-153..D-160 (sample) | *Compressed — 8 rows in git history. Key: D-158 ferro-residue cleared + records-lint L12 dead-brand-token guard; D-159 P1D-187 CLEAN streak 1/3; D-160 P1D-188 NOT CLEAN streak RESET.* | | Phase 1/ops | 2026-08-16 | orchestrator/state-manager |
| D-161..D-164 (sample) | *Compressed — 4 rows in git history. Key: D-161 DI-008 attribution class swept; D-163 TrustLevel::Untrusted title-sync; D-164 ProvenanceTag→TrustLevel class retired CORPUS-WIDE.* | | Phase 1/ops | 2026-08-16 | state-manager/orchestrator |
| D-165..D-166 (sample) | *Compressed — 2 rows in git history. Key: D-165 P1D-191 CLEAN streak 1/3; D-166 P1D-192 CLEAN streak 2/3 (different-slice deep-read 7 axes).* | | Phase 1/ops | 2026-08-17 | state-manager/orchestrator |
| D-167..D-194 (sample) | *Compressed — 28 rows archived to cycles/v1.0.0-greenfield/burst-log.md. Key: D-167 Phase-1d CONVERGED 3/3 on 1262ebe; D-170 LCEL scope expansion (human-directed; streak RESET); D-171 LCEL authoring COMPLETE (BC 129→133; VP 13→14; ADR 25→26); D-178 EXEC 13th error category; D-185 residual-coverage audit 8 findings closed; D-189..D-194 (sample) passes (streak 1/3→RESET→1/3→RESET→1/3→2/3).* | | Phase 1/ops | 2026-08-17..18 | various |
| D-195 | **P1-pass-213 CLEAN(strict)=YES CLEAN(PR-merge)=YES; 0 findings; frozen anchor 79eb2f3; streak 2/3→3/3 CONVERGED. Phase-1d re-convergence cascade CLOSED — 3/3 on frozen anchor 79eb2f3 (post-D170-LCEL-expansion; ~215 passes total). BC-5.39.001 3-CLEAN satisfied: P1-pass-211/212/213 all CLEAN(strict). All corpus-wide canonical-form checks PASS. Novelty ZERO. BC census UNCHANGED 133 (51/79/3).** | BC-5.39.001 satisfied; Phase-1d cascade CLOSED; SECOND convergence post-LCEL-expansion | Phase 1 | 2026-08-18 | state-manager/orchestrator |
| D-196 | **INPUT-HASH BOOKKEEPING PRECEDENT: Input-hash frontmatter field refresh is BOOKKEEPING METADATA, NOT normative spec content. Refreshing stale input-hash fields does NOT reset the 3-CLEAN streak or invalidate a recorded convergence. Human-ruled 2026-08-18. Extends D-143 class.** | Human ruling: input-hash is derived metadata; refresh = bookkeeping, not spec change | Phase 1 | 2026-08-18 | human (senior architect) |
| D-197 | **PHASE 1 GATE CLOSED / COMPLETE (burst-325; 2026-08-18). Pre-gate conditions: (1) consistency-validator GATE-CLEAN (5 input-hash drift advisories resolved D-196); (2) Phase-1d CONVERGED 3/3 on 79eb2f3 (D-195); (3) D-170 conditional approval SATISFIED. CORPUS STATE: 133 BCs (51/79/3); 39 CAPs; 16 DIs; 14 VPs (6P0/8P1); 26 ADRs; 114 error codes / 13 categories; ~697 TVs; 83 modules. Phase 2 Story Decomposition IN PROGRESS.** | All Phase-1 gate conditions satisfied; D-170 conditional approval fulfilled | Phase 1→2 | 2026-08-18 | state-manager/orchestrator |
| D-198 | **Phase-2 structural decomposition COMPLETE (burst-326; 2026-08-18). 39 stories / 22 epics / 294 pts. Wave plan: Wave1=27 (pregolya-core+graph+partners), Wave2=11, Wave6=1. D7 priority honored. 133/133 BC coverage; DAG acyclic; critical path S-1.01→S-1.25 (10 stories/74 pts); 14/14 VP anchors; 11/11 Red Gate BCs. 3 gap-register entries IN-SCOPE (GAP-001 BC-2.19.004; GAP-002 Kani; GAP-003 VP-004/005).** | D7 wave priority and BC coverage satisfied; gap-register entries are in-scope story resolutions | Phase 2 | 2026-08-18 | state-manager/orchestrator |
| D-199..D-206 (sample) | *Compressed — 8 rows archived to cycles/v1.0.0-greenfield/burst-log.md (bursts 327-334). Key: D-199 Batch 1 COMPLETE (S-1.01..S-1.06); D-200 Batch 2 (S-1.07..S-1.13; VP-002/003); D-201 Batch 3 (S-1.14..S-1.20; VP-001); D-202 Wave 1 FULLY AUTHORED (S-1.21..S-1.27; VP-011/012/013); D-203 pin forward-fix; D-204 Wave 2 Batch 1 (VP-006/007/009/010; GAP-001); D-205 Wave 2 FULLY AUTHORED (VP-004/005/008); D-206 Wave 6 COMPLETE / per-story authoring COMPLETE (S-6.01; 39/39; 14 VPs; GAP-002). [D-206 bookkeeping reconciliation 2026-08-21: original note said "12 VPs" — corrected to 14 VPs per authoritative VP-INDEX + ARCH-INDEX; LCEL expansion per D-171 added VP-014 post original authoring note.]* | | Phase 2 | 2026-08-18..19 | story-writer/state-manager |
| D-207 | **Phase-2 holdout scenarios Domains A+B COMPLETE (burst-335; 2026-08-19). product-owner authored 14 scenarios: Domain A Virtual SOC Analyst (HS-A-001..HS-A-007; 5 must-pass; 2 should-pass) + Domain B Dark Factory (HS-B-001..HS-B-007; 4 must-pass; 3 should-pass). 9 must-pass = 64% (> required 60% Phase-4 gate). SEALED until Phase-4. Phase-4 holdout-evaluator must feed ONLY spec-free scenario narratives + rubrics (NOT BC Linkage tables).** | D8 plan fulfilled; 9 must-pass = 64% satisfies Phase-4 gate; information asymmetry confirmed | Phase 2 | 2026-08-19 | product-owner |
| D-208..D-218 (sample) | *Compressed — 11 rows in burst-log/trajectory. Key: P2A-001..P2A-011 adversarial passes + fix-bursts ALL COMPLETE (2026-08-19..20); all findings closed corpus-wide; PGAP-MSGDRIFT content instances swept D-218 (10 instances corpus-wide); corpus unchanged (133 BC/14 VP/115 EC/12 VP-anchor/8 RG); streak 0/3 throughout. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md.* | | Phase 2 | 2026-08-19..20 | various |
| D-219 | **Phase-2 adversarial P2A-012 NOT CLEAN (2H) ALL CLOSED. F-01 (HIGH, POL-4) S-2.08 AC-003/EC-001 error-type mis-anchor E-CORE-005→EvalError::AllCasesInfraError per BC-2.08.008 PC5/EC-001/EC-003/TV-004; AC-003 postcondition ref corrected 3→5; behavioral_contracts frontmatter normalized. F-02 (HIGH, POL-6/POL-24 + CLAUDE.md) mod.rs-logic violations relocated across 4 stories (S-2.03/S-2.02/S-1.09/S-1.27); all mod.rs now re-export-only. Corpus unchanged (133 BC / 14 VP / 115 EC / 12 VP-anchor / 8 RG). Streak 0/3. NEXT P2A-013.** | Phase-2 adversarial convergence pass 12; 2 findings closed (2H) | Phase 2 | 2026-08-20 | story-writer/state-manager |
| D-220 | **SESSION WRAP — RESUME SNAPSHOT v5.32 committed (2026-08-20; single-commit burst per TD-VSDD-053). Human decision: F-02/TDIV-009 WAIVED (holdout `## Category: real-world-corpus` heading accepted as known vendor-template limitation; durable fix = engine-vendor template change). P2A-013 dispatched then STOPPED mid-run (read-only, no disk writes). Streak 0/3. NEXT: P2A-013 fresh dispatch on this wrap HEAD.** | Session wrap bookkeeping per POL-22 | Phase 2 | 2026-08-20 | state-manager |
| D-221 | **Phase-2 adversarial P2A-013 NOT CLEAN (1H/3M/1L) ALL CLOSED. P2A013-02 (HIGH): S-1.13 target_module pregolya-memory→[pregolya-core,pregolya-memory,pregolya-graph]; STORY-INDEX+sprint-state reconciled. P2A013-01 (MED): S-2.05 BC-table BC-2.18.004 priority P0→P1. P2A013-03 (MED): S-6.01 target-crate triad → canonical 9-crate set (architect Q2). P2A013-04 (MED): S-1.16 depends_on S-1.13 edge + reciprocal added (architect Q1; DAG acyclic). P2A013-05 (LOW): 6 stories version literals→workspace pin. Corpus: 133 BC / 14 VP; no renumber. Streak 0/3. NEXT P2A-014.** | Pass 13; 5 findings closed (1H/3M/1L) | Phase 2 | 2026-08-21 | story-writer/state-manager |
| D-222 | **Phase-2 adversarial P2A-014 NOT CLEAN (1M/1L/1OBS) ALL CLOSED. P2A014-01 (MED): 5 Wave-2 stories target_module expanded (S-2.02/06/07/08/09); 39-story sibling sweep exhausted class. P2A014-02 (LOW): STORY-INDEX S-1.13 Subsystem SS-15→SS-15+SS-03. P2A014-03 (OBS): wave-schedule S-1.16 Depends-On → appended S-1.13. Hygiene: behavioral_contracts inline S-2.07+S-2.09; BC-2.08.006 prose cross-ref; input-hash refresh. Census 133 BC / 14 VP; DAG unchanged. Streak 0/3. NEXT P2A-015.** | Pass 14; 3 findings closed (1M/1L/1OBS) | Phase 2 | 2026-08-21 | story-writer/state-manager |
| D-223 | **Phase-2 adversarial P2A-015 NOT CLEAN (1H/1M/3L) ALL CLOSED. Root cause: D17-Q5 SDK-split under-propagation (pregolya-openai-sdk, pregolya-anthropic-sdk, pregolya-ollama-sdk never propagated into S-2.06 triad, wave-schedule tiers, or ARCH-INDEX SS-08). P2A015-01 (HIGH, POL-6/8): 3 -sdk crates added to S-2.06 target_module + sprint-state (3→6); wave-schedule updated (sdk→Tier-6; adapters→Tier-7; mcp→Tier-8; xtask→Tier-9; community→post-v1). P2A015-02 (MED, POL-6): pregolya-community→post-v1. OBS-1: S-2.10+S-2.11 behavioral_contracts block-seq→inline. OBS-2: STORY-INDEX stale "(written in subsequent bursts)" clause removed. OBS-3: ARCH-INDEX SS-08 +pregolya-macros + two stale VP-INDEX cites de-pinned (records-lint TD-VSDD-091). D-206 bookkeeping: "12 VPs" corrected to "14 VPs" (LCEL expansion per D-171 added VP-014; VP-INDEX + ARCH-INDEX authoritative at 14). BC-2.08.006 coverage floor VERIFIED INTACT (S-2.06 covers all 6 crates). No ID renumber (POL-1); no bcs: set changes; census 133 BC / 14 VP; ARCH-INDEX SS-08 registry updated. Streak 0/3. NEXT P2A-016.** | Pass 15; 5 findings closed (1H/1M/3L); D17-Q5 SDK-split propagated corpus-wide; D-206 VP count reconciliation | Phase 2 | 2026-08-21 | architect/story-writer/state-manager |
| D-224 | **Phase-2 adversarial P2A-016 NOT CLEAN (2M/1L) ALL CLOSED. P2A016-01 (MED, POL-4/DAG-derived-view): dep-graph §TopSort violated its own no-intra-batch rule (S-1.15 co-listed with dep S-1.14; S-1.15 duplicated in two batches); batch grouping also diverged from wave-schedule. Both docs reconciled to single canonical 10-batch Wave-1 structure derived from authoritative DAG edges. DAG EDGES UNCHANGED; acyclic confirmed. P2A016-02 (MED, POL-6): pregolya facade (roster #1, v1) absent from wave-schedule §Crate Implementation Order; architect ruling (a): re-export-only, no dedicated story per ADR-007 §Consequences; story-writer added explicit annotation row. P2A016-LOW: SS-17 Primary-Crate convention gap; architect added `Primary Crate(s)` convention definition to ARCH-INDEX Subsystem Registry preamble + SS-17 scope note blockquote. No ADR change. No ID renumber (POL-1); no DAG EDGE changes (only derived batch-grouping views reconciled); no bcs: set changes — Token Budget unaffected; census 133 BC / 14 VP; streak 0/3. NEXT P2A-017.** | Phase-2 adversarial convergence pass 16; 3 findings closed (2M/1L) | Phase 2 | 2026-08-21 | architect/story-writer/state-manager |
| D-225 | **Phase-2 adversarial P2A-017 NOT CLEAN (2M/1L) ALL CLOSED. P2A017-01 (MED, POL-6/24): SS-10 Primary Crate(s) omitted pregolya-core (homes BC-2.10.005/VP-012 core::budget); added. P2A017-02 (MED, POL-6/4): SS-06 StreamEvent taxonomy adjudicated CORE canonical per ADR-006 §Consequences; module-decomposition graph::event_emitter rescoped to emission-only; S-1.17 target_module→[pregolya-core,pregolya-graph] + core::events File Structure entry + AC-001 re-trace (triad synced). P2A017-03 (LOW): SS-08 core::tool scope note confirmed correct — Tool trait is Phase-3 prerequisite, not BC-homing crate; pregolya-core exclusion from SS-08 Primary Crate(s) valid. EXHAUSTIVE SWEEP: all 23 SS rows (SS-01..SS-23) verified via three-source cross-check (module-decomp SS-tags + VP-INDEX + BC→SS numbering); only SS-10 required a FIX; 22 others MATCH — POL-24 sibling-sweep SATISFIED. No BC/VP/story renumber (POL-1); S-1.17 BC set unchanged (BC-2.06.001–003); census 133 BC / 14 VP; ARCH-INDEX updated; module-decomposition updated. Streak 0/3. NEXT P2A-018.** | Phase-2 adversarial pass 17; 3 findings closed (2M/1L); Primary Crate(s) convention swept corpus-wide | Phase 2 | 2026-08-21 | architect/story-writer/state-manager |
| D-226 | **Phase-2 adversarial P2A-020 NOT CLEAN (1M/1L) ALL CLOSED. STREAK HISTORY: P2A-018 CLEAN(strict)=YES streak 1/3; P2A-019 CLEAN(strict)=YES streak 2/3; P2A-020 NOT CLEAN streak RESET 0/3. F-P2A020-01 (MED, POL-4/46) CLOSED: scheduler.rs ownership ambiguity — 4 same-batch stories (S-1.13/S-1.15/S-1.17/S-1.18) made mutually-inconsistent claims incl. false ones (S-1.18 credited S-1.14 with a scheduler skeleton it never builds; S-1.13 falsely claimed first-touch). Architect ruling: S-1.15 CREATES scheduler.rs skeleton; S-1.17 adds run()/stream(); S-1.13 adds ContextMutationConfig pre-loop loader; S-1.18 adds per-super-step budget eval; S-1.16 adds ceiling/run_id checks. New DAG edges: S-1.17 dep S-1.15; S-1.13/S-1.18/S-1.16 dep S-1.17; S-1.16 dep S-1.18. batch-1e split into sequential chain S-1.15→S-1.17→{S-1.13∥S-1.18}→S-1.16 (Wave-1 10→12 batches; DAG acyclic; critical path 10→12 stories/69→82 pts). F-P2A020-02 (LOW) CLOSED: S-1.16 depends_on S-1.13 rationale absent → documented via PSI rows. D-221 S-1.16↔S-1.13 edge CONFIRMED. No BC/VP/story renumber (POL-1); census 133 BC/14 VP; DAG ACYCLIC; no ADR change. Content defect (not process-gap). Streak 0/3. NEXT P2A-021.** | Phase-2 adversarial pass 20; 2 findings closed (1M/1L); scheduler.rs ownership model + 5 new DAG edges; streak history P2A-018/019 CLEAN then P2A-020 reset | Phase 2 | 2026-08-21 | architect/story-writer/state-manager |

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

None active. Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..020 (sample) fix-bursts COMPLETE. NEXT: P2A-021. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Convergence Status

Counter: **Phase-1 CLOSED (burst-325; D-197; 2026-08-18)**: 3/3 CONVERGED on frozen anchor 79eb2f3 (D-195). Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..020 (sample) fix-bursts COMPLETE. P2A-018 CLEAN(strict) streak 1/3; P2A-019 CLEAN(strict) streak 2/3; P2A-020 NOT CLEAN (1M/1L; D-226; fix-burst COMPLETE 2026-08-21) streak RESET 0/3. NEXT: Phase-2 adversarial P2A-021. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Session Resume Checkpoint

<!-- v5.38 checkpoint replaces v5.37 — v5.37 archived to cycles/v1.0.0-greenfield/session-checkpoints.md. Keep ONLY the latest checkpoint here. -->

### RESUME IN ONE BREATH
Pregolya (Rust semantic port of langchain/langgraph), greenfield+semport, /Users/jmagady/Dev/pregolya. Phase 1 CLOSED. Phase 2 Story Decomposition: content COMPLETE (39 story specs, 133/133 BC coverage, 14 holdout scenarios SEALED). Currently in Phase-2 adversarial story-decomposition convergence (BC-5.39.001 3-CLEAN); streak **0/3**. Adversary passes P2A-001..P2A-020 run; P2A-018/019 CLEAN(strict) (streak 1/3→2/3); P2A-020 NOT CLEAN (1M/1L; D-226; scheduler.rs ownership model; Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts) — streak RESET 0/3. Fix-burst COMPLETE. NEXT: dispatch a FRESH `vsdd-factory:adversary` pass **P2A-021** on the current post-fix-burst factory-artifacts HEAD (frozen-HEAD baseline reset by this fix-burst push).

### HEADS
- develop `644d1ad` — clean, PUSHED, untouched.
- factory-artifacts: run `git -C .factory log -1 --format='%h'` for the current HEAD. PUSHED to origin. (Per TD-VSDD-053, do NOT pin the SHA literally here — git is source of truth.)
- Worktrees: NONE. Open PRs: NONE.

### CURRENT WORKSTREAM — Phase-2 adversarial story convergence
- Streak **0/3** (BC-5.39.001). P2A-018/019 were CLEAN(strict); P2A-020 found a real defect (scheduler.rs ownership), resetting streak.
- Finding trajectory P2A-001..020: 8→3→7→3→8→2→3→4→8→10→4→2→5→3→5→3→3→0→0→2. Axes swept: VP anchors; subsystem-name canon; error-code categories; error-message strings; DAG reciprocity; holdout BC-linkage; purity; VP-011; error-type semantics; mod.rs layout; BC-table priority; target-crate frontmatter; DAG S-1.16→S-1.13; version-literal pins; Wave-2 target-crate; STORY-INDEX subsystem; SDK-split D17-Q5; dep-graph 10-batch; pregolya facade; SS-10 Primary Crate(s) (D-225); SS-06 StreamEvent CORE canonical (D-225); scheduler.rs ownership model (D-226).
- **RESUME NEXT-ACTION:** dispatch `vsdd-factory:adversary` **P2A-021**, fresh context, Read/Grep/Glob only, Form-B verbatim evidence, FULL POL rubric (POL-1..31 + POL-46/47). ACCEPTED/DO-NOT-REFLAG: (1) F-02/TDIV-009 vendor-template limitation waived (D-220); (2) OBS-1 + PGAP-MSGDRIFT open gaps — report NEW instances only; (3) Primary Crate(s) convention swept ALL 23 SS rows (P2A-017; D-225) — do NOT re-flag absent NEW concrete BC-homing divergence; (4) scheduler.rs ownership model ESTABLISHED (D-226) — do NOT re-flag the coordination model. Dual CLEAN(strict)/CLEAN(PR-merge) verdict, frozen-HEAD baseline. CLEAN(strict) → streak 1/3 → P2A-022/023 on SAME HEAD to 3/3.
- **OPS LEARNING (this session):** (a) `sidecar-learning.md` session-hook re-dirties the tree after every agent stop — a streak-transparent `chore:` hygiene commit needed before each adversary dispatch (adversary/wave-gate dispatches BLOCKED on dirty tree; fix-burst dispatches are not); (b) PROPOSED: gitignore `sidecar-learning.md` in `.factory/.gitignore` — DEFER-004 class; requires human authorization before implementing.

### PENDING USER-APPROVED WORK
None pending (Phase 2→3 autonomous per DIRECTIVE 1). **F-02/TDIV-009 WAIVED** (vendor-template limitation; D-220).

### OPEN ITEMS FOR PHASE-2 GATE
- TDIV-009-VENDOR (human-waived; durable fix = vendor template change).
- OBS-1 — DAG reciprocity validator pending devops scope authorization.
- PGAP-MSGDRIFT — mechanical gate pending devops scope authorization.
- Human actions: E013 (default_branch→main), R6/R14 (cargo login + publish-all.sh), B1 (direnv allow .), TDIV-008 (vendor). WORKSPACE INIT incomplete (Phase-3 prerequisite).

### DECISION DELTA (this session)
D-226 minted (P2A-020 fix-burst COMPLETE; 1M/1L ALL CLOSED; scheduler.rs ownership model; 5 new DAG edges; Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts). P2A-018/019 CLEAN(strict) streak history 1/3→2/3→RESET 0/3. Human F-02/TDIV-009 waiver in effect (D-220).

### PENDING HUMAN ACTIONS
1. **E013 (Medium)** — `gh repo edit --default-branch main`.
2. **R14/R6 (HIGH)** — `cargo login` → `cd .factory/namespace-reservation && bash publish-all.sh`.
3. B1 — `direnv allow .`
4. **TDIV-008** — engine `path_allow` fix requires vendor action.

## Historical Content

| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–343; Phase-2 per-story authoring + holdout scenarios; P2A-001..020 (sample) fix-bursts + session wrap D-220) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| Adversary pass details (~215 Phase-1 passes; Phase-2 P2A-001..P2A-020) | `cycles/v1.0.0-greenfield/convergence-trajectory.md` |
| Session checkpoints (v4.45..v5.37 archived; v5.37 replaced 2026-08-21) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (188+ lessons) | `cycles/v0.0.0-pre-pipeline/lessons.md` + `cycles/v1.0.0-greenfield/lessons.md` |
| Resolved blockers (R1–R5, R7, R9) | `cycles/v1.0.0-greenfield/blocking-issues-resolved.md` |
| Spec artifacts (133 BCs; 14 VPs; 26 ADRs; PRD; L2 domain spec; architecture) | `.factory/specs/` |
| Phase-2 story specs (39 stories; epics; DAG; wave schedule; sprint state) | `.factory/stories/` |
| Holdout scenarios (14 scenarios; SEALED) | `.factory/holdout-scenarios/` |
| Planning artifacts (DTU assessment; semport analysis; market intel; naming; policies.yaml) | `.factory/planning/` + `.factory/semport/` + `.factory/policies.yaml` |
