---
document_type: epics
version: "1.0"
status: active
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
traces_to: .factory/specs/architectural/ARCH-INDEX.md
---

# Epics — pregolya Phase 2

> **22 epics spanning 39 stories across Wave 1 (27), Wave 2 (11), Wave 6 (1).**
> Epic IDs are stable references. Stories within each epic share a primary subsystem.

## Epic Catalog

| Epic ID | Title | Wave | Stories | Points | Primary Subsystem | Primary Crate(s) |
|---------|-------|------|---------|--------|-------------------|-----------------|
| E-01 | Core Primitives — Error Taxonomy, Message Types, Runnable, LCEL | 1 | S-1.01, S-1.02, S-1.03, S-1.04, S-1.05, S-1.06 | 33 | SS-01, SS-14, SS-16 | pregolya-core |
| E-02 | Proc-Macro Attributes | 1 | S-1.07 | 5 | SS-08 | pregolya-macros |
| E-03 | Text Splitting — Recursive Unicode Splitter | 1 | S-1.08 | 8 | SS-07 | pregolya-splitters |
| E-04 | Sandboxed Tool Execution | 1 | S-1.09 | 13 | SS-13 | pregolya-sandbox |
| E-05 | Durable Checkpointing | 1 | S-1.10, S-1.11 | 16 | SS-04 | pregolya-checkpoint |
| E-06 | Long-Horizon Memory | 1 | S-1.12, S-1.13 | 16 | SS-15 | pregolya-memory |
| E-07 | StateGraph Definition | 1 | S-1.14, S-1.15 | 13 | SS-02 | pregolya-graph |
| E-08 | BSP Execution Engine | 1 | S-1.16 | 13 | SS-03 | pregolya-graph |
| E-09 | Streaming Event Taxonomy | 1 | S-1.17, S-1.24 | 10 | SS-06 | pregolya-graph |
| E-10 | Budget Governance and Compaction | 1 | S-1.18, S-1.25 | 13 | SS-10 | pregolya-graph |
| E-11 | Content Provenance and Guardrail Hooks | 1 | S-1.19 | 13 | SS-11 | pregolya-graph |
| E-12 | HITL Interrupt / Resume | 1 | S-1.20, S-1.23 | 18 | SS-05 | pregolya-graph |
| E-13 | First-Party Tool Library | 1 | S-1.21, S-1.22 | 16 | SS-23 | pregolya-tools |
| E-14 | Durable-Run HTTP Server | 1 | S-1.26, S-1.27 | 16 | SS-12 | pregolya-server |
| E-15 | LC Serialization / Round-Trip Registry | 2 | S-2.01 | 13 | SS-19 | pregolya-core |
| E-16 | Document Retrieval | 2 | S-2.02 | 8 | SS-20 | pregolya-core, pregolya-vectorstores |
| E-17 | VectorStore Abstraction | 2 | S-2.03 | 8 | SS-21 | pregolya-vectorstores |
| E-18 | Prompt Templates and Injection Safety | 2 | S-2.04, S-2.05 | 16 | SS-18 | pregolya-prompts |
| E-19 | Provider SDK Conformance | 2 | S-2.06, S-2.07, S-2.08 | 24 | SS-08 | pregolya-openai, pregolya-anthropic, pregolya-ollama |
| E-20 | Embeddings Trait and Providers | 2 | S-2.09 | 8 | SS-22 | pregolya-core, pregolya-openai, pregolya-ollama |
| E-21 | MCP Tool Adapter | 2 | S-2.10, S-2.11 | 13 | SS-09 | pregolya-mcp |
| E-22 | Formal Verification Pipeline | 6 | S-6.01 | 8 | SS-17 | xtask, pregolya-graph, pregolya-checkpoint, pregolya-sandbox |

## Epic Summaries

### E-01 — Core Primitives (Wave 1, 33 pts)

The foundation of the entire workspace. Establishes `PregolyaError` (2D component × category struct,
RFC-7807 emission), the `Message`/`ContentBlock` type system, the `Runnable` trait invocation model,
LCEL composition (`RunnableParallel`, `RunnablePassthrough`, `RunnableAssign`), and the tool
retry/circuit-breaker policy. Every other crate depends on this epic. All production-grade constraints
(no `unwrap`, redacted `Debug` for credentials, reqwest rustls-tls, 30s timeout) are first exercised here.

**VP Anchor:** VP-014 (RunnableParallel key-completeness proptest, P1) anchors to S-1.05.

### E-02 — Proc-Macro Attributes (Wave 1, 5 pts)

Provides `#[tool]`, `#[entrypoint]`, and `#[task]` attribute macros that generate boilerplate
for tool registration, graph entrypoint wiring, and async task wrapping. These macros are consumed
by E-13 (tools), E-19 (providers), and the Wave 2 ecosystem. Built in `pregolya-macros`.

### E-03 — Text Splitting (Wave 1, 8 pts)

Recursive character-based text splitter with strict Unicode code-point boundary semantics
and byte-perfect parity with the Python reference implementation for non-ASCII content.
Red Gate: BC-2.07.002 non-ASCII parity test must be written and failing before implementation.

### E-04 — Sandboxed Tool Execution (Wave 1, 13 pts)

Security-critical sandbox for all tool file and process operations. Enforces workspace
confinement via `canonicalize_beneath_root`, symlink escape prevention, macOS Seatbelt deny-by-default,
and env var sanitization. VP-003 (Kani P0) anchors BC-2.13.004 workspace confinement — Kani harness
must be produced in Phase 6.

### E-05 — Durable Checkpointing (Wave 1, 16 pts)

Full checkpoint lifecycle: `put_writes` durability contract, monotonic logical-clock IDs, fork
lineage, crash recovery (no re-execution), triple-address session uniqueness (VP-002), at-rest
encryption, and FTS conversation search over checkpoint history. SQLite and in-memory backends.
The graph execution engine (E-08) depends on this epic.

### E-06 — Long-Horizon Memory (Wave 1, 16 pts)

KV and vector memory persistence across threads, user/app/session tenant tier isolation,
GDPR erasure (all tiers), SkillStore load-on-demand registry, guarded memory writes
(`MemoryWriteGuard`), and frozen-snapshot context mutation. Security-sensitive: guards must
be fail-closed.

### E-07 — StateGraph Definition (Wave 1, 13 pts)

`StateGraph` node/edge API, `LastValue`/`Append`/`BarrierValue`/`EphemeralValue` channel reducers,
conditional edge routing functions, and `Send` API dynamic fan-out. Red Gate BCs:
`NamedBarrierValue` missing-writer boundary (BC-2.02.003) and `EphemeralValue` cleared-after-super-step
(BC-2.02.004).

### E-08 — BSP Execution Engine (Wave 1, 13 pts)

The Bulk-Synchronous Parallel super-step execution engine. Deterministic execution order,
concurrent `LastValue` write rejection, and deterministic reducer application order.
VP-001 (Kani P0) anchors BC-2.03.001 BSP determinism — the highest-criticality formal proof in the workspace.
Depends on E-05 (checkpoint) and E-07 (StateGraph).

### E-09 — Streaming Event Taxonomy (Wave 1, 10 pts)

Typed per-phase streaming event taxonomy (16 variants including `on_chain_start`, `on_tool_start`,
`on_llm_stream`, etc.), `run_id` + `parent_ids` correlation, streaming/unary output parity, and
tool-approval / compaction event types (S-1.24 extends the base taxonomy established in S-1.17).

### E-10 — Budget Governance and Compaction (Wave 1, 13 pts)

`BudgetPolicy` allow/escalate/deny evaluation, append-only `EvidenceJournal`, graceful halt at
ceiling, budget escalation to HITL interrupt, `CompactionTrigger` watermark arithmetic (VP-012),
and mid-run compaction window replacement.

### E-11 — Content Provenance and Guardrail Hooks (Wave 1, 13 pts)

`ProvenanceTag` at every ingress boundary, `GuardrailHook` at tool-result / RAG / memory ingress
boundaries, rejected-content never enters model context, and no-hook default pass-through with
WARNING log. P0 security-critical — all 6 BCs are P0.

### E-12 — HITL Interrupt / Resume (Wave 1, 18 pts)

Human-in-the-loop interrupt suspension, FIFO resume-value delivery, interrupted-node re-execution
from start, `Command(resume=value)` API, resume-on-empty-queue error, risk-tiered interrupt
classification, `PreToolCallHook` dispatch (VP-011, Kani P0), and skip-hook-on-resume invariant.

### E-13 — First-Party Tool Library (Wave 1, 16 pts)

`ReadFileTool`, `WriteFileTool`, `EditFileTool`, `ListDirTool` (all PathGuard-confined),
`BashTool` (non-lowerable medium risk floor, VP-013 Kani P1), and `GrepTool` (in-process
linear-time DFA regex). All tools depend on E-04 (sandbox) and E-01 (core types).

### E-14 — Durable-Run HTTP Server (Wave 1, 16 pts)

Axum-based HTTP server: Thread/Assistant/Run CRUD, `CronSchedule` proactive run, `SecurityConfig::default()` CORS-deny, idempotency/rate-limit/run store seams, and streaming/unary same graph engine. Depends on E-08 (BSP) and E-05 (checkpoint).

### E-15 — LC Serialization / Round-Trip Registry (Wave 2, 13 pts)

`LcSerializable` round-trip (VP-007 proptest P1), `lc_secrets()` credential stripping, OnceLock allowlist-based type registry, legacy namespace remap (`OLD_CORE_NAMESPACES_MAPPING`, P2), reviver allowlist containment fail-closed (VP-010 Kani P0, Red Gate), and langchain-monolith type ID rejection. Security-critical serialization path.

### E-16 — Document Retrieval (Wave 2, 8 pts)

`Retriever` trait as `Arc<dyn Retriever>` graph seam, RAGRetrieval guardrail coverage obligation
(BC-2.20.002 Red Gate), and `VectorStoreRetriever` search-type configuration.

### E-17 — VectorStore Abstraction (Wave 2, 8 pts)

`VectorStore` trait (instance-method surface), `InMemoryVectorStore` with `Arc` DI, `RwLock`,
Vec<f32> cosine similarity, zero-norm vector guard (VP-009 Kani P0, Red Gate), and
`MetadataFilter` with Eq/Ne/In clauses.

### E-18 — Prompt Templates and Injection Safety (Wave 2, 16 pts)

`PromptTemplate` f-string rendering, `ChatPromptTemplate` multi-message rendering,
`MessagesPlaceholder` and `FewShotPromptTemplate`, and injection safety guard with
`TrustLevel` enforcement (VP-006 Kani P1, Red Gate). Both BCs in S-2.05 are Red Gate.

### E-19 — Provider SDK Conformance (Wave 2, 24 pts)

Standalone SDK crate split architecture (BC-2.08.006), chat model streaming/tool-call/structured-output/error-fidelity/token-usage conformance across OpenAI + Anthropic + Ollama, eval score aggregation, tool schema naming stability, pluggable tool-call dialect seam, and provider failover chain. Largest Wave 2 epic.

### E-20 — Embeddings Trait and Providers (Wave 2, 8 pts)

`Embeddings` trait with dimensionality contract (VP-008 proptest P1, Red Gate),
`EmbeddingsOpenAI` with credential opacity and batch failure handling, and
`EmbeddingsOllama` POST /api/embed with legacy endpoint toggle.

### E-21 — MCP Tool Adapter (Wave 2, 13 pts)

MCP client: tool discovery, invocation routing, untrusted-ingress guardrail coverage, bare
`ToolException` re-raise (Red Gate, VP-004 integration P1), and `MultiServerMcpClient` holds-no-live-connections invariant (VP-005 integration P1). MCP server: tool advertisement (tools/list) and invocation (tools/call).

### E-22 — Formal Verification Pipeline (Wave 6, 8 pts)

Single story that establishes the Kani harness obligations for all 9 VP Kani proofs
(6 P0 + 3 P1), cargo-fuzz targets for serialization and graph-execution paths, and cargo-mutants
mutation gate. This story formally executes the verification plans laid out in VP-001 through
VP-014. Gated until all Wave 1 + Wave 2 implementation stories are merged.
