---
artifact: planning/rename-sweep-manifest
document_type: planning
stage: rename-stage-1b
created: 2026-07-30T00:00:00Z
author: spec-steward
purpose: >
  Authoritative, mechanically-derived rename sweep manifest for burst 284.
  Per-file classification (RENAME / PRESERVE / MIXED) plus structural surface
  inventory and execution order for the project rename.
  The new name is not yet chosen — do NOT execute any renames until the human
  confirms a name following Stage 2 availability verification.
predecessor: .factory/planning/rename-constraint-spec.md
input-hash: "pending"
---

# Rename Sweep Manifest — Burst 284

**Governance note.** This manifest was derived by mechanical enumeration, not
by recollection of the directory tree. That method is mandatory: L-138 was
minted after D-87 defect 4 to prescribe sibling cross-checking, but a
recollection-based scope list still omitted four live areas in the predecessor
document. This manifest closes that gap.

**Status:** DO NOT EXECUTE. Stage 2 availability sweep is running concurrently.
No rename action until the human approves a name.

---

## Changelog

### 2026-07-30 — Initial manifest (burst 284)
- Created by spec-steward via mechanical enumeration
- Classification covers all 598 ferrochain-matching files outside exclusion zones
- Non-obvious structural surfaces documented (gate-disabling risk, branch protection)
- Burst-284 execution order established

---

## 1. Enumeration Command and Summary

### Reproducible command

```bash
cd /path/to/repo && find . -type f \
  -not -path "./.git/*" \
  -not -path "./.reference/*" \
  -not -path "./.factory/logs/*" \
  -not -path "./.factory/.git/*" \
  | sort | xargs grep -il "ferrochain" 2>/dev/null
```

Three exclusion zones: `.git/` (version control internals), `.reference/`
(pinned read-only corpora, per project constitution), `.factory/logs/` (daemon
log files). `.factory/.git` is excluded because it is the separate
factory-artifacts worktree git internals — not an editable text artifact.

### Totals

| Metric | Count |
|--------|-------|
| Files containing "ferrochain" (case-insensitive) | 598 |
| Total occurrences across all files | 6,397 |

### Per-directory breakdown

| Directory | Files | Occurrences | Classification |
|-----------|-------|-------------|----------------|
| `.factory/specs/` | 197 | 3,716 | RENAME |
| `.factory/cycles/` | 117 | 987 | PRESERVE |
| `.factory/namespace-reservation/` | 185 | 481 | RENAME (source 45) / DELETE-REBUILD (target ~140) |
| `.factory/semport/` | 45 | 326 | RENAME |
| `.factory/hooks/` | 20 | 130 | RENAME |
| `.factory/comparative/` | 13 | 421 | MIXED |
| `.factory/planning/` | 14 | 289 | MIXED (see §2) |
| `.factory/STATE.md` | 1 | 8 | MIXED |
| `.factory/policies.yaml` | 1 | 6 | RENAME |
| `CLAUDE.md` | 1 | 16 | RENAME |
| `.factory/preflight-report.md` | 1 | 2 | PRESERVE |
| `.factory/proposals/template-divergence-register.md` | 1 | 1 | RENAME |
| `.github/workflows/ci.yml` | 1 | 1 | RENAME |
| **Total** | **598** | **6,397** | — |

---

## 2. Per-File Classification

### Classification buckets

- **RENAME** — live artifact; all ferrochain occurrences are forward-looking
  project or crate identity text that must change to the new name.
- **PRESERVE** — historical/audit record; changing it would retroactively
  falsify what was true when written. No edits permitted.
- **MIXED** — file contains both live text and historical text. For each,
  the frozen regions are specified precisely.

### Summary counts (source files; excludes compiled artifacts)

| Bucket | File count |
|--------|-----------|
| RENAME | 458 |
| PRESERVE | 125 |
| MIXED | 15 |
| DELETE-REBUILD (target/ compiled artifacts) | ~140 |
| **Total** | **~738** |

The DELETE-REBUILD count covers compiled Rust artifacts under
`.factory/namespace-reservation/*/target/` that contain the crate name in
binary file paths and metadata. These are not text-edited — the directories
are deleted and rebuilt after the rename.

---

### 2a. PRESERVE files — full list with reasoning

**`.factory/cycles/` — 117 files (ENTIRE DIRECTORY)**

Authority: D-79, D-84. Adversary pass reports (ADV-P1D-PASS-*, pass-*.md),
burst logs, convergence trajectory, session checkpoints, lessons, and
validation archives. Each recorded findings, decisions, and metrics at a
specific time. A crate name cited in a finding was accurate when it was
written; altering it retroactively falsifies the evidentiary chain.

Files include: all adversarial review pass files, burst-log, burst-278-sweep-manifest,
blocking-issues-resolved, session-checkpoints, lessons, convergence-trajectory,
spec-gate-consistency-audit, validation-report-archive across both
`v0.0.0-pre-pipeline/` and `v1.0.0-greenfield/` cycle directories.

**`.factory/planning/naming-decision-study.md`**

The D6 rationale record. It accurately records why `ferrochain` was chosen at
scoring time (23/25 vs 14/25). The rename supersedes D6 but does not falsify
it — the criterion that `ferrochain` was the best available name in 2026-07-12
context remains true. Altering this document would erase the audit trail for
the naming decision.

**`.factory/planning/repo-initialization-log.md`**

Historical log of the workspace initialization event (GitHub rename from
`langchain-rs` to `ferrochain`, crates.io name availability checks at that
time, git remote URL configuration). All occurrences of `ferrochain` document
the state at initialization. Changing them falsifies when these steps happened
and under what name.

**`.factory/planning/rename-constraint-spec.md`**

Special case. This document explicitly describes the rename exercise. Its
references to `ferrochain` are intentional: Part A documents why the name was
chosen; Part D §What Must NOT Change enumerates the hard exclusions.
Altering these references would make the document internally contradictory.
The document remains valid history even after the rename.

**`.factory/planning/decisions-archive-pre-p1d.md`**

Archive of D1–D17 decision rows extracted from STATE.md for size management.
These decision rows record what was decided at specific times, including D6
which ratified the name `ferrochain`. Same protection as STATE.md historical
decision rows. The archive exists precisely so these records survive STATE.md
compaction — modifying them destroys the archive's purpose.

**`.factory/preflight-report.md`**

Snapshot of the development environment at Phase 1 start. Its two occurrences
of `ferrochain` are filesystem path references (the project directory path
`/Users/jmagady/Dev/ferrochain/...`) — not project identity text. These
paths document the machine environment at that point in time; they are not
crate names, package identifiers, or forward-looking references.

---

### 2b. MIXED files — with precise frozen/live regions

**`.factory/STATE.md`**

- **Live (RENAME):** Frontmatter field `project: ferrochain`; the `| **Product** |`
  row in the Pipeline State summary table; the `| **Repository** |` row;
  `user_directive_persistent` prose where the project is named; the
  `convergence_status` narrative; the `current_step` narrative.
- **Frozen (PRESERVE):** All decision rows D1 through D-90 (and any added
  between now and the rename burst). Decision rows are append-only; D6 and
  related rows correctly record what was decided at those times. The risk
  register rows R1–R14 that cite crate names in context of those specific
  decisions are also frozen — they record risks assessed against the
  then-current name. New forward-looking content added post-rename uses
  the new name.
- **Mechanism:** Add a new decision row D-NN recording the rename decision
  with the new name. Do NOT edit existing rows.

**`.factory/planning/cicd-setup.md`**

- **Live (RENAME):** Document title (`ferrochain CI/CD Setup`), `project:
  ferrochain` frontmatter, the CI pipeline description, the GitHub repo
  identifier `BOHICA-LABS/ferrochain`, the crate family references in the
  setup steps.
- **Frozen (PRESERVE):** The embedded decision rows (D1, D6, D7, D9 etc.)
  in the decisions-traced section. These are historical records of what was
  decided; they carry the same D-79/D-84 protection as STATE.md decision rows.
- **Mechanism:** Update prose and frontmatter; leave the D-decision rows intact.

**`.factory/comparative/COMPARATIVE-ASSESSMENT.md` (and all 12 files in `.factory/comparative/`)**

The D16 comparative assessment is an architectural input document that
continues to guide Phase 1 spec crystallization. It is NOT an adversary pass
report and does not carry D-79/D-84 protection for its project-name references.

- **Live (RENAME):** The project name in forward-looking architectural
  recommendations (e.g., crate names cited in resolution columns, error type
  `FerrochainError` in architecture prescriptions, gate question answers that
  name specific crates like `ferrochain-anthropic-sdk`).
- **Frozen (PRESERVE):** The historical assessment conclusions — conflict
  verdicts, pattern dispositions (ADOPT/ADAPT/REJECT), certification pass
  records, and quality tags. These were produced at a specific time against
  a specific corpus state; altering the analytical findings would falsify the
  evidence trail even if the project name changes.
- **Mechanism for all 13 comparative files:** Update contextual project-name
  usage and forward-looking crate references; leave disposition tables,
  conflict verdicts, and certification pass records intact.

Specific high-traffic rename sites within the comparative files:
- `COMPARATIVE-ASSESSMENT.md`: gate question answer at `ferrochain-anthropic-sdk`
  recommendation; `FerrochainError` prescription in conflict-6 resolution;
  contextual project name in outcome scoring.
- `adk-rust/CERTIFICATION-REPORT.md`: contextual project name in `ferrochain
  should replicate`, `ferrochain's rustls-only rule`; no crate identifiers.
- `assessment-parts/part-*`: contextual project-name usage in framing prose only.
- `adk-rust/behavioral-intent.md`, `dependency-disposition.md`,
  `module-inventory.md`, `patterns-observed.md`, `rust-translation-strategy.md`,
  `test-inventory.md`, `ANALYSIS-STATE.md`, `SWEEP-patterns.md`,
  `SWEEP-test-deps.md`: contextual project-name usage in framing prose only.

---

### 2c. RENAME files — by area (not exhaustive list; use enumeration command)

**`.factory/specs/` — 197 files (ALL RENAME)**
Every live spec artifact: PRD, product brief, all 168 behavioral contract files,
all 21 ADRs, all architecture section files (ARCH-INDEX, system-overview,
api-surface, module-decomposition, dependency-graph, purity-boundary-map,
tooling-selection, verification-architecture, verification-coverage-matrix,
all 13 VPs), all 15 domain spec shards, all 8 PRD supplements, module-criticality.

**`.factory/semport/` — 45 files (ALL RENAME)**
Per-package analysis files for all 7 semport packages (core, graph, langchain,
mcp, partners, platform, splitters): behavioral-intent, dependency-disposition,
EXHAUSTIVE-SWEEP, module-inventory, rust-translation-strategy, test-inventory,
reference-manifest, VALIDATION-REPORT, ANALYSIS-STATE. These describe
output crate names in their rust-translation-strategy sections; the crate
names in those sections are forward-looking and change.

**`.factory/hooks/` — 20 files (ALL RENAME, with gate-critical items; see §3)**
Script headers, comments, and allowlist headers are cosmetic RENAME. Three
files also contain functional patterns (not just comments) that constitute
gate-disabling risks if left stale. See §3 for details.

**`.factory/namespace-reservation/` — 45 source files (RENAME) + ~140 target/ files (DELETE-REBUILD)**
Source: 22 crate `Cargo.toml` files, 22 `src/lib.rs` files, `publish-all.sh`.
Target/ compiled artifacts: delete and rebuild after rename; not text-editable.
Plus: `ferrochain-prebuilt/` directory — DELETE ENTIRELY (not in canonical
roster; inert orphan per rename-constraint-spec.md §Special Cases).

**`CLAUDE.md` (project root) — 1 file (RENAME)**
16 occurrences: toolchain section crate family reference, pipeline phase
descriptions, code conventions section crate examples, standing adversary probe
references to specific crate names.

**`.github/workflows/ci.yml` — 1 file (RENAME)**
1 occurrence: comment header `# ferrochain CI pipeline`. No job names or
required-status-check names contain `ferrochain` — see §3 for the branch
protection analysis.

**`.factory/policies.yaml` — 1 file (RENAME)**
1 occurrence: policy-33 description field cites `ferrochain-openai, ferrochain-anthropic,
ferrochain-ollama` as the DTU clone crate names. Live policy content; must
match the new crate names.

**`.factory/proposals/template-divergence-register.md` — 1 file (RENAME)**
1 occurrence: template prose references the project generically as `ferrochain
spec artifact`. Live template; created this burst.

---

## 3. Non-Obvious Structural Surfaces

### 3a. `.factory/hooks/` — gate-disabling risk

Three files contain functional patterns that the gate executes as search tokens,
not merely documentation. A stale search token silently disables a gate check —
this is the D-57 failure mode.

**`verify-signature-canon.sh` — BLOCKING**

The embedded Python contains a hardcoded search token:
```
SEARCH_TOKENS = ['Arc<dyn Tool>', 'dyn ferrochain_core::Tool']
```
This token causes the gate to scan spec files for the prohibited pattern
`dyn ferrochain_core::Tool`. After the rename, the prohibited pattern becomes
`dyn <newname>_core::Tool`. If the token is not updated, the gate will stop
detecting the anti-pattern in spec files, silently disabling rule S4 (D-43).

**`spec_region_utils.py` — BLOCKING (shared module)**

Contains:
```
_FERROCHAIN_SINGLE_LINE_RE = re.compile(r'\bFerrochainError\s+\{')
_FERROCHAIN_SPLIT_END_RE   = re.compile(r'\bFerrochainError\s*$')
def find_ferrochain_error_openers(raw_lines):
```
These regex patterns are used by `verify-error-notation-canon.sh` to detect
`FerrochainError { ... }` openers in spec files and classify them per ADR-010.
After the rename, the error type will presumably become `<NewName>Error`. If
these patterns are not updated, `verify-error-notation-canon.sh` will report
0 openers on a non-empty corpus — silently disabling the notation gate.

**`verify-error-notation-canon.sh` — BLOCKING**

Imports `find_ferrochain_error_openers` and also contains:
```
DECL_RE = re.compile(r'\b(?:pub\s+struct|impl)\s+FerrochainError\b')
```
plus inline test fixture references to `FerrochainError { ... }` in self-test
examples. The structural patterns (not the test fixtures) are gate-functional
and must match the new error type name.

**Remaining 17 hook files — cosmetic only**

All other ferrochain occurrences in `.factory/hooks/` are in script header
comments (`# script.sh — ferrochain factory-artifacts ...`) and do not affect
gate behavior. Update for cleanliness but no gate risk.

**`verify-module-canonicality.sh` — safe (dynamic, not hardcoded)**

The comment `ferrochain-XXX` is documentation only. The script dynamically reads
its canonical crate list from `ARCH-INDEX.md` at runtime via regex extraction.
It will work correctly after the rename as long as ARCH-INDEX.md is updated first.
No hardcoded crate names in the functional code path.

**`verify-arch-anchor-resolution.sh` — comment-only, but note expected failures**

The expected-failures list cites `architecture/ferrochain-core.md` etc. as
placeholder paths that do not yet exist. These are in a comment block
documenting known expected failures. After the rename, these placeholder
citations change. The script itself is functional in the comments; update them.

**`version-pin-allowlist.txt` — comment-only**

The comment references `ferrochain-guardrail crate references with the canonical
ferrochain-core`. Header and comment text only; no functional patterns.

**`signature-canon-allowlist.txt` — comment-only**

Header comment: `# signature-canon-allowlist.txt — ferrochain factory-artifacts`.
No functional entries; the allowlist is currently empty.

---

### 3b. `.factory/namespace-reservation/` — directory names and publish-all.sh

The 22 crate subdirectories are themselves named `ferrochain-{suffix}/`. A
content sweep that updates file contents but leaves directory names unchanged
is incomplete — Cargo requires the directory name to match the package name.

Required actions (beyond file-content edits):
- Rename 21 crate directories from `ferrochain-{suffix}/` to
  `<newname>-{suffix}/` (22nd directory `ferrochain-prebuilt/` is deleted, not renamed).
- Update `publish-all.sh` CRATES array (21 entries) to new names.
- Update `publish-all.sh` comment block (crate family list).
- Delete all `*/target/` subdirectories (Rust build artifacts keyed on old crate
  name); rebuild after rename using `cargo build` per crate or workspace.

**`publish-all.sh` `EXPECTED_OWNER` field** is `BOHICA-LABS` (the GitHub org / crates.io
owner identity) — this does NOT change with the project name. Only the crate
names in the `CRATES` array change.

**crates.io reservation timing hazard.** crates.io is first-come-first-served.
The moment a new name is confirmed, devops-engineer must run `publish-all.sh`
immediately to claim all 21 new crate names before any public announcement.
The current `ferrochain-*` reservations (12 already owned per STATE.md R14)
retain their existing crates.io ownership — those 12 names cannot be reclaimed
once registered, so a clean-slate rename requires the new names.

---

### 3c. `.github/workflows/ci.yml` — branch protection analysis

The CI workflow defines these job names:
- `CI / fmt`
- `CI / clippy`
- `CI / test`
- `CI / build`
- `CI / file-size-gate`

None of these job names contain `ferrochain`. GitHub branch protection required
checks are keyed on these job name strings. Renaming the single comment header
(`# ferrochain CI pipeline`) does NOT affect branch protection — no merge
blockage risk from this file.

However: if GitHub branch protection rules for `develop` or `main` cite the
workflow file by name and the repository is also renamed (from
`BOHICA-LABS/ferrochain` to `BOHICA-LABS/<newname>`), the branch protection
rules must be re-verified after the repository rename. Repository renames
preserve branch protection rules in GitHub, but any third-party integrations
(webhooks, CI badges, clone URLs) must be updated.

---

### 3d. Git and remote URL surfaces

- **GitHub repository:** `BOHICA-LABS/ferrochain` — rename is a devops-engineer
  task using `gh repo rename <newname> -R BOHICA-LABS/ferrochain`. All git
  remote URLs in local clones and worktrees update automatically if push/fetch
  follows the redirect; explicit `git remote set-url` is cleaner.
- **Factory-artifacts branch:** branch name is `factory-artifacts` — no rename needed.
- **Feature/develop/main branches:** names do not contain the project name — no change.
- **`repo-initialization-log.md`** documents the PREVIOUS rename (langchain-rs →
  ferrochain) and is a PRESERVE artifact; it correctly records historical URLs.

---

### 3e. `input-hash` field drift

Artifact classes that carry `input-hash` frontmatter fields:

- `.factory/specs/` files (prd.md, product-brief, module-criticality,
  all VP files, all architecture files, all BC files, all domain-spec files,
  all prd-supplement files)
- `.factory/planning/` live files (adr-tech-validation, dtu-assessment,
  market-intel, holdout-domain files, rename-constraint-spec)
- `.factory/policies.yaml`

A rename changes file content; therefore the SHA-256 hash of every renamed
input file changes. Any artifact whose `input-hash` was computed over a
ferrochain-named input will have a stale hash after the rename.

**Scope:** ALL `input-hash` fields in the RENAME bucket that point to spec files
as their inputs. This is the majority of spec files.

**Required action:** After the content sweep, spec-steward must re-pin all
`input-hash` fields in `.factory/specs/` artifacts (the check-input-drift skill
automates this). The re-pin is a single pass after the full content sweep
completes — do not do it piecemeal.

**`input-hash: "pending"` fields** (rename-constraint-spec.md and similar) are
already unhashed; no re-pin needed for those.

---

### 3f. `FerrochainError` type name propagation

`FerrochainError` is the project's canonical structured error type, defined in
`error-taxonomy.md` and referenced across 351 spec-file opener sites
(post-burst-282 baseline). The gate `verify-error-notation-canon.sh` counts
these. After the rename:

1. The type name changes in `error-taxonomy.md` (RENAME bucket).
2. All 350+ opener sites in behavioral contracts and spec files change to the
   new error type name.
3. The gate patterns in `spec_region_utils.py` change to match.

The 351-opener baseline becomes 0 until step 2 completes. The gate will show
0 openers (PASS with empty corpus) during the transition window. This is
expected — the gate's behavior when `FerrochainError` is absent is to silently
pass. Devops-engineer should verify gate behavior on the new type name before
declaring the sweep complete.

---

## 4. Burst-284 Execution Order and Hazard Map

The rename has six dependency classes. Executing them out of order creates either
gate blindness (gates check for old names and pass vacuously) or gate blockage
(gates run on stale content and fire false positives).

### Step 1 — Hook allowlist / search-token updates (before content sweep)

**What:** Update functional patterns in `verify-signature-canon.sh`,
`spec_region_utils.py`, and `verify-error-notation-canon.sh` to use the new
name. Do NOT update the cosmetic header comments in the same step.

**Why first:** These gates run on `.factory/specs/` content. If the content
sweep runs first (renaming `FerrochainError` → `<NewName>Error` in 351 spec
files), the old gate patterns will produce 0 matches and vacuously PASS —
silently disabling the gates. Updating the patterns first means the gates check
for the new name immediately, providing coverage during and after the sweep.

**Hazard avoided:** D-57 silent-gate-disable pattern.

### Step 2 — `.factory/specs/` content sweep (the largest batch)

**What:** Update all 197 spec files — crate names, `FerrochainError` → new
error type name, project name in prose, ARCH-INDEX canonical crate roster,
ADRs, BCs, VPs, domain spec, PRD, prd-supplements.

**Why here:** After gate patterns are updated (Step 1), the spec sweep can
run fully and the gates will check the new content correctly.

**Note:** `verify-module-canonicality.sh` reads ARCH-INDEX dynamically. Update
ARCH-INDEX before other spec files so the canonical crate list is correct for
any mid-sweep gate runs.

### Step 3 — `input-hash` re-pin

**What:** Re-pin all `input-hash` fields across `.factory/specs/` and other
RENAME-bucket artifacts that carried hash-verified inputs.

**Why here:** After the content sweep completes, file hashes are stable. Re-pin
in one pass rather than per-file to avoid repeated hash-drift alarms.

### Step 4 — Supporting artifacts (semport, hooks headers, planning RENAME files, CLAUDE.md, policies.yaml, CI workflow, proposals)

**What:** Update `.factory/semport/`, the cosmetic hook headers, `.factory/planning/`
RENAME files (adr-tech-validation, dtu-assessment, file-size-standard-study,
market-intel, holdout-domains files), `.factory/planning/cicd-setup.md` live
regions, `CLAUDE.md`, `.factory/policies.yaml`, `.factory/proposals/template-divergence-register.md`,
`.github/workflows/ci.yml`.

**Why here:** These do not affect gate behavior; order relative to Steps 2–3
is flexible but must happen before Step 6.

### Step 5 — `.factory/namespace-reservation/` directory rename and source file update

**What:**
1. Delete `ferrochain-prebuilt/` directory entirely.
2. Delete all `*/target/` subdirectories (compiled artifacts keyed on old names).
3. Rename each remaining 21 crate directory from `ferrochain-{suffix}/` to
   `<newname>-{suffix}/`.
4. Update `Cargo.toml` `[package] name` in each renamed directory.
5. Update `src/lib.rs` `//!` doc comment in each renamed directory.
6. Update `publish-all.sh` CRATES array and comments.

**Why here:** The directory renames are filesystem operations that must complete
before any `cargo build` or `cargo publish` attempt. Keeping this as a discrete
step avoids partially-renamed directories being presented to cargo.

**Hazard:** Do not run `cargo build` in the namespace-reservation directory
until all 21 directories are renamed and all `Cargo.toml` files updated. A
partial state leaves mismatched directory name vs. package name, which cargo
will reject.

### Step 6 — STATE.md update (state-manager)

**What:** Update STATE.md live fields (frontmatter `project:`, Pipeline State
`Product` and `Repository` rows, convergence narrative). Add a new decision
row D-NN recording the rename with the new name. Leave all historical D-rows
and risk register rows intact.

**Why last:** STATE.md is state-manager's domain; it should receive a single
burst commit (TD-VSDD-053) after all other changes are staged. Updating it
before other files risks committing an inconsistent mid-sweep state.

### Parallel vs sequential

Steps 1 and 5 must be sequential relative to each other's prerequisites:
- Step 1 must complete before Step 2.
- Step 2 must complete before Step 3.
- Steps 4 and 5 may run concurrently with each other after Step 1 completes.
- Step 6 must be the final commit in the burst.

Within Step 2, ARCH-INDEX must be updated before the bulk of other spec files.

### GitHub-specific ordering

Repository rename (`gh repo rename`) and remote URL updates must happen AFTER
Steps 1–6 (all local content changes) and are a devops-engineer task separate
from burst 284. Performing the GitHub rename before updating remote URLs in
all worktrees (including `.factory/` worktree) will break the `git push` at
state-manager commit time.

---

## 5. Artifact Path Choice

This manifest is written to `.factory/planning/rename-sweep-manifest.md`.

**Reason:** The artifact-path-registry.yaml does not define explicit path entries
for `.factory/planning/` or `.factory/proposals/`. Given that choice, the
predecessor document `rename-constraint-spec.md` already lives in
`.factory/planning/`, and this manifest extends that work as the same stage
of the rename exercise. Placing both planning artifacts in the same directory
creates a discoverable pair: constraint spec → sweep manifest. The
`.factory/proposals/` directory's existing content (`template-divergence-register.md`)
suggests it is for governance templates, not operational planning artifacts.

---

## 6. Files Omitted by Predecessor Constraint Spec

The `rename-constraint-spec.md` §Part D enumerated scope from recollection and
omitted these live areas:

| Area omitted | Files | Why it matters |
|-------------|-------|----------------|
| `.factory/planning/` root files (non-holdout) | 9 files | Contain live crate names in planning artifacts |
| `.factory/planning/holdout-domains/` | 5 files | Live briefs feeding Phase 2; not yet sealed |
| `.factory/comparative/` | 13 files | Forward-looking crate recommendations in D16 architectural input |
| `.factory/preflight-report.md` | 1 file | Appears in grep; PRESERVE — only filesystem path occurrences |
| `.factory/policies.yaml` | 1 file | Live policy description field cites 3 specific crate names |
| `.factory/STATE.md` | 1 file | Live front-matter and summary table fields |
| `.factory/proposals/template-divergence-register.md` | 1 file | Live template created this burst |

This recurrence of L-138 is the proximate cause for mechanical enumeration
rather than recollection-based scope. The lesson is: scope must be derived by
`find + grep`; no recollection of "where things live" is sufficient at this
project size.
