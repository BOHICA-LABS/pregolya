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
# Used as an ERE alternation in id-extraction and count-extraction grep patterns
# (straight-line uses; not in a loop).
# SEV_LIST is the canonical severity enumeration; SEV is its ERE alternation form.
SEV_LIST='CRIT HIGH MED LOW OBS PROCESS-GAP'
SEV="($(echo "$SEV_LIST" | tr ' ' '|'))"

# ── do_parity_check <changelog_file> <evidence_report_file> ─────────────────
#
# Core check logic.  Uses `return` (not `exit`) so the self-probe can call it
# and inspect the exit code without aborting the whole script.
#
# Exit codes: 0 = PASS, 1 = FAIL.
do_parity_check() {
    local cl_file="$1"
    local er_file="$2"
    local cl_declared cl_actual er_declared er_actual cl_dupes er_dupes sev

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

    # ── Fail-closed: tally lines must be extractable to certify the tally ───────
    # Hoisted before pass-number comparison: both cl_pass and er_pass are always
    # non-empty when cl_tally/er_tally are non-empty (the tally regex requires
    # Pass-<N>). Format drift that makes the pass token absent will also make the
    # tally line un-extractable, caught here first. This guard fires before any
    # downstream check that depends on tally content.
    if [ -z "$cl_tally" ] || [ -z "$er_tally" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: tally extraction empty — cannot certify tally"
        return 1
    fi

    # ── Pass-number agreement between CHANGELOG and evidence-report ─────────────
    # The -n guards on cl_pass/er_pass are redundant: non-empty tally implies
    # non-empty pass (the tally regex requires Pass-<N>). The empty-tally guard
    # above catches the unreachable case. This guard fires only when both
    # extractions succeed and they disagree.
    local cl_pass er_pass
    cl_pass=$(printf '%s\n' "$cl_tally" \
        | grep -oE 'Pass-[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
    er_pass=$(printf '%s\n' "$er_tally" \
        | grep -oE 'pass [0-9]+' | grep -oE '[0-9]+' | head -1 || true)

    if [ "$cl_pass" != "$er_pass" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: CHANGELOG cites Pass-${cl_pass} but evidence-report cites Adversary pass ${er_pass}"
        return 1
    fi

    local cl_counts er_counts
    cl_counts=$(printf '%s\n' "$cl_tally" \
        | grep -oE "[0-9]+ ${SEV}" | sort || true)
    er_counts=$(printf '%s\n' "$er_tally" \
        | grep -oE "[0-9]+ ${SEV}" | sort || true)

    # ── Fail-closed: tally severity-count tokens must be extractable ─────────────
    # A tally line that contains no "N SEV" tokens (e.g. CLEAN(strict)=yes with no
    # severity breakdown) would silently pass the equality check below (empty==empty),
    # masking a format gap.  Fail closed instead.
    if [ -z "$cl_counts" ] || [ -z "$er_counts" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: tally line found but no severity-count tokens extracted (CL: '${cl_counts:-empty}' / ER: '${er_counts:-empty}')"
        return 1
    fi

    if [ "$cl_counts" != "$er_counts" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: tally mismatch between CHANGELOG and evidence-report"
        echo "  CHANGELOG tally:         $cl_tally"
        echo "  Evidence-report tally:   $er_tally"
        return 1
    fi

    # ── Duplicate-ID guard: duplicate IDs in either document are a defect ───────
    cl_dupes=$(printf '%s' "$cl_ids" | sort | uniq -d)
    er_dupes=$(printf '%s' "$er_ids" | sort | uniq -d)
    if [ -n "$cl_dupes" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: duplicate finding IDs in CHANGELOG: $cl_dupes"
        return 1
    fi
    if [ -n "$er_dupes" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: duplicate finding IDs in evidence-report: $er_dupes"
        return 1
    fi

    local id_count
    id_count=$(printf '%s\n' "$cl_ids" | wc -l | tr -d ' ')

    # ── Tally sum ↔ ID count reconciliation ─────────────────────────────────────
    # Sum the leading integers from cl_counts and compare to the actual finding
    # ID count.  Catches cases where the tally text is arithmetically inconsistent
    # with the number of heading-delimited IDs in the CHANGELOG section (e.g.,
    # "1 HIGH + 2 MED" declared but only 2 finding headings present → sum 3 ≠ 2).
    local tally_sum=0 n token
    while IFS= read -r token; do
        n=$(printf '%s' "$token" | grep -oE '^[0-9]+' || echo 0)
        tally_sum=$((tally_sum + n))
    done <<< "$cl_counts"

    if [ "$tally_sum" -ne "$id_count" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: declared tally sums to ${tally_sum} but ${id_count} finding IDs enumerated"
        return 1
    fi

    # ── Per-severity histogram: declared counts vs extracted ID counts ───────────
    # Catches cases where the total tally sum is correct but the per-severity
    # breakdown disagrees (e.g. "2 HIGH + 2 OBS" declared but IDs show 1 HIGH + 3 OBS).
    for sev in $SEV_LIST; do
        cl_declared=$(printf '%s' "$cl_tally" | grep -oE "[0-9]+ ${sev}" | grep -oE '^[0-9]+' | head -1 || true)
        cl_actual=$(printf '%s' "$cl_ids" | grep -c "^${sev}-" || true)
        if [ -n "$cl_declared" ] && [ "$cl_declared" != "$cl_actual" ]; then
            echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: CHANGELOG declares ${cl_declared} ${sev} findings but ${cl_actual} ${sev}-prefixed IDs extracted"
            return 1
        fi
    done
    for sev in $SEV_LIST; do
        er_declared=$(printf '%s' "$er_tally" | grep -oE "[0-9]+ ${sev}" | grep -oE '^[0-9]+' | head -1 || true)
        er_actual=$(printf '%s' "$er_ids" | grep -c "^${sev}-" || true)
        if [ -n "$er_declared" ] && [ "$er_declared" != "$er_actual" ]; then
            echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: evidence-report declares ${er_declared} ${sev} findings but ${er_actual} ${sev}-prefixed IDs extracted"
            return 1
        fi
    done

    # ── Compare ID sets ───────────────────────────────────────────────────────
    if [ "$cl_ids" != "$er_ids" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: finding ID mismatch between CHANGELOG and evidence-report"
        echo "  In CHANGELOG only:      $(comm -23 <(printf '%s\n' "$cl_ids") <(printf '%s\n' "$er_ids") | tr '\n' ' ')"
        echo "  In evidence-report only: $(comm -13 <(printf '%s\n' "$cl_ids") <(printf '%s\n' "$er_ids") | tr '\n' ' ')"
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
# Each probe is documented inline at its construction site.
# Run with --self-probe to list all probe scenarios.
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
    # MED-002.  Identical tally (1 HIGH + 1 MED); diverges only on ID ordinal.
    local fake_er1="$tmpdir1/evidence-report.md"
    cat > "$fake_er1" <<'PROBE_HEREDOC'
## fix-burst-99 re-verification

**Adversary pass 97 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 1 MED.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P97-HIGH-001 | HIGH | test class | test artifact |
| F-P97-MED-002 | MED | test class | test artifact |
PROBE_HEREDOC

    local probe1_out="" probe1_exit=0
    probe1_out=$(do_parity_check "$fake_cl1" "$fake_er1" 2>&1) || probe1_exit=$?
    rm -rf "$tmpdir1"

    if [ "$probe1_exit" -ne 0 ] && echo "$probe1_out" | grep -qF "fix-burst-99: finding ID mismatch"; then
        echo "[SELF-PROBE PASS] probe-1 (ID-mismatch): divergent ID pair correctly detected mismatch"
    else
        echo "[SELF-PROBE FAIL] probe-1 (ID-mismatch): expected non-zero exit with 'fix-burst-99: finding ID mismatch' but got exit=${probe1_exit}, output='${probe1_out}'"
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

    local probe2_out="" probe2_exit=0
    probe2_out=$(do_parity_check "$fake_cl2" "$fake_er2" 2>&1) || probe2_exit=$?
    rm -rf "$tmpdir2"

    if [ "$probe2_exit" -ne 0 ] && echo "$probe2_out" | grep -qF "fix-burst-98: tally mismatch"; then
        echo "[SELF-PROBE PASS] probe-2 (tally-divergent): identical IDs with divergent tallies correctly detected mismatch"
    else
        echo "[SELF-PROBE FAIL] probe-2 (tally-divergent): expected non-zero exit with 'fix-burst-98: tally mismatch' but got exit=${probe2_exit}, output='${probe2_out}'"
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

    local probe3_out="" probe3_exit=0
    probe3_out=$(do_parity_check "$fake_cl3" "$fake_er3" 2>&1) || probe3_exit=$?
    rm -rf "$tmpdir3"

    if [ "$probe3_exit" -ne 0 ] && echo "$probe3_out" | grep -qF "fix-burst-97: declared tally sums to"; then
        echo "[SELF-PROBE PASS] probe-3 (tally-sum≠id-count): declared tally sum 3 vs 2 IDs correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-3 (tally-sum≠id-count): expected non-zero exit with 'fix-burst-97: declared tally sums to' but got exit=${probe3_exit}, output='${probe3_out}'"
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

    local probe4_out="" probe4_exit=0
    probe4_out=$(do_parity_check "$fake_cl4" "$fake_er4" 2>&1) || probe4_exit=$?
    rm -rf "$tmpdir4"

    if [ "$probe4_exit" -ne 0 ] && echo "$probe4_out" | grep -qF "fix-burst-95: CHANGELOG cites Pass-"; then
        echo "[SELF-PROBE PASS] probe-4 (pass-number-divergent): divergent pass numbers (CHANGELOG Pass-94 vs evidence-report pass 93) correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-4 (pass-number-divergent): expected non-zero exit with 'fix-burst-95: CHANGELOG cites Pass-' but got exit=${probe4_exit}, output='${probe4_out}'"
        all_passed=1
    fi

    # ── Probe 5: tally-line-absent ─────────────────────────────────────────────
    # CHANGELOG section has finding headings but no tally line.
    # The hoisted empty-tally fail-closed guard must detect the absent CHANGELOG
    # tally and return non-zero.
    local tmpdir5
    tmpdir5="$(mktemp -d)"

    local fake_cl5="$tmpdir5/CHANGELOG.md"
    cat > "$fake_cl5" <<'PROBE_HEREDOC'
## fix-burst-94 (pass-92 findings)

### HIGH-001: Some finding

Description of the finding.
PROBE_HEREDOC

    local fake_er5="$tmpdir5/evidence-report.md"
    cat > "$fake_er5" <<'PROBE_HEREDOC'
## fix-burst-94 re-verification

**Adversary pass 92 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P92-HIGH-001 | HIGH | test class | test artifact |
PROBE_HEREDOC

    local probe5_out="" probe5_exit=0
    probe5_out=$(do_parity_check "$fake_cl5" "$fake_er5" 2>&1) || probe5_exit=$?
    rm -rf "$tmpdir5"

    if [ "$probe5_exit" -ne 0 ] && echo "$probe5_out" | grep -qF "fix-burst-94: tally extraction empty"; then
        echo "[SELF-PROBE PASS] probe-5 (tally-line-absent): absent CHANGELOG tally correctly detected mismatch"
    else
        echo "[SELF-PROBE FAIL] probe-5 (tally-line-absent): expected non-zero exit with 'fix-burst-94: tally extraction empty' but got exit=${probe5_exit}, output='${probe5_out}'"
        all_passed=1
    fi

    # ── Probe 6: er-newest-burst-divergent ────────────────────────────────────────
    # ER newest burst (95) is newer than CHANGELOG newest burst (94).
    # The `## fix-burst-94 re-verification` block is present so the
    # section-existence guard passes; control reaches the
    # `er_newest_burst != newest_burst` comparison, which is the guard under
    # test here. Do not remove that block — its absence silently reverts this
    # probe to section-existence coverage (fix-burst-59 HIGH-001).
    local tmpdir6
    tmpdir6="$(mktemp -d)"

    local fake_cl6="$tmpdir6/CHANGELOG.md"
    cat > "$fake_cl6" <<'PROBE_HEREDOC'
## fix-burst-94 (pass-92 findings)

**Pass-92 finding tally: 1 HIGH**

### HIGH-001: Some finding

Description of the finding.
PROBE_HEREDOC

    local fake_er6="$tmpdir6/evidence-report.md"
    cat > "$fake_er6" <<'PROBE_HEREDOC'
## fix-burst-94 re-verification

**Adversary pass 92 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P92-HIGH-001 | HIGH | test class | test artifact |

## fix-burst-95 re-verification

**Adversary pass 93 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P93-HIGH-001 | HIGH | test class | test artifact |
PROBE_HEREDOC

    local probe6_out="" probe6_exit=0
    probe6_out=$(do_parity_check "$fake_cl6" "$fake_er6" 2>&1) || probe6_exit=$?
    rm -rf "$tmpdir6"

    if [ "$probe6_exit" -ne 0 ] && echo "$probe6_out" | grep -qF "evidence-report newest burst (fix-burst-95) differs from CHANGELOG newest burst (fix-burst-94)"; then
        echo "[SELF-PROBE PASS] probe-6 (er-newest-burst-divergent): ER-newer-than-CHANGELOG correctly detected mismatch"
    else
        echo "[SELF-PROBE FAIL] probe-6 (er-newest-burst-divergent): expected non-zero exit with 'evidence-report newest burst (fix-burst-95) differs from CHANGELOG newest burst (fix-burst-94)' but got exit=${probe6_exit}, output='${probe6_out}'"
        all_passed=1
    fi

    # ── Probe 7: per-severity-histogram-divergent ─────────────────────────────
    # CHANGELOG tally declares 2 HIGH + 2 OBS but contains only 1 HIGH heading
    # (HIGH-001) and 3 OBS headings (OBS-001, OBS-002, OBS-003).
    # Tally sum = 4 = id_count = 4 (no sum mismatch), no duplicate IDs.
    # The per-severity histogram check must detect HIGH declared=2 but actual=1.
    local tmpdir7
    tmpdir7="$(mktemp -d)"

    local fake_cl7="$tmpdir7/CHANGELOG.md"
    cat > "$fake_cl7" <<'PROBE_HEREDOC'
## fix-burst-96 (pass-92 findings)

**Pass-92 finding tally: 2 HIGH + 2 OBS**

### HIGH-001: A high severity finding

Description of the high finding.

### OBS-001: An obs finding

Description of the obs finding.

### OBS-002: Another obs finding

Description of the obs finding.

### OBS-003: Another obs finding

Description of the obs finding.
PROBE_HEREDOC

    local fake_er7="$tmpdir7/evidence-report.md"
    cat > "$fake_er7" <<'PROBE_HEREDOC'
## fix-burst-96 re-verification

**Adversary pass 92 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 2 OBS.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P92-HIGH-001 | HIGH | test class | test artifact |
| F-P92-OBS-001 | OBS | test class | test artifact |
| F-P92-OBS-002 | OBS | test class | test artifact |
| F-P92-OBS-003 | OBS | test class | test artifact |
PROBE_HEREDOC

    local probe7_out="" probe7_exit=0
    probe7_out=$(do_parity_check "$fake_cl7" "$fake_er7" 2>&1) || probe7_exit=$?
    rm -rf "$tmpdir7"

    if [ "$probe7_exit" -ne 0 ] && echo "$probe7_out" | grep -qF "fix-burst-96: CHANGELOG declares"; then
        echo "[SELF-PROBE PASS] probe-7 (per-severity-histogram-divergent): histogram mismatch (2 HIGH declared, 1 actual) correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-7 (per-severity-histogram-divergent): expected non-zero exit with 'fix-burst-96: CHANGELOG declares' but got exit=${probe7_exit}, output='${probe7_out}'"
        all_passed=1
    fi

    # ── Probe 8: duplicate-id-detected ───────────────────────────────────────
    # CHANGELOG tally declares 2 HIGH + 1 MED + 1 LOW (sum=4) with 4 headings,
    # but HIGH-001 appears twice (duplicate).  Histogram: declared HIGH=2,
    # actual HIGH=2 (two HIGH-prefixed IDs extracted) — histogram passes.
    # The duplicate-ID guard must detect the duplicate before or at its guard.
    local tmpdir8
    tmpdir8="$(mktemp -d)"

    local fake_cl8="$tmpdir8/CHANGELOG.md"
    cat > "$fake_cl8" <<'PROBE_HEREDOC'
## fix-burst-93 (pass-92 findings)

**Pass-92 finding tally: 2 HIGH + 1 MED + 1 LOW**

### HIGH-001: A high severity finding

Description of the high finding.

### HIGH-001: Duplicate high severity finding

Description of the duplicate.

### MED-001: A medium severity finding

Description of the medium finding.

### LOW-001: A low severity finding

Description of the low finding.
PROBE_HEREDOC

    local fake_er8="$tmpdir8/evidence-report.md"
    cat > "$fake_er8" <<'PROBE_HEREDOC'
## fix-burst-93 re-verification

**Adversary pass 92 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 2 HIGH + 1 MED + 1 LOW.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P92-HIGH-001 | HIGH | test class | test artifact |
| F-P92-HIGH-001 | HIGH | test class | test artifact |
| F-P92-MED-001 | MED | test class | test artifact |
| F-P92-LOW-001 | LOW | test class | test artifact |
PROBE_HEREDOC

    local probe8_out="" probe8_exit=0
    probe8_out=$(do_parity_check "$fake_cl8" "$fake_er8" 2>&1) || probe8_exit=$?
    rm -rf "$tmpdir8"

    if [ "$probe8_exit" -ne 0 ] && echo "$probe8_out" | grep -qF "fix-burst-93: duplicate finding IDs in CHANGELOG:"; then
        echo "[SELF-PROBE PASS] probe-8 (duplicate-id-detected): duplicate finding ID (HIGH-001) in CHANGELOG correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-8 (duplicate-id-detected): expected non-zero exit with 'fix-burst-93: duplicate finding IDs in CHANGELOG:' but got exit=${probe8_exit}, output='${probe8_out}'"
        all_passed=1
    fi

    # ── Probe 9: re-verification-section-existence ────────────────────────────
    # CHANGELOG has fix-burst-94. ER has no re-verification sections.
    # er_newest_burst="" → er_newest_burst guard does not fire.
    # Section-existence guard fires because ER is missing fix-burst-94 re-verification.
    local tmpdir9
    tmpdir9="$(mktemp -d)"

    local fake_cl9="$tmpdir9/CHANGELOG.md"
    cat > "$fake_cl9" <<'PROBE_HEREDOC'
## fix-burst-94 (pass-92 findings)

**Pass-92 finding tally: 1 HIGH**

### HIGH-001: Some finding

Description of the finding.
PROBE_HEREDOC

    local fake_er9="$tmpdir9/evidence-report.md"
    cat > "$fake_er9" <<'PROBE_HEREDOC'
## Some other section

This ER has no re-verification sections at all.
PROBE_HEREDOC

    local probe9_out="" probe9_exit=0
    probe9_out=$(do_parity_check "$fake_cl9" "$fake_er9" 2>&1) || probe9_exit=$?
    rm -rf "$tmpdir9"

    if [ "$probe9_exit" -ne 0 ] && echo "$probe9_out" | grep -qF "CHANGELOG has '## fix-burst-94' but evidence-report is missing"; then
        echo "[SELF-PROBE PASS] probe-9 (section-existence-missing): CHANGELOG newest burst missing from ER re-verification correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-9 (section-existence-missing): expected non-zero exit with \"CHANGELOG has '## fix-burst-94' but evidence-report is missing\" but got exit=${probe9_exit}, output='${probe9_out}'"
        all_passed=1
    fi

    # ── Probe 10: heading-format-drift ────────────────────────────────────────
    # CHANGELOG has fix-burst tokens (case-insensitive) but NO canonical
    # '^## fix-burst-[0-9]+' headings (capital letters prevent the canonical match).
    # newest_burst="" → heading-format-drift guard fires.
    local tmpdir10
    tmpdir10="$(mktemp -d)"

    local fake_cl10="$tmpdir10/CHANGELOG.md"
    cat > "$fake_cl10" <<'PROBE_HEREDOC'
## Fix-Burst-94 (pass-92 findings)

**Pass-92 finding tally: 1 HIGH**

### HIGH-001: Some finding

Description of the finding.
PROBE_HEREDOC

    local fake_er10="$tmpdir10/evidence-report.md"
    cat > "$fake_er10" <<'PROBE_HEREDOC'
## some section

Irrelevant content.
PROBE_HEREDOC

    local probe10_out="" probe10_exit=0
    probe10_out=$(do_parity_check "$fake_cl10" "$fake_er10" 2>&1) || probe10_exit=$?
    rm -rf "$tmpdir10"

    if [ "$probe10_exit" -ne 0 ] && echo "$probe10_out" | grep -qF "heading-format drift detected"; then
        echo "[SELF-PROBE PASS] probe-10 (heading-format-drift): non-canonical fix-burst heading correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-10 (heading-format-drift): expected non-zero exit with 'heading-format drift detected' but got exit=${probe10_exit}, output='${probe10_out}'"
        all_passed=1
    fi

    # ── Probe 11: cl-ids-empty ────────────────────────────────────────────────
    # CHANGELOG has canonical fix-burst-94 heading with a valid tally, but NO
    # '### HIGH-001:' style headings in the section.
    # The heading-format-drift, section-existence, and er_newest_burst guards
    # all pass; then the cl_ids-empty fail-closed guard fires (it precedes
    # tally extraction).
    local tmpdir11
    tmpdir11="$(mktemp -d)"

    local fake_cl11="$tmpdir11/CHANGELOG.md"
    cat > "$fake_cl11" <<'PROBE_HEREDOC'
## fix-burst-94 (pass-92 findings)

**Pass-92 finding tally: 1 HIGH**

Descriptive text with no finding headings.
PROBE_HEREDOC

    local fake_er11="$tmpdir11/evidence-report.md"
    cat > "$fake_er11" <<'PROBE_HEREDOC'
## fix-burst-94 re-verification

**Adversary pass 92 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P92-HIGH-001 | HIGH | test class | test artifact |
PROBE_HEREDOC

    local probe11_out="" probe11_exit=0
    probe11_out=$(do_parity_check "$fake_cl11" "$fake_er11" 2>&1) || probe11_exit=$?
    rm -rf "$tmpdir11"

    if [ "$probe11_exit" -ne 0 ] && echo "$probe11_out" | grep -qF "CHANGELOG section extraction returned empty for fix-burst-94"; then
        echo "[SELF-PROBE PASS] probe-11 (cl-ids-empty): empty CHANGELOG finding-ID extraction correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-11 (cl-ids-empty): expected non-zero exit with 'CHANGELOG section extraction returned empty for fix-burst-94' but got exit=${probe11_exit}, output='${probe11_out}'"
        all_passed=1
    fi

    # ── Probe 12: er-ids-empty ────────────────────────────────────────────────
    # CHANGELOG has canonical headings (cl_ids non-empty), but ER section has
    # no '| F-P92-HIGH-001 |' rows — just descriptive text.
    # cl_ids is non-empty so the cl_ids-empty guard passes;
    # then the er_ids-empty fail-closed guard fires.
    local tmpdir12
    tmpdir12="$(mktemp -d)"

    local fake_cl12="$tmpdir12/CHANGELOG.md"
    cat > "$fake_cl12" <<'PROBE_HEREDOC'
## fix-burst-94 (pass-92 findings)

**Pass-92 finding tally: 1 HIGH**

### HIGH-001: Some finding

Description of the finding.
PROBE_HEREDOC

    local fake_er12="$tmpdir12/evidence-report.md"
    cat > "$fake_er12" <<'PROBE_HEREDOC'
## fix-burst-94 re-verification

**Adversary pass 92 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH.

Descriptive text with no finding rows.
PROBE_HEREDOC

    local probe12_out="" probe12_exit=0
    probe12_out=$(do_parity_check "$fake_cl12" "$fake_er12" 2>&1) || probe12_exit=$?
    rm -rf "$tmpdir12"

    if [ "$probe12_exit" -ne 0 ] && echo "$probe12_out" | grep -qF "evidence-report re-verification section extraction returned empty for fix-burst-94"; then
        echo "[SELF-PROBE PASS] probe-12 (er-ids-empty): empty ER finding-ID extraction correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-12 (er-ids-empty): expected non-zero exit with 'evidence-report re-verification section extraction returned empty for fix-burst-94' but got exit=${probe12_exit}, output='${probe12_out}'"
        all_passed=1
    fi

    # ── Probe 13: er-duplicate-id ─────────────────────────────────────────────
    # The cl_dupes guard passes (no CL duplicates).  The er_dupes guard fires
    # because F-P89-HIGH-001 appears twice in the ER finding rows.
    # Verifies that the er_dupes fail-closed guard is exercised by the self-probe
    # suite (it has zero coverage in probes 1-12, which never reach it via the
    # er_dupes path).
    local tmpdir13
    tmpdir13="$(mktemp -d)"

    local fake_cl13="$tmpdir13/CHANGELOG.md"
    cat > "$fake_cl13" <<'PROBE_HEREDOC'
## fix-burst-91 (pass-89 findings)

**Pass-89 finding tally: 1 HIGH + 1 MED**

### HIGH-001: A high severity finding

Description of the high finding.

### MED-001: A medium severity finding

Description of the medium finding.
PROBE_HEREDOC

    local fake_er13="$tmpdir13/evidence-report.md"
    cat > "$fake_er13" <<'PROBE_HEREDOC'
## fix-burst-91 re-verification

**Adversary pass 89 result:** CLEAN(strict)=no — 1 HIGH + 1 MED.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P89-HIGH-001 | HIGH | test class | test artifact |
| F-P89-HIGH-001 | HIGH | test class | test artifact |
| F-P89-MED-001 | MED | test class | test artifact |
PROBE_HEREDOC

    local probe13_out="" probe13_exit=0
    probe13_out=$(do_parity_check "$fake_cl13" "$fake_er13" 2>&1) || probe13_exit=$?
    rm -rf "$tmpdir13"

    if [ "$probe13_exit" -ne 0 ] && echo "$probe13_out" | grep -qF "fix-burst-91: duplicate finding IDs in evidence-report:"; then
        echo "[SELF-PROBE PASS] probe-13 (er-duplicate-id): duplicate finding ID (F-P89-HIGH-001) in evidence-report correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-13 (er-duplicate-id): expected non-zero exit with 'fix-burst-91: duplicate finding IDs in evidence-report:' but got exit=${probe13_exit}, output='${probe13_out}'"
        all_passed=1
    fi

    # ── Probe 14: er-per-severity-histogram-divergent ─────────────────────────
    # CL tally declares 1 HIGH + 2 MED with 3 headings (HIGH-001, MED-001, MED-002) —
    # sum=3=id_count, CL histogram correct.  ER tally also declares 1 HIGH + 2 MED
    # (so tally-count comparison passes), but ER has 3 finding rows:
    # F-P88-HIGH-001, F-P88-HIGH-002, F-P88-MED-001 — no duplicates, sum=3=id_count,
    # but 2 HIGH rows where tally declares 1 HIGH.
    # The ER per-severity histogram loop detects 1 HIGH declared vs 2 HIGH actual →
    # fires before the ID-set comparison guard is reached.
    local tmpdir14
    tmpdir14="$(mktemp -d)"

    local fake_cl14="$tmpdir14/CHANGELOG.md"
    cat > "$fake_cl14" <<'PROBE_HEREDOC'
## fix-burst-90 (pass-88 findings)

**Pass-88 finding tally: 1 HIGH + 2 MED**

### HIGH-001: A high severity finding

Description of the high finding.

### MED-001: A medium severity finding

Description of the medium finding.

### MED-002: Another medium severity finding

Description of the second medium finding.
PROBE_HEREDOC

    local fake_er14="$tmpdir14/evidence-report.md"
    cat > "$fake_er14" <<'PROBE_HEREDOC'
## fix-burst-90 re-verification

**Adversary pass 88 result:** CLEAN(strict)=no — 1 HIGH + 2 MED.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P88-HIGH-001 | HIGH | test class | test artifact |
| F-P88-HIGH-002 | HIGH | test class | test artifact |
| F-P88-MED-001 | MED | test class | test artifact |
PROBE_HEREDOC

    local probe14_out="" probe14_exit=0
    probe14_out=$(do_parity_check "$fake_cl14" "$fake_er14" 2>&1) || probe14_exit=$?
    rm -rf "$tmpdir14"

    if [ "$probe14_exit" -ne 0 ] && echo "$probe14_out" | grep -qF "fix-burst-90: evidence-report declares"; then
        echo "[SELF-PROBE PASS] probe-14 (er-per-severity-histogram-divergent): ER histogram mismatch (1 HIGH declared, 2 actual) correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-14 (er-per-severity-histogram-divergent): expected non-zero exit with 'fix-burst-90: evidence-report declares' but got exit=${probe14_exit}, output='${probe14_out}'"
        all_passed=1
    fi

    # ── Probe 15: er-tally-counts-absent ──────────────────────────────────────
    # Both CL and ER have tally lines, but the ER tally line contains no
    # "N SEV" tokens (e.g. CLEAN(strict)=yes with no severity breakdown suffix).
    # The fail-closed empty-extraction guard fires after extracting er_counts="".
    # Without this guard the empty er_counts would silently pass the equality
    # check (empty == empty), masking the format gap.
    # (LOW-001 fix: this message now routes to stdout, not stderr, consistent
    # with all other FAIL messages.)
    local tmpdir15
    tmpdir15="$(mktemp -d)"

    local fake_cl15="$tmpdir15/CHANGELOG.md"
    cat > "$fake_cl15" <<'PROBE_HEREDOC'
## fix-burst-89 (pass-87 findings)

**Pass-87 finding tally: 1 HIGH**

### HIGH-001: A high severity finding

Description of the high finding.
PROBE_HEREDOC

    local fake_er15="$tmpdir15/evidence-report.md"
    cat > "$fake_er15" <<'PROBE_HEREDOC'
## fix-burst-89 re-verification

**Adversary pass 87 result:** CLEAN(strict)=yes.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P87-HIGH-001 | HIGH | test class | test artifact |
PROBE_HEREDOC

    local probe15_out="" probe15_exit=0
    probe15_out=$(do_parity_check "$fake_cl15" "$fake_er15" 2>&1) || probe15_exit=$?
    rm -rf "$tmpdir15"

    if [ "$probe15_exit" -ne 0 ] && echo "$probe15_out" | grep -qF "fix-burst-89: tally line found but no severity-count tokens extracted"; then
        echo "[SELF-PROBE PASS] probe-15 (er-tally-counts-absent): ER tally line with no severity-count tokens correctly detected"
    else
        echo "[SELF-PROBE FAIL] probe-15 (er-tally-counts-absent): expected non-zero exit with 'fix-burst-89: tally line found but no severity-count tokens extracted' but got exit=${probe15_exit}, output='${probe15_out}'"
        all_passed=1
    fi

    # ── Probe 16: happy-path ───────────────────────────────────────────────────
    # Well-formed, matching CHANGELOG and evidence-report: `do_parity_check`
    # must exit 0 and output must contain [BURST-PARITY PASS].
    local tmpdir16
    tmpdir16="$(mktemp -d)"

    local fake_cl16="$tmpdir16/CHANGELOG.md"
    cat > "$fake_cl16" <<'PROBE_HEREDOC'
## fix-burst-97 (pass-92 findings)

**Pass-92 finding tally: 1 HIGH + 1 MED**

### HIGH-001: A high severity finding

Description of the high finding.

### MED-001: A medium severity finding

Description of the medium finding.
PROBE_HEREDOC

    local fake_er16="$tmpdir16/evidence-report.md"
    cat > "$fake_er16" <<'PROBE_HEREDOC'
## fix-burst-97 re-verification

**Adversary pass 92 result:** CLEAN(strict)=no — 1 HIGH + 1 MED.

| Finding ID | Severity | Status | Category | Load-bearing artifact |
|------------|----------|--------|----------|-----------------------|
| F-P92-HIGH-001 | HIGH | closed | test | test |
| F-P92-MED-001 | MED | closed | test | test |
PROBE_HEREDOC

    local probe16_out="" probe16_exit=0
    probe16_out=$(do_parity_check "$fake_cl16" "$fake_er16" 2>&1) || probe16_exit=$?
    rm -rf "$tmpdir16"

    if [ "$probe16_exit" -eq 0 ] && echo "$probe16_out" | grep -qF "[BURST-PARITY PASS]"; then
        echo "[SELF-PROBE PASS] probe-16 (happy-path): well-formed matching input correctly passes"
    else
        echo "[SELF-PROBE FAIL] probe-16 (happy-path): expected exit 0 with '[BURST-PARITY PASS]' but got exit=${probe16_exit}, output='${probe16_out}'"
        all_passed=1
    fi

    # ── Probe 17: skip-path ────────────────────────────────────────────────────
    # CHANGELOG with no `fix-burst` tokens at all: `do_parity_check` must exit 0
    # and output must contain [BURST-PARITY SKIP].
    local tmpdir17
    tmpdir17="$(mktemp -d)"

    local fake_cl17="$tmpdir17/CHANGELOG.md"
    cat > "$fake_cl17" <<'PROBE_HEREDOC'
# Changelog
## [Unreleased]
### Added
- Initial feature
PROBE_HEREDOC

    # ER can be anything — it is not read when the skip path fires.
    local fake_er17="$tmpdir17/evidence-report.md"
    cat > "$fake_er17" <<'PROBE_HEREDOC'
# Evidence Report
PROBE_HEREDOC

    local probe17_out="" probe17_exit=0
    probe17_out=$(do_parity_check "$fake_cl17" "$fake_er17" 2>&1) || probe17_exit=$?
    rm -rf "$tmpdir17"

    if [ "$probe17_exit" -eq 0 ] && echo "$probe17_out" | grep -qF "[BURST-PARITY SKIP]"; then
        echo "[SELF-PROBE PASS] probe-17 (skip-path): no fix-burst sections correctly skipped"
    else
        echo "[SELF-PROBE FAIL] probe-17 (skip-path): expected exit 0 with '[BURST-PARITY SKIP]' but got exit=${probe17_exit}, output='${probe17_out}'"
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
