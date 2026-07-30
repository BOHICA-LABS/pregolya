#!/usr/bin/env bash
# verify-arch-anchor-resolution.sh — pregolya factory-artifacts wrap guard
#
# Validates Architecture-Anchor file citations in BC files:
# (.factory/specs/behavioral-contracts/ss-*/BC-*.md)
#
#   Rule 1 (PATH-RESOLUTION): Every path-style architecture citation
#           (pattern `architecture/<path>.md`) found in the BODY of a BC
#           file (post-frontmatter) must resolve to an existing file under
#           .factory/specs/architecture/.  Glob-style citations containing
#           `*` wildcards are REJECTED — a wildcard path is not a specific
#           file reference and cannot be verified against a real artifact.
#           Bare "ADR-NNN" prose references that contain no `architecture/`
#           path prefix are NOT validated (to keep false positives at zero).
#
#   Rule 2 (NO-PLACEHOLDER): The ## Architecture Anchors section of each
#           BC file must not contain the literal substring "(filled by"
#           (case-insensitive).  This string indicates pending architect
#           work and is a blocking process-gap.
#
# Files are scanned from the BODY only (content after the closing `---`
# frontmatter delimiter).  Frontmatter YAML changelog entries that
# reference historical non-existent paths as audit-trail are therefore
# not flagged.
#
# Expected failures (worklist as of fix-burst-277):
#   12 SS-11/SS-13 BCs — BC-2.11.001 through BC-2.11.006 and
#   BC-2.13.001 through BC-2.13.006.  These carry nonexistent citations
#   (architecture/pregolya-core.md, architecture/pregolya-graph.md,
#   architecture/pregolya-memory.md, architecture/pregolya-sandbox.md,
#   architecture/cargo-features.md, architecture/verification-properties.md)
#   and "(filled by architect)" placeholder text.
#   4 glob-wildcard citations — BC-2.20.001, BC-2.22.001, BC-2.20.002,
#   BC-2.21.002 use architecture/*.md wildcard citations which are now
#   rejected (wildcard paths are non-specific and cannot be verified).
#   Total expected: 16. BC-2.13.007 PASSES (cites only code paths).
#   Any FAIL outside these 16 is an ADDITIONAL UNEXPECTED FAILURE.
#
# Usage:  bash .factory/hooks/verify-arch-anchor-resolution.sh
# Exit:   0 if no FAIL lines; 1 if any FAIL.
#
# Integration (state-manager burst protocol):
#   Add as a validation step before the atomic factory-artifacts commit:
#     bash .factory/hooks/verify-arch-anchor-resolution.sh

set -euo pipefail

FACTORY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BC_GLOB="$FACTORY_DIR/specs/behavioral-contracts/ss-*/BC-*.md"
ARCH_ROOT="$FACTORY_DIR/specs/architecture"

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

# ── Python3 inline parser ─────────────────────────────────────────────────────
#
# Produces one output line per BC file in the format:
#   PASS <filepath>
#   FAIL <filepath> <defect-description>
#   SKIP <filepath> <reason>

PYTHON_OUTPUT="$(python3 - "$BC_GLOB" "$ARCH_ROOT" <<'PYEOF'
import sys, glob as globmod, re, os

bc_pattern = sys.argv[1]
arch_root  = sys.argv[2]

files = sorted(globmod.glob(bc_pattern))

# Match path-style citations: architecture/<something>.md
# Stops at whitespace, quotes, backtick, brackets, hash, parens, backslash.
# Handles glob wildcards (*) in the path — they are left in the captured
# group and resolved via glob.glob() below.
PATH_CITATION_RE = re.compile(
    r"""architecture/([^\s"'`\[\]#)(\\]+\.md)"""
)

def citation_exists(citation, arch_root):
    """
    Resolve 'architecture/<relative>' against arch_root.
    Returns True only if the exact file exists.
    Paths containing glob wildcards ('*') are REJECTED (return False) —
    a wildcard is not a specific file reference and cannot be verified.
    """
    relative = citation[len('architecture/'):]
    if '*' in relative:
        # Wildcard citations are non-specific — reject unconditionally.
        # The caller will treat False as unresolved → FAIL.
        return False
    return os.path.exists(os.path.join(arch_root, relative))

for filepath in files:
    try:
        with open(filepath, 'r', encoding='utf-8') as fh:
            content = fh.read()
    except OSError as e:
        print(f"SKIP {filepath} read-error:{e}")
        continue

    # Split into [pre, frontmatter, body]; scan BODY only so that
    # historical changelog entries in frontmatter YAML are not flagged.
    parts = content.split('---', 2)
    if len(parts) < 3:
        # No frontmatter at all — treat entire content as body
        body = content
    else:
        body = parts[2]

    failures = []

    # ── Rule 1: path-citation resolution ─────────────────────────────────
    raw_matches = PATH_CITATION_RE.findall(body)
    # Restore the 'architecture/' prefix and deduplicate (preserve order)
    seen_citations = set()
    citations = []
    for m in raw_matches:
        full = f"architecture/{m}"
        if full not in seen_citations:
            seen_citations.add(full)
            citations.append(full)

    unresolved = [c for c in citations if not citation_exists(c, arch_root)]
    if unresolved:
        failures.append("unresolved-citations:" + ",".join(unresolved))

    # ── Rule 2: placeholder check in Architecture Anchors section ─────────
    aa_match = re.search(
        r'(?:^|\n)## Architecture Anchors\n(.*?)(?=\n## |\Z)',
        body,
        re.DOTALL
    )
    if aa_match:
        if re.search(r'\(filled by', aa_match.group(1), re.IGNORECASE):
            failures.append("placeholder-in-anchors:(filled by) found")

    if failures:
        print(f"FAIL {filepath} {'; '.join(failures)}")
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
    FAIL)
      emit FAIL "$short — $detail"
      ;;
    SKIP)
      emit WARN "$short (skipped: $detail)"
      ;;
    WARN)
      emit WARN "$short — $detail"
      ;;
    *)
      emit WARN "unexpected parser output: $line"
      ;;
  esac
done <<< "$PYTHON_OUTPUT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "verify-arch-anchor-resolution: PASS=$PASS WARN=$WARN FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
