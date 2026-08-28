#!/usr/bin/env bash
# verify-decision-section-canonical-form.sh — §Decision-N hyphenated-form residue in new changelog additions (ADVISORY)
#
# PURPOSE
# ───────
# Flags the hyphenated `§Decision-N` / `§Decision-\d+` form in NEWLY-authored
# changelog additions and recommends the canonical `§Decision N` (space) form.
#
# ROOT CAUSE (F-P2A098-02 process-gap, round-22)
# ───────────────────────────────────────────────
# verify-adr-decision-refs.sh (CITE_RE) checks that §Decision N citations in
# ADR bodies resolve to real headings — its changelog exclusion (POL-19 measured-
# scope carve-out) is intentional: changelog prose documents historical reasoning,
# not normative citations.  However, this carve-out leaves the hyphenated form
# `§Decision-N` (N integer) unchecked in NEWLY-authored changelog entries, so
# round-22 findings show fresh `§Decision-3` / `§Decision-4` violations in
# BC-2.09.008 v2.0/v2.1 changelogs and ARCH-INDEX changelogs after ADR-022
# §Decision 5 established the canonical space form.
#
# This hook uses `git diff HEAD` (addition-only scoping) to catch newly-authored
# hyphenated forms BEFORE they are committed.  Existing committed content is
# grandfathered by the addition-only scoping (no date-boundary needed).
#
# CANONICAL FORM
# ──────────────
# ADR-022 §Decision 5 establishes the canonical §citation convention:
#   CANONICAL: §Decision N    (space before integer — e.g. "§Decision 3")
#   STALE:     §Decision-N    (hyphen before integer — e.g. "§Decision-3")
#
# SCOPE
# ─────
# Scanned: `git diff HEAD` addition lines (+ prefix) in .factory/ *.md files.
# Excluded: .factory/hooks/** (POL-30 self-exclusion; hook scripts are code, not records).
# Note: this gate applies to ALL records-tier markdown files in newly-authored content,
# not just changelog regions — the pattern is uniformly wrong regardless of where it
# appears. The rationale for checking changelog regions specifically is that the
# verify-adr-decision-refs.sh CITE_RE excludes changelogs, leaving them ungated.
#
# SELF-PROBE (POL-31)
# ───────────────────
# Two probes run before the live check:
#   probe_pos: addition line containing `§Decision-3` → WARN reported
#   probe_neg: addition line containing `§Decision 3` (space form) → no WARN
#
# EXIT CONTRACT
# ─────────────
# Advisory: always exits 0.  WARN findings are printed but commit is not blocked.
# Exit 2: self-probe failure (script logic bug — false-green or false-red check).
#
# Promotion to blocking requires:
#   1. Human-authorized promotion decision
#   2. Moving to run_blocking in pre-commit-validators.sh
#   3. Incrementing EXPECTED_BLOCKING_COUNT
#   4. Changing exit 0 at end to exit "$WARN_COUNT"
#
# Usage:  bash .factory/hooks/verify-decision-section-canonical-form.sh
# Called: run_advisory in pre-commit-validators.sh (advisory until promoted)

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"

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

# ── Pattern definition ────────────────────────────────────────────────────────
# STALE_PATTERN: `§Decision-N` or `§Decision-\d+` with a hyphen before the integer.
# Catches: §Decision-3, §Decision-12, §Decision-N (where N is one or more digits).
# Does NOT catch: §Decision 3 (canonical space form), §Decision N (space form).
# Does NOT catch: "decision-making", "§Decisions-" (plural) — word boundary on digit.
STALE_DECISION_PATTERN='§Decision-[0-9]+'

# ── Self-probe helpers ────────────────────────────────────────────────────────

# probe_must_fire <probe_id> <description> <probe_exit_code>
# Expects the stale pattern to be detected (exit_code != 0 from grep).
probe_must_fire() {
  local probe_id="$1"
  local description="$2"
  local probe_exit="$3"
  if [ "$probe_exit" -eq 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — false-green: '$description' was NOT detected."
    echo "  This is a script bug — the check would silently pass on a real violation."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — correctly detected stale form: $description"
  fi
}

# probe_must_not_fire <probe_id> <description> <probe_exit_code>
# Expects the stale pattern to NOT be detected (exit_code == 0 from grep = no match).
probe_must_not_fire() {
  local probe_id="$1"
  local description="$2"
  local probe_exit="$3"
  if [ "$probe_exit" -ne 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — false-positive: '$description' fired but should NOT have."
    echo "  This is a script bug — the check would incorrectly flag a canonical form."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — correctly passed canonical form: $description"
  fi
}

# ── Self-probes ───────────────────────────────────────────────────────────────
echo ""
echo "── verify-decision-section-canonical-form: running self-probes ──────────"

# probe_pos: addition line with hyphenated §Decision-3 → should fire
PROBE_POS="+  - \"1.3 (burst-NNN/2026-08-28): F-058-06 records: citation corrected per ADR-022 §Decision-3 and §Decision-4.\""
PROBE_POS_EXIT=0
echo "$PROBE_POS" | grep -qE "^\+[^+].*${STALE_DECISION_PATTERN}" || PROBE_POS_EXIT=$?
# grep -qE returns 0 on match, 1 on no match. We want PROBE_POS_EXIT to be non-zero when NO match.
# Re-invert: if grep returns 0 (found), PROBE_EXIT should be 1 (stale detected)
if echo "$PROBE_POS" | grep -qE "^\+[^+].*${STALE_DECISION_PATTERN}"; then
  PROBE_POS_EXIT=1
else
  PROBE_POS_EXIT=0
fi
probe_must_fire "probe-pos" "addition line with §Decision-3 (hyphenated form)" "$PROBE_POS_EXIT"

# probe_neg: addition line with canonical §Decision 3 (space form) → should NOT fire
PROBE_NEG="+  - \"1.3 (burst-NNN/2026-08-28): F-058-06 records: citation corrected per ADR-022 §Decision 3 and §Decision 4.\""
if echo "$PROBE_NEG" | grep -qE "^\+[^+].*${STALE_DECISION_PATTERN}"; then
  PROBE_NEG_EXIT=1
else
  PROBE_NEG_EXIT=0
fi
probe_must_not_fire "probe-neg" "addition line with §Decision 3 (canonical space form)" "$PROBE_NEG_EXIT"

# ── Self-probe gate ───────────────────────────────────────────────────────────
if [ "$SELF_PROBE_FAIL" -gt 0 ]; then
  echo ""
  echo "[SELF-PROBE FAIL] $SELF_PROBE_FAIL self-probe(s) failed — this is a script bug."
  echo "  Fix the pattern logic before using this gate for advisory checks."
  exit 2
fi

echo "[SELF-PROBE PASS] Both self-probes passed — check is not false-green."

# ── Live check ────────────────────────────────────────────────────────────────
echo ""
echo "── verify-decision-section-canonical-form: running live check ────────────"

# Get git diff addition lines from .factory/ *.md files, excluding hooks/
DIFF_OUTPUT="$(git -C "$FACTORY_DIR" diff HEAD -- '*.md' ':!hooks/**' 2>/dev/null || true)"

if [ -z "$DIFF_OUTPUT" ]; then
  emit PASS "§Decision-N form — no diff relative to HEAD (UNVERIFIED on clean tree; not checked, not passed)"
  echo ""
  echo "================================================================"
  echo "§Decision-canonical-form summary: PASS=$PASS WARN=$WARN"
  echo "  (Note: UNVERIFIED on clean tree — checks require uncommitted additions)"
  exit 0
fi

# Scan addition lines for §Decision-N hyphenated form
VIOLATIONS=""
while IFS= read -r diffline; do
  case "$diffline" in
    "+++"*) continue ;;
    "+"*)   : ;;
    *)      continue ;;
  esac

  if echo "$diffline" | grep -qE "^\+[^+].*${STALE_DECISION_PATTERN}"; then
    # Capture the matched form(s) for reporting
    MATCHED="$(echo "$diffline" | grep -oE "${STALE_DECISION_PATTERN}" | head -3 | tr '\n' ',' | sed 's/,$//')"
    VIOLATIONS="${VIOLATIONS}
  ${diffline:0:140}  (matched: ${MATCHED})"
  fi
done <<< "$DIFF_OUTPUT"

if [ -n "$VIOLATIONS" ]; then
  emit WARN "§Decision-N form — newly-authored additions contain hyphenated §Decision-N form (stale per ADR-022 §Decision 5):"
  echo "$VIOLATIONS"
  echo ""
  echo "  Canonical form: §Decision N (space before integer, e.g. '§Decision 3')"
  echo "  Stale form:     §Decision-N (hyphen before integer, e.g. '§Decision-3')"
  echo "  Authority: ADR-022 §Decision 5 citation conventions."
  echo "  Replace each occurrence before committing."
  echo ""
  echo "  Note: existing committed content is grandfathered (addition-only git diff HEAD scoping)."
  echo "  This advisory gate fires only on NEWLY-authored additions."
else
  emit PASS "§Decision-N form — no hyphenated §Decision-N forms in newly-authored additions"
fi

echo ""
echo "================================================================"
echo "§Decision-canonical-form summary: PASS=$PASS WARN=$WARN"

if [ "$WARN" -gt 0 ]; then
  echo ""
  echo "[ADVISORY] §Decision-N hyphenated form found in new additions — commit not blocked."
  echo "  Fix before committing to prevent accumulation of non-canonical citations."
fi

# Advisory gate: always exits 0
exit 0
