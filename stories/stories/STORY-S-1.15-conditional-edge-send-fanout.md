---
document_type: story
level: ops
story_id: S-1.15
epic_id: E-07
version: "1.4"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.005.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "ce75598"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.14]
blocks: [S-1.16, S-1.17]
behavioral_contracts: [BC-2.02.005, BC-2.02.006]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-02]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
changelog:
  - "1.3 (R46/R05-catch_unwind-SEC-008/2026-08-30): AC-002 extended with SEC-008 build-profile dependency note — std::panic::catch_unwind in pregolya-graph/src/bsp_engine.rs requires panic=\"unwind\" in workspace-root Cargo.toml [profile.release] (pregolya-server binary); library-member profile override is silently ignored by Cargo and MUST NOT be relied upon; panic=\"abort\" at workspace root voids the E-GRAPH-011 recovery path (CWE-248/703). Governing BC: BC-2.02.005."
  - "1.2 (P2-bc-completeness-burst-B/2026-08-26): BC-2.02.005 {INV-002}: AC-012 side-effecting path_fn executes (not sandboxed). {INV-005}/{EC-006}: AC-013 multi-edge End+NodeName live-node runs before terminus. BC table version bumped."
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors"
---

> **tdd_mode:** strict — full TDD Iron Law enforced.

> **Execute:** `/vsdd-factory:deliver-story S-1.15`

# S-1.15: Conditional Edges and Send API Dynamic Fan-Out

## Narrative

- **As a** graph runtime developer building the pregolya-graph BSP engine
- **I want to** support conditional routing via `add_conditional_edges(source, path_fn, path_map?)` and dynamic task fan-out via the Send API (`Send("worker", arg_i)` producing PUSH tasks onto the TASKS topic with deterministic task IDs)
- **So that** graph authors can branch execution based on state and dynamically spawn parallel subtasks within a super-step, enabling the full LangGraph-compatible routing surface

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.02.005 | Conditional Edge Routing Function | AC-001..AC-005, AC-012..AC-013 |
| BC-2.02.006 | Send API Dynamic Fan-Out | AC-006..AC-011 |

## Acceptance Criteria

### AC-001 (traces to BC-2.02.005 PC-001 — add_conditional_edges registers routing function)
`add_conditional_edges(source, path_fn)` registers a routing function that is called after `source` node completes; its return value selects the next node(s). Verified by `test_BC_2_02_005_conditional_edge_routes_correctly()`.

### AC-002 (traces to BC-2.02.005 PC-005 — path_fn panic caught and routed to error)
If `path_fn` panics, the panic is caught via `std::panic::catch_unwind`; the super-step returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-011, .. })` with `{ source_node, message }`. The graph does not propagate the panic. Verified by `test_BC_2_02_005_path_fn_panic_caught()`.

**Build-profile prerequisite (SEC-008) — `panic = "unwind"` required in the workspace-root release profile (pregolya-server binary):** This `std::panic::catch_unwind` recovery requires `panic = "unwind"` in the workspace-root `Cargo.toml` `[profile.release]` governing the `pregolya-server` binary. Cargo honors `[profile.release] panic` ONLY at the workspace root, applying it to the final binary at link time. A library-member `[profile.release] panic` override — including a `[profile.release] panic = "unwind"` line inside `pregolya-graph/Cargo.toml` or any other workspace-member manifest — is silently ignored by the Cargo linker and MUST NOT be relied upon as the SEC-008 gate. If the workspace-root release profile sets `panic = "abort"`, `std::panic::catch_unwind` in `pregolya-graph/src/bsp_engine.rs` is voided — the process aborts on panic instead of unwinding, bypassing the `E-GRAPH-011` recovery path and exposing a denial-of-service vector (CWE-248/703). This is a Phase-3 devops-engineer obligation (workspace-root `Cargo.toml` authoring; assert on the `pregolya-server` binary profile, NOT the `pregolya-graph` library-member profile). The implementing engineer MUST add a `// SEC-008: panic = "unwind" required in workspace-root release profile (pregolya-server) — library-member (pregolya-graph) profile override is inert (silently ignored by Cargo); std::panic::catch_unwind voids under abort` comment at the `std::panic::catch_unwind` dispatch site in `pregolya-graph/src/bsp_engine.rs` to document this workspace-root dependency. The devops-engineer asserts the workspace-root release profile at Phase-3 workspace init. Verified by devops-engineer at Phase-3; implementer obligation is the comment annotation. (See BC-2.02.005 SEC-008 obligation; mirrors S-1.19 AC-024 and S-2.11 AC-037 for the analogous fail-closed catch obligations on other paths.)

### AC-003 (traces to BC-2.02.005 PC-004 — path_map validates routing targets at compile time)
When `path_map` is provided, `compile()` validates that every value in `path_map` is a registered node name. If not, `compile()` returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-012, .. })`. Verified by `test_BC_2_02_005_path_map_validated_at_compile()`.

### AC-004 (traces to BC-2.02.005 INV-003 — unknown route returns error not panic)
If `path_fn` returns a node name not in the graph or not in `path_map`, the engine returns `Err(PregolyaError { category: GRAPH, code: E-GRAPH-003, .. })` rather than panicking. Verified by `test_BC_2_02_005_unknown_route_returns_error()`.

### AC-005 (traces to BC-2.02.005 INV-004 — multiple conditional edges on same source allowed)
Multiple `add_conditional_edges` calls with the same `source` node are cumulative — all routing functions run. Verified by `test_BC_2_02_005_multiple_conditional_edges_on_source()`.

### AC-006 (traces to BC-2.02.006 PC-001 — Send API produces PUSH tasks on TASKS topic)
`Send("worker", arg_i)` from within a node function produces a PUSH task entry on the TASKS topic. The PUSH task is not executed in the current super-step; it is queued for the next scheduling cycle. Verified by `test_BC_2_02_006_send_api_produces_push_tasks()`.

### AC-007 (traces to BC-2.02.006 PC-004 — task ID is deterministic xxh3_128 hash)
Each PUSH task's `task_id` is `xxh3_128(checkpoint_id ++ ns ++ step ++ node ++ "PUSH" ++ arg_hash)` encoded as a lowercase hex string. The same inputs always produce the same task_id. Verified by `test_BC_2_02_006_task_id_is_deterministic()`.

### AC-008 (traces to BC-2.02.006 PC-003 — fan-out tasks dispatched independently)
Multiple `Send(...)` calls in the same super-step produce multiple independent PUSH tasks, each with its own task_id. Tasks are dispatched independently — no implicit ordering between fan-out branches. Verified by `test_BC_2_02_006_fanout_tasks_independent()`.

### AC-009 (traces to BC-2.02.006 INV-004 — UntrackedValue sanitized before task argument serialization)
Any `UntrackedValue` in the `Send` argument is replaced with `None` (sanitized) before the argument is serialised into the PUSH task record. No `UntrackedValue` data crosses the task boundary. Verified by `test_BC_2_02_006_untracked_value_sanitized()`.

### AC-010 (traces to BC-2.02.006 INV-003 — crash recovery idempotent via task_id)
If a PUSH task crashes before completing, resubmitting the same `Send(...)` with the same inputs produces the same `task_id`, enabling at-least-once idempotent recovery via task deduplication. Verified by `test_BC_2_02_006_crash_recovery_idempotent()`.

### AC-011 (traces to BC-2.02.006 PC-001 — Send API available from within node async fn)
Node functions receive a context object with a `send` method; calling `ctx.send("target", value)` queues the PUSH task without blocking the current node. Verified by `test_BC_2_02_006_send_available_in_node_context()`.

### AC-012 (traces to BC-2.02.005 §{INV-002} — side-effecting path_fn executes; not sandboxed)
If `path_fn` performs I/O or mutates external state (e.g., increments an `Arc<AtomicU32>` counter), those operations ARE executed — the graph does NOT sandbox `path_fn`. The mutation is observable after the routing step completes. However, the mutation is NOT covered by the graph's checkpoint/rollback boundary: if the run is retried from a checkpoint, the external side effect is not rolled back. Callers who require transactional side effects must place them inside node functions, not routing functions. Verified by `test_BC_2_02_005_side_effecting_path_fn_executes()`.

### AC-013 (traces to BC-2.02.005 §{INV-005} and §{EC-006} — multi-edge End+NodeName: live node runs before terminus)
When two `add_conditional_edges` calls are registered for the same source node `"router"`, and in a given super-step path_fn-A returns `End` and path_fn-B returns `NodeName("cleanup")`: the scheduling union is `{End, "cleanup"}`. `"cleanup"` is scheduled and executes in the next super-step. `End` is added as a terminus marker but does NOT preempt `"cleanup"` from running. After `"cleanup"` completes with no further outgoing edges, the graph terminates with status `completed`. The caller does NOT observe an immediate halt after the `"router"` step. Verified by `test_BC_2_02_005_multi_edge_end_plus_nodename_cleanup_runs()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| Conditional edge registration | `pregolya-graph/src/definition.rs` | Pure (builder extension) |
| path_fn panic safety | `pregolya-graph/src/bsp_engine.rs` | Effectful (catch_unwind) |
| Send API / PUSH task queue | `pregolya-graph/src/scheduler.rs` | Effectful (TASKS topic write) |
| Task ID hash | `pregolya-graph/src/types.rs` | Pure (xxh3_128 deterministic) |
| UntrackedValue sanitization | `pregolya-graph/src/types.rs` | Pure |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `definition.rs` (conditional edge builder) | pure-core | Registers routing functions; no I/O |
| `types.rs` (task_id hash, UntrackedValue sanitize) | pure-core | Deterministic hash + data transformation |
| `bsp_engine.rs` (path_fn dispatch with catch_unwind) | effectful-shell | catch_unwind is a side-effecting runtime safety mechanism |
| `scheduler.rs` (PUSH task queue, TASKS topic) | effectful-shell | Writes to task queue (I/O) |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | `path_fn` panics with a non-Send type | `catch_unwind` catches it; `E-GRAPH-011` returned; run does not abort |
| EC-002 | `path_fn` returns node name not in graph | `E-GRAPH-003` returned; not a panic |
| EC-003 | `path_map` contains unmapped return values from `path_fn` | `E-GRAPH-012` at compile time for nodes not registered |
| EC-004 | Zero `Send()` calls in a super-step | No PUSH tasks queued; normal super-step completion |
| EC-005 | `Send("nonexistent_node", arg)` | Error at dispatch time: target node not found; `E-GRAPH-003` |
| EC-006 | `Send` arg contains nested `UntrackedValue` | Sanitized recursively before serialization |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,000 |
| BC files (2 BCs) | ~3,500 |
| S-1.14 context (channels, types, state) | ~1,500 |
| `scheduler.rs` stub (new) | ~800 |
| Test files | ~2,500 |
| Architecture module-decomposition.md (SS-02) | ~600 |
| **Total** | **~11,900** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~6.0%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for all 11 ACs in `pregolya-graph/tests/conditional_send_fanout.rs`
2. [ ] Extend `pregolya-graph/src/definition.rs` — `add_conditional_edges(source, path_fn, path_map?)`
3. [ ] Add path_fn panic safety to `pregolya-graph/src/bsp_engine.rs` using `catch_unwind`
4. [ ] Add path_map compile-time validation in `compile()`
5. [ ] Create `pregolya-graph/src/scheduler.rs` — PUSH task queue, TASKS topic (S-1.15 is the owner and creator of this file)
6. [ ] Add `task_id` hash function to `pregolya-graph/src/types.rs` — xxh3_128 with canonical key components
7. [ ] Add `UntrackedValue` sanitization in `types.rs`
8. [ ] Add `ctx.send(target, value)` to node execution context
9. [ ] Write failing test `test_BC_2_02_005_side_effecting_path_fn_executes()` for AC-012 (test-writer)
10. [ ] Write failing test `test_BC_2_02_005_multi_edge_end_plus_nodename_cleanup_runs()` for AC-013 (test-writer)
11. [ ] Run `cargo nextest run -p pregolya-graph --no-fail-fast` — all tests green

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.14 | `StateGraph::builder()` + `compile()` pattern; `WriteRecord` sort; channel materialisation at compile | `mod.rs` re-export only; no `HashMap` for reduce ordering | `pregolya-graph/src/bsp_engine.rs` is partially owned by S-1.14 and S-1.16 — coordinate changes |

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `std::panic::catch_unwind` only for path_fn dispatch — not elsewhere | BC-2.02.005; CLAUDE.md forbids panics in production paths | Code review |
| Task ID computation is pure and deterministic — same inputs = same hash | BC-2.02.006 PC-004; BSP determinism requirement | Unit test: `test_BC_2_02_006_task_id_is_deterministic()` |
| `UntrackedValue` must be sanitized before task arg serialization | BC-2.02.006 INV-004 | Unit test: `test_BC_2_02_006_untracked_value_sanitized()` |
| No `unwrap()` / `expect()` in non-test code | CLAUDE.md §No unwrap / expect | `cargo clippy -D clippy::unwrap_used` |
| `#[non_exhaustive]` on all public enums/structs | CLAUDE.md §`#[non_exhaustive]` | Non-exhaustive gate crate |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `xxhash-rust` | workspace-pinned | xxh3_128 deterministic task ID hashing |
| `tokio` | workspace-pinned | Async node execution context |
| `serde` | workspace-pinned | Task argument serialization before PUSH |
| `tracing` | workspace-pinned | Structured events for conditional routing and fan-out |

**Forbidden Dependencies:** Same as S-1.14 — no dependency on `pregolya-openai`, `pregolya-anthropic`, `pregolya-ollama`.

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-graph/src/definition.rs` | modify | Add `add_conditional_edges(source, path_fn, path_map?)` |
| `pregolya-graph/src/bsp_engine.rs` | modify | Add `catch_unwind` around path_fn dispatch; `E-GRAPH-011` error |
| `pregolya-graph/src/scheduler.rs` | create | PUSH task queue, TASKS topic, `ctx.send()` — S-1.15 creates this file (scheduler.rs skeleton) |
| `pregolya-graph/src/types.rs` | modify | Add `task_id` hash fn, `UntrackedValue`, `PushTask` struct |
| `pregolya-graph/tests/conditional_send_fanout.rs` | create | AC-001..AC-011 tests |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.4 | 2026-09-02 | round-79/F-P2A251-02: BC table title cells corrected to verbatim canonical H1 per POL-7/F-P2A251-02. | round-79 F-P2A251-02 |
