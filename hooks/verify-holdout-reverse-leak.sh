#!/usr/bin/env bash
# verify-holdout-reverse-leak.sh — spec/story corpus holdout-ID reverse-leak gate (BLOCKING)
#
# PURPOSE
# ───────
# Enforces holdout information asymmetry in the REVERSE direction: the spec and
# story corpus (.factory/specs/**/*.md, .factory/stories/**/*.md) must NOT
# reference sealed holdout scenario IDs matching the pattern HS-[A-Z]-[0-9]+.
#
# BACKGROUND — WHY THE REVERSE DIRECTION MATTERS
# ────────────────────────────────────────────────
# verify-holdout-asymmetry.sh guards the FORWARD direction: evaluator-facing
# sections in HS-*.md files must not contain internal spec identifiers (BC IDs,
# VP IDs, error codes) that would leak implementation details to evaluators.
#
# The REVERSE direction is equally critical: if a spec, ADR, or BC body names a
# sealed holdout by ID and co-locates that citation with description of the
# scenario's expected solution structure, implementers can "teach to the test"
# and target their code specifically at the holdout rather than implementing the
# general capability.  This corrupts the holdout evaluation's independence.
#
# FINDING CLASS
# ─────────────
# F-P2A217-02 (round-52 STAGE-A): the holdout information-asymmetry gate is
# UNIDIRECTIONAL.  verify-holdout-asymmetry.sh scans HS-*.md files for leaked
# internal identifiers but does NOT scan specs/stories for references to sealed
# holdout IDs.  ADR-030 §Decision 1 was found citing "used in HS-D-002" and
# describing its anonymization-transform solution — invisible to the existing gate.
#
# SCAN TARGETS
# ────────────
# .factory/specs/**/*.md
# .factory/stories/**/*.md
#
# The holdout-scenarios/ directory itself is NOT scanned — it may legitimately
# carry HS-IDs by definition.
#
# HOLDOUT ID PATTERN
# ──────────────────
# HS-[A-Z]-[0-9]+   (e.g., HS-C-001, HS-D-002)
#
# EXEMPT REGIONS (not scanned)
# ─────────────────────────────
# The following regions legitimately carry HS-IDs as historical provenance records
# and cannot be purged without rewriting project history:
#
#   YAML frontmatter (the entire --- ... --- block at top of file)
#       Rationale: frontmatter changelog: list items are immutable historical records
#       of when a spec was driven by a holdout gap.  They do not expose solution
#       structure to implementers reading the body text.
#
#   ## Changelog sections (the entire ## Changelog section body)
#       Rationale: changelog table rows record WHAT changed and WHY; HS-ID references
#       in changelogs document historical provenance, not solution disclosure.  Purging
#       them would require rewriting project history.
#
# FAIL-CLOSED RATIONALE
# ─────────────────────
# The default is FAIL: any HS-ID outside the two exempt regions is a potential
# information-asymmetry violation.  A reference in normative prose (scenario
# motivation, decision rationale, source/origin sections, table cells) either:
#   (a) names the holdout scenario by ID, revealing to implementers which capability
#       the holdout tests, or
#   (b) directly describes solution structure for the named holdout scenario.
# Both (a) and (b) are disqualifying — the holdout identity itself is sealed
# (sealed holdouts must not be named in builder-visible artifacts at all per VSDD
# §Information Asymmetry).  The fact that prior adversarial passes accepted some
# ADR-029 HS-C-001 provenance references does NOT make them correct; this gate
# closes the gap retroactively.
#
# ALLOWLIST MECHANISM
# ───────────────────
# If a reference is genuinely necessary in normative body text and has been
# explicitly human-reviewed, add it to:
#   .factory/hooks/holdout-reverse-leak-allowlist.txt
# Each line must be in the format:
#   FILE_BASENAME:LINE_NUMBER  # REASON: <why this is an accepted exception>
# (e.g., ADR-029-graph-agent-tool-wrapping.md:60  # REASON: ...)
# Lines starting with # are comments.  The allowlist is checked after scanning;
# flagged hits that appear in the allowlist are suppressed from FAIL output but
# still reported as [ALLOW] for visibility.
#
# SELF-PROBE (POL-31)
# ───────────────────
#   probe_hrl1_negative_normative_prose:    HS-D-002 in normative § with solution desc → FAIL
#   probe_hrl2_positive_clean_spec:         spec with no HS-ID at all → PASS
#   probe_hrl3_changelog_section_exempt:    HS-C-001 ONLY in ## Changelog section → PASS
#   probe_hrl4_yaml_frontmatter_exempt:     HS-C-001 ONLY in YAML frontmatter → PASS
#
# EXIT CONTRACT
# ─────────────
# Exit 0: no FAIL hits (after allowlist suppression)
# Exit 1: one or more FAIL hits (BLOCKING)
# Exit 2: self-probe failure (script bug — a check is false-green or false-red)
#
# PRE-EXISTING VIOLATIONS (at gate creation, round-52)
# ─────────────────────────────────────────────────────
# The following live-corpus hits are BLOCKING and require architect remediation:
#   ADR-030-research-orchestrator-composition.md — §Decision 1 table cell:
#       "the realizable pattern (used in HS-D-002) is a standard node function..."
#   ADR-029-graph-agent-tool-wrapping.md — Problem context paragraph:
#       "HS-C-001: a host application that embeds a Pregolya agent..."
#   ADR-029-graph-agent-tool-wrapping.md — §Source / Origin section:
#       "Human-approved v1 scope addition (GAP-01, 2026-08-26) — HS-C-001 Flowloom..."
# Routing: architect (ADR body section text — Problem context, §Source/Origin, §Decision table)
#
# Usage:  bash .factory/hooks/verify-holdout-reverse-leak.sh
# Called: run_blocking in pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
SPECS_DIR="$FACTORY_DIR/specs"
STORIES_DIR="$FACTORY_DIR/stories"
ALLOWLIST="$HOOKS_DIR/holdout-reverse-leak-allowlist.txt"

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

# ── Core Python scanner ───────────────────────────────────────────────────────
# Arguments: <search_dir> [<search_dir2> ...]
# Output lines:
#   HIT <relpath>:<lineno> matched="<token>" | <snippet>
#   SCAN_FILES <n>
#   TOTAL <n>
run_reverse_leak_scanner() {
  python3 - "$@" <<'PYEOF'
import sys, re
from pathlib import Path

search_dirs = [Path(d) for d in sys.argv[1:] if Path(d).is_dir()]

# ─────────────────────────────────────────────────────────────────────────────
# HOLDOUT ID PATTERN
# ─────────────────────────────────────────────────────────────────────────────

HS_ID_RE = re.compile(r'\bHS-[A-Z]-[0-9]+\b')

# ─────────────────────────────────────────────────────────────────────────────
# SECTION CLASSIFIER
# Only "## Changelog" sections are exempt from scanning.
# All other sections (Background, Problem, Decision N, Source/Origin, etc.) are
# SCANNED — any HS-ID found outside exempt regions is a FAIL.
# ─────────────────────────────────────────────────────────────────────────────

MD_H2_RE = re.compile(r'^##\s+(.+)$')

EXEMPT_HEADING_PREFIXES = (
    "changelog",   # ## Changelog — historical provenance records
)

def is_exempt_heading(heading_text: str) -> bool:
    norm = heading_text.strip().lower()
    for prefix in EXEMPT_HEADING_PREFIXES:
        if norm == prefix or norm.startswith(prefix + " ") or norm.startswith(prefix + ":"):
            return True
    return False


def scan_file(path: Path, base_dir: Path) -> list:
    """Return list of (relpath, lineno, matched_token, snippet) for HS-ID hits
    outside exempt regions (YAML frontmatter and ## Changelog sections)."""
    try:
        raw = path.read_text(encoding='utf-8', errors='replace')
    except Exception:
        return []

    rel = str(path.relative_to(base_dir))
    lines = raw.splitlines()
    findings = []

    in_yaml_front = False
    yaml_ended = False
    in_exempt_section = False  # inside a ## Changelog section

    for lineno, line in enumerate(lines, 1):
        stripped = line.strip()

        # ── YAML frontmatter boundaries ──────────────────────────────────────
        if lineno == 1 and stripped == '---':
            in_yaml_front = True
            continue
        if in_yaml_front and not yaml_ended:
            if stripped == '---':
                in_yaml_front = False
                yaml_ended = True
            # Skip all YAML frontmatter lines (including changelog: list items)
            continue

        # ── Section tracking via ## headings ─────────────────────────────────
        m = MD_H2_RE.match(stripped)
        if m:
            heading_text = m.group(1)
            in_exempt_section = is_exempt_heading(heading_text)
            continue

        # ── Skip exempt sections ─────────────────────────────────────────────
        if in_exempt_section:
            continue

        # ── Scan for HS-IDs in all other lines ───────────────────────────────
        for hit in HS_ID_RE.finditer(line):
            findings.append((
                rel,
                lineno,
                hit.group(0),
                line.rstrip()[:140],
            ))

    return findings


# ── Scan all .md files under each search dir ─────────────────────────────────

total_findings = 0
scan_files_count = 0
all_results = []  # list of (relpath, lineno, token, snippet)

for search_dir in search_dirs:
    for p in sorted(search_dir.rglob('*.md')):
        # Skip any holdout-scenarios directory that might be nested
        if 'holdout-scenarios' in p.parts:
            continue
        scan_files_count += 1
        hits = scan_file(p, search_dir.parent)
        if hits:
            all_results.extend(hits)
            total_findings += len(hits)

# ── Emit output ───────────────────────────────────────────────────────────────
for relpath, lineno, matched, snippet in all_results:
    print(f'HIT {relpath}:{lineno} matched="{matched}" | {snippet}')

print(f'SCAN_FILES {scan_files_count}')
print(f'TOTAL {total_findings}')
PYEOF
}

# ── Load allowlist entries ────────────────────────────────────────────────────
# Returns 0 (true) if a "FILE:LINE" key is in the allowlist.
is_allowlisted() {
  local key="$1"  # format: "BASENAME:LINENO"
  if [ ! -f "$ALLOWLIST" ]; then
    return 1
  fi
  # Strip comments and blank lines; check for exact key match in the key part
  # (before any whitespace/comment)
  while IFS= read -r al_line; do
    # Skip comment and blank lines
    [[ "$al_line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${al_line// }" ]] && continue
    # Extract the key (first whitespace-delimited token)
    al_key="${al_line%%[[:space:]]*}"
    if [ "$al_key" = "$key" ]; then
      return 0
    fi
  done < "$ALLOWLIST"
  return 1
}

# ── Self-probe infrastructure ─────────────────────────────────────────────────
PROBE_TMP=""

init_probe_tmp() {
  PROBE_TMP="$(mktemp -d)"
}

clean_probe_tmp() {
  [ -n "$PROBE_TMP" ] && [ -d "$PROBE_TMP" ] && rm -rf "$PROBE_TMP"
  PROBE_TMP=""
}

run_probe_scan() {
  local probe_dir="$1"
  run_reverse_leak_scanner "$probe_dir" | grep '^HIT' || true
}

# ── Self-probe hrl1: HS-ID in normative prose MUST be flagged ─────────────────
# A synthetic spec file citing HS-D-002 in a §Decision section that also
# describes solution structure must produce a HIT.
probe_hrl1_negative_normative_prose() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs"
  cat > "$PROBE_TMP/specs/ADR-PROBE.md" <<'SPECEOF'
---
document_type: adr
version: "1.0"
---

## Decision 1 — Author-Metadata Stripping on Panel Topology

| Pattern element | Mapped primitive |
|-----------------|-----------------|
| **Author-metadata stripping** — project-state fan-out | The realizable pattern (used in HS-D-002) is a standard node function that reads the full state and returns a projected subset |

This pattern avoids per-node channel-visibility-scoping primitives.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/specs")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_hrl1_negative_normative_prose: HS-D-002 in §Decision prose was NOT flagged."
    echo "  Expected a HIT line for the HS-D-002 reference in the Decision table."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'HS-D-002'; then
    echo "[SELF-PROBE FAIL] probe_hrl1_negative_normative_prose: no HIT for HS-D-002."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hrl1_negative_normative_prose: HS-D-002 in §Decision prose is detected."
}

# ── Self-probe hrl2: clean spec with no HS-ID MUST produce no hits ────────────
probe_hrl2_positive_clean_spec() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs"
  cat > "$PROBE_TMP/specs/ADR-PROBE.md" <<'SPECEOF'
---
document_type: adr
version: "1.0"
---

## Decision 1 — Use-Case Composition on Existing Primitives

The research orchestrator pattern is fully expressible on the current pregolya API surface.
Author-metadata stripping is implemented as an explicit transform node that projects the
state map — no per-node channel-visibility-scoping primitive exists in the pregolya API;
the realizable pattern is a standard node function that reads the full state and returns
a projected subset.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2026-08-31 | architect | Initial version. |
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/specs")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_hrl2_positive_clean_spec: clean spec (no HS-ID) was incorrectly flagged."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hrl2_positive_clean_spec: clean spec with no HS-ID produces no HIT."
}

# ── Self-probe hrl3: HS-ID ONLY in ## Changelog MUST NOT be flagged ──────────
probe_hrl3_changelog_section_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs"
  cat > "$PROBE_TMP/specs/ADR-PROBE.md" <<'SPECEOF'
---
document_type: adr
version: "1.0"
---

## Decision 1 — GraphAgentTool Wrapping Contract

GraphAgentTool wraps a CompiledStateGraph for exposure as an MCP tool. The gap that
motivated this decision was that no prior BC specified how a StateGraph becomes a
registered tool in the ToolRegistry.

## Changelog

| Version | Date | Author | Ref | Summary |
|---------|------|--------|-----|---------|
| 1.0 | 2026-08-26 | architect | GAP-01/HS-C-001 | Initial ADR. Human-approved v1 scope addition driven by Flowloom-embedding holdout. |
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/specs")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_hrl3_changelog_section_exempt: HS-C-001 in ## Changelog was incorrectly flagged."
    echo "  ## Changelog sections are an exempt historical-provenance region — must produce no HIT."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hrl3_changelog_section_exempt: HS-C-001 in ## Changelog section produces no HIT."
}

# ── Self-probe hrl4: HS-ID ONLY in YAML frontmatter MUST NOT be flagged ──────
probe_hrl4_yaml_frontmatter_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/specs"
  cat > "$PROBE_TMP/specs/BC-PROBE.md" <<'SPECEOF'
---
document_type: behavioral-contract
bc_id: BC-2.09.008
version: "1.0"
changelog:
  - "1.0 (GAP-01/ADR-029/2026-08-26): Initial — StateGraph-as-MCP-Tool wrapping contract;
     Human-approved v1 scope addition 2026-08-26 (GAP-01/HS-C-001)."
---

## Description

GraphAgentTool exposes a CompiledStateGraph as an MCP tool. The tool wraps
a StateGraph and handles interrupt-denied fail-closed behavior.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/specs")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_hrl4_yaml_frontmatter_exempt: HS-C-001 in YAML frontmatter was incorrectly flagged."
    echo "  YAML frontmatter is an exempt region — must produce no HIT."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hrl4_yaml_frontmatter_exempt: HS-C-001 in YAML frontmatter produces no HIT."
}

# ── Main live check ───────────────────────────────────────────────────────────
check_reverse_leak() {
  local scan_dirs=()
  [ -d "$SPECS_DIR" ] && scan_dirs+=("$SPECS_DIR")
  [ -d "$STORIES_DIR" ] && scan_dirs+=("$STORIES_DIR")

  if [ "${#scan_dirs[@]}" -eq 0 ]; then
    emit PASS "holdout-reverse-leak: neither specs/ nor stories/ found — no files to scan"
    return
  fi

  local raw_output
  raw_output="$(run_reverse_leak_scanner "${scan_dirs[@]}")"

  local scan_files=0
  local total=0
  local hit_lines=()

  while IFS= read -r line; do
    case "$line" in
      HIT\ *)        hit_lines+=("${line#HIT }") ;;
      SCAN_FILES\ *) scan_files="${line#SCAN_FILES }" ;;
      TOTAL\ *)      total="${line#TOTAL }" ;;
    esac
  done <<< "$raw_output"

  echo "  Scanned: ${scan_files} .md files under specs/ and stories/"
  echo "  Exempt:  YAML frontmatter, ## Changelog sections"
  echo "  Pattern: HS-[A-Z]-[0-9]+ (sealed holdout scenario IDs)"
  echo ""

  if [ "${#hit_lines[@]}" -eq 0 ]; then
    emit PASS "holdout-reverse-leak: ZERO sealed holdout ID references in spec/story corpus"
    return
  fi

  # Check each hit against the allowlist
  local fail_hits=()
  local allow_hits=()

  for entry in "${hit_lines[@]}"; do
    # entry format: "relpath:lineno matched="token" | snippet"
    # Extract "BASENAME:LINENO" for allowlist lookup
    local relpath_line
    relpath_line="${entry%% *}"  # everything before first space
    local basename_line
    basename_line="$(basename "${relpath_line%%:*}"):${relpath_line##*:}"

    if is_allowlisted "$basename_line"; then
      allow_hits+=("$entry")
    else
      fail_hits+=("$entry")
    fi
  done

  if [ "${#allow_hits[@]}" -gt 0 ]; then
    echo "  Allowlisted (suppressed — explicitly reviewed):"
    for entry in "${allow_hits[@]}"; do
      echo "    [ALLOW] $entry"
    done
    echo ""
  fi

  if [ "${#fail_hits[@]}" -eq 0 ]; then
    emit PASS "holdout-reverse-leak: all hits are allowlisted; ZERO unreviewed HS-ID references"
    return
  fi

  echo "  Sealed holdout IDs found in spec/story body text (outside exempt regions):"
  echo "  (These reference sealed scenarios by ID — replace with non-identifying language)"
  echo ""
  for entry in "${fail_hits[@]}"; do
    emit FAIL "holdout-reverse-leak: $entry"
  done
  echo ""
  echo "  Fix guidance:"
  echo "    In normative prose / decision tables / source-origin sections:"
  echo "      Replace 'HS-X-NNN' with non-identifying language describing the capability gap"
  echo "      that motivated the decision, without naming the holdout scenario."
  echo "      Example: 'used in HS-D-002' → 'used in the research-orchestrator composition pattern'"
  echo "      Example: 'HS-C-001: a host application...' → 'A host application that embeds a'"
  echo "               'Pregolya agent and exposes it as an MCP tool has no first-class contract.'"
  echo "      Example: '— HS-C-001 Flowloom-embedding holdout surfaced the gap' →  remove the"
  echo "               HS-ID citation; retain the capability-gap description in plain terms."
  echo "  If a reference is genuinely required as provenance and has been human-reviewed:"
  echo "    Add to .factory/hooks/holdout-reverse-leak-allowlist.txt with a reason comment."
  echo "  Routing: architect (ADR body section text)"
  echo "  Reference: F-P2A217-02 (round-52 STAGE-A); VSDD §Information Asymmetry"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-holdout-reverse-leak: spec/story corpus sealed holdout-ID reverse-leak gate (BLOCKING)"
echo "  Specs:    $SPECS_DIR"
echo "  Stories:  $STORIES_DIR"
echo "  Finding:  F-P2A217-02 — specs/stories must not name sealed holdout IDs in body text"
echo "  Allowlist: $ALLOWLIST ($([ -f "$ALLOWLIST" ] && wc -l < "$ALLOWLIST" | tr -d ' ' || echo "absent") entries)"
echo ""

echo "[SELF-PROBE] Verifying check catches HS-IDs and respects all exemptions (POL-31)..."
probe_hrl1_negative_normative_prose
probe_hrl2_positive_clean_spec
probe_hrl3_changelog_section_exempt
probe_hrl4_yaml_frontmatter_exempt
echo "[SELF-PROBE] All 4 self-probes passed — check is not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "BLOCKING check (exit 1 on FAIL)"
echo "════════════════════════════════════════════"
echo ""
echo "── holdout reverse-leak scan ───────────────────────────────────────────"
check_reverse_leak

echo ""
echo "════════════════════════════════════════════"
echo ""
echo "verify-holdout-reverse-leak: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "  BLOCKING: $FAIL FAIL(s) — sealed holdout IDs in spec/story body text"
  echo "  Routing: architect (ADR body section text)"
  echo "  Gate reference: F-P2A217-02 (round-52 STAGE-A)"
  echo ""
  echo "RESULT: FAIL (exit 1)"
  exit 1
fi

echo ""
echo "RESULT: PASS (exit 0)"
exit 0
