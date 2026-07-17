---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T18:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 95
previous_review: pass-94.md
---

# Adversarial Review: ferrochain (Pass 95)

## Finding ID Convention

Finding IDs for this pass use the format `F-P95-NN` (project-local shorthand). Canonical ADV IDs: `ADV-P1CONV-P95-MED-001` through `ADV-P1CONV-P95-LOW-002`; observation `OBS-P95-A`.

## Part A — Fix Verification (burst-176 sibling-checks)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P94-02 (TV-006 renumber) | MED | RESOLVED | BC-2.10.004 v1.5 sequential TV-001..006 verified; test-vectors v1.8 arithmetic 504+9=513 exact recount PASS |
| F-P94-03 (BC-2.10.001 dispatch propagation) | MED | RESOLVED | BC-2.10.001 v1.4 + BC-2.10.002 v1.2 + events.md v1.2 coherence vs interface-definitions v2.33 decision table PASS |
| F-P94-01 (BC-INDEX title sync) | MED | RESOLVED | BC-INDEX byte-exact H1 match for BC-2.10.003/BC-2.10.004 confirmed PASS |

**Burst-176 sibling-checks: 5/5 PASS.** Major positive signal: SS-10 budget model fully converged and propagated (BC bodies, index, test-vectors 513=504+9 recounted exact, events, interface v2.33).

## Content Probe Results (Full-Depth Owed Probes)

- SS-03 semantic coherence (super-step ceiling arithmetic): PASS
- SS-12 semantic coherence (Run lifecycle state machine, all E-codes resolve): PASS
- ADR-003 durability coherent: PASS
- Server endpoints (7 signatures verified): PASS
- TV-index 10-BC sampling: PASS (exact matches)

## Part B — New Findings

### MEDIUM

#### F-P95-01 (MED): ADR Budget-Evaluation Placement Inconsistent with BC Canon

- **Severity:** MEDIUM
- **Category:** contradictions
- **Location:** ADR-001-graph-execution-model.md (4 sites), ADR-009-budget-governance-placement.md (3 sites), ADR-012-self-improvement-primitives.md (2 sites)
- **Description:** ADR-001 placed budget evaluation "between super-steps" (specifically: "Evaluating budget policy between super-steps" in §Orchestrator responsibilities item 7; "budget governance fit between orchestrator state transitions" in §Alternative B Pros; "orchestrator transition concern" in §Decision rationale; "transition hook between Reducing and Checkpointing" in §Consequences). This directly contradicts BC canon: BC-2.10.001 PC1/PC2 specifies per-LLM-call and per-tool-invocation within tick() during the Collecting phase; BC-2.10.003 EC-001 specifies in-flight tasks settle before halt; BC-2.10.003 PC9 specifies RunContext.budget_info population before task dispatch (a pre-dispatch activity, not post-Reducing). The same stale "between-super-steps" characterization appeared in ADR-009 and ADR-012.
- **Evidence:** ADR-001 §Orchestrator responsibilities: "7. Evaluating budget policy between super-steps". BC-2.10.001 PC1: "The engine evaluates budget policy on every LLM call and tool invocation within a super-step (tick() loop)."
- **Proposed Fix:** Reconcile ADR prose with BC canon. Correct model: EVALUATION per-call during Collecting; HALT EXECUTION lands at super-step boundary after in-flight settle; budget_info POPULATION is the legitimate phase-boundary activity.

#### F-P95-02 (MED [process-gap]): Gate #13 VP-Census Regex Inert for Multi-Segment IDs

- **Severity:** MEDIUM
- **Category:** coverage-gap
- **Location:** bc-authoring-plan.md §Gate #13 VP-census command
- **Description:** The gate #13 VP-census regex `VP-[A-Z]+-[0-9]+` is inert for multi-segment or digit-bearing domain prefixes. VP-BSP-DET-01 (prefix BSP-DET contains an embedded hyphen) and VP-DI001-01 (prefix DI001 contains digits) are invisible to the census. SS-03's entire VP set may be undetectable. The gate has been returning a false-green VP uniqueness verdict for every pass since gate #13 was introduced.
- **Evidence:** Running `grep -rE 'VP-[A-Z]+-[0-9]+' .factory/specs/behavioral-contracts/` extracts 71 IDs. Running `grep -rE 'VP-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]+' .factory/specs/behavioral-contracts/` extracts 141 IDs. Difference = 70 IDs invisible under old regex.
- **Proposed Fix:** Update regex to `VP-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]+`. Re-run census and record new count in bc-authoring-plan.

### LOW

#### F-P95-03 (LOW): BC-2.10.004 Verbatim Duplicate and Malformed PC Numbering

- **Severity:** LOW
- **Category:** spec-fidelity
- **Location:** BC-2.10.004.md §Postconditions
- **Description:** BC-2.10.004 contained verbatim-duplicate PC1b/PC2b text and malformed numbering (1a/1b/2/2b — mixing alphabetic sub-numbering with plain numeric 2 and then 2b). The duplicate body was a copy-paste hazard and the numbering convention was non-standard across the corpus.
- **Evidence:** PC1b and PC2b contained identical text blocks; the sequence 1a→1b→2→2b does not follow any established BC numbering pattern.
- **Proposed Fix:** Restructure to clean PC1..PC4 with one statement of the Deny condition. Update BC-2.10.001 v1.4 Related-BCs cite to reflect the restructured PC numbers.

#### F-P95-04 (LOW): CAP-012 Missing D20 Summarize Mode

- **Severity:** LOW
- **Category:** missing-edge-cases
- **Location:** capabilities-p0.md §CAP-012
- **Description:** CAP-012 in capabilities-p0 v1.2 enumerated only halt and escalate-to-HITL as budget ceiling responses. The D20 Summarize mode (OnCeiling::Summarize / summary_halt) was absent. BC-2.10.003 PC8 requires the Summarize mode.
- **Evidence:** capabilities-p0 v1.2 CAP-012 text lists two modes only. BC-2.10.003 PC8 references OnCeiling::Summarize. BC-2.10.004 v1.5 §CAP-012 verbatim quote was stale relative to the missing mode.
- **Proposed Fix:** Add three-mode enumeration to CAP-012. Refresh BC-2.10.004 CAP-012 verbatim quote in the same burst.

### OBSERVATION

#### OBS-P95-A: VP-SPLIT 3-Digit Width Non-Standard

- **Severity:** OBSERVATION
- **Category:** spec-fidelity
- **Location:** BC-2.07.001, BC-2.07.002, BC-2.07.003 (VP-SPLIT domain)
- **Description:** VP-SPLIT IDs use 3-digit width (VP-SPLIT-001 through VP-SPLIT-008) while all other VP domains use 2-digit width (VP-BUDGET-01, VP-STREAM-01, etc.). Blast radius = 3 files — below the >5 threshold for mandatory deferral.
- **Proposed Fix:** Renumber VP-SPLIT-001..008 to VP-SPLIT-01..08 in the 3 affected BC files.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 2 |
| LOW | 2 |
| OBSERVATION | 1 |

**Overall Assessment:** pass-with-findings (all fixed in-burst)
**Convergence:** FINDINGS_REMAIN — iterate; counter stays 0/3
**Readiness:** All 5 findings fixed in burst 177; adversary pass 96 next

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 95 |
| **New findings** | 5 (all genuinely new — no prior pass found any of these specific issues) |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 5 / (5 + 0) = 1.0 |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4 |
| **Verdict** | FINDINGS_REMAIN |
