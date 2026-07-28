#!/usr/bin/env bash
# verify-module-canonicality.sh — ferrochain factory-artifacts BLOCKING validator
#
# PURPOSE
# ───────
# Verifies that every Module cell in every module-keyed table across four primary
# documents (plus the VP family and ARCH-INDEX VP section) follows the canonical
# `crate_component::module_name` form (`^[a-z_]+::[a-z_]+$`) OR is an ARCH-INDEX
# canonical-roster crate name (for crate-level roll-up rows such as `ferrochain-macros`).
#
# Four primary documents for module-census and set-equality:
#   1. specs/architecture/module-decomposition.md  (canonical reference)
#   2. specs/architecture/purity-boundary-map.md
#   3. specs/architecture/verification-coverage-matrix.md
#   4. specs/module-criticality.md
#
# VP family + ARCH-INDEX VP section (module column check only — not 4-way set equality):
#   5. specs/verification-properties/VP-INDEX.md
#   6. specs/architecture/verification-architecture.md
#   7. specs/architecture/ARCH-INDEX.md §Verification Properties section
#
# Gate #25 — crate-level census reverse equation:
#   registry_total_rows − module_level_matched_rows == crate_level_qualifier_rows
#   Where crate-level rows are identified by the Qualifier column prefix "crate-level".
#   A mismatch indicates census drift (a row is missing from the decomposition set or
#   is misclassified as crate-level).
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
# EXIT CONTRACT
# ─────────────
# Exits 1 if any FAIL lines are emitted; exits 0 otherwise.
# Non-canonical cells emit FAIL (blocking). Gate #25 mismatch emits FAIL (blocking).
#
# Usage:  bash .factory/hooks/verify-module-canonicality.sh
# Exit:   1 if FAIL > 0; 0 if FAIL == 0

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
    in_excluded_h2 = False      # True while the enclosing H2 is in exclude_sections
    in_excluded_section = False  # effective exclusion state (can be overridden by H3)
    module_col_idx = None
    table_header_cols = None
    in_table = False

    for lineno, line in enumerate(lines, 1):
        raw = line.rstrip('\n')

        # Track section headings (H2 level)
        if raw.startswith('## '):
            current_section = raw.strip()
            in_excluded_h2 = False
            in_excluded_section = False
            if exclude_sections:
                for excl in exclude_sections:
                    if excl in current_section:
                        in_excluded_h2 = True
                        in_excluded_section = True
                        break
            # Reset table state when entering a new section
            module_col_idx = None
            table_header_cols = None
            in_table = False
            continue

        # An H3 nested inside an excluded H2 re-enables table extraction for
        # that subsection's scope.  Tables without a Module column are already
        # ignored by the natural header-row branch below, so clearing
        # in_excluded_section here is sufficient — only tables whose header row
        # contains a "Module" column will be extracted.  This is the general
        # rule: H3 sections carrying a Module table should never be silently
        # dropped because their parent H2 happens to be excluded.
        if raw.startswith('### ') and in_excluded_h2:
            in_excluded_section = False
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
    {
        'key': 'arch-index-vp',
        'path': os.path.join(factory_dir, 'specs/architecture/ARCH-INDEX.md'),
        'exclude_sections': set(),
        'exclude_header_patterns': [],
        'in_4way_join': False,
        'label': 'ARCH-INDEX.md §Verification Properties',
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
diff_label = 'empty' if not differences_found else 'NON-EMPTY (see FAIL lines)'
print(f"CENSUS 4-documents={len(join_keys)} "
      f"decomposition-modules={decomp_total} "
      f"registry-rows={reg_total} "
      f"canonical-in-decomposition={len(decomp_set)} "
      f"difference-set={diff_label}")

# ── Step 5: Gate #25 — crate-level census reverse equation ────────────────────
#
# module-criticality.md uses two row classes:
#   (a) Module-level rows: Qualifier column is "—" or a non-"crate-level" qualifier.
#       These rows must appear in the module-decomposition canonical set.
#   (b) Crate-level rows: Qualifier column starts with "crate-level" prefix.
#       These are roll-up annotations and are NOT expected in module-decomposition.
#
# Reverse equation (Gate #25):
#   registry_total_rows − module_level_matched_rows == crate_level_qualifier_rows
#
# A mismatch means census drift: either a module-level row is missing from
# decomposition, or a row is misclassified as crate-level.

mcrit_path = os.path.join(factory_dir, 'specs/module-criticality.md')
try:
    with open(mcrit_path, 'r', encoding='utf-8') as fh:
        mcrit_lines = fh.readlines()
except OSError as e:
    print(f"G25-ERROR cannot read module-criticality.md: {e}")
    mcrit_lines = []

# Scan module-criticality.md for Qualifier column presence
# Identify "crate-level" rows by Qualifier column content
CRATE_LEVEL_QUALIFIER_RE = re.compile(r'^crate-level\b', re.IGNORECASE)

crate_level_rows = []   # (module_name, qualifier_text)
module_level_rows = []  # (module_name, qualifier_text) — non-crate-level

if mcrit_lines:
    fm_end_mcrit = parse_frontmatter_end(mcrit_lines)
    qualifier_col_idx = None
    module_col_idx_g25 = None
    in_table_g25 = False

    for lineno, line in enumerate(mcrit_lines, 1):
        raw = line.rstrip('\n')

        # Track section transitions — reset table state
        if raw.startswith('## ') or raw.startswith('### '):
            qualifier_col_idx = None
            module_col_idx_g25 = None
            in_table_g25 = False
            continue

        # Skip frontmatter
        if fm_end_mcrit >= 0 and lineno <= fm_end_mcrit + 1:
            continue

        if not raw.strip().startswith('|'):
            if in_table_g25 and raw.strip() == '':
                pass
            else:
                qualifier_col_idx = None
                module_col_idx_g25 = None
                in_table_g25 = False
            continue

        parts_g25 = raw.split('|')
        if len(parts_g25) < 3:
            continue
        cells_g25 = [c.strip() for c in parts_g25[1:-1]]
        if not cells_g25:
            continue

        # Separator row
        if is_separator_row(cells_g25):
            continue

        header_clean = [c.strip('`').strip() for c in cells_g25]

        if not in_table_g25:
            # Check for a table with both Module and Qualifier columns
            if 'Module' in header_clean and 'Qualifier' in header_clean:
                module_col_idx_g25 = header_clean.index('Module')
                qualifier_col_idx = header_clean.index('Qualifier')
                in_table_g25 = True
                continue
            else:
                continue

        # Data row
        if module_col_idx_g25 is not None and qualifier_col_idx is not None:
            if module_col_idx_g25 < len(cells_g25) and qualifier_col_idx < len(cells_g25):
                raw_mod = cells_g25[module_col_idx_g25]
                raw_qual = cells_g25[qualifier_col_idx]
                mod_name = extract_module_from_cell(raw_mod)
                qual_text = raw_qual.strip()

                # Skip empty, tier-summary, or header-reappearance rows
                if not mod_name or mod_name in ('—', '', 'Module'):
                    continue
                if mod_name in ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW'):
                    continue

                if CRATE_LEVEL_QUALIFIER_RE.match(qual_text):
                    crate_level_rows.append((mod_name, qual_text))
                else:
                    module_level_rows.append((mod_name, qual_text))

crate_level_count = len(crate_level_rows)
module_level_count = len(module_level_rows)
total_g25_rows = crate_level_count + module_level_count

# Matched module-level rows: module-level rows whose Module name is in decomp_set
matched_module_level = [
    (m, q) for (m, q) in module_level_rows
    if m in decomp_set or (CANONICAL_RE.match(m) and m in decomp_set)
]
unmatched_module_level = [
    (m, q) for (m, q) in module_level_rows
    if m not in decomp_set
]

# Reverse equation check
equation_holds = (total_g25_rows - len(matched_module_level) == crate_level_count)
equation_result = (
    f"{total_g25_rows} − {len(matched_module_level)} == {crate_level_count}: "
    + ("PASS" if equation_holds else "FAIL")
)

# Enumerate crate-level row names for audit
crate_level_names = sorted(m for (m, q) in crate_level_rows)
unmatched_names = sorted(m for (m, q) in unmatched_module_level)

print(f"G25-CENSUS total={total_g25_rows} crate-level={crate_level_count} "
      f"module-level={module_level_count} matched={len(matched_module_level)} "
      f"unmatched={len(unmatched_module_level)} equation={equation_result}")
print(f"G25-CRATE-LEVEL names={crate_level_names}")
if unmatched_module_level:
    print(f"G25-UNMATCHED names={unmatched_names}")

PYEOF
)"

# ── Process Python3 output ────────────────────────────────────────────────────

TOTAL_NON_CANONICAL=0
CENSUS_LINE=""
G25_CENSUS_LINE=""
G25_CRATE_LEVEL_LINE=""
G25_UNMATCHED_LINE=""

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
        emit FAIL "CHECK4: $label — $nc of $total Module cells non-canonical (must match ^[a-z_]+::[a-z_]+\$ or be a canonical crate name)"
      else
        emit PASS "CHECK4: $label — all $total Module cells canonical"
      fi
      ;;
    NON-CANONICAL)
      key="$(echo "$rest" | grep -oE 'key=[^ ]+' | cut -d= -f2)"
      lineno="$(echo "$rest" | grep -oE 'line=[^ ]+' | cut -d= -f2)"
      name="$(echo "$rest" | sed "s/.*name=//" | tr -d "'")"
      echo "  CHECK4: $key row near line $lineno — non-canonical module name $name"
      ;;
    NON-CANONICAL-TRUNCATED)
      key="$(echo "$rest" | grep -oE 'key=[^ ]+' | cut -d= -f2)"
      additional="$(echo "$rest" | grep -oE 'additional=[^ ]+' | cut -d= -f2)"
      echo "  CHECK4: $key — ($additional more non-canonical names not shown)"
      ;;
    SET-DIFF)
      direction="$(echo "$rest" | grep -oE 'direction=[^ ]+' | cut -d= -f2)"
      key="$(echo "$rest" | grep -oE 'key=[^ ]+' | cut -d= -f2)"
      count="$(echo "$rest" | grep -oE 'count=[^ ]+' | cut -d= -f2)"
      names="$(echo "$rest" | sed 's/.*names=//')"
      emit FAIL "CHECK4 set-diff: $key $direction ($count modules) — $names"
      ;;
    CENSUS)
      CENSUS_LINE="$rest"
      ;;
    G25-CENSUS)
      G25_CENSUS_LINE="$rest"
      # Parse equation result to decide PASS/FAIL
      if echo "$rest" | grep -q 'equation=.*FAIL'; then
        total_g25="$(echo "$rest" | grep -oE 'total=[^ ]+' | cut -d= -f2)"
        matched_g25="$(echo "$rest" | grep -oE 'matched=[^ ]+' | cut -d= -f2)"
        crate_g25="$(echo "$rest" | grep -oE 'crate-level=[^ ]+' | cut -d= -f2)"
        unmatched_g25="$(echo "$rest" | grep -oE 'unmatched=[^ ]+' | cut -d= -f2)"
        emit FAIL "GATE-25: crate-level census equation FAIL — total=$total_g25 matched=$matched_g25 crate-level=$crate_g25 unmatched=$unmatched_g25 (expected: total − matched == crate-level)"
      else
        total_g25="$(echo "$rest" | grep -oE 'total=[^ ]+' | cut -d= -f2)"
        crate_g25="$(echo "$rest" | grep -oE 'crate-level=[^ ]+' | cut -d= -f2)"
        matched_g25="$(echo "$rest" | grep -oE 'matched=[^ ]+' | cut -d= -f2)"
        emit PASS "GATE-25: crate-level census equation PASS — total=$total_g25 crate-level=$crate_g25 matched=$matched_g25"
      fi
      ;;
    G25-CRATE-LEVEL)
      G25_CRATE_LEVEL_LINE="$rest"
      echo "  GATE-25 crate-level rows: $rest"
      ;;
    G25-UNMATCHED)
      G25_UNMATCHED_LINE="$rest"
      emit FAIL "GATE-25: module-level rows in module-criticality not found in module-decomposition — $rest"
      ;;
    G25-ERROR)
      emit FAIL "GATE-25 internal error: $rest"
      ;;
    ERROR)
      emit FAIL "CHECK4 internal error: $rest"
      ;;
    *)
      # Unexpected output — ignore silently (may be Python traceback lines)
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Print the runtime census line (positive coverage proof) ──────────────────

echo ""
echo "  Module census: $CENSUS_LINE"
echo "  Gate #25 census: $G25_CENSUS_LINE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-module-canonicality: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  Total non-canonical Module cells detected: $TOTAL_NON_CANONICAL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
