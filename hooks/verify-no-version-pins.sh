#!/usr/bin/env bash
# verify-no-version-pins.sh — ferrochain factory-artifacts wrap guard
#
# Scans all .md files under .factory/specs/ for LIVE-BODY volatile version
# pins of the following forms:
#
#   ADR-\d+\s+v\d+\.\d+             e.g. "ADR-018 v1.3"
#   BC-2\.\d{2}\.\d{3}\s+v\d+\.\d+  e.g. "BC-2.06.001 v1.4"
#   VP-\d{3}\s+v\d+\.\d+            e.g. "VP-011 v1.2"
#   CAP-\d{3}\s+v\d+\.\d+           e.g. "CAP-018 v1.2"
#   [a-z0-9][a-z0-9_-]*\.md\s+\(v\d+\.\d+   e.g. "error-taxonomy.md (v1.31, D23)"
#   [a-z0-9][a-z0-9_-]*\.md\s+v\d+\.\d+     e.g. "bc-authoring-plan.md v2.10"
#
# Patterns 5 and 6 were added in FIX-BURST-268 (OBS-P166-B) to catch supplement
# self-referential pins of the form `<filename>.md (vN.N` and `<filename>.md vN.N`.
# Both patterns use a negative lookbehind `(?<![A-Za-z0-9_-])` to avoid false
# positives on paths like `VP-010.md v1.1` where the `0` is immediately preceded
# by a hyphen (a word-boundary char) that anchors the token to an ID namespace.
#
# EXEMPTIONS — the following locations are NOT scanned:
#
#   (a) YAML frontmatter block (all lines between the first and second '---'
#       delimiters).  Rationale: changelog: list entries are the primary source
#       of version pins here; blanket frontmatter exemption gives zero false
#       positives on multi-line changelog: strings while covering every other
#       frontmatter field (version:, supersedes:, etc.) that should never carry
#       body-style version pins.
#
#   (b) Body ## Changelog section (all lines from a "## Changelog" heading to
#       the next "## " heading or end of file).  Rationale: these rows record
#       historical change state and are explicitly excepted by TD-VSDD-091
#       ("pass-report changelogs").
#
#   (c) Lines listed in .factory/hooks/version-pin-allowlist.txt.
#       Format (one entry per non-comment line):
#         <path-relative-to-.factory/specs>:<1-indexed-line-number>
#       Allowlist entries are for Red Gate test tables, AC source-of-truth
#       tables, and quoted historical before-state that cannot be de-pinned
#       without losing meaning.  Each entry MUST be accompanied by a reason
#       comment on the preceding line:
#         # Reason: Red Gate test table — audit-trail pin
#         architecture/decisions/ADR-018-per-tool-call-approval-hook.md:142
#
# DESIGN NOTE — section detection vs. allowlist trade-off:
#   Section heading context detection (e.g., inferring that a line is inside a
#   "Red Gate Test Table" block from preceding ## headings) is feasible for
#   well-structured files but fragile across the diverse document shapes in this
#   corpus.  The allowlist mechanism provides the escape hatch for any edge case
#   that reliable heading detection would miss; the ## Changelog detection covers
#   the high-volume case.
#
# KNOWN EXPECTED FAILURES: 3 live-normative supplement pins (FIX-BURST-268, OBS-P166-B).
#   These were uncovered when patterns 5 and 6 were added; they are outside devops
#   scope and must be closed by the owning specialist before the next burst gate.
#   (Historical: FIX-BURST-262 closed 4 volatile-pin sites in ADR-018 ~line 156,
#    module-decomposition ~line 69, purity-boundary-map ~line 83, ADR-019 ~line 33.
#    FIX-BURST-268 patterns-1..4 parallel work fixed VP-013 ~line 236 and
#    prd-supplements/module-criticality.md superseded-banner.)
#
#   OPEN (FAIL=3 expected until owners close):
#     architecture/decisions/ADR-012-self-improvement-primitives.md:52
#       match: "bc-authoring-plan.md v2.10"  owner: architect
#     behavioral-contracts/ss-19/BC-2.19.005.md:109
#       match: "error-taxonomy.md v1.28"     owner: product-owner
#     behavioral-contracts/ss-19/BC-2.19.006.md:86
#       match: "error-taxonomy.md v1.27"     owner: product-owner
#
#   Any FAIL beyond these three is a NEW finding requiring a fix-burst.
#
# Usage:   bash .factory/hooks/verify-no-version-pins.sh
# Exit:    0 if no FAIL lines; 1 if any FAIL.
#
# Integration (state-manager burst protocol — validator #4):
#   Add as the last validation step before the atomic factory-artifacts commit:
#     bash .factory/hooks/verify-no-version-pins.sh

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPECS_ROOT="$FACTORY_DIR/specs"
ALLOWLIST="$FACTORY_DIR/hooks/version-pin-allowlist.txt"

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

# ── Python3 inline scanner ────────────────────────────────────────────────────
#
# Produces one output line per file:
#   PASS <filepath>
#   FAIL <filepath> <finding1>; <finding2>; ...
#   SKIP <filepath> <reason>
#
# Each finding has the form:
#   live-body-pin:line=<N>,text=<matched-text>

PYTHON_OUTPUT="$(python3 - "$SPECS_ROOT" "$ALLOWLIST" <<'PYEOF'
import sys, os, glob, re

specs_root  = sys.argv[1]
allowlist_f = sys.argv[2]

# ── Pin patterns ──────────────────────────────────────────────────────────────
#
# Each pattern is anchored to a word boundary on the left so that partial
# matches like "BC-2.10.003X v1.2" are not flagged.  The version suffix ends
# at any non-digit-or-dot character, so "BC-2.06.001 v1.4)" is still caught.
#
# Pattern groups (one compiled regex, alternation):
#   1. ADR-\d+ v\d+\.\d+
#   2. BC-2\.\d{2}\.\d{3} v\d+\.\d+
#   3. VP-\d{3} v\d+\.\d+
#   4. CAP-\d{3} v\d+\.\d+
#   5. <filename>.md (vX.Y   — paren-form supplement self-referential pin
#   6. <filename>.md vX.Y    — noparen-form supplement self-referential pin
#
# Patterns 5 and 6 (added FIX-BURST-268 OBS-P166-B): catch F-P166-01 class hits
# such as "error-taxonomy.md (v1.31, D23)" and "bc-authoring-plan.md v2.10".
# The same negative lookbehind prevents false positives on identifier-prefixed
# paths like VP-010.md v1.1 (the "-" before "010" is in [A-Za-z0-9_-] and blocks
# the match) or upper-case-prefixed paths like ARCH-INDEX.md v1.6 (the "A" does
# not match [a-z0-9] at the start of the alternation arm).

PIN_RE = re.compile(
    r'(?<![A-Za-z0-9_-])'                      # negative lookbehind: not preceded by word char
    r'(?:'
    r'ADR-\d+\s+v\d+\.\d+'                      # 1. ADR-NNN vX.Y
    r'|BC-2\.\d{2}\.\d{3}\s+v\d+\.\d+'          # 2. BC-2.SS.NNN vX.Y
    r'|VP-\d{3}\s+v\d+\.\d+'                    # 3. VP-NNN vX.Y
    r'|CAP-\d{3}\s+v\d+\.\d+'                   # 4. CAP-NNN vX.Y
    r'|[a-z0-9][a-z0-9_-]*\.md\s+\(v\d+\.\d+'  # 5. filename.md (vX.Y  [paren form]
    r'|[a-z0-9][a-z0-9_-]*\.md\s+v\d+\.\d+'    # 6. filename.md vX.Y   [noparen form]
    r')'
)

# ── Load allowlist ────────────────────────────────────────────────────────────
# Allowlist: {relative_path: set(1-indexed line numbers)}
allowlist = {}
if os.path.isfile(allowlist_f):
    with open(allowlist_f, 'r', encoding='utf-8') as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith('#'):
                continue
            if ':' not in line:
                continue
            try:
                rel_path, lineno_str = line.rsplit(':', 1)
                lineno = int(lineno_str)
                allowlist.setdefault(rel_path, set()).add(lineno)
            except ValueError:
                pass   # malformed entry — ignore silently

# ── Collect markdown files ────────────────────────────────────────────────────
md_files = sorted(glob.glob(os.path.join(specs_root, '**', '*.md'), recursive=True))

for filepath in md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            raw_lines = fh.readlines()   # preserves \n
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    content = ''.join(raw_lines)

    # ── Locate frontmatter boundaries ─────────────────────────────────────
    # Split on '---' delimiters. We expect the file to optionally begin with
    # a YAML block enclosed in '---\n' ... '---\n'.
    # Strategy: find the line index of the first and second '---' lines.
    fm_end_line = None   # 0-indexed line index of the closing '---'
    if raw_lines and raw_lines[0].rstrip() == '---':
        for i in range(1, len(raw_lines)):
            if raw_lines[i].rstrip() == '---':
                fm_end_line = i
                break

    # fm_end_line == None means no frontmatter (or unclosed frontmatter —
    # treat as no frontmatter in either case).
    # Lines 0..fm_end_line (inclusive) are FRONTMATTER; skip them entirely.
    fm_end = fm_end_line if fm_end_line is not None else -1

    # ── Locate ## Changelog sections in body ──────────────────────────────
    # A ## Changelog section runs from the '## Changelog' heading line through
    # (but not including) the next '## ' heading line or EOF.
    # There may be multiple such sections per file (e.g., a versioned doc with
    # a primary ## Changelog and a supplementary one).
    CHANGELOG_HEADING_RE = re.compile(r'^## Changelog\s*$')
    SECTION_HEADING_RE   = re.compile(r'^## ')

    changelog_line_ranges = []   # list of (start_0idx, end_0idx_exclusive)
    i = fm_end + 1
    while i < len(raw_lines):
        if CHANGELOG_HEADING_RE.match(raw_lines[i]):
            start = i
            j = i + 1
            while j < len(raw_lines):
                if SECTION_HEADING_RE.match(raw_lines[j]):
                    break
                j += 1
            changelog_line_ranges.append((start, j))
            i = j
        else:
            i += 1

    def in_changelog(line_0idx):
        for (s, e) in changelog_line_ranges:
            if s <= line_0idx < e:
                return True
        return False

    # ── Compute relative path for allowlist lookup ─────────────────────────
    rel_path = os.path.relpath(filepath, specs_root)

    # ── Scan non-exempt body lines ─────────────────────────────────────────
    failures = []
    for line_0idx in range(fm_end + 1, len(raw_lines)):
        if in_changelog(line_0idx):
            continue

        line_text = raw_lines[line_0idx]
        matches = PIN_RE.findall(line_text)
        if not matches:
            continue

        # 1-indexed line number
        lineno = line_0idx + 1

        # Check allowlist
        allowed_lines = allowlist.get(rel_path, set())
        if lineno in allowed_lines:
            continue

        # Deduplicate matches on this line (same text may appear multiple times)
        seen = set()
        unique_matches = []
        for m in matches:
            # Normalise internal whitespace for dedup
            key = re.sub(r'\s+', ' ', m.strip())
            if key not in seen:
                seen.add(key)
                unique_matches.append(key)

        for m in unique_matches:
            failures.append(f"live-body-pin:line={lineno},text={m!r}")

    if failures:
        print(f"FAIL {filepath} {'; '.join(failures)}")
    else:
        print(f"PASS {filepath}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"
  filepath="${rest%% *}"
  detail="${rest#* }"
  # Strip leading FACTORY_DIR for readability
  short="${filepath#"$FACTORY_DIR"/}"

  case "$level" in
    PASS)
      emit PASS "$short"
      ;;
    FAIL)
      emit FAIL "$short — $detail"
      ;;
    SKIP)
      emit WARN "$short (skipped: $detail)"
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
echo "verify-no-version-pins: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
