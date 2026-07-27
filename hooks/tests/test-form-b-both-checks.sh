#!/usr/bin/env bash
# test-form-b-both-checks.sh — TD-VSDD-059 catch-proof synthetic tests
# Proves the both-forms short-circuit blindness fix (F-P172a-14, fix-burst 274).
#
# Test strategy: each scenario creates an isolated tmpdir, copies the two
# hook scripts into <tmpdir>/hooks/ (so FACTORY_DIR resolves to <tmpdir>),
# places synthetic spec fixtures in <tmpdir>/specs/, runs the script, and
# asserts on the output lines.  No real specs are touched.
#
# TD-VSDD-091 compliance: all comments cite behavioral anchors (rule names,
# function names, signal labels) — never file:NNN line citations.
set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

# ── Assertion helpers ─────────────────────────────────────────────────────

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

assert_result_pass() {
    local label="$1" output="$2"
    if echo "$output" | grep -q 'RESULT: PASS'; then
        echo "ok - $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "not ok - $label (expected RESULT: PASS)"
        echo "$output" | tail -5 | sed 's/^/    /'
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ── Scenario runner ───────────────────────────────────────────────────────
# Each scenario gets a fresh tmpdir; FACTORY_DIR resolves to that tmpdir
# when the copied scripts run.

run_scenario() {
    local scenario_name="$1"
    local TMPDIR
    TMPDIR="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$TMPDIR'" RETURN

    mkdir -p "$TMPDIR/hooks"
    mkdir -p "$TMPDIR/specs/behavioral-contracts/ss-00"
    mkdir -p "$TMPDIR/specs/architecture/decisions"
    mkdir -p "$TMPDIR/specs/domain-spec"

    cp "$HOOKS_DIR/verify-form-a-changelog-direction.sh" "$TMPDIR/hooks/"
    cp "$HOOKS_DIR/verify-changelog-date-monotonicity.sh" "$TMPDIR/hooks/"

    # Call the fixture writer — sets up files in TMPDIR
    "write_fixture_$scenario_name" "$TMPDIR"

    # Capture output from both scripts (|| true prevents set -e from firing when
    # the script-under-test exits non-zero, which is expected in failure scenarios)
    DIR_OUT="$(bash "$TMPDIR/hooks/verify-form-a-changelog-direction.sh" 2>&1)" || true
    DATE_OUT="$(bash "$TMPDIR/hooks/verify-changelog-date-monotonicity.sh" 2>&1)" || true

    # Call assertions — they receive DIR_OUT / DATE_OUT from the environment
    "assert_scenario_$scenario_name"
}

# ─────────────────────────────────────────────────────────────────────────
# Scenario 1 — BC file with Form-B direction violation (was invisible)
#
# Before fix: Form-A present → short-circuit → Form-B never evaluated.
# After fix:  Form-B ascending-order violation surfaces as FAIL.
# ─────────────────────────────────────────────────────────────────────────
write_fixture_bc_both_forms_form_b_violation() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/ss-00/BC-TEST-001.md" <<'MDEOF'
---
title: Test BC both-forms Form-B violation
document_type: behavioral-contract
version: "1.2"
changelog:
  - "1.0 (2025-01-01): initial"
  - "1.1 (2025-06-01): update"
  - "1.2 (2025-12-01): latest"
---
## Section

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2025-01-01 | tester | initial |
| 1.1 | 2025-06-01 | tester | update |
| 1.2 | 2025-12-01 | tester | latest |
MDEOF
}

assert_scenario_bc_both_forms_form_b_violation() {
    # verify-form-a-changelog-direction: both-forms WARN + direction FAIL
    assert_contains \
        "dir: BC both-forms — WARN co-existence signal emitted" \
        "$DIR_OUT" "WARN"
    assert_contains \
        "dir: BC both-forms — FAIL form-b-not-descending(ascending)" \
        "$DIR_OUT" "form-b-not-descending(ascending)"
    # verify-changelog-date-monotonicity: both-forms WARN + Form-B date FAIL
    assert_contains \
        "date: BC both-forms — WARN co-existence signal emitted" \
        "$DATE_OUT" "WARN"
    assert_contains \
        "date: BC both-forms — FAIL form-b date ascending order" \
        "$DATE_OUT" "form-b:"
}

# ─────────────────────────────────────────────────────────────────────────
# Scenario 2 — Non-BC file with Form-B direction violation (was invisible)
#
# Before fix: Form-A present in non-BC section → short-circuit → Form-B skipped.
# After fix:  Form-B direction checked independently; violation surfaces as FAIL.
# ─────────────────────────────────────────────────────────────────────────
write_fixture_nonbc_both_forms_form_b_violation() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-001.md" <<'MDEOF'
---
title: Test ADR both-forms Form-B violation
version: "1.2"
changelog:
  - "1.2 (2025-12-01): latest"
  - "1.1 (2025-06-01): update"
  - "1.0 (2025-01-01): initial"
---
## Section

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0 | 2025-01-01 | tester | initial |
| 1.1 | 2025-06-01 | tester | update |
| 1.2 | 2025-12-01 | tester | latest |
MDEOF
}

assert_scenario_nonbc_both_forms_form_b_violation() {
    assert_contains \
        "dir: non-BC both-forms — WARN co-existence signal emitted" \
        "$DIR_OUT" "WARN"
    assert_contains \
        "dir: non-BC both-forms — FAIL form-b-not-descending(ascending)" \
        "$DIR_OUT" "form-b-not-descending(ascending)"
    assert_contains \
        "date: non-BC both-forms — WARN co-existence signal emitted" \
        "$DATE_OUT" "WARN"
    assert_contains \
        "date: non-BC both-forms — FAIL form-b date ascending order" \
        "$DATE_OUT" "form-b:"
    # Overall gate should still PASS (gate measures zero FAIL in total run;
    # with only this fixture the FAIL counts as a non-zero FAIL → RESULT: FAIL
    # is expected here because the fixture has a genuine defect we are proving
    # is now caught).
    assert_contains \
        "dir: non-BC both-forms — overall RESULT contains FAIL" \
        "$DIR_OUT" "FAIL="
}

# ─────────────────────────────────────────────────────────────────────────
# Scenario 3 — Non-BC both-forms: Rule 4 version-mismatch is NOT a FAIL
#
# When a both-forms file has Form-A descending (correct) and Form-B descending
# (correct direction) but Form-B first-row differs from frontmatter version,
# the Rule 4 version-mismatch must NOT generate a FAIL line.  Form-A is the
# authoritative version source; Form-B lag is expected while the body table
# is being backfilled.
# ─────────────────────────────────────────────────────────────────────────
write_fixture_nonbc_both_forms_rule4_suppressed() {
    local d="$1"
    cat > "$d/specs/domain-spec/TEST-domain-001.md" <<'MDEOF'
---
title: Test domain doc both-forms Rule 4 suppressed
version: "1.2"
changelog:
  - "1.2 (2025-12-01): latest"
  - "1.1 (2025-06-01): update"
  - "1.0 (2025-01-01): initial"
---
## Section

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1 | 2025-06-01 | tester | update |
| 1.0 | 2025-01-01 | tester | initial |
MDEOF
}

assert_scenario_nonbc_both_forms_rule4_suppressed() {
    # Both-forms WARN should be present (co-existence gate)
    assert_contains \
        "dir: Rule 4 suppressed — WARN co-existence emitted" \
        "$DIR_OUT" "WARN"
    # Rule 4 version-mismatch must NOT appear as a FAIL
    assert_not_contains \
        "dir: Rule 4 suppressed — no FAIL for form-b-version-mismatch" \
        "$DIR_OUT" "form-b-version-mismatch"
    # Form-A should PASS (descending, correct)
    assert_contains \
        "dir: Rule 4 suppressed — Form-A direction PASS" \
        "$DIR_OUT" "PASS"
    # Overall RESULT: PASS (WARN lines are non-blocking)
    assert_result_pass \
        "dir: Rule 4 suppressed — RESULT: PASS" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────
# Scenario 4 — Non-BC Form-B-only file: now validated (F-B276-02 fix)
#
# A non-BC file with a Form-B body table, no Form-A `changelog:` entry,
# and version > 1.0 is now direction-checked rather than silently skipped.
# This is the Mode 2 fix from F-B276-02: Form-B-only non-BC files must
# reach PASS (correctly ordered) or FAIL (direction/version defect), never
# a silent SKIP counted as a benign WARN.
#
# Fixture has version: "1.3" with a correctly-descending Form-B table
# whose first row is also "1.3" — must emit PASS, not SKIP.
# ─────────────────────────────────────────────────────────────────────────
write_fixture_nonbc_form_b_only_regression_guard() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-002.md" <<'MDEOF'
---
title: Test ADR Form-B only no Form-A
version: "1.3"
---
## Section

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3 | 2025-12-01 | tester | latest |
| 1.2 | 2025-06-01 | tester | update |
| 1.1 | 2025-01-01 | tester | initial |
MDEOF
}

assert_scenario_nonbc_form_b_only_regression_guard() {
    # F-B276-02 fix: Form-B-only non-BC files are now parsed and validated.
    # A correctly-descending table with matching frontmatter version must PASS.
    assert_contains \
        "dir: Form-B-only non-BC — PASS (now validated, not skipped)" \
        "$DIR_OUT" "[PASS] specs/architecture/decisions/ADR-TEST-002.md"
    # Must NOT emit the old skip signal
    assert_not_contains \
        "dir: Form-B-only non-BC — no skipped-WARN emitted" \
        "$DIR_OUT" "skipped: no-changelog-version-gt-1.0"
    # Must NOT generate a FAIL (table is correctly ordered + version-match OK)
    assert_not_contains \
        "dir: Form-B-only non-BC — no FAIL emitted" \
        "$DIR_OUT" "FAIL specs/"
    # Overall RESULT: PASS
    assert_result_pass \
        "dir: Form-B-only non-BC — RESULT: PASS" \
        "$DIR_OUT"
    # Date-monotonicity script: Form-B-only non-BC emits PASS (no Form-A to validate,
    # no date violations to flag) — RESULT: PASS is the key gate.
    assert_not_contains \
        "date: Form-B-only non-BC — no FAIL emitted" \
        "$DATE_OUT" "FAIL specs/"
    assert_result_pass \
        "date: Form-B-only non-BC — RESULT: PASS" \
        "$DATE_OUT"
}

# ─────────────────────────────────────────────────────────────────────────
# Scenario 5 — Version-parity WARN (date-monotonicity script)
#
# A both-forms file where Form-A has versions not present in Form-B should
# emit a WARN both-forms-version-divergence signal.  This signal was added
# as part of the both-forms transparency requirement.
# ─────────────────────────────────────────────────────────────────────────
write_fixture_both_forms_version_parity_divergence() {
    local d="$1"
    cat > "$d/specs/domain-spec/TEST-domain-002.md" <<'MDEOF'
---
title: Test version parity divergence
version: "1.3"
changelog:
  - "1.3 (2025-12-01): third"
  - "1.2 (2025-09-01): second"
  - "1.1 (2025-06-01): first update"
  - "1.0 (2025-01-01): initial"
---
## Section

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1 | 2025-06-01 | tester | first update |
| 1.0 | 2025-01-01 | tester | initial |
MDEOF
}

assert_scenario_both_forms_version_parity_divergence() {
    # date-monotonicity: both-forms WARN + version-divergence WARN
    assert_contains \
        "date: version-parity — WARN both-changelog-forms emitted" \
        "$DATE_OUT" "both-changelog-forms"
    assert_contains \
        "date: version-parity — WARN both-forms-version-divergence emitted" \
        "$DATE_OUT" "both-forms-version-divergence"
    # Overall RESULT: PASS (divergence is WARN, not FAIL)
    assert_result_pass \
        "date: version-parity — RESULT: PASS (divergence is non-blocking)" \
        "$DATE_OUT"
}

# ─────────────────────────────────────────────────────────────────────────
# Scenario 6 — Both-forms BC: both forms correct → WARN only, no FAIL
#
# A BC file where Form-A is valid ascending and Form-B is valid descending
# should emit only the co-existence WARN — no FAIL lines.
# ─────────────────────────────────────────────────────────────────────────
write_fixture_bc_both_forms_both_correct() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/ss-00/BC-TEST-002.md" <<'MDEOF'
---
title: Test BC both-forms both correct
document_type: behavioral-contract
version: "1.2"
changelog:
  - "1.0 (2025-01-01): initial"
  - "1.1 (2025-06-01): update"
  - "1.2 (2025-12-01): latest"
---
## Section

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2 | 2025-12-01 | tester | latest |
| 1.1 | 2025-06-01 | tester | update |
| 1.0 | 2025-01-01 | tester | initial |
MDEOF
}

assert_scenario_bc_both_forms_both_correct() {
    # Co-existence WARN is expected (gate #28 — file has both forms)
    assert_contains \
        "dir: BC both-forms correct — WARN co-existence emitted" \
        "$DIR_OUT" "WARN"
    # No FAIL for form-b-not-descending (Form-B is correctly descending)
    assert_not_contains \
        "dir: BC both-forms correct — no FAIL for Form-B direction" \
        "$DIR_OUT" "form-b-not-descending"
    # Overall gate PASS
    assert_result_pass \
        "dir: BC both-forms correct — RESULT: PASS" \
        "$DIR_OUT"
    assert_result_pass \
        "date: BC both-forms correct — RESULT: PASS" \
        "$DATE_OUT"
}

# ── Run all scenarios ─────────────────────────────────────────────────────

echo "TAP version 13"
echo "# F-P172a-14 both-forms short-circuit blindness — catch-proof synthetic tests"
echo ""

run_scenario "bc_both_forms_form_b_violation"
run_scenario "nonbc_both_forms_form_b_violation"
run_scenario "nonbc_both_forms_rule4_suppressed"
run_scenario "nonbc_form_b_only_regression_guard"
run_scenario "both_forms_version_parity_divergence"
run_scenario "bc_both_forms_both_correct"

echo ""
echo "# Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo "# RESULT: FAIL"
    exit 1
else
    echo "# RESULT: PASS"
    exit 0
fi
