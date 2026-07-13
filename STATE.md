---
document_type: pipeline-state
level: ops
version: "2.1"
status: in-progress
producer: state-manager
timestamp: 2026-07-14T05:30:00Z
phase: pre-1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "D16 assessment COMPLETE — awaiting HUMAN DIRECTION GATE (Q1-Q9); Phase 1 blocked on human"
current_cycle: v0.0.0-pre-pipeline
pipeline: IN_PROGRESS
dtu_required: false
user_directive_persistent: "Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes." (verbatim, 2026-07-13)
---

<!--
  STATE.md SIZE BUDGET: 198 lines (wc-l) | margin from soft-target (200): +2 | margin from hard-limit (500): +302

  Historical content belongs in cycle files, NOT here:
  - Burst narratives → cycles/<cycle>/burst-log.md
  - Adversary pass details → cycles/<cycle>/convergence-trajectory.md
  - Old session checkpoints → cycles/<cycle>/session-checkpoints.md
  - Lessons learned → cycles/<cycle>/lessons.md
  - Resolved blockers → cycles/<cycle>/blocking-issues-resolved.md

  Run /vsdd-factory:compact-state if this file grows past 200 lines.
-->

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
| **Last Updated** | 2026-07-14 — burst 67: D16 comparative best-patterns assessment COMPLETE. COMPARATIVE-ASSESSMENT.md (522 lines) + 3 part-files written. Dispositions: 27 ADOPT / 16 ADAPT / 27 REJECT / 27 NOT-APPLICABLE. 10 cross-corpus conflicts (CRITICAL: adk-rust lacks BSP determinism, per-task durability, resume-value HITL — all D9/D11-required). RECOMMENDED: (b) HYBRID — LangChain API surface + 43 ADOPT/ADAPT patterns; 9 human-gate questions (Q1 blocks). Recovered via 4-part decomposition. HUMAN DIRECTION GATE open. |
| **Current Phase** | pre-1 (pre-pipeline) |
| **Current Step** | D16 assessment COMPLETE — awaiting HUMAN DIRECTION GATE (Q1-Q9); Phase 1 blocked on human |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | in-progress | 2026-07-12 | — | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23) | — |
| 1: Spec Crystallization | not-started | | | | |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/v0.0.0-pre-pipeline/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| D16 comparative best-patterns assessment (4-part decomposed synthesis) | architect | COMPLETE | COMPARATIVE-ASSESSMENT.md written (522 lines) + 3 part-files. Dispositions across all 97 patterns: 27 ADOPT / 16 ADAPT / 27 REJECT / 27 NOT-APPLICABLE. 10 cross-corpus design conflicts (CRITICAL: adk-rust graph engine lacks BSP determinism, per-task durability, resume-value HITL — all D9/D11-required). 17 negative-evidence must-not-inherit items. RECOMMENDED outcome: (b) HYBRID — LangChain API surface + 43 ADOPT/ADAPT adk-rust internal patterns; runner-up (a) pure LangChain port. 9 human-gate questions (Q1 outcome choice blocking). Note: monolithic dispatch failed 3x on API stream stalls; recovered via 4-part decomposition. Burst 67. |
| adk-rust certification pass C23 (strict-zero, GATE-CLOSING pass) | validate-extraction | COMPLETE | CLEAN(strict)=YES. ZERO corrections. C22 sibling check 3/3 CONFIRMED; dep-disp A1 version defect-class check 8/8 zero discrepancies. Rotation 10/10 CONFIRMED (graph §7.1/§7.2 negative-existence claims, §15 ScopeGuard/ScopedTool/AuditSink 4 impls, §17 cancel_token, dep-disp A3 a2a-protocol-types + thiserror error types, test-inventory A2 property-test file ratio, §15 RequestContextExtractor). Metrics 8/8 Delta=0. Novel probe: dep-disp A3 anyhow exposure-cluster confinement — grep 0 hits across all 8 library src dirs, CONFIRMED. Streak 2/3 → 3/3. **3-CLEAN GATE CLOSED** on adk-rust v1.0.0 (SHA a6c79b6f). Cumulative C1–C23: 0 hallucinations. Burst 66. |
| adk-rust certification pass C22 (strict-zero, C21 sibling check + dep-disp continuation) | validate-extraction | COMPLETE | CLEAN(strict)=YES. ZERO corrections. C21 sibling check 3/3 CONFIRMED (P-18, P-75, P-16 resolution); dep-disp A2 continuation 4/4 CONFIRMED. Rotation 10/10 CONFIRMED (sqlite rewind, has_intersection, RecursionLimitExceeded, rewind impl coverage, pending_nodes restore, SequentialAgent=LoopAgent(1), DEFAULT_LOOP_MAX_ITERATIONS=1000, /health route, memory search scoping, provider crate versions). Metrics 8/8 Delta=0. Novel probe: dep-disp A4 dependency versions vs Cargo.toml — 6/6 exact (wasmtime 45, wasmtime-wasi 44, bollard 0.18, serde_yaml 0.9, statrs 0.18, quick-xml 0.37). Streak 1/3 → 2/3. Burst 65. |
| adk-rust certification pass C21 (strict-zero, C20 defect-class sweep opener) | validate-extraction | COMPLETE | CLEAN(strict)=YES. ZERO corrections. C20-01 landing CONFIRMED; C20 defect-class sweep (count-methodology consistency, A1/A2/A4 tables) CLEAN. Rotation 10/10 CONFIRMED (P-02, P-18, P-53, P-64, P-74, P-75, P-82, P-97, P-16 resolution, dep-disp A4 windows-sys). Metrics 8/8 Delta=0. Novel probe: dependency-disposition A2 internal claims vs source — 3/3 CONFIRMED (checkpoint SQL schema, similar crate char-diff, Uuid::new_v4). Streak 0/3 → 1/3. Burst 64. |
| adk-rust certification pass C20 (strict-zero, gate-closing attempt, A5 per-crate recount probe) | validate-extraction | COMPLETE | CLEAN(strict)=NO. 1 MEDIUM correction (C20-01): test-inventory A5 adk-mistralrs ~264→~282 — prior sweep correction had excluded proptest! for this crate only (methodology inconsistency; recount 245 #[test] + 19 #[tokio::test] + 18 proptest! = 282). C19 sibling check 4/4 CLEAN; cross-doc A5 probe CONSISTENT. Rotation 10/10 CONFIRMED. Metrics 8/8 Delta=0. Novel probe: A5 per-crate recount 10/11 exact. Streak RESET 2/3 → 0/3. Burst 63. |

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

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R1 | langgraph `scheduler-kafka` confirmed removed from langgraph 1.2.9. With D1 amended, treat as out-of-scope unless architecture finds a dependency | Low | Phase 1/3 | Effectively resolved by D1 amendment |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 3 | Phase community work last per D1 roadmap |
| R3 | DTU scope revised per D13 — ferrochain-server is first-party. DTU = OpenAI, Anthropic, provider APIs, Ollama keyless CI. Pass-6 "stateful fake" RETIRED. | Low | Phase 1 | Direction resolved by D13 |
| R4 | Competing active `langgraph` crate on crates.io (updated 2026-07-01) — positioning risk | Medium | Phase 1 | Feeds market-intelligence-assessment gate |
| R5 | Three incompatible tag conventions across reference repos — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling must handle all three |
| R6 | crates.io names verified available; GitHub=BOHICA-LABS/ferrochain registered; publish-all.sh prepped — human has NOT yet run publish-all.sh (cargo login required). Time-sensitive. | High | pre-1 | Pending human action: `cargo login` + run publish-all.sh to reserve all ferrochain-* crate names |
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
| Adversary passes completed | 0 |
| Fix bursts completed | 0 |
| Convergence counter | 3 of 3 — GATE CLOSED |
| Finding trajectory | trajectory-tail →1→1→0→0→1→2→0→1→1→0→0→1→0→0→0 (C23: CLEAN; 3/3 GATE CLOSED) |

## Session Resume Checkpoint

<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v0.0.0-pre-pipeline/session-checkpoints.md. -->

### RESUME IN ONE BREATH

ferrochain pre-pipeline. ALL pre-pipeline work COMPLETE. Corpus 1 (LangChain semport, 7 areas) CONVERGED — extraction gate closed 3/3 strict-zero. Corpus 5 (adk-rust comparative, 97 patterns) analysis CONVERGED; 3-CLEAN GATE CLOSED C21-C23 (0 cumulative hallucinations). D16 comparative assessment COMPLETE: COMPARATIVE-ASSESSMENT.md (522 lines) + 3 part-files. 27 ADOPT / 16 ADAPT / 27 REJECT / 27 NOT-APPLICABLE; 10 cross-corpus conflicts (CRITICAL: adk-rust lacks BSP determinism, per-task durability, resume-value HITL). RECOMMENDED: (b) HYBRID — LangChain API surface + 43 ADOPT/ADAPT adk-rust patterns. 9 human-gate Qs (Q1 = outcome choice, blocks Phase 1). NEXT ACTION: HUMAN DIRECTION GATE — present COMPARATIVE-ASSESSMENT.md §7 Q1-Q9; on answers record D17 and enter Phase 1.

### HEADS

| Repo | Branch | SHA | Pushed | Notes |
|------|--------|-----|--------|-------|
| factory-artifacts | factory-artifacts | (burst 67 commit — run `git -C .factory log -1 --format='%h'`) | YES — BOHICA-LABS/ferrochain | Durable artifact backup |
| main | main | ZERO COMMITS | LOCAL-ONLY | Untracked on disk: CLAUDE.md (553-line constitution + D12 file-size rule), .gitignore, .envrc, .mcp.json — BACKUP BOUNDARY: these exist only on this machine; CLAUDE.md commit to main is scheduled at workspace-init per D10 |

No worktrees. No PRs. Reference clones (.reference/: langchain@langchain==1.3.13, langgraph@1.2.9, langchain-community@libs/community/v0.4.2, langchain-mcp-adapters@0.3.0, adk-rust@v1.0.0) are gitignored local clones — reproducible from the pinned manifest, not backed up by design.

### WORKSTREAM

**D16 COMPLETE.** COMPARATIVE-ASSESSMENT.md (522 lines, 4-part decomposed synthesis). Monolithic dispatch failed 3× on API stream stalls; recovered via decomposition (part-1: P01-P50, part-2: P51-P97, part-3: conflicts + negative evidence). Corpus 1 (LangChain/LangGraph semport) vs Corpus 5 (adk-rust v1.0.0, 97 certified patterns) under RUST-BLINDNESS RULE. Outcome: 43 ADOPT/ADAPT, 10 critical conflicts, 17 must-not-inherit items.

**RESUME NEXT-ACTION:** HUMAN DIRECTION GATE. Present COMPARATIVE-ASSESSMENT.md §7 questions Q1-Q9. Q1 = outcome choice (recommended: (b) HYBRID — LangChain API surface + 43 ADOPT/ADAPT adk-rust patterns; runner-up: (a) pure LangChain port). On all answers, record as D17 and enter Phase 1 spec crystallization.

### PENDING HUMAN ACTIONS (open)

1. **HUMAN DIRECTION GATE** — review COMPARATIVE-ASSESSMENT.md §7 Q1-Q9 and answer all 9 questions; Q1 = outcome choice (recommended: hybrid). Blocks Phase 1.
2. `direnv allow .` (B1 — Low, blocks key loading)
3. `cargo login` + `.factory/namespace-reservation/publish-all.sh` — R6 namespace race STILL OPEN, time-sensitive

### STANDING DIRECTIVES

| ID | Directive |
|----|-----------|
| D15 | Autonomous loop, never ask to continue — "Keep going until you hit convergence protocol." |
| D14 | Absolute strict-zero: CLEAN(strict) = zero findings; 3 consecutive required |
| D16 | COMPLETE — comparative assessment done; awaiting human direction gate. Phase 1 enters after D17 recorded. |

Holdout domains A/B/C briefs at planning/holdout-domains/. Phase-4 carry-forward: 4 a2a-v1 runtime test obligations. D1-D16 all recorded in Decisions Log above.

### WRAP METADATA

| Field | Value |
|-------|-------|
| **Date** | 2026-07-14 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Burst commit** | (burst 67 — run `git -C .factory log -1 --format='%h %s'`) |
| **Convergence counter** | 3 of 3 — GATE CLOSED |

## Historical Content

| Content | Location |
|---------|----------|
| All burst narratives (bursts 1–41, pre-pipeline semport+cert passes, adk-rust A1–A5, exhaustive sweep) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Validation report archive (passes 1–10, 3,478 lines) | `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` |
| Session checkpoints bursts 5–58 (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` |
| Lessons learned (12 lessons, 12 codified guardrails incl. Guardrail #12 test-count methodology, Drift/Deferral DEFER-001) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Domain A brief (SOC analyst — Phase-1 forcing surfaces) | `.factory/planning/holdout-domains/domain-a-soc-analyst.md` |
| Domain B brief (dark factory — agent-registry, token/cost metering) | `.factory/planning/holdout-domains/domain-b-dark-factory.md` |
| Domain C brief (OpenClaw — channel ingress, personal-memory, local-first) | `.factory/planning/holdout-domains/domain-c-openclaw.md` |
| Reference corpus manifest (v1.4.0 — adk-rust Corpus 5 added) | `.factory/semport/reference-manifest.md` |
| Naming decision study | `.factory/planning/naming-decision-study.md` |
| File-size standard study | `.factory/planning/file-size-standard-study.md` |
| Semport pass 1 analysis state (deepening items, risks) | `.factory/semport/core/ANALYSIS-STATE.md` |
| D16 comparative assessment + 3 part-files (COMPARATIVE-ASSESSMENT.md synthesis) | `.factory/comparative/COMPARATIVE-ASSESSMENT.md` (+ `assessment-parts/`) |
