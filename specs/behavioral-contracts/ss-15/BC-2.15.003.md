---
document_type: behavioral-contract
level: L3
bc_id: BC-2.15.003
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P2
subsystem: SS-15
capability: CAP-017
wave: 2
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-memory per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-017
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "ae9233f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.15.003: GDPR Erasure Removes All Traces from All Memory Tiers

## Description

When a GDPR erasure request is submitted for a `user_id`, `ferrochain-memory` must
delete **all memory entries in all three tiers** (user-scoped, app-scoped authored-by,
and session-scoped belonging to the user's sessions) that are attributable to that
user. The erasure is **atomically all-or-nothing**: if any tier fails mid-erasure, the
operation rolls back and returns `Err(E-MEMORY-005 ErasurePartialFailure)`. A receipt
with per-tier deletion counts is returned on success. The operation is irreversible at
the application level — no soft-delete or tombstone pattern is used for the primary data
(a compliance audit log may record the erasure event, subject to its own retention
policy).

## Preconditions

1. A valid `user_id` is provided in the erasure request.
2. The `MemoryStore` has at least the user-scoped and app-scoped tiers enabled.
3. The caller has operator-level privilege (same `AdminContext` as admin operations
   in BC-2.15.002); erasure cannot be initiated from a standard `RunnableConfig` context.

## Postconditions

1. All entries with `MemoryScope::User(user_id)` are deleted from the store. A
   subsequent `memory_get(User(user_id), any_key)` returns `None`.
2. All session-scoped entries from sessions attributable to `user_id` are deleted.
   The store must maintain a `session_id → user_id` mapping to support this lookup.
3. All app-scoped entries authored by `user_id` (i.e., written with `author_id =
   user_id` in the entry metadata) are deleted. App-scoped entries authored by other
   users are unaffected.
4. A `GdprErasureReceipt` is returned on success containing:
   - `user_id: UserId`
   - `erased_at: Timestamp`
   - `user_scoped_count: u64`
   - `app_scoped_authored_count: u64`
   - `session_scoped_count: u64`
5. If the user has no memory entries in any tier, the operation returns `Ok(receipt)`
   with all counts set to `0`. This is not an error.
6. The erasure is recorded in the compliance audit log (if configured) with the
   `GdprErasureReceipt`. The compliance audit log itself is NOT deleted by this
   operation; it is subject to a separate retention policy.

## Invariants

- **Atomicity:** The erasure across all three tiers is wrapped in a single database
  transaction (or equivalent atomic operation). A storage failure that occurs after
  deleting user-scoped entries but before deleting session-scoped entries causes the
  transaction to roll back. No partial erasure state is committed.
- **Irreversibility:** Deleted entries cannot be restored by any application-level
  API call after a successful erasure. (Physical recoverability from backup media is
  a separate operational concern outside this contract's scope.)
- **Author-id tracking:** App-scoped entries must carry an `author_id` metadata field
  set at write time. Entries written before `author_id` tracking was introduced are
  treated as having `author_id = None` and are NOT deleted by user erasure (they lack
  attributability). This is a documented limitation.

## Edge Cases

### EC-001: User has no memory entries in any tier
**Scenario:** GDPR erasure submitted for `user_id = "ghost"` who has never written
any memory entries.
**Expected behavior:** `Ok(GdprErasureReceipt { user_scoped_count: 0,
app_scoped_authored_count: 0, session_scoped_count: 0, ... })`. Not an error.

### EC-002: Storage error mid-erasure (atomicity test)
**Scenario:** The database returns a write error after user-scoped entries are deleted
but before session-scoped entries are deleted (injected fault).
**Expected behavior:** The entire transaction is rolled back. All user-scoped entries
that were deleted are restored. `Err(E-MEMORY-005 ErasurePartialFailure { user_id,
deleted_before_rollback: UserScoped(42), backend_error: "<reason>" })` is returned.
A subsequent `memory_get(User(user_id), any_key)` returns the original values (rollback
confirmed).

### EC-003: Concurrent memory writes during erasure
**Scenario:** A graph node writes a new user-scoped entry for `user_id = "alice"` at
the same time as a GDPR erasure for "alice" is in progress.
**Expected behavior:** The erasure transaction serializes with the concurrent write.
Either the new write is included in the erasure (if it commits before the transaction
closes) or it is excluded (if it commits after). No data race; no partial-delete of
the new entry.

### EC-004: Session-to-user mapping not available for old sessions
**Scenario:** An old session predates the introduction of `session_id → user_id`
tracking. Session-scoped entries exist but cannot be attributed.
**Expected behavior:** Erasure proceeds for all tiers that have attribution data.
A `WARN` log is emitted: `"GDPR erasure: N session entries could not be attributed to
user_id=<id> due to missing session-user mapping; these entries are NOT deleted."` The
receipt includes `unattributed_session_count: N`. This is a documented limitation.

### EC-005: Caller without admin privilege attempts erasure
**Scenario:** A standard `RunnableConfig` context (graph node) calls the erasure API.
**Expected behavior:** `Err(E-MEMORY-006 InsufficientPrivilege { operation: "gdpr_erasure",
required: "AdminContext" })` before any deletion occurs.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Write user-scoped entries for "alice"; GDPR erasure for "alice"; `memory_get(User("alice"), any_key)` | `None` | User-scoped entries removed |
| TV-002 | Write session-scoped entries for "alice"'s sessions; GDPR erasure for "alice"; `memory_get(Session(alice_session), any_key)` | `None` | Session-scoped entries removed |
| TV-003 | Write app-scoped entries by "alice" and by "bob"; GDPR erasure for "alice"; `memory_get(App("app"), bob_key)` | `Some(bob_value)` — bob's entries unaffected | Only alice's authored entries removed |
| TV-004 | GDPR erasure for user with no entries | `Ok(receipt)` with all counts = 0 | Empty erasure is not an error |
| TV-005 | Inject storage fault mid-erasure (after user-scope delete, before session-scope delete) | `Err(E-MEMORY-005 ErasurePartialFailure)`; user-scoped entries restored (rollback verified) | Atomicity: partial failure rolls back |
| TV-006 | Caller without `AdminContext`; GDPR erasure attempt | `Err(E-MEMORY-006 InsufficientPrivilege)` | Privilege guard: no deletion occurs |
| TV-007 | Successful erasure; verify `GdprErasureReceipt` fields | `user_scoped_count` = N (written count); `erased_at` is a valid timestamp; `user_id` matches request | Receipt completeness |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-MEM-05 | Erasure is atomic: storage fault mid-transaction rolls back all deletions | Integration test with injected fault (mock SQLite error after first DELETE statement) | Post-v1 |
| VP-MEM-06 | Erasure removes all user-scoped entries; zero entries remain after successful erasure | Integration test (write N entries; erase; assert memory_search returns empty) | Post-v1 |

## Related BCs

- BC-2.15.001 — depends on: KV persistence semantics define what is being erased
- BC-2.15.002 — depends on: tier isolation defines the scope boundaries that erasure must cover

## Architecture Anchors

- `ferrochain-memory/src/gdpr.rs` — `gdpr_erasure(user_id: UserId, ctx: AdminContext)` entry point
- `ferrochain-memory/src/sqlite.rs` — transactional multi-table DELETE for three tiers
- `ferrochain-memory/src/audit_log.rs` — compliance audit log writing `GdprErasureReceipt` without deleting the log itself

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-MEM-05, VP-MEM-06

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-017 |
| Capability Anchor Justification | CAP-017 ("Long-Horizon Cross-Session Memory Store (KV + Vector)") per capabilities-p1-p2.md §CAP-017 — "GDPR erasure must remove all traces from all tiers" is verbatim text in the CAP-017 description |
| L2 Domain Invariants | — (no DI directly applies; CONFLICT-7 memory scope model and GDPR requirement are the primary references) |
| CONFLICT Reference | CONFLICT-7 — memory scope: user/app/session partitioning + GDPR erasure; erasure must cover all three tiers |
| Domain C Forcing Function | domain-c-openclaw.md §2.6 — memory is per-agent; domain-c §4 — credential / data handling as operator responsibility; the absence of GDPR tooling in OpenClaw is a gap ferrochain addresses |
| Priority | P2 |
| Wave | Wave 2 |
| Test Types | I (integration) |
| Module | ferrochain-memory |
