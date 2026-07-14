---
document_type: adversarial-review
cycle: v1.0.0-greenfield
phase: 1d
pass: 1
verdict: NOT CLEAN
timestamp: 2026-07-13T00:00:00Z
scope_attacked: "BC-INDEX, PRD, error-taxonomy, invariants, edge-cases, VP-INDEX, interface-definitions, ss-02/03/04/05/08/11/12"
scope_deferred: "brief, domain-spec shards (capabilities/risks/assumptions), ADR-002..011 bodies, VP bodies, module-criticality, architecture sections, holdout briefs"
findings_total: 14
findings_by_severity:
  critical: 2
  high: 5
  medium: 5
  low: 2
fix_burst: ADV-P1D-FIX-1
fix_status: applied
---

# Adversarial Review — Phase 1d Pass 1

**Project:** ferrochain  
**Verdict:** NOT CLEAN  
**Findings:** 14 (2 CRITICAL / 5 HIGH / 5 MEDIUM / 2 LOW)

---

## Scope

**Attacked:** BC-INDEX, PRD, error-taxonomy.md, invariants.md, edge-cases.md, VP-INDEX, interface-definitions.md, and BC bodies in subsystems SS-02/03/04/05/08/11/12.

**Deferred to Pass 2:** product-brief, domain-spec shards (capabilities, risks, assumptions, differentiators), ADR-002..011 bodies, VP bodies (VP-001..VP-005), module-criticality.md, architecture sections (ARCH-INDEX, system-overview, module-decomposition, etc.), holdout scenario briefs.

---

## Finding Summary

| ID | Sev | Status | One-Line Description |
|----|-----|--------|----------------------|
| F-01 | CRIT | FIXED | E-GRAPH-001..006 code collisions across BCs vs error-taxonomy |
| F-02 | CRIT | FIXED | DELETE /runs/{id} semantics: "Cancel in-progress" (interface-definitions) vs refuse-active-409 (BC-2.12.003) |
| F-03 | HIGH | FIXED | Run-status vocabulary contradictions across 4 docs; no cancelled/expired transitions; no cancel endpoint |
| F-04 | HIGH | FIXED | BC-2.04.005 control-signal set self-contradiction (ERROR_SOURCE_NODE vs SCHEDULED) |
| F-05 | HIGH | FIXED | BC-2.08.007 title Err(Timeout) vs PC2 Err(Transport) for TCP reset; DEC-013 wrong error category |
| F-06 | HIGH | FIXED | error-taxonomy GRAPH anchors wrong (E-GRAPH-003→BC-2.02.001, E-GRAPH-004→BC-2.02.003 unused) |
| F-07 | HIGH | FIXED | BC-2.05.006 SOC authz errors used E-GRAPH-005 (BudgetCeiling); security path must be wire-distinct |
| F-08 | MED | FIXED | BC-2.12.006 EC-002 unbounded in-flight deduplication block violates DI-009 intent |
| F-09 | MED | FIXED | BC-2.05.006 EC-005 4h approval timeout missing wall-clock UTC durable deadline spec |
| F-10 | MED | FIXED | BC-2.12.003 H1 title inconsistent with canonical F-03 state machine |
| F-11 | MED | FIXED | BC-INDEX DI Anchors column missing DI-002 (BC-2.04.001/002/005) and DI-004 (BC-2.04.003/004) |
| F-12 | MED | FIXED | interface-definitions.md:204 status enum misaligned with canonical state machine; multitask_strategy "enqueue" / queued state note missing |
| F-13 | LOW | FIXED | BC-2.11.006:111 stale embedded "at INFO level" quote (OQR-5 resolved log level to WARN) |
| F-14 | LOW | FIXED | 19 BC files (ss-04/ss-11/ss-13) missing bc_id frontmatter field; inconsistent field order |

---

## Canonical E-GRAPH Code Map (post F-01 renumber)

| Code | Name | Category | BC Anchor |
|------|------|----------|-----------|
| E-GRAPH-001 | InvalidUpdateError | CONCURRENCY | BC-2.03.002 |
| E-GRAPH-002 | NoActiveInterrupt | POLICY | BC-2.05.005 |
| E-GRAPH-003 | UnknownRoutingTarget | VAL | BC-2.02.005 |
| E-GRAPH-004 | DuplicateBarrierWrite | VAL | BC-2.02.003 |
| E-GRAPH-005 | BudgetCeiling | POLICY | BC-2.10.003 |
| E-GRAPH-006 | BspDeterminismViolation | INTERNAL | BC-2.03.001 |
| E-GRAPH-007 | UnknownChannelKey | VAL | BC-2.02.001 |
| E-GRAPH-008 | UnreachableGraph | VAL | BC-2.02.001 |
| E-GRAPH-009 | DuplicateNodeName | VAL | BC-2.02.001 |
| E-GRAPH-010 | UnknownBarrierWriter | VAL | BC-2.02.003 |
| E-GRAPH-011 | ConditionalEdgePanic | INTERNAL | BC-2.02.005 |
| E-GRAPH-012 | UnmappedRouteKey | VAL | BC-2.02.005 |
| E-GRAPH-013 | InsufficientApproverRole | SECURITY | BC-2.05.006 |
| E-GRAPH-014 | InterruptApprovalTimeout | POLICY | BC-2.05.006 |
| E-GRAPH-015 | NoParentGraph | VAL | BC-2.05.004 |

> **Note:** E-GRAPH-015 added during fix-burst verification — BC-2.02.002 used E-GRAPH-006 for InvalidUpdateError (should be E-GRAPH-001; fixed) and BC-2.05.004 used E-GRAPH-004 for NoParentGraph (required new code E-GRAPH-015; fixed). Both were pre-existing collisions within F-01 scope (adversary listed E-GRAPH-006 as having InvalidUpdateError among its multiple meanings).

---

## Canonical Run State Machine (post F-02/F-03)

`queued → in_progress → completed | failed | interrupted | cancelled`

- `queued`: created via POST /runs, not yet picked up by executor (default multitask_strategy="reject" rejects concurrent; "enqueue" queues here)
- `in_progress`: executor is actively running the graph
- `interrupted`: HITL interrupt raised; parked waiting for POST .../resume
- `completed`: graph reached END; `output` populated
- `failed`: unhandled FerrochainError; `error` populated
- `cancelled`: explicitly cancelled via POST /runs/{id}/cancel
- `expired`: future state (timeout on parked run); not required in v1.0.0 unless RiskGatePolicy timeout fires (F-09 aligns via E-GRAPH-014 InterruptApprovalTimeout → run transitions to `failed`, not `expired`, in v1)

DELETE /runs/{id}: deletes a TERMINAL state record only (completed/failed/cancelled/interrupted-then-resolved). Active runs require POST /runs/{id}/cancel first.

---

## Detailed Findings

### F-01 (CRITICAL): E-GRAPH Code Collisions

**Observed:** BC authors assigned error codes E-GRAPH-001..009 independently in BCs (ss-02/ss-05), without consulting error-taxonomy.md. This created 6+ code collisions where the same E-GRAPH-NNN code has different meanings in different BCs vs the taxonomy. E-GRAPH-005 in BC-2.05.006 means `InsufficientApproverRole`; in error-taxonomy it means `BudgetCeiling`. E-GRAPH-006 in BC-2.05.006 means `InterruptApprovalTimeout`; in error-taxonomy it means `BspDeterminismViolation`. E-GRAPH-001/002/004 also multi-meaning. E-GRAPH-007/008/009 used in BCs but undefined in taxonomy.

**Fix applied:** Taxonomy is source of truth. E-GRAPH-001..006 kept stable with their taxonomy meanings. All colliding BC usages renumbered to new codes E-GRAPH-007..014 (see canonical map above). Taxonomy updated with new entries. All BC bodies updated. F-06 anchor fixes included.

**Process gap note:** This collision class requires a global cross-component lint story in the Phase 2 backlog: "global cross-component collision lint" — a CI check that validates every error code used in any BC body appears in the taxonomy with the same name and category.

### F-02 (CRITICAL): DELETE /runs/{id} Semantic Contradiction

**Observed:** interface-definitions.md:164 describes `DELETE /threads/{thread_id}/runs/{run_id}` as "Cancel an in-progress run." BC-2.12.003 EC-005 specifies that DELETE on an active run returns HTTP 409 ("use cancel first"). LangGraph platform (`.factory/semport/platform/behavioral-intent.md`) has separate `cancel()` and `delete()` operations.

**Fix applied:** DELETE = delete a terminal run record (HTTP 409 if pending/in_progress). Added `POST /threads/{thread_id}/runs/{run_id}/cancel` endpoint for active run cancellation. Updated interface-definitions.md line 164. BC-2.12.003 body updated for consistency.

**Decision basis:** langgraph-sdk has `runs.cancel(wait, action)` distinct from deletion. D13 (no wire-compat) gives first-party freedom; the safer semantic (delete=terminal-only) prevents accidental data loss.

### F-03 (HIGH): Run Status Vocabulary Contradictions

**Observed:** Four documents use four vocabularies: BC-2.12.003 (pending/running/interrupted), BC-2.12.006 (queued/in_progress/requires_action/cancelled/expired), interface-definitions.md (queued/in_progress/interrupted/cancelled), entities-server.md (queued/in_progress/requires_action/completed/failed/cancelled/expired).

**Fix applied:** Canonical set: `queued, in_progress, interrupted, completed, failed, cancelled`. BC-2.12.003, BC-2.12.006, interface-definitions.md, entities-server.md all aligned. `requires_action` → `interrupted` (same concept). `expired` deferred to future (v1 uses `failed` for timeout-expired runs; entities-server.md notes this).

### F-04 (HIGH): BC-2.04.005 Control Signal Self-Contradiction

**Observed:** Description/PC4/EC-005 say skipped signals are `ERROR, ERROR_SOURCE_NODE, INTERRUPT, RESUME`. Invariants §3 says the four channel indices `ERROR=-1, SCHEDULED=-2, INTERRUPT=-3, RESUME=-4` are "NEVER re-applied" — mixing the channel-index map with the skip-on-reapply list.

**Verified via:** `.factory/semport/graph/behavioral-intent.md:176-181` which explicitly lists: write-routing indices `WRITES_IDX_MAP = {ERROR:-1, SCHEDULED:-2, INTERRUPT:-3, RESUME=-4}` AND skip-on-reapply set `ERROR, ERROR_SOURCE_NODE, INTERRUPT, RESUME`. Note: "SCHEDULED has -2 index but is NOT skipped on re-apply; ERROR_SOURCE_NODE has no dedicated negative index but IS skipped."

**Fix applied:** Invariants §3 rewritten to cleanly separate the two concepts. Description/PC4/EC-005 (which use ERROR_SOURCE_NODE) are correct per semport verification and unchanged.

### F-05 (HIGH): BC-2.08.007 Title / DEC-013 Mismatch

**Observed:** BC-2.08.007 H1 title "Err(Timeout)" implies only timeout errors. PC2 specifies TCP reset → `Err(Transport)`. DEC-013 in edge-cases.md says TCP reset surfaces as `Err(FerrochainError { category: Timeout })` — wrong category (should be Transport).

**Fix applied:** BC-2.08.007 H1 updated to "Err(Timeout) or Err(Transport)". DEC-013 fixed: TCP reset → `Err(FerrochainError { category: Transport })`; stall timeout → `Err(FerrochainError { category: Timeout })`.

### F-06 (HIGH): E-GRAPH-003/004 Anchor Wrong

**Observed:** E-GRAPH-003 anchor → BC-2.02.001 but BC-2.02.001 doesn't use E-GRAPH-003. E-GRAPH-004 anchor → BC-2.02.003 but BC-2.02.003 EC-003 used E-GRAPH-007 (not E-GRAPH-004).

**Fix applied:** E-GRAPH-003 renamed to UnknownRoutingTarget; anchor updated to BC-2.02.005. E-GRAPH-004 renamed to DuplicateBarrierWrite; anchor stays BC-2.02.003; BC-2.02.003 EC-003 updated to use E-GRAPH-004. Resolved as part of F-01 renumber.

### F-07 (HIGH): Security Auth Errors Not Wire-Distinguishable

**Observed:** BC-2.05.006 used E-GRAPH-005 (BudgetCeiling) for `InsufficientApproverRole`. Security authorization failures on the SOC HITL path shared a code with token budget enforcement — unacceptable for a security-critical path where wire observability of auth failures is required.

**Fix applied:** E-GRAPH-013 (SECURITY category) assigned to InsufficientApproverRole. All BC-2.05.006 references updated.

### F-08 (MEDIUM): BC-2.12.006 EC-002 Unbounded Block

**Observed:** EC-002 specifies that a concurrent duplicate request "blocks until the first completes" with no timeout. This violates DI-009 (no outbound connection may hang indefinitely) by analogy — the same no-hang principle should apply to in-flight deduplication waits.

**Fix applied:** EC-002 updated: the in-flight deduplication block has a maximum wait of 30 seconds (the DI-009/NFR-009 connection timeout value, configurable via `IdempotencyStore::lock_timeout`). On timeout expiry: HTTP 503 Service Unavailable with `E-SERVER-016 IdempotencyLockTimeout`. Added E-SERVER-016 to error-taxonomy.md.

### F-09 (MEDIUM): BC-2.05.006 EC-005 Approval Timeout Missing Durable Deadline

**Observed:** EC-005 specifies a 4h approval timeout but doesn't specify: (a) whether the deadline is wall-clock UTC or relative, (b) whether it survives process restart, (c) clock-skew posture.

**Fix applied:** EC-005 updated to specify: deadline is stored as an absolute wall-clock UTC timestamp in the parked interrupt record at interrupt() time (written to the checkpoint alongside the interrupt payload). Evaluated lazily on resume or poll (not a background timer). Clock-skew posture: deadline is set by the process that creates the interrupt using its local clock; ferrochain makes no NTP/cluster-clock guarantees. Operators requiring strict SLA enforcement should use a distributed coordinator.

### F-10 (MEDIUM): BC-2.12.003 H1 / PRD Table Inconsistency

**Observed:** BC-2.12.003 H1 "Run Creation and Execution Lifecycle (create → running → completed/failed)" uses "running" (old name) and omits interrupted/cancelled. BC-INDEX title row matches the stale H1.

**Fix applied:** H1 updated to "Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/interrupted/cancelled)". BC-INDEX title updated.

### F-11 (MEDIUM): BC-INDEX Missing DI Anchors

**Observed:** BC-INDEX DI Anchors column missing DI-002 for BC-2.04.001, BC-2.04.002, BC-2.04.005 and DI-004 for BC-2.04.003, BC-2.04.004.

**Fix applied:** BC-INDEX rows for BC-2.04.001, BC-2.04.002, BC-2.04.003, BC-2.04.004, BC-2.04.005 updated with correct DI anchors.

### F-12 (MEDIUM): interface-definitions.md Status Enum Misaligned

**Observed:** interface-definitions.md:204 enum had `"queued"` but BC-2.12.003 had `"pending"`; `"in_progress"` but BC-2.12.003 had `"running"`. No note linking `multitask_strategy: "enqueue"` to `queued` initial state.

**Fix applied:** Enum aligned to canonical set. Added note: multitask_strategy "enqueue" → new run created in `queued` state, transitions to `in_progress` after current run completes.

### F-13 (LOW): BC-2.11.006 Stale INFO Level Quote

**Observed:** BC-2.11.006 OQR Resolution row (Traceability section) contains stale embedded quote "WARNING LOG at INFO level" from before OQR-5's log-level correction.

**Fix applied:** Stale "at INFO level" quote cleaned to "WARNING LOG at WARN level" matching the adopted resolution.

### F-14 (LOW / Process Gap): BC Frontmatter Normalization

**Observed:** 19 BC files in ss-04, ss-11, ss-13 missing `bc_id:` frontmatter field. These use v1.1 template with different field order. The majority pattern (v1.0 BCs) includes `bc_id:` as the third field after `document_type` and `level`.

**Fix applied:** `bc_id:` field added to all 19 affected BCs, inserted after `level:` to match majority pattern.

**Process gap follow-up:** "global cross-component collision lint" candidate story for Phase 2 backlog — automated CI check validating (a) every error code referenced in a BC body exists in error-taxonomy.md with matching name+category, and (b) no two BCs use the same E-NNN code for different error names.

---

## Pass 2 Deferred Scope

The following were NOT attacked in this pass and remain queued for Pass 2:

- Product brief (`specs/product-brief.md`)
- Domain-spec shards: capabilities-p0.md, capabilities-p1-p2.md, risks.md, assumptions.md, differentiators.md, failure-modes.md, ubiquitous-language.md, bounded-contexts.md
- ADR-002..011 bodies
- VP-001..VP-005 bodies
- module-criticality.md, all architecture sections (ARCH-INDEX, system-overview, module-decomposition, dependency-graph, purity-boundary-map, verification-architecture, api-surface, tooling-selection)
- Holdout scenario briefs (`.factory/holdout-scenarios/`)
- ss-TBD BCs
