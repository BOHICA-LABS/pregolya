# Heartbeat Auto-Recovery Protocol — pregolya

**Status:** ACTIVE — human-mandated 2026-08-29 (D-318)
**Authority:** This document is the authoritative pregolya-specific operating protocol
for the durable cron heartbeat. Read before every autonomous recovery action.

---

## Purpose

Survive API transport errors, silent agent deaths, session disconnects, and pipeline
stalls without a human present. The factory must never sit stuck waiting for a dead
agent when there is safe, defined recovery work available.

This is the ACTIVE protocol. It extends the passive `HEARTBEAT.md` engine monitor
(which only alerts). This protocol recovers — it re-dispatches, re-drives, and
self-re-arms.

---

## Standing Policy: AUTO-RECOVER + DRIVE TO CONVERGENCE

**Policy (human-directed 2026-08-29, D-318):**
The heartbeat's default action is to keep the convergence loop running autonomously.
It re-dispatches dead or stalled agents and drives toward the next phase gate.
It STOPS and alerts ONLY at defined escalation boundaries (see §Escalation Boundary).

### Composition with standing directives

| Directive | Composition |
|-----------|-------------|
| DIRECTIVE 1 (2026-07-13): Keep going to convergence; never ask "should I continue?" | The heartbeat inherits this: it does NOT pause the pipeline or ask permission to re-dispatch unless at an escalation boundary. |
| DIRECTIVE 2 (2026-07-29): fix-in-scope is the default; deferral requires explicit human permission | The heartbeat applies this to recovery: if a dead agent left behind incomplete-but-recoverable work, the heartbeat assesses completeness and fixes in scope, not in a future burst. |
| DIRECTIVE 3 (2026-08-29, this protocol): AUTO-RECOVER + DRIVE TO CONVERGENCE | Overarching policy governing cron-fired autonomous orchestration behavior. Supersedes any engine-default "ask before re-dispatching" behavior for this project. |

---

## 5-State Classification Loop

At each heartbeat fire, the orchestrator executes this classification loop in order.
The **first matching state wins**; do not cascade through lower states once matched.

### State A: HEALTHY IN-FLIGHT

**Condition:** At least one active background agent is making forward progress (recent
tool-use activity, no error signal), and STATE.md `current_step` shows the expected
next action is already in flight.

**Action:** No recovery needed.

**Output:** Log `HEARTBEAT_OK` and exit.

---

### State B: DEAD / FAILED AGENT

**Condition:** A background agent that was dispatched shows error status, was killed by
an API transport failure, or is no longer listed in `/tasks` but left STATE.md in a
mid-burst state (e.g., current_step shows "IN PROGRESS" with a partial output set).

**Worked example — round-42 story-writer API death:**
During the round-42 fix-burst (D-317), the story-writer agent was dispatched to close
three story-file findings (F-P2A176-01, F-P2A177-01, F-P2A177-02, F-P2A179-01). The
agent died mid-task after writing S-1.04 but before completing S-2.11. D-316 recorded
the session-wrap state: "story-writer PENDING." Recovery was performed by:

1. Reading STATE.md §Session-Resume-Checkpoint to identify exactly which story files
   were partially updated and which acceptance criteria were still outstanding.
2. Grepping the relevant story files (S-1.04, S-1.26, S-2.11) to verify which ACs
   were already written vs still missing.
3. Re-dispatching story-writer with a narrowed scope: "complete only the remaining ACs
   per the D-316 session-wrap scope list; do NOT re-write ACs already present."
4. After completion, running the state-manager burst to close D-317.

**The "verify completeness, never trust self-disclosure" rule:**
A dead agent's last message may claim it completed more than it actually did. Do NOT
accept self-disclosure. Always verify by reading the actual artifacts:

- For story files: grep for each AC number to confirm the body is present.
- For spec files: read the relevant sections to confirm they match the BC/ADR contract.
- For STATE.md: confirm the version bump and decision row are present.

Re-dispatch only the missing work. Do not re-dispatch work that is already complete.

**Output:** Log recovery rationale, dispatch the gap, verify after completion.

---

### State C: STALLED

**Condition:** An agent was dispatched but has not made observable forward progress
(no tool-use activity) beyond its expected timeout, or STATE.md has not advanced in
more than one heartbeat cycle after a non-final step was recorded.

**Expected timeout guidance:**

| Agent type | Nominal completion time | Stall threshold |
|------------|------------------------|-----------------|
| Adversary pass (1 lens) | 5-15 min | 25 min |
| Fix-burst (single specialist) | 10-20 min | 35 min |
| Session-wrap (state-manager) | 3-8 min | 15 min |
| Full fix-burst (architect + PO + story-writer) | 30-60 min | 90 min |

**Action:** Re-dispatch the stalled agent with the same scope. If the same agent stalls
twice consecutively (two heartbeat cycles with no progress), escalate per
§Escalation Boundary condition 5.

---

### State D: IDLE WITH PENDING NEXT

**Condition:** No agents are in flight, no agents are stalled, but STATE.md
`current_step` shows a clear NEXT action (e.g., "NEXT: round-43").

**Action:** Dispatch the NEXT action per the orchestrator routing table in CLAUDE.md
§Agent-Routing-Table. Do NOT dispatch the next action yourself — you are the
orchestrator; use the Agent tool with the appropriate specialist.

**Key constraint:** Always confirm the `.factory/` worktree is clean (no pending
uncommitted changes) before dispatching a new round. If there is uncommitted work,
commit it via state-manager first per TD-VSDD-053.

---

### State E: HUMAN-APPROVAL GATE OR TRUE BLOCKER

**Condition:** See §Escalation Boundary. Any of the listed conditions is met.

**Action:** STOP autonomous recovery. Output `[HEARTBEAT ALERT]` with a clear reason.
Do NOT proceed past this point without explicit human input.

---

## Escalation Boundary

The heartbeat STOPS and alerts (does NOT auto-recover) under these conditions:

1. **Human-approval phase gate reached.** STATE.md shows the pipeline is at a defined
   human review gate (e.g., HRQ-1 through HRQ-6, Phase-2 approval gate, Phase-4
   Holdout gating, force-push needed for factory-artifacts). These require a human
   decision, not autonomous continuation.

2. **Repository missing or unreachable.** The workspace path does not exist, git
   commands fail, or `.factory/` is not a valid worktree on `factory-artifacts`.
   Recovery: report the exact error and the recovery command
   (`git worktree add .factory factory-artifacts`).

3. **Unresolvable merge conflict.** A git operation produces a conflict that cannot be
   resolved by the state-manager's single-writer discipline. This requires human
   judgment about which version to keep.

4. **Force-push required.** Any scenario where recovering the correct state requires
   `git push --force` or `git push --force-with-lease` to `factory-artifacts` (or
   any other branch). Per the git safety protocol in CLAUDE.md §Non-Negotiable-Git-Rules,
   force-push always requires explicit human approval.

5. **Budget / token exhaustion.** The session approaches context or cost limits such
   that starting a new specialist agent would exceed budget. Alert with current
   budget status.

6. **Same agent stalls for two consecutive heartbeat cycles.** Two re-dispatches with
   no progress on the same scope indicates a structural problem (bug, missing tool,
   spec contradiction) that a human needs to investigate.

7. **Finding introduced that has no clear ownership-route in the Agent Routing Table.**
   The orchestrator cannot determine which specialist to dispatch. Rather than guess,
   stop and report.

---

## Interaction with the Passive Engine HEARTBEAT.md Monitor

The engine provides a passive `HEARTBEAT.md` monitor that:
- Fires at a regular interval when the REPL is idle
- Reads STATE.md and logs current phase + step
- ALERTS on anomalies (stalled phase, dirty worktree, SHA drift)

This protocol EXTENDS that behavior. The engine monitor alerts; this protocol recovers.
When both are active:
- The engine monitor fires first and reports status.
- If the engine monitor would alert, this protocol evaluates whether the condition is
  in the recoverable states (B/C/D) or the escalation boundary (E).
- If recoverable: this protocol acts. The engine monitor's alert is superseded.
- If escalation boundary: both alert. Human sees two consistent alerts.

---

## Cron Facts

| Field | Value |
|-------|-------|
| Job identifier | `60FC8EB8` (Claude Code scheduler; written uppercase per TD-VSDD-091 records discipline) |
| Schedule expression | `8,23,38,53 * * * *` |
| Cadence | ~15 minutes; fires at :08/:23/:38/:53 past each hour |
| Offset rationale | Off the :00/:30 marks to avoid fleet-wide API load spikes and to respect the ~15-min per-prompt context cache window |
| Persistence | `durable: true` — stored in `.claude/scheduled_tasks.json`; survives session restarts |
| Recurrence | `recurring: true` |
| Auto-expiry | Claude Code durable crons auto-expire after 7 days (fire one final time, then delete) |
| Firing condition | REPL must be idle (not mid-query); cron does not interrupt active sessions |
| Self-re-arm | Step 4 of the heartbeat prompt (`CronList`; if missing or within ~1 day of 7-day expiry, recreate) |
| Teardown | `CronDelete 60FC8EB8` |

### Self-re-arm logic (Step 4 of the heartbeat prompt)

The 7-day auto-expiry means the cron silently disappears ~7 days after creation if not
re-armed. Step 4 of every heartbeat execution:

1. Run `CronList` to see all scheduled jobs.
2. Check whether a job matching the heartbeat prompt is present.
3. If absent OR if the job's creation date is more than 6 days ago (within ~1 day of
   the 7-day expiry): recreate using `CronCreate` with the same parameters.
4. The cron prompt itself (step 3 of the heartbeat) instructs the heartbeat to perform
   this re-arm — it is a standing part of the protocol, not an optional step.

This creates a durable self-maintaining loop: even if the REPL is restarted, the next
heartbeat fire will re-arm the cron if it is missing.

---

## Session-Start Self-Heal

The SessionStart hook provides an additional durability layer beyond the 7-day cron
auto-expiry. Every time a new Claude Code session starts in the pregolya workspace,
the hook runs `ensure-heartbeat.sh` before the REPL becomes interactive.

### What it does

`ensure-heartbeat.sh` (`.factory/hooks/ensure-heartbeat.sh`) examines
`.claude/scheduled_tasks.json` and applies one of three idempotent operations:

| Case | Detection | Action |
|------|-----------|--------|
| No `[HEARTBEAT]` task in store | `jq` finds no task with `startswith("[HEARTBEAT]")` | **Seed:** write a new task entry with the canonical schedule + prompt from `.factory/hooks/heartbeat-cron-prompt.txt` |
| Task exists but `createdAt` ≥ 6 days ago | Age math in milliseconds | **Re-arm:** refresh `createdAt` and `prompt` from template; resets the 7-day expiry clock |
| Task exists and fresh (< 6 days old) | Same age check | **No-op:** log `present, fresh` and exit 0 |

The script is idempotent — running it multiple times produces the same result.

### What it closes

- **7-day expiry gap:** if the cron expired between sessions (REPL was offline for
  7+ days), the next session re-seeds it automatically — no manual `CronCreate` required.
- **No-re-verification gap:** the heartbeat prompt is kept fresh from the canonical
  template file at `.factory/hooks/heartbeat-cron-prompt.txt` on every re-arm. If
  the prompt is edited, the next re-arm picks up the edit automatically.

### Path resolution (nested worktree safety)

`ensure-heartbeat.sh` resolves the project root using `$CLAUDE_PROJECT_DIR` (set by
the SessionStart hook), falling back to path traversal (`SCRIPT_DIR/../..`), then
strips any `/.factory` suffix as a belt-and-suspenders check. It NEVER uses `git
rev-parse --show-toplevel` — this would return `.factory/` (the nested worktree root)
rather than the actual project root. See `.factory/rules/heartbeat-setup-guide.md`
§SessionStart-Hook for the full PORTABILITY GOTCHA explanation.

### Setup

The hook is installed in `.claude/settings.json` (project-scoped, committed to
`develop` at `bfe0592`). The hook entry runs:

```
bash ${CLAUDE_PROJECT_DIR}/.factory/hooks/ensure-heartbeat.sh
```

at every SessionStart event for this project.

---

## Recovery Worked-Examples (this session, 2026-08-30)

Two agents died on API transport errors during the round-42 fix-burst + hook-builder
session and were recovered inline using the verify-then-continue /
verify-then-re-dispatch-specific-gap pattern. These are evidence the loop works.

### Example 1 — story-writer round-42 (2026-08-30)

**Failure:** story-writer was dispatched to close findings F-P2A176-01, F-P2A177-01,
F-P2A177-02, and F-P2A179-01 across S-1.04, S-1.26, and S-2.11. The agent died
mid-task via API transport error after writing S-1.04 changes but before completing
S-2.11.

**Detection:** D-316 session-wrap state recorded "story-writer PENDING."

**Recovery:**
1. Read STATE.md §Session-Resume-Checkpoint to identify the incomplete scope.
2. Grepped S-1.04, S-1.26, and S-2.11 to verify which ACs were already written vs still missing.
3. Re-dispatched story-writer with narrowed scope: "complete only the remaining ACs
   per the D-316 session-wrap scope list; do NOT re-write ACs already present."
4. After completion, state-manager closed D-317.

**Pattern:** verify completeness by reading actual files; never trust self-disclosure;
re-dispatch only the gap.

### Example 2 — hook-builder (2026-08-30)

**Failure:** the agent building `ensure-heartbeat.sh` died on an API transport error
partway through implementation.

**Detection:** working tree showed partial file; the agent's final message was cut off
before all logic was written.

**Recovery:**
1. Read the partial file to see exactly what was already written.
2. Identified the specific remaining gap (path-resolution logic and re-arm branch).
3. Re-dispatched with a narrowed scope targeting only the missing code sections.
4. Tests A-D all passed after re-dispatch completed.

**Pattern:** same verify-then-re-dispatch-specific-gap discipline. No full re-write.

---

## Standing Orchestrator Constraints (always apply during heartbeat recovery)

These constraints from CLAUDE.md apply unconditionally during heartbeat-fired
autonomous recovery:

- **Worktree health gate on cold resume.** On any cold resume (no agents in flight,
  no recent STATE.md updates), run `vsdd-factory:factory-worktree-health` before
  dispatching any specialist.
- **State-manager is always LAST in the burst.** After any set of specialist agents
  completes a burst, the state-manager closes the burst with a single commit per
  TD-VSDD-053. Never commit before all specialists in the burst have finished.
- **Single-commit-per-burst (TD-VSDD-053).** One atomic commit per logical burst.
  No "Stage 1" + "Stage 2 backfill" patterns.
- **Records-lint gate (TD-VSDD-091).** `records-lint.sh` must exit 0 before any
  factory-artifacts commit. The heartbeat must not suppress this gate.
- **Frozen-HEAD streak (BC-5.39.001).** A docs/ops commit (no spec-perimeter change)
  does NOT reset the adversary streak. Only a new spec-perimeter push resets it.
  The heartbeat must correctly distinguish docs/ops bursts from spec-perimeter bursts
  when deciding whether to reset `streak 0/3`.
- **No self-delegation.** The orchestrator does not write files itself (except
  CLAUDE.md when human-mandated). All file writes are delegated to the correct
  specialist per the routing table.

---

## Quick-Reference Checklist (at each heartbeat fire)

```
[ ] 1. Read /tasks — are any agents in flight?
[ ] 2. Read .factory/STATE.md — what is current_step? what is NEXT?
[ ] 3. Classify: HEALTHY / DEAD / STALLED / IDLE-PENDING / GATE-OR-BLOCKER
[ ] 4. If HEALTHY: log HEARTBEAT_OK, exit.
[ ] 5. If DEAD: verify artifact completeness (read actual files), re-dispatch gap only.
[ ] 6. If STALLED: re-dispatch same scope; if 2nd consecutive stall → escalate.
[ ] 7. If IDLE-PENDING: check worktree clean, dispatch NEXT per routing table.
[ ] 8. If GATE-OR-BLOCKER: STOP, output [HEARTBEAT ALERT] with reason.
[ ] 9. CronList — re-arm if missing or near 7-day expiry.
[ ] 10. Verify state-manager is LAST; single-commit-per-burst honored.
```
