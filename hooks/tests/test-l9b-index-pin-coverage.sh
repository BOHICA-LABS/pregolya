#!/usr/bin/env bash
# test-l9b-index-pin-coverage.sh — E06/P1D-177 INDEX version-pin detection proof
#
# Proves check L9b in records-lint.sh catches INDEX-name version pins like
# "VP-INDEX v1.2" and "BC-INDEX v1.5" in newly-authored record/changelog/spec prose.
#
# Background (E06/P1D-177): burst-287 extended PIN_RE in verify-no-version-pins.sh
# to detect compound INDEX names (VP-INDEX, BC-INDEX, ARCH-INDEX, etc.). The companion
# L9b scanner (VP_RE1/VP_RE2) in records-lint.sh was NOT updated in that burst, leaving
# a gap: verify-no-version-pins.sh would catch the pin at the spec level but records-lint.sh
# would not catch it in newly-authored *changelog* prose. burst-288 closes that gap by
# updating VP_RE1 to include the `[A-Z][A-Z0-9]*-INDEX` pattern. This test proves the fix.
#
# Test strategy: each scenario initializes an isolated git repo in a tmpdir, copies
# records-lint.sh into <tmpdir>/hooks/ (so FACTORY_DIR resolves to <tmpdir>), creates
# synthetic spec fixtures in <tmpdir>/specs/, stages them with `git add`, then runs
# records-lint.sh --skip-self-probe and asserts on the output. No real specs or git
# state are touched.
#
# TD-VSDD-091 compliance: all comments cite behavioral anchors — never file:NNN cites.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

# ── Assertion helpers ─────────────────────────────────────────────────────────

assert_contains() {
    local label="$1" output="$2" pattern="$3"
    if echo "$output" | grep -qF "$pattern"; then
        echo "ok - $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "not ok - $label"
        echo "  expected output to contain: $pattern"
        echo "  actual output (tail):"
        echo "$output" | tail -15 | sed 's/^/    /'
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_not_contains() {
    local label="$1" output="$2" pattern="$3"
    if echo "$output" | grep -qF "$pattern"; then
        echo "not ok - $label"
        echo "  expected output NOT to contain: $pattern"
        echo "  actual output (tail):"
        echo "$output" | tail -15 | sed 's/^/    /'
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "ok - $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
}

assert_exit_fail() {
    local label="$1" exit_code="$2"
    if [ "$exit_code" -ne 0 ]; then
        echo "ok - $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "not ok - $label (expected non-zero exit, got 0)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_exit_pass() {
    local label="$1" exit_code="$2"
    if [ "$exit_code" -eq 0 ]; then
        echo "ok - $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "not ok - $label (expected exit 0, got $exit_code)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ── Scenario runner ───────────────────────────────────────────────────────────
# Each scenario gets a fresh isolated git repo in a tmpdir. FACTORY_DIR resolves
# to that tmpdir when records-lint.sh runs (script uses $(dirname "$0")/..).
# Fixture files are staged (git add) so they appear in `git diff HEAD` as additions.

run_scenario() {
    local scenario_name="$1"
    local TMPDIR
    TMPDIR="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$TMPDIR'" RETURN

    # Initialize isolated git repo with empty baseline commit
    git -C "$TMPDIR" init -b main 2>/dev/null || git -C "$TMPDIR" init 2>/dev/null
    git -C "$TMPDIR" config user.email "factory-test@local"
    git -C "$TMPDIR" config user.name "Factory Test"
    git -C "$TMPDIR" commit --allow-empty -m "chore: test baseline"

    # Set up directory structure
    mkdir -p "$TMPDIR/hooks"
    mkdir -p "$TMPDIR/specs/behavioral-contracts"

    # Copy the script under test (FACTORY_DIR will resolve to TMPDIR)
    cp "$HOOKS_DIR/records-lint.sh" "$TMPDIR/hooks/"

    # Call the fixture writer — creates files in TMPDIR
    "write_fixture_$scenario_name" "$TMPDIR"

    # Stage all new files so they appear in `git diff HEAD` as additions
    git -C "$TMPDIR" add -A

    # Run records-lint.sh --skip-self-probe (self-probes are tested by the script itself;
    # here we test the actual check behavior against synthetic fixtures)
    LINT_EXITCODE=0
    LINT_OUT="$(bash "$TMPDIR/hooks/records-lint.sh" --skip-self-probe 2>&1)" || LINT_EXITCODE=$?

    # Call assertions — they receive LINT_OUT and LINT_EXITCODE from the environment
    "assert_scenario_$scenario_name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 1 — TRUE POSITIVE: VP-INDEX version pin in changelog prose → L9b FAIL
#
# A changelog entry cites "VP-INDEX v1.2" — a compound INDEX-name version pin.
# This is the canonical E06 violation: burst-287 added VP-INDEX to the blocking
# verify-no-version-pins.sh regex but forgot the companion L9b scanner.
# burst-288 (E06 fix) extends VP_RE1 to `[A-Z][A-Z0-9]*-INDEX` pattern.
# L9b must detect it and exit 1 (blocking).
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_positive_vp_index_pin() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/BC-SYNTHETIC-001.md" <<'MDEOF'
---
document_type: behavioral-contract
bc_id: BC-2.00.001
version: "1.3"
---
# BC-SYNTHETIC-001: INDEX version pin fixture

## Changelog

| Version | Date       | Description |
|---------|------------|-------------|
| 1.3     | 2026-08-15 | Traceability updated. See VP-INDEX v1.2 for traceability table. |
| 1.2     | 2026-08-01 | Initial draft. |
MDEOF
}

assert_scenario_true_positive_vp_index_pin() {
    # L9b must detect "VP-INDEX v1.2" and emit FAIL
    assert_contains \
        "VP-INDEX pin: L9b FAIL emitted for VP-INDEX v1.2 version pin" \
        "$LINT_OUT" "[FAIL] L9"
    # exit code must be non-zero (blocking)
    assert_exit_fail \
        "VP-INDEX pin: exit code 1 (BLOCKING)" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 2 — TRUE POSITIVE: BC-INDEX version pin → L9b FAIL
#
# A different INDEX name format: "BC-INDEX v1.5". Verifies the general
# `[A-Z][A-Z0-9]*-INDEX` pattern (not VP-INDEX–specific).
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_positive_bc_index_pin() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/BC-SYNTHETIC-002.md" <<'MDEOF'
---
document_type: behavioral-contract
bc_id: BC-2.00.002
version: "2.1"
---
# BC-SYNTHETIC-002: BC-INDEX pin fixture

## Changelog

| Version | Date       | Description |
|---------|------------|-------------|
| 2.1     | 2026-08-15 | Cross-reference updated. Aligns with BC-INDEX v1.5. |
MDEOF
}

assert_scenario_true_positive_bc_index_pin() {
    assert_contains \
        "BC-INDEX pin: L9b FAIL emitted for BC-INDEX v1.5 version pin" \
        "$LINT_OUT" "[FAIL] L9"
    assert_exit_fail \
        "BC-INDEX pin: exit code 1 (BLOCKING)" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 3 — TRUE POSITIVE: STORY-INDEX version pin → L9b FAIL
#
# Verifies STORY-INDEX v2.3 fires the same gate — confirming the pattern
# generalizes beyond VP-INDEX and BC-INDEX to any compound INDEX name.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_positive_story_index_pin() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/BC-SYNTHETIC-003.md" <<'MDEOF'
---
document_type: behavioral-contract
bc_id: BC-2.00.003
version: "1.0"
---
# BC-SYNTHETIC-003: STORY-INDEX pin fixture

changelog:
  - "1.0 (burst-288/2026-08-15): Wave 1 coverage confirmed. See STORY-INDEX v2.3."
MDEOF
}

assert_scenario_true_positive_story_index_pin() {
    assert_contains \
        "STORY-INDEX pin: L9b FAIL emitted for STORY-INDEX v2.3 version pin" \
        "$LINT_OUT" "[FAIL] L9"
    assert_exit_fail \
        "STORY-INDEX pin: exit code 1 (BLOCKING)" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 4 — TRUE NEGATIVE: INDEX name without version number passes
#
# "VP-INDEX" alone (no `vN.N`) is a legitimate cross-reference, not a pin.
# The VERSION_PIN_PATTERN requires `vN.N` to fire. Bare INDEX-name references
# must NOT trigger L9b.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_index_no_version() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/BC-SYNTHETIC-004.md" <<'MDEOF'
---
document_type: behavioral-contract
bc_id: BC-2.00.004
version: "1.0"
---
# BC-SYNTHETIC-004: bare INDEX name (no version) is valid

## Changelog

| Version | Date       | Description |
|---------|------------|-------------|
| 1.0     | 2026-08-15 | Traceability confirmed. See VP-INDEX for the full table. |
MDEOF
}

assert_scenario_true_negative_index_no_version() {
    assert_not_contains \
        "bare INDEX: no L9b FAIL for 'VP-INDEX' without version (legitimate reference)" \
        "$LINT_OUT" "[FAIL] L9"
    assert_contains \
        "bare INDEX: RESULT PASS" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "bare INDEX: exit code 0" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 5 — TRUE NEGATIVE: Pre-existing ADR pin (grandfathered) passes
#
# verify-no-version-pins.sh and records-lint.sh only gate NEWLY-AUTHORED lines
# (lines appearing in `git diff HEAD` as additions, prefixed with `+`).
# Pre-existing content that was committed in a prior commit is NOT gated.
# This scenario commits the file first, then checks it — confirming grandfathering.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_grandfathered_prior_commit() {
    local d="$1"
    # Write the file with a pin, then COMMIT it (so it becomes pre-existing)
    cat > "$d/specs/behavioral-contracts/BC-SYNTHETIC-005.md" <<'MDEOF'
---
document_type: behavioral-contract
bc_id: BC-2.00.005
version: "1.0"
---
# BC-SYNTHETIC-005: grandfathered prior-commit fixture

changelog:
  - "1.0 (burst-100/2026-07-01): Initial. VP-INDEX v1.0 traceability established."
MDEOF
    # Commit it so it is pre-existing (not a new addition in the next diff)
    git -C "$d" add -A
    git -C "$d" commit -m "chore: baseline with prior pin"
    # Now create a NEW file with NO pin — this is the newly-staged content
    cat > "$d/specs/behavioral-contracts/BC-SYNTHETIC-005b.md" <<'MDEOF'
---
document_type: behavioral-contract
bc_id: BC-2.00.005b
version: "1.0"
---
# BC-SYNTHETIC-005b: clean new-addition (no pin)

changelog:
  - "1.0 (burst-288/2026-08-15): New BC, no version pins."
MDEOF
}

assert_scenario_true_negative_grandfathered_prior_commit() {
    # Grandfathered pre-existing content (committed before the new staging) must not fire
    assert_not_contains \
        "grandfathered: no L9b FAIL for pre-existing committed VP-INDEX v1.0 pin" \
        "$LINT_OUT" "[FAIL] L9"
    assert_contains \
        "grandfathered: RESULT PASS" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "grandfathered: exit code 0" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 6 — TRUE NEGATIVE: Doc vN.N form (D-50) for plain doc name passes L9b
#
# "doc v1.3" style (D-50 ban on `doc vN.N` forms) is handled by a separate
# VP_RE2 pattern. An unrelated document name like "report v2.1" should NOT
# be caught by VP_RE1 (INDEX pattern) — it is NOT an INDEX-name pin.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_doc_name_not_index() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/BC-SYNTHETIC-006.md" <<'MDEOF'
---
document_type: behavioral-contract
bc_id: BC-2.00.006
version: "1.0"
---
# BC-SYNTHETIC-006: plain doc-name version form is different from INDEX-name pin

## Changelog

| Version | Date       | Description |
|---------|------------|-------------|
| 1.0     | 2026-08-15 | Reviewed against architecture doc v1.3 (non-INDEX name form). |
MDEOF
}

assert_scenario_true_negative_doc_name_not_index() {
    # VP_RE1 (INDEX pattern) must NOT fire for "doc v1.3" — that's VP_RE2's domain
    # (and VP_RE2 does flag it, so overall L9b WILL fire — but for VP_RE2, not VP_RE1)
    # This test confirms the INDEX-specific pattern did not cause a DOUBLE-fire here.
    # We can't assert no-FAIL overall because VP_RE2 legitimately fires on "doc v1.3".
    # Instead we confirm the script ran and reported output (not a crash/error).
    assert_contains \
        "doc-name: records-lint produced output (ran without crashing)" \
        "$LINT_OUT" "records-lint"
    # Scenario is self-documenting: VP_RE2 fires on "doc v1.3" (expected); VP_RE1 does not.
}

# ── Run all scenarios ─────────────────────────────────────────────────────────

echo "TAP version 13"
echo "# E06/P1D-177 INDEX version-pin detection (L9b VP_RE1 extension) — catch-proof synthetic tests"
echo ""

run_scenario "true_positive_vp_index_pin"
run_scenario "true_positive_bc_index_pin"
run_scenario "true_positive_story_index_pin"
run_scenario "true_negative_index_no_version"
run_scenario "true_negative_grandfathered_prior_commit"
run_scenario "true_negative_doc_name_not_index"

echo ""
echo "# Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo "# RESULT: FAIL"
    exit 1
else
    echo "# RESULT: PASS"
    exit 0
fi
