---
document_type: adversarial-review
phase: 1d
pass: 15
verdict: NOT CLEAN
timestamp: 2026-07-14T22:00:00Z
producer: architect
scope: architecture/decisions/ (11 ADRs — ADR-anchor axis probe)
inputs:
  - .factory/specs/architecture/decisions/ADR-001-graph-execution-model.md
  - .factory/specs/architecture/decisions/ADR-002-checkpoint-format.md
  - .factory/specs/architecture/decisions/ADR-003-durability-tiers.md
  - .factory/specs/architecture/decisions/ADR-004-serde-schemars-schema-generation.md
  - .factory/specs/architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md
  - .factory/specs/architecture/decisions/ADR-006-streaming-event-taxonomy.md
  - .factory/specs/architecture/decisions/ADR-007-crate-topology-sdk-split.md
  - .factory/specs/architecture/decisions/ADR-008-proc-macro-attributes.md
  - .factory/specs/architecture/decisions/ADR-009-budget-governance-placement.md
  - .factory/specs/architecture/decisions/ADR-010-error-taxonomy-anyhow-confinement.md
  - .factory/specs/architecture/decisions/ADR-011-cache-key-content-hash.md
  - .factory/specs/prd.md §9 NE Disposition Table
  - .factory/specs/domain-spec/invariants.md
  - .factory/comparative/adk-rust/patterns-observed.md
input-hash: "pending"
findings:
  - id: F-P15-01
    severity: HIGH
    status: FIXED
trajectory: "...→1→1→2→1"
clean_pass_counter: 0/3
---

# ADV-P1D-PASS-15: Adversarial Review

## Verdict: NOT CLEAN — 1 HIGH Finding

Novel probe axis this pass: **ADR-anchor axis** — verify every NE-NN / DI-NNN / CONFLICT-N / P-NN
cite in all 11 ADR titles, Context, and Consequences prose against the authoritative index
(PRD §9 NE Disposition Table, invariants.md, patterns-observed.md). New probe class not
covered by any prior pass.

---

## F-P15-01 (HIGH) — ADR-010 Mis-Anchors NE-16 as anyhow Confinement

### Finding

ADR-010 frontmatter title and Context prose both cite NE-16 as the motivating
negative-evidence anchor for anyhow confinement:

- Frontmatter line 6: `title: "Error Taxonomy and anyhow Confinement (NE-16 / NE-03 / DI-014)"`
- Context line 22: `...losing structured error information for callers (NE-16 pattern to avoid).`

PRD §9 NE Disposition Table row:

```
| NE-16 | BC | BC-2.13.006 (macOS Seatbelt deny-by-default) |
```

NE-16 = macOS Seatbelt enforcement (BC-2.13.006, ferrochain-sandbox). It has nothing
to do with anyhow confinement.

The true anchor for the anyhow public-signature leak is **P-78** (`MistralRsError::Other(#[from]
anyhow::Error)` in `adk-mistralrs/src/error.rs:277`, certified as the sole genuine anyhow
public-signature leak in CERTIFICATION-REPORT W-04). ADR-010's own prose at line 60 already
correctly disclaims NE-16 as macOS Seatbelt — the title and Context contradict that disclaimer.

### Root Cause

Title/Context anchor (NE-16) and internal disclaimer (line 60) were authored in different
bursts without a cross-check, producing an internal contradiction.

### Fix Applied

1. ADR-010 frontmatter title: `(NE-16 / NE-03 / DI-014)` → `(P-78 / NE-03 / DI-014)`
2. ADR-010 Context line ~22: `(NE-16 pattern to avoid)` → `(P-78 pattern to avoid)`
3. ADR-010 lines 60-62: "NE-16 note" adjusted to "Scope note" — no NE-16 ownership
   claim remains; P-78 authority established; NE-16 = Seatbelt disambiguation retained.
4. ARCH-INDEX ADR registry row ADR-010 carries no parenthetical — no change required.

---

## Full 11-ADR Anchor Sweep (Pre-empt Pass 16)

Every NE-NN / DI-NNN / CONFLICT-N / P-NN cite in all 11 ADR titles + Context +
Consequences prose checked against PRD §9 NE Table, invariants.md, patterns-observed.md.

| ADR | Cites verified | Verdict |
|-----|----------------|---------|
| ADR-001 | DI-001 (BSP determinism) ✓; DI-002 (sync durability) ✓; DI-003 (HITL interrupt) ✓; VP-001 (Kani target, internal ref) ✓ | PASS |
| ADR-002 | No NE/DI/CONFLICT/P cites in scope | PASS |
| ADR-003 | NE-11 (Decision/Rationale line 38) cited as "step-boundary-only checkpoint" — **WRONG.** PRD §9: NE-11 = BC-2.04.007 (encryption at rest covers state AND event payloads). Step-boundary-only checkpoint = CONFLICT-2 (invariants.md DI-002 Source) / P-29 (patterns-observed.md). **SWEEP FIX APPLIED.** | FIXED |
| ADR-004 | No NE/DI/CONFLICT/P cites in scope | PASS |
| ADR-005 | CONFLICT-4 (title + Context): "adk-rust UUID v4 + wall-clock" — ✓ per invariants.md CONFLICT-4 source | PASS |
| ADR-006 | CONFLICT-5 (title + Context): "typed enum vs stringly-typed" — ✓ per BC-2.06.001/002/003; DI-011 (body): "streaming/unary equivalence" — ✓ per invariants.md DI-011 Source = NE-13/CONFLICT-10 | PASS |
| ADR-007 | No NE/DI/CONFLICT/P cites (D17-Q5 decision ref only) | PASS |
| ADR-008 | No NE/DI/CONFLICT/P cites (D17-Q6, D5 decision refs only) | PASS |
| ADR-009 | No NE/DI/CONFLICT/P cites; BC-2.10.004 internal ref ✓ | PASS |
| ADR-010 | NE-16 (title + Context) **WRONG** → P-78; NE-03 ✓ (BC-2.14.006); DI-014 ✓. **F-P15-01 FIXED.** | FIXED |
| ADR-011 | NE-05 (title + Context): "cache-key content hash" ✓ per PRD §9 NE-05 row; P-17 (body): "description proxy" ✓ per patterns-observed.md P-17 | PASS |

**Summary: 9 PASS / 2 FIXED (ADR-003 sweep fix + ADR-010 F-P15-01)**

---

## Sibling Checks (4/4 PASS)

| Check | Verdict |
|-------|---------|
| Post-fix: ADR-010 title contains no NE-16 cite | PASS |
| Post-fix: ADR-010 Context contains no NE-16 cite | PASS |
| Post-fix: ADR-003 Decision/Rationale cites CONFLICT-2 (P-29) not NE-11 | PASS |
| ARCH-INDEX ADR-010 row title carries no parenthetical — no NE-16 drift vector | PASS |

---

## FM-Detection Adjudication

**Result: ACCEPTABLE-CONVENTION**

Detection field = verification vehicle (the mechanism that catches the failure: Kani VP
harness, integration test, domain holdout, CI lint, DEC unit test, etc.). Explicit DI-NNN
citation in the Detection field is required only when the verification vehicle IS that
DI's VP proof harness. FMs whose detection vehicle is an integration test, holdout
scenario, or CI lint do not require a DI-NNN cite; this is correct by design.

FM-006 (source NE-11; no governing DI-NNN — NE-11 is an operational safety requirement
without a named domain invariant per BC-2.04.007 Traceability) and FM-012 (DEC unit test
vehicle; NE-09 source without a governing DI) are correct by design. No corrective action.

LOW observation OBS-P15-02 (below): this convention should be documented near the top
of failure-modes.md so future auditors do not re-flag as gaps.

---

## Rotated Censuses (3/3 PASS)

**Census A — NE-11 disambiguation post-fix:** After ADR-003 sweep fix, NE-11 appears
consistently as encryption at rest (BC-2.04.007; failure-modes.md FM-006 counter-example;
module-criticality.md NE-11 REJECT note). No step-boundary-only checkpoint usage of NE-11
remains anywhere in specs. PASS.

**Census B — ADR title parenthetical survey:** All ADR titles with NE/CONFLICT/P
parentheticals verified post-fix: ADR-005 (CONFLICT-4 ✓), ADR-006 (CONFLICT-5 ✓),
ADR-010 (P-78/NE-03/DI-014 ✓), ADR-011 (NE-05 ✓). No title carries a mis-anchor. PASS.

**Census C — PRD §9 NE double-claim check:** All 17 NEs anchored per PRD §9 footer.
Post-fix no NE is claimed by two different ADR titles. NE-16 now belongs exclusively to
BC-2.13.006 (Seatbelt); no ADR title claims NE-16. PASS.

---

## LOW Observations

**OBS-P15-01 (LOW):** nfr-catalog.md NFR-006 BC Trace listed `BC-2.08.001–BC-2.08.008`
but BC-2.08.006 (SDK crate split) and BC-2.08.007 (streaming transport error surfacing)
are not direct ferrochain-standard-tests conformance subjects. The five conformance
categories (streaming, tool-call, structured-output, error-fidelity, token-accounting)
map to BC-2.08.001–005 and BC-2.08.008 (eval score aggregation). **Fix applied:**
trace narrowed to `BC-2.08.001–005, BC-2.08.008`.

**OBS-P15-02 (LOW):** failure-modes.md Detection fields have no stated convention
for when DI-NNN citation is required. Future auditors may re-flag FM-002, FM-003,
FM-004, FM-006, FM-009, FM-012 as DI-cite gaps when they are correct by design.
**Fix applied:** convention note added near top of failure-modes.md.

---

## Trajectory and Counter

**Pass trajectory:** ...→1→1→2→1
- Pass 12: 1 finding
- Pass 13: 1 finding
- Pass 14: 2 findings
- Pass 15: 1 HIGH finding (F-P15-01) + 1 sweep fix (ADR-003 NE-11)

**Clean pass counter:** 0/3

---

## Strongest Surviving Attack for Pass 16

Full backward-traceability audit: for every BC cited in an ADR Consequences section
(e.g., BC-2.14.001, BC-2.04.001, BC-2.14.003, BC-2.08.006, etc.), verify the BC exists
in the PRD BC table with the correct PRD section / subsystem assignment. This closes the
loop from ADR anchor correctness (checked pass 15) to BC existence and placement
correctness (not yet checked as a pair).
