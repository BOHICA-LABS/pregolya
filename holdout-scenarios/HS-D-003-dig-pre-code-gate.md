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
id: HS-D-003
title: "DIG Pre-Code Gate — Read-Only Contract Selection Before Implementation"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.005
  - BC-2.02.001
  - BC-2.08.003
  - BC-2.04.001
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
  - structured_output
  - providers
changelog:
  - "1.0 (initial/2026-08-31): Domain D HS-D-003 authored for autonomous research orchestrator use case."
---

# Holdout Scenario HS-D-003: DIG Pre-Code Gate — Read-Only Contract Selection Before Implementation

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A design-interrogation gate ("DIG gate") is modeled as a dedicated reasoning node that runs in read-only mode before any implementation-producing node is allowed to execute. The gate accepts a problem statement and candidate approaches, reasons over them via a chat model, and commits a design contract — a typed structured record that specifies which approach is selected and under what conditions. Downstream implementation nodes receive the committed contract as required input; they may not proceed without a committed contract.

**Given:**
- A linear graph with two phases: Phase 1 is the DIG gate node (read-only reasoning); Phase 2 is an implementation node that produces a typed output based on the committed contract.
- The DIG gate node calls a DTU mock provider with a problem statement and a list of candidate approach records. It returns a typed design contract with fields: `selected_approach` (a string identifying one candidate), `rationale` (a non-empty explanation string), and `constraints` (a list of zero or more constraint strings).
- The implementation node reads `selected_approach` from the design contract and uses it to produce its output. It must not use a default approach when a committed contract is present.
- A test fixture controls the candidate approaches and configures the DTU mock to return a specific contract selection.

**Check 1 — Gate commits a typed contract; downstream observes it**

**When** the graph is invoked with a problem statement and two candidate approaches (`approach-A`, `approach-B`):

**Then:**
1. The DIG gate node executes and produces a typed design contract. The contract is a structured record, not a raw string.
2. `selected_approach` is one of the two candidates provided (either `approach-A` or `approach-B`). It is not null, empty, or a value not present in the candidate list.
3. `rationale` is a non-empty string.
4. The implementation node executes after the gate. The implementation node's output reflects `selected_approach` from the contract — it does not use a hardcoded default or a randomly chosen approach.
5. The contract value is persisted in the checkpoint before the implementation node begins.

**Check 2 — Gate is read-only: no external side-effect calls during gate execution**

**When** the DIG gate node executes (Phase 1):

**Then:**
1. No calls to write-classified tools, external storage mutation APIs, or side-effect-producing external services are made during the gate node's execution. The gate is observable at the network/call level and must produce no outbound calls other than the single chat model inference call.
2. If the test harness intercepts external write calls during Phase 1, none are recorded.

**Check 3 — Gate failure surfaces a structured error; implementation does not proceed**

**When** the DTU mock is configured to return a response that cannot be deserialized as a valid design contract (missing required fields):

**Then:**
1. The run surfaces a structured error at the gate node. The error is a typed value (not a panic or a raw string).
2. The implementation node is NOT executed. No partial or default output is produced.
3. The run terminates with an error status, not with a fabricated contract.

**Check 4 — Contract selection is stable under identical inputs**

**When** the graph is invoked twice with identical problem statements and identical candidate lists:

**Then:**
1. Both invocations produce the same `selected_approach` value (deterministic contract selection for identical inputs when using the same DTU mock configuration).
2. The `rationale` fields of both contracts are consistent with the selected approach (not a random or unrelated explanation).

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.005 | Conditional edge: gate-node result routes to implementation vs. error-exit | If contract invalid → error exit; if valid → implementation node proceeds |
| BC-2.02.001 | Typed channel carries committed design contract across gate→implementation edge | Implementation node reads contract from typed channel, not a default |
| BC-2.08.003 | Structured output deserialization: design contract returned as typed record | DIG gate returns typed contract, not raw string |
| BC-2.04.001 | Per-task checkpoint write before next super-step | Contract persisted in checkpoint before implementation node begins |
| BC-2.06.001 | Typed streaming events; run_id stable across both phases | Events emitted for gate phase and implementation phase; run_id consistent |

---

## Verification Approach

1. Construct a two-phase graph. Phase 1: DIG gate node that calls the DTU mock with a problem statement and two candidate approaches (`approach-A`, `approach-B`) and returns a typed design contract. Phase 2: implementation node that reads `selected_approach` from the contract and appends it to a result record.
2. Configure the DTU mock to select `approach-A` when given the fixture inputs.
3. Invoke the graph. Assert the DIG gate returns a typed design contract with `selected_approach = "approach-A"`, non-empty `rationale`, and a `constraints` list (may be empty).
4. Assert the implementation node output references `approach-A` (not `approach-B` or a hardcoded default).
5. Assert the design contract is present in the checkpoint after the gate completes but before the implementation node's checkpoint write.
6. Intercept outbound calls during Phase 1. Assert only one outbound call is recorded (the chat model inference). No write calls to external storage or side-effect APIs.
7. Reconfigure the DTU mock to return a response missing the `selected_approach` field. Invoke the graph again. Assert a structured error is returned from the gate node. Assert the implementation node does not execute and no output is produced.
8. Invoke the graph twice with identical inputs and the same DTU mock configuration. Assert both invocations select the same `selected_approach` and produce consistent rationales.
9. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Must-Pass? | Passing Signal |
|-----------|--------|------------|----------------|
| Check 1: typed contract committed; downstream observes it | 0.30 | yes | Contract is a typed record; implementation output matches selected_approach |
| Check 2: gate is read-only (no external write calls during Phase 1) | 0.25 | yes | No write-classified external calls recorded during gate execution |
| Check 3: invalid contract → structured error; implementation blocked | 0.25 | yes | Structured error surfaced; implementation node not executed |
| Check 4: deterministic selection under identical inputs | 0.20 | yes | Same selected_approach across two identical invocations |

**Must-pass threshold (all four checks):** weighted average ≥ 0.70.

---

## Edge Conditions

### EC-001: Single candidate approach (no choice to make)
**Expected behavior:** The DIG gate receives a problem statement with only one candidate. The contract selects the only candidate. `selected_approach` equals the single candidate. `rationale` explains why it was selected. No error is raised.

### EC-002: Candidate list contains an approach name that is an empty string
**Expected behavior:** The gate must either skip the invalid candidate and select from valid ones, or surface a structured validation error. It must not select the empty string as `selected_approach`.

### EC-003: Contract `constraints` field contains more than 10 entries
**Expected behavior:** The contract is accepted and persisted as-is. The implementation node receives all constraints. No truncation occurs silently.

### EC-004: Process restart between gate completion and implementation start
**Expected behavior:** The resumed run loads the committed contract from the checkpoint. The gate does NOT re-execute (the contract is already present in the checkpoint). The implementation node receives the same contract values as the original run.

### EC-005: Implementation node attempts to write to a channel not specified in the contract
**Expected behavior:** Either the graph type system prevents the write at construction time, or the channel carries a null/default value. The implementation node does not silently overwrite the committed contract.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-003 (satisfaction: X.XX) — the DIG pre-code gate did not correctly commit a typed contract, enforce read-only execution, or block downstream nodes on gate failure. Likely failure modes:

- Contract type fail: the DIG gate returned a raw string or an untyped map instead of a typed design contract; the implementation node could not read a structured selected_approach.
- Downstream non-compliance fail: the implementation node used a hardcoded default or ignored the committed contract rather than reading selected_approach from the typed channel.
- Read-only violation fail: external write-classified calls were recorded during Phase 1 (gate execution), violating the read-only gate requirement.
- Failure-propagation fail: when the DTU mock returned an invalid contract, the gate did not surface a structured error, or the implementation node executed anyway with a partial or fabricated contract.
- Determinism fail: two invocations with identical inputs and mock configuration returned different selected_approach values."

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
