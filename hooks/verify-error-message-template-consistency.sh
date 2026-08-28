#!/usr/bin/env bash
# verify-error-message-template-consistency.sh — error message template consistency gate
#
# PURPOSE
# ───────
# Detects drift between error-code message templates in ADR §Decision error-code
# specification tables and the authoritative canonical templates in error-taxonomy.md.
#
# ROOT CAUSE (F-P2A101-01, round-23)
# ────────────────────────────────────
# ADR §Decision sections that specify new error codes (e.g., ADR-029 §Decision 4
# E-MCP-011, §Decision 5 E-MCP-010) carry pipe-table rows with a "Message template"
# field. When those ADR tables are updated independently from error-taxonomy.md (the
# authoritative source), the inline ADR message drifts from the canonical form.
# No prior gate checked this cross-document message parity.
#
# DETECTION STRATEGY
# ──────────────────
# 1. Parse error-taxonomy.md → build E-code → canonical message template map.
#    Canonical = first backtick-quoted segment in the message column of each
#    pipe-table row (content before any trailing " — (annotation):" annotation).
#
# 2. Scan .factory/specs/**/*.md and .factory/stories/**/*.md for pipe-table rows
#    whose first cell is "Message template" (or case variant).
#    Find the associated E-code by looking backward within the same table for a
#    "Code" row — the containing table describes that code's specification.
#
# 3. Normalize both the found message and the canonical:
#    - Strip outer backtick-quoting and double-quote wrapping
#    - Normalize placeholder syntax: {name} → <name> (curly-brace to angle-bracket)
#    - Strip trailing period
#    - Collapse whitespace
#
# 4. Compare normalized forms:
#    - Exact match → PASS (no finding)
#    - Trailing ellipsis shorthand (found ends with '...' or '…' → prefix match OK) → PASS
#    - Mismatch → WARN (advisory, non-blocking)
#
# EXCLUSIONS
# ──────────
# (A) YAML frontmatter and body ## Changelog sections — historical narrative
# (B) <!-- discriminator:illustration-start/end --> illustration regions
# (C) error-taxonomy.md itself (authoritative source, not a citation site)
# (D) .factory/hooks/** (POL-30 self-exclusion)
# (E) Lines inside triple-backtick fenced code blocks (may contain example output)
#
# SELF-PROBES (POL-31)
# ─────────────────────
# Two probes run before the live scan in isolated $TMPDIR fixtures:
#   Positive: synthetic table with | Code | E-CORE-001 | and stale "WRONG_MESSAGE" → WARN
#   Negative: synthetic table with canonical E-CORE-001 message → no WARN
# POL-30: probe fixtures live in $TMPDIR — never under .factory/specs/.
#
# ADVISORY
# ────────
# Advisory: always exits 0. WARN findings are printed but commit is not blocked.
# Exit 2: self-probe failure (script logic bug — false-green or false-red check).
#
# Promotion to blocking requires:
#   1. Human-authorized promotion decision after all current WARN findings are fixed
#   2. Move to run_blocking in pre-commit-validators.sh
#   3. Increment EXPECTED_BLOCKING_COUNT
#   4. Change exit contract to exit 1 on WARN > 0
#
# Usage:  bash .factory/hooks/verify-error-message-template-consistency.sh
# Called: run_advisory in pre-commit-validators.sh (advisory — gate F-P2A101-PG)

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
TAXONOMY_FILE="$FACTORY_DIR/specs/prd-supplements/error-taxonomy.md"

PASS=0
WARN=0
SELF_PROBE_FAIL=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
  esac
}

# ── Self-probe infrastructure ─────────────────────────────────────────────────
PROBE_TMP="$(mktemp -d)"
trap 'rm -rf "$PROBE_TMP"' EXIT

probe_expect_warn() {
  local probe_id="$1"
  local description="$2"
  local warn_count="$3"
  if [ "$warn_count" -eq 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — is false-green: '$description' was NOT detected."
    echo "  Script logic bug — a stale message template would silently pass this gate."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — positive probe correctly detected stale form: $description"
  fi
}

probe_expect_pass() {
  local probe_id="$1"
  local description="$2"
  local warn_count="$3"
  if [ "$warn_count" -gt 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — false-positive: '$description' fired but should NOT have."
    echo "  Script logic bug — the gate incorrectly rejects a canonical message form."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — negative probe correctly passed on canonical form: $description"
  fi
}

# ── Core Python scanner ───────────────────────────────────────────────────────
# Arguments: <taxonomy_file> <probe_file> <spec_glob1> [<spec_glob2> ...]
# When probe_file is non-empty, it is the ONLY file scanned (self-probe mode).
# When probe_file is empty, spec_globs are expanded and all .md files are scanned.
# Output lines:
#   REGISTRY <n>               — number of E-codes in canonical map
#   PASS <filepath> <code>     — message template matches canonical
#   WARN <filepath> <code> <detail>  — message template drifted from canonical
#   SKIP <filepath> <reason>   — file skipped (taxonomy, hooks dir, etc.)
run_scanner() {
  local taxonomy_file="$1"
  local probe_file="${2:-}"
  shift 2
  local spec_globs=("$@")
  python3 - "$taxonomy_file" "$probe_file" "${spec_globs[@]}" <<'PYEOF'
import sys, re, glob, os

taxonomy_file = sys.argv[1]
probe_file    = sys.argv[2] if len(sys.argv) > 2 else ""
spec_globs    = sys.argv[3:]

# ── 1. Parse canonical message templates from error-taxonomy.md ───────────────
E_CODE_ROW_RE = re.compile(r'^\|\s*(E-[A-Z]+-\d+)\s*\|')
BACKTICK_RE   = re.compile(r'`([^`]+)`')

canonical = {}   # E-code -> normalized canonical message

with open(taxonomy_file, 'r', encoding='utf-8') as fh:
    for line in fh:
        m = E_CODE_ROW_RE.match(line)
        if not m:
            continue
        code = m.group(1)
        parts = line.split('|')
        if len(parts) < 7:   # need at least 7 cells: ''|code|cat|sev|bc|msg|''
            continue
        msg_col = parts[5]   # index: 0='' 1=E-CODE 2=CAT 3=SEV 4=BC 5=MSG
        bm = BACKTICK_RE.search(msg_col)
        if not bm:
            continue
        raw = bm.group(1).strip('"').strip()
        # Normalize: strip trailing period, collapse whitespace
        raw = re.sub(r'\s+', ' ', raw).rstrip('.').strip()
        canonical[code] = raw

print(f"REGISTRY {len(canonical)}")

# ── 2. Normalization helpers ──────────────────────────────────────────────────

def normalize_msg(s):
    """Strip backtick/double-quote wrapping, normalize placeholders, trailing period."""
    s = s.strip().strip('`"').strip()
    # Normalize curly-brace placeholders {name} → <name>
    s = re.sub(r'\{([^}]+)\}', r'<\1>', s)
    # Collapse internal whitespace
    s = re.sub(r'\s+', ' ', s).rstrip('.').strip()
    return s

def is_ellipsis_prefix(candidate_norm, canonical_norm):
    """True if candidate is a prefix of canonical with trailing '...' or ellipsis."""
    c = candidate_norm.rstrip('.').rstrip('…').rstrip('.').strip()
    # Require at least 15 chars to avoid spurious prefix matches
    return len(c) >= 15 and canonical_norm.startswith(c)

# ── 3. Region-exempt helpers ──────────────────────────────────────────────────

def changelog_exempt_set(lines):
    """Return set of 0-based line indices that are in frontmatter or ## Changelog."""
    exempt = set()
    # Frontmatter: lines between first pair of '---' delimiters
    fm_end = -1
    if lines and lines[0].strip() == '---':
        for i in range(1, len(lines)):
            if lines[i].strip() == '---':
                fm_end = i
                break
    if fm_end >= 0:
        for i in range(0, fm_end + 1):
            exempt.add(i)
    # Body ## Changelog sections
    in_changelog = False
    for i, line in enumerate(lines):
        if line.strip() == '## Changelog':
            in_changelog = True
        elif in_changelog and line.startswith('## '):
            in_changelog = False
        if in_changelog:
            exempt.add(i)
    return exempt

def illustration_exempt_set(lines):
    """Return set of 0-based line indices inside illustration regions."""
    exempt = set()
    depth = 0
    for i, line in enumerate(lines):
        if re.search(r'<!--\s*discriminator:illustration-start', line):
            depth += 1
        if depth > 0:
            exempt.add(i)
        if re.search(r'<!--\s*discriminator:illustration-end', line):
            depth = max(0, depth - 1)
    return exempt

def fenced_code_exempt_set(lines):
    """Return set of 0-based line indices inside triple-backtick fences."""
    exempt = set()
    in_fence = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('```'):
            in_fence = not in_fence
        if in_fence:
            exempt.add(i)
    return exempt

# ── 4. Pipe-table scan helpers ────────────────────────────────────────────────
# Pattern: | Message template | <message> |
MSG_TEMPLATE_ROW_RE = re.compile(
    r'^\|\s*[Mm]essage\s+[Tt]emplate\s*\|\s*(.+?)\s*\|'
)
# Pattern: | Code | `E-XXX-NNN` |  (find associated E-code for the table)
CODE_ROW_RE = re.compile(
    r'^\|\s*[Cc]ode\s*\|\s*[`"]*\s*(E-[A-Z]+-\d+)\s*[`"]*\s*\|'
)

def scan_file(filepath, taxonomy_file_abs, hooks_dir):
    """Scan one file for | Message template | rows, returning list of (code, found, canonical_msg, pass)."""
    filepath_abs = os.path.abspath(filepath)
    # Skip taxonomy file and hooks directory
    if filepath_abs == taxonomy_file_abs:
        return []
    if filepath_abs.startswith(hooks_dir + os.sep):
        return []

    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError:
        return []

    lines = content.split('\n')
    exempt = (
        changelog_exempt_set(lines)
        | illustration_exempt_set(lines)
        | fenced_code_exempt_set(lines)
    )

    results = []

    for i, line in enumerate(lines):
        if i in exempt:
            continue
        mm = MSG_TEMPLATE_ROW_RE.match(line)
        if not mm:
            continue

        # Found a "Message template" row — look backward for associated E-code
        found_code = None
        for j in range(i - 1, max(-1, i - 25), -1):
            if j in exempt:
                continue
            cm = CODE_ROW_RE.match(lines[j])
            if cm:
                found_code = cm.group(1)
                break
            # Stop looking back if we hit a blank line that looks like a table boundary
            # (two consecutive blank lines typically separate tables)
            if lines[j].strip() == '' and j > 0 and lines[j-1].strip() == '':
                break

        if not found_code:
            continue   # No associated E-code found — skip this row

        if found_code not in canonical:
            continue   # E-code not in taxonomy (e.g., future code not yet minted)

        # Extract the message text from the cell value
        raw_cell = mm.group(1)
        inner = BACKTICK_RE.search(raw_cell)
        if inner:
            found_msg = normalize_msg(inner.group(1))
        else:
            found_msg = normalize_msg(raw_cell)

        canon = canonical[found_code]
        canon_norm = normalize_msg(canon)

        if found_msg == canon_norm:
            results.append((found_code, found_msg, canon_norm, True, i))
        elif is_ellipsis_prefix(found_msg, canon_norm):
            results.append((found_code, found_msg, canon_norm, True, i))   # prefix OK
        else:
            results.append((found_code, found_msg, canon_norm, False, i))

    return results

# ── 5. Collect files to scan ──────────────────────────────────────────────────
taxonomy_abs = os.path.abspath(taxonomy_file)
hooks_dir    = os.path.abspath(os.path.dirname(taxonomy_file) + '/../hooks')

if probe_file:
    files = [probe_file]
else:
    files_set = set()
    for pat in spec_globs:
        files_set.update(glob.glob(pat, recursive=True))
    files = sorted(files_set)

# ── 6. Run scan ───────────────────────────────────────────────────────────────
for fp in files:
    hits = scan_file(fp, taxonomy_abs, hooks_dir)
    for (code, found_msg, canon_norm, is_pass, line_idx) in hits:
        rel = os.path.relpath(fp, os.path.dirname(taxonomy_abs) + '/..')
        if is_pass:
            print(f"PASS {rel} {code}")
        else:
            # Truncate for display
            found_display  = found_msg[:80]  + ('…' if len(found_msg)  > 80 else '')
            canon_display  = canon_norm[:80] + ('…' if len(canon_norm) > 80 else '')
            print(
                f"WARN {rel} {code} "
                f"found={found_display!r} "
                f"canonical={canon_display!r}"
            )
PYEOF
}

# ── Self-probes ───────────────────────────────────────────────────────────────
echo "── Self-probes ──────────────────────────────────────────────────────────"

# Positive probe: stale E-CORE-001 message in a synthetic §Decision table → expect WARN
PROBE_POS="$PROBE_TMP/probe-pos.md"
cat > "$PROBE_POS" <<'MDEOF'
---
document_type: architecture-decision
version: "1.0"
---

## §Decision 1

| Field | Value |
|-------|-------|
| Code | `E-CORE-001` |
| Name | `StrictContentBlockValidation` |
| Message template | `WRONG_MESSAGE_THAT_DOES_NOT_MATCH_CANONICAL` |
MDEOF

POS_OUTPUT="$(run_scanner "$TAXONOMY_FILE" "$PROBE_POS" 2>/dev/null)"
POS_WARN_COUNT="$(echo "$POS_OUTPUT" | grep -c '^WARN ' || true)"
probe_expect_warn "pos-1" "stale message for E-CORE-001 (synthetic ADR table)" "$POS_WARN_COUNT"

# Negative probe: canonical E-CORE-001 message → expect no WARN
PROBE_NEG="$PROBE_TMP/probe-neg.md"
cat > "$PROBE_NEG" <<'MDEOF'
---
document_type: architecture-decision
version: "1.0"
---

## §Decision 1

| Field | Value |
|-------|-------|
| Code | `E-CORE-001` |
| Name | `StrictContentBlockValidation` |
| Message template | `StrictContentBlockValidation: block at position <n> has unrecognized type tag '<type>'; not in KNOWN_BLOCK_TYPES — use lenient deserialization for NonStandard passthrough` |
MDEOF

NEG_OUTPUT="$(run_scanner "$TAXONOMY_FILE" "$PROBE_NEG" 2>/dev/null)"
NEG_WARN_COUNT="$(echo "$NEG_OUTPUT" | grep -c '^WARN ' || true)"
probe_expect_pass "neg-1" "canonical E-CORE-001 message (no WARN expected)" "$NEG_WARN_COUNT"

# Negative probe — ellipsis shorthand: allowed abbreviated form → expect no WARN
PROBE_ELLIPSIS="$PROBE_TMP/probe-ellipsis.md"
cat > "$PROBE_ELLIPSIS" <<'MDEOF'
---
document_type: architecture-decision
version: "1.0"
---

## §Decision 1

| Field | Value |
|-------|-------|
| Code | `E-CORE-001` |
| Name | `StrictContentBlockValidation` |
| Message template | `StrictContentBlockValidation: block at position <n> has unrecognized type tag '<type>'...` |
MDEOF

ELLIPSIS_OUTPUT="$(run_scanner "$TAXONOMY_FILE" "$PROBE_ELLIPSIS" 2>/dev/null)"
ELLIPSIS_WARN_COUNT="$(echo "$ELLIPSIS_OUTPUT" | grep -c '^WARN ' || true)"
probe_expect_pass "neg-2" "ellipsis-abbreviated E-CORE-001 message (prefix match — no WARN expected)" "$ELLIPSIS_WARN_COUNT"

echo ""

# Bail on self-probe failures — script logic bugs, not corpus findings
if [ "$SELF_PROBE_FAIL" -gt 0 ]; then
  echo "ABORT: $SELF_PROBE_FAIL self-probe(s) failed — script has false-green or false-red bugs."
  echo "  Fix the script logic before relying on live scan results."
  exit 2
fi

# ── Live scan ─────────────────────────────────────────────────────────────────
echo "── Live scan ────────────────────────────────────────────────────────────"
SPECS_GLOB="$FACTORY_DIR/specs/**/*.md"
STORIES_GLOB="$FACTORY_DIR/stories/**/*.md"

SCAN_OUTPUT="$(run_scanner "$TAXONOMY_FILE" "" "$SPECS_GLOB" "$STORIES_GLOB")"

# Extract registry size for reporting
REGISTRY_LINE="$(echo "$SCAN_OUTPUT" | grep '^REGISTRY ' | head -1)"
REGISTRY_SIZE="${REGISTRY_LINE#REGISTRY }"

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"

  case "$level" in
    REGISTRY) continue ;;  # already captured above
    PASS)     emit PASS "$rest" ;;
    WARN)     emit WARN "$rest" ;;
    SKIP)     ;;  # silently skip; no emit needed for advisory gate
    *)        ;;
  esac
done <<< "$SCAN_OUTPUT"

echo ""
echo "verify-error-message-template-consistency: PASS=$PASS WARN=$WARN"
echo "  Registry: $REGISTRY_SIZE E-codes with canonical message templates"
echo "  Scan scope: .factory/specs/**/*.md + .factory/stories/**/*.md"
echo "  Advisory: WARN findings do not block commit."
if [ "$WARN" -gt 0 ]; then
  echo "  ACTION: Update the flagged ADR §Decision Message template cells to match"
  echo "  the canonical form in error-taxonomy.md (authoritative source per ADR-010)."
fi

# Advisory gate: always exit 0 (findings are informational, not blocking)
exit 0
