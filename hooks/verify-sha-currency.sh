#!/usr/bin/env bash
# verify-sha-currency.sh — pregolya factory-artifacts wrap guard
#
# Checks:
#   (a) The burst SHA cited in STATE.md Session Resume Checkpoint matches
#       `git -C .factory rev-parse --short HEAD` (or HEAD~1 for the
#       self-referential wrap commit case — accepted with a NOTE).
#   (b) factory-artifacts HEAD == origin/factory-artifacts (push currency).
#       Prints WARN (not FAIL) if local is ahead of remote.
#   (c) Tracked-file dirty check. FAIL if any tracked files are dirty
#       EXCEPT logs/*.jsonl files, which are excluded.
#
# TODO (workspace-init): Add develop_head cross-check. At workspace-init
# the orchestrator should write the develop branch HEAD SHA into STATE.md
# frontmatter (develop_head:). This script should then verify:
#   git -C <repo_root> rev-parse HEAD == STATE.md develop_head
# That check is deferred until Phase 1 workspace-init establishes the
# develop branch.
#
# Usage: bash .factory/hooks/verify-sha-currency.sh
# Exit:  0 if no FAIL lines; non-zero otherwise.

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE_MD="$FACTORY_DIR/STATE.md"

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

# ── (a) SHA citation check ────────────────────────────────────────────────────

HEAD_SHORT="$(git -C "$FACTORY_DIR" rev-parse --short HEAD 2>/dev/null || echo "UNKNOWN")"
HEAD1_SHORT="$(git -C "$FACTORY_DIR" rev-parse --short HEAD~1 2>/dev/null || echo "UNKNOWN")"

# Extract the factory-artifacts SHA cited in the HEADS line of the
# Session Resume Checkpoint section.  Uses flag-based awk to handle the
# macOS BSD awk edge case where '## Session Resume Checkpoint' matches
# both the start-range and end-range pattern '^## [A-Z]', causing the
# classic range form to capture only one line.
# Extracts the backtick-delimited SHA from the specific pattern:
#   factory-artifacts `<sha>` — PUSHED
# This avoids false-matching "default_branch is `factory-artifacts`"
# in the RESUME paragraph.
CITED_SHA="$(awk '
  /^## Session Resume Checkpoint/ { in_sec=1; next }
  in_sec && /^## [A-Z]/ { in_sec=0 }
  in_sec
' "$STATE_MD" \
  | sed -n 's/.*factory-artifacts[[:space:]]*`\([0-9a-f][0-9a-f]*\)`.*/\1/p' \
  | head -1 || echo "")"

if [ -z "$CITED_SHA" ]; then
  emit WARN "STATE.md Session Resume Checkpoint: no factory-artifacts SHA found in HEADS (write 'factory-artifacts \`SHA\` — PUSHED' to resolve; acceptable during active wrap)"
elif [ "$CITED_SHA" = "$HEAD_SHORT" ] || [ "$CITED_SHA" = "$(git -C "$FACTORY_DIR" rev-parse --short HEAD 2>/dev/null | cut -c1-${#CITED_SHA})" ]; then
  emit PASS "SHA citation matches HEAD ($CITED_SHA == $HEAD_SHORT)"
elif [ "$CITED_SHA" = "$HEAD1_SHORT" ] || [ "$CITED_SHA" = "$(git -C "$FACTORY_DIR" rev-parse --short HEAD~1 2>/dev/null | cut -c1-${#CITED_SHA})" ]; then
  emit PASS "SHA citation matches HEAD~1 ($CITED_SHA == $HEAD1_SHORT) — self-referential wrap commit case, accepted with NOTE"
else
  emit FAIL "SHA citation mismatch: STATE.md cites '$CITED_SHA' but HEAD=$HEAD_SHORT / HEAD~1=$HEAD1_SHORT"
fi

# ── (b) Push currency check ───────────────────────────────────────────────────

REMOTE_SHA="$(git -C "$FACTORY_DIR" rev-parse origin/factory-artifacts 2>/dev/null || echo "UNKNOWN")"
LOCAL_SHA="$(git -C "$FACTORY_DIR" rev-parse HEAD 2>/dev/null || echo "UNKNOWN")"

if [ "$REMOTE_SHA" = "UNKNOWN" ]; then
  emit WARN "origin/factory-artifacts not found — cannot verify push currency (run git fetch first)"
elif [ "$LOCAL_SHA" = "$REMOTE_SHA" ]; then
  emit PASS "factory-artifacts HEAD == origin/factory-artifacts ($LOCAL_SHA)"
else
  AHEAD="$(git -C "$FACTORY_DIR" rev-list --count origin/factory-artifacts..HEAD 2>/dev/null || echo "?")"
  emit WARN "factory-artifacts is $AHEAD commit(s) ahead of origin/factory-artifacts — push pending (run: git -C .factory push origin factory-artifacts)"
fi

# ── (c) Tracked-file dirty check (excluding logs/*.jsonl) ────────────────────

# Get list of dirty tracked files, exclude logs/*.jsonl
DIRTY_FILES="$(git -C "$FACTORY_DIR" diff --name-only HEAD 2>/dev/null \
  | grep -v '^logs/.*\.jsonl$' || true)"

if [ -z "$DIRTY_FILES" ]; then
  emit PASS "No dirty tracked files (excluding logs/*.jsonl)"
else
  emit FAIL "Dirty tracked files found (excluding logs/*.jsonl):"
  while IFS= read -r f; do
    echo "       $f"
  done <<< "$DIRTY_FILES"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-sha-currency: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
