---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.012
version: "1.6"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-003
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.0 (2026-07-13): initial authoring — Greenfield batch 13"
  - "1.1 (2026-07-14): Architecture Anchor pregolya-core/src/graph/builder.rs corrected to pregolya-graph/src/graph/state.rs — StateGraph builder is owned by pregolya-graph per ADR-007 / module-decomposition.md / BC-2.02.001 (F-P42-01, ADV-P1D-PASS-42)"
  - "1.2 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.07 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.3 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.4 (burst-B-SS07-08/bc-completeness-scan-P2/2026-08-26): Resolve Phase-2 BC-completeness-scan gap SS-07..08: EC-004 reserved-name behavior decided as HARD compile-time error (decision: accepting a reserved name silently produces unreachable nodes or routing-symbol shadowing at runtime; a warn-only outcome is insufficient because graph execution would misroute without surfacing the error at the call site; failing closed at compile time is the production-grade default). TV-006 added: function named `start` → compile-time error."
  - "1.5 (round-12/GAP-01-type-grounding/2026-08-27): {PC-001} `register_into(graph: &mut StateGraph<S>)` → `register_into(graph: &mut StateGraph)` (non-generic; architect-confirmed BC-2.02.001 {PC-001} / ADR-029 §Symbol Grounding). The node-fn parameter `state: S` retains `S` — that is the user's concrete state type, NOT a StateGraph type parameter. Zero residual `StateGraph<S>` in live body."
  - "1.6 (round-38-ss08/F-P2A163-01/2026-08-29): F-P2A163-01 [MED] same-class sweep — §Architecture Anchors phantom `pregolya-graph/src/graph/state.rs` corrected to architect-confirmed canonical `pregolya-graph/src/definition.rs` (module `graph::definition`); no behavioral change."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
  - architecture/decisions/ADR-008-proc-macro-attributes.md
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-008-proc-macro-attributes.md
input-hash: "361ee99"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.012: `#[task]` Attribute Macro — Task Registration Boilerplate Generation

## Description

The `#[pregolya::task]` proc-macro attribute marks an async function as a StateGraph task,
generating the registration boilerplate that wires it as a node into the graph's task
dispatch table. This eliminates the manual `graph.add_node("node_name", node_fn)` call: the
macro captures the function name as the canonical task identifier and produces a registration
token. The macro is additive — manual `add_node(...)` remains valid and produces identical
runtime behavior. A `#[task]`-annotated function compiles and runs identically to a manually
registered node function with the same name.

## Preconditions

1. {PRE-001} The annotated function is an async fn with the StateGraph node signature:
   `async fn task_name(state: S) -> Result<Update<S>, PregolyaError>` (or equivalent).
2. {PRE-002} The function name is a valid Rust identifier and will be used as the node's string
   identifier in the task dispatch table.
3. {PRE-003} `pregolya-macros` is available (re-exported from `pregolya-core`).

## Postconditions

1. {PC-001} The macro generates a registration token type `<PascalCaseTaskName>Node` that implements
   a `register_into(graph: &mut StateGraph)` method equivalent to
   `graph.add_node(stringify!(task_name), task_name)`.
2. {PC-002} The annotated function itself is unchanged — it remains a callable async fn with its
   original signature.
3. {PC-003} A `StateGraph` built by calling `<PascalCaseTaskName>Node::register_into(&mut graph)` is
   semantically identical to one built by calling `graph.add_node("task_name", task_name)`.
4. {PC-004} The generated registration token type is `Send + Sync`.
5. {PC-005} Calling `register_into` on a graph that already has a node with the same name returns
   `Err(GraphBuildError::DuplicateNode("task_name"))`.

## Invariants

- {INV-001} The macro does not alter the function body, signature, or visibility of the annotated
  function. It only generates adjacent boilerplate.
- {INV-002} The canonical task identifier (node name string) is derived deterministically from the
  function name; it cannot be overridden via attribute arguments. If a custom name is needed,
  the user must use manual `add_node(...)`.
- {INV-003} Name derivation: `snake_case_fn_name` → string `"snake_case_fn_name"` (no case conversion).

## Edge Cases

### EC-001: Duplicate task registration in the same graph
**Scenario:** `TaskANode::register_into(&mut graph)` called twice on the same graph instance.
**Expected behavior:** First call succeeds. Second call returns
`Err(GraphBuildError::DuplicateNode("task_a"))`. No silent override.

### EC-002: `#[task]` function not called via `register_into`
**Scenario:** The annotated function is used directly as a closure in `graph.add_node(...)`.
**Expected behavior:** Valid and correct — the macro generates a registration token but does
not prevent direct use. The token type is simply unused.

### EC-003: Annotated function has a generic type parameter
**Scenario:** `#[pregolya::task] async fn process<T: Runnable<...>>(state: S) -> ...`
**Expected behavior:** Compile-time error from the macro: `#[task] does not support generic
functions; use add_node directly for generic task registration`.

### EC-004: Task name conflicts with a built-in graph node identifier
**Scenario:** Function named `start` or `end` (reserved identifiers in StateGraph routing semantics).
**Expected behavior:** **Compile-time error** (hard; not a warning). The `#[pregolya::task]`
macro rejects any function whose derived task identifier collides with the reserved identifiers
`START` (`"start"`) or `END` (`"end"`). Decision rationale: a warn-only outcome is insufficient
because a task registered under a reserved name would silently produce unreachable nodes or shadow
the routing symbols at graph-execution time; the graph would misroute without surfacing the error
at the call site. Failing closed at compile time (hard error) is the production-grade default
(CANONICAL PRINCIPLE: production-grade correctness; silent runtime misrouting is a P1 defect).
Operators who require a task with a `start`-like canonical string MUST use `graph.add_node(...)`
directly with an explicitly chosen non-reserved name string.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `#[pregolya::task] async fn summarize(state: S) -> ...` + `SummarizeNode::register_into(&mut graph)` | Graph registers node with key `"summarize"` | Happy path |
| TV-002 | `SummarizeNode::register_into` called twice on same graph | Second call returns `Err(GraphBuildError::DuplicateNode("summarize"))` | Duplicate guard |
| TV-003 | Graph with `#[task]` registration vs manual `add_node("summarize", summarize)` | Both graphs execute identically for same input | Semantic equivalence |
| TV-004 | Generic `#[task]` function | Compile-time error from macro | Generics unsupported |
| TV-005 | Function annotated but `register_into` never called | Compiles; function remains a valid standalone async fn | Additive only |
| TV-006 | `#[pregolya::task] async fn start(state: S) -> Result<Update<S>, PregolyaError>` | Compile-time error: "reserved name 'start' conflicts with START routing symbol; use add_node(...) directly" | Reserved-name hard error (EC-004) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208012-01 | Graph built via `#[task]` registration is semantically equivalent to graph built via manual `add_node` | Equivalence test: identical execution traces for same input | Phase 3 |

## Related BCs

- BC-2.08.010 — sibling: `#[tool]` macro (same proc-macro crate)
- BC-2.08.011 — sibling: `#[entrypoint]` macro (same proc-macro crate)
- BC-2.02.001 — depends on: StateGraph node definition contract (what this macro registers)
- BC-2.03.001 — depends on: BSP execution dispatches tasks registered via this macro

## Architecture Anchors

- `pregolya-macros/src/task.rs` — `#[task]` proc-macro implementation
- `pregolya-graph/src/definition.rs` (module `graph::definition`) — `add_node` API that the generated code calls
- `architecture/decisions/ADR-008-proc-macro-attributes.md` — proc-macro design rationale

## Story Anchor

S-1.07

## VP Anchors

- VP-BC208012-01

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — the `#[task]` macro generates the node registration boilerplate for StateGraph construction; node registration is the foundational operation in CAP-003's "define directed agent graphs: add typed nodes" scope |
| L2 Domain Invariants | — (no DI directly anchored; the macro generates correct graph registration per CAP-003 constraints) |
| DEC Reference | — |
| Risk Source | ADR-008 acceptance (D5 gate resolved via ADR-004); proc-macro design |
| D17 Commitment | D17-Q6 — proc-macro BCs gated on D5 ADR; ADR-004 accepted unblocks this BC |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit) |
| Module | pregolya-macros (re-exported pregolya-core) |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.6 | 2026-08-29 | F-P2A163-01 [MED] same-class sweep — §Architecture Anchors phantom `pregolya-graph/src/graph/state.rs` corrected to architect-confirmed canonical `pregolya-graph/src/definition.rs` (module `graph::definition`); no behavioral change | round-38-ss08/F-P2A163-01 |
| 1.5 | 2026-08-27 | {PC-001} `register_into(graph: &mut StateGraph<S>)` → `register_into(graph: &mut StateGraph)` (non-generic; architect-confirmed BC-2.02.001 {PC-001}) | round-12/GAP-01-type-grounding |
| 1.4 | 2026-08-26 | EC-004 reserved-name behavior decided as HARD compile-time error (warn-only produces silent runtime misrouting); TV-006 added for reserved-name path | burst-B-SS07-08/bc-completeness-scan-P2 |
| 1.3 | 2026-08-23 | stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change | M1/ADR-027 |
| 1.2 | 2026-08-22 | §Story Anchor backfilled to S-1.07 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change) | story-anchor-backfill |
| 1.1 | 2026-07-14 | Architecture Anchor `pregolya-core/src/graph/builder.rs` corrected to `pregolya-graph/src/graph/state.rs` — StateGraph builder is owned by pregolya-graph per ADR-007 / module-decomposition.md / BC-2.02.001 (F-P42-01, ADV-P1D-PASS-42) | F-P42-01 |
| 1.0 | 2026-07-13 | Initial authoring | Greenfield batch 13 |
