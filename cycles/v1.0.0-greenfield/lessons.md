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

## Infrastructure-Level

<!-- No lessons yet. -->

## Policy Candidates

| Lesson | Proposed Policy | Scope | Status |
|--------|----------------|-------|--------|
| — | — | — | — |
