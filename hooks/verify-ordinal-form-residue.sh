#!/usr/bin/env bash
# verify-ordinal-form-residue.sh — ADR-027 old-form clause ordinal residue scanner
#
# PURPOSE
# ───────
# Scans .factory/stories/stories/ and .factory/specs/behavioral-contracts/ for
# old-form clause ordinals that ADR-027 Decision 3 retired corpus-wide.
# This check is ADVISORY ONLY — it never blocks commits.
# Promotion to blocking gate requires zero residue corpus-wide.
#
# DETECTED OLD FORMS (in live content only):
#   OE-1 — "postcondition N"  word form + bare number (case-insensitive)
#   OE-2 — "invariant N"      word form + bare number
#   OE-3 — "precondition N"   word form + bare number
#   OE-4 — "edge case EC-..."  prose-prefix phrase before any EC citation
#   OE-5 — "EC-N"             single-digit EC reference (non-stable; stable is EC-NNN)
#   OE-6 — "BC-S.SS.NNN EC-N" BC citation with single-digit EC suffix
#
# EXCLUSIONS:
#   (a) YAML frontmatter changelog: list items (lines indented under changelog:)
#   (b) ## Changelog markdown sections (until next ## heading)
#   (c) Fenced code blocks (between ``` markers)
#   (d) Stable-tag forms (PC-NNN / INV-NNN / PRE-NNN / EC-NNN three-digit) are
#       already naturally excluded — word-form patterns do not match them
#
# EXIT CONTRACT
# ─────────────
# Always exits 0 (advisory: WARN output never blocks commit).
# Emits "ADVISORY: 0 residue corpus-wide" if clean.
# Emits "ADVISORY: N old-form ordinal(s) found — routing to PO/story-writer" if not.
#
# PROMOTION PATH
# ──────────────
# Once residue reaches zero, orchestrator promotes to blocking by:
#   1. Adding run_blocking "verify-ordinal-form-residue.sh" to pre-commit-validators.sh
#   2. Incrementing EXPECTED_BLOCKING_COUNT from 15 to 16
#   3. Changing exit contract below from "exit 0" to "exit $rc"

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HOOKS_DIR/../.." && pwd)"
STORIES_DIR="$REPO_ROOT/.factory/stories/stories"
BC_DIR="$REPO_ROOT/.factory/specs/behavioral-contracts"

# ── Python3 scanner (handles state: YAML changelog region, ## Changelog, code blocks) ──
python3 - "$STORIES_DIR" "$BC_DIR" <<'PYEOF'
import re
import sys
from pathlib import Path

STORIES_DIR = Path(sys.argv[1])
BC_DIR      = Path(sys.argv[2])

# ── Detection patterns ────────────────────────────────────────────────────────
# OE-1/2/3: word-form clause ordinals (case-insensitive)
WORD_ORDINAL_RE = re.compile(
    r'\b(postcondition|invariant|precondition)\s+(\d+)\b',
    re.IGNORECASE
)
# OE-4: "edge case EC-..." prose prefix
EDGE_CASE_EC_RE = re.compile(r'\bedge\s+case\s+EC-', re.IGNORECASE)
# OE-5/6: single-digit EC reference (not followed by more digits → non-stable)
OLD_EC_RE = re.compile(r'\bEC-([0-9])(?![0-9])')

# ── Region exclusion helpers ──────────────────────────────────────────────────
# Fenced code block toggle (```)
CODE_FENCE_RE    = re.compile(r'^```')
# Top-level YAML key (used to detect end of changelog: block)
YAML_KEY_RE      = re.compile(r'^[a-zA-Z_][\w_-]*\s*:')
# Markdown ## Changelog heading
MD_CHANGELOG_RE  = re.compile(r'^##\s+Changelog\b', re.IGNORECASE)
# Any markdown ## heading (used to end ## Changelog region)
MD_HEADING_RE    = re.compile(r'^##\s+')

# ── Scan a single file ────────────────────────────────────────────────────────
def scan_file(path: Path) -> list:
    """Return list of (lineno, line_text, oe_code, detail) tuples."""
    try:
        raw = path.read_text(encoding='utf-8', errors='replace')
    except Exception as e:
        return []

    lines = raw.splitlines()
    findings = []

    in_yaml_front      = False
    yaml_ended         = False
    in_yaml_changelog  = False  # inside changelog: list in YAML frontmatter
    in_md_changelog    = False  # inside ## Changelog body section
    in_code_block      = False

    for lineno, line in enumerate(lines, 1):
        stripped = line.strip()

        # ── YAML frontmatter boundaries ───────────────────────────────────────
        if lineno == 1 and stripped == '---':
            in_yaml_front = True
            continue
        if in_yaml_front and not yaml_ended:
            if stripped == '---':
                in_yaml_front  = False
                yaml_ended     = True
                in_yaml_changelog = False
                continue
            # Detect start of changelog: list
            if re.match(r'^changelog\s*:', stripped):
                in_yaml_changelog = True
                continue
            # Any other top-level key ends the changelog block
            if YAML_KEY_RE.match(stripped) and not stripped.startswith('-'):
                in_yaml_changelog = False
            # Skip all lines in the changelog: list (they are historical records)
            if in_yaml_changelog:
                continue
            # Other YAML frontmatter lines are live (description, traces_to, etc.)
            # but they rarely have ordinal citations — include them for completeness

        # ── Fenced code block toggle (only in body) ───────────────────────────
        if yaml_ended or not in_yaml_front:
            if CODE_FENCE_RE.match(stripped):
                in_code_block = not in_code_block
                continue
            if in_code_block:
                continue

        # ── ## Changelog section in markdown body ─────────────────────────────
        if yaml_ended or not in_yaml_front:
            if MD_CHANGELOG_RE.match(stripped):
                in_md_changelog = True
                continue
            if in_md_changelog and MD_HEADING_RE.match(stripped):
                in_md_changelog = False
            if in_md_changelog:
                continue

        # ── Pattern matching on live content ──────────────────────────────────
        # OE-1/2/3: word-form clause ordinals
        for m in WORD_ORDINAL_RE.finditer(line):
            keyword = m.group(1).lower()
            number  = m.group(2)
            oe_code = {'postcondition': 'OE-1', 'invariant': 'OE-2', 'precondition': 'OE-3'}[keyword]
            findings.append((lineno, line.rstrip(), oe_code,
                             f'{keyword} {number}'))

        # OE-4: "edge case EC-..." prose prefix
        for m in EDGE_CASE_EC_RE.finditer(line):
            findings.append((lineno, line.rstrip(), 'OE-4',
                             line[m.start():m.start()+20].rstrip()))

        # OE-5/6: single-digit EC reference
        for m in OLD_EC_RE.finditer(line):
            digit = m.group(1)
            findings.append((lineno, line.rstrip(), 'OE-5/6',
                             f'EC-{digit}'))

    return findings

# ── Deduplicate findings per (path, lineno, oe_code, detail) ─────────────────
# A line can match multiple patterns; emit once per distinct match.
def run_scan(root: Path, glob_pattern: str) -> dict:
    """Returns {relative_path: [(lineno, line, oe_code, detail), ...]}"""
    results = {}
    for p in sorted(root.rglob(glob_pattern)):
        hits = scan_file(p)
        if hits:
            # Deduplicate within file (same lineno+oe_code+detail)
            seen = set()
            deduped = []
            for h in hits:
                key = (h[0], h[2], h[3])
                if key not in seen:
                    seen.add(key)
                    deduped.append(h)
            results[p] = deduped
    return results

# ── Run both corpuses ─────────────────────────────────────────────────────────
stories_hits = run_scan(STORIES_DIR, '*.md') if STORIES_DIR.is_dir() else {}
bc_hits      = run_scan(BC_DIR,      '*.md') if BC_DIR.is_dir()      else {}

all_hits = {}
all_hits.update(stories_hits)
all_hits.update(bc_hits)

total = sum(len(v) for v in all_hits.values())

# ── Emit report ───────────────────────────────────────────────────────────────
if total == 0:
    print("ADVISORY: 0 residue corpus-wide — no old-form clause ordinals detected")
    sys.exit(0)

print(f"ADVISORY: {total} old-form ordinal(s) found — routing to PO/story-writer for stable-tag migration")
print()

for path, hits in sorted(all_hits.items()):
    # Make path relative to repo root for readability
    try:
        rel = path.relative_to(Path(sys.argv[1]).parent.parent.parent)
    except ValueError:
        rel = path
    print(f"  FILE: {rel}")
    for lineno, line_text, oe_code, detail in hits:
        # Truncate long lines for readability
        snippet = line_text.strip()[:120]
        print(f"    [{oe_code}] line {lineno:4d} | {detail!r:30s} | {snippet}")
    print()

sys.exit(0)  # ADVISORY: always exits 0
PYEOF

# Capture exit code from Python (should always be 0 — advisory)
RC=$?
# Always exit 0 regardless (belt-and-suspenders: Python already exits 0)
exit 0
