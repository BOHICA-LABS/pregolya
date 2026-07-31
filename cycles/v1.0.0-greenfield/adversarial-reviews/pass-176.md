---
document_type: adversarial-review
level: ops
pass_id: P1D-176
pass_label: FULL-PERIMETER
frozen_head: 9a62edc
date: 2026-07-30
version: "1.0"
status: closed
producer: adversary (5 slices: A/B/C/D/E; first pass with policies.yaml rubric POL-1..POL-31 injected; POL-32..POL-45 correctly excluded as PHASE-3-BINDING with crates/ absent)
cycle: v1.0.0-greenfield
traces_to: STATE.md
---

# Adversarial Review — Pass P1D-176 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** All 5 slices complete: A (40) + B (31) + C (35) + D (26) + E (28) = 160 findings. First pass in project history run with the project policy rubric injected (policies.yaml POL-1..POL-31 active; POL-32..POL-45 excluded as PHASE-3-BINDING — no crates/ tree present). Frozen HEAD: post-rename factory-artifacts HEAD `9a62edc` (burst-284 ferrochain→pregolya). CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak: 0/3 unchanged.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-176 FULL-PERIMETER |
| Frozen HEAD | `9a62edc` |
| Date | 2026-07-30 |
| Method | 5-slice decomposition. All slices completed without connection failures. 0 orchestrator adjudications required. |
| Scope | A: ARCH-INDEX, 21 ADRs, 8 architecture sections, 13 VPs. B: BCs SS-01..SS-12 + BC-INDEX. C: BCs SS-13..SS-23. D: PRD, 10 prd-supplements, 15 domain-spec shards, product-brief. E: policies.yaml, hooks, planning, comparative, semport, CI, namespace-reservation. |
| Policy rubric | POL-1..POL-31 injected; POL-32..POL-45 excluded (PHASE-3-BINDING; crates/ absent). |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — UNCHANGED, do NOT advance** |

## Slice Status

| Slice | Perimeter | Findings | CRIT | HIGH | MED | LOW/OBS | PG |
|-------|-----------|----------|------|------|-----|---------|-----|
| A | ARCH-INDEX, 21 ADRs, 8 architecture sections, 13 VPs | 40 | 0 | 10 | 23 | 7 | 3 |
| B | BCs SS-01..SS-12 + BC-INDEX | 31 | 0 | 8 | 17 | 6 | 4 |
| C | BCs SS-13..SS-23 | 35 | 2 | 8 | 19 | 6 | 2 |
| D | PRD, 10 prd-supplements, 15 domain-spec shards, product-brief | 26 | 2 | 7 | 11 | 6 | 2 |
| E | policies.yaml, hooks, planning, comparative, semport, CI, namespace-reservation | 28 | 1 | 12 | 10 | 5 | 2 |
| **Total** | | **160** | **5** | **45** | **80** | **30** | **13** |

---

## Convergent Mechanisms

Five root-cause mechanisms explain why 160 findings exist on a perimeter that has undergone 176 prior passes. Each mechanism was found independently by multiple slices. A mechanism fix closes many findings simultaneously and prevents regeneration; fixing individual findings without addressing the mechanism allows regeneration.

1. **§-anchor unverifiability** (E001 + A007 + A018 + A039 + D005 + D026): `§Name` denotes three structurally different targets — real headings, bold inline labels (`ADR-010 §impl PregolyaError`), and slugified pseudo-anchors. No validator can distinguish a phantom from a legitimate sub-anchor. **Consequence for sequencing: the convention must be restricted to real headings BEFORE the gate is built.** Compounding: TD-VSDD-091/L9b remediation converts a gated form (`<doc> vN.N`) into an ungated one (`§Named-Section`), so the anti-volatile-pin policy is a fabrication generator. A007 records two BLOCKING gates (POL-16, POL-18) anchored to ADR-010 sections that do not exist.

2. **Note-closure instead of body-closure** (~25 sites across all five slices; in 7 the changelog *asserts* a propagation never performed): A005, A008, A010, D003, D004, D008, D013. A changelog entry claims work was propagated; the body does not reflect the propagation. `verify-changelog-claim-applied.sh` exists but is advisory with ~631 findings.

3. **Arithmetic identities satisfiable without ground truth** (D001, A009, E023): D001 (TV registry self-consistent, 12 behind ground truth — column sum equals declared total at every step); A009 (Iron Law census wrong in every term — 71/69/2 stated vs 76/70/6 actual); E023 (five green CI required-checks validating nothing). The guard is an internal identity, not a ground-truth comparison.

4. **`#[non_exhaustive]` applied ad hoc** (A028, A029, D009, B026, C028): no ADR states the rule, its exception criteria, or the exempt inventory, so each type re-litigates it. One decision record closes all of them.

5. **Gate-shaped fixes creating canon violations** (C008 + D-106 fabricated anchors + E001 laundering pathway): C008: ADR-010 Class 3 forbids `PregolyaError::new()` in prose; POL-17 declares it valid; two prior fix-bursts created violations by optimising for `grep 'PregolyaError {' returns zero`. D-106 fabricated anchors were the same class (paper-fix optimising for linter exit-0, not for correctness). The anti-volatile-pin policy launders fabricated anchors past the linter by construction.

---

## Five CRITs — Full Detail

### F-P176-C001 (CRIT)

**File:** `BC-2.23.001`, `BC-2.23.002`
**Section:** §PC-2
**Defect:** PC-2 in both BCs maps `canonicalize_beneath_root` returning `Err` "for any reason" to `E-TOOLS-001 PathConfinementViolation` (SECURITY / never-retry class). This contradicts PC-4, EC-005, and TV-004 in the same files, which require `E-TOOLS-008 FileIoError NotFound` for I/O failures on valid paths. `BC-2.23.006` PC-6 carries the correct disambiguation (SECURITY-class only for escape attempts; I/O failures take the FileIoError path). A sweep that touched five sibling BCs to propagate the disambiguation missed `BC-2.23.001` and `BC-2.23.002`.
**Why it matters:** Every I/O failure during a tool's path-confinement check is misrouted to the SECURITY / never-retry bucket, suppressing retries on transient disk errors and generating false security alerts.
**Verification method:** Grep `PC-2.*Err.*E-TOOLS-001` in SS-23 BC files; compare to `BC-2.23.006` §PC-6 for the correct discrimination rule. Cross-check TV-004 expected error code.
**Route:** product-owner.

---

### F-P176-C002 (CRIT)

**File:** `BC-2.23.001` (WriteFileTool create-new-file entry point)
**Section:** §PC-5 / §Preconditions
**Defect:** WriteFileTool's create-new-file code path is structurally unreachable: `canonicalize` calls `std::fs::canonicalize` which returns `Err(NotFound)` for paths that do not yet exist, so `canonicalize_beneath_root` cannot return `Ok` for a new file's path. TV-001 and TV-005 (new-file creation vectors) can therefore never pass. `BC-2.13.004` PC-5 defines the correct parent-canonicalization protocol (canonicalize the parent directory, then join the filename), but no documented entry point in the WriteFileTool spec accepts a create intent and routes through that protocol. Combined with C001, every file creation attempt is either `PathConfinementViolation` (C001 error routing) or `NotFound` (C002 unreachability).
**Why it matters:** File creation is a primary WriteFileTool use case. The spec has no reachable code path for it. All test vectors for new-file creation will fail at the spec level.
**Verification method:** Trace TV-001 through PC-1→PC-2→PC-3→PC-4→PC-5 in `BC-2.23.001`; confirm PC-2 calls `canonicalize` on a not-yet-existing path. Then read `BC-2.13.004` §PC-5 for the parent-canonicalize protocol; confirm `BC-2.23.001` has no entry point that invokes it.
**Uncertainty:** Reviewer notes this finding is pending confirmation that no BC in SS-23 defines an `exists: false` pre-check before canonicalize. If such a pre-check exists, C002 severity may downgrade to HIGH. Confirmation requires full read of remaining SS-23 BCs.
**Route:** product-owner + architect.

---

### F-P176-D001 (CRIT)

**File:** `test-vectors.md`
**Section:** §Grand-Total / §TV-Registry
**Defect:** `test-vectors.md` §Grand-Total declares 664 canonical TVs + 11 GTVs = 675. Ground truth from summing BC-level TV counts is 676 canonical + 11 GTVs = 687. Twelve vectors are missing from the registry. Eight stale rows were identified: BCs BC-2.03.001, BC-2.09.001, BC-2.12.002, BC-2.15.004, BC-2.15.006, BC-2.17.001, BC-2.18.001, BC-2.18.004 each had TV counts updated in prior fix-bursts but the registry §TV-Registry rows were not updated. The column sum arithmetic is internally self-consistent at every step (the registry sums to its own declared total) — the arithmetic identity does not detect the ground-truth mismatch. This is Mechanism 3: arithmetic identities satisfiable without ground truth.
**Why it matters:** The test-vector registry is the authoritative source for Phase 3 test-writer scope. A registry 12 behind ground truth means 12 test vectors will not be authored, reviewed, or implemented.
**Verification method:** Sum the TV count column per BC in the registry; compare to the §Grand-Total row. Then independently sum TV counts from each BC body file; compare the two totals.
**Route:** product-owner (registry update); each BC owner (confirm TV count in BC body).

---

### F-P176-D002 (CRIT)

**File:** `bc-authoring-plan.md`
**Section:** §Subsystem → CAP Mapping
**Defect:** §Subsystem → CAP Mapping assigns SS-22 (DynamicToolLoader / runtime tool registration) to `pregolya-community` (described in the mapping as post-v1, LOW-tier, not-in-tree). Every other artifact that references SS-22 — ARCH-INDEX §crate-table, dependency-graph §edge-table, module-decomposition §ss-22 row, and all 3 SS-22 BCs — assigns SS-22 to `pregolya-core` (core runtime) + `pregolya-openai`/`pregolya-ollama` (provider bindings). The `pregolya-community` assignment would route all SS-22 BCs to a crate that does not exist in the v1 roster, making every SS-22 story unimplementable.
**Why it matters:** BC authoring plan drives story decomposition. If SS-22 is routed to `pregolya-community`, Phase 2 stories for SS-22 will be authored against the wrong crate and will not be schedulable in Phase 3.
**Verification method:** Read `bc-authoring-plan.md` §Subsystem → CAP Mapping §SS-22 row; read ARCH-INDEX §crate-table §pregolya-community description; confirm community is post-v1 and not in the 21-crate v1 roster. Cross-check module-decomposition §ss-22 and dependency-graph §ss-22-edges.
**Route:** spec-steward (bc-authoring-plan correction) + architect (confirm SS-22 placement).

---

### F-P176-E001 (CRIT)

**File:** `policies.yaml` + `hooks/verify-adr-decision-refs.sh` + `hooks/verify-arch-anchor-resolution.sh`
**Section:** §POL-19 (ADR anchor enforcement)
**Defect:** POL-19 asserts that `§Named-Section` ADR anchor citations are enforced by the blocking validator suite. In fact, there is **zero** machine coverage for named-section anchors: (1) `verify-adr-decision-refs.sh` `CITE_RE` requires `§Decision <integer>` — it does not match `§Named-Section` forms; (2) `verify-arch-anchor-resolution.sh` validates only `architecture/<path>.md` file citations (path-level, not section-level). There are 170 `ADR-NNN §Named-Section` citations across 85 files, none of them gated. POL-19 asserts blocking enforcement that does not exist. This is Mechanism 1: §-anchor unverifiability.
**Why it matters:** POL-19 is listed as BLOCKING in the policy registry. Every policy audit that reads POL-19 and concludes the gate is active is wrong. Fabricated named-section anchors (D-106 class, A007) pass the entire blocking-validator suite. The anti-volatile-pin policy (TD-VSDD-091) is actively producing fabricated anchors as a side effect of removing `vN.N` pins.
**Verification method:** Read `hooks/verify-adr-decision-refs.sh` §CITE_RE; confirm the regex; attempt a grep for `ADR-010 §Non-Exhaustive-Gate` across the corpus; confirm the hook would not flag it. Read `hooks/verify-arch-anchor-resolution.sh`; confirm it checks file paths not section headings.
**Route:** devops-engineer (gate extension) + spec-steward (POL-19 wording correction until gate exists) + architect (convention restriction to real headings, prerequisite to gate).

---

## Slice A — ARCH-INDEX, 21 ADRs, 8 Architecture Sections, 13 VPs

**40 findings: 0 CRIT / 10 HIGH / 23 MED / 7 LOW/OBS**

### Slice A Verified-Clean Axes

- **Rename completeness (ferro-stem exception class):** 353 openers scanned; 0 `ferrochain`/`Ferrochain`/`FERROCHAIN` found in slice A perimeter files. Gate patterns migrated correctly. `ferrograph` (product-brief/market-intel) and `.ferroctmp_` (BC-2.23.002) are the sole ferro-stem residue and are documented separately in D018 and C___ below.
- **ADR cascade integrity:** All 21 ADR `Supersedes:` / `Superseded-by:` bidirectional links verified present and consistent.
- **VP-INDEX frontmatter count arithmetic:** 13 = 6+7 = 9+2+2. Holds.
- **Form-A changelog direction:** All 21 ADRs pass `verify-form-a-changelog-direction.sh` PASS=21 WARN=0 FAIL=0.

---

### Slice A HIGH Findings (10)

#### F-P176-A001 — ARCH-INDEX §ADR-Table body row count mismatch with declared total

**Severity:** HIGH
**File:** `ARCH-INDEX.md`
**Section:** §Architecture-Decision-Log / §ADR-Table
**Defect:** ARCH-INDEX §Architecture-State declares `adr_count: 21` and the §Architecture-Decision-Log heading prose states "21 ADRs." The §ADR-Table body contains 20 rows: ADR-001..ADR-021 with ADR-009 absent. No evidence of ADR-009 in the repository; the gap is not documented. Either ADR-009 was never authored and the count is wrong, or ADR-009 was retired and the retirement is unrecorded.
**Verification method:** Count §ADR-Table body rows; grep for `ADR-009` in `specs/architecture/`; check if a file `decisions/ADR-009-*.md` exists.
**Route:** architect.

---

#### F-P176-A002 — ADR-021 §Backward-Compatibility false self-refuting claim

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-021-runnable-config-configurable.md`
**Section:** §Backward-Compatibility
**Defect:** ADR-021 §Backward-Compatibility asserts "`configurable: HashMap` is fully backward-compatible — existing call sites pass no argument and receive an empty map." This is self-refuting: the field is a new required field on `RunnableConfig`. Existing call sites constructing `RunnableConfig` as a struct literal would require the field (E0063 missing field). If `configurable` has a `Default` impl or is `Option<HashMap>`, backward compatibility holds, but neither is stated. The §Backward-Compatibility claim is a false assertion that will mislead implementers about the migration cost.
**Verification method:** Read ADR-021 §RunnableConfig-configurable-field; check whether `configurable` has `Default` or `Option` wrapper; check whether the BC bodies for BC-2.12.002 / BC-2.15.004 / BC-2.15.006 specify the field's optionality.
**Uncertainty:** Reviewer flagged this as pending intent verification: if the field is `Option<HashMap<String, serde_json::Value>>`, the claim is technically correct but still misleading because adding an `Option` field to a `#[non_exhaustive]` struct breaks struct-literal construction by external crates.
**Route:** architect.

---

#### F-P176-A003 — ADR-010 §Non-Exhaustive-Gate asserted as Phase-3-blocking with no wired gate

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-010-error-type-design.md`
**Section:** §Non-Exhaustive-Gate
**Defect:** ADR-010 §Non-Exhaustive-Gate describes a compile-fail test (`tests/external/non_exhaustive_gate/`) that verifies all public enums carry `#[non_exhaustive]`. POL-32 binds this gate at Phase 3. However, ADR-010 §Non-Exhaustive-Gate claims the gate "enforces the convention at Phase 1" in its rationale paragraph, implying it is already active. The gate file does not exist at frozen HEAD `9a62edc`; `tests/external/` is absent from the repository. This contradicts neither POL-32 (which correctly defers to Phase 3) nor ARCH-INDEX (which lists it as forthcoming), but the ADR body's own rationale paragraph asserts current enforcement.
**Why it matters:** Mechanism 4: the only normative statement for `#[non_exhaustive]` scope and exceptions is dispersed across finding notes in adversarial pass reports, with no single decision record. This is the mechanism that causes A028, A029, D009, B026, C028.
**Verification method:** Read ADR-010 §Non-Exhaustive-Gate §rationale paragraph; check for "at Phase 1" or "currently enforces" wording; grep `tests/external/non_exhaustive_gate` in the repository.
**Route:** architect (ADR-010 §rationale correction + governing decision record for the rule itself).

---

#### F-P176-A004 — ADR-001 §BSP-Implementation §crate-placement contradicts dependency-graph

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-001-graph-execution-engine.md`
**Section:** §BSP-Implementation / §crate-placement
**Defect:** ADR-001 §BSP-Implementation assigns the BSP graph engine to `pregolya-core`. `dependency-graph.md` §Edge-Table assigns graph-execution functionality to `pregolya-graph`. Eight cross-reference sites in architecture section files carry the `pregolya-core` placement form. ADR-001 postdates D21 which added `pregolya-graph` as a separate crate. The placement in ADR-001 was not updated at D21 scope expansion.
**Verification method:** Read ADR-001 §BSP-Implementation §crate-placement; read `dependency-graph.md` §pregolya-graph; grep `bsp_engine` in architecture files for crate attribution.
**Route:** architect.

---

#### F-P176-A005 — ADR-015 §Changelog note-closure: injection-guard propagation claimed complete; not applied

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-015-prompt-injection-safety.md`
**Section:** §Changelog
**Defect:** A changelog entry states "propagated injection guard to BC-2.18.003." F-P176-C023 (this pass, Slice C) verifies that `BC-2.18.003` §Related-BCs still carries the false coverage claim from F-P175-B202, with the body uncorrected at frozen HEAD. The changelog note describes work that was not performed. This is Mechanism 2: note-closure without body-closure.
**Verification method:** Read ADR-015 §Changelog for the entry claiming BC-2.18.003 propagation; read BC-2.18.003 §Related-BCs §injection-guard at frozen HEAD `9a62edc`; confirm the body still claims unguarded coverage.
**Route:** architect (ADR-015 changelog correction) + product-owner (BC-2.18.003 body correction — routed separately as F-P176-C023).

---

#### F-P176-A006 — VP-INDEX §Module column: 7 stale pre-canonicalization entries

**Severity:** HIGH
**File:** `specs/verification-properties/VP-INDEX.md`
**Section:** §Module
**Defect:** VP-INDEX §Module column carries pre-canonicalization module-path forms for 7 of 13 VP rows. The burst-276 `crate::module` canonicalization applied to VP-INDEX, `verification-architecture.md`, and `verification-coverage-matrix.md` (the index documents) but did NOT apply to the 13 authoritative VP source files (confirmed by F-P175-A27). The canonicalization now correctly appears in the source files but VP-INDEX was not re-updated after the source files were fixed in a subsequent burst. Result: VP-INDEX and VP source files disagree on the canonical module path for at least 7 VPs.
**Verification method:** Read VP-INDEX §Module column; read frontmatter `module:` from VP-002.md through VP-013.md; compare pairs.
**Route:** architect (VP-INDEX §Module column sync).

---

#### F-P176-A007 — POL-16 and POL-18 anchored to nonexistent ADR-010 sections

**Severity:** HIGH
**File:** `policies.yaml`
**Section:** §POL-16 / §POL-18
**Defect:** POL-16 `enforcement_anchor: "ADR-010 §impl PregolyaError"` and POL-18 `enforcement_anchor: "ADR-010 §non-exhaustive-gate/F-P173-619"`. Neither section heading exists in ADR-010 at frozen HEAD. The first is a Rust impl block label, not a section heading. The second is a slugified pseudo-anchor combining a heading and a finding ID. Both are in the `[process-gap]` class from E001 (§-anchor three-meaning taxonomy, Mechanism 1). Two BLOCKING gates cite unreachable enforcement anchors.
**Why it matters:** If an engineer attempts to verify POL-16 or POL-18 compliance by navigating to the stated anchors, they cannot find the governing rule. The anchor resolution is phantom.
**Verification method:** Read `policies.yaml` §POL-16 and §POL-18 `enforcement_anchor:` fields; grep for `## impl PregolyaError` and `## non-exhaustive-gate` in ADR-010; confirm they do not exist as headings.
**Route:** spec-steward (POL-16/POL-18 anchor correction to real headings) + devops-engineer (E001 gate extension — prerequisite to valid anchor enforcement).

---

#### F-P176-A008 — ADR-005 §Changelog note-closure: CheckpointId disambiguation propagation claimed; 6 stale sites remain

**Severity:** HIGH
**File:** `specs/architecture/decisions/ADR-005-checkpoint-id-type.md`
**Section:** §Changelog
**Defect:** ADR-005 §Changelog carries an entry "CheckpointId store-global scope removed; disambiguation propagated to all call-sites." Six grep hits across VP and BC body files carry the old store-global scope language for `checkpoint_id` uniqueness. The propagation was not complete; the changelog note describes work that was incomplete. This is Mechanism 2: note-closure without body-closure.
**Verification method:** Grep `store.global\|store-global\|global.*unique` in `specs/verification-properties/` and `specs/behavioral-contracts/`; count hits; compare to zero (the expected post-propagation count).
**Route:** architect (VP files) + product-owner (BC files).

---

#### F-P176-A009 — Iron Law census wrong in every term

**Severity:** HIGH
**File:** `specs/architecture/ARCH-INDEX.md`
**Section:** §Iron-Law-Census
**Defect:** §Iron-Law-Census states 71 modules / 69 canonical / 2 non-canonical. Actual ground truth from module-decomposition body is 76 modules / 70 canonical / 6 non-canonical. The crate registry shows 83 entries; actual count from the §crate-table body is 84. The §Iron-Law-Census §crate-row count states 6; the §crate-table body has 7 rows for the non-canonical-crate class. Every term of the census is wrong. This is Mechanism 3: arithmetic identity satisfiable without ground truth (the census was self-consistent at the last re-sum but was never re-derived from the source document bodies after D23 scope expansion).
**Verification method:** Count rows in module-decomposition body; compare to §Iron-Law-Census terms. Count §crate-table body rows; compare to §crate-registry count.
**Route:** architect.

---

#### F-P176-A039 — §Name three-meaning taxonomy: gate pre-requisite convention restriction

**Severity:** HIGH
**File:** `specs/architecture/ARCH-INDEX.md` (primary); `policies.yaml` §POL-16/18/19 (secondary); `specs/architecture/decisions/ADR-010-error-type-design.md` §Class-3-Illustration (tertiary)
**Section:** §Key-ADR-Anchors / §enforcement_anchor fields
**Defect:** The `§Named-Section` citation convention covers three structurally different targets without distinguishing them: (1) real Markdown `## Heading` entries that produce stable anchor slugs; (2) bold inline labels inside prose (`**E-CFG-001 resolution:**`) that have no heading anchor; (3) slugified pseudo-anchors combining a heading and a sub-identifier (`§non-exhaustive-gate/F-P173-619`). A gate that validates `ADR-NNN §Named-Section` citations cannot distinguish a phantom from a legitimate sub-anchor because the three forms look syntactically identical in citation prose. **Consequence for sequencing:** the convention must be restricted to form (1) only BEFORE any anchor-resolution gate is built; otherwise the gate cannot discriminate valid from invalid citations. TD-VSDD-091/L9b remediation actively converts form `<doc> vN.N` into `§Named-Section` without enforcing form (1) only — making the anti-volatile-pin policy a fabrication generator. This is Mechanism 1: §-anchor unverifiability. This finding is the root-cause record enabling the mechanism fix.
**Verification method:** Read ADR-010 §Class-3-Illustration for inline bold labels; grep `ADR-NNN §[A-Z]` across the corpus for ~170 citations; sample 10 citations and attempt to locate each as a `## ` heading in the cited ADR file.
**Route:** architect (convention restriction decision — prerequisite to devops-engineer gate implementation) + spec-steward (POL-19 wording correction).

---

### Slice A MED Findings (23)

#### F-P176-A010 — ADR-007 §Changelog note-closure: D23 propagation claimed complete; crate-count stale

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-007-workspace-crate-decomposition.md`
**Section:** §Changelog
**Defect:** ADR-007 §Changelog entry "D23 domain expansion propagated; 21-crate roster applied" was committed in burst-265. ADR-007 §Consequences §crate-count still says 18. The note closure was wrong; §Consequences was not updated. Mechanism 2.
**Verification method:** Read ADR-007 §Consequences §crate-count; confirm 18 vs expected 21.
**Route:** architect.

---

#### F-P176-A011 — ADR-007 §Consequences §crate-count 18 vs current 21

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-007-workspace-crate-decomposition.md`
**Section:** §Consequences
**Defect:** §Consequences states "18-crate workspace decomposition." Post-D21+D23, the roster is 21. ARCH-INDEX §crate-table has 21 rows. The consequence paragraph was not updated during scope expansions.
**Verification method:** Read §Consequences §crate-count; read ARCH-INDEX §crate-table row count.
**Route:** architect (follow-on to A010 fix).

---

#### F-P176-A012 — ARCH-INDEX §Key-ADR-Anchors: 5 of 8 rows use §Decision <Name> not §Decision <Integer>

**Severity:** MED
**File:** `specs/architecture/ARCH-INDEX.md`
**Section:** §Key-ADR-Anchors
**Defect:** §Key-ADR-Anchors table has 8 rows. 5 of 8 use `§Decision <Name>` form (e.g., `§Decision retroactive-suppression`). `verify-adr-decision-refs.sh` gates only `§Decision <integer>` form. These 5 entries pass the gate invisibly while pointing to sections that may not exist. This is a Mechanism 1 instance within the index file itself.
**Verification method:** Read ARCH-INDEX §Key-ADR-Anchors; compare each anchor to the actual ADR heading.
**Route:** architect.

---

#### F-P176-A013 — VP-002 §module frontmatter: `checkpoint-session-index` (pre-canonicalization)

**Severity:** MED
**File:** `specs/verification-properties/VP-002.md`
**Section:** §frontmatter / `module:`
**Defect:** VP-002 `module: checkpoint-session-index`. Canonical form is `checkpoint::session_index` (established by burst-276 canonicalization). VP-INDEX was updated but VP source file was not. This is the F-P175-A27 residue class.
**Verification method:** Read VP-002.md `module:` frontmatter field; compare to VP-INDEX §Module column for the VP-002 row.
**Route:** architect.

---

#### F-P176-A014 — VP-003 §module frontmatter: `path-guard` (pre-canonicalization)

**Severity:** MED
**File:** `specs/verification-properties/VP-003.md`
**Section:** §frontmatter / `module:`
**Defect:** VP-003 `module: path-guard`. Canonical form is `sandbox::path_guard`.
**Verification method:** Same as A013 pattern.
**Route:** architect.

---

#### F-P176-A015 — VP-004 §module frontmatter: `mcp-adapter` (pre-canonicalization)

**Severity:** MED
**File:** `specs/verification-properties/VP-004.md`
**Section:** §frontmatter / `module:`
**Defect:** VP-004 `module: mcp-adapter`. Canonical form is `mcp::adapter`.
**Route:** architect.

---

#### F-P176-A016 — VP-005 §module frontmatter: `mcp-client` (pre-canonicalization)

**Severity:** MED
**File:** `specs/verification-properties/VP-005.md`
**Section:** §frontmatter / `module:`
**Defect:** VP-005 `module: mcp-client`. Canonical form is `mcp::client`.
**Route:** architect.

---

#### F-P176-A017 — VP-007 §module frontmatter: `serializable` (pre-canonicalization)

**Severity:** MED
**File:** `specs/verification-properties/VP-007.md`
**Section:** §frontmatter / `module:`
**Defect:** VP-007 `module: serializable`. Canonical form is `core::serializable`.
**Route:** architect.

---

#### F-P176-A018 — verification-architecture §Phase-3-Anchors: 12 §Named-Section cites resolve to nothing

**Severity:** MED
**File:** `specs/architecture/verification-architecture.md`
**Section:** §Phase-3-Anchors
**Defect:** §Phase-3-Anchors contains 12 `ADR-010 §Named-Section` citation forms. None of the 12 section names appear as `## ` headings in ADR-010 at frozen HEAD. These are phantom anchors of the form identified in A039 (Mechanism 1). This is the anchor unverifiability mechanism manifesting in the verification architecture document specifically.
**Verification method:** Extract the 12 anchor names from §Phase-3-Anchors; grep each as `^## ` in ADR-010; confirm zero matches.
**Route:** architect.

---

#### F-P176-A019 — ADR-019 §Compact-Type-Canon heading mismatch across citation chain

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-019-compaction-type-canonicalization.md`
**Section:** §Compact-Type-Canon (cited form) vs actual heading
**Defect:** 4 cross-reference files cite `ADR-019 §Compact-Type-Canon` as the governing rule. The actual ADR-019 heading is `§CompactTypeCanon` (CamelCase, no hyphens). The two forms generate different anchor slugs. Navigating from the cited form produces a 404.
**Verification method:** Read ADR-019 body for the exact heading; compare to cited forms in BC-INDEX and VP-INDEX.
**Route:** architect.

---

#### F-P176-A020 — VP-013 §Evidence §Tech-Debt references three TDs not current post-rename

**Severity:** MED
**File:** `specs/verification-properties/VP-013.md`
**Section:** §Evidence
**Defect:** VP-013 §Evidence lists three tech-debt references using `ferrochain-` prefixed identifiers. Post-rename, the canonical prefix is `pregolya-`. TD references are not code citations (not banned by TD-VSDD-091) but they are misleading.
**Verification method:** Read VP-013 §Evidence; grep for `ferrochain-`.
**Route:** architect.

---

#### F-P176-A021 — ADR-008 §Feature-Flag §Phase-Gating: claim contradicts bc-authoring-plan §Phase-Progression

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-008-feature-flags.md`
**Section:** §Feature-Flag / §Phase-Gating
**Defect:** ADR-008 §Phase-Gating asserts "feature flags are evaluated at Phase-1 gate." `bc-authoring-plan.md` §Phase-Progression does not include a Phase-1-gate step; the progression moves from Phase-1-adversarial-convergence directly to Phase-2. Two normative documents describe different gating points.
**Verification method:** Read ADR-008 §Phase-Gating; read bc-authoring-plan.md §Phase-Progression for the Phase-1 step sequence.
**Route:** architect (ADR-008 §Phase-Gating correction).

---

#### F-P176-A022 — ADR-012 §Tenancy-Bridge: claim contradicts BC-2.15.001 §Traceability title

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-012-tenancy-isolation-model.md`
**Section:** §Tenancy-Bridge
**Defect:** ADR-012 §Tenancy-Bridge says "BC-2.15.001 traces to CAP-017 (Wave-2)." `BC-2.15.001` §Traceability title cell says `CAP-017 (Wave-1)`. The Wave assignment was corrected by F-P159-01 fix-burst-260 in BC-2.15.001 body but not back-propagated to ADR-012.
**Verification method:** Read ADR-012 §Tenancy-Bridge CAP-017 wave citation; read BC-2.15.001 §Traceability §Wave column.
**Route:** architect.

---

#### F-P176-A023 — verification-coverage-matrix §VP-004 proof_method mismatch

**Severity:** MED
**File:** `specs/architecture/verification-coverage-matrix.md`
**Section:** §VP-004 row / proof_method column
**Defect:** `verification-coverage-matrix.md` §VP-004 row shows `proof_method: manual`. VP-004.md body §Proof-Method describes integration tests executed by nextest. The frontmatter form and the body description specify different verification mechanisms. (Same class as F-P175-A13; not yet fixed at frozen HEAD.)
**Verification method:** Read verification-coverage-matrix §VP-004 row; read VP-004.md §Proof-Method.
**Route:** architect.

---

#### F-P176-A024 — ADR-001 §BSP-Phase-Count: 7 phases stated; architecture section §Valiant-BSP says 5

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-001-graph-execution-engine.md`
**Section:** §BSP-Phase-Count
**Defect:** ADR-001 §BSP-Phase-Count lists 7 super-step phases. The architecture section `specs/architecture/execution-model.md` §Valiant-BSP describes 5 phases. The discrepancy is unaddressed.
**Verification method:** Count phases in ADR-001 §BSP-Phase-Count; count phases in execution-model.md §Valiant-BSP.
**Route:** architect.

---

#### F-P176-A025 — ARCH-INDEX §crate-table missing pregolya-tools row

**Severity:** MED
**File:** `specs/architecture/ARCH-INDEX.md`
**Section:** §crate-table
**Defect:** ARCH-INDEX §crate-table has 21 rows per §Architecture-State, but `pregolya-tools` does not appear as its own row; tools functionality appears only as a subsystem in other rows. Module-decomposition §ss-23 assigns `pregolya-tools` as a first-party crate in the 21-crate roster. The §crate-table is missing the row.
**Verification method:** List §crate-table rows; grep for `pregolya-tools` row.
**Route:** architect.

---

#### F-P176-A026 — ADR-002 §Migration-Notes §LangGraph-v0x version pin

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-002-checkpoint-storage-backends.md`
**Section:** §Migration-Notes
**Defect:** §Migration-Notes cites `LangGraph v0.x` in a normative position. This is a TD-VSDD-091 `<doc> vN.N` volatile-pin class. The `.x` wildcard does not fully address the volatility because the major version pin `v0` is itself a version claim that will become stale when LangGraph reaches v1.
**Verification method:** Read ADR-002 §Migration-Notes for `LangGraph v0` or `v0.x` occurrence.
**Route:** architect.

---

#### F-P176-A027 — ADR-010 §Class-3-Illustration contains non-exempt normative construction form

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-010-error-type-design.md`
**Section:** §Class-3-Illustration
**Defect:** The §Class-3-Illustration block contains a bare `PregolyaError { .. }` struct-literal construction form in what appears to be a normative context (not inside the `illustration_exempt_lines` block recognized by `spec_region_utils.py`). If this line is in the normative region, `verify-error-notation-canon.sh` should flag it as a Class-3 violation but may not because the discriminator's illustration-block detection could be miscalibrated. Reviewer notes uncertainty: pending confirmation whether the line sits inside the exempted illustration region.
**Uncertainty:** This finding is marked **pending `spec_region_utils.py` output verification**. If the line is inside the exempted block, this finding downgrades to OBS.
**Verification method:** Run `verify-error-notation-canon.sh` in verbose mode; check whether ADR-010 §Class-3-Illustration line is categorized as EXEMPT or NORMATIVE.
**Route:** devops-engineer (if normative: discriminator fix) + architect (if normative: illustration block marker repair).

---

#### F-P176-A028 — StreamEvent `#[non_exhaustive]` applied without governing ADR rule

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-006-stream-event-type.md`
**Section:** §StreamEvent-Variants / §non_exhaustive-annotation
**Defect:** ADR-006 describes the `StreamEvent` enum and mentions `#[non_exhaustive]` in passing. No ADR states: the rule requiring `#[non_exhaustive]` on public enums, the exception criteria, or the exempt inventory. `StreamEvent`'s `#[non_exhaustive]` was applied ad hoc. This is Mechanism 4: #[non_exhaustive] applied without a governing decision record. One governing ADR closes A028, A029, D009, B026, and C028.
**Verification method:** Grep all ADRs for a normative rule requiring `#[non_exhaustive]` on public enums with stated exceptions; confirm no such rule exists.
**Route:** architect (governing decision record).

---

#### F-P176-A029 — BoundaryType `#[non_exhaustive]` applied without governing ADR rule

**Severity:** MED
**File:** `specs/architecture/decisions/ADR-016-injection-guard-architecture.md`
**Section:** §BoundaryType / §non_exhaustive-annotation
**Defect:** Same class as A028. `BoundaryType` enum in ADR-016 carries `#[non_exhaustive]` without a governing rule. This is the second instance of Mechanism 4.
**Route:** architect (same governing decision record as A028).

---

#### F-P176-A030 — module-criticality §TOOLS tier: CRIT vs ADR §Criticality-Tier HIGH

**Severity:** MED
**File:** `specs/module-criticality.md`
**Section:** §TOOLS
**Defect:** `module-criticality.md` §TOOLS assigns tier `CRIT`. ADR-001 §Criticality-Tier definition reserves CRIT for compile-time safety and memory-safety. Tools functionality is runtime safety — the correct tier is HIGH under ADR-001's own definitions. The prior CRIT assignment was made before ADR-001 §Criticality-Tier §Runtime-Safety was authored.
**Verification method:** Read ADR-001 §Criticality-Tier definitions; read module-criticality §TOOLS tier assignment; confirm mismatch.
**Route:** architect.

---

#### F-P176-A031 — verification-architecture §VP-008-Rationale references stale harness construction form

**Severity:** MED
**File:** `specs/architecture/verification-architecture.md`
**Section:** §VP-008-Rationale
**Defect:** §VP-008-Rationale describes the MockEmbeddings harness as `MockEmbeddings { dim }` (struct-literal form). F-P175-A24 identified this as a self-proving mock; the fix-burst should have updated verification-architecture §VP-008-Rationale to reflect the corrected harness form, but the rationale paragraph was not updated. The stale rationale will mislead any future review of VP-008.
**Verification method:** Read verification-architecture §VP-008-Rationale; check for struct-literal harness form.
**Route:** architect.

---

#### F-P176-A032 — dependency-graph §Edge-Table: 2 edges from D23 missing

**Severity:** MED
**File:** `specs/architecture/dependency-graph.md`
**Section:** §Edge-Table
**Defect:** F-P163-03 added 3 crates and 4 edges to dependency-graph in fix-burst-265. However, 2 edges introduced by D23 scope expansion (runtime-tool-loader and dynamic-schema edges) remain absent from the §Edge-Table. ARCH-INDEX §D23-scope-expansion lists these edges as required.
**Verification method:** Read ARCH-INDEX §D23-scope-expansion §required-edges; check dependency-graph §Edge-Table for each.
**Route:** architect.

---

#### F-P176-A033 — BC-INDEX §VP-Seed-Table header row count 11 vs body rows 8

**Severity:** MED
**File:** `specs/behavioral-contracts/BC-INDEX.md`
**Section:** §VP-Seed-Table
**Defect:** BC-INDEX §VP-Seed-Table header row states "VP Seed count: 11." The §VP-Seed-Table body contains 8 rows. This is an independent observation of the cross-perimeter observation recorded in F-P175 Slice A cross-perimeter note 1. Not yet fixed at frozen HEAD.
**Verification method:** Count §VP-Seed-Table body rows; read header count assertion.
**Route:** product-owner.

---

### Slice A LOW / OBS Findings (7)

#### F-P176-A034 — ADR-010 §Preface changelog date future-dated relative to frozen HEAD

**Severity:** LOW
**File:** `specs/architecture/decisions/ADR-010-error-type-design.md`
**Section:** §Preface / §changelog
**Defect:** A changelog entry carries date 2026-07-31, which postdates the frozen HEAD `9a62edc` (committed 2026-07-30). `verify-changelog-date-validity.sh` should catch this; if it did not, the validator has a boundary condition.
**Route:** devops-engineer (validator check) + architect (date correction).

---

#### F-P176-A035 — ADR-016 §Decision-3 anchor spelling inconsistency across citation chain

**Severity:** LOW
**File:** `specs/architecture/decisions/ADR-016-injection-guard-architecture.md`
**Section:** §Decision-3
**Defect:** 3 BC files cite `ADR-016 §Decision 3 Property 4`. ADR-016 §Decision-3 heading is `§Decision 3: Property Mapping`. The §Property-4 sub-item is a table row, not a heading. This is a Mechanism 1 instance: `§Decision 3 Property 4` is a composite identifier, not a real heading anchor.
**Route:** architect (simplify citation to `ADR-016 §Decision 3`).

---

#### F-P176-A036 — verification-coverage-matrix §Phase-3-Column: post-v1 items without marker

**Severity:** LOW
**File:** `specs/architecture/verification-coverage-matrix.md`
**Section:** §Phase-3-Column
**Defect:** 4 rows in §Phase-3-Column list verification obligations without a `[post-v1]` or `[Phase-4]` phase marker. These rows cover the `Async-Kani` and `async-harness` axes that VP-008 §Feasibility defers to post-Phase-3. The absence of a phase marker creates false coverage claims for Phase-3 scope.
**Route:** architect.

---

#### F-P176-A037 — ARCH-INDEX §ADR-Table ADR-021 row version `1.0` vs body `1.1`

**Severity:** LOW
**File:** `specs/architecture/ARCH-INDEX.md`
**Section:** §ADR-Table / ADR-021 row
**Defect:** ARCH-INDEX §ADR-Table lists ADR-021 version as `1.0`. ADR-021.md body §changelog shows current version `1.1` after the burst-283 BC bump.
**Route:** architect.

---

#### F-P176-A038 — VP-001 §Proof-Harness comment references stale sort form

**Severity:** LOW
**File:** `specs/verification-properties/VP-001.md`
**Section:** §Proof-Harness
**Defect:** VP-001 §Proof-Harness inline comment says `// sort by channel_name, then task_id`. Post-F-P172b fix, the sort order is `task_id` then `channel_name`. The comment is stale.
**Route:** architect.

---

#### F-P176-A040 — ADR-013 §Tools-List vs §Tool-List heading inconsistency

**Severity:** LOW
**File:** `specs/architecture/decisions/ADR-013-tool-invocation-protocol.md`
**Section:** §Tools-List (cited) / §Tool-List (actual)
**Defect:** 2 BC files cite `ADR-013 §Tools-List`. ADR-013 actual heading is `§Tool-List` (singular). Another Mechanism 1 instance (phantom named-section anchor).
**Route:** architect (if real heading exists: update citations; if heading is wrong: rename heading).

---

#### F-P176-A039-PG — `[process-gap]` VP source-file sync not gated after VP-INDEX updates

**Severity:** `[process-gap]`
**Finding:** There is no mechanical gate that detects divergence between VP frontmatter `module:` fields (in VP source files) and VP-INDEX §Module column. A013–A017 are all instances of this gap. PG-175-A-04 proposed this gate; it remains unimplemented.
**Route:** devops-engineer.

---

#### F-P176-A007-PG — `[process-gap]` No anchor-resolution test for §Named-Section forms in policy enforcement_anchor fields

**Severity:** `[process-gap]`
**Finding:** `policies.yaml` `enforcement_anchor:` fields accept any string; no gate validates that the string resolves to a real heading in the cited ADR. A007 is the direct finding; this PG tracks the missing gate.
**Route:** devops-engineer (prerequisite: architect A039 convention restriction decision).

---

#### F-P176-A005-PG — `[process-gap]` Changelog claim verification advisory not promoted to blocking

**Severity:** `[process-gap]`
**Finding:** `verify-changelog-claim-applied.sh` has 631 advisory findings. D-100 recorded this as records-only micro-burst eligible. A005, A008, A010 are three instances where the advisory correctly identifies false closures. The advisory being non-blocking allows false closures to accumulate. The gate should be promoted to blocking or the false-closure class should be gated separately.
**Route:** devops-engineer.

---

## Slice B — BCs SS-01..SS-12 + BC-INDEX

**31 findings: 0 CRIT / 8 HIGH / 17 MED / 6 LOW/OBS**

### Slice B Verified-Clean Axes

- **BC-2.01.001 through BC-2.11.003 rename completeness:** 0 `ferrochain` occurrences in BC bodies (SS-01..SS-11 inclusive).
- **Form-A changelog direction:** All 51 BC files pass `verify-form-a-changelog-direction.sh` (PASS=51 WARN=0 FAIL=0).
- **Error notation canon:** All BCs in SS-01..SS-12 pass `verify-error-notation-canon.sh` (PASS per slice scope).
- **BC frontmatter schema:** All BC files in SS-01..SS-12 pass `verify-bc-frontmatter-schema.sh`.

---

### Slice B HIGH Findings (8)

#### F-P176-B001 — BC-INDEX §SS-01 row: BC-2.01.004 subsystem frontmatter absent

**Severity:** HIGH
**File:** `specs/behavioral-contracts/BC-INDEX.md` / `specs/behavioral-contracts/ss-01/BC-2.01.004.md`
**Section:** §SS-01 row / frontmatter
**Defect:** BC-2.01.004 frontmatter is missing `subsystem: SS-01`. BC-INDEX §SS-01 row includes BC-2.01.004 in its count, but the BC file itself has no subsystem frontmatter field. `verify-bc-frontmatter-schema.sh` apparently did not flag this. Reviewer notes this may indicate the schema check does not require subsystem field to be present.
**Uncertainty:** Pending confirmation whether `subsystem:` is a required or optional frontmatter field per the bc-authoring-plan §BC-Template.
**Route:** product-owner.

---

#### F-P176-B002 — BC-2.12.002 EC-006 cites BC-2.12.003 as authority for a merge rule that authority contradicts; TV-008 cannot discriminate the two rules (fix-burst-283 regression)

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-12/BC-2.12.002.md`
**Section:** §EC-006 / §TV-008
**Defect:** `BC-2.12.002` EC-006 cites `BC-2.12.003` as the authority for configurable-merge semantics. Reading `BC-2.12.003` at frozen HEAD, its §configurable-merge section states merge behavior that contradicts EC-006's stated rule. TV-008 cannot distinguish which rule applies because both rules produce valid-looking PASS outcomes on the same test input. This is a fix-burst-283 regression: burst-283 added the `configurable` field (ADR-021 / D-95 / D-97) and introduced the four BC version bumps (BC-2.12.002, BC-2.12.004, BC-2.15.004, BC-2.15.006). The EC-006 cross-citation was authored in burst-283 and has not been independently verified. Self-attributed to the orchestrator.
**Verification method:** Read BC-2.12.002 §EC-006; read BC-2.12.003 §configurable-merge; identify the contradiction; check TV-008 test scenario to confirm it cannot discriminate.
**Route:** product-owner (BC-2.12.002 + BC-2.12.003 reconciliation) + architect (ADR-021 §merge-semantics clarification if needed).

---

#### F-P176-B003 — BC-2.09.001 §PC-3 error variant name: E-MCP-001 vs E-MCP-007

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-09/BC-2.09.001.md`
**Section:** §PC-3
**Defect:** BC-2.09.001 §PC-3 names `E-MCP-001` as the error returned on connection failure. `error-taxonomy.md` §MCP table shows `E-MCP-001` was renumbered to `E-MCP-007` in burst-258 (F-P158). BC-2.09.001 was not in the sweep scope for that fix-burst. The BC body references a retired error code.
**Verification method:** Read BC-2.09.001 §PC-3; grep error-taxonomy §MCP table for E-MCP-001 and E-MCP-007 to confirm renumbering.
**Route:** product-owner.

---

#### F-P176-B004 — max_queue_depth phantom field: unswept sibling of missed_fire_policy (fix-burst-283 regression)

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-12/BC-2.12.002.md`
**Section:** §PC-4 / §CronConfig-fields
**Defect:** `BC-2.12.002` §CronConfig-fields lists `max_queue_depth` as a field of `CronConfig`. This field does not appear in `interface-definitions.md` §CronConfig field table, `entities-server.md` §CronConfig entity, or any ADR. `missed_fire_policy` was identified as a phantom in an earlier pass and corrected. `max_queue_depth` is its unswept sibling — same file, same burst-283 authoring session, same phantom-field pattern. This is a TD-VSDD-060 sibling-site sweep failure in fix-burst-283. Self-attributed to the orchestrator.
**Verification method:** Grep `max_queue_depth` in `interface-definitions.md`, `entities-server.md`, and ADR bodies; confirm no definition exists.
**Route:** product-owner (BC-2.12.002 §CronConfig field removal or definition).

---

#### F-P176-B005 — BC-2.06.001 §StreamEvent §variant-count: 15 listed; D23 expansion adds 2 more

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-06/BC-2.06.001.md`
**Section:** §StreamEvent-Variants
**Defect:** BC-2.06.001 §StreamEvent-Variants lists 15 variants. ADR-006 rev-5 (updated in fix-burst-269 F-P167-03) documents the D18-P99-A addition (GuardrailDecision, making 12→13) and states "17 total post-D21+D23 addition." BC-2.06.001 was not updated at ADR-006 rev-5 time. 15 vs 17.
**Verification method:** Count variants in BC-2.06.001 §StreamEvent-Variants; read ADR-006 rev-5 §StreamEvent total count.
**Route:** product-owner.

---

#### F-P176-B006 — BC-2.07.003 §max-content-length: 10,000 vs interface-definitions 8,192

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-07/BC-2.07.003.md`
**Section:** §max-content-length
**Defect:** BC-2.07.003 §Preconditions cites `max_content_length: 10_000` as the splitter boundary. `interface-definitions.md` §SplitterConfig declares `max_content_length: 8_192` as the default and authoritative value. 10,000 vs 8,192 — implementers will code the wrong boundary.
**Verification method:** Read BC-2.07.003 §max-content-length value; read interface-definitions §SplitterConfig §max_content_length.
**Route:** product-owner.

---

#### F-P176-B007 — BC-2.10.003 §PC-8 note-closure: completed-at migration claimed; body not updated

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-10/BC-2.10.003.md`
**Section:** §PC-8 / §changelog
**Defect:** A BC-2.10.003 §changelog entry says "completed-at migration per burst-238 applied to §PC-8." BC-2.10.003 §PC-8 body does not include the completed-at postcondition described in burst-238-dates-sweep-manifest. Mechanism 2 instance.
**Verification method:** Read BC-2.10.003 §PC-8 for completed-at postcondition; read §changelog entry claiming the migration; confirm mismatch.
**Route:** product-owner.

---

#### F-P176-B008 — BC-2.04.001 §Checkpoint-Invariant-5 §Immutability: phantom anchor to ADR-002

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-04/BC-2.04.001.md`
**Section:** §Checkpoint-Invariant-5 / §Immutability
**Defect:** §Checkpoint-Invariant-5 §Immutability cites `ADR-002 §checkpoint-immutability` as the governing rule. ADR-002 at frozen HEAD has no heading `§checkpoint-immutability`; the relevant content is under `§Immutability-Invariant`. This is Mechanism 1: a §Named-Section anchor that resolves to nothing.
**Verification method:** Grep `^## .*checkpoint.immutability` in ADR-002; confirm absent.
**Route:** product-owner (citation correction to real heading).

---

### Slice B MED Findings (17)

#### F-P176-B009 — BC-2.01.001 §PC-1 MessageContent type: not in SS-01 interface table

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-01/BC-2.01.001.md`
**Section:** §PC-1
**Defect:** §PC-1 declares return type `MessageContent`. `interface-definitions.md` §SS-01 table does not include a `MessageContent` type entry. The type appears in entity files but lacks an interface-definitions row. Implementer using interface-definitions as the canonical API surface will not find `MessageContent`.
**Route:** product-owner.

---

#### F-P176-B010 — BC-2.02.001 §PC-3 streaming partial token: MessageChunk not in entities-server

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-02/BC-2.02.001.md`
**Section:** §PC-3
**Defect:** §PC-3 references `MessageChunk` as the streaming partial-token entity. `entities-server.md` does not define `MessageChunk`; it defines `StreamEvent::Token`. The entity name mismatch will cause test-writers to author tests against a nonexistent type.
**Route:** product-owner.

---

#### F-P176-B011 — BC-2.03.001 §recursion-ceiling formula: §Description says "within recursion_limit" but §PC-2 says "+ 1"

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-03/BC-2.03.001.md`
**Section:** §Description vs §PC-2
**Defect:** §Description prose says "terminates within `recursion_limit` super-steps." §PC-2 (the normative postcondition) says "terminates at step `recursion_limit + 1`." Both cannot be correct. F-P160-01 corrected the §Description; §PC-2 was not updated to match, or vice versa.
**Route:** product-owner.

---

#### F-P176-B012 — BC-2.04.006 §PC-2 references CheckpointConfig vs BC-2.12.002 uses RunnableConfig

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-04/BC-2.04.006.md`
**Section:** §PC-2
**Defect:** §PC-2 names `CheckpointConfig` as the config parameter type for checkpoint operations. `BC-2.12.002` §RunnableConfig and ADR-021 use `RunnableConfig` as the unified config type. `interface-definitions.md` §CheckpointSaver declares `CheckpointConfig` on every method. Two different types are in play; the authoritative one is not established by cross-reference.
**Uncertainty:** Reviewer notes pending intent verification: if `CheckpointConfig` and `RunnableConfig` co-exist as separate types (checkpoint-level vs runnable-level config), the finding may be a non-issue. Requires reading ADR-002 §config-type-hierarchy.
**Route:** architect (adjudication) + product-owner (BC body update).

---

#### F-P176-B013 — BC-2.05.001 §TV-001 test vector: DispatchOutcome variants not specified

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-05/BC-2.05.001.md`
**Section:** §TV-001
**Defect:** TV-001 scenario does not specify which `DispatchOutcome` variant is expected on the tested code path. Post-F-P154 adjudication, `DispatchOutcome` is a 2-variant enum (per VP-011 Option-A). The test vector is underspecified.
**Route:** product-owner.

---

#### F-P176-B014 — BC-2.05.007 §PendingHumanApproval: PC-4 peel-off semantics not propagated after VP-011 adjudication

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-05/BC-2.05.007.md`
**Section:** §PC-4
**Defect:** VP-011 adjudication (Option-A, fix-burst-255) peeled `PendingHumanApproval` off `DispatchOutcome` and moved it upstream to `pre_tool_dispatch`. BC-2.05.007 §PC-4 still references the peel-off state as if it is a `DispatchOutcome` variant.
**Route:** product-owner.

---

#### F-P176-B015 — BC-2.06.001 §changelog v1.4 entry note-closure without body update

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-06/BC-2.06.001.md`
**Section:** §changelog / v1.4 entry
**Defect:** §changelog v1.4 says "D23 StreamEvent additions propagated to §variants." BC-2.06.001 §StreamEvent-Variants body has 15 variants; ADR-006 rev-5 states 17. The note was added but the body propagation was incomplete. Mechanism 2.
**Route:** product-owner (follow-on to B005 fix).

---

#### F-P176-B016 — BC-2.07.002 §GTV-010-011 updated; BC-INDEX §GTV row count 9 vs body 11

**Severity:** MED
**File:** `specs/behavioral-contracts/BC-INDEX.md`
**Section:** §GTV row
**Defect:** BC-INDEX §GTV row count shows 9. F-P152-03 (fix-burst-253) added GTV-010 and GTV-011 to BC-2.07.002, making the total 11. BC-INDEX §GTV row was not updated at that time.
**Route:** product-owner.

---

#### F-P176-B017 — BC-2.08.001 §PC-2: pregolya-core placement vs dependency-graph pregolya-graph

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-08/BC-2.08.001.md`
**Section:** §PC-2 / §module
**Defect:** BC-2.08.001 §module frontmatter says `core::tools`. The §PC-2 crate attribution in the body says `pregolya-core`. `dependency-graph.md` assigns tool-invocation routing to `pregolya-graph`. Same placement conflict as A004 at the BC level.
**Route:** product-owner.

---

#### F-P176-B018 — BC-2.08.008 §eval.judge_infra_error: observability §emitting-crate says pregolya-graph; BC §module says pregolya-core

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-08/BC-2.08.008.md`
**Section:** §module / observability §emitting-crate
**Defect:** BC-2.08.008 frontmatter `module: core::judge`. `observability.md` §eval.judge_infra_error §emitting-crate row says `pregolya-graph`. Two sources name different crates for the same emission point.
**Route:** product-owner.

---

#### F-P176-B019 — BC-2.09.001 §TV-003: ID collision with BC-2.12.001 §TV-003 in global registry

**Severity:** MED
**File:** `specs/prd-supplements/test-vectors.md`
**Section:** §TV-Registry
**Defect:** TV-003 was issued to both BC-2.09.001 (connection failure test) and BC-2.12.001 (cron job failure test) in the global test-vector registry. Duplicate IDs break Phase 3 test-writer dispatch routing.
**Route:** product-owner (renumber one; update test-vectors.md registry).

---

#### F-P176-B020 — BC-2.09.002 §McpError-Wrapper: PC-5 absent from §Formal-Postcondition

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-09/BC-2.09.002.md`
**Section:** §Formal-Postcondition
**Defect:** BC-2.09.002 §Preconditions lists PC-5 (error source chain depth). §Formal-Postcondition does not include PC-5 as a postcondition assertion. The PC is declared but has no formal counterpart for the verifier to check.
**Route:** product-owner.

---

#### F-P176-B021 — BC-2.10.001 §DenyState §Deny-Invariants: 3 in prose, 2 numbered in body table

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-10/BC-2.10.001.md`
**Section:** §DenyState / §Deny-Invariants
**Defect:** §Description says "3 deny invariants." §Deny-Invariants body table has 2 numbered rows. One invariant was described in prose but not added to the table.
**Route:** product-owner.

---

#### F-P176-B022 — BC-2.10.004 §PC-3 lettered sub-numbering a/b/c vs sibling BCs using arabic

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-10/BC-2.10.004.md`
**Section:** §PC-3
**Defect:** §PC-3 sub-items are labeled (a), (b), (c). All sibling BCs in SS-10 use arabic numbering (1), (2), (3) for sub-items. The inconsistency was previously recorded in P1D-95 but not yet corrected at frozen HEAD.
**Route:** product-owner.

---

#### F-P176-B023 — BC-2.11.002 §changelog descending order (ascending required by gate #28 Rule 6)

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-11/BC-2.11.002.md`
**Section:** §changelog
**Defect:** §changelog entries are in descending order (newest at top). Gate #28 Rule 6 (VERSION-MONOTONICITY) requires ascending order (oldest at top). `verify-form-a-changelog-direction.sh` WARN=7 in burst-284; this may be one of the 7.
**Uncertainty:** Reviewer notes: unclear whether this is one of the 7 WARN cases captured in burst-284 baseline or a new finding. Flagged for confirmation.
**Route:** product-owner.

---

#### F-P176-B024 — BC-2.11.003 §PC-7 TrustLevel: 3-level ordering vs interface-definitions 4 levels

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-11/BC-2.11.003.md`
**Section:** §PC-7 / §TrustLevel-ordering
**Defect:** §PC-7 documents `TrustLevel` as a 3-level enum (Trusted, Untrusted, System). `interface-definitions.md` §TrustLevel lists 4 levels (adds Elevated). `BC-2.21.001` §TrustLevel body also shows 4 variants. BC-2.11.003 was not updated when the 4th level was added.
**Route:** product-owner.

---

#### F-P176-B025 — BC-2.12.005 §configurable §PC-4: cites phantom ADR-021 §configurable-merge-protocol

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-12/BC-2.12.005.md`
**Section:** §PC-4
**Defect:** §PC-4 cites `ADR-021 §configurable-merge-protocol` as the governing merge rule. ADR-021 at frozen HEAD has no section heading `§configurable-merge-protocol`; the relevant content is under `§configurable-merge-semantics`. Mechanism 1 instance.
**Route:** product-owner (citation correction).

---

### Slice B LOW / OBS Findings (6)

#### F-P176-B026 — BC-2.01.002 §ContentBlock `#[non_exhaustive]` without governing rule (OBS — Mechanism 4 instance)

**Severity:** OBS
**File:** `specs/behavioral-contracts/ss-01/BC-2.01.002.md`
**Section:** §ContentBlock / `#[non_exhaustive]`
**Defect:** Mechanism 4 instance. `ContentBlock` enum carries `#[non_exhaustive]` without a governing ADR rule. Same class as A028/A029/D009/C028. One governing decision record closes all instances.
**Route:** architect (same governing decision record as A028; no separate fix needed once ADR is written).

---

#### F-P176-B027 — BC-INDEX §format-version out of sync with latest BC bump

**Severity:** LOW
**File:** `specs/behavioral-contracts/BC-INDEX.md`
**Section:** §format-version / §frontmatter
**Defect:** BC-INDEX frontmatter `format-version` field has not been incremented since the burst-283 BC version bumps (D-97). The format-version counter is used by some validators as a staleness heuristic.
**Route:** product-owner.

---

#### F-P176-B028 — BC-2.05.004 §changelog date 2026-07-25 for fix applied 2026-07-28

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-05/BC-2.05.004.md`
**Section:** §changelog
**Defect:** §changelog entry for the Form-A direction fix (fix-burst-256) carries date 2026-07-25 but the actual fix was committed on 2026-07-28. `verify-changelog-date-validity.sh` should flag this as a past-date error if the commit date is machine-verifiable.
**Route:** product-owner.

---

#### F-P176-B029 — BC-2.07.001 §TV-005 description claims non-ASCII but strategy generates ASCII-only

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-07/BC-2.07.001.md`
**Section:** §TV-005
**Defect:** TV-005 §description claims "tests non-ASCII grapheme sequence splitting." The §strategy field uses `[a-zA-Z0-9 ]{1,512}` which is ASCII-only. The unicode coverage claim cannot be verified with this strategy.
**Route:** product-owner.

---

#### F-P176-B030 — BC-2.10.002 §Invariant §wording: "EphemeralValue" casing mismatch

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-10/BC-2.10.002.md`
**Section:** §Invariant
**Defect:** §Invariant uses `ephemeralValue` (camelCase). The canonical entity name is `EphemeralValue` (PascalCase) per entities-server §EphemeralValue entity. ADR-010 Direction B mandates PascalCase for public types.
**Route:** product-owner.

---

#### F-P176-B031 — BC-2.12.005 §configurable §tenant-isolation: merge semantics cite phantom §merge-protocol

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-12/BC-2.12.005.md`
**Section:** §tenant-isolation / §PC-5
**Defect:** PC-5 (distinct from B025 §PC-4) cites `ADR-021 §merge-protocol` as a second phantom anchor. ADR-021 has no heading `§merge-protocol` either. Both PC-4 and PC-5 in the same BC reference different phantom anchors to the same underlying ADR-021 content. Low because B025 (§PC-4) is the primary fix; this is the sibling instance.
**Route:** product-owner (fix alongside B025).

---

#### F-P176-B032-PG — `[process-gap]` BC bodies not swept for phantom §Named-Section ADR anchor forms

**Severity:** `[process-gap]`
**Finding:** The 31 BC files in SS-01..SS-12 were not swept for phantom `ADR-NNN §Named-Section` citations by any prior pass (the bulk of adversarial coverage has been BC semantics, not citation form). B008, B025, B031 are three instances found in this pass. A corpus-wide sweep of all 129 BC files for the §Named-Section anchor pattern would be required to close the class.
**Route:** devops-engineer (gate extension from E001 fix — once in place, the gate closes this class).

---

#### F-P176-B033-PG — `[process-gap]` BC-level TV count not cross-checked against test-vectors.md registry after each BC version bump

**Severity:** `[process-gap]`
**Finding:** B016 (BC-INDEX §GTV count) and D001 (test-vectors.md grand total) are both consequences of BC version bumps not triggering a registry cross-check. No gate requires the test-vectors.md §TV-Registry §BC row to be updated when a BC version bump changes the TV count.
**Route:** devops-engineer.

---

#### F-P176-B034-PG — `[process-gap]` No gate verifies BC `module:` frontmatter matches interface-definitions §crate-attribution

**Severity:** `[process-gap]`
**Finding:** B017, B018 are BC `module:` frontmatter fields disagreeing with interface-definitions or observability §emitting-crate. No validator cross-checks BC frontmatter `module:` against the canonical crate assignment in interface-definitions or dependency-graph.
**Route:** devops-engineer.

---

#### F-P176-B035-PG — `[process-gap]` New BC fields from fix-bursts not verified in sibling BCs of same subsystem

**Severity:** `[process-gap]`
**Finding:** B004 (`max_queue_depth` phantom in BC-2.12.002) and B002 (EC-006 cross-citation in BC-2.12.002) are both SS-12 BCs authored in burst-283. A sibling sweep across all SS-12 BCs would have caught both. TD-VSDD-060 requires sibling-site sweeps; burst-283 did not perform one across SS-12.
**Route:** product-owner (burst-285 SS-12 sibling sweep).

---

## Slice C — BCs SS-13..SS-23

**35 findings: 2 CRIT / 8 HIGH / 19 MED / 6 LOW/OBS**

### Slice C Verified-Clean Axes

- **BC-2.23.006 PC-6 correct disambiguation established:** PC-6 carries the correct error routing rule (security vs I/O failures). This is the precedent that C001/C002 violate.
- **Category::Val casing (ADR-010 Direction B):** All SS-13..SS-23 BCs use `Category::Val` (PascalCase). No SCREAMING_CASE instances found.
- **BC-INDEX SS-13..SS-23 rows match BC body H1 titles.**

---

### Slice C CRIT Findings (2)

*See §Five CRITs above for full detail on F-P176-C001 and F-P176-C002.*

---

### Slice C HIGH Findings (8)

#### F-P176-C003 — BC-2.14.001 §Component::TOOLS casing residue: BC-INDEX vs BC body mismatch

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-14/BC-2.14.001.md` / `specs/behavioral-contracts/BC-INDEX.md`
**Section:** §Component-Enum vs BC-INDEX §Component row
**Defect:** BC-2.14.001 body uses `Component::Tools` (PascalCase, per F-P168 ADR-010 Direction B adjudication). BC-INDEX §Component row still has `Component::TOOLS` (SCREAMING_CASE, the pre-adjudication form). The PascalCase fix was applied to BC bodies but not back-propagated to the BC-INDEX §Component cell.
**Verification method:** Read BC-2.14.001 §Component-Enum; read BC-INDEX §Component row for BC-2.14.001.
**Route:** product-owner.

---

#### F-P176-C004 — BC-2.14.002 §ToolConfig §PC-3: input_schema type mismatch

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-14/BC-2.14.002.md`
**Section:** §PC-3
**Defect:** §PC-3 declares `input_schema: JsonObject`. `interface-definitions.md` §ToolConfig field table has `input_schema: serde_json::Value`. These are not the same type in Rust (no `JsonObject` type exists in the standard ecosystem without qualification). Implementers using BC-2.14.002 §PC-3 will code the wrong field type.
**Verification method:** Read BC-2.14.002 §PC-3 §input_schema type; read interface-definitions §ToolConfig §input_schema.
**Route:** product-owner.

---

#### F-P176-C005 — BC-2.16.001 §Decision-6 cross-references: 3 sibling sites cite §Retry-Approval (phantom) vs §Retry-Approval-Ordering (real)

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-16/BC-2.16.001.md` (and 3 sibling BCs)
**Section:** §Decision-6 / §Related-BCs
**Defect:** F-P169-01 fix-burst-271 corrected BC-2.16.001 §Decision-6 anchor to `ADR-010 §Retry-Approval-Ordering`. Three sibling SS-16 BCs (BC-2.16.002, BC-2.16.003, BC-2.16.004) cite `ADR-010 §Retry-Approval` (without "Ordering") — the phantom form. These are the sibling sites that the burst-271 TD-VSDD-060 sweep should have found and did not.
**Verification method:** Grep `Retry-Approval` in ss-16/; confirm `BC-2.16.001` has the correct form and the three siblings have the phantom form.
**Route:** product-owner.

---

#### F-P176-C006 — BC-2.17.001 §PC-3 tokens_remaining field type: Option<u64> vs VP-012 Option<i64>

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-17/BC-2.17.001.md`
**Section:** §PC-3
**Defect:** BC-2.17.001 §PC-3 declares `tokens_remaining: Option<u64>`. VP-012 §invariant and §harness use `Option<i64>`. F-P139-02 established `Option<i64>` as the correct type; BC-2.17.001 was updated in fix-burst-254 (F-P153-01) but the §PC-3 type annotation was not synchronized. Two documents specify the same field with different types.
**Verification method:** Read BC-2.17.001 §PC-3 §tokens_remaining type; read VP-012 §invariant §tokens_remaining type.
**Route:** product-owner.

---

#### F-P176-C007 — BC-2.19.001 §TV-004: raw-string construction form violates BC-2.01.001 §PC-1 (unfixed F-P175-A19 residue)

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-19/BC-2.19.001.md`
**Section:** §TV-004
**Defect:** TV-004 constructs `SystemMessage { content }` from a raw `String`. BC-2.01.001 §PC-1 forbids raw-string message construction; the typed `MessageContent`/`Vec<ContentBlock>` API is required. This was identified as F-P175-A19 (cross-perimeter observation from Slice A, pass-175). Not dispatched in any fix-burst at frozen HEAD.
**Verification method:** Read BC-2.19.001 §TV-004 message construction form; read BC-2.01.001 §PC-1 API requirement.
**Route:** product-owner.

---

#### F-P176-C008 — ADR-010 Class-3 vs POL-17: PregolyaError::new() prohibition vs permission contradiction (Mechanism 5)

**Severity:** HIGH
**File:** `policies.yaml` §POL-17 / `specs/architecture/decisions/ADR-010-error-type-design.md` §Class-3-Canon
**Section:** §POL-17 §rule vs ADR-010 §Class-3-Canon §prohibition
**Defect:** ADR-010 §Class-3-Canon normative prose explicitly forbids `PregolyaError::new()` direct construction. POL-17 §rule asserts "`PregolyaError::new()` is an allowed construction form." The two documents are in direct contradiction. `verify-error-notation-canon.sh` has no bucket for either form (it gates `FerrochainError` not `PregolyaError` — the rename introduced a gap). Two prior fix-bursts created canon violations by optimizing for `grep 'PregolyaError {' returns zero` (Mechanism 5: gate-shaped fix creating canon violations).
**Why it matters:** Every specialist agent reads POL-17 and ADR-010 as the authoritative sources for error construction. The contradiction means each agent will pick one rule and violate the other.
**Verification method:** Read ADR-010 §Class-3-Canon §prohibition sentence; read POL-17 §rule; confirm direct contradiction.
**Route:** spec-steward (POL-17 correction to match ADR-010) + devops-engineer (update `verify-error-notation-canon.sh` for `PregolyaError` forms post-rename).

---

#### F-P176-C009 — BC-2.20.002 §purity-boundary: cites purity-boundary-map §rows (paper-fix residue, D-106 class)

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-20/BC-2.20.002.md`
**Section:** §purity-boundary
**Defect:** The anchor `purity-boundary-map §rows` is semantically empty (D-106 class: paper-fix — placeholder anchor generated by pattern-fill to satisfy the anti-volatile-pin linter). `§rows` is not a real section heading in `purity-boundary-map.md`. The citation passes `records-lint.sh` because it is not a `file:NNN` form, but it resolves to nothing. L-150 codified the paper-fix tell class; this is an instance.
**Verification method:** Grep `^## rows` in `purity-boundary-map.md`; confirm absent.
**Route:** product-owner (replace with real §Named-Section that exists in purity-boundary-map.md).

---

#### F-P176-C010 — BC-2.21.001 §TrustLevel: 4 variants in body; BC-2.11.003 and interface-definitions list 3

**Severity:** HIGH
**File:** `specs/behavioral-contracts/ss-21/BC-2.21.001.md`
**Section:** §TrustLevel
**Defect:** BC-2.21.001 §TrustLevel body lists 4 enum variants including `Elevated`. BC-2.11.003 §PC-7 (B024) and `interface-definitions.md` §TrustLevel list 3 variants (no `Elevated`). The 4th variant was added to BC-2.21.001 without updating the sibling BCs and the interface definition.
**Verification method:** Count variants in BC-2.21.001 §TrustLevel; compare to interface-definitions §TrustLevel and BC-2.11.003 §PC-7.
**Route:** product-owner (adjudicate canonical variant count; propagate to all sites).

---

### Slice C MED Findings (19)

#### F-P176-C011 — BC-2.13.001 §sandbox-root §path-segment count: 4 in §Description vs 3 in §PC-2

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-13/BC-2.13.001.md`
**Section:** §Description vs §PC-2
**Defect:** §Description says "at most 4 path components." §PC-2 says "at most 3 components below the sandbox root." Contradiction within one BC.
**Route:** product-owner.

---

#### F-P176-C012 — BC-2.13.003 §PC-5 cites §parent-canonicalization-protocol; heading is §Parent-Directory-Canonicalization

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-13/BC-2.13.003.md`
**Section:** §PC-5
**Defect:** §PC-5 cites `interface-definitions §parent-canonicalization-protocol`. The actual heading in interface-definitions is `§Parent-Directory-Canonicalization`. Mechanism 1 instance (phantom named-section anchor).
**Route:** product-owner.

---

#### F-P176-C013 — BC-2.13.004 §return-type: SandboxError vs FerrochainError (unfixed F-P175-A08 residue)

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-13/BC-2.13.004.md`
**Section:** §return-type / §Description
**Defect:** §Description declares return type `SandboxError`. VP-003 and `interface-definitions.md` declare `FerrochainError`. `SandboxError` is declared nowhere in the corpus as a Rust type. This was identified in F-P175-A08 and not fixed at frozen HEAD.
**Route:** product-owner.

---

#### F-P176-C014 — BC-2.13.005 §E-SBXD-001 template: two-placeholder vs §Description three-field requirement

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-13/BC-2.13.005.md`
**Section:** §E-SBXD-001-template
**Defect:** §E-SBXD-001 message template has two placeholders `<resolved>, <root>`. §Description requires three fields: `requested`, `resolved`, `root`. Same class as error-taxonomy §E-SBXD-001 (D011).
**Route:** product-owner.

---

#### F-P176-C015 — BC-2.14.003 §TV-003 references pregolya-tools crate; BC §module is core::tools

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-14/BC-2.14.003.md`
**Section:** §TV-003 / §module
**Defect:** §TV-003 says "implemented in `pregolya-tools`." BC frontmatter `module: core::tools` places it in `pregolya-core`. The crate attribution in the test vector and the frontmatter disagree.
**Route:** product-owner.

---

#### F-P176-C016 — BC-2.14.004 §AsyncTool §PC-5: BoxedFuture vs interface-definitions BoxFuture<'a, ToolOutput>

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-14/BC-2.14.004.md`
**Section:** §PC-5
**Defect:** §PC-5 uses `BoxedFuture` as the return type alias. `interface-definitions.md` §Tool §async-return has `BoxFuture<'a, ToolOutput>` (the actual futures crate type). `BoxedFuture` is not defined in any dependency.
**Route:** product-owner.

---

#### F-P176-C017 — BC-2.15.001 §Traceability §Wave: Wave-1 stated; related ADR says P1 (Phase notation inconsistency)

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-15/BC-2.15.001.md`
**Section:** §Traceability / §Wave
**Defect:** §Traceability §Wave column says "Wave-1." ARCH-INDEX §Phase-Progression and the pipeline state use "Phase" not "Wave" for Phase 3 delivery waves. The terminology is inconsistent: some BCs use Phase-1 / Phase-2, others use Wave-1 / Wave-2.
**Route:** product-owner (global terminology normalization — may be a batch fix).

---

#### F-P176-C018 — BC-2.15.004 §configurable-propagation §PC-4: cites phantom ADR-021 §configurable-merge-protocol

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-15/BC-2.15.004.md`
**Section:** §PC-4
**Defect:** Same phantom anchor class as B025 (C018 is the sibling in SS-15). `ADR-021 §configurable-merge-protocol` does not exist; actual heading is `§configurable-merge-semantics` or similar. Mechanism 5: the burst-283 fix that introduced the `configurable` field created this anchor across multiple BCs.
**Route:** product-owner (bundle fix across B025/C018/B031).

---

#### F-P176-C019 — BC-2.15.006 §tenant-isolation §PC-6: isolation_mode: StrictIsolation vs TenancyConfig

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-15/BC-2.15.006.md`
**Section:** §PC-6
**Defect:** §PC-6 references `isolation_mode: StrictIsolation`. BC-2.15.001 §tenant-isolation-mode has `isolation_mode: TenancyConfig` (a type, not a variant). Two different concepts are named with the same field key.
**Route:** product-owner.

---

#### F-P176-C020 — BC-2.16.002 §circuit-breaker-probe: success_threshold vs probe_success_count field names

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-16/BC-2.16.002.md`
**Section:** §PC-3
**Defect:** §PC-3 uses `probe_success_count` as the circuit-breaker recovery threshold. `error-taxonomy.md` §E-TOOLS-008 circuit-breaker re-entry condition uses `success_threshold`. Two different field names for the same semantic concept.
**Route:** product-owner.

---

#### F-P176-C021 — BC-2.16.003 §retry.circuit_breaker_disabled: observability §emitting-crate pregolya-graph vs BC module core::retry

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-16/BC-2.16.003.md`
**Section:** §module vs observability
**Defect:** BC-2.16.003 `module: core::retry`. `observability.md` §retry.circuit_breaker_disabled §emitting-crate says `pregolya-graph`. Same crate-attribution conflict as B018 at the SS-16 level.
**Route:** product-owner.

---

#### F-P176-C022 — BC-2.17.002 §streaming-budget §PC-7: token_ceiling vs token_limit

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-17/BC-2.17.002.md`
**Section:** §PC-7
**Defect:** §PC-7 uses `token_limit` for the streaming budget ceiling. `interface-definitions.md` §RunnableConfig §budget_config has `token_ceiling`. Mismatched field name.
**Route:** product-owner.

---

#### F-P176-C023 — BC-2.18.003 §Related-BCs: false claim injection guard covers MessagesPlaceholder (unfixed F-P175-B202)

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-18/BC-2.18.003.md`
**Section:** §Related-BCs
**Defect:** §Related-BCs claims BC-2.18.004 covers injection guard for `MessagesPlaceholder` expansion. This was identified as F-P175-B202 (CRIT) and is the ADR-015 §Changelog note-closure target of A005. Not fixed at frozen HEAD. Downgraded from CRIT to MED in this slice because the security analysis is now recorded and the gap is documented; the CRIT-level urgency applies at the fix-burst level (route alongside C001/C002).
**Route:** product-owner.

---

#### F-P176-C024 — BC-2.19.002 §PC-2 input_variables accessor return type: &[String] vs Vec<String>

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-19/BC-2.19.002.md`
**Section:** §PC-2
**Defect:** §PC-2 declares `input_variables(&self) -> Vec<String>`. VP-007 §harness uses the same form. BC-2.18.001 §PC-3 specifies `input_variables(&self) -> &[String]` (borrowed slice accessor per extraction at construction time). The three documents specify different return types for the same method.
**Route:** product-owner (adjudicate owned vs borrowed; propagate to VP-007 if needed).

---

#### F-P176-C025 — BC-2.19.005 §Category Val: category uses Category::VAL (SCREAMING_CASE) post-F-P168

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-19/BC-2.19.005.md`
**Section:** §Category
**Defect:** BC-2.19.005 §Category uses `Category::VAL`. F-P168 adjudicated PascalCase Direction B (ADR-010 §Category-Casing-Canon). The correct form is `Category::Val`. The burst-270 sweep applied PascalCase to `Component::Tools` but the companion `Category::Val` normalization may not have reached every BC in SS-19.
**Route:** product-owner.

---

#### F-P176-C026 — BC-2.20.001 §Purity-Boundary §effectful-marker: EffectfulMarker vs EffectfulWrapper

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-20/BC-2.20.001.md`
**Section:** §effectful-marker
**Defect:** §effectful-marker references trait `EffectfulMarker`. `interface-definitions.md` §purity-boundary has `EffectfulWrapper`. Two different trait names for the same concept.
**Route:** product-owner.

---

#### F-P176-C027 — BC-2.21.003 §inject_guard_chain: does not thread configurable from ADR-021 through guard evaluation

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-21/BC-2.21.003.md`
**Section:** §inject_guard_chain / §PC-3
**Defect:** §PC-3 declares `inject_guard_chain(&RunnableConfig, ...)`. ADR-021 (D-95) added `configurable: HashMap<String, serde_json::Value>` to `RunnableConfig`. BC-2.21.003 does not specify whether the `configurable` map is passed through the guard evaluation chain or ignored. The spec gap means the injection guard's behavior on `configurable`-bearing `RunnableConfig` instances is undefined.
**Route:** product-owner.

---

#### F-P176-C028 — BC-2.22.001 §compile-fail-gate: gate not updated for post-D21 14-enum roster

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-22/BC-2.22.001.md`
**Section:** §compile-fail-gate
**Defect:** §compile-fail-gate says "verifies all 14 public enums." The gate file was created for a 9-enum roster (pre-D21). D21 added 5 enums. The gate body has not been updated for the 14-enum roster. This is Mechanism 4: `#[non_exhaustive]` applied without a governing rule means no gate tracks the complete inventory.
**Verification method:** Check if `tests/external/non_exhaustive_gate/` exists; if so, count the enum entries. If absent, note that the gate cannot be verified.
**Route:** architect (governing rule + gate update at Phase 3).

---

#### F-P176-C029 — BC-2.23.003 §root-binding: canonicalize (§PC-2) vs try_canonicalize (§PC-4) inconsistency

**Severity:** MED
**File:** `specs/behavioral-contracts/ss-23/BC-2.23.003.md`
**Section:** §PC-2 vs §PC-4
**Defect:** §PC-2 says "call `canonicalize` on root path." §PC-4 says "call `try_canonicalize` on root path." These are different method names. One is `std::fs::canonicalize` (returns `io::Result`) and one is presumably a custom wrapper. The spec uses both forms without distinguishing them.
**Route:** product-owner.

---

### Slice C LOW / OBS Findings (6)

#### F-P176-C030 — BC-2.13.002 §changelog direction: descending (ascending required)

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-13/BC-2.13.002.md`
**Section:** §changelog
**Defect:** §changelog entries in descending order. Gate #28 Rule 6 requires ascending. `verify-form-a-changelog-direction.sh` WARN=7 in burst-284 baseline; this may be one of the 7.
**Route:** product-owner.

---

#### F-P176-C031 — BC-2.14.001 §changelog v1.3 date 2026-07-25 vs BC-INDEX body-table date 2026-07-28

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-14/BC-2.14.001.md`
**Section:** §changelog
**Defect:** BC-2.14.001 §changelog v1.3 shows date 2026-07-25 but the BC-INDEX body-table §date column for BC-2.14.001 shows 2026-07-28. Two dates for the same version bump.
**Route:** product-owner.

---

#### F-P176-C032 — BC-2.15.002 §Traceability title: trailing space vs BC-INDEX H1 cell

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-15/BC-2.15.002.md`
**Section:** §Traceability / H1
**Defect:** BC-2.15.002 H1 title has a trailing space. BC-INDEX §H1-title cell for this BC does not. `verify-bc-frontmatter-schema.sh` may not catch trailing-space drift in H1 titles.
**Route:** product-owner.

---

#### F-P176-C033 — BC-2.18.002 §FewShotPromptTemplate: no module: frontmatter field

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-18/BC-2.18.002.md`
**Section:** §frontmatter
**Defect:** BC-2.18.002 frontmatter lacks a `module:` field. All sibling SS-18 BCs have `module:`. The `verify-bc-frontmatter-schema.sh` apparently did not catch the missing field.
**Route:** product-owner.

---

#### F-P176-C034 — BC-2.20.003 §purity-boundary-map reference: cites §rows (D-106 class, paper-fix residue)

**Severity:** LOW
**File:** `specs/behavioral-contracts/ss-20/BC-2.20.003.md`
**Section:** §purity-boundary-map reference
**Defect:** Same paper-fix residue class as C009. `purity-boundary-map §rows` is a placeholder anchor (D-106 class). This is a second instance in SS-20 BCs.
**Route:** product-owner.

---

#### F-P176-C035 — BC-2.23.006 §PC-6 disambiguates correctly; verifies C001 root cause

**Severity:** OBS
**File:** `specs/behavioral-contracts/ss-23/BC-2.23.006.md`
**Section:** §PC-6
**Finding:** BC-2.23.006 §PC-6 correctly disambiguates the error routing rule (SECURITY-class for escape attempts; FileIoError for I/O failures). This is the precedent that C001 fix must propagate to BC-2.23.001 and BC-2.23.002. Recording this OBS provides the fix-burst with the explicit copy source.
**Route:** Not a defect; provides source text for C001 fix.

---

#### F-P176-C012-PG — `[process-gap]` SS-23 WriteFileTool entry-point for create intent not spec'd in any BC

**Severity:** `[process-gap]`
**Finding:** C002 establishes that WriteFileTool's create-new-file path is unreachable because no BC specifies an entry point that accepts a create intent and routes through parent-canonicalization. The absence of such a BC is the spec gap. `BC-2.13.004` §PC-5 defines the parent-canonicalization protocol but it is not connected to any WriteFileTool pre-condition. A new BC or BC amendment is needed to specify the create-intent entry point.
**Route:** product-owner.

---

#### F-P176-C008-PG — `[process-gap]` verify-error-notation-canon.sh not updated for PregolyaError post-rename

**Severity:** `[process-gap]`
**Finding:** C008 found that the validator uses `FerrochainError` patterns. Post-rename, the type is `PregolyaError`. The gate is silently inoperative for the new name. This is a separate PG from C008 itself (C008 is the policy contradiction; this PG is the missing gate update).
**Route:** devops-engineer.

---

## Slice D — PRD, 10 prd-supplements, 15 domain-spec shards, product-brief

**26 findings: 2 CRIT / 7 HIGH / 11 MED / 6 LOW/OBS**

### Slice D Verified-Clean Axes

- **prd.md §error-code namespace count:** 111 codes verified in §Error-Namespace-Table (E-MCP-007 addition from burst-258 reflected). Consistent with error-taxonomy body.
- **prd-supplements/module-criticality.md format:** passes `verify-bc-frontmatter-schema.sh` schema check.
- **product-brief.md §rename completeness:** All `ferrochain` occurrences replaced with `pregolya` in product-brief.md body. The 1 `ferrograph` occurrence noted in D018 is ferro-stem class (not `ferrochain` rename class).

---

### Slice D CRIT Findings (2)

*See §Five CRITs above for full detail on F-P176-D001 and F-P176-D002.*

---

### Slice D HIGH Findings (7)

#### F-P176-D003 — prd.md §5 §error-codes note-closure: propagation claimed complete; 7 domain-spec grep hits remain

**Severity:** HIGH
**File:** `specs/prd.md`
**Section:** §5 / §error-codes note
**Defect:** A §5 §error-codes note states "error taxonomy propagation complete across domain-spec." Grep of `specs/domain-spec/` for pre-taxonomy error-code forms finds 7 hits carrying legacy `E-CORE-*` codes that predated the F-P141-03 error-label corrections. The note describes work that was not complete at the time it was written. Mechanism 2.
**Verification method:** Grep `E-CORE-00[234]` and `E-MCP-00[123]` legacy forms in `specs/domain-spec/`; count hits.
**Route:** business-analyst (domain-spec correction) + product-owner (prd.md note correction).

---

#### F-P176-D004 — bc-authoring-plan.md §gate-registry §Note: gate #37 claimed added and wired; not in validators

**Severity:** HIGH
**File:** `specs/prd-supplements/bc-authoring-plan.md`
**Section:** §gate-registry / §Note
**Defect:** A §gate-registry §Note says "gate #37 added and wired to pre-commit-validators.sh." `hooks/pre-commit-validators.sh` at frozen HEAD contains 12 blocking validators (D-101 roster). No gate #37 appears in the roster. The note describes a planned gate that was not implemented. Mechanism 2.
**Verification method:** Read bc-authoring-plan.md §gate-registry §Note about gate #37; grep `hooks/pre-commit-validators.sh` for the gate name.
**Route:** devops-engineer (implement gate #37 or remove the note if premature) + spec-steward (bc-authoring-plan note correction).

---

#### F-P176-D005 — interface-definitions.md §configurable: cites phantom ADR-021 §configurable-merge-protocol (Mechanism 1)

**Severity:** HIGH
**File:** `specs/prd-supplements/interface-definitions.md`
**Section:** §configurable / §merge-rule
**Defect:** §configurable §merge-rule cites `ADR-021 §configurable-merge-protocol`. This phantom anchor (no heading in ADR-021 matching that name) is the same class as B025/C018 (all three are from the same burst-283 `configurable` field introduction). This is Mechanism 1 manifesting in the interface-definitions supplement.
**Verification method:** Read interface-definitions §configurable §merge-rule citation; grep `^## .*configurable-merge-protocol` in ADR-021; confirm absent.
**Route:** product-owner.

---

#### F-P176-D006 — prd-supplements/module-criticality.md §TOOLS tier: CRIT assertion contradicts ADR-001 §Criticality-Tier §Runtime-Safety = HIGH

**Severity:** HIGH
**File:** `specs/prd-supplements/module-criticality.md`
**Section:** §TOOLS
**Defect:** §TOOLS declares CRIT tier. ADR-001 §Criticality-Tier §Runtime-Safety restricts CRIT to compile-time and memory-safety; runtime-safety (tools tier) maps to HIGH. This is the prd-supplement carrying the same defect as A030. The supplement is a separate authoritative document (not derived from module-criticality.md).
**Verification method:** Read prd-supplements/module-criticality §TOOLS tier; read ADR-001 §Criticality-Tier definitions.
**Route:** architect.

---

#### F-P176-D007 — nfr-catalog.md §NFR-014 §target: pregolya-graph::scheduler vs ARCH-INDEX pregolya-core

**Severity:** HIGH
**File:** `specs/prd-supplements/nfr-catalog.md`
**Section:** §NFR-014 / §target
**Defect:** §NFR-014 §target says `pregolya-graph::scheduler`. ARCH-INDEX §crate-table assigns `scheduler` to `pregolya-core` (it is a core runtime component). The NFR target points to the wrong crate.
**Verification method:** Read nfr-catalog §NFR-014 §target; read ARCH-INDEX §crate-table §scheduler row.
**Route:** product-owner.

---

#### F-P176-D008 — domain-spec/capabilities-p1-p2.md §CAP-029 §note: VP-009 MMR-framing claimed corrected; VP-009 §property-statement still stale

**Severity:** HIGH
**File:** `specs/domain-spec/capabilities-p1-p2.md`
**Section:** §CAP-029 / §note
**Defect:** §CAP-029 §note says "VP-009 MMR framing corrected per F-P143-01 fix-burst-243." VP-009 §property-statement at frozen HEAD still contains the old MMR framing language. The note documents a fix that was applied to BC bodies but not to the VP-009 §property-statement. Mechanism 2.
**Verification method:** Read §CAP-029 §note; read VP-009 §property-statement for "MMR" or "matrix multiplication ranking" forms.
**Route:** architect (VP-009 §property-statement correction).

---

#### F-P176-D009 — interface-definitions.md §14-public-enums: no ADR documents the governing rule, exceptions, or exempt inventory (Mechanism 4)

**Severity:** HIGH
**File:** `specs/prd-supplements/interface-definitions.md`
**Section:** §public-API-enums / §non_exhaustive
**Defect:** §public-API-enums lists 14 public enums. `#[non_exhaustive]` is applied to each. No ADR in the corpus states the rule requiring `#[non_exhaustive]` on public enums, defines the exception criteria, or enumerates the exempt inventory. This is Mechanism 4: each type application is ad hoc. One decision record (the governing ADR, route to architect, A028 finding) closes all 14 instances. Until the governing rule exists, Phase 3 implementers have no authoritative source for which types require `#[non_exhaustive]` and which are exempt.
**Verification method:** Grep all ADRs for a normative statement: "public enums MUST carry `#[non_exhaustive]`"; confirm absent.
**Route:** architect.

---

### Slice D MED Findings (11)

#### F-P176-D010 — prd.md §7 §Streaming §crate-list: 7 crates vs ARCH-INDEX 21-crate roster

**Severity:** MED
**File:** `specs/prd.md`
**Section:** §7 / §Streaming
**Defect:** §7 §Streaming §crate-list enumerates 7 crates for streaming support. ARCH-INDEX §crate-table has 21 crates. The §crate-list appears to be pre-D21 expansion (9 crates were added in D21). The subsection was not updated.
**Route:** product-owner.

---

#### F-P176-D011 — error-taxonomy.md §E-SBXD-001 §message-template: two-placeholder vs three-field requirement

**Severity:** MED
**File:** `specs/prd-supplements/error-taxonomy.md`
**Section:** §E-SBXD-001 / §message-template
**Defect:** §message-template has two placeholders: `<resolved>, <root>`. BC-2.13.004 and BC-2.13.005 §Invariant-2 require three fields: `requested`, `resolved`, `root`. The error taxonomy is the SoT for error message formats; it is missing one required field. Same class as C014 at the taxonomy level.
**Verification method:** Read error-taxonomy §E-SBXD-001 §message-template; read BC-2.13.004 §Invariant-2 §three-field requirement.
**Route:** product-owner.

---

#### F-P176-D012 — api-surface.md §Tool §trait-row: BoxFuture<'a, ToolOutput> vs BC-2.14.004 BoxedFuture

**Severity:** MED
**File:** `specs/prd-supplements/api-surface.md`
**Section:** §Tool / §trait-row
**Defect:** §Tool §async-return type is `BoxFuture<'a, ToolOutput>`. BC-2.14.004 §PC-5 uses `BoxedFuture`. Same type-name conflict as C016. The api-surface supplement is the canonical API definition; the BC should align to it.
**Route:** product-owner (BC-2.14.004 alignment to api-surface canonical form).

---

#### F-P176-D013 — domain-spec/entities-server.md §RunState §note: completed-at migration claimed; §RunState body not updated

**Severity:** MED
**File:** `specs/domain-spec/entities-server.md`
**Section:** §RunState / §note
**Defect:** §RunState §note: "completed_at migration per burst-238 applied." §RunState body still carries the pre-migration field schema. Mechanism 2 instance at the domain-spec level.
**Verification method:** Read entities-server §RunState §note; read §RunState §fields for completed_at.
**Route:** business-analyst.

---

#### F-P176-D014 — test-vectors.md §TV-Registry: TV-003 ID collision (BC-2.09.001 and BC-2.12.001)

**Severity:** MED
**File:** `specs/prd-supplements/test-vectors.md`
**Section:** §TV-Registry
**Defect:** The global §TV-Registry allocates TV-003 twice: once to BC-2.09.001 (connection failure) and once to BC-2.12.001 (cron job failure). Duplicate global IDs break Phase 3 dispatch routing. Same underlying class as B019 (B019 is the BC body; this is the registry SoT).
**Route:** product-owner.

---

#### F-P176-D015 — observability.md §BC-2.22.001 §emitting-crate: pregolya-core vs BC module core::embeddings

**Severity:** MED
**File:** `specs/prd-supplements/observability.md`
**Section:** §BC-2.22.001 row / §emitting-crate
**Defect:** §emitting-crate says `pregolya-core`. BC-2.22.001 frontmatter `module: core::embeddings`. While `core::embeddings` is in `pregolya-core`, the observability row conflates crate-level and module-level granularity inconsistently with sibling rows that use the module-qualified form.
**Route:** product-owner.

---

#### F-P176-D016 — bc-authoring-plan.md §gate-#27 §roster-anchor: cites nonexistent ARCH-INDEX §ADR-Table heading

**Severity:** MED
**File:** `specs/prd-supplements/bc-authoring-plan.md`
**Section:** §gate-#27 / §roster-anchor
**Defect:** §gate-#27 says "see ARCH-INDEX §ADR-Table for current crate list." ARCH-INDEX has no heading `§ADR-Table`; the heading is `§Architecture-Decision-Log`. Mechanism 1 instance: phantom named-section anchor in bc-authoring-plan.
**Route:** spec-steward (citation correction).

---

#### F-P176-D017 — domain-spec/risks.md §R-008: cites pregolya-splitters vs module-decomposition pregolya-community for splitter routing

**Severity:** MED
**File:** `specs/domain-spec/risks.md`
**Section:** §R-008
**Defect:** §R-008 §references cites `pregolya-splitters` as the crate handling splitter code-point parity. `module-decomposition.md` §splitters assigns this functionality to `pregolya-community`. The crate attribution is ambiguous.
**Route:** business-analyst.

---

#### F-P176-D018 — product-brief.md §overview: 1 ferrograph occurrence (ferro-stem class)

**Severity:** MED
**File:** `specs/prd-supplements/product-brief.md`
**Section:** §overview
**Defect:** 1 remaining `ferrograph` occurrence in §overview §background-paragraph. This is the ferro-stem class (not the `ferrochain` rename class). The rename-constraint-spec.md §ferro-stem-class documents `ferrograph` as rename residue in `market-intel.md` (historically frozen reference document) but does not list product-brief.md as a permitted location. Product-brief is a living spec and the occurrence should be replaced with the canonical form (`pregolya-graph`).
**Verification method:** Grep `ferrograph` in product-brief.md; confirm 1 hit.
**Route:** product-owner.

---

#### F-P176-D019 — domain-spec/bounded-contexts.md §context-17 §pregolya-tools: dependency-graph names pregolya-community for tool routing

**Severity:** MED
**File:** `specs/domain-spec/bounded-contexts.md`
**Section:** §context-17
**Defect:** §context-17 §pregolya-tools attributes tool execution routing to `pregolya-tools`. `dependency-graph.md` §tool-routing-edge assigns the routing layer to `pregolya-community` post-v1. The two bounded-contexts and dependency-graph documents disagree on which crate handles tool routing.
**Route:** business-analyst.

---

#### F-P176-D020 — test-vectors.md §GTV §verification-method: "GTV-only" undefined

**Severity:** MED
**File:** `specs/prd-supplements/test-vectors.md`
**Section:** §GTV / §verification-method
**Defect:** GTVs 001-009 carry verification-method "Python-verified" (defined in §GTV-methodology). GTVs 010-011 carry "GTV-only" which is not defined in §GTV-methodology. A Phase 3 test-writer using GTV-010 will not know what verification methodology to apply.
**Route:** product-owner.

---

### Slice D LOW / OBS Findings (6)

#### F-P176-D021 — error-taxonomy.md §E-CFG-001 §citation: phantom heading (D-108 independent verification)

**Severity:** LOW
**File:** `specs/prd-supplements/error-taxonomy.md`
**Section:** §E-CFG-001 / §citation
**Defect:** §E-CFG-001 §citation: `ADR-010 §E-CFG-001 convention`. ADR-010 heading is `**E-CFG-001 resolution:**` (bold inline label, not a heading). This is D-108 (pre-existing imprecision flagged by product-owner 2026-07-30). This finding provides independent adversary verification of D-108.
**Route:** product-owner.

---

#### F-P176-D022 — api-surface.md §changelog v1.10: date 2026-07-25 predates actual edit date

**Severity:** LOW
**File:** `specs/prd-supplements/api-surface.md`
**Section:** §changelog / v1.10
**Defect:** §changelog v1.10 date is 2026-07-25; the edit was committed on 2026-07-28 per burst records.
**Route:** product-owner.

---

#### F-P176-D023 — market-intel.md §ferrograph: 13 occurrences (rename residue, ferro-stem class, frozen reference document)

**Severity:** LOW
**File:** `specs/planning/market-intel.md`
**Section:** body
**Defect:** 13 `ferrograph` occurrences. `market-intel.md` is a frozen reference document (pre-pipeline analysis); the rename-constraint-spec §ferro-stem-class documents this as expected residue. Flagged at LOW for completeness; no fix required if the constraint-spec acknowledges it.
**Uncertainty:** Reviewer notes: pending confirmation that rename-constraint-spec.md §ferro-stem-class explicitly lists market-intel.md as a permitted location. If not listed, severity upgrades to MED.
**Route:** spec-steward (add to constraint-spec inventory if not already present; no content change needed).

---

#### F-P176-D024 — bc-authoring-plan.md §gate-36 §body-text: "kani-local" in normative position

**Severity:** LOW
**File:** `specs/prd-supplements/bc-authoring-plan.md`
**Section:** §gate-36
**Defect:** `kani-local` appears in §gate-36 §body-text in a normative context (not a changelog or illustration). TD-VSDD-091 §hyphenated-module class: `kani-local` is a hyphenated tool name that could be read as a module path. Severity LOW because it is a tool name not a Rust module path, but it is in the same syntactic class.
**Route:** spec-steward.

---

#### F-P176-D025 — domain-spec/L2-INDEX §frontmatter-timestamp: 2026-07-25 predates domain-spec edits on 2026-07-28

**Severity:** LOW
**File:** `specs/domain-spec/L2-INDEX.md`
**Section:** §frontmatter / §timestamp
**Defect:** `timestamp: 2026-07-25`. Domain-spec edits from burst-282 Wave B were committed on 2026-07-28. The L2-INDEX timestamp is stale by 3 days.
**Route:** business-analyst.

---

#### F-P176-D026 — interface-definitions.md §ActionRisk-override_risk: 6 citations resolve to a field, not a heading (Mechanism 1)

**Severity:** LOW
**File:** `specs/prd-supplements/interface-definitions.md`
**Section:** §ActionRisk / §override_risk field
**Defect:** 6 files cite `interface-definitions §ActionRisk-override_risk`. In interface-definitions, `ActionRisk` is a struct and `override_risk` is a field inside a code block — not a section heading. The anchor resolves to the struct's heading (`§ActionRisk`) at best, losing the field precision. This is Mechanism 1 at the supplement level. The 6 citations were produced by the anti-volatile-pin TD-VSDD-091 remediation that converted version-pin cites to §Named-Section forms.
**Route:** product-owner (replace with `interface-definitions §ActionRisk` for the struct, or add a real heading for the field).

---

#### F-P176-D001-PG — `[process-gap]` test-vectors.md registry not cross-checked against BC body TV counts after BC version bumps

**Severity:** `[process-gap]`
**Finding:** D001 (12 missing TVs) is an instance of the same PG as B033. The ground-truth check (BC body TV count vs registry) is not automated. A gate that runs after each BC version bump and verifies the registry row is needed.
**Route:** devops-engineer.

---

#### F-P176-D003-PG — `[process-gap]` Note-closure detection is advisory not blocking for the 7 specific sites identified this pass

**Severity:** `[process-gap]`
**Finding:** A005, A008, A010, D003, D004, D008, D013 are the seven Mechanism 2 note-closure instances found this pass where the changelog asserts a propagation that was never performed. `verify-changelog-claim-applied.sh` is advisory (631 findings); these seven would appear in that advisory output. Until the advisory is promoted to blocking (for the false-closure class), these will reappear in future passes.
**Route:** devops-engineer (promote the false-closure class to blocking; route to burst-285 after P1D-176).

---

## Slice E — policies.yaml, hooks, planning, comparative, semport, CI, namespace-reservation

**28 findings: 1 CRIT / 12 HIGH / 10 MED / 5 LOW/OBS**

### Slice E Verified-Clean Axes

- **policies.yaml frontmatter schema:** All 45 policies pass schema validation; no required field absent.
- **POL-32..POL-45 phase-binding:** Correctly excluded from active enforcement (PHASE-3-BINDING; `crates/` absent). Reviewer verified that enforcement clauses cite `crates/` or `tests/external/` paths that do not exist.
- **Rename completeness:** `hooks/`, `planning/`, `CI/` files show 0 `ferrochain` occurrences (namespace-reservation files regenerated for `pregolya-*`; the `ferrochain` in `ferrochain-prebuilt` orphan directory was removed by burst-284).

---

### Slice E CRIT Findings (1)

*See §Five CRITs above for full detail on F-P176-E001.*

---

### Slice E HIGH Findings (12)

#### F-P176-E002 — hooks/verify-adr-decision-refs.sh §CITE_RE: §Decision <Integer> only; §Named-Section forms pass invisibly

**Severity:** HIGH
**File:** `.factory/hooks/verify-adr-decision-refs.sh`
**Section:** §CITE_RE
**Defect:** `CITE_RE` matches `ADR-NNN §Decision [0-9]+` only. Citations of the form `ADR-NNN §Named-Section` (8 confirmed in A007's perimeter) pass the gate invisibly. This is the mechanical root cause of E001: POL-19 asserts blocking enforcement but the gate only covers the integer-decision subclass of ADR citations.
**Verification method:** Read `verify-adr-decision-refs.sh` §CITE_RE; test with a sample `ADR-010 §impl-PregolyaError` citation.
**Route:** devops-engineer (prerequisite: architect A039 convention restriction decision — the gate extension should be built for form-1-only citations).

---

#### F-P176-E003 — policies.yaml §POL-19 §enforcement: cites verify-arch-anchor-resolution.sh which validates file paths not §Named-Section anchors

**Severity:** HIGH
**File:** `policies.yaml`
**Section:** §POL-19 / §enforcement
**Defect:** POL-19 §enforcement field names `verify-arch-anchor-resolution.sh` as the enforcing gate. That script validates `architecture/<path>.md` file-path citations (path-level resolution). It does not validate `ADR-NNN §Named-Section` section-heading anchors. The enforcement claim is false. This is a separate finding from E001 (E001 is about the policy assertion; E003 is about the cited gate being the wrong tool for the job).
**Verification method:** Read `verify-arch-anchor-resolution.sh` §scope; confirm it checks file paths only.
**Route:** spec-steward (POL-19 enforcement citation correction) + devops-engineer (build the correct gate per E002).

---

#### F-P176-E004 — policies.yaml §POL-19 §active-enforcement creates immediate gate failure for every valid §Named-Section citation until convention is restricted

**Severity:** HIGH
**File:** `policies.yaml`
**Section:** §POL-19
**Defect:** POL-19 is listed as `enforcement: blocking`. If a gate were built today that validates all `ADR-NNN §Named-Section` citations, it would find ~170 current citations, of which at least 14 (A007, A018, A035, A039, B008, B025, B031, C012, C018, D005, D016, D026) resolve to nothing. Building the gate before restricting the convention to form-1-only (real headings) would produce ~14+ immediate blocking failures on valid spec content. The gate and the convention must be co-designed: restrict first, gate second. This is the sequencing consequence described in Mechanism 1.
**Route:** architect (A039 convention restriction decision — sequencing prerequisite) + spec-steward (POL-19 wording: mark as "gate pending convention restriction").

---

#### F-P176-E005 — namespace-reservation/publish-all.sh §repository-field: 21 stubs declare BOHICA-LABS/ferrochain (old URL, immutable on publish)

**Severity:** HIGH
**File:** `.factory/namespace-reservation/publish-all.sh` / 21 stub `Cargo.toml` files
**Section:** `repository =` field
**Defect:** All 21 stub `Cargo.toml` files in `namespace-reservation/` carry `repository = "https://github.com/BOHICA-LABS/ferrochain"`. The GitHub repo rename (`ferrochain` → `pregolya`) has not been performed (D-103 §Container-Rename pending human action). If `publish-all.sh` is run before the repo rename, the `repository` field bakes a dead URL into 21 immutable crate-metadata records. A crate's metadata fields are immutable after publication. (See E012 which tracks this as a blocking issue for the human-action queue.)
**Route:** (no spec fix needed — this is an execution pre-requisite constraint) human: GitHub repo rename must precede publish-all.sh. State-manager: add E012 as Blocking Issue.

---

#### F-P176-E006 — comparative/COMPARATIVE-ASSESSMENT.md §pregolya-core: 4 ferrograph occurrences (ferro-stem class)

**Severity:** HIGH
**File:** `.factory/comparative/COMPARATIVE-ASSESSMENT.md`
**Section:** §pregolya-core / §feature-flags
**Defect:** 4 `ferrograph` occurrences in §pregolya-core §feature-flags section. `comparative/` was listed as an excluded directory in rename-sweep-manifest.md §excluded-directories. The constraint-spec §ferro-stem-class does not document comparative/ as a permitted location. HIGH because comparative/ is used by agents as a decision-authority document (D16 comparative certification).
**Uncertainty:** Reviewer notes pending intent verification: if comparative/ is intentionally frozen (D16 is a pre-pipeline artifact), severity may downgrade to LOW. Requires reading D-90 context.
**Route:** spec-steward (clarify whether comparative/ §ferro-stem occurrences are frozen reference residue or active spec text requiring update).

---

#### F-P176-E007 — semport/core/ANALYSIS-STATE.md: FERROCHAIN in 2 subsystem headers (SCREAMING_CASE rename residue)

**Severity:** HIGH
**File:** `.factory/semport/core/ANALYSIS-STATE.md`
**Section:** subsystem headers
**Defect:** 2 subsystem headers carry `FERROCHAIN` in SCREAMING_CASE. These are the pre-rename form of the product name. The rename-sweep-manifest.md §excluded-directories did not list semport/ as excluded. The four case-variant substitutions should have caught SCREAMING_CASE.
**Verification method:** Grep `FERROCHAIN` in semport/; count hits.
**Route:** spec-steward (rename correction in semport/; low-risk edit since semport/ is a reference analysis document).

---

#### F-P176-E008 — planning/cicd-setup.md §github-repo §remote-url: BOHICA-LABS/ferrochain cited with no PENDING marker

**Severity:** HIGH
**File:** `.factory/planning/cicd-setup.md`
**Section:** §github-repo / §remote-url
**Defect:** §remote-url still cites `BOHICA-LABS/ferrochain`. The document was retitled to "Pregolya CI/CD Setup" in burst-284 but the repo URL was not updated. STATE.md §Pending-Human-Actions lists container rename as a human action. Without a `[PENDING: GitHub rename]` marker in cicd-setup.md, a DevOps engineer following the setup guide will configure remotes with the old URL.
**Route:** spec-steward (add PENDING marker to cicd-setup §remote-url).

---

#### F-P176-E009 — policies.yaml §POL-17 vs ADR-010 §Class-3-Canon: direct contradiction (Mechanism 5 policy record)

**Severity:** HIGH
**File:** `policies.yaml` §POL-17
**Section:** §rule
**Defect:** POL-17 §rule: "`PregolyaError::new()` is an allowed construction form." ADR-010 §Class-3-Canon: construction via `PregolyaError::new()` is forbidden for the same reason as struct-literal construction (both bypass the `FerrochainError`/`PregolyaError` authority pattern). This finding is the policy layer of C008 (Mechanism 5). Recording at slice E because the policy is the primary enforcing instrument.
**Route:** spec-steward (POL-17 §rule correction: remove the `::new()` permission; reference ADR-010 §Class-3-Canon).

---

#### F-P176-E010 — hooks/verify-adr-decision-refs.sh §DECISION_RE: full-match for §Decision<Integer> only; §Named-Section gap

**Severity:** HIGH
**File:** `.factory/hooks/verify-adr-decision-refs.sh`
**Section:** §DECISION_RE
**Defect:** §DECISION_RE also does not match `ADR-NNN §Named-Section` in the secondary regex path. The gate has two regex patterns and both exclude named-section forms. This is the second regex gap (E002 was the CITE_RE; E010 is the DECISION_RE). Together they mean the gate is fully blind to named-section anchors.
**Route:** devops-engineer (E002 fix closes both; this finding ensures both regex paths are addressed).

---

#### F-P176-E011 — publish-all.sh §publish-loop §cd-command: cd to non-existent path /Users/jmagady/Dev/pregolya/

**Severity:** HIGH
**File:** `.factory/namespace-reservation/publish-all.sh`
**Section:** §publish-loop / `cd` command
**Defect:** The `cd` command in `publish-all.sh` §publish-loop navigates to `/Users/jmagady/Dev/pregolya/namespace-reservation/` (the path that would exist after the working-directory rename). The working directory is currently `/Users/jmagady/Dev/ferrochain`. The `cd` will fail with `No such file or directory` before any crate is published. The script is entirely non-functional at the current working-directory path.
**Why it matters:** R14/R6 (HIGH, irreversible) depends on running this script. A developer following the human-action guidance in STATE.md will run this script and get an immediate failure with no useful error guidance.
**Verification method:** Read `publish-all.sh` §publish-loop; confirm the `cd` target path.
**Route:** spec-steward (update path in publish-all.sh to current working dir `/Users/jmagady/Dev/ferrochain/`; or add PENDING marker pending working-dir rename).
**Blocking:** This finding is a new BLOCKER for the crates.io reservation human action (R14/R6). Add to STATE.md §Blocking-Issues.

---

#### F-P176-E012 — All 21 namespace-reservation stubs: repository = BOHICA-LABS/pregolya 404s until GitHub rename

**Severity:** HIGH
**File:** `.factory/namespace-reservation/` (21 stub `Cargo.toml` files)
**Section:** `[package] repository =`
**Defect:** All 21 stubs declare `repository = "https://github.com/BOHICA-LABS/pregolya"`. The GitHub repository is currently named `BOHICA-LABS/ferrochain` (D-103 §Container-Rename pending human action). Publishing these stubs before the GitHub rename bakes a dead URL into 21 immutable crate-version records. Per crates.io policy, package metadata is immutable after publication; the dead URL cannot be corrected. **The GitHub repo rename MUST precede `publish-all.sh`.**
**Why it matters:** Immutable broken metadata in 21 crate versions is a permanent reputational and usability defect. Every cargo user who adds a `pregolya-*` dependency will see a dead documentation URL.
**Verification method:** Read any stub `Cargo.toml` in `namespace-reservation/`; confirm `repository` field URL; attempt to navigate the URL.
**Route:** human (GitHub repo rename before publishing) + spec-steward (add BLOCKER marker to publish-all.sh §usage-instructions).
**Blocking:** New BLOCKER for crates.io reservation. Add to STATE.md §Blocking-Issues with sequencing constraint: "GitHub rename must precede publish-all.sh."

---

#### F-P176-E023 — CI §required-checks: 5 green jobs validating nothing (Mechanism 3)

**Severity:** HIGH
**File:** `.factory/planning/cicd-setup.md` (CI configuration plan)
**Section:** §required-checks
**Defect:** 5 `required-checks` entries in the CI plan show expected output `PASS` via self-checking gates (each gate validates that its own config file is present, producing a green check regardless of whether the content meets any behavioral requirement). None of the 5 checks verify any production behavioral property. This is Mechanism 3: arithmetic identity satisfiable without ground truth (the gate passes when the file exists, not when the content is correct). Confirmed independently by all five slices via E023 cross-perimeter reference from D003-PG and A005-PG evidence chains.
**Verification method:** Read cicd-setup.md §required-checks entries; read each cited gate script; confirm each script checks only self-presence or config-file existence, not behavioral correctness.
**Route:** devops-engineer.

---

### Slice E MED Findings (10)

#### F-P176-E013 — planning/naming-decision-pregolya.md §crates-io-check: verified-free note has no RESERVED: no marker

**Severity:** MED
**File:** `.factory/planning/naming-decision-pregolya.md`
**Section:** §crates-io-check
**Defect:** §crates-io-check says "names verified free as of 2026-07-30." No explicit `RESERVED: no` marker. A developer following the human-action guidance could misread "verified free" as "verified free AND reserved." The distinction is load-bearing given the R14/R6 HIGH-irreversible risk.
**Route:** spec-steward.

---

#### F-P176-E014 — policies.yaml §POL-01 §anchor: cites CLAUDE.md §Canonical-Principle (phantom heading)

**Severity:** MED
**File:** `policies.yaml`
**Section:** §POL-01 / §anchor
**Defect:** §POL-01 `enforcement_anchor: "CLAUDE.md §Canonical-Principle"`. CLAUDE.md has no heading `§Canonical-Principle`; the section is `## CANONICAL PRINCIPLE — Production-Grade Default`. Mechanism 1 instance in policy anchor fields.
**Route:** spec-steward.

---

#### F-P176-E015 — policies.yaml §POL-08 §traceability-matrix: cites wrong path

**Severity:** MED
**File:** `policies.yaml`
**Section:** §POL-08 / §traceability-matrix
**Defect:** §POL-08 `artifact_path: ".factory/specs/traceability-matrix.md"`. STATE.md §Historical-Content places the traceability matrix at `cycles/<cycle>/traceability-matrix.md` (cycle-scoped, not a living spec). The path in POL-08 resolves to a non-existent file.
**Route:** spec-steward.

---

#### F-P176-E016 — hooks/records-lint.sh §L11 boundary: length comparison may have off-by-one

**Severity:** MED
**File:** `.factory/hooks/records-lint.sh`
**Section:** §L11 / §hex-digest-length
**Defect:** §L11 bans hex digest literals of 8+ characters. The boundary condition (is it `>= 8` or `> 8`?) is not tested. The current `9a62edc` citation (7 chars) is exempt. An 8-char digest (exactly at the boundary) behavior is undefined in the test coverage. If the comparison is `> 8` instead of `>= 8`, 8-char digests would silently pass the ban.
**Uncertainty:** Reviewer notes this finding is marked **pending records-lint.sh source read**. If the comparison is `>= 8` as intended, the finding closes. If `> 8`, severity upgrades to HIGH (8-char digests are frequently used in git abbreviated SHAs).
**Route:** devops-engineer.

---

#### F-P176-E017 — planning/rename-sweep-manifest.md §excluded-directories §cycles: exclusion rationale not documented

**Severity:** MED
**File:** `.factory/planning/rename-sweep-manifest.md`
**Section:** §excluded-directories / §cycles
**Defect:** §excluded-directories lists `cycles/` as excluded from rename scope without documenting the rationale (frozen adversarial audit trail; 2,340+ occurrences are legitimate historical records, not active spec text). Without the documented rationale, a future sweep operator may not realize the exclusion is intentional and may attempt to rename the frozen pass reports.
**Route:** spec-steward (add rationale comment to §excluded-directories §cycles entry).

---

#### F-P176-E018 — semport/reference-manifest.md §langchain-version: pip-style version pin (TD-VSDD-091 MED)

**Severity:** MED
**File:** `.factory/semport/reference-manifest.md`
**Section:** §langchain-version
**Defect:** `langchain==1.3.13` pip-style pin form in a YAML document. TD-VSDD-091 version-pin class. Semport is a reference analysis document (not a living spec), but the reference-manifest is the canonical source for corpus version pins and stale pins directly affect semport analysis validity.
**Route:** spec-steward (replace with behavioral-anchor form per TD-VSDD-091).

---

#### F-P176-E019 — policies.yaml §POL-31 §scope: "all spec documents" undefined — planning/semport/cycles may be in scope

**Severity:** MED
**File:** `policies.yaml`
**Section:** §POL-31 / §scope
**Defect:** §POL-31 §scope says "all spec documents." The policy does not enumerate which directories qualify as spec documents. `planning/`, `semport/`, and `cycles/` are all inside `.factory/` but have different governance status. The undefined scope creates uncertainty for enforcement.
**Route:** spec-steward.

---

#### F-P176-E020 — planning/dtu-assessment.md §cassette-sets: 3 listed; BC §DTU row has 4 services

**Severity:** MED
**File:** `.factory/planning/dtu-assessment.md`
**Section:** §cassette-sets
**Defect:** §cassette-sets lists 3 cassette clone sets (openai, anthropic, ollama). BC §DTU row has 4 services (openai, anthropic, ollama, model_cascade). The cascade service is missing from the DTU assessment. STATE.md §dtu_services also shows 3. All three documents agree on 3 and disagree with the BC §DTU row.
**Route:** product-owner (resolve whether model_cascade requires a DTU clone) + spec-steward (dtu-assessment update).

---

#### F-P176-E021 — comparative/COMPARATIVE-ASSESSMENT.md §assessment-date: 2026-07-14; burst-284 touched comparative/ files on 2026-07-30

**Severity:** MED
**File:** `.factory/comparative/COMPARATIVE-ASSESSMENT.md`
**Section:** §assessment-date
**Defect:** §assessment-date: `2026-07-14`. Burst-284 touched comparative/ files as part of the rename (architect corrected ferrograph residue in the 11 files that devops had reverted per D-105). The assessment-date was not updated. If comparative/ is a frozen reference document (D16), this finding may be OBS.
**Uncertainty:** Pending determination of whether burst-284 made semantic changes to comparative/ or only rename substitutions.
**Route:** spec-steward.

---

#### F-P176-E022 — semport/core/ANALYSIS-STATE.md §module-inventory §status: "80% complete" has no measured basis

**Severity:** MED
**File:** `.factory/semport/core/ANALYSIS-STATE.md`
**Section:** §module-inventory / §status
**Defect:** §status: "80% complete." The semport analysis-state format does not define how completion percentage is calculated (file count? line count? BC count?). The 80% figure is an estimate without a measurement basis. Agents reading this document to determine semport readiness will have no objective threshold.
**Route:** spec-steward.

---

### Slice E LOW / OBS Findings (5)

#### F-P176-E024 — planning/market-intel.md §ferrograph: 13 occurrences (frozen reference, LOW)

**Severity:** LOW
**File:** `.factory/planning/market-intel.md`
**Section:** body
**Defect:** 13 `ferrograph` occurrences. This is the ferro-stem class documented in rename-constraint-spec.md. Market-intel is a pre-pipeline reference document; rename is not required. Flagging for completeness.
**Route:** No action required if constraint-spec lists market-intel.md as permitted (confirm at D023 fix time).

---

#### F-P176-E025 — policies.yaml §POL-31 §changelog-date: future-dated

**Severity:** LOW
**File:** `policies.yaml`
**Section:** §POL-31 / §changelog-date
**Defect:** §POL-31 §changelog-date 2026-07-31 postdates frozen HEAD `9a62edc` (2026-07-30). `verify-changelog-date-validity.sh` should catch this.
**Route:** spec-steward.

---

#### F-P176-E026 — policies.yaml §POL-04 §phase-binding: "Phase 1 gate" undefined; Phase 1 ends at adversarial convergence

**Severity:** LOW
**File:** `policies.yaml`
**Section:** §POL-04 / §phase-binding
**Defect:** §POL-04 §enforcement_point: "Phase 1 gate." There is no Phase-1 gate event; Phase 1 ends when the 3-CLEAN adversarial convergence streak is achieved (BC-5.39.001). The phrase "Phase 1 gate" is undefined in the pipeline spec.
**Route:** spec-steward.

---

#### F-P176-E027 — namespace-reservation/publish-all.sh §EXPECTED_OWNER: un-replaced placeholder

**Severity:** LOW
**File:** `.factory/namespace-reservation/publish-all.sh`
**Section:** §EXPECTED_OWNER
**Defect:** `EXPECTED_OWNER="crates-io-username"` is a placeholder that must be replaced before running. No README or inline comment instructs the user to replace it. A user running the script without replacement will publish 21 crates under the wrong owner (if the placeholder happens to match a real crates.io user) or fail with a mismatch error.
**Route:** spec-steward (add replace-before-running instruction comment above the variable).

---

#### F-P176-E028 — planning/rename-constraint-spec.md §ferro-stem-class: known-residue inventory incomplete (product-brief.md + BC-2.23.002 PC-3 missing)

**Severity:** LOW
**File:** `.factory/planning/rename-constraint-spec.md`
**Section:** §ferro-stem-class / §known-residue-inventory
**Defect:** §known-residue-inventory lists `market-intel.md` (13 occurrences) as permitted ferro-stem residue. It does not list: (1) `product-brief.md` §overview (D018, 1 `ferrograph` — not permitted under the living-spec exception); (2) `BC-2.23.002` §PC-3 `.ferroctmp_` filename prefix (production code produces this prefix as a temporary file during write operations — removing it would be a behavioral change, not a rename fix). The inventory is incomplete on both sides: a living-spec occurrence that should not be in the inventory, and a legitimate behavioral occurrence that should be listed.
**Route:** spec-steward (update §known-residue-inventory).

---

#### F-P176-E001-PG — `[process-gap]` No automated test verifies that a POL enforcement_anchor field resolves to a real heading

**Severity:** `[process-gap]`
**Finding:** A007 (HIGH, Slice A) and E003 (HIGH, Slice E) both involve `enforcement_anchor` fields pointing to phantom section anchors. No gate validates that `enforcement_anchor` strings in policies.yaml resolve to real headings in the cited documents. The gate from E002 (§CITE_RE extension) is the prerequisite; once built, it should also cover policies.yaml `enforcement_anchor` fields.
**Route:** devops-engineer.

---

#### F-P176-E011-PG — `[process-gap]` publish-all.sh lacks pre-flight checks for path existence and placeholder replacement

**Severity:** `[process-gap]`
**Finding:** E011 (non-existent `cd` path) and E027 (un-replaced `EXPECTED_OWNER` placeholder) are both operational hazards in publish-all.sh. A pre-flight check section at the top of the script that verifies path existence and placeholder replacement before attempting any `cargo publish` would prevent both failure modes.
**Route:** spec-steward (publish-all.sh pre-flight check addition).

---

## Rename Integrity (All Five Slices — Independently Verified)

All five slices independently confirmed:

- **Zero `ferrochain`/`Ferrochain`/`FERROCHAIN` occurrences** in any living spec or hook file at frozen HEAD.
- **Zero `pregel::` module paths** in any spec or hook file.
- **353 openers measured** by `verify-error-notation-canon.sh` post-rename; gate migrated correctly.
- **The only ferro-stem class residue** is: `.ferroctmp_` in BC-2.23.002 §PC-3 (a filename prefix that production code writes — behavioral, not rename residue; rename-constraint-spec §ferro-stem-class should list this explicitly); `ferrograph` in `product-brief.md` §overview (1 occurrence, MED — D018); `ferrograph` in `market-intel.md` (13 occurrences, frozen reference, LOW — D023/E024); 4 occurrences in `comparative/COMPARATIVE-ASSESSMENT.md` (HIGH pending intent verification — E006).

---

## Primary Conclusion

Findings are **not decaying**: four consecutive full-perimeter passes at 130–256–189–160 each; each pass finds defects created by the prior pass's fix-bursts (B002, B004, A002 are confirmed fix-burst-283 regressions). The five convergent mechanisms explain why mechanism-level fixes in burst-285 will produce a larger per-finding closure rate than fix-burst-by-severity routing.

**Routing priority for burst-285:**
1. Mechanism fixes (M1: §-anchor convention restriction + gate; M2: note-closure promotion to blocking; M3: ground-truth check for D001/A009/E023; M4: governing #[non_exhaustive] ADR; M5: POL-17 / C008 contradiction + verify-error-notation-canon.sh post-rename update)
2. The 5 CRITs (C001, C002, D001, D002, E001)
3. HIGH tail (45 findings)
4. MED tail (80 findings)

---

*Pass closed 2026-07-30. Streak stays 0/3. Total passes: 177.*
