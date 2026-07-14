---
document_type: adr
level: L3
adr_id: "005"
slug: logical-clock-checkpoint-ordering
title: "Logical Clock and Checkpoint Ordering (CONFLICT-4: monotonic vs wall-clock)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D11]
---

# ADR-005: Logical Clock and Checkpoint Ordering

**Status:** Proposed (CONFLICT-4 resolution; finalizable)

## Context

CONFLICT-4: adk-rust uses UUID v4 + wall-clock `created_at` for checkpoint IDs.
This creates race conditions in concurrent fork/resume scenarios where two forks
created within the same millisecond have non-deterministic ordering. DI-004 mandates
monotonic logical-clock checkpoint IDs.

## Scope

This ADR covers: `checkpoint_id` generation and ordering in ferrochain-checkpoint.
Not covered: `thread_id` (user-supplied string, not clock-derived), `checkpoint_ns` (user-supplied namespace).

## Decision: Monotonic AtomicU64 Logical Clock per CheckpointSaver Instance

**Design:**

```rust
pub struct MonotonicClock {
    counter: std::sync::atomic::AtomicU64,
}

impl MonotonicClock {
    pub fn next_id(&self) -> CheckpointId {
        CheckpointId(self.counter.fetch_add(1, Ordering::SeqCst))
    }
}
```

- `CheckpointId` is a newtype over `u64`, not a UUID. Serialized as `u64` in msgpack.
- Monotonic guarantee: `id_a < id_b` implies `a` was created before `b` on the same saver instance.
- Cross-instance ordering: not required; each process restart starts a new saver instance. Fork lineage (`parent_checkpoint_id`) provides causal ordering across instances.
- Wall-clock UUIDs are REJECTED: `CheckpointId::from_uuid()` does not exist.

**Fork lineage (BC-2.04.004):**

```rust
pub struct CheckpointMetadata {
    pub id: CheckpointId,
    pub parent_checkpoint_id: Option<CheckpointId>,
    pub thread_id: ThreadId,
    pub checkpoint_ns: CheckpointNamespace,
    // ... other fields
}
```

Fork creates a new `CheckpointId` with `parent_checkpoint_id = Some(source_id)`.
State is NOT copied; the parent checkpoint is referenced by pointer only.

## Consequences

- `CheckpointId` is `u64`, not `String` or `Uuid`. Downstream systems that expect UUID-format IDs must adapt.
- HTTP API: `checkpoint_id` field in `/runs` and `/threads` responses is a `u64` encoded as a JSON number.
- The SQL schema stores `checkpoint_id` as `INTEGER NOT NULL`. Primary key is `(thread_id, checkpoint_ns, checkpoint_id)` (composite — VP-002 enforcement).
- `parent_checkpoint_id` is `INTEGER NULL` (null for root checkpoints).
