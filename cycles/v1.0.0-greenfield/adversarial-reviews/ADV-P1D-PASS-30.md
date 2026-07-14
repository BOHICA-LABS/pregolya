---
document_type: adversarial-review-pass
phase: 1d
pass: 30
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 1
low_count: 0
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→6→1→6→1"
timestamp: 2026-07-14T00:00:00Z
new_class: "HTTP dual-authority categorical-map token divergence (TOOL)"
---

# Adversarial Review Pass 30 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (0 HIGH, 1 MED, 0 LOW) + 2 observations. Counter reset: 0/3 consecutive clean.

---

## F-P30-01 [MED] — `TOOL→N/A` Contradicts BC-2.14.002 PC3 Categorical Map (`Category::Tool → 422`)

**Finding class:** HTTP dual-authority categorical-map token divergence (TOOL) — new class this pass.

**Scope:**
- `interface-definitions.md` line ~233 (blanket omission note, OBS-P29-1): `TOOL→N/A`
- `BC-2.14.002.md` line ~71 (PC3 authoritative categorical map): `Category::Tool → 422`
- `VP-BC214002-02` line ~186 (all 12 categories mapped): TOOL maps to 422, none to N/A

**Finding:** The blanket omission note added in pass-29 (OBS-P29-1) listed `TOOL→N/A` as the categorical fallback for the `TOOL` error category. This directly contradicts BC-2.14.002 PC3, which is the single categorical authority: `Category::Tool → 422`. `N/A` is not a valid HTTP status code and was never the defined fallback. Any implementer reading the blanket note would conclude that TOOL-category errors have no HTTP surface — but BC-2.14.002 PC3, confirmed by VP-BC214002-02 (all 12 categories fully mapped), specifies 422. The divergence is a pass-29 propagation regression: the blanket note was written in the same burst that fixed the streaming taxonomy, but was not cross-checked against BC-2.14.002 PC3.

**Full 12-category token diff (blanket note vs BC-2.14.002 PC3):**

| Category | PC3 (authoritative) | Blanket note (pre-fix) | Status |
|----------|---------------------|------------------------|--------|
| VAL | 400 | 400/422 | **FIX** (422 requires per-endpoint override, not categorical fallback) |
| AUTH | 401 | *(absent)* | NOT LISTED (no E-AUTH codes in library families; omission acceptable) |
| POLICY | 403 | 403 | PASS |
| SECURITY | 403 | 403 | PASS |
| CONCURRENCY | 409 | *(absent)* | NOT LISTED (no E-CONCURRENCY codes in library families; omission acceptable) |
| RATE | 429 | *(absent)* | NOT LISTED (no E-RATE codes in library families; omission acceptable) |
| TENANCY | 409 | *(absent)* | NOT LISTED (no E-TENANCY codes in library families; omission acceptable) |
| TIMEOUT | 504 | *(absent)* | NOT LISTED (no E-TIMEOUT codes in library families; omission acceptable) |
| TRANSPORT | 502 | *(absent)* | **ADD** (E-MCP-* family explicitly labels TRANSPORT; categorical fallback missing) |
| DURABILITY | 500 | 500 | PASS |
| INTERNAL | 500 | *(absent)* | **ADD** (E-SBXD-* family explicitly labels INTERNAL; categorical fallback missing) |
| TOOL | 422 | N/A | **FIX** (primary finding) |

**Fix applied:**
1. `interface-definitions.md` (v2.0 → v2.1): Blanket omission note updated:
   - `TOOL→N/A` → `TOOL→422` (primary fix; BC-2.14.002 PC3 is the categorical authority)
   - `VAL→400/422` → `VAL→400` (categorical default; 422 requires per-endpoint override decision, not applicable to library-layer fallback)
   - Added `TRANSPORT→502` (E-MCP-* family labels TRANSPORT but fallback was absent from summary)
   - Added `INTERNAL→500` (E-SBXD-* family labels INTERNAL but fallback was absent from summary)
   - Updated note header to cite `F-P30-01, ADV-P1D-PASS-30`

---

## Gate #23 Streaming Census — FIRST FULL RUN (PASS, 11/11 variants)

> Gate #23 (STREAMING-EVENT-NAME COHERENCE) was added in pass-29. This is the first full run of the
> 11-variant census since the gate became active. All 11 canonical `StreamEvent` variants checked
> across primary authority (BC-2.06.001), architecture (ADR-006), supplement
> (interface-definitions.md), and resource BC (BC-2.12.007).

| # | Variant | BC-2.06.001 (authority) | ADR-006 enum | interface-definitions.md | BC-2.12.007 | Result |
|---|---------|------------------------|--------------|--------------------------|-------------|--------|
| 1 | RunStart | ✓ present | ✓ present | `run_start` wire token ✓ | ✓ referenced | PASS |
| 2 | RunStream | ✓ present | ✓ present | `run_stream` wire token ✓ | ✓ referenced | PASS |
| 3 | RunEnd | ✓ present | ✓ present | `run_end` wire token ✓ | ✓ referenced | PASS |
| 4 | StepStart | ✓ present | ✓ present | *(step events not enumerated individually — gate permits representative subset)* | ✓ referenced | PASS |
| 5 | StepEnd | ✓ present | ✓ present | *(see above)* | ✓ referenced | PASS |
| 6 | NodeStart | ✓ present | ✓ present | `node_start/stream/end` ✓ (F-P29-03) | ✓ present (F-P29-03) | PASS |
| 7 | NodeStream | ✓ present | ✓ present (F-P29-04) | `node_stream` ✓ (F-P29-03) | ✓ present (F-P29-03) | PASS |
| 8 | NodeEnd | ✓ present | ✓ present | `node_end` ✓ | ✓ present | PASS |
| 9 | ToolStart | ✓ present | ✓ present | `tool_start/stream/end` ✓ | ✓ referenced | PASS |
| 10 | ToolStream | ✓ present | ✓ present (F-P29-04) | `tool_stream` ✓ | ✓ referenced | PASS |
| 11 | ToolEnd | ✓ present | ✓ present | `tool_end` ✓ | ✓ referenced | PASS |

**Census result: 11/11 PASS.** D13 wire posture: ADR-006 rev-1 explicitly states ferrochain-native format per D13; zero astream_events compat claims in architecture/ (confirmed P29, no edits to ADR-006 this burst).

**Scope note (OBS-P30-2 — see Observations):** `events.md` does not list `run_stream`, `step_start`, or `step_end` labels. This is intentional and correct — `events.md` documents domain processing-stages, not the wire-event taxonomy. BC-2.06.001 is the single wire-taxonomy authority. Gate #23 step 1 permits representative subsets in L2. Anti-fix note added to gate #23 text in bc-authoring-plan.md.

---

## Sibling Reverse-Anchor Checks

No BCs added or retired this burst. No E-codes minted. BC count unchanged: P0 48 + P1 30 + P2 8 = 86 total.

**(a) BC and artifact version bumps consistent with changelog entries:**
- `interface-definitions.md`: 2.0 → 2.1 ✓ (F-P30-01 blanket note correction)
- `entities-server.md`: 1.1 → 1.2 ✓ (OBS-P30-1 Timestamp UTC canon)
- `bc-authoring-plan.md`: anti-fix note appended to gate #23 ✓ (OBS-P30-2; no version field — narrative update)

**(b) HTTP dual-authority categorical-map census (new this burst):**
`grep -n "TOOL→" interface-definitions.md` → line ~234: `TOOL→422` (no `N/A`). PASS after F-P30-01 fix.

**(c) BC-2.14.002 PC3 12-category map unchanged:**
The fix consumed PC3 as the authoritative source; the BC itself was not modified. PASS.

**(d) VP-BC214002-02 mapping coverage:**
VP asserts all 12 categories map to defined HTTP codes — TOOL→422 is listed. No VP modification required. PASS.

---

## Rotated Census Results (4 Selected)

| Census | Command | Result |
|--------|---------|--------|
| Capability-tier census (P0 gates) | `grep -rn "P0\b" .factory/specs/behavioral-contracts/ \| grep -c "priority: P0"` | PASS — 48 P0 BCs stable; no new BCs this burst |
| Wire-object census (StreamEvent downstream) | `grep -rn "node_delta" .factory/specs/ \| grep -v "bc-authoring-plan\|~~\|changelog\|retired.*list\|Census"` | PASS — zero live hits (drain carried from F-P29-03) |
| HTTP dual-authority census — blanket note category map | `grep -n "TOOL→" interface-definitions.md` | FAIL pre-fix (TOOL→N/A) → **F-P30-01**; PASS post-fix (TOOL→422) |
| E-code↔variant census (BC-2.14.002 full map) | Full 12-category diff table above | PASS post-fix — all 12 categories match PC3 (4 tokens corrected/added: TOOL, VAL, TRANSPORT, INTERNAL) |

---

## Observations

### OBS-P30-1 (applied) — Timestamp UTC Canonicalization Undeclared in entities-server.md

**Finding:** `entities-server.md` uses `Timestamp` in every entity's field list (Thread `created_at`/`updated_at`, Assistant `created_at`, Run `created_at`/`updated_at`/`completed_at`, CronSchedule `last_fired_at`, ProvenanceTag `timestamp`, EvidenceEntry `timestamp`) but never declared the UTC normalization canon. The RFC 3339 date-time type carries an offset; the error taxonomy code E-GRAPH-014 uses `<deadline_utc>` in its message format, implying UTC. Without an explicit declaration, implementers might accept non-UTC offsets and store them as-is, causing comparison failures between timestamps stored with different offsets.

**Canon decision:** All Timestamp values are RFC 3339 date-time normalized to UTC (offset +00:00 / Z) at construction; wire serialization preserves UTC form.

**DECISION-friendly canon list entry:** `Timestamp = RFC 3339 UTC` — all Timestamp values must be normalized to UTC (+00:00 / Z) at construction before storage or wire serialization.

**Fix applied:** `entities-server.md` (v1.1 → v1.2): Canonical Timestamp semantics blockquote added under `## Server Domain` header, citing OBS-P30-1, before the first entity (`Thread`) that uses Timestamp. Changelog entry added.

### OBS-P30-2 (record only, no edit to entities/BCs) — Gate #23 Scope: events.md Legitimately Omits Wire-Taxonomy Labels

**Finding:** During the gate #23 first full run, an observation arose: `events.md` does not include `run_stream`, `step_start`, `step_end`, or other wire-token labels. These are in BC-2.06.001's canonical `StreamEvent` enum. One could incorrectly read gate #23 step 1 ("note the domain event names and any stream-event labels") as requiring these labels to be present in events.md.

**Decision:** No fix to `events.md`. The omission is intentional and correct. `events.md` documents domain processing-stages using DDD past-tense PascalCase (`RunStarted`, `InterruptRaised`, etc.) — not the exhaustive wire-taxonomy. BC-2.06.001 is the single wire-taxonomy source of truth. Gate #23 step 1 explicitly states "representative subsets" are permitted in L2.

**Anti-fix note added:** `bc-authoring-plan.md` gate #23 text: durable anti-fix note appended stating that future passes MUST NOT add wire-taxonomy labels (`run_stream`, `step_start`, `step_end`) to `events.md`. Any such "fix" would be incorrect and would violate the single-authority principle.

---

## NEW CLASS: HTTP Dual-Authority Categorical-Map Token Divergence (TOOL)

**Definition:** A supplement or BC uses a categorical HTTP fallback mapping for an error category that diverges from BC-2.14.002 PC3 (the single categorical authority). The divergence can be a wrong code (`TOOL→N/A` vs `TOOL→422`), a wrong range (`VAL→400/422` blending categorical default with per-endpoint overrides), or a missing mapping for a category that appears in error-family labels within the same artifact.

**Characteristics:**
- Only occurs in artifacts that enumerate categorical fallbacks (interface-definitions.md blanket notes, error-taxonomy.md category tables)
- BC-2.14.002 PC3 is the single source of truth; all downstream categorical mappings must match it token-by-token
- Missing mappings are also a violation when the category appears in the same artifact's family labels (TRANSPORT and INTERNAL were in E-MCP-*/E-SBXD-* family descriptions but absent from the fallback summary)
- Per-endpoint overrides (e.g., VAL→422 for specific codes) are distinct from categorical defaults; categorical fallbacks must not blend them

**Drain status:** All live occurrences drained this burst (1 fix + 3 corrections in the same note). No standing gate added — existing gate #22 covers RetryHint categorical overrides; BC-2.14.002 PC3 is the canonical reference. Add a spot-check to each burst that edits blanket omission notes: diff the summary tokens against PC3.

---

## BC↔Taxonomy Category Census — PASS (73 Active Codes, Zero New Codes, Zero Mismatches)

> Census scope: all active (non-retired) error codes in error-taxonomy.md vs their BC anchor's category declaration. No new E-codes minted this burst. Retired codes excluded.

Census result: **73 active codes, ZERO category mismatches.** Pass-29 census table carried forward; no changes to error-code categories this pass.

---

## Novelty Assessment

**Classification: MEDIUM.**

**Trajectory context:** Pass counts: ...→6 (P27)→1 (P28)→6 (P29)→1 (P30). After P29's rebound to 6 (streaming taxonomy class), P30 returns to 1 — matching P28's minimum. The single finding is a direct propagation regression from the P29 burst: the blanket note was written as an OBS-P29-1 fix but was not validated against BC-2.14.002 PC3 before the burst closed.

**New class assessment:** The HTTP dual-authority categorical-map token divergence class is new but MEDIUM severity because:
- Only one artifact was affected (the blanket omission note added in P29)
- The divergence was `N/A` (an obviously invalid HTTP code) — detection is straightforward
- The root cause is a missing cross-check at blanket-note authoring time, not a systemic architectural gap
- No BC, VP, or error-taxonomy entry was affected; the categorical map in BC-2.14.002 PC3 remained authoritative throughout

**Recovery signal:** With F-P30-01 fixed and TRANSPORT/INTERNAL/VAL corrected in the same edit, the categorical-map axis is now fully consistent. The new-class pattern (one regression from the prior burst's own OBS fix) is an expected low-frequency recurrence at this stage. Gate #23 first full run returned 11/11 PASS, confirming the streaming taxonomy axis is closed.

**Adversary expectation:** CLEAN with LOW novelty if next pass finds no new categorical divergences and no new propagation regressions from this burst's Timestamp canon addition.

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P30-01 | interface-definitions.md | Blanket omission note: TOOL→N/A→TOOL→422; VAL→400/422→VAL→400; added TRANSPORT→502 and INTERNAL→500; header updated to cite F-P30-01; changelog; v2.0→2.1 | APPLIED |
| OBS-P30-1 | entities-server.md | Timestamp UTC canon blockquote added under ## Server Domain; changelog; v1.1→1.2 | APPLIED |
| OBS-P30-2 | bc-authoring-plan.md | Anti-fix note appended to gate #23 text — events.md legitimately omits wire-taxonomy labels; MUST NOT add them | APPLIED |

---

## Post-Fix Verification

| Check | Command | Result |
|-------|---------|--------|
| (1) TOOL→ in interface-definitions.md = 422, no N/A | `grep -n "TOOL→" interface-definitions.md` | PASS — line ~234: `TOOL→422`; no `N/A` present |
| (2) Full 12-category token diff (blanket note vs PC3) | diff table above | PASS — TOOL→422 ✓, TRANSPORT→502 ✓ (added), SECURITY→403 ✓, POLICY→403 ✓, DURABILITY→500 ✓, INTERNAL→500 ✓ (added), VAL→400 ✓ (corrected from 400/422); all match BC-2.14.002 PC3 |
| (3) RFC 3339 UTC canon in entities-server.md | `grep -n "RFC 3339" entities-server.md` | PASS — line ~31: `Canonical Timestamp semantics (OBS-P30-1): All Timestamp values are RFC 3339 date-time normalized to UTC (offset +00:00 / Z) at construction; wire serialization preserves UTC form.` |
| (4) Gate #23 anti-fix note in bc-authoring-plan.md | `grep -n "Anti-fix\|OBS-P30-2\|MUST NOT.*fix.*events" bc-authoring-plan.md` | PASS — line ~662: anti-fix note present with DURABLE flag |
