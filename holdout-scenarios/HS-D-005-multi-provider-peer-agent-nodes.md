---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-31T00:00:00Z
phase: 2
domain: D
domain_name: Autonomous Research Orchestrator
id: HS-D-005
title: "Multi-Provider Peer Agent Nodes with Shared MCP Tool Access"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.08.001
  - BC-2.09.001
  - BC-2.09.002
  - BC-2.02.006
  - BC-2.08.004
  - BC-2.14.005
inputs:
  - .factory/specs/prd.md
input-hash: "b7af049"
traces_to: .factory/specs/prd.md
lifecycle_status: active
introduced: v1.0.0-phase-2-newuc
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - graph_execution
  - providers
  - mcp
  - tools
  - composition
changelog:
  - "1.0 (initial/2026-08-31): Domain D HS-D-005 authored for autonomous research orchestrator use case."
---

# Holdout Scenario HS-D-005: Multi-Provider Peer Agent Nodes with Shared MCP Tool Access

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A research orchestrator deploys three peer agent nodes within the same graph, each backed by a distinct chat model provider (an OpenAI-family DTU mock, an Anthropic-family DTU mock, and an Ollama-family DTU mock). All three peers share access to the same external MCP tool set. An orchestrating synthesis node collects the peer outputs and produces a combined result.

This scenario verifies that the framework correctly routes provider-specific API calls to the correct transport for each peer, that tool invocations are correctly dispatched regardless of which provider backs the peer, and that credential material for one provider does not appear in another provider's request or response.

**Given:**
- A graph with three parallel peer nodes, each configured with a different DTU mock provider: `peer-openai` (OpenAI-family DTU), `peer-anthropic` (Anthropic-family DTU), `peer-ollama` (Ollama-family DTU).
- A shared external MCP server running a single read-classified tool: `fetch_evidence` that accepts a query string and returns a short evidence snippet.
- Each peer node is configured to call `fetch_evidence` once and incorporate the result into its response.
- A synthesis node at the end of the parallel fan-out collects all three peer responses and produces a typed combined summary record.
- Each DTU mock is configured with a distinct credential value (distinct API key format per provider family). These credentials must NOT appear in any response or in any other provider's outbound request.

**Check 1 — All three provider-backed peers execute and return responses**

**When** the graph is invoked with a research question fixture:

**Then:**
1. All three peers (`peer-openai`, `peer-anthropic`, `peer-ollama`) execute and each returns a non-empty response. No peer silently returns an empty result.
2. Each peer's response is distinct (reflects the DTU mock's configured behavior for that provider — different mock responses per provider).
3. The graph does not error due to a provider routing failure for any of the three providers.

**Check 2 — Tool invocations reach the MCP server and results are incorporated**

**When** each peer calls `fetch_evidence` via the shared MCP tool set:

**Then:**
1. The external MCP server records exactly three invocations of `fetch_evidence` — one per peer.
2. Each peer's response incorporates the evidence returned by `fetch_evidence`. The peer response is observably different from what it would be without the evidence snippet (the evidence value provably influenced the response).
3. Tool routing for all three peers targets the same external MCP server (no provider-specific tool routing differences).

**Check 3 — Provider credential isolation**

**When** the three peers execute and make their respective provider API calls:

**Then:**
1. The outbound request for `peer-openai` does not contain the credential value for `peer-anthropic` or `peer-ollama`.
2. The outbound request for `peer-anthropic` does not contain the credential value for `peer-openai` or `peer-ollama`.
3. The outbound request for `peer-ollama` does not contain any credential value from the OpenAI or Anthropic DTU mock configurations.
4. No DTU mock response contains credential material from any provider. Credential values are not logged, streamed, or serialized into tool results.

**Check 4 — Synthesis node produces a combined structured result**

**When** all three peer responses arrive at the synthesis node:

**Then:**
1. The synthesis node receives all three peer outputs and produces a typed combined summary record. The record is not empty and not a raw string.
2. The combined summary references or synthesizes content from all three peers (it is not a copy of a single peer's output).
3. The graph completes cleanly. All streaming events carry a stable run-level correlation identifier.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.08.001 | Chat model completions conformance per provider family | Three provider-backed peers each successfully call their respective DTU mock |
| BC-2.09.001 | MCP server tool discovery: list_tools, registration at runtime | All three peers discover and register `fetch_evidence` from the shared MCP server |
| BC-2.09.002 | Tool invocation routing to correct MCP server transport | All peer tool calls reach the same MCP server regardless of backing provider |
| BC-2.02.006 | Send API fan-out: three parallel peer tasks dispatched | Three peer nodes execute in parallel; synthesis begins after all three complete |
| BC-2.08.004 | Chat model error-type fidelity: structured error per provider | If a DTU mock returns an error, it surfaces as a typed provider error, not a generic panic |
| BC-2.14.005 | API Key Newtype with Redacted Debug; credential values not serialized or exposed in responses | No credential value appears in any provider response, streaming event, or tool result payload |

---

## Verification Approach

1. Start three DTU mock servers (OpenAI-family, Anthropic-family, Ollama-family), each configured with a distinct API credential value. Each mock is configured to return a unique deterministic response for the research question fixture.
2. Start the shared MCP server with the `fetch_evidence` tool. Configure it to return a short fixed evidence string for any query.
3. Construct a graph with three parallel peer nodes. Each peer is configured with its respective DTU mock base URL and credential. Each peer calls `fetch_evidence` via the MCP tool before generating its response.
4. Invoke the graph with a research question fixture. Assert all three peers complete and return non-empty responses.
5. Inspect the MCP server's call log. Assert exactly three `fetch_evidence` invocations were recorded.
6. Assert each peer's response incorporates the evidence snippet (not a pure model response without evidence).
7. Inspect the outbound HTTP request logs for each DTU mock. Assert that the OpenAI-family mock received a request with the OpenAI-family credential only; the Anthropic-family mock received a request with the Anthropic-family credential only; the Ollama-family mock received a request with no credential material from other providers.
8. Assert no credential value appears in any streaming event, tool result, or synthesis node input.
9. Assert the synthesis node produces a typed combined summary record referencing all three peers.
10. Collect all streaming events. Assert the run-level correlation identifier is stable across all phases.
11. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Must-Pass? | Passing Signal |
|-----------|--------|------------|----------------|
| Check 1: all three provider-backed peers execute and return responses | 0.25 | yes | All three peers produce non-empty, distinct responses without provider routing errors |
| Check 2: tool invocations reach the MCP server; evidence incorporated | 0.25 | yes | Three fetch_evidence calls recorded; each peer response incorporates evidence |
| Check 3: provider credential isolation | 0.25 | yes | No credential from provider A appears in provider B's request or any response payload |
| Check 4: synthesis node produces typed combined result | 0.25 | yes | Typed combined summary referencing all three peers; stable streaming correlation |

**Must-pass threshold (all four checks):** weighted average ≥ 0.70.

---

## Edge Conditions

### EC-001: One DTU mock provider returns a structured error (simulated provider failure)
**Expected behavior:** The failing peer surfaces a typed provider error — not a panic and not an empty response. The synthesis node receives two valid peer outputs and the structured error for the third. The combined summary either notes the missing peer or the run surfaces a structured partial-failure error. Silent swallowing of the failure (treating the error as an empty success) is not acceptable.

### EC-002: The shared MCP server returns an error response on one peer's `fetch_evidence` call
**Expected behavior:** The failing peer receives the tool error as a typed tool-call result (not a protocol panic). The peer's response may omit the evidence or include a note about the failed lookup. The other two peers are not affected.

### EC-003: Credential values are long strings (32+ characters)
**Expected behavior:** Long credential values do not appear truncated in any log output or response. Credential opacity holds regardless of credential length.

### EC-004: All three peers call `fetch_evidence` with the same query string
**Expected behavior:** The MCP server handles three concurrent invocations without serialization errors or dropped calls. Each invocation receives the correct response independently.

### EC-005: Synthesis node receives three peer outputs with conflicting recommendations
**Expected behavior:** The synthesis node calls its underlying model with all three outputs regardless of their content. The combined summary is produced without raising a conflict-resolution error. The summary may note the disagreement.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-005 (satisfaction: X.XX) — the multi-provider peer graph did not correctly execute across all three provider backends, route tool calls to the shared MCP server, or maintain credential isolation. Likely failure modes:

- Provider routing fail: one or more peers failed to invoke their DTU mock (wrong base URL routed, wrong credential attached, or provider family not recognized by the framework).
- Tool routing fail: `fetch_evidence` was not called for one or more peers, or the MCP server recorded fewer than three invocations; or tool results were not incorporated into peer responses.
- Credential leak fail: a credential value from one provider appeared in another provider's outbound request or in any streaming event, tool result, or combined summary payload.
- Synthesis fail: the synthesis node received fewer than three peer outputs, produced an empty combined summary, or returned a raw string rather than a typed record.
- Streaming fail: streaming events had inconsistent or missing run-level correlation identifiers across the three peer phases and synthesis phase."

---

## Information Asymmetry Confirmation

**Evaluator-facing sections confirmed FREE of internal traceability identifiers (BC IDs, VP IDs, error code identifiers, and internal module-path identifiers):**
- §Scenario (Check 1 through Check 4)
- §Verification Approach
- §Evaluation Rubric (table rows and must-pass threshold)
- §Failure Guidance
- §Edge Conditions

**Exempted non-evaluator metadata sections (legitimately retain traceability IDs):**
- §Behavioral Contract Linkage (BC-ID traceability table — orchestrator metadata only)

---

## Category: real-world-corpus

Not applicable — this scenario's category is `integration-boundaries` (see the frontmatter `category:` field). No real-world corpus is required for this `integration-boundaries` test.
