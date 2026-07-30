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
#   verify-no-version-pins.sh              — (CLEAN) pinned doc-id vN.N versions block
#   verify-adr-decision-refs.sh            — (CLEAN) missing ADR decision refs block
#   records-lint.sh                        — (CLEAN) line-cite and version-pin (D-50) in new content block
#   verify-changelog-date-monotonicity.sh  — (CLEAN) non-monotone changelog dates block
#   verify-changelog-date-validity.sh      — (CLEAN) gate #28 Rules 4+5: future-date ceiling and
#       supplement timestamp-currency (burst-283/DEFER-002). Fires when any changelog entry
#       date exceeds today, or when a prd-supplements/*.md timestamp: does not match its
#       newest changelog entry date.
#   verify-enum-variant-casing.sh          — (CLEAN) non-canonical enum casing block
#   verify-signature-canon.sh             — (FAILING) adjudicated type-signature canon
#       D-42 FerrochainError ctor | D-43 DynTool | D-45/D-48 as_retriever receiver
#       Pre-existing violations: S1b (capabilities-p1-p2.md as_retriever(&self)),
#       S2 (capabilities-p1-p2.md VectorStoreRetriever<), S4 (4 files Arc<dyn Tool>),
#       S5 (80 files FerrochainError full-form literals). In-flight: architect fix-burst
#       closes S1/S2/S3; product-owner fix-burst closes S4/S5. Wire date: 2026-07-28.
#   verify-error-notation-canon.sh        — (FAILING) ADR-010 error-construction notation
#       D-72 error-construction notation canon | 5 violations in prd-supplements/bc-authoring-plan.md
#       Pre-existing: 3 × CLASS3_ASCII_ELLIPSIS_VIOLATION, 2 × CLASS3_MISSING_DOTS_VIOLATION.
#       Routing: product-owner fix-burst replaces '...' with '..' and adds '..' to partial-field
#       forms in bc-authoring-plan.md. Wire date: 2026-07-29.
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
PASS_COUNT=0

# run_blocking runs a validator and records failure in FAILED_VALIDATORS
run_blocking() {
  local name="$1"
  local script="$HOOKS_DIR/$name"

  if [ ! -f "$script" ]; then
    echo "[SKIP] $name — script not found at $script"
    return
  fi

  echo ""
  echo "── $name ──────────────────────────────"
  if bash "$script"; then
    PASS_COUNT=$((PASS_COUNT + 1))
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

echo "factory-artifacts pre-commit gate — running blocking validators"
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

# ── Advisory validators (run but do not block; see header for promotion paths) ─
echo ""
echo "── Advisory validators (non-blocking; see header for promotion paths) ─"
run_advisory "verify-changelog-claim-applied.sh"

# ── Final gate ────────────────────────────────────────────────────────────────
echo ""
echo "================================================================"
echo "Blocking validators passed: $PASS_COUNT"

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

echo "GATE: PASS — all blocking validators passed"
exit 0
