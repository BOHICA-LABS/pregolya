#!/usr/bin/env bash
# verify-bc-frontmatter-schema.sh — ferrochain factory-artifacts ADVISORY validator
#
# PURPOSE
# ───────
# Validates that every BC (behavioral-contract) file has a complete, well-formed
# frontmatter schema. Required fields:
#
#   red_gate       boolean (true/false)  — mandatory on every BC
#   vp_seed        boolean (true/false)  — mandatory on every BC
#   red_gate_source  non-null string     — mandatory when red_gate: true
#   vp_id            non-null string     — mandatory when vp_seed: true
#
# Additionally detects common typo'd key names:
#   "redgate", "red-gate", "vpSeed", "vp-seed", "vpseed",
#   "red_gate_src", "rg_source", "vp_source" — these are wrong key names
#   and indicate a spec authoring error.
#
# VERSION
# ───────
# Checks that every BC file has:
#   version: X.Y   — required present (any semver-like value accepted)
#   changelog:     — required present (any value; content format enforced elsewhere)
#   document_type: behavioral-contract
#   id:            — present and matching filename pattern BC-S.SS.NNN
#
# SCOPE
# ─────
# All files matching .factory/specs/behavioral-contracts/ss-*/BC-*.md
#
# ADVISORY STATUS
# ───────────────
# All findings are WARN (non-blocking). Will be promoted to blocking after
# a corpus-wide schema sweep confirms zero false-positives.
#
# EXIT CONTRACT
# ─────────────
# Always exits 0 (advisory — non-blocking).
#
# Usage:  bash .factory/hooks/verify-bc-frontmatter-schema.sh
# Exit:   0 always (advisory)

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
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
files = sorted(globmod.glob(bc_pattern))

# Typo'd key names that indicate mis-authored frontmatter
TYPO_KEYS = {
    'redgate': 'red_gate',
    'red-gate': 'red_gate',
    'red_gate_src': 'red_gate_source',
    'rg_source': 'red_gate_source',
    'vpseed': 'vp_seed',
    'vpSeed': 'vp_seed',
    'vp-seed': 'vp_seed',
    'vp_source': 'vp_id',
    'vp-id': 'vp_id',
    'vpId': 'vp_id',
}

# BC ID pattern: BC-D.DD.DDD or BC-D.D.DDD
BC_ID_RE = re.compile(r'^BC-\d+\.\d+\.\d+$')

def parse_frontmatter_raw(content):
    """
    Return (fm_dict, raw_fm_keys_list, parse_error).
    fm_dict may be None on parse failure.
    raw_fm_keys_list is the list of top-level key names found (order-preserved).
    """
    parts = content.split('---', 2)
    if len(parts) < 3:
        return None, [], 'no-frontmatter-delimiters'
    raw_yaml = parts[1]
    try:
        fm = yaml.safe_load(raw_yaml)
    except yaml.YAMLError as exc:
        return None, [], f'yaml-parse-error:{exc}'
    if not isinstance(fm, dict):
        return None, [], 'frontmatter-not-a-mapping'
    # Extract raw key names for typo detection
    raw_keys = list(yaml.safe_load(raw_yaml).keys()) if fm else []
    return fm, raw_keys, None

def check_bc(filepath):
    """
    Return (status, list_of_findings) where status is 'PASS' or 'WARN'.
    Each finding is a string.
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError as exc:
        return 'WARN', [f'read-error: {exc}']

    fm, raw_keys, error = parse_frontmatter_raw(content)
    if error:
        return 'WARN', [f'frontmatter-parse-failure: {error}']

    findings = []
    filename = os.path.basename(filepath)

    # ── Typo key detection ────────────────────────────────────────────────────
    for key in raw_keys:
        if key in TYPO_KEYS:
            findings.append(f"typo'd key '{key}' — should be '{TYPO_KEYS[key]}'")

    # ── Required boolean: red_gate ────────────────────────────────────────────
    if 'red_gate' not in fm:
        findings.append("missing required key 'red_gate' (boolean)")
    else:
        val = fm['red_gate']
        if not isinstance(val, bool):
            findings.append(f"'red_gate' must be boolean true/false, got {type(val).__name__}:{val!r}")

    # ── Required boolean: vp_seed ─────────────────────────────────────────────
    if 'vp_seed' not in fm:
        findings.append("missing required key 'vp_seed' (boolean)")
    else:
        val = fm['vp_seed']
        if not isinstance(val, bool):
            findings.append(f"'vp_seed' must be boolean true/false, got {type(val).__name__}:{val!r}")

    # ── Conditional: red_gate_source ──────────────────────────────────────────
    if fm.get('red_gate') is True:
        rgs = fm.get('red_gate_source')
        if rgs is None:
            findings.append("'red_gate: true' requires non-null 'red_gate_source' key")
        elif not str(rgs).strip():
            findings.append("'red_gate_source' is present but empty — required non-null when red_gate is true")

    # ── Conditional: vp_id ───────────────────────────────────────────────────
    if fm.get('vp_seed') is True:
        vpid = fm.get('vp_id')
        if vpid is None:
            findings.append("'vp_seed: true' requires non-null 'vp_id' key")
        elif not str(vpid).strip():
            findings.append("'vp_id' is present but empty — required non-null when vp_seed is true")

    # ── Required: version ────────────────────────────────────────────────────
    if 'version' not in fm:
        findings.append("missing required key 'version'")
    else:
        v = str(fm['version']).strip()
        if not re.match(r'^\d+\.\d+', v):
            findings.append(f"'version' does not look like a semver value: {v!r}")

    # ── Required: changelog ──────────────────────────────────────────────────
    if 'changelog' not in fm:
        findings.append("missing required key 'changelog' (Form-A list)")

    # ── Required: document_type ──────────────────────────────────────────────
    if 'document_type' not in fm:
        findings.append("missing required key 'document_type'")
    else:
        dt = str(fm['document_type']).strip()
        if dt != 'behavioral-contract':
            findings.append(f"'document_type' must be 'behavioral-contract', got {dt!r}")

    # ── Required: id — must be present and match BC-S.SS.NNN pattern ─────────
    if 'id' not in fm:
        findings.append("missing required key 'id'")
    else:
        id_val = str(fm['id']).strip()
        if not BC_ID_RE.match(id_val):
            findings.append(f"'id' value {id_val!r} does not match expected BC-D.DD.DDD pattern")
        # Cross-check: id should match the filename stem
        # filename is like BC-2.01.001.md → id should be BC-2.01.001
        filename_stem = filename[:-3]  # strip .md
        if BC_ID_RE.match(id_val) and id_val != filename_stem:
            findings.append(f"'id' {id_val!r} does not match filename stem {filename_stem!r}")

    if findings:
        return 'WARN', findings
    return 'PASS', []

for filepath in files:
    status, findings = check_bc(filepath)
    # Emit a structured line per file
    if findings:
        # Join findings with '; ' for single-line output; individual items on next lines
        short = filepath.split('/specs/')[-1] if '/specs/' in filepath else filepath
        print(f"WARN {short} findings={len(findings)}")
        for f in findings:
            f_safe = f.replace('\n', ' ')
            print(f"  DETAIL: {f_safe}")
    else:
        short = filepath.split('/specs/')[-1] if '/specs/' in filepath else filepath
        print(f"PASS {short}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

FILE_WARN=0

while IFS= read -r line; do
  tag="${line%% *}"
  rest="${line#* }"

  case "$tag" in
    PASS)
      emit PASS "$rest"
      ;;
    WARN)
      short="$(echo "$rest" | awk -F' findings=' '{print $1}')"
      count="$(echo "$rest" | grep -oE 'findings=[0-9]+' | cut -d= -f2)"
      emit WARN "[ADVISORY] schema findings in $short ($count issue(s))"
      FILE_WARN=$((FILE_WARN + 1))
      ;;
    "  DETAIL:")
      detail="${line#*DETAIL: }"
      echo "  $detail"
      ;;
    *)
      : # space-indented detail lines — printed directly
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-bc-frontmatter-schema: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  Files with schema advisory findings: $FILE_WARN"
echo ""
echo "Advisory checks (all non-blocking):"
echo "  required booleans: red_gate, vp_seed"
echo "  conditional non-null: red_gate_source (when red_gate: true)"
echo "  conditional non-null: vp_id (when vp_seed: true)"
echo "  required: version, changelog, document_type, id"
echo "  typo key detection: redgate, red-gate, vpSeed, vp-seed, etc."
echo ""
echo "RESULT: PASS (advisory — non-blocking)"
# Always exit 0 — advisory check
exit 0
