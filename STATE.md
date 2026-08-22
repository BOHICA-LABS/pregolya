---
document_type: pipeline-state
level: ops
version: "5.53"
status: in-progress
producer: state-manager
timestamp: "2026-08-22T17:58:00Z"
phase: 2
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: pregolya
mode: greenfield+semport
current_step: "P2A-032 RESOLVED (validator-first; D-240; 2026-08-22): 45/59 drift citations were parser false-positives; 14 genuine re-anchored across 8 stories. verify-ac-pc-trace.sh BLOCKING (0 DRIFT/519 citations/39 stories; count 14→15); POL-48 registered; S-MAINT-001 added (BC format normalization, out-of-wave). Streak 0/3. NEXT: adversary P2A-033. trajectory-tail →3→2→1→0"
current_cycle: v1.0.0-greenfield
convergence_status: "Phase-1 CLOSED (burst-325; D-197; 2026-08-18). 3/3 CONVERGED on frozen anchor 79eb2f3 (D-195). Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout COMPLETE 14/14 (SEALED). P2A-001..031 COMPLETE D-208..D-238 (sample). P2A-032 RESOLVED (D-240; validator-first; 14 genuine fixes; verify-ac-pc-trace.sh BLOCKING 0/519; POL-48). Streak 0/3. NEXT: P2A-033. Full trajectory: cycles/v1.0.0-greenfield/convergence-trajectory.md."
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "DIRECTIVE 1 (2026-07-13): Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes. DIRECTIVE 2 (2026-07-29): fix-in-scope is the DEFAULT posture; deferral requires explicit per-case human permission; CLAUDE.md Canonical Principle Rule 3 UNCHANGED. Agents may NOT self-authorize deferrals. Orchestrator may PROPOSE deferrals but default action is to fix."
---

<!-- STATE.md SIZE BUDGET: 187 lines (wc-l) | margin from soft-target (200L): +13 lines | margin from actual: +13 lines | v5.53 (2026-08-22): P2A-032 RESOLVED (D-240); validator-first fix; verify-ac-pc-trace.sh BLOCKING 0/519; POL-48; S-MAINT-001. Streak 0/3. NEXT: P2A-033. -->

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
| **Last Updated** | 2026-08-22 — v5.53; P2A-032 RESOLVED (D-240; validator-first; 14 genuine fixes; verify-ac-pc-trace.sh BLOCKING 0/519; POL-48; S-MAINT-001 added). Streak 0/3. NEXT: P2A-033. trajectory-tail →3→2→1→0 |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | COMPLETE | 2026-07-14 | 2026-08-18 | 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195); input-hash drift resolved (D-196); Phase-1 gate CLOSED (D-197; burst-325). ~215 adversarial passes total. Full detail: cycles/v1.0.0-greenfield/convergence-trajectory.md | trajectory-tail →1→0→0→0; 3/3 CONVERGED |
| 2: Story Decomposition | IN PROGRESS | 2026-08-18 | | Structural decomp COMPLETE (D-198); per-story authoring COMPLETE 39/39 D-199..D-206 (sample); holdout scenarios COMPLETE 14/14 (D-207; SEALED). P2A-001..031 fix-bursts COMPLETE D-208..D-238 (sample). P2A-032 RESOLVED (D-240; validator-first). NEXT: P2A-033. | trajectory-tail →2→3→2→1→RESOLVED; 0/3. NEXT: P2A-033. |
| 2: P2A-001..031 (compressed; archived burst-log+trajectory 2026-08-22) | COMPLETE | 2026-08-19 | 2026-08-22 | 31 passes + fix-bursts. P2A-001..026 (sample): mixed findings ALL CLOSED (D-208..D-233 (sample)). P2A-027..031 NOT CLEAN (D-234..D-238): P2A-027 D-233 type-flip REVERTED (ADR-014 D2 canonical); P2A-028 CLEAN(strict) streak 1/3; P2A-029 E-MCP-008/009 minted + 115→117 EC; P2A-030 single-underscore + E-PROV-012 + 117→118 EC; P2A-031 S-2.08/S-2.07 AC-trace + D-238 109 Story Anchor backfill (unfilled-anchor class CLOSED). Full: cycles/v1.0.0-greenfield/convergence-trajectory.md + burst-log.md. Census 133 BC/14 VP/118 EC throughout. | trajectory-tail →0→2→3→2; streak RESET after P2A-031 |
| 2: adversary pass-32 (P2A-032) NOT CLEAN → RESOLVED | COMPLETE | 2026-08-22 | 2026-08-22 | CORPUS-WIDE AC→PC drift (1 HIGH class; 59 citations/17 stories; 45 false-positives from parser blind-spots; 14 genuine). VALIDATOR-FIRST (D-239→D-240). verify-ac-pc-trace.sh 3 parser blind-spots found + fixed. RESOLVED (D-240). | trajectory-tail →2→3→2→1→RESOLVED; streak RESET 0/3 |
| 2: P2A-032 fix burst COMPLETE (validator-first; D-240) | COMPLETE | 2026-08-22 | 2026-08-22 | 14 genuine AC re-anchors (8 stories). verify-ac-pc-trace.sh BLOCKING; 0/519 DRIFT. POL-48. S-MAINT-001. | trajectory-tail →RESOLVED; 0/3. NEXT: P2A-033. |
| 3: TDD Implementation | not-started | | | | — |
| 4: Holdout Evaluation | not-started | | | | — |
| 5: Adversarial Refinement | not-started | | | | — |
| 6: Formal Hardening | not-started | | | | — |
| 7: Convergence | not-started | | | | — |

## Current Phase Steps

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| P2A-031 NOT CLEAN pass (2026-08-22) — 2 findings (1H/1M). P2A031-01 (HIGH): S-2.08 AC→PC trace drift. P2A031-02 (MED): S-2.07 AC-001/003 mistrace. D-237 minted. Streak RESET 0/3. | vsdd-factory:adversary | COMPLETE | 2 findings (1H/1M). Streak RESET 0/3. |
| P2A-031 fix-burst (2026-08-22) — all 2 findings closed (D-237) + D-238 corpus-wide BC Story-Anchor backfill (109 Story Anchor fields; unfilled-anchor class CLOSED). Census UNCHANGED 39/133/14/118. | state-manager | COMPLETE | ~111 files + STATE.md + trajectory + sidecar. Streak 0/3. NEXT: P2A-032. |
| P2A-032 NOT CLEAN pass (2026-08-22) — CORPUS-WIDE AC→PC drift detected; ~73% of citation-bearing stories drifted. Human authorized validator-first approach (D-239). verify-ac-pc-trace.sh built ADVISORY. Streak RESET 0/3. | vsdd-factory:adversary + devops-engineer | COMPLETE | 59 drift citations across 17 stories. Streak 0/3. NEXT: batch-fix. |
| SESSION WRAP (2026-08-22) — D-239 minted; verify-ac-pc-trace.sh committed to hooks/; RESUME SNAPSHOT v5.52 written; convergence-trajectory.md P2A-032 entry appended. | state-manager | COMPLETE | STATE.md v5.52 + trajectory + sidecar + hooks/verify-ac-pc-trace.sh. Single commit per TD-VSDD-053. |
| P2A-032 FIX-BURST (2026-08-22) — D-240; 14 genuine AC re-anchors (8 stories); verify-ac-pc-trace.sh parser-fixed+BLOCKING (0/519 DRIFT); pre-commit wired (14→15); POL-48; S-MAINT-001; STATE.md v5.53. | state-manager | COMPLETE | 8 story files + hooks + policies.yaml + STORY-INDEX + STATE.md + trajectory. Single commit per TD-VSDD-053. |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D-1..D-55 (sample) | *Compressed — pre-pipeline + early Phase 1. See `.factory/planning/decisions-archive-pre-p1d.md` (D1–D17) + git history. Key: StreamEvent::GuardrailDecision 12th variant; ecosystem-parity + Domain-E expansion (D21–D23); ActionRisk/ToolConfig/DynTool/as_retriever API canon; TD-VSDD-091 enforcement.* | | pre-1 + Phase 1 | 2026-07-12..07-28 | various |
| D-56..D-135 (sample) | *Compressed — Phase 1 (P1D passes + ops). Key: D-61 SS-15 tenancy; D-65 TrustLevel severity ordering; D-76 BC count 170; D-93 rename to pregolya; D-103 D-93 supersedes D6; D-109 P1D-176 COMPLETE; D-116 container rename; D-118 factory-artifacts default_branch; D-126 5 CRITs CLOSED; D-127 ADR-025+POL-46/47.* | | Phase 1 | 2026-07-28..08-01 | various |
| D-136..D-194 (sample) | *Compressed — Phase 1 convergence cascade. Key: D-143 3-CLEAN streak over spec; D-149 non-ADR §-anchor closed; D-158 ferro-residue+records-lint L12; D-167 Phase-1d CONVERGED 3/3 on 1262ebe; D-170 LCEL scope expansion; D-171 LCEL COMPLETE (BC 129→133; VP 13→14); D-178 EXEC 13th error; D-189..D-194 (sample) streak progression.* | | Phase 1/ops | 2026-08-15..08-18 | various |
| D-195..D-207 (sample) | *Compressed — Phase-1 gate + Phase-2 structural. Key: D-195 Phase-1 3/3 CONVERGED 79eb2f3; D-196 input-hash = bookkeeping (human ruling); D-197 Phase-1 GATE CLOSED burst-325 (133 BC/39 CAP/16 DI/14 VP/26 ADR/114 EC); D-198 Phase-2 structural COMPLETE; D-207 holdout 14/14 SEALED (9 must-pass=64%).* | | Phase 1→2 | 2026-08-18..08-19 | various |
| D-208..D-232 (sample) | *Compressed — Phase-2 P2A-001..025 (sample) + fix-bursts. Key: D-208..D-225 (sample) ALL CLOSED; D-226 scheduler.rs ownership; D-227 VectorStore ordering + rename; D-228 VP-anchor fix; D-229 VP-008 drift; D-230 VP-013 check_risk_floor; D-231 VP-012 seed ceiling + S-2.03↔S-2.09 DAG edge; D-232 CheckpointSaver rename + async put_writes. Census 133 BC/14 VP.* | | Phase 2 | 2026-08-19..08-22 | various |
| D-233 | **P2A-026 NOT CLEAN (1H/1M) ALL CLOSED. VectorStore 7-method surface reconciled to BC-2.21.001 PC-2 canonical. api-surface.md StreamEvent relocated to §pregolya-core. Census UNCHANGED. Streak 0/3.** | Phase-2 pass 26; VectorStore surface fix; StreamEvent relocation | Phase 2 | 2026-08-22 | product-owner/architect/state-manager |
| D-234 | **P2A-027 NOT CLEAN (1H) ALL CLOSED. SELF-CORRECTION OF D-233: D-233 lambda_mult f64→f32 and delete &[String]→&[&str] REVERTED per ADR-014 Decision 2 (architect adjudicated). Census UNCHANGED. Streak 0/3.** | Phase-2 pass 27; D-233 revert; ADR-014 D2 canonical | Phase 2 | 2026-08-22 | architect/product-owner/story-writer/state-manager |
| D-235 | **P2A-028 CLEAN(strict)=YES (streak 1/3). P2A-029 NOT CLEAN (1H/1M; streak RESET) ALL CLOSED. E-MCP-008/009 minted; BC-2.09.001 §PC9 added (overflow RAISE fail-closed); S-2.10 EC-001 re-anchored; error-taxonomy 115→117 EC. Census UNCHANGED.** | Phase-2 P2A-028 CLEAN (1/3); P2A-029 RAISE E-MCP-008/009; 115→117 EC | Phase 2 | 2026-08-22 | product-owner/story-writer/state-manager |
| D-236 | **P2A-030 NOT CLEAN (1H/2M) ALL CLOSED. Single-underscore canonical; S-2.10 AC-trace renumber + AC-026/027 (PC3/PC8); E-PROV-012 ProviderConnectionError minted; 117→118 EC. Census UNCHANGED. Streak 0/3.** | Phase-2 pass 30; single-underscore; AC-trace; E-PROV-012; 117→118 EC | Phase 2 | 2026-08-22 | product-owner/story-writer/state-manager |
| D-237 | **P2A-031 NOT CLEAN (1H/1M) ALL CLOSED. S-2.08 AC→PC traces corrected (BC-2.08.008/013/014) + 5 covering ACs. S-2.07 AC-001/003 retraced to BC-2.07.001 + 2 covering ACs. Census UNCHANGED 39/133/14/118. Streak 0/3.** | Phase-2 pass 31; S-2.08 AC-trace + 5 ACs; S-2.07 retrace + 2 ACs | Phase 2 | 2026-08-22 | story-writer/state-manager |
| D-238 | **109 BC §Story Anchor fields backfilled from STORY-INDEX. Zero coverage gaps. Unfilled-anchor finding class CLOSED. No postcondition/invariant/TV/AC content changed. Census UNCHANGED.** | Corpus-wide BC §Story Anchor backfill; unfilled-anchor class CLOSED | Phase 2 | 2026-08-22 | product-owner/state-manager |
| D-239 | **P2A-032 NOT CLEAN: corpus-wide AC→PC drift — ~73% of citation-bearing stories (17/20) drifted (CHECK 1 nonexistent + CHECK 2 code-absent). Human (senior architect) DECISION 2026-08-22: VALIDATOR-FIRST. DEFER-004-class devops auth granted. verify-ac-pc-trace.sh ADVISORY built; 59 drift citations/17 stories. Streak 0/3. NEXT: PO adjudicates S-2.06 gap, story-writer batch-fix parallel forks, re-run to 0, flip blocking, P2A-033.** | P2A-032 corpus-wide AC→PC drift; validator-first; verify-ac-pc-trace.sh ADVISORY; 59/17 stories | Phase 2 | 2026-08-22 | human (senior architect)/devops-engineer/state-manager |
| D-240 | **P2A-032 RESOLVED via validator-first fix. verify-ac-pc-trace.sh had 3 parser blind-spots (numbered invariants; table edge cases; off-by-one extraction) → 45/59 drift citations false-positive; 14 genuine across 8 stories (S-1.03/1.13/1.16/1.17/1.18/1.20/2.03/2.06). Genuine ACs re-anchored (code-absent → PC/EC with asserted error code; S-2.06 AC-006 → BC-2.14.005 PC-2 + POLICY-8 propagation). Validator made format-agnostic; re-verified 0 DRIFT/519 citations/39 stories; flipped BLOCKING; wired pre-commit-validators.sh (14→15); POL-48 registered. S-MAINT-001 (BC format normalization, EPIC-MAINT, out-of-wave, draft). stash@{0} holds superseded route-around edits. Streak 0/3. NEXT: P2A-033.** | P2A-032 RESOLVED; validator-first fix; verify-ac-pc-trace.sh BLOCKING; POL-48; S-MAINT-001 | Phase 2 | 2026-08-22 | product-owner/story-writer/devops-engineer/state-manager |

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R6 | `pregolya-*` crates.io names NOT reserved. publish-all.sh regenerated. | High | pre-1 | Pending human action: `cargo login` → `cd .factory/namespace-reservation && bash publish-all.sh`. 21 crates unreserved. |
| R8 | Splitters code-point vs byte-length parity: GTV-010/011 grapheme-discriminating vectors added (burst 253). Full byte-level parity coverage lands Phase 3. | High | Phase 1/3 | CRITICAL parity risk. Route to product-owner at Phase 1. |
| R10 | NamedBarrierValue has NO dedicated unit test. EphemeralValue only 3 assert lines. | Medium | Phase 1 | Route to product-owner at Phase 1 |
| R11 | MCP upstream test voids: mcp bare-ToolException re-raise untested; mcp `__aenter__` NotImplementedError untested. | Medium | Phase 1/3 | Route to product-owner at Phase 1 |
| R-009 | No v1 migration path for Python LangGraph checkpoint stores. | Medium | Phase 3/4 | Registered D-73. Route to architect at Phase 3. |

## Skip Log

| Step | Skipped? | Justification |
|------|----------|---------------|
| Phase 0: Codebase Ingestion | yes | Greenfield — no existing Rust codebase to ingest. Replaced by semport-analyze of Python reference corpus. |

## Blocking Issues

| ID | Issue | Severity | Blocking Phase | Owner | Resolution |
|----|-------|----------|----------------|-------|------------|
| B1 | direnv not allowed — .envrc present but unenabled | Low | pre-1 | human | Run `direnv allow .` from project root |
| TDIV-008 | `validate-artifact-path` exits 0 on every invocation — engine `path_allow` resolves relative to engine dir. | High | Phase 1+ | human+engine-vendor | Engine-level path_allow fix requires vendor action. |
| E013 | Repository `default_branch` is `factory-artifacts`. A fresh clone checks out `.factory/` bookkeeping. | Medium | pre-1 | human | Set default_branch to `main` via GitHub repo settings |
| TDIV-009-VENDOR | Engine holdout template mandates `## Category: real-world-corpus`. 12/14 pregolya scenarios non-real-world-corpus. Human-WAIVED P2A-006. Do NOT re-flag. | Low | none (waived) | engine-vendor | Vendor template patch. |

## Drift / Deferrals

| ID | Item | Target | Reason |
|----|------|--------|--------|
| DEFER-003 | Resume procedure should detect+quiesce orphaned prior-session background agents | Phase-1-gate close / first self-improvement wave | Engine concern; authorized per D-168 |
| DEFER-004 | Mechanical canonical-form drift detection (broader scope) | POL-48 realized AC-citation integrity class (D-240). Broader scope (additional validators) awaiting human/devops prioritization. | DIRECTIVE 2 — human must authorize additional devops scope |
| OBS-1 | No validator enforces story-frontmatter `blocks:` ↔ DAG reverse(depends_on) reciprocity. | Phase-2-gate / first self-improvement wave | OPEN — awaiting devops-engineer story OR human-authorized deferral. |
| PGAP-MSGDRIFT | No mechanical gate diffs AC error-message strings against error-taxonomy.md. | Phase-2-gate / first self-improvement wave | OPEN — awaiting follow-up story OR human-authorized deferral. |

## Concurrent Cycles

None active. Phase 2 IN PROGRESS; per-story authoring COMPLETE 39/39; holdout COMPLETE 14/14 (SEALED). P2A-001..032 COMPLETE. P2A-032 RESOLVED (D-240; validator-first; verify-ac-pc-trace.sh BLOCKING; POL-48). NEXT: P2A-033.

## Convergence Status

Counter: **Phase-1 CLOSED (burst-325; D-197; 2026-08-18)**: 3/3 CONVERGED on frozen anchor 79eb2f3 (D-195). Phase 2 IN PROGRESS. P2A-028 CLEAN(strict)=YES (streak 1/3). P2A-029/030/031/032 NOT CLEAN (streak RESET each). P2A-032 RESOLVED (D-240; validator-first; verify-ac-pc-trace.sh BLOCKING; 0/519 DRIFT; POL-48). Streak 0/3. NEXT: P2A-033.

## Session Resume Checkpoint

<!-- v5.53 checkpoint replaces v5.52 — v5.52 archived to cycles/v1.0.0-greenfield/session-checkpoints.md. Keep ONLY the latest checkpoint here. -->

### RESUME IN ONE BREATH
pregolya (Rust semantic port of langchain/langgraph), greenfield+semport, /Users/jmagady/Dev/pregolya. Phase-2 Story Decomposition adversarial convergence (BC-5.39.001 3-CLEAN), streak 0/3. P2A-032 RESOLVED: validator-first fix complete (D-240; 2026-08-22) — verify-ac-pc-trace.sh now BLOCKING (0 DRIFT/519 citations/39 stories), wired into pre-commit + POL-48 registered. 14 genuine AC citations re-anchored across 8 stories. S-MAINT-001 added (out-of-wave BC format normalization, EPIC-MAINT). NEXT: dispatch fresh adversary P2A-033 on new HEAD.

### HEADS
- develop: `644d1ad` — clean, PUSHED, untouched.
- factory-artifacts: run `git -C .factory log -1 --format='%h'` for current HEAD. PUSHED to origin. (Per TD-VSDD-053, no literal SHA pin here.)
- Worktrees: NONE. Open PRs: NONE.

### RESUME NEXT-ACTION (exact, ordered)
1. **adversary P2A-033**: fresh `vsdd-factory:adversary` pass on new HEAD. verify-ac-pc-trace.sh is now BLOCKING so any new AC-citation drift is caught at pre-commit. Instruct output-size discipline + retry protocol (adversary dies to API connection mid-run on long outputs).
2. **state-manager**: If P2A-033 CLEAN(strict): update counter (1/3). If NOT CLEAN: dispatch fix burst per finding severity (BC-5.39.001 3-CLEAN cascade).
3. Phase-2→3 is autonomous per DIRECTIVE 1 on 3/3 CLEAN.

### PENDING USER-APPROVED WORK
No fix-burst pending. P2A-033 dispatching next (autonomous per DIRECTIVE 1). Phase-2→3 autonomous on 3/3 CLEAN.

### DECISION DELTA (this session, not yet in prior snapshots)
D-237 (P2A-031 AC-trace fix; S-2.08/S-2.07; 7 covering ACs). D-238 (109 BC §Story Anchors backfilled; unfilled-anchor class CLOSED). D-239 (P2A-032 NOT CLEAN; validator-first plan approved). D-240 (this burst: P2A-032 RESOLVED; 45/59 false positives; 14 genuine fixes; verify-ac-pc-trace.sh BLOCKING; POL-48; S-MAINT-001).

### STASH NOTE
stash@{0} in main worktree holds superseded route-around edits (droppable after confirming P2A-033 dispatches cleanly against new HEAD).

### OPEN ITEMS FOR PHASE-2 GATE
- verify-ac-pc-trace.sh BLOCKING (POL-48) — REALIZED via D-240. DEFER-004 remains open for broader scope.
- OBS-1 (blocks↔depends_on reciprocity validator), PGAP-MSGDRIFT (AC error-message validator) — open, awaiting devops authorization.
- TDIV-009-VENDOR (human-waived), TDIV-008 (engine path_allow — vendor action required).
- Human actions: E013 (default_branch→main), R6/R14 (cargo login + publish-all.sh), B1 (direnv allow).
- Human verification: D-235 RAISE review at BC-2.09.001 §PC9 (overflow fail-closed; human may override at Phase-2 gate).
- WORKSPACE INIT incomplete (Cargo.toml/crates/ absent — Phase-3 prerequisite).
- Full ACCEPTED/DO-NOT-REFLAG for P2A-033: cycles/v1.0.0-greenfield/convergence-trajectory.md §P2A-032 Fix-Burst (items 28–30) + §P2A-032 pass record (items 25–27).

### OPS LEARNINGS (carry forward)
- sidecar-learning.md re-dirties after every agent stop — streak-transparent `chore:` hygiene commit before each adversary/wave-gate dispatch (fix-burst dispatches are NOT tree-gated).
- Orchestrator: verify governing ADR BEFORE directing any signature/type/name change; sweep the full authority set in one burst.
- Adversary dies to API connection error mid-run on long outputs — instruct output-size discipline + retry.

### PENDING HUMAN ACTIONS
1. **E013 (Medium)** — `gh repo edit --default-branch main`.
2. **R14/R6 (HIGH)** — `cargo login` → `cd .factory/namespace-reservation && bash publish-all.sh`.
3. B1 — `direnv allow .`
4. **TDIV-008** — engine `path_allow` fix requires vendor action.
5. **D-235 RAISE review (recommended)** — BC-2.09.001 §PC9 overflow fail-closed; human may override at Phase-2 gate.

## Historical Content

| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–344+; Phase-2 per-story authoring + holdout scenarios; P2A-001..032 fix-bursts + D-226..D-240 (sample) archived 2026-08-22) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| Adversary pass details (~215 Phase-1 passes; Phase-2 P2A-001..P2A-032; D-228..D-240 (sample) fix-bursts) | `cycles/v1.0.0-greenfield/convergence-trajectory.md` |
| Session checkpoints (v4.45..v5.52 archived; v5.52 replaced 2026-08-22) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (188+ lessons) | `cycles/v0.0.0-pre-pipeline/lessons.md` + `cycles/v1.0.0-greenfield/lessons.md` |
| Resolved blockers (R1–R5, R7, R9, R12/R13) | `cycles/v1.0.0-greenfield/blocking-issues-resolved.md` |
| Spec artifacts (133 BC / 14 VP / 26 ADR; PRD; L2 domain spec; architecture) | `.factory/specs/` |
| Phase-2 story specs (39 product stories + S-MAINT-001 out-of-wave; epics; DAG; wave schedule; sprint state) | `.factory/stories/` |
| Holdout scenarios (14 scenarios; SEALED) | `.factory/holdout-scenarios/` |
| Planning artifacts (DTU assessment; semport analysis; market intel; naming; policies.yaml) | `.factory/planning/` + `.factory/semport/` + `.factory/policies.yaml` |
