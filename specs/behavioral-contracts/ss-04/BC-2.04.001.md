---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.001
version: "1.1"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "0d1063d"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-04
capability: CAP-005
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-6): E-category canon — EC-002 and test vector error category corrected from `CheckpointError` to `DURABILITY, code: E-CHKPT-001` (F-P6-03, status/category canon sweep)."
  - "1.1 (ADV-P1D-PASS-20): F-P20-02 — `Checkpointer` → `CheckpointSaver` in PC-1 (canonical trait name correction)."
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
---

# BC-2.04.001: Per-Task put_writes Completes Before Next Super-Step Begins

## Description

Every PregelTask's output is stored via `put_writes` before `apply_writes` is called to
advance to the next super-step. As each task finishes, its writes are submitted to the
checkpointer under the current `checkpoint_id` keyed by `task_id` — providing per-task
crash-safety at sub-step granularity. This is the foundational contract that makes
`sync`/`async` durability tiers meaningful.

## Preconditions

1. A `StateGraph` is compiled with a `CheckpointSaver` that implements the `put_writes` method
2. The durability tier is `DurabilityTier::Sync` or `DurabilityTier::Async` (not `Exit`)
3. At least one PregelTask has completed execution within the current super-step
4. The task's writes are non-null (even empty lists are valid — the task completed)

## Postconditions

1. For each completed PregelTask, `put_writes(config, writes, task_id)` has been called
   and submitted to the backend before `apply_writes` is invoked for the super-step
2. The writes are linked to the current `checkpoint_id` with `task_id` as the sub-key
3. With `DurabilityTier::Sync`: `put_writes` futures are fully resolved (storage confirmed)
   before the super-step boundary (`apply_writes` + new checkpoint creation)
4. With `DurabilityTier::Async`: `put_writes` futures are submitted (queued) before the
   next super-step begins; futures are joined before the run exits
5. Special-channel writes (`ERROR`, `INTERRUPT`, `RESUME`, `SCHEDULED`) use negative write
   indices `(-1, -3, -4, -2)` that never collide with regular writes; dedup is last-write-wins
   for special channels

## Invariants

1. `put_writes` is called as each task finishes — per-task, not batched at super-step end
2. The write record links `(config.thread_id, config.checkpoint_ns, current_checkpoint_id,
   task_id)` — the full four-field key
3. A task producing zero writes still results in a `put_writes` call with an empty write list;
   the task is marked committed
4. The super-step boundary (apply_writes + new checkpoint) does not execute until all
   `put_writes` submissions are at minimum queued (async) or confirmed (sync)

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Task produces no writes (zero-output node) | `put_writes(config, [], task_id)` is called; task is recorded as committed; super-step boundary proceeds normally |
| EC-002 | `put_writes` storage backend returns an error | Error surfaces as `Err(FerrochainError { category: DURABILITY, code: E-CHKPT-001 })`; super-step does NOT advance; the run transitions to `failed` |
| EC-003 | Durability tier is `Exit` | `put_writes` is NOT called mid-run; writes accumulate in memory; only the full checkpoint is written on graph exit |
| EC-004 | Task writes to ERROR special channel | Written with negative index (-1); does not collide with regular writes; recorded separately for error-handler re-routing on crash-resume |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 3-task super-step with `sync` durability; all 3 tasks complete | All 3 `put_writes` calls confirmed in storage BEFORE `apply_writes` executes for super-step N+1; verified by querying `pending_writes` table before advancing | happy-path |
| 3-task super-step; task 2 produces an empty write list | `put_writes(config, [], task2_id)` called successfully; no error; super-step boundary proceeds; task 2 is committed | edge-case |
| `put_writes` storage call fails with I/O error on task 1 completion | `Err(FerrochainError { category: DURABILITY, code: E-CHKPT-001 })` returned to caller; `apply_writes` not executed; graph halts without advancing to super-step N+1 | error |
| 3-task super-step with `exit` durability | Zero `put_writes` calls mid-run; only one full `put` call on graph exit; crash mid-run loses all task writes from the current run | edge-case |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.04.001-A | For all tasks T in super-step S, `put_writes(T)` precedes `apply_writes(S)` in the happens-before partial order | proptest / model check |
| VP-2.04.001-B | Storage contains a `pending_writes` record for each completed task before the next checkpoint is created | integration test |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 |
| Capability Anchor Justification | CAP-005 ("Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)") per capabilities-p0.md §CAP-005 |
| L2 Domain Invariants | DI-002 (Per-Task Durability (Sync Default)) |
| Source Analysis | semport/graph/behavioral-intent.md §2.4 (pending-writes semantics); CONFLICT-2 (per-task pending writes vs step-boundary whole-state) |
| Binding Decisions | D11.3 (all three durability tiers; sync default), D17-Q3 (per-task put_writes is Phase-1 BC) |
| Architecture Module | ferrochain-checkpoint (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.04.002 — depends on: establishes that `sync` is the default tier under which this contract is strongest
- BC-2.04.005 — composes with: crash recovery relies on `put_writes` having been called per-task
- BC-2.04.006 — depends on: session triple-address uniqueness is precondition for correct `put_writes` keying

## Architecture Anchors

- `architecture/ferrochain-checkpoint.md` — checkpoint trait and storage contracts (filled by architect)

## Story Anchor

S-N.MM — Checkpoint per-task write contract (filled by story-writer)

## VP Anchors

- VP-2.04.001-A — put_writes precedes apply_writes (proptest)
- VP-2.04.001-B — pending_writes present before checkpoint advance (integration)
