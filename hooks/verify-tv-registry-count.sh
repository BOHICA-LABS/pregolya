#!/usr/bin/env bash
# verify-tv-registry-count.sh — TV registry ground-truth validation gate
#
# PURPOSE
# ───────
# Compares the sum of test-vector counts parsed from BC body files against
# the canonical total declared in test-vectors.md §Grand-Total.  This is a
# cross-source ground-truth check, NOT an internal consistency check.
#
# BLOCKING: exits 1 on mismatch.  Wired into pre-commit-validators.sh.
#
# GROUND TRUTH MODEL
# ──────────────────
# Source A (BC bodies):  For each BC file under specs/behavioral-contracts/ss-*/
#                        count data rows in the "## Canonical Test Vectors" section.
#                        A data row is any table row that is neither the header row
#                        (first row after the ## heading) nor a separator row
#                        (containing only |, -, :, and whitespace).
#
# Source B (registry):   The declared canonical total in test-vectors.md is the
#                        single integer on the line matching:
#                          **Total vectors (NNN authored BCs):** NNN canonical ...
#
# Gate: Source A == Source B → PASS; mismatch → FAIL.
#
# WHAT THIS CATCHES
# ─────────────────
# Mechanism 3 drift: BC body gets new test vectors → BC author bumps TV Count in
# test-vectors.md registry → but does NOT update the Grand Total line → registry
# column sum stays consistent internally but Grand Total drifts from BC bodies.
# This gate compares the two external sources directly; it CANNOT be satisfied by
# only updating the registry's internal column arithmetic.
#
# WHAT THIS DOES NOT CHECK
# ────────────────────────
# - GTV (golden test vectors in BC-2.07.002) — those are counted separately
# - The TV Count column values in the registry (per-BC accuracy) — those would
#   require per-BC body comparison; this gate checks the aggregate total only
# - Named TV labels (TV-001, TV-002, ...) — some older BCs use unlabeled tables
#
# NOTE on BC format variants
# ──────────────────────────
# Newer BCs (added burst-224+) label rows "TV-001", "TV-002", etc.
# Older BCs (SS-04, SS-11, SS-13) use unlabeled markdown tables under the same
# "## Canonical Test Vectors" heading.  The section-row-counting method handles
# both formats and gives the same total (676 at v3.0) as the declared registry.
# Counting only labeled "| TV-NNN" rows would give 593 (not 676) because it
# misses 83 TVs in the unlabeled-format BCs.  This is documented: the counting
# method matches BC-body reality, not just a subset of BCs.
#
# SPEC AUTHORITY
# ──────────────
# test-vectors.md §Grand-Total, line starting "**Total vectors"
# test-vectors.md §Ground-truth validation requirement (normative note added fix-burst-287)
#
# SELF-PROBES (2 mandatory)
# ─────────────────────────
# 1. Mismatch detected (synthetic BC body + registry with wrong total)
# 2. Match passes (synthetic BC body + registry with correct total)
#
# TD-VSDD-091: findings cite "file :: symbol"; no file:NNN line-number citations.
#
# Usage:  bash .factory/hooks/verify-tv-registry-count.sh
# Exit:   0 if body total matches registry declared total; 1 if mismatch.
#
# Integration: wired as BLOCKING in pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
SPECS_DIR="$FACTORY_DIR/specs"
BC_ROOT="$SPECS_DIR/behavioral-contracts"
TV_REGISTRY="$SPECS_DIR/prd-supplements/test-vectors.md"

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

# ── Core Python counter ───────────────────────────────────────────────────────
# Arguments: <bc_root> <registry_file>
# Output lines:
#   BODY_TOTAL <n>      sum of data rows in all BC ## Canonical Test Vectors sections
#   DECLARED_TOTAL <n>  canonical total from registry §Grand-Total line
#   BODY_BC_COUNT <n>   number of BC files with a ## Canonical Test Vectors section
#   ERROR <msg>         if registry total could not be parsed
run_tv_counter() {
  local bc_root="$1" registry_file="$2"
  python3 - "$bc_root" "$registry_file" <<'PYEOF'
import sys, glob, re, os

bc_root       = sys.argv[1]
registry_file = sys.argv[2]

# ── Parse registry declared canonical total ───────────────────────────────────
# Line format: **Total vectors (NNN authored BCs):** NNN canonical test vectors ...
DECLARED_RE = re.compile(r'\*\*Total vectors[^:]*:\*\*\s+(\d+)\s+canonical test vectors')

try:
    with open(registry_file, 'r', encoding='utf-8') as fh:
        reg_content = fh.read()
except OSError as e:
    print(f'ERROR cannot read registry: {e}')
    sys.exit(0)  # let shell handle error reporting

m = DECLARED_RE.search(reg_content)
if not m:
    print(f'ERROR §Grand-Total line not found in {registry_file} — cannot validate')
    sys.exit(0)

declared_total = int(m.group(1))
print(f'DECLARED_TOTAL {declared_total}')

# ── Count data rows in BC ## Canonical Test Vectors sections ─────────────────

def count_bc_tvs(filepath):
    """
    Count data rows in the ## Canonical Test Vectors section of a BC file.

    A data row is a table row (starts with '|') that is:
    - Not the header row (first '|' row after the section heading)
    - Not a separator row (contains only |, -, :, spaces)

    Returns: int (count of data rows, 0 if section not present)
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        return 0

    in_section = False
    header_seen = False
    separator_seen = False
    count = 0

    for line in lines:
        stripped = line.strip()
        if stripped == '## Canonical Test Vectors':
            in_section = True
            header_seen = False
            separator_seen = False
            count = 0  # reset — use the LAST such section if multiple (shouldn't happen)
            continue
        if in_section:
            if stripped.startswith('## ') and stripped != '## Canonical Test Vectors':
                # Next section — stop counting
                break
            if stripped.startswith('|'):
                # Check if separator row (only |, -, :, spaces)
                if re.match(r'^[|\-:\s]+$', stripped):
                    separator_seen = True
                elif not header_seen:
                    header_seen = True   # first non-separator row = header
                elif separator_seen:
                    count += 1           # data row
                # If header_seen but not separator_seen: second header? Unusual — skip
    return count

# Find all BC files in ss-* directories
bc_files = sorted(glob.glob(os.path.join(bc_root, 'ss-*', '*.md')))

body_total = 0
bc_with_tvs = 0
for f in bc_files:
    n = count_bc_tvs(f)
    if n > 0:
        body_total += n
        bc_with_tvs += 1

print(f'BODY_TOTAL {body_total}')
print(f'BODY_BC_COUNT {bc_with_tvs}')
PYEOF
}

# ── Self-probe infrastructure ─────────────────────────────────────────────────
PROBE_TMP=""

init_probe_tmp() {
  PROBE_TMP="$(mktemp -d)"
  mkdir -p "$PROBE_TMP/behavioral-contracts/ss-99"
  mkdir -p "$PROBE_TMP/prd-supplements"
}

clean_probe_tmp() {
  [ -n "$PROBE_TMP" ] && [ -d "$PROBE_TMP" ] && rm -rf "$PROBE_TMP"
  PROBE_TMP=""
}

# Create a synthetic BC with N TVs in its ## Canonical Test Vectors section
write_probe_bc() {
  local filepath="$1" tv_count="$2"
  {
    echo "document_type: bc"
    echo ""
    echo "# BC-2.99.001"
    echo ""
    echo "## Description"
    echo ""
    echo "Test BC."
    echo ""
    echo "## Canonical Test Vectors"
    echo ""
    echo "| Input | Expected | Category |"
    echo "|-------|----------|----------|"
    local i
    for ((i=1; i<=tv_count; i++)); do
      echo "| input-${i} | expected-${i} | happy-path |"
    done
    echo ""
    echo "## Traceability"
    echo ""
    echo "Some traceability."
  } > "$filepath"
}

# Create a synthetic registry with a given declared canonical total
write_probe_registry() {
  local filepath="$1" declared_total="$2"
  {
    echo "document_type: supplement"
    echo ""
    echo "## BC Test Vector Inventory"
    echo ""
    echo "| BC ID | Subsystem | TV Count |"
    echo "|-------|-----------|----------|"
    echo "| BC-2.99.001 | SS-99 | ${declared_total} |"
    echo ""
    echo "**Total vectors (1 authored BCs):** ${declared_total} canonical test vectors (TV Count column) + 0 golden test vectors = **${declared_total} total vectors**"
  } > "$filepath"
}

# ── Probe 1: Mismatch detected ────────────────────────────────────────────────
probe_mismatch_detected() {
  init_probe_tmp
  # BC has 3 TVs, registry declares 5 → mismatch
  write_probe_bc "$PROBE_TMP/behavioral-contracts/ss-99/BC-2.99.001.md" 3
  write_probe_registry "$PROBE_TMP/prd-supplements/test-vectors.md" 5

  local out
  out="$(run_tv_counter "$PROBE_TMP/behavioral-contracts" "$PROBE_TMP/prd-supplements/test-vectors.md")"

  local body_total declared
  body_total="$(echo "$out" | grep '^BODY_TOTAL' | awk '{print $2}')"
  declared="$(echo "$out" | grep '^DECLARED_TOTAL' | awk '{print $2}')"

  if [ "$body_total" = "$declared" ]; then
    echo "[SELF-PROBE FAIL] Probe 1: mismatch not detected (body=${body_total}, declared=${declared} should differ)."
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 1: mismatch detected (body=${body_total} ≠ declared=${declared})."
}

# ── Probe 2: Match passes ─────────────────────────────────────────────────────
probe_match_passes() {
  init_probe_tmp
  # BC has 4 TVs, registry declares 4 → match
  write_probe_bc "$PROBE_TMP/behavioral-contracts/ss-99/BC-2.99.001.md" 4
  write_probe_registry "$PROBE_TMP/prd-supplements/test-vectors.md" 4

  local out
  out="$(run_tv_counter "$PROBE_TMP/behavioral-contracts" "$PROBE_TMP/prd-supplements/test-vectors.md")"

  local body_total declared
  body_total="$(echo "$out" | grep '^BODY_TOTAL' | awk '{print $2}')"
  declared="$(echo "$out" | grep '^DECLARED_TOTAL' | awk '{print $2}')"

  if [ "$body_total" != "$declared" ]; then
    echo "[SELF-PROBE FAIL] Probe 2: match not recognised (body=${body_total} ≠ declared=${declared} but should be equal)."
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 2: match correctly recognised (body=${body_total} == declared=${declared})."
}

# ── Main TV registry check ────────────────────────────────────────────────────

check_tv_registry() {
  if [ ! -f "$TV_REGISTRY" ]; then
    emit FAIL "TV1: test-vectors.md not found at expected path: $TV_REGISTRY"
    return
  fi

  local raw_output
  raw_output="$(run_tv_counter "$BC_ROOT" "$TV_REGISTRY")"

  # Check for parse errors
  if echo "$raw_output" | grep -q '^ERROR'; then
    local err_msg
    err_msg="$(echo "$raw_output" | grep '^ERROR' | head -1 | cut -d' ' -f2-)"
    emit FAIL "TV1: registry parse error — ${err_msg}"
    return
  fi

  local body_total declared_total bc_count
  body_total="$(echo "$raw_output" | grep '^BODY_TOTAL' | awk '{print $2}')"
  declared_total="$(echo "$raw_output" | grep '^DECLARED_TOTAL' | awk '{print $2}')"
  bc_count="$(echo "$raw_output" | grep '^BODY_BC_COUNT' | awk '{print $2}')"

  echo "  Ground-truth source:   BC body files (## Canonical Test Vectors data rows)"
  echo "  Registry source:       test-vectors.md §Grand-Total declared canonical total"
  echo "  BC files with TVs:     ${bc_count}"
  echo "  Sum from BC bodies:    ${body_total}"
  echo "  Registry declared:     ${declared_total}"

  if [ "$body_total" = "$declared_total" ]; then
    emit PASS "TV1 (test-vectors.md): BC body TV sum (${body_total}) matches registry declared total (${declared_total})"
  else
    local delta=$(( body_total - declared_total ))
    emit FAIL "TV1 (test-vectors.md): BC body TV sum (${body_total}) != registry declared total (${declared_total}); delta=${delta}"
    echo "  Action required: update §Grand-Total in test-vectors.md to match the sum of"
    echo "  data rows in all BC ## Canonical Test Vectors sections."
    echo "  Root cause pattern: Mechanism 3 (arithmetic identity) — column sum may equal"
    echo "  declared total internally while drifting from BC bodies (fix-burst-287 precedent)."
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-tv-registry-count: TV registry ground-truth validation"
echo "  BC_ROOT:    $BC_ROOT"
echo "  REGISTRY:   $TV_REGISTRY"
echo "  Method:     BC body data-row count vs registry §Grand-Total declared canonical total"
echo ""

echo "[SELF-PROBE] Verifying mismatch detection and match recognition..."
probe_mismatch_detected
probe_match_passes
echo "[SELF-PROBE] All probes passed — checks are not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "BLOCKING rules"
echo "════════════════════════════════════════════"
echo ""
echo "── TV1 (test-vectors.md §Grand-Total): BC body count vs declared total ──"
check_tv_registry

echo ""
echo "════════════════════════════════════════════"

echo ""
echo "verify-tv-registry-count: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "RESULT: FAIL"
  exit 1
else
  echo ""
  echo "RESULT: PASS"
  exit 0
fi
