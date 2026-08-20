---
document_type: holdout-scenario-index
level: ops
version: "1.1"
status: active
producer: product-owner
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "3102b0a"
traces_to: .factory/specs/prd.md
changelog:
  - "1.0 (initial, 2026-08-18): base index authored."
  - "1.1 (F-P2A003-06, P2A-003-fix-burst, 2026-08-19): Phase-4 gate wording updated to reference both sealed domains (A+B) with explanatory note re five design-forcing analysis domains; HS-B-006 title corrected in index table."
---

# Holdout Scenario Index

> **SEALED — Phase 4 use only.**
> Holdout scenarios must NEVER be shared with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Phase 4 Gate (from product-brief.md §Success Criteria)

- Mean holdout satisfaction ≥ 0.85 (across all active scenarios)
- Each `must_pass` scenario individually ≥ 0.60
- Both sealed holdout domains (Domain A and Domain B) pass their domain-level gate

> **Note on domain count:** The product brief references five design-forcing holdout analysis domains (D8, D22). Of these, two were promoted to sealed Phase 4 acceptance scenarios: Domain A (Virtual SOC Analyst) and Domain B (Dark Factory / Autonomous Software Pipeline). The three remaining design-forcing domains were not promoted to sealed scenarios at Phase 2. The gate criterion above applies to the two sealed domains only.

---

## Domain A — Virtual SOC Analyst Agent

| HS ID | Title | Category | Priority | Coverage Areas | Status |
|-------|-------|----------|----------|----------------|--------|
| HS-A-001 | Single Alert Triage — Basic End-to-End | integration-boundaries | must-pass | composition, providers, streaming, structured_output | active |
| HS-A-002 | Parallel Enrichment Fan-Out with Partial Failure | integration-boundaries | must-pass | graph_execution, mcp, tools, providers | active |
| HS-A-003 | Durable Multi-Stage Investigation Surviving Process Restart | integration-boundaries | must-pass | checkpoint_resume, graph_execution, providers | active |
| HS-A-004 | Risk-Tiered Human Approval Gate Before Containment Action | integration-boundaries | must-pass | hitl, checkpoint_resume, graph_execution | active |
| HS-A-005 | Real-World Attack Corpus Triage — FP and TP Discrimination | real-world-corpus | should-pass | composition, providers, structured_output, graph_execution | active |
| HS-A-006 | High-Volume Concurrent Alert Triage — Scheduler Fairness | edge-case-combinations | should-pass | graph_execution, providers, streaming | active |
| HS-A-007 | Prompt Injection Resistance at Tool Result Boundary | security-probes | must-pass | tools, composition, providers | active |

**Domain A totals:** 7 scenarios, 5 must-pass, 2 should-pass.

---

## Domain B — Dark Factory / Autonomous Software Pipeline

| HS ID | Title | Category | Priority | Coverage Areas | Status |
|-------|-------|----------|----------|----------------|--------|
| HS-B-001 | Spec-Driven Pipeline Phase Traversal with Quality Gate | integration-boundaries | must-pass | graph_execution, composition, structured_output, providers | active |
| HS-B-002 | Checkpoint Resume After Simulated Crash Mid-Wave | integration-boundaries | must-pass | checkpoint_resume, graph_execution | active |
| HS-B-003 | Human Approval Interrupt at Phase Boundary — Cross-Process Resume | integration-boundaries | must-pass | hitl, checkpoint_resume, graph_execution, server | active |
| HS-B-004 | Convergence Loop Terminates at Fixed Point — Streak Resets on New Finding | edge-case-combinations | should-pass | graph_execution, checkpoint_resume | active |
| HS-B-005 | Parallel Sub-Agent Fan-Out with Context Isolation and Result Synthesis | integration-boundaries | must-pass | graph_execution, composition, providers | active |
| HS-B-006 | Budget-Bounded Run — Graceful Ceiling Handling with No Silent Overrun | edge-case-combinations | should-pass | graph_execution, checkpoint_resume | active |
| HS-B-007 | Real-World Specification Corpus Pipeline — Known-Good and Known-Incomplete | real-world-corpus | should-pass | composition, providers, retrieval, streaming, structured_output | active |

**Domain B totals:** 7 scenarios, 4 must-pass, 3 should-pass.

---

## Aggregate Summary

| Metric | Value |
|--------|-------|
| Total scenarios (Domain A + B) | 14 |
| Must-pass scenarios | 9 |
| Should-pass scenarios | 5 |
| Must-pass ratio | 9/14 = 64% (> required 60%) |
| real-world-corpus scenarios | 2 (HS-A-005, HS-B-007) |
| security-probes | 1 (HS-A-007) |
| edge-case-combinations | 3 (HS-A-006, HS-B-004, HS-B-006) |
| integration-boundaries | 8 |

---

## Capability Coverage Map

| Capability Area | Exercised By |
|-----------------|-------------|
| composition | HS-A-001, HS-A-005, HS-A-007, HS-B-001, HS-B-005, HS-B-007 |
| graph_execution | HS-A-002, HS-A-003, HS-A-004, HS-A-006, HS-B-001, HS-B-002, HS-B-003, HS-B-004, HS-B-005, HS-B-006 |
| checkpoint_resume | HS-A-003, HS-A-004, HS-B-002, HS-B-003, HS-B-004, HS-B-006 |
| hitl | HS-A-004, HS-B-003 |
| mcp | HS-A-002 |
| tools | HS-A-002, HS-A-007 |
| providers | HS-A-001, HS-A-002, HS-A-003, HS-A-005, HS-A-006, HS-B-001, HS-B-005, HS-B-007 |
| streaming | HS-A-001, HS-A-006, HS-B-007 |
| structured_output | HS-A-001, HS-A-005, HS-B-001, HS-B-007 |
| retrieval | HS-B-007 |
| server | HS-B-003 |

---

## Wave Holdout Scenarios (cycle-scoped)

None authored at Phase 2. Wave holdout scenarios are cycle-scoped artifacts authored during Phase 3 delivery.

| WHS ID | Title | Wave | Target Stories | Status |
|--------|-------|------|---------------|--------|
| — | — | — | — | — |

---

## Asymmetry Confirmation

All scenario narratives (Scenario, Verification Approach, Evaluation Rubric sections) are free of:
- BC IDs (BC-S.SS.NNN)
- VP IDs (VP-NNN)
- Internal module names (e.g., pregolya_graph::StateGraph)
- Error code identifiers (e.g., E-CORE-NNN)
- Implementation structure references

BC linkage tables and frontmatter `behavioral_contracts:` fields are traceability metadata for product-owner/pipeline use — they are NOT part of the evaluator's scenario narrative.
