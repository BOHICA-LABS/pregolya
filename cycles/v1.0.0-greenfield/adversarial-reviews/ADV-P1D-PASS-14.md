---
document_type: adversarial-review
phase: 1d
pass: 14
verdict: NOT CLEAN
timestamp: 2026-07-14T21:30:00Z
producer: business-analyst
scope: domain-spec/ (L2-INDEX.md Key Anchors + failure-modes.md) + BC-2.09.004 VP-ID
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/failure-modes.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.004.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.005.md
  - .factory/specs/architecture/verification-coverage-matrix.md
input-hash: "944a045"
findings:
  - id: F-P14-01
    severity: HIGH
    status: FIXED
  - id: F-P14-02
    severity: MED
    status: FIXED (pre-existing fix confirmed)
trajectory: "...→1→1→2"
clean_pass_counter: 0/3
---

# ADV-P1D-PASS-14: Adversarial Review

## Verdict: NOT CLEAN — 2 Findings

---

## F-P14-01 (HIGH) — L2-INDEX Key Anchors FM/DEC Mis-Anchors × 3

### Finding

Three rows of the Key Anchors table (L2-INDEX.md:117-130) pointed to wrong FM or DEC
targets, creating a double-use tell and a wrong edge-case cross-reference:

| Row | Source | Old (wrong) | Correct | Root cause |
|-----|--------|-------------|---------|------------|
| L2-INDEX:122 | NE-01 | FM-007 | FM-013 (new) | FM-007 is "Streaming Endpoint Does Not Invoke Engine" (NE-13); NE-01 is sandbox enforcement |
| L2-INDEX:123 | NE-02 | DEC-012 | DEC-011 | DEC-012 is "MCP Bare ToolException Re-Raise" (R11); DEC-011 is "Workspace Symlink Escape" (NE-02/DI-007) |
| L2-INDEX:126 | NE-07 | FM-010 | FM-014 (new) | FM-010 is "API Key Leaked via Debug or Serialize" (NE-10); NE-07 is constructor panic |

**Double-use tells (pre-fix):**
- FM-007 was cited for both NE-01 and NE-13 — NE-13 is the correct anchor; NE-01 had no FM
- FM-010 was cited for both NE-07 and NE-10 — NE-10 is the correct anchor; NE-07 had no FM

### Fix Applied

1. `L2-INDEX.md:122`: `FM-007` → `FM-013`
2. `L2-INDEX.md:123`: `DEC-012` → `DEC-011`
3. `L2-INDEX.md:126`: `FM-010` → `FM-014`
4. `failure-modes.md`: Authored FM-013 and FM-014 in new "Core / Sandbox Subsystem" section
5. `L2-INDEX.md:64`: FM count `12 modes` → `14 modes`
6. `L2-INDEX.md:91`: ID Registry FM count `12` → `14`
7. `failure-modes.md` Subsystem Summary: added `Core / Sandbox | FM-013, FM-014 | High` row

### FM-013: Sandbox Executes Without Enforcement
- **Anchor:** NE-01 / DI-006 / P-61
- **What:** Tool dispatched through strict policy against non-enforcing process backend;
  silently executes in host context without error instead of returning
  `Err(PolicyNotEnforceable)`.
- **Detection:** DI-006 enforcement contract test — strict-policy + process-backend must
  return `Err(PolicyNotEnforceable)`.

### FM-014: Library Constructor Panics Instead of Returning Result
- **Anchor:** NE-07 / DI-008 / P-66
- **What:** `.expect()` in public constructor body panics and terminates host process when
  initialization fails (e.g., WASM engine init). Caller has no structured error to handle.
- **Detection:** DI-008 CI lint gate; proptest boundary with adversarial constructor inputs.

---

## F-P14-02 (MED) — BC-2.09.004 Orphan "VP-MCP-04" vs Registered VP-004

### Finding

The Finding: BC-2.09.004's Verification Properties table and VP Anchors section used the
stale local working ID "VP-MCP-04" instead of the globally registered VP-INDEX ID "VP-004"
(title: "MCP ToolException Type-Identity Preservation"). VP-MCP-04 does not exist in
VP-INDEX.

### Status

**Pre-existing fix confirmed.** Reading BC-2.09.004.md shows VP-004 is already in place at
lines 131 and 149. This was resolved between pass 13 and pass 14 (the prior spec-gate audit
action item F-06's sister item for BC-2.09.004 was applied). No further action needed.

---

## Sibling Topology Checks (11/11 PASS)

| Check | Verdict |
|-------|---------|
| DEC-NNN count: L2-INDEX says 13; edge-cases.md has DEC-001..013 | PASS |
| FM-NNN count: L2-INDEX says 14 (after fix); failure-modes.md has FM-001..014 | PASS |
| All DEC Source fields cite canonical NE/DI/R IDs | PASS (R8/R10/R11 are documented state.md aliases with cross-walk in risks.md) |
| FM-007 no longer double-cited (NE-01 now → FM-013) | PASS |
| FM-010 no longer double-cited (NE-07 now → FM-014) | PASS |
| DEC-011 Source cites NE-02, DI-007 | PASS |
| DEC-012 Source cites R11 (not NE-02) — correct, separate concern | PASS |
| FM-013 Counter-example source cites NE-01/P-61 | PASS |
| FM-014 Counter-example source cites NE-07/P-66 | PASS |
| BC-2.09.004 VP-004 in Verification Properties table | PASS |
| BC-2.09.004 VP-004 in VP Anchors section | PASS |

---

## Rotated Censuses (3/3 PASS)

**Census A — Key Anchors bidirectional completeness:**
Every row in L2-INDEX Key Anchors table (14 rows) has a corresponding DI-NNN whose Source
field back-references the row's NE/CONFLICT. Every cited FM/DEC back-references its row's
source. No row lacks a destination artifact. PASS.

**Census B — FM subsystem coverage:**
All 14 FMs (FM-001..014) appear in the Subsystem Summary table. Five subsystems represented.
No FM is unclassified. PASS.

**Census C — DEC Source field consistency:**
All 13 DEC Source fields correctly identify their driving NE/DI/Risk or holdout domain.
R-alias citations (R8, R10, R11) are resolved by risks.md dual-ID reconciliation table —
no hanging references. PASS.

---

## Full Four-Column Bidirectional Audit (L2-INDEX:117-130)

For each Key Anchors row: Source → DI back-ref check + FM/DEC back-ref check.

| # | Source | Cited DI | DI Source field cites row source? | Cited FM/DEC | FM/DEC counter-example or source cites row source? | Verdict |
|---|--------|----------|-----------------------------------|--------------|------------------------------------------------------|---------|
| 1 | CONFLICT-1, NE-17 | DI-001 | DI-001: "CONFLICT-1, NE-17" ✓ | FM-001 | FM-001 Counter-example: "NE-17, CONFLICT-1" ✓ | PASS |
| 2 | CONFLICT-2, D11.3 | DI-002 | DI-002: "CONFLICT-2, D11.3, D17-Q3" ✓ | FM-002 | FM-002 Counter-example: "CONFLICT-2" ✓ | PASS |
| 3 | CONFLICT-3 | DI-003 | DI-003: "CONFLICT-3, D17-Q2" ✓ | FM-003 | FM-003 Counter-example: "CONFLICT-3" ✓ | PASS |
| 4 | CONFLICT-4 | DI-004 | DI-004: "CONFLICT-4" ✓ | (none) | N/A | PASS |
| 5 | CONFLICT-6 | (no DI) | entities-server.md FerrochainError entity Source: "CONFLICT-6" ✓; CAP-016 Grounding: "CONFLICT-6/D17" ✓ | (entities-server, CAP-016) | Semantic ✓ | PASS |
| 6 | NE-01 | DI-006 | DI-006: "NE-01" ✓ | FM-013 | FM-013 Counter-example: "NE-01 / P-61" ✓ | PASS (post-fix) |
| 7 | NE-02 | DI-007 | DI-007: "NE-02" ✓ | DEC-011 | DEC-011 Source: "NE-02, DI-007, Domain C" ✓ | PASS (post-fix) |
| 8 | NE-04 | DI-009 | DI-009: "NE-04" ✓ | FM-011 | FM-011 Counter-example: "NE-04 — adk-rust 8+ sites without timeout" ✓ | PASS |
| 9 | NE-06, HS-8 | DI-012 | DI-012: "NE-06, HS-8, D17-Q8" ✓ | CAP-013 | CAP-013 Grounding cites "D17-Q8" (which flows from NE-06/HS-8); semantically ✓ | PASS |
| 10 | NE-07 | DI-008 | DI-008: "NE-07" ✓ | FM-014 | FM-014 Counter-example: "NE-07 / P-66" ✓ | PASS (post-fix) |
| 11 | NE-10 | DI-010 | DI-010: "NE-10" ✓ | FM-010 | FM-010 Counter-example: "NE-10 — adk-rust workspace-wide bare-String API keys" ✓ | PASS |
| 12 | NE-12 | DI-005 | DI-005: "NE-12" ✓ | FM-005 | FM-005 Counter-example: "NE-12 — adk-rust triple collapse" ✓ | PASS |
| 13 | NE-13 | DI-011 | DI-011: "NE-13, CONFLICT-10" ✓ | FM-007 | FM-007 Counter-example: "NE-13 — adk-rust streaming sends stub events only" ✓ | PASS |
| 14 | NE-14 | DI-013 | DI-013: "NE-14" ✓ | FM-008, FM-009 | FM-008 Counter-example: "NE-14" ✓; FM-009 Counter-example: "NE-14" ✓ | PASS |

**All 14 rows: 14/14 PASS** (rows 6, 7, 10 required fixes above before passing).

---

## FM Detection Field Audit (14 FMs)

| FM | Detection cites | DI/NE reference | Verdict |
|----|----------------|-----------------|---------|
| FM-001 | DI-001 ✓ | DI-001 ✓ | PASS |
| FM-002 | Domain B holdout | DI-002 not cited explicitly | LOW OBS (semantic: Domain B = durability holdout = DI-002 domain) |
| FM-003 | DEC-007, Domain A/B holdout | DI-003 not cited explicitly | LOW OBS (DEC-007 maps to DI-003) |
| FM-004 | Concurrent-fork integration test; Kani VP candidate | DI-004 not cited explicitly | LOW OBS |
| FM-005 | DI-005 Kani VP ✓ | DI-005 ✓ | PASS |
| FM-006 | Integration test (no DI cite) | NE-11 in source but no DI (NE-11 has no DI-NNN) | LOW OBS (NE-11 is unclaimed by any DI; not a gap in this FM) |
| FM-007 | DI-011 ✓ | DI-011 ✓ | PASS |
| FM-008 | DI-013 ✓ | DI-013 ✓ | PASS |
| FM-009 | No DI cite | DI-013 is the governing invariant | LOW OBS (DI-013 cited in FM-008 sibling; omission benign) |
| FM-010 | DI-010 ✓ | DI-010 ✓ | PASS |
| FM-011 | DI-009 ✓ | DI-009 ✓ | PASS |
| FM-012 | DEC unit test (no DI/NE cite) | NE-09 is source | LOW OBS |
| FM-013 | DI-006 ✓ (authored this pass) | DI-006 ✓ | PASS |
| FM-014 | DI-008 ✓ (authored this pass) | DI-008 ✓ | PASS |

LOW observations only (5 FMs missing explicit DI cite in Detection field). No HIGH or MED gaps.

---

## DEC Source Field Audit (13 DECs)

| DEC | Source field | Verdict |
|-----|-------------|---------|
| DEC-001 | "R8" (state.md alias for R-004) | PASS (risks.md dual-ID table resolves) |
| DEC-002 | (none — scenario-only, no external source) | PASS (self-contained edge case) |
| DEC-003 | "R10" (alias for R-005) | PASS (risks.md dual-ID table resolves) |
| DEC-004 | (none — derived from EphemeralValue semantics) | PASS |
| DEC-005 | (none — derived from LastValue conflict rule) | PASS |
| DEC-006 | (none — derived from HITL contract) | PASS |
| DEC-007 | (none — derived from DI-003) | PASS |
| DEC-008 | (none — derived from DI-004 fork semantics) | PASS |
| DEC-009 | "Domain B dark-factory holdout" | PASS |
| DEC-010 | "Domain A SOC analyst holdout" | PASS |
| DEC-011 | "NE-02, DI-007, Domain C" ✓ | PASS |
| DEC-012 | "R11; upstream MCP test void" (alias for R-006) | PASS |
| DEC-013 | (none — F-05 alignment note in body) | PASS |

All 13 DEC Source fields: no incorrect NE/DI citations. R-alias citations are documented.

---

## LOW Observations

**OBS-P14-01 (LOW):** coverage-matrix.md VP title abbreviations. Informal VP names
("BSP-determinism-VP", "workspace-confinement-VP") used in module-criticality.md VP Count
column. Canonical IDs are VP-001/002/003. No traceability gap; cosmetic/maintenance concern.

**OBS-P14-02 (LOW):** bounded-contexts.md BC Phase-column ambiguity. VP-004/VP-005 are
Phase-3 integration VPs; their Phase column reads "3" which is consistent with VP-INDEX.
No contradiction, but the column header could clarify "Phase (implementation)" vs
"Phase (current spec)". Cosmetic.

---

## Trajectory and Counter

**Pass trajectory:** ...→1→1→2
- Pass 12: 1 finding
- Pass 13: 1 finding
- Pass 14: 2 findings (F-P14-01 HIGH + F-P14-02 MED, F-P14-02 was pre-existing fix)

**Clean pass counter:** 0/3

---

## Strongest Surviving Attack for Pass 15

Run the full four-column bidirectional audit of L2-INDEX:117-130 again with post-fix state
to confirm no residual double-use tells or orphan citations remain. Additionally: audit
CAP-013's anchor justification for explicit NE-06/HS-8 citation (currently only D17-Q8 is
cited — the semantic chain is correct but explicit NE attribution would be stronger). Verify
DEC-011 back-reference chain is complete in both edge-cases.md and L2-INDEX.
