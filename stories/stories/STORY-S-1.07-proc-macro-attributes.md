---
document_type: story
level: ops
story_id: S-1.07
epic_id: E-02
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.010.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.011.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.012.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "1edd17d"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.04]
blocks: [S-1.21, S-2.07]
behavioral_contracts: [BC-2.08.010, BC-2.08.011, BC-2.08.012]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-macros
subsystems: [SS-08]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.07: Proc-Macro Attributes — #[tool], #[entrypoint], #[task]

## Narrative

- **As a** pregolya library user building tool-calling agents
- **I want to** annotate Rust functions with `#[tool]`, `#[entrypoint]`, and `#[task]` proc-macro attributes
- **So that** the macro expansion generates the required boilerplate structs, trait implementations, and graph wiring automatically — eliminating manual scaffolding and ensuring every generated type is correct-by-construction per the behavioral contracts

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.08.010 | `#[tool]` Proc-Macro — Generates Tool Struct, Args Struct, and ActionRisk Impl | AC-001..AC-007 |
| BC-2.08.011 | `#[entrypoint]` Proc-Macro — Auto-wires START Edge; At Most One Per Graph | AC-008..AC-011 |
| BC-2.08.012 | `#[task]` Proc-Macro — Generates Task Node with `register_into(graph)` | AC-012..AC-015 |

## Acceptance Criteria

### AC-001 (traces to BC-2.08.010 postcondition 1)
`#[tool]` applied to an `async fn my_search(args: MySearchArgs) -> Result<T, PregolyaError>` generates a zero-sized struct `MySearchTool` that implements the `Tool` trait from `pregolya-core`. The generated struct name is the PascalCase conversion of the function name with `Tool` suffix appended. Verified by `test_BC_2_08_010_tool_struct_generated()`.

### AC-002 (traces to BC-2.08.010 postcondition 2)
`#[tool]` generates an `Args` struct named `<PascalCaseName>Args` that derives `serde::Deserialize` and `schemars::JsonSchema` (schemars 1.x). The generated `json_schema()` method on the `Tool` impl returns the schema produced by `schemars`. Verified by `test_BC_2_08_010_args_struct_schema()`.

### AC-003 (traces to BC-2.08.010 postcondition 3)
`#[tool(action_risk = "High")]` emits the `action_risk()` method returning `Some(::pregolya_core::action_risk::ActionRisk::High)` using the fully-qualified path (no unqualified variant names). `#[tool]` without the attribute emits `action_risk()` returning `None`. Verified by `test_BC_2_08_010_action_risk_fully_qualified()`.

### AC-004 (traces to BC-2.08.010 postcondition 4)
The function body annotated with `#[tool]` is moved into the generated `Tool::invoke` implementation. The original function is replaced by the macro expansion; no duplicate definition exists. Verified by `test_BC_2_08_010_invoke_body_moved()`.

### AC-005 (traces to BC-2.08.010 postcondition 5)
The function signature wrapped by `#[tool]` MUST return `Result<T, PregolyaError>`. If the return type is not `Result<_, PregolyaError>`, the macro emits a compile error: `"#[tool] function must return Result<T, PregolyaError>"`. Verified by compile-fail test `test_BC_2_08_010_non_result_return_compile_error` in `tests/compile-fail/`.

### AC-006 (traces to BC-2.08.010 edge case EC-001 — name collision)
If the generated `<PascalCaseName>Tool` or `<PascalCaseName>Args` name would collide with an existing identifier in the same module, the macro emits a compile error rather than silently shadowing. Verified by compile-fail test `test_BC_2_08_010_name_collision_compile_error`.

### AC-007 (traces to BC-2.08.010 edge case EC-003 — invalid action_risk value)
`#[tool(action_risk = "InvalidVariant")]` emits a compile error: `"#[tool] action_risk must be one of: Low, Medium, High, Critical"`. Verified by compile-fail test `test_BC_2_08_010_invalid_action_risk_compile_error`.

### AC-008 (traces to BC-2.08.011 postcondition 1)
`#[entrypoint]` applied to a function auto-wires the `START` edge to the annotated function's generated node in the `StateGraph`. The generated wiring calls `graph.set_entry_point(node_name)`. Verified by `test_BC_2_08_011_start_edge_wired()`.

### AC-009 (traces to BC-2.08.011 postcondition 2 — at most one per graph)
If two functions in the same `StateGraph` builder are annotated with `#[entrypoint]`, the macro expansion produces a compile error: `"#[entrypoint] may be applied to at most one function per graph"`. Verified by compile-fail test `test_BC_2_08_011_duplicate_entrypoint_compile_error`.

### AC-010 (traces to BC-2.08.011 postcondition 3)
The entrypoint function must be compatible with the graph's state type. If the function signature does not accept the graph state, the macro emits a type-mismatch compile error. Verified by compile-fail test `test_BC_2_08_011_state_type_mismatch_compile_error`.

### AC-011 (traces to BC-2.08.011 edge case EC-002 — async entrypoint)
`#[entrypoint]` on an `async fn` correctly wraps the invocation in an `async` context within the graph executor. The generated `register_into` call preserves the async signature. Verified by `test_BC_2_08_011_async_entrypoint_register()`.

### AC-012 (traces to BC-2.08.012 postcondition 1)
`#[task]` applied to `async fn my_process_task(...)` generates a struct `MyProcessTaskNode` — the name is derived from the function name with `Node` suffix and NO case conversion (snake_case fn name → PascalCase struct name by standard Rust naming, then `Node` suffix). Verified by `test_BC_2_08_012_node_struct_generated()`.

### AC-013 (traces to BC-2.08.012 postcondition 2)
The generated `MyProcessTaskNode` implements a `register_into(graph: &mut StateGraph<S>)` method that registers the node with the graph under the function's original snake_case name as the node identifier. Verified by `test_BC_2_08_012_register_into_called()`.

### AC-014 (traces to BC-2.08.012 postcondition 3)
`#[task]` preserves `async` semantics: the generated `invoke` method is `async fn invoke(&self, state: S) -> Result<NodeOutput<S>, PregolyaError>` and the macro wraps the annotated function body correctly. Verified by `test_BC_2_08_012_async_invoke_preserved()`.

### AC-015 (traces to BC-2.08.012 edge case EC-001 — non-async task)
`#[task]` on a synchronous (non-async) function emits a compile error: `"#[task] requires an async function"`. Verified by compile-fail test `test_BC_2_08_012_sync_fn_compile_error`.

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `#[tool]` attribute macro (struct generation, `Args`, `ActionRisk` impl, compile-fail gates) | `pregolya_macros::tool` | pregolya-macros | Pure (compile-time `TokenStream` transform; no runtime I/O) |
| `#[entrypoint]` attribute macro (START edge wiring, at-most-one gate, async compatibility) | `pregolya_macros::entrypoint` | pregolya-macros | Pure (compile-time `TokenStream` transform; no runtime I/O) |
| `#[task]` attribute macro (`Node` struct, `register_into` generation, async-required gate) | `pregolya_macros::task` | pregolya-macros | Pure (compile-time `TokenStream` transform; no runtime I/O) |
| Compile-fail test harness (`trybuild`) | `pregolya_macros::tests::compile-fail` | pregolya-macros | Pure (`#[cfg(test)]`; compile-time only) |

**Subsystem anchor:** SS-08 owns this story's scope because BC-2.08.010–012 fall under PRD section 2.08 per ARCH-INDEX Subsystem Registry. The `pregolya-macros` crate (ADR-008) is the implementation target — it delivers compile-time `#[tool]`, `#[entrypoint]`, and `#[task]` attribute macros, which are the code-generation layer enabling provider-conformant tool and graph wiring without hand-written boilerplate. Pure-core / effectful-shell boundary: all macro expansion logic is pure (compile-time token transforms); the generated `invoke` body (user-provided async function) is effectful but lives in the user's crate, not in `pregolya-macros`.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `#[tool]` macro expansion | Pure | Compile-time `TokenStream` transform via `syn` + `quote`; no I/O side effects at runtime |
| `#[entrypoint]` macro expansion | Pure | Compile-time `TokenStream` transform; no I/O side effects at runtime |
| `#[task]` macro expansion | Pure | Compile-time `TokenStream` transform; no I/O side effects at runtime |
| Generated `<Name>Tool::invoke` (user-provided function body, wrapped by macro) | Effectful Shell | User-provided async function body; macro wraps but does not execute it — effectfulness is the user's responsibility |
| Compile-fail tests (`trybuild`) | Pure (`#[cfg(test)]`) | Compile-check harness only; no production I/O |

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~3,500 |
| BC files (3 BCs: BC-2.08.010/011/012) | ~4,500 |
| Architecture module-decomposition.md (SS-08 section) | ~800 |
| pregolya-macros proc-macro crate skeleton | ~1,500 |
| pregolya-core trait surface (Tool, Runnable) | ~2,000 |
| Test files (unit + compile-fail) | ~3,000 |
| schemars 1.x docs reference | ~500 |
| **Total** | **~15,800** |

Well within the 20-30% agent context window threshold (≈30,000 tokens for 100k context).

## Tasks

- [ ] Create `pregolya-macros/src/lib.rs` — declare proc-macro crate with `proc-macro = true` in Cargo.toml
- [ ] Implement `#[tool]` macro in `pregolya-macros/src/tool.rs` — PascalCase name derivation, Args struct generation, schemars JsonSchema derive, ActionRisk fully-qualified path, Result return-type gate, compile-fail for name collision and invalid action_risk
- [ ] Implement `#[entrypoint]` macro in `pregolya-macros/src/entrypoint.rs` — START edge wiring, at-most-one gate, async compatibility
- [ ] Implement `#[task]` macro in `pregolya-macros/src/task.rs` — Node struct, register_into method, async-required gate
- [ ] Write unit tests in `pregolya-macros/tests/` for AC-001..AC-004, AC-008, AC-011..AC-014
- [ ] Write compile-fail tests in `pregolya-macros/tests/compile-fail/` for AC-005, AC-006, AC-007, AC-009, AC-010, AC-015 using `trybuild`
- [ ] Add `pregolya-macros` to workspace `Cargo.toml` members
- [ ] Add `pregolya-macros` dependency to `pregolya-core` and `pregolya-graph` with re-export via `pub use`
- [ ] Verify `#[non_exhaustive]` on any public enum generated by macros (ActionRisk is upstream in pregolya-core)
- [ ] Run `just iter pregolya-macros` — all tests green

## Previous Story Intelligence

- S-1.04 (Runnable Trait and Pipe) established the `Tool` trait and `Runnable` abstraction that `#[tool]`-generated structs must implement. The exact trait surface (invoke signature, json_schema) drives macro output.
- S-1.04 established `pregolya-core` as the crate providing `Tool`, `ActionRisk`, and `PregolyaError`. The fully-qualified path `::pregolya_core::action_risk::ActionRisk::<Variant>` is mandated by BC-2.08.010 postcondition 3 and must be hardcoded in the macro expansion to avoid unqualified name resolution failures in user crates.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-macros` and ADR-008:

1. `pregolya-macros` must be a `proc-macro = true` Cargo crate — no non-proc-macro code in the crate root
2. All macro output uses fully-qualified paths for upstream types (e.g., `::pregolya_core::action_risk::ActionRisk::High`, not `ActionRisk::High`). This prevents name-resolution failures in user crates.
3. `pregolya-macros` MUST NOT depend on `pregolya-core` at runtime — the dependency is compile-time only (syn, quote, proc-macro2). Add `pregolya-core` as a `dev-dependency` only for testing the generated output.
4. Macro span hygiene: generated identifiers must use `Span::mixed_site()` to avoid accidental variable capture in user code.
5. All public types generated by macros must carry `#[non_exhaustive]` if they will be returned across crate boundaries.
6. No `unwrap()` / `expect()` in macro expansion code (panic at compile time is acceptable for diagnosed errors; use `syn::Error::new_spanned` for proper diagnostics).

## Library & Framework Requirements

Derived from `architecture/dependency-graph.md` external dependency table:

| Library | Version | Usage |
|---------|---------|-------|
| `syn` | 2.x | Parse proc-macro input TokenStream |
| `quote` | 1.x | Generate output TokenStream |
| `proc-macro2` | 1.x | Token manipulation |
| `schemars` | 1.x | Derived `JsonSchema` on generated Args structs (ADR-004) |
| `serde` | 1.x | Derived `Deserialize` on generated Args structs |
| `trybuild` | 1.x | Compile-fail test harness for AC-005..AC-007, AC-009, AC-010, AC-015 |

All versions are pinned via the workspace `Cargo.toml`. Do not introduce versions not present in the workspace dependency table.

**Forbidden Dependencies:** `pregolya-macros` MUST NOT have a runtime dependency on `pregolya-core`, `pregolya-graph`, `tokio`, or any crate that would create a circular dependency. The build system must fail if these appear as non-dev dependencies in `pregolya-macros/Cargo.toml`.

## File Structure Requirements

Files to CREATE:
- `/pregolya-macros/Cargo.toml` — proc-macro crate manifest; `[lib] proc-macro = true`
- `/pregolya-macros/src/lib.rs` — re-export only: `pub use tool::tool; pub use entrypoint::entrypoint; pub use task::task;`
- `/pregolya-macros/src/tool.rs` — `#[tool]` implementation
- `/pregolya-macros/src/entrypoint.rs` — `#[entrypoint]` implementation
- `/pregolya-macros/src/task.rs` — `#[task]` implementation
- `/pregolya-macros/tests/tool_tests.rs` — unit tests for AC-001..AC-004
- `/pregolya-macros/tests/entrypoint_tests.rs` — unit tests for AC-008, AC-011
- `/pregolya-macros/tests/task_tests.rs` — unit tests for AC-012..AC-014
- `/pregolya-macros/tests/compile-fail/tool_non_result_return.rs` — AC-005
- `/pregolya-macros/tests/compile-fail/tool_name_collision.rs` — AC-006
- `/pregolya-macros/tests/compile-fail/tool_invalid_action_risk.rs` — AC-007
- `/pregolya-macros/tests/compile-fail/entrypoint_duplicate.rs` — AC-009
- `/pregolya-macros/tests/compile-fail/entrypoint_state_mismatch.rs` — AC-010
- `/pregolya-macros/tests/compile-fail/task_sync_fn.rs` — AC-015

Files to MODIFY:
- `/Cargo.toml` — add `"pregolya-macros"` to `[workspace] members`
- `/pregolya-core/Cargo.toml` — add `pregolya-macros` dependency; re-export macros via `pub use pregolya_macros::*` in `pregolya-core/src/lib.rs`

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Generated `<PascalCaseName>Tool` or `<PascalCaseName>Args` collides with existing identifier in the same module | Macro emits compile error rather than silently shadowing (AC-006) |
| EC-002 | `#[tool(action_risk = "InvalidVariant")]` with a value not in `{Low, Medium, High, Critical}` | Macro emits compile error: `"#[tool] action_risk must be one of: Low, Medium, High, Critical"` (AC-007) |
| EC-003 | `#[tool]` on a function whose return type is not `Result<T, PregolyaError>` | Macro emits compile error: `"#[tool] function must return Result<T, PregolyaError>"` (AC-005) |
| EC-004 | Two functions in the same `StateGraph` builder annotated with `#[entrypoint]` | Macro expansion emits compile error: `"#[entrypoint] may be applied to at most one function per graph"` (AC-009) |
| EC-005 | `#[task]` applied to a synchronous (non-async) function | Macro emits compile error: `"#[task] requires an async function"` (AC-015) |
