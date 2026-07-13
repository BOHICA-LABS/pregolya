---
document_type: session-checkpoints
level: ops
version: "1.0"
status: archive
producer: state-manager
timestamp: 2026-07-13T03:30:00Z
cycle: v0.0.0-pre-pipeline
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Session Checkpoints — v0.0.0-pre-pipeline

<!-- Archived session resume checkpoints extracted from STATE.md.
     Only the LATEST checkpoint lives in STATE.md.
     Prior checkpoints are archived here for historical reference. -->

## Session Resume Checkpoint (2026-07-13) — burst 13 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 13 complete. Pass 5 COMPLETE: CLEAN(strict)=NO, CLEAN(PR-merge)=YES — first pass with zero CRIT/HIGH/MED; 2 corrections (2 LOW). Behavioral-locus correction: tick() sets status out_of_steps and returns False — outer invoke loop converts status to error. Load-bearing for Rust API: tick() -> bool, not Result<bool, GraphRecursionError>. Stale "60+ tests" → 48 in partners/module-inventory.md. Verified exact: postgres/sqlite checkpoint schemas, all 15 partner LOC counts, pregel halt ordering, interrupt machinery (xxh3 IDs, interrupt_counter resume matching, Command fields). Zero hallucinations. Cascade trajectory: 11→5→7→9→2 corrections; severity collapsed to LOW-only; strata approaching exhaustion. Pass 6 DISPATCHED (fresh context; strata rotated to least-sampled: core messages/parsers/prompts claims, create_agent graph-construction vs factory.py, splitters boundary semantics, mcp behaviors; behavioral-locus precision guardrail added from pass-5 lesson). Streak: 0/3. |
| **Key context** | D1-D14 locked. D14: 3-CLEAN applies to extraction-validation gate (human mandate). D13: ferrochain-server first-party; DTU = OpenAI/Anthropic/providers/Ollama only. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. R10 OPEN: NamedBarrierValue + EphemeralValue coverage gap — route to product-owner at Phase 1. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + trade-offs to human before ADR lock. D11 formal ADR at Phase 1c. Phase 1 gate agenda: D13 server API shape, CLI re-scope, subagent-transformer non-goal, RemoteGraph parity depth, license/attribution, crate-name ADR, slimmed DTU assessment (third-parties only). Pass-5 lesson: behavioral-locus precision guardrail — tick() returns False/bool (not error/exception). |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 12 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 12 complete. Pass 4 COMPLETE: CLEAN(strict)=NO — 9 corrections (5 MEDIUM, 4 LOW). Headline: checkpoint serialization ext-hook dispatch enumeration was INCOMPLETE across all 5 graph-area documents — Pydantic v2 (PRIMARY path for user graph state), Pydantic v1/SecretStr, Enum, dataclasses, NamedTuples, numpy omitted; langgraph named types (Command/Interrupt/TimeoutPolicy) are @dataclasses on the GENERIC dispatch, not a special path. A Rust implementer building from the uncorrected docs would have shipped a serializer unable to handle real graph state. All 5 graph docs corrected. Also: test-citation integrity failure (test_channels.py cited for barrier/ephemeral semantics it does not test) + propagation residue (stale ANALYSIS-STATE footer, ~62→~48 tokio-test estimate in partners strategy). R10 registered: NamedBarrierValue has NO dedicated unit test in langgraph reference corpus; EphemeralValue only 3 assert lines in test_state.py — product-owner must author BCs + tests from behavior. Pass 5 DISPATCHED with graph-area weighting (pregel loop, checkpoint SQL schemas, prebuilt, interrupts) + light-coverage partners inventory + test-citation integrity checks. Streak: 0/3. Cascade trend: corrections 11→5→7→9 — NOT count-decaying because each pass rotates into unexplored strata. |
| **Key context** | D1-D14 locked. D14: 3-CLEAN applies to extraction-validation gate (human mandate). D13: ferrochain-server first-party; DTU = OpenAI/Anthropic/providers/Ollama only. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. R10 OPEN: NamedBarrierValue + EphemeralValue coverage gap — route to product-owner at Phase 1. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + trade-offs to human before ADR lock. D11 formal ADR at Phase 1c. Phase 1 gate agenda: D13 server API shape, CLI re-scope, subagent-transformer non-goal, RemoteGraph parity depth, license/attribution, crate-name ADR, slimmed DTU assessment (third-parties only). |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 11 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 11 complete. D14 locked: full 3-CLEAN applies to extraction-validation gate. Pass 3 COMPLETE: CLEAN(strict)=NO — 7 corrections (2 MEDIUM, 5 LOW), all propagation residue (no new source-level inaccuracies). 65/65 fresh behavioral claims verified; all 17 Rust crates confirmed on crates.io; finding-class decay: source gaps (pass 1) → validator errors (pass 2) → propagation residue only (pass 3). Second process-gap codified (TD-VSDD-060 applies to documentation corrections; mandatory propagation audit as first stratum). Pass 4 DISPATCHED (fresh context; propagation audit first stratum; fresh behavioral strata; test-citation integrity). Streak: 0/3. Phase 1 opens only after 3 consecutive CLEAN(strict) passes. |
| **Key context** | D1-D14 locked. D14: 3-CLEAN applies to extraction-validation gate (human mandate). D13: ferrochain-server first-party; DTU = OpenAI/Anthropic/providers/Ollama only. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + trade-offs to human before ADR lock. D11 formal ADR at Phase 1c. Phase 1 gate agenda: D13 server API shape, CLI re-scope, subagent-transformer non-goal, RemoteGraph parity depth, license/attribution, crate-name ADR, slimmed DTU assessment (third-parties only). |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 10 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 10 complete. D14 locked: full 3-CLEAN applies to extraction-validation gate (human directive — zero findings ANY severity, corrections reset streak, fresh-context each pass). Pass 1 COMPLETE: PASS WITH CORRECTIONS — 11 corrections; streak reset 0/3. Pass 2 COMPLETE: CLEAN(strict)=NO, CLEAN(PR-merge)=NO — 5 corrections (4 HIGH, 1 LOW); streak RESET. Key: pass-1's corrections were WRONG (regex counted multi-line tuple values as dict keys); actuals 27 chat / 10 embeddings. 128 behavioral items re-verified ALL accurate — semantic corpus is sound. Process-gap codified in lessons.md; hardening story noted for session-review. Pass 3 DISPATCHED (fresh context, AST-counting guardrail, cross-doc propagation checks, crates.io claims verification). Streak: 0/3. Phase 1 opens only after 3 consecutive CLEAN(strict) passes. |
| **Key context** | D1-D14 locked. D14: 3-CLEAN applies to extraction-validation gate (human mandate). D13: ferrochain-server first-party; DTU = OpenAI/Anthropic/providers/Ollama only. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + trade-offs to human before ADR lock. D11 formal ADR at Phase 1c. Phase 1 gate agenda: D13 server API shape, CLI re-scope, subagent-transformer non-goal, RemoteGraph parity depth, license/attribution, crate-name ADR, slimmed DTU assessment (third-parties only). |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 9 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 9 complete. D14 locked: full 3-CLEAN applies to extraction-validation gate (human directive — zero findings ANY severity, corrections reset streak, fresh-context each pass). Extraction-validation pass 1 COMPLETE: PASS WITH CORRECTIONS — 11 corrections (3 MEDIUM, 8 LOW); ZERO hallucinations corpus-wide. Top corrections: sqlite-vec runtime dep fully missing from graph disposition (3 Rust options added for Phase 1); checkpoint serde/types.py pregel sentinel constants (TASKS/INTERRUPT/RESUME/ERROR/SCHEDULED) omitted; ChatModelIntegrationTests count inflated ~62→~48; _BUILTIN_PROVIDERS undercounts (chat 30→33, embeddings 11→14); RedisCache tier in langgraph-checkpoint unmentioned. Report: .factory/semport/VALIDATION-REPORT.md. Streak: 0/3 (reset by corrections). Pass 2 DISPATCHED (fresh context, rotated sampling strata, independently re-verifies pass-1 corrections). Phase 1 opens only after 3 consecutive CLEAN(strict) passes. |
| **Key context** | D1-D14 locked. D14: 3-CLEAN applies to extraction-validation gate (human mandate). D13: ferrochain-server first-party; DTU = OpenAI/Anthropic/providers/Ollama only. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + trade-offs to human before ADR lock. D11 formal ADR at Phase 1c. Phase 1 gate agenda: D13 server API shape, CLI re-scope, subagent-transformer non-goal, RemoteGraph parity depth, license/attribution, crate-name ADR, slimmed DTU assessment (third-parties only). |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 8 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 8 complete. ALL 8 semport passes DONE. Pass 8 CONVERGED: ADR-5 resolved (transform = streaming primitive; tee/stream-duplication = base primitive, unify with ADR-8 start-before-end; 7 locking tests); ADR-3 enumerated (176 unique keys: 141 core-internal, 12 unsupported, 23 partner; namespace allowlist DERIVED from registry); C-7 added; langchain-protocol 0.0.17 VERIFIED (strictly additive). D13 locked: ferrochain-server is first-party (built in-workspace, spec'd Phase 1, implemented after core→graph→first-partners; NO wire-compat with LangGraph Platform). R3 and R9 downgraded to Low. Extraction-validation gate IN_PROGRESS (validate-extraction agent; output .factory/semport/VALIDATION-REPORT.md). On PASS → semport phase CLOSED → Phase 1 spec crystallization opens. |
| **Key context** | D1-D13 locked. D13: ferrochain-server first-party; DTU scope = OpenAI/Anthropic/providers/Ollama only; stateful-platform-fake RETIRED. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + trade-offs to human before ADR lock. D11 formal ADR at Phase 1c. ADR queue: ADR-1..ADR-8+ all pending architecture phase. Phase 1 gate agenda: D13 server API shape, CLI re-scope, subagent-transformer non-goal, RemoteGraph parity depth, license/attribution, crate-name ADR, slimmed DTU assessment (third-parties only). |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 7 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 7 complete. Passes 6-7 DONE: platform SDK/CLI (5 deliverables at .factory/semport/platform/; SDK async-only; CLI validate+schema portable; DTU spec complete: 50+ endpoints/40+ DTOs/19 enums), core convergence deepening (all 5 deliverables updated; C-1..C-6 contradictions logged; ADR-6/7/8 queued; NOT fully converged). Pass 8 IN_PROGRESS: narrow RunnableSequence line-verify + SERIALIZABLE_MAPPING; parallel research: langchain-protocol 0.0.17 CDDL → .factory/semport/core/langchain-protocol-0.0.17-verification.md. Next gate: extraction-validation (validate-extraction over all passes with C-1..C-6 as known-corrections) → semport convergence → Phase 1. Queued Phase 1 gate decisions: (a) subagent stream transformer v1 non-goal, (b) MAP-vs-HTTP ADR, (c) CLI re-scope, (d) platform-client depth (full PregelProtocol vs reduced subset), (e) final crate-name ADR, (f) license decision. |
| **Key context** | D1-D12 locked. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario. R9 OPEN: platform API churn — DTU clone anchored to SDK-1.2.9. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + production trade-offs to human before ADR lock. D11 formal ADR ratification at Phase 1c. C-1 headline: langchain-protocol is full Agent Streaming Protocol; core consumes MessagesData subset only → ADR-6 scope split eliminates _compat_bridge. |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 6 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 6 complete. Passes 4-5 DONE: partners+standard-tests (~52,193 src LOC; 5 deliverables at .factory/semport/partners/), text-splitters+mcp-adapters (10 deliverables at .factory/semport/splitters/+mcp/). D12 file-size standard locked (500/750 production, 1000/1500 tests, tokei Code metric, CI xtask + clippy::too_many_lines). R8 CRITICAL: code-point/byte parity in splitters — route to product-owner at Phase 1. rmcp 2.2.0 ADOPT for MCP. Passes 6-7 IN_PROGRESS (platform SDK/CLI → .factory/semport/platform/, core deepening → .factory/semport/core/). Next gate: extraction-validation → semport convergence → Phase 1. Queued Phase 1 decisions: (a) subagent stream transformer v1 non-goal, (b) MAP-vs-HTTP conflict ADR (supersedes pass-1 §3), (c) final crate-name ADR, (d) license decision. |
| **Key context** | D1-D12 locked. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). R8 OPEN: route to product-owner at Phase 1 for BC + holdout scenario authoring. CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + production trade-offs to human before ADR lock. D11 formal ADR ratification at Phase 1c. Deepseek+xai are BaseChatOpenAI subclasses; groq/fireworks/openrouter ride OpenAI wire → one openai-wire module serves ~6 crates. |
| **Convergence counter** | 0 of 3 |

---

## Session Resume Checkpoint (2026-07-13) — burst 5 complete

### State

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Cycle** | v0.0.0-pre-pipeline |
| **Position** | pre-1, burst 5 complete. Passes 2-3 DONE: langgraph (~46,150 deep-scope LOC; 5 deliverables at .factory/semport/graph/), langchain_v1 (14,512 src / 31,653 test LOC; 5 deliverables at .factory/semport/langchain/). D11 design steers recorded (HYBRID execution model, RUST-NATIVE checkpoint, sync-default durability). Passes 4-5 IN_PROGRESS (partners+standard-tests → .factory/semport/partners/, text-splitters+mcp-adapters → .factory/semport/splitters/+mcp/). Remaining queue: langgraph-platform SDK/CLI deep pass, core deepening pass, then semport convergence → Phase 1. Queued Phase 1 gate decisions: (a) subagent stream transformer v1 non-goal, (b) final crate-name ADR, (c) license decision (MIT-derivative attribution). |
| **Key context** | D1-D11 locked. R6 OPEN: cargo login + publish-all.sh still needed (time-sensitive). CLAUDE.md on main — NO initial commit yet; devops commits at workspace-init Phase 1. Ref corpus pinned: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived), langchain-mcp-adapters==0.3.0. D9 gate: Phase 1c architect MUST show ≥2 graph alternatives + production trade-offs to human before ADR lock. D11 formal ADR ratification at Phase 1c. Semport deepening items logged in ANALYSIS-STATE.md (8 items). |
| **Convergence counter** | 0 of 3 |

---
