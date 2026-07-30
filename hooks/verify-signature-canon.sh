#!/usr/bin/env bash
# verify-signature-canon.sh — pregolya factory-artifacts signature-canon gate
#
# PURPOSE
# ───────
# Enforces the adjudicated canonical type-signature table against every .md
# file under .factory/specs/ (full-file scan including frontmatter, so
# changelog references to illegal forms are also caught as live violations).
#
# BLOCKING: exits 1 on any FAIL. Wired into pre-commit-validators.sh.
#
# CANON TABLE — each rule is grounded in a ratified Decision ID.
# D-46 discipline: a rule with no ratified Decision ID must be DELETED,
# not downgraded.  Advisory-only rules are permissible only when the corpus
# has pre-existing violations being tracked toward closure.
#
# ┌──────┬────────────────────────────────────────────────────────────────────┐
# │ Rule │ Description                                                        │
# ├──────┼────────────────────────────────────────────────────────────────────┤
# │  S1  │ D-48 — as_retriever receiver                                      │
# │      │   Canonical: fn as_retriever(self: Arc<Self>)                     │
# │      │   FAIL (S1a): as_retriever(self: &Arc<Self>) — non-dyn-compat;    │
# │      │              makes VectorStore non-object-safe (E0038)             │
# │      │   FAIL (S1b): as_retriever(&self) — drops Arc; retriever cannot   │
# │      │              own Arc<dyn VectorStore>                              │
# ├──────┼────────────────────────────────────────────────────────────────────┤
# │  S2  │ D-48/D-45 — VectorStoreRetriever has no lifetime parameter        │
# │      │   VectorStoreRetriever owns store: Arc<dyn VectorStore> and is    │
# │      │   'static; lifetime param removed so Arc<dyn Retriever> coercion  │
# │      │   succeeds and retriever survives tokio::spawn.                    │
# │      │   FAIL: any VectorStoreRetriever< occurrence (lifetime or other)  │
# ├──────┼────────────────────────────────────────────────────────────────────┤
# │  S3  │ D-48 general — no &Arc<Self> receiver anywhere                   │
# │      │   &Arc<Self> compiles on a concrete impl but makes the trait      │
# │      │   non-dyn-compatible (E0038). Project hit E0038 twice from this: │
# │      │   Tool (D-43) and VectorStore (D-48). Standing hazard.           │
# │      │   FAIL: &Arc<Self> anywhere in .factory/specs/                    │
# │      │   Allowlist: hooks/signature-canon-allowlist.txt                  │
# │      │              <path :: symbol> format; Reason: comment required    │
# ├──────┼────────────────────────────────────────────────────────────────────┤
# │  S4  │ D-43 — Arc<dyn Tool> is E0038                                    │
# │      │   Tool inherits Runnable::stream (impl Stream, non-dyn-compat)   │
# │      │   and pipe (where Self: Sized); dyn Tool is non-object-safe.     │
# │      │   Canonical replacement: Arc<dyn DynTool> (blanket impl:         │
# │      │   T: Tool + Send + Sync + 'static auto-implements DynTool).      │
# │      │   FAIL: Arc<dyn Tool>, dyn pregolya_core::Tool                 │
# │      │   EXEMPT: lines explicitly naming the hazard (containing any of: │
# │      │           non-object-safe, E0038, not dyn compatible,             │
# │      │           dyn-incompatible, NOT object-safe, non_exhaustive)      │
# ├──────┼────────────────────────────────────────────────────────────────────┤
# │  S5  │ D-42/D-49 — PregolyaError full-form literals IN RUST FENCES   │
# │      │   D-42 adjudicated PregolyaError::new() as sole public ctor.  │
# │      │   D-49 set scope as "full-form named-field literals only."       │
# │      │                                                                  │
# │      │   ORCHESTRATOR ADJUDICATION 2026-07-28 (sharpens D-49):         │
# │      │   The operative test is FENCE-MEMBERSHIP, not ellipsis presence. │
# │      │   Original S5 (full-corpus scan) flagged 229 literals / 80 files │
# │      │   but only ~14 are construction sites implementers copy & must   │
# │      │   compile.  The 215 over-flags were:                             │
# │      │     – backtick inline spans in prose/postconditions (designators) │
# │      │     – markdown table cells (Test Vector expected-output columns)  │
# │      │     – impl/struct definitions (not literals at all)              │
# │      │     – grep shell-command examples (bc-authoring-plan.md)         │
# │      │     – changelog prose describing past censuses                   │
# │      │   Items (1)–(5) are outside Rust fences and auto-exempt under    │
# │      │   the fence-membership test.                                     │
# │      │                                                                  │
# │      │   FAIL: named-field PregolyaError { } literal that            │
# │      │          (a) appears inside a ```rust (or unlabelled-Rust) fence │
# │      │          (b) lacks any of the 6 required fields                  │
# │      │          (c) is not an abbreviated designator (..)               │
# │      │          Fenced doc comments (/// ...) are IN SCOPE — a prior   │
# │      │          finding confirmed bind_tools doc-comment is copied      │
# │      │          verbatim by implementers.                               │
# │      │   PERMIT: (1) backtick inline spans outside fences; (2) table   │
# │      │           cells; (3) impl/struct definitions; (4) shell command  │
# │      │           examples; (5) changelog prose; (6) abbreviated         │
# │      │           designator (..) anywhere inside braces; (7) formal-   │
# │      │           invariant notation: literal preceded by '== Err(' or  │
# │      │           '==' in the same expression — these are ∀-quantified  │
# │      │           equality assertions (VP notation), not construction    │
# │      │           sites. Implemented as: prefix before PregolyaError { │
# │      │           ends with r'==\s*(?:(?:Ok|Err)\s*\()?\s*$'.           │
# │      │   Required fields: component, category, retry_hint, code,       │
# │      │   message, source (6 total; source via with_source() builder).  │
# └──────┴────────────────────────────────────────────────────────────────────┘
#
# OUTPUT FORMAT (TD-VSDD-091 compliance)
# ──────────────────────────────────────
# Findings cite "file :: symbol" — never "file:NNN" line-number citations.
# Symbol is the method name, type name, or illegal token anchoring the reader.
#
# ALLOWLIST (S3 only)
# ───────────────────
# hooks/signature-canon-allowlist.txt
# Format: <path-relative-to-.factory/specs> :: <symbol>
# Preceding line must be: "# Reason: <justification>"
# Keyed on (file, symbol) — LINE-NUMBER-INDEPENDENT.
#
# CHANGELOG EXEMPTION — S1, S2, S3, S4 (not S5)
# ───────────────────────────────────────────────
# S1, S2, S3, and S4 exempt two regions from scanning:
#   (a) YAML frontmatter — lines between the opening and closing '---' delimiters.
#   (b) Body ## Changelog sections — lines from '## Changelog' heading to the
#       next '## ' heading or EOF.
#
# DESIGN PRINCIPLE (arose FIX-BURST-278-WAVE-C, 2026-07-28):
#   An authoring rule that requires quoting a term cannot apply to terms a gate
#   forbids — otherwise the changelog documenting a fix trips the gate that
#   motivated it.  A changelog entry such as "changed as_retriever(&self) to
#   Arc<Self>" is descriptive (historical record); it records a past state.
#   A signature in prose, a table cell, an Architecture Anchor, or a code fence
#   is normative (implementer guidance); it defines a future state.  Only the
#   normative positions need gating.
#
#   The canonical region-detection logic lives in spec_region_utils.py.
#   verify-no-version-pins.sh uses the same module for its own changelog exemption.
#   There is ONE definition of "what counts as a changelog region" in this suite.
#
# S5 is left as-is (fence-scoped): YAML frontmatter cannot contain Rust fences,
# and the orchestrator confirmed that changelog prose cannot reach fence-scoped
# pattern detection.
#
# Usage:  bash .factory/hooks/verify-signature-canon.sh
# Exit:   0 if no FAIL; 1 if any FAIL.
#
# Integration: wired as BLOCKING in pre-commit-validators.sh.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
FACTORY_DIR="$(cd "$HOOKS_DIR/.." && pwd)"
SPECS_DIR="$FACTORY_DIR/specs"
ALLOWLIST="$HOOKS_DIR/signature-canon-allowlist.txt"

PASS=0
WARN=0
FAIL=0
BLOCKING_FAIL=0
ADVISORY_WARN=0

emit() {
  local level="$1"
  local msg="$2"
  echo "[$level] $msg"
  case "$level" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)); ADVISORY_WARN=$((ADVISORY_WARN + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)); BLOCKING_FAIL=$((BLOCKING_FAIL + 1)) ;;
  esac
}

# ── Hazard-word exemption for S4 ─────────────────────────────────────────────
# Lines that explicitly NAME the hazard are exempt from S4.
# These words indicate the line is DESCRIBING the non-object-safe form,
# not endorsing it.  Value-based, not file-based exemption (D-46 discipline).
S4_HAZARD_PATTERN='non-object-safe\|E0038\|not dyn compatible\|dyn-incompatible\|NOT object-safe\|non_exhaustive'

# ── S1 Python scanner (changelog-exempt; shared region detection) ─────────────
# Arguments: <hooks_dir> <scan_dir>
# Output lines: S1A <rel> <count>  — as_retriever(self: &Arc<Self>) occurrences
#               S1B <rel> <count>  — as_retriever(&self) occurrences
# Exempt: YAML frontmatter and body ## Changelog sections per spec_region_utils.
run_s1_scanner() {
  local hooks_dir="$1" scan_dir="$2"
  python3 - "$hooks_dir" "$scan_dir" <<'PYEOF'
import sys, glob

hooks_dir = sys.argv[1]
scan_dir  = sys.argv[2]
sys.path.insert(0, hooks_dir)
from spec_region_utils import changelog_exempt_lines

files = sorted(glob.glob(f'{scan_dir}/**/*.md', recursive=True))

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    text = ''.join(lines)
    if 'as_retriever(' not in text:
        continue

    exempt = changelog_exempt_lines(lines)
    rel = f.replace(scan_dir.rstrip('/') + '/', '')
    s1a = s1b = 0
    for i, line in enumerate(lines):
        if i in exempt:
            continue
        s1a += line.count('as_retriever(self: &Arc<Self>)')
        s1b += line.count('as_retriever(&self)')

    if s1a:
        print(f"S1A {rel} {s1a}")
    if s1b:
        print(f"S1B {rel} {s1b}")
PYEOF
}

# ── S2 Python scanner (changelog-exempt; shared region detection) ─────────────
# Arguments: <hooks_dir> <scan_dir>
# Output lines: FAIL <rel> <count>  — VectorStoreRetriever< occurrences
run_s2_scanner() {
  local hooks_dir="$1" scan_dir="$2"
  python3 - "$hooks_dir" "$scan_dir" <<'PYEOF'
import sys, glob

hooks_dir = sys.argv[1]
scan_dir  = sys.argv[2]
sys.path.insert(0, hooks_dir)
from spec_region_utils import changelog_exempt_lines

files = sorted(glob.glob(f'{scan_dir}/**/*.md', recursive=True))

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    if 'VectorStoreRetriever<' not in ''.join(lines):
        continue

    exempt = changelog_exempt_lines(lines)
    rel = f.replace(scan_dir.rstrip('/') + '/', '')
    count = 0
    for i, line in enumerate(lines):
        if i in exempt:
            continue
        count += line.count('VectorStoreRetriever<')

    if count > 0:
        print(f"FAIL {rel} {count}")
PYEOF
}

# ── S3 Python scanner (changelog-exempt; shared region detection) ─────────────
# Arguments: <hooks_dir> <scan_dir> <allowlist_file>
# Output lines: FAIL <rel> <count>    — non-allowlisted &Arc<Self> occurrences
#               ALLOWED <rel> <count> — allowlisted occurrences (informational)
run_s3_scanner() {
  local hooks_dir="$1" scan_dir="$2" allowlist_f="$3"
  python3 - "$hooks_dir" "$scan_dir" "$allowlist_f" <<'PYEOF'
import sys, glob, os

hooks_dir   = sys.argv[1]
scan_dir    = sys.argv[2]
allowlist_f = sys.argv[3]
sys.path.insert(0, hooks_dir)
from spec_region_utils import changelog_exempt_lines

# Load S3 allowlist: set of rel-paths exempted for &Arc<Self>
allowed_paths = set()
if os.path.isfile(allowlist_f):
    with open(allowlist_f, 'r', encoding='utf-8') as fh:
        for raw in fh:
            entry = raw.strip()
            if entry and not entry.startswith('#') and ' :: &Arc<Self>' in entry:
                allowed_paths.add(entry.split(' :: &Arc<Self>')[0].strip())

files = sorted(glob.glob(f'{scan_dir}/**/*.md', recursive=True))

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    if '&Arc<Self>' not in ''.join(lines):
        continue

    rel = f.replace(scan_dir.rstrip('/') + '/', '')

    if rel in allowed_paths:
        count = ''.join(lines).count('&Arc<Self>')
        if count > 0:
            print(f"ALLOWED {rel} {count}")
        continue

    exempt = changelog_exempt_lines(lines)
    count = 0
    for i, line in enumerate(lines):
        if i in exempt:
            continue
        count += line.count('&Arc<Self>')

    if count > 0:
        print(f"FAIL {rel} {count}")
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

# ── S5 Python scanner (fence-scoped; shared between check and probe) ─────────
# Arguments: <scan_dir>
# Outputs: FAIL <rel> :: PregolyaError — <N> literal(s) missing: <fields>
#
# Scope: scans only PregolyaError { } literals INSIDE Rust fences.
#   Rust fence = ```rust (or rust,no_run / rust,ignore etc.) or an unlabelled
#   fence whose body contains Rust-keyword indicators.
#   Auto-exempt by being outside a fence: inline backtick spans, table cells,
#   impl/struct definitions, shell grep examples, changelog prose.
#   Also exempt inside a fence:
#     - impl PregolyaError { } and pub struct PregolyaError { }
#     - abbreviated designator (.. anywhere inside braces)
#     - formal-invariant notation: prefix before PregolyaError { ends with
#       '== (Ok(|Err()?' — ∀-quantified equality assertions in VP specs are
#       designators, not construction sites (orchestrator adjudication 2026-07-28).
#       Implemented as: re.search(r'==\s*(?:(?:Ok|Err)\s*\()?\s*$', prefix).
#       Single-line formal invariants detected; multi-line invariants may be
#       flagged (acceptable edge case; formally-stated spec files use single-line
#       invariant notation per corpus survey).
run_s5_scanner() {
  local scan_dir="$1"
  python3 - "$scan_dir" <<'PYEOF'
import sys, glob, re

scan_root = sys.argv[1]
files = sorted(glob.glob(f'{scan_root}/**/*.md', recursive=True))
REQUIRED = {'component', 'category', 'retry_hint', 'code', 'message', 'source'}
FIELD_PAT = re.compile(r'\b(component|category|retry_hint|code|message|source)\s*[=:]')

# Labels that identify a known-non-Rust fence (when explicitly labelled)
NON_RUST_LABELS = {
    'json','toml','yaml','yml','bash','sh','shell','console','output',
    'python','py','javascript','js','typescript','ts','css','html','xml',
    'sql','go','java','c','cpp','text','txt','diff','patch',
    'makefile','dockerfile','markdown','md',
}
# Rust syntax indicators for unlabelled fence classification
# '::' catches short Err(PregolyaError { Component::X, ... }) fences that
# contain no statement-level keywords but use the Rust path separator.
RUST_KWS = ['fn ', 'let ', 'impl ', '-> Result', 'Arc<', '&mut ', 'async fn', 'pub fn', '::']

# Formal-invariant exemption: PregolyaError preceded by == (equality comparison)
# Matches: '... == Err(PregolyaError {', '... == PregolyaError {', etc.
# This is an equality assertion in VP formal notation, not a construction site.
FORMAL_INVARIANT_RE = re.compile(r'==\s*(?:(?:Ok|Err)\s*\()?\s*$')

# impl/struct definition exemption
IMPL_STRUCT_RE = re.compile(r'^(?:impl|pub\s+struct|struct)\b')

def fence_is_rust(lang_tag, body):
    """Return True if this fence should be scanned for Rust PregolyaError patterns."""
    label = lang_tag.lower().strip().split(',')[0].strip()
    if label == 'rust':
        return True
    if label in NON_RUST_LABELS:
        return False
    if label == '':
        return any(kw in body for kw in RUST_KWS)
    return False  # unknown label: exclude (safe default)

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue
    if 'PregolyaError {' not in ''.join(lines):
        continue

    rel = f.replace(scan_root.rstrip('/') + '/', '')

    # ── Pass 1: locate fenced code blocks ───────────────────────────────────
    # Each rust fence stored as list of its body lines (delimiter lines excluded)
    rust_fences = []  # list of [body_line, ...]
    in_fence = False
    fence_start_body = 0
    fence_lang = ''

    for i, line in enumerate(lines):
        s = line.rstrip('\n').strip()
        if not in_fence:
            m = re.match(r'^```(.*)$', s)
            if m:
                in_fence = True
                fence_start_body = i + 1
                fence_lang = (m.group(1) or '').strip()
        else:
            if re.match(r'^```\s*$', s):
                body_lines = lines[fence_start_body:i]
                body_text = ''.join(body_lines)
                if fence_is_rust(fence_lang, body_text):
                    rust_fences.append(body_lines)
                in_fence = False

    # ── Pass 2: scan each Rust fence for PregolyaError violations ─────────
    file_fails = 0
    file_missing = set()

    for fence_lines in rust_fences:
        i2 = 0
        while i2 < len(fence_lines):
            line2 = fence_lines[i2]
            if 'PregolyaError {' not in line2:
                i2 += 1
                continue

            # Skip impl/struct definitions (check part before 'PregolyaError')
            prefix_part = line2.split('PregolyaError')[0].strip()
            # Strip leading Rust doc-comment markers (/// or //!) to get actual content
            prefix_part = re.sub(r'^/{2,3}[/!]?\s*', '', prefix_part).strip()
            if IMPL_STRUCT_RE.match(prefix_part):
                i2 += 1
                continue

            # Accumulate brace-balanced block
            block = line2
            depth = line2.count('{') - line2.count('}')
            j2 = i2 + 1
            while depth > 0 and j2 < len(fence_lines):
                block += fence_lines[j2]
                depth += fence_lines[j2].count('{') - fence_lines[j2].count('}')
                j2 += 1

            # Find PregolyaError { within accumulated block
            ms = block.find('PregolyaError {')
            if ms < 0:
                i2 = j2 if j2 > i2 else i2 + 1
                continue

            # Formal-invariant exemption: check if == precedes PregolyaError {
            # The prefix is the block content up to (not including) 'PregolyaError {'
            blk_prefix = block[:ms]
            if FORMAL_INVARIANT_RE.search(blk_prefix):
                # Equality comparison: this is a designator, not a construction site
                i2 = j2 if j2 > i2 else i2 + 1
                continue

            # Extract inner content of PregolyaError { ... }
            inner = block[ms + len('PregolyaError {'):]
            ep = len(inner)
            d2 = 1
            for k, ch in enumerate(inner):
                if ch == '{':   d2 += 1
                elif ch == '}':
                    d2 -= 1
                    if d2 == 0: ep = k; break
            struct_inner = inner[:ep]

            # Abbreviated designator: '..' anywhere inside braces
            # '..' subsumes '...' because '...' contains '..'
            if '..' in struct_inner:
                i2 = j2 if j2 > i2 else i2 + 1
                continue

            # Check field completeness
            found = set(FIELD_PAT.findall(struct_inner))
            missing = REQUIRED - found
            if missing:
                file_fails += 1
                file_missing.update(missing)

            i2 = j2 if j2 > i2 else i2 + 1

    if file_fails > 0:
        missing_str = ','.join(sorted(file_missing))
        print(f"FAIL {rel} :: PregolyaError — {file_fails} literal(s) missing: {missing_str}")
PYEOF
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE S1: as_retriever receiver canon (D-48)
# ─────────────────────────────────────────────────────────────────────────────

check_s1() {
  local s1a_count=0 s1b_count=0
  local s1a_files=() s1b_files=()

  while IFS= read -r line; do
    case "$line" in
      "S1A "*)
        local rel n
        rel="${line#S1A }"
        n="${rel##* }"
        rel="specs/${rel% *}"
        s1a_count=$((s1a_count + n))
        s1a_files+=("$rel ($n)")
        ;;
      "S1B "*)
        local rel n
        rel="${line#S1B }"
        n="${rel##* }"
        rel="specs/${rel% *}"
        s1b_count=$((s1b_count + n))
        s1b_files+=("$rel ($n)")
        ;;
    esac
  done <<< "$(run_s1_scanner "$HOOKS_DIR" "$SPECS_DIR")"

  if [ "$s1a_count" -gt 0 ]; then
    emit FAIL "S1a (D-48): as_retriever(self: &Arc<Self>) — non-dyn-compatible; canonical: self: Arc<Self>: $s1a_count occurrence(s)"
    for e in "${s1a_files[@]}"; do echo "       $e"; done
  fi
  if [ "$s1b_count" -gt 0 ]; then
    emit FAIL "S1b (D-48): as_retriever(&self) — drops Arc; canonical: self: Arc<Self>: $s1b_count occurrence(s)"
    for e in "${s1b_files[@]}"; do echo "       $e"; done
  fi
  if [ "$s1a_count" -eq 0 ] && [ "$s1b_count" -eq 0 ]; then
    emit PASS "S1 (D-48): as_retriever receiver — all occurrences use canonical self: Arc<Self>"
  fi
}

probe_s1() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/s1a-fire" "$PROBE_TMP/s1b-fire" "$PROBE_TMP/s1-noop"
  local out

  # S1a fire: illegal &Arc<Self> receiver
  printf 'fn as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>;\n' \
    > "$PROBE_TMP/s1a-fire/probe.md"
  out="$(run_s1_scanner "$HOOKS_DIR" "$PROBE_TMP/s1a-fire")"
  if ! echo "$out" | grep -qF 'S1A'; then
    echo "[SELF-PROBE FAIL] S1a: as_retriever(self: &Arc<Self>) not detected."
    clean_probe_tmp; exit 2
  fi

  # S1b fire: illegal &self receiver
  printf 'fn as_retriever(&self) -> VectorStoreRetriever;\n' \
    > "$PROBE_TMP/s1b-fire/probe.md"
  out="$(run_s1_scanner "$HOOKS_DIR" "$PROBE_TMP/s1b-fire")"
  if ! echo "$out" | grep -qF 'S1B'; then
    echo "[SELF-PROBE FAIL] S1b: as_retriever(&self) not detected."
    clean_probe_tmp; exit 2
  fi

  # S1 non-fire: canonical form must not trigger either pattern
  printf 'fn as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>;\n' \
    > "$PROBE_TMP/s1-noop/probe.md"
  out="$(run_s1_scanner "$HOOKS_DIR" "$PROBE_TMP/s1-noop")"
  if echo "$out" | grep -qE '^S1[AB]'; then
    echo "[SELF-PROBE FAIL] S1: canonical self: Arc<Self> was incorrectly flagged."
    clean_probe_tmp; exit 2
  fi

  clean_probe_tmp
  echo "[SELF-PROBE PASS] S1: detects S1a/S1b; ignores canonical self: Arc<Self>."
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE S2: VectorStoreRetriever has no lifetime parameter (D-48/D-45)
# ─────────────────────────────────────────────────────────────────────────────

check_s2() {
  local s2_count=0
  local s2_files=()

  while IFS= read -r line; do
    case "$line" in
      "FAIL "*)
        local rel n
        rel="${line#FAIL }"
        n="${rel##* }"
        rel="specs/${rel% *}"
        s2_count=$((s2_count + n))
        s2_files+=("$rel ($n)")
        ;;
    esac
  done <<< "$(run_s2_scanner "$HOOKS_DIR" "$SPECS_DIR")"

  if [ "$s2_count" -gt 0 ]; then
    emit FAIL "S2 (D-48/D-45): VectorStoreRetriever< — lifetime-parameterised form; VectorStoreRetriever is 'static, owns Arc<dyn VectorStore>: $s2_count occurrence(s)"
    for e in "${s2_files[@]}"; do echo "       $e"; done
  else
    emit PASS "S2 (D-48/D-45): VectorStoreRetriever has no lifetime parameter — corpus clean"
  fi
}

probe_s2() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/s2-fire" "$PROBE_TMP/s2-noop"
  local out

  # S2 fire: lifetime-parameterised form
  printf "pub struct VectorStoreRetriever<'a> { store: &'a dyn VectorStore }\n" \
    > "$PROBE_TMP/s2-fire/probe.md"
  out="$(run_s2_scanner "$HOOKS_DIR" "$PROBE_TMP/s2-fire")"
  if ! echo "$out" | grep -qF 'FAIL'; then
    echo "[SELF-PROBE FAIL] S2: VectorStoreRetriever< not detected."
    clean_probe_tmp; exit 2
  fi

  # S2 non-fire: no-lifetime form must not be caught
  printf 'pub struct VectorStoreRetriever { store: Arc<dyn VectorStore> }\n' \
    > "$PROBE_TMP/s2-noop/probe.md"
  out="$(run_s2_scanner "$HOOKS_DIR" "$PROBE_TMP/s2-noop")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S2: VectorStoreRetriever (no <) was incorrectly flagged."
    clean_probe_tmp; exit 2
  fi

  clean_probe_tmp
  echo "[SELF-PROBE PASS] S2: detects VectorStoreRetriever<; ignores VectorStoreRetriever."
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE S3: no &Arc<Self> receiver anywhere (D-48 general)
# ─────────────────────────────────────────────────────────────────────────────

check_s3() {
  local s3_count=0
  local s3_files=()
  local s3_allowed=0

  while IFS= read -r line; do
    case "$line" in
      "FAIL "*)
        local rel n
        rel="${line#FAIL }"
        n="${rel##* }"
        rel="specs/${rel% *}"
        s3_count=$((s3_count + n))
        s3_files+=("$rel ($n)")
        ;;
      "ALLOWED "*)
        local n
        n="${line##* }"
        s3_allowed=$((s3_allowed + n))
        ;;
    esac
  done <<< "$(run_s3_scanner "$HOOKS_DIR" "$SPECS_DIR" "$ALLOWLIST")"

  if [ "$s3_count" -gt 0 ]; then
    emit FAIL "S3 (D-48 general): &Arc<Self> — non-dyn-compatible receiver; use Arc<Self>: $s3_count occurrence(s)"
    for e in "${s3_files[@]}"; do echo "       $e"; done
    [ "$s3_allowed" -gt 0 ] && echo "  ($s3_allowed occurrence(s) allowlisted)"
    echo "  Allowlist: $ALLOWLIST  (path :: &Arc<Self>; preceding: # Reason: ...)"
  else
    local note=""
    [ "$s3_allowed" -gt 0 ] && note=" ($s3_allowed allowlisted)"
    emit PASS "S3 (D-48 general): &Arc<Self> — corpus clean${note}"
  fi
}

probe_s3() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/s3-fire" "$PROBE_TMP/s3-noop"
  local out

  # S3 fire: &Arc<Self> in method receiver (body prose — not in frontmatter/changelog)
  printf 'fn foo(self: &Arc<Self>) -> Bar;\n' > "$PROBE_TMP/s3-fire/probe.md"
  out="$(run_s3_scanner "$HOOKS_DIR" "$PROBE_TMP/s3-fire" "$ALLOWLIST")"
  if ! echo "$out" | grep -qF 'FAIL'; then
    echo "[SELF-PROBE FAIL] S3: &Arc<Self> not detected."
    clean_probe_tmp; exit 2
  fi

  # S3 non-fire: Arc<Self> (no leading &) must not be caught
  printf 'fn foo(self: Arc<Self>) -> Bar;\n' > "$PROBE_TMP/s3-noop/probe.md"
  out="$(run_s3_scanner "$HOOKS_DIR" "$PROBE_TMP/s3-noop" "$ALLOWLIST")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S3: Arc<Self> (no &) was incorrectly flagged."
    clean_probe_tmp; exit 2
  fi

  clean_probe_tmp
  echo "[SELF-PROBE PASS] S3: detects &Arc<Self>; ignores Arc<Self>."
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE S4: Arc<dyn Tool> is E0038; canonical: Arc<dyn DynTool> (D-43)
# ─────────────────────────────────────────────────────────────────────────────

run_s4_scanner() {
  local hooks_dir="$1" scan_dir="$2"
  python3 - "$hooks_dir" "$scan_dir" <<'PYEOF'
import sys, glob

hooks_dir = sys.argv[1]
scan_root = sys.argv[2]
sys.path.insert(0, hooks_dir)
from spec_region_utils import changelog_exempt_lines

files = sorted(glob.glob(f'{scan_root}/**/*.md', recursive=True))

HAZARD_WORDS = [
    'non-object-safe', 'E0038', 'not dyn compatible',
    'dyn-incompatible', 'NOT object-safe', 'non_exhaustive',
]
SEARCH_TOKENS = ['Arc<dyn Tool>', 'dyn pregolya_core::Tool']

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
    except OSError:
        continue

    rel = f.replace(scan_root.rstrip('/') + '/', '')
    exempt = changelog_exempt_lines(lines)
    file_count = 0

    for i, line in enumerate(lines):
        if i in exempt:
            continue
        if any(tok in line for tok in SEARCH_TOKENS):
            if not any(hw in line for hw in HAZARD_WORDS):
                file_count += 1

    if file_count > 0:
        print(f"FAIL {rel} :: Arc<dyn Tool> — {file_count} non-exempt occurrence(s)")
PYEOF
}

check_s4() {
  local s4_count=0
  local s4_files=()

  while IFS= read -r line; do
    case "$line" in
      "FAIL "*)
        s4_count=$((s4_count + 1))
        s4_files+=("  specs/${line#FAIL }")
        ;;
    esac
  done <<< "$(run_s4_scanner "$HOOKS_DIR" "$SPECS_DIR")"

  if [ "$s4_count" -gt 0 ]; then
    emit FAIL "S4 (D-43): Arc<dyn Tool> / dyn pregolya_core::Tool — non-object-safe (E0038); canonical: Arc<dyn DynTool>: $s4_count file(s)"
    for e in "${s4_files[@]}"; do echo "     $e"; done
    echo "  Exempt when line contains: non-object-safe | E0038 | not dyn compatible | dyn-incompatible | NOT object-safe | non_exhaustive"
  else
    emit PASS "S4 (D-43): Arc<dyn Tool> — no non-exempt occurrences found"
  fi
}

probe_s4() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/fire" "$PROBE_TMP/exempt" "$PROBE_TMP/noop"

  # S4 fire: non-exempt Arc<dyn Tool>
  printf 'let tool: Arc<dyn Tool> = register(t);\n' > "$PROBE_TMP/fire/probe.md"
  local out
  out="$(run_s4_scanner "$HOOKS_DIR" "$PROBE_TMP/fire")"
  if [ -z "$out" ]; then
    echo "[SELF-PROBE FAIL] S4: non-exempt Arc<dyn Tool> not detected."
    clean_probe_tmp; exit 2
  fi

  # S4 exempt probe: line naming the hazard must not be caught
  printf 'Arc<dyn Tool> is non-object-safe (E0038); use Arc<dyn DynTool> instead.\n' > "$PROBE_TMP/exempt/probe.md"
  out="$(run_s4_scanner "$HOOKS_DIR" "$PROBE_TMP/exempt")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S4: hazard-naming line (contains E0038) was incorrectly flagged."
    clean_probe_tmp; exit 2
  fi

  # S4 non-fire: Arc<dyn DynTool> must not be caught
  printf 'let tool: Arc<dyn DynTool> = dispatch(t);\n' > "$PROBE_TMP/noop/probe.md"
  out="$(run_s4_scanner "$HOOKS_DIR" "$PROBE_TMP/noop")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S4: Arc<dyn DynTool> was incorrectly caught as Arc<dyn Tool>."
    clean_probe_tmp; exit 2
  fi

  clean_probe_tmp
  echo "[SELF-PROBE PASS] S4: detects non-exempt Arc<dyn Tool>; exempts hazard-naming lines; ignores Arc<dyn DynTool>."
}

# ─────────────────────────────────────────────────────────────────────────────
# CHANGELOG EXEMPTION PROBE (S1–S4)
# Proves the exemption is NARROW: banned pattern in changelog must not fire,
# identical pattern in normative body must fire.
# ─────────────────────────────────────────────────────────────────────────────

probe_changelog_exempt() {
  init_probe_tmp
  mkdir -p "$PROBE_TMP/cl-exempt" "$PROBE_TMP/cl-normative-s1" "$PROBE_TMP/cl-normative-s3"
  local out

  # ── EXEMPT side: banned patterns ONLY in YAML frontmatter changelog ──────
  # The YAML changelog: block describes past fixes; these occurrences are
  # historical record (descriptive), not normative declarations.
  cat > "$PROBE_TMP/cl-exempt/probe.md" <<'PROBEOF'
---
id: PROBE-CL-001
changelog:
  - "1.0 (2026-07-28): changed as_retriever(&self) to as_retriever(self: Arc<Self>); removed &Arc<Self> receiver; removed VectorStoreRetriever<'_> lifetime param; replaced Arc<dyn Tool> with Arc<dyn DynTool>"
---
## Description

No banned patterns appear outside the frontmatter in this file.
PROBEOF

  out=""
  out+="$(run_s1_scanner "$HOOKS_DIR" "$PROBE_TMP/cl-exempt")"
  out+="$(run_s2_scanner "$HOOKS_DIR" "$PROBE_TMP/cl-exempt")"
  out+="$(run_s3_scanner "$HOOKS_DIR" "$PROBE_TMP/cl-exempt" "$ALLOWLIST")"
  out+="$(run_s4_scanner "$HOOKS_DIR" "$PROBE_TMP/cl-exempt")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] Changelog exemption: patterns in YAML frontmatter changelog: entry incorrectly flagged."
    echo "  Scanner output: $out"
    clean_probe_tmp; exit 2
  fi

  # ── NORMATIVE side S1b: as_retriever(&self) in body prose MUST fire ──────
  cat > "$PROBE_TMP/cl-normative-s1/probe.md" <<'PROBEOF'
---
id: PROBE-CL-002
---
## Description

The method signature as_retriever(&self) drops the Arc.
PROBEOF

  out="$(run_s1_scanner "$HOOKS_DIR" "$PROBE_TMP/cl-normative-s1")"
  if ! echo "$out" | grep -qF 'S1B'; then
    echo "[SELF-PROBE FAIL] Changelog exemption narrow: as_retriever(&self) in body prose not detected."
    clean_probe_tmp; exit 2
  fi

  # ── NORMATIVE side S3: &Arc<Self> in body prose MUST fire ────────────────
  cat > "$PROBE_TMP/cl-normative-s3/probe.md" <<'PROBEOF'
---
id: PROBE-CL-003
---
## Description

The receiver takes &Arc<Self> which is non-dyn-compatible.
PROBEOF

  out="$(run_s3_scanner "$HOOKS_DIR" "$PROBE_TMP/cl-normative-s3" "$ALLOWLIST")"
  if ! echo "$out" | grep -qF 'FAIL'; then
    echo "[SELF-PROBE FAIL] Changelog exemption narrow: &Arc<Self> in body prose not detected."
    clean_probe_tmp; exit 2
  fi

  clean_probe_tmp
  echo "[SELF-PROBE PASS] Changelog exemption (narrow): frontmatter changelog entries exempt; body prose violations still caught."
}

# ─────────────────────────────────────────────────────────────────────────────
# RULE S5: PregolyaError full-form literals (D-42/D-49)
# ─────────────────────────────────────────────────────────────────────────────

check_s5() {
  local s5_file_count=0
  local s5_total=0
  local s5_findings=()

  while IFS= read -r line; do
    case "$line" in
      "FAIL "*)
        s5_file_count=$((s5_file_count + 1))
        local n
        n="$(echo "$line" | grep -oE '[0-9]+ literal' | grep -oE '[0-9]+' || echo 0)"
        s5_total=$((s5_total + n))
        s5_findings+=("${line#FAIL }")
        ;;
    esac
  done <<< "$(run_s5_scanner "$SPECS_DIR")"

  if [ "$s5_file_count" -gt 0 ]; then
    emit FAIL "S5 (D-42/D-49, fence-scoped): PregolyaError full-form literals in Rust fences missing required fields: $s5_total literal(s) across $s5_file_count file(s)"
    echo "  Scope: Rust fences (rustfence) only — inline spans, tables, impl/struct defns auto-exempt"
    echo "  Required: component, category, retry_hint, code, message, source"
    echo "  Canonical form: PregolyaError::new(component, category, retry_hint, code, msg)"
    echo "                  .with_source(arc_err)  [for source field]"
    echo "  Permitted: abbreviated designator containing '..' inside braces"
    echo "  Affected files (symbol :: missing-fields):"
    for e in "${s5_findings[@]}"; do echo "       $e"; done
  else
    emit PASS "S5 (D-42/D-49, fence-scoped): PregolyaError — all Rust-fence literals use abbreviated designator (..) or full 6-field form"
  fi
}

probe_s5() {
  init_probe_tmp

  # ── S5 FIRE: full-form literal in ```rust fence, missing required fields ──
  mkdir -p "$PROBE_TMP/p5-fire"
  cat > "$PROBE_TMP/p5-fire/probe.md" <<'PROBEOF'
```rust
fn example() -> Result<(), PregolyaError> {
    return Err(PregolyaError {
        component: Component::Vs,
        code: "E-VS-001",
    });
}
```
PROBEOF
  local out
  out="$(run_s5_scanner "$PROBE_TMP/p5-fire")"
  if [ -z "$out" ]; then
    echo "[SELF-PROBE FAIL] S5: full-form literal in rust fence (missing 4 fields) not detected."
    clean_probe_tmp; exit 2
  fi

  # ── S5 PERMIT: abbreviated designator (..) in ```rust fence ──────────────
  mkdir -p "$PROBE_TMP/p5-abbrev"
  cat > "$PROBE_TMP/p5-abbrev/probe.md" <<'PROBEOF'
```rust
matches!(err, Err(PregolyaError { code: "E-VS-001", .. }))
```
PROBEOF
  out="$(run_s5_scanner "$PROBE_TMP/p5-abbrev")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S5: abbreviated designator (..) in rust fence incorrectly flagged."
    clean_probe_tmp; exit 2
  fi

  # ── S5 PERMIT: inline backtick span outside any fence ────────────────────
  # Backtick inline spans in prose are designators, not construction sites.
  # They are auto-exempt because they are not inside any Rust fence.
  mkdir -p "$PROBE_TMP/p5-inline"
  printf '`Err(PregolyaError { component: MCP, code: "E-MCP-001" })` in prose.\n' \
    > "$PROBE_TMP/p5-inline/probe.md"
  out="$(run_s5_scanner "$PROBE_TMP/p5-inline")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S5: inline backtick span outside fence incorrectly flagged."
    clean_probe_tmp; exit 2
  fi

  # ── S5 PERMIT: impl PregolyaError { } definition in ```rust fence ──────
  mkdir -p "$PROBE_TMP/p5-impl"
  cat > "$PROBE_TMP/p5-impl/probe.md" <<'PROBEOF'
```rust
impl PregolyaError {
    pub fn new() -> Self { todo!() }
}
```
PROBEOF
  out="$(run_s5_scanner "$PROBE_TMP/p5-impl")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S5: impl PregolyaError { } incorrectly flagged as literal."
    clean_probe_tmp; exit 2
  fi

  # ── S5 PERMIT: formal-invariant notation in ```rust fence ────────────────
  # Orchestrator adjudication: == Err(PregolyaError { ... }) is a ∀-quantified
  # equality assertion (VP formal property), not a construction site.
  mkdir -p "$PROBE_TMP/p5-formal"
  cat > "$PROBE_TMP/p5-formal/probe.md" <<'PROBEOF'
```rust
check_risk_floor(r) == Err(PregolyaError { code: "E-TOOLS-007", category: VAL })
```
PROBEOF
  out="$(run_s5_scanner "$PROBE_TMP/p5-formal")"
  if [ -n "$out" ]; then
    echo "[SELF-PROBE FAIL] S5: formal-invariant notation (== Err(PregolyaError)) incorrectly flagged."
    clean_probe_tmp; exit 2
  fi

  # ── S5 FIRE: full-form literal in unlabelled fence identified as Rust via '::' ──
  # '::' is the Rust path separator; short fences with Component::Foo syntax
  # are classified as Rust even without statement-level keywords.
  mkdir -p "$PROBE_TMP/p5-unlabelled-rust"
  cat > "$PROBE_TMP/p5-unlabelled-rust/probe.md" <<'PROBEOF'
```
Err(PregolyaError {
    component: Component::Foo,
    code: "E-FOO-001",
})
```
PROBEOF
  out="$(run_s5_scanner "$PROBE_TMP/p5-unlabelled-rust")"
  if [ -z "$out" ]; then
    echo "[SELF-PROBE FAIL] S5: full-form literal in unlabelled fence with '::' (Rust path separator) not detected."
    clean_probe_tmp; exit 2
  fi

  clean_probe_tmp
  echo "[SELF-PROBE PASS] S5 (fence-scoped): detects full-form literals in Rust fences; permits abbreviated (..), inline spans, impl defns, and formal-invariant (==) forms; detects unlabelled Rust fences via '::' indicator."
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

echo "verify-signature-canon: pregolya adjudicated type-signature canon"
echo "  SPECS_DIR: $SPECS_DIR"
echo "  Decisions: D-42 PregolyaError ctor | D-43 DynTool | D-45/D-48 as_retriever receiver"
echo "  D-46 discipline: every rule grounded in a ratified Decision ID"
echo ""

echo "[SELF-PROBE] Verifying each rule catches its synthetic violation..."
probe_s1
probe_s2
probe_s3
probe_s4
probe_changelog_exempt
probe_s5
echo "[SELF-PROBE] All probes passed — checks are not false-green."
echo ""

echo "════════════════════════════════════════════"
echo "BLOCKING rules"
echo "════════════════════════════════════════════"

echo ""
echo "── S1 (D-48): as_retriever receiver canon ──────────────────────────────"
check_s1

echo ""
echo "── S2 (D-48/D-45): VectorStoreRetriever lifetime parameter ─────────────"
check_s2

echo ""
echo "── S3 (D-48 general): &Arc<Self> receiver ──────────────────────────────"
check_s3

echo ""
echo "── S4 (D-43): Arc<dyn Tool> non-object-safe ────────────────────────────"
check_s4

echo ""
echo "── S5 (D-42/D-49, fence-scoped): PregolyaError full-form literals in Rust fences ──"
check_s5

echo ""
echo "════════════════════════════════════════════"
echo "ADVISORY rules: none currently defined"
echo "(Add with emit WARN when a rule has pre-existing corpus violations"
echo " being tracked toward closure; must cite a Decision ID per D-46.)"
echo "════════════════════════════════════════════"

echo ""
echo "verify-signature-canon: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "  BLOCKING: $BLOCKING_FAIL FAIL(s)"
echo "  ADVISORY: $ADVISORY_WARN WARN(s)"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "RESULT: FAIL"
  echo ""
  echo "Routing guide (TD-VSDD-091: symbol/section cites; no line numbers):"
  echo "  S1 violations → architect: correct as_retriever receiver to self: Arc<Self>"
  echo "  S2 violations → architect: remove lifetime parameter from VectorStoreRetriever"
  echo "  S3 violations → architect: replace &Arc<Self> receiver with Arc<Self>"
  echo "                             or add entry to signature-canon-allowlist.txt"
  echo "  S4 violations → product-owner/architect: replace Arc<dyn Tool> with Arc<dyn DynTool>"
  echo "  S5 violations → product-owner/architect: replace struct literal with"
  echo "                                            PregolyaError::new(...) constructor"
  exit 1
else
  echo ""
  echo "RESULT: PASS"
  exit 0
fi
