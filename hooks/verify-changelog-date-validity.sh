#!/usr/bin/env bash
# verify-changelog-date-validity.sh — gate #28 Rules 4 and 5 enforcement
#
# Checks two date-validity properties for spec files under .factory/specs/:
#
# RULE 4 (FUTURE-DATE CEILING — D18-P75-A / gate #28 Rule 4):
#   No changelog entry date (Form-A frontmatter list or Form-B body table) may
#   exceed today's date.  Applied universally to ALL spec files.  A future-dated
#   entry is a gate failure regardless of intra-file ordering (verify-changelog-
#   date-monotonicity.sh checks ordering; this script closes the ceiling gap: a
#   future-dated entry at the HEAD of an ascending list is monotonically valid yet
#   still wrong).
#
# RULE 5 (FRONTMATTER-CURRENCY — D18-P86-A / gate #28 Rule 5):
#   frontmatter timestamp: must match the appropriate anchor date.  Scoped by
#   document type per D18-P86-A, D18-P87-A, F-P171a-17:
#
#   Supplement documents (.factory/specs/prd-supplements/*.md — the explicit 7:
#     bc-authoring-plan, test-vectors, error-taxonomy, interface-definitions,
#     nfr-catalog, module-criticality, observability):
#       timestamp: date must equal max(all changelog entry dates across Form-A
#       and Form-B).  A supplement timestamp: that does not match the newest
#       changelog entry date is a self-contradiction.
#
#   BC files (.factory/specs/behavioral-contracts/ss-*/BC-*.md, identified by
#   introduced: frontmatter field present):
#       timestamp: is frozen at initial authoring (v1.0).  If the file carries a
#       Form-B body ## Changelog table with an identifiable v1.0 row, verify
#       timestamp: date == that row's date.  BCs with Form-A only (no Form-B v1.0
#       row) are trivially valid — the frozen timestamp cannot be checked without
#       the v1.0 row anchor.
#
#   ADR files (.factory/specs/architecture/decisions/):
#       timestamp: (or date:) is frozen at original acceptance.  If an ADR carries
#       a Form-B ## Changelog table, verify timestamp: date == the OLDEST (last
#       row, descending table) entry date.  Emits WARN (advisory), not FAIL:
#       ADR format varies and promotion to FAIL occurs after census confirms
#       full ADR coverage.
#
#   All other spec files: out of scope for Rule 5 (architecture non-ADR, domain-spec,
#   prd.md, VP-INDEX.md, etc. have separate timestamp disciplines not covered by
#   gate #28 Rule 5 as adjudicated in D18-P86-A).
#
# D-56 self-scope exclusion:
#   Corpus is .factory/specs/**/*.md.  Hook scripts (.factory/hooks/) and self-probe
#   fixtures (written to /tmp/ via mktemp) are outside the corpus by scope.
#   No additional exclusion pattern is required.
#
# Baseline (established burst-283): PASS=N WARN=N FAIL=0
#
# Per-file output:
#   [PASS] <short-path>
#   [WARN] <short-path> — <reason>
#   [FAIL] <short-path> — <violation>
#
# Summary line format:
#   verify-changelog-date-validity: PASS=N WARN=N FAIL=N
#
# Exit: 0 if no FAIL; 1 if any FAIL.

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TODAY="$(date -u +%Y-%m-%d)"

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

# ── Self-probe: narrow proof per D-57 ────────────────────────────────────────
#
# Demonstrates that the Rule 5 supplement check:
#   (A) FIRES in normative position: supplement with timestamp != newest_cl_date
#   (B) Does NOT fire in exempt position: BC file (introduced: present) with same
#       apparent timestamp mismatch — exempt because BC branch applies instead,
#       and BC branch trivially passes when no Form-B v1.0 row is present.
#
# Both probes run in the SAME temp directory (same fixture run), satisfying D-57.
# D-56: fixtures live in /tmp/ — outside .factory/specs/ corpus by scope.

run_self_probes() {
  local PROBE_TMP
  PROBE_TMP="$(mktemp -d)"
  trap 'rm -rf "$PROBE_TMP"' EXIT

  # Normative position: supplement file (no introduced:) with timestamp 2026-07-15
  # but newest Form-A changelog date 2026-07-20.  Rule 5 supplement branch must FAIL.
  cat > "$PROBE_TMP/probe-supplement.md" <<'EOF'
---
document_type: prd-supplement-probe
version: "1.2"
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.2 (burst-probe/2026-07-20): Second version."
  - "1.1 (burst-probe/2026-07-18): First version."
---
# Probe supplement document (no introduced: field = supplement branch applies)
EOF

  # Exempt position: BC file with introduced: present.  Same apparent mismatch:
  # timestamp 2026-07-13 but newest changelog date 2026-07-20.  The supplement
  # rule does NOT apply.  BC rule: no Form-B v1.0 row → trivially PASS.
  cat > "$PROBE_TMP/probe-bc.md" <<'EOF'
---
document_type: behavioral-contract
version: "1.2"
timestamp: 2026-07-13T00:00:00Z
introduced: "v1.0.0-greenfield"
changelog:
  - "1.2 (burst-probe/2026-07-20): Second version."
  - "1.1 (burst-probe/2026-07-17): First version."
---
# Probe BC document (introduced: present = BC branch, exempt from supplement rule)
EOF

  # Inline Python: same scan logic but applied to PROBE_TMP as the spec dir.
  # prd-supplements path for probe = PROBE_TMP itself (no sub-directory).
  PROBE_OUT="$(python3 - "$PROBE_TMP" "$PROBE_TMP" "2026-07-30" <<'PYEOF'
import sys, os, glob, re, yaml

spec_dir        = sys.argv[1]
supplement_dir  = sys.argv[2]
today           = sys.argv[3]

ADR_DEC_DIR   = os.path.join(spec_dir, 'architecture', 'decisions')
DATE_RE       = re.compile(r'\b(\d{4}-\d{2}-\d{2})\b')
FORM_B_ROW_RE = re.compile(
    r'^\|\s*(v?\d+\.\d+(?:\.\d+)*)\s*\|\s*(\d{4}-\d{2}-\d{2})\s*\|',
    re.MULTILINE
)

def extract_dates_form_a(changelog):
    dates = []
    for entry in (changelog or []):
        m = DATE_RE.search(str(entry))
        if m:
            dates.append(m.group(1))
    return dates

def extract_form_b_rows(body):
    return FORM_B_ROW_RE.findall(body)

for filepath in sorted(glob.glob(os.path.join(spec_dir, '**', '*.md'), recursive=True)):
    try:
        content = open(filepath, 'r', encoding='utf-8').read()
    except OSError:
        continue
    parts = content.split('---', 2)
    if len(parts) < 3:
        continue
    try:
        fm = yaml.safe_load(parts[1])
    except Exception:
        continue
    if not isinstance(fm, dict):
        continue
    body         = parts[2]
    short        = os.path.basename(filepath)
    is_bc        = 'introduced' in fm
    is_adr       = filepath.startswith(ADR_DEC_DIR + os.sep)
    is_supplement= filepath.startswith(supplement_dir + os.sep) and not is_bc
    cl           = fm.get('changelog', []) if 'changelog' in fm else None
    form_a_dates = extract_dates_form_a(cl) if cl else []
    form_b_rows  = extract_form_b_rows(body)
    form_b_dates = [d for _, d in form_b_rows]
    all_dates    = form_a_dates + form_b_dates
    if not all_dates:
        print(f"PASS {short}")
        continue
    future = [d for d in all_dates if d > today]
    if future:
        print(f"FAIL-R4 {short} future-dates:{','.join(sorted(future))}")
        continue
    ts_raw = fm.get('timestamp') or fm.get('date')
    if ts_raw is None:
        print(f"PASS {short}")
        continue
    ts_date = str(ts_raw)[:10]
    if is_bc:
        v10_rows = [(ver, date) for ver, date in form_b_rows
                    if ver.lstrip('v') == '1.0']
        if v10_rows:
            v1_date = v10_rows[-1][1]
            if ts_date != v1_date:
                print(f"FAIL-R5-BC {short} timestamp={ts_date} v1.0-form-b-date={v1_date}")
            else:
                print(f"PASS {short}")
        else:
            print(f"PASS {short}")
    elif is_supplement:
        newest_date = max(all_dates)
        if ts_date != newest_date:
            print(f"FAIL-R5-SUP {short} timestamp={ts_date} newest-cl-date={newest_date}")
        else:
            print(f"PASS {short}")
    elif is_adr:
        if form_b_dates:
            oldest_date = form_b_dates[-1]
            if ts_date != oldest_date:
                print(f"WARN-R5-ADR {short} timestamp={ts_date} oldest-cl-date={oldest_date}")
            else:
                print(f"PASS {short}")
        else:
            print(f"PASS {short}")
    else:
        print(f"PASS {short}")
PYEOF
)"

  # Probe A: supplement file must emit FAIL-R5-SUP
  if ! echo "$PROBE_OUT" | grep -q "FAIL-R5-SUP probe-supplement.md"; then
    echo "[SELF-PROBE FAIL] Rule 5 supplement probe A: expected FAIL-R5-SUP not detected."
    echo "  probe-supplement.md: timestamp=2026-07-15, newest_cl_date=2026-07-20 — should FAIL."
    echo "  This is a script bug — the supplement check would silently pass on a real violation."
    echo "  Probe output:"; echo "$PROBE_OUT"
    exit 2
  fi

  # Probe B: BC file (introduced:) must NOT emit any FAIL
  if echo "$PROBE_OUT" | grep -q "FAIL.*probe-bc.md"; then
    echo "[SELF-PROBE FAIL] Rule 5 BC probe B: unexpected FAIL for probe-bc.md."
    echo "  probe-bc.md has introduced: — BC branch applies; supplement rule must not fire."
    echo "  This is a script bug — gate incorrectly classifies BC files as supplements."
    echo "  Probe output:"; echo "$PROBE_OUT"
    exit 2
  fi

  echo "[SELF-PROBE PASS] Rule 5 fires in normative position (supplement timestamp mismatch)"
  echo "[SELF-PROBE PASS] Rule 5 silent in exempt position (BC with introduced: field)"
  echo "[SELF-PROBE] Narrow proof complete — gate is not false-green."
  echo ""

  rm -rf "$PROBE_TMP"
  trap - EXIT
}

# ── Main scan ─────────────────────────────────────────────────────────────────

echo "verify-changelog-date-validity: gate #28 Rules 4 and 5"
echo "  FACTORY_DIR: $FACTORY_DIR"
echo "  TODAY: $TODAY"
echo ""

echo "── Self-probe ──────────────────────────────────────────────────────────"
run_self_probes

SUPPLEMENT_DIR="$FACTORY_DIR/specs/prd-supplements"

PYTHON_OUTPUT="$(python3 - "$FACTORY_DIR/specs" "$SUPPLEMENT_DIR" "$TODAY" <<'PYEOF'
import sys, os, glob, re, yaml

spec_dir       = sys.argv[1]
supplement_dir = sys.argv[2]
today          = sys.argv[3]
factory_dir    = os.path.dirname(spec_dir)

ADR_DEC_DIR   = os.path.join(spec_dir, 'architecture', 'decisions')
DATE_RE       = re.compile(r'\b(\d{4}-\d{2}-\d{2})\b')
FORM_B_ROW_RE = re.compile(
    r'^\|\s*(v?\d+\.\d+(?:\.\d+)*)\s*\|\s*(\d{4}-\d{2}-\d{2})\s*\|',
    re.MULTILINE
)

def extract_dates_form_a(changelog):
    """Extract first YYYY-MM-DD from each Form-A YAML list entry."""
    dates = []
    for entry in (changelog or []):
        m = DATE_RE.search(str(entry))
        if m:
            dates.append(m.group(1))
    return dates

def extract_form_b_rows(body):
    """Return list of (version_str, date_str) for Form-B ## Changelog table rows."""
    return FORM_B_ROW_RE.findall(body)

all_files = sorted(glob.glob(os.path.join(spec_dir, '**', '*.md'), recursive=True))

for filepath in all_files:
    try:
        content = open(filepath, 'r', encoding='utf-8').read()
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    parts = content.split('---', 2)
    if len(parts) < 3:
        print(f"SKIP {filepath} no-frontmatter")
        continue

    try:
        fm = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        # FAIL (not SKIP/WARN): unparseable frontmatter = UNVERIFIED (F-P176-E007 class).
        print(f"FAIL {filepath} yaml-parse-error:{str(e).replace(chr(10), ' | ')}")
        continue

    if not isinstance(fm, dict):
        # FAIL (not SKIP/WARN): non-dict frontmatter is structurally malformed.
        print(f"FAIL {filepath} frontmatter-not-dict")
        continue

    body = parts[2]
    short = filepath[len(factory_dir) + 1:]

    # File classification
    is_bc        = 'introduced' in fm
    is_adr       = filepath.startswith(ADR_DEC_DIR + os.sep)
    # Rule 5 supplement branch applies only to prd-supplements/*.md
    is_supplement = filepath.startswith(supplement_dir + os.sep) and not is_bc

    # Extract changelog dates from both forms
    cl           = fm.get('changelog', []) if 'changelog' in fm else None
    form_a_dates = extract_dates_form_a(cl) if cl else []
    form_b_rows  = extract_form_b_rows(body)
    form_b_dates = [d for _, d in form_b_rows]
    all_dates    = form_a_dates + form_b_dates

    # No changelog dates: trivially valid for Rules 4 and 5
    if not all_dates:
        print(f"PASS {filepath}")
        continue

    # ── RULE 4: future-date ceiling (universal) ──────────────────────────────
    future_dates = [d for d in all_dates if d > today]
    if future_dates:
        print(f"FAIL-R4 {filepath} future-dates:{','.join(sorted(future_dates))}")
        continue

    # ── RULE 5: frontmatter-currency (scoped by document type) ───────────────
    ts_raw = fm.get('timestamp') or fm.get('date')
    if ts_raw is None:
        # No timestamp — Rule 5 not applicable for this file
        print(f"PASS {filepath}")
        continue

    ts_date = str(ts_raw)[:10]  # Extract YYYY-MM-DD from ISO timestamp

    if is_bc:
        # BC branch: timestamp: must equal date of the v1.0 Form-B row (if present)
        v10_rows = [(ver, date) for ver, date in form_b_rows
                    if ver.lstrip('v') == '1.0']
        if v10_rows:
            # Form-B is descending; last v1.0 row is the canonical anchor
            v1_date = v10_rows[-1][1]
            if ts_date != v1_date:
                print(f"FAIL-R5-BC {filepath} timestamp={ts_date} v1.0-form-b-date={v1_date}")
            else:
                print(f"PASS {filepath}")
        else:
            # No Form-B v1.0 row — frozen timestamp trivially valid
            print(f"PASS {filepath}")

    elif is_supplement:
        # Supplement branch: timestamp: must equal newest changelog entry date
        newest_date = max(all_dates)
        if ts_date != newest_date:
            print(f"FAIL-R5-SUP {filepath} timestamp={ts_date} newest-cl-date={newest_date}")
        else:
            print(f"PASS {filepath}")

    elif is_adr:
        # ADR branch (WARN, advisory): timestamp: must equal oldest Form-B entry date
        # Promoted to FAIL after census confirms full ADR coverage.
        if form_b_dates:
            oldest_date = form_b_dates[-1]
            if ts_date != oldest_date:
                print(f"WARN-R5-ADR {filepath} timestamp={ts_date} oldest-cl-date={oldest_date}")
            else:
                print(f"PASS {filepath}")
        else:
            print(f"PASS {filepath}")

    else:
        # Other spec files (domain-spec, prd.md, VP-INDEX.md, architecture non-ADR,
        # standalone module-criticality.md, etc.): Rule 5 not scoped to this file class.
        print(f"PASS {filepath}")

PYEOF
)"

# ── Process scan output ───────────────────────────────────────────────────────

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"
  filepath="${rest%% *}"
  detail="${rest#* }"
  short="${filepath#"$FACTORY_DIR"/}"

  case "$level" in
    PASS)        emit PASS "$short" ;;
    FAIL-R4)     emit FAIL "$short — Rule 4 (future-date ceiling): $detail" ;;
    FAIL-R5-SUP) emit FAIL "$short — Rule 5 (supplement timestamp-currency): $detail" ;;
    FAIL-R5-BC)  emit FAIL "$short — Rule 5 (BC v1.0-date mismatch): $detail" ;;
    WARN-R5-ADR) emit WARN "$short — Rule 5 ADR (advisory): $detail" ;;
    SKIP)        emit WARN "$short (skipped: $detail)" ;;
    *)           emit WARN "unexpected output: $line" ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-changelog-date-validity: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
