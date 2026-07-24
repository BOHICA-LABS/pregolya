---
document_type: bc-index
level: L3
version: "2.8"
status: active
producer: state-manager
timestamp: 2026-07-22T12:00:00Z
project: ferrochain
cycle: v1.0.0-greenfield
input-hash: "[live-index]"
traces_to: .factory/specs/prd.md
changelog:
  - "2.8 (F-P142-03, burst-242, 2026-07-23): BC-2.05.008 and BC-2.06.005 titles updated to match new H1s (bc_h1_is_title_source_of_truth): Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority."
  - "2.7 (burst-241/Wave-2/F-P141-02/2026-07-23): BC-2.17.001 title updated to match new H1 (bc_h1_is_title_source_of_truth): 'Kani Harness Scope — BSP Determinism VP + Session Tenancy VP + Workspace Confinement VP' → 'Six P0 Kani VP Obligations + Three P1 Kani VP Obligations'. DI column +DI-014."
  - "2.6 (burst-239/F-P139/2026-07-22): BC-2.06.001 title updated to match current H1 (H1 is source of truth per bc_h1_is_title_source_of_truth policy — drift from D23 v1.5 update not swept to index). No BC count changes. BCs modified this burst: BC-2.04.001 v1.4 (+Inv-5 append-only), BC-2.10.006 v1.4 (citation fix), BC-2.06.001 v1.6 (PC2 type + Description), BC-2.07.003 v1.3 (PC5), BC-2.07.001 v1.3 (TV-005), BC-2.05.008 v1.1 (Related BCs + EC-006)."
  - "2.5 (burst-238/sweep/2026-07-23): Update VP-INDEX status note — 'VP-006–VP-010 pending architect authoring' was stale; VP-INDEX v1.2 (burst-223) registered VP-006–010 and VP-006.md–VP-010.md all exist. Note updated to reflect completed state."
---

# BC-INDEX: ferrochain Behavioral Contracts

> **129 BCs total — 51 P0 / 75 P1 / 3 P2 | 11 Red Gate | 11 VP Seed | 13 VPs registered**
>
> Subsystem IDs: SS-01 through SS-17 assigned by architect at Phase 1 Step D (2026-07-14).
> SS-18 through SS-22 added D21 ecosystem-parity expansion (2026-07-20).
> SS-23 (First-Party Tools) added D23 first-class approval hook + compaction expansion (2026-07-22).
> All BCs reside under `specs/behavioral-contracts/ss-NN/` per ARCH-INDEX Subsystem Registry.
> VP-INDEX: 13 VPs registered (VP-001–VP-003 Kani P0, VP-004–VP-005 integration P1,
> VP-006–VP-010 assigned VP-INDEX v1.2 (burst-223, 2026-07-21) and authored — VP-006.md–VP-010.md all complete;
> VP-011–VP-013 seeds assigned D23 burst-232 and authored — VP-011.md–VP-013.md all complete).

## Summary

| Metric | Count |
|--------|-------|
| Total BCs | 129 |
| Priority P0 | 51 |
| Priority P1 | 75 |
| Priority P2 | 3 |
| Red Gate BCs | 11 |
| VP Seed BCs | 11 |
| Subsection groups | 23 (SS-2.01 – SS-2.23) |

## Red Gate BCs

| BC ID | Title | Risk Source |
|-------|-------|-------------|
| BC-2.02.003 | NamedBarrierValue Missing-Writer Boundary Behavior | R10 (upstream coverage gap) |
| BC-2.02.004 | EphemeralValue Cleared-After-Super-Step Semantics | R10 (upstream coverage gap) |
| BC-2.07.002 | Non-ASCII Boundary Parity with Python Reference Implementation | R8 (splitter code-point parity) |
| BC-2.09.004 | MCP Bare ToolException Re-Raise Preserving Type Identity | R11 (MCP upstream test void) |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections | R11 (MCP upstream test void) |
| BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time) | ADR-015 Security Invariant 1 |
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
| VP-006 | BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 | Kani (candidate) | ADR-015 Security Invariant 1 |
| VP-007 | BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | Proptest | CAP-024 round-trip invariant |
| VP-008 | BC-2.22.001 | Embeddings Trait — Dimensionality Contract → E-EMBED-001; Batch Partial-Failure as Err | Proptest | CAP-031 dimensionality invariant |
| VP-009 | BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division | Kani (candidate) | ADR-014 v1.1 Hardening Note |
| VP-010 | BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed) | Kani (candidate) | ADR-016 Security Invariant |
| VP-011 | BC-2.05.007 | PreToolCallHook Dispatch — pre_invoke Contract; Approve/Deny/Edit/PendingHumanApproval; Fail-Closed Deny | Kani (candidate) | ADR-018 Decision 1 |
| VP-012 | BC-2.10.005 | CompactionTrigger Configuration — Disabled/OnWatermark/OnMessageCount/OnTokenCount; Watermark Arithmetic | Kani (candidate) | ADR-019 Decision 3 |
| VP-013 | BC-2.23.005 | BashTool — Non-Lowerable Medium Risk Floor; Sandboxed Shell Execution | Kani (candidate) | ADR-020 Decision 3 |

_VP-004 and VP-005 are integration VPs (from BC-2.09.004/005); registered in VP-INDEX but not formal verification seeds. VP-006/007/008/009/010 seeds assigned burst-222 (2026-07-21); VP-011/012/013 seeds assigned burst-231 (2026-07-22); architect to author VP body files in Phase 6._

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
| BC-2.05.007 | PreToolCallHook Dispatch — pre_invoke Contract; Approve/Deny/Edit/PendingHumanApproval; Fail-Closed Deny (VP-011 Kani Seed) | CAP-034 | | DI-014 | P1 | | **VP** | ss-05/BC-2.05.007.md |
| BC-2.05.008 | Skip-Hook-on-Resume Invariant — ToolApprovalRequest Checkpoint Persistence; Command(resume=PreToolDecision); No Re-Invocation of pre_invoke | CAP-034 | | DI-014 | P1 | | | ss-05/BC-2.05.008.md |
| BC-2.06.001 | Typed Per-Phase Event Taxonomy (run/step/node/tool start-stream-end; guardrail_decision; tool_approval_request/resolved; compaction_event) — 15 Variants | CAP-007 | | DI-011 | P0 | | | ss-06/BC-2.06.001.md |
| BC-2.06.002 | run_id + parent_ids Correlation Across All Streaming Events | CAP-007 | | | P0 | | | ss-06/BC-2.06.002.md |
| BC-2.06.003 | Streaming and Unary Run Produce Identical Final Answer (NE-13) | CAP-007 | NE-13 | DI-011 | P0 | | | ss-06/BC-2.06.003.md |
| BC-2.06.004 | `tool_approval_request` StreamEvent (Event 13) — Payload; Emission Timing; Causal Ordering Before Interrupt | CAP-034 | | DI-014 | P1 | | | ss-06/BC-2.06.004.md |
| BC-2.06.005 | `tool_approval_resolved` StreamEvent (Event 14) — Payload; Emission on Command(resume=…); Decision Outcome | CAP-034 | | DI-014 | P1 | | | ss-06/BC-2.06.005.md |
| BC-2.06.006 | `compaction_event` StreamEvent (Event 15) — Payload; Emission After Compaction Completes; Trigger Variant | CAP-035 | | DI-014 | P1 | | | ss-06/BC-2.06.006.md |
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
| BC-2.10.005 | CompactionTrigger Configuration — Disabled/OnWatermark/OnMessageCount/OnTokenCount; BudgetConfig Extension; Watermark Arithmetic (VP-012 Kani Seed) | CAP-035 | | DI-014 | P1 | | **VP** | ss-10/BC-2.10.005.md |
| BC-2.10.006 | Compaction Execution — ConversationSnapshot from FTS; Mid-Run Window REPLACEMENT; CompactionEvent → EvidenceJournal; Checkpoint Immutability; DefaultSummarizationPolicy | CAP-035 | | DI-014 | P1 | | | ss-10/BC-2.10.006.md |
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
| BC-2.13.002 | Process Backend Requires Explicit Opt-In and Emits Loud Runtime Warning | CAP-015 | | DI-006,DI-015 | P1 | | | ss-13/BC-2.13.002.md |
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
| BC-2.15.001 | KV and Vector Memory Persistence Across Threads (Not Per-Checkpoint) | CAP-017 | | | P1 | | | ss-15/BC-2.15.001.md |
| BC-2.15.002 | User/App/Session Tier Isolation — User-Private Does Not Bleed Across Scopes | CAP-017 | | | P1 | | | ss-15/BC-2.15.002.md |
| BC-2.15.003 | GDPR Erasure Removes All Traces from All Memory Tiers | CAP-017 | | | P1 | | | ss-15/BC-2.15.003.md |
| BC-2.15.004 | SkillStore Registry — Load-on-Demand Skill Documents | CAP-020 | | DI-008,DI-014 | P1 | | | ss-15/BC-2.15.004.md |
| BC-2.15.005 | Guarded Memory and Skill Writes (MemoryWriteGuard; E-MEMORY-007) | CAP-020 | | DI-008,DI-012,DI-014 | P1 | | | ss-15/BC-2.15.005.md |
| BC-2.15.006 | Frozen-Snapshot Context Mutation — Memory-Sourced System-Prompt Content | CAP-020 | | DI-002,DI-008,DI-014 | P1 | | | ss-15/BC-2.15.006.md |
| BC-2.16.001 | Per-Tool Retry Policy Keyed by tool_name (Not Args Hash) | CAP-018 | NE-09 | | P1 | | | ss-16/BC-2.16.001.md |
| BC-2.16.002 | Finite global_limit Non-None Default for All Retry Policies | CAP-018 | NE-09 | | P1 | | | ss-16/BC-2.16.002.md |
| BC-2.16.003 | Circuit Breaker Trips After Repeated Failure; Prevents Infinite Retry | CAP-018 | NE-09 | | P1 | | | ss-16/BC-2.16.003.md |
| BC-2.17.001 | Six P0 Kani VP Obligations + Three P1 Kani VP Obligations | CAP-019 | | DI-001,DI-005,DI-007,DI-014 | P2 | | | ss-17/BC-2.17.001.md |
| BC-2.17.002 | cargo-fuzz Targets — Serialization Round-Trip (Checkpoint) and Graph-Execution Paths | CAP-019 | | | P2 | | | ss-17/BC-2.17.002.md |
| BC-2.18.001 | PromptTemplate F-String Rendering, Partial Binding, Variable Detection, and Strict-Undefined Guard | CAP-022 | | DI-008,DI-014 | P1 | | | ss-18/BC-2.18.001.md |
| BC-2.18.002 | ChatPromptTemplate Multi-Message Rendering with PromptValue and Per-Message MessageProvenance | CAP-022 | | DI-008 | P1 | | | ss-18/BC-2.18.002.md |
| BC-2.18.003 | MessagesPlaceholder Vec\<Message\> In-Place Expansion and FewShotPromptTemplate Few-Shot Composition | CAP-023 | | DI-008 | P1 | | | ss-18/BC-2.18.003.md |
| BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time) | CAP-022 | | DI-008,DI-014 | P1 | **RG** | **VP-006** | ss-18/BC-2.18.004.md |
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
| BC-2.23.001 | ReadFileTool — PathGuard-Confined File Read; max_bytes 1 MiB Limit; E-TOOLS-001 / E-TOOLS-002 | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.001.md |
| BC-2.23.002 | WriteFileTool — PathGuard-Confined Atomic Write; High ActionRisk; No Auto-Retry; E-TOOLS-001 | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.002.md |
| BC-2.23.003 | EditFileTool — Exact-Match String Replace; E-TOOLS-003 on No-Match; Opt-In Fuzzy Fallback (EditConfig::fuzzy_threshold); Conditional Retry Safe | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.003.md |
| BC-2.23.004 | ListDirTool — PathGuard-Confined Directory Listing; ReadOnly; E-TOOLS-001; DirEntry Struct | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.004.md |
| BC-2.23.005 | BashTool — Sandboxed Shell Execution; Non-Lowerable Medium Risk Floor; BashOutput; 256 KiB Output Cap; 30 s Timeout; E-TOOLS-004/005/007 (VP-013 Kani Seed) | CAP-037 | | DI-014,DI-015 | P1 | | **VP** | ss-23/BC-2.23.005.md |
| BC-2.23.006 | GrepTool — In-Process Regex Search; Linear-Time `regex` Crate; max_results 100 Cap; Hermetic; PathGuard Scope; E-TOOLS-001/006 | CAP-038 | | DI-014 | P1 | | | ss-23/BC-2.23.006.md |

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
| 2.6 | 2026-07-22 | burst-239/F-P139: BC-2.06.001 title corrected to match H1 (H1 authority — title was stale from pre-D23 era). BCs updated this burst: BC-2.04.001 v1.4 (+Inv-5 append-only invariant, F-P139-01a), BC-2.10.006 v1.4 (citation fix to BC-2.04.001 Inv-5, F-P139-01b), BC-2.06.001 v1.6 (PC2 tokens_remaining_after u64→Option<i64> F-P139-02; Description Step-no-Stream F-P139-04), BC-2.07.003 v1.3 (PC5 mandate [] F-P139-03), BC-2.07.001 v1.3 (TV-005 [] F-P139-03), BC-2.05.008 v1.1 (Related BCs PC-4 scope + EC-006 F-P139-07). | burst-239 F-P139 |
| 2.5 | 2026-07-23 | burst-238/sweep/2026-07-23: Update VP-INDEX status note — 'VP-006–VP-010 pending architect authoring' was stale; VP-INDEX v1.2 (burst-223) registered VP-006–010 and VP-006.md–VP-010.md all exist. Note updated to reflect completed state. | burst-238 |
| 2.4 | 2026-07-22 | burst-237/F-P137-01: BC-2.13.002 DI column DI-006 → DI-006,DI-015. Propagates burst-235 F-P135-05 di_anchors addition (co-enforcer of DI-015 Subprocess Execution Timeout; kill_on_drop PC-6+INV-6) to the index row — BC file frontmatter was correct since burst-235 but index was not swept. DI-anchor reconcile sweep: no other drift found (BC-2.20.003 and BC-2.18.004/005 apparent discrepancies confirmed as awk false-positives from \\| in title). | burst-237 F-P137-01 |
| 2.3 | 2026-07-22 | burst-235/F-P135-03: BC-2.23.005 DI column DI-009,DI-014 → DI-014,DI-015. Propagates burst-234 F-P134-06 re-anchor (DI-009→DI-015 adjudication) to the index row — BC file frontmatter was correct since burst-234 but index was not swept. | burst-235 F-P135-03 |
| 2.2 | 2026-07-22 | burst-233/F-P133-02: BC-2.16.001/002/003 Wave-1 promotion per D23 — priority P2→P1, wave 2→1; header 72 P1/6 P2 → 75 P1/3 P2; Full Catalog P2→P1 for all three rows. VP-013 Security Anchor corrected: ADR-018 Decision 6 → ADR-020 Decision 3 (BashTool non-lowerable Medium risk floor is ADR-020 Decision 3, not ADR-018). | burst-233 F-P133-02 |
| 2.1 | 2026-07-22 | D23 INTEGRATE burst-231: header 116→129 BCs; P1 56→72, P2 9→6 (BC-2.15.001/002/003 promoted P2→P1); VP Seed 8→11 (+VP-011→BC-2.05.007, VP-012→BC-2.10.005, VP-013→BC-2.23.005); VP-INDEX 10→13; subsection groups 22→23 (+SS-23 First-Party Tools); Full Catalog +13 rows (BC-2.05.007/008, BC-2.06.004/005/006, BC-2.10.005/006, BC-2.23.001–006). | D23 burst-231 |
| 2.0 | 2026-07-21 | Burst-226 (F-P131-01/02/03/05/06/07): (1) F-P131-05 TrustLevel migration: BC-2.18.004 v1.1→1.2 (title updated to canonical TrustLevel form; EC/TV/INV migrated from ProvenanceTag to TrustLevel). BC-2.18.002 v1.0→1.1 (INV-2/PC3 TrustLevel). BC-2.09.003 v1.1→1.2 (PC1 ProvenanceTag struct form; PC4 canonical guardrail.unregistered_passthrough). BC-2.11.006 v1.1→1.2 (PC2 canonical event_type). (2) F-P131-01: BC-2.20.002 v1.2→1.3 (PC2 severity-bifurcated Fail; E-CORE-008). (3) F-P131-07: BC-2.21.004 v1.1→1.2 (INV-3 fail-safe E-VS-005). (4) F-P131-02+03: BC-2.13.002 v1.0→1.1 (event_type sandbox.process_no_isolation_execute). BC-2.12.006 v1.2→1.3 (event_type server.rate_limit_store_in_memory). BC-2.15.003 v1.1→1.2 (event_type memory.gdpr_unattributed_session_entries). BC-2.12.005 v1.4→1.5 (event_type server.security_config_cors_wildcard). BC-2.18.004 H1 title already updated in v1.9→2.0 scope. | burst-226 F-P131 |
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
