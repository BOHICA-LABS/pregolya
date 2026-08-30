#!/usr/bin/env bash
# verify-security-literal-propagation.sh — security-critical BC/ADR ↔ anchor-story literal propagation (ADVISORY)
#
# PURPOSE
# ───────
# Detects stale security literals in anchor implementation stories that were NOT
# updated after corrections landed in their source-of-truth BC/ADR files.
#
# ROOT CAUSE (F-P2A097-PG / F-P2A096-PG, round-22)
# ──────────────────────────────────────────────────
# verify-ac-pc-trace.sh verifies that AC CITATION IDs resolve to real items in
# the referenced BC — it does NOT verify that AC/Task BODY LITERALS mirror the
# current canonical form of the cited BC/ADR item.  When a security correction
# lands in BC-2.09.008/ADR-029 (e.g., UUID regex → version-agnostic form; panic
# mechanism → FutureExt::catch_unwind), the story AC bodies that cite those items
# are not swept by any existing gate.  This hook closes that gap.
#
# RULE TABLE
# ──────────
# Rules are data-driven (see Python block).  Adding a new security propagation
# check requires only a new dict entry in RULES — no structural changes.
#
# Current rule set (R01–R03: stories/stories/*.md; R04/R04-PREC: stories + BC + ADR corpus):
#   R01 — UUID v4-specific regex fragment (`-4[0-9a-f]{3}-[89ab]`) forbidden in any story body
#         Authority: BC-2.09.008 {INV-001} + ADR-029 §Decision 5 corrected in round-19
#         Stale form: `-4[0-9a-f]{3}-[89ab][0-9a-f]{3}` (v4-specific)
#         Canonical:  `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` (version-agnostic)
#         Scope: stale_re naturally confines hits to sanitizer-context stories
#
#   R02 — "UUID v4" wording in sanitizer context forbidden in any story body
#         Authority: BC-2.09.008 {INV-001} + ADR-029 §Decision 3 SEC-005
#         Stale form: "UUID v4 removal/pattern/values"
#         Canonical:  "version-agnostic UUID removal/pattern"
#         Scope: context_re (sanitiz|remov|pattern|...) confines hits to sanitizer stories
#
#   R03 — async-callee catch_unwind must use FutureExt::catch_unwind (CORPUS-WIDE)
#         Authority: BC-2.09.008 EC-010 + ADR-029 §Decision 5 SEC-008 (round-21 correction)
#         F-P2A109-01: synchronous std::panic::catch_unwind around an async fn (e.g.
#           GuardrailHook::evaluate, GraphRunner::run, DynTool::invoke_dyn) CANNOT catch
#           panics that occur during .await polling — only FutureExt::catch_unwind can.
#         Trigger: story contains `catch_unwind` AND an async callee
#           (GuardrailHook::evaluate, runner.run, invoke_dyn, etc.)
#         Required: story must ALSO name `FutureExt`
#         Canonical: `FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy)))`
#
#   R04 — SEC-008 panic = "unwind" obligation should appear in any artifact referencing SEC-008
#         Authority: BC-2.09.008 EC-010 v3.4 + BC-2.12.003 EC-003 + ADR-029 §Decision 5
#         Scope (EXTENDED round-45 R04-DETECTION-ENHANCEMENT): stories + BC corpus +
#                ADR corpus — any artifact that references SEC-008 must carry the
#                panic=unwind obligation note; related_re (\bSEC-008\b) confines hits;
#                anchor_glob now a list: stories/stories/*.md +
#                specs/behavioral-contracts/**/*.md + specs/architecture/**/*.md
#
#   R04-PREC — precision sub-check: SEC-008 artifact pins panic=unwind in a LIBRARY-MEMBER
#              release profile as the authoritative control WITHOUT workspace-root framing
#         Authority: BC-2.09.008 EC-010 v3.5 / ADR-029 §Decision 5 v2.16 / S-2.11 AC-037 v1.31
#         Defect class: "pregolya-<crate> release profile MUST pin panic=unwind" named as
#              the authoritative control — library-member [profile.release] overrides are
#              silently ignored by Cargo; authoritative pin is workspace-root [profile.release]
#         PASS form: workspace-root [profile.release] framing present (BC-2.09.008 EC-010 v3.5)
#         WARN form: library-member/binary pin claim present without workspace-root framing
#              (e.g. BC-2.11.002 {INV-005} pre-fix: "pregolya-graph release profile MUST pin")
#         WORD-ORDER EXTENSION (round-46 F-193-04): broadened to also match reverse word order
#              "MUST pin ... in the pregolya-<crate> release profile" (ADR-001 obligation 3 form)
#              — the original trigger only matched "pregolya-\w+ release profile MUST pin"
#
#   R05 — catch_unwind implies SEC-008 build-profile dependency note (round-46 F-193-04)
#         Authority: BC-2.09.008 EC-010 / ADR-029 §Decision 5 SEC-008 / BC-2.12.003 EC-003
#         Defect class: a BC/ADR/story that uses catch_unwind (std::panic::catch_unwind OR
#              FutureExt::catch_unwind) without citing the SEC-008 build-profile invariant
#              (`panic = "unwind"` workspace-root requirement) is structurally invisible to R04
#              because R04 gates on `\bSEC-008\b` as the related_re.
#         TRIGGER: any normative body mention of `catch_unwind`
#         REQUIRED: `\bSEC-008\b` somewhere in the same normative body
#         LIVE VIOLATIONS (round-46): BC-2.15.005 + BC-2.02.005 (std::panic::catch_unwind
#              without SEC-008 note — survived because they never wrote "SEC-008")
#         Scope: BC + ADR + story corpus (same anchor_glob as R04)
#
# EXCLUSIONS
# ──────────
# All checks exclude:
#   (A) YAML frontmatter (between opening and closing ---) — changelog historical records
#   (B) ## Changelog body sections — historical narrative
#   (C) Lines with negation/historical markers (INADEQUATE, corrected, STALE, REMOVED, etc.)
#       indicating the stale form is being described as a negative example
#   (D) .factory/hooks/** (POL-30 self-exclusion)
#
# SELF-PROBE (POL-31)
# ───────────────────
# Eleven self-probes run before the live check:
#   R01-pos: synthetic story body with v4-specific regex fragment → WARN reported
#   R01-neg: synthetic story body with version-agnostic regex → no WARN
#   R02-pos: synthetic story body with "UUID v4 removal" → WARN reported
#   R02-neg: synthetic story body with "version-agnostic UUID removal" → no WARN
#   R03-pos: synthetic story body with std::panic::catch_unwind + async callee (runner.run)
#            and no FutureExt → WARN (F-P2A109-01 async-panic defect class)
#   R03-neg: synthetic story body with FutureExt::catch_unwind + async callee → no WARN
#   R04-pos: synthetic BC body with SEC-008 ref + "pregolya-graph release profile MUST pin"
#            WITHOUT workspace-root framing → R04-PREC WARN (inert library-member pin)
#   R04-neg: synthetic BC body with SEC-008 ref + workspace-root framing + library-member
#            crate mentioned as "silently ignored" → no R04-PREC WARN (correctly structured)
#   R04-PREC-WO-pos: synthetic ADR body with REVERSE word order
#            "MUST pin ... in the pregolya-server release profile" + SEC-008 ref +
#            NO workspace-root framing → R04-PREC WARN (word-order extension, round-46)
#            Mirrors CURRENT ADR-001 obligation 3 text (F-193-01 live violation form)
#   R05-pos: synthetic BC body with catch_unwind but NO SEC-008 note → R05 WARN
#   R05-neg: synthetic BC body with catch_unwind AND SEC-008 note → no R05 WARN
#
# EXIT CONTRACT
# ─────────────
# Advisory: always exits 0.  WARN findings are printed but commit is not blocked.
# Exit 2: self-probe failure (script logic bug — false-green or false-red check).
#
# Promotion to blocking requires:
#   1. Human-authorized promotion decision
#   2. Moving to run_blocking in pre-commit-validators.sh
#   3. Incrementing EXPECTED_BLOCKING_COUNT
#   4. Changing exit $RC at end of script to "exit $WARN_COUNT"  (where 0 = clean)
#
# Usage:  bash .factory/hooks/verify-security-literal-propagation.sh
# Called: run_advisory in pre-commit-validators.sh (advisory until promoted)

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"

PASS=0
WARN=0
SELF_PROBE_FAIL=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
  esac
}

# ── Self-probe infrastructure ─────────────────────────────────────────────────
PROBE_TMP="$(mktemp -d)"
trap 'rm -rf "$PROBE_TMP"' EXIT

# probe_expect_warn <probe_id> <description> <warn_count>
# Asserts that running the check against PROBE_FILE produced WARN_COUNT > 0.
probe_expect_warn() {
  local probe_id="$1"
  local description="$2"
  local warn_count="$3"
  if [ "$warn_count" -eq 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — is false-green: '$description' was NOT detected."
    echo "  This is a script bug — the check would silently pass on a real stale violation."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — positive probe correctly detected stale form: $description"
  fi
}

# probe_expect_pass <probe_id> <description> <warn_count>
# Asserts that running the check against PROBE_FILE produced WARN_COUNT == 0.
probe_expect_pass() {
  local probe_id="$1"
  local description="$2"
  local warn_count="$3"
  if [ "$warn_count" -gt 0 ]; then
    echo "[SELF-PROBE FAIL] $probe_id — false-positive: '$description' fired but should NOT have."
    echo "  This is a script bug — the check would incorrectly flag a canonical form."
    SELF_PROBE_FAIL=$((SELF_PROBE_FAIL + 1))
  else
    echo "[SELF-PROBE PASS] $probe_id — negative probe correctly passed on canonical form: $description"
  fi
}

# ── Core Python checker ───────────────────────────────────────────────────────
# Arguments: <factory_dir> <probe_file_or_empty>
# When probe_file is non-empty, it overrides the live story glob (for self-probes).
# Output lines:
#   WARN R<N> <file> — stale form detected
#   PASS R<N> — all anchor files checked and no stale form found
#   SKIP R<N> — no anchor files found matching glob (likely pre-story-decomposition)
run_rule_check() {
  local factory_dir="$1"
  local probe_override="${2:-}"  # optional: path to synthetic probe file
  python3 - "$factory_dir" "$probe_override" <<'PYEOF'
import sys, re, glob
from pathlib import Path

factory_dir    = Path(sys.argv[1])
probe_override = sys.argv[2] if len(sys.argv) > 2 else ""

# ── Rule table ────────────────────────────────────────────────────────────────
# Each rule is a dict describing a security-literal propagation check.
# check_type values:
#   "presence_forbidden"   — stale_re must NOT appear in story body (outside exclusions)
#   "requires_coexistence" — if trigger_re appears in body, required_re must also appear
#   "absence_when_related" — if related_re appears in body, required_re should also appear
#                            (softer advisory: emits WARN but is framed as an obligation note)
RULES = [
    {
        "id": "R01",
        "check_type": "presence_forbidden",
        "description": "UUID v4-specific regex fragment in story body",
        "authority": "BC-2.09.008 {INV-001} / ADR-029 §Decision 5 (round-19 correction)",
        "anchor_glob": "stories/stories/*.md",
        # The stale form is the v4-specific UUID regex PATTERN written as text in
        # the document, e.g.:
        #   `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}`
        # The characteristic v4 fragment is `-4[0-9a-f]{3}-[89ab]` where `[`, `]`,
        # `{`, `}` are literal characters. The regex must escape these to match
        # the literal text (not interpret them as regex metacharacters).
        "stale_re": re.compile(r"-4\[0-9a-f\]\{3\}-\[89ab\]", re.IGNORECASE),
        "negation_re": re.compile(
            r"INADEQUATE|inadequate|corrected|STALE|REMOVED|RETIRED"
            r"|NOT.*regex|regex.*NOT|cannot|ADR-029.*Decision|round-19|round-21"
            r"|version-agnostic",
            re.IGNORECASE
        ),
        "canonical_hint": (
            "use version-agnostic UUID regex "
            "`[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`"
        ),
        "sec_ref": "SEC-005 / CWE-209",
    },
    {
        "id": "R02",
        "check_type": "presence_forbidden",
        "description": "'UUID v4' wording in sanitizer context in story body",
        "authority": "BC-2.09.008 {INV-001} / ADR-029 §Decision 3 SEC-005 (round-19 correction)",
        "anchor_glob": "stories/stories/*.md",
        "stale_re": re.compile(r"\bUUID v4\b", re.IGNORECASE),
        "context_re": re.compile(
            r"sanitiz|remov|pattern|strip|prevent|block|regex|uuid.*format",
            re.IGNORECASE
        ),
        "negation_re": re.compile(
            r"INADEQUATE|inadequate|NOT.*UUID v4|UUID v4.*NOT"
            r"|excluded|outside.*scope|corrected|version-agnostic|round-19",
            re.IGNORECASE
        ),
        "canonical_hint": (
            "replace 'UUID v4 removal/pattern/values' with "
            "'version-agnostic UUID removal/pattern'"
        ),
        "sec_ref": "SEC-005 / CWE-209",
    },
    {
        "id": "R03",
        "check_type": "requires_coexistence",
        "description": (
            "story uses catch_unwind around async callee without FutureExt::catch_unwind "
            "(F-P2A109-01: sync catch_unwind cannot span async .await boundary)"
        ),
        "authority": (
            "BC-2.09.008 EC-010 / ADR-029 §Decision 5 SEC-008 (round-21 correction): "
            "synchronous std::panic::catch_unwind cannot catch panics during .await polling; "
            "FutureExt::catch_unwind(AssertUnwindSafe(runner.run(...))) is the sole correct form"
        ),
        "anchor_glob": "stories/stories/*.md",
        # Trigger: any mention of catch_unwind (both std::panic and FutureExt forms contain it)
        "trigger_re": re.compile(r"\bcatch_unwind\b"),
        # Context gate: rule only applies when the story also mentions an async callee whose
        # interface-definitions/BC signature is `async fn` — e.g. GuardrailHook::evaluate,
        # GraphRunner::run, DynTool::invoke_dyn. Without an async callee in scope, sync
        # catch_unwind is harmless.
        "trigger_context_re": re.compile(
            r"GuardrailHook::evaluate"
            r"|GraphRunner::run"
            r"|DynTool::invoke_dyn"
            r"|\brunner\.run\b"
            r"|\binvoke_dyn\b",
        ),
        "required_re": re.compile(r"FutureExt"),
        "negation_re": re.compile(
            r"INADEQUATE|inadequate|corrected|STALE|REMOVED|cannot|round-21",
            re.IGNORECASE
        ),
        "canonical_hint": (
            "use `FutureExt::catch_unwind(AssertUnwindSafe(async_callee(...)))` "
            "instead of synchronous `std::panic::catch_unwind`; "
            "the async form wraps the Future so panics during .await are caught"
        ),
        "sec_ref": "SEC-008 / CWE-248 / CWE-703",
    },
    {
        "id": "R04",
        "check_type": "absence_when_related",
        "description": "artifact references SEC-008 but lacks `panic = \"unwind\"` obligation note",
        "authority": (
            "BC-2.09.008 EC-010 v3.4 / BC-2.12.003 EC-003 / ADR-029 §Decision 5: "
            "panic = \"unwind\" obligation covers BOTH pregolya-mcp AND pregolya-server; "
            "authoritative pin is workspace-root [profile.release] governing the "
            "pregolya-server binary (library crate profile overrides are ignored by Cargo); "
            "`panic = \"abort\"` at workspace root voids FutureExt::catch_unwind recovery (CWE-248)"
        ),
        # EXTENDED round-45 R04-DETECTION-ENHANCEMENT: scan stories + BC corpus + ADR corpus
        "anchor_glob": [
            "stories/stories/*.md",
            "specs/behavioral-contracts/**/*.md",
            "specs/architecture/**/*.md",
        ],
        "related_re": re.compile(r"\bSEC-008\b"),
        "required_re": re.compile(r'panic\s*=\s*["\']unwind["\']|panic.*=.*unwind|panic-profile'),
        "canonical_hint": (
            "add a reference to the SEC-008 build-profile obligation: "
            "`panic = \"unwind\"` in workspace-root [profile.release] (governs "
            "pregolya-server binary) per BC-2.09.008 EC-010 v3.4 + BC-2.12.003 EC-003; "
            "library-member profile overrides are silently ignored by Cargo — "
            "do NOT pin pregolya-mcp release profile; "
            "pregolya-mcp obligation is the S-2.11 AC-037 source comment only "
            "(devops-engineer asserts at Phase 3 workspace authoring)"
        ),
        "sec_ref": "SEC-008 / CWE-248",
    },
    {
        # R04-PREC — precision sub-check: library-member profile pin as authoritative control
        # Defect class detected: F-P2A189-01 (SS-11 BC-2.11.002 {INV-005} inert-pin form)
        # Three consecutive HIGH SEC-008 slippage findings (R43–R45) caused by this gap.
        "id": "R04-PREC",
        "check_type": "library_member_pin_without_workspace",
        "description": (
            "SEC-008-referencing artifact pins panic=unwind in a LIBRARY-MEMBER release profile "
            "as the authoritative control, without workspace-root framing "
            "(library-member [profile.release] overrides are silently ignored by Cargo — CWE-248)"
        ),
        "authority": (
            "BC-2.09.008 EC-010 v3.5 / ADR-029 §Decision 5 v2.16 / S-2.11 AC-037 v1.31: "
            "authoritative pin is workspace-root [profile.release] (governs pregolya-server binary "
            "at link time); library-member [profile.release] panic override silently ignored by Cargo"
        ),
        "anchor_glob": [
            "stories/stories/*.md",
            "specs/behavioral-contracts/**/*.md",
            "specs/architecture/**/*.md",
        ],
        # Presence of SEC-008 is required for this rule to apply
        "related_re": re.compile(r"\bSEC-008\b"),
        # Matches inert library-member/binary pin claim in EITHER word order:
        #   (1) "pregolya-<crate> release profile MUST pin"  — original order
        #       (crate name may not have surrounding backticks in this position)
        #   (2) "MUST pin ... in the `pregolya-<crate>` release profile" — reverse order
        #       e.g. ADR-001 obligation 3: "MUST pin `panic = \"unwind\"` in the
        #       `pregolya-server` release profile" (word-order extension, round-46 F-193-04)
        #       [^\s]* after crate name allows for closing backtick before the space
        "trigger_re": re.compile(
            r"pregolya-\w+\s+release\s+profile\s+MUST\s+pin"
            r"|MUST\s+pin\b[^.]*\bpregolya-\w+[^\s]*\s+release\s+profile",
            re.IGNORECASE
        ),
        # Workspace-root framing confirms the doc is correctly structured — rule does not fire
        "workspace_re": re.compile(
            r"workspace[-\s]root.*\[profile|workspace[-\s]root.*profile.*release"
            r"|library[-\s]member.*ignored\s+by\s+Cargo"
            r"|MUST\s+NOT\s+be\s+relied\s+upon",
            re.IGNORECASE
        ),
        # Negation: skip trigger lines that are describing the stale form as a correction
        "negation_re": re.compile(
            r"OLD:|prior\s+form|INADEQUATE|corrected|STALE|REMOVED|RETIRED"
            r"|round-\d+\s+correction|was\s+incorrect",
            re.IGNORECASE
        ),
        "canonical_hint": (
            "the authoritative panic=unwind pin is the workspace-root [profile.release] "
            "governing the pregolya-server binary at link time; "
            "library-member [profile.release] panic overrides (e.g. pregolya-graph, pregolya-mcp) "
            "are silently ignored by Cargo and MUST NOT be relied upon; "
            "canonical form: BC-2.09.008 EC-010 v3.5 / ADR-029 §Decision 5 v2.16 / S-2.11 AC-037 v1.31"
        ),
        "sec_ref": "SEC-008 / CWE-248",
    },
    {
        # R05 — catch_unwind implies SEC-008 build-profile dependency note
        # Defect class: BC/ADR/story uses catch_unwind without citing the SEC-008 invariant.
        # R04 gates on `\bSEC-008\b` as the related_re; a file that never writes "SEC-008"
        # is structurally invisible to R04 even if it mandates catch_unwind behavior.
        # LIVE VIOLATIONS (round-46): BC-2.15.005 + BC-2.02.005 (std::panic::catch_unwind
        # without SEC-008 note — survived R45/R46 because neither file wrote "SEC-008").
        "id": "R05",
        "check_type": "requires_coexistence",
        "description": (
            "artifact uses catch_unwind without SEC-008 build-profile dependency note "
            "(catch_unwind requires panic=unwind in workspace-root [profile.release]; "
            "SEC-008 / CWE-248)"
        ),
        "authority": (
            "BC-2.09.008 EC-010 / ADR-029 §Decision 5 SEC-008 / BC-2.12.003 EC-003: "
            "catch_unwind (both std::panic and FutureExt forms) requires panic = \"unwind\" "
            "in workspace-root [profile.release]; panic = \"abort\" voids recovery (CWE-248)"
        ),
        # EXTENDED round-45 R04-DETECTION-ENHANCEMENT scope: stories + BC + ADR corpus
        "anchor_glob": [
            "stories/stories/*.md",
            "specs/behavioral-contracts/**/*.md",
            "specs/architecture/**/*.md",
        ],
        # Trigger: any catch_unwind mention (both std::panic::catch_unwind and
        # FutureExt::catch_unwind — both forms share the "catch_unwind" substring)
        "trigger_re": re.compile(r"\bcatch_unwind\b"),
        # Required: explicit SEC-008 build-profile reference somewhere in normative body
        "required_re": re.compile(r"\bSEC-008\b"),
        # Negation: trigger lines that describe catch_unwind as incorrect/historical
        "negation_re": re.compile(
            r"INADEQUATE|inadequate|corrected|STALE|REMOVED|RETIRED"
            r"|round-\d+\s+correction|was\s+incorrect|cannot\s+catch",
            re.IGNORECASE
        ),
        "canonical_hint": (
            "add a reference to the SEC-008 build-profile obligation: "
            "`panic = \"unwind\"` in workspace-root [profile.release] (governs "
            "pregolya-server binary at link time) per BC-2.09.008 EC-010 + "
            "BC-2.12.003 EC-003; `panic = \"abort\"` voids catch_unwind recovery (CWE-248)"
        ),
        "sec_ref": "SEC-008 / CWE-248",
    },
]

# ── Region utilities (mirrors spec_region_utils.py changelog_exempt_lines) ──
def frontmatter_end_line(lines):
    """Return the line index (0-based) of the closing '---' delimiter, or -1."""
    if not lines or lines[0].strip() != '---':
        return -1
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            return i
    return -1

def changelog_exempt_line_set(lines):
    """Return set of 0-based line indices that are inside changelog regions."""
    exempt = set()
    fm_end = frontmatter_end_line(lines)
    # (A) Entire frontmatter block
    if fm_end >= 0:
        for i in range(fm_end + 1):
            exempt.add(i)
    # (B) ## Changelog body sections
    in_changelog = False
    for i, line in enumerate(lines):
        if i <= fm_end:
            continue
        stripped = line.strip()
        if stripped.startswith('## Changelog'):
            in_changelog = True
            exempt.add(i)
        elif in_changelog and stripped.startswith('## '):
            in_changelog = False
        if in_changelog:
            exempt.add(i)
    return exempt

# ── Check runner ─────────────────────────────────────────────────────────────
def find_anchor_files(factory_dir, anchor_glob, probe_override):
    if probe_override:
        p = Path(probe_override)
        return [p] if p.exists() else []
    # anchor_glob may be a string (single pattern) or a list of patterns
    globs = [anchor_glob] if isinstance(anchor_glob, str) else anchor_glob
    files = []
    for g in globs:
        pattern = str(factory_dir / g)
        files.extend(Path(f) for f in glob.glob(pattern, recursive=True))
    # Deduplicate preserving order
    seen = set()
    unique = []
    for f in files:
        if f not in seen:
            seen.add(f)
            unique.append(f)
    return unique

def get_normative_lines(path):
    """Return list of (line_index, line_text) for normative (non-exempt) lines."""
    try:
        content = path.read_text(encoding='utf-8', errors='replace')
    except Exception as e:
        return [], f"PARSE_ERROR reading {path}: {e}"
    lines = content.splitlines()
    exempt = changelog_exempt_line_set(lines)
    return [(i, lines[i]) for i in range(len(lines)) if i not in exempt], None

def run_rule(rule, factory_dir, probe_override):
    anchor_files = find_anchor_files(factory_dir, rule["anchor_glob"], probe_override)
    if not anchor_files:
        return [("SKIP", rule["id"], None, "no anchor files found matching glob")]

    results = []
    check_type = rule["check_type"]

    for path in anchor_files:
        normative_lines, err = get_normative_lines(path)
        if err:
            results.append(("WARN", rule["id"], str(path), err))
            continue

        try:
            rel = str(path.relative_to(factory_dir))
        except ValueError:
            rel = path.name  # probe file outside factory_dir (self-probe synthetic fixture)

        if check_type == "presence_forbidden":
            stale_re    = rule["stale_re"]
            negation_re = rule.get("negation_re")
            context_re  = rule.get("context_re")

            for lineno, line in normative_lines:
                if not stale_re.search(line):
                    continue
                # Check context requirement (for R02 compound check)
                if context_re and not context_re.search(line):
                    continue
                # Apply negation exclusion
                if negation_re and negation_re.search(line):
                    continue
                results.append((
                    "WARN", rule["id"], rel,
                    f"stale form on body line {lineno+1}: {line.strip()[:100]}"
                ))

        elif check_type == "requires_coexistence":
            trigger_re         = rule["trigger_re"]
            required_re        = rule["required_re"]
            negation_re        = rule.get("negation_re")
            trigger_context_re = rule.get("trigger_context_re")

            # Collect trigger lines (excluding negation)
            trigger_lines = []
            for lineno, line in normative_lines:
                if trigger_re.search(line):
                    if negation_re and negation_re.search(line):
                        continue
                    trigger_lines.append((lineno, line))

            if not trigger_lines:
                # No trigger → rule is satisfied (no obligation to have required_re)
                continue

            # Context gate: if trigger_context_re is specified, the rule only applies
            # when the full normative body ALSO matches the context pattern.
            # This scopes the rule to its intended context (e.g. async callee present).
            all_text = "\n".join(l for _, l in normative_lines)
            if trigger_context_re and not trigger_context_re.search(all_text):
                # Trigger fired but context not present → rule does not apply to this file
                continue

            # Check if required_re appears ANYWHERE in normative body
            if not required_re.search(all_text):
                # Trigger present, required absent → WARN
                first_lineno, first_line = trigger_lines[0]
                results.append((
                    "WARN", rule["id"], rel,
                    f"story body has '{trigger_re.pattern}' (body line {first_lineno+1}) "
                    f"but lacks required '{required_re.pattern}'; "
                    f"stale line: {first_line.strip()[:80]}"
                ))

        elif check_type == "absence_when_related":
            related_re  = rule["related_re"]
            required_re = rule["required_re"]

            all_text = "\n".join(l for _, l in normative_lines)
            if related_re.search(all_text) and not required_re.search(all_text):
                results.append((
                    "WARN", rule["id"], rel,
                    f"artifact references '{related_re.pattern}' but lacks "
                    f"'{required_re.pattern}' obligation reference"
                ))

        elif check_type == "library_member_pin_without_workspace":
            # Fires when:
            #   (a) artifact references SEC-008 (related_re), AND
            #   (b) a library-member release-profile pin claim is present (trigger_re), AND
            #   (c) workspace-root framing is ABSENT (workspace_re does not match)
            # The canonical PASS form per BC-2.09.008 EC-010 v3.5 has workspace-root framing;
            # the WARN form is an inert library-member pin named as the authoritative control.
            related_re   = rule["related_re"]
            trigger_re   = rule["trigger_re"]
            workspace_re = rule["workspace_re"]
            negation_re  = rule.get("negation_re")

            all_text = "\n".join(l for _, l in normative_lines)

            # Rule only applies when SEC-008 is referenced in this artifact
            if not related_re.search(all_text):
                continue

            # Find library-member pin lines; skip lines that describe the stale form negatively
            lib_pin_lines = []
            for lineno, line in normative_lines:
                if trigger_re.search(line):
                    if negation_re and negation_re.search(line):
                        continue
                    lib_pin_lines.append((lineno, line))

            if not lib_pin_lines:
                # No library-member pin language — rule is satisfied for this file
                continue

            # Library-member pin present; check for workspace-root framing anywhere in body
            if workspace_re.search(all_text):
                # Workspace-root framing present alongside library-member mention — correctly
                # structured (e.g. "library-member ... ignored by Cargo; workspace-root pin
                # is the authoritative control")
                continue

            # Library-member pin present, workspace-root framing absent → WARN
            first_lineno, first_line = lib_pin_lines[0]
            results.append((
                "WARN", rule["id"], rel,
                f"SEC-008 referenced; library-member profile pin on body line {first_lineno+1} "
                f"without workspace-root framing (inert pin defect class, CWE-248): "
                f"{first_line.strip()[:100]}"
            ))

    if not results:
        results.append(("PASS", rule["id"], None, "no stale forms detected"))

    return results

# ── Main ──────────────────────────────────────────────────────────────────────
total_warn = 0
total_pass = 0
total_skip = 0

for rule in RULES:
    results = run_rule(rule, factory_dir, probe_override)
    for level, rule_id, rel, msg in results:
        if rel:
            print(f"[{level}] {rule_id} ({rule['authority'][:60]}…): {rel} — {msg}")
        else:
            print(f"[{level}] {rule_id}: {msg}")
        if level == "WARN":
            total_warn += 1
        elif level == "PASS":
            total_pass += 1
        elif level == "SKIP":
            total_skip += 1

sys.exit(total_warn)
PYEOF
}

# ── Self-probes ───────────────────────────────────────────────────────────────
echo ""
echo "── verify-security-literal-propagation: running self-probes ──────────────"

# R01-pos: story body with v4-specific UUID regex fragment → WARN expected
PROBE_R01_POS="$PROBE_TMP/probe-r01-pos.md"
cat > "$PROBE_R01_POS" <<'STALE_EOF'
---
document_type: story
story_id: S-9.99
version: "1.0"
---
# S-9.99 Synthetic Probe

## AC-099 — UUID sanitization
Implement `sanitize_internal_ids(text: &str) -> Cow<str>` — UUID v4 pattern removal
(`[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}`, case-insensitive).
STALE_EOF

PROBE_R01_POS_WARNS=0
run_rule_check "$FACTORY_DIR" "$PROBE_R01_POS" | while IFS= read -r line; do
  case "$line" in [WARN]*) echo $((PROBE_R01_POS_WARNS+1)) ;; esac
done > /dev/null || true
# Count directly
PROBE_R01_POS_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R01_POS" 2>/dev/null || true)"
PROBE_R01_POS_WARNS="$(echo "$PROBE_R01_POS_OUT" | grep -c '^\[WARN\] R01' || true)"
probe_expect_warn "R01-pos" "v4-specific UUID regex fragment '-4[0-9a-f]{3}-[89ab]' in body" "$PROBE_R01_POS_WARNS"

# R01-neg: story body with version-agnostic UUID regex → no WARN expected
PROBE_R01_NEG="$PROBE_TMP/probe-r01-neg.md"
cat > "$PROBE_R01_NEG" <<'CANONICAL_EOF'
---
document_type: story
story_id: S-9.99
version: "1.0"
---
# S-9.99 Synthetic Probe

## AC-099 — UUID sanitization
Implement `sanitize_internal_ids(text: &str) -> Cow<str>` — version-agnostic UUID removal
(`[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`, case-insensitive).
CANONICAL_EOF

PROBE_R01_NEG_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R01_NEG" 2>/dev/null || true)"
PROBE_R01_NEG_WARNS="$(echo "$PROBE_R01_NEG_OUT" | grep -c '^\[WARN\] R01' || true)"
probe_expect_pass "R01-neg" "version-agnostic UUID regex passes without warning" "$PROBE_R01_NEG_WARNS"

# R02-pos: story body with "UUID v4 removal" in sanitizer context → WARN expected
PROBE_R02_POS="$PROBE_TMP/probe-r02-pos.md"
cat > "$PROBE_R02_POS" <<'STALE_EOF'
---
document_type: story
story_id: S-9.99
version: "1.0"
---
# S-9.99 Synthetic Probe

## AC-099 — UUID sanitization
`sanitize_internal_ids` — UUID v4 removal chained after `redact_credentials` on `isError: true` paths.
STALE_EOF

PROBE_R02_POS_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R02_POS" 2>/dev/null || true)"
PROBE_R02_POS_WARNS="$(echo "$PROBE_R02_POS_OUT" | grep -c '^\[WARN\] R02' || true)"
probe_expect_warn "R02-pos" "'UUID v4 removal' in sanitizer-context body line" "$PROBE_R02_POS_WARNS"

# R02-neg: story body with "version-agnostic UUID removal" → no WARN expected
PROBE_R02_NEG="$PROBE_TMP/probe-r02-neg.md"
cat > "$PROBE_R02_NEG" <<'CANONICAL_EOF'
---
document_type: story
story_id: S-9.99
version: "1.0"
---
# S-9.99 Synthetic Probe

## AC-099 — UUID sanitization
`sanitize_internal_ids` — version-agnostic UUID removal chained after `redact_credentials` on `isError: true` paths.
CANONICAL_EOF

PROBE_R02_NEG_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R02_NEG" 2>/dev/null || true)"
PROBE_R02_NEG_WARNS="$(echo "$PROBE_R02_NEG_OUT" | grep -c '^\[WARN\] R02' || true)"
probe_expect_pass "R02-neg" "'version-agnostic UUID removal' passes without warning" "$PROBE_R02_NEG_WARNS"

# R03-pos: story body with std::panic::catch_unwind + async callee (runner.run) and no FutureExt
# Represents the F-P2A109-01 defect class: sync catch_unwind around an async callee
PROBE_R03_POS="$PROBE_TMP/probe-r03-pos.md"
cat > "$PROBE_R03_POS" <<'STALE_EOF'
---
document_type: story
story_id: S-9.99
version: "1.0"
---
# S-9.99 Synthetic Probe

## Task-37
Implement panic protection for `GraphAgentTool::invoke_dyn`: use
`std::panic::catch_unwind(|| runner.run(input, policy))` to catch panics
during execution and return static `isError: true` response with
`content[0].text == "internal error"`. The `UnwindSafe` boundary ensures
the captured variables satisfy the `UnwindSafe` marker trait.
STALE_EOF

PROBE_R03_POS_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R03_POS" 2>/dev/null || true)"
PROBE_R03_POS_WARNS="$(echo "$PROBE_R03_POS_OUT" | grep -c '^\[WARN\] R03' || true)"
probe_expect_warn "R03-pos" "sync catch_unwind + async callee (runner.run) without FutureExt" "$PROBE_R03_POS_WARNS"

# R03-neg: story body with "FutureExt::catch_unwind" → no WARN expected
PROBE_R03_NEG="$PROBE_TMP/probe-r03-neg.md"
cat > "$PROBE_R03_NEG" <<'CANONICAL_EOF'
---
document_type: story
story_id: S-9.99
version: "1.0"
---
# S-9.99 Synthetic Probe

## Task-37
Implement `FutureExt::catch_unwind(AssertUnwindSafe(runner.run(input, policy)))` inside
`GraphAgentTool::invoke_dyn` — `UnwindSafe` wraps the async future so a panic during `.await`
polling is caught as `Err(panic_value)`; mapped to static `isError: true` response.
CANONICAL_EOF

PROBE_R03_NEG_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R03_NEG" 2>/dev/null || true)"
PROBE_R03_NEG_WARNS="$(echo "$PROBE_R03_NEG_OUT" | grep -c '^\[WARN\] R03' || true)"
probe_expect_pass "R03-neg" "'FutureExt::catch_unwind' present — R03 passes" "$PROBE_R03_NEG_WARNS"

# R04-pos: BC body with SEC-008 ref + "pregolya-graph release profile MUST pin" WITHOUT
# workspace-root framing → R04-PREC WARN expected (inert library-member pin defect class;
# mirrors BC-2.11.002 {INV-005} pre-fix form that caused F-P2A189-01)
PROBE_R04_POS="$PROBE_TMP/probe-r04-pos.md"
cat > "$PROBE_R04_POS" <<'STALE_EOF'
---
document_type: behavioral_contract
bc_id: BC-9.99
version: "1.0"
---
# BC-9.99 Synthetic Probe

## {INV-005} Async panic recovery at ingress boundary (SEC-008)
`GuardrailHook::evaluate` is an async method; panic recovery MUST use
`FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag))).await`.
Recovery requires `panic = "unwind"` in the release profile; `panic = "abort"` voids
the catch and causes process termination on any hook panic (CWE-248).
The pregolya-graph release profile MUST pin `panic = "unwind"` —
devops asserts this at Phase-3 workspace `Cargo.toml` authoring.
STALE_EOF

PROBE_R04_POS_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R04_POS" 2>/dev/null || true)"
PROBE_R04_POS_WARNS="$(echo "$PROBE_R04_POS_OUT" | grep -c '^\[WARN\] R04-PREC' || true)"
probe_expect_warn "R04-pos" "library-member pin (pregolya-graph release profile MUST pin) without workspace-root framing" "$PROBE_R04_POS_WARNS"

# R04-neg: BC body with SEC-008 ref + workspace-root framing + library-member crate
# mentioned as "silently ignored by Cargo" → no R04-PREC WARN expected (canonical form)
PROBE_R04_NEG="$PROBE_TMP/probe-r04-neg.md"
cat > "$PROBE_R04_NEG" <<'CANONICAL_EOF'
---
document_type: behavioral_contract
bc_id: BC-9.99
version: "1.0"
---
# BC-9.99 Synthetic Probe

## {INV-005} Async panic recovery at ingress boundary (SEC-008)
SEC-008 build-profile invariant: recovery via `FutureExt::catch_unwind` requires
`panic = "unwind"`. The AUTHORITATIVE pin is the workspace-root `[profile.release]`
governing the `pregolya-server` binary (applied at link time); the pregolya-graph
release profile MUST pin `panic = "unwind"` only through the workspace-root
`[profile.release]` that governs it — a library-member `[profile.release]` override
is silently ignored by Cargo and MUST NOT be relied upon for this guarantee.
`panic = "abort"` at the workspace root voids the catch (CWE-248).
CANONICAL_EOF

PROBE_R04_NEG_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R04_NEG" 2>/dev/null || true)"
PROBE_R04_NEG_WARNS="$(echo "$PROBE_R04_NEG_OUT" | grep -c '^\[WARN\] R04-PREC' || true)"
probe_expect_pass "R04-neg" "workspace-root framing present — R04-PREC passes" "$PROBE_R04_NEG_WARNS"

# R04-PREC-WO-pos: ADR body with REVERSE word order "MUST pin ... in the pregolya-server
# release profile" + SEC-008 ref + NO workspace-root framing → R04-PREC WARN expected.
# Mirrors the CURRENT ADR-001 obligation 3 text (F-193-01 live violation before architect fix).
PROBE_R04_PREC_WO_POS="$PROBE_TMP/probe-r04-prec-wo-pos.md"
cat > "$PROBE_R04_PREC_WO_POS" <<'STALE_EOF'
---
document_type: architecture_decision_record
adr_id: ADR-9.99
version: "1.0"
---
# ADR-9.99 Synthetic Probe

## §Graph Run-Executor Panic Boundary

**Obligations:**

3. **SEC-008 scope extension:** devops-engineer MUST pin `panic = "unwind"` in the `pregolya-server` release profile at Phase 3; `panic = "abort"` voids `catch_unwind` recovery (CWE-248/703 remote DoS).
STALE_EOF

PROBE_R04_PREC_WO_POS_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R04_PREC_WO_POS" 2>/dev/null || true)"
PROBE_R04_PREC_WO_POS_WARNS="$(echo "$PROBE_R04_PREC_WO_POS_OUT" | grep -c '^\[WARN\] R04-PREC' || true)"
probe_expect_warn "R04-PREC-WO-pos" \
  "reverse word order 'MUST pin ... in the pregolya-server release profile' (ADR-001 obligation 3 form)" \
  "$PROBE_R04_PREC_WO_POS_WARNS"

# R05-pos: BC body with catch_unwind but NO SEC-008 note → R05 WARN expected.
# Mirrors the live defect class in BC-2.15.005 + BC-2.02.005 (round-46 survivors).
PROBE_R05_POS="$PROBE_TMP/probe-r05-pos.md"
cat > "$PROBE_R05_POS" <<'STALE_EOF'
---
document_type: behavioral_contract
bc_id: BC-9.99
version: "1.0"
---
# BC-9.99 Synthetic Probe

## {INV-TEST} Panic recovery at write-guard boundary

**Expected behavior:** `memory::write_guard` catches the panic (via `std::panic::catch_unwind`
on the closure body) and returns an error response instead of crashing the thread.
Recovery wraps the execution to ensure the process continues even when individual
write operations panic unexpectedly.
STALE_EOF

PROBE_R05_POS_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R05_POS" 2>/dev/null || true)"
PROBE_R05_POS_WARNS="$(echo "$PROBE_R05_POS_OUT" | grep -c '^\[WARN\] R05' || true)"
probe_expect_warn "R05-pos" "catch_unwind without SEC-008 note → R05 WARN" "$PROBE_R05_POS_WARNS"

# R05-neg: BC body with catch_unwind AND SEC-008 note → no R05 WARN expected.
PROBE_R05_NEG="$PROBE_TMP/probe-r05-neg.md"
cat > "$PROBE_R05_NEG" <<'CANONICAL_EOF'
---
document_type: behavioral_contract
bc_id: BC-9.99
version: "1.0"
---
# BC-9.99 Synthetic Probe

## {INV-TEST} Panic recovery at write-guard boundary

**Expected behavior:** `memory::write_guard` catches the panic (via `std::panic::catch_unwind`
on the closure body) and returns an error response. This recovery requires `panic = "unwind"`
in the workspace-root `[profile.release]` per the SEC-008 build-profile invariant
(BC-2.09.008 EC-010); `panic = "abort"` voids `catch_unwind` recovery (CWE-248).
CANONICAL_EOF

PROBE_R05_NEG_OUT="$(run_rule_check "$FACTORY_DIR" "$PROBE_R05_NEG" 2>/dev/null || true)"
PROBE_R05_NEG_WARNS="$(echo "$PROBE_R05_NEG_OUT" | grep -c '^\[WARN\] R05' || true)"
probe_expect_pass "R05-neg" "catch_unwind WITH SEC-008 note — R05 passes" "$PROBE_R05_NEG_WARNS"

# ── Self-probe gate ───────────────────────────────────────────────────────────
if [ "$SELF_PROBE_FAIL" -gt 0 ]; then
  echo ""
  echo "[SELF-PROBE FAIL] $SELF_PROBE_FAIL self-probe(s) failed — this is a script bug."
  echo "  A failing self-probe means a check is false-green or false-red on synthetic fixtures."
  echo "  Fix the script logic before using this gate for advisory checks."
  exit 2
fi

echo "[SELF-PROBE PASS] All 11 self-probes passed — checks are not false-green on synthetic fixtures."

# ── Live check ────────────────────────────────────────────────────────────────
echo ""
echo "── verify-security-literal-propagation: running live checks ───────────────"

LIVE_OUTPUT="$(run_rule_check "$FACTORY_DIR" "" 2>/dev/null || true)"
echo "$LIVE_OUTPUT"

LIVE_WARNS="$(echo "$LIVE_OUTPUT" | grep -c '^\[WARN\]' || true)"
LIVE_PASSES="$(echo "$LIVE_OUTPUT" | grep -c '^\[PASS\]' || true)"
LIVE_SKIPS="$(echo "$LIVE_OUTPUT" | grep -c '^\[SKIP\]' || true)"

echo ""
echo "── Security-literal propagation summary ──────────────────────────────────"
echo "   WARN: $LIVE_WARNS  PASS: $LIVE_PASSES  SKIP: $LIVE_SKIPS"

if [ "$LIVE_WARNS" -gt 0 ]; then
  echo ""
  echo "[ADVISORY] $LIVE_WARNS stale security literal(s) detected in anchor stories."
  echo "  These are advisory findings — commit is not blocked."
  echo "  Route to story-writer for body-literal sweep of anchor stories."
  echo "  Root cause: verify-ac-pc-trace.sh checks citation ID existence only;"
  echo "  it does NOT verify that AC/Task body literals mirror current BC/ADR canonical forms."
  echo ""
  echo "  Remediation per rule:"
  echo "    R01: replace v4-specific fragment with version-agnostic UUID regex"
  echo "    R02: replace 'UUID v4 removal/pattern' with 'version-agnostic UUID removal/pattern'"
  echo "    R03: add FutureExt::catch_unwind(AssertUnwindSafe(...)) as explicit mechanism"
  echo "    R04: add panic = \"unwind\" in workspace-root [profile.release] (governs pregolya-server)"
  echo "         per BC-2.09.008 EC-010 v3.4 + BC-2.12.003 EC-003; library-member profile"
  echo "         overrides are silently ignored by Cargo — do NOT pin pregolya-mcp release profile;"
  echo "         pregolya-mcp obligation is the S-2.11 AC-037 source comment only"
  echo "    R04-PREC (WO): same as R04-PREC but triggered by reverse word order"
  echo "         'MUST pin ... in the pregolya-<crate> release profile' — add workspace-root"
  echo "         framing to the obligation note (ADR-001 obligation 3 canonical fix)"
  echo "    R05: add SEC-008 build-profile obligation alongside any catch_unwind mention;"
  echo "         canonical: 'requires panic = \"unwind\" in workspace-root [profile.release]"
  echo "         per SEC-008 / BC-2.09.008 EC-010; panic = \"abort\" voids catch_unwind (CWE-248)'"
fi

# Advisory gate: always exits 0 (commit not blocked by WARN findings)
exit 0
