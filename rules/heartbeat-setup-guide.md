# Heartbeat Auto-Recovery Setup Guide — Portable Reproduction

**Status:** ACTIVE — created 2026-08-29 (D-318)
**Audience:** Any operator standing up the heartbeat auto-recovery pattern on a new
project. Replace every `<PLACEHOLDER>` with your project-specific value.

---

## What This Sets Up

A durable recurring cron job that fires every ~15 minutes while the Claude Code REPL
is idle. The cron inspects in-flight agents, reads pipeline state, and either logs
"all clear" or re-dispatches stalled/dead agents — keeping the pipeline running
without a human present.

The protocol this cron invokes is documented in the authoritative protocol file
(`.factory/rules/heartbeat-recovery-protocol.md` for pregolya; adapt path for your
project).

---

## Step-by-Step Reproduction

### Step 1 — Choose a cadence

The recommended cadence is **~15 minutes**, offset from the hour/half-hour marks.

Rationale:
- 15 minutes is short enough to catch stalled agents before they waste a full session.
- Offset from :00/:30 avoids API load spikes from fleet-wide cron fires.
- 15 minutes aligns with the approximate context cache window — each fire re-reads
  STATE.md; fires more frequent than the cache window regenerate context repeatedly
  and increase cost.

Recommended schedule: `8,23,38,53 * * * *` (fires at :08, :23, :38, :53 past each hour).

For a faster cadence (e.g., 5 min): `3,8,13,18,23,28,33,38,43,48,53,58 * * * *`.
For a slower cadence (e.g., 30 min): `7,37 * * * *`.

### Step 2 — Create the durable cron job

Use the `CronCreate` tool in Claude Code:

```
CronCreate(
  expression: "8,23,38,53 * * * *",
  prompt: <heartbeat-prompt — see §Canonical Heartbeat Prompt Template>,
  durable: true,
  recurring: true
)
```

`durable: true` persists the job to `.claude/scheduled_tasks.json`. The job survives
REPL restarts.

`recurring: true` ensures the job fires repeatedly on the schedule (not just once).

### Step 3 — Verify

After creation, run `CronList` to confirm the job appears with:
- The correct schedule expression
- `durable: true`
- `recurring: true`
- A job identifier (record this — needed for teardown and re-arm checks)

The durable job is stored at: `~/.claude/scheduled_tasks.json` (user-level persistence;
survives project workspace restarts).

### Step 4 — Record the job identifier

Write the job identifier into your project's state tracking. For pregolya, this is
recorded in STATE.md (D-318 decision row) and in `.factory/rules/heartbeat-recovery-protocol.md`
§Cron-Facts. For your project, record it wherever your project's operational decisions live.

---

## SessionStart Hook (auto-setup on every new session)

The SessionStart hook provides a second durability layer that runs `ensure-heartbeat.sh`
automatically at the start of every Claude Code session. This closes two gaps the cron
alone cannot close:

1. **7-day expiry gap:** if the REPL was offline when the cron expired, the cron is
   silently gone — no alert, no retry. The SessionStart hook re-seeds it on the next
   session start.
2. **No-re-verification gap:** the heartbeat prompt is refreshed from the canonical
   template file at `.factory/hooks/heartbeat-cron-prompt.txt` at every re-arm, so
   prompt edits propagate automatically.

### `.claude/settings.json` snippet

Add the following to `.claude/settings.json` in the **project root** (not `~/.claude/`).
This scopes the hook to this project only.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PROJECT_DIR}/.factory/hooks/ensure-heartbeat.sh"
          }
        ]
      }
    ]
  }
}
```

For pregolya, this file is at `/Users/jmagady/Dev/pregolya/.claude/settings.json`,
committed to `develop` at `bfe0592`.

### `ensure-heartbeat.sh` resolution strategy

The script uses this priority order to resolve the project root:

1. `$CLAUDE_PROJECT_DIR` — set by Claude Code's SessionStart hook mechanism; most
   reliable because it is injected by the harness before the script runs.
2. Path traversal: `$(cd "${SCRIPT_DIR}/../.." && pwd)` — strips two levels from the
   script's directory (`.factory/hooks/` → project root).
3. Belt-and-suspenders: strip any `/.factory` suffix from the resolved root — guards
   against edge-case double-traversal where `SCRIPT_DIR` resolved into the worktree.

### PORTABILITY GOTCHA — nested git worktrees

> **Do NOT resolve the project root with `git rev-parse --show-toplevel`** in any
> script or hook that runs from inside a nested git worktree directory.

**Why:** `.factory/` is mounted as a git worktree via
`git worktree add .factory factory-artifacts`. When you run
`git rev-parse --show-toplevel` from inside `.factory/` (or any subdirectory of it),
git returns the worktree root — `.factory/` itself — NOT the parent project root. This
causes the script to compute the wrong store path (e.g., resolving
`.factory/.claude/scheduled_tasks.json` instead of `.claude/scheduled_tasks.json`),
silently writing to or reading from the wrong location with no error.

**Affected directories in pregolya:** `.factory/` (always) and `.factory-project/` in
multi-repo mode.

**Correct approach:** use `$CLAUDE_PROJECT_DIR` (injected by the SessionStart hook) or
explicit path traversal from the script's known location. Both avoid git entirely.

---

## Canonical Heartbeat Prompt Template

Replace `<WORKSPACE_PATH>`, `<PROJECT_NAME>`, `<PROTOCOL_PATH>`, and `<POLICY_NAME>`
with your project-specific values. The bracketed markers are placeholders.

```
[HEARTBEAT] Autonomous auto-recovery check for the <PROJECT_NAME> pipeline.
Workspace: <WORKSPACE_PATH>.
Standing policy: <POLICY_NAME> (e.g., AUTO-RECOVER + DRIVE TO CONVERGENCE).
You are the orchestrator; delegate all work, never write files yourself.

1. Inspect in-flight background agents (/tasks). Read <WORKSPACE_PATH>/.factory/STATE.md
   (current phase, current_step NEXT action, streak, convergence_status).

2. Classify and act:
   (a) HEALTHY IN-FLIGHT → HEARTBEAT_OK, no action;
   (b) DEAD/FAILED AGENT → assess working tree completeness, continue the burst if
       complete else re-dispatch the specific gap, verify independently;
   (c) STALLED (past timeout / phase idle) → re-dispatch;
   (d) IDLE WITH PENDING NEXT → dispatch the NEXT action per the routing table;
   (e) HUMAN-APPROVAL GATE or TRUE BLOCKER → STOP + [HEARTBEAT ALERT] with reason.

3. Honor standing constraints: worktree-health gate on cold resume,
   state-manager LAST in burst, single-commit-per-burst, records-lint,
   frozen-HEAD streak, no self-delegation.

4. RE-ARM: CronList; if the heartbeat cron is missing or within ~1 day of the
   7-day auto-expiry, recreate the durable heartbeat cron.

5. Follow the standing protocol at <PROTOCOL_PATH> (authoritative).
```

### Pregolya instantiation (reference)

The prompt used for pregolya (D-318) is the template above with these substitutions:

| Placeholder | Pregolya value |
|-------------|----------------|
| `<WORKSPACE_PATH>` | `/Users/jmagady/Dev/pregolya` |
| `<PROJECT_NAME>` | `pregolya` |
| `<POLICY_NAME>` | `AUTO-RECOVER + DRIVE TO CONVERGENCE (user DIRECTIVE 1 + heartbeat policy D-318)` |
| `<PROTOCOL_PATH>` | `.factory/rules/heartbeat-recovery-protocol.md` |

---

## Adaptation Notes

### How to tune cadence

- Set cadence based on expected agent completion time. For agents that typically
  complete in 10-20 minutes, a 15-minute heartbeat gives one recovery window before
  doubling the wait time.
- For projects with very long-running bursts (e.g., 45-60 min), increase to 30-minute
  cadence to reduce unnecessary re-dispatch noise.
- Always offset from :00/:30 to avoid fleet-wide load spikes.

### How to set the policy

Two common policies:

**AUTO-RECOVER + DRIVE TO CONVERGENCE** (recommended for active development):
The heartbeat re-dispatches dead/stalled agents and drives toward the next gate.
Composes with a "keep going to convergence" directive.

**ALERT ONLY** (recommended for pre-production projects or when human must approve
each step):
The heartbeat only logs status and alerts on anomalies. No autonomous re-dispatch.
Useful when the project is in a phase requiring human approval at every step.

### What to change for a project without `.factory/`

If your project does not use the Dark Factory pipeline:
1. Replace the STATE.md read step with your project's equivalent state file.
2. Replace "current_step NEXT action, streak, convergence_status" with your project's
   equivalent status fields.
3. Replace the routing table reference with your project's agent routing table.
4. The 5-state classification loop is universal — adapt the detection logic for your
   pipeline's equivalent of "in-flight", "dead", "stalled", and "idle with pending next".

### Adjusting escalation boundaries

The default escalation boundaries (human-approval gates, force-push required, budget
exhaustion, 2 consecutive stalls) are conservative and apply to most projects without
change. To adjust:
- Add project-specific human-approval gates to State E condition 1.
- Adjust stall thresholds in State C based on your project's typical agent completion times.
- Never remove force-push from the escalation boundary — this is a safety invariant.

---

## Teardown

To stop the heartbeat:

```
CronDelete <JOB-IDENTIFIER>
```

For pregolya, the job identifier is `60FC8EB8` (see D-318 / heartbeat-recovery-protocol.md
§Cron-Facts). Replace with your project's job identifier.

After deletion, confirm with `CronList` that no matching job appears.

---

## Caveats

### 7-day auto-expiry

Claude Code durable crons auto-expire after 7 days (they fire one final time, then
delete themselves). The heartbeat prompt includes a self-re-arm step (Step 4) that
recreates the cron before expiry. If the REPL is not running when the final fire
occurs, the cron silently disappears — resume by manually running Step 2 above.

### Idle-only firing

The cron fires only while the REPL is idle (not mid-query). If you are actively
working in the REPL, the heartbeat will not interrupt. This is a feature — it avoids
disrupting active sessions.

### Cost of frequent fires

Each heartbeat fire reads STATE.md (uncached after a restart) and may dispatch agents.
At 15-minute intervals, a full 8-hour session generates ~32 heartbeat fires. If each
fire results in a no-op `HEARTBEAT_OK`, cost is minimal (a few input tokens per fire).
If each fire re-dispatches a stalled agent, cost is that agent's execution cost.
Balance cadence against session budget.

### Model context

The cron prompt runs in a fresh context. It does not inherit prior conversation
history. The prompt must be self-contained enough for the heartbeat to act without
prior context (hence the instruction to read STATE.md as the first step).

---

## Portability Checklist

Use this checklist to stand up the heartbeat on a new project in under 5 minutes.

```
[ ] Identify workspace path (absolute) → substitute for <WORKSPACE_PATH>
[ ] Identify project name → substitute for <PROJECT_NAME>
[ ] Choose policy: AUTO-RECOVER or ALERT-ONLY → substitute for <POLICY_NAME>
[ ] Create/confirm a protocol file → substitute path for <PROTOCOL_PATH>
[ ] Choose cadence (recommend 15 min, off-minute offset)
[ ] Run CronCreate with durable: true, recurring: true
[ ] Run CronList to confirm job appears
[ ] Record job identifier in project state (decision log or equivalent)
[ ] Add re-arm check to protocol file §Cron-Facts
[ ] Install SessionStart hook in .claude/settings.json (project root, NOT ~/.claude/)
    using "bash ${CLAUDE_PROJECT_DIR}/.factory/hooks/ensure-heartbeat.sh"
[ ] Commit ensure-heartbeat.sh + heartbeat-cron-prompt.txt to factory-artifacts branch
[ ] PORTABILITY GOTCHA: if .factory/ is a nested git worktree, do NOT use
    git rev-parse --show-toplevel in ensure-heartbeat.sh — use $CLAUDE_PROJECT_DIR
    or path traversal (see §PORTABILITY-GOTCHA above)
[ ] Test: wait for one heartbeat fire; confirm it reads state correctly
[ ] Note: job will auto-expire in 7 days — SessionStart self-heal + cron re-arm handle this
```

Total: ~5-8 minutes if you have the workspace path and policy ready.
