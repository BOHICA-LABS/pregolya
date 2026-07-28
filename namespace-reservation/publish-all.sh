#!/usr/bin/env bash
# publish-all.sh — Publish all ferrochain namespace-reservation crates to crates.io
#
# HUMAN RUNS THIS — do not automate in CI, do not embed your token here.
#
# Prerequisites:
#   cargo login   # run once; token stored in ~/.cargo/credentials.toml
#
# Usage:
#   cd /Users/jmagady/Dev/ferrochain/.factory/namespace-reservation
#   bash publish-all.sh
#
# Self-test (no network contact, no cargo — exercises all four outcomes):
#   bash publish-all.sh --self-test
#
# Three-way name classification — an UNKNOWN name never counts as secured:
#
#   AVAILABLE  — crates.io returns 404: name is free; will be published in this run.
#   OWNED      — crates.io returns 200 AND the owners endpoint confirms EXPECTED_OWNER
#                is listed; name is already secured by us.  Counts toward TOTAL_SECURED.
#   SQUATTED   — crates.io returns 200 but EXPECTED_OWNER is absent from the owners list;
#                name is held by a third party.  Hard failure — never counts as secured.
#   UNKNOWN    — any non-200/non-404 crates.io response, OR the owners endpoint returns
#                non-200 for a 200-crate; name cannot be measured.  Fail-closed: never
#                counts as secured.  Re-run after resolving network/API issues.
#
# SUCCESS is printed only when ALL of these hold simultaneously:
#   (PUBLISHED + OWNED == EXPECTED_TOTAL) AND SQUATTED == 0 AND UNKNOWN == 0 AND ERRORS == 0
#
# Canonical roster: ARCH-INDEX.md §Canonical Crate Roster — 21 published crates.
# xtask is a workspace binary (not published) and is NOT in this list.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Canonical 21-crate roster (ARCH-INDEX.md §Canonical Crate Roster).
# Derivation: D6 base (9) + D1 (mcp, standard-tests) + D13 (server)
#             + P2-05 (sandbox, memory) + ADR-008 (macros) + D17-Q5 (3 x -sdk)
#             + D21 (prompts, vectorstores) + D23 (tools) = 21.
# ferrochain-prebuilt is NOT present — pre-D21 residue with no workspace crate.
CRATES=(
  ferrochain
  ferrochain-core
  ferrochain-graph
  ferrochain-checkpoint
  ferrochain-openai
  ferrochain-anthropic
  ferrochain-ollama
  ferrochain-community
  ferrochain-splitters
  ferrochain-mcp
  ferrochain-standard-tests
  ferrochain-server
  ferrochain-sandbox
  ferrochain-memory
  ferrochain-macros
  ferrochain-openai-sdk
  ferrochain-anthropic-sdk
  ferrochain-ollama-sdk
  ferrochain-prompts
  ferrochain-vectorstores
  ferrochain-tools
)

# Guard constant — must equal the number of entries in CRATES above.
# Adding a crate to CRATES without bumping EXPECTED_TOTAL causes the
# summary gate to fire even on an otherwise clean run.  That is intentional.
EXPECTED_TOTAL=21

# The crates.io / GitHub login that must appear in the owners list for a
# 200-response crate to be classified OWNED rather than SQUATTED.
# Must match your `cargo login` identity exactly (case-sensitive).
EXPECTED_OWNER="BOHICA-LABS"

UA="BOHICA-LABS/ferrochain namespace-reservation-publish/0.1.0 (github.com/BOHICA-LABS/ferrochain)"

# ---------------------------------------------------------------------------
# HTTP helper functions — production implementations.
# All four are replaced wholesale in --self-test mode below.
# ---------------------------------------------------------------------------

# Returns the HTTP status code for the crate's main endpoint, or "ERR" on
# curl failure (DNS, timeout, etc.).
_crate_http_code() {
  curl -s -o /dev/null -w "%{http_code}" -A "$UA" \
    "https://crates.io/api/v1/crates/$1" 2>/dev/null || echo "ERR"
}

# Returns the HTTP status code for the crate's owners endpoint, or "ERR" on
# curl failure.
_owners_http_code() {
  curl -s -o /dev/null -w "%{http_code}" -A "$UA" \
    "https://crates.io/api/v1/crates/$1/owners" 2>/dev/null || echo "ERR"
}

# Returns the JSON body from the crate's owners endpoint.
# Only called after _owners_http_code confirmed "200".
_owners_body() {
  curl -s -A "$UA" \
    "https://crates.io/api/v1/crates/$1/owners" 2>/dev/null
}

# Publishes the placeholder crate at the given manifest path.
_do_publish() {
  cargo publish --manifest-path "$SCRIPT_DIR/$1/Cargo.toml" 2>&1
}

# ---------------------------------------------------------------------------
# --self-test mode
# Overrides all helpers with local fixtures and a 4-crate roster that covers
# every classification outcome, without touching the network or cargo.
# ---------------------------------------------------------------------------
SELF_TEST=false
if [[ "${1:-}" == "--self-test" ]]; then
  SELF_TEST=true
  echo "=== SELF-TEST MODE — no network contact, no cargo publish ==="
  echo "    Four fixture crates exercise every classification outcome."
  echo ""

  CRATES=(
    ferrochain-test-available   # 404         → AVAILABLE: will be published (mocked)
    ferrochain-test-owned       # 200 + ours  → OWNED: already secured by us
    ferrochain-test-squatted    # 200 + theirs → SQUATTED: held by a third party
    ferrochain-test-unknown     # 503         → UNKNOWN: cannot be measured
  )
  EXPECTED_TOTAL=4

  _crate_http_code() {
    case "$1" in
      ferrochain-test-available)  echo "404" ;;
      ferrochain-test-owned)      echo "200" ;;
      ferrochain-test-squatted)   echo "200" ;;
      ferrochain-test-unknown)    echo "503" ;;
      *)                          echo "404" ;;
    esac
  }

  _owners_http_code() {
    case "$1" in
      ferrochain-test-owned)      echo "200" ;;
      ferrochain-test-squatted)   echo "200" ;;
      *)                          echo "ERR" ;;
    esac
  }

  _owners_body() {
    case "$1" in
      ferrochain-test-owned)
        echo '{"users":[{"login":"'"${EXPECTED_OWNER}"'","kind":"user","id":1,"avatar":"","url":""}]}'
        ;;
      ferrochain-test-squatted)
        echo '{"users":[{"login":"evil-squatter","kind":"user","id":999,"avatar":"","url":""}]}'
        ;;
      *)
        echo '{}'
        ;;
    esac
  }

  _do_publish() {
    echo ""
    echo "    (self-test: dry-run publish for $1 — no network contact)"
    return 0
  }
fi

# ---------------------------------------------------------------------------
# Pre-publish classification
# ---------------------------------------------------------------------------
echo "=== Pre-publish classification (expecting ${EXPECTED_TOTAL} crates) ==="
echo "    EXPECTED_OWNER: ${EXPECTED_OWNER}"
echo ""

AVAILABLE=()
OWNED=()
SQUATTED=()
UNKNOWN=()

for crate in "${CRATES[@]}"; do
  http_code=$(_crate_http_code "$crate")

  case "$http_code" in
    404)
      echo "  AVAILABLE:  $crate — free on crates.io, will publish now"
      AVAILABLE+=("$crate")
      ;;
    200)
      # Name exists — verify ownership (fail-closed: non-200 owners response → UNKNOWN)
      owners_code=$(_owners_http_code "$crate")
      if [ "$owners_code" != "200" ]; then
        echo "  UNKNOWN:    $crate — name exists but owners endpoint returned ${owners_code}; cannot confirm ownership"
        UNKNOWN+=("$crate")
      else
        body=$(_owners_body "$crate")
        # Match the "login" field in the owners JSON.  grep -E handles optional
        # whitespace around the colon for robustness across JSON formatters.
        if echo "$body" | grep -qE '"login"[[:space:]]*:[[:space:]]*"'"${EXPECTED_OWNER}"'"'; then
          echo "  OWNED:      $crate — exists on crates.io, owned by ${EXPECTED_OWNER}"
          OWNED+=("$crate")
        else
          echo "  SQUATTED:   $crate — ${EXPECTED_OWNER} is NOT an owner *** NAME POTENTIALLY LOST ***"
          SQUATTED+=("$crate")
        fi
      fi
      ;;
    *)
      # ERR, 429, 5xx, redirect, or any other unmeasured code — fail-closed
      echo "  UNKNOWN:    $crate — crates.io returned ${http_code}; cannot confirm availability"
      UNKNOWN+=("$crate")
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Warn and (in non-self-test mode) confirm before continuing.
# SQUATTED and UNKNOWN names require the operator's attention.
# OWNED names are already secured — no pause required.
# AVAILABLE names are the point of this run — no warning needed.
# ---------------------------------------------------------------------------
echo ""
NEEDS_CONFIRM=false

if [ "${#SQUATTED[@]}" -gt 0 ]; then
  echo "  WARNING: ${#SQUATTED[@]} name(s) appear squatted by a third party: ${SQUATTED[*]}"
  echo "           Continuing will NOT recover these names."
  NEEDS_CONFIRM=true
fi

if [ "${#UNKNOWN[@]}" -gt 0 ]; then
  echo "  WARNING: ${#UNKNOWN[@]} name(s) could not be measured: ${UNKNOWN[*]}"
  echo "           These will NOT count as secured regardless of what happens next."
  NEEDS_CONFIRM=true
fi

if [ "$NEEDS_CONFIRM" = "true" ] && [ "$SELF_TEST" = "false" ]; then
  read -r -p "Continue publishing the available crates? [y/N] " confirm
  case "$confirm" in
    [yY][eE][sS]|[yY]) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Publish AVAILABLE crates
# ---------------------------------------------------------------------------
echo ""
echo "=== Publishing ${#AVAILABLE[@]} available crate(s) ==="
PUBLISHED=()
ERRORS=()

for i in "${!AVAILABLE[@]}"; do
  crate="${AVAILABLE[$i]}"
  echo -n "  Publishing $crate ... "
  if _do_publish "$crate"; then
    echo "OK"
    PUBLISHED+=("$crate")
    # crates.io rate limit: pause between publishes, not after the last one
    if [ "$((i + 1))" -lt "${#AVAILABLE[@]}" ]; then
      echo "    (waiting 10s for crates.io rate limit)"
      sleep 10
    fi
  else
    echo "FAILED"
    ERRORS+=("$crate")
  fi
done

# ---------------------------------------------------------------------------
# Summary and guards
#
# An unmeasured name is not a secured name.
# SQUATTED and UNKNOWN entries always trigger a non-zero exit.
# The SUCCESS line is printed only when every condition passes.
# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "  Expected total  : ${EXPECTED_TOTAL}"
echo "  Published (new) : ${#PUBLISHED[@]} — ${PUBLISHED[*]:-none}"
echo "  Owned (already) : ${#OWNED[@]} — ${OWNED[*]:-none}"
echo "  Squatted        : ${#SQUATTED[@]} — ${SQUATTED[*]:-none}"
echo "  Unknown         : ${#UNKNOWN[@]} — ${UNKNOWN[*]:-none}"
echo "  Errors          : ${#ERRORS[@]} — ${ERRORS[*]:-none}"
echo ""

FAIL=false

if [ "${#ERRORS[@]}" -gt 0 ]; then
  echo "FATAL: ${#ERRORS[@]} crate(s) failed to publish: ${ERRORS[*]}"
  echo "       Fix the cargo errors above and re-run."
  FAIL=true
fi

if [ "${#SQUATTED[@]}" -gt 0 ]; then
  echo "FATAL: ${#SQUATTED[@]} name(s) squatted — ${EXPECTED_OWNER} is not the owner: ${SQUATTED[*]}"
  echo "       These names cannot be used for ferrochain without resolving third-party ownership."
  FAIL=true
fi

if [ "${#UNKNOWN[@]}" -gt 0 ]; then
  echo "FATAL: ${#UNKNOWN[@]} name(s) were not measurable (network/API error): ${UNKNOWN[*]}"
  echo "       An unmeasured name is not a secured name. Re-run after resolving network issues."
  FAIL=true
fi

# Final arithmetic guard: catches any logic gap not covered by the per-set checks above.
TOTAL_SECURED=$(( ${#PUBLISHED[@]} + ${#OWNED[@]} ))
if [ "${TOTAL_SECURED}" -lt "${EXPECTED_TOTAL}" ]; then
  echo "FATAL: Only ${TOTAL_SECURED} of ${EXPECTED_TOTAL} names are secured."
  echo "       Breakdown — published:${#PUBLISHED[@]} owned:${#OWNED[@]} squatted:${#SQUATTED[@]} unknown:${#UNKNOWN[@]} errors:${#ERRORS[@]}"
  FAIL=true
fi

if [ "$FAIL" = "true" ]; then
  exit 1
fi

echo "SUCCESS: All ${EXPECTED_TOTAL} ferrochain crate names are secured on crates.io."
