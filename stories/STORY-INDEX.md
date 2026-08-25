---
document_type: story-index
version: "1.2"
status: active
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (P2A-044/2026-08-24): Revert P2A-043 over-propagation — BC-2.06.001 removed from S-1.27 behavioral_contracts (taxonomy reference not coverage); BC-2.06.001 §Story Anchor updated to S-1.17 only."
  - "1.2 (P2A-047/2026-08-24): F-047-02: S-2.03 Subsystem column updated SS-21 → SS-21, SS-20 (BC-2.20.003 owned by SS-20 Document Retrieval per ARCH-INDEX Subsystem Registry; subsystems field is a superset of covered-BC-owning + implementation-touched subsystems, per S-1.13 SS-15,SS-03 precedent). Story versions: S-2.03 v1.3→v1.4; S-2.04 v1.3→v1.4 (verification_properties frontmatter cleared to []; VP-2.18.003-A/B are BC-local not VP-INDEX-registered)."
phase: 2
traces_to: .factory/specs/behavioral-contracts/BC-INDEX.md
inputs:
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/verification-properties/VP-INDEX.md
input-hash: "f6e9b48"
---

# STORY-INDEX: pregolya Phase 2 Story Inventory

> **40 stories total — 27 Wave 1 / 11 Wave 2 / 1 Wave 6 / 1 Maint (S-MAINT-001 housekeeping, out-of-wave)**
> **Product-story census: 39 (27 Wave 1 / 11 Wave 2 / 1 Wave 6). S-MAINT-001 is maintenance, not a product feature.**
> **BC coverage: 133 BCs — 51 P0 / 79 P1 / 3 P2 — all covered**
> **Story files:** Individual STORY-NNN specs live in `.factory/stories/stories/`

## Census

| Metric | Count |
|--------|-------|
| Total Story Files | 40 |
| Product Stories | 39 |
| Wave 1 stories | 27 |
| Wave 2 stories | 11 |
| Wave 6 stories | 1 |
| Maintenance Stories | 1 |
| Total Epics | 22 |
| BCs covered | 133 / 133 |
| Stories with VP anchor | 12 |
| Stories with Red Gate BCs | 8 |

## Story Inventory

> **Columns:** ID | Title | BCs (abbreviated) | SS | Crate(s) | Priority | Points | depends_on | Wave | Status
> **Priority** = derived from highest-priority BC in story (P0 > P1 > P2).

### Wave 1 — pregolya-core Foundation

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.01 | PregolyaError 2D Struct and RFC-7807 Emission | BC-2.14.001, BC-2.14.002 | SS-14 | pregolya-core | P0 | 5 | [] | draft |
| S-1.02 | Error Policy Enforcement — Result, Timeout, Credential, Validation | BC-2.14.003, BC-2.14.004, BC-2.14.005, BC-2.14.006 | SS-14 | pregolya-core | P0 | 5 | [S-1.01] | draft |
| S-1.03 | Message and ContentBlock Type System | BC-2.01.001, BC-2.01.002 | SS-01 | pregolya-core | P0 | 5 | [S-1.01] | draft |
| S-1.04 | Runnable Trait Invocation and Pipe Composition | BC-2.01.003, BC-2.01.004 | SS-01 | pregolya-core | P0 | 5 | [S-1.03, S-1.02] | draft |
| S-1.05 | LCEL Composition Primitives — RunnableParallel, RunnablePassthrough, RunnableAssign | BC-2.01.005, BC-2.01.006, BC-2.01.007, BC-2.01.008 | SS-01 | pregolya-core | P1 | 8 | [S-1.04] | draft |
| S-1.06 | Tool Retry Policy and Circuit Breaker | BC-2.16.001, BC-2.16.002, BC-2.16.003 | SS-16 | pregolya-core | P1 | 5 | [S-1.04, S-1.02] | draft |

### Wave 1 — pregolya-macros (proc-macro attributes)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.07 | Proc-Macro Attributes — #[tool], #[entrypoint], #[task] | BC-2.08.010, BC-2.08.011, BC-2.08.012 | SS-08 | pregolya-macros | P1 | 5 | [S-1.04] | draft |

### Wave 1 — Independent crates (parallel, depend only on pregolya-core)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.08 | Recursive Text Splitter — Unicode Boundaries and Non-ASCII Parity | BC-2.07.001, BC-2.07.002, BC-2.07.003 | SS-07 | pregolya-splitters | P0 | 8 | [S-1.01] | draft |
| S-1.09 | Sandbox Backend Selection, Path Guard and Policy Enforcement | BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.004, BC-2.13.005, BC-2.13.006, BC-2.13.007 | SS-13 | pregolya-sandbox | P1 | 13 | [S-1.01, S-1.02] | draft |
| S-1.10 | Checkpoint Core — put_writes, Durability Tiers, Monotonic Clock, Fork, Crash Recovery, Encryption | BC-2.04.001, BC-2.04.002, BC-2.04.003, BC-2.04.004, BC-2.04.005, BC-2.04.006, BC-2.04.007 | SS-04 | pregolya-checkpoint | P0 | 13 | [S-1.04, S-1.02] | draft |
| S-1.11 | FTS Conversation Search Over Checkpoint History | BC-2.04.008 | SS-04 | pregolya-checkpoint | P1 | 3 | [S-1.10] | draft |
| S-1.12 | Memory KV and Vector Persistence, Tenant Tier Isolation and GDPR Erasure | BC-2.15.001, BC-2.15.002, BC-2.15.003 | SS-15 | pregolya-memory | P1 | 8 | [S-1.04, S-1.02] | draft |
| S-1.13 | SkillStore Registry, Guarded Memory Writes and Frozen-Snapshot Context Mutation | BC-2.15.004, BC-2.15.005, BC-2.15.006 | SS-15, SS-03 | [pregolya-core, pregolya-memory, pregolya-graph] | P1 | 8 | [S-1.12, S-1.04, S-1.14, S-1.17] | draft |

### Wave 1 — pregolya-graph (StateGraph, BSP, HITL, Streaming, Budget, Guardrail)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.14 | StateGraph Node Definition and Channel Reducer Semantics | BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.004 | SS-02 | pregolya-graph | P0 | 8 | [S-1.04, S-1.01] | draft |
| S-1.15 | Conditional Edge Routing and Send API Dynamic Fan-Out | BC-2.02.005, BC-2.02.006 | SS-02 | pregolya-graph | P0 | 5 | [S-1.14] | draft |
| S-1.16 | BSP Super-Step Execution Determinism | BC-2.03.001, BC-2.03.002, BC-2.03.003 | SS-03 | pregolya-graph | P0 | 13 | [S-1.14, S-1.15, S-1.10, S-1.13, S-1.17, S-1.18] | draft |
| S-1.17 | Streaming Event Types, run_id Correlation and Run Parity | BC-2.06.001, BC-2.06.002, BC-2.06.003 | SS-06 | [pregolya-core, pregolya-graph] | P0 | 5 | [S-1.14, S-1.04, S-1.15] | draft |
| S-1.18 | Budget Policy Evaluation, EvidenceJournal and Ceiling Halt and Escalate | BC-2.10.001, BC-2.10.002, BC-2.10.003, BC-2.10.004 | SS-10 | pregolya-graph | P0 | 8 | [S-1.14, S-1.04, S-1.10, S-1.17] | draft |
| S-1.19 | GuardrailHook at All Ingress Boundaries — Tool-Result, RAG, Memory | BC-2.11.001, BC-2.11.002, BC-2.11.003, BC-2.11.004, BC-2.11.005, BC-2.11.006 | SS-11 | pregolya-graph | P0 | 13 | [S-1.14, S-1.04] | draft |
| S-1.20 | HITL Interrupt and Resume Core — FIFO Queue, Risk Classification, Command API | BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005, BC-2.05.006 | SS-05 | pregolya-graph | P0 | 13 | [S-1.16, S-1.17, S-1.10] | draft |

### Wave 1 — pregolya-tools (depends on pregolya-sandbox and pregolya-core)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.21 | File System Tools — ReadFileTool, WriteFileTool, EditFileTool, ListDirTool | BC-2.23.001, BC-2.23.002, BC-2.23.003, BC-2.23.004 | SS-23 | pregolya-tools | P1 | 8 | [S-1.09, S-1.04, S-1.07] | draft |
| S-1.22 | Shell and Search Tools — BashTool and GrepTool | BC-2.23.005, BC-2.23.006 | SS-23 | pregolya-tools | P1 | 8 | [S-1.09, S-1.21, S-1.06] | draft |

### Wave 1 — pregolya-graph late (depend on HITL, tools, compaction)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.23 | PreToolCallHook Dispatch and Skip-on-Resume Invariant | BC-2.05.007, BC-2.05.008 | SS-05 | pregolya-graph | P1 | 5 | [S-1.20, S-1.17] | draft |
| S-1.24 | Tool Approval and Compaction Streaming Events | BC-2.06.004, BC-2.06.005, BC-2.06.006 | SS-06 | pregolya-graph | P1 | 5 | [S-1.23, S-1.17, S-1.18] | draft |
| S-1.25 | Compaction Trigger Configuration and Mid-Run Execution | BC-2.10.005, BC-2.10.006 | SS-10 | [pregolya-core, pregolya-graph] | P1 | 5 | [S-1.10, S-1.18, S-1.24] | draft |

### Wave 1 — pregolya-server (depends on pregolya-graph and pregolya-checkpoint)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.26 | Thread, Assistant and Run CRUD — Durable HTTP Server | BC-2.12.001, BC-2.12.002, BC-2.12.003 | SS-12 | pregolya-server | P1 | 8 | [S-1.16, S-1.10, S-1.04] | draft |
| S-1.27 | CronSchedule, SecurityConfig, Store Seams, and SSE Streaming | BC-2.12.004, BC-2.12.005, BC-2.12.006, BC-2.12.007 | SS-12 | pregolya-server | P1 | 8 | [S-1.26] | draft |

---

### Wave 2 — pregolya-core D21 additions (LC Serialization and Retrieval)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-2.01 | LC Serialization Round-Trip, Inventory Registry and Reviver Allowlist Security | BC-2.19.001, BC-2.19.002, BC-2.19.003, BC-2.19.004, BC-2.19.005, BC-2.19.006 | SS-19 | pregolya-core | P0 | 13 | [S-1.04, S-1.02] | draft |
| S-2.02 | Retriever Trait, GuardedDocuments and RAGRetrieval Guardrail Coverage | BC-2.20.001, BC-2.20.002 | SS-20 | pregolya-core | P0 | 5 | [S-1.19, S-1.04] | draft |

### Wave 2 — pregolya-vectorstores (VectorStore Abstraction)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-2.03 | VectorStore Trait, InMemoryVectorStore, Zero-Norm Guard and MetadataFilter | BC-2.21.001, BC-2.21.002, BC-2.21.003, BC-2.21.004, BC-2.20.003 | SS-21, SS-20 | pregolya-vectorstores | P0 | 10 | [S-2.02, S-1.04, S-2.09] | draft |

### Wave 2 — pregolya-prompts (Prompt Templates and Injection Safety)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-2.04 | Prompt Template Core — PromptTemplate, ChatPromptTemplate, MessagesPlaceholder, FewShot | BC-2.18.001, BC-2.18.002, BC-2.18.003 | SS-18 | pregolya-prompts | P1 | 8 | [S-1.04, S-1.02] | draft |
| S-2.05 | Prompt Injection Safety Guard — TrustLevel Enforcement and Fail-Closed at Render Time | BC-2.18.002, BC-2.18.004, BC-2.18.005 | SS-18 | pregolya-prompts | P1 | 8 | [S-2.04] | draft |

### Wave 2 — Provider crates (SS-08 + SS-22)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-2.06 | Provider SDK Split Architecture — Standalone SDK Crate and Adapter Crate Pattern | BC-2.08.006 | SS-08 | pregolya-openai, pregolya-anthropic, pregolya-ollama, pregolya-openai-sdk, pregolya-anthropic-sdk, pregolya-ollama-sdk | P1 | 3 | [S-1.04] | draft |
| S-2.07 | Chat Model Core Conformance — Streaming, Tool-Call, Structured Output, Error Fidelity | BC-2.08.001, BC-2.08.002, BC-2.08.003, BC-2.08.004, BC-2.08.005, BC-2.08.007 | SS-08 | pregolya-openai, pregolya-anthropic, pregolya-ollama | P1 | 13 | [S-2.06, S-1.07, S-1.06] | draft |
| S-2.08 | Advanced Provider Features — Eval Scoring, Schema Stability, Tool Dialects, Failover Chain | BC-2.08.008, BC-2.08.009, BC-2.08.013, BC-2.08.014 | SS-08 | pregolya-openai, pregolya-anthropic, pregolya-ollama, pregolya-standard-tests | P1 | 8 | [S-2.07] | draft |
| S-2.09 | Embeddings Trait and Provider Implementations — OpenAI and Ollama Embeddings | BC-2.22.001, BC-2.22.002, BC-2.22.003 | SS-22 | pregolya-core, pregolya-openai, pregolya-ollama | P1 | 8 | [S-2.06, S-1.02] | draft |

### Wave 2 — pregolya-mcp (MCP Tool Adapter and Server)

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-2.10 | MCP Client — Tool Discovery, Invocation Routing and Untrusted Ingress | BC-2.09.001, BC-2.09.002, BC-2.09.003, BC-2.09.004, BC-2.09.005 | SS-09 | pregolya-mcp | P1 | 8 | [S-1.19, S-1.04, S-1.22] | draft |
| S-2.11 | MCP Server — Tool Advertisement and External Client Invocation | BC-2.09.006, BC-2.09.007 | SS-09 | pregolya-mcp | P1 | 5 | [S-2.10] | draft |

---

### Wave 6 — Formal Verification Pipeline

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-6.01 | Formal Verification Pipeline — Kani Harness Obligations and cargo-fuzz Targets | BC-2.17.001, BC-2.17.002 | SS-17 | xtask, pregolya-graph, pregolya-checkpoint, pregolya-sandbox, pregolya-core, pregolya-vectorstores, pregolya-prompts, pregolya-tools, fuzz | P2 | 8 | [S-1.16, S-1.10, S-1.09, S-2.01, S-2.03, S-1.23, S-1.25, S-1.05, S-2.09, S-2.05, S-1.22] | draft |

---

### Maintenance — EPIC-MAINT (out-of-wave)

> Product-story census is **39** (unchanged). S-MAINT-001 is a housekeeping story outside the wave schedule; it does not block Phase-3.

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|---------------------|-----------|-------------|-----|-----|------------|--------|
| S-MAINT-001 | BC Corpus Section Formatting Normalization | [] | — | .factory/specs/behavioral-contracts/ | P2 | 5 | [] | draft |

---

## Conventions

> **Story title and BC-table "Title" cells** are story-scoped intent summaries written by the
> story-writer to capture implementation focus. They are NOT canonical BC titles.
> The canonical BC titles are authoritative in `BC-INDEX.md` (POL-7).
> The story BC-table column labelled "Title" (or "Description") should be read as "Intent" —
> a paraphrase that may differ from the BC-INDEX H1 in wording while pointing to the same contract.
> BC IDs and AC traces (`traces to BC-S.SS.NNN`) are the authoritative cross-references.

> **`verification_properties` frontmatter field** holds canonical VP-INDEX IDs (`VP-0NN`) or `[]`.
> BC-local VP IDs (defined within a BC's §Verification Properties section and deliberately NOT
> registered in VP-INDEX) are documented in the story body, not in this frontmatter field.
> Example: S-1.08 uses VP-SPLIT-01..08 (BC-local, BC-2.07.001/002/003 §Verification Properties);
> these appear in the S-1.08 body's §Behavioral Contracts note, not in the frontmatter array.
> A validator checking `verification_properties ⊆ VP-INDEX` must not flag S-1.08 as having gaps
> because its frontmatter correctly holds `[]`.

> **Status axes:** `STORY-INDEX` `Status: draft` = story-document lifecycle_status (pre-merge); `sprint-state.yaml` `status: spec-ready` = Phase-3 delivery-readiness. Distinct vocabularies; both intentionally uniform pre-Phase-3.

---

## BC to Story Coverage Map

> **All 133 BCs covered. Zero silent gaps.**
> P2 BCs (BC-2.17.001, BC-2.17.002, BC-2.19.004) are explicitly assigned to stories — they are
> in v1 scope at lower priority, not post-v1 deferrals.

### SS-01 Core Primitives (8 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.01.001 | Typed ContentBlock Sequence Construction | S-1.03 | P0 |
| BC-2.01.002 | Message Type-Safety | S-1.03 | P0 |
| BC-2.01.003 | Runnable Trait Invocation | S-1.04 | P0 |
| BC-2.01.004 | Runnable Pipe Composition | S-1.04 | P0 |
| BC-2.01.005 | RunnableParallel Construction and Concurrent Invocation | S-1.05 | P1 |
| BC-2.01.006 | RunnableParallel Branch Failure | S-1.05 | P1 |
| BC-2.01.007 | RunnablePassthrough Identity Pass-Through | S-1.05 | P1 |
| BC-2.01.008 | RunnableAssign Dict Augmentation | S-1.05 | P1 |

### SS-02 StateGraph Definition (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.02.001 | StateGraph Node Definition | S-1.14 | P0 |
| BC-2.02.002 | LastValue/Append/BarrierValue Channel Semantics | S-1.14 | P0 |
| BC-2.02.003 | NamedBarrierValue Missing-Writer Boundary (RG) | S-1.14 | P0 |
| BC-2.02.004 | EphemeralValue Cleared-After-Super-Step (RG) | S-1.14 | P0 |
| BC-2.02.005 | Conditional Edge Routing Function | S-1.15 | P0 |
| BC-2.02.006 | Send API Dynamic Fan-Out | S-1.15 | P0 |

### SS-03 BSP Execution Engine (3 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.03.001 | BSP Super-Step Execution Determinism (VP-001) | S-1.16 | P0 |
| BC-2.03.002 | Concurrent LastValue Write Rejection | S-1.16 | P0 |
| BC-2.03.003 | Deterministic Reducer Application Order | S-1.16 | P0 |

### SS-04 Durable Checkpointing (8 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.04.001 | Per-Task put_writes Contract | S-1.10 | P0 |
| BC-2.04.002 | Sync Durability Tier Default | S-1.10 | P0 |
| BC-2.04.003 | Monotonic Logical-Clock Checkpoint IDs | S-1.10 | P0 |
| BC-2.04.004 | Fork Lineage via parent_checkpoint_id | S-1.10 | P0 |
| BC-2.04.005 | Crash Recovery — No Re-Execution | S-1.10 | P0 |
| BC-2.04.006 | Session Triple-Address Uniqueness (VP-002) | S-1.10 | P0 |
| BC-2.04.007 | Encryption at Rest — State and Event Payloads | S-1.10 | P0 |
| BC-2.04.008 | FTS Conversation Search | S-1.11 | P1 |

### SS-05 HITL Interrupt / Resume (8 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.05.001 | Interrupt Suspension | S-1.20 | P0 |
| BC-2.05.002 | FIFO Resume-Value Delivery | S-1.20 | P0 |
| BC-2.05.003 | Interrupted Node Re-Executes from Start | S-1.20 | P0 |
| BC-2.05.004 | Command(resume=value) API | S-1.20 | P0 |
| BC-2.05.005 | Resume on Empty Queue Returns Err | S-1.20 | P0 |
| BC-2.05.006 | Risk-Tiered Interrupt Classification | S-1.20 | P0 |
| BC-2.05.007 | PreToolCallHook Dispatch — Fail-Closed (VP-011) | S-1.23 | P1 |
| BC-2.05.008 | Skip-Hook-on-Resume Invariant | S-1.23 | P1 |

### SS-06 Streaming Event Taxonomy (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.06.001 | Typed Per-Phase Event Taxonomy — 16 Variants | S-1.17 | P0 |
| BC-2.06.002 | run_id + parent_ids Correlation | S-1.17 | P0 |
| BC-2.06.003 | Streaming and Unary Identical Final Answer | S-1.17 | P0 |
| BC-2.06.004 | tool_approval_request StreamEvent | S-1.24 | P1 |
| BC-2.06.005 | tool_approval_resolved StreamEvent | S-1.24 | P1 |
| BC-2.06.006 | compaction_event StreamEvent | S-1.24 | P1 |

### SS-07 Text Splitting (3 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.07.001 | Chunk Boundaries Are Unicode Code-Point Counts | S-1.08 | P0 |
| BC-2.07.002 | Non-ASCII Boundary Parity with Python Reference (RG) | S-1.08 | P0 |
| BC-2.07.003 | Short Document — Single Chunk, No Overlap, No Panic | S-1.08 | P0 |

### SS-08 Provider Conformance + Standard Tests (14 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.08.001 | Chat Model Streaming Completions Conformance | S-2.07 | P1 |
| BC-2.08.002 | Chat Model Tool-Call Round-Trip Conformance | S-2.07 | P1 |
| BC-2.08.003 | Chat Model Structured Output Conformance | S-2.07 | P1 |
| BC-2.08.004 | Chat Model Error-Type Fidelity | S-2.07 | P1 |
| BC-2.08.005 | Chat Model Token-Usage Accounting | S-2.07 | P1 |
| BC-2.08.006 | Standalone SDK Crate Split Architecture | S-2.06 | P1 |
| BC-2.08.007 | Transport Error Surfaces Err — Not Truncated Success | S-2.07 | P1 |
| BC-2.08.008 | Eval Score Aggregation — Arithmetic Mean + InfraError | S-2.08 | P1 |
| BC-2.08.009 | Tool Schema Naming Stability | S-2.08 | P1 |
| BC-2.08.010 | #[tool] Attribute Macro | S-1.07 | P1 |
| BC-2.08.011 | #[entrypoint] Attribute Macro | S-1.07 | P1 |
| BC-2.08.012 | #[task] Attribute Macro | S-1.07 | P1 |
| BC-2.08.013 | Pluggable Tool-Call Dialect Seam | S-2.08 | P1 |
| BC-2.08.014 | Provider Failover Chain | S-2.08 | P1 |

### SS-09 MCP Tool Adapter (7 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.09.001 | MCP Server Tool Discovery and Registration | S-2.10 | P1 |
| BC-2.09.002 | ToolInvocation Routing to Correct MCP Server | S-2.10 | P1 |
| BC-2.09.003 | Tool-Result Content Treated as Untrusted Ingress | S-2.10 | P1 |
| BC-2.09.004 | MCP Bare ToolException Re-Raise (RG) | S-2.10 | P1 |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections (RG) | S-2.10 | P1 |
| BC-2.09.006 | MCP Server Tool Advertisement (tools/list) | S-2.11 | P1 |
| BC-2.09.007 | MCP Server Tool Invocation (tools/call) | S-2.11 | P1 |

### SS-10 Budget Governance (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.10.001 | BudgetPolicy allow/escalate/deny Evaluation | S-1.18 | P0 |
| BC-2.10.002 | Append-Only EvidenceJournal | S-1.18 | P0 |
| BC-2.10.003 | Graceful Halt When Budget Ceiling Reached | S-1.18 | P0 |
| BC-2.10.004 | Budget Escalation to HITL Interrupt | S-1.18 | P0 |
| BC-2.10.005 | CompactionTrigger Config — Watermark Arithmetic (VP-012) | S-1.25 | P1 |
| BC-2.10.006 | Compaction Execution — Mid-Run Window Replacement | S-1.25 | P1 |

### SS-11 Content Provenance / Guardrail (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.11.001 | ProvenanceTag at Every Ingress Boundary | S-1.19 | P0 |
| BC-2.11.002 | GuardrailHook at Tool-Result Ingress | S-1.19 | P0 |
| BC-2.11.003 | GuardrailHook at RAG Ingress | S-1.19 | P0 |
| BC-2.11.004 | GuardrailHook at Memory Ingress | S-1.19 | P0 |
| BC-2.11.005 | Rejected Content Never Enters Model Context | S-1.19 | P0 |
| BC-2.11.006 | No-Hook Default — Pass-Through with WARNING LOG | S-1.19 | P0 |

### SS-12 Durable-Run HTTP Server (7 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.12.001 | Thread Resource CRUD | S-1.26 | P1 |
| BC-2.12.002 | Assistant Resource CRUD | S-1.26 | P1 |
| BC-2.12.003 | Run Creation and Execution Lifecycle | S-1.26 | P1 |
| BC-2.12.004 | CronSchedule Creation and Proactive Run | S-1.27 | P1 |
| BC-2.12.005 | SecurityConfig::default() Denies CORS | S-1.27 | P1 |
| BC-2.12.006 | IdempotencyStore / RateLimitStore / RunStore Seams | S-1.27 | P1 |
| BC-2.12.007 | Streaming and Unary Same Graph Engine | S-1.27 | P1 |

### SS-13 Sandboxed Tool Execution (7 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.13.001 | Enforcing Sandbox Backend Is Default | S-1.09 | P1 |
| BC-2.13.002 | Process Backend Requires Explicit Opt-In | S-1.09 | P1 |
| BC-2.13.003 | Strict Policy + Non-Enforcing Backend Returns Err | S-1.09 | P1 |
| BC-2.13.004 | Workspace File Ops Call canonicalize_beneath_root (VP-003) | S-1.09 | P1 |
| BC-2.13.005 | Symlink Workspace Escape Returns Err | S-1.09 | P1 |
| BC-2.13.006 | macOS Seatbelt Deny-by-Default Profile | S-1.09 | P1 |
| BC-2.13.007 | Environment Variable Sanitization | S-1.09 | P1 |

### SS-14 Typed Error Taxonomy (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.14.001 | PregolyaError 2D Component × Category Struct | S-1.01 | P0 |
| BC-2.14.002 | RFC-7807 Compatible Problem Emission | S-1.01 | P0 |
| BC-2.14.003 | All Library Constructors Return Result; No unwrap | S-1.02 | P0 |
| BC-2.14.004 | Every Outbound HTTP Client Must Set .timeout(30s) | S-1.02 | P0 |
| BC-2.14.005 | API Key Newtype with Redacted Debug | S-1.02 | P0 |
| BC-2.14.006 | Validation Failures Propagate Err; No Silent None | S-1.02 | P0 |

### SS-15 Long-Horizon Memory (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.15.001 | KV and Vector Memory Persistence Across Threads | S-1.12 | P1 |
| BC-2.15.002 | User/App/Session Tier Isolation | S-1.12 | P1 |
| BC-2.15.003 | GDPR Erasure — All Traces from All Memory Tiers | S-1.12 | P1 |
| BC-2.15.004 | SkillStore Registry — Load-on-Demand Skill Documents | S-1.13 | P1 |
| BC-2.15.005 | Guarded Memory and Skill Writes (MemoryWriteGuard) | S-1.13 | P1 |
| BC-2.15.006 | Frozen-Snapshot Context Mutation | S-1.13 | P1 |

### SS-16 Tool Retry + Circuit Breaker (3 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.16.001 | Per-Tool Retry Policy Keyed by tool_name | S-1.06 | P1 |
| BC-2.16.002 | Finite global_limit Non-None Default | S-1.06 | P1 |
| BC-2.16.003 | Circuit Breaker Trips After Repeated Failure | S-1.06 | P1 |

### SS-17 Formal Verification Pipeline (2 BCs — P2)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.17.001 | Six P0 Kani VP Obligations + Three P1 Kani VP Obligations | S-6.01 | P2 |
| BC-2.17.002 | cargo-fuzz Targets — Serialization and Graph-Execution Paths | S-6.01 | P2 |

### SS-18 Prompt Templates (5 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.18.001 | PromptTemplate F-String Rendering | S-2.04 | P1 |
| BC-2.18.002 | ChatPromptTemplate Multi-Message Rendering | S-2.04, S-2.05 | P1 |
| BC-2.18.003 | MessagesPlaceholder and FewShotPromptTemplate | S-2.04 | P1 |
| BC-2.18.004 | injection_guard — TrustLevel Untrusted Raises E-TMPL-001 (VP-006, RG) | S-2.05 | P1 |
| BC-2.18.005 | SlotTrustPolicy TrustAll Raises E-TMPL-002 at Construction (RG) | S-2.05 | P1 |

### SS-19 LC Serialization / Round-Trip Registry (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.19.001 | LcSerializable Round-Trip (VP-007) | S-2.01 | P1 |
| BC-2.19.002 | lc_secrets() Credential Stripping Before Serialization | S-2.01 | P1 |
| BC-2.19.003 | Inventory-Based Type Registry — OnceLock Allowlist | S-2.01 | P1 |
| BC-2.19.004 | Legacy Namespace Remap — OLD_CORE_NAMESPACES_MAPPING | S-2.01 | P2 |
| BC-2.19.005 | Reviver Allowlist Containment — E-SRLZ-001 Fail-Closed (VP-010, RG) | S-2.01 | P0 |
| BC-2.19.006 | Langchain Monolith Type Ids Return E-SRLZ-002 | S-2.01 | P1 |

### SS-20 Document Retrieval (3 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.20.001 | Retriever Trait — Arc<dyn Retriever> Graph Seam | S-2.02 | P1 |
| BC-2.20.002 | RAGRetrieval Guardrail Coverage Obligation (RG) | S-2.02 | P0 |
| BC-2.20.003 | VectorStoreRetriever SearchType Config | S-2.03 | P1 |

### SS-21 VectorStore Abstraction (4 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.21.001 | VectorStore Trait — Instance-Method Surface | S-2.03 | P1 |
| BC-2.21.002 | InMemoryVectorStore — Arc DI, RwLock, Vec<f32> Cosine | S-2.03 | P1 |
| BC-2.21.003 | Zero-Norm Vector Guard — VP-009 Kani P0 (RG) | S-2.03 | P0 |
| BC-2.21.004 | MetadataFilter — Eq/Ne/In FilterClause | S-2.03 | P1 |

### SS-22 Embeddings (3 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.22.001 | Embeddings Trait — Dimensionality Contract (VP-008) | S-2.09 | P1 |
| BC-2.22.002 | EmbeddingsOpenAI — Credential Opacity and Batch Failure (RG) | S-2.09 | P1 |
| BC-2.22.003 | EmbeddingsOllama — POST /api/embed and Legacy Toggle | S-2.09 | P1 |

### SS-23 First-Party Tool Library (6 BCs)

| BC ID | Title (abbreviated) | Story | Priority |
|-------|---------------------|-------|---------|
| BC-2.23.001 | ReadFileTool — PathGuard-Confined File Read | S-1.21 | P1 |
| BC-2.23.002 | WriteFileTool — Atomic Write; High ActionRisk | S-1.21 | P1 |
| BC-2.23.003 | EditFileTool — Exact-Match Replace; Fuzzy Fallback | S-1.21 | P1 |
| BC-2.23.004 | ListDirTool — PathGuard-Confined Directory Listing | S-1.21 | P1 |
| BC-2.23.005 | BashTool — Non-Lowerable Medium Risk Floor (VP-013) | S-1.22 | P1 |
| BC-2.23.006 | GrepTool — In-Process Regex; Linear-Time DFA | S-1.22 | P1 |

---

## VP to Story Anchor Map

| VP | BC Anchor | Story | Priority | Crate |
|----|-----------|-------|---------|-------|
| VP-001 | BC-2.03.001 | S-1.16 | P0 | pregolya-graph |
| VP-002 | BC-2.04.006 | S-1.10 | P0 | pregolya-checkpoint |
| VP-003 | BC-2.13.004 | S-1.09 | P0 | pregolya-sandbox |
| VP-004 | BC-2.09.004 | S-2.10 | P1 | pregolya-mcp |
| VP-005 | BC-2.09.005 | S-2.10 | P1 | pregolya-mcp |
| VP-006 | BC-2.18.004 | S-2.05 | P1 | pregolya-prompts |
| VP-007 | BC-2.19.001 | S-2.01 | P1 | pregolya-core |
| VP-008 | BC-2.22.001 | S-2.09 | P1 | pregolya-core |
| VP-009 | BC-2.21.003 | S-2.03 | P0 | pregolya-vectorstores |
| VP-010 | BC-2.19.005 | S-2.01 | P0 | pregolya-core |
| VP-011 | BC-2.05.007 | S-1.23 | P0 | pregolya-graph |
| VP-012 | BC-2.10.005 | S-1.25 | P1 | pregolya-core (watermark_arithmetic_harness) |
| VP-013 | BC-2.23.005 | S-1.22 | P1 | pregolya-tools |
| VP-014 | BC-2.01.005 + BC-2.01.006 | S-1.05 | P1 | pregolya-core |
