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
# These validators are currently CLEAN on the full corpus (zero FAIL findings)
# and are wired to block factory-artifacts commits.
#
#   verify-no-version-pins.sh              — pinned pypi/npm versions block
#   verify-adr-decision-refs.sh            — missing ADR decision refs block
#   records-lint.sh                        — line-cite citations in new content block
#   verify-changelog-date-monotonicity.sh  — non-monotone changelog dates block
#   verify-enum-variant-casing.sh          — non-canonical enum casing block
#
# ADVISORY VALIDATORS (exit 0; WARN/FAIL output shown but commit not blocked)
# ─────────────────────────────────────────────────────────────────────────────
# These validators have pre-existing findings that require specialist remediation
# before they can be wired as blocking. Each has a documented promotion path.
#
#   verify-form-a-changelog-direction.sh   — exits 1 standalone (Task-1 blocking).
#       Advisory here because 6 BC files lack Form-A: BC-2.07.002, BC-2.08.011,
#       BC-2.08.012, BC-2.09.007, BC-2.13.007, BC-2.15.005. Product-owner adds
#       Form-A changelog entries to those 6 files. Promote when BC_UNVERIFIED=0.
#
#   verify-arch-anchor-resolution.sh       — exits 1 standalone (Task-7a blocking).
#       Advisory here because 4 BC files use wildcard arch citations (now rejected):
#       BC-2.20.001, BC-2.20.002, BC-2.21.002, BC-2.22.001. Architect replaces
#       wildcard citations with specific ADR file paths. Promote when FAIL=0.
#
#   verify-module-canonicality.sh          — exits 1 standalone (Task-3 blocking).
#       Advisory here because set-diff mismatches exist in purity-boundary-map
#       and verification-coverage-matrix. Architect reconciles after Wave-A ADR
#       updates. Promote when FAIL=0.
#
#   verify-changelog-claim-applied.sh      — false-closure candidates (advisory, new gate)
#   verify-bc-frontmatter-schema.sh        — BC schema gaps (advisory, new gate)
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

# ── Blocking validators (currently clean on full corpus) ─────────────────────
run_blocking "verify-no-version-pins.sh"
run_blocking "verify-adr-decision-refs.sh"
run_blocking "records-lint.sh"
run_blocking "verify-changelog-date-monotonicity.sh"
run_blocking "verify-enum-variant-casing.sh"

# ── Advisory validators (run but do not block; see promotion paths in header) ─
echo ""
echo "── Advisory validators (non-blocking; see header for promotion paths) ─"
run_advisory "verify-form-a-changelog-direction.sh"
run_advisory "verify-arch-anchor-resolution.sh"
run_advisory "verify-module-canonicality.sh"
run_advisory "verify-changelog-claim-applied.sh"
run_advisory "verify-bc-frontmatter-schema.sh"

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
