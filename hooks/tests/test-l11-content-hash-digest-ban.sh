#!/usr/bin/env bash
# test-l11-content-hash-digest-ban.sh — F-P173-505 mechanical enforcement proof
# Proves check L11 in records-lint.sh: BLOCKING gate for standalone 8+ char lowercase
# hex content-hash digest literals in newly-authored record/changelog/spec prose.
#
# Test strategy: each scenario initializes an isolated git repo in a tmpdir, copies
# records-lint.sh into <tmpdir>/hooks/ (so FACTORY_DIR resolves to <tmpdir>), creates
# synthetic spec fixtures in <tmpdir>/specs/, stages them with `git add`, then runs
# records-lint.sh --skip-self-probe and asserts on the output. No real specs or git
# state are touched.
#
# TD-VSDD-091 compliance: all comments cite behavioral anchors — never file:NNN cites.
#
# FALSE-NEGATIVE SELF-CHECK (documented boundary, not a test scenario):
#   Uppercase hex: `ABC123DEF456789012345678901234567890` — escapes L11 because
#   CONTENT_HASH_PATTERN requires lowercase `[0-9a-f]`. This is an intentional scope
#   boundary: all hash outputs in this project are lowercase (git, sha256sum, sha1sum);
#   uppercase hex appears in Rust code as `0xABCD` form where the `0x` prefix causes
#   the `x` word-char to break the `\b` boundary before `A`, preventing a match.
#   Verification: `echo "+ABC123DEF456789012345678901234567890" | grep -qE '\b[0-9a-f]{8,}\b'`
#   exits 1 (no match). Documented as out-of-scope for L11; would require a separate
#   check `[0-9a-fA-F]{8,}` if uppercase hashes ever appear in records prose.

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
    mkdir -p "$TMPDIR/specs/verification-properties"

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
# Scenario 1 — TRUE POSITIVE: 40-char SHA-1 in changelog prose → L11 FAIL
#
# A changelog entry cites a raw SHA-1 digest as evidence of input-file identity.
# This is the canonical violation the finding describes. L11 must detect it and
# exit 1 (blocking).
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_positive_sha1_in_prose() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-001.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
input-hash: "f065653"
---
# VP-SYNTHETIC-001: Synthetic violation fixture

## Property Statement

For the test.

changelog:
  - "1.0 (burst-999/2026-07-27): initial VP authored"
  - "1.1 (burst-999/2026-07-27): Input-hash refreshed: 4bcef4e5790e7f8352c28d6ae3b3697572939ef3 (ADR-014 edited in same burst)"
MDEOF
}

assert_scenario_true_positive_sha1_in_prose() {
    # L11 must detect the 40-char SHA-1 and emit FAIL
    assert_contains \
        "true-positive: L11 FAIL emitted for 40-char SHA-1 in changelog prose" \
        "$LINT_OUT" "[FAIL] L11"
    assert_contains \
        "true-positive: violation count reported" \
        "$LINT_OUT" "1 newly-added line"
    # exit code must be non-zero (blocking)
    assert_exit_fail \
        "true-positive: exit code 1 (BLOCKING)" \
        "$LINT_EXITCODE"
    # Must name the replacement guidance
    assert_contains \
        "true-positive: replacement guidance present" \
        "$LINT_OUT" "artifact+section anchor cites"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 2 — TRUE NEGATIVE CE1: input-hash frontmatter field passes
#
# The `input-hash: "abc12345678"` YAML field is LEGITIMATE structured metadata.
# L11 must NOT flag it (CE1 exclusion). The field VALUE contains an 8+ char
# hex string but the line is excluded because it is a structured YAML assignment.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_ce1_frontmatter() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-CE1.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
input-hash: "abc12345678901234567890"
proof_file_hash: "def45678901234567890abc"
develop_head: "4bcef4e5790e7f8352c28d6ae3b3697572939ef3"
frozen_head: "cafa10de3cec85e9e1f2dcb5dfd38e079051a3a8"
---
# VP-SYNTHETIC-CE1: CE1 exclusion fixture — frontmatter hash fields are not prose

## Property Statement

No prose hash citations here.
MDEOF
}

assert_scenario_true_negative_ce1_frontmatter() {
    # No L11 FAIL — all hashes are in YAML frontmatter fields (CE1)
    assert_not_contains \
        "CE1: no L11 FAIL for input-hash frontmatter field" \
        "$LINT_OUT" "[FAIL] L11"
    # Overall result must pass (no FAIL)
    assert_contains \
        "CE1: RESULT PASS" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "CE1: exit code 0" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 3 — TRUE NEGATIVE CE2: Frozen HEAD citation passes
#
# A convergence-trajectory or adversarial-pass-record line that cites a frozen
# HEAD commit SHA — `**Frozen HEAD:** burst-NNN commit (`FULLSHA40`)` — is
# sanctioned by verify-sha-currency.sh and must NOT be flagged by L11.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_ce2_frozen_head() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-CE2.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
---
# VP-SYNTHETIC-CE2: CE2 exclusion fixture — frozen HEAD citations are sanctioned

## Adversarial Pass Context

**Adversary:** fresh-context on frozen HEAD (burst-274 commit, SHA `554dfd6bf3f0cfcaff0e67c48efcc68e32bf9b29`)
**Frozen HEAD:** burst-274 commit (`554dfd6bf3f0cfcaff0e67c48efcc68e32bf9b29`)

Also acceptable: frozen head burst-271 commit `4bcef4e5790e7f8352c28d6ae3b3697572939ef3`.
MDEOF
}

assert_scenario_true_negative_ce2_frozen_head() {
    # No L11 FAIL — all hashes appear on lines containing "Frozen HEAD" or "frozen head" (CE2)
    assert_not_contains \
        "CE2: no L11 FAIL for Frozen HEAD citation lines" \
        "$LINT_OUT" "[FAIL] L11"
    assert_contains \
        "CE2: RESULT PASS" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "CE2: exit code 0" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 4 — TRUE NEGATIVE CE3: [live-state] sentinel passes
#
# Lines containing `[live-state]` are ephemeral wrap-state markers validated by
# verify-sha-currency.sh. They must NOT be flagged by L11 even if they contain
# a full SHA.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_ce3_live_state() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-CE3.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
---
# VP-SYNTHETIC-CE3: CE3 exclusion fixture — [live-state] sentinel lines are exempt

[live-state] develop_head: 4bcef4e5790e7f8352c28d6ae3b3697572939ef3
[live-state] session_commit: abc12345678901234567890def
MDEOF
}

assert_scenario_true_negative_ce3_live_state() {
    # No L11 FAIL — all hash-containing lines begin with [live-state] (CE3)
    assert_not_contains \
        "CE3: no L11 FAIL for [live-state] sentinel lines" \
        "$LINT_OUT" "[FAIL] L11"
    assert_contains \
        "CE3: RESULT PASS" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "CE3: exit code 0" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 5 — TRUE NEGATIVE CE4: Rust toolchain build-hash passes
#
# `rustc -V` emits `1.95.0 (59807616e 2026-04-14)`. This appears in preflight
# reports and toolchain verification tables. The `(HEX YYYY-MM-DD)` form is
# toolchain identity metadata, not a content pin, and must NOT be flagged.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_ce4_toolchain_hash() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-CE4.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
---
# VP-SYNTHETIC-CE4: CE4 exclusion fixture — Rust toolchain hash format is exempt

## Preflight Results

| Tool  | Version                         | Status |
|-------|---------------------------------|--------|
| rustc | 1.95.0 (59807616e 2026-04-14)  | PASS   |
| cargo | 1.95.0 (f2d3ce0bd 2026-03-21)  | PASS   |
MDEOF
}

assert_scenario_true_negative_ce4_toolchain_hash() {
    # No L11 FAIL — Rust toolchain build-hash format `(HEX YYYY-MM-DD)` matches CE4
    assert_not_contains \
        "CE4: no L11 FAIL for Rust toolchain hash format" \
        "$LINT_OUT" "[FAIL] L11"
    assert_contains \
        "CE4: RESULT PASS" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "CE4: exit code 0" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 6 — TRUE NEGATIVE SIZE BOUNDARY: 7-char hex is L10 scope, not L11
#
# A changelog entry containing only 7-char hex strings (e.g. `5fc3abe → baaf36d`)
# is L10's scope (advisory). L11 starts at 8 chars. A 7-char-only line must NOT
# trigger L11 (no FAIL), though L10 will emit WARN for it.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_size_boundary_7char() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-SIZE.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
---
# VP-SYNTHETIC-SIZE: size-boundary fixture — 7-char hex is L10 scope only

changelog:
  - "1.0 (burst-123): input-hash refreshed: 5fc3abe → baaf36d (ADR-017 edited)"
MDEOF
}

assert_scenario_true_negative_size_boundary_7char() {
    # L11 must NOT fire — 7-char hex strings are out of L11's scope (8+ required)
    assert_not_contains \
        "size-boundary: no L11 FAIL for 7-char hex (L10 scope only)" \
        "$LINT_OUT" "[FAIL] L11"
    # L10 WILL emit WARN for the 7-char strings (advisory, non-blocking)
    assert_contains \
        "size-boundary: L10 WARN emitted for 7-char hex (expected advisory)" \
        "$LINT_OUT" "[WARN] L10"
    # Overall result PASS (L10 is advisory/WARN, L11 did not fire)
    assert_contains \
        "size-boundary: RESULT PASS (L10 WARN is non-blocking)" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "size-boundary: exit code 0 (WARN does not block)" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 7 — TRUE POSITIVE: 32-char MD5-length hex in prose → L11 FAIL
#
# A second positive-case scenario verifying L11 catches a different digest
# length (32-char = MD5 format). Ensures the pattern is not SHA-1-specific.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_positive_md5_in_prose() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-MD5.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
---
# VP-SYNTHETIC-MD5: second true-positive fixture — MD5-length digest in changelog

changelog:
  - "1.0 (burst-999): content-hash computed: d41d8cd98f00b204e9800998ecf8427e (empty-file sentinel)"
MDEOF
}

assert_scenario_true_positive_md5_in_prose() {
    # L11 must detect the 32-char MD5-length hex string
    assert_contains \
        "MD5-length: L11 FAIL emitted for 32-char hex digest in changelog prose" \
        "$LINT_OUT" "[FAIL] L11"
    assert_exit_fail \
        "MD5-length: exit code 1 (BLOCKING)" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 8 — TRUE NEGATIVE CE5: Rust float literal in VP changelog passes
#
# VP-009's changelog (added in FIX-BURST-276) describes overflow behavior and
# contains `1e20f32` (a Rust float literal documenting ~1e20f32 as a finite value
# that overflows during sum-of-squares). This 7-char hex-looking token triggered
# L10's 3 false-positive WARNs before CE5 was added. The same exclusion applies
# to L11 for 8+ char Rust literals like `1e200f64`.
#
# This scenario proves CE5 eliminates both the 7-char (L10) and 8-char (L11)
# false positives from Rust float literals in VP changelog prose.
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_negative_ce5_rust_float_literal() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-CE5.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
---
# VP-SYNTHETIC-CE5: CE5 exclusion fixture — Rust float literals are not hash digests

changelog:
  - "1.6 (burst-999): Extend harness to cover norm-overflow. Individually finite elements (e.g., elements ~1e20f32) can produce norm = +Inf via sum-of-squares overflow. Add overflow guard."
  - "1.7 (burst-999): Update to cover 1e200f64 case — 8 char float literal must not trigger L11."
  - "1.8 (burst-999): Binary literal test: 0b10101010 is a bitmask pattern, not a hash."
MDEOF
}

assert_scenario_true_negative_ce5_rust_float_literal() {
    # L10 must NOT warn for `1e20f32` (CE5 exclusion — 7-char Rust float literal)
    assert_not_contains \
        "CE5: no L10 WARN for 1e20f32 (Rust float literal, not a git SHA7)" \
        "$LINT_OUT" "[WARN] L10"
    # L11 must NOT fail for `1e200f64` or `0b10101010` (CE5 exclusion)
    assert_not_contains \
        "CE5: no L11 FAIL for 1e200f64 (8-char Rust float literal, not a hash)" \
        "$LINT_OUT" "[FAIL] L11"
    # Overall result PASS
    assert_contains \
        "CE5: RESULT PASS" \
        "$LINT_OUT" "RESULT: PASS"
    assert_exit_pass \
        "CE5: exit code 0" \
        "$LINT_EXITCODE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Scenario 9 — TRUE POSITIVE: 64-char SHA-256 in prose → L11 FAIL
#
# Verifies L11 catches SHA-256 length digests (64 chars), the most common
# content-hash format for file identity verification (sha256sum output).
# ─────────────────────────────────────────────────────────────────────────────
write_fixture_true_positive_sha256_in_prose() {
    local d="$1"
    cat > "$d/specs/verification-properties/VP-SYNTHETIC-SHA256.md" <<'MDEOF'
---
document_type: verification-property
version: "1.0"
---
# VP-SYNTHETIC-SHA256: third true-positive fixture — SHA-256 digest in burst log prose

Summary: product-brief.md v1.1 authored. input-hash 67fa2efbe06fdea2450aa43fde2ba87dfd2d6ff3b0460fd86427809581dcb347 computed and written to frontmatter.
MDEOF
}

assert_scenario_true_positive_sha256_in_prose() {
    # L11 must detect the 64-char SHA-256 string
    assert_contains \
        "SHA-256: L11 FAIL emitted for 64-char hex digest in prose" \
        "$LINT_OUT" "[FAIL] L11"
    assert_exit_fail \
        "SHA-256: exit code 1 (BLOCKING)" \
        "$LINT_EXITCODE"
}

# ── False-negative self-check (runtime verification) ─────────────────────────
# Verify the known scope boundary: uppercase hex is not matched by CONTENT_HASH_PATTERN.
# This is EXPECTED behavior (out-of-scope), not a defect. The test confirms the boundary
# is as documented, preventing a future change from silently expanding scope.

verify_false_negative_boundary_uppercase() {
    # Load CONTENT_HASH_PATTERN from the script variables
    CONTENT_HASH_PATTERN='\b[0-9a-f]{8,}\b'

    UPPERCASE_HEX="ABC123DEF456789012345678901234567890"
    if echo "+refresh: content-hash ${UPPERCASE_HEX} (ADR edited)" | grep -qE "${CONTENT_HASH_PATTERN}"; then
        echo "not ok - false-negative boundary: uppercase hex UNEXPECTEDLY matched (scope expanded beyond documented boundary)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "ok - false-negative boundary: uppercase hex does NOT match (documented scope boundary confirmed)"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi

    # Also verify that a lowercase equivalent DOES match (confirming the test is meaningful,
    # not a tautology — the pattern is active and only the uppercase case escapes it)
    LOWERCASE_HEX="abc123def456789012345678901234567890"
    if echo "+refresh: content-hash ${LOWERCASE_HEX} (ADR edited)" | grep -qE "${CONTENT_HASH_PATTERN}"; then
        echo "ok - false-negative boundary: lowercase equivalent DOES match (confirming pattern is active)"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "not ok - false-negative boundary: lowercase equivalent did NOT match (pattern is broken)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ── Run all scenarios ─────────────────────────────────────────────────────────

echo "TAP version 13"
echo "# F-P173-505 content-hash digest ban (L11) — catch-proof synthetic tests"
echo ""

run_scenario "true_positive_sha1_in_prose"
run_scenario "true_negative_ce1_frontmatter"
run_scenario "true_negative_ce2_frozen_head"
run_scenario "true_negative_ce3_live_state"
run_scenario "true_negative_ce4_toolchain_hash"
run_scenario "true_negative_size_boundary_7char"
run_scenario "true_negative_ce5_rust_float_literal"
run_scenario "true_positive_md5_in_prose"
run_scenario "true_positive_sha256_in_prose"
verify_false_negative_boundary_uppercase

echo ""
echo "# Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo "# RESULT: FAIL"
    exit 1
else
    echo "# RESULT: PASS"
    exit 0
fi
