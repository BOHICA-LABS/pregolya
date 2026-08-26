---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.004
version: "1.11"
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
timestamp: 2026-08-24T01:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/platform/behavioral-intent.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "1c078bf"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
changelog:
  - "1.1 (ADV-P1D-PASS-31): F-P31-01 add PC7 for GET /runs?schedule_id aggregate query endpoint — limit default 10, max 100 (clamped), offset default 0, created_at DESC ordering declared as canon; update TV-002 notes to cite F-P31-01 pagination."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-server per module-decomposition.md v1.10."
  - "1.3 (F-P118-02, fix burst 121, 2026-07-19): Propagate four-member terminal set from BC-2.12.003 v1.4 (F-P117-01 adjudication). PC2b: lifecycle arrow `completed | failed | cancelled` → `completed | failed | cancelled | summary_halt`. Related BCs §BC-2.12.003 description: same three-member form → four-member form. TD-VSDD-060 file-wide sweep: only these two sites enumerated the terminal set; all other status references are specific-value or query-result forms (exempt)."
  - "1.4 (burst-258/F-P157-01/2026-07-24): Assign canonical event_type 'server.cron_schedule_queue_full' to EC-004 queue-full WARN emission per observability census (SAP-1). EC-004 updated with structured event_type and fields."
  - "1.5 (burst-259/F-P158-02/2026-07-24): EC-004 queue-full boundary predicate corrected from 'exceeds' (>) to 'meets or exceeds' (>=). ScheduleQueueFull fires when queue_depth >= max_queue_depth (at capacity); 'exceeds' incorrectly implied strictly-greater-than. Consistent with observability.md Recurrence column and error-taxonomy.md E-CRON-003 (updated same burst-259)."
  - "1.6 (burst-264/2026-07-25): Architecture Anchors filesystem path corrected src/scheduler/ → src/cron/ per module-decomposition v1.26 adjudication (canonical module server::cron)."
  - "1.7 (fix-burst-283/TD-VSDD-060-sibling/2026-07-30): Architect sibling-site sweep: 'No missed-fire accumulation' invariant referenced RunnableConfig.missed_fire_policy, which does not exist (not added by ADR-021; absent from LangGraph Cron TypedDict and ADK-Rust CreateCronJobRequest in reference corpus). Option A applied: fixed skip policy for missed firings; no per-schedule missed-fire override available in v1. Removed internally-contradictory 'Exactly one Run is created for each elapsed scheduled time' clause."
  - "1.8 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.27 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.9 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.10 (P2A-044 F-06/2026-08-24): compressed-ordinal citations normalized to stable tags."
  - "1.11 (P2A-BC-scan-B/2026-08-26): EC-006 added — invalid RunnableConfig at schedule creation → E-CRON-004 InvalidRunnableConfig (VAL/400/Never). PRE-004 violation failure path now specified; closes gap where the precondition was declared but no failure postcondition existed. Note: error-taxonomy.md minted E-CRON-004 with anchor BC-2.12.004 EC-005; EC-005 is occupied by ScheduleNotFound; authoritative raise site is EC-006 per ADR-027 append-only numbering — taxonomy anchor update deferred to error-taxonomy owners."
---

# BC-2.12.004: CronSchedule Creation and Proactive Run Execution

## Description

`pregolya-server` exposes a `CronSchedule` resource that registers a recurring,
proactive run trigger on a named Assistant. On each schedule firing, the server
creates a new Run with a **fresh, isolated session** — no prior thread context is
shared across firings unless the operator explicitly wires a persistent thread via
`RunnableConfig`. This contract specifies the full lifecycle: create, enable, fire, disable,
and delete, plus the isolation guarantee that distinguishes proactive runs from
interactive runs.

## Preconditions

1. {PRE-001} A valid `Assistant` record exists for the `assistant_id` referenced in the schedule
   creation request.
2. {PRE-002} The `schedule` field is a syntactically valid cron expression (five or six fields,
   standard quartz-compatible or POSIX cron syntax).
3. {PRE-003} The pregolya-server scheduler subsystem is running (not shut down).
4. {PRE-004} `RunnableConfig` supplied in the schedule creation request is valid per `Assistant`
   configuration (no unknown fields, no contradicting overrides).

## Postconditions

1. {PC-001} A `CronSchedule` record is persisted with a unique `cron_id: Uuid`; `enabled: true`
   by default.
2. {PC-002} On each schedule firing the server atomically:
   a. Creates a new `Run` with a freshly allocated `run_id` and `thread_id` (no
      checkpoint history — isolated fresh session).
   b. Sets `Run.status = RunStatus::Queued`; the Run progresses through the standard
      `queued → in_progress → completed | failed | cancelled | summary_halt; in_progress ⇄ interrupted (resume via POST .../resume)` lifecycle.
3. {PC-003} The `cron_id` is returned in the creation response; subsequent `GET /schedules/{cron_id}`
   reflects current `enabled` state and `last_fired_at` timestamp.
4. {PC-004} Setting `enabled: false` via `PATCH /schedules/{cron_id}` prevents all future firings
   immediately (any in-flight Run from the last firing continues to completion).
5. {PC-005} `DELETE /schedules/{cron_id}` removes the schedule; no further Runs are created; the
   operation returns `204 No Content`.
6. {PC-006} If the referenced `Assistant` no longer exists at firing time, the scheduled Run is
   created with `status = RunStatus::Failed` and error `E-CRON-001
   AssistantNotFoundAtFiring`.

### Cross-Thread Aggregate Query (`GET /runs?schedule_id={cron_id}`)

7. {PC-007} `GET /runs?schedule_id={cron_id}` returns `{ runs: [Run], total_count: u64 }` listing
   all Runs fired by the given schedule across all threads. Results are ordered
   `created_at` **descending** (most-recent firing first). This ordering is the
   authoritative canon for this endpoint (F-P31-01, ADV-P1D-PASS-31).
   Pagination: `limit` (default 10, max 100; values > 100 silently clamped to 100) and
   `offset` (default 0) query params apply. This is the only flat `/runs` endpoint;
   all other Run CRUD paths are thread-scoped (see interface-definitions.md §Cron Schedules
   for the cross-thread aggregate rationale and BC-2.12.003 for thread-scoped list).

## Invariants

- {INV-001} **Session isolation:** Each cron-fired Run receives a newly allocated `thread_id`;
  it does not inherit state from any previous cron Run on the same schedule unless
  `RunnableConfig.thread_id` is explicitly set by the operator.
- {INV-002} **Idempotent scheduling:** Creating two schedules with identical
  (`assistant_id`, `schedule`, `config`) is allowed; they are distinct records with
  distinct `cron_id` values — there is no deduplication.
- {INV-003} **No missed-fire accumulation:** If a schedule fires while the server was down, the
  server does **not** attempt to catch up with the missed firings. The server applies a
  fixed `skip` policy for missed firings; no per-schedule missed-fire override is
  available in v1.

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
execute in order. If the queue depth meets or exceeds `max_queue_depth`,
new firings are skipped with a `tracing::warn!(event_type = "server.cron_schedule_queue_full", cron_id, queue_depth)` and `E-CRON-003 ScheduleQueueFull { cron_id,
queue_depth }` error.

### EC-005: `DELETE /schedules/{cron_id}` for non-existent schedule
**Scenario:** `DELETE /schedules/unknown-id` where `unknown-id` is not a valid cron_id.
**Expected behavior:** `404 Not Found` with `E-SERVER-006 ScheduleNotFound { cron_id:
"unknown-id" }`.

### EC-006: Invalid RunnableConfig at schedule creation (PRE-004 violation) {EC-006}
**Scenario:** `POST /schedules { assistant_id: "a1", schedule: "0 9 * * *", config: { unknown_field: "x" } }` where `config` contains a field not accepted by the Assistant's `RunnableConfig` schema, or contains a value that violates a constraint (e.g., `recursion_limit: -1`).
**Expected behavior:** HTTP 400 `{ code: "E-CRON-004", message: "Validation failed for '<field>': <reason>" }`. No `CronSchedule` record is created. The validation is performed at request time before any persistence; PRE-004 is pre-validated as part of the POST /schedules handler. This closes the PRE-004 failure path gap: the precondition was declared but the postcondition for its violation was unspecified.
**Note:** E-CRON-004 InvalidRunnableConfig (VAL, broken, Never, HTTP 400); two placeholders: `<field>` (failing field name) and `<reason>` (constraint violation description). Error-taxonomy.md minted E-CRON-004 with anchor label EC-005; per ADR-027 append-only numbering EC-005 is occupied by ScheduleNotFound; this BC's authoritative raise site is EC-006.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `POST /schedules` with valid `assistant_id`, `schedule: "0 9 * * *"`, valid `config` | `201 Created`; response body includes `cron_id: <uuid>`, `enabled: true`; no Run created yet | Happy path — schedule creation |
| TV-002 | Advance mock clock to fire time; poll `GET /runs?schedule_id=<cron_id>` (canonical defaults: `limit=10&offset=0`) | One Run returned with `status: queued` or `in_progress`; `thread_id` is freshly allocated (not reused); `total_count: 1`; result ordered `created_at` DESC | Firing creates isolated fresh session. Pagination: F-P31-01 canonical convention applies — default `limit=10`, `offset=0`, `created_at` DESC. See {PC-007} and interface-definitions.md §Cron Schedules |
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

- BC-2.12.003 — depends on: Run lifecycle (queued → in_progress → completed | failed | cancelled | summary_halt; in_progress ⇄ interrupted) is the standard lifecycle each cron-fired Run follows
- BC-2.12.001 — depends on: thread creation semantics apply to cron-fired fresh sessions
- BC-2.05.001 — related to: domain-c requires isolated sessions per cron run (same isolation guarantee as HITL session isolation)

## Architecture Anchors

- `pregolya-server/src/cron/` — cron scheduler subsystem
- `pregolya-server/src/routes/schedules.rs` — `POST /schedules`, `GET /schedules/{id}`, `PATCH /schedules/{id}`, `DELETE /schedules/{id}` handlers
- `pregolya-server/src/store/run_store.rs` — `RunStore` trait (durable Run records per BC-2.12.006)

## Story Anchor

S-1.27

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
| Module | pregolya-server |
