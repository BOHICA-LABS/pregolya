---
document_type: adr
level: L3
adr_id: "028"
slug: server-run-lifecycle-semantics
title: "Server Run Lifecycle Semantics: multitask_strategy, delete_threads Cascade Atomicity, and Idempotency-Key TTL Basis"
status: accepted
date: "2026-08-25"
producer: architect
timestamp: 2026-08-25T00:00:00Z
version: "1.0"
phase: 2a
traces_to: ARCH-INDEX.md
decisions: []
supersedes: null
superseded_by: null
subsystems_affected: ["SS-12"]
changelog:
  - "1.0 (P2A-BC-scan/2026-08-25): Initial ADR — five server lifecycle decisions that were omitted from BC-2.12.003 (multitask_strategy), BC-2.12.002 (delete_threads cascade), and BC-2.12.006 (idempotency-key TTL), surfaced as behavioral-completeness gaps during Phase 2 BC adversarial scan."
---

# ADR-028: Server Run Lifecycle Semantics

**Status:** Accepted — Phase 2 BC completeness adjudication

---

## Context

Phase 2 adversarial BC scan identified five behavioral gaps in the SS-12 server lifecycle
contracts where postconditions, error codes, or ordering semantics were either absent or
internally contradictory. All five require cross-component architectural reasoning and
cannot be resolved at the BC layer alone. These decisions provide the implementation-ready
specifications that product-owner propagates into the affected BCs.

### Gap sources

- **BC-2.12.003 PC-004**: `multitask_strategy` options `interrupt`, `rollback`, and `enqueue`
  are listed by name but their lifecycle semantics (pre-empted run terminal state, new run
  start timing, rollback checkpoint target, queue bounds, error on overflow) are undefined.
- **BC-2.12.002 EC-003 vs BC-2.12.001 EC-006**: `DELETE /assistants/{id}?delete_threads=true`
  asserts HTTP 204 unconditionally, but BC-2.12.001 EC-006 returns HTTP 409 when a constituent
  thread has an active run. These are contradictory; the cascade atomicity rule is undefined.
- **BC-2.12.006 EC-001**: The idempotency-key TTL start anchor is explicitly left
  "implementation-defined" ("TTL-on-completion OR TTL-from-submission, implementation must
  document which"). A single canonical basis is required for consistent re-submission behavior.

---

## Decision 1 — `multitask_strategy = "interrupt"` Semantics

### Pre-empted run terminal state

The pre-empted (currently active) run transitions to **`cancelled`** — NOT to `interrupted`.

Rationale: `interrupted` is semantically reserved for HITL-pause (BC-2.05.002 §Description):
a user-driven pause awaiting resume input. Reusing `interrupted` for system-driven preemption
would conflate two semantically distinct states:
- `interrupted` (HITL): graph paused, executor holding state, resume expected — resumable
- preempted-by-sibling-run: graph forcibly stopped, no resume path available — NOT resumable

Using `cancelled` is clean, final, and gives a consistent terminal state regardless of
preemption mechanism.

### New run start timing

The new run enters `queued` state immediately (HTTP 202 is returned synchronously). The
executor dispatches it to `in_progress` **after** the pre-empted run's `cancelled` transition
is durably written to the RunStore. The executor MUST NOT start the new run concurrently with
the pre-empted run's shutdown — sequential handoff is required.

### Handling queued pre-empted run

If the pre-empted run is in `queued` state (not yet started), it transitions directly from
`queued → cancelled` without ever reaching `in_progress`.

### Error paths

- If cancellation signal delivery fails (RunStore write error): `Err(E-SERVER-014 RunStoreFailed)`;
  the new run is NOT queued until the pre-empted run's cancellation is durable.
- No new error code required for the `interrupt` strategy itself.

---

## Decision 2 — `multitask_strategy = "rollback"` Semantics

### Definition of "rollback"

Rollback means: reset the thread's checkpoint state to the **last checkpoint written before
the pre-empted run's first step**, then start the new run against that restored state.

Concretely: the rollback target is the checkpoint identified by the thread's
`latest_completed_checkpoint_id` at the moment `POST /threads/{thread_id}/runs` is
processed. This is the checkpoint from the previous completed/failed/cancelled run's last
successful `put_writes` call. If the thread has no prior checkpoint (e.g., this is the
first run on the thread), the rollback target is the empty thread state (no checkpoint rows
for this thread — effectively the same as a fresh thread).

### Execution sequence

1. Receive `POST .../runs { multitask_strategy: "rollback" }`.
2. Look up `latest_completed_checkpoint_id` for the thread (pre-preempt anchor).
3. Signal the pre-empted run to cancel.
4. Wait for pre-empted run to reach `cancelled` state (durable RunStore write).
5. Discard all checkpoint writes made by the pre-empted run:
   the CheckpointSaver MUST delete checkpoint rows with `checkpoint_id >
   latest_completed_checkpoint_id` for this thread. This is a single bounded delete
   using the logical-clock monotone property (ADR-005 §Decision).
6. Advance thread's `current_checkpoint` pointer back to `latest_completed_checkpoint_id`.
7. Start the new run against the rolled-back thread state.

### Pre-empted run terminal status

`cancelled` — same as `interrupt`. Rollback is a clean abort; the pre-empted run's
work is discarded, not preserved as a failure.

### Error paths

- Checkpoint discard failure (SQLite I/O error): `Err(E-CHKPT-001 CheckpointWriteFailed)`
  propagated; new run NOT started until rollback is complete. Partial rollback (some writes
  deleted, some remaining) is not permitted — the discard step is retried until success or
  the caller receives a 500.
- No new error code required for the `rollback` strategy itself.

---

## Decision 3 — `multitask_strategy = "enqueue"` Semantics

### Queue-depth bound

Maximum **`max_queued_runs`** enqueued runs behind the current active run. Default: **10**.
This is configurable per-server-instance at startup (pregolya-server config, not per-thread).
The bound applies to the count of Runs in `queued` state on a single thread (excluding the
currently `in_progress` run).

### Error on queue full

HTTP 429 with **E-SERVER-019 RunQueueFull** (NEW — PO must mint).

| Field | Value |
|-------|-------|
| Code | E-SERVER-019 |
| Namespace | SERVER (pregolya-server) |
| Category | POLICY |
| Severity | broken |
| Mnemonic | RunQueueFull |
| RetryHint | Later (divergence from POLICY default Never — when a queued run completes, a queue slot opens; `Later` correctly signals that retrying after the current run completes may succeed) |
| BC Anchor | BC-2.12.003 (multitask_strategy=enqueue queue bound) |
| Message Format | `RunQueueFull: thread '<thread_id>' already has <queue_depth> queued run(s); max_queued_runs=<max_queued_runs>` |
| Placeholders | 3: `<thread_id>` (available from path param), `<queue_depth>` (current queued count from RunStore), `<max_queued_runs>` (config value) |

The pattern mirrors E-CRON-003 ScheduleQueueFull (POLICY, Later divergence) — a transient
capacity constraint that may resolve on retry.

### Ordering

FIFO (first-come, first-served): Runs execute in `created_at` ascending order. When the
current `in_progress` run terminates (any terminal state), the executor selects the oldest
`queued` Run on the thread and transitions it to `in_progress`.

### Behavior if blocking run never terminates

A queued Run remains in `queued` state indefinitely if the blocking `in_progress` Run does
not terminate. No automatic queue-position timeout in v1 (this is an operational concern;
operators monitor via `GET /threads/{id}/runs?status=queued` and metric counters). Operators
must cancel the blocking run to unblock the queue.

Rationale for no automatic timeout: a blocking run may be legitimately long-running (e.g.,
an agent processing a large document). Silently cancelling the blocking run would be
data-destructive. Operators have explicit control via the cancel endpoint.

---

## Decision 4 — `delete_threads = true` Cascade Atomicity

### The conflict

BC-2.12.002 EC-003 (`DELETE /assistants/{id}?delete_threads=true`) asserts HTTP 204
unconditionally. BC-2.12.001 EC-006 (added v1.7) asserts HTTP 409 (E-SERVER-008
ThreadStateConflict) when a thread has an active run. If any of the assistant's associated
threads has an active run, these two postconditions are irreconcilable.

### Decision: Atomic-abort

If ANY constituent thread has an active (`queued` or `in_progress`) run, the ENTIRE cascade
ABORTS. No partial deletion occurs: neither the assistant record nor any thread record
is modified. HTTP 409 is returned.

**Error code:** reuse **E-SERVER-008 ThreadStateConflict** (already covers thread deletion
with active run per BC-2.12.001 EC-006; no new code required).

**Message form for cascade context:**

```
ThreadStateConflict: thread '<thread_id>' has an active run '<run_id>';
cascade delete aborted — assistant '<assistant_id>' and no thread records were modified
```

Placeholders: `<thread_id>` (first blocking thread found), `<run_id>` (its active run),
`<assistant_id>` (the assistant the caller attempted to delete).

### Caller contract

The caller MUST cancel all active runs on ALL constituent threads before
`DELETE /assistants/{id}?delete_threads=true` will succeed. Concretely:

1. `GET /assistants/{id}/runs` or inspect `GET /threads/{t}/runs?status=queued,in_progress`
   per thread to find blocking runs.
2. `POST /threads/{t}/runs/{r}/cancel` for each blocking run.
3. Wait for all blocking runs to reach terminal state.
4. Retry `DELETE /assistants/{id}?delete_threads=true`.

### Atomicity scope

The cascade delete is internally atomic: either ALL constituent threads are deleted (and
the assistant record is deleted), or NOTHING is deleted. The implementation MUST perform
the deletion within a single database transaction (or equivalent atomic operation for the
RunStore + CheckpointSaver backends in use).

Rationale: partial deletion (some threads deleted, assistant partially cleaned up) creates
an inconsistent state from which recovery requires manual inspection. Atomic-abort is the
production-grade default — no orphaned or inconsistent resources.

---

## Decision 5 — Idempotency-Key TTL Basis

### Decision: TTL-from-submission

The 24-hour idempotency TTL clock starts **at submission time** — when the first request
carrying `Idempotency-Key: <key>` arrives and the key is registered in the
`IdempotencyStore`. It does NOT start at Run completion time.

### Externally-observable consequence

| Re-submission timing | Behavior |
|----------------------|----------|
| During the 24h window | Returns the cached response (same `run_id`, same output). No new Run is created. The cached response may be returned even while the original Run is still `in_progress` (if the Run takes a long time). |
| After the 24h window | The key has expired; the request is treated as new. A new Run is created with a new `run_id`. |

### Rationale

1. **Caller predictability:** the caller knows when they submitted the request; they can
   compute the cache expiry window without knowing when the server completed the Run.
2. **Non-pathological long Runs:** TTL-on-completion would mean a 23-hour Run expires almost
   immediately after completion, giving callers a near-zero safe retry window.
3. **Simplicity:** the IdempotencyStore only needs one timestamp per key (registration time);
   TTL-on-completion would require a second timestamp (completion time) plus a state
   machine on the key itself.
4. **Platform alignment:** LangGraph Platform uses submission-anchored idempotency windows.

### Operator responsibility for long-running Runs

If a Run takes longer than the TTL (e.g., operator sets TTL = 5 minutes; Run takes 30
minutes), the key expires during execution. A re-submission at minute 6 starts a NEW Run
concurrently with the still-running original Run. This is an operator misconfiguration —
the TTL MUST be set to exceed the expected maximum Run duration. This constraint MUST be
documented in the `IdempotencyStore` configuration reference and in the server operations
guide. Pregolya does NOT guard against this at the framework layer in v1.

### Interaction with lock_timeout (EC-002)

The per-key lock (default 30 seconds, E-SERVER-016 IdempotencyLockTimeout on expiry)
handles concurrent race within the TTL window. After the first request registers the key,
subsequent requests within the 30s lock window wait for the cached response; after 30s,
they receive E-SERVER-016. This is orthogonal to the 24h TTL basis — the lock handles
in-flight deduplication; the TTL handles historical deduplication.

---

## Rationale

All five decisions follow the same principle: choose the behavior that produces the least
surprising externally-observable outcome under a production-grade default, consistent with
LangGraph parity where applicable.

**Decisions 1 and 2** (`interrupt` and `rollback`): using `cancelled` as the pre-empted
run's terminal state avoids conflating HITL-pause (`interrupted`) with system-driven
preemption. The existing `interrupted` state carries an implied resume contract
(BC-2.05.002); callers checking `run.status == "interrupted"` expect to resume it.
A sibling-preempted run has no resume path; `cancelled` is the correct terminal state.

**Decision 3** (`enqueue`): the FIFO ordering with a configurable bounded queue mirrors
the cron scheduling back-pressure pattern (E-CRON-003), applying consistent resource
management across all background-scheduling paths. The RetryHint: Later divergence is
justified: queue slots become available as Runs complete, making retry meaningful.

**Decision 4** (cascade atomicity): atomic-abort is the production-grade default for
compound mutations. Any partial-success scenario — assistant deleted but some threads
retained — would require callers to implement their own cleanup logic to discover which
threads were deleted. Atomic-abort is deterministic, auditable, and follows the GDPR-style
erasure principle in BC-2.15.002 (all-or-nothing semantics for resource cleanup).

**Decision 5** (TTL-from-submission): submission-anchored TTL is predictable from the
caller's perspective. Completion-anchored TTL would mean long-running Runs have a near-zero
retry window after completion — exactly the scenario where callers are most likely to retry
(they submitted a request, waited, and are now confirming the result). Submission-anchored
TTL maximizes the practical utility of the idempotency cache.

## Alternatives Considered

| Alternative | Disposition |
|-------------|-------------|
| Decision 1: pre-empted run → `interrupted` for sibling-run preemption | REJECT — `interrupted` is the HITL-pause state; conflating it with forced cancellation destroys the semantic model. The HITL resume path (`POST .../resume`) must NOT be callable on a sibling-preempted run. |
| Decision 2: rollback to "any earlier checkpoint" (caller-supplied target) | REJECT — arbitrary checkpoint targeting requires checkpoint ID enumeration and validation logic; adds API surface. Rolling back to the pre-preempt boundary is the only semantically meaningful target. |
| Decision 3: no queue-depth bound (unlimited) | REJECT — unbounded queues are a resource-exhaustion vector; a single misconfigured client can fill thread queues. The default cap + configurable limit follows the cron back-pressure pattern (E-CRON-003). |
| Decision 4: partial cascade (delete threads that have no active runs; skip those that do) | REJECT — partial deletion produces inconsistent assistant state (some threads deleted, some retained); the caller cannot determine which threads were deleted without a separate audit. Atomic-abort is deterministic. |
| Decision 5: TTL-on-completion | REJECT — long-running Runs would expire almost immediately after completion; non-trivially complicates IdempotencyStore (second timestamp, state machine on key); non-predictable window from caller's perspective. |

---

## Consequences

### New error code (Decision 3): E-SERVER-019

PO must mint E-SERVER-019 RunQueueFull in error-taxonomy.md:

| Field | Value |
|-------|-------|
| Code | E-SERVER-019 |
| Namespace | SERVER (pregolya-server) |
| Category | POLICY |
| Severity | broken |
| Mnemonic | RunQueueFull |
| BC Anchor | BC-2.12.003 {PC-004} (multitask_strategy=enqueue) |
| RetryHint | Later — divergence from POLICY default Never; rationale: a queued run completing opens a slot; the same request may succeed after a wait interval (analogous to E-CRON-003 ScheduleQueueFull). Add to RetryHint divergence blockquote. |
| Message Format | `RunQueueFull: thread '<thread_id>' already has <queue_depth> queued run(s); max_queued_runs=<max_queued_runs>` |
| HTTP Status | 429 Too Many Requests |

SERVER namespace: 18→19 live codes after mint.

### BC amendments (PO scope)

| BC | Required amendment |
|----|-------------------|
| BC-2.12.003 PC-004 | For each of `interrupt`, `rollback`, `enqueue`: specify pre-empted run terminal state, new run start condition, error path, and bounds per Decisions 1–3 above. Add TV for each strategy. Add EC citing E-SERVER-019 for enqueue-queue-full. |
| BC-2.12.002 EC-003 | Replace "HTTP 204. All 3 threads deleted" with atomic-abort semantics per Decision 4. Add TV for the active-run-blocks-cascade scenario. |
| BC-2.12.006 EC-001 | Replace "TTL-on-completion OR TTL-from-submission, implementation must document which" with "TTL-from-submission" (Decision 5). Add the operator-responsibility note for long-running Runs. |

### Run state machine (BC-2.12.003 PC-007)

Decisions 1 and 2 do NOT add new arcs to the run state machine. Both `interrupt` and
`rollback` use the existing `in_progress → cancelled` arc (or `queued → cancelled`).
`enqueue` uses no new arc — enqueued runs follow the normal `queued → in_progress`
transition when the queue unblocks.

### No changes to VPs or module-criticality

These decisions are behavioral lifecycle semantics, not formal proofs. No VP additions
required. No module-criticality changes — pregolya-server remains HIGH (90%) per
module-criticality.md.

---

## BC Anchors

| BC | Relevance |
|----|-----------|
| BC-2.12.003 | Run Creation and Execution Lifecycle — multitask_strategy primary authority |
| BC-2.12.001 | Thread CRUD — thread delete with active run (EC-006) feeds Decision 4 |
| BC-2.12.002 | Assistant CRUD — delete_threads cascade primary authority (EC-003) |
| BC-2.12.006 | IdempotencyStore / RunStore trait seams — idempotency TTL primary authority (EC-001) |

---

## Source / Origin

- Phase 2 behavioral-completeness adversarial scan of SS-12 contracts.
- D13 (server config surface — original mandate for BC-2.12.*).
- BC-2.12.001 (EC-006 addition): thread-delete-with-active-run → 409; the conflict
  with BC-2.12.002 EC-003 cascade was introduced when EC-006 was added without backfilling
  cascade semantics into BC-2.12.002.
- BC-2.12.006: idempotency TTL left deliberately open as "implementation must document
  which" — this ADR closes that openness.
