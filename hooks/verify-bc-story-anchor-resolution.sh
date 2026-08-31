#!/usr/bin/env bash
# verify-bc-story-anchor-resolution.sh — BC Story Anchor S-TBD resolution gate
#
# PURPOSE
# ───────
# Closes the index-body / source-of-truth-header propagation blind spot exposed
# by F-P2A214-01 (round-51): BCs that STORY-INDEX has assigned to real stories
# (in §BC to Story Coverage Map) must not still carry `S-TBD` in their body
# `## Story Anchor` section.
#
# GROUND TRUTH SOURCE
# ───────────────────
# STORY-INDEX §BC to Story Coverage Map table: each row lists a BC ID and the
# story that implements it. When that story column is a real story ID (S-N.NN or
# S-MAINT-NNN), the corresponding BC file must have that story ID (or a resolved
# form) in its ## Story Anchor section — NOT `S-TBD`.
#
# DETECTION ALGORITHM
# ───────────────────
# 1. Parse STORY-INDEX §BC to Story Coverage Map for rows:
#    `| BC-N.NN.NNN | title | S-N.NN | priority |`
#    Extract BC ID and assigned Story ID.
# 2. For each assigned BC: derive file path (`ss-NN/BC-N.NN.NNN.md`).
# 3. Read the BC file; find `## Story Anchor` section; read first non-blank line.
# 4. If that line starts with `S-TBD`: emit FAIL.
#
# WHAT THIS CATCHES
# ─────────────────
# D-327 class: story-writer adds stories S-1.28 and S-2.12 to STORY-INDEX and
# maps BC-2.02.007/008/009 → S-1.28 and BC-2.04.009/010/011 → S-2.12 in the
# coverage map, but does NOT update the Story Anchor section in those 6 BC files.
# Those BC files still say `S-TBD (assigned at story decomposition — Stage 3)`.
# Without this gate, the S-TBD back-anchors persist across rounds.
#
# SELF-PROBES (POL-31)
# ─────────────────────
# Synthetic fixture pairs exercised before live scan (in isolated TMPDIR):
#   probe_neg_story_anchor_stale: STORY-INDEX assigns BC to S-1.28, BC says S-TBD → FAIL
#   probe_pos_story_anchor_resolved: STORY-INDEX assigns BC to S-1.28, BC says S-1.28 → PASS
# POL-30: probe fixtures live in $TMPDIR, never under .factory/.
#
# EXIT CONTRACT
# ─────────────
# Exit 1 if any FAIL lines are emitted (blocking gate).
# Exit 2 if any self-probe fails (script bug — check is false-green or false-red).
# Exit 0 if FAIL == 0 and all self-probes pass.
#
# TD-VSDD-091: findings cite "§BC to Story Coverage Map" and "§Story Anchor";
# no file:NNN line-number citations.
#
# Usage:  bash .factory/hooks/verify-bc-story-anchor-resolution.sh
# Exit:   1 if FAIL > 0; 2 if self-probe fails; 0 otherwise.
# Integration: wired as BLOCKING in pre-commit-validators.sh.

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
STORY_INDEX_FILE="$FACTORY_DIR/stories/STORY-INDEX.md"
BC_BASE_DIR="$FACTORY_DIR/specs/behavioral-contracts"

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

# ── Python3 scanner ───────────────────────────────────────────────────────────
# Arguments: <story_index_file> <bc_base_dir>
# For each BC in §BC to Story Coverage Map with a real story assignment,
# checks the BC file's ## Story Anchor section for S-TBD.
#
# Output lines:
#   FAIL <bc_id> STORY_INDEX_SAYS=<story> BC_SAYS=S-TBD   — unresolved anchor
#   PASS <bc_id> STORY_INDEX_SAYS=<story> BC_SAYS=<value> — resolved anchor
#   MISSING <bc_id> <reason>                               — BC file not found
#   SKIP <bc_id> <reason>                                  — BC ID not parseable
#   SUMMARY PASS=N FAIL=M MISSING=K                        — totals
run_scanner() {
  local story_index_file="$1"
  local bc_base_dir="$2"
  python3 - "$story_index_file" "$bc_base_dir" <<'PYEOF'
import sys, re, os

story_index_file = sys.argv[1]
bc_base_dir = sys.argv[2]

try:
    with open(story_index_file, 'r', encoding='utf-8') as fh:
        story_lines = fh.readlines()
except OSError as e:
    print(f'PARSE_ERROR cannot read {story_index_file}: {e}')
    sys.exit(0)

# ── Parse STORY-INDEX §BC to Story Coverage Map ───────────────────────────────
# Table rows: | BC-N.NN.NNN | Title | S-N.NN | Priority |
# Only extract rows where:
#   - Column 1 matches BC-ID pattern: BC-\d+\.\d+\.\d+
#   - Column 3 is a real story ID: S-\d+\.\d+ or S-MAINT-\w+
IN_BC_COVERAGE = False
BC_ID_RE    = re.compile(r'^BC-\d+\.\d+\.\d+$')
STORY_ID_RE = re.compile(r'^S-(\d+\.\d+|MAINT-\w+)$')

bc_assignments = {}  # BC ID → Story ID

for line in story_lines:
    s = line.strip()
    if re.match(r'^##\s+BC to Story Coverage Map', s):
        IN_BC_COVERAGE = True
        continue
    if IN_BC_COVERAGE:
        if s.startswith('## ') and 'BC to Story Coverage Map' not in s:
            break
        if not s.startswith('|'):
            continue
        # Split pipe-table row
        cells = [c.strip() for c in s.strip('|').split('|')]
        if len(cells) < 3:
            continue
        bc_id    = cells[0].strip()
        story_id = cells[2].strip()
        # Skip header rows and separator rows
        if not BC_ID_RE.match(bc_id):
            continue
        if not STORY_ID_RE.match(story_id):
            continue
        bc_assignments[bc_id] = story_id

# ── Check each assigned BC's Story Anchor section ────────────────────────────
pass_count   = 0
fail_count   = 0
missing_count = 0

for bc_id in sorted(bc_assignments.keys()):
    story_id = bc_assignments[bc_id]

    # Derive file path: BC-2.NN.NNN → ss-NN/BC-2.NN.NNN.md
    m = re.match(r'^BC-\d+\.(\d+)\.\d+$', bc_id)
    if not m:
        print(f'SKIP {bc_id} — cannot derive subsystem from ID')
        continue
    ss_num = int(m.group(1))
    bc_file = os.path.join(bc_base_dir, f'ss-{ss_num:02d}', f'{bc_id}.md')

    if not os.path.exists(bc_file):
        print(f'MISSING {bc_id} — file not found at ss-{ss_num:02d}/{bc_id}.md')
        missing_count += 1
        continue

    try:
        with open(bc_file, 'r', encoding='utf-8') as fh:
            bc_lines = fh.readlines()
    except OSError as e:
        print(f'MISSING {bc_id} — cannot read {bc_file}: {e}')
        missing_count += 1
        continue

    # Find ## Story Anchor section and read the first non-blank content line
    in_sa = False
    anchor_value = None
    for bc_line in bc_lines:
        bs = bc_line.strip()
        if bs == '## Story Anchor':
            in_sa = True
            continue
        if in_sa:
            if bs.startswith('## '):
                break  # next section; Story Anchor section was empty
            if bs:  # first non-blank line in Story Anchor section
                anchor_value = bs
                break

    if anchor_value is None:
        # No Story Anchor section or empty section — different schema issue;
        # report as MISSING so it's visible but doesn't double-count with
        # verify-bc-frontmatter-schema.sh
        print(f'MISSING {bc_id} — ## Story Anchor section absent or empty (STORY-INDEX says {story_id})')
        missing_count += 1
        continue

    if re.match(r'^S-TBD', anchor_value):
        print(f'FAIL {bc_id} STORY_INDEX_SAYS={story_id} BC_SAYS=S-TBD')
        fail_count += 1
    else:
        print(f'PASS {bc_id} STORY_INDEX_SAYS={story_id} BC_SAYS={anchor_value[:60]}')
        pass_count += 1

print(f'SUMMARY PASS={pass_count} FAIL={fail_count} MISSING={missing_count}')
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

# Write a minimal synthetic STORY-INDEX with given BC→Story assignments.
# Args: outfile bc_id story_id [bc_id2 story_id2 ...]
write_probe_story_index() {
  local outfile="$1"
  shift
  {
    echo "---"
    echo "document_type: story-index"
    echo "---"
    echo ""
    echo "## Story Inventory"
    echo ""
    echo "| ID | Title |"
    echo "|----|-------|"
    echo "| S-1.28 | Synthetic Story |"
    echo ""
    echo "## BC to Story Coverage Map"
    echo ""
    echo "> **All BCs covered.**"
    echo ""
    echo "### SS-02 Synthetic (2 BCs)"
    echo ""
    echo "| BC ID | Title | Story | Priority |"
    echo "|-------|-------|-------|---------|"
    # Write pairs
    while [ "$#" -ge 2 ]; do
      echo "| $1 | Synthetic Title | $2 | P1 |"
      shift 2
    done
  } > "$outfile"
}

# Write a minimal BC file with given Story Anchor value.
# Args: outfile bc_id story_anchor_value
write_probe_bc_file() {
  local outfile="$1"
  local bc_id="$2"
  local anchor_value="$3"
  {
    echo "---"
    echo "document_type: behavioral-contract"
    echo "bc_id: ${bc_id}"
    echo "version: \"1.0\""
    echo "---"
    echo ""
    echo "# ${bc_id}: Synthetic BC for probe"
    echo ""
    echo "## Story Anchor"
    echo ""
    echo "${anchor_value}"
    echo ""
    echo "## VP Anchors"
    echo ""
    echo "- None"
  } > "$outfile"
}

# ── Self-probe 1: Stale S-TBD anchor (exact F-P2A214-01 defect) ─────────────
# STORY-INDEX assigns BC-2.02.007 to S-1.28, BC body says S-TBD → FAIL
probe_neg_story_anchor_stale() {
  init_probe_tmp
  local story_idx="$PROBE_TMP/stories/STORY-INDEX.md"
  local bc_dir="$PROBE_TMP/specs/behavioral-contracts/ss-02"
  local bc_file="$bc_dir/BC-2.02.007.md"

  mkdir -p "$(dirname "$story_idx")" "$bc_dir"
  write_probe_story_index "$story_idx" "BC-2.02.007" "S-1.28"
  write_probe_bc_file "$bc_file" "BC-2.02.007" \
    "S-TBD (assigned at story decomposition — Stage 3)"

  local out
  out="$(run_scanner "$story_idx" "$PROBE_TMP/specs/behavioral-contracts")"

  local fail_line
  fail_line="$(echo "$out" | grep '^FAIL BC-2.02.007' || true)"
  local summary
  summary="$(echo "$out" | grep '^SUMMARY' || true)"

  if [ -z "$fail_line" ]; then
    echo "[SELF-PROBE FAIL] probe_neg_story_anchor_stale: expected FAIL for BC-2.02.007 S-TBD, got: ${out}"
    clean_probe_tmp; return 2
  fi
  echo "[SELF-PROBE PASS] probe_neg_story_anchor_stale: S-TBD correctly detected for BC-2.02.007 (${summary})"
  clean_probe_tmp
}

# ── Self-probe 2: Resolved story anchor (positive case) ──────────────────────
# STORY-INDEX assigns BC-2.02.007 to S-1.28, BC body says S-1.28 → PASS
probe_pos_story_anchor_resolved() {
  init_probe_tmp
  local story_idx="$PROBE_TMP/stories/STORY-INDEX.md"
  local bc_dir="$PROBE_TMP/specs/behavioral-contracts/ss-02"
  local bc_file="$bc_dir/BC-2.02.007.md"

  mkdir -p "$(dirname "$story_idx")" "$bc_dir"
  write_probe_story_index "$story_idx" "BC-2.02.007" "S-1.28"
  write_probe_bc_file "$bc_file" "BC-2.02.007" "S-1.28"

  local out
  out="$(run_scanner "$story_idx" "$PROBE_TMP/specs/behavioral-contracts")"

  local pass_line fail_line
  pass_line="$(echo "$out" | grep '^PASS BC-2.02.007' || true)"
  fail_line="$(echo "$out" | grep '^FAIL' || true)"
  local summary
  summary="$(echo "$out" | grep '^SUMMARY' || true)"

  if [ -n "$fail_line" ]; then
    echo "[SELF-PROBE FAIL] probe_pos_story_anchor_resolved: unexpected FAIL: ${fail_line}"
    clean_probe_tmp; return 2
  fi
  if [ -z "$pass_line" ]; then
    echo "[SELF-PROBE FAIL] probe_pos_story_anchor_resolved: expected PASS for BC-2.02.007, got: ${out}"
    clean_probe_tmp; return 2
  fi
  echo "[SELF-PROBE PASS] probe_pos_story_anchor_resolved: resolved anchor correctly accepted for BC-2.02.007 (${summary})"
  clean_probe_tmp
}

# ── Run self-probes ───────────────────────────────────────────────────────────
echo "── bc-story-anchor-resolution self-probes ──────────────────────────────"

PROBE_FAIL=0

probe_neg_story_anchor_stale      || PROBE_FAIL=$((PROBE_FAIL + 1))
probe_pos_story_anchor_resolved   || PROBE_FAIL=$((PROBE_FAIL + 1))

if [ "$PROBE_FAIL" -gt 0 ]; then
  echo ""
  echo "[SELF-PROBE ABORT] ${PROBE_FAIL} self-probe(s) failed — script has a bug; aborting live scan"
  exit 2
fi

echo ""

# ── Live corpus scan ──────────────────────────────────────────────────────────
echo "── bc-story-anchor-resolution live scan ────────────────────────────────"

if [ ! -f "$STORY_INDEX_FILE" ]; then
  emit WARN "bc-story-anchor-resolution: STORY-INDEX.md not found at ${STORY_INDEX_FILE} — skipping live scan"
  echo ""; echo "PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"; exit 0
fi

if [ ! -d "$BC_BASE_DIR" ]; then
  emit WARN "bc-story-anchor-resolution: BC base dir not found at ${BC_BASE_DIR} — skipping live scan"
  echo ""; echo "PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"; exit 0
fi

SCAN_OUT="$(run_scanner "$STORY_INDEX_FILE" "$BC_BASE_DIR")"

if echo "$SCAN_OUT" | grep -q '^PARSE_ERROR'; then
  err_msg="$(echo "$SCAN_OUT" | grep '^PARSE_ERROR' | sed 's/^PARSE_ERROR //')"
  emit FAIL "bc-story-anchor-resolution: parser error — ${err_msg}"
  echo ""; echo "PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"; exit 1
fi

# Count results from scanner output
SCANNER_PASS=0
SCANNER_FAIL=0
SCANNER_MISSING=0

while IFS= read -r line; do
  case "$line" in
    FAIL\ *)
      bc_id="$(echo "$line" | awk '{print $2}')"
      rest="$(echo "$line" | cut -d' ' -f3-)"
      emit FAIL "bc-story-anchor-resolution: ${bc_id} — §Story Anchor still says S-TBD (${rest}); STORY-INDEX §BC to Story Coverage Map has assigned this BC to a story; update the BC body §Story Anchor"
      SCANNER_FAIL=$((SCANNER_FAIL + 1))
      ;;
    PASS\ *)
      SCANNER_PASS=$((SCANNER_PASS + 1))
      ;;
    MISSING\ *)
      bc_id="$(echo "$line" | awk '{print $2}')"
      reason="$(echo "$line" | cut -d' ' -f3-)"
      emit WARN "bc-story-anchor-resolution: ${bc_id} — ${reason} (non-blocking; file presence checked by other gates)"
      SCANNER_MISSING=$((SCANNER_MISSING + 1))
      ;;
    SUMMARY\ *)
      : # handled via emit counters above
      ;;
  esac
done < <(echo "$SCAN_OUT")

# Aggregate PASSes from scanner into the gate PASS counter
PASS=$((PASS + SCANNER_PASS))

echo ""
echo "  BCs checked: $((SCANNER_PASS + SCANNER_FAIL + SCANNER_MISSING))  Resolved: ${SCANNER_PASS}  S-TBD: ${SCANNER_FAIL}  Missing: ${SCANNER_MISSING}"
echo "  PASS=${PASS}  WARN=${WARN}  FAIL=${FAIL}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "GATE: FAIL — ${FAIL} BC(s) still carry S-TBD in §Story Anchor despite being assigned in STORY-INDEX §BC to Story Coverage Map. Update each BC body §Story Anchor to the assigned story ID."
  exit 1
fi

echo "GATE: PASS — all BCs assigned in STORY-INDEX have resolved §Story Anchor (no S-TBD)."
exit 0
