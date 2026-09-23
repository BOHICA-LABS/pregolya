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
        echo "[BURST-PARITY] No fix-burst sections found in CHANGELOG — skipping."
        return 0
    fi

    # ── Re-verification section must exist before any extraction ────────────
    if ! grep -q "^## fix-burst-${newest_burst} re-verification" "$er_file"; then
        echo "[BURST-PARITY FAIL] CHANGELOG has '## fix-burst-${newest_burst}' but evidence-report is missing '## fix-burst-${newest_burst} re-verification'."
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

    local cl_counts er_counts
    cl_counts=$(printf '%s\n' "$cl_tally" \
        | grep -oE "[0-9]+ ${SEV}" | sort || true)
    er_counts=$(printf '%s\n' "$er_tally" \
        | grep -oE "[0-9]+ ${SEV}" | sort || true)

    if [ -n "$cl_counts" ] && [ -n "$er_counts" ] && [ "$cl_counts" != "$er_counts" ]; then
        echo "[BURST-PARITY FAIL] fix-burst-${newest_burst}: tally mismatch between CHANGELOG and evidence-report"
        echo "  CHANGELOG tally:         $cl_tally"
        echo "  Evidence-report tally:   $er_tally"
        return 1
    fi

    local id_count
    id_count=$(printf '%s\n' "$cl_ids" | wc -l | tr -d ' ')
    echo "[BURST-PARITY PASS] fix-burst-${newest_burst}: ${id_count} finding IDs matched; tally verified."
    return 0
}

# ── Self-probe ───────────────────────────────────────────────────────────────
#
# Creates a deliberately-divergent pair of synthetic CHANGELOG + evidence-report
# and asserts that do_parity_check detects the mismatch (exits non-zero).
# This pins the regex logic against future breakage.
run_self_probes() {
    local tmpdir
    tmpdir="$(mktemp -d)"

    # Synthetic CHANGELOG: fix-burst-99 with HIGH-001 and MED-001.
    local fake_cl="$tmpdir/CHANGELOG.md"
    cat > "$fake_cl" <<'PROBE_HEREDOC'
## fix-burst-99 (pass-97 findings)

**Pass-97 finding tally: 1 HIGH + 1 MED**

### HIGH-001: A high severity finding

Description of the high finding.

### MED-001: A medium severity finding

Description of the medium finding.
PROBE_HEREDOC

    # Synthetic evidence-report: fix-burst-99 re-verification with HIGH-001 and
    # LOW-001.  Deliberately divergent: CHANGELOG says MED-001, ER says LOW-001.
    local fake_er="$tmpdir/evidence-report.md"
    cat > "$fake_er" <<'PROBE_HEREDOC'
## fix-burst-99 re-verification

**Adversary pass 97 result:** CLEAN(strict)=no, CLEAN(PR-merge)=no — 1 HIGH + 1 LOW.

| Finding | Severity | Detection class | Load-bearing artifact |
|---------|----------|-----------------|-----------------------|
| F-P97-HIGH-001 | HIGH | test class | test artifact |
| F-P97-LOW-001 | LOW | test class | test artifact |
PROBE_HEREDOC

    # Run the check against the synthetic pair; expect a non-zero exit (FAIL).
    local probe_exit=0
    do_parity_check "$fake_cl" "$fake_er" >/dev/null 2>&1 || probe_exit=$?
    rm -rf "$tmpdir"

    if [ "$probe_exit" -ne 0 ]; then
        echo "[SELF-PROBE PASS] burst-parity deliberately-divergent pair correctly detected mismatch"
    else
        echo "[SELF-PROBE FAIL] burst-parity self-probe: divergent pair was not detected"
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
