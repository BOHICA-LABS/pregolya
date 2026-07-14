---
document_type: adversarial-review
phase: 1d
pass: 2
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
finding_count: 5
critical_count: 1
high_count: 3
medium_count: 1
timestamp: 2026-07-14T00:00:00Z
---

# Adversarial Review — Phase 1d Pass 2

**Verdict: NOT CLEAN — 5 findings (1 CRITICAL, 3 HIGH, 1 MEDIUM)**

---

## Sibling Check: 6/7 landed (run-state partial)

Pass-2 arrived with Pass-1 fixes applied. Six of seven sibling-check items landed
cleanly. The run-state fix (F-P2-03) was partial: domain-spec, architecture, and
stories have the correct `interrupted` state naming, but BCs authored before the
canonical state machine was locked retained `requires_action`. Those are the remaining
mismatches addressed in this pass.

---

## F-P2-01 CRITICAL — Budget Namespace Incoherent

**File:** `prd-supplements/error-taxonomy.md`
**Scope:** product-owner

The budget error space is split across two namespaces with no authoritative home:
- `E-GRAPH-005 BudgetCeiling` exists in the GRAPH component table (anchored to BC-2.10.003)
- BCs BC-2.10.001 TV-005, BC-2.10.002 EC-001/TV-005, BC-2.10.003 postconditions 1/5
  all reference `E-BUDGET-001 BudgetCeilingReached` and `E-BUDGET-002 JournalWriteFailed`
  — but no `BUDGET` component section exists in the taxonomy

Additionally BC-2.10.003 postcondition 5 uses `category: BudgetExceeded`, a category
that does not appear in the canonical Category Codes table. This makes the error
taxonomy non-machine-parseable and breaks the VP-BC214001-01 collision-detection CI check.

**Required fix:** Add `Component: BUDGET` section with E-BUDGET-001 (POLICY) and
E-BUDGET-002 (DURABILITY). Retire E-GRAPH-005 with tombstone note. Fix
`category: BudgetExceeded` → `category: Policy` in BC-2.10.003. Add reconciliation note.

---

## F-P2-02 HIGH — RetryHint/Category Triple Vocabulary Inconsistency

**File:** `behavioral-contracts/ss-08/BC-2.08.004.md`
**Scope:** product-owner

BC-2.08.004 uses a three-value RetryHint vocabulary that differs from BC-2.14.001:
- BC-2.08.004 uses: `RetryAfter(Duration)`, `Retry`, `NoRetry`
- BC-2.14.001 canonical vocabulary: `Later(Duration)`, `Maybe`, `Never`

Occurrences: postcondition 3 (line 62), invariants (lines 79-80), EC-003 (line 99),
TV-003 (line 119). All must use the canonical three-value enum.

---

## F-P2-03 HIGH — run-state fix unpropagated in 6 files

**Files:** BC-2.12.007, BC-2.10.001, BC-2.10.004 (+ domain-spec, architecture,
stories already fixed by other agents)
**Scope:** product-owner (BC files only)

The canonical run state machine (introduced during Phase 1a spec crystallization)
names the interrupt-parked state `interrupted`, not `requires_action`. Seven BCs
and three architecture files used the pre-canonical `requires_action` label.
Pass-1 fixed architecture and domain-spec files. Remaining in product-owner scope:

- BC-2.10.001 line 61: postcondition 3 escalate bullet
- BC-2.10.004 lines 39, 60, 122, 133, 136: description, postcondition 4, EC-005, TV-001, TV-004
- BC-2.12.007 lines 104, 105, 129: EC-003 streaming/unary status, TV-005

---

## F-P2-04 MEDIUM — Component enum incomplete

**File:** `behavioral-contracts/ss-14/BC-2.14.001.md`
**Scope:** architect (deferred — architect scope)

BC-2.14.001 postcondition 2 lists the `component` field identifiers but the
enumerated set (CORE, GRAPH, CHKPT, SERVER, PROV, MCP, SPLIT, SBXD) is missing
RETRY, CRON, MEMORY, and (post-fix) BUDGET. The postcondition description is
out of sync with the taxonomy.

**Deferred to architect pass.** Product-owner scope is limited to taxonomy and BCs.

---

## F-P2-05 HIGH — Brief Omits ferrochain-sandbox and ferrochain-memory Crates

**File:** `specs/product-brief.md`
**Scope:** product-owner

The ARCH-INDEX Subsystem Registry defines:
- SS-13 Sandboxed Tool Execution → `ferrochain-sandbox` (Wave 1)
- SS-15 Long-Horizon Memory → `ferrochain-memory` (Wave 2)

Neither crate appears in:
1. The Wave 1 or Wave 2 In-Scope crate lists (§Scope)
2. The ferrochain brand namespace enumeration (§Workspace topology ~line 140)

The namespace reservation script (R6 — PENDING HUMAN ACTION) therefore omits two
crate registrations. R6's mitigation note must be updated to cover both crates.

---

## Coverage Note

**Attacked this pass:**
- error-taxonomy.md: full taxonomy table (GRAPH, CHKPT, SERVER, PROV, MCP, SPLIT,
  SBXD, RETRY, CRON, MEMORY component sections; Category Codes table; RetryHint table)
- Glossaries and entity definitions for run state terminology
- BC-2.10.001, BC-2.10.002, BC-2.10.003, BC-2.10.004 (budget governance cluster)
- BC-2.12.007, BC-2.14.001, BC-2.14.002 (server surface, error struct)
- BC-2.08.004 (provider error fidelity)
- product-brief.md §Scope Wave lists, §Constraints namespace enumeration
- ADR-009, ADR-010 (error taxonomy decisions)
- VP axis: all VP files in verification-properties/ — CLEAN
- BC-2.10.* and BC-2.12.* invariant/traceability sections

**Deferred (not attacked this pass):**
- ADR-002 through ADR-008, ADR-011 bodies
- VP bodies (VP-001 through VP-005)
- Remaining domain shards (events.md, event-flow.md, entities.md, edge-cases.md)
- module-criticality.md
- Remaining architecture sections (subsystem-decomposition.md bodies, data-flow.md)
- Holdout briefs (domain-a, domain-b, domain-c) for run-state terminology
- BC-2.14.001 Component enum completeness (F-P2-04 — architect scope)
