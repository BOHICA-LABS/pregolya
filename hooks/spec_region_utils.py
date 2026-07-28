"""
Canonical changelog-region detector for ferrochain factory-artifacts hooks.

Single source of truth for "what counts as a changelog region."
Imported by verify-no-version-pins.sh and verify-signature-canon.sh.

DESIGN PRINCIPLE — arose from FIX-BURST-278-WAVE-C, 2026-07-28:
  An authoring rule that requires quoting a term cannot apply to terms a gate
  forbids — otherwise the changelog documenting a fix trips the gate that
  motivated it.  This is a general constraint: whenever a gate forbids pattern P,
  every changelog entry describing a past fix to P must be able to write P
  verbatim.  Region-exempt logic implements this constraint: frontmatter
  changelog: entries and body ## Changelog sections are descriptive (historical
  record), not normative (implementer guidance).  Only normative positions —
  prose, postconditions, invariants, table cells, Architecture Anchors, and code
  fences — need gating.

Exempt regions
──────────────
(a) YAML frontmatter: all lines 0..fm_end_line (inclusive), where fm_end_line
    is the line index of the closing '---' delimiter.  The changelog: YAML key
    lives inside frontmatter; blanket frontmatter exemption covers it while also
    covering every other frontmatter field (version:, supersedes:, ...) that
    should never carry normative content.

(b) Body ## Changelog sections: all lines from a '## Changelog' heading through
    (not including) the next '## ' heading, or EOF.  There may be multiple such
    sections per file.

Normative — IN SCOPE for gating
────────────────────────────────
All lines not in (a) or (b): prose, postconditions, invariants, table cells,
Architecture Anchors, code fences, and any other body content.
"""

import re

_CHANGELOG_HEADING_RE = re.compile(r'^## Changelog\s*$')
_SECTION_HEADING_RE   = re.compile(r'^## ')


def changelog_exempt_lines(raw_lines):
    """
    Return a frozenset of 0-indexed line numbers that are exempt from
    normative-content scanning (frontmatter + ## Changelog body sections).

    Parameters
    ----------
    raw_lines : list[str]
        File content as a list of raw lines (with or without trailing newline).

    Returns
    -------
    frozenset[int]
        0-indexed line numbers to skip.  Membership test: ``idx in result``.
    """
    exempt = set()

    # ── (a) YAML frontmatter ─────────────────────────────────────────────────
    # Lines 0..fm_end (inclusive) are the YAML block between the opening and
    # closing '---' delimiters.  If no closing delimiter is found, treat the
    # file as having no frontmatter (fm_end = -1 → no lines added to exempt).
    fm_end = -1
    if raw_lines and raw_lines[0].rstrip() == '---':
        for i in range(1, len(raw_lines)):
            if raw_lines[i].rstrip() == '---':
                fm_end = i
                break

    for i in range(0, fm_end + 1):
        exempt.add(i)

    # ── (b) Body ## Changelog sections ──────────────────────────────────────
    # Walk lines after frontmatter.  When a '## Changelog' heading is found,
    # mark all lines from that heading through (not including) the next '## '
    # heading or EOF.
    i = fm_end + 1
    while i < len(raw_lines):
        if _CHANGELOG_HEADING_RE.match(raw_lines[i]):
            start = i
            j = i + 1
            while j < len(raw_lines):
                if _SECTION_HEADING_RE.match(raw_lines[j]):
                    break
                j += 1
            for k in range(start, j):
                exempt.add(k)
            i = j
        else:
            i += 1

    return frozenset(exempt)
