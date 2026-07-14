---
document_type: lessons-learned
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-14T01:00:00Z
cycle: v1.0.0-greenfield
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Lessons Learned — v1.0.0-greenfield

<!-- Durable lessons from this cycle for future VSDD factory runs.
     Organized by category: agent-level, process-level, infrastructure-level.
     Each lesson is numbered continuously and includes the pass/burst
     where it was discovered. -->

## Agent-Level

<!-- No lessons yet. Append here as lessons are captured. -->

## Process-Level

### L-001 [process-gap, codified]: §17-C Status-Code Census Was Inert — Positive-Coverage Assertion Required

**Discovered:** Pass 25 (burst 101)
**Symptom:** The §17-C census in bc-authoring-plan.md was structured as an absence-check only — it would report PASS if no disallowed codes were present, but never grep-verified that required PASS-row codes (201, 204, 502, 503, 504) actually appeared in the target status table. F-P25-07 revealed that 201/204/502/503/504 rows were absent from the status table yet §17-C had been reporting PASS for multiple prior passes.
**Root cause:** Census was written as "verify no bad codes" without a complementary "verify all expected good codes exist" assertion.
**Codified fix:** §17-C now requires a positive-coverage assertion: for each code in the MUST-APPEAR list, grep the status table and fail the census if any expected row is absent. Implemented in bc-authoring-plan.md §17-C.
**Applicable to:** Any census gate that validates presence of a required set (not just absence of a forbidden set). Both halves are required for completeness.

### L-002 [process-gap, codified]: BC Absolute "Must Not Diverge" Invariants Must Carry Precedence Carve-Outs

**Discovered:** Pass 25 (burst 101)
**Symptom:** BC-2.14.002 contained an absolute invariant "per-endpoint status codes MUST NOT diverge from the categorical table" with no exception mechanism. This made the spec self-contradictory: the categorical table is correct as a default-floor, but legitimate per-endpoint contracts (e.g., CRON endpoints returning 201) necessarily override the floor.
**Root cause:** Invariant was authored as a blanket prohibition rather than as a default-with-explicit-override policy.
**Codified fix:** BC-2.14.002 now states that the categorical table is the default floor; per-endpoint status rules documented in the endpoint's own BC take precedence and are not divergence — they are intentional extensions. The invariant now reads as "per-endpoint rules must be explicitly documented and must not contradict the categorical table without a stated rationale."
**Applicable to:** Any BC invariant using absolute prohibition language ("must not", "never", "always") — these should be audited for whether a legitimate override pathway exists and documented if so.

### L-003 [process-gap, codified]: Manual Positive-Coverage Census Not Re-Run After Wildcard Narrowing

**Discovered:** Pass 27 (burst 103)
**Symptom:** The §17-C positive-coverage census (codified in L-001, burst 101) was not re-run after pass-26 narrowed the 422-row wildcard to 8 enumerated VAL E-GRAPH codes. The census row for E-GRAPH-002 remained green (from a pre-narrowing run) despite E-GRAPH-002 now being in a three-way contradiction: it appeared in taxonomy as POLICY (returning 422), the status table showed a wildcard-narrowed 422 row covering VAL codes only, and BC-2.14.002 PC3 had no entry for it. F-P27-01 (HIGH) found the gap.
**Root cause:** The census is a manual step. No gate enforced re-running it when a prerequisite artifact (the status table) changed. The census result was treated as a cached pass.
**Codified fix:** Gate #21 CENSUS RE-RUN TRIGGER added to bc-authoring-plan.md: whenever any status-table wildcard is narrowed or any E-code taxonomy category is changed, §17-C census MUST be re-run before the fix burst is closed. This gate is checked as a sibling-check in the next adversarial pass.
**Deferred improvement (NOT yet codified):** Machine-enforce the census grep via CI/hook — orchestrator to open a follow-up story or deferral entry at cycle close per S-7.02.
**Applicable to:** Any multi-step authoring plan where a downstream census depends on upstream artifact state. Cache invalidation must be explicit: record WHICH artifacts the census depends on and trigger re-run when any of them change.

## Infrastructure-Level

<!-- No lessons yet. -->

### L-004 [process-gap, codified]: Wire-Visible Taxonomy With No Standing Gate Drifts Undetected

**Discovered:** Pass 29 (burst 105)
**Symptom:** The streaming-event surface (SSE chunk type, domain events, envelope keys) had drifted across 5 artifacts — BC-2.12.007, interface-definitions.md, ADR-006, events.md, module-decomposition.md — using inconsistent names (node_delta vs node_stream; past-tense variant names vs imperative canon; astream_events wire-compat claim vs D13 native-wire). None of this was caught through 28 adversarial passes because no standing gate covered streaming-event name coherence. F-P29-03/04/05 (3 HIGH findings) all stem from this single root cause.
**Root cause:** Every wire-visible taxonomy (errors, events, objects) needs its own coherence census from the moment it first appears in specs. The streaming-event surface was introduced in early Phase 1 BCs and ADRs but was never given a corresponding coherence gate — unlike error taxonomy (gated via §17-C census) or wire objects (gated via §18-C sub-field census).
**Codified fix:** Gate #23 STREAMING-EVENT-NAME COHERENCE added to bc-authoring-plan.md: every wire-visible event name (SSE chunk type, domain event, envelope key) must appear consistently in events.md, the StreamEvent enum in ADR-006 (11 imperative variants), and any BC that references it; census must be re-run after any streaming-surface change.
**Applicable to:** Any new wire-visible taxonomy introduced during spec authoring — the moment a named set of events, codes, or objects appears across more than one artifact, a coherence census gate must be added for it. Do not wait for an adversarial pass to discover the gap.

### L-005 [process-gap, codified]: Census Regexes Must Enumerate All Punctuation Forms; Censuses Must Detect Collisions, Not Just Drift

**Discovered:** Pass 34 (burst 110)
**Symptom:** Gate #16 (E-code/variant coherence census) policed space-delimited pairings only (e.g., `E-RETRY-003 CircuitBreakerOpen`). It did not grep colon-delimited forms (e.g., `E-RETRY-003: CircuitBreakerOpen`) nor cross-check each pairing against the error-taxonomy authoritative binding to detect collisions. As a result, E-RETRY-003 carried two contradictory meanings across the BC boundary — error-taxonomy defined it as CircuitBreakerOpen (POLICY/Later) while BC-2.16.001 EC-003 used the same code for InvalidRetryLimit — and this collision survived all 33 prior adversarial passes undetected.
**Root cause:** (1) Census regex matched only one punctuation form; spec authors use both forms interchangeably. (2) Census checked for name-drift (does the code name match across files?) but not for collision (does one code name map to two different concepts?). Both checks are required.
**Codified fix:** Gate #16 widened to two grep forms (space-delimited AND colon-delimited E-code↔variant pairings) + cross-check every pairing against the error-taxonomy authoritative binding (collision detection, not just name drift). Codified in bc-authoring-plan.md gate #16 (D18-P34-C). Full-corpus sweep of 44 pairings confirmed ZERO additional collisions post-fix.
**Applicable to:** Every census gate that polices named identifiers across multiple artifacts. The census must: (a) enumerate ALL punctuation/formatting forms the pattern can appear in; (b) perform both drift-check (name matches across files) AND collision-check (one identifier maps to one concept only). These are two orthogonal failure modes requiring two orthogonal assertions.

## Policy Candidates

| Lesson | Proposed Policy | Scope | Status |
|--------|----------------|-------|--------|
| L-001 | Positive-coverage assertions required for census gates | All census gates | Codified |
| L-002 | Absolute invariants must carry precedence carve-outs | BC authoring | Codified |
| L-003 | Census re-run trigger required after artifact changes | All census gates | Codified (gate #21) |
| L-004 | Wire-visible taxonomy requires coherence gate from first appearance | BC authoring + gate management | Codified (gate #23) |
| L-005 | Census regexes must enumerate all punctuation forms; census must detect collisions AND drift | All census gates | Codified (gate #16) |
