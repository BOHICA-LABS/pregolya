---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.005
version: "1.4"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "4fa1f6b"
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
  - "1.3 (2026-07-19, F-P114-01 fix burst 117): Anchor correction — Architecture Anchors updated from nonexistent 'architecture/ferrochain-checkpoint.md' to 'architecture/module-decomposition.md §ferrochain-checkpoint' (checkpoint::saver row) per architect adjudication (burst 117). No BC body content changed."
  - "1.4 (notation-sweep-wave-b-ss04/2026-07-29): Class 3 error-construction notation sweep (Wave B batch B4). EC-006 Expected Behavior cell: added `..` rest-pattern marker (4 of 5 fields present, missing retry_hint). Test-vector row: replaced forbidden `...` (three-dot ASCII) with `..` (CLASS3_ASCII_ELLIPSIS_VIOLATION; ADR-010 §Error-Construction Notation Canon, Class 3)."
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

1. A graph run is in progress with `sync` or `async` durability and a durable `CheckpointSaver`
2. During super-step N, K of M total tasks have completed and their writes are persisted via
   `put_writes` (K ≥ 0)
3. The process crashes before `apply_writes` completes the super-step N+1 checkpoint
4. The same graph is restarted and `invoke`/`stream` is called with the same `thread_id`

## Postconditions

1. The graph loads the most recent committed checkpoint (super-step N-1 or earlier)
2. `_reapply_writes_to_succeeded_nodes` restores the K committed tasks' write sets from
   `pending_writes` storage, WITHOUT re-executing those nodes' bodies
3. The remaining M-K uncommitted tasks re-execute from their node entry points
4. The skipped control signals (`ERROR`, `ERROR_SOURCE_NODE`, `INTERRUPT`, `RESUME`) are
   NOT re-applied from pending_writes; their nodes re-execute and encounter them freshly
5. The run completes with a final state identical to what would have been produced without
   the crash (given idempotent node side-effects)
6. Total node executions = M-K (only uncommitted) + later super-steps; no task executes twice

## Invariants

1. A task is "committed" if and only if its `task_id` appears in `pending_writes` for the
   current `checkpoint_id` with non-empty writes (or explicit empty-write record)
2. Task IDs are deterministic content-addressed hashes — the same graph state and step produce
   the same task_id on restart, enabling correct pending-write matching
3. **Control-signal write routing vs. re-apply skip set (two distinct concepts):**
   - *Write-routing index map* (`WRITES_IDX_MAP`): four channels use negative indices for
     internal routing: `ERROR=-1`, `SCHEDULED=-2`, `INTERRUPT=-3`, `RESUME=-4`. `SCHEDULED`
     carries the -2 index and is routed normally — it is NOT excluded from re-apply.
   - *Skip-on-reapply set*: four signals are filtered out during
     `_reapply_writes_to_succeeded_nodes` so that failed/interrupted nodes re-execute
     and encounter them freshly: `ERROR`, `ERROR_SOURCE_NODE`, `INTERRUPT`, `RESUME`.
     Note: `ERROR_SOURCE_NODE` does not have a dedicated negative index but IS skipped.
     Note: `SCHEDULED` has index -2 but is NOT skipped (its write is re-applied normally).
   - Source: semport/graph/behavioral-intent.md:176-181 + validation-certification-6
4. No committed task's node body is called more than once across a crash-and-resume cycle

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | All M tasks completed before crash; `apply_writes` did not run | All M writes re-applied from pending; zero tasks re-execute; run advances to super-step N+1 without any node bodies running |
| EC-002 | Zero tasks completed before crash (crash at super-step start) | No pending writes found; all M tasks re-execute from scratch |
| EC-003 | A task has an `INTERRUPT` control marker in pending_writes (DEC-009 variant) | `INTERRUPT` skipped during re-apply; node re-executes and re-encounters the interrupt; original interrupt value recovered via scratchpad |
| EC-004 | Send API fan-out: 5 tasks; 3 completed before crash; 2 incomplete (Domain B) (DEC-009) | On resume: 3 completed tasks not re-executed; 2 incomplete tasks re-run; result identical to no-crash run |
| EC-005 | A failed task has `ERROR` + `ERROR_SOURCE_NODE` markers | Both markers skipped; node re-executes; if it fails again, the error handler is invoked freshly |
| EC-006 | `get_tuple()` returns `Err(E-CHKPT-003 CheckpointReadFailed)` during crash-recovery checkpoint load | Recovery halts immediately with `Err(FerrochainError { component: CHKPT, category: DURABILITY, code: E-CHKPT-003, message: "CheckpointReadFailed: cannot restore state for thread '<thread_id>' checkpoint '<checkpoint_id>': <reason>", .. })`; no task writes from `pending_writes` are re-applied; no node bodies execute; caller decides whether to retry or abandon the thread |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 5-task super-step; tasks 1–3 persisted via `put_writes`; process crash; restart with same thread_id | Tasks 1–3 not re-executed (node bodies not called); tasks 4–5 re-execute; final state matches no-crash run | happy-path |
| 5-task super-step; 0 tasks persisted before crash | All 5 tasks re-execute on resume; final state correct | edge-case |
| Task with `ERROR` marker persisted; crash before `apply_writes`; restart | `ERROR` not re-applied; node re-executes; error handler invoked; final error state recorded correctly | error |
| Send fan-out: 10 tasks; 7 completed; crash; restart | 7 not re-executed; 3 re-run; all 10 results present in final state | edge-case |
| `get_tuple()` returns `Err(E-CHKPT-003 CheckpointReadFailed { thread_id: "t1", checkpoint_id: "c1", reason: "storage unavailable" })` during crash-recovery checkpoint load | `invoke`/`stream` returns `Err(FerrochainError { code: E-CHKPT-003, .. })`; recovery halts immediately; no task writes are re-applied; no node bodies execute | error |

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
| Architecture Module | ferrochain-checkpoint (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.04.001 — depends on: per-task put_writes is the mechanism that makes committed-task skip possible
- BC-2.04.002 — depends on: Sync/Async durability (not Exit) is required for crash recovery

## Architecture Anchors

- `architecture/module-decomposition.md §ferrochain-checkpoint` — `checkpoint::saver` row: `CheckpointSaver` trait + `put_writes` contract (SS-04)

## Story Anchor

S-N.MM — Crash recovery and committed-task skip (filled by story-writer)

## VP Anchors

- VP-2.04.005-A — at-most-once node body execution across crash-resume (proptest)
- VP-2.04.005-B — control signal exclusion from re-apply (unit test)
