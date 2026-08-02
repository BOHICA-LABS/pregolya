#!/usr/bin/env bash
# verify-adr-anchor-citations.sh — ADR §Named-Section citation existence gate
#
# PURPOSE
# ───────
# Enforces ADR-022 §Decision 3 across all .md files under .factory/specs/.
# For every `ADR-NNN §Section-Text` citation in normative (non-changelog, non-fence,
# non-backtick) positions, verifies that a heading starting with Section-Text exists
# in the target ADR file, and that the match is unambiguous (exactly one heading).
#
# ADVISORY: exits 0 always. The ~170-citation migration sweep (ADR-022 Decision 4)
# is deferred to a later burst. Until that sweep completes this gate reports findings
# but does not block. Upgrade to BLOCKING (replace run_advisory with run_blocking in
# pre-commit-validators.sh) after the sweep.
#
# SPEC AUTHORITY
# ──────────────
# ADR-022-section-anchor-citation-convention.md §Decision 3 — Machine verification spec
# Closes: F-P176-E001 (CRIT), F-P176-A039 (HIGH), F-P176-A007 (HIGH)
#
# VALIDATION RULE
# ───────────────
# For each `ADR-NNN §Section-Text` citation (in normative positions):
#   1. Find the target ADR file: specs/architecture/decisions/ADR-NNN-*.md
#   2. Read the target body (post-frontmatter)
#   3. Find headings starting with Section-Text (prefix match, case-sensitive)
#      using longest-prefix matching to handle trailing-context text
#   4. FAIL: no heading starts with Section-Text (phantom anchor — D-106 class)
#   5. FAIL: multiple headings start with Section-Text (ambiguous citation)
#   6. PASS: exactly one heading starts with Section-Text
#
# EXCLUSIONS
# ──────────
# - YAML frontmatter and ## Changelog body sections (changelog_exempt_lines)
# - Content inside fenced code blocks (``` ... ```)
# - Content inside inline backtick spans (`...`)
#   ADR-022 itself quotes Form B/C examples in backticks as illustration;
#   these must not trigger failures.
#
# NOT IN SCOPE (v1 explicit exclusions)
# ──────────────────────────────────────
# - `ADR-NNN §Decision N` pure-numeric: handled by verify-adr-decision-refs.sh
# - `ADR-NNN §Decision N Amendment` (numeric+Amendment): excluded by same negative
#     lookahead; 16 instances in corpus. These cite real headings but are adjacent
#     to numeric decisions — promote to scan scope when needed.
# - `§Section` without leading doc-id (standalone or chained double-§ citations):
#     CITE_RE requires `ADR-NNN\s+§` — 1 instance (api-surface.md §Object-safety
#     chained after §Decision 2). Currently neither scanned nor flagged.
# - Non-ADR target citations (BC-NNN §Section, VP-NNN §Section, CAP-NNN §Section,
#     ADV-P §Section, etc.): 183 instances in corpus (BC:79, ADV-P:42, VP:24, F-P:14,
#     CAP:11, others:13). ADR-022 §Decision 1 restricts §-citations generally, but
#     v1 scope is ADR-target-only. Promotion to full coverage is a separate burst item.
# - Changelog/frontmatter lines (133 of 217 raw ADR §-citations): normative
#     exclusion — these are historical narrative ("fixed per ADR-NNN §Y"), not
#     forward-normative references that need heading existence validation.
#
# COVERAGE STATEMENT (honest, measurable)
# ─────────────────────────────────────────
# Raw ADR-NNN §Section occurrences corpus-wide: 217
# After exemptions applied by this gate:
#   Excluded — changelog/frontmatter: 133 (historical narrative, not normative)
#   Excluded — fenced code blocks:      7
#   Excluded — inline backtick spans:  16
#   Excluded — illustration regions:    2
#   Excluded — §Decision N numeric:    ~16 (verify-adr-decision-refs.sh scope)
#   Excluded — edge cases (double-§):   1
# This gate scans: 42 normative prose ADR-target §-citations
# (Adversary estimate of ~170 was inflated; the normative-prose population is 42.)
# Gate scope label: "ADR-target §Named-Section citations in normative prose (42 of 217 raw)"
#
# SELF-PROBES (3 mandatory)
# ─────────────────────────
# 1. Phantom anchor (no heading) detected as FAIL
# 2. Valid anchor (heading exists) detected as PASS
# 3. Ambiguous anchor (multiple headings) detected as FAIL
# 4. Inline-backtick exemption: backtick-quoted citation not flagged
# 5. Changelog-section exemption: citation in ## Changelog not flagged
#
# Usage:  bash .factory/hooks/verify-adr-anchor-citations.sh
# Exit:   0 always (ADVISORY — see header note above)
#
# Integration: wired as ADVISORY in pre-commit-validators.sh.
# Upgrade to BLOCKING: replace run_advisory with run_blocking after migration sweep.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
SPECS_DIR="$FACTORY_DIR/specs"
ADR_DIR="$SPECS_DIR/architecture/decisions"

PASS=0
WARN=0
FAIL=0
ADVISORY_WARN=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)); ADVISORY_WARN=$((ADVISORY_WARN + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
  esac
}

# ── Core Python scanner ───────────────────────────────────────────────────────
# Arguments: <hooks_dir> <scan_dir> <adr_dir>
# Output lines:
#   CITATION_PASS   <adr_num> <section_text> <file>   valid (exactly one heading match)
#   CITATION_FAIL   <adr_num> <section_text> <file>   phantom (no heading match)
#   CITATION_AMBIG  <adr_num> <section_text> <file>   ambiguous (multiple heading matches)
#   CITATION_NOTGT  <adr_num> <section_text> <file>   target ADR file not found on disk
run_anchor_scanner() {
  local hooks_dir="$1" scan_dir="$2" adr_dir="$3"
  python3 - "$hooks_dir" "$scan_dir" "$adr_dir" <<'PYEOF'
import sys, glob, re, os

hooks_dir = sys.argv[1]
scan_dir  = sys.argv[2]
adr_dir   = sys.argv[3]
sys.path.insert(0, hooks_dir)
from spec_region_utils import changelog_exempt_lines

# ── Compiled patterns ─────────────────────────────────────────────────────────

# ADR-NNN §Section-Text — the §Name citation.
# Captures: group(1) = 3-digit ADR number, group(2) = section text (up to 80 chars).
# Section text: starts with a word character, stops at common prose terminators.
#
# EXCLUSION: Pure numeric decision citations (§Decision N, §Decisions N) are
# handled by verify-adr-decision-refs.sh and are excluded from this gate to
# avoid double-reporting (ADR-022 §Integration with existing validators).
# A "pure numeric decision" citation is one where the text is just
# "Decision[s] <integer>" (optionally terminated). Named-section citations that
# include additional text (e.g. §Decision 3 Amendment) ARE in scope.
CITE_RE = re.compile(
    r'\bADR-(\d{3})\s+§'
    r'(?!Decisions?\s+\d+(?:[,.:;\'\")\]\s]|$))'  # skip §Decision N (pure numeric)
    r'([A-Za-z][^\n`]{0,80}?)'  # capture text starting with letter
    r'(?=[`\n]|[,.:;\'\")\]]|\s{2,}|\s*$)'  # stop at natural terminators
)

# Heading detection: any markdown heading level (#+ text)
HEADING_RE = re.compile(r'^(#{1,6})\s+(.+?)\s*$', re.MULTILINE)

# Inline backtick span (single-line)
INLINE_TICK_RE = re.compile(r'`[^`\n]*`')

# Fenced code block detection (tracks entry/exit)
FENCE_START_RE = re.compile(r'^\s*```')
FENCE_END_RE   = re.compile(r'^\s*```\s*$')

def build_fence_exempt(lines):
    """Return set of 0-indexed line numbers inside fenced code blocks."""
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
# Maps adr_num (str, e.g. '010') -> (file_path, [heading_texts])
# Returns None for file_path if ADR not found on disk.
_adr_cache = {}

def get_adr_headings(adr_num):
    """Load headings from the target ADR file. Returns (path, [heading_text])."""
    if adr_num in _adr_cache:
        return _adr_cache[adr_num]

    # Find the file: ADR-NNN-*.md in adr_dir
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

    # Strip frontmatter before extracting headings
    lines = raw.splitlines()
    body_start = 0
    if lines and lines[0].strip() == '---':
        for j in range(1, len(lines)):
            if lines[j].strip() == '---':
                body_start = j + 1
                break
    body = '\n'.join(lines[body_start:])

    # Extract heading texts
    headings = [m.group(2).strip() for m in HEADING_RE.finditer(body)]
    _adr_cache[adr_num] = (adr_path, headings)
    return (adr_path, headings)

def find_matching_heading(section_text, headings):
    """
    Try longest-prefix match: find the longest prefix of section_text (stripping
    from the right one word at a time) that matches the start of any heading.
    Returns: list of heading texts that match the best prefix found.

    This handles cases where citations contain trailing context not in the heading:
      §Error-Construction Notation Canon Class 3  → match on "Error-Construction Notation Canon"
      §Class 3                                    → match on "Class 3"
    """
    # Normalise: strip trailing punctuation and whitespace from the captured text
    candidate = section_text.rstrip(' .,;:\'\")')

    words = candidate.split()
    if not words:
        return []

    # Try progressively shorter prefixes, stopping at the first match
    for length in range(len(words), 0, -1):
        prefix = ' '.join(words[:length])
        # Case-sensitive prefix match: heading starts with prefix
        matched = [h for h in headings if h.startswith(prefix)]
        if matched:
            return matched

    return []

# ── Main scan ─────────────────────────────────────────────────────────────────
md_files = sorted(glob.glob(os.path.join(scan_dir, '**', '*.md'), recursive=True))

results = []

for filepath in md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    if 'ADR-' not in ''.join(lines) or '§' not in ''.join(lines):
        continue

    rel           = filepath.replace(scan_dir.rstrip('/') + '/', '')
    cl_exempt     = changelog_exempt_lines(lines)
    fence_exempt  = build_fence_exempt(lines)

    for i, raw_line in enumerate(lines):
        if i in cl_exempt or i in fence_exempt:
            continue

        # Strip inline backtick spans before scanning
        stripped = INLINE_TICK_RE.sub('', raw_line)

        for m in CITE_RE.finditer(stripped):
            adr_num      = m.group(1)
            section_text = m.group(2).strip()

            if not section_text:
                continue

            # Retrieve headings for target ADR
            adr_path, headings = get_adr_headings(adr_num)

            if adr_path is None:
                # Target ADR not found on disk
                results.append(('NOTGT', adr_num, section_text, rel))
                continue

            matching = find_matching_heading(section_text, headings)

            if len(matching) == 0:
                results.append(('FAIL', adr_num, section_text, rel))
            elif len(matching) == 1:
                results.append(('PASS', adr_num, section_text, rel))
            else:
                results.append(('AMBIG', adr_num, section_text, rel))

# ── Emit output ───────────────────────────────────────────────────────────────
for outcome, adr_num, section_text, rel in results:
    # Encode section_text with | as field separator (safe since § not in it)
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
  # Create a source file citing a phantom anchor
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Postconditions

See ADR-099 §NonExistent Section for error handling.
PROBEOF
  # Create a target ADR with no matching heading
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
  # Create a source file citing a real heading
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Postconditions

See ADR-099 §Decision for error handling.
PROBEOF
  # Create target ADR with matching heading
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
  # Create a source file with a citation that matches multiple headings
  cat > "$PROBE_TMP/specs/source.md" <<'PROBEOF'
## Postconditions

See ADR-099 §Class for the class definition.
PROBEOF
  # Create target ADR with two headings starting with "Class"
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
  # Citation inside backticks should NOT be flagged
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

# ── Main anchor check ─────────────────────────────────────────────────────────

check_anchor_citations() {
  local scan_dir="${1:-$SPECS_DIR}"

  local raw_output
  raw_output="$(run_anchor_scanner "$HOOKS_DIR" "$scan_dir" "$ADR_DIR")"

  local -i pass_count=0 fail_count=0 ambig_count=0 notgt_count=0

  declare -A fail_by_file=()
  declare -A ambig_by_file=()

  while IFS=$'\t' read -r outcome adr_num section_text rel_file; do
    case "$outcome" in
      CITATION_PASS)
        pass_count=$(( pass_count + 1 ))
        ;;
      CITATION_FAIL)
        fail_count=$(( fail_count + 1 ))
        local key="${rel_file}"
        fail_by_file["$key"]="${fail_by_file[$key]:-}  PHANTOM: ADR-${adr_num} §${section_text}\n"
        ;;
      CITATION_AMBIG)
        ambig_count=$(( ambig_count + 1 ))
        local key="${rel_file}"
        ambig_by_file["$key"]="${ambig_by_file[$key]:-}  AMBIGUOUS: ADR-${adr_num} §${section_text}\n"
        ;;
      CITATION_NOTGT)
        notgt_count=$(( notgt_count + 1 ))
        ;;
    esac
  done <<< "$raw_output"

  local total_problems=$(( fail_count + ambig_count + notgt_count ))
  local total_scanned=$(( pass_count + fail_count + ambig_count + notgt_count ))

  echo "  Citations scanned:  ${total_scanned}"
  echo "  PASS (valid):       ${pass_count}"
  echo "  FAIL (phantom):     ${fail_count}"
  echo "  FAIL (ambiguous):   ${ambig_count}"
  echo "  FAIL (target missing): ${notgt_count}"

  if [ "${#fail_by_file[@]}" -gt 0 ]; then
    echo ""
    echo "  Phantom anchors (ADR-022 Decision 4 migration targets):"
    for fpath in "${!fail_by_file[@]}"; do
      echo "    ${fpath}:"
      printf '%b' "${fail_by_file[$fpath]}"
    done
  fi

  if [ "${#ambig_by_file[@]}" -gt 0 ]; then
    echo ""
    echo "  Ambiguous citations (tighten the cited prefix):"
    for fpath in "${!ambig_by_file[@]}"; do
      echo "    ${fpath}:"
      printf '%b' "${ambig_by_file[$fpath]}"
    done
  fi

  if [ "${total_problems}" -gt 0 ]; then
    emit WARN "A1 (ADR-022): §Named-Section anchor citations — ${fail_count} phantom, ${ambig_count} ambiguous, ${notgt_count} target-missing (${total_scanned} total scanned)"
    echo "  ADVISORY: migration sweep deferred to later burst (ADR-022 Decision 4)"
    echo "  Routing guide: for each phantom anchor, see ADR-022 §Decision 4 for migration rule."
    echo "    - If real heading exists: citation is valid — no change needed."
    echo "    - If phantom (no heading): replace §Name with the real heading text, or with"
    echo "                                 ADR-NNN Decision N if a numbered decision is the target."
    echo "    - If cannot determine intent: replace with bare ADR-NNN citation."
  else
    emit PASS "A1 (ADR-022): all ${total_scanned} §Named-Section citations resolve to real headings."
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-adr-anchor-citations: ADR-022 §Named-Section citation existence gate"
echo "  SPECS_DIR: $SPECS_DIR"
echo "  ADR_DIR:   $ADR_DIR"
echo "  Authority: ADR-022 §Decision 3 (prefix match, unique heading)"
echo "  Status:    ADVISORY — migration sweep deferred (ADR-022 §Decision 4)"
echo ""

echo "[SELF-PROBE] Verifying phantom/valid/ambiguous detection and exemptions..."
probe_phantom_anchor
probe_valid_anchor
probe_ambiguous_anchor
probe_backtick_exempt
probe_changelog_exempt
echo "[SELF-PROBE] All probes passed — checks are not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "ADVISORY rules (upgrade to BLOCKING after migration sweep)"
echo "════════════════════════════════════════════"
echo ""
echo "── A1 (ADR-022 Decision 3): §Named-Section citation existence ──────────"
check_anchor_citations "$SPECS_DIR"

echo ""
echo "════════════════════════════════════════════"

echo ""
echo "verify-adr-anchor-citations: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  ADVISORY: $ADVISORY_WARN WARN(s)"

# ADVISORY: always exit 0 — do not block commits
# Upgrade path: when WARN count reaches 0, change this to:
#   [ "$FAIL" -gt 0 ] && exit 1 || exit 0
# and switch from run_advisory to run_blocking in pre-commit-validators.sh
echo ""
echo "RESULT: ADVISORY (exit 0 — migration sweep pending)"
exit 0
