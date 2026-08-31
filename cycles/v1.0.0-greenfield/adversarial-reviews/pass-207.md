---
document_type: adversarial-review
level: ops
pass_id: P2A-207
pass_label: ROUND-49 SS-09/SS-11 DEEP-AUDIT
frozen_head: 2c7ab45
review_head: 2c7ab45
date: 2026-08-31
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-31T00:00:00Z"
phase: 2
pass: 207
previous_review: pass-206.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P2A-207 ROUND-49 SS-09/SS-11 DEEP-AUDIT (CLOSED)

> **RECORD STATUS: CLOSED.** 4 findings (2 HIGH + 1 MED + 1 OBS). CLEAN(strict): NO. CLEAN(PR-merge): NO (2 HIGH). Streak: 0/3 (reset on fix-burst push). Frozen spec HEAD: `2c7ab45` (post-D-325 push). Phase-2 re-convergence pass (round-49, lens 4: SS-09/SS-11 deep-audit).

## Finding ID Convention

Finding IDs use the format `F-P2A207-NN` for substantive findings and `OBS-P2A207-NN` for observations. Canonical format per template: `ADV-P2CONV-P207-<SEV>-<SEQ>`. Phase-2 shorthand applied throughout.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P2A-207 ROUND-49 SS-09/SS-11 DEEP-AUDIT |
| Frozen spec HEAD | `2c7ab45` |
| Date | 2026-08-31 |
| Pass total | Phase-2 pass 207 (round-49, lens 4) |
| Method | SS-09 (MCP tool invocation) and SS-11 (guardrail/memory) deep-audit — dependency isolation, module-decomposition home completeness, DI-seam homelessness, phantom anchor citations. |
| Scope | S-2.10 forbidden-deps clause vs ADR-029/S-2.11 actual graph dependency; InvocationContext type home in module-decomposition + BC preconditions; BC-2.09.003 phantom context.rs anchor; GraphAgentTool Arc-DI assertion gap. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** (2 HIGH) |
| 3-CLEAN streak (BC-5.39.001) | **0/3** |

## Part A — Fix Verification

SS-09/SS-11 prior-round fixes verified: BC-2.09.007 {INV-003}(b) 6-pattern canonical set (round-49 Stage-2 closure) confirmed present; ADR-029 §SEC-BOUND-001 BC attribution correction (round-49 Stage-2) confirmed; BC-2.09.008 {INV-001} STATE-ISOLATION invariant confirmed unchanged. No regression on round-46/47/48 SS-09/SS-11 closures.

## Part B — New Findings

### HIGH

#### F-P2A207-01 [HIGH] — S-2.10 forbidden-deps bans pregolya-mcp→pregolya-graph, contradicts ADR-029/S-2.11

**Description:** Story S-2.10 (MCP client tool discovery and invocation) included a forbidden-deps clause explicitly banning `pregolya-mcp → pregolya-graph` as a disallowed dependency. However, ADR-029 (§Graph-Agent-Tool Wrapping) explicitly REQUIRES the `GraphAgentTool` in `pregolya-mcp` to hold an `Arc<CompiledStateGraph>` from `pregolya-graph`. Story S-2.11 (MCP server tool advertisement) implements `GraphAgentTool` and therefore REQUIRES the `pregolya-mcp → pregolya-graph` edge. The S-2.10 forbidden-deps clause was inconsistent with the established architecture: banning a mandatory dependency would cause S-2.11 to fail its own acceptance criteria. This is a HIGH spec-contradiction defect (conflicting mandatory/forbidden directives on the same dependency edge).

**Disposition:** CLOSED. S-2.10 (v1.4→v1.5) forbidden-deps clause updated: `pregolya-mcp → pregolya-graph` removed from banned list; carve-out annotation added: "Exception: `mcp::graph_tool` (GraphAgentTool) REQUIRES `pregolya-graph::CompiledStateGraph` per ADR-029; this dependency edge is explicitly permitted for the graph-agent-tool module only." ARCH-INDEX (v1.59→v1.60) module-decomposition InvocationContext row added.

#### F-P2A207-02 [HIGH] — InvocationContext DI seam un-homed in module-decomposition

**Description:** BC-2.11.001 and BC-2.11.002 both reference `InvocationContext` as a precondition DI object ("the server provides an `InvocationContext` to each guardrail hook invocation"). However, `InvocationContext` had no assigned home in `module-decomposition.md`. No module row defined it, no creating story owned it, no Arc-DI constructor was assigned. A DI-seam type named in BC preconditions with no module-decomposition home is a phantom type from the implementation perspective: the implementer has no canonical location to define it. This survives spec-perimeter review because the type appears in BC text (making it "defined") without being anchored to a module or story.

**Disposition:** CLOSED. `interface-definitions.md` (v3.01→v3.02) §InvocationContext section added: canonical DI seam type definition (`pregolya-core/src/invocation_context.rs`; SS-11 scope). `module-decomposition.md` (v1.59→v1.60) `core::invocation_context` definitions-only row added. `module-criticality.md` (v2.18→v2.19) corresponding row added. S-1.19 (v1.8→v1.9) AC-026 updated to canonicalize `InvocationContext` home. BC-2.11.001 (v1.6→v1.8) and BC-2.11.002 (v1.18→v1.19) preconditions updated to cite `pregolya-core::invocation_context::InvocationContext`. L-241 codified (DI-seam type un-homed in module-decomposition surviving 48 rounds).

### MEDIUM

#### F-P2A207-03 [MED] — BC-2.09.003 phantom context.rs anchor

**Description:** BC-2.09.003 (Tool-result as untrusted ingress) contained a spec anchor citation pointing to `context.rs` in the module notes. No `pregolya-mcp/src/context.rs` file is defined in the module-decomposition. The type that was intended here is `InvocationContext` (homed in `pregolya-core` as found by F-P2A207-02). The phantom `context.rs` anchor would cause the test-writer to look for a non-existent module and potentially create it in the wrong crate.

**Disposition:** CLOSED. BC-2.09.003 (v1.8→v1.9) phantom `context.rs` citation replaced with canonical `pregolya-core::invocation_context::InvocationContext` per module-decomposition row added in F-P2A207-02 closure.

### OBS

#### OBS-P2A207-04 [OBS] — GraphAgentTool Arc-DI constructor not explicitly asserted in test-vectors

**Description:** BC-2.09.008 {INV-001} specifies STATE-ISOLATION and the `GraphAgentTool` holding an `Arc<CompiledStateGraph>`. The Arc-DI constructor requirement is mentioned in the PC (preconditions) but no test vector explicitly asserts that `GraphAgentTool::new(Arc<CompiledStateGraph>)` is the canonical construction form, and no TV verifies that constructing `GraphAgentTool` without passing an `Arc<CompiledStateGraph>` is a compile error. This is a test-vector coverage gap for Arc-DI constructor enforcement.

**Disposition:** CLOSED-OBS-IN-SCOPE. BC-2.09.008 {PC-001} arc-constructor assertion tightened. No new TV minted (OBS severity; covered by VP-016 proptest scope which exercises the full `GraphAgentTool` construction path). OBS-P2A207-04 logged as standing structural lesson; no story blocker.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 1 |
| LOW | 0 |
| OBS | 1 |
| PROCESS-GAP | 0 |
| **Total** | **4** |

**Overall Assessment:** NOT CLEAN (strict). NOT CLEAN (PR-merge).
**CLEAN(strict): NO | CLEAN(PR-merge): NO (2 HIGH) | streak: 0/3**

## GATE-READY Audit Result (round-49)

Appended to P2A-207 per convention (final pass of round).

| Gate | Result |
|------|--------|
| GATE-READY audit | **13/13 PASS** |
| Standing OBS | STORY-INDEX missing `level:` field — CLOSED in round-49 Stage-3 (STORY-INDEX §level-field adds `level: L3`). |

All 13 gate checks passed after fix-burst closure. No blocking HRQs remain for round-49.

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 207 |
| **New findings** | 4 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 4 / (4 + 0) = 1.0 |
| **Median severity** | HIGH |
| **Trajectory** | →2→2→1→1→2→3→0→4 |
| **Verdict** | FINDINGS_REMAIN (round-49 NOT CLEAN(strict); 7 total findings across 4 passes; 1/4 lenses CLEAN(strict) [P2A-206]; ALL FINDINGS CLOSED; streak 0/3 [reset on D-326 push]; NEXT round-50) |
