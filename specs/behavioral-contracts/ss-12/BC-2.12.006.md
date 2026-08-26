---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.006
version: "1.6"
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
timestamp: 2026-08-23T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-server per module-decomposition.md v1.10."
  - "1.2 (F-P117-01, fix burst 120, 2026-07-19): PC7 — add summary_halt to the enumerated transition set (RunStore must persist all lifecycle transitions including the budget-summarize terminal state per BC-2.10.003 PC8(d) and BC-2.12.003 PC8 post-fix)."
  - "1.3 (burst-226/F-P131-03/2026-07-21): Assign canonical event_type 'server.rate_limit_store_in_memory' to EC-005 startup WARN emission per observability census (SAP-1). EC-005 and Invariants updated."
  - "1.4 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.27 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (P2A-BC-scan-B/2026-08-26): (1) EC-001 fixed — ADR-028 Decision 5 TTL-from-submission propagation: replaced ambiguous 'TTL-on-completion OR TTL-from-submission, implementation must document which' with authoritative TTL-from-submission (24h clock starts at submission time, not completion time). Operator responsibility note added (TTL MUST exceed expected max Run duration; concurrent-run risk from TTL expiry during long run documented). ADR-028 D5 cited. (2) EC-006 added — API rate-limit 429 → E-SERVER-021 ApiRateLimitExceeded (RATE/429/Later). Closes gap: PC-004 declared 429 but no error code was specified. Note: error-taxonomy minted E-SERVER-021 with anchor BC-2.12.006 EC-002; EC-002 is occupied (idempotency race); authoritative raise site is EC-006 per ADR-027 append-only numbering."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/platform/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
input-hash: "85e4c28"
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

`pregolya-server` must not hard-wire in-memory data structures for idempotency,
rate limiting, or run state storage. These three concerns are exposed as traits
(`IdempotencyStore`, `RateLimitStore`, `RunStore`) with a pluggable backend seam.
The default in-memory implementation uses LRU eviction with TTL for idempotency and
rate-limit buckets, and a non-evicting in-memory map for run state. Durable backends
(SQLite, Postgres) are first-class alternatives configurable at startup without
changing any server logic. This contract is the direct correction of the adk-rust
counter-example (P-43): hard-wired `RwLock<HashMap>` with no persistence seam and no
eviction.

## Preconditions

1. {PRE-001} `pregolya-server` is initialized with an explicit or default store configuration.
2. {PRE-002} For idempotency: an HTTP request includes `Idempotency-Key: <key>` in headers.
3. {PRE-003} For rate limiting: an HTTP request arrives from a caller with a known `caller_id`.
4. {PRE-004} For run state: a `Run` is created and its lifecycle state transitions are stored.

## Postconditions

**IdempotencyStore:**
1. {PC-001} A request with `Idempotency-Key: "k1"` that completes successfully caches its
   response payload; a second identical request with the same key returns the cached
   response without re-executing the Run, within the TTL window.
2. {PC-002} After the idempotency TTL expires, the key is evicted; the next request with the
   same key executes a new Run.
3. {PC-003} In-memory default uses an LRU cache with bounded capacity and TTL (default:
   capacity 10,000 entries, TTL 24 hours). At capacity, the least-recently-used entry
   is evicted regardless of TTL.

**RateLimitStore:**
4. {PC-004} Each caller's request count is tracked per time window. Exceeding the configured
   rate limit returns `429 Too Many Requests` with a `Retry-After: <seconds>` header.
5. {PC-005} In-memory default uses a token-bucket per `caller_id` with LRU eviction when the
   bucket map exceeds capacity (default: 10,000 callers).
6. {PC-006} A durable `RateLimitStore` backend (e.g., Redis or Postgres) enables rate limiting
   to be enforced consistently across multiple server instances.

**RunStore:**
7. {PC-007} Every `Run` state transition (queued, in_progress, interrupted, completed,
   failed, cancelled, summary_halt) is written to the `RunStore` before the HTTP response
   is returned to the caller.
8. {PC-008} `GET /threads/{thread_id}/runs/{run_id}` reads directly from the `RunStore`; no in-memory copy is
   consulted separately.
9. {PC-009} Swapping the `RunStore` backend from in-memory to SQLite (via config) requires
   no code change to the server's route handlers or business logic.

**Trait seam:**
10. {PC-010} All three stores are accessed only through their trait interfaces (`IdempotencyStore`,
    `RateLimitStore`, `RunStore`). No route handler references a concrete store type.
    This is verifiable by the absence of any concrete store type in `pregolya-server`
    route handler modules.

## Invariants

- {INV-001} `IdempotencyStore` entries are immutable after creation: the same `Idempotency-Key`
  always returns the same cached response during its TTL window; no in-place updates
  are permitted.
- {INV-002} `RunStore` writes are synchronous (consistent with DI-002's sync-default durability
  tier for task outputs); a `RunStore` write failure propagates as `Err(E-SERVER-014
  RunStoreFailed)`, not a silent state corruption.
- {INV-003} The in-memory default `RunStore` is explicitly documented as non-durable: a process
  restart loses all Run records. Operators requiring durability must configure a
  persistent backend.
- {INV-004} The in-memory `RateLimitStore` emits `event_type = "server.rate_limit_store_in_memory"` at server startup as an operator signal to configure a distributed backend for multi-instance deployments.

## Edge Cases

### EC-001: Idempotency TTL and long-running operations (ADR-028 Decision 5: TTL-from-submission) {EC-001}
**TTL basis:** The idempotency TTL clock starts **at submission time** — when the first request carrying `Idempotency-Key: <key>` arrives and the key is registered in the `IdempotencyStore`. It does NOT start at Run completion time (ADR-028 Decision 5).

**Externally-observable behavior:**
- Re-submission within the 24h window → returns the cached response (same `run_id`, same output). No new Run is created. The cached response may be returned even while the original Run is still `in_progress`.
- Re-submission after the 24h window → key expired; request treated as new; a new Run is created with a new `run_id`.

**Operator responsibility:** The idempotency TTL MUST be configured to exceed the expected maximum Run duration. If a Run takes longer than the TTL (e.g., TTL = 5 minutes, Run takes 30 minutes), the key expires during execution. A re-submission at minute 6 starts a NEW Run concurrently with the still-running original Run — this is an operator misconfiguration. Pregolya does NOT guard against this at the framework layer in v1. This constraint MUST be documented in the `IdempotencyStore` configuration reference.

**Scenario (original):** Operator reduces TTL to 5 minutes; Run completes at minute 6; re-submission of `"k1"` at minute 7.
**Expected behavior:** Starts a new Run (key expired during execution). The behavior is deterministic and correctly predicted by TTL-from-submission semantics — the caller knows they submitted at T=0 and the window closes at T=5m.

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
**Scenario:** Two `pregolya-server` instances share no state; both have in-memory
`RateLimitStore`; a caller sends requests to both.
**Expected behavior:** Each instance enforces the rate limit independently. The
in-memory default is documented as not suitable for multi-instance rate limiting.
A `WARN` log is emitted at startup if no distributed `RateLimitStore` is configured, with `event_type = "server.rate_limit_store_in_memory"` and structured field `{ backend: "in_memory" }`: `"RateLimitStore: in-memory backend — rate limits are not coordinated across instances"`.

### EC-006: API rate limit exceeded → E-SERVER-021 (LOW gap closure) {EC-006}
**Scenario:** A caller exceeds the server's configured API throughput rate limit (global or per-tenant request-per-second cap) — distinct from the per-thread run queue bound (E-SERVER-019).
**Expected behavior:** HTTP 429 `{ code: "E-SERVER-021", message: "ApiRateLimitExceeded: request rate limit exceeded; retry after <retry_after_ms>ms" }` with `Retry-After: <seconds>` header. The `RateLimitStore` tracks per-caller request counts; the `retry_after_ms` field communicates the back-off horizon until the rate window resets. Error code: E-SERVER-021 ApiRateLimitExceeded (RATE, broken, RetryHint Later — RATE category default; HTTP 429). **Note:** error-taxonomy minted E-SERVER-021 with anchor BC-2.12.006 EC-002; EC-002 is occupied (idempotency concurrent-request race); authoritative raise site is EC-006 per ADR-027 append-only numbering.

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

- `pregolya-server/src/store/idempotency_store.rs` — `IdempotencyStore` trait and in-memory LRU implementation
- `pregolya-server/src/store/rate_limit_store.rs` — `RateLimitStore` trait and in-memory token-bucket implementation
- `pregolya-server/src/store/run_store.rs` — `RunStore` trait and SQLite / in-memory implementations
- `pregolya-server/src/routes/` — route handlers using only trait references (no concrete store imports)

## Story Anchor

S-1.27

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
| Module | pregolya-server |
