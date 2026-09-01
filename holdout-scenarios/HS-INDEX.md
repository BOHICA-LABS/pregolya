---
document_type: holdout-scenario-index
level: ops
version: "1.8"
status: active
producer: product-owner
timestamp: 2026-08-31T00:00:00Z
phase: 2
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "d381e81"
traces_to: .factory/specs/prd.md
changelog:
  - "1.8 (Round-52 Stage-C/2026-08-31): F-P2A219-03 fix — HS-D-007 promoted from should-pass to must-pass. Durable trajectory persistence is the only Domain-D holdout exercising the SS-04 trajectory primitive (a core P1 contract); asymmetric classification with sibling ledger holdouts HS-D-008/009 was unjustified. Domain D totals updated: 7 must-pass, 2 should-pass (7/9 = 77.8%). Aggregate must-pass updated: 17/24 = 70.8% (> required 60%). Must-pass subset rationale paragraph updated."
  - "1.7 (Round-50 B2/2026-08-31): F-P2A211-08 fix — HS-D-007 re-scoped from checkpoint super-step replay to dedicated trajectory recording primitive (BC-2.04.009/010/011); prior v1.0 was satisfiable with trajectory absent. HS-D-008 added (must-pass): dedup-idempotent evidence accumulation and first-appearance ordering (BC-2.02.007/008). HS-D-009 added (must-pass): active-set promote/retire lifecycle with idempotency (BC-2.02.009). Domain D totals updated to 9 scenarios, 6 must-pass, 3 should-pass (6/9 = 66.7%). Aggregate totals updated to 24 scenarios, 16 must-pass (16/24 = 66.7%). Capability Coverage Map extended with trajectory and ledger_channel areas."
  - "1.6 (Domain-D/Stage-2b/2026-08-31): Domain D (Autonomous Research Orchestrator) added — 7 scenarios HS-D-001..007 covering generation-loop resume, panel deliberation, DIG pre-code gate, QD diversity allocation, multi-provider peer nodes, budget/guardrail gating, and audit-grade trajectory replay. Must-pass subset: HS-D-001/002/003/005 (4/7 = 57%, consistent with Domain B ratio). Aggregate totals updated to 22 scenarios, 14 must-pass. Phase-4 gate extended to include Domain D. Capability coverage map extended with new Domain D entries. Asymmetry Confirmation updated for Domain D. Asymmetry confirmed clean via verify-holdout-asymmetry.sh (ZERO WARN across 23 files)."
  - "1.5 (round-24/F-P2A105-01+F-P2A105-02+GAP-R24-01+GAP-R24-02/2026-08-28): EXHAUSTIVE asymmetry scrub of HS-C-001 (round-23 scrub was incomplete). §Failure Guidance Check 5 fail bullet and §Evaluation Rubric must-pass threshold paragraph purged of residual internal identifiers. §Edge Conditions EC-006 stale '(Contingent on gap resolution.)' marker removed. §Information Asymmetry Confirmation in HS-C-001 rewritten as CLOSED-SET declaration enumerating confirmed-FREE evaluator-facing sections (Scenario, Verification Approach, Evaluation Rubric, Failure Guidance, Edge Conditions) and exempted non-evaluator metadata sections (BC Linkage table, Coverage Gap note). HS-INDEX §Asymmetry Confirmation updated to reflect expanded confirmed-free section list."
  - "1.4 (round-23/F-1/2026-08-28): F-1 [BLOCKER]: HS-C-001 §Acceptance-Criteria asymmetry scrub applied — §Verification Approach step 8 and §Evaluation Rubric Check 5 purged of BC/VP/error-code identifiers; replaced with observable behavioral descriptions. §Asymmetry Confirmation claim (Scenario, Verification Approach, Evaluation Rubric sections free of BC IDs, VP IDs, error code identifiers, and implementation structure references) is now confirmed accurate for all three sealed domains."
  - "1.3 (GAP-01-RESOLVED/2026-08-26): HS-C-001-GAP-01 RESOLVED — BC-2.09.008 (GraphAgentTool; mcp::graph_tool; ADR-029) human-approved v1 scope addition (2026-08-26). Check 5 promoted to first-class must-pass; contingency note removed. HS-C-001 now covers all 7 primitives including StateGraph→Tool wrapping. Domain C coverage gap closed."
  - "1.2 (HS-C-001/flowloom-embedding/2026-08-26): Domain C (Flowloom Embedding Host) added with one must-pass scenario HS-C-001. Aggregate counts updated. Capability coverage map updated. Phase-4 gate extended to include Domain C. Coverage gap HS-C-001-GAP-01 noted (StateGraph→Tool wrapping unspecified)."
  - "1.1 (F-P2A003-06, P2A-003-fix-burst, 2026-08-19): Phase-4 gate wording updated to reference both sealed domains (A+B) with explanatory note re five design-forcing analysis domains; HS-B-006 title corrected in index table."
  - "1.0 (initial, 2026-08-18): base index authored."
---

# Holdout Scenario Index

> **SEALED — Phase 4 use only.**
> Holdout scenarios must NEVER be shared with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Phase 4 Gate (from product-brief.md §Success Criteria)

- Mean holdout satisfaction ≥ 0.85 (across all active scenarios)
- Each `must_pass` scenario individually ≥ 0.60
- All four sealed holdout domains (Domain A, Domain B, Domain C, Domain D) pass their domain-level gate

> **Note on domain count:** The product brief references five design-forcing holdout analysis domains (D8, D22). Of these, two were promoted to sealed Phase 4 acceptance scenarios at Phase 2: Domain A (Virtual SOC Analyst) and Domain B (Dark Factory / Autonomous Software Pipeline). Domain C (Flowloom Embedding Host) was added after Phase 2 via a targeted authoring request (2026-08-26) with provenance tag `origin: flowloom-embedding`. Domain D (Autonomous Research Orchestrator) was added via Stage 2b new use case authoring (2026-08-31) with provenance tag `origin: new-use-case-stage-2b`. The gate criterion above applies to all four sealed domains.

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

## Domain C — Flowloom Embedding Host

| HS ID | Title | Category | Priority | Coverage Areas | Status |
|-------|-------|----------|----------|----------------|--------|
| HS-C-001 | Flowloom Embedding Host — Full-Stack Agent Integration (MCP In/Out, HITL, Checkpoint, Streaming, Isolation) | integration-boundaries | must-pass | mcp, tools, hitl, checkpoint_resume, streaming, graph_execution, server, tenancy | active |

> **HS-C-001-GAP-01 RESOLVED 2026-08-26 — BC-2.09.008 (GraphAgentTool; mcp::graph_tool; ADR-029) authored;
> Check 5 first-class must-pass; VP-016 proptest P1 proof target / E-MCP-010 fail-closed interrupt boundary.**

**Domain C totals:** 1 scenario, 1 must-pass, 0 should-pass.

---

## Domain D — Autonomous Research Orchestrator

| HS ID | Title | Category | Priority | Coverage Areas | Status |
|-------|-------|----------|----------|----------------|--------|
| HS-D-001 | Generation Loop Persistence and Evidence Resume | integration-boundaries | must-pass | graph_execution, checkpoint_resume, providers | active |
| HS-D-002 | Panel-Topology Deliberation — Anonymized Cross-Review and Chair Reduction | integration-boundaries | must-pass | graph_execution, composition, providers, structured_output | active |
| HS-D-003 | DIG Pre-Code Gate — Read-Only Contract Selection Before Implementation | integration-boundaries | must-pass | graph_execution, composition, structured_output, providers | active |
| HS-D-004 | QD Diversity Allocation — Cohort Diversity Cap Enforcement | edge-case-combinations | should-pass | graph_execution, structured_output, composition | active |
| HS-D-005 | Multi-Provider Peer Agent Nodes with Shared MCP Tool Access | integration-boundaries | must-pass | graph_execution, providers, mcp, tools, composition | active |
| HS-D-006 | Budget and Guardrail Gating — Structured Refusal and Ceiling Enforcement | edge-case-combinations | should-pass | graph_execution, checkpoint_resume, providers | active |
| HS-D-007 | Durable Audit-Grade Trajectory Replay | edge-case-combinations | must-pass | trajectory, checkpoint_resume, streaming | active |
| HS-D-008 | Dedup-Idempotent Evidence Accumulation with First-Appearance Ordering | integration-boundaries | must-pass | graph_execution, ledger_channel, composition | active |
| HS-D-009 | Active-Set Promote/Retire Lifecycle with Idempotency | integration-boundaries | must-pass | graph_execution, ledger_channel, composition | active |

**Domain D totals:** 9 scenarios, 7 must-pass, 2 should-pass.

> **Must-pass subset rationale:** HS-D-001/002/003/005/007/008/009 (7/9 = 77.8%) selected as must-pass. HS-D-001/002/003/005 cover the critical integration-boundary behaviors: durable generation-loop resume, multi-agent panel deliberation, pre-implementation read-only gate enforcement, and multi-provider tool-access correctness. HS-D-008 and HS-D-009 cover the SS-02 channel primitives (dedup-idempotent ledger accumulation and promote/retire active-set lifecycle). HS-D-007 is promoted to must-pass (F-P2A219-03) because it is the only Domain-D holdout exercising the SS-04 trajectory primitive — durable audit-grade persistence and crash-isolated compaction are core P1 contracts, not boundary-condition niceties; asymmetric classification with HS-D-008/009 (both must-pass) was unjustified. HS-D-004 and HS-D-006 (edge-case-combinations) remain should-pass: they test cohort diversity-cap enforcement and budget/guardrail boundary conditions that are important but not blocking for the framework's core contract. Domain D ratio 7/9 = 77.8%; overall must-pass ratio 17/24 = 70.8% (> required 60%).

---

## Aggregate Summary

| Metric | Value |
|--------|-------|
| Total scenarios (Domain A + B + C + D) | 24 |
| Must-pass scenarios | 17 |
| Should-pass scenarios | 7 |
| Must-pass ratio | 17/24 = 70.8% (> required 60%) |
| real-world-corpus scenarios | 2 (HS-A-005, HS-B-007) |
| security-probes | 1 (HS-A-007) |
| edge-case-combinations | 6 (HS-A-006, HS-B-004, HS-B-006, HS-D-004, HS-D-006, HS-D-007) |
| integration-boundaries | 15 |

---

## Capability Coverage Map

| Capability Area | Exercised By |
|-----------------|-------------|
| composition | HS-A-001, HS-A-005, HS-A-007, HS-B-001, HS-B-005, HS-B-007, HS-D-002, HS-D-003, HS-D-004, HS-D-005, HS-D-008, HS-D-009 |
| graph_execution | HS-A-002, HS-A-003, HS-A-004, HS-A-006, HS-B-001, HS-B-002, HS-B-003, HS-B-004, HS-B-005, HS-B-006, HS-C-001, HS-D-001, HS-D-002, HS-D-003, HS-D-004, HS-D-005, HS-D-006, HS-D-008, HS-D-009 |
| checkpoint_resume | HS-A-003, HS-A-004, HS-B-002, HS-B-003, HS-B-004, HS-B-006, HS-C-001, HS-D-001, HS-D-006, HS-D-007 |
| trajectory | HS-D-007 |
| ledger_channel | HS-D-008, HS-D-009 |
| hitl | HS-A-004, HS-B-003, HS-C-001 |
| mcp | HS-A-002, HS-C-001, HS-D-005 |
| tools | HS-A-002, HS-A-007, HS-C-001, HS-D-005 |
| providers | HS-A-001, HS-A-002, HS-A-003, HS-A-005, HS-A-006, HS-B-001, HS-B-005, HS-B-007, HS-D-001, HS-D-002, HS-D-003, HS-D-005, HS-D-006 |
| streaming | HS-A-001, HS-A-006, HS-B-007, HS-C-001, HS-D-007 |
| structured_output | HS-A-001, HS-A-005, HS-B-001, HS-B-007, HS-D-002, HS-D-003, HS-D-004 |
| retrieval | HS-B-007 |
| server | HS-B-003, HS-C-001 |
| tenancy | HS-C-001 |

---

## Wave Holdout Scenarios (cycle-scoped)

None authored at Phase 2. Wave holdout scenarios are cycle-scoped artifacts authored during Phase 3 delivery.

| WHS ID | Title | Wave | Target Stories | Status |
|--------|-------|------|---------------|--------|
| — | — | — | — | — |

---

## Asymmetry Confirmation

All evaluator-facing sections of every scenario narrative (Scenario, Verification Approach,
Evaluation Rubric, Failure Guidance, Edge Conditions) are confirmed FREE of:
- BC IDs (BC-S.SS.NNN)
- VP IDs (VP-NNN)
- Internal module names (e.g., pregolya_graph::StateGraph)
- Error code identifiers (e.g., E-CORE-NNN, E-XXX-NNN)
- Implementation structure references

The following sections legitimately retain traceability IDs and are NOT part of the
evaluator's scenario narrative:
- §Behavioral Contract Linkage tables (BC-ID / clause / check cross-reference)
- Frontmatter `behavioral_contracts:` arrays
- Coverage gap notes (gap provenance, BC authorship, resolution references)

This confirmed-free claim was verified exhaustively in round-24 for all three sealed domains
(Domain A, B, C). HS-C-001 was the subject of the round-24 exhaustive scrub.

Domain D (HS-D-001 through HS-D-007) was verified clean at authoring time (2026-08-31,
Stage-2b burst). verify-holdout-asymmetry.sh reported ZERO evaluator-facing internal
identifiers across all 23 HS-*.md files (PASS=1 WARN=0 FAIL=0).

HS-D-007 (re-scoped v2.0), HS-D-008, and HS-D-009 were authored in Round-50 B2
(2026-08-31) following F-P2A211-08 remediation. All three files were verified clean by
verify-holdout-asymmetry.sh (ZERO evaluator-facing internal identifiers; PASS=1 WARN=0
FAIL=0 across all 25 HS-*.md files). BC IDs (BC-2.04.009/010/011, BC-2.02.007/008/009)
appear only in §Behavioral Contract Linkage tables and frontmatter behavioral_contracts
arrays — both exempted sections per the traceability-metadata policy above.
