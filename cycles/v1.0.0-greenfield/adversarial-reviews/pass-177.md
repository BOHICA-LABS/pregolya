---
document_type: adversarial-review
level: ops
pass_id: P1D-177
pass_label: FULL-PERIMETER
frozen_head: cd6f79d
date: 2026-08-02
version: "1.0"
status: closed
producer: adversary (5 slices: A/B/C/D/E; first pass under POL-46 calibrated-instrument requirements; all slices disclosed POL-46 req-1 unsatisfiability — Bash denied in tool profile, verbatim file+line quotation substituted)
cycle: v1.0.0-greenfield
traces_to: STATE.md
---

# Adversarial Review — Pass P1D-177 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** All 5 slices complete: A (14) + B (7) + C (12) + D (9) + E (18) = 60 findings. **First pass in project history run under POL-46 calibrated-instrument requirements.** Frozen HEAD: post-burst-287 factory-artifacts HEAD `cd6f79d`. CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak: 0/3 unchanged. 54 documented refutations across all slices (A:10 / B:6 / C:6 discard+2 downgraded / D:22 / E:10).

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-177 FULL-PERIMETER |
| Frozen HEAD | `cd6f79d` |
| Date | 2026-08-02 |
| Method | 5-slice decomposition. All slices completed. 54 candidate findings discarded per POL-46 calibration discipline (10/6/6+2/22/10). 1 orchestrator adjudication recorded (A-vs-C on ADR-024 soundness). |
| Scope | A: ARCH-INDEX, ADRs, architecture sections, VPs. B: BCs SS-01..SS-12 + BC-INDEX. C: BCs SS-13..SS-23. D: PRD, prd-supplements, domain-spec shards, product-brief. E: policies.yaml, hooks, planning, comparative, semport, CI. |
| Policy rubric | POL-46 calibration requirements active. All 5 slices disclosed: POL-46 req-1 mandates inline executed-command output; adversary tool profile denies Bash; verbatim file+line quotation substituted throughout. This is an instrument limitation, not a compliance violation — see §Review-Instrument Defects. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — UNCHANGED, do NOT advance** |

## Slice Status

| Slice | Perimeter | Findings | CRIT | HIGH | MED | LOW/OBS |
|-------|-----------|----------|------|------|-----|---------|
| A | ARCH-INDEX, ADRs 001..025, 8 architecture sections, 13 VPs | 14 | 0 | 4 | 6 | 4 |
| B | BCs SS-01..SS-12 + BC-INDEX | 7 | 0 | 3 | 2 | 2 |
| C | BCs SS-13..SS-23 | 12 | 2 | 3 | 5 | 2 |
| D | PRD, prd-supplements, 15 domain-spec shards, product-brief | 9 | 0 | 3 | 3 | 3 |
| E | policies.yaml, hooks, planning, comparative, semport, CI | 18 | 1 | 7 | 3 | 7 |
| **Total** | | **60** | **3** | **20** | **19** | **18** |

---

## THE HEADLINE — First Pass Under POL-46; Instrument Improved Measurably

**P1D-176 → P1D-177: 160 → 60 findings with 54 documented refutations.** Per slice: A 40→14 (10 discards), B 31→7 (6 discards), C 35→12 (6 discards + 2 downgraded), D 26→9 (22 of 31 candidates, 71% discard rate), E 28→18 (10 discards).

**Do NOT record the drop as convergence evidence.** Part of it reflects a calibrated instrument (POL-46 filtering out note-closure class and phantom-coordinate findings that previously inflated counts), not solely an improved corpus. This distinction is load-bearing for the 3-CLEAN gate — a pass could otherwise be certified clean for the wrong reason. D-131 records the adjudication; L-170 codifies the lesson.

**All 3 CRITs are in artifacts that fix-burst 287 created or modified.** The defect-pump hypothesis from burst 287 is now measured: this pass caught new defects introduced by burst-287 within one cycle instead of four. This is the dominant mechanism of this pass — partial-fix propagation within a single burst.

---

## The 3 CRITs

### C-01 (Slice C) — BC-2.13.005 EC-003 vs ADR-024 Phase-2 Fallback: Direct Contradiction

> **Orchestrator-verified: contradiction confirmed verbatim at frozen HEAD cd6f79d.** Route: architect + product-owner.

**File:** `specs/behavioral-contracts/ss-13/BC-2.13.005.md` + `specs/architecture/decisions/ADR-024-writefile-create-path-confinement.md`
**Section:** BC-2.13.005 §EC-003 vs ADR-024 §Phase-2-Fallback
**Defect:** BC-2.13.005 §EC-003 states that a dangling symlink yields `Err(SandboxError::PathNotFound)`. ADR-024's Phase-2 fallback — the two-phase create-path protocol authored in burst-287 — returns `Ok` on `ErrorKind::NotFound` (i.e., treats it as the signal to proceed with parent-canonicalize protocol). These two behaviors are directly contradictory: the BC says the call returns an error while the ADR says it returns Ok and proceeds. At runtime, an implementer following ADR-024 will suppress the error condition that BC-2.13.005 EC-003 requires to surface. Orchestrator-verified verbatim: both documents were read at frozen HEAD; the contradiction is literal, not inferential.
**Why it matters:** BC-2.13.005 is the behavioral contract governing path confinement for a class of symlink inputs. If the implementation follows ADR-024's Phase-2 protocol, it will silently succeed where the BC requires an error. This makes the BC's test vectors unfulfillable.
**Route:** architect (ADR-024 §Phase-2-Fallback correction) + product-owner (BC-2.13.005 §EC-003 alignment).

---

### C-02 (Slice C) — ADR-024 Confinement Proof Unsound: Dangling Symlink Escape Path

> **Orchestrator-verified: "dangling" appears ZERO times in ADR-024; symlink analysis section covers only symlinked-parent, not dangling-target. Falsifies BC-2.13.004 PC-4 and VP-3 [P0].** Route: architect (security-critical; Kani P0 obligation blocked).

**File:** `specs/architecture/decisions/ADR-024-writefile-create-path-confinement.md`
**Section:** §Confinement-Proof / §Symlink-Analysis
**Defect:** ADR-024 line 72 claims "a bare filename component cannot escape a confirmed canonical parent." This is false when the final component is a symlink with an absent target — which is precisely what produces the `ErrorKind::NotFound` that Phase-2 triggers on. In that case, `canonical_parent.join(filename)` returns a **non-canonical** path that may resolve outside the root.

Orchestrator-verified enumeration: ADR-024 contains the word "dangling" **zero times**. Its only symlink analysis is "Symlinked parents" (covers the parent-directory-as-symlink case). The final-component-as-dangling-symlink case is entirely absent from ADR-024's analysis.

**Consequence:** This falsifies two properties:
1. `BC-2.13.004` PC-4: the precondition that guarantees confinement is incomplete — it does not account for the dangling-target case.
2. `BC-2.17.001` **VP-3 [P0]** ("no path escapes the sandbox root") — VP-3 is a P0 Kani obligation. A P0 failure is a Phase-7 convergence blocker. The Kani harness cannot be authored against an unsound confinement proof.

**Exploitability:** No *current* SS-23 tool demonstrably escapes in the burst-287 corpus (WriteFileTool's temp+rename replaces the symlink rather than following it for write purposes). However, any future writer using `OpenOptions::create` inherits the unsound proof and gains an escape path. The unsoundness must be closed before Phase-3 implementation begins.

**Why A-vs-C adjudication matters here:** Slice A declared the confinement argument clean after probing five shapes: traversal, absolute-path join, trailing `..`, symlinked parent, separator-in-filename — all correctly rejected by ADR-024. Slice C found a sixth shape (dangling-target symlink) absent from A's probe set. See §Orchestrator Adjudication.
**Route:** architect (ADR-024 §Confinement-Proof redesign — security-critical; P0 Kani obligation blocked until resolved).

---

### E01 (Slice E) — ADR-010 Class 1 Coverage Zero + verify-error-notation-canon Routing Inverts Canon

> **Orchestrator self-attributed contribution recorded.** Route: devops-engineer + architect.

**File:** `specs/architecture/decisions/ADR-010-error-type-design.md` §Class-1-Mandatory + `hooks/verify-error-notation-canon.sh` §CLASS1_VIOLATION routing
**Section:** §error-construction-notation + gate CLASS1_VIOLATION branch
**Defect:** ADR-010 §error-construction-notation §Class 1 states `::new()` is MANDATORY. The blocking gate `verify-error-notation-canon.sh` has zero coverage for Class 1 violations: the gate scans for Class 3 violations (`PregolyaError { .. }` struct-literal form) but has no scan for the affirmative obligation (files that MUST use `::new()` but do not). A corpus that replaced all `::new()` calls with bare struct literals would pass the gate.

More critically: the `CLASS1_VIOLATION` routing text inside the gate **prescribes `..` addition** as the remedy, which converts a Class 1 violation into a `CLASS2_VALID` pass (struct literal with `..` is Class 2, not Class 3) while leaving the ADR-010 Class 1 positive requirement unmet. Following the gate's own routing text actively violates the ADR.

This is Mechanism 5 rebuilt from burst-287 — the gate was rebuilt to eliminate Mechanism 5 but the rebuild introduced a routing-text inversion that creates a new mechanism of the same class.

**Orchestrator self-attributed contribution:** The orchestrator corrected devops from a blanket `::new()` prohibition to context-awareness in burst-287 but never specified the Class 1 *positive* requirement ("MUST use `::new()`") when describing the gate scope. The gate was rebuilt with accurate Class 3 detection but incomplete Class 1 detection because the positive obligation was not stated in the orchestrator's dispatch.

**Route:** devops-engineer (add Class 1 scanner: files that should use `::new()` but do not) + architect (verify ADR-010 §Class 1 positive requirement is unambiguous).

---

## Slice A — ARCH-INDEX, ADRs 001..025, Architecture Sections, VPs

**14 findings: 0 CRIT / 4 HIGH / 6 MED / 4 LOW/OBS. 10 candidates discarded per POL-46.**

### Slice A Verified-Clean Axes

- **ADR-024 symlinked-parent and 4 additional shapes**: traversal, absolute-path join, trailing `..`, separator-in-filename — all correctly rejected. (The dangling-target shape was NOT in this probe set — see C-02 and §Orchestrator Adjudication.)
- **ADR cascade integrity (001..025):** All 25 ADR `Supersedes:` / `Superseded-by:` bidirectional links verified consistent.
- **ADR-007 D23 crate count:** "Authoritative current count: 21" blockquote present and confirmed as the normative statement. (A010 from P1D-176 confirmed FALSE a third time — this is the canonical A010 refutation reference.)
- **Form-A changelog direction:** All ADRs pass verify-form-a-changelog-direction.sh.

### Slice A HIGH Findings (4)

#### F-P177-A01 — ADR-022 §Decision 3 vs §Decision 4: Ambiguous Prefix Rule Conflict (3 Live Instances)

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-022-section-anchor-citation-convention.md`
**Section:** §Decision 3 rule 5 vs §Decision 4 step 2
**Defect:** ADR-022 §Decision 3 rule 5 states that citations with ambiguous prefixes (where the prefix could match multiple heading slugs) MUST FAIL gate validation. ADR-022 §Decision 4 step 2 tells the migration sweep to treat ambiguous-prefix citations as "valid, no change required." The migration sweep following §Decision 4 will leave ambiguous-prefix citations in place while §Decision 3 rule 5 mandates they fail the gate. The gate and the migration sweep contradict each other. Three live instances of ambiguous-prefix citations exist in the corpus at frozen HEAD.
**Consequence:** The 3 live instances will not be fixed by the migration sweep (§Decision 4 clears them) and will not pass the gate (§Decision 3 fails them). The corpus cannot be promoted to gate-blocking status until one of these sections is corrected.
**Route:** architect (ADR-022 §Decision 3/4 reconciliation).

---

#### F-P177-A02 — ADR-023 §Decision 4 Heading + §Rationale Assert BC-2.22.001 IS Compile-Fail Gate While Body Denies It

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-023-non-exhaustive-governance.md`
**Section:** §Decision 4 heading (line 89) + §Rationale (line 151) vs §Decision 4 body
**Defect:** ADR-023's §Decision 4 **heading** (line 89) reads "BC-2.22.001 is the compile-fail gate" and §Rationale (line 151) repeats this assertion. The §Decision 4 **body** immediately below states that BC-2.22.001 is a behavioral specification, not itself the compile-fail test — the compile-fail test is a separate artifact. The heading and the body directly contradict each other on the same page.

**Orchestrator self-attributed:** The orchestrator enumerated three fix sites (127/134/167) from burst-287's finding report rather than grepping; there were five fix sites. Lines 89 and 151 are the two sites that remain.
**Route:** architect (lines 89 and 151 correction in ADR-023).

---

#### F-P177-A03 — purity-boundary-map Line 178: Async pre_tool_dispatch Named "Pure Part"

**Severity:** HIGH
**File:** `specs/prd-supplements/purity-boundary-map.md`
**Section:** §pre_tool_dispatch / line 178
**Defect:** purity-boundary-map line 178 designates the async `pre_tool_dispatch` function as the "Pure part" of its boundary, pointing a Kani harness annotation at an async fn. This contradicts Rule 3 in the same file (async functions cannot be pure in the Kani model without special handling) and contradicts both `verification-architecture.md` §Async-Purity and VP-011 §Async-Harness boundary constraints.
**Route:** architect (purity-boundary-map §pre_tool_dispatch correction + verification-architecture §Async-Purity cross-check).

---

#### F-P177-A04 — verification-coverage-matrix + tooling-selection: Stale "7 of 28 HIGH" After HIGH Went 28→29

**Severity:** HIGH
**File:** `specs/architecture/verification-coverage-matrix.md` + `specs/architecture/tooling-selection.md`
**Section:** §HIGH-finding-count
**Defect:** Both files carry the phrase "7 of 28 HIGH" in their coverage ratio text. P1D-176 finding progression updated HIGH from 28 to 29 (burst-287 opened one new HIGH finding). Neither document was updated. The same sentence in each file now carries both "28" (the stale denominator) and "29" (the updated count), making the ratio inconsistent within the sentence itself.
**Route:** architect (both files: update 28→29 in coverage ratio).

---

### Slice A MED Findings (6)

Slice A MED findings cover: VP frontmatter module-path pre-canonicalization residue (continuation of A013-A017 class from P1D-176 — any VPs not caught in burst-287 sweep); ADR §Phase-Gating claims contradicted by bc-authoring-plan §Phase-Progression; verification-coverage-matrix §proof_method mismatches; ARCH-INDEX §Key-ADR-Anchors named-section phantom anchors. All 6 instances are in the §-anchor or residual-propagation classes identified in P1D-176.

### Slice A LOW/OBS Findings (4)

Slice A LOW/OBS findings cover: ADR date boundary conditions; verification-architecture stale harness form references; cross-citation anchor spelling inconsistencies of the Mechanism 1 class; post-v1 marker omissions in verification-coverage-matrix §Phase-3-Column.

---

## Slice B — BCs SS-01..SS-12 + BC-INDEX

**7 findings: 0 CRIT / 3 HIGH / 2 MED / 2 LOW/OBS. 6 candidates discarded per POL-46.**

### Slice B Verified-Clean Axes

- **BC-2.01.001 through BC-2.11.003 rename completeness:** 0 `ferrochain` occurrences.
- **Error notation canon:** All BCs in SS-01..SS-12 pass `verify-error-notation-canon.sh` for Class 3 violations (note: Class 1 coverage is zero per E01; this clean claim covers Class 3 only).
- **Fence-exclusion rebuild cannot invert back to 26-false-positive state:** Confirmed via sub-probe B; the failure direction is over-exclusion only.
- **`Grep` with `glob:` + `path:` combined returns zero matches:** Slice B discovered this false-clean generator independently (see §Review-Instrument Defects). Slice B's initial scan of SS-01..SS-12 BC TV-row labels via this method was retracted; findings relying on it were discarded.

### Slice B HIGH Findings (3)

#### F-P177-B01 — StreamEvent Has No `error` Variant; EC-005 Mandates a 16th Wire Event

**Severity:** HIGH
**File:** BCs in SS-06 + `specs/architecture/decisions/ADR-023-non-exhaustive-governance.md`
**Section:** SS-06 §StreamEvent-Variants / ADR-023 §exhaustive-by-design
**Defect:** The `StreamEvent` enum has 15 enumerated variants. EC-005 mandates that a failed run emits a terminal `error` SSE event on the wire, which requires a 16th `StreamEvent::Error` variant. No such variant exists. ADR-023 ratified `StreamEvent` as exhaustively-matched by design, which means `StreamEvent::Error` cannot be added additively post-v1 without a breaking change to every exhaustively-matching consumer. A failed run therefore emits **zero** `StreamEvent`s (the `RunEnd` event is suppressed per EC-005's run-failure semantics) and an exhaustively-matching consumer cannot observe failure at all.
**Why it matters:** This is a silent-failure-at-spec-level defect for all error paths in streaming runs. Implementing from this spec produces a system that silently swallows run failures.
**Route:** architect (ADR-023 §StreamEvent variant inventory) + product-owner (SS-06 §StreamEvent-Variants).

---

#### F-P177-B02 — steps_remaining Underflows Given BC-2.03.001 recursion_limit + 1 Canon

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-XX/` (BC defining `steps_remaining` field) + `specs/behavioral-contracts/ss-03/BC-2.03.001.md`
**Section:** §steps_remaining formula vs BC-2.03.001 §recursion_limit_canon
**Defect:** `steps_remaining: Option<u32>` is defined as `recursion_limit − current_step`. BC-2.03.001 §recursion_limit_canon establishes that execution runs to `recursion_limit + 1` steps. At step `recursion_limit + 1` (the final step), `steps_remaining = recursion_limit − (recursion_limit + 1) = −1`. This underflows a `u32`. The sibling field `tokens_remaining` is typed `Option<i64>` precisely because it was designed to go negative; `steps_remaining` has the same semantic need but uses the wrong type. The asymmetry is a spec authoring defect.
**Route:** product-owner (change `steps_remaining` to `Option<i64>` or add guard; align with `tokens_remaining` design precedent).

---

#### F-P177-B03 — BC-2.12.003 PC19 directs interrupted→cancelled Arc Undefined in PC7 and Unauthorized by PC10

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-12/BC-2.12.003.md`
**Section:** §PC19 / §PC7 arc table / §PC10
**Defect:** BC-2.12.003 PC19 directs callers: "on `interrupted` status, transition to `cancelled` to enable deletion." The 8-arc transition table in PC7 does not include the `interrupted → cancelled` arc. PC10's authorization table does not authorize this transition for any caller role. A Run in `interrupted` state that follows PC19's instruction will have PC7 reject the transition as unauthorized. The result: `interrupted` Runs become permanently undeletable — they cannot transition to `cancelled` (blocked by PC7/PC10) and cannot be deleted directly (blocked by the deletion precondition that requires `cancelled`).
**Route:** product-owner (BC-2.12.003: either add the arc to PC7 + authorization in PC10, or correct PC19's recommendation).

---

### Slice B MED Findings (2)

Slice B MED findings cover continuation-class defects from P1D-176 that were not in burst-287 fix scope: a BC-INDEX §VP-Seed-Table header count vs body-row mismatch; an entity-type name mismatch between BC body and entities-server.

### Slice B LOW/OBS Findings (2)

Slice B LOW/OBS findings cover: a phantom §Named-Section anchor in a BC cross-reference; a stale version-vs-changelog discrepancy.

---

## Slice C — BCs SS-13..SS-23

**12 findings: 2 CRIT / 3 HIGH / 5 MED / 2 LOW/OBS. 6 candidates discarded + 2 downgraded per POL-46.**

### Slice C Verified-Clean Axes

- **C001 (PC-2 discrimination) CORRECT AND COMPLETE** across all 6 SS-23 BCs: every E-TOOLS-001/E-TOOLS-008 routing site checked; the burst-287 fix was complete.
- **All 15 BC frontmatter schemas in SS-13..SS-23 pass `verify-bc-frontmatter-schema.sh`.**

### Slice C CRITs

See §The 3 CRITs: C-01 (BC-2.13.005 EC-003 vs ADR-024) and C-02 (ADR-024 confinement proof unsound).

### Slice C HIGH Findings (3)

#### F-P177-C-H01 — ADR-024 §Phase-2 PC-1..PC-5 Mandated; Only PC-1/PC-2 Edited in Burst-287

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-024-writefile-create-path-confinement.md`
**Section:** §Phase-2 / §Postconditions PC-1..PC-5
**Defect:** ADR-024 §Phase-2 mandates five postcondition checks (PC-1 through PC-5) for the create-path fallback protocol. Burst-287 authored PC-1 and PC-2 but PC-3, PC-4, and PC-5 are absent from ADR-024's Phase-2 section at frozen HEAD. The spec is incomplete for the protocol it defines. This is the partial-fix propagation mechanism: within a single burst, the fix was applied to the immediately-visible targets (PC-1/PC-2) but the sibling postconditions were not enumerated and verified before declaring done.
**Route:** architect (ADR-024 §Phase-2 PC-3 through PC-5 authoring).

---

#### F-P177-C-H02 — Zero BC Propagation to Provider BC for ADR-024; Only 1 BC in Corpus References ADR-024

**Severity:** HIGH
**File:** corpus-wide — `specs/behavioral-contracts/ss-*/`
**Section:** ADR-024 citations
**Defect:** ADR-024 governs create-path confinement for WriteFileTool. A corpus-wide read confirms exactly **one** BC references ADR-024. The provider BCs (for pregolya-openai and pregolya-ollama WriteFileTool variants) do not reference ADR-024 at all, meaning the confinement requirement is untraced for provider implementations. Any Phase-3 story that implements WriteFileTool for a provider will not have the confinement requirement in scope. This is the same partial-fix propagation class: the ADR was authored but not propagated to sibling consumers.
**Route:** product-owner (sweep SS-23 provider BCs; add ADR-024 references where provider WriteFileTool BCs exist).

---

#### F-P177-C-H03 — BC-2.13.004 PC-4 Confinement Claim Incompletely Updated for ADR-024 Scope

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-13/BC-2.13.004.md`
**Section:** §PC-4
**Defect:** BC-2.13.004 §PC-4 carries the confinement claim that ADR-024 was authored to formalize. Burst-287 created ADR-024 but did not update BC-2.13.004 §PC-4 to trace to ADR-024. The BC's confinement claim and ADR-024's proof are thus independent — changes to ADR-024 (such as the C-02 redesign required) will not automatically invalidate the BC, creating a consistency gap. Also: C-02's finding that ADR-024's proof is unsound means BC-2.13.004 PC-4 currently asserts a property whose governing proof has a gap.
**Route:** product-owner (BC-2.13.004 §PC-4 traces_to ADR-024 + note pending redesign) + architect (coordinate with C-02 fix).

---

### Slice C MED/LOW Findings (7)

Slice C MED/LOW findings cover: SS-13..SS-22 residual note-closure candidates (all confirmed FALSE per POL-46 note-closure verification protocol; filed as discards, not findings — counted in the 6 discards); SS-17 TV count vs BC-INDEX registry mismatch (1 MED); SS-20 §Phase-Wave propagation residue from D23 (1 MED); SS-22 Embeddings BC crate citation requiring ADR-024 tracing (2 MED); 2 LOW instances of phantom §Named-Section anchors in SS-14/SS-16.

---

## Slice D — PRD, prd-supplements, Domain-Spec Shards, product-brief

**9 findings: 0 CRIT / 3 HIGH / 3 MED / 3 LOW/OBS. 22 of 31 candidates (71%) discarded per POL-46.**

### Slice D Verified-Clean Axes

- **D001 (TV registry) FIX CORRECT AND COMPLETE** — re-derived 687 by two disjoint independent methods: (1) 593 labeled + 29 ss-04 + 25 ss-11 + 29 ss-13 = 676 canonical, +11 GTV; (2) registry column sum = 676; all 129 rows match individually. Much stronger than the product-owner's initial `664 + 12` derivation. Registry count 687 is confirmed.
- **P1D-176 A010 confirmed FALSE a third time** — ADR-007 carries the authoritative 21-crate blockquote at its current normative location. This is the definitive refutation of the note-closure reading.
- **15 of 15 numeric census axes in Slice D's perimeter measured clean:** CAP 38, DI 15, FM 19, NE 17, observability 11+1, Red Gate 11, soak markers 4 — all match current corpus ground truth.
- **yaml-parse-error→FAIL promotion verified complete** across all 4 frontmatter validators (6 sites total verified by Slice D).

### Slice D HIGH Findings (3)

#### F-P177-D-01 — D002 Sibling Sweep Stopped One Row Short: SS.06/SS.13/SS.20 Still Diverge

**Severity:** HIGH
**File:** `specs/prd-supplements/bc-authoring-plan.md`
**Section:** §Subsystem → CAP Mapping rows for SS.06, SS.13, SS.20
**Defect:** Burst-287 fixed the SS.22 row in bc-authoring-plan §Subsystem → CAP Mapping. The sweep that corrected SS.22 stopped without checking sibling rows. At frozen HEAD, rows SS.06, SS.13, and SS.20 still diverge from the authoritative crate assignments in ARCH-INDEX §crate-table + dependency-graph §Edge-Table:
- **SS.13** assigns `pregolya-graph/sandbox` as the implementing crate. `pregolya-graph` owns **zero** SS-13 modules per module-decomposition §ss-13 — SS-13 is implemented in `pregolya-sandbox`.
This is the partial-fix propagation mechanism: burst-287 corrected one divergent row without enumerating and verifying all rows in the same table section.

**D002 framing correction (per D-135):** The burst-287 record framed D002 as a "nonexistent crate" error. This is incorrect: `pregolya-community` IS in the 21-crate roster (row 8, post-v1 lifecycle, Published = YES (post-v1)). The actual defect was wave/lifecycle routing — a v1 story was assigned to a post-v1 crate. The fix (pregolya-core + pregolya-openai + pregolya-ollama) was correct; the diagnosis was wrong.
**Route:** spec-steward (bc-authoring-plan §Subsystem → CAP Mapping SS.06/SS.13/SS.20 sweep).

---

#### F-P177-D-02 — ToolCallPreview Declared Without #[non_exhaustive] Though ADR-023 Lists It as Required

**Severity:** HIGH
**File:** type declaration for `ToolCallPreview` (in entities or interface definitions) + `specs/architecture/decisions/ADR-023-non-exhaustive-governance.md`
**Section:** ADR-023 §required-types inventory / `ToolCallPreview` declaration
**Defect:** ADR-023 §required-types lists `ToolCallPreview` among the 8 structs and enums that MUST carry `#[non_exhaustive]`. At frozen HEAD, `ToolCallPreview` is declared without `#[non_exhaustive]`. ADR-023 states there are no exempt structs for the required-types list. Burst-287 authored ADR-023 but did not sweep all 8 required types to verify the attribute was present; it only verified the types already known to have been discussed in the burst context.
**Route:** product-owner (add `#[non_exhaustive]` to `ToolCallPreview` declaration) + architect (verify remaining 7 required types in ADR-023 inventory have the attribute).

---

#### F-P177-D-03 — ADR-023 "20-Type Gate Scope" Undercounts by 22 Public Types

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-023-non-exhaustive-governance.md`
**Section:** §gate-scope / §type-inventory
**Defect:** ADR-023's stated gate scope is 20 public types. A corpus-wide survey of public type declarations finds 22 additional public types (9 enums + 13 structs) that appear in neither ADR-023's required-types inventory nor its exempt-types list. These 22 types are in a coverage gap: the gate does not apply to them (not in required list), but they have not been explicitly exempted either. The "20-type gate scope" is the total of the required+exempt lists; at 22 additional public types, the real perimeter is 42 public types of which the gate covers 20 (~48%).
**Route:** architect (ADR-023 §type-inventory: add 22 missing types to required or exempt list).

---

### Slice D MED/LOW Findings (6)

Slice D MED findings cover: 2 domain-spec shard CAP-wave propagation residues from D23; 1 prd-supplement input-hash mismatch (note: 631 advisories context, not a new class — tracked under Residual Items). Slice D LOW findings cover: 3 instances of minor cross-reference inconsistencies in domain shards.

---

## Slice E — policies.yaml, Hooks, Planning, Comparative, Semport, CI

**18 findings: 1 CRIT / 7 HIGH / 3 MED / 7 LOW/OBS. 10 candidates discarded per POL-46.**

### Slice E Ground-Truth Table — Blocking Validator Independence Audit (13 Validators)

This is the pass's most structurally valuable artifact. Of 13 blocking validators:

| Validator | Independence Class | Notes |
|-----------|-------------------|-------|
| #2 verify-adr-decision-refs | Genuinely independent: compares citations to document headings | Checks citation A → document B |
| #10 verify-arch-anchor-resolution | Genuinely independent: compares path citations to repository paths | Checks citation A → filesystem |
| #11 verify-module-canonicality | Genuinely independent: compares module names to authoritative registry | Checks value A → registry B |
| #13 verify-tv-registry-count | Genuinely independent: compares registry total to BC-body section rows | Checks sum A → independent count B |
| #5 Rule 4 | Genuinely independent: compares form to enumerated exception list | Checks value → external list |
| #3 records-lint L1/L7 | Self-referential: compares document to its own embedded rule | Document and rule in same file |
| #4 verify-changelog-date-monotonicity | Self-referential: compares entry N to entry N-1 in same document | No external ground truth |
| #5 Rule 5 | Self-referential: compares form to rule defined in same document | Document and rule in same file |
| #12 verify-bc-frontmatter-schema | Self-referential: compares frontmatter to schema embedded in tool | Schema is the tool's hardcoded expectation |
| #6 verify-enum-variant-casing | Hardcoded canon: checks casing against literal pattern; never reads ADR-010 | ADR-010 is the authority; validator hardcodes the rule |
| #7 verify-signature-canon | Hardcoded canon: checks signatures against allowlist file; never reads ADR-025 | ADR-025 is the authority; validator hardcodes the rule |
| #8 verify-error-notation-canon | Inverted: CLASS1_VIOLATION routing prescribes `..` addition — converts Class 1 violation to CLASS2_VALID, leaving ADR-010 §Class 1 violated | See E01 CRIT |
| Aggregator (pre-commit-validators.sh) | Certifies without counting: declares GATE: PASS without asserting PASS_COUNT against expected roster | See E04 HIGH |

**Summary:** 5 of 13 blocking validators compare genuinely independent sources. 4 compare a document to itself or a hardcoded copy of its own rule. 2 hardcode a canon whose document they never read. 1 inverts its ADR's rule. 1 aggregator certifies without counting.

### Slice E CRIT

See §The 3 CRITs: E01 (ADR-010 Class 1 zero blocking coverage + inverted routing text).

### Slice E HIGH Findings (7)

#### F-P177-E02 — policies.yaml CHANGELOG 1.2: 4 Line-Number Pins, All Wrong (POL-12-Forbidden)

**Severity:** HIGH
**File:** `.factory/policies.yaml`
**Section:** §CHANGELOG 1.2 (the entry minted for POL-47 in burst-287)
**Defect:** CHANGELOG entry 1.2 in policies.yaml carries 4 line-number pins: the entry cites line numbers 55, 95, 131, 172. The actual current line numbers are 58, 102, 142, 188. All 4 are wrong. This violates POL-12 (no line-number pins in records).

The entry itself claims "all four grep-verified." The section headings were grep-verified; the line numbers were apparently not independently measured and instead carried the wrong values.

**Why it matters invisible to gates:** `records-lint` diffs only `*.md` files; `verify-no-version-pins` globs `specs/**/*.md`. Neither gate covers `policies.yaml` CHANGELOG entries for line-number pins.
**Route:** spec-steward (CHANGELOG 1.2: remove all 4 line-number citations per POL-12; rephrase as section-heading references).

---

#### F-P177-E03 — Nonexistent-ADR Citations via False Delegation Claim

**Severity:** HIGH
**File:** multiple `policies.yaml` entries + `specs/architecture/ARCH-INDEX.md`
**Section:** `enforcement_anchor:` fields
**Defect:** Multiple policy entries carry `enforcement_anchor:` values citing ADRs that do not exist at frozen HEAD. The citations appear to have been generated by pattern-fill rather than by reading the target ADR. In at least two cases, the policy entry states "delegates to ADR-NNN §Section" where the ADR and section do not exist. This is the coordinate-fabrication class (L-162) applied to policy entries rather than adversary findings.
**Route:** spec-steward (all `enforcement_anchor:` fields: verify ADR exists and section heading is real before committing).

---

#### F-P177-E04 — pre-commit-validators.sh run_blocking: Missing Script Silently Skips, Gate Declares PASS

**Severity:** HIGH `[process-gap]`
**File:** `.factory/hooks/pre-commit-validators.sh`
**Section:** `run_blocking` function
**Defect:** In `run_blocking`, a script that does not exist at its expected path prints `[SKIP]` to stdout but does NOT append to `FAILED_VALIDATORS`. The gate then runs its final check: if `FAILED_VALIDATORS` is empty, it prints `GATE: PASS — all blocking validators passed`. With one or more scripts missing: `PASS_COUNT` accumulates only for scripts that ran; `FAILED_VALIDATORS` remains empty; the gate prints `PASS`. A roster of 13 validators where one is missing produces `GATE: PASS` from 12 validators.

**PASS_COUNT is never asserted against the expected roster of 13.** Two-line fix: (1) append the missing script name to `FAILED_VALIDATORS` in the `[SKIP]` branch; (2) add a final assertion `[ "$PASS_COUNT" -eq 13 ] || echo "GATE: FAIL — expected 13 validators, ran $PASS_COUNT"`.

**Current instance status:** ABSENT — the 13 listed validators all exist at frozen HEAD `cd6f79d`. This is a latent defect that activates on script deletion or path change.
**Route:** devops-engineer (two-line fix in run_blocking + roster assertion).

---

#### F-P177-E05 — Gate Keyed on `git branch --show-current`: Empty in Detached HEAD/Rebase/Bisect

**Severity:** HIGH `[process-gap]`
**File:** `.factory/hooks/pre-commit-validators.sh`
**Section:** branch-gating logic
**Defect:** `pre-commit-validators.sh` uses `git branch --show-current` to determine whether to run the blocking suite. In detached HEAD state, during rebase, bisect, or cherry-pick, `git branch --show-current` returns an empty string. The gate's conditional falls through to `exit 0` — zero validators run, gate silently passes.

**Current instance ABSENT:** the `.factory/` worktree is on `factory-artifacts` (not detached), so the burst-287 commit did run the suite. However:

**Compounding factors:**
1. The hook lives in untracked `.git/hooks/` and is `--no-verify`-bypassable.
2. `branches-ignore: factory-artifacts` in CI means no CI job ever runs the suite — the gate's "BLOCKING today" claim in `policies.yaml` rests entirely on an untracked per-clone file.
3. POL-26's verification step "confirm hook ran" is unexecutable — no artifact records that the hook ran for any specific commit.

**Route:** devops-engineer (replace `git branch --show-current` with a more robust branch-detection pattern; consider running suite unconditionally on `.factory/` commits).

---

#### F-P177-E06 — records-lint `-INDEX` Regex Extension Never Propagated; Newly-Authored Path Jointly Uncovered

**Severity:** HIGH `[process-gap]`
**File:** `.factory/hooks/records-lint.sh`
**Section:** `INDEX_PATTERN` regex
**Defect:** Burst-287 extended the records-lint `INDEX_PATTERN` to cover `-INDEX.md` file names in response to a prior finding. The extension was authored but not propagated to the companion check that validates newly-authored changelog frontmatter entries. The result: the `records-lint.sh` diff path that handles newly-created `-INDEX.md` files uses the old regex. Any newly-authored changelog entry in an INDEX file bypasses the lint check.

**Jointly-uncovered path:** The changelog/frontmatter path created during burst-287 authoring (the very burst that added the INDEX extension) is in this coverage gap. If burst-287's INDEX changes had been run through this path, the uncovered path would have caught the gap immediately.
**Route:** devops-engineer (propagate INDEX_PATTERN extension to companion check; add a test fixture for newly-authored INDEX changelog entries).

---

#### F-P177-E07 — Per-Validator CLEAN/FAILING Census is Authored, Not Measured; Contradicts Sibling Header

**Severity:** HIGH `[process-gap]`
**File:** `.factory/hooks/pre-commit-validators.sh`
**Section:** §per-validator census output
**Defect:** The per-validator CLEAN/FAILING count summary printed at gate completion is authored as a static string inside the script. It is not computed from the actual run results. The static census contradicts the sibling summary header produced by the same run (the header counts actual PASS/FAIL from accumulated arrays; the census repeats numbers from when the script was last edited). On a run where one validator produces a different result than the authored census, the printed summary will misrepresent the state.
**Route:** devops-engineer (replace authored census with computed census derived from the same arrays that drive PASS_COUNT/FAILED_VALIDATORS).

---

#### F-P177-E08 — verify-changelog-claim-applied Has 1 Decidable Heuristic, 3 Undecidable, + Structural Issues

**Severity:** HIGH `[process-gap]`
**File:** `.factory/hooks/verify-changelog-claim-applied.sh`
**Section:** heuristic logic
**Defect:** The validator's heuristic coverage:
1. **Decidable (1):** input-hash comparison — if the file's input-hash changed, a claim may have been applied. This is genuinely checkable.
2. **Redundant (1):** version comparison — a sibling blocking validator already enforces version monotonicity; this adds no coverage.
3. **Undecidable (3):** three heuristics attempt to verify that "the body reflects the claimed change" by grepping for phrases from the claim text. These are false-clean generators: a claim that says "section X updated" passes if the phrase "section X" appears anywhere in the body, regardless of whether the update occurred.

Additional structural issues:
- **Greedy body strip:** `## Changelog` → EOF is captured as the "body to check," stripping the entire post-Changelog document content including illustrative examples and fenced code blocks.
- **No illustration/fence exclusion:** matches inside fenced code blocks and illustration examples inflate WARN counts.

This is why WARN=662 is not actionable: 662 WARNs from a tool with 3 undecidable heuristics produces 662 false-positive WARNs, not 662 real coverage gaps.
**Route:** devops-engineer (narrow to input-hash heuristic only, or retire; remove 3 undecidable heuristics; fix body strip and fence exclusion; then re-evaluate WARN count).

---

### Slice E MED/LOW Findings (10)

Slice E MED/LOW findings cover: E09–E18 per Slice E's report. These include: policies.yaml entries with stale enforcement_anchor forms after ADR-022 restatement (3 entries, MED); verify-adr-anchor-citations advisory citing phantom anchors that were part of burst-287's fix scope but not swept in the advisory's result set (1 MED); 6 LOW/OBS instances of process-gap class: missing `--no-verify` guard in the hook's self-bypass documentation; CI branch-ignore scope not covering the factory hook test path; verify-changelog-date-monotonicity WARN categorization underdocumented; verify-module-canonicality output format inconsistency; advisory WARN count not included in SESSION-HANDOFF prose summary (N/A — no SESSION-HANDOFF in this project).

---

## Orchestrator Adjudication

### Slices A and C: ADR-024 Soundness

**Context:** Slice A declared ADR-024's confinement proof clean after probing five attack shapes:
1. Traversal (`../` in path components) — correctly rejected
2. Absolute-path join (`/etc/passwd` as filename) — correctly rejected
3. Trailing `..` (`filename/..`) — correctly rejected
4. Symlinked parent (parent directory is a symlink) — correctly rejected
5. Separator-in-filename (filename containing `/`) — correctly rejected

Slice C found a sixth shape: **final component as dangling symlink** (the filename itself is a symlink whose target is absent). This is precisely what triggers `ErrorKind::NotFound` in Phase-2, making the confinement claim `canonical_parent.join(filename)` return a non-canonical path.

**Adjudication: Slice C is correct; this is a coverage gap in A's probe, not a contradiction between slices.** Slice A's five probes are all accurately analyzed and correctly rejected. The probe set was enumerated-but-incomplete; the sixth shape was not in the enumerated list.

**Derived lesson (L-170):** A verified-clean claim backed by an enumerated-but-incomplete probe set is itself a false-clean generator — the same class as the tooling defect the pass found in E04. The issue is not that the individual probes were wrong; it is that the enumeration was closed before exhausting the attack surface. This is recorded in D-131.

---

## Review-Instrument Defects Found (Process Gaps)

### Instrument Defect 1 — POL-46 Requirement 1 Unsatisfiable with Current Adversary Tool Profile

**Category:** `[process-gap]` — orchestrator self-attributed
**Finding:** POL-46 requirement 1 mandates inline executed-command output as evidence in every finding. The adversary agent's tool profile is `Read`/`Grep`/`Glob` with **Bash denied**. All five slices disclosed this constraint and substituted verbatim file+line quotation as evidence. No adversary in this project can produce a POL-46-compliant finding as written.

**Orchestrator self-attributed:** POL-46 was minted in burst-287 without checking the adversary agent's tool profile against requirement 1's constraint. D-133 records this; L-171 codifies the lesson.

**Remedy options (one must be implemented before P1D-178):**
- (A) Grant the adversary agent Bash access (validators are read-only operations; execution risk is low).
- (B) Amend POL-46 requirement 1 to accept verbatim file+line quotation as equivalent evidence.

**Current mitigation:** All five slices substituted verbatim quotation; the quality of evidence is equivalent in context. No finding in this pass should be retracted on grounds of POL-46 non-compliance.

---

### Instrument Defect 2 — `Grep` with `glob:` + `path:` Combined Returns Zero Matches (False-Clean Generator)

**Category:** `[process-gap]`
**Finding:** Using `Grep` with both `glob:` and `path:` parameters simultaneously returns zero matches in this repository. This is a false-clean generator: an adversary that sweeps an axis using this pattern combination will report "no violations found" when violations may exist. Found independently by Slices B and C.

**Confirmed impact:** Slice B initially found zero TV-row labeling issues in SS-01..SS-12 using `glob: + path:` combination, nearly filing a fabricated finding that "all SS-01..12 BCs use unlabeled TV rows." The finding was retracted when Slice B discovered the tool limitation. Any prior pass that swept an axis using this combination may carry unfounded clean claims.
**Route:** instrument documentation — warn adversary dispatches that `Grep` requires exclusive use of either `glob:` or `path:`, not both simultaneously.

---

### Instrument Defect 3 — Three Orchestrator Dispatch Defects (Self-Attributed)

**Category:** `[process-gap]` — orchestrator self-attributed. Recorded in D-135.

1. **Bash-pin instruction:** Orchestrator told slices to pin evidence using `git show cd6f79d:<path>` when the adversary tool profile denies Bash. The instruction was unexecutable for every slice.

2. **Supplement count wrong:** Orchestrator specified "10 supplements in `prd-supplements/`" to slices. Actual count is **7** (`api-surface.md` and `module-decomposition.md` live in `architecture/`, not `prd-supplements/`). Any slice that used this count as a boundary condition for its coverage check may have declared the supplement perimeter exhausted after 7 files.

3. **D002 misframing propagated:** Orchestrator propagated "nonexistent crate" framing for D002 (pregolya-community) to slice dispatch prompts. `pregolya-community` IS in the 21-crate roster as row 8 (post-v1, Published = YES (post-v1)). D002 was a wave/lifecycle routing error, not a phantom-crate error. The misframing biases any slice auditing bc-authoring-plan toward looking for phantom crates rather than for lifecycle-routing errors. **Correct this framing** in STATE.md D-126 (which currently reads "corrected to pregolya-community + openai + ollama" — should read "corrected to pregolya-core + pregolya-openai + pregolya-ollama; community IS in roster as post-v1 wave/lifecycle error not phantom-crate").

---

## Dominant Mechanism — Partial-Fix Propagation Within a Single Burst

The dominant mechanism of this pass, succeeding P1D-176's five mechanisms, is: **partial-fix propagation within a single burst — approximately 10 instances traceable to fix-burst 287.**

Named instances:
- **A02:** ADR-023 §Decision 4 — orchestrator enumerated 3 fix sites from the report, missed 5; lines 89 and 151 remain.
- **A03:** purity-boundary-map line 178 async pre_tool_dispatch — burst-287 addressed adjacent lines but not this one.
- **A04:** verification-coverage-matrix and tooling-selection "28→29 HIGH" — one document updated, sibling not swept.
- **C-H01:** ADR-024 §Phase-2 — PC-1/PC-2 authored; PC-3/PC-4/PC-5 absent.
- **C-H02/C-H03:** ADR-024 not propagated to provider BCs (zero citations in corpus beyond one); BC-2.13.004 §PC-4 not updated.
- **D-01:** bc-authoring-plan SS.22 corrected, SS.06/SS.13/SS.20 not swept.
- **E06:** records-lint INDEX extension not propagated to companion check.
- **E07:** validator census authored once per edit, not recomputed on run.
- **Three orchestrator dispatch defects** (D-135): each reflects partial context from the instrument being dispatched without complete scope verification.

**POL-24 covers sibling sweeps and is demonstrably insufficient.** POL-24 requires a post-fix sibling sweep but does not require enumerating the complete target file set before the fix. The remedy is structural: a multi-file fix must (1) enumerate all affected files from the spec before applying any change, (2) diff the enumeration against the committed changes before declaring done. D-134 records the structural remedy requirement.

---

## Verified-Clean, Recorded to Prevent Re-Audit

- **D001 (TV registry) FIX CORRECT AND COMPLETE** — Slice D re-derived 687 by two disjoint independent methods. See §Slice D Verified-Clean Axes.
- **C001 (PC-2 discrimination) CORRECT AND COMPLETE** across all 6 SS-23 BCs. See §Slice C Verified-Clean Axes.
- **P1D-176 A010 confirmed FALSE a third time** — ADR-007 carries authoritative 21-crate blockquote.
- `yaml-parse-error`→FAIL promotion verified complete across all 4 frontmatter validators, 6 sites.
- The fence-exclusion rebuild **cannot invert** back to the 26-false-positive state.
- `branches-ignore: factory-artifacts` isolation holds — cannot wedge factory commits.
- All `§`citations in POL-16/17/18/19/46/47 resolve to real headings; ADR-025's four headings exist verbatim; no chained double-`§` in any POL entry.
- 15 of 15 numeric census axes in Slice D's perimeter measured clean.
- ADR-024 five-shape probe (traversal / absolute-path join / trailing `..` / symlinked parent / separator-in-filename) all correctly rejected — coverage gap is specifically the dangling-target shape (C-02), not these five.
