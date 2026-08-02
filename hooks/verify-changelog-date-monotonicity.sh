#!/usr/bin/env bash
# verify-changelog-date-monotonicity.sh — pregolya factory-artifacts wrap guard
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
# Both-forms co-existence detection (WARN, non-blocking — Sections 1 and 2):
#   When a file carries both a frontmatter `changelog:` list AND a body
#   `## Changelog` table, a gate-convention violation is emitted:
#     both-changelog-forms:frontmatter=X.X,body-table=Y.Y
#   Version-parity divergence (versions present in one form but absent from
#   the other) is additionally reported as:
#     both-forms-version-divergence:frontmatter-only=...,body-only=...
#   The frontmatter-only set is the dangerous gap — recent additions not yet
#   backfilled into the body table.  These are WARN not FAIL because the
#   remediation path (retire the body table or backfill it) is a product-owner
#   decision.
#
# Date extraction:
#   The first YYYY-MM-DD substring is extracted from each changelog entry (or
#   Form-B table row).  If an entry contains no such date it is skipped for
#   the adjacent pair comparison and a per-file WARN is emitted.  When NO
#   entry in a changelog carries a date the file emits PASS (nothing to check).
#
# Edge cases — FAIL (blocking, F-P176-E007 class):
#   - yaml-parse-error: frontmatter cannot be parsed — file is UNVERIFIED.
#       An unparseable file must FAIL; it cannot present as a non-failure.
#       Routing: fix the YAML syntax error in the frontmatter.
#   - frontmatter-not-dict: valid YAML but not a mapping — structurally malformed.
#       Routing: correct the frontmatter to be a YAML dict.
#
# Edge cases — WARN-and-skip (non-blocking):
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
# Form-B body table row: | version | YYYY-MM-DD | ... |
FORM_B_ROW_RE  = re.compile(
    r'^\|\s*(\d+\.\d+(?:\.\d+)*)\s*\|\s*(\d{4}-\d{2}-\d{2})\s*\|',
    re.MULTILINE
)

def extract_date(entry_str):
    """Return the first YYYY-MM-DD date in entry_str, or None."""
    m = DATE_RE.search(entry_str)
    return m.group(1) if m else None

def extract_version_str(entry_str):
    """Return the version string at the start of a changelog entry, or None."""
    m = VERSION_RE.match(entry_str.strip())
    return m.group(1) if m else None

def parse_version_tuple(s):
    """Convert '1.10' -> (1, 10) for correct numeric sort."""
    return tuple(int(x) for x in s.split('.'))

def check_date_monotonicity(dated_pairs, ascending):
    """
    Check date monotonicity across a list of (date_or_None, label) pairs.
    ascending=True  — non-decreasing (Form-A BC: oldest first).
    ascending=False — non-increasing (Form-B or non-BC: newest first).
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

def check_form_b_dates(rows_b):
    """
    Validate Form-B body table date monotonicity (DESCENDING: newest row first).
    rows_b: list of (version_str, date_str) from FORM_B_ROW_RE.
    Returns defect string or None (None means valid or single-row table).
    """
    if len(rows_b) <= 1:
        return None
    dated_pairs = [(r[1], r[0]) for r in rows_b]
    return check_date_monotonicity(dated_pairs, ascending=False)

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
        # FAIL (not SKIP/WARN): an unparseable file is UNVERIFIED — cannot certify
        # changelog order for a file whose frontmatter cannot be parsed.
        # Malformed YAML in a spec file is itself a gate violation (F-P176-E007 class).
        print(f"FAIL {filepath} yaml-parse-error:{single_line}")
        continue

    if not isinstance(fm, dict):
        # FAIL (not SKIP/WARN): non-dict frontmatter is structurally malformed.
        print(f"FAIL {filepath} frontmatter-not-dict")
        continue

    # Probe both forms unconditionally — short-circuit fix: Form-B is now
    # always examined regardless of whether Form-A (frontmatter changelog)
    # is present.  Previously, a file with both forms had its body table
    # completely skipped whenever the frontmatter list was non-empty.
    bm = re.search(
        r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)',
        body, re.DOTALL
    )
    rows_b     = FORM_B_ROW_RE.findall(bm.group(1)) if bm else []
    has_form_b = bool(rows_b)
    has_form_a = 'changelog' in fm

    # ── Neither form ──────────────────────────────────────────────────────
    if not has_form_a and not has_form_b:
        fm_version = str(fm.get('version', '')).strip()
        if fm_version == '1.0' or fm_version == '':
            print(f"PASS {filepath}")
        else:
            print(f"SKIP {filepath} no-changelog-version-gt-1.0")
        continue

    # ── Both-forms co-existence detection (WARN, non-blocking) ───────────
    # Gate convention: one file should carry only one changelog form.
    # When both are found, report each form's newest version so the
    # product-owner can decide the remediation path (retire the body table
    # with a banner, or backfill it).
    if has_form_a and has_form_b:
        cl_raw = fm['changelog']
        if isinstance(cl_raw, list) and cl_raw:
            # BC Form-A convention is ASCENDING: the LAST entry is newest.
            fa_newest = extract_version_str(str(cl_raw[-1]).strip()) or '?'
        else:
            fa_newest = '?'
        fb_newest = rows_b[0][0]
        print(f"WARN {filepath} both-changelog-forms:frontmatter={fa_newest},body-table={fb_newest}")

        # Version-parity cross-check: versions present in one form but absent
        # from the other.  The frontmatter-only set is the dangerous gap —
        # recent additions not yet backfilled into the body table.
        fa_versions = set()
        if isinstance(cl_raw, list):
            for e in cl_raw:
                v = extract_version_str(str(e).strip())
                if v:
                    fa_versions.add(v)
        fb_versions = {r[0] for r in rows_b}
        fa_only = sorted(fa_versions - fb_versions, key=parse_version_tuple)
        fb_only = sorted(fb_versions - fa_versions, key=parse_version_tuple)
        if fa_only or fb_only:
            fa_str = ','.join(fa_only) if fa_only else 'none'
            if len(fb_only) > 10:
                fb_str = f"{fb_only[0]}..{fb_only[-1]}({len(fb_only)}-versions)"
            else:
                fb_str = ','.join(fb_only) if fb_only else 'none'
            print(f"WARN {filepath} both-forms-version-divergence:frontmatter-only={fa_str};body-only={fb_str}")

    # ── Form-B only ───────────────────────────────────────────────────────
    if not has_form_a:
        if len(rows_b) <= 1:
            print(f"PASS {filepath}")
            continue
        defect = check_form_b_dates(rows_b)
        if defect:
            print(f"FAIL {filepath} {defect}")
        else:
            print(f"PASS {filepath}")
        continue

    # ── Form-A validation (ASCENDING convention for BC files) ─────────────
    changelog = fm['changelog']
    if not isinstance(changelog, list):
        print(f"SKIP {filepath} changelog-not-list")
        if has_form_b:
            defect_b = check_form_b_dates(rows_b)
            if defect_b:
                print(f"FAIL {filepath} form-b:{defect_b}")
        continue
    if len(changelog) == 0:
        print(f"SKIP {filepath} changelog-empty")
        if has_form_b:
            defect_b = check_form_b_dates(rows_b)
            if defect_b:
                print(f"FAIL {filepath} form-b:{defect_b}")
        continue

    # rev-N format: non-standard naming, cannot validate dates
    has_rev = any(REV_RE.match(str(e).strip()) for e in changelog)
    has_ver = any(VERSION_RE.match(str(e).strip()) for e in changelog)
    if has_rev and not has_ver:
        print(f"WARN {filepath} non-standard-rev-format:skipping-date-check")
        if has_form_b:
            defect_b = check_form_b_dates(rows_b)
            if defect_b:
                print(f"FAIL {filepath} form-b:{defect_b}")
        continue

    if len(changelog) == 1:
        # Single-entry: trivially monotonic
        print(f"PASS {filepath}")
    else:
        dated_pairs = [(extract_date(str(e).strip()), str(e).strip()[:50])
                       for e in changelog]
        no_date_count = sum(1 for d, _ in dated_pairs if d is None)

        if no_date_count == len(changelog):
            # No dates at all — nothing to validate
            print(f"PASS {filepath}")
        else:
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

    # ── Form-B date check when both forms present ─────────────────────────
    # Validates the body table independently on the DESCENDING convention.
    # This was previously invisible when Form-A existed (short-circuit fix).
    if has_form_b:
        defect_b = check_form_b_dates(rows_b)
        if defect_b:
            print(f"FAIL {filepath} form-b:{defect_b}")

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
# Form-B body table row: | version | YYYY-MM-DD | ... |
FORM_B_ROW_RE = re.compile(
    r'^\|\s*(\d+\.\d+(?:\.\d+)*)\s*\|\s*(\d{4}-\d{2}-\d{2})\s*\|',
    re.MULTILINE
)

def parse_version(s):
    return tuple(int(x) for x in s.split('.'))

def extract_version_str(entry_str):
    m = VERSION_RE.match(entry_str.strip())
    return m.group(1) if m else None

def extract_date(entry_str):
    m = DATE_RE.search(entry_str)
    return m.group(1) if m else None

def check_form_b_dates(rows_b):
    """
    Validate Form-B body table date monotonicity (DESCENDING: newest row first).
    rows_b: list of (version_str, date_str) from FORM_B_ROW_RE.
    Returns defect string or None (None means valid or single-row table).
    """
    if len(rows_b) <= 1:
        return None
    for i in range(1, len(rows_b)):
        prev_date = rows_b[i - 1][1]
        curr_date = rows_b[i][1]
        if curr_date > prev_date:
            return (
                f"form-b-date-not-descending:"
                f"row[{i-1}]={prev_date},row[{i}]={curr_date}"
            )
    return None

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
    body    = parts[2]

    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        single_line = str(e).replace('\n', ' | ')
        # FAIL (not SKIP/WARN): unparseable frontmatter = UNVERIFIED (F-P176-E007 class).
        print(f"FAIL {filepath} yaml-parse-error:{single_line}")
        continue

    if not isinstance(fm, dict):
        # FAIL (not SKIP/WARN): non-dict frontmatter is structurally malformed.
        print(f"FAIL {filepath} frontmatter-not-dict")
        continue

    # Skip actual BC files identified by document_type
    if str(fm.get('document_type', '')).strip() == 'behavioral-contract':
        continue  # Handled by Section 1

    # Probe both forms unconditionally — short-circuit fix: Form-B is now
    # always examined regardless of whether Form-A is present.
    # The four known both-forms non-BC files (BC-INDEX, ubiquitous-language-server,
    # bc-authoring-plan, test-vectors) all live in this section, not Section 1.
    bm = re.search(
        r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)',
        body, re.DOTALL
    )
    rows_b     = FORM_B_ROW_RE.findall(bm.group(1)) if bm else []
    has_form_b = bool(rows_b)
    has_form_a = 'changelog' in fm

    # ── Neither form ──────────────────────────────────────────────────────
    if not has_form_a and not has_form_b:
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

    # ── Both-forms co-existence detection (WARN, non-blocking) ───────────
    if has_form_a and has_form_b:
        cl_raw = fm['changelog']
        if isinstance(cl_raw, list) and cl_raw:
            # non-BC Form-A convention is DESCENDING: the FIRST entry is newest.
            fa_newest = extract_version_str(str(cl_raw[0]).strip()) or '?'
        else:
            fa_newest = '?'
        fb_newest = rows_b[0][0]
        print(f"WARN {filepath} both-changelog-forms:frontmatter={fa_newest},body-table={fb_newest}")

        # Version-parity cross-check
        fa_versions = set()
        if isinstance(cl_raw, list):
            for e in cl_raw:
                v = extract_version_str(str(e).strip())
                if v:
                    fa_versions.add(v)
        fb_versions = {r[0] for r in rows_b}
        fa_only = sorted(fa_versions - fb_versions, key=parse_version)
        fb_only = sorted(fb_versions - fa_versions, key=parse_version)
        if fa_only or fb_only:
            fa_str = ','.join(fa_only) if fa_only else 'none'
            if len(fb_only) > 10:
                fb_str = f"{fb_only[0]}..{fb_only[-1]}({len(fb_only)}-versions)"
            else:
                fb_str = ','.join(fb_only) if fb_only else 'none'
            print(f"WARN {filepath} both-forms-version-divergence:frontmatter-only={fa_str};body-only={fb_str}")

    # ── Form-B only for a non-BC file ─────────────────────────────────────
    if not has_form_a:
        defect_b = check_form_b_dates(rows_b)
        if defect_b:
            print(f"FAIL {filepath} {defect_b}")
        else:
            print(f"PASS {filepath}")
        continue

    # ── Form-A validation (DESCENDING for non-BC files) ───────────────────
    changelog = fm['changelog']
    if not isinstance(changelog, list) or len(changelog) == 0:
        print(f"SKIP {filepath} changelog-empty-or-invalid")
        if has_form_b:
            defect_b = check_form_b_dates(rows_b)
            if defect_b:
                print(f"FAIL {filepath} form-b:{defect_b}")
        continue

    # rev-N format (e.g. ADR-001, ADR-006): fall through to date extraction.
    # extract_date() uses DATE_RE (r'\b\d{4}-\d{2}-\d{2}\b') which finds ISO
    # dates inside rev-N entry strings.  Entries without ISO dates are handled
    # by the existing partial-date-check-ok mechanism.  Skipping the whole file
    # was too broad — it classified ADR-001/ADR-006 as UNVERIFIED despite their
    # entries containing ISO dates that CAN be monotonicity-checked.
    # (Section 2 BC-files block keeps its own rev-N skip — BC files should not
    # use rev-N versioning; this widening applies only to non-BC spec files.)

    if len(changelog) == 1:
        print(f"PASS {filepath}")
    else:
        dated_pairs = [(extract_date(str(e).strip()), str(e).strip()[:50])
                       for e in changelog]
        no_date_count = sum(1 for d, _ in dated_pairs if d is None)

        if no_date_count == len(changelog):
            print(f"PASS {filepath}")
        else:
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

    # ── Form-B date check when both forms present ─────────────────────────
    # Validates the body table independently on the DESCENDING convention.
    # Previously invisible when Form-A existed (short-circuit fix).
    if has_form_b:
        defect_b = check_form_b_dates(rows_b)
        if defect_b:
            print(f"FAIL {filepath} form-b:{defect_b}")

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
