---
document_type: domain-spec-section
level: L2
section: bounded-contexts
version: "1.6"
status: active
producer: business-analyst
timestamp: 2026-07-27T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
input-hash: "b170fb3"
traces_to: L2-INDEX.md
decisions: [D1, D4, D6, D11, D13, D17, D19, D20, D21, D23]
changelog:
  - "1.6 (NOTATION-SWEEP-DOMAIN-SPEC/2026-07-29): Error-construction notation corrections per ADR-010 §Error-Construction Notation Canon. 2 CLASS3_MISSING_DOTDOT violations corrected: added `, ..` before `}` in PregolyaError { code: E-SBXD-001 } (Context 9 Translation seam with Core) and PregolyaError { code: E-TMPL-001 } (Context 11 Translation seam with Core); both were partial-field observations (code-only; 4 of 5 non-source fields elided) with no elision marker."
  - "1.5 (F-P173-104/burst-276/2026-07-27): Fix Context Dependency Order — remove pregolya-graph from pregolya-tools direct-dep list. ADR-020 Decision 1 explicitly states pregolya-tools does NOT depend on pregolya-graph at compile time; ActionRisk is in pregolya-core::action_risk per D-24/ADR-020 Decision 1 adjudication. The v1.3 changelog entry recorded 'pregolya-tools multi-dep edges (core+sandbox+graph+macros per ADR-020)' — that history entry is preserved per TD-VSDD-091 but is incorrect; live body now reflects ADR-020 Decision 1 canon. TD-VSDD-060 sibling sweep of domain-spec/: entities-graph.md correctly confirms no pregolya-graph compile-time dep for pregolya-tools; sole live-body defect in domain-spec/ was this Context Dependency Order line."
  - "1.4 (F-P170-16/burst-272/2026-07-25): Fix Context 13 'What it owns' — retire set_risk(ReadOnly)/set_risk(Low) spellings; replace with canonical ToolConfig::override_risk(ActionRisk::ReadOnly) and ToolConfig::override_risk(ActionRisk::Low) per BC-2.23.005 v1.7 §Invariants adjudication (ADR-020 Decision 3). TD-VSDD-060 sweep: sole set_risk occurrence in this file."
  - "1.3 (fix burst 242 F-P142-04, 2026-07-23): Map 6 orphaned crates into DDD model: Context 9 (pregolya-sandbox, P2-05/DI-006/DI-007/DI-015), Context 10 (pregolya-memory, D20/CAP-020/SS-15), Context 11 (pregolya-prompts, D21/SS-18/CAP-022/023), Context 12 (pregolya-vectorstores, D21/SS-20/SS-21/FM-017), Context 13 (pregolya-tools, D23/SS-23/FM-019), Context 14 (pregolya-macros, ADR-008). Context 5 updated: D21 embedding modules (openai::embeddings, ollama::embeddings) noted per ADR-017. Context 6 updated: D19/D20 mcp::server capability (CAP-021/ADR-013) added to model and ownership. Context Dependency Order updated: pregolya-macros as proc-macro root (no pregolya-* runtime deps); 6 new crate entries with correct acyclic edges; pregolya-tools multi-dep edges (core+sandbox+graph+macros per ADR-020); all 21 canonical crates from ARCH-INDEX accounted for. Decisions [D1,D4,D6,D11,D13,D17] -> [D1,D4,D6,D11,D13,D17,D19,D20,D21,D23]. input-hash recomputed to ff4eb49 (new inputs ARCH-INDEX.md + module-decomposition.md added)."
  - "1.2 (F-P122-01, fix burst 125, 2026-07-19): Context 8 Splitters translation seam: 'Splitters accept and return ContentBlocks (Document variant)' -> 'Splitters accept plain UTF-8 String inputs and return Vec<String> chunk strings' per BC-2.07.001/002/003 preconditions. Document is not a canonical ContentBlock variant (BC-2.01.001 PC2 14-variant list). ContentBlock wrapping is caller responsibility."
  - "1.1 (F-P121-01, fix burst 124, 2026-07-19): Context 6 MCP Adapter: 'conversion from MCP tool result to ToolResult ContentBlock' -> 'ToolMessage (BC-2.09.002)'; translation seam: 'ToolResult from MCPTool' / 'ToolResult -> GuardrailHook boundary' -> canonical ToolMessage/IngressContent::ToolResult phrasing. TD-VSDD-060 sweep: only Context 6 had ToolResult ContentBlock vocabulary; fixed."
  - "1.0 (initial): base bounded contexts authored."
---

# Bounded Contexts

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

For this pipeline-oriented framework, bounded contexts map to crate-level subsystems.
Each context has a clear model boundary and a translation seam where it meets others.

---

## Context 1: Core Primitives (pregolya-core)

**Model:** Messages, ContentBlocks, Runnable trait, Tool schema traits, PregolyaError.
**What it owns:** The universal composition protocol; the error taxonomy; credential types.
**What it does NOT own:** Graph state; checkpointing; server routing; provider transports.
**Translation seam:** All other contexts depend on pregolya-core types. The only
direction is inward — pregolya-core does not depend on any other pregolya crate.
**Key invariants:** DI-008 (constructor Result), DI-010 (credential opacity), DI-014
(error propagation), DI-009 (outbound timeout).

---

## Context 2: Graph Execution (pregolya-graph)

**Model:** StateGraph, Node, Channel, GraphState, PregelTask, SuperStep, Send API,
conditional edges, HITL Interrupt, ResumeValue.
**What it owns:** The BSP execution model; channel reducer application; HITL lifecycle;
graph compilation and validation.
**What it does NOT own:** Checkpoint persistence (delegates to pregolya-checkpoint);
server HTTP layer; provider transport.
**Translation seam with Core:** StateGraph nodes are Runnables from pregolya-core.
**Translation seam with Checkpoint:** Graph execution calls `put_writes` on the
CheckpointSaver trait; the concrete implementation is injected (dependency inversion).
**Key invariants:** DI-001 (BSP determinism), DI-002 (per-task durability), DI-003
(HITL FIFO), DI-004 (monotonic clock), DI-012 (guardrail ingress coverage).

---

## Context 3: Checkpoint / Durability (pregolya-checkpoint)

**Model:** Checkpoint, PendingWrite, CheckpointSaver trait, CheckpointTuple, delta
serialization, logical clock.
**What it owns:** The durability model; checkpoint ID generation; delta encoding;
msgpack serialization; SQLite and in-memory backends.
**What it does NOT own:** Graph execution logic; when to checkpoint (that is Context 2's
policy); network transport.
**Translation seam with Graph:** Exposes `CheckpointSaver` trait; graph execution holds
an Arc<dyn CheckpointSaver>.
**Translation seam with Server:** Server's Thread model is backed by CheckpointSaver
thread_id partitioning.
**Key invariants:** DI-002, DI-004, DI-005 (session triple-address).

---

## Context 4: Server (pregolya-server)

**Model:** Thread, Assistant, Run, CronSchedule, StreamEvent, SecurityConfig.
**What it owns:** HTTP endpoint routing; run lifecycle management; cron scheduling;
streaming protocol; authentication; per-tenant isolation.
**What it does NOT own:** Graph execution semantics (delegates to Context 2); checkpoint
persistence (delegates to Context 3).
**Translation seam with Graph:** Server creates a CompiledGraph from an Assistant's
graph_id and invokes it for each Run.
**Translation seam with Checkpoint:** Server uses CheckpointSaver to persist/resume Run
state.
**Key invariants:** DI-005 (tenancy), DI-011 (streaming/unary equiv.), DI-013 (secure defaults).
**Excluded failure mode (FM-007):** streaming stub must not exist.
**Out-of-scope note:** No wire compatibility with LangGraph Platform (D13).

---

## Context 5: Providers (pregolya-openai, pregolya-anthropic, pregolya-ollama)

**Model:** ProviderClient (ChatModel Runnable), ApiKey newtypes, streaming completions,
tool-call round-trips, structured output, token usage accounting.
**What it owns:** Provider-specific wire protocol; streaming event mapping; error
translation to PregolyaError; credential management.
**What it does NOT own:** Graph orchestration; checkpointing; server routing.
**Architecture:** Standalone SDK crate split (HS-6/D17-Q5): `pregolya-<provider>-sdk`
(wire client) + `pregolya-<provider>` (Runnable adapter). Final names in architecture ADR.
**Translation seam with Core:** Provider crates implement ChatModel Runnable from
pregolya-core.
**Translation seam with Standard Tests:** pregolya-standard-tests imports provider crates
and exercises the ChatModel interface.
**Key invariants:** DI-009 (outbound timeout), DI-010 (credential opacity).
**D21 extension (ADR-017):** pregolya-openai and pregolya-ollama each gain an
`embeddings` module implementing the `Embeddings` trait from pregolya-core (SS-22).
pregolya-anthropic is excluded — no embeddings API. Embedding implementations are
consumed by Context 12 (RAG / Vector Retrieval) via `Arc<dyn Embeddings>` injection
at runtime.

---

## Context 6: MCP Adapter (pregolya-mcp)

**Model:** MCPTool, MCP server connection, tool discovery protocol, untrusted ingress
boundary, MCP server endpoint (inbound tool-call dispatch, CAP-021/D19/D20).
**What it owns:** MCP client transport; runtime tool capability discovery; conversion from
MCP tool call result to `ToolMessage` (BC-2.09.002); untrusted-ingress tagging; MCP server
endpoint that exposes registered tools to external MCP clients and dispatches inbound
tool-call requests with serialized responses (CAP-021/ADR-013/D19/D20).
**What it does NOT own:** Graph scheduling; guardrail evaluation (that is Context 2/Core).
**Translation seam with Core:** MCPTool implements the Tool Runnable interface.
**Translation seam with Graph:** The `ToolMessage` content produced by MCPTool passes through `GuardrailHook` as `IngressContent::ToolResult(ContentBlock)` before entering the model context (DI-012). The seam is the tool-result content -> GuardrailHook boundary.
**Key invariants:** DI-012 (guardrail on tool-result ingress), DEC-012 (bare ToolException).

---

## Context 7: Standard Tests (pregolya-standard-tests)

**Model:** Conformance test harness, test fixtures, scoring assertions.
**What it owns:** The conformance contract definition; pass/fail criteria for provider crates.
**What it does NOT own:** Actual provider implementations (those are in Context 5).
**Translation seam with Providers:** Standard tests exercise the ChatModel Runnable
interface from pregolya-core; providers must implement that interface to pass.
**Note:** This is a dev-dependency crate; it ships as a library that provider crates
use in their test suites.

---

## Context 8: Splitters (pregolya-splitters)

**Model:** TextSplitter, chunk boundary algorithm, code-point counting.
**What it owns:** Document chunking logic; boundary correctness (code-point not byte).
**What it does NOT own:** Embedding; vector store; model invocation.
**Translation seam with Core:** Splitters accept plain UTF-8 String inputs and return Vec<String> chunk strings (BC-2.07.001/BC-2.07.002/BC-2.07.003). ContentBlock wrapping (e.g., into ContentBlock::Text or ContentBlock::PlainText) is the caller's responsibility at the use site.
**Key invariants:** R-004 (code-point parity), DEC-001, DEC-002.

---

## Context 9: Execution Sandbox (pregolya-sandbox)

**Model:** SandboxPolicy, SandboxBackend, workspace path guard, ProcessBackend,
enforcement capability contract, PolicyNotEnforceable error.
**What it owns:** WASM, container, macOS Seatbelt, and explicit process execution
backends; workspace path canonicalization (`canonicalize_beneath_root`);
`Err(E-SBXD-001)` on workspace escape; subprocess kill-on-drop timeout co-enforcement
(DI-015 — `tokio::process::Command::kill_on_drop(true)` at sandbox layer, defense-in-depth
beneath BashTool outer `tokio::time::timeout`); `PolicyNotEnforceable` error when a strict
policy is requested from a non-enforcing backend.
**What it does NOT own:** Tool trait or risk-tier annotations (Core/Graph); HITL approval
decisions (Context 2/Graph); credential management (Core).
**Translation seam with Core:** `sandbox::path_guard` raises `PregolyaError { code:
E-SBXD-001, .. }` on workspace escape; backend implementations accept an `Arc<dyn
SandboxBackend>` injected at construction.
**Translation seam with Tools:** pregolya-tools routes all file operations through
`sandbox::path_guard` (FM-019 prevention) and the sandbox backend for BashTool subprocess
execution (ADR-020; one-way dep: tools -> sandbox, no reverse dep).
**Key invariants:** DI-006 (sandbox enforcement — fail-closed `PolicyNotEnforceable` on
mismatch; ProcessBackend only via explicit `unsafe_process_no_isolation()` opt-in),
DI-007 (workspace confinement), DI-015 (subprocess timeout co-enforcement).
**Failure modes:** FM-013 (sandbox executes without enforcement).

---

## Context 10: Long-Horizon Memory (pregolya-memory)

**Model:** MemoryStore trait, SkillStore, SkillDescriptor, MemoryWriteGuard enforcement
engine, WriteGuardDecision (Allow/Deny{reason}/Transform{sanitized}), GDPR erasure protocol.
**What it owns:** KV + vector storage; skills registry overlay (SkillStore routing and
tagging over MemoryStore KV — SkillDescriptor names, load-on-demand semantics); guarded
write enforcement engine (calls `MemoryWriteGuard::validate()` from `core::write_guard`
before committing, blocks or sanitizes per WriteGuardDecision); keyword, vector, and
hybrid search. CAP-020 self-improvement execution (D20/ADR-012).
**What it does NOT own:** Embeddings implementation (Context 5/Providers); VectorStore
abstraction for RAG retrieval (Context 12 — separate capability); graph scheduling
(Context 2).
**Translation seam with Core:** MemoryStore uses the `Embeddings` trait from
`core::embeddings` for vector ops; MemoryWriteGuard trait defined in `core::write_guard`;
PregolyaError for error propagation.
**Translation seam with Graph:** `graph::scheduler` assembles ContextMutationConfig at
run start by calling MemoryStore (frozen-snapshot semantics — context loaded once before
the first super-step, preserving prompt-prefix cache stability; writes during a run are
visible at next run start only; ADR-012 Decision 3).
**Key invariants:** DI-010 (credential opacity on stored secrets), CAP-020 (guarded
writes via MemoryWriteGuard — injection scanning on the write path, not just the ingress
path).

---

## Context 11: Prompt Templates (pregolya-prompts)

**Model:** PromptTemplate, ChatPromptTemplate, MessagesPlaceholder,
FewShotPromptTemplate, SlotTrustPolicy, PromptValue, MessageProvenance, TrustLevel.
**What it owns:** f-string rendering engine (in-house, no external dep); injection safety
guard (SlotTrustPolicy x TrustLevel enforcement at render time — `E-TMPL-001` blocker for
`TrustLevel::Untrusted` in `TrustRequired` slot, pure-core, no I/O); PromptValue output
with per-message MessageProvenance.
**What it does NOT own:** Model invocation or graph orchestration; vector retrieval
(Context 12); credential handling (Core).
**Translation seam with Core:** Outputs PromptValue yielding `Vec<Message>` (pregolya-core
types) consumed by ChatModel Runnable; raises `PregolyaError { code: E-TMPL-001, .. }` on
injection-guard violation before PromptValue is produced.
**Translation seam with Graph:** Graph nodes pipe PromptValue into ChatModel Runnable calls;
injection_guard fires before any PromptValue is produced (fail-closed VP-006 Kani P1 proof
— `TrustLevel::Untrusted` in `TrustRequired` slot ALWAYS raises E-TMPL-001).
**Key invariants:** CAP-022 (strict-undefined universal — untrusted variable injection
universally blocked regardless of slot position), CAP-023 (injection-guard highest-severity
TrustLevel), FM-016 (injection-guard bypass blocked by VP-006 Kani proof).

---

## Context 12: RAG / Vector Retrieval (pregolya-vectorstores)

**Model:** VectorStore trait, VectorStoreFactory, VectorStoreRetriever, MetadataFilter,
SearchType (Similarity/SimilarityScoreThreshold/Mmr), cosine similarity primitive, MMR
selection algorithm.
**What it owns:** VectorStore abstraction; in-memory backend with `Arc<dyn Embeddings>`
injection; Maximal Marginal Relevance selection; VectorStoreRetriever (implements Retriever
trait from pregolya-core); zero-norm IEEE-754 guard in cosine similarity (E-VS-001 on
zero-magnitude input — VP-009 Kani P0 proof that NaN never enters the result set).
**What it does NOT own:** Embeddings computation (Context 5/Providers injects concrete
impl); Document type (Core); MemoryStore or skills (Context 10); GuardrailHook dispatch
(Core/Graph).
**Translation seam with Core:** VectorStoreRetriever implements Retriever trait
(`core::retriever`); `Arc<dyn Embeddings>` from `core::embeddings` injected at construction;
Document type from `core::documents`; PregolyaError for E-VS-001/E-VS-002.
**Translation seam with Providers:** Concrete Embeddings implementations from
pregolya-openai and pregolya-ollama injected at runtime via `Arc<dyn Embeddings>`
(ADR-017/D21; pregolya-anthropic excluded — no embeddings API).
**Key invariants:** FM-017 (zero-norm NaN corruption in embedding similarity — VP-009 Kani
P0 proof that `cosine_similarity` NEVER returns NaN and zero-norm input ALWAYS returns
Err(E-VS-001) before any similarity computation).

---

## Context 13: First-Party Tool Library (pregolya-tools)

**Model:** ReadFileTool, WriteFileTool, EditFileTool, ListDirTool, BashTool, GrepTool;
ActionRisk risk-tier enum; BashOutput; E-TOOLS-* error namespace (9 codes).
**What it owns:** First-party file I/O, shell execution, and text search tools; default
risk-tier annotations (ActionRisk — ReadOnly/Low/Medium/High); path-guard integration for
all filesystem access; BashTool subprocess execution via sandbox backend with minimum risk
floor Medium (VP-013 Kani P1 proof — `ToolConfig::override_risk(ActionRisk::ReadOnly)` and `ToolConfig::override_risk(ActionRisk::Low)` on a `BashTool` instance ALWAYS return `Err(E-TOOLS-007)`).
**What it does NOT own:** Sandbox policy evaluation (Context 9); HITL approval decisions
(Context 2/Graph); MCP tool discovery or protocol (Context 6).
**Translation seam with Core:** All tools implement the `Tool` trait from pregolya-core;
`#[tool]` proc-macro attribute from pregolya-macros applied at compile time;
E-TOOLS-* errors are PregolyaError variants.
**Translation seam with Sandbox:** All file tools delegate path canonicalization to
`sandbox::path_guard` (FM-019 prevention — path resolved before any I/O; E-TOOLS-001 on
escape); BashTool invokes pregolya-sandbox execution backend (WASM or container via
ADR-020; one-way dep: tools -> sandbox, no reverse dep).
**Translation seam with Graph:** Tools carry ActionRisk annotations consumed by
`graph::hitl::pre_tool_dispatch` (ADR-018 PreToolCallHook); PreToolCallHook Deny is
fail-closed (VP-011 Kani P0 proof — Deny NEVER leads to tool invocation regardless of
execution path).
**Key invariants:** DI-007 (workspace confinement per tool via sandbox::path_guard),
FM-019 (path escape blocked by E-TOOLS-001 before any I/O), VP-013 (BashTool minimum
risk floor Medium — WriteFileTool/EditFileTool default ActionRisk::High;
ReadFileTool/ListDirTool default ActionRisk::ReadOnly).

---

## Context 14: Build Macros (pregolya-macros)

**Model:** `#[tool]`, `#[entrypoint]`, `#[task]` proc-macro attributes.
**What it owns:** Compile-time code generation for Tool implementors (`#[tool]` — derives
Tool impl with JSON Schema), START-edge wiring (`#[entrypoint]` — StateGraph node), and
task registration boilerplate (`#[task]`).
**What it does NOT own:** Any runtime behavior; trait definitions (pregolya-core owns
those); graph scheduling; credential handling.
**Translation seam with Core:** pregolya-core re-exports `#[tool]`, `#[entrypoint]`,
`#[task]` so users declare `use pregolya::tool;`. pregolya-macros has NO pregolya-*
runtime dependencies — it is a proc-macro (compile-time only) dependency of pregolya-core
(ADR-008). Generated code implements traits from pregolya-core; no runtime linkage
to pregolya-macros itself.
**Note:** Proc-macro crates are compile-time build dependencies. pregolya-macros
contributes no runtime model, no invariants, and no failure modes of its own. crates that
apply `#[tool]` (e.g., pregolya-tools) list pregolya-macros as a direct proc-macro dep
in their Cargo.toml per ADR-020.
**Key anchors:** ADR-008, BC-2.08.010/011/012.

---

## Context Dependency Order

```
pregolya-macros (proc-macro; no pregolya-* runtime deps [ADR-008])
  <- pregolya-core (re-exports macros; pregolya-macros is compile-time dep only)

pregolya-core (zero pregolya-* runtime deps)
  <- pregolya-splitters
  <- pregolya-checkpoint
  <- pregolya-sandbox
  <- pregolya-memory
  <- pregolya-prompts
  <- pregolya-vectorstores
  <- pregolya-graph            (direct deps: pregolya-core + pregolya-checkpoint)
  <- pregolya-server           (direct deps: pregolya-graph + pregolya-checkpoint)
  <- pregolya-tools            (direct deps: pregolya-core + pregolya-sandbox + pregolya-macros [ADR-020 Decision 1]; NOT pregolya-graph — ActionRisk is in pregolya-core::action_risk per D-24/ADR-020 Decision 1; adding this edge violates build-position ordering and was the explicit motivation for relocating ActionRisk to core)
  <- pregolya-<provider>       (direct deps: pregolya-core + pregolya-<provider>-sdk)
  <- pregolya-mcp
  <- pregolya-standard-tests   (dev-dep)

pregolya-<provider>-sdk (standalone root; NO pregolya-core dep [D17-Q5])
  <- pregolya-<provider>
```

No circular dependencies; pregolya-macros has no pregolya-* runtime dependencies
(proc-macro compile-time only); pregolya-core has no pregolya-* runtime dependencies.
All 21 canonical crates from ARCH-INDEX Canonical Crate Roster accounted for
(pregolya facade crate and pregolya-community post-v1 crate are excluded from the DDD
bounded context model — neither carries an independent domain model).
