---
document_type: pipeline-state
level: ops
version: "2.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-12T23:12:22Z
phase: pre-1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: langchain-rs
mode: greenfield+semport
current_step: "market-intelligence-assessment (D-443) trajectory-tail →0→0→0→0"
current_cycle: v0.0.0-pre-pipeline
pipeline: IN_PROGRESS
dtu_required: false
---

<!--
  STATE.md SIZE BUDGET: 143 lines (wc-l) | margin from soft-target (200): +57 | margin from actual (500): +357

  Historical content belongs in cycle files, NOT here:
  - Burst narratives → cycles/<cycle>/burst-log.md
  - Adversary pass details → cycles/<cycle>/convergence-trajectory.md
  - Old session checkpoints → cycles/<cycle>/session-checkpoints.md
  - Lessons learned → cycles/<cycle>/lessons.md
  - Resolved blockers → cycles/<cycle>/blocking-issues-resolved.md

  Run /vsdd-factory:compact-state if this file grows past 200 lines.
-->

# Pipeline State: langchain-rs (working name)

## Project Metadata

| Field | Value |
|-------|-------|
| **Product** | langchain-rs (working name — final naming under research, D6) |
| **Repository** | /Users/jmagady/Dev/langchain-rs |
| **Mode** | greenfield + semport (Python→Rust semantic port) |
| **Language** | Rust (target), Python (reference corpus) |
| **Target Workspace** | Single Cargo workspace (D4) |
| **Reference Corpus** | .reference/ (gitignored) — langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 |
| **Started** | 2026-07-12 |
| **Last Updated** | 2026-07-12 trajectory-tail →0→0→0→0 |
| **Current Phase** | pre-1 (pre-pipeline) |
| **Current Step** | market-intelligence-assessment (D-443) |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | in-progress | 2026-07-12 | — | pending | — |
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
| Toolchain preflight | dx-engineer | DONE (WARN) | .factory/preflight-report.md |
| Reference corpus clone (3 repos pinned) | devops-engineer | DONE | .factory/semport/reference-manifest.md |
| External research — LangChain v1 architecture | research-agent | DONE | .factory/semport/langchain-research.md |
| market-intelligence-assessment | research-agent | pending | — |
| semport-analyze (reference corpus) | codebase-analyzer | pending | — |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D1 | Full ecosystem port: langchain-core, langchain v1 (libs/langchain_v1; skip classic), text-splitters, 15 partner packages, FULL langgraph (runtime + checkpoints + pg/sqlite + prebuilt + Platform SDK/CLI), FULL langchain-community (~1,051 modules, roadmap-phased) | Maximize Rust ecosystem value | pre-1 | 2026-07-12 | human |
| D2 | Reference version: langchain==1.3.13 (SHA 42f8f79), langgraph==1.2.9 (SHA 95af6a0), langchain-community==v0.4.2 (SHA 7c10a5f) | Latest stable v1 line; full pins in reference-manifest.md | pre-1 | 2026-07-12 | human |
| D3 | Early integrations: OpenAI, Anthropic, Ollama first; then full partner set | Unblocks core use-cases earliest | pre-1 | 2026-07-12 | human |
| D4 | Single Cargo workspace, one repo, one pipeline; crates publish individually | Simplest topology for first release cycle | pre-1 | 2026-07-12 | human |
| D5 | semport-analyze must emit dependency-disposition.md per package (map/port/eliminate); numpy→ndarray, pandas→polars default; pydantic→serde/schemars requires dedicated ADR before BCs | Prevents unreviewed dep choices propagating into BCs | pre-1 | 2026-07-12 | human |
| D6 | Naming UNDER RESEARCH — deciding between keep-langchain-rs-with-crate-suffix vs new distinct brand; `langchain` and `langgraph` crate names TAKEN on crates.io | Naming affects market positioning and crate publication strategy | pre-1 | 2026-07-12 | human |

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R1 | langgraph `scheduler-kafka` removed between 0.3.x and 1.2.9 — confirm new home before porting | Medium | Phase 1/3 | Feeds semport-analyze output |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 3 | Phase community work last per D1 roadmap |
| R3 | LangGraph Platform SDK/CLI in scope → DTU_REQUIRED likely TRUE at P1-06 (proprietary SaaS backend; behavioral clone needed for holdout testing) | High | Phase 1/4 | Assess at P1-06; may become B-001 |
| R4 | Competing active `langgraph` crate on crates.io (updated 2026-07-01) — positioning risk | Medium | Phase 1 | Feeds market-intelligence-assessment gate |
| R5 | Three incompatible tag conventions across reference repos (PyPI `==`, bare semver, path-style) — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling must handle all three |

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
| **Date** | 2026-07-12 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 1 complete. Next: (1) market-intelligence-assessment — mandatory GO/CAUTION/STOP gate; (2) semport-analyze over .reference/ corpus; (3) Phase 1 spec crystallization. trajectory-tail →0→0→0→0 |
| **Key context** | Reference corpus pinned in .reference/ (gitignored). D1-D6 locked. Risks R1-R5 registered. .mcp.json gitignored (plaintext API keys resolved). direnv unenabled (B1). |
| **Convergence counter** | 0 of 3 |

## Historical Content

| Content | Location |
|---------|----------|
| Burst 1 narrative (pre-pipeline) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
