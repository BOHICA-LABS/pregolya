---
document_type: pipeline-state
level: ops
version: "3.2"
status: in-progress
producer: state-manager
timestamp: 2026-07-16T22:00:00Z
phase: 1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "Phase 1d pass 48 remediated — pass 49 ready to dispatch"
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
| **Last Updated** | 2026-07-16 — burst 124: Phase 1d pass 48 — E-RETRY annotation completeness + REST-resume FIFO-only doc. |
| **Current Phase** | 1 (Spec Crystallization) |
| **Current Step** | Phase 1d adversarial spec convergence — pass 48 remediated; pass 49 ready (0/3; 37 standing gates; sibling-checks for pass 49: interface-definitions v2.7 E-RETRY-* = POLICY/VAL + all 6 namespace annotations exhaustive-verified + FIFO-only resume note; MANDATORY gate #25 FULL run [tier-sibling + per-row crate diff — PARTIAL in pass 48]) |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | in-progress | 2026-07-14 | | | →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24) →7 (P1D-25) →5 (P1D-26) →6 (P1D-27) →1 (P1D-28) →6 (P1D-29) →1 (P1D-30) →1 (P1D-31) →4 (P1D-32) →2 (P1D-33) →3 (P1D-34) →0 (P1D-35 CLEAN) →3 (P1D-36, reset) →2 (P1D-37) →1 (P1D-38) →2 (P1D-39) →1 (P1D-40) →0 (P1D-41 CLEAN) →1 (P1D-42, reset) →1 (P1D-43) →0 (P1D-44 CLEAN) →2 (P1D-45, reset) →1 (P1D-46) →2 (P1D-47) →1 (P1D-48) |
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
| Phase 1d pass 48 + fix burst | adversary + PO | COMPLETE | Pass 48: NOT CLEAN — 1 MED (F-P48-01 interface-definitions blanket-note E-RETRY-* annotated POLICY-only vs taxonomy POLICY+VAL [E-RETRY-004 minted P34 post-dated the P29/P30 note — S-7.01 partial-fix propagation] → POLICY/VAL + FULL 6-namespace annotation verification table [MCP/SBXD/RETRY/BUDGET/MEMORY/SPLIT all now exhaustive-verified, RETRY was sole incomplete] [v2.7]) + 1 obs ADJUDICATED (OBS-P48-1 REST resume lacks interrupt_id targeting → intentional v1 limitation consistent with D17-Q2 FIFO-resume contract; FIFO-only note added to Resume Request Schema; BC-2.05.004 verified consistent [library-API-only targeting]). Sibling-checks: sandbox v2.6 fixes PASS verbatim; gate #29 census FAIL on E-RETRY seam→fixed, all other seams clean. Censuses: #16 PASS (full extraction, zero collisions); #22 PASS (5); #23 PASS (RunEnd completion-only holds); #24 PASS 6/6; #25 PARTIAL (arithmetic OK; tier+crate diff → pass 49 MANDATORY). Probes: memory×tenancy, sandbox×tool, HITL×REST, provenance×streaming ALL PASS. Novelty MEDIUM. Trajectory ...→2→1. Convergence 0/3. Gates 37. Burst 124. |
| Phase 1d pass 47 + fix burst | adversary + PO | COMPLETE | Pass 47: NOT CLEAN — 2 findings (1 CRITICAL security: F-P47-01 interface-definitions Flag-Interaction row mandated SILENT PROCESS-BACKEND FALLBACK [the adk-rust P-61 behavior BC-2.13.001/DI-006/NE-01 exist to invert] → row rewritten: both-off ⇒ Err(E-SBXD-003), process ONLY via unsafe_process_no_isolation(); 1 MED: F-P47-02 config comment 'WARNING on startup' vs BC-2.13.002 per-execute() contract → fixed; supplement-wide sweep: zero other fallback text) + 2 obs (OBS-P47-1 [process-gap] no census covered supplement tables vs governing BCs — sandbox-process feature row ADDED + GATE #29 minted [supplement-vs-BC seam census; bc-authoring-plan v1.8]; census first run: 6 SS-13 rows PASS, 0 additional mismatches; OBS-P47-2 notional changelog dates non-load-bearing). Sibling-checks pass-46 ALL PASS. MANDATORY FULL censuses ALL PASS: #21 (exactly 9 overrides, no 10th), #26, #27, #28 (distribution EXACT 53/23/8/2=86, 33 changelogs), #16, #24, #25 A/B/C, RetryHint 5, VP 4-doc. Seams: sandbox×flags → CRITICAL fix; provider×retry, checkpoint×streaming, cron×runs ALL PASS. NEW CLASS: supplement-table vs BC contradiction. Novelty HIGH. Trajectory ...→1→2. Convergence 0/3. Gates 37. Burst 123. |
| Phase 1d pass 46 + fix burst | adversary + PO | COMPLETE | Pass 46: NOT CLEAN — 1 MED (F-P46-01 streaming×interrupt seam: BC-2.12.007 TV-005 asserted run_end.status=interrupted vs authority BC-2.06.001 TV-004 'RunEnd not emitted for interrupted run' [+ events.md ordering rules] → RunEnd = COMPLETION-ONLY canon: interrupted runs close after __interrupt__ envelope, failed runs close after error SSE event, no run_end either way, status via REST; BC-2.06.001 EC-005 added [v1.1, authority made explicit], BC-2.12.007 TV-005/EC-003/EC-001 fixed [v1.2], interface-definitions /stream row clarified [v2.5]; EC-001 hedge '(or run_end with status failed)' eliminated) + 1 obs (OBS-P46-1 BC-2.09.005 Red-Gate phrasing aligned to sibling [v1.1]). Sibling-checks pass-45 PASS (gate #25 Part C first full run: 33/33 rows crate-clean; BC-2.05.006 v1.2; Wave-0 partial). Censuses: #22/#23 PASS; #21/#26/#27/#28 PARTIAL → pass 47 must run fully. Seam probes: retry×breaker×tool PASS; checkpoint×tenancy PASS; streaming×interrupt FAIL→fixed. NEW CANON: RunEnd completion-only. Novelty MEDIUM. Trajectory ...→2→1. Convergence 0/3. Gates 36. Burst 122. |
| Phase 1d pass 45 + fix burst | adversary + architect + PO | COMPLETE | Pass 45: NOT CLEAN, counter RESET 1/3→0/3 — 2 MED (F-P45-01 coverage-matrix retry row crate = ferrochain-graph vs 6 authorities ferrochain-core [tier-identical so gate #25 Part B missed it] → cell fixed + row relocated to core cluster + FULL 33-row crate diff: retry sole mismatch [v1.2]; gate #25 Part C minted [per-row crate-ownership diff, crate-divergent = HIGH]; F-P45-02 cross-BC seam: BC-2.05.006 line 178 claimed budget escalation = High-tier interrupt, contradicting BC-2.10.004's entire contract [BudgetEscalation payload, BudgetResume, orchestrator resume permitted, TVs role-free] → line corrected to base-mechanism characterization [BC v1.2]; BC-2.10.004 untouched-coherent) + 1 obs (OBS-P45-1 Wave 0 ⊂ Wave 1 foundational sub-wave convention DOCUMENTED [bc-authoring-plan v1.7]). Regression checks + censuses #16/#24/#25/arithmetic ALL PASS. Probes: budget×HITL seam → F-P45-02; per-row crate ownership → F-P45-01; BC internal-consistency stress ×4 CLEAN; quantitative spot CLEAN. NEW CLASSES: per-row crate ownership; cross-BC seam semantics. Novelty MEDIUM. Trajectory ...→0→2. Convergence 0/3 (reset). Gates 36. Burst 121. |
| Phase 1d pass 44 (CLEAN 1/3) | adversary + state-manager | COMPLETE | Pass 44: CLEAN — ZERO findings. Gate #28 census PASS (distribution exact 55/23/6/2=86; 31 changelogs present; pass-43 adjudication holds). MANDATORY gate #24 re-run PASS 6/6. Censuses #21/#22/#23/#26/#27 ALL PASS. Novel probes ALL CLEAN: full dependency graph (no dangling refs, no cycles, wave order respected); exhaustive server EC statuses; inputs: staleness; cross-supplement citations. E-RETRY-004 propagation + H1↔INDEX titles verified. 1 obs (intra-crate anchor path variance, exempted). Novelty LOW — 'spec package has converged'. Trajectory ...→1→0. Convergence 1/3. Gates 36. Burst 120. |
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
| D18-P43-A | Version-adjudication policy: metadata-only git history (bc_id add, status draft→active) = unmodified → revert to v1.0; any content change = modified → keep version + add changelog. Evidence standard: git show diff per file. Applied to 17 BCs (13 kept+changelog, 4 reverted). | F-P43-01: 17-BC self-contradictory version metadata | phase-1d | 2026-07-16 | adversary+PO |
| D18-P43-B | GATE #28 minted: version-changelog integrity — version>1.0 MUST carry changelog entry per bump (frontmatter changelog: or ## Changelog table); modified: [] is vestigial, not a substitute; census greps version≠1.0 vs changelog presence. bc-authoring-plan v1.6, total gates 28. | F-P43-01 [process-gap]: no census covered version-metadata coherence | phase-1d | 2026-07-16 | adversary+PO |
| D18-P45-A | verification-coverage-matrix retry row = ferrochain-core (relocated to core cluster); full 33-row crate diff: sole mismatch = retry row. Gate #25 Part B was tier-census only — blind to crate column. | F-P45-01: coverage-matrix retry row listed ferrochain-graph vs 6 authorities ferrochain-core | phase-1d | 2026-07-16 | adversary+architect |
| D18-P45-B | Budget escalation (BC-2.10.004) reuses BASE interrupt mechanism (BC-2.05.001) with BudgetEscalation payload + BudgetResume::Extend|Halt; NOT risk-tiered, NOT High-tier-gated; orchestrator resume permitted. BC-2.05.006 line-179 base-mechanism characterization corrected. | F-P45-02: BC-2.05.006 mischaracterized the seam as High-tier interrupt | phase-1d | 2026-07-16 | adversary+PO |
| D18-P45-C | Gate #25 Part C minted: per-row crate-ownership diff across the 4 criticality docs (module-criticality authoritative); tier-identical crate-divergent row = HIGH. Part B (tier census) insufficient alone. | F-P45-01: Part B structurally blind to crate column | phase-1d | 2026-07-16 | adversary+PO |
| D18-P45-D | Wave 0 ⊂ Wave 1: BC-planning foundational sub-wave (13 BCs, SS-01/07/14, no intra-workspace deps); ARCH-INDEX/dependency-graph two-wave scheme is crate-build granularity; both canonical at own granularity. bc-authoring-plan v1.7. | OBS-P45-1 reconciliation note | phase-1d | 2026-07-16 | adversary+PO |
| D18-P46-A | RunEnd = COMPLETION-ONLY SSE event. Non-completion terminal states: failed → error SSE then close; interrupted → __interrupt__ envelope then close; NO run_end either way; status via GET /threads/{id}/runs/{id}. Authority BC-2.06.001 PC2 + EC-005. | F-P46-01 seam contradiction | phase-1d | 2026-07-16 | adversary+PO |
| D18-P46-B | Authority-deference rule: when a BC declares another BC as taxonomy authority, contradictions in the citing BC are defects in the citing BC (auto-adjudicated); the authority BC may only be EXTENDED (new ECs) via PO adjudication with changelog. | F-P46-01 adjudication pattern | phase-1d | 2026-07-16 | adversary+PO |
| D18-P47-A | Supplement rows are DERIVED; BC PCs/ECs are AUTHORITY — on conflict the BC wins and the supplement is corrected. GATE #29 minted: supplement-vs-BC seam census (every BC-citing supplement row diffed against the cited BC's PCs/ECs; trigger: supplement edits + adversary rotation). | F-P47-01 CRITICAL survived 46 passes — no census covered supplement tables | phase-1d | 2026-07-16 | adversary+PO |
| D18-P47-B | sandbox-process feature: off by default, explicit-constructor-only, NOT enforcing; SandboxBackend::default() NEVER returns process; both-enforcing-off ⇒ Err(E-SBXD-003). | F-P47-01; authority BC-2.13.001 PC3/PC4/EC-002 | phase-1d | 2026-07-16 | adversary+PO |
| D18-P47-C | Process-backend warning: once per execute() invocation, NEVER construction/startup-only. | F-P47-02; authority BC-2.13.002 PC2/EC-002 | phase-1d | 2026-07-16 | adversary+PO |
| D18-P48-A | Blanket-note namespace annotations are authoritative category sets — must be updated whenever a new code is minted in a covered namespace. E-RETRY-* = POLICY/VAL. All 6 annotations exhaustive-verified. | F-P48-01: P34 minting didn't propagate to P29/P30 note | phase-1d | 2026-07-16 | adversary+PO |
| D18-P48-B | REST resume = FIFO-only v1 (single active slot; no interrupt_id field) per D17-Q2 committed HITL contract; targeted delivery = library Command API only (BC-2.05.004 EC-002). Intentional scoping, documented in Resume Request Schema v2.7. | OBS-P48-1 adjudication | phase-1d | 2026-07-16 | adversary+PO |

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
| Adversary passes completed | 48 (Phase 1d) |
| Fix bursts completed | 45 (Phase 1d) |
| Convergence counter | 0 of 3 (Phase 1d; pre-pipeline 3/3 CLOSED; reset at P1D-45) |
| Finding trajectory | (pre-pipeline) →1→1→0→0→1→2→0→1→1→0→0→1→0→0→0 (C23: CLEAN) ‖ (Phase 1d) →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24) →7 (P1D-25) →5 (P1D-26) →6 (P1D-27) →1 (P1D-28) →6 (P1D-29) →1 (P1D-30) →1 (P1D-31) →4 (P1D-32) →2 (P1D-33) →3 (P1D-34) →0 (P1D-35 CLEAN) →3 (P1D-36, reset) →2 (P1D-37) →1 (P1D-38) →2 (P1D-39) →1 (P1D-40) →0 (P1D-41 CLEAN) →1 (P1D-42, reset) →1 (P1D-43) →0 (P1D-44 CLEAN) →2 (P1D-45, reset) →1 (P1D-46) →2 (P1D-47) →1 (P1D-48) |

## Session Resume Checkpoint

<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v1.0.0-greenfield/session-checkpoints.md. -->

### RESUME IN ONE BREATH

"ferrochain Phase 1 spec crystallization, step 1d adversarial convergence IN PROGRESS: 48 passes / 45 fix bursts, trajectory ...→2→1 (finding sizes shrinking: pass 47 CRITICAL supplement class → gated #29 + drained; pass 48 single annotation-completeness residue of a P34 edit). Counter 0/3 (strict-zero D14; 37 standing gates). NEXT ACTION: dispatch adversary pass 49 — fresh context, sibling-check pass-48 (interface-definitions v2.7: E-RETRY POLICY/VAL, 6-namespace table, FIFO-only note), MANDATORY FULL gate #25 A+B+C (PARTIAL two passes running), rotate #21/#26/#27/#28/#29, novel probes free-choice (seams mostly drained: budget×HITL, streaming×interrupt, sandbox×flags, provider×retry, checkpoint×streaming/tenancy, cron×runs, memory×tenancy, HITL×REST, provenance×streaming all probed; adversary hunts genuinely new axes); CLEAN advances 1/3; ANY finding resets; loop per D15 until 3/3, then /vsdd-factory:check-input-drift then Phase 1 human approval gate."

### HEADS

- factory-artifacts: burst 124 (run `git -C .factory log -1 --format='%h %s'`)
- main: `d018d3f` (=develop, pushed BOHICA-LABS/ferrochain; CI green; branch protection on)

No worktrees. No PRs. verify-sha-currency PASS.

### WORKSTREAM: single — Phase 1d convergence loop. Frozen: spec package = brief v1.1 + domain-spec 15 shards (14 FMs, 11 P0 CAPs) + prd + 6 supplements (bc-authoring-plan v1.8 [gate #29 + Wave-0, 29 gates in plan] + test-vectors v1.2 + error-taxonomy + nfr-catalog + module-criticality + interface-definitions v2.7) + 86 BCs (ss-01..17, incl. BC-2.07.002 v1.1 + BC-2.08.011 v1.1 + BC-2.08.012 v1.1 + BC-2.16.001 v1.1 + BC-2.12.001 v1.2 + BC-2.05.006 v1.2 + BC-2.06.001 v1.1 + BC-2.09.005 v1.1 + BC-2.12.007 v1.2; version distribution 53×1.0/23×1.1/8×1.2/2×1.3; BC-2.13.001/002/003/005 reverted v1.0 per D18-P43-A) + ARCH-INDEX + 8 sections + 11 ADRs (ADR-001 v1.1 + ADR-006 v1.1) + VP-INDEX (5 VPs, harness_fn registry) + module-criticality (20 rows) + module-decomposition v1.2 + verification-coverage-matrix v1.2 (33 rows) + ubiquitous-language-server v1.1. All 48 pass reports in cycles/v1.0.0-greenfield/adversarial-reviews/. Adversary dispatch template: see RESUME NEXT-ACTION in any recent pass (fresh context, strict-zero, sibling-check + rotate censuses + novel probe, findings INLINE [adversary is read-only — fixer persists report]).

### PENDING HUMAN ACTIONS: (1) direnv allow . [B1]; (2) REGENERATE + run .factory/namespace-reservation/publish-all.sh for ALL 18 crates (script predates sandbox/memory/macros/-sdk) — R6 time-sensitive; (3) langgraph crate 0.2.5 competitor watch (R4 reframed).

### DECISION DELTA (this session, all recorded): D17 hybrid outcome + Q2-Q9 (Decisions Log); D9 gate Alt B (ADR-001); phase-1d spec canons: E-code namespaces + tombstones, run state machine (queued→in_progress→completed|failed|cancelled, interrupted pausable), type names CheckpointSaver/RunnableConfig/AiMessage, URL scheme (thread-nested runs/flat schedules), completed_at terminal-only semantics, capability tiers 11/5/3; pass-25 additions: E-SERVER-016→503, E-SERVER-004 POLICY/403, FerrochainError.code String, to_problem() name, InterruptPayload.interrupt_id, Run.interrupt sub-fields, BC-2.14.002 precedence carve-out, 201/204/502/503/504 rows; pass-26 additions: BC-2.14.002 PC3 8-override registry, /_debug fixed path Authorization: Bearer, debug_route_path REMOVED, 401=E-PROV-004 categorical-fallback, 422=enumerated VAL E-GRAPH codes only, gates #19+#20; pass-27 additions: E-GRAPH-002 stays 422 (POLICY→422 9th PC3 override), E-CHKPT-004 category INTERNAL (BC authoritative), E-CHKPT-005 embedded-in-Run.error, E-GRAPH-013 SECURITY→403, hitl module path action_risk.rs, gate #21 census re-run trigger; pass-28 additions: RetryHint per-code authoritative over category default (5 codes), E-PROV-007 StructuredOutputRefused minted, E-CHKPT-005 raise-condition = composite-PK tenancy collision, gate #22 RetryHint coherence; pass-29 additions: stream chunk event = node_stream (node_delta retired); StreamEvent = 11 imperative variants; wire format ferrochain-native per D13; interrupt SSE surface = {"__interrupt__": [InterruptPayload]} envelope; E-CRON-003 Later divergence documented (5/5); gate #23; pass-30 additions: blanket-note categorical tokens must match BC-2.14.002 PC3 12-category map exactly; Timestamp = RFC 3339 UTC; events.md representative-subset legitimate; gate #23 census PASS 11/11; pass-31 additions: pagination convention canon (limit 10/max 100/CLAMP/offset/created_at DESC); no list endpoint UNBOUNDED; gate #24; ferrochain-macros = HIGH criticality; module-criticality count 20; pass-32 additions: arch-view criticality = 33 modules (9C/12H/10M/2L); /versions paginated w/ version ASC exemption (PC20); no list-all-schedules v1; gate #25; pass-33 additions: GET /assistants list = BC-2.12.002 PC21-23; run-config leaf-level deep-merge, run wins at leaf; endpoint-count invariant 26 pinned §17-B; pass-34 additions: E-RETRY-004 InvalidRetryLimit minted (VAL, Never, BC-2.16.001 v1.1); E-RETRY-003 CircuitBreakerOpen sole owner (BC-2.16.003); BC-2.12.001 PC8 full pagination + PC9 created_at DESC (BC v1.2); gate #16 = two-form census (space+colon) + collision cross-check; endpoint-count invariant location = bc-authoring-plan.md lines 407-411 (not interface-definitions §17-B); BC-2.12.002 label order = PC21=pagination/PC22=shape/PC23=ordering. pass-35: CLEAN, no canon additions; OBS-P35-1 (422 two-layer VAL refinement documented-coherent [optional PC3 cross-ref]) and OBS-P35-2 (prd.md RETRY example list illustrative) recorded in pass-35.md. pass-36 additions: ADR-006 Decision heading = ferrochain-native wire format over HTTP (retired LangGraph-format claim from structurally-privileged heading; architecture-tree grep zero residue); ADR-001 interrupt-check = Collecting→Reducing (completed-sibling outputs reduced+checkpointed; interrupted node contributes only INTERRUPT marker; suspend after Checkpointing; on resume interrupted node re-executes from entry [DI-003+BC-2.05.003+D17-Q2]); GTV-008 = ["abc🎉🎉", "🎉🎉🎉x", "yz"] PROVISIONAL byte-identical in BC-2.07.002 v1.1 + test-vectors.md v1.1; gate #26 structurally-privileged-line canon check (headings/Summary/index greps on every canon-retirement fix); total_standing_gates frontmatter in bc-authoring-plan v1.1. pass-37 additions: module-decomposition.md v1.2 criticality corrected (channels/message CRITICAL→HIGH, event_emitter HIGH→MEDIUM, macros heading + macros::tool/entrypoint/task MEDIUM→HIGH — 7 cells + 1 heading; full row-diff no further drift); verification-coverage-matrix.md v1.1 tier summary 9/12/10/2=33 + per-module table COMPLETED 27→33 rows (added ferrochain-macros HIGH; sandbox-wasm, ferrochain-standard-tests, memory-store MEDIUM; xtask, ferrochain-community LOW); gate #25 Part-B WIDENED to 4-doc sibling set (arch registry + PO registry + module-decomposition + verification-coverage-matrix); GTV mirror byte-identical 9/9 incl. annotations. pass-38 additions: Committed VP Obligations = 5 total (3 Kani [D17-Q7/NFR-003: VP-001/002/003] + 2 integration [R11 Red Gate: VP-004/005]); NFR-003 scope = 3 Kani proofs only (unchanged in prd.md/nfr-catalog/system-overview); verification-architecture.md v1.1 heading '(D17-Q7 + R11)' + intro 'Five VPs committed before v1.0 release — three Kani (D17-Q7/NFR-003: VP-001/002/003) plus two integration (R11 Red Gate: VP-004/005)'. pass-39 additions: ubiquitous-language reconciliation-table ferrochain-term cells = exact canonical Rust trait/type names (Store → MemoryStore; per BC-2.15.001); bc-authoring-plan v1.3 Batch-9 = 9 BCs documented Step-E exception (BC-2.08.009, ADR-004), planning cap 8 preserved, exception named in prose + Summary metric; no re-batching. pass-40 additions: gate #13 five-way (batch-table CAP/DI verified carrier); Cap column = primary capability only; corrected cells: BC-2.08.007 DI-009+DI-014, BC-2.08.001..005 CAP-009, BC-2.10.004 CAP-012, BC-2.05.006 DI-003. pass-41: CLEAN, 3 obs recorded in report. pass-42 additions: gate #27 crate-resolution census (anchor paths resolve to ADR-007 roster + module ownership); BC-2.08.011/012 v1.1 anchors = ferrochain-graph/src/graph/state.rs (StateGraph builder); bc-authoring-plan v1.5. pass-43 additions: version-adjudication policy (metadata-only git history = revert v1.0; content change = keep version + changelog); gate #28 version-changelog integrity (version>1.0 MUST have changelog entry per bump; modified: [] vestigial); 17-BC adjudication (13 ss-04/ss-11/ss-13 kept v1.1 + changelog added, 4 BC-2.13.001/002/003/005 reverted v1.0); BC version distribution 55×1.0/23×1.1/6×1.2/2×1.3; bc-authoring-plan v1.6, gates 28. pass-44: CLEAN (1/3), 1 obs. pass-45 additions: verification-coverage-matrix v1.2 retry row = ferrochain-core (core cluster); 33-row crate-ownership diff (sole mismatch = retry); gate #25 Part C minted (per-row crate-ownership diff, crate-divergent = HIGH); BC-2.05.006 v1.2 base-mechanism characterization (BudgetEscalation payload, BudgetResume::Extend|Halt, orchestrator resume permitted, NOT High-tier gated); bc-authoring-plan v1.7 Wave-0 ⊂ Wave-1 convention documented. pass-46 additions: RunEnd = completion-only SSE event (BC-2.06.001 v1.1 EC-005; BC-2.12.007 v1.2 TV-005/EC-003/EC-001; interface-definitions v2.6); authority-deference rule (citing BC yields to declared authority BC; contradictions auto-adjudicated); BC-2.09.005 v1.1 Red-Gate phrasing aligned. pass-47 additions: supplement rows derived, BCs authority (gate #29); sandbox default NEVER process — both-off ⇒ E-SBXD-003, unsafe_process_no_isolation() only [BC-2.13.001 PC3/PC4/EC-002]; per-execute() warning [BC-2.13.002 PC2/EC-002]; gate #29 supplement-vs-BC seam census (BC-citing supplement rows vs cited BC PCs/ECs; trigger: supplement edits + adversary rotation). pass-48 additions: blanket-note namespace annotations = authoritative category sets (update on every code mint; E-RETRY-* = POLICY/VAL); REST resume FIFO-only v1 (single active slot, no interrupt_id; targeted delivery = library-only [BC-2.05.004 EC-002]; FIFO-only note added to interface-definitions v2.7).

### PASS-48 CANONS (burst 124): blanket-note namespace annotations = authoritative category sets (update on every code mint); REST resume FIFO-only v1 (targeted delivery library-only).

### PASS-47 CANONS (burst 123): supplement rows derived, BCs authority (gate #29); sandbox default NEVER process — both-off ⇒ E-SBXD-003, unsafe_process_no_isolation() only; process warning per-execute().

### PASS-46 CANONS (burst 122): RunEnd completion-only (failed → error SSE close; interrupted → envelope close; no run_end; status via REST); authority-deference rule (citing BC yields to declared authority BC).

### PASS-45 CANONS (burst 121): retry = ferrochain-core everywhere; budget escalation = base interrupt + BudgetEscalation payload, NOT risk-tiered; gate #25 Part C per-row crate diff; Wave 0 ⊂ Wave 1.

### STANDING DIRECTIVES: D15 autonomous loop (verbatim in frontmatter); D14 strict-zero 3-consecutive-clean.

### WRAP METADATA

| Field | Value |
|-------|-------|
| **Date** | 2026-07-16 |
| **Cycle** | v1.0.0-greenfield |
| **Burst commit** | burst 124 (run `git -C .factory log -1 --format='%h %s'`) |
| **Convergence counter** | 0 of 3 (Phase 1d; reset at P1D-45) |

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
