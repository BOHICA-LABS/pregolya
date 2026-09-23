# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- **No-panic CI enforcement** (`cargo xtask check-no-panic`): AST-based scan of all `crates/` production source files that flags `unwrap()`, `expect()`, bare `assert!` / `assert_eq!` / `assert_ne!` / `assert_matches!` without `# Panics` doc and BC-ID message, `todo!` / `unimplemented!` (unconditionally flagged — no exemption applies; mark incomplete work), `panic!`, named-arm `unreachable!` where the match has an unguarded catch-all sibling, and wildcard `_ => unreachable!()` arms; exempts `debug_assert!`, exhaustive-match `unreachable!` in fully-named arms, and programmer-error guards with compliant doc+message pattern (BC-2.14.003).
- **HTTP client timeout CI enforcement** (`cargo xtask check-client-timeout`): source scan that flags `reqwest::ClientBuilder` chains missing `.timeout(duration > 0)` before `.build()` and any bare `reqwest::Client::new()` in non-test production code (BC-2.14.004), including `Client::default()` / `ClientBuilder::default()` constructions, UFCS `<reqwest::Client as Default>::default()` forms, `reqwest::blocking::*` surfaces, and macro-body constructions via recursive syn AST parsing.
- **Credential structural safety CI gate** (`cargo xtask deny-bare-api-key`): structural scanner that flags public structs with credential-sentinel names (`key`, `token`, `secret`, `credential`, `auth`, `bearer`, `password`, `passphrase`) that auto-derive `Debug` (without a manual redacted impl), derive `Serialize`, derive `Deserialize` (bypasses `new()` validation), implement `Display`, or implement `Deref<Target=str/String>` (BC-2.14.005).
- **Error-code registry CI enforcement** (`cargo xtask check-error-code-registry`): parses `.factory/specs/prd-supplements/error-taxonomy.md` and fails the build if any `E-<COMPONENT>-<NNN>` code appears more than once; exits 1 with a descriptive error if zero codes are extracted (vacuity guard — detects taxonomy format changes); taxonomy path resolved via `FACTORY_DIR` env var (set by CI factory-artifacts checkout step) or `.factory/` relative fallback when `FACTORY_DIR` is absent or empty (BC-2.14.001, VP-BC214001-01).
- **`OpenAiApiKey` and `AnthropicApiKey` credential newtypes** in `pregolya-core`: private-field newtypes with manually-implemented redacted `Debug` (emits exactly `"<redacted>"`); fallible construction via `new() -> Result<Self, PregolyaError>`; infallible `From<String>`/`From<&str>` conversions are structurally forbidden and pinned by `static_assertions::assert_not_impl_any!` (BC-2.14.006 EC-005); no `Serialize`, `Deserialize`, `Display`, `Deref`, or `AsRef<str>`; compile-time `static_assertions` enforce all exclusions (BC-2.14.005, BC-2.14.006).
- **`build_client()` HTTP client factory** in `pregolya-core`: `reqwest::ClientBuilder` wrapper enforcing 30-second total timeout with `rustls-tls` backend; maps `ClientBuilder::build()` failure to `PregolyaError { category: TRANSPORT, code: "E-CORE-012", retry_hint: Never }` (BC-2.14.004).
- **Validation error propagation** (`E-CORE-005`): `OpenAiApiKey::new("")` and `::new("   ")` return `Err(PregolyaError { category: VAL, code: "E-CORE-005", message: "Validation failed for 'api_key': value must not be empty or whitespace-only", retry_hint: Never })`; no silent `None` or default returns (BC-2.14.006).

## fix-burst-51 (pass-49 findings)

**Pass-49 finding tally: 1 HIGH + 6 MED + 3 LOW + 3 OBS**

### HIGH-001: Three-way inventory contradiction for pass-48

**What was wrong:** STATE.md D-420, CHANGELOG fix-burst-50, and evidence-report fix-burst-50 each reported a different pass-48 finding count: 6, 10, and 14 respectively. Per-finding ID content also diverged (MED-002 and LOW-004 mapped to different findings in CHANGELOG vs evidence-report). The `check-burst-records-parity` hook could not detect this because it checks section presence, not content parity.

**What was fixed:** Adjudicated authoritative inventory: 1 HIGH + 4 MED + 5 LOW + 3 OBS + 1 PROCESS-GAP = 14 findings. state-manager corrected STATE.md D-420 tally and D-421 closure enumeration to all 14 findings. CHANGELOG fix-burst-50 and evidence-report fix-burst-50 reconciled to the same adjudicated inventory (MED-002 content corrected, LOW-004 content corrected, OBS/PROCESS-GAP sections added to CHANGELOG, phantom symbol removed from HIGH-001 description).

### MED-001: evidence-report OBS rows cited phantom function and mis-attributed exclusion

**What was wrong:** evidence-report fix-burst-50 OBS-001 Detection-class cited `check_l8` (function does not exist in records-lint.sh — the MAX_D extraction lives in `check_l13`). OBS-002 Load-bearing-artifact stated the `:!hooks/**` exclusion prevented triggering "the L9 volatile-pin ban" — the change was to `check_l10`/`check_l11`; `check_l9` already had the exclusion.

**What was fixed:** OBS-001 Detection-class → `check_l13`; OBS-002 Load-bearing-artifact → "L10/L11 hash-digest bans (`check_l9` already carried the exclusion)".

### MED-002: CHANGELOG and evidence-report used different phantom symbols for HIGH-001

**What was wrong:** CHANGELOG fix-burst-50 HIGH-001 heading cited `_L13G_OUT` as the phantom symbol; evidence-report cited `_check_l13_impl`. Adversary verified neither symbol appeared in STATE.md D-419 before or after fix-burst-50.

**What was fixed:** Both records rewritten to describe the actual D-419 defect: D-419 used language stating "self-contained swap-and-restore" when fix-burst-49 ELIMINATED swap-and-restore. No phantom symbol cited. Behavioral anchor: `check_l13 parameterized with optional path arg; swap-and-restore ELIMINATED; _L13_CHECK mirror RETIRED`.

### MED-003: CHANGELOG HIGH-001 "What was fixed" inverted the guard mechanism

**What was wrong:** CHANGELOG fix-burst-50 HIGH-001 body described an unapplied D-419 edit, stated the guard "exits 2 when no FAIL text is present" (inverted — `grep -q "[PASS]"` succeeds when PASS is present, so exits 2 when PASS is found), and referenced the pre-LOW-003 guard as if current.

**What was fixed:** Rewritten to describe the actual D-419 correction. `grep -q "does not match live"` is the primary guard. `[PASS]` absence is the secondary guard. Both introduced in fix-burst-49/50.

### MED-004: evidence-report test count was stale fix-burst-26 figure

**What was wrong:** `300 tests pass (cargo nextest), 7 skipped` was the fix-burst-26 figure from §Recording Provenance. fix-burst-49 workspace total was 345 tests, 7 skipped.

**What was fixed:** Corrected to "345 tests pass (cargo nextest), 7 skipped (workspace) — unchanged from fix-burst-49; no Rust logic changed".

### MED-005: evidence-report fix-burst-50 missing validity-criterion clause (a) attestation

**What was wrong:** fix-burst-50 renamed two UI fixture files inside `crates/pregolya-core/tests/ui/` (triggering clause (a) of §Recording Provenance validity criterion). No clause-by-clause paragraph or gate-count restatement was present.

**What was fixed:** Clause (a) paragraph added stating the rename is net-zero to exempt-file count; gate counts confirmed unchanged: `check-client-timeout PASSED: 25 analyzed, 16 exempt, 0 violations`; fixture-mode `14/17`; `148 codes / 0 collisions`.

### MED-006: lefthook burst-parity hook hardcoded story path, failed open on missing file

**What was wrong:** `EVIDENCE_REPORT` was hardcoded to `docs/demo-evidence/S-1.02/evidence-report.md` — would break every future story branch. The missing-file branch exited 0 (silent skip) instead of 1 (fail-closed).

**What was fixed:** Path now derived from current branch name: `git rev-parse --abbrev-ref HEAD` → extract `S-X.XX` → `docs/demo-evidence/${STORY_ID}/evidence-report.md`. Missing-file branch now exits 1.

### LOW-001: records-lint.sh frozen-HEAD extraction was case-sensitive

**What was wrong:** `grep -oE 'frozen HEAD [0-9a-f]{7,40}'` (no `-i`) would miss `**Frozen HEAD:** <sha>` capitalized form, silently disabling both live-HEAD guards.

**What was fixed:** Two-step case-insensitive extraction using `grep -i 'frozen[[:space:]]HEAD'`. Probe H added: synthetic checkpoint with `**Frozen HEAD:**` capitalized form; asserts `check_l13` finds the SHA.

### LOW-002: records-lint.sh feature-branch resolution was unanchored

**What was wrong:** `head -1` on all `feature/…` mentions in the checkpoint could pick the wrong branch during a multi-story wave.

**What was fixed:** Primary resolution now uses the line co-located with `FROZEN_HEAD_SHA` (bound co-location). Probe I added: synthetic checkpoint with decoy branch listed first; asserts correct branch is selected.

### LOW-003: evidence-report gate output conflated two separate chains

**What was wrong:** `"All pre-push hooks PASSED. records-lint.sh exits 0."` grouped lefthook pre-push and the factory-dispatcher chain as one.

**What was fixed:** Split into two distinct lines: lefthook pre-push attestation and factory-dispatcher chain attestation.

### OBS-001: --skip-self-probe produced byte-identical output to validated run

**What was done:** `records-lint.sh` now emits `[SELF-PROBE SKIPPED]` banner and appends `probes=skipped` to the `RESULT:` line when `--skip-self-probe` is active.

### OBS-002 (no action): credential _blocked.rs fixtures do not discriminate #[non_exhaustive]

Acknowledged as no-action by adversary — correctly documented in gate doc comment. `#[non_exhaustive]` for credentials is pinned by `test_non_exhaustive_inventory_matches_source` and `test_all_pub_types_have_non_exhaustive`.

### OBS-003: STATE.md BRANCH STATE used 7-char SHA

**What was done:** Normalized to 40-char form consistent with sibling surfaces.

**Test count:** 345 tests pass (cargo nextest), 7 skipped — no Rust logic changed; all xtask gates PASSED.

## fix-burst-50 (pass-48 findings)

### STATE.md D-419 phantom symbol / inverted mechanism; records accuracy corrections; fixture rename; structural completeness

**Pass-48 finding tally: 1 HIGH + 4 MED + 5 LOW + 3 OBS + 1 PROCESS-GAP.**

**HIGH-001 (F-P48-HIGH-001) — STATE.md D-419 inverted mechanism description:**
What was wrong: D-419 in STATE.md described the `check_l13` mechanism as "self-contained swap-and-restore" — but fix-burst-49 ELIMINATED swap-and-restore via parameterization. D-419 continued to describe the retired swap-and-restore pattern rather than the current `check_l13 [state_md_path]` parameterized invocation pattern.
What was fixed: state-manager corrected D-419 to accurately describe `check_l13` parameterization with optional path arg, retirement of the `_L13_CHECK` mirror function (0 calls remaining), and elimination of swap-and-restore. All 7 probes (A–G) call `check_l13 "$PROBE_L13X"` with synthetic path directly. The primary assertion in probe G is `grep -q "does not match live"` on `check_l13` output; the `[PASS]` absence guard is secondary.

**MED-001 (F-P48-MED-001) — CHANGELOG and evidence-report `probe_must_fail` citations in fix-burst-49 records incorrectly describe retired mechanism:**
What was wrong: CHANGELOG `## fix-burst-49` HIGH-001 paragraph last sentence said "→ `check_l13` correctly FAILs → `probe_must_fail` passes." Evidence-report `## fix-burst-49 re-verification` F-P47-HIGH-001 row Load-bearing-artifact said "→ FAIL → `probe_must_fail` passes." Fix-burst-49 structural refactor retired `probe_must_fail`; probe G now uses an inline negative guard that exits 2 when no FAIL text is present.
What was fixed: CHANGELOG HIGH-001 last sentence corrected to describe the inline negative guard mechanism. Evidence-report F-P47-HIGH-001 Load-bearing-artifact updated to match current probe G behavior.

**MED-002 (F-P48-MED-002) — CHANGELOG fix-burst-49 extraction-scope statement described nonexistent internal helper:**
What was wrong: The extraction-scope statement in the CHANGELOG fix-burst-49 section described a nonexistent internal helper rather than accurately characterizing the `check_l13 [state_md_path]` parameterized invocation pattern that was actually implemented.
What was fixed: technical-writer corrected the extraction-scope statement in the CHANGELOG fix-burst-49 section to accurately describe `check_l13 [state_md_path]` parameterized invocation pattern.

**MED-003 (F-P48-MED-003) — pass fixture filenames `_match_with_dots_passes` inconsistent with E0532-oriented naming established for fail fixtures in fix-burst-49:**
What was wrong: After fix-burst-49 renamed fail fixtures to `_external_field_access_blocked`, the corresponding pass fixtures still had filenames with `_match_with_dots_passes` suffix, inconsistent with the E0532-oriented naming convention.
What was fixed: test-writer renamed pass fixtures from `open_ai_api_key_match_with_dots_passes.rs` / `anthropic_api_key_match_with_dots_passes.rs` to `open_ai_api_key_expose_secret_passes.rs` / `anthropic_api_key_expose_secret_passes.rs`. story-writer updated §File Structure Requirements rows in story spec.

**MED-004 (F-P48-MED-004) — STATE.md D-419 enumeration incomplete; D-419/D-420 MED-001 contradiction:**
What was wrong: D-419 listed only partial pass-47 closure records (fewer than all 10 closures). D-419 and D-420 had contradictory descriptions for MED-001.
What was fixed: state-manager completed the D-419 enumeration to include all 10 pass-47 closures and resolved the D-419/D-420 MED-001 contradiction.

**LOW-001 (F-P48-LOW-001) — CHANGELOG and evidence-report fix-burst-49 live-HEAD example text cites transient branch name `feature/S-1.02`:**
What was wrong: `[live-HEAD: checked(feature/S-1.02=matched)]` was written as a static example value. The branch name `feature/S-1.02` is runtime-derived from `§Session Resume Checkpoint` and will differ in any future story.
What was fixed: Replaced `feature/S-1.02` with `<branch>` placeholder in both CHANGELOG MED-001 paragraph and evidence-report F-P47-MED-001 row. Added parenthetical clarifying `<branch>` is runtime-derived from `§Session Resume Checkpoint`.

**LOW-002 (F-P48-LOW-002) — Probe G EXIT trap does not delete throwaway ref on abort:**
What was wrong: The EXIT trap in probe G's shell function did not include cleanup of the PID-unique disposable ref (`refs/heads/feature/records-lint-selfprobe-g-$$`), so an interrupt or unexpected abort could leave the ref dangling.
What was fixed: devops-engineer extended the EXIT trap to delete the throwaway ref on any abort path.

**LOW-003 (F-P48-LOW-003) — Probe G assertion checks absence of `[PASS]` instead of presence of `[FAIL]` text:**
What was wrong: The inline negative guard (`if echo "$_L13G_OUT" | grep -q "\[PASS\]"`) asserts absence of `[PASS]` token. This passes vacuously if `check_l13` emits no output at all — an error exit or empty output would satisfy the guard without confirming FAIL behavior.
What was fixed: devops-engineer changed probe G's assertion from absence-of-PASS to presence-of-FAIL text.

**LOW-004 (F-P48-LOW-004) — Story spec §File Structure Requirements: 3 rows use crate-relative paths instead of repo-relative `crates/` paths:**
What was wrong: Three rows in §File Structure Requirements cited paths relative to the crate root instead of the repo-relative `crates/pregolya-core/src/…` form used by all other rows.
What was fixed: story-writer normalized the 3 rows to repo-relative `crates/` paths in story spec.

**LOW-005 (F-P48-LOW-005) — evidence-report fix-burst-49 re-verification section missing test count, gate output, KL note, and separator:**
What was wrong: The fix-burst-49 re-verification section contained only the pass-47 tally line and the 10-row attestation table, without the standard test count restatement, gate output line, known limitations cross-reference, or trailing separator.
What was fixed: technical-writer added test count, gate output, known limitations note, and trailing separator to the fix-burst-49 re-verification section.

**OBS-001 (F-P48-OBS-001) — records-lint.sh `check_l13` MAX_D awk extraction fragility:**
What was wrong: The `MAX_D` extraction in `check_l13` did not pipe through `awk -F'|' '{print $2}'` first-column extraction before the `grep -oE` step, allowing `D-NNN` tokens in later table columns to inflate the max decision ID.
What was fixed: devops-engineer added `awk -F'|' '{print $2}'` first-column extraction as the first pipe stage in `check_l13` `MAX_D` extraction (the function is `check_l13`, not `check_l8` — `check_l8` does not exist in the codebase).

**OBS-002 (F-P48-OBS-002) — records-lint.sh `check_l10`/`check_l11` false-positive on hooks files:**
What was wrong: `check_l10` and `check_l11` did not carry the `:!hooks/**` exclusion in their git diff path-specs, causing hooks-directory hex patterns to trigger the L10/L11 hash-digest bans (`check_l9` already carried the exclusion before this fix).
What was fixed: devops-engineer added `:!hooks/**` exclusion to git diff path-specs in `check_l10` and `check_l11`.

**OBS-003 (F-P48-OBS-003) — evidence-report fix-burst-48 rows not annotated as superseded by fix-burst-49:**
What was wrong: The fix-burst-48 HIGH-001 and MED-002 rows in the evidence-report cited swap-and-restore artifacts (`_L13_CHECK`, `L13-probe-G-real`, swap-and-restore windows) that were eliminated by fix-burst-49, with no annotation marking the rows as superseded.
What was fixed: technical-writer annotated fix-burst-48 HIGH-001 and MED-002 rows as superseded by fix-burst-49 closures; fix-burst-47 and earlier historical probe citations annotated as historical with supersession chain.

**PROCESS-GAP-001 (F-P48-PROCESS-GAP-001) — Burst-parity check unenforced at push time:**
What was wrong: No pre-push enforcement verified that the newest `## fix-burst-N` heading in CHANGELOG.md had a matching `## fix-burst-N re-verification` heading in evidence-report.md before a push could proceed.
What was fixed: devops-engineer added `check-burst-records-parity` as a pre-push command in `lefthook.yml`; the hook asserts the parity invariant on every push.

**Test count (fix-burst-50):** 345 tests pass (cargo nextest), 7 skipped (workspace). No Rust logic changes. Pass fixture rename (`_match_with_dots_passes` → `_expose_secret_passes`) maintains same trybuild fixture counts: 8 compile_fail + 7 pass = 15 total.

## fix-burst-49 (pass-47 findings)

### records-lint.sh structural refactor, credential fixture rename, records accuracy

**Pass-47 finding tally: 0 CRIT + 1 HIGH + 4 MED + 5 LOW.**

**HIGH-001 (F-P47-HIGH-001) — `L13-probe-G` coupled to live `feature/S-1.02` branch; records-lint.sh will hard-`exit 2` and block every `.factory/` commit once that branch is deleted:**
What was wrong: Probe G's synthetic STATE.md hardcoded `feature/S-1.02` in its §DEVELOP STATE. After PR merge and branch deletion, `git rev-parse --verify refs/heads/feature/S-1.02` returns empty; `_L13_CHECK` exits 0 (skip path); `probe_must_fail` fires `exit 2`, permanently blocking all factory-artifacts commits.
What was fixed: Probe G now creates a PID-unique disposable ref (`refs/heads/feature/records-lint-selfprobe-g-$$`) and references it in the synthetic STATE.md. The synthetic STATE.md contains an all-zeros frozen HEAD that does not match the live disposable ref's real SHA → `check_l13` correctly FAILs (output contains no `[PASS]` token) → the inline negative guard (`if echo "$_L13G_OUT" | grep -q "\[PASS\]"`) exits 2 on false-green, throwaway ref deleted on both paths. No reference to `feature/S-1.02` anywhere in the probe.

**MED-001 (F-P47-MED-001) — Step 3.5 PASS line had no positive-coverage signal for live-HEAD check:**
What was wrong: The PASS line only reported "3/3 surfaces in sync"; whether the live-HEAD assertion actually executed or was silently skipped was indistinguishable from the output.
What was fixed: `check_l13` now tracks `LIVE_HEAD_COVERAGE` through all code paths: `[live-HEAD: checked(<branch>=matched)]` (branch resolved, SHA matched; where `<branch>` is the feature branch name, runtime-derived from `§Session Resume Checkpoint`), `[live-HEAD: skipped(branch-not-found)]` (branch not resolvable), or `[live-HEAD: skipped(no-frozen-sha-in-checkpoint)]`. Both `emit PASS` sites append this suffix. Script-header and function-header comments updated to document both new FAIL conditions.

**MED-002 (F-P47-MED-002) — credential trybuild fail fixtures tested E0532 (field privacy) but were named and described as `#[non_exhaustive]` match-without-dots gates; pass fixtures were non-discriminating (opaque function call):**
What was wrong: `open_ai_api_key_match_without_dots_fails.rs` and `anthropic_api_key_match_without_dots_fails.rs` named "match_without_dots" implying failure was about `..` wildcard. The actual error is E0532 (private field blocks ALL pattern destructuring including `(..)`). Pass fixtures called an opaque function — not discriminating on field privacy or `#[non_exhaustive]`.
What was fixed: Renamed fail fixtures to `open_ai_api_key_external_field_access_blocked.rs` / `anthropic_api_key_external_field_access_blocked.rs` (E0532 naming). Pass fixtures now call `expose_secret()` — the correct external API, discriminating because the fixture fails to compile if `expose_secret()` is removed or made private. Gate doc comment corrected: for private-field tuple struct credentials, external boundary is enforced by field privacy (E0532); `#[non_exhaustive]` is pinned by inventory/glob gates. Story spec §File Structure Requirements updated (v1.25): old `_match_without_dots_fails` rows replaced, pass fixture descriptions corrected.

**MED-003 (F-P47-MED-003) — evidence-report fix-burst-48 MED-001 row cited SHA tokens `2d71869` / `489584d`, re-opening the fix-burst-35 de-SHA sweep:**
Self-corrected: SHA tokens removed; replaced with behavioral anchors. See evidence-report fix-burst-48 re-verification MED-001 row.

**MED-004 (F-P47-MED-004) — records-lint.sh `check_l13` hardcoded input path; swap-and-restore window put backup in trap-deleted PROBE_TMP, risking STATE.md destruction on interrupt:**
What was wrong: `check_l13` used `local STATE_MD="${FACTORY_DIR}/STATE.md"` (hardcoded). Probe F and Probe G-real used swap-and-restore to exercise the shipped function: backup → overwrite → check → restore. Backup stored in `PROBE_TMP` which is deleted by `trap 'rm -rf "$PROBE_TMP"' EXIT` — any interrupt destroyed STATE.md.
What was fixed: `check_l13` now accepts `check_l13 [state_md_path]` — optional first argument, defaulting to `${FACTORY_DIR}/STATE.md`. All 7 probes (A–G) now call `check_l13 "$PROBE_L13X"` directly with their synthetic file. The `_L13_CHECK` mirror function (~76 lines) retired entirely. All three swap-and-restore windows eliminated. No probe ever touches the canonical STATE.md.

**LOW-001 (F-P47-LOW-001) — CHANGELOG fix-burst-48 HIGH-001 paragraph cited `§DEVELOP STATE` sub-scope incorrectly:**
Corrected to "whole awk-delimited section" — the code extracts from the entire §Session Resume Checkpoint section.

**LOW-002 (F-P47-LOW-002) — evidence-report fix-burst-48 HIGH-001 row conflated `probe_must_fail "L13-probe-G"` with `L13-probe-G-real` inline guard:**
Split into two distinct assertions in the Load-bearing-artifact cell.

**LOW-003 (F-P47-LOW-003) — residual over-claim "accessible within the defining crate" at 3 sites:**
Corrected to "accessible within the defining module and its descendants" in CHANGELOG fix-burst-48 MED-004 paragraph, evidence-report fix-burst-47 re-verification LOW-002 row, and story spec AC-008 parenthetical (v1.24).

**LOW-004 (F-P47-LOW-004) — story spec §File Structure Requirements missing 3 rows:**
Added `open_ai_api_key_match_with_dots_passes.rs` (CREATE), `anthropic_api_key_match_with_dots_passes.rs` (CREATE), and `non_exhaustive_external_gate.rs` (MODIFY) in story spec v1.24. Subsequently updated all fail fixture rows to new `_external_field_access_blocked` names and corrected pass fixture descriptions in v1.25.

**LOW-005 (F-P47-LOW-005) — evidence-report section ordering non-monotonic (48/47/46 ascending inserted into descending 45→40 block):**
All 22 `## fix-burst-N re-verification` sections reordered to strict descending order (48→27), matching CHANGELOG.md convention.

**Test count (fix-burst-49):** 253 run: 253 passed, 5 skipped (xtask per-crate: `cargo nextest run -p xtask`). Full workspace: 345 run: 345 passed, 7 skipped (`cargo nextest run --workspace`). Test counts unchanged (no Rust logic changes; trybuild fixture rename keeps same compile_fail/pass counts: 8 compile_fail + 7 pass = 15 total).

## fix-burst-48 (pass-46 findings)

### records-lint.sh L13 live-HEAD check, probe G, probe F extension, banner correction, false Rust semantics correction

**Pass-46 finding tally: 1 HIGH + 4 MED + 1 OBS.**

**HIGH-001 (F-P46-HIGH-001) — L13 Step 3.5 vacuous; false-green when checkpoint and COMPLETE row share stale SHA:**
What was wrong: `check_l13` Step 3.5 verified the checkpoint's frozen HEAD SHA appeared in any `| COMPLETE |` row, but when both the checkpoint and a COMPLETE row referenced the same stale SHA, the check passed (e.g., be1af38 in D-413 COMPLETE + checkpoint also citing be1af38). The check never compared against the live feature branch HEAD.
What was fixed: added live branch HEAD resolution (`git rev-parse --verify refs/heads/<branch>` where `<branch>` is extracted from the §Session Resume Checkpoint section (whole awk-delimited section)); now fails when checkpoint frozen HEAD != live branch HEAD. Changed `head -1` to `tail -1` for extraction to take the most recent `frozen HEAD <sha>` match. Same fix applied to `_L13_CHECK` mirror. New self-probe `L13-probe-G` (must_fail): synthetic STATE.md with all-zeros frozen HEAD that exists in a COMPLETE row but != live branch HEAD. Probe F extended to also invoke real `check_l13` via swap-and-restore (addresses MED-002). Banner in `run_self_probes` updated to "Seven probes (A–G)".

**MED-001 (F-P46-MED-001) — STATE.md cited be1af38 throughout; no D-415/D-416:**
Self-resolved: state-manager committed D-414 COMPLETE + D-415 COMPLETE (fix-burst-47, pushed at 489584d816281cfc371a66c7174ab0641ea8621b) + D-416 IN FLIGHT (adversary pass-46 dispatched) in a single factory-artifacts commit (2d71869). No code action required.

**MED-002 (F-P46-MED-002) — L13 probes A–F exercised _L13_CHECK mirror, not shipped check_l13:**
Bundled with HIGH-001 fix above (probe F extension with swap-and-restore).

**MED-003 (F-P46-MED-003) — run_self_probes L13 block banner said "Five probes:":**
Bundled with HIGH-001 fix above (banner updated to "Seven probes (A–G)" with full enumeration).

**MED-004 (F-P46-MED-004) — 3 artifact sites propagated false Rust semantics ("`#[non_exhaustive]` + private field" claim):**
What was wrong: fix-burst-47 LOW-002 closure stated that direct tuple-struct construction of `OpenAiApiKey`/`AnthropicApiKey` was unavailable due to `#[non_exhaustive]` + private field. This is false: `#[non_exhaustive]` only restricts construction outside the defining crate; the private field is accessible within the defining module and its descendants (tests are in `#[cfg(test)] mod tests` with `use super::*`).
What was fixed: story spec AC-008 parenthetical corrected (v1.23); CHANGELOG fix-burst-47 LOW-002 paragraph corrected; evidence-report fix-burst-47 re-verification LOW-002 row corrected. Accurate claim: tests use `from_raw_for_tests()` because it is the explicit `#[cfg(test)]`-gated validation-bypass helper, not because the tuple form is unavailable.

**Test count (fix-burst-48):** 253 run: 253 passed, 5 skipped (xtask per-crate: `cargo nextest run -p xtask`). Full workspace: 345 run: 345 passed, 7 skipped (`cargo nextest run --workspace`). Test counts unchanged (no Rust code changes in fix-burst-48).

### Known limitations after fix-burst-48

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 253 run: 253 passed, 5 skipped (xtask per-crate); 345 run: 345 passed, 7 skipped (workspace). Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-47 (pass-45 findings)

### Evidence-report attestation corrections, AllowList entry-side normalization pin, L13 frozen-HEAD SHA currency, story-spec AC-008 construction form

**Pass-45 finding tally: 3 MED + 2 LOW.**

**MED-001 (F-P45-MED-001) — evidence-report fix-burst-46 MED-004 attestation cited `probe_must_fail` for probe E (convergence-absent path); code uses `probe_must_not_fail`:**
The MED-004 attestation row in the fix-burst-46 re-verification section incorrectly described the probe direction as `probe_must_fail "L13-probe-E"`. Probe E covers the convergence-absent path where `check_l13` skips the convergence surface and emits PASS — the probe must NOT fail (success expected). The fix inverts the label to `probe_must_not_fail "L13-probe-E"`. No code change required — record-only correction.

**MED-002 (F-P45-MED-002) — `AllowList::is_allowed` entry-side normalization lacked a load-bearing regression pin:**
Fix-burst-46 MED-003 added `test_allowlist_exact_match` with a backslash assertion pinning the path-side normalization (`let normalized_path = path.replace('\\', "/")`) in `AllowList::is_allowed`. The entry-side normalization (`let normalized_entry = e.path.replace('\\', "/")`) was not pinned — reverting it left the test suite green. Fixed by implementer: new test `test_allowlist_is_allowed_entry_side_normalization` added; reverting entry-side normalization causes the test assertion to fail. Test is load-bearing.

**MED-003 (F-P45-MED-003) — L13 false-green when newest §Current Phase Steps row is IN FLIGHT (MAX_D degrades to previous COMPLETE, bypassing the parity check) / frozen-HEAD SHA currency:**
When the most recent D-NNN row in §Current Phase Steps carries status IN FLIGHT rather than COMPLETE, `MAX_D` in `check_l13` degrades to the prior COMPLETE value. If the §Session Resume Checkpoint and §Convergence Status cite the IN FLIGHT D-NNN, the parity check passes on a stale baseline, silently hiding the mismatch between the checkpoint and the actual newest completed decision. Fixed by devops-engineer: frozen-HEAD SHA currency check added to `check_l13`; `L13-probe-F` added to `records-lint.sh` with a synthetic STATE.md containing a §Session Resume Checkpoint frozen HEAD SHA absent from all COMPLETE rows — `probe_must_fail "L13-probe-F"` asserts FAIL. `records-lint.sh` exits 0 on current STATE.md. LOW-001 bundled: `check_l13` function-header comment updated to document both "3/3 surfaces in sync" (convergence PRESENT) and "2/2 surfaces asserted (convergence SKIPPED)" PASS templates.

**LOW-001 (F-P45-LOW-001) — `check_l13` function-header comment documented only the "3/3 surfaces in sync" PASS template; the convergence-SKIPPED "2/2 surfaces asserted" template was undocumented:**
Function-header banner updated to enumerate both PASS templates explicitly. Bundled with MED-003 fix as a single records change. No new test required (comment-only correction).

**LOW-002 (F-P45-LOW-002) — AC-008 in story spec cited non-idiomatic tuple-struct construction form `OpenAiApiKey("sk-real".to_string())`:**
`#[non_exhaustive]` restricts construction only outside the defining crate; the private inner field is accessible within the crate's own module tree (including `#[cfg(test)] mod tests` with `use super::*`). The tests use `from_raw_for_tests()` because it is the explicit `#[cfg(test)]`-gated validation-bypass helper — not because the tuple form is unavailable. Fixed by story-writer: AC-008 Verified-by updated to use `from_raw_for_tests("sk-real")` form; story spec version bumped to v1.22.

**Test count (fix-burst-47):** 253 run: 253 passed, 5 skipped (xtask per-crate: `cargo nextest run -p xtask`). Full workspace: 345 run: 345 passed, 7 skipped (`cargo nextest run --workspace`; includes pregolya-core and other workspace crate tests; basis: full workspace per push hook convention established in fix-burst-45). Net change from fix-burst-46: +1 xtask test (`test_allowlist_is_allowed_entry_side_normalization`).

### Known limitations after fix-burst-47

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 253 run: 253 passed, 5 skipped (xtask per-crate); 345 run: 345 passed, 7 skipped (workspace). Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-46 (pass-44 findings)

### CHANGELOG attestation correction, test-count reconciliation, STATE.md structural fixes, normalization regression pins, L13 denominator fix, story-spec AC-009 phantom cite

**HIGH-001 (F-P44-HIGH-001) — CHANGELOG fix-burst-43 OBS-001 stale labels:**
The fix-burst-43 OBS-001 paragraph attesting the L13 implementation cited "Phase Progress COMPLETE rows" (wrong source table — should be "§Current Phase Steps") and "Three self-probes" (wrong count — four probes ship). This paragraph was the *originating* claim; it was never swept when fix-burst-44/45 corrected the same labels in records-lint.sh and other documents. Fixed by technical-writer in this burst.

**MED-001 (F-P44-MED-001) — fix-burst-45 test count missing skipped count and undocumented basis change:**
fix-burst-45 attested "343 run: 343 passed" with no skipped count, while fix-burst-44 said "251 run: 251 passed, 5 skipped." The 343 is the full workspace count (`cargo nextest run --workspace`), which is larger because it includes pregolya-core and other workspace crate tests in addition to xtask. The basis change from per-crate to full workspace was not documented, and the "5 skipped" term disappeared despite five `#[ignore]` tests remaining in xtask. Fixed: corrected to "343 run: 343 passed, 7 skipped" with explicit basis statement.

**MED-002 (F-P44-MED-002) — §Convergence Status duplicated paragraph + inline heading fragment:**
STATE.md §Convergence Status had the Counter paragraph appear twice back-to-back (two copies, neither identical to the other), and the second copy terminated with `…Streak: 0/3.## Session Resume Checkpoint` glued to prose instead of a clean line break. Fixed by state-manager: duplicate removed, inline heading fragment removed.

**MED-003 (F-P44-MED-003) — Two of six path-normalization sites lacked load-bearing regression pins:**
`AllowList::is_allowed` and the `check_file_size` exclusion loop (`name_n` site) had no backslash test assertions — reverting normalization at either site left the test suite green. Fixed by implementer: `is_size_gate_excluded(name: &str) -> bool` extracted as `pub(crate)` function from the `check_file_size` loop, pinned with `test_is_size_gate_excluded_windows_paths` (5 assertions: 3 positive backslash paths for `/target/`, `/tests/fixtures/`, `.gen.rs`; 2 negative controls); `test_allowlist_exact_match` extended with one backslash assertion against the existing entry.

**MED-004 (F-P44-MED-004) — L13 hardcoded "3/3" on convergence-absent skip path:**
When §Convergence Status was absent or carried no `**D-NNN` bold entry, `check_l13` emitted "3/3 surfaces in sync" despite only asserting 2 surfaces. Fixed by devops-engineer: denominator computed at runtime (`ASSERTED=2` when skipped, `3` otherwise); probe E added for convergence-absent path.

**MED-005 (F-P44-MED-005) — STATE.md checkpoint stale (D-411 IN FLIGHT at review time):**
STATE.md was reviewed mid-update with D-411 still IN FLIGHT and D-412 not yet recorded. Fixed by state-manager.

**MED-006 (F-P44-MED-006) — AC-009 phantom compile-fail cite + missing AnthropicApiKey + stale `.as_str()`:**
STORY-S-1.02 AC-009 Verified-by cited "compile-fail test or `static_assertions::assert_not_impl_any!(OpenAiApiKey: AsRef<str>)`" — no compile-fail test exists; only the static assertion. `AnthropicApiKey` was also omitted despite the same assertion existing in credentials.rs. And "`.as_str()` or `.expose_secret()` method" was stale — `.as_str()` doesn't exist on either type. Fixed by story-writer: Verified-by rewritten to cite both `OpenAiApiKey` and `AnthropicApiKey` static assertions; phantom compile-fail hedge removed; `.as_str()` removed from exposure-path sentence.

**Test count (fix-burst-46):** 252 run: 252 passed, 5 skipped (xtask per-crate: `cargo nextest run -p xtask`). Full workspace: 344 run: 344 passed, 7 skipped (`cargo nextest run --workspace`). Net change from fix-burst-45: +1 xtask test (`test_is_size_gate_excluded_windows_paths`), +1 assertion in `test_allowlist_exact_match`.

### Known limitations after fix-burst-46

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 252 run: 252 passed, 5 skipped (xtask per-crate); 344 run: 344 passed, 7 skipped (workspace). Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-45 (pass-43 findings)

### records-lint.sh header / STATE.md PGAP / evidence-report — stale source-table labels, skip-conditions rewrite, attestation table

**HIGH-001 (F-P43-HIGH-001) — records-lint.sh header + STATE.md PGAP: stale source-table label persists:**
The fix-burst-44 sweep corrected 15 sites inside `check_l13` body and probe fixtures but missed two sites in records-lint.sh's top-of-file header inventory block: (1) the L13 entry saying "Decision Log / Phase Progress table rows"; (2) the same entry's PASS-condition text "(Decision Log not yet started)". The STATE.md PGAP entry's additional assertion clause also still cited "newest D-NNN in the Decision Log" instead of "newest COMPLETE D-NNN in §Current Phase Steps". Because the header inventory is the operator-facing specification and the PGAP entry is the live obligation text, a maintainer implementing the remaining PGAP obligation from either document would re-introduce the exact mis-anchor that MED-003 was filed to remove. Fixed by devops-engineer (records-lint.sh header rewrite) and state-manager (PGAP entry correction). CHANGELOG fix-burst-44 MED-003 attestation corrected (above).

**MED-001 (F-P43-MED-001) — records-lint.sh header "Skip conditions" documents pre-fix PASS semantics:**
The L13 header entry's "Skip conditions (PASS without blocking assertion)" paragraph still listed STATE.md absent, zero rows, and checkpoint absent as PASS-on-absence conditions — the exact semantics that fix-burst-44 MED-005 changed to FAIL. The code was correct; the documentation told maintainers the opposite. Fixed by devops-engineer: "Skip conditions" rewritten to distinguish "Blocking FAIL (vacuity guards)" from "Genuine skip (§Convergence Status absent)" and states the four self-probes.

**LOW-001 (F-P43-LOW-001) — evidence-report fix-burst-44 re-verification missing attestation table:**
`## fix-burst-44 re-verification` had no per-detection-class attestation table for MED-003 (anchor sweep) or MED-005 (vacuity guards + probe D), unlike the fix-burst-43 section which carried a row for its records-lint change. Fixed by adding a two-row attestation table naming `L13-probe-D` as the load-bearing artifact for MED-005.

**Test count:** 343 run: 343 passed, 7 skipped (`cargo nextest run --workspace`; includes pregolya-core and other workspace crate tests; xtask per-crate: `cargo nextest run -p xtask` → 251 run: 251 passed, 5 skipped; basis changed to full workspace from push hook starting fix-burst-45 — no test additions in fix-burst-45). 10-row KL table (same structure; no new KL entries).

### Known limitations after fix-burst-45

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 343 run: 343 passed (full workspace; no code or test changes). Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-44 (pass-42 findings)

### STATE.md / records-lint.sh / CHANGELOG — Decisions Log misfiling, duplicate D-407, records-lint.sh mis-anchors, CHANGELOG attestation corrections, L13 vacuity paths

**MED-001 (F-P42-MED-001) — Decisions Log truncated at D-384; D-385..D-408 misfiled:** 24 decision rows were appended below the §Drift/Deferrals genuine deferral rows without a separator, making them GFM-parse into the Deferral table (wrong schema). §Decisions Log appeared to terminate at D-384. Fixed by state-manager: rows moved to §Decisions Log after D-384.

**MED-002 (F-P42-MED-002) — Duplicate D-407 rows + D-406 out of sequence:** Among the misfiled rows, D-407 appeared twice (different text, same ID); D-406 was sandwiched between them. Fixed by state-manager: shorter D-407 removed; sequence restored to monotonic ...D-405, D-406, D-407, D-408.

**MED-003 (F-P42-MED-003) — records-lint.sh L13 mis-anchors source table:** Comments name "Phase Progress" and "Decision Log" but the regex targets §Current Phase Steps. FAIL message routes state-manager to "Decision Log" (terminating at D-384 before fix-burst-44). Fixed by devops-engineer: all references inside `check_l13` function body and associated probe fixtures corrected to '§Current Phase Steps' (15 sites). Two sites in the top-of-file header inventory block and one site in the STATE.md PGAP entry were not swept; these are addressed in fix-burst-45 (F-P43-HIGH-001).

**MED-004 (F-P42-MED-004) — CHANGELOG fix-burst-43 OBS-001 false DONE attestation:** CHANGELOG said PGAP marked "IN PROGRESS → DONE" but STATE.md still marks it IN PROGRESS and only the D-NNN parity half (L13) shipped. Corrected in this fix-burst.

**MED-005 (F-P42-MED-005) — L13 three vacuity paths PASS silently:** STATE.md absent, zero matching rows, checkpoint-phrase absent each silently PASS instead of FAIL. Fixed by devops-engineer: vacuity FAIL guards + probe D exercising NOT-FOUND path.

**LOW-001 (F-P42-LOW-001) — "A ninth function" residue:** CHANGELOG fix-burst-41 said "A ninth function"; evidence-report said "One additional function". Corrected to "One additional test function".

**Test count:** 251 run: 251 passed, 5 skipped (no code or test changes in fix-burst-44 — all factory-artifacts and CHANGELOG corrections).

### Known limitations after fix-burst-44

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 251 run: 251 passed, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-43 (pass-41 findings)

### xtask main / STATE.md — attestation corrections, validate_allowlist_entry_path Windows normalization, records-lint parity check

**MED-001 (F-P41-MED-001) — STATE.md checkpoint staleness (5th consecutive recurrence):** D-407 was recorded in the Decision Log but §Convergence Status, §Session Resume Checkpoint, and §Branch State were not propagated. Fixed by state-manager (D-408): D-407 entry appended to §Convergence Status; checkpoint re-stamped to D-407 state; Phase Progress extended through D-408.

**MED-002 (F-P41-MED-002) — evidence-report fix-burst-41 §Findings closed and §Clause (d) still said "nine load-bearing":** The table row 4 correction made in fix-burst-42 was not propagated to the prose sentences in the same section. Fixed: §Findings closed now says eight backslash-path assertions with one non-load-bearing addition (renamed in fix-burst-42); §Clause (d) says 8 not 9.

**LOW-001 (F-P41-LOW-001) — "eight load-bearing" overcounts by two:** Two of the eight backslash-path test assertions are negative controls (`!is_test_file(r"crates\...\lib.rs")` and `!is_test_class_file(r"crates\...\lib.rs")`) that do NOT fail under reversion of the `replace('\\', "/")` normalization — the raw backslash form still returns false for a lib.rs path regardless of normalization. Only the six positive cases are truly load-bearing under reversion. Fixed: CHANGELOG and evidence-report now say "six load-bearing positive assertions plus two non-load-bearing negative controls."

**LOW-002 (F-P41-LOW-002) — `validate_allowlist_entry_path` POSIX-only predicates:** Last unswept path predicate in the allowlist family. Fixed by implementer: `let path = path.replace('\\', "/");` added as first statement in `validate_allowlist_entry_path`. Load-bearing test `test_validate_allowlist_entry_path_windows_separator` added (3 assertions: 2 positive backslash cases, 1 negative control).

**OBS-001 (F-P41-OBS-001) — PGAP-RECORDS-LINT-FIXBURST-PARITY implemented:** 5 consecutive recurrences of the STATE.md checkpoint staleness defect class triggered production-grade default (CLAUDE.md Rule 3). Devops-engineer extended `.factory/hooks/records-lint.sh` with L13 (D-NNN parity assertion): extracts max D-NNN from §Current Phase Steps rows carrying `| COMPLETE |`, asserts same value appears in §Session Resume Checkpoint and §Convergence Status. Four self-probes (A/B/C/D); note probe D (checkpoint-absent path) was added in fix-burst-44. The D-NNN parity half of PGAP-RECORDS-LINT-FIXBURST-PARITY shipped (records-lint.sh L13). The primary obligation — asserting newest `## fix-burst-N` in CHANGELOG matches `## fix-burst-N re-verification` in evidence-report and a corresponding story-spec changelog row — remains unimplemented. PGAP entry remains IN PROGRESS in STATE.md OPEN SELF-IMPROVEMENT ITEMS pending the fix-burst-N ↔ evidence-report ↔ story-spec parity check.

**Test count:** 251 run: 251 passed, 5 skipped (+1 `test_validate_allowlist_entry_path_windows_separator`; was 250 from fix-burst-42).

### Known limitations after fix-burst-43

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 251 run: 251 passed, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-42 (pass-40 findings)

### xtask main / check_no_panic / check_file_size — discriminating fixture-guard test, POSIX-only exclusion predicates, STATE.md checkpoint staleness (4th recurrence), evidence-report row correction

**MED-001 (F-P40-MED-001) — non-load-bearing fixture-guard test (TD-VSDD-059):** `test_scan_for_panics_exempt_fixture_windows` used path `xtask\src\fixtures\violations\test.rs` which causes `is_test_file` to return false (no `/tests/` directory component, no `tests.rs` suffix match after normalization) — the `&&` short-circuits and `normalized_path` is never consulted. Reverting the `normalized_path` fix in `scan_for_panics_in_source` would not fail this test. Fix: renamed the test to `test_scan_for_panics_clean_source_windows_path_not_in_test_tree` (which accurately describes its actual coverage: a non-test-tree Windows path with clean source). Added discriminating regression pin `test_scan_for_panics_violations_fixture_not_exempted_windows_path` using path `r"xtask\tests\fixtures\violations\violation_unwrap.rs"` (IS a test-tree path: contains `/tests/` after normalization), panicking source (bare `.unwrap()` call), asserts NON-empty findings — this assertion FAILS if `normalized_path` reverts to raw `path`. Also corrected the CHANGELOG fix-burst-41 HIGH-001 paragraph and evidence-report table row 4.

**MED-002 (F-P40-MED-002) — POSIX-only exclusion predicates in `check_file_size` loop (TD-VSDD-060):** The per-report loop in `check_file_size` contained four exclusion predicates; two used hard-coded forward slashes (`/target/` and `/tests/fixtures/`). Fix: added `let name_n = name.replace('\\', "/");` at the top of the loop body and updated all four predicates to use `name_n`. Display and filesystem uses of `name` remain unchanged.

**MED-003 (F-P40-MED-003) — STATE.md checkpoint staleness (4th recurrence):** §Session Resume Checkpoint, §Convergence Status, and §Phase Progress were not propagated at D-406. Fixed by state-manager (D-407): checkpoint re-stamped to D-406 state, D-406 entry appended to §Convergence Status, §Phase Progress extended through D-406.

**LOW-001 (F-P40-LOW-001) — evidence-report row 3 wrong backslash forms:** Row 3 of the fix-burst-41 re-verification per-detection-class attestation table claimed the `test_is_test_class_file_patterns` additions verified `_test.rs` and `_tests.rs` suffix forms. The actual three cases added were: `crates\pregolya-core\tests\integration.rs` (backslash `tests\` directory component → `contains("/tests/")` branch), `crates\pregolya-core\src\tests.rs` (backslash `tests.rs` filename → `ends_with("/tests.rs")` branch), and a negative control `crates\pregolya-core\src\lib.rs` → false. Corrected in evidence-report.

**Test count:** 250 run: 250 passed, 5 skipped (+1 discriminating test `test_scan_for_panics_violations_fixture_not_exempted_windows_path`; renamed test retains same count; net +1 from fix-burst-41's 249).

### Known limitations after fix-burst-42

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 250 run: 250 passed, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-41 (pass-39 findings)

### xtask main / check_no_panic — Windows path-separator normalization in exemption predicates; STATE.md checkpoint staleness

**HIGH-001 (F-P39-HIGH-001) — Windows path-separator normalization gap in exemption predicates:** The `walkdir` refactor (fix-burst-35) replaced POSIX `find` subprocess for file *discovery* but did not extend Windows portability to file *classification*. The exemption predicates `is_test_file`, `is_test_class_file` (in `main.rs`) and the `fixtures/violations` guard in `scan_for_panics_in_source` (in `check_no_panic.rs`) matched exclusively on POSIX forward-slash forms. On Windows, `WalkDir` and `Path::push` yield OS-native backslash-separated paths, so the exemptions silently failed: test-file `unwrap()`/`expect()` calls would be flagged as violations and `check-file-size` would apply the 750-line production gate to `xtask/src/tests.rs`. Contradicted by `AllowList::is_allowed` in the same file, which explicitly normalizes with `replace('\\', "/")`.

Fix: added `let path = path.replace('\\', "/");` as the first statement in `is_test_file` and `is_test_class_file`; added `let normalized_path = path.replace('\\', "/");` and updated the fixture guard in `scan_for_panics_in_source` to use `normalized_path`. Six load-bearing positive assertions plus two non-load-bearing negative controls across two extended test functions (`test_is_test_file_patterns`: 4 positive backslash cases + 1 negative control, `test_is_test_class_file_patterns`: 2 positive backslash cases + 1 negative control). The negative controls pass under reversion and are regression guards, not reversion pins. One additional test function `test_scan_for_panics_exempt_fixture_windows` was added but proved non-load-bearing: the test path `xtask\src\fixtures\violations\test.rs` does not match any `is_test_file` predicate, so `normalized_path` was never evaluated — the guard short-circuits. A discriminating replacement was added in fix-burst-42 (F-P40-MED-001); the existing test was renamed. False "Windows portability restored" attestation in fix-burst-35 MED-002 corrected.

`is_lint_exempt_file` was inspected and requires no change — it delegates entirely to `is_test_file`, which now normalizes.

**MED-001 (F-P39-MED-001) — STATE.md checkpoint staleness:** §Session Resume Checkpoint, §Convergence Status, and §Phase Progress Finding Progression not propagated at D-405. Fixed by state-manager (D-406): checkpoint updated to D-405/pass-39 state; Convergence Status extended through D-405; Phase Progress extended D-401–D-405; PGAP-RECORDS-LINT-FIXBURST-PARITY scope extended to include STATE.md checkpoint freshness.

**Test count:** 249 run: 249 passed, 5 skipped (was 248 run before fix-burst-41; +1 new test function `test_scan_for_panics_exempt_fixture_windows`).

### Known limitations after fix-burst-41

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 249 run: 249 passed, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-40 (pass-38 findings)

### Multi-site gate-count stale-phrase correction; fix-burst-39 OBS records added

**MED-001 (F-P38-MED-001) — Three remaining stale "all 6 gates" / "six xtask lint gates" sites corrected:** (1) STATE.md D-401 rows in Current Phase Steps and Decision Log corrected from "all 6 gates depend on `collect_rust_files()`" to "five of seven xtask lint gates (six call sites)". (2) CHANGELOG fix-burst-35 MED-002 paragraph heading corrected to enumerate six call sites across five gates. Also: D-404 "sibling-site sweep complete" attestation superseded — the sweep enumerated only 3 sites and missed 3 more; full sweep at this fix-burst confirms no remaining stale instances. TD-VSDD-059 false-closure attestation class.

**LOW-001 (F-P38-LOW-001) — fix-burst-39 CHANGELOG section and evidence-report re-verification updated to include OBS-001 and OBS-002 paragraphs, and finding inventory updated:** Finding inventory updated to "1 MED + 1 LOW + 2 OBS" in both CHANGELOG fix-burst-39 and evidence-report `## fix-burst-39 re-verification` sections.

**OBS-001 (F-P38-OBS-001) — PGAP-RECORDS-LINT-FIXBURST-PARITY added to STATE.md OPEN SELF-IMPROVEMENT ITEMS with devops-engineer routing:** OBS-002 from pass-37 now constitutes the 3rd recurrence of unrecorded-burst pattern; PGAP entry is the mechanical prevention mechanism.

### Known limitations after fix-burst-40

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 248 xtask tests pass, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-39 (pass-37 findings)

### xtask `collect_rust_files` doc comment sibling-sweep; fix-burst-38 records added

**MED-001 (F-P37-MED-001) — fix-burst-38 had no CHANGELOG or evidence-report record (recurrence of F-P35-MED-001 class):** Added `## fix-burst-38 (pass-36 findings)` CHANGELOG section and `## fix-burst-38 re-verification` evidence-report section. fix-burst-38 was a RECORDS-ONLY micro-burst closing the walkdir gate-count precision finding (F-P36-LOW-001). Records now complete through fix-burst-38.

**LOW-001 (F-P37-LOW-001) — `collect_rust_files` doc comment retains "all six gate entry points" after fix-burst-38 swept the sibling record artifacts:** Doc comment on `collect_rust_files` in `main.rs` updated to match the canonical wording: "five of the seven xtask lint gates (six call sites — `check-no-panic` invokes it for both the normal scan and the `--fixture-mode` path)". Partial-Fix Regression Discipline (TD-VSDD-060) sibling-site sweep now complete: the CHANGELOG paragraph, story spec row, and source doc comment all carry the same wording.

**OBS-001 (F-P37-OBS-001) — story spec path convention:** The adversary dispatch convention specifies story spec at `.factory/stories/<story-id>-*.md` but the canonical location is `.factory/stories/stories/STORY-<ID>-*.md` (nested `stories/stories/` directory). Resolved in dispatches by specifying the exact absolute path. Not a code defect; convention reconciliation noted.

**OBS-002 (F-P37-OBS-002) — recurrence pattern (unrecorded burst, 2nd occurrence):** The "unrecorded-burst" defect class had now occurred twice (fix-burst-36, fix-burst-38). Process-gap tag fires at 3+ recurrences. Follow-up: extend records-lint.sh to assert newest fix-burst-N in CHANGELOG matches evidence-report and story-spec changelog (PGAP-RECORDS-LINT-FIXBURST-PARITY, routed to devops-engineer, tracked in STATE.md OPEN SELF-IMPROVEMENT ITEMS).

### Known limitations after fix-burst-39

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 248 xtask tests pass, 5 skipped. (Doc comment fix only — no behavioral change, no new tests.) Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-38 (pass-36 findings)

### xtask walkdir gate-count precision fix — RECORDS-ONLY micro-burst (TD-RECORDS-MICRO-BURST-001)

**LOW-001 (F-P36-LOW-001) — walkdir gate-count precision fix:** Story spec §Library & Framework Requirements walkdir row Purpose cell updated from "all six xtask lint gates" to "five of seven xtask lint gates via `collect_rust_files()` (six call sites — `check-no-panic` invokes it for both normal scan and `--fixture-mode`)". CHANGELOG fix-burst-36 MED-002 paragraph corrected: "all six xtask lint gates" → "five of seven xtask lint gates (six call sites — `check-no-panic` invokes `collect_rust_files()` for both the normal scan and `--fixture-mode` path)".

**Records-only burst:** No behavioral changes to xtask gates. No scanner logic modified. records-lint.sh exit 0.

### Known limitations after fix-burst-38

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 248 xtask tests pass, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-37 (pass-35 findings)

### xtask check_client_timeout — records backfill, bin/oct negative controls, test count correction

**MED-001 (F-P35-MED-001) — fix-burst-36 had no record in CHANGELOG or evidence-report; shipped code contained a dangling `fix-burst-36 OBS-001` citation in test doc comments; test count attestation was stale (244 vs actual 246):** Added `## fix-burst-36 (pass-34 findings)` CHANGELOG section and `## fix-burst-36 re-verification` evidence-report section documenting all pass-34 findings and their closures. Note that `INT_SUFFIXES` is now a single module-level const (superseding the "per-radix" phrasing in fix-burst-35 LOW-001). Correct test count of 246 now attested in both records.

**LOW-001 (F-P35-LOW-001) — bin/oct radix paths had positive-direction tests only; no negative controls:** Two negative controls added to `check_client_timeout.rs`: `test_timeout_checker_bin_nonzero_literal_not_flagged` (binary `0b11110` = 30 seconds must NOT be flagged; LOAD-BEARING: fails without the all-zeros digit predicate in the binary branch of `is_zero_literal`) and `test_timeout_checker_oct_nonzero_literal_not_flagged` (octal `0o36` = 30 seconds must NOT be flagged; LOAD-BEARING: same predicate for the octal branch). Both assert `findings.is_empty()`. The hex radix path already had `test_timeout_checker_hex_literal_with_f64_suffix_not_zero` as a negative control; all three non-decimal radix paths now have symmetric positive + negative coverage.

### Known limitations after fix-burst-37

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 248 xtask tests pass, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-36 (pass-34 findings)

### xtask deny_bare_api_key / check_no_panic / check_client_timeout — story spec VP frontmatter, walkdir row, symbol-trio correction, CHANGELOG extension, INT_SUFFIXES hoist

**MED-001 — Story spec §Purity Classification `deny_bare_api_key.rs` row Justification and `check_no_panic.rs` row Justification stale:** `deny_bare_api_key.rs` Justification updated from "find subprocess" to `collect_rust_files() (walkdir)`. `check_no_panic.rs` Justification extended with "; file discovery via `collect_rust_files()` (walkdir)". `check_client_timeout.rs` row was already correct (walkdir) — no change needed.

**MED-002 — `walkdir = "2"` row missing from story spec §Library & Framework Requirements MANDATORY table:** Added `walkdir = "2"` row — cross-platform recursive Rust-file discovery for five of seven xtask lint gates (six call sites — `check-no-panic` invokes `collect_rust_files()` for both the normal scan and `--fixture-mode` path) via `collect_rust_files()`, replaces POSIX `find`.

**MED-003 — VP-DI010-02 and VP-DI010-03 absent from `verification_properties` frontmatter in story spec:** VP-DI010-02 and VP-DI010-03 added with `status: delivered`, `gate: cargo xtask deny-bare-api-key`. These VPs correspond to BC-2.14.005 enforcement: no `Serialize` derive and no `Deref<Target=str|String>` on credential newtypes. Story bumped to v1.19.

**LOW-001 — STATE.md D-398 decision row cited incorrect symbol trio for `PanicVisitor` function visitors:** Symbol trio corrected from `visit_expr_call, visit_expr_method_call, visit_expr_macro` to `visit_item_fn, visit_impl_item_fn, visit_trait_item_fn` — these are the actual methods in `PanicVisitor` that carry the `#[test]`-family last-path-segment guard.

**LOW-002 — CHANGELOG fix-burst-35 LOW-001 paragraph did not note the `TYPE_SUFFIXES` split into two named constants:** Added one sentence noting that `TYPE_SUFFIXES` was split into `DECIMAL_SUFFIXES` (decimal path, includes f64/f32 suffixes) and per-radix `INT_SUFFIXES` (hex/bin/oct paths, integer suffixes only), so the fix-burst-34 longest-first ordering attestation applies to both constants.

**OBS-001 — `INT_SUFFIXES` declared inline three times in hex/bin/oct branches of `is_zero_literal`:** `INT_SUFFIXES` hoisted to module-level const in `check_client_timeout.rs`, removing three identical inline declarations from the hex/bin/oct branches of `is_zero_literal`. The module-level const is now the single source of truth for integer suffixes across all three radix paths. Two new regression tests added to pin radix parity: `test_timeout_checker_bin_zero_literal_flagged` (binary zero `0b0` is flagged; asserts `!findings.is_empty()`) and `test_timeout_checker_oct_zero_literal_flagged` (octal zero `0o0` is flagged; asserts `!findings.is_empty()`).

### Known limitations after fix-burst-36

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 246 xtask tests pass, 5 skipped. Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

## fix-burst-35 (pass-33 findings)

### xtask check_client_timeout / check_no_panic — BC authority correction, walkdir portability, clause-(d) re-attestation de-SHA sweep, hex-radix fix, doc-comment count correction, cross-reference label fix

**MED-001 — `{INV-004}` mis-cited as authority for zero-duration timeout rule in `check_client_timeout.rs` and `tests.rs`:** `{INV-004}` governs config-struct defaults with `None` (unlimited), not the builder-chain zero-duration rule. Approximately 24 sites corrected to cite `{PC-001}` (builder-chain rule: "`.timeout(duration)` with `duration > Duration::ZERO` before `.build()`"). Six `{INV-004}` sites in `tests.rs` were correctly preserved — they appear in `BC-2.14.003` test-file exemption context.

**MED-002 — Six `collect_rust_files()` call sites across five of seven xtask lint gates used POSIX `find` subprocess for Rust file discovery (`check-no-panic` has two call sites — normal scan and `--fixture-mode`):** Windows `find.exe` is a text-search utility, not a filesystem traversal tool. Story spec required `walkdir`. Replaced all `find` subprocess calls (`Command::new("find")`) with in-process `walkdir` traversal via shared `collect_rust_files()` helper in `main.rs`. Added `walkdir = "2"` to `xtask/Cargo.toml`. Gate behavior unchanged. File *discovery* portability restored (six `collect_rust_files()` call sites across five of seven xtask lint gates). File *classification* — the exemption predicates (`is_test_file`, `is_test_class_file`, `is_lint_exempt_file`, and the `scan_for_panics_in_source` fixture guard) — retained POSIX-only forward-slash matching at this stage; that gap was closed in fix-burst-41 (F-P39-HIGH-001).

**MED-003 — fix-burst-34 `## fix-burst-34 re-verification` clause (d) discharge cited a pre-change SHA instead of post-change HEAD:** Demo-recorder re-ran all 8 gates and recorded counts in the evidence-report. Subsequently, the TD-VSDD-091 de-SHA sweep (see below) removed the SHA-pinned gate re-attestation subsection and updated clause (d) to record gate counts by gate name and count value without SHA pins.

**LOW-001 — `is_zero_literal` in `check_client_timeout.rs` stripped type suffix before detecting radix prefix, causing non-zero hex literals to be falsely classified as zero-duration:** Hex literal `0x0f64` (decimal 3940, non-zero) would strip the `f64` suffix to produce `0x0`, which was then interpreted as zero. Fixed by detecting hex/bin/oct radix prefix BEFORE stripping type suffix; non-decimal literals no longer have suffixes stripped. Load-bearing tests: `test_timeout_checker_hex_literal_with_f64_suffix_not_zero` (non-zero hex not flagged — LOAD-BEARING: fails without radix-first fix) and `test_timeout_checker_hex_zero_literal_flagged` (hex zero still detected — negative control). Note: this implementation split `TYPE_SUFFIXES` into `DECIMAL_SUFFIXES` (decimal path, includes f64/f32 suffixes) and per-radix `INT_SUFFIXES` (hex/bin/oct paths, integer suffixes only), so the fix-burst-34 LOW-001 longest-first ordering attestation applies to both `DECIMAL_SUFFIXES` and `INT_SUFFIXES`.

**LOW-002 — Two test doc-comments in `check_no_panic.rs` stated "causes this test to FAIL (returns 1 violation instead of 0)" but each fixture has 2 panic sites:** Each fixture file contains both an `.unwrap()` and an `.expect()` call. Corrected to "2 violations instead of 0". Tests: `test_no_panic_tokio_test_attr_fn_exempt` and `test_no_panic_cfg_test_item_trait_exempt`.

**LOW-003 — Evidence-report cross-reference in `## fix-burst-34 re-verification` referred to "fix-burst-32 gate output re-attestation section" but the referenced subsection was added retroactively under the fix-burst-32 heading at fix-burst-33 HEAD:** Cross-reference corrected to unambiguously identify the subsection's heading text.

**OBS-001 — Process gap: no enforced mechanism to source adversary dispatch KL list from evidence-report; pass-31 OBS-001 closure narrative contradicted the actual diff:** Orchestrator cycle-closing checklist follow-up required.

**Orchestrator-directed TD-VSDD-091 compliance sweep:** Evidence-report.md contained approximately 59 volatile commit SHA and "frozen HEAD" citations (TD-VSDD-091 violation: records must cite behavioral anchors only). Removed all volatile SHA citations from evidence-report.md, including: "Implementation commits" rows, per-fix-burst "Recorded at HEAD" phrases, "Gate output re-attestation at frozen HEAD" subsections, and per-AC "frozen HEAD" pins. Updated Recording Provenance clause (d) to anchor gate counts by gate name and count value, not SHA. Post-sweep grep: 0 SHA citations remaining.

**Test count: 244 xtask tests pass, 5 skipped.** Gate output unchanged: 25 analyzed / 16 exempt / 0 violations per scanning gate; fixture-mode 14/17; 148 codes / 0 collisions.

### Known limitations after fix-burst-35

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 244 xtask tests pass, 5 skipped.

## fix-burst-34 (pass-32 findings)

### xtask check_no_panic / deny_bare_api_key — KL registry restore, `#[cfg(test)]` ItemTrait guard, story spec correction, TYPE_SUFFIXES order, process gap

**HIGH-001 (F-P32-HIGH-001) — KL registry corrupted in fix-burst-33:** `NP-KL-1` and `BAK-KL-1` descriptions in CHANGELOG and evidence-report were replaced with wrong text from a mislabelled dispatch prompt (inverted fix of pass-31 OBS-001). Technical-writer restored correct module-doc descriptions in both artifacts (commit `4c3ea72`):
- NP-KL-1 restored: "Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan"
- BAK-KL-1 restored: "`#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate"

**MED-001 (F-P32-MED-001) — `#[cfg(test)]` on enclosing `ItemTrait` not exempted in either syn gate:** Trait is an item per BC-2.14.003 `{INV-004}`(b) and BC-2.14.004 `{INV-003}`(b); sibling-sweep miss. Implementer added `visit_item_trait` override to both `PanicVisitor` and `TimeoutChecker` (commit `74e5a63`). Load-bearing tests: `test_no_panic_cfg_test_item_trait_exempt` and `test_timeout_checker_cfg_test_item_trait_exempt` (commit `7184a97`).

**MED-002 (F-P32-MED-002) — Story spec stale: still described `check_client_timeout.rs` as `proc_macro2` token-stream scan:** Stale since fix-burst-26 syn AST rewrite. Story-writer amended three sites (§Tasks item 7, §Purity Classification, §Library & Framework Requirements) and bumped story to v1.18 (commit `4fa94af` on factory-artifacts).

**LOW-001 (F-P32-LOW-001) — `is_zero_literal` `TYPE_SUFFIXES` comment claimed "longest first" but array was not sorted longest-first:** Reordered: `"usize"`, `"isize"`, `"u128"`, `"i128"`, then 3-char entries, then `"u8"`, `"i8"` (commit `74e5a63`).

**OBS-001 (F-P32-OBS-001) — Process gap: no mechanism to source adversary dispatch KL list from evidence-report:** Closure narrative for pass-31 OBS-001 contradicted the actual diff. Partially addressed by HIGH-001 restore; orchestrator cycle-closing checklist follow-up required.

### Known limitations after fix-burst-34

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 242 xtask tests pass, 5 skipped.

Note: the `## fix-burst-34 re-verification` section's "Gate output re-attestation" subsection was subsequently removed by the TD-VSDD-091 de-SHA sweep (fix-burst-35). Gate counts (25 analyzed / 16 exempt / 0 violations; 14/17 fixture-mode; 148 codes / 0 collisions) are attested in the evidence-report by gate name and count value without SHA pins.

## fix-burst-33 (pass-31 findings)

### xtask check_no_panic — `#[test]`-family attribute exemption sibling-sweep, path-call form known gap, gate output re-attestation

**MED-001 (F-P31-MED-001) — `PanicVisitor` missing `#[test]`-family attribute exemption — sibling-sweep miss vs `TimeoutChecker`:** `TimeoutChecker` gained last-path-segment `test` guard in fix-burst-27; `PanicVisitor`'s three function visitors (`visit_item_fn`, `visit_impl_item_fn`, `visit_trait_item_fn`) still lacked this guard, missing `#[tokio::test]`, `#[async_std::test]`, `#[rstest]`, and similar framework test attributes. Fixed: all three function visitors gained the last-path-segment `test` guard (implementer commit `3b1ecff`). Load-bearing test: `test_no_panic_tokio_test_attr_fn_exempt` (test-writer commit `3eb68be`) — this test FAILS if the guard is deleted. Routes: implementer + test-writer.

**MED-002 (F-P31-MED-002) — `PanicVisitor` does not detect path-call form of `unwrap`/`expect` (`Result::unwrap(r)`, `Option::expect(o,"m")`):** These parse as `syn::ExprCall` rather than `syn::ExprMethodCall`; without type inference they cannot be distinguished from user-defined `SomeType::unwrap(key)`. Addressed via option (b): `NP-KL-3` minted in module doc (implementer commit `3b1ecff`). Pinning test: `test_no_panic_np_kl3_path_call_form_known_gap` pins zero-finding behavior; any incorrect "fix" adding false positives will break this test.

**LOW-001 (F-P31-LOW-001) — evidence-report Recording Provenance clause (d) not satisfied — fix-burst-30/31/32 had behavioral scanner changes (guard additions) but never re-recorded gate output counts:** Demo-recorder re-ran all 8 gates at HEAD `3eb68be` and recorded actual output (commit `63eee0a`):
- `check-no-panic`: 25 analyzed, 16 exempt, 0 unreadable, 0 violations
- `check-client-timeout`: 25 analyzed, 16 exempt, 0 unreadable, 0 violations
- `deny-bare-api-key`: 25 analyzed, 16 exempt, 0 unreadable, 0 violations
- `check-error-code-registry`: 148 codes validated, 0 collisions
- `deny-anyhow-in-lib`: 25 analyzed, 16 exempt, 0 unreadable, 0 violations
- `deny-description-cache-key`: 25 analyzed, 16 exempt, 0 unreadable, 0 violations
- `check-file-size`: PASSED (2 warnings, 45 files measured, 2 allowlisted)
- `check-no-panic --fixture-mode`: 14/17

**OBS-001 (F-P31-OBS-001) — Dispatch prompt's KL list was mislabelled vs actual code/CHANGELOG/evidence-report:** Process gap — the dispatch prompt's mislabelled KL descriptions were NOT the cause of the artifact content (those descriptions were independently set by the technical-writer for fix-burst-33); the KL table descriptions in fix-burst-33 require correction per F-P32-HIGH-001. Corrected in future dispatches by sourcing KL list from evidence-report.

### Known limitations after fix-burst-33

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind macro token scan — `scan_method_calls_in_tokens` called unconditionally; exemption logic (cfg(test), `# Panics` doc, arm-context) not applied in macro arg scan |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Multi-argument turbofish `<String, u8>` in `syn_macro_has_bc_id` — angle_depth counter |
| NP-KL-3 | `check-no-panic` | Active | Path-call form `Result::unwrap(r)`, `Option::expect(o,"m")` — `ExprCall` not detected; requires type inference unavailable at AST level |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` conditional derives not detected by AST walker — feature-gated dangerous derives evade the gate |

Test count: 240 xtask tests pass, 5 skipped.

## fix-burst-32 (pass-30 findings)

### xtask check_no_panic / check_client_timeout — BC-2.14.003 sibling-sweep, angle-depth mechanism pin, evidence-report table gap

**MED-001 (F-P30-MED-001) — BC-2.14.003 `{INV-004}` not sibling-swept with BC-2.14.004 v1.16 `{INV-003}` fix:** Both BCs are enforced by the same `is_test_file` predicate, but BC-2.14.003 still described only `tests/` directory and `#[cfg(test)]`. Product-owner amended BC-2.14.003 to v1.6 (commit `7c4b5a4`): `{INV-004}` now enumerates all three test-code contexts matching BC-2.14.004 v1.16. No gate behavior change.

**MED-002 (F-P30-MED-002) — `angle_depth` multi-argument turbofish mechanism in `syn_macro_has_bc_id` had zero load-bearing tests:** NP-KL-2 "CONFIRMED RESOLVED" in prior records was overstated. The mechanism's purpose (suppressing commas inside `<String, u8>` style turbofish) was unpin, so deleting `angle_depth` would leave all 236 tests green and silently reintroduce the false-negative. Two load-bearing tests added: `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_exempt` (positive — Exemption-2 fires with multi-arg turbofish condition) and `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` (the mechanism pin — WITHOUT `angle_depth`, this test fails, returning EXEMPT instead of FLAGGED). Also fixed doc comment on `test_no_panic_exemption2_bc_id_with_turbofish_condition` which overclaimed `angle_depth` coverage.

**LOW-001 (F-P30-LOW-001) — evidence-report fix-burst-31 KL table was missing the `CT-KL-4 | RETIRED in fix-burst-26` row:** The CHANGELOG fix-burst-31 table carried the row; the evidence-report table had only 8 rows (CT-KL-4 absent). Fixed in evidence-report (CT-KL-4 row added).

### Known limitations after fix-burst-32

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor; see `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31/32 load-bearing tests) | Turbofish comma miscounting — angle-bracket depth tracking + turbofish-vs-comparison disambiguation both implemented; `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` is the mechanism pin |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |
| NP-KL-3 | `check-no-panic` | **DOCUMENTED in fix-burst-33** | Path-call form `Result::unwrap(r)` — see fix-burst-33 |

Test count: 238 xtask tests pass, 5 skipped.

## fix-burst-31 (pass-29 findings)

### xtask check_no_panic / check_client_timeout / deny_bare_api_key — turbofish-vs-comparison disambiguation, KL namespace canonicalization, defense-in-depth annotations

**HIGH-001 — `syn_macro_has_bc_id` incorrectly increments `angle_depth` for bare comparison `<`:** The NP-KL-2 fix in fix-burst-30 incremented `angle_depth` on ANY `<` punct token. A bare comparison operator (`assert!(a < b, "BC-2.14.003 ...")`) inflated `angle_depth` to 1, hiding the message-argument comma from the top-level scan and causing `syn_macro_has_bc_id` to return `false` even when the message contained a valid BC-ID — a fully-compliant programmer-error guard was flagged as a violation. Fixed: `<` is now treated as a turbofish opener ONLY when preceded by `::` (tokens_vec[i-2] = `:` Joint, tokens_vec[i-1] = `:`). Bare comparison `<` (no `::` prefix) no longer increments `angle_depth`. Import updated from `use proc_macro2::TokenTree` to `use proc_macro2::{Spacing, TokenTree}`. NP-KL-2 fully resolved; module doc updated to `[RESOLVED in fix-burst-30/fix-burst-31]`.

**MED-001 — `syn_macro_has_bc_id` paper-fix closure for NP-KL-2 required additional tests:** ADV-P28-MED-004 NP-KL-2 closure was a paper-fix — `syn_macro_has_bc_id`'s angle-bracket depth fix was untested and its implementation was incorrect (HIGH-001), and the evidence-report attestation table had no row for the Exemption-2 BC-ID detection class. Closed by: (1) HIGH-001 fix above makes the implementation correct; (2) three new pinning tests added: `test_no_panic_exemption2_bc_id_with_turbofish_condition` (Exemption-2 + turbofish condition — EXEMPT), `test_no_panic_exemption2_bc_id_with_comparison_condition` (Exemption-2 + comparison condition — EXEMPT, regression pin for HIGH-001), `test_no_panic_comparison_condition_no_bc_id_flagged` (no BC-ID — FLAGGED, negative control); (3) evidence-report fix-burst-31 re-verification section adds the Exemption-2 BC-ID detection class attestation row; `NP-KL-2` confirmed RESOLVED (both turbofish and comparison regression tests pass). (See fix-burst-32 ADV-P30-MED-002: the multi-arg turbofish angle-depth mechanism was further pinned by load-bearing tests `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_false_negative_guard` and `test_no_panic_exemption2_angle_depth_multi_arg_turbofish_exempt`.)

**MED-002 — BC-2.14.004 `{INV-003}` clause (a) misdescribed test-file exemption perimeter:** BC-2.14.004 `{INV-003}` clause (a) declared `test/` (singular) as exempt when `is_test_file` only checks `/tests/` (directory form), and omitted the `tests.rs` / `_test.rs` / `_tests.rs` filename forms. Closed by: product-owner amended BC-2.14.004 to v1.16 (commit `369758b`) — clause (a) now reads: "source files whose path contains a `/tests/` directory component, or whose filename is exactly `tests.rs`, or whose filename ends with `_test.rs` or `_tests.rs`". No behavioral change to the gate itself.

**MED-003 — Source module docs used generic `KNOWN-LIMITATION N` IDs colliding across modules:** Renamed all Known Limitation IDs in module docs to canonical namespaced form: `KNOWN-LIMITATION 1/2/3` → `CT-KL-1/2/3` in `check_client_timeout`; `KL-macro` → `CT-KL-macro` throughout `check_client_timeout` (module doc, `scan_macro_body_as_ast` doc, inline comment, `analyze_build_chain` doc, and five test-body sites); `CT-KL-4` retirement note added (RETIRED in fix-burst-26; renumbered to avoid reusing retired number); `KNOWN-LIMITATION 5` → `CT-KL-5` (module doc, test doc, two test body sites); `KNOWN-LIMITATION 1/2` → `NP-KL-1/NP-KL-2` in `check_no_panic` module doc, with NP-KL-2 moved to a `## Resolved Limitations` sub-section; `KNOWN-LIMITATION` → `BAK-KL-1` in `deny_bare_api_key` module doc.

**LOW-001 — `visit_expr_macro` cfg-test guards undocumented as defense-in-depth:** Added inline doc comment before the `#[cfg(test)]` guard in `visit_expr_macro` in both `check_client_timeout` and `check_no_panic` explaining that the guard is defense-in-depth: stable Rust cannot express `#[cfg(test)]` as an outer attribute on an expression-position macro call, so the guard is not reachable by compliant code but is retained for future-proofing.

### Known limitations after fix-burst-31

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-4 | `check-client-timeout` | **RETIRED** in fix-burst-26 | Parenthesized/braced base subexpression — eliminated by syn AST visitor |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **CONFIRMED RESOLVED** (fix-burst-30/31 implementation + fix-burst-32 load-bearing tests) | Turbofish comma miscounting — angle-bracket depth tracking + turbofish-vs-comparison disambiguation both implemented |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |

Test count: 236 xtask tests pass, 5 skipped.

## fix-burst-30 (pass-28 findings, code commits `cf25c56`, `715aa72`, BC-2.14.004 v1.15)

### xtask check_client_timeout / check_no_panic / deny_bare_api_key — cfg-test guards, Strategy 2 positive detection, dead arm removal, KL namespace, NP-KL-2 resolution

**ADV-P28-HIGH-001 — `KNOWN-LIMITATION 4` identifier collision resolved:** Module doc heading renamed to `KL-macro`; `scan_macro_body_as_ast` doc updated from `KNOWN-LIMITATION 4` to `KL-macro`; two `assert!` message strings in `test_timeout_scanner_parenthesized_base_subexpr_handled_by_syn` and `test_timeout_scanner_braced_base_subexpr_handled_by_syn` updated from "KNOWN-LIMITATION 4 eliminated" to "formerly KL-4 of the flat-token scanner — eliminated".

**ADV-P28-HIGH-002 — `#[cfg(test)]` guard missing from `visit_expr_macro` and `visit_stmt_macro`:** Added `has_cfg_test_attr` / `syn_has_cfg_test` guards as first statement in `visit_expr_macro` and `visit_stmt_macro` in both `check_client_timeout` and `check_no_panic`; all four previously-unguarded methods now skip macro calls inside `#[cfg(test)]`-gated contexts. Two pinning tests added: `test_timeout_checker_cfg_test_stmt_macro_not_flagged` (`check_client_timeout`) and `test_no_panic_cfg_test_stmt_macro_not_flagged` (`check_no_panic`); the expression-position `visit_expr_macro` guard is defense-in-depth (stable Rust cannot express `#[cfg(test)]` on an expression-position macro — see inline comment).

**ADV-P28-MED-001 — Strategy 2 of `scan_macro_body_as_ast` had no positive-detection test:** Added `test_timeout_checker_strategy2_detects_statement_macro_violation` exercising the `fn __macro_fragment__()` wrapper path; evidence-report attestation row corrected to cite one test per strategy (S1/S2/S3).

**ADV-P28-MED-002 — Three test doc comments referenced deleted `scan_macro_tokens_for_timeout_violations`:** Updated to reference `scan_macro_body_as_ast` Strategy 1 / Strategy 3 as appropriate.

**ADV-P28-MED-003 — Dead `"builder"` arm in `visit_expr_call` Pattern-A UFCS qself branch:** Narrowed guard from `matches!(last_method, "default" | "new" | "builder")` to `matches!(last_method, "default" | "new")`; inline doc corrected (Pattern-A does not handle `<reqwest::Client>::builder()`; that is Pattern B via `analyze_build_chain`).

**ADV-P28-MED-004 — `check_no_panic` and `deny_bare_api_key` KL disclosures absent from story records; NP-KL-2 sound fix implemented:** `KNOWN-LIMITATION 2` in `check_no_panic` (turbofish comma miscounting in `syn_macro_has_bc_id`) had a documented sound fix not yet applied — implemented angle-bracket depth tracking (`u32` with `saturating_sub`) in `syn_macro_has_bc_id`; NP-KL-2 is now resolved.

**ADV-P28-LOW-001 — Three doc sites in `check_client_timeout` enumerated only `<reqwest::Client as Default>::default()` UFCS form:** Expanded to include `<reqwest::Client>::new()`, `<reqwest::ClientBuilder>::new().build()`, and `<reqwest::Client>::builder().build()`.

**ADV-P28-LOW-002 — `KL-macro` was the only known limitation with no pinning test:** Added `test_timeout_checker_unparseable_macro_body_known_limitation` asserting zero findings for an opaque macro body failing all three strategies.

**ADV-P28-LOW-003 — Correction to fix-burst-29 `F-P27-MED-002` attribution:** (See fix-burst-29 section below — "Six" corrected to "Four".)

**ADV-P28-LOW-004 — BC-2.14.004 `{INV-003}` test-code exemption perimeter:** BC-2.14.004 `{INV-003}` expanded to enumerate full test-code exemption perimeter; handled by product-owner (BC-2.14.004 v1.15).

### Known limitations after fix-burst-30

| ID | Gate | Status | Description |
|----|------|--------|-------------|
| CT-KL-1 | `check-client-timeout` | Active (conservative FP) | Bare `Client::new()` via `use` import — flagged conservatively; workaround: qualify with owning-crate path |
| CT-KL-2 | `check-client-timeout` | Active | Split-statement builder chains |
| CT-KL-3 | `check-client-timeout` | Active | Constant-valued zero timeout |
| CT-KL-5 | `check-client-timeout` | Active | Module-alias re-export false negative |
| CT-KL-macro | `check-client-timeout` | Active | Macro bodies failing all three parse strategies (opaque bodies skip, not flag) |
| NP-KL-1 | `check-no-panic` | Active | Exemption-blind flat-token macro scan (conservative FP direction) |
| NP-KL-2 | `check-no-panic` | **RESOLVED in fix-burst-30** | Turbofish comma miscounting — angle-bracket depth tracking implemented |
| BAK-KL-1 | `deny-bare-api-key` | Active | `#[cfg_attr(feature=…, derive(…))]` false negative |

Note: CT-KL-4 was retired (parenthesized/braced base subexpression eliminated by syn AST visitor in fix-burst-26; renumbered in fix-burst-28/29 → now CT-KL-macro for the opaque-macro limitation).

Test count: 233 xtask tests pass, 5 skipped.

## fix-burst-29 (pass-27 findings, code commits `a98d8ae`, `c0d6783`)

### xtask check_client_timeout — UFCS extension, dead-code removal, KL corrections

**F-P27-MED-002 — UFCS qself extended to `new` and `builder`:** `visit_expr_call` qself branch and `analyze_build_chain` UFCS branch both previously guarded on `last_method == "default"` only. Extended to `matches!(last_method, "default" | "new" | "builder")`, enabling detection of `<reqwest::Client>::new()`, `<reqwest::Client>::builder().build()`, and `<reqwest::ClientBuilder>::new().build()` without `.timeout()`. Four new pinning tests cover qualified and clean forms.

**F-P27-MED-004 — Strategy 3 (dead code) removed:** `scan_macro_body_as_ast` previously described four progressive parse strategies; Strategy 3 (`syn::parse2::<syn::Expr>`) was logically dead because any token stream it accepts is also accepted by Strategy 2's `fn __macro_fragment__()` wrapper. Strategy 3 removed; all four documentation sites updated to say "three strategies."

**F-P27-HIGH-001 + F-P27-MED-003 — KL-1 module doc corrected:** KNOWN-LIMITATION 1 in the module doc now explicitly labels bare-name detection as a conservative false POSITIVE (not false negative). The workaround corrected from "use `reqwest::Client::new()`" (unconditional violation — wrong) to "qualify with owning-crate path (e.g., `other_sdk::Client::new()`)".

**F-P27-MED-008 — KNOWN-LIMITATION 5 added:** Documents the module-alias re-export false negative: `http::Client::new()` (where `http` re-exports `reqwest::Client`) is suppressed because the gate classifies non-reqwest head segments as non-reqwest. Pinned by `test_timeout_checker_module_alias_false_negative_known_limitation`.

**F-P27-HIGH-002 + F-P27-MED-001 — Pattern-A UFCS test added:** `test_timeout_checker_detects_client_ufcs_default_qualified` pins the `visit_expr_call` qself branch for `<reqwest::Client as Default>::default()`; `test_timeout_checker_ufcs_non_reqwest_client_as_default_clean` pins the non-reqwest negative.

**F-P27-LOW-001 — blocking arm doc fixed:** Module doc `# Scanning rules` previously attributed bare `blocking::` detection to "the path-relative guard"; now correctly names "the `blocking`-head segment arm in `classify_client_new` / `classify_builder_constructor`."

**F-P27-LOW-002 — stale KL-4 refs updated:** `analyze_build_chain` doc updated from "eliminating KNOWN-LIMITATION 4" to "parenthesized/braced base subexpression (formerly KL-4 of the flat-token scanner)". Tests renamed: `test_timeout_scanner_parenthesized_base_subexpr_known_limitation` → `..._handled_by_syn`; `test_timeout_scanner_braced_base_subexpr_known_limitation` → `..._handled_by_syn`.

**F-P27-OBS-001 — check_error_code_registry doc fixed:** Module doc now says "every code declared in the canonical registry table (one code per leading `| E-` table cell)" instead of overstating coverage.

### Known limitations after fix-burst-29

| ID | Description | Status |
|----|-------------|--------|
| KL-1 | Bare `Client::new()` without a qualifying module path — conservative **false positive**: gate cannot distinguish reqwest vs other SDK clients, flags conservatively. Workaround: qualify with owning-crate path (e.g., `other_sdk::Client::new()`) | Preserved (now false-positive, per-syn-rewrite clarification) |
| KL-2 | Split-statement builder chains (builder on line 1, `.build()` on line N via variable) | Preserved |
| KL-3 | `.timeout(SOME_CONST_ZERO)` — constant-valued zero not detected | Preserved |
| KL-4/macro | Macro bodies failing all three parse strategies are skipped | Preserved (renumbered from 4 to KL-macro, three strategies after Strategy-3 removal) |
| KL-5 | Module-alias re-export (`http::Client::new()` where `http` re-exports reqwest) — false negative; head segment treated as non-reqwest | New |

Test count: 229 passing (xtask), 5 skipped.

## fix-burst-28 (pass-26 findings, commit `2d2f6ece`)

### xtask check_client_timeout — recursive macro AST, ClientBuilder UFCS, doc hygiene

**F-P26-HIGH-001 + F-P26-MED-001 — Recursive macro AST scanner:** Replaced the flat-token `scan_macro_tokens_for_timeout_violations` with `scan_macro_body_as_ast`, which uses four progressive parse strategies to obtain a `syn` AST and re-run `TimeoutChecker` recursively on macro body tokens: (1) `syn::parse2::<syn::File>` (direct parse — works for `thread_local!`), (2) `fn __macro_fragment__() { … }` wrapper parse (works for statement/expression bodies), (3) `syn::parse2::<syn::Expr>` (bare expression), (4) `extract_initializer_exprs_from_tokens` (splits at top-level `;`, extracts the initializer expression — works for `lazy_static!`-style `static ref NAME: TYPE = EXPR;` bodies). Macro bodies that fail all four strategies are skipped rather than flagged conservatively. The recursive approach eliminates the depth-blind false-negative (any `.timeout` token in a flat stream had suppressed violations) and the false-positive for `reqwest::Client::builder()` (previously in Pattern A arm, now correctly classified as Pattern B via chain tracing).

**F-P26-MED-002 — Module-level docs updated:** `//!` module doc, `run()`, and `scan_for_timeout_violations_in_source` now mention `Client::default()` / `ClientBuilder::default()`, recursive macro AST scanning, and UFCS qself handling.

**F-P26-MED-003 — KNOWN-LIMITATION 4 added:** Documents that macro bodies failing all four parse strategies are skipped.

**F-P26-MED-004 — UFCS `<reqwest::ClientBuilder as Default>::default()` detection:** `analyze_build_chain` Call branch extended — when path segments are `["Default", "default"]` and qself type is `reqwest::ClientBuilder` or bare `ClientBuilder`, treats as a builder entry point.

**F-P26-MED-005 — KNOWN-LIMITATION 1 workaround corrected:** Removed nonexistent "lint-exempt allowlist" workaround claim; the correct escape is to use the fully-qualified form `reqwest::Client::new()`.

**F-P26-LOW-001 — `visit_trait_item_fn` added:** `TimeoutChecker` now has the same `#[cfg(test)]` / `#[test]` guard for trait default methods as `PanicVisitor`.

### Known limitations after fix-burst-28

| ID | Description | Status |
|----|-------------|--------|
| KL-1 | Bare `Client::new()` without a qualifying module path — **conservative false positive**: the gate cannot determine whether `Client` refers to `reqwest::Client` or another SDK's client, so it flags conservatively. (Qualifying with a non-reqwest head segment suppresses the alarm.) Workaround: qualify with owning-crate path (e.g., `other_sdk::Client::new()`); reqwest-qualified forms are unconditional violations. | Conservative false positive |
| KL-2 | Split-statement builder chains (builder on line 1, `.build()` on line N via variable) | Preserved |
| KL-3 | `.timeout(SOME_CONST_ZERO)` — constant-valued zero not detected | Preserved |
| KL-macro | Macro bodies failing all four parse strategies (not valid as item sequence, wrapped-fn, expression, or initializer extraction) are skipped | Preserved (narrowed scope from fix-burst-27) |

Test count: 222 passing (xtask), 5 skipped (pre-existing ignored tests requiring live API keys).

## fix-burst-27 (pass-25 findings, commit `356ee3b`)

### xtask check_client_timeout — macro scanning and Default constructor

**F-P25-HIGH-001 — macro token stream scanning:** Added `visit_expr_macro`, `visit_stmt_macro`, and `visit_item_macro` overrides to `TimeoutChecker`. Each override delegates to `scan_macro_tokens_for_timeout_violations`, a flat-token scanner that detects the following qualified `reqwest::*` forms inside macro invocation bodies: `reqwest::Client::new`, `reqwest::Client::builder`, `reqwest::Client::default`, `reqwest::ClientBuilder::new`, `reqwest::ClientBuilder::default`, `reqwest::blocking::Client::new`, `reqwest::blocking::Client::builder`, `reqwest::blocking::Client::default`, `reqwest::blocking::ClientBuilder::new`, and `reqwest::blocking::ClientBuilder::default`. Reqwest client constructions inside `thread_local!{}`, `lazy_static!{}`, and arbitrary macro bodies are now detected. Three new pinning tests cover this path. Note: this flat-token scanner is replaced in fix-burst-28 by `scan_macro_body_as_ast`, a recursive AST approach that reuses `TimeoutChecker` on the macro body tokens — detection is performed via `classify_client_new` and `classify_builder_constructor` rather than flat-token matching.

**F-P25-HIGH-002 — `Client::default()` / `ClientBuilder::default()` unclassified:** `classify_client_new` extended to match `Client::default` in addition to `Client::new` and `Client::builder`; `classify_builder_constructor` extended to include `ClientBuilder::default`. The UFCS qself form `<reqwest::Client as Default>::default()` is handled conservatively in the `ExprCall` visitor path. Four new pinning tests cover qualified and bare forms.

**F-P25-MED-001 — stale doc comments:** 16 doc-comment sites in `check_client_timeout` and `tests` referencing deleted symbols (`scan_reqwest_blocking_pattern`, `preceded_by_non_reqwest`, `has_build_without_timeout`, flat-index notation, Pattern 1/2/3/4 numbering) updated to reference current symbols and Pattern A/B terminology.

**F-P25-LOW-001 — `has_cfg_test_attr` divergence rationale:** Divergence-rationale doc added explaining intentional separation from `check_no_panic::syn_has_cfg_test`.

**F-P25-LOW-002 — `map_build_failure` doc:** Doc comment updated to cite `sanitize_error_message` for the 200-char cap.

**F-P25-LOW-003 — `#[tokio::test]` not recognized:** Test-attribute detection changed from `is_ident("test")` to last-path-segment matching, covering `#[tokio::test]`, `#[async_std::test]`, `#[rstest]`, etc.

**F-P25-OBS-001 — monotonic-OR in `analyze_build_chain`:** Fixed — `has_valid_timeout` now reflects the last `.timeout()` call rather than any previous valid call, matching reqwest's own last-wins semantics.

### Known limitations after fix-burst-27

| ID | Description | Status |
|----|-------------|--------|
| KL-1 | Bare `Client::new()` without a qualifying module path — **conservative false positive**: the gate cannot determine whether `Client` refers to `reqwest::Client` or another SDK's client, so it flags conservatively. (Qualifying with a non-reqwest head segment suppresses the alarm.) | Conservative false positive |
| KL-2 | Split-statement builder chains (builder on line 1, `.build()` on line N) | Preserved |
| KL-3 | `.timeout(SOME_CONST_ZERO)` — constant-valued zero not detected (inline `Duration::ZERO` now caught by OBS-001 fix) | Preserved |
| KL-macro | Macro token stream scanning is best-effort flat-token; deeply nested or aliased macro constructions may evade detection | New |

Test count: 309 passing, 7 skipped (pre-existing ignored tests requiring live API keys).

### Fixed (fix-burst-26)

- **F-P24-HIGH-001** (`xtask/src/check_client_timeout.rs`) — Head-anchored blocking detection: `blocking::Client::new()` (use-imported form where `blocking` is the path head) now flagged conservatively; `other_sdk::blocking::Client::new()` still suppressed (head `other_sdk` is non-reqwest). Implemented via `preceded_by_non_reqwest_qualifier` helper (point-patch commit `5d50f79`), then structurally eliminated by the syn rewrite below.
- **F-P24-MED-002** (`xtask/src/check_client_timeout.rs`) — Module doc `# Scanning rules` and `scan_flat_for_timeout_violations` Patterns detected list updated to include blocking patterns.
- **F-P24-MED-003** (`xtask/src/check_client_timeout.rs`) — Updated `scan_flat_for_timeout_violations` doc summary paragraph from pre-fix-burst-24 suppression rule to current head-anchored rule.
- **F-P24-LOW-004** (`xtask/src/check_client_timeout.rs`) — Corrected blocking test doc comments: `scan_reqwest_blocking_pattern` sibling helper, not "Pattern 1 extension".
- **F-P24-LOW-005** (`crates/pregolya-core/src/http.rs`) — `sanitize_error_message` now uses char-count cap (`chars().take(200)`) to match spec BC-2.14.004 {EC-006}; added multibyte pinning test.
- **Structural refactor** (`xtask/src/check_client_timeout.rs`) — Rewrote entire timeout gate from proc_macro2 flat-token scanner to `syn::visit::Visit`-based `TimeoutChecker` AST visitor (commit `ebea3e1`). Coordinator-directed structural intervention after 7 passes finding new syntactic forms in the manual token scanner. KNOWN-LIMITATION 4 (parenthesized/braced base subexpression GroupEnd false-negative) is **eliminated** — its tests inverted from `is_empty()` to detection assertions. KL-1 (bare name via `use` import) and KL-3 (constant-valued zero timeout) preserved. Net: −499 lines.

### Fixed (fix-burst-25)

- **F-P23-HIGH-001** (`xtask/src/check_client_timeout.rs`) — Added `scan_reqwest_blocking_pattern` helper to detect `reqwest::blocking::Client::new()`, `reqwest::blocking::ClientBuilder::new().build()`, and `reqwest::blocking::Client::builder().build()` without `.timeout()`; previously evaded detection via `preceded_by_non_reqwest` treating `blocking` as non-reqwest. Added four pinning tests (three positive, one negative for `other_sdk::blocking`).
- **F-P23-MED-005** (`xtask/src/check_client_timeout.rs`) — Added three qualifier pinning tests for `self::Client::new()`, `super::ClientBuilder::new().build()`, and `Self::Client::builder().build()`; confirms `crate|self|super|Self` exclusion flags all four qualifier forms.
- **F-P23-LOW-006** (`xtask/src/check_client_timeout.rs`) — Updated KNOWN-LIMITATION 4 paragraph to name both `ParenGroupEnd` and `BraceGroupEnd` terminators and cite both pinning tests.
- **F-P23-LOW-007** (`xtask/src/check_client_timeout.rs`) — Rewrote Pattern 4 comment to accurately describe de-duplication (not catching); added matching `preceded_by_reqwest` de-dup guard to Patterns 2 and 3 for symmetry.

### Fixed (fix-burst-24)

- **F-P22-MED-001** (`CHANGELOG.md`) — Added missing fix-burst-23 section documenting F-P21-MED-001, F-P21-MED-002, and F-P21-LOW-001; reordered `### Fixed` sections to descending fix-burst order.
- **F-P22-MED-002** (`docs/demo-evidence/S-1.02/evidence-report.md`) — Corrected fix-burst-23 attestation paragraph wording; accurately describes KNOWN-LIMITATION 4 (`ParenGroupEnd` depth-0 break) and Pattern 3 label.
- **F-P22-MED-003** (`xtask/src/check_client_timeout.rs`) — Updated KNOWN-LIMITATION 1 scope statement to cover Patterns 2, 3, and 4 (was previously scoped to Pattern 2 only).
- **F-P22-MED-004** (`xtask/src/check_client_timeout.rs`) — Extended `preceded_by_non_reqwest` guard in Patterns 2, 3, and 4 to exclude `"crate" | "self" | "super" | "Self"` from suppression; path-relative qualifiers now treated as ambiguous and flagged conservatively. Added three `crate::`-qualifier pinning tests.
- **F-P22-MED-005** (`xtask/src/check_no_panic.rs`) — Renumbered KNOWN-LIMITATION labels: KL-1 (`scan_method_calls_in_tokens` exemption-blind macro-arg scan) and KL-2 (`syn_macro_has_bc_id` turbofish comma counting); added `# Known Limitations` module-doc index.
- **F-P22-LOW-006** (`xtask/src/check_client_timeout.rs`) — Added `test_timeout_scanner_braced_base_subexpr_known_limitation` pinning test for KNOWN-LIMITATION 4 braced form.
- **F-P22-LOW-007** (`xtask/src/check_client_timeout.rs`) — Added defense-in-depth comment to Pattern 4's `preceded_by_reqwest` guard; guard is currently unreachable but intentional as future-proofing.

### Fixed (fix-burst-23, 2026-09-22)
- F-P21-MED-001: Pattern 3 (`ClientBuilder::new()`) gained a `preceded_by_non_reqwest` qualifier guard matching Patterns 2 and 4; suppresses false positives for non-reqwest types named `ClientBuilder`.
- F-P21-MED-002: Added KNOWN-LIMITATION 4 to `has_build_without_timeout` documenting the parenthesized/braced base subexpression false negative (`(reqwest::ClientBuilder::new()).build()` is not flagged); added pinning test.
- F-P21-LOW-001: Removed dead `_end: usize` parameter from `has_build_without_timeout`; all 5 call sites updated (TD-VSDD-059).

### Fixed (fix-burst-22, 2026-09-22)
- F-P20-HIGH-001: `find_chain_end` bounded forward scan to base-call ident path; function-reference base call no longer skips following statements
- F-P20-HIGH-002: `has_build_without_timeout` `*GroupEnd` at depth-0 now terminates scan (`break`) instead of clamping (`saturating_sub`); inner builder no longer claims outer chain's `.build()`
- F-P20-MED-001: doc comments reconciled; added 3 regression tests

### Fixed (fix-burst-21, 2026-09-22)
- F-P19-HIGH-001: `has_build_without_timeout` added depth guard (brace/bracket/paren depth-0 check) on `.timeout()` crediting; nested inner builder's `.timeout()` no longer credited to outer chain; added 3 regression tests

### Fixed (fix-burst-20, 2026-09-22)
- F-P18-HIGH-001: has_build_without_timeout now terminates at first depth-0 .build() — eliminates cross-chain verdict leakage where a compliant chain's timeout credited a violating chain
- F-P18-MED-002: ParenGroupEnd variant added to FlatToken; paren_depth counter prevents vec!(x;n) semicolons from terminating the chain scan

### Fixed (fix-burst-19, 2026-09-22)
- F-P17-MED-001/MED-002: evidence-report.md AC-017 counts updated to 14/17, 14th violation class added, validity criterion extended with fixture-directory clause (c)
- F-P17-MED-003: BracketGroup/BracketGroupEnd depth tracking in has_build_without_timeout — vec![..;n] repeat `;` no longer terminates chain scan
- F-P17-MED-004: Leading `::` skip before post-`for` ident collection in check_impl_deref and check_impl_display_in_tokens
- F-P17-LOW-005: Exempt-direction tests for assert_eq!/assert_ne!/assert_matches! 3-arg form with BC-ID in message
- F-P17-LOW-006: CREDENTIAL_FIXTURE_COUNT doc comment ratio updated to 14/17
- F-P17-OBS-007: KNOWN-LIMITATION added to syn_macro_has_bc_id for turbofish comma counting

### Fixed (fix-burst-18, 2026-09-22)
- F-P16-MED-001: `syn_macro_has_bc_id` made arity-aware — `assert_eq!`/`assert_ne!`/`assert_matches!` now require BC-ID in message (3rd argument), not comparand; new violation fixture and test added
- F-P16-MED-002: `has_build_without_timeout` brace-depth tracking via `BraceGroupEnd` variant prevents brace-group arguments from terminating the scan before `.build()` is reached
- F-P16-MED-005: `test_BC_2_14_003_programmer_error_guards_compliant` assertion message corrected — `panic!()` removed as an acceptable guard form (it is unconditionally flagged with no Exemption-2 path)
- F-P16-LOW-006: `check_impl_deref` and `check_impl_display_in_tokens` post-`for` ident-collection loops stop at `where` clause boundary; two regression tests added

### Fixed (fix-burst-17, 2026-09-22)

- **F-P15-M01** — Separated `panic!` from the Exemption-2 group in `pub fn run()` doc (`check_no_panic.rs`): `panic!`/`todo!`/`unimplemented!` are now documented as unconditionally flagged; the Exemption-2 qualifier "(without `# Panics` doc + BC-ID exemption)" now applies only to the assert-family; `assert_matches!` added to the assert-family list in the `run()` doc.
- **F-P15-M02** — Complete sweep of retired scanner internals in `tests.rs`: converted all 8 present-tense claims about former `FLAGGED_PANIC_MACROS` handler, `in_match_arm_position` check, and `Delimiter::Parenthesis` guard to past-tense provenance framing ("the former handler checked/used/saw…"); deleted the self-contradictory "current scanner only checks Delimiter::Parenthesis" fragment from the `test_BC_2_14_003_fixture_mode_in_process_violation_found` assertion message.
- **F-P15-M03** — Fixed mis-anchor in `test_BC_2_14_006_error_code_and_format_table` comment (`credentials.rs`): replaced wrong `{EC-005}` clause with `{EC-004}/{PC-004}` (empty-string input returns Err); narrowed claim from "empty string and whitespace-only" to "empty-string input only"; added cross-reference to whitespace-only test for `{EC-006}`.
- **F-P15-M04** — Added `BC-2.14.005 {INV-001} DI-010` citation alongside existing `{EC-006}` and `CWE-209` in `map_build_failure` and `sanitize_error_message` doc comments (`http.rs`); `{INV-001}` is the governing invariant for credential sanitization behavior.
- **F-P15-L01** — Added `assert_matches!` to the "## Exempt patterns" Exemption-2 bullet in the module doc (`check_no_panic.rs`); extended the module summary line to enumerate all flagged panic-family constructs including `todo!`, `unimplemented!`, and conditional `unreachable!()` patterns.
- **F-P15-L02** — Fixed `scan_for_anyhow_in_source` doc predicate citation in `main.rs`: changed "`is_test_file`" to "`is_lint_exempt_file`" to match the actual code path.

### Fixed (fix-burst-16, 2026-09-22)

- **F-P14-M07** — Split `"panic"` out of the Exemption-2 guard arm in `handle_macro_invocation` (`check_no_panic.rs`): `panic!()` is now unconditionally flagged via its own dedicated arm (no `fn_has_panics_doc && syn_macro_has_bc_id` guard); Exemption-2 guard now applies only to assert-family macros (`assert!`, `assert_eq!`, `assert_ne!`, `assert_matches!`). Updated `handle_macro_invocation` doc, `scan_for_panics_in_source` doc, and module-level "## Flagged patterns" doc to reflect the behavioral change.
- **F-P14-L01** — Added `todo!()`, `unimplemented!()`, and `assert_matches!` to the "## Flagged patterns" module doc in `check_no_panic.rs`; clarified `panic!()` as unconditionally flagged with no exemption.
- **F-P14-M01** — Changed present-tense scanner-behavior claims to past-tense provenance framing in two assertion messages in `tests.rs`: "checks…fires" → "checked…fired" in `test_BC_2_14_003_std_qualified_unreachable_in_named_arm_not_flagged`; "fires" → "fired" in `test_BC_2_14_003_core_qualified_unreachable_in_named_arm_not_flagged`.
- **F-P14-M02** — Extended `is_lint_exempt_file` "Used by:" list in `main.rs` to include `deny_bare_api_key` and `deny_description_cache_key`.
- **F-P14-M03** — Removed "or examples" / "/ examples" from three doc sites: `scan_for_anyhow_in_source` doc in `main.rs`, `scan_for_description_cache_key_in_source` doc in `main.rs`, and `test_description_cache_key_scanner_skips_test_files` doc in `tests.rs`.
- **F-P14-M04** — Replaced phantom `SEC-004` anchor with `BC-2.14.005 {PC-004}/{INV-003}` in `impl_body_has_target_str` doc (`deny_bare_api_key.rs`); replaced all `SEC-007` occurrences in `http.rs` with `BC-2.14.004 {EC-006}` (retaining `CWE-209`): `map_build_failure` doc, `sanitize_error_message` doc, test section header, and four test doc comments.
- **F-P14-M05** — Replaced "struct-literal" with "`from_raw_for_tests`" in three test doc comments in `credentials.rs`: `test_BC_2_14_005_openai_debug_emits_redacted_sentinel`, `test_BC_2_14_005_anthropic_debug_emits_redacted_sentinel`, and `test_BC_2_14_005_debug_does_not_leak_key_material`.
- **F-P14-L02** — Removed `check-no-panic` from the timeout test parenthetical in `test_BC_2_14_004_timeout_error_shape` (`http.rs`); comment now reads "(check-client-timeout)" only.
- **F-P14-L03** — Replaced stale "Table: (constructor, input, must_be_err) / Only empty string is a guaranteed failure ... may be added by the implementer." comment in `test_BC_2_14_006_error_code_and_format_table` with accurate comment describing direct assertions over `OpenAiApiKey::new("")` / `AnthropicApiKey::new("")`.

### Fixed (fix-burst-15, 2026-09-22)

- **F-P13-M02** — Extended `test_check_post_exemption_vacuity_gate_names_are_distinct` to include `"check-file-size"` in the gates array (six gates, not five); updated doc comment accordingly.
- **F-P13-M02** — Extended `test_check_post_exemption_vacuity_wiring_present_in_all_scanners` to assert `check_post_exemption_vacuity("check-file-size"` is present in `main.rs`; updated doc comment to "six gates across four source files".
- **F-P13-M03** — Replaced permanently-green `let _ = findings;` in `test_timeout_scanner_split_statement_false_negative_known_limitation` with a load-bearing `assert!(findings.is_empty(), "KNOWN-LIMITATION 2: …")` so the test will fail if cross-statement tracking is ever implemented.
- **F-P13-M04** — Removed stale reference to `assert!` in `check_file_size` from `check_no_panic::run()` scan-root comment; replaced with accurate statement that xtask production code contains no panic-family constructs and surfaces failures via stderr + non-zero exit.
- **F-P13-OBS01** — Added cross-reference paragraphs to `is_test_file` and `is_test_class_file` doc comments in `main.rs` making the intentional predicate duplication explicit and documenting the expected divergence rationale.

### Fixed (fix-burst-14, 2026-09-22)

- **F-P12-M01** — Removed duplicate test `test_bc_2_14_003_panic_family_detected_in_token_stream` from `xtask/src/check_no_panic.rs`; it was byte-identical to `test_bc_2_14_003_panic_in_macro_arg_detected_by_panic_family`.
- **F-P12-M02** — Rewrote `scan_method_calls_in_tokens` doc comment to accurately describe both call paths (primary syn path via `handle_macro_invocation`, and syn parse-failure fallback) and state that exemption logic is not applied on either path.
- **F-P12-M03** — Fixed test doc in `test_bc_2_14_003_panic_in_macro_arg_detected_by_panic_family`: replaced incorrect label "KNOWN-LIMITATION 4" with the correct label "Residual detection gap" for the token-pasting gap paragraph.
- **F-P12-M04** — Fixed three dangling anchors in `crates/pregolya-core/src/http.rs` doc comments: replaced phantom `make_build_error_for_test` coupling description with the actual compile-time coupling mechanism; replaced adversary finding ID `F-C` with BC clause `{EC-006}`; replaced non-existent `POL-34` with `SID-1`.
- **F-P12-M05** — Fixed incorrect `AC-010` references in `crates/pregolya-core/src/credentials.rs`: `test_BC_2_14_005_openai_expose_secret_returns_inner_value` and `test_BC_2_14_005_anthropic_expose_secret_returns_inner_value` trace to `AC-009` (the only-intentional-exposure-path AC), not `AC-010` (the structural gate AC).
- **F-P12-M06** — Fixed `{INV-004}` → `{INV-001}` in `test_BC_2_14_004_timeout_error_shape` doc: INV-001 is the outbound connection timeout invariant that DI-009 covers; INV-004 was wrong.
- **F-P12-L01** — Fixed `xtask/tests/fixtures/violations/violation_todo_stub.rs`: corrected header comment to say "detects `todo!()`" only (removed false claim of `unimplemented!()` coverage); renamed `unimplemented_function` to `todo_stub_function` to remove the false implication.
- **F-P12-L03** — Fixed self-contradicting Pattern-2 inline comment in `xtask/src/check_client_timeout.rs`: removed the false claim that Pattern 2 "only detects inline-qualified calls"; replaced with accurate description that bare unqualified `Client::new()` calls are flagged conservatively per KNOWN-LIMITATION 1.
- **F-P12-L05** — Replaced `assert!` panic in `check_file_size()` (`xtask/src/main.rs`) with `check_post_exemption_vacuity` structured error path; vacuity condition now produces stderr message + exit code 1 (not exit code 101 from panic).
