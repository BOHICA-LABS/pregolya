#!/usr/bin/env bash
# verify-module-criticality-vp-column.sh — VP-INDEX ↔ module-criticality VP-column reverse check
#
# PURPOSE
# ───────
# For each (VP-ID, module) row in VP-INDEX.md §VP Catalog, asserts that
# specs/module-criticality.md §Module Classification table's row for that
# module shows the VP-ID in its VP column (not '—').
#
# This gate closes the drift path that allowed graph::hitl VP-011 to sit at
# '—' in module-criticality.md across multiple rounds undetected (F-P2A095-01).
# The VP-column in VP-INDEX is the authoritative source of which modules host
# VPs; module-criticality must mirror that assignment in its VP column.
#
# SCOPE
# ─────
# Reads:
#   .factory/specs/verification-properties/VP-INDEX.md   — §VP Catalog (VP-ID + Module columns)
#   .factory/specs/module-criticality.md                 — §Module Classification (VP column)
#
# Multi-VP hosts (e.g., prompts::injection_guard = VP-006 + VP-006-B) must
# show ALL their VP-IDs in the VP column (comma-separated notation).
# core::serializable has two rows (Reviver → VP-010, LcSerializable → VP-007);
# each row's VP must be present across the union of VP cells for that module.
#
# SELF-PROBE (POL-31)
# ───────────────────
# Two synthetic-fixture probes run before the live check:
#   probe_pos: module has VP-INDEX entry but '—' in module-criticality → FAIL/WARN reported
#   probe_neg: module has VP-INDEX entry and VP-ID correctly in module-criticality → pass
#
# EXIT CONTRACT
# ─────────────
# Exit 0: self-probes pass AND live check finds zero VP-column gaps (advisory)
# Exit 0: WARN findings printed but commit not blocked (advisory-first promotion path)
# Exit 2: self-probe failure (script logic bug — a probe is false-green or false-red)
#
# ADVISORY: exits 0 always.  Promoted to blocking by:
#   1. Human-authorized promotion decision
#   2. Adding run_blocking "verify-module-criticality-vp-column.sh" in pre-commit-validators.sh
#   3. Incrementing EXPECTED_BLOCKING_COUNT from 16 to 17
#   4. Changing exit contract below from "exit 0" to "exit $rc"
#   5. Updating the ADVISORY VALIDATORS header comment in pre-commit-validators.sh
#
# Usage:  bash .factory/hooks/verify-module-criticality-vp-column.sh
# Called: run_advisory in pre-commit-validators.sh (advisory until promoted)

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
VP_INDEX_PATH="$FACTORY_DIR/specs/verification-properties/VP-INDEX.md"
MODULE_CRIT_PATH="$FACTORY_DIR/specs/module-criticality.md"

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

# ── Core Python checker ───────────────────────────────────────────────────────
# Arguments: <vp_index_path> <module_criticality_path>
# Output lines:
#   MATCH <vp_id> <module>           — VP-ID present in module-criticality VP column (pass)
#   GAP   <vp_id> <module> <found>   — VP-ID missing from module-criticality VP column (fail)
#   MISS  <vp_id> <module>           — module absent from module-criticality table entirely
#   PARSE_ERROR <msg>                — input file parse failure
run_vp_column_check() {
  local vp_index_path="$1"
  local module_crit_path="$2"
  python3 - "$vp_index_path" "$module_crit_path" <<'PYEOF'
import sys, re
from pathlib import Path

vp_index_path  = Path(sys.argv[1])
module_crit_path = Path(sys.argv[2])

def load_vp_catalog(path):
    """Parse VP-INDEX.md §VP Catalog → list of (vp_id, module)."""
    if not path.exists():
        print(f'PARSE_ERROR VP-INDEX not found: {path}')
        return []
    try:
        content = path.read_text(encoding='utf-8', errors='replace')
    except Exception as e:
        print(f'PARSE_ERROR reading VP-INDEX: {e}')
        return []

    pairs = []
    in_catalog = False
    for line in content.splitlines():
        stripped = line.strip()
        if re.match(r'^##\s+VP\s+Catalog\b', stripped, re.IGNORECASE):
            in_catalog = True
            continue
        if in_catalog and re.match(r'^##\s+', stripped):
            in_catalog = False
            continue
        if not in_catalog:
            continue
        if not (stripped.startswith('|') and stripped.endswith('|')):
            continue
        cells = [c.strip() for c in stripped.split('|')]
        if len(cells) < 5:
            continue
        vp_id  = cells[1].strip()
        module = cells[3].strip()
        # Skip header row and separator row
        if not vp_id or not module:
            continue
        if vp_id in ('VP', '---') or module in ('Module', '---'):
            continue
        if re.match(r'^-', vp_id) or re.match(r'^-', module):
            continue
        if re.match(r'^(?:VP|vp)-', vp_id):
            pairs.append((vp_id, module))
    return pairs

def load_module_vp_map(path):
    """Parse module-criticality.md §Module Classification → {module: set(vp_ids)}.
    Module key is the bare canonical form (backticks stripped).
    VP column values are split on commas; '—' and '-' map to empty set.
    Multi-row modules (core::serializable) are merged: union of all VP cells."""
    if not path.exists():
        print(f'PARSE_ERROR module-criticality not found: {path}')
        return {}
    try:
        content = path.read_text(encoding='utf-8', errors='replace')
    except Exception as e:
        print(f'PARSE_ERROR reading module-criticality: {e}')
        return {}

    module_vp = {}  # module_name -> set of vp_ids
    in_classification = False
    for line in content.splitlines():
        stripped = line.strip()
        if re.match(r'^##\s+Module\s+Classification\b', stripped, re.IGNORECASE):
            in_classification = True
            continue
        if in_classification and re.match(r'^##\s+', stripped):
            in_classification = False
            continue
        if not in_classification:
            continue
        if not (stripped.startswith('|') and stripped.endswith('|')):
            continue
        cells = [c.strip() for c in stripped.split('|')]
        if len(cells) < 8:
            continue
        module_cell = cells[1].strip().strip('`')
        vp_cell     = cells[6].strip()
        # Skip header and separator rows
        if not module_cell:
            continue
        if module_cell in ('Module', '---') or module_cell.startswith('-'):
            continue
        # Parse comma-separated VP IDs; '—' and '-' mean no VP
        if vp_cell in ('—', '-', '') or not vp_cell:
            module_vp.setdefault(module_cell, set())
        else:
            vp_ids = {
                v.strip()
                for v in vp_cell.split(',')
                if v.strip() and v.strip() not in ('—', '-')
            }
            if module_cell in module_vp:
                module_vp[module_cell].update(vp_ids)
            else:
                module_vp[module_cell] = vp_ids
    return module_vp

vp_pairs    = load_vp_catalog(vp_index_path)
module_vp_map = load_module_vp_map(module_crit_path)

for (vp_id, module) in vp_pairs:
    if module not in module_vp_map:
        print(f'MISS {vp_id} {module}')
    elif vp_id not in module_vp_map[module]:
        found = ','.join(sorted(module_vp_map[module])) if module_vp_map[module] else '—'
        print(f'GAP {vp_id} {module} found={found}')
    else:
        print(f'MATCH {vp_id} {module}')
PYEOF
}

# ── Self-probe infrastructure ─────────────────────────────────────────────────
PROBE_TMP=""

init_probe_tmp() {
  PROBE_TMP="$(mktemp -d)"
}

clean_probe_tmp() {
  [ -n "$PROBE_TMP" ] && [ -d "$PROBE_TMP" ] && rm -rf "$PROBE_TMP"
  PROBE_TMP=""
}

# ── Self-probe pos: module in VP-INDEX but '—' in module-criticality → FAIL ─────
# Uses synthetic VP-INDEX and module-criticality files in PROBE_TMP.
probe_pos_vp_column_gap_reported() {
  init_probe_tmp

  # Synthetic VP-INDEX: test::phantom hosts VP-999
  cat > "$PROBE_TMP/vp-index.md" <<'SPECEOF'
---
version: "1.0"
---

## VP Catalog

| VP | BC Anchor | Module | Tool | Phase | Priority | Status | DI | Crate | harness_fn | File |
|----|-----------|--------|------|-------|----------|--------|----|-------|------------|------|
| VP-999 | BC-9.99.001 | test::phantom | Kani | 6 | P0 | draft | DI-001 | test-crate | `phantom_harness` | VP-999.md |
SPECEOF

  # Synthetic module-criticality: test::phantom has VP = '—' (gap)
  cat > "$PROBE_TMP/module-crit.md" <<'SPECEOF'
---
version: "1.0"
---

## Module Classification

| Module | Qualifier | Crate | SS | Tier | VP | Kill Rate | Phase Gate |
|--------|-----------|-------|-----|------|-----|-----------|-----------|
| `test::phantom` | — | test-crate | SS-01 | CRITICAL | — | ≥ 95% | P3 per-story + P5 |
SPECEOF

  local output
  output="$(run_vp_column_check "$PROBE_TMP/vp-index.md" "$PROBE_TMP/module-crit.md")"

  if ! echo "$output" | grep -q '^GAP '; then
    echo "[SELF-PROBE FAIL] probe_pos_vp_column_gap_reported: VP-999/test::phantom gap was NOT reported as GAP."
    echo "  Expected a GAP line for VP-999 test::phantom."
    echo "  Output: $output"
    clean_probe_tmp; exit 2
  fi
  if ! echo "$output" | grep -q 'VP-999.*test::phantom'; then
    echo "[SELF-PROBE FAIL] probe_pos_vp_column_gap_reported: GAP line found but not for VP-999/test::phantom."
    echo "  Output: $output"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_pos_vp_column_gap_reported: VP-column gap correctly reported as GAP."
}

# ── Self-probe neg: module in VP-INDEX with correct VP-ID in module-criticality → MATCH ─
probe_neg_vp_column_correct_passes() {
  init_probe_tmp

  # Synthetic VP-INDEX: test::widget hosts VP-998
  cat > "$PROBE_TMP/vp-index.md" <<'SPECEOF'
---
version: "1.0"
---

## VP Catalog

| VP | BC Anchor | Module | Tool | Phase | Priority | Status | DI | Crate | harness_fn | File |
|----|-----------|--------|------|-------|----------|--------|----|-------|------------|------|
| VP-998 | BC-9.98.001 | test::widget | Kani | 6 | P1 | draft | DI-001 | test-crate | `widget_harness` | VP-998.md |
SPECEOF

  # Synthetic module-criticality: test::widget has VP-998 correctly in VP column
  cat > "$PROBE_TMP/module-crit.md" <<'SPECEOF'
---
version: "1.0"
---

## Module Classification

| Module | Qualifier | Crate | SS | Tier | VP | Kill Rate | Phase Gate |
|--------|-----------|-------|-----|------|-----|-----------|-----------|
| `test::widget` | — | test-crate | SS-02 | HIGH | VP-998 | ≥ 90% | P5 |
SPECEOF

  local output
  output="$(run_vp_column_check "$PROBE_TMP/vp-index.md" "$PROBE_TMP/module-crit.md")"

  if echo "$output" | grep -q '^GAP \|^MISS '; then
    echo "[SELF-PROBE FAIL] probe_neg_vp_column_correct_passes: correctly-populated row was incorrectly flagged as GAP/MISS."
    echo "  VP-998 is correctly in test::widget VP column — must not be flagged."
    echo "  Output: $output"
    clean_probe_tmp; exit 2
  fi
  if ! echo "$output" | grep -q '^MATCH VP-998 test::widget'; then
    echo "[SELF-PROBE FAIL] probe_neg_vp_column_correct_passes: expected MATCH line not found."
    echo "  Output: $output"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_neg_vp_column_correct_passes: correctly-populated VP-column row passes."
}

# ── Main live check ───────────────────────────────────────────────────────────
check_module_criticality_vp_column() {
  local raw_output
  raw_output="$(run_vp_column_check "$VP_INDEX_PATH" "$MODULE_CRIT_PATH")"

  local gap_lines=()
  local miss_lines=()
  local match_count=0
  local parse_errors=()

  while IFS= read -r line; do
    case "$line" in
      MATCH\ *)  match_count=$((match_count + 1)) ;;
      GAP\ *)    gap_lines+=("${line#GAP }") ;;
      MISS\ *)   miss_lines+=("${line#MISS }") ;;
      PARSE_ERROR\ *) parse_errors+=("${line#PARSE_ERROR }") ;;
    esac
  done <<< "$raw_output"

  echo "  VP-INDEX:         $VP_INDEX_PATH"
  echo "  module-criticality: $MODULE_CRIT_PATH"
  echo "  VP pairs checked: $((match_count + ${#gap_lines[@]} + ${#miss_lines[@]}))"
  echo ""

  for err in "${parse_errors[@]}"; do
    emit FAIL "vp-column-check: PARSE ERROR — $err"
  done

  for entry in "${miss_lines[@]}"; do
    emit WARN "vp-column-check: MISS — module in VP-INDEX but absent from module-criticality table: $entry"
  done

  for entry in "${gap_lines[@]}"; do
    emit WARN "vp-column-check: GAP — VP-ID missing from module-criticality VP column: $entry"
    echo "    Fix: add the VP-ID to the VP column for the module row in module-criticality.md"
    echo "    Root-cause pattern: VP-INDEX lists (VP-ID, module) but module-criticality VP column shows '—'"
  done

  if [ "${#gap_lines[@]}" -eq 0 ] && [ "${#miss_lines[@]}" -eq 0 ] && [ "${#parse_errors[@]}" -eq 0 ]; then
    emit PASS "vp-column-check: all $match_count VP-INDEX (VP-ID, module) pairs have matching VP column entries in module-criticality.md"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-module-criticality-vp-column: VP-INDEX ↔ module-criticality VP-column reverse check (ADVISORY)"
echo "  VP-INDEX:            $VP_INDEX_PATH"
echo "  module-criticality:  $MODULE_CRIT_PATH"
echo "  Finding: F-P2A095-01 — VP-column drift in module-criticality.md escaped machine gate"
echo ""

echo "[SELF-PROBE] Verifying check catches VP-column gaps and passes correct rows (POL-31)..."
probe_pos_vp_column_gap_reported
probe_neg_vp_column_correct_passes
echo "[SELF-PROBE] Both self-probes passed — check is not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "ADVISORY check (exit 0 always)"
echo "════════════════════════════════════════════"
echo ""
echo "── VP-INDEX ↔ module-criticality VP-column check ──────────────────────"
check_module_criticality_vp_column

echo ""
echo "════════════════════════════════════════════"
echo ""
echo "verify-module-criticality-vp-column: PASS=$PASS WARN=$WARN FAIL=$FAIL"
if [ "$WARN" -gt 0 ] || [ "$FAIL" -gt 0 ]; then
  echo "  Routing: architect (module-criticality.md VP column) — add missing VP-IDs"
  echo "  Reference: VP-INDEX.md §VP Catalog (authoritative VP-to-module mapping)"
fi
echo ""
echo "RESULT: PASS (advisory — exit 0 regardless of WARN/FAIL count)"
exit 0
