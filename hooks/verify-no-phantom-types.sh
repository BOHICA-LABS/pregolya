#!/usr/bin/env bash
# verify-no-phantom-types.sh — GAP-01 phantom-type corpus grep gate (ADVISORY)
#
# PURPOSE
# ───────
# Enforces that sibling-sweeps for retired/phantom Rust type symbols use a
# CORPUS GREP over the entire .factory/ spec/story/holdout tree — not an
# enumerated file list.  Round-10 GAP-01 type-grounding fixed phantoms in the
# files the sweep explicitly listed; phantoms survived in un-enumerated files
# (holdout-scenarios/, architecture prose, VP §Realizability Trace, etc.) and
# re-surfaced in rounds 11+.  This hook is the mechanical enforcement gate.
#
# PHANTOM PATTERN SET (edit the PHANTOM_PATTERNS list in the Python block)
# ────────────────────────────────────────────────────────────────────────
#   ToolOutput::Structured           — no such variant; invoke_dyn returns serde_json::Value
#   CompiledGraph<                   — generic phantom; canonical is non-generic CompiledStateGraph
#   ConcreteGraphRunner<             — generic phantom; canonical is non-generic ConcreteGraphRunner
#   from_value::<S>                  — retired deserialization step [GAP-01 scoped]
#   from_value::<TestGraphState>     — same [GAP-01 scoped]
#   S: GraphState                    — GraphState is NOT a trait (composed channel value)
#   trait GraphState                 — same
#   Fn(&S)                           — retired extract_output type; canonical is Fn(&serde_json::Value)
#   |s: &S| closure parameter        — retired closure form
#   schema_for!(S)                   — construction-time schema derivation; caller must supply
#   DynTool::invoke (word-boundary)  — no such method; canonical is DynTool::invoke_dyn (ADR-029 v1.7)
#   PreToolCallHook::PendingHumanApproval — no such path; canonical is PreToolDecision::PendingHumanApproval (BC-2.05.007)
#
# GAP-01 SCOPING NOTE
# ───────────────────
# from_value::<S> and from_value::<TestGraphState> appear legitimately in
# non-GAP-01 BCs (e.g. BC-2.01.001 ContentBlock serde deserialization).
# Those are REAL uses and are NOT flagged.  The "gap01_scope" check type
# fires only when the file's live body also references GraphAgentTool,
# mcp::graph_tool, mcp_graph_tool, or ConcreteGraphRunner — the exact
# surface that the GAP-01 type-grounding covers.
#
# ALLOWED-CONTEXT EXCLUSIONS (scanner skips these)
# ─────────────────────────────────────────────────
#   (A) YAML frontmatter changelog: list items (historical record)
#   (B) ## Changelog markdown section (until next ## heading)
#   (C) ## Symbol Grounding section (PHANTOM-audit table in ADR-029 and peers)
#   (D) Descriptive-negation / prohibition prose — lines containing any of:
#         no `        → "no `ToolOutput::Structured`"
#         NOT         → "is NOT a trait"
#         does not exist
#         eliminated
#         PHANTOM
#         replaced with
#         → `serde_json  (replacement notation)
#         no .*from_value  → "no type-level from_value::<S>", "(no from_value::<S> step"
#         no ToolOutput   → "no ToolOutput::Structured wrapping" (code comment, no backtick)
#   (E) The hooks/ directory itself (POL-30 self-exclusion)
#
# SCOPE
# ─────
# Scanned: .factory/specs/**/*.md
#          .factory/stories/**/*.md
#          .factory/holdout-scenarios/**/*.md
# Excluded: .factory/hooks/** (POL-30)
#
# ADVISORY: exits 0 always.  Findings are printed as [WARN] lines.
# Do NOT wire as blocking without human authorization — blocking flip requires
# explicit approval per the DEFER-004 / ORDINAL-RESIDUE-GATE precedent set in
# STATE.md.  Wire is advisory-only until corpus-wide residue reaches zero and
# a human explicitly promotes it.
#
# SELF-PROBE (POL-31)
# ───────────────────
# Synthetic fixtures exercised before live scan:
#   probe_1_live_body_flagged:                    ToolOutput::Structured in body → WARN fired
#   probe_2_changelog_exempt:                     same token inside ## Changelog → NOT flagged
#   probe_3_negation_exempt:                      no `ToolOutput::Structured` negation → NOT flagged
#   probe_4_gap01_scope_nonmatch:                 from_value::<S> in non-GAP-01 file → NOT flagged
#   probe_5_gap01_scope_match:                    from_value::<S> in GAP-01-scoped file → WARN fired
#   probe_6a_tooloutput_text_struct_flagged:      ToolOutput::Text { in GAP-01 file → WARN fired
#   probe_6b_tooloutput_text_struct_nongap01:     ToolOutput::Text { in non-GAP-01 file → NOT flagged
#   probe_7a_invoke_dyn_tooloutput_flagged:       invoke_dyn+ToolOutput in GAP-01 file → WARN fired
#   probe_7b_invoke_dyn_tooloutput_not_exempt:    invoke_dyn+ToolOutput with NOT negation → NOT flagged
#   probe_8a_graphstate_s_prose_flagged:          GraphState S in GAP-01 file → WARN fired
#   probe_8b_graphstate_s_changelog_exempt:       GraphState S in ## Changelog → NOT flagged
#   probe_9a_actionrisk_none_variant_flagged:     ActionRisk...None in GAP-01 file → WARN fired
#   probe_9b_actionrisk_none_not_negation_exempt: ActionRisk...None with NOT negation → NOT flagged
#   probe_10a_vp_not_in_inventory_flagged:        VP-016.md absent from VP-INDEX inventory → WARN fired
#   probe_10b_vp_in_inventory_not_flagged:        VP-015.md in-inventory filename → NOT flagged
#   probe_11a_ec_tv_hybrid_flagged:               EC-TV-3 hybrid anchor in GAP-01 file → WARN fired
#   probe_11b_ec_tv_hybrid_phantom_negation:      EC-TV-N with PHANTOM negation → NOT flagged
#   probe_12a_dyntool_invoke_flagged:             DynTool::invoke (phantom) in body → WARN fired
#   probe_12b_dyntool_invoke_dyn_exempt:          DynTool::invoke_dyn canonical form → NOT flagged
#   probe_13a_pretoolcallhook_pa_flagged:         PreToolCallHook::PendingHumanApproval in body → WARN fired
#   probe_13b_pretoolcalldecision_pa_exempt:      PreToolDecision::PendingHumanApproval canonical → NOT flagged
# POL-30: probe fixtures live in $TMPDIR, never under .factory/specs/ or .factory/stories/.
#
# EXIT CONTRACT
# ─────────────
# Exit 0: always (advisory).
# Exit 2: self-probe failure (script bug — a check is false-green or false-red).
#
# PROMOTION PATH
# ──────────────
# Once residue reaches zero, orchestrator promotes to blocking by:
#   1. Adding run_blocking "verify-no-phantom-types.sh" to pre-commit-validators.sh
#   2. Incrementing EXPECTED_BLOCKING_COUNT from 16 to 17
#   3. Changing exit contract in this script from "exit 0" to "exit $rc"
#   4. Updating the ADVISORY VALIDATORS header comment in pre-commit-validators.sh
#
# Usage:  bash .factory/hooks/verify-no-phantom-types.sh
# Called: standalone advisory check; also run_advisory in pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
SPECS_DIR="$FACTORY_DIR/specs"
STORIES_DIR="$FACTORY_DIR/stories"
HOLDOUT_DIR="$FACTORY_DIR/holdout-scenarios"

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
# Arguments: <scan_dir> [<scan_dir2> ...]
# Output lines:
#   HIT <relpath>:<lineno> [<pattern_name>] <snippet>
#   SCAN_FILES <n>
#   TOTAL <n>
run_phantom_scanner() {
  local factory_dir="$1"
  shift
  local scan_dirs=("$@")
  python3 - "$factory_dir" "${scan_dirs[@]}" <<'PYEOF'
import sys, re
from pathlib import Path

factory_dir = Path(sys.argv[1])
scan_dirs = [Path(d) for d in sys.argv[2:]]

# ─────────────────────────────────────────────────────────────────────────────
# VP FILENAME INVENTORY
# ─────────────────────────────────────────────────────────────────────────────
# Loads the authoritative set of VP filenames from VP-INDEX.md §VP Catalog
# File column.  R14-05 flags a VP filename reference ONLY when the filename
# is NOT present in this inventory (i.e., a genuine reference to a non-existent
# VP file).  References to in-inventory filenames (VP-001.md…VP-015.md,
# vp-006-b-injection-guard-multipair-fewshot.md,
# vp-016-graph-agent-tool-state-isolation.md, …) are NOT flagged.

def load_vp_inventory(fdir):
    """Parse VP-INDEX.md §VP Catalog File column → frozenset of valid VP filenames."""
    vp_index = fdir / 'specs' / 'verification-properties' / 'VP-INDEX.md'
    if not vp_index.exists():
        return frozenset()
    try:
        content = vp_index.read_text(encoding='utf-8', errors='replace')
    except Exception:
        return frozenset()
    vp_file_cell_re = re.compile(r'^(?:VP-\d{3}|vp-\d{3}[a-zA-Z0-9._-]*)\.md$')
    inventory = set()
    in_catalog = False
    for line in content.splitlines():
        stripped = line.strip()
        if re.match(r'^##\s+VP\s+Catalog\b', stripped, re.IGNORECASE):
            in_catalog = True
            continue
        if in_catalog and re.match(r'^##\s+', stripped):
            in_catalog = False
            continue
        if not in_catalog:
            continue
        if not (stripped.startswith('|') and stripped.endswith('|')):
            continue
        cells = [c.strip() for c in stripped.split('|')]
        for cell in cells:
            if vp_file_cell_re.match(cell):
                inventory.add(cell)
    return frozenset(inventory)

VP_INVENTORY = load_vp_inventory(factory_dir)

# ─────────────────────────────────────────────────────────────────────────────
# PHANTOM PATTERNS
# ─────────────────────────────────────────────────────────────────────────────
# Maintainable list — add newly-retired symbols here as phantoms are discovered.
# Each entry: (display_name, compiled_regex, check_type)
#
# check_type:
#   "always"      — checked in all in-scope .md files
#   "gap01_scope" — checked ONLY when the file's live body references any of:
#                   GraphAgentTool | mcp::graph_tool | mcp_graph_tool | ConcreteGraphRunner
#                   (limits false positives on legitimate serde uses in non-GAP-01 BCs)

PHANTOM_PATTERNS = [
    # ── F-P2A072-02 ── ToolOutput::Structured (no such variant; invoke_dyn returns serde_json::Value)
    ("ToolOutput::Structured",
     re.compile(r'ToolOutput::Structured'),
     "always"),

    # ── F-P2A072-03 ── CompiledGraph<S> generic phantom
    # Canonical: non-generic CompiledStateGraph (BC-2.02.001 {PC-001})
    ("CompiledGraph< (generic phantom)",
     re.compile(r'CompiledGraph<'),
     "always"),

    # ── F-P2A072-03 ── ConcreteGraphRunner<S> generic phantom
    # Canonical: non-generic ConcreteGraphRunner (no type parameter)
    ("ConcreteGraphRunner< (generic phantom)",
     re.compile(r'ConcreteGraphRunner<'),
     "always"),

    # ── F-P2A072-03 ── from_value::<S> / from_value::<TestGraphState>
    # Retired deserialization step — CompiledStateGraph::invoke takes serde_json::Value directly.
    # GAP-01 SCOPED: only flagged in files whose live body references the GraphAgentTool/
    # mcp::graph_tool surface.  Non-GAP-01 serde BCs use from_value legitimately.
    ("from_value::<S> (GAP-01 scoped)",
     re.compile(r'from_value::<S>'),
     "gap01_scope"),
    ("from_value::<TestGraphState> (GAP-01 scoped)",
     re.compile(r'from_value::<TestGraphState>'),
     "gap01_scope"),

    # ── F-P2A072-03 ── GraphState as trait bound
    # GraphState is NOT a user-defined trait — it is the composed Map<ChannelName, ChannelValue>.
    ("S: GraphState (phantom trait bound)",
     re.compile(r'S:\s+GraphState|S:GraphState'),
     "always"),
    ("trait GraphState (phantom trait declaration)",
     re.compile(r'\btrait\s+GraphState\b'),
     "always"),

    # ── F-P2A072-03 ── extract_output generic closure types
    # Canonical: Fn(&serde_json::Value) -> serde_json::Value
    ("Fn(&S) (phantom closure type)",
     re.compile(r'\bFn\s*\(\s*&S\s*\)'),
     "always"),
    ("|s: &S| closure parameter (phantom)",
     re.compile(r'\|s:\s*&S\b'),
     "always"),

    # ── F-P2A072-03 ── schema_for!(S) construction-time schema derivation
    # Canonical: caller derives schema via schemars::schema_for!(ConcreteType) at the call site
    # and passes the result as input_schema parameter — no construction-time S.
    ("schema_for!(S) (construction-time phantom)",
     re.compile(r'schema_for!\s*\(\s*S\s*\)'),
     "always"),

    # ── Round-14 extensions (GAP-01-context-scoped residue forms) ────────────────

    # ── R14-01 ── ToolOutput::Text { struct-literal form
    # Canonical: Text(String) tuple variant — struct-literal { field: val } form does not exist.
    # invoke_dyn returns serde_json::Value; wrapping as Text requires the tuple constructor.
    # GAP-01 SCOPED: only flagged in files referencing the GraphAgentTool/DynTool surface.
    ("ToolOutput::Text { (struct-literal phantom — canonical is Text(String) tuple form)",
     re.compile(r'ToolOutput::Text\s*\{'),
     "gap01_scope"),

    # ── R14-02 ── invoke_dyn line co-occurring with ToolOutput
    # DynTool::invoke_dyn dispatch path returns serde_json::Value, never a ToolOutput.
    # Heuristic: a line where invoke_dyn appears before ToolOutput — suggests phantom return-type
    # annotation or dispatch description.  One-directional to reduce false positives on comparative
    # prose where ToolOutput is mentioned first ("ToolOutput is what Tool::invoke returns, while
    # invoke_dyn returns serde_json::Value").
    # The NOT negation marker handles "does NOT return ToolOutput" style corrections.
    # GAP-01 SCOPED.
    ("invoke_dyn before ToolOutput on same line (invoke_dyn path returns serde_json::Value, not ToolOutput)",
     re.compile(r'\binvoke_dyn\b.*\bToolOutput\b'),
     "gap01_scope"),

    # ── R14-03 ── Prose "GraphState S" — retired generic state type
    # Canonical state is the channel-composed serde_json::Value map; "GraphState S" as a
    # prose type-annotation form (e.g., "takes a GraphState S parameter") is the retired pattern.
    # Distinct from the existing "S: GraphState" trait-bound and "trait GraphState" patterns:
    # catches the name-then-param word order used in informal prose and some spec tables.
    # GAP-01 SCOPED.
    ("GraphState S (prose — retired generic state type; canonical is serde_json::Value)",
     re.compile(r'\bGraphState\s+S\b'),
     "gap01_scope"),

    # ── R14-04 ── ActionRisk variant enumeration containing None
    # Canonical ActionRisk variants: ReadOnly | Low | Medium | High.
    # 'None' is Option::None in Rust — NOT an ActionRisk variant.
    # Heuristic: line with 'ActionRisk' and 'None' on the same line, suggesting an enum
    # definition or variant-list prose that incorrectly includes None.
    # The NOT negation marker handles "does NOT include ActionRisk::None" corrections.
    # GAP-01 SCOPED.
    ("ActionRisk...None (phantom variant — None is Option::None, not an ActionRisk variant)",
     re.compile(r'\bActionRisk\b.*\bNone\b'),
     "gap01_scope"),

    # ── R14-05 ── VP filename reference not present in VP-INDEX §VP-Catalog inventory
    # Source of truth: VP-INDEX.md §VP Catalog File column (VP_INVENTORY set, loaded above).
    # Canonical filenames currently: VP-001.md…VP-015.md (uppercase, no slug) and
    # vp-006-b-injection-guard-multipair-fewshot.md + vp-016-graph-agent-tool-state-isolation.md
    # (lowercase, with slug).  Any reference that matches the VP filename shape but is absent
    # from the inventory is a broken reference to a non-existent file.
    # check_type "vp_inventory": scan_file Pass 3 extracts group(1) and checks VP_INVENTORY.
    # NOT GAP-01 scoped: broken VP references can appear in any spec file.
    ("VP filename absent from VP-INDEX §VP-Catalog inventory (phantom reference to non-existent VP file)",
     re.compile(r'\b((?:VP|vp)-\d{3}[a-zA-Z0-9._-]*\.md)\b'),
     "vp_inventory"),

    # ── R14-06 ── EC-TV-N hybrid anchor form
    # Canonical anchors: EC-NNN (error case) OR TV-NNN (test vector) — separate namespaces.
    # 'EC-TV-N' is a malformed hybrid that combines both prefixes and corresponds to no
    # canonical anchor in any spec index.
    # GAP-01 SCOPED: hybrid anchors observed only in GAP-01-related story and BC files.
    ("EC-TV-N (hybrid anchor — canonical is EC-NNN or TV-NNN separately, never combined)",
     re.compile(r'\bEC-TV-\d+\b'),
     "gap01_scope"),

    # ── F-P2A087-PG-01 ── DynTool::invoke (phantom method path)
    # The object-safe DynTool trait exposes: name, description, schema, action_risk, invoke_dyn.
    # There is NO 'invoke' method — the phantom form 'DynTool::invoke' never resolves.
    # Canonical: DynTool::invoke_dyn (ADR-029 changelog v1.7).
    # Regex uses \b word-boundary: 'invoke' followed by '_' (word char) has no word boundary,
    # so DynTool::invoke_dyn (and any other DynTool::invoke_xxx suffix) does NOT match.
    # Only the bare DynTool::invoke form at a word boundary is flagged.
    # ALWAYS scoped: DynTool is used across the entire tool-invocation surface, not GAP-01 only.
    ("DynTool::invoke (phantom — canonical is DynTool::invoke_dyn; ADR-029 v1.7)",
     re.compile(r'\bDynTool::invoke\b'),
     "always"),

    # ── F-P2A087-PG-02 ── PreToolCallHook::PendingHumanApproval (phantom enum path)
    # PreToolCallHook is the hook trait (single method: pre_invoke) — it is NOT an enum and
    # has no variants.  PendingHumanApproval is a PreToolDecision enum variant (BC-2.05.007).
    # The :: path form 'PreToolCallHook::PendingHumanApproval' therefore never resolves.
    # Canonical: PreToolDecision::PendingHumanApproval.
    # Bare prose without '::' (e.g., "a PreToolCallHook returns PendingHumanApproval") does
    # NOT match this regex — only the literal '::' path form is flagged.
    # ALWAYS scoped: the pre-tool-call hook / HITL surface spans all hook-bearing specs.
    ("PreToolCallHook::PendingHumanApproval (phantom path — canonical is PreToolDecision::PendingHumanApproval; BC-2.05.007)",
     re.compile(r'PreToolCallHook::PendingHumanApproval'),
     "always"),
]

# Anchor patterns for GAP-01 scope detection (live-body content only)
GAP01_ANCHOR_RE = re.compile(
    r'GraphAgentTool|mcp::graph_tool|mcp_graph_tool|ConcreteGraphRunner|VP-016|BC-2\.09\.008'
)

# ─────────────────────────────────────────────────────────────────────────────
# NEGATION / DESCRIPTIVE-EXCLUSION MARKERS
# ─────────────────────────────────────────────────────────────────────────────
# Lines containing any of these phrases describe retired/eliminated symbols —
# they must NOT be flagged (they are correct documentation of what was removed).
#
# Task-specified exclusions (per P2A-077 process-gap specification):
#   no `          → "no `ToolOutput::Structured`", "no `from_value::<S>` step"
#   NOT           → "GraphState is NOT a trait"
#   does not exist
#   eliminated
#   PHANTOM
#   replaced with
#   → `serde_json → replacement notation "→ `serde_json::Value`"
#
# Additional practical exclusions derived from corpus analysis:
#   no .*from_value → "no type-level from_value::<S>", "(no from_value::<S> step"
#               (code-block comments explaining absence of the step; no backtick used)

NEGATION_RES = [
    re.compile(r'no `'),                          # "no `ToolOutput::Structured`"
    re.compile(r'\bNOT\b'),                       # "is NOT a trait"
    re.compile(r'does not exist'),
    re.compile(r'\beliminated\b'),
    re.compile(r'\bPHANTOM\b'),
    re.compile(r'replaced with'),
    re.compile(r'→ `serde_json'),                 # "→ `serde_json::Value`" replacement notation
    re.compile(r'\bno\b.*\bfrom_value\b', re.IGNORECASE),  # "no type-level from_value", "(no from_value"
    re.compile(r'\bno\b\s+ToolOutput\b'),                 # "no ToolOutput::Structured wrapping" (code comment without backtick)
]

def is_negation_line(line: str) -> bool:
    return any(r.search(line) for r in NEGATION_RES)


# ─────────────────────────────────────────────────────────────────────────────
# REGION STATE MACHINE
# ─────────────────────────────────────────────────────────────────────────────

MD_CHANGELOG_RE  = re.compile(r'^##\s+Changelog\b', re.IGNORECASE)
MD_SYMBOL_GND_RE = re.compile(r'^##\s+Symbol\s+Grounding\b', re.IGNORECASE)
MD_ANY_H2_RE     = re.compile(r'^##\s+')
YAML_KEY_RE      = re.compile(r'^[a-zA-Z_][\w_-]*\s*:')


def scan_file(path: Path) -> list:
    """Return list of (lineno, pattern_name, line_text) for phantom hits in this file."""
    try:
        raw = path.read_text(encoding='utf-8', errors='replace')
    except Exception:
        return []

    lines = raw.splitlines()

    # ── Pass 1: Collect live-body lines (exclude changelog + symbol-grounding) ──
    in_yaml_front     = False
    yaml_ended        = False
    in_yaml_changelog = False   # inside changelog: list in YAML frontmatter
    in_md_changelog   = False   # inside ## Changelog body section
    in_symbol_gnd     = False   # inside ## Symbol Grounding body section

    live_lines = []  # list of (lineno, line)

    for lineno, line in enumerate(lines, 1):
        stripped = line.strip()

        # ── YAML frontmatter boundaries ───────────────────────────────────────
        if lineno == 1 and stripped == '---':
            in_yaml_front = True
            continue
        if in_yaml_front and not yaml_ended:
            if stripped == '---':
                in_yaml_front  = False
                yaml_ended     = True
                in_yaml_changelog = False
                continue
            # Detect start of changelog: list in YAML
            if re.match(r'^changelog\s*:', stripped):
                in_yaml_changelog = True
                continue
            # Any other top-level YAML key ends the changelog: block
            if YAML_KEY_RE.match(stripped) and not stripped.startswith('-'):
                in_yaml_changelog = False
            # Skip all lines in the changelog: list (historical records)
            if in_yaml_changelog:
                continue
            # All other YAML frontmatter lines are live (description, traces_to, etc.)

        # ── Markdown section exclusions (body only, after YAML end) ──────────
        if yaml_ended or not in_yaml_front:
            if MD_CHANGELOG_RE.match(stripped):
                in_md_changelog = True
                in_symbol_gnd   = False
                continue
            if MD_SYMBOL_GND_RE.match(stripped):
                in_symbol_gnd   = True
                in_md_changelog = False
                continue
            if MD_ANY_H2_RE.match(stripped):
                # Any other ## heading ends both exclusion regions
                if in_md_changelog or in_symbol_gnd:
                    in_md_changelog = False
                    in_symbol_gnd   = False
            if in_md_changelog or in_symbol_gnd:
                continue

        live_lines.append((lineno, line))

    # ── Pass 2: Determine GAP-01 scope from live content ─────────────────────
    is_gap01_scoped = any(
        GAP01_ANCHOR_RE.search(line)
        for _, line in live_lines
    )

    # ── Pass 3: Check live lines against phantom patterns ────────────────────
    findings = []
    for lineno, line in live_lines:
        if is_negation_line(line):
            continue
        for (name, pattern, check_type) in PHANTOM_PATTERNS:
            if check_type == "gap01_scope" and not is_gap01_scoped:
                continue
            if check_type == "vp_inventory":
                # R14-05 inventory check: match filename, flag only if absent from inventory
                m = pattern.search(line)
                if m:
                    filename = m.group(1)
                    if filename not in VP_INVENTORY:
                        findings.append((lineno, name, line.rstrip()))
            elif pattern.search(line):
                findings.append((lineno, name, line.rstrip()))

    return findings


# ── Scan all directories ──────────────────────────────────────────────────────
# POL-30: the hooks/ directory is excluded automatically because we receive only
# SPECS_DIR, STORIES_DIR, and HOLDOUT_DIR as arguments — the hooks/ dir is never
# passed in, so verify-no-phantom-types.sh itself cannot be a false positive.

total_findings = 0
scan_files_count = 0
all_results = {}  # Path -> [(lineno, name, line)]

for scan_dir in scan_dirs:
    if not scan_dir.is_dir():
        continue
    for p in sorted(scan_dir.rglob('*.md')):
        scan_files_count += 1
        hits = scan_file(p)
        if hits:
            all_results[p] = hits
            total_findings += len(hits)

# ── Emit output ───────────────────────────────────────────────────────────────
for path, hits in sorted(all_results.items()):
    # Make path relative to the common parent (.factory/) for readability
    rel = str(path)
    for sd in scan_dirs:
        try:
            rel = str(path.relative_to(sd.parent))
            break
        except ValueError:
            pass
    for lineno, name, line_text in hits:
        snippet = line_text.strip()[:120]
        print(f'HIT {rel}:{lineno} [{name}] {snippet}')

print(f'SCAN_FILES {scan_files_count}')
print(f'TOTAL {total_findings}')
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

# Helper: run the scanner against a probe scan dir; return HIT lines only.
# Passes FACTORY_DIR so the VP inventory is loaded from the real VP-INDEX.md,
# enabling probe_10b to verify that in-inventory filenames (VP-015.md) are exempt.
run_probe_scan() {
  local probe_scan_dir="$1"
  run_phantom_scanner "$FACTORY_DIR" "$probe_scan_dir" | grep '^HIT' || true
}

# ── Self-probe 1: live body MUST be flagged ───────────────────────────────────
probe_1_live_body_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Preconditions

The GraphAgentTool wraps a CompiledStateGraph.

## Postconditions

The extract_output closure returns Ok(ToolOutput::Structured { value: result }).
The invoke_dyn call returns Ok(ToolOutput::Structured { value }).
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_1_live_body_flagged: ToolOutput::Structured in body was NOT flagged."
    echo "  Expected at least one HIT line."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'ToolOutput::Structured'; then
    echo "[SELF-PROBE FAIL] probe_1_live_body_flagged: HIT found but not for ToolOutput::Structured."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_1_live_body_flagged: ToolOutput::Structured in body is detected."
}

# ── Self-probe 2: ## Changelog section MUST NOT be flagged ───────────────────
probe_2_changelog_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Preconditions

No suspicious tokens here.

## Changelog

- 1.1: corrected ToolOutput::Structured phantom; invoke_dyn returns serde_json::Value.
- 1.0: initial version with CompiledGraph<S> and ConcreteGraphRunner<TestGraphState>.

## Postconditions

Also no suspicious tokens here.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_2_changelog_exempt: token inside ## Changelog was incorrectly flagged."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_2_changelog_exempt: ## Changelog tokens are exempt."
}

# ── Self-probe 3: descriptive-negation prose MUST NOT be flagged ──────────────
probe_3_negation_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Description

GraphAgentTool has been updated. There is no `ToolOutput::Structured` wrapping —
`DynTool::invoke_dyn` returns `Result<serde_json::Value, PregolyaError>` directly.
The `CompiledGraph<S>` generic form is NOT used; canonical is `CompiledStateGraph`.
The `S: GraphState` trait bound was eliminated in round-10.
The `from_value::<S>` step does not exist — CompiledStateGraph::invoke takes serde_json::Value.
The pattern has been replaced with a non-generic form.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_3_negation_exempt: negation-marker line was incorrectly flagged."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_3_negation_exempt: descriptive-negation lines are exempt."
}

# ── Self-probe 4: from_value::<S> in non-GAP-01 file MUST NOT be flagged ──────
# from_value::<S> appears in non-GAP-01 serde BCs (e.g. BC-2.01.001 ContentBlock).
# Those files do not reference GraphAgentTool/mcp::graph_tool/ConcreteGraphRunner —
# they must not be flagged.
probe_4_gap01_scope_nonmatch() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  # A non-GAP-01 BC that uses from_value legitimately — no GraphAgentTool anchor.
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

Deserializes via serde_json::from_value::<ContentBlock>(raw_json) to produce the typed struct.
The from_value::<S> pattern is the standard serde deserialization idiom.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_4_gap01_scope_nonmatch: from_value::<S> in non-GAP-01 file was incorrectly flagged."
    echo "  This would produce false positives on legitimate serde uses in unrelated BCs."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_4_gap01_scope_nonmatch: from_value::<S> in non-GAP-01 file is not flagged."
}

# ── Self-probe 5: from_value::<S> in GAP-01 scoped file MUST be flagged ───────
# A file that references GraphAgentTool (GAP-01 anchor) and contains from_value::<S>
# in live normative text should be flagged.
probe_5_gap01_scope_match() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Description

The GraphAgentTool wraps a CompiledStateGraph for MCP tool invocation.

## Postconditions

The runner performs serde_json::from_value::<S>(input) inside ConcreteGraphRunner::run
to deserialize the input JSON into the graph state type.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_5_gap01_scope_match: from_value::<S> in GAP-01-scoped file was NOT flagged."
    echo "  Expected a HIT line for from_value::<S> (GAP-01 scoped)."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'from_value::<S>'; then
    echo "[SELF-PROBE FAIL] probe_5_gap01_scope_match: HIT found but not for from_value::<S>."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_5_gap01_scope_match: from_value::<S> in GAP-01-scoped file is flagged."
}

# ── Self-probe 6a: ToolOutput::Text { in GAP-01 scoped file MUST be flagged ─────
probe_6a_tooloutput_text_struct_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

The GraphAgentTool dispatch returns Ok(ToolOutput::Text { value: result_string }).
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_6a_tooloutput_text_struct_flagged: ToolOutput::Text { in GAP-01 scoped file was NOT flagged."
    echo "  Expected a HIT for 'ToolOutput::Text { (struct-literal phantom)'."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'ToolOutput::Text {'; then
    echo "[SELF-PROBE FAIL] probe_6a_tooloutput_text_struct_flagged: HIT found but not for ToolOutput::Text { pattern."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_6a_tooloutput_text_struct_flagged: ToolOutput::Text { in GAP-01 scoped file is flagged."
}

# ── Self-probe 6b: ToolOutput::Text { in non-GAP-01 file MUST NOT be flagged ────
probe_6b_tooloutput_text_struct_nongap01_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

The tool dispatch path returns Ok(ToolOutput::Text { value: result_string }) to the caller.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_6b_tooloutput_text_struct_nongap01_exempt: ToolOutput::Text { in non-GAP-01 file was incorrectly flagged."
    echo "  This file has no GraphAgentTool/mcp::graph_tool/ConcreteGraphRunner/VP-016/BC-2.09.008 anchor."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_6b_tooloutput_text_struct_nongap01_exempt: ToolOutput::Text { in non-GAP-01 file is not flagged."
}

# ── Self-probe 7a: invoke_dyn before ToolOutput in GAP-01 scoped file MUST be flagged ─
probe_7a_invoke_dyn_tooloutput_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

The GraphAgentTool calls invoke_dyn on the inner tool and returns ToolOutput::Text(result).
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_7a_invoke_dyn_tooloutput_flagged: invoke_dyn+ToolOutput in GAP-01 scoped file was NOT flagged."
    echo "  Expected a HIT for 'invoke_dyn before ToolOutput on same line'."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'invoke_dyn'; then
    echo "[SELF-PROBE FAIL] probe_7a_invoke_dyn_tooloutput_flagged: HIT found but not for invoke_dyn pattern."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_7a_invoke_dyn_tooloutput_flagged: invoke_dyn+ToolOutput in GAP-01 scoped file is flagged."
}

# ── Self-probe 7b: invoke_dyn + ToolOutput in NOT-negation line MUST NOT be flagged ─
probe_7b_invoke_dyn_tooloutput_not_negation_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Description

The GraphAgentTool dispatch calls invoke_dyn which does NOT return ToolOutput — it returns serde_json::Value.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_7b_invoke_dyn_tooloutput_not_negation_exempt: NOT-negated line with invoke_dyn+ToolOutput was incorrectly flagged."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_7b_invoke_dyn_tooloutput_not_negation_exempt: invoke_dyn+ToolOutput in NOT-negation line is exempt."
}

# ── Self-probe 8a: GraphState S prose in GAP-01 scoped file MUST be flagged ─────
probe_8a_graphstate_s_prose_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

The GraphAgentTool runner accepts a GraphState S parameter representing the channel-composed state.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_8a_graphstate_s_prose_flagged: GraphState S in GAP-01 scoped file was NOT flagged."
    echo "  Expected a HIT for 'GraphState S (prose — retired generic state type)'."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'GraphState S'; then
    echo "[SELF-PROBE FAIL] probe_8a_graphstate_s_prose_flagged: HIT found but not for GraphState S pattern."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_8a_graphstate_s_prose_flagged: GraphState S in GAP-01 scoped file is flagged."
}

# ── Self-probe 8b: GraphState S in ## Changelog MUST NOT be flagged ──────────────
probe_8b_graphstate_s_changelog_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Description

The GraphAgentTool runner accepts a serde_json::Value state map.

## Changelog

- 1.1: removed GraphState S generic type parameter; canonical is serde_json::Value.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_8b_graphstate_s_changelog_exempt: GraphState S in ## Changelog was incorrectly flagged."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_8b_graphstate_s_changelog_exempt: GraphState S in ## Changelog section is exempt."
}

# ── Self-probe 9a: ActionRisk + None in GAP-01 scoped file MUST be flagged ───────
probe_9a_actionrisk_none_variant_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

The GraphAgentTool risk level is one of ActionRisk variants: None, ReadOnly, Low, Medium, High.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_9a_actionrisk_none_variant_flagged: ActionRisk...None in GAP-01 scoped file was NOT flagged."
    echo "  Expected a HIT for 'ActionRisk...None (phantom variant)'."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'ActionRisk'; then
    echo "[SELF-PROBE FAIL] probe_9a_actionrisk_none_variant_flagged: HIT found but not for ActionRisk pattern."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_9a_actionrisk_none_variant_flagged: ActionRisk...None in GAP-01 scoped file is flagged."
}

# ── Self-probe 9b: ActionRisk + None in NOT-negation line MUST NOT be flagged ────
probe_9b_actionrisk_none_not_negation_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Description

The GraphAgentTool risk classification does NOT include ActionRisk::None as a valid variant.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_9b_actionrisk_none_not_negation_exempt: NOT-negated ActionRisk+None line was incorrectly flagged."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_9b_actionrisk_none_not_negation_exempt: ActionRisk+None in NOT-negation line is exempt."
}

# ── Self-probe 10a: VP filename absent from inventory MUST be flagged ─────────────
# VP-016.md is NOT in the VP-INDEX §VP-Catalog File column inventory —
# the real file is vp-016-graph-agent-tool-state-isolation.md.
# A reference to VP-016.md is a phantom reference to a non-existent VP file.
probe_10a_vp_not_in_inventory_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## References

State isolation proofs are documented in VP-016.md for the graph agent tool boundary.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_10a_vp_not_in_inventory_flagged: VP-016.md (absent from VP-INDEX inventory) was NOT flagged."
    echo "  Expected a HIT — VP-016.md is not in VP-INDEX §VP-Catalog File column inventory."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'VP-016.md'; then
    echo "[SELF-PROBE FAIL] probe_10a_vp_not_in_inventory_flagged: HIT found but not for VP-016.md in snippet."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_10a_vp_not_in_inventory_flagged: VP-016.md absent-from-inventory reference is flagged."
}

# ── Self-probe 10b: VP filename present in inventory MUST NOT be flagged ──────────
# VP-015.md IS in the VP-INDEX §VP-Catalog File column inventory (mcp::sanitize unit P1).
# The inventory check exempts in-inventory filenames regardless of case/slug form.
# This probe verifies R14-05 does NOT false-positive on real VP filenames.
probe_10b_vp_in_inventory_not_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## References

Credential redaction proofs are documented in VP-015.md for the MCP sanitize unit test.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_10b_vp_in_inventory_not_flagged: in-inventory VP-015.md reference was incorrectly flagged."
    echo "  VP-015.md is in VP-INDEX §VP-Catalog File column — R14-05 must not flag in-inventory filenames."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_10b_vp_in_inventory_not_flagged: in-inventory VP-015.md reference is not flagged."
}

# ── Self-probe 11a: EC-TV-N hybrid anchor in GAP-01 scoped file MUST be flagged ──
probe_11a_ec_tv_hybrid_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Edge Cases

The GraphAgentTool handles EC-TV-3: state isolation validation failure on concurrent access.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_11a_ec_tv_hybrid_flagged: EC-TV-3 hybrid anchor in GAP-01 scoped file was NOT flagged."
    echo "  Expected a HIT for 'EC-TV-N (hybrid anchor)'."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'EC-TV'; then
    echo "[SELF-PROBE FAIL] probe_11a_ec_tv_hybrid_flagged: HIT found but not for EC-TV pattern."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_11a_ec_tv_hybrid_flagged: EC-TV-N hybrid anchor in GAP-01 scoped file is flagged."
}

# ── Self-probe 11b: EC-TV-N with PHANTOM negation in live body MUST NOT be flagged ─
# File is GAP-01 scoped (GraphAgentTool present) so the gap01_scope check cannot
# explain the non-firing — the PHANTOM negation marker is what exempts the line.
probe_11b_ec_tv_hybrid_phantom_negation_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Description

The PHANTOM anchor EC-TV-3 in GraphAgentTool spec was split into EC-013 (error case) and TV-003 (test vector).

## Postconditions

The GraphAgentTool uses canonical EC-013 for graph-boundary error handling.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_11b_ec_tv_hybrid_phantom_negation_exempt: EC-TV-3 with PHANTOM negation marker was incorrectly flagged."
    echo "  The PHANTOM negation on the same line as EC-TV-3 should exempt it from scanning."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_11b_ec_tv_hybrid_phantom_negation_exempt: EC-TV-N with PHANTOM negation marker in live body is exempt."
}

# ── Self-probe 12a: DynTool::invoke in live body MUST be flagged ─────────────
# DynTool::invoke is a phantom method — the canonical form is DynTool::invoke_dyn.
# This 'always'-scoped pattern fires without any GAP-01 anchor.
probe_12a_dyntool_invoke_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

The dispatcher calls DynTool::invoke on each registered tool and collects the results.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_12a_dyntool_invoke_flagged: DynTool::invoke in live body was NOT flagged."
    echo "  Expected a HIT for 'DynTool::invoke (phantom — canonical is DynTool::invoke_dyn)'."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'DynTool::invoke'; then
    echo "[SELF-PROBE FAIL] probe_12a_dyntool_invoke_flagged: HIT found but not for DynTool::invoke pattern."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_12a_dyntool_invoke_flagged: DynTool::invoke phantom is detected."
}

# ── Self-probe 12b: DynTool::invoke_dyn canonical form MUST NOT be flagged ────
# The \b word-boundary on the pattern means 'invoke_dyn' (underscore is a word char,
# so no boundary after 'invoke') does NOT trigger the DynTool::invoke pattern.
probe_12b_dyntool_invoke_dyn_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

The dispatcher calls DynTool::invoke_dyn on each registered tool, returning serde_json::Value.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_12b_dyntool_invoke_dyn_exempt: DynTool::invoke_dyn was incorrectly flagged."
    echo "  'invoke_dyn' has no word boundary after 'invoke' (underscore is a word char) — must not match."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_12b_dyntool_invoke_dyn_exempt: DynTool::invoke_dyn canonical form is not flagged."
}

# ── Self-probe 13a: PreToolCallHook::PendingHumanApproval MUST be flagged ─────
# PreToolCallHook is a trait (not an enum) — PendingHumanApproval is a
# PreToolDecision variant.  The :: path form is always a phantom.
probe_13a_pretoolcallhook_pa_flagged() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

When the policy requires human sign-off, pre_invoke returns PreToolCallHook::PendingHumanApproval
to pause execution until the operator confirms.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -z "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_13a_pretoolcallhook_pa_flagged: PreToolCallHook::PendingHumanApproval was NOT flagged."
    echo "  Expected a HIT for 'PreToolCallHook::PendingHumanApproval (phantom path)'."
    clean_probe_tmp; exit 2
  fi
  if ! echo "$hits" | grep -qF 'PreToolCallHook::PendingHumanApproval'; then
    echo "[SELF-PROBE FAIL] probe_13a_pretoolcallhook_pa_flagged: HIT found but not for PreToolCallHook::PendingHumanApproval pattern."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_13a_pretoolcallhook_pa_flagged: PreToolCallHook::PendingHumanApproval phantom is detected."
}

# ── Self-probe 13b: PreToolDecision::PendingHumanApproval MUST NOT be flagged ─
# The canonical enum path uses PreToolDecision, not PreToolCallHook — no :: match.
# Bare prose "a PreToolCallHook returns PendingHumanApproval" also must NOT match
# because the pattern requires the '::' separator.
probe_13b_pretoolcalldecision_pa_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/spec"
  cat > "$PROBE_TMP/spec/probe.md" <<'SPECEOF'
---
version: "1.0"
---

## Postconditions

When the policy requires human sign-off, pre_invoke returns PreToolDecision::PendingHumanApproval
to pause execution until the operator confirms. The PreToolCallHook implementation yields
PendingHumanApproval via the PreToolDecision enum, not directly as a hook variant.
SPECEOF
  local hits
  hits="$(run_probe_scan "$PROBE_TMP/spec")"
  if [ -n "$hits" ]; then
    echo "[SELF-PROBE FAIL] probe_13b_pretoolcalldecision_pa_exempt: canonical PreToolDecision::PendingHumanApproval was incorrectly flagged."
    echo "  Pattern must only match 'PreToolCallHook::PendingHumanApproval', not 'PreToolDecision::' or bare prose."
    echo "  Output: $hits"
    clean_probe_tmp; exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_13b_pretoolcalldecision_pa_exempt: PreToolDecision::PendingHumanApproval canonical form is not flagged."
}

# ── Main live check ───────────────────────────────────────────────────────────
check_phantom_types() {
  local raw_output
  raw_output="$(run_phantom_scanner "$FACTORY_DIR" "$SPECS_DIR" "$STORIES_DIR" "$HOLDOUT_DIR")"

  local scan_files=0
  local total=0
  local hit_lines=()

  while IFS= read -r line; do
    case "$line" in
      HIT\ *)        hit_lines+=("${line#HIT }") ;;
      SCAN_FILES\ *) scan_files="${line#SCAN_FILES }" ;;
      TOTAL\ *)      total="${line#TOTAL }" ;;
    esac
  done <<< "$raw_output"

  echo "  Scanned: ${scan_files} .md files across specs/, stories/, holdout-scenarios/"
  echo "  Scope:   CORPUS GREP (no enumerated file list — P2A-077 process-gap prevention)"
  echo ""

  if [ "${#hit_lines[@]}" -eq 0 ]; then
    emit PASS "phantom-types: ZERO live phantom-type occurrences found corpus-wide"
  else
    echo "  Live occurrences found (routing: architect/product-owner/story-writer per GAP-01-straggler fix-burst):"
    echo ""
    for entry in "${hit_lines[@]}"; do
      emit WARN "phantom-types: $entry"
    done
    echo ""
    echo "  Fix guidance:"
    echo "    ToolOutput::Structured   → invoke_dyn returns serde_json::Value directly"
    echo "    CompiledGraph<S>         → non-generic CompiledStateGraph (BC-2.02.001 {PC-001})"
    echo "    ConcreteGraphRunner<S>   → non-generic ConcreteGraphRunner"
    echo "    from_value::<S>          → CompiledStateGraph::invoke takes serde_json::Value directly"
    echo "    S: GraphState            → GraphState is NOT a trait; use serde_json::Value"
    echo "    Fn(&S)                   → Fn(&serde_json::Value) -> serde_json::Value"
    echo "    schema_for!(S)           → caller-supplied input_schema: schemars::Schema"
    echo "    ToolOutput::Text {       → Text(String) tuple form: ToolOutput::Text(value.to_string())"
    echo "    invoke_dyn+ToolOutput    → invoke_dyn returns serde_json::Value; wrap at call site if needed"
    echo "    GraphState S (prose)     → serde_json::Value; GraphState is not a user-defined type"
    echo "    ActionRisk...None        → ActionRisk: ReadOnly|Low|Medium|High; None = Option::None"
    echo "    VP phantom filename      → check VP-INDEX §VP-Catalog File column for the exact in-inventory filename"
    echo "    EC-TV-N (hybrid)         → canonical: EC-NNN (error case) or TV-NNN (test vector) separately"
    echo "    DynTool::invoke          → DynTool::invoke_dyn (object-safe dispatch; ADR-029 v1.7)"
    echo "    PreToolCallHook::PendingHumanApproval → PreToolDecision::PendingHumanApproval (BC-2.05.007)"
    echo "    Reference: ADR-029 §Symbol Grounding"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-no-phantom-types: GAP-01 phantom-type corpus grep gate (ADVISORY)"
echo "  Specs:    $SPECS_DIR"
echo "  Stories:  $STORIES_DIR"
echo "  Holdout:  $HOLDOUT_DIR"
echo "  Finding:  P2A-077 class — enumerated-file-list sweep left straggler phantom occurrences"
echo ""

echo "[SELF-PROBE] Verifying check catches phantoms and respects all exclusions (POL-31)..."
probe_1_live_body_flagged
probe_2_changelog_exempt
probe_3_negation_exempt
probe_4_gap01_scope_nonmatch
probe_5_gap01_scope_match
probe_6a_tooloutput_text_struct_flagged
probe_6b_tooloutput_text_struct_nongap01_exempt
probe_7a_invoke_dyn_tooloutput_flagged
probe_7b_invoke_dyn_tooloutput_not_negation_exempt
probe_8a_graphstate_s_prose_flagged
probe_8b_graphstate_s_changelog_exempt
probe_9a_actionrisk_none_variant_flagged
probe_9b_actionrisk_none_not_negation_exempt
probe_10a_vp_not_in_inventory_flagged
probe_10b_vp_in_inventory_not_flagged
probe_11a_ec_tv_hybrid_flagged
probe_11b_ec_tv_hybrid_phantom_negation_exempt
probe_12a_dyntool_invoke_flagged
probe_12b_dyntool_invoke_dyn_exempt
probe_13a_pretoolcallhook_pa_flagged
probe_13b_pretoolcalldecision_pa_exempt
echo "[SELF-PROBE] All 21 self-probes passed — check is not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "ADVISORY check (exit 0 always)"
echo "════════════════════════════════════════════"
echo ""
echo "── phantom-type corpus scan ────────────────────────────────────────────"
check_phantom_types

echo ""
echo "════════════════════════════════════════════"
echo ""
echo "verify-no-phantom-types: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  ADVISORY: $WARN WARN(s) — corpus-wide phantom occurrence count"
if [ "$WARN" -gt 0 ]; then
  echo "  Routing: architect + product-owner + story-writer — GAP-01-straggler fix-burst"
  echo "  Gate ADR-029 §Symbol Grounding; reference: verify-ordinal-form-residue.sh promotion path"
fi
echo ""
echo "RESULT: PASS (advisory — exit 0 regardless of WARN count)"
exit 0
