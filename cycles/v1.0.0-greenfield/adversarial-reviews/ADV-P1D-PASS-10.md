---
document_type: adversarial-review
pass: 10
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
open_findings: 4
timestamp: 2026-07-14T00:00:00Z
trajectory: "14→5→7→13→3→3→3→5→2→4"
counter_clean: 0
counter_clean_needed: 3
---

# ADV-P1D PASS-10: Adversarial Review — Phase 1d

**Verdict: NOT CLEAN — 4 findings (2 HIGH, 2 MED) — all fixed in this pass**

---

## Findings

### F-P10-01 (HIGH): BC-2.08.010 DI-008 description conflates DI-010 (Credential Opacity)

**File:** `.factory/specs/behavioral-contracts/ss-08/BC-2.08.010.md`

**Root cause — NEW FINDING CLASS: DI-description fidelity vs citation presence.**
The pass-9 census confirmed DI citation *presence* across all 86 BCs (3-way BC-body /
BC-INDEX / plan-RTM match). This pass rotated to a new axis: whether the *description
text* in each `L2 Domain Invariants` cell matches the canonical invariant title from
`invariants.md`. BC-2.08.010 line 143 cited `DI-008 (Type-Safe API Contract — generated
argument struct preserves structural type safety; no raw String for parameter passing)`.
The canonical name is **"Library Constructor Result Contract"** (see invariants.md §DI-008).
The description text described DI-010 ("Credential Opacity" — newtype structs, no Debug,
no Serialize) language that was incorrectly attributed to DI-008.

Additionally, postcondition 4 (`cargo expand shows no #[derive(Debug)] on API key types —
DI-008 structural type safety is preserved`) and the Invariants bullet referenced the same
DI-010 language under DI-008 attribution. The `#[tool]` macro does not enforce DI-010 —
that is BC-2.14.005's responsibility. What DI-008 actually requires of this BC is that
the macro enforces the `Result<T, FerrochainError>` return type at compile time (EC-003).

**Status: FIXED in this pass.**

Changes to `BC-2.08.010.md`:
1. Postcondition 4: replaced `#[derive(Debug)]` credential language with DI-008-correct
   language (Result return contract, no `.unwrap()`/`.expect()` in generated code, EC-003
   compile-time enforcement).
2. Invariants section DI-008 bullet: replaced with "Library Constructor Result Contract"
   description; added `Related invariant — DI-010 (Credential Opacity)` note citing
   BC-2.14.005 as the enforcer (cross-reference only — DI-010 is NOT added to this BC's
   enforcement claims).
3. Traceability row: `DI-008 (Type-Safe API Contract — ...)` → `DI-008 (Library Constructor
   Result Contract — macro-generated invoke wraps the annotated function, which must return
   Result<T, FerrochainError>; EC-003 enforces this at compile time)`.

---

### F-P10-02 (HIGH): ARCH-INDEX SS-08 BC range stale — `BC-2.08.001–008` vs actual `001–012`

**File:** `.factory/specs/architecture/ARCH-INDEX.md` line 67

**Root cause:** SS-08 subsystem row was written when only 8 BCs existed
(BC-2.08.001–008). Four additional BCs were created in batch 13 (BC-2.08.009–012:
schema snapshot, `#[tool]` macro, `#[entrypoint]` macro, `#[task]` macro). The
ARCH-INDEX range was never updated.

**Status: FIXED in this pass.** Line 67: `BC-2.08.001–008` → `BC-2.08.001–012`.

---

### F-P10-03 (MED): ARCH-INDEX Subsystem Registry note stale — "82 BC files" vs actual 86

**File:** `.factory/specs/architecture/ARCH-INDEX.md` line 56

**Root cause:** The subsystem registry preamble was written at 82 BCs. Four additional
BCs (batch 13: BC-2.08.009–012) brought the total to 86. The preamble was never updated.

**Status: FIXED in this pass.** Line 56: `all 82 BC files` → `all 86 BC files`.

---

### F-P10-04 (MED): PRD §5 component enumeration 8 vs taxonomy 12

**File:** `.factory/specs/prd.md` §5 (Error Taxonomy section)

**Root cause:** PRD §5 intro text listed only 8 crate abbreviations: CORE, GRAPH, CHKPT,
SERVER, PROV, MCP, SPLIT, SBXD. The error taxonomy (`prd-supplements/error-taxonomy.md`)
defines 12 components — the 4 missing were MEMORY (crate-level: ferrochain-memory),
RETRY (intra-crate: ferrochain-core retry combinator), CRON (intra-crate: ferrochain-server
scheduler), and BUDGET (intra-crate: ferrochain-graph budget subsystem). The 3 intra-crate
components follow the same pattern established for RETRY/CRON/BUDGET in the taxonomy's
component sections.

**Status: FIXED in this pass.** PRD §5 updated to:
- Enumerate all 12 components in the intro text with the crate-level vs intra-crate distinction
- Add MEMORY, RETRY, CRON, BUDGET rows to the summary table with Level column

---

## Cosmetic Fix (non-finding)

**BC-2.12.003 duplicate ordinals** — postconditions in "Read Run" sub-section reused
ordinals 10–13 (already used in "Cancel Run"). "List Runs" and "Delete Run" were then
correctly numbered 14–17, creating a gap in the sequential count. Renumbered:
- Read Run: `10–13` → `13–16`
- List Runs: `14–15` → `17–18`
- Delete Run: `16–17` → `19–20`
Total postconditions: 20 (continuous sequence 1–20).

---

## Sibling Checks (5/5 PASS)

| Check | Result |
|-------|--------|
| BC-INDEX total count == 86 | PASS |
| All BC files present in ss-NN dirs | PASS |
| VP-INDEX registration (VP-001–005) | PASS |
| Red Gate BCs (5) complete | PASS |
| 14-DI four-way census (body / BC-INDEX / plan / prd RTM) | PASS (carried from pass-9 exact match) |

---

## New Axis: DI-Description Fidelity Census

**Census method:** Extract `| L2 Domain Invariants |` row from every BC's Traceability
table; compare description text in parentheses against the canonical H2 title in
`invariants.md`. A citation is canonical if and only if its description text matches
the canonical title verbatim (extensions after " — " are permitted; the leading title
must be exact).

**Canonical titles (invariants.md):**

| DI | Canonical Title |
|----|----------------|
| DI-001 | BSP Reducer Determinism |
| DI-002 | Per-Task Durability (Sync Default) |
| DI-003 | HITL FIFO Resume-Value Delivery |
| DI-004 | Monotonic Checkpoint Clock |
| DI-005 | Session Triple-Address Uniqueness |
| DI-006 | Enforcing Sandbox Backend is Default |
| DI-007 | Workspace Path Confinement |
| DI-008 | Library Constructor Result Contract |
| DI-009 | Outbound Connection Timeout (Mandatory) |
| DI-010 | Credential Opacity |
| DI-011 | Streaming / Unary Run Equivalence |
| DI-012 | Guardrail Coverage at Ingress Boundaries |
| DI-013 | Secure Server Defaults |
| DI-014 | Error Propagation (No Silent Swallowing) |

**Census result — exceptions found and fixed:**

| BC | DI | Pre-fix description | Canonical | Status |
|----|----|--------------------|-----------|--------|
| BC-2.08.010 | DI-008 | "Type-Safe API Contract — generated argument struct preserves structural type safety; no raw String for parameter passing" | "Library Constructor Result Contract" | FIXED |
| BC-2.09.005 | DI-014 | "Error Propagation / No Silent Behavior — the struct's lifecycle must not have hidden network side effects" | "Error Propagation (No Silent Swallowing)" | FIXED |
| BC-2.12.007 | DI-011 | "Streaming/Unary Run Equivalence" | "Streaming / Unary Run Equivalence" | FIXED (missing spaces around /) |

**Note — style variant (not fixed):** BC-2.08.007 and BC-2.14.004 cite DI-009 as
"Outbound Connection Timeout — Mandatory" (em-dash replacing the inner parens of the
canonical name "Outbound Connection Timeout (Mandatory)"). This avoids nested-parentheses
awkwardness and contains the same semantic content. Flagged as a style variant; not
treated as a canonical mismatch. If a future pass elevates this, the fix is
`— Mandatory` → `(Mandatory)` in both BCs.

**Post-fix census: 83/86 had canonical descriptions before this pass; 86/86 canonical after fixes.**

(83 = 86 − 3 exceptions above; the DI-009 em-dash variant in 2 BCs is not counted as a mismatch.)

---

## F-P10-02/03 Complement Evidence: ARCH-INDEX Subsystem Registry vs Frontmatter Census

Census method: `grep -l "subsystem: SS-NN"` count per subsystem; compare against ARCH-INDEX
`BCs` range column (after fix). All 17 SS rows verified.

| SS ID | Name | ARCH-INDEX Range (post-fix) | Frontmatter Count | File Count | Match? |
|-------|------|-----------------------------|-------------------|------------|--------|
| SS-01 | Core Primitives | BC-2.01.001–004 | 4 | 4 | PASS |
| SS-02 | StateGraph Definition | BC-2.02.001–006 | 6 | 6 | PASS |
| SS-03 | BSP Execution Engine | BC-2.03.001–003 | 3 | 3 | PASS |
| SS-04 | Durable Checkpointing | BC-2.04.001–007 | 7 | 7 | PASS |
| SS-05 | HITL Interrupt / Resume | BC-2.05.001–006 | 6 | 6 | PASS |
| SS-06 | Streaming Event Taxonomy | BC-2.06.001–003 | 3 | 3 | PASS |
| SS-07 | Text Splitting | BC-2.07.001–003 | 3 | 3 | PASS |
| SS-08 | Provider Conformance + Standard Tests | BC-2.08.001–012 | 12 | 12 | PASS (fixed from 001–008) |
| SS-09 | MCP Tool Adapter | BC-2.09.001–005 | 5 | 5 | PASS |
| SS-10 | Budget Governance | BC-2.10.001–004 | 4 | 4 | PASS |
| SS-11 | Content Provenance / Guardrail | BC-2.11.001–006 | 6 | 6 | PASS |
| SS-12 | Durable-Run HTTP Server | BC-2.12.001–007 | 7 | 7 | PASS |
| SS-13 | Sandboxed Tool Execution | BC-2.13.001–006 | 6 | 6 | PASS |
| SS-14 | Typed Error Taxonomy | BC-2.14.001–006 | 6 | 6 | PASS |
| SS-15 | Long-Horizon Memory | BC-2.15.001–003 | 3 | 3 | PASS |
| SS-16 | Tool Retry + Circuit Breaker | BC-2.16.001–003 | 3 | 3 | PASS |
| SS-17 | Formal Verification Pipeline | BC-2.17.001–002 | 2 | 2 | PASS |
| **Total** | | | **86** | **86** | **ALL PASS** |

---

## F-P10-04 Assertion: PRD §5 Component Set == Error Taxonomy Component Set

**Error taxonomy components** (from `prd-supplements/error-taxonomy.md` `### Component:` headings):

CORE, GRAPH, CHKPT, SERVER, PROV, MCP, SPLIT, SBXD, RETRY, CRON, MEMORY, BUDGET

**PRD §5 components** (from `prd.md` §5 summary table rows, after fix):

CORE, GRAPH, CHKPT, SERVER, PROV, MCP, SPLIT, SBXD, MEMORY, RETRY, CRON, BUDGET

**Set equality:** PASS. 12 = 12. No component in taxonomy is absent from PRD §5; no
component in PRD §5 is absent from taxonomy.

---

## Re-Verified Axes

| Axis | Result |
|------|--------|
| E-code namespace (no collisions) | CLEAN (carried from pass-8 full reconciliation) |
| Subsystem coherence: ARCH-INDEX range == file census | F-P10-02 (FIXED — SS-08 range updated) |
| DI-description fidelity (new axis, pass-10) | 3 exceptions FIXED; 86/86 canonical post-fix |

---

## Trajectory and Process Notes

**Trajectory:** 14→5→7→13→3→3→3→5→2→4

**Counter clean:** 0/3 (reset: findings present this pass)

**Process-gap observation:** Two census gates are now established as permanent rotation
axes for future passes:
1. **ARCH-INDEX SS range gate:** After any BC batch addition, verify each affected SS-NN
   row's range and the preamble total count. Trigger: any new BC file created.
2. **PRD §5 component gate:** After any new component section added to error-taxonomy.md,
   verify PRD §5 enumerates it. Trigger: new `### Component:` heading in error-taxonomy.md.

**Cosmetic observation:** BC-2.12.003 duplicate ordinals — the Read Run sub-section had
ordinals 10–13 re-used after Cancel Run already used 10–12. Cosmetic only (no testability
impact) but fixed to maintain sequential integrity (1–20 continuous).
