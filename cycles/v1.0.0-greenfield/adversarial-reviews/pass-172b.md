---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-26T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 172b
previous_review: pass-172a.md
---

# Adversarial Review: ferrochain (Sub-pass P1D-172b)

## Scope

**Realized scope:** NARROW — axis 4 only (broad regression + free hunt: criticality-registry expansion audit, derived-count/consistency regression, and free hunt). Axes 2 and 3 of P1D-172 NOT RUN — carried forward as mandatory axes for P1D-172 continuation.

**Frozen HEAD:** `554dfd6bf3f0cfcaff0e67c48efcc68e32bf9b29` (burst-274 commit)

**Convergence-integrity rule:** 3-CLEAN streak (BC-5.39.001) requires FULL-PERIMETER passes only. This sub-pass must NOT advance the streak.

---

## Part A — Validator Status at Dispatch

All 7 blocking validators + advisory + records-lint were PASS at dispatch.

| Validator | Status |
|-----------|--------|
| verify-sha-currency.sh | PASS |
| verify-form-a-changelog-direction.sh | PASS |
| verify-arch-anchor-resolution.sh | PASS |
| verify-no-version-pins.sh | PASS |
| verify-enum-variant-casing.sh | PASS |
| verify-adr-decision-refs.sh | PASS=287 |
| verify-changelog-date-monotonicity.sh | PASS |
| verify-adr-self-version-refs.sh (advisory) | PASS |
| records-lint.sh | PASS |

---

## Part B — Findings (20 total — all OPEN; fix-burst 275 pending)

### HEADLINE: Phantom "56-module universe" invalidates burst-274 sweep

**F-P172b-02 (HIGH)** and **F-P172b-01 (HIGH)** together establish that burst-274's "full module-universe coverage sweep" was gated on a baseline that never equaled the artifact it names. The "56-row module-decomposition universe" is a phantom figure — an independent recount yields **70 rows** (68 tiered + 2 exempt). The figure has been mirroring the criticality registry total since v1.2, not the decomposition row count. Consequently 7 modules with non-`—` Criticality values in `module-decomposition.md` have no registry row and no exemption annotation.

---

### F-P172b-01 HIGH (architect)

**Title:** 7 tiered modules with no criticality row and no exemption annotation — registry gaps survive burst-274 sweep

**Finding:** An independent recount of `module-decomposition.md` yields 70 rows (68 tiered + 2 exempt). Seven modules carry a non-`—` Criticality tier in that table, have no row in `module-criticality.md`, and appear in no exempt list:
- `vectorstores::store` (ferrochain-vectorstores, MEDIUM)
- `vectorstores::retriever` (ferrochain-vectorstores, MEDIUM)
- `vectorstores::memory` (ferrochain-vectorstores, MEDIUM)
- `openai::embeddings` (ferrochain-openai, MEDIUM — credential-bearing HTTP surface, DI-009)
- `ollama::embeddings` (ferrochain-ollama, MEDIUM — credential-bearing HTTP surface, DI-010)
- `tools::fs` (ferrochain-tools, MEDIUM — filesystem-effectful path-guard consumer)
- `tools::search` (ferrochain-tools, MEDIUM — filesystem-effectful path-guard consumer)

All seven are present in `purity-boundary-map.md` (so real, not phantoms). The burst-274 "full module-universe coverage sweep" claim is a TD-VSDD-059 false closure.

**Fix:** Add 7 MEDIUM rows to `module-criticality.md`; registry 66 → 73; mirror in `verification-coverage-matrix.md`. Universe baseline corrected by F-P172b-02.

---

### F-P172b-02 HIGH (architect)

**Title:** Phantom "56" module-universe baseline in `module-criticality.md` and `purity-boundary-map.md` — actual count is 70

**Finding:** `module-criticality.md` §Module-universe sweep (v2.0) and `purity-boundary-map.md` §[Section Content] both cite a "56-row module-decomposition universe." An independent recount of `module-decomposition.md`'s module-bearing tables yields **70 rows** (68 tiered + 2 exempt).

Per-section breakdown (recounted independently):
- core: 8, graph: 8, checkpoint: 8, server: 5, sandbox: 6, splitters: 2, mcp: 5, memory: 6, macros: 3, core-D21: 4, prompts: 4, vectorstores: 5, provider-embeddings: 2, tools: 4 = **70**

The "56" figure has been mirroring the criticality registry total, not the decomposition row count, since v1.2. At v1.11 it recorded 35 while the actual table already held 48 tiered rows. Every criticality sweep since v1.2 was gated on a number not derived from the artifact it names.

Arithmetic impossibility: a 48-row registry diffed against a 56-row universe cannot yield 18 gaps — it was impossible on its face.

Note: `purity-boundary-map.md`'s own 81 = 33+36+12 total is CORRECT and its Iron Law coverage of all 70 rows is COMPLETE — only the "56" prose is wrong.

**Fix:** Replace "56" with "70 (68 tiered + 2 exempt)" in both cited locations; state the per-section derivation inline so the figure is reproducible.

---

### F-P172b-03 HIGH (architect)

**Title:** Two tier divergences between criticality registry and `module-decomposition.md`

**Finding:** Two modules have conflicting tier assignments between `module-criticality.md` and `module-decomposition.md`:
1. `core::embeddings` / registry `embeddings` (SS-22): registry **HIGH** (VP-008, ≥90%) vs decomposition **MEDIUM**
2. `vectorstores::similarity` (SS-21): registry **CRITICAL** (VP-009 Kani P0, ≥95%, §CRITICAL Security Profile row) vs decomposition **MEDIUM**

Both divergences were introduced by the registry-side v1.4 D21+burst-224 backfill that never propagated to `module-decomposition.md`. Gate #25 Part B declares tier mismatch a HIGH-severity finding. An implementer reading the decomposition would under-test the VP-009 zero-norm guard at ≥80% instead of ≥95%.

**Fix:** Update `module-decomposition.md` to reflect the authoritative registry tiers: `core::embeddings` → HIGH, `vectorstores::similarity` → CRITICAL.

---

### F-P172b-04 MED (architect)

**Title:** Three tier-bearing H2 headings in `module-decomposition.md` understate their crate's max tier

**Finding:** Per `module-decomposition.md`'s own mixed-tier convention (example: `## ferrochain-sandbox (SS-13) — CRITICAL (path-guard) / MEDIUM (backends)`), three crate headings understate:
- `## ferrochain-memory (SS-15) — MEDIUM` contains `memory::write_guard` HIGH
- `## ferrochain-prompts (SS-18) — MEDIUM` contains `prompts::injection_guard` HIGH
- `## ferrochain-vectorstores (SS-20, SS-21) — MEDIUM` contains `vectorstores::similarity` CRITICAL

Understated in the direction that matters — a skimmer applies ≥80% to a ≥90%/≥95% module. Gate #25's mandated `grep -n "^## "` heading census either was not run in burst-274 or was run without adjudicating results.

**Fix:** Update three H2 headings to enumerate max tier per crate: ferrochain-memory HIGH/MEDIUM, ferrochain-prompts HIGH/MEDIUM, ferrochain-vectorstores CRITICAL/MEDIUM.

---

### F-P172b-05 HIGH [process-gap] (product-owner)

**Title:** Gate #25 Part B exemption clause inverts the check direction — introduced by fix-burst 274

**Finding:** Gate #25 Part B's exemption clause, extended in fix-burst 274 under orchestrator routing, ends: "**Only check modules that are present as rows in the arch-registry (module-criticality.md) table.**" This INVERTS the check direction: a module with a tier in `module-decomposition.md` but no registry row is skipped WITHOUT being flagged, exempt-listed, or noted. This is exactly the class the same burst was closing, and it is why 7 gaps survived while the burst reported the sweep complete.

This defect was introduced by orchestrator routing in fix-burst 274.

**Fix:** Make the census bidirectional: "For each module in `module-decomposition.md` with a non-`—` Criticality value, a row MUST exist in `module-criticality.md`; if absent, HIGH-severity finding UNLESS the module appears verbatim in the gate #32 carrier-4 exempt list, in which case its Criticality column MUST read `—`" — plus a positive-coverage assertion requiring the triple (decomposition_tiered_rows, registry_rows, matched_rows) to be recorded.

---

### F-P172b-06 MED [process-gap] (architect)

**Title:** Inconsistent naming convention makes gate #25 Part C census mechanically unrunnable for ~30 of 66 registry rows

**Finding:** Burst-274 introduced `crate::module` naming into a registry that is ~45% prose-named, so gate #25 Part C's exact-string census is mechanically unrunnable: ~30 of 66 rows will not match. Examples: registry `bsp-engine (reducer stage)` vs decomposition `graph::bsp_engine`; registry `session-index` vs `checkpoint::session_index`; registry `path-guard` vs `sandbox::path_guard`; `server handlers`/`server security` vs `server::handlers`/`server::security`; `sqlite backend` vs `checkpoint::sqlite`; `memory-store (MemoryStore)` vs `memory::store`; `mcp client/adapter/server` vs `mcp::client/adapter/server`; `sandbox-wasm`/`sandbox-policy` vs `sandbox::wasm`/`sandbox::policy`.

The table now holds `sqlite backend` alongside `checkpoint::memory`, `checkpoint::postgres` and `memory::sqlite` — sibling backends in two conventions, one ambiguous about its owning crate.

**Fix:** Normalize all 66 Module cells to canonical `crate::module`, moving prose qualifiers into a separate column; annotate the 7 crate-level rows as "crate-level row, no 1:1 decomposition module" so the census can skip them deliberately.

---

### F-P172b-07 HIGH (architect)

**Title:** `dependency-graph.md` §Edge Table omits the `ferrochain-graph → ferrochain-checkpoint` edge

**Finding:** The `ferrochain-graph → ferrochain-checkpoint` edge is absent from `dependency-graph.md` §Edge Table, contradicting:
- The same file's §Invariant block ("graph depends on checkpoint")
- The same file's §Topological Build Order (checkpoint at position 5, graph at position 8)
- `domain-spec/bounded-contexts.md`
- `architecture/system-overview.md` P-06
- `module-decomposition.md`'s `graph::budget` row which uses `CheckpointSaver::search_history` (BC-2.04.008)

`ARCH-INDEX.md` §Document Map declares `dependency-graph.md` as the story-writer input for the crate DAG — a story-writer authoring `ferrochain-graph`'s `Cargo.toml` from the Edge Table would omit the dependency and the crate would not compile.

Sibling-sweep failure: burst-273 F-P171a-06 added two missing Edge Table rows without sweeping the table against the DAG/Invariant/BuildOrder for other omissions.

**Fix:** Add the `ferrochain-graph → ferrochain-checkpoint` row; then run a full three-way DAG↔Edge-Table↔Build-Order completeness diff and record the verified edge count.

---

### F-P172b-08 MED (architect)

**Title:** Kani crate list (3 crates) and proptest crate list both understated vs VP-INDEX

**Finding:** `dependency-graph.md` §Cross-Cutting Dependencies `kani` row names 3 crates (graph, checkpoint, sandbox); `tooling-selection.md` and `nfr-catalog.md` NFR-003 both name **7** (adding vectorstores, core, prompts, tools), derivable from `VP-INDEX.md`'s 9 Kani VPs.

Worse, the `proptest` row: `VP-INDEX.md` registers exactly two proptest VPs (VP-007, VP-008) **both in `ferrochain-core`**, which appears in NEITHER the dependency-graph row NOR `tooling-selection.md` §Property-Based Testing (which names graph, checkpoint, splitters). `verification-coverage-matrix.md` also marks proptest:yes for `message`/`runnable`/`retry` (core) and `memory-store`.

Consequence: Phase 6 would provision Kani for 3 of 7 harness-hosting crates, and both registered proptest obligations have no dev-dependency home.

**Fix:** Sync kani row to 7 crates; add `ferrochain-core` and `ferrochain-memory` to proptest rows in BOTH files; extend tooling-selection proptest §Target to name SS-19 and SS-22.

---

### F-P172b-09 HIGH (architect)

**Title:** `tooling-selection.md` §Kani async constraint mandates extracting a phantom symbol `checkpoint::session_index::derive_key`

**Finding:** `tooling-selection.md` §Kani async constraint mandates extracting **`checkpoint::session_index::derive_key`** — a PHANTOM symbol with zero other corpus occurrences. The authoritative VP-002 target is `storage_address` per `VP-002.md` §Proof Harness Skeleton / §Feasibility / §Proof Obligations. VP-002's sync-core target is now three-way divergent:
- `VP-002.md` → `storage_address`
- `tooling-selection.md` → phantom `derive_key`
- `purity-boundary-map.md` Rule 3 → `get_next_version` in the wrong module

**Fix:** Replace `derive_key` with `storage_address`; optionally name it in `verification-architecture.md` §Kani Async Constraint so all four sites are byte-consistent.

---

### F-P172b-10 HIGH (architect)

**Title:** `purity-boundary-map.md` Rule 3 mis-anchors VP-002 to `get_next_version` in `checkpoint::clock`

**Finding:** `purity-boundary-map.md` §Purity Enforcement Rules Rule 3 anchors VP-002 to `get_next_version` in `checkpoint::clock`, contradicting:
- The same file's §Pure Core table (VP-002 on the `checkpoint::session_index` row; `checkpoint::clock` → `—`)
- `verification-architecture.md`'s own v1.4 changelog ("VP-002 target is checkpoint::session_index; checkpoint::clock is not a direct VP target")
- `VP-INDEX.md` (module `session-index`)
- `verification-coverage-matrix.md`

Introduced by v1.20 (FIX-BURST-273 F-P171a-05) — the same edit that correctly re-scoped VP-010/011/013. `ARCH-INDEX.md` names the formal-verifier as Rule 3's consumer, so it would aim the VP-002 harness at the wrong module AND wrong function.

**Fix:** Rule 3 → `VP-002 (storage_address, checkpoint::session_index)`, then re-verify the other five same-clause pairings against `VP-INDEX.md` `harness_fn` and record the pass count.

---

### F-P172b-11 MED (product-owner)

**Title:** Stale "43 modules" count at two live sites after registry reached 66

**Finding:** `prd.md` §10 reads "authoritative, **43-module** Phase 1b registry" and `prd-supplements/module-criticality.md` §SUPERSEDED banner reads "**43 modules**, Phase 1b." The registry passed 44→48→66 across bursts 273–274 without either being swept. Partial-fix pattern: the banner's v1.7 change deleted its tier breakdown on the reasoning "the authoritative file owns the count" but left the total — same decaying class.

**Fix:** Delete the parenthetical count from both and route to §Classification Summary per the v1.7 precedent. The frozen-file objection does not apply — the banner was edited in bursts 268 and 272.

---

### F-P172b-12 MED (product-owner)

**Title:** 6 of 11 `observability.md` catalog rows carry Emitting-Module anchors resolving to no module in `module-decomposition.md`

**Finding:** 6 of 11 active rows in `observability.md` carry Emitting-Module anchors that do not resolve to any module in `module-decomposition.md`:
- `guardrail.unregistered_passthrough` → `tools.rs` (should be `mcp::ingress`)
- `server.rate_limit_store_in_memory` → `server init` (should be `server::stores`)
- `server.security_config_cors_wildcard` → `server init` (should be `server::security`)
- `memory.gdpr_unattributed_session_entries` → `gdpr.rs` (should be `memory::store`)
- `retry.unlimited_policy_constructed` / `retry.circuit_breaker_disabled` / `retry.circuit_probe_failed` → `retry::policy` / `retry::circuit_breaker` (registered module is `core::retry`)
- `eval.judge_infra_error` → `eval::judge` (crate `ferrochain-standard-tests` has NO module rows at all — Iron Law gap if real)

Two rows are correct and show the canonical form (`openai::embeddings`, `server::cron`). Sibling-sweep failure: `module-decomposition.md` v1.26 adjudicated `server::cron` canonical over the filesystem-path form and named "observability.md Module column" as a downstream fix — only the `server::cron` row was fixed; six siblings carrying the identical defect were not.

**Fix:** Re-anchor each; adjudicate `eval::judge` (add a `ferrochain-standard-tests` module table per Iron Law, or anchor crate-only with an explicit note).

---

### F-P172b-13 MED (state-manager/product-owner)

**Title:** `BC-INDEX.md` §VP Seed BCs footnote claims "architect to author VP body files in Phase 6" and carries stale "(candidate)" proof-method labels for 6 VPs

**Finding:** `BC-INDEX.md` §VP Seed BCs footnote reads "**architect to author VP body files in Phase 6**" though all 13 VP files exist, contradicting the same document's own preamble which states they are complete. Also its "Proof Method" column reads `Kani (candidate)` for VP-006/009/010/011/012/013 while `VP-INDEX.md` registers all nine as `tool: Kani`. For VP-011/012/013 the "(candidate)" label contradicts their BC H1s, which read `(VP-011 Kani Seed)` etc.

Partial-fix pattern: BC-INDEX v2.5 fixed the preamble note but left the footnote and Proof-Method labels unswept. A Production-Grade Default violation: an open "architect to author" imperative for completed work is a finding.

**Fix:** Remove the "architect to author" clause from the footnote; change `Kani (candidate)` → `Kani` for VP-006/009/010/011/012/013 in the Proof Method column.

---

### F-P172b-14 MED (architect)

**Title:** Three architecture documents bumped in burst-274 without advancing frontmatter `timestamp`

**Finding:** Burst-274 bumped versions/changelogs on three architecture documents without advancing frontmatter `timestamp`:
- `module-criticality.md`: timestamp 2026-07-25, newest changelog entry v2.0 **2026-07-26**
- `verification-coverage-matrix.md`: timestamp 2026-07-24, newest entries v2.6/v2.5 **2026-07-26**
- `module-decomposition.md`: timestamp 2026-07-25, newest entries v1.31/v1.30 **2026-07-26**

`purity-boundary-map.md` is consistent and shows the correct pattern. Gate #28 states the supplement rule and the architecture-section convention is established by `module-decomposition.md` v1.26 and `ARCH-INDEX.md` v1.12 precedent.

**Fix:** Advance all three frontmatter timestamps to 2026-07-26.

---

### F-P172b-15 MED (architect)

**Title:** `mcp::ingress` MEDIUM contradicts architectural sibling `graph::provenance` HIGH — same DI-012 classification, asymmetric kill-rate targets

**Finding:** `mcp::ingress` MEDIUM contradicts its byte-identical architectural sibling `graph::provenance` HIGH — `purity-boundary-map.md` §Boundary Modules classifies both as DI-012 guardrail-dispatch modules with equivalent pure/effectful splits, yet the registry assigns ≥90% to one and ≥80% to the other. `mcp::ingress` handles the EXTERNAL untrusted-input side (BC-2.09.003 "Tool-Result Content Treated as Untrusted Ingress"). Pre-dates burst-274 (both values match module-decomposition) — inherited, surfaced by the sweep.

**Fix:** Architect adjudication — raise `mcp::ingress` to HIGH for parity with `graph::provenance`, or document why the external-ingress side warrants a lower kill-rate target; propagate per gate #25 Part B.

---

### F-P172b-16 LOW (architect)

**Title:** `dependency-graph.md` omits the `ferrochain` facade crate (#1) from Crate DAG, Edge Table, and Topological Build Order

**Finding:** `dependency-graph.md` omits the `ferrochain` facade crate (#1) from the Crate DAG, Edge Table, and Topological Build Order (19 crates / positions 1–19). The facade re-exports from every implementation crate, so it is the terminal DAG node with the highest fan-in edge set — entirely undocumented. `ferrochain-community` is also absent but justifiably ("post-v1; not in-tree at v1"); the facade has no such note, and the three `-sdk` crates ARE included, making the omission asymmetric.

**Fix:** Add the `ferrochain` facade to all three sections with appropriate edges and build order position.

---

### F-P172b-17 LOW (architect)

**Title:** `dependency-graph.md` §Crate DAG and §Edge Table attribute `CheckpointSaver` to `ferrochain-core`

**Finding:** `dependency-graph.md` §Crate DAG and §Edge Table attribute `CheckpointSaver` to `ferrochain-core` (text: "ferrochain-checkpoint (uses core: CheckpointSaver, FerrochainError)"). `CheckpointSaver` is DEFINED in `ferrochain-checkpoint` per `module-decomposition.md` §ferrochain-checkpoint `checkpoint::saver` row (CRITICAL, SS-04).

**Fix:** Change the rationale to `FerrochainError; Message/ContentBlock for GraphState payloads` and move `CheckpointSaver` onto the graph→checkpoint edge added by F-P172b-07.

---

### F-P172b-18 LOW [pending intent verification] (architect)

**Title:** `tooling-selection.md` excludes `xtask/` and `ferrochain-community/` from cargo-mutants while both carry a ≥70% LOW kill-rate target

**Finding:** `tooling-selection.md` §Mutation Testing excludes `xtask/` and `ferrochain-community/` from cargo-mutants while both carry a ≥70% LOW-tier kill-rate target in `module-criticality.md` and `verification-coverage-matrix.md`. An "advisory" gate implies a reported number; a hard exclusion means none exists.

**Fix:** Adjudicate — drop the exclusions and mark LOW advisory-only in CI, or change both files' Kill Rate cells to `n/a (excluded from cargo-mutants)`.

---

### F-P172b-19 LOW (product-owner)

**Title:** `prd-supplements/module-criticality.md` frontmatter carries a stale and unsatisfiable obligation

**Finding:** `prd-supplements/module-criticality.md` frontmatter carries `architect_note: "Architect must confirm crate-to-subsystem mapping and fill Architecture Module column after producing ARCH-INDEX.md"`. `ARCH-INDEX.md` has existed since 2026-07-13, the file was superseded at Phase 1b, and its §Module Classification table has NO "Architecture Module" column — so the obligation is both stale and unsatisfiable.

**Fix:** Replace with a discharged-obligation note.

---

### OBS-P172b-A (observation)

**Title:** `ARCH-INDEX.md`, `module-decomposition.md`, and `dependency-graph.md` declare the SUPERSEDED PO draft in `inputs:` but not the live `specs/module-criticality.md`

**Observation:** These three documents carry the SUPERSEDED 22-module PO draft in their frontmatter `inputs:` while none declares the authoritative `specs/module-criticality.md`. The input-hash cascade for those three documents is anchored to a frozen draft and therefore cannot signal drift when the live registry changes. No live work-routing to the superseded file was found anywhere — supersession blast radius otherwise CLEAN. Recorded as a plausible mechanism behind F-P172b-03 (tier drift that went undetected by hash cascade).

---

### OBS-P172b-B [process-gap] (observation)

**Title:** No census gate requires a positive-coverage assertion; prose completeness claims are unfalsifiable

**Observation:** NO census gate (#25 Part A/B/C, #32 carrier 4) requires a **positive-coverage assertion**; no gate output records "N modules checked, M matched." Every criticality census has been a prose claim ("sweep complete", "full module-universe coverage") with no countable artifact — which is why F-P172b-01/02/03/04 all survived unfalsifiably. Recommend extending gate #25 to require a recorded triple `(decomposition_tiered_rows, registry_rows, matched_rows)` in the burst changelog, blocking the burst unless `decomposition_tiered_rows − exempt == matched_rows`. This is an OPEN process-gap (fix-burst 275 pending).

---

## Part C — Verified-Clean Surfaces

The following surfaces were independently verified CLEAN during this pass. Record in full for future pass economy — this list is unusually valuable.

1. **Criticality registry arithmetic:** 66 rows recounted; 12/22/30/2 = 66 matches §Classification Summary exactly; `verification-coverage-matrix.md` 66 rows with matching §Coverage by Criticality Tier.

2. **Row-for-row set equality between the two registries:** All 66 rows correspond 1:1 (modulo parenthetical qualifiers); ZERO crate divergences; ZERO tier divergences *between these two files*. Gate #25 Part C crate-ownership diff CLEAN.

3. **Tier defensibility of the 18 new rows:** All 18 match `module-decomposition.md`'s pre-existing Criticality column. Explicitly adjudicated DEFENSIBLE (not findings): `checkpoint::saver` CRITICAL (tier definition includes "durability invariants"; no VP requirement; precedent `clock`/`encryption`/`hitl`/`scheduler`/`credentials`/`error` all CRITICAL without a VP); the three sandbox backends MEDIUM (consistent with pre-existing `sandbox::wasm` MEDIUM and §ferrochain-sandbox heading); `server::cron` MEDIUM (sole non-request-path server module); `core::events` HIGH (parallel to `core::message`); `graph::definition`/`server::streaming`/`server::stores` HIGH. Only `mcp::ingress` failed (F-P172b-15).

4. **Exemption-annotation integrity:** `core::documents` and `memory::skills` both correctly annotated `—`, consistent with their purity classifications, and the exempt lists in gate #25 Part B and gate #32 carrier-4 agree verbatim with each other and with the ground truth.

5. **Purity-boundary Iron Law completeness:** 33 + 36 + 12 = 81 recounted; all 70 decomposition rows appear in exactly one column; the 11 extra rows accounted for (4 definitions-only core modules, 6 crate-level rows, 1 intentional `graph::hitl` dual-classification).

6. **BC census:** 129 files on disk; per-subsystem counts match every `ARCH-INDEX.md` BC range exactly (summing to 129); priority tally independently recounted **P0 51 / P1 75 / P2 3**; Red Gate 11 rows == 11 `**RG**` marks (sets identical); VP Seed 11 rows == 11 `**VP**` marks.

7. **VP arithmetic:** 13 = P0 6 + P1 7; Kani 9 + proptest 2 + integration 2 = 13; `verification-architecture.md`, `verification-coverage-matrix.md`, `ARCH-INDEX.md` agree row-for-row on BC anchor/DI/module/crate/tool/phase/priority. `red_gate` uniformity confirmed exactly: 5 true (VP-004/005/006/009/010), 8 false — consistent across all 13 VP bodies.

8. **Observability catalog census:** Exactly 11 active `event_type` values (+1 correctly struck RETIRED row); every row cites a real emitting BC; bidirectional BC↔catalog completeness holds. Only the *module* anchors are defective (F-P172b-12).

9. **Enum/canon hygiene:** ZERO live-body occurrences of `ActionRisk::Critical`, `set_risk`, `Category::VALIDATION`, `Category::COMPATIBILITY`; `ActionRisk` 4-variant `#[non_exhaustive]` in `core::action_risk`; `ToolConfig::override_risk(self, …) -> Result<ToolConfig, FerrochainError>` in `tools::config`; E-TOOLS-007 at call time; `set_risk` retired — all hold corpus-wide with no contradicting document.

10. **Domain-spec derived counts:** 15 DIs, 38 CAPs (11 P0 + 27 P1/P2), 19 failure modes FM-001..019, 21 crates (roster derivation sums correctly), 20 ADR files.

11. **DI orphan detection:** All 15 DI IDs carry ≥1 BC citation; 564 DI references across 103 BC files; every DI appears in `BC-INDEX.md` DI Anchors column. ZERO orphan invariants.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 6 |
| MED | 8 |
| LOW | 4 |
| OBS | 2 |
| **Total findings** | **20** |

**Overall Assessment:** NOT CLEAN — 20 findings (2 OBS include 2 process-gaps: F-P172b-05, F-P172b-06, OBS-P172b-B)

**CLEAN (strict):** no — 20 items present (0C/6H/8M/4L/2OBS)
**CLEAN (PR-merge):** no — 6 HIGH findings present

**Streak:** 0/3 (remains 0/3; HIGH findings present; sub-pass cannot advance streak per convergence-integrity rule)
**Novelty:** HIGH — phantom baseline figure (F-P172b-02) reveals systematic census failure since v1.2; 7 registry gaps (F-P172b-01) survived 172 prior passes; gate-inversion defect (F-P172b-05) introduced by the burst that claimed to close the class; VP-002 target three-way divergence (F-P172b-09/10) introduced by fix-burst 273.

**Trajectory tail:** →19→19→20

**Fix burst:** 275 PENDING (route mostly to architect; F-P172b-05/11/12/13/19 to product-owner)
