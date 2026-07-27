#!/usr/bin/env bash
# verify-module-canonicality.sh — ferrochain factory-artifacts ADVISORY validator
#
# PURPOSE
# ───────
# Verifies that every Module cell in every module-keyed table across four primary
# documents (plus the VP family) follows the canonical `crate_component::module_name`
# form (`^[a-z_]+::[a-z_]+$`) OR is an ARCH-INDEX canonical-roster crate name
# (for crate-level roll-up rows such as `ferrochain-macros`).
#
# Four primary documents for module-census and set-equality:
#   1. specs/architecture/module-decomposition.md  (canonical reference)
#   2. specs/architecture/purity-boundary-map.md
#   3. specs/architecture/verification-coverage-matrix.md
#   4. specs/module-criticality.md
#
# VP family (module column check only — not included in 4-way set equality):
#   5. specs/verification-properties/VP-INDEX.md
#   6. specs/architecture/verification-architecture.md
#
# Known current non-canonical counts (FIX-BURST-276 WARN baseline):
#   verification-coverage-matrix.md: 36 of 77 non-canonical Module cells
#   VP-INDEX.md: 13 of 13 VP catalog rows use short-form dialect
#   verification-architecture.md Committed VP Obligations: 13 of 13 rows
#   module-decomposition.md: 0 (already canonical)
#   purity-boundary-map.md: 0 (already canonical)
#   module-criticality.md: see runtime output
#
# PARSER CAUTION
# ──────────────
# Tables in module-decomposition.md have three different column arities:
#   3-col (Provider Crates section — excluded; no Module header)
#   4-col (most module tables)
#   5-col (Provider Embeddings, extra Crate column)
# Column index for "Module" is derived from each table's header row at runtime;
# never hardcoded. The Provider Crates crate-role table (header: "| Crate | Role |...")
# has no "Module" column and is naturally excluded.
#
# ADVISORY STATUS
# ───────────────
# All findings are WARN (non-blocking) in Wave A of FIX-BURST-276.
# Promotion to blocking after Wave B closes finding IDs:
#   P1D-173-CHECK4-vcm (36 non-canonical in verification-coverage-matrix.md)
#   P1D-173-CHECK4-vp-index (13 non-canonical in VP-INDEX.md)
#   P1D-173-CHECK4-vp-arch (13 non-canonical in verification-architecture.md)
#   P1D-173-CHECK4-mcrit (non-canonical in module-criticality.md)
# Target burst for promotion: Wave B (module name canonicalization burst).
#
# EXIT CONTRACT
# ─────────────
# Always exits 0 (advisory — non-blocking). WARN count reflects violations.
#
# Usage:  bash .factory/hooks/verify-module-canonicality.sh
# Exit:   0 always (advisory)

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"

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

# ── Python3 inline processor ──────────────────────────────────────────────────

PYTHON_OUTPUT="$(python3 - "$FACTORY_DIR" <<'PYEOF'
import sys, os, re, glob

factory_dir = sys.argv[1]

# ── Step 1: Extract canonical crate names from ARCH-INDEX.md ─────────────────
arch_index_path = os.path.join(factory_dir, 'specs/architecture/ARCH-INDEX.md')
canonical_crates = set()
try:
    with open(arch_index_path, 'r', encoding='utf-8') as fh:
        arch_content = fh.read()
    # Match rows: | N | ferrochain-XXX | Origin | ... or | — | xtask | ...
    for m in re.finditer(r'^\|\s*(?:\d+|—)\s*\|\s*([a-z][a-zA-Z0-9_-]+)\s*\|', arch_content, re.MULTILINE):
        name = m.group(1).strip()
        if name and not name.startswith('#'):
            canonical_crates.add(name)
except OSError as e:
    print(f"ERROR cannot read ARCH-INDEX.md: {e}")
    sys.exit(1)

# ── Step 2: Module canonicality check ────────────────────────────────────────

CANONICAL_RE = re.compile(r'^[a-z_]+::[a-z_][a-z_0-9]*$')

def is_canonical(name, canonical_crates):
    """True if name matches ^[a-z_]+::[a-z_0-9]+$ OR is a canonical crate name."""
    if CANONICAL_RE.match(name):
        return True
    if name in canonical_crates:
        return True
    return False

def extract_module_from_cell(cell):
    """
    Extract the module name from a table cell.
    - If cell starts with a backtick, extract the backtick-quoted content.
    - Otherwise, return the raw cell content.
    - Trailing qualifier text outside backticks (e.g. " (reducer stage)") is stripped.
    """
    cell = cell.strip()
    # Backtick-wrapped: `module::name` possibly followed by qualifier text
    m = re.match(r'^`([^`]+)`', cell)
    if m:
        return m.group(1).strip()
    # Plain text: return as-is (strip trailing parenthetical qualifier)
    # e.g. "bsp-engine" stays "bsp-engine"; "server handlers" stays "server handlers"
    return cell.strip()

def parse_frontmatter_end(lines):
    """Return 0-indexed closing '---' line, or -1 if no valid frontmatter."""
    if not lines or lines[0].rstrip() != '---':
        return -1
    for i in range(1, len(lines)):
        if lines[i].rstrip() == '---':
            return i
    return -1

def is_separator_row(cells):
    """True if all cells look like a markdown table separator (---:---:---)."""
    return all(
        len(c.strip()) > 0 and all(ch in '-: ' for ch in c.strip())
        for c in cells if c.strip()
    )

def extract_modules_from_file(filepath, exclude_sections=None, exclude_header_patterns=None):
    """
    Extract (module_name, line_number, table_header) tuples from all
    module-keyed tables in the file. A module-keyed table is one whose
    header row contains 'Module' as a column.

    exclude_sections: set of section heading substrings to skip
    exclude_header_patterns: list of regex patterns; tables whose first-cell
                             header matches any of these are skipped
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError as e:
        print(f"ERROR cannot read {filepath}: {e}")
        return []

    fm_end = parse_frontmatter_end(lines)
    results = []
    current_section = ''
    in_excluded_section = False
    module_col_idx = None
    table_header_cols = None
    in_table = False

    for lineno, line in enumerate(lines, 1):
        raw = line.rstrip('\n')

        # Track section headings (H2 level)
        if raw.startswith('## '):
            current_section = raw.strip()
            in_excluded_section = False
            if exclude_sections:
                for excl in exclude_sections:
                    if excl in current_section:
                        in_excluded_section = True
                        break
            # Reset table state when entering a new section
            module_col_idx = None
            table_header_cols = None
            in_table = False
            continue

        if in_excluded_section:
            module_col_idx = None
            in_table = False
            continue

        # Only look at table lines
        if not raw.strip().startswith('|'):
            if in_table and raw.strip() == '':
                pass  # blank lines between table rows are OK
            else:
                module_col_idx = None
                table_header_cols = None
                in_table = False
            continue

        # Parse cells (strip leading/trailing | and split)
        parts = raw.split('|')
        # Cells are between the first and last |
        if len(parts) < 3:
            continue
        cells = [c.strip() for c in parts[1:-1]]
        if not cells:
            continue

        # Separator row detection
        if is_separator_row(cells):
            continue

        # Header row: look for 'Module' as one of the column headers
        # (the word "Module" stripped of backticks, case-sensitive)
        header_cells_clean = [c.strip('`').strip() for c in cells]
        if not in_table:
            if 'Module' in header_cells_clean:
                # Check exclude_header_patterns on first cell
                first_header = header_cells_clean[0]
                if exclude_header_patterns:
                    skip = False
                    for pat in exclude_header_patterns:
                        if re.search(pat, first_header, re.IGNORECASE):
                            skip = True
                            break
                    if skip:
                        module_col_idx = None
                        continue
                module_col_idx = header_cells_clean.index('Module')
                table_header_cols = list(header_cells_clean)
                in_table = True
                continue
            else:
                # Not a module-keyed table
                module_col_idx = None
                in_table = False
                continue

        # Data row: extract the Module column
        if module_col_idx is not None and module_col_idx < len(cells):
            raw_cell = cells[module_col_idx]
            module_name = extract_module_from_cell(raw_cell)
            # Skip empty, "—", or summary/tier rows
            if not module_name or module_name in ('—', ''):
                continue
            # Skip rows that look like tier-summary rows (CRITICAL/HIGH/MEDIUM/LOW)
            if module_name in ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW'):
                continue
            # Skip the header row if it reappears
            if module_name == 'Module':
                continue
            results.append((module_name, lineno, table_header_cols[module_col_idx] if table_header_cols else 'Module'))

    return results

# ── Step 3: Process each document ─────────────────────────────────────────────

DOCS = [
    {
        'key': 'module-decomposition',
        'path': os.path.join(factory_dir, 'specs/architecture/module-decomposition.md'),
        'exclude_sections': {'Provider Crates and Standard Tests'},
        'exclude_header_patterns': [r'^Crate$'],
        'in_4way_join': True,
        'label': 'module-decomposition.md',
    },
    {
        'key': 'purity-boundary-map',
        'path': os.path.join(factory_dir, 'specs/architecture/purity-boundary-map.md'),
        'exclude_sections': set(),
        'exclude_header_patterns': [],
        'in_4way_join': True,
        'label': 'purity-boundary-map.md',
    },
    {
        'key': 'verification-coverage-matrix',
        'path': os.path.join(factory_dir, 'specs/architecture/verification-coverage-matrix.md'),
        'exclude_sections': set(),
        'exclude_header_patterns': [],
        'in_4way_join': True,
        'label': 'verification-coverage-matrix.md',
    },
    {
        'key': 'module-criticality',
        'path': os.path.join(factory_dir, 'specs/module-criticality.md'),
        'exclude_sections': set(),
        'exclude_header_patterns': [],
        'in_4way_join': True,
        'label': 'module-criticality.md',
    },
    {
        'key': 'vp-index',
        'path': os.path.join(factory_dir, 'specs/verification-properties/VP-INDEX.md'),
        'exclude_sections': set(),
        'exclude_header_patterns': [],
        'in_4way_join': False,
        'label': 'VP-INDEX.md (VP catalog)',
    },
    {
        'key': 'verification-architecture',
        'path': os.path.join(factory_dir, 'specs/architecture/verification-architecture.md'),
        'exclude_sections': set(),
        'exclude_header_patterns': [],
        'in_4way_join': False,
        'label': 'verification-architecture.md (Committed VP Obligations)',
    },
]

doc_results = {}  # key → list of (module_name, lineno, col_header)
doc_canonical_sets = {}  # key → set of canonical module names (for 4-way join)

for doc in DOCS:
    key = doc['key']
    entries = extract_modules_from_file(
        doc['path'],
        exclude_sections=doc['exclude_sections'],
        exclude_header_patterns=doc['exclude_header_patterns'],
    )
    doc_results[key] = entries

    non_canonical = []
    canonical_names = set()
    for (name, lineno, col_hdr) in entries:
        if is_canonical(name, canonical_crates):
            canonical_names.add(name)
        else:
            non_canonical.append((name, lineno))

    doc_canonical_sets[key] = canonical_names

    total = len(entries)
    nc_count = len(non_canonical)

    print(f"DOC-SUMMARY key={key} total={total} non-canonical={nc_count} label={doc['label']}")
    if nc_count > 0:
        for (name, lineno) in non_canonical[:20]:  # cap report at 20 per doc
            print(f"NON-CANONICAL key={key} line={lineno} name={name!r}")
        if nc_count > 20:
            print(f"NON-CANONICAL-TRUNCATED key={key} additional={nc_count - 20}")

# ── Step 4: 4-way set equality (primary documents only) ───────────────────────

join_keys = [d['key'] for d in DOCS if d['in_4way_join']]
join_labels = {d['key']: d['label'] for d in DOCS if d['in_4way_join']}

# Use module-decomposition as the canonical reference
decomp_set = doc_canonical_sets.get('module-decomposition', set())
decomp_total = len(doc_results.get('module-decomposition', []))
reg_total = len(doc_results.get('module-criticality', []))

# Compute pairwise differences against decomposition
differences_found = False
for key in join_keys:
    if key == 'module-decomposition':
        continue
    other_set = doc_canonical_sets.get(key, set())
    in_decomp_not_other = decomp_set - other_set
    in_other_not_decomp = other_set - decomp_set
    if in_decomp_not_other or in_other_not_decomp:
        differences_found = True
        if in_decomp_not_other:
            names = sorted(in_decomp_not_other)[:10]
            trunc = ' ...' if len(in_decomp_not_other) > 10 else ''
            print(f"SET-DIFF key={key} direction=in-decomp-not-here "
                  f"count={len(in_decomp_not_other)} names={names}{trunc}")
        if in_other_not_decomp:
            names = sorted(in_other_not_decomp)[:10]
            trunc = ' ...' if len(in_other_not_decomp) > 10 else ''
            print(f"SET-DIFF key={key} direction=in-here-not-decomp "
                  f"count={len(in_other_not_decomp)} names={names}{trunc}")

# Emit the required runtime-computed census line
diff_label = 'empty' if not differences_found else 'NON-EMPTY (see WARN lines)'
print(f"CENSUS 4-documents={len(join_keys)} "
      f"decomposition-modules={decomp_total} "
      f"registry-rows={reg_total} "
      f"canonical-in-decomposition={len(decomp_set)} "
      f"difference-set={diff_label}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

TOTAL_NON_CANONICAL=0
CENSUS_LINE=""

while IFS= read -r line; do
  tag="${line%% *}"
  rest="${line#* }"

  case "$tag" in
    DOC-SUMMARY)
      # Parse: key=... total=... non-canonical=... label=...
      key="$(echo "$rest" | grep -oE 'key=[^ ]+' | cut -d= -f2)"
      total="$(echo "$rest" | grep -oE 'total=[^ ]+' | cut -d= -f2)"
      nc="$(echo "$rest" | grep -oE 'non-canonical=[^ ]+' | cut -d= -f2)"
      label="$(echo "$rest" | sed 's/.*label=//')"
      TOTAL_NON_CANONICAL=$((TOTAL_NON_CANONICAL + nc))
      if [ "$nc" -gt 0 ]; then
        emit WARN "[ADVISORY] CHECK4: $label — $nc of $total Module cells non-canonical (should match ^[a-z_]+::[a-z_]+\$ or be a canonical crate name)"
      else
        emit PASS "CHECK4: $label — all $total Module cells canonical"
      fi
      ;;
    NON-CANONICAL)
      key="$(echo "$rest" | grep -oE 'key=[^ ]+' | cut -d= -f2)"
      lineno="$(echo "$rest" | grep -oE 'line=[^ ]+' | cut -d= -f2)"
      name="$(echo "$rest" | sed "s/.*name=//" | tr -d "'")"
      echo "  [ADVISORY] CHECK4: $key line $lineno — non-canonical module name $name"
      ;;
    NON-CANONICAL-TRUNCATED)
      key="$(echo "$rest" | grep -oE 'key=[^ ]+' | cut -d= -f2)"
      additional="$(echo "$rest" | grep -oE 'additional=[^ ]+' | cut -d= -f2)"
      echo "  [ADVISORY] CHECK4: $key — ($additional more non-canonical names not shown)"
      ;;
    SET-DIFF)
      direction="$(echo "$rest" | grep -oE 'direction=[^ ]+' | cut -d= -f2)"
      key="$(echo "$rest" | grep -oE 'key=[^ ]+' | cut -d= -f2)"
      count="$(echo "$rest" | grep -oE 'count=[^ ]+' | cut -d= -f2)"
      names="$(echo "$rest" | sed 's/.*names=//')"
      emit WARN "[ADVISORY] CHECK4 set-diff: $key $direction ($count modules) — $names"
      ;;
    CENSUS)
      CENSUS_LINE="$rest"
      ;;
    ERROR)
      emit WARN "CHECK4 internal error: $rest"
      ;;
    *)
      # Unexpected output — ignore silently (may be Python traceback lines)
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Print the runtime census line (positive coverage proof) ──────────────────

echo ""
echo "  Module census: $CENSUS_LINE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-module-canonicality: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  Total non-canonical Module cells detected: $TOTAL_NON_CANONICAL"
echo ""
echo "Promotion path (advisory → blocking):"
echo "  P1D-173-CHECK4-vcm:    fix 36 non-canonical cells in verification-coverage-matrix.md"
echo "  P1D-173-CHECK4-vp:     fix 13 non-canonical cells in VP-INDEX.md"
echo "  P1D-173-CHECK4-vparch: fix 13 non-canonical cells in verification-architecture.md"
echo "  P1D-173-CHECK4-mcrit:  fix non-canonical cells in module-criticality.md"
echo "  All four must close before promotion to blocking. Target burst: Wave B."
echo ""
echo "RESULT: PASS (advisory — non-blocking)"
# Always exit 0 — advisory check
exit 0
