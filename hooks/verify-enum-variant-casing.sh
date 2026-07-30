#!/usr/bin/env bash
# verify-enum-variant-casing.sh — pregolya factory-artifacts wrap guard (blocking validator #5)
#
# Detects SCREAMING_CASE enum variant references in spec files under
# .factory/specs/.  Direction B (ADR-010 v1.9) mandates PascalCase Rust
# variant identifiers — Category::Val, Category::Security, Component::Tmpl,
# etc.  SCREAMING_CASE forms (Category::VAL, Component::TMPL) are violations
# because clippy::upper_case_acronyms with -D warnings makes them compile
# errors and all Component:: variants are uniformly PascalCase per the
# BC-2.14.001 §Rendering Convention.
#
# DETECTION PATTERNS (two, as specified by ADR-010 v1.9 Direction B process gap F-P168-01):
#
#   Category::[A-Z][A-Z]   — any Category:: variant reference where the
#                             identifier starts with 2+ consecutive uppercase
#                             chars.  Catches: VAL, SECURITY, TOOL, TIMEOUT,
#                             INTERNAL, CONFIGURATION, VALIDATION, AUTH, etc.
#
#   Component::[A-Z][A-Z]  — any Component:: variant reference where the
#                             identifier starts with 2+ consecutive uppercase
#                             chars.  Catches: TMPL, SRLZ, EMBED, VS, CHKPT,
#                             CORE, etc.
#
# NOT violations:
#   Bare SCREAMING code-strings without the Category:: / Component:: prefix
#   (e.g. standalone `VAL`, `AUTH`, `TOOLS` used as documentation shorthand
#   or as taxonomy code-column values) are not flagged.  Only references that
#   include the Rust path prefix `Category::` or `Component::` are violations.
#
# SCAN SCOPE:
#   All .md files under .factory/specs/ (recursive) — covers architecture,
#   behavioral-contracts, verification-properties, prd-supplements, domain-spec,
#   prd.md, and product-brief.md.
#
# EXEMPTIONS — the following regions and lines are NOT scanned:
#
#   (a) YAML frontmatter block (all lines between the first and second '---'
#       delimiters, inclusive of the delimiter lines).  Frontmatter changelog
#       list entries are the primary location where historical SCREAMING forms
#       are cited as audit trail — e.g. "1.1 (...): Category::VAL → Category::Val".
#
#   (b) Body ## Changelog section (all lines from a "## Changelog" heading
#       through the next "## " heading or end of file).  These rows record
#       historical change state per TD-VSDD-091 ("pass-report changelogs"
#       exception) and must be able to cite the old form for audit continuity.
#
#   (c) Lines whose content contains any of these anti-pattern discussion
#       markers (exact substring match, case-sensitive except NON-CANONICAL):
#         "SCREAMING"      — lines explaining the SCREAMING_CASE anti-pattern
#         "non-canonical"  — lines labelling an old form as non-canonical
#         "NON-CANONICAL"  — uppercase variant of the above
#         "retract"        — lines retracting a prior decision
#         "was amended"    — lines describing a historical amendment
#         "Direction B"    — lines citing the ADR-010 v1.9 adjudication itself
#       Rationale: these lines must cite the old SCREAMING form to be
#       meaningful context (e.g. "Category::VAL is non-canonical; use Val").
#
#   (d) Lines listed in .factory/hooks/enum-variant-casing-allowlist.txt.
#       Format (one entry per non-comment line):
#         <path-relative-to-.factory/specs>:<1-indexed-line-number>
#       Each entry MUST be preceded by a reason comment:
#         # Reason: <explanation>
#         architectural/foo.md:42
#       Allowlist is optional — if the file does not exist it is silently
#       ignored (zero allowlist entries).
#
# KNOWN EXPECTED FAILURES (PO sweep F-P168-01 in-flight as of FIX-BURST-270
#   validation run; count decreases toward zero as sweep progresses):
#
#   OPEN (5 SS-23 BC files remaining — PO owns):
#     behavioral-contracts/ss-23/BC-2.23.002.md — Category::SECURITY + Category::TOOL
#     behavioral-contracts/ss-23/BC-2.23.003.md — Category::VAL + Category::TOOL
#     behavioral-contracts/ss-23/BC-2.23.004.md — Category::SECURITY + Category::TOOL ×2
#     behavioral-contracts/ss-23/BC-2.23.005.md — Category::TIMEOUT + Category::VAL
#     behavioral-contracts/ss-23/BC-2.23.006.md — Category::VAL ×3 + Category::SECURITY + Category::TOOL
#
#   ALREADY FIXED (PASS as of FIX-BURST-270 validation run):
#     All architecture/ and verification-properties/ files (architect sweep)
#     behavioral-contracts/ss-18/BC-2.18.001/004/005 (FIX-BURST-270 devops share)
#     behavioral-contracts/ss-19/BC-2.19.005/006 (PO sweep in-flight)
#     behavioral-contracts/ss-21/BC-2.21.002/003 (PO sweep in-flight)
#     behavioral-contracts/ss-22/BC-2.22.001     (PO sweep in-flight)
#     behavioral-contracts/ss-23/BC-2.23.001     (PO sweep in-flight)
#
#   Any FAIL from architecture/, verification-properties/, domain-spec/,
#   prd-supplements/, prd.md, or product-brief.md is UNEXPECTED — the
#   architect sweep (FIX-BURST-270) already fixed those trees; report as
#   regression or new content added without casing sweep.
#
# Usage:   bash .factory/hooks/verify-enum-variant-casing.sh
# Exit:    0 if no FAIL lines; 1 if any FAIL.
#
# Integration (state-manager burst protocol — blocking validator #5):
#   Add as a validation step before the atomic factory-artifacts commit:
#     bash .factory/hooks/verify-enum-variant-casing.sh

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPECS_ROOT="$FACTORY_DIR/specs"
ALLOWLIST="$FACTORY_DIR/hooks/enum-variant-casing-allowlist.txt"

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
# Produces one output line per .md file:
#   PASS <filepath>
#   FAIL <filepath> <finding1>; <finding2>; ...
#   SKIP <filepath> <reason>
#
# Each finding has the form:
#   screaming-variant:line=<N>,text=<matched-text>

PYTHON_OUTPUT="$(python3 - "$SPECS_ROOT" "$ALLOWLIST" <<'PYEOF'
import sys, os, glob, re

specs_root  = sys.argv[1]
allowlist_f = sys.argv[2]

# ── Detection regex ───────────────────────────────────────────────────────────
#
# Matches Category:: or Component:: followed by two or more consecutive
# uppercase letters (SCREAMING_CASE), capturing the full variant name up to
# the first non-identifier character.
#
# Category::VAL     → matches (V and A are uppercase)
# Category::SECURITY → matches (S and E are uppercase)
# Component::TMPL   → matches (T and M are uppercase)
# Component::VS     → matches (V and S are uppercase)
# Category::Val     → NO match (V uppercase, a lowercase — only 1 leading uppercase)
# Component::Tmpl   → NO match (T uppercase, m lowercase — only 1 leading uppercase)
#
# The trailing [A-Za-z0-9_]* captures the rest of the identifier so the full
# variant name is available for the diagnostic message.

VARIANT_RE = re.compile(r'(?:Category|Component)::[A-Z][A-Z][A-Za-z0-9_]*')

# ── Content exemption ─────────────────────────────────────────────────────────
#
# Lines discussing the anti-pattern or recording historical amendments must be
# able to cite the SCREAMING form as context.  Exempt any line that contains
# one of these marker strings.

EXEMPT_CONTENT_RE = re.compile(
    r'SCREAMING'
    r'|non-canonical'
    r'|NON-CANONICAL'
    r'|retract'
    r'|was amended'
    r'|Direction B'
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

CHANGELOG_HEADING_RE = re.compile(r'^## Changelog\s*$')
SECTION_HEADING_RE   = re.compile(r'^## ')

for filepath in md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            raw_lines = fh.readlines()   # preserves \n
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    # ── Locate frontmatter boundaries ─────────────────────────────────────
    # A valid frontmatter block starts with '---' on line 0 and ends at the
    # next '---' line.  All lines 0..fm_end (inclusive) are frontmatter.
    # fm_end == -1 means no frontmatter (scan starts at line 0).
    fm_end = -1
    if raw_lines and raw_lines[0].rstrip() == '---':
        for i in range(1, len(raw_lines)):
            if raw_lines[i].rstrip() == '---':
                fm_end = i
                break

    # ── Locate body ## Changelog sections ─────────────────────────────────
    # Each ## Changelog section runs from the heading line through (but not
    # including) the next ## heading or EOF.  Multiple such sections per file
    # are supported (e.g. versioned docs with more than one changelog block).
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
        # Exemption (b): skip ## Changelog sections
        if in_changelog(line_0idx):
            continue

        line_text = raw_lines[line_0idx]

        # Exemption (c): skip lines discussing the anti-pattern
        if EXEMPT_CONTENT_RE.search(line_text):
            continue

        matches = VARIANT_RE.findall(line_text)
        if not matches:
            continue

        # 1-indexed line number for human readers
        lineno = line_0idx + 1

        # Exemption (d): check allowlist
        allowed_lines = allowlist.get(rel_path, set())
        if lineno in allowed_lines:
            continue

        # Deduplicate matches on this line (same variant may appear twice)
        seen = set()
        unique_matches = []
        for m in matches:
            if m not in seen:
                seen.add(m)
                unique_matches.append(m)

        for m in unique_matches:
            failures.append(f"screaming-variant:line={lineno},text={m!r}")

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
echo "verify-enum-variant-casing: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
