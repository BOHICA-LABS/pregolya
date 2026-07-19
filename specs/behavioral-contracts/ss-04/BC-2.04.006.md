---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.006
version: "1.4"
status: active
producer: product-owner
timestamp: 2026-07-14T00:00:00Z
phase: 1a
changelog:
  - "1.1 (initial): base BC authored."
  - "1.2 (ADV-P1D-PASS-28): OBS-P28-2 added EC-005 (SessionAddressCollision raise-condition) — E-CHKPT-005 had no behavioral home specifying when it is raised; EC-005 derives the raise-condition from Invariant 1 (composite-PK uniqueness guard at the tenancy boundary)."
  - "1.3 (ADV-P1D-PASS-56-COMPLETION): Gate #30 second-pass census — EC-003 had `Err(FerrochainError { category: VAL })` with no code for the case where both `checkpoint_ns` and `thread_id` are missing. Added code: E-CORE-005 (ValidationFailed) — missing required field `thread_id` is a VAL construction-time validation failure."
  - "1.4 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. (1) EC-003 had bare `Err(FerrochainError { category: VAL, code: E-CORE-005 })` without message; E-CORE-005 has <field> and <detail> placeholders. Added inline message template for the missing thread_id case. (2) EC-005 had `Err(FerrochainError { category: TENANCY, code: \"E-CHKPT-005\" })` without message; E-CHKPT-005 has <t> (thread_id) and <ns> (checkpoint_ns) placeholders. Added inline message template; both are available from config at raise site."
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "fc82aff"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-04
capability: CAP-005
lifecycle_status: active
introduced: v1.0.0-greenfield
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
vp_seed: true
vp_id: VP-002
---

# BC-2.04.006: Session Triple-Address Uniqueness (thread_id, checkpoint_ns, checkpoint_id) — Kani VP Seed

## Description

Every checkpoint storage and retrieval operation is addressed by the complete triple
`(thread_id, checkpoint_ns, checkpoint_id)`. No code path may address state by `thread_id`
alone or by any 2-field subset of the triple. The full triple propagates from the trait
method signature through to the SQL WHERE clause without collapsing any field. This is a
Kani formal-verification seed targeting the NE-12 multi-tenancy correctness obligation —
the adk-rust identity-triple collapse is the explicit counter-example.

## Preconditions

1. A `CheckpointSaver` trait implementation exists for a storage backend (SQLite, in-memory,
   PostgreSQL, or custom)
2. A `RunnableConfig` with `configurable.thread_id`, `configurable.checkpoint_ns`, and
   optionally `configurable.checkpoint_id` is provided to each storage method
3. The storage backend schema includes all three fields as either a composite primary key
   or separately indexed columns

## Postconditions

1. `get_tuple(config)` executes with a WHERE clause equivalent to
   `WHERE thread_id = ? AND checkpoint_ns = ? AND checkpoint_id = ?`
2. `put(config, checkpoint, ...)` inserts with all three fields populated and non-null
3. `put_writes(config, writes, task_id)` stores writes under the full triple key
4. `list(config, ...)` filters by at least `thread_id` and `checkpoint_ns`;
   `checkpoint_id` is optionally further constrained (e.g., `before=`)
5. No query returns data from a different `(thread_id, checkpoint_ns)` pair than requested

## Invariants

1. The triple `(thread_id, checkpoint_ns, checkpoint_id)` is the composite primary key in
   every backend schema; no backend may use bare `checkpoint_id` as a sole primary key
2. `checkpoint_ns` defaults to `""` (empty string) for the root graph; subgraphs use
   `parent_ns + "|" + node_name`; the empty-string root is a valid, distinct namespace
3. No API allows bare `thread_id`-only lookups except `list`, which returns a scoped collection
4. Two sessions on different `thread_id` values but sharing `checkpoint_ns = ""` never
   interfere (thread_id is the primary partition)
5. Two subgraph namespaces on the same `thread_id` never interfere (checkpoint_ns is the
   secondary partition)
6. The full triple flows through the call stack from the public API entry to the SQL/KV
   storage layer without any field being dropped

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Two threads `A` and `B` share the same `checkpoint_ns` and `checkpoint_id` | `get_tuple({A, ns, id})` and `get_tuple({B, ns, id})` return independent results; no cross-contamination |
| EC-002 | Root namespace `checkpoint_ns = ""` and subgraph namespace `checkpoint_ns = "sub"` on the same thread | They are independent namespaces; writes to one never appear in the other; both present in `list` scoped to `thread_id` |
| EC-003 | `get_tuple` called with `RunnableConfig` missing `checkpoint_ns` field | `checkpoint_ns` defaults to `""`; the root namespace is queried; no error if the root namespace exists; `Err(FerrochainError { category: VAL, code: E-CORE-005, message: "Validation failed for 'thread_id': value is required" })` if `thread_id` is also missing |
| EC-004 | Concurrent writes from the same `thread_id` to different `checkpoint_ns` values | Each namespace is independent; no locking across namespaces required; both writes succeed |
| EC-005 | A `put(config, checkpoint, ...)` or `put_writes(config, writes, task_id)` call where the composite triple `(config.thread_id, config.checkpoint_ns, config.checkpoint_id)` already exists in storage under a session belonging to a different tenant context — i.e., the composite-PK uniqueness constraint (Invariant 1) is violated at the tenancy boundary | `Err(FerrochainError { category: TENANCY, code: "E-CHKPT-005", message: "SessionAddressCollision: operation with (thread_id='<t>', ns='<ns>') conflicts with existing session — triple must be unique" })` (where `<t>` = `config.thread_id`, `<ns>` = `config.checkpoint_ns`, both available at raise site); write rejected atomically, no partial mutation. This is the raise-condition for E-CHKPT-005: the composite primary key collision surfaces as a tenancy boundary violation when two distinct tenant contexts attempt to own the same session address triple. In v1 this error surfaces embedded in Run.error. (OBS-P28-2, ADV-P1D-PASS-28.) |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `get_tuple({ thread_id: "A", checkpoint_ns: "root", checkpoint_id: "cp-1" })` | Returns exactly the checkpoint stored at that triple; no other checkpoints from thread `"A"` are returned | happy-path |
| Two threads `"A"` and `"B"`, same `checkpoint_ns = "root"`, same `checkpoint_id = "cp-1"` | `get_tuple({A,...})` returns A's checkpoint; `get_tuple({B,...})` returns B's checkpoint; they are distinct records | edge-case |
| `get_tuple({ thread_id: "A" })` with no `checkpoint_ns` or `checkpoint_id` | `checkpoint_ns` defaults to `""`; `checkpoint_id` selects the latest; returns latest root-namespace checkpoint for thread A | edge-case |
| `put_writes({ thread_id: "A", checkpoint_ns: "" }, writes, task_id="t1")` | Writes stored under `(A, "", current_cp_id, t1)`; not visible under `(A, "sub", current_cp_id, t1)` | edge-case |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.04.006-A | For all storage operations O: O.key contains all three of (thread_id, checkpoint_ns, checkpoint_id); no field is dropped | Kani harness — exhaustive path-symbolic execution of CheckpointSaver trait methods |
| VP-2.04.006-B | For all distinct (thread_id_A, ns_A) ≠ (thread_id_B, ns_B): no write to (A, ns_A) is readable from (B, ns_B) | Kani harness — session tenancy partition |
| VP-2.04.006-C | list(config, filter={}, limit=None) returns only checkpoints where thread_id == config.thread_id AND checkpoint_ns == config.checkpoint_ns | proptest |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 |
| Capability Anchor Justification | CAP-005 ("Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)") per capabilities-p0.md §CAP-005 |
| L2 Domain Invariants | DI-005 (Session Triple-Address Uniqueness) |
| Source Analysis | semport/graph/behavioral-intent.md §2.5 (thread / checkpoint namespacing: thread_id, checkpoint_ns, checkpoint_id) |
| NE anchor | NE-12: adk-rust identity-triple collapse — bare thread_id used in some lookup paths — is the explicit counter-example |
| Binding Decisions | D17-Q7 (Kani VP seed obligation for session tenancy partition) |
| Architecture Module | ferrochain-checkpoint (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.04.001 — composes with: put_writes uses the full triple as the write key
- BC-2.04.003 — depends on: monotonic checkpoint_id is the third field of the triple

## Architecture Anchors

- `architecture/ferrochain-checkpoint.md` — CheckpointSaver trait signatures, storage schema primary key (filled by architect)

## Story Anchor

S-N.MM — Session triple-address and Kani VP (filled by story-writer)

## VP Anchors

- VP-2.04.006-A — triple completeness in all storage ops (Kani)
- VP-2.04.006-B — session tenancy partition (Kani)
- VP-2.04.006-C — list scoping invariant (proptest)
