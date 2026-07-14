---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.003
version: "1.1"
status: draft
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "b70ff73bc43c6e0f2789620e0e7fc41b2e5bc60892d1fbf730f8e71cce052be6"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-04
capability: CAP-005
lifecycle_status: active
introduced: v1.0.0-greenfield
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P0
wave: 1
conflict_rejection: CONFLICT-4
---

# BC-2.04.003: Monotonic Logical-Clock Checkpoint IDs — Wall-Clock UUIDs Rejected

## Description

Checkpoint IDs are produced by a monotonic logical clock — either a per-thread/per-namespace
sequence counter or a uuid6-style time-sortable ID — guaranteeing that `ORDER BY checkpoint_id`
yields true chronological order. `Uuid::new_v4()` (random, not time-sortable) and wall-clock
`ORDER BY created_at DESC` are explicitly rejected. This is the direct behavioral rejection of
the adk-rust CONFLICT-4 counter-example: two checkpoints written in the same millisecond, under
NTP adjustment, or under clock skew in distributed deployments must have unambiguous order.

## Preconditions

1. A `CheckpointSaver` implementation provides a `get_next_version(current, channel)` method
2. A new checkpoint is being created for a `(thread_id, checkpoint_ns)` pair
3. The checkpoint ID is computed before writing to storage

## Postconditions

1. The new `checkpoint_id` is strictly greater than all prior `checkpoint_id` values for
   the same `(thread_id, checkpoint_ns)` pair
2. `sort_key(checkpoint_id)` yields chronological order — either numeric comparison or
   lexicographic comparison on the ID string produces the correct sequence
3. `Uuid::new_v4()` is never used as a `checkpoint_id` at any call site
4. `created_at` wall-clock timestamp is stored as metadata only (for observability);
   it is never the canonical ordering key
5. Channel versions within the same super-step share a single `next_version` value;
   that value is monotonically greater than the previous step's version

## Invariants

1. For checkpoints C1 and C2 on the same `(thread_id, checkpoint_ns)`: if C1 was created
   before C2, then `C1.checkpoint_id < C2.checkpoint_id` under the natural ordering of the ID type
2. The logical counter never decreases, even if the system wall clock goes backward (NTP jump)
3. Two checkpoints written within the same millisecond have distinct, ordered IDs
4. A global uniqueness property holds: the triple
   `(thread_id, checkpoint_ns, checkpoint_id)` is unique across all checkpoints in storage

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Two concurrent forks from the same parent checkpoint `P` | Both new checkpoints receive IDs > P; sibling ordering between the two forks is deterministic (e.g., first-writer wins the next counter value); both are valid branch heads |
| EC-002 | System wall clock rolls backward (NTP adjustment) during an active run | Logical counter is unaffected; next checkpoint_id is still monotonically greater than the previous one; no ordering anomaly |
| EC-003 | A caller attempts to construct a checkpoint with a random UUID (`Uuid::new_v4()`) as the ID | Compile-time type mismatch or runtime `Err(FerrochainError { category: CheckpointError, message: "checkpoint_id must be monotonic: random UUID rejected" })` |
| EC-004 | Checkpoint storage is queried with `ORDER BY created_at DESC` | This is a lint-detected anti-pattern; the canonical query MUST use `ORDER BY checkpoint_id DESC`; any storage backend that only exposes wall-clock ordering is non-conformant |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Create 5 sequential checkpoints on thread `"t1"`, namespace `"root"` | `id_1 < id_2 < id_3 < id_4 < id_5`; `ORDER BY checkpoint_id DESC` returns C5, C4, C3, C2, C1; `get_latest` returns C5 | happy-path |
| Simulate wall-clock rollback: create C1 at t=100, then force clock to t=50, create C2 | `C2.checkpoint_id > C1.checkpoint_id` (logical counter unaffected); `C2.metadata.ts` may appear earlier than C1 but ordering is correct | edge-case |
| Attempt `CheckpointSaver::put` with checkpoint whose ID is `Uuid::new_v4().to_string()` | `Err(FerrochainError { category: CheckpointError })` — non-monotonic ID rejected | error |
| Two concurrent writers race to create the next checkpoint on thread `"t1"` | One writer wins the counter; the other retries with a higher ID; final storage contains two distinct monotonic IDs with no ordering tie | edge-case |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.04.003-A | For all pairs (C1, C2) on the same (thread_id, ns): created-before(C1, C2) ↔ C1.id < C2.id | proptest |
| VP-2.04.003-B | No `checkpoint_id` is produced by `Uuid::new_v4()` at any reachable code path | static analysis / grep CI gate |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 |
| Capability Anchor Justification | CAP-005 ("Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)") per capabilities-p0.md §CAP-005 |
| L2 Domain Invariants | DI-004 (Monotonic Checkpoint Clock) |
| Source Analysis | semport/graph/behavioral-intent.md §1.2 (determinism; monotonic next_version), §2.2 (Checkpoint shape; uuid6 IDs); CONFLICT-4 (logical clock vs wall-clock — adk-rust Uuid::new_v4 + created_at DESC is the counter-example) |
| Binding Decisions | D11.2 (Rust-native msgpack format — leaves clock choice open), D11.3 (all three durability tiers — per-task writes compound ordering risk if wall-clock used) |
| Negative evidence | CONFLICT-4: adk-rust `Uuid::new_v4()` + `ORDER BY created_at DESC` fails under NTP adjustment, same-millisecond writes, and distributed clock skew |
| Architecture Module | ferrochain-checkpoint (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.04.004 — composes with: fork lineage via parent pointers depends on stable monotonic IDs
- BC-2.04.006 — composes with: triple-address uniqueness uses checkpoint_id as the third key

## Architecture Anchors

- `architecture/ferrochain-checkpoint.md` — checkpoint ID type, get_next_version contract (filled by architect)

## Story Anchor

S-N.MM — Monotonic checkpoint ID (filled by story-writer)

## VP Anchors

- VP-2.04.003-A — monotonic ordering invariant (proptest)
- VP-2.04.003-B — no random UUID at any call site (CI lint gate)
