---
document_type: adversarial-review
pass: 11
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
open_findings: 4
timestamp: 2026-07-14T00:00:00Z
trajectory: "14→5→7→13→3→3→3→5→2→4→4"
counter_clean: 0
counter_clean_needed: 3
---

# ADV-P1D PASS-11: Adversarial Review — Phase 1d

**Verdict: NOT CLEAN — 4 findings (1 HIGH, 3 MED) — all fixed in this pass**

---

## Sibling-Axis Checks (Pass-11 coverage complement)

| Axis | Status | Notes |
|------|--------|-------|
| DI-fidelity: verbatim title equivalence rule | FAIL (7 non-compliant sites → F-P11-02) | New-class finding; see census below |
| Cross-BC state-machine consistency (terminal-set coherence) | FAIL (F-P11-01) | New-class finding |
| RTM completeness (CAP coverage per BC) | FAIL (2 rows missing CAP-016 → F-P11-03) | |
| Error-taxonomy coverage for all BC error variants | FAIL (2 SandboxError variants unmapped → F-P11-04) | |

Rotated axes (PASS):
- BC-body/BC-INDEX/plan-RTM triple-citation consistency (pass-9 method): PASS
- DI citation presence (all 86 BCs cite ≥1 DI or explicit "—"): PASS

---

## Findings

### F-P11-01 (HIGH): BC-2.12.003 PC7/PC8/PC9 cross-BC state-machine inconsistency

**NEW FINDING CLASS: cross-BC state-machine consistency**

**File:** `.factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md`

**Root cause:** PC8 declared `completed`, `failed`, `interrupted`, and `cancelled` as
terminal states (no further transitions). PC9 then specified that `interrupted` can be
resumed. A "terminal state" cannot have a valid outbound transition — the two postconditions
directly contradict each other. Additionally, PC7 omitted the `interrupted → in_progress`
resume arc, making the state machine diagram incomplete. The `DELETE` postcondition (PC19)
also listed `interrupted` as a deletable terminal state, which further propagated the error.
The H1 title grouped `interrupted` with terminal states in the parenthetical.

**Affected evidence:**
- BC-2.12.003 PC8: `"completed", "failed", "interrupted", and "cancelled" are terminal states`
- BC-2.12.003 PC7: missing `interrupted → in_progress` arc
- BC-2.12.003 PC19: listed `interrupted` as deletable terminal state
- BC-2.12.003 Related BCs line: described "interrupted terminal state resume path"
- interface-definitions.md line 165: DELETE endpoint listed `interrupted` as deletable terminal

**Fix applied:**
- PC7: added `interrupted → in_progress (caller posts resume value via POST .../runs/{run_id}/resume)`
- PC8: rewritten to `Terminal states: completed, failed, and cancelled. interrupted is NOT terminal — it is a pausable/resumable state.`
- PC9: updated to clarify the `interrupted → in_progress` transition
- PC19: removed `interrupted` from deletable-terminal set; added guidance (resume or cancel first)
- Related BCs: "terminal" → "pausable"
- interface-definitions.md DELETE row: updated terminal set
- H1 title: updated to `...completed/failed/cancelled; interrupted is pausable/resumable`

**Coherence check post-fix:**
- PC9 and PC7 now agree: interrupted → in_progress is a valid transition
- BC-2.05.002 covers the HITL resume contract; PC9 cross-references it correctly
- DEC-006 (Resume Value Injection with Empty Interrupt Queue) still applies via the `interrupted` state resume path — coherent
- DEC-007 (multiple HITL interrupts): not affected by this fix (DEC-007 concerns FIFO queue behavior, which is upstream of this BC)

---

### F-P11-02 (MED): DI-014 and DI-009 verbatim title violations — pass-10 86/86 census was over-broad

**NEW FINDING CLASS: census method must define title equivalence**

**Root cause:** The pass-10 census claimed 86/86 for DI-description fidelity. That census
checked whether each `L2 Domain Invariants` cell contained the DI ID + some description,
but treated em-dash formatting as equivalent to canonical parenthetical formatting. The canonical
titles in `invariants.md` are:
- DI-014: `Error Propagation (No Silent Swallowing)` — parenthetical
- DI-009: `Outbound Connection Timeout (Mandatory)` — parenthetical

Multiple BCs cited these with em-dash substitution:
- `DI-014 (Error Propagation — No Silent Swallowing)` — em-dash replaces inner parenthetical
- `DI-009 (Outbound Connection Timeout — Mandatory)` — em-dash replaces inner parenthetical
- `DI-014 (Error Propagation — no silent swallowing; ...)` — lowercase + semicolon expansion

**Affected sites (Traceability table `L2 Domain Invariants` cells):**

| File | Line | Non-compliant form |
|------|------|--------------------|
| BC-2.08.004 | ~159 | `DI-014 (Error Propagation — No Silent Swallowing)` |
| BC-2.08.007 | ~159 | `DI-009 (Outbound Connection Timeout — Mandatory), DI-014 (Error Propagation — No Silent Swallowing)` |
| BC-2.14.001 | ~168 | `DI-014 (Error Propagation — No Silent Swallowing)` |
| BC-2.14.006 | ~125 | `DI-014 (Error Propagation — No Silent Swallowing)` |
| BC-2.09.004 | ~156 | `DI-014 (Error Propagation — no silent swallowing; ...)` |
| BC-2.14.004 | ~158 | `DI-009 (Outbound Connection Timeout — Mandatory)` |

Total: 5 DI-014 violations + 2 DI-009 violations = 7 non-compliant cells.

**Fix applied:** All 7 cells normalized to verbatim canonical form. Body invariant
mentions in the same files also normalized for consistency.

**Census method note (verbatim rule):** A DI citation in any `L2 Domain Invariants`
Traceability table cell PASSES the verbatim test only if the invariant title is reproduced
exactly as it appears in `invariants.md` — including inner parentheticals, capitalization,
and punctuation. Em-dash substitution for parenthetical text is NOT equivalent. Adding
extra context after the canonical title (separated by `—`) is ACCEPTABLE provided the
canonical title appears verbatim first.

**86-BC verbatim census re-run (post-fix):**
- BCs with DI citations in Traceability tables: 26 (all others show `—`)
- Non-compliant after fix: 0
- Result: **86/86 PASS** under verbatim equivalence rule

---

### F-P11-03 (MED): PRD RTM rows BC-2.14.004 and BC-2.14.005 missing CAP-016

**File:** `.factory/specs/prd.md` lines 545–546

**Root cause:** BC-2.14.004 and BC-2.14.005 frontmatter both declare `capability: CAP-016`
and both reference CAP-016 in their Traceability sections. The PRD RTM rows for these
two BCs listed only the DI references (`DI-009, NE-04` and `DI-010, NE-10`) without the
primary CAP column entry. All other SS-14 BCs (BC-2.14.001–003, BC-2.14.006) correctly
show `CAP-016` in their RTM rows. This is a systematic omission for the two CI-lint BCs.

**Fix applied:** BC-2.14.004 RTM row → `CAP-016, DI-009, NE-04`; BC-2.14.005 RTM row
→ `CAP-016, DI-010, NE-10`.

---

### F-P11-04 (MED): BC-2.13.006 SandboxError variants PlatformNoEnforcement and BackendUnavailable unmapped to E-SBXD codes

**File:** `.factory/specs/prd-supplements/error-taxonomy.md §SBXD` and
`.factory/specs/behavioral-contracts/ss-13/BC-2.13.006.md`

**Root cause:** BC-2.13.006 postcondition PC6 specifies
`Err(SandboxError::PlatformNoEnforcement { reason: ... })` and edge-case EC-002
specifies `Err(SandboxError::BackendUnavailable { reason: ... })`. The SBXD error
catalog contained only E-SBXD-001 (WorkspaceEscape), E-SBXD-002 (PolicyNotEnforceable),
and E-SBXD-003 (SandboxInitFailed). Neither PlatformNoEnforcement nor BackendUnavailable
had a taxonomy entry, leaving two named error variants without codes — a direct violation
of the requirement that every BC error variant maps to an E-xxx-NNN code.

**Category judgment:**
- E-SBXD-004 PlatformNoEnforcement: POLICY — the enforcement policy requires deny-by-default
  Seatbelt; the macOS allow-list is too broad to enumerate that policy, so the policy
  constraint rejects the operation. Analogous to E-SBXD-002 PolicyNotEnforceable but
  specific to the macOS Seatbelt allow-list feasibility failure.
- E-SBXD-005 BackendUnavailable: INTERNAL — the macOS Seatbelt API is unavailable at the
  kernel level; this is a runtime environment capability failure, not a user-policy error.
  Analogous to E-SBXD-003 SandboxInitFailed (INTERNAL) but for platform-level API absence
  rather than initialization failure.

**Fix applied:** Added E-SBXD-004 and E-SBXD-005 to error-taxonomy.md §SBXD.
Updated BC-2.13.006: PC6 now cites `(E-SBXD-004)`; EC-002 now cites `(E-SBXD-005)`;
EC-005 now cites `E-SBXD-004 PlatformNoEnforcement`.

---

## Observation: Wave 0 label

**Status:** Wave 0 was NOT a sanctioned label in the wave vocabulary at pass-11 entry.
The system-overview.md Wave Alignment table contained only Wave 1, Wave 2, and Post-v1.
ARCH-INDEX SS-14 listed ferrochain-core subsystems as Wave 1. However, 13 BCs across
ss-01, ss-07, and ss-14 used `wave: 0` in their frontmatter and Traceability tables.

**Disposition:** Wave 0 REGISTERED (not realigned). The Wave 0 BCs are:
- BC-2.01.001–004 (Core Primitives / message type shapes)
- BC-2.07.001–003 (Text Splitting API shape)
- BC-2.14.001–006 (Typed Error Taxonomy — foundational types + CI-lint gates)

These BCs specify cross-cutting foundational types and CI-lint gates in ferrochain-core
that all Wave 1 crates depend on. They are authored before Wave 1 compilation begins
(Phase 2 spec/CI setup). Realigning all 13 BCs to Wave 1 would lose the semantic
distinction between "foundational types exist before compilation" and "feature
implementation begins in CI". Wave 0 is registered with one row in system-overview.md
Wave Alignment table. ARCH-INDEX SS-14 Wave column remains "1" — ARCH-INDEX tracks
subsystem wave (which is correct: SS-14 ships as part of the ferrochain-core Wave 1
crate). The `wave: 0` frontmatter in individual BCs tracks the *story scheduling wave*
within Phase 2/3, which is a finer-grained concept than the crate-level wave.

---

## Counter-Clean Status

- Required for CLEAN: 3 consecutive passes with 0 open findings
- Counter at this pass: 0 (NOT CLEAN — 4 findings)
- Trajectory: ...→5→2→4→4

---

## Next-pass rotation axes (suggestions for pass-12)

1. BC-2.05.002 (HITL resume contract) full postcondition audit — verify coherence with
   updated BC-2.12.003 state machine (DEC-006/007 edge cases, resume-value FIFO)
2. All 86 BCs: EC-NNN count completeness — every BC must have ≥1 edge case; scan for
   missing EC sections
3. Cross-component error code collision scan: verify no two components share the same NNN
   for semantically different errors (post-GRAPH-reconciliation hygiene check)
4. BC-INDEX title column audit: verify all 86 BC-INDEX title entries match their respective
   H1 headings verbatim (BC H1 authority rule)
