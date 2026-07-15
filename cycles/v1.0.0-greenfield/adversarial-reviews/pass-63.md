---
document_type: adversarial-review-pass
phase: 1d
pass: 63
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 1
low_count: 0
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "→ fuzz-target coherence (new lens); single derived-doc contradiction on splitter row"
timestamp: 2026-07-15T00:00:00Z
new_class: "none (localized derived-doc contradiction — verification-architecture outlier vs BC + matrix)"
routing: "F-P63-01 → architect (verification-architecture.md owner)"
---

# Adversarial Review Pass 63 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (0 HIGH, 1 MED, 0 LOW) + 2 observations. Counter reset: 0/3 consecutive clean. Novelty: LOW-MEDIUM.

---

## F-P63-01 [MED] — verification-architecture §Fuzzing Targets Splitter Row Contradicts BC-2.17.002 and verification-coverage-matrix

**Finding class:** Derived-doc contradiction on a never-exercised lens (fuzz-target coherence).

**Status:** Pending-intent-verified → accepted. Routed to architect. Orchestrator adjudication: BC-authoritative.

**Scope:** `.factory/specs/architecture/verification-architecture.md` §Fuzzing Targets (header cites BC-2.17.002); `.factory/specs/behavioral-contracts/BC-2.17.002.md`; `.factory/specs/architecture/verification-coverage-matrix.md` fuzz-tier rows.

**Finding:** The §Fuzzing Targets section of `verification-architecture.md` (whose header cites BC-2.17.002 as authority) lists **3 fuzz targets**, including:

| Target | Crate | Priority |
|---|---|---|
| fuzz_checkpoint_serde | bsp-engine | P0 |
| fuzz_graph_execution | bsp-engine | P0 |
| Splitter inputs | ferrochain-splitters | P1 |

BC-2.17.002 is authoritative and specifies exactly **two** cargo-fuzz targets — `fuzz_checkpoint_serde` and `fuzz_graph_execution` — covering the two CAP-019 paths (checkpoint serde round-trip and graph execution boundary). The BC postconditions contain no splitter fuzz target and no reference to `ferrochain-splitters`.

`verification-coverage-matrix.md` is coherent with BC-2.17.002: the splitter fuzz cell = `—` and the MEDIUM-tier fuzz cell = `—`, with the two BC-2.17.002 targets mapped exclusively to bsp-engine + sqlite rows. The matrix correctly reflects the two-target mandate.

`verification-architecture.md` is the outlier: the "Splitter inputs | ferrochain-splitters | P1" row is not authorized by any BC postcondition, is not reflected in the coverage matrix, and contradicts the BC's explicit "must include two cargo-fuzz targets" mandate.

**Orchestrator adjudication:** BC-authoritative — splitter row removed from §Fuzzing Targets; splitter robustness coverage in v1 = proptest + GTV Red Gate (BC-2.07.002). Post-v1 fuzz addition requires BC + matrix updates in the same burst.

**Consumer impact:** An implementer or test-writer reading `verification-architecture.md` as the authoritative fuzz surface would create a third cargo-fuzz target (`fuzz_splitter_inputs`) not backed by any behavioral contract, bloating the fuzz harness with an untested-against-spec target, and potentially masking true coverage gaps. The contradiction is silent: no consistency-validator gate currently runs fuzz-target coherence.

**Root cause:** One-directional authoring. When §Fuzzing Targets was drafted or last edited, the splitter row was added speculatively (likely as a v1+ aspirational target) without a corresponding BC postcondition or matrix row. The BC and matrix were authored independently and correctly reflect the two-target mandate. No prior gate exercised fuzz-target count coherence across the three carrier documents.

**Severity justification (MED):** The contradiction does not affect any BC, interface definition, error taxonomy, or story acceptance criterion. The fix surface is narrow (one row deletion in one table in `verification-architecture.md`). However, the gap is structurally consequential: fuzz harness scope is a Phase 3 deliverable, and an extra un-BCed target would reach the test-writer as a specification input.

**Fix route:** Routed to architect (verification-architecture.md owner). Fix = remove "Splitter inputs | ferrochain-splitters | P1" row from §Fuzzing Targets. No BC changes, no matrix changes, no interface changes required. If splitter fuzzing is desired post-v1, it requires a new BC postcondition in the relevant BC file + a corresponding matrix row + verification-architecture update in the same burst.

---

## Observations

### OBS-P63-1 — BC-INDEX VP Column Kani-Seed-Only Convention Confirmed Intentional

**Observation:** The BC-INDEX VP column entries are populated with Kani seed references only (not the full VP set). This was identified as a potential gap in prior passes. Confirmed this pass: the convention is intentional per the index's declared scope — the VP column is a Kani-seed pointer, not a full VP inventory. Full VP traceability lives in VP-INDEX and the verification-coverage-matrix. No gap.

**Disposition:** Not flagged as a finding. Convention confirmed intentional. No fix required.

### OBS-P63-2 — Kani sync-core Mandate Omitting path-guard Defensible

**Observation:** The Kani formal verification mandate covers `sync-core` paths but does not include a `path-guard` formal target. The omission is defensible on technical grounds: `sync-core` is inherently synchronous, and the OS-model note in the verification architecture correctly characterizes the path-guard layer as an OS-boundary concern outside Kani's effective model. No behavioral contract requires a `path-guard` Kani target.

**Disposition:** Not flagged as a finding. Omission is architecturally justified. No fix required.

---

## Sibling Check — module-decomposition v1.4 xtask Section PASS

Gate #32 follow-up: module-decomposition v1.4 xtask section verified complete (qualifier present + 5 rows: `check-file-size`, `deny-client-new`, `deny-expect-in-lib`, `deny-anyhow-in-lib`, `deny-description-cache-key` + naming-variant rationale). Universe 33 unchanged. F-P62-01 fix confirmed applied.

---

## Mandatory Censuses

| Gate | Description | Verdict |
|---|---|---|
| #12 | Lifecycle-arrow coherence — all BC lifecycle transitions consistent | PASS |
| #14 | Harness-fn coherence — all harness function names match BC IDs | PASS |
| #17-A | URL-scheme coherence — no mixed http/https within a single surface | PASS |
| #19 | Retired-identifier coherence — retired IDs carry status:retired, no reuse | PASS |
| #25-A | Summary arithmetic — 33 = 9 P0 + 12 P1 + 10 P2 + 2 retired; universe unchanged | PASS |
| #27 | Wrong-crate coherence — no type defined outside its declared type-home crate | PASS |
| #30 | Minted-codes — no new error codes introduced without taxonomy entry | PASS |

**Census #28 EXACT distribution:** 41×v1.0 + 26×v1.1 + 11×v1.2 + 7×v1.3 + 1×v1.4 = 86 total spec documents. Changelog-bearing set (45) exactly equals version>1.0 set (45). Zero spurious changelog entries.

**Gate #32 spot:** ADR-009, ADR-010, ADR-011 — all three-carrier coherence PASS (following F-P62-01 fix).

---

## Extra Axes

| Axis | Verdict |
|---|---|
| DI orphans | 14/14 covered — zero orphan invariants | PASS |
| VP 3-doc coherence (VP-INDEX ↔ verification-architecture ↔ verification-coverage-matrix) | PASS |
| BC H1↔INDEX↔subsystem sync — ALL 86 BCs (full corpus, not sampled) | PASS |

---

## Free Probes

**Fuzz-target coherence (NEW lens):** Three-carrier check (BC postconditions → verification-architecture §Fuzzing Targets → verification-coverage-matrix fuzz rows). Two of three carriers coherent (BC + matrix = two targets, bsp-engine only). Third carrier (verification-architecture) diverges on splitter row. Surfaced as F-P63-01.

**Numeric VP-ID collision probe:** BC-local namespaced VP tables (VP-NNN entries scoped within each BC file) verified non-colliding with global VP-001..005 registry. All BC-local VP references use BC-scoped namespacing — no integer collision with the global VP catalog.

---

## Novelty Assessment

**Classification: LOW-MEDIUM.**

**Basis:** Single localized derived-doc contradiction surfaced by a never-exercised fuzz-target coherence lens. The gap is narrow (one row in one table), local (verification-architecture.md §Fuzzing Targets only), and does not affect any BC, interface definition, error taxonomy, story, or VP artifact. No new finding class — derived-doc contradictions are a known subclass. The package is otherwise converged: absent F-P63-01, this pass would be CLEAN. Novelty is elevated to LOW-MEDIUM (rather than LOW) because the finding emerged from a genuinely new lens (fuzz-target count coherence across three carriers) not previously exercised in any prior pass.
