---
document_type: adversarial-review-pass
phase: 1d
pass: 33
verdict: NOT CLEAN
findings_count: 2
high_count: 0
med_count: 2
low_count: 0
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→1→1→4→2"
timestamp: 2026-07-14T00:00:00Z
new_class: "none (existing gate #24 class + config-precedence content gap)"
---

# Adversarial Review Pass 33 — Phase 1d

**Verdict: NOT CLEAN** — 2 findings (0 HIGH, 2 MED, 0 LOW) + 2 observations. Counter reset: 0/3 consecutive clean.

---

## F-P33-01 [MED] — GET /assistants List Has No Governing Postcondition in BC-2.12.002

**Finding class:** Pagination coherence gap (gate #24 — list-assistants endpoint anchored to BC-2.12.002 in interface-definitions.md but BC has no list-collection postcondition block).

**Scope:** `.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` (Assistant Resource CRUD); `.factory/specs/prd-supplements/interface-definitions.md` §Assistants row line ~181.

**Finding:** `interface-definitions.md` line 181 declares `GET /assistants` with canonical pagination (`limit` default 10, max 100; `offset`; `created_at` DESC) and cites BC-2.12.002 as the anchor BC. However, BC-2.12.002 contained no postcondition block for the list-collection operation. The BC covered Create (PC1-PC6), Read (PC7-PC8), Update/PATCH (PC9-PC12), Delete (PC13-PC16), and Version Operations (PC17-PC20) but had no List Assistants section. Gate #24 PAGINATION COHERENCE (added ADV-P1D-PASS-31) requires that each list-endpoint row's anchor BC must have a matching postcondition declaring the same limit/offset/ordering semantics. The drift meant BC-2.12.002 was anchoring a pagination guarantee it did not actually specify.

**Severity justification (MED):** Implementers reading BC-2.12.002 as their specification source would find no pagination contract for the list endpoint, potentially implementing unbounded queries or wrong orderings. The interface-definitions.md row gave the correct parameters but those are a supplement, not the authoritative BC. This is a spec-completeness gap, not a missing-endpoint gap — the endpoint itself was declared; the BC-level authority for its pagination behavior was absent.

**Fix applied:**
1. `BC-2.12.002.md` (v1.1 → v1.2): Added `### List Assistants (GET /assistants)` section with PC21-PC23:
   - PC21: Accepts query params `limit` (default 10, max 100; values > 100 silently clamped to 100), `offset` (default 0).
   - PC22: Returns `{ assistants: [Assistant], total_count: u64 }` for all stored Assistants.
   - PC23: Results ordered `created_at` descending (canonical; F-P31-01). Out-of-range clamp canon per BC-2.12.001 PC8 (F-P31-01, ADV-P1D-PASS-31). Interface anchor: interface-definitions.md §Assistants `GET /assistants` row (F-P33-01).
2. `interface-definitions.md` (v2.3 → v2.4): §Canonical Pagination Convention BC anchors line updated — added `BC-2.12.002 PC21-PC23 (assistants list)` to the anchor list.
3. `bc-authoring-plan.md`: Gate #24 census commands updated — added BC-2.12.002 grep step asserting PC21-PC23 (list-assistants) and PC20 (/versions pagination) both present (closes OBS-P33-1 process-gap).

---

## F-P33-02 [MED] — Run-vs-Assistant Config/Metadata/Context Merge Precedence Unspecified

**Finding class:** Config-precedence content gap — run creation accepts override fields but no BC declared the merge rule for how run-level values interact with the Assistant's stored values.

**Scope:** `.factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md` (Create Run); `.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` §Description (cross-ref gap).

**Finding:** BC-2.12.002 §Description stated "the Run inherits the Assistant's config" (line 36-38). BC-2.12.003 PC1 declared that the Create-Run body accepts an optional `config?: RunnableConfig`, `metadata?: Map<String, Value>`. No BC or supplement document stated what happens when the run-level fields are present alongside the Assistant's stored config — specifically:
- Which config wins on a per-key collision?
- Is the merge shallow (per-top-level-key replacement) or deep (leaf-key merge)?
- Does the same rule apply uniformly to all three fields (`config`, `metadata`, `context`)?

Without a canon, two implementers working independently would likely produce different merge strategies. The PATCH sparse-update posture in BC-2.12.002 PC9 (only provided fields updated) and BC-2.01.003 PC6 (metadata "accumulates" down the run tree) both implied merging, but no source stated leaf-level deep-merge explicitly or confirmed the run-wins rule.

**Severity justification (MED):** Config merge is a cross-cutting concern: operators rely on per-run config overrides to customize behavior (e.g., override `model` for a single run without changing the Assistant's stored config). An incorrect shallow-merge would silently drop nested keys from the Assistant's config whenever a run supplies a partial override; a reversed precedence (assistant wins) would make per-run overrides impossible. Either failure mode is silent at the API surface.

**Upstream check result:** No contradicting merge semantics found in either:
- `BC-2.01.003` PC6: states metadata "accumulates" down the run tree (consistent with merge; run-supplied values win). Architecture anchor: `ferrochain-core/src/runnables/config.rs — merge_configs (to be created)`.
- `semport/platform/behavioral-intent.md` §2.3 Runs: Runs large shared param vocabulary documented but no explicit merge rule for run-over-assistant config. No LangChain Python source for a different merge convention found.

**Decision:** Leaf-level deep-merge adopted as spec canon. Rule: run-supplied `config`, `metadata`, and `context` are deep-merged over the Assistant's stored values at the leaf-key level, with run-level keys winning on any collision. Fields absent from the run request body retain the Assistant's stored values unchanged. Applied independently to each of the three fields.

**Fix applied:**
1. `BC-2.12.003.md` (v1.1 → v1.2): Added **Run-Config Merge Precedence** bullet to the Invariants section declaring the full precedence chain, the leaf-level deep-merge rule, and the upstream-check result.
2. `BC-2.12.002.md` (v1.1 → v1.2, same bump as F-P33-01): §Description updated — "the Run inherits the Assistant's config" sentence extended with cross-reference to BC-2.12.003 §Run-Config Merge Precedence Invariant.
3. `interface-definitions.md` (v2.3 → v2.4, same bump as F-P33-01): `POST /threads/{thread_id}/runs` row description extended with one-line precedence note: "run-supplied `config`/`metadata`/`context` deep-merge over the Assistant's stored values, run wins at leaf key (BC-2.12.003 §Run-Config Merge Precedence Invariant, F-P33-02)".

---

## Gate #25 FULL Arithmetic Census — FIRST FULL RUN (All Counts Reconcile)

Gate #25 (SUMMARY-ARITHMETIC + CRITICALITY-SIBLING COHERENCE) was added in ADV-P1D-PASS-32. This is the first full run of the artifact-count arithmetic census across all VSDD planning documents.

| Artifact | Source-of-Truth | Count Method | Result |
|----------|----------------|--------------|--------|
| BC Index entries (total) | `BC-INDEX.md` row count | `grep -c "| BC-" BC-INDEX.md` | **86** (48 P0 + 30 P1 + 8 P2) |
| BC physical files | `find .factory/specs/behavioral-contracts/ -name "BC-*.md"` | file count | **86** |
| BC-authoring-plan registry | `bc-authoring-plan.md` frontmatter `total_bcs` | direct read | **86** |
| Index = Files = Registry | triple reconciliation | 86 = 86 = 86 | **PASS — zero drift** |
| CAP P0 | capabilities-p0.md + bc-authoring-plan subsystem table | SS.01 (CAP-001/002), SS.02, SS.03, SS.04, SS.05, SS.06, SS.07, SS.10, SS.11, SS.14 = 11 CAPs | **11** |
| CAP P1 | capabilities-p1-p2.md + bc-authoring-plan subsystem table | SS.08 (CAP-009/011), SS.09 (CAP-010), SS.12 (CAP-014), SS.13 (CAP-015) = 5 CAPs | **5** |
| CAP P2 | capabilities-p1-p2.md + bc-authoring-plan subsystem table | SS.15 (CAP-017), SS.16 (CAP-018), SS.17 (CAP-019) = 3 CAPs | **3** |
| CAP total | 11+5+3 | arithmetic | **19** (CAP-001–CAP-019) — PASS |
| VP files | `find .factory/specs/verification-properties/ -name "VP-*.md"` | file count | **5** (VP-001 through VP-005; VP-INDEX.md not counted) |
| Workspace crates | ADR-007 canonical roster | direct read | **18** (established ADV-P1D-PASS-3 F-P3-04; expanded to 18 including sandbox/memory/macros/-sdk) |
| BC batches | `bc-authoring-plan.md` frontmatter `total_batches` | direct read | **13** |
| Batch sum → total BCs | 13 batches × declared batch sizes | arithmetic reconciliation | Sum = **86** — PASS |

**Census verdict: ALL COUNTS RECONCILE.** No orphan BCs, no missing CAPs, no VP drift, crate roster stable at 18.

---

## Pagination Gate #24 Sibling-Check: GET /assistants List FAIL → F-P33-01

| Census | Command | Pre-fix Result | Post-fix Result |
|--------|---------|---------------|----------------|
| Gate #24: GET /assistants row carries pagination | `grep "assistants" interface-definitions.md \| grep "GET"` | **Already PASS** — interface-definitions.md row carried pagination since F-P31-01 | PASS (unchanged) |
| Gate #24: BC-2.12.002 has matching list-assistants PC | `grep -n "limit\|offset" BC-2.12.002.md` | **FAIL** — only PC20 (/versions) present; no list-collection PC for GET /assistants | PASS — PC21-PC23 added with limit/offset/clamped/created_at DESC |
| Gate #24: BC anchors list includes BC-2.12.002 for assistants list | `grep "BC-2.12.002.*assistants\|assistants.*BC-2.12.002" interface-definitions.md` | **FAIL** — §Canonical Pagination Convention anchors list omitted BC-2.12.002 | PASS — BC-2.12.002 PC21-PC23 (assistants list) added to anchor list |

---

## Rotated Census Results (4 Selected)

| Census | Command | Result |
|--------|---------|--------|
| Streaming: no astream_events compat claims in live spec | `grep -rn "astream_events" .factory/specs/architecture/ \| grep -v "native\|D13\|NOT\|no.*compat"` | **PASS** — zero live compat claims (unchanged from prior passes; anti-fix note OBS-P30-2 DURABLE) |
| Dual-authority: both criticality docs agree post-pass-32 | `grep "ferrochain-macros\|Proc-macro" both criticality docs \| grep "HIGH"` | **PASS** — arch-view: HIGH ✓; prd-supplements: HIGH ✓; no criticality edit this pass (gate #25 Part B N/A) |
| Pagination: BC-2.12.002 list-assistants PC present | `grep -n "limit\|offset" BC-2.12.002.md` | **FAIL pre-fix → PASS post-fix** — PC21-PC23 added (F-P33-01); PC20 /versions pagination retained; interface-definitions.md anchors updated |
| Category spot: BC↔taxonomy error-code categories | Zero new E-codes minted this burst | **PASS** — 73 active codes unchanged; no new codes; no category drift |

---

## Observations

### OBS-P33-1 [process-gap] — Gate #24 Census Commands Missing BC-2.12.002 Grep

**Finding:** Gate #24 PAGINATION COHERENCE (bc-authoring-plan.md line ~685) had census commands for BC-2.12.004 (PC7), BC-2.12.003 (PC18), and BC-2.12.001 (PC8/PC17) but no command for BC-2.12.002. The omission meant gate #24's step-4 census could pass even with BC-2.12.002 lacking a list-assistants pagination PC, which is precisely what happened — the BC had PC20 for /versions but no PC for GET /assistants, and the census did not catch it because no BC-2.12.002 grep was in the gate.

**Fix applied:** Covered by F-P33-01(c) — gate #24 census commands extended with BC-2.12.002 grep step asserting both PC21-PC23 (list-assistants) and PC20 (/versions). Tag: [process-gap].

### OBS-P33-2 [process-gap] — No Endpoint-Count Invariant in §17-B

**Finding:** Gate #17-B (HTTP endpoint census, bc-authoring-plan.md) tracked endpoint path × citing-docs × scheme-verdict but had no pinned total count. Without a total count, a burst adding or removing an endpoint could slip through by updating the table rows without anyone noticing the total changed. The interface-definitions.md defines 26 ferrochain-server HTTP endpoints (confirmed by recount: Threads 7 + Assistants 7 + Runs 7 + Cron 4 + aggregate 1 = 26). This count was not pinned anywhere as a hard invariant.

**Fix applied (this burst):** Endpoint-count invariant added to bc-authoring-plan.md §17-B: "Total ferrochain-server HTTP endpoints = 26 (Threads 7 + Assistants 7 + Runs 7 + Cron 4 + aggregate 1)." Recount confirmed from interface-definitions.md §Threads / §Assistants / §Runs / §Cron Schedules tables = 26 (matches stated count exactly; no discrepancy). Tag: [process-gap].

**Endpoint recount (this burst):**

| Group | Endpoints | Count |
|-------|-----------|-------|
| Threads | POST /threads, GET /threads/{id}, GET /threads, DELETE /threads/{id}, GET /threads/{id}/state, POST /threads/{id}/state, GET /threads/{id}/history | 7 |
| Assistants | POST /assistants, GET /assistants/{id}, GET /assistants, PATCH /assistants/{id}, DELETE /assistants/{id}, GET /assistants/{id}/versions, POST /assistants/{id}/set_latest | 7 |
| Runs | POST /threads/{id}/runs, GET /threads/{id}/runs, GET /threads/{id}/runs/{run_id}, GET /threads/{id}/runs/{run_id}/stream, POST /threads/{id}/runs/{run_id}/resume, POST /threads/{id}/runs/{run_id}/cancel, DELETE /threads/{id}/runs/{run_id} | 7 |
| Cron | POST /schedules, GET /schedules/{cron_id}, PATCH /schedules/{cron_id}, DELETE /schedules/{cron_id} | 4 |
| Aggregate | GET /runs?schedule_id={cron_id} | 1 |
| **TOTAL** | — | **26** |

---

## Novelty Assessment

**Classification: MEDIUM-LOW.**

**Trajectory context:** Pass counts: ...→1 (P30)→1 (P31)→4 (P32)→2 (P33). The rebound at pass-32 (4 findings, new class) was driven by a new arithmetic audit axis. Pass-33 returns to 2 findings — both from existing classes. No trajectory break; the spec is highly converged.

**New class assessment:** No new finding class this pass.
- F-P33-01 is gate #24 class (pagination/query-param coherence) — first introduced ADV-P1D-PASS-31.
- F-P33-02 is a config-precedence content gap — related to BC completeness (existing correctness class), not a structurally new pattern.

**Recovery signal:** Both gaps were narrow and local (one BC missing a list-collection PC; one BC missing a merge-precedence invariant). Fix surface was 4 files, all in the SS-12 Assistants/Runs cluster. No cross-subsystem propagation required. Gate #24 census now covers all 5 list-endpoint BCs (BC-2.12.001 PC8/PC17, BC-2.12.002 PC20/PC21-PC23, BC-2.12.003 PC18, BC-2.12.004 PC7). Gate #17-B now has a pinned endpoint count. The spec is in a highly converged state.

---

## Sibling Reverse-Anchor Checks

No BCs added or retired this burst. No E-codes minted. BC count unchanged: P0 48 + P1 30 + P2 8 = 86 total.

**(a) BC and artifact version bumps consistent with changelog entries:**
- `BC-2.12.002.md`: 1.1 → 1.2 ✓ (F-P33-01 PC21-PC23 + F-P33-02 description cross-ref)
- `BC-2.12.003.md`: 1.1 → 1.2 ✓ (F-P33-02 Run-Config Merge Precedence invariant)
- `prd-supplements/interface-definitions.md`: 2.3 → 2.4 ✓ (F-P33-01 BC anchors + F-P33-02 run-create row note)
- `bc-authoring-plan.md`: gate #24 BC-2.12.002 grep step added ✓ (F-P33-01 OBS-P33-1); endpoint-count invariant added to §17-B ✓ (OBS-P33-2) — no version field

**(b) BC-2.12.002 PC21-PC23 pagination matches interface-definitions.md GET /assistants row:**
`grep -n "limit\|offset" BC-2.12.002.md` → PC21 (limit default 10/max 100/clamped), PC22 (response shape {assistants, total_count}), PC23 (created_at DESC/F-P31-01). Interface row: "canonical pagination (?limit=N default 10 max 100, ?offset=N; created_at DESC) — F-P31-01". PASS — BC postconditions match interface row exactly.

---

## BC↔Taxonomy Category Census — PASS (73 Active Codes, Zero New Codes, Zero Mismatches)

> Census scope: all active (non-retired) error codes in error-taxonomy.md vs their BC anchor's category declaration. No new E-codes minted this burst. Retired codes excluded.

Census result: **73 active codes, ZERO category mismatches.** Pass-32 census table carried forward; no changes to error-code categories this pass.

---

## Decisions (Merge Semantics + Upstream-Check Result)

**Run-Config Merge Semantics (F-P33-02):**
- **Adopted:** Leaf-level deep-merge, run wins on collision.
- **Upstream-check result:** BC-2.01.003 PC6 — metadata "accumulates" (consistent with merge; no conflict). Semport behavioral-intent §2.3 — no explicit merge rule; no LangChain Python source establishes a different convention (e.g., shallow per-top-level-key). No contradiction found. Leaf-level deep-merge is the natural extension of the PATCH sparse-update posture in BC-2.12.002 PC9.
- **Applies to:** `config`, `metadata`, `context` independently. Fields absent from run body retain Assistant's stored values.
- **Effective-config semantics:** Merge is applied at run creation time; the merged effective config is what the graph executor receives.

**Endpoint Recount (OBS-P33-2):**
- Recount: Threads 7 + Assistants 7 + Runs 7 + Cron 4 + aggregate 1 = **26**.
- Matches the stated count in the task (26). No discrepancy.

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P33-01 | `.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` | PC21-PC23 added (List Assistants section); description cross-ref to BC-2.12.003 merge invariant; v1.1→1.2; changelog entry | APPLIED |
| F-P33-01 | `.factory/specs/prd-supplements/interface-definitions.md` | BC-2.12.002 PC21-PC23 added to §Canonical Pagination Convention BC anchors; run-create row note (F-P33-02); v2.3→2.4; changelog entry | APPLIED |
| F-P33-01 | `.factory/specs/prd-supplements/bc-authoring-plan.md` | Gate #24 census commands: BC-2.12.002 grep step added (PC21-PC23 + PC20 assertions); OBS-P33-1 process-gap closed | APPLIED |
| F-P33-02 | `.factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md` | Run-Config Merge Precedence invariant added with full leaf-level deep-merge rule + upstream-check result; v1.1→1.2; changelog entry | APPLIED |
| F-P33-02 | `.factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` | Description cross-ref to BC-2.12.003 merge invariant added; covered in same v1.1→1.2 bump as F-P33-01 | APPLIED |
| F-P33-02 | `.factory/specs/prd-supplements/interface-definitions.md` | POST /threads/{id}/runs row: one-line config-merge precedence note added; covered in same v2.3→2.4 bump as F-P33-01 | APPLIED |
| OBS-P33-1 | `.factory/specs/prd-supplements/bc-authoring-plan.md` | Covered by F-P33-01(c) — gate #24 BC-2.12.002 grep added | APPLIED |
| OBS-P33-2 | `.factory/specs/prd-supplements/bc-authoring-plan.md` | Endpoint-count invariant (26 = Threads 7 + Assistants 7 + Runs 7 + Cron 4 + aggregate 1) added to §17-B; recount confirmed = 26; no discrepancy | APPLIED |

---

## Post-Fix Verification

| Check | Command | Result |
|-------|---------|--------|
| (1) BC-2.12.002 list-assistants PC present with shape/pagination/ordering | `grep -n "limit\|offset" BC-2.12.002.md` | PASS — PC21 (limit/offset/clamped), PC22 (response shape), PC23 (created_at DESC/F-P31-01) all present |
| (1) Interface anchor list updated for BC-2.12.002 | `grep "BC-2.12.002.*PC21\|assistants list" interface-definitions.md` | PASS — "BC-2.12.002 PC21-PC23 (assistants list)" present in §Canonical Pagination Convention anchors |
| (2) Gate #24 census commands include BC-2.12.002 greps | `grep -n "BC-2.12.002.*grep\|grep.*BC-2.12.002" bc-authoring-plan.md` | PASS — BC-2.12.002 grep step present asserting PC21-PC23 and PC20 |
| (3) BC-2.12.003 precedence invariant present | `grep -n "Merge Precedence\|deep-merged\|leaf-key" BC-2.12.003.md` | PASS — Run-Config Merge Precedence invariant at Invariants section; leaf-key merge, upstream-check result, cross-ref all present |
| (3) BC-2.12.002 cross-ref present | `grep -n "Merge Precedence\|deep-merge\|leaf level" BC-2.12.002.md` | PASS — description cross-ref sentence cites BC-2.12.003 §Run-Config Merge Precedence Invariant |
| (4) Endpoint count pinned in §17-B | `grep -n "26\|Threads 7\|OBS-P33-2" bc-authoring-plan.md` | PASS — "Total ferrochain-server HTTP endpoints = 26 (Threads 7 + Assistants 7 + Runs 7 + Cron 4 + aggregate 1)" at §17-B |
| (4) Endpoint recount matches count | Manual recount from interface-definitions.md tables | PASS — recount = 26, matches stated count, no discrepancy |
| (5) Gate #24 six-surface check — Surface 1: GET /threads list | `grep "limit" interface-definitions.md \| grep "GET.*threads[^/]"` | PASS — "canonical pagination (?limit=N default 10 max 100, ?offset=N; created_at DESC) — F-P31-01" |
| (5) Gate #24 six-surface check — Surface 2: GET /threads/{id}/history | `grep "limit" interface-definitions.md \| grep "history"` | PASS — "canonical pagination (?limit=N default 10 max 100, ?offset=N; values > 100 clamped) — F-P31-01" |
| (5) Gate #24 six-surface check — Surface 3: GET /assistants list | `grep "limit" interface-definitions.md \| grep "GET.*assistants[^/]"` | PASS — "canonical pagination (?limit=N default 10 max 100, ?offset=N; created_at DESC) — F-P31-01"; BC-2.12.002 PC21-PC23 anchor present |
| (5) Gate #24 six-surface check — Surface 4: GET /assistants/{id}/versions | `grep "limit" interface-definitions.md \| grep "versions"` | PASS — canonical pagination + version ASC exemption declared; BC-2.12.002 PC20 anchor |
| (5) Gate #24 six-surface check — Surface 5: GET /threads/{id}/runs | `grep "limit" interface-definitions.md \| grep "GET.*runs[^/]"` | PASS — canonical pagination + status filter + BC-2.12.003 PC18 anchor |
| (5) Gate #24 six-surface check — Surface 6: GET /runs?schedule_id | `grep "limit" interface-definitions.md \| grep "schedule_id"` | PASS — canonical pagination + created_at DESC + BC-2.12.004 PC7 anchor |
