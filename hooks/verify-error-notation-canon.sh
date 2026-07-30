#!/usr/bin/env bash
# verify-error-notation-canon.sh — pregolya error-construction notation gate
#
# PURPOSE
# ───────
# Enforces the ADR-010 §Error-Construction Notation Canon across all .md files
# under .factory/specs/.  Classifies every PregolyaError { occurrence per the
# Mechanical Discriminator (Steps 0–2) and blocks on any FAIL-class finding.
#
# BLOCKING: exits 1 on any FAIL.  Wired into pre-commit-validators.sh.
#
# SPEC AUTHORITY
# ──────────────
# All classification rules derive from:
#   ADR-010-error-taxonomy-anyhow-confinement.md
#   §Error-Construction Notation Canon (D-72 extension, v1.14+)
#   §Mechanical Discriminator (Steps 0–2)
# NEVER use line-number citations (TD-VSDD-091): symbol/section anchors only.
#
# VIOLATION CLASSES
# ─────────────────
#   CLASS1_VIOLATION             rust fence, value-expression, no `..` (must use ::new())
#   CLASS3_ASCII_ELLIPSIS        prose/formal, `...` (three ASCII dots) as field-elision
#   CLASS3_UNICODE_ELLIPSIS      prose/formal, `…` (U+2026) in field-elision position
#   CLASS3_MISSING_DOTS          prose/formal, no elision marker, partial fields (add `..`)
#
# EXCLUSION BUCKETS (Step 0 — skipped from further classification)
#   EXEMPT                       frontmatter + ## Changelog regions (changelog_exempt_lines)
#   EXCLUDED_ILLUSTRATION        <!-- discriminator:illustration-start/end --> regions
#   EXCLUDED_DECL                pub struct PregolyaError / impl PregolyaError openers
#   CLASS0_EXEMPT                type-schema form: component: Component, immediately after {
#   EXCLUDED_BASH                inside ```bash or ```sh fence
#   EXCLUDED_PATTERN_REF         { immediately followed by ` (backtick pattern-name cite)
#   EXCLUDED_DOC_COMMENT         /// line inside ```rust fence
#   EXCLUDED_NO_CLOSE            span unclosed within 15-line lookahead
#
# VALID BUCKETS
#   CLASS2_VALID                 rust fence, `..` rest pattern present
#   CLASS4_VALID                 BC-2.14.001 / BC-2.14.002 defining-crate exception
#   CLASS3_VALID                 prose/formal, `..` present
#   CLASS3_VALID_COMPLETE        prose/formal, all 5 non-source fields present (no `..` needed)
#
# SHARED MODULE — spec_region_utils.py
# ─────────────────────────────────────
# Functions consumed (no parallel reimplementation):
#   changelog_exempt_lines()      frontmatter + ## Changelog detection
#   illustration_exempt_lines()   <!-- discriminator:illustration-start/end --> detection
#   find_pregolya_error_openers() single-line and split-line opener detection
#
# SELF-PROBES (6 mandatory)
# ─────────────────────────
#   1. Each violation sub-class (CLASS1, ASCII_ELLIPSIS, UNICODE_ELLIPSIS, MISSING_DOTS) detected
#   2. CLASS3_VALID_COMPLETE NOT flagged
#   3. Changelog line quoting `...` → `..` NOT flagged
#   4. pub struct / impl PregolyaError NOT flagged
#   5. Split-line opener correctly classified
#   6. ADR-010 itself reports ZERO violations
#
# TD-VSDD-091: findings cite "file :: symbol"; no file:NNN line-number citations.
#
# Usage:  bash .factory/hooks/verify-error-notation-canon.sh
# Exit:   0 if no FAIL; 1 if any FAIL.
#
# Integration: wired as BLOCKING in pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
SPECS_DIR="$FACTORY_DIR/specs"
ADR010="$SPECS_DIR/architecture/decisions/ADR-010-error-taxonomy-anyhow-confinement.md"

PASS=0
WARN=0
FAIL=0
BLOCKING_FAIL=0
ADVISORY_WARN=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)); ADVISORY_WARN=$((ADVISORY_WARN + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)); BLOCKING_FAIL=$((BLOCKING_FAIL + 1)) ;;
  esac
}

# ── Core Python scanner ───────────────────────────────────────────────────────
# Arguments: <hooks_dir> <scan_dir>
# Output lines:
#   TOTAL <n>                     total PregolyaError { openers found
#   BUCKET <name> <n>             bucket count
#   VIOLATION <class> <rel_path>  one line per violation occurrence
run_notation_scanner() {
  local hooks_dir="$1" scan_dir="$2"
  python3 - "$hooks_dir" "$scan_dir" <<'PYEOF'
import sys, glob, re, os

hooks_dir = sys.argv[1]
scan_dir  = sys.argv[2]
sys.path.insert(0, hooks_dir)
from spec_region_utils import (
    changelog_exempt_lines,
    illustration_exempt_lines,
    find_pregolya_error_openers,
)

# ── Compiled patterns ─────────────────────────────────────────────────────────
# Two-dot rest pattern NOT part of three-dot (lookbehind/lookahead on '.')
TWO_DOT_RE          = re.compile(r'(?<!\.)\.\.(?!\.)')
# Three ASCII dots — forbidden field-elision marker (Class 3)
THREE_DOT_RE        = re.compile(r'\.\.\.')
# Unicode ellipsis U+2026 in field-elision position: after , or { (plus optional whitespace)
UNICODE_ELISION_RE  = re.compile(r'[,{]\s*…')
# CLASS0_EXEMPT: type-schema form — { component: Component, (TYPE name, not VALUE)
CLASS0_RE           = re.compile(r'\{\s*component\s*:\s*Component\s*,')
# EXCLUDED_DECL: struct declaration or impl block — check opener_line text
DECL_RE             = re.compile(r'\b(?:pub\s+struct|impl)\s+PregolyaError\b')
# CLASS4 defining-crate file detection (word-boundary on the BC number)
CLASS4_FILE_RE      = re.compile(r'BC-2\.14\.00[12]\b')
# Five non-source observable fields
FIVE_FIELDS         = ['component', 'category', 'retry_hint', 'code', 'message']
FIELD_RE            = {f: re.compile(rf'\b{re.escape(f)}\s*[=:]') for f in FIVE_FIELDS}

# ── Fence-context builder ─────────────────────────────────────────────────────
def build_fence_context(lines):
    """Return list[str|None]: 'rust', 'bash', or None per line index."""
    ctx      = [None] * len(lines)
    in_fence = False
    ftype    = None
    for i, raw in enumerate(lines):
        s = raw.strip()
        if not in_fence:
            if s.startswith('```'):
                label = s[3:].lower().strip().split(',')[0].strip()
                if label == 'rust':
                    ftype = 'rust'
                elif label in ('bash', 'sh'):
                    ftype = 'bash'
                else:
                    ftype = 'other'
                in_fence = True
                ctx[i] = ftype
        else:
            ctx[i] = ftype
            if s == '```':
                in_fence = False
                ftype = None
    return ctx

# ── Span extractor ────────────────────────────────────────────────────────────
def extract_span(lines, opener):
    """
    Extract text from the PregolyaError { opening brace to its matching },
    using up to 15-line lookahead.  Returns (span_text, closed).
    span_text begins at the { character on brace_line.
    """
    brace_line = opener['brace_line']
    form       = opener['form']
    bl         = lines[brace_line]

    if form == 'single':
        m = re.search(r'PregolyaError\s+\{', bl)
        if not m:
            return '', False
        start = m.end() - 1          # index of '{' in bl
    else:  # split
        m = re.search(r'\{', bl)
        if not m:
            return '', False
        start = m.start()

    # Character-by-character brace tracking stops exactly at the matching '}'.
    # Counting '{'/'}' over the whole seg tail is wrong when the matching '}'
    # is followed by more text on the same line (e.g. table cell suffix) that
    # could contain unrelated '...' or other false-trigger patterns.
    span  = ''
    depth = 0
    for line_idx in range(brace_line, min(brace_line + 16, len(lines))):
        seg = lines[line_idx] if line_idx > brace_line else lines[line_idx][start:]
        for ch in seg:
            span += ch
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    return span, True
    return span, False

# ── Field helpers ─────────────────────────────────────────────────────────────
def _strip_quoted(text):
    """Remove contents of double-quoted strings to avoid false matches inside values."""
    return re.sub(r'"[^"\n]*"', '""', text)

def has_two_dot(span):
    return bool(TWO_DOT_RE.search(_strip_quoted(span)))

def has_three_dot(span):
    return bool(THREE_DOT_RE.search(_strip_quoted(span)))

def has_unicode_elision(span):
    return bool(UNICODE_ELISION_RE.search(_strip_quoted(span)))

def all_five_fields(span):
    return all(FIELD_RE[f].search(span) for f in FIVE_FIELDS)

# ── Main scan ─────────────────────────────────────────────────────────────────
files = sorted(glob.glob(f'{scan_dir}/**/*.md', recursive=True))

buckets = {
    'EXEMPT'                           : 0,
    'EXCLUDED_ILLUSTRATION'            : 0,
    'EXCLUDED_DECL'                    : 0,
    'CLASS0_EXEMPT'                    : 0,
    'EXCLUDED_BASH'                    : 0,
    'EXCLUDED_PATTERN_REF'             : 0,
    'EXCLUDED_DOC_COMMENT'             : 0,
    'EXCLUDED_NO_CLOSE'                : 0,
    'CLASS2_VALID'                     : 0,
    'CLASS4_VALID'                     : 0,
    'CLASS3_VALID'                     : 0,
    'CLASS3_VALID_COMPLETE'            : 0,
    'CLASS1_VIOLATION'                 : 0,
    'CLASS3_ASCII_ELLIPSIS_VIOLATION'  : 0,
    'CLASS3_UNICODE_ELLIPSIS_VIOLATION': 0,
    'CLASS3_MISSING_DOTS_VIOLATION'    : 0,
}

total_openers = 0
violations    = []  # list of (class_tag, rel_path)

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    if 'PregolyaError' not in ''.join(lines):
        continue

    rel            = f.replace(scan_dir.rstrip('/') + '/', '')
    basename       = os.path.basename(f)
    is_class4_file = bool(CLASS4_FILE_RE.search(basename))

    cl_exempt  = changelog_exempt_lines(lines)
    ill_exempt = illustration_exempt_lines(lines)
    fence_ctx  = build_fence_context(lines)

    for opr in find_pregolya_error_openers(lines):
        total_openers += 1
        ol = opr['opener_line']

        # Step 0a — EXEMPT (frontmatter / ## Changelog)
        if ol in cl_exempt:
            buckets['EXEMPT'] += 1
            continue

        # Step 0b — EXCLUDED_ILLUSTRATION
        if ol in ill_exempt:
            buckets['EXCLUDED_ILLUSTRATION'] += 1
            continue

        # Step 0c — EXCLUDED_DECL (pub struct / impl, single or split-line)
        if DECL_RE.search(lines[ol]):
            buckets['EXCLUDED_DECL'] += 1
            continue

        # Step 0d — EXCLUDED_BASH
        if fence_ctx[ol] == 'bash':
            buckets['EXCLUDED_BASH'] += 1
            continue

        # Extract span (needed for all remaining checks)
        span, closed = extract_span(lines, opr)

        # Step 0e — EXCLUDED_PATTERN_REF: { immediately followed by `
        # span[0] == '{'; span[1] is the char right after '{'
        if len(span) > 1 and span[1] == '`':
            buckets['EXCLUDED_PATTERN_REF'] += 1
            continue

        # Step 0f — EXCLUDED_NO_CLOSE: span unclosed within 15-line lookahead
        if not closed:
            buckets['EXCLUDED_NO_CLOSE'] += 1
            continue

        # Step 0g — CLASS0_EXEMPT: type-schema form (component: Component,)
        if CLASS0_RE.search(span):
            buckets['CLASS0_EXEMPT'] += 1
            continue

        # Step 0h — EXCLUDED_DOC_COMMENT: /// line inside ```rust fence
        if fence_ctx[ol] == 'rust' and lines[ol].lstrip().startswith('///'):
            buckets['EXCLUDED_DOC_COMMENT'] += 1
            continue

        # Step 1 — Fence context
        rust_fence = (fence_ctx[ol] == 'rust')

        # Step 2 — Classify
        if rust_fence:
            if has_two_dot(span):
                buckets['CLASS2_VALID'] += 1
            elif is_class4_file:
                buckets['CLASS4_VALID'] += 1
            else:
                buckets['CLASS1_VIOLATION'] += 1
                violations.append(('CLASS1_VIOLATION', rel))
        else:  # prose or non-rust formal fence
            if has_two_dot(span):
                buckets['CLASS3_VALID'] += 1
            elif has_three_dot(span):
                buckets['CLASS3_ASCII_ELLIPSIS_VIOLATION'] += 1
                violations.append(('CLASS3_ASCII_ELLIPSIS_VIOLATION', rel))
            elif has_unicode_elision(span):
                buckets['CLASS3_UNICODE_ELLIPSIS_VIOLATION'] += 1
                violations.append(('CLASS3_UNICODE_ELLIPSIS_VIOLATION', rel))
            elif all_five_fields(span):
                buckets['CLASS3_VALID_COMPLETE'] += 1
            else:
                buckets['CLASS3_MISSING_DOTS_VIOLATION'] += 1
                violations.append(('CLASS3_MISSING_DOTS_VIOLATION', rel))

# ── Emit output ───────────────────────────────────────────────────────────────
print(f'TOTAL {total_openers}')
for k, v in buckets.items():
    print(f'BUCKET {k} {v}')
for vtag, vrel in violations:
    print(f'VIOLATION {vtag} {vrel}')
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

# ── Probe 1: Violation sub-classes are detected ───────────────────────────────

probe_class1_violation() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p1"
  cat > "$PROBE_TMP/p1/probe.md" <<'PROBEOF'
## Description

```rust
fn example() -> Result<(), PregolyaError> {
    return Err(PregolyaError { code: "E-CORE-001", category: VAL });
}
```
PROBEOF
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p1")"
  if ! echo "$out" | grep -qF 'VIOLATION CLASS1_VIOLATION'; then
    echo "[SELF-PROBE FAIL] Probe 1a: CLASS1_VIOLATION (rust fence, no ..) not detected."
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 1a: CLASS1_VIOLATION detected in rust fence."
}

probe_class3_ascii_ellipsis() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p2"
  cat > "$PROBE_TMP/p2/probe.md" <<'PROBEOF'
## Description

Returns `Err(PregolyaError { code: "E-CORE-001", ... })` on bad input.
PROBEOF
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p2")"
  if ! echo "$out" | grep -qF 'VIOLATION CLASS3_ASCII_ELLIPSIS_VIOLATION'; then
    echo "[SELF-PROBE FAIL] Probe 1b: CLASS3_ASCII_ELLIPSIS_VIOLATION (three-dot) not detected."
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 1b: CLASS3_ASCII_ELLIPSIS_VIOLATION detected."
}

probe_class3_unicode_ellipsis() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p3"
  # U+2026 in field-elision position (after ,)
  printf '## Description\n\nReturns `Err(PregolyaError { code: "E-CORE-001", … })` on bad input.\n' \
    > "$PROBE_TMP/p3/probe.md"
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p3")"
  if ! echo "$out" | grep -qF 'VIOLATION CLASS3_UNICODE_ELLIPSIS_VIOLATION'; then
    echo "[SELF-PROBE FAIL] Probe 1c: CLASS3_UNICODE_ELLIPSIS_VIOLATION (U+2026 elision) not detected."
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 1c: CLASS3_UNICODE_ELLIPSIS_VIOLATION detected."
}

probe_class3_missing_dots() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p4"
  cat > "$PROBE_TMP/p4/probe.md" <<'PROBEOF'
## Description

Returns `Err(PregolyaError { code: "E-CORE-001" })` on bad input.
PROBEOF
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p4")"
  if ! echo "$out" | grep -qF 'VIOLATION CLASS3_MISSING_DOTS_VIOLATION'; then
    echo "[SELF-PROBE FAIL] Probe 1d: CLASS3_MISSING_DOTS_VIOLATION (missing .., partial fields) not detected."
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 1d: CLASS3_MISSING_DOTS_VIOLATION detected."
}

# ── Probe 2: CLASS3_VALID_COMPLETE not flagged ────────────────────────────────

probe_class3_valid_complete() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p5"
  cat > "$PROBE_TMP/p5/probe.md" <<'PROBEOF'
## Description

The full-field form `PregolyaError { component: MCP, category: TOOL, retry_hint: Never, code: "E-MCP-001", message: "connection lost" }` is CLASS3_VALID_COMPLETE.
PROBEOF
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p5")"
  # Check for actual violation output lines (start with VIOLATION <space>)
  if echo "$out" | grep -qE '^VIOLATION '; then
    echo "[SELF-PROBE FAIL] Probe 2: CLASS3_VALID_COMPLETE (all 5 fields) was incorrectly flagged."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if ! echo "$out" | grep -qF 'BUCKET CLASS3_VALID_COMPLETE 1'; then
    echo "[SELF-PROBE FAIL] Probe 2: CLASS3_VALID_COMPLETE not counted in bucket."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 2: CLASS3_VALID_COMPLETE (all 5 fields) not flagged as violation."
}

# ── Probe 3: Changelog quoting NOT flagged ────────────────────────────────────

probe_changelog_not_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p6"
  cat > "$PROBE_TMP/p6/probe.md" <<'PROBEOF'
---
document_type: bc
version: "1.1"
changelog:
  - "1.0 (2026-07-28): initial."
  - "1.1 (2026-07-29): replaced `PregolyaError { code: \"E-X\", ... }` with `PregolyaError { code: \"E-X\", .. }` (CLASS3_ASCII_ELLIPSIS_VIOLATION fix)."
---

## Description

This section has no violations.
PROBEOF
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p6")"
  if echo "$out" | grep -qE '^VIOLATION '; then
    echo "[SELF-PROBE FAIL] Probe 3: changelog line quoting '...' was incorrectly flagged."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 3: changelog quoting '...' not flagged (EXEMPT)."
}

# ── Probe 4: pub struct / impl NOT flagged ────────────────────────────────────

probe_decl_not_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p7"
  cat > "$PROBE_TMP/p7/probe.md" <<'PROBEOF'
```rust
pub struct PregolyaError {
    pub component: Component,
    pub code: &'static str,
}

impl PregolyaError {
    pub fn new() -> Self { todo!() }
}
```
PROBEOF
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p7")"
  if echo "$out" | grep -qE '^VIOLATION '; then
    echo "[SELF-PROBE FAIL] Probe 4: pub struct PregolyaError { or impl PregolyaError { was incorrectly flagged."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 4: pub struct PregolyaError / impl PregolyaError not flagged (EXCLUDED_DECL)."
}

# ── Probe 5: Split-line opener correctly classified ───────────────────────────

probe_split_line() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p8"
  # Split-line opener: PregolyaError at end of line, { on next line with ..
  cat > "$PROBE_TMP/p8/probe.md" <<'PROBEOF'
## Description

Returns `Err(PregolyaError
{ code: "E-CORE-001", .. })` when validation fails.
PROBEOF
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p8")"
  if echo "$out" | grep -qE '^VIOLATION '; then
    echo "[SELF-PROBE FAIL] Probe 5: split-line opener with valid '..' was incorrectly flagged."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  # Verify it was actually detected (CLASS3_VALID, not silently skipped)
  if ! echo "$out" | grep -qF 'BUCKET CLASS3_VALID 1'; then
    echo "[SELF-PROBE FAIL] Probe 5: split-line opener with '..' not counted as CLASS3_VALID."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  # Now test that a split-line VIOLATION is also detected
  mkdir -p "$PROBE_TMP/p8v"
  cat > "$PROBE_TMP/p8v/probe.md" <<'PROBEOF'
## Description

Returns `Err(PregolyaError
{ code: "E-CORE-001" })` when validation fails.
PROBEOF
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p8v")"
  if ! echo "$out" | grep -qF 'VIOLATION CLASS3_MISSING_DOTS_VIOLATION'; then
    echo "[SELF-PROBE FAIL] Probe 5: split-line violation (no ..) not detected."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 5: split-line opener: valid form detected as CLASS3_VALID; violation form detected as CLASS3_MISSING_DOTS_VIOLATION."
}

# ── Probe 6: ADR-010 reports zero violations ──────────────────────────────────

probe_adr010_zero_violations() {
  if [ ! -f "$ADR010" ]; then
    echo "[SELF-PROBE SKIP] Probe 6: ADR-010 not found at expected path — skipping ADR self-check."
    return
  fi
  init_probe_tmp
  mkdir -p "$PROBE_TMP/p9"
  cp "$ADR010" "$PROBE_TMP/p9/"
  local out
  out="$(run_notation_scanner "$HOOKS_DIR" "$PROBE_TMP/p9")"
  local viol_count
  viol_count="$(echo "$out" | grep -c '^VIOLATION' || true)"
  if [ "$viol_count" -ne 0 ]; then
    echo "[SELF-PROBE FAIL] Probe 6: ADR-010 has ${viol_count} violation(s) — the canon self-flags."
    echo "  The illustration regions (<!-- discriminator:illustration-start/end -->) must be honoured."
    echo "  Violations:"
    echo "$out" | grep '^VIOLATION' | while IFS= read -r line; do echo "    $line"; done
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] Probe 6: ADR-010 reports zero violations (illustration regions correctly excluded)."
}

# ── Main notation check ───────────────────────────────────────────────────────

check_notation() {
  local scan_dir="${1:-$SPECS_DIR}"

  local raw_output
  raw_output="$(run_notation_scanner "$HOOKS_DIR" "$scan_dir")"

  local total_openers=0
  declare -A bkt
  local violation_lines=()

  while IFS= read -r line; do
    case "$line" in
      TOTAL\ *)
        total_openers="${line#TOTAL }"
        ;;
      BUCKET\ *)
        local name val
        name="${line#BUCKET }"
        val="${name##* }"
        name="${name% *}"
        bkt["$name"]="$val"
        ;;
      VIOLATION\ *)
        violation_lines+=("${line#VIOLATION }")
        ;;
    esac
  done <<< "$raw_output"

  local total_violations=0
  total_violations=$(( ${bkt[CLASS1_VIOLATION]:-0}
                     + ${bkt[CLASS3_ASCII_ELLIPSIS_VIOLATION]:-0}
                     + ${bkt[CLASS3_UNICODE_ELLIPSIS_VIOLATION]:-0}
                     + ${bkt[CLASS3_MISSING_DOTS_VIOLATION]:-0} ))

  # ── Partition table ────────────────────────────────────────────────────────
  local bucket_sum=0
  for k in EXEMPT EXCLUDED_ILLUSTRATION EXCLUDED_DECL CLASS0_EXEMPT \
            EXCLUDED_BASH EXCLUDED_PATTERN_REF EXCLUDED_DOC_COMMENT EXCLUDED_NO_CLOSE \
            CLASS2_VALID CLASS4_VALID CLASS3_VALID CLASS3_VALID_COMPLETE \
            CLASS1_VIOLATION CLASS3_ASCII_ELLIPSIS_VIOLATION \
            CLASS3_UNICODE_ELLIPSIS_VIOLATION CLASS3_MISSING_DOTS_VIOLATION; do
    bucket_sum=$(( bucket_sum + ${bkt[$k]:-0} ))
  done

  echo "  Bucket partition (total openers found: ${total_openers}):"
  echo "    ── Exclusion buckets (Step 0) ──────────────────────────────────────"
  printf "    %-44s %d\n" "EXEMPT (frontmatter + changelog):"      "${bkt[EXEMPT]:-0}"
  printf "    %-44s %d\n" "EXCLUDED_ILLUSTRATION:"                  "${bkt[EXCLUDED_ILLUSTRATION]:-0}"
  printf "    %-44s %d\n" "EXCLUDED_DECL (struct/impl):"           "${bkt[EXCLUDED_DECL]:-0}"
  printf "    %-44s %d\n" "CLASS0_EXEMPT (type-schema):"            "${bkt[CLASS0_EXEMPT]:-0}"
  printf "    %-44s %d\n" "EXCLUDED_BASH:"                          "${bkt[EXCLUDED_BASH]:-0}"
  printf "    %-44s %d\n" "EXCLUDED_PATTERN_REF:"                   "${bkt[EXCLUDED_PATTERN_REF]:-0}"
  printf "    %-44s %d\n" "EXCLUDED_DOC_COMMENT:"                   "${bkt[EXCLUDED_DOC_COMMENT]:-0}"
  printf "    %-44s %d\n" "EXCLUDED_NO_CLOSE:"                      "${bkt[EXCLUDED_NO_CLOSE]:-0}"
  echo "    ── Valid buckets ───────────────────────────────────────────────────"
  printf "    %-44s %d\n" "CLASS2_VALID (rust fence, ..present):"  "${bkt[CLASS2_VALID]:-0}"
  printf "    %-44s %d\n" "CLASS4_VALID (defining-crate):"         "${bkt[CLASS4_VALID]:-0}"
  printf "    %-44s %d\n" "CLASS3_VALID (prose, .. present):"      "${bkt[CLASS3_VALID]:-0}"
  printf "    %-44s %d\n" "CLASS3_VALID_COMPLETE (all 5 fields):"  "${bkt[CLASS3_VALID_COMPLETE]:-0}"
  echo "    ── Violation buckets ───────────────────────────────────────────────"
  printf "    %-44s %d\n" "CLASS1_VIOLATION (rust, no ..):"        "${bkt[CLASS1_VIOLATION]:-0}"
  printf "    %-44s %d\n" "CLASS3_ASCII_ELLIPSIS_VIOLATION (...):" "${bkt[CLASS3_ASCII_ELLIPSIS_VIOLATION]:-0}"
  printf "    %-44s %d\n" "CLASS3_UNICODE_ELLIPSIS_VIOLATION (U+2026):" "${bkt[CLASS3_UNICODE_ELLIPSIS_VIOLATION]:-0}"
  printf "    %-44s %d\n" "CLASS3_MISSING_DOTS_VIOLATION:"         "${bkt[CLASS3_MISSING_DOTS_VIOLATION]:-0}"
  echo "    ────────────────────────────────────────────────────────────────────"
  printf "    %-44s %d\n" "VIOLATIONS TOTAL:"                       "${total_violations}"
  printf "    %-44s %d\n" "BUCKET SUM:"                             "${bucket_sum}"
  printf "    %-44s %d\n" "TOTAL OPENERS (from scanner):"           "${total_openers}"

  if [ "${bucket_sum}" -ne "${total_openers}" ]; then
    echo "    [WARNING] Bucket sum (${bucket_sum}) != total openers (${total_openers}) — unaccounted remainder!"
  fi

  if [ "${total_violations}" -gt 0 ]; then
    echo ""
    echo "  Per-file violations:"
    declare -A vfile_counts
    declare -A vfile_classes
    for entry in "${violation_lines[@]}"; do
      local vclass vpath
      vclass="${entry%% *}"
      vpath="${entry#* }"
      vfile_counts["$vpath"]=$(( ${vfile_counts[$vpath]:-0} + 1 ))
      if [ -n "${vfile_classes[$vpath]:-}" ]; then
        vfile_classes["$vpath"]="${vfile_classes[$vpath]}, ${vclass}"
      else
        vfile_classes["$vpath"]="${vclass}"
      fi
    done
    for vpath in "${!vfile_counts[@]}"; do
      local cnt="${vfile_counts[$vpath]}"
      local classes="${vfile_classes[$vpath]}"
      echo "    $vpath :: PregolyaError — ${cnt} violation(s) [${classes}]"
    done
  fi

  if [ "${total_violations}" -gt 0 ]; then
    local n_files
    n_files="$(printf '%s\n' "${violation_lines[@]}" | awk '{print $NF}' | sort -u | wc -l | tr -d ' ')"
    emit FAIL "N1 (ADR-010): error-construction notation — ${total_violations} violation(s) across ${n_files} file(s)"
    echo "  Routing guide (TD-VSDD-091: symbol/section cites; no line numbers):"
    echo "    CLASS1_VIOLATION           → product-owner/architect: replace struct literal with"
    echo "                                 PregolyaError::new(...) inside rust fences"
    echo "    CLASS3_ASCII_ELLIPSIS      → product-owner: replace '...' with '..' in observation"
    echo "    CLASS3_UNICODE_ELLIPSIS    → product-owner: replace '…' (U+2026) with '..' in observation"
    echo "    CLASS3_MISSING_DOTS        → product-owner: add '..' before closing '}'"
  else
    emit PASS "N1 (ADR-010): error-construction notation canon — corpus clean (${total_violations} violations, bucket sum ${bucket_sum})"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-error-notation-canon: ADR-010 error-construction notation canon"
echo "  SPECS_DIR: $SPECS_DIR"
echo "  Decisions: D-72 (error-construction notation) / ADR-010 v1.14+"
echo "  Classes: CLASS1 (rust fence) | CLASS3 ASCII/Unicode/Missing (prose/formal)"
echo ""

echo "[SELF-PROBE] Verifying all violation sub-classes and exemptions..."
probe_class1_violation
probe_class3_ascii_ellipsis
probe_class3_unicode_ellipsis
probe_class3_missing_dots
probe_class3_valid_complete
probe_changelog_not_flagged
probe_decl_not_flagged
probe_split_line
probe_adr010_zero_violations
echo "[SELF-PROBE] All probes passed — checks are not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "BLOCKING rules"
echo "════════════════════════════════════════════"
echo ""
echo "── N1 (ADR-010 D-72): error-construction notation canon ────────────────"
check_notation "$SPECS_DIR"

echo ""
echo "════════════════════════════════════════════"

echo ""
echo "verify-error-notation-canon: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  BLOCKING: $BLOCKING_FAIL FAIL(s)"
echo "  ADVISORY: $ADVISORY_WARN WARN(s)"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "RESULT: FAIL"
  exit 1
else
  echo ""
  echo "RESULT: PASS"
  exit 0
fi
