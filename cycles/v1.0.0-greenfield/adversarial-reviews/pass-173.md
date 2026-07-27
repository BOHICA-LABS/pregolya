---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-27T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 173
previous_review: pass-172b.md
---

# Adversarial Review: ferrochain (P1D-173 FULL-PERIMETER)

## Scope

**Realized scope:** FULL-PERIMETER — 8 fresh-context slices at frozen HEAD `8954a11`. Carries P1D-172 axes 2 and 3 forward and extends to five additional surfaces never previously read at method granularity.

**Methodology note:** A single adversary agent was originally dispatched for the full perimeter. Repeated API connection errors ("connection closed mid-response") caused three successive dispatch losses before diagnosis. Root cause: the adversary tool profile is read-only (Read/Grep/Glob — no Write, no Bash), so its entire output must arrive in a single final message; any API interruption discards the full run. Mitigation: decompose the perimeter into 8 bounded slices, each small enough to complete within one response window. The orchestrator ran `verify-sha-currency.sh`, `records-lint.sh`, and all project validators (no Bash available to the adversary). Per-slice results were compiled by the orchestrator into this record.

**Frozen HEAD:** `8954a11` (factory-artifacts branch at time of dispatch; develop HEAD `46725ad`).

### Per-Slice Coverage Depth

| Slice | Scope | Files Read at Depth | Findings |
|-------|-------|---------------------|----------|
| 1a | ADR-018, ADR-019, ADR-020 semantic citations — 339 occurrences verified, 96 decision-numbered anchors checked | ADR-018, ADR-019, ADR-020 full bodies | 15 (F-P173-101..115) |
| 1b | ADR-014, ADR-012, ADR-017 semantic citations — ~117 sites | ADR-014, ADR-012, ADR-017 full bodies | 15 (F-P173-701..715) |
| 2a | `api-surface.md` full read — first audit of this file | `api-surface.md` (never previously audited at method granularity) | 15 (F-P173-201..215) |
| 2b | `interface-definitions.md` full read — 1917 lines | `interface-definitions.md` (first line-granularity read) | 23 (F-P173-601..623) |
| 2c | `verification-coverage-matrix.md` + `system-overview.md` full read | Both files in full | 17 (F-P173-801..817) + 4 OBS |
| 3 | burst-275 regression + census recount + gate meta-check | `bc-authoring-plan.md` §gate-25/26/27, `module-criticality.md`, `module-decomposition.md`, `purity-boundary-map.md` | 19 (F-P173-301..319) |
| 4 | Free hunt: `domain-spec/`, 129 BC body files, taxonomies, indices | `domain-spec/bounded-contexts.md`, `BC-INDEX.md`, `error-taxonomy.md`, `L2-INDEX.md`, capability shards | 10 (F-P173-401..410) |
| 5 | 13 VP body files full read — first audit of VP bodies at property-text granularity | `VP-001.md` through `VP-013.md` in full | 16 (F-P173-501..516) |

**Raw total: 130 findings. After merges documented below: ~122 unique findings.**

---

## Part A — Validator Status (Orchestrator-Run, Post-Burst-275 Commit)

| Validator | Result | Detail |
|-----------|--------|--------|
| `records-lint.sh` | PASS | PASS=3 WARN=0 FAIL=0 |
| `verify-sha-currency.sh` | PASS | PASS=2 WARN=1 FAIL=0 |
| `verify-form-a-changelog-direction.sh` | PASS | PASS=192 WARN=10 FAIL=0 |
| `verify-changelog-date-monotonicity.sh` | PASS | PASS=131 WARN=74 FAIL=0 |
| `verify-no-version-pins.sh` | PASS | PASS=198 WARN=0 FAIL=0 |
| `verify-arch-anchor-resolution.sh` | PASS | PASS=129 WARN=0 FAIL=0 |
| `verify-enum-variant-casing.sh` | PASS | PASS=198 WARN=0 FAIL=0 |
| `verify-adr-decision-refs.sh` | PASS | — |
| `verify-adr-self-version-refs.sh` | ADVISORY (non-blocking) | Non-blocking advisory |

**Headline process observation:** All 9 validators PASS while 130 findings exist. The validator suite is existence-checking, not semantics-checking. It cannot detect label-semantic errors, sub-anchor resolution failures, or claim-presence gaps. See process-gap class §F-P173-115/OBS-P173-B.

---

## Merge Register

Seven raw finding pairs resolved to single canonical findings before routing:

| Merged IDs | Disposition | Basis |
|------------|-------------|-------|
| F-P173-301 (CRIT) ≡ F-P173-402 (HIGH) | Carry as **F-P173-301 CRIT** | Two slices (slice 3 and slice 4) converged independently on same `eval::judge` BC mis-anchor. CRIT severity wins. |
| F-P173-302 ⊂ F-P173-401 | Carry as **F-P173-401** | F-P173-401 is the superset (three-document observability deadlock); F-P173-302 is a strict subset. |
| F-P173-305 (HIGH) ≡ F-P173-403 (MED) | Carry as **F-P173-305 HIGH** | Same "56 → 57" phantom string in live body. HIGH severity wins. |
| F-P173-312 ≡ F-P173-404 | Carry as **F-P173-312** | Both identify `module-criticality.md` body text "70 (68 tiered + 2 exempt)" as stale; correct values are 71/69/2. |
| F-P173-307 ≡ F-P173-801 | Carry as **F-P173-307/801** | Both identify 36 of 77 `verification-coverage-matrix.md` Module cells as non-canonical; same root cause. |
| F-P173-408 ≡ F-P173-814 | Carry as **F-P173-408/814** | VP-INDEX and `verification-architecture.md` Module dialect not canonicalized; same surface. |
| F-P173-210 ≡ F-P173-619 | Carry as **F-P173-619** | Both flag `#[non_exhaustive]` asymmetry on `StreamEvent`/`FerrochainError`; F-P173-619 is the superset (adds `ToolCallPreview`/`PreToolDecision` sibling asymmetry). |

---

## CRITICAL Findings (4)

All four independently verified by the orchestrator.

### F-P173-601 — CRIT — PathGuard Declared in Wrong Crate (product-owner + architect)

`interface-definitions.md` §ferrochain-tools declares `pub struct PathGuard { root: PathBuf }` with `pub fn check(&self, path: &Path)`, anchored to BC-2.23.001–006. Five artifacts disagree with this placement:

- `api-surface.md` does not list `PathGuard` under `ferrochain-tools`
- ADR-020 Decision 2 assigns sandbox path enforcement to `ferrochain-sandbox`
- `dependency-graph.md` shows no `ferrochain-tools → ferrochain-sandbox` edge
- `module-criticality.md` places `sandbox::path_guard` at CRITICAL tier, SS-13, VP-003
- `VP-003.md` names target `ferrochain-sandbox` and proof function `canonicalize_beneath_root`

**Consequence:** If implemented as written, the implementer builds a second unproven `PathGuard` in the wrong crate. VP-003 Kani P0 loses its proof target. The NE-02 mandatory-call invariant goes unenforced across all six first-party tools.

**Fix:** Delete the `PathGuard` struct and `check` function declaration from `interface-definitions.md` §ferrochain-tools. Replace with a consumption note: "Path enforcement delegated to `ferrochain-sandbox::canonicalize_beneath_root` per BC-2.13.004." Re-anchor BC-2.23.001–006 references to match the canonical location.

---

### F-P173-211 — CRIT — `FerrochainError` Non-Compilable Clone Derive (architect)

ADR-010 declares `#[derive(Debug, Clone)]` on `FerrochainError`. The `source` field is typed `Option<Box<dyn std::error::Error + Send + Sync>>`. `Box<dyn Trait>` does not implement `Clone`. This produces `error[E0277]` at the first build of `ferrochain-core::error` — Wave 0, CRITICAL-tier, before any other crate can compile. The issue is invisible from `api-surface.md` because that document reproduces only 4 of 6 `FerrochainError` fields (see F-P173-202), omitting the `source` field entirely.

**Fix:** Architect adjudicates one of: (a) change `source` to `Option<Arc<dyn std::error::Error + Send + Sync>>` — preserves `Clone`, maintains the error chain; (b) drop `Clone` from the derive — errors rarely need cloning; (c) hand-implement `Clone` with a source-chain truncation. Choice propagates to `api-surface.md` §Error Type (add the `source` field with its resolved type) and BC-2.14.001 (add the `source` field to the canonical struct definition).

---

### F-P173-104 — CRIT — `ferrochain-tools` Declared Dependent on `ferrochain-graph` (business-analyst)

`domain-spec/bounded-contexts.md` §Context Dependency Order lists `ferrochain-graph` as a direct compile-time dependency of `ferrochain-tools`. ADR-020 Decision 1 states verbatim: "`ferrochain-tools` does NOT depend on `ferrochain-graph` at compile time." This absent edge is the load-bearing premise of the D-24 `ActionRisk` relocation to `core::action_risk`. If the devops-engineer uses `bounded-contexts.md` §Context Dependency Order as the source of truth for `Cargo.toml` workspace dependencies at workspace init, the `ferrochain-tools` crate will be wired with the prohibited `ferrochain-graph` dep.

**Fix:** Remove `ferrochain-graph` from the `ferrochain-tools` dependency list in `bounded-contexts.md` §Context Dependency Order. Add inline note citing ADR-020 Decision 1 and the D-24 `ActionRisk`-from-core rationale.

---

### F-P173-301/402 — CRIT — `eval::judge` Mis-Anchored to BC-2.08.013/014 (architect)

`eval::judge` is anchored to BC-2.08.013 ("Pluggable Tool-Call Dialect Seam") 7 times and BC-2.08.014 ("Provider Failover Chain") 2 times across five artifacts: `module-decomposition.md` (2 sites), `module-criticality.md`, `purity-boundary-map.md`, `verification-coverage-matrix.md`. The correct anchor is BC-2.08.008 ("Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome, NE-15"). `observability.md` and BC-INDEX already carry BC-2.08.008 correctly. `prd.md` assigns BC-2.08.013/014 to different crates entirely. Two independent slices (3 and 4) converged on this finding.

**Fix:** Replace all BC-2.08.013/014 citations for `eval::judge` across the five affected artifacts with BC-2.08.008. Verify `observability.md` and BC-INDEX remain the reference standard.

---

## Architect — HIGH Findings

| ID | Severity | Title | Fix Essence |
|----|----------|-------|-------------|
| F-P173-105 | HIGH | VP-012 anchored to ADR-019 Dec 2 not Dec 3 step 1; symbol `on_watermark` phantom vs real `check_watermark_trigger`; property misstated | Re-anchor VP-012 to ADR-019 Decision 3 step 1; replace `on_watermark` with `check_watermark_trigger` throughout VP-012 body |
| F-P173-201 | HIGH | `BudgetConfig`/`CompactionTrigger`/`ProvenanceTag` catalogued under `ferrochain-graph` in `api-surface.md`; these are `ferrochain-core` types — placing them in graph creates a circular `core→graph` dep | Move all three type rows to the `ferrochain-core` section |
| F-P173-202 | HIGH | `FerrochainError` reproduced with 4 of 6 fields in `api-surface.md`; `message` (credential-safety constraint) and `source` (error chain) fields omitted | Add missing `message` and `source` fields with types and constraints |
| F-P173-203 | HIGH | `CompactionEvent` given a standalone Public Types row; it is a `StreamEvent` variant, not a top-level type | Remove standalone row; add `CompactionEvent` as a variant entry under the `StreamEvent` enum section |
| F-P173-204 | HIGH | `PathGuard` row in `api-surface.md` pairs BC-2.13.004 with E-TOOLS-001; BC-2.13.004 raises E-SBXD-001 | Correct error code to E-SBXD-001 |
| F-P173-205 | HIGH | `api-surface.md` §Public Rust Traits omits the D21 trait layer entirely: `Retriever`, `Embeddings`, `LcSerializable`, `MemoryWriteGuard`, `ToolCallDialect`; also no trait section for 5 crates | Add missing trait entries; add trait sections for omitted crates |
| F-P173-206 | HIGH | `api-surface.md` §Cargo Feature Flags documents 6 of 10 flags; omits security-relevant `sandbox-process` and 3 others | Add the 4 missing feature flag rows including `sandbox-process` with its security annotation |
| F-P173-207 | HIGH | F-P170-03 qualified `PreToolCallHook` crate attribution in `api-surface.md`; left `PreToolDecision`/`ToolCallPreview` siblings unqualified | Apply same qualification to all three sibling types consistently |
| F-P173-304 | HIGH | burst-275 recorded a quintuple census verification; the mandated sextuple (identity 3: composite-key uniqueness) was never recorded as evaluated | Record identity 3 evaluation explicitly in `bc-authoring-plan.md` gate #25 body |
| F-P173-305 | HIGH | `module-decomposition.md` live body contains "Module universe 56 → 57"; actual universe is 71/69; "56" is a phantom that survived multiple passes | Replace "56 → 57" prose with correct current count; audit the surrounding paragraph for all stale count references |
| F-P173-307/801 | HIGH | 36 of 77 `verification-coverage-matrix.md` Module column cells use non-canonical module names (e.g. `graph` vs `ferrochain-graph::graph_executor`); census join on Module field mechanically impossible | Canonicalize all 36 non-canonical Module cells to the `crate::module` form from `module-decomposition.md` |
| F-P173-501 | HIGH | VP-001 proves a weaker sort property: drops the `channel_name` tiebreaker field and models `TaskId(u64)` numerically where BC-2.01.001 mandates lexicographic string sort | Extend VP-001 harness to include `channel_name` in the sort key and change `TaskId` model to string |
| F-P173-503 | HIGH (escalated from MED) | VP-009 else-branch: if both vectors have zero norm, `a=b=[1e30f32]` causes norm overflow to `+Inf`; `Inf/Inf = NaN`; the zero-norm guard never fires; BC-2.21.003 Invariant 3 "No NaN in any output path" is unsatisfiable by a zero-norm-only guard | Fix VP-009 harness to include infinity/overflow guard; **escalate to product-owner**: BC-2.21.003 Invariant 3 requires a pre-normalization overflow check that the current property text does not specify |
| F-P173-504 | HIGH | Stale `(Red Gate)` labels remain in VP-012 and VP-013 body text — siblings of the closed VP-011 `red_gate` fix in burst-248 | Remove `(Red Gate)` labels from VP-012 and VP-013 everywhere `red_gate: false` is the correct value |
| F-P173-701 | HIGH | `interface-definitions.md` §VectorStore: 2 of 4 paren-interleaved ADR-014 citation labels point at wrong decisions; `InMemoryVectorStore` attributed to ADR-014 Decision 4 but is ADR-017 Decision 4 | Correct the two mis-cited labels; `InMemoryVectorStore` → ADR-017 Decision 4 |
| F-P173-706 | HIGH | ADR-012 asserts frozen 18-crate roster at 3 sites; canon is 21 crates; ADR-013 has 3 additional sites with 18-crate count; ADR-007 was forward-amended but its siblings were not | Update all sites in ADR-012 and ADR-013 to 21-crate count; add forward-amendment notes where missing |
| F-P173-802 | HIGH | `system-overview.md` P-06 asserts an edge that `dependency-graph.md` §Invariant explicitly forbids; edge direction is ambiguous in both arrow readings; the `graph→checkpoint` edge is omitted | Remove the forbidden edge; resolve arrow ambiguity; add the missing `graph→checkpoint` edge |
| F-P173-803 | HIGH | `verification-coverage-matrix.md` tier summary claims proptest coverage "all"/"most"; actual coverage is 3 of 12 CRITICAL tiers and 7 of 28 HIGH tiers; `tooling-selection.md` gates 12/12 and 28/28 | Correct the summary to reflect actual 3/12 and 7/28 proptest coverage; update `tooling-selection.md` gates to match |

## Architect — MED/LOW Findings (to fix-burst 276)

IDs listed by slice; full details in orchestrator dispatch notes. Fix: route to architect for fix-burst 276.

**Slice 1a (MED/LOW):** F-P173-108, F-P173-109
**Slice 2a (MED/LOW):** F-P173-208, F-P173-209, F-P173-212, F-P173-213, F-P173-214
**Slice 3 (MED/LOW):** F-P173-303 (process-gap class — see §Process-Gap), F-P173-306 (process-gap class), F-P173-308, F-P173-309, F-P173-310, F-P173-311, F-P173-313, F-P173-314, F-P173-315, F-P173-316, F-P173-317, F-P173-318, F-P173-319 (process-gap class)
**Slice 5 (MED/LOW):** F-P173-502, F-P173-506, F-P173-507, F-P173-508, F-P173-509, F-P173-510, F-P173-511, F-P173-512, F-P173-513, F-P173-514, F-P173-515, F-P173-516
**Slice 2b (MED/LOW):** F-P173-617, F-P173-623
**Slice 1b (MED/LOW):** F-P173-707, F-P173-709 (formal-verifier, see below), F-P173-714
**Slice 2c (MED/LOW):** F-P173-804, F-P173-805, F-P173-806, F-P173-807, F-P173-808, F-P173-809, F-P173-810, F-P173-811, F-P173-812, F-P173-813, F-P173-815, F-P173-816, F-P173-817; F-P173-408/814 (see Merge Register)

---

## Product-Owner — HIGH Findings

| ID | Severity | Title | Fix Essence |
|----|----------|-------|-------------|
| F-P173-101 | HIGH | §PreToolCallHook `Source:` line in `interface-definitions.md` omits ADR-020 Decision 1 (sole authority for the trait signature); fail-closed Deny cited to Decision 4 instead of Decision 3 step 4 | Add ADR-020 Decision 1 as primary source; correct fail-closed Deny anchor to Decision 3 step 4 |
| F-P173-102 | HIGH | §Compaction `Source:` line misattributes `CompactionPolicy` trait and mid-run/next-run distinction; self-contradicts 20 lines below | Correct source attribution; align both mentions of mid-run/next-run to the ADR-019 canonical definition |
| F-P173-401 | HIGH (carries -302) | Three-document `eval::judge` observability deadlock: `observability.md`, `BC-2.08.008`, and BC-INDEX each claim a pending note closure that never landed; two changelogs claim closure of an action never effected; contains forbidden "pending architect Wave B" deferral | Close all three open-note references; remove "pending architect Wave B" deferral; record actual closure state |
| F-P173-602 | HIGH | `bind_tools` in `interface-definitions.md` returns bare `impl BaseChatModel`; BC-mandated E-CORE-005 unreachable from opaque return; also `async fn → impl Trait` nested-impl does not compile | Change return type to `Arc<dyn BaseChatModel>` or a named concrete type; remove illegal nested-impl syntax |
| F-P173-603 | HIGH | `with_structured_output` in `interface-definitions.md` drops the `schema` parameter that every BC-2.08.003 PC/EC/TV requires; missing `schemars::JsonSchema` bound | Add `schema: &dyn schemars::JsonSchema` parameter; add `T: schemars::JsonSchema` bound |
| F-P173-604 | HIGH | `pipe` returns opaque `impl Runnable` making BC-2.01.004 PC4 flattening and TV-002 structural assertion impossible | Change return type to `RunnableSequence` (load-bearing concrete type per ADR-005) |
| F-P173-605 | HIGH | `DynRunnable` and `RunnableSequence` — both load-bearing per ADR-005 — are undeclared in `interface-definitions.md` | Add canonical declarations for both types with their ADR-005 anchors |
| F-P173-606 | HIGH | `ChatConfig` marked "corpus-unresolved / implementer defines" while `module-decomposition.md` places it in `core::config` and BC-2.08.014 PC1 names a required field | Resolve ChatConfig: define fields from BC-2.08.014 PC1 and `module-decomposition.md`; remove "corpus-unresolved" marker |
| F-P173-607 | HIGH | `ProviderCredential`/`CredentialRefreshConfig` flagged "for architect review" dropping the DI-010 redacted-Debug credential obligation | Remove architect-review flag; apply DI-010: implement `Debug` as `<redacted>` for both types |
| F-P173-608 | HIGH | `ToolConfig::override_risk(self, risk)` has no tool-identity parameter; cannot discriminate BashTool's Medium floor from ReadOnly defaults; VP-013 unprovable as declared | Add a tool-identity parameter or rework the discriminator; ensure the Medium floor for BashTool is enforceable |
| F-P173-609 | HIGH | The `Tool` trait (implemented by every tool) is undeclared in `interface-definitions.md` though cited twice | Declare the `Tool` trait with its BC-anchored method signatures |
| F-P173-610 | HIGH | `ProviderFallbackPolicy.chain` is public with no fallible constructor; defeats the non-empty-at-construction invariant; the VAL error code for this invariant has no minted code | Add a constructor `new(chain: Vec<ProviderConfig>) -> Result<Self, FerrochainError>` that validates non-empty; mint the VAL error code |

## Product-Owner — MED/LOW Findings (to fix-burst 276)

IDs: F-P173-103, F-P173-107, F-P173-114, F-P173-406, F-P173-407, F-P173-611, F-P173-612, F-P173-613, F-P173-614, F-P173-615, F-P173-616, F-P173-618, F-P173-619 (merged from F-P173-210), F-P173-620, F-P173-621, F-P173-622, F-P173-703, F-P173-704, F-P173-705, F-P173-708, F-P173-710, F-P173-713, F-P173-715.

**Notably:** F-P173-406 — BC-2.07.003 PC1/PC2 mandate a 1-element list while PC5/TV-004 mandate `[]` for the empty-string Precondition 3; guaranteed Phase-3 red-gate stall. F-P173-407 — DEC-013 orphan; a prior pass recorded a false "13/13 with explicit DEC" closure.

---

## Business-Analyst Findings

| ID | Severity | Title | Fix Essence |
|----|----------|-------|-------------|
| F-P173-104 | CRIT | `bounded-contexts.md` asserts `ferrochain-tools→ferrochain-graph` dep; ADR-020 Decision 1 explicitly forbids it | See §CRITICAL Findings above |
| F-P173-106 | HIGH | CAP-038 instructs "confirm `regex` is already a workspace dependency"; ADR-020 Decision 7 resolved it is NOT — a resolved question re-opened | Update CAP-038 to state `regex` is confirmed NOT a workspace dep per ADR-020 Decision 7; remove the "confirm" instruction |
| F-P173-702 | HIGH | CAP-029 attributes `InMemoryVectorStore` + Arc-DI to ADR-014 Decision 4; correct attribution is ADR-017 Decision 4 | Correct CAP-029 source attribution to ADR-017 Decision 4 |
| F-P173-110, -111, -112, -113 | MED/LOW | Domain-spec minor anchoring and consistency gaps | Route to business-analyst for fix-burst 276 |
| F-P173-712 | LOW | Minor domain-spec inconsistency | Route to business-analyst for fix-burst 276 |

---

## Formal-Verifier Findings

| ID | Severity | Title | Fix Essence |
|----|----------|-------|-------------|
| F-P173-709 | MED | VP body file anomaly — VP property text inconsistency requiring formal-verifier adjudication | Route to formal-verifier for fix-burst 276 |

---

## State-Manager Findings

| ID | Severity | Title | Fix Essence |
|----|----------|-------|-------------|
| F-P173-410 | LOW | STATE.md / cycle-file consistency gap — minor bookkeeping discrepancy | Self-repair in this state-record burst |
| F-P173-505 | HIGH (process-gap) | `input-hash` frontmatter contradicts changelog-recorded values in VP-008, VP-009, VP-010; VP-009 changelog cites a pair of content-hash digests that do not match the `input-hash` frontmatter field; recording literal hash digests as changelog prose is a TD-VSDD-091 family violation | Replace hash-digest references in the VP-008/VP-009/VP-010 changelog entries with artifact-name + section anchors; correct `input-hash` frontmatter to `[live-state]`; add a `records-lint.sh` L9 check for bare hash-digest literals |

---

## Process-Gap Class (Distinct from Content Findings)

These are structural gate failures — the most high-leverage items for fix-burst 276. Fix process gates BEFORE content findings.

### F-P173-303 — HIGH — Blocking Identity 1 Is a Tautology (fourth generation)

`bc-authoring-plan.md` gate #25 Part C blocking identity 1 (`total == tiered + exempt`) is a tautology. All four failure modes the gate text claims it detects still satisfy it: (a) a module counted in both tiers; (b) a module excluded from both; (c) a misclassified module; (d) an extra module in one list not the other. This is the F-P172b-05 shape one level above the clause commissioned to fix it — the fourth generation of the unfalsifiable-suppression defect. The orchestrator self-attributes defect (b) in §Orchestrator Self-Attributed Defects below.

**Fix:** Replace identity 1 with a set-operation check: print the difference set `(tiered_modules − registry_modules)` and assert it is empty. The assertion must include the diff output inline, not just the count. No count claim is acceptable without the derivation and the printed diff.

### F-P173-306 — HIGH — Crate-Level Annotation Verification Returns False PASS

The crate-level annotation verification in `bc-authoring-plan.md` gate #26 uses a module-name-prefix grep (`standard_tests::`) to check for annotations. For `ferrochain-standard-tests` (which owns `eval::judge`), this grep returns 0 results — a false PASS. The validator minted to catch exactly that class of missing annotation is itself vulnerable to a module-prefix mismatch.

**Fix:** Replace the module-name-prefix grep with a structural check: assert the presence of an explicit annotation element (e.g., `crate_level_annotation:` or equivalent frontmatter key) rather than a code pattern that may not appear in a test-helper crate.

### F-P173-319 — MED — Gate #25 Part C `awk` Field Extraction Re-Broken

The `awk '{print $2, $3}'` command in gate #25 Part C was re-broken by the Qualifier column insertion in burst-275. The Crate column moved to `$4`; the command now extracts wrong fields. This is the second break of the same command: F-P170-15 fixed `$4→$3` one burst earlier. Hardcoded field indices next to a mutating table are a defect generator.

**Fix:** Replace field-index extraction with a header-named extraction (e.g., use `awk -v col=... NR==1 { ... }` or `cut --complement`) that does not require updating when columns change.

### F-P173-308, -309, -310 — MED — Gate Self-Consistency Failures

- F-P173-308: Gate #26 names a nonexistent "Criticality" column; the recount degenerates into the prohibited mirroring pattern.
- F-P173-309: `registry_rows` field is self-contradictory: 77 vs 76 appear in adjacent sentences. This is the generation-2 ambiguity shape (count-without-derivation) recurring.
- F-P173-310: Class A inverse assertion has no verification obligation; an absence claim is stated without a falsifiability mechanism.

**Fix:** Each gate must name only columns that exist; every count must appear with its derivation and a falsifiability mechanism.

### F-P173-115 and OBS-1b — Recommended Mechanical Checks for ADR Citation Validator

The `verify-adr-decision-refs.sh` validator is existence-only: it checks that a cited ADR file exists at a cited decision number. 10 of slice 1b's 15 findings cite a real ADR at a real decision number and fail only on label semantics, sub-anchor resolution, or claim presence. Three recommended mechanical additions:

1. Assert that a `§SubAnchor` marker is a heading nested under `## Decision M` in the cited ADR body.
2. Assert that each parenthetical label's distinctive noun phrase appears within the cited decision's text span.
3. **Reverse coverage:** flag any accepted-ADR decision with zero inbound citations — a decision cited by nothing while other artifacts incorrectly cite the same ADR for its content (as with ADR-017 Decision 4) is a defect signal.

### OBS-P173-B — No Mechanical Canonicality Gate for Module-Name Quartet

No mechanical gate verifies that the module-name quartet (`module-criticality.md`, `module-decomposition.md`, `purity-boundary-map.md`, `verification-coverage-matrix.md`) plus the VP family uses consistent canonical module identifiers. Census identities are hand-computed assertions no future pass can cheaply re-verify — the same condition that allowed the phantom "56-module universe" to survive ~170 passes.

**Recommendation:** Mint a validator that extracts all Module-column values from the quartet, compares them against `module-decomposition.md` as the canonical source, and fails on any non-canonical form.

### F-P173-505 (process-gap restatement) — Hash Digest Citations in VP Changelogs

VP-008/VP-009/VP-010 changelogs contain literal content-hash digest strings as evidence of input-file identity. `records-lint.sh` L9 gates `file.rs:NNN` patterns but not hash-literal patterns. Both are TD-VSDD-091 family violations: they are volatile identifiers that become stale when the source file changes and provide no behavioral anchor for future passes.

---

## Verified-Clean Surfaces

The following surfaces are confirmed **genuinely converged**. Each was independently reproduced by the adversary; orchestrator confirmed the key items by set operations. Future passes should treat these as high-confidence unless a content-modifying burst touches them.

**Census arithmetic (independently reproduced):**
- 129 BCs: 51 P0 / 75 P1 / 3 P2 — frontmatter-verified
- Red Gate: 11 confirmed four independent ways
- 38 CAPs: zero orphans both directions
- 15 DIs: zero orphans; 564 DI references across 103 BC files
- 13 VPs: 6 P0 + 7 P1 = 9 Kani + 2 proptest + 2 integration (arithmetic closes)
- 108 error codes: zero duplicates; 3 documented tombstones; 12 categories; 17 components
- 674 test vectors: 663 canonical + 11 GTV; per-subsystem subtotals all reconciling
- 11 event_types: bidirectionally complete (BC↔observability catalog)
- 17/17 NE anchoring: complete
- 21 crates: derivation recomputed independently
- 20 ADR files: no phantom ADR-021+
- 14 bounded contexts; 15 StreamEvents; 19 FMs; 13 DECs; 9 ASMs; 8 Rs; 14 NFRs
- 77 registry rows: per-tier splits CRITICAL 12 / HIGH 28 / MEDIUM 35 / LOW 2 = 77
- Purity: 82 rows = 33 Pure Core + 37 Effectful Shell + 12 Boundary = 71 decomp + 4 Class A + 6 crate-level + 1 dual-aspect (reconciling)
- Census sextuple: `(71, 69, 2, 77, 76, 69)` — both difference sets empty; confirmed by two parties independently

**Structural integrity:**
- VP-002 and VP-006 symbol chains: clean
- Zero phantom error codes
- All `supersedes`/`superseded_by` fields: bidirectionally consistent
- ADR-005 §Adjacent Trait Object-Safety Adjudications: Runnable/BaseChatModel dyn axis closed — do not re-open
- Domain C (OpenClaw): verified legitimate across 21 spec files

**Semantics:**
- BC-2.08.008 anchor in observability.md and BC-INDEX: correct (finding F-P173-301 is a prose-propagation failure, not a source-of-truth error)
- ADR-019 compaction type canon: closed (burst-252)
- Category::VALIDATION purge: complete (burst-269)
- PascalCase/Direction-B: complete (burst-270)

---

## Summary

| Metric | Value |
|--------|-------|
| Pass | P1D-173 |
| Head frozen at | `8954a11` |
| Method | 8 fresh-context slices |
| Raw findings | 130 |
| After merges | ~122 unique |
| CRIT | 4 |
| HIGH | ~22 |
| MED | ~50 |
| LOW/OBS | ~46 |
| Process-gap class | 7 structural gate findings |
| All validators | PASS (existence-checking only) |
| New surfaces audited | `api-surface.md`, `interface-definitions.md`, `verification-coverage-matrix.md`, `system-overview.md`, all 13 VP bodies |
| **CLEAN (strict)** | **no** |
| **CLEAN (PR-merge)** | **no** |
| Streak | 0/3 (unchanged) |
| Total adversary passes | 174 |
| Trajectory tail | →19→20→130 |
| Next action | fix-burst 276 — process-gap gates FIRST (F-P173-303/306/319/308/309/310), then content by ownership wave |

**Jump note:** The 130-finding jump from the ~20/pass plateau is a **coverage expansion artifact**, not a regression. Slices 2a, 2b, and 5 read `api-surface.md`, `interface-definitions.md`, and all 13 VP bodies at method granularity for the first time in 173 passes. The plateau of ~20 findings/pass was re-auditing audited surfaces; these three surfaces were never in scope.

### Orchestrator Self-Attributed Defects (recorded by orchestrator)

1. Instructed the adversary to write findings incrementally to a report file during the full-perimeter pass. The adversary tool profile is read-only (no Write, no Bash); three dispatches were lost before this was diagnosed. The correct mitigation (bounded slices) was applied starting slice 1a.
2. The F-P172b-05 fix commissioned in burst-275 produced blocking identity 1 (`total == tiered + exempt`) in gate #25 Part C. F-P173-303 shows this is a tautology that advertises four detection capabilities it cannot perform. This is the fourth generation of the unfalsifiable-suppression defect shape, and it was commissioned by the orchestrator.
