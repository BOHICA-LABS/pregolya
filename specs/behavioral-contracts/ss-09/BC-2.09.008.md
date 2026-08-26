---
document_type: behavioral-contract
level: L3
bc_id: BC-2.09.008
version: "1.3"
status: draft
lifecycle_status: draft
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-09
capability: CAP-021
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-26T00:00:00Z
changelog:
  - "1.0 (GAP-01/ADR-029/2026-08-26): Initial — StateGraph-as-MCP-Tool wrapping contract; GraphAgentTool; mcp::graph_tool module in pregolya-mcp; inputSchema derivation via schemars; STATE-ISOLATION invariant {INV-001} (VP-016 proptest P1 proof target); fail-closed DenyInterrupts default; ForceApproveHooks explicit opt-in; E-MCP-010 GraphAgentInterruptDenied (ADR-029 §Decision 5; note: ADR-029 body incorrectly referenced E-MCP-006 — that code is taken by McpContentUnsupported; PO-authoritative mint is E-MCP-010). Human-approved v1 scope addition 2026-08-26 (GAP-01/HS-C-001)."
  - "1.1 (ADR-029-sec-hardening/SEC-006/007/008/005/001/2026-08-26): Security hardening per ADR-029 §Decision 3/4/5. SEC-007: {PC-006} rewritten — ForceApproveHooks overrides ONLY PreToolDecision::PendingHumanApproval (subject to {INV-004} ActionRisk check); PreToolDecision::Deny and other decision variants pass through unchanged; ForceApproveHooks does not override security-based Deny decisions. SEC-006: {INV-004} body replaced — BoundaryApprovalHook enforces read-only restriction at runtime via ActionRisk check; PendingHumanApproval overridden to Approve only when action_risk < ActionRisk::Medium; otherwise Deny + CRITICAL log at mcp.graph_tool.force_approve_write_blocked + E-MCP-011 ForceApproveWriteBlocked; EC-009 and TV-008 added. SEC-005: {INV-001} extended — STATE-ISOLATION guarantee covers error paths; two unconditional sanitization passes applied to isError:true responses (redact_credentials + sanitize_internal_ids UUID v4 removal); node implementations must exclude internal IDs at authoring site; TV-009 added. SEC-001: {INV-005} added — extract_output closure must not select credential-bearing fields; framework does not sanitize success-path extract_output result; caller obligation per DI-010; TV-010 added. SEC-008: EC-010 added — extract_output panic caught via UnwindSafe boundary; static 'internal error' response; server continues serving; TV-011 added."
  - "1.2 (ADR-029-v1.3/F-057-01/F-057-02/F-057-05/2026-08-26): Round-2 security fixes per ADR-029 §Decision 1, §Decision 4 architect adjudication. F-057-01 ({INV-004}): ActionRisk gate is now fail-closed on None — preview.action_risk (Option<ActionRisk> per BC-2.05.007 {PRE-003}) is None (undeclared, fail-closed per BC-2.05.006 EC-004/{INV-002}) OR Some(r >= Medium) → Deny + E-MCP-011; Some(r < Medium) → Approve. EC-009 heading updated to cover both None and Some(High) cases; TV-012 added for the None/undeclared path; note that both None and Some(High) must be tested. F-057-01 ({PC-006}): None case appended — None (undeclared) fails closed to Deny identically to Some(>= Medium), consistent with BC-2.05.006 EC-004/{INV-002}. F-057-02 ({PC-005}): BoundaryApprovalHook::Deny sub-bullet corrected — graph CONTINUES executing after Deny; if valid terminal reached, {PC-004} applies (Ok); if error terminal reached, Err carries graph's OWN error (NOT E-MCP-010); closing sentence 'In both cases invoke_dyn returns Err(E-MCP-010)' removed. F-057-02 ({INV-002}): binary interrupt invariant scoped to node-level interrupt() parking (RunStatus::Interrupted) only; BoundaryApprovalHook::Deny path explicitly excluded (graph continues to own terminal). EC-005 is the authority for the Deny-path behavior and was already correct — {PC-005} and {INV-002} reconciled to match EC-005. F-057-05: §Story Anchor set to S-2.11 (sibling BCs BC-2.09.006/007 both anchor S-2.11; S-2.11 covers BC-2.09.008)."
  - "1.3 (P2A-058/F-058-02/F-058-06/2026-08-26): F-058-02: E-MCP-010 ForceApproveHooks recovery clause dropped from {PC-005} and EC-004 message strings — node-level interrupt() fires E-MCP-010 under ForceApproveHooks identically to DenyInterrupts; ForceApproveHooks cannot resolve E-MCP-010 (interrupt() parking is orthogonal to tool approval policy); corrected remedy: restructure the graph so it does not call interrupt() during a synchronous tools/call invocation. F-058-06 (records): changelog v1.2 citation corrected from §Decision-1/§Decision-4 to §Decision 1, §Decision 4 per ADR-022 §Decision 5 citation conventions."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-021
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-029-graph-agent-tool-wrapping.md
input-hash: "1b83a93"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
behavioral_contracts:
  - BC-2.09.006
  - BC-2.09.007
  - BC-2.09.008
verification_properties:
  - VP-016
---

# BC-2.09.008: StateGraph-as-MCP-Tool Wrapping (GraphAgentTool; mcp::graph_tool)

## Description

`GraphAgentTool` (in `mcp::graph_tool`, `pregolya-mcp`) wraps a compiled `StateGraph<S>`
as a `DynTool` so that it can be registered in the `ToolRegistry` and exposed to external
MCP clients via the existing `tools/list` advertisement (BC-2.09.006) and `tools/call`
execution (BC-2.09.007) paths. The contract specifies three surfaces: (1) construction —
`from_graph` derives the MCP `inputSchema` from `S: schemars::JsonSchema`; (2) output
isolation — the caller-supplied `extract_output` closure is the ONLY path through which
data exits the graph run (STATE-ISOLATION invariant {INV-001}); (3) interrupt policy —
`GraphToolApprovalPolicy::DenyInterrupts` (default, fail-closed) converts any internal
graph interrupt to `Err(E-MCP-010)`; `ForceApproveHooks` is an explicit opt-in that
overrides `PreToolCallHook` approval decisions only.

## Preconditions

1. {PRE-001} A compiled `StateGraph<S>` is available as `Arc<CompiledGraph<S>>` where
   `S: GraphState + for<'de> serde::Deserialize<'de> + schemars::JsonSchema + Send + Sync + 'static`.
2. {PRE-002} The caller provides an `extract_output: Fn(&S) -> serde_json::Value + Send + Sync + 'static`
   closure that selects the fields of `S` to expose to external MCP clients. The closure
   is the STATE-ISOLATION boundary; fields NOT selected by the closure are structurally
   excluded from the output.
3. {PRE-003} The caller provides a stable `name: impl Into<String>` and a `description: impl Into<String>`
   for the tool advertisement; `name` is the public MCP tool name and must be unique within
   the `ToolRegistry` it is registered in (BC-2.08.010 `DuplicateToolName` constraint).

## Postconditions

1. {PC-001} `GraphAgentTool::from_graph(name, description, graph, extract_output)` constructs
   a `GraphAgentTool`. At construction time, `schemars::schema_for!(S)` is called to derive
   the `RootSchema` for `S`. This schema is stored internally and returned by `DynTool::schema()`
   for advertisement in `tools/list` responses per BC-2.09.006 {PC-002}.
2. {PC-002} The constructed `GraphAgentTool` implements `DynTool` (object-safe dispatch
   seam per ADR-005 §Adjacent Trait Object-Safety Adjudications) and may be registered in
   a `ToolRegistry` via the standard registration API. After registration, the MCP server
   advertises the tool in `tools/list` responses per BC-2.09.006 {PC-002} — name,
   description, and inputSchema are exposed verbatim from the `GraphAgentTool` fields.
3. {PC-003} On `tools/call` invocation: the `mcp::server` validates the call arguments
   against `DynTool::schema()` per BC-2.09.007 {PC-005}; if validation fails, the server
   returns JSON-RPC `-32602` ("Invalid arguments for tool '...': <schema_error>") before
   `invoke_dyn` is called. If schema validation passes but `serde_json::from_value::<S>(arguments)`
   fails (e.g., custom serde validation logic rejects a structurally-valid JSON object),
   `GraphAgentTool::invoke_dyn` returns `Err(PregolyaError { .. })`; the server surfaces
   this as `isError: true` per BC-2.09.007 {PC-003}; credential redaction applies
   per {INV-003}.
4. {PC-004} On successful graph execution: `GraphRunner::run` runs the graph to a terminal
   state, then calls `extract_output(&final_state)` and returns ONLY the resulting
   `serde_json::Value`. `GraphAgentTool::invoke_dyn` returns
   `Ok(ToolOutput::Structured { value: extract_output_result })`.
   The server serializes this per BC-2.09.007 {PC-002} (`result_text =
   serde_json::to_string(&extract_output_result)`). If `extract_output` returns
   `Value::Null`, `result_text = "null"` per BC-2.09.007 {PC-002}; no error raised.
5. {PC-005} On graph interrupt under `GraphToolApprovalPolicy::DenyInterrupts` (default):
   - **Node-level `interrupt()`:** `GraphRunner::run` detects `RunStatus::Interrupted` and
     returns `Err(PregolyaError { code: "E-MCP-010", category: EXEC, message: "graph agent
     tool invocation interrupted at MCP boundary: HITL approval not supported for synchronous
     tools/call; restructure the graph so it does not call interrupt() during a synchronous
     tools/call invocation", retry_hint: Never, .. })`.
     The interrupted run is NOT persisted to durable checkpoint.
   - **`PreToolCallHook::PendingHumanApproval`:** `BoundaryApprovalHook` converts
     `PendingHumanApproval` → `Deny`; the tool is not invoked; the graph CONTINUES executing.
     If the graph reaches a valid terminal state, {PC-004} applies
     (`Ok(ToolOutput::Structured)`). If the graph reaches an error terminal,
     `GraphRunner::run` returns `Err(PregolyaError)` with the graph's OWN error (NOT
     `E-MCP-010`). `E-MCP-010` is NOT raised on the `BoundaryApprovalHook::Deny` path.
6. {PC-006} Under `GraphToolApprovalPolicy::ForceApproveHooks`: `BoundaryApprovalHook`
   overrides ONLY `PreToolDecision::PendingHumanApproval` to `Approve` (subject to the
   `ActionRisk` check in {INV-004}). `PreToolDecision::Deny` and all other decision variants
   pass through to the graph UNCHANGED. `ForceApproveHooks` does not override security-based
   `Deny` decisions. Node-level `interrupt()` calls STILL produce `Err(E-MCP-010)` — the
   `ForceApproveHooks` policy does NOT override node-level interrupt semantics. {INV-002}
   holds under `ForceApproveHooks`. `preview.action_risk` is `Option<ActionRisk>`; `None`
   (undeclared) fails closed to `Deny` identically to `Some(>= Medium)` — undeclared risk
   requires the highest gate, consistent with BC-2.05.006 EC-004/{INV-002}.

## Invariants

- {INV-001} **STATE-ISOLATION (VP-016 proof target):** `GraphAgentTool::invoke_dyn` on
  successful graph completion returns ONLY the `serde_json::Value` produced by
  `extract_output(&final_state)`. The following are NEVER included in the output unless
  `extract_output` explicitly constructs a `Value` containing them:
  - Any checkpoint ID or durable storage key
  - Any run ID or internal execution identifier
  - Any intermediate node output accumulated during the run
  - Any message history or tool call history captured in graph channels
  - Any internal graph metadata or execution statistics
  The `extract_output` closure is the sole data-exit path at the `GraphRunner` boundary.
  DI-010 Credential Opacity is a structural corollary: credentials in input fields,
  intermediate fields, or model reasoning cannot appear in the output if `extract_output`
  is correctly scoped to output fields only.
  The STATE-ISOLATION guarantee extends to all output paths including error paths. On any
  `isError:true` MCP response from a `GraphAgentTool` invocation, `content[0].text` must
  not contain checkpoint IDs, run IDs, or thread IDs (UUID v4 format). The framework
  applies two unconditional sanitization passes: (1) `redact_credentials`, (2)
  `sanitize_internal_ids` (UUID v4 removal). Node implementations must not rely on
  framework sanitization for errors they author — error messages must exclude internal IDs
  at the authoring site.

- {INV-002} **Binary interrupt invariant (fail-closed default):** Exactly one of two
  outcomes is possible for any `GraphAgentTool::invoke_dyn` call under
  `GraphToolApprovalPolicy::DenyInterrupts`:
  - Terminal state reached → `Ok(ToolOutput::Structured { value: extract_output_result })`
  - Node-level `interrupt()` parking (`RunStatus::Interrupted`) → `Err(E-MCP-010)`
  The `BoundaryApprovalHook::Deny` path does NOT raise `E-MCP-010`; the graph continues
  to its own terminal (`Ok` per `{PC-004}` or the graph's own `Err`). The binary interrupt
  invariant (`interrupt()` → `Err(E-MCP-010)`) applies to node-level `interrupt()` PARKING
  (`RunStatus::Interrupted`) only. There is NO `Ok` code path that returns a result when
  the graph reached `RunStatus::Interrupted`. `ForceApproveHooks` overrides only the
  `PreToolCallHook` path; the node-level interrupt invariant holds under both policies.

- {INV-003} **Mandatory credential redaction (DI-010):** All `isError: true` paths from
  `GraphAgentTool` invocations — including `E-MCP-010` interrupt-denied errors and any
  `Err(PregolyaError)` propagated from graph execution — pass through
  `pregolya_mcp::sanitize::redact_credentials` before the MCP server populates
  `content[0].text`. This obligation is unconditional per BC-2.09.007 {INV-003}. Only
  `PregolyaError::message` is used as the text source (never `.source()`, `Debug`, or
  `Display` output).

- {INV-004} **`ForceApproveHooks` ActionRisk runtime gate:**
  `ForceApproveHooks` is appropriate ONLY for read-only tool graphs (graphs composed
  exclusively of tools with `ActionRisk::ReadOnly` or `ActionRisk::Low`). The
  `ForceApproveHooks` policy's `BoundaryApprovalHook` enforces the read-only restriction
  at runtime. Before overriding `PendingHumanApproval` → `Approve`, the hook checks
  `preview.action_risk` (`Option<ActionRisk>` per BC-2.05.007 {PRE-003}). If
  `preview.action_risk` is `None` (undeclared — fail-closed per BC-2.05.006 EC-004/{INV-002})
  OR `Some(r)` where `r >= ActionRisk::Medium`, the hook returns `Deny` (with a
  CRITICAL-level structured log at key `mcp.graph_tool.force_approve_write_blocked`) and
  emits `E-MCP-011 ForceApproveWriteBlocked`; the tool is NOT invoked. If
  `preview.action_risk` is `Some(r)` where `r < ActionRisk::Medium`, the override proceeds
  to `Approve`.

- {INV-005} **`extract_output` closure credential opacity (caller obligation):**
  The `extract_output` closure provided to `GraphAgentTool::from_graph` MUST NOT select
  credential-bearing fields of `GraphState S` for inclusion in the output
  `serde_json::Value`. The framework does not apply credential sanitization to the
  success-path result of `extract_output`. Caller obligation, auditable at registration
  (DI-010).

## Edge Cases

### EC-001: JSON schema validation failure — args rejected before invoke_dyn
**Scenario:** tools/call arguments do not conform to the derived inputSchema for `S` (e.g.,
a required field is absent, or a field has the wrong JSON type).
**Expected behavior:** `mcp::server` validates call arguments against `DynTool::schema()`
per BC-2.09.007 {PC-005} BEFORE calling `invoke_dyn`. Server returns JSON-RPC
`{ "code": -32602, "message": "Invalid arguments for tool '<name>': <schema_error>" }`.
`GraphAgentTool::invoke_dyn` is never called; the graph is not invoked.

### EC-002: Deserialization failure after schema validation passes
**Scenario:** Arguments pass JSON Schema validation but `serde_json::from_value::<S>(args)`
fails due to custom `serde::Deserialize` logic (e.g., an out-of-range numeric field not
captured by the JSON Schema).
**Expected behavior:** `GraphAgentTool::invoke_dyn` returns `Err(PregolyaError { .. })`.
`mcp::server` surfaces this as `isError: true` per BC-2.09.007 {PC-003}. Credential
redaction applies per {INV-003}.

### EC-003: Graph execution error — node returns Err(PregolyaError)
**Scenario:** Graph node logic returns `Err(PregolyaError)` (e.g., an LLM provider call
fails with E-PROV-002 ProviderTimeout).
**Expected behavior:** `GraphRunner::run` propagates the `Err(PregolyaError)`.
`GraphAgentTool::invoke_dyn` returns the error. `mcp::server` surfaces as `isError: true`
with redacted `PregolyaError::message` per BC-2.09.007 {PC-003} and {INV-003}. The
`E-MCP-010` code is NOT raised; the original graph error code is propagated.

### EC-004: Node-level interrupt() under DenyInterrupts (default)
**Scenario:** A graph node calls `interrupt()` during execution; `approval_policy =
DenyInterrupts` (default, constructed via `GraphAgentTool::from_graph` without `.with_approval_policy`).
**Expected behavior:** `GraphRunner::run` detects `RunStatus::Interrupted`;
returns `Err(PregolyaError { code: "E-MCP-010", category: EXEC, message: "graph agent tool
invocation interrupted at MCP boundary: HITL approval not supported for synchronous
tools/call; restructure the graph so it does not call interrupt() during a synchronous
tools/call invocation", retry_hint: Never, .. })`.
The interrupted run is NOT persisted to durable checkpoint. `mcp::server` surfaces as
`isError: true`. Credential redaction applies per {INV-003}. {INV-002} holds.

### EC-005: PreToolCallHook PendingHumanApproval under DenyInterrupts
**Scenario:** A tool call inside a node triggers `PreToolCallHook::PendingHumanApproval`;
`BoundaryApprovalHook` is active because `approval_policy = DenyInterrupts`.
**Expected behavior:** `BoundaryApprovalHook::pre_invoke` returns `Deny { reason:
"HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY" }`. The tool is NOT invoked. The node receives
`ToolOutput::Error("HITL_NOT_SUPPORTED_AT_MCP_BOUNDARY")`. The graph continues executing;
if this denial causes the graph to reach an error terminal state, `GraphRunner::run`
returns `Err(PregolyaError { .. })` for that terminal error, surfaced as `isError: true`.
If the graph reaches a valid terminal state despite the denial, {PC-004} applies. {INV-002}
holds.

### EC-006: ForceApproveHooks + node-level interrupt() — ForceApproveHooks does NOT apply
**Scenario:** `approval_policy = ForceApproveHooks`; a `PreToolCallHook` returns
`PendingHumanApproval` (overridden to `Approve`); later in the same run a node calls
`interrupt()`.
**Expected behavior:** The `PendingHumanApproval` is overridden to `Approve` — the tool
proceeds. The subsequent `interrupt()` call causes `RunStatus::Interrupted` →
`Err(E-MCP-010)`. `ForceApproveHooks` does NOT override node-level interrupt semantics;
the binary invariant {INV-002} holds even under `ForceApproveHooks`.

### EC-007: STATE-ISOLATION — extra fields in GraphState not in extract_output
**Scenario:** `GraphState S` has fields `answer: String`, `internal_checkpoint_id: String`,
`accumulated_messages: Vec<serde_json::Value>`. `extract_output = |s: &S| json!({ "answer": s.answer })`.
Graph runs successfully to terminal state.
**Expected behavior:** `ToolOutput::Structured { value: json!({"answer": "<final>"}) }`.
The fields `internal_checkpoint_id` and `accumulated_messages` do NOT appear in the output.
{INV-001} STATE-ISOLATION holds. VP-016 proptest verifies this property over arbitrary
`S` instances.

### EC-008: extract_output returns Value::Null
**Scenario:** `extract_output = |_| Value::Null`. Graph runs successfully.
**Expected behavior:** `ToolOutput::Structured { value: Value::Null }` → `result_text = "null"`
per BC-2.09.007 {PC-002} result_text selection rule. Server responds with
`{ "content": [{ "type": "text", "text": "null" }], "isError": false }`. No error raised.
{PC-004} holds. {INV-001} holds (Null output is a valid extract_output result).

### EC-009: ForceApproveHooks + ActionRisk>=Medium or None — E-MCP-011 emitted, tool not invoked
**Scenario:** `approval_policy = ForceApproveHooks`; a `PreToolCallHook` returns
`PendingHumanApproval` for a tool whose `preview.action_risk` is either `None`
(un-annotated tool, fail-closed) OR `Some(r)` where `r >= ActionRisk::Medium`
(e.g., a write-class tool with `ActionRisk::High`).
**Expected behavior:** `BoundaryApprovalHook` checks `preview.action_risk` before
overriding. Because `action_risk` is `None` (undeclared, fails closed) or
`>= ActionRisk::Medium`, the hook returns `Deny` and emits `E-MCP-011
ForceApproveWriteBlocked` with a CRITICAL-level structured log at key
`mcp.graph_tool.force_approve_write_blocked`. The tool is NOT invoked. {INV-004} enforces
this gate at runtime; the graph continues executing with the `Deny` result but the tool
never executes. Both the `None` case (un-annotated tool → `Deny` + `E-MCP-011`) and the
`Some(High)` case must be tested.

### EC-010: extract_output closure panics (caller contract violation)
**Scenario:** The `extract_output` closure provided to `GraphAgentTool::from_graph`
panics during execution after graph completion (programming error in the caller-supplied
closure).
**Expected behavior:** The `mcp::server` handler catches the panic via `UnwindSafe`
boundary; response is `isError:true`, `content[0].text == "internal error"` (static; no
panic message, backtrace, or internal state forwarded); server continues serving subsequent
`tools/call` requests. A subsequent valid `tools/call` to a different (non-panicking)
tool still succeeds.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `from_graph("agent", "desc", graph, `\|`s`\|` json!({"result": s.result}))`; tools/call valid args; graph runs to terminal `result: "ok"` | `{ "content": [{ "type": "text", "text": "{\"result\":\"ok\"}" }], "isError": false }` | Happy-path STATE-ISOLATION (EC-007) |
| TV-002 | Same setup; graph node calls `interrupt()` under DenyInterrupts | `{ "content": [{ "type": "text", "text": "graph agent tool invocation interrupted at MCP boundary: ..." }], "isError": true }` | Interrupt denied (EC-004) |
| TV-003 | tools/call with args missing required field for `S`'s JSON Schema | JSON-RPC `{ "code": -32602, "message": "Invalid arguments for tool '...': ..." }` | Schema validation (EC-001) |
| TV-004 | `S` has `answer`, `internal_checkpoint_id`, `messages`; `extract_output` selects only `answer`; graph succeeds | Response contains ONLY `"answer"` key; `internal_checkpoint_id` and `messages` absent | STATE-ISOLATION (EC-007, {INV-001}) |
| TV-005 | `ForceApproveHooks` policy; PreToolCallHook returns `PendingHumanApproval`; later node calls `interrupt()` | `isError: true`, E-MCP-010 message — interrupt not suppressed by ForceApproveHooks | EC-006, {INV-002} |
| TV-006 | `extract_output = `\|`_`\|` Value::Null`; graph succeeds | `{ "content": [{ "type": "text", "text": "null" }], "isError": false }` | Null output valid (EC-008) |
| TV-007 | Graph returns `Err(PregolyaError { message: "failed: sk-ant-abc123XYZXYZXYZ12345678901234567", .. })` | `isError: true`, message contains `<redacted>` not the key material | Credential redaction ({INV-003}) |
| TV-008 | `approval_policy = ForceApproveHooks`; `PreToolCallHook` returns `PendingHumanApproval` for tool with `action_risk = ActionRisk::High` | `isError: true`, E-MCP-011 ForceApproveWriteBlocked message; tool NOT invoked; CRITICAL log emitted at `mcp.graph_tool.force_approve_write_blocked` | ActionRisk runtime gate — Some(High) path (EC-009, {INV-004}) |
| TV-012 | `approval_policy = ForceApproveHooks`; `PreToolCallHook` returns `PendingHumanApproval` for tool with `action_risk = None` (un-annotated tool) | `isError: true`, E-MCP-011 ForceApproveWriteBlocked message; tool NOT invoked; CRITICAL log emitted at `mcp.graph_tool.force_approve_write_blocked` (None fails closed identically to Some(>= Medium)) | ActionRisk runtime gate — None/undeclared path (EC-009, {INV-004}) |
| TV-009 | Graph node returns `Err(PregolyaError { message: "operation failed for run <example-run-id>", .. })` | `isError: true`; `content[0].text` does NOT contain `<example-run-id>` (UUID removed by `sanitize_internal_ids`) | Error-path UUID sanitization ({INV-001}) |
| TV-010 | `extract_output = `\|`s: &S`\|` json!({ "api_key": s.api_key })`; graph succeeds with `api_key = "sk-abc123"` in state | `isError: false`; `content[0].text` contains `"api_key":"sk-abc123"` (framework does NOT sanitize success-path `extract_output` result) | `extract_output` credential opacity boundary test ({INV-005}) — no post-hoc stripping |
| TV-011 | `extract_output = `\|`_`\|` panic!("boom")`; graph succeeds to terminal state; server receives `tools/call` | `{ "content": [{ "type": "text", "text": "internal error" }], "isError": true }`; a subsequent `tools/call` to a different (non-panicking) tool returns `isError: false` | extract_output panic recovery (EC-010) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-016 | STATE-ISOLATION: `ToolOutput` contains only `extract_output`-selected fields; no internal graph state, checkpoint IDs, message history, or metadata in output | proptest P1 — generate arbitrary `S` instances with extra fields; verify ONLY selected fields appear in invoke result | Phase 3 |

## Related BCs

- BC-2.09.006 — depends on: `tools/list` advertisement path; `GraphAgentTool` registers in `ToolRegistry` and is advertised per BC-2.09.006 {PC-002}; inputSchema derived at `from_graph` time is the value advertised
- BC-2.09.007 — depends on: `tools/call` invocation path; `GraphAgentTool::invoke_dyn` is called by the `mcp::server` dispatch loop; argument schema validation ({PC-005}), isError semantics ({PC-002}/{PC-003}), credential redaction ({INV-003}) all apply
- BC-2.05.001 — related to: node-level `interrupt()` machinery; `RunStatus::Interrupted` detection per BC-2.05.001 is the trigger for the E-MCP-010 error path ({PC-005})
- BC-2.05.007 — related to: `BoundaryApprovalHook` implements `PreToolCallHook`; `Deny { reason }` path per BC-2.05.007 {PC-002} is used for the DenyInterrupts `PendingHumanApproval` conversion (EC-005)

## Architecture Anchors

- `pregolya-mcp/src/graph_tool.rs` (`mcp::graph_tool`) — `GraphAgentTool` struct implementing `DynTool`; `GraphToolApprovalPolicy` enum; `GraphRunner` type-erased trait; `BoundaryApprovalHook` internal struct; `from_graph` constructor; inputSchema derivation; `extract_output` state-isolation enforcement; E-MCP-010 interrupt-denied error path (ADR-029 §Decision 1, ADR-029 §Decision 2, ADR-029 §Decision 3, ADR-029 §Decision 4, ADR-029 §Decision 5)
- `pregolya-mcp/src/sanitize.rs` (`mcp::sanitize`) — `redact_credentials` function shared with `mcp::server` per BC-2.09.007 {INV-003}
- `pregolya-mcp/src/registry.rs` — `ToolRegistry` into which `GraphAgentTool` is registered

## Story Anchor

S-2.11

## VP Anchors

- VP-016 ({INV-001} STATE-ISOLATION proof target — proptest P1, `graph_agent_tool_state_isolation` harness fn, Phase 3)

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-021 |
| Capability Anchor Justification | CAP-021 ("MCP Server Role (Expose Registered Tools as MCP Server Endpoint)") per capabilities-p1-p2.md §CAP-021 — this BC specifies how a pregolya `StateGraph<S>` becomes a registered MCP tool, completing the MCP server role surface: graphs are the primary agent artifacts in pregolya, and exposing them as MCP tools is the core "expose registered tools" behavior CAP-021 defines for external LLM orchestrators |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — `GraphAgentTool::from_graph` returns a value, not `Err`; validation errors at construction time are caught by {PRE-001}/{PRE-002} bounds), DI-010 (Credential Opacity — {INV-001} STATE-ISOLATION structurally prevents credential-bearing internal state from leaking; {INV-003} redact_credentials applies to all error paths), DI-014 (Error Propagation — graph execution errors propagate as `Err`, not silent `Ok(empty)`; interrupt → `Err(E-MCP-010)` not `Ok(null)`) |
| Architecture ADR | ADR-029 (GraphAgentTool wrapping; `mcp::graph_tool` module; fail-closed interrupt policy; E-MCP-010 error code; VP-016 proptest P1) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration), P (property-based: VP-016 proptest) |
| Module | pregolya-mcp (`mcp::graph_tool`) |
| Error Codes | E-MCP-010 GraphAgentInterruptDenied (EXEC, broken, Never) — minted by this BC per ADR-029 §Decision 5; note: ADR-029 body incorrectly referenced code number E-MCP-006 (already taken by McpContentUnsupported, minted burst-240); PO-authoritative mint is E-MCP-010 as the next available MCP namespace code |
