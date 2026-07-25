#!/usr/bin/env bash
# verify-adr-self-version-refs.sh — ferrochain factory-artifacts advisory validator (#5)
#
# PURPOSE:
#   For each ADR file under specs/architecture/decisions/, extracts the set of
#   version labels declared in its changelog (frontmatter YAML `changelog:` list
#   and/or body ## Changelog table; handles both vX.Y and rev-N label formats),
#   then scans the ADR's LIVE BODY for self-referential version tokens of the
#   form vN.N, and flags any that are absent from the changelog or are stale
#   (not the latest declared version).
#
# ─────────────────────────────────────────────────────────────────────────────
# SELF-REF DETECTION HEURISTIC
# ─────────────────────────────────────────────────────────────────────────────
#
# A `vN.N` token in the live body is classified as a SELF-REFERENCE if the
# nearest preceding "artifact-name token" on the SAME LINE is either:
#   (a) this ADR's own ID (e.g. "ADR-010" while scanning ADR-010), or
#   (b) absent — bare version with no recognizable artifact context.
#
# A `vN.N` is classified as a CROSS-DOC reference (not flagged) if the nearest
# preceding artifact-name token is a DIFFERENT artifact.
#
# Recognized artifact-name token patterns (terminate self-ref classification):
#   ADR-NNN                    — any ADR ID (e.g. ADR-016)
#   BC-S.SS.NNN                — behavioral contract IDs (e.g. BC-2.06.001)
#   VP-NNN                     — verification property IDs (e.g. VP-009)
#   CAP-NNN                    — capability IDs (e.g. CAP-021)
#   [a-z][a-z0-9]*(-[a-z0-9]+)+ — lowercase hyphenated doc names (e.g. error-taxonomy,
#                                  interface-definitions, bc-authoring-plan,
#                                  verification-architecture, module-decomposition,
#                                  purity-boundary-map) — with optional .md suffix
#   [A-Z][A-Z0-9]*-(INDEX|OVERVIEW|AUDIT)  — uppercase compound names (e.g. ARCH-INDEX,
#                                             VP-INDEX, BC-INDEX, L2-INDEX)
#
# ─────────────────────────────────────────────────────────────────────────────
# EXEMPTED REGIONS (not scanned for self-refs)
# ─────────────────────────────────────────────────────────────────────────────
#
#   (a) YAML frontmatter block — all lines between the first and second '---'
#       delimiters. Rationale: changelog: list entries and version: field are
#       the authoritative version declarations; scanning them would produce
#       trivial self-matches for every version ever declared.
#
#   (b) Body ## Changelog section — all lines from a "## Changelog" heading
#       through the next "## " heading or EOF. Rationale: these rows record
#       historical change state explicitly and are exempt per TD-VSDD-091
#       (pass-report changelog exception). Same exemption as verify-no-version-pins.sh.
#
# ─────────────────────────────────────────────────────────────────────────────
# KNOWN HEURISTIC LIMITS (documented; non-fatal false-positive WARNs expected)
# ─────────────────────────────────────────────────────────────────────────────
#
#   1. Cross-line artifact references: if an artifact name appears on line N
#      and its version appears at the start of line N+1 (sentence wraps), the
#      vN.N on N+1 has no preceding artifact on its own line and will be flagged
#      as a self-ref. Produces a false-positive WARN that the adversary can
#      dismiss by reading context.
#      Current corpus example: ADR-013 line 153 — "in v1.7" refers to
#      module-decomposition.md v1.7, but "module-decomposition.md" is on the
#      preceding line. This WARN is expected and correctly classified as a
#      heuristic false-positive.
#
#   2. Historical tracking tables: ADRs that embed a version evolution table
#      (e.g. ADR-010's "Component count summary" with rows "v1.0 (D17)" and
#      "v1.1 (D21)") will produce stale-version WARNs on each row. These are
#      intentional historical documentation, not decay. The adversary should
#      check whether the stale self-ref is in a history table before routing
#      it as a fix candidate.
#
#   3. rev-N changelog format: ADRs whose changelog entries use "rev-N" labels
#      (ADR-001, ADR-006) cannot map body vN.N tokens to rev-N labels. Any bare
#      vN.N in those ADR bodies would be flagged as unknown. No such patterns
#      exist in the current corpus; the limit is noted for future robustness.
#
#   4. Intra-line forward artifact: the heuristic only looks BACKWARD from vN.N
#      to the left-most artifact on the same line. A forward artifact ("v1.3
#      refers to BC-2.06.001") would be a false-positive. No such patterns were
#      observed in the current corpus.
#
# ─────────────────────────────────────────────────────────────────────────────
# ADVISORY ONLY — EXIT 0 ALWAYS (unless the script itself errors)
# ─────────────────────────────────────────────────────────────────────────────
#
# This validator is a HEURISTIC ADVISORY LENS. It NEVER blocks a commit or
# pipeline step. All findings are WARN-only. Exit code is always 0 regardless
# of the number of WARNs found. The adversary and state-manager use findings
# as diagnostic prompts during pass reviews, not as gates.
#
# Usage:   bash .factory/hooks/verify-adr-self-version-refs.sh
# Exit:    0 always
#
# Integration (state-manager burst protocol — advisory validator #5):
#   Run after verify-no-version-pins.sh (validator #4) as a companion lens:
#     bash .factory/hooks/verify-adr-self-version-refs.sh
#   WARNs are reported but do NOT block the commit. Adversary should classify
#   each WARN as: stale-in-history-table (low urgency), stale-in-prose (medium
#   urgency — may need de-labeling per TD-VSDD-091), unknown-version (higher
#   urgency — possible forward-reference or cross-line false-positive), or
#   cross-line-false-positive (dismiss with context check).

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADR_GLOB="$FACTORY_DIR/specs/architecture/decisions/ADR-*.md"

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

# ── Python3 inline scanner ────────────────────────────────────────────────────
#
# For each ADR file:
#   1. Extracts version set from frontmatter `changelog:` YAML list (vX.Y and
#      rev-N entries both handled) and/or body ## Changelog table.
#   2. Adds the frontmatter `version:` field to the version set (it is the
#      latest, authoritative current version even if changelog list is absent).
#   3. Determines the latest version by numeric comparison.
#   4. Scans live body lines for vN.N self-refs using the artifact-prefix
#      heuristic described above.
#   5. Emits one output line per file:
#        PASS <filepath>                  — no self-ref issues found
#        WARN <filepath> <finding>; ...   — one or more self-ref issues found
#        SKIP <filepath> <reason>         — parse error, unreadable, or skipped

PYTHON_OUTPUT="$(python3 - "$ADR_GLOB" <<'PYEOF'
import sys, os, glob, re

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

adr_glob = sys.argv[1]
files = sorted(glob.glob(adr_glob))

# ── Compiled regexes ──────────────────────────────────────────────────────────

# Matches a vN.N version token in body text (e.g. v1.3, v1.10, v2.10)
VN_RE = re.compile(r'v(\d+\.\d+(?:\.\d+)*)')

# Artifact-name tokens that, when preceding vN.N, identify it as a cross-doc ref.
# The last match on the line before vN.N is the "nearest preceding artifact".
ARTIFACT_RE = re.compile(
    r'(?<![A-Za-z0-9])'                                # word-boundary left guard
    r'(?:'
    r'ADR-\d+'                                          # ADR-NNN identifiers
    r'|BC-\d+\.\d+\.\d+'                               # BC-S.SS.NNN identifiers
    r'|VP-\d+'                                          # VP-NNN identifiers
    r'|CAP-\d+'                                         # CAP-NNN identifiers
    r'|[A-Z][A-Z0-9]*-(?:INDEX|OVERVIEW|AUDIT)'         # ARCH-INDEX, VP-INDEX, etc.
    r'|[a-z][a-z0-9]*(?:-[a-z0-9]+)+(?:\.md)?'         # lowercase-hyphenated doc names
    r')'
)

# Changelog entry version extraction patterns
# Frontmatter list entries: "1.6 (...)" or "v1.6 (...)"
FM_VERSION_RE = re.compile(r'^v?(\d+\.\d+(?:\.\d+)*)[\s:(]')
# Frontmatter list entries with rev-N labels: "rev-4 (...)"
FM_REV_RE = re.compile(r'^rev-(\d+)[\s:(]')
# Body ## Changelog table rows: "| 1.2 | ..." or "| v1.2 | ..."
TABLE_VERSION_RE = re.compile(r'^\|\s*v?(\d+\.\d+(?:\.\d+)*)\s*\|')
# Body ## Changelog table rows with rev-N: "| rev-4 | ..."
TABLE_REV_RE = re.compile(r'^\|\s*rev-(\d+)\s*\|')

CHANGELOG_HEADING_RE = re.compile(r'^## Changelog\s*$')
SECTION_HEADING_RE   = re.compile(r'^## ')


def parse_version(s):
    """Convert '1.3' or '1.10' to tuple of ints for numeric comparison."""
    return tuple(int(x) for x in s.split('.'))


# ── Per-file processing ───────────────────────────────────────────────────────

for filepath in files:
    # Extract ADR ID from filename (e.g. "ADR-010" from "ADR-010-error-taxonomy...")
    basename = os.path.basename(filepath)
    id_match = re.match(r'(ADR-\d+)', basename)
    if not id_match:
        print(f"SKIP {filepath} cannot-extract-adr-id")
        continue
    adr_id = id_match.group(1)

    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            raw_lines = fh.readlines()
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    # ── Locate frontmatter boundaries ─────────────────────────────────────────
    fm_end = -1
    if raw_lines and raw_lines[0].rstrip() == '---':
        for i in range(1, len(raw_lines)):
            if raw_lines[i].rstrip() == '---':
                fm_end = i
                break

    if fm_end < 0:
        # No frontmatter found — still scan the body but version set will be empty
        fm_text = ''
        fm = {}
    else:
        fm_text = ''.join(raw_lines[1:fm_end])
        if HAS_YAML:
            try:
                fm = yaml.safe_load(fm_text) or {}
            except Exception:
                fm = {}
        else:
            fm = {}

    # ── Locate body ## Changelog sections ─────────────────────────────────────
    changelog_ranges = []   # list of (start_0idx, end_0idx_exclusive)
    i = fm_end + 1
    while i < len(raw_lines):
        if CHANGELOG_HEADING_RE.match(raw_lines[i]):
            start = i
            j = i + 1
            while j < len(raw_lines):
                if SECTION_HEADING_RE.match(raw_lines[j]):
                    break
                j += 1
            changelog_ranges.append((start, j))
            i = j
        else:
            i += 1

    def in_changelog(line_0idx):
        for (s, e) in changelog_ranges:
            if s <= line_0idx < e:
                return True
        return False

    # ── Build changelog version set ───────────────────────────────────────────
    # cl_versions: set of version strings like "1.3", "1.10", "2.0"
    # cl_revs:     set of rev integers like {1, 2, 4} (for rev-N format ADRs)
    cl_versions = set()
    cl_revs     = set()

    # Source 1: frontmatter `changelog:` list
    if isinstance(fm, dict):
        raw_cl = fm.get('changelog', None)
        if isinstance(raw_cl, list):
            for entry in raw_cl:
                s = str(entry).strip()
                m = FM_VERSION_RE.match(s)
                if m:
                    cl_versions.add(m.group(1))
                else:
                    m2 = FM_REV_RE.match(s)
                    if m2:
                        cl_revs.add(int(m2.group(1)))

    # Source 2: body ## Changelog table rows
    for (rng_start, rng_end) in changelog_ranges:
        for line_0idx in range(rng_start + 1, rng_end):
            line = raw_lines[line_0idx]
            tm = TABLE_VERSION_RE.match(line)
            if tm:
                cl_versions.add(tm.group(1))
            else:
                tr = TABLE_REV_RE.match(line)
                if tr:
                    cl_revs.add(int(tr.group(1)))

    # Source 3: frontmatter `version:` field — authoritative latest
    fm_ver = ''
    if isinstance(fm, dict):
        fm_ver = str(fm.get('version', '')).strip()
    if fm_ver:
        cl_versions.add(fm_ver)

    # ── Determine latest version ───────────────────────────────────────────────
    # For vN.N body tokens we only compare against vN.N changelog entries.
    # rev-N format is tracked in cl_revs but body tokens of the form vN.N would
    # be "unknown" relative to a pure rev-N changelog — noted as a heuristic limit.
    if cl_versions:
        try:
            latest = max(cl_versions, key=parse_version)
        except (ValueError, TypeError):
            latest = None
    else:
        latest = None

    # ── Scan live body for vN.N self-refs ─────────────────────────────────────
    findings = []

    for line_0idx in range(fm_end + 1, len(raw_lines)):
        if in_changelog(line_0idx):
            continue

        line = raw_lines[line_0idx]
        for m in VN_RE.finditer(line):
            ver_str = m.group(1)          # e.g. "1.3" or "1.10"
            pos     = m.start()           # character position of the 'v' prefix

            # ── Self-ref classification ────────────────────────────────────
            # Scan backward on the line for the nearest preceding artifact name.
            prefix            = line[:pos]
            artifact_matches  = list(ARTIFACT_RE.finditer(prefix))

            if artifact_matches:
                nearest = artifact_matches[-1].group(0)
                if nearest == adr_id:
                    # Nearest artifact is this ADR's own ID → explicit self-ref
                    is_self_ref = True
                else:
                    # Nearest artifact is a DIFFERENT document → cross-doc ref
                    is_self_ref = False
            else:
                # No artifact token precedes the version on this line → bare self-ref
                is_self_ref = True

            if not is_self_ref:
                continue

            # ── Classify the self-ref ──────────────────────────────────────
            lineno = line_0idx + 1   # 1-indexed for human readers
            snippet = line.rstrip()[:80]   # context for the message

            if ver_str not in cl_versions:
                # Version label not in changelog — unknown forward-ref or false-positive
                known = sorted(cl_versions, key=parse_version) if cl_versions else []
                findings.append(
                    f"unknown-version:line={lineno},token=v{ver_str},"
                    f"changelog-versions={known}"
                )
            elif latest is not None and parse_version(ver_str) < parse_version(latest):
                # Version label in changelog but not the latest — stale self-ref
                findings.append(
                    f"stale-version:line={lineno},token=v{ver_str},"
                    f"latest=v{latest}"
                )
            # else: ver_str == latest → current self-ref, no warning needed

    if findings:
        print(f"WARN {filepath} {'; '.join(findings)}")
    else:
        print(f"PASS {filepath}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

while IFS= read -r line; do
  level="${line%% *}"
  rest="${line#* }"
  filepath="${rest%% *}"
  detail="${rest#* }"
  # Strip leading FACTORY_DIR for readability
  short="${filepath#"$FACTORY_DIR"/}"

  case "$level" in
    PASS)
      emit PASS "$short"
      ;;
    WARN)
      emit WARN "$short — $detail"
      ;;
    SKIP)
      emit WARN "$short (skipped: $detail)"
      ;;
    *)
      emit WARN "unexpected parser output: $line"
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-adr-self-version-refs: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo ""
echo "NOTE: This is advisory validator #5. All findings are WARN-only."
echo "      Exit code is always 0. Adversary should classify each WARN:"
echo "        stale-in-history-table  → low urgency (intentional historical doc)"
echo "        stale-in-prose          → medium urgency (de-label per TD-VSDD-091)"
echo "        unknown-version         → check context: may be cross-line false-positive"
echo "        current-self-ref        → no action needed (not emitted)"
echo "RESULT: ADVISORY (non-blocking)"
exit 0
