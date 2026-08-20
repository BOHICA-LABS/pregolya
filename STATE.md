---
document_type: pipeline-state
level: ops
version: "5.26"
status: in-progress
producer: state-manager
timestamp: "2026-08-20T18:35:00Z"
phase: 2
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: pregolya
mode: greenfield+semport
current_step: "P2A-007 fix-burst COMPLETE (2026-08-20; D-214): 3 findings (2M/1L) ALL CLOSED. F-P2A007-01 (MED,POL-6) S-1.21 §Architecture Mapping subsystem name 'Tool Implementations'→'First-Party Tool Library' (ARCH-INDEX canonical). F-P2A007-02 (MED,POL-4/21) HS-B-004 BC mis-anchor BC-2.04.004→BC-2.03.001 (BSP super-step ceiling halt / E-GRAPH-017; HS-B-004 v1.2). F-P2A007-03 (LOW,POL-5) S-1.13 SS-03 co-anchor justification rewritten to BSP-scheduler-boundary basis. OBS-A non-scored (STORY-INDEX §Conventions note). Regression: all P2A-003..006 HELD; TDIV-009 NOT re-flagged. Corpus unchanged (133 BC / 14 VP / 115 EC / 12 VP-anchor / 8 RG). trajectory-tail →3→8→2→3. Streak 0/3. NEXT P2A-008."
current_cycle: v1.0.0-greenfield
convergence_status: "Phase-1 CLOSED (burst-325; D-197; 2026-08-18). 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195). Phase 2 IN PROGRESS: per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..007 (sample) fix-bursts COMPLETE. P2A-007 NOT CLEAN (2M/1L; D-214; fix-burst COMPLETE 2026-08-20); streak 0/3. NEXT: Phase-2 adversarial P2A-008. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md."
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "DIRECTIVE 1 (2026-07-13): Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes. DIRECTIVE 2 (2026-07-29): fix-in-scope is the DEFAULT posture; deferral requires explicit per-case human permission; CLAUDE.md Canonical Principle Rule 3 UNCHANGED. Agents may NOT self-authorize deferrals. Orchestrator may PROPOSE deferrals but default action is to fix."
---

<!-- STATE.md SIZE BUDGET: 199 lines (wc-l) | margin from soft-target (200L): +1 line | margin from actual wc-l: 0 lines | compact-state v5.26 (2026-08-20): P2A-007 fix-burst COMPLETE (D-214); 3 findings closed (2M/1L); P2A-002 step row archived to burst-log. NEXT: P2A-008. -->

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
| **Last Updated** | 2026-08-20 — compact-state v5.26; P2A-007 fix-burst COMPLETE (D-214); trajectory-tail →3→8→2→3. NEXT: Phase-2 adversarial P2A-008. |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | COMPLETE | 2026-07-14 | 2026-08-18 | 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195); input-hash drift resolved (D-196); Phase-1 gate CLOSED (D-197; burst-325). ~215 adversarial passes total. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md | trajectory-tail →1→0→0→0; 3/3 CONVERGED |
| 2: Story Decomposition | IN PROGRESS | 2026-08-18 | | Structural decomp COMPLETE (D-198); per-story authoring COMPLETE 39/39 D-199..D-206 (sample); holdout scenarios COMPLETE 14/14 (D-207; SEALED). P2A-001..007 (sample) fix-bursts COMPLETE D-208..D-214 (sample). NEXT: P2A-008. | trajectory-tail →3→8→2→3; 0/3. NEXT: P2A-008. |
| 2: adversary passes P2A-001..004 | COMPLETE | 2026-08-19 | 2026-08-20 | NOT CLEAN each; 8+3+7+3=21 findings; fix-bursts dispatched D-208..D-211 (sample) | trajectory-tail →0→0→8→3→7→3; 0/3 (all NOT CLEAN; all fix-bursts CLOSED) |
| 2: fix bursts post-P2A-001..004 | COMPLETE | 2026-08-19 | 2026-08-20 | All 21 findings closed in-scope; census unchanged (133 BC / 39 stories / 12 VP-anchor / 8 RedGate) | trajectory-tail →0→0→0→8→3→7→3; 0/3 → NEXT P2A-005 |
| 2: adversary pass-5 (P2A-005) | COMPLETE | 2026-08-20 | 2026-08-20 | NOT CLEAN: 7 findings (3H/3M/1L/1PG); fix-burst dispatched (D-212). OBS-1 process-gap recorded. | trajectory-tail →7→3→7→3→8; 0/3 (NOT CLEAN; streak RESET) |
| 2: fix burst (post-pass-5 P2A-005) | COMPLETE | 2026-08-20 | 2026-08-20 | P2A-005: all 7 findings closed (D-212); OBS-1 OPEN. Streak 0/3 (HIGH present). NEXT P2A-006. | trajectory-tail →3→7→3→8; 0/3 → NEXT P2A-006 |
| 2: adversary pass-6 (P2A-006) | COMPLETE | 2026-08-20 | 2026-08-20 | NOT CLEAN: 2 findings (1M/1OBS); fix-burst dispatched (D-213). F-01 STORY-INDEX stale cell; F-02 vendor-template heading HUMAN-WAIVED (TDIV-009). | trajectory-tail →3→7→3→8→2; 0/3 (NOT CLEAN; streak 0/3) |
| 2: fix burst (post-pass-6 P2A-006) | COMPLETE | 2026-08-20 | 2026-08-20 | P2A-006: all 2 findings closed (D-213); TDIV-009-VENDOR blocking-issue recorded. Streak 0/3. NEXT P2A-007. | trajectory-tail →7→3→8→2; 0/3 → NEXT P2A-007 |
| 2: adversary pass-7 (P2A-007) | COMPLETE | 2026-08-20 | 2026-08-20 | NOT CLEAN: 3 findings (2M/1L); OBS-A non-scored; fix-burst dispatched (D-214). F-01 S-1.21 subsystem name; F-02 HS-B-004 BC re-anchor; F-03 S-1.13 justification. | trajectory-tail →7→3→8→2→3; 0/3 (NOT CLEAN; streak 0/3) |
| 2: fix burst (post-pass-7 P2A-007) | COMPLETE | 2026-08-20 | 2026-08-20 | P2A-007: all 3 findings closed (D-214); OBS-A non-scored. Streak 0/3. NEXT P2A-008. | trajectory-tail →3→8→2→3; 0/3 → NEXT P2A-008 |
| 3: TDD Implementation | not-started | | | | — |
| 4: Holdout Evaluation | not-started | | | | — |
| 5: Adversarial Refinement | not-started | | | | — |
| 6: Formal Hardening | not-started | | | | — |
| 7: Convergence | not-started | | | | — |

## Current Phase Steps

<!-- Keep last 5 rows only. Older rows archived to cycles/v1.0.0-greenfield/burst-log.md. -->
| Step | Agent | Status | Output |
|------|-------|--------|--------|
| P2A-007 fix-burst (2026-08-20) — 3 findings closed (2M/1L): F-P2A007-01 (MED,POL-6) S-1.21 §Architecture Mapping subsystem name 'Tool Implementations'→'First-Party Tool Library' (ARCH-INDEX canonical; frontmatter SS-23 correct). F-P2A007-02 (MED,POL-4/21) HS-B-004 BC mis-anchor BC-2.04.004→BC-2.03.001 (BSP super-step ceiling halt / E-GRAPH-017; frontmatter+linkage+changelog synced; HS-B-004 v1.2). F-P2A007-03 (LOW,POL-5) S-1.13 SS-03 co-anchor justification rewritten to BSP-scheduler-boundary basis. OBS-A non-scored: STORY-INDEX §Conventions note (Status:draft vs sprint-state status:spec-ready = distinct axes). Regression all P2A-003..006 HELD; TDIV-009 NOT re-flagged. Corpus unchanged. D-214 minted. | state-manager | COMPLETE | 3 story/HS files + STORY-INDEX. Streak 0/3. NEXT: P2A-008. |
| P2A-006 fix-burst (2026-08-20) — 2 findings closed (1M/1OBS): F-P2A006-01 STORY-INDEX S-1.13 depends_on cell [S-1.12,S-1.04]→[S-1.12,S-1.04,S-1.14] (39-row sweep confirmed sole divergence); F-P2A006-02 holdout `## Category: real-world-corpus` HUMAN-WAIVED (TDIV-009; vendor-template limitation). All ~20 regression checks HELD. TDIV-009-VENDOR blocking-issue recorded. D-213 minted. | state-manager | COMPLETE | STORY-INDEX + 12 holdout HS bodies + TDIV-009 divergence-register. Streak 0/3. NEXT: P2A-007. |
| P2A-005 fix-burst (2026-08-20) — 7 findings closed (3H/3M/1L/1PG): F-01/02 DAG blocks-reciprocity sweep (4 dep-graph nodes + 16 story frontmatters); F-03 S-1.13 hard dep S-1.14+SS-03+re-batch 1e→1f; F-04 S-1.21 SS-22→SS-13; F-05 S-1.05 BC table; F-06 S-1.11 FTS+encrypt in-spec (E-CHKPT-010+BC-2.04.008 §Invariant-5); F-07 S-6.01 predecessors. Input-hash refreshed 173 files. OBS-1 open. D-212 minted. | state-manager | COMPLETE | Story specs + BC-2.04.008 + error-taxonomy + wave-schedule + dep-graph + STORY-INDEX. Streak 0/3. NEXT: P2A-006. |
| P2A-004 fix-burst (2026-08-20) — 3 findings closed (1M/2L): F-P2A004-01 S-1.21 verification_properties [VP-003]→[]; F-P2A004-02 S-1.08 verification_properties [VP-SPLIT-01..08]→[] + body blockquote + STORY-INDEX §Conventions note; F-P2A004-03 wave-schedule §Critical Path wording clarified. All 7 P2A-003 fixes HELD. Census unchanged. D-211 minted. | state-manager | COMPLETE | Story specs + wave-schedule + STORY-INDEX. Streak 0/3. NEXT: P2A-005. |
| P2A-003 fix-burst (2026-08-20) — 7 findings closed (2H/4M/1OBS): F-01 5 story specs §Architecture Mapping+§Purity Classification + edge cases + BC-ID rephrase; F-02 14 HS BC-linkage re-anchored; F-03 S-6.01 DAG reciprocal; F-04 wave-schedule 74→69; F-05 STORY-INDEX VP-014 anchor; F-06 HS-INDEX gate wording; F-07 HS-A stray Category. D-210 minted. | state-manager | COMPLETE | Story specs + HS files + wave-schedule + STORY-INDEX + HS-INDEX. Streak 0/3. NEXT: P2A-004. |

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
| D-199..D-206 (sample) | *Compressed — 8 rows archived to cycles/v1.0.0-greenfield/burst-log.md (bursts 327-334). Key: D-199 Batch 1 COMPLETE (S-1.01..S-1.06); D-200 Batch 2 (S-1.07..S-1.13; VP-002/003); D-201 Batch 3 (S-1.14..S-1.20; VP-001); D-202 Wave 1 FULLY AUTHORED (S-1.21..S-1.27; VP-011/012/013); D-203 pin forward-fix; D-204 Wave 2 Batch 1 (VP-006/007/009/010; GAP-001); D-205 Wave 2 FULLY AUTHORED (VP-004/005/008); D-206 Wave 6 COMPLETE / per-story authoring COMPLETE (S-6.01; 39/39; 12 VPs; GAP-002).* | | Phase 2 | 2026-08-18..19 | story-writer/state-manager |
| D-207 | **Phase-2 holdout scenarios Domains A+B COMPLETE (burst-335; 2026-08-19). product-owner authored 14 scenarios: Domain A Virtual SOC Analyst (HS-A-001..HS-A-007; 5 must-pass; 2 should-pass) + Domain B Dark Factory (HS-B-001..HS-B-007; 4 must-pass; 3 should-pass). 9 must-pass = 64% (> required 60% Phase-4 gate). SEALED until Phase-4. Phase-4 holdout-evaluator must feed ONLY spec-free scenario narratives + rubrics (NOT BC Linkage tables).** | D8 plan fulfilled; 9 must-pass = 64% satisfies Phase-4 gate; information asymmetry confirmed | Phase 2 | 2026-08-19 | product-owner |
| D-208 | **Phase-2 adversarial P2A-001 NOT CLEAN (2026-08-19): 8 findings (1C/1H/3M/3L) ALL CLOSED by fix-burst. CRIT F-P2A001-01: S-1.25 VP-012 CompactionTrigger execution vehicle mis-anchored pregolya-graph→pregolya-core::core::budget. HIGH F-P2A001-02: 24 epic_id corrections across story files reconciled to epics.md. MED F-P2A001-03: STORY-INDEX VP-anchor census 10→12. MED F-P2A001-04: RedGate BCs census 9→8. MED F-P2A001-05: S-6.01 reverse-edge reciprocity. LOW F-P2A001-06/07/08: records-tier. Streak 0/3. NEXT P2A-002.** | Phase-2 adversarial convergence first pass; all 8 findings closed in-scope | Phase 2 | 2026-08-19 | story-writer/state-manager |
| D-209 | **Phase-2 adversarial P2A-002 NOT CLEAN (2026-08-19): 2H/1L ALL CLOSED. HIGH F-P2A002-01: S-1.25 budget module paths. HIGH F-P2A002-02: 9 Kani proof stubs canonical src/proofs/. LOW F-P2A002-03: STORY-INDEX §Conventions note (POL-7). Streak 0/3. NEXT P2A-003.** | Phase-2 adversarial convergence pass 2; all 3 findings + template drift closed in-scope | Phase 2 | 2026-08-19 | story-writer/state-manager |
| D-210 | **Phase-2 adversarial P2A-003 NOT CLEAN (2026-08-20): 7 findings (2H/4M/1OBS) ALL CLOSED. HIGH F-01: 5 story specs §Architecture Mapping+§Purity Classification. HIGH F-02: holdout BC-linkage re-anchored 14 scenarios. MED F-03: S-6.01 DAG +depends_on+reciprocal. MED F-04: wave-schedule 74→69. MED F-05: STORY-INDEX VP-014 anchor. MED F-06: HS-INDEX gate wording. OBS F-07: HS-A stray Category. Streak 0/3. NEXT P2A-004.** | Phase-2 adversarial convergence pass 3; all 7 findings closed | Phase 2 | 2026-08-20 | story-writer/state-manager |
| D-211 | **Phase-2 adversarial P2A-004 NOT CLEAN (2026-08-20): 3 findings (1M/2L) ALL CLOSED. MED F-P2A004-01: S-1.21 VP-003 cleared. LOW F-P2A004-02: S-1.08 VP-SPLIT cleared+STORY-INDEX note. LOW F-P2A004-03: wave-schedule §Critical Path clarified. Regression: 7 P2A-003 fixes HELD. Streak 0/3. NEXT P2A-005.** | Phase-2 adversarial convergence pass 4; all 3 findings closed | Phase 2 | 2026-08-20 | story-writer/state-manager |
| D-212 | **Phase-2 adversarial P2A-005 NOT CLEAN (2026-08-20): 7 findings (3H/3M/1L/1PG) ALL CLOSED by fix-burst. HIGH F-P2A005-01/02: DAG reverse-edge `blocks` reciprocity broken corpus-wide — SW-1 swept full 39-story set (4 dependency-graph nodes + 16 story frontmatters corrected to exact reverse(depends_on)); ZERO depends_on changed; DAG acyclic; census untouched. HIGH F-P2A005-03: S-1.13 missing hard dep on S-1.14 (StateGraph/pregolya-graph) — added depends_on, subsystems +=SS-03, re-batched Wave-1e→1f. MED F-P2A005-04: S-1.21 sandbox subsystem SS-22→SS-13. MED F-P2A005-05: S-1.05 §Behavioral Contracts table added. MED F-P2A005-06 (POL-29): S-1.11 EC-005 FTS-vs-encryption resolved IN-SPEC: BC-2.04.008 §Invariant-5 (EC-007+TV-007); E-CHKPT-010 FtsEncryptionIncompatible minted (corpus 114→115). LOW F-P2A005-07: S-6.01 predecessors +=S-2.05/S-1.22. Regression: all 8 prior-fix checks HELD. OBS-1 process-gap open (DAG reciprocity validator; devops-engineer required). Streak 0/3 (HIGH present → full cascade). NEXT P2A-006.** | Phase-2 adversarial convergence pass 5; all 7 findings closed in-scope; OBS-1 process-gap recorded | Phase 2 | 2026-08-20 | story-writer/state-manager |
| D-213 | **Phase-2 adversarial P2A-006 NOT CLEAN (2026-08-20): 2 findings (1M/1OBS) ALL CLOSED. F-P2A006-01 (MED, POL-3): STORY-INDEX S-1.13 depends_on cell stale [S-1.12,S-1.04]→[S-1.12,S-1.04,S-1.14] (P2A-005 propagation miss; full 39-row sweep confirmed sole divergence). F-P2A006-02 (OBS, [process-gap]): holdout `## Category: real-world-corpus` heading contradicts actual category for 12 non-real-world-corpus scenarios — ROOT CAUSE: engine vendor holdout-scenario-template.md mandates that heading as a required (non-conditional) H2 section; validate-template-compliance enforces it on ALL holdout scenarios; templates resolve only from plugin cache (no project override). HUMAN-WAIVED 2026-08-20 as documented known vendor-template limitation: 12 non-RWC scenario bodies made uniformly self-disambiguating (heading retained verbatim for hook compliance), 2 RWC scenarios HS-A-005/HS-B-007 verified complete, TDIV-009 divergence-register entry added. Durable fix = engine-vendor template change (mark section conditional). Future adversary passes: F-02 accepted — do NOT re-flag. All ~20 regression checks HELD. Corpus unchanged (133 BC / 14 VP / 115 EC / 12 VP-anchor / 8 RG). Streak 0/3. NEXT P2A-007.** | Phase-2 adversarial convergence pass 6; F-01 index stale cell fixed; F-02 vendor-template heading HUMAN-WAIVED (TDIV-009); streak 0/3 | Phase 2 | 2026-08-20 | product-owner/state-manager |
| D-214 | **Phase-2 adversarial P2A-007 NOT CLEAN (2026-08-20): 2M/1L; OBS-A non-scored; ALL CLOSED. F-P2A007-01 (MED,POL-6) S-1.21 §Architecture Mapping subsystem name 'Tool Implementations'→'First-Party Tool Library' (ARCH-INDEX canonical; frontmatter SS-23 already correct). F-P2A007-02 (MED,POL-4/21) HS-B-004 BC mis-anchor BC-2.04.004 (Fork Lineage — scenario never forks)→BC-2.03.001 (BSP super-step ceiling halt / E-GRAPH-017), matches max-iterations edge condition; frontmatter+linkage+changelog synced (HS-B-004 v1.2). F-P2A007-03 (LOW,POL-5) S-1.13 SS-03 co-anchor justification rewritten to real BSP-scheduler-boundary basis (anchor confirmed correct). OBS-A (non-scored) status-vocabulary clarified via STORY-INDEX §Conventions note (STORY-INDEX Status:draft vs sprint-state status:spec-ready = distinct axes). Regression: all P2A-003..006 checks HELD; F-02/TDIV-009 vendor-heading NOT re-flagged (accepted). Corpus unchanged (133 BC / 14 VP / 115 EC / 12 VP-anchor / 8 RG). Streak 0/3. NEXT P2A-008.** | Phase-2 adversarial convergence pass 7; all 3 findings closed in-scope | Phase 2 | 2026-08-20 | story-writer/state-manager |

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
| TDIV-009-VENDOR | Engine holdout-scenario-template.md mandates `## Category: real-world-corpus` as a required (non-conditional) H2 section; validate-template-compliance enforces it on ALL holdout scenarios; templates resolve only from plugin cache (no project override). 12/14 pregolya scenarios are non-real-world-corpus → heading semantically wrong. Human-WAIVED P2A-006 (2026-08-20); mitigated in-project via self-disambiguating bodies + TDIV-009 divergence-register entry. Durable fix = engine-vendor template change (mark section conditional so the hook skips it). | Low | none (waived) | engine-vendor | Vendor template patch (analogous to TDIV-008). Future adversary passes: F-02 accepted — do NOT re-flag. |

## Drift / Deferrals

| ID | Item | Target | Reason |
|----|------|--------|--------|
| DEFER-003 | Resume procedure should detect+quiesce orphaned prior-session background agents (L-182; D-168) | Phase-1-gate close / first self-improvement wave | Engine/session-management concern; authorized per D-168 |
| DEFER-004 | PROPOSED mechanical grep-lint (devops-engineer) for canonical-form drift detection. | Awaiting human/devops prioritization | DIRECTIVE 2 — proposal only; human must authorize devops scope |
| OBS-1 | No validator enforces story-frontmatter `blocks:` ↔ DAG reverse(depends_on) reciprocity. P2A-005 SW-1 found 20 divergent sites (4 dep-graph nodes + 16 frontmatters). Mechanical check REQUIRED before Phase-2 gate close (S-7.02). | Phase-2-gate / first self-improvement wave | OPEN — awaiting devops-engineer story OR human-authorized deferral per DIRECTIVE 2. Do NOT self-authorize. |

## Concurrent Cycles

None active. Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..007 (sample) fix-bursts COMPLETE. NEXT: P2A-008. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Convergence Status

Counter: **Phase-1 CLOSED (burst-325; D-197; 2026-08-18)**: 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195). Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..007 (sample) fix-bursts COMPLETE. P2A-007 NOT CLEAN (2M/1L; D-214; fix-burst COMPLETE 2026-08-20); streak 0/3. NEXT: Phase-2 adversarial P2A-008. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Session Resume Checkpoint

<!-- v5.26 checkpoint replaces v5.25 — v5.25 archived to cycles/v1.0.0-greenfield/session-checkpoints.md. Keep ONLY the latest checkpoint here. -->

### RESUME IN ONE BREATH
Pregolya (Rust port of langchain/langgraph), greenfield+semport, /Users/jmagady/Dev/pregolya. Phase 1 COMPLETE (3/3 converged, gate closed D-197). Phase 2 content COMPLETE (39 story specs, 133/133 BC coverage; 14 holdout scenarios sealed). In Phase-2 adversarial story convergence (BC-5.39.001 3-CLEAN, streak 0/3). NEXT: adversary **P2A-008** (streak restart 1/3 attempt) on the post-P2A-007-fix HEAD. Inject rubric note: F-02 holdout `## Category:` heading is HUMAN-ACCEPTED (TDIV-009) — do NOT re-flag. OBS-1 process-gap open (DAG reciprocity validator — codification required before Phase-2 gate close).

### HEADS
- develop `644d1ad` — clean, PUSHED, untouched.
- factory-artifacts: run `git -C .factory log -1 --format='%h'` for current HEAD (= this burst commit).
- Story worktrees: NONE. Open PRs: NONE.

### CURRENT WORKSTREAM — Phase-2 adversarial story convergence (P2A-007 fix-burst COMPLETE; NEXT P2A-008)
- **Prior milestones**: Phase 1 COMPLETE (D-197; burst-325); Phase-2 decomp+authoring+holdouts COMPLETE D-198..D-207 (sample); P2A-001..006 (sample) fix-bursts COMPLETE D-208..D-213 (sample); 31 findings closed.
- **P2A-007 fix-burst COMPLETE (D-214; 2026-08-20): 3 findings (2M/1L) ALL CLOSED** — F-P2A007-01 S-1.21 subsystem name 'Tool Implementations'→'First-Party Tool Library'; F-P2A007-02 HS-B-004 BC-2.04.004→BC-2.03.001 (BSP max-iterations halt / E-GRAPH-017; v1.2); F-P2A007-03 S-1.13 SS-03 co-anchor justification rewritten to BSP-scheduler-boundary basis. OBS-A non-scored (STORY-INDEX §Conventions note). Regression all P2A-003..006 HELD; TDIV-009 NOT re-flagged.
- **NEXT-ACTION**: dispatch `vsdd-factory:adversary` **P2A-008** — fresh context, Phase-1-active POL rubric (POL-1..31+46/47), form-B verbatim evidence, dual CLEAN(strict)/CLEAN(PR-merge) verdict, deep-read fresh story slice + re-derive coverage matrices + regression-check P2A-001..007 (sample) fixes held. Streak 0/3 → target 3/3. **Rubric note: F-02 holdout `## Category:` heading is HUMAN-ACCEPTED (TDIV-009) — do NOT re-flag.** OBS-1 codification required before Phase-2 gate close.

### PENDING USER-APPROVED WORK
None pending (Phase 2→3 autonomous per DIRECTIVE 1; Phase-1 closed under D-170).

### PRODUCT BACKLOG PRIORITY (Phase 2)
1. **P2A-008** — Phase-2 adversarial story convergence re-pass (adversary, BC-5.39.001; streak 0/3 → target 3/3; rubric note: TDIV-009 holdout heading accepted)
2. **OBS-1** — DAG reciprocity validator codification (devops-engineer; required before Phase-2 gate close)
3. Pre-Phase-2-gate consistency audit — consistency-validator; Phase-2 gate → Phase 3

### OPEN DEFERRALS / PROCESS-GAPS
- DEFER-003: resume procedure quiescence. Owner: session-reviewer + engine-vendor.
- DEFER-004: proposed mechanical grep-lint. Owner: devops-engineer + human prioritization.
- **OBS-1**: DAG `blocks:` ↔ `depends_on` reciprocity validator. OPEN — devops-engineer or human-authorized deferral. Required before Phase-2 gate close.
- **TDIV-009-VENDOR**: holdout template `## Category:` heading (vendor fix needed; waived for project use). See Blocking Issues.
- Pre-existing human/vendor actions OPEN: E013 (repo default_branch → main); R14/R6 (cargo login + publish-all.sh for 21 pregolya-* names); B1 (direnv allow .); TDIV-008 (engine path_allow, vendor). WORKSPACE INIT INCOMPLETE (Cargo.toml/crates/Justfile absent — Phase-3 prerequisite).

### OPS NOTES FOR NEXT SESSION
compact-state v5.26 COMPLETE. P2A-007 fix-burst COMPLETE (D-214; 3 findings 2M/1L). P2A-002 step row archived to burst-log. Next: P2A-008 adversarial re-pass (adversary dispatch, fresh-context; rubric note: TDIV-009 accepted) → 3-CLEAN per BC-5.39.001 → pre-Phase-2-gate consistency audit → Phase-2 gate → Phase 3.

### PENDING HUMAN ACTIONS
1. **E013 (Medium)** — Set `default_branch` to `main` (D-118). `gh repo edit --default-branch main`.
2. **R14/R6 (HIGH, irreversible)** — `cargo login` → `cd .factory/namespace-reservation && bash publish-all.sh`.
3. B1 — `direnv allow .`
4. **TDIV-008** — engine `path_allow` fix requires vendor action.

## Historical Content

| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–337; Phase-2 per-story authoring + holdout scenarios; P2A-001..007 (sample) fix-bursts) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| Adversary pass details (~215 Phase-1 passes; Phase-2 P2A-001..P2A-007) | `cycles/v1.0.0-greenfield/convergence-trajectory.md` |
| Session checkpoints (v4.45..v5.25 archived; v5.25 checkpoint replaced 2026-08-20) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (188+ lessons) | `cycles/v0.0.0-pre-pipeline/lessons.md` + `cycles/v1.0.0-greenfield/lessons.md` |
| Resolved blockers (R1–R5, R7, R9) | `cycles/v1.0.0-greenfield/blocking-issues-resolved.md` |
| Spec artifacts (133 BCs; 14 VPs; 26 ADRs; PRD; L2 domain spec; architecture) | `.factory/specs/` |
| Phase-2 story specs (39 stories; epics; DAG; wave schedule; sprint state) | `.factory/stories/` |
| Holdout scenarios (14 scenarios; SEALED) | `.factory/holdout-scenarios/` |
| Planning artifacts (DTU assessment; semport analysis; market intel; naming; policies.yaml) | `.factory/planning/` + `.factory/semport/` + `.factory/policies.yaml` |
