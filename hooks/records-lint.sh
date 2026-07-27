#!/usr/bin/env bash
# records-lint.sh — ferrochain factory records discipline lint
#
# Runs before every factory commit (.factory/ worktree). exit 0 = PASS, exit 1 = FAIL.
#
# CHECKS (by ID — violations route by ID):
#   L1 — Version/Changelog Parity: frontmatter version > "1.0" requires at least one
#        changelog entry (Form A: frontmatter `changelog:` key, or Form B: `## Changelog`
#        body section). Codifies lesson L-010 (Gate #28) as a mechanical gate.
#        Routing: state-manager (frontmatter fix) or spec owner (changelog authoring).
#
#   L7 — Changelog Monotonic Order: version entries in a `## Changelog` body section
#        must appear in non-increasing (newest-first) order. A version number found AFTER
#        a strictly lower version number is a violation.
#        Routing: spec owner (reorder changelog entries so newest appears first).
#
#   L9 — Line-Cite Ban: newly-authored lines (added since HEAD) must not contain
#        file:NNN line-number citations of the form `word.ext:digits`. Existing text
#        in HEAD is grandfathered. Uses `git diff HEAD` so both staged and unstaged
#        additions are caught. Only lines starting with `+` (additions) are checked.
#        Routing: finding author (replace `path/file.ext:NNN` with symbol/anchor cite).
#
#   L10 — Hash-Digest Ban (ADVISORY): newly-authored changelog prose must not contain
#        standalone 7-hex-literal git SHA fragments (e.g. `5fc3abe → baaf36d`). These
#        are volatile pins of the TD-VSDD-091 family — they decay on the next refresh
#        with nothing to detect the stale reference. The compliant form names the upstream
#        artifact and section: `input-hash refreshed (ADR-014 §Decision 2 edited)`.
#        ADVISORY: non-blocking WARN in FIX-BURST-276 (Wave A). Promotion to blocking
#        after Wave B closes finding IDs P1D-173-L10-class in verification-properties/.
#        Exclusion: YAML hash-field assignments (HASH_FIELD_EXCLUSION); Rust numeric
#        literal type-suffix tokens (CE5/RUST_LITERAL_EXCL — e.g. `1e20f32` in VP prose
#        documents floating-point overflow behavior, not a content hash).
#        Routing: finding author (replace 7-hex SHA with artifact+section anchor cite).
#
#   L11 — Content-Hash Digest Ban (BLOCKING): newly-authored record/changelog/spec prose
#        must not contain standalone 8+ character lowercase hex digest literals. These are
#        the TD-VSDD-091 volatile-pin family at the content-hash level — citing a raw
#        hash value (SHA-1, SHA-256, MD5, or longer partial digest) as evidence of
#        input-file identity creates a reference that goes stale the moment the input
#        changes, with no behavioral anchor a future pass can verify against. Closes
#        F-P173-505 (FIX-BURST-276 Wave B). Existing text in HEAD is grandfathered via
#        the same `git diff HEAD` scoping as L9. Corpus-wide grandfathered count: ~75
#        lines across ~22 files; state-manager owns the cleanup schedule.
#        Exclusions (lines matching ANY of CE1–CE4 are exempt):
#          CE1 — YAML frontmatter hash-field assignments (`input-hash:`, `develop_head:`,
#                `frozen_head:`, etc.); the field VALUE is legitimate structured metadata.
#          CE2 — Frozen-HEAD citation lines (`**Frozen HEAD:**`, etc.); validated by
#                verify-sha-currency.sh — the only sanctioned prose SHA citations.
#          CE3 — `[live-state]` sentinel lines; ephemeral wrap-state markers replaced
#                each session, validated by verify-sha-currency.sh.
#          CE4 — Rust toolchain build-hash format `(HEX YYYY-MM-DD)` from `rustc -V`.
#        Known scope boundary: uppercase hex (`ABC123...`) is out of scope — all hash
#        outputs in this project are lowercase; uppercase appears only in Rust code
#        literals (`0xDEADBEEF`) where the `x` prefix prevents `\b` word-boundary match.
#        CE5/RUST_LITERAL_EXCL applies to L11 as well: Rust float literals (`1e200f64`,
#        `3e38f128`) and binary literals (`0b10101010`) that produce 8+ hex-looking char
#        sequences are excluded; they document numeric ranges in VP bodies, not hash pins.
#        Routing: finding author (replace hex digest literal with artifact+section anchor
#                 cite, e.g. `input-hash refreshed (ADR-014 §Decision 2 edited)`).
#
# SELF-PROBE: Each check self-probes against a synthetic violation before running on
#             the real corpus. A self-probe failure means the check would be false-green —
#             the script exits 2 immediately (script bug, not lint violation).
#             Disable with --skip-self-probe for CI environments where probe cost matters.
#
# Cross-applied from the CLIP email-notifications Stage-3 cascade
# (trend-gate #4 structural intervention + S3-39..S3-42 evidence), human-directed 2026-07-24.
#
# Usage: bash .factory/hooks/records-lint.sh [--skip-self-probe]
# Exit:  0 if no FAIL lines; 1 on lint violations; 2 on self-probe failure (script bug).

set -euo pipefail

SKIP_SELF_PROBE=false
for arg in "$@"; do
  case "$arg" in
    --skip-self-probe) SKIP_SELF_PROBE=true ;;
  esac
done

# ── Config ────────────────────────────────────────────────────────────────────
# Derived from .factory/artifact-path-registry.yaml artifact_types.
# Add new patterns here when new records-tier artifact types are registered.
# TODO(workspace-init): After workspace-init finalises artifact paths, verify
#   that all RECORDS_PATTERNS below match at least one file under FACTORY_DIR.

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Records-tier file glob patterns (relative to FACTORY_DIR).
# Covers all artifact types declared in artifact-path-registry.yaml.
RECORDS_PATTERNS=(
  "specs/behavioral-contracts/**/*.md"      # behavioral-contract, bc-index
  "specs/architecture/**/*.md"              # architecture-doc, adr, architecture-index, architecture-section
  "specs/prd-supplements/*.md"              # prd-supplement
  "specs/prd.md"                            # prd
  "specs/product-brief.md"                  # product-brief
  "specs/module-criticality.md"             # module-criticality
  "specs/domain-spec/*.md"                  # domain-spec
  "specs/verification-properties/*.md"      # verification-property, vp-index
  "cycles/*/cycle-manifest.md"              # cycle-manifest
  "cycles/*/burst-log.md"                   # burst-log
  "cycles/*/convergence-trajectory.md"      # convergence-trajectory
  "cycles/*/lessons.md"                     # lessons (records tier)
  "stories/*.md"                            # story
  "holdout-scenarios/*.md"                  # holdout-scenario
  # TODO: semport/**/*.md — semport analysis files; add once semport artifact
  #   type is registered in artifact-path-registry.yaml
  # TODO: planning/*.md — planning artifacts; add if/when registered in registry
)

# L9 line-citation pattern.
# Matches: word.ext:NNN where ext is a known code/doc extension and NNN is digits.
# Catches: src/lib.rs:42  path/to/CLAUDE.md:156  Cargo.toml:8  api-surface.md:23
# Does NOT catch: version strings (v1.2.3), URLs without line-number suffix,
#   or colon-delimited identifiers without a leading file extension.
LINE_CITE_PATTERN='\b[a-zA-Z0-9_.-]+\.(rs|md|toml|yaml|yml|ts|js|py|json|sh|txt):[0-9]{1,6}\b'

# L10 hash-digest pattern.
# Matches standalone 7-character lowercase-hex strings (git SHA fragments).
# Catches: `5fc3abe → baaf36d`, `c745d15 → c504e82`, etc. in changelog prose.
# Does NOT match lines that are YAML hash-field assignments like `input-hash: "abc1234"`.
HASH_DIGEST_PATTERN='\b[0-9a-f]{7}\b'
# YAML hash-field exclusion: lines of the form `  key: "7hex"` or `  key: 7hex`
# These are structured frontmatter fields, not prose — exempt from L10.
HASH_FIELD_EXCLUSION='^\+[[:space:]]*(input.hash|proof_file_hash|commit.hash|content.hash)[[:space:]]*:[[:space:]]*"?[0-9a-f]'

# L11 content-hash digest pattern.
# Matches standalone 8+ character lowercase-hex strings (content-hash digest literals).
# 8-char minimum is the complement of L10's 7-char scope: captures SHA-1 (40 chars),
# SHA-256 (64 chars), MD5 (32 chars), and any partial digest used as a content pin.
# Does NOT match inline code hex literals where the `0x` prefix or embedding in a
# longer word-char sequence prevents `\b` matching.
CONTENT_HASH_PATTERN='\b[0-9a-f]{8,}\b'

# L11 EXCLUSIONS — lines matching ANY of CE1-CE4 are exempt from L11.
#
# CE1: YAML frontmatter hash-field assignments. The field VALUE is legitimate structured
#      metadata; what is forbidden is restating that value as prose evidence. Covers all
#      hash-bearing YAML keys used in factory artifact frontmatter, including STATE.md
#      develop_head and adversarial-pass-record frozen_head fields.
CONTENT_HASH_CE1='^\+[[:space:]]*(input.hash|input_hash|proof_file_hash|commit.hash|content.hash|develop_head|frozen_head)[[:space:]]*:[[:space:]]*"?[0-9a-f]'

# CE2: Frozen-HEAD citation lines — sanctioned by verify-sha-currency.sh. These are the
#      only prose SHA citations the project allows; verify-sha-currency.sh validates each
#      one against the actual git ref. Covers: `**Frozen HEAD:** commit (...)`, `frozen
#      HEAD burst-NNN`, `Frozen HEAD (burst-NNN commit, SHA ...)`. Case-insensitive on
#      all letters via explicit character classes; accepts `-` or space as separator.
#      Note: "HEAD" in git parlance is always uppercase; "head" (lowercase) is less common.
#      The full `[Hh][Ee][Aa][Dd]` expansion covers both forms without requiring `-i` flag.
CONTENT_HASH_CE2='[Ff]rozen[-[:space:]][Hh][Ee][Aa][Dd]'

# CE3: [live-state] sentinel lines. These are ephemeral wrap-state markers that record
#      current git SHA during a session. They are replaced each session wrap and validated
#      by verify-sha-currency.sh. Matched as a literal string (brackets are not regex here).
# Note: grep -F is used for CE3 in check_l11 (literal bracket-string match).

# CE4: Rust toolchain build-hash format. `rustc -V` emits `X.Y.Z (NNNNNNNN YYYY-MM-DD)`;
#      this appears in preflight reports and toolchain verification tables. The
#      `(HEX YYYY-MM-DD)` parenthesized form is unambiguous toolchain identity metadata.
CONTENT_HASH_CE4='\([0-9a-f]{6,12}[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}\)'

# CE5 / RUST_LITERAL_EXCL — Rust numeric literals that produce hex-shaped tokens.
# Applied to BOTH L10 and L11. Two sub-cases:
#
#   (a) Float literals with Rust type suffixes where all suffix chars are lowercase hex:
#       `f32`, `f64`, `f16`, `f128`. Examples: `1e20f32` (7 chars, L10 scope),
#       `1e200f64` (8 chars, L11 scope), `3e38f128` (8 chars, L11 scope).
#       Token must start with a digit (distinguishing from hash strings starting a-f).
#       These appear in VP changelogs documenting IEEE-754 overflow behavior — the HIGHEST
#       density co-location of legitimate Rust float literals AND potential hash digests.
#
#   (b) Binary integer literals: `0b[01]+` sequences. Binary digits (0 and 1) are
#       both valid hex chars, so `0b10101010` (10 chars) matches `[0-9a-f]{8,}`.
#       The `0b` prefix unambiguously identifies these as binary literals, not content pins.
#       Hex literals (`0x...`) do NOT need exclusion: the `x` char is not in `[0-9a-f]`,
#       so the `0x` prefix breaks the match before the hex digits begin.
#
# Trade-off: CE5 is applied at the LINE level. A line containing BOTH a Rust float literal
# AND a real hash digest would be skipped (false negative). This is an accepted trade-off:
# changelog entries mixing numeric Rust literals with hash citations should be split.
RUST_LITERAL_EXCL='\b[0-9][0-9a-f]*(f32|f64|f16|f128)\b|\b0b[01]+\b'

# ── Counters ─────────────────────────────────────────────────────────────────

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

# ── Self-probe helpers ────────────────────────────────────────────────────────

# probe_must_fail <check_id> <description>
# Call after a check function has been run against a synthetic violation.
# Expects the subshell exit code to be stored in PROBE_EXIT.
probe_must_fail() {
  local check_id="$1"
  local description="$2"
  if [ "${PROBE_EXIT:-0}" -eq 0 ]; then
    echo "[SELF-PROBE FAIL] $check_id self-probe is false-green: '$description' was NOT detected."
    echo "  This is a script bug — the check would silently pass on a real violation."
    exit 2
  fi
}

# ── Self-probes ───────────────────────────────────────────────────────────────
# Each self-probe creates a synthetic violating artifact and verifies the
# corresponding check catches it. A passing self-probe = the check is not false-green.

run_self_probes() {
  PROBE_TMP="$(mktemp -d)"
  trap 'rm -rf "$PROBE_TMP"' EXIT

  # ── L1 self-probe: version > 1.0 with no changelog ───────────────────────
  # Synthetic violation: frontmatter version: "1.2" but no changelog entry.
  PROBE_L1="$PROBE_TMP/l1-violation.md"
  cat > "$PROBE_L1" <<'EOF'
---
document_type: behavioral-contract
version: "1.2"
status: active
---
# BC-9.99.001 Synthetic Violation

No changelog entry here.
EOF

  PROBE_EXIT=0
  # L1 check: version > 1.0 implies changelog (Form A or Form B)
  BUMPED_VER="$(grep -m1 '^version:' "$PROBE_L1" | grep -oE '"[0-9]+\.[0-9]+"' | tr -d '"' || echo "")"
  if [ -n "$BUMPED_VER" ]; then
    MAJOR="$(echo "$BUMPED_VER" | cut -d. -f1)"
    MINOR="$(echo "$BUMPED_VER" | cut -d. -f2)"
    if [ "$MAJOR" -gt 1 ] || { [ "$MAJOR" -eq 1 ] && [ "$MINOR" -gt 0 ]; }; then
      FORM_A="$(grep -c '^changelog:' "$PROBE_L1" || true)"
      FORM_B="$(grep -c '^## Changelog' "$PROBE_L1" || true)"
      if [ "$FORM_A" -eq 0 ] && [ "$FORM_B" -eq 0 ]; then
        PROBE_EXIT=1
      fi
    fi
  fi
  probe_must_fail "L1" "version 1.2 with no changelog"

  # ── L7 self-probe: changelog entries in wrong order ───────────────────────
  # Synthetic violation: older version appears before newer version.
  PROBE_L7="$PROBE_TMP/l7-violation.md"
  cat > "$PROBE_L7" <<'EOF'
---
document_type: behavioral-contract
version: "1.2"
---
# BC-9.99.002 Synthetic Violation

## Changelog

| Version | Change |
|---------|--------|
| 1.0     | Initial |
| 1.2     | Second (this is newer but listed after older — wrong) |
EOF

  PROBE_EXIT=0
  # L7 check: extract version numbers from changelog table rows (N.N pattern),
  # verify they are in non-increasing order (newest first).
  # Uses flag-based awk (not range pattern) to avoid early termination when the
  # end-pattern /^## [A-Z]/ also matches the ## Changelog start line.
  CHANGELOG_VERSIONS="$(awk '/## Changelog/{flag=1;next} /^## /{flag=0} flag' "$PROBE_L7" \
    | grep -oE '^\| [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' || echo "")"
  if [ -n "$CHANGELOG_VERSIONS" ]; then
    PREV_VER=""
    while IFS= read -r VER; do
      if [ -n "$PREV_VER" ]; then
        PREV_MAJ="$(echo "$PREV_VER" | cut -d. -f1)"
        PREV_MIN="$(echo "$PREV_VER" | cut -d. -f2)"
        CUR_MAJ="$(echo "$VER" | cut -d. -f1)"
        CUR_MIN="$(echo "$VER" | cut -d. -f2)"
        # If current is GREATER than prev, order is wrong (should be newest-first)
        if [ "$CUR_MAJ" -gt "$PREV_MAJ" ] || \
           { [ "$CUR_MAJ" -eq "$PREV_MAJ" ] && [ "$CUR_MIN" -gt "$PREV_MIN" ]; }; then
          PROBE_EXIT=1
          break
        fi
      fi
      PREV_VER="$VER"
    done <<< "$CHANGELOG_VERSIONS"
  fi
  probe_must_fail "L7" "changelog with version 1.0 before 1.2 (wrong order)"

  # ── L9 self-probe: line-cite pattern in a synthetic diff addition ─────────
  # Synthetic violation: a new line containing a file:NNN citation.
  PROBE_L9_DIFF="+The function is defined at src/lib.rs:42 in the build path."
  PROBE_EXIT=0
  if echo "$PROBE_L9_DIFF" | grep -qE "^\+[^+].*${LINE_CITE_PATTERN}"; then
    PROBE_EXIT=1
  fi
  probe_must_fail "L9" "addition line containing src/lib.rs:42"

  # ── L10 self-probe: hash-digest pattern in a synthetic diff addition ───────
  # Synthetic violation: a changelog entry containing a 7-hex SHA transition.
  # The probe uses two forms that should both be caught:
  #   (a) The right-arrow form (the dominant violation shape in the corpus)
  #   (b) A bare 7-hex standalone word in changelog prose
  PROBE_L10_DIFF='  - "1.9 (burst-123/2026-07-01): Input-hash refreshed: 5fc3abe → baaf36d (ADR-017 bumped)"'
  PROBE_EXIT=0
  # Simulate: echo "+$PROBE_L10_DIFF" (prefixed with + as it would appear in git diff)
  PROBE_L10_LINE="+${PROBE_L10_DIFF}"
  # Check: not a hash-field exclusion line, and contains a 7-hex pattern
  if ! echo "$PROBE_L10_LINE" | grep -qE "${HASH_FIELD_EXCLUSION}"; then
    if echo "$PROBE_L10_LINE" | grep -qE "${HASH_DIGEST_PATTERN}"; then
      PROBE_EXIT=1
    fi
  fi
  probe_must_fail "L10" "changelog addition containing 7-hex SHA transition 5fc3abe → baaf36d"

  # ── L11 self-probe: 8+ char content-hash digest in a synthetic diff addition ──
  # Synthetic violation: a changelog entry citing a 40-char SHA-1 digest literal as
  # evidence of input-file identity. This line does NOT match CE1-CE4 exclusions:
  #   - Not a YAML hash-field assignment (CE1).
  #   - Does not contain "Frozen HEAD" or "frozen HEAD" (CE2).
  #   - Does not contain "[live-state]" (CE3).
  #   - Does not match Rust toolchain format `(HEX YYYY-MM-DD)` (CE4).
  PROBE_L11_DIFF='  - "1.5 (burst-999/2026-07-27): input-hash refreshed: 4bcef4e5790e7f8352c28d6ae3b3697572939ef3 (ADR-014 edited)"'
  PROBE_EXIT=0
  PROBE_L11_LINE="+${PROBE_L11_DIFF}"
  # Apply CE1 first (same two-condition structure as L10 self-probe)
  if ! echo "$PROBE_L11_LINE" | grep -qE "${CONTENT_HASH_CE1}"; then
    # Apply CE2
    if ! echo "$PROBE_L11_LINE" | grep -qE "${CONTENT_HASH_CE2}"; then
      # Apply CE3 (literal bracket match)
      if ! echo "$PROBE_L11_LINE" | grep -qF "[live-state]"; then
        # Apply CE4
        if ! echo "$PROBE_L11_LINE" | grep -qE "${CONTENT_HASH_CE4}"; then
          # Check for 8+ char hex pattern
          if echo "$PROBE_L11_LINE" | grep -qE "${CONTENT_HASH_PATTERN}"; then
            PROBE_EXIT=1
          fi
        fi
      fi
    fi
  fi
  probe_must_fail "L11" "addition line containing 40-char SHA-1 content-hash digest in changelog prose"

  rm -rf "$PROBE_TMP"
  trap - EXIT
}

# ── Check L1 — Version/Changelog Parity ──────────────────────────────────────
# For every records-tier markdown file: if frontmatter version > "1.0", at least
# one changelog entry must be present (Form A: frontmatter `changelog:` key; OR
# Form B: `## Changelog` body section). Codifies lesson L-010 / Gate #28.

check_l1() {
  local found_violation=0

  for pattern in "${RECORDS_PATTERNS[@]}"; do
    # shellcheck disable=SC2086
    while IFS= read -r -d '' f; do
      # Extract frontmatter version field (first occurrence)
      VER="$(grep -m1 '^version:' "$f" | grep -oE '"[0-9]+\.[0-9]+"' | tr -d '"' || echo "")"
      [ -z "$VER" ] && continue

      MAJOR="$(echo "$VER" | cut -d. -f1)"
      MINOR="$(echo "$VER" | cut -d. -f2)"

      # Only check files with version > 1.0
      if [ "$MAJOR" -gt 1 ] || { [ "$MAJOR" -eq 1 ] && [ "$MINOR" -gt 0 ]; }; then
        FORM_A="$(grep -c '^changelog:' "$f" || true)"
        FORM_B="$(grep -c '^## Changelog' "$f" || true)"
        if [ "$FORM_A" -eq 0 ] && [ "$FORM_B" -eq 0 ]; then
          rel="${f#$FACTORY_DIR/}"
          emit FAIL "L1: $rel — version $VER but no changelog entry (add frontmatter changelog: or ## Changelog section)"
          found_violation=1
        fi
      fi
    done < <(find "$FACTORY_DIR" -path "$FACTORY_DIR/$pattern" -name "*.md" -print0 2>/dev/null || true)
  done

  if [ "$found_violation" -eq 0 ]; then
    emit PASS "L1: version/changelog parity — all versioned records carry changelog entries"
  fi
}

# ── Check L7 — Changelog Monotonic Order ─────────────────────────────────────
# For every records-tier file with a ## Changelog section: version entries in
# the table must appear in non-increasing (newest-first) order. An entry with a
# version greater than the preceding entry is a violation.

check_l7() {
  local found_violation=0

  for pattern in "${RECORDS_PATTERNS[@]}"; do
    # shellcheck disable=SC2086
    while IFS= read -r -d '' f; do
      # Extract version numbers from ## Changelog table rows (| N.N format).
      # Uses flag-based awk (not range pattern) to avoid early termination when
      # /^## [A-Z]/ also matches the ## Changelog start line itself.
      VERSIONS="$(awk '/## Changelog/{flag=1;next} /^## /{flag=0} flag' "$f" \
        | grep -oE '^\| [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' || echo "")"
      [ -z "$VERSIONS" ] && continue

      PREV_VER=""
      VIOLATION=""
      while IFS= read -r VER; do
        if [ -n "$PREV_VER" ]; then
          PREV_MAJ="$(echo "$PREV_VER" | cut -d. -f1)"
          PREV_MIN="$(echo "$PREV_VER" | cut -d. -f2)"
          CUR_MAJ="$(echo "$VER" | cut -d. -f1)"
          CUR_MIN="$(echo "$VER" | cut -d. -f2)"
          if [ "$CUR_MAJ" -gt "$PREV_MAJ" ] || \
             { [ "$CUR_MAJ" -eq "$PREV_MAJ" ] && [ "$CUR_MIN" -gt "$PREV_MIN" ]; }; then
            VIOLATION="version $VER appears after $PREV_VER (newest-first required)"
            break
          fi
        fi
        PREV_VER="$VER"
      done <<< "$VERSIONS"

      if [ -n "$VIOLATION" ]; then
        rel="${f#$FACTORY_DIR/}"
        emit FAIL "L7: $rel — changelog out of order: $VIOLATION"
        found_violation=1
      fi
    done < <(find "$FACTORY_DIR" -path "$FACTORY_DIR/$pattern" -name "*.md" -print0 2>/dev/null || true)
  done

  if [ "$found_violation" -eq 0 ]; then
    emit PASS "L7: changelog monotonic order — all changelog sections are newest-first"
  fi
}

# ── Check L9 — Line-Cite Ban ──────────────────────────────────────────────────
# Newly-authored lines (additions since HEAD in .factory/) must not contain
# file:NNN line-number citations. Only `+` lines (additions) from `git diff HEAD`
# are checked — existing text in HEAD is grandfathered.
# Covers all markdown additions, not only records-tier patterns, since line-cite
# violations can appear in any spec artifact.

check_l9() {
  # Get additions from working tree + staged changes relative to HEAD
  DIFF_OUTPUT="$(git -C "$FACTORY_DIR" diff HEAD -- '*.md' 2>/dev/null || true)"

  if [ -z "$DIFF_OUTPUT" ]; then
    emit WARN "L9: no diff relative to HEAD — nothing to check (acceptable if running on a clean tree)"
    return
  fi

  VIOLATIONS="$(echo "$DIFF_OUTPUT" \
    | grep -E '^\+[^+]' \
    | grep -oE "${LINE_CITE_PATTERN}" \
    || true)"

  if [ -n "$VIOLATIONS" ]; then
    emit FAIL "L9: line-cite ban — newly-added text contains file:NNN citations (retire with symbol/anchor cites):"
    while IFS= read -r cite; do
      echo "       $cite"
    done <<< "$VIOLATIONS"
    # Also show which files contain violations for easier routing
    echo ""
    echo "  Affected files (lines containing violations):"
    echo "$DIFF_OUTPUT" | grep -n -E "^\+[^+].*${LINE_CITE_PATTERN}" \
      | sed 's/^/       /' || true
  else
    emit PASS "L9: line-cite ban — no file:NNN citations in newly-authored additions"
  fi
}

# ── Check L10 — Hash-Digest Ban (ADVISORY) ───────────────────────────────────
# Newly-authored lines (additions since HEAD in .factory/) must not contain
# standalone 7-hex-literal hash values in changelog prose. These decay on the
# next refresh because they reference mutable intermediate SHA state.
# ADVISORY: emits WARN (not FAIL); exits 0 regardless of WARN count.
# Existing text in HEAD is grandfathered (same scoping as L9).
# Promotion to blocking: after Wave B closes P1D-173-L10-class findings.
#
# Exclusion: lines that are YAML hash-field assignments (input-hash:,
# proof_file_hash:, etc.) are exempt — those are structured fields, not prose.

check_l10() {
  DIFF_OUTPUT="$(git -C "$FACTORY_DIR" diff HEAD -- '*.md' 2>/dev/null || true)"

  if [ -z "$DIFF_OUTPUT" ]; then
    emit WARN "L10 [ADVISORY]: no diff relative to HEAD — nothing to check (acceptable if running on a clean tree)"
    return
  fi

  L10_COUNT=0
  L10_LINES=""

  while IFS= read -r diffline; do
    # Only check + additions (not +++ diff header, not -- removal)
    case "$diffline" in
      "+++"*) continue ;;
      "+"*)   : ;;
      *)      continue ;;
    esac

    # Exclude YAML hash-field assignment lines (structured fields, not prose)
    if echo "$diffline" | grep -qE "${HASH_FIELD_EXCLUSION}"; then
      continue
    fi

    # CE5: exclude lines containing Rust numeric literal type-suffix tokens (float literals
    # like `1e20f32`, `1e200f64` and binary literals like `0b10101010` produce hex-shaped
    # tokens that are not content-hash digests). Same exclusion applied to L10 and L11.
    if echo "$diffline" | grep -qE "${RUST_LITERAL_EXCL}"; then
      continue
    fi

    # Check for standalone 7-hex string
    if echo "$diffline" | grep -qE "${HASH_DIGEST_PATTERN}"; then
      L10_COUNT=$((L10_COUNT + 1))
      # Capture a short representation (first 120 chars) for the report
      L10_LINES="${L10_LINES}
       $(echo "$diffline" | cut -c1-120)"
    fi
  done <<< "$DIFF_OUTPUT"

  if [ "$L10_COUNT" -gt 0 ]; then
    emit WARN "L10 [ADVISORY]: hash-digest ban — $L10_COUNT newly-added line(s) contain standalone 7-hex SHA literals in changelog prose (ADVISORY: non-blocking in Wave A; promote to blocking after Wave B)"
    echo "  Replace 7-hex literals with artifact+section anchor cites, e.g. 'input-hash refreshed (ADR-014 §Decision 2 edited)'"
    echo "  Affected lines:${L10_LINES}"
  else
    emit PASS "L10 [ADVISORY]: hash-digest ban — no 7-hex SHA literals in newly-authored changelog prose"
  fi
}

# ── Check L11 — Content-Hash Digest Ban ──────────────────────────────────────
# Newly-authored lines (additions since HEAD in .factory/) must not contain
# standalone 8+ character lowercase hex digest literals in record/changelog prose.
# These are volatile content-pin identifiers in the TD-VSDD-091 family: they go
# stale the moment the referenced file changes, with nothing left to detect the
# stale reference. Closes F-P173-505 (FIX-BURST-276 Wave B).
# Existing text in HEAD is grandfathered (same scoping as L9/L10).
#
# Exclusions CE1-CE4 (see Config section above for full rationale):
#   CE1 — YAML frontmatter hash-field assignments
#   CE2 — Frozen-HEAD citation lines (validated by verify-sha-currency.sh)
#   CE3 — [live-state] sentinel lines (validated by verify-sha-currency.sh)
#   CE4 — Rust toolchain build-hash format `(HEX YYYY-MM-DD)`
#
# Known scope boundary: uppercase hex is out of scope (see Config section).

check_l11() {
  DIFF_OUTPUT="$(git -C "$FACTORY_DIR" diff HEAD -- '*.md' 2>/dev/null || true)"

  if [ -z "$DIFF_OUTPUT" ]; then
    emit WARN "L11: no diff relative to HEAD — nothing to check (acceptable if running on a clean tree)"
    return
  fi

  L11_COUNT=0
  L11_LINES=""

  while IFS= read -r diffline; do
    # Only check + additions (not +++ diff headers, not -- removals)
    case "$diffline" in
      "+++"*) continue ;;
      "+"*)   : ;;
      *)      continue ;;
    esac

    # CE1: exclude YAML frontmatter hash-field assignments
    if echo "$diffline" | grep -qE "${CONTENT_HASH_CE1}"; then
      continue
    fi

    # CE2: exclude frozen-HEAD citation lines (sanctioned by verify-sha-currency.sh)
    if echo "$diffline" | grep -qE "${CONTENT_HASH_CE2}"; then
      continue
    fi

    # CE3: exclude [live-state] sentinel lines (literal bracket-string match)
    if echo "$diffline" | grep -qF "[live-state]"; then
      continue
    fi

    # CE4: exclude Rust toolchain build-hash format `(HEX YYYY-MM-DD)`
    if echo "$diffline" | grep -qE "${CONTENT_HASH_CE4}"; then
      continue
    fi

    # CE5: exclude lines containing Rust numeric literal type-suffix tokens (same
    # exclusion as applied to L10; see RUST_LITERAL_EXCL in Config section for rationale)
    if echo "$diffline" | grep -qE "${RUST_LITERAL_EXCL}"; then
      continue
    fi

    # Check for standalone 8+ char lowercase hex sequence
    if echo "$diffline" | grep -qE "${CONTENT_HASH_PATTERN}"; then
      L11_COUNT=$((L11_COUNT + 1))
      # Capture a short representation (first 120 chars) for the report
      L11_LINES="${L11_LINES}
       $(echo "$diffline" | cut -c1-120)"
    fi
  done <<< "$DIFF_OUTPUT"

  if [ "$L11_COUNT" -gt 0 ]; then
    emit FAIL "L11: content-hash digest ban — $L11_COUNT newly-added line(s) contain standalone 8+ char hex digest literals in record/changelog prose"
    echo "  Replace hex digest literals with artifact+section anchor cites, e.g. 'input-hash refreshed (ADR-014 §Decision 2 edited)'"
    echo "  Affected lines:${L11_LINES}"
  else
    emit PASS "L11: content-hash digest ban — no 8+ char hex digest literals in newly-authored record/changelog prose"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

echo "records-lint: ferrochain factory records discipline"
echo "  FACTORY_DIR: $FACTORY_DIR"
echo ""

if [ "$SKIP_SELF_PROBE" = false ]; then
  echo "[SELF-PROBE] Verifying each check catches its synthetic violation..."
  run_self_probes
  echo "[SELF-PROBE] All self-probes passed — checks are not false-green."
  echo ""
fi

echo "--- L1: Version/Changelog Parity ---"
check_l1

echo ""
echo "--- L7: Changelog Monotonic Order ---"
check_l7

echo ""
echo "--- L9: Line-Cite Ban (newly-authored additions) ---"
check_l9

echo ""
echo "--- L10: Hash-Digest Ban (ADVISORY — newly-authored changelog prose) ---"
check_l10

echo ""
echo "--- L11: Content-Hash Digest Ban (newly-authored record/changelog/spec prose) ---"
check_l11

echo ""
echo "records-lint: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL — resolve violations before committing"
  echo ""
  echo "Routing guide:"
  echo "  L1 violations → state-manager (frontmatter) or spec owner (changelog body)"
  echo "  L7 violations → spec owner (reorder changelog entries, newest first)"
  echo "  L9 violations → finding author (replace file:NNN with symbol/anchor cite)"
  echo "  L10 violations → finding author (replace 7-hex SHA with artifact+section anchor cite) [ADVISORY]"
  echo "  L11 violations → finding author (replace 8+ char hex digest with artifact+section anchor cite)"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
