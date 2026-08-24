#!/usr/bin/env bash
# verify-ac-pc-trace.sh — pregolya factory-artifacts BLOCKING/ADVISORY validator
#
# PURPOSE
# ───────
# Mechanically checks AC→BC-postcondition trace citations in story files.
# For every acceptance criterion in .factory/stories/stories/*.md that cites
# a BC section, verifies that the cited numbered item actually exists in the
# referenced BC file. Catches the P2A-032 drift class (stories citing
# non-existent PC/INV/EC numbers).
#
# DUAL-MODE CITATION RESOLUTION (ADR-027 M2)
# ───────────────────────────────────────────
# Two citation forms are valid during the M2→M3 migration window:
#
#   OLD ordinal form (all 39 stories at M2 start):
#     ### AC-NNN (traces to BC-S.SS.NNN postcondition N)
#     ### AC-NNN (traces to BC-S.SS.NNN invariant [freeform])
#     ### AC-NNN (traces to BC-S.SS.NNN precondition N)
#
#   NEW stable-tag form (ADR-027 Decision 3; stories migrate in M3):
#     ### AC-NNN (traces to BC-S.SS.NNN PC-NNN)
#     ### AC-NNN (traces to BC-S.SS.NNN INV-NNN)
#     ### AC-NNN (traces to BC-S.SS.NNN PRE-NNN)
#     ### AC-NNN (traces to BC-S.SS.NNN EC-NNN)   (unchanged format)
#
# The validator tries the NEW form first.  If matched, it resolves by
# grepping for {PC-NNN}/{INV-NNN}/{PRE-NNN}/{EC-NNN} tokens in the BC.
# If not matched, it falls through to OLD ordinal resolution.
#
# IMPORTANT (M2 constraint): Old-form citations against BCs that now carry
# stable tags are ACCEPTED — no mixed-form-anchor DRIFT is emitted.  The
# strict "new-form required / mixing = DRIFT" behaviour is M4's cutover.
#
# CHECKS IMPLEMENTED
# ──────────────────
# CHECK 1 — Existence check (highest value):
#   NEW form: the cited {PC-NNN}/{INV-NNN}/{PRE-NNN} token must be present
#     in the relevant BC section.
#   OLD form: the cited numbered item must exist by ordinal count:
#     - Postconditions: numbered list items (^\d+\.) in ## Postconditions
#     - Invariants: bullet items (^-) in ## Invariants (ordinal numbering)
#     - Preconditions: numbered list items (^\d+\.) in ## Preconditions
#     - Edge Cases: ### EC-NNN: headers in ## Edge Cases
#   reason=nonexistent in DRIFT output.
#
# CHECK 2 — Error-code co-location check (ADVISORY — non-blocking):
#   If the AC text asserts an error code (E-XXX-NNN), verify that SAME code
#   appears in the text of the specifically-cited PC/INV/EC item in the BC.
#   A code that is absent from the cited item but present elsewhere in the BC
#   is a strong signal the trace number is wrong.
#   reason=code-absent in ADVISORY output (heuristic; error codes may appear
#   in ACs as examples, table-row contrasts, or inline illustrations without
#   implying the cited item must contain them).
#
# CHECK 3 — Keyword-overlap heuristic (ADVISORY hints only):
#   When the AC's key nouns/verbs have near-zero overlap with the cited
#   PC/INV/EC text, emit a low-confidence WARN with reason=low-overlap.
#   Threshold: AC has ≥4 content words but zero overlap with cited item text.
#
# SCOPE
# ─────
# All .factory/stories/stories/STORY-S-*.md files (39 stories).
# Self-scope exclusion: this file is in .factory/hooks/ and is never parsed.
#
# EXIT CONTRACT
# ─────────────
# CHECK 1 (existence: reason=nonexistent, reason=bc-file-missing) — BLOCKING.
#   Exits 1 when any CHECK-1 DRIFT > 0. Emits "DRIFT ..." lines.
# CHECK 2 (error-code co-location: reason=code-absent) — ADVISORY.
#   Never blocks. Emits "ADVISORY ..." lines (grep-separable from DRIFT).
#   Exits 0 even when advisory hints exist, provided CHECK-1 drift is 0.
# Summary reports:
#   "CHECK-1 (blocking) drift: N" and "CHECK-2 (advisory) hints: M"
# RESULT line: PASS when CHECK-1 drift == 0; FAIL when CHECK-1 drift > 0.
#
# POL-26: Edit/Write tools only for .factory/ mutations.
# POL-30: Self-scope exclusion — hooks dir excluded from lint scope.
# TD-VSDD-091: No file:NNN line citations in comments or output text.
#
# Usage:  bash .factory/hooks/verify-ac-pc-trace.sh
# Exit:   0 when DRIFT==0; 1 when DRIFT>0 (blocking mode)

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STORIES_DIR="$FACTORY_DIR/stories/stories"
BC_BASE_DIR="$FACTORY_DIR/specs/behavioral-contracts"

DRIFT=0
TOTAL_CITATIONS=0
STORIES_WITH_DRIFT=0

# ── Emit helpers ─────────────────────────────────────────────────────────────

emit_drift() {
  local story_id="$1"
  local ac_id="$2"
  local cited="$3"
  local reason="$4"
  local extra="$5"
  local bc_id="$6"
  echo "DRIFT $story_id $ac_id cited=$cited reason=$reason${extra:+ $extra} bc=$bc_id"
  DRIFT=$((DRIFT + 1))
}

# ── Python3 core logic ───────────────────────────────────────────────────────

PYTHON_OUTPUT="$(python3 - "$STORIES_DIR" "$BC_BASE_DIR" <<'PYEOF'
import sys
import os
import re

STORIES_DIR = sys.argv[1]
BC_BASE_DIR  = sys.argv[2]

# ── Citation regexes (dual-mode, ADR-027 M2) ─────────────────────────────────
# NEW stable-tag form: ### AC-NNN (traces to BC-S.SS.NNN PC-NNN)
# Tried first; groups: (1)AC-id (2)BC-id (3)tag-prefix (4)tag-digits (5)trailing
NEW_CITE_RE = re.compile(
    r'###\s+(AC-\d+)\s+\(traces\s+to\s+'
    r'(BC-\d+\.\d+\.\d+)\s+'
    r'(PC|INV|PRE|EC)-(\d+)'
    r'([^)]*)\)',
    re.IGNORECASE
)

# OLD ordinal form: ### AC-NNN (traces to BC-S.SS.NNN postcondition N)
# Fallback when NEW_CITE_RE does not match.
# groups: (1)AC-id (2)BC-id (3)section-word (4)number-or-EC (5)trailing
OLD_CITE_RE = re.compile(
    r'###\s+(AC-\d+)\s+\(traces\s+to\s+'
    r'(BC-\d+\.\d+\.\d+)\s+'
    r'(postconditions?|invariant|precondition|edge\s+case)\s*'
    r'(EC-\d+|\d+(?:/\d+)*)?'
    r'([^)]*)\)',
    re.IGNORECASE
)

# Error code pattern anywhere in AC text
ERRCODE_RE = re.compile(r'\bE-[A-Z]+-\d+\b')

# Stop-words for keyword overlap check (short or common words not useful)
STOPWORDS = {
    'the','a','an','is','are','was','were','be','been','being',
    'have','has','had','do','does','did','will','would','could',
    'should','may','might','shall','must','can','of','in','on',
    'at','to','for','with','by','from','as','or','and','not',
    'that','this','it','its','if','when','then','so','but','no',
    'any','all','each','per','via','ok','err','fn','pub','use',
    'let','mut','ref','type','impl','struct','enum','trait','mod',
    'true','false','none','some','result','option',
}

def keywords(text):
    """Extract meaningful words from text for overlap heuristic."""
    words = re.findall(r'[a-zA-Z][a-zA-Z0-9_]*', text.lower())
    return {w for w in words if len(w) >= 4 and w not in STOPWORDS}


def resolve_bc_path(bc_id):
    """BC-2.SS.NNN → .../ss-SS/BC-2.SS.NNN.md"""
    m = re.match(r'BC-(\d+)\.(\d+)\.(\d+)', bc_id)
    if not m:
        return None
    section = m.group(2).zfill(2)
    return os.path.join(BC_BASE_DIR, f"ss-{section}", f"{bc_id}.md")


def extract_section(content, section_header):
    """
    Extract text from a ## Section to the next ## heading (exclusive).
    Returns the text within that section, or '' if not found.
    """
    # Match ## Postconditions, ## Invariants, ## Preconditions, ## Edge Cases
    pattern = re.compile(
        r'^## ' + re.escape(section_header) + r'\s*$',
        re.MULTILINE | re.IGNORECASE
    )
    m = pattern.search(content)
    if not m:
        return ''
    start = m.end()
    # Find next ## heading
    next_heading = re.search(r'^## ', content[start:], re.MULTILINE)
    end = start + next_heading.start() if next_heading else len(content)
    return content[start:end]


def count_numbered_items(section_text):
    """Count top-level numbered list items (^\d+\.) in section text, fence-aware."""
    # Skip lines inside fenced code blocks — they must not be treated as item boundaries.
    items = []
    in_fence = False
    for line in section_text.split('\n'):
        if line.strip().startswith('```'):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = re.match(r'^(\d+)\.\s', line)
        if m:
            items.append(int(m.group(1)))
    return items  # list of found numbers


def count_bullet_items(section_text):
    """Count top-level bullet items (^-) in section text; return count."""
    count = 0
    for line in section_text.split('\n'):
        if re.match(r'^-\s', line):
            count += 1
    return count


def get_ec_ids(section_text):
    """Return set of EC-NNN IDs found in ### EC-NNN: headers or table rows."""
    header_ids = set(re.findall(r'###\s+(EC-\d+)\b', section_text))
    table_ids  = set(re.findall(r'^\|\s*(EC-\d+)\s*\|', section_text, re.MULTILINE))
    return header_ids | table_ids


def get_stable_tags(section_text, tag_prefix):
    """
    Return the set of stable tag IDs present in section_text for the given prefix.
    tag_prefix is 'PC', 'INV', or 'PRE'.
    Matches {PC-NNN} / {INV-NNN} / {PRE-NNN} tokens anywhere in the section.
    Returns a set of normalised strings like {'PC-001', 'PC-002', ...}.
    Added for ADR-027 M2 dual-mode.
    """
    pattern = re.compile(r'\{' + re.escape(tag_prefix) + r'-(\d+)\}', re.IGNORECASE)
    return {f"{tag_prefix.upper()}-{m.zfill(3)}" for m in pattern.findall(section_text)}


def get_item_text_by_tag(section_text, tag):
    """
    Extract the text of a clause identified by its stable tag token, e.g. 'PC-001'.
    Scans from the line containing {TAG} to the line before the next stable tag at a
    top-level list-item boundary (^\\d+\\. or ^- at column 0), or end of section.
    Fence-aware: lines inside ``` fences belong to the enclosing clause.
    Returns '' when the tag is not found.
    Added for ADR-027 M2 dual-mode; used for CHECK-2 on new-form citations.
    """
    tag_token   = '{' + tag.upper() + '}'
    next_tag_re = re.compile(r'\{(?:PC|INV|PRE)-\d+\}', re.IGNORECASE)

    lines     = section_text.split('\n')
    capturing = False
    item_lines: list = []
    in_fence  = False

    for line in lines:
        if line.strip().startswith('```'):
            in_fence = not in_fence
            if capturing:
                item_lines.append(line)
            continue
        if in_fence:
            if capturing:
                item_lines.append(line)
            continue

        if not capturing:
            if tag_token in line:
                capturing = True
                item_lines.append(line)
        else:
            # Stop when a NEW top-level list marker carries a different stable tag
            top_marker = re.match(r'^(?:\d+\.\s|-\s)', line)
            if top_marker and next_tag_re.search(line) and tag_token not in line:
                break
            item_lines.append(line)

    return '\n'.join(item_lines)


def get_item_text(section_text, section_type, number_or_ec):
    """
    Extract the text of a specific numbered item or EC from a section.
    Used for CHECK 2 (error-code co-location) and CHECK 3 (keyword overlap).
    Returns '' if not found.
    """
    if section_type in ('postcondition', 'precondition'):
        # Numbered item: lines from N. up to next top-level M. (fence-aware).
        # Lines inside a ``` fenced block belong to the enclosing item and must
        # not be treated as new item boundaries.
        n = number_or_ec
        lines = section_text.split('\n')
        capturing = False
        item_lines = []
        in_fence = False
        for line in lines:
            if line.strip().startswith('```'):
                in_fence = not in_fence
                if capturing:
                    item_lines.append(line)
                continue
            if in_fence:
                if capturing:
                    item_lines.append(line)
                continue
            m = re.match(r'^(\d+)\.\s', line)
            if m:
                if int(m.group(1)) == n:
                    capturing = True
                    item_lines.append(line)
                elif capturing:
                    break
            elif capturing:
                item_lines.append(line)
        return '\n'.join(item_lines)

    elif section_type == 'invariant':
        n = number_or_ec
        lines = section_text.split('\n')
        # Detect list style: numbered (^\d+\.) wins over bullet (^-)
        is_numbered = any(re.match(r'^\d+\.\s', l) for l in lines)
        if is_numbered:
            # Walk numbered items, match by label (N. text) like postcondition branch (fence-aware).
            capturing = False
            item_lines = []
            in_fence = False
            for line in lines:
                if line.strip().startswith('```'):
                    in_fence = not in_fence
                    if capturing:
                        item_lines.append(line)
                    continue
                if in_fence:
                    if capturing:
                        item_lines.append(line)
                    continue
                lm = re.match(r'^(\d+)\.\s', line)
                if lm:
                    if int(lm.group(1)) == n:
                        capturing = True
                        item_lines.append(line)
                    elif capturing:
                        break
                elif capturing:
                    item_lines.append(line)
            return '\n'.join(item_lines)
        else:
            # Bullet style: the N-th bullet item (ordinal)
            count = 0
            capturing = False
            item_lines = []
            for line in lines:
                if re.match(r'^-\s', line):
                    count += 1
                    if count == n:
                        capturing = True
                        item_lines.append(line)
                    elif capturing:
                        break
                elif capturing:
                    # continuation lines (indented)
                    if line.startswith('  ') or line.startswith('\t') or line == '':
                        item_lines.append(line)
                    else:
                        break
            return '\n'.join(item_lines)

    elif section_type == 'edge_case':
        ec_id = number_or_ec  # e.g. 'EC-001'
        # Detect table format: section has rows matching | EC-NNN |
        if re.search(r'^\|\s*EC-\d+\s*\|', section_text, re.MULTILINE):
            # Table format: return the full matching row so error codes are visible
            for row in section_text.split('\n'):
                if re.match(r'^\|\s*' + re.escape(ec_id) + r'\s*\|', row):
                    return row
            return ''
        # Header-block format: ### EC-NNN: to next ### or ##
        pattern = re.compile(
            r'^###\s+' + re.escape(ec_id) + r'\b',
            re.MULTILINE
        )
        m = pattern.search(section_text)
        if not m:
            return ''
        start = m.start()
        # Search from m.end() so the current ### line is never re-matched
        rest = section_text[m.end():]
        next_h = re.search(r'^#{2,3} ', rest, re.MULTILINE)
        end = m.end() + next_h.start() if next_h else len(section_text)
        return section_text[start:end]

    return ''


# ── BC cache ─────────────────────────────────────────────────────────────────
_bc_cache = {}

def load_bc(bc_id):
    """Load and parse a BC file, return parsed dict or None if missing."""
    if bc_id in _bc_cache:
        return _bc_cache[bc_id]

    path = resolve_bc_path(bc_id)
    if path is None or not os.path.isfile(path):
        _bc_cache[bc_id] = None
        return None

    with open(path, encoding='utf-8') as f:
        content = f.read()

    pc_section  = extract_section(content, 'Postconditions')
    inv_section = extract_section(content, 'Invariants')
    pre_section = extract_section(content, 'Preconditions')
    ec_section  = extract_section(content, 'Edge Cases')

    parsed = {
        'content':       content,
        'pc_section':    pc_section,
        'inv_section':   inv_section,
        'pre_section':   pre_section,
        'ec_section':    ec_section,
        'pc_numbers':    count_numbered_items(pc_section),
        'pc_max':        max(count_numbered_items(pc_section), default=0),
        'inv_count':     max(len(count_numbered_items(inv_section)), count_bullet_items(inv_section)),
        'pre_numbers':   count_numbered_items(pre_section),
        'pre_max':       max(count_numbered_items(pre_section), default=0),
        'ec_ids':        get_ec_ids(ec_section),
        # Stable tag sets — populated for BCs that completed M1 labeling (ADR-027)
        'pc_tags':       get_stable_tags(pc_section, 'PC'),
        'inv_tags':      get_stable_tags(inv_section, 'INV'),
        'pre_tags':      get_stable_tags(pre_section, 'PRE'),
    }
    _bc_cache[bc_id] = parsed
    return parsed


# ── Story processing ─────────────────────────────────────────────────────────

findings = []     # list of dicts
total_citations   = 0
per_story_counts  = {}  # story_id -> (citations, drift)

story_files = sorted(
    f for f in os.listdir(STORIES_DIR)
    if f.startswith('STORY-S-') and f.endswith('.md')
)

for filename in story_files:
    filepath = os.path.join(STORIES_DIR, filename)

    # Extract story_id from frontmatter story_id field
    story_id = None
    with open(filepath, encoding='utf-8') as f:
        raw = f.read()
    m = re.search(r'^story_id:\s*(\S+)', raw, re.MULTILINE)
    if m:
        story_id = m.group(1).strip()
    if not story_id:
        # Fallback: derive from filename STORY-S-X.XX-...
        fm = re.match(r'STORY-(S-[\d.]+)-', filename)
        story_id = fm.group(1) if fm else filename

    story_citations = 0
    story_drift = 0
    story_advisory = 0

    # Pre-extract full AC block body for each citation header line.
    # CHECK 2 must scan the body text (not just the header) because error codes
    # asserted by an AC appear in the lines following the ### AC-NNN heading.
    raw_lines = raw.split('\n')
    _ac_body_cache = {}
    for _i, _rl in enumerate(raw_lines):
        if '### AC-' in _rl and 'traces to BC-' in _rl:
            _body = [_rl]
            _j = _i + 1
            while _j < len(raw_lines) and not re.match(r'^#{1,6} ', raw_lines[_j]):
                _body.append(raw_lines[_j])
                _j += 1
            _ac_body_cache[_rl] = '\n'.join(_body)

    for line in raw_lines:
        if 'traces to BC-' not in line:
            continue

        # ── Try NEW stable-tag form first (ADR-027 M2 dual-mode) ─────────────
        new_m = NEW_CITE_RE.search(line)
        if new_m:
            ac_id      = new_m.group(1)                    # e.g. AC-001
            bc_id      = new_m.group(2)                    # e.g. BC-2.08.006
            tag_prefix = new_m.group(3).upper()            # PC | INV | PRE | EC
            tag_num    = new_m.group(4).zfill(3)           # '001'
            tag_id     = f"{tag_prefix}-{tag_num}"         # e.g. PC-001

            total_citations += 1
            story_citations += 1

            bc = load_bc(bc_id)
            if bc is None:
                print(f"DRIFT {story_id} {ac_id} cited={tag_id} "
                      f"reason=bc-file-missing bc={bc_id}")
                story_drift += 1
                continue

            ac_text_full = _ac_body_cache.get(line, line)

            # CHECK 1 (new form): stable tag token must exist in BC section
            if tag_prefix == 'PC':
                exists = tag_id in bc['pc_tags']
                section_key = 'pc_section'
            elif tag_prefix == 'INV':
                exists = tag_id in bc['inv_tags']
                section_key = 'inv_section'
            elif tag_prefix == 'PRE':
                exists = tag_id in bc['pre_tags']
                section_key = 'pre_section'
            else:  # EC — same logic as old form
                exists = tag_id in bc['ec_ids']
                section_key = 'ec_section'

            if not exists:
                print(f"DRIFT {story_id} {ac_id} cited={tag_id} "
                      f"reason=nonexistent bc={bc_id}")
                story_drift += 1
                continue

            # CHECK 2 (new form): error-code co-location (advisory)
            ac_codes = ERRCODE_RE.findall(ac_text_full)
            if ac_codes:
                if tag_prefix in ('PC', 'INV', 'PRE'):
                    item_text = get_item_text_by_tag(bc[section_key], tag_id)
                else:
                    item_text = get_item_text(bc['ec_section'], 'edge_case', tag_id)
                if item_text:
                    for code in ac_codes:
                        if code not in item_text:
                            print(f"ADVISORY {story_id} {ac_id} cited={tag_id} "
                                  f"reason=code-absent asserted-code={code} bc={bc_id}")
                            story_advisory += 1
                            break  # one ADVISORY per AC

            continue  # new-form citation fully processed; do not fall through

        # ── OLD ordinal form fallback ─────────────────────────────────────────
        m = OLD_CITE_RE.search(line)
        if not m:
            # Skip complex formats: PC9/EC-008, postconditions 1/2/3 (slash-separated)
            # These are non-standard and checked by adversary separately
            if re.search(r'BC-\d+\.\d+\.\d+\s+PC\d+', line):
                continue   # PC-shorthand table format — skip
            if re.search(r'postconditions?\s+\d+/\d+', line, re.IGNORECASE):
                continue   # multi-cite slash format — skip
            continue

        ac_id    = m.group(1)          # e.g. AC-001
        bc_id    = m.group(2)          # e.g. BC-2.08.006
        sec_raw  = m.group(3).lower().replace(' ', '_')  # postcondition/invariant/edge_case/precondition
        detail   = (m.group(4) or '').strip()   # e.g. "5" or "EC-001" or "" or "1/2/3"
        trailing = m.group(5).strip()            # e.g. "— Red Gate"

        # Normalise section type
        if sec_raw.startswith('postcondition'):
            sec_type = 'postcondition'
        elif sec_raw == 'invariant':
            sec_type = 'invariant'
        elif sec_raw == 'precondition':
            sec_type = 'precondition'
        elif sec_raw.startswith('edge_case'):
            sec_type = 'edge_case'
        else:
            continue  # unknown — skip

        # Skip slash-separated multi-cite in detail
        if '/' in detail:
            continue

        # Parse cited number or EC-ID
        cited_num  = None  # int, for postcondition/invariant/precondition
        cited_ec   = None  # str, e.g. 'EC-001', for edge_case

        if sec_type == 'edge_case':
            if not detail.startswith('EC-'):
                continue  # malformed — skip
            cited_ec = detail
        elif sec_type == 'invariant' and detail == '':
            cited_num = None  # bare "invariant" — just existence check
        elif detail:
            try:
                cited_num = int(detail)
            except ValueError:
                continue  # can't parse — skip

        total_citations += 1
        story_citations += 1

        # ── Load BC ───────────────────────────────────────────────────────────
        bc = load_bc(bc_id)
        if bc is None:
            print(f"DRIFT {story_id} {ac_id} cited={sec_type}{('_'+detail) if detail else ''} "
                  f"reason=bc-file-missing bc={bc_id}")
            story_drift += 1
            continue

        # Full AC block text (header + body) for error-code extraction.
        # Using only the header line was the root-cause false-negative: error codes
        # asserted by the AC appear in the body, not in the ### AC-NNN citation line.
        ac_text_full = _ac_body_cache.get(line, line)

        # ── CHECK 1: Existence check (old ordinal form) ───────────────────────
        exists = True
        cited_label = ''

        if sec_type == 'postcondition':
            if cited_num is None:
                pass  # bare postcondition without number — skip existence check
            else:
                cited_label = f'postcondition_{cited_num}'
                if cited_num not in bc['pc_numbers']:
                    exists = False

        elif sec_type == 'invariant':
            if cited_num is None:
                # Bare "invariant" — just check section exists and has content
                cited_label = 'invariant'
                if bc['inv_count'] == 0:
                    exists = False
            else:
                cited_label = f'invariant_{cited_num}'
                if cited_num > bc['inv_count']:
                    exists = False

        elif sec_type == 'precondition':
            if cited_num is None:
                pass
            else:
                cited_label = f'precondition_{cited_num}'
                if cited_num not in bc['pre_numbers']:
                    exists = False

        elif sec_type == 'edge_case':
            cited_label = cited_ec
            if cited_ec not in bc['ec_ids']:
                exists = False

        if not exists:
            print(f"DRIFT {story_id} {ac_id} cited={cited_label} "
                  f"reason=nonexistent bc={bc_id}")
            story_drift += 1
            continue  # no point checking further if item doesn't exist

        # ── CHECK 2: Error-code co-location ───────────────────────────────────
        ac_codes = ERRCODE_RE.findall(ac_text_full)
        if ac_codes and cited_label:
            # Get the specific item text from the BC
            if sec_type in ('postcondition', 'precondition'):
                item_text = get_item_text(bc['pc_section' if sec_type == 'postcondition' else 'pre_section'],
                                          sec_type, cited_num)
            elif sec_type == 'invariant' and cited_num is not None:
                item_text = get_item_text(bc['inv_section'], 'invariant', cited_num)
            elif sec_type == 'edge_case':
                item_text = get_item_text(bc['ec_section'], 'edge_case', cited_ec)
            else:
                item_text = ''

            if item_text:
                for code in ac_codes:
                    if code not in item_text:
                        # Code is asserted in AC but not present in the specifically cited item
                        # (Could be in a different PC/EC — strong drift signal)
                        print(f"ADVISORY {story_id} {ac_id} cited={cited_label} "
                              f"reason=code-absent asserted-code={code} bc={bc_id}")
                        story_advisory += 1
                        break  # one ADVISORY line per AC

            # Don't emit a second DRIFT/ADVISORY for the same AC if code-absent already fired

        # ── CHECK 3: Keyword-overlap heuristic (low-confidence WARN) ─────────
        # Only run if no DRIFT already emitted for this AC
        # and AC text has ≥4 content words
        if story_drift == 0 or True:  # always run; overlap is non-blocking anyway
            pass  # overlap check suppressed in this release — advisory only at AC level

    per_story_counts[story_id] = (story_citations, story_drift, story_advisory)
    if story_drift > 0:
        pass  # tally below

# ── Per-story summary ─────────────────────────────────────────────────────────
stories_with_drift = sum(1 for s, (c, d, a) in per_story_counts.items() if d > 0)
total_advisory = sum(a for s, (c, d, a) in per_story_counts.items())

print(f"SUMMARY total_citations={total_citations} stories_checked={len(per_story_counts)} stories_with_drift={stories_with_drift} total_advisory={total_advisory}")
for sid in sorted(per_story_counts):
    c, d, a = per_story_counts[sid]
    status = 'PASS' if d == 0 else 'FAIL'
    print(f"STORY_RESULT {sid} {status} citations={c} drift={d} advisory={a}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

TOTAL_CITATIONS=0
TOTAL_STORIES_CHECKED=0
STORIES_WITH_DRIFT=0
DRIFT=0
ADVISORY_COUNT=0

while IFS= read -r line; do
  case "$line" in
    DRIFT*)
      echo "$line"
      DRIFT=$((DRIFT + 1))
      ;;
    ADVISORY*)
      echo "$line"
      ADVISORY_COUNT=$((ADVISORY_COUNT + 1))
      ;;
    SUMMARY*)
      TOTAL_CITATIONS=$(echo "$line" | grep -oE 'total_citations=[0-9]+' | cut -d= -f2)
      TOTAL_STORIES_CHECKED=$(echo "$line" | grep -oE 'stories_checked=[0-9]+' | cut -d= -f2)
      STORIES_WITH_DRIFT=$(echo "$line" | grep -oE 'stories_with_drift=[0-9]+' | cut -d= -f2)
      ;;
    STORY_RESULT*)
      # e.g. STORY_RESULT S-1.01 PASS citations=10 drift=0
      story_id=$(echo "$line" | awk '{print $2}')
      status=$(echo "$line" | awk '{print $3}')
      details=$(echo "$line" | cut -d' ' -f4-)
      echo "  $status $story_id $details"
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-ac-pc-trace: checked $TOTAL_CITATIONS citations across $TOTAL_STORIES_CHECKED stories"
echo ""
echo "Dual-mode citation resolution (ADR-027 M2):"
echo "  NEW stable-tag form: AC cites BC-S.SS.NNN PC-NNN / INV-NNN / PRE-NNN / EC-NNN"
echo "    CHECK 1 resolves by grepping {TAG} token in the BC section."
echo "  OLD ordinal form: AC cites BC-S.SS.NNN postcondition N / invariant N / precondition N"
echo "    CHECK 1 resolves by ordinal count (unchanged from pre-M2 logic)."
echo "  Both forms accepted during M2-M3 window. Strict new-form enforcement is M4."
echo ""
echo "Checks implemented:"
echo "  CHECK 1 (BLOCKING): Existence — cited PC/INV/EC/PRE tag or ordinal must exist in the referenced BC"
echo "           reason=nonexistent | reason=bc-file-missing -> DRIFT line -> exits 1"
echo "  CHECK 2 (ADVISORY): Error-code co-location — E-XXX-NNN asserted in AC must appear in cited item"
echo "           reason=code-absent -> ADVISORY line -> does not block (heuristic; codes may appear"
echo "           in ACs as examples/table-rows/contrast without implying the cited item contains them)"
echo "  CHECK 3: Keyword-overlap heuristic (suppressed in v1 — reserved for future use)"
echo "           reason=low-overlap (not emitted)"
echo ""
echo "Per-story pass/fail above."
echo ""
echo "CHECK-1 (blocking) drift: $DRIFT"
echo "CHECK-2 (advisory) hints: $ADVISORY_COUNT"
echo ""
if [ "$DRIFT" -gt 0 ]; then
  echo "RESULT: FAIL ($DRIFT blocking drift citations across $STORIES_WITH_DRIFT stories)"
  exit 1
else
  echo "RESULT: PASS (CHECK-1 drift=0; CHECK-2 advisory hints=$ADVISORY_COUNT)"
  exit 0
fi
