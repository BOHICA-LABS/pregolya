---
document_type: adr
level: L3
adr_id: "005"
slug: logical-clock-checkpoint-ordering
title: "Logical Clock and Checkpoint Ordering (CONFLICT-4: monotonic vs wall-clock)"
status: accepted
date: "2026-07-19"
subsystems_affected: ["SS-04"]
supersedes: null
superseded_by: null
producer: architect
timestamp: 2026-07-19T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D11]
version: "1.1"
changelog:
  - "1.1 (F-P114-01, 2026-07-19): CRIT — replace argument-less MonotonicClock::next_id() AtomicU64 counter with stateless get_next_version(current, channel) per BC-2.04.003 PC1; correct 'Cross-instance ordering: not required' to cross-restart monotonicity guarantee via persisted-max seeding; define seeding scope as per-(thread_id, checkpoint_ns); document E-CHKPT-003 failure path at get_tuple() read; reconcile API surface with BC-2.04.003; add Rationale, Alternatives Considered, Source/Origin sections per adr-template.md."
  - "1.0 (2026-07-14, initial): base ADR accepted; CONFLICT-4 resolution; CheckpointId as u64 newtype; AtomicU64 per-instance counter design (superseded in 1.1)."
---

# ADR-005: Logical Clock and Checkpoint Ordering

**Status:** Accepted rev-2

## Context

CONFLICT-4: adk-rust uses UUID v4 + wall-clock `created_at` for checkpoint IDs.
This creates race conditions in concurrent fork/resume scenarios where two forks
created within the same millisecond have non-deterministic ordering. DI-004 mandates
monotonic logical-clock checkpoint IDs.

BC-2.04.003 Inv1 requires that for any two checkpoints C1 and C2 on the same
`(thread_id, checkpoint_ns)` pair, if C1 was created before C2 then
`C1.checkpoint_id < C2.checkpoint_id` — with no restart exception. BC-2.04.005
specifies crash recovery that resumes the same `thread_id` post-restart and writes
new checkpoints. BC-2.04.006 Inv1 makes `(thread_id, checkpoint_ns, checkpoint_id)`
the composite primary key across ALL storage, including across restarts.

The rev-1 design (AtomicU64 counter starting at 0 on restart) violated these three BCs:
a fresh-restart saver generates IDs starting at 0, colliding with or underrunning the
persisted maximum and producing PK collisions or ordering violations.

## Scope

This ADR covers: `checkpoint_id` generation and ordering in ferrochain-checkpoint.
Not covered: `thread_id` (user-supplied string, not clock-derived), `checkpoint_ns` (user-supplied namespace).

## Decision: Stateless Monotonic Logical Clock per (thread_id, checkpoint_ns) Pair

### Design

```rust
/// Monotonic logical clock for checkpoint ordering.
///
/// Stateless: all sequencing state is persisted with the checkpoint.
/// Cross-restart monotonicity is implicit: callers pass the `checkpoint_id`
/// from the most recently loaded `CheckpointTuple` (returned by `get_tuple()`)
/// as `current`, ensuring the next ID is always strictly greater than any
/// previously written ID for the same `(thread_id, checkpoint_ns)` pair.
pub struct MonotonicClock;

impl MonotonicClock {
    /// Returns the next checkpoint ID, strictly greater than `current`.
    ///
    /// # Arguments
    /// - `current`:  `None` for a fresh thread/namespace (no prior checkpoints),
    ///               `Some(c)` for the `checkpoint_id` from the most recently
    ///               loaded `CheckpointTuple` for the `(thread_id, checkpoint_ns)` pair.
    /// - `_channel`: Accepted for API compatibility with BC-2.04.003 PC1; unused for
    ///               ordering. All channels within the same super-step receive the same
    ///               `next_version` value because `current` is identical for all
    ///               channel calls within a single super-step (BC-2.04.003 PC5).
    ///
    /// # Return
    /// - `current = None`    → `Ok(CheckpointId(1))` (first checkpoint for this pair)
    /// - `current = Some(c)` → `Ok(CheckpointId(c.0 + 1))`
    ///
    /// # Errors
    /// - `c.0 == u64::MAX`: `Err(FerrochainError { category: INTERNAL, code: E-CHKPT-002,
    ///   message: "MonotonicClockRegression: checkpoint_id overflow — u64 exhausted" })`.
    ///   Unreachable in practice (requires 2^64 checkpoints per thread/namespace).
    pub fn get_next_version(
        current: Option<CheckpointId>,
        _channel: &ChannelName,
    ) -> Result<CheckpointId, FerrochainError> {
        match current {
            None => Ok(CheckpointId(1)),
            Some(c) => c.0.checked_add(1)
                .map(CheckpointId)
                .ok_or_else(|| FerrochainError {
                    component: Component::CHKPT,
                    category: Category::INTERNAL,
                    code: "E-CHKPT-002",
                    message: "MonotonicClockRegression: checkpoint_id overflow — u64 exhausted",
                }),
        }
    }
}
```

- `CheckpointId` is a newtype over `u64`, not a UUID. Serialized as `u64` in msgpack.
- Wall-clock UUIDs are REJECTED: `CheckpointId::from_uuid()` does not exist.

### Seeding Scope

Seeding is per `(thread_id, checkpoint_ns)` pair:

- **Scope justification:** BC-2.04.003 Inv1 scopes the monotonicity invariant to `(thread_id, checkpoint_ns)` pairs. The `current` parameter is the `checkpoint_id` from the most recently loaded `CheckpointTuple` for that specific pair, not a store-global counter.
- **PK uniqueness:** BC-2.04.006 Inv1 defines the composite PK as `(thread_id, checkpoint_ns, checkpoint_id)`. Two different `(thread_id, checkpoint_ns)` pairs may independently start at `CheckpointId(1)` without violating global uniqueness.
- **Seeding mechanism:** Before calling `get_next_version`, the `CheckpointSaver` implementation loads the latest `CheckpointTuple` for the `(thread_id, checkpoint_ns)` pair via `get_tuple()` and passes its `checkpoint_id` as `current`. For fresh threads (no prior checkpoints), `get_tuple()` returns `Ok(None)` → `current = None` → `CheckpointId(1)`.
- **No constructor-time read required:** Seeding occurs at operation time (when a new super-step begins), not at `CheckpointSaver` construction time. The saver holds no mutable sequence counter.

### Cross-Restart Monotonicity Guarantee

`get_next_version` takes `current` as an explicit parameter derived from persisted storage. This guarantees that after a process restart, the next `CheckpointId` for any `(thread_id, checkpoint_ns)` pair is always strictly greater than all previously written IDs for that pair — without requiring any in-memory counter to survive the restart.

**Corrected guarantee (supersedes rev-1):** Cross-restart monotonicity is preserved for each `(thread_id, checkpoint_ns)` pair. The `current` parameter is the `checkpoint_id` sourced from the persisted `CheckpointTuple` returned by `get_tuple()`, so the generated ID is always strictly greater than the persisted maximum, regardless of how many times the process has restarted.

The rev-1 claim "Cross-instance ordering: not required; each process restart starts a new saver instance" is **retracted**. An in-memory counter that starts at 0 on each restart violates BC-2.04.003 Inv1 (cross-restart monotonicity not excepted) and BC-2.04.006 Inv1 (PK collision after restart). The stateless design with `current` sourced from storage is the correct replacement.

### API Surface Reconciliation

BC-2.04.003 PC1 specifies `get_next_version(current, channel)` as the required method signature. The rev-1 design exposed `next_id(&self)` with no parameters — an in-memory `AtomicU64` counter that started at 0 on each restart. These are incompatible:

| Dimension | rev-1 (retracted) | rev-2 (this ADR) |
|-----------|-------------------|-------------------|
| Signature | `next_id(&self) -> CheckpointId` | `get_next_version(current: Option<CheckpointId>, _channel: &ChannelName) -> Result<CheckpointId, FerrochainError>` |
| State | AtomicU64 counter in instance | Stateless; all state in `current` parameter |
| Seeding | None (starts at 0) | Sourced from persisted `CheckpointTuple` by caller |
| Cross-restart | Resets to 0 (PK collision risk) | Monotonicity preserved via persisted-max seed |

The `channel` parameter matches BC-2.04.003 PC1's `get_next_version(current, channel)` signature. It is accepted but unused for ordering: per BC-2.04.003 PC5, all channels within the same super-step share a single `next_version` value because `current` is identical for all channel calls within a super-step (all derived from the same loaded checkpoint).

### Failure Mode: get_tuple() Read Failure

If `get_tuple()` returns `Err(FerrochainError { category: DURABILITY, code: E-CHKPT-003, ... })` during crash recovery or run resumption:

- Recovery halts immediately per BC-2.04.005 EC-006.
- `get_next_version` is NOT called with an assumed-zero `current`.
- The error propagates to the caller unchanged.

This closes the "silent PK collision" failure mode: the saver never computes a new `CheckpointId` without first successfully loading the persisted state.

### Fork Lineage (BC-2.04.004, unchanged)

```rust
pub struct CheckpointMetadata {
    pub id: CheckpointId,
    pub parent_checkpoint_id: Option<CheckpointId>,
    pub thread_id: ThreadId,
    pub checkpoint_ns: CheckpointNamespace,
    // ... other fields
}
```

Fork creates a new `CheckpointId` (via `get_next_version`) with `parent_checkpoint_id = Some(source_id)`.
State is NOT copied; the parent checkpoint is referenced by pointer only.

## Rationale

The stateless `get_next_version(current, channel)` design is the only approach that satisfies all three governing BCs simultaneously:

1. **BC-2.04.003 PC1/Inv1:** The method signature `get_next_version(current, channel)` is directly specified by PC1. Inv1 requires monotonicity for each `(thread_id, checkpoint_ns)` pair with no restart exception — an in-memory counter that resets on restart cannot satisfy this invariant.

2. **BC-2.04.006 Inv1:** The composite PK `(thread_id, checkpoint_ns, checkpoint_id)` must be unique across ALL storage, including across restarts and across different saver instances. A counter that resets to 0 generates IDs that collide with pre-restart persisted IDs, violating this invariant.

3. **BC-2.04.005 (crash recovery):** Crash recovery uses the same `thread_id` post-restart. The saver must generate IDs that are strictly greater than the last ID written before the crash for that `(thread_id, checkpoint_ns)` pair. Only a design that reads the persisted max at operation time can guarantee this.

The `current` parameter design achieves all three properties by construction: because `current` is the persisted `checkpoint_id` from `get_tuple()`, the next ID is always `persisted_max + 1`. No operational discipline, initialization sequence, or in-memory state is needed — the invariant is enforced by the function signature itself.

The per-`(thread_id, checkpoint_ns)` seeding scope is chosen over a store-global counter because BC-2.04.003 Inv1 scopes monotonicity to the pair, not to the store. A store-global counter would be unnecessarily strict and would serialize checkpoint ID allocation across unrelated threads.

## Consequences

### Positive

- Cross-restart monotonicity is guaranteed by construction — no in-memory state to manage or lose across restarts.
- The function is pure (no side effects, no mutable state) and directly Kani-verifiable as part of the sync pure-core mandate.
- The API signature matches BC-2.04.003 PC1 exactly, eliminating the prior BC/ADR contract divergence.
- `get_tuple()` failure (E-CHKPT-003) is handled uniformly at the call site before `get_next_version` is invoked — no hidden "start from zero" fallback.

### Negative / Trade-offs

- Callers bear the responsibility of loading the latest `CheckpointTuple` before calling `get_next_version`. The saver implementation must not skip or cache-bypass this load at the start of each super-step.
- Return type is `Result<CheckpointId, FerrochainError>` rather than a plain `CheckpointId` — callers must propagate the overflow error even though it is unreachable in practice. This is the production-grade default (no silent panic for arithmetic).
- `CheckpointId` is `u64`, not `String` or `Uuid`. Downstream systems that expect UUID-format IDs must adapt.

### Status as of rev-2 (2026-07-19)

In-effect per this ADR revision. Implementation of `checkpoint::clock::get_next_version` is
pending Phase 3 (Wave 1, ferrochain-checkpoint story). The retired `checkpoint::clock::next_id`
symbol MUST NOT appear in any Phase 3 implementation.

## Alternatives Considered

- **Option A — Constructor-time store-max seed (AtomicU64 initialized at `CheckpointSaver::new()`):** Read the global or per-pair maximum `checkpoint_id` from storage at construction time and initialize an `AtomicU64` at that value. Rejected: (a) requires a store read that can fail with E-CHKPT-003 at construction, complicating the constructor result; (b) in-memory counter diverges from storage if the saver is reused across multiple concurrent pairs; (c) a global max seed is more aggressive than the per-pair scope in BC-2.04.003 Inv1 and can starve ID space unnecessarily.

- **Option B — Per-(thread_id, checkpoint_ns) counter map in CheckpointSaver:** Maintain a `HashMap<(ThreadId, Namespace), AtomicU64>` seeded from the persisted max at first use per pair. Rejected: significantly more complex than the stateless design; the map is mutable shared state requiring synchronization; on restart the map starts empty and must re-seed from storage on first use anyway — equivalent to the stateless design but with extra indirection.

- **Option C — UUID v6 / ULID (time-sortable):** Use ULIDs or UUID v6 which embed a millisecond timestamp and are lexicographically sortable. Rejected: (a) same-millisecond writes within one saver still require a monotonic counter component, reintroducing the seeding problem; (b) adds UUID/ULID dependency; (c) CONFLICT-4 explicitly rejects wall-clock ordering; (d) ULIDs are `String`s — the BC requires `u64` semantics for simple numeric comparison.

- **Option D — Global sequence table in storage:** Add a `sequences` table to the backend (one row per `(thread_id, checkpoint_ns)`); atomically increment via `UPDATE ... RETURNING`. Rejected: backend-specific; SQLite supports this but it requires a separate write per super-step beyond the checkpoint write; adds migration complexity; the BC does not require a separate sequence object — `get_tuple()` already returns the current max as part of the loaded checkpoint.

## Source / Origin

- **BC-2.04.003 PC1** — mandates `get_next_version(current, channel)` API signature; Inv1 mandates monotonicity with no restart exception; PC5 mandates all channels share a single `next_version` per super-step.
- **BC-2.04.006 Inv1** — establishes `(thread_id, checkpoint_ns, checkpoint_id)` as the composite PK across all storage; drives the cross-restart uniqueness requirement.
- **BC-2.04.005 EC-006** — defines E-CHKPT-003 CheckpointReadFailed as the recovery-halt path; drives the failure-mode design.
- **DI-004** (domain invariant) — "Monotonic Checkpoint Clock" — foundational requirement; no wall-clock dependency.
- **CONFLICT-4** (comparative assessment) — adk-rust `Uuid::new_v4()` + `ORDER BY created_at DESC` is the explicit counter-example.
- **F-P114-01** (adversary pass 114, burst 117, 2026-07-19) — CRIT finding that identified the rev-1 AtomicU64 design as violating BC-2.04.003/006 cross-restart monotonicity + triple uniqueness.
