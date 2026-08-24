---
document_type: story
level: ops
story_id: S-1.27
epic_id: E-14
version: "1.1"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors; 13 mis-anchors corrected (AC-001 PC1→INV-001, AC-002 PC2→INV-003, AC-003 PC3→PC-007, AC-004 PC4→EC-004, AC-005 BC5.PC1→INV-001, AC-006 BC5.PC2→PC-007, AC-007 BC5.PC3→INV-003, AC-008 BC6.PC1→PC-003, AC-009 BC6.PC2→INV-004, AC-010 BC6.PC3→PC-009, AC-011 BC7.PC1→INV-001, AC-012 BC7.PC2→PC-002, AC-013 BC7.PC3→INV-002)"
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.005.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.006.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.007.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "35c9361"
traces_to:
  - behavioral-contracts/BC-2.12.004
  - behavioral-contracts/BC-2.12.005
  - behavioral-contracts/BC-2.12.006
  - behavioral-contracts/BC-2.12.007
points: 8
depends_on: [S-1.26]
blocks: []
behavioral_contracts: [BC-2.12.004, BC-2.12.005, BC-2.12.006, BC-2.12.007]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-server
subsystems: [SS-12]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: N/A — BCs authored (BC-2.12.004, BC-2.12.005, BC-2.12.006, BC-2.12.007)
---

# STORY-S-1.27: CronSchedule, SecurityConfig, Store Seams, and SSE Streaming

## Narrative

As a platform operator and API consumer, I want CronSchedule support for automated agent runs, a secure-by-default `SecurityConfig` (CORS denied, debug route gated), pluggable store trait seams for idempotency/rate-limit/run storage, and SSE streaming that uses the same graph engine as unary execution, so that the server is production-hardened and deployable without additional configuration changes.

## Token Budget Estimate

| Context Component | Estimated Tokens |
|-------------------|-----------------|
| This story spec | ~5,000 |
| BC files (4 BCs: BC-2.12.004–007) | ~13,000 |
| Architecture module-decomposition.md | ~3,000 |
| Target source files (pregolya-server/src/) | ~14,000 |
| Test files | ~12,000 |
| S-1.26 (Thread/Run CRUD) store interface | ~3,000 |
| **Total estimate** | **~50,000** |

Comfortable within context window. No split required.

## Behavioral Contracts

| BC ID | Title | Red Gate? |
|-------|-------|-----------|
| BC-2.12.004 | CronSchedule — fresh isolated session per firing, skip missed-fire policy | No |
| BC-2.12.005 | SecurityConfig::default — CORS denied, debug route gated (DI-013) | No |
| BC-2.12.006 | Store trait seams — IdempotencyStore, RateLimitStore, RunStore | No |
| BC-2.12.007 | SSE streaming — same engine as unary (DI-011); 5 event types | No |

## Acceptance Criteria

### AC-001: CronSchedule — each firing creates a fresh isolated thread
Each cron schedule firing creates a new `thread_id` for the session. Sessions from different firings are independent — they do not share thread state, checkpoints, or message history.
(traces to BC-2.12.004 INV-001)

### AC-002: CronSchedule — missed firings are skipped (no accumulation)
If the server was down during scheduled firing times, missed firings are not replayed or accumulated. The skip policy fires at most once on the next check interval regardless of how many firings were missed.
(traces to BC-2.12.004 INV-003)

### AC-003: CronSchedule — cross-thread aggregate query by schedule_id
`GET /runs?schedule_id=<id>` returns all runs across threads that were created by the named schedule. The schedule_id is stored on each run created by the cron scheduler.
(traces to BC-2.12.004 PC-007)

### AC-004: CronSchedule — queue-full warning event
When the cron scheduler's internal queue is full and a firing is dropped, the server emits a tracing event with `event_type = "server.cron_schedule_queue_full"`. Returns `E-CRON-001` (CronParseError), `E-CRON-002` (CronScheduleNotFound), `E-CRON-003` (CronScheduleConflict) on appropriate errors.
(traces to BC-2.12.004 EC-004)

### AC-005: SecurityConfig::default — CORS denied (empty allowed_origins)
`SecurityConfig::default()` configures CORS with an empty `allowed_origins` list. All cross-origin requests are denied. This is the DI-013 secure-by-default invariant.
(traces to BC-2.12.005 INV-001)

### AC-006: SecurityConfig::default — debug route gated by key
The `/_debug` route is disabled unless `debug_route_key: Some("non-empty-string")` is provided. An empty string `debug_route_key: Some("")` is rejected at startup with an error. Returns `E-SERVER-004` (DebugRouteUnauthorized) when key is missing; `E-SERVER-013` (InvalidDebugRouteKey) when key format is invalid.
(traces to BC-2.12.005 PC-007)

### AC-007: CORS wildcard allowed but emits startup WARN
`SecurityConfig` with CORS wildcard (`allowed_origins: ["*"]`) is a valid configuration but emits a startup tracing warning with `event_type = "server.security_config_cors_wildcard"`. The WARN is emitted once at server startup, not per-request.
(traces to BC-2.12.005 INV-003)

### AC-008: IdempotencyStore — LRU + TTL cache; in-memory default
`IdempotencyStore` trait is implemented by an in-memory LRU + TTL cache as the default. The trait seam allows injection of a persistent backend for production deployments (SID-1 compliance: unit tests use the in-memory implementation directly).
(traces to BC-2.12.006 PC-003)

### AC-009: RateLimitStore — token-bucket algorithm; in-memory default emits startup WARN
`RateLimitStore` trait uses a token-bucket algorithm. The default in-memory implementation emits a startup tracing warning with `event_type = "server.rate_limit_store_in_memory"` indicating it is not durable across restarts. Returns `E-SERVER-014` (RunStoreFailed) on store failure.
(traces to BC-2.12.006 INV-004)

### AC-010: RunStore — SQLite durable default + in-memory option
`RunStore` trait has two implementations: in-memory (non-durable, test use) and SQLite (durable across restarts). The SQLite implementation satisfies VP-STORE-02 (run state survives process restart). Route handlers use `Arc<dyn RunStore>` — never the concrete type.
(traces to BC-2.12.006 PC-009)

### AC-011: SSE streaming uses same CompiledGraph engine as unary execution (DI-011)
The SSE endpoint (`GET /threads/:id/runs/:run_id/stream`) invokes the same `CompiledGraph::run` execution path as the unary `POST /threads/:id/runs/:run_id/execute`. There is no separate streaming engine. This corrects NE-13.
(traces to BC-2.12.007 INV-001)

### AC-012: SSE event types — run_start, node_start, node_stream, node_end, run_end
SSE events emitted during a run: `run_start`, `node_start`, `node_stream` (NOT `node_delta` — that name is retired), `node_end`, `run_end`. `run_end` is ONLY emitted on successful completion. Failed or interrupted runs do NOT emit `run_end`.
(traces to BC-2.12.007 PC-002)

### AC-013: Concurrent execution on same run_id returns E-SERVER-015
If a second SSE or unary execution request arrives for a `run_id` that is already executing, returns `E-SERVER-015` (RunAlreadyExecuting). Only one execution per `run_id` at a time.
(traces to BC-2.12.007 INV-002)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `CronScheduler` | `pregolya_server::cron` | pregolya-server | Effectful (timer + thread creation) |
| `SecurityConfig` | `pregolya_server::security` | pregolya-server | Pure (configuration struct) |
| `IdempotencyStore` trait | `pregolya_server::store::idempotency` | pregolya-server | Pure (trait) |
| `RateLimitStore` trait | `pregolya_server::store::rate_limit` | pregolya-server | Pure (trait) |
| `SseRoutes` | `pregolya_server::streaming` | pregolya-server | Effectful (SSE stream + engine) |
| `InMemoryRunStore` | `pregolya_server::store::run_memory` | pregolya-server | Effectful (in-memory state) |
| `SqliteRunStore` | `pregolya_server::store::run_sqlite` | pregolya-server | Effectful (SQLite I/O) |

**Subsystem anchor:** SS-12 owns this story's scope because SS-12 is the Server subsystem per ARCH-INDEX Subsystem Registry. CronSchedule, SecurityConfig, store trait seams, and SSE streaming are all server-layer concerns within SS-12. The SSE stream shares the CompiledGraph engine (SS-05/SS-10) but the HTTP layer and event marshaling are SS-12 responsibilities.

**Dependency anchor:**
- Depends on S-1.26: Thread, Assistant, Run store traits and models are established in S-1.26. S-1.27 adds CronSchedule (which creates threads + runs), SecurityConfig (server-level), store seam completions, and SSE routing.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `SecurityConfig::default` | Pure | Returns a config struct; no I/O |
| `SecurityConfig::validate` | Pure | Rejects empty debug key; no I/O |
| `CronSchedule::parse` | Pure | Parses cron expression; returns E-CRON-001 on parse error |
| `CronScheduler::fire` | Effectful | Creates thread + run; schedules next firing |
| `SseRoutes::stream_run` | Effectful | Runs CompiledGraph, emits SSE events |
| `InMemoryRunStore` operations | Effectful | Mutates in-memory map |
| `SqliteRunStore` operations | Effectful | SQLite I/O |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.12.004 EC-1 | Server down during 3 scheduled firings | Skip 3; fire once at next check interval |
| EC-002 | BC-2.12.004 EC-2 | Invalid cron expression | `E-CRON-001` |
| EC-003 | BC-2.12.004 EC-3 | Cron queue full | Firing dropped; emit `event_type = "server.cron_schedule_queue_full"` |
| EC-004 | BC-2.12.005 EC-1 | `SecurityConfig::default()` | `allowed_origins: []`, `debug_route_key: None` |
| EC-005 | BC-2.12.005 EC-2 | CORS wildcard configured | Startup WARN with `event_type = "server.security_config_cors_wildcard"` |
| EC-006 | BC-2.12.005 EC-3 | `debug_route_key: Some("")` | Rejected at startup; error |
| EC-007 | BC-2.12.006 EC-1 | In-memory RateLimitStore used | Startup WARN with `event_type = "server.rate_limit_store_in_memory"` |
| EC-008 | BC-2.12.006 EC-2 | RunStore fails | `E-SERVER-014` |
| EC-009 | BC-2.12.007 EC-1 | Second SSE request for same run_id | `E-SERVER-015` (RunAlreadyExecuting) |
| EC-010 | BC-2.12.007 EC-2 | Run fails mid-stream | `run_end` NOT emitted; SSE stream closes with error event |
| EC-011 | BC-2.12.007 EC-3 | `node_delta` event name used anywhere | Forbidden — event name is `node_stream` (NE-13 correction) |

## Tasks

- [ ] Create `crates/pregolya-server/src/cron/schedule.rs` — `CronSchedule`, `CronScheduler`, skip policy; create `crates/pregolya-server/src/cron/mod.rs` as re-export-only (`pub mod schedule; pub use schedule::{CronSchedule, CronScheduler};`)
- [ ] Create `crates/pregolya-server/src/security.rs` — `SecurityConfig`, validate on startup (flat; no `config/` subdir)
- [ ] Create `crates/pregolya-server/src/store/idempotency.rs` — `IdempotencyStore` trait + in-memory impl
- [ ] Create `crates/pregolya-server/src/store/rate_limit.rs` — `RateLimitStore` trait + in-memory impl
- [ ] Create `crates/pregolya-server/src/store/run_memory.rs` — `InMemoryRunStore`
- [ ] Create `crates/pregolya-server/src/store/run_sqlite.rs` — `SqliteRunStore`
- [ ] Create `crates/pregolya-server/src/streaming.rs` — SSE streaming endpoint (flat; no `routes/` subdir)
- [ ] Write failing tests for AC-001..AC-013 before any implementation
- [ ] Implement `SecurityConfig::default()` — empty allowed_origins, no debug key
- [ ] Implement `SecurityConfig::validate()` — reject `debug_route_key: Some("")`
- [ ] Implement CORS wildcard startup WARN with canonical event_type
- [ ] Implement in-memory RateLimitStore with startup WARN
- [ ] Implement `SqliteRunStore` — durable across restart (VP-STORE-02)
- [ ] Implement `SseRoutes::stream_run` — same `CompiledGraph::run` as unary
- [ ] Verify `node_stream` event name (grep codebase for `node_delta` — must be zero occurrences)
- [ ] Implement cron skip policy — no missed-fire accumulation
- [ ] Add `event_type = "server.cron_schedule_queue_full"` to Canonical Structured Event Catalog
- [ ] Add `event_type = "server.security_config_cors_wildcard"` to Catalog
- [ ] Add `event_type = "server.rate_limit_store_in_memory"` to Catalog
- [ ] Run `just iter pregolya-server` — all tests green

## Previous Story Intelligence

**From S-1.26 (Thread/Assistant/Run CRUD):**
- `Arc<dyn RunStore>` is the canonical injection pattern for run storage in route handlers. `SseRoutes` must accept `Arc<dyn RunStore>` in its constructor — NOT the concrete `InMemoryRunStore`.
- `RunState` enum and `E-SERVER-NNN` error codes established in S-1.26 are reused here (especially `E-SERVER-015` for RunAlreadyExecuting, which is a new code defined in S-1.27 scope).
- `configurable_merge` leaf-level merge (S-1.26) must be applied when CronSchedule fires and creates a run from the assistant's stored config.

## Architecture Compliance Rules

1. **SSE and unary use the same CompiledGraph engine.** No separate streaming engine. Both call `CompiledGraph::run`. This is the DI-011 / NE-13 correction — any code creating a separate "streaming executor" is a behavioral defect.
2. **`node_stream` is the canonical event name.** `node_delta` is retired. Zero occurrences of `node_delta` are acceptable after this story. The final Task item above enforces this via grep.
3. **`run_end` on completion only.** Do not emit `run_end` on failed or interrupted runs. The SSE stream closes without `run_end` on non-completion paths.
4. **SecurityConfig defaults are secure.** `SecurityConfig::default()` must have `allowed_origins: vec![]` and `debug_route_key: None`. Any default that opens CORS or enables debug route is a DI-013 violation.
5. **Empty `debug_route_key` rejected at startup.** The rejection must happen at server startup (configuration validation), not at first request to `/_debug`.
6. **All three event_type values registered in Canonical Structured Event Catalog.** SAP-1 applies: `server.cron_schedule_queue_full`, `server.security_config_cors_wildcard`, `server.rate_limit_store_in_memory` must have catalog rows before PR merges.
7. **Route handlers use `Arc<dyn Store>` — never concrete store types.** VP-STORE-01 applies to all route handlers in this story.
8. **No `unwrap()` / `expect()` in production code.**
9. **`mod.rs` re-export only** in all modules.
10. **`#[non_exhaustive]`** on `CronSchedule`, `SecurityConfig` (public API surface types).

## Library & Framework Requirements

| Library | Version | Feature Flags | License | Usage |
|---------|---------|--------------|---------|-------|
| `axum` | (workspace pin) | `headers` feature for SSE | MIT | HTTP routing + SSE response |
| `tokio-stream` | (workspace pin) | — | MIT | SSE event stream |
| `cron` or `cron_parser` | (workspace if present; research needed) | — | MIT/Apache | Cron expression parsing; E-CRON-001 on parse failure |
| `rusqlite` | (workspace pin) | `bundled` | MIT | SQLite for `SqliteRunStore` |
| `serde` | (workspace pin) | `derive` | MIT/Apache | JSON serialization |
| `tracing` | (workspace pin) | default | MIT | Structured logging + startup WARNs |
| `pregolya-core` | (workspace) | — | — | `PregolyaError`, error codes |

**Note on cron library:** If no cron library is pinned in the workspace dependency table, use `cron = "0.12"` (MIT, widely used). Do NOT invent a version; if uncertain, flag for research-agent lookup.

## File Structure Requirements

```
crates/pregolya-server/
  src/
    cron/
      mod.rs                         # re-export only
      schedule.rs                    # CronSchedule, CronScheduler, skip policy
    security.rs                      # SecurityConfig (#[non_exhaustive]) — flat; no config/ subdir (server::security, DI-013)
    store/
      idempotency.rs                 # IdempotencyStore trait + InMemoryIdempotencyStore
      rate_limit.rs                  # RateLimitStore trait + InMemoryRateLimitStore (token-bucket)
      run_memory.rs                  # InMemoryRunStore
      run_sqlite.rs                  # SqliteRunStore (durable)
    streaming.rs                     # SSE streaming endpoint (same CompiledGraph engine) — flat; no routes/ subdir (server::streaming, DI-011)
  tests/
    cron_tests.rs                    # firing isolation, skip policy, queue-full WARN
    security_config_tests.rs         # defaults, CORS wildcard WARN, empty debug key rejection
    store_tests.rs                   # idempotency LRU+TTL, rate limit token-bucket, run store durability
    sse_streaming_tests.rs           # event types, node_stream name, run_end on completion only
```

**Files to create (new):** all cron/ files, `security.rs` (flat), new store/ files, and `streaming.rs` (flat).
**Files to modify (existing):** `pregolya-server/src/lib.rs` (register new routes, store construction), `pregolya-server/Cargo.toml` (add cron, rusqlite if not present), Canonical Structured Event Catalog (3 new event_type rows).
