---
document_type: adversarial-review-pass
phase: 1d
pass: 65
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 1
low_count: 0
observations_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "→ future-date/partial-fix lens → BC-2.07.002 Form-B changelog v1.1 date (same-cycle incomplete fix residue from F-P64-02)"
timestamp: 2026-07-15T00:00:00Z
new_class: "same-cycle incomplete-fix propagation (Form-B BC set omitted from supplement date sweep)"
routing: "F-P65-01 → product-owner (BC-2.07.002 body changelog fix + gate #28 widening — fixed this burst)"
---

# Adversarial Review Pass 65 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (0 HIGH, 1 MED, 0 LOW). Counter reset: 0/3 consecutive clean. Novelty: MEDIUM.

---

## F-P65-01 [MED] — BC-2.07.002 Body `## Changelog` v1.1 Row Dated 2026-07-16 — Future-Dated / Same-Cycle Incomplete Fix

**Finding class:** Same-cycle incomplete-fix propagation — partial-fix residue at the same layer (S-7.01 partial-fix propagation).

**Status:** FIXED this burst (product-owner, BC-2.07.002 v1.1→v1.2; bc-authoring-plan.md v2.5→v2.6 gate #28 widening per OBS-P65-1).

**Scope:** `.factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md` body `## Changelog` table — v1.1 row date field.

**Finding:** `BC-2.07.002.md` body `## Changelog` table (line ~200 prior to fix) carries a v1.1 row with date `2026-07-16`. Today is 2026-07-15; 2026-07-16 is a future date and therefore impossible as a changelog entry date. The v1.1 row documents the F-P36-03 fix from ADV-P1D-PASS-36; `test-vectors.md` (also carrying a F-P36-03 changelog row) dates the same change to `2026-07-14`. The two files share a single root cause: the PASS-36 batch applied edits with an off-by-two date (`2026-07-16` instead of `2026-07-14`).

**Same-cycle incomplete fix:** The F-P64-02 sweep (pass-64 fix burst) identified the same root cause in `bc-authoring-plan.md` and `test-vectors.md` — both prd-supplement files carrying body `## Changelog` tables — and corrected their v1.1 rows from `2026-07-16` to `2026-07-14`. The sweep never enumerated the three BCs carrying Form-B (`## Changelog`) body tables: `BC-2.07.002`, `BC-2.08.011`, `BC-2.08.012` (the gate #28 Form-B set). Gate #28 scope at the time covered changelog-presence only, not date-validity. The BC-2.07.002 defect therefore propagated through pass-64's fix burst undetected.

**Sibling check — BC-2.08.011 and BC-2.08.012:** Both BCs carry v1.1 changelog rows dated `2026-07-14` (F-P42-01, ADV-P1D-PASS-42). Their dates are correct and consistent with the fix-pass date. **PASS** — no defect found.

**Cross-artifact consistency:** `bc-authoring-plan.md` v1.1 = `2026-07-14` (corrected in pass-64); `test-vectors.md` v1.1 = `2026-07-14` (corrected in pass-64). Corrected `BC-2.07.002` v1.1 = `2026-07-14` — all three PASS-36 changelog entries now agree.

**Severity justification (MED):** The date error is metadata-only with no behavioral impact on any BC postcondition, interface definition, error taxonomy, or story acceptance criterion. However, the finding reveals a systematic gap in the gate #28 date sweep: the Form-B BC set was never in scope. Severity is elevated from LOW to MED because the incomplete-fix pattern (F-P64-02 swept supplements but missed BCs at the same changelog layer) is a process gap rather than a simple typo — it requires gate widening, not just a date correction.

**Fix route:** Product-owner (prd-supplements and behavioral-contracts scope). Fix = (1) correct BC-2.07.002 v1.1 date `2026-07-16` → `2026-07-14`; (2) add BC-2.07.002 v1.2 row dated 2026-07-15 recording the F-P65-01 correction; (3) bump BC-2.07.002 frontmatter `version: "1.2"`; (4) widen gate #28 with date-validity sub-check (OBS-P65-1).

---

## OBS-P65-1 [process-gap] — Gate #28 Date Sweep Must Enumerate Form-B BC Set

**Observation:** The F-P64-02 fix burst (pass-64) swept prd-supplement body changelogs for date-monotonicity defects but did not enumerate the three Form-B BCs (`BC-2.07.002`, `BC-2.08.011`, `BC-2.08.012`). Gate #28 in bc-authoring-plan.md — which defines the Form-B set explicitly — covered changelog-presence but carried no date-validity sub-check. This allowed the BC-2.07.002 future-date to survive the targeted sweep.

**Process improvement:** Gate #28 must be widened to include a date-validity sub-check requiring that all changelog dates (Form A and Form B) satisfy: (a) date ≤ frontmatter `timestamp:`, (b) date ≤ current burst date, and (c) monotonic per the file's ordering convention. The Form-B set (BC-2.07.002/BC-2.08.011/BC-2.08.012) must be explicitly listed as required targets in any date sweep.

**Disposition:** FIXED — bc-authoring-plan.md v2.5→v2.6 adds the date-validity sub-check and Form-B enumeration requirement to gate #28.

---

## Sibling Checks

**Sibling check 1 — api-surface.md port line (post-F-P64-01 fix):** `api-surface.md` §Server Binding now states `7437` as the canonical default port, consistent with `interface-definitions.md` §Base URL and ferrochain-server.toml config schema. Architecture↔supplement default-config coherence: **PASS**.

**Sibling check 2 — Architecture supplement date sweep:** bc-authoring-plan.md v2.5 changelog (newest-at-top) and test-vectors.md v1.3 changelog verified monotonic — v2.5 (2026-07-15) > v2.4 (2026-07-15, same day ok) > v2.3 (2026-07-15) > v1.2 (2026-07-14) > v1.1 (2026-07-14) > v1.0 (2026-07-13). No future dates. **PASS**.

**Sibling check 3 — Ollama port (architecture sweep):** Only ferrochain-server default port `7437` and Ollama default `11434` appear in architecture and supplement files. No rogue port constants or contradictions. **PASS**.

---

## Mandatory Censuses

| Gate | Description | Verdict |
|------|-------------|---------|
| #12 | Lifecycle-arrow coherence — all Run state-machine lifecycle arrows in BC corpus use canonical forms; `interrupted` appears only as pausable/resumable, never terminal | PASS |
| #15 | Shared-type identifier census — zero live occurrences of CheckpointStore, RunConfig, BaseCheckpointSaver, AIMessage (Rust context), bare `\bCheckpointer\b` in non-architecture spec files | PASS |
| #17-A | URL-scheme consistency — zero flat `/runs` POST/GET/DELETE/PATCH paths outside thread-nested context; cross-thread aggregate `GET /runs?schedule_id=` is the sole exempt path | PASS |
| #19 | Retired-identifier residue — zero live occurrences of to_problem_detail, risk_tier, IngressSource, GuardrailAction, BudgetDecision, BudgetContext, node_delta, RunStarted/NodeStarted (L3 only) in non-architecture spec files | PASS |
| #23 | Streaming-event-name coherence — BC-2.06.001 StreamEvent enum is authoritative; downstream consumers use imperative names (RunStart, NodeStream); zero LangChain compat claims in architecture | PASS |
| #28 | Version-changelog integrity (presence check) — 45 BCs with version > "1.0": 42 Form-A (frontmatter `changelog:` key) + 3 Form-B (`## Changelog` body table: BC-2.07.002, BC-2.08.011, BC-2.08.012); union complete; zero uncovered. Date-value defect in BC-2.07.002 was outside prior gate scope (OBS-P65-1 widening applied this burst) | PASS (presence); F-P65-01 (date-validity; now fixed + gate widened) |

**Extra axes:**

**H1↔BC-INDEX title coherence (all 86 BCs):** Spot-checked BC-2.07.002 H1 ("Non-ASCII Boundary Parity with Python Reference Implementation (Emoji, CJK) — R8 Red Gate") against BC-INDEX. No drift introduced by the version bump and changelog correction. Full 86-BC sweep: **PASS**.

**VP 3-doc coherence (VP-INDEX ↔ verification-architecture ↔ verification-coverage-matrix):** No VP changes this burst. 3-doc coherence carries over from pass-64 confirmation: **PASS**.

**DI coverage (14/14):** No BC changes this burst affect DI enforcement mapping. Coverage census: 14/14 domain invariants enforced. **PASS**.

---

## Free Probes

**Enum-value-set coherence — `action_risk` wire values vs BC-2.05.006 `ActionRisk`:** `BC-2.05.006` defines `ActionRisk` as a typed enum used in the Run.interrupt sub-object. `interface-definitions.md` §Run.interrupt field `action_risk` carries the wire-visible string values. Checked: enum variants in BC body match wire-serialization values in interface-definitions.md; no null/fail-closed context confusion between the typed `ActionRisk` internal enum and the wire-level `action_risk` string field. **CLEAN** — no drift.

**Future-date / partial-fix lens:** Applied as the primary finding lens this pass, producing F-P65-01. All other BC changelogs in the Form-B set (BC-2.08.011, BC-2.08.012) verified clean. Prd-supplement changelogs (bc-authoring-plan v2.5, test-vectors v1.3) verified monotonic and date-valid. No additional future-date anomalies found beyond F-P65-01.

**Gate #28 date-validity coverage completeness check:** With OBS-P65-1 fix applied (bc-authoring-plan.md v2.6), the date-validity sub-check now enumerates all five changelog-bearing files in scope: bc-authoring-plan.md, test-vectors.md, BC-2.07.002.md, BC-2.08.011.md, BC-2.08.012.md. The census command in gate #28 v2.6 covers all five files. **Closed**.

---

## Novelty Assessment

**Classification: MEDIUM.**

**Basis:** The finding arises from same-cycle incomplete-fix residue — a structurally repeatable class. F-P64-02 (pass-64) identified the PASS-36 root cause and swept prd-supplement body changelogs, but the sweep did not carry over to the Form-B BC set at the same changelog layer. The lens is "future-date / partial-fix propagation" — previously exercised in pass-64 for supplements; extended one layer to BCs this pass. The structural gap (gate #28 date-validity scope omitting the Form-B set) is new but follows directly from OBS-P64's implicit process gap. The spec is near convergence: only metadata-layer defects remain. Novelty is MEDIUM rather than LOW because the Form-B enumeration gap is a genuine process omission requiring gate widening (not just a one-off typo fix), but LOW in isolation because the root cause was already identified in pass-64.

---

## Proposed Decisions Log Entry

**D18-P65-A:** Gate #28 date-validity widening accepted. All changelog dates in any BC file (Form A or Form B) must satisfy: (a) date ≤ frontmatter timestamp, (b) date ≤ current burst date, (c) monotonic per file ordering convention. The Form-B BC set (BC-2.07.002/BC-2.08.011/BC-2.08.012) is an explicit required target in every date sweep alongside prd-supplement body changelogs. Motivating instances: F-P64-02 (pass-64) + F-P65-01 (pass-65). Applied: bc-authoring-plan.md v2.5→v2.6 gate #28.
