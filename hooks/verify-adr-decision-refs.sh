#!/usr/bin/env bash
# verify-adr-decision-refs.sh — ferrochain factory-artifacts blocking validator (#6)
#
# PURPOSE
# ───────
# Verifies that every "ADR-NNN Decision N" citation in spec files refers to a
# Decision number that actually exists in the target ADR file.
#
# Three classes of finding that motivated this validator:
#   F-P148-01 — "ADR-016 Decision 6" on a 5-decision ADR (existence violation)
#   F-P167-02 — "ADR-016 Decision 7" on a 5-decision ADR (existence violation)
#   F-P169-01 — existing-but-semantically-wrong number (out of scope; see below)
#
# ─────────────────────────────────────────────────────────────────────────────
# WHAT THIS SCRIPT CHECKS (EXISTENCE AXIS)
# ─────────────────────────────────────────────────────────────────────────────
#
#   For each citation matching the pattern `ADR-(\d{3}) Decision (\d+)` found
#   in the LIVE BODY of any .md file under .factory/specs/:
#
#   1. FAIL — ADR file exists but has NO numbered decisions (only the unnumbered
#             "## Decision: ..." or "## Decision — ..." heading form).  The cited
#             Decision number is structurally fabricated.
#
#   2. FAIL — ADR file exists and has numbered decisions, but the cited number
#             is outside the range of existing `## Decision N` headings.
#             Examples: "Decision 6" on a 5-decision ADR; "Decision 7" ditto.
#
#   3. WARN — The cited ADR-NNN has no corresponding file in the decisions
#             directory at all.  File-existence resolution is the responsibility
#             of verify-arch-anchor-resolution.sh (validator #3); this is
#             only a WARN here to avoid double-reporting.
#
#   4. PASS — The cited Decision number exists in the target ADR.
#
# ─────────────────────────────────────────────────────────────────────────────
# WHAT THIS SCRIPT DOES NOT CHECK (SEMANTIC AXIS)
# ─────────────────────────────────────────────────────────────────────────────
#
#   This script is an EXISTENCE-ONLY check.  It CANNOT detect the following
#   class of error (F-P169-01):
#
#     A citation points to a Decision number that EXISTS in the ADR, but is
#     the WRONG decision for the described context.  For example, citing
#     "ADR-016 Decision 3" when the actual authority is Decision 4, where
#     both Decision 3 and Decision 4 are valid numbered headings.
#
#   Semantic-correctness review — verifying that the cited Decision number
#   matches the described behavior — is the ADVERSARY's responsibility and
#   cannot be mechanized without LLM-level comprehension.
#
# ─────────────────────────────────────────────────────────────────────────────
# DECISION-MAP EXTRACTION
# ─────────────────────────────────────────────────────────────────────────────
#
# Decision headings extracted from ADR BODY (post-frontmatter) by the pattern:
#
#   ^## Decision N          — numbered form; N is the extracted integer
#
# Heading forms observed in the corpus (empirical survey):
#   ## Decision N — Description       (ADR-012 through ADR-020, numbered)
#   ## Decision: Description          (ADR-001–011, unnumbered)
#   ## Decision — Description         (ADR-013, unnumbered)
#   ### Decision                      (H3 subsection in ADR-014; ignored — not ##)
#
# Only `^## Decision (\d+)` (H2 with a numeric label) contributes to the map.
# Unnumbered forms produce an empty decision set for that ADR.
#
# ─────────────────────────────────────────────────────────────────────────────
# EXEMPTED REGIONS (not scanned for citations)
# ─────────────────────────────────────────────────────────────────────────────
#
#   (a) YAML frontmatter block — all content between the opening `---` and the
#       closing `---` delimiter (the first two occurrences at line start).
#       Rationale: changelog: list entries preserve historical citations as
#       audit-trail records; flagging them would generate noise for already-
#       fixed violations (e.g., the F-P148-01/F-P167-02 entries in BC-INDEX.md
#       and BC-2.19.006.md frontmatter correctly record the prior bad state).
#
#   (b) Body ## Changelog section — all lines from a `## Changelog` heading
#       through the next `## ` heading or EOF.  Same rationale as (a): these
#       rows record historical change state, not live normative claims.
#
# ─────────────────────────────────────────────────────────────────────────────
# BLOCKING VALIDATOR — EXIT CONTRACT
# ─────────────────────────────────────────────────────────────────────────────
#
# Exit 1 if any FAIL lines are emitted; exit 0 otherwise.
# This is blocking validator #6; same PASS/WARN/FAIL/summary output contract
# as validators #1–#5.
#
# Usage:   bash .factory/hooks/verify-adr-decision-refs.sh
# Exit:    1 if FAIL > 0; 0 if FAIL == 0
#
# Integration (state-manager burst protocol):
#   Add as a validation step before the atomic factory-artifacts commit:
#     bash .factory/hooks/verify-adr-decision-refs.sh

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADR_DECISIONS_DIR="$FACTORY_DIR/specs/architecture/decisions"
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
# Phase 1: Build the decision map from ADR files.
# Phase 2: Scan spec files for ADR-NNN Decision N citations.
#
# Output: one line per citation-site finding:
#   PASS <filepath>:<lineno>  ADR-NNN Decision N
#   FAIL <filepath>:<lineno>  ADR-NNN Decision N  <reason>
#   WARN <filepath>:<lineno>  ADR-NNN Decision N  <reason>
#
# Plus one summary line per file:
#   FILE-PASS <filepath>      (no findings in this file)
#   FILE-WARN <filepath>      (only WARN-level findings)
#   FILE-FAIL <filepath>      (at least one FAIL-level finding)
#
# The shell layer processes these lines into emit() calls.

PYTHON_OUTPUT="$(python3 - "$ADR_DECISIONS_DIR" "$SPECS_ROOT" <<'PYEOF'
import sys, os, glob, re

adr_dir   = sys.argv[1]
specs_root = sys.argv[2]

# ── Phase 1: Build decision map ───────────────────────────────────────────────
#
# Map structure: { "ADR-NNN": set_of_int_decision_numbers }
# An ADR whose only Decision heading is unnumbered ("## Decision: ..." etc.)
# will have an empty set, which we use to detect fabricated numbered cites.
#
# The heading regex extracts BODY-only content (post-frontmatter).

# Matches "## Decision N" at the start of a line (N must be a bare integer
# optionally followed by space, em-dash, colon, or EOL).
DECISION_HEADING_RE = re.compile(r'^## Decision\s+(\d+)\b')

def parse_frontmatter_end(lines):
    """Return the 0-indexed line number of the closing '---' delimiter,
    or -1 if no valid frontmatter block found."""
    if not lines or lines[0].rstrip() != '---':
        return -1
    for i in range(1, len(lines)):
        if lines[i].rstrip() == '---':
            return i
    return -1

def build_changelog_ranges(lines, fm_end):
    """Return list of (start, end_exclusive) 0-indexed line ranges for
    body ## Changelog sections."""
    CHANGELOG_RE = re.compile(r'^## Changelog\s*$')
    SECTION_RE   = re.compile(r'^## ')
    ranges = []
    i = fm_end + 1
    while i < len(lines):
        if CHANGELOG_RE.match(lines[i]):
            start = i
            j = i + 1
            while j < len(lines):
                if SECTION_RE.match(lines[j]):
                    break
                j += 1
            ranges.append((start, j))
            i = j
        else:
            i += 1
    return ranges

def in_exempt_region(line_0idx, fm_end, changelog_ranges):
    """True if line_0idx is in frontmatter or a Changelog section."""
    if fm_end >= 0 and line_0idx <= fm_end:
        return True
    for (s, e) in changelog_ranges:
        if s <= line_0idx < e:
            return True
    return False

# ── Build decision map ────────────────────────────────────────────────────────

decision_map = {}   # "ADR-NNN" -> set of int decision numbers (may be empty)

adr_glob = os.path.join(adr_dir, 'ADR-*.md')
for filepath in sorted(glob.glob(adr_glob)):
    basename = os.path.basename(filepath)
    id_match = re.match(r'(ADR-\d{3})', basename)
    if not id_match:
        continue
    adr_id = id_match.group(1)

    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        # Unreadable ADR — map to empty set with a flag
        decision_map[adr_id] = None  # None = unreadable (distinct from empty set)
        continue

    fm_end = parse_frontmatter_end(lines)
    numbers = set()
    for i in range(fm_end + 1, len(lines)):
        m = DECISION_HEADING_RE.match(lines[i])
        if m:
            numbers.add(int(m.group(1)))

    decision_map[adr_id] = numbers  # empty set = ADR exists but has no numbered decisions

# ── Phase 2: Scan spec files for citations ────────────────────────────────────
#
# Pattern: ADR-NNN Decision N  (ADR-NNN must be exactly 3 digits)
CITE_RE = re.compile(r'\bADR-(\d{3})\s+Decision\s+(\d+)\b')

# Gather all .md files under specs_root
all_md_files = []
for root, dirs, files in os.walk(specs_root):
    # Skip hidden directories
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for fn in sorted(files):
        if fn.endswith('.md'):
            all_md_files.append(os.path.join(root, fn))
all_md_files.sort()

for filepath in all_md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError as e:
        print(f"WARN {filepath}:0 <unreadable> read-error:{e}")
        continue

    fm_end = parse_frontmatter_end(lines)
    cl_ranges = build_changelog_ranges(lines, fm_end)

    file_findings = []

    for i, line in enumerate(lines):
        if in_exempt_region(i, fm_end, cl_ranges):
            continue

        for m in CITE_RE.finditer(line):
            adr_num_str = m.group(1)        # e.g. "016"
            dec_num     = int(m.group(2))   # e.g. 6
            adr_id      = f"ADR-{adr_num_str}"
            lineno      = i + 1             # 1-indexed

            cite_label  = f"{adr_id} Decision {dec_num}"

            if adr_id not in decision_map:
                # No ADR file found — warn (file-existence is another validator's job)
                file_findings.append(
                    f"WARN {filepath}:{lineno} {cite_label} "
                    f"adr-file-not-found:{adr_id} not in decisions directory"
                )
            elif decision_map[adr_id] is None:
                # ADR file was unreadable
                file_findings.append(
                    f"WARN {filepath}:{lineno} {cite_label} "
                    f"adr-unreadable:{adr_id}"
                )
            elif len(decision_map[adr_id]) == 0:
                # ADR exists but has NO numbered decisions — fabricated cite
                file_findings.append(
                    f"FAIL {filepath}:{lineno} {cite_label} "
                    f"no-numbered-decisions:{adr_id} uses unnumbered-only "
                    f"Decision heading format; numbered citation is fabricated"
                )
            elif dec_num not in decision_map[adr_id]:
                # ADR has numbered decisions but this number is out-of-range
                max_dec = max(decision_map[adr_id])
                file_findings.append(
                    f"FAIL {filepath}:{lineno} {cite_label} "
                    f"out-of-range:ADR has Decisions 1-{max_dec}; {dec_num} does not exist"
                )
            else:
                # Citation is existence-valid
                file_findings.append(
                    f"PASS {filepath}:{lineno} {cite_label}"
                )

    for finding in file_findings:
        print(finding)

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

while IFS= read -r line; do
  # Lines are: LEVEL filepath:lineno rest...
  level="${line%% *}"
  rest="${line#* }"
  # filepath:lineno is the first token after level
  locref="${rest%% *}"
  detail="${rest#* }"
  # Strip leading FACTORY_DIR for readability
  short="${locref#"$FACTORY_DIR"/}"

  case "$level" in
    PASS)
      emit PASS "$short — $detail"
      ;;
    FAIL)
      emit FAIL "$short — $detail"
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
echo "verify-adr-decision-refs: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo ""
echo "NOTE: EXISTENCE-ONLY check. This script cannot detect semantically wrong"
echo "      but numerically valid Decision citations (F-P169-01 class)."
echo "      Semantic-correctness review is the adversary's responsibility."

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
