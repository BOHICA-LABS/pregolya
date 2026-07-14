---
document_type: adversarial-review-pass
phase: 1d
pass: 32
verdict: NOT CLEAN
findings_count: 4
high_count: 1
med_count: 2
low_count: 1
observations_count: 3
consecutive_clean: 0
required_clean: 3
trajectory: "...→6→1→1→4"
timestamp: 2026-07-14T00:00:00Z
new_class: "summary-vs-table arithmetic divergence (module-criticality docs)"
---

# Adversarial Review Pass 32 — Phase 1d

**Verdict: NOT CLEAN** — 4 findings (1 HIGH, 2 MED, 1 LOW) + 3 observations. Counter reset: 0/3 consecutive clean.

---

## F-P32-01 [HIGH] — arch-view module-criticality.md Summary Diverges from Table

**Finding class:** Summary-vs-table arithmetic divergence — new class this pass.

**Scope:** `.factory/specs/module-criticality.md` (arch-view, authoritative post-Phase 1b) §Summary

**Finding:** The Classification Summary in the arch-view module-criticality.md does not match the actual row counts in the Module Inventory table. Pre-fix summary stated `HIGH 10 / MEDIUM 12 / Total 33`. Actual row recount: `CRITICAL 9 / HIGH 11 / MEDIUM 10 / LOW 2 = 32 rows`. The discrepancy: HIGH understated by 1 (10 vs 11 actual), MEDIUM overstated by 2 (12 vs 10 actual), and Total overstated by 1 (33 vs 32 actual). The summary rows add to 9+10+12+2=33 but the table row count was 32 — an internal self-sum contradiction. This means the Summary was never reconciled against the actual table when the arch-view was first produced or subsequently edited.

**Severity justification (HIGH):** The arch-view is the authoritative criticality document consumed by architect, formal-verifier, and story-writer to route mutation testing requirements. An incorrect HIGH count misleads the verifier team about how many HIGH-tier modules require ≥90% kill rate enforcement. The MEDIUM over-count has the same misleading effect. Any automation that processes Summary counts (e.g., gate checks) would also produce incorrect totals.

**Fix applied:** Recount performed row-by-row (see verification below). Summary rewritten to `CRITICAL 9 / HIGH 12 / MEDIUM 10 / LOW 2 = 33` (33 because ferrochain-macros HIGH row was added by F-P32-04 in the same burst — see adjudication). Version bump 1.0 → 1.1. Changelog entry added.

---

## F-P32-02 [MED] — prd-supplements/module-criticality.md Classification Summary MEDIUM Cell Off-by-One

**Finding class:** Summary-vs-table arithmetic divergence (sibling document).

**Scope:** `.factory/specs/prd-supplements/module-criticality.md` §Classification Summary (lines ~112–118)

**Finding:** The Classification Summary MEDIUM cell reads `5`. Actual count of MEDIUM-tier rows in the Module Classification table: 4 (MCP tool adapter, ferrochain-splitters, Sandbox WASM/container backend, ferrochain-standard-tests). The stated total is 20, but if MEDIUM=5 the implied sum is 6+8+5+2=21 ≠ 20 — the Summary is internally inconsistent. The percentage column also reads 25% (5/20) rather than the correct 20% (4/20).

**Context:** OBS-P31-1 in the previous burst added a HIGH row (ferrochain-macros) and correctly updated HIGH and Total; however, neither the MEDIUM count nor the MEDIUM percentage were touched, and the document had an off-by-one MEDIUM count that predated OBS-P31-1. The OBS-P31-1 fix inadvertently masked this pre-existing error by making the total appear correct (20) while the MEDIUM cell remained wrong.

**Fix applied:** `prd-supplements/module-criticality.md` MEDIUM cell corrected `5 → 4`, percentage `25% → 20%`. Post-fix self-sum: 6+8+4+2=20=stated total. Version bump 1.1 → 1.2. Changelog entry added.

---

## F-P32-03 [MED] — GET /assistants/{assistant_id}/versions Unbounded / Unpaginated

**Finding class:** Pagination/query-param coherence (gate #24 — versions-list sibling endpoint not checked in pass-31 pagination sweep).

**Scope:** `.factory/specs/prd-supplements/interface-definitions.md` §Assistants `/versions` row (line ~183); `BC-2.12.002` §Version Operations (PC17)

**Finding:** `GET /assistants/{assistant_id}/versions` has no declared pagination. The versions list grows unbounded — one immutable snapshot is created per `PATCH` (BC-2.12.002 PC10), and EC-004 establishes that `/versions` is the only path to access historical snapshots. A long-lived assistant with thousands of patches would return an unbounded payload with no limit cap. The endpoint also has no declared ordering, leaving implementers with no anchor.

**Gate #24 miss analysis:** Pass-31 pagination sweep (F-P31-01) covered GET /threads, GET /threads/{id}/history, GET /assistants (list), GET /threads/{id}/runs, and GET /runs?schedule_id. The `/versions` sub-resource endpoint was not in scope because it is not a "list assistants" endpoint — it is a per-resource version-history endpoint. However it still returns an array and carries the same unbounded-payload risk. Gate #24 as written triggers on "list/aggregate GET endpoint" — the `/versions` path qualifies and should have been caught. This is a gate #24 scope gap that gate #25 (OBS-P32-3) will close.

**Ordering decision:** Unlike all other list endpoints where `created_at` DESC is the sensible default (most-recent first for operational monitoring), the versions list is most naturally consumed in **version ASC** order — clients replaying history read from lowest to highest. DECISION: `version` ascending; this is a documented ordering exemption from the canonical `created_at` DESC convention.

**Pagination parameters:** Same canonical convention as all other list endpoints: `limit` (default 10, max 100; values > 100 silently clamped to 100; clamp canon per F-P31-01), `offset` (default 0).

**Fixes applied:**
1. `interface-definitions.md` (v2.2 → v2.3): `/versions` row updated with canonical pagination + explicit version ASC ordering exemption. BC-2.12.002 PC20 cited as anchor.
2. `BC-2.12.002.md` (v1.0 → v1.1): PC20 added — `GET /assistants/{id}/versions` pagination (limit default 10 max 100 clamped / offset 0 / ordering exemption version ASC). Changelog entry added.

---

## F-P32-04 [LOW — ADJUDICATED] — arch-view module-criticality.md Missing ferrochain-macros Row and Exclusion Note

**Finding class:** Criticality-sibling coherence — OBS-P31-1 applied to prd-supplements but not mirrored to arch-view.

**Scope:** `.factory/specs/module-criticality.md` (arch-view) §Module Inventory

**Finding:** OBS-P31-1 (ADV-P1D-PASS-31) added a ferrochain-macros HIGH-tier row and exclusion-criteria blockquote to `prd-supplements/module-criticality.md` but did NOT apply the same change to the authoritative arch-view file at `.factory/specs/module-criticality.md`. The arch-view had no ferrochain-macros row and no exclusion-criteria note, creating a sibling-coherence gap between the two criticality documents.

**ORCHESTRATOR ADJUDICATION (pre-fix, consistent with OBS-P31-1 decision):** ferrochain-macros is criticality-bearing HIGH — `#[tool]` generates ToolDefinition plumbing consumed by all P0 tool-calling paths (BC-2.09.001, BC-2.09.002) and `#[entrypoint]` gates graph composition entry points; incorrect macro expansion silently corrupts P0 execution without a clear runtime error. The arch-view MUST include the macros row at HIGH tier, consistent with the prd-supplements decision and per ADR-008.

**Fix applied:** `module-criticality.md` (v1.0 → v1.1):
- Added `ferrochain-macros (#[tool], #[entrypoint]) | ferrochain-macros | — | HIGH | — | ≥ 90% | P5` to Module Inventory after the `lineage` row.
- Added exclusion-criteria blockquote mirroring prd-supplements/module-criticality.md — facade/re-export crates excluded; ferrochain-macros NOT excluded; rationale present.
- Summary rewritten (in the same edit as F-P32-01): CRITICAL 9 / HIGH 12 / MEDIUM 10 / LOW 2 = 33.

---

## Pagination Gate #24 Sibling-Check: /versions FAIL

| Census | Command | Pre-fix Result | Post-fix Result |
|--------|---------|---------------|----------------|
| Gate #24: GET /versions row carries pagination | `grep "versions" interface-definitions.md` | **FAIL** — row had no pagination, no ordering declared | PASS — limit default 10 max 100 clamped / offset 0 / version ASC exemption present |
| Gate #24: BC-2.12.002 PC matching /versions pagination | `grep -n "limit\|offset" BC-2.12.002.md` | **FAIL** — no PC for /versions pagination | PASS — PC20 added with full limit/offset/ordering exemption |

---

## Rotated Census Results (4 Selected)

| Census | Command | Result |
|--------|---------|--------|
| Arch-view Summary reconciles with table | Python row recount: CRITICAL=9, HIGH=12, MEDIUM=10, LOW=2, Total=33 | PASS — Summary cells match row recount exactly post-fix |
| PO-draft Summary self-sum reconciles | 6+8+4+2=20=stated total | PASS — MEDIUM corrected 5→4; self-sum 20=20 ✓ |
| Both criticality docs agree on macros tier | `grep "ferrochain-macros\|Proc-macro" both files` | PASS — arch-view: HIGH ✓; prd-supplements: HIGH ✓ |
| /versions pagination + BC-2.12.002 PC20 present | `grep "limit\|offset" interface-definitions.md` + `grep "PC20\|20\." BC-2.12.002.md` | PASS — /versions row carries pagination + version ASC exemption; PC20 present at line 82 |

---

## Observations

### OBS-P32-1 (applied) — No List-All-Schedules Endpoint Note Missing from §Cron Schedules

**Finding:** The §Cron Schedules section of `interface-definitions.md` did not document that v1 provides no `GET /schedules` list endpoint. A reader new to the API could reasonably expect a list endpoint to exist alongside the create/get/patch/delete schedule endpoints. The absence was documented in pass-23 URL-scheme canon but not surfaced as a note in the §Cron Schedules section.

**Fix applied:** Added note to §Cron Schedules (version bump covered by F-P32-03 changelog): "No list-all-schedules endpoint in v1 — schedules are addressed individually by cron_id; the flat `GET /runs?schedule_id={cron_id}` aggregate is the only schedule-scoped listing surface (URL-scheme canon, ADV-P1D-PASS-23)."

### OBS-P32-2 (record only) — Gate #24 Scope Gap on Sub-Resource Array Endpoints

**Finding:** Gate #24 PAGINATION COHERENCE (added pass-31) was scoped to "list/aggregate GET endpoints" but did not explicitly call out sub-resource array endpoints (e.g., `/versions`, `/history`). The `/history` endpoint was covered in pass-31 because it was in scope of the pagination sweep at that time; the `/versions` endpoint was not covered because it was added after the sweep. Gate #24's census commands did not include a check for `/versions`.

**Decision:** Gate #24 wording is sufficient — "list endpoint rows" includes any endpoint returning an array. The miss was a human-review scope limitation, not a gate wording defect. Gate #25 (OBS-P32-3) adds the criticality-sibling check that would have prevented the arch-view/prd-supplements divergence. No edit to gate #24 wording required. Record only.

### OBS-P32-3 (applied) [process-gap] — No Standing Gate for Summary-Arithmetic + Criticality-Sibling Coherence

**Finding:** Two process gaps revealed by this pass:
1. Any edit to a table with a Summary section must reconcile Summary cells against actual row counts in the same burst. There was no standing gate enforcing this. The arch-view summary diverged from its table undetected.
2. Any edit to either criticality document must update BOTH documents (arch-view + prd-supplements) in the same burst. OBS-P31-1 updated only the prd-supplements, leaving the arch-view out of sync.

**Fix applied:** Gate #25 SUMMARY-ARITHMETIC + CRITICALITY-SIBLING COHERENCE appended to `bc-authoring-plan.md` (standing gate, [process-gap] tag). Two-part gate: Part A covers summary reconciliation for any table with a summary section; Part B covers mandatory dual-document update for any criticality edit. Root cause documented in gate text.

---

## NEW CLASS: Summary-vs-Table Arithmetic Divergence

**Definition:** A spec document maintains a count-summary table (Classification Summary, Module Count, etc.) derived from a sibling data table, but the summary cells diverge from the actual data-table row counts due to row additions, removals, or re-tiering that updated the data table without reconciling the summary. The divergence may be: a single tier off-by-one, a self-sum that doesn't equal the stated total, a percentage column that disagrees with the count, or a sibling document that received the same data-table edit but not the summary update.

**Characteristics:**
- Compound risk: a summary-table edit that is arithmetically consistent internally (e.g., total looks right) can hide a tier-level error if two cells are wrong in opposite directions (as in F-P32-01: HIGH -1 / MEDIUM +2 / Total +1 — all cells wrong)
- Sibling documents (arch-view + prd-supplements for criticality) are independently maintained and will diverge when a burst updates one but not the other
- The error class is invisible to semantic review (reviewers read the summary as authority rather than re-counting the table) and only emerges under a dedicated arithmetic audit axis

**Drain status:** Both live occurrences drained this burst (arch-view F-P32-01 + F-P32-04; prd-supplements F-P32-02). Standing gate #25 SUMMARY-ARITHMETIC + CRITICALITY-SIBLING COHERENCE added to `bc-authoring-plan.md` to prevent recurrence.

---

## Sibling Reverse-Anchor Checks

No BCs added or retired this burst. No E-codes minted. BC count unchanged: P0 48 + P1 30 + P2 8 = 86 total.

**(a) BC and artifact version bumps consistent with changelog entries:**
- `module-criticality.md` (arch-view): 1.0 → 1.1 ✓ (F-P32-01 + F-P32-04)
- `prd-supplements/module-criticality.md`: 1.1 → 1.2 ✓ (F-P32-02)
- `prd-supplements/interface-definitions.md`: 2.2 → 2.3 ✓ (F-P32-03 + OBS-P32-1)
- `BC-2.12.002.md`: 1.0 → 1.1 ✓ (F-P32-03 PC20)
- `bc-authoring-plan.md`: gate #25 appended ✓ (no version field — narrative update)

**(b) Ordering exemption documented for /versions:**
`grep -n "version.*ascending\|version ASC\|exemption" interface-definitions.md` → /versions row carries "ordering exemption: version ascending — deviates from created_at DESC canon". BC-2.12.002 PC20 cites same exemption. PASS.

**(c) Both criticality docs agree on macros classification (HIGH):**
- Arch-view: `| ferrochain-macros (#[tool], #[entrypoint]) | ferrochain-macros | — | HIGH |` ✓
- PO-draft: `| Proc-macro suite (#[tool], #[entrypoint]) | ferrochain-macros | HIGH |` ✓
Cross-check: PASS.

---

## Novelty Assessment

**Classification: HIGH.**

**Trajectory context:** Pass counts: ...→6 (P29)→1 (P30)→1 (P31)→4 (P32). After two consecutive passes at minimum (1 finding), this pass returned 4 findings — a rebound driven by a completely new audit axis. The trajectory break is significant: the arithmetic audit axis had never been run in any prior pass.

**New class assessment:** The summary-vs-table arithmetic divergence class is NEW and HIGH novelty because:
- An entirely new audit axis was applied: direct row-by-row recount of every tier in the Module Inventory table and comparison against the Summary section
- The class found two independent instances (arch-view + prd-supplements) plus a sibling-coherence gap — compound severity
- The root error in the arch-view (HIGH -1 / MEDIUM +2) was internally inconsistent: the Summary cells disagreed with each other AND with the table, but the Total happened to be 33 in both the wrong summary and the post-macros-addition correct summary, masking the pre-existing error from casual review
- The class is expected to occur in other tabular specs that maintain summary sections — the standing gate is essential to prevent recurrence

**Recovery signal:** With F-P32-01/02/04 fixed, both criticality docs have reconciled summaries and synchronized content. Gate #25 closes the process gap. The remaining novelty surface is: (1) arithmetic audits in other tabular spec sections (test-vectors.md, error-taxonomy.md counts), (2) any future sub-resource array endpoint that gets added without a pagination check. Both are now covered by standing gates (#25 and #24 respectively).

---

## BC↔Taxonomy Category Census — PASS (73 Active Codes, Zero New Codes, Zero Mismatches)

> Census scope: all active (non-retired) error codes in error-taxonomy.md vs their BC anchor's category declaration. No new E-codes minted this burst. Retired codes excluded.

Census result: **73 active codes, ZERO category mismatches.** Pass-31 census table carried forward; no changes to error-code categories this pass.

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P32-01 | `.factory/specs/module-criticality.md` | Summary rewritten: CRITICAL 9, HIGH 12, MEDIUM 10, LOW 2, Total 33 (row recount confirmed exact match); v1.0→1.1; changelog entry | APPLIED |
| F-P32-02 | `.factory/specs/prd-supplements/module-criticality.md` | Classification Summary MEDIUM 5→4, percentage 25%→20%; self-sum 20=20 ✓; v1.1→1.2; changelog entry | APPLIED |
| F-P32-03 | `.factory/specs/prd-supplements/interface-definitions.md` | /versions row: add limit default 10 max 100 clamped / offset 0 / ordering exemption version ASC; BC-2.12.002 PC20 cited; v2.2→2.3; changelog entry | APPLIED |
| F-P32-03 | `.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` | PC20 added — /versions pagination (limit 10/100/clamped/offset 0/version ASC exemption); v1.0→1.1; changelog entry | APPLIED |
| F-P32-04 | `.factory/specs/module-criticality.md` | ferrochain-macros HIGH row added to Module Inventory (after lineage, before sqlite backend); exclusion-criteria blockquote added; covered in same v1.0→1.1 bump as F-P32-01 | APPLIED |
| OBS-P32-1 | `.factory/specs/prd-supplements/interface-definitions.md` | No-list-schedules note added to §Cron Schedules; covered in same v2.2→2.3 bump as F-P32-03 | APPLIED |
| OBS-P32-2 | — | Gate #24 scope gap on sub-resource arrays — record only; gate #24 wording sufficient; gate #25 addresses root cause | RECORD ONLY |
| OBS-P32-3 | `.factory/specs/prd-supplements/bc-authoring-plan.md` | Gate #25 SUMMARY-ARITHMETIC + CRITICALITY-SIBLING COHERENCE appended (standing gate, [process-gap]); no version field | APPLIED |

---

## Post-Fix Verification

| Check | Command | Result |
|-------|---------|--------|
| (1) Arch-view: row recount == Summary cells | Python row recount: CRITICAL=9, HIGH=12, MEDIUM=10, LOW=2, Total=33 | PASS — Summary cells match exactly; ferrochain-macros HIGH row confirmed present |
| (1) Arch-view: exclusion note present | `grep -n "Exclusion criteria" module-criticality.md` | PASS — exclusion-criteria blockquote present with facade-crate reasoning and ferrochain-macros decision |
| (2) PO-draft: MEDIUM=4, self-sum=20 | Python row recount PO-draft: CRITICAL=6, HIGH=8, MEDIUM=4, LOW=2, Total=20 | PASS — MEDIUM=4 ✓; 6+8+4+2=20=stated Total ✓ |
| (3) /versions row carries pagination + version ASC exemption | `grep "versions" interface-definitions.md \| grep "GET"` | PASS — limit default 10 max 100 clamped / offset 0 / version ASC ordering exemption / F-P32-03 / BC-2.12.002 PC20 all present |
| (3) BC-2.12.002 PC20 matches /versions row | `grep -n "limit\|offset" BC-2.12.002.md` | PASS — PC20 at line 82: "limit (default 10, max 100; values > 100 silently clamped to 100), offset (default 0). Ordering exemption: version ascending" |
| (4) No-list-schedules note present in §Cron Schedules | `grep -n "No list-all-schedules\|OBS-P32-1" interface-definitions.md` | PASS — line 205: OBS-P32-1 note present |
| (5) Gate #25 present in bc-authoring-plan.md | `grep -n "gate #25\|SUMMARY-ARITHMETIC" bc-authoring-plan.md` | PASS — line 702: gate #25 SUMMARY-ARITHMETIC + CRITICALITY-SIBLING COHERENCE present |
| (6) Cross-check: both criticality docs agree on macros HIGH | `grep "ferrochain-macros\|Proc-macro" both files \| grep "HIGH"` | PASS — arch-view: HIGH ✓; prd-supplements: HIGH ✓ |
