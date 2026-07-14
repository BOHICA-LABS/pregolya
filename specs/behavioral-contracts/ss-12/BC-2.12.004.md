---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.004
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-12
capability: CAP-014
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/platform/behavioral-intent.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "2fa3aaf38e5dd19ee39c3df5596438a531328d2cdf99120e4914b0e4275419f1"
---

# BC-2.12.004: CronSchedule Creation and Proactive Run Execution

## Description

`ferrochain-server` exposes a `CronSchedule` resource that registers a recurring,
proactive run trigger on a named Assistant. On each schedule firing, the server
creates a new Run with a **fresh, isolated session** — no prior thread context is
shared across firings unless the operator explicitly wires a persistent thread via
`RunnableConfig`. This contract specifies the full lifecycle: create, enable, fire, disable,
and delete, plus the isolation guarantee that distinguishes proactive runs from
interactive runs.

## Preconditions

1. A valid `Assistant` record exists for the `assistant_id` referenced in the schedule
   creation request.
2. The `schedule` field is a syntactically valid cron expression (five or six fields,
   standard quartz-compatible or POSIX cron syntax).
3. The ferrochain-server scheduler subsystem is running (not shut down).
4. `RunnableConfig` supplied in the schedule creation request is valid per `Assistant`
   configuration (no unknown fields, no contradicting overrides).

## Postconditions

1. A `CronSchedule` record is persisted with a unique `cron_id: Uuid`; `enabled: true`
   by default.
2. On each schedule firing the server atomically:
   a. Creates a new `Run` with a freshly allocated `run_id` and `thread_id` (no
      checkpoint history — isolated fresh session).
   b. Sets `Run.status = RunStatus::Queued`; the Run progresses through the standard
      `queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted (resume via POST .../resume)` lifecycle.
3. The `cron_id` is returned in the creation response; subsequent `GET /schedules/{cron_id}`
   reflects current `enabled` state and `last_fired_at` timestamp.
4. Setting `enabled: false` via `PATCH /schedules/{cron_id}` prevents all future firings
   immediately (any in-flight Run from the last firing continues to completion).
5. `DELETE /schedules/{cron_id}` removes the schedule; no further Runs are created; the
   operation returns `204 No Content`.
6. If the referenced `Assistant` no longer exists at firing time, the scheduled Run is
   created with `status = RunStatus::Failed` and error `E-CRON-001
   AssistantNotFoundAtFiring`.

## Invariants

- **Session isolation:** Each cron-fired Run receives a newly allocated `thread_id`;
  it does not inherit state from any previous cron Run on the same schedule unless
  `RunnableConfig.thread_id` is explicitly set by the operator.
- **Idempotent scheduling:** Creating two schedules with identical
  (`assistant_id`, `schedule`, `config`) is allowed; they are distinct records with
  distinct `cron_id` values — there is no deduplication.
- **No missed-fire accumulation:** If a schedule fires while the server was down, the
  server does **not** attempt to catch up with the missed firings. Exactly one Run
  is created for each elapsed scheduled time (miss-on-restart, fire-on-resume, or
  skip-on-restart — behavior is configurable per `RunnableConfig.missed_fire_policy`; the
  default is `skip`).

## Edge Cases

### EC-001: Assistant deleted after schedule creation; schedule fires
**Scenario:** A `CronSchedule` for `assistant_id = "a1"` fires after `"a1"` has been
deleted from the server.
**Expected behavior:** The scheduler creates a `Run` with `status = RunStatus::Failed`
and error `E-CRON-001 AssistantNotFoundAtFiring { cron_id, assistant_id }`. The
schedule itself is not automatically disabled; future firings will produce the same
result until the schedule is deleted or the assistant is recreated with the same ID.

### EC-002: Invalid cron expression at creation time
**Scenario:** `POST /schedules` with `schedule: "99 * * * *"` (invalid minute field).
**Expected behavior:** `400 Bad Request` with `E-CRON-002 InvalidCronExpression
{ field: "schedule", value: "99 * * * *", reason: "minute value 99 out of range 0-59" }`.
No `CronSchedule` record is created.

### EC-003: Schedule disabled while a Run is in progress
**Scenario:** A cron-fired Run is currently `in_progress`; operator sends
`PATCH /schedules/{cron_id}` with `{ "enabled": false }`.
**Expected behavior:** The in-flight Run continues to completion unaffected. No new Runs
are created for future firings. `GET /schedules/{cron_id}` returns `enabled: false`.

### EC-004: Schedule fires faster than runs complete (back-pressure)
**Scenario:** A schedule is configured for `"* * * * * *"` (every second); each Run
takes 10 seconds. Ten concurrent Runs have been enqueued.
**Expected behavior:** New Runs are created and queued; the server's run concurrency
limit determines how many execute simultaneously. Queued Runs are not cancelled; they
execute in order. If the queue depth exceeds a configurable `max_queue_depth` threshold,
new firings are skipped with `WARN` log and `E-CRON-003 ScheduleQueueFull { cron_id,
queue_depth }`.

### EC-005: `DELETE /schedules/{cron_id}` for non-existent schedule
**Scenario:** `DELETE /schedules/unknown-id` where `unknown-id` is not a valid cron_id.
**Expected behavior:** `404 Not Found` with `E-SERVER-006 ScheduleNotFound { cron_id:
"unknown-id" }`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `POST /schedules` with valid `assistant_id`, `schedule: "0 9 * * *"`, valid `config` | `201 Created`; response body includes `cron_id: <uuid>`, `enabled: true`; no Run created yet | Happy path — schedule creation |
| TV-002 | Advance mock clock to fire time; poll `/runs?schedule_id=<cron_id>` | One Run returned with `status: queued` or `in_progress`; `thread_id` is freshly allocated (not reused) | Firing creates isolated fresh session |
| TV-003 | Fire schedule twice (two ticks apart); list Runs for schedule | Two distinct Runs with distinct `run_id` and `thread_id` values | Each firing produces independent Run |
| TV-004 | `PATCH /schedules/{cron_id}` `{ "enabled": false }`; advance clock past next fire time | No new Run created | Disabling prevents future firings |
| TV-005 | Delete assistant; advance clock to fire time | Run created with `status: failed`, error `E-CRON-001 AssistantNotFoundAtFiring` | Missing-assistant error path |
| TV-006 | `POST /schedules` with `schedule: "99 * * * *"` | `400 Bad Request`, `E-CRON-002 InvalidCronExpression` | Validation error path |
| TV-007 | `DELETE /schedules/{cron_id}` for existing schedule | `204 No Content`; subsequent fire attempt produces no Run | Deletion halts future firings |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-CRON-01 | Each schedule firing allocates a fresh `thread_id` not shared with any prior Run | Integration test (assert `thread_id` uniqueness across two firings of the same schedule) | Phase 1 |
| VP-CRON-02 | Disabling a schedule prevents all subsequent firings | Integration test (disable; advance clock N periods; assert zero new Runs) | Phase 1 |

## Related BCs

- BC-2.12.003 — depends on: Run lifecycle (queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted) is the standard lifecycle each cron-fired Run follows
- BC-2.12.001 — depends on: thread creation semantics apply to cron-fired fresh sessions
- BC-2.05.001 — related to: domain-c requires isolated sessions per cron run (same isolation guarantee as HITL session isolation)

## Architecture Anchors

- `ferrochain-server/src/scheduler/` — cron scheduler subsystem
- `ferrochain-server/src/routes/schedules.rs` — `POST /schedules`, `GET /schedules/{id}`, `PATCH /schedules/{id}`, `DELETE /schedules/{id}` handlers
- `ferrochain-server/src/store/run_store.rs` — `RunStore` trait (durable Run records per BC-2.12.006)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-CRON-01, VP-CRON-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — this BC specifies the CronSchedule resource, its creation API, the proactive firing lifecycle, and the fresh-session-per-firing isolation guarantee, all of which are named components of the "Crons" surface in CAP-014 |
| L2 Domain Invariants | — (no DI directly applies; CAP-014 entity model defines CronSchedule semantics) |
| Domain C Forcing Function | domain-c-openclaw.md §2.8 — "Cron jobs run the agent proactively on a schedule — each run gets a fresh isolated session" |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration) |
| Module | [architect to assign — ferrochain-server] |
