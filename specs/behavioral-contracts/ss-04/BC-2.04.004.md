---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.004
version: "1.1"
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
input-hash: "3d1804e"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-04
capability: CAP-005
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-6): E-category canon — EC-003 and test vector error category corrected from `StateUpdateError` to `VAL, code: E-GRAPH-007` (F-P6-03, status/category canon sweep)."
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
conflict_rejection: CONFLICT-4
dec_anchor: DEC-008
---

# BC-2.04.004: Fork Lineage via parent_checkpoint_id Pointers; No State Copy on Fork

## Description

A fork from an existing checkpoint creates a new checkpoint that contains a
`parent_checkpoint_id` pointer to the source checkpoint. The source checkpoint's channel
state blobs are NOT physically copied. Branch lineage is fully recoverable by walking
parent pointers. This rejects the adk-rust fork-by-copy pattern (CONFLICT-4), which loses
branch lineage entirely and requires full state duplication.

## Preconditions

1. An existing checkpoint `C_parent` exists at `(thread_id, checkpoint_ns, checkpoint_id=P)`
2. The caller invokes a fork/time-travel operation
   (e.g., `update_state(config.with_checkpoint_id(P), values)`)
3. The `CheckpointSaver` supports writing a checkpoint with a non-null `parent_checkpoint_id`

## Postconditions

1. A new checkpoint `C_fork` is created with a monotonically greater `checkpoint_id > P`
2. `C_fork.metadata.parents[checkpoint_ns] == P` (pointer to the source; not a data copy)
3. `C_fork.metadata.source` is `"update"` or `"fork"` (not `"loop"`)
4. The original checkpoint `C_parent` is unmodified (no mutation, no side effects)
5. Walking `parent_checkpoint_id` pointers from `C_fork` eventually reaches `C_parent`
6. `C_fork.channel_values` contains only the channels explicitly updated by `values`;
   all other channels are inherited by reference via the parent chain, not duplicated

## Invariants

1. A fork never copies the full channel_values blob; only new/updated channel values
   and metadata are written for the fork checkpoint
2. The source checkpoint is never mutated by any fork operation
3. Multiple sibling forks from the same parent checkpoint are all valid and independent;
   each has `parent_checkpoint_id == P` and each has a distinct monotonic `checkpoint_id`
4. The parent chain forms a DAG (directed acyclic graph), not a cycle; no checkpoint
   may be its own ancestor

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Two concurrent forks from the same parent `P` (DEC-008) | Both `C_fork1` and `C_fork2` have `parent = P`; their own IDs are distinct monotonic values both > P; no shared-state corruption; each fork is independently resumable |
| EC-002 | Fork chain depth N = 200 (deep branch history) | Parent chain walk succeeds iteratively (no stack overflow); all 200 ancestors retrievable via `get_state_history` following parent pointers |
| EC-003 | Fork with `values` update containing an unknown channel key | `Err(FerrochainError { category: VAL, code: E-GRAPH-007 })`; no partial checkpoint is written; `C_parent` unchanged |
| EC-004 | Fork from a checkpoint that is itself a fork (chained forks) | Works correctly; grandchild fork's parent chain walks through the intermediate fork to the root |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `update_state(config.with_checkpoint_id("cp-5"), {k: v})` on thread `"t1"` | New checkpoint with `parent = "cp-5"`, new `checkpoint_id > "cp-5"`, `source = "update"`; original `"cp-5"` unchanged in storage | happy-path |
| Two parallel fork calls from `"cp-5"`: `fork_a` and `fork_b` | Both have `parent = "cp-5"`; fork_a.id != fork_b.id; walking from either arrives at `"cp-5"`; no shared mutable state | edge-case |
| Fork with `values = {nonexistent_channel: 42}` | `Err(FerrochainError { category: VAL, code: E-GRAPH-007 })`; storage unchanged | error |
| Fork from fork: create `cp-5` → fork to `cp-6` → fork again to `cp-7` | `cp-7.parent = "cp-6"`, `cp-6.parent = "cp-5"`; parent walk from `cp-7` reaches both ancestors | edge-case |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.04.004-A | Fork never mutates the source checkpoint (parent immutability) | proptest |
| VP-2.04.004-B | Parent-chain walk from any fork eventually terminates at a root (no cycles) | Kani / proptest |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 |
| Capability Anchor Justification | CAP-005 ("Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)") per capabilities-p0.md §CAP-005 |
| L2 Domain Invariants | DI-004 (Monotonic Checkpoint Clock) |
| L2 Edge Cases | DEC-008 (Checkpoint Fork with Identical Parent) |
| Source Analysis | semport/graph/behavioral-intent.md §2.6 (time-travel and forking; fork via parent pointer); CONFLICT-4 (fork-by-copy in adk-rust is the counter-example: loses branch lineage entirely) |
| Binding Decisions | D11.3 (all three durability tiers confirmed; per-task writes compound the ordering problem if fork copies state) |
| Negative evidence | CONFLICT-4: adk-rust creates a new UUID + full state copy on fork; no parent pointer; branch lineage irrecoverably lost |
| Architecture Module | ferrochain-checkpoint (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.04.003 — depends on: monotonic checkpoint IDs are required for unambiguous parent-pointer chains
- BC-2.04.006 — composes with: triple-address uniqueness ensures fork checkpoint IDs are globally unique

## Architecture Anchors

- `architecture/ferrochain-checkpoint.md` — CheckpointMetadata.parents field, update_state contract (filled by architect)

## Story Anchor

S-N.MM — Fork lineage and time-travel (filled by story-writer)

## VP Anchors

- VP-2.04.004-A — parent immutability on fork (proptest)
- VP-2.04.004-B — no cycles in parent chain (Kani / proptest)
