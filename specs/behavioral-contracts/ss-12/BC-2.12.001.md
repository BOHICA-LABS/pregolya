---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.001
version: "1.8"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-12
capability: CAP-014
wave: 1
phase: 1a
red_gate: false
producer: product-owner
timestamp: 2026-08-24T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/platform/behavioral-intent.md
input-hash: "68ed851"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
changelog:
  - "1.1 (ADV-P1D-PASS-31): F-P31-01 PC17 history endpoint — declare limit default 10, max 100, values > 100 clamped to 100, offset default 0 (pagination coherence canon; clamp out-of-range semantics)."
  - "1.2 (ADV-P1D-PASS-34): F-P34-01 PC8 — add clamp semantics (values > 100 silently clamped to 100) and offset default 0 (partial-fix propagation gap from pass-31). PC9 — declare created_at DESC ordering (canonical; F-P31-01). interface-definitions.md §Canonical Pagination Convention cites BC-2.12.001 PC8 as threads-list clamp+ordering anchor; PC8 now matches."
  - "1.3 (2026-07-15, F-P78-SWEEP/D18-P78-A): E-SERVER-007 message-prefix correction at two BC sites. (1) PC3 (Create Thread): added 'ThreadAlreadyExists:' prefix and lowercased 'Thread' to 'thread' in message string (was 'Thread'; now 'thread'). (2) EC-001: same corrections applied. Taxonomy already carried the prefix and lowercase; BC was the lagging artifact. Both sites now produce the canonical form 'ThreadAlreadyExists: thread <id> already exists'."
  - "1.4 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-server per module-decomposition.md v1.10."
  - "1.5 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.26 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.6 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.7 (M3b-escalation-EC006/2026-08-24): EC-006 added — DELETE /threads/{id} while an active (queued or in_progress) run exists returns HTTP 409 E-SERVER-008; PC-011 is unconditional and did not cover this restriction; gap surfaced during S-1.26 EC adjudication P2A-043 F-05."
  - "1.8 (P2A-052 F-052-01/2026-08-25): ## VP Anchors section corrected from duplicated Story-Anchor story-ID to 'None' (BC has no Kani VP seed; see §Verification Properties)."
---

# BC-2.12.001: Thread Resource CRUD (Create, Read, List, Delete Durable Conversation History)

## Description

A Thread is pregolya-server's durable conversation history container: it is the
persistent identity that binds a sequence of Runs to a shared checkpoint lineage.
This BC specifies the CRUD operations on Thread resources (no wire-compatibility with
LangGraph Platform per D13 — the pregolya-server API is first-party). Threads are
the lowest-level persistence unit; their checkpoint state is managed by the
pregolya-checkpoint subsystem. Thread-not-found returns `E-SERVER-003`.

## Preconditions

1. {PRE-001} `pregolya-server` is running with a configured `RunStore` and `CheckpointSaver` backend.
2. {PRE-002} The caller holds a valid authentication credential (or the server is in unauthenticated
   dev mode).

## Postconditions

### Create Thread (`POST /threads`)

1. {PC-001} Accepts body `{ thread_id?: Uuid, metadata?: Map<String, Value> }`.
2. {PC-002} `thread_id` is caller-supplied or server-generated (UUID v4 if absent).
3. {PC-003} If `thread_id` already exists and `if_exists = "raise"` (default): returns HTTP 409
   with `{ code: "E-SERVER-007", message: "ThreadAlreadyExists: thread '<id>' already exists" }`.
4. {PC-004} If `thread_id` already exists and `if_exists = "do_nothing"`: returns the existing
   Thread record (HTTP 200), no modification.
5. {PC-005} Returns HTTP 201 with the created `Thread { thread_id, metadata, created_at, updated_at, status }`.

### Read Thread (`GET /threads/{thread_id}`)

6. {PC-006} Returns HTTP 200 with the Thread record if found.
7. {PC-007} Returns HTTP 404 with `{ code: "E-SERVER-003", message: "ThreadNotFound: thread '<id>' does not exist" }` if not found.

### List/Search Threads (`GET /threads`)

8. {PC-008} Accepts query params `metadata` (filter), `limit` (default 10, max 100; values > 100 silently clamped to 100), `offset` (default 0).
9. {PC-009} Returns `{ threads: [Thread], total_count: u64 }`; results ordered `created_at` descending (canonical; F-P31-01, ADV-P1D-PASS-34).
10. {PC-010} Metadata filter uses exact-match on top-level keys; partial matches are not supported.

### Delete Thread (`DELETE /threads/{thread_id}`)

11. {PC-011} Deletes the Thread record and all associated checkpoint state for that thread.
12. {PC-012} Returns HTTP 204 on success.
13. {PC-013} Returns HTTP 404 with `E-SERVER-003` if the thread does not exist.
14. {PC-014} A delete is idempotent at the HTTP layer: a second DELETE on the same ID returns 404, not 500.

### Thread State Operations

15. {PC-015} `GET /threads/{thread_id}/state` — returns the latest checkpoint state for the thread:
    `{ values: GraphState, checkpoint: CheckpointId, next: [NodeId] }`.
16. {PC-016} `POST /threads/{thread_id}/state` — updates checkpoint state by applying a delta:
    `{ values: Map<String, Value>, as_node?: NodeId }`. Returns `{ checkpoint: CheckpointId }`.
17. {PC-017} `GET /threads/{thread_id}/history?limit=N` — returns the checkpoint history list
    for the thread, ordered newest-first; `limit` default 10, max 100; values > 100
    clamped to 100; `offset` default 0 (F-P31-01, ADV-P1D-PASS-31).

## Invariants

- {INV-001} Thread IDs are globally unique within the server instance.
- {INV-002} Deleting a thread MUST cascade-delete all checkpoint data for that thread (no orphan
  checkpoint rows).
- {INV-003} Thread state operations (`/state`) are mediated by the checkpoint subsystem; they do
  not bypass `put_writes` / `get_tuple` (DI-002).
- {INV-004} All thread CRUD operations are atomic: a create either fully succeeds or fully fails;
  no partially created thread is observable.

## Edge Cases

### EC-001: Caller-supplied thread_id conflicts with existing (if_exists=raise)
**Scenario:** `POST /threads` with `{ thread_id: "abc", if_exists: "raise" }`;
thread "abc" already exists.
**Expected behavior:** HTTP 409 `{ code: "E-SERVER-007", message: "ThreadAlreadyExists: thread 'abc' already exists" }`.
No data modified.

### EC-002: Metadata filter with no matches
**Scenario:** `GET /threads?metadata={"env":"prod"}` where no threads have that metadata key.
**Expected behavior:** HTTP 200 `{ threads: [], total_count: 0 }`. Not an error.

### EC-003: Delete non-existent thread
**Scenario:** `DELETE /threads/does-not-exist`.
**Expected behavior:** HTTP 404 `{ code: "E-SERVER-003", ... }`. Not 204. Second call to
the same ID also returns 404 — idempotent in error semantics.

### EC-004: GET /state for thread with no runs
**Scenario:** Thread created but no Run has been executed against it.
**Expected behavior:** HTTP 200 with `{ values: {}, checkpoint: null, next: [] }`.
The thread exists but has no checkpoint state. This is valid.

### EC-005: POST /state concurrent with running Run
**Scenario:** A Run is active on the thread (state: `in_progress`); caller simultaneously
calls `POST /threads/{thread_id}/state`.
**Expected behavior:** HTTP 409 `{ code: "E-SERVER-008", message: "ThreadStateConflict: thread '<id>' has an active run '<run_id>'; state updates during active runs are disallowed" }`.

### EC-006: DELETE thread with active (queued or in_progress) Run
**Scenario:** `DELETE /threads/{thread_id}` where the thread has a Run currently in `queued` or `in_progress` state.
**Expected behavior:** HTTP 409 `{ code: "E-SERVER-008", message: "ThreadStateConflict: thread '<id>' has an active run '<run_id>'; thread deletion while an active run is in progress is disallowed" }`.
The thread and its runs are NOT deleted. Caller must first cancel the active run
(`POST /threads/{thread_id}/runs/{run_id}/cancel`), await a terminal state, then retry the thread deletion.
**Rationale:** PC-011 is unconditional; this EC makes the active-run guard explicit. Re-uses the E-SERVER-008
ThreadStateConflict code established by EC-005 (state writes during active run), extending the guard to deletion.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `POST /threads` with no body | HTTP 201, server-generated UUID `thread_id`, `metadata: {}` | Happy-path create |
| TV-002 | `POST /threads { thread_id: "t1" }` × 2 with default `if_exists` | First: 201; Second: 409 E-SERVER-007 | Conflict detection |
| TV-003 | `GET /threads/t1` after creation | HTTP 200, Thread record | Happy-path read |
| TV-004 | `GET /threads/nonexistent` | HTTP 404 E-SERVER-003 | Thread not found |
| TV-005 | `DELETE /threads/t1`, then `DELETE /threads/t1` | First: 204; Second: 404 E-SERVER-003 | Idempotent delete |
| TV-006 | `GET /threads?metadata={"env":"prod"}&limit=5` | Filtered list, max 5 results | List with filter |
| TV-007 | `GET /threads/t1/state` (no runs) | HTTP 200 `{ values: {}, checkpoint: null, next: [] }` | Empty state |

## Verification Properties

_No Kani VP seed required. Integration tests against in-process pregolya-server are sufficient._

## Related BCs

- BC-2.12.002 — sibling: Assistants reference graph configs; threads reference no assistant directly (they are untyped containers)
- BC-2.12.003 — depends on: Runs are executed against Threads; Run lifecycle ties to thread state

## Architecture Anchors

- `pregolya-server/src/api/threads.rs` — Thread CRUD handlers
- `pregolya-server/src/store/run_store.rs` — Thread persistence (durable backend seam)
- `pregolya-checkpoint/src/store.rs` — Checkpoint cascade-delete on thread delete

## Story Anchor

S-1.26

## VP Anchors

None

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — this BC implements the Thread resource CRUD, which is explicitly listed as the first of the four managed resources in CAP-014: "Thread (durable conversation history)" |
| L2 Domain Invariants | — |
| DEC Reference | — |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration), E2E (end-to-end) |
| Module | pregolya-server |
