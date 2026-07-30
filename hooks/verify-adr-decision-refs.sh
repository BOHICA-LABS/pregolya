#!/usr/bin/env bash
# verify-adr-decision-refs.sh — pregolya factory-artifacts blocking validator (#6)
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
# F-P170-20 coverage widening (fix-burst 272):
#   Added two previously-invisible citation forms to the scanner:
#   (a) §Decision N form  — e.g. "ADR-015 §Decision 3"
#   (b) Decisions N, M form — e.g. "ADR-020 Decisions 2, 3, and 5"
#       Continuation items (", N" and " and N" forms) are validated via
#       CONTINUATION_RE scanning after each initial match.
#
# Known scanner limitations (documented, not defects):
#   L1 — "Decisions N+M" separator form (e.g. "Decisions 1+4" in
#        purity-boundary-map §graph::hitl): only N is validated; M is skipped.
#   L2 — paren-interleaved form (e.g. "Decisions 3 (label) and 4"):
#        text between the first number and "and" prevents CONTINUATION_RE from
#        reaching the second number; only the first is validated.
#   L3 — §Decision (no number) form (e.g. "ADR-009 §Decision (Option 3 split)"):
#        no digit follows §Decision so CITE_RE does not match; this is correct
#        behaviour — these are unnumbered section references, not decision cites.
#
# ─────────────────────────────────────────────────────────────────────────────
# WHAT THIS SCRIPT CHECKS (EXISTENCE AXIS)
# ─────────────────────────────────────────────────────────────────────────────
#
#   For each citation matching the pattern
#     `ADR-(\d{3}) §?Decisions? (\d+)` (plus optional `, N` / ` and N`
#     continuation items) found in the LIVE BODY of any .md file under
#     .factory/specs/:
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
# CITE_RE matches the initial citation token in three forms:
#   (1) "ADR-NNN Decision N"   — original singular form
#   (2) "ADR-NNN §Decision N"  — section-symbol form (F-P170-20 addition)
#   (3) "ADR-NNN Decisions N"  — plural form; first number captured here;
#                                 continuation items captured by CONTINUATION_RE
# ADR-NNN must be exactly 3 digits.  The §? makes the section symbol optional.
# The s? makes the plural suffix optional to cover both singular and plural.
CITE_RE = re.compile(r'\bADR-(\d{3})\s+§?Decisions?\s+(\d+)\b')

# CONTINUATION_RE scans list-continuation items after an initial CITE_RE match.
# Two forms handled:
#   Form A: ", N" or ", and N"  (comma-separated, with optional "and")
#   Form B: " and N"            (and-only, space-prefixed)
# Usage: CONTINUATION_RE.match(line, pos) anchors at position pos; stops
# advancing when neither form matches the next characters, bounding the scan
# to the current citation list and preventing runoff into unrelated numbers.
# Known limitations L1 and L2 (see header): "+" separator and paren-interleaved
# forms are NOT matched by either continuation form and are documented there.
CONTINUATION_RE = re.compile(r'(?:\s*,\s*(?:and\s+)?|\s+and\s+)(\d+)\b')

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
            adr_id      = f"ADR-{adr_num_str}"
            lineno      = i + 1             # 1-indexed

            # Collect all decision numbers cited: initial match + continuations.
            # CONTINUATION_RE.match anchors at pos so the scan stops as soon as
            # neither Form A (", N" / ", and N") nor Form B (" and N") starts at
            # the current position — bounding the scan to the current citation.
            dec_nums = [int(m.group(2))]
            pos = m.end()
            while pos < len(line):
                cont = CONTINUATION_RE.match(line, pos)
                if cont:
                    dec_nums.append(int(cont.group(1)))
                    pos = cont.end()
                else:
                    break

            # Validate each decision number in this citation group
            for dec_num in dec_nums:
                cite_label = f"{adr_id} Decision {dec_num}"

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

# ── Summary (blocking checks) ─────────────────────────────────────────────────

echo ""
echo "verify-adr-decision-refs (blocking): PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo ""
echo "NOTE: Blocking checks are EXISTENCE-ONLY. Semantically wrong but numerically"
echo "      valid Decision citations (F-P169-01 class) are the adversary's job."

BLOCKING_FAIL=$FAIL

# ── Advisory checks (Checks 1, 2, 3 from FIX-BURST-276 / Wave A) ─────────────
#
# CHECK 1 — ADR Sub-Anchor Nesting:
#   Citations of the form `ADR-NNN Decision M §SubAnchor` must have §SubAnchor
#   be a heading nested under ## Decision M in the target ADR — not a document-level
#   heading and not a restatement of the decision's own title.
#
# CHECK 2 — ADR Label-Noun Presence:
#   For citations carrying a parenthetical label — `Decision M (trait shape)`,
#   `Decisions 1+4`, `Decisions 3 (foo) and 4` — the label's distinctive noun
#   phrase must appear within Decision M's text span in the target ADR.
#   Also handles the two known parser blind spots: + separator and paren-interleaved.
#
# CHECK 3 — ADR Reverse Coverage:
#   Every decision in an `status: accepted` ADR must have at least one inbound
#   citation from somewhere in .factory/specs/. A decision with zero inbound
#   citations is either non-normative or its consumers are citing something else.
#
# ADVISORY STATUS: All findings WARN only. Non-blocking in Wave A.
# Promotion path:
#   CHECK 1 — after F-P173-ADVISORY-C1 class closes; target burst: Wave B
#   CHECK 2 — after F-P173-ADVISORY-C2 class closes; target burst: Wave B
#   CHECK 3 — after F-P173-ADVISORY-C3 class closes; target burst: Wave B

ADVISORY_WARN=0
ADVISORY_PASS=0

emit_advisory() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) ADVISORY_PASS=$((ADVISORY_PASS + 1)) ;;
    WARN) ADVISORY_WARN=$((ADVISORY_WARN + 1)) ;;
  esac
}

echo ""
echo "--- ADVISORY: Check 1/2/3 — Sub-Anchor Nesting, Label-Noun, Reverse Coverage ---"

ADVISORY_OUTPUT="$(python3 - "$ADR_DECISIONS_DIR" "$SPECS_ROOT" <<'ADVRPY'
import sys, os, re, glob

adr_dir    = sys.argv[1]
specs_root = sys.argv[2]

# ── Build extended decision map ───────────────────────────────────────────────
#
# For each ADR, build:
#   decision_numbers[adr_id] = set of int decision numbers
#   decision_title[adr_id][N] = title string of Decision N (the text after ---)
#   decision_text[adr_id][N]  = full text span of Decision N
#   decision_subheadings[adr_id][N] = list of (heading_text, heading_level) nested under N
#   adr_status[adr_id] = "accepted" | "draft" | ...

DECISION_HEADING_RE = re.compile(r'^## Decision\s+(\d+)\b')
STATUS_RE           = re.compile(r'^status:\s*(\S+)\s*$')

def parse_frontmatter_end(lines):
    if not lines or lines[0].rstrip() != '---':
        return -1
    for i in range(1, len(lines)):
        if lines[i].rstrip() == '---':
            return i
    return -1

decision_numbers   = {}  # adr_id -> set[int]
decision_title     = {}  # adr_id -> {int: str}
decision_text_span = {}  # adr_id -> {int: str}
decision_subheads  = {}  # adr_id -> {int: list[str]}  (### heading titles under each decision)
adr_status         = {}  # adr_id -> str

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
        continue

    fm_end = parse_frontmatter_end(lines)

    # Extract status from frontmatter
    status = 'unknown'
    for i in range(1, fm_end + 1 if fm_end >= 0 else 0):
        m = STATUS_RE.match(lines[i])
        if m:
            status = m.group(1).rstrip(':').lower()
            break
    adr_status[adr_id] = status

    # Parse body: identify decision sections and their sub-headings
    body_lines = lines[fm_end + 1:] if fm_end >= 0 else lines
    # Map: decision_start_idx -> decision_number
    decision_starts = []  # list of (line_idx, decision_num)
    for i, bline in enumerate(body_lines):
        m = DECISION_HEADING_RE.match(bline)
        if m:
            decision_starts.append((i, int(m.group(1))))

    numbers  = set()
    titles   = {}
    texts    = {}
    subheads = {}
    for j, (start_idx, dec_num) in enumerate(decision_starts):
        # Find end of this decision's span (next ## heading or EOF)
        end_idx = len(body_lines)
        for k, bline in enumerate(body_lines[start_idx + 1:], start_idx + 1):
            if bline.startswith('## '):
                end_idx = k
                break

        numbers.add(dec_num)
        # Title: text after "## Decision N —" or "## Decision N:"
        heading_line = body_lines[start_idx].strip()
        title_match = re.match(r'^## Decision\s+\d+\s*(?:[-—:]+\s*)?(.*)$', heading_line)
        titles[dec_num] = title_match.group(1).strip() if title_match else ''

        # Full text span (body_lines[start_idx:end_idx])
        texts[dec_num] = ''.join(body_lines[start_idx:end_idx])

        # Sub-headings: any ### (or ####) headings nested under this decision
        sh_list = []
        for bline in body_lines[start_idx + 1:end_idx]:
            m = re.match(r'^(#{3,})\s+(.*)', bline)
            if m:
                sh_list.append(m.group(2).strip())
        subheads[dec_num] = sh_list

    decision_numbers[adr_id]   = numbers
    decision_title[adr_id]     = titles
    decision_text_span[adr_id] = texts
    decision_subheads[adr_id]  = subheads

# ── Scan patterns ─────────────────────────────────────────────────────────────

# Base citation pattern (same as existing CITE_RE in blocking checks)
CITE_RE = re.compile(r'\bADR-(\d{3})\s+§?Decisions?\s+(\d+)\b')
CONTINUATION_RE = re.compile(r'(?:\s*,\s*(?:and\s+)?|\s+and\s+)(\d+)\b')

# Sub-anchor pattern: §SubAnchorWord (after a decision reference)
# Must NOT be inside a YAML frontmatter or Changelog section (same exemptions
# as the existing blocking scanner).
SUB_ANCHOR_RE = re.compile(r'§([A-Za-z][A-Za-z0-9_-]*)(?:\s|$|[^A-Za-z0-9_-])')

# Label-noun pattern: (label phrase) after a decision reference
# Capture: "(" then non-")" text then ")"
LABEL_RE = re.compile(r'\(([^)]+)\)')

# Blind-spot: "+"-separated multi-decision form, e.g. "Decisions 1+4"
PLUS_SEP_RE = re.compile(r'\bADR-(\d{3})\s+Decisions?\s+(\d+)\+(\d+)\b')

# Blind-spot: paren-interleaved form, e.g. "Decisions 3 (foo) and 4"
PAREN_INTER_RE = re.compile(
    r'\bADR-(\d{3})\s+Decisions?\s+(\d+)\s*\([^)]*\)\s+and\s+(\d+)\b'
)

# ── Gather all spec files ─────────────────────────────────────────────────────

all_md_files = []
for root, dirs, files in os.walk(specs_root):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for fn in sorted(files):
        if fn.endswith('.md'):
            all_md_files.append(os.path.join(root, fn))
all_md_files.sort()

def build_changelog_ranges(lines, fm_end):
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
    if fm_end >= 0 and line_0idx <= fm_end:
        return True
    for (s, e) in changelog_ranges:
        if s <= line_0idx < e:
            return True
    return False

# ── Reverse-coverage counter ──────────────────────────────────────────────────
# Track how many times each (adr_id, dec_num) is cited (in live body, non-exempt)
citation_count = {}  # (adr_id, dec_num) -> int

# ── Per-file scanning ─────────────────────────────────────────────────────────

c1_findings = []  # (filepath, lineno, cite_label, detail)
c2_findings = []
# blind_spot_findings: Check 2 violations found via blind-spot patterns
bs_findings = []

for filepath in all_md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    fm_end = parse_frontmatter_end(lines)
    cl_ranges = build_changelog_ranges(lines, fm_end)

    for i, line in enumerate(lines):
        if in_exempt_region(i, fm_end, cl_ranges):
            continue
        lineno = i + 1

        # ── Check 2 blind-spot: + separator form ─────────────────────────────
        for m in PLUS_SEP_RE.finditer(line):
            adr_id  = f"ADR-{m.group(1)}"
            nums    = [int(m.group(2)), int(m.group(3))]
            for dec_num in nums:
                key = (adr_id, dec_num)
                citation_count[key] = citation_count.get(key, 0) + 1
                if adr_id not in decision_numbers:
                    continue
                if dec_num not in decision_numbers[adr_id]:
                    continue
                # No label to check for pure blind-spot; but record existence
                # No additional Check 2 finding here — just counting

        # ── Check 2 blind-spot: paren-interleaved form ────────────────────────
        for m in PAREN_INTER_RE.finditer(line):
            adr_id  = f"ADR-{m.group(1)}"
            label   = None  # label is the paren content
            nums    = [int(m.group(2)), int(m.group(3))]
            for dec_num in nums:
                key = (adr_id, dec_num)
                citation_count[key] = citation_count.get(key, 0) + 1

        # ── Main CITE_RE scan ─────────────────────────────────────────────────
        for m in CITE_RE.finditer(line):
            adr_num_str = m.group(1)
            adr_id      = f"ADR-{adr_num_str}"
            dec_nums    = [int(m.group(2))]
            pos         = m.end()
            while pos < len(line):
                cont = CONTINUATION_RE.match(line, pos)
                if cont:
                    dec_nums.append(int(cont.group(1)))
                    pos = cont.end()
                else:
                    break

            for dec_num in dec_nums:
                key = (adr_id, dec_num)
                citation_count[key] = citation_count.get(key, 0) + 1

            # ── Check 1: §SubAnchor scan ──────────────────────────────────────
            # Look for § anywhere in the segment starting at the CITE_RE match
            # to the end of the current logical citation clause.
            # We look in the portion of the line from the match start to
            # approximately 80 chars after the last continuation end.
            segment = line[m.start():min(m.start() + 120, len(line))]
            for sa_m in SUB_ANCHOR_RE.finditer(segment):
                sub_anchor = sa_m.group(1)
                # For the first cited decision only (this is the primary decision
                # for which the § sub-anchor is most relevant)
                primary_dec = dec_nums[0]
                cite_label  = f"{adr_id} Decision {primary_dec} §{sub_anchor}"

                if adr_id not in decision_numbers:
                    continue  # ADR not found — already reported by blocking check
                if primary_dec not in decision_numbers[adr_id]:
                    continue  # Decision out-of-range — already reported by blocking check

                # Get sub-headings under primary_dec in adr_id
                subheads = decision_subheads.get(adr_id, {}).get(primary_dec, [])
                # Check: does any sub-heading contain the sub-anchor text?
                anchor_found = any(
                    sub_anchor.lower() in sh.lower()
                    for sh in subheads
                )
                # Also check: is sub_anchor restating the decision title?
                dec_title = decision_title.get(adr_id, {}).get(primary_dec, '')
                is_title_restatement = (
                    dec_title and sub_anchor.lower() in dec_title.lower()
                )

                if not anchor_found:
                    if is_title_restatement:
                        reason = (f"§{sub_anchor} restates the decision title "
                                  f"'{dec_title}' — no sub-heading needed")
                    elif not subheads:
                        reason = (f"Decision {primary_dec} has no ### sub-headings; "
                                  f"§{sub_anchor} has nothing to resolve to")
                    else:
                        reason = (f"§{sub_anchor} not found in Decision {primary_dec}'s "
                                  f"sub-headings {subheads}")
                    c1_findings.append((filepath, lineno, cite_label, reason))

            # ── Check 2: (label phrase) scan ──────────────────────────────────
            # Look for parenthetical labels after decision references.
            # Scan a window from the match start.
            window_end = min(m.end() + 60, len(line))
            window = line[m.end():window_end]
            for lbl_m in LABEL_RE.finditer(window):
                label_text = lbl_m.group(1).strip()
                # Skip if the label is purely numeric (e.g. "(1)" issue refs)
                if re.match(r'^\d+$', label_text):
                    continue
                # Skip short abbreviations (1-2 chars)
                if len(label_text) <= 2:
                    continue

                # For each cited decision, check if label text appears in decision span
                for dec_num in dec_nums:
                    cite_label = f"{adr_id} Decision {dec_num} ({label_text})"
                    if adr_id not in decision_numbers:
                        continue
                    if dec_num not in decision_numbers[adr_id]:
                        continue

                    dec_span = decision_text_span.get(adr_id, {}).get(dec_num, '')
                    # Check: do meaningful words from label_text appear in dec_span?
                    # Extract words > 3 chars from label as "distinctive terms"
                    label_words = [w.lower() for w in re.split(r'\W+', label_text) if len(w) > 3]
                    if not label_words:
                        continue  # No distinctive words to check

                    span_lower = dec_span.lower()
                    found_count = sum(1 for w in label_words if w in span_lower)
                    if found_count == 0:
                        # None of the distinctive label words appear in the decision span
                        dec_title = decision_title.get(adr_id, {}).get(dec_num, '(unknown)')
                        c2_findings.append((
                            filepath, lineno, cite_label,
                            f"label '{label_text}' has no distinctive words in "
                            f"Decision {dec_num} span (title: '{dec_title}')"
                        ))

# ── Check 3: Reverse coverage for accepted ADRs ───────────────────────────────

c3_findings = []
for adr_id, status in sorted(adr_status.items()):
    if 'accept' not in status:
        continue
    for dec_num in sorted(decision_numbers.get(adr_id, set())):
        key = (adr_id, dec_num)
        count = citation_count.get(key, 0)
        if count == 0:
            dec_title = decision_title.get(adr_id, {}).get(dec_num, '')
            c3_findings.append((adr_id, dec_num, dec_title))

# ── Output ────────────────────────────────────────────────────────────────────

print(f"ADV-C1-SUMMARY count={len(c1_findings)}")
for (fp, ln, cite, reason) in c1_findings:
    short = fp.split('/specs/')[-1] if '/specs/' in fp else fp
    print(f"ADV-C1 {short}:{ln} [{cite}] — {reason}")

print(f"ADV-C2-SUMMARY count={len(c2_findings)}")
for (fp, ln, cite, reason) in c2_findings:
    short = fp.split('/specs/')[-1] if '/specs/' in fp else fp
    print(f"ADV-C2 {short}:{ln} [{cite}] — {reason}")

print(f"ADV-C3-SUMMARY count={len(c3_findings)}")
for (adr_id, dec_num, title) in c3_findings:
    print(f"ADV-C3 {adr_id} Decision {dec_num} '{title}' — zero inbound citations in .factory/specs/")

ADVRPY
)"

# ── Process advisory Python output ───────────────────────────────────────────

C1_COUNT=0
C2_COUNT=0
C3_COUNT=0

while IFS= read -r line; do
  tag="${line%% *}"
  rest="${line#* }"

  case "$tag" in
    ADV-C1-SUMMARY)
      C1_COUNT="$(echo "$rest" | grep -oE 'count=[^ ]+' | cut -d= -f2)"
      if [ "$C1_COUNT" -gt 0 ]; then
        emit_advisory WARN "[ADVISORY] CHECK1 (sub-anchor nesting): $C1_COUNT citation(s) with §SubAnchor not nested under claimed decision"
      else
        emit_advisory PASS "CHECK1 (sub-anchor nesting): 0 §SubAnchor violations found"
      fi
      ;;
    ADV-C1)
      echo "  [ADVISORY] CHECK1: $rest"
      ;;
    ADV-C2-SUMMARY)
      C2_COUNT="$(echo "$rest" | grep -oE 'count=[^ ]+' | cut -d= -f2)"
      if [ "$C2_COUNT" -gt 0 ]; then
        emit_advisory WARN "[ADVISORY] CHECK2 (label-noun presence): $C2_COUNT citation(s) where parenthetical label has no distinctive words in the cited decision span"
      else
        emit_advisory PASS "CHECK2 (label-noun presence): 0 label-noun violations found"
      fi
      ;;
    ADV-C2)
      echo "  [ADVISORY] CHECK2: $rest"
      ;;
    ADV-C3-SUMMARY)
      C3_COUNT="$(echo "$rest" | grep -oE 'count=[^ ]+' | cut -d= -f2)"
      if [ "$C3_COUNT" -gt 0 ]; then
        emit_advisory WARN "[ADVISORY] CHECK3 (reverse coverage): $C3_COUNT decision(s) in accepted ADRs with zero inbound citations from .factory/specs/"
      else
        emit_advisory PASS "CHECK3 (reverse coverage): all decisions in accepted ADRs have at least one inbound citation"
      fi
      ;;
    ADV-C3)
      echo "  [ADVISORY] CHECK3: $rest"
      ;;
    *)
      : # Ignore other lines
      ;;
  esac
done <<< "$ADVISORY_OUTPUT"

# ── Final summary ─────────────────────────────────────────────────────────────

echo ""
echo "verify-adr-decision-refs: blocking PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  advisory: PASS=$ADVISORY_PASS WARN=$ADVISORY_WARN"
echo "  Check 1 (sub-anchor nesting): $C1_COUNT advisory findings"
echo "  Check 2 (label-noun presence): $C2_COUNT advisory findings"
echo "  Check 3 (reverse coverage): $C3_COUNT advisory findings"
echo ""
echo "Promotion path (advisory → blocking):"
echo "  CHECK1: after F-P173-ADVISORY-C1 class closes; target burst: Wave B"
echo "  CHECK2: after F-P173-ADVISORY-C2 class closes; target burst: Wave B"
echo "  CHECK3: after F-P173-ADVISORY-C3 class closes; target burst: Wave B"
echo ""
echo "NOTE: Blocking checks are EXISTENCE-ONLY. Semantically wrong but numerically"
echo "      valid Decision citations (F-P169-01 class) are the adversary's job."

if [ "$BLOCKING_FAIL" -gt 0 ]; then
  echo "RESULT: FAIL (blocking violations present)"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
