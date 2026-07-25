#!/usr/bin/env bash
# verify-form-a-changelog-direction.sh — ferrochain factory-artifacts wrap guard
#
# Validates Form-A frontmatter `changelog:` lists in BC files
# (.factory/specs/behavioral-contracts/ss-*/BC-*.md):
#
#   Rule 1 (ASCENDING): Changelog entries must be in STRICTLY ASCENDING version
#           order — oldest (lowest) entry at the top, newest (highest) at the
#           bottom.  Equal consecutive versions also fail (must be strictly >).
#   Rule 2 (VERSION-MATCH): The frontmatter `version:` field must equal the
#           version of the LAST (newest, bottom) changelog entry.
#
# NOTE: This check applies to BC files ONLY.  Architecture docs and prd-
#       supplements use DESCENDING order (newest top) — do NOT pass those paths
#       to this script.
#
# Design notes:
#   - Frontmatter extracted between the first and second '---' delimiter.
#   - PyYAML (python3 -c "import yaml") used for robust YAML parsing; avoids
#     fragile line-by-line awk that breaks on embedded colons, braces, etc.
#   - Version numbers compared as integer tuples (so 1.10 > 1.9 correctly).
#   - Files lacking a 'changelog:' key are SKIPped (WARN, non-blocking).
#   - Files lacking a 'version:' key are WARN (non-blocking).
#   - Single-entry changelogs are always valid (trivially ascending).
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

# ── Python3 inline parser ─────────────────────────────────────────────────────
#
# Produces one output line per BC file in the format:
#   PASS <filepath>
#   FAIL <filepath> <defect-description>
#   SKIP <filepath> <reason>
#
# The bash loop below reads these and calls emit() accordingly.

PYTHON_OUTPUT="$(python3 - "$BC_GLOB" <<'PYEOF'
import sys, glob, re, yaml

pattern = sys.argv[1]
files = sorted(glob.glob(pattern))

VERSION_RE = re.compile(r'^(\d+\.\d+(?:\.\d+)*)[\s:(]')

def parse_version(s):
    """Convert '1.3' or '1.10' to tuple of ints for numeric comparison."""
    return tuple(int(x) for x in s.split('.'))

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

    if 'changelog' not in fm:
        print(f"SKIP {filepath} no-changelog")
        continue

    changelog = fm['changelog']
    if not isinstance(changelog, list):
        print(f"SKIP {filepath} changelog-not-list")
        continue

    if len(changelog) == 0:
        print(f"SKIP {filepath} changelog-empty")
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
