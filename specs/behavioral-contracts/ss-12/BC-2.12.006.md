---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.006
version: "1.2"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-12
capability: CAP-014
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-server per module-decomposition.md v1.10."
  - "1.2 (F-P117-01, fix burst 120, 2026-07-19): PC7 — add summary_halt to the enumerated transition set (RunStore must persist all lifecycle transitions including the budget-summarize terminal state per BC-2.10.003 PC8(d) and BC-2.12.003 PC8 post-fix)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/platform/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
input-hash: "8997318"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.006: IdempotencyStore / RateLimitStore / RunStore Trait Seams with Durable Backends (NE-08)

## Description

`ferrochain-server` must not hard-wire in-memory data structures for idempotency,
rate limiting, or run state storage. These three concerns are exposed as traits
(`IdempotencyStore`, `RateLimitStore`, `RunStore`) with a pluggable backend seam.
The default in-memory implementation uses LRU eviction with TTL for idempotency and
rate-limit buckets, and a non-evicting in-memory map for run state. Durable backends
(SQLite, Postgres) are first-class alternatives configurable at startup without
changing any server logic. This contract is the direct correction of the adk-rust
counter-example (P-43): hard-wired `RwLock<HashMap>` with no persistence seam and no
eviction.

## Preconditions

1. `ferrochain-server` is initialized with an explicit or default store configuration.
2. For idempotency: an HTTP request includes `Idempotency-Key: <key>` in headers.
3. For rate limiting: an HTTP request arrives from a caller with a known `caller_id`.
4. For run state: a `Run` is created and its lifecycle state transitions are stored.

## Postconditions

**IdempotencyStore:**
1. A request with `Idempotency-Key: "k1"` that completes successfully caches its
   response payload; a second identical request with the same key returns the cached
   response without re-executing the Run, within the TTL window.
2. After the idempotency TTL expires, the key is evicted; the next request with the
   same key executes a new Run.
3. In-memory default uses an LRU cache with bounded capacity and TTL (default:
   capacity 10,000 entries, TTL 24 hours). At capacity, the least-recently-used entry
   is evicted regardless of TTL.

**RateLimitStore:**
4. Each caller's request count is tracked per time window. Exceeding the configured
   rate limit returns `429 Too Many Requests` with a `Retry-After: <seconds>` header.
5. In-memory default uses a token-bucket per `caller_id` with LRU eviction when the
   bucket map exceeds capacity (default: 10,000 callers).
6. A durable `RateLimitStore` backend (e.g., Redis or Postgres) enables rate limiting
   to be enforced consistently across multiple server instances.

**RunStore:**
7. Every `Run` state transition (queued, in_progress, interrupted, completed,
   failed, cancelled, summary_halt) is written to the `RunStore` before the HTTP response
   is returned to the caller.
8. `GET /threads/{thread_id}/runs/{run_id}` reads directly from the `RunStore`; no in-memory copy is
   consulted separately.
9. Swapping the `RunStore` backend from in-memory to SQLite (via config) requires
   no code change to the server's route handlers or business logic.

**Trait seam:**
10. All three stores are accessed only through their trait interfaces (`IdempotencyStore`,
    `RateLimitStore`, `RunStore`). No route handler references a concrete store type.
    This is verifiable by the absence of any concrete store type in `ferrochain-server`
    route handler modules.

## Invariants

- `IdempotencyStore` entries are immutable after creation: the same `Idempotency-Key`
  always returns the same cached response during its TTL window; no in-place updates
  are permitted.
- `RunStore` writes are synchronous (consistent with DI-002's sync-default durability
  tier for task outputs); a `RunStore` write failure propagates as `Err(E-SERVER-014
  RunStoreFailed)`, not a silent state corruption.
- The in-memory default `RunStore` is explicitly documented as non-durable: a process
  restart loses all Run records. Operators requiring durability must configure a
  persistent backend.

## Edge Cases

### EC-001: Idempotency TTL expires during a long-running operation
**Scenario:** `Idempotency-Key: "k1"` is submitted; the Run takes 30 minutes;
the idempotency TTL is 24 hours; no expiry issue. But the operator reduces TTL to
5 minutes: the Run completes at minute 6; the response is cached but immediately
discarded (TTL expired during execution).
**Expected behavior:** A re-submission of `"k1"` at minute 7 starts a new Run (no
cached response available). This is the correct behavior — TTL-on-completion semantics
are acceptable; TTL-from-submission is also acceptable; the implementation must
document which is used.

### EC-002: Concurrent duplicate requests with the same idempotency key (race)
**Scenario:** Two identical requests with `Idempotency-Key: "k2"` arrive simultaneously
before either has been processed.
**Expected behavior:** One request proceeds to Run execution; the other acquires a
per-key lock and waits for at most `IdempotencyStore::lock_timeout` (default: 30 seconds,
matching the DI-009/NFR-009 connection timeout value, configurable). Within the timeout
window it receives the cached response. If the lock_timeout expires before the first
request completes, the waiting request returns HTTP 503 with
`E-SERVER-016 IdempotencyLockTimeout`. The `IdempotencyStore` must provide a per-key
lock or serialization mechanism for in-flight deduplication; the lock must be bounded.

### EC-003: RateLimitStore LRU eviction of active callers
**Scenario:** The in-memory `RateLimitStore` is at capacity (10,000 callers); a new
caller triggers eviction of an existing caller's bucket.
**Expected behavior:** The evicted caller's rate counter resets; subsequent requests
from that caller are treated as a fresh window. This is documented as expected behavior
of the in-memory default (not a bug). Operators needing accurate cross-restart rate
limiting must use a durable backend.

### EC-004: RunStore write failure mid-transition
**Scenario:** `Run.status` transitions from `in_progress` to `completed`; the `RunStore`
backend returns a durability error.
**Expected behavior:** `Err(E-SERVER-014 RunStoreFailed { run_id, transition:
"in_progress→completed", backend_error: <reason> })` is returned; the caller receives
a `500 Internal Server Error`. The Run is not silently left in `in_progress` state —
the error is surfaced.

### EC-005: Rate limit across multiple server instances with in-memory backend
**Scenario:** Two `ferrochain-server` instances share no state; both have in-memory
`RateLimitStore`; a caller sends requests to both.
**Expected behavior:** Each instance enforces the rate limit independently. The
in-memory default is documented as not suitable for multi-instance rate limiting.
A `WARN` log is emitted at startup if no distributed `RateLimitStore` is configured:
`"RateLimitStore: in-memory backend — rate limits are not coordinated across instances"`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `POST /threads/t1/runs` with `Idempotency-Key: "key1"`; Run completes; `POST /threads/t1/runs` again with same key and body | Second request returns `200 OK` with identical response body; no new Run created; `run_id` is the same | Idempotency happy path |
| TV-002 | `POST /threads/t1/runs` 101 times from `caller_id: "alice"` within 1 second (limit: 100/s) | 101st request returns `429 Too Many Requests` with `Retry-After: 1` header | Rate limit enforcement |
| TV-003 | Configure in-memory `RunStore`; create 3 Runs; restart server; `GET /threads/t1/runs/{run_id}` | `404 Not Found` (in-memory not durable) | In-memory RunStore is non-persistent |
| TV-004 | Configure SQLite `RunStore`; create 3 Runs; restart server; `GET /threads/t1/runs/{run_id}` | `200 OK` with Run details (durable across restart) | SQLite RunStore is durable |
| TV-005 | Swap `RunStore` backend from in-memory to SQLite via config only; verify all route handler tests pass | All tests pass with no code change to handlers | Trait seam: backend swap is config-only |
| TV-006 | `RunStore` write fails (injected fault); Run transitions to `completed` | `500 Internal Server Error`, `E-SERVER-014 RunStoreFailed` propagated | Storage error surfaces correctly |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-STORE-01 | No concrete store type appears in route handler modules; only trait references | Static analysis (grep for concrete store type in `routes/`) | Phase 1 |
| VP-STORE-02 | SQLite `RunStore` backend preserves Run state across process restart | Integration test (create Runs, kill server, restart, assert state) | Phase 1 |

## Related BCs

- BC-2.12.003 — depends on: Run lifecycle that RunStore must track
- BC-2.12.004 — depends on: CronSchedule-fired Runs are tracked in RunStore
- BC-2.04.001 — related to: per-task `put_writes` durability (checkpoint layer) complements RunStore durability (server layer)

## Architecture Anchors

- `ferrochain-server/src/store/idempotency_store.rs` — `IdempotencyStore` trait and in-memory LRU implementation
- `ferrochain-server/src/store/rate_limit_store.rs` — `RateLimitStore` trait and in-memory token-bucket implementation
- `ferrochain-server/src/store/run_store.rs` — `RunStore` trait and SQLite / in-memory implementations
- `ferrochain-server/src/routes/` — route handlers using only trait references (no concrete store imports)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-STORE-01, VP-STORE-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — durable Run state is a core named deliverable of the server capability; the trait seam for RunStore, IdempotencyStore, and RateLimitStore is the implementation contract that makes "Durable-Run" first-class rather than hard-wired in-memory |
| L2 Domain Invariants | — (no DI directly; NE-08 is the relevant counter-example requirement) |
| NE Reference | NE-08 — P-43 REJECT: hard-wired in-memory idempotency map + rate-limit buckets + run state with no durability seam is the adk-rust counter-example |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-server |
