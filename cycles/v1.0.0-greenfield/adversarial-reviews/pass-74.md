---
document_type: adversarial-review
pass: 74
verdict: NOT CLEAN
finding_count: 1
finding_severity: [HIGH]
novelty: MEDIUM-HIGH
novelty_class: d20-integration-retired-spelling-residue
novelty_notes: "D20 sub-burst BC body never re-swept by gate #15 post-integration — retired type name CheckpointStore survived in two live artifacts (BC-2.04.008 Description + interface-definitions.md E-CHKPT-008 omission note). Structural census blind spot: gate #15 excludes interface-definitions.md (architect scope); gate #19 grep pattern omitted the retired shared-type names its own table lists — retired shared-type names in interface-definitions.md were covered by NO census."
sibling_checks: "6/6 PASS"
timestamp: 2026-07-15T00:00:00Z
phase: 1d
---

# Adversarial Review Pass 74

**Verdict:** NOT CLEAN — 1 HIGH + 2 OBS (1 process-gap).

**Novelty:** MEDIUM-HIGH — D20-integration retired-spelling residue + structural census blind spot.

---

## Findings

### F-P74-01 (HIGH)

**Location:** specs/behavioral-contracts/ss-04/BC-2.04.008.md line 32 (Description field) + specs/prd-supplements/interface-definitions.md line 542 (E-CHKPT-008 omission note)

**Description:** Retired type name `CheckpointStore` appears in two live artifacts — a two-file blast radius:

1. **BC-2.04.008 Description (line 32):** `CheckpointStore::fts_search` — while PC5, EC-005, and EC-006 of the same BC correctly spell `CheckpointSaver`. Inconsistency within a single BC body: description references the retired name, postconditions and error cases reference the current name.
2. **interface-definitions.md line 542, E-CHKPT-008 omission note:** same retired spelling `CheckpointStore`; the adjacent line 544 correctly reads `CheckpointSaver`. Same pattern: one line stale, adjacent sibling correct.

Both violations directly violate:
- **Gate #15** zero-occurrence assertion for retired identifiers in live BC bodies
- **Gate #19** retired-identifier table entry (CheckpointStore → CheckpointSaver)

Root cause: D20 sub-burst authored BC-2.04.008 and interface-definitions entries but did not run a post-integration full-file retired-spelling sweep. Gate #15 excludes interface-definitions.md (it is architect-scoped, not PO-scoped), and gate #19's census grep pattern omitted the retired shared-type names listed in its own table — so the interface-definitions residue was covered by NO census.

**Severity:** HIGH — retired spelling in a BC description creates a direct contract ambiguity: test-writer and implementer reading the Description line see `CheckpointStore::fts_search`, while the postconditions and error taxonomy say `CheckpointSaver`. Two-file blast radius confirms a structural census gap, not an isolated typo.

**Fix (PO):** BC-2.04.008 — replace `CheckpointStore::fts_search` → `CheckpointSaver::fts_search` in Description; run full-file retired-spelling scan (CheckpointStore, RunConfig, BaseCheckpointSaver, AIMessage [Rust contexts], Checkpointer) to confirm clean; reorder changelog newest-at-top; bump → v1.2.

**Fix (architect):** interface-definitions.md — correct line 542 E-CHKPT-008 omission note (`CheckpointStore` → `CheckpointSaver`); run full-file residue scan (no RunConfig, BaseCheckpointSaver, AIMessage-Rust contexts, Checkpointer-type references); bump → v2.23.

**FIXED:** Both fixes completed in same burst. BC-2.04.008 → v1.2 (CheckpointSaver::fts_search; full-file retired-spelling scan clean; changelog reordered newest-at-top). interface-definitions → v2.23 (line 542 corrected; full-file residue scan clean: no RunConfig/BaseCheckpointSaver/AIMessage-Rust/Checkpointer-type).

---

## Observations (Non-Defects — All Fixed Same Burst)

### OBS-P74-A [process-gap], FIXED

**Location:** bc-authoring-plan gate #19 census command + gate #15 scope boundary

**Description:** Structural census coverage blind spot — two-layered:

1. Gate #15 explicitly excludes interface-definitions.md (architect scope). This means a retired shared-type name in interface-definitions.md passes gate #15 with no flag.
2. Gate #19's census grep pattern listed `CheckpointStore` → `CheckpointSaver` in the table but the grep command issued in the plan omitted `CheckpointStore\b`, `RunConfig\b`, `BaseCheckpointSaver\b`, `AIMessage\b`, `\bCheckpointer\b` from its pattern — so the census command never matched the names it claimed to enforce.

Net result: retired shared-type names in interface-definitions.md were covered by NO standing census. Gate #15 excluded it; gate #19 didn't match it. F-P74-01 exploited exactly this gap.

**Adjudication:** D18-P74-A (below).

**Disposition:** OBS [process-gap] — fixed same burst. bc-authoring-plan → v2.15: gate #19 grep pattern extended with `CheckpointStore\b`, `RunConfig\b`, `BaseCheckpointSaver\b`, `AIMessage\b`, `\bCheckpointer\b`; domain-spec/ added to exclusion list (Python→Rust mapping tables); AIMessage Python-context operator note added; coverage-closure note documenting that gate #19 now covers interface-definitions.md on the retired-spelling axis (closing the gate #15 exclusion blind spot).

---

### OBS-P74-B (LOW), FIXED

**Location:** specs/behavioral-contracts/BC-INDEX.md — Carry-Forward Note #5

**Description:** Note #5 historical annotation "83 → 86" (Batch 13 authoring record) had no forward pointer. OQR-4 in prd.md gained the "(later grown to 95 via D20)" forward pointer in the F-P73-02 fix, but the parallel carry-forward note in BC-INDEX did not receive the equivalent pointer — leaving an asymmetry in the cross-document OQR-4 narrative.

**Disposition:** OBS — fixed same burst. BC-INDEX → v1.4: Note #5 "(83 → 86)" → "(83 → 86; later grown to 95 via D20)" for OQR-4 parallelism.

---

## Clean Verifications

### Sibling Checks (6/6 PASS)

| # | Check | Result |
|---|-------|--------|
| 1 | test-vectors v1.4: 9 D20 rows at correct SS positions; independent recount BC-2.04.008=6, BC-2.10.003=7, BC-2.15.004=7, BC-2.09.006=6 TVs matches; total ~534 approximate-ok | PASS |
| 2 | prd v1.1: §5b 95, OQR-4 Batch-13 framing, §2.10 3-way sync (halt\|summarize + BudgetInfo), §3 +4 D20 traits | PASS |
| 3 | BC-INDEX v1.3: note #1 = 95 BCs, changelog section present, date-monotonic | PASS |
| 4 | bc-authoring-plan v2.14: gate #32 carrier #5 = 22-module subset | PASS |
| 5 | stale-86 grep: zero current-state "86" residue (historical changelog entries exempt) | PASS |
| 6 | gate #28 date-monotonicity: 4/4 files monotonic (D18-P65-A discipline) | PASS |

---

### Census Rotation

| Gate | Check | Result |
|------|-------|--------|
| #15 | Retired-identifier zero-occurrence in BC bodies (PO scope) | FAIL → F-P74-01 (triggered OBS-P74-A) |
| #18 | Error code census — blanket-library boundary | PASS |
| #19 | Retired-identifier table enforcement (post-fix with new pattern) | PASS — ZERO live violations (4 non-live audit-trail/Python-context lines documented) |
| #22 | E-MCP-005 TRANSPORT/Never anchored in BC-2.09.006, 6 RetryHint divergences | PASS |
| #28 | Date-monotonicity across supplement changelogs | PASS |
| #32 | ADR-propagation census: 22-module subset (gate #32 = 22-module subset) | PASS |

---

### Free Probes

- **VP-INDEX ↔ BC anchor bidirectionality:** 5 VPs; BC-INDEX VP column = 3 Kani seeds. No drift. CLEAN.
- **Stale-count grep:** zero live stale count assertions found. CLEAN.
- **Post-fix gate #19 census (new extended pattern):** ZERO live violations. 4 non-live lines identified as: (a) bc-authoring-plan changelog row documenting old→new pattern change [audit trail], (b) domain-spec/ Python mapping table entries [excluded by updated exclusion list], (c) interface-definitions.md changelog row referencing the corrected residue [audit trail]. All documented. CLEAN.

---

## Novelty Assessment

**MEDIUM-HIGH** — Two-layered structural census blind spot: (1) gate #15 explicitly excluded interface-definitions.md from retired-spelling enforcement (architect scope); (2) gate #19's grep pattern listed retired names in prose but the command never matched them. Standard census rotation would not detect this gap because both gates appeared structurally valid. The defect class (per-gate exclusion + per-gate pattern omission combining to leave a whole artifact class uncovered) is novel within Phase 1d.

**Trajectory:** →1 (P1D-74). Convergence counter 0/3.
