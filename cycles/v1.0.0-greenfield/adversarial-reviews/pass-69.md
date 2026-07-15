---
document_type: adversarial-review-pass
phase: 1d
pass: 69
verdict: NOT CLEAN
findings_count: 1
high_count: 1
med_count: 0
low_count: 0
observations_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "→0→1→0"
timestamp: 2026-07-18T23:30:00Z
novelty: MEDIUM
new_class: "range-shorthand category mismatch — range expression in status row sweeps in a code whose category does not match the row label; undetectable by per-code membership census"
routing: "product-owner: F-P69-01 fix (interface-definitions.md 400 row + E-CORE-004 omission note), OBS-P69-1 gate-widen (bc-authoring-plan.md gate #20)"
sibling_checks:
  - "SC-1 422-row 6 codes (E-CHKPT-001,-002,-003,-004,-006,-007) PASS — F-P67-01 fix confirmed"
  - "SC-2 tombstone/homes/census 78 independent recount PASS"
  - "SC-3 gate #33 reverse-anchor spot 10/10 PASS"
censuses:
  - "#14 harness-fn registry consistent PASS"
  - "#15 shared-type zero retired spellings PASS"
  - "#19/#26 retired identifiers zero live occurrences PASS"
  - "#22 RetryHint exactly 5 intentional divergences PASS"
  - "#24 pagination 5 endpoints covered PASS"
  - "#29 SS-13 seams correct PASS"
  - "#31 type-resolution 19/21 resolved + 2 implementer-scope PASS"
  - "#32 ADR-propagation bidirectional PASS"
  - "#33 reverse 10/10 spot PASS"
extra_axes: []
free_probes:
  - "range-notation category sweep (NEW) — 400 row 'E-CORE-001 through E-CORE-005' expands to include E-CORE-004 (INTERNAL, not VAL) → F-P69-01 FAIL"
  - "independent live-code recount: 78 = 44+11+23 census PASS"
---

# Adversarial Review Pass 69 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (1 HIGH, 0 MED, 0 LOW). Novelty: MEDIUM.

---

## F-P69-01 (HIGH, confidence HIGH): 400 row range silently includes E-CORE-004 (INTERNAL) — RFC-7807 self-contradiction

**File:** `.factory/specs/prd-supplements/interface-definitions.md` §HTTP Status Codes, 400 row

**Finding:**

The 400 row reads:

> E-CORE-001 through E-CORE-005, E-CRON-002 (InvalidCronExpression); E-PROV-005 …

The range "E-CORE-001 through E-CORE-005" silently includes **E-CORE-004**, whose category in
`error-taxonomy.md` (line 71) is **INTERNAL** — not VAL. The 400 row's description explicitly
asserts "categorical VAL→400", making E-CORE-004's presence an RFC-7807 self-contradiction: a
code with `category: INTERNAL` (title "Internal") is listed in a row that claims categorical
VAL→400 routing.

E-CORE-004 (pipe composition type-boundary mismatch — BC-2.01.004 PC5) is a library-layer
`Err(FerrochainError { category: INTERNAL, code: E-CORE-004 })` returned by
`RunnableSequence::invoke` when a type-erased DynRunnable pipeline detects a stage type mismatch
at first invocation. It is never surfaced as a direct HTTP terminal response by ferrochain-server.
It belongs in an individual omission note (INTERNAL→500 categorical fallback) following the
pattern of E-CORE-006 and E-CORE-007.

Supporting facts:
- error-taxonomy.md line 71: `E-CORE-004 | INTERNAL | broken | BC-2.01.004`
- BC-2.01.004 PC5: "returns `Err(FerrochainError { category: INTERNAL, code: E-CORE-004 })`"
- E-CORE-007 is already absent from the 400 row with an individual omission note
- E-CORE-006 is already absent from the 400 row with an individual omission note
- Range stops correctly at E-CORE-005 (excluding E-CORE-006, -007); E-CORE-004 is the lone INTERNAL swept in by shorthand

**Root cause:** The range notation "E-CORE-001 through E-CORE-005" is opaque to category verification.
A reader (or census) checks only whether the code name appears, not whether its category matches
the row label. E-CORE-004 was introduced as INTERNAL (BC-2.01.004 — pipe composition) long before
the range was written. No census axis checked category-of-member-within-range against row-label.

**Concrete failure scenario:** An implementer building BC-2.14.002's HTTP status routing map reads
"E-CORE-001 through E-CORE-005 → 400". They implement `E-CORE-004 => StatusCode::BAD_REQUEST`.
The implemented server returns HTTP 400 for a pipe-composition type-mismatch error — a 5xx-class
internal error returned as 4xx, misdirecting clients into believing the request was malformed rather
than reporting a server-side programming error.

**Fix (product-owner):**
1. Replace "E-CORE-001 through E-CORE-005" with explicit enumeration "E-CORE-001, E-CORE-002, E-CORE-003, E-CORE-005".
2. Add E-CORE-004 individual omission note mirroring E-CORE-006 / E-CORE-007 pattern.
3. Update disposition census (44 HTTP → 43 HTTP; 11 omission → 12 omission; total 78 unchanged).

---

## OBS-P69-1 [process-gap]: Gate #20 lacks INTERNAL→500 axis and range-expansion rule

**Observation:** Gate #20 (AUTH/POLICY category re-sweep) verifies AUTH→401, POLICY→403,
CONCURRENCY→409 mappings, but has no axis for INTERNAL→500. A code with INTERNAL category
swept into a VAL-labeled row escapes all existing census checks. Additionally, range notation
("X through Y") in status rows is not flagged as requiring member-level category verification.

**Recommendation:** Widen gate #20 to add:
(a) INTERNAL→500 axis — every INTERNAL code maps to the 500 row OR has a documented
omission note; no INTERNAL code in a VAL-labeled row.
(b) Range-expansion rule — any range expression in status rows must be mentally expanded and
each member's category verified against the row label on every table edit. Prefer explicit
enumerations over ranges in all status table rows.

---

## Regression Spot-Checks

| Check | Result |
|-------|--------|
| SC-1: 422 row cross-row enumeration (6 CHKPT codes + 2 GRAPH codes) | PASS — F-P67-01 fix present; E-CHKPT-007 included |
| SC-2: 78 live-code recount (44 HTTP + 11 omission + 23 blanket) | PASS — arithmetic confirmed independently |
| SC-3: Gate #33 reverse-anchor spot (10 BCs sampled) | PASS — all 10 sampled BCs bidirectional |

---

## Full Census Results (9 censuses)

| Census | Result |
|--------|--------|
| #14 harness-fn registry | PASS |
| #15 shared-type zero retired spellings | PASS |
| #19/#26 retired identifiers | PASS |
| #22 RetryHint exactly 5 intentional divergences | PASS |
| #24 pagination 5 endpoints | PASS |
| #29 SS-13 seams | PASS |
| #31 type-resolution 19/21 + 2 implementer-scope | PASS |
| #32 ADR-propagation | PASS |
| #33 reverse 10/10 spot | PASS |

---

## Novelty Assessment

**MEDIUM.** F-P69-01 represents a new class of finding: *range-shorthand category mismatch*
— a range expression in a status row that sweeps in a member whose category does not match
the row's label. This class was invisible to all prior censuses (which check "is code X in
the table?" but not "does code X's category match the row label?"). Strong convergence on
all other dimensions: 9 full censuses PASS, 3 regression checks PASS. The range-expansion
census rule (gate #20 widening) is the durable process fix.

---

## Routing

| Agent | Action |
|-------|--------|
| product-owner | Fix F-P69-01: interface-definitions.md v2.18→v2.19 (400 row, E-CORE-004 omission note, census) |
| product-owner | OBS-P69-1: bc-authoring-plan.md v2.8→v2.9 (gate #20 INTERNAL axis + range-expansion rule) |
| state-manager | Commit both files after product-owner confirms |
