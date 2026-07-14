---
document_type: pipeline-state
level: ops
version: "3.2"
status: in-progress
producer: state-manager
timestamp: 2026-07-15T22:30:00Z
phase: 1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "Phase 1d pass 36 remediated — counter reset to 0/3; pass 37 ready to dispatch"
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
| **Last Updated** | 2026-07-15 — burst 112: Phase 1d pass 36 — ADR-006 heading residue + ADR-001 interrupt-timing adjudication + GTV-008 sync + gate #26. |
| **Current Phase** | 1 (Spec Crystallization) |
| **Current Step** | Phase 1d adversarial spec convergence — pass 36 remediated; pass 37 ready (0/3; 35 standing gates; sibling-checks for pass 37: ADR-006 Decision heading = ferrochain-native wire [line 30] + no live LangGraph-format claims in architecture/, ADR-001 interrupt rule both refs agree [Collecting→Reducing; completed-sibling writes reduced+checkpointed, interrupted node contributes only INTERRUPT marker, suspend after Checkpointing] + coherence vs BC-2.05.003, GTV-008 byte-identical PROVISIONAL in BC-2.07.002 v1.1 + test-vectors v1.1, gate #26 structurally-privileged-line census first run) |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | in-progress | 2026-07-14 | | | →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24) →7 (P1D-25) →5 (P1D-26) →6 (P1D-27) →1 (P1D-28) →6 (P1D-29) →1 (P1D-30) →1 (P1D-31) →4 (P1D-32) →2 (P1D-33) →3 (P1D-34) →0 (P1D-35 CLEAN) →3 (P1D-36, reset) |
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
| Phase 1d pass 36 + fix burst | adversary + architect + PO | COMPLETE | Pass 36: NOT CLEAN — 3 findings, counter RESET 1/3→0/3 (1 HIGH: F-P36-01 ADR-006 Decision heading still said 'JSON-serialized to LangGraph format' — pass-29 F-P29-05 partial-fix residue in structurally-privileged line → heading corrected to ferrochain-native wire per D13, architecture-tree grep confirms zero live residue; 2 MED: F-P36-02 ADR-001 placed DI-003 interrupt check both 'after reduction' [item 6] and 'Collecting→Reducing' [Consequences] → ADJUDICATED Collecting→Reducing with precise rule [completed-sibling outputs reduced+checkpointed; interrupted node contributes only INTERRUPT marker, no state delta; suspend after Checkpointing; on resume interrupted node re-executes from entry] — satisfies DI-003 + BC-2.05.003 + D17-Q2, NO BC change needed; F-P36-03 GTV-008 drift: test-vectors.md placeholder vs BC-2.07.002 concrete value → both synced byte-identical with PROVISIONAL marker [must Python-verify before Red Gate test; BC v1.1 + supplement v1.1]) + 2 obs (OBS-P36-2 [process-gap] second privileged-line residue instance [F-P27-02, F-P36-01] → NEW GATE #26 structurally-privileged-line canon check [headings/Summary/index rows greps on every canon-retirement fix]). Regression checks + censuses #21/#22/#23/#25 all PASS. Probes: test-vectors axis 1 finding; ADR pairwise sweep 2 findings, all cross-ADR pins consistent. NEW CLASS: structurally-privileged-line residue. Novelty MEDIUM. Trajectory ...→3→0→3. Convergence 0/3 (reset). Gates 35. Burst 112. |
| Phase 1d pass 35 (CLEAN 1/3) | adversary + state-manager | COMPLETE | Pass 35: CLEAN — ZERO findings (first clean pass of Phase 1d). All sibling-checks PASS (E-RETRY-004/003 separation holds; BC-2.12.001 PC8/PC9 holds; gate #16 two-form census ~45 pairings zero collisions). All censuses PASS (status-token 12 defaults + 9 overrides; gate #24 6/6; gate #25 all counts reconcile incl. 86-BC grep-94 reconciliation). Novel probe: L2 DI cross-shard coherence — all 14 DIs bidirectionally anchored, zero orphans. 2 obs non-blocking (OBS-P35-1 422/400 two-layer VAL refinement documented-coherent [optional PC3 cross-ref]; OBS-P35-2 prd.md RETRY example list illustrative). Novelty LOW. Trajectory ...→2→3→0. Convergence 1/3. Gates 34. Burst 111. |
| Phase 1d pass 34 + fix burst | adversary + PO | COMPLETE | Pass 34: NOT CLEAN — 3 findings (1 HIGH: F-P34-02 E-RETRY-003 code collision [error-taxonomy=CircuitBreakerOpen/POLICY/Later vs BC-2.16.001 EC-003 InvalidRetryLimit] → E-RETRY-004 minted [InvalidRetryLimit, VAL, Never, anchor BC-2.16.001; taxonomy v1.5, BC v1.1]; 2 MED: F-P34-01 BC-2.12.001 PC8 GET /threads missing CLAMP+ordering [partial propagation from F-P31-01; PC17 fixed, PC8 not] → PC8 clamp+offset-0 + PC9 created_at DESC added [BC v1.2], gate #24 six-surface census now 6/6 PASS; F-P34-03 [process-gap] gate #16 census regex blind to colon-delimited pairings [why collision survived 33 passes] → gate widened to two grep forms + collision cross-check; full-corpus sweep 44 pairings, ZERO additional collisions) + 3 obs (OBS-P34-1 endpoint-count invariant lives in bc-authoring-plan lines 407-411, NOT interface-definitions §17-B — resume pointer corrected; OBS-P34-2 BC-2.12.002 labels are PC21=pagination/PC22=shape/PC23=ordering; OBS-P34-3 Domain-A audit-trail self-flagged forcing function, no defect). Censuses: #22 FAIL→fixed, #23 PASS 11/11, #25 PASS. NEW CLASS: live error-code collision. Novelty HIGH. Trajectory ...→4→2→3. Convergence 0/3. Gates 34 (#16 widened). Burst 110. |
| Phase 1d pass 33 + fix burst + SESSION WRAP | adversary + PO + state-manager | COMPLETE | Pass 33: NOT CLEAN — 2 MED (F-P33-01 GET /assistants list had NO governing PC [interface declared pagination anchored to BC-2.12.002 which never specified the list surface] → PC21-23 added [shape {assistants, total_count}, pagination, created_at DESC] + anchor list + gate #24 census now greps BC-2.12.002 [closes OBS-P33-1 process-gap]; F-P33-02 run-vs-assistant config/metadata/context merge precedence unspecified → CANON: leaf-level deep-merge, run wins at leaf, upstream-checked no contradiction) + 2 obs (endpoint count 26 pinned in §17-B; gate #25 arithmetic census FIRST FULL RUN all reconcile [86 BCs index+files+registry, 19 CAPs, 5 VPs, 18 crates, 13 batches]). No new class. Novelty MEDIUM-LOW — highly converged. Trajectory ...→1→4→2. Convergence 0/3. Gates 34. Burst 109 (wrap). |
| Phase 1d pass 32 + fix burst (criticality arithmetic + /versions) | adversary + PO | COMPLETE | Pass 32: NOT CLEAN — 4 findings (1 HIGH: F-P32-01 arch-view module-criticality Summary ≠ its own table [claimed 9/10/12/2=33 vs actual 9/11/10/2=32] → recounted + macros HIGH row added per F-P32-04 adjudication → 9/12/10/2=33 reconciled; 2 MED: F-P32-02 PO-draft MEDIUM cell 5→4 [self-sum 21≠20 residue]; F-P32-03 GET /assistants/{id}/versions was the 6th unbounded list surface missed by pass-31 canon → pagination + version ASC ordering exemption + BC-2.12.002 PC20; 1 LOW: F-P32-04 macros row absent from arch-view → ADJUDICATED add HIGH row consistent w/ pass-31 decision) + 3 obs (no-list-schedules v1 note added; VP-INDEX arithmetic PASS; criticality-sibling never cross-checked [process-gap] → NEW GATE #25 summary-arithmetic + criticality-sibling coherence). All 4 rotated censuses PASS. NEW CLASS: summary-vs-table arithmetic. Novelty HIGH — arithmetic audit axis never run. Trajectory ...→1→1→4. Convergence 0/3. Gates 34. Burst 108. |

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
| D18-P28-A | RetryHint per-code authoritative over category default: when a specific error code carries an explicit per-code RetryHint in its BC entry, that per-code value overrides the category-level default RetryHint. 5 documented diverging codes (across GRAPH/PROV/CHKPT/SERVER/CRON namespaces). BC-2.12.005 relabeled 'Default RetryHint' per category; gate #22 codified. | Per-code specificity must win over category default to prevent RetryHint incoherence across BC boundary (F-P28-01) | phase-1d | 2026-07-14 | adversary+PO |
| D18-P28-B | E-PROV-007 StructuredOutputRefused MINTED (POLICY, Never, anchor BC-2.08.003): provider returns a response that violates the caller's declared structured-output schema; ferrochain raises E-PROV-007 rather than silently propagating a malformed payload. Added to error-taxonomy.md, BC-2.08.003 (4 sites), interface-definitions.md omission note. | Refusal path was codeless — violated every-FerrochainError-has-a-code posture (OBS-P28-03) | phase-1d | 2026-07-14 | adversary+PO |
| D18-P28-C | E-CHKPT-005 raise-condition = composite-PK tenancy collision (BC-2.04.006 EC-005 updated): checkpoint_id + thread_id composite key already exists for a different tenant. BC-2.04.006 EC-005 now carries TENANCY raise-condition. | Tenancy raise-condition was embedded-in-Run.error omission note only; no authoritative EC-005 raise-condition entry existed (OBS-P28-02) | phase-1d | 2026-07-14 | adversary+PO |
| D18-P31-A | Pagination convention canonical: all list endpoints must declare limit (default 10, max 100, out-of-range CLAMP), offset, and ordering (schedule-runs aggregate = created_at DESC). No list endpoint may be UNBOUNDED. Propagated to 5 interface rows + BC-2.12.001 PC17 + BC-2.12.003 PC18 + BC-2.12.004 PC7. Gate #24 pagination coherence codified. | F-P31-01: /runs?schedule_id aggregate was UNBOUNDED; 4 other list endpoints lacked convention documentation | phase-1d | 2026-07-15 | adversary+PO |
| D18-P31-B | ferrochain-macros = HIGH criticality (proc-macros in ferrochain-macros affect P0 execution paths: span wrapping, tool registration per ADR-008). Facade/SDK crates (ferrochain, ferrochain-sdk, ferrochain-openai, etc.) documented-excluded from module-criticality inventory via explicit exclusion-criteria note. Module-criticality count 19→20. | ferrochain-macros proc-macro path was excluded from inventory without documentation (OBS-P31-1); exclusion-criteria note added to module-criticality.md preamble | phase-1d | 2026-07-15 | adversary+PO |
| D18-P33-A | GET /assistants list endpoint governed by BC-2.12.002 PC21-23: PC21 = shape {assistants: Vec<Assistant>, total_count: u64}; PC22 = pagination (limit/offset/CLAMP per D18-P31-A); PC23 = created_at DESC ordering. Gate #24 census scope updated to grep BC-2.12.002 alongside the 5 other list endpoints. | F-P33-01: BC-2.12.002 declared pagination without specifying the list surface; PC21-23 close that gap and anchor the census | phase-1d | 2026-07-15 | adversary+PO |
| D18-P33-B | Run-config leaf-level deep-merge canon: when a run-level config, metadata, or context field is provided alongside an assistant-level value, the merge algorithm is leaf-level deep-merge and the run value wins at each leaf. Applies independently to config, metadata, and context. Encoded in BC-2.12.003 run-config invariant. | F-P33-02: merge precedence was unspecified across BC-2.12.002 and BC-2.12.003 — canonical rule now in BC-2.12.003 | phase-1d | 2026-07-15 | adversary+PO |
| D18-P33-C | Endpoint-count invariant = 26: total REST endpoint surface is 26 endpoints, pinned in §17-B of interface-definitions.md as an invariant. Gate #25 arithmetic census first full run confirmed all counts reconcile (86 BCs, 19 CAPs, 5 VPs, 18 crates, 13 batches). | OBS-P33-2: endpoint count was informal; §17-B pinning makes it a first-class invariant | phase-1d | 2026-07-15 | adversary+PO |
| D18-P34-A | E-RETRY-004 minted = InvalidRetryLimit (VAL, Never, anchor BC-2.16.001). E-RETRY-003 remains CircuitBreakerOpen sole owner (BC-2.16.003, POLICY, Later). Collision resolved by minting next free RETRY code; not a RetryHint divergence (matches VAL default). | F-P34-02: single code carried two contradictory meanings across BC boundary | phase-1d | 2026-07-15 | adversary+PO |
| D18-P34-B | BC-2.12.001 PC8 (GET /threads) carries full canonical pagination convention per D18-P31-A: limit default 10 / max 100 / silent CLAMP / offset default 0; PC9 declares created_at DESC ordering. | F-P34-01: partial-fix propagation gap — F-P31-01 fixed sibling PC17 but not PC8, which interface-definitions cites as anchor | phase-1d | 2026-07-15 | adversary+PO |
| D18-P34-C | Gate #16 census = TWO grep forms (space-delimited AND colon-delimited E-code↔variant pairings) + cross-check every pairing against error-taxonomy authoritative binding (collision detection, not just name drift). | F-P34-03 [process-gap]: colon-form blind spot let the E-RETRY-003 collision survive 33 passes | phase-1d | 2026-07-15 | adversary+PO |
| D18-P36-A | ADR-006 Decision heading corrected: "Typed Enum in Rust API; JSON-serialized to ferrochain-native wire format over HTTP". No LangGraph Platform wire-compat claim anywhere in architecture/ (changelog/history refs only). | F-P36-01: pass-29 fix drained the body but left the retired claim in the load-bearing Decision heading | phase-1d | 2026-07-15 | adversary+architect |
| D18-P36-B | ADR-001 interrupt-check placement CANONICAL: Collecting→Reducing transition (DI-003). Rule: completed-sibling task outputs reduced + checkpointed; interrupted node contributes only the INTERRUPT marker (in-progress writes discarded); orchestrator suspends after Checkpointing; on resume (BC-2.05.003) interrupted node re-executes from function entry, siblings do not re-run. "After reduction" retired. | F-P36-02: ADR self-contradiction material to HITL correctness; adjudication satisfies DI-003 + BC-2.05.003 + D17-Q2 LangGraph reference semantics | phase-1d | 2026-07-15 | adversary+architect |
| D18-P36-C | GTV-008 = ["abc🎉🎉", "🎉🎉🎉x", "yz"] PROVISIONAL in BOTH BC-2.07.002 (v1.1) and test-vectors.md (v1.1), byte-identical; PROVISIONAL values must be Python-verified before any Red Gate test hard-codes them. | F-P36-03: "read-only copy" had drifted from authoritative BC; OBS-P36-1 provisional-by-note reconciled | phase-1d | 2026-07-15 | adversary+PO |
| D18-P36-D | GATE #26 minted: structurally-privileged-line canon check — every canon-retirement/amendment fix must grep H1/H2/H3 headings (esp. "## Decision:"), Summary cells/blocks, and index/registry rows across affected + citing documents for the retired claim. bc-authoring-plan v1.1, total_standing_gates frontmatter added. | OBS-P36-2 [process-gap]: two instances (F-P27-02, F-P36-01) of fixes skipping privileged lines; F-P36-01 survived 7 passes | phase-1d | 2026-07-15 | adversary+PO |

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
| Adversary passes completed | 36 (Phase 1d) |
| Fix bursts completed | 35 (Phase 1d) |
| Convergence counter | 0 of 3 (Phase 1d; pre-pipeline 3/3 CLOSED; reset at P1D-36) |
| Finding trajectory | (pre-pipeline) →1→1→0→0→1→2→0→1→1→0→0→1→0→0→0 (C23: CLEAN) ‖ (Phase 1d) →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24) →7 (P1D-25) →5 (P1D-26) →6 (P1D-27) →1 (P1D-28) →6 (P1D-29) →1 (P1D-30) →1 (P1D-31) →4 (P1D-32) →2 (P1D-33) →3 (P1D-34) →0 (P1D-35 CLEAN) →3 (P1D-36, reset) |

## Session Resume Checkpoint

<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v1.0.0-greenfield/session-checkpoints.md. -->

### RESUME IN ONE BREATH

"ferrochain Phase 1 spec crystallization, step 1d adversarial convergence IN PROGRESS: 36 passes / 35 fix bursts, trajectory ...→3→0→3 — pass 35 was CLEAN (1/3) but pass 36 found 3 substantive cross-artifact contradictions (ADR heading residue, ADR-001 interrupt-timing self-contradiction, GTV-008 copy drift) → counter RESET 0/3 (strict-zero D14; 35 standing gates incl. new #26 privileged-line check). NEXT ACTION: dispatch adversary pass 37 — fresh context, sibling-check pass-36 fixes (ADR-006 heading + zero live LangGraph-format claims; ADR-001 both interrupt refs agree w/ nuanced rule + BC-2.05.003 coherence; GTV-008 byte-identical PROVISIONAL both files; gate #26 first census run), rotate 4 censuses, novel probe (all previously-listed axes now probed: L2 DI coherence CLEAN, NFR CLEAN, holdout-A CLEAN, test-vectors 1 finding fixed, ADR pairwise 2 findings fixed — adversary free-choice on any genuinely novel axis, e.g. product-brief↔PRD claims coherence, BC cross-reference (traces_to/anchors) integrity sweep, capability-tier vs BC-priority coherence); CLEAN advances 1/3; ANY finding resets; loop per D15 until 3/3, then /vsdd-factory:check-input-drift then Phase 1 human approval gate."

### HEADS

- factory-artifacts: burst 112 (run `git -C .factory log -1 --format='%h %s'`)
- main: `d018d3f` (=develop, pushed BOHICA-LABS/ferrochain; CI green; branch protection on)

No worktrees. No PRs. verify-sha-currency PASS.

### WORKSTREAM: single — Phase 1d convergence loop. Frozen: spec package = brief v1.1 + domain-spec 15 shards (14 FMs, 11 P0 CAPs) + prd + 6 supplements (bc-authoring-plan v1.1 + test-vectors v1.1 + error-taxonomy + nfr-catalog + module-criticality + interface-definitions) + 86 BCs (ss-01..17, incl. BC-2.07.002 v1.1 + BC-2.16.001 v1.1 + BC-2.12.001 v1.2) + ARCH-INDEX + 8 sections + 11 ADRs (ADR-001 v1.1 + ADR-006 v1.1) + VP-INDEX (5 VPs, harness_fn registry) + module-criticality (20 rows). All 36 pass reports in cycles/v1.0.0-greenfield/adversarial-reviews/. Adversary dispatch template: see RESUME NEXT-ACTION in any recent pass (fresh context, strict-zero, sibling-check + rotate censuses + novel probe, findings INLINE [adversary is read-only — fixer persists report]).

### PENDING HUMAN ACTIONS: (1) direnv allow . [B1]; (2) REGENERATE + run .factory/namespace-reservation/publish-all.sh for ALL 18 crates (script predates sandbox/memory/macros/-sdk) — R6 time-sensitive; (3) langgraph crate 0.2.5 competitor watch (R4 reframed).

### DECISION DELTA (this session, all recorded): D17 hybrid outcome + Q2-Q9 (Decisions Log); D9 gate Alt B (ADR-001); phase-1d spec canons: E-code namespaces + tombstones, run state machine (queued→in_progress→completed|failed|cancelled, interrupted pausable), type names CheckpointSaver/RunnableConfig/AiMessage, URL scheme (thread-nested runs/flat schedules), completed_at terminal-only semantics, capability tiers 11/5/3; pass-25 additions: E-SERVER-016→503, E-SERVER-004 POLICY/403, FerrochainError.code String, to_problem() name, InterruptPayload.interrupt_id, Run.interrupt sub-fields, BC-2.14.002 precedence carve-out, 201/204/502/503/504 rows; pass-26 additions: BC-2.14.002 PC3 8-override registry, /_debug fixed path Authorization: Bearer, debug_route_path REMOVED, 401=E-PROV-004 categorical-fallback, 422=enumerated VAL E-GRAPH codes only, gates #19+#20; pass-27 additions: E-GRAPH-002 stays 422 (POLICY→422 9th PC3 override), E-CHKPT-004 category INTERNAL (BC authoritative), E-CHKPT-005 embedded-in-Run.error, E-GRAPH-013 SECURITY→403, hitl module path action_risk.rs, gate #21 census re-run trigger; pass-28 additions: RetryHint per-code authoritative over category default (5 codes), E-PROV-007 StructuredOutputRefused minted, E-CHKPT-005 raise-condition = composite-PK tenancy collision, gate #22 RetryHint coherence; pass-29 additions: stream chunk event = node_stream (node_delta retired); StreamEvent = 11 imperative variants; wire format ferrochain-native per D13; interrupt SSE surface = {"__interrupt__": [InterruptPayload]} envelope; E-CRON-003 Later divergence documented (5/5); gate #23; pass-30 additions: blanket-note categorical tokens must match BC-2.14.002 PC3 12-category map exactly; Timestamp = RFC 3339 UTC; events.md representative-subset legitimate; gate #23 census PASS 11/11; pass-31 additions: pagination convention canon (limit 10/max 100/CLAMP/offset/created_at DESC); no list endpoint UNBOUNDED; gate #24; ferrochain-macros = HIGH criticality; module-criticality count 20; pass-32 additions: arch-view criticality = 33 modules (9C/12H/10M/2L); /versions paginated w/ version ASC exemption (PC20); no list-all-schedules v1; gate #25; pass-33 additions: GET /assistants list = BC-2.12.002 PC21-23; run-config leaf-level deep-merge, run wins at leaf; endpoint-count invariant 26 pinned §17-B; pass-34 additions: E-RETRY-004 InvalidRetryLimit minted (VAL, Never, BC-2.16.001 v1.1); E-RETRY-003 CircuitBreakerOpen sole owner (BC-2.16.003); BC-2.12.001 PC8 full pagination + PC9 created_at DESC (BC v1.2); gate #16 = two-form census (space+colon) + collision cross-check; endpoint-count invariant location = bc-authoring-plan.md lines 407-411 (not interface-definitions §17-B); BC-2.12.002 label order = PC21=pagination/PC22=shape/PC23=ordering. pass-35: CLEAN, no canon additions; OBS-P35-1 (422 two-layer VAL refinement documented-coherent [optional PC3 cross-ref]) and OBS-P35-2 (prd.md RETRY example list illustrative) recorded in pass-35.md. pass-36 additions: ADR-006 Decision heading = ferrochain-native wire format over HTTP (retired LangGraph-format claim from structurally-privileged heading; architecture-tree grep zero residue); ADR-001 interrupt-check = Collecting→Reducing (completed-sibling outputs reduced+checkpointed; interrupted node contributes only INTERRUPT marker; suspend after Checkpointing; on resume interrupted node re-executes from entry [DI-003+BC-2.05.003+D17-Q2]); GTV-008 = ["abc🎉🎉", "🎉🎉🎉x", "yz"] PROVISIONAL byte-identical in BC-2.07.002 v1.1 + test-vectors.md v1.1; gate #26 structurally-privileged-line canon check (headings/Summary/index greps on every canon-retirement fix); total_standing_gates frontmatter in bc-authoring-plan v1.1.

### PASS-32 CANONS (burst 108): arch-view criticality = 33 modules (9 CRITICAL / 12 HIGH / 10 MEDIUM / 2 LOW) incl. ferrochain-macros HIGH in BOTH criticality docs; /versions paginated w/ version ASC ordering exemption (BC-2.12.002 PC20); no list-all-schedules endpoint in v1 (documented note added to interface-definitions.md); gate #25 summary-arithmetic + criticality-sibling coherence (both criticality docs' Summary cells must match their own table row counts; arch-view and PO-draft summaries must reconcile).

### PASS-33 CANONS (burst 109): GET /assistants list governed by BC-2.12.002 PC21-23 (shape {assistants, total_count}, pagination per D18-P31-A, created_at DESC); run-config precedence = leaf-level deep-merge, run wins at leaf, applies independently to config/metadata/context (BC-2.12.003); endpoint-count invariant = 26 (pinned §17-B in interface-definitions.md); gate #24 census scope updated to include BC-2.12.002 greps.

### PASS-34 CANONS (burst 110): E-RETRY-004 = InvalidRetryLimit (VAL, Never, BC-2.16.001); E-RETRY-003 = CircuitBreakerOpen sole owner (BC-2.16.003); BC-2.12.001 PC8 full pagination convention + PC9 created_at DESC; gate #16 = two-form census (space-delimited + colon-delimited E-code↔variant pairings) + collision cross-check; endpoint-count invariant location = bc-authoring-plan.md (not interface-definitions §17-B).

### PASS-36 CANONS (burst 112): ADR-006 Decision heading = ferrochain-native wire format over HTTP (no LangGraph Platform wire-compat claim in architecture/ live text); ADR-001 interrupt check = Collecting→Reducing with rule: completed-sibling outputs reduced+checkpointed, interrupted node INTERRUPT-marker-only (no state delta), suspend after Checkpointing, on resume re-executes from entry; GTV-008 PROVISIONAL byte-identical in BC-2.07.002 v1.1 + test-vectors.md v1.1 (must Python-verify before Red Gate hard-codes); gate #26 structurally-privileged-line canon check (headings/Summary blocks/index rows in affected + citing docs); total_standing_gates frontmatter in bc-authoring-plan v1.1.

### STANDING DIRECTIVES: D15 autonomous loop (verbatim in frontmatter); D14 strict-zero 3-consecutive-clean.

### WRAP METADATA

| Field | Value |
|-------|-------|
| **Date** | 2026-07-15 |
| **Cycle** | v1.0.0-greenfield |
| **Burst commit** | burst 112 (run `git -C .factory log -1 --format='%h %s'`) |
| **Convergence counter** | 0 of 3 (Phase 1d; reset at P1D-36) |

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
