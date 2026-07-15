---
document_type: adversarial-review-pass
phase: 1d
pass: 64
verdict: NOT CLEAN
findings_count: 2
high_count: 0
med_count: 1
low_count: 1
observations_count: 0
consecutive_clean: 0
required_clean: 3
trajectory: "→ server default-config coherence (new lens) → architecture↔supplement port mismatch; supplement self-changelog temporal ordering (new lens) → future-dated v1.1 row"
timestamp: 2026-07-15T00:00:00Z
new_class: "architecture↔supplement default-config coherence; supplement self-changelog temporal ordering"
routing: "F-P64-01 → architect (api-surface.md owner); F-P64-02 → product-owner (fixed this burst)"
---

# Adversarial Review Pass 64 — Phase 1d

**Verdict: NOT CLEAN** — 2 findings (0 HIGH, 1 MED, 1 LOW). Counter reset: 0/3 consecutive clean. Novelty: MEDIUM-HIGH.

---

## F-P64-01 [MED] — api-surface.md:69 "no default port mandated" Contradicts interface-definitions.md Default Port 7437

**Finding class:** Architecture↔supplement default-config coherence (new lens — no prior pass exercised port-default cross-check between api-surface.md and interface-definitions.md).

**Status:** ADJUDICATED by orchestrator — 7437 IS the canonical default; api-surface.md is the outlier. Routed to architect for fix in concurrent burst.

**Scope:** `.factory/specs/architecture/api-surface.md` §Server Binding (line 69); `.factory/specs/prd-supplements/interface-definitions.md` line 274 ("Default port: `7437`") and line 483 (`port = 7437` in ferrochain-server.toml config block).

**Finding:** `api-surface.md` line 69 states "no default port mandated — caller supplies bind address" (or equivalent text asserting no canonical default exists). `interface-definitions.md` defines `7437` as the default port at two independent sites: (1) the Base URL prose section (line 274) and (2) the `ferrochain-server.toml` config schema example (line 483). The supplement self-references are mutually consistent; architecture is the outlier.

**Adjudication (D18-P64-A):** `interface-definitions.md` is the behavioral authority for server configuration defaults (PRD supplement, product-owner scope). `api-surface.md` is a derived architecture artifact. Default port 7437 is canonical. `api-surface.md` must be updated to reflect the 7437 default. No supplement changes required.

**Consumer impact:** An implementer reading `api-surface.md` as the server-binding authority would produce a server with no compile-time or startup default, requiring callers to always supply an explicit bind address. This directly contradicts the ferrochain-server.toml config schema (which specifies `port = 7437` as the baked-in default) and the Base URL prose (which consumers rely on for local development setup). The contradiction is silent: no consistency-validator gate currently cross-checks default-config values between architecture and supplement layers.

**Root cause:** One-directional authoring. The default port was established in `interface-definitions.md` during PRD supplement authoring. When `api-surface.md` was drafted, the server-binding section was written without consulting the supplement's config schema, producing an independently reasonable but contradictory statement. No prior census exercised architecture↔supplement default-config coherence.

**Severity justification (MED):** The contradiction does not affect any BC postcondition, error taxonomy, or story acceptance criterion directly. The fix surface is narrow (one statement in one architecture file). However, the gap is consequential for implementers: the default port value is a setup-critical constant that appears in documentation, integration tests, and developer onboarding.

**Fix route:** Routed to architect (api-surface.md owner). Fix = align api-surface.md §Server Binding default port statement to "7437 (configurable via `server.port` in `ferrochain-server.toml`)". No BC changes, no supplement changes, no matrix changes required.

---

## F-P64-02 [LOW] — bc-authoring-plan.md Changelog v1.1 Row Dated 2026-07-16 — Future-Dated Relative to v1.2 (2026-07-14)

**Finding class:** Supplement self-changelog temporal ordering (new lens — no prior pass audited date monotonicity within supplement body changelog tables).

**Status:** FIXED this burst (product-owner, bc-authoring-plan.md v2.4→v2.5; test-vectors.md v1.2→v1.3 co-fix from sweep).

**Scope:** `.factory/specs/prd-supplements/bc-authoring-plan.md` changelog table line 1368 (v1.1 row); `.factory/specs/prd-supplements/test-vectors.md` changelog table line 211 (v1.1 row — same error found in sweep).

**Finding:** `bc-authoring-plan.md` changelog table lists entries newest-at-top, oldest-at-bottom. The v1.1 row (line 1368) carries date `2026-07-16` — two days LATER than the superseding v1.2 row (date `2026-07-14`). This inverts the temporal order: v1.1 is the antecedent of v1.2 (PASS-36 precedes PASS-37) yet carries a later date. The frontmatter `timestamp: 2026-07-15T00:00:00Z` further bounds the issue: a changelog entry for a prior version cannot be dated after the document's own timestamp without self-contradiction.

Sweep (all prd-supplements with body changelog tables): `test-vectors.md` carries the identical defect — v1.1 row dated `2026-07-16`, superseded by v1.2 dated `2026-07-14` (same PASS-36/PASS-37 pairing). Both errors share a single root cause (F-P36-03 edits to both files were logged with an erroneous future date).

**Corrected dates:** Both v1.1 rows corrected to `2026-07-14` (PASS-36 day, consistent with v1.2 same-day PASS-37 authoring).

**Severity justification (LOW):** Metadata-only error with no behavioral impact. No BC postcondition, interface definition, error taxonomy, or story acceptance criterion references these rows. Gate #28 scope is BC changelog integrity only; supplement-body changelog temporal ordering is outside all standing gates. The error is cosmetic but creates misleading history for future reviewers.

**Root cause:** F-P36-03 edits to both bc-authoring-plan.md and test-vectors.md were logged with an incorrect date (`2026-07-16`) — two days ahead of the actual authoring date (`2026-07-14`). PASS-36 and PASS-37 both occurred on 2026-07-14; the v1.1 changelog entry was likely typed with an off-by-two error. No prior census exercised date-monotonicity within supplement body changelog tables.

---

## Sibling Check — verification-architecture v1.2 Two-Row Fuzz Table PASS

Following F-P63-01 fix (architect burst): `verification-architecture.md` §Fuzzing Targets now contains exactly two rows (`fuzz_checkpoint_serde` + `fuzz_graph_execution`, both bsp-engine P0). The splitter row has been removed. Two-row table is coherent with BC-2.17.002 postconditions (two-target mandate) and `verification-coverage-matrix.md` fuzz-tier rows (splitter fuzz cell = `—`). Three-carrier coherence: PASS.

---

## Mandatory Censuses

| Gate | Description | Verdict |
|---|---|---|
| #12 | Lifecycle-arrow coherence — 15 hits across BC corpus, all transitions canonical | PASS |
| #18 | Shared-type zero-live — zero live uses of retired shared types in non-architecture files | PASS |
| #19 | Retired-identifier coherence — retired IDs (BudgetContext, BudgetDecision, etc.) carry status:retired; zero reuse | PASS |
| #20 | Shared-type zero-live (complement) — zero live shared-type references outside declared home crates | PASS |
| #27 | Wrong-crate coherence — quick spot: zero wrong-crate architecture anchor refs in newly touched files | PASS |
| #28 | Version-changelog integrity — 45 BCs with version>1.0: 42 Form-A (frontmatter `changelog:` key) + 3 Form-B (body `## Changelog` table); union complete; zero uncovered | PASS |
| #29 | Supplement-vs-BC seam census — SS-13 sandbox rows: 6 rows checked across feature-flags + flag-interactions + config-comment; zero mismatches with BC-2.13.001/002 | PASS |
| #31 | Trait-signature type-resolution — PolicyDecision/RunContext name-equality check RESOLVED (gate #31 step 4): both names match BC-authoritative terms; zero name-drift on newly touched types | PASS |
| #32 | ADR-propagation census — ADR-009 three-carrier check (bc-authoring-plan batch-table + BC bodies + interface-definitions): PASS | PASS |

**VP 3-doc coherence** (VP-INDEX ↔ verification-architecture ↔ verification-coverage-matrix): PASS — post-F-P63-01 fix confirmed coherent.

**New-mint spot check:** Zero new error codes introduced this burst; zero new type names introduced. Gate #30 census returns zero genuine hits; gate #31 census unchanged.

---

## Free Probes

**CAP-011↔BC-2.08.008 semantic-fit (spot):** BC-2.08.008 capability anchor cites CAP-011 ("Provide LLM provider abstraction with structured output support"). BC-2.08.008 describes structured output schema enforcement at the provider boundary. Semantic fit: PASS — the BC's postconditions are a direct behavioral expression of CAP-011's scope.

**Server default-config coherence (NEW lens):** Cross-checked default configuration values between architecture files (api-surface.md) and prd-supplements (interface-definitions.md config schema). Discovered port-default contradiction. Surfaced as F-P64-01.

**Supplement self-changelog temporal ordering (NEW lens):** Scanned all prd-supplement files carrying body `## Changelog` tables for date-monotonicity violations (newest-at-top convention: dates must be non-increasing top-to-bottom). Found two violations sharing PASS-36 root cause. Surfaced as F-P64-02.

---

## Novelty Assessment

**Classification: MEDIUM-HIGH.**

**Basis:** Two genuinely new lenses — neither exercised in any prior pass. (1) Architecture↔supplement default-config coherence: a cross-layer check comparing concrete default values (port numbers, config keys) between architecture docs and PRD supplements. The finding surface (api-surface.md §Server Binding) had never been compared against interface-definitions.md's config schema in any prior pass. (2) Supplement self-changelog temporal ordering: a meta-integrity check verifying that body changelog tables maintain date monotonicity within their own ordering convention. Both lenses are repeatable and structurally distinct from previously exercised axes. Approximately 10 other axes converged cleanly (lifecycle, shared-types, retired IDs, VP coherence, ADR propagation, seam census, new-mint, semantic-fit spot). Novelty is elevated to MEDIUM-HIGH — two new lenses with non-trivial findings, even though one (F-P64-02) is metadata-only severity.
