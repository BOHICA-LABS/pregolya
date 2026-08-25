#!/usr/bin/env bash
# verify-vp-anchors-grammar.sh — pregolya factory-artifacts BLOCKING validator
#
# PURPOSE
# ───────
# Every non-blank content line in a BC's `## VP Anchors` section must be either:
#   (a) a VP identifier line  — contains at least one `VP-` token
#       (covers all valid forms: VP-004, VP-MEM-01, VP-2.13.001-A, VP-SPLIT-08, etc.;
#        optional leading `- ` list marker; comma-separated lists on one line; optional
#        free text after a dash/em-dash)
#   (b) a None variant line   — literal `None` (optionally followed by free text),
#       or the italicised markdown form `_(none…)_` used in the corpus
#
# Any other non-blank content line is a VIOLATION (P2A-052 process-gap).
# The most common violation class: bare story IDs (`S-2.10`, `S-1.26`) that are
# template-fill artifacts from the story-decomposition phase.
#
# SCOPE
# ─────
# Full-corpus scan: all .factory/specs/behavioral-contracts/ss-*/BC-*.md files.
# BC-INDEX.md is EXCLUDED (catalog file, not a behavioral contract).
# This is a STANDING STRUCTURAL INVARIANT — addition-only scoping is NOT used.
# The gate enforces correctness of all committed BC bodies, not just new additions.
#
# SELF-PROBE (POL-31)
# ───────────────────
# A synthetic `## VP Anchors` section is exercised before the live scan:
#   probe_must_fail:     S-1.26 bare story ID is caught
#   probe_must_not_fail: `- VP-004` passes
#   probe_must_not_fail: `VP-2.20.003-A, VP-2.20.003-B` passes
#   probe_must_not_fail: `None` passes
# POL-30 (gate-self-scope-exclusion): probe fixture lines live in shell variables /
# $TMPDIR, never under .factory/specs/behavioral-contracts/, so the live scan cannot
# accidentally scan them.
#
# BLOCKING / ADVISORY
# ───────────────────
# BLOCKING: consistent with other structural BC validators
# (verify-bc-frontmatter-schema.sh, verify-module-canonicality.sh, etc.).
# Newly introduced gate — grounded in P2A-052 finding, human-authorized.
#
# EXIT CONTRACT
# ─────────────
# Exit 0: all BCs pass (no FAIL lines).
# Exit 1: one or more BCs have VP Anchors grammar violations.
# Exit 2: self-probe failure (script bug — a check is false-green).
#
# Usage: bash .factory/hooks/verify-vp-anchors-grammar.sh [--skip-self-probe]
# Called: from .factory/hooks/pre-commit-validators.sh (blocking)

set -euo pipefail

SKIP_SELF_PROBE=false
for arg in "$@"; do
  case "$arg" in
    --skip-self-probe) SKIP_SELF_PROBE=true ;;
  esac
done

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BC_DIR="${FACTORY_DIR}/specs/behavioral-contracts"

PASS=0
WARN=0
FAIL=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
  esac
}

# ── Self-probe helpers ────────────────────────────────────────────────────────

probe_must_fail() {
  local check_id="$1"
  local description="$2"
  if [ "${PROBE_EXIT:-0}" -eq 0 ]; then
    echo "[SELF-PROBE FAIL] $check_id self-probe is false-green: '$description' was NOT detected."
    echo "  This is a script bug — the check would silently pass on a real violation."
    exit 2
  fi
}

probe_must_not_fail() {
  local check_id="$1"
  local description="$2"
  if [ "${PROBE_EXIT:-0}" -ne 0 ]; then
    echo "[SELF-PROBE FAIL] $check_id false-positive probe: '$description' FIRED but should be exempt."
    echo "  This is a script bug — the check would incorrectly flag a non-violation line."
    exit 2
  fi
}

# ── Core line-validity helper ─────────────────────────────────────────────────
# Returns 0 (valid) or 1 (violation) for a single VP Anchors content line.
# Blank lines are always valid (return 0).
# Valid if: contains VP- token OR is a None variant.
_vp_line_valid() {
  local line="$1"
  # Blank/whitespace-only lines are always valid
  if [[ "$line" =~ ^[[:space:]]*$ ]]; then
    return 0
  fi
  # (a) Contains at least one VP- token (covers all VP identifier forms)
  if echo "$line" | grep -qE 'VP-[A-Z0-9]'; then
    return 0
  fi
  # (b) None variant: literal `None` (optionally followed by free text)
  if echo "$line" | grep -qiE '^[[:space:]]*None([[:space:]].*)?$'; then
    return 0
  fi
  # (b2) Italicised markdown None form: `_(none…)_`
  if echo "$line" | grep -qi '^_(none'; then
    return 0
  fi
  # No valid pattern matched — violation
  return 1
}

# ── Self-probes (POL-31) ──────────────────────────────────────────────────────

run_self_probes() {
  # Probe 1: bare story ID S-1.26 MUST be caught (FIRES)
  PROBE_EXIT=0
  _vp_line_valid "S-1.26" || PROBE_EXIT=1
  probe_must_fail "vp-anchors-grammar" "bare story ID 'S-1.26' is caught as violation"

  # Probe 2: `- VP-004` MUST pass (does NOT fire)
  PROBE_EXIT=0
  _vp_line_valid "- VP-004" || PROBE_EXIT=1
  probe_must_not_fail "vp-anchors-grammar" "'- VP-004' passes as valid VP identifier line"

  # Probe 3: `VP-2.20.003-A, VP-2.20.003-B` MUST pass (does NOT fire)
  PROBE_EXIT=0
  _vp_line_valid "VP-2.20.003-A, VP-2.20.003-B" || PROBE_EXIT=1
  probe_must_not_fail "vp-anchors-grammar" "'VP-2.20.003-A, VP-2.20.003-B' passes as valid VP identifier line"

  # Probe 4: `None` MUST pass (does NOT fire)
  PROBE_EXIT=0
  _vp_line_valid "None" || PROBE_EXIT=1
  probe_must_not_fail "vp-anchors-grammar" "'None' passes as valid None-variant line"

  # Probe 5: `None — no formal proofs required` MUST pass (does NOT fire)
  PROBE_EXIT=0
  _vp_line_valid "None — no formal proofs required" || PROBE_EXIT=1
  probe_must_not_fail "vp-anchors-grammar" "'None — no formal proofs required' passes as valid None-variant with free text"

  # Probe 6: bare story ID S-2.10 MUST be caught (FIRES) — the other violation shape in corpus
  PROBE_EXIT=0
  _vp_line_valid "S-2.10" || PROBE_EXIT=1
  probe_must_fail "vp-anchors-grammar" "bare story ID 'S-2.10' is caught as violation"

  # Probe 7: `_(none — unit tests sufficient)_` MUST pass (does NOT fire)
  PROBE_EXIT=0
  _vp_line_valid "_(none — unit tests sufficient)_" || PROBE_EXIT=1
  probe_must_not_fail "vp-anchors-grammar" "'_(none — unit tests sufficient)_' passes as italicised None variant"
}

# ── Main check ────────────────────────────────────────────────────────────────

check_vp_anchors_grammar() {
  local found_violation=0
  local bc_checked=0

  while IFS= read -r -d '' f; do
    # Extract VP Anchors section: text between `## VP Anchors` and the next `## ` heading.
    # Uses flag-based awk to avoid early termination on the section heading itself.
    local section
    section="$(awk '/^## VP Anchors/{flag=1;next} /^## /{flag=0} flag' "$f")"

    # No section = no ## VP Anchors heading in this BC
    if [ -z "$section" ]; then
      rel="${f#$FACTORY_DIR/}"
      emit FAIL "vp-anchors-grammar: $rel — no '## VP Anchors' section found (required BC structure)"
      found_violation=1
      bc_checked=$((bc_checked + 1))
      continue
    fi

    bc_checked=$((bc_checked + 1))

    # Check each line in the section
    local line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))
      # Skip blank/whitespace-only lines
      if [[ "$line" =~ ^[[:space:]]*$ ]]; then
        continue
      fi
      # Validate the line
      if ! _vp_line_valid "$line"; then
        rel="${f#$FACTORY_DIR/}"
        emit FAIL "vp-anchors-grammar: $rel — VP Anchors line $line_num is invalid: $(echo "$line" | cut -c1-80)"
        found_violation=1
      fi
    done <<< "$section"
  done < <(find "$BC_DIR" -path "*/ss-*/BC-*.md" -name "BC-*.md" -print0 2>/dev/null | sort -z)

  if [ "$found_violation" -eq 0 ]; then
    emit PASS "vp-anchors-grammar: all $bc_checked BC files have valid ## VP Anchors sections"
  else
    echo ""
    echo "  Routing: product-owner (fix invalid VP Anchors content in BC files)"
    echo "  Valid forms:"
    echo "    VP identifier: '- VP-004', '- VP-MEM-01', '- VP-2.13.001-A, VP-2.13.001-B'"
    echo "    None variant:  'None', 'None — <free text>', '_(none — <free text>)_'"
    echo "  Violation class: bare story IDs (S-N.NN) are template-fill artifacts — replace"
    echo "                   with the actual VP identifier(s) or None if no VP is assigned."
  fi
}

# ── Entry point ───────────────────────────────────────────────────────────────

echo "verify-vp-anchors-grammar: BC ## VP Anchors section grammar validator"
echo "  BC_DIR: $BC_DIR"
echo ""

if [ "$SKIP_SELF_PROBE" = false ]; then
  echo "[SELF-PROBE] Verifying check catches synthetic violations (POL-31)..."
  run_self_probes
  echo "[SELF-PROBE] All self-probes passed — check is not false-green."
  echo ""
fi

echo "--- VP Anchors grammar check (full corpus) ---"
check_vp_anchors_grammar

echo ""
echo "verify-vp-anchors-grammar: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL — resolve violations before committing (P2A-052 gate)"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
