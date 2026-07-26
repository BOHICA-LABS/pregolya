---
document_type: adversarial-review-pass
cycle: v1.0.0-greenfield
phase: 1d
pass: 172a
verdict: NOT CLEAN
findings_count: 19
crit_count: 0
high_count: 4
med_count: 10
low_count: 5
obs_count: 0
consecutive_clean: 0
required_clean: 3
trajectory: "...→20→19→19"
timestamp: 2026-07-25T18:00:00Z
frozen_head: "cafa10de3cec85e9e1f2dcb5dfd38e079051a3a8"
scope: "narrow — axis 1 only: governance-gate registry (bc-authoring-plan.md v2.53, 36 gates as executable content); axes 2-4 NOT RUN"
novelty: HIGH
fix_burst: 274
---

# Adversarial Review Pass P1D-172a

## Pass Metadata

- **Date:** 2026-07-25
- **Adversary:** fresh-context on frozen HEAD (burst-273 commit, SHA `cafa10de3cec85e9e1f2dcb5dfd38e079051a3a8`)
- **Streak:** 0/3 (remains 0/3 — HIGH findings present)
- **CLEAN (strict):** no — 19 items present (0C/4H/10M/5L)
- **CLEAN (PR-merge):** no — 4 HIGH findings present
- **Realized scope:** NARROW — axis 1 only (governance-gate registry as executable content). Axes 2, 3, 4 NOT RUN; carried forward.
- **Convergence-integrity rule:** the 3-CLEAN streak (BC-5.39.001) requires FULL-PERIMETER passes only. A narrowed sub-pass may never advance the streak.
- **Novelty:** HIGH — sibling-sweep failures (TD-VSDD-060) at structural/gate level; cascade-fix importing wrong count; exemption list member failing its own stated prerequisite
- **Fix burst:** 274 (PENDING)

## Summary

Sub-pass P1D-172a on frozen HEAD burst-273. Scope: axis 1 only — `specs/prd-supplements/bc-authoring-plan.md` v2.53, 36 gates audited as executable content. All 7 blocking validators + advisory + records-lint were PASS at dispatch. 19 findings: 0 CRIT / 4 HIGH / 10 MED / 5 LOW.

Dominant class: sibling-sweep failures (TD-VSDD-060) — fixes applied to one gate instance but not swept to structurally identical siblings. The gate #25 Part C `awk` field fix (F-P170-15) was never applied to gate #33's structurally identical census. The "ALL FOUR → ALL THREE" count reduction (burst-272 F-P170-08 rationale) survived as six live non-changelog sites inside the very gate whose changelog declared the fix. Secondary: cascade-fix count import error — burst-272 imported gate #25 Part B's three-sibling count into gate #32's five-carrier structure. Tertiary: an exemption list member (`memory::skills`) failing its own stated prerequisite (no I/O), confirmed by `purity-boundary-map.md` §Effectful Shell placement.

Trajectory tail: →20→19→19.

## Findings (All OPEN — Fix-Burst 274 Pending)

### F-P172a-01 HIGH [process-gap] (PO)

**Gate:** #33 TAXONOMY ANCHOR REVERSE-VERIFICATION CENSUS
**Summary:** The automated pre-check uses `anchor=$4`; with the `error-taxonomy.md` §Error Catalog header `| Error Code | Category | Severity | BC Anchor | Message Format |` the leading empty field makes `$4`=Severity and `$5`=BC Anchor. The command emits `(code, severity)` pairs, routing downstream resolution to `behavioral-contracts/**/broken.md` — a nonexistent path. All 78+ live codes fail path resolution while the gate declares "Zero orphans permitted."

**Root cause:** Same class as F-P170-15 (gate #25 Part C `{print $2, $4}` field-index error, fixed in burst-272), but never swept to the sibling census command in gate #33 (TD-VSDD-060).

**Fix:** `anchor=$5`; add an inline header-mapping note documenting the column-to-field mapping; consider `shopt -s globstar` or `ss-*/` glob for the resolution path.

---

### F-P172a-02 HIGH [process-gap] (PO)

**Gate:** #32 carrier 5 vs carrier 4 conflict
**Summary:** Carrier 5 says "Any new ADR module addition need only appear in the THREE live documents listed above (items 1–3)". Gate #32 has FIVE carriers; items 1–4 are live — carrier 4 is the arch criticality registry, whose own text states "A module added by an ADR that does not appear in the arch registry is a gate #32 + gate #25 violation." The carrier-5 text actively authorizes skipping what carrier 4 forbids.

**Root cause:** The burst-272 F-P170-08 fix imported gate #25 Part B's three-sibling count into gate #32's five-carrier structure. The §Census procedure (steps 1–5) exercises carriers 1–3 only — there is no procedure step for carrier 4 — making the burst-273 definitions-only carve-out (which lives inside carrier 4) unenforceable by the gate's own procedure. The document also overloads "step N" to mean both carrier N and procedure step N.

**Fix:** Carrier 5 → "FOUR live documents (items 1–4)"; add a procedure step for carrier 4; disambiguate carrier-vs-step numbering throughout gate #32.

---

### F-P172a-03 HIGH [process-gap] (PO)

**Gate:** #25 "ALL FOUR" residue — six live sites survived the burst-272 count reduction
**Summary:** The burst-272 `ALL FOUR → ALL THREE` reduction did not propagate. Six live (non-changelog) sites survive inside gate #25: Part B "After editing" bullet ("across all four documents"); Part B Census-commands bullet (reconcile the PO §Classification Summary — whose tier parenthetical the v1.7 F-P170-11 fix deliberately deleted); Part C "across the four docs" ×2; Part C "tier-identical across all four docs but crate-divergent is a HIGH-severity finding"; Part C "All four docs must agree on crate ownership"; Part C census command comment ("and the PO module-criticality.md registry"). The v2.52 changelog claims this was closed — a TD-VSDD-059 incomplete closure with a TD-VSDD-060 sibling-sweep failure inside the same gate.

**Fix:** Sweep all six sites to "three"; delete the PO-registry clauses; leave only the §Source line's historical "all four criticality-bearing docs added" (P37 audit trail).

---

### F-P172a-04 HIGH [process-gap] (PO)

**Gate:** #32 carrier 4 definitions-only exemption — `memory::skills` fails its own prerequisite
**Summary:** The burst-273 definitions-only exemption names `memory::skills` as an established exempt case. `purity-boundary-map.md` places `memory::skills` in §Effectful Shell: "async `SkillStore` I/O: reads skill KV entries via `MemoryStore` backend; `load_skill`, `list_skills`, `skill_exists` I/O-bound (ADR-012 / BC-2.15.004)". This refutes the stated exemption criterion ("hosts ONLY type/trait definitions… no I/O"). It is also the one case with an untrusted-document ingress surface (BC-2.15.004 / DI-012). `module-decomposition.md` classifies it separately as a "routing-overlay entry" — a different rationale from definitions-only cases.

The exemption also mandates a §Pure Core placement record that would invite promoting an effectful module into Pure Core (F-P70-01 backward-correction failure mode). The other four named cases (`core::context_mutation`, `core::write_guard`, `core::guardrail`, `core::action_risk`) are verified correct.

Secondary weakness: the carve-out cites "ADR-009 Option 3 precedent" while `core::budget` — the ADR-009 pure-types module itself — carries a criticality row (`core-budget | ferrochain-core | SS-10 | HIGH`), as does `embeddings` (also declared definitions-only). The cited precedent does not support a no-row rule.

**Note:** This defect was introduced by fix-burst 273 under orchestrator routing.

**Fix:** Remove `memory::skills` from the definitions-only list; register it as a separately-named routing-overlay exception class; restate the precedent citation accurately; verify whether `core::documents` is intended to be covered.

---

### F-P172a-05 MED [process-gap] (PO)

**Gate:** #28 DEFER-002 note stale
**Summary:** Gate #28's DEFER-002 note still says machine enforcement of rules 1–6 "is DEFERRED to Phase 3 CI hardening… Until machine enforcement, burst discipline governs." `verify-changelog-date-monotonicity.sh` (blocking validator #7) now mechanizes Rule 2's date ordering and Rule 3. `verify-form-a-changelog-direction.sh` mechanizes Rule 6 for Form A.

**Verified NOT a finding:** Rule 5's supplement branch is satisfied by all seven live supplements and does not contradict validator #7.

**Fix:** Narrow the deferral to still-unmechanized rules (1, 4, 5, 6-Form-B); add a "LIVE (blocking)" line naming both hooks; record that validator #7 deliberately does NOT implement a `timestamp` ceiling check so the Phase-3 `assert date ≤ frontmatter_timestamp` plan remains open.

---

### F-P172a-06 MED [process-gap] (PO + devops)

**Gate:** #28 date-validity census — hardcoded five-file list vs actual eleven-file Form-B corpus
**Summary:** Gate #28's date-validity census is a hardcoded FIVE-file list, but the gate's own v2.34 sweep established the Form-B set as ELEVEN files (ADR-007, ADR-009, ADR-012, ADR-013, `BC-INDEX.md`, three BCs, `bc-authoring-plan.md`, `test-vectors.md`, `verification-architecture.md`). Six carry dated `## Changelog` tables and are absent — the exact incompleteness class the gate documents in F-P65-01. Also mis-classifies `verification-architecture.md` under "Supplements" though it lives in `architecture/`.

**Fix:** Make validator #7 the authoritative corpus-wide sweep; keep the enumeration only as a manual fallback, widened to eleven; correct the mis-classification.

---

### F-P172a-07 MED (PO)

**Gate:** #28 Rule 5 supplement enumeration — `observability.md` absent
**Summary:** Gate #28 Rule 5's supplement enumeration omits `observability.md` (`version: "1.5"`, `status: active`, changelog-bearing). There are SEVEN live files in `prd-supplements/`. Same class as F-P106-01. Consequential because `observability.md` hosts the Canonical Structured Event Catalog under SAP-1.

**Fix:** Add `observability.md` and state the count as 7.

---

### F-P172a-08 MED (PO)

**Gate:** #13 census scope / §authoring guidelines — stale "95 BCs" at six live sites vs `total_bcs: 129`
**Summary:** Six live (non-changelog) sites still read "95 BCs": frontmatter `subsystem_note`, §Proc-Macro BCs Batch-13 scope note, Authoring Guideline #1, Authoring Guideline #8, gate #13 census prose, gate #28 Rule 6 census header comment. Three are the SAME sites swept 86→95 by v2.13 that the v2.42 95→129 registration failed to re-sweep (TD-VSDD-060). Not cosmetic: gate #13 is the five-way anchor-matrix carrier census, so its stated scope with "95 BCs" EXCLUDES SS-18…SS-23 — the entire D21/D23 corpus.

**Fix:** Sweep all six sites to 129 or to "all BCs in BC-INDEX" to stop recurrence.

---

### F-P172a-09 MED (PO)

**Gate:** #13 VP-uniqueness census regex does not match either dominant VP-ID form
**Summary:** The census regex `VP-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]+` cannot match either dominant corpus VP-ID form: `VP-013` (the registered VP-001..013 namespace) extracts nothing (no trailing `-[0-9]+` after numeric segment), and `VP-2.23.003-A`-style per-BC IDs extract nothing (`.` is outside `[A-Z0-9]`). Only the alpha-domain form (`VP-BUDGET-05`) is visible. Both the "Expected output: empty" absolute and the v2.27 "141 unique VP IDs extracted" claim over-claim coverage.

**Fix:** Alternation permitting `.` and a bare 3-digit form; define whether co-citation of a registered VP by multiple BCs is permitted (it must be) versus VP definition.

---

### F-P172a-10 MED (PO)

**Gate:** #25 Part C census — two structural defects
**Summary:** (a) `grep -n` prefixes `NN:` so `grep -v "^| Module\|^|---"` matches nothing and header/separator rows survive. (b) `"| "` is not section-scoped, so it sweeps §Tier Definitions, §CRITICAL Module — Security Profile, and §Anti-Patterns, yielding ~30 junk pairs (`bsp-engine "all graph runs"`, `path-guard "all tool execution"`) presented as `(module, owning_crate)` pairs — on precisely the CRITICAL rows where the gate says "Any mismatch is a HIGH-severity finding" (F-P70-01 false-HIGH hazard). The `{print $2, $3}` field indices are CORRECT (F-P170-15's fix holds).

**Fix:** Section-scope with awk and drop `-n` from grep.

---

### F-P172a-11 MED (PO)

**Gate:** #25 Part B census — "Module Inventory table (arch)" routes to superseded PO file
**Summary:** Gate #25 Part B census names "Module Inventory table (arch)"; the arch registry has §Module Classification — §Module Inventory exists ONLY in the superseded PO file. An operator following the census is routed to the frozen file (compounds F-P172a-03).

**Verified alongside:** The arch registry's arithmetic is sound — 11/18/13/2 = 44 matches a row-by-row recount of its 44 §Module Classification rows; gate #25 Part B's de-pinned instruction is correct; `9/12/10/2=33` survives only inside the labelled OBS-P37-1 historical instance, as F-P170-14 intended.

**Fix:** "Module Classification table (arch)" in the census reference.

---

### F-P172a-12 MED [process-gap] (PO)

**Gate:** #32 definitions-only exemption not propagated to gate #25
**Summary:** The burst-273 definitions-only exemption was written into gate #32 ONLY, though it asserts it binds "gate #32 + gate #25". Gate #25 Part B's derived-doc check ("Any mismatch is a HIGH-severity finding") therefore yields a guaranteed FALSE HIGH for `memory::skills`, which carries a MEDIUM Criticality row in `module-decomposition.md` and no arch-registry row by documented intent.

**Fix:** Add the exemption (with the corrected case list per F-P172a-04) to gate #25 Part B as an explicit non-violation class.

---

### F-P172a-13 MED (PO)

**Gate:** #36 census glob matches `VP-INDEX.md`
**Summary:** Gate #36's census `grep -rL "^red_gate:" specs/verification-properties/VP-*.md` can never return the expected empty output because the glob matches `VP-INDEX.md`, an index with no `red_gate:` field (nor should it have one). Permanent false failure trains operators to ignore the gate. Same pattern for step 1's `ls`.

**Fix:** `VP-[0-9][0-9][0-9].md` or `| grep -v VP-INDEX`; add a note documenting the index exclusion in Rule 1.

---

### F-P172a-14 MED (PO)

**Gate:** #28 changelog-form integrity — `bc-authoring-plan.md` carries BOTH forms with missing rows in Form-B
**Summary:** `bc-authoring-plan.md` carries BOTH changelog forms — a frontmatter Form-A list (newest 2.53) AND a body §Changelog Form-B table (newest 2.51) — violating gate #28's "Do not mix both formats in the same file." The Form-B table is missing rows for versions **2.48, 2.49, 2.52, 2.53**; the document's own F-P88-03 precedent treats missing rows for existing versions as a defect requiring reconstruction. Gate #28's known-file list mis-classifies the file as Form-B-ONLY though a "BOTH forms" category exists (used for `ubiquitous-language-server.md`). Additionally, Rule 6's Python census `chk()` matches Form A first and returns when the frontmatter list has ≥2 entries (this file has 13), so the body table of ANY both-forms file is never examined — which is how four rows were lost undetected.

**Fix:** Pick one authoritative form (Form A recommended, hook-enforced); retire-with-banner or backfill the Form-B table; correct the known-file classification; make `chk()` evaluate Form B even when Form A is present.

---

### F-P172a-15 LOW (PO)

**Gate:** #25 Part B heading-check — bare filename with no path
**Summary:** Gate #25 Part B heading-check command uses bare `module-decomposition.md` with no path; every other census uses a `.factory/specs/...` path.

**Fix:** Full path.

---

### F-P172a-16 LOW (PO)

**Gate:** #25 Part B heading example — wrong heading text
**Summary:** Gate #25 Part B's heading example says "`## ferrochain-macros — MEDIUM`" but the actual heading is `## ferrochain-macros (ADR-008) — HIGH` and the registry says HIGH. Reading the example as current content invites a backward "correction" (F-P70-01 hazard).

**Fix:** Mark the example explicitly hypothetical with a note that real values must be verified against the registry.

---

### F-P172a-17 LOW (PO)

**Gate:** §Authoring Guidelines items 16 and 17 transposed
**Summary:** §Authoring Guidelines source order transposes items 16 and 17 (the `17.` block precedes the `16.` block). CommonMark renumbers sequentially, so rendered labels swap and gate #21's "re-run the full §17-C census (guideline #17 above)" points at the E-code gate, which has no Part C. Raw-markdown readers unaffected; rendered/human readers misrouted.

**Fix:** Reorder the blocks; text unchanged.

---

### F-P172a-18 LOW (PO)

**Gate:** #28 Census Step 1 form — counts rather than lists
**Summary:** Gate #28 Census Step 1 uses `grep -rh … | wc -l` (discarding filenames, counting `BC-INDEX.md`'s own `version:`) while Step 2 says "for each BC identified in Step 1."

**Fix:** Use a `grep -rl` form; or state Step 1 is a count only and Step 2's "each BC" is independent.

---

### F-P172a-19 LOW (pending intent verification) (PO)

**Gate:** VP-NNN Label Policy rule (3) — obligation created but simultaneously declined
**Summary:** The new "VP-NNN candidate" Label Policy rule (3) says "Once the architect assigns the VP in VP-INDEX, the 'candidate' qualifier is dropped" — but `VP-013` IS assigned in `VP-INDEX.md` while `BC-2.23.005` §Verification Properties still reads "VP-013 (Kani P1 candidate)". The same burst declined the sweep as disproportionate, so rule (3) creates an obligation the authoring burst simultaneously declined to satisfy. Ambiguity: `(Kani P1 candidate)` may mean "candidate for the Kani-P1 tier", not "candidate VP ID."

**Fix:** Either sweep all assigned-VP labels per rule (3), or add a grandfathering clause and a note distinguishing the two senses of "candidate."

---

## Verified-Clean Surfaces (P1D-172a — Axis 1 Complete)

- Every mechanism named by a gate EXISTS: `validate-input-hash.sh`, `validate-changelog-monotonicity.sh`, `validate-count-propagation.sh`, `compute-input-hash` in the vsdd-factory plugin cache, plus the nine project-side `.factory/hooks/` scripts; no gate claims a nonexistent hook or CI job.
- Gate-number inventory 1–36: each appears exactly once, no duplicates or gaps; corpus-wide sweep finds NO gate reference outside #12–#36 (zero dangling). `total_standing_gates: 36` count is correct.
- All gate-named paths resolve (F-P170-13's fix holds).
- Section anchors resolve in `interface-definitions.md` and `error-taxonomy.md`.
- Gate #17's positive-coverage and Part-A self-exclusion censuses are functional.
- Gate #27's multi-line quoted grep concatenates correctly; the 21-crate roster fix (F-P163-01) holds.
- `tools::config` is correctly NOT swallowed by the definitions-only carve-out (it carries a MEDIUM criticality row).
- All four other definitions-only carve-out cases (`core::context_mutation`, `core::write_guard`, `core::guardrail`, `core::action_risk`) check out.
- Naming caveat (not filed): `total_standing_gates: 36` counts numbered items 1–36 of which only #12–#36 self-identify as "gates" — defensible, but a definitional note would remove the ambiguity.

## Carried-Forward Directed Axes for P1D-172 Continuation (MANDATORY)

**Axis 2 — ADR semantic citation (not existence):** Prioritize ADR-018, ADR-019, ADR-020, ADR-014, ADR-012, ADR-017, ADR-010 families. Include validator #6's two documented blind spots: `+`-separated (`Decisions 1+4`) and paren-interleaved (`Decisions 3 (foo) and 4`) citations. Open item: ADR-010's `timestamp` diverges from the ADR decision-date convention now documented in gate #28 Rule 5 (architect).

**Axis 3 — End-to-end deep read:** `specs/architecture/api-surface.md` (only 3 sites corrected in burst-272; rest unaudited), `prd-supplements/interface-definitions.md`, `specs/architecture/verification-coverage-matrix.md`, `specs/architecture/system-overview.md`.

**Axis 4 — Broad regression sweep + FREE HUNT:** all derived-count parity BOTH directions; enum membership; error-taxonomy anchoring; wave/phase/priority propagation; observability catalog bidirectional completeness; VP `red_gate` uniformity; supersession blast radius; open future-imperative ADR handoffs.

## Validator Status at Dispatch

All 7 blocking validators + advisory + records-lint verified PASS before dispatch:

- verify-sha-currency.sh: PASS
- verify-form-a-changelog-direction.sh: PASS
- verify-arch-anchor-resolution.sh: PASS
- verify-no-version-pins.sh: PASS
- verify-enum-variant-casing.sh: PASS
- verify-adr-decision-refs.sh: PASS=267
- verify-changelog-date-monotonicity.sh: PASS
- verify-adr-self-version-refs.sh: PASS (advisory)
- records-lint.sh: PASS

## Orchestration Note

Two adversary dispatches and several specialist dispatches died on transient API errors (`Connection closed mid-response`, `Stream idle timeout`) during this session. This is WHY P1D-171 and P1D-172 were split into bounded sub-passes. Mitigation that worked: bounded sub-passes with fresh context, run sequentially rather than in parallel.
