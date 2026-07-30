#!/usr/bin/env bash
# verify-red-gate-consistency.sh — pregolya factory-artifacts ADVISORY validator
#
# PURPOSE
# ───────
# Verifies consistency between the `red_gate` frontmatter field and `(Red Gate)`
# label usage in the body text of VP files (and any other files carrying a
# red_gate: frontmatter key under .factory/specs/).
#
# Three directions checked:
#   Direction 1 — FALSE→LABEL:      red_gate: false + "(Red Gate)" in live body → WARN
#   Direction 2 — TRUE→ABSENT:      red_gate: true  + no "Red Gate" anywhere in body → WARN
#   Direction 3 — FALSE→LIFECYCLE:  red_gate: false + "Red Gate test" lifecycle table
#                                   rows in body → WARN
#
# Changelog-exclusion: occurrences of "(Red Gate)" inside the YAML frontmatter
# block (lines 1..fm_end inclusive) are intentionally excluded from body scans.
# This correctly grandfathers VP-011's changelog entries that describe their
# own prior removal.  VP-012 and VP-013 have live-body violations; VP-011 does
# not (for Direction 1).  VP-011 DOES have Direction-3 violations.
#
# Confirmed violations driving this check (FIX-BURST-276):
#   VP-012.md — red_gate: false, has "TV-001/002 (Red Gate):" in body     [D1]
#   VP-013.md — red_gate: false, has "TV-005 (Red Gate):" and
#               "§TV-005 (Red Gate)" in body                               [D1]
#   VP-011.md — red_gate: false, has "Red Gate test" lifecycle rows        [D3]
#   VP-012.md — red_gate: false, has "Red Gate test" lifecycle rows        [D3]
#   VP-013.md — red_gate: false, has "Red Gate test" lifecycle rows        [D3]
#   (VP-011.md D1 is correctly grandfathered — "(Red Gate)" only in
#    frontmatter changelog entries, not in live body)
#
# ADVISORY STATUS
# ───────────────
# All findings are WARN (non-blocking) in Wave A of FIX-BURST-276.
# Promotion to blocking after Wave B closes finding IDs:
#   P1D-173-CHECK6-VP012, P1D-173-CHECK6-VP013
# Target burst for promotion: Wave B (VP body fix burst).
#
# EXIT CONTRACT
# ─────────────
# Always exits 0 (advisory — non-blocking). WARN count reflects violations.
#
# Usage:  bash .factory/hooks/verify-red-gate-consistency.sh
# Exit:   0 always (advisory)

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPECS_ROOT="$FACTORY_DIR/specs"

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

# ── Python3 inline processor ──────────────────────────────────────────────────
#
# For every .md file under specs_root carrying a `red_gate:` frontmatter field:
#   - Extract the red_gate value (true/false)
#   - Scan the BODY (lines after the closing frontmatter ---) only
#   - Direction 1: red_gate: false + "(Red Gate)" parenthetical in body → WARN
#   - Direction 2: red_gate: true  + no "Red Gate" anywhere in body → WARN
#   - Direction 3: red_gate: false + "Red Gate test" lifecycle-table rows in body → WARN
#
# A single file may produce findings in multiple directions independently.
# PASS is emitted only when a file is clean in ALL applicable directions.
#
# Output: one line per finding (WARN or PASS):
#   WARN <filepath>  direction=<key> <detail>
#   PASS <filepath>
# Plus a trailing CENSUS line.
#
# Changelog exclusion: "(Red Gate)" text inside the YAML frontmatter block
# is NOT included in the body scan — it is correctly grandfathered.

PYTHON_OUTPUT="$(python3 - "$SPECS_ROOT" <<'PYEOF'
import sys, os, re

specs_root = sys.argv[1]

def parse_frontmatter_end(lines):
    """Return 0-indexed closing '---' line, or -1 if no valid frontmatter."""
    if not lines or lines[0].rstrip() != '---':
        return -1
    for i in range(1, len(lines)):
        if lines[i].rstrip() == '---':
            return i
    return -1

# Gather all .md files under specs_root
all_md_files = []
for root, dirs, files in os.walk(specs_root):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for fn in sorted(files):
        if fn.endswith('.md'):
            all_md_files.append(os.path.join(root, fn))
all_md_files.sort()

RED_GATE_FM_RE    = re.compile(r'^red_gate:\s*(true|false)\s*$')
# Body label pattern: "(Red Gate)" as a parenthetical
BODY_LABEL_RE     = re.compile(r'\(Red Gate\)', re.IGNORECASE)
# Any "Red Gate" text (without parens) for the true→absent direction
BODY_ANY_RE       = re.compile(r'Red Gate', re.IGNORECASE)
# Lifecycle-table rows: "| Red Gate test " at start of a table row in body
# Matches: "| Red Gate test authored |" and "| Red Gate test passes (...) |"
LIFECYCLE_ROW_RE  = re.compile(r'^\s*\|\s*Red Gate test ', re.MULTILINE)

checked = 0
for filepath in all_md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    fm_end = parse_frontmatter_end(lines)
    if fm_end < 0:
        continue  # No frontmatter — file does not carry red_gate field

    # Extract red_gate value from frontmatter only
    red_gate_value = None
    for i in range(1, fm_end):
        m = RED_GATE_FM_RE.match(lines[i])
        if m:
            red_gate_value = m.group(1)   # "true" or "false"
            break

    if red_gate_value is None:
        continue  # No red_gate field — not in scope

    checked += 1
    # Body is EVERYTHING after the closing frontmatter delimiter.
    # This intentionally excludes changelog entries in the frontmatter block
    # (e.g. VP-011 changelog entries that describe prior label removal).
    body = ''.join(lines[fm_end + 1:])

    label_in_body         = bool(BODY_LABEL_RE.search(body))    # "(Red Gate)" present
    redgate_in_body       = bool(BODY_ANY_RE.search(body))       # Any "Red Gate" present
    lifecycle_rows_in_body = bool(LIFECYCLE_ROW_RE.search(body)) # lifecycle table rows

    findings = []

    if red_gate_value == 'false' and label_in_body:
        # Direction 1: red_gate:false but body has parenthetical "(Red Gate)" label
        count = len(BODY_LABEL_RE.findall(body))
        findings.append(
            f"WARN {filepath} direction=false-has-label "
            f"red_gate:false but body contains {count} '(Red Gate)' "
            f"label(s) — remove labels or set red_gate:true"
        )

    if red_gate_value == 'true' and not redgate_in_body:
        # Direction 2: red_gate:true but body has no Red Gate reference at all
        findings.append(
            f"WARN {filepath} direction=true-no-label "
            f"red_gate:true but body contains no 'Red Gate' reference — "
            f"add (Red Gate) label to relevant test vectors or set red_gate:false"
        )

    if red_gate_value == 'false' and lifecycle_rows_in_body:
        # Direction 3: red_gate:false but body contains "Red Gate test" lifecycle rows.
        # red_gate:true files legitimately carry these rows (VP-004/005/009/010).
        # red_gate:false files should not (VP-011/012/013 are violations).
        count = len(LIFECYCLE_ROW_RE.findall(body))
        findings.append(
            f"WARN {filepath} direction=false-lifecycle-rows "
            f"red_gate:false but body contains {count} 'Red Gate test' lifecycle "
            f"row(s) — remove lifecycle rows or set red_gate:true"
        )

    if findings:
        for f in findings:
            print(f)
    else:
        print(f"PASS {filepath}")

# Emit census line for positive coverage
print(f"CENSUS files-with-red_gate-field={checked}")
PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────
#
# Direction extraction: the WARN line format is:
#   WARN <filepath> direction=<key> <rest of message with colons>
#
# Correct extraction: strip "direction=" prefix then strip from first space.
# Do NOT use %%:* (which strips from the first colon in the entire detail
# string, landing in "red_gate:false" rather than after the direction key).

D1_COUNT=0
D2_COUNT=0
D3_COUNT=0

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"

  case "$level" in
    PASS)
      emit PASS "${rest#"$FACTORY_DIR"/}"
      ;;
    WARN)
      filepath="${rest%% *}"
      detail="${rest#* }"
      short="${filepath#"$FACTORY_DIR"/}"
      # Extract direction key: strip "direction=" prefix, then take up to first space.
      # This correctly handles detail strings that contain colons (e.g. "red_gate:false").
      direction="${detail#direction=}"
      direction="${direction%% *}"
      case "$direction" in
        false-has-label)
          D1_COUNT=$((D1_COUNT + 1))
          emit WARN "[ADVISORY] CHECK6-D1 (false→label): $short — ${detail#* }"
          ;;
        true-no-label)
          D2_COUNT=$((D2_COUNT + 1))
          emit WARN "[ADVISORY] CHECK6-D2 (true→absent): $short — ${detail#* }"
          ;;
        false-lifecycle-rows)
          D3_COUNT=$((D3_COUNT + 1))
          emit WARN "[ADVISORY] CHECK6-D3 (false→lifecycle-rows): $short — ${detail#* }"
          ;;
        *)
          emit WARN "[ADVISORY] CHECK6: $short — $detail"
          ;;
      esac
      ;;
    CENSUS)
      echo "  Red Gate consistency census: ${rest}"
      ;;
    *)
      emit WARN "unexpected parser output: $line"
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-red-gate-consistency: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo ""
echo "ADVISORY SUMMARY: Direction-1 (false→label) violations:         $D1_COUNT"
echo "                  Direction-2 (true→absent) violations:          $D2_COUNT"
echo "                  Direction-3 (false→lifecycle-rows) violations:  $D3_COUNT"
echo ""
echo "Promotion path: findings P1D-173-CHECK6-VP012 and P1D-173-CHECK6-VP013"
echo "  must close before this check flips from advisory to blocking."
echo "  Target burst: Wave B (VP body fix burst)."
echo ""
echo "RESULT: PASS (advisory — non-blocking)"
# Always exit 0 — advisory check
exit 0
