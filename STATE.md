---
document_type: pipeline-state
level: ops
version: "2.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-13T02:15:00Z
phase: pre-1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "all 8 semport passes DONE; D13 ferrochain-server first-party confirmed; R9 downgraded Low; extraction-validation gate IN_PROGRESS (validate-extraction → .factory/semport/VALIDATION-REPORT.md); on PASS → semport CLOSED → Phase 1"
current_cycle: v0.0.0-pre-pipeline
pipeline: IN_PROGRESS
dtu_required: false
---

<!--
  STATE.md SIZE BUDGET: 160 lines (wc-l) | margin from soft-target (200): +40 | margin from actual (500): +340

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
| **Reference Corpus** | .reference/ (gitignored) — langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived upstream — curated-subset reference only), langchain-mcp-adapters==0.3.0 (SHA a61c783a) |
| **Started** | 2026-07-12 |
| **Last Updated** | 2026-07-13 — all 8 semport passes DONE; D13 ferrochain-server first-party confirmed; R9 downgraded to Low; extraction-validation gate dispatched |
| **Current Phase** | pre-1 (pre-pipeline) |
| **Current Step** | extraction-validation gate IN_PROGRESS (validate-extraction agent; output .factory/semport/VALIDATION-REPORT.md); on PASS → semport phase CLOSED → Phase 1 |

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
| adversary pass-0 | not-started | | | | trajectory-tail →0→0→0→0 |
| fix burst 0 | not-started | | | | trajectory-tail →0→0→0→0 |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/v0.0.0-pre-pipeline/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| D12 file-size standard locked (human-approved, research-validated) | human | DONE | Production 500 soft/750 hard LOC; tests 1,000/1,500; tokei Code metric; CI xtask check-file-size + clippy::too_many_lines=150; xtask/file-size-allowlist.toml for exceptions; cohesion clause (split-by-concern, no over-splitting); CLAUDE.md codified |
| semport-analyze pass 6 — platform SDK/CLI | codebase-analyzer | DONE | .factory/semport/platform/ (5 deliverables; SDK 18,728 LOC async-only; auth/runtime/encryption DROP from client crate; CLI 8,383 LOC — validate+schema ~2,500 LOC portable→ferrochain.toml; build/up/dev/deploy DROP/RE-SCOPE; DTU spec: 50+ endpoints, 40+ DTOs, 19 enums; R9 added) |
| semport-analyze pass 7 — core convergence deepening | codebase-analyzer | DONE | .factory/semport/core/ (all 5 deliverables + ANALYSIS-STATE.md; 8 items; 1 HIGH/4 MED/3 LOW novelty; C-1..C-6 contradictions logged; ADR-6/7/8 queued; NOT fully converged → pass 8 dispatched) |
| semport-analyze pass 8 — narrow: RunnableSequence + ADR-3 + langchain-protocol-0.0.17 | codebase-analyzer | DONE | CONVERGED. ADR-5 resolved (transform = streaming primitive, two-default trait, 7 locking tests; tee/stream-duplication = base primitive, unify with ADR-8 start-before-end). ADR-3 enumerated (176 unique keys: 141 core-internal, 12 unsupported, 23 partner/12 packages; alias multiplicity preserved; namespace allowlist DERIVED from registry — eliminates upstream hand-maintained-list drift class). C-7 (LOW count correction) added. langchain-protocol 0.0.17 VERIFIED (strictly additive; content blocks byte-identical to 0.0.15-documented subset; only UsageInfo gained optional token-detail structs). |
| extraction-validation gate | validate-extraction | IN_PROGRESS | .factory/semport/VALIDATION-REPORT.md (pending; validates all 8 passes with C-1..C-7 as known-corrections; on PASS → semport phase CLOSED → Phase 1) |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D1 | AMENDED (human-approved 2026-07-12): langchain-community full 1,051-module port REMOVED from scope. Upstream archived 2026-06-19 (sunset announcement issue #674; replaced by standalone packages + in-app tools + MCP). New integration strategy: (a) integration trait contracts in ferrochain-core, (b) ferrochain-standard-tests conformance suite (port of libs/standard-tests), (c) NEW ferrochain-mcp crate — port of langchain-mcp-adapters, (d) curated demand-ranked community integration crates post-v1, (e) long tail out-of-tree conformance-validated | langchain-community archived upstream — full port is dead scope; MCP adapter is the live integration surface | pre-1 | 2026-07-12 | human |
| D2 | Reference version: langchain==1.3.13 (SHA 42f8f79), langgraph==1.2.9 (SHA 95af6a0), langchain-community==v0.4.2 (SHA 7c10a5f; ARCHIVED — curated-subset reference only), langchain-mcp-adapters==0.3.0 (SHA a61c783a7949719a8c3fbe4aeba961f45f3b7849) | Latest stable v1 line; full pins in reference-manifest.md v1.3.0 | pre-1 | 2026-07-12 | human |
| D3 | Early integrations: OpenAI, Anthropic, Ollama first; then full partner set | Unblocks core use-cases earliest | pre-1 | 2026-07-12 | human |
| D4 | Single Cargo workspace, one repo, one pipeline; crates publish individually | Simplest topology for first release cycle | pre-1 | 2026-07-12 | human |
| D5 | semport-analyze must emit dependency-disposition.md per package (map/port/eliminate); numpy→ndarray, pandas→polars default; pydantic→serde/schemars requires dedicated ADR before BCs | Prevents unreviewed dep choices propagating into BCs | pre-1 | 2026-07-12 | human |
| D6 | RESOLVED — ferrochain (distinct brand; scored 23/25 vs 14/25 for langchain-* suffix; `langchain_rs` name blocked by crates.io name-normalization collision). Crate family: ferrochain, ferrochain-core, ferrochain-graph, ferrochain-checkpoint, ferrochain-openai, ferrochain-anthropic, ferrochain-ollama, ferrochain-community, ferrochain-splitters. Final crate names get ADR in architecture phase. Evidence: .factory/planning/naming-decision-study.md | Distinct brand maximizes positioning; suffix scheme is blocked | pre-1 | 2026-07-12 | human |
| D7 | Wave priority: core → graph → partners. LangGraph runtime + durable checkpointing is the P0 lead differentiator and ships immediately after ferrochain-core | White space analysis confirms graph-runtime-with-checkpointing + conformance suite + formal verification is unoccupied; rig v0.40 competitor velocity HIGH — must lead with graph | pre-1 | 2026-07-12 | human |
| D8 | Reference-application forcing functions + holdout scenario domains (human directive). Two archetypes serve dual purpose: (1) DESIGN FORCING FUNCTIONS for Phase 1 — PRD/architecture must demonstrate these workloads are supportable (capability checklist: durable multi-day graph runs, hierarchical sub-agent delegation/spawning, parallel fan-out, human-approval interrupts mid-run, quality-gate conditional routing, structured outputs, MCP tool integration, checkpoint/resume across process restarts). (2) HOLDOUT SCENARIO DOMAINS for Phase 2 — product-owner authors hidden acceptance scenarios in these domains; specific scenarios stay hidden from implementers per information-asymmetry rules; only the domains are public. Domain A: Virtual SOC analyst agent — long-running security investigations, SIEM/EDR tool calling via MCP, structured triage verdicts, human approval before containment actions, high-volume alert triage. Domain B: Dark factory (autonomous software development orchestrator) — VSDD-style multi-agent software factory built on ferrochain; behavioral references: /Users/jmagady/Dev/vsdd-factory (Rust cargo workspace — design reference for Rust multi-agent orchestration patterns) + https://factory.strongdm.ai/ (verified live HTTP 200). Downstream product concepts (out of this pipeline's scope, deferred to discovery mode post-convergence): SOC-analyst product + build-your-own-agents SaaS. | Concrete reference applications surface capability gaps before spec crystallization; information-asymmetric holdout domains enforce unbiased Phase 4 evaluation | pre-1 | 2026-07-12 | human |
| D9 | ferrochain-graph design consultation gate (human directive). Before ANY ferrochain-graph execution-model ADR is finalized, the architect MUST present ≥2 alternatives with production trade-offs (scheduling model, checkpoint atomicity, backpressure, cancellation, multi-tenant fairness) to the human for a design conversation. The Rust workspace at /Users/jmagady/Dev/vsdd-factory is designated PRIOR ART / EVIDENCE, explicitly NOT a template — "most productionally best, not just prior art" (human's words). Gate applies at Phase 1c architecture. | Human mandate: design consultation before ADR lock prevents premature architecture commit on the highest-risk component | pre-1 | 2026-07-12 | human |
| D10 | Production-grade constitution adopted (human directive). /Users/jmagady/Dev/ferrochain/CLAUDE.md (553 lines) authored by technical-writer from a full harvest of /Users/jmagady/Dev/prism/CLAUDE.md per direct human mandate ("EVERYTHING that applies to us"). Includes: Canonical Principle (Production-Grade Default, six rules + self-audit checklist), Correct Agent Routing companion, Source-of-Truth Precedence, TD-VSDD-053/059/060/091, BC-5.39.001 3-CLEAN w/ strict-vs-PR-merge + frozen-HEAD rules, SID-1, SAP-1 (adapted), day-1 Rust conventions (rustls-tls mandatory, credential newtypes w/ redacted Debug, no-unwrap, non_exhaustive discipline, tokio async-first), git non-negotiables. Binds ALL agents from now (including spec/analysis agents). NOTE: CLAUDE.md sits on main which has no initial commit yet — gets committed in workspace-init commit (devops, Phase 1); do NOT attempt to commit repo-root files outside .factory/. | Human mandate: production-grade agent constitution must be in place before Phase 1 begins | pre-1 | 2026-07-12 | human |
| D11 | ferrochain-graph design steers (from D9 early conversation 2026-07-12; formal ADR ratification still at Phase 1c). D11.1 Execution model: HYBRID — orchestrator-loop engine per run (compile-time write-isolation, single-writer checkpoint atomicity) wrapped by actor-style outer scheduler (multi-tenant fairness/quotas); serves embedded-library AND hosted-SaaS stances. D11.2 Checkpoint wire format: RUST-NATIVE msgpack-based + security-allowlist RCE-guard concept retained + one-way Python-checkpoint import tool; NOT byte-compatible with Python ormsgpack ext-table format. D11.3 Durability: port all three tiers (sync/async/exit) for API parity; ferrochain DEFAULTS to sync (crash-safe) — deliberate documented deviation from upstream defaults per production-grade constitution. | Human design-conversation preceding D9 gate; formal ADR ratification at Phase 1c | pre-1 | 2026-07-12 | human |
| D12 | File size & module splitting standard (human-approved; research-validated in .factory/planning/file-size-standard-study.md). Production files: 500 code-lines soft / 750 hard (CI fail). Test files: 1,000 soft / 1,500 hard. Counted via tokei Code metric (blanks/comments/doc-comments/#[cfg(test)]/generated excluded). Enforcement: required CI job `cargo xtask check-file-size` (created at workspace init, binds from first crate) + clippy::too_many_lines=150 function-level. Exceptions: xtask/file-size-allowlist.toml (path+reason+approver+date, PR-reviewed, audited to shrink); no inline opt-outs. Cohesion clause: split by concern, mod.rs re-export-only, over-splitting is an anti-pattern. Codified in CLAUDE.md Code Conventions + Forbidden Patterns. | Human hypothesis 500/750/1500 CONFIRMED by research with refinements; prevents unreviewed monoliths from accumulating | pre-1 | 2026-07-13 | human |
| D13 | ferrochain-server is a first-party target (human directive, confirmed via structured question). (1) Building ferrochain-server in-workspace (durable runs, threads/assistants/crons/store, streaming); spec'd in Phase 1 alongside client (client+server designed as one system); implemented in waves AFTER core → graph → first partners. (2) NO wire-compatibility goal with LangGraph Platform; no support for langchain's private server backends; SDK-1.2.9 endpoint catalog is design input we own and may diverge from, not a conformance target. (3) DTU scope collapses to genuine third parties only: OpenAI, Anthropic, provider APIs, Ollama local surface for keyless CI. Pass-6 "stateful fake of LangChain's platform" requirement RETIRED. ferrochain-server gets real BCs/holdouts like all first-party code. (4) Pass-6 DROPped server-authoring modules (auth/runtime/encryption) + CLI dev/deploy semantics RE-CLASSIFIED as ferrochain-server design references. (5) D11.1 actor-style outer scheduler is ferrochain-server's core. R9 updated: severity downgraded to Low (design-input staleness only). | First-party server unifies design surface, eliminates DTU conformance burden, enables full BC coverage for all server semantics | pre-1 | 2026-07-13 | human |

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R1 | langgraph `scheduler-kafka` confirmed removed from langgraph 1.2.9. With D1 amended, treat as out-of-scope unless architecture finds a dependency | Low | Phase 1/3 | Effectively resolved by D1 amendment; flag if architecture phase surface it |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 3 | Phase community work last per D1 roadmap |
| R3 | DTU scope revised per D13 — ferrochain-server is first-party (full BCs/holdouts; no DTU clone needed for it). DTU scope collapses to genuine third parties: OpenAI, Anthropic, provider APIs, Ollama keyless CI. Pass-6 "stateful fake" requirement RETIRED. | Low | Phase 1 | Direction resolved by D13 (2026-07-13). Formal DTU assessment still at P1-06 to enumerate final clone list. |
| R4 | Competing active `langgraph` crate on crates.io (updated 2026-07-01) — positioning risk | Medium | Phase 1 | Feeds market-intelligence-assessment gate |
| R5 | Three incompatible tag conventions across reference repos (PyPI `==`, bare semver, path-style) — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling must handle all three |
| R6 | crates.io names verified available; GitHub=BOHICA-LABS/ferrochain registered; publish-all.sh prepped — human has NOT yet run publish-all.sh (cargo login required). Time-sensitive. | High | pre-1 | Pending human action: `cargo login` + run publish-all.sh to reserve all ferrochain-* crate names |
| R7 | langchain-protocol v0.0.17 discovered as upstream dep of langchain-core (semport pass 1); immature package with no stable release. Port-as-provisional strategy. | Medium | Phase 1/3 | Identified in semport pass 1. Strategy: port as provisional, monitor for breaking changes. Full schema in .factory/semport/core/ANALYSIS-STATE.md |
| R8 | Splitters code-point vs byte-length parity: upstream `len()` calls on text are code-point counts, not byte counts — produces different split boundaries on non-ASCII input. NOT covered by any upstream test (no non-ASCII test vector exists). Risk that ferrochain-splitters silently diverges on Unicode-heavy workloads with no behavioral signal. | High | Phase 1/3 | CRITICAL parity risk (semport pass 5). Must become explicit BC + holdout scenario candidate. Route to product-owner at Phase 1 gate. Also flagged: json.dumps separator fidelity + BeautifulSoup-vs-html5ever DOM parity (medium). |
| R9 | Platform API churn re-classified per D13 — LangGraph Platform SaaS is design reference only, not a conformance target. Risk applies as design-input staleness: SDK-1.2.9 endpoint catalog should be reviewed for relevant changes at each spec revision cycle. DTU conformance requirement RETIRED. | Low | Phase 1 | Per D13 (2026-07-13): severity downgraded from High to Low; no DTU re-conformance obligation. |

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

## Concurrent Cycles

| Cycle | Status | Started | Phase |
|-------|--------|---------|-------|
| v0.0.0-pre-pipeline | active | 2026-07-12 trajectory-tail →0→0→0→0 | pre-1 |

## Session Resume Checkpoint

<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v0.0.0-pre-pipeline/session-checkpoints.md. -->

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 8 complete. ALL 8 semport passes DONE. Pass 8 CONVERGED: ADR-5 resolved (transform = streaming primitive; tee/stream-duplication = base primitive, unify with ADR-8 start-before-end; 7 locking tests); ADR-3 enumerated (176 unique keys: 141 core-internal, 12 unsupported, 23 partner; namespace allowlist DERIVED from registry); C-7 added; langchain-protocol 0.0.17 VERIFIED (strictly additive). D13 locked: ferrochain-server is first-party (built in-workspace, spec'd Phase 1, implemented after core→graph→first-partners; NO wire-compat with LangGraph Platform). R3 and R9 downgraded to Low. Extraction-validation gate IN_PROGRESS (validate-extraction agent; output .factory/semport/VALIDATION-REPORT.md). On PASS → semport phase CLOSED → Phase 1 spec crystallization opens. |
| **Key context** | D1-D13 locked. D13: ferrochain-server first-party; DTU scope = OpenAI/Anthropic/providers/Ollama only; stateful-platform-fake RETIRED. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + trade-offs to human before ADR lock. D11 formal ADR at Phase 1c. ADR queue: ADR-1..ADR-8+ all pending architecture phase. Phase 1 gate agenda: D13 server API shape, CLI re-scope, subagent-transformer non-goal, RemoteGraph parity depth, license/attribution, crate-name ADR, slimmed DTU assessment (third-parties only). |
| **Convergence counter** | 0 of 3 |

## Historical Content

| Content | Location |
|---------|----------|
| Burst 1 narrative (pre-pipeline) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 3 narrative (market-intelligence gate close, repo-init, D1 amendment, semport dispatch) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 4 narrative (D9/D10, semport pass 1 close, passes 2-3 start) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 5 narrative (passes 2-3 DONE, D11 design steers, passes 4-5 dispatch) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 6 narrative (passes 4-5 DONE, D12 locked, R8 added, passes 6-7 dispatch) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 7 narrative (passes 6-7 DONE, R9 added, C-1..C-6 logged, ADR-6/7/8 queued, pass 8 dispatch) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 8 narrative (pass 8 CONVERGED, D13 locked, R3/R9 downgraded, extraction-validation gate dispatch) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 5 checkpoint (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` |
| Burst 6 checkpoint (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` |
| Burst 7 checkpoint (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` |
| Naming decision study | `.factory/planning/naming-decision-study.md` |
| File-size standard study | `.factory/planning/file-size-standard-study.md` |
| Semport pass 1 analysis state (deepening items, risks) | `.factory/semport/core/ANALYSIS-STATE.md` |
