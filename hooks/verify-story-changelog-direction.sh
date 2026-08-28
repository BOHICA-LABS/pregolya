#!/usr/bin/env bash
# verify-story-changelog-direction.sh — story changelog monotonicity + version-integrity gate
#
# PURPOSE
# ───────
# Enforces INTERNAL MONOTONICITY of story changelog sequences and integrity of
# the frontmatter `version:` field. Direction (ascending vs descending) is NOT
# globally mandated across stories — a file may use either convention so long as
# it is internally self-consistent.
#
# CANONICAL RULE SET (orchestrator-revised 2026-08-28)
# ─────────────────────────────────────────────────────
# Rule 1 (MONOTONICITY):     A story changelog must be STRICTLY MONOTONIC in
#                             its own established direction. Direction is inferred
#                             by comparing the FIRST and LAST entries:
#                               first > last  →  DESCENDING (newest at top)
#                               first < last  →  ASCENDING  (newest at bottom)
#                             Any local inversion (a pair that goes the wrong way)
#                             is a WARN, regardless of overall direction.
#
# Rule 2 (VERSION-MATCH):    Frontmatter `version:` must equal the NEWEST entry:
#                               Descending: version == FIRST entry (top)
#                               Ascending:  version == LAST  entry (bottom)
#
# Rule 3 (FM/BODY AGREEMENT): If BOTH a frontmatter `changelog:` list and a body
#                             `## Changelog` section are parseable, they must share
#                             the SAME direction. A mixed (frontmatter ascending,
#                             body descending) story is a WARN.
#
# Rule 4 (BODY MONOTONICITY): Body `## Changelog` sections are checked for
#                             internal monotonicity independently. Pure-body stories
#                             (no frontmatter `changelog:` key) also validate
#                             `version:` == body newest extreme.
#
# NOT enforced: uniformity of direction across different story files. Ascending
# stories (e.g. S-1.07/08/09) that are internally consistent PASS — they are
# cosmetically different from descending stories but are NOT integrity defects.
#
# FILES IN SCOPE
# ──────────────
# .factory/stories/stories/*.md  — per-story spec files
# .factory/stories/*.md          — STORY-INDEX.md and other stories-root .md files
# Only files where document_type is 'story' or 'story-index' (or absent) are
# validated. Files with no parseable changelog of any kind are silently SKIP'd.
#
# SELF-PROBES (POL-31)
# ────────────────────
#   Positive probe P1: non-monotonic changelog (1.17,1.18,1.1) + version="1.18"
#                      → WARN: non-monotonic local-inversion detected
#   Positive probe P2: version≠newest-extreme, ascending (1.1,1.2) + version="1.5"
#                      → WARN: version-mismatch (1.5≠last=1.2)
#   Negative probe N1: clean ASCENDING (1.1,1.2) + version="1.2"
#                      → PASS (ascending + version==last=1.2)
#   Negative probe N2: clean DESCENDING (1.2,1.1) + version="1.2"
#                      → PASS (descending + version==first=1.2)
# POL-30: fixtures live in $TMPDIR — never under .factory/stories/.
#
# ADVISORY
# ────────
# Advisory: always exits 0. WARN findings are printed but commit is not blocked.
# Exit 2: self-probe failure (script logic bug — false-green or false-red probe).
#
# Usage:  bash .factory/hooks/verify-story-changelog-direction.sh
# Called: run_advisory in pre-commit-validators.sh (advisory — gate O-P2A102-05)

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
STORIES_GLOB_SUBDIR="$FACTORY_DIR/stories/stories/*.md"
STORIES_GLOB_ROOT="$FACTORY_DIR/stories/*.md"

PASS=0
WARN=0
SKIP=0
SELF_PROBE_FAIL=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
    SKIP) SKIP=$((SKIP + 1)) ;;
  esac
}

# ── Self-probe infrastructure ─────────────────────────────────────────────────
PROBE_TMP="$(mktemp -d)"
trap 'rm -rf "$PROBE_TMP"' EXIT

probe_expect_warn() {
  local probe_id="$1"
  local description="$2"
  local warn_count="$3"
  if [ "$warn_count" -eq 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — false-green: '$description' was NOT detected."
    echo "  Script logic bug — violation silently passed."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — positive probe correctly detected violation: $description"
  fi
}

probe_expect_pass() {
  local probe_id="$1"
  local description="$2"
  local warn_count="$3"
  if [ "$warn_count" -gt 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — false-positive: '$description' fired but should NOT have."
    echo "  Script logic bug — valid form incorrectly flagged."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — negative probe correctly passed on valid form: $description"
  fi
}

# ── Core Python scanner ───────────────────────────────────────────────────────
# Arguments: [<probe_file> <glob1> <glob2> ...]
# When probe_file is non-empty, scans ONLY that file (self-probe mode).
# Output lines:
#   PASS <filepath>             — all rules satisfied
#   WARN <filepath> <detail>    — Rule 1, 2, 3, or 4 violation
#   SKIP <filepath> <reason>    — file skipped (no changelog, wrong doc_type, etc.)
run_scanner() {
  local probe_override="${1:-}"
  shift || true
  local glob_patterns=("$@")
  python3 - "$probe_override" "${glob_patterns[@]}" <<'PYEOF'
import sys, re, glob, os, yaml

probe_override = sys.argv[1] if len(sys.argv) > 1 else ""
glob_patterns  = sys.argv[2:]

# Version entry RE: optional leading 'v', then X.Y or X.Y.Z, then whitespace/colon/paren
VERSION_FM_RE    = re.compile(r'^v?(\d+\.\d+(?:\.\d+)*)[\s:(]')
# Body pipe-table version (| N.N |)
VERSION_PIPE_RE  = re.compile(r'^\|\s*(\d+\.\d+(?:\.\d+)*)\s*\|', re.MULTILINE)
# Body bullet-list version (- N.N ...)
VERSION_BULLET_RE = re.compile(r'^-\s+v?(\d+\.\d+(?:\.\d+)*)\s*[\s(]', re.MULTILINE)

STORY_DOC_TYPES = {'story', 'story-index', ''}

def parse_version(s):
    """Convert '1.3' or '1.10' to tuple of ints for numeric comparison."""
    return tuple(int(x) for x in s.split('.'))

def determine_direction(versions):
    """
    Infer direction from first vs last entry.
    Returns 'ascending', 'descending', or 'equal'.
    """
    if len(versions) < 2:
        return 'equal'
    first = parse_version(versions[0])
    last  = parse_version(versions[-1])
    if first < last:
        return 'ascending'
    elif first > last:
        return 'descending'
    else:
        return 'equal'

def check_monotonic(versions, direction):
    """
    Verify versions are strictly monotonic in the given direction.
    Returns None if OK; else (versions[i-1], versions[i], issue_label) for the first violation.
    """
    if len(versions) < 2:
        return None
    nums = [parse_version(v) for v in versions]
    for i in range(1, len(nums)):
        prev, curr = nums[i - 1], nums[i]
        if direction == 'descending' and curr >= prev:
            return (versions[i - 1], versions[i], 'local-inversion-in-descending')
        elif direction == 'ascending' and curr <= prev:
            return (versions[i - 1], versions[i], 'local-inversion-in-ascending')
    return None

def newest_extreme(versions, direction):
    """Return the newest version string: first if descending, last if ascending."""
    if direction == 'descending':
        return versions[0]
    elif direction == 'ascending':
        return versions[-1]
    # equal / single entry: return first
    return versions[0]

def get_body_changelog_versions(body):
    """
    Extract version numbers from a body ## Changelog section.
    Returns (versions_list, format_name) or ([], None) if absent/unreadable.
    """
    bm = re.search(
        r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)',
        body, re.DOTALL
    )
    if bm is None:
        return [], None

    section = bm.group(1)
    pipe_vers   = VERSION_PIPE_RE.findall(section)
    bullet_vers = VERSION_BULLET_RE.findall(section)

    if pipe_vers:
        return pipe_vers, 'pipe-table'
    if bullet_vers:
        return bullet_vers, 'bullet-list'
    return [], None

def format_versions(versions, max_show=5):
    shown = versions[:max_show]
    suffix = ',...' if len(versions) > max_show else ''
    return ','.join(shown) + suffix

def scan_file(filepath):
    """Returns list of output lines for this file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError as e:
        return [f"SKIP {filepath} read-error:{e}"]

    parts = content.split('---', 2)
    if len(parts) < 3:
        return [f"SKIP {filepath} no-frontmatter"]

    fm_text = parts[1]
    body    = parts[2]

    try:
        fm = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        single_line = str(e).replace('\n', ' | ')
        return [f"SKIP {filepath} yaml-parse-error:{single_line}"]

    if not isinstance(fm, dict):
        return [f"SKIP {filepath} frontmatter-not-dict"]

    doc_type = str(fm.get('document_type', '')).strip()
    if doc_type not in STORY_DOC_TYPES:
        return [f"SKIP {filepath} not-a-story-file:document_type={doc_type}"]

    fm_version   = str(fm.get('version', '')).strip()
    results      = []
    has_fm_cl    = False
    fm_direction = None

    # ── Rule 1+2: Frontmatter changelog ────────────────────────────────────────
    if 'changelog' in fm:
        changelog = fm['changelog']
        if not isinstance(changelog, list) or len(changelog) == 0:
            results.append(f"SKIP {filepath} changelog-empty-or-not-list")
        else:
            fm_versions = []
            for entry in changelog:
                m = VERSION_FM_RE.match(str(entry).strip())
                if m:
                    fm_versions.append(m.group(1))

            if not fm_versions:
                results.append(f"SKIP {filepath} no-parseable-versions-in-changelog")
            else:
                has_fm_cl    = True
                fm_direction = determine_direction(fm_versions)
                defects      = []

                # Rule 1: must be strictly monotonic in its own direction
                if fm_direction == 'equal':
                    # Single effective version or all equal — skip monotonicity check
                    pass
                else:
                    inversion = check_monotonic(fm_versions, fm_direction)
                    if inversion:
                        v_prev, v_curr, label = inversion
                        defects.append(
                            f"non-monotonic({label}:{v_prev}->{v_curr}):"
                            f"{format_versions(fm_versions)}"
                        )

                # Rule 2: frontmatter version == newest extreme
                if fm_direction in ('ascending', 'descending'):
                    extreme = newest_extreme(fm_versions, fm_direction)
                    if fm_version and fm_version != extreme:
                        defects.append(
                            f"version-mismatch({fm_direction}):"
                            f"frontmatter={fm_version},"
                            f"newest-extreme({fm_direction})={extreme}"
                        )
                    elif not fm_version:
                        defects.append("no-version-field:cannot-verify-version-match")

                if defects:
                    for d in defects:
                        results.append(f"WARN {filepath} {d}")
                else:
                    results.append(f"PASS {filepath}")

    # ── Rule 4+3: Body ## Changelog ────────────────────────────────────────────
    body_versions, body_fmt = get_body_changelog_versions(body)
    if body_versions:
        body_direction = determine_direction(body_versions)
        body_defects   = []

        # Rule 4: body must be internally monotonic
        if body_direction not in ('equal',):
            inversion = check_monotonic(body_versions, body_direction)
            if inversion:
                v_prev, v_curr, label = inversion
                body_defects.append(
                    f"body-non-monotonic({label}:{v_prev}->{v_curr},{body_fmt}):"
                    f"{format_versions(body_versions)}"
                )

        # Rule 3: if both changelogs present, directions must agree
        if has_fm_cl and fm_direction and fm_direction != 'equal' and body_direction != 'equal':
            if body_direction != fm_direction:
                body_defects.append(
                    f"fm-body-direction-mismatch:"
                    f"frontmatter={fm_direction},body-{body_fmt}={body_direction}"
                )

        # Rule 2 for body-only stories: check version == body newest extreme
        if not has_fm_cl and body_direction in ('ascending', 'descending'):
            extreme = newest_extreme(body_versions, body_direction)
            if fm_version and fm_version != extreme:
                body_defects.append(
                    f"version-mismatch(body-only,{body_direction}):"
                    f"frontmatter={fm_version},"
                    f"newest-extreme({body_direction})={extreme}"
                )
            elif not fm_version:
                body_defects.append("no-version-field:cannot-verify-body-version-match")

        if body_defects:
            for d in body_defects:
                results.append(f"WARN {filepath} {d}")
        elif not has_fm_cl:
            # Body-only: emit PASS when clean
            results.append(
                f"PASS {filepath}"
                f" body-changelog-{body_fmt}-{body_direction}-clean"
            )

    # If no changelog of any kind was found, emit SKIP
    if not has_fm_cl and not body_versions:
        results.append(f"SKIP {filepath} no-changelog")

    return results

# ── Collect files ─────────────────────────────────────────────────────────────
if probe_override:
    all_files = [probe_override]
else:
    files_set = set()
    for pat in glob_patterns:
        files_set.update(glob.glob(pat))
    all_files = sorted(files_set)

for fp in all_files:
    for line in scan_file(fp):
        print(line)

PYEOF
}

# ── Self-probes (POL-31) ──────────────────────────────────────────────────────
echo "── Self-probes ──────────────────────────────────────────────────────────"

# Positive probe P1: non-monotonic changelog (1.17, 1.18, 1.1) + version=1.18
# Expect WARN: local inversion 1.17→1.18 detected (ascending in a descending sequence)
PROBE_P1="$PROBE_TMP/probe-story-p1-nonmonotonic.md"
cat > "$PROBE_P1" <<'MDEOF'
---
document_type: story
story_id: S-TEST-P1
version: "1.18"
status: draft
changelog:
  - "1.17 (descending start — then local inversion to 1.18)"
  - "1.18 (wrong: goes UP before going back down — non-monotonic)"
  - "1.1 (resuming downward)"
  - "1.2 (then up again — clearly non-monotonic)"
---

# Positive Probe P1 (non-monotonic changelog — expect WARN)
MDEOF

P1_OUTPUT="$(run_scanner "$PROBE_P1" 2>/dev/null)"
P1_WARN_COUNT="$(echo "$P1_OUTPUT" | grep -c '^WARN ' || true)"
probe_expect_warn "P1" "non-monotonic changelog (1.17→1.18→1.1) + version=1.18 → non-monotonic WARN" "$P1_WARN_COUNT"

# Positive probe P2: version≠newest-extreme, ascending (1.1, 1.2) + version=1.5
# Expect WARN: version 1.5 ≠ last=1.2 for ascending sequence
PROBE_P2="$PROBE_TMP/probe-story-p2-version-mismatch.md"
cat > "$PROBE_P2" <<'MDEOF'
---
document_type: story
story_id: S-TEST-P2
version: "1.5"
status: draft
changelog:
  - "1.1 (oldest entry at top — ASCENDING convention)"
  - "1.2 (newest entry at bottom — but version: says 1.5, which is wrong)"
---

# Positive Probe P2 (ascending changelog, version≠last — expect WARN)
MDEOF

P2_OUTPUT="$(run_scanner "$PROBE_P2" 2>/dev/null)"
P2_WARN_COUNT="$(echo "$P2_OUTPUT" | grep -c '^WARN ' || true)"
probe_expect_warn "P2" "ascending changelog (1.1→1.2) + version=1.5 (≠last=1.2) → version-mismatch WARN" "$P2_WARN_COUNT"

# Negative probe N1: clean ASCENDING (1.1, 1.2) + version="1.2" → PASS
PROBE_N1="$PROBE_TMP/probe-story-n1-ascending.md"
cat > "$PROBE_N1" <<'MDEOF'
---
document_type: story
story_id: S-TEST-N1
version: "1.2"
status: draft
changelog:
  - "1.1 (oldest entry — ascending convention, valid)"
  - "1.2 (newest entry — version==last==1.2, correct)"
---

# Negative Probe N1 (clean ascending — expect PASS)
MDEOF

N1_OUTPUT="$(run_scanner "$PROBE_N1" 2>/dev/null)"
N1_WARN_COUNT="$(echo "$N1_OUTPUT" | grep -c '^WARN ' || true)"
probe_expect_pass "N1" "clean ascending (1.1→1.2) + version==last=1.2 → PASS" "$N1_WARN_COUNT"

# Negative probe N2: clean DESCENDING (1.2, 1.1) + version="1.2" → PASS
PROBE_N2="$PROBE_TMP/probe-story-n2-descending.md"
cat > "$PROBE_N2" <<'MDEOF'
---
document_type: story
story_id: S-TEST-N2
version: "1.2"
status: draft
changelog:
  - "1.2 (newest entry first — descending convention, valid)"
  - "1.1 (older entry — version==first==1.2, correct)"
---

# Negative Probe N2 (clean descending — expect PASS)
MDEOF

N2_OUTPUT="$(run_scanner "$PROBE_N2" 2>/dev/null)"
N2_WARN_COUNT="$(echo "$N2_OUTPUT" | grep -c '^WARN ' || true)"
probe_expect_pass "N2" "clean descending (1.2→1.1) + version==first=1.2 → PASS" "$N2_WARN_COUNT"

echo ""

# Bail on self-probe failures
if [ "$SELF_PROBE_FAIL" -gt 0 ]; then
  echo "ABORT: $SELF_PROBE_FAIL self-probe(s) failed — script has false-green or false-red bugs."
  echo "  Fix the script logic before relying on live scan results."
  exit 2
fi

# ── Live scan ─────────────────────────────────────────────────────────────────
echo "── Live scan ────────────────────────────────────────────────────────────"

SCAN_OUTPUT="$(run_scanner "" "$STORIES_GLOB_SUBDIR" "$STORIES_GLOB_ROOT")"

FACTORY_SHORT="$FACTORY_DIR/"

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"
  if [[ "$rest" =~ ^([^\ ]+)\ +(.+)$ ]]; then
    filepath="${BASH_REMATCH[1]}"
    detail="${BASH_REMATCH[2]}"
  else
    filepath="$rest"
    detail=""
  fi
  short="${filepath#"$FACTORY_SHORT"}"

  case "$level" in
    PASS) emit PASS "$short${detail:+ — $detail}" ;;
    WARN) emit WARN "$short — $detail" ;;
    SKIP) emit SKIP "$short — $detail" ;;
    *)    emit WARN "unexpected output: $line" ;;
  esac
done <<< "$SCAN_OUTPUT"

echo ""
echo "verify-story-changelog-direction: PASS=$PASS WARN=$WARN SKIP=$SKIP"
echo "  Rule: story changelog must be INTERNALLY MONOTONIC (ascending OR descending)."
echo "  Rule: frontmatter 'version:' must equal the newest-extreme entry."
echo "        (DESCENDING: version == first entry; ASCENDING: version == last entry)"
echo "  Rule: body and frontmatter changelogs must share the same direction when both present."
echo "  Advisory: WARN findings do not block commit."
if [ "$WARN" -gt 0 ]; then
  echo "  ACTION: Fix non-monotonic sequences or version-mismatch as indicated above."
  echo "  Routing: story-writer for story files; state-manager for version-field corrections."
fi

# Advisory gate: always exit 0
exit 0
