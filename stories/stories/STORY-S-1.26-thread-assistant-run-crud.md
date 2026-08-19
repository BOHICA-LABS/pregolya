---
document_type: story
level: L4
story_id: S-1.26
epic_id: EPIC-1
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "ef3968d"
traces_to:
  - behavioral-contracts/BC-2.12.001
  - behavioral-contracts/BC-2.12.002
  - behavioral-contracts/BC-2.12.003
points: 8
depends_on: [S-1.16, S-1.10, S-1.04]
blocks: [S-1.27]
behavioral_contracts: [BC-2.12.001, BC-2.12.002, BC-2.12.003]
verification_properties: []
priority: P1
cycle: 1
wave: 1
target_module: pregolya-server
subsystems: [SS-12]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: N/A — BCs authored (BC-2.12.001 v1.4, BC-2.12.002 v1.6, BC-2.12.003 v1.6)
---

# STORY-S-1.26: Thread, Assistant, and Run CRUD REST Endpoints

## Narrative

As an API consumer, I want Thread, Assistant, and Run CRUD endpoints so that I can programmatically create and manage conversation threads, register assistant configurations with versioned snapshots, and submit graph runs with a full lifecycle state machine from `queued` through terminal states.

## Token Budget Estimate

| Context Component | Estimated Tokens |
|-------------------|-----------------|
| This story spec | ~5,000 |
| BC files (3 BCs: BC-2.12.001–003) | ~11,000 |
| Architecture module-decomposition.md | ~3,000 |
| Target source files (pregolya-server/src/routes/) | ~12,000 |
| Test files | ~12,000 |
| S-1.16 (BSP super-step determinism) route scaffolding | ~2,000 |
| **Total estimate** | **~45,000** |

Comfortable within context window. No split required.

## Behavioral Contracts

| BC ID | Title | Version | Red Gate? |
|-------|-------|---------|-----------|
| BC-2.12.001 | Thread CRUD — create, get, list, delete with cascade-delete | v1.4 | No |
| BC-2.12.002 | Assistant CRUD — immutable version snapshots, configurable map | v1.6 | No |
| BC-2.12.003 | Run lifecycle — 9-arc state machine, Run-Config Merge | v1.6 | No |

## Acceptance Criteria

### AC-001: Thread POST — creates thread and returns 201
`POST /threads` creates a new thread with a generated `thread_id` and returns HTTP 201 with the thread object. Duplicate `thread_id` (if caller provides one) returns `E-SERVER-007` (ThreadAlreadyExists).
(traces to BC-2.12.001 postcondition 1)

### AC-002: Thread GET/LIST — returns thread(s), clamped limit
`GET /threads/:id` returns the thread or `E-SERVER-003` (ThreadNotFound). `GET /threads?limit=N` returns up to min(N, 100) threads sorted by `created_at DESC`. Default limit is 10.
(traces to BC-2.12.001 postcondition 2)

### AC-003: Thread DELETE — cascade-deletes checkpoint
`DELETE /threads/:id` deletes the thread and cascade-deletes any associated checkpoint data. Returns `E-SERVER-003` if thread not found. Returns `E-SERVER-008` (ThreadStateConflict) if a run is currently active on the thread.
(traces to BC-2.12.001 postcondition 3)

### AC-004: Assistant POST — creates versioned snapshot
`POST /assistants` creates an assistant at `version = 1`. Each subsequent `PATCH /assistants/:id` creates a new immutable version snapshot. Versions list (`GET /assistants/:id/versions`) is ordered `version ASC` (exemption from canonical `created_at DESC`).
(traces to BC-2.12.002 postcondition 1)

### AC-005: Assistant configurable map — key collision: run wins at leaf
When merging run-provided `configurable` with assistant-stored `configurable`, run values win at leaf level over assistant-stored values (fine-grained per-key merge, not whole-map replacement). Returns `E-SERVER-009` (AssistantNotFound), `E-SERVER-010` (AssistantVersionNotFound), `E-SERVER-011` (AssistantConfigConflict) on error.
(traces to BC-2.12.002 postcondition 2)

### AC-006: Run POST — enqueues with queued state
`POST /threads/:id/runs` creates a run with initial state `queued`. Returns `E-SERVER-002` (RunNotFound) on GET for non-existent run. Returns `E-SERVER-012` (ConcurrentRun) if another run is already active on the same thread.
(traces to BC-2.12.003 postcondition 1)

### AC-007: Run state machine — 9-arc transitions
The run state machine supports these arcs: `queued → in_progress`, `in_progress → completed`, `in_progress → failed`, `in_progress → interrupted`, `in_progress → cancelled`, `in_progress → summary_halt`, `interrupted → in_progress` (resume), `interrupted → cancelled`. No other state transitions are valid.
(traces to BC-2.12.003 postcondition 2)

### AC-008: summary_halt is terminal, output populated, directly deletable
`summary_halt` is a terminal state. A run in `summary_halt` has its `output` field populated. The run can be deleted directly (no prior cancel required). `summary_halt` is distinct from `failed`.
(traces to BC-2.12.003 postcondition 3)

### AC-009: Run-Config Merge Precedence — run wins over assistant at leaf level
When creating a run, merge precedence for `configurable`: run-provided values win over assistant-stored values at each leaf key. This is the same leaf-level merge rule as AC-005, applied at run creation time.
(traces to BC-2.12.003 postcondition 4)

### AC-010: interrupted → cancelled arc exists
A run in `interrupted` state (awaiting HITL approval) can be transitioned to `cancelled` without going through `in_progress`. `DELETE /threads/:id/runs/:run_id` or a cancel API call on an `interrupted` run results in `cancelled` state.
(traces to BC-2.12.003 invariant 1)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `ThreadRoutes` | `pregolya_server::routes::threads` | pregolya-server | Effectful (HTTP + store) |
| `AssistantRoutes` | `pregolya_server::routes::assistants` | pregolya-server | Effectful (HTTP + store) |
| `RunRoutes` | `pregolya_server::routes::runs` | pregolya-server | Effectful (HTTP + store) |
| `RunState` enum | `pregolya_server::models::run` | pregolya-server | Pure (state machine enum) |
| `ThreadStore` trait | `pregolya_server::store::thread` | pregolya-server | Pure (trait) |
| `AssistantStore` trait | `pregolya_server::store::assistant` | pregolya-server | Pure (trait) |
| `RunStore` trait | `pregolya_server::store::run` | pregolya-server | Pure (trait) |

**Subsystem anchor:** SS-12 owns this story's scope because SS-12 is the Server subsystem per ARCH-INDEX Subsystem Registry. Thread/Assistant/Run CRUD endpoints form the REST API surface managed by SS-12. The store trait seams (ThreadStore, AssistantStore, RunStore) are SS-12 abstractions that decouple route handlers from concrete persistence.

**Dependency anchors:**
- Depends on S-1.16: BSP super-step machinery (S-1.16) provides the run execution engine. S-1.26 adds the HTTP route layer on top.
- Depends on S-1.10: `CheckpointSaver` trait used for cascade-delete of thread checkpoint data.
- Depends on S-1.04: `DynTool` / `Runnable` trait is invoked by run execution, surfaced via run routes.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `RunState` | Pure | Enum; transition logic is pure |
| `validate_state_transition(from, to)` | Pure | Returns Ok/Err based on valid arc set |
| Thread/Assistant/Run route handlers | Effectful | HTTP I/O + store operations |
| `configurable_merge(run, assistant)` | Pure | Leaf-level map merge |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.12.001 EC-1 | Duplicate thread_id on POST | `E-SERVER-007` |
| EC-002 | BC-2.12.001 EC-2 | DELETE thread with active run | `E-SERVER-008` |
| EC-003 | BC-2.12.001 EC-3 | GET /threads?limit=150 | Clamped to 100 |
| EC-004 | BC-2.12.001 EC-4 | GET /threads (default) | Limit 10, created_at DESC |
| EC-005 | BC-2.12.002 EC-1 | PATCH non-existent assistant | `E-SERVER-009` |
| EC-006 | BC-2.12.002 EC-2 | Versions list ordering | `version ASC` (not created_at DESC) |
| EC-007 | BC-2.12.003 EC-1 | POST run on thread with active run | `E-SERVER-012` |
| EC-008 | BC-2.12.003 EC-2 | Transition to invalid state | `E-SERVER-...` state conflict |
| EC-009 | BC-2.12.003 EC-3 | summary_halt run DELETE | Allowed directly (no cancel required) |
| EC-010 | BC-2.12.003 EC-4 | interrupted → cancelled | Valid arc; run moves to cancelled |

## Tasks

- [ ] Create `crates/pregolya-server/src/routes/threads.rs` — Thread CRUD routes
- [ ] Create `crates/pregolya-server/src/routes/assistants.rs` — Assistant CRUD + versions routes
- [ ] Create `crates/pregolya-server/src/routes/runs.rs` — Run CRUD + state machine routes
- [ ] Create `crates/pregolya-server/src/models/run.rs` — `RunState` enum, `Run` struct
- [ ] Create `crates/pregolya-server/src/models/thread.rs` — `Thread` struct
- [ ] Create `crates/pregolya-server/src/models/assistant.rs` — `Assistant`, `AssistantVersion` structs
- [ ] Create `crates/pregolya-server/src/store/thread.rs` — `ThreadStore` trait
- [ ] Create `crates/pregolya-server/src/store/assistant.rs` — `AssistantStore` trait
- [ ] Write failing tests for AC-001..AC-010 before any implementation
- [ ] Implement `validate_state_transition` — 9-arc validation (including `interrupted → cancelled`)
- [ ] Implement `configurable_merge` — leaf-level map merge, run wins
- [ ] Implement Thread routes: POST, GET, LIST (limit clamp), DELETE (cascade)
- [ ] Implement Assistant routes: POST, GET, PATCH (new version), versions list (ASC)
- [ ] Implement Run routes: POST (queued), GET, state transition, DELETE
- [ ] Run `just iter pregolya-server` — all tests green

## Previous Story Intelligence

**From S-1.16 (BSP Super-Step Determinism):**
- The run execution engine is built in S-1.16. S-1.26 adds the HTTP API layer that triggers and monitors runs. The run state machine in S-1.26 must align with the BSP execution states.

**From S-1.10 (Checkpoint Core):**
- Thread cascade-delete calls `CheckpointSaver::delete` or equivalent to remove checkpoint data when a thread is deleted.

**N/A for prior server story.** S-1.26 is the first server CRUD story.

## Architecture Compliance Rules

1. **Route handlers must not depend on concrete store implementations.** Thread/Assistant/Run route handlers use `Arc<dyn ThreadStore>`, `Arc<dyn AssistantStore>`, `Arc<dyn RunStore>` — never concrete types. This is VP-STORE-01 (no concrete store in route handlers).
2. **`interrupted → cancelled` arc is load-bearing.** The 9-arc state machine was updated in BC-2.12.003 v1.6 to add this arc. The transition validator must include it.
3. **Versions list is `version ASC` (not `created_at DESC`).** The assistant versions endpoint is the documented exemption from the canonical created_at DESC ordering.
4. **Leaf-level merge, not whole-map replacement.** `configurable_merge` performs per-key override at leaf level. A run providing `{ "model": "gpt-4" }` must not erase other assistant keys not present in the run config.
5. **`summary_halt` is terminal and directly deletable.** Do not require a cancel step before deleting a `summary_halt` run.
6. **No `unwrap()` / `expect()` in production code.**
7. **`#[non_exhaustive]`** on `RunState` enum (public API surface).
8. **`mod.rs` re-export only** in all route and store modules.

## Library & Framework Requirements

| Library | Version | Feature Flags | License | Usage |
|---------|---------|--------------|---------|-------|
| `axum` | (workspace pin) | — | MIT | HTTP routing and handlers |
| `serde` | (workspace pin) | `derive` | MIT/Apache | Request/response serialization |
| `serde_json` | (workspace pin) | — | MIT/Apache | JSON body handling |
| `uuid` | (workspace pin) | `v4, serde` | MIT/Apache | `thread_id`, `run_id`, `assistant_id` |
| `tokio` | (workspace pin) | `full` | MIT | Async handlers |
| `tracing` | (workspace pin) | default | MIT | Structured logging |
| `pregolya-core` | (workspace) | — | — | `PregolyaError`, error codes |

## File Structure Requirements

```
crates/pregolya-server/
  src/
    routes/
      mod.rs                         # re-export only
      threads.rs                     # Thread CRUD route handlers
      assistants.rs                  # Assistant CRUD + versions route handlers
      runs.rs                        # Run CRUD + lifecycle route handlers
    models/
      mod.rs                         # re-export only
      thread.rs                      # Thread struct
      assistant.rs                   # Assistant, AssistantVersion structs
      run.rs                         # Run struct, RunState enum (#[non_exhaustive])
    store/
      mod.rs                         # re-export only
      thread.rs                      # ThreadStore trait (Arc<dyn ThreadStore>)
      assistant.rs                   # AssistantStore trait
      run.rs                         # RunStore trait
  tests/
    thread_routes_tests.rs           # CRUD tests, cascade-delete, limit clamp
    assistant_routes_tests.rs        # versions list ASC, configurable merge
    run_lifecycle_tests.rs           # 9-arc state machine, interrupted→cancelled
```

**Files to create (new):** all routes/, models/, store/ files.
**Files to modify (existing):** `pregolya-server/src/lib.rs` (register routes), `Cargo.toml` (add axum if not present).
