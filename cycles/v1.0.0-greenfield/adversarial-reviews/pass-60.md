---
document_type: adversarial-review
pass: 60
verdict: NOT_CLEAN
novelty: HIGH
finding_count: 3
high_count: 2
medium_count: 1
low_count: 0
timestamp: 2026-07-15T00:00:00Z
scope: prd-supplements, behavioral-contracts, domain-spec
---

# Adversarial Review — Pass 60

**Verdict:** NOT CLEAN — 3 findings (2 HIGH, 1 MED). Novelty HIGH.
BudgetPolicy cluster: all three findings converge on the §BudgetPolicy block in
`interface-definitions.md` v2.14 contradicting the four ss-10 BCs (the behavioral authority).

---

## Orchestrator Adjudication (D18-P60-A — verbatim)

> The four ss-10 BCs are uniform and are the behavioral authority (D18-P47-A deference):
>
> - **Return type canonical name = PolicyDecision** (retire BudgetDecision everywhere outside
>   architecture/ — architect handles ADR-009).
> - **Variants = PolicyDecision::{Allow, Escalate { reason: String, current_usage: TokenUsage },
>   Deny { reason: String, current_usage: TokenUsage }}** (per BC-2.10.001 PC3 + TVs).
> - **Signature = SYNC and PURE:** `fn evaluate(&self, usage: TokenUsage, context: &BudgetContext) -> PolicyDecision`
>   (BC PC1/PC2 two params usage+context; ADR-009 agrees pure/no-async; NO journal parameter —
>   journal writes are performed by the CALLER/BudgetEngine per BC-2.10.001 INV + ADR-009).
> - **BudgetContext:** check whether the BCs define its shape; if loose, reference it as
>   implementer-scope like ChatConfig (documented note) or cite the BC fields if enumerated.

---

## F-P60-01 (HIGH): BudgetDecision vs PolicyDecision — 4-BC Split

**Location:** `interface-definitions.md` v2.14 §BudgetPolicy block (lines 239, 242);
`bc-authoring-plan.md` v2.2 gate #31 registry row 22 (line 1244); ADR-009 (architecture/,
architect scope); gate #31 census registry.

**Finding:** The §BudgetPolicy block names the return type `BudgetDecision` and defines it
inline. All four ss-10 BCs (BC-2.10.001, BC-2.10.002, BC-2.10.003, BC-2.10.004) use
`PolicyDecision` exclusively:
- BC-2.10.001 PC3: "Each returned `PolicyDecision` is one of the three variants: Allow / Escalate / Deny"
- BC-2.10.003: "A `BudgetPolicy::evaluate` call has returned `PolicyDecision::Deny`"
- BC-2.10.004: "A `BudgetPolicy::evaluate` call has returned `PolicyDecision::Escalate`"

The BC cluster is uniform and authoritative per D18-P47-A. The interface-definitions.md block is
the sole dissenter. ADR-009 pre-aligns with the BC canon (ADR-009 v1.1 records the rename decision).
The gate #31 registry row cites the *interface block* as the definition site under the name
`BudgetDecision` — but that name is wrong (the BC authority uses `PolicyDecision`).

**Required fix:** Rename `BudgetDecision` → `PolicyDecision` everywhere in product-owner domain
(interface-definitions.md §BudgetPolicy, gate #31 registry row). Add `BudgetDecision` to the
gate #19 retired-identifier table.

---

## F-P60-02 (MED): Escalate/Deny Missing current_usage: TokenUsage Payload

**Location:** `interface-definitions.md` v2.14 §BudgetPolicy enum definition (lines 244–245).

**Finding:** The current `BudgetDecision` (now `PolicyDecision`) enum defines:
```rust
Escalate { reason: String },
Deny { reason: String },
```
BC-2.10.001 PC3 states the canonical variants are:
```
PolicyDecision::Escalate { reason: String, current_usage: TokenUsage }
PolicyDecision::Deny { reason: String, current_usage: TokenUsage }
```
BC-2.10.001 TV-002 shows `Escalate { reason: "soft limit exceeded", current_usage: ... }`.
BC-2.10.001 TV-003 shows `Deny { reason: "hard limit exceeded", current_usage: ... }`.
The `current_usage: TokenUsage` payload field is missing from both variants. Implementers
following the interface definition would produce structurally incorrect results — callers
that inspect `current_usage` (e.g., the EvidenceJournal writer, BC-2.10.002) would fail
to compile.

**Required fix:** Add `current_usage: TokenUsage` to both `Escalate` and `Deny` variants in
the §BudgetPolicy enum definition.

---

## F-P60-03 (HIGH): Signature Three-Way Contradiction + Purity Violation

**Location:** `interface-definitions.md` v2.14 §BudgetPolicy trait block (lines 234–239).

**Finding:** The current signature:
```rust
async fn evaluate(
    &self,
    run_id: RunId,
    usage: TokenUsage,
    journal: &dyn EvidenceJournal,
) -> BudgetDecision;
```
contradicts the authoritative sources on three axes:

1. **async vs sync:** BC-2.10.001 INV: "BudgetPolicy::evaluate is a pure, stateless function
   (takes snapshot, returns decision)." ADR-009 records: "evaluate is sync, pure — no async, no
   I/O." The interface-definitions.md uses `async fn` — wrong.

2. **Parameter count (3-param vs 2-param):** BC-2.10.001 PC1/PC2 consistently call
   `policy.evaluate(usage, context)` — two parameters. The interface block has three:
   `run_id`, `usage`, `journal`.

3. **journal parameter (purity violation):** BC-2.10.001 INV: "Side effects (journal write,
   interrupt trigger) are performed by the **caller** (the execution engine) after receiving
   the decision." Passing `journal: &dyn EvidenceJournal` into `evaluate` is a direct purity
   violation — it exposes the journal to the policy implementation, enabling side effects inside
   evaluate, which the invariant explicitly forbids.

**Required fix:** Replace the signature with the pure sync 2-param canon:
`fn evaluate(&self, usage: TokenUsage, context: &BudgetContext) -> PolicyDecision;`
Add doc-comment: no side effects; journal writes performed by caller per BC-2.10.001 INV + ADR-009.

---

## OBS-P60-1 [process-gap]: Gate #31 Resolves Names Against Interface Block Rather Than Cited BC

**Location:** `bc-authoring-plan.md` v2.2 gate #31 census procedure.

**Observation:** Gate #31's census procedure (step 3) locates the definition site of each type
and verifies it exists. It does NOT assert that the type identifier name in the interface block
equals the identifier used in the cited authority BC. This gap allowed `BudgetDecision` (interface
name) to remain RESOLVED in the registry while all four authoritative BCs use `PolicyDecision` —
the drift persisted through pass-58 and pass-59 undetected.

**Fix:** Widen gate #31 to add step 4: "Assert that the type name used in the interface block
equals the identifier used in the cited authority BC (name-equality check, not just
definition-existence). A name mismatch where the interface uses a different identifier than the
BC is a HIGH-severity finding." This is a widening (not a new gate); `total_standing_gates` stays
at 31. Motivating instance: F-P60-01.

---

## Sibling Checks

| Check | Result | Note |
|-------|--------|------|
| Critical citations verified (ss-10 BCs uniform — all four use PolicyDecision) | PASS | BC-2.10.001/002/003/004: zero BudgetDecision occurrences; all use PolicyDecision |
| Transform vectors typecheck + same-boundary 3-doc | PASS | F-P59-02 fix confirmed; IngressContent same-variant rule holds across interface-def, BC-2.11.002 EC-003, BC-2.11.005 EC-002 |
| ss-10 BCs contain stray BudgetDecision text | PASS | grep -rn BudgetDecision ss-10/ → zero hits |

## Census Results

| Census | Status | Note |
|--------|--------|------|
| #23 (endpoint count) | PASS | 26 endpoints unchanged |
| #30 (codeless-error) | PARTIAL | No new errors introduced; ss-10 BCs use E-BUDGET-001/002 with variant names; verified |
| #31 (type-resolution) | FAIL→fixed | BudgetDecision → PolicyDecision; gate widened (OBS-P60-1); see gate #31 widening |
| #13 (anchor-matrix) | PARTIAL | ss-10 batch-table rows unchanged; full 5-way check deferred pass 61 |
| #21 (URL-scheme) | PARTIAL | No endpoint changes this burst; prior PASS holds; reconfirm pass 61 |
| #26 (structurally-privileged-line) | PARTIAL | No changes to structurally-privileged lines; reconfirm pass 61 |
| #27 (architecture-anchor crate) | PARTIAL | No new Architecture Anchor lines; reconfirm pass 61 |
| #29 (supplement-vs-BC seam) | PARTIAL | BudgetPolicy block rewritten — ss-10 BCs are the seam authority; verified match |

## Probes

| Probe | Result |
|-------|--------|
| BudgetPolicy cluster (F-P60-01/02/03 resolution) | FAIL → trigger fix burst |
| CheckpointSaver trait signature | PASS — no drift |
| Runnable/BaseChatModel signatures | PASS — no drift |
| evaluate purity lens (journal param) | FAIL → folded into F-P60-03 |

---

## Decisions Log

**D18-P60-A (adjudication):** PolicyDecision is the canonical return type for BudgetPolicy::evaluate.
The four ss-10 BCs are the behavioral authority. interface-definitions.md §BudgetPolicy block and
gate #31 registry are derived documents; they defer to the BC canon per D18-P47-A.

**D18-P60-B (gate #31 widening):** Gate #31 census procedure gains step 4 (name-equality check).
A type in the interface block resolves only if (a) its definition site exists in the corpus AND
(b) the interface block uses the same identifier name as the cited authority BC. Motivating
instance: BudgetDecision/PolicyDecision drift (F-P60-01) survived pass-58 and pass-59 because
only definition-existence was checked.
