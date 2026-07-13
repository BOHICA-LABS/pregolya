---
document_type: pipeline-state
level: ops
version: "2.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-12T23:35:00Z
phase: pre-1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "semport-analyze pass 1 dispatched — codebase-analyzer on langchain-core (libs/core), output .factory/semport/core/"
current_cycle: v0.0.0-pre-pipeline
pipeline: IN_PROGRESS
dtu_required: false
---

<!--
  STATE.md SIZE BUDGET: 146 lines (wc-l) | margin from soft-target (200): +54 | margin from actual (500): +354

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
| **Last Updated** | 2026-07-12 — market-intelligence gate PASSED; semport-analyze dispatched |
| **Current Phase** | pre-1 (pre-pipeline) |
| **Current Step** | semport-analyze pass 1 — codebase-analyzer on langchain-core (libs/core) |

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
| Naming decision study | research-agent | DONE | .factory/planning/naming-decision-study.md |
| market-intelligence-assessment | business-analyst | DONE | .factory/planning/market-intel.md (PASSED — GO w/ conditions) |
| repo-initialization (parts 1+2) | devops-engineer | DONE | GitHub=BOHICA-LABS/ferrochain; local=/Users/jmagady/Dev/ferrochain; placeholder crates prepped; publish-all.sh ready |
| semport-analyze pass 1 — langchain-core | codebase-analyzer | IN_PROGRESS | .factory/semport/core/ (pending) |
| semport-analyze (remaining packages) | codebase-analyzer | pending | .factory/semport/ |

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

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R1 | langgraph `scheduler-kafka` confirmed removed from langgraph 1.2.9. With D1 amended, treat as out-of-scope unless architecture finds a dependency | Low | Phase 1/3 | Effectively resolved by D1 amendment; flag if architecture phase surface it |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 3 | Phase community work last per D1 roadmap |
| R3 | LangGraph Platform SDK/CLI in scope → DTU_REQUIRED likely TRUE at P1-06 (proprietary SaaS backend; behavioral clone needed for holdout testing) | High | Phase 1/4 | Assess at P1-06; may become B-001 |
| R4 | Competing active `langgraph` crate on crates.io (updated 2026-07-01) — positioning risk | Medium | Phase 1 | Feeds market-intelligence-assessment gate |
| R5 | Three incompatible tag conventions across reference repos (PyPI `==`, bare semver, path-style) — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling must handle all three |
| R6 | crates.io names verified available; GitHub=BOHICA-LABS/ferrochain registered; publish-all.sh prepped — human has NOT yet run publish-all.sh (cargo login required). Time-sensitive. | High | pre-1 | Pending human action: `cargo login` + run publish-all.sh to reserve all ferrochain-* crate names |

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
| **Position** | pre-1, burst 3 complete. market-intelligence gate PASSED (GO with conditions, human-approved). B2 RESOLVED: GitHub=BOHICA-LABS/ferrochain, local=/Users/jmagady/Dev/ferrochain, worktree repaired. D1 AMENDED: community full port removed, ferrochain-mcp added. D7 NEW: wave priority core→graph→partners. semport-analyze pass 1 dispatched on langchain-core (libs/core). Next: complete semport passes, then Phase 1 spec crystallization. |
| **Key context** | ferrochain RESOLVED (D6). R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). D1-D7 locked. Ref corpus: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived; curated subset), langchain-mcp-adapters==0.3.0. .mcp.json gitignored. direnv unenabled (B1). R1 LOW: scheduler-kafka out of scope per D1 amendment. |
| **Convergence counter** | 0 of 3 |

## Historical Content

| Content | Location |
|---------|----------|
| Burst 1 narrative (pre-pipeline) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Naming decision study | `.factory/planning/naming-decision-study.md` |
