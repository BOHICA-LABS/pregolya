#!/usr/bin/env bash
# verify-adr-anchor-citations.sh — ADR §Named-Section citation existence gate
#
# PURPOSE
# ───────
# Enforces ADR-022 §Decision 3 across all .md files under .factory/specs/.
# For every `ADR-NNN §Section-Text` citation in normative (non-changelog, non-fence,
# non-illustration) positions, verifies that a heading starting with Section-Text
# exists in the target ADR file, and that the match is unambiguous (exactly one
# heading). Also detects chained double-§ forms (ADR-NNN §X §Y) and bare §Section
# citations that lack an ADR-NNN prefix in live-body normative prose.
#
# BLOCKING — migration complete (burst-290)
#
# SPEC AUTHORITY
# ──────────────
# ADR-022 §Decision 3 — Machine verification spec for §Name citation existence
# ADR-022 §Decision 5 — Chained double-§ prohibition (ADR-NNN §X §Y form)
# Closes: F-P176-E001 (CRIT), F-P176-A039 (HIGH), F-P176-A007 (HIGH), F-180-PG (PROCESS)
#
# VALIDATION RULES
# ────────────────
# For each `ADR-NNN §Section-Text` citation (in normative positions):
#   1. Find the target ADR file: specs/architecture/decisions/ADR-NNN-*.md
#   2. Read the target body (post-frontmatter)
#   3. Find headings starting with Section-Text (prefix match, case-sensitive)
#      using longest-prefix matching to handle trailing-context text
#   4. FAIL: no heading starts with Section-Text (phantom anchor — D-106 class)
#   5. FAIL: multiple headings start with Section-Text (ambiguous citation)
#   6. PASS: exactly one heading starts with Section-Text
#
# For each `ADR-NNN §X §Y` chained form (ADR-022 §Decision 5 prohibited):
#   7. FAIL (chained): two §-anchors following a single ADR reference
#      Note: §Decision N is NOT excluded here (unlike CITE_RE) because
#      ADR-NNN §Decision N §PhantomSub is the archetypal chained violation.
#      Post-filter: skip if the text between the two § contains another ADR-NNN
#      (would be two separate ADR citations, not a chained form).
#
# For bare `§Section` without ADR-NNN prefix in live-body normative prose:
#   8. FAIL (ambiguous): bare §-reference without resolvable doc-ID context
#      and without a same-file heading match.
#
# EXCLUSIONS (live-body scope — normative content only)
# ─────────────────────────────────────────────────────
# - YAML frontmatter and ## Changelog body sections (changelog_exempt_lines)
# - Content inside fenced code blocks (``` ... ```)
# - Content inside inline backtick spans (`...`)
# - Content inside illustration regions (discriminator:illustration-start/end)
# - Lines starting with #, |, > (headings, tables, blockquotes)
# - Lines whose raw content matches LINE_DOC_ID_RE (whole-line doc-ID context):
#     ADR-NNN, BC-N.NN.NNN, VP-NNN, F-P*, P1D-*, ADV-P*, OBS-P*, INDEX identifiers,
#     and *.md file references — these carry convention-bound non-ADR §-citations
# - Bare-§ refs that resolve to a same-file heading (self-references) or whose
#     § text is an ALL-CAPS acronym matching a same-file heading's word initials
# - Bare-§ where last token before § is a lowercase-hyphenated doc shortname
#     (product-brief, interface-definitions, error-taxonomy, arch-registry, etc.)
# - Bare-§ where last token before § is a connector word or list marker
#     (≤ 2 chars, or in _CONNECTOR_WORDS: 'the', 'see', 'overflow', 'brief', ...)
# - Bare-§ where section_text ends with em-dash '—' (table/list prefix fragments)
# - Bare-§ where section_text is a lowercase-hyphenated slug (code identifiers)
#
# NOT IN SCOPE
# ────────────
# - `ADR-NNN §Decision N` pure-numeric: verify-adr-decision-refs.sh scope
# - `ADR-NNN §Decision N Amendment` (numeric+Amendment): excluded by CITE_RE
#     negative lookahead; 16 instances in corpus.
# - Non-ADR §-target citations (BC-NNN §Section, VP-NNN §Section, ADV-P §Section,
#     etc.): ~183 instances; convention-bound per ADR-022 §Decision 1; handled by
#     LINE_DOC_ID_RE whole-line skip + same-file heading match.
#
# COVERAGE STATEMENT
# ──────────────────
# Raw ADR-NNN §Section occurrences corpus-wide: 217
# After exemptions applied by this gate:
#   Excluded — changelog/frontmatter: 133 (historical narrative, not normative)
#   Excluded — fenced code blocks:      7
#   Excluded — inline backtick spans:  16
#   Excluded — illustration regions:    2
#   Excluded — §Decision N numeric:   ~16 (verify-adr-decision-refs.sh scope)
#   Excluded — chained double-§:        0 (burst-290 sweep complete)
# This gate scans: 42 normative prose ADR-target §-citations (CITE_RE)
#                  + corpus-wide chained double-§ scan (CHAINED_RE)
#                  + bare-§ in live-body normative (BARE_SECT_RE with exclusions)
#
# SELF-PROBES (7 mandatory)
# ─────────────────────────
# 1. Phantom anchor (no heading) detected as CITATION_FAIL
# 2. Valid anchor (heading exists) detected as CITATION_PASS
# 3. Ambiguous anchor (multiple headings) detected as CITATION_AMBIG
# 4. Inline-backtick exemption: backtick-quoted citation not flagged
# 5. Changelog-section exemption: citation in ## Changelog not flagged
# 6. Chained double-§ form detected as CITATION_CHAINED  (new — burst-290)
# 7. Valid single-§ still passes; not flagged as CITATION_CHAINED (new — burst-290)
#
# Usage:  bash .factory/hooks/verify-adr-anchor-citations.sh
# Exit:   1 if any phantom/chained/ambiguous/bare-§ found; 0 if all clean
#
# Integration: wired as BLOCKING in pre-commit-validators.sh (burst-290).

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
SPECS_DIR="$FACTORY_DIR/specs"
ADR_DIR="$SPECS_DIR/architecture/decisions"

PASS=0
FAIL=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
  esac
}

# ── Core Python scanner ───────────────────────────────────────────────────────
# Arguments: <hooks_dir> <scan_dir> <adr_dir>
# Output lines (4 columns, tab-separated):
#   CITATION_PASS     <adr_num>  <section_text>  <file>   valid (exactly one heading match)
#   CITATION_FAIL     <adr_num>  <section_text>  <file>   phantom (no heading match)
#   CITATION_CHAINED  <adr_num>  <section_text>  <file>   chained double-§ (ADR-NNN §X §Y)
#   CITATION_AMBIG    <adr_num>  <section_text>  <file>   ambiguous (multiple matches) or bare-§
#   CITATION_NOTGT    <adr_num>  <section_text>  <file>   target ADR file not found on disk
run_anchor_scanner() {
  local hooks_dir="$1" scan_dir="$2" adr_dir="$3"
  python3 - "$hooks_dir" "$scan_dir" "$adr_dir" <<'PYEOF'
import sys, glob, re, os

hooks_dir = sys.argv[1]
scan_dir  = sys.argv[2]
adr_dir   = sys.argv[3]
sys.path.insert(0, hooks_dir)
from spec_region_utils import changelog_exempt_lines, illustration_exempt_lines

# ── Compiled patterns ─────────────────────────────────────────────────────────

# ADR-NNN §Section-Text — the §Name citation.
# Captures: group(1) = 3-digit ADR number, group(2) = section text.
# EXCLUSION: Pure numeric decision citations (§Decision N) are
# handled by verify-adr-decision-refs.sh and excluded here to avoid
# double-reporting (negative lookahead).
CITE_RE = re.compile(
    r'\bADR-(\d{3})\s+§'
    r'(?!Decisions?\s+\d+(?:[,.:;\'\")\]\s]|$))'  # skip §Decision N (pure numeric)
    r'([A-Za-z][^\n`]{0,80}?)'  # capture text starting with letter
    r'(?=[`\n]|[,.:;\'\")\]]|\s{2,}|\s*$)'  # stop at natural terminators
)

# ADR-NNN §X §Y — chained double-§ form (ADR-022 §Decision 5 prohibited).
# NO negative lookahead for §Decision N — §Decision N §Sub is the archetypal violation.
# group(1) = adr_num, group(2) = first section text (no § allowed), group(3) = second.
# Post-filter: skip if group(2) contains another ADR-NNN (two separate ADR citations).
CHAINED_RE = re.compile(
    r'\bADR-(\d{3})\s+§'
    r'([A-Za-z][^\n\xa7`]{1,80}?)\s*'     # first section text — no § char (\xa7)
    r'\xa7'                                # the § separator (literal U+00A7)
    r'([A-Za-z][^\n`]{0,80}?)'            # second section text
    r'(?=[`\n]|[,.:;\'\")\]]|\s{2,}|\s*$)'
)

# Heading detection: any markdown heading level (#+ text)
HEADING_RE = re.compile(r'^(#{1,6})\s+(.+?)\s*$', re.MULTILINE)

# Inline backtick span (single-line)
INLINE_TICK_RE = re.compile(r'`[^`\n]*`')

# Bare §Section without doc prefix — detects § not already covered by CITE_RE/CHAINED_RE
BARE_SECT_RE = re.compile(
    r'\xa7([A-Za-z][^\n\xa7`]{0,80}?)'    # § followed by section text (no nested §)
    r'(?=[`\n]|[,.:;\'\")\]]|\s{2,}|\s*$)'
)

# Whole-line doc-ID context: if any of these appear on the raw line,
# skip all bare-§ scanning on this line (convention-bound non-ADR citations).
# Applied against the ORIGINAL LINE (pre-backtick-strip) to catch *.md refs.
LINE_DOC_ID_RE = re.compile(
    r'(?:'
    r'\bADR-\d{3}\b'                           # ADR-022
    r'|BC-\d+\.\d+\.\d+\b'                    # BC-2.13.005
    r'|\bVP-\d{3}\b'                           # VP-006
    r'|\bF-P\d+[A-Z0-9]*-[A-Z0-9]'            # F-P47-01, F-P176-C028
    r'|\bP\dD-\d'                              # P1D-177
    r'|\bADV-P'                                # ADV-P1D-PASS-29
    r'|\bOBS-P\d'                              # OBS-P29-2
    r'|\b(?:ARCH|BC|VP|STORY|L2|EVAL)-INDEX\b' # index doc IDs
    r'|\S+\.md\b'                              # *.md file references
    r')'
)

# Lowercase-hyphenated pattern: matches doc shortnames (product-brief, error-taxonomy)
# and code-identifier slugs (layer-disambiguation). Compiled once for efficiency.
_LOWERCASE_HYPH_RE = re.compile(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)+$')

# Connector/shortname tokens that legitimately precede bare-§ references.
# Function words and list-item markers are contextual — not standalone ADR anchors.
# 'overflow' = Overflow section of product-brief; 'brief' = product-brief shorthand.
_CONNECTOR_WORDS = frozenset({
    'a', 'an', 'the', 'in', 'at', 'of', 'to', 'by', 'on', 'or', 'and',
    'as', 'if', 'is', 'it', 'be', 'do', 'so', 'see', 'per', 'via',
    'for', 'with', 'from', 'not', 'but', 'this', 'that', 'each', 'when',
    'what', 'which', 'such', 'all', 'some', 'any', 'its', 'second',
    'where', 'how', 'note', 'than', 'also', 'only', 'even', 'then',
    'cf', 'ref',
    # Project-specific doc-section shortnames used as inline cross-doc context
    'overflow', 'brief',
})

def build_fence_exempt(lines):
    """Return frozenset of 0-indexed line numbers inside fenced code blocks."""
    exempt = set()
    in_fence = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not in_fence:
            if stripped.startswith('```'):
                in_fence = True
                exempt.add(i)
        else:
            exempt.add(i)
            if stripped == '```':
                in_fence = False
    return frozenset(exempt)

# ── ADR heading cache ─────────────────────────────────────────────────────────
_adr_cache = {}

def get_adr_headings(adr_num):
    """Load headings from target ADR file. Returns (path, [heading_text])."""
    if adr_num in _adr_cache:
        return _adr_cache[adr_num]

    pattern = os.path.join(adr_dir, f'ADR-{adr_num}-*.md')
    matches = glob.glob(pattern)
    if not matches:
        _adr_cache[adr_num] = (None, [])
        return (None, [])

    adr_path = matches[0]
    try:
        with open(adr_path, 'r', encoding='utf-8') as fh:
            raw = fh.read()
    except OSError:
        _adr_cache[adr_num] = (adr_path, [])
        return (adr_path, [])

    lines = raw.splitlines()
    body_start = 0
    if lines and lines[0].strip() == '---':
        for j in range(1, len(lines)):
            if lines[j].strip() == '---':
                body_start = j + 1
                break
    body = '\n'.join(lines[body_start:])
    headings = [m.group(2).strip() for m in HEADING_RE.finditer(body)]
    _adr_cache[adr_num] = (adr_path, headings)
    return (adr_path, headings)

def get_file_headings(raw_lines):
    """Extract heading texts from arbitrary file lines (post-frontmatter)."""
    body_start = 0
    if raw_lines and raw_lines[0].strip() == '---':
        for j in range(1, len(raw_lines)):
            if raw_lines[j].strip() == '---':
                body_start = j + 1
                break
    body = ''.join(raw_lines[body_start:])
    return [m.group(2).strip() for m in HEADING_RE.finditer(body)]

def find_matching_heading(section_text, headings):
    """
    Longest-prefix match: progressively shorter prefixes of section_text,
    returns list of headings that match the best (longest) prefix found.
    """
    candidate = section_text.rstrip(' .,;:\'\")')
    words = candidate.split()
    if not words:
        return []
    for length in range(len(words), 0, -1):
        prefix = ' '.join(words[:length])
        matched = [h for h in headings if h.startswith(prefix)]
        if matched:
            return matched
    return []

def has_heading_match(section_text, headings):
    """True if section_text (or a prefix) matches the start of any heading."""
    return len(find_matching_heading(section_text, headings)) > 0

def is_acronym_of_heading(acronym, headings):
    """True if acronym == initials of the first N alpha-starting words of any heading."""
    n = len(acronym)
    if n < 2 or n > 8:
        return False
    for h in headings:
        words = [w for w in h.split() if w[:1].isalpha()]
        if len(words) >= n:
            initials = ''.join(w[0].upper() for w in words[:n])
            if initials == acronym.upper():
                return True
    return False

# ── Main scan ─────────────────────────────────────────────────────────────────
md_files = sorted(glob.glob(os.path.join(scan_dir, '**', '*.md'), recursive=True))

results = []

for filepath in md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    if '\xa7' not in ''.join(lines):  # § (U+00A7) — quick skip
        continue

    rel           = filepath.replace(scan_dir.rstrip('/') + '/', '')
    cl_exempt     = changelog_exempt_lines(lines)
    il_exempt     = illustration_exempt_lines(lines)
    fence_exempt  = build_fence_exempt(lines)
    file_headings = get_file_headings(lines)

    for i, raw_line in enumerate(lines):
        if i in cl_exempt or i in il_exempt or i in fence_exempt:
            continue
        if '\xa7' not in raw_line:
            continue

        # Strip inline backtick spans before scanning CITE_RE and CHAINED_RE
        stripped = INLINE_TICK_RE.sub('', raw_line)

        # ── CHAINED_RE (process BEFORE CITE_RE — chained takes precedence) ────
        chained_starts = set()
        chain_spans    = set()

        for m in CHAINED_RE.finditer(stripped):
            first_text = m.group(2)
            # Post-filter: two separate ADR citations on one line, not a chain
            if re.search(r'\bADR-\d{3}\b', first_text):
                continue
            chained_starts.add(m.start())
            chain_spans.update(range(m.start(), m.end()))
            adr_num = m.group(1)
            # Report the full chained form for clarity
            section_text = m.group(2).rstrip() + ' \xa7' + m.group(3).strip()
            results.append(('CHAINED', adr_num, section_text, rel))

        # ── CITE_RE (ADR-NNN §Named-Section existence check) ──────────────────
        cite_spans = set()

        for m in CITE_RE.finditer(stripped):
            # Suppress CITE_RE result when CHAINED_RE already covers this ADR ref
            if m.start() in chained_starts:
                continue
            cite_spans.update(range(m.start(), m.end()))
            adr_num      = m.group(1)
            section_text = m.group(2).strip()
            if not section_text:
                continue

            adr_path, headings = get_adr_headings(adr_num)
            if adr_path is None:
                results.append(('NOTGT', adr_num, section_text, rel))
                continue

            matching = find_matching_heading(section_text, headings)
            if len(matching) == 0:
                results.append(('FAIL', adr_num, section_text, rel))
            elif len(matching) == 1:
                results.append(('PASS', adr_num, section_text, rel))
            else:
                results.append(('AMBIG', adr_num, section_text, rel))

        # ── BARE_SECT_RE (§Section without ADR-NNN prefix) ────────────────────
        if '\xa7' not in stripped:
            continue

        # Positions already covered by CITE_RE or CHAINED_RE — skip these
        covered = cite_spans | chain_spans

        # Whole-line doc-ID check on ORIGINAL LINE (preserves backtick content).
        # Non-ADR §citations on lines with doc-ID context are convention-bound.
        if LINE_DOC_ID_RE.search(raw_line):
            continue

        # Line structure: skip headings, tables, blockquotes
        line_s = raw_line.strip()
        if line_s.startswith('#') or line_s.startswith('|') or line_s.startswith('>'):
            continue

        for bm in BARE_SECT_RE.finditer(stripped):
            if bm.start() in covered:
                continue
            section_text = bm.group(1).strip()
            if not section_text:
                continue

            # Skip **§ bold-annotation markers (e.g. **§FewShot harness note:**)
            text_before = stripped[:bm.start()]
            if text_before.rstrip().endswith('**'):
                continue

            # Last-token analysis: what word/token precedes this §?
            tokens = text_before.split()
            last_token = tokens[-1] if tokens else ''
            # Strip leading non-alphanumeric (removes **, (, etc.)
            last_token_clean = re.sub(r'^[^A-Za-z0-9]+', '', last_token)

            # Skip if last token is a known doc-ID prefix pattern
            if re.match(
                r'^(?:ADR|BC|VP|F-P|P\dD|ADV|OBS|ARCH|STORY|L2|EVAL)',
                last_token_clean
            ):
                continue
            if last_token_clean.endswith('.md'):
                continue
            if '/' in last_token_clean:  # path reference (e.g. assessment-parts/part-3)
                continue

            # Lowercase-hyphenated doc shortnames (product-brief, interface-definitions,
            # error-taxonomy, arch-registry, etc.): cross-document references, not
            # standalone bare-§ anchors.
            if _LOWERCASE_HYPH_RE.match(last_token_clean):
                continue

            # Connector tokens + project shortnames: unconditional skip.
            # Covers function words, list markers (≤2 chars), and named doc-section
            # shortnames ('overflow' for product-brief Overflow section, 'brief').
            if len(last_token_clean) <= 2 or last_token_clean.lower() in _CONNECTOR_WORDS:
                continue

            # Section_text ending with em-dash/en-dash: table/list prefix fragment
            # (e.g., §VS —, §EMBED —, §Scope cross-cutting —).
            if section_text.endswith('—') or section_text.endswith('–'):
                continue

            # Lowercase-hyphenated slug as section_text: code identifier or invariant
            # name (e.g., §layer-disambiguation) — not a markdown heading reference.
            if _LOWERCASE_HYPH_RE.match(section_text):
                continue

            # Same-file heading match (self-reference to a heading in this document)
            if has_heading_match(section_text, file_headings):
                continue

            # ALL-CAPS acronym: §GTV → Golden Test Vectors (checks word initials)
            first_word = section_text.split()[0] if section_text.split() else ''
            if re.match(r'^[A-Z]{2,8}$', first_word):
                if is_acronym_of_heading(first_word, file_headings):
                    continue

            # Bare-§ without resolvable context — flag as AMBIG
            results.append(('AMBIG', 'N/A', section_text, rel))

# ── Emit output ───────────────────────────────────────────────────────────────
for outcome, adr_num, section_text, rel in results:
    print(f'CITATION_{outcome}\t{adr_num}\t{section_text}\t{rel}')
PYEOF
}

# ── Self-probe infrastructure ─────────────────────────────────────────────────
PROBE_TMP=""

init_probe_tmp() {
  PROBE_TMP="$(mktemp -d)"
  mkdir -p "$PROBE_TMP/specs/architecture/decisions"
}

clean_probe_tmp() {
  [ -n "$PROBE_TMP" ] && [ -d "$PROBE_TMP" ] && rm -rf "$PROBE_TMP"
  PROBE_TMP=""
}

# ── Probe 1: Phantom anchor detected ─────────────────────────────────────────
probe_phantom_anchor() {
  init_probe_tmp
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Postconditions

See ADR-099 §NonExistent Section for error handling.
PROBEOF
  cat > "$PROBE_TMP/specs/architecture/decisions/ADR-099-test.md" <<'PROBEOF'
---
title: "Test ADR"
---
# ADR-099: Test

## Context

Some context.

## Decision

Some decision.
PROBEOF
  local out
  out="$(run_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP/specs/architecture/decisions")"
  if ! echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 1: phantom anchor (no heading) not detected."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 1: phantom anchor detected as CITATION_FAIL."
}

# ── Probe 2: Valid anchor detected ───────────────────────────────────────────
probe_valid_anchor() {
  init_probe_tmp
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Postconditions

See ADR-099 §Decision for error handling.
PROBEOF
  cat > "$PROBE_TMP/specs/architecture/decisions/ADR-099-test.md" <<'PROBEOF'
---
title: "Test ADR"
---
# ADR-099: Test

## Context

Some context.

## Decision

Some decision.
PROBEOF
  local out
  out="$(run_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP/specs/architecture/decisions")"
  if ! echo "$out" | grep -qF 'CITATION_PASS'; then
    echo "[SELF-PROBE FAIL] Probe 2: valid anchor not detected as CITATION_PASS."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 2: valid anchor incorrectly flagged as CITATION_FAIL."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 2: valid anchor detected as CITATION_PASS."
}

# ── Probe 3: Ambiguous anchor detected ───────────────────────────────────────
probe_ambiguous_anchor() {
  init_probe_tmp
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Postconditions

See ADR-099 §Class for the class definition.
PROBEOF
  cat > "$PROBE_TMP/specs/architecture/decisions/ADR-099-test.md" <<'PROBEOF'
---
title: "Test ADR"
---
# ADR-099: Test

## Class A — first class

Some content.

## Class B — second class

Other content.
PROBEOF
  local out
  out="$(run_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP/specs/architecture/decisions")"
  if ! echo "$out" | grep -qF 'CITATION_AMBIG'; then
    echo "[SELF-PROBE FAIL] Probe 3: ambiguous anchor not detected as CITATION_AMBIG."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 3: ambiguous anchor detected as CITATION_AMBIG."
}

# ── Probe 4: Inline-backtick exemption ───────────────────────────────────────
probe_backtick_exempt() {
  init_probe_tmp
  printf '## Description\n\nSee `ADR-099 §NonExistent` for details.\n' \
    > "$PROBE_TMP/specs/source.md"
  cat > "$PROBE_TMP/specs/architecture/decisions/ADR-099-test.md" <<'PROBEOF'
---
title: "Test ADR"
---
# ADR-099: Test

## Decision

Some decision.
PROBEOF
  local out
  out="$(run_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP/specs/architecture/decisions")"
  if echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 4: inline-backtick ADR citation was incorrectly flagged."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 4: inline-backtick citation not flagged (exempt)."
}

# ── Probe 5: Changelog-section exemption ─────────────────────────────────────
probe_changelog_exempt() {
  init_probe_tmp
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
---
document_type: bc
version: "1.1"
---

## Description

Normal body content.

## Changelog

- 1.1 (2026-08-01): Updated per ADR-099 §NonExistentInChangelog.
PROBEOF
  cat > "$PROBE_TMP/specs/architecture/decisions/ADR-099-test.md" <<'PROBEOF'
---
title: "Test ADR"
---
# ADR-099: Test

## Decision

Some decision.
PROBEOF
  local out
  out="$(run_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP/specs/architecture/decisions")"
  if echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 5: ## Changelog section ADR citation was incorrectly flagged."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 5: ## Changelog citation not flagged (exempt)."
}

# ── Probe 6: Chained double-§ form detected ───────────────────────────────────
probe_chained_double_section() {
  init_probe_tmp
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Background

This uses ADR-099 §Real Section §PhantomSub which is a chained form.
PROBEOF
  cat > "$PROBE_TMP/specs/architecture/decisions/ADR-099-test.md" <<'PROBEOF'
---
title: "Test ADR"
---
# ADR-099: Test

## Real Section

Content here.
PROBEOF
  local out
  out="$(run_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP/specs/architecture/decisions")"
  if ! echo "$out" | grep -qF 'CITATION_CHAINED'; then
    echo "[SELF-PROBE FAIL] Probe 6: chained double-§ form not detected as CITATION_CHAINED."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  # CHAINED takes precedence — no spurious CITATION_PASS should be emitted
  if echo "$out" | grep -qF 'CITATION_PASS'; then
    echo "[SELF-PROBE FAIL] Probe 6: chained form also emitted CITATION_PASS (should be suppressed)."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 6: chained double-§ detected as CITATION_CHAINED (PASS suppressed)."
}

# ── Probe 7: Valid single-§ still passes; not flagged as CHAINED ──────────────
probe_single_section_not_chained() {
  init_probe_tmp
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Background

This uses ADR-099 §Real Section which is a valid single citation.
PROBEOF
  cat > "$PROBE_TMP/specs/architecture/decisions/ADR-099-test.md" <<'PROBEOF'
---
title: "Test ADR"
---
# ADR-099: Test

## Real Section

Content here.
PROBEOF
  local out
  out="$(run_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP/specs/architecture/decisions")"
  if echo "$out" | grep -qF 'CITATION_CHAINED'; then
    echo "[SELF-PROBE FAIL] Probe 7: valid single-§ incorrectly flagged as CITATION_CHAINED."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if ! echo "$out" | grep -qF 'CITATION_PASS'; then
    echo "[SELF-PROBE FAIL] Probe 7: valid single-§ not detected as CITATION_PASS."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 7: valid single-§ detected as CITATION_PASS (not chained)."
}

# ── Main anchor check ─────────────────────────────────────────────────────────

check_anchor_citations() {
  local scan_dir="${1:-$SPECS_DIR}"

  local raw_output
  raw_output="$(run_anchor_scanner "$HOOKS_DIR" "$scan_dir" "$ADR_DIR")"

  local -i pass_count=0 fail_count=0 chain_count=0 ambig_count=0 notgt_count=0

  declare -A fail_by_file=()
  declare -A chain_by_file=()
  declare -A ambig_by_file=()

  while IFS=$'\t' read -r outcome adr_num section_text rel_file; do
    case "$outcome" in
      CITATION_PASS)
        pass_count=$(( pass_count + 1 ))
        ;;
      CITATION_FAIL)
        fail_count=$(( fail_count + 1 ))
        fail_by_file["$rel_file"]="${fail_by_file[$rel_file]:-}  PHANTOM: ADR-${adr_num} §${section_text}\n"
        ;;
      CITATION_CHAINED)
        chain_count=$(( chain_count + 1 ))
        chain_by_file["$rel_file"]="${chain_by_file[$rel_file]:-}  CHAINED: ADR-${adr_num} §${section_text}\n"
        ;;
      CITATION_AMBIG)
        ambig_count=$(( ambig_count + 1 ))
        local label
        if [ "$adr_num" = "N/A" ]; then
          label="BARE-§"
        else
          label="AMBIGUOUS"
        fi
        ambig_by_file["$rel_file"]="${ambig_by_file[$rel_file]:-}  ${label}: §${section_text}\n"
        ;;
      CITATION_NOTGT)
        notgt_count=$(( notgt_count + 1 ))
        ;;
    esac
  done <<< "$raw_output"

  local total_problems=$(( fail_count + chain_count + ambig_count + notgt_count ))
  local total_scanned=$(( pass_count + fail_count + chain_count + ambig_count + notgt_count ))

  echo "  Citations scanned:     ${total_scanned}"
  echo "  PASS (valid):          ${pass_count}"
  echo "  FAIL (phantom):        ${fail_count}"
  echo "  FAIL (chained §§):     ${chain_count}"
  echo "  FAIL (ambiguous/bare): ${ambig_count}"
  echo "  FAIL (target missing): ${notgt_count}"

  if [ "${#fail_by_file[@]}" -gt 0 ]; then
    echo ""
    echo "  Phantom anchors (no matching heading in target ADR):"
    for fpath in "${!fail_by_file[@]}"; do
      echo "    ${fpath}:"
      printf '%b' "${fail_by_file[$fpath]}"
    done
  fi

  if [ "${#chain_by_file[@]}" -gt 0 ]; then
    echo ""
    echo "  Chained double-§ forms (ADR-022 §Decision 5 prohibits §X §Y):"
    for fpath in "${!chain_by_file[@]}"; do
      echo "    ${fpath}:"
      printf '%b' "${chain_by_file[$fpath]}"
    done
    echo ""
    echo "  Fix guide: split ADR-NNN §X §Y → ADR-NNN §X (remove trailing §Y sub-anchor)."
  fi

  if [ "${#ambig_by_file[@]}" -gt 0 ]; then
    echo ""
    echo "  Ambiguous/bare-§ citations:"
    for fpath in "${!ambig_by_file[@]}"; do
      echo "    ${fpath}:"
      printf '%b' "${ambig_by_file[$fpath]}"
    done
    echo ""
    echo "  Fix guide: add ADR-NNN prefix, or if same-doc ref verify heading exists."
  fi

  if [ "${total_problems}" -gt 0 ]; then
    emit FAIL "B1 (ADR-022): §Named-Section citations — ${fail_count} phantom, ${chain_count} chained, ${ambig_count} ambiguous/bare, ${notgt_count} target-missing (${total_scanned} scanned)"
    echo "  Routing: phantom → replace §Name with real heading; chained → remove §Y sub-anchor;"
    echo "           bare-§ → add ADR-NNN prefix; target-missing → verify ADR file exists."
  else
    emit PASS "B1 (ADR-022): all ${total_scanned} §Named-Section citations resolve to real headings."
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-adr-anchor-citations: ADR-022 §Named-Section citation existence gate"
echo "  SPECS_DIR: $SPECS_DIR"
echo "  ADR_DIR:   $ADR_DIR"
echo "  Authority: ADR-022 §Decision 3 (prefix match, unique heading)"
echo "  Status:    BLOCKING — migration complete (burst-290)"
echo ""

echo "[SELF-PROBE] Verifying phantom/valid/ambiguous/chained detection and exemptions..."
probe_phantom_anchor
probe_valid_anchor
probe_ambiguous_anchor
probe_backtick_exempt
probe_changelog_exempt
probe_chained_double_section
probe_single_section_not_chained
echo "[SELF-PROBE] All 7 probes passed — checks are not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "BLOCKING rules (exit 1 on any finding)"
echo "════════════════════════════════════════════"
echo ""
echo "── B1 (ADR-022 Decision 3+5): §Named-Section citation existence + chained forms ──"
check_anchor_citations "$SPECS_DIR"

echo ""
echo "════════════════════════════════════════════"

echo ""
echo "verify-adr-anchor-citations: PASS=$PASS FAIL=$FAIL"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
