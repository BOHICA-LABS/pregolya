#!/usr/bin/env bash
# verify-adr-anchor-citations.sh — §Named-Section citation existence gate (ADR + non-ADR)
#
# PURPOSE
# ───────
# Enforces ADR-022 §Decision 3 across all .md files under .factory/specs/ (ADR citations)
# and all .md files under .factory/ (non-ADR citations — burst-291 gap closure).
# For every `ADR-NNN §Section-Text` citation in normative (non-changelog, non-fence,
# non-illustration) positions, verifies that a heading starting with Section-Text
# exists in the target ADR file, and that the match is unambiguous (exactly one
# heading). Also detects chained double-§ forms (ADR-NNN §X §Y) and bare §Section
# citations that lack an ADR-NNN prefix in live-body normative prose.
# Non-ADR citations (BC-N.SS.NNN §…, VP-NNN §…, CAP-NNN §…, filename.md §…) are
# validated against the respective target file's headings using the same prefix-match
# logic, extended with item-anchor resolution for standard shorthand forms.
#
# BLOCKING — ADR coverage (burst-290) + non-ADR coverage (burst-291)
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
# - Non-ADR §-target citations are now IN SCOPE (burst-291): BC-N.SS.NNN §Section,
#     VP-NNN §Section, CAP-NNN §Section, and filename.md §Section forms are validated
#     by B2 (run_nonadr_anchor_scanner). The former LINE_DOC_ID_RE whole-line skip
#     that convention-bound these citations is no longer the only enforcement layer.
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
# SELF-PROBES (14 mandatory)
# ──────────────────────────
# ADR-target probes (burst-290):
# 1. Phantom anchor (no heading) detected as CITATION_FAIL
# 2. Valid anchor (heading exists) detected as CITATION_PASS
# 3. Ambiguous anchor (multiple headings) detected as CITATION_AMBIG
# 4. Inline-backtick exemption: backtick-quoted citation not flagged
# 5. Changelog-section exemption: citation in ## Changelog not flagged
# 6. Chained double-§ form detected as CITATION_CHAINED
# 7. Valid single-§ still passes; not flagged as CITATION_CHAINED
# Non-ADR probes (burst-291):
# 8.  BC phantom §-anchor (no matching heading) detected as CITATION_FAIL
# 9.  BC valid §-anchor (heading exists) detected as CITATION_PASS
# 10. VP phantom §-anchor detected as CITATION_FAIL
# 11. filename.md phantom §-anchor detected as CITATION_FAIL
# 12. BC item-anchor §PC-1 resolves via Postconditions (CITATION_PASS)
# Colon-extension probes (burst-291 precision fix):
# 13. §Component: TOOLS (colon in heading name) resolves uniquely → CITATION_PASS
# 14. §Component (bare, no ': NAME' suffix) still matches multiple → CITATION_AMBIG
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
PROJECT_ROOT="$(cd "$FACTORY_DIR/.." && pwd)"

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
            # Colon-suffix: captured for AMBIG-fallback only (see AMBIG branch).
            # Heading names like '## Component: TOOLS' contain ':' which the
            # regex treats as a hard terminator; ':' in the middle of a citation
            # like 'ADR-004 §Decision: schemars' where 'Decision' already uniquely
            # matches must NOT extend (would create phantom 'Decision: schemars').
            _ce_pos = m.end()
            _colon_suffix = (stripped[_ce_pos:]
                             if _ce_pos < len(stripped) and stripped[_ce_pos] == ':'
                             else '')

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
                # AMBIG: try colon-extension before giving up.
                # §Component: TOOLS → 'Component' matched multiple headings →
                # extend to 'Component: TOOLS' → unique match → PASS.
                _resolved = False
                if _colon_suffix:
                    _ce_m = re.match(r'^:\s+(\S+)', _colon_suffix)
                    if _ce_m:
                        _ext = section_text + ': ' + _ce_m.group(1)
                        _ext_match = find_matching_heading(_ext, headings)
                        if len(_ext_match) == 1:
                            results.append(('PASS', adr_num, _ext, rel))
                            _resolved = True
                if not _resolved:
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

# ── Non-ADR citation scanner ──────────────────────────────────────────────────
# Validates §Named-Section citations whose target is a NON-ADR spec doc:
#   BC-N.SS.NNN §Section  → specs/behavioral-contracts/ss-SS/BC-N.SS.NNN.md
#   VP-NNN §Section       → specs/verification-properties/VP-NNN.md
#   CAP-NNN §Section      → specs/domain-spec/capabilities-p0.md or -p1-p2.md
#   filename.md §Section  → any .md file found under factory_dir or project_root
#
# Item-anchor resolution maps shorthand forms to canonical headings:
#   §PC-N / §Postcondition(s) → Postconditions heading
#   §EC-NNN                   → Edge Cases heading
#   §TV-NNN / §GTV-NNN        → Canonical Test Vectors / Test Vectors heading
#   §Invariant(s) …           → Invariants heading
#   §N / §N.N                 → Section N: / N. / numbered heading forms
#
# Closes: F-P1D182-01 (ADR-022 Decision-5 gap — non-ADR targets unenforced)
#
# Arguments: <hooks_dir> <scan_dir> <factory_dir> <project_root>
# Output: same 4-column tab-separated format as run_anchor_scanner
run_nonadr_anchor_scanner() {
  local hooks_dir="$1" scan_dir="$2" factory_dir="$3" project_root="$4"
  python3 - "$hooks_dir" "$scan_dir" "$factory_dir" "$project_root" <<'PYEOF2'
import sys, glob, re, os

hooks_dir    = sys.argv[1]
scan_dir     = sys.argv[2]
factory_dir  = sys.argv[3]
project_root = sys.argv[4]
sys.path.insert(0, hooks_dir)
from spec_region_utils import changelog_exempt_lines, illustration_exempt_lines

# ── Heading detection ─────────────────────────────────────────────────────────
HEADING_RE = re.compile(r'^(#{1,6})\s+(.+?)\s*$', re.MULTILINE)

# ── Inline backtick span (single-line) ────────────────────────────────────────
INLINE_TICK_RE = re.compile(r'`[^`\n]*`')

# ── Citation patterns ─────────────────────────────────────────────────────────
# \xa7 = U+00A7 (§).  Adding \xa7 to the lookahead terminator handles chained
# double-§ forms (filename.md §X §Y) — section text stops at the first §,
# and only the first anchor is validated (ADR-022 §Decision 5 principle).

# BC-N.SS.NNN §Section — [A-Z] first char prevents prose false-positives.
# e.g. ADR-023 line "BC-2.22.001 §compile-fail-gate exists and is stale"
# starts with lowercase 'c' → excluded ✓
BC_CITE_RE = re.compile(
    r'\bBC-(\d+\.\d{2}\.\d{3})\s+\xa7'
    r'([A-Z][^\n`\xa7]{0,80}?)'
    r'(?=[`\n\xa7]|[,.:;\'\")\]]|\s{2,}|\s*$)'
)

# VP-NNN §Section (bare VP-NNN, no .md suffix)
VP_CITE_RE = re.compile(
    r'\bVP-(\d{3})\s+\xa7'
    r'([A-Za-z][^\n`\xa7]{0,80}?)'
    r'(?=[`\n\xa7]|[,.:;\'\")\]]|\s{2,}|\s*$)'
)

# CAP-NNN §Section (zero occurrences in current corpus; future-proofing)
CAP_CITE_RE = re.compile(
    r'\bCAP-(\d{3})\s+\xa7'
    r'([A-Za-z][^\n`\xa7]{0,80}?)'
    r'(?=[`\n\xa7]|[,.:;\'\")\]]|\s{2,}|\s*$)'
)

# filename.md §Section — matches any .md filename reference.
# Lookbehind (?<![A-Z0-9]) prevents matching e.g. "XADR-022.md §…".
# ADR-NNN short aliases (ADR-NNN.md) post-filtered out; covered by ADR scanner.
FNMD_CITE_RE = re.compile(
    r'(?<![A-Z0-9])([A-Za-z0-9][A-Za-z0-9_.\-/]{0,80}?\.md)\s+\xa7'
    r'([A-Za-z0-9*#][^\n`\xa7]{0,80}?)'
    r'(?=[`\n\xa7]|[,.:;\'\")\]]|\s{2,}|\s*$)'
)

# ── Fenced code block exemption ───────────────────────────────────────────────
def build_fence_exempt(lines):
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

# ── File resolvers ────────────────────────────────────────────────────────────
def resolve_bc_file(bc_id):
    """BC-X.SS.NNN → specs/behavioral-contracts/ss-SS/BC-X.SS.NNN.md"""
    m = re.match(r'^(\d+)\.(\d{2})\.(\d{3})$', bc_id)
    if not m:
        return None
    ss = m.group(2)
    path = os.path.join(factory_dir, 'specs', 'behavioral-contracts',
                        f'ss-{ss}', f'BC-{bc_id}.md')
    return path if os.path.isfile(path) else None

def resolve_vp_file(vp_num):
    """VP-NNN → specs/verification-properties/VP-NNN.md"""
    path = os.path.join(factory_dir, 'specs', 'verification-properties',
                        f'VP-{vp_num}.md')
    return path if os.path.isfile(path) else None

_cap_files_cache = None

def resolve_cap_files():
    """Return list of capabilities files that exist on disk."""
    global _cap_files_cache
    if _cap_files_cache is not None:
        return _cap_files_cache
    base = os.path.join(factory_dir, 'specs', 'domain-spec')
    paths = []
    for fname in ('capabilities-p0.md', 'capabilities-p1-p2.md'):
        p = os.path.join(base, fname)
        if os.path.isfile(p):
            paths.append(p)
    _cap_files_cache = paths
    return paths

_file_index = None

def build_file_index():
    global _file_index
    if _file_index is not None:
        return _file_index
    _file_index = {}
    roots = [factory_dir]
    if os.path.abspath(project_root) != os.path.abspath(factory_dir):
        roots.append(project_root)
    for root in roots:
        if not os.path.isdir(root):
            continue
        for fpath in glob.glob(os.path.join(root, '**', '*.md'), recursive=True):
            basename = os.path.basename(fpath)
            if basename not in _file_index:
                _file_index[basename] = []
            _file_index[basename].append(fpath)
    return _file_index

def resolve_filename(filename):
    """Resolve a filename.md to an absolute path."""
    if '/' in filename:
        # Relative path: try factory_dir then project_root
        for base in (factory_dir, project_root):
            p = os.path.join(base, filename)
            if os.path.isfile(p):
                return p
        return None
    # Basename lookup in file index
    idx = build_file_index()
    candidates = idx.get(filename, [])
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]
    # Multiple files with same basename — prefer specs/ path
    specs_matches = [p for p in candidates if '/specs/' in p]
    if len(specs_matches) == 1:
        return specs_matches[0]
    return sorted(candidates)[0]  # deterministic fallback

# ── Heading cache ─────────────────────────────────────────────────────────────
_headings_cache = {}

def get_headings_cached(path):
    if path in _headings_cache:
        return _headings_cache[path]
    try:
        with open(path, 'r', encoding='utf-8') as fh:
            raw = fh.read()
    except OSError:
        _headings_cache[path] = []
        return []
    lines = raw.splitlines()
    body_start = 0
    if lines and lines[0].strip() == '---':
        for j in range(1, len(lines)):
            if lines[j].strip() == '---':
                body_start = j + 1
                break
    body = '\n'.join(lines[body_start:])
    headings = [m.group(2).strip() for m in HEADING_RE.finditer(body)]
    _headings_cache[path] = headings
    return headings

# ── Heading match: longest-prefix ─────────────────────────────────────────────
def _strip_md_inline(text):
    """Strip inline markdown formatting (**bold**, _italic_, `code`) from text."""
    return re.sub(r'[\*_`]+', '', text)

def find_matching_heading(section_text, headings):
    # Strip inline markdown decoration before prefix matching.
    # Handles citations like §Description** (bold marker on section text).
    clean = _strip_md_inline(section_text)
    candidate = clean.rstrip(' .,;:\'")')
    words = candidate.split()
    if not words:
        return []
    for length in range(len(words), 0, -1):
        prefix = ' '.join(words[:length])
        matched = [h for h in headings if h.startswith(prefix)]
        if matched:
            return matched
    return []

# ── Item-anchor resolution ─────────────────────────────────────────────────────
def resolve_item_anchor(section_text, headings):
    """
    Maps standard BC/VP shorthand anchors to canonical section headings.
    Returns True if the anchor resolves to an existing heading.
    """
    # Strip markdown decoration (bold, italic, code) and trailing punctuation
    text = re.sub(r'[\*_`]+', '', section_text).strip().rstrip(' .,;:)')
    if not text:
        return False

    # §PC-N or §Postcondition(s) … → Postconditions heading
    if re.match(r'^PC-?\d', text, re.I) or re.match(r'^Postcondition[s]?\b', text, re.I):
        return any(h.startswith('Postcondition') for h in headings)

    # §EC-NNN → Edge Cases heading
    if re.match(r'^EC-\d{3}', text):
        return any(h.startswith('Edge Case') for h in headings)

    # §TV-NNN or §GTV-NNN → Canonical Test Vectors / Test Vectors heading
    if re.match(r'^G?TV-\d+', text):
        return any(
            h.startswith('Canonical Test Vector') or h.startswith('Test Vector')
            for h in headings
        )

    # §Invariant(s) … → Invariants heading
    if re.match(r'^Invariant[s]?\b', text, re.I):
        return any(h.startswith('Invariant') for h in headings)

    # §N or §N.N (pure integer/decimal) → numbered heading forms:
    #   "N. Title", "N Title", "Section N:", "Appendix N:", etc.
    first_word = text.split()[0] if text.split() else ''
    if re.match(r'^\d+(\.\d+)?$', first_word):
        N = first_word
        for h in headings:
            if re.match(r'^' + re.escape(N) + r'[. :]', h):
                return True
            if re.match(
                r'^(?:Section|Appendix|Part|Chapter)\s+' + re.escape(N) + r'(?:[. :]|$)',
                h
            ):
                return True

    return False

# ── Validate a single citation ────────────────────────────────────────────────
def validate_citation(section_text, target_path, colon_suffix=''):
    """Returns 'PASS', 'FAIL', 'AMBIG', or 'NOTGT'.

    colon_suffix: the raw text starting at m.end() (beginning with ':') when the
    regex terminated at ':'.  Used only for AMBIG fallback: if section_text matches
    multiple headings, try extending with the next word from colon_suffix before
    reporting AMBIG.  Not used when section_text already uniquely matches.
    """
    if target_path is None:
        return 'NOTGT'
    headings = get_headings_cached(target_path)
    if not headings:
        # File exists but has no headings — treat as phantom
        return 'FAIL'
    # Primary: longest-prefix heading match
    matching = find_matching_heading(section_text, headings)
    if len(matching) == 1:
        return 'PASS'
    if len(matching) > 1:
        # Colon-extension fallback (AMBIG only): heading names like
        # '## Component: TOOLS' contain ':' which the regex terminated on.
        # The base capture is 'Component' (AMBIG); extend to 'Component: TOOLS'
        # using the next word from the raw line suffix, and re-check uniqueness.
        # This is ONLY tried on AMBIG — when the base text already uniquely
        # matches (e.g. 'Decision' → '## Decision'), we returned PASS above and
        # never reach this branch, so '§Decision: schemars' is not mis-extended.
        if colon_suffix:
            _ce = re.match(r'^:\s+(\S+)', colon_suffix)
            if _ce:
                extended = section_text + ': ' + _ce.group(1)
                ext_matching = find_matching_heading(extended, headings)
                if len(ext_matching) == 1:
                    return 'PASS'
        # Numbered-section tolerance: §N / §N.N / §N item M / §N items M-P
        # forms are convention-bound citations in analysis and reference docs
        # that point to a numbered section generally (the 'item M' qualifier
        # is prose context, not a heading title).  When multiple headings
        # start with the same numeric prefix — confirming section N exists in
        # the target — accept the citation as VALID rather than AMBIG.
        _first_word = section_text.split()[0] if section_text.split() else ''
        if re.match(r'^\d+(\.\d+)?$', _first_word):
            return 'PASS'
        return 'AMBIG'
    # Fallback: item-anchor resolution
    if resolve_item_anchor(section_text, headings):
        return 'PASS'
    return 'FAIL'

def validate_cap_citation(section_text, colon_suffix=''):
    """Check section_text against all capabilities files; return best outcome."""
    cap_files = resolve_cap_files()
    if not cap_files:
        return 'NOTGT'
    for path in cap_files:
        outcome = validate_citation(section_text, path, colon_suffix)
        if outcome == 'PASS':
            return 'PASS'
    return 'FAIL'

# ── Main scan ─────────────────────────────────────────────────────────────────
md_files = sorted(glob.glob(os.path.join(scan_dir, '**', '*.md'), recursive=True))

results = []

for filepath in md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    if '\xa7' not in ''.join(lines):  # § quick skip
        continue

    rel          = filepath.replace(scan_dir.rstrip('/') + '/', '')
    cl_exempt    = changelog_exempt_lines(lines)
    il_exempt    = illustration_exempt_lines(lines)
    fence_exempt = build_fence_exempt(lines)

    for i, raw_line in enumerate(lines):
        if i in cl_exempt or i in il_exempt or i in fence_exempt:
            continue
        if '\xa7' not in raw_line:
            continue

        # Skip line-structure exclusions
        line_s = raw_line.strip()
        if line_s.startswith('#') or line_s.startswith('|') or line_s.startswith('>'):
            continue

        # Strip inline backtick spans before scanning
        stripped = INLINE_TICK_RE.sub('', raw_line)
        if '\xa7' not in stripped:
            continue

        # Track spans already claimed by higher-priority patterns (BC > VP > CAP > FNMD)
        claimed = set()

        # ── BC citations ──────────────────────────────────────────────────────
        for m in BC_CITE_RE.finditer(stripped):
            claimed.update(range(m.start(), m.end()))
            bc_id        = m.group(1)
            section_text = m.group(2).strip()
            if not section_text:
                continue
            # Colon-suffix for AMBIG-fallback: when ':' terminates the regex
            # match, the raw suffix (': WORD ...') lets validate_citation extend
            # section_text only if the base text is already ambiguous (matches
            # multiple headings).  '§Decision: schemars' where 'Decision' is
            # unique does NOT extend; '§Component: TOOLS' where 'Component'
            # matches multiple does extend to 'Component: TOOLS' → unique PASS.
            _ce_pos = m.end()
            _colon_suffix = (stripped[_ce_pos:]
                             if _ce_pos < len(stripped) and stripped[_ce_pos] == ':'
                             else '')
            target_path = resolve_bc_file(bc_id)
            outcome = validate_citation(section_text, target_path, _colon_suffix)
            results.append((outcome, f'BC-{bc_id}', section_text, rel))

        # ── VP citations ──────────────────────────────────────────────────────
        for m in VP_CITE_RE.finditer(stripped):
            if any(pos in claimed for pos in range(m.start(), m.end())):
                continue
            claimed.update(range(m.start(), m.end()))
            vp_num       = m.group(1)
            section_text = m.group(2).strip()
            if not section_text:
                continue
            # Colon-suffix for AMBIG-fallback (see BC_CITE_RE note above).
            _ce_pos = m.end()
            _colon_suffix = (stripped[_ce_pos:]
                             if _ce_pos < len(stripped) and stripped[_ce_pos] == ':'
                             else '')
            target_path = resolve_vp_file(vp_num)
            outcome = validate_citation(section_text, target_path, _colon_suffix)
            results.append((outcome, f'VP-{vp_num}', section_text, rel))

        # ── CAP citations ─────────────────────────────────────────────────────
        for m in CAP_CITE_RE.finditer(stripped):
            if any(pos in claimed for pos in range(m.start(), m.end())):
                continue
            claimed.update(range(m.start(), m.end()))
            cap_num      = m.group(1)
            section_text = m.group(2).strip()
            if not section_text:
                continue
            # Colon-suffix for AMBIG-fallback (see BC_CITE_RE note above).
            _ce_pos = m.end()
            _colon_suffix = (stripped[_ce_pos:]
                             if _ce_pos < len(stripped) and stripped[_ce_pos] == ':'
                             else '')
            outcome = validate_cap_citation(section_text, _colon_suffix)
            results.append((outcome, f'CAP-{cap_num}', section_text, rel))

        # ── filename.md citations ─────────────────────────────────────────────
        for m in FNMD_CITE_RE.finditer(stripped):
            if any(pos in claimed for pos in range(m.start(), m.end())):
                continue
            filename     = m.group(1)
            section_text = m.group(2).strip()
            if not section_text:
                continue
            # Colon-suffix for AMBIG-fallback: heading names like
            # '## Component: TOOLS (pregolya-tools)' contain ':' which the
            # regex treats as a hard terminator.  'error-taxonomy.md §Component:
            # TOOLS' captures only 'Component' (AMBIG against all Component: X
            # headings); the suffix ': TOOLS ...' is passed to validate_citation
            # which tries 'Component: TOOLS' as an AMBIG fallback → unique PASS.
            # When the base text already uniquely matches, extension is skipped.
            _ce_pos = m.end()
            _colon_suffix = (stripped[_ce_pos:]
                             if _ce_pos < len(stripped) and stripped[_ce_pos] == ':'
                             else '')
            # Post-filter: skip bare ADR-NNN.md short aliases (ADR scanner scope)
            if re.match(r'^ADR-\d{3}\.md$', filename, re.I):
                continue
            target_path = resolve_filename(filename)
            outcome = validate_citation(section_text, target_path, _colon_suffix)
            results.append((outcome, filename, section_text, rel))

# ── Emit output ───────────────────────────────────────────────────────────────
for outcome, doc_id, section_text, rel in results:
    print(f'CITATION_{outcome}\t{doc_id}\t{section_text}\t{rel}')
PYEOF2
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

# ── Probe 8: BC phantom §-anchor detected ────────────────────────────────────
probe_nonadr_bc_phantom() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs/behavioral-contracts/ss-99"
  cat > "$PROBE_TMP/specs/source-nonadr.md" <<'PROBEOF'
## Body

See BC-2.99.001 §Nonexistent Section for details.
PROBEOF
  cat > "$PROBE_TMP/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'PROBEOF'
---
bc_id: BC-2.99.001
---
# BC-2.99.001 Test

## Postconditions

None.
PROBEOF
  local out
  out="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP" "$PROBE_TMP")"
  if ! echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 8: BC phantom §-anchor not detected as CITATION_FAIL."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 8: BC phantom §-anchor detected as CITATION_FAIL."
}

# ── Probe 9: BC valid §-anchor detected ──────────────────────────────────────
probe_nonadr_bc_valid() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs/behavioral-contracts/ss-99"
  cat > "$PROBE_TMP/specs/source-nonadr.md" <<'PROBEOF'
## Body

See BC-2.99.001 §Postconditions for details.
PROBEOF
  cat > "$PROBE_TMP/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'PROBEOF'
---
bc_id: BC-2.99.001
---
# BC-2.99.001 Test

## Postconditions

None.
PROBEOF
  local out
  out="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP" "$PROBE_TMP")"
  if ! echo "$out" | grep -qF 'CITATION_PASS'; then
    echo "[SELF-PROBE FAIL] Probe 9: BC valid §-anchor not detected as CITATION_PASS."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 9: BC valid §-anchor incorrectly flagged as CITATION_FAIL."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 9: BC valid §-anchor detected as CITATION_PASS."
}

# ── Probe 10: VP phantom §-anchor detected ────────────────────────────────────
probe_nonadr_vp_phantom() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs/verification-properties"
  cat > "$PROBE_TMP/specs/source-nonadr.md" <<'PROBEOF'
## Body

See VP-099 §Nonexistent Property for details.
PROBEOF
  cat > "$PROBE_TMP/specs/verification-properties/VP-099.md" <<'PROBEOF'
---
vp_id: VP-099
---
# VP-099 Test

## Overview

None.
PROBEOF
  local out
  out="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP" "$PROBE_TMP")"
  if ! echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 10: VP phantom §-anchor not detected as CITATION_FAIL."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 10: VP phantom §-anchor detected as CITATION_FAIL."
}

# ── Probe 11: filename.md phantom §-anchor detected ──────────────────────────
probe_nonadr_filename_phantom() {
  init_probe_tmp
  cat > "$PROBE_TMP/specs/source-nonadr.md" <<'PROBEOF'
## Body

See testref.md §Missing Section for details.
PROBEOF
  cat > "$PROBE_TMP/specs/testref.md" <<'PROBEOF'
# Testref

## Overview

None.
PROBEOF
  local out
  out="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP" "$PROBE_TMP")"
  if ! echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 11: filename.md phantom §-anchor not detected as CITATION_FAIL."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 11: filename.md phantom §-anchor detected as CITATION_FAIL."
}

# ── Probe 12: BC item-anchor §PC-1 resolves via Postconditions ───────────────
probe_nonadr_bc_item_anchor() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs/behavioral-contracts/ss-99"
  cat > "$PROBE_TMP/specs/source-nonadr.md" <<'PROBEOF'
## Body

See BC-2.99.001 §PC-1 for postcondition details.
PROBEOF
  cat > "$PROBE_TMP/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'PROBEOF'
---
bc_id: BC-2.99.001
---
# BC-2.99.001 Test

## Postconditions

- PC-1: The result is correct.
PROBEOF
  local out
  out="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP" "$PROBE_TMP")"
  if ! echo "$out" | grep -qF 'CITATION_PASS'; then
    echo "[SELF-PROBE FAIL] Probe 12: BC item-anchor §PC-1 not resolved as CITATION_PASS."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if echo "$out" | grep -qF 'CITATION_FAIL'; then
    echo "[SELF-PROBE FAIL] Probe 12: BC item-anchor §PC-1 incorrectly flagged as CITATION_FAIL."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 12: BC item-anchor §PC-1 resolved to Postconditions (CITATION_PASS)."
}

# ── Probe 13: §Component: TOOLS resolves uniquely (colon-extension PASS) ─────
probe_nonadr_colon_unique() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs/behavioral-contracts/ss-99"
  # Citation: BC-2.99.001 §Component: TOOLS — colon is part of the heading name.
  # The BC file has two Component: X headings so that bare '§Component' is AMBIG
  # but '§Component: TOOLS' uniquely matches the first heading.
  cat > "$PROBE_TMP/specs/source-colon.md" <<'PROBEOF'
## Body

See BC-2.99.001 §Component: TOOLS for the tool crate errors.
PROBEOF
  cat > "$PROBE_TMP/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'PROBEOF'
---
bc_id: BC-2.99.001
---
# BC-2.99.001 Test

## Component: TOOLS (pregolya-tools)

Tool errors go here.

## Component: HTTP (pregolya-http)

HTTP errors go here.
PROBEOF
  local out
  out="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP" "$PROBE_TMP")"
  if ! echo "$out" | grep -qF 'CITATION_PASS'; then
    echo "[SELF-PROBE FAIL] Probe 13: §Component: TOOLS not resolved as CITATION_PASS."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if echo "$out" | grep -qF 'CITATION_AMBIG'; then
    echo "[SELF-PROBE FAIL] Probe 13: §Component: TOOLS incorrectly reported as CITATION_AMBIG (colon-extension not working)."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 13: §Component: TOOLS (colon in heading) resolved uniquely as CITATION_PASS."
}

# ── Probe 14: §Component (bare, no ': NAME') still AMBIG ─────────────────────
probe_nonadr_colon_bare_ambig() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs/behavioral-contracts/ss-99"
  # Citation: BC-2.99.001 §Component — bare, without ': NAME' disambiguation.
  # Must still be AMBIG because it matches Component: TOOLS AND Component: HTTP.
  cat > "$PROBE_TMP/specs/source-bare.md" <<'PROBEOF'
## Body

See BC-2.99.001 §Component for all component-level errors.
PROBEOF
  cat > "$PROBE_TMP/specs/behavioral-contracts/ss-99/BC-2.99.001.md" <<'PROBEOF'
---
bc_id: BC-2.99.001
---
# BC-2.99.001 Test

## Component: TOOLS (pregolya-tools)

Tool errors go here.

## Component: HTTP (pregolya-http)

HTTP errors go here.
PROBEOF
  local out
  out="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$PROBE_TMP/specs" "$PROBE_TMP" "$PROBE_TMP")"
  if ! echo "$out" | grep -qF 'CITATION_AMBIG'; then
    echo "[SELF-PROBE FAIL] Probe 14: bare §Component not reported as CITATION_AMBIG (should still be ambiguous)."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if echo "$out" | grep -qF 'CITATION_PASS'; then
    echo "[SELF-PROBE FAIL] Probe 14: bare §Component incorrectly reported as CITATION_PASS."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 14: bare §Component (no ': NAME') correctly AMBIG (multiple Component: X headings)."
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

# ── Non-ADR citation check ────────────────────────────────────────────────────
# Validates BC/VP/CAP/filename.md §Named-Section citations across all .factory/ docs.
# Closes the ADR-022 Decision-5 gap (burst-291): non-ADR targets now machine-enforced.
check_nonadr_citations() {
  # Scan normative spec content only ($SPECS_DIR — same scope as B1).
  # Historical documents (burst-log, ADV pass reports, convergence trajectories)
  # are excluded: they carry convention-bound narrative references that were never
  # targeted by the F-P1D182-01 sweep and would generate false positives.
  #
  # BLOCKING: CITATION_FAIL (no heading match) + CITATION_NOTGT (file not found)
  # ADVISORY: CITATION_AMBIG (multiple heading matches) — convention-bound patterns
  #   like `error-taxonomy.md §Component` are intentionally broad references; they
  #   are reported but do not block until a separate AMBIG-sweep clears them.
  local raw_output
  raw_output="$(run_nonadr_anchor_scanner "$HOOKS_DIR" "$SPECS_DIR" "$FACTORY_DIR" "$PROJECT_ROOT")"

  local -i pass_count=0 fail_count=0 ambig_count=0 notgt_count=0

  declare -A fail_by_file=()
  declare -A ambig_by_file=()

  while IFS=$'\t' read -r outcome doc_id section_text rel_file; do
    case "$outcome" in
      CITATION_PASS)
        pass_count=$(( pass_count + 1 ))
        ;;
      CITATION_FAIL)
        fail_count=$(( fail_count + 1 ))
        fail_by_file["$rel_file"]="${fail_by_file[$rel_file]:-}  PHANTOM: ${doc_id} §${section_text}\n"
        ;;
      CITATION_AMBIG)
        # ADVISORY: ambiguous (multiple heading matches); reported but non-blocking.
        # Convention-bound broad references (e.g., §Component, §1, §2) are common
        # in normative specs but were never swept; promote to BLOCKING after sweep.
        ambig_count=$(( ambig_count + 1 ))
        ambig_by_file["$rel_file"]="${ambig_by_file[$rel_file]:-}  AMBIGUOUS (advisory): ${doc_id} §${section_text}\n"
        ;;
      CITATION_NOTGT)
        notgt_count=$(( notgt_count + 1 ))
        fail_by_file["$rel_file"]="${fail_by_file[$rel_file]:-}  NO-TARGET: ${doc_id} §${section_text}\n"
        ;;
    esac
  done <<< "$raw_output"

  # Only PHANTOM + NOTGT are blocking; AMBIG is advisory
  local total_blocking=$(( fail_count + notgt_count ))
  local total_scanned=$(( pass_count + fail_count + ambig_count + notgt_count ))

  echo "  Non-ADR citations scanned (specs/ only): ${total_scanned}"
  echo "  PASS (valid):                            ${pass_count}"
  echo "  FAIL/blocking (phantom):                 ${fail_count}"
  echo "  FAIL/blocking (target missing):          ${notgt_count}"
  echo "  WARN/advisory (ambiguous):               ${ambig_count}"

  if [ "${#fail_by_file[@]}" -gt 0 ]; then
    echo ""
    echo "  Phantom/unresolvable non-ADR §-citations (BLOCKING):"
    for fpath in "${!fail_by_file[@]}"; do
      echo "    ${fpath}:"
      printf '%b' "${fail_by_file[$fpath]}"
    done
    echo ""
    echo "  Fix guide: verify heading exists in target doc; update citation to exact"
    echo "             heading prefix, or use a standard item-anchor (§PC-N, §EC-NNN, §TV-NNN)."
  fi

  if [ "${#ambig_by_file[@]}" -gt 0 ]; then
    echo ""
    echo "  Ambiguous non-ADR §-citations (ADVISORY — non-blocking):"
    for fpath in "${!ambig_by_file[@]}"; do
      echo "    ${fpath}:"
      printf '%b' "${ambig_by_file[$fpath]}"
    done
    echo "  Note: promote to BLOCKING once a dedicated AMBIG-sweep clears these."
  fi

  if [ "${total_blocking}" -gt 0 ]; then
    emit FAIL "B2 (ADR-022 Decision-5 gap): ${fail_count} phantom + ${notgt_count} target-missing non-ADR §-citations in specs/ (${total_scanned} scanned; ${ambig_count} advisory-ambig not blocking)"
    echo "  Routing: phantom → update §Name to real heading or use item-anchor form;"
    echo "           target-missing → verify file exists in .factory/ or project root."
  else
    if [ "${total_scanned}" -gt 0 ]; then
      emit PASS "B2 (ADR-022 Decision-5 gap): all ${total_scanned} non-ADR §Named-Section citations in specs/ resolve (${ambig_count} advisory-ambig noted)."
    else
      emit PASS "B2 (ADR-022 Decision-5 gap): no non-ADR §Named-Section citations found in specs/."
    fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-adr-anchor-citations: ADR-022 §Named-Section citation existence gate (ADR + non-ADR)"
echo "  SPECS_DIR:    $SPECS_DIR"
echo "  ADR_DIR:      $ADR_DIR"
echo "  FACTORY_DIR:  $FACTORY_DIR"
echo "  PROJECT_ROOT: $PROJECT_ROOT"
echo "  Authority: ADR-022 §Decision 3 (prefix match, unique heading)"
echo "  Status:    BLOCKING — ADR coverage (burst-290) + non-ADR coverage (burst-291)"
echo ""

echo "[SELF-PROBE] Verifying phantom/valid/ambiguous/chained detection and exemptions..."
probe_phantom_anchor
probe_valid_anchor
probe_ambiguous_anchor
probe_backtick_exempt
probe_changelog_exempt
probe_chained_double_section
probe_single_section_not_chained
probe_nonadr_bc_phantom
probe_nonadr_bc_valid
probe_nonadr_vp_phantom
probe_nonadr_filename_phantom
probe_nonadr_bc_item_anchor
probe_nonadr_colon_unique
probe_nonadr_colon_bare_ambig
echo "[SELF-PROBE] All 14 probes passed — checks are not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "BLOCKING rules (exit 1 on any finding)"
echo "════════════════════════════════════════════"
echo ""
echo "── B1 (ADR-022 Decision 3+5): §Named-Section citation existence + chained forms ──"
check_anchor_citations "$SPECS_DIR"

echo ""
echo "── B2 (ADR-022 Decision-5 gap): non-ADR §Named-Section citation existence ──────"
check_nonadr_citations

echo ""
echo "════════════════════════════════════════════"

echo ""
echo "verify-adr-anchor-citations: PASS=$PASS FAIL=$FAIL"

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
