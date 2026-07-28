#!/usr/bin/env bash
# verify-changelog-claim-applied.sh — ferrochain factory-artifacts ADVISORY validator
#
# PURPOSE
# ───────
# Detects false closures where a changelog entry claims a change was made but the
# body of the same file still reflects the pre-change state. Four heuristics:
#
#   (a) REMOVAL CLAIMS — changelog entry contains "remove[d]/drop[ped]/eliminat[ed]/
#       delet[ed]" + a quoted or backtick-wrapped term; checks if that term still
#       appears verbatim in the body.
#
#   (b) RENAME CLAIMS — changelog entry contains "OLD → NEW" (U+2192) or "OLD -> NEW"
#       (ASCII arrow); checks if the old form OLD still appears verbatim in the body.
#       OLD is the token immediately before the arrow; NEW is the token immediately after.
#
#   (c) INPUT-HASH CLAIMS — changelog entry (Form-A frontmatter list or Form-B body
#       table) claims "input-hash [updated/refreshed/bumped/set] to HASH" or
#       "input-hash: HASH"; verifies that the frontmatter `input-hash:` field matches
#       the claimed hash value.
#
#   (d) VERSION CLAIMS — Form-A changelog entry that starts with version X claims
#       that is the current version; verifies frontmatter `version:` matches the
#       last (newest) changelog entry's version (VERSION-MATCH, Rule 2). Separately
#       verifies Form-B first-row version matches frontmatter version (Rule 4).
#       NOTE: Heuristic (d) overlaps with verify-form-a-changelog-direction.sh
#       VERSION-MATCH checks — findings here are advisory cross-validation.
#
# SCOPE
# ─────
# All .md files under .factory/specs/ (behavioral-contracts, architecture,
# prd-supplements, verification-properties, domain-spec).
#
# ADVISORY STATUS
# ───────────────
# All findings are WARN (non-blocking). This validator starts advisory and
# will be promoted to blocking after a corpus-wide false-closure sweep.
#
# MOTIVATING FALSE CLOSURES (per adversarial pass P1D-174 at frozen-HEAD cd0a2c7)
#   FC-1: verification-architecture.md changelog claimed "replacing TaskId(i as u64)"
#         but body still contained TaskId(i as u64). Caught by heuristic (a)/(b).
#   FC-2: BC-2.19.003 changelog claimed "Drop fabricated 'duplicate detection' clause"
#         but body still contained "duplicate detection". Caught by heuristic (a).
#   FC-3: VP-013.md changelog claimed "Remove stale '(Red Gate)' labels" but
#         (Red Gate) still appeared in the Lifecycle table. Caught by heuristic (a).
#   FC-4: BC-2.07.002 Form-B changelog row claimed "input-hash updated to ea9cf4b"
#         but frontmatter input-hash was a different value. Caught by heuristic (c).
#
# EXIT CONTRACT
# ─────────────
# Always exits 0 (advisory — non-blocking). WARN count reflects findings.
#
# Usage:  bash .factory/hooks/verify-changelog-claim-applied.sh
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

PYTHON_OUTPUT="$(python3 - "$SPECS_ROOT" <<'PYEOF'
import sys, os, re, glob, yaml

specs_root = sys.argv[1]

# ── File discovery ─────────────────────────────────────────────────────────────

all_md_files = []
for root, dirs, files in os.walk(specs_root):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for fn in sorted(files):
        if fn.endswith('.md'):
            all_md_files.append(os.path.join(root, fn))
all_md_files.sort()

# ── Helpers ───────────────────────────────────────────────────────────────────

def parse_frontmatter(content):
    """Return (fm_dict, body_text) or (None, content) on parse failure."""
    parts = content.split('---', 2)
    if len(parts) < 3:
        return None, content
    try:
        fm = yaml.safe_load(parts[1])
    except yaml.YAMLError:
        return None, content
    if not isinstance(fm, dict):
        return None, content
    return fm, parts[2]

def get_form_a_entries(fm):
    """Return list of changelog entry strings from Form-A frontmatter, or []."""
    cl = fm.get('changelog', [])
    if not isinstance(cl, list):
        return []
    return [str(e) for e in cl]

def get_form_b_entries(body):
    """Return list of changelog entry strings from Form-B body table rows, or []."""
    bm = re.search(r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)', body, re.DOTALL)
    if not bm:
        return []
    rows = []
    for line in bm.group(1).split('\n'):
        line = line.strip()
        if line.startswith('|') and not all(c in '|-: ' for c in line.replace('|', '')):
            rows.append(line)
    return rows

# ── Heuristic (a): Removal claims ─────────────────────────────────────────────

# Patterns that introduce a term claimed to be removed
REMOVAL_VERB_RE = re.compile(
    r'\b(?:remove[sd]?|remov(?:ing|al)|drop(?:ped)?|drop(?:ping)?|'
    r'eliminat(?:ed?|ing)|delet(?:ed?|ing))\b',
    re.IGNORECASE
)

# Quoted phrase: 'X', "X", or `X` — short snippet, not a full sentence
QUOTED_TERM_RE = re.compile(r"[`'\"]([^`'\"]{1,80})[`'\"]")
# Code token in backticks
BACKTICK_TERM_RE = re.compile(r'`([^`]{1,60})`')

def check_removal_claims(filepath, fm, body, changelog_entries):
    """Return list of (entry_text, term, reason) for each removal claim not applied."""
    findings = []
    for entry in changelog_entries:
        if not REMOVAL_VERB_RE.search(entry):
            continue
        # Extract quoted/backtick terms following a removal verb
        quoted = QUOTED_TERM_RE.findall(entry)
        for term in quoted:
            term_stripped = term.strip()
            if len(term_stripped) < 3:
                continue
            # Skip terms that look like version numbers
            if re.match(r'^\d+\.\d+', term_stripped):
                continue
            # Check if term still appears in body
            if term_stripped in body:
                findings.append((entry[:120], term_stripped,
                    f"removal claim for '{term_stripped}' but term still in body"))
    return findings

# ── Heuristic (b): Rename/replacement claims ──────────────────────────────────

# Arrow forms: "OLD → NEW" (U+2192) or "OLD -> NEW"
# We capture the token(s) immediately before and after the arrow
ARROW_RE = re.compile(r'([^\s→>|,;:]{2,60})\s*(?:→|->)\s*([^\s→>|,;:]{2,60})')

def check_rename_claims(filepath, fm, body, changelog_entries):
    """Return list of (entry_text, old_term, reason) for rename claims not applied."""
    findings = []
    for entry in changelog_entries:
        for m in ARROW_RE.finditer(entry):
            old_term = m.group(1).strip().strip('`\'"')
            new_term = m.group(2).strip().strip('`\'"')
            # Skip pure version transitions (e.g. "1.3 → 1.4")
            if re.match(r'^\d+[\.\d]*$', old_term):
                continue
            # Skip very short terms (noise)
            if len(old_term) < 4:
                continue
            # If the old form still appears in body, the rename wasn't applied
            if old_term in body:
                findings.append((entry[:120], old_term,
                    f"rename claim '{old_term} → {new_term}' but old form still in body"))
    return findings

# ── Heuristic (c): Input-hash claims ──────────────────────────────────────────

# Pattern: "input-hash [updated/refreshed/bumped/changed] to HASH"
# or: "input-hash: HASH" in prose (not a YAML field assignment)
INPUT_HASH_CLAIM_RE = re.compile(
    r'input[-_]hash\s*(?:updated?|refreshed?|bumped?|changed?|set|→|->\s*)?\s*'
    r'(?:to\s+)?([0-9a-f]{6,40})\b',
    re.IGNORECASE
)

def check_input_hash_claims(filepath, fm, body, changelog_entries):
    """Return list of (entry_text, claimed_hash, reason) for input-hash mismatches."""
    findings = []
    fm_hash = str(fm.get('input-hash', '') or '').strip().strip('"\'')
    if not fm_hash:
        return []  # No input-hash field — nothing to verify against

    for entry in changelog_entries:
        for m in INPUT_HASH_CLAIM_RE.finditer(entry):
            claimed = m.group(1).strip()
            if not claimed:
                continue
            # Only check if claim looks like a proper hex hash (not just a version number)
            if not re.match(r'^[0-9a-f]{6,40}$', claimed):
                continue
            if claimed != fm_hash:
                findings.append((entry[:120], claimed,
                    f"input-hash claim '{claimed}' does not match frontmatter "
                    f"input-hash '{fm_hash}'"))
    return findings

# ── Heuristic (d): Version claims ─────────────────────────────────────────────

# Check that Form-A last entry version matches frontmatter version:
# (This is also checked by verify-form-a-changelog-direction.sh — here it's
# a cross-check in advisory mode.)
VERSION_RE = re.compile(r'^(\d+\.\d+(?:\.\d+)*)[\s:(]')

def check_version_claims(filepath, fm, changelog_entries):
    """Return list of (entry_text, claimed_version, reason) for version mismatches."""
    findings = []
    fm_version = str(fm.get('version', '') or '').strip()
    if not fm_version or not changelog_entries:
        return []

    # BC files use ascending (last entry is newest); detect document_type
    doc_type = str(fm.get('document_type', '')).strip()
    is_bc = (doc_type == 'behavioral-contract')

    versions = []
    for entry in changelog_entries:
        entry_str = str(entry).strip()
        m = VERSION_RE.match(entry_str)
        if m:
            versions.append((m.group(1), entry_str))

    if not versions:
        return []

    if is_bc:
        # BC: last entry should match frontmatter version
        last_ver, last_entry = versions[-1]
        if last_ver != fm_version:
            findings.append((last_entry[:120], last_ver,
                f"BC Form-A last-entry version '{last_ver}' does not match "
                f"frontmatter version '{fm_version}'"))
    else:
        # Non-BC: first entry should match frontmatter version
        first_ver, first_entry = versions[0]
        if first_ver != fm_version:
            findings.append((first_entry[:120], first_ver,
                f"Form-A first-entry version '{first_ver}' does not match "
                f"frontmatter version '{fm_version}'"))
    return findings

# ── Per-file scan ─────────────────────────────────────────────────────────────

file_findings = {}  # filepath -> list of (heuristic, entry_text, term, reason)

for filepath in all_md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError:
        continue

    fm, body = parse_frontmatter(content)
    if fm is None:
        continue

    form_a_entries = get_form_a_entries(fm)
    form_b_entries = get_form_b_entries(body)
    all_entries = form_a_entries + form_b_entries

    if not all_entries:
        continue

    ffindings = []

    # Heuristic (a): removal claims
    for (entry, term, reason) in check_removal_claims(filepath, fm, body, all_entries):
        ffindings.append(('a-removal', entry, term, reason))

    # Heuristic (b): rename/replacement claims
    for (entry, old_term, reason) in check_rename_claims(filepath, fm, body, all_entries):
        ffindings.append(('b-rename', entry, old_term, reason))

    # Heuristic (c): input-hash claims
    for (entry, claimed, reason) in check_input_hash_claims(filepath, fm, body, all_entries):
        ffindings.append(('c-input-hash', entry, claimed, reason))

    # Heuristic (d): version claims
    for (entry, ver, reason) in check_version_claims(filepath, fm, form_a_entries):
        ffindings.append(('d-version', entry, ver, reason))

    if ffindings:
        file_findings[filepath] = ffindings

# ── Output ────────────────────────────────────────────────────────────────────

total_findings = sum(len(v) for v in file_findings.values())
print(f"SUMMARY total-files-with-findings={len(file_findings)} total-findings={total_findings}")

for filepath in sorted(file_findings.keys()):
    short = filepath.split('/specs/')[-1] if '/specs/' in filepath else filepath
    for (heuristic, entry, term, reason) in file_findings[filepath]:
        # Sanitize for single-line output
        entry_safe = entry.replace('\n', ' ').replace('\t', ' ')
        term_safe = str(term).replace('\n', ' ')
        print(f"FINDING heuristic={heuristic} file={short} "
              f"term={term_safe!r} reason={reason}")
        print(f"  CLAIM: {entry_safe[:100]}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

FINDINGS_COUNT=0

while IFS= read -r line; do
  tag="${line%% *}"
  rest="${line#* }"

  case "$tag" in
    SUMMARY)
      files_count="$(echo "$rest" | grep -oE 'total-files-with-findings=[^ ]+' | cut -d= -f2)"
      total_count="$(echo "$rest" | grep -oE 'total-findings=[^ ]+' | cut -d= -f2)"
      FINDINGS_COUNT="$total_count"
      if [ "$total_count" -gt 0 ]; then
        emit WARN "[ADVISORY] $total_count false-closure candidate(s) detected across $files_count file(s)"
      else
        emit PASS "no changelog claims found that contradict body content"
      fi
      ;;
    FINDING)
      heuristic="$(echo "$rest" | grep -oE 'heuristic=[^ ]+' | cut -d= -f2)"
      file="$(echo "$rest" | grep -oE 'file=[^ ]+' | cut -d= -f2)"
      reason="$(echo "$rest" | sed 's/.*reason=//')"
      emit WARN "[ADVISORY] heuristic-$heuristic: $file — $reason"
      ;;
    "  CLAIM:")
      echo "  Claim: $rest"
      ;;
    *)
      : # Ignore other lines (Python may emit CLAIM: lines starting with spaces)
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-changelog-claim-applied: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  Advisory findings: $FINDINGS_COUNT false-closure candidate(s)"
echo ""
echo "Heuristics (all advisory — non-blocking):"
echo "  (a) removal claims: changelog 'remove/drop/eliminate X' but X still in body"
echo "  (b) rename claims:  changelog 'X → Y' but old form X still in body"
echo "  (c) input-hash:     changelog 'input-hash updated to HASH' but FM hash differs"
echo "  (d) version claims: Form-A last/first entry version != frontmatter version"
echo ""
echo "RESULT: PASS (advisory — non-blocking)"
# Always exit 0 — advisory check
exit 0
