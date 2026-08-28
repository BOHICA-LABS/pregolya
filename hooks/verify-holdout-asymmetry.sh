#!/usr/bin/env bash
# verify-holdout-asymmetry.sh — HS-*.md evaluator-facing section internal-identifier gate (ADVISORY)
#
# PURPOSE
# ───────
# Enforces holdout scenario information asymmetry: evaluator-facing sections in
# HS-*.md files must be free of internal implementation identifiers (BC IDs, BC
# clause tags, VP IDs, error codes, internal module paths).  When an evaluator reads
# §Scenario, §Verification Approach, §Evaluation Rubric, §Failure Guidance, or
# §Edge Conditions, they must see only observable behavioral language — not internal
# traceability tokens that reveal implementation details and violate information
# asymmetry (Phase 4 guard per VSDD §Information Asymmetry).
#
# FINDING CLASS
# ─────────────
# F-P2A105-03 / GAP-R24 process-gap: round-23 scrub of HS-C-001 §Failure Guidance
# was incomplete because no gate verified that EVALUATOR-FACING sections are free
# of internal identifiers.  The same gap exists in any HS-*.md file where the
# product-owner authored Failure Guidance or Evaluation Rubric with internal IDs
# carried over from traceability drafts.
#
# EVALUATOR-FACING SECTIONS (scanned — closed set)
# ─────────────────────────────────────────────────
#   ## Scenario
#   ## Verification Approach
#   ## Evaluation Rubric   (including any prose/threshold notes below the table)
#   ## Failure Guidance
#   ## Edge Conditions
#
# EXEMPT SECTIONS (not scanned — may legitimately carry internal IDs)
# ─────────────────────────────────────────────────────────────────────
#   ## Behavioral Contract Linkage   (BC linkage table — traceability metadata for orchestrator)
#   ## Coverage Gap                  (coverage gap notes — traceability metadata)
#   ## Changelog                     (if present as ## heading; changelog prose is traceability)
#   ## Information Asymmetry Confirmation   (meta note for product-owner; not evaluator narrative)
#   ## Category                      (## Category: real-world-corpus — logistical note)
#   YAML frontmatter (the entire --- ... --- block, including changelog: list)
#   Any ## section NOT in the evaluator-facing closed set is SKIPPED (not scanned, not exempt)
#
# INTERNAL IDENTIFIER PATTERNS
# ─────────────────────────────
#   BC-ID:    BC-\d+\.\d+\.\d+        (e.g., BC-2.09.008)
#   BC-CLAUSE: {(PC|INV|PRE|EC)-\d+}  (e.g., {INV-001}, {PC-003})
#   VP-ID:    VP-\d{3,} or VP-[A-Z]+-\d+ or VP-\d+-[A-Z]  (e.g., VP-016, VP-STREAM-04)
#   E-CODE:   E-[A-Z]+-\d+            (e.g., E-MCP-010, E-GRAPH-018)
#   MOD-PATH: pregolya[_a-z]*::[a-z_]+ (e.g., pregolya_core::graph_engine)
#
# ADVISORY: exits 0 always.  Findings are printed as [WARN] lines.
# Do NOT wire as blocking without human authorization.  Promotion path: once
# all HS-*.md files show 0 evaluator-facing internal-ID findings, orchestrator
# promotes by:
#   1. Adding run_blocking "verify-holdout-asymmetry.sh" to pre-commit-validators.sh
#   2. Incrementing EXPECTED_BLOCKING_COUNT from 16 to 17
#   3. Changing exit contract in this script from "exit 0" to "exit $rc"
#
# SELF-PROBE (POL-31)
# ───────────────────
#   probe_hsa1_failure_guidance_flagged:    BC-2.09.008 {INV-001} in §Failure Guidance → WARN
#   probe_hsa2_behavioral_language_exempt:  behavioral description in §Failure Guidance → no WARN
#   probe_hsa3_bc_linkage_table_exempt:     BC-2.09.008 {INV-001} in §Behavioral Contract Linkage → no WARN
# POL-30: probe fixtures live in $TMPDIR, never under .factory/holdout-scenarios/.
#
# EXIT CONTRACT
# ─────────────
# Exit 0: always (advisory).
# Exit 2: self-probe failure (script bug — a check is false-green or false-red).
#
# Usage:  bash .factory/hooks/verify-holdout-asymmetry.sh
# Called: run_advisory in pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
HOLDOUT_DIR="$FACTORY_DIR/holdout-scenarios"

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
# Arguments: <holdout_dir>
# Output lines:
#   HIT <filename>:<lineno> [§<section>] [<id_type>] matched="<token>" | <snippet>
#   SCAN_FILES <n>
#   TOTAL <n>
run_asymmetry_scanner() {
  local holdout_dir="$1"
  python3 - "$holdout_dir" <<'PYEOF'
import sys, re
from pathlib import Path

holdout_dir = Path(sys.argv[1])

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — edit these two sets to change the section classification.
# Match is performed on the ## heading text (after "## " stripped), lowercased,
# using exact match or startswith (handles "## Coverage Gap — HS-C-001" etc.).
# ─────────────────────────────────────────────────────────────────────────────

# Closed set of evaluator-facing ## section heading prefixes.
# Sections in this set are scanned for internal identifiers.
EVALUATOR_FACING_PREFIXES = (
    "scenario",
    "verification approach",
    "evaluation rubric",
    "failure guidance",
    "edge conditions",
)

# Exempt ## section heading prefixes.
# These sections legitimately carry internal identifiers (traceability metadata).
EXEMPT_PREFIXES = (
    "behavioral contract linkage",
    "coverage gap",
    "changelog",
    "information asymmetry confirmation",
    "category",          # "## Category: real-world-corpus" — logistical note
)

# ─────────────────────────────────────────────────────────────────────────────
# INTERNAL IDENTIFIER PATTERNS
# ─────────────────────────────────────────────────────────────────────────────

INTERNAL_ID_PATTERNS = [
    # BC-2.09.008, BC-2.05.007, etc.
    ("BC-ID",
     re.compile(r'\bBC-\d+\.\d+\.\d+\b')),
    # {PC-001}, {INV-002}, {PRE-001}, {EC-001}
    ("BC-CLAUSE",
     re.compile(r'\{(?:PC|INV|PRE|EC)-\d+\}')),
    # VP-001, VP-016, VP-STREAM-04, VP-016-B, etc.
    ("VP-ID",
     re.compile(r'\bVP-\d{3,}\b|\bVP-[A-Z]+-\d+\b|\bVP-\d+-[A-Z]\b')),
    # E-MCP-010, E-GRAPH-018, E-TOOL-001, etc.
    ("E-CODE",
     re.compile(r'\bE-[A-Z]+-\d+\b')),
    # pregolya::foo, pregolya_core::bar_baz, etc.
    ("MOD-PATH",
     re.compile(r'\bpregolya[_a-z]*::[a-z_]+\b')),
]

# ─────────────────────────────────────────────────────────────────────────────
# SECTION CLASSIFIER
# ─────────────────────────────────────────────────────────────────────────────

MD_H2_RE = re.compile(r'^##\s+(.+)$')

def classify_section(heading_text: str) -> str:
    """Return 'evaluator', 'exempt', or 'skip' for a ## heading text."""
    norm = heading_text.strip().lower()
    for prefix in EVALUATOR_FACING_PREFIXES:
        if norm == prefix or norm.startswith(prefix):
            return "evaluator"
    for prefix in EXEMPT_PREFIXES:
        if norm == prefix or norm.startswith(prefix):
            return "exempt"
    return "skip"

# ─────────────────────────────────────────────────────────────────────────────
# FILE SCANNER
# ─────────────────────────────────────────────────────────────────────────────

def scan_file(path: Path) -> list:
    """Return list of (lineno, section_text, id_type, matched, snippet) for hits
    in evaluator-facing sections of this holdout scenario file."""
    try:
        raw = path.read_text(encoding='utf-8', errors='replace')
    except Exception:
        return []

    lines = raw.splitlines()
    findings = []

    in_yaml_front = False
    yaml_ended = False
    current_section = "skip"           # classification before first ## heading
    current_section_text = "(preamble)"

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
            # Skip all YAML frontmatter lines (changelog: list included)
            continue

        # ── Section tracking via ## headings ─────────────────────────────────
        # H3+ headings (### …) inherit the parent ## section's classification.
        m = MD_H2_RE.match(stripped)
        if m:
            heading_text = m.group(1)
            current_section = classify_section(heading_text)
            current_section_text = heading_text.strip()
            continue

        # ── Only scan evaluator-facing sections ──────────────────────────────
        if current_section != "evaluator":
            continue

        # ── Check for internal identifiers ───────────────────────────────────
        for (id_type, pattern) in INTERNAL_ID_PATTERNS:
            for m in pattern.finditer(line):
                findings.append((
                    lineno,
                    current_section_text,
                    id_type,
                    m.group(0),
                    line.rstrip()[:120],
                ))

    return findings


# ── Scan all HS-*.md files ────────────────────────────────────────────────────

total_findings = 0
scan_files_count = 0
all_results = {}  # Path -> list of finding tuples

if holdout_dir.is_dir():
    for p in sorted(holdout_dir.glob('HS-*.md')):
        scan_files_count += 1
        hits = scan_file(p)
        if hits:
            all_results[p] = hits
            total_findings += len(hits)

# ── Emit output ───────────────────────────────────────────────────────────────
for path, hits in sorted(all_results.items()):
    rel = path.name
    for lineno, section, id_type, matched, snippet in hits:
        print(f'HIT {rel}:{lineno} [§{section}] [{id_type}] matched="{matched}" | {snippet}')

print(f'SCAN_FILES {scan_files_count}')
print(f'TOTAL {total_findings}')
PYEOF
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

# Helper: run the scanner against a probe holdout dir; return HIT lines only.
run_probe_scan() {
  local probe_holdout_dir="$1"
  run_asymmetry_scanner "$probe_holdout_dir" | grep '^HIT' || true
}

# ── Self-probe hsa1: BC ID + clause tag in §Failure Guidance MUST be flagged ──
# A synthetic HS file with BC-2.09.008 {INV-001} in §Failure Guidance must produce
# two WARNs (one for BC-ID, one for BC-CLAUSE) — information asymmetry violation.
probe_hsa1_failure_guidance_flagged() {
  init_probe_tmp
  cat > "$PROBE_TMP/HS-PROBE.md" <<'SPECEOF'
---
document_type: holdout-scenario
version: "1.0"
---

## Scenario

An external host calls the runtime tool surface.

## Verification Approach

1. Send tools/list and verify the response.
2. Send tools/call and verify the result.

## Failure Guidance

"HOLDOUT LOW: HS-PROBE (satisfaction: X.XX) — integration failed.

- Check 5 fail: run_agent not advertised in tools/list (BC-2.09.008 {INV-001} violation),
  or the interrupt did not surface as E-MCP-010 and/or caused a hang ({INV-002} violation)."
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_hsa1_failure_guidance_flagged: BC-2.09.008 {INV-001} in §Failure Guidance was NOT flagged."
    echo "  Expected HIT lines for BC-ID and BC-CLAUSE patterns."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'BC-2.09.008'; then
    echo "[SELF-PROBE FAIL] probe_hsa1_failure_guidance_flagged: no BC-ID HIT for BC-2.09.008."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF '{INV-001}'; then
    echo "[SELF-PROBE FAIL] probe_hsa1_failure_guidance_flagged: no BC-CLAUSE HIT for {INV-001}."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hsa1_failure_guidance_flagged: BC-2.09.008 {INV-001} in §Failure Guidance is detected."
}

# ── Self-probe hsa2: behavioral language in §Failure Guidance MUST NOT be flagged ──
# A §Failure Guidance section with only observable behavioral descriptions (no internal IDs)
# must produce zero WARNs — this is the desired post-scrub state.
probe_hsa2_behavioral_language_exempt() {
  init_probe_tmp
  cat > "$PROBE_TMP/HS-PROBE.md" <<'SPECEOF'
---
document_type: holdout-scenario
version: "1.0"
---

## Scenario

An external host calls the runtime tool surface.

## Verification Approach

1. Send tools/list and verify the response.
2. Send tools/call and verify the result.

## Failure Guidance

"HOLDOUT LOW: HS-PROBE (satisfaction: X.XX) — integration failed.

- Check 5 fail: the agent was not advertised in the tools list, or the tools/call
  invocation failed or returned malformed content, or the response contained internal
  state (graph state, checkpoint identifiers, or message history), or a human-approval
  interrupt caused the call to hang instead of returning a structured tool error."
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_hsa2_behavioral_language_exempt: behavioral language in §Failure Guidance was incorrectly flagged."
    echo "  Pure observable-behavior descriptions must produce zero WARNs."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hsa2_behavioral_language_exempt: behavioral language in §Failure Guidance produces no WARN."
}

# ── Self-probe hsa3: BC ID in §Behavioral Contract Linkage MUST NOT be flagged ──
# The §Behavioral Contract Linkage table legitimately carries BC IDs, clause tags, and VP IDs
# as traceability metadata.  The gate must not flag this section.
probe_hsa3_bc_linkage_table_exempt() {
  init_probe_tmp
  cat > "$PROBE_TMP/HS-PROBE.md" <<'SPECEOF'
---
document_type: holdout-scenario
version: "1.0"
---

## Scenario

An external host calls the runtime tool surface and receives a well-formed response.

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Check |
|-------|--------------|----------------|
| BC-2.09.008 {PC-002} | tools/list includes run_agent | Check 5 — discovery |
| BC-2.09.008 {INV-001} + VP-016 | STATE-ISOLATION: only extract_output fields | Check 5 — isolation |
| BC-2.09.008 {INV-002} + E-MCP-010 | interrupt → isError:true | Check 5 — fail-closed |
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_hsa3_bc_linkage_table_exempt: BC ID in §Behavioral Contract Linkage was incorrectly flagged."
    echo "  §Behavioral Contract Linkage is an exempt traceability section — must not produce WARNs."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hsa3_bc_linkage_table_exempt: BC IDs in §Behavioral Contract Linkage are not flagged."
}

# ── Main live check ───────────────────────────────────────────────────────────
check_holdout_asymmetry() {
  if [ ! -d "$HOLDOUT_DIR" ]; then
    emit PASS "holdout-asymmetry: HOLDOUT_DIR not found ($HOLDOUT_DIR) — no HS-*.md files to scan"
    return
  fi

  local raw_output
  raw_output="$(run_asymmetry_scanner "$HOLDOUT_DIR")"

  local scan_files=0
  local total=0
  local hit_lines=()
  local hit_files=()

  while IFS= read -r line; do
    case "$line" in
      HIT\ *)        hit_lines+=("${line#HIT }") ;;
      SCAN_FILES\ *) scan_files="${line#SCAN_FILES }" ;;
      TOTAL\ *)      total="${line#TOTAL }" ;;
    esac
  done <<< "$raw_output"

  echo "  Scanned: ${scan_files} HS-*.md files in holdout-scenarios/"
  echo "  Scope:   Evaluator-facing sections only (Scenario, Verification Approach,"
  echo "           Evaluation Rubric, Failure Guidance, Edge Conditions)"
  echo "  Exempt:  Behavioral Contract Linkage, Coverage Gap, Changelog,"
  echo "           Information Asymmetry Confirmation, Category, YAML frontmatter"
  echo ""

  if [ "${#hit_lines[@]}" -eq 0 ]; then
    emit PASS "holdout-asymmetry: ZERO internal identifiers in evaluator-facing sections corpus-wide"
  else
    echo "  Internal identifiers found in evaluator-facing sections:"
    echo "  (These leak implementation details to evaluators — replace with observable behavioral language)"
    echo ""
    for entry in "${hit_lines[@]}"; do
      emit WARN "holdout-asymmetry: $entry"
    done
    echo ""
    echo "  Fix guidance:"
    echo "    BC-ID (e.g., BC-2.09.008)      → describe the observable contract behavior"
    echo "    BC-CLAUSE (e.g., {INV-001})     → describe the invariant in behavioral terms"
    echo "    VP-ID (e.g., VP-016)            → describe the property being verified"
    echo "    E-CODE (e.g., E-MCP-010)        → describe the error as observable behavior (isError:true, structured response)"
    echo "    MOD-PATH (e.g., pregolya::foo)  → describe the observable outcome at the API level"
    echo "  Routing: product-owner (HS-*.md evaluator-facing section scrub)"
    echo "  Reference: VSDD §Information Asymmetry; F-P2A105-03 / GAP-R24"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-holdout-asymmetry: HS-*.md evaluator-facing section internal-identifier gate (ADVISORY)"
echo "  Holdout: $HOLDOUT_DIR"
echo "  Finding: F-P2A105-03 / GAP-R24 — evaluator-facing sections must be free of internal IDs"
echo ""

echo "[SELF-PROBE] Verifying check catches internal IDs and respects all exclusions (POL-31)..."
probe_hsa1_failure_guidance_flagged
probe_hsa2_behavioral_language_exempt
probe_hsa3_bc_linkage_table_exempt
echo "[SELF-PROBE] All 3 self-probes passed — check is not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "ADVISORY check (exit 0 always)"
echo "════════════════════════════════════════════"
echo ""
echo "── holdout asymmetry scan ──────────────────────────────────────────────"
check_holdout_asymmetry

echo ""
echo "════════════════════════════════════════════"
echo ""
echo "verify-holdout-asymmetry: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  ADVISORY: $WARN WARN(s) — internal identifiers in evaluator-facing sections"
if [ "$WARN" -gt 0 ]; then
  echo "  Routing: product-owner — HS-*.md evaluator-facing section scrub"
  echo "  Gate reference: F-P2A105-03 / GAP-R24"
fi
echo ""
echo "RESULT: PASS (advisory — exit 0 regardless of WARN count)"
exit 0
