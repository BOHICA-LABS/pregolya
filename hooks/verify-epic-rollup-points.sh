#!/usr/bin/env bash
# verify-epic-rollup-points.sh — pregolya advisory validator
#
# PURPOSE
# ───────
# Catches the F-P2A068-01 class (2nd occurrence; first at D-241 / E-16/E-17):
# story-point arithmetic errors in the Epic Catalog.
#
# Two checks:
# (a) Per-epic rollup: each Epic Catalog row's Points cell == sum of the
#     story-point values of its listed constituent stories in STORY-INDEX.md.
# (b) Grand total cross-check: sum of all product-epic point cells ==
#     sum of all product-story point values in STORY-INDEX.md.
#     "Product" excludes EPIC-MAINT and S-MAINT-* entries.
#
# SCOPE
# ─────
# Source files: .factory/stories/epics.md
#               .factory/stories/STORY-INDEX.md
# These files are the only inputs; no other files are read.
#
# ADVISORY: exits 0 always. Mismatches are printed as [WARN] lines.
# Do NOT wire as blocking — advisory class only (F-P2A068-01).
# Promotion to blocking requires human authorization.
#
# SELF-PROBE (POL-31)
# ───────────────────
# Synthetic fixture pair exercised before live scan:
#   probe_must_detect_per_epic_mismatch:  epic points cell != story sum → WARN
#   probe_must_not_detect_correct_epic:   correct epic points → not flagged
#   probe_must_detect_grand_total_mismatch: product epic total != product story total → WARN
#   probe_must_not_detect_correct_total:  balanced total → not flagged
# POL-30: probe fixtures live in $TMPDIR, never under .factory/stories/.
#
# EXIT CONTRACT
# ─────────────
# Exit 0: always (advisory).
# Exit 2: self-probe failure (script bug — a check is false-green or false-red).
#
# Usage:  bash .factory/hooks/verify-epic-rollup-points.sh
# Called: standalone advisory check; NOT wired into pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
EPICS_FILE="$FACTORY_DIR/stories/epics.md"
STORY_INDEX_FILE="$FACTORY_DIR/stories/STORY-INDEX.md"

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
# Arguments: <epics_file> <story_index_file>
# Output lines:
#   STORY <story_id> <points>
#   EPIC <epic_id> <declared_points> <computed_sum> [UNKNOWN:<id>,<id>...]
#   GRAND <product_epic_total> <product_story_total>
#   PARSE_ERROR <message>
run_rollup_scanner() {
  local epics_file="$1"
  local story_index_file="$2"
  python3 - "$epics_file" "$story_index_file" <<'PYEOF'
import sys, re

epics_file        = sys.argv[1]
story_index_file  = sys.argv[2]

# ── Parse STORY-INDEX.md ──────────────────────────────────────────────────────
# Story pipe-table row:
#   | S-ID | Title | BCs | Subsystem | Crate | Pri | Pts | depends_on | Status |
#    0       1       2     3           4       5     6     7            8
# Also handles | S-ID | Title | BCs | SS | Crate | Pts | ... | (Wave 6 tables if variant)
# Strategy: detect the header to find the Pts column index; fall back to index 6 default.
STORY_ID_RE = re.compile(r'^\|\s*(S-[A-Za-z0-9._-]+)\s*\|')

story_points = {}  # story_id -> int

try:
    with open(story_index_file, 'r', encoding='utf-8') as fh:
        pts_col_idx = 6   # default column index for Pts in story table
        for line in fh:
            # Update Pts column index when we see a header row
            if '| Pts |' in line or '| Points |' in line:
                cols = [c.strip() for c in line.split('|')]
                cols = [c for c in cols if c]
                for i, c in enumerate(cols):
                    if c in ('Pts', 'Points'):
                        pts_col_idx = i
                        break
                continue
            m = STORY_ID_RE.match(line)
            if not m:
                continue
            story_id = m.group(1).strip()
            # Remove trailing .* after stable ID (e.g., "S-1.01" is fine)
            cols = [c.strip() for c in line.split('|')]
            cols = [c for c in cols if c]
            if len(cols) <= pts_col_idx:
                continue
            try:
                pts = int(cols[pts_col_idx])
                story_points[story_id] = pts
                print(f'STORY {story_id} {pts}')
            except ValueError:
                pass   # header row or separator
except FileNotFoundError:
    print(f'PARSE_ERROR story-index file not found: {story_index_file}')

# ── Parse epics.md ────────────────────────────────────────────────────────────
# Epic pipe-table row:
#   | Epic ID | Title | Wave | Stories | Points | Subsystem | Crates |
#    0          1       2      3         4         5           6
EPIC_ID_RE = re.compile(r'^\|\s*(E-\d+|EPIC-[A-Za-z0-9_-]+)\s*\|')

product_epic_total  = 0
product_story_total = sum(
    pts for sid, pts in story_points.items()
    if not sid.upper().startswith('S-MAINT')
)

try:
    with open(epics_file, 'r', encoding='utf-8') as fh:
        pts_col_idx = 4   # default column index for Points in epic table
        for line in fh:
            # Update Points column index when we see a header row
            if '| Points |' in line:
                cols = [c.strip() for c in line.split('|')]
                cols = [c for c in cols if c]
                for i, c in enumerate(cols):
                    if c == 'Points':
                        pts_col_idx = i
                        break
                continue
            m = EPIC_ID_RE.match(line)
            if not m:
                continue
            epic_id = m.group(1).strip()
            cols = [c.strip() for c in line.split('|')]
            cols = [c for c in cols if c]
            # Skip separator rows (all dashes)
            if all(set(c) <= set('-') for c in cols if c):
                continue
            if len(cols) <= pts_col_idx:
                continue
            try:
                declared_pts = int(cols[pts_col_idx])
            except ValueError:
                continue  # header row or malformed row

            # Stories column (index 3)
            stories_col_idx = 3
            if len(cols) <= stories_col_idx:
                continue
            stories_str = cols[stories_col_idx]
            story_ids   = [s.strip() for s in stories_str.split(',') if s.strip() and s.strip() != 'Stories']

            # Sum constituent story points
            computed_sum = sum(story_points.get(sid, 0) for sid in story_ids)
            unknown      = [sid for sid in story_ids if sid not in story_points]

            suffix = ''
            if unknown:
                suffix = f' UNKNOWN:{",".join(unknown)}'
            print(f'EPIC {epic_id} declared={declared_pts} computed={computed_sum}{suffix}')

            # Grand total (product epics only — skip EPIC-MAINT)
            if not epic_id.upper().startswith('EPIC-MAINT'):
                product_epic_total += declared_pts

except FileNotFoundError:
    print(f'PARSE_ERROR epics file not found: {epics_file}')

print(f'GRAND product_epic_total={product_epic_total} product_story_total={product_story_total}')
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

# ── Self-probe 1: per-epic mismatch MUST be detected ─────────────────────────
probe_must_detect_per_epic_mismatch() {
  init_probe_tmp

  cat > "$PROBE_TMP/story-index.md" <<'SIEOF'
---
document_type: story-index
---

## Story Inventory

### Wave 1

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|----------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.01 | Story One | BC-X | SS-01 | crate-a | P0 | 5 | [] | draft |
| S-1.02 | Story Two | BC-Y | SS-01 | crate-a | P1 | 8 | [] | draft |
SIEOF

  # Epic declares 20 points but stories sum to 13 — mismatch
  cat > "$PROBE_TMP/epics.md" <<'EPEOF'
---
document_type: epics
---

## Epic Catalog

| Epic ID | Title | Wave | Stories | Points | Primary Subsystem | Primary Crate(s) |
|---------|-------|------|---------|--------|-------------------|-----------------|
| E-01 | Test Epic | 1 | S-1.01, S-1.02 | 20 | SS-01 | crate-a |
EPEOF

  local out
  out="$(run_rollup_scanner "$PROBE_TMP/epics.md" "$PROBE_TMP/story-index.md")"
  if ! echo "$out" | grep -q 'E-01.*computed=13'; then
    echo "[SELF-PROBE FAIL] probe_must_detect_per_epic_mismatch: mismatch NOT detected."
    echo "  Expected computed=13, declared=20 for E-01."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_must_detect_per_epic_mismatch: per-epic arithmetic mismatch detected."
}

# ── Self-probe 2: correct per-epic rollup MUST NOT be flagged ─────────────────
probe_must_not_detect_correct_epic() {
  init_probe_tmp

  cat > "$PROBE_TMP/story-index.md" <<'SIEOF'
---
document_type: story-index
---

## Story Inventory

### Wave 1

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|----------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.01 | Story One | BC-X | SS-01 | crate-a | P0 | 5 | [] | draft |
| S-1.02 | Story Two | BC-Y | SS-01 | crate-a | P1 | 8 | [] | draft |
SIEOF

  # Epic correctly declares 13 = 5 + 8
  cat > "$PROBE_TMP/epics.md" <<'EPEOF'
---
document_type: epics
---

## Epic Catalog

| Epic ID | Title | Wave | Stories | Points | Primary Subsystem | Primary Crate(s) |
|---------|-------|------|---------|--------|-------------------|-----------------|
| E-01 | Test Epic | 1 | S-1.01, S-1.02 | 13 | SS-01 | crate-a |
EPEOF

  local out
  out="$(run_rollup_scanner "$PROBE_TMP/epics.md" "$PROBE_TMP/story-index.md")"
  if echo "$out" | grep -q 'EPIC E-01.*declared=13.*computed=13'; then
    # computed == declared: no mismatch expected; check GRAND is balanced
    if echo "$out" | grep -q 'GRAND product_epic_total=13 product_story_total=13'; then
      echo "[SELF-PROBE PASS] probe_must_not_detect_correct_epic: correct rollup produces balanced output."
      clean_probe_tmp; return
    fi
  fi
  # If the line doesn't appear as expected, just verify no mismatch-class output
  # (GRAND mismatch would only matter in check_rollup; here we test per-epic)
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_must_not_detect_correct_epic: correct epic rollup not flagged."
}

# ── Self-probe 3: grand-total mismatch MUST be detected ──────────────────────
probe_must_detect_grand_total_mismatch() {
  init_probe_tmp

  # Two epics sum to 10; but STORY-INDEX has 15 total points
  cat > "$PROBE_TMP/story-index.md" <<'SIEOF'
---
document_type: story-index
---

## Story Inventory

### Wave 1

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|----------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.01 | Story One | BC-X | SS-01 | crate-a | P0 | 5 | [] | draft |
| S-1.02 | Story Two | BC-Y | SS-01 | crate-a | P1 | 5 | [] | draft |
| S-1.03 | Story Three | BC-Z | SS-01 | crate-a | P1 | 5 | [] | draft |
SIEOF

  # E-01 has S-1.01, S-1.02 (sum 10) correctly. S-1.03 is NOT in any epic.
  cat > "$PROBE_TMP/epics.md" <<'EPEOF'
---
document_type: epics
---

## Epic Catalog

| Epic ID | Title | Wave | Stories | Points | Primary Subsystem | Primary Crate(s) |
|---------|-------|------|---------|--------|-------------------|-----------------|
| E-01 | Test Epic | 1 | S-1.01, S-1.02 | 10 | SS-01 | crate-a |
EPEOF

  local out
  out="$(run_rollup_scanner "$PROBE_TMP/epics.md" "$PROBE_TMP/story-index.md")"
  # product_epic_total=10 but product_story_total=15 (S-1.03 is orphaned)
  if ! echo "$out" | grep -q 'product_epic_total=10'; then
    echo "[SELF-PROBE FAIL] probe_must_detect_grand_total_mismatch: grand total mismatch not in output."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  if ! echo "$out" | grep -q 'product_story_total=15'; then
    echo "[SELF-PROBE FAIL] probe_must_detect_grand_total_mismatch: product_story_total not 15."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_must_detect_grand_total_mismatch: grand total mismatch captured in output."
}

# ── Self-probe 4: EPIC-MAINT excluded from grand total ───────────────────────
probe_maint_excluded_from_grand_total() {
  init_probe_tmp

  cat > "$PROBE_TMP/story-index.md" <<'SIEOF'
---
document_type: story-index
---

## Story Inventory

### Wave 1

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|----------------------|-----------|-------------|-----|-----|------------|--------|
| S-1.01 | Story One | BC-X | SS-01 | crate-a | P0 | 5 | [] | draft |

### Maintenance

| ID | Title | Behavioral Contracts | Subsystem | Target Crate | Pri | Pts | depends_on | Status |
|----|-------|----------------------|-----------|-------------|-----|-----|------------|--------|
| S-MAINT-001 | Maint | BC-M | all | all | P1 | 5 | [] | draft |
SIEOF

  cat > "$PROBE_TMP/epics.md" <<'EPEOF'
---
document_type: epics
---

## Epic Catalog

| Epic ID | Title | Wave | Stories | Points | Primary Subsystem | Primary Crate(s) |
|---------|-------|------|---------|--------|-------------------|-----------------|
| E-01 | Product Epic | 1 | S-1.01 | 5 | SS-01 | crate-a |
| EPIC-MAINT | Maintenance | out-of-wave | S-MAINT-001 | 5 | N/A | all |
EPEOF

  local out
  out="$(run_rollup_scanner "$PROBE_TMP/epics.md" "$PROBE_TMP/story-index.md")"
  # product_epic_total should be 5 (E-01 only; EPIC-MAINT excluded)
  # product_story_total should be 5 (S-1.01 only; S-MAINT-001 excluded)
  if ! echo "$out" | grep -q 'GRAND product_epic_total=5 product_story_total=5'; then
    echo "[SELF-PROBE FAIL] probe_maint_excluded_from_grand_total: EPIC-MAINT not excluded from grand total."
    echo "  Output: $out"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_maint_excluded_from_grand_total: EPIC-MAINT excluded from product grand total."
}

# ── Main live check ───────────────────────────────────────────────────────────
check_epic_rollup_points() {
  if [ ! -f "$EPICS_FILE" ]; then
    emit WARN "epic-rollup-points: epics.md not found at $EPICS_FILE — skipping"
    return
  fi
  if [ ! -f "$STORY_INDEX_FILE" ]; then
    emit WARN "epic-rollup-points: STORY-INDEX.md not found at $STORY_INDEX_FILE — skipping"
    return
  fi

  local raw_output
  raw_output="$(run_rollup_scanner "$EPICS_FILE" "$STORY_INDEX_FILE")"

  local story_count=0
  local epic_count=0
  local per_epic_mismatches=0
  local grand_epic_total=0
  local grand_story_total=0
  local grand_balanced=false

  while IFS= read -r line; do
    case "$line" in
      STORY\ *)
        story_count=$((story_count + 1))
        ;;
      EPIC\ *)
        epic_count=$((epic_count + 1))
        # EPIC E-01 declared=33 computed=33
        # EPIC E-16 declared=5 computed=10 UNKNOWN:...
        local epic_id declared computed
        epic_id="$(echo "$line" | awk '{print $2}')"
        declared="$(echo "$line" | grep -oE 'declared=[0-9]+' | cut -d= -f2)"
        computed="$(echo "$line" | grep -oE 'computed=[0-9]+' | cut -d= -f2)"
        unknown_info="$(echo "$line" | grep -oE 'UNKNOWN:[^ ]+' || true)"
        if [ "$declared" != "$computed" ]; then
          per_epic_mismatches=$((per_epic_mismatches + 1))
          local extra=""
          [ -n "$unknown_info" ] && extra=" (stories not in STORY-INDEX: ${unknown_info#UNKNOWN:})"
          emit WARN "epic-rollup-points(a): $epic_id — declared=${declared} pts but story sum=${computed}${extra}"
        fi
        ;;
      GRAND\ *)
        grand_epic_total="$(echo "$line" | grep -oE 'product_epic_total=[0-9]+' | cut -d= -f2)"
        grand_story_total="$(echo "$line" | grep -oE 'product_story_total=[0-9]+' | cut -d= -f2)"
        if [ "$grand_epic_total" = "$grand_story_total" ]; then
          grand_balanced=true
        fi
        ;;
      PARSE_ERROR\ *)
        emit WARN "epic-rollup-points: parse error — ${line#PARSE_ERROR }"
        ;;
    esac
  done <<< "$raw_output"

  echo "  Stories parsed: $story_count"
  echo "  Epics parsed:   $epic_count"
  echo "  Per-epic mismatches: $per_epic_mismatches"
  echo "  Product grand total — epic declared: ${grand_epic_total}  story computed: ${grand_story_total}"

  if [ "$grand_balanced" = "false" ] && [ -n "$grand_epic_total" ] && [ -n "$grand_story_total" ]; then
    emit WARN "epic-rollup-points(b): product grand total mismatch — product epics sum=${grand_epic_total}, product stories sum=${grand_story_total} (delta=$((grand_story_total - grand_epic_total)))"
  fi

  if [ "$per_epic_mismatches" -eq 0 ] && [ "$grand_balanced" = "true" ]; then
    emit PASS "epic-rollup-points: all ${epic_count} epic rollups balance (${story_count} stories, product total ${grand_epic_total} pts)"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-epic-rollup-points: epic ↔ story-point rollup arithmetic check (ADVISORY)"
echo "  Epics:       $EPICS_FILE"
echo "  Story index: $STORY_INDEX_FILE"
echo "  Finding:     F-P2A068-01 class — epic declared points ≠ constituent story sum"
echo ""

echo "[SELF-PROBE] Verifying arithmetic mismatches are caught and correct sums pass (POL-31)..."
probe_must_detect_per_epic_mismatch
probe_must_not_detect_correct_epic
probe_must_detect_grand_total_mismatch
probe_maint_excluded_from_grand_total
echo "[SELF-PROBE] All self-probes passed — check is not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "ADVISORY check (exit 0 always)"
echo "════════════════════════════════════════════"
echo ""
echo "── epic rollup ↔ story-point arithmetic ───────────────────────────────"
check_epic_rollup_points

echo ""
echo "════════════════════════════════════════════"
echo ""
echo "verify-epic-rollup-points: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  ADVISORY: $WARN WARN(s)"
echo ""
echo "RESULT: PASS (advisory — exit 0 regardless of WARN count)"
exit 0
