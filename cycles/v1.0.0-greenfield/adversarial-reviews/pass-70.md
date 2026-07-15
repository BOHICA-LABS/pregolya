---
document_type: adversarial-review
pass: 70
verdict: NOT CLEAN
finding_count: 2
finding_severity: [MED, MED]
novelty: MEDIUM
novelty_class: partial-fix-regression
novelty_notes: "Downstream residue of pass-60/61 budget refactor (ownership rule not updated when ADR-009 Option 3 was adjudicated) + pass-26 401 row rewrite (cross-doc note not updated when interface-definitions 401 row was populated with E-PROV-004 categorical fallback)"
sibling_checks: PASS
arithmetic_axes_converged: true
timestamp: 2026-07-15T00:00:00Z
phase: 1d
---

# Adversarial Review Pass 70

**Verdict:** NOT CLEAN — 2 findings (both MED)

**Novelty:** MEDIUM — arithmetic axes fully converged; residue is enforcement-tooling + cross-doc notes

---

## Findings

### F-P70-01 (MED) [process-gap]

**Location:** bc-authoring-plan.md gate #27, ownership rule line ~974 and quick-check pattern lines ~990–995

**Description:** Gate #27's ownership rule grouped "budget" with the ferrochain-graph–owned modules ("BSP engine, HITL, channels, scheduler, **budget**, provenance → ferrochain-graph"). The quick-check command also included `ferrochain-core/src/budget` in the forbidden grep set, with "Output must be EMPTY (zero hits)" assertion.

ADR-009 v1.2 Option 3 (the adjudicated canon, adopted pass-61) splits at the trait boundary: the budget ENGINE (`BudgetEngine`, `EvidenceJournal`) belongs in ferrochain-graph; the budget TRAIT/types (`BudgetPolicy`, `PolicyDecision`, `TokenUsage`, `RunContext`) belong in `ferrochain-core/src/budget.rs`. BC-2.10.001:141 and BC-2.10.003:139 correctly anchor to `ferrochain-core/src/budget.rs` per that split.

Running gate #27's quick-check verbatim would produce 2 false HIGH hits on those correct anchors, risking a backward "correction" that removes them.

Root cause: F-P61-01 updated BCs, ADR-009, and module-decomposition to reflect Option 3. The bc-authoring-plan enforcement command was not updated in the same burst.

**Fix:** Ownership rule split; `ferrochain-core/src/budget` removed from forbidden set; positive assertion added for BudgetEngine/EvidenceJournal.

---

### F-P70-02 (MED)

**Location:** error-taxonomy.md line ~152, inside the E-SERVER-004 category correction note

**Description:** The note ended: "The 401 row in interface-definitions.md §HTTP Status Codes is now marked reserved (no E-code maps there in v1)."

interface-definitions.md line 370 (the 401 row) was rewritten in pass-26 (F-P26-05) to carry:
> E-PROV-004 (ProviderAuthFailed, AUTH) — categorical fallback only; no v1 server endpoint emits 401 as a direct terminal HTTP status; surfaced embedded in Run.error.

The row is not "reserved" — it has an E-code mapping (E-PROV-004) and carries an explanation of why 401 is only a categorical fallback. The taxonomy note is stale relative to the current interface-definitions row.

**Fix:** Note updated to: "The 401 row … carries no directly-emitted E-code in v1 (E-PROV-004 AUTH→401 is a categorical fallback surfaced embedded in Run.error, never a direct terminal response — see interface-definitions §HTTP Status Codes)."

---

## Sibling Checks

| Check | Result |
|-------|--------|
| v2.19 400 row: explicit E-code enumeration (no ranges), E-CORE-004 note present | PASS |
| Disposition census: exact 78 = 43+12+23 (full per-namespace breakdown confirmed) | PASS |
| Gate #20 INTERNAL axis 11/11 | PASS |

---

## Censuses Run

| Gate | Command Class | Result |
|------|---------------|--------|
| Gate #12 | BC frontmatter completeness | PASS |
| Gate #18 | BC-INDEX row count | PASS |
| Gate #19 | Retired-identifier presence | PASS |
| Gate #20 | INTERNAL-axis ownership | PASS — 11/11 |
| Gate #28 | Version-changelog integrity (date sub-check) | PASS |
| Gate #27 | Architecture-anchor crate-resolution census | FAIL → F-P70-01 |

---

## Probes

| Probe | Class | Result |
|-------|-------|--------|
| Enforcement-command-vs-canon (NEW): gate #27 quick-check pattern vs ADR-009 Option 3 canon | New probe | FAIL → F-P70-01 |
| Stale cross-doc status-row refs (NEW): taxonomy notes referencing interface-definitions rows | New probe | FAIL → F-P70-02 |
| RunContext / SubAgentId resolution | Prior probe | PASS |

---

## Proposed Decisions Log Entries

**D18-P70-A:** Gate #27 enforcement command must be updated atomically with any ADR that changes the trait/engine split boundary. Specifically: when ADR-009 Option 3 was adjudicated (pass-61), the bc-authoring-plan enforcement command was a required co-update — this was missed. Going forward, ADR-propagation census (gate #32) must include bc-authoring-plan gate commands in its scope.

**D18-P70-B:** Any taxonomy note cross-referencing an interface-definitions row must cite the row's current content, not a prior state. The "reserved" description of the 401 row was accurate at pass-25 (before E-PROV-004 categorical fallback was added in pass-26). Pass-26 fix burst updated the interface-definitions row but did not update the taxonomy note. Going forward, supplement-vs-BC seam census (gate #29) scope must explicitly include taxonomy notes that reference interface-definitions row content.
