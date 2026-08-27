---
document_type: adr
level: L3
adr_id: "029"
slug: graph-agent-tool-wrapping
title: "Agent-as-MCP-Tool (GraphAgentTool) Wrapping — StateGraph Registration in ToolRegistry for MCP Exposure"
status: accepted
date: "2026-08-26"
producer: architect
timestamp: 2026-08-26T00:00:00Z
version: "2.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
superseded_by: null
subsystems_affected: ["SS-09"]
changelog:
  - "2.1 (round-12/GAP-01-straggler/2026-08-27): §Context: 'compiled StateGraph<S>' → 'CompiledStateGraph' (COMPILED form is CompiledStateGraph, non-generic per BC-2.02.001 {PC-001}). §Symbol Grounding CompiledStateGraph::stub_terminal row: status REQUIRES-ROUTING → ROUTED/SPECCED — S-1.14 §AC-014 + Task 18 (round-10); cross-ref §Stub Graph Obligation → §Proof Obligations (real VP-016 heading per ADR-022 real-heading rule)."
  - "2.0 (round-10/F-P2A072-01+F-P2A072-02+F-P2A072-03/2026-08-27): TYPE-GROUNDING reconciliation against canonical pregolya-core/pregolya-graph type surfaces (P2A-072 realizability lens). F-P2A072-02 HIGH (ToolOutput::Structured phantom — 16× across cluster): `ToolOutput` has exactly `Text(String)`, `Json(serde_json::Value)`, `Error(String)` — NO `Structured` variant (interface-definitions.md §Tool). `DynTool::invoke_dyn` returns `Result<serde_json::Value, PregolyaError>` not `Result<ToolOutput, PregolyaError>`. All `Ok(ToolOutput::Structured { value })` occurrences replaced with `Ok(serde_json::Value from extract_output_result)` in §Decision 3, §Decision 4, §Decision 5 Error Routing Table, §Consequences VP Addition. §Decision 3 SEC-001 updated to reference `serde_json::Value` directly. §Decision 3 Null output paragraph updated. F-P2A072-01 HIGH (as_value() phantom — parallel VP-016 fix): VP-016 §Proof Harness `tool_output.as_value()` removed (no such method on serde_json::Value); resolved by F-P2A072-02 grounding. F-P2A072-03 HIGH (CompiledGraph<S> + trait GraphState phantom): canonical type is `CompiledStateGraph` (non-generic, BC-2.02.001 {PC-001}, pregolya-graph/src/types.rs); `GraphState` is NOT a trait (entities-graph.md §GraphState). §Decision 1 Module Interface Sketch: `from_graph<S>` → non-generic `from_graph` with explicit `input_schema: schemars::Schema` + `Arc<CompiledStateGraph>` + `extract_output: Fn(&serde_json::Value) -> serde_json::Value`; removed `S: GraphState + Deserialize + JsonSchema` bound; `GraphRunner` doc comment updated. §Decision 1 dep-edge narrative: `CompiledGraph<S>` → `CompiledStateGraph`. §Decision 2 inputSchema derivation: 'caller derives schema via schemars::schema_for!(StateType) and passes as input_schema parameter' (CompiledStateGraph has no schema introspection method per BC-2.02.001). §Decision 2 pipeline: `serde_json::from_value::<S>` step eliminated; CompiledStateGraph::invoke takes serde_json::Value directly. §Consequences dep edge + module description updated. §Symbol Grounding subsection added (symbol-existence audit table). PO handoff: BC-2.09.008 ×5 ToolOutput::Structured→Value + {PRE-001}→CompiledStateGraph + {PC-003} deserialization-path update; BC-2.09.007 ×3 ToolOutput::Structured→Value. Story-writer handoff: S-2.11 Task 23/File-Structure/Arch-rule update."
  - "1.9 (round-8/F-P2A069-02+F-P2A069-01/2026-08-26): F-P2A069-02 MED — §Decision 2 pseudocode, §Decision 2 prose paragraph, §Decision 5 Error Routing Table: three occurrences of 'runs inside invoke_dyn' corrected to 'runs inside ConcreteGraphRunner<S>::run; failure surfaced through invoke_dyn.' GraphAgentTool is non-generic (runner: Arc<dyn GraphRunner>; S is erased); invoke_dyn cannot name or monomorphize S; from_value::<S> must live in ConcreteGraphRunner<S>::run where S is statically known — consistent with §Decision 3 canonical seam. Routing decision (isError: true, NOT JSON-RPC -32602) UNCHANGED. F-P2A069-01 HIGH: parallel harness realizability rewrite in VP-016 §Realizability-Trace (complete input, vacuous-Err guard) in same burst."
  - "1.8 (round-7/F-P2A066-01+F-P2A067-01/2026-08-26): F-P2A067-01 HIGH — §Decision 2 pseudocode + prose + §Decision 5 Error Routing Table: removed all three occurrences of phantom `E-MCP-004 McpInvalidArguments` (E-MCP-004 is already assigned to ToolNotFound per BC-2.09.002 {PC-008}; there is no McpInvalidArguments code; the schema-validation-failure path is a wire-protocol JSON-RPC -32602 response with no PregolyaError raised per BC-2.09.007 {PC-005}/BC-2.09.008 EC-001). Replaced with wire-protocol-only description identical to the -32700/-32600 paths already in the table. F-P2A066-01 HIGH (partial) — §Decision 3: canonical seam statement added: 'STATE-ISOLATION is enforced solely by `GraphRunner::run` via `extract_output(&final_state)`; `GraphAgentTool::invoke_dyn` performs no re-filtering.' Prevents seam re-drift. VP-016 receives parallel harness rewrite (same round)."
  - "1.7 (round-6/O-063-02/2026-08-26): §Decision 4 fail-closed guarantee paragraph: `GraphAgentTool::invoke` → `GraphAgentTool::invoke_dyn` (O-063-02 OBS — canonical DynTool dispatch method is invoke_dyn; one bare occurrence corrected)."
  - "1.6 (P2A-062/2026-08-26): F-062-01 HIGH — §Decision 4 fail-closed guarantee: VP-016 attribution corrected — binary interrupt invariant ({INV-002}) is enforced by Red-Gate test set (BC-2.09.008 TV-002/TV-005, S-2.11 AC-024), not VP-016; VP-016 proves STATE-ISOLATION ({INV-001}, §Decision 3). F2 MED — §Decision 2 pipeline + §Decision 5 Error Routing Table: post-schema serde_json::from_value failure corrected — runs inside invoke_dyn, surfaces as isError: true (BC-2.09.008 {PC-003}/EC-002), not JSON-RPC -32602; prose clarified to keep two paths distinct. F3 MED — §Decision 2: Tool::input_schema() corrected to Tool::schema() (canonical method per interface-definitions.md). F-P2A-061-02 MED — §Consequences Error Code (PO Obligation): E-MCP-011 ForceApproveWriteBlocked obligation added, cross-referencing §Decision 4. LOW schemars — schemars::schema::RootSchema corrected to schemars::Schema; RootSchema prose corrected to Schema."
  - "1.5 (P2A-059-records/2026-08-26): F-P2A-059-01 LOW (records-tier) — §Decision 5 E-MCP-010 message-template cell: trailing period dropped so the ADR cell matches error-taxonomy.md verbatim ('...synchronous tools/call invocation' — no trailing period). 1-character literal alignment to authoritative taxonomy source. No semantic or rationale changes. RECORDS-ONLY micro-burst per TD-RECORDS-MICRO-BURST-001."
  - "1.4 (P2A-058/2026-08-26): F-058-02 MED — E-MCP-010 message template remedy corrected in §Decision 5: dropped 'or register with GraphToolApprovalPolicy::ForceApproveHooks if read-only' clause (ForceApproveHooks cannot resolve E-MCP-010; node-level interrupt() causes RunStatus::Interrupted regardless of approval policy; the hook path and the node interrupt path are independent); corrected remedy: 'restructure the graph so it does not call interrupt() during a synchronous tools/call invocation.' RetryHint rationale in §Decision 5 updated to remove ForceApproveHooks reference. F-058-05 LOW — E-MCP-011 message-template wording: two illustrative variant forms exist (table vs code sketch); illustrative-forms note added in §Decision 4 after E-MCP-011 table; error-taxonomy.md is the authoritative message source and supersedes any wording shown in this ADR."
  - "1.3 (P2A-057-adjudication/2026-08-26): F-057-01 CRITICAL — fail-open None fixed: preview.action_risk is Option<ActionRisk> (BC-2.05.007 {PRE-003}); the if/else check on action_risk was replaced with a match on Option<ActionRisk>; None (undeclared risk) now fails closed to Deny per BC-2.05.006 EC-004/{INV-002} — None no longer falls through to Approve. F-057-04 MED — type-name corrected in ForceApproveHooks code sketch: ToolPreview→ToolCallPreview (canonical type per BC-2.05.007 {PRE-003}). F-057-02 HIGH — E-MCP-010/E-MCP-011 path reconciliation: removed incorrect claim that 'E-MCP-011 fires before the outer E-MCP-010'; clarified in rationale, enum docs, and Error Routing Table that the two codes are distinct independently-surfacing paths: E-MCP-010 fires only when node-level interrupt() causes RunStatus::Interrupted (graph parks); E-MCP-011 is a diagnostic emitted by BoundaryApprovalHook on the ActionRisk block path (graph does NOT park; terminal propagated normally). Added BoundaryApprovalHook Deny row to Error Routing Table. Enum doc comments updated for both DenyInterrupts and ForceApproveHooks. E-MCP-011 message template updated to reflect None-or->=Medium condition."
  - "1.2 (SEC-review-adjudication/2026-08-26): SEC-007 — ForceApproveHooks BoundaryApprovalHook corrected to override ONLY PendingHumanApproval→Approve; Deny and all other decisions pass through UNCHANGED. SEC-006 — runtime ActionRisk enforcement added to ForceApproveHooks: BoundaryApprovalHook checks preview.action_risk before overriding; if >= ActionRisk::Medium returns Deny (CRITICAL log) instead of Approve; E-MCP-011 ForceApproveWriteBlocked specified for PO to mint. SEC-005 — error-path STATE-ISOLATION convention added to §Decision 3: node error messages must exclude checkpoint/run/thread IDs; sanitization pass applied before content[0].text. SEC-001 — explicit Decision 3 invariant: Tool implementations MUST NOT embed credential material in ToolOutput; framework does not sanitize success-path result_text (DI-010 binds callers, not framework). SEC-008 — panic contract firmed up in §Decision 5 Error Routing Table: extract_output panic caught by server-handler UnwindSafe boundary; static isError 'internal error' message; server continues serving."
  - "1.1 (E-code-correction/2026-08-26): Error code corrected to E-MCP-010 (GraphAgentInterruptDenied) — prior code was already taken by McpContentUnsupported (minted 2026-07-22); {INV-STATE-ISOLATION} tag corrected to {INV-001} (stable BC-2.09.008 numeric anchor). See §Changelog for full history."
---

# ADR-029: Agent-as-MCP-Tool (GraphAgentTool) Wrapping

**Status:** Accepted — human-approved v1 scope addition (GAP-01, 2026-08-26)

## Context

BC-2.09.006 (tools/list advertisement) and BC-2.09.007 (tools/call execution) specify how the
pregolya MCP server advertises and dispatches tools that are already registered in the
`ToolRegistry`. Neither BC specifies how a pregolya agent — a `CompiledStateGraph` — becomes
such a registered tool. This gap was surfaced by the Flowloom-embedding holdout scenario
HS-C-001: a host application that embeds a Pregolya agent and exposes it as an MCP tool to
downstream orchestrators has no first-class contract for this wrapping path.

The human approved this as v1 behavior (GAP-01 resolution, 2026-08-26). BC-2.09.008 is the
new behavioral contract. This ADR governs the architectural decisions for the wrapping layer.

### Constraints

1. The MCP `tools/call` protocol is synchronous request-response: no mid-call streaming or
   multi-turn interaction is possible in v1.
2. BC-2.09.007 {INV-003} mandates credential redaction before any error text reaches an
   external MCP client. This obligation extends to errors produced by graph runs.
3. ADR-018 establishes `PreToolCallHook` / `GraphToolApprovalPolicy` machinery for HITL
   interrupt handling. The wrapping layer must integrate with this machinery.
4. The `mcp::server` module in `pregolya-mcp` (ADR-013) is the server that dispatches
   `tools/call` requests. Any wrapped graph tool must be usable by that server without
   special-casing — it must implement `DynTool` and register in `ToolRegistry` like any
   other tool.

---

## Decision 1 — Module: `mcp::graph_tool` in `pregolya-mcp`; New Dep Edge `pregolya-mcp → pregolya-graph`

`GraphAgentTool` lives in `mcp::graph_tool` (`pregolya-mcp/src/graph_tool.rs`). This is a
new module in the existing `pregolya-mcp` crate (no new crate; roster unchanged at 21
published crates + 1 workspace binary per ARCH-INDEX.md §Canonical Crate Roster).

**Module tier:** MEDIUM — effectful execution (runs an async graph), important for
correctness, not a security boundary in the class of `path-guard` or `session-index`. No
Kani VP host at v1. Consistent with `mcp::server` (MEDIUM) and `mcp::client` (MEDIUM).

**New dependency edge:** `pregolya-mcp` → `pregolya-graph` (runtime; `GraphAgentTool`
wraps `CompiledStateGraph` which is defined in `pregolya-graph` per BC-2.02.001 {PC-001}). This edge did not previously
exist. `pregolya-mcp` already depends on `pregolya-core`; adding `pregolya-graph` is
consistent with the topological order (`pregolya-graph` is Wave 1; `pregolya-mcp` is Wave 2).
No dependency cycle is introduced.

**Module cohesion rationale (ADR-013 extension):** ADR-013 placed `mcp::server` in
`pregolya-mcp` for protocol cohesion. `mcp::graph_tool` is the MCP-server registration
path for agents — it belongs in the same crate so that `mcp::server` and `mcp::graph_tool`
share the same `ToolRegistry` view, `McpServerConfig` context, and `mcp::sanitize` redaction
utilities without cross-crate imports.

**BC assignment:** BC-2.09.008 (SS-09; next BC in the SS-09 range after BC-2.09.007).

### Module Interface Sketch

> **Behavioral authority note:** BC-2.09.008 is the authoritative signature carrier.
> Interface definitions in BC-2.09.008 and `interface-definitions.md` take precedence
> over ADR sketches per the behavioral authority rule.

```rust
// pregolya-mcp/src/graph_tool.rs

/// Wraps a compiled StateGraph as a pregolya DynTool, enabling registration in a
/// ToolRegistry and advertisement/invocation via BC-2.09.006 tools/list and
/// BC-2.09.007 tools/call. The wrapping enforces STATE-ISOLATION (only the
/// extract_output closure result is returned), fail-closed interrupt policy, and
/// mandatory credential redaction on error messages (BC-2.09.007 {INV-003}).
pub struct GraphAgentTool {
    name: String,
    description: String,
    input_schema: schemars::Schema,
    runner: Arc<dyn GraphRunner>,
    approval_policy: GraphToolApprovalPolicy,
}

impl GraphAgentTool {
    /// Convenience constructor. The caller derives `input_schema` from their channel-state
    /// struct via `schemars::schema_for!(StateType)` and passes it explicitly — no schema
    /// derivation occurs inside `from_graph` (`CompiledStateGraph` is non-generic and has no
    /// schema introspection method per BC-2.02.001). `extract_output` receives the final
    /// channel-composed state as `&serde_json::Value` and selects which fields are returned
    /// to the external MCP client. All other fields are STATE-ISOLATION discarded.
    pub fn from_graph(
        name: impl Into<String>,
        description: impl Into<String>,
        graph: Arc<CompiledStateGraph>,
        input_schema: schemars::Schema,
        extract_output: impl Fn(&serde_json::Value) -> serde_json::Value + Send + Sync + 'static,
    ) -> Self;

    /// Override the default DenyInterrupts approval policy.
    pub fn with_approval_policy(self, policy: GraphToolApprovalPolicy) -> Self;
}

/// Interrupt-handling policy for GraphAgentTool invocations via tools/call.
#[non_exhaustive]
pub enum GraphToolApprovalPolicy {
    /// Default — fail-closed. Node-level interrupt() calls cause the graph to park
    /// (RunStatus::Interrupted) → Err(E-MCP-010). PreToolCallHook PendingHumanApproval
    /// decisions are converted to Deny; the tool is not invoked; the graph continues
    /// toward its terminal state (Ok per {PC-004} or graph's own Err — NOT a synthetic
    /// E-MCP-010). No checkpoint state is persisted for a node-level interrupted run.
    DenyInterrupts,
    /// Override PreToolCallHook PendingHumanApproval decisions to Approve for tools
    /// with declared ActionRisk < Medium. Deny and all other hook decisions pass through UNCHANGED.
    /// Tools with undeclared ActionRisk (None) or ActionRisk >= Medium are DENIED (fail-closed)
    /// — runtime enforcement prevents write-class tools from being unconditionally approved.
    /// Node-level interrupt() calls still cause the graph to park → Err(E-MCP-010); they are
    /// not overridden by this policy.
    /// MUST be explicitly opted into. Suitable only for read-only tool graphs with declared
    /// ActionRisk < Medium for every tool.
    ForceApproveHooks,
}

/// Type-erased runner — holds `Arc<CompiledStateGraph>` internally; `GraphAgentTool` stores
/// this behind `Arc<dyn GraphRunner>`. No generic parameter. Enforces STATE-ISOLATION by
/// calling `extract_output(&final_state_value)` as the sole data-exit path before returning
/// `serde_json::Value` to `invoke_dyn`.
#[async_trait]
pub(crate) trait GraphRunner: Send + Sync {
    async fn run(
        &self,
        input: serde_json::Value,
        approval_policy: &GraphToolApprovalPolicy,
    ) -> Result<serde_json::Value, PregolyaError>;
}
```

---

## Decision 2 — Input Mapping: schemars Schema + JSON Schema Validation + serde_json Deserialization

**inputSchema derivation:** The caller derives `inputSchema` from their channel-state struct
via `schemars::schema_for!(StateType)` before calling `from_graph`, and passes it as
`input_schema: schemars::Schema`. `CompiledStateGraph` is non-generic (BC-2.02.001 {PC-001})
and has no schema introspection method — schema derivation is the caller's responsibility.
The value is stored in `GraphAgentTool` and returned by `DynTool::schema()`.
This schema is advertised in the MCP `tools/list` response per BC-2.09.006 {PC-002}.

**Validation + deserialization at invoke time:**

```
tools/call arguments (serde_json::Value)
  → JSON Schema validation against input_schema (jsonschema crate)
  → if INVALID: wire-protocol JSON-RPC -32602 response (BC-2.09.007 {PC-005}); no PregolyaError, no E-MCP-* code raised on this path
  → if VALID: serde_json::Value passed directly to CompiledStateGraph::invoke(input, config)
              [runs inside ConcreteGraphRunner::run — ConcreteGraphRunner is non-generic (no S);
               CompiledStateGraph takes serde_json::Value directly (BC-2.02.001 {PC-005});
               no type-level from_value::<S> deserialization step (F-P2A072-03 closure)]
  → if invoke FAILS: Err(PregolyaError) propagated through invoke_dyn as isError: true
                     (standard graph execution error path; BC-2.09.008 {PC-003} updated by PO)
  → on success: extract_output(&final_state_value) called inside ConcreteGraphRunner::run;
                final_state_value is the serde_json::Value (channel-keyed map) from invoke
                → proceeds to state-isolation return (Decision 3)
```

The two-step approach (schema validate, then invoke) surfaces schema errors with structured
messages before running the graph. The two paths are distinct: schema-validation failure
results in a wire-protocol JSON-RPC `-32602` response (BC-2.09.007 {PC-005}); no
`PregolyaError` or `E-MCP-*` code is raised on this path — identical treatment to the
`-32700`/`-32600` wire-protocol paths in the error routing table. Graph execution failure
runs inside `ConcreteGraphRunner::run` (non-generic; no `from_value::<S>` step — F-P2A072-03
closure) and is surfaced through `invoke_dyn` as `isError: true` per BC-2.09.008 {PC-003}
(updated by PO for the non-generic path) — it is a tool-error result, not a protocol error.

**Empty arguments:** An empty JSON object `{}` is valid if `S` has no required fields per
the derived JSON Schema. Schema validation catches missing required fields.

---

## Decision 3 — Output Mapping + STATE-ISOLATION Invariant

**`extract_output` closure:** Provided by the caller at construction. Receives a reference
to the final channel-composed state as `&serde_json::Value` (the value returned by
`CompiledStateGraph::invoke`) and returns `serde_json::Value` containing only the fields
the caller selects for external exposure.

**STATE-ISOLATION invariant:** The `GraphRunner::run` method:

1. Runs the graph to terminal state (or to an interrupt — see Decision 4).
2. On successful terminal: calls `extract_output(&final_state_value)` where
   `final_state_value: serde_json::Value` is the channel-composed state returned by
   `CompiledStateGraph::invoke`.
3. Returns ONLY the `serde_json::Value` from step 2.

**Canonical seam statement (F-P2A066-01):** STATE-ISOLATION is enforced solely by
`GraphRunner::run` via `extract_output(&final_state_value)`; `GraphAgentTool::invoke_dyn`
performs no re-filtering. This is the authoritative seam definition — VP-016 proof harness, BC-2.09.008
{PC-004}/{INV-001}, and S-2.11 Task 23 Arch-Compliance rule must all conform to this seam.

The `GraphRunner` NEVER:
- Serializes `final_state` directly (the full struct).
- Includes any checkpoint ID, run ID, or durable storage key in the return value.
- Includes any intermediate node output or accumulated message history.
- Includes any internal graph metadata or execution statistics.

**Rationale:** The external MCP client has no need for — and must not receive — pregolya's
internal execution state. Checkpoint IDs could be used by a caller to directly access the
durable store, bypassing access controls. Intermediate message history may contain
credential-bearing model reasoning. The `extract_output` closure is the ONLY path through
which data exits the graph run boundary.

**Null output:** `extract_output` returning `Value::Null` is valid. `invoke_dyn` returns
`Ok(Value::Null)` — BC-2.09.007 {PC-002} result_text selection rule maps this to
`result_text = "null"`. No error raised.

**DI-010 interaction:** The STATE-ISOLATION invariant is a superset of DI-010 (Credential
Opacity). If `extract_output` is correctly scoped to the output fields of `S`, credential
material in input fields, intermediate fields, or model reasoning captured in messages
cannot appear in the output. The caller is the final line of defense for `extract_output`
scoping; the framework guarantees no additional field leaks beyond what `extract_output` returns.

**SEC-001 Decision — Credential Opacity on Success Path:**
`mcp::sanitize::redact_credentials` is NOT applied to the success-path `result_text`
generated by `extract_output`. Rationale: `invoke_dyn` returns `serde_json::Value` directly;
applying regex-based credential scrubbing to structured JSON would corrupt legitimate 64+
character alphanumeric data (base64 blobs, hashes, public keys).
The correct enforcement point is the Tool implementation invariant: **Tool implementations
MUST NOT embed credential material in `ToolOutput`** — this obligation derives directly from
DI-010 (Credential Opacity) and binds every caller of `GraphAgentTool::from_graph` at the
`extract_output` closure authoring site. The framework enforces credential opacity on ALL
error paths (unconditional `redact_credentials` before `content[0].text`); success-path
enforcement is the caller's responsibility. This decision is auditable at code-review time:
reviewers must verify every `extract_output` closure does not select credential-bearing fields.

**SEC-005 Decision — Error-Path STATE-ISOLATION Convention:**
The STATE-ISOLATION invariant ({INV-001}) applies to ALL output paths, including error paths.
Node error messages that propagate through `GraphRunner::run` MUST NOT include checkpoint IDs,
run IDs, or thread IDs. Convention:
- Graph node implementations MUST author error messages using only functional/behavioral
  descriptions (e.g., "tool invocation failed: timeout") — not internal execution context
  (checkpoint IDs, run UUIDs, thread identifiers).
- The `BoundaryApprovalHook` and `GraphRunner::run` apply a sanitization pass for
  internal-ID patterns (UUID v4 format: `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}`) before
  populating `content[0].text` on any `isError: true` path, in addition to the existing
  `redact_credentials` pass. The two passes are chained:
  `sanitize_internal_ids(redact_credentials(message))`.
- The BC-2.09.008 {INV-001} scope extension (error paths included) must be specified by PO
  as a clause addition to the BC invariant body and a corresponding TV.

---

## Decision 4 — Interrupt/HITL Policy at the MCP Tool Boundary (Fail-Closed Default)

### The Problem

The MCP `tools/call` protocol is synchronous: a single request produces a single response.
There is no mechanism to surface an in-flight interrupt to the external MCP client, collect
a human decision, and resume the same tool invocation. An internal graph interrupt during a
`tools/call` invocation cannot be resolved — it can only be denied or awaited (awaiting is
not possible in this protocol context).

### GraphToolApprovalPolicy::DenyInterrupts (Default)

When `approval_policy = DenyInterrupts` (the default):

- **PreToolCallHook path:** `GraphAgentTool` wraps the graph's configured `pre_tool_hook`
  with a `BoundaryApprovalHook` that intercepts `PendingHumanApproval` decisions:
  ```rust
  // BoundaryApprovalHook (internal, not public API)
  impl PreToolCallHook for BoundaryApprovalHook {
      async fn pre_invoke(&self, preview, run_ctx) -> PreToolDecision {
          let decision = self.inner.pre_invoke(preview, run_ctx).await;
          match decision {
              PreToolDecision::PendingHumanApproval { .. } =>
                  PreToolDecision::Deny { reason: "HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY".into() },
              other => other,
          }
      }
  }
  ```
  The `Deny` path is the ADR-018 Decision 3 fast path: the tool is not invoked; the graph
  receives `ToolOutput::Error("HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY")`. The graph may
  continue running (the run is not aborted immediately by the Deny alone), but the denied
  tool call means the graph will likely reach an error terminal state.

- **Node-level interrupt path:** If the graph calls `interrupt()` from a node (BC-2.05.001
  machinery), the run parks and returns `RunStatus::Interrupted`. `GraphRunner::run`
  detects this status and returns `Err(PregolyaError { code: "E-MCP-010",
  category: EXEC, message: "graph agent tool invocation interrupted at MCP boundary: HITL
  approval not supported for synchronous tools/call", .. })`. The interrupted run is NOT
  persisted to durable checkpoint — the run is abandoned at the graph level.

**Fail-closed guarantee:** NO code path in `GraphAgentTool::invoke_dyn` returns `Ok(ToolOutput)`
if the graph was interrupted (parked). The binary invariant: completed terminal → Ok, any
interrupt → Err(E-MCP-010). This binary interrupt invariant ({INV-002}) is enforced by the
Red-Gate test set (BC-2.09.008 TV-002/TV-005, S-2.11 AC-024) — it is NOT the VP-016 proof
target. VP-016 (proptest P1) proves the STATE-ISOLATION invariant ({INV-001}, §Decision 3):
that `ToolOutput` contains only the fields returned by `extract_output`.

### GraphToolApprovalPolicy::ForceApproveHooks (Explicit Opt-In)

When `approval_policy = ForceApproveHooks`:

- **SEC-007 Correction:** The `BoundaryApprovalHook` overrides ONLY `PendingHumanApproval`
  → `Approve`. `Deny` and ALL other `PreToolDecision` values pass through UNCHANGED.
  A `Deny` returned by the inner hook is always respected regardless of the approval policy —
  `ForceApproveHooks` is not a blanket security bypass, only a HITL-dialog suppressor.
- Node-level `interrupt()` calls STILL use DenyInterrupts semantics — the graph parks
  → `Err(E-MCP-010)`. Only the PreToolCallHook `PendingHumanApproval` path is overridden.

**SEC-006 — Runtime ActionRisk Enforcement (CWE-862 prevention):**
Before overriding `PendingHumanApproval` → `Approve`, the `BoundaryApprovalHook` MUST
check `preview.action_risk` (type: `Option<ActionRisk>` per BC-2.05.007 {PRE-003} —
`Some(tier)` if the tool is annotated with `#[tool(action_risk = ...)]`, `None` otherwise).
If `preview.action_risk` is `None` (undeclared — fail-closed per BC-2.05.006 EC-004/{INV-002})
or `Some(r)` where `r >= ActionRisk::Medium`, the hook returns `Deny` (with a CRITICAL-level
structured log) instead of `Approve`:

```rust
// BoundaryApprovalHook for ForceApproveHooks (SEC-006 + SEC-007 corrected form)
// F-057-04: canonical type is ToolCallPreview (BC-2.05.007 {PRE-003}), not ToolPreview.
// F-057-01: preview.action_risk is Option<ActionRisk>; match on Option to avoid fail-open
//           on None (undeclared risk). None fails closed to Deny per BC-2.05.006 EC-004/{INV-002}.
impl PreToolCallHook for BoundaryApprovalHook {
    async fn pre_invoke(&self, preview: &ToolCallPreview, run_ctx: &RunContext) -> PreToolDecision {
        let decision = self.inner.pre_invoke(preview, run_ctx).await;
        match decision {
            PreToolDecision::PendingHumanApproval { .. } => {
                // SEC-006: fail-closed ActionRisk gate (CWE-862 prevention).
                // preview.action_risk: Option<ActionRisk> — Some(tier) if annotated, None otherwise.
                // None (undeclared) fails closed to Deny per BC-2.05.006 EC-004/{INV-002}.
                match preview.action_risk {
                    Some(r) if r < ActionRisk::Medium => {
                        // Declared ReadOnly or Low risk: safe to auto-approve HITL
                        PreToolDecision::Approve
                    }
                    _ => {
                        // None (undeclared) and Some(>= Medium) both Deny — fail-closed
                        tracing::error!(
                            event_type = "mcp.graph_tool.force_approve_write_blocked",
                            tool_name = %preview.tool_name,
                            action_risk = ?preview.action_risk,
                            "CRITICAL: ForceApproveHooks policy violation — tool has undeclared \
                             or >= Medium ActionRisk; denying tool invocation. Use DenyInterrupts \
                             or restrict graph to tools with declared ActionRisk < Medium."
                        );
                        PreToolDecision::Deny {
                            reason: format!(
                                "ForceApproveHooks policy violation: tool '{}' has ActionRisk {:?} \
                                 (None or >= Medium); ForceApproveHooks is valid only for \
                                 read-only tool graphs with declared ActionRisk < Medium",
                                preview.tool_name, preview.action_risk
                            )
                        }
                    }
                }
            }
            // SEC-007: Deny and all other decisions pass through UNCHANGED
            other => other,
        }
    }
}
```

**New Error Code — `E-MCP-011 ForceApproveWriteBlocked` (PO must mint):**

| Field | Value |
|-------|-------|
| Code | `E-MCP-011` |
| Name | `ForceApproveWriteBlocked` |
| Component | `MCP` |
| Category | `EXEC` |
| Severity | `broken` |
| RetryHint | `Never` |
| Message template | `"ForceApproveHooks policy violation: tool '{tool_name}' has ActionRisk {action_risk} (None or >= Medium); ForceApproveHooks is only valid for graphs with declared ActionRisk < Medium for every tool. Reconfigure with DenyInterrupts or audit the tool set."` |
| Minted by | ADR-029 §Decision 4 (architect recommendation); PO authoritative mint |

> **Illustrative wording note (F-058-05):** The message template in the table above and the
> `format!` string in the code sketch below are illustrative forms. `error-taxonomy.md` is
> the authoritative message source for `E-MCP-011`; the taxonomy row supersedes any variant
> wording shown in this ADR.

**Rationale for `E-MCP-011`:** `E-MCP-011` is a structured diagnostic emitted (as a
CRITICAL-level log entry and `Deny` reason) by `BoundaryApprovalHook` when the ActionRisk gate
fires (`None` or `>= Medium`). The hook returns `Deny`; the tool is NOT invoked; the graph
continues executing toward its terminal state. The terminal result surfaces via the normal
execution path — `Ok(serde_json::Value from extract_output_result)` if the graph reaches a
clean terminal ({PC-004}), or `Err(PregolyaError)` carrying the graph's own error if it
reaches an error terminal. `E-MCP-010` (GraphAgentInterruptDenied) is NOT raised on this path.

`E-MCP-010` and `E-MCP-011` are distinct, independently-surfacing codes with orthogonal
triggers and separate graph fates:
- `E-MCP-010`: node-level `interrupt()` causes `RunStatus::Interrupted` → graph PARKS → no
  terminal reached; `Err(E-MCP-010)` is the sole result.
- `E-MCP-011`: `BoundaryApprovalHook` ActionRisk gate fires → `Deny` → graph CONTINUES → terminal
  result (Ok or graph's own Err) propagated normally; `E-MCP-011` is a diagnostic, not the
  terminal error code.

Neither code is a prerequisite for the other; they never co-surface from the same trigger event.

**When to use `ForceApproveHooks`:** Graphs composed exclusively of read-only tools
(e.g., `ReadFileTool`, `GrepTool`) where approval of each tool call adds no security value
AND every tool has `action_risk < ActionRisk::Medium`. The runtime enforcement above ensures
that even if a write-class tool is inadvertently included, it is blocked at invocation time.

**NOT suitable for `ForceApproveHooks`:** Any graph that may invoke `BashTool`,
`WriteFileTool`, `EditFileTool`, or other write-class tools with `action_risk >= ActionRisk::Medium`.
The runtime `ActionRisk` enforcement provides a fail-closed backstop, but callers should
audit tool composition at registration time rather than relying solely on runtime enforcement.

### On-Resume Non-Applicability

BC-2.05.008 specifies a "skip-hook-on-resume" invariant for standard interrupt/resume flows.
This invariant does not apply to `GraphAgentTool` because the `DenyInterrupts` policy never
produces a parked run that could be resumed via `Command(resume=...)`. The run is abandoned
immediately. No resume path exists for MCP-boundary-denied interrupts.

---

## Decision 5 — Error Handling

### New Error Code: `E-MCP-010 GraphAgentInterruptDenied`

**Specification (PO must mint in error-taxonomy.md):**

| Field | Value |
|-------|-------|
| Code | `E-MCP-010` |
| Name | `GraphAgentInterruptDenied` |
| Component | `MCP` |
| Category | `EXEC` |
| Severity | `broken` |
| RetryHint | `Never` |
| Message template | `"graph agent tool invocation interrupted at MCP boundary: HITL approval not supported for synchronous tools/call; restructure the graph so it does not call interrupt() during a synchronous tools/call invocation"` |
| Minted by | ADR-029 (architect recommendation); PO authoritative mint |

**Rationale for EXEC category:** D26 extended the category axis to 13 categories; EXEC is
the correct category for "the graph execution was interrupted before producing a result."
This is an execution-lifecycle error, not a transport (TRANSPORT), credentials (AUTH), or
validation (VAL) error.

**Rationale for Never RetryHint:** A retry with identical arguments will produce the same
interrupt. The caller must restructure the graph so it does not call interrupt() during a
synchronous tools/call invocation — retrying the same invocation cannot succeed.

### Error Routing Table

| Condition | Error | MCP Layer Response |
|-----------|-------|--------------------|
| Input fails JSON Schema validation | wire-protocol only — no PregolyaError, no E-MCP-* code raised (BC-2.09.007 {PC-005} / BC-2.09.008 EC-001) | JSON-RPC -32602 ("Invalid arguments for tool '...': &lt;schema_error&gt;") |
| Graph execution returns `Err(PregolyaError)` (from `CompiledStateGraph::invoke` inside `ConcreteGraphRunner::run`; no `from_value::<S>` step — F-P2A072-03 closure) | original PregolyaError | `isError: true`, redacted message (BC-2.09.007 {PC-003}, {INV-003}; BC-2.09.008 {PC-003} updated by PO) |
| Graph parks (node-level `interrupt()` → `RunStatus::Interrupted`) | `E-MCP-010 GraphAgentInterruptDenied` | `isError: true`, message (after redact_credentials pass) |
| `BoundaryApprovalHook` returns `Deny` (either policy — graph CONTINUES to terminal) | terminal result propagated normally: `Ok(serde_json::Value from extract_output_result)` ({PC-004}) if graph reaches clean terminal; original `Err(PregolyaError)` (graph's own error) if graph reaches error terminal. `E-MCP-010` is NOT raised. `E-MCP-011` is emitted as a structured log entry (ActionRisk gate path only) — it is a diagnostic, not a terminal error code. | `isError: false` (clean terminal) or `isError: true` with graph's own redacted error (error terminal) |
| `extract_output` panics (contract violation by caller) | Rust panic caught by `mcp::server` `UnwindSafe` boundary (`std::panic::catch_unwind` around the `DynTool::invoke` dispatch call); no panic propagates past the MCP handler. Server loop continues serving subsequent requests. | `isError: true`, static message `"internal error"` (no internal state, no panic message, no backtrace leaked to MCP client; SEC-008 contract: panic text may contain internal state so it is NEVER forwarded); error is logged internally at ERROR level with backtrace before the static message is returned |

**Sanitization applies to all `isError: true` paths** — including `E-MCP-010` messages.
Two passes are chained before populating `content[0].text`:
1. `mcp::sanitize::redact_credentials` — per BC-2.09.007 {INV-003} (DI-010 credential opacity)
2. `sanitize_internal_ids` — removes UUID v4 patterns (checkpoint IDs, run IDs, thread IDs)
   per SEC-005 / §Decision 3 error-path STATE-ISOLATION convention

Both passes are unconditional on all `isError: true` paths. Success paths are NOT subject
to framework-level sanitization (see §Decision 3 SEC-001 invariant — Tool implementations
own the credential-opacity obligation for success output).

---

## Rationale

**Why `mcp::graph_tool` in `pregolya-mcp` (not `pregolya-graph`):** ADR-013 establishes
`pregolya-mcp` as the home for all MCP protocol handling. `GraphAgentTool` is specifically
the MCP-server registration path for agents — it exists to make graphs callable via the MCP
`tools/call` protocol. Placing it in `pregolya-mcp` keeps the credential redaction
requirement, the `ToolRegistry` reference, and the server-side error routing co-located with
`mcp::server` and `mcp::sanitize`. The new `pregolya-mcp → pregolya-graph` dependency is
appropriate: `mcp` is Wave 2, `graph` is Wave 1; the topological ordering supports this edge.

**Why `extract_output` closure (not full state serialization):** The graph's `GraphState`
is an accumulator type — it collects messages, intermediate node outputs, tool call history,
and internal bookkeeping fields over the course of the run. Serializing the full final state
would expose all of this to the MCP client. The `extract_output` closure makes the isolation
boundary explicit and auditable at the registration site. Security-conscious callers can
audit a single closure to verify what is being exposed.

**Why `DenyInterrupts` as the fail-closed default:** The MCP protocol has no mechanism to
surface an interrupt mid-call. Any policy that attempts to resolve an interrupt within a
`tools/call` invocation either deadlocks (waiting forever for a human that cannot be reached)
or corrupts the run state. `DenyInterrupts` is the only policy that is both safe and
deterministic. `ForceApproveHooks` is permitted as an opt-in for callers who have audited
their tool composition, but the DEFAULT must be fail-closed.

**Why proptest for VP-016 (not Kani):** The STATE-ISOLATION property operates over
`serde_json::Value` — the output of `extract_output` is arbitrary JSON. Kani's symbolic
reasoning over bounded types cannot cover the full `serde_json::Value` space effectively.
Proptest can generate arbitrary `GraphState` instances (via `Arbitrary` derive) with
arbitrary additional fields and verify that none of those fields appear in the
`extract_output` output unless explicitly selected. This is the right tool for a
structural containment property over open data.

---

## Alternatives Considered

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| `graph::agent_tool` in `pregolya-graph` — no new dep edge | REJECT | Splits the MCP server integration surface across two crates; `pregolya-graph` would need to know about MCP error codes and credential redaction; breaks ADR-013 cohesion |
| Full `final_state` serialization (no `extract_output` closure) | REJECT | Exposes full graph accumulator state to external clients; intermediate messages, tool call history, and internal bookkeeping fields leak to MCP clients; violates DI-010 |
| `ForceApproveHooks` as default | REJECT | Not fail-closed; write-class tool graphs would silently skip approval; any graph with a hook that produces `PendingHumanApproval` would have that approval bypassed by default |
| `AutoApproveHooks` + `AutoDenyInterrupts` as two separate fields | REJECT | Too granular; callers who opt out of the default need a coherent policy name; `ForceApproveHooks` with the documented restriction to read-only graphs is clearer |
| New `pregolya-mcp-adapter` crate | REJECT | 22nd crate; ADR-013 already rejected a new crate for `mcp::server`; same reasoning applies |

---

## Consequences

### New Module

`pregolya-mcp` gains one new module row in module-decomposition.md:
- `mcp::graph_tool` (MEDIUM, SS-09): StateGraph-as-MCP-Tool wrapping adapter;
  `GraphAgentTool` struct implementing `DynTool`; type-erased `GraphRunner` trait holding
  `Arc<CompiledStateGraph>` (non-generic, BC-2.02.001 {PC-001}); `BoundaryApprovalHook`
  for fail-closed interrupt policy; `GraphToolApprovalPolicy` enum; caller-provided
  `input_schema: schemars::Schema`, JSON Schema validation, `extract_output`
  state-isolation enforcement (BC-2.09.008 / ADR-029).

### Module Universe

Module universe: 72 → **73** (+1 MEDIUM execution row; `mcp::graph_tool` is the 73rd module).

### Purity Classification

`mcp::graph_tool` is **Effectful Shell**: it runs an async graph (I/O-bound via
`tool.invoke` calls, checkpointing, network calls), waits for async completion, and returns
a result. The `extract_output` closure itself may be pure, but the module as a whole is
effectful.

### New Dependency Edge

dependency-graph.md gains one new edge:
- `pregolya-mcp` → `pregolya-graph` (runtime; `GraphAgentTool` wraps `CompiledStateGraph` per BC-2.02.001 {PC-001})

### VP Addition

VP-016 (proptest P1, `mcp::graph_tool`, BC-2.09.008) proves the STATE-ISOLATION invariant:
for any channel-composed state `serde_json::Value` with fields beyond the `extract_output`
selection, the `serde_json::Value` returned by `GraphAgentTool::invoke_dyn` contains ONLY
the selected fields.
Harness fn: `graph_agent_tool_state_isolation`.

### BC Anchors

| BC | Contract |
|----|---------|
| BC-2.09.008 | StateGraph-as-MCP-Tool wrapping: `GraphAgentTool` registration, input mapping, output state-isolation, interrupt policy, error routing |

### SS-09 BC Range Extension

SS-09 BC range: BC-2.09.001–007 → BC-2.09.001–008.

### ADR Count

ARCH-INDEX.md ADR registry: 28 → 29 (ADR-028 through ADR-029).

### Error Code (PO Obligation)

PO must mint the following two error codes in `error-taxonomy.md`:

- `E-MCP-010 GraphAgentInterruptDenied` — full spec in §Decision 5. BC-2.09.008 references
  this code at the interrupt-denied edge case (node-level interrupt → RunStatus::Interrupted).
- `E-MCP-011 ForceApproveWriteBlocked` — full spec in §Decision 4 (SEC-006 ActionRisk gate).
  BC-2.09.008 references this code at the ForceApproveHooks ActionRisk block path (§Decision 4).

---

## Source / Origin

- **Decision mandate:** Human-approved v1 scope addition (GAP-01, 2026-08-26) — HS-C-001
  Flowloom-embedding holdout surfaced the gap: BC-2.09.006/007 cover tools already in
  ToolRegistry; no BC specifies how a StateGraph becomes such a tool.
- **BC traceability:** BC-2.09.008 (authored by PO per this ADR spec outline).
- **Upstream design basis:** ADR-013 (mcp::server placement + cohesion rationale),
  ADR-018 (PreToolCallHook / BoundaryApprovalHook pattern),
  BC-2.09.006 (tools/list — inputSchema advertisement path),
  BC-2.09.007 (tools/call — invocation + credential redaction path).
- **Authoring context:** Phase 1b architecture design session (2026-08-26).

---

## Symbol Grounding

Symbol-existence audit against canonical pregolya-core / pregolya-graph type surfaces.
All symbols named in this ADR, VP-016, and `interface-definitions.md §GraphAgentTool`
must resolve to a declared location. Added in round-10 (F-P2A072-01+02+03 closure).

| Symbol | Canonical Location | Source of Truth | Status |
|--------|--------------------|-----------------|--------|
| `CompiledStateGraph` | `pregolya-graph/src/types.rs` | BC-2.02.001 {PC-001} | EXISTS — non-generic; `invoke(input, config)` takes/returns `serde_json::Value` |
| `CompiledStateGraph::invoke` | `pregolya-graph/src/types.rs` | BC-2.02.001 {PC-005} | EXISTS — `invoke(input: serde_json::Value, config) -> Result<serde_json::Value, PregolyaError>` |
| `CompiledStateGraph::stub_terminal` | `pregolya-graph/src/types.rs` (`#[cfg(test)]`) | VP-016 §Proof Obligations; S-1.14 §AC-014 / Task 18 | ROUTED / SPECCED — S-1.14 §AC-014 + Task 18 (round-10); `#[cfg(test)]` helper; consumed by VP-016 (BC-2.09.008 {INV-001}) in S-2.11. Signature: `pub fn stub_terminal(terminal_state: serde_json::Value) -> Arc<CompiledStateGraph>` — builds a minimal single-node graph that returns `terminal_state` when invoked. |
| `CompiledGraph<S>` | (none) | (none) | PHANTOM — eliminated. Generic form does not exist. All references replaced with `CompiledStateGraph`. |
| `GraphState` (as trait) | (none) | entities-graph.md §GraphState | PHANTOM — `GraphState` is NOT a trait. It is the composed value of all Channels (Map<ChannelName, ChannelValue>). No user-defined trait. All `S: GraphState` bounds eliminated. |
| `DynTool` | `pregolya-core/src/core/tool.rs` | interface-definitions.md §Tool | EXISTS — `invoke_dyn(&self, input: serde_json::Value) -> Result<serde_json::Value, PregolyaError>` |
| `ToolOutput` variants (`Text`, `Json`, `Error`) | `pregolya-core/src/core/tool.rs` | interface-definitions.md §Tool | EXISTS — exactly three variants: `Text(String)`, `Json(serde_json::Value)`, `Error(String)` |
| `ToolOutput::Structured` | (none) | (none) | PHANTOM — eliminated. No such variant. `invoke_dyn` returns `Result<serde_json::Value, PregolyaError>` directly. Blanket `DynTool` impl maps `Text`/`Json` → `Ok(serde_json::Value)`; `Error` → `Err(PregolyaError)`. |
| `serde_json::Value::as_value()` | (none) | (none) | PHANTOM — eliminated (VP-016 F-P2A072-01). `serde_json::Value` has no `.as_value()` method. Harness now calls `.as_object()` directly on the returned `serde_json::Value`. |
| `schemars::Schema` | `schemars` crate | interface-definitions.md §Tool, ADR-029 §Decision 1 | EXISTS — canonical schema type (corrected from `schemars::schema::RootSchema` in ADR-029 §Decision 1). |
| `schemars::schema_for!` | `schemars` crate | schemars docs | EXISTS — derive-based schema macro; caller's responsibility to invoke before `from_graph`. |
| `GraphAgentTool` | `pregolya-mcp/src/graph_tool.rs` | BC-2.09.008, ADR-029 §Decision 1 | PLANNED — SS-09, S-2.11 implementation story. Non-generic struct. |
| `GraphAgentTool::from_graph` | `pregolya-mcp/src/graph_tool.rs` | BC-2.09.008 {PRE-001}, ADR-029 §Decision 1 | PLANNED — non-generic signature: `(name, description, Arc<CompiledStateGraph>, schemars::Schema, Fn(&serde_json::Value) -> serde_json::Value) -> Self` |
| `ConcreteGraphRunner` | `pregolya-mcp/src/graph_tool.rs` | ADR-029 §Decision 3 | PLANNED — non-generic (no `<S>`); holds `Arc<CompiledStateGraph>` + `Box<dyn Fn(&serde_json::Value) -> serde_json::Value + Send + Sync>` |
| `GraphRunner` (trait) | `pregolya-mcp/src/graph_tool.rs` | ADR-029 §Decision 1 | PLANNED — `run(input, policy) -> Result<serde_json::Value, PregolyaError>` |
| `GraphToolApprovalPolicy` | `pregolya-mcp/src/graph_tool.rs` | ADR-029 §Decision 4 | PLANNED — `DenyInterrupts` (default), `ForceApproveHooks` (explicit opt-in) |
| `BoundaryApprovalHook` | `pregolya-mcp/src/graph_tool.rs` | ADR-029 §Decision 4 | PLANNED — `pub(crate)`; implements `PreToolCallHook` |
| `PreToolCallHook` | `pregolya-core/src/core/tool.rs` or `pregolya-mcp` | BC-2.05.007, ADR-018 | EXISTS — hook trait for pre-invocation decisions |
| `ToolCallPreview` | `pregolya-core` | BC-2.05.007 {PRE-003} | EXISTS — canonical type (corrected from `ToolPreview` per F-P2A057-04) |
| `ActionRisk` | `pregolya-core` | BC-2.05.006/BC-2.05.007 | EXISTS — enum with `None`/`Low`/`Medium`/`High` variants |
| `PreToolDecision` | `pregolya-core` | ADR-018, BC-2.05.007 | EXISTS — `PendingHumanApproval`, `Approve`, `Deny` variants |
| `E-MCP-010 GraphAgentInterruptDenied` | `error-taxonomy.md` | ADR-029 §Decision 5 (PO obligation) | PLANNED — PO must mint in error-taxonomy.md |
| `E-MCP-011 ForceApproveWriteBlocked` | `error-taxonomy.md` | ADR-029 §Decision 4 (PO obligation) | PLANNED — PO must mint in error-taxonomy.md |

**Eliminated phantom surfaces (F-P2A072-01+02+03):**
- `ToolOutput::Structured { value }` — 16 occurrences across cluster; no such variant exists
- `.as_value()` on `serde_json::Value` — E0599; no such method; VP-016 harness fixed
- `CompiledGraph<S>` — generic phantom; replaced with non-generic `CompiledStateGraph`
- `trait GraphState` / `S: GraphState` bounds — `GraphState` is composed state value, not a trait

## Changelog

| Version | Date | Author | Decision | Change |
|---------|------|--------|----------|--------|
| 2.1 | 2026-08-27 | architect | round-12/GAP-01-straggler | §Context: 'compiled StateGraph<S>' → 'CompiledStateGraph' (COMPILED form is CompiledStateGraph, non-generic per BC-2.02.001 {PC-001}). §Symbol Grounding CompiledStateGraph::stub_terminal row: status REQUIRES-ROUTING → ROUTED/SPECCED — S-1.14 §AC-014 + Task 18 (round-10); cross-ref §Stub Graph Obligation → §Proof Obligations (real VP-016 heading per ADR-022 real-heading rule). |
| 2.0 | 2026-08-27 | architect | round-10/F-P2A072-01+F-P2A072-02+F-P2A072-03 | TYPE-GROUNDING: `ToolOutput::Structured` phantom removed (no such variant; `invoke_dyn` returns `Result<serde_json::Value, PregolyaError>`); `CompiledGraph<S>` + `trait GraphState` phantoms removed (`CompiledStateGraph` non-generic per BC-2.02.001; `GraphState` not a trait per entities-graph.md); `from_graph<S>` redesigned as non-generic with explicit `input_schema: schemars::Schema` and `extract_output: Fn(&serde_json::Value) -> serde_json::Value`; Decision 2 pipeline updated (no `from_value::<S>` step); §Symbol Grounding subsection added. PO/story-writer handoffs provided. |
| 1.9 | 2026-08-26 | architect | round-8/F-P2A069-02+F-P2A069-01 | F-P2A069-02 MED: §Decision 2 pseudocode, §Decision 2 prose paragraph, §Decision 5 Error Routing Table — three occurrences of "runs inside invoke_dyn" corrected to "runs inside ConcreteGraphRunner<S>::run; failure surfaced through invoke_dyn." GraphAgentTool is non-generic (runner: Arc<dyn GraphRunner>; S is erased); invoke_dyn cannot name or monomorphize S; from_value::<S> must live in ConcreteGraphRunner<S>::run where S is statically known — consistent with §Decision 3 canonical seam. Routing decision (isError: true, NOT JSON-RPC -32602) UNCHANGED. F-P2A069-01 HIGH: parallel VP-016 §Realizability-Trace harness rewrite (complete input, vacuous-Err guard) in same burst. |
| 1.8 | 2026-08-26 | architect | round-7/F-P2A066-01+F-P2A067-01 | F-P2A067-01 HIGH: §Decision 2 pseudocode, §Decision 2 prose, §Decision 5 Error Routing Table — three occurrences of phantom `E-MCP-004 McpInvalidArguments` removed (E-MCP-004 is ToolNotFound per BC-2.09.002 {PC-008}; schema-validation failure is a wire-protocol JSON-RPC -32602 response per BC-2.09.007 {PC-005}/BC-2.09.008 EC-001; no PregolyaError or E-MCP-* code raised). F-P2A066-01 HIGH (partial): §Decision 3 canonical seam statement added. |
| 1.7 | 2026-08-26 | architect | round-6/O-063-02 | §Decision 4 fail-closed guarantee: `GraphAgentTool::invoke` → `GraphAgentTool::invoke_dyn` (O-063-02 OBS — canonical DynTool dispatch method is invoke_dyn; one bare occurrence in §Decision 4 §DenyInterrupts fail-closed guarantee paragraph). |
| 1.6 | 2026-08-26 | architect | P2A-062 | F-062-01 HIGH: §Decision 4 fail-closed guarantee — VP-016 attribution corrected; binary interrupt invariant ({INV-002}) → Red-Gate test set (BC-2.09.008 TV-002/TV-005, S-2.11 AC-024); VP-016 proves STATE-ISOLATION ({INV-001}). F2 MED: §Decision 2 + §Decision 5 Error Routing Table — post-schema deserialize failure corrected to isError: true (BC-2.09.008 {PC-003}/EC-002), not -32602 protocol error. F3 MED: Tool::input_schema() → Tool::schema() (canonical method). F-P2A-061-02 MED: §Consequences Error Code Obligation — E-MCP-011 ForceApproveWriteBlocked added, cross-referencing §Decision 4. LOW schemars: schemars::schema::RootSchema → schemars::Schema. |
| 1.5 | 2026-08-26 | state-manager | P2A-059-records | F-P2A-059-01 LOW (records-tier): §Decision 5 E-MCP-010 message-template cell — trailing period dropped so ADR cell matches error-taxonomy.md verbatim. 1-character literal alignment. No semantic changes. RECORDS-ONLY micro-burst per TD-RECORDS-MICRO-BURST-001. |
| 1.4 | 2026-08-26 | architect | P2A-058 | F-058-02 MED: E-MCP-010 message template remedy corrected in §Decision 5 — dropped "or register with GraphToolApprovalPolicy::ForceApproveHooks if read-only" clause (ForceApproveHooks cannot resolve E-MCP-010; node-level interrupt() causes RunStatus::Interrupted regardless of approval policy); corrected remedy text: "restructure the graph so it does not call interrupt() during a synchronous tools/call invocation." RetryHint rationale updated to remove ForceApproveHooks reference. F-058-05 LOW: E-MCP-011 message-template wording — two illustrative variant forms exist (table vs code sketch); illustrative-forms note added in §Decision 4 after E-MCP-011 table; error-taxonomy.md is the authoritative message source. |
| 1.3 | 2026-08-26 | architect | P2A-057-adjudication | F-057-01 CRITICAL: fail-open None fixed — preview.action_risk is Option<ActionRisk>; replaced if/else with match on Option; None (undeclared) now fails closed to Deny per BC-2.05.006 EC-004/{INV-002}. F-057-04 MED: ToolPreview→ToolCallPreview in ForceApproveHooks code sketch (canonical type per BC-2.05.007 {PRE-003}). F-057-02 HIGH: removed incorrect claim that E-MCP-011 fires before E-MCP-010; clarified in rationale, enum docs, and Error Routing Table that the codes are distinct independently-surfacing paths: E-MCP-010 fires only when node-level interrupt() causes RunStatus::Interrupted (graph parks); E-MCP-011 is a diagnostic from BoundaryApprovalHook ActionRisk gate path (graph continues to terminal — NOT E-MCP-010). New BoundaryApprovalHook Deny row added to Error Routing Table. E-MCP-011 message template updated to reflect None-or->=Medium condition. |
| 1.2 | 2026-08-26 | architect | SEC-review-adjudication | SEC-007: ForceApproveHooks BoundaryApprovalHook corrected to pass Deny and all non-PendingHumanApproval decisions through UNCHANGED; only PendingHumanApproval is overridden to Approve. SEC-006: runtime ActionRisk enforcement added — BoundaryApprovalHook checks preview.action_risk; ActionRisk >= Medium returns Deny (CRITICAL log) instead of Approve; E-MCP-011 ForceApproveWriteBlocked specified for PO. SEC-005: error-path STATE-ISOLATION convention added — node error messages must exclude checkpoint/run/thread IDs; sanitization pass applied before content[0].text. SEC-001: explicit invariant that Tool implementations MUST NOT embed credential material in ToolOutput; framework does not sanitize success-path result_text. SEC-008: extract_output panic contract firmed — caught by server-handler UnwindSafe boundary; static isError 'internal error' message; server continues serving. |
| 1.1 | 2026-08-26 | architect | E-code-correction | Error code corrected throughout: E-MCP-010 (GraphAgentInterruptDenied) — prior code was already taken by McpContentUnsupported (minted 2026-07-22); all body, routing-table, enum-comment, and §Error Code occurrences updated. {INV-STATE-ISOLATION} invariant tag → {INV-001} (stable BC-2.09.008 numeric anchor per product-owner). |
| 1.0 | 2026-08-26 | architect | GAP-01/HS-C-001 | Initial ADR: GraphAgentTool wrapping contract, mcp::graph_tool module, pregolya-mcp→pregolya-graph dep edge, BC-2.09.008 assignment, VP-016 proptest P1, E-MCP-010 GraphAgentInterruptDenied recommendation. Human-approved v1 scope addition. |
