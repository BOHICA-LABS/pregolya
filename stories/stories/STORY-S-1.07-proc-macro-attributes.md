---
document_type: story
level: ops
story_id: S-1.07
epic_id: E-02
version: "1.6"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.010.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.011.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.012.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "a260b4d"
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
| BC-2.08.010 | `#[tool]` Attribute Macro — async fn to Tool Implementor via schemars::JsonSchema | AC-001..AC-007, AC-016 |
| BC-2.08.011 | `#[entrypoint]` Attribute Macro — START Edge Auto-Wiring for StateGraph | AC-008..AC-011 |
| BC-2.08.012 | `#[task]` Attribute Macro — Task Registration Boilerplate Generation | AC-012..AC-015, AC-017 |

## Acceptance Criteria

### AC-001 (traces to BC-2.08.010 PC-001)
`#[tool]` applied to an `async fn my_search(args: MySearchArgs) -> Result<T, PregolyaError>` generates a zero-sized struct `MySearchTool` that implements the `Tool` trait from `pregolya-core`. The generated struct name is the PascalCase conversion of the function name with `Tool` suffix appended. Verified by `test_BC_2_08_010_tool_struct_generated()`.

### AC-002 (traces to BC-2.08.010 PC-002)
`#[tool]` generates an `Args` struct named `<PascalCaseName>Args` that derives `serde::Deserialize` and `schemars::JsonSchema` (schemars 1.x). The generated `json_schema()` method on the `Tool` impl returns the schema produced by `schemars`. Verified by `test_BC_2_08_010_args_struct_schema()`.

### AC-003 (traces to BC-2.08.010 PC-001)
`#[tool(action_risk = ActionRisk::High)]` emits the `action_risk()` method returning `Some(::pregolya_core::action_risk::ActionRisk::High)` using the fully-qualified path (no unqualified variant names). `#[tool]` without the attribute emits `action_risk()` returning `None`. Verified by `test_BC_2_08_010_action_risk_fully_qualified()`.

### AC-004 (traces to BC-2.08.010 PC-001)
The function body annotated with `#[tool]` is moved into the generated `Tool::invoke` implementation. The original function is replaced by the macro expansion; no duplicate definition exists. Verified by `test_BC_2_08_010_invoke_body_moved()`.

### AC-005 (traces to BC-2.08.010 PC-004)
The function signature wrapped by `#[tool]` MUST return `Result<T, PregolyaError>`. If the return type is not `Result<_, PregolyaError>`, the macro emits a compile error: `"#[tool] function must return Result<T, PregolyaError>"`. Verified by compile-fail test `test_BC_2_08_010_non_result_return_compile_error` in `tests/compile-fail/`.

### AC-006 (traces to BC-2.08.010 EC-001 — name collision)
If the generated `<PascalCaseName>Tool` or `<PascalCaseName>Args` name would collide with an existing identifier in the same module, the macro emits a compile error rather than silently shadowing. Verified by compile-fail test `test_BC_2_08_010_name_collision_compile_error`.

### AC-007 (traces to BC-2.08.010 EC-003 — invalid action_risk value)
`#[tool(action_risk = ActionRisk::Critical)]` emits a compile error: `"#[tool] action_risk must be one of: ReadOnly, Low, Medium, High"`. Verified by compile-fail test `test_BC_2_08_010_invalid_action_risk_compile_error`.

### AC-008 (traces to BC-2.08.011 PC-001)
`#[entrypoint]` applied to a function auto-wires the `START` edge to the annotated function's generated node in the `StateGraph`. The generated wiring calls `graph.set_entry_point(node_name)`. Verified by `test_BC_2_08_011_start_edge_wired()`.

### AC-009 (traces to BC-2.08.011 EC-001)
If two functions in the same `StateGraph` builder are annotated with `#[entrypoint]`, the macro expansion produces a compile error: `"#[entrypoint] may be applied to at most one function per graph"`. Verified by compile-fail test `test_BC_2_08_011_duplicate_entrypoint_compile_error`.

### AC-010 (traces to BC-2.08.011 PRE-001)
The entrypoint function must be compatible with the graph's state type. If the function signature does not accept the graph state, the macro emits a type-mismatch compile error. Verified by compile-fail test `test_BC_2_08_011_state_type_mismatch_compile_error`.

### AC-011 (traces to BC-2.08.011 PC-003)
`#[entrypoint]` on an `async fn` correctly wraps the invocation in an `async` context within the graph executor. The generated `register_into` call preserves the async signature. Verified by `test_BC_2_08_011_async_entrypoint_register()`.

### AC-012 (traces to BC-2.08.012 PC-001)
`#[task]` applied to `async fn my_process_task(...)` generates a struct `MyProcessTaskNode` — the name is derived from the function name with `Node` suffix and NO case conversion (snake_case fn name → PascalCase struct name by standard Rust naming, then `Node` suffix). Verified by `test_BC_2_08_012_node_struct_generated()`.

### AC-013 (traces to BC-2.08.012 PC-001)
The generated `MyProcessTaskNode` implements a `register_into(graph: &mut StateGraph)` method that registers the node with the graph under the function's original snake_case name as the node identifier. Verified by `test_BC_2_08_012_register_into_called()`.

### AC-014 (traces to BC-2.08.012 PC-002)
`#[task]` preserves `async` semantics: the generated `invoke` method is `async fn invoke(&self, state: S) -> Result<NodeOutput<S>, PregolyaError>` and the macro wraps the annotated function body correctly. Verified by `test_BC_2_08_012_async_invoke_preserved()`.

### AC-015 (traces to BC-2.08.012 PRE-001)
`#[task]` on a synchronous (non-async) function emits a compile error: `"#[task] requires an async function"`. Verified by compile-fail test `test_BC_2_08_012_sync_fn_compile_error`.

### AC-016 (traces to BC-2.08.010 PC-006 — duplicate tool name at collection assembly)
When assembling a tool collection (e.g., `ToolRegistry` or `MultiServerMcpClient`) and a second `Tool` implementor is registered under a name already occupied in the collection (duplicate `tool.name()` return value), the registration call returns `Err(PregolyaError { component: TOOLS, category: VAL, code: "E-TOOLS-010", message: "DuplicateToolName: tool name '<name>' is already registered", retry_hint: Never })`. The first-registered tool is retained; the collection is NOT partially mutated. Detection is at collection-assembly time, not compile time (the two tools may be generated from different function names that happen to produce the same `tool.name()` string). Verified by `test_BC_2_08_010_duplicate_tool_name_e_tools_010()` and TV-006.

### AC-017 (traces to BC-2.08.012 EC-004 — reserved-name HARD compile-time error)
`#[pregolya::task]` applied to a function whose name is `start` or `end` (or whose derived task identifier matches a reserved graph routing symbol) produces a compile-time error. The error message is: `"#[pregolya::task] macro rejects reserved identifiers START ('start') or END ('end'); use add_node(...) directly"`. This is a HARD compilation failure — accepting a reserved name silently would produce nodes that shadow or conflict with `START`/`END` routing symbols, making the resulting graph unroutable. Verified by compile-fail test `test_BC_2_08_012_reserved_name_compile_error` and TV-006.

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
- [ ] Write unit tests in `pregolya-macros/tests/` for AC-001..AC-004, AC-008, AC-011..AC-014, AC-016 (`test_BC_2_08_010_duplicate_tool_name_e_tools_010`)
- [ ] Write compile-fail tests in `pregolya-macros/tests/compile-fail/` for AC-005, AC-006, AC-007, AC-009, AC-010, AC-015, AC-017 using `trybuild`
- [ ] Add `pregolya-macros` to workspace `Cargo.toml` members
- [ ] Add `pregolya-macros` dependency to `pregolya-core` and `pregolya-graph` with re-export via `pub use`
- [ ] Verify `#[non_exhaustive]` on any public enum generated by macros (ActionRisk is upstream in pregolya-core)
- [ ] Run `just iter pregolya-macros` — all tests green

## Previous Story Intelligence

- S-1.04 (Runnable Trait and Pipe) established the `Tool` trait and `Runnable` abstraction that `#[tool]`-generated structs must implement. The exact trait surface (invoke signature, json_schema) drives macro output.
- S-1.04 established `pregolya-core` as the crate providing `Tool`, `ActionRisk`, and `PregolyaError`. The fully-qualified path `::pregolya_core::action_risk::ActionRisk::<Variant>` is mandated by BC-2.08.010 PC-001 and must be hardcoded in the macro expansion to avoid unqualified name resolution failures in user crates.

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
| `schemars` | workspace pin | Derived `JsonSchema` on generated Args structs (ADR-004) |
| `serde` | workspace pin | Derived `Deserialize` on generated Args structs |
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
| EC-002 | `#[tool(action_risk = ActionRisk::Critical)]` with a value not in `{ReadOnly, Low, Medium, High}` | Macro emits compile error: `"#[tool] action_risk must be one of: ReadOnly, Low, Medium, High"` (AC-007) |
| EC-003 | `#[tool]` on a function whose return type is not `Result<T, PregolyaError>` | Macro emits compile error: `"#[tool] function must return Result<T, PregolyaError>"` (AC-005) |
| EC-004 | Two functions in the same `StateGraph` builder annotated with `#[entrypoint]` | Macro expansion emits compile error: `"#[entrypoint] may be applied to at most one function per graph"` (AC-009) |
| EC-005 | `#[task]` applied to a synchronous (non-async) function | Macro emits compile error: `"#[task] requires an async function"` (AC-015) |
| EC-006 | Two tools both with `name()` == `"search_web"` assembled into a `ToolRegistry` | Registration of second tool returns `Err(E-TOOLS-010 DuplicateToolName { name: "search_web" })`; first-registered tool retained; collection not mutated (AC-016) |
| EC-007 | `#[pregolya::task] async fn start(state: S) -> ...` | Compile-time error: `"#[pregolya::task] macro rejects reserved identifiers START ('start') or END ('end')"` (AC-017) |

## Changelog

- 1.0 (2026-08-18): initial story authoring.
- 1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors. Corrections: AC-003 postcondition 3→PC-001 (action_risk in PC-001 not PC-003); AC-004 postcondition 4→PC-001 (invoke delegation in PC-001); AC-005 postcondition 5→PC-004 (DI-008 Result enforcement); AC-009 postcondition 2→EC-001 (duplicate entrypoint is EC-001); AC-010 postcondition 3→PRE-001 (state type is precondition); AC-011 EC-002→PC-003 (async preservation in PC-003); AC-013 postcondition 2→PC-001 (register_into in PC-001); AC-014 postcondition 3→PC-002 (async fn unchanged); AC-015 EC-001→PRE-001 (non-async violates PRE-001). ESCALATION: AC-006 (BC-2.08.010 EC-001 mismatch — story asserts struct name collision but BC EC-001 is about missing JsonSchema); AC-007 (BC-2.08.010 EC-003 mismatch — story asserts invalid action_risk compile error but BC EC-003 is about non-PregolyaError return; no BC EC covers invalid action_risk values). Routes to product-owner.
- 1.2 (ADR-027 M4/2026-08-24): ADR-027 M4: normalize edge-case citations to stable EC-NNN tag.
- 1.3 (P2A-043 F-04/2026-08-24): old-form ordinal cross-refs converted to stable tags.
- 1.4 (SW-2/bc-completeness-hardening/2026-08-26): BC-2.08.010 → AC-016 (PC-006 duplicate tool name at collection assembly → E-TOOLS-010; first-registered retained); BC-2.08.012 → AC-017 (EC-004 reserved-name HARD compile-time error). EC-006/EC-007 added to edge cases. Tasks updated for new test functions.
- 1.5 (GAP-01-type-grounding/round-12/2026-08-27): AC-013 `register_into` signature de-genericized: `StateGraph<S>` → `StateGraph` — `StateGraph` is non-generic per S-1.14 (architect-confirmed round-12). User node-state type `S` in node-fn signatures (e.g. `async fn task(state: S) -> Result<Update<S>>`) is unaffected; only the `StateGraph<S>` type parameter is removed. input-hash updated (state-manager recomputes).
- 1.6 (round-79/F-P2A251-02/2026-09-02): BC table title cells corrected to verbatim canonical H1 per POL-7/F-P2A251-02.
