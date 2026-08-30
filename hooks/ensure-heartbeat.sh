#!/usr/bin/env bash
# ensure-heartbeat.sh — Idempotent heartbeat cron self-healing script.
# Guarantees exactly one [HEARTBEAT] task exists in .claude/scheduled_tasks.json.
# Called by the Claude Code SessionStart hook.
# Graceful degradation: exits 0 on any non-fatal error so it never blocks a session.
#
# Human-mandated 2026-08-30. See .factory/hooks/heartbeat-cron-prompt.txt for
# the canonical prompt body.
set -euo pipefail

# ── Resolve paths ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Derive repo root using CLAUDE_PROJECT_DIR (set by SessionStart hook) when available.
# Do NOT use git rev-parse --show-toplevel: .factory/ is a nested git worktree and
# rev-parse would return the worktree root (.factory/) rather than the real project root.
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  REPO_ROOT="${CLAUDE_PROJECT_DIR}"
else
  REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi
# Belt-and-suspenders: if REPO_ROOT somehow resolved to inside .factory, strip the suffix.
REPO_ROOT="${REPO_ROOT%/.factory}"

STORE="${REPO_ROOT}/.claude/scheduled_tasks.json"
PROMPT_TEMPLATE="${SCRIPT_DIR}/heartbeat-cron-prompt.txt"
CRON_SCHEDULE="8,23,38,53 * * * *"
HEARTBEAT_ID="60fc8eb8"
# 6 days in milliseconds (re-arm threshold; 7-day expiry → warn at day 6).
SIX_DAYS_MS=$((6 * 24 * 60 * 60 * 1000))

# ── Graceful dependency check ────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "[ensure-heartbeat] jq missing, skipped" >&2
  exit 0
fi

if [[ ! -f "${PROMPT_TEMPLATE}" ]]; then
  echo "[ensure-heartbeat] prompt template not found at ${PROMPT_TEMPLATE}, skipped" >&2
  exit 0
fi

# ── Ensure store directory and file exist ────────────────────────────────────
STORE_DIR="$(dirname "${STORE}")"
if [[ ! -d "${STORE_DIR}" ]]; then
  mkdir -p "${STORE_DIR}"
fi
if [[ ! -f "${STORE}" ]]; then
  echo '{"tasks": []}' > "${STORE}"
fi

# Validate existing JSON is parseable; if corrupt, bail gracefully.
if ! jq empty "${STORE}" 2>/dev/null; then
  echo "[ensure-heartbeat] store JSON invalid, skipped" >&2
  exit 0
fi

# ── Read prompt body from template ───────────────────────────────────────────
PROMPT_BODY="$(cat "${PROMPT_TEMPLATE}")"

# ── Check for existing heartbeat task ────────────────────────────────────────
NOW_MS="$(date +%s)000"
# Use jq to detect a task whose prompt starts with "[HEARTBEAT]"
EXISTING="$(jq 'first(.tasks[] | select(.prompt | startswith("[HEARTBEAT]"))) // empty' "${STORE}" 2>/dev/null || true)"

if [[ -z "${EXISTING}" ]]; then
  # ── CASE: no heartbeat task → seed one ──────────────────────────────────
  TEMP_FILE="$(mktemp "${STORE}.tmp.XXXXXX")"
  jq --arg id "${HEARTBEAT_ID}" \
     --arg cron "${CRON_SCHEDULE}" \
     --arg prompt "${PROMPT_BODY}" \
     --argjson created_at "${NOW_MS}" \
     '.tasks += [{
       "id": $id,
       "cron": $cron,
       "prompt": $prompt,
       "createdAt": $created_at,
       "recurring": true
     }]' "${STORE}" > "${TEMP_FILE}"
  mv "${TEMP_FILE}" "${STORE}"
  echo "[ensure-heartbeat] seeded"
  exit 0
fi

# ── CASE: heartbeat task exists — check age ──────────────────────────────────
CREATED_AT="$(echo "${EXISTING}" | jq '.createdAt // 0')"
AGE_MS=$(( NOW_MS - CREATED_AT ))

if (( AGE_MS >= SIX_DAYS_MS )); then
  # Re-arm: refresh createdAt and prompt from template.
  TEMP_FILE="$(mktemp "${STORE}.tmp.XXXXXX")"
  jq --arg prompt "${PROMPT_BODY}" \
     --argjson created_at "${NOW_MS}" \
     '(.tasks[] | select(.prompt | startswith("[HEARTBEAT]"))) |= . + {
       "createdAt": $created_at,
       "prompt": $prompt
     }' "${STORE}" > "${TEMP_FILE}"
  mv "${TEMP_FILE}" "${STORE}"
  echo "[ensure-heartbeat] re-armed"
  exit 0
fi

# ── CASE: present and fresh — no-op ─────────────────────────────────────────
echo "[ensure-heartbeat] present, fresh"
exit 0
