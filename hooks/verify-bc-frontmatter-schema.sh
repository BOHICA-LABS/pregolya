#!/usr/bin/env bash
# verify-bc-frontmatter-schema.sh — ferrochain factory-artifacts BLOCKING validator
#
# PURPOSE
# ───────
# Validates BC (behavioral-contract) frontmatter against the rules ratified in
# bc-authoring-plan.md. Every assertion below is grounded in a named rule or gate.
#
# RATIONALE-TO-RULE MAP
# ─────────────────────
# Each check is grounded in a specific rule from bc-authoring-plan.md.
# (Symbol/section citations only — TD-VSDD-091 forbids file:NNN line citations.)
#
#   CHECK 1 — bc_id: present AND value == file stem
#     Rule: bc-authoring-plan §Authoring Guidelines item 10 ("File path:
#     BC-S.SS.NNN.md") establishes the canonical BC identifier format.
#     §version-bump rules ("bc_id addition") names bc_id as the canonical
#     frontmatter field. Value MUST equal the file stem exactly (identity
#     check, not presence-only — a label-not-value check is the defect class
#     P1D-174 named).
#
#   CHECK 2 — changelog: required for version > "1.0" (BOTH forms checked)
#     Rule: bc-authoring-plan gate #28 §VERSION-CHANGELOG INTEGRITY:
#     "Any BC file with version > '1.0' MUST carry a changelog: frontmatter key
#     (or a ## Changelog body table) with at least one entry per version bump."
#     "A 'missing changelog' finding is ONLY valid when BOTH Form A AND Form B
#     return empty output for the target file."
#     v1.0 BCs are explicitly exempt ("version: '1.0': no changelog required").
#
#   CHECK 3 — red_gate: true → red_gate_source: required
#     Rule: bc-authoring-plan gate #36 §VP↔BC RED-GATE PARITY:
#     "red_gate: true requires three-way corroboration: anchor BC frontmatter
#     red_gate: true + BC-INDEX Red Gate membership + verifiable red_gate_source
#     citation." The red_gate_source key is mandatory when red_gate: true.
#     Note: red_gate: itself is OPTIONAL on BCs — gate #36 mandates it on all
#     VP files; on BCs it is CONDITIONAL (present only when the BC is a red-gate
#     anchor per VP-side red_gate: true).
#
#   CHECK 4 — vp_seed: true → vp_id format validation (if vp_id is present)
#     Rule: bc-authoring-plan §VP-NNN candidate label policy: "In the BC
#     frontmatter vp_seed: true field, the companion vp_id field MAY be set to
#     the candidate ID." vp_seed: itself is OPTIONAL; absence correctly means
#     the BC seeds no VP. When vp_seed: true and vp_id is explicitly set,
#     validate its format.
#
#   TYPO DETECTION (gate-critical fields only)
#     Misnamed variants of red_gate: and vp_seed: would silently bypass
#     CHECK 3 and CHECK 4 above. Detecting them preserves gate integrity.
#     Grounded in gate #36 canonical key name (red_gate) and §VP-NNN candidate
#     policy canonical key name (vp_seed).
#
# SCOPE
# ─────
# All .factory/specs/behavioral-contracts/ss-*/BC-*.md files.
# BC-INDEX.md is EXCLUDED — it is a catalog file, not a behavioral contract
# (analogous to VP-INDEX.md exclusion in gate #36 step 2).
#
# EXIT CONTRACT
# ─────────────
# Exits 0 if no FAIL lines (all BCs pass schema checks).
# Exits 1 if any FAIL lines (one or more BCs have schema violations).
#
# Promoted from advisory (always exits 0) to blocking at fix-burst-283.
# Corpus-wide baseline at promotion: PASS=129 FAIL=0 — zero violations confirmed.
#
# Usage:  bash .factory/hooks/verify-bc-frontmatter-schema.sh
# Exit:   0 if FAIL == 0; 1 if FAIL > 0

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# BC-INDEX.md excluded — catalog file, not a behavioral contract
BC_GLOB="$FACTORY_DIR/specs/behavioral-contracts/ss-*/BC-*.md"

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

# ── Python3 inline validator ──────────────────────────────────────────────────

PYTHON_OUTPUT="$(python3 - "$BC_GLOB" <<'PYEOF'
import sys, glob as globmod, os, re, yaml

bc_pattern = sys.argv[1]
# BC-INDEX.md matches BC-*.md glob — exclude it explicitly (catalog, not contract)
all_files = sorted(globmod.glob(bc_pattern))
files = [f for f in all_files if os.path.basename(f) != 'BC-INDEX.md']

# CHECK 1: bc_id value must match BC-D.DD.DDD pattern exactly
# (bc-authoring-plan §Authoring Guidelines item 10, §version-bump rules)
BC_ID_RE = re.compile(r'^BC-\d+\.\d+\.\d+$')

# CHECK 4: vp_id format (when present) — VP-NNN or VP-NNN.NNN.NNN-A or VP-DOMAIN-SUB-NN
# (bc-authoring-plan §VP-NNN candidate label policy)
VP_ID_RE = re.compile(r'^VP-\d{3}$|^VP-\d+\.\d+\.\d+-[A-Z]+$|^VP-[A-Z]+-[A-Z]+-\d+$')

# TYPO DETECTION: misnamed variants of gate-critical keys that would silently
# bypass CHECK 3 (red_gate) and CHECK 4 (vp_seed).
# Grounded in gate #36 (red_gate canonical name) and §VP-NNN candidate policy (vp_seed).
TYPO_KEYS = {
    'redgate':  'red_gate',   # gate #36 canonical: red_gate
    'red-gate': 'red_gate',   # gate #36 canonical: red_gate
    'vp-seed':  'vp_seed',    # VP-NNN candidate policy canonical: vp_seed
    'vpseed':   'vp_seed',    # VP-NNN candidate policy canonical: vp_seed
}

def parse_frontmatter(content):
    """Return (fm_dict, raw_fm_keys, parse_error_string_or_None)."""
    parts = content.split('---', 2)
    if len(parts) < 3:
        return None, [], 'no-frontmatter-delimiters'
    raw_yaml = parts[1]
    try:
        fm = yaml.safe_load(raw_yaml)
    except yaml.YAMLError as exc:
        return None, [], f'yaml-parse-error: {exc}'
    if not isinstance(fm, dict):
        return None, [], 'frontmatter-not-a-mapping'
    raw_keys = list(fm.keys())
    return fm, raw_keys, None

def check_bc(filepath):
    """Return (status, findings_list)."""
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError as exc:
        return 'WARN', [f'read-error: {exc}']

    fm, raw_keys, error = parse_frontmatter(content)
    if error:
        return 'WARN', [f'frontmatter-parse-failure: {error}']

    findings = []
    stem = os.path.basename(filepath)[:-3]  # e.g. BC-2.01.001

    # ── CHECK 1: bc_id present and value == file stem ─────────────────────────
    # Rule: bc-authoring-plan §Authoring Guidelines item 10 + §version-bump rules
    if 'bc_id' not in fm:
        findings.append("missing required key 'bc_id'")
    else:
        bc_id_val = str(fm['bc_id']).strip().strip('"\'')
        if not BC_ID_RE.match(bc_id_val):
            findings.append(
                f"'bc_id' value {bc_id_val!r} does not match BC-D.DD.DDD pattern "
                f"(bc-authoring-plan §Authoring Guidelines item 10)")
        elif bc_id_val != stem:
            findings.append(
                f"'bc_id' {bc_id_val!r} does not match file stem {stem!r} "
                f"(bc-authoring-plan §Authoring Guidelines item 10)")

    # ── CHECK 2: changelog for version > "1.0" (both forms) ──────────────────
    # Rule: bc-authoring-plan gate #28 §VERSION-CHANGELOG INTEGRITY
    version_str = str(fm.get('version', '')).strip().strip('"\'')
    if version_str and version_str != '1.0':
        has_form_a = 'changelog' in fm and fm['changelog'] is not None
        has_form_b = '\n## Changelog\n' in content or content.startswith('## Changelog\n')
        if not has_form_a and not has_form_b:
            findings.append(
                f"version {version_str!r} > '1.0' but neither Form A (frontmatter "
                f"'changelog:' list) nor Form B ('## Changelog' body table) is present "
                f"(gate #28 §VERSION-CHANGELOG INTEGRITY)")

    # ── CHECK 3: red_gate: true → red_gate_source required ───────────────────
    # Rule: bc-authoring-plan gate #36 §VP↔BC RED-GATE PARITY
    # Note: red_gate: is NOT universally required on BCs — only gate #36 VPs must
    # carry it universally; BC-side obligation is conditional per gate #36 Rule 2.
    if fm.get('red_gate') is True:
        rgs = fm.get('red_gate_source')
        if rgs is None:
            findings.append(
                "'red_gate: true' requires non-null 'red_gate_source' "
                "(gate #36 §VP↔BC RED-GATE PARITY)")
        elif not str(rgs).strip():
            findings.append(
                "'red_gate_source' is empty; must be non-null when red_gate: true "
                "(gate #36 §VP↔BC RED-GATE PARITY)")

    # ── CHECK 4: vp_seed: true → validate vp_id format if set ────────────────
    # Rule: bc-authoring-plan §VP-NNN candidate label policy
    # Note: vp_seed: is OPTIONAL; absence correctly means the BC seeds no VP.
    # When vp_seed: true, vp_id MAY be absent (candidate VP, not yet assigned).
    # When vp_seed: true AND vp_id is present, validate its format.
    if fm.get('vp_seed') is True:
        vpid = fm.get('vp_id')
        if vpid is not None:
            vpid_str = str(vpid).strip().strip('"\'')
            if vpid_str and not VP_ID_RE.match(vpid_str):
                findings.append(
                    f"'vp_id' value {vpid_str!r} does not match VP-NNN or VP-NNN.NNN.NNN-A "
                    f"pattern (bc-authoring-plan §VP-NNN candidate label policy)")

    # ── TYPO DETECTION: gate-critical field misspellings ─────────────────────
    # Grounded in gate #36 canonical key (red_gate) and §VP-NNN candidate policy (vp_seed)
    for key in raw_keys:
        if key in TYPO_KEYS:
            findings.append(
                f"typo'd key '{key}': use '{TYPO_KEYS[key]}' instead — "
                f"misspelling bypasses gate-integrity checks")

    return ('FAIL', findings) if findings else ('PASS', [])

for filepath in files:
    status, findings = check_bc(filepath)
    short = filepath.split('/specs/')[-1] if '/specs/' in filepath else filepath
    if findings:
        print(f"FAIL {short} findings={len(findings)}")
        for f in findings:
            print(f"  DETAIL: {f.replace(chr(10), ' ')}")
    else:
        print(f"PASS {short}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

FILE_FAIL=0

while IFS= read -r line; do
  tag="${line%% *}"
  rest="${line#* }"

  case "$tag" in
    PASS)
      emit PASS "$rest"
      ;;
    FAIL)
      short="$(echo "$rest" | awk -F' findings=' '{print $1}')"
      count="$(echo "$rest" | grep -oE 'findings=[0-9]+' | cut -d= -f2)"
      emit FAIL "schema violations in $short ($count issue(s))"
      FILE_FAIL=$((FILE_FAIL + 1))
      ;;
    *)
      # DETAIL lines start with two spaces — tag extraction strips leading spaces
      # to a bare space, so they fall through to this handler.
      if [[ "$line" == "  DETAIL: "* ]]; then
        detail="${line#  DETAIL: }"
        echo "  $detail"
      fi
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-bc-frontmatter-schema: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  Files with schema violations: $FILE_FAIL"
echo ""
echo "Checks (all grounded in a ratified rule from bc-authoring-plan.md):"
echo "  CHECK 1: bc_id: present AND value == file stem"
echo "           Rule: bc-authoring-plan §Authoring Guidelines item 10, §version-bump rules"
echo "  CHECK 2: changelog: for version > 1.0 (Form A OR Form B)"
echo "           Rule: bc-authoring-plan gate #28 §VERSION-CHANGELOG INTEGRITY"
echo "  CHECK 3: red_gate: true → red_gate_source: required"
echo "           Rule: bc-authoring-plan gate #36 §VP↔BC RED-GATE PARITY"
echo "  CHECK 4: vp_seed: true AND vp_id present → vp_id format valid"
echo "           Rule: bc-authoring-plan §VP-NNN candidate label policy"
echo "  TYPO:    redgate/red-gate/vp-seed/vpseed key-name detection"
echo "           Rule: gate-critical canonical names from gate #36 and §VP-NNN candidate policy"
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
