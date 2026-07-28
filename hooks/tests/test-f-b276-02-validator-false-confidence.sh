#!/usr/bin/env bash
# test-f-b276-02-validator-false-confidence.sh — F-B276-02 catch-proof synthetic tests
#
# Proves the two false-confidence modes found in finding F-B276-02:
#
#   Mode 1 — vacuous PASS: files with no `version:` frontmatter field reach
#             PASS having been checked for nothing.  Fixed by emitting
#             UNVERIFIED instead.
#
#   Mode 2 — silent skip counted as benign WARN: Form-B-only non-BC files
#             (version > 1.0, body `## Changelog` table, no frontmatter
#             `changelog:` list) were emitted as SKIP→WARN, indistinguishable
#             from advisory WARNs.  Fixed by parsing and direction-checking
#             the Form-B table directly.
#
# Test strategy: each scenario creates an isolated tmpdir, copies the validator
# script into <tmpdir>/hooks/, places synthetic spec fixtures in <tmpdir>/specs/,
# runs the script, and asserts on output lines.  No real specs are touched.
#
# False-negative self-check (documented boundaries — not test scenarios):
#   1. Form-B version cells with 'v' prefix (e.g. '| v1.3 |') are NOT matched
#      by FORM_B_VERSION_RE (which requires bare digits).  The corpus uses bare
#      numeric cells, so this is not a current false-negative risk.  If a future
#      file uses 'v'-prefixed Form-B cells the validator will emit
#      SKIP→UNVERIFIED no-changelog-version-gt-1.0 (catches the gap indirectly).
#   2. Form-B tables under `### Changelog` (H3) rather than `## Changelog` (H2)
#      would not be found.  The corpus uses H2 throughout.  A future H3 table
#      would result in SKIP→UNVERIFIED no-changelog-version-gt-1.0 rather than
#      PASS, so the file would not gain false confidence.
#   3. Equal consecutive versions (e.g. 1.3, 1.3 in Form-B): tested explicitly
#      by scenario 9 — caught as FAIL.
#
# TD-VSDD-091 compliance: all comments cite behavioral anchors (rule names,
# function names, signal labels) — never file:NNN line citations.
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

assert_result_fail() {
    local label="$1" output="$2"
    if echo "$output" | grep -q 'RESULT: FAIL'; then
        echo "ok - $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "not ok - $label (expected RESULT: FAIL)"
        echo "$output" | tail -5 | sed 's/^/    /'
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ── Scenario runner ───────────────────────────────────────────────────────────
# Each scenario gets a fresh tmpdir; FACTORY_DIR resolves to that tmpdir
# when the copied script runs.

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
    mkdir -p "$TMPDIR/specs/prd-supplements"

    cp "$HOOKS_DIR/verify-form-a-changelog-direction.sh" "$TMPDIR/hooks/"

    # Call the fixture writer — sets up files in TMPDIR
    "write_fixture_$scenario_name" "$TMPDIR"

    # Capture output (|| true: set -e must not fire on expected non-zero exits)
    DIR_OUT="$(bash "$TMPDIR/hooks/verify-form-a-changelog-direction.sh" 2>&1)" || true

    # Call assertions — they receive DIR_OUT from the environment
    "assert_scenario_$scenario_name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 1 — Mode 1: no-version-field → UNVERIFIED, not PASS
#
# A non-BC ADR file with no `version:` field and no changelog must emit
# UNVERIFIED rather than silently PASS.  This is the primary Mode 1 false-
# confidence gap identified in F-B276-02.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_no_version_field_unverified() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-NO-VERSION.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-no-version
title: "Test ADR with no version field"
status: accepted
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
---

# ADR-TEST: No Version Field

Content without version or changelog.
MDEOF
}

assert_scenario_no_version_field_unverified() {
    # Must emit [UNVERIFIED] with no-version-field reason
    assert_contains \
        "no-version-field: [UNVERIFIED] emitted" \
        "$DIR_OUT" "[UNVERIFIED]"
    assert_contains \
        "no-version-field: reason is no-version-field" \
        "$DIR_OUT" "no-version-field"
    # Must NOT emit [PASS] for this file — that is the false-confidence being fixed
    assert_not_contains \
        "no-version-field: must not emit [PASS] for file" \
        "$DIR_OUT" "[PASS] specs/architecture/decisions/ADR-TEST-NO-VERSION.md"
    # Summary must include UNVERIFIED=1 (only one file in fixture)
    assert_contains \
        "no-version-field: summary shows UNVERIFIED=1" \
        "$DIR_OUT" "UNVERIFIED=1"
    # Overall gate still PASS (UNVERIFIED is non-blocking)
    assert_result_pass \
        "no-version-field: RESULT: PASS (UNVERIFIED is non-blocking)" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 2 — Mode 2: Form-B-only non-BC correct descending → PASS
#
# A non-BC file with version > 1.0, no frontmatter `changelog:` list, and a
# body `## Changelog` table in correct descending order must emit PASS (not
# SKIP→WARN).  This is the primary Mode 2 fix.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_form_b_only_nonbc_correct_descending() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-FORM-B-PASS.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-form-b-pass
title: "Test ADR Form-B correct descending"
status: accepted
version: "1.3"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
---

# ADR-TEST: Form-B Correct Descending

## Decision

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3 | 2026-07-03 | architect | third revision |
| 1.2 | 2026-07-02 | architect | second revision |
| 1.1 | 2026-07-01 | architect | initial revision |
MDEOF
}

assert_scenario_form_b_only_nonbc_correct_descending() {
    # Must emit [PASS] for the file (Form-B is correctly descending)
    assert_contains \
        "form-b-correct-descending: [PASS] emitted" \
        "$DIR_OUT" "[PASS] specs/architecture/decisions/ADR-TEST-FORM-B-PASS.md"
    # Must NOT emit WARN skipped for this file
    assert_not_contains \
        "form-b-correct-descending: no skipped-WARN emitted" \
        "$DIR_OUT" "skipped: no-changelog-version-gt-1.0"
    # Must NOT emit [FAIL] for this file
    assert_not_contains \
        "form-b-correct-descending: no [FAIL] emitted" \
        "$DIR_OUT" "[FAIL] specs/"
    # Must NOT emit [UNVERIFIED] for this file
    assert_not_contains \
        "form-b-correct-descending: no [UNVERIFIED] emitted" \
        "$DIR_OUT" "[UNVERIFIED]"
    # Summary: PASS=1, WARN=0, FAIL=0, UNVERIFIED=0
    assert_contains \
        "form-b-correct-descending: summary PASS=1" \
        "$DIR_OUT" "PASS=1"
    assert_contains \
        "form-b-correct-descending: summary UNVERIFIED=0" \
        "$DIR_OUT" "UNVERIFIED=0"
    assert_result_pass \
        "form-b-correct-descending: RESULT: PASS" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 3 — Form-B-only non-BC ascending order → FAIL
#
# A non-BC file with a Form-B body table in ASCENDING order must emit FAIL.
# Non-BC files use the DESCENDING convention.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_form_b_only_nonbc_ascending_fail() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-FORM-B-FAIL.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-form-b-fail
title: "Test ADR Form-B ascending order (wrong for non-BC)"
status: accepted
version: "1.3"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
---

# ADR-TEST: Form-B Wrong Ascending

## Decision

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1 | 2026-07-01 | architect | initial revision |
| 1.2 | 2026-07-02 | architect | second revision |
| 1.3 | 2026-07-03 | architect | third revision |
MDEOF
}

assert_scenario_form_b_only_nonbc_ascending_fail() {
    # Must emit [FAIL] for the ascending Form-B table
    assert_contains \
        "form-b-ascending-fail: [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    assert_contains \
        "form-b-ascending-fail: ascending defect identified" \
        "$DIR_OUT" "form-b-not-descending(ascending)"
    # Also emits version-mismatch: frontmatter=1.3 but first row = 1.1
    assert_contains \
        "form-b-ascending-fail: version-mismatch also detected" \
        "$DIR_OUT" "form-b-version-mismatch"
    # Overall RESULT: FAIL
    assert_result_fail \
        "form-b-ascending-fail: RESULT: FAIL" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 4 — Form-B-only non-BC version-mismatch → FAIL
#
# A non-BC file with a correctly-descending Form-B table but where the
# frontmatter `version:` does not match the first (newest) row must FAIL.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_form_b_only_nonbc_version_mismatch_fail() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-FORM-B-VMATCH.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-form-b-version-mismatch
title: "Test ADR Form-B version-mismatch (frontmatter v1.3, first row v1.2)"
status: accepted
version: "1.3"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
---

# ADR-TEST: Form-B Version Mismatch

## Decision

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2 | 2026-07-02 | architect | second revision |
| 1.1 | 2026-07-01 | architect | initial revision |
MDEOF
}

assert_scenario_form_b_only_nonbc_version_mismatch_fail() {
    # Must emit [FAIL] for the version-mismatch
    assert_contains \
        "form-b-vmatch-fail: [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    assert_contains \
        "form-b-vmatch-fail: version-mismatch defect identified" \
        "$DIR_OUT" "form-b-version-mismatch"
    assert_contains \
        "form-b-vmatch-fail: frontmatter version in defect detail" \
        "$DIR_OUT" "frontmatter=1.3"
    # Direction is correct (descending) so no direction defect
    assert_not_contains \
        "form-b-vmatch-fail: no direction defect emitted" \
        "$DIR_OUT" "form-b-not-descending"
    # Overall RESULT: FAIL
    assert_result_fail \
        "form-b-vmatch-fail: RESULT: FAIL" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 5 — Non-BC Form-A correct DESCENDING → PASS
#
# A non-BC file (ADR/architecture/) with a frontmatter `changelog:` list in
# correct DESCENDING order must emit PASS.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_nonbc_form_a_correct_descending() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-FORM-A-PASS.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-form-a-pass
title: "Test ADR Form-A correct descending"
status: accepted
version: "1.3"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
changelog:
  - "1.3 (2026-07-03): third revision"
  - "1.2 (2026-07-02): second revision"
  - "1.1 (2026-07-01): initial revision"
---

# ADR-TEST: Form-A Correct Descending

Content.
MDEOF
}

assert_scenario_nonbc_form_a_correct_descending() {
    # Must emit [PASS]
    assert_contains \
        "nonbc-form-a-pass: [PASS] emitted" \
        "$DIR_OUT" "[PASS] specs/architecture/decisions/ADR-TEST-FORM-A-PASS.md"
    # Must NOT emit [FAIL] or [UNVERIFIED]
    assert_not_contains \
        "nonbc-form-a-pass: no [FAIL] emitted" \
        "$DIR_OUT" "[FAIL] specs/"
    assert_not_contains \
        "nonbc-form-a-pass: no [UNVERIFIED] emitted" \
        "$DIR_OUT" "[UNVERIFIED]"
    # Summary RESULT: PASS
    assert_result_pass \
        "nonbc-form-a-pass: RESULT: PASS" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 6 — Non-BC Form-A wrong order (ASCENDING) → FAIL
#
# A non-BC file with a frontmatter `changelog:` list in ASCENDING order
# (oldest first) must emit FAIL.  Non-BC files require DESCENDING.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_nonbc_form_a_ascending_fail() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-FORM-A-FAIL.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-form-a-fail
title: "Test ADR Form-A ascending (wrong for non-BC)"
status: accepted
version: "1.3"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
changelog:
  - "1.1 (2026-07-01): initial revision"
  - "1.2 (2026-07-02): second revision"
  - "1.3 (2026-07-03): third revision"
---

# ADR-TEST: Form-A Wrong Ascending

Content.
MDEOF
}

assert_scenario_nonbc_form_a_ascending_fail() {
    # Must emit [FAIL] for ascending order
    assert_contains \
        "nonbc-form-a-ascending-fail: [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    assert_contains \
        "nonbc-form-a-ascending-fail: ascending defect identified" \
        "$DIR_OUT" "ascending:1.1,1.2,1.3"
    # Overall RESULT: FAIL
    assert_result_fail \
        "nonbc-form-a-ascending-fail: RESULT: FAIL" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 7 — BC Form-A correct ASCENDING → PASS (positive case)
#
# A behavioral-contract file with a frontmatter `changelog:` list in correct
# ASCENDING order (oldest first, newest last) must emit PASS.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_bc_form_a_correct_ascending() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/ss-00/BC-TEST-ASCENDING.md" <<'MDEOF'
---
title: Test BC Form-A correct ascending
document_type: behavioral-contract
version: "1.3"
changelog:
  - "1.1 (2026-07-01): initial"
  - "1.2 (2026-07-02): update"
  - "1.3 (2026-07-03): latest"
---
## Section

Content.
MDEOF
}

assert_scenario_bc_form_a_correct_ascending() {
    # Must emit [PASS]
    assert_contains \
        "bc-form-a-ascending: [PASS] emitted" \
        "$DIR_OUT" "[PASS] specs/behavioral-contracts/ss-00/BC-TEST-ASCENDING.md"
    # Must NOT emit [FAIL] or [UNVERIFIED]
    assert_not_contains \
        "bc-form-a-ascending: no [FAIL] emitted" \
        "$DIR_OUT" "[FAIL] specs/"
    assert_not_contains \
        "bc-form-a-ascending: no [UNVERIFIED] emitted" \
        "$DIR_OUT" "[UNVERIFIED]"
    # Summary RESULT: PASS
    assert_result_pass \
        "bc-form-a-ascending: RESULT: PASS" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 8 — BC Form-A wrong order (DESCENDING) → FAIL
#
# A BC file with a frontmatter `changelog:` list in DESCENDING order
# (newest first) must emit FAIL.  BC files require ASCENDING.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_bc_form_a_descending_fail() {
    local d="$1"
    cat > "$d/specs/behavioral-contracts/ss-00/BC-TEST-DESCENDING-FAIL.md" <<'MDEOF'
---
title: Test BC Form-A descending (wrong)
document_type: behavioral-contract
version: "1.3"
changelog:
  - "1.3 (2026-07-03): latest"
  - "1.2 (2026-07-02): update"
  - "1.1 (2026-07-01): initial"
---
## Section

Content.
MDEOF
}

assert_scenario_bc_form_a_descending_fail() {
    # Must emit [FAIL] for descending order
    assert_contains \
        "bc-form-a-descending-fail: [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    assert_contains \
        "bc-form-a-descending-fail: descending defect identified" \
        "$DIR_OUT" "descending:1.3,1.2,1.1"
    # Overall RESULT: FAIL
    assert_result_fail \
        "bc-form-a-descending-fail: RESULT: FAIL" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 9 — Summary line includes UNVERIFIED= counter
#
# The summary line must always include UNVERIFIED=N.  This proves the key
# requirement: no future reader can mistake "not checked" for "checked and fine"
# by reading the summary.  Uses the no-version-field fixture to generate a
# non-zero UNVERIFIED count.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_summary_unverified_counter() {
    local d="$1"
    # File with no version: field — triggers UNVERIFIED
    cat > "$d/specs/architecture/decisions/ADR-TEST-NO-VER.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-no-ver
title: "Test ADR no version field"
status: accepted
producer: architect
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
---

Content.
MDEOF
    # Clean file with version and correct changelog
    cat > "$d/specs/architecture/decisions/ADR-TEST-CLEAN.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST2"
slug: test-clean
title: "Test ADR clean"
status: accepted
version: "1.2"
producer: architect
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
changelog:
  - "1.2 (2026-07-02): second"
  - "1.1 (2026-07-01): initial"
---

Content.
MDEOF
}

assert_scenario_summary_unverified_counter() {
    # Summary line MUST contain UNVERIFIED= (even when zero — structural proof)
    assert_contains \
        "summary-counter: summary line includes UNVERIFIED=" \
        "$DIR_OUT" "UNVERIFIED="
    # With one no-version-field file: UNVERIFIED=1
    assert_contains \
        "summary-counter: UNVERIFIED=1 for one no-version file" \
        "$DIR_OUT" "UNVERIFIED=1"
    # Clean file must PASS
    assert_contains \
        "summary-counter: clean file PASSes" \
        "$DIR_OUT" "[PASS] specs/architecture/decisions/ADR-TEST-CLEAN.md"
    # No-version file must UNVERIFIED
    assert_contains \
        "summary-counter: no-version file is UNVERIFIED" \
        "$DIR_OUT" "[UNVERIFIED]"
    # Overall RESULT: PASS (UNVERIFIED is non-blocking)
    assert_result_pass \
        "summary-counter: RESULT: PASS (UNVERIFIED non-blocking)" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 10 — Form-B equal consecutive versions → FAIL
#
# False-negative self-check: equal consecutive versions in a Form-B table
# (1.3, 1.3) must FAIL strict-descent check.  Verifies the `curr >= prev`
# gate fires on equality (not just on ascending pairs).
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_form_b_equal_consecutive_fail() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-FORM-B-EQUAL.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-form-b-equal
title: "Test ADR Form-B equal consecutive versions"
status: accepted
version: "1.3"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
---

# ADR-TEST: Form-B Equal Consecutive

## Decision

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3 | 2026-07-03 | architect | third revision |
| 1.3 | 2026-07-02 | architect | duplicate version — must fail |
| 1.1 | 2026-07-01 | architect | initial revision |
MDEOF
}

assert_scenario_form_b_equal_consecutive_fail() {
    # Must emit [FAIL] — equal consecutive versions violate strict descent
    assert_contains \
        "form-b-equal-fail: [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    assert_contains \
        "form-b-equal-fail: form-b-not-descending defect identified" \
        "$DIR_OUT" "form-b-not-descending"
    # Overall RESULT: FAIL
    assert_result_fail \
        "form-b-equal-fail: RESULT: FAIL" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 11 — Form-B version numeric comparison: 1.10 > 1.9
#
# False-negative self-check: the validator must use numeric tuple comparison
# (1,10) > (1,9), not string comparison '1.10' < '1.9'.  A table with 1.10
# at the top (correctly newer) followed by 1.9 must PASS.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_form_b_numeric_version_compare() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-FORM-B-NUMERIC.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-form-b-numeric
title: "Test ADR Form-B numeric version comparison (1.10 > 1.9)"
status: accepted
version: "1.10"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
---

# ADR-TEST: Form-B Numeric Version

## Decision

Content.

## Changelog

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.10 | 2026-07-10 | architect | tenth revision |
| 1.9 | 2026-07-09 | architect | ninth revision |
| 1.8 | 2026-07-08 | architect | eighth revision |
MDEOF
}

assert_scenario_form_b_numeric_version_compare() {
    # 1.10 > 1.9 numerically — table is correctly descending, must PASS
    assert_contains \
        "form-b-numeric: [PASS] emitted (1.10 correctly > 1.9)" \
        "$DIR_OUT" "[PASS] specs/architecture/decisions/ADR-TEST-FORM-B-NUMERIC.md"
    # Must NOT emit [FAIL] — string comparison '1.10' < '1.9' would be a false negative
    assert_not_contains \
        "form-b-numeric: no [FAIL] emitted" \
        "$DIR_OUT" "[FAIL] specs/"
    assert_result_pass \
        "form-b-numeric: RESULT: PASS" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 12 — rev-N format, correctly DESCENDING, no version: field
#
# A non-BC ADR with rev-N changelog entries in correct DESCENDING order (larger
# N first = newer first) and no version: field must:
#   - NOT emit [WARN] non-standard-rev-format (that was the false-confidence gap)
#   - Verify direction (pass — seq is correctly decreasing)
#   - Emit [UNVERIFIED] no-version-field (Rule 6 cannot be satisfied)
#   - Overall RESULT: PASS (UNVERIFIED is non-blocking)
#
# This scenario mirrors ADR-001 and ADR-006 from the real corpus.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_rev_n_descending_no_version() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-REV-N-PASS.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-rev-n-descending
title: "Test ADR rev-N correctly descending, no version field"
status: accepted
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
changelog:
  - "rev-3 (FIX-BURST-999/2026-07-03): third amendment body"
  - "rev-2 (ADV-P1D-PASS-42/2026-07-02): second amendment body"
  - "rev-1 (ADV-P1D-PASS-29/2026-07-01): initial amendment body"
---

# ADR-TEST: rev-N Descending, No Version Field

Content.
MDEOF
}

assert_scenario_rev_n_descending_no_version() {
    # Direction is verified (descending) but version: absent — must emit UNVERIFIED
    assert_contains \
        "rev-n-descending-no-version: [UNVERIFIED] emitted" \
        "$DIR_OUT" "[UNVERIFIED]"
    assert_contains \
        "rev-n-descending-no-version: reason is no-version-field" \
        "$DIR_OUT" "no-version-field"
    # Must NOT emit [WARN] non-standard-rev-format — that was the false-confidence gap
    assert_not_contains \
        "rev-n-descending-no-version: no non-standard-rev-format WARN" \
        "$DIR_OUT" "non-standard-rev-format"
    # Must NOT emit [FAIL] — direction is correct
    assert_not_contains \
        "rev-n-descending-no-version: no [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    # Summary: UNVERIFIED=1 (one no-version-field file)
    assert_contains \
        "rev-n-descending-no-version: summary shows UNVERIFIED=1" \
        "$DIR_OUT" "UNVERIFIED=1"
    # Overall RESULT: PASS (UNVERIFIED is non-blocking)
    assert_result_pass \
        "rev-n-descending-no-version: RESULT: PASS (UNVERIFIED non-blocking)" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 13 — rev-N format, ASCENDING order (wrong direction) → FAIL
#
# A non-BC ADR with rev-N entries in ASCENDING order (rev-1 first = oldest first)
# must emit [FAIL] with rev-format-not-descending(ascending).  Non-BC files use
# the DESCENDING convention; ascending order is a direction violation.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_rev_n_ascending_fail() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-REV-N-FAIL.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-rev-n-ascending-fail
title: "Test ADR rev-N ascending (wrong direction for non-BC)"
status: accepted
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
changelog:
  - "rev-1 (ADV-P1D-PASS-01/2026-07-01): oldest entry — wrong: must be newest first"
  - "rev-2 (ADV-P1D-PASS-02/2026-07-02): second entry"
  - "rev-3 (FIX-BURST-003/2026-07-03): newest entry — wrong position for non-BC"
---

# ADR-TEST: rev-N Ascending (wrong)

Content.
MDEOF
}

assert_scenario_rev_n_ascending_fail() {
    # Must emit [FAIL] — ascending rev-N order violates Rule 5 (DESCENDING)
    assert_contains \
        "rev-n-ascending-fail: [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    assert_contains \
        "rev-n-ascending-fail: rev-format-not-descending(ascending) defect" \
        "$DIR_OUT" "rev-format-not-descending(ascending)"
    assert_contains \
        "rev-n-ascending-fail: defect lists rev sequence" \
        "$DIR_OUT" "rev-1,rev-2,rev-3"
    # Must NOT emit [WARN] non-standard-rev-format — it was replaced by real checking
    assert_not_contains \
        "rev-n-ascending-fail: no non-standard-rev-format WARN" \
        "$DIR_OUT" "non-standard-rev-format"
    # Overall RESULT: FAIL
    assert_result_fail \
        "rev-n-ascending-fail: RESULT: FAIL" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 14 — rev-N format, correctly DESCENDING, WITH version: present → PASS
#
# A non-BC ADR with rev-N entries in correct DESCENDING order and a version:
# field present must emit [PASS].  This exercises the positive path where both
# direction (Rule 5) and the governance check (version: present) are satisfied.
# VERSION-MATCH for rev-N is accepted when version: is present; the requirement
# is satisfied simply by its existence (no semver-match convention for rev-N).
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_rev_n_descending_with_version() {
    local d="$1"
    cat > "$d/specs/architecture/decisions/ADR-TEST-REV-N-VERSIONED.md" <<'MDEOF'
---
document_type: adr
level: L3
adr_id: "TEST"
slug: test-rev-n-descending-versioned
title: "Test ADR rev-N correctly descending with version: field"
status: accepted
version: "rev-5"
producer: architect
timestamp: 2026-07-01T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
changelog:
  - "rev-5 (FIX-BURST-500/2026-07-05): fifth amendment"
  - "rev-4 (FIX-BURST-400/2026-07-04): fourth amendment"
  - "rev-3 (FIX-BURST-300/2026-07-03): third amendment"
  - "rev-2 (FIX-BURST-200/2026-07-02): second amendment"
  - "rev-1 (FIX-BURST-100/2026-07-01): initial amendment"
---

# ADR-TEST: rev-N Descending with version: Field

Content.
MDEOF
}

assert_scenario_rev_n_descending_with_version() {
    # Direction is verified (descending) and version: field is present — must PASS
    assert_contains \
        "rev-n-descending-with-version: [PASS] emitted" \
        "$DIR_OUT" "[PASS] specs/architecture/decisions/ADR-TEST-REV-N-VERSIONED.md"
    # Must NOT emit [FAIL], [UNVERIFIED], or non-standard-rev-format WARN
    assert_not_contains \
        "rev-n-descending-with-version: no [FAIL] emitted" \
        "$DIR_OUT" "[FAIL]"
    assert_not_contains \
        "rev-n-descending-with-version: no [UNVERIFIED] emitted" \
        "$DIR_OUT" "[UNVERIFIED]"
    assert_not_contains \
        "rev-n-descending-with-version: no non-standard-rev-format WARN" \
        "$DIR_OUT" "non-standard-rev-format"
    # Summary: PASS=1, WARN=0, FAIL=0, UNVERIFIED=0
    assert_contains \
        "rev-n-descending-with-version: summary PASS=1" \
        "$DIR_OUT" "PASS=1"
    assert_contains \
        "rev-n-descending-with-version: summary UNVERIFIED=0" \
        "$DIR_OUT" "UNVERIFIED=0"
    assert_result_pass \
        "rev-n-descending-with-version: RESULT: PASS" \
        "$DIR_OUT"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 15 — BC + Form-B + no Form-A → BC_UNVERIFIED (blocking)
#
# A BC file that has a Form-B body `## Changelog` table (direction valid) but
# NO frontmatter `changelog:` key (Form-A) must emit BC_UNVERIFIED and cause
# RESULT: FAIL. BC files require Form-A for machine-readable version provenance.
# This is the exact false-confidence gap identified in F-ORCH-174-04.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_bc_form_b_only_no_form_a() {
    local d="$1"
    # BC file: has Form-B body changelog (valid, descending) but NO Form-A
    cat > "$d/specs/behavioral-contracts/ss-00/BC-TEST-FORM-B-ONLY.md" <<'MDEOF'
---
title: Test BC Form-B only (no Form-A) — must be BC_UNVERIFIED
document_type: behavioral-contract
version: "1.3"
status: active
---
## Overview

Some behavioral contract content.

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 1.3 | 2026-07-27 | third revision |
| 1.2 | 2026-07-25 | second revision |
| 1.1 | 2026-07-20 | initial |
MDEOF
}

assert_scenario_bc_form_b_only_no_form_a() {
    # Must emit [BC_UNVERIFIED] — BC without Form-A is a version-provenance gap
    assert_contains \
        "bc-form-b-only: [BC_UNVERIFIED] emitted" \
        "$DIR_OUT" "[BC_UNVERIFIED]"
    assert_contains \
        "bc-form-b-only: no-form-a-changelog-key reason present" \
        "$DIR_OUT" "no-form-a-changelog-key"
    # Must NOT emit [PASS] for this file — that was the vacuous-pass defect
    assert_not_contains \
        "bc-form-b-only: must not emit [PASS] for this BC" \
        "$DIR_OUT" "[PASS] specs/behavioral-contracts/ss-00/BC-TEST-FORM-B-ONLY.md"
    # BC_UNVERIFIED is blocking — RESULT must be FAIL
    assert_result_fail \
        "bc-form-b-only: RESULT: FAIL (BC_UNVERIFIED is blocking)" \
        "$DIR_OUT"
    # Summary must show BC_UNVERIFIED=1
    assert_contains \
        "bc-form-b-only: summary shows BC_UNVERIFIED=1" \
        "$DIR_OUT" "BC_UNVERIFIED=1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 16 — BC v1.0 + no Form-A + no Form-B → BC_UNVERIFIED (blocking)
#
# A BC file at version 1.0 with no changelog of either form must emit
# BC_UNVERIFIED and cause RESULT: FAIL. The "trivially valid" v1.0 exception
# does not apply to BC files — every BC needs Form-A for version provenance.
# This is the second vacuous-pass path closed by F-ORCH-174-04.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_bc_v1_no_changelog() {
    local d="$1"
    # BC file at v1.0, no Form-A and no Form-B
    cat > "$d/specs/behavioral-contracts/ss-00/BC-TEST-V1-NO-CL.md" <<'MDEOF'
---
title: Test BC version 1.0 no changelog — must be BC_UNVERIFIED
document_type: behavioral-contract
version: "1.0"
status: active
---
## Overview

Initial authoring with no changelog entries.
MDEOF
}

assert_scenario_bc_v1_no_changelog() {
    # Must emit [BC_UNVERIFIED] — v1.0 BC without Form-A is still a provenance gap
    assert_contains \
        "bc-v1-no-changelog: [BC_UNVERIFIED] emitted" \
        "$DIR_OUT" "[BC_UNVERIFIED]"
    assert_contains \
        "bc-v1-no-changelog: no-form-a-changelog-key reason present" \
        "$DIR_OUT" "no-form-a-changelog-key"
    # Must NOT emit [PASS] — that was the vacuous-pass defect being fixed
    assert_not_contains \
        "bc-v1-no-changelog: must not emit [PASS] for this BC" \
        "$DIR_OUT" "[PASS] specs/behavioral-contracts/ss-00/BC-TEST-V1-NO-CL.md"
    # BC_UNVERIFIED is blocking — RESULT must be FAIL
    assert_result_fail \
        "bc-v1-no-changelog: RESULT: FAIL (BC_UNVERIFIED is blocking)" \
        "$DIR_OUT"
    # Summary must show BC_UNVERIFIED=1
    assert_contains \
        "bc-v1-no-changelog: summary shows BC_UNVERIFIED=1" \
        "$DIR_OUT" "BC_UNVERIFIED=1"
}

# ── Run all scenarios ─────────────────────────────────────────────────────────

echo "TAP version 13"
echo "# F-B276-02 validator false-confidence — catch-proof synthetic tests"
echo ""

run_scenario "no_version_field_unverified"
run_scenario "form_b_only_nonbc_correct_descending"
run_scenario "form_b_only_nonbc_ascending_fail"
run_scenario "form_b_only_nonbc_version_mismatch_fail"
run_scenario "nonbc_form_a_correct_descending"
run_scenario "nonbc_form_a_ascending_fail"
run_scenario "bc_form_a_correct_ascending"
run_scenario "bc_form_a_descending_fail"
run_scenario "summary_unverified_counter"
run_scenario "form_b_equal_consecutive_fail"
run_scenario "form_b_numeric_version_compare"
run_scenario "rev_n_descending_no_version"
run_scenario "rev_n_ascending_fail"
run_scenario "rev_n_descending_with_version"
run_scenario "bc_form_b_only_no_form_a"
run_scenario "bc_v1_no_changelog"

echo ""
echo "# Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo "# RESULT: FAIL"
    exit 1
else
    echo "# RESULT: PASS"
    exit 0
fi
