#!/usr/bin/env bash
# verify-form-a-changelog-direction.sh — ferrochain factory-artifacts wrap guard
#
# SECTION 1 — BC files (.factory/specs/behavioral-contracts/ss-*/BC-*.md):
# ─────────────────────────────────────────────────────────────────────────
# Two changelog forms are supported — each has its own direction convention:
#
#   Form-A (frontmatter YAML `changelog:` list):
#     Rule 1 (ASCENDING): Entries must be in STRICTLY ASCENDING version
#             order — oldest (lowest) entry at the top, newest (highest) at the
#             bottom.  Equal consecutive versions also fail (must be strictly >).
#     Rule 2 (VERSION-MATCH): The frontmatter `version:` field must equal the
#             version of the LAST (newest, bottom) changelog entry.
#
#   Form-B (body `## Changelog` markdown table, e.g. BC-2.07.002/011/012):
#     Rule 3 (DESCENDING): Table rows must be in STRICTLY DESCENDING version
#             order — newest (highest) version at the top, oldest (lowest) at
#             the bottom.  Equal consecutive versions also fail.
#     Rule 4 (VERSION-MATCH): The frontmatter `version:` field must equal the
#             version of the FIRST (newest, top) table row.
#     Single-row tables are trivially valid (monotonicity satisfied).
#
#   No changelog (version == "1.0", neither Form-A nor Form-B present):
#     Treated as trivially valid — initial-authoring BC requires no history.
#     Emits PASS.
#
#   Both forms present (both Form-A and Form-B in the same file):
#     Gate convention requires one form per file.  Each form is validated
#     independently against its own direction rule.  Co-existence emits a WARN
#     (non-blocking) so the product-owner can decide on remediation.
#
# SECTION 2 — All other spec files under .factory/specs/ (non-BC):
# ─────────────────────────────────────────────────────────────────
# Covers: domain-spec/, architecture/ (incl. decisions/), prd-supplements/,
#         verification-properties/, BC-INDEX.md, L2-INDEX.md, ARCH-INDEX.md,
#         VP-INDEX.md, prd.md, product-brief.md, and any other .md with a
#         frontmatter `changelog:` list that is NOT a behavioral-contract.
#
#   Rule 5 (DESCENDING): Entries must be in STRICTLY DESCENDING version order —
#           newest (highest) entry at the top, oldest (lowest) at the bottom.
#           Equal consecutive versions also fail (must be strictly >).
#   Rule 6 (VERSION-MATCH): The frontmatter `version:` field must equal the
#           version of the FIRST (newest, top) changelog entry.
#   Entries with optional "v" prefix (e.g. "v1.8 (...)") are accepted; the "v"
#   is stripped before numeric comparison.
#   Entries using a non-version-number prefix (e.g. "rev-2 (...)") cannot be
#   validated — the file is emitted as WARN (non-blocking) for that format.
#
#   Both-forms detection (WARN, non-blocking):
#     Non-BC files that carry both a frontmatter `changelog:` list AND a body
#     `## Changelog` table are emitted as WARN (same co-existence policy as
#     Section 1 above).  Each form is validated independently.
#
# Empirical verification (FIX-BURST-263):
#   Convention confirmed DESCENDING/FIRST across 4+ files per non-BC class:
#   domain-spec (entities-server v1.14, capabilities-p1-p2 v1.14, ARCH-INDEX
#   v1.11, entities-graph v1.10), architecture/decisions (ADR-019 v1.6,
#   ADR-018 v1.5, ADR-020 v1.8), prd-supplements (error-taxonomy v1.40,
#   nfr-catalog v1.7), verification-properties (VP-001 v1.3, VP-011 v1.4,
#   VP-INDEX v1.6).  BC files confirmed ASCENDING/LAST (Form-A).
#
# Per-class direction summary (canonical reference):
#   behavioral-contract (ss-*/BC-*.md) : Form-A ASCENDING, version == LAST entry
#   domain-spec/*.md                    : DESCENDING, version == FIRST entry
#   architecture/**/*.md                : DESCENDING, version == FIRST entry
#   prd-supplements/*.md                : DESCENDING, version == FIRST entry
#   verification-properties/*.md        : DESCENDING, version == FIRST entry
#   indexes (BC-INDEX, L2-INDEX, etc.)  : DESCENDING, version == FIRST entry
#   prd.md, product-brief.md            : DESCENDING, version == FIRST entry
#
# Common notes (both sections):
#   - Frontmatter extracted between the first and second '---' delimiter.
#   - PyYAML (python3 -c "import yaml") used for robust YAML parsing; avoids
#     fragile line-by-line awk that breaks on embedded colons, braces, etc.
#   - Version numbers compared as integer tuples (so 1.10 > 1.9 correctly).
#   - Files lacking a 'version:' key are WARN (non-blocking).
#   - Files lacking a changelog AND version == "1.0": PASS (trivially valid).
#   - Files lacking a changelog AND version > "1.0": WARN (non-blocking).
#
# Usage:  bash .factory/hooks/verify-form-a-changelog-direction.sh
# Exit:   0 if no FAIL lines; 1 if any FAIL.
#
# Integration (state-manager burst protocol):
#   Add as the last validation step before the atomic factory-artifacts commit:
#     bash .factory/hooks/verify-form-a-changelog-direction.sh

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

# ── Python3 inline parser — Section 1 (BC files) ─────────────────────────────
#
# Produces one or more output lines per BC file in the format:
#   PASS <filepath>
#   FAIL <filepath> <defect-description>
#   SKIP <filepath> <reason>
#   WARN <filepath> <reason>
#
# Multiple output lines per file are possible when both forms are present:
# the WARN for co-existence precedes the Form-A and Form-B validation results.

PYTHON_OUTPUT="$(python3 - "$BC_GLOB" <<'PYEOF'
import sys, glob, re, yaml

pattern = sys.argv[1]
files = sorted(glob.glob(pattern))

VERSION_RE = re.compile(r'^(\d+\.\d+(?:\.\d+)*)[\s:(]')
# Form-B body table: match version number in the first pipe-delimited column
FORM_B_VERSION_RE = re.compile(r'^\|\s*(\d+\.\d+(?:\.\d+)*)\s*\|', re.MULTILINE)

def parse_version(s):
    """Convert '1.3' or '1.10' to tuple of ints for numeric comparison."""
    return tuple(int(x) for x in s.split('.'))

def check_form_b(filepath, fm, body):
    """
    Validate a Form-B body ## Changelog table (DESCENDING convention):
      Rule 3: rows must be strictly descending (newest first, oldest last).
      Rule 4: frontmatter version == first (top/newest) row version.
    Returns a list of defect strings, or [] for PASS.
    Special return value None means no ## Changelog section found.
    """
    bm = re.search(
        r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)',
        body,
        re.DOTALL
    )
    if bm is None:
        return None  # No Form-B section

    table_text = bm.group(1)
    versions = FORM_B_VERSION_RE.findall(table_text)

    if len(versions) == 0:
        return []  # Empty table — treat as trivially valid

    defects = []

    if len(versions) >= 2:
        nums = [parse_version(v) for v in versions]
        # Rule 3: strictly descending
        for i in range(1, len(nums)):
            prev, curr = nums[i - 1], nums[i]
            if curr >= prev:
                direction = 'ascending' if nums[-1] > nums[0] else 'non-monotonic'
                defects.append(f"form-b-not-descending({direction}):{','.join(versions)}")
                break

    # Rule 4: frontmatter version == first (top/newest) row version
    fm_version = str(fm.get('version', '')).strip()
    first_version = versions[0]
    if fm_version and fm_version != first_version:
        defects.append(
            f"form-b-version-mismatch:frontmatter={fm_version},first-entry={first_version}"
        )

    return defects

def get_form_b_first_version(body):
    """Return the first (newest) version from the body ## Changelog table, or None."""
    bm = re.search(
        r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)',
        body, re.DOTALL
    )
    if bm is None:
        return None
    versions = FORM_B_VERSION_RE.findall(bm.group(1))
    return versions[0] if versions else None

for filepath in files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    # Extract frontmatter between first and second '---'
    parts = content.split('---', 2)
    if len(parts) < 3:
        print(f"SKIP {filepath} no-frontmatter")
        continue

    fm_text = parts[1]
    body = parts[2]

    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        # Flatten multi-line YAMLError to single line to keep bash loop clean
        single_line = str(e).replace('\n', ' | ')
        print(f"SKIP {filepath} yaml-parse-error:{single_line}")
        continue

    if not isinstance(fm, dict):
        print(f"SKIP {filepath} frontmatter-not-dict")
        continue

    # Skip non-BC documents that happen to match the glob (defensive)
    doc_type = fm.get('document_type', '')
    if doc_type not in ('behavioral-contract', ''):
        print(f"SKIP {filepath} document_type={doc_type}")
        continue

    # Probe both forms unconditionally — short-circuit fix: Form-B is now
    # always examined regardless of whether Form-A (frontmatter changelog)
    # is present.  Previously, a both-forms BC file had Form-B silently
    # skipped when the frontmatter list was non-empty.
    form_b_result = check_form_b(filepath, fm, body)
    has_form_b    = form_b_result is not None
    has_form_a    = 'changelog' in fm

    # ── Form-B only (or neither) ──────────────────────────────────────────
    if not has_form_a:
        if has_form_b:
            # Form-B section found — report defects or PASS
            if form_b_result:
                print(f"FAIL {filepath} {'; '.join(form_b_result)}")
            else:
                print(f"PASS {filepath}")
        else:
            # Neither Form-A nor Form-B changelog present.
            fm_version = str(fm.get('version', '')).strip()
            if fm_version == '1.0' or fm_version == '':
                print(f"PASS {filepath}")
            else:
                print(f"SKIP {filepath} no-changelog-version-gt-1.0")
        continue

    # ── Form-A validation ──────────────────────────────────────────────────
    changelog = fm['changelog']
    if not isinstance(changelog, list):
        print(f"SKIP {filepath} changelog-not-list")
        if has_form_b:
            fb_newest = get_form_b_first_version(body) or '?'
            print(f"WARN {filepath} both-changelog-forms:frontmatter=?(invalid-type),body-table={fb_newest}")
            if form_b_result:
                print(f"FAIL {filepath} {'; '.join(form_b_result)}")
        continue

    if len(changelog) == 0:
        print(f"SKIP {filepath} changelog-empty")
        if has_form_b:
            fb_newest = get_form_b_first_version(body) or '?'
            print(f"WARN {filepath} both-changelog-forms:frontmatter=?(empty),body-table={fb_newest}")
            if form_b_result:
                print(f"FAIL {filepath} {'; '.join(form_b_result)}")
        continue

    # Extract version from each entry
    versions = []
    parse_errors = []
    for entry in changelog:
        entry_str = str(entry).strip()
        m = VERSION_RE.match(entry_str)
        if m:
            versions.append(m.group(1))
        else:
            parse_errors.append(entry_str[:60])

    if parse_errors:
        print(f"WARN {filepath} could-not-parse-version-in:{parse_errors[0]!r}")
        if has_form_b:
            fb_newest = get_form_b_first_version(body) or '?'
            print(f"WARN {filepath} both-changelog-forms:frontmatter=?(parse-error),body-table={fb_newest}")
            if form_b_result:
                print(f"FAIL {filepath} {'; '.join(form_b_result)}")
        continue

    # Rule 1: strictly ascending (oldest first, newest last)
    ascending_fail = None
    for i in range(1, len(versions)):
        prev = parse_version(versions[i - 1])
        curr = parse_version(versions[i])
        if curr <= prev:
            ascending_fail = (versions[i - 1], versions[i])
            break

    # Rule 2: frontmatter version == last entry's version
    fm_version = str(fm.get('version', '')).strip()
    last_version = versions[-1]
    version_mismatch = (fm_version != last_version) if fm_version else None

    defects = []
    if ascending_fail:
        direction = 'descending' if parse_version(versions[0]) > parse_version(versions[-1]) else 'non-monotonic'
        defects.append(f"{direction}:{','.join(versions)}")
    if version_mismatch:
        defects.append(f"version-mismatch:frontmatter={fm_version},last-entry={last_version}")

    # ── Both-forms co-existence WARN and Form-B direction check ──────────
    # Emitted before the Form-A result so the both-forms context precedes
    # any FAIL line.  This was previously invisible when Form-A existed
    # (short-circuit fix).
    # Rule 4 (Form-B version-match) is NOT emitted as FAIL here: when Form-A
    # is present it is the authoritative version source, so the frontmatter
    # version legitimately differs from the Form-B first row while the body
    # table backfill is pending.  Only direction violations (Rule 3) are FAIL.
    if has_form_b:
        fa_newest = versions[-1]  # BC ASCENDING: last entry is newest
        fb_newest = get_form_b_first_version(body) or '?'
        print(f"WARN {filepath} both-changelog-forms:frontmatter={fa_newest},body-table={fb_newest}")
        dir_defects = [d for d in (form_b_result or []) if 'version-mismatch' not in d]
        if dir_defects:
            print(f"FAIL {filepath} form-b:{'; '.join(dir_defects)}")

    if defects:
        print(f"FAIL {filepath} {'; '.join(defects)}")
    else:
        print(f"PASS {filepath}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"
  filepath="${rest%% *}"
  detail="${rest#* }"
  # Strip leading FACTORY_DIR for readability
  short="${filepath#"$FACTORY_DIR"/}"

  case "$level" in
    PASS)
      emit PASS "$short"
      ;;
    FAIL)
      emit FAIL "$short — $detail"
      ;;
    SKIP)
      # No changelog field is a WARN (non-blocking) — not an error
      emit WARN "$short (skipped: $detail)"
      ;;
    WARN)
      emit WARN "$short — $detail"
      ;;
    *)
      emit WARN "unexpected parser output: $line"
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── SECTION 2 — Non-BC spec files (DESCENDING convention) ────────────────────
#
# Validates frontmatter `changelog:` list direction for ALL .md files under
# .factory/specs/ that are NOT behavioral-contract documents (BC files are
# handled by Section 1 above).  Also detects Form-B body tables in non-BC
# files and emits WARN when both forms co-exist in the same file.

PYTHON_OUTPUT_NONBC="$(python3 - "$FACTORY_DIR/specs" "$BC_GLOB" <<'PYEOF'
import sys, os, glob, re, yaml

specs_root    = sys.argv[1]
bc_glob_pat   = sys.argv[2]

# Build exclusion set: BC files handled by Section 1 above
bc_files = set(glob.glob(bc_glob_pat))

# Version entry RE: optional leading 'v', then X.Y or X.Y.Z, then whitespace/colon/paren
VERSION_RE = re.compile(r'^v?(\d+\.\d+(?:\.\d+)*)[\s:(]')
# Non-version prefix RE: entries like "rev-2 (...)" that cannot be version-compared
REV_RE = re.compile(r'^rev-\d+[\s:(]')
# Form-B body table version: first pipe-delimited column
FORM_B_VERSION_RE = re.compile(r'^\|\s*(\d+\.\d+(?:\.\d+)*)\s*\|', re.MULTILINE)

def parse_version(s):
    """Convert '1.3' or '1.10' to tuple of ints for numeric comparison."""
    return tuple(int(x) for x in s.split('.'))

def check_form_b_direction_only(fb_versions):
    """
    Check Form-B body table direction (Rule 3 only — no version-match Rule 4).
    Used for both-forms files where Form-A is the authoritative version source.
    Rule 3: rows must be strictly descending (newest first, oldest last).
    Returns list of direction defect strings or [].
    """
    if len(fb_versions) < 2:
        return []
    defects = []
    nums = [parse_version(v) for v in fb_versions]
    for i in range(1, len(nums)):
        prev, curr = nums[i - 1], nums[i]
        if curr >= prev:
            direction = 'ascending' if nums[-1] > nums[0] else 'non-monotonic'
            defects.append(f"form-b-not-descending({direction}):{','.join(fb_versions)}")
            break
    return defects

all_files = sorted(glob.glob(os.path.join(specs_root, '**', '*.md'), recursive=True))

for filepath in all_files:
    if filepath in bc_files:
        continue   # Handled by Section 1

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

    # Skip actual BC files (document_type == 'behavioral-contract')
    doc_type = str(fm.get('document_type', '')).strip()
    if doc_type == 'behavioral-contract':
        continue   # Handled by Section 1

    # Probe for Form-B presence — needed to detect both-forms files
    fb_bm = re.search(
        r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)',
        body, re.DOTALL
    )
    fb_vers    = FORM_B_VERSION_RE.findall(fb_bm.group(1)) if fb_bm else []
    has_form_b = bool(fb_vers)
    has_form_a = 'changelog' in fm

    # ── No Form-A (Form-B-only or neither) ───────────────────────────────
    # Keep the original behavior: Form-B-only non-BC files are handled
    # by the "no-changelog" path — direction-only Form-B validation is
    # scoped exclusively to both-forms files where Form-A is authoritative.
    if not has_form_a:
        fm_version = str(fm.get('version', '')).strip()
        try:
            is_gt_1_0 = (parse_version(fm_version) > (1, 0)) if fm_version else False
        except (ValueError, TypeError):
            is_gt_1_0 = False
        if is_gt_1_0:
            print(f"SKIP {filepath} no-changelog-version-gt-1.0")
        else:
            print(f"PASS {filepath}")
        continue

    # ── Form-A present (+ maybe Form-B) ───────────────────────────────────
    changelog = fm['changelog']
    if not isinstance(changelog, list):
        print(f"SKIP {filepath} changelog-not-list")
        continue

    if len(changelog) == 0:
        print(f"SKIP {filepath} changelog-empty")
        continue

    # Classify entries: parseable version, rev-N format, or other unparseable
    versions   = []
    rev_format = []
    other_errs = []
    for entry in changelog:
        entry_str = str(entry).strip()
        m = VERSION_RE.match(entry_str)
        if m:
            versions.append(m.group(1))
        elif REV_RE.match(entry_str):
            rev_format.append(entry_str[:40])
        else:
            other_errs.append(entry_str[:60])

    # All entries are rev-N format: non-standard naming, cannot validate — WARN
    if rev_format and not versions:
        print(f"WARN {filepath} non-standard-rev-format:{rev_format[0]!r}")
        continue

    # Any unparseable entries (neither version nor rev-N): WARN, skip validation
    if other_errs:
        print(f"WARN {filepath} could-not-parse-version:{other_errs[0]!r}")
        continue

    if not versions:
        print(f"SKIP {filepath} no-parseable-versions")
        continue

    # Single-entry changelog: trivially valid (no pair to check direction on)
    if len(versions) == 1:
        fm_version = str(fm.get('version', '')).strip()
        version_mismatch = (fm_version != versions[0]) if fm_version else None
        # Both-forms co-existence WARN (Rule 3 direction check on single-row Form-B
        # is trivially valid — no pair exists to be out of order).
        if has_form_b:
            print(f"WARN {filepath} both-changelog-forms:frontmatter={versions[0]},body-table={fb_vers[0]}")
        if version_mismatch:
            print(f"FAIL {filepath} version-mismatch:frontmatter={fm_version},first-entry={versions[0]}")
        else:
            print(f"PASS {filepath}")
        continue

    # Rule 5 (DESCENDING): strictly decreasing — each entry's version must be
    # strictly less than the one before it (first = newest, last = oldest).
    nums = [parse_version(v) for v in versions]
    descending_fail = None
    for i in range(1, len(nums)):
        prev, curr = nums[i - 1], nums[i]
        if curr >= prev:
            direction = 'ascending' if nums[-1] > nums[0] else 'non-monotonic'
            descending_fail = (versions[i - 1], versions[i], direction)
            break

    # Rule 6 (VERSION-MATCH): frontmatter version == FIRST (top/newest) entry
    fm_version   = str(fm.get('version', '')).strip()
    first_version = versions[0]
    version_mismatch = (fm_version != first_version) if fm_version else None

    defects = []
    if descending_fail:
        v_prev, v_curr, direction = descending_fail
        defects.append(f"{direction}:{','.join(versions)}")
    if version_mismatch:
        defects.append(
            f"version-mismatch:frontmatter={fm_version},first-entry={first_version}"
        )

    # ── Both-forms co-existence WARN and Form-B direction check ──────────
    # Emitted before the Form-A result so context precedes any FAIL line.
    # This was previously invisible when Form-A existed (short-circuit fix).
    # Rule 4 (Form-B version-match) is NOT checked: Form-A is the authoritative
    # version source when both forms co-exist; the body table may legitimately
    # lag behind while backfilling is pending.  Only direction (Rule 3) is FAIL.
    if has_form_b:
        print(f"WARN {filepath} both-changelog-forms:frontmatter={first_version},body-table={fb_vers[0]}")
        dir_defects = check_form_b_direction_only(fb_vers)
        if dir_defects:
            print(f"FAIL {filepath} {'; '.join(dir_defects)}")

    if defects:
        print(f"FAIL {filepath} {'; '.join(defects)}")
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
    PASS)
      emit PASS "$short"
      ;;
    FAIL)
      emit FAIL "$short — $detail"
      ;;
    SKIP)
      emit WARN "$short (skipped: $detail)"
      ;;
    WARN)
      emit WARN "$short — $detail"
      ;;
    *)
      emit WARN "unexpected parser output: $line"
      ;;
  esac
done <<< "$PYTHON_OUTPUT_NONBC"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-form-a-changelog-direction: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
