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
id: HS-D-002
title: "Panel-Topology Deliberation — Anonymized Cross-Review and Chair Reduction"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.006
  - BC-2.02.002
  - BC-2.08.001
  - BC-2.08.003
  - BC-2.03.001
  - BC-2.06.001
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
  - composition
  - providers
  - structured_output
changelog:
  - "1.0 (initial/2026-08-31): Domain D HS-D-002 authored for autonomous research orchestrator use case."
---

# Holdout Scenario HS-D-002: Panel-Topology Deliberation — Anonymized Cross-Review and Chair Reduction

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A deliberation panel is modeled as a multi-phase graph. In the first phase, N parallel researcher agents ("panel members") each independently produce a draft agenda contribution. In the second phase, each contribution is anonymized before being passed to a cross-review round — panel members review contributions without knowing which peer authored them. In the third phase, a designated chair agent receives all anonymized contributions and reduces them to exactly one committed agenda record.

**Given:**
- A graph configured with N parallel panel-member nodes (N ≥ 2) backed by a DTU mock provider.
- An anonymization step in the graph that strips identifying metadata (author identifier, agent identifier) from each contribution before forwarding it to the cross-review round.
- A chair node that receives all anonymized contributions as a collected input and invokes a chat model to reduce them to a single structured agenda record.
- The structured agenda record has at minimum three fields: `topic` (a non-empty string), `rationale` (a non-empty string), and `confidence` (a numeric value in the range [0.0, 1.0]).

**When** the deliberation graph is invoked with a research question fixture:

**Then:**
1. All N panel-member nodes execute and each produces a contribution. The graph does not exit until all N contributions are available.
2. After the anonymization step, no contribution in the cross-review round carries an agent identifier or author label. Each contribution's author field is absent, null, or replaced with a generic placeholder.
3. The chair node receives all N anonymized contributions as a unified collection and invokes its underlying model exactly once (not once per contribution).
4. The chair node emits exactly one committed agenda record. The record is a typed structured value (not a raw string) with `topic`, `rationale`, and `confidence` fields all populated.
5. `confidence` is in the range [0.0, 1.0]. `topic` and `rationale` are non-empty strings.
6. The graph completes without panic, crash, or empty response. All streaming events carry consistent run-level correlation identifiers.

**Partial-failure variant:** When one panel-member node returns a structured error (simulated via the DTU mock returning an error response), the graph must behave in one of two acceptable ways: (a) the chair proceeds with N − 1 contributions and the agenda record notes the missing contribution, or (b) the run surfaces a structured error indicating which member failed, without panicking or producing an empty agenda. Silent swallowing of the partial failure (proceeding as if N contributions arrived when only N − 1 did) is not acceptable.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.006 | Send API dynamic fan-out: N panel-member tasks dispatched in parallel | N parallel panel-member nodes all execute before chair step begins |
| BC-2.02.002 | BarrierValue channel collects N contributions before barrier releases | Chair step begins only after all N contributions are collected |
| BC-2.08.001 | Chat model streaming completions conformance (per panel-member, per chair) | Each panel-member and the chair invoke the chat model successfully |
| BC-2.08.003 | Structured output deserialization: typed agenda record returned | Chair emits a typed structured record, not a raw string |
| BC-2.03.001 | BSP super-step determinism: identical inputs → identical outputs | Parallel panel members do not cause non-deterministic barrier behavior |
| BC-2.06.001 | Typed streaming events across all phases; run_id correlation | Events emitted for fan-out, anonymization, and chair steps; run_id stable |

---

## Verification Approach

1. Construct a graph with N = 3 panel-member nodes wired in parallel via a fan-out edge. Each panel-member node calls the DTU mock provider and returns a contribution record with an `author_id` field set to a distinct value per member.
2. After the fan-out barrier, add an anonymization transform node that iterates over the collected contributions and removes or nullifies the `author_id` field in each.
3. Forward the anonymized contributions to a chair node that collects them into a single list and calls the DTU mock provider with the list as context, requesting a structured agenda.
4. Assert that the chair node returns a typed structured agenda with `topic`, `rationale`, and `confidence` all populated and `confidence` in [0.0, 1.0].
5. Assert no `author_id` field is present in any contribution passed to the chair node (inspect the graph state at the anonymization→chair edge).
6. Assert the chair's model was called exactly once (not N times).
7. Run the partial-failure variant: configure the DTU mock to return an error for panel-member 2. Assert the graph either proceeds with 2 contributions (and the agenda notes the absence) or surfaces a structured error identifying the failed member. Assert no panic and no silent empty agenda.
8. Collect all streaming events. Assert run-level correlation identifier is stable across all phases.
9. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Must-Pass? | Passing Signal |
|-----------|--------|------------|----------------|
| Fan-out completion: all N contributions collected | 0.25 | yes | Chair step does not begin until all N members have produced outputs |
| Anonymization: no author identity in cross-review inputs | 0.25 | yes | Contributions passed to chair contain no agent/author identifier |
| Chair reduction: exactly one structured agenda record | 0.25 | yes | Typed agenda with topic, rationale, confidence all populated and valid |
| Partial-failure handling: structured response, not panic | 0.15 | yes | On panel-member error, run produces structured error or partial agenda without panicking |
| Streaming correlation: stable run identifier across phases | 0.10 | yes | All events carry same run-level correlation identifier |

**Must-pass threshold (all five dimensions):** weighted average ≥ 0.70.

---

## Edge Conditions

### EC-001: N = 2 (minimum panel size)
**Expected behavior:** With two panel members, both must contribute before the chair step begins. The chair emits exactly one agenda record. Anonymization removes both `author_id` fields.

### EC-002: Both panel members return identical contributions
**Expected behavior:** The chair receives two identical (but separately sourced) contributions. The chair emits exactly one agenda record. No deduplication error. The `rationale` may reference both contributions or synthesize them.

### EC-003: All panel members fail
**Expected behavior:** With all N members returning errors, the run surfaces a structured error. The chair is not invoked. No empty agenda is emitted silently.

### EC-004: DTU mock returns a malformed agenda from the chair
**Expected behavior:** The framework surfaces a structured deserialization error. The run does not return a partially-constructed agenda with missing required fields.

### EC-005: Cross-review round receives contributions with no text content (empty strings)
**Expected behavior:** The chair is still invoked with the empty contributions. The resulting agenda record has `topic` and `rationale` populated (the chair's model must synthesize content even from sparse input). `confidence` is a low but valid value.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-002 (satisfaction: X.XX) — the panel deliberation did not correctly complete the fan-out, anonymization, or chair reduction. Likely failure modes:

- Fan-out fail: the chair step began before all panel members completed, or the collected contributions were fewer than N (N − 1 or fewer contributed before the barrier released).
- Anonymization fail: the chair received contributions that still carried an author identifier, violating the anonymized cross-review requirement.
- Chair reduction fail: the chair was invoked more than once (once per contribution), or the chair returned a raw string rather than a typed structured agenda, or required fields were missing or null.
- Partial-failure fail: when one panel member errored, the graph panicked, produced a silent empty agenda, or proceeded as if all N contributions arrived without noting the missing one.
- Streaming fail: streaming events had inconsistent or absent run-level correlation identifiers across the fan-out and chair phases."

---

## Information Asymmetry Confirmation

**Evaluator-facing sections confirmed FREE of internal traceability identifiers (BC IDs, VP IDs, error code identifiers, and internal module-path identifiers):**
- §Scenario
- §Verification Approach
- §Evaluation Rubric (table rows and must-pass threshold)
- §Failure Guidance
- §Edge Conditions

**Exempted non-evaluator metadata sections (legitimately retain traceability IDs):**
- §Behavioral Contract Linkage (BC-ID traceability table — orchestrator metadata only)

---

## Category: real-world-corpus

Not applicable — this scenario's category is `integration-boundaries` (see the frontmatter `category:` field). No real-world corpus is required for this `integration-boundaries` test.
