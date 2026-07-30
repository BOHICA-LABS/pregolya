"""
Canonical changelog-region detector for pregolya factory-artifacts hooks.

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

Exempt regions — changelog_exempt_lines()
──────────────────────────────────────────
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

Illustration regions — illustration_exempt_lines()
──────────────────────────────────────────────────
Canon documents (primarily ADR-010) contain intentional FORBIDDEN-form examples
that demonstrate the prohibited patterns for documentation purposes.  These lines
are NOT normative assertions — they show what NOT to do.

Illustration regions are marked with HTML comment pairs in the markdown source:
    <!-- discriminator:illustration-start -->
    ...lines showing forbidden/violation forms for documentation only...
    <!-- discriminator:illustration-end -->

The marker lines themselves are excluded.  Regions may be nested (unlikely in
practice) but the implementation handles them correctly via a depth counter.

This mechanism ensures that a CI validator running the discriminator against
canon documents does not permanently fail due to the canon's own examples.
"""

import re

_CHANGELOG_HEADING_RE = re.compile(r'^## Changelog\s*$')
_SECTION_HEADING_RE   = re.compile(r'^## ')
_ILLUS_START_RE = re.compile(r'<!--\s*discriminator:illustration-start\s*-->')
_ILLUS_END_RE   = re.compile(r'<!--\s*discriminator:illustration-end\s*-->')

# ── PregolyaError opener detection ─────────────────────────────────────────
# Used by find_pregolya_error_openers() to locate both single-line and
# split-line PregolyaError { ... } openers.
#
# Single-line form: identifier and opening brace on the same line.
#   e.g. `PregolyaError { code: "E-X", .. }`
#
# Split-line form: identifier at end of line N, opening brace at start of N+1.
#   e.g. line N  → `Err(PregolyaError`
#        line N+1 → `{ category: VAL, .. })`
#
# _PREGOLYA_SPLIT_END_RE matches a line that ends with the PregolyaError
# identifier (optional trailing whitespace/backtick/parenthesis but NO `{`).
# _SPLIT_BRACE_START_RE matches a continuation line whose first non-whitespace
# character is `{`.
_PREGOLYA_SINGLE_LINE_RE = re.compile(r'\bPregolyaError\s+\{')
_PREGOLYA_SPLIT_END_RE   = re.compile(r'\bPregolyaError\s*$')
_SPLIT_BRACE_START_RE      = re.compile(r'^\s*\{')


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


def illustration_exempt_lines(raw_lines):
    """
    Return a frozenset of 0-indexed line numbers that fall inside illustration
    regions (inclusive of marker lines).

    Illustration regions are marked with HTML comment pairs:
        <!-- discriminator:illustration-start -->
        <!-- discriminator:illustration-end -->

    These mark blocks that intentionally show FORBIDDEN/violation forms for
    documentation purposes (e.g. in ADR-010's FORBIDDEN examples block and
    worked-examples table).  Lines inside these regions are EXCLUDED_ILLUSTRATION
    and must not be counted as normative violations.

    IMPORTANT: Marker detection is skipped for lines already in changelog-exempt
    regions (YAML frontmatter and ## Changelog sections).  This prevents accidental
    region opening when a changelog entry describes the marker syntax verbatim
    (e.g. "... marked with `<!-- discriminator:illustration-start -->` ...").

    Parameters
    ----------
    raw_lines : list[str]
        File content as a list of raw lines (with or without trailing newline).

    Returns
    -------
    frozenset[int]
        0-indexed line numbers to skip.  Membership test: ``idx in result``.
    """
    # Compute changelog-exempt lines first; skip marker detection there.
    changelog_exempt = changelog_exempt_lines(raw_lines)

    exempt = set()
    depth = 0  # nesting depth (start increments, end decrements)

    for i, line in enumerate(raw_lines):
        # Skip marker detection in frontmatter / ## Changelog regions.
        # These regions are historical record; they may quote the marker syntax
        # for documentation but must never open/close normative illustration regions.
        if i in changelog_exempt:
            if depth > 0:
                exempt.add(i)  # still mark as exempt if we're inside a region
            continue

        had_start = bool(_ILLUS_START_RE.search(line))
        had_end   = bool(_ILLUS_END_RE.search(line))

        if had_start and had_end:
            # Both markers on the same line (e.g. a table row that quotes the
            # marker syntax for documentation).  Treat as a self-contained
            # zero-depth region: exempt the line but leave depth unchanged.
            exempt.add(i)
        elif had_start:
            depth += 1
            exempt.add(i)  # marker line itself is excluded
        elif had_end:
            if depth > 0:
                exempt.add(i)  # marker line itself is excluded
                depth -= 1
        elif depth > 0:
            exempt.add(i)

    return frozenset(exempt)


def find_pregolya_error_openers(raw_lines):
    """
    Locate all PregolyaError { opener positions, including split-line forms
    where the identifier and the opening brace appear on adjacent lines.

    Single-line form
    ----------------
    ``PregolyaError {`` on one line.  opener_line == brace_line.

    Split-line form (Gap 2 — NOTATION-GAP-FIX)
    -------------------------------------------
    ``PregolyaError`` at the end of line N (nothing after it on that line
    except optional whitespace); ``{`` as the first non-whitespace character
    on line N+1.  opener_line = N, brace_line = N+1.

    Step 0 EXCLUDED_DECL applies to the OPENER LINE
    -------------------------------------------------
    Callers check whether the line at ``opener_line`` contains
    ``pub struct PregolyaError`` or ``impl PregolyaError``.  This rule
    applies equally to single-line and split-line forms — a split-line
    ``pub struct PregolyaError`` / ``{`` is still EXCLUDED_DECL.

    This function does NOT apply any Step 0 exclusions.  Callers are
    responsible for filtering with ``changelog_exempt_lines()`` and
    ``illustration_exempt_lines()`` and for applying all EXCLUDED_* rules.

    Parameters
    ----------
    raw_lines : list[str]
        File content as a list of raw lines (with or without trailing newline).

    Returns
    -------
    list[dict]
        Each dict has three keys:
            ``opener_line`` : int — 0-indexed line where PregolyaError appears
            ``brace_line``  : int — 0-indexed line where { appears
                                    (== opener_line for single-line form;
                                     opener_line + 1 for split-line form)
            ``form``        : str — ``"single"`` | ``"split"``
    """
    results = []
    i = 0
    while i < len(raw_lines):
        line = raw_lines[i].rstrip('\n')
        if _PREGOLYA_SINGLE_LINE_RE.search(line):
            # Single-line form: PregolyaError { on the same line.
            results.append({"opener_line": i, "brace_line": i, "form": "single"})
        elif _PREGOLYA_SPLIT_END_RE.search(line):
            # PregolyaError at end of line — check if the next line opens with {.
            if i + 1 < len(raw_lines):
                next_line = raw_lines[i + 1].rstrip('\n')
                if _SPLIT_BRACE_START_RE.match(next_line):
                    results.append(
                        {"opener_line": i, "brace_line": i + 1, "form": "split"}
                    )
        i += 1
    return results
