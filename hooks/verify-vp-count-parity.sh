#!/usr/bin/env bash
# verify-vp-count-parity.sh — BC-INDEX header VP count parity gate
#
# PURPOSE
# ───────
# Closes the index-body / source-of-truth-header propagation blind spot exposed
# by F-P2A214-02 (round-51): BC-INDEX header blockquote VP count fields drift
# from the authoritative VP-INDEX Summary total and from the BC-INDEX §VP Seed
# BCs table body.
#
# GROUND TRUTH SOURCES
# ────────────────────
# Source A — VP-INDEX §Summary table: `| Total VPs | N |`
#   Authoritative count of all registered VPs.
#
# Source B — BC-INDEX §VP Seed BCs table body rows: count of distinct VP-ID
#   values in the first column (VP-014 appears twice → 1 unique). Authoritative
#   VP Seed unique count.
#
# VALIDATION TARGETS
# ──────────────────
# 1. BC-INDEX primary header blockquote bold line `N VPs registered`
#    must equal Source A (VP-INDEX Total VPs).
# 2. BC-INDEX primary header blockquote bold line `N VP Seed`
#    must equal Source B (unique VP IDs in VP Seed BCs table).
# 3. BC-INDEX blockquote detail line `VP-INDEX: N VPs registered`
#    must equal Source A (catches the secondary stale count).
# 4. BC-INDEX §Summary table "VP Seed BCs | N unique VPs" cell
#    must equal Source B (Summary table vs VP Seed BCs table body agreement).
#
# WHAT THIS CATCHES
# ─────────────────
# D-328 class: VP-019 added to VP-INDEX, VP-INDEX Total VPs 19→20.
# BC-INDEX primary header "VPs registered" stayed at 19; "VP Seed" stayed
# at 17 while the VP Seed BCs table gained VP-017/VP-018/VP-019 bringing
# unique VPs to 18; the blockquote detail line still says "17 VPs registered".
#
# SELF-PROBES (POL-31)
# ─────────────────────
# Synthetic fixture pairs exercised before live scan:
#   probe_neg_vps_registered_mismatch: header says 19, VP-INDEX says 20 → FAIL
#   probe_neg_vp_seed_mismatch:        header says 17, VP Seed table unique=18 → FAIL
#   probe_pos_all_agree:               all representations consistent → PASS
# POL-30: probe fixtures live in $TMPDIR, never under .factory/.
#
# EXIT CONTRACT
# ─────────────
# Exit 1 if any FAIL lines are emitted (blocking gate).
# Exit 2 if any self-probe fails (script bug — check is false-green or false-red).
# Exit 0 if FAIL == 0 and all self-probes pass.
#
# TD-VSDD-091: findings cite "§header-blockquote" or "§Summary table :: VP Seed BCs";
# no file:NNN line-number citations.
#
# Usage:  bash .factory/hooks/verify-vp-count-parity.sh
# Exit:   1 if FAIL > 0; 2 if self-probe fails; 0 otherwise.
# Integration: wired as BLOCKING in pre-commit-validators.sh.

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
BC_INDEX_FILE="$FACTORY_DIR/specs/behavioral-contracts/BC-INDEX.md"
VP_INDEX_FILE="$FACTORY_DIR/specs/verification-properties/VP-INDEX.md"

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

# ── Python3 parser ────────────────────────────────────────────────────────────
# Arguments: <bc_index_file> <vp_index_file>
# Output lines (key=value format):
#   BC_HDR_VPS_REGISTERED N    — "N VPs registered" from bold header line
#   BC_HDR_VP_SEED N           — "N VP Seed" from bold header line
#   BC_DETAIL_VPS_REGISTERED N — "VP-INDEX: N VPs registered" from detail line
#   VP_IDX_TOTAL N             — "Total VPs | N" from VP-INDEX §Summary
#   BC_VPSEED_UNIQUE N         — distinct VP IDs in §VP Seed BCs table body
#   BC_VPSEED_ROWS N           — total body rows in §VP Seed BCs table
#   BC_SUMMARY_VPSEED_UNIQUE N — "N unique VPs" from BC-INDEX §Summary VP Seed BCs row
#   PARSE_ERROR <msg>          — if any required field could not be parsed
run_parser() {
  local bc_index_file="$1"
  local vp_index_file="$2"
  python3 - "$bc_index_file" "$vp_index_file" <<'PYEOF'
import sys, re

bc_index_file = sys.argv[1]
vp_index_file = sys.argv[2]

def read_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as fh:
            return fh.readlines()
    except OSError as e:
        print(f'PARSE_ERROR cannot read {path}: {e}')
        sys.exit(0)

bc_lines = read_file(bc_index_file)
vp_lines = read_file(vp_index_file)

# ── BC-INDEX: Primary header blockquote bold line ─────────────────────────────
# Pattern: > **... | N VP Seed | M VPs registered**
# Matches the first line containing both "VP Seed" and "VPs registered"
BC_HDR_VPS_REGISTERED = None
BC_HDR_VP_SEED = None
SEED_RE = re.compile(r'(\d+)\s+VP\s+Seed')
REG_RE  = re.compile(r'(\d+)\s+VPs?\s+registered')

for line in bc_lines:
    s = line.strip()
    if s.startswith('> **') and 'VP Seed' in s and 'registered' in s:
        m_seed = SEED_RE.search(s)
        m_reg  = REG_RE.search(s)
        if m_seed:
            BC_HDR_VP_SEED = int(m_seed.group(1))
        if m_reg:
            BC_HDR_VPS_REGISTERED = int(m_reg.group(1))
        break

# ── BC-INDEX: Blockquote detail line "VP-INDEX: N VPs registered" ─────────────
# Pattern: > VP-INDEX: N VPs registered
BC_DETAIL_VPS_REGISTERED = None
DETAIL_RE = re.compile(r'VP-INDEX:\s*(\d+)\s+VPs?\s+registered')

for line in bc_lines:
    s = line.strip()
    if s.startswith('>') and DETAIL_RE.search(s):
        m = DETAIL_RE.search(s)
        BC_DETAIL_VPS_REGISTERED = int(m.group(1))
        break

# ── BC-INDEX: VP Seed BCs table body ─────────────────────────────────────────
# Section starts at "## VP Seed BCs"; body rows have VP ID in first column.
# Excludes header row "VP ID" and separator rows.
IN_VPSEED = False
vp_ids_seen = set()
vp_seed_rows = 0
VP_ROW_RE = re.compile(r'^\|\s*(VP-[A-Z0-9-]+)\s*\|')

for line in bc_lines:
    s = line.strip()
    if re.match(r'^##\s+VP Seed BCs', s):
        IN_VPSEED = True
        continue
    if IN_VPSEED:
        if s.startswith('## ') and not re.match(r'^##\s+VP Seed BCs', s):
            IN_VPSEED = False
            continue
        m = VP_ROW_RE.match(s)
        if m:
            vp_id = m.group(1)
            # Skip table header row "VP ID"
            if vp_id.upper() == 'VP ID' or vp_id.upper() == 'VP-ID':
                continue
            vp_ids_seen.add(vp_id)
            vp_seed_rows += 1

BC_VPSEED_UNIQUE = len(vp_ids_seen)
BC_VPSEED_ROWS   = vp_seed_rows

# ── BC-INDEX: Summary table VP Seed BCs row ───────────────────────────────────
# Pattern: | VP Seed BCs | N unique VPs ... |
BC_SUMMARY_VPSEED_UNIQUE = None
IN_SUMMARY = False
SUMMARY_VP_RE = re.compile(r'^\|\s*VP Seed BCs\s*\|\s*(\d+)\s+unique VPs')

for line in bc_lines:
    s = line.strip()
    if re.match(r'^##\s+Summary', s):
        IN_SUMMARY = True
        continue
    if IN_SUMMARY:
        if s.startswith('## ') and not re.match(r'^##\s+Summary', s):
            IN_SUMMARY = False
            continue
        m = SUMMARY_VP_RE.match(s)
        if m:
            BC_SUMMARY_VPSEED_UNIQUE = int(m.group(1))
            break

# ── VP-INDEX: Summary table Total VPs row ────────────────────────────────────
# Pattern: | Total VPs | N |
VP_IDX_TOTAL = None
IN_VP_SUMMARY = False
TOTAL_VP_RE = re.compile(r'^\|\s*Total VPs\s*\|\s*(\d+)\s*\|')

for line in vp_lines:
    s = line.strip()
    if re.match(r'^##\s+Summary', s):
        IN_VP_SUMMARY = True
        continue
    if IN_VP_SUMMARY:
        if s.startswith('## ') and not re.match(r'^##\s+Summary', s):
            IN_VP_SUMMARY = False
            continue
        m = TOTAL_VP_RE.match(s)
        if m:
            VP_IDX_TOTAL = int(m.group(1))
            break

# ── Emit results ──────────────────────────────────────────────────────────────
print(f'BC_HDR_VPS_REGISTERED {BC_HDR_VPS_REGISTERED}')
print(f'BC_HDR_VP_SEED {BC_HDR_VP_SEED}')
print(f'BC_DETAIL_VPS_REGISTERED {BC_DETAIL_VPS_REGISTERED}')
print(f'VP_IDX_TOTAL {VP_IDX_TOTAL}')
print(f'BC_VPSEED_UNIQUE {BC_VPSEED_UNIQUE}')
print(f'BC_VPSEED_ROWS {BC_VPSEED_ROWS}')
print(f'BC_SUMMARY_VPSEED_UNIQUE {BC_SUMMARY_VPSEED_UNIQUE}')
PYEOF
}

# ── Cross-validation helper ───────────────────────────────────────────────────
# Usage: check_count LOCATION FIELD_LABEL parsed_val expected_val
check_count() {
  local location="$1" label="$2" parsed="$3" expected="$4"

  if [ "$parsed" = "None" ] || [ -z "$parsed" ]; then
    emit FAIL "vp-count-parity: ${location} :: ${label} — could not parse value (expected ${expected})"
    return
  fi
  if [ "$parsed" -ne "$expected" ] 2>/dev/null; then
    emit FAIL "vp-count-parity: ${location} :: ${label} — found ${parsed}, expected ${expected} (delta $((parsed - expected)))"
  else
    emit PASS "vp-count-parity: ${location} :: ${label} = ${parsed} (matches ground truth)"
  fi
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

# Write a minimal synthetic BC-INDEX with given VP counts.
# Args: outfile hdr_vp_seed hdr_vps_registered detail_vps_registered summary_unique <vp_id...>
# vp_id args: list of VP IDs to put in the VP Seed BCs table (duplicates → duplicate rows)
write_probe_bc_index() {
  local outfile="$1"
  local hdr_seed="$2"       # bold line "N VP Seed"
  local hdr_reg="$3"        # bold line "N VPs registered"
  local detail_reg="$4"     # VP-INDEX detail line "N VPs registered"
  local summary_unique="$5" # Summary table "N unique VPs"
  shift 5
  local vp_ids=("$@")      # VP ID values for table body rows

  {
    echo "---"
    echo "document_type: bc-index"
    echo "---"
    echo ""
    echo "> **50 BCs total | 5 Red Gate | ${hdr_seed} VP Seed | ${hdr_reg} VPs registered**"
    echo ">"
    echo "> VP-INDEX: ${detail_reg} VPs registered (placeholder detail line)."
    echo ""
    echo "## Summary"
    echo ""
    echo "| Metric | Count |"
    echo "|--------|-------|"
    echo "| Total BCs | 50 |"
    echo "| VP Seed BCs | ${summary_unique} unique VPs (placeholder) |"
    echo ""
    echo "## VP Seed BCs"
    echo ""
    echo "| VP ID | BC ID | Title | Proof Method | NE / Security Anchor |"
    echo "|-------|-------|-------|-------------|----------------------|"
    for vp_id in "${vp_ids[@]}"; do
      echo "| ${vp_id} | BC-2.01.001 | Synthetic Title | Kani | NE-1 |"
    done
    echo ""
    echo "## Full BC Catalog"
  } > "$outfile"
}

# Write a minimal synthetic VP-INDEX with given Total VPs count.
write_probe_vp_index() {
  local outfile="$1"
  local total_vps="$2"

  {
    echo "---"
    echo "document_type: vp-index"
    echo "---"
    echo ""
    echo "## Summary"
    echo ""
    echo "| Metric | Count |"
    echo "|--------|-------|"
    echo "| Total VPs | ${total_vps} |"
    echo "| Priority P0 | 6 |"
    echo ""
    echo "## VP Catalog"
  } > "$outfile"
}

# ── Self-probe 1: VPs registered mismatch (exact F-P2A214-02 defect) ──────────
# BC-INDEX header says "19 VPs registered" but VP-INDEX says Total VPs = 20 → FAIL
# Fixture has 18 unique VP IDs (VP-014 dual-anchor = 19 rows); header VP Seed and
# Summary are consistent at 18; only VPs registered is wrong (19 vs 20).
probe_neg_vps_registered_mismatch() {
  init_probe_tmp
  local bc_idx="$PROBE_TMP/BC-INDEX.md"
  local vp_idx="$PROBE_TMP/VP-INDEX.md"

  # 18 unique VPs: VP-001..VP-003, VP-006, VP-006-B, VP-007..VP-010,
  # VP-011..VP-013, VP-014 (×2), VP-015..VP-016, VP-017..VP-019 = 18 unique / 19 rows
  # Header: "18 VP Seed | 19 VPs registered"; VP-INDEX: Total VPs = 20
  write_probe_bc_index "$bc_idx" 18 19 20 18 \
    VP-001 VP-002 VP-003 VP-006 VP-006-B VP-007 VP-008 VP-009 VP-010 \
    VP-011 VP-012 VP-013 VP-014 VP-014 VP-015 VP-016 VP-017 VP-018 VP-019

  write_probe_vp_index "$vp_idx" 20

  local out
  out="$(run_parser "$bc_idx" "$vp_idx")"

  local hdr_reg vp_total
  hdr_reg="$(echo "$out" | grep '^BC_HDR_VPS_REGISTERED ' | awk '{print $2}')"
  vp_total="$(echo "$out" | grep '^VP_IDX_TOTAL ' | awk '{print $2}')"

  if [ "$hdr_reg" != "19" ]; then
    echo "[SELF-PROBE FAIL] probe_neg_vps_registered_mismatch: expected BC_HDR_VPS_REGISTERED=19, got '${hdr_reg}'"
    clean_probe_tmp; return 2
  fi
  if [ "$vp_total" != "20" ]; then
    echo "[SELF-PROBE FAIL] probe_neg_vps_registered_mismatch: expected VP_IDX_TOTAL=20, got '${vp_total}'"
    clean_probe_tmp; return 2
  fi
  if [ "$hdr_reg" -eq "$vp_total" ] 2>/dev/null; then
    echo "[SELF-PROBE FAIL] probe_neg_vps_registered_mismatch: mismatch NOT detected (hdr_reg=${hdr_reg} == vp_total=${vp_total})"
    clean_probe_tmp; return 2
  fi
  echo "[SELF-PROBE PASS] probe_neg_vps_registered_mismatch: BC_HDR_VPS_REGISTERED=${hdr_reg} != VP_IDX_TOTAL=${vp_total} — mismatch correctly detectable"
  clean_probe_tmp
}

# ── Self-probe 2: VP Seed count mismatch (exact F-P2A214-02 VP Seed sub-defect) ─
# BC-INDEX header says "17 VP Seed" but VP Seed BCs table has 18 unique VPs → FAIL
# Fixture has 18 unique VP IDs; VPs registered and Summary are consistent at 20/18;
# only the bold header VP Seed count is wrong (17 vs 18).
probe_neg_vp_seed_mismatch() {
  init_probe_tmp
  local bc_idx="$PROBE_TMP/BC-INDEX.md"
  local vp_idx="$PROBE_TMP/VP-INDEX.md"

  # 18 unique VP IDs (VP-014 dual-anchor = 19 rows); header says "17 VP Seed" (stale)
  write_probe_bc_index "$bc_idx" 17 20 20 18 \
    VP-001 VP-002 VP-003 VP-006 VP-006-B VP-007 VP-008 VP-009 VP-010 \
    VP-011 VP-012 VP-013 VP-014 VP-014 VP-015 VP-016 VP-017 VP-018 VP-019

  write_probe_vp_index "$vp_idx" 20

  local out
  out="$(run_parser "$bc_idx" "$vp_idx")"

  local hdr_seed vpseed_unique
  hdr_seed="$(echo "$out" | grep '^BC_HDR_VP_SEED ' | awk '{print $2}')"
  vpseed_unique="$(echo "$out" | grep '^BC_VPSEED_UNIQUE ' | awk '{print $2}')"

  if [ "$hdr_seed" != "17" ]; then
    echo "[SELF-PROBE FAIL] probe_neg_vp_seed_mismatch: expected BC_HDR_VP_SEED=17, got '${hdr_seed}'"
    clean_probe_tmp; return 2
  fi
  if [ "$vpseed_unique" != "18" ]; then
    echo "[SELF-PROBE FAIL] probe_neg_vp_seed_mismatch: expected BC_VPSEED_UNIQUE=18, got '${vpseed_unique}'"
    clean_probe_tmp; return 2
  fi
  if [ "$hdr_seed" -eq "$vpseed_unique" ] 2>/dev/null; then
    echo "[SELF-PROBE FAIL] probe_neg_vp_seed_mismatch: mismatch NOT detected (hdr_seed=${hdr_seed} == vpseed_unique=${vpseed_unique})"
    clean_probe_tmp; return 2
  fi
  echo "[SELF-PROBE PASS] probe_neg_vp_seed_mismatch: BC_HDR_VP_SEED=${hdr_seed} != BC_VPSEED_UNIQUE=${vpseed_unique} — mismatch correctly detectable"
  clean_probe_tmp
}

# ── Self-probe 3: All representations agree (positive case) ───────────────────
# BC-INDEX header says "18 VP Seed | 20 VPs registered", VP-INDEX says 20,
# VP Seed BCs table has 18 unique VPs → all checks pass
probe_pos_all_agree() {
  init_probe_tmp
  local bc_idx="$PROBE_TMP/BC-INDEX.md"
  local vp_idx="$PROBE_TMP/VP-INDEX.md"

  # 18 unique VPs (VP-014 dual-anchor = 19 rows); all counts consistent
  write_probe_bc_index "$bc_idx" 18 20 20 18 \
    VP-001 VP-002 VP-003 VP-006 VP-006-B VP-007 VP-008 VP-009 VP-010 \
    VP-011 VP-012 VP-013 VP-014 VP-014 VP-015 VP-016 VP-017 VP-018 VP-019

  write_probe_vp_index "$vp_idx" 20

  local out
  out="$(run_parser "$bc_idx" "$vp_idx")"

  local hdr_seed hdr_reg detail_reg vp_total vpseed_unique summary_unique
  hdr_seed="$(echo "$out" | grep '^BC_HDR_VP_SEED ' | awk '{print $2}')"
  hdr_reg="$(echo "$out" | grep '^BC_HDR_VPS_REGISTERED ' | awk '{print $2}')"
  detail_reg="$(echo "$out" | grep '^BC_DETAIL_VPS_REGISTERED ' | awk '{print $2}')"
  vp_total="$(echo "$out" | grep '^VP_IDX_TOTAL ' | awk '{print $2}')"
  vpseed_unique="$(echo "$out" | grep '^BC_VPSEED_UNIQUE ' | awk '{print $2}')"
  summary_unique="$(echo "$out" | grep '^BC_SUMMARY_VPSEED_UNIQUE ' | awk '{print $2}')"

  local failed=0
  if [ "$hdr_seed" != "18" ] || [ "$vpseed_unique" != "18" ] || [ "$summary_unique" != "18" ]; then
    echo "[SELF-PROBE FAIL] probe_pos_all_agree: VP Seed mismatch — hdr=${hdr_seed} unique=${vpseed_unique} summary=${summary_unique} (all expected 18)"
    failed=1
  fi
  if [ "$hdr_reg" != "20" ] || [ "$vp_total" != "20" ] || [ "$detail_reg" != "20" ]; then
    echo "[SELF-PROBE FAIL] probe_pos_all_agree: VPs registered mismatch — hdr=${hdr_reg} vp_idx=${vp_total} detail=${detail_reg} (all expected 20)"
    failed=1
  fi
  if [ "$failed" -eq 0 ]; then
    echo "[SELF-PROBE PASS] probe_pos_all_agree: VP Seed=18/18/18, VPs registered=20/20/20 — all consistent"
  fi
  clean_probe_tmp
  return "$failed"
}

# ── Run self-probes ───────────────────────────────────────────────────────────
echo "── vp-count-parity self-probes ─────────────────────────────────────────"

PROBE_FAIL=0

probe_neg_vps_registered_mismatch || PROBE_FAIL=$((PROBE_FAIL + 1))
probe_neg_vp_seed_mismatch        || PROBE_FAIL=$((PROBE_FAIL + 1))
probe_pos_all_agree               || PROBE_FAIL=$((PROBE_FAIL + 1))

if [ "$PROBE_FAIL" -gt 0 ]; then
  echo ""
  echo "[SELF-PROBE ABORT] ${PROBE_FAIL} self-probe(s) failed — script has a bug; aborting live scan"
  exit 2
fi

echo ""

# ── Live corpus scan ──────────────────────────────────────────────────────────
echo "── vp-count-parity live scan ───────────────────────────────────────────"

if [ ! -f "$BC_INDEX_FILE" ]; then
  emit WARN "vp-count-parity: BC-INDEX.md not found at ${BC_INDEX_FILE} — skipping live scan"
  echo ""; echo "PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"; exit 0
fi

if [ ! -f "$VP_INDEX_FILE" ]; then
  emit WARN "vp-count-parity: VP-INDEX.md not found at ${VP_INDEX_FILE} — skipping live scan"
  echo ""; echo "PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"; exit 0
fi

PARSE_OUT="$(run_parser "$BC_INDEX_FILE" "$VP_INDEX_FILE")"

if echo "$PARSE_OUT" | grep -q '^PARSE_ERROR'; then
  err_msg="$(echo "$PARSE_OUT" | grep '^PARSE_ERROR' | sed 's/^PARSE_ERROR //')"
  emit FAIL "vp-count-parity: parser error — ${err_msg}"
  echo ""; echo "PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"; exit 1
fi

get_val() { echo "$PARSE_OUT" | grep "^$1 " | awk '{print $2}'; }

BC_HDR_VPS_REGISTERED="$(get_val BC_HDR_VPS_REGISTERED)"
BC_HDR_VP_SEED="$(get_val BC_HDR_VP_SEED)"
BC_DETAIL_VPS_REGISTERED="$(get_val BC_DETAIL_VPS_REGISTERED)"
VP_IDX_TOTAL="$(get_val VP_IDX_TOTAL)"
BC_VPSEED_UNIQUE="$(get_val BC_VPSEED_UNIQUE)"
BC_VPSEED_ROWS="$(get_val BC_VPSEED_ROWS)"
BC_SUMMARY_VPSEED_UNIQUE="$(get_val BC_SUMMARY_VPSEED_UNIQUE)"

echo "  Ground truth (VP-INDEX §Summary):"
echo "    Total VPs = ${VP_IDX_TOTAL}"
echo "  Ground truth (BC-INDEX §VP Seed BCs table):"
echo "    Unique VP IDs = ${BC_VPSEED_UNIQUE}  Body rows = ${BC_VPSEED_ROWS}"
echo ""

# ── Check 1: VPs registered in header == VP-INDEX Total VPs ──────────────────
echo "  Check 1 — §header-blockquote :: VPs registered vs VP-INDEX Total VPs:"
check_count "§header-blockquote" "VPs registered (bold line)" \
  "$BC_HDR_VPS_REGISTERED" "$VP_IDX_TOTAL"

# ── Check 2: VP Seed in header == unique VP IDs in VP Seed BCs table ──────────
echo ""
echo "  Check 2 — §header-blockquote :: VP Seed vs §VP Seed BCs table unique IDs:"
check_count "§header-blockquote" "VP Seed (bold line)" \
  "$BC_HDR_VP_SEED" "$BC_VPSEED_UNIQUE"

# ── Check 3: Detail line VPs registered == VP-INDEX Total VPs (if present) ───
echo ""
echo "  Check 3 — §header-blockquote :: VP-INDEX detail line VPs registered:"
if [ "$BC_DETAIL_VPS_REGISTERED" != "None" ] && [ -n "$BC_DETAIL_VPS_REGISTERED" ]; then
  check_count "§header-blockquote" "VP-INDEX detail line VPs registered" \
    "$BC_DETAIL_VPS_REGISTERED" "$VP_IDX_TOTAL"
else
  emit WARN "vp-count-parity: §header-blockquote :: VP-INDEX detail line not found (non-blocking)"
fi

# ── Check 4: BC-INDEX Summary unique VPs == VP Seed BCs table unique IDs ──────
echo ""
echo "  Check 4 — §Summary table :: VP Seed BCs unique count vs table body:"
check_count "§Summary table :: VP Seed BCs" "unique VPs" \
  "$BC_SUMMARY_VPSEED_UNIQUE" "$BC_VPSEED_UNIQUE"

# ── Final summary ──────────────────────────────────────────────────────────────
echo ""
echo "  PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "GATE: FAIL — ${FAIL} VP count parity finding(s) — BC-INDEX header VP counts drift from VP-INDEX authoritative total; update BC-INDEX header blockquote VP counts to match VP-INDEX §Summary Total VPs and §VP Seed BCs table unique-VP count."
  exit 1
fi

echo "GATE: PASS — all BC-INDEX VP count representations agree with VP-INDEX §Summary and §VP Seed BCs table."
exit 0
