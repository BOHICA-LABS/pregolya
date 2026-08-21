---
document_type: pipeline-state
level: ops
version: "5.40"
status: in-progress
producer: state-manager
timestamp: "2026-08-21T19:25:00Z"
phase: 2
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: pregolya
mode: greenfield+semport
current_step: "P2A-021 fix-burst COMPLETE (D-227; 2026-08-21): NOT CLEAN (1H/3M/1L) ALL CLOSED — VectorStore ordering S-2.02→S-2.03; add_documents rename swept corpus-wide; BC anchor fills; S-1.25/S-1.16 PSI rewords. trajectory-tail →0→0→2→5. Streak 0/3. NEXT: P2A-022 on post-fix-burst HEAD."
current_cycle: v1.0.0-greenfield
convergence_status: "Phase-1 CLOSED (burst-325; D-197; 2026-08-18). 3/3 CONVERGED on frozen anchor 79eb2f3 (D-195). Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..021 (sample) fix-bursts COMPLETE. P2A-021 NOT CLEAN (1H/3M/1L; D-227; fix-burst COMPLETE 2026-08-21) streak RESET 0/3. NEXT: Phase-2 adversarial P2A-022. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md."
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "DIRECTIVE 1 (2026-07-13): Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes. DIRECTIVE 2 (2026-07-29): fix-in-scope is the DEFAULT posture; deferral requires explicit per-case human permission; CLAUDE.md Canonical Principle Rule 3 UNCHANGED. Agents may NOT self-authorize deferrals. Orchestrator may PROPOSE deferrals but default action is to fix."
---

<!-- STATE.md SIZE BUDGET: 177 lines (wc-l) | margin from soft-target (200L): 23 lines | margin from actual: 23 lines | compact-state v5.40 (2026-08-21): compacted 200L→177L. Extracted Phase-Progress rows P2A-012..018 + verbose Decisions D-195..D-225 (sample) to burst-log.md. NEXT: P2A-022. -->

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
| **Last Updated** | 2026-08-21 — compact-state v5.40; extracted Phase-Progress rows P2A-012..018 + verbose Decisions D-195..D-225 (sample) to burst-log.md; 200L→177L. trajectory-tail →0→0→2→5. NEXT: Phase-2 adversarial P2A-022. |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | COMPLETE | 2026-07-14 | 2026-08-18 | 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195); input-hash drift resolved (D-196); Phase-1 gate CLOSED (D-197; burst-325). ~215 adversarial passes total. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md | trajectory-tail →1→0→0→0; 3/3 CONVERGED |
| 2: Story Decomposition | IN PROGRESS | 2026-08-18 | | Structural decomp COMPLETE (D-198); per-story authoring COMPLETE 39/39 D-199..D-206 (sample); holdout scenarios COMPLETE 14/14 (D-207; SEALED). P2A-001..021 (sample) fix-bursts COMPLETE D-208..D-227 (sample). NEXT: P2A-022. | trajectory-tail →3→3→0→0→2→5; 0/3. NEXT: P2A-022. |
| 2: passes P2A-012..P2A-018 (sample; archived to burst-log 2026-08-21) | COMPLETE | 2026-08-20 | 2026-08-21 | P2A-012..016: 17 findings (2H/7M/7L/1OBS) ALL CLOSED; P2A-017: 3 findings (2M/1L) CLOSED (D-225); P2A-018: CLEAN(strict)=YES streak 1/3. Census 133 BC/14 VP throughout. Full: cycles/v1.0.0-greenfield/convergence-trajectory.md + burst-log.md. | compressed; detail in trajectory+burst-log |
| 2: adversary pass-19 (P2A-019) | COMPLETE | 2026-08-21 | 2026-08-21 | CLEAN(strict)=YES CLEAN(PR-merge)=YES; 0 findings; streak 2/3. All prior fixes HELD. | trajectory-tail →3→0→0; streak 2/3 |
| 2: adversary pass-20 (P2A-020) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 2 findings (1M/1L); streak RESET 0/3; fix-burst dispatched (D-226). F-P2A020-01 (MED,POL-4/46) scheduler.rs ownership conflict; 4 stories inconsistent/false claims. F-P2A020-02 (LOW) S-1.16→S-1.13 rationale absent. | trajectory-tail →0→0→2; streak RESET 0/3 |
| 2: fix burst (post-pass-20 P2A-020) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-020: all 2 findings closed (D-226). F-P2A020-01 CLOSED: scheduler.rs ownership model (S-1.15 creates; S-1.17 run/stream; S-1.13/S-1.18/S-1.16 layer); 5 new DAG edges; Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts. F-P2A020-02 CLOSED: S-1.16→S-1.13 rationale documented. Census 133 BC/14 VP; DAG acyclic. Streak 0/3. NEXT P2A-021. | trajectory-tail →0→0→2; 0/3 → NEXT P2A-021 |
| 2: adversary pass-21 (P2A-021) | COMPLETE | 2026-08-21 | 2026-08-21 | NOT CLEAN: 5 findings (1H/3M/1L); streak RESET 0/3; fix-burst dispatched (D-227). P2A021-01 (HIGH): VectorStore trait ordering inversion; S-2.02/S-2.03 delivery reorder. P2A021-02/03/04 (MED): orphaned-methods BC-2.21.001 PC-2 + S-2.03 ACs; S-1.25 scheduler.rs traceability; wave-schedule max-parallelism 4→6. P2A021-05 (LOW): S-1.16 PSI reworded. add_texts→add_documents rename swept corpus-wide (TD-VSDD-060). | trajectory-tail →0→0→2→5; streak RESET 0/3 |
| 2: fix burst (post-pass-21 P2A-021) | COMPLETE | 2026-08-21 | 2026-08-21 | P2A-021: all 5 findings closed (D-227). BC anchor fills: BC-2.20.003/BC-2.21.001/002/003/004 → S-2.03. Census 133 BC / 14 VP; DAG edges UNCHANGED; no renumber. Streak 0/3. NEXT P2A-022. | trajectory-tail →0→0→2→5; 0/3 → NEXT P2A-022 |
| 3: TDD Implementation | not-started | | | | — |
| 4: Holdout Evaluation | not-started | | | | — |
| 5: Adversarial Refinement | not-started | | | | — |
| 6: Formal Hardening | not-started | | | | — |
| 7: Convergence | not-started | | | | — |

## Current Phase Steps

<!-- Keep last 5 rows only. Older rows archived to cycles/v1.0.0-greenfield/burst-log.md. -->
| Step | Agent | Status | Output |
|------|-------|--------|--------|
| P2A-019 CLEAN pass (2026-08-21) — 0 findings. CLEAN(strict)=YES CLEAN(PR-merge)=YES; all prior fixes HELD. Streak advances 1/3→2/3. | vsdd-factory:adversary | COMPLETE | 0 findings. Streak 2/3. |
| P2A-020 NOT CLEAN pass (2026-08-21) — 2 findings (1M/1L). F-P2A020-01 (MED,POL-4/46) scheduler.rs ownership — 4 stories mutually-inconsistent incl. false claims. F-P2A020-02 (LOW) S-1.16→S-1.13 rationale absent. Streak RESET 0/3. D-226 minted. Fix-burst dispatched. | vsdd-factory:adversary | COMPLETE | 2 findings. Streak RESET 0/3. |
| P2A-020 fix-burst (2026-08-21) — all 2 findings closed (D-226). F-P2A020-01 CLOSED: scheduler.rs ownership model (S-1.15 creates; S-1.17 run/stream; S-1.13/S-1.18/S-1.16 layer); 5 new DAG edges (S-1.17 dep S-1.15; S-1.13/S-1.18/S-1.16 dep S-1.17; S-1.16 dep S-1.18); Wave-1 10→12 batches; critical path 10→12 stories/69→82 pts. F-P2A020-02 CLOSED: S-1.16→S-1.13 rationale documented via PSI rows. D-221 S-1.16↔S-1.13 CONFIRMED. | state-manager | COMPLETE | 8 files + STATE.md + trajectory. Census 133 BC/14 VP. DAG acyclic. Streak 0/3. NEXT: P2A-021. |
| P2A-021 NOT CLEAN pass (2026-08-21) — 5 findings (1H/3M/1L). P2A021-01 (HIGH) VectorStore trait ordering inversion; P2A021-02 (MED) orphaned methods BC-2.21.001 PC-2; P2A021-03 (MED) S-1.25 scheduler.rs traceability; P2A021-04 (MED) wave-schedule max-parallelism 4→6; P2A021-05 (LOW) S-1.16 PSI reword. add_texts→add_documents rename swept corpus-wide (TD-VSDD-060). D-227 minted. Streak RESET 0/3. | vsdd-factory:adversary | COMPLETE | 5 findings. Streak RESET 0/3. |
| P2A-021 fix-burst (2026-08-21) — all 5 findings closed (D-227). VectorStore S-2.02→pregolya-core (2 BCs, 5 pts); S-2.03→vectorstores (5 BCs, 10 pts, MMR/as_retriever ACs). add_documents rename: capabilities, entities, 4 BCs, module-decomp, ADR-014, purity-map, S-2.03. BC-2.20.003+BC-2.21.001/002/003/004 anchors → S-2.03. Census 133 BC/14 VP. DAG UNCHANGED. | state-manager | COMPLETE | ~20 files + STATE.md + trajectory. Census 133 BC/14 VP. DAG UNCHANGED. Streak 0/3. NEXT: P2A-022. |

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

None active. Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..021 (sample) fix-bursts COMPLETE. NEXT: P2A-022. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Convergence Status

Counter: **Phase-1 CLOSED (burst-325; D-197; 2026-08-18)**: 3/3 CONVERGED on frozen anchor 79eb2f3 (D-195). Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout scenarios COMPLETE 14/14 (SEALED). P2A-001..021 (sample) fix-bursts COMPLETE. P2A-021 NOT CLEAN (1H/3M/1L; D-227; fix-burst COMPLETE 2026-08-21) streak RESET 0/3. NEXT: Phase-2 adversarial P2A-022. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md.

## Session Resume Checkpoint

<!-- v5.39 checkpoint replaces v5.38 — v5.38 archived to cycles/v1.0.0-greenfield/session-checkpoints.md. Keep ONLY the latest checkpoint here. -->

### RESUME IN ONE BREATH
Pregolya (Rust semantic port of langchain/langgraph), greenfield+semport, /Users/jmagady/Dev/pregolya. Phase 1 CLOSED. Phase 2 Story Decomposition: content COMPLETE (39 story specs, 133/133 BC coverage, 14 holdout scenarios SEALED). Currently in Phase-2 adversarial story-decomposition convergence (BC-5.39.001 3-CLEAN); streak **0/3**. Adversary passes P2A-001..P2A-021 run; P2A-018/019 CLEAN(strict) (streak 1/3→2/3); P2A-020 NOT CLEAN (1M/1L; D-226; scheduler.rs ownership); P2A-021 NOT CLEAN (1H/3M/1L; D-227; VectorStore ordering + add_documents rename + BC anchors) — streak RESET 0/3 (P2A-021 reset). Fix-burst COMPLETE. NEXT: dispatch a FRESH `vsdd-factory:adversary` pass **P2A-022** on the current post-fix-burst factory-artifacts HEAD (frozen-HEAD baseline reset by this fix-burst push).

### HEADS
- develop `644d1ad` — clean, PUSHED, untouched.
- factory-artifacts: run `git -C .factory log -1 --format='%h'` for the current HEAD. PUSHED to origin. (Per TD-VSDD-053, do NOT pin the SHA literally here — git is source of truth.)
- Worktrees: NONE. Open PRs: NONE.

### CURRENT WORKSTREAM — Phase-2 adversarial story convergence
- Streak **0/3** (BC-5.39.001). P2A-020 RESET (scheduler.rs ownership); P2A-021 RESET (VectorStore ordering + add_documents rename).
- Finding trajectory P2A-001..021: 8→3→7→3→8→2→3→4→8→10→4→2→5→3→5→3→3→0→0→2→5. Axes swept: VP anchors; subsystem-name canon; error-code categories; error-message strings; DAG reciprocity; holdout BC-linkage; purity; VP-011; error-type semantics; mod.rs layout; BC-table priority; target-crate frontmatter; DAG S-1.16→S-1.13; version-literal pins; Wave-2 target-crate; STORY-INDEX subsystem; SDK-split D17-Q5; dep-graph 10-batch; pregolya facade; SS-10 Primary Crate(s) (D-225); SS-06 StreamEvent CORE canonical (D-225); scheduler.rs ownership (D-226); VectorStore trait ordering S-2.02→S-2.03 (D-227); add_documents rename corpus-wide (D-227).
- **RESUME NEXT-ACTION:** dispatch `vsdd-factory:adversary` **P2A-022**, fresh context, Read/Grep/Glob only, Form-B verbatim evidence, FULL POL rubric (POL-1..31 + POL-46/47). ACCEPTED/DO-NOT-REFLAG: (1) F-02/TDIV-009 vendor-template limitation waived (D-220); (2) OBS-1 + PGAP-MSGDRIFT open gaps — report NEW instances only; (3) Primary Crate(s) convention swept ALL 23 SS rows (D-225) — do NOT re-flag absent NEW concrete BC-homing divergence; (4) scheduler.rs ownership model ESTABLISHED (D-226) — do NOT re-flag the coordination model; (5) add_documents is the canonical VectorStore ingestion method (was add_texts; rename swept corpus-wide D-227) — do NOT re-flag. Dual CLEAN(strict)/CLEAN(PR-merge) verdict, frozen-HEAD baseline. CLEAN(strict) → streak 1/3 → P2A-023/024 on SAME HEAD to 3/3.
- **OPS LEARNING (this session):** (a) `sidecar-learning.md` session-hook re-dirties the tree after every agent stop — a streak-transparent `chore:` hygiene commit needed before each adversary dispatch (adversary/wave-gate dispatches BLOCKED on dirty tree; fix-burst dispatches are not); (b) PROPOSED: gitignore `sidecar-learning.md` in `.factory/.gitignore` — DEFER-004 class; requires human authorization before implementing.
- STATE.md over soft target — schedule /compact-state before the next large STATE write.

### PENDING USER-APPROVED WORK
None pending (Phase 2→3 autonomous per DIRECTIVE 1). **F-02/TDIV-009 WAIVED** (vendor-template limitation; D-220).

### OPEN ITEMS FOR PHASE-2 GATE
- TDIV-009-VENDOR (human-waived; durable fix = vendor template change).
- OBS-1 — DAG reciprocity validator pending devops scope authorization.
- PGAP-MSGDRIFT — mechanical gate pending devops scope authorization.
- Human actions: E013 (default_branch→main), R6/R14 (cargo login + publish-all.sh), B1 (direnv allow .), TDIV-008 (vendor). WORKSPACE INIT incomplete (Phase-3 prerequisite).

### DECISION DELTA (this session)
D-226 minted (P2A-020; scheduler.rs ownership). D-227 minted (P2A-021; VectorStore ordering + add_documents rename + BC anchor fills). P2A-018/019 CLEAN(strict); P2A-020/021 RESET. Human F-02/TDIV-009 waiver in effect (D-220).

### PENDING HUMAN ACTIONS
1. **E013 (Medium)** — `gh repo edit --default-branch main`.
2. **R14/R6 (HIGH)** — `cargo login` → `cd .factory/namespace-reservation && bash publish-all.sh`.
3. B1 — `direnv allow .`
4. **TDIV-008** — engine `path_allow` fix requires vendor action.

## Historical Content

| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–343; Phase-2 per-story authoring + holdout scenarios; P2A-001..021 (sample) fix-bursts + session wrap D-220) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| Adversary pass details (~215 Phase-1 passes; Phase-2 P2A-001..P2A-021) | `cycles/v1.0.0-greenfield/convergence-trajectory.md` |
| Session checkpoints (v4.45..v5.38 archived; v5.38 replaced 2026-08-21) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (188+ lessons) | `cycles/v0.0.0-pre-pipeline/lessons.md` + `cycles/v1.0.0-greenfield/lessons.md` |
| Resolved blockers (R1–R5, R7, R9) | `cycles/v1.0.0-greenfield/blocking-issues-resolved.md` |
| Spec artifacts (133 BCs; 14 VPs; 26 ADRs; PRD; L2 domain spec; architecture) | `.factory/specs/` |
| Phase-2 story specs (39 stories; epics; DAG; wave schedule; sprint state) | `.factory/stories/` |
| Holdout scenarios (14 scenarios; SEALED) | `.factory/holdout-scenarios/` |
| Planning artifacts (DTU assessment; semport analysis; market intel; naming; policies.yaml) | `.factory/planning/` + `.factory/semport/` + `.factory/policies.yaml` |
