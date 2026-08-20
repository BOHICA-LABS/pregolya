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
id: HS-A-001
title: "Single Alert Triage — Basic End-to-End"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.08.001
  - BC-2.06.001
  - BC-2.01.004
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
input-hash: "b45cace"
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
  - composition
  - providers
  - streaming
  - structured_output
---

# Holdout Scenario HS-A-001: Single Alert Triage — Basic End-to-End

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A security analyst builds a minimal alert-triage agent using the pregolya framework. The agent accepts a single security alert record and produces a structured verdict.

**Given** a running DTU mock provider that simulates a chat completions endpoint, and an alert record containing: a source IP, a destination IP, an alert type label ("Possible port scan"), a severity level ("medium"), and a raw log snippet ("SYN packets to 1024 distinct ports in 30 seconds from a single source").

**When** the analyst invokes the agent with the alert record as input.

**Then:**
1. The agent returns a structured verdict with at minimum three fields: `disposition` (one of `true_positive`, `false_positive`, or `needs_escalation`), `confidence` (a numeric value in the range [0.0, 1.0]), and `summary` (a non-empty natural-language explanation).
2. The agent completes without panicking, crashing, or returning an empty response.
3. If the streaming API is used, at least one intermediate token event is delivered before the final verdict — confirming that the streaming pipeline is functional at the framework level.
4. The `disposition` value reflects a plausible triage decision for a port-scan alert against a high-severity IP.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.08.001 | Chat model invocation returns typed structured output | Verdict deserialized from chat completion |
| BC-2.06.001 | Streaming events delivered before final result | Intermediate token events observed |
| BC-2.01.004 | Runnable composition produces typed output | Alert record flows through composition to verdict |

---

## Verification Approach

1. Construct an agent using pregolya's public API (chain or single-node graph) that wraps a chat model call and deserializes the response into a structured verdict type.
2. Provide the alert fixture as the input state: source IP, dest IP, alert type, severity, log snippet.
3. Run the agent against the DTU mock provider (no real API key needed).
4. Assert that the output is a structured verdict with `disposition`, `confidence`, and `summary` fields matching the expected shape.
5. Assert `disposition` is one of `true_positive`, `false_positive`, `needs_escalation`.
6. Assert `confidence` is in [0.0, 1.0].
7. Assert `summary` is non-empty.
8. Optionally: invoke using the streaming API and assert at least one token event arrives before the final result.
9. Run the test with `cargo test` or equivalent; it must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Functional correctness | 0.45 | Structured verdict returned with all three required fields and valid values |
| Output shape conformance | 0.25 | Verdict is a typed record, not a raw string requiring manual parsing |
| Streaming availability | 0.15 | At least one intermediate event delivered before final result (if streaming path exercised) |
| Stability | 0.15 | No panic, no crash, clean exit; errors produce structured error values rather than panics |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

- Alert with empty `log_snippet`: agent must still return a valid verdict (lower confidence acceptable, no crash).
- Alert with `severity: "critical"`: `disposition` must still be one of the three valid values.
- DTU mock returning a malformed or empty response: agent must surface a structured error value, not a panic.

---

## Failure Guidance

"HOLDOUT LOW: HS-A-001 (satisfaction: X.XX) — basic triage agent did not return a well-formed structured verdict or crashed during execution."

---

## Category: real-world-corpus

Not applicable — this scenario uses a synthetic alert fixture, not a real-world corpus. No real-world corpus is required for this integration-boundaries test.
