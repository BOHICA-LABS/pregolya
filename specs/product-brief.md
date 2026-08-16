---
document_type: product-brief
level: L1
version: "1.12"
status: approved
producer: product-owner
timestamp: 2026-08-16T00:00:00Z
phase: 1a
inputs:
  - .factory/planning/market-intel.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
  - .factory/planning/holdout-domains/domain-e-agentic-coding-assistant.md
  - .factory/planning/naming-decision-study.md
  - .factory/semport/reference-manifest.md
input-hash: "53d83c5"
traces_to: ""
decisions: [D1, D2, D3, D4, D5, D6, D7, D8, D9, D11, D12, D13, D17, D19, D20, D21, D22, D23]
changelog:
  - "v1.12 (burst-295/F-2-LOW/P1D-186/2026-08-16): §Market Intelligence Summary: 'D7 ferrograph as P0 differentiator' → 'D7 pregolya-graph (formerly ferrograph) as P0 differentiator'. ferrograph was the ferrochain-era internal codename for the graph runtime; current brand is pregolya-graph. Historical decision provenance (D7 GO-conditions) preserved via parenthetical clarifier. D-134 ferro-residue sweep: sole live-body occurrence in product-brief.md outside planning/ subtree."
  - "v1.11 (burst-291/D-134/2026-08-16): §Risk Register Summary phantom anchor corrected. 'risks.md §F-10' → 'risks.md §Dual Risk ID Reconciliation' (real heading is '## Dual Risk ID Reconciliation (F-10)'; §F-10 alone matches no heading in risks.md). TD-VSDD-060 sweep: sole §F-10 occurrence in live body text."
  - "v1.10 (F-178-01, burst-289, 2026-08-16): §Out of Scope Callbacks section: StreamEvent variant count corrected 15→16. BC-2.06.001 PC2 (v1.10) is the canonical 16-variant authority (added StreamEvent::Error as the 16th variant per F-P177-B01/ADR-023 §exhaustive-by-design). The Callbacks section description is a current-state claim about the live StreamEvent taxonomy and must match the authoritative BC. TD-VSDD-060 sweep: sole live '15 variants' site in product-brief.md; all other count references are historical changelog entries (exempt)."
  - "v1.9 (fix-burst-280-corr/F-P175-C207-brief/F-P175-C208/2026-07-28): C207 brief-side and C208 residue cleared. (1) C207: §Out of Scope Python runtime bullet corrected — 'one-way Python-checkpoint import tool is in scope' removed; disposition is definitively out of v1 scope per ADR-002 (post-v1 stretch; no roster slot, no SS, no capability in closed Phase 1b architecture). (2) C208: three simultaneously out-of-scope/pending items resolved with definitive decisions: voice/canvas/device-node bridges → out of v1 scope (no SS-NN, no CAP, no roster slot in closed Phase 1b architecture; SS registry has 23 subsystems covering none of these); OCSF telemetry normalization → out of v1 scope (integration-layer concern per domain-a §5; pregolya event surface is typed astream_events v2 taxonomy per SS-06/CAP-007; no SS, ADR, or capability in closed Phase 1b architecture); SEC/SOC 2 compliance semantics → out of v1 scope (operator-layer concern per domain-a §4; no SS, ADR, or capability in closed Phase 1b architecture). (3) §Open Questions: OCSF and SEC/SOC 2 references removed from Phase-1 architect gate items list; all gate items now resolved (D9 → ADR-001; D5 → ADR-004/ADR-008; OCSF and SEC/SOC 2 scope decisions resolved above)."
  - "v1.8 (fix-burst-280/F-P175-C201/C202/C203/C204/C205/C206/C209/2026-07-28): Seven findings closed across §In Scope, §Who Is It For, §Success Criteria, §Out of Scope, §Overflow. (1) C201/C203 §In Scope Wave 1: added `pregolya-tools` (SS-23/CAP-034..038/ADR-018/ADR-019/ADR-020/D23), `pregolya-macros` (ADR-008); extended `pregolya-graph` bullet with PreToolCallHook per-tool-call HITL hook (D23/ADR-018/SS-05/CAP-006 extension); extended `pregolya-checkpoint` bullet with rolling compaction (D23/ADR-019/SS-10); added CAP-017 and CAP-018 Wave-1 promotion note (SS-15/SS-16 promoted to Wave 1 per D23). (2) C203 §In Scope Wave 2: `pregolya-mcp` bullet extended with inbound MCP server role (CAP-021/D19/ADR-013); `pregolya-memory` bullet extended with self-improvement primitives (CAP-020/D20/ADR-012). (3) C202 §Who Is It For: added Domain D (Hermes Agent) and Domain E (Agentic Coding CLI) persona rows. (4) Frontmatter `inputs:` extended with domain-d-hermes-agent.md and domain-e-agentic-coding-assistant.md. (5) Frontmatter `decisions:` extended with D19/D20/D22. (6) C202 §Success Criteria holdout gate: corrected from three domains to five domains; source references extended with domain-d and domain-e. (7) C206 §In Scope Cross-cutting: VP obligation count corrected from three to six P0 obligations (VP-001/VP-002/VP-003/VP-009/VP-010/VP-011); anchors updated to reflect D17-Q7 plus D21 plus D23 expansion. (8) C206 §Overflow Differentiator Traceability: formally-verified core VP anchor column updated from three VP references to all six P0 VPs. (9) C204/C205 §Overflow Risk Register: source authority note corrected (STATE.md R-N shorthand; downstream spec authoring uses risks.md R-NNN canonical IDs per risks.md §F-10); R4 and R7 removed (archived as resolved in STATE.md); R6 row updated to describe regenerated script covering all 21 crates with 3-way AVAILABLE/OWNED/SQUATTED/UNKNOWN classification; open HIGH risks R12/R13/R14 added from STATE.md. (10) C209 §Out of Scope: CAP-002 live BA imperative removed; replaced with completed-status note."
  - "v1.7 (FIX-BURST-267/F-P165-03/2026-07-25): Workspace topology + R6 risk: update 18→21 publishable crates per D21 (pregolya-prompts #19, pregolya-vectorstores #20) and D23 (pregolya-tools #21). (1) §Constraints workspace-topology: '18 publishable crates' → '21 publishable crates'; enumeration extended with pregolya-prompts, pregolya-vectorstores, pregolya-tools; derivation parenthetical updated. (2) R6 risk mitigation: '18 publishable crates' → '21 publishable crates'; added pregolya-prompts (Wave 2), pregolya-vectorstores (Wave 2), pregolya-tools (Wave 1) to enumeration; corrected pregolya-memory Wave 2→1 (burst-265 roster fix). Both sites are live actionable instructions — wrong count risked 3 unreserved namespace squatting targets. Sweep result: zero live '18 publishable|18 crates|18-crate' actionable sites remain (v1.3/v1.4 changelog historical references exempt). decisions[] updated to include D23."
  - "v1.6 (OBS-P164-A/burst-266/2026-07-25): Out-of-Scope disposition table — four stale count references corrected. (1) Para header 'traceable to the 18-crate roster' → 'original 18-crate roster (since expanded to 21 per D21/D23)' — disposition decisions were made in burst-215 (v1.3) against the 18-crate roster; roster has since grown but these subsystems remain excluded. (2) Callbacks section '12 variants' → '15 variants' — StreamEvent taxonomy grew 12→15 per D23/BC-2.06.001 v1.5 (ADR-018 +tool_approval_request #13 + tool_approval_resolved #14; ADR-019 +compaction_event #15); the StreamEvent description is a current-state claim and must reflect the live count. (3) Callbacks section 'not in the 18-crate roster' → 'not in the current 21-crate roster' — current-state assertion about what is included. (4) chat_history section 'in the 18-crate roster' → 'in the current 21-crate roster' — same. TD-VSDD-060 sibling sweep: all four '18-crate roster' occurrences within Out-of-Scope narrative fixed in one burst; Workspace Topology line (authoritative source deferred to ARCH-INDEX §Canonical Crate Roster) and risk-register R6 narrative (historical context) left unchanged as they are not current-state assertions or explicitly defer to the index. Changelog entries (v1.3/v1.4) referencing '18-crate roster' are historical and exempt from sweep."
  - "v1.5 (burst-241/Wave-2/F-P141-02/2026-07-23): VP-gate expansion — Success Criteria 'Formal verification coverage' row updated from 3 to 6 P0 Kani VP obligations (D17-Q7 + D21 + D23) to align with nfr-catalog NFR-003 and BC-2.17.001 v1.2."
  - "v1.4 (2026-07-20): D21 ecosystem-parity scope-move (burst 216) — 5 langchain-core subsystems moved from Out-of-Scope to In Scope: prompt templates (SS-18/CAP-022..023, pregolya-prompts), LC serialization/lc-JSON (SS-19/CAP-024..025, pregolya-core::serializable), retrievers (SS-20/CAP-026..027, pregolya-vectorstores), vectorstores (SS-21/CAP-028..030, pregolya-vectorstores), embeddings (SS-22/CAP-031..033, pregolya-core + pregolya-openai + pregolya-ollama). Callbacks and output parsers remain excluded (superseded). chat_history remains excluded (superseded). Out-of-Scope 8-subsystem table condensed: 5 detailed entries replaced with IN-v1-per-D21 single-line pointers; 3 remain unchanged. CAP-002 clarification updated (PromptTemplate now in-scope per D21; only OutputParser remains post-v1). 4 new Wave 2 bullets added to §In Scope."
  - "v1.3 (2026-07-20): Q1-GAP fix (burst 215) — explicit exclusion record for 8 langchain-core subsystems present in semport/core/rust-translation-strategy.md but absent from all BCs, SSes, and crate roster. Prevents Phase-2 story-writer scope ambiguity. Eight dispositions added to Out of Scope with rationale traceable to wave plan, 18-crate roster, and D1/D7/D13. CAP-002 clarification wording provided for BA routing."
  - "v1.2 (2026-07-17): Provenance-integrity fix — removed .factory/STATE.md from inputs: list. STATE.md is a live pipeline-state file with no spec-content signal for this brief. All genuine derivation sources (market-intel, COMPARATIVE-ASSESSMENT, holdout domain files, naming study, semport reference manifest) are already listed. Input-hash recomputed."
  - "v1.1: SR-01 compress core sections; SR-02 relocate security defaults to Overflow; SR-03 mark locked tech; SR-04 reformulate time-to-market criterion"
---

# Product Brief: pregolya

## What Is This?

pregolya is a Rust implementation of the LangChain v1 architecture — a production-grade,
async-native agent orchestration framework that gives Rust developers the same conceptual
model as LangChain/LangGraph (chains, StateGraph, HITL, durable checkpointing, provider
conformance) without the Python runtime. It occupies the confirmed white space in the Rust
LLM ecosystem: no existing crate ships a StateGraph execution engine with durable per-task
checkpointing, human-in-the-loop interrupts, a provider standard-tests conformance suite,
and a formally-verified core — the four-part combination that market intelligence confirms
no competitor has (market-intel.md §4, ASM-003/ASM-004). The product is a Cargo workspace
of independently-publishable crates, not a monolith; every layer composes with standard
Rust async idioms and never requires the Python runtime.

## Who Is It For?

Primary users are Rust developers building production AI agent systems who know
LangChain/LangGraph semantics and need them in a language where Python is not an option
or is a performance liability. Five holdout-domain archetypes anchor the design (D8, D22):

| Persona | Pain Point | Current Workaround | Source |
|---------|-----------|-------------------|--------|
| Security/platform engineers building SOC-analyst agents | Durable multi-step pipelines with HITL risk-tiered authorization gates, MCP tool integration, forensic audit trails, and prompt-injection isolation at tool-result boundaries | Patch together langchain-rust + rig + swiftide manually; accept partial coverage | domain-a-soc-analyst.md §5, §10 |
| Autonomous software development teams building dark-factory pipelines | Multi-day graph runs surviving process restarts, parallel sub-agent fan-out, per-run budget/cost metering, convergence-loop support | Python LangGraph (GIL bottleneck) or custom Rust with no durable checkpoint | domain-b-dark-factory.md §5 |
| Personal AI assistant / gateway builders (OpenClaw-like) | Persistent sessions, pluggable multi-channel ingress, local-first single-binary deployment, long-horizon cross-session memory, default-on execution isolation | OpenClaw (TypeScript, 2–3 GB Docker image, host-first unsafe defaults) | domain-c-openclaw.md §5 |
| Autonomous agent builders needing an inbound MCP server role (Hermes-Agent-like) | Expose registered tools as a live MCP server endpoint; consume and forward tool results from remote MCP clients; self-improvement via SkillStore | No Rust framework exposes registered tools as an MCP server; custom server code required | domain-d-hermes-agent.md §5 |
| Agentic coding CLI / IDE extension builders (Claude-Code-like) | Fine-grained per-tool-call HITL approval, rolling context compaction, multi-session project memory, tool retry with circuit breaker, first-party file/bash/search tools (D22/D23) | Python-only or requires combining multiple incomplete Rust crates with no HITL hook API | domain-e-agentic-coding-assistant.md §5 |
| Rust developers generally building LLM applications | Must cobble together langchain-rust + rig + swiftide + rust-langgraph; none provides LangGraph runtime or formal verification | Manual multi-crate integration; no standard provider conformance contract | market-intel.md §1, §3 |

**Secondary users:** provider / tool vendors who want their integrations conformance-tested via
pregolya-standard-tests; Rust infrastructure teams (edge/WASM/embedded) where Python is
architecturally excluded.

## Scope

### In Scope

Wave 0 — Core primitives (P0, unlocks everything)
- `pregolya-core`: typed message/content primitives (Runnable, Message, ContentBlock), tool
  schema traits, PregolyaError 2D component×category error taxonomy (CONFLICT-6/D17),
  secure-by-default construction posture (NE catalog: NE-01/NE-02/NE-04/NE-07/NE-10/NE-14/D17;
  PRD-level detail in Overflow §Security-PRD-Carry-Forward)
- `pregolya-splitters`: text splitter capability with explicit BC for code-point vs
  byte-length boundary parity on non-ASCII input (R8/D17-Q9)

Wave 1 — Graph runtime + server + first-party tools (P0 lead differentiator, D7/D23)
- `pregolya-graph`: LangGraph StateGraph engine — BSP scheduling with deterministic reducer
  order (CONFLICT-1/NE-17), Send API fan-out, conditional edges, full HITL interrupt/resume
  contract (CONFLICT-3/D17-Q2); **D23 extension:** PreToolCallHook per-tool-call approval hook
  (ADR-018/SS-05/CAP-006 extension) — sub-node granularity HITL dispatch before any tool
  invocation; PreToolDecision enum (Approve/Deny/Edit/PendingHumanApproval); fail-closed Deny
  (VP-011 Kani P0 seed, DI-014)
- `pregolya-checkpoint`: three-tier durable checkpointing (sync default, crash-safe), per-task
  put_writes (CONFLICT-2/D17-Q3), monotonic logical-clock checkpoint IDs (CONFLICT-4),
  msgpack wire format [locked: D11.2], SQLite + in-memory backends [locked: D11.3],
  Postgres stretch target; **D23 extension:** rolling context compaction (ADR-019/SS-10) —
  CompactionTrigger/CompactionPolicy/CompactionSummary types in core::budget; compaction
  engine in graph::budget
- `pregolya-server`: first-party durable-run HTTP server (D13); threads, assistants, cron
  scheduler, streaming and unary run equivalence (NE-13/D17); no LangGraph Platform wire-compat
- `pregolya-sandbox`: sandboxed tool execution (SS-13/ARCH-INDEX); WASM/container enforcing
  backend default, workspace path confinement, process backend as loud opt-in (NE-01/NE-02/D17)
- `pregolya-tools`: first-party tool library (SS-23/D23/ADR-020) — `tools::fs`
  (ReadFileTool/WriteFileTool/EditFileTool/ListDirTool), `tools::shell` (BashTool/BashOutput,
  256 KiB output cap, 30 s timeout, non-lowerable Medium risk floor), `tools::search`
  (GrepTool); PreToolCallHook integration; E-TOOLS-001..009 error range;
  CAP-034/CAP-035/CAP-036/CAP-037/CAP-038; VP-013 Kani seed (risk-floor invariant)
- `pregolya-macros`: proc-macro derive support (ADR-008/D5) — `#[derive(LcSerializable)]`
  for lc-JSON round-trip registry registration; enables SS-19 serializable types without
  manual LcSerializable impl boilerplate
- **D23 Wave-1 promotions:** SS-15 (Long-Horizon Memory / CAP-017, pregolya-memory) and
  SS-16 (Tool Retry + Circuit Breaker / CAP-018, pregolya-core) promoted from Wave 2 to
  Wave 1 per D23 items 3 and 4; these promotions ensure Domain E (Agentic Coding CLI)
  holdout evaluation completes at Wave 1 (see §Success Criteria)

Wave 2 — Partners + conformance + MCP (P1, D7 roadmap)
- `pregolya-openai`, `pregolya-anthropic`, `pregolya-ollama`: first-party provider
  crates (D3 early-integration priority); standalone SDK crate split architecture (HS-6/D17-Q5)
- `pregolya-mcp`: port of langchain-mcp-adapters==0.3.0 (D1 amendment); MCP client adapter
  for security, productivity, and custom server integration (server list in Overflow §MCP-Surface);
  **D19/ADR-013 addition:** inbound MCP server role — expose registered pregolya tools as an
  MCP server endpoint so external MCP clients can call them (CAP-021/SS-09/BC-2.09.006–007)
- `pregolya-memory`: long-horizon cross-session memory (SS-15/ARCH-INDEX); vector search,
  scoped memory isolation, GDPR erasure (D17-Q4 memory holdout; domain-c cross-session requirement);
  **D20/ADR-012 addition:** self-improvement primitives — SkillStore (skill persistence and
  retrieval), MemoryWriteGuard (write-policy enforcement), ContextMutationConfig (frozen-snapshot
  context mutation rules) (CAP-020/SS-15/BC-2.15.004–006)
- `pregolya-standard-tests`: port of LangChain's langchain-tests conformance suite; all
  Wave 2 provider crates must pass before v1 release
- `pregolya-prompts`: `PromptTemplate` (f-string render, partial binding, strict-undefined
  guard, injection guard — E-TMPL-001/002), `ChatPromptTemplate` (multi-message render,
  PromptValue + MessageProvenance), `MessagesPlaceholder`, `FewShotPromptTemplate`
  (SS-18/CAP-022..023, D21)
- `pregolya-core` (LC serialization): `LcSerializable` round-trip registry, reviver allowlist
  containment (security-critical Fail-Closed, VP-010 Kani candidate), lc_secrets() credential
  stripping, namespace remap (SS-19/CAP-024..025, D21)
- `pregolya-vectorstores`: `Retriever` trait + `VectorStoreRetriever` (SearchType:
  Similarity / SimilarityScoreThreshold / MMR, BoundaryType::RAGRetrieval guardrail DI-012);
  `VectorStore` trait + `InMemoryVectorStore` + zero-norm guard (VP-009 Kani candidate);
  `MetadataFilter` (SS-20..21/CAP-026..030, D21)
- Embeddings: `Embeddings` trait in `pregolya-core`; `EmbeddingsOpenAI` in
  `pregolya-openai`; `EmbeddingsOllama` in `pregolya-ollama`; dimension-mismatch
  contract (E-EMBED-001), batch partial-failure (DI-014), redacted-Debug credential
  opacity (DI-010) (SS-22/CAP-031..033, D21)

Post-v1 community ecosystem
- Demand-ranked community integration crates: conformance-validated via pregolya-standard-tests,
  published independently (not in-tree), third-party contributed (D1 amendment)

Cross-cutting (all waves)
- Formal verification pipeline: Kani proofs + cargo-fuzz [both locked: D17-Q7] for
  pregolya-core + pregolya-graph + pregolya-checkpoint + pregolya-sandbox +
  pregolya-vectorstores + pregolya-tools invariants — 6 P0 obligations (D17-Q7 + D21 + D23):
  BSP determinism (VP-001/NE-17), session triple-address uniqueness (VP-002/DI-005/NE-12),
  workspace path confinement (VP-003/DI-007/NE-02), zero-norm cosine guard (VP-009/DI-014),
  reviver allowlist containment (VP-010/DI-014), PreToolCallHook fail-closed (VP-011/DI-014)
- Phase-1 BC backlog (D17-Q2/Q3/Q4/Q8/Q9): HITL contract, per-task durability, budget
  governance, content provenance/guardrail-on-ingress, R8/R10/R11 upstream test-void BCs —
  all authored from behavior, not deferred to Phase 3 (detail in Overflow §D17-BC-Backlog)

### Out of Scope

- Full 1,051-module langchain-community port: archived by LangChain Inc. 2026-06-19;
  community integrations are third-party contributed, not in-tree (D1)
- Wire-compatibility with LangGraph Platform or any external managed graph runtime (D13)
- A2A/AWP/ACP protocol implementations: out-of-scope per D13; COMPARATIVE-ASSESSMENT
  Section 3 (all A2A patterns NOT-APPLICABLE)
- LangGraph kafka scheduler: removed from LangGraph v1.x; not a port target (reference-manifest.md)
- Voice/audio/canvas/device-node bridges: definitively out of v1 scope — library product with no SS, CAP, or roster slot in closed Phase 1b architecture (SS registry has 23 subsystems, none covering audio/canvas/device; no ADR addresses it)
- Managed hosting / LangGraph Platform-equivalent SaaS: possible future monetization path,
  not v1 scope (market-intel.md §2)
- OCSF-style telemetry normalization at core layer: definitively out of v1 scope —
  integration-layer concern for SOC domain consumers per domain-a §5; pregolya event
  surface is the typed astream_events v2 taxonomy (SS-06/CAP-007/BC-2.06.001–006); no
  SS, ADR, or capability in closed Phase 1b architecture
- SEC disclosure / SOC 2 compliance semantics as in-product features: definitively out of
  v1 scope — compliance reporting is operator-layer concern per domain-a §4; no SS, ADR,
  or capability in closed Phase 1b architecture
- Python runtime or PyO3 interop (including one-way Python-checkpoint import tool): out of
  v1 scope per ADR-002 (post-v1 stretch; no roster slot, no SS, no capability in closed
  Phase 1b architecture); general Py bridge also excluded
- langchain-community v1.0.0a1 API tracking: alpha churn risk; community wave targets
  demand-ranked integration surface, not the archived module manifest

**Langchain-core subsystems — disposition table (semport scope clarification — Q1-GAP burst 215; updated D21 burst 216)**

The following langchain-core subsystems have detailed port strategies in
`semport/core/rust-translation-strategy.md`. Their dispositions are made explicit here to prevent
Phase-2 scope ambiguity. **5 of the original 8 exclusions were moved IN-SCOPE per D21** (prompt
templates, LC serialization/lc-JSON, retrievers, vectorstores, embeddings — SS-18..22). **3 remain
excluded** (callbacks, output parsers, chat_history). Every disposition is traceable to the original 18-crate
roster (since expanded to 21 per D21/D23), wave plan, and decision record.

- `callbacks` (~4,850 LOC) — SUPERSEDED; no 1:1 port: pregolya's observer surface is the
  typed `astream_events` v2 event taxonomy (SS-06/CAP-007, BC-2.06.001–003). The 20+ lifecycle
  `CallbackHandler` hooks are replaced by structured `StreamEvent` typed events (run/step/node/
  tool start-stream-end, 16 variants) with type-safe run_id + parent_ids correlation. LangSmith
  tracer and other `CallbackHandler` impls are not in the current 21-crate roster; they target the
  community wave. No `callbacks/` module ships in v1.

- `prompt templates` (~4,495 LOC) — **IN v1 per D21** → SS-18 (pregolya-prompts), CAP-022..023; see §In Scope Wave 2.

- `output parsers` (~2,253 LOC) — PRIMARY USE CASE SUPERSEDED; standalone trait post-v1:
  `with_structured_output<T: DeserializeOwned + JsonSchema>` on `ChatModel` (BC-2.08.003)
  covers the primary production use case (schema-backed typed extraction from LLM responses).
  The standalone `OutputParser` Runnable trait family (StrOutputParser, JsonOutputParser,
  streaming json-patch diff emitter, etc.) has no SS, BC, or crate in the wave plan; it targets
  the community wave. NOTE: a trivial `StrOutputParser` adapter may appear as internal test
  infrastructure for SS-06 streaming conformance tests; if so, it is an internal utility, not a
  first-class public API surface.

- `LC serialization / load` (`lc-JSON`, ~2,656 LOC) — **IN v1 per D21** → SS-19 (pregolya-core::serializable), CAP-024..025; see §In Scope Wave 2.

- `retrievers` (~328 LOC) — **IN v1 per D21** → SS-20 (pregolya-vectorstores), CAP-026..027; see §In Scope Wave 2.

- `vectorstores` (~1,873 LOC) — **IN v1 per D21** → SS-21 (pregolya-vectorstores), CAP-028..030; see §In Scope Wave 2.

- `embeddings` (~238 LOC) — **IN v1 per D21** → SS-22 (pregolya-core + pregolya-openai + pregolya-ollama), CAP-031..033; see §In Scope Wave 2.

- `chat_history` (~246 LOC) — SUPERSEDED; no 1:1 port: `BaseChatMessageHistory` /
  `InMemoryChatMessageHistory` / `RunnableWithMessageHistory` solve in-session message injection
  for chain-era applications. pregolya's graph-native design replaces this pattern with two
  mechanisms: (a) typed state channels (SS-02/CAP-003) using Append-reducer message lists for
  within-graph message accumulation, and (b) `Thread` (SS-12/CAP-014) for durable cross-session
  conversation persistence in pregolya-server. These jointly cover the `chat_history` use case
  without a dedicated class. No `ChatMessageHistory` trait or crate is in the current 21-crate roster.

> **CAP-002 status (completed):** capabilities-p0.md §CAP-002 has been updated per D21 scope
> move (burst 216). The first-party `PromptTemplate` is in v1 scope (SS-18/D21); first-party
> `OutputParser` implementations remain post-v1/community deliverables. No further action
> required — the BA propagation imperative that appeared here is closed.

## Success Criteria

| Outcome | Metric | Target | Source |
|---------|--------|--------|--------|
| Community adoption | crates.io monthly downloads for pregolya-core | ≥ 4,000/month within 12 months of public release (parity with langchain-rust baseline) | market-intel.md §2 (SOM), ASM-005 |
| Competitive time-to-market | pregolya-graph durable-checkpointing GA release date vs. R4 watchlist competitor announcements | Binary: pregolya-graph durable-checkpointing GA ships before any competing Rust framework announces equivalent GA; measured at release date against R4 watchlist. **Human may substitute a calendar target at Phase-1 approval gate.** | market-intel.md §1 (R4 watchlist), D7 rationale |
| Provider conformance | pregolya-standard-tests pass rate for pregolya-openai, -anthropic, -ollama | 100% conformance (streaming, tool-calling, structured output, error propagation, token accounting) before v1 release | market-intel.md §4 differentiator #2 |
| Holdout evaluation fidelity | VSDD wave-gate: mean holdout score and per-critical-scenario floor | Mean ≥ 0.85; each critical holdout ≥ 0.60; no rounding; all five domains pass Phase 4 gate | VSDD wave-gate protocol; domain-a §6, domain-b §6, domain-c §7, domain-d-hermes-agent.md §6, domain-e-agentic-coding-assistant.md §6 |
| Formal verification coverage | VP coverage: 6 P0 Kani proofs — BSP determinism (VP-001/NE-17), session tenancy (VP-002/DI-005/NE-12), workspace confinement (VP-003/DI-007/NE-02), zero-norm cosine guard (VP-009/DI-014), reviver allowlist containment (VP-010/DI-014), PreToolCallHook fail-closed (VP-011/DI-014) | All 6 P0 Kani VP obligations (D17-Q7 + D21 + D23) pass Kani harness before v1 convergence | D17-Q7 + D21 + D23; COMPARATIVE-ASSESSMENT §6 |

## Constraints & Integration Points

**Language and runtime**
- Rust only for all production crates; Python reference corpus (langchain 1.3.13, langgraph
  1.2.9, langchain-mcp-adapters 0.3.0, adk-rust v1.0.0) is analysis-only (reference-manifest.md v1.4.0)
- Minimum supported Rust edition/version: set in Phase-1 architecture ADR

**Workspace topology**
- Single Cargo workspace per D4; crates publish individually
- pregolya brand namespace (21 publishable crates — authoritative source: ARCH-INDEX §Canonical Crate Roster):
  pregolya (facade), pregolya-core, pregolya-graph, pregolya-checkpoint,
  pregolya-openai, pregolya-anthropic, pregolya-ollama, pregolya-mcp, pregolya-community,
  pregolya-splitters, pregolya-standard-tests, pregolya-server, pregolya-sandbox,
  pregolya-memory, pregolya-macros,
  pregolya-openai-sdk, pregolya-anthropic-sdk, pregolya-ollama-sdk,
  pregolya-prompts, pregolya-vectorstores, pregolya-tools
  (D6 base 9 + D1 mcp/standard-tests + D13 server + P2-05 sandbox/memory + ADR-008 macros + D17-Q5 3×-sdk
  + D21 prompts/vectorstores + D23 tools = 21; updated ADV-P1D-PASS-3 F-P3-04)
- Partner crate architecture: standalone SDK crate split (HS-6/D17-Q5); pregolya-openai-sdk,
  pregolya-anthropic-sdk, pregolya-ollama-sdk do NOT depend on pregolya-core (per ADR-007)

**API surface and semantic fidelity**
- External API surface: LangChain v1 semantic fidelity per D17 HYBRID outcome; internal
  implementation uses 43 ADOPT/ADAPT patterns from adk-rust v1.0.0 (COMPARATIVE-ASSESSMENT §5)
- All 17 NE requirements are first-class BCs, ADRs, or CI policies; must be anchored before
  Phase-2 story decomposition (COMPARATIVE-ASSESSMENT §4)

**File size and modularity standard (D12)**
- Production code: 500 lines soft / 750 hard (CI fail on `cargo xtask check-file-size`)
- Test code: 1,000 lines soft / 1,500 hard
- Exceptions via `xtask/file-size-allowlist.toml`

**Phase-1 gates (D9, D5)**
- D9: architect must present ≥2 alternatives for graph execution-model ADR before lock;
  D11 steers apply (D11.1 HYBRID engine, D11.2 msgpack, D11.3 three-tier durability, sync default)
- D5: schemars/proc-macro ADR required before proc-macro BCs can be authored (D17-Q6)

**Integration points (Wave 1)**
- pregolya-mcp targets langchain-mcp-adapters==0.3.0 (D2); verified active MCP server
  surface spans security, productivity, and custom integration (Overflow §MCP-Surface)
- Early provider integrations (D3): OpenAI, Anthropic, Ollama; full partner set in Wave 2

**Branding and discoverability**
- Do not use LANGCHAIN or LANGGRAPH marks in any crate name (naming-decision-study.md §3)
- Positioning tagline: "A Rust implementation of the LangChain v1 architecture"
- crates.io keywords: llm, agent, rag, nlp, ai; GitHub topics to match; submit to
  jondot/awesome-rust-llm and rust-unofficial/awesome-rust at launch

**Security posture**
- Secure-by-default construction: the 17 NE catalog requirements (COMPARATIVE-ASSESSMENT §4,
  D17) are first-class BCs, ADRs, or CI policies; PRD-level specification in Overflow §Security-PRD-Carry-Forward.

## Open Questions

None outstanding at brief level. All Phase-1 architect gate items resolved: D9 → ADR-001
accepted; D5 → ADR-004/ADR-008 accepted; OCSF normalization → out of v1 scope (§Out of Scope
above); SEC/SOC 2 semantics → out of v1 scope (§Out of Scope above).

---

## Overflow Context

*This section is NOT loaded into agent context by default. Phase-1 agents pull from it
on-demand via the Extended ToC pattern. Subsections tagged `PRD carry-forward` must be
anchored to BCs, ADRs, or CI policies during Phase-1 spec crystallization.*

### Market Intelligence Summary
Source: .factory/planning/market-intel.md (recommendation: CAUTION → GO-with-conditions;
market-intel gate PASSED per STATE.md)

- AI agents market: $10.9B (2026) → $182.9B (2033) at 49.6% CAGR (Grand View Research)
- Confirmed white space (ASM-003, ASM-004): zero Rust crates have LangGraph runtime +
  checkpointing + conformance suite + formal verification
- Pain validated: GitHub issue #15057 in langchain-ai/langchain explicitly requests a Rust
  LangChain implementation; Rust agents 25-44% faster and 4x less memory than Python equivalents
  (dev.to benchmark)
- GO conditions accepted: D1 scope amendment, D7 pregolya-graph (formerly 'ferrograph') as P0 differentiator, D6 brand
- Competitor traction baselines: rig ~6k stars (no checkpointing), langchain-rust ~4k
  downloads/month (chain-era model only), langgraph-rust (Onelevenvy) v0.2.x / 599 downloads

### Risk Register Summary
Source: STATE.md Risk Register — synchronized. Risk IDs (R-N) follow STATE.md operational shorthand;
downstream BC and spec authoring uses canonical risks.md R-NNN form per risks.md §Dual Risk ID Reconciliation.
R4 and R7 were archived as resolved; they no longer appear in this table.

| Risk ID | Summary | Severity | Mitigation |
|---------|---------|---------|------------|
| R6 | Namespace reservation race — `cargo login` + `publish-all.sh` not yet run (PENDING HUMAN ACTION) | High | Run (1) `cargo login` (2) `cd .factory/namespace-reservation && bash publish-all.sh`. Script covers all 21 roster crates (see ARCH-INDEX §Canonical Crate Roster) with 3-way classification: AVAILABLE (will publish), OWNED (already secured), SQUATTED or UNKNOWN (hard-fail — never counts as secured). `EXPECTED_OWNER` constant in script must match your crates.io login exactly. `pregolya-prebuilt` is NOT in the script. An inert orphan `pregolya-prebuilt/` stub directory remains under `namespace-reservation/`; it is unreferenced and pending cleanup. Sharpened by R14. |
| R8 | Splitters code-point vs byte-length parity on non-ASCII — no upstream test coverage | High | Phase-1 BC + Red Gate test authored from behavior per D17-Q9 |
| R10 | NamedBarrierValue/EphemeralValue have no upstream unit tests | Medium | Phase-1 BC backlog — product-owner authors BCs + Red Gate tests per D17-Q9 |
| R11 | MCP test voids: bare-ToolException re-raise + `__aenter__` NotImplementedError untested upstream | Medium | Phase-1 BC backlog — explicit Red Gate tests per D17-Q9 |
| R12 | D21 scope expansion introduces largest single scope delta (~9,600 ref LOC, 5 subsystems). Re-convergence cost and new attack surface (injection-safety, deserialization-safety). | High | Architecture-first: injection-safety ADR (ADR-015) and deserialization-safety ADR (ADR-016) authored before BC authoring; Phase 1d re-convergence in progress |
| R13 | D-23 scope expansion: second scope delta during Phase 1d re-convergence. Five new subsystem extensions and SS-23 new crate. | High | D23 architecture layer complete (ADR-018/ADR-019/ADR-020 accepted; SS-23 authored); Phase 1d re-convergence in progress |
| R14 | Namespace exposure — 12 specific roster crates currently unreserved until human runs `publish-all.sh`. Time-sensitive and irreversible if squatted. Sharpens R6. | High | Same as R6 mitigation. `EXPECTED_OWNER` must match crates.io identity exactly. Script exits non-zero on any SQUATTED or UNKNOWN result. |

### Reference Corpus Pins
Source: .factory/semport/reference-manifest.md v1.4.0

| Corpus | Tag | SHA |
|--------|-----|-----|
| langchain | langchain==1.3.13 | 42f8f79293cfb7589e5bc1d74a8ae4dfd0bf15e3 |
| langgraph | 1.2.9 | 95af6a00718588e7b7ce17310e8006d267896a77 |
| langchain-community | libs/community/v0.4.2 | 7c10a5fa327f6aaaf7c932822a9e5d144891406e |
| langchain-mcp-adapters | langchain-mcp-adapters==0.3.0 | a61c783a7949719a8c3fbe4aeba961f45f3b7849 |
| adk-rust (comparative) | v1.0.0 | a6c79b6f97a338de58d2c0fbf33cac00eaae0f13 |

### D17 HYBRID Outcome — Phase-1 BC Scope Commitments
Source: STATE.md D17, COMPARATIVE-ASSESSMENT.md §6

Five Phase-1 BC categories committed at the Human Direction Gate (all Q2–Q9 accepted verbatim):

1. **HITL contract** (D17-Q2, CONFLICT-3): per-task scratchpad, FIFO resume-value delivery,
   node-re-executes-from-start, Command(resume=value) API — cannot be retrofitted post-graph-design
2. **Per-task durability** (D17-Q3, CONFLICT-2): sync-default put_writes per task in checkpoint
   store; Domain B multi-day holdout depends on this
3. **Budget governance** (D17-Q4, HS-4/HS-9): allow/escalate/deny policy trait, composable,
   append-only evidence journal — Domain B dark-factory holdout requires it
4. **Content provenance / guardrail-on-ingress** (D17-Q8, NE-06/HS-8): provenance-tag seam +
   guardrail hook at tool-result, RAG, and memory ingress — Domain A SOC analyst holdout
5. **R8/R10/R11 BC backlog** (D17-Q9): splitters code-point parity (R8) +
   NamedBarrierValue/EphemeralValue behavioral contracts (R10) + MCP bare-ToolException/
   `__aenter__` contracts (R11) — all authored from behavior, not deferred to Phase 3

This is also the `### D17-BC-Backlog` section referenced from core §Scope.

### Competitive Differentiator Traceability
Source: market-intel.md §4, COMPARATIVE-ASSESSMENT.md §5 (seeded from L2 → PRD Section 6)

| Differentiator | Source | BC anchor (Phase 1) |
|---------------|--------|---------------------|
| LangGraph runtime + durable checkpointing in Rust — no competitor has this | market-intel §4 #1, CONFLICT-1/2/3/4 | Graph BSP determinism + HITL + per-task durability BCs (D17-Q2/Q3) |
| Standard-tests conformance suite — no competitor has this | market-intel §4 #2 | pregolya-standard-tests conformance BC |
| Formally-verified core (Kani + cargo-fuzz) — no competitor has this | market-intel §4 #3, D17-Q7 + D21 + D23 | VP-001 BSP determinism (NE-17), VP-002 session triple-address (DI-005/NE-12), VP-003 workspace path confinement (DI-007/NE-02), VP-009 zero-norm cosine guard (DI-014), VP-010 reviver allowlist containment (DI-014), VP-011 PreToolCallHook fail-closed (DI-014) |
| Idiomatic async-first trait design with typed ContentBlock | market-intel §4 #4, CONFLICT-6 | PregolyaError 2D struct BC, typed ContentBlock BC |
| Provider conformance + migration story from LangChain Python v1 | market-intel §4 #5 | pregolya-standard-tests + "Coming from LangChain?" docs |

### Security Defaults — PRD Carry-Forward
*Tag: PRD carry-forward. Source: NE catalog (COMPARATIVE-ASSESSMENT §4), D17, CLAUDE.md D10.*
*Every item must be anchored to a BC, ADR, or CI policy before Phase-2 story decomposition.*

| NE | Requirement | Anchor type |
|----|-------------|------------|
| NE-14 | SecurityConfig::default() must be deny-CORS and debug route must be explicitly gated | BC |
| NE-10 | Every API key type: newtype wrapper + `impl Debug → "<redacted>"`; no `#[derive(Serialize)]`; no `Deref<Target=str>` | BC + CI lint |
| NE-07 | All library constructors return `Result`; no `.expect()`/`.unwrap()`/`assert!` in non-test code; Default must not delegate to fallible ctor | BC + CI lint |
| NE-04 | Every outbound HTTP client builder must set a mandatory connection timeout (recommended 30s); zero `Client::new()` outside test files | CI lint gate |
| NE-01 | Enforcing sandbox backend (WASM/container) must be the default; process backend is loud opt-in; `Sandbox::execute` on strict policy against non-enforcing backend returns `Err(PolicyNotEnforceable)` | BC |
| NE-02 | All workspace file operations must call `canonicalize_beneath_root(base, path)` at access time; no file op may observe content outside declared workspace root | BC + VP |

### MCP Server Surface — Integration Reference
*Tag: reference. Source: domain-a-soc-analyst.md §3 (independently cross-verified [V]). D1.*
*This is the §MCP-Surface section referenced from core Constraints.*

| Tool | Status | Governance |
|------|--------|-----------|
| Splunk MCP Server (Splunkbase app 7931) | GA (v1.2.1, Jun 2026) | Official (Splunk LLC) |
| Microsoft Sentinel MCP | GA (Nov 2025) | Official (Microsoft) |
| Okta MCP Server | Active | Official (Okta) |
| ServiceNow MCP Console | Active | Official (ServiceNow) |
| CrowdStrike falcon-mcp | Preview (Aug 2025) | Community — NOT official CrowdStrike product (MIT) |
| VirusTotal mcp-virustotal | Active | Community |
| MISP MCP Server | Active | Community |
| AlienVault OTX otx-mcp | Active | Community |

These validate pregolya-mcp's prioritization per D1 amendment. Could NOT verify dedicated
MCP servers for Elastic Security, Google Chronicle, SentinelOne, PagerDuty, or Recorded
Future as of mid-2026.
