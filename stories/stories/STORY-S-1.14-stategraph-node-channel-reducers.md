---
document_type: story
level: ops
story_id: S-1.14
epic_id: E-07
version: "1.4"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.002.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.003.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.004.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "86b4511"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.04, S-1.01]
blocks: [S-1.13, S-1.15, S-1.16, S-1.17, S-1.18, S-1.19, S-2.11]
behavioral_contracts: [BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.004]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-02]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
changelog:
  - "1.4 (round-21/F-P2A093-01/2026-08-28): AC-014 gate updated from bare `#[cfg(test)]` to `#[cfg(any(test, feature = \"test-util\"))]`; stub_terminal is now exposed via pregolya-graph `test-util` feature (dev-only) for cross-crate VP-016 harness; helper remains non-public-API. Task-18 updated to include `[features] test-util = []` in pregolya-graph/Cargo.toml. Library Requirements serde_json row and File Structure types.rs row updated to feature-gated form. Sibling sweep: all five live-body bare-`#[cfg(test)]` stub_terminal references replaced."
  - "1.3 (round-10/stub_terminal/2026-08-27): AC-014 + Task 18 added — CompiledStateGraph::stub_terminal #[cfg(test)] helper (BC-2.02.001 PC-001); consumed by VP-016 (BC-2.09.008 {INV-001}) in S-2.11. blocks updated to include S-2.11. BC-2.02.001 covered-ACs updated AC-001..AC-013 → AC-001..AC-014. serde_json added to Library Requirements. File Structure extended with #[cfg(test)] impl row."
  - "1.2 (P2-bc-completeness-burst-B/2026-08-26): BC-2.02.001 {PC-007}: AC-012 Command goto+update full semantics; AC-013 Command null-field variants. BC table version bumped."
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors"
---

> **tdd_mode:** strict — full TDD Iron Law enforced. Two Red Gate BCs (BC-2.02.003, BC-2.02.004) require tests to be written first and must fail before any implementation exists.

> **Execute:** `/vsdd-factory:deliver-story S-1.14`

# S-1.14: StateGraph Node, Channel, and Reducer Foundation

## Narrative

- **As a** graph runtime developer building the pregolya-graph BSP engine
- **I want to** define a `StateGraph` with typed channels (LastValue, Append, BarrierValue, NamedBarrierValue, EphemeralValue), register nodes that write to those channels via task-identity-sorted reducers, and compile the graph into a runnable `CompiledStateGraph`
- **So that** the BSP engine can execute deterministic super-steps with correct channel semantics and downstream stories (S-1.15, S-1.16, S-1.20) have a stable channel-and-reducer foundation to build on

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.02.001 | StateGraph Builder API — Node and Channel Registration | AC-001..AC-003, AC-012..AC-014 |
| BC-2.02.002 | Channel Semantics — LastValue, Append, BarrierValue | AC-004..AC-007 |
| BC-2.02.003 | NamedBarrierValue Missing-Writer Boundary Behavior (Red Gate) | AC-008, AC-011 |
| BC-2.02.004 | EphemeralValue Cleared After Each Super-Step (Red Gate) | AC-009..AC-010 |

## Acceptance Criteria

### AC-001 (traces to BC-2.02.001 PC-001 — builder accepts valid node and channel registration)
`StateGraph::builder()` followed by `add_node(name, async_fn)` and channel schema registration compiles and does not error for a valid graph. Verified by `test_BC_2_02_001_builder_accepts_valid_graph()`.

### AC-002 (traces to BC-2.02.001 INV-002 — compile errors on invalid graph; add_node errors on duplicate name)
`compile()` returns `Err(PregolyaError { category: VAL, code: E-GRAPH-008, .. })` when the graph has no reachable path from `START` (no entry edge or zero nodes). `add_node()` returns `Err(PregolyaError { category: VAL, code: E-GRAPH-009, .. })` when a node name is already registered. Writing to an unregistered channel key returns `Err(PregolyaError { category: VAL, code: E-GRAPH-007, .. })` at runtime from `invoke`/`stream` at the `apply_writes` stage — this is NOT a compile-time error. Verified by `test_BC_2_02_001_compile_rejects_invalid_graphs()`.

### AC-003 (traces to BC-2.02.001 PC-002 — channels materialised at compile time)
All channels declared in the state schema are materialised before the first super-step begins; no channel is created lazily during execution. Verified by `test_BC_2_02_001_channels_materialised_at_compile()`.

### AC-004 (traces to BC-2.02.002 PC-001 — LastValue retains most-recent write)
A `LastValue<T>` channel retains only the value written in the current super-step. Verified by `test_BC_2_02_002_last_value_retains_most_recent()`.

### AC-005 (traces to BC-2.02.002 PC-003 — concurrent LastValue writes rejected)
When two tasks in the same super-step both write to the same `LastValue<T>` channel, the engine returns `Err(PregolyaError { category: CONCURRENCY, code: E-GRAPH-001, .. })` with fields `{ channel, task_ids, step }`. Verified by `test_BC_2_02_002_last_value_concurrent_write_rejected()`.

### AC-006 (traces to BC-2.02.002 PC-004 — Append channel accumulates in deterministic order)
An `Append`/`BinaryOperatorAggregate<T,Op>` channel accumulates every write from the current super-step. Values are ordered by `(task_id, channel_name)` lexicographic ascending via sorted `Vec<WriteRecord { task_id, channel_name, value }>` before reduction — not via unordered `HashMap` iteration. Verified by `test_BC_2_02_002_append_channel_deterministic_order()`.

### AC-007 (traces to BC-2.02.002 PC-007 — BarrierValue unavailable until all writers complete; no error on missing write)
A `BarrierValue` channel becomes `available()` only after all registered upstream writers have each delivered exactly one write in the current super-step. If any expected writer fails to deliver in that step, the channel is NOT available; the downstream node is NOT triggered; no error is raised. If no other nodes are triggered, the graph halts naturally (run transitions to `completed`). Verified by `test_BC_2_02_002_barrier_value_blocks_until_all_writers()`.

### AC-008 (traces to BC-2.02.003 PC-001 / PC-002 / PC-003 — NamedBarrierValue missing-writer causes silent non-trigger, no error; RED GATE)
When a `NamedBarrierValue` channel has a declared writer that does not deliver a write in the current super-step, the channel's `is_available()` returns `false`; the downstream node is NOT triggered; no error is raised; the run does NOT transition to `failed`. This test MUST be written before any implementation and MUST fail on stubs before the feature is implemented (Red Gate discipline, BC-2.02.003 — the default stub behavior is likely to raise an error or fail to implement the no-trigger contract). Verified by `test_BC_2_02_003_named_barrier_missing_writer_no_trigger()`.

### AC-009 (traces to BC-2.02.004 PC-002 — EphemeralValue absent from checkpoint; RED GATE)
An `EphemeralValue<T>` channel's value is not written to the checkpoint and is absent at the start of the next super-step. This test MUST be written before any implementation and MUST fail on stubs (Red Gate discipline, BC-2.02.004). Verified by `test_BC_2_02_004_ephemeral_value_absent_after_step()`.

### AC-010 (traces to BC-2.02.004 PC-004 — EphemeralValue absent from checkpoint snapshot)
A checkpoint snapshot of graph state taken after a super-step that wrote an `EphemeralValue<T>` contains no key for that channel. Verified by `test_BC_2_02_004_ephemeral_value_not_in_checkpoint()`.

### AC-011 (traces to BC-2.02.003 EC-003 — NamedBarrierValue duplicate writer raises E-GRAPH-004)
When a declared writer of a `NamedBarrierValue` channel writes twice in the same super-step (e.g., two `Send` tasks bearing the same writer name both deliver to the channel in that step), the engine returns `Err(PregolyaError { category: VAL, code: E-GRAPH-004, .. })` with fields `{ channel, writer, step }`. Verified by `test_BC_2_02_003_named_barrier_duplicate_writer_error()`.

### AC-012 (traces to BC-2.02.001 §{PC-007} — Command with goto + update: update applied then routing override)
When a node function returns `Command { goto: Some("target"), update: Some(update_dict) }`, the Pregel executor: (a) applies `update_dict` to the graph state channels subject to channel reducer semantics (LastValue / BinaryOperatorAggregate) and the unregistered-key guard (INV-001 — any unregistered key returns `Err(E-GRAPH-007)`); (b) schedules `"target"` in the next super-step, bypassing any static or conditional edges declared for this source node. When `"target"` eventually reaches `END`, `invoke` returns `Ok(output_state)`. Verified by `test_BC_2_02_001_command_goto_and_update_applied()`.

### AC-013 (traces to BC-2.02.001 §{PC-007} — Command null-field variants preserve correct routing)
`Command { goto: None, update: Some(dict) }`: state update is applied; static/conditional edges for the current node take effect normally (no routing override). `Command { goto: Some("target"), update: None }`: schedules `"target"` without applying any state update for this step. `Command { goto: None, update: None }`: semantically equivalent to returning `None` — no state mutation, normal edge routing. All three variants eventually return `Ok(output_state)` when the run reaches `END`. Verified by `test_BC_2_02_001_command_null_field_variants()`.

### AC-014 (traces to BC-2.02.001 PC-001 — stub_terminal test helper; consumed by VP-016 in S-2.11)
`CompiledStateGraph::stub_terminal(terminal_state: serde_json::Value) -> Arc<CompiledStateGraph>`
is gated `#[cfg(any(test, feature = "test-util"))]` and exposed as a `pub fn` on
`CompiledStateGraph` (implemented in `pregolya-graph/src/types.rs`). It constructs a minimal
single-node terminal graph whose `invoke` returns `terminal_state` verbatim as its output —
NO LLM calls, NO checkpointing, NO channel reduction. This helper enables the VP-016 proptest
harness `graph_agent_tool_state_isolation` (STATE-ISOLATION invariant, anchored in S-2.11) to
exercise `GraphAgentTool::invoke_dyn` against a realistic `CompiledStateGraph` without a live
graph executor. The helper is gated `#[cfg(any(test, feature = "test-util"))]`, exposed via
pregolya-graph's `test-util` feature (dev-only) — this gate makes it reachable cross-crate
from pregolya-mcp's `[dev-dependencies]` VP-016 test harness. It is NOT part of the public API
surface; it is a test-util helper only, not a user-facing method.
Points impact: none — a single test-util feature-gated helper does not re-point this story (8 pts
unchanged). Verified by `test_BC_2_02_001_stub_terminal_constructs_minimal_graph()`: call
`stub_terminal(json!({"answer": "ok"}))`, invoke with `json!({})`, assert result equals
`json!({"answer": "ok"})` verbatim.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| StateGraph builder | `pregolya-graph/src/definition.rs` | Pure (builder, no I/O) |
| LastValue channel | `pregolya-graph/src/channels/last_value.rs` | Pure (data + reduce logic) |
| Append/BinaryOperator channel | `pregolya-graph/src/channels/append.rs` | Pure |
| BarrierValue channel | `pregolya-graph/src/channels/barrier.rs` | Pure |
| NamedBarrierValue channel | `pregolya-graph/src/channels/named_barrier.rs` | Pure |
| EphemeralValue channel | `pregolya-graph/src/channels/ephemeral.rs` | Pure |
| BSP reduce phase | `pregolya-graph/src/bsp_engine.rs` | Effectful (owns reduce + finish) |
| WriteRecord sort | `pregolya-graph/src/types.rs` | Pure |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `channels/` (all five channel types) | pure-core | No I/O; deterministic data transformation with immutable inputs |
| `definition.rs` (builder + compile) | pure-core | Validation and construction; no side effects |
| `types.rs` (WriteRecord, ChannelKind) | pure-core | Data types only |
| `bsp_engine.rs` (reduce_super_step, finish) | effectful-shell | Calls checkpoint write (I/O) in finish(); pure reduce logic extracted for Kani harness in S-1.16 |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Node writes to unregistered channel key at runtime | `invoke`/`stream` returns `E-GRAPH-007 UnknownChannelKey { node_id, key }` at the `apply_writes` stage; not a compile-time error |
| EC-002 | Two tasks write same `LastValue` channel in one super-step | `E-GRAPH-001 { channel, task_ids, step }` — deterministic error, not UB |
| EC-003 | `NamedBarrierValue` writer list is empty | Treated as immediately ready; no blocking, no error |
| EC-004 | `EphemeralValue` read before any write in current super-step | Returns `None`; no panic; no `unwrap` |
| EC-005 | `compile()` called on graph with zero nodes | `E-GRAPH-008 { .. }` — zero nodes means no reachable path from `START` (UnreachableGraph) |
| EC-006 | Append channel receives zero writes in super-step | Channel retains prior accumulated value; no error |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,500 |
| BC files (4 BCs) | ~6,000 |
| `channels/` module stubs (5 files) | ~1,500 |
| `definition.rs` stub | ~800 |
| `bsp_engine.rs` partial (reduce only) | ~1,200 |
| Test files (unit + Red Gate) | ~3,000 |
| Error taxonomy reference | ~500 |
| Architecture module-decomposition.md (SS-02 section) | ~600 |
| **Total** | **~17,100** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~8.6%** |

## Tasks (MANDATORY)

1. [ ] Write Red Gate failing test for `test_BC_2_02_003_named_barrier_missing_writer_no_trigger()` — verify it fails on stubs (stub must not implement the is_available()=false / no-trigger / no-error contract)
2. [ ] Write Red Gate failing test for `test_BC_2_02_004_ephemeral_value_absent_after_step()` — verify it fails on stubs
3. [ ] Write full AC test suite in `pregolya-graph/tests/channel_semantics.rs`
4. [ ] Create `pregolya-graph/src/channels/mod.rs` (re-export only)
5. [ ] Create `pregolya-graph/src/channels/last_value.rs` — `LastValue<T>` with concurrent-write detection
6. [ ] Create `pregolya-graph/src/channels/append.rs` — `BinaryOperatorAggregate<T,Op>` + `WriteRecord` sort
7. [ ] Create `pregolya-graph/src/channels/barrier.rs` — `BarrierValue`
8. [ ] Create `pregolya-graph/src/channels/named_barrier.rs` — `NamedBarrierValue` (declared writers)
9. [ ] Create `pregolya-graph/src/channels/ephemeral.rs` — `EphemeralValue<T>` (not in checkpoint)
10. [ ] Create `pregolya-graph/src/definition.rs` — `StateGraph::builder()` + `compile()` (flat layout; no `graph/` subdir)
11. [ ] Create `pregolya-graph/src/types.rs` — `WriteRecord`, `CompiledStateGraph`, `ChannelKind`
12. [ ] Register `graph.channel.reduced` in Canonical Structured Event Catalog (SAP-1)
13. [ ] Verify `#[non_exhaustive]` on all public enums and structs in channels and types
14. [ ] Run `cargo nextest run -p pregolya-graph --no-fail-fast` — all tests green
15. [ ] Write test for `test_BC_2_02_003_named_barrier_duplicate_writer_error()` — covers AC-011 (E-GRAPH-004 DuplicateBarrierWrite; BC-2.02.003 EC-003); add to `pregolya-graph/tests/channel_semantics.rs`
16. [ ] Write failing test `test_BC_2_02_001_command_goto_and_update_applied()` for AC-012 (test-writer)
17. [ ] Write failing test `test_BC_2_02_001_command_null_field_variants()` for AC-013 (test-writer)
18. [ ] Implement `CompiledStateGraph::stub_terminal(terminal_state: serde_json::Value) -> Arc<CompiledStateGraph>` gated `#[cfg(any(test, feature = "test-util"))]` as a `pub fn` in `pregolya-graph/src/types.rs` — single-node terminal graph that returns `terminal_state` verbatim from `invoke`; no LLM calls, no checkpointing. Also add `[features]\ntest-util = []\n` to `pregolya-graph/Cargo.toml` so the feature can be activated by dev-dependents (e.g., pregolya-mcp's `[dev-dependencies]` entry). Write test `test_BC_2_02_001_stub_terminal_constructs_minimal_graph()` confirming `invoke(json!({}), config)` returns the terminal state verbatim (AC-014 / BC-2.02.001 PC-001; consumed by VP-016 harness in S-2.11)

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.01 | Workspace init, `pregolya-graph` crate created as member | `Cargo.toml` members list is authoritative | Verify `pregolya-graph/src/lib.rs` exists before adding modules |
| S-1.04 | `PregolyaError` struct with category + code fields; error taxonomy `E-GRAPH-*` codes | All errors use `?` propagation, never `unwrap` | `E-GRAPH-001` through `E-GRAPH-009` must be in the taxonomy before use |

N/A — S-1.14 is the first `pregolya-graph` story that writes channel logic. The two predecessor stories (S-1.01, S-1.04) are workspace/core stories.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `mod.rs` files re-export only — no logic | CLAUDE.md §File size & module splitting | Code review; `mod.rs` must contain only `pub use` declarations |
| No `HashMap` iteration for reduce ordering — use sorted `Vec<WriteRecord>` | BC-2.02.002 PC-004; BSP determinism requirement | Unit test: `test_BC_2_02_002_append_channel_deterministic_order()` verifies sort key |
| `#[non_exhaustive]` on all public API surface types | CLAUDE.md §`#[non_exhaustive]` on public API surface types | Non-exhaustive gate crate compile-fail test |
| No `unwrap()` / `expect()` in non-test code | CLAUDE.md §No unwrap / expect in non-test code | `cargo clippy -D clippy::unwrap_used` |
| Production file ≤ 500 code-lines soft target; ≤ 750 hard gate | CLAUDE.md §File size & module splitting | `cargo xtask check-file-size` CI gate |
| `pregolya-graph` must NOT depend on `pregolya-openai`, `pregolya-anthropic`, `pregolya-ollama` | architecture/dependency-graph.md | `cargo deny` configuration |
| `EphemeralValue` is not serialized to checkpoint | BC-2.02.004 INV-001 | `bsp_engine.rs finish()` must exclude ephemeral channels from checkpoint snapshot |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `tokio` | workspace-pinned | Async runtime; channel reduce is sync but node fns are async |
| `serde` | workspace-pinned | Channel state serialization for checkpoint (all channel types except EphemeralValue) |
| `uuid` | workspace-pinned | `ingress_id` and `task_id` UUIDs for `WriteRecord` |
| `tracing` | workspace-pinned | Structured event emission — `graph.channel.reduced` |
| `serde_json` | workspace-pinned | `serde_json::Value` in `CompiledStateGraph::invoke` (BC-2.02.001 PC-005) and `stub_terminal` test-util helper (AC-014) |

Exact versions are pinned in the workspace root `Cargo.toml`. Consult `.factory/stories/dependency-graph.md` external dependency table for confirmed pins. Do not introduce new dependencies without architect approval.

**Forbidden Dependencies:** `pregolya-graph` must NOT depend on `pregolya-openai`, `pregolya-anthropic`, or `pregolya-ollama`.

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-graph/src/channels/mod.rs` | create | Re-export only — `pub use` of all five channel types |
| `pregolya-graph/src/channels/last_value.rs` | create | `LastValue<T>` with concurrent-write detection |
| `pregolya-graph/src/channels/append.rs` | create | `BinaryOperatorAggregate<T,Op>`, `WriteRecord`, deterministic sort |
| `pregolya-graph/src/channels/barrier.rs` | create | `BarrierValue` (all-writers-required) |
| `pregolya-graph/src/channels/named_barrier.rs` | create | `NamedBarrierValue` with declared-writers list |
| `pregolya-graph/src/channels/ephemeral.rs` | create | `EphemeralValue<T>` — cleared in `bsp_engine.finish()`, not in checkpoint |
| `pregolya-graph/src/definition.rs` | create | `StateGraph`, `StateGraphBuilder`, `compile()` returning `CompiledStateGraph` (flat layout; no `graph/` subdir) |
| `pregolya-graph/src/types.rs` | create | `WriteRecord`, `CompiledStateGraph`, `ChannelKind`; `#[cfg(any(test, feature = "test-util"))] pub fn stub_terminal(terminal_state: serde_json::Value) -> Arc<CompiledStateGraph>` — single-node terminal helper exposed via `test-util` feature for cross-crate VP-016 harness in S-2.11; NOT public API |
| `pregolya-graph/src/bsp_engine.rs` | create (partial) | `reduce_super_step`, `finish` — shared with S-1.16 |
| `pregolya-graph/tests/channel_semantics.rs` | create | AC-001..AC-011 + Red Gate tests |
