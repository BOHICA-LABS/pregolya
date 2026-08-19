---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-19T00:00:00Z
phase: 2
domain: A
domain_name: Virtual SOC Analyst Agent
id: HS-A-002
title: "Parallel Enrichment Fan-Out with Partial Failure"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.04.001
  - BC-2.09.001
  - BC-2.01.006
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
input-hash: "7442088"
traces_to: .factory/planning/holdout-domains/domain-a-soc-analyst.md
lifecycle_status: active
introduced: v1.0.0-phase-2
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - graph_execution
  - mcp
  - tools
  - providers
---

# Holdout Scenario HS-A-002: Parallel Enrichment Fan-Out with Partial Failure

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A SOC triage agent must enrich an alert by querying three independent sources in parallel — a threat intelligence lookup for the suspect IP, an endpoint telemetry lookup for the source host, and an identity lookup for the account associated with the activity.

**Given** an alert for a suspicious outbound connection: `{ src_ip: "198.51.100.73", account: "alice@example.com", host: "workstation-14", alert_type: "Suspicious outbound to known C2 range" }`. Three DTU mock tool servers are available: a threat-intel server (responds in ~50ms), an EDR/endpoint server (responds in ~50ms), and an identity server (set to return an error for this scenario to test partial failure).

**When** the agent is invoked with the alert record and is configured to fan-out to all three sources simultaneously.

**Then:**
1. The threat-intel and endpoint enrichment results are collected successfully and appear in the final enrichment record.
2. The identity lookup failure is surfaced as a structured partial-failure entry (not a crash, not silently discarded).
3. The final enrichment record is produced — containing the two successful results and an indication that identity lookup failed — within a reasonable wall-clock time bound (the partial failure must not cause the healthy lookups to be delayed by more than a small multiple of their individual latency).
4. The agent does NOT crash or panic because one tool returned an error.
5. The final structured output includes a `partial_failure` field (or equivalent) indicating which enrichment source failed and why.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.04.001 | Parallel fan-out (Send API) executes branches concurrently | Three enrichment tool calls dispatched simultaneously |
| BC-2.09.001 | MCP tool integration — tool call dispatched and result returned | Threat-intel and endpoint tool calls succeed |
| BC-2.01.006 | Parallel branch failure surfaced, not swallowed | Identity lookup error becomes a partial-failure record |

---

## Verification Approach

1. Build an agent graph with a fan-out node that dispatches three parallel tool calls (threat-intel lookup, EDR lookup, identity lookup) using pregolya's parallel execution primitives.
2. Configure the threat-intel and EDR DTU mock servers to return valid enrichment records. Configure the identity DTU mock server to return a tool error for the `alice@example.com` query.
3. Invoke the agent with the alert fixture.
4. Assert the final enrichment record contains both the threat-intel and EDR enrichment fields.
5. Assert the final record contains an indicator that identity lookup failed (a structured error entry, not a missing field).
6. Assert the agent exits cleanly (no panic, exit code 0 from the test binary).
7. Optional: measure wall-clock time to confirm all three parallel calls complete within roughly 2× the longest individual mock server latency (not 3× sequential).

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Correct fan-out and result collection | 0.40 | Both successful enrichment results present in output |
| Partial failure surfacing | 0.30 | Failed identity lookup appears as structured error, not absent field or panic |
| Concurrency (parallel, not sequential) | 0.15 | Wall-clock time consistent with parallel execution |
| Stability | 0.15 | Clean exit, no panic; partial-failure does not cascade to a full failure |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- All three tool servers return errors: agent must produce an enrichment record with three partial-failure entries, not crash.
- One tool server is unreachable (connection refused rather than an application-level error): this must also be surfaced as a partial failure.
- Tool servers return large payloads (100KB+): agent must handle without truncation or memory error.

---

## Failure Guidance

"HOLDOUT LOW: HS-A-002 (satisfaction: X.XX) — parallel enrichment fan-out did not correctly handle partial tool failure, or executed tool calls sequentially rather than concurrently."

---

## Category: real-world-corpus

Not applicable — this scenario uses synthetic alert fixtures and DTU mock tool servers, not a real-world corpus. Category is `integration-boundaries`.
