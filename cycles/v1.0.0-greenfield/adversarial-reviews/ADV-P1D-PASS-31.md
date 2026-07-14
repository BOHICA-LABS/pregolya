---
document_type: adversarial-review-pass
phase: 1d
pass: 31
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 0
low_count: 1
observations_count: 3
consecutive_clean: 0
required_clean: 3
trajectory: "...→1→6→1→1"
timestamp: 2026-07-14T00:00:00Z
new_class: "pagination/query-param coherence"
---

# Adversarial Review Pass 31 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (0 HIGH, 0 MED, 1 LOW) + 3 observations. Counter reset: 0/3 consecutive clean.

---

## F-P31-01 [LOW] — Pagination Non-Uniformity Across List/Aggregate Endpoints

**Finding class:** Pagination/query-param coherence — new class this pass.

**Scope:**
- `interface-definitions.md` §Threads `GET /threads`, §Threads `GET /threads/{id}/history`, §Assistants `GET /assistants`, §Runs `GET /threads/{id}/runs`, §Cron Schedules cross-thread aggregate `GET /runs?schedule_id={cron_id}`
- `BC-2.12.001.md` PC8 (threads list — already specified), PC17 (history — limit param undeclared)
- `BC-2.12.003.md` PC17-18 (list runs — no pagination)
- `BC-2.12.004.md` (no PC for the aggregate query endpoint — covered only by TV-002 notes)

**Finding:** `BC-2.12.001 PC8` (`GET /threads`) established the canonical pagination convention — `limit` (default 10, max 100), `offset` — as a spec fact. Four sibling list/aggregate endpoints do not propagate this convention: the history endpoint (`PC17`) declares `?limit=N` without defaults or max; the list-runs endpoint (`BC-2.12.003 PC18`) has no pagination params at all; the assistants list row (`interface-definitions.md`) has no pagination; and the cross-thread cron aggregate (`GET /runs?schedule_id=`) has no pagination and no authoritative PC in `BC-2.12.004` (it appears only in TV-002 notes). The unbounded cross-thread aggregate is a real scaling hazard — a schedule with thousands of Runs and no limit cap can return unbounded payloads. The absence of a declared ordering canon for the aggregate also means implementers have no anchor.

**Pagination non-uniformity table (pre-fix state):**

| Endpoint | interface-definitions.md (pre-fix) | Anchor BC PC (pre-fix) | Status |
|----------|-----------------------------------|------------------------|--------|
| `GET /threads` | `(paginated, ?limit=&offset=)` — no defaults/max explicit | PC8: default 10, max 100, offset ✓ (already correct) | PARTIAL — interface row lacked explicit defaults |
| `GET /threads/{id}/history` | `(?limit=N)` — no default/max | PC17: `?limit=N` only — no default/max declared | **FIXED** |
| `GET /assistants` | "List assistants" — no pagination | BC-2.12.002: no matching PC checked (not anchor BC of finding) | **FIXED** |
| `GET /threads/{id}/runs` | `?status=...` filter only | PC18: status filter only — no limit/offset | **FIXED** |
| `GET /runs?schedule_id={cron_id}` | no pagination | BC-2.12.004: no PC for this endpoint (only TV-002 note) | **FIXED** — PC7 added |

**Out-of-range semantics decision:** BC-2.12.001 PC8 did not explicitly state clamp-vs-reject. No prior BC stated reject/E-CORE. DECISION: **clamp** (limit > 100 silently clamped to 100; no validation error). This avoids surprising callers who pass limit=200 expecting a larger page. Uniform across all list endpoints.

**Ordering canon for schedule-runs aggregate:** BC-2.12.004 had no explicit ordering declaration for `GET /runs?schedule_id=`. DECISION: `created_at` **descending** (most-recent firing first). This is intuitive for operational monitoring of a cron schedule and consistent with all other list endpoints. Declared in BC-2.12.004 PC7 as the authoritative ordering canon.

**Fixes applied:**
1. `interface-definitions.md` (v2.1 → v2.2): Add `§Canonical Pagination Convention` section immediately before `### Threads`, with parameter table (limit default 10 max 100 clamp / offset default 0) and ordering note (`created_at` DESC). Update 5 list endpoint rows to cite F-P31-01 with explicit defaults. BC anchors listed.
2. `BC-2.12.001.md` (v1.0 → v1.1): PC17 history endpoint — add "limit default 10, max 100; values > 100 clamped to 100; offset default 0 (F-P31-01)".
3. `BC-2.12.003.md` (v1.0 → v1.1): PC18 list-runs — extend to include limit/offset/clamped/`created_at` DESC.
4. `BC-2.12.004.md` (v1.0 → v1.1): Add PC7 `§Cross-Thread Aggregate Query` with full pagination declaration (limit default 10, max 100, clamped; offset 0; `created_at` DESC as ordering canon); update TV-002 Notes to cite F-P31-01.

---

## Sibling Reverse-Anchor Checks

No BCs added or retired this burst. No E-codes minted. BC count unchanged: P0 48 + P1 30 + P2 8 = 86 total.

**(a) BC and artifact version bumps consistent with changelog entries:**
- `interface-definitions.md`: 2.1 → 2.2 ✓ (F-P31-01 pagination propagation)
- `BC-2.12.001.md`: 1.0 → 1.1 ✓ (F-P31-01 PC17 history pagination)
- `BC-2.12.003.md`: 1.0 → 1.1 ✓ (F-P31-01 PC18 list-runs pagination)
- `BC-2.12.004.md`: 1.0 → 1.1 ✓ (F-P31-01 PC7 aggregate query + TV-002 update)
- `module-criticality.md`: 1.0 → 1.1 ✓ (OBS-P31-1 exclusion note + ferrochain-macros row)
- `bc-authoring-plan.md`: gate #24 PAGINATION COHERENCE appended ✓ (no version field — narrative update)

**(b) Pagination convention note present + gate #24 active:**
`grep -n "Canonical Pagination" interface-definitions.md` → line 145: `§Canonical Pagination Convention (F-P31-01, ADV-P1D-PASS-31)` present. `grep -n "PAGINATION COHERENCE\|gate #24" bc-authoring-plan.md` → line 666: gate #24 PAGINATION COHERENCE present. PASS.

**(c) Ordering canon documented for schedule-runs aggregate:**
`grep -n "created_at.*descend\|DESC" BC-2.12.004.md` → PC7 (line ~78): "Results are ordered `created_at` **descending** (most-recent firing first)." Canon declared. PASS.

---

## Rotated Census Results (4 Selected)

| Census | Command | Result |
|--------|---------|--------|
| Capability-tier census (P0 gates) | `grep -c "priority: P0" .factory/specs/behavioral-contracts/**/*.md` | PASS — 48 P0 BCs stable; no BCs added/retired this burst |
| HTTP dual-authority categorical-map (blanket note) | `grep -n "TOOL→" interface-definitions.md` | PASS — line ~250: `TOOL→422`; F-P30-01 fix carried forward; no regression |
| Pagination convention present in all 5 list rows | `grep -n "limit.*interface-definitions.md \| grep GET"` → 5 rows, all cite F-P31-01 | PASS — threads, history, assistants, runs, schedule-runs aggregate all carry pagination |
| BC-2.12.001 PC8 existing pagination consistency | `grep -n "default 10.*max 100" BC-2.12.001.md` | PASS — PC8 already had default 10, max 100, offset; unchanged; serves as the authoritative precedent that seeded F-P31-01 canon |

---

## Observations

### OBS-P31-1 (applied) — module-criticality.md Missing Exclusion-Criteria Note and ferrochain-macros Classification

**Finding:** `module-criticality.md` Module Inventory listed 13 crates but provided no explanation for which workspace crates were intentionally excluded from the Module Classification table. The workspace contains facade/re-export crates (`ferrochain` #1, `ferrochain-openai-sdk` #16, `ferrochain-anthropic-sdk` #17, `ferrochain-ollama-sdk` #18) and a proc-macro crate (`ferrochain-macros` #15) that are absent from both the inventory and classification table with no rationale. `xtask` is classified (LOW) but carries no "not a library" annotation that explains why dev-tooling receives a classification row while macros do not.

**Exception check performed — ferrochain-macros:** Per the job instructions and ADR-008, `ferrochain-macros` carries real `#[tool]` and `#[entrypoint]` proc-macro logic. `#[tool]` generates the ToolDefinition plumbing consumed by all P0 tool-calling paths (BC-2.09.001, BC-2.09.002); `#[entrypoint]` gates graph entry-point composition. Incorrect macro expansion silently corrupts P0 execution without a clear runtime error. DECISION: `ferrochain-macros` receives a **HIGH**-tier criticality row — it is NOT excluded as a facade crate.

**Fix applied:** `module-criticality.md` (v1.0 → v1.1):
- Added `ferrochain-macros` to Module Inventory with description.
- Added exclusion-criteria blockquote explaining facade/re-export crates (#1/#16/#17/#18) are excluded; `xtask` is classified because its file-size-check logic gates CI.
- Added `ferrochain-macros` HIGH-tier row to Module Classification table.
- Updated Classification Summary: HIGH 7→8, Total 19→20.

### OBS-P31-2 (record only — covered by F-P31-01) — Unbounded Aggregate Pagination Hazard

**Finding:** The `GET /runs?schedule_id={cron_id}` endpoint had no documented size bound or pagination. A high-frequency schedule (e.g., every second for a year) could produce >31M Run records; an unbounded query would return all of them.

**Decision:** Covered by F-P31-01 fix — PC7 declares limit/offset/clamped semantics. No separate fix required. Record only.

### OBS-P31-3 (record only — no edit) — BC-2.12.001 PC8 Already Conforms; No Change Needed

**Finding:** During the pagination census, `BC-2.12.001 PC8` was checked first as the precedent source. It already declared `limit` (default 10, max 100), `offset` — matching the proposed canon. The interface-definitions.md `GET /threads` row was updated to make the defaults explicit in the row description, but the BC PC itself required no edit.

**Decision:** Allowed-zone confirmation. The existing PC8 is the canonical source that justified the F-P31-01 clamp decision and default values. No further edits required. Record only.

---

## NEW CLASS: Pagination/Query-Param Coherence

**Definition:** A spec establishes a list/aggregate endpoint pagination convention in one BC or supplement but fails to propagate the same convention (defaults, max, out-of-range semantics, ordering) to sibling list endpoints or their anchor BCs. The divergence can be: absence of pagination params entirely (unbounded aggregate hazard), undeclared defaults (ambiguous implementer behavior), undeclared ordering (non-deterministic page results), or inconsistent out-of-range semantics across endpoints (some reject, some clamp).

**Characteristics:**
- Only occurs in specs with multiple list/aggregate endpoints where one endpoint is used as the implicit pattern source
- Particularly acute for cross-subsystem aggregate queries (e.g., flat `/runs?schedule_id=`) that lack both a dedicated BC section and explicit pagination
- Out-of-range semantics (clamp vs. reject) must be decided once and applied uniformly — per-endpoint variation is a separate class of finding
- Ordering canon is part of pagination coherence: a list endpoint without a declared ordering is implicitly non-deterministic across implementations

**Drain status:** All live occurrences drained this burst (1 finding + full propagation to 4 endpoints + 3 BCs). Standing gate #24 PAGINATION COHERENCE added to `bc-authoring-plan.md` to prevent recurrence on future list-endpoint additions.

---

## BC↔Taxonomy Category Census — PASS (73 Active Codes, Zero New Codes, Zero Mismatches)

> Census scope: all active (non-retired) error codes in error-taxonomy.md vs their BC anchor's category declaration. No new E-codes minted this burst. Retired codes excluded.

Census result: **73 active codes, ZERO category mismatches.** Pass-30 census table carried forward; no changes to error-code categories this pass.

---

## Novelty Assessment

**Classification: MEDIUM.**

**Trajectory context:** Pass counts: ...→1 (P28)→6 (P29)→1 (P30)→1 (P31). Two consecutive passes at 1 finding, both LOW severity. P31 matches P30's minimum count. The trajectory suggests the spec has entered a stable phase where individual passes find one cross-cutting coherence gap rather than clusters of related issues.

**New class assessment:** The pagination/query-param coherence class is new and MEDIUM novelty because:
- Two new edge axes were probed: (1) pagination parameter uniformity across sibling endpoints, (2) explicit ordering canon for aggregate queries
- The finding was LOW severity — no BC was semantically wrong, only underdeclared
- The root cause is a common spec-authoring pattern: anchor the convention in the first endpoint spec'd, never propagate it to siblings
- One prior unambiguous precedent (`BC-2.12.001 PC8`) provided the canon values — the fix was mechanical propagation

**Recovery signal:** With F-P31-01 fixed, all 5 list endpoints now carry uniform pagination. Gate #24 PAGINATION COHERENCE is active, preventing recurrence. The spec-core structural axes (HTTP codes, error taxonomy, streaming events, wire objects) have been stable for multiple passes. The remaining novelty surface is cross-endpoint convention coherence — a narrower, lower-severity class.

**Adversary expectation:** CLEAN with LOW novelty if next pass finds no new endpoint-convention gaps and no propagation regressions from this burst's pagination canon addition.

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P31-01 | interface-definitions.md | §Canonical Pagination Convention section added; 5 list rows updated with explicit defaults + F-P31-01 cite; v2.1→2.2; changelog entry | APPLIED |
| F-P31-01 | BC-2.12.001.md | PC17 history: declare limit default 10/max 100/clamped/offset default 0; v1.0→1.1; changelog entry | APPLIED |
| F-P31-01 | BC-2.12.003.md | PC18 list-runs: add limit/offset/clamped/created_at DESC; v1.0→1.1; changelog entry | APPLIED |
| F-P31-01 | BC-2.12.004.md | PC7 added (§Cross-Thread Aggregate Query) with full pagination + created_at DESC ordering canon; TV-002 notes updated to cite F-P31-01; v1.0→1.1; changelog entry | APPLIED |
| OBS-P31-1 | module-criticality.md | Exclusion-criteria blockquote + ferrochain-macros to Module Inventory + HIGH row to Classification table + Summary counts updated (HIGH 7→8, Total 19→20); v1.0→1.1; changelog entry | APPLIED |
| OBS-P31-1 | bc-authoring-plan.md | Gate #24 PAGINATION COHERENCE appended (standing gate); no version field — narrative update | APPLIED |
| OBS-P31-2 | — | Covered by F-P31-01 (unbounded aggregate hazard resolved by PC7 limit declaration) | RECORD ONLY |
| OBS-P31-3 | — | BC-2.12.001 PC8 already conforms; allowed-zone confirmation | RECORD ONLY |

---

## Post-Fix Verification

| Check | Command | Result |
|-------|---------|--------|
| (1) All 5 list rows carry pagination in interface-definitions.md | `grep -n "limit" interface-definitions.md \| grep "GET"` | PASS — lines 168, 172, 180, 191, 215: all 5 rows carry `limit` default 10 max 100 + F-P31-01; no list GET row is missing pagination |
| (2) BC-2.12.004 PC7 has limit/offset/ordering | `grep -n "limit\|offset" BC-2.12.004.md` | PASS — lines 78-79: PC7 "limit (default 10, max 100; values > 100 silently clamped to 100)" + "offset (default 0)"; TV-002 line 138 updated |
| (2) BC-2.12.003 PC18 has limit/offset | `grep -n "limit\|offset" BC-2.12.003.md` | PASS — line 113: PC18 includes "limit (default 10, max 100; values > 100 clamped to 100) and offset (default 0); results ordered created_at descending (F-P31-01)" |
| (2) BC-2.12.001 PC8/PC17 match interface rows | `grep -n "limit\|offset" BC-2.12.001.md` | PASS — line 65: PC8 "limit (default 10, max 100), offset" ✓; lines 82-84: PC17 "limit default 10, max 100; values > 100 clamped to 100; offset default 0 (F-P31-01)" ✓ |
| (3) Pagination convention note present + gate #24 present | `grep -n "Canonical Pagination" interface-definitions.md` + `grep -n "PAGINATION COHERENCE\|gate #24" bc-authoring-plan.md` | PASS — interface-definitions.md line 145 ✓; bc-authoring-plan.md line 666 ✓ |
| (4) module-criticality note present + ferrochain-macros decision documented | `grep -n "Exclusion\|ferrochain-macros\|OBS-P31" module-criticality.md` | PASS — exclusion-criteria blockquote lines 49-62; ferrochain-macros inventory line 42; HIGH row line 82; decision text present |
| (5) Ordering canon documented for schedule-runs aggregate | `grep -n "created_at.*descend\|DESC" BC-2.12.004.md` | PASS — PC7 line ~77: "Results are ordered `created_at` **descending** (most-recent firing first)" — ordering canon declared |
