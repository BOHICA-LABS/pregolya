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
# What it does:
#   - Re-verifies each crate name is still available on crates.io (exits early if taken)
#   - Publishes crates in dependency order with a 10-second pause between each
#     (crates.io has rate limits)
#   - Reports success/failure for each crate
#
# Note: version 0.0.0 crates are placeholder reservations only.
# Real releases will use semantic versioning starting from 0.1.0.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CRATES=(
  ferrochain
  ferrochain-core
  ferrochain-graph
  ferrochain-checkpoint
  ferrochain-prebuilt
  ferrochain-openai
  ferrochain-anthropic
  ferrochain-ollama
  ferrochain-community
  ferrochain-splitters
)

UA="BOHICA-LABS/ferrochain namespace-reservation-publish/0.1.0 (github.com/BOHICA-LABS/ferrochain)"

echo "=== Pre-publish availability check ==="
TAKEN=()
for crate in "${CRATES[@]}"; do
  http_code=$(curl -s -o /dev/null -w "%{http_code}" -A "$UA" \
    "https://crates.io/api/v1/crates/$crate")
  if [ "$http_code" = "200" ]; then
    echo "  TAKEN (skip): $crate — already exists on crates.io"
    TAKEN+=("$crate")
  elif [ "$http_code" = "404" ]; then
    echo "  AVAILABLE:    $crate"
  else
    echo "  UNKNOWN ($http_code): $crate — check manually before proceeding"
    TAKEN+=("$crate")
  fi
done

if [ ${#TAKEN[@]} -gt 0 ]; then
  echo ""
  echo "WARNING: ${#TAKEN[@]} crate(s) already taken or unknown: ${TAKEN[*]}"
  echo "Review above before continuing."
  read -r -p "Continue publishing the available crates? [y/N] " confirm
  case "$confirm" in
    [yY][eE][sS]|[yY]) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
fi

echo ""
echo "=== Publishing crates ==="
PUBLISHED=()
ERRORS=()

for crate in "${CRATES[@]}"; do
  # Skip already-taken crates
  skip=false
  for t in "${TAKEN[@]}"; do
    [ "$t" = "$crate" ] && skip=true && break
  done
  if [ "$skip" = "true" ]; then
    echo "  SKIP: $crate (taken/unknown)"
    continue
  fi

  echo -n "  Publishing $crate ... "
  if cargo publish --manifest-path "$SCRIPT_DIR/$crate/Cargo.toml" 2>&1; then
    echo "OK"
    PUBLISHED+=("$crate")
    # crates.io rate limit: wait between publishes
    if [ "${#PUBLISHED[@]}" -lt "${#CRATES[@]}" ]; then
      echo "    (waiting 10s for crates.io rate limit)"
      sleep 10
    fi
  else
    echo "FAILED"
    ERRORS+=("$crate")
  fi
done

echo ""
echo "=== Summary ==="
echo "  Published: ${#PUBLISHED[@]} — ${PUBLISHED[*]:-none}"
echo "  Skipped:   ${#TAKEN[@]}    — ${TAKEN[*]:-none}"
echo "  Errors:    ${#ERRORS[@]}   — ${ERRORS[*]:-none}"

if [ ${#ERRORS[@]} -gt 0 ]; then
  exit 1
fi
