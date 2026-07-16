---
document_type: adversarial-review
phase: 1d
pass: 81
verdict: NOT CLEAN
finding_count: 1
finding_severity: [MED]
novelty: LOW-MEDIUM
novelty_class: fabricated-variant-name-single-site
sibling_checks: "1/1 PASS"
timestamp: 2026-07-15T00:00:00Z
---

# Adversarial Review — Pass 81 (Phase 1d)

**Verdict:** NOT CLEAN — 1 finding (MED), FIXED same burst.

---

## F-P81-01 (MED, FIXED) — BC-2.08.014 TV-007 Fabricated PascalCase Variant Name

**Location:** `.factory/specs/behavioral-contracts/ss-08/BC-2.08.014.md` — TV-007

**Finding:** BC-2.08.014 TV-007 (empty fallback chain at config construction) previously asserted
the expected output as `Err(E-CORE-005 ValidationFailed)`. The PascalCase variant name
`ValidationFailed` does not exist in error-taxonomy.md: E-CORE-005's entry carries a plain prose
message (`"<field>: <reason>"` template), no PascalCase discriminant. The form `Err(E-CORE-005
ValidationFailed)` is an informal shorthand that violates the canonical bare-code error citation
convention used consistently across all 11 sibling BC TV/EC entries that reference E-CORE-005
(including the direct sibling BC-2.08.002 TV-005).

**Sibling census (all E-CORE-005 citations across BCs):** 11 sites scanned. All 10 pre-existing
citations use bare-code form `Err(FerrochainError { category: VAL, code: E-CORE-005 })` or
EC-body equivalents without a PascalCase variant. BC-2.08.014 TV-007 was the sole outlier with
the fabricated `ValidationFailed` appended.

**Adjudication:** informal shorthand, not canonical. The taxonomy has no variant names for
E-CORE-005 — the variant-name was an unfounded abbreviation. Dropped. The canonical form is
the bare-code structure used by all siblings.

**Fix applied (BC-2.08.014 v1.1):**
- TV-007 Expected Output: `Err(E-CORE-005 ValidationFailed)` → `Err(FerrochainError { category: VAL, code: E-CORE-005 })`.
- Form is verbatim match to BC-2.08.002 TV-005 (direct sibling; same E-CORE-005 bare-code raise context).
- Changelog entry added, frontmatter version bumped to "1.1", timestamp confirmed 2026-07-15T00:00:00Z.

**Residue grep:** zero live occurrences of `ValidationFailed` in `.factory/specs/` after fix.
Six changelog glosses in the historical note (`E-CORE-005 ValidationFailed` cited as the
pre-fix defect form) are exempt — historical audit-trail, not live assertions.

**BC-2.08.014 → v1.1.**

---

## Sibling-Checks (1/1 PASS)

1. **BC-2.08.014 v1.1 currency** — frontmatter version "1.1" confirmed; changelog entry 1.1
   dated 2026-07-15 present; frontmatter timestamp 2026-07-15T00:00:00Z confirmed (gate #28
   Rule 5 frontmatter-currency PASS). TV-007 Expected Output now reads bare-code form
   `Err(FerrochainError { category: VAL, code: E-CORE-005 })` — no PascalCase variant. PASS.

---

## Clean Verifications

**MANDATORY hedge sweep:** All `"or similar"` / `"or equivalent"` hits in `.factory/specs/`
that wrap a specific E-code were scanned. No new hedge-shielded variant names found. The sole
standing E-code hedge is BC-2.15.004 EC-004 (`StorageFull` / `"or similar capacity-exceeded
error"`) — standing-adjudicated per prior passes, exempt. CLEAN.

**Gate #16 / #20 variant-name census:** ~60 error-code variant-name pairings checked across
all live BCs. All pairings are canonical (taxonomy-sourced). F-P81-01 was the sole fabricated
variant name in the census. No additional defects found.

**Gate #19 (retired identifier census):** zero live occurrences of retired type/function/module
names across all `.factory/specs/` BCs and supplements. CLEAN.

**Gate #27 (wrong-crate anchor census):** zero live wrong-crate anchors in Architecture Anchors
sections surveyed. CLEAN.

**BC file count on disk:** 95 BC files on disk = BC-INDEX count exactly. No ghost or orphan
files. CLEAN.

---

## Coverage Note (Explicit — Debt for Pass 82)

The following gates and probe angles were **NOT exercised this pass** and MUST rotate into
pass 82:

- **Gate #21** (HTTP status row ↔ E-code routing completeness)
- **Gate #23** (streaming-event names)
- **Gate #24** (pagination)
- **Gate #29** (supplement-vs-BC seam — taxonomy notes that reference BC rows)
- **Gate #30** (codeless-construction — constructors that return Err without an E-code)
- **Free probe:** domain-spec shard prose staleness (shards not touched since D20 expansion)
- **Free probe:** holdout-domain-B post-D20 freshness (domain-b brief vs D20 new BCs)

Pass 82 MUST include all seven of the above plus ≥1 novel probe angle.

---

## Novelty Assessment

**Novelty:** LOW-MEDIUM. **Class:** fabricated-variant-name-single-site. This is the shallowest
defect class yet observed in Phase 1d: a single informal shorthand in one TV row, no systemic
cascade, zero downstream propagation (single-site). The class is recognized (variant-name
fabrication), but the scope is minimal — consistent with terminal-phase decay of finding severity
and breadth.

**Trajectory:** →1 (P1D-81). **Convergence counter:** 0/3 (reset by this finding).
