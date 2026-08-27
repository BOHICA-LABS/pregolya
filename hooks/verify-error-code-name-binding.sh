#!/usr/bin/env bash
# verify-error-code-name-binding.sh — pregolya advisory validator
#
# PURPOSE
# ───────
# Catches the F-P2A067-01 violation class: an ADR, BC, or story spec cites
# an error code of the form `E-XXX-NNN SomeName` where `SomeName` does NOT
# match any canonical name registered in error-taxonomy.md for that code.
#
# Canonical name definition: all PascalCase words of the form `Name:` (backtick
# immediately before, colon immediately after, not double-colon) inside the
# backtick-quoted message string(s) in the error-taxonomy.md pipe-table row for
# that code.  Multi-message codes (e.g. E-CHKPT-008) carry more than one valid
# name; ALL of them are accepted.
# Only codes whose messages contain at least one `Name:` token are entered in
# the map; codes with plain-sentence messages (no `Name:` opener) are not checked.
#
# FALSE-POSITIVE GUARDS
# ─────────────────────
# The scanner skips three classes of tokens that follow an error code but are
# NOT name claims:
#
#   1. Category tokens  — `E-CODE <CATEGORY>` where <CATEGORY> is in the set
#      of Category Code values defined in error-taxonomy.md's Error Categories
#      table (e.g. INTERNAL, POLICY, TOOL, VAL, EXEC, TIMEOUT, TRANSPORT, ...).
#      The set is derived DYNAMICALLY at runtime so it stays current as new
#      categories are added.  Also covers SCREAMING_CASE tokens that are
#      identifiers (isupper() guard) — catches planning-doc label tokens.
#
#   2. Multi-message codes — codes like E-CHKPT-008 carry two `Name:` tokens
#      in their message column (FtsLimitZero and FtsQuerySyntaxError).  The
#      scanner parses ALL `Name:` tokens and accepts any of them as valid.
#
#   3. Hyphenated-compound tokens — `E-SBXD-001 BC-2.13.004` would naively
#      produce cited=BC; the citation regex now requires the matched word NOT
#      be immediately followed by a hyphen, so compound identifiers like
#      `BC-2.13.004` and `CODE-SPECIFIC` are silently skipped.
#
# SCOPE
# ─────
# Source of truth:  .factory/specs/prd-supplements/error-taxonomy.md
# Scanned files:    .factory/specs/**/*.md (BCs, ADRs, arch docs)
#                   .factory/stories/**/*.md (story specs)
# Excluded:         frontmatter (between --- delimiters) and ## Changelog sections
#                   (where historical names may be referenced legitimately).
#                   The taxonomy file itself (source, not a citation site).
#                   Cross-table-cell citations (E-code and name in separate | cells)
#                   are not caught; inline/prose/same-cell citations are the target.
#
# ADVISORY: exits 0 always. Findings are printed as [WARN] lines.
# Do NOT wire as blocking — advisory class only (F-P2A067-01).
# Promotion to blocking requires human authorization.
#
# SELF-PROBE (POL-31)
# ───────────────────
# Synthetic fixtures exercised before live scan:
#   probe_must_detect:            E-CORE-001 WrongName → WARN fired (StrictContentBlockValidation)
#   probe_must_not_detect:        E-CORE-001 StrictContentBlockValidation → not flagged (correct)
#   probe_code_not_in_map:        E-CORE-002 AnythingAtAll → not flagged (no Name: token in map)
#   probe_changelog_exempt:       E-CORE-001 WrongName inside ## Changelog → not flagged
#   probe_double_colon_not_stolen: double-colon not confused for Name: token
#   probe_category_annotation:    E-CODE CATEGORY_TOKEN → not flagged (FP-hardening)
#   probe_multi_message_code:     secondary Name: in multi-message code → not flagged (FP-hardening)
#   probe_hyphenated_compound:    E-CODE BC-N.NN.NNN → BC not flagged (FP-hardening)
# POL-30: probe fixtures live in $TMPDIR, never under .factory/specs/ or .factory/stories/.
#
# EXIT CONTRACT
# ─────────────
# Exit 0: always (advisory).
# Exit 2: self-probe failure (script bug — a check is false-green or false-red).
#
# Usage:  bash .factory/hooks/verify-error-code-name-binding.sh
# Called: standalone advisory check; NOT wired into pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
TAXONOMY_FILE="$FACTORY_DIR/specs/prd-supplements/error-taxonomy.md"
SPECS_DIR="$FACTORY_DIR/specs"
STORIES_DIR="$FACTORY_DIR/stories"

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
# Arguments: <taxonomy_file> <scan_dir> [<scan_dir2> ...]
# Output lines:
#   REGISTRY_COUNT <n>          total codes in the canonical-name map
#   REGISTRY <code> <names>     one line per registered code; names are space-separated
#   CATEGORIES <tok1> <tok2>... all category tokens derived from taxonomy
#   MISMATCH <rel_path> <code> cited=<name> canonical=<name1>[,<name2>...]
#   SCAN_FILES <n>              total .md files scanned
run_binding_scanner() {
  local taxonomy_file="$1"
  shift
  local scan_dirs=("$@")
  python3 - "$taxonomy_file" "${scan_dirs[@]}" <<'PYEOF'
import sys, re, glob, os

taxonomy_file = sys.argv[1]
scan_dirs     = sys.argv[2:]

# ── Taxonomy parser ───────────────────────────────────────────────────────────
# Pipe-table row: | E-CODE | CAT | SEV | BC | `Name: message text` |
# Code is at split-index 1; category at split-index 2; message column at split-index 5.
#
# Category set: derived from any pipe-table row whose first column is all-uppercase
# letters only (the Error Categories table rows: VAL, AUTH, RATE, …).
# Error code rows start with E-COMP-NNN (contains hyphens/digits — never purely [A-Z]+).
#
# Multi-message codes: the message column may contain more than one backtick-quoted
# segment, each starting with `Name: …`.  All are collected; any is a valid name.
#
E_CODE_ROW_RE = re.compile(r'^\|\s*(E-[A-Z]+-\d+)\s*\|')
CAT_ROW_RE    = re.compile(r'^\|\s*([A-Z]{2,})\s*\|')   # 2+ uppercase letters only
# All Name: tokens in message column — not anchored to start, finds all occurrences
MSG_NAME_RE   = re.compile(r'`([A-Z][A-Za-z0-9]+):(?!:)')

category_tokens = set()
code_to_names   = {}   # code -> frozenset of valid names

try:
    with open(taxonomy_file, 'r', encoding='utf-8') as fh:
        for line in fh:
            # ── Collect category tokens ──────────────────────────────────────
            cat_m = CAT_ROW_RE.match(line)
            if cat_m:
                tok = cat_m.group(1)
                # Exclude pipe-table header tokens that look all-caps but are
                # not real categories (none expected; guard anyway).
                # All real category codes are 2-14 uppercase letters.
                if 2 <= len(tok) <= 14:
                    category_tokens.add(tok)

            # ── Collect error code → name(s) mapping ─────────────────────────
            m = E_CODE_ROW_RE.match(line)
            if not m:
                continue
            code = m.group(1)
            parts = line.split('|')
            if len(parts) < 7:
                continue
            # Also add the category field itself to category_tokens (column 2)
            cat_field = parts[2].strip()
            if cat_field and re.match(r'^[A-Z]{2,14}$', cat_field):
                category_tokens.add(cat_field)
            msg_col = parts[5].strip()
            names = MSG_NAME_RE.findall(msg_col)
            if names:
                code_to_names[code] = frozenset(names)
except FileNotFoundError:
    pass

print(f'REGISTRY_COUNT {len(code_to_names)}')
for code, names in sorted(code_to_names.items()):
    print(f'REGISTRY {code} {" ".join(sorted(names))}')
cats_line = ' '.join(sorted(category_tokens)) if category_tokens else '(none)'
print(f'CATEGORIES {cats_line}')

# ── Citation scanner ──────────────────────────────────────────────────────────
# Pattern: E-PREFIX-NNN followed by whitespace and a PascalCase word.
# The (?!-) lookahead prevents matching hyphenated compound tokens such as
# `BC` in `BC-2.13.004` or `CODE` in `CODE-SPECIFIC`.
# Excludes: frontmatter (---..---), ## Changelog sections.
E_CODE_CITE_RE = re.compile(r'\b(E-[A-Z]+-\d+)\s+([A-Z][A-Za-z0-9]+)(?!-)\b')

total_files = 0
for scan_dir in scan_dirs:
    files = sorted(glob.glob(f'{scan_dir}/**/*.md', recursive=True))
    taxonomy_abs = os.path.abspath(taxonomy_file)
    for f in files:
        if os.path.abspath(f) == taxonomy_abs:
            continue
        total_files += 1
        rel = f.replace(scan_dir.rstrip('/') + '/', '')
        try:
            with open(f, 'r', encoding='utf-8') as fh:
                lines = fh.readlines()
        except OSError:
            continue

        in_frontmatter = False
        fm_count       = 0
        in_changelog   = False

        for line in lines:
            stripped = line.strip()
            if stripped == '---':
                fm_count += 1
                if fm_count <= 2:
                    in_frontmatter = (fm_count == 1)
                continue
            if in_frontmatter:
                continue

            if re.match(r'^## Changelog', line):
                in_changelog = True
                continue
            if re.match(r'^## ', line) and in_changelog:
                in_changelog = False
            if in_changelog:
                continue

            for m in E_CODE_CITE_RE.finditer(line):
                code       = m.group(1)
                cited_name = m.group(2)

                # FP guard 1: skip category tokens (derived dynamically) and
                # any all-uppercase SCREAMING_CASE identifier (label tokens).
                if cited_name in category_tokens or cited_name.isupper():
                    continue

                # Code not in name map — no canonical name to check against.
                if code not in code_to_names:
                    continue

                # FP guard 2: multi-message codes — accept any registered name.
                if cited_name in code_to_names[code]:
                    continue

                canonical_display = ','.join(sorted(code_to_names[code]))
                print(f'MISMATCH {rel} {code} cited={cited_name} canonical={canonical_display}')

print(f'SCAN_FILES {total_files}')
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

# Helper: run the scanner against a probe taxonomy file + probe scan dir.
# Returns all MISMATCH lines (or empty if none).
run_probe_scan() {
  local probe_taxonomy="$1"
  local probe_scan_dir="$2"
  run_binding_scanner "$probe_taxonomy" "$probe_scan_dir" | grep '^MISMATCH' || true
}

# ── Self-probe 1: mismatch MUST be detected ───────────────────────────────────
probe_must_detect_mismatch() {
  init_probe_tmp
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| VAL | Validation | Input shape | Never |

## Error Codes

| E-CORE-001 | VAL | broken | BC-2.01.001 | `StrictContentBlockValidation: block at position <n>` |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Postconditions

Raises E-CORE-001 WrongName when the content block is invalid.
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -z "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_must_detect_mismatch: E-CORE-001 WrongName was NOT flagged."
    echo "  Expected a MISMATCH line with canonical=StrictContentBlockValidation."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$mismatches" | grep -qF 'canonical=StrictContentBlockValidation'; then
    echo "[SELF-PROBE FAIL] probe_must_detect_mismatch: MISMATCH found but wrong canonical name."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_must_detect_mismatch: wrong name for E-CORE-001 is detected."
}

# ── Self-probe 2: correct citation MUST NOT be flagged ────────────────────────
probe_must_not_detect_correct() {
  init_probe_tmp
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| VAL | Validation | Input shape | Never |

## Error Codes

| E-CORE-001 | VAL | broken | BC-2.01.001 | `StrictContentBlockValidation: block at position <n>` |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Postconditions

Raises E-CORE-001 StrictContentBlockValidation when the content block is invalid.
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -n "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_must_not_detect_correct: correct citation was incorrectly flagged."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_must_not_detect_correct: correct E-CORE-001 citation not flagged."
}

# ── Self-probe 3: code without Name: token MUST NOT be flagged ────────────────
probe_code_not_in_map() {
  init_probe_tmp
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| VAL | Validation | Input shape | Never |

## Error Codes

| E-CORE-002 | VAL | broken | BC-2.01.002 | `Message role '<role>' is not a recognized message type` |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Postconditions

Raises E-CORE-002 AnyPascalName when the message role is unrecognized.
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -n "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_code_not_in_map: code without Name: token was incorrectly flagged."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_code_not_in_map: code without Name: token is not checked."
}

# ── Self-probe 4: ## Changelog lines MUST be exempt ──────────────────────────
probe_changelog_exempt() {
  init_probe_tmp
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| VAL | Validation | Input shape | Never |

## Error Codes

| E-CORE-001 | VAL | broken | BC-2.01.001 | `StrictContentBlockValidation: block at position <n>` |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Description

No violations here.

## Changelog

- "1.0 (2026-08-01): corrected E-CORE-001 OldWrongName to StrictContentBlockValidation."

## Postconditions

No violations here either.
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -n "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_changelog_exempt: ## Changelog citation was incorrectly flagged."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_changelog_exempt: wrong name in ## Changelog section is exempt."
}

# ── Self-probe 5: double-colon in message MUST NOT steal the Name token ───────
probe_double_colon_not_stolen() {
  init_probe_tmp
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| INTERNAL | Internal | Invariant violation | Never |

## Error Codes

| E-CORE-007 | INTERNAL | broken | BC-2.11.002 | `GuardrailHookPanic: GuardrailHook::evaluate panicked` |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Postconditions

Raises E-CORE-007 GuardrailHookPanic when the hook panics.
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -n "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_double_colon_not_stolen: GuardrailHookPanic was incorrectly flagged."
    echo "  Expected double-colon not to confuse the Name: extractor."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Postconditions

Raises E-CORE-007 GuardrailHook when the hook panics.
SPECEOF
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if ! echo "$mismatches" | grep -qF 'canonical=GuardrailHookPanic'; then
    echo "[SELF-PROBE FAIL] probe_double_colon_not_stolen: wrong name GuardrailHook not flagged as mismatch."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_double_colon_not_stolen: double-colon not stolen; Name: extracted correctly."
}

# ── Self-probe 6: category annotation MUST NOT be flagged (FP-hardening) ──────
# Pattern: E-CODE CATEGORY_TOKEN where CATEGORY_TOKEN is in the taxonomy
# Error Categories table.  E.g. E-GRAPH-002 POLICY→422, E-CORE-011 INTERNAL.
probe_category_annotation_exempt() {
  init_probe_tmp
  # Taxonomy with a category table AND a code that has a Name: token
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| VAL        | Validation | Input shape | Never |
| POLICY     | Policy     | Policy rejected the operation | Never |
| INTERNAL   | Internal   | Invariant violation | Never |
| TOOL       | Tool       | Tool execution error | Maybe |

## Error Codes

| E-GRAPH-002 | POLICY | broken | BC-2.05.005 | `NoActiveInterrupt: no interrupt is pending for run '<run_id>'` |
| E-CORE-011  | INTERNAL | broken | BC-2.01.006 | `RunnableParallelTaskPanic: task panicked: <detail>` |
| E-MCP-001   | TOOL | broken | BC-2.09.002 | `ToolException: tool '<tool>' raised exception: <message>` |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  # These patterns mirror what real specs contain:
  # E-GRAPH-002 POLICY→422 per-endpoint override
  # E-CORE-011 INTERNAL category rendered as INTERNAL
  # E-MCP-001 TOOL category — flag does not suppress
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Postconditions

HTTP 422 (E-GRAPH-002 POLICY→422 per-endpoint override; BC-2.14.002 PC-003).
The E-CORE-011 INTERNAL category renders as bare `Internal` corrected to ALL-CAPS.
Bare ToolException propagates as E-MCP-001 TOOL category — flag does not suppress.
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -n "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_category_annotation_exempt: category token after E-CODE was flagged as mismatch."
    echo "  These are legitimate category annotations, not name claims."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  # Also verify that a real wrong name IS still flagged in the same file
  cat >> "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'

Raises E-GRAPH-002 WrongName when there is no interrupt.
SPECEOF
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if ! echo "$mismatches" | grep -qF 'cited=WrongName'; then
    echo "[SELF-PROBE FAIL] probe_category_annotation_exempt: real mismatch WrongName was NOT flagged."
    echo "  The category-exempt guard must not suppress real mismatches."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_category_annotation_exempt: category annotations exempt; real mismatches still caught."
}

# ── Self-probe 7: multi-message code secondary name MUST NOT be flagged ───────
# Pattern: E-CHKPT-008 has two valid names: FtsLimitZero (leading) and
# FtsQuerySyntaxError (secondary).  Both must be accepted; wrong names must fire.
probe_multi_message_code() {
  init_probe_tmp
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| VAL | Validation | Input shape | Never |

## Error Codes

| E-CHKPT-008 | VAL | broken | BC-2.04.008 | `FtsLimitZero: FtsSearchConfig.limit must be > 0; got <limit>` (PC6/EC-004); also raised for malformed FTS5 query syntax: `FtsQuerySyntaxError: FTS5 query syntax error: <sqlite_error>` (EC-002) — both are VAL rejections. |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  # Cite the SECONDARY name — must NOT be flagged
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Error Conditions

EC-002: Raises E-CHKPT-008 FtsQuerySyntaxError when query syntax is invalid.
PC6: Raises E-CHKPT-008 FtsLimitZero when limit is zero.
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -n "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_multi_message_code: secondary name FtsQuerySyntaxError or FtsLimitZero was incorrectly flagged."
    echo "  Both names in a multi-message code are valid."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  # Cite a WRONG name — must be flagged
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Error Conditions

EC-003: Raises E-CHKPT-008 WrongSyntaxName when something is wrong.
SPECEOF
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if ! echo "$mismatches" | grep -qF 'cited=WrongSyntaxName'; then
    echo "[SELF-PROBE FAIL] probe_multi_message_code: wrong name WrongSyntaxName was NOT flagged for E-CHKPT-008."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_multi_message_code: secondary names accepted; wrong names still caught."
}

# ── Self-probe 8: hyphenated-compound tokens MUST NOT be flagged (FP-hardening)
# Pattern: E-SBXD-001 BC-2.13.004 → `BC` captured then rejected by (?!-) lookahead.
# Pattern: E-CHKPT-004 CODE-SPECIFIC → `CODE` captured then rejected by (?!-).
probe_hyphenated_compound_exempt() {
  init_probe_tmp
  cat > "$PROBE_TMP/taxonomy.md" <<'TAXEOF'
## Error Categories

| VAL | Validation | Input shape | Never |
| SECURITY | Security | Workspace escape | Never |

## Error Codes

| E-SBXD-001  | SECURITY | broken | BC-2.13.005 | `WorkspaceEscape: resolved path '<resolved>' escapes workspace root '<root>'` |
| E-CHKPT-004 | VAL | broken | BC-2.04.007 | `EncryptionKeyRotationFailed: <reason>` |
TAXEOF
  mkdir -p "$PROBE_TMP/spec"
  # These patterns mirror what bc-authoring-plan.md contains:
  # "E-SBXD-001 BC-2.13.004 (secondary" → would naive-match `BC`
  # "E-CHKPT-004 CODE-SPECIFIC" → would naive-match `CODE`
  cat > "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'
## Notes

anchored "in file" rather than "across ALL anchor BCs" — E-SBXD-001 BC-2.13.004 (secondary anchor).
`message` field alias (E-CHKPT-004 CODE-SPECIFIC — the entire constructed error message).
SPECEOF
  local mismatches
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if [ -n "$mismatches" ]; then
    echo "[SELF-PROBE FAIL] probe_hyphenated_compound_exempt: hyphenated compound token was incorrectly flagged."
    echo "  BC-2.13.004 should not produce cited=BC; CODE-SPECIFIC should not produce cited=CODE."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  # Verify real wrong name IS still flagged
  cat >> "$PROBE_TMP/spec/bc-probe.md" <<'SPECEOF'

Raises E-SBXD-001 PathConfinementViolation when path escapes.
SPECEOF
  mismatches="$(run_probe_scan "$PROBE_TMP/taxonomy.md" "$PROBE_TMP/spec")"
  if ! echo "$mismatches" | grep -qF 'cited=PathConfinementViolation'; then
    echo "[SELF-PROBE FAIL] probe_hyphenated_compound_exempt: real mismatch PathConfinementViolation was NOT flagged."
    echo "  Output: $mismatches"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_hyphenated_compound_exempt: hyphenated compounds exempt; real mismatches still caught."
}

# ── Main live check ───────────────────────────────────────────────────────────
check_error_code_name_binding() {
  if [ ! -f "$TAXONOMY_FILE" ]; then
    emit WARN "error-code-name-binding: taxonomy file not found at $TAXONOMY_FILE — skipping live scan"
    return
  fi

  local raw_output
  raw_output="$(run_binding_scanner "$TAXONOMY_FILE" "$SPECS_DIR" "$STORIES_DIR")"

  local registry_count=0
  local scan_files=0
  local categories_line=""
  local mismatch_lines=()

  while IFS= read -r line; do
    case "$line" in
      REGISTRY_COUNT\ *)  registry_count="${line#REGISTRY_COUNT }" ;;
      SCAN_FILES\ *)      scan_files="${line#SCAN_FILES }" ;;
      CATEGORIES\ *)      categories_line="${line#CATEGORIES }" ;;
      MISMATCH\ *)        mismatch_lines+=("${line#MISMATCH }") ;;
    esac
  done <<< "$raw_output"

  echo "  Registry: ${registry_count} codes with canonical Name: tokens"
  echo "  Scanned:  ${scan_files} .md files"
  echo "  Categories derived: ${categories_line}"
  echo ""

  if [ "${#mismatch_lines[@]}" -eq 0 ]; then
    emit PASS "error-code-name-binding: no mismatches (${registry_count} codes in map, ${scan_files} files scanned)"
  else
    echo "  Mismatches found:"
    for entry in "${mismatch_lines[@]}"; do
      emit WARN "error-code-name-binding: $entry"
    done
    echo ""
    echo "  Routing: product-owner — update the cited name to match a canonical name in"
    echo "    .factory/specs/prd-supplements/error-taxonomy.md"
    echo "    Pattern: E-XXX-NNN <canonical-name> (no renaming of the registered name)"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-error-code-name-binding: error-code ↔ canonical-name binding check (ADVISORY)"
echo "  Taxonomy: $TAXONOMY_FILE"
echo "  Scan:     $SPECS_DIR, $STORIES_DIR"
echo "  Finding:  F-P2A067-01 class — cited name ≠ canonical registered name"
echo ""

echo "[SELF-PROBE] Verifying check catches mismatches and respects exemptions (POL-31)..."
probe_must_detect_mismatch
probe_must_not_detect_correct
probe_code_not_in_map
probe_changelog_exempt
probe_double_colon_not_stolen
probe_category_annotation_exempt
probe_multi_message_code
probe_hyphenated_compound_exempt
echo "[SELF-PROBE] All self-probes passed — check is not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "ADVISORY check (exit 0 always)"
echo "════════════════════════════════════════════"
echo ""
echo "── error-code ↔ canonical-name binding ────────────────────────────────"
check_error_code_name_binding

echo ""
echo "════════════════════════════════════════════"
echo ""
echo "verify-error-code-name-binding: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  ADVISORY: $WARN WARN(s)"
echo ""
echo "RESULT: PASS (advisory — exit 0 regardless of WARN count)"
exit 0
