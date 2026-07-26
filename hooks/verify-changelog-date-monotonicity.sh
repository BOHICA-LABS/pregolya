#!/usr/bin/env bash
# verify-changelog-date-monotonicity.sh — ferrochain factory-artifacts wrap guard
#
# Validates that YYYY-MM-DD dates embedded in changelog entries are consistent
# with version ordering.  In a DESCENDING (newest-first) changelog the date of
# each entry must be >= the date of the entry below it; in an ASCENDING
# (oldest-first) changelog the date of each entry must be <= the date below it.
# A violation means a later-added entry was inadvertently back-dated.
#
# Two well-known examples motivating this validator (both DESCENDING):
#   entities-graph.md: v1.9 (2026-07-22) sits above v1.8 (2026-07-23)
#   interface-definitions.md: 2.49 (2026-07-22) sits above 2.48 (2026-07-23)
#
# SECTION 1 — BC files (.factory/specs/behavioral-contracts/ss-*/BC-*.md):
# ─────────────────────────────────────────────────────────────────────────
#   Form-A (frontmatter YAML `changelog:` list, ASCENDING convention):
#     Date-Monotonicity: dates extracted from entries must be non-decreasing
#                        top-to-bottom (oldest entry first, newest last).
#
#   Form-B (body `## Changelog` markdown table, DESCENDING convention):
#     Date-Monotonicity: ISO dates in the second pipe-delimited column must be
#                        non-increasing top-to-bottom (newest row first).
#
# SECTION 2 — All other spec files under .factory/specs/ (non-BC):
# ─────────────────────────────────────────────────────────────────
#   Frontmatter `changelog:` list (DESCENDING convention):
#     Date-Monotonicity: dates must be non-increasing top-to-bottom
#                        (newest/highest entry first, oldest entry last).
#
# Date extraction:
#   The first YYYY-MM-DD substring is extracted from each changelog entry (or
#   Form-B table row).  If an entry contains no such date it is skipped for
#   the adjacent pair comparison and a per-file WARN is emitted.  When NO
#   entry in a changelog carries a date the file emits PASS (nothing to check).
#
# Edge cases (WARN-and-skip, not FAIL — matching sibling script behavior):
#   - rev-N format entries (e.g. ADR-001, ADR-006): WARN and skip file.
#   - Single-entry changelog: trivially valid — PASS.
#   - No changelog (version == "1.0"): trivially valid — PASS.
#   - No changelog (version > "1.0"): WARN (non-blocking).
#   - Zero parseable ISO dates across all entries: PASS (no data).
#   - Some entries lack an ISO date: WARN and skip undated pair-members;
#     continue validating dated adjacent pairs.
#
# Note on the frontmatter `timestamp` field:
#   The `timestamp` field records document-creation time and is NOT updated
#   each time a changelog entry is added.  A newest-entry-date > timestamp
#   is therefore normal and is NOT checked here.
#
# Per-file output:
#   [PASS] <short-path>
#   [WARN] <short-path> — <reason>
#   [FAIL] <short-path> — <violation>
#
# Summary line format:
#   verify-changelog-date-monotonicity: PASS=N WARN=N FAIL=N
#
# Exit: 0 if no FAIL lines; 1 if any FAIL.
#
# Integration (state-manager burst protocol — validator #7):
#   Add as a validation step before the atomic factory-artifacts commit:
#     bash .factory/hooks/verify-changelog-date-monotonicity.sh

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BC_GLOB="$FACTORY_DIR/specs/behavioral-contracts/ss-*/BC-*.md"

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

# ── SECTION 1 — BC files ──────────────────────────────────────────────────────

PYTHON_OUTPUT_BC="$(python3 - "$BC_GLOB" <<'PYEOF'
import sys, glob, re, yaml

pattern = sys.argv[1]
files = sorted(glob.glob(pattern))

VERSION_RE     = re.compile(r'^v?(\d+\.\d+(?:\.\d+)*)[\s:(]')
REV_RE         = re.compile(r'^rev-\d+[\s:(]')
DATE_RE        = re.compile(r'\b(\d{4}-\d{2}-\d{2})\b')
# Form-B table row: first column = version, second column = ISO date
FORM_B_ROW_RE  = re.compile(
    r'^\|\s*(\d+\.\d+(?:\.\d+)*)\s*\|\s*(\d{4}-\d{2}-\d{2})\s*\|',
    re.MULTILINE
)

def extract_date(entry_str):
    """Return the first YYYY-MM-DD date found in entry_str, or None."""
    m = DATE_RE.search(entry_str)
    return m.group(1) if m else None

def check_date_monotonicity(dated_pairs, ascending):
    """
    Check date monotonicity for a sequence of (date_or_None, label) tuples.
    ascending=True  — dates must be non-decreasing (oldest first, Form-A BC).
    ascending=False — dates must be non-increasing (newest first, non-BC or Form-B BC).
    Returns the first defect string found, or None.
    """
    for i in range(1, len(dated_pairs)):
        prev_date, _ = dated_pairs[i - 1]
        curr_date, _ = dated_pairs[i]
        if prev_date is None or curr_date is None:
            continue  # Skip undated pair-members
        if ascending:
            if curr_date < prev_date:
                return (
                    f"date-not-ascending:"
                    f"entry[{i-1}]={prev_date},entry[{i}]={curr_date}"
                )
        else:
            if curr_date > prev_date:
                return (
                    f"date-not-descending:"
                    f"entry[{i-1}]={prev_date},entry[{i}]={curr_date}"
                )
    return None

for filepath in files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    parts = content.split('---', 2)
    if len(parts) < 3:
        print(f"SKIP {filepath} no-frontmatter")
        continue

    fm_text = parts[1]
    body    = parts[2]

    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        single_line = str(e).replace('\n', ' | ')
        print(f"SKIP {filepath} yaml-parse-error:{single_line}")
        continue

    if not isinstance(fm, dict):
        print(f"SKIP {filepath} frontmatter-not-dict")
        continue

    # ── Form-B branch (no frontmatter changelog, body ## Changelog table) ─────
    if 'changelog' not in fm:
        bm = re.search(
            r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)',
            body, re.DOTALL
        )
        if bm is None:
            fm_version = str(fm.get('version', '')).strip()
            if fm_version == '1.0' or fm_version == '':
                print(f"PASS {filepath}")
            else:
                print(f"SKIP {filepath} no-changelog-version-gt-1.0")
            continue

        table_text = bm.group(1)
        rows = FORM_B_ROW_RE.findall(table_text)
        # rows: list of (version_str, date_str); Form-B is DESCENDING

        if len(rows) <= 1:
            print(f"PASS {filepath}")
            continue

        # Form-B DESCENDING: dates must be non-increasing row-to-row
        dated_pairs = [(r[1], r[0]) for r in rows]
        defect = check_date_monotonicity(dated_pairs, ascending=False)
        if defect:
            print(f"FAIL {filepath} {defect}")
        else:
            print(f"PASS {filepath}")
        continue

    # ── Form-A branch (frontmatter changelog list, ASCENDING convention) ──────
    changelog = fm['changelog']
    if not isinstance(changelog, list):
        print(f"SKIP {filepath} changelog-not-list")
        continue
    if len(changelog) == 0:
        print(f"SKIP {filepath} changelog-empty")
        continue

    # rev-N format: non-standard naming, cannot validate dates
    has_rev = any(REV_RE.match(str(e).strip()) for e in changelog)
    has_ver = any(VERSION_RE.match(str(e).strip()) for e in changelog)
    if has_rev and not has_ver:
        print(f"WARN {filepath} non-standard-rev-format:skipping-date-check")
        continue

    if len(changelog) == 1:
        # Single-entry: trivially monotonic
        print(f"PASS {filepath}")
        continue

    dated_pairs = [(extract_date(str(e).strip()), str(e).strip()[:50])
                   for e in changelog]
    no_date_count = sum(1 for d, _ in dated_pairs if d is None)

    if no_date_count == len(changelog):
        # No dates at all — nothing to validate
        print(f"PASS {filepath}")
        continue

    # Form-A ASCENDING: dates must be non-decreasing
    defect = check_date_monotonicity(dated_pairs, ascending=True)

    suffix = (f";{no_date_count}-entries-lack-date-skipped"
              if no_date_count > 0 else "")
    if defect:
        print(f"FAIL {filepath} {defect}{suffix}")
    elif no_date_count > 0:
        print(f"WARN {filepath} partial-date-check-ok:{no_date_count}-entries-no-date")
    else:
        print(f"PASS {filepath}")

PYEOF
)"

# ── Process Section 1 output ──────────────────────────────────────────────────

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"
  filepath="${rest%% *}"
  detail="${rest#* }"
  short="${filepath#"$FACTORY_DIR"/}"

  case "$level" in
    PASS) emit PASS "$short" ;;
    FAIL) emit FAIL "$short — $detail" ;;
    SKIP) emit WARN "$short (skipped: $detail)" ;;
    WARN) emit WARN "$short — $detail" ;;
    *)    emit WARN "unexpected parser output: $line" ;;
  esac
done <<< "$PYTHON_OUTPUT_BC"

# ── SECTION 2 — Non-BC spec files (DESCENDING convention) ────────────────────

PYTHON_OUTPUT_NONBC="$(python3 - "$FACTORY_DIR/specs" "$BC_GLOB" <<'PYEOF'
import sys, os, glob, re, yaml

specs_root  = sys.argv[1]
bc_glob_pat = sys.argv[2]

bc_files = set(glob.glob(bc_glob_pat))

VERSION_RE = re.compile(r'^v?(\d+\.\d+(?:\.\d+)*)[\s:(]')
REV_RE     = re.compile(r'^rev-\d+[\s:(]')
DATE_RE    = re.compile(r'\b(\d{4}-\d{2}-\d{2})\b')

def parse_version(s):
    return tuple(int(x) for x in s.split('.'))

def extract_date(entry_str):
    m = DATE_RE.search(entry_str)
    return m.group(1) if m else None

all_files = sorted(glob.glob(os.path.join(specs_root, '**', '*.md'), recursive=True))

for filepath in all_files:
    if filepath in bc_files:
        continue  # Handled by Section 1

    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    parts = content.split('---', 2)
    if len(parts) < 3:
        print(f"SKIP {filepath} no-frontmatter")
        continue

    fm_text = parts[1]

    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        single_line = str(e).replace('\n', ' | ')
        print(f"SKIP {filepath} yaml-parse-error:{single_line}")
        continue

    if not isinstance(fm, dict):
        print(f"SKIP {filepath} frontmatter-not-dict")
        continue

    # Skip actual BC files identified by document_type
    if str(fm.get('document_type', '')).strip() == 'behavioral-contract':
        continue  # Handled by Section 1

    if 'changelog' not in fm:
        fm_version = str(fm.get('version', '')).strip()
        try:
            is_gt_1_0 = (parse_version(fm_version.lstrip('v')) > (1, 0)) if fm_version else False
        except (ValueError, TypeError):
            is_gt_1_0 = False
        if is_gt_1_0:
            print(f"SKIP {filepath} no-changelog-version-gt-1.0")
        else:
            print(f"PASS {filepath}")
        continue

    changelog = fm['changelog']
    if not isinstance(changelog, list) or len(changelog) == 0:
        print(f"SKIP {filepath} changelog-empty-or-invalid")
        continue

    # rev-N format (e.g. ADR-001, ADR-006): non-standard naming — WARN and skip
    has_rev = any(REV_RE.match(str(e).strip()) for e in changelog)
    has_ver = any(VERSION_RE.match(str(e).strip()) for e in changelog)
    if has_rev and not has_ver:
        print(f"WARN {filepath} non-standard-rev-format:skipping-date-check")
        continue

    if len(changelog) == 1:
        print(f"PASS {filepath}")
        continue

    dated_pairs = [(extract_date(str(e).strip()), str(e).strip()[:50])
                   for e in changelog]
    no_date_count = sum(1 for d, _ in dated_pairs if d is None)

    if no_date_count == len(changelog):
        print(f"PASS {filepath}")
        continue

    # Non-BC DESCENDING: dates must be non-increasing top-to-bottom
    defect = None
    for i in range(1, len(dated_pairs)):
        prev_date, _ = dated_pairs[i - 1]
        curr_date, _ = dated_pairs[i]
        if prev_date is None or curr_date is None:
            continue
        if curr_date > prev_date:
            defect = (
                f"date-not-descending:"
                f"entry[{i-1}]={prev_date},entry[{i}]={curr_date}"
            )
            break

    suffix = (f";{no_date_count}-entries-lack-date-skipped"
              if no_date_count > 0 else "")
    if defect:
        print(f"FAIL {filepath} {defect}{suffix}")
    elif no_date_count > 0:
        print(f"WARN {filepath} partial-date-check-ok:{no_date_count}-entries-no-date")
    else:
        print(f"PASS {filepath}")

PYEOF
)"

# ── Process Section 2 output ──────────────────────────────────────────────────

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"
  filepath="${rest%% *}"
  detail="${rest#* }"
  short="${filepath#"$FACTORY_DIR"/}"

  case "$level" in
    PASS) emit PASS "$short" ;;
    FAIL) emit FAIL "$short — $detail" ;;
    SKIP) emit WARN "$short (skipped: $detail)" ;;
    WARN) emit WARN "$short — $detail" ;;
    *)    emit WARN "unexpected parser output: $line" ;;
  esac
done <<< "$PYTHON_OUTPUT_NONBC"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-changelog-date-monotonicity: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
