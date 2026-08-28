#!/usr/bin/env bash
# pre-commit-validators.sh — factory-artifacts pre-commit gate runner
#
# PURPOSE
# ───────
# Runs all BLOCKING validators before any factory-artifacts commit.
# Called by the project pre-commit hook when a commit targets the
# factory-artifacts branch.
#
# BLOCKING VALIDATORS (exit 1 on failure)
# ────────────────────────────────────────
# Blocking validators prevent factory-artifacts commits when any FAIL fires.
# Validators marked (CLEAN) have zero current FAIL findings.
# Validators marked (FAILING) have pre-existing violations tracked to closure
# via in-flight fix-bursts; they block commits until those violations are cleared.
#
#   verify-no-version-pins.sh              — (FAILING) pinned doc-id vN.N versions block.
#       fix-burst-287 extended PIN_RE to cover compound index names (VP-INDEX, BC-INDEX,
#       ARCH-INDEX, L2-INDEX, STORY-INDEX, EVAL-INDEX). 7 new FAILs surfaced: VP-INDEX v1.2
#       and v1.5 pins in BC body normative sections (VP Anchors + Traceability tables) in
#       BC-2.05.007, BC-2.10.005, BC-2.18.004, BC-2.19.005, BC-2.21.003, BC-2.22.001,
#       BC-2.23.005. Routing: product-owner de-pin sweep in BC VP-Anchors/Traceability sections.
#   verify-adr-decision-refs.sh            — (CLEAN) missing ADR decision refs block
#   records-lint.sh                        — (CLEAN) line-cite and version-pin (D-50) in new content block
#   verify-changelog-date-monotonicity.sh  — (CLEAN) non-monotone changelog dates block
#   verify-changelog-date-validity.sh      — (CLEAN) gate #28 Rules 4+5: future-date ceiling and
#       supplement timestamp-currency (burst-283/DEFER-002). Fires when any changelog entry
#       date exceeds today, or when a prd-supplements/*.md timestamp: does not match its
#       newest changelog entry date.
#   verify-enum-variant-casing.sh          — (CLEAN) non-canonical enum casing block
#   verify-signature-canon.sh             — (FAILING) adjudicated type-signature canon
#       D-42 PregolyaError ctor | D-43 DynTool | D-45/D-48 as_retriever receiver
#       Pre-existing violations: S1b (capabilities-p1-p2.md as_retriever(&self)),
#       S2 (capabilities-p1-p2.md VectorStoreRetriever<), S4 (4 files Arc<dyn Tool>),
#       S5 (80 files PregolyaError full-form literals). In-flight: architect fix-burst
#       closes S1/S2/S3; product-owner fix-burst closes S4/S5. Wire date: 2026-07-28.
#   verify-error-notation-canon.sh        — (FAILING) ADR-010 v1.17 error-construction notation.
#       fix-burst-287: (1) CLASS1_VIOLATION routing guide corrected (was "use ::new()", now
#       "add '..' rest pattern; struct-literal is canonical"). (2) NEW_FORM_VIOLATION class
#       added — PregolyaError::new() is FORBIDDEN per ADR-010 v1.17; canonical form is
#       PregolyaError { code: "E-XXX", .. }. (3) 48 violations across 23 files surfaced;
#       all are NEW_FORM_VIOLATION from prior burst conversions that used ::new(). Routing:
#       product-owner/architect sweep in BC bodies and ADR bodies to revert ::new() back to
#       struct-literal { code: "E-XXX", .. } form. Wire date: 2026-07-29.
#       Note: ADR-010 itself has 1 pending fix (Mechanical Discriminator §Step 2 routing
#       text); spec-steward to update "must use PregolyaError::new(...)" → struct-literal.
#   verify-form-a-changelog-direction.sh   — (CLEAN) BC Form-A changelog direction + VERSION-MATCH.
#       Promoted from advisory at fix-burst-283. Baseline: PASS=199 WARN=7 FAIL=0 BC_UNVERIFIED=0.
#       WARN=7 are co-existence advisory (both-forms files) — non-blocking. Fires on FAIL or
#       BC_UNVERIFIED > 0. Prior advisory condition (6 BCs lacking Form-A) was resolved before
#       promotion.
#   verify-arch-anchor-resolution.sh       — (CLEAN) BC body architecture citation path resolution.
#       Promoted from advisory at fix-burst-283. Baseline: PASS=129 WARN=0 FAIL=0.
#       Prior advisory conditions (16 expected FAILs: 12 nonexistent paths + 4 wildcard citations)
#       fully resolved before promotion. Any new unresolved architecture/ citation in a BC body
#       blocks commit.
#   verify-module-canonicality.sh          — (CLEAN) Module-cell canonicality + 4-way set equality.
#       Promoted from advisory at fix-burst-283. Baseline: PASS=8 WARN=0 FAIL=0.
#       Prior advisory condition (set-diff mismatches in purity-boundary-map and
#       verification-coverage-matrix) was resolved before promotion.
#   verify-bc-frontmatter-schema.sh        — (CLEAN) BC frontmatter schema (bc_id, changelog,
#       red_gate_source, vp_id format, typo detection).
#       Promoted from advisory at fix-burst-283. Baseline: PASS=129 FAIL=0.
#       Exit contract changed from "always exits 0" to "exits 1 on FAIL > 0" at promotion.
#   verify-tv-registry-count.sh            — (CLEAN) TV registry ground-truth validation.
#       Added fix-burst-287. Compares sum of data rows in BC ## Canonical Test Vectors
#       sections against §Grand-Total declared canonical total in test-vectors.md.
#       Ground truth: 676 canonical TVs in 129 BC bodies == 676 declared in registry.
#       Catches Mechanism-3 drift (registry internal arithmetic drifting from BC bodies).
#   verify-vp-anchors-grammar.sh           — (CLEAN) BC ## VP Anchors section grammar. Every non-blank
#       content line must be a VP identifier (contains VP-) or a None variant. Catches bare story IDs
#       (S-N.NN) that are template-fill artifacts surviving without a real VP assignment. Added P2A-052
#       (2026-08-25). Baseline: 133 BCs checked, PASS=1 FAIL=0.
#   verify-ac-pc-trace.sh                  — (CLEAN) AC→BC postcondition/invariant/precondition/edge-case
#       citation existence. Exits 1 when any cited item is absent from the referenced BC
#       (reason=nonexistent) or an asserted error code is absent from the specifically-cited
#       item (reason=code-absent). Promoted to blocking with 0 DRIFT across 519 citations / 39
#       stories (human-authorized 2026-08-22). POL-48.
#   verify-adr-anchor-citations.sh         — (CLEAN) §Named-Section citation existence.
#       Promoted to BLOCKING at burst-290 (closes F-180-PG PROCESS). Architecture +
#       product-owner swept corpus to ZERO live-body phantom ADR §-citations before
#       promotion. Gate now also detects: (1) chained double-§ forms ADR-NNN §X §Y
#       (ADR-022 §Decision 5 prohibited); (2) bare §Section citations in normative
#       prose without ADR-NNN prefix and without same-file heading resolution.
#       Illustration regions (discriminator:illustration-start/end) are now excluded.
#
# ADVISORY VALIDATORS (exit 0; WARN/FAIL output shown but commit not blocked)
# ─────────────────────────────────────────────────────────────────────────────
# These validators have findings that require corpus-wide remediation or specialist
# routing before promotion to blocking.
#
#   verify-changelog-claim-applied.sh      — false-closure detector (advisory).
#       630 WARN findings across 97 files at fix-burst-283 measurement. Cannot promote
#       until corpus-wide false-closure sweep clears the advisory finding backlog.
#       Promotion requires: WARN=0 AND exit contract changed to exit 1 on WARN > 0.
#       Routing: product-owner + architect joint sweep per P1D-174 findings (FC-1..FC-6).
#
#   verify-ordinal-form-residue.sh         — ADR-027 old-form clause ordinal residue (advisory).
#       Detects "postcondition N" / "invariant N" / "precondition N" word-form ordinals,
#       "edge case EC-..." prose prefix, and single-digit EC-N references (non-stable form)
#       in .factory/stories/ and .factory/specs/behavioral-contracts/ live content.
#       Excludes YAML changelog: list items, ## Changelog sections, and fenced code blocks.
#       Baseline measurement (ADR-027 / P2A-043 F-05 burst): 72 findings across 12 files.
#       Promotion to blocking requires: residue = 0 AND exit contract changed to exit 1.
#       Routing: product-owner (BC files) + story-writer (story files).
#
#   verify-no-phantom-types.sh             — GAP-01 phantom-type corpus grep gate (advisory).
#       Codifies P2A-077 process-gap: sibling-sweeps must be CORPUS GREP, not enumerated file
#       lists. Detects retired/phantom Rust type symbols (ToolOutput::Structured, CompiledGraph<,
#       ConcreteGraphRunner<, S: GraphState, trait GraphState, Fn(&S), schema_for!(S)) across
#       the FULL .factory/specs/ + .factory/stories/ + .factory/holdout-scenarios/ corpus.
#       from_value::<S> / from_value::<TestGraphState> are GAP-01 scoped (only flagged in
#       files referencing GraphAgentTool/mcp::graph_tool/ConcreteGraphRunner; avoids false
#       positives on legitimate serde uses in non-GAP-01 BCs).
#       R14-05 (VP filename): inventory-based check against VP-INDEX §VP-Catalog File column
#       (F-P2A093-02 fix, round-21): flags VP filename references absent from inventory;
#       references to in-inventory filenames (VP-001.md..VP-015.md + slug forms) are NOT flagged.
#       Excludes: YAML changelog: blocks, ## Changelog sections, ## Symbol Grounding sections
#       (PHANTOM-audit rows), and descriptive-negation prose.
#       Baseline measurement (P2A-077 burst, 2026-08-27): 1 finding (HS-C-001 line 230).
#       Promotion to blocking requires: residue = 0 AND exit contract changed to exit 1.
#       Routing: architect + product-owner + story-writer per GAP-01-straggler fix-burst.
#
#   verify-module-criticality-vp-column.sh — VP-INDEX ↔ module-criticality VP-column reverse check (advisory).
#       Closes drift path exposed by F-P2A095-01 (graph::hitl VP-011 sat at '—' across multiple
#       rounds): for each (VP-ID, module) row in VP-INDEX §VP-Catalog, asserts that
#       module-criticality.md §Module Classification VP column shows the VP-ID (not '—').
#       Multi-VP hosts (prompts::injection_guard VP-006 + VP-006-B) must show all VP-IDs.
#       Baseline (round-21 post-architect-fix): PASS=17 WARN=0 (zero '—' entries for VP hosts).
#       Promotion to blocking requires: WARN=0 sustained AND exit contract changed to exit 1.
#       Routing: architect (module-criticality.md VP column updates).
#
#   verify-security-literal-propagation.sh — security-critical BC/ADR ↔ anchor-story propagation (advisory).
#       Closes process-gap F-P2A097-PG / F-P2A096-PG (round-22): verify-ac-pc-trace.sh checks
#       AC citation ID existence only — it does NOT check that AC/Task body literals mirror the
#       current canonical forms of the cited BC/ADR items. When BC-2.09.008/ADR-029 received
#       security corrections (UUID regex → version-agnostic; panic mechanism → FutureExt::catch_unwind),
#       story S-2.11 AC/Task bodies were not swept by any existing gate.
#       Rule set (data-driven; 4 rules):
#         R01: UUID v4-specific regex fragment (`-4[0-9a-f]{3}-[89ab]`) forbidden in S-2.11 body
#         R02: "UUID v4" wording in sanitizer context forbidden in S-2.11 body
#         R03: story body with UnwindSafe mechanism must also name FutureExt::catch_unwind
#         R04: story with SEC-008 reference should cite `panic = "unwind"` obligation
#       Baseline (round-22 gate creation): wires advisory; story-writer concurrently sweeping S-2.11.
#       Promotion to blocking: after story-writer sweep clears all R01-R04 findings on live tree.
#       Routing: story-writer (anchor story body-literal sweep).
#
#   verify-decision-section-canonical-form.sh — §Decision-N hyphenated form in new changelog additions (advisory).
#       Closes process-gap F-P2A098-02 (round-22): verify-adr-decision-refs.sh excludes changelog
#       regions (POL-19 measured-scope carve-out), leaving `§Decision-N` (hyphen) unchecked in
#       newly-authored changelog prose. ADR-022 §Decision 5 establishes `§Decision N` (space) as
#       canonical; the hyphenated form was observed in BC-2.09.008 v2.0/v2.1 and ARCH-INDEX entries.
#       Uses git diff HEAD addition-only scoping — existing committed content grandfathered.
#       Baseline (round-22 gate creation): wires advisory.
#       Promotion to blocking: after corpus-wide cleanup of hyphenated form in committed content
#       (requires verify-adr-decision-refs.sh CITE_RE to expand scope or a separate full-corpus
#       gate to be added).
#       Routing: finding author (replace §Decision-N with §Decision N in new additions).
#
# EXIT CONTRACT
# ─────────────
# Exit 0 if all blocking validators pass.
# Exit 1 if any blocking validator exits 1.
#
# Usage:  bash .factory/hooks/pre-commit-validators.sh
# Called: from .git/hooks/pre-commit on factory-artifacts branch commits

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FAILED_VALIDATORS=()
PASSED_VALIDATORS=()
PASS_COUNT=0
# Single source of truth for the expected blocking validator roster size.
# Update this constant when adding or removing a blocking validator.
EXPECTED_BLOCKING_COUNT=16

# run_blocking runs a validator and records failure in FAILED_VALIDATORS
run_blocking() {
  local name="$1"
  local script="$HOOKS_DIR/$name"

  if [ ! -f "$script" ]; then
    echo "[SKIP] $name — script not found at $script"
    FAILED_VALIDATORS+=("$name (MISSING — script not found)")
    return
  fi

  echo ""
  echo "── $name ──────────────────────────────"
  if bash "$script"; then
    PASS_COUNT=$((PASS_COUNT + 1))
    PASSED_VALIDATORS+=("$name")
  else
    FAILED_VALIDATORS+=("$name")
  fi
}

# run_advisory runs a validator for visibility only; never blocks the commit
run_advisory() {
  local name="$1"
  local script="$HOOKS_DIR/$name"

  if [ ! -f "$script" ]; then
    echo "[SKIP] $name — script not found at $script"
    return
  fi

  echo ""
  echo "── $name (advisory) ──────────────────────────────"
  bash "$script" || true  # exit code is explicitly ignored
}

# ── Branch detection (robust; suite runs unconditionally) ─────────────────────
# Do NOT gate on `git branch --show-current` — it returns empty string in detached
# HEAD / rebase / bisect / cherry-pick, causing silent bypass of all validators.
# `symbolic-ref --short` also fails in detached HEAD but we capture it explicitly
# and still run the suite rather than silently passing.
# --no-verify bypass note: git commit --no-verify skips this entire hook chain.
# The factory-artifacts branch protection does not enforce --no-verify prevention;
# rely on team discipline and CI audit to detect unauthorized bypasses.
FACTORY_BRANCH="$(git -C "$HOOKS_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(unknown)")"
echo "factory-artifacts pre-commit gate — running blocking validators"
echo "  branch: $FACTORY_BRANCH (suite runs unconditionally regardless of branch state)"
echo "================================================================"

# ── Blocking validators ───────────────────────────────────────────────────────
run_blocking "verify-no-version-pins.sh"
run_blocking "verify-adr-decision-refs.sh"
run_blocking "records-lint.sh"
run_blocking "verify-changelog-date-monotonicity.sh"
run_blocking "verify-changelog-date-validity.sh"
run_blocking "verify-enum-variant-casing.sh"
run_blocking "verify-signature-canon.sh"
run_blocking "verify-error-notation-canon.sh"
run_blocking "verify-form-a-changelog-direction.sh"
run_blocking "verify-arch-anchor-resolution.sh"
run_blocking "verify-module-canonicality.sh"
run_blocking "verify-bc-frontmatter-schema.sh"
run_blocking "verify-tv-registry-count.sh"
run_blocking "verify-adr-anchor-citations.sh"
run_blocking "verify-ac-pc-trace.sh"
run_blocking "verify-vp-anchors-grammar.sh"

# ── Advisory validators (run but do not block; see header for promotion paths) ─
echo ""
echo "── Advisory validators (non-blocking; see header for promotion paths) ─"
run_advisory "verify-changelog-claim-applied.sh"
run_advisory "verify-ordinal-form-residue.sh"
run_advisory "verify-no-phantom-types.sh"
run_advisory "verify-module-criticality-vp-column.sh"
run_advisory "verify-security-literal-propagation.sh"
run_advisory "verify-decision-section-canonical-form.sh"

# ── Final gate ────────────────────────────────────────────────────────────────
echo ""
echo "================================================================"
echo "Blocking validators passed: $PASS_COUNT / $EXPECTED_BLOCKING_COUNT expected"

# ── Per-validator census (computed from actual run results) ───────────────────
# Replaces the static (CLEAN)/(FAILING) comment-block annotations.
# Reports actual run outcome, not an authored snapshot.
echo ""
echo "Per-validator census (computed from this run):"
for v in "${PASSED_VALIDATORS[@]}"; do
  printf "  PASS   : %s\n" "$v"
done
for v in "${FAILED_VALIDATORS[@]}"; do
  printf "  FAIL   : %s\n" "$v"
done

# ── Roster assertion (E04) ────────────────────────────────────────────────────
TOTAL_RAN=$(( PASS_COUNT + ${#FAILED_VALIDATORS[@]} ))
if [ "$TOTAL_RAN" -ne "$EXPECTED_BLOCKING_COUNT" ]; then
  echo ""
  echo "GATE: FAIL — roster mismatch: expected $EXPECTED_BLOCKING_COUNT blocking validators, only $TOTAL_RAN ran (check for missing scripts)"
  exit 1
fi

if [ "${#FAILED_VALIDATORS[@]}" -gt 0 ]; then
  echo ""
  echo "GATE: FAIL — the following blocking validators failed:"
  for v in "${FAILED_VALIDATORS[@]}"; do
    echo "  - $v"
  done
  echo ""
  echo "Commit blocked. Fix the above findings before committing."
  exit 1
fi

echo ""
echo "GATE: PASS — all $EXPECTED_BLOCKING_COUNT blocking validators passed"
exit 0
