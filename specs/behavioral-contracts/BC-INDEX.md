---
document_type: bc-index
level: L3
version: "1.9"
status: active
producer: state-manager
timestamp: 2026-07-21T00:00:00Z
project: ferrochain
cycle: v1.0.0-greenfield
input-hash: "[live-index]"
traces_to: .factory/specs/prd.md
---

# BC-INDEX: ferrochain Behavioral Contracts

> **116 BCs total — 51 P0 / 56 P1 / 9 P2 | 11 Red Gate | 8 VP Seed | 10 VPs registered**
>
> Subsystem IDs: SS-01 through SS-17 assigned by architect at Phase 1 Step D (2026-07-14).
> SS-18 through SS-22 added D21 ecosystem-parity expansion (2026-07-20).
> All BCs reside under `specs/behavioral-contracts/ss-NN/` per ARCH-INDEX Subsystem Registry.
> VP-INDEX: 10 VPs registered (VP-001–VP-003 Kani P0, VP-004–VP-005 integration P1,
> VP-006–VP-010 pending architect authoring — seeds assigned in D21 burst).

## Summary

| Metric | Count |
|--------|-------|
| Total BCs | 116 |
| Priority P0 | 51 |
| Priority P1 | 56 |
| Priority P2 | 9 |
| Red Gate BCs | 11 |
| VP Seed BCs | 8 |
| Subsection groups | 22 (SS-2.01 – SS-2.22) |

## Red Gate BCs

| BC ID | Title | Risk Source |
|-------|-------|-------------|
| BC-2.02.003 | NamedBarrierValue Missing-Writer Boundary Behavior | R10 (upstream coverage gap) |
| BC-2.02.004 | EphemeralValue Cleared-After-Super-Step Semantics | R10 (upstream coverage gap) |
| BC-2.07.002 | Non-ASCII Boundary Parity with Python Reference Implementation | R8 (splitter code-point parity) |
| BC-2.09.004 | MCP Bare ToolException Re-Raise Preserving Type Identity | R11 (MCP upstream test void) |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections | R11 (MCP upstream test void) |
| BC-2.18.004 | injection_guard — SystemMessage Slot with Untrusted ProvenanceTag Raises E-TMPL-001 (Fail-Closed) | ADR-015 Security Invariant 1 |
| BC-2.18.005 | SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed) | ADR-015 Security Invariant 2 |
| BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate) | ADR-016 Security Invariant |
| BC-2.20.002 | BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns Entering Graph Context | ADR-014 Consequences §DI-012 |
| BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division (VP-009 Kani Candidate) | ADR-014 v1.1 Hardening Note |
| BC-2.22.002 | EmbeddingsOpenAI — OpenAiApiKey Redacted-Debug Credential Opacity (DI-010); Batch Partial-Failure as Err | DI-010 Credential Opacity |

## VP Seed BCs

| VP ID | BC ID | Title | Proof Method | NE / Security Anchor |
|-------|-------|-------|-------------|----------------------|
| VP-001 | BC-2.03.001 | BSP Super-Step Execution Determinism | Kani | NE-17 |
| VP-002 | BC-2.04.006 | Session Triple-Address Uniqueness | Kani | NE-12 |
| VP-003 | BC-2.13.004 | All Workspace File Ops Call canonicalize_beneath_root | Kani | NE-02 |
| VP-006 | BC-2.18.004 | injection_guard — SystemMessage Slot with Untrusted ProvenanceTag Raises E-TMPL-001 | Kani (candidate) | ADR-015 Security Invariant 1 |
| VP-007 | BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | Proptest | CAP-024 round-trip invariant |
| VP-008 | BC-2.22.001 | Embeddings Trait — Dimensionality Contract → E-EMBED-001; Batch Partial-Failure as Err | Proptest | CAP-031 dimensionality invariant |
| VP-009 | BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division | Kani (candidate) | ADR-014 v1.1 Hardening Note |
| VP-010 | BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed) | Kani (candidate) | ADR-016 Security Invariant |

_VP-004 and VP-005 are integration VPs (from BC-2.09.004/005); registered in VP-INDEX but not formal verification seeds. VP-006/007/008/009/010 seeds assigned burst-222 (2026-07-21); architect to author VP body files in Phase 6._

## Full BC Catalog

| BC ID | Title | Cap | NE Anchors | DI Anchors | Pri | RG | VP | File |
|-------|-------|-----|-----------|-----------|-----|----|----|------|
| BC-2.01.001 | Typed ContentBlock Sequence Construction (No Raw Content Where Typed Expected) | CAP-001 | | DI-008 | P0 | | | ss-01/BC-2.01.001.md |
| BC-2.01.002 | Message Type-Safety (AiMessage / HumanMessage / SystemMessage / ToolMessage) | CAP-001 | | DI-008 | P0 | | | ss-01/BC-2.01.002.md |
| BC-2.01.003 | Runnable Trait Invocation — invoke, stream, batch | CAP-002 | | | P0 | | | ss-01/BC-2.01.003.md |
| BC-2.01.004 | Runnable Pipe Composition (A.pipe(B) = AB Chain) | CAP-002 | | | P0 | | | ss-01/BC-2.01.004.md |
| BC-2.02.001 | StateGraph Node Definition with Typed Channel Assignment | CAP-003 | | | P0 | | | ss-02/BC-2.02.001.md |
| BC-2.02.002 | LastValue / Append / BarrierValue Channel Semantics and Reducer Wiring | CAP-003 | | DI-001 | P0 | | | ss-02/BC-2.02.002.md |
| BC-2.02.003 | NamedBarrierValue Missing-Writer Boundary Behavior (Red Gate — R10) | CAP-003 | | | P0 | **RG** | | ss-02/BC-2.02.003.md |
| BC-2.02.004 | EphemeralValue Cleared-After-Super-Step Semantics (Red Gate — R10) | CAP-003 | | | P0 | **RG** | | ss-02/BC-2.02.004.md |
| BC-2.02.005 | Conditional Edge Routing Function | CAP-003 | | | P0 | | | ss-02/BC-2.02.005.md |
| BC-2.02.006 | Send API Dynamic Fan-Out | CAP-003 | | | P0 | | | ss-02/BC-2.02.006.md |
| BC-2.03.001 | BSP Super-Step Execution Determinism — Kani VP Seed (NE-17) | CAP-004 | NE-17 | DI-001 | P0 | | **VP** | ss-03/BC-2.03.001.md |
| BC-2.03.002 | Concurrent LastValue Write Rejection Raises InvalidUpdateError | CAP-004 | | DI-001 | P0 | | | ss-03/BC-2.03.002.md |
| BC-2.03.003 | Deterministic Reducer Application Order (Task-Identity Sort) | CAP-004 | NE-17 | DI-001 | P0 | | | ss-03/BC-2.03.003.md |
| BC-2.04.001 | Per-Task put_writes Completes Before Next Super-Step Begins | CAP-005 | | DI-002 | P0 | | | ss-04/BC-2.04.001.md |
| BC-2.04.002 | Sync Durability Tier Is Default; Async and Exit Are Explicit Opt-In | CAP-005 | | DI-002 | P0 | | | ss-04/BC-2.04.002.md |
| BC-2.04.003 | Monotonic Logical-Clock Checkpoint IDs — Wall-Clock UUIDs Rejected | CAP-005 | | DI-004 | P0 | | | ss-04/BC-2.04.003.md |
| BC-2.04.004 | Fork Lineage via parent_checkpoint_id Pointers; No State Copy on Fork | CAP-005 | | DI-004 | P0 | | | ss-04/BC-2.04.004.md |
| BC-2.04.005 | Crash Recovery — Completed Tasks Not Re-Executed After Process Restart | CAP-005 | | DI-002 | P0 | | | ss-04/BC-2.04.005.md |
| BC-2.04.006 | Session Triple-Address Uniqueness (thread_id, checkpoint_ns, checkpoint_id) — Kani VP Seed | CAP-005 | NE-12 | DI-005 | P0 | | **VP** | ss-04/BC-2.04.006.md |
| BC-2.04.007 | Encryption at Rest Covers Both State AND Event Payloads; Rotation Errors Propagate | CAP-005 | NE-11 | | P0 | | | ss-04/BC-2.04.007.md |
| BC-2.04.008 | FTS Conversation Search Over Checkpoint History (Single-Process; SQLite FTS5) | CAP-005 | | DI-002,DI-008,DI-014 | P1 | | | ss-04/BC-2.04.008.md |
| BC-2.05.001 | Interrupt Suspension with Durable State Persistence | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.001.md |
| BC-2.05.002 | FIFO Resume-Value Delivery Order | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.002.md |
| BC-2.05.003 | Interrupted Node Re-Executes from Start of Super-Step on Resume | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.003.md |
| BC-2.05.004 | Command(resume=value) API Contract for Programmatic Resume | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.004.md |
| BC-2.05.005 | Resume on Empty Interrupt Queue Returns Err(NoActiveInterrupt) | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.005.md |
| BC-2.05.006 | Risk-Tiered Interrupt Classification (Typed Action-Risk Levels for Domain A SOC) | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.006.md |
| BC-2.06.001 | Typed Per-Phase Event Taxonomy (run/step/node/tool start-stream-end; guardrail_decision) | CAP-007 | | DI-011 | P0 | | | ss-06/BC-2.06.001.md |
| BC-2.06.002 | run_id + parent_ids Correlation Across All Streaming Events | CAP-007 | | | P0 | | | ss-06/BC-2.06.002.md |
| BC-2.06.003 | Streaming and Unary Run Produce Identical Final Answer (NE-13) | CAP-007 | NE-13 | DI-011 | P0 | | | ss-06/BC-2.06.003.md |
| BC-2.07.001 | Chunk Boundaries Are Unicode Code-Point Counts (Not Bytes) | CAP-008 | | | P0 | | | ss-07/BC-2.07.001.md |
| BC-2.07.002 | Non-ASCII Boundary Parity with Python Reference Implementation (Emoji, CJK) — R8 Red Gate | CAP-008 | | | P0 | **RG** | | ss-07/BC-2.07.002.md |
| BC-2.07.003 | Short Document (length < chunk_size) — Single Chunk, No Overlap, No Panic | CAP-008 | | | P0 | | | ss-07/BC-2.07.003.md |
| BC-2.08.001 | Chat Model Streaming Completions Conformance | CAP-009 | | DI-011 | P1 | | | ss-08/BC-2.08.001.md |
| BC-2.08.002 | Chat Model Tool-Call Round-Trip Conformance | CAP-009 | | | P1 | | | ss-08/BC-2.08.002.md |
| BC-2.08.003 | Chat Model Structured Output Conformance | CAP-009 | | | P1 | | | ss-08/BC-2.08.003.md |
| BC-2.08.004 | Chat Model Error-Type Fidelity Conformance | CAP-009 | | DI-014 | P1 | | | ss-08/BC-2.08.004.md |
| BC-2.08.005 | Chat Model Token-Usage Accounting Conformance | CAP-009 | | | P1 | | | ss-08/BC-2.08.005.md |
| BC-2.08.006 | Standalone SDK Crate Split Architecture (ferrochain-\<provider\>-sdk + Adapter) | CAP-009 | | DI-008 | P1 | | | ss-08/BC-2.08.006.md |
| BC-2.08.007 | Provider Streaming Interrupted by Transport Error Surfaces Err(Timeout) or Err(Transport), Not Truncated Success | CAP-009 | | DI-009,DI-014 | P1 | | | ss-08/BC-2.08.007.md |
| BC-2.08.008 | Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome (NE-15) | CAP-011 | NE-15 | | P1 | | | ss-08/BC-2.08.008.md |
| BC-2.08.009 | Tool Schema Naming Stability (Snapshot Test Anchor) | CAP-009 | | | P1 | | | ss-08/BC-2.08.009.md |
| BC-2.08.010 | `#[tool]` Attribute Macro — async fn to Tool Implementor via schemars::JsonSchema | CAP-002 | | DI-008 | P1 | | | ss-08/BC-2.08.010.md |
| BC-2.08.011 | `#[entrypoint]` Attribute Macro — START Edge Auto-Wiring for StateGraph | CAP-003 | | | P1 | | | ss-08/BC-2.08.011.md |
| BC-2.08.012 | `#[task]` Attribute Macro — Task Registration Boilerplate Generation | CAP-003 | | | P1 | | | ss-08/BC-2.08.012.md |
| BC-2.08.013 | Pluggable Tool-Call Dialect Seam (ToolCallDialect; Hermes ChatML XML) | CAP-009 | | DI-008,DI-014 | P1 | | | ss-08/BC-2.08.013.md |
| BC-2.08.014 | Provider Failover Chain (ProviderFallbackPolicy; Ordered Fallback on 429/5xx/Auth) | CAP-009 | | DI-008,DI-009,DI-010,DI-014 | P1 | | | ss-08/BC-2.08.014.md |
| BC-2.09.001 | MCP Server Tool Discovery and Registration at Runtime | CAP-010 | | | P1 | | | ss-09/BC-2.09.001.md |
| BC-2.09.002 | ToolInvocation Routing to Correct MCP Server Transport | CAP-010 | | | P1 | | | ss-09/BC-2.09.002.md |
| BC-2.09.003 | Tool-Result Content Treated as Untrusted Ingress (DI-012 Applies) | CAP-010 | | DI-012 | P1 | | | ss-09/BC-2.09.003.md |
| BC-2.09.004 | MCP Bare ToolException Re-Raise Preserving Type Identity (Red Gate — R11) | CAP-010 | | DI-014 | P1 | **RG** | | ss-09/BC-2.09.004.md |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections (Red Gate — R11) | CAP-010 | | DI-014 | P1 | **RG** | | ss-09/BC-2.09.005.md |
| BC-2.09.006 | MCP Server Tool Advertisement (tools/list; mcp::server) | CAP-021 | | DI-008,DI-014 | P1 | | | ss-09/BC-2.09.006.md |
| BC-2.09.007 | MCP Server Tool Invocation (tools/call; External Client Executes Registered Tool) | CAP-021 | | DI-008,DI-010,DI-014 | P1 | | | ss-09/BC-2.09.007.md |
| BC-2.10.001 | BudgetPolicy allow/escalate/deny Evaluation per Run and per Sub-Agent | CAP-012 | | | P0 | | | ss-10/BC-2.10.001.md |
| BC-2.10.002 | Append-Only EvidenceJournal Records Every Budget Evaluation | CAP-012 | | | P0 | | | ss-10/BC-2.10.002.md |
| BC-2.10.003 | Graceful Halt When Budget Ceiling Reached (on_ceiling = halt \| summarize); Remaining-Budget Exposure | CAP-012 | | | P0 | | | ss-10/BC-2.10.003.md |
| BC-2.10.004 | Budget Escalation to HITL Interrupt (Soft-Limit Escalate Path and Hard-Ceiling on_ceiling=Escalate Path) | CAP-012 | | DI-003 | P0 | | | ss-10/BC-2.10.004.md |
| BC-2.11.001 | ProvenanceTag Attached at Every Ingress Boundary (Tool-Result, RAG, Memory) | CAP-013 | | DI-012 | P0 | | | ss-11/BC-2.11.001.md |
| BC-2.11.002 | GuardrailHook Fires Unconditionally at Tool-Result Ingress | CAP-013 | NE-06 | DI-012 | P0 | | | ss-11/BC-2.11.002.md |
| BC-2.11.003 | GuardrailHook Fires at RAG Ingress | CAP-013 | NE-06 | DI-012 | P0 | | | ss-11/BC-2.11.003.md |
| BC-2.11.004 | GuardrailHook Fires at Memory Ingress | CAP-013 | NE-06 | DI-012 | P0 | | | ss-11/BC-2.11.004.md |
| BC-2.11.005 | Rejected Content Does Not Enter Model Context Under Any Code Path | CAP-013 | | DI-012 | P0 | | | ss-11/BC-2.11.005.md |
| BC-2.11.006 | No-Hook Default — Content Passes Through with WARNING LOG (Default-Permit) | CAP-013 | | DI-012 | P0 | | | ss-11/BC-2.11.006.md |
| BC-2.12.001 | Thread Resource CRUD (Create, Read, List, Delete Durable Conversation History) | CAP-014 | | | P1 | | | ss-12/BC-2.12.001.md |
| BC-2.12.002 | Assistant Resource CRUD (Named Agent Config with Graph Reference) | CAP-014 | | | P1 | | | ss-12/BC-2.12.002.md |
| BC-2.12.003 | Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable) | CAP-014 | | | P1 | | | ss-12/BC-2.12.003.md |
| BC-2.12.004 | CronSchedule Creation and Proactive Run Execution | CAP-014 | | | P1 | | | ss-12/BC-2.12.004.md |
| BC-2.12.005 | SecurityConfig::default() Denies CORS; Debug Route Gated on Explicit Opt-In Key (NE-14) | CAP-014 | NE-14 | DI-013 | P1 | | | ss-12/BC-2.12.005.md |
| BC-2.12.006 | IdempotencyStore / RateLimitStore / RunStore Trait Seams with Durable Backends (NE-08) | CAP-014 | NE-08 | | P1 | | | ss-12/BC-2.12.006.md |
| BC-2.12.007 | Streaming Endpoint and Unary Endpoint Drive Same Graph Engine, Same Final Answer | CAP-014 | NE-13 | DI-011 | P1 | | | ss-12/BC-2.12.007.md |
| BC-2.13.001 | Enforcing Sandbox Backend (WASM or Container) Is Default (NE-01) | CAP-015 | NE-01 | DI-006 | P1 | | | ss-13/BC-2.13.001.md |
| BC-2.13.002 | Process Backend Requires Explicit Opt-In and Emits Loud Runtime Warning | CAP-015 | | DI-006 | P1 | | | ss-13/BC-2.13.002.md |
| BC-2.13.003 | Strict Policy + Non-Enforcing Backend Returns Err(PolicyNotEnforceable) | CAP-015 | | DI-006 | P1 | | | ss-13/BC-2.13.003.md |
| BC-2.13.004 | All Workspace File Ops Call canonicalize_beneath_root at Access Time (NE-02) — Kani VP Seed | CAP-015 | NE-02 | DI-007 | P1 | | **VP** | ss-13/BC-2.13.004.md |
| BC-2.13.005 | Symlink That Escapes Workspace Root Returns Err(WorkspaceEscape) | CAP-015 | NE-02 | DI-007 | P1 | | | ss-13/BC-2.13.005.md |
| BC-2.13.006 | macOS Seatbelt Profile: Deny-by-Default with Explicit Allow Rules (NE-16) | CAP-015 | NE-16 | DI-006 | P1 | | | ss-13/BC-2.13.006.md |
| BC-2.13.007 | Environment Variable Sanitization at Sandbox Execution Boundary | CAP-015 | | DI-006,DI-008,DI-010 | P1 | | | ss-13/BC-2.13.007.md |
| BC-2.14.001 | FerrochainError 2D Component × Category Struct with RetryHint and Machine Code | CAP-016 | | DI-008,DI-014 | P0 | | | ss-14/BC-2.14.001.md |
| BC-2.14.002 | RFC-7807 Compatible Problem Emission from FerrochainError | CAP-016 | | | P0 | | | ss-14/BC-2.14.002.md |
| BC-2.14.003 | All Library Constructors Return Result; No .unwrap()/.expect()/assert! in Non-Test Code | CAP-016 | NE-07 | DI-008 | P0 | | | ss-14/BC-2.14.003.md |
| BC-2.14.004 | Every Outbound HTTP ClientBuilder Must Set .timeout(30s); Zero Client::new() Outside Tests | CAP-016 | NE-04 | DI-009 | P0 | | | ss-14/BC-2.14.004.md |
| BC-2.14.005 | API Key Newtype with Redacted Debug; No Serialize; No Deref\<Target=str\> | CAP-016 | NE-10 | DI-010 | P0 | | | ss-14/BC-2.14.005.md |
| BC-2.14.006 | Validation Failures Propagate Err(FerrochainError); No Silent None | CAP-016 | NE-03 | DI-014 | P0 | | | ss-14/BC-2.14.006.md |
| BC-2.15.001 | KV and Vector Memory Persistence Across Threads (Not Per-Checkpoint) | CAP-017 | | | P2 | | | ss-15/BC-2.15.001.md |
| BC-2.15.002 | User/App/Session Tier Isolation — User-Private Does Not Bleed Across Scopes | CAP-017 | | | P2 | | | ss-15/BC-2.15.002.md |
| BC-2.15.003 | GDPR Erasure Removes All Traces from All Memory Tiers | CAP-017 | | | P2 | | | ss-15/BC-2.15.003.md |
| BC-2.15.004 | SkillStore Registry — Load-on-Demand Skill Documents | CAP-020 | | DI-008,DI-014 | P1 | | | ss-15/BC-2.15.004.md |
| BC-2.15.005 | Guarded Memory and Skill Writes (MemoryWriteGuard; E-MEMORY-007) | CAP-020 | | DI-008,DI-012,DI-014 | P1 | | | ss-15/BC-2.15.005.md |
| BC-2.15.006 | Frozen-Snapshot Context Mutation — Memory-Sourced System-Prompt Content | CAP-020 | | DI-002,DI-008,DI-014 | P1 | | | ss-15/BC-2.15.006.md |
| BC-2.16.001 | Per-Tool Retry Policy Keyed by tool_name (Not Args Hash) | CAP-018 | NE-09 | | P2 | | | ss-16/BC-2.16.001.md |
| BC-2.16.002 | Finite global_limit Non-None Default for All Retry Policies | CAP-018 | NE-09 | | P2 | | | ss-16/BC-2.16.002.md |
| BC-2.16.003 | Circuit Breaker Trips After Repeated Failure; Prevents Infinite Retry | CAP-018 | NE-09 | | P2 | | | ss-16/BC-2.16.003.md |
| BC-2.17.001 | Kani Harness Scope — BSP Determinism VP + Session Tenancy VP + Workspace Confinement VP | CAP-019 | | DI-001,DI-005,DI-007 | P2 | | | ss-17/BC-2.17.001.md |
| BC-2.17.002 | cargo-fuzz Targets — Serialization Round-Trip (Checkpoint) and Graph-Execution Paths | CAP-019 | | | P2 | | | ss-17/BC-2.17.002.md |
| BC-2.18.001 | PromptTemplate F-String Rendering, Partial Binding, Variable Detection, and Strict-Undefined Guard | CAP-022 | | DI-008,DI-014 | P1 | | | ss-18/BC-2.18.001.md |
| BC-2.18.002 | ChatPromptTemplate Multi-Message Rendering with PromptValue and Per-Message MessageProvenance | CAP-022 | | DI-008 | P1 | | | ss-18/BC-2.18.002.md |
| BC-2.18.003 | MessagesPlaceholder Vec\<Message\> In-Place Expansion and FewShotPromptTemplate Few-Shot Composition | CAP-023 | | DI-008 | P1 | | | ss-18/BC-2.18.003.md |
| BC-2.18.004 | injection_guard — SystemMessage Slot with Untrusted ProvenanceTag Raises E-TMPL-001 (Fail-Closed at Render Time) | CAP-022 | | DI-008,DI-014 | P1 | **RG** | **VP-006** | ss-18/BC-2.18.004.md |
| BC-2.18.005 | SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed) | CAP-022 | | DI-008,DI-014 | P1 | **RG** | | ss-18/BC-2.18.005.md |
| BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | CAP-024 | | DI-008 | P1 | | **VP-007** | ss-19/BC-2.19.001.md |
| BC-2.19.002 | lc_secrets() Credential Fields Stripped from kwargs Before Serialization and Constructor Dispatch | CAP-024 | | DI-008,DI-010 | P1 | | | ss-19/BC-2.19.002.md |
| BC-2.19.003 | Inventory-Based Type Registry — Link-Time Registration, Feature-Gated Partner Entries, OnceLock Allowlist | CAP-025 | | DI-008 | P1 | | | ss-19/BC-2.19.003.md |
| BC-2.19.004 | Legacy Namespace Remap — OLD_CORE_NAMESPACES_MAPPING Aliases Resolve to Canonical Constructors | CAP-025 | | DI-008 | P2 | | | ss-19/BC-2.19.004.md |
| BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate) | CAP-025 | | DI-008,DI-014 | P0 | **RG** | **VP-010** | ss-19/BC-2.19.005.md |
| BC-2.19.006 | Langchain-Monolith Type Ids Return E-SRLZ-002 (Structured Error, Not Silent None or E-SRLZ-001) | CAP-025 | | DI-008,DI-014 | P1 | | | ss-19/BC-2.19.006.md |
| BC-2.20.001 | Retriever Trait — get_relevant_documents Async Dyn-Compatible; Document Carrier Type; Arc\<dyn Retriever\> Graph Seam | CAP-026 | | DI-008,DI-012,DI-014 | P1 | | | ss-20/BC-2.20.001.md |
| BC-2.20.002 | BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns Entering Graph Context (DI-012 Coverage Obligation) | CAP-026 | | DI-012,DI-014 | P0 | **RG** | | ss-20/BC-2.20.002.md |
| BC-2.20.003 | VectorStoreRetriever — SearchType Enum (Similarity \| SimilarityScoreThreshold \| Mmr); k / fetch_k / lambda_mult Configuration; Constructed via as_retriever() | CAP-027 | | DI-008 | P1 | | | ss-20/BC-2.20.003.md |
| BC-2.21.001 | VectorStore Trait — Instance-Method Surface; VectorStoreFactory Sized-Bounded Separation; Arc\<dyn VectorStore\> Dyn-Safety | CAP-028 | | DI-008 | P1 | | | ss-21/BC-2.21.001.md |
| BC-2.21.002 | InMemoryVectorStore — Arc\<dyn Embeddings\> DI; RwLock Interior Mutability; Vec\<f32\> Cosine; VectorStoreFactory Constructor | CAP-029 | | DI-008 | P1 | | | ss-21/BC-2.21.002.md |
| BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division (VP-009 Kani Candidate) | CAP-029 | | DI-008,DI-014 | P0 | **RG** | **VP-009** | ss-21/BC-2.21.003.md |
| BC-2.21.004 | MetadataFilter — Eq / Ne / In FilterClause; Additive similarity_search_with_filter; Native Pre-Filter vs InMemoryVectorStore Post-Filter; #[non_exhaustive] | CAP-030 | | DI-008,DI-014 | P1 | | | ss-21/BC-2.21.004.md |
| BC-2.22.001 | Embeddings Trait — embed_documents Batch; embed_query; Dimensionality Contract → E-EMBED-001; Batch Partial-Failure as Err; Arc\<dyn Embeddings\> Dyn-Safe (VP-008 Proptest Seed) | CAP-031 | | DI-008,DI-014 | P1 | | **VP-008** | ss-22/BC-2.22.001.md |
| BC-2.22.002 | EmbeddingsOpenAI — text-embedding-3-small/large/ada-002-legacy; OpenAiApiKey Redacted-Debug Credential Opacity (DI-010); reqwest/rustls-tls/.timeout(30s); Batch Partial-Failure as Err | CAP-032 | | DI-008,DI-009,DI-010,DI-014 | P1 | **RG** | | ss-22/BC-2.22.002.md |
| BC-2.22.003 | EmbeddingsOllama — No API Key; POST /api/embed Preferred; use_legacy_endpoint Toggle for /api/embeddings; reqwest/rustls-tls/.timeout(30s) Unconditional | CAP-033 | | DI-008,DI-009,DI-014 | P1 | | | ss-22/BC-2.22.003.md |

## Carry-Forward Notes (RESOLVED at Phase 1 Step D, 2026-07-14)

1. **SS-TBD backfill** — RESOLVED. All 95 BCs now have `subsystem: SS-NN`. BC files moved to `ss-NN/` dirs per artifact-path-registry. ARCH-INDEX Subsystem Registry is authoritative.
2. **VP-INDEX registration** — RESOLVED. VP-001..VP-003 (Kani) + VP-004..VP-005 (integration, from BC-2.09.004/005) registered in VP-INDEX.md.
3. **vp_seed frontmatter inconsistency** — RESOLVED. BC-2.03.001: `vp_seed: true, vp_id: VP-001`. BC-2.04.006: normalized `kani_vp_seed` → `vp_seed: true, vp_id: VP-002`. BC-2.13.004: `vp_seed: true, vp_id: VP-003`.
4. **red_gate_required vs red_gate** — RESOLVED. BC-2.07.002: `red_gate_required: true` → `red_gate: true, red_gate_source: R8`.
5. **Proc-macro BCs (Phase-1b)** — ADDED. BC-2.08.010/011/012 authored from ADR-004 + ADR-008 acceptance (D5 gate resolved). Batch 13 in bc-authoring-plan.md. Total: 83 → 86 BCs; P1 count: 27 → 30 (later grown to 95 via D20).
6. **SS-15 wave drift (ADV-P1D-PASS-3 F-P3-06)** — RESOLVED. BC-2.15.001/002/003 frontmatter `wave: post-v1` → `wave: 2`; Traceability rows updated to `Wave 2`. Aligns with ARCH-INDEX §Canonical Crate Roster (ferrochain-memory assigned wave 2).
7. **SS-16 wave drift (ADV-P1D-PASS-4 F-P4-03)** — RESOLVED. BC-2.16.001/002/003 frontmatter `wave: Post-v1` → `wave: 2`; Traceability rows updated to `Wave 2`. Stale Note rows (E-RETRY-001/002/003 "requires addition to error-taxonomy") removed — all three codes were already in RETRY component. Aligns with ARCH-INDEX §Canonical Crate Roster (SS-16 assigned wave 2).

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.9 | 2026-07-21 | F-P130 fix burst 225: DI column updates — (1) BC-2.20.001: DI-008,DI-012 → DI-008,DI-012,DI-014 (F-P130-04). (2) BC-2.20.002: DI-012 → DI-012,DI-014 (F-P130-02/04). (3) BC-2.21.004: DI-008 → DI-008,DI-014 (F-P130-04). (4) BC-2.22.002: DI-008,DI-010,DI-014 → DI-008,DI-009,DI-010,DI-014 (F-P130-09). (5) BC-2.22.003: DI-008,DI-014 → DI-008,DI-009,DI-014 (F-P130-09). | F-P130 burst-225 |
| 1.8 | 2026-07-21 | D21 spec-body layer complete (burst 222): header 95→116 BCs; P0 48→51, P1 39→56, P2 8→9; Red Gate 5→11 (+BC-2.18.004/005, BC-2.19.005, BC-2.20.002, BC-2.21.003, BC-2.22.002); VP Seed 3→8 (+VP-006→BC-2.18.004, VP-007→BC-2.19.001, VP-008→BC-2.22.001, VP-009→BC-2.21.003, VP-010→BC-2.19.005); VP-INDEX 5→10; subsection groups 17→22; Full Catalog +21 rows (SS-18..22); VP Seed table restructured with VP ID column. BC-2.19.001 v1.0→v1.1 (VP-007 seed assigned). | D21 burst-222 |
| 1.7 | 2026-07-20 | D21 ecosystem-parity expansion: 21 BC files authored (SS-18..22); frontmatter/changelog updated in prd.md + BC-INDEX.md. Body incomplete (this entry). | D21 burst-216 |
| 1.6 | 2026-07-19 | F-P114-01 fix burst 117: Architecture Anchor fields corrected in BC-2.04.001–007 (7 files) — replaced nonexistent `architecture/ferrochain-checkpoint.md` citation with adjudicated real targets per architect guidance. Per-file versions: BC-2.04.001 v1.3, BC-2.04.002 v1.4, BC-2.04.003 v1.4, BC-2.04.004 v1.3, BC-2.04.005 v1.3, BC-2.04.006 v1.5, BC-2.04.007 v1.7. No BC body content changed. | F-P114-01 fix burst 117 |
| 1.5 | 2026-07-17 | F-P94-01: BC-2.10.003 index row trailing italic `_(v1.2: adds OnCeiling::Summarize + RunContext.budget_info / BudgetInfo)_` removed — title now byte-exact match to H1 in ss-10/BC-2.10.003.md. | F-P94-01 |
| 1.4 | 2026-07-15 | OBS-P74-B: Carry-Forward Note #5 appended "(later grown to 95 via D20)" for parallelism with prd OQR-4 clarifier convention. | OBS-P74-B |
| 1.3 | 2026-07-15 | F-P73-02: Carry-Forward Note #1 updated "All 86 BCs" → "All 95 BCs" (9 D20 BCs verified to carry `subsystem: SS-NN` frontmatter); version and timestamp bumped. | F-P73-02 |
| 1.2 | 2026-07-15 | D20 INTEGRATE sub-burst 2: 9 D20 BCs registered (86→95 total); header, Summary table, and section tables updated. | D20 sub-burst 2 |
| 1.1 | 2026-07-14 | Phase 1 Step D SS-NN backfill: all BCs moved to `ss-NN/` subdirectories; subsystem IDs assigned from ARCH-INDEX; carry-forward notes updated. | Phase 1 Step D |
| 1.0 | 2026-07-13 | Initial authoring. | Greenfield Phase 1a |
