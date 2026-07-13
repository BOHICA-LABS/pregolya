---
document_type: pipeline-state
level: ops
version: "2.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-13T08:00:00Z
phase: pre-1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "adk-rust deep passes A4+A5 in progress (A1 COMPLETE 19P, A2 COMPLETE +15P=34P, A3 COMPLETE +12P=46P)"
current_cycle: v0.0.0-pre-pipeline
pipeline: IN_PROGRESS
dtu_required: false
user_directive_persistent: "Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes." (verbatim, 2026-07-13)
---

<!--
  STATE.md SIZE BUDGET: 160 lines (wc-l) | margin from soft-target (200): +40 | margin from hard-limit (500): +340

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
| **Last Updated** | 2026-07-13 — burst 39: adk-rust passes A2+A3 COMPLETE. A2: 15P P-20..P-34 (5S/3N/7W); adk-graph = Pregel vocabulary, edge-walker mechanism; nondeterministic merge order (P-28), step-boundary-only durability (P-29), notification-only interrupt (P-30). A3: 12P P-35..P-46 (4S/2N/6W); budget-governance gap NET-NEW confirmed (P-46); 7 reqwest zero-timeout (P-42). New ADR question: unify graph-checkpoint + session persistence? A4+A5 DISPATCHED parallel. |
| **Current Phase** | pre-1 (pre-pipeline) |
| **Current Step** | adk-rust deep passes A4 (guardrail/sandbox/eval/retry-reflect/skill/plugin/code/browser) + A5 (provider/capability cluster + P-16 resolution + final anyhow verdict) in progress |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | in-progress | 2026-07-12 | — | market-intelligence PASSED (GO w/ conditions, human-approved) | — |
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
| Cert passes 13–17 (extraction cascade) | validate-extraction | DONE — GATE CLOSED | 3-CLEAN achieved (CP15+16+17). 32 total validation runs, ~100 corrections, zero in final 3 passes. All 11 error classes closed. Full record: burst-log.md bursts 33–37. |
| adk-rust pass A1 (broad sweep + 6 deep core crates) | codebase-analyzer | COMPLETE | 19 patterns (10 STRONG/4 NEUTRAL/5 WEAK). Compliance flags: native-tls conflict, reqwest root-store delta. ANALYSIS-STATE.md written. Burst 38. |
| adk-rust pass A2 (state/persistence/orchestration) | codebase-analyzer | COMPLETE | 15P P-20..P-34 (5S/3N/7W). adk-graph = Pregel vocabulary, edge-walker mechanism. Key: transactional session writes (P-20), AEAD encryption+rotation (P-21), DeltaCheckpointer (P-22), BSP write-isolation (P-23), property tests (P-24). Defects: nondeterministic merge order (P-28), step-boundary-only durability (P-29), notification-only interrupt (P-30). Burst 39. |
| adk-rust pass A3 (server/platform/protocols) | codebase-analyzer | COMPLETE | 12P P-35..P-46 (4S/2N/6W). Session-centric A2A-native server; A2A stream+background = STUBS. SSRF-hardened webhooks (P-35), defense-in-depth middleware (P-36), A2A input validation (P-37), auth-as-injected-trait (P-38). Defects: 7 reqwest zero-timeout (P-42), secrets bare String (P-44), non-durable in-memory request-path state (P-43). Budget-governance gap NET-NEW (P-46). Burst 39. |
| adk-rust passes A4+A5 (safety+quality / provider+capability) | codebase-analyzer | IN-PROGRESS | A4: guardrail/sandbox/eval/retry-reflect/skill/plugin/code/browser. A5: providers/realtime/protocols/payments + P-16 duplication resolution + final anyhow verdict. Dispatched parallel. |

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
| Convergence counter | 0 of 3 |
| Finding trajectory | trajectory-tail →0→0→0→0 |

## Session Resume Checkpoint

<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v0.0.0-pre-pipeline/session-checkpoints.md. -->

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 39 complete. adk-rust A1 COMPLETE (19P), A2 COMPLETE (15P P-20..P-34), A3 COMPLETE (12P P-35..P-46). Total: 46 patterns across A1-A3. ANALYSIS-STATE.md + patterns-observed.md updated in .factory/comparative/adk-rust/. Passes A4 (guardrail/sandbox/eval/retry-reflect/skill/plugin/code/browser) + A5 (provider/capability cluster, P-16 resolution, final anyhow verdict) DISPATCHED in parallel. Pending after A4+A5: exhaustive sweep → strict-zero 3-CLEAN → comparative assessment → HUMAN DIRECTION GATE → Phase 1. |
| **Key context** | D1-D16 locked. D16 ACTIVE: Rust-blindness rule in force. RESOLVED from A1 open items: reqwest-timeout-sites (P-42 — 7 sites, zero timeouts, counter-example not template); anyhow-in-library confirmed clean (confined to CLI binaries; final verdict deferred to A5). UNRESOLVED: adk-model vs standalone drift surface (A5 will cover P-16 duplication). New ADR question raised: unify graph-checkpoint + session persistence on one store (adk answers disjoint, LangGraph unifies — to be decided at Phase 1). Compliance flags: native-tls (adk-realtime/livekit, hard conflict), reqwest rustls-tls-native-roots (root store delta). R6 OPEN: cargo login + publish-all.sh (time-sensitive). R8/R10/R11 OPEN: route to product-owner at Phase 1. |
| **Convergence counter** | 0 of 3 |

## Historical Content

| Content | Location |
|---------|----------|
| All burst narratives (bursts 1–37, pre-pipeline semport+cert passes) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Validation report archive (passes 1–10, 3,478 lines) | `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` |
| Session checkpoints bursts 5–36 (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` |
| Lessons learned (all 11 lessons, 11 codified guardrails, Drift/Deferral DEFER-001) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Domain A brief (SOC analyst — Phase-1 forcing surfaces) | `.factory/planning/holdout-domains/domain-a-soc-analyst.md` |
| Domain B brief (dark factory — agent-registry, token/cost metering) | `.factory/planning/holdout-domains/domain-b-dark-factory.md` |
| Domain C brief (OpenClaw — channel ingress, personal-memory, local-first) | `.factory/planning/holdout-domains/domain-c-openclaw.md` |
| Reference corpus manifest (v1.4.0 — adk-rust Corpus 5 added) | `.factory/semport/reference-manifest.md` |
| Naming decision study | `.factory/planning/naming-decision-study.md` |
| File-size standard study | `.factory/planning/file-size-standard-study.md` |
| Semport pass 1 analysis state (deepening items, risks) | `.factory/semport/core/ANALYSIS-STATE.md` |
