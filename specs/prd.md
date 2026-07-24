---
document_type: prd
level: L3
version: "1.15"
status: active
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/specs/domain-spec/risks.md
  - .factory/specs/domain-spec/differentiators.md
  - .factory/specs/domain-spec/assumptions.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "ccbc310"
traces_to: domain-spec/L2-INDEX.md
decisions: [D1, D2, D3, D4, D5, D6, D7, D8, D9, D11, D12, D13, D17, D21, D23]
supplements:
  - prd-supplements/interface-definitions.md
  - prd-supplements/error-taxonomy.md
  - prd-supplements/nfr-catalog.md
  - prd-supplements/module-criticality.md
  - prd-supplements/bc-authoring-plan.md
  - prd-supplements/test-vectors.md
  - prd-supplements/observability.md
changelog:
  - "v1.15 (F-P142-03, burst-242, 2026-07-23): §2.05 BC-2.05.008 title and §2.06 BC-2.06.005 title updated to match new H1s (bc_h1_is_title_source_of_truth): Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority."
  - "v1.14 (burst-241/Wave-2/F-P141-02/2026-07-23): VP-gate expansion — 6 P0 Kani proof obligations. §4 NFR-003 target updated '3 committed VP' → '6 P0 Kani VP obligations pass before v1 convergence'. §2.17 OQR-3 note expanded: invariants +DI-014; enforcing BCs +BC-2.21.003/2.19.005/2.05.007; plural 'harnesses'/'are Phase-6 artifacts'. BC-2.17.001 row retitled to '6 P0 VP obligations (VP-001/002/003/009/010/011) + 3 P1 VP obligations (VP-006/012/013)', DI column +DI-014. §6.3 KD-003 table: BC-2.03.001/2.04.006/2.13.004 retitled with VP-00N Kani P0 harness target label; +BC-2.21.003 (VP-009)/BC-2.19.005 (VP-010)/BC-2.05.007 (VP-011) Kani P0 rows; BC-2.17.001 updated to '6 P0 + 3 P1'."
  - "v1.13 (burst-241/F-P141-03/F-P141-04/2026-07-22): §5 error taxonomy summary table label corrections — alignment to error-taxonomy.md source of truth (gate #33 reverse, TD-VSDD-060 sibling sweep). (1) F-P141-03 (MED): E-CORE-002 label corrected — was 'RunnableCompositionError' (wrong: pipe composition is E-CORE-004); corrected to 'MessageRoleUnrecognized' (BC-2.01.002, message role validation — taxonomy message: 'Message role <role> is not a recognized message type'); E-CORE-004 PipeCompositionFailed added to CORE examples to explicitly represent the composition error. (2) F-P141-04 (LOW): E-TOOLS-006 label corrected — was 'BashGrepResultsTruncated' (wrong: 'Bash' prefix misattributes GrepTool informational payload field to BashTool); corrected to 'GrepResultsCapped' (taxonomy: GrepResult.capped payload field, BC-2.23.006 PC-2). (3) TD-VSDD-060 sibling sweep of all §5 TOOLS examples — three additional label mismatches found and fixed: E-TOOLS-001 'PathEscape' → 'PathConfinementViolation' (taxonomy message prefix 'PathConfinementViolation:', BC-2.23.001); E-TOOLS-002 'FileSizeExceeded' → 'FileReadExceedsLimit' (taxonomy message prefix 'FileReadExceedsLimit:', BC-2.23.001); E-TOOLS-003 'ExactMatchNotFound' → 'EditOldStringNotFound' (taxonomy message prefix 'EditOldStringNotFound:', BC-2.23.003). All five corrected labels now match error-taxonomy.md v1.34 message prefixes exactly. error-taxonomy.md not modified — all defects were PRD-side labels."
  - "v1.12 (burst-237/F-P137-01/2026-07-22): BC-2.13.002 DI column DI-006 → DI-006, DI-015 in §2.13 body table and §7 RTM. Propagates burst-235 F-P135-05 di_anchors co-enforcement (DI-015 Subprocess Execution Timeout) to prd.md — BC file frontmatter was correct since burst-235 but prd.md DI columns were not swept."
  - "v1.11 (burst-235/F-P135/2026-07-22): RTM and §2 reconciliation — 13 D23 BC rows propagated from BC frontmatter source-of-truth. Gate #28 close. (1) F-P135-01: §7 RTM Source(L2) CAP column fixed for all 13 D23 rows (CAP-006/007/012/034–038 placeholder → authoritative CAP-034/035/036/037/038 per BC frontmatter); BC-2.10.005 Module corrected ferrochain-graph → ferrochain-core (VP-012 core-budget crate: ferrochain-core confirmed). (2) F-P135-02: §2.05 DI DI-003→DI-014 (BC-2.05.007/008); §2.06 DI DI-011→DI-014 (BC-2.06.004/005/006); §2.10 DI —→DI-014 (BC-2.10.005) and DI-002→DI-014 (BC-2.10.006); §2.23 DI DI-008→DI-014 (BC-2.23.001–004,006) and DI-008→DI-014,DI-015 (BC-2.23.005); §7 RTM DI column corrected to match. DI-008 citation removed from all SS-23 RTM rows — no SS-23 BC anchors DI-008 per frontmatter (adjudicated unbacked; PRD-only citation removed). (3) F-P135-04: §2.15 header P1/P2→P1; BC-2.15.001/002/003 rows P2→P1 (D23 CAP-017 promotion swept §7 RTM + BC-INDEX but not §2.15 body — now reconciled). Note: F-P135-03 (BC-INDEX BC-2.23.005 DI-009,DI-014→DI-014,DI-015) applied to BC-INDEX.md v2.2→v2.3 in same burst."
  - "v1.10 (burst-233/F-P133-02/2026-07-22): BC-2.16.001/002/003 Wave-1 promotion per D23 — §2.16 header P2→P1; BC table rows P2→P1; §7 RTM rows P2→P1; §7 totals 72 P1/6 P2 → 75 P1/3 P2. §5 TOOLS component range row updated to list E-TOOLS-008 (FileIoError) and E-TOOLS-009 (InvalidRegexPattern). VP-013 Security Anchor corrected: ADR-018 Decision 6 → ADR-020 Decision 3."
  - "v1.9 (D23/2026-07-22): D23 First-Party Tools + Per-Tool Approval + Rolling Compaction expansion. (1) §2: BC-2.05.007/008 added to §2.05 (PreToolCallHook dispatch + skip-hook-on-resume); BC-2.06.004/005/006 added to §2.06 (StreamEvents 13/14/15); BC-2.10.005/006 added to §2.10 (CompactionTrigger config, compaction execution); §2.23 added (SS-23 First-Party Tool Library — 6 tool BCs). (2) §3: PreToolCallHook + CompactionPolicy traits added; first-party tools bullet. (3) §5: E-TOOLS-001–099 range row added (TOOLS component). (4) §5b: BC file count 116→129. (5) §7 RTM: BC-2.15.001/002/003 P2→P1 (CAP-017 wave promotion); +13 rows; totals updated to 129 (51 P0 / 72 P1 / 6 P2). D23 added to decisions list."
  - "v1.8 (burst-227/F-P132-01/2026-07-21): §11 Observability emission census: convert from stale duplicate table (2 entries, retired ferrochain.mcp.guardrail.unregistered listed as active) to pointer+count form citing observability.md as the sole catalog authority. Active count updated to 6 (per observability.md v1.1). Prevents future dual-maintenance drift."
  - "v1.7 (burst-226/F-P131-01+F-P131-07/2026-07-21): §5 error taxonomy ranges updated: CORE 007→008 (E-CORE-008 GuardrailCriticalRejection), VS 004→005 (E-VS-005 FilterUnsupported). Census: 96→98."
  - "v1.6 (F-P130/2026-07-21): Fix burst 225 — 7 adversarial pass P1D-130 findings closed. (1) F-P130-02: BC-2.20.002 v1.1→v1.2 — 3 nonexistent `ferrochain-guardrail` crate references replaced with canonical `ferrochain-core: core::guardrail` per ADR-014 v1.4 PO Obligations. (2) F-P130-03: interface-definitions.md v2.42→v2.43 — 5 missing D21 trait sections added (Retriever+GuardedDocuments, VectorStore+VectorStoreFactory, Embeddings, ChatPromptTemplate/PromptValue, LcSerializable/Reviver) with verbatim ADR signatures and per-method BC anchors. (3) F-P130-04: DI-014 added to di_anchors of BC-2.20.001 v1.0→v1.1, BC-2.20.002 v1.1→v1.2, BC-2.21.004 v1.0→v1.1; propagated to BC-INDEX + prd.md §2 + §7 RTM. (4) F-P130-06: observability.md v1.0 created — Canonical Structured Event Catalog with 2 confirmed event_type emissions; SAP-1 policy stated; registered in supplements list. (5) F-P130-07: E-EMBED-001 prefix `DimensionMismatch:` → `EmbeddingDimensionMismatch:` in error-taxonomy.md v1.28→v1.29 and BC-2.22.001 v1.0→v1.1; E-VS-002 unchanged; gate #33 forward+reverse clean. (6) F-P130-08: BC-2.19.003 v1.0→v1.1 TV-001/TV-002 made falsifiable — relational assertions against LANGCHAIN_CORE_REGISTRY.len() and feature-gated delta >= 1. (7) F-P130-09: DI-009 added to di_anchors of BC-2.22.002 v1.0→v1.1 and BC-2.22.003 v1.0→v1.1; BC-2.14.004 cross-reference added in PC2/INV-5 and PC4/INV-2 prose; propagated to BC-INDEX + §2 + §7 RTM."
  - "v1.5 (F-P224/2026-07-21): §5 E-VS range row updated — E-VS-004 ZeroNormWriteTime (STATIC) added to examples column (write-time zero-norm guard on add_texts/from_texts_sync; minted in error-taxonomy.md v1.28; BC-2.21.002 v1.1 anchor)."
  - "v1.4 (2026-07-20): D21 ecosystem-parity expansion (burst 216) — 21 new BCs across 5 subsystems SS-18..22 (ferrochain-prompts/core-serializable/vectorstores/embeddings); BC total 95→116, P0 48→51, P1 39→56, P2 8→9; §2 adds subsections 2.18–2.22; §3 public-traits list extended with Retriever/VectorStore/VectorStoreFactory/Embeddings; §5 error taxonomy adds E-TMPL/E-SRLZ/E-VS/E-EMBED components; §5b count 95→116 BC files; §7 RTM +21 rows."
  - "v1.3 (F-P97-02, 2026-07-17): §10 Module Criticality — deleted stale deferral parenthetical '(architect to confirm crate→subsystem mapping in Phase 1b)'. Mapping fully resolved at Phase 1b (2026-07-14); parenthetical survived sweep. Input-hash updated."
  - "v1.2 (2026-07-17): Provenance-integrity fix — removed .factory/STATE.md from inputs: list. STATE.md is a live pipeline-state file with no spec-content signal for the PRD. All genuine derivation sources (product-brief, domain-spec files, COMPARATIVE-ASSESSMENT) are already listed. D-NNN decision references in the PRD body are stable baked-in facts. Input-hash recomputed."
  - "v1.1 F-P73 (2026-07-15): F-P73-02: stale '86' references updated to 95 (§5b test-vector note, OQR-4 historical annotation); OBS-P73-A: §2.10 BC-2.10.003 summary corrected '(on_ceiling = halt)' → '(on_ceiling = halt | summarize)' for 3-way H1/PRD/BC-INDEX sync; OBS-P73-C: §3 public-trait list extended with 4 D20 first-class traits (SkillStore, MemoryWriteGuard, ToolCallDialect, ProviderFallbackPolicy)."
  - "v1.0: Initial PRD core. BC files authored in sub-bursts 2–N per bc-authoring-plan.md."
  - "v1.0 Step-E: BC-2.08.009 added to SS.08 — Tool Schema Naming Stability (Snapshot Test Anchor). Authored from ADR-004 acceptance (architect feedback): snapshot test obligation for public tool types deriving schemars::JsonSchema. Batch 9 count: 8 → 9. Total BC count: 82 → 83."
  - "v1.0 P53-A: §9 NE summary corrected (F-P53-01). Previous rollup was 15→BC/1→BC+CI lint gate/1→CI-only, which undercounted CI-gate NEs by 2. Re-derived from table: 13→BC (incl. 3 VP-seed: NE-02/12/17); 3→BC+CI lint gate (NE-04, NE-07, NE-10); 1→CI lint gate only (NE-05). Partial-fix signature: rows NE-07/NE-10 had been upgraded to BC+CI lint gate in the table but rollup was never re-derived."
open_question_resolutions:
  - OQR-1: HITL risk tiers — extension of CAP-006
  - OQR-2: Agent registry — application-layer concern
  - OQR-3: CAP-019 phase anchoring — behavioral invariants Phase-1, proofs Phase-6
  - OQR-4: D5 proc-macro BC dependency — gated BCs noted per subsection
  - OQR-5: DI-012 default hook behavior — default-permit with WARNING LOG
---

# Product Requirements Document: ferrochain

> **BC Index Model:** This PRD is an index document. Each BC lives in its own file under
> `behavioral-contracts/ss-NN/`. Section 2 tables provide one-line summaries linking to
> individual files. Do NOT inline full contract details here.
>
> **Supplement Model:** Sections 3–5 reference extracted supplement files under
> `prd-supplements/`. Each supplement targets a different downstream agent.
>
> **Subsystem IDs:** All BCs carry `subsystem: SS-NN` per ARCH-INDEX.md Subsystem Registry
> (backfilled Phase 1b, 2026-07-14). ARCH-INDEX.md is the source of truth for SS-NN IDs.

---

## 1. Product Overview

### 1.1 Problem Statement

Rust developers building production AI agent systems have no framework that provides
the LangGraph StateGraph execution model (durable multi-step graphs, HITL interrupts,
checkpointing) in an async-native Rust codebase. Existing Rust crates (rig, langchain-rust,
langgraph-rust) provide either the chain-era LangChain API or a partial graph runtime
without durable checkpointing, HITL resume-value delivery, or provider conformance testing.
This forces teams to patch together multiple crates, accept missing durability guarantees, or
use Python with GIL bottlenecks and 4x higher memory consumption than equivalent Rust code.

**Measurable pain:** langchain-rust downloads 4,000/month with no durable-graph runtime;
GitHub issue #15057 in langchain-ai/langchain explicitly requests a Rust LangChain
implementation; langgraph-rust (Onelevenvy) at 599 downloads ships no durable checkpoint
or HITL resume. The four-part gap (LangGraph runtime + durable checkpointing + conformance
suite + formal verification) is confirmed unoccupied white space (ASM-003).

### 1.2 Solution Vision

ferrochain is a Rust implementation of the LangChain v1 architecture: a Cargo workspace of
independently-publishable crates that gives Rust developers the LangGraph StateGraph
execution model (BSP scheduling, durable per-task checkpointing, HITL interrupt/resume),
provider conformance testing, and a formally-verified core — without the Python runtime.

The external API surface follows LangChain Python v1 semantics (D17 HYBRID outcome). Internal
implementation adopts 43 ADOPT/ADAPT patterns from adk-rust v1.0.0 where they are superior
to the Python reference (COMPARATIVE-ASSESSMENT.md). The 17 NE must-not-inherit patterns
become first-class BCs, CI lint gates, or ADRs (see Section 9).

**Three design-forcing holdout domains (D8):**
- Domain A (SOC analyst): risk-tiered HITL auth gates, forensic audit trail, prompt-injection
  isolation at tool-result boundaries
- Domain B (dark factory): multi-day graph runs surviving process restarts, budget governance,
  convergence-loop support, per-task durability
- Domain C (OpenClaw): persistent sessions, pluggable multi-channel ingress, local-first
  single-binary deployment

### 1.3 Key Differentiators

| ID | Differentiator | Market Source | Traced to (PRD Section 6) |
|----|---------------|--------------|--------------------------|
| KD-001 | LangGraph runtime + durable checkpointing in Rust — no competitor has this | market-intel §4 #1; CONFLICT-1/2/3/4 | 6.1 |
| KD-002 | Standard-tests conformance suite — no competitor has this | market-intel §4 #2 | 6.2 |
| KD-003 | Formally-verified core (Kani + cargo-fuzz) — no competitor has this | market-intel §4 #3; D17-Q7 | 6.3 |
| KD-004 | Idiomatic async-first trait design with typed ContentBlock and 2D error taxonomy | market-intel §4 #4; CONFLICT-6 | 6.4 |
| KD-005 | Provider conformance + LangChain Python v1 migration story | market-intel §4 #5 | 6.5 |

### 1.4 Target Users

| Persona | Description | Pain Level | Holdout Domain |
|---------|-------------|-----------|----------------|
| Security/platform engineer | Building SOC-analyst agents; needs risk-tiered HITL, forensic audit, prompt-injection isolation | Critical | Domain A |
| Autonomous software team | Building dark-factory pipelines; needs multi-day durable runs, budget governance, convergence loops | Critical | Domain B |
| Personal AI assistant builder | Building OpenClaw-like systems; needs persistent sessions, local-first single binary | High | Domain C |
| Rust developer (LLM applications) | Needs LangChain/LangGraph semantics without Python; cobbling together 3+ crates today | High | General |
| Provider / tool vendor | Wants conformance-tested integrations via ferrochain-standard-tests | Medium | Secondary |

### 1.5 Out of Scope

> **Machine-consumed (Criterion 51).** Adversary and consistency-validator check no story AC
> implements any feature listed here.

- Full 1,051-module langchain-community port (upstream archived 2026-06-19; D1 amendment)
- Wire-compatibility with LangGraph Platform or any external managed graph runtime (D13)
- A2A/AWP/ACP protocol implementations (all NOT-APPLICABLE per COMPARATIVE-ASSESSMENT §2)
- LangGraph kafka scheduler (removed from LangGraph v1.x; not a port target)
- Voice/audio/canvas/device-node bridges
- Managed hosting / LangGraph Platform-equivalent SaaS
- OCSF-style telemetry normalization at core layer (integration-layer concern; explicit
  in/out decision required in architecture phase — domain-a §5)
- SEC disclosure / SOC 2 compliance semantics as in-product features (low-confidence;
  explicit architect decision required — domain-a §4)
- Python runtime or PyO3 interop (one-way Python-checkpoint import tool is in scope;
  general Py bridge is not)
- langchain-community v1.0.0a1 API tracking (alpha churn risk; community wave targets
  demand-ranked surface post-v1)

---

## 2. Behavioral Contracts Index

> BCs are sharded into `behavioral-contracts/ss-NN/` directories. The shard `ss-NN`
> identifier maps to the architect's ARCH-INDEX Subsystem Registry (assigned Phase 1b).
> All BCs carry `subsystem: SS-NN` per ARCH-INDEX.md (backfilled Phase 1b, 2026-07-14).
> Full authoring plan: `prd-supplements/bc-authoring-plan.md`.

### 2.01 Core Primitives (CAP-001, CAP-002) — P0

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.01.001 | Typed ContentBlock sequence construction (no raw content where typed expected) | P0 | DI-008 | ss-01/BC-2.01.001.md |
| BC-2.01.002 | Message type-safety (AiMessage/HumanMessage/SystemMessage/ToolMessage) | P0 | DI-008 | ss-01/BC-2.01.002.md |
| BC-2.01.003 | Runnable trait invocation — invoke, stream, batch | P0 | — | ss-01/BC-2.01.003.md |
| BC-2.01.004 | Runnable pipe composition (A \| B = AB chain) | P0 | — | ss-01/BC-2.01.004.md |

### 2.02 StateGraph Definition (CAP-003) — P0

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.02.001 | StateGraph node definition and typed channel assignment | P0 | — | ss-02/BC-2.02.001.md |
| BC-2.02.002 | LastValue / Append / BarrierValue channel semantics and reducer wiring | P0 | DI-001 | ss-02/BC-2.02.002.md |
| BC-2.02.003 | NamedBarrierValue missing-writer boundary behavior (R10) | P0 | — | ss-02/BC-2.02.003.md |
| BC-2.02.004 | EphemeralValue cleared-after-super-step semantics (R10) | P0 | — | ss-02/BC-2.02.004.md |
| BC-2.02.005 | Conditional edge routing function | P0 | — | ss-02/BC-2.02.005.md |
| BC-2.02.006 | Send API dynamic fan-out | P0 | — | ss-02/BC-2.02.006.md |

### 2.03 BSP Graph Execution (CAP-004) — P0

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.03.001 | BSP super-step execution determinism and Kani VP seed | P0 | DI-001, NE-17 | ss-03/BC-2.03.001.md |
| BC-2.03.002 | Concurrent LastValue write rejection (InvalidUpdateError) | P0 | DI-001 | ss-03/BC-2.03.002.md |
| BC-2.03.003 | Deterministic reducer application order (task-identity sort) | P0 | DI-001, NE-17 | ss-03/BC-2.03.003.md |

### 2.04 Durable Three-Tier Checkpointing (CAP-005) — P0

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.04.001 | Per-task put_writes before next super-step begins | P0 | DI-002 | ss-04/BC-2.04.001.md |
| BC-2.04.002 | Sync durability tier as default; async and exit-only are explicit opt-in | P0 | DI-002 | ss-04/BC-2.04.002.md |
| BC-2.04.003 | Monotonic logical-clock checkpoint IDs (not wall-clock) | P0 | DI-004 | ss-04/BC-2.04.003.md |
| BC-2.04.004 | Fork lineage via parent_checkpoint_id pointers (not state copy) | P0 | DI-004 | ss-04/BC-2.04.004.md |
| BC-2.04.005 | Crash recovery: completed tasks not re-executed after process restart | P0 | DI-002 | ss-04/BC-2.04.005.md |
| BC-2.04.006 | Session triple-address uniqueness (thread_id, checkpoint_ns, checkpoint_id) — VP seed | P0 | DI-005, NE-12 | ss-04/BC-2.04.006.md |
| BC-2.04.007 | Encryption at rest for both state payloads AND event payloads; rotation errors propagate | P0 | — (NE-11) | ss-04/BC-2.04.007.md |
| BC-2.04.008 | FTS conversation search over checkpoint history (single-process; SQLite FTS5) | P1 | DI-002, DI-008, DI-014 | ss-04/BC-2.04.008.md |

### 2.05 HITL Interrupt / Resume (CAP-006) — P0

> D17-Q2 mandates these as Phase-1 BCs. Cannot be retrofitted post-graph-design.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.05.001 | Interrupt suspension with durable state persistence | P0 | DI-003 | ss-05/BC-2.05.001.md |
| BC-2.05.002 | FIFO resume-value delivery order | P0 | DI-003 | ss-05/BC-2.05.002.md |
| BC-2.05.003 | Interrupted node re-executes from start of super-step on resume | P0 | DI-003 | ss-05/BC-2.05.003.md |
| BC-2.05.004 | Command(resume=value) API contract | P0 | DI-003 | ss-05/BC-2.05.004.md |
| BC-2.05.005 | Resume on empty interrupt queue returns Err(NoActiveInterrupt) | P0 | DI-003 | ss-05/BC-2.05.005.md |
| BC-2.05.006 | Risk-tiered interrupt classification (typed action-risk levels for Domain A) | P0 | DI-003, ASM-008 | ss-05/BC-2.05.006.md |
| BC-2.05.007 | PreToolCallHook dispatch — pre_invoke contract; Approve/Deny/Edit/PendingHumanApproval; fail-closed Deny (VP-011 Kani seed) | P1 | DI-014 | ss-05/BC-2.05.007.md |
| BC-2.05.008 | Skip-hook-on-resume invariant — ToolApprovalRequest checkpoint persistence; Command(resume=PreToolDecision); no re-invocation of pre_invoke | P1 | DI-014 | ss-05/BC-2.05.008.md |

### 2.06 Structured Streaming Event Taxonomy (CAP-007) — P0

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.06.001 | Typed per-phase event taxonomy (run/step/node/tool start-stream-end) | P0 | DI-011 | ss-06/BC-2.06.001.md |
| BC-2.06.002 | run_id + parent_ids correlation across all events in a run | P0 | — | ss-06/BC-2.06.002.md |
| BC-2.06.003 | Streaming and unary run produce identical final answer (NE-13) | P0 | DI-011 | ss-06/BC-2.06.003.md |
| BC-2.06.004 | `tool_approval_request` StreamEvent (event 13) — payload; emission before interrupt; causal ordering | P1 | DI-014 | ss-06/BC-2.06.004.md |
| BC-2.06.005 | `tool_approval_resolved` StreamEvent (event 14) — payload on Command(resume=…); decision outcome | P1 | DI-014 | ss-06/BC-2.06.005.md |
| BC-2.06.006 | `compaction_event` StreamEvent (event 15) — payload; emission after compaction completes; trigger variant | P1 | DI-014 | ss-06/BC-2.06.006.md |

### 2.07 Text Splitting with Code-Point Boundary Correctness (CAP-008) — P0

> D17-Q9 mandates these as Phase-1 BCs. R8 is High risk.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.07.001 | Chunk boundaries are Unicode code-point counts (not bytes) | P0 | — | ss-07/BC-2.07.001.md |
| BC-2.07.002 | Non-ASCII boundary parity with Python reference implementation (emoji, CJK) | P0 | — | ss-07/BC-2.07.002.md |
| BC-2.07.003 | Short document (length < chunk_size) — single chunk returned, no overlap applied, no panic | P0 | — | ss-07/BC-2.07.003.md |

### 2.08 Provider-Conformant Chat Model Interface + Standard Tests + Dialect/Failover Extensions (CAP-009, CAP-011) — P1

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.08.001 | Chat model streaming completions conformance | P1 | DI-011 | ss-08/BC-2.08.001.md |
| BC-2.08.002 | Chat model tool-call round-trip conformance | P1 | — | ss-08/BC-2.08.002.md |
| BC-2.08.003 | Chat model structured output conformance | P1 | — | ss-08/BC-2.08.003.md |
| BC-2.08.004 | Chat model error-type fidelity conformance | P1 | DI-014 | ss-08/BC-2.08.004.md |
| BC-2.08.005 | Chat model token-usage accounting conformance | P1 | — | ss-08/BC-2.08.005.md |
| BC-2.08.006 | Standalone SDK crate split architecture (ferrochain-\<provider\>-sdk + adapter) | P1 | DI-008 | ss-08/BC-2.08.006.md |
| BC-2.08.007 | Provider streaming interrupted by transport error surfaces Err(Timeout) or Err(Transport), not truncated success | P1 | DI-009, DI-014 | ss-08/BC-2.08.007.md |
| BC-2.08.008 | Eval score aggregation: arithmetic mean + JudgeResult::InfraError third outcome (NE-15) | P1 | — | ss-08/BC-2.08.008.md |
| BC-2.08.009 | Tool schema naming stability (snapshot test anchor) — semver-major required on any schema change to a public tool type | P1 | — | ss-08/BC-2.08.009.md |
| BC-2.08.010 | `#[tool]` attribute macro: async fn → Tool implementor via schemars::JsonSchema | P1 | DI-008 | ss-08/BC-2.08.010.md |
| BC-2.08.011 | `#[entrypoint]` attribute macro: START edge auto-wiring for StateGraph | P1 | — | ss-08/BC-2.08.011.md |
| BC-2.08.012 | `#[task]` attribute macro: task registration boilerplate generation | P1 | — | ss-08/BC-2.08.012.md |
| BC-2.08.013 | Pluggable tool-call dialect seam (ToolCallDialect; Hermes ChatML XML) | P1 | DI-008, DI-014 | ss-08/BC-2.08.013.md |
| BC-2.08.014 | Provider failover chain (ProviderFallbackPolicy; ordered fallback on 429/5xx/Auth) | P1 | DI-008, DI-009, DI-010, DI-014 | ss-08/BC-2.08.014.md |

### 2.09 MCP Tool Adapter + MCP Server Role (CAP-010, CAP-021) — P1

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.09.001 | MCP server tool discovery and registration at runtime | P1 | — | ss-09/BC-2.09.001.md |
| BC-2.09.002 | ToolInvocation routing to correct MCP server transport | P1 | — | ss-09/BC-2.09.002.md |
| BC-2.09.003 | Tool-result content treated as untrusted ingress (DI-012 applies) | P1 | DI-012 | ss-09/BC-2.09.003.md |
| BC-2.09.004 | MCP bare ToolException re-raise preserving type identity (R11) | P1 | DI-014 | ss-09/BC-2.09.004.md |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections (Red Gate — R11) | P1 | DI-014 | ss-09/BC-2.09.005.md |
| BC-2.09.006 | MCP server tool advertisement (tools/list; mcp::server) | P1 | DI-008, DI-014 | ss-09/BC-2.09.006.md |
| BC-2.09.007 | MCP server tool invocation (tools/call; external client executes registered tool) | P1 | DI-008, DI-010, DI-014 | ss-09/BC-2.09.007.md |

### 2.10 Budget Governance (CAP-012) — P0

> D17-Q4 mandates these as Phase-1 BCs. Domain B dark-factory holdout depends on this.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.10.001 | BudgetPolicy allow/escalate/deny evaluation per run and per sub-agent | P0 | — | ss-10/BC-2.10.001.md |
| BC-2.10.002 | Append-only EvidenceJournal recording of every budget evaluation | P0 | — | ss-10/BC-2.10.002.md |
| BC-2.10.003 | Graceful halt when budget ceiling reached (on_ceiling = halt \| summarize); remaining-budget exposure (RunContext.budget\_info) | P0 | — | ss-10/BC-2.10.003.md |
| BC-2.10.004 | Budget escalation to HITL interrupt when on_ceiling = escalate | P0 | DI-003 | ss-10/BC-2.10.004.md |
| BC-2.10.005 | CompactionTrigger configuration — Disabled/OnWatermark/OnMessageCount/OnTokenCount; BudgetConfig extension; watermark arithmetic (VP-012 Kani seed) | P1 | DI-014 | ss-10/BC-2.10.005.md |
| BC-2.10.006 | Compaction execution — ConversationSnapshot from FTS; mid-run window REPLACEMENT; CompactionEvent → EvidenceJournal; checkpoint immutability; DefaultSummarizationPolicy | P1 | DI-014 | ss-10/BC-2.10.006.md |

### 2.11 Content Provenance Tagging and Guardrail-on-Ingress (CAP-013) — P0

> D17-Q8 mandates these as Phase-1 BCs. Domain A SOC analyst holdout depends on this.
> **DI-012 default behavior resolution (OQR-5):** default-permit with WARNING LOG when
> no GuardrailHook is registered — graph does not fail; operator sees a log warning.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.11.001 | ProvenanceTag attached at every ingress boundary (tool-result, RAG, memory) | P0 | DI-012 | ss-11/BC-2.11.001.md |
| BC-2.11.002 | GuardrailHook fires unconditionally at tool-result ingress | P0 | DI-012, NE-06 | ss-11/BC-2.11.002.md |
| BC-2.11.003 | GuardrailHook fires at RAG ingress | P0 | DI-012, NE-06 | ss-11/BC-2.11.003.md |
| BC-2.11.004 | GuardrailHook fires at memory ingress | P0 | DI-012, NE-06 | ss-11/BC-2.11.004.md |
| BC-2.11.005 | Rejected content does not enter model context under any code path | P0 | DI-012 | ss-11/BC-2.11.005.md |
| BC-2.11.006 | No-hook default: content passes through with WARNING LOG (default-permit) | P0 | DI-012 | ss-11/BC-2.11.006.md |

### 2.12 Durable-Run HTTP Server (CAP-014) — P1

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.12.001 | Thread resource CRUD (create, read, list, delete durable conversation history) | P1 | — | ss-12/BC-2.12.001.md |
| BC-2.12.002 | Assistant resource CRUD (named agent config) | P1 | — | ss-12/BC-2.12.002.md |
| BC-2.12.003 | Run creation and execution lifecycle (queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable) | P1 | — | ss-12/BC-2.12.003.md |
| BC-2.12.004 | CronSchedule creation and proactive run execution | P1 | — | ss-12/BC-2.12.004.md |
| BC-2.12.005 | SecurityConfig::default() denies CORS, gates debug route on explicit opt-in key (NE-14) | P1 | DI-013 | ss-12/BC-2.12.005.md |
| BC-2.12.006 | IdempotencyStore / RateLimitStore / RunStore trait seams with durable backends (NE-08) | P1 | — | ss-12/BC-2.12.006.md |
| BC-2.12.007 | Streaming endpoint and unary endpoint drive same graph engine, same final answer | P1 | DI-011, NE-13 | ss-12/BC-2.12.007.md |

### 2.13 Sandboxed Tool Execution — Enforcing Backend Default (CAP-015) — P1

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.13.001 | Enforcing sandbox backend (WASM or container) is default | P1 | DI-006 | ss-13/BC-2.13.001.md |
| BC-2.13.002 | Process backend requires explicit opt-in and emits loud runtime warning | P1 | DI-006, DI-015 | ss-13/BC-2.13.002.md |
| BC-2.13.003 | Strict policy + non-enforcing backend returns Err(PolicyNotEnforceable) | P1 | DI-006 | ss-13/BC-2.13.003.md |
| BC-2.13.004 | All workspace file ops call canonicalize_beneath_root at access time | P1 | DI-007, NE-02 | ss-13/BC-2.13.004.md |
| BC-2.13.005 | Symlink that escapes workspace root returns Err(WorkspaceEscape) | P1 | DI-007, NE-02 | ss-13/BC-2.13.005.md |
| BC-2.13.006 | macOS Seatbelt profile is deny-by-default with explicit allow rules | P1 | DI-006 | ss-13/BC-2.13.006.md |
| BC-2.13.007 | Environment variable sanitization at sandbox execution boundary | P1 | DI-006, DI-008, DI-010 | ss-13/BC-2.13.007.md |

### 2.14 Typed Error Taxonomy — FerrochainError (CAP-016) — P0

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.14.001 | FerrochainError 2D component × category struct with RetryHint and machine code | P0 | DI-008, DI-014 | ss-14/BC-2.14.001.md |
| BC-2.14.002 | RFC-7807 compatible problem emission from FerrochainError | P0 | — | ss-14/BC-2.14.002.md |
| BC-2.14.003 | All library constructors return Result; no .unwrap()/.expect()/assert! in non-test code (NE-07) | P0 | DI-008 | ss-14/BC-2.14.003.md |
| BC-2.14.004 | Every outbound HTTP ClientBuilder must set .timeout(30s); zero Client::new() outside tests (NE-04) | P0 | DI-009 | ss-14/BC-2.14.004.md |
| BC-2.14.005 | Every API key type: newtype + Debug→"<redacted>"; no #[derive(Serialize)]; no Deref<Target=str> (NE-10) | P0 | DI-010 | ss-14/BC-2.14.005.md |
| BC-2.14.006 | Validation failures propagate Err(FerrochainError); no public API returns None for validation failure (NE-03) | P0 | DI-014 | ss-14/BC-2.14.006.md |

### 2.15 Long-Horizon Cross-Session Memory Store + Self-Improvement Primitives (CAP-017, CAP-020) — P1

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.15.001 | KV and vector memory persistence across threads (not per-checkpoint) | P1 | — | ss-15/BC-2.15.001.md |
| BC-2.15.002 | User/app/session tier isolation — user-private does not bleed across scopes | P1 | — | ss-15/BC-2.15.002.md |
| BC-2.15.003 | GDPR erasure removes all traces from all memory tiers | P1 | — | ss-15/BC-2.15.003.md |
| BC-2.15.004 | SkillStore registry — load-on-demand skill documents | P1 | DI-008, DI-014 | ss-15/BC-2.15.004.md |
| BC-2.15.005 | Guarded memory and skill writes (MemoryWriteGuard; E-MEMORY-007) | P1 | DI-008, DI-012, DI-014 | ss-15/BC-2.15.005.md |
| BC-2.15.006 | Frozen-snapshot context mutation — memory-sourced system-prompt content | P1 | DI-002, DI-008, DI-014 | ss-15/BC-2.15.006.md |

### 2.16 Tool Retry with Circuit Breaker (CAP-018) — P1

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.16.001 | Per-tool retry policy keyed by tool_name (not args hash) (NE-09) | P1 | — | ss-16/BC-2.16.001.md |
| BC-2.16.002 | Finite global_limit non-None default (NE-09) | P1 | — | ss-16/BC-2.16.002.md |
| BC-2.16.003 | Circuit breaker trips after repeated failure; prevents infinite retry (NE-09) | P1 | — | ss-16/BC-2.16.003.md |

### 2.17 Formal Verification Pipeline (CAP-019) — P2

> **Phase anchor (OQR-3):** VP proof deliverables belong to Phase 6. The behavioral
> invariants they prove (DI-001, DI-005, DI-007, DI-014) are specified in Phase-1 BCs
> (BC-2.03.001, BC-2.04.006, BC-2.13.004, BC-2.21.003, BC-2.19.005, BC-2.05.007). These BCs describe the behavioral contract;
> the Kani harnesses that prove them are Phase-6 artifacts.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.17.001 | Kani harness scope: 6 P0 VP obligations (VP-001/002/003/009/010/011) + 3 P1 VP obligations (VP-006/012/013) | P2 | DI-001, DI-005, DI-007, DI-014 | ss-17/BC-2.17.001.md |
| BC-2.17.002 | cargo-fuzz targets: serialization round-trip and graph-execution paths | P2 | — | ss-17/BC-2.17.002.md |

### 2.18 Prompt Templates (CAP-022, CAP-023) — P1

> **D21 ecosystem-parity expansion.** ferrochain-prompts crate; wave 2.
> ADR-015 injection-safety constraints mandate BC-2.18.004 and BC-2.18.005 as Red Gate
> tests (ADR-015 Security Invariants 1 and 2). BC-2.18.004 is also VP-006 Kani candidate.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.18.001 | PromptTemplate F-String Rendering, Partial Binding, Variable Detection, and Strict-Undefined Guard | P1 | DI-008, DI-014 | ss-18/BC-2.18.001.md |
| BC-2.18.002 | ChatPromptTemplate Multi-Message Rendering with PromptValue and Per-Message MessageProvenance | P1 | DI-008 | ss-18/BC-2.18.002.md |
| BC-2.18.003 | MessagesPlaceholder Vec\<Message\> In-Place Expansion and FewShotPromptTemplate Few-Shot Composition | P1 | DI-008 | ss-18/BC-2.18.003.md |
| BC-2.18.004 | injection_guard — SystemMessage Slot with Untrusted ProvenanceTag Raises E-TMPL-001 (Fail-Closed at Render Time) | P1 | DI-008, DI-014 | ss-18/BC-2.18.004.md |
| BC-2.18.005 | SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed) | P1 | DI-008, DI-014 | ss-18/BC-2.18.005.md |

### 2.19 LC Serialization (CAP-024, CAP-025) — P0/P1/P2

> **D21 ecosystem-parity expansion.** ferrochain-core (core::serializable); wave 2.
> ADR-016 security invariant mandates BC-2.19.005 as Red Gate test + VP-010 Kani candidate.
> BC-2.19.001 is VP-007 proptest seed (round-trip serialize→Serialized→deserialize→equivalent).

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | P1 | DI-008 | ss-19/BC-2.19.001.md |
| BC-2.19.002 | lc_secrets() Credential Fields Stripped from kwargs Before Serialization and Constructor Dispatch | P1 | DI-008, DI-010 | ss-19/BC-2.19.002.md |
| BC-2.19.003 | Inventory-Based Type Registry — Link-Time Registration, Feature-Gated Partner Entries, OnceLock Allowlist | P1 | DI-008 | ss-19/BC-2.19.003.md |
| BC-2.19.004 | Legacy Namespace Remap — OLD_CORE_NAMESPACES_MAPPING Aliases Resolve to Canonical Constructors | P2 | DI-008 | ss-19/BC-2.19.004.md |
| BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate) | P0 | DI-008, DI-014 | ss-19/BC-2.19.005.md |
| BC-2.19.006 | Langchain-Monolith Type Ids Return E-SRLZ-002 (Structured Error, Not Silent None or E-SRLZ-001) | P1 | DI-008, DI-014 | ss-19/BC-2.19.006.md |

### 2.20 Document Retrieval (CAP-026, CAP-027) — P0/P1

> **D21 ecosystem-parity expansion.** ferrochain-core (Retriever trait) + ferrochain-vectorstores
> (VectorStoreRetriever); wave 2. BC-2.20.002 is a Red Gate test enforcing DI-012 RAG-guardrail
> coverage obligation — required before any graph node wires Arc\<dyn Retriever\>.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.20.001 | Retriever Trait — get_relevant_documents Async Dyn-Compatible; Document Carrier Type; Arc\<dyn Retriever\> Graph Seam | P1 | DI-008, DI-012, DI-014 | ss-20/BC-2.20.001.md |
| BC-2.20.002 | BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns Entering Graph Context (DI-012 Coverage Obligation) | P0 | DI-012, DI-014 | ss-20/BC-2.20.002.md |
| BC-2.20.003 | VectorStoreRetriever — SearchType Enum (Similarity \| SimilarityScoreThreshold \| Mmr); k / fetch_k / lambda_mult Configuration; Constructed via as_retriever() | P1 | DI-008 | ss-20/BC-2.20.003.md |

### 2.21 VectorStore Abstraction (CAP-028, CAP-029, CAP-030) — P0/P1

> **D21 ecosystem-parity expansion.** ferrochain-vectorstores crate; wave 2.
> BC-2.21.003 is a Red Gate test + VP-009 Kani candidate: zero-norm vector guard prevents
> NaN corruption in cosine similarity ranking.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.21.001 | VectorStore Trait — Instance-Method Surface; VectorStoreFactory Sized-Bounded Separation; Arc\<dyn VectorStore\> Dyn-Safety | P1 | DI-008 | ss-21/BC-2.21.001.md |
| BC-2.21.002 | InMemoryVectorStore — Arc\<dyn Embeddings\> DI; RwLock Interior Mutability; Vec\<f32\> Cosine; VectorStoreFactory Constructor | P1 | DI-008 | ss-21/BC-2.21.002.md |
| BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division (VP-009 Kani Candidate) | P0 | DI-008, DI-014 | ss-21/BC-2.21.003.md |
| BC-2.21.004 | MetadataFilter — Eq / Ne / In FilterClause; Additive similarity_search_with_filter; Native Pre-Filter vs InMemoryVectorStore Post-Filter; #[non_exhaustive] | P1 | DI-008, DI-014 | ss-21/BC-2.21.004.md |

### 2.22 Embeddings (CAP-031, CAP-032, CAP-033) — P1

> **D21 ecosystem-parity expansion.** ferrochain-core (Embeddings trait) + ferrochain-openai
> + ferrochain-ollama; wave 2. BC-2.22.001 is VP-008 proptest seed (dimensionality invariant).
> BC-2.22.002 is a Red Gate test for DI-010 OpenAiApiKey credential opacity.

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.22.001 | Embeddings Trait — embed_documents Batch; embed_query; Dimensionality Contract → E-EMBED-001; Batch Partial-Failure as Err; Arc\<dyn Embeddings\> Dyn-Safe (VP-008 Proptest Seed) | P1 | DI-008, DI-014 | ss-22/BC-2.22.001.md |
| BC-2.22.002 | EmbeddingsOpenAI — text-embedding-3-small/large/ada-002-legacy; OpenAiApiKey Redacted-Debug Credential Opacity (DI-010); reqwest/rustls-tls/.timeout(30s); Batch Partial-Failure as Err | P1 | DI-008, DI-009, DI-010, DI-014 | ss-22/BC-2.22.002.md |
| BC-2.22.003 | EmbeddingsOllama — No API Key; POST /api/embed Preferred; use_legacy_endpoint Toggle for /api/embeddings; reqwest/rustls-tls/.timeout(30s) Unconditional | P1 | DI-008, DI-009, DI-014 | ss-22/BC-2.22.003.md |

### 2.23 First-Party Tool Library (CAP-034, CAP-035, CAP-036, CAP-037, CAP-038) — P1

> **D23 expansion.** ferrochain-tools crate; Wave 1. PathGuard (workspace-confinement struct)
> is the shared safety primitive for all file I/O tools. BashTool enforces a non-lowerable
> Medium ActionRisk floor — the `action_risk` attribute cannot lower it below Medium
> (E-TOOLS-007). BC-2.23.005 is VP-013 Kani seed (risk-floor invariant).

| BC ID | Title | Priority | DI | File |
|-------|-------|----------|----|------|
| BC-2.23.001 | ReadFileTool — PathGuard-confined file read; 1 MiB max_bytes limit; E-TOOLS-001/E-TOOLS-002 | P1 | DI-014 | ss-23/BC-2.23.001.md |
| BC-2.23.002 | WriteFileTool — PathGuard-confined atomic write; High ActionRisk; no auto-retry; E-TOOLS-001 | P1 | DI-014 | ss-23/BC-2.23.002.md |
| BC-2.23.003 | EditFileTool — exact-match string replace; E-TOOLS-003 on no-match; opt-in fuzzy fallback (EditConfig::fuzzy_threshold); conditional retry safe | P1 | DI-014 | ss-23/BC-2.23.003.md |
| BC-2.23.004 | ListDirTool — PathGuard-confined directory listing; ReadOnly ActionRisk; DirEntry struct; E-TOOLS-001 | P1 | DI-014 | ss-23/BC-2.23.004.md |
| BC-2.23.005 | BashTool — sandboxed shell execution; non-lowerable Medium risk floor; BashOutput; 256 KiB output cap; 30 s timeout; E-TOOLS-004/005/007 (VP-013 Kani seed) | P1 | DI-014, DI-015 | ss-23/BC-2.23.005.md |
| BC-2.23.006 | GrepTool — in-process regex search; linear-time `regex` crate; max_results 100 cap; hermetic; PathGuard scope; E-TOOLS-001/006 | P1 | DI-014 | ss-23/BC-2.23.006.md |

---

## 3. Interface Definition

> **Supplement:** Full interface definitions are in `prd-supplements/interface-definitions.md`.
> Primary consumers: implementer, test-writer.

ferrochain is a Rust library framework, not a CLI tool. The public interface surface is:

- **Public Rust traits:** `Runnable<Input, Output>`, `CheckpointSaver`, `GuardrailHook`,
  `BudgetPolicy`, `BaseChatModel`, `Tool`, `MemoryStore`, `SkillStore`, `MemoryWriteGuard`,
  `ToolCallDialect`, `ProviderFallbackPolicy` _(last 4 added D20)_;
  `Retriever`, `VectorStore`, `VectorStoreFactory`, `Embeddings`
  _(added D21 — see `prd-supplements/interface-definitions.md §Retriever`,
  `§VectorStore`, `§VectorStoreFactory`, `§Embeddings`)_;
  `PreToolCallHook`, `CompactionPolicy`
  _(added D23 — see `prd-supplements/interface-definitions.md §PreToolCallHook`, `§Compaction`)_
- **First-party tools (ferrochain-tools):** `ReadFileTool`, `WriteFileTool`, `EditFileTool`,
  `ListDirTool`, `BashTool`, `GrepTool` — all PathGuard-confined; `ActionRisk` enum;
  _(added D23 — see `prd-supplements/interface-definitions.md §First-Party Tools`)_
- **Error type:** `FerrochainError { component: Component, category: Category, retry_hint, code }`
- **ferrochain-server:** First-party HTTP server with `/threads`, `/assistants`,
  `/threads/{id}/runs` (thread-nested; includes `…/stream`, `…/resume`, `…/cancel`),
  `/schedules` (flat; cron schedule CRUD + `PATCH` enable/disable) endpoints;
  `GET /runs?schedule_id=` cross-thread aggregate query (F-P23-01)
- **Cargo features:** `checkpoint-sqlite` (default), `checkpoint-memory`, `checkpoint-postgres`
  (stretch), `sandbox-wasm` (default), `sandbox-container`, `server`
- **Wire format:** msgpack for checkpoint state (D11.2); JSON for HTTP responses

See `prd-supplements/interface-definitions.md` for the complete HTTP endpoint catalog,
public trait signatures, config file schema, and Cargo feature interaction rules.

---

## 4. Non-Functional Requirements

> **Supplement:** Full NFR catalog is in `prd-supplements/nfr-catalog.md`.
> Primary consumers: architect, performance-engineer.

Summary table:

| NFR ID | Category | Target | Priority |
|--------|----------|--------|----------|
| NFR-001 | Performance | Runnable::invoke latency overhead ≤ 1ms over direct async fn | P0 |
| NFR-002 | Reliability | Zero tasks lost on process crash during sync-tier checkpoint | P0 |
| NFR-003 | Formal Verification | All 6 P0 Kani VP obligations pass before v1 convergence | P0 |
| NFR-004 | Maintainability | Production crate: ≤500 lines soft / ≤750 hard; CI gate | P0 |
| NFR-005 | Security | FerrochainError Debug impl never emits secret material | P0 |
| NFR-006 | Conformance | ferrochain-standard-tests: 100% pass for all Wave 2 providers | P1 |
| NFR-007 | Performance | ferrochain-graph: ≥100 nodes/second throughput on M1 | P1 |
| NFR-008 | Reliability | HITL interrupt state survives process restart without loss | P0 |
| NFR-009 | Security | No outbound HTTP call may hang indefinitely; 30s timeout CI-enforced | P0 |
| NFR-010 | Adoptability | ferrochain-core ≥ 4,000 downloads/month within 12 months of release | P1 |
| NFR-011 | Correctness | BSP identical graph inputs → identical outputs (Kani VP) | P0 |

See `prd-supplements/nfr-catalog.md` for full NFR table with validation methods and risk sources.

---

## 5. Error Taxonomy

> **Supplement:** Full error taxonomy is in `prd-supplements/error-taxonomy.md`.
> Primary consumers: implementer, test-writer.

Error codes follow the convention `E-<component>-<NNN>` where component is the crate
abbreviation for crate-level components (CORE, GRAPH, CHKPT, SERVER, PROV, MCP, SPLIT, SBXD,
MEMORY) or the intra-crate subsystem abbreviation for RETRY, CRON, BUDGET (which are
subsystems within ferrochain-core, ferrochain-server, and ferrochain-graph respectively —
following the same pattern as the error-taxonomy.md RETRY/CRON/BUDGET component sections).

Summary:

| Range | Component | Level | Examples |
|-------|-----------|-------|---------|
| E-CORE-001–099 | ferrochain-core | crate | E-CORE-001 InvalidContentBlock, E-CORE-002 MessageRoleUnrecognized, E-CORE-004 PipeCompositionFailed, E-CORE-008 GuardrailCriticalRejection |
| E-GRAPH-001–099 | ferrochain-graph | crate | E-GRAPH-001 InvalidUpdateError, E-GRAPH-002 NoActiveInterrupt |
| E-CHKPT-001–099 | ferrochain-checkpoint | crate | E-CHKPT-001 CheckpointWriteFailed, E-CHKPT-002 MonotonicClockRegression |
| E-SERVER-001–099 | ferrochain-server | crate | ~~E-SERVER-001 PolicyNotEnforceable~~ (retired — duplicate of E-SBXD-002; see error-taxonomy.md tombstone), E-SERVER-002 RunNotFound |
| E-PROV-001–099 | ferrochain-\<provider\> | crate | E-PROV-001 RateLimited, E-PROV-002 Timeout |
| E-MCP-001–099 | ferrochain-mcp | crate | E-MCP-001 ToolException, E-MCP-002 TransportError |
| E-SPLIT-001–099 | ferrochain-splitters | crate | E-SPLIT-001 ZeroChunkSize |
| E-SBXD-001–099 | ferrochain-sandbox | crate | E-SBXD-001 WorkspaceEscape, E-SBXD-002 PolicyNotEnforceable |
| E-MEMORY-001–099 | ferrochain-memory | crate | E-MEMORY-001 EmbeddingBackendNotConfigured, E-MEMORY-003 ScopeAccessDenied |
| E-RETRY-001–099 | ferrochain-core retry combinator | intra-crate | E-RETRY-001 RetryExhausted, E-RETRY-003 CircuitBreakerOpen |
| E-CRON-001–099 | ferrochain-server scheduler | intra-crate | E-CRON-001 AssistantNotFoundAtFiring, E-CRON-002 InvalidCronExpression |
| E-BUDGET-001–099 | ferrochain-graph budget subsystem | intra-crate | E-BUDGET-001 BudgetCeilingReached, E-BUDGET-002 JournalWriteFailed |
| E-TMPL-001–099 | ferrochain-prompts | crate | E-TMPL-001 InjectionAttempt (SECURITY), E-TMPL-002 SystemSlotTrustAllRejected, E-TMPL-003 UndefinedVariable |
| E-SRLZ-001–099 | ferrochain-core (lc-serializable) | intra-crate | E-SRLZ-001 UnknownSerializableType (STATIC — type id not echoed), E-SRLZ-002 UnsupportedMonolithType |
| E-VS-001–099 | ferrochain-vectorstores | crate | E-VS-001 ZeroNormVector (STATIC), E-VS-002 DimensionMismatch (STATIC), E-VS-003 RetrieverConfigInvalid, E-VS-004 ZeroNormWriteTime (STATIC), E-VS-005 FilterUnsupported |
| E-EMBED-001–099 | ferrochain-core (embeddings) | intra-crate | E-EMBED-001 EmbeddingDimensionMismatch (STATIC) |
| E-TOOLS-001–099 | ferrochain-tools | crate | E-TOOLS-001 PathConfinementViolation (SECURITY), E-TOOLS-002 FileReadExceedsLimit, E-TOOLS-003 EditOldStringNotFound, E-TOOLS-004 BashTimeout, E-TOOLS-005 BashOutputTruncated, E-TOOLS-006 GrepResultsCapped, E-TOOLS-007 BashRiskTierViolation, E-TOOLS-008 FileIoError (TOOL/Maybe), E-TOOLS-009 InvalidRegexPattern (VAL/Never) |

See `prd-supplements/error-taxonomy.md` for the complete catalog.

---

## 5b. Test Vectors

> **Supplement:** `prd-supplements/test-vectors.md` — consolidated test-vector catalog
> indexing the canonical test vectors embedded in all 129 BC files.
> Primary consumers: test-writer, holdout-evaluator.

---

## 6. Competitive Differentiator Traceability

### 6.1 KD-001 — LangGraph Runtime + Durable Checkpointing in Rust

| BC ID | Contribution |
|-------|-------------|
| BC-2.03.001 | BSP deterministic super-step execution — core of the LangGraph runtime |
| BC-2.03.002 | Concurrent write rejection prevents silent state corruption |
| BC-2.03.003 | Deterministic reducer order — key property no Rust competitor has |
| BC-2.04.001 | Per-task put_writes — durable before next super-step starts |
| BC-2.04.002 | Sync default — crash-safe without explicit opt-in |
| BC-2.04.005 | Crash recovery — completed tasks not re-executed |
| BC-2.05.001–006 | Full HITL contract — risk-tiered interrupt, FIFO resume, node re-execute |

### 6.2 KD-002 — Standard-Tests Conformance Suite

| BC ID | Contribution |
|-------|-------------|
| BC-2.08.001–008 | Provider trait contracts that ferrochain-standard-tests verifies |

### 6.3 KD-003 — Formally-Verified Core

| BC ID | Contribution |
|-------|-------------|
| BC-2.03.001 | VP-001 Kani P0 harness target — BSP determinism behavioral contract (Phase 6) |
| BC-2.04.006 | VP-002 Kani P0 harness target — Session tenancy triple-address contract (Phase 6) |
| BC-2.13.004 | VP-003 Kani P0 harness target — Workspace confinement behavioral contract (Phase 6) |
| BC-2.21.003 | VP-009 Kani P0 harness target — Zero-norm cosine guard behavioral contract (Phase 6) |
| BC-2.19.005 | VP-010 Kani P0 harness target — Reviver allowlist containment behavioral contract (Phase 6) |
| BC-2.05.007 | VP-011 Kani P0 harness target — PreToolCallHook fail-closed Deny behavioral contract (Phase 6) |
| BC-2.17.001 | Kani harness scope and VP obligation specification (6 P0 + 3 P1) |
| BC-2.17.002 | cargo-fuzz targets for serialization and graph paths |

### 6.4 KD-004 — Idiomatic Async-First Trait Design + 2D Error Taxonomy

| BC ID | Contribution |
|-------|-------------|
| BC-2.01.001 | Typed ContentBlock — no raw content where typed variant expected |
| BC-2.01.003 | Runnable universal composition protocol |
| BC-2.14.001 | FerrochainError 2D struct with RetryHint |
| BC-2.14.003 | Constructor Result contract — no panics in library code |
| BC-2.14.005 | Credential opacity newtypes — secrets never in debug output |

### 6.5 KD-005 — Provider Conformance + LangChain Migration Story

| BC ID | Contribution |
|-------|-------------|
| BC-2.08.001–008 | Full conformance suite — streaming, tool-call, structured output, error fidelity |
| BC-2.09.001–005 | MCP adapter — primary integration surface post-community-archive |

---

## 7. Requirements Traceability Matrix

> Module column filled from ARCH-INDEX Subsystem Registry + module-decomposition.md (Phase 1b, 2026-07-14).
> Test type abbreviations: unit=U, integration=I, property=P, fuzz=F, Kani=K, soak=S.

| BC ID | Source (L2) | Module | Priority | Test Types |
|-------|-------------|--------|----------|-----------|
| BC-2.01.001 | CAP-001 | ferrochain-core | P0 | U, P |
| BC-2.01.002 | CAP-001 | ferrochain-core | P0 | U |
| BC-2.01.003 | CAP-002 | ferrochain-core | P0 | U, I |
| BC-2.01.004 | CAP-002 | ferrochain-core | P0 | U |
| BC-2.02.001 | CAP-003 | ferrochain-graph | P0 | U |
| BC-2.02.002 | CAP-003 | ferrochain-graph | P0 | U, P |
| BC-2.02.003 | CAP-003, R-005 | ferrochain-graph | P0 | U, P |
| BC-2.02.004 | CAP-003, R-005 | ferrochain-graph | P0 | U |
| BC-2.02.005 | CAP-003 | ferrochain-graph | P0 | U, I |
| BC-2.02.006 | CAP-003 | ferrochain-graph | P0 | I |
| BC-2.03.001 | CAP-004, NE-17 | ferrochain-graph | P0 | P, K |
| BC-2.03.002 | CAP-004, DI-001 | ferrochain-graph | P0 | U, P |
| BC-2.03.003 | CAP-004, DI-001, NE-17 | ferrochain-graph | P0 | P, K |
| BC-2.04.001 | CAP-005, DI-002 | ferrochain-checkpoint | P0 | U, I, S |
| BC-2.04.002 | CAP-005, DI-002 | ferrochain-checkpoint | P0 | U, I |
| BC-2.04.003 | CAP-005, DI-004 | ferrochain-checkpoint | P0 | U, P |
| BC-2.04.004 | CAP-005, DI-004 | ferrochain-checkpoint | P0 | U, I |
| BC-2.04.005 | CAP-005, DI-002 | ferrochain-checkpoint | P0 | I, S |
| BC-2.04.006 | CAP-005, DI-005, NE-12 | ferrochain-checkpoint | P0 | P, K |
| BC-2.04.007 | CAP-005, NE-11 | ferrochain-checkpoint | P0 | U, I |
| BC-2.05.001 | CAP-006, DI-003 | ferrochain-graph | P0 | I |
| BC-2.05.002 | CAP-006, DI-003 | ferrochain-graph | P0 | U, I |
| BC-2.05.003 | CAP-006, DI-003 | ferrochain-graph | P0 | I |
| BC-2.05.004 | CAP-006, DI-003 | ferrochain-graph | P0 | U, I |
| BC-2.05.005 | CAP-006, DI-003 | ferrochain-graph | P0 | U |
| BC-2.05.006 | CAP-006, DI-003, ASM-008 | ferrochain-graph | P0 | U, I |
| BC-2.06.001 | CAP-007, DI-011 | ferrochain-graph | P0 | U, I |
| BC-2.06.002 | CAP-007 | ferrochain-graph | P0 | U, I |
| BC-2.06.003 | CAP-007, DI-011, NE-13 | ferrochain-graph | P0 | I, S |
| BC-2.07.001 | CAP-008, R-004 | ferrochain-splitters | P0 | U |
| BC-2.07.002 | CAP-008, R-004 | ferrochain-splitters | P0 | U (golden vectors) |
| BC-2.07.003 | CAP-008 | ferrochain-splitters | P0 | U |
| BC-2.08.001 | CAP-009, CAP-011, DI-011 | ferrochain-standard-tests | P1 | I |
| BC-2.08.002 | CAP-009, CAP-011 | ferrochain-standard-tests | P1 | I |
| BC-2.08.003 | CAP-009, CAP-011 | ferrochain-standard-tests | P1 | I |
| BC-2.08.004 | CAP-009, CAP-011, DI-014 | ferrochain-standard-tests | P1 | I |
| BC-2.08.005 | CAP-009, CAP-011 | ferrochain-standard-tests | P1 | I |
| BC-2.08.006 | CAP-009, DI-008 | ferrochain-openai, ferrochain-anthropic, ferrochain-ollama | P1 | U |
| BC-2.08.007 | CAP-009, DI-009, DI-014 | ferrochain-standard-tests | P1 | I |
| BC-2.08.008 | CAP-011, NE-15 | ferrochain-standard-tests | P1 | U, I |
| BC-2.08.009 | CAP-009, ADR-004 | ferrochain-standard-tests | P1 | U (snapshot) |
| BC-2.09.001 | CAP-010 | ferrochain-mcp | P1 | I |
| BC-2.09.002 | CAP-010 | ferrochain-mcp | P1 | I |
| BC-2.09.003 | CAP-010, DI-012 | ferrochain-mcp | P1 | I |
| BC-2.09.004 | CAP-010, DI-014, R-006 | ferrochain-mcp | P1 | U |
| BC-2.09.005 | CAP-010, DI-014, R-006 | ferrochain-mcp | P1 | U |
| BC-2.10.001 | CAP-012, D17-Q4 | ferrochain-graph | P0 | U, I |
| BC-2.10.002 | CAP-012, D17-Q4 | ferrochain-graph | P0 | U, P |
| BC-2.10.003 | CAP-012, D17-Q4 | ferrochain-graph | P0 | U, I |
| BC-2.10.004 | CAP-012, CAP-006, DI-003 | ferrochain-graph | P0 | I |
| BC-2.11.001 | CAP-013, DI-012 | ferrochain-graph | P0 | U, I |
| BC-2.11.002 | CAP-013, DI-012, NE-06 | ferrochain-graph | P0 | U, I |
| BC-2.11.003 | CAP-013, DI-012, NE-06 | ferrochain-graph | P0 | I |
| BC-2.11.004 | CAP-013, DI-012, NE-06 | ferrochain-graph | P0 | I |
| BC-2.11.005 | CAP-013, DI-012 | ferrochain-graph | P0 | U, I |
| BC-2.11.006 | CAP-013, DI-012 | ferrochain-graph | P0 | U |
| BC-2.12.001 | CAP-014 | ferrochain-server | P1 | I |
| BC-2.12.002 | CAP-014 | ferrochain-server | P1 | I |
| BC-2.12.003 | CAP-014 | ferrochain-server | P1 | I |
| BC-2.12.004 | CAP-014 | ferrochain-server | P1 | I |
| BC-2.12.005 | CAP-014, DI-013, NE-14 | ferrochain-server | P1 | U, I |
| BC-2.12.006 | CAP-014, NE-08 | ferrochain-server | P1 | U, I |
| BC-2.12.007 | CAP-014, DI-011, NE-13 | ferrochain-server | P1 | I, S |
| BC-2.13.001 | CAP-015, DI-006, NE-01 | ferrochain-sandbox | P1 | U, I |
| BC-2.13.002 | CAP-015, DI-006, DI-015 | ferrochain-sandbox | P1 | U |
| BC-2.13.003 | CAP-015, DI-006 | ferrochain-sandbox | P1 | U |
| BC-2.13.004 | CAP-015, DI-007, NE-02 | ferrochain-sandbox | P1 | U, P, K |
| BC-2.13.005 | CAP-015, DI-007, NE-02 | ferrochain-sandbox | P1 | U |
| BC-2.13.006 | CAP-015, DI-006, NE-16 | ferrochain-sandbox | P1 | U |
| BC-2.14.001 | CAP-016, DI-008, DI-014 | ferrochain-core | P0 | U |
| BC-2.14.002 | CAP-016 | ferrochain-core | P0 | U |
| BC-2.14.003 | CAP-016, DI-008, NE-07 | ferrochain-core | P0 | U (CI lint) |
| BC-2.14.004 | CAP-016, DI-009, NE-04 | ferrochain-core | P0 | U (CI lint) |
| BC-2.14.005 | CAP-016, DI-010, NE-10 | ferrochain-core | P0 | U (CI lint) |
| BC-2.14.006 | CAP-016, DI-014, NE-03 | ferrochain-core | P0 | U |
| BC-2.15.001 | CAP-017 | ferrochain-memory | P1 | I |
| BC-2.15.002 | CAP-017 | ferrochain-memory | P1 | I, P |
| BC-2.15.003 | CAP-017 | ferrochain-memory | P1 | I |
| BC-2.16.001 | CAP-018, NE-09 | ferrochain-core | P1 | U, I |
| BC-2.16.002 | CAP-018, NE-09 | ferrochain-core | P1 | U |
| BC-2.16.003 | CAP-018, NE-09 | ferrochain-core | P1 | U, I |
| BC-2.17.001 | CAP-019, DI-001, DI-005, DI-007, DI-014 | ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox, ferrochain-vectorstores, ferrochain-core | P2 | K |
| BC-2.17.002 | CAP-019 | ferrochain-graph, ferrochain-checkpoint | P2 | F |
| BC-2.08.010 | CAP-002, DI-008, ADR-004, ADR-008 | ferrochain-macros (re-exported ferrochain-core) | P1 | U |
| BC-2.08.011 | CAP-003, ADR-008 | ferrochain-macros (re-exported ferrochain-core) | P1 | U |
| BC-2.08.012 | CAP-003, ADR-008 | ferrochain-macros (re-exported ferrochain-core) | P1 | U |
| BC-2.04.008 | CAP-005, DI-002, DI-008, DI-014 | ferrochain-checkpoint | P1 | I |
| BC-2.08.013 | CAP-009, DI-008, DI-014 | ferrochain-core (trait), ferrochain-\<provider\> (dispatch) | P1 | U, I |
| BC-2.08.014 | CAP-009, DI-008, DI-009, DI-010, DI-014 | ferrochain-core (types), ferrochain-\<provider\> (dispatch) | P1 | U, I |
| BC-2.09.006 | CAP-021, DI-008, DI-014 | ferrochain-mcp | P1 | I |
| BC-2.09.007 | CAP-021, DI-008, DI-010, DI-014 | ferrochain-mcp | P1 | I |
| BC-2.13.007 | CAP-015, DI-006, DI-008, DI-010 | ferrochain-sandbox | P1 | U, I |
| BC-2.15.004 | CAP-020, DI-008, DI-014 | ferrochain-memory (memory::skills) | P1 | U, I |
| BC-2.15.005 | CAP-020, DI-008, DI-012, DI-014 | ferrochain-core (core::write\_guard), ferrochain-memory | P1 | U, I |
| BC-2.15.006 | CAP-020, DI-002, DI-008, DI-014 | ferrochain-core (core::context\_mutation), ferrochain-graph | P1 | I |
| BC-2.18.001 | CAP-022, DI-008, DI-014 | ferrochain-prompts | P1 | U |
| BC-2.18.002 | CAP-022, DI-008 | ferrochain-prompts | P1 | U |
| BC-2.18.003 | CAP-023, DI-008 | ferrochain-prompts | P1 | U |
| BC-2.18.004 | CAP-022, DI-008, DI-014 | ferrochain-prompts | P1 | U, K |
| BC-2.18.005 | CAP-022, DI-008, DI-014 | ferrochain-prompts | P1 | U |
| BC-2.19.001 | CAP-024, DI-008 | ferrochain-core (core::serializable) | P1 | U, P |
| BC-2.19.002 | CAP-024, DI-008, DI-010 | ferrochain-core (core::serializable) | P1 | U |
| BC-2.19.003 | CAP-025, DI-008 | ferrochain-core (core::serializable) | P1 | U |
| BC-2.19.004 | CAP-025, DI-008 | ferrochain-core (core::serializable) | P2 | U |
| BC-2.19.005 | CAP-025, DI-008, DI-014 | ferrochain-core (core::serializable) | P0 | U, K |
| BC-2.19.006 | CAP-025, DI-008, DI-014 | ferrochain-core (core::serializable) | P1 | U |
| BC-2.20.001 | CAP-026, DI-008, DI-012, DI-014 | ferrochain-core (core::retriever) | P1 | U, I |
| BC-2.20.002 | CAP-026, DI-012, DI-014 | ferrochain-core (core::retriever) | P0 | U, I |
| BC-2.20.003 | CAP-027, DI-008 | ferrochain-vectorstores | P1 | U |
| BC-2.21.001 | CAP-028, DI-008 | ferrochain-vectorstores | P1 | U |
| BC-2.21.002 | CAP-029, DI-008 | ferrochain-vectorstores | P1 | U, I |
| BC-2.21.003 | CAP-029, DI-008, DI-014 | ferrochain-vectorstores | P0 | U, K |
| BC-2.21.004 | CAP-030, DI-008, DI-014 | ferrochain-vectorstores | P1 | U |
| BC-2.22.001 | CAP-031, DI-008, DI-014 | ferrochain-core (core::embeddings) | P1 | U, P |
| BC-2.22.002 | CAP-032, DI-008, DI-009, DI-010, DI-014 | ferrochain-openai | P1 | U, I |
| BC-2.22.003 | CAP-033, DI-008, DI-009, DI-014 | ferrochain-ollama | P1 | U, I |
| BC-2.05.007 | CAP-034, DI-014 | ferrochain-graph | P1 | U, K |
| BC-2.05.008 | CAP-034, DI-014 | ferrochain-graph | P1 | U, I |
| BC-2.06.004 | CAP-034, DI-014 | ferrochain-graph | P1 | U, I |
| BC-2.06.005 | CAP-034, DI-014 | ferrochain-graph | P1 | U, I |
| BC-2.06.006 | CAP-035, DI-014 | ferrochain-graph | P1 | U |
| BC-2.10.005 | CAP-035, DI-014 | ferrochain-core | P1 | U, K |
| BC-2.10.006 | CAP-035, DI-014 | ferrochain-graph | P1 | U, I |
| BC-2.23.001 | CAP-036, DI-014 | ferrochain-tools | P1 | U, I |
| BC-2.23.002 | CAP-036, DI-014 | ferrochain-tools | P1 | U, I |
| BC-2.23.003 | CAP-036, DI-014 | ferrochain-tools | P1 | U, I |
| BC-2.23.004 | CAP-036, DI-014 | ferrochain-tools | P1 | U |
| BC-2.23.005 | CAP-037, DI-014, DI-015 | ferrochain-tools | P1 | U, K |
| BC-2.23.006 | CAP-038, DI-014 | ferrochain-tools | P1 | U |

**Totals:** 129 BCs — 51 P0 / 75 P1 / 3 P2

---

## 8. Open Question Resolutions (from Phase 1 Step B)

The following 5 open questions were routed from the L2 domain-spec Step B to this PRD step.
All are resolved here. Flagged-for-human column indicates whether human gate review is needed.

| # | Question | Resolution | Rationale | Flagged? |
|---|----------|-----------|-----------|---------|
| OQR-1 | HITL risk tiers — extend CAP-006 or new capability? | Extension of CAP-006. BC-2.05.006 adds typed action-risk levels within the HITL interrupt model. No new CAP. | The interrupt mechanism is unchanged; risk tiers are a BC-level typing of interrupt types within the same subsystem. ASM-008 confirms the capability is HITL, just richer. | No |
| OQR-2 | Agent registry — first-class vs application-layer vs deferred? | Application-layer concern. CAP-014 Assistant concept (named agent config) in ferrochain-server covers named agent registration at the server level. No separate "agent registry" primitive is in scope for v1. | LangChain v1 has no first-class agent registry; adk-rust's agent registry is REJECT (P-17). The Assistant concept in LangGraph Platform (the server's domain) is the right analog. | No |
| OQR-3 | CAP-019 phase anchoring — behavioral invariants Phase-1 vs proof deliverables Phase-6? | Behavioral invariants (DI-001, DI-005, DI-007, DI-014) get Phase-1 BCs (BC-2.03.001, BC-2.04.006, BC-2.13.004, BC-2.21.003, BC-2.19.005, BC-2.05.007). Kani proof deliverables belong to Phase 6. BC-2.17.001 specifies the VP scope (6 P0 + 3 P1); the harnesses that prove them are Phase-6 work. | This is already stated explicitly in CAP-019's domain-spec entry. Expanded from 3 to 9 VPs (6 P0 + 3 P1) per D21+D23 (burst-241). | No |
| OQR-4 | D5 proc-macro BC dependency — note gating ADR? | BCs for #[tool], #[entrypoint], #[task] proc-macro attributes are GATED on D5 ADR. They are not in the 83-BC plan. A placeholder note is in each affected subsection's BC index. D17-Q6 accepted D5 gate. | D5 ADR (schemars/proc-macro decision) must precede proc-macro BCs per D17-Q6. The 83-BC base plan contained no proc-macro BCs; 3 were added as Phase-1b amendments (BC-2.08.010–012, Batch 13) after ADR-004 and ADR-008 acceptance (total at Batch 13: 86 BCs; later grown to 95 via D20). If D5 ADR produces an ADOPT disposition, proc-macro BCs become a Phase-1b addition via the BC authoring plan. | No (D5 ADR is the gate, not human) |
| OQR-5 | DI-012 default hook behavior — default-permit or default-deny? | Default-permit with WARNING LOG at WARN level when no GuardrailHook is registered. Graph does not fail. Operator sees a warning. _(Changelog: updated INFO→WARN 2026-07-13 to match BC-2.11.006 and BC-2.09.003 which both emit `WARN`-level; INFO is insufficient for an operator-actionable security alert.)_ | Security posture (NE-01, NE-14) is about enforcing defaults for sandbox and server config — not about blocking all content when no guardrail is configured. A missing guardrail is valid for most non-SOC use cases. Domain A users must explicitly register a GuardrailHook. default-deny would break every RAG and MCP use case that doesn't need content filtering. BC-2.11.006 specifies this contract. | No |

---

## 9. NE Requirement Disposition Table

All 17 must-not-inherit requirements from COMPARATIVE-ASSESSMENT Section 4 are anchored
to BCs, CI lint gates, or ADRs.

| NE | Disposition | Anchor |
|----|-------------|--------|
| NE-01 | BC | BC-2.13.001 (enforcing sandbox default) |
| NE-02 | BC + VP seed | BC-2.13.004, BC-2.13.005 (workspace confinement) |
| NE-03 | BC | BC-2.14.006 (no silent None for validation failures) |
| NE-04 | BC + CI lint gate | BC-2.14.004 (mandatory 30s timeout; cargo xtask deny-client-new) |
| NE-05 | CI lint gate (ADR) | ADR-011 (cache-key-content-hash): cache keys must be content hash of (resolved instruction bytes + sorted tool declarations) |
| NE-06 | BC | BC-2.11.002 (tool-result ingress), BC-2.11.003 (RAG), BC-2.11.004 (memory) |
| NE-07 | BC + CI lint gate | BC-2.14.003 (constructor Result; deny-expect-in-lib lint) |
| NE-08 | BC | BC-2.12.006 (IdempotencyStore/RateLimitStore/RunStore trait seams) |
| NE-09 | BC | BC-2.16.001, BC-2.16.002, BC-2.16.003 (retry termination contract) |
| NE-10 | BC + CI lint gate | BC-2.14.005 (credential newtypes + redacted Debug) |
| NE-11 | BC | BC-2.04.007 (encryption covers state AND event payloads) |
| NE-12 | BC + VP seed | BC-2.04.006 (session triple-address uniqueness) |
| NE-13 | BC | BC-2.06.003, BC-2.12.007 (streaming/unary equivalence) |
| NE-14 | BC | BC-2.12.005 (SecurityConfig::default() secure) |
| NE-15 | BC | BC-2.08.008 (eval arithmetic mean + InfraError outcome) |
| NE-16 | BC | BC-2.13.006 (macOS Seatbelt deny-by-default) |
| NE-17 | BC + VP seed | BC-2.03.001, BC-2.03.003 (BSP determinism) |

**Coverage: 17/17 NEs anchored. 13 → BC (incl. 3 VP-seed: NE-02/12/17); 3 → BC + CI lint gate (NE-04, NE-07, NE-10); 1 → CI lint gate only (NE-05). Zero unanchored.**

---

## 10. Module Criticality

> **Supplement:** Full classification is in `prd-supplements/module-criticality.md`.

Summary:

| Crate | Criticality | Rationale |
|-------|-------------|-----------|
| ferrochain-core | CRITICAL | Security boundaries (credential opacity, constructor Result), universal composition primitive |
| ferrochain-graph | CRITICAL | BSP determinism, HITL, session tenancy — formal verification targets |
| ferrochain-checkpoint | CRITICAL | Per-task durability, monotonic clock, crash recovery, encryption at rest |
| ferrochain-server | HIGH | Secure defaults, streaming/unary equivalence, CRUD resources |
| ferrochain-mcp | HIGH | Untrusted ingress routing, tool-exception fidelity |
| ferrochain-\<provider\> | HIGH | Conformance contract, error-type fidelity |
| ferrochain-splitters | MEDIUM | Correctness-critical (code-point parity) but isolated |
| ferrochain-standard-tests | MEDIUM | Test infrastructure — quality signal, not production gate |
| ferrochain-community | LOW | Third-party contributed; not in-tree at v1 |

---

## 11. Observability — Canonical Structured Event Catalog

> **Supplement:** Full catalog is in `prd-supplements/observability.md`.

The Canonical Structured Event Catalog enumerates every `tracing::*!(event_type = "...")` emission
that is specified across the BC corpus. Per SAP-1 (CLAUDE.md §Standing Adversary Probes), each
emission site must have a catalog row with full field schema, emitting BC anchor, audit role, and
recurrence policy.

**Catalog authority:** `prd-supplements/observability.md` is the **single source of truth** for all
`event_type` emission registrations. This section does not duplicate the catalog table; consult
`observability.md` for the full row-by-row schema, field definitions, audit roles, and recurrence
policies.

**Current active count (2026-07-21):** **6** distinct `event_type` values active, 1 retired.
Full catalog: `prd-supplements/observability.md`.

**SAP-1 obligation:** implementers adding a new `event_type` emission in any `crates/` file must add a
same-commit catalog row to `prd-supplements/observability.md`. Missing rows are P1 findings in adversarial review.
