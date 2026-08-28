#!/usr/bin/env bash
# verify-module-name-consistency.sh — module registry ↔ BC/story file-path consistency gate (ADVISORY)
#
# PURPOSE
# ───────
# Detects drift between the canonical module→file-path registry (module-decomposition.md)
# and the file paths cited in BC §Architecture Anchors and story §File Structure Requirements /
# §Architecture Mapping sections.
#
# Each module row in module-decomposition.md declares (explicitly or by convention) a canonical
# source file path.  When BCs or stories reference that module via a DIFFERENT file path, the
# discrepancy is a registry drift: specs are pointing implementers to the wrong file.
# Round-25 canonicalized all pregolya-mcp/* module→file mappings; this gate verifies
# propagation completeness and catches future regressions across all subsystems.
#
# FINDING CLASSES
# ───────────────
# F-P2A111-01/02/03: pregolya-mcp module→file canonicalization established in module-decomposition
# v1.52 (round-25): discovery.rs / interceptor.rs / session.rs / ingress.rs canonical paths
# supersede the stale tools.rs / interceptors.rs / sessions.rs / guardrail.rs anchors that
# BCs and stories still carry.  OBS-3 generalization per F-P2A111: check corpus-wide.
#
# DETECTION RULES
# ───────────────
# For each crate that has any module with an explicit canonical file path in module-decomposition:
#
# R1 — STALE-FILE: a path cited in a BC (§Architecture Anchors) or story (§File Structure /
#      §Architecture Mapping) belongs to a canonicalized crate AND is NOT in that crate's
#      canonical path set.  Indicates the spec was written against an old file mapping.
#
# R2 — MISSING-COVERAGE: a canonical path (explicitly declared in a module description, not
#      derived by convention) for a HIGH or CRITICAL module appears in ZERO BC or story files.
#      Indicates the spec was never updated to reference the new canonical path.
#
# R3 — BC-STORY-MISMATCH: a BC cites path A for a module's crate but the story for the same
#      functional area cites path B (different stem or singular/plural form).  Indicates
#      inconsistency between PO and story-writer artifacts.
#
# SCOPE
# ─────
# Canonical-path-aware crates (have explicit paths in module-decomposition): pregolya-mcp,
# pregolya-graph, pregolya-core (selected modules), pregolya-memory, pregolya-checkpoint.
# Other crates have no explicit canonical paths declared and are therefore SKIPPED to avoid
# false-positive findings from implementation-level supplementary files.
#
# ADVISORY: exits 0 always.  Findings are printed as [WARN] lines.
# Promotion to blocking: after story-writer + product-owner propagation sweep clears all
# WARN findings across the full corpus; requires human authorization.
#
# SELF-PROBES (POL-31)
# ────────────────────
# probe_mnc_pos_stale_file:  synthetic module probe::widget canonical=pregolya-probe/src/widget.rs,
#                            BC cites pregolya-probe/src/widgets.rs → R1 STALE-FILE WARN expected
# probe_mnc_neg_aligned:     same module, BC cites pregolya-probe/src/widget.rs (canonical) → no R1 WARN
# POL-30: probe fixtures live in $TMPDIR, never under .factory/.
#
# EXIT CONTRACT
# ─────────────
# Exit 0: always (advisory).
# Exit 2: self-probe failure (script bug — gate is false-green or false-red).
#
# Usage:  bash .factory/hooks/verify-module-name-consistency.sh
# Called: run_advisory in pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
BC_DIR="$FACTORY_DIR/specs/behavioral-contracts"
STORIES_DIR="$FACTORY_DIR/stories/stories"
MODULE_DECOMP="$FACTORY_DIR/specs/architecture/module-decomposition.md"

PASS=0
WARN=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
  esac
}

# ── Core Python scanner ────────────────────────────────────────────────────────
# Arguments:
#   $1: module_decomp_path
#   $2: bc_dir
#   $3: stories_dir
# Output lines:
#   WARN <source_path>:<context> RULE=R<n> CRATE=<crate> CITED=<path> CANONICAL=<path>|NONE
#   PASS <context>
#   SCAN_MODULES <n>
#   SCAN_BC_FILES <n>
#   SCAN_STORY_FILES <n>
#   TOTAL_WARN <n>
run_consistency_scanner() {
  local module_decomp="$1"
  local bc_dir="$2"
  local stories_dir="$3"
  python3 - "$module_decomp" "$bc_dir" "$stories_dir" <<'PYEOF'
import sys, re
from pathlib import Path
from collections import defaultdict

module_decomp_path = Path(sys.argv[1])
bc_dir = Path(sys.argv[2])
stories_dir = Path(sys.argv[3])

# ─── Crate namespace → crate directory prefix map ────────────────────────────
CRATE_NAMESPACE = {
    'core':          'pregolya-core',
    'graph':         'pregolya-graph',
    'checkpoint':    'pregolya-checkpoint',
    'server':        'pregolya-server',
    'sandbox':       'pregolya-sandbox',
    'splitters':     'pregolya-splitters',
    'mcp':           'pregolya-mcp',
    'memory':        'pregolya-memory',
    'macros':        'pregolya-macros',
    'prompts':       'pregolya-prompts',
    'vectorstores':  'pregolya-vectorstores',
    'tools':         'pregolya-tools',
    'eval':          'pregolya-standard-tests',
    'openai':        'pregolya-openai',
    'ollama':        'pregolya-ollama',
    'anthropic':     'pregolya-anthropic',
}

# ─── Parse module-decomposition.md ───────────────────────────────────────────
# Extract module table rows: `` `ns::name` `` | description | criticality | ...
# From the description cell, extract any explicitly-declared file paths
# (pregolya-X/src/Y.rs or pregolya-X/src/Y/).

FILE_PATH_RE = re.compile(r'`(pregolya-[a-z-]+/src/[^`]+)`')
MODULE_ROW_RE = re.compile(r'^\|\s*`([a-z_]+::[a-z_]+)`\s*\|(.*?)\|([^|]*)\|')

# Criticality values that require mandatory BC/story coverage (R2)
HIGH_CRITICALITY = {'CRITICAL', 'HIGH'}

class ModuleInfo:
    __slots__ = ('module', 'crate', 'canonical_paths', 'criticality', 'explicit')
    def __init__(self, module, crate, canonical_paths, criticality, explicit):
        self.module = module
        self.crate = crate
        self.canonical_paths = canonical_paths  # list of str
        self.criticality = criticality
        self.explicit = explicit  # True if any path was declared explicitly in description

modules = []     # list of ModuleInfo
# crate → set of canonical paths (explicit only)
crate_explicit_canonicals = defaultdict(set)

decomp_text = module_decomp_path.read_text(encoding='utf-8')
for line in decomp_text.splitlines():
    m = MODULE_ROW_RE.match(line)
    if not m:
        continue
    mod_name = m.group(1)          # e.g. "mcp::client"
    description = m.group(2)       # pipe table description cell
    criticality_raw = m.group(3).strip()

    ns = mod_name.split('::')[0]
    crate = CRATE_NAMESPACE.get(ns)
    if not crate:
        continue  # unknown namespace — skip

    # Extract file paths explicitly declared in the description cell
    explicit_paths = FILE_PATH_RE.findall(description)

    # Derive canonical path from module name convention if no explicit path
    if explicit_paths:
        canonical_paths = explicit_paths
        explicit = True
        for p in explicit_paths:
            crate_explicit_canonicals[crate].add(p)
    else:
        # Derive: namespace::module_name → pregolya-CRATE/src/module_name.rs
        module_part = mod_name.split('::')[1]
        derived = f"{crate}/src/{module_part}.rs"
        canonical_paths = [derived]
        explicit = False

    # Normalize criticality: strip leading/trailing whitespace, take first word
    crit_word = criticality_raw.split()[0] if criticality_raw.split() else '—'

    modules.append(ModuleInfo(mod_name, crate, canonical_paths, crit_word, explicit))

scan_modules = len(modules)

# Crates that have at least one explicit canonical path — only these are checked
# to avoid false positives from supplementary implementation files.
canonicalized_crates = set(crate_explicit_canonicals.keys())

# ─── Scan BCs for §Architecture Anchors ──────────────────────────────────────
ANCHOR_H2_RE = re.compile(r'^##\s+Architecture\s+Anchors?\s*$', re.IGNORECASE)

def extract_anchor_paths(text: str) -> list:
    """Return all `pregolya-X/src/...` paths from §Architecture Anchors section."""
    results = []
    in_anchors = False
    for line in text.splitlines():
        if ANCHOR_H2_RE.match(line):
            in_anchors = True
            continue
        if in_anchors and line.startswith('##'):
            break  # next section
        if in_anchors:
            for p in FILE_PATH_RE.findall(line):
                results.append(p)
    return results

# crate → list of (path, source_file)
bc_crate_paths = defaultdict(list)
bc_files_scanned = 0
for bc_file in sorted(bc_dir.rglob('*.md')):
    if bc_file.name == 'BC-INDEX.md':
        continue
    text = bc_file.read_text(encoding='utf-8', errors='replace')
    for p in extract_anchor_paths(text):
        crate = p.split('/')[0] if '/' in p else ''
        if crate:
            bc_crate_paths[crate].append((p, str(bc_file.relative_to(bc_dir))))
    bc_files_scanned += 1

# ─── Scan stories for §File Structure and §Architecture Mapping ───────────────
FILE_STRUCT_RE = re.compile(r'^##\s+File\s+Structure\s+Requirements', re.IGNORECASE)
ARCH_MAP_RE = re.compile(r'^##\s+Architecture\s+Mapping', re.IGNORECASE)

def extract_story_paths(text: str) -> list:
    """Return all `pregolya-X/src/...` paths from story file-structure/arch-mapping sections."""
    results = []
    in_section = False
    for line in text.splitlines():
        if FILE_STRUCT_RE.match(line) or ARCH_MAP_RE.match(line):
            in_section = True
            continue
        if in_section and line.startswith('##'):
            in_section = False
        if in_section:
            for p in FILE_PATH_RE.findall(line):
                results.append(p)
    return results

# crate → list of (path, source_file)
story_crate_paths = defaultdict(list)
story_files_scanned = 0
for story_file in sorted(stories_dir.glob('STORY-*.md')):
    text = story_file.read_text(encoding='utf-8', errors='replace')
    for p in extract_story_paths(text):
        crate = p.split('/')[0] if '/' in p else ''
        if crate:
            story_crate_paths[crate].append((p, story_file.name))
    story_files_scanned += 1

# ─── Cross-check ─────────────────────────────────────────────────────────────
warnings = []

# R1 — STALE-FILE: cited path is NOT in the canonical set for its crate
# Only check crates that have been explicitly canonicalized.
for crate in canonicalized_crates:
    canonical_set = crate_explicit_canonicals[crate]
    cited_sources = []
    for (p, src) in bc_crate_paths.get(crate, []):
        cited_sources.append((p, src, 'BC'))
    for (p, src) in story_crate_paths.get(crate, []):
        cited_sources.append((p, src, 'STORY'))

    for (cited_path, source, kind) in cited_sources:
        if cited_path not in canonical_set:
            # Find the closest canonical path (same crate, check if any share the stem)
            stem = cited_path.rstrip('/').rsplit('/', 1)[-1].replace('.rs', '')
            closest = [c for c in canonical_set if stem in c or c.endswith(f"{stem}.rs") or c.endswith(f"{stem}/")]
            canonical_hint = closest[0] if closest else f"(see module-decomposition.md §{crate})"
            warnings.append((
                'R1',
                f"{kind}:{source}",
                crate,
                cited_path,
                canonical_hint,
                f"STALE-FILE — cited path not in canonical set for {crate}; nearest: {canonical_hint}",
            ))

# R2 — MISSING-COVERAGE: explicit canonical path with zero citations in BCs or stories
# Only for HIGH/CRITICAL modules.
all_bc_paths = set(p for crate_list in bc_crate_paths.values() for (p, _) in crate_list)
all_story_paths = set(p for crate_list in story_crate_paths.values() for (p, _) in crate_list)

for mod in modules:
    if not mod.explicit:
        continue  # only check explicitly-declared canonical paths
    if mod.criticality not in HIGH_CRITICALITY:
        continue
    for cp in mod.canonical_paths:
        if cp not in all_bc_paths and cp not in all_story_paths:
            warnings.append((
                'R2',
                f"MODULE:{mod.module}",
                mod.crate,
                cp,
                '',
                f"MISSING-COVERAGE — canonical path {cp!r} for {mod.criticality} module {mod.module!r} cited in zero BCs or stories",
            ))

# R3 — BC-STORY-MISMATCH: same crate, BC cites path A, story cites path B with same stem
# (singular vs plural or same-area rename).
for crate in canonicalized_crates:
    bc_paths_set = {p for (p, _) in bc_crate_paths.get(crate, [])}
    story_paths_set = {p for (p, _) in story_crate_paths.get(crate, [])}

    # Group paths by directory prefix (everything before the final component)
    def path_dir(p):
        parts = p.rstrip('/').rsplit('/', 1)
        return parts[0] if len(parts) > 1 else ''

    def path_stem(p):
        return p.rstrip('/').rsplit('/', 1)[-1].replace('.rs', '')

    # Build stem → {paths} for BC and story separately
    bc_stems = defaultdict(set)
    for p in bc_paths_set:
        if path_dir(p).endswith('/src') or '/src/' in p:
            bc_stems[path_stem(p)].add(p)
    story_stems = defaultdict(set)
    for p in story_paths_set:
        if path_dir(p).endswith('/src') or '/src/' in p:
            story_stems[path_stem(p)].add(p)

    # Find near-mismatches: stem differs only in trailing 's' or prefix match
    bc_stem_list = sorted(bc_stems.keys())
    story_stem_list = sorted(story_stems.keys())
    for bs in bc_stem_list:
        for ss in story_stem_list:
            if bs == ss:
                continue  # same stem — fine
            # Detect singular/plural mismatch: bs == ss+'s' or ss == bs+'s'
            if bs == ss + 's' or ss == bs + 's':
                bc_path = sorted(bc_stems[bs])[0]
                story_path = sorted(story_stems[ss])[0]
                warnings.append((
                    'R3',
                    f"BC↔STORY:{crate}",
                    crate,
                    bc_path,
                    story_path,
                    f"BC-STORY-MISMATCH — BC cites {bc_path!r}, story cites {story_path!r} (singular/plural divergence)",
                ))

# ─── Emit output ─────────────────────────────────────────────────────────────
# Deduplicate warnings on (rule, cited, source)
seen_warn_keys = set()
unique_warnings = []
for w in warnings:
    key = (w[0], w[3], w[1])
    if key not in seen_warn_keys:
        seen_warn_keys.add(key)
        unique_warnings.append(w)

for (rule, source, crate, cited, canonical, message) in unique_warnings:
    print(f"WARN {source} RULE={rule} CRATE={crate} CITED={cited!r} CANONICAL={canonical!r}")
    print(f"     {message}")

if not unique_warnings:
    print(f"PASS all canonicalized crates have consistent BC/story file citations")

print(f"SCAN_MODULES {scan_modules}")
print(f"SCAN_BC_FILES {bc_files_scanned}")
print(f"SCAN_STORY_FILES {story_files_scanned}")
print(f"TOTAL_WARN {len(unique_warnings)}")
PYEOF
}

# ── Probe infrastructure (POL-30/POL-31) ──────────────────────────────────────
PROBE_TMP=""

init_probe_tmp() {
  PROBE_TMP="$(mktemp -d)"
}

clean_probe_tmp() {
  if [ -n "$PROBE_TMP" ] && [ -d "$PROBE_TMP" ]; then
    rm -rf "$PROBE_TMP"
  fi
  PROBE_TMP=""
}

# Run the scanner against probe fixtures.
# $1: probe_module_decomp_file (temp path)
# $2: probe_bc_dir
# $3: probe_stories_dir
run_probe_scan() {
  python3 - "$1" "$2" "$3" <<'PROBESCANEOF'
import sys, re
from pathlib import Path
from collections import defaultdict

module_decomp_path = Path(sys.argv[1])
bc_dir = Path(sys.argv[2])
stories_dir = Path(sys.argv[3])

CRATE_NAMESPACE = {
    'core': 'pregolya-core',
    'mcp': 'pregolya-mcp',
    'graph': 'pregolya-graph',
    'probe': 'pregolya-probe',   # probe namespace for self-tests
}

FILE_PATH_RE = re.compile(r'`(pregolya-[a-z-]+/src/[^`]+)`')
MODULE_ROW_RE = re.compile(r'^\|\s*`([a-z_]+::[a-z_]+)`\s*\|(.*?)\|([^|]*)\|')

crate_explicit_canonicals = defaultdict(set)
modules_info = []

text = module_decomp_path.read_text(encoding='utf-8', errors='replace')
for line in text.splitlines():
    m = MODULE_ROW_RE.match(line)
    if not m:
        continue
    mod_name = m.group(1)
    description = m.group(2)
    criticality_raw = m.group(3).strip()
    ns = mod_name.split('::')[0]
    crate = CRATE_NAMESPACE.get(ns)
    if not crate:
        continue
    explicit_paths = FILE_PATH_RE.findall(description)
    if explicit_paths:
        for p in explicit_paths:
            crate_explicit_canonicals[crate].add(p)

canonicalized_crates = set(crate_explicit_canonicals.keys())

ANCHOR_H2_RE = re.compile(r'^##\s+Architecture\s+Anchors?\s*$', re.IGNORECASE)

def extract_anchor_paths(text):
    results = []
    in_anchors = False
    for line in text.splitlines():
        if ANCHOR_H2_RE.match(line):
            in_anchors = True
            continue
        if in_anchors and line.startswith('##'):
            break
        if in_anchors:
            for p in FILE_PATH_RE.findall(line):
                results.append(p)
    return results

bc_crate_paths = defaultdict(list)
for bc_file in sorted(bc_dir.rglob('*.md')):
    t = bc_file.read_text(encoding='utf-8', errors='replace')
    for p in extract_anchor_paths(t):
        crate = p.split('/')[0] if '/' in p else ''
        if crate:
            bc_crate_paths[crate].append((p, bc_file.name))

warnings = []
for crate in canonicalized_crates:
    canonical_set = crate_explicit_canonicals[crate]
    for (cited_path, source) in bc_crate_paths.get(crate, []):
        if cited_path not in canonical_set:
            stem = cited_path.rstrip('/').rsplit('/', 1)[-1].replace('.rs', '')
            closest = [c for c in canonical_set if stem in c or c.endswith(f"{stem}.rs")]
            canonical_hint = closest[0] if closest else f"(see module-decomposition for {crate})"
            warnings.append(f"WARN BC:{source} R1 CRATE={crate} CITED={cited_path!r} CANONICAL={canonical_hint!r}")

for w in warnings:
    print(w)
if not warnings:
    print("PASS no R1 stale-file findings in probe corpus")
print(f"TOTAL_WARN {len(warnings)}")
PROBESCANEOF
}

# ── Self-probes (POL-31) ───────────────────────────────────────────────────────

# Positive probe: synthetic module probe::widget → canonical pregolya-probe/src/widget.rs
# BC cites pregolya-probe/src/widgets.rs (wrong — plural stem) → R1 WARN expected
probe_mnc_pos_stale_file() {
  init_probe_tmp
  local probe_md_dir="$PROBE_TMP/probe-md"
  local probe_bc_dir="$PROBE_TMP/probe-bc"
  local probe_stories_dir="$PROBE_TMP/probe-stories"
  mkdir -p "$probe_md_dir" "$probe_bc_dir" "$probe_stories_dir"

  # Synthetic module-decomposition.md with explicit canonical path
  cat > "$probe_md_dir/module-decomposition.md" <<'MDEOF'
---
document_type: architecture-section
version: "0.1"
---
# Module Decomposition: probe

## pregolya-probe (SS-00) — MEDIUM

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `probe::widget` | Widget implementation; canonical file: `pregolya-probe/src/widget.rs` | HIGH | SS-00 |
MDEOF

  # BC with WRONG path (plural form)
  cat > "$probe_bc_dir/BC-PROBE-001.md" <<'BCEOF'
---
document_type: behavioral-contract
---
## Architecture Anchors

- `pregolya-probe/src/widgets.rs` — `WidgetFactory`, `build_widget`
BCEOF

  local hits
  hits="$(run_probe_scan "$probe_md_dir/module-decomposition.md" "$probe_bc_dir" "$probe_stories_dir")"
  local warn_count
  warn_count="$(echo "$hits" | grep '^TOTAL_WARN' | awk '{print $2}')"
  if [ "${warn_count:-0}" -eq 0 ]; then
    echo "[SELF-PROBE FAIL] probe_mnc_pos_stale_file: expected R1 WARN for stale 'widgets.rs' but got 0 warnings"
    clean_probe_tmp
    exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_mnc_pos_stale_file: stale 'widgets.rs' vs canonical 'widget.rs' → R1 WARN produced"
}

# Negative probe: same canonical, BC cites the CORRECT canonical path → no R1 WARN
probe_mnc_neg_aligned() {
  init_probe_tmp
  local probe_md_dir="$PROBE_TMP/probe-md"
  local probe_bc_dir="$PROBE_TMP/probe-bc"
  local probe_stories_dir="$PROBE_TMP/probe-stories"
  mkdir -p "$probe_md_dir" "$probe_bc_dir" "$probe_stories_dir"

  cat > "$probe_md_dir/module-decomposition.md" <<'MDEOF'
---
document_type: architecture-section
version: "0.1"
---
# Module Decomposition: probe

## pregolya-probe (SS-00) — MEDIUM

| Module | Responsibility | Criticality | SS |
|--------|---------------|-------------|-----|
| `probe::widget` | Widget implementation; canonical file: `pregolya-probe/src/widget.rs` | HIGH | SS-00 |
MDEOF

  # BC with CORRECT canonical path
  cat > "$probe_bc_dir/BC-PROBE-001.md" <<'BCEOF'
---
document_type: behavioral-contract
---
## Architecture Anchors

- `pregolya-probe/src/widget.rs` — `WidgetFactory`, `build_widget`
BCEOF

  local hits
  hits="$(run_probe_scan "$probe_md_dir/module-decomposition.md" "$probe_bc_dir" "$probe_stories_dir")"
  local warn_count
  warn_count="$(echo "$hits" | grep '^TOTAL_WARN' | awk '{print $2}')"
  if [ "${warn_count:-0}" -ne 0 ]; then
    echo "[SELF-PROBE FAIL] probe_mnc_neg_aligned: expected 0 R1 warnings for aligned canonical path but got ${warn_count}"
    echo "$hits"
    clean_probe_tmp
    exit 2
  fi
  clean_probe_tmp
  echo "[SELF-PROBE PASS] probe_mnc_neg_aligned: aligned 'widget.rs' → no R1 WARN"
}

# ── MAIN ──────────────────────────────────────────────────────────────────────

echo "[SELF-PROBE] Running POL-31 self-probes (gate correctness guards)..."
probe_mnc_pos_stale_file
probe_mnc_neg_aligned
echo "[SELF-PROBE] Both self-probes passed — gate is not false-green."
echo ""

echo "── verify-module-name-consistency (advisory) ────────────────────────────"
echo "Scanning: $MODULE_DECOMP"
echo "BC dir:   $BC_DIR"
echo "Story dir: $STORIES_DIR"
echo ""

raw_output="$(run_consistency_scanner "$MODULE_DECOMP" "$BC_DIR" "$STORIES_DIR")"

# Parse SCAN_* and TOTAL_WARN from output
scan_modules="$(echo "$raw_output" | grep '^SCAN_MODULES' | awk '{print $2}')"
scan_bc="$(echo "$raw_output"      | grep '^SCAN_BC_FILES' | awk '{print $2}')"
scan_story="$(echo "$raw_output"   | grep '^SCAN_STORY_FILES' | awk '{print $2}')"
total_warn="$(echo "$raw_output"   | grep '^TOTAL_WARN' | awk '{print $2}')"

# Emit WARN/PASS lines
while IFS= read -r line; do
  case "$line" in
    WARN*)
      # WARN line — strip WARN prefix then emit
      msg="${line#WARN }"
      emit "WARN" "$msg"
      ;;
    "     "*)
      # Continuation (detail line) — print as-is
      echo "$line"
      ;;
    PASS*)
      msg="${line#PASS }"
      emit "PASS" "$msg"
      ;;
  esac
done <<< "$raw_output"

echo ""
echo "── Summary ──────────────────────────────────────────────────────────────"
echo "  Modules scanned:      ${scan_modules:-0}"
echo "  BC files scanned:     ${scan_bc:-0}"
echo "  Story files scanned:  ${scan_story:-0}"
echo "  WARN: ${WARN}   PASS: ${PASS}"

if [ "${WARN:-0}" -gt 0 ]; then
  echo ""
  echo "ADVISORY: ${WARN} module-file consistency finding(s). Routing:"
  echo "  R1 STALE-FILE    → product-owner (BC §Architecture Anchors update)"
  echo "                     story-writer  (story §File Structure / §Architecture Mapping update)"
  echo "  R2 MISSING-COVERAGE → product-owner (add canonical path to BC §Architecture Anchors)"
  echo "  R3 BC-STORY-MISMATCH → product-owner + story-writer (align file citations)"
fi

# Advisory exit — never block the commit
exit 0
