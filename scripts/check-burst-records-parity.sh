#!/usr/bin/env bash
# check-burst-records-parity.sh
#
# Verifies that the newest fix-burst-N section in CHANGELOG.md has a
# matching re-verification section in evidence-report.md, and that the
# finding-ID sets and tally counts agree between the two documents.
#
# Normal usage (called by lefthook pre-push):
#   bash scripts/check-burst-records-parity.sh
#
# Self-probe usage (called by lefthook burst-parity-self-probe):
#   bash scripts/check-burst-records-parity.sh --self-probe
# or:
#   SELF_PROBE=1 bash scripts/check-burst-records-parity.sh
set -euo pipefail

# Severity class alternation for grep -E patterns.
# Must enumerate each value — awk ERE is used for patterns that include $SEV,
# so bash expands the variable before awk sees it.
SEV='(CRIT|HIGH|MED|LOW|OBS|PROCESS-GAP)'

# ── do_parity_check <changelog_file> <evidence_report_file> ─────────────────
#
# Core check logic.  Uses `return` (not `exit`) so the self-probe can call it
# and inspect the exit code without aborting the whole script.
#
# Exit codes: 0 = PASS, 1 = FAIL.
do_parity_check() {
    local cl_file="$1"
    local er_file="$2"

    # ── Identify newest fix-burst number (numeric max, order-independent) ───
    local newest_burst
    newest_burst=$(grep -oE '^## fix-burst-[0-9]+' "$cl_file" 2>/dev/null \
        | grep -oE '[0-9]+' | sort -rn | head -1 || true)
    if [ -z "$newest_burst" ]; then
        # Case-insensitive search: if any 'fix-burst' token exists but the canonical
        # '^## fix-burst-N' pattern matched zero headings, that is heading-format drift.
        # Only skip entirely when no fix-burst token is present at all (e.g., brand-new
        # story branch with no adversary passes yet).
        if grep -qi 'fix-burst' "$cl_file" 2>/dev/null; then
            echo "[BURST-PARITY FAIL] heading-format drift detected: 'fix-burst' tokens present but no canonical '## fix-burst-N' headings matched"
            return 1
        fi
        echo "[BURST-PARITY SKIP] No fix-burst content in CHANGELOG — skipping."
        return 0
    fi

    # ── Re-verification section must exist before any extraction ────────────
    if ! grep -q "^## fix-burst-${newest_burst} re-verification" "$er_file"; then
        echo "[BURST-PARITY FAIL] CHANGELOG has '## fix-burst-${newest_burst}' but evidence-report is missing '## fix-burst-${newest_burst} re-verification'."
        return 1
    fi

    # ── Evidence-report newest-burst must match CHANGELOG newest-burst ──────
    # Prevents silently certifying an older burst when ER has gained a newer section.
    local er_newest_burst
    er_newest_burst=$(grep -oE '^## fix-burst-[0-9]+ re-verification' "$er_file" 2>/dev/null \
        | grep -oE '[0-9]+' | sort -rn | head -1 || true)
    if [ -n "$er_newest_burst" ] && [ "$er_newest_burst" != "$newest_burst" ]; then
        echo "[BURST-PARITY FAIL] evidence-report newest burst (fix-burst-${er_newest_burst}) differs from CHANGELOG newest burst (fix-burst-${newest_burst})"
        return 1
    fi

    # ── Extract CHANGELOG section for newest burst ───────────────────────────
    # Heading format: "## fix-burst-52 (pass-50 findings)" or "## fix-burst-52"
    # Terminated by any subsequent "## " heading or EOF.
    # Pattern "( |$)" matches heading-number followed by space or end-of-line,
    # preventing false matches on "## fix-burst-520" when newest_burst=52.
    local cl_section
    cl_section=$(awk "
        /^## fix-burst-${newest_burst}( |\$)/ { found=1; next }
        found && /^## /                        { found=0 }
        found                                  { print }
    " "$cl_file")

    # Finding headings: "### HIGH-001:", "### PROCESS-GAP-001:", etc.
    # (NOT "### F-P51-HIGH-001:" — CHANGELOG uses bare severity-number form.)
    local cl_ids
    cl_ids=$(printf '%s\n' "$cl_section" \
        | grep -oE "^### ${SEV}-[0-9]+" \
        | grep -oE "${SEV}-[0-9]+" \
        | sort || true)

    if [ -z "$cl_ids" ]; then
        echo "[BURST-PARITY FAIL] CHANGELOG section extraction returned empty for fix-burst-${newest_burst} — cannot certify parity"
        return 1
    fi

    # ── Extract evidence-report re-verification section ──────────────────────
    # Heading format: "## fix-burst-52 re-verification"
    # Finding rows: "| F-P50-HIGH-001 | HIGH | ..."
    local er_section
    er_section=$(awk "
        /^## fix-burst-${newest_burst} re-verification/ { found=1; next }
        found && /^## /                                  { found=0 }
        found                                            { print }
    " "$er_file")

    # Strip the "F-P<N>-" prefix (e.g. "F-P50-") to normalize to "HIGH-001"
    # form matching CHANGELOG IDs.  Works for PROCESS-GAP: "F-P48-PROCESS-GAP-001"
    # becomes "PROCESS-GAP-001" after removing the first "F-P[0-9]*-" match.
    local er_ids
    er_ids=$(printf '%s\n' "$er_section" \
        | grep -oE "\| F-P[0-9]+-${SEV}-[0-9]+ \|" \
        | grep -oE "F-P[0-9]+-${SEV}-[0-9]+" \
        | sed 's/F-P[0-9]*-//' \
        | sort || true)

    if [ -z "$er_ids" ]; then
        echo "[BURST-PARITY FAIL] evidence-report re-verification section extraction returned empty for fix-burst-${newest_burst} — cannot certify parity"
        return 1
    fi

    # ── Compare ID sets ───────────────────────────────────────────────────────
    if [ "$cl_ids" != "$er_ids" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: finding ID mismatch between CHANGELOG and evidence-report"
        echo "  In CHANGELOG only:      $(comm -23 <(printf '%s\n' "$cl_ids") <(printf '%s\n' "$er_ids") | tr '\n' ' ')"
        echo "  In evidence-report only: $(comm -13 <(printf '%s\n' "$cl_ids") <(printf '%s\n' "$er_ids") | tr '\n' ' ')"
        return 1
    fi

    # ── Compare tally counts (soft — fails only when both lines present and diverge) ──
    #
    # CHANGELOG tally line format:
    #   **Pass-50 finding tally: 3 HIGH + 5 MED + 3 LOW + 2 OBS**
    #
    # Evidence-report tally line format:
    #   **Adversary pass 50 result:** CLEAN(strict)=no, ... — 3 HIGH + 5 MED + 3 LOW + 2 OBS.
    #
    # The ER format has "result:**" (closing ** immediately after the colon) so
    # [^*]+ would never match.  Correct pattern: \*\*Adversary pass N result:\*\*.*
    local cl_tally
    cl_tally=$(printf '%s\n' "$cl_section" \
        | grep -oE '\*\*Pass-[0-9]+ finding tally:[^*]+\*\*' | head -1 || true)

    local er_tally
    er_tally=$(printf '%s\n' "$er_section" \
        | grep -oE '\*\*Adversary pass [0-9]+ result:\*\*.*' | head -1 || true)

    # ── Pass-number agreement between CHANGELOG and evidence-report ─────────────
    # Both cl_pass and er_pass are always non-empty when cl_tally/er_tally are
    # non-empty (the tally regex requires Pass-<N>). Format drift that makes the
    # pass token absent will also make the tally line un-extractable, caught by
    # the empty-tally fail-closed guard. This guard fires only when both
    # extractions succeed and they disagree.
    local cl_pass er_pass
    cl_pass=$(printf '%s\n' "$cl_tally" \
        | grep -oE 'Pass-[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
    er_pass=$(printf '%s\n' "$er_tally" \
        | grep -oE 'pass [0-9]+' | grep -oE '[0-9]+' | head -1 || true)

    if [ -n "$cl_pass" ] && [ -n "$er_pass" ] && [ "$cl_pass" != "$er_pass" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: CHANGELOG cites Pass-${cl_pass} but evidence-report cites Adversary pass ${er_pass}"
        return 1
    fi

    local cl_counts er_counts
    cl_counts=$(printf '%s\n' "$cl_tally" \
        | grep -oE "[0-9]+ ${SEV}" | sort || true)
    er_counts=$(printf '%s\n' "$er_tally" \
        | grep -oE "[0-9]+ ${SEV}" | sort || true)

    # ── Fail-closed: tally lines must be extractable to certify the tally ───────
    # If either raw tally line is absent (format drift), we cannot compare — fail.
    if [ -z "$cl_tally" ] || [ -z "$er_tally" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: tally extraction empty — cannot certify tally"
        return 1
    fi

    if [ -n "$cl_counts" ] && [ -n "$er_counts" ] && [ "$cl_counts" != "$er_counts" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: tally mismatch between CHANGELOG and evidence-report"
        echo "  CHANGELOG tally:         $cl_tally"
        echo "  Evidence-report tally:   $er_tally"
        return 1
    fi

    local id_count
    id_count=$(printf '%s\n' "$cl_ids" | wc -l | tr -d ' ')

    # ── Tally sum ↔ ID count reconciliation ─────────────────────────────────────
    # Sum the leading integers from cl_counts and compare to the actual finding
    # ID count.  Catches cases where the tally text is arithmetically inconsistent
    # with the number of heading-delimited IDs in the CHANGELOG section (e.g.,
    # "1 HIGH + 2 MED" declared but only 2 finding headings present → sum 3 ≠ 2).
    local tally_sum=0 n
    while IFS= read -r token; do
        n=$(printf '%s' "$token" | grep -oE '^[0-9]+' || echo 0)
        tally_sum=$((tally_sum + n))
    done <<< "$cl_counts"

    if [ "$tally_sum" -ne "$id_count" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: declared tally sums to ${tally_sum} but ${id_count} finding IDs enumerated"
        return 1
    fi

    # ── Runtime-computed tally label ─────────────────────────────────────────────
    # Emit the actual compared tally (e.g. "1H+1M") rather than an unconditional
    # "tally verified".  Uses cl_counts (which equals er_counts at this point).
    local tally_label
    if [ -n "$cl_counts" ]; then
        tally_label=$(printf '%s\n' "$cl_counts" \
            | sed 's/ CRIT$/C/;s/ HIGH$/H/;s/ MED$/M/;s/ LOW$/L/;s/ OBS$/OBS/;s/ PROCESS-GAP$/PG/' \
            | paste -sd'+' - || echo "?")
    else
        tally_label="(no count tokens)"
    fi

    echo "[BURST-PARITY PASS] fix-burst-${newest_burst}: ${id_count} finding IDs matched; tally: ${tally_label}."
    return 0
}

# ── Self-probe ───────────────────────────────────────────────────────────────
#
# Probe 1 — ID-mismatch probe.
#   CHANGELOG: HIGH-001 + MED-001.  Evidence-report: HIGH-001 + LOW-001.
#   Diverges on ID set.  Asserts do_parity_check exits non-zero.
#
# Probe 2 — Tally-divergent probe.
#   CHANGELOG: HIGH-001 + MED-001.  Evidence-report: HIGH-001 + MED-001.
#   IDENTICAL ID sets, but CHANGELOG tally = 1 HIGH + 1 MED whereas ER
#   tally = 2 HIGH + 0 MED.  This is the only construction that exercises the
#   tally comparison path (probe 1 short-circuits at the ID check).
#   Asserts do_parity_check exits non-zero.
#
# Probe 3 — Tally-sum ≠ ID-count probe.
#   CHANGELOG: HIGH-001 + MED-001 (2 IDs), tally declares 1 HIGH + 2 MED (sum=3).
#   Evidence-report: HIGH-001 + MED-001, same tally — ID-set and tally-text match.
#   Tally-sum ↔ ID-count reconciliation must detect 3 ≠ 2.
#   Asserts do_parity_check exits non-zero.
#
# Probe 4 — Pass-number divergence probe.
#   CHANGELOG: HIGH-001, tally cites Pass-94.  Evidence-report: HIGH-001, result
#   cites Adversary pass 93.  IDENTICAL ID sets and tally counts, but pass numbers
#   diverge (94 ≠ 93).  Asserts do_parity_check exits non-zero.
run_self_probes() {
    local all_passed=0

    # ── Probe 1: ID-mismatch ──────────────────────────────────────────────────
    local tmpdir1
    tmpdir1="$(mktemp -d)"

    # Synthetic CHANGELOG: fix-burst-99 with HIGH-001 and MED-001.
    local fake_cl1="$tmpdir1/CHANGELOG.md"
    cat > "$fake_cl1" <<'PROBE_HEREDOC'
## fix-burst-99 (pass-97 findings)

**Pass-97 finding tally: 1 HIGH + 1 MED**

### HIGH-001: A high severity finding

Description of the high finding.

### MED-001: A medium severity finding

Description of the medium finding.
PROBE_HEREDOC

    # Synthetic evidence-report: fix-burst-99 re-verification with HIGH-001 and
    # LOW-001.  Deliberately divergent: CHANGELOG says MED-001, ER says LOW-001.
    local fake_er1="$tmpdir1/evidence-report.md"
    cat > "$fake_er1" <<'PROBE_HEREDOC'
## fix-burst-99 re-verification

**Adversary pass 97 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 1 LOW.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P97-HIGH-001 | HIGH | test class | test artifact |
| F-P97-LOW-001 | LOW | test class | test artifact |
PROBE_HEREDOC

    local probe1_exit=0
    do_parity_check "$fake_cl1" "$fake_er1" >/dev/null 2>&1 || probe1_exit=$?
    rm -rf "$tmpdir1"

    if [ "$probe1_exit" -ne 0 ]; then
        echo "[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch"
    else
        echo "[SELF-PROBE FAIL] probe-1 (ID-mismatch): divergent ID pair was not detected"
        all_passed=1
    fi

    # ── Probe 2: tally-divergent, ID-matching ─────────────────────────────────
    # This probe exercises the tally comparison path that probe 1 never reaches
    # (probe 1 short-circuits at the ID check).
    local tmpdir2
    tmpdir2="$(mktemp -d)"

    # Synthetic CHANGELOG: fix-burst-98 with HIGH-001 and MED-001.
    # Tally: 1 HIGH + 1 MED.
    local fake_cl2="$tmpdir2/CHANGELOG.md"
    cat > "$fake_cl2" <<'PROBE_HEREDOC'
## fix-burst-98 (pass-97 findings)

**Pass-97 finding tally: 1 HIGH + 1 MED**

### HIGH-001: A high severity finding

Description of the high finding.

### MED-001: A medium severity finding

Description of the medium finding.
PROBE_HEREDOC

    # Synthetic evidence-report: IDENTICAL finding IDs (HIGH-001 + MED-001),
    # but DIVERGENT tally: 2 HIGH + 0 MED.
    local fake_er2="$tmpdir2/evidence-report.md"
    cat > "$fake_er2" <<'PROBE_HEREDOC'
## fix-burst-98 re-verification

**Adversary pass 97 result:** CLEAN(strict)=no — 2 HIGH + 0 MED.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P97-HIGH-001 | HIGH | test class | test artifact |
| F-P97-MED-001 | MED | test class | test artifact |
PROBE_HEREDOC

    local probe2_exit=0
    do_parity_check "$fake_cl2" "$fake_er2" >/dev/null 2>&1 || probe2_exit=$?
    rm -rf "$tmpdir2"

    if [ "$probe2_exit" -ne 0 ]; then
        echo "[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch"
    else
        echo "[SELF-PROBE FAIL] probe-2 (tally-divergent): tally mismatch was not detected (tally comparison path untested)"
        all_passed=1
    fi

    # ── Probe 3: tally-sum ≠ id-count ────────────────────────────────────────────
    # CHANGELOG declares "1 HIGH + 2 MED" (sum=3) but contains only 2 finding
    # headings (HIGH-001 + MED-001).  Evidence-report has matching IDs and the
    # same tally, so ID-set and tally-text comparisons both pass.  The new
    # tally-sum ↔ id-count reconciliation must catch the discrepancy (3 ≠ 2).
    local tmpdir3
    tmpdir3="$(mktemp -d)"

    local fake_cl3="$tmpdir3/CHANGELOG.md"
    cat > "$fake_cl3" <<'PROBE_HEREDOC'
## fix-burst-97 (pass-96 findings)

**Pass-96 finding tally: 1 HIGH + 2 MED**

### HIGH-001: A high severity finding

Description of the high finding.

### MED-001: A medium severity finding

Description of the medium finding.
PROBE_HEREDOC

    local fake_er3="$tmpdir3/evidence-report.md"
    cat > "$fake_er3" <<'PROBE_HEREDOC'
## fix-burst-97 re-verification

**Adversary pass 96 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 2 MED.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P96-HIGH-001 | HIGH | test class | test artifact |
| F-P96-MED-001 | MED | test class | test artifact |
PROBE_HEREDOC

    local probe3_exit=0
    do_parity_check "$fake_cl3" "$fake_er3" >/dev/null 2>&1 || probe3_exit=$?
    rm -rf "$tmpdir3"

    if [ "$probe3_exit" -ne 0 ]; then
        echo "[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-3 (tally-sum≠id-count): tally-sum/id-count mismatch was not detected"
        all_passed=1
    fi

    # ── Probe 4: pass-number divergent ────────────────────────────────────────
    # Exercises the pass-number agreement guard: identical IDs and tally counts,
    # but CHANGELOG cites Pass-94 while evidence-report cites Adversary pass 93.
    local tmpdir4
    tmpdir4="$(mktemp -d)"

    local fake_cl4="$tmpdir4/CHANGELOG.md"
    cat > "$fake_cl4" <<'PROBE_HEREDOC'
## fix-burst-95 (pass-94 findings)

**Pass-94 finding tally: 1 HIGH**

### HIGH-001: A high severity finding

Description of the high finding.
PROBE_HEREDOC

    local fake_er4="$tmpdir4/evidence-report.md"
    cat > "$fake_er4" <<'PROBE_HEREDOC'
## fix-burst-95 re-verification

**Adversary pass 93 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P93-HIGH-001 | HIGH | test class | test artifact |
PROBE_HEREDOC

    local probe4_exit=0
    do_parity_check "$fake_cl4" "$fake_er4" >/dev/null 2>&1 || probe4_exit=$?
    rm -rf "$tmpdir4"

    if [ "$probe4_exit" -ne 0 ]; then
        echo "[SELF-PROBE PASS] probe-4 (pass-number-divergent): divergent pass numbers (CHANGELOG Pass-94 vs evidence-report pass 93) correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-4 (pass-number-divergent): pass-number mismatch was not detected (pass-number guard untested)"
        all_passed=1
    fi

    if [ "$all_passed" -ne 0 ]; then
        exit 1
    fi
}

# ── Entry point ───────────────────────────────────────────────────────────────
if [ "${1:-}" = "--self-probe" ] || [ "${SELF_PROBE:-0}" = "1" ]; then
    run_self_probes
    exit 0
fi

# Normal check: derive story ID from current feature branch name.
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
STORY_ID=$(printf '%s\n' "$BRANCH" | grep -oE 'S-[0-9]+\.[0-9]+' | head -1 || true)

# Parity is enforced on feature branches only.  Non-feature branches
# (develop, main, maintenance/*) exit 0 without checking.
if [ -z "$STORY_ID" ]; then
    echo "[BURST-PARITY SKIP] Non-feature branch (${BRANCH:-<unknown>}) — parity enforced on feature branches only"
    exit 0
fi

CHANGELOG_FILE="CHANGELOG.md"
EVIDENCE_REPORT="docs/demo-evidence/${STORY_ID}/evidence-report.md"

if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "[BURST-PARITY FAIL] CHANGELOG.md not found — failing closed"
    exit 1
fi
if [ ! -f "$EVIDENCE_REPORT" ]; then
    echo "[BURST-PARITY FAIL] evidence-report.md not found at ${EVIDENCE_REPORT} — failing closed"
    exit 1
fi

do_parity_check "$CHANGELOG_FILE" "$EVIDENCE_REPORT" || exit 1
