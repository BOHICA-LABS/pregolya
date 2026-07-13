---
document_type: pipeline-state
level: ops
version: "2.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-14T00:25:00Z
phase: pre-1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "certification pass 9 recorded; gate-strategy decision pending human."
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
| **Last Updated** | 2026-07-13 — burst 26: 3-CLEAN certification pass 9 COMPLETE — CLEAN(strict)=NO. 4 corrections (2 MEDIUM, 2 LOW). Streak 0/3. HEADLINE: pass-1 claim "langchain-protocol v3 streaming has only 2 tests — immature" was WRONG — actual 107 tests across 4 files (3 test files omitted from original inventory). R7 severity DOWNGRADED to Low: v3 protocol is well-tested; port-as-provisional rationale becomes version-volatility only (not immaturity). Also: `BaseLLM.generate` is batch-fail (atomic `_generate`, no per-prompt exception collection — corpus claimed per-prompt collection); `HTMLHeaderTextSplitter` active_headers keyed by header NAME not DOM depth. Gate-strategy decision pending human (orchestrator escalation, Level 2). |
| **Current Phase** | pre-1 (pre-pipeline) |
| **Current Step** | Certification pass 9 recorded; gate-strategy decision pending human. 24 validation runs total (8 sampled + 7-area exhaustive sweep + 9 certification passes); ~75 total corrections; best streak 1/3 (once); all bounded error classes closed. Human consulted on gate-closure strategy. |

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
| 3-CLEAN certification pass 6 | validate-extraction | DONE | CLEAN(strict)=NO. 1 correction (1 LOW, port-critical): `_reapply_writes_to_succeeded_nodes` skips FOUR signals (ERROR, ERROR_SOURCE_NODE, INTERRUPT, RESUME) not two — INTERRUPT omission corrupts resume semantics. Housekeeping: XAI_API_BASE, GROQ_API_BASE, GROQ_PROXY added. VERSION CLASS CLOSED: 7/7 verified. Streak 0/3. |
| 3-CLEAN certification pass 7 | validate-extraction | DONE | CLEAN(strict)=NO. 1 correction (1 LOW): `NamedBarrierValueAfterFinish` absent from channel Concrete-types enumeration in graph/rust-translation-strategy.md §6.1 (asymmetric vs LastValueAfterFinish sibling). ENUMERATION CLASS CLOSED: 42 claims verified across 14 files, 6/7 areas clean. ALL bounded error classes closed. Streak 0/3. |
| 3-CLEAN certification pass 8 | validate-extraction | DONE | CLEAN(strict)=NO. 1 correction (1 MEDIUM): subgraph `checkpointer=True` borrows parent's checkpointer via `recast_checkpoint_ns` — NOT own persistence. Own persistence requires `BaseCheckpointSaver` instance. `True` on root graphs raises `RuntimeError`. All four variants documented. Coverage-saturation reported: core/graph/langchain/partners high; residual named. Streak 0/3. |
| 3-CLEAN certification pass 9 | validate-extraction | DONE | CLEAN(strict)=NO. 4 corrections (2 MEDIUM, 2 LOW). MEDIUM-1: `BaseLLM.generate` is batch-fail (fires `on_llm_error` per run_manager then re-raises; NO per-prompt exception collection; `batch(return_exceptions=True)` replicates same exception). MEDIUM-2: langchain-protocol v3 streaming 107 tests across 4 files (not 2) — R7 downgraded to Low. LOW-1: `HTMLHeaderTextSplitter` active_headers keyed by header NAME (e.g., "Header 1"), not DOM depth; depth is value tuple field-3. LOW-2: `dependency-disposition.md` propagation of v3 test count corrected. Streak 0/3. Gate-strategy decision pending human. |

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
| D14 | AMENDED D14.1 (human-approved 2026-07-13): exhaustive-sweep-then-3-CLEAN. Sampling provably does not converge (constant error-strike rate across 8 passes, cascade 11→5→7→9→2→2→2→7). New protocol: 7 parallel area validators (core, graph, langchain, partners, splitters, mcp, platform), each confined to its own area directory, exhaustively verify every discrete claim against pinned source (not sampling), fix in-place with [validation-exhaustive] markers, write `<area>/EXHAUSTIVE-SWEEP.md` with claims-checked counts and coverage statements. THEN 3-CLEAN certification passes run (coverage precedes certification). D14 strict-zero bar UNCHANGED: CLEAN(strict) = zero findings of ANY severity; corrections reset streak; 3 consecutive CLEAN(strict) passes required before Phase 1 opens. Base decision (2026-07-13): Extraction-validation gate runs FULL 3-CLEAN protocol; BC-5.39.001 applies. | Sampling does not converge; exhaustive coverage must precede certification; strict-zero bar preserved | pre-1 | 2026-07-13 | human |

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R1 | langgraph `scheduler-kafka` confirmed removed from langgraph 1.2.9. With D1 amended, treat as out-of-scope unless architecture finds a dependency | Low | Phase 1/3 | Effectively resolved by D1 amendment; flag if architecture phase surface it |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 3 | Phase community work last per D1 roadmap |
| R3 | DTU scope revised per D13 — ferrochain-server is first-party (full BCs/holdouts; no DTU clone needed for it). DTU scope collapses to genuine third parties: OpenAI, Anthropic, provider APIs, Ollama keyless CI. Pass-6 "stateful fake" requirement RETIRED. | Low | Phase 1 | Direction resolved by D13 (2026-07-13). Formal DTU assessment still at P1-06 to enumerate final clone list. |
| R4 | Competing active `langgraph` crate on crates.io (updated 2026-07-01) — positioning risk | Medium | Phase 1 | Feeds market-intelligence-assessment gate |
| R5 | Three incompatible tag conventions across reference repos (PyPI `==`, bare semver, path-style) — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling must handle all three |
| R6 | crates.io names verified available; GitHub=BOHICA-LABS/ferrochain registered; publish-all.sh prepped — human has NOT yet run publish-all.sh (cargo login required). Time-sensitive. | High | pre-1 | Pending human action: `cargo login` + run publish-all.sh to reserve all ferrochain-* crate names |
| R7 | langchain-protocol v0.0.17 discovered as upstream dep of langchain-core (semport pass 1); no stable release; schema evolving. Port rationale is version-volatility, not immaturity — v3 streaming has 107 dedicated tests (corrected cert pass 9; original "2 tests — immature" claim was wrong). Port-as-provisional stance can relax to normal port at Phase 1 discretion. | Low | Phase 1/3 | DOWNGRADED from Medium → Low (cert pass 9): v3 protocol is well-tested; gating v3 behind a feature remains a valid architecture choice, but immaturity is no longer the rationale. Full schema in .factory/semport/core/ANALYSIS-STATE.md |
| R8 | Splitters code-point vs byte-length parity: upstream `len()` calls on text are code-point counts, not byte counts — produces different split boundaries on non-ASCII input. NOT covered by any upstream test (no non-ASCII test vector exists). Risk that ferrochain-splitters silently diverges on Unicode-heavy workloads with no behavioral signal. | High | Phase 1/3 | CRITICAL parity risk (semport pass 5). Must become explicit BC + holdout scenario candidate. Route to product-owner at Phase 1 gate. Also flagged: json.dumps separator fidelity + BeautifulSoup-vs-html5ever DOM parity (medium). |
| R9 | Platform API churn re-classified per D13 — LangGraph Platform SaaS is design reference only, not a conformance target. Risk applies as design-input staleness: SDK-1.2.9 endpoint catalog should be reviewed for relevant changes at each spec revision cycle. DTU conformance requirement RETIRED. | Low | Phase 1 | Per D13 (2026-07-13): severity downgraded from High to Low; no DTU re-conformance obligation. |
| R10 | Upstream coverage gap: NamedBarrierValue has NO dedicated unit test anywhere in the langgraph reference corpus. EphemeralValue only 3 assert lines in test_state.py. Like R8 — a contract upstream never wrote; product-owner must author BCs + tests from behavior, not from ported tests. | Medium | Phase 1 | Registered pass 4 (2026-07-13). Route to product-owner at Phase 1: explicit BC + holdout scenario candidate. Do NOT assume upstream test coverage for these types. |
| R11 | MCP upstream test voids: (1) mcp bare-ToolException re-raise path is untested upstream; (2) mcp `__aenter__` NotImplementedError contract is untested upstream. Both belong to the same untested-upstream-contract class as R8 (splitters) and R10 (graph state types). | Medium | Phase 1/3 | Registered burst 17 (2026-07-13). Route to product-owner at Phase 1: must become explicit ferrochain Red Gate tests. Do NOT assume upstream test coverage for these MCP paths. |

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
| **Position** | pre-1, burst 26 complete. 3-CLEAN certification pass 9 COMPLETE: CLEAN(strict)=NO — 4 corrections (2 MEDIUM, 2 LOW). MEDIUM-1: `BaseLLM.generate` is batch-fail — fires `on_llm_error` per run_manager on exception (all receive SAME exception) then re-raises; NO per-prompt exception collection; `batch(return_exceptions=True)` replicates same exception for all inputs. Corpus incorrectly claimed per-prompt exception collection. MEDIUM-2: langchain-protocol v3 streaming has 107 dedicated tests across 4 files (`test_chat_model_v3_stream.py` 41, `test_chat_model_stream.py` 42, `test_chat_model_streamer.py` 24, `test_runnable_events_v3.py` 2) — original pass-1 inventory omitted 3 test files; "2 tests — immature" was factually wrong. R7 downgraded from Medium to Low. LOW-1: `HTMLHeaderTextSplitter` active_headers dict keyed by user-defined header NAME (e.g., "Header 1"), not DOM depth; DOM depth is value tuple field-3, used for scope eviction. LOW-2: `dependency-disposition.md:84` stale "only 2 tests" propagation corrected. All pass-8 named residual territory resolved. Gate-strategy decision pending human (orchestrator escalation, Level 2). 24 total validation runs; ~75 total corrections; best streak 1/3; all bounded error classes closed. |
| **Key context** | D1-D14.1 locked. D14.1: exhaustive-sweep-then-3-CLEAN (human-approved); strict-zero bar unchanged. D13: ferrochain-server first-party; DTU = OpenAI/Anthropic/providers/Ollama only. R6 OPEN: cargo login + publish-all.sh needed (time-sensitive). R7 DOWNGRADED to Low (cert pass 9). R8 OPEN: Unicode/code-point parity — route to product-owner at Phase 1. R10 OPEN: NamedBarrierValue/EphemeralValue coverage gap. R11 OPEN: MCP upstream test voids. CLAUDE.md on main — no initial commit yet; devops at workspace-init Phase 1. Ref corpus: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2, langchain-mcp-adapters==0.3.0. D9: architect presents ≥2 graph alternatives at Phase 1c. D11 ADR at Phase 1c. 10 guardrails active. ALL bounded error classes closed. Gate-strategy: human consulted on 3-CLEAN closure path. |
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
| Burst 9 narrative (D14 locked, extraction-validation pass 1 COMPLETE/corrections, pass 2 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 10 narrative (pass 2 COMPLETE/corrections, pass-1 corrections WRONG, 128 items re-verified, process-gap codified, pass 3 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 11 narrative (pass 3 COMPLETE/7 corrections all propagation residue, second process-gap codified, pass 4 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 12 narrative (pass 4 COMPLETE/9 corrections — 5 graph-area ext-hook dispatch + test-citation + propagation residue; R10 registered; pass 5 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 13 narrative (pass 5 COMPLETE/2 corrections — behavioral-locus tick() returns False not raises, stale "60+ tests"→48; severity collapsed LOW-only; pass 6 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 14 narrative (pass 6 COMPLETE/2 corrections — merge_dicts identity-key semantics corrected, block_translators 7→8 notes-without-edits fix; CASCADE 11→5→7→9→2→2; two lessons; pass 7 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 15 narrative (pass 7 COMPLETE/2 corrections — LoggingCallbackHandler misattributed to langchain-core (MEDIUM), BaseCallbackHandler 4→7 ignore flags (LOW); propagation audit ZERO stale values; all strata sampled; CASCADE 11→5→7→9→2→2→2; 6th guardrail package-attribution; pass 8 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 16 narrative (pass 8 COMPLETE/7 corrections — PHANTOM BEHAVIOR: base_url gate does not exist in source; AnyValue channel semantics OPPOSITE of actual; D14.1 exhaustive-sweep-then-3-CLEAN human-approved; 7 parallel area validators dispatched; CASCADE 11→5→7→9→2→2→2→7; 56 total) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 17 narrative (D14.1 exhaustive sweep COMPLETE — all 7 areas, ~1,216 claims, ~45 corrections, 3 CRITICAL, ZERO hallucinations, 2 phantoms removed; CRITICAL: graph recursion_limit 10,007 not 25; langchain hook return type corrected; R11 registered; 3-CLEAN certification pass 1 dispatched; streak 0/3) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 18 narrative (3-CLEAN certification pass 1 COMPLETE — CLEAN(strict)=NO, CLEAN(PR-merge)=YES; 2 MEDIUM corrections: sdk-py 63/20,787→45/18,728 + cli 46/9,997→19/8,383 reverted to package-dir scope; STRONG convergence: 4 high-consequence fixes RE-CONFIRMED; guardrail #7 SCOPE-LABEL MATCHING codified; pass 2 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 19 narrative (3-CLEAN certification pass 2 COMPLETE — CLEAN(strict)=YES, ZERO corrections; streak 0/3→1/3; 58 checks all 7 areas; 21 behavioral claims confirmed; 21 numeric rows delta=0; pass-1 fixes re-verified; cross-area consistent; pass 3 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 20 narrative (3-CLEAN certification pass 3 COMPLETE — CLEAN(strict)=NO; 1 correction (LOW): anthropic dep `<1.0.0` upper bound absent; streak RESET 1/3→0/3; 6/7 areas PASS; lesson 7b DEPENDENCY-CONSTRAINT COMPLETENESS codified; pass 4 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 21 narrative (3-CLEAN certification pass 4 COMPLETE — CLEAN(strict)=NO; 6 corrections (6 LOW): 4 partner upper bounds missing + ANTHROPIC_API_URL primary env var precedence + CLI test LOC 7,208→7,102; DEPENDENCY-CONSTRAINT class permanently closed; streak 0/3; pass 5 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 22 narrative (3-CLEAN certification pass 5 COMPLETE — CLEAN(strict)=NO; 3 unique inaccuracies / 4 corrections (2 MEDIUM, 1 LOW): ENV-VAR CLASS CLOSED; DEPRECATED-VS-ACTIVE LATEST_VERSION=4 active pregel; validate_model opt-in default FALSE; 9th lesson; pass 6 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 23 narrative (3-CLEAN certification pass 6 COMPLETE — CLEAN(strict)=NO; 1 correction (1 LOW, port-critical): `_reapply_writes_to_succeeded_nodes` 2→4 signals, INTERRUPT omission; housekeeping 3 env-vars; VERSION CLASS CLOSED; ENUMERATION INCOMPLETENESS dominant class; 10th lesson; pass 7 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 24 narrative (3-CLEAN certification pass 7 COMPLETE — CLEAN(strict)=NO; 1 correction (1 LOW): NamedBarrierValueAfterFinish missing from graph/rust-translation-strategy.md §6.1 enumeration; ENUMERATION CLASS CLOSED: 42 claims / 14 files; ALL bounded error classes closed; pass 8 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 25 narrative (3-CLEAN certification pass 8 COMPLETE — CLEAN(strict)=NO; 1 correction (1 MEDIUM): subgraph checkpointer=True borrows parent's checkpointer (recast_checkpoint_ns), NOT own persistence — own persistence requires BaseCheckpointSaver; True on root graphs raises RuntimeError; all four variants documented; coverage-saturation reported; pass 9 dispatched) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Burst 26 narrative (3-CLEAN certification pass 9 COMPLETE — CLEAN(strict)=NO; 4 corrections (2 MEDIUM, 2 LOW): BaseLLM.generate batch-fail semantics; langchain-protocol v3 107 tests not 2 — R7 downgraded to Low; HTMLHeaderTextSplitter active_headers keyed by NAME not depth; dependency-disposition propagation fix; all pass-8 residual territory resolved; gate-strategy decision pending human) | `cycles/v0.0.0-pre-pipeline/burst-log.md` |
| Bursts 5-23 checkpoints (all archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` |
| Lessons learned (PROCESS-GAP: validator counting methodology) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Lessons learned (PROCESS-GAP: cross-document propagation failures / TD-VSDD-060) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Lessons learned (PROCESS-GAP: package-attribution guardrail — 6th guardrail) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Lessons learned (PROCESS-GAP: scope-label matching — 7th guardrail; certification pass 1) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Lessons learned (PROCESS-GAP: dependency-constraint completeness — 8th guardrail 7b; certification pass 3) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Naming decision study | `.factory/planning/naming-decision-study.md` |
| File-size standard study | `.factory/planning/file-size-standard-study.md` |
| Semport pass 1 analysis state (deepening items, risks) | `.factory/semport/core/ANALYSIS-STATE.md` |
