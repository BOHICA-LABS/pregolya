---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-26T00:00:00Z
phase: 2
domain: C
domain_name: Flowloom Embedding Host
id: HS-C-001
title: "Flowloom Embedding Host — Full-Stack Agent Integration (MCP In/Out, HITL, Checkpoint, Streaming, Isolation)"
category: integration-boundaries
must_pass: true
priority: must-pass
origin: flowloom-embedding
behavioral_contracts:
  - BC-2.09.001
  - BC-2.09.004
  - BC-2.09.005
  - BC-2.09.006
  - BC-2.09.007
  - BC-2.05.007
  - BC-2.05.004
  - BC-2.05.001
  - BC-2.04.001
  - BC-2.04.005
  - BC-2.04.006
  - BC-2.06.001
  - BC-2.06.002
  - BC-2.12.003
  - BC-2.12.006
  - BC-2.03.001
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "b0141af"
traces_to: .factory/specs/prd.md
lifecycle_status: active
introduced: v1.0.0-phase-2
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
epic_id: N/A
coverage_areas:
  - mcp
  - tools
  - hitl
  - checkpoint_resume
  - streaming
  - graph_execution
  - server
  - tenancy
coverage_gap_pending:
  - "HS-C-001-GAP-01: No BC specifies that a StateGraph/agent can be wrapped as a Tool and registered in the ToolRegistry so that it appears as an MCP-advertised tool. BC-2.09.006 and BC-2.09.007 cover the MCP protocol layer for REGISTERED TOOLS but do not specify the StateGraph→Tool wrapping contract. Check 5 of this scenario is CONTINGENT on resolution of this gap. Surfaced to orchestrator for product-owner adjudication."
changelog:
  - "1.0 (initial, 2026-08-26): HS-C-001 authored for Flowloom embedding use case. Seven-primitive traceability verified. Coverage gap HS-C-001-GAP-01 (StateGraph→Tool wrapping absent) surfaced."
---

# Holdout Scenario HS-C-001: Flowloom Embedding Host — Full-Stack Agent Integration

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
>
> **NOTE:** Check 5 of this scenario (agent exposed as MCP tool) is marked **CONTINGENT**
> pending resolution of a surfaced coverage gap. See the Behavioral Contract Linkage table
> and the product-owner deliverable note at the end of this file. The evaluator must still
> attempt check 5 and record the result; a failure on check 5 alone does not block the
> overall must-pass threshold if the gap is acknowledged as unresolved.

---

## Scenario

An external host registers an agent with the runtime, connects the agent to an external
capability server, exercises write-gated approval, suspends and resumes a durable run,
verifies streaming correlation, exposes the agent outward via the server's tool interface,
and confirms that two simultaneous runs for different tenants do not bleed state.

**Given:**
- A stand-in external MCP server is running with exactly two tools: a read-classed tool
  `lookup_record` (no side effects) and a write-classed tool `update_record` (produces
  observable external side effects). Both tools are reachable via a network-accessible
  transport endpoint.
- The runtime is configured with a checkpoint backend (SQLite) and with a per-tool approval
  hook wired to a policy that **withholds approval for any tool classified as write-class**.
- A deterministic agent graph is registered with the runtime. Its logic is: (1) call
  `lookup_record` with a fixed key; (2) incorporate the returned value into a decision;
  (3) call `update_record` with the decision as the payload.
- Two distinct session identities, TENANT-ALPHA and TENANT-BETA, are provisioned.

---

**Check 1 — MCP client discovery, tool invocation, and result ingress**

**When** the agent run starts for TENANT-ALPHA with run ID `EMBED-RUN-01`:

**Then:**
1. The agent connects to the external MCP server, discovers its tool manifest, and
   retrieves at minimum the two advertised tools without error.
2. The agent calls `lookup_record` with the configured key. The external MCP server returns
   a response. The agent incorporates the returned value into its internal state.
3. The agent's next decision is observably different from what it would be with an empty or
   absent record (the returned value provably influences the agent's next action — the
   decision value reflects the lookup result, not a default).
4. If the external MCP server is unreachable or returns an error on `lookup_record`, the
   run surfaces a structured failure (not a panic, not a silent empty result).

---

**Check 2 — Write-class tool blocked; pending-human-approval state emitted**

**When** the agent reaches the step that calls `update_record` (after a successful
`lookup_record`):

**Then:**
1. The per-tool approval hook fires before `update_record` is invoked.
2. With approval **withheld** (the configured policy denies write-class tools without
   explicit approval), `update_record` is NOT invoked. No observable side effect occurs
   on the external MCP server's side (the record is not updated).
3. The run transitions to a pending-human-approval state. It does NOT proceed past this
   point, does NOT fabricate a success response, and does NOT time out silently.
4. The pending-human-approval state is durable: if the host process restarts at this point,
   a new process loading the same run ID `EMBED-RUN-01` discovers the pending approval
   request and waits for a resume signal. It does not re-execute `lookup_record`.

---

**Check 3 — Approval delivery; single execution; idempotent re-deliver**

**When** the host delivers an APPROVE signal for run `EMBED-RUN-01` (approving the
`update_record` call):

**Then:**
1. `update_record` executes exactly once. The external MCP server observes exactly one
   invocation with the correct payload.
2. The run completes with status `completed` and a well-formed result.
3. If the host delivers the identical APPROVE signal a second time (same run ID, same
   resume key), the runtime does NOT re-execute `update_record`. It returns a response
   (either the cached completion result or a structured indication that the run is already
   complete) without a second invocation of `update_record` on the external server.
4. The run carries a stable run identifier throughout. All streaming events emitted after
   the resume carry the same run-level correlation identifier as events emitted before
   the interrupt.

---

**Check 4 — Typed streaming events with stable correlation ids**

**When** a fresh run `EMBED-RUN-02` completes in one shot (no interrupt; approval hook
configured to `approve_all`):

**Then:**
1. The host collects all streaming events for `EMBED-RUN-02`. Every event carries a
   non-null, stable run-level identifier that is the same value from the first event to
   the last.
2. For a nested invocation within the run (e.g., a sub-graph or a tool-spawned nested
   execution), the nested events carry their own identifier distinct from the top-level
   run identifier, and the top-level run's identifier appears in the nested events'
   ancestry chain.
3. After an interrupt and resume (as in Check 3), the resumed portion of the run carries
   a new run-level identifier (the resume creates a new run record), but the resumed
   run's ancestry context is consistent with the interrupted run's nesting level — it is
   not deeper.
4. Events sufficient to reconstruct the full causal sequence are emitted (run start, node
   starts/ends, tool call start/result, approval request, approval resolved, run end).

---

**Check 5 — Agent exposed as MCP tool; external caller receives well-formed response**
**(CONTINGENT — see coverage gap note)**

**Given** the agent graph used in Check 2 / Check 3 is additionally exposed through the
runtime's outbound server interface as an invocable MCP tool named `run_agent`.

**When** an external MCP caller (independent of the embedding host) sends a `tools/list`
request and then a `tools/call { "name": "run_agent", "arguments": { "key": "test" } }`:

**Then:**
1. The `tools/list` response includes `run_agent` in the tools array with a name,
   description, and input schema.
2. The `tools/call` invocation returns a well-formed MCP tool result: a content array with
   at least one text entry containing the agent's output. `isError` is `false` on success.
3. The external MCP caller has NO access to the agent's internal state, intermediate node
   outputs, or checkpoint data. The response boundary is the tool result only.
4. If the agent run encounters an error, the MCP response returns `isError: true` with a
   sanitized error message (no credential material in the response text).

---

**Check 6 — Concurrent runs under distinct session identities remain isolated**

**When** run `EMBED-RUN-ALPHA` for TENANT-ALPHA and run `EMBED-RUN-BETA` for TENANT-BETA
execute concurrently, both using the same agent graph and calling `lookup_record` from the
same external MCP server:

**Then:**
1. TENANT-ALPHA's run state is not visible to TENANT-BETA's run and vice versa. Reads
   from checkpoint storage by one run never return data belonging to the other run.
2. The `lookup_record` calls for each run are independent. A modified result returned for
   TENANT-ALPHA does not affect TENANT-BETA's run state.
3. Both runs complete (or reach their respective terminal states) independently. One run
   failing does not affect the other run's execution.
4. Streaming events for each run are tagged with distinct run-level identifiers. An observer
   following only TENANT-ALPHA's identifier never receives TENANT-BETA's events.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Check |
|-------|--------------|----------------|
| BC-2.09.001 {PC-001} | Tool discovery via MCP server: list_tools pagination until all tools retrieved | Check 1 — agent discovers external tools |
| BC-2.09.001 {PC-001} §overflow fail-closed (E-MCP-008) | Pagination overflow → Err, no partial list | Check 1 — EC: MCP server with >1000 pages |
| BC-2.09.001 §unknown-server (E-MCP-009) | Session call on unconfigured server → structured Err | Check 1 — EC: unknown server name |
| BC-2.09.004 {PC-001} + VP-004 | Bare ToolException preserved as typed error, not panic (Red Gate R11) | Check 1 — MCP tool error surface |
| BC-2.09.005 {PC-005} + VP-005 | RAII session-per-call (McpSessionGuard); MultiServerMcpClient holds no live connections | Check 1 — session lifecycle correctness |
| BC-2.05.007 {INV-001}{PC-002} + VP-011 Kani `deny_excludes_tool_invocation` | Deny decision → ToolOutput::Error without tool execution (fail-closed; Kani proof over route_pre_tool_decision) | Check 2 — write-class tool not invoked on withheld approval |
| BC-2.05.007 {PC-004} | PendingHumanApproval → interrupt issued via BC-2.05.001 machinery; run suspended | Check 2 — pending-human-approval state emitted |
| BC-2.05.004 {PC-001} + E-GRAPH-018 | Command(resume=value) routes to correct pending interrupt; unmatched interrupt_id → E-GRAPH-018 InterruptIdNotFound (not silent discard) | Check 3 — approval delivery and resume routing |
| BC-2.04.005 | Completed super-steps not re-executed after process restart; lookup_record not re-run | Check 2 — no re-execution of lookup after restart |
| BC-2.04.001 {PC-001} | Checkpoint write after each super-step; durable across process restart | Check 2 — pending approval durable after restart |
| BC-2.12.006 {PC-001} (ADR-028 D5) | IdempotencyStore: second identical request within TTL returns cached response without re-running | Check 3 — idempotent re-deliver of APPROVE |
| BC-2.12.003 {PC-004} (ADR-028 D1–D3) | Concurrent-run lifecycle: queued/in_progress/interrupted state machine; multitask enqueue semantics | Check 6 — concurrent runs under distinct identities |
| BC-2.06.001 | StreamEvent taxonomy (16 variants): RunStart, NodeStart/End, ToolStart/End, ToolApprovalRequest, ToolApprovalResolved, RunEnd emitted | Check 4 — full event sequence observable |
| BC-2.06.002 {INV-001}{INV-002} + VP-STREAM-04 | run_id stable for run lifetime; new run_id on resume (not reuse); parent_ids copied verbatim from interrupted run (no extra nesting level added) | Check 4 — stable correlation ids; Check 3 — post-resume event correlation |
| BC-2.04.006 {INV-001} + VP-002 Kani `session_tenancy_harness` | Session triple-address uniqueness (thread_id, checkpoint_ns, checkpoint_id) — no two sessions share a storage address | Check 6 — cross-tenant state isolation |
| BC-2.03.001 {PC-001} + VP-001 Kani `bsp_determinism_harness` | BSP scheduler produces identical GraphState for identical inputs regardless of node completion order | Check 6 — concurrent runs deterministic |
| BC-2.09.006 {PC-002} | MCP server tools/list returns all registered tools with name/description/inputSchema | Check 5 — run_agent appears in tools/list |
| BC-2.09.007 {PC-001}{PC-002}{INV-003} + VP-015 | tools/call routes to registered Tool, executes, serializes result; mandatory credential redaction before response | Check 5 — run_agent invocable via tools/call; internal state not leaked |

### Coverage Gap — HS-C-001-GAP-01

**Affected check:** Check 5 (agent exposed as MCP tool).

**Gap:** BC-2.09.006 and BC-2.09.007 specify the MCP server protocol layer: they cover
advertising and invoking TOOLS already registered in the ToolRegistry. Neither BC specifies
the **StateGraph-to-Tool wrapping contract** — the mechanism by which a Pregolya agent
(StateGraph) is wrapped as a `Tool` implementation and registered in the ToolRegistry so
that it appears to external MCP clients as a first-class invocable tool.

**Implication for this scenario:** Check 5 tests the observable end-to-end behavior, but
there is no existing BC whose postconditions formally guarantee the wrapping step. If the
evaluator observes a failure on Check 5, it cannot be conclusively attributed to a
violation of an existing contract; the behavior may simply be unspecified.

**Routing:** Surfaced to orchestrator. Product-owner should either (a) author a new BC
(e.g., BC-2.09.008 or in a new subsystem) specifying `GraphAgentTool::from(StateGraph)`
wrapping behavior, or (b) confirm that the embedding host is expected to perform this
wrapping externally (in which case Check 5 is out of scope for Pregolya's own contracts
and should be removed from future revisions of this scenario).

---

## Verification Approach

1. Start the runtime with: (a) an external stand-in MCP server (stdio or SSE) offering
   `lookup_record` and `update_record`; (b) a SQLite checkpoint backend; (c) the per-tool
   approval hook configured to withhold write-class tools; (d) the MCP server transport
   enabled for outbound tool advertisement.
2. Submit the agent graph registered with the stand-in MCP server as the tool source, with
   run ID `EMBED-RUN-01`, tenant TENANT-ALPHA.
3. Let the agent execute until it reaches the `update_record` call. Confirm the run enters
   pending-human-approval state. Confirm `lookup_record` was called and its result is
   reflected in the agent's intermediate state.
4. Simulate process restart. Load checkpoint for `EMBED-RUN-01`. Confirm pending approval
   survives and `lookup_record` is NOT called again.
5. Deliver APPROVE for `EMBED-RUN-01`. Confirm `update_record` executes exactly once.
   Confirm the run completes with status `completed`.
6. Deliver the same APPROVE signal again. Confirm `update_record` is NOT called a second
   time. Confirm idempotent response.
7. Collect all streaming events for a clean run (no interrupt, `approve_all` policy). Verify
   every event carries the same stable run-level identifier. Verify nested events carry
   ancestry identifiers. Verify post-resume events use a new run-level identifier but the
   same ancestry context.
8. (Check 5 — CONTINGENT) If the runtime supports outbound MCP tool advertisement of
   the agent: connect an external MCP client; send `tools/list`; assert `run_agent` is
   present. Send `tools/call { "name": "run_agent", … }`; assert a well-formed tool
   result is returned. Assert the response contains no internal state (no checkpoint IDs,
   no intermediate node outputs beyond the final result).
9. Start two runs concurrently: `EMBED-RUN-ALPHA` (TENANT-ALPHA) and `EMBED-RUN-BETA`
   (TENANT-BETA). Inject different `lookup_record` return values for each tenant.
   Assert each run's `update_record` (if approved) uses the value from its own tenant's
   lookup. Assert checkpoint data for one run is not accessible via the other run's
   session identity. Assert streaming events for each run are tagged with distinct
   run-level identifiers.

---

## Evaluation Rubric

| Dimension | Weight | Must-Pass? | Passing Signal |
|-----------|--------|------------|----------------|
| Check 1: MCP discovery and read-result ingress | 0.20 | yes | lookup_record result provably reflected in agent's next decision |
| Check 2: Write blocked fail-closed; pending-approval state durable | 0.25 | yes | update_record not invoked; approval request survives restart; lookup not re-run |
| Check 3: Approval → single execution; idempotent re-deliver | 0.20 | yes | update_record executes exactly once; second APPROVE has no side effect |
| Check 4: Typed streaming events with stable correlation ids | 0.10 | yes | all events carry stable run_id; resumed run has correct ancestry context |
| Check 5: Agent exposed as MCP tool (CONTINGENT on gap) | 0.10 | no (contingent) | tools/list shows agent; tools/call returns result; no internal state leaked |
| Check 6: Cross-tenant state isolation | 0.15 | yes | each tenant's run state and lookup result are independent |

**Must-pass threshold (excluding check 5):** weighted average of checks 1–4 and 6 ≥ 0.72.
**Full threshold (all checks):** weighted average ≥ 0.80.

Check 5 is scored but does not individually gate the must-pass verdict if HS-C-001-GAP-01
has not been resolved. If GAP-01 is resolved before Phase 4 evaluation, check 5 becomes
must-pass and its weight is redistributed (suggested: +0.05 to check 2, +0.05 to check 6).

---

## Edge Conditions

### EC-001: External MCP server returns error on lookup_record
**Expected behavior:** The run surfaces a structured error (via the MCP ingress error
taxonomy). The run does NOT proceed to update_record with a fabricated or default value.
The evaluator asserts a structured failure, not a panic or silent empty continuation.

### EC-002: External MCP server returns isError:true (tool-level failure) on lookup_record
**Expected behavior:** The agent receives the error as a tool result (not as a protocol
error). The agent's next node observes the tool-error signal, not a fabricated success.
The run may fail or the agent may route to an error-handling branch — either is acceptable
provided no fabrication occurs.

### EC-003: Approval signal delivered with an incorrect or mismatched resume key
**Expected behavior:** The runtime returns a structured error. The run remains in
pending-human-approval state. update_record is NOT invoked.

### EC-004: Process restart between lookup_record and update_record (before interrupt fires)
**Expected behavior:** On restart, the completed lookup_record super-step is not
re-executed. The run resumes from the last committed checkpoint. The lookup result remains
in run state.

### EC-005: Concurrent runs — one run fails during update_record
**Expected behavior:** The failure of TENANT-BETA's run does not affect TENANT-ALPHA's
run. TENANT-ALPHA completes independently.

### EC-006: tools/call for run_agent returns a tool-level error (agent run fails)
**Expected behavior:** MCP response `isError: true`; sanitized error message; no API key
material or internal state in the response text. (Contingent on gap resolution.)

---

## Failure Guidance

"HOLDOUT LOW: HS-C-001 (satisfaction: X.XX) — the embedding host integration did not
satisfy one or more core invariants. Likely failure modes:

- Check 1 fail: MCP client did not discover external tools, or lookup result did not
  influence the agent's next decision (fabrication or empty-result swallow).
- Check 2 fail: write-class tool executed despite withheld approval (fail-open violation),
  or the run did not enter pending-human-approval state, or approval state was not durable
  across process restart.
- Check 3 fail: update_record was called more than once after a single APPROVE signal
  (single-execution violation), or the idempotent re-deliver caused a second invocation.
- Check 4 fail: streaming events had inconsistent or missing run-level correlation
  identifiers, or the post-resume ancestry context was incorrect.
- Check 5 fail (CONTINGENT): run_agent not advertised in tools/list, tools/call failed,
  or internal state leaked in the tool response. Flag for gap adjudication.
- Check 6 fail: TENANT-ALPHA's state was visible to TENANT-BETA's run, or lookup result
  from one tenant appeared in the other's decision."

---

## Information Asymmetry Confirmation

This scenario is evaluated at the wire and observable-behavior level only. The evaluator:
- Has access to the public API surface (HTTP endpoints, MCP protocol messages, streaming
  event JSON, and the output of tool calls).
- Does NOT have access to source code, module internals, checkpoint database contents
  (beyond what the public API surfaces), BC/VP identifiers, error code identifiers, or
  internal scheduler state.
- The BC linkage table and coverage gap note above are traceability metadata for
  product-owner and orchestrator use. They are NOT part of the evaluator's test narrative.

---

## Category: real-world-corpus

Not applicable — this scenario's category is `integration-boundaries` (see the frontmatter
`category:` field). No real-world corpus is required for this `integration-boundaries` test.

This scenario exercises all seven embedding-host primitives end-to-end under a single
composite integration run, verifying that the existing in-scope Pregolya contracts compose
to support an external embedding host without requiring new runtime capabilities.
