---
document_type: pipeline-state
level: ops
version: "2.4"
status: in-progress
producer: state-manager
timestamp: 2026-07-14T16:00:00Z
phase: 1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "Phase 1d pass 23 ready"
current_cycle: v1.0.0-greenfield
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes." (verbatim, 2026-07-13)
---

<!-- STATE.md SIZE BUDGET: 200-line soft limit / 500-line hard limit.
  Historical content → cycle files (burst-log, convergence-trajectory, session-checkpoints, lessons, blocking-issues-resolved).
  Run /vsdd-factory:compact-state if this file grows past 200 lines. -->

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
| **Last Updated** | 2026-07-14 — burst 98: Phase 1d pass 22 — 16 BC re-anchors to capabilities-p0 (reverse-anchor sweep). |
| **Current Phase** | 1 (Spec Crystallization) |
| **Current Step** | Phase 1d adversarial spec convergence — pass 22 remediated; pass 23 ready (0/3 passes clean; 22 standing gates; reverse-anchor 16 BCs re-anchored to capabilities-p0, zero residue) |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | in-progress | 2026-07-14 | | | →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/v1.0.0-greenfield/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| Phase 1d pass 22 + fix burst (reverse-anchor sweep) | adversary + PO | COMPLETE | Pass 22: NOT CLEAN — 1 HIGH (F-P22-01 pass-21 relocation left 16 P0 BCs with dangling capabilities-p1-p2 anchors — reverse-anchor dimension of the relocation; forward tier census was already converged 19/19). 16 files re-anchored (ss-10: 4, ss-11: 6, ss-14: 6), zero residue. Input-hashes refreshed. Trajectory ...→1→1→1. Convergence 0/3. Burst 98. |
| Phase 1d pass 21 + fix burst (capability-tier census) | adversary + BA | COMPLETE | Pass 21: NOT CLEAN — 1 HIGH (F-P21-01 CAP-012/013/016 stuck P1/Wave-2 in L2 while D17 elevation made all constituent BCs P0; NEW CLASS: capability-tier ↔ BC-priority). Fixed + relocated + 19-CAP census drained (16/3/0). All other censuses + 3 novel probes PASS (inputs-arrays, holdout-vs-CAP, prose reads converged). Trajectory ...→3→1. Convergence 0/3. Gates 22. Burst 97. |
| Phase 1d pass 20 + fix burst (E-code variant census) | adversary + PO | COMPLETE | Pass 20: NOT CLEAN — 3 findings (F-P20-01 CRIT E-GRAPH-003/E-CHKPT-003 collision residue on P0 HITL path [burst-77 sweep missed ss-05/ss-10] → E-GRAPH-016/E-CHKPT-006 minted; F-P20-02 MED Checkpointer straggler; F-P20-03 gate widenings §15/§16). Full 86-BC code↔variant census: 40 pairings, zero residue beyond the 6. Trajectory ...→2→3. Convergence 0/3. Gates 21. Burst 96. |
| Phase 1d pass 19 + fix burst (census scope widened) | adversary + PO | COMPLETE | Pass 19: NOT CLEAN — 2 findings, both pass-18-remedy residue (F-P19-01 HIGH 3 AiMessage sites outside census scope; F-P19-02 MED gate-#19 scope hole → widened to all specs/, 6 hits all exempt). Shared-type canon otherwise fully CLEAN in-scope. Trajectory ...→1→4→2. Convergence 0/3. Burst 95. |
| Phase 1d pass 18 + fix burst (shared-type canon) | adversary + BA + PO + architect | COMPLETE | Pass 18: NOT CLEAN — 4 findings (F-P18-01 HIGH layer-correlated type-name splits CheckpointSaver/Store + RunnableConfig/RunConfig — would fail Phase-3 integration; NEW CLASS: shared Rust type identifiers; F-P18-02/03 MED casing + nonexistent variants). CANON: CheckpointSaver + RunnableConfig (upstream LangChain names, D17 fidelity). 3-layer parallel propagation; 26-type census ALL OK; retired spellings 0. Trajectory ...→1→1→1→4. Convergence 0/3. Gates now 19. Burst 94. |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D1 | AMENDED (human-approved 2026-07-12): langchain-community full 1,051-module port REMOVED from scope. Upstream archived 2026-06-19 (sunset announcement issue #674; replaced by standalone packages + in-app tools + MCP). New integration strategy: (a) integration trait contracts in ferrochain-core, (b) ferrochain-standard-tests conformance suite (port of libs/standard-tests), (c) NEW ferrochain-mcp crate — port of langchain-mcp-adapters, (d) curated demand-ranked community integration crates post-v1, (e) long tail out-of-tree conformance-validated | langchain-community archived upstream — full port is dead scope; MCP adapter is the live integration surface | pre-1 | 2026-07-12 | human |
| D2 | Reference version: langchain==1.3.13 (SHA 42f8f79), langgraph==1.2.9 (SHA 95af6a0), langchain-community==v0.4.2 (SHA 7c10a5f; ARCHIVED — curated-subset reference only), langchain-mcp-adapters==0.3.0 (SHA a61c783a7949719a8c3fbe4aeba961f45f3b7849) | Latest stable v1 line; full pins in reference-manifest.md v1.4.0 (adk-rust Corpus 5 added per D16). | pre-1 | 2026-07-12 | human |
| D3 | Early integrations: OpenAI, Anthropic, Ollama first; then full partner set | Unblocks core use-cases earliest | pre-1 | 2026-07-12 | human |
| D4 | Single Cargo workspace, one repo, one pipeline; crates publish individually | Simplest topology for first release cycle | pre-1 | 2026-07-12 | human |
| D5 | semport-analyze must emit dependency-disposition.md per package (map/port/eliminate); numpy→ndarray, pandas→polars default; pydantic→serde/schemars requires dedicated ADR before BCs | Prevents unreviewed dep choices propagating into BCs | pre-1 | 2026-07-12 | human |
| D6 | RESOLVED — ferrochain (distinct brand; scored 23/25 vs 14/25 for langchain-* suffix; `langchain_rs` name blocked by crates.io name-normalization collision). Crate family: ferrochain, ferrochain-core, ferrochain-graph, ferrochain-checkpoint, ferrochain-openai, ferrochain-anthropic, ferrochain-ollama, ferrochain-community, ferrochain-splitters. Final crate names get ADR in architecture phase. Evidence: .factory/planning/naming-decision-study.md | Distinct brand maximizes positioning; suffix scheme is blocked | pre-1 | 2026-07-12 | human |
| D7 | Wave priority: core → graph → partners. LangGraph runtime + durable checkpointing is the P0 lead differentiator and ships immediately after ferrochain-core | White space analysis confirms graph-runtime-with-checkpointing + conformance suite + formal verification is unoccupied; rig v0.40 competitor velocity HIGH — must lead with graph | pre-1 | 2026-07-12 | human |
| D8 | AMENDED (human directive, 2026-07-13): three holdout domains. Domains serve dual purpose: (1) DESIGN FORCING FUNCTIONS for Phase 1 (PRD/architecture capability checklist extended). (2) HOLDOUT SCENARIO DOMAINS for Phase 2. Domain A: Virtual SOC analyst. Domain B: Dark factory (VSDD-style). Domain C: OpenClaw-like personal AI assistant (persistent sessions, multi-channel, local-first). | Domain C surfaces persistent-session + multi-channel + local-first gaps; all three extend Phase 1 checklist | pre-1 | 2026-07-12 | human |
| D9 | ferrochain-graph design consultation gate. Before ANY graph execution-model ADR is finalized, architect MUST present ≥2 alternatives with production trade-offs to human. /Users/jmagady/Dev/vsdd-factory is PRIOR ART / EVIDENCE, NOT a template. Gate applies at Phase 1c. | Human mandate: design conversation before ADR lock on highest-risk component | pre-1 | 2026-07-12 | human |
| D10 | Production-grade constitution adopted. /Users/jmagady/Dev/ferrochain/CLAUDE.md (553 lines) authored by technical-writer from full harvest of /Users/jmagady/Dev/prism/CLAUDE.md per human mandate. NOTE: CLAUDE.md on main, no initial commit yet — committed at workspace-init Phase 1 by devops. | Human mandate: production-grade agent constitution before Phase 1 | pre-1 | 2026-07-12 | human |
| D11 | ferrochain-graph design steers (D9 early conversation; formal ADR at Phase 1c). D11.1 HYBRID engine (orchestrator-loop per run + actor-style outer scheduler). D11.2 RUST-NATIVE msgpack checkpoint format (NOT Python-compatible; one-way import tool). D11.3 All three durability tiers ported; ferrochain DEFAULTS to sync (crash-safe). | Human design-conversation preceding D9 gate | pre-1 | 2026-07-12 | human |
| D12 | File size & module splitting standard (human-approved; .factory/planning/file-size-standard-study.md). Production: 500 code-lines soft / 750 hard (CI fail). Tests: 1,000 soft / 1,500 hard. CI: `cargo xtask check-file-size`. Exceptions: xtask/file-size-allowlist.toml. | Human hypothesis CONFIRMED by research | pre-1 | 2026-07-13 | human |
| D13 | ferrochain-server is first-party (human directive). (1) Built in-workspace. (2) NO wire-compatibility with LangGraph Platform. (3) DTU scope = genuine third parties only: OpenAI, Anthropic, providers, Ollama. Pass-6 "stateful fake" RETIRED. ferrochain-server gets full BCs/holdouts. | First-party server unifies design surface; eliminates DTU conformance burden | pre-1 | 2026-07-13 | human |
| D14 | REAFFIRMED UNAMENDED (human, Level-2 escalation). AMENDED D14.1 (human-approved): exhaustive-sweep-then-3-CLEAN protocol. 7 parallel area validators; exhaustive coverage precedes certification. D14 strict-zero bar UNCHANGED: CLEAN(strict) = zero findings; 3 consecutive required. | Sampling does not converge; coverage precedes certification; strict-zero preserved | pre-1 | 2026-07-13 | human |
| D15 | PERSISTENT HUMAN DIRECTIVE: "Keep going until you hit convergence protocol." Autonomous continuation; no check-ins on gate patience. COMPLETED — extraction gate closed at burst 37. | Human mandate: no orchestrator check-in overhead during convergence loop | pre-1 | 2026-07-13 | human |
| D16 | ACTIVE DIRECTIVE (human, 2026-07-13): adk-rust comparative corpus. TRIGGERED at extraction gate closure. adk-rust v1.0.0 (SHA a6c79b6f) as Corpus 5; identical rigor (analysis → exhaustive sweep → 3-CLEAN). RUST-BLINDNESS RULE: language carries zero evidentiary weight; patterns win on production-grade merit only. Full comparative assessment → all outcomes on table → HUMAN DIRECTION GATE → Phase 1. | Human mandate to evaluate adk-rust with zero language bias; anti-sunk-cost explicit; goal = best product | pre-1 | 2026-07-13 | human |
| D17 | HUMAN DIRECTION GATE (D16) PASSED 2026-07-14: outcome (b) HYBRID adopted — LangChain API surface + 43 ADOPT/ADAPT adk-rust internal patterns per COMPARATIVE-ASSESSMENT.md. All eight scoped recommendations accepted verbatim: (Q2) LangGraph HITL contract (scratchpad/FIFO-resume/node-re-executes) = Phase-1 BC; (Q3) per-task put_writes sync-tier durability = Phase-1 BC; (Q4) budget governance allow/escalate/deny primitive = Phase-1 BC; (Q5) standalone SDK crate split for partners; (Q6) proc-macros (#[tool]/#[entrypoint]/#[task]) in Phase 1/2 gated on D5 ADR; (Q7) top-3 BSP invariants committed as VP obligations before architecture lock; (Q8) content provenance-tag + guardrail-on-ingress = Phase-1 BC; (Q9) R8/R10/R11 into Phase-1 BC backlog. | Human selection at direction gate; assessment recommendation followed | pre-1 | 2026-07-14 | human |

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R1 | langgraph `scheduler-kafka` confirmed removed from langgraph 1.2.9. With D1 amended, treat as out-of-scope unless architecture finds a dependency | Low | Phase 1/3 | Effectively resolved by D1 amendment |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 3 | Phase community work last per D1 roadmap |
| R3 | DTU scope revised per D13 — ferrochain-server is first-party. DTU = OpenAI, Anthropic, provider APIs, Ollama keyless CI. Pass-6 "stateful fake" RETIRED. | Low | Phase 1 | Direction resolved by D13 |
| R4 | langgraph crate 0.2.5 (2026-07-01, pre-1.0) ships Postgres/Sqlite checkpointing. Competitor velocity HIGH confirmed. ferrochain differentiator = GA maturity + conformance suite + formal verification. Watch for their 1.0 release. | Medium | Phase 1/3 | R4 REFRAMED per burst-74 research. Monitor langgraph 1.0 release date. |
| R5 | Three incompatible tag conventions across reference repos — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling must handle all three |
| R6 | crates.io names verified available; GitHub=BOHICA-LABS/ferrochain registered; publish-all.sh prepped — human has NOT yet run publish-all.sh (cargo login required). Time-sensitive. NOTE (burst 79): canonical 18-crate roster established in ARCH-INDEX. publish-all.sh predates sandbox/memory/macros/-sdk additions — MUST BE REGENERATED for all 18 crates before running. | High | pre-1 | Pending human action: `cargo login` + regenerate publish-all.sh for 18 crates + run to reserve all ferrochain-* names |
| R7 | langchain-protocol v0.0.17 — no stable release; schema evolving. Port rationale is version-volatility, not immaturity (v3 streaming has 107 dedicated tests — corrected cert pass 9). | Low | Phase 1/3 | DOWNGRADED from Medium; full schema in .factory/semport/core/ANALYSIS-STATE.md |
| R8 | Splitters code-point vs byte-length parity: upstream `len()` calls on text are code-point counts — different split boundaries on non-ASCII. NOT covered by any upstream test. | High | Phase 1/3 | CRITICAL parity risk. Must become explicit BC + holdout scenario. Route to product-owner at Phase 1. |
| R9 | Platform API churn re-classified per D13 — SDK-1.2.9 endpoint catalog is design reference only; no conformance target. | Low | Phase 1 | Severity downgraded per D13 |
| R10 | Upstream coverage gap: NamedBarrierValue has NO dedicated unit test. EphemeralValue only 3 assert lines. Product-owner must author BCs + tests from behavior. | Medium | Phase 1 | Route to product-owner at Phase 1 |
| R11 | MCP upstream test voids: (1) mcp bare-ToolException re-raise path untested; (2) mcp `__aenter__` NotImplementedError contract untested. Same class as R8 and R10. | Medium | Phase 1/3 | Route to product-owner at Phase 1: must become explicit Red Gate tests |

## Skip Log

| Step | Skipped? | Justification |
|------|----------|---------------|
| Phase 0: Codebase Ingestion | yes | Greenfield — no existing Rust codebase to ingest. Replaced by semport-analyze of Python reference corpus. |

## Blocking Issues

<!-- Open issues only. Move resolved issues to cycles/v0.0.0-pre-pipeline/blocking-issues-resolved.md. -->

| ID | Issue | Severity | Blocking Phase | Owner | Resolution |
|----|-------|----------|----------------|-------|------------|
| B1 | direnv not allowed — .envrc present but unenabled; 4 AWS/Anthropic key names declared | Low | pre-1 | human | Run `direnv allow .` from project root |

## Convergence Status

| Metric | Value |
|--------|-------|
| Adversary passes completed | 22 (Phase 1d) |
| Fix bursts completed | 22 (Phase 1d) |
| Convergence counter | 0 of 3 (Phase 1d; pre-pipeline 3/3 CLOSED) |
| Finding trajectory | (pre-pipeline) →1→1→0→0→1→2→0→1→1→0→0→1→0→0→0 (C23: CLEAN) ‖ (Phase 1d) →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) |

## Session Resume Checkpoint

<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v1.0.0-greenfield/session-checkpoints.md. -->

### RESUME IN ONE BREATH

ferrochain Phase 1d adversarial spec convergence: Pass 22 REMEDIATED — NOT CLEAN. 1 finding: F-P22-01 HIGH pass-21 CAP relocation left 16 P0 BCs with dangling capabilities-p1-p2.md anchors (reverse-anchor dimension of relocation; forward tier census was already converged 19/19). NEW CLASS: reverse-anchor sweep (relocation must be followed by reverse-direction grep). 16 BC files re-anchored (ss-10: 4, ss-11: 6, ss-14: 6) at all sites [traces_to/inputs/justification]; zero residue; input-hashes refreshed on all 16. Trajectory ...→1→1→1. Convergence 0/3. Gates 22. Burst 98.

### HEADS

| Repo | Branch | SHA | Pushed | Notes |
|------|--------|-----|--------|-------|
| factory-artifacts | factory-artifacts | (burst 98 — run `git -C .factory log -1 --format='%h'`) | YES | Durable artifact backup |
| main | main | d018d3f | YES | CLAUDE.md + .gitignore committed (D10); develop initialized |

No worktrees. No PRs. Reference clones (.reference/) gitignored.

### WORKSTREAM

**Burst 98 COMPLETE.** Phase 1d pass 22: 1 finding fixed (F-P22-01 HIGH 16 P0 BCs with dangling capabilities-p1-p2.md anchors; NEW CLASS: reverse-anchor sweep). 16 BC files re-anchored (ss-10: 4, ss-11: 6, ss-14: 6); zero residue confirmed by grep; input-hashes refreshed on all 16. Trajectory ...→1→1→1.

**RESUME NEXT-ACTION:** adversary pass 23 (fresh context): sibling-check pass-22 (reverse-anchor grep re-run + hash freshness on the 16), rotate 4 censuses, free-choice probe or 3 highest-yield regression re-runs if probe space exhausted.

### PENDING HUMAN ACTIONS (open)

1. `direnv allow .` (B1 — Low, blocks key loading)
2. `cargo login` + regenerate + run `.factory/namespace-reservation/publish-all.sh` — R6 STILL OPEN. IMPORTANT: publish-all.sh predates sandbox/memory/macros/-sdk additions — MUST BE REGENERATED for all 18 crates before running.

### STANDING DIRECTIVES

| ID | Directive |
|----|-----------|
| D15 | Autonomous loop, never ask to continue — "Keep going until you hit convergence protocol." |
| D14 | Absolute strict-zero: CLEAN(strict) = zero findings; 3 consecutive required |
| D17 | HYBRID outcome adopted — LangChain API surface + 43 ADOPT/ADAPT adk-rust patterns |

### WRAP METADATA

| Field | Value |
|-------|-------|
| **Date** | 2026-07-14 |
| **Cycle** | v1.0.0-greenfield |
| **Burst commit** | (burst 98 — run `git -C .factory log -1 --format='%h %s'`) |
| **Convergence counter** | 0 of 3 (Phase 1d) |

## Historical Content

| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–74, pre-pipeline semport+cert+adk-rust, Phase 1 A–E, Phase 1d P1–P2) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| 86 Behavioral Contracts (ss-01..ss-17/, ~12,600+ lines) + BC-INDEX.md (48P0/30P1/8P2) | `.factory/specs/behavioral-contracts/ss-NN/` + `BC-INDEX.md` |
| L3 PRD (index + BC summary tables, 607 lines) + v1.0 Step-E annotation (BC-2.08.009) | `.factory/specs/prd.md` |
| PRD supplements: bc-authoring-plan (308), error-taxonomy (146), nfr-catalog (80), module-criticality (155), interface-definitions (303), test-vectors (198) | `.factory/specs/prd-supplements/` |
| L2 domain spec (15-shard, 1,889 lines) | `.factory/specs/domain-spec/L2-INDEX.md` (+ 14 section shards) |
| Validation report archive (passes 1–10, 3,478 lines) | `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` |
| Session checkpoints bursts 5–77 (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (12 lessons, 12 codified guardrails incl. Guardrail #12 test-count methodology, Drift/Deferral DEFER-001) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Holdout domain briefs A/B/C (SOC analyst, dark factory, OpenClaw) | `.factory/planning/holdout-domains/domain-{a,b,c}-*.md` |
| Reference corpus manifest (v1.4.0 — adk-rust Corpus 5 added) | `.factory/semport/reference-manifest.md` |
| Planning studies (naming decision, file-size standard) | `.factory/planning/naming-decision-study.md` + `file-size-standard-study.md` |
| Semport pass 1 analysis state (deepening items, risks) | `.factory/semport/core/ANALYSIS-STATE.md` |
| D16 comparative assessment + 3 part-files (COMPARATIVE-ASSESSMENT.md synthesis) | `.factory/comparative/COMPARATIVE-ASSESSMENT.md` (+ `assessment-parts/`) |
| Architecture core: ARCH-INDEX + 9 section files + ADR-011 (~1,100+ lines), 11 ADRs | `.factory/specs/architecture/` + `decisions/` |
| VP-INDEX + VP-001..005 (D17-Q7 top-3 BSP invariants + MCP integration VPs) | `.factory/specs/verification-properties/` |
| DTU assessment (DTU_REQUIRED: true; 3 cassette clone sets; pre-Phase-3 gate ≥8/7/3) | `.factory/planning/dtu-assessment.md` |
| ADR tech validation (schemars 1.2.1, rmp-serde 1.3.1, Kani 0.67.0 no-async) | `.factory/planning/adr-tech-validation.md` |
| Module criticality assessment (33 modules, architect version) | `.factory/specs/module-criticality.md` |
| CI/CD setup log (workspace-init; d018d3f; ci.yml; branch protection) | `.factory/planning/cicd-setup.md` |
