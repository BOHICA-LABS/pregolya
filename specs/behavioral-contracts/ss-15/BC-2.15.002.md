---
document_type: behavioral-contract
level: L3
bc_id: BC-2.15.002
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
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "f518e29"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.15.002: User/App/Session Tier Isolation — User-Private Does Not Bleed Across Scopes

## Description

`ferrochain-memory` organizes memory entries into three isolation tiers: **user-scoped**
(private to a single user identity), **app-scoped** (shared across all users within an
application deployment), and **session-scoped** (private to a single session and
discarded when the session ends or is reset). This contract specifies the isolation
guarantee: no read or search operation may return entries from a higher-privilege or
different-owner tier without explicit elevation. Scope isolation is enforced at the
storage layer (SQL `WHERE` clause or equivalent index predicate) — not solely at the
application layer. This contract applies the NE-12 tenancy partition principle to the
memory tier model: scope fields flow from the trait method signature to the storage
predicate without collapsing.

## Preconditions

1. `MemoryStore` is configured with at least the user-scoped and app-scoped tiers.
2. Memory entries exist in all three tiers for different users/sessions.
3. A read or search operation is performed with a specific `MemoryScope` identifier.

**Scope definitions:**
- `MemoryScope::User(user_id)` — entries visible only to `user_id`
- `MemoryScope::App(app_id)` — entries visible to all callers within the same `app_id`
- `MemoryScope::Session(session_id)` — entries visible only to the calling `session_id`

## Postconditions

**Tier isolation:**
1. `memory_get(MemoryScope::User("alice"), key)` returns only entries that were written
   with `MemoryScope::User("alice")`; entries for `User("bob")` are invisible.
2. `memory_get(MemoryScope::Session("s1"), key)` returns only entries written with
   `MemoryScope::Session("s1")`; entries for `Session("s2")` are invisible.
3. `memory_get(MemoryScope::App("app1"), key)` returns entries visible to all callers
   within `"app1"`, regardless of `user_id` or `session_id`.

**Scope hierarchy (read-up semantics):**
4. `memory_get` with `MemoryScope::Session("s1")` does **not** automatically fall through
   to user-scope or app-scope. If callers want cross-scope reads, they must issue
   separate `memory_get` calls per scope. There is no implicit scope elevation.
5. App-scoped entries written by user "alice" are readable by user "bob" in the same
   app (app scope is shared by design). No content-level access control is applied
   within app scope in v1.

**Storage-layer enforcement:**
6. Scope isolation is implemented as a SQL `WHERE scope_key = ?` predicate (or
   equivalent index predicate) evaluated at the storage layer. No application-layer
   post-filtering is the primary isolation mechanism; the WHERE clause is mandatory.

## Invariants

- **NE-12 tenancy partition analog:** scope fields (`user_id`, `app_id`, `session_id`)
  flow from the `MemoryScope` enum passed to the trait method, through to the SQL
  WHERE clause, without collapsing or merging. No code path may issue a query without
  a scope predicate unless it is explicitly documented as a privileged admin operation.
- Writing to `MemoryScope::User("bob")` as caller "alice" (scope mismatch) returns
  `Err(E-MEMORY-003 ScopeAccessDenied { requested_scope: User("bob"),
  caller_identity: "alice" })` when identity enforcement is active. (v1 scope: enforcement
  is opt-in at the server layer; the store itself trusts the caller-provided scope.)
- Session-scoped entries may be explicitly deleted when a session ends; the memory store
  exposes `memory_delete_session(session_id)` for this purpose. Automatic session-scoped
  cleanup is opt-in.

## Edge Cases

### EC-001: No scope provided; default is session-scoped
**Scenario:** A caller invokes `memory_get(key)` without specifying a `MemoryScope`.
**Expected behavior:** The default scope is `MemoryScope::Session(current_session_id)`.
The current session ID must be derivable from the call context (e.g., injected from
`RunnableConfig`). If no session context is available, `Err(E-MEMORY-004 NoScopeContext)`
is returned.

### EC-002: User-scoped entry readable across the same user's sessions
**Scenario:** User "alice" writes `MemoryScope::User("alice")` entry in session "s1".
User "alice" then starts session "s2". `memory_get(MemoryScope::User("alice"), key)`
from session "s2".
**Expected behavior:** Returns the entry (user scope persists across sessions for the
same user). Session "s2" does not see it under session scope, only under user scope.

### EC-003: App-scoped entry not visible in user-scope search
**Scenario:** An app-scoped entry exists with key "theme". `memory_search(
MemoryScope::User("alice"), "theme")` is called.
**Expected behavior:** The app-scoped entry does NOT appear in user-scope search
results. Search is strictly bounded by the provided scope.

### EC-004: Session-scoped entry from different session not visible
**Scenario:** Entry written in `MemoryScope::Session("s1")`. `memory_get(
MemoryScope::Session("s2"), key)` called.
**Expected behavior:** `None` returned. The session scope is a hard boundary.

### EC-005: Privileged admin query across all scopes (audit use case)
**Scenario:** An operator with admin access wants to enumerate all memory entries for
compliance audit, across all scopes for user "alice".
**Expected behavior:** The `MemoryStore` trait exposes an `admin_list_all(user_id)` fn
(or equivalent privileged API) that requires an explicit `AdminContext` parameter. This
function is not callable from a standard `RunnableConfig` context; it requires the server
operator's explicit privilege level.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Write `User("alice"), "key1", "a"`; `memory_get(User("bob"), "key1")` | `None` | User scope: alice's entry invisible to bob |
| TV-002 | Write `App("app1"), "theme", "dark"`; `memory_get(User("alice"), "theme")` | `None` | App-scoped entry not returned in user-scope read |
| TV-003 | Write `App("app1"), "theme", "dark"`; `memory_get(App("app1"), "theme")` as alice AND as bob | Both return `Some("dark")` | App scope is shared within same app |
| TV-004 | Write `Session("s1"), "tmp", "data"`; `memory_get(Session("s2"), "tmp")` | `None` | Session scope: s1 entry invisible to s2 |
| TV-005 | Write `User("alice"), "pref", "dark"` in session s1; `memory_get(User("alice"), "pref")` from session s2 | `Some("dark")` | User scope persists across sessions for same user |
| TV-006 | Write `Session("s1"), "tmp", "data"`; call `memory_delete_session("s1")`; `memory_get(Session("s1"), "tmp")` | `None` | Session cleanup deletes scoped entries |
| TV-007 | `memory_search(User("alice"), "dark")` when only app-scoped "dark" entries exist | Empty result | Scope-bounded search excludes app-scoped entries |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-MEM-03 | Storage-layer isolation: SQL query for User("alice") contains WHERE predicate; no post-filter | Unit test (assert generated SQL includes `WHERE scope = 'user' AND user_id = 'alice'`) | Post-v1 |
| VP-MEM-04 | User "bob" cannot read User("alice") entries via any standard API call | Integration test (cross-scope read attempt returns None, not alice's data) | Post-v1 |

## Related BCs

- BC-2.15.001 — depends on: KV and vector persistence semantics are the foundation this tier model governs
- BC-2.15.003 — depends on: GDPR erasure must delete across all three tiers per this contract's scope definitions
- BC-2.04.006 — related to: NE-12 tenancy partition principle is applied to checkpoint addressing in BC-2.04.006 and to memory scope addressing here

## Architecture Anchors

- `ferrochain-memory/src/store.rs` — `MemoryScope` enum and trait method signatures carrying scope parameter
- `ferrochain-memory/src/sqlite.rs` — SQL query builder ensuring `WHERE scope_key = ?` predicate on every read
- `ferrochain-memory/src/admin.rs` — privileged admin API requiring explicit `AdminContext`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-MEM-03, VP-MEM-04

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-017 |
| Capability Anchor Justification | CAP-017 ("Long-Horizon Cross-Session Memory Store (KV + Vector)") per capabilities-p1-p2.md §CAP-017 — "user-private, app-scoped, and session-scoped tiers" is verbatim text in the CAP-017 description; this BC specifies exactly that tier isolation contract |
| L2 Domain Invariants | — (NE-12 tenancy partition principle applied analogously: scope fields flow from method signature to storage WHERE clause without collapsing) |
| CONFLICT Reference | CONFLICT-7 — memory scope model: user/app/session partitioning + GDPR erasure (shapes the tier definitions in this contract) |
| Domain C Forcing Function | domain-c-openclaw.md §4 — "Session identity as an authorization boundary (not merely routing) for multi-user gateways" aligns with the scope-as-isolation-boundary principle |
| Priority | P2 |
| Wave | Wave 2 |
| Test Types | I (integration), U (unit/SQL assertion) |
| Module | ferrochain-memory |
