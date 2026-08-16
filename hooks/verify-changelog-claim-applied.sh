#!/usr/bin/env bash
# verify-changelog-claim-applied.sh — pregolya factory-artifacts ADVISORY validator
#
# PURPOSE
# ───────
# Detects false closures where a changelog entry claims an input-hash change was
# made but the frontmatter `input-hash:` field does not match the claimed value.
#
# ACTIVE HEURISTIC (burst-288 narrowing, E08 fix):
#   (c) INPUT-HASH CLAIMS — changelog entry claims "input-hash [updated/refreshed/
#       bumped/set] to HASH"; verifies frontmatter `input-hash:` matches the claim.
#       This is the 1 decidable heuristic retained after burst-288 narrowing.
#
# REMOVED HEURISTICS (burst-288 per E08, P1D-177):
#   (a) removal claims — phrase-grep heuristic; undecidable; 3 of 5 heuristics
#   (b) rename claims  — phrase-grep heuristic; undecidable
#   (d) version claims — redundant: already covered by the blocking gate
#                        verify-form-a-changelog-direction.sh
#   (e) from-X claims  — phrase-grep heuristic; undecidable
#   These 4 heuristics produced the WARN=662 count at P1D-177 frozen HEAD.
#   After narrowing to (c) only, WARN count reflects only genuine input-hash
#   mismatches — a much smaller, actionable set.
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
#   FC-1: verification-architecture.md v2.12 claimed "update formal statement from
#         `sorts by task_id`" but body still contains "sorts by `task_id`" (old key).
#         CAUGHT by heuristic (e) [from-X, backtick-normalized].
#   FC-2: BC-2.19.003 v1.2 claimed "Drop fabricated 'duplicate detection' clause"
#         but body still contained "duplicate detection". CAUGHT by heuristic (a).
#   FC-3: VP-013.md v1.13 STATE.md record claimed "all 13 VP bodies checked" —
#         review-process completeness claim; NOT catchable by in-file heuristics.
#         Structural limitation: this validator checks file body only.
#   FC-4: capabilities-p1-p2.md v1.13 claimed "zero additional hits" — count claim
#         with no quoted term; NOT catchable by in-file heuristics.
#         Structural limitation: count claims require external grep verification.
#   FC-5: BC-2.07.002 v1.5 Form-B claimed "input-hash updated to ea9cf4b" but
#         frontmatter input-hash was a different value. CAUGHT by heuristic (c).
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

# -- File discovery -----------------------------------------------------------

all_md_files = []
for root, dirs, files in os.walk(specs_root):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for fn in sorted(files):
        if fn.endswith('.md'):
            all_md_files.append(os.path.join(root, fn))
all_md_files.sort()

# -- Helpers ------------------------------------------------------------------

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

def strip_body_changelog(body):
    """Strip the Form-B ## Changelog section from body (non-greedy: stop at next ## heading).
    Also strips fenced code blocks and illustration regions to prevent false matches."""
    # Non-greedy: stop at next ## heading or end of string
    body_no_cl = re.sub(r'\n## Changelog\n.*?(?=\n## |\Z)', '', body, flags=re.DOTALL)
    # Strip fenced code blocks (``` ... ```)
    body_no_cl = re.sub(r'```[^`]*?```', '', body_no_cl, flags=re.DOTALL)
    # Strip illustration regions
    body_no_cl = re.sub(
        r'<!--\s*discriminator:illustration-start\s*-->.*?<!--\s*discriminator:illustration-end\s*-->',
        '', body_no_cl, flags=re.DOTALL)
    return body_no_cl

# -- Heuristic (c): Input-hash claims (ONLY ACTIVE HEURISTIC) ----------------
# All other heuristics (a, b, d, e) removed in burst-288 per E08 fix:
#   (a) removal claims -- undecidable phrase-grep heuristic removed
#   (b) rename claims  -- undecidable phrase-grep heuristic removed
#   (d) version claims -- redundant (verify-form-a-changelog-direction.sh already blocks)
#   (e) from-X claims  -- undecidable phrase-grep heuristic removed
# Input-hash comparison is the 1 decidable heuristic; it remains.

INPUT_HASH_CLAIM_RE = re.compile(
    r'input[-_]hash\s*(?:updated?|refreshed?|bumped?|changed?|set|\u2192|->\s*)?\s*'
    r'(?:to\s+)?([0-9a-f]{6,40})\b',
    re.IGNORECASE
)

def check_input_hash_claims(filepath, fm, body, changelog_entries):
    """Return list of (entry_text, claimed_hash, reason) for input-hash mismatches."""
    findings = []
    fm_hash = str(fm.get('input-hash', '') or '').strip().strip("\"'")
    if not fm_hash:
        return []  # No input-hash field -- nothing to verify against

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

# -- Per-file scan ------------------------------------------------------------

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

    # Heuristic (c): input-hash claims (only active heuristic)
    for (entry, claimed, reason) in check_input_hash_claims(filepath, fm, body, all_entries):
        ffindings.append(('c-input-hash', entry, claimed, reason))

    if ffindings:
        file_findings[filepath] = ffindings

# -- Output -------------------------------------------------------------------

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
echo "Active heuristic (burst-288 narrowing — only decidable heuristic retained):"
echo "  (c) input-hash: changelog 'input-hash updated to HASH' but FM input-hash differs"
echo "Removed heuristics (E08/P1D-177 — undecidable or redundant):"
echo "  (a) removal claims, (b) rename claims, (e) from-X claims — undecidable phrase-grep"
echo "  (d) version claims — redundant with verify-form-a-changelog-direction.sh blocking gate"
echo ""
echo "RESULT: PASS (advisory — non-blocking)"
# Always exit 0 — advisory check
exit 0
