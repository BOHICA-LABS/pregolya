---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.005
version: "1.7"
status: active
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "c73e8fd"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-04
capability: CAP-005
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-1): Invariant 3 rewritten — SCHEDULED channel routing vs. skip-on-reapply distinction clarified; `ERROR_SOURCE_NODE` no-negative-index note added; `SCHEDULED` NOT-skipped note added (F-P1-HIGH, semport/graph/behavioral-intent.md validation)."
  - "1.2 (ADV-P1D-PASS-66): F-P66-02 — EC-006 and TV added: checkpoint read failure during crash recovery (`get_tuple()` returns `Err(E-CHKPT-003 CheckpointReadFailed)`) → recovery halts, error propagated to caller. Confirms E-CHKPT-003 anchor to this BC. (OBS-P28-2 class; gate #33 reverse-verification finding.)"
  - "1.3 (2026-07-19, F-P114-01 fix burst 117): Anchor correction — Architecture Anchors updated from nonexistent 'architecture/pregolya-checkpoint.md' to 'architecture/module-decomposition.md §pregolya-checkpoint' (checkpoint::saver row) per architect adjudication (burst 117). No BC body content changed."
  - "1.4 (notation-sweep-wave-b-ss04/2026-07-29): Class 3 error-construction notation sweep (Wave B batch B4). EC-006 Expected Behavior cell: added `..` rest-pattern marker (4 of 5 fields present, missing retry_hint). Test-vector row: replaced forbidden `...` (three-dot ASCII) with `..` (CLASS3_ASCII_ELLIPSIS_VIOLATION; ADR-010 §Error-Construction Notation Canon, Class 3)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (P2-BC-SS04-06-hardening/2026-08-26): EC-007 added — pending_writes reapply read/deserialize failure. EC-006 covered `get_tuple()` failure during checkpoint load but did not specify the failure surface for the subsequent `_reapply_writes_to_succeeded_nodes` storage query and entry deserialization step. EC-007 specifies both sub-cases (storage I/O error and deserialization failure) with E-CHKPT-003 REUSE (DURABILITY, broken — 'cannot restore state' semantic covers both sub-cases; `<reason>` field discriminates between I/O error and deserialization failure). TV row added for EC-007. BC-completeness-scan Phase-2 BURST-B gap BC-2.04.005."
  - "1.7 (F-P2A123-01/2026-08-28): §Story Anchor backfilled to S-1.10; §Architecture Module confirmed as pregolya-checkpoint — from STORY-INDEX forward map (SS-04 coverage map) and self §Architecture Anchors (module-decomposition.md §pregolya-checkpoint). No behavioral change."
modified: []
extracted_from: null
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P0
wave: 1
d17_commitment: Q3
dec_anchor: DEC-009
---

# BC-2.04.005: Crash Recovery — Completed Tasks Not Re-Executed After Process Restart

## Description

When a process crashes mid-super-step and is subsequently restarted, any PregelTask whose
writes were persisted via `put_writes` before the crash is not re-executed. Only tasks with
no committed writes re-run. This implements the at-most-once-committed / at-least-once-uncommitted
crash-recovery contract. Control-signal writes (`ERROR`, `ERROR_SOURCE_NODE`, `INTERRUPT`,
`RESUME`) are explicitly excluded from re-application so that the node re-executes and handles
them freshly rather than replaying stale control state.

## Preconditions

1. {PRE-001} A graph run is in progress with `sync` or `async` durability and a durable `CheckpointSaver`
2. {PRE-002} During super-step N, K of M total tasks have completed and their writes are persisted via
   `put_writes` (K ≥ 0)
3. {PRE-003} The process crashes before `apply_writes` completes the super-step N+1 checkpoint
4. {PRE-004} The same graph is restarted and `invoke`/`stream` is called with the same `thread_id`

## Postconditions

1. {PC-001} The graph loads the most recent committed checkpoint (super-step N-1 or earlier)
2. {PC-002} `_reapply_writes_to_succeeded_nodes` restores the K committed tasks' write sets from
   `pending_writes` storage, WITHOUT re-executing those nodes' bodies
3. {PC-003} The remaining M-K uncommitted tasks re-execute from their node entry points
4. {PC-004} The skipped control signals (`ERROR`, `ERROR_SOURCE_NODE`, `INTERRUPT`, `RESUME`) are
   NOT re-applied from pending_writes; their nodes re-execute and encounter them freshly
5. {PC-005} The run completes with a final state identical to what would have been produced without
   the crash (given idempotent node side-effects)
6. {PC-006} Total node executions = M-K (only uncommitted) + later super-steps; no task executes twice

## Invariants

1. {INV-001} A task is "committed" if and only if its `task_id` appears in `pending_writes` for the
   current `checkpoint_id` with non-empty writes (or explicit empty-write record)
2. {INV-002} Task IDs are deterministic content-addressed hashes — the same graph state and step produce
   the same task_id on restart, enabling correct pending-write matching
3. {INV-003} **Control-signal write routing vs. re-apply skip set (two distinct concepts):**
   - *Write-routing index map* (`WRITES_IDX_MAP`): four channels use negative indices for
     internal routing: `ERROR=-1`, `SCHEDULED=-2`, `INTERRUPT=-3`, `RESUME=-4`. `SCHEDULED`
     carries the -2 index and is routed normally — it is NOT excluded from re-apply.
   - *Skip-on-reapply set*: four signals are filtered out during
     `_reapply_writes_to_succeeded_nodes` so that failed/interrupted nodes re-execute
     and encounter them freshly: `ERROR`, `ERROR_SOURCE_NODE`, `INTERRUPT`, `RESUME`.
     Note: `ERROR_SOURCE_NODE` does not have a dedicated negative index but IS skipped.
     Note: `SCHEDULED` has index -2 but is NOT skipped (its write is re-applied normally).
   - Source: semport/graph/behavioral-intent.md:176-181 + validation-certification-6
4. {INV-004} No committed task's node body is called more than once across a crash-and-resume cycle

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | All M tasks completed before crash; `apply_writes` did not run | All M writes re-applied from pending; zero tasks re-execute; run advances to super-step N+1 without any node bodies running |
| EC-002 | Zero tasks completed before crash (crash at super-step start) | No pending writes found; all M tasks re-execute from scratch |
| EC-003 | A task has an `INTERRUPT` control marker in pending_writes (DEC-009 variant) | `INTERRUPT` skipped during re-apply; node re-executes and re-encounters the interrupt; original interrupt value recovered via scratchpad |
| EC-004 | Send API fan-out: 5 tasks; 3 completed before crash; 2 incomplete (Domain B) (DEC-009) | On resume: 3 completed tasks not re-executed; 2 incomplete tasks re-run; result identical to no-crash run |
| EC-005 | A failed task has `ERROR` + `ERROR_SOURCE_NODE` markers | Both markers skipped; node re-executes; if it fails again, the error handler is invoked freshly |
| EC-006 | `get_tuple()` returns `Err(E-CHKPT-003 CheckpointReadFailed)` during crash-recovery checkpoint load | Recovery halts immediately with `Err(PregolyaError { component: CHKPT, category: DURABILITY, code: E-CHKPT-003, message: "CheckpointReadFailed: cannot restore state for thread '<thread_id>' checkpoint '<checkpoint_id>': <reason>", .. })`; no task writes from `pending_writes` are re-applied; no node bodies execute; caller decides whether to retry or abandon the thread |
| EC-007 | During `_reapply_writes_to_succeeded_nodes`: (a) the storage query for `pending_writes` entries returns an I/O error, OR (b) a retrieved `pending_writes` entry's write value cannot be deserialized to the channel type (data corruption or schema-evolution incompatibility after a checkpoint format change) | Recovery halts immediately with `Err(PregolyaError { component: CHKPT, category: DURABILITY, code: E-CHKPT-003, message: "CheckpointReadFailed: cannot restore state for thread '<thread_id>' checkpoint '<checkpoint_id>': <reason>", .. })` — REUSE of E-CHKPT-003 ("cannot restore state" covers both sub-cases; sub-case (a) `<reason>` = "pending_writes read failed — backend error: <backend_error>"; sub-case (b) `<reason>` = "pending_writes entry for task '<task_id>' deserialization failed — <cause>"); no task writes are re-applied; no node bodies execute; {INV-001} ensures the partially-applied state is never committed; caller decides whether to retry or abandon the thread |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 5-task super-step; tasks 1–3 persisted via `put_writes`; process crash; restart with same thread_id | Tasks 1–3 not re-executed (node bodies not called); tasks 4–5 re-execute; final state matches no-crash run | happy-path |
| 5-task super-step; 0 tasks persisted before crash | All 5 tasks re-execute on resume; final state correct | edge-case |
| Task with `ERROR` marker persisted; crash before `apply_writes`; restart | `ERROR` not re-applied; node re-executes; error handler invoked; final error state recorded correctly | error |
| Send fan-out: 10 tasks; 7 completed; crash; restart | 7 not re-executed; 3 re-run; all 10 results present in final state | edge-case |
| `get_tuple()` returns `Err(E-CHKPT-003 CheckpointReadFailed { thread_id: "t1", checkpoint_id: "c1", reason: "storage unavailable" })` during crash-recovery checkpoint load | `invoke`/`stream` returns `Err(PregolyaError { code: E-CHKPT-003, .. })`; recovery halts immediately; no task writes are re-applied; no node bodies execute | error |
| Crash recovery: `get_tuple()` succeeds; storage query for `pending_writes` entries fails with I/O error during `_reapply_writes_to_succeeded_nodes` | `invoke`/`stream` returns `Err(PregolyaError { code: E-CHKPT-003, .. })`; recovery halts; no task writes re-applied; no node bodies execute (PASS-ABBREV via EC-007) | error |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.04.005-A | No committed task's node body executes more than once across crash-resume | proptest / model-check |
| VP-2.04.005-B | Control signals (ERROR, INTERRUPT, RESUME, ERROR_SOURCE_NODE) are never re-applied from pending_writes | unit test + code review |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 |
| Capability Anchor Justification | CAP-005 ("Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)") per capabilities-p0.md §CAP-005 |
| L2 Domain Invariants | DI-002 (Per-Task Durability (Sync Default)) |
| L2 Edge Cases | DEC-009 (Process Restart During Active Send Fan-Out — Domain B) |
| Source Analysis | semport/graph/behavioral-intent.md §2.4 (pending-writes semantics; _reapply_writes_to_succeeded_nodes skips 4 signals: ERROR, ERROR_SOURCE_NODE, INTERRUPT, RESUME), §5.2 (what survives a crash mid-super-step) |
| Binding Decisions | D11.3 (all three durability tiers; sync default), D17-Q3 (per-task put_writes Phase-1 BC) |
| Domain forcing | Domain B (dark-factory): multi-day graph runs surviving process restarts require this contract |
| Architecture Module | pregolya-checkpoint |
| Stories | S-1.10 |

## Related BCs

- BC-2.04.001 — depends on: per-task put_writes is the mechanism that makes committed-task skip possible
- BC-2.04.002 — depends on: Sync/Async durability (not Exit) is required for crash recovery

## Architecture Anchors

- `architecture/module-decomposition.md §pregolya-checkpoint` — `checkpoint::saver` row: `CheckpointSaver` trait + `put_writes` contract (SS-04)

## Story Anchor

S-1.10 — Crash recovery and committed-task skip

## VP Anchors

- VP-2.04.005-A — at-most-once node body execution across crash-resume (proptest)
- VP-2.04.005-B — control signal exclusion from re-apply (unit test)
