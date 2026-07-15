---
document_type: adversarial-review
pass: 61
verdict: NOT_CLEAN
novelty: HIGH
finding_count: 2
high_count: 1
medium_count: 1
low_count: 0
obs_count: 2
timestamp: 2026-07-15T00:00:00Z
scope: prd-supplements, behavioral-contracts, domain-spec
---

# Adversarial Review — Pass 61

**Verdict:** NOT CLEAN — 2 findings (1 HIGH, 1 MED). Novelty HIGH.
Two independent defect classes: F-P61-01 is the ADR-009 Option-3 split never propagated to
BC Architecture Anchors; F-P61-02 is a structural census blindspot (UNRESOLVED-vs-near-name-concept)
that misclassified `BudgetContext` when the corpus already named `RunContext` in BC-2.10.001 pre-3.

---

## Orchestrator Canon (verbatim — D18-P61-A)

ADR-009 Option-3 split fully propagated: `ferrochain-core/src/budget.rs` hosts the DEFINITIONS
(`BudgetPolicy` trait, `PolicyDecision`, `TokenUsage`, `RunContext`); `ferrochain-graph`
`graph::budget` hosts `BudgetEngine` + `EvidenceJournal` (dispatch). Context type canonical name
= `RunContext` (BC-2.10.001 precondition 3: thread_id, run_id, sub-agent identity);
`BudgetContext` RETIRED. Signature: `fn evaluate(&self, usage: TokenUsage, context: &RunContext) -> PolicyDecision`.
Context-contents citations = BC-2.10.001 precondition 3 (NOT PC3/INV).

---

## F-P61-01 (HIGH): ADR-009 Trait-in-Core Split Never Propagated to BCs

**Location:**
- `BC-2.10.001.md` Architecture Anchors (line 139): `ferrochain-graph/src/budget/policy.rs — BudgetPolicy trait, PolicyDecision enum, TokenUsage struct`
- `BC-2.10.001.md` Traceability Module field (line 163): `[architect to assign — ferrochain-graph]`
- `BC-2.10.003.md` Architecture Anchors (line 137): `ferrochain-graph/src/budget/policy.rs — BudgetPolicy::on_ceiling field: OnCeiling::Halt | OnCeiling::Escalate`

**Finding:** ADR-009 Option-3 places the `BudgetPolicy` trait definitions (trait itself,
`PolicyDecision`, `TokenUsage`, `RunContext`) in `ferrochain-core/src/budget.rs` and the
dispatch machinery (`BudgetEngine`, `EvidenceJournal`) in `ferrochain-graph`. The BC
Architecture Anchors for BC-2.10.001 and BC-2.10.003 still route the trait types to
`ferrochain-graph/src/budget/policy.rs`, which defeats the non-graph-dependency rationale of
Option 3. An implementer following the BC anchors would place the trait in the wrong crate.

The `[architect to assign — ferrochain-graph]` placeholder on BC-2.10.001 line 163
(Module field) similarly misdirects: the module is now fully determined by the ADR-009 split.

The Pass-60 S-7.01 partial propagation corrected the interface-definitions.md return type but
did not propagate the crate placement to the BC Architecture Anchors — the split exists in the
ADR but is invisible to the BC layer.

**Required fix:**
1. BC-2.10.001 Architecture Anchors: move trait/PolicyDecision/TokenUsage/RunContext anchor
   line to `ferrochain-core/src/budget.rs`; BudgetEngine/EvidenceJournal anchors stay in
   ferrochain-graph. Resolve Module field: `ferrochain-core (trait + types) / ferrochain-graph (engine)`.
2. BC-2.10.003 Architecture Anchors: move `BudgetPolicy::on_ceiling` anchor to
   `ferrochain-core/src/budget.rs`. Resolve Module field.
3. BC-2.10.002 and BC-2.10.004 Module fields: resolve stale `[architect to assign]` placeholders.

---

## F-P61-02 (MED): BudgetContext Cited to BC-2.10.001 PC3/INV — Wrong Section; RunContext Already in Corpus

**Location:**
- `interface-definitions.md` v2.15 line 257–260 (BudgetContext implementer-scope note)
- `bc-authoring-plan.md` v2.3 gate #31 census row `BudgetContext` (line 1253)

**Finding:** The pass-60 fix added this note:
```
> **`BudgetContext`** — implementer-scope struct (shape not enumerated in spec corpus; logically
> contains execution identity passed to the policy for contextual decisions: thread_id, run_id,
> sub-agent identity per BC-2.10.001 PC3/INV).
```
The citation "BC-2.10.001 PC3/INV" is structurally wrong on two axes:

1. **Wrong section:** BC-2.10.001 PC3 describes `PolicyDecision` variants (Allow/Escalate/Deny).
   BC-2.10.001 INV describes purity of `evaluate`. Neither section enumerates context contents.
   The actual source is **BC-2.10.001 precondition 3** (the third item under Preconditions):
   "The execution engine has access to the `RunContext` (thread_id, run_id, sub-agent identity
   if applicable) for policy evaluation calls."

2. **Wrong identifier:** Precondition 3 names the type `RunContext`, not `BudgetContext`.
   `BudgetContext` was minted by the pass-60 fix burst without checking whether the corpus
   already contained a near-name concept for the same role.

**Root cause (gate #31 blindspot):** Gate #31 step 3 checks whether an UNRESOLVED type has a
definition site anywhere in the corpus. It does not check whether the corpus contains a
near-name concept that IS the intended type under a different name. `BudgetContext` failed the
"NOT IN CORPUS" check (correctly, since that exact name doesn't appear), but the step did not
ask: "Is there a corpus type that plays this role?" Answering that question would have surfaced
`RunContext` in precondition 3 immediately.

**Required fix:**
1. `interface-definitions.md`: change parameter type `&BudgetContext` → `&RunContext`; replace
   the implementer-scope note with a RESOLVED note citing BC-2.10.001 precondition 3; since
   precondition 3 fully enumerates the fields (thread_id, run_id, sub-agent identity), RunContext
   is RESOLVED (not implementer-scope).
2. `bc-authoring-plan.md` gate #31 census: retire `BudgetContext` row, add `RunContext` row as
   RESOLVED per BC-2.10.001 precondition 3; update census verdict 18/21 → 19/21.
3. Add `BudgetContext` to gate #19 retired-identifier table.
4. Widen gate #31 step 4 to cover the UNRESOLVED-vs-near-name-concept blindspot: UNRESOLVED
   types must also be checked against near-name corpus concepts before classification.

---

## OBS-P61-1 [process-gap]: ADR-Propagation Census Gap — Gate #32 Minted This Burst

**Observation:** ADR-009 Option-3 crate-placement decision was accepted without a reconciliation
gate requiring propagation to BC Architecture Anchors, interface-definitions.md section headers,
and module-decomposition scope lines in the same burst as ADR acceptance. The BC anchor gap
(F-P61-01) survived at least one full pass because no census compared ADR placement statements
against those three carriers.

**Fix:** Mint gate #32 "ADR-propagation census": any accepted/amended ADR that makes a
crate-placement or type-home decision must reconcile, in the SAME burst: (1) module-decomposition
scope lines + module rows/notes, (2) every affected BC's Architecture Anchors, and (3) the
interface-definitions section headers. Census = diff ADR placement statements against those three
carriers. `total_standing_gates` 31→32.

---

## OBS-P61-2: Stale Placeholder Resolved (No Action Required)

**Observation:** The stale `[architect to assign — ferrochain-graph]` placeholder on BC-2.10.001
Module field (and siblings) was a visible signal that ADR-009 propagation had not occurred. This
finding is closed by the F-P61-01 fix.

---

## Sibling Checks

| Check | Result | Note |
|-------|--------|------|
| 1. ss-10 BCs uniform — all four use RunContext in body | PASS (with F-P61-02 caveat) | BC-2.10.001 pre-3 names RunContext; BCs 002/003/004 do not name the context param directly; BC-2.10.001 is the body authority |
| 2. PolicyDecision canonical name consistent across ss-10 BCs | PASS | All four BCs use PolicyDecision; zero BudgetDecision occurrences in ss-10/ |
| 3. evaluate purity invariant — no side effects in BC bodies | PASS | BC-2.10.001 INV: pure, stateless; journal writes are caller responsibility; all four BCs consistent |

---

## Census Results

| Census | Status | Note |
|--------|--------|------|
| #27 (architecture-anchor crate) | FAIL→fixed | F-P61-01: BC-2.10.001/003 used ferrochain-graph/src/budget/policy.rs for trait types → fixed to ferrochain-core/src/budget.rs |
| #13 (anchor-matrix 5-way) | PASS (sampled) | ss-10 batch-table rows unchanged by this burst; full 5-way check deferred pass 62 MANDATORY |
| #21 (URL-scheme) | PASS | No endpoint changes this burst |
| #26 (structurally-privileged-line) | PASS | No new structurally-privileged lines introduced |
| #29 (supplement-vs-BC seam) | PASS | BudgetPolicy block rewritten — BC-2.10.001 pre-3 is the seam authority; RunContext verified |
| #24, #25, #28 | NOT RUN | Pass 62 MANDATORY |

---

## Probes

| Probe | Result |
|-------|--------|
| Taxonomy anchor-column (§BudgetPolicy interface block, section header) | PASS (10/10) — §BudgetPolicy header not an architecture placement claim; F-P61-01 is the Architecture Anchors finding |
| Budget trait home resolution (F-P61-01 root probe) | FAIL → trigger fix burst |
| RunContext/BudgetContext identity in BC corpus | FAIL → F-P61-02 |

---

## Decisions Log

**D18-P61-A (canon — verbatim):** ADR-009 Option-3 split fully propagated.
`ferrochain-core/src/budget.rs` hosts definitions: `BudgetPolicy` trait, `PolicyDecision`,
`TokenUsage`, `RunContext`. `ferrochain-graph` `graph::budget` hosts `BudgetEngine` +
`EvidenceJournal` (dispatch). Context type canonical name = `RunContext`; `BudgetContext`
RETIRED. Signature: `fn evaluate(&self, usage: TokenUsage, context: &RunContext) -> PolicyDecision`.
Context-contents citations = BC-2.10.001 precondition 3 (NOT PC3/INV). Gate #32 (OBS-P61-1
ADR-propagation census) minted this burst; `total_standing_gates` 31→32.

**D18-P61-B (gate #31 widening):** Gate #31 step 4 extended: UNRESOLVED types must be checked
against near-name corpus concepts before final classification. An UNRESOLVED type that has a
near-name concept in the corpus playing the same role is a HIGH-severity name-drift finding.
Motivating instance: `BudgetContext` (interface-definitions.md) vs `RunContext` (BC-2.10.001
pre-3) — same contents, different identifier, same structural role, `BudgetContext` minted
without corpus search.
