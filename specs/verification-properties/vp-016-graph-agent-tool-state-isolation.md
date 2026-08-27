---
document_type: verification-property
level: L4
vp_id: VP-016
title: "GraphAgentTool State-Isolation — the Returned serde_json::Value Contains Only extract_output-Selected Fields (No Internal Graph State Leak)"
status: draft
producer: architect
timestamp: 2026-08-26T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.008.md
input-hash: "e57e95f"
traces_to: ARCH-INDEX.md
source_bc: BC-2.09.008
bc_anchor: BC-2.09.008
di_anchor: DI-010
module: mcp::graph_tool
crate: pregolya-mcp
tool: proptest
proof_method: proptest
proof_phase: 3
priority: P1
red_gate: false
red_gate_source: null
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v1.0.0-greenfield
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
version: "2.0"
changelog:
  - "2.0 (round-18/F-P2A084-01+F-P2A084-02/2026-08-27): Exhaustive title/H1/frontmatter/table-cell/code-sketch sweep. Frontmatter `title:` and H1: 'ToolOutput Contains Only extract_output-Selected Fields' → 'the Returned `serde_json::Value` Contains Only extract_output-Selected Fields' (F-P2A084-01). §Proof Method table Bounded? cell: 'Unbounded over GraphState values' → 'Unbounded over `serde_json::Value` graph states'; Coverage cell: 'For any generated `S` instance' → 'For any generated `TestGraphState` instance (as `serde_json::Value`)' (F-P2A084-02). TestGraphState struct doc: 'GraphState carrying' → 'Test graph-state value carrying'; 'leaking into ToolOutput' → 'leaking into the `serde_json::Value` returned by `invoke_dyn`'; 'MUST NOT appear in ToolOutput' → 'MUST NOT appear in the `serde_json::Value` returned by `invoke_dyn`' (F-P2A084-01). Prose FALSE-GREEN GUARD (1): 'extra fields appear in `ToolOutput`' → 'extra fields appear in the `serde_json::Value` returned by `invoke_dyn`'. Harness proptest macro doc: 'into ToolOutput FAILS' → 'into the `serde_json::Value` returned by `invoke_dyn` FAILS'. Code-sketch: inline comment 'ToolOutput must contain EXACTLY' → 'the returned `serde_json::Value` must contain EXACTLY'; three prop_assert! messages 'must not appear in ToolOutput' → 'must not appear in the `serde_json::Value` returned by `invoke_dyn`'; prop_assert_eq! message 'ToolOutput must contain exactly' → 'the returned `serde_json::Value` must contain exactly'. input-hash updated 2e9c2d7 → e57e95f (BC-2.09.008 drift)."
  - "1.9 (round-14/F-P2A078-02+F-P2A078-04/2026-08-27): §Property Statement: 'fields from `GraphState S`' → 'fields from the non-generic `serde_json::Value` graph state'; 'the `ToolOutput` returned by `GraphAgentTool::invoke_dyn`' → 'the `serde_json::Value` returned by `GraphAgentTool::invoke_dyn`' (F-P2A078-02). §Corollary: 'in the `ToolOutput` unless' → 'in the `serde_json::Value` returned by `invoke_dyn` unless'. §BC Traceability table: '`ToolOutput` is structurally bounded by `extract_output`' → '`serde_json::Value` return is structurally bounded by `extract_output`'; EC-TV-1 → TV-001 / EC-007 (canonical BC-2.09.008 anchor forms; F-P2A078-04 MED). §Proof Method: 'concrete `S` instances' → 'concrete `TestGraphState` instances (serialized as `serde_json::Value`)'. §Feasibility: 'Open (arbitrary GraphState)' → 'Open (arbitrary `TestGraphState` as `serde_json::Value`)'."
  - "1.8 (round-12/GAP-01-straggler/2026-08-27): §Proof Obligations Stub Graph Obligation: ROUTING FLAG → SATISFIED (S-1.14 §AC-014 / Task 18, round-10); removed 'does NOT yet exist / requires routing / BEFORE Phase-3' language; ADR-029 §Symbol Grounding cross-ref updated. §Realizability Trace Step 1: 'Deserialization SUCCEEDS' → 'Input validation SUCCEEDS'; removed from_value::<TestGraphState> / ConcreteGraphRunner<S> deserialization framing (CompiledStateGraph::invoke takes serde_json::Value directly per BC-2.02.001 {PC-005}; no from_value step per F-P2A072-03). Step 2: ConcreteGraphRunner<TestGraphState> → ConcreteGraphRunner (non-generic); final_state.output → final_state[\"output\"] (serde_json::Value index form; matches harness closure). §Feasibility async-concern row: CompiledGraph::stub_terminal → CompiledStateGraph::stub_terminal."
  - "1.7 (round-10-sibling-sweep/2026-08-27): GAP-01 type-grounding straggler — §Feasibility: `Fn(&S) -> serde_json::Value + Send + Sync + 'static` bound → `Fn(&serde_json::Value) -> serde_json::Value + Send + Sync + 'static` bound (aligns with ADR-029 §Symbol Grounding canonical `extract_output` type; completes the type-grounding applied to property harness, prop harness imports, and module-decomposition in round-10 burst). input-hash updated to 1a605ae."
  - "1.6 (round-10/F-P2A072-01+F-P2A072-02+F-P2A072-03/2026-08-27): TYPE-GROUNDING reconciliation against canonical pregolya-core/pregolya-graph surfaces. F-P2A072-01 HIGH (as_value() E0599): `tool_output.as_value()` removed — `DynTool::invoke_dyn` returns `Result<serde_json::Value, PregolyaError>` directly (interface-definitions.md §Tool); `tool_output` IS a `serde_json::Value`; replaced `tool_output.as_value()` with direct `tool_output.as_object()` in Ok arm. Realizability Trace step 4 updated to reflect actual return type. F-P2A072-02 HIGH (ToolOutput::Structured phantom): `ToolOutput` has exactly `Text(String)`, `Json(serde_json::Value)`, `Error(String)` — NO `Structured` variant (interface-definitions.md §Tool). Formal property `Ok(ToolOutput::Structured { value })` rewritten to `Ok(value: serde_json::Value)`; `Ok(ToolOutput::Text { text })` arm removed. Realizability Trace step 3 rewritten to remove ToolOutput::Structured wrapping. F-P2A072-03 HIGH (CompiledGraph<S> + trait GraphState phantom): canonical type is `CompiledStateGraph` (non-generic, BC-2.02.001 {PC-001}, pregolya-graph/src/types.rs); `GraphState` is not a trait (entities-graph.md §GraphState: 'GraphState is not a user-defined struct; it is the composed value of all Channels'). `CompiledGraph::stub_terminal(state: S)` phantom replaced by `CompiledStateGraph::stub_terminal(terminal_state: serde_json::Value)`; `from_graph<S>` replaced by non-generic `from_graph` with explicit `input_schema: schemars::Schema` and `extract_output: Fn(&serde_json::Value) -> serde_json::Value`; harness `extract_output` closure updated from `|s: &TestGraphState|` to `|s: &serde_json::Value|`; Stub Graph Obligation type signature updated. All three phantoms closed. FOLLOW-UP (same burst, symbol-existence audit): `CompiledStateGraph::stub_terminal` confirmed NOT present in BC-2.02.001 or S-1.14 — this is a new symbol requiring graph-subsystem routing. §Stub Graph Obligation updated with ROUTING FLAG: orchestrator must dispatch story-writer or PO to add `stub_terminal` as `#[cfg(test)]` spec addition to S-1.14 or companion story before Phase 3 S-2.11 begins. ADR-029 §Symbol Grounding updated with REQUIRES-ROUTING row for this symbol."
  - "1.5 (round-8/F-P2A069-01+F-P2A069-02/2026-08-26): HOLISTIC realizability rewrite (GAP-01 cluster, 4-round cycle-breaker). F-P2A069-01 HIGH (vacuous false-green closed): input corrected from partial json!({output:…}) to serde_json::to_value(&state).unwrap() — complete serialized TestGraphState ensures ConcreteGraphRunner<S>::run deserialization succeeds and Ok-arm is reached for every generated case; all STATE-ISOLATION prop_assert!s execute. Err(_) arm converted to hard FALSE-GREEN GUARD (prop_assert!(false, …)) — stub_terminal always succeeds, so any Err is infra failure, never vacuous-pass. FALSE-GREEN GUARD prose updated to cover both invoke_dyn-bypass and vacuous-Err cases. POL-31 now reachable: complete input reaches extract_output; bypassing extract_output returns raw state with extra fields, failing prop_assert!s. §Realizability Trace added: 5-step end-to-end proof including leak-injection variant making an assertion FAIL, and explicit statement that no vacuous-Err path is reachable. F-P2A069-02 MED (deserialize location): parallel fix in ADR-029 §Decision 2 (from_value::<S> runs inside ConcreteGraphRunner<S>::run, not invoke_dyn; routing isError:true unchanged)."
  - "1.4 (round-7/F-P2A066-01/2026-08-26): F-P2A066-01 HIGH (seam contradiction closed). Option A adopted per authoritative carriers (BC-2.09.008 {PC-004}, ADR-029 §Decision 3): STATE-ISOLATION is enforced solely by GraphRunner::run via extract_output, NOT by invoke_dyn. §Proof Harness Skeleton rewritten: from_runner/MockGraphRunner approach replaced by from_graph/stub-graph approach; from_graph creates a real ConcreteGraphRunner<TestGraphState> that calls extract_output inside run(); stub_graph (CompiledGraph::stub_terminal) emits the full TestGraphState with extra fields; invoke_dyn wraps the runner's already-filtered result. FALSE-GREEN GUARD updated for Option A. Test Seam Obligation replaced with Stub Graph Obligation (CompiledGraph::stub_terminal). BC-2.09.008 {INV-001} code-review obligation updated to ConcreteGraphRunner::run call site. POL-31 rewritten: removed architecturally-impossible 'patch invoke_dyn to bypass extract_output'; new POL-31 requires formal-verifier to confirm harness FAILS when ConcreteGraphRunner::run bypasses extract_output call. Canonical Seam Statement obligation added. ADR-029 §Decision 3 receives parallel canonical seam statement (same burst)."
  - "1.3 (round-6/F-064-02+O-063-02/2026-08-26): F-064-02 HIGH (triple-confirmed) — §Proof Harness Skeleton: harness relocated from non-compilable integration test path (pregolya-mcp/tests/state_isolation.rs) to IN-CRATE #[cfg(test)] mod tests inside pregolya-mcp/src/graph_tool.rs. Three non-realizability defects fixed: (1) from_runner call now references the #[cfg(test)]-gated constructor seam on GraphAgentTool defined in the same file — not a phantom public API; (2) pub(crate) GraphRunner is reachable inside the crate's own cfg(test) block — E0603 eliminated; (3) extract_output closure corrected from Fn(&serde_json::Value) to Fn(&TestGraphState) -> serde_json::Value per the Fn(&S) -> serde_json::Value contract. 'Target file' line updated to pregolya-mcp/src/graph_tool.rs. §Proof Obligations: explicit §Test Seam Obligation added (impl GraphAgentTool::from_runner<S> must exist under #[cfg(test)] in graph_tool.rs; seam is NOT public). Harness remains load-bearing: MockGraphRunner returns full TestGraphState with EXTRA internal fields; ToolOutput key-set must equal exactly {'output'}; any field leak FAILS. O-063-02 OBS — normalize invoke→invoke_dyn in §Property Statement, formal property, §Source Contract {INV-001} paragraph, §Proof Method table, §Proof Obligations code-review obligation (three occurrences). Input-hash unchanged (source BC unchanged)."
  - "1.2 (P2A-062/2026-08-26): F-P2A-061-01 HIGH — §Proof Harness Skeleton rewritten to invoke the real production path (GraphAgentTool::invoke_dyn via MockGraphRunner test double) rather than a tautological local closure. Harness constructs GraphAgentTool over MockGraphRunner whose terminal state carries checkpoint_id/run_id/accumulated_messages beyond what extract_output selects; asserts returned ToolOutput contains ONLY extract_output-selected fields; any field leak FAILS the proptest. Follows VP-006-B pattern. §Proof Obligations: POL-31 live-violation obligation added (formal-verifier must confirm harness fails under injected-leak fixture at Phase 6). §Feasibility: Async concern row updated (harness calls invoke_dyn via tokio current-thread runtime). Input-hash refreshed to 90e3c45."
  - "1.1 (GAP-01/BC-2.09.008-authored/2026-08-26): BC-2.09.008 authored by PO. Named anchor {INV-STATE-ISOLATION} replaced with numeric ADR-027-compliant stable tag {INV-001} throughout (three occurrences: §Source Contract, §BC Traceability, and §Proof Obligations). BC-2.09.008 {INV-001} is the STATE-ISOLATION invariant. Input-hash refreshed."
  - "1.0 (GAP-01/ADR-029/2026-08-26): VP-016 created — STATE-ISOLATION invariant for GraphAgentTool; proptest P1 Phase 3; anchors BC-2.09.008 (PO to author); harness_fn `graph_agent_tool_state_isolation`; DI-010 Credential Opacity. Minted by architect per ADR-029 §Consequences."
---

# VP-016: GraphAgentTool State-Isolation — the Returned `serde_json::Value` Contains Only extract_output-Selected Fields

## Property Statement

For any `GraphAgentTool` construction with an `extract_output` closure that selects a
proper subset of fields from the non-generic `serde_json::Value` graph state, the
`serde_json::Value` returned by `GraphAgentTool::invoke_dyn` on successful graph completion
MUST contain only the JSON fields returned by `extract_output(&final_state)` — and NO fields
from `final_state` that were not selected by `extract_output`.

**Formal property (DI-010, ADR-029 §Decision 3 STATE-ISOLATION invariant):**

```
∀ initial_input: serde_json::Value valid against input_schema (caller-provided schemars::Schema),
∀ extract_output: Fn(&serde_json::Value) -> serde_json::Value,
∀ extra_field ∉ extract_output(&final_state_value).as_object().keys():

  // invoke_dyn return type: Result<serde_json::Value, PregolyaError>
  // (canonical DynTool contract per interface-definitions.md §Tool)
  let result: Result<serde_json::Value, PregolyaError> =
      GraphAgentTool::invoke_dyn(initial_input).await;
  match result {
    Ok(value) =>
        // value IS the serde_json::Value — no ToolOutput wrapper;
        // DynTool::invoke_dyn maps ToolOutput::Json/Text → Ok(serde_json::Value)
        value.as_object() does NOT contain extra_field
    Err(_) => property vacuously satisfied (no output produced)
  }
```

**Corollary:** No checkpoint ID, run ID, intermediate node output, accumulated message
history, or internal graph metadata field can appear in the `serde_json::Value` returned by
`invoke_dyn` unless `extract_output` explicitly constructs a `Value` containing it.

## Source Contract

- **BC:** BC-2.09.008 — StateGraph-as-MCP-Tool Wrapping (GraphAgentTool; mcp::graph_tool)
- **STATE-ISOLATION invariant {INV-001}:** `GraphAgentTool::invoke_dyn` returns
  ONLY the value from `extract_output(&final_state)`. No field from `final_state` beyond
  the `extract_output` selection, no checkpoint IDs, no run IDs, no intermediate node
  outputs, no graph metadata.
- **DI-010 (Credential Opacity):** External callers MUST NOT receive internal state that
  could carry credential material. STATE-ISOLATION is a structural superset of DI-010 for
  this boundary — correct `extract_output` scoping prevents credential-bearing fields from
  appearing in the output even without the `redact_credentials` step.

## BC Traceability

| BC | Title | Contribution |
|----|-------|-------------|
| BC-2.09.008 | StateGraph-as-MCP-Tool Wrapping | Primary VP obligation; {INV-001} state-isolation invariant — `serde_json::Value` return is structurally bounded by `extract_output` |

Specific anchors: BC-2.09.008 {INV-001} (only `extract_output(&final_state)` result
returned), {PC-004} (output extraction postcondition), TV-001 / EC-007 (happy-path
state-isolation test vectors: successful graph run returning `answer` field only; other
internal fields absent from response).

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| Property-based test | proptest | Unbounded over `serde_json::Value` graph states | For any generated `TestGraphState` instance (as `serde_json::Value`) with arbitrary extra fields, verify the `invoke_dyn` output contains only the fields selected by a fixed `extract_output` closure |

**Why proptest (not Kani):** The STATE-ISOLATION property ranges over `serde_json::Value`,
which is a recursive open data type. Kani's symbolic reasoning over unbounded JSON trees is
not tractable. Proptest generates concrete `TestGraphState` instances (serialized as `serde_json::Value`)
with arbitrary field values and verifies the containment property empirically across a large sample. The property is
structural ("output is a subset of extract_output result") — not an arithmetic invariant —
making proptest the appropriate tool.

**Why not Kani:** `extract_output` is an arbitrary closure provided by the caller, not a
fixed-signature function. Kani cannot reason symbolically over closure bodies in general.

## Proof Harness Skeleton

Target file: `pregolya-mcp/src/graph_tool.rs` (inside `#[cfg(test)] mod tests` block)

Harness function: `graph_agent_tool_state_isolation`

**FALSE-GREEN GUARD (two conditions enforced, F-P2A069-01 closure):**

**(1) invoke_dyn-bypass guard:** This harness exercises the REAL production path via
`from_graph`. The `stub_graph` produces a terminal `TestGraphState` carrying ALL four fields
including `checkpoint_id`, `run_id`, and `accumulated_messages`. `extract_output` runs INSIDE
`ConcreteGraphRunner::run` — NOT in `invoke_dyn` (ADR-029 §Decision 3 canonical seam
statement). If `ConcreteGraphRunner::run` returns raw terminal state instead of calling
`extract_output` (a leak-injected scenario), the extra fields appear in the `serde_json::Value`
returned by `invoke_dyn` and the `prop_assert!` checks FAIL.

**(2) vacuous-Err guard (§Realizability-Trace):** The harness input is produced via
`serde_json::to_value(&state).unwrap()` — a complete round-trip serialization of the
generated `TestGraphState` with ALL four required fields present. `CompiledStateGraph::invoke`
takes `serde_json::Value` directly (no `from_value::<S>` step — F-P2A072-03 closure; ADR-029
§Decision 2). A complete serialized input guarantees `stub_terminal`'s internal invoke path
succeeds for every generated case; the Ok-arm is always reached; the STATE-ISOLATION
`prop_assert!`s always execute. The `Err(_)` arm is a hard `prop_assert!(false, …)` guard —
`stub_terminal` always produces a clean terminal, so any Err is a harness infrastructure
failure, not a vacuous pass.

A harness using `json!({ "output": state.output })` (partial input, three fields missing)
would produce a partial channel-value JSON; `CompiledStateGraph::invoke` (or the stub's
internal logic) may return an Err or an incomplete value causing the FALSE-GREEN GUARD to
fire; all STATE-ISOLATION `prop_assert!`s would be unreachable; the harness would pass
vacuously. This was the F-P2A069-01 defect (rounds 5–8); the complete-input approach closes it.

A harness that tests only a locally-defined closure (bypassing the production runner) would
be tautological. This harness is non-tautological because `from_graph` binds the production
`ConcreteGraphRunner::run` execution path. Follows the same non-tautology pattern as VP-006-B.

**Harness resides in `#[cfg(test)] mod tests` inside `pregolya-mcp/src/graph_tool.rs`** so that:
- `pub(crate) GraphRunner` and `ConcreteGraphRunner` (non-generic) are visible (crate-internal
  visibility; F-P2A072-03: no generic `<S>` on the runner),
- `from_graph` can construct the production `ConcreteGraphRunner` (no test-only seam required —
  `from_graph` is the public API), and
- `CompiledStateGraph::stub_terminal` (from `pregolya-graph`, `#[cfg(test)]` only) is accessible
  as a dev-dependency (see §Proof Obligations "Stub Graph Obligation").

```rust
// pregolya-mcp/src/graph_tool.rs — #[cfg(test)] mod tests
// VP-016 — graph_agent_tool_state_isolation harness
//
// Canonical seam: STATE-ISOLATION is enforced solely by GraphRunner::run via
// extract_output(&final_state). GraphAgentTool::invoke_dyn performs no re-filtering.
// (ADR-029 §Decision 3 canonical seam statement — F-P2A066-01 closure.)
//
// POL-31 OBLIGATION (Phase 6): formal-verifier must confirm this harness FAILS under
// an injected-leak modification to ConcreteGraphRunner::run — see §Proof Obligations.

#[cfg(test)]
mod tests {
    use super::*;  // Sees pub(crate) GraphRunner, ConcreteGraphRunner, GraphAgentTool
    use pregolya_core::tool::DynTool;
    use pregolya_graph::CompiledStateGraph;  // stub_terminal is #[cfg(test)] on CompiledStateGraph
    use proptest::prelude::*;
    use proptest_derive::Arbitrary;
    use serde::{Deserialize, Serialize};
    use schemars::JsonSchema;
    use std::sync::Arc;

    /// Test graph-state value carrying an externally-visible `output` field PLUS three internal fields
    /// that extract_output must NOT select. Any of the three leaking into the `serde_json::Value`
    /// returned by `invoke_dyn` is a STATE-ISOLATION violation ({INV-001}).
    #[derive(Debug, Clone, Serialize, Deserialize, JsonSchema, Arbitrary)]
    struct TestGraphState {
        /// The only field exposed to the MCP client.
        output: String,
        /// Internal fields that MUST NOT appear in the `serde_json::Value` returned by `invoke_dyn`.
        #[proptest(strategy = "any::<String>()")]
        checkpoint_id: String,
        #[proptest(strategy = "any::<String>()")]
        run_id: String,
        #[proptest(strategy = "proptest::collection::vec(any::<String>(), 0..4)")]
        accumulated_messages: Vec<String>,
    }

    proptest! {
        /// VP-016 — STATE-ISOLATION ({INV-001}, BC-2.09.008): the production
        /// ConcreteGraphRunner::run calls extract_output(&final_state) before returning;
        /// invoke_dyn wraps the runner's already-filtered result without re-filtering.
        /// The stub graph emits the full TestGraphState with extra internal fields;
        /// ConcreteGraphRunner::run applies extract_output (selecting ONLY `output`);
        /// any leak of extra fields into the `serde_json::Value` returned by `invoke_dyn` FAILS the prop_assert! checks.
        #[test]
        fn graph_agent_tool_state_isolation(state in any::<TestGraphState>()) {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();

            rt.block_on(async {
                // Convert TestGraphState → serde_json::Value so it can feed the
                // non-generic CompiledStateGraph stub (ADR-029 §Decision 1 grounding:
                // CompiledStateGraph is non-generic; GraphState is not a trait).
                // All four fields (output, checkpoint_id, run_id, accumulated_messages)
                // are present in state_value — full serialization for F-P2A069-01 closure.
                let state_value = serde_json::to_value(&state).unwrap();

                // Build a stub CompiledStateGraph that emits `state_value` as terminal output.
                // (Stub Graph Obligation — see §Proof Obligations; test-writer implements
                // CompiledStateGraph::stub_terminal as #[cfg(test)] on CompiledStateGraph in
                // pregolya-graph — canonical type per BC-2.02.001 {PC-001}.)
                // The stub produces the full channel-value JSON — checkpoint_id, run_id,
                // and accumulated_messages are ALL present and MUST NOT appear in
                // the serde_json::Value returned by invoke_dyn after ConcreteGraphRunner::run
                // applies extract_output.
                let stub_graph: Arc<CompiledStateGraph> =
                    CompiledStateGraph::stub_terminal(state_value.clone());

                // Derive inputSchema from TestGraphState (caller's responsibility per
                // ADR-029 §Decision 2 grounding: CompiledStateGraph has no schema-introspection
                // method; schema is passed explicitly to from_graph).
                let input_schema: schemars::Schema = schemars::schema_for!(TestGraphState);

                // from_graph creates a ConcreteGraphRunner (non-generic) that stores
                // BOTH stub_graph (Arc<CompiledStateGraph>) AND the extract_output closure.
                // When ConcreteGraphRunner::run is called (via invoke_dyn), it:
                //   1. Calls CompiledStateGraph::invoke(input_value) → receives terminal
                //      serde_json::Value (channel-keyed map with all four fields)
                //   2. Calls (self.extract_output)(&final_state_value) → returns ONLY
                //      serde_json::json!({ "output": s["output"] })
                // invoke_dyn receives the already-filtered serde_json::Value and returns
                // Ok(filtered_value) directly — no ToolOutput::Structured wrapping.
                // This is the PRODUCTION isolation path per ADR-029 §Decision 3.
                let tool = GraphAgentTool::from_graph(
                    "test-agent".to_string(),
                    "VP-016 state-isolation test agent".to_string(),
                    stub_graph,
                    input_schema,
                    |s: &serde_json::Value| -> serde_json::Value {
                        serde_json::json!({ "output": s["output"] })
                    },
                );

                // Invoke via the REAL production path:
                // invoke_dyn → ConcreteGraphRunner::run → stub_graph terminal →
                //   extract_output(&final_state) → filtered serde_json::Value.
                //
                // COMPLETE INPUT (F-P2A069-01 closure): state_value contains all four required
                // fields. CompiledStateGraph::invoke receives a complete channel-value JSON.
                // Since there is no serde_json::from_value::<S> step (CompiledStateGraph takes
                // serde_json::Value directly — ADR-029 §Decision 2 grounding), every generated
                // case succeeds deserialization; the Ok-arm is always reached.
                let input = state_value.clone();
                let result = tool.invoke_dyn(input).await;

                match result {
                    Ok(tool_output) => {
                        // tool_output IS a serde_json::Value — invoke_dyn return type is
                        // Result<serde_json::Value, PregolyaError> per interface-definitions.md §Tool.
                        // No .as_value() call needed (F-P2A072-01 closure).
                        let obj = tool_output.as_object()
                            .expect("invoke_dyn result must be a JSON object for TestGraphState");

                        // Selected field must be present.
                        prop_assert!(obj.contains_key("output"),
                            "extract_output must include the `output` field");

                        // Extra internal fields must NOT appear — any leak FAILS VP-016.
                        prop_assert!(!obj.contains_key("checkpoint_id"),
                            "checkpoint_id must not appear in the `serde_json::Value` returned by `invoke_dyn` \
                             (STATE-ISOLATION {INV-001} violation)");
                        prop_assert!(!obj.contains_key("run_id"),
                            "run_id must not appear in the `serde_json::Value` returned by `invoke_dyn` \
                             (STATE-ISOLATION {INV-001} violation)");
                        prop_assert!(!obj.contains_key("accumulated_messages"),
                            "accumulated_messages must not appear in the `serde_json::Value` returned by `invoke_dyn` \
                             (STATE-ISOLATION {INV-001} violation)");

                        // Exact key-set check: the returned `serde_json::Value` must contain EXACTLY the
                        // extract_output-selected keys.
                        let keys: Vec<&str> = obj.keys().map(|k| k.as_str()).collect();
                        prop_assert_eq!(
                            keys, vec!["output"],
                            "the returned `serde_json::Value` must contain exactly the extract_output-selected keys; \
                             any extra key is a STATE-ISOLATION leak ({INV-001})"
                        );
                    }
                    Err(e) => {
                        // FALSE-GREEN GUARD (vacuous-Err, F-P2A069-01 + F-P2A072-03 closure):
                        // stub_terminal always produces a clean terminal; CompiledStateGraph::invoke
                        // takes serde_json::Value directly (no from_value::<S> step — F-P2A072-03).
                        // A complete input guarantees no invoke-level deserialization failure.
                        // Reaching this arm means a harness infrastructure failure —
                        // the STATE-ISOLATION prop_assert!s above did NOT execute; the
                        // prior vacuous-pass behaviour would have falsely confirmed VP-016.
                        // Fail explicitly so this can never be mistaken for a real proof.
                        // (See §Realizability Trace for the end-to-end path proof.)
                        prop_assert!(false,
                            "VP-016 FALSE-GREEN GUARD (vacuous-Err): invoke_dyn returned \
                             Err on a complete valid input. The Ok-arm was not reached; \
                             STATE-ISOLATION prop_assert!s did not execute. \
                             Error: {:?}. Investigate CompiledStateGraph::stub_terminal and \
                             ConcreteGraphRunner::run execution path.",
                            e
                        );
                    }
                }
            });
        }
    }
}
```

## Feasibility Assessment

**Feasibility: HIGH**

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space | Open (arbitrary `TestGraphState` as `serde_json::Value`) | proptest covers via `Arbitrary` derive |
| Proof complexity | Low | Structural containment check on JSON objects; no async, no I/O in the harness |
| Tool support | Supported | `proptest` + `proptest-derive`; no blocking dependencies |
| Async concern | Low | Harness calls `invoke_dyn` which is async; `tokio::runtime::Builder::new_current_thread()` wraps each proptest case; no actual I/O occurs (`CompiledStateGraph::stub_terminal` resolves synchronously — no network, no checkpoint I/O) |
| Estimated proof time | < 1s per proptest case | 10k cases × negligible per case |

No blocking risks. The `extract_output` closure must be extractable and callable outside the
async context of `GraphRunner::run` for the harness to work — this is guaranteed by the
`Fn(&serde_json::Value) -> serde_json::Value + Send + Sync + 'static` bound.

## Proof Obligations

- [x] **Stub Graph Obligation — SATISFIED (S-1.14 AC-014 / Task 18; round-10):**
  `CompiledStateGraph::stub_terminal` is specced in S-1.14 AC-014 and Task 18 (added
  round-10); implemented in `pregolya-graph/src/types.rs` as a `#[cfg(test)]` helper.
  `CompiledStateGraph` is the canonical non-generic compiled graph type (BC-2.02.001 {PC-001},
  `pregolya-graph/src/types.rs`). This constructor creates a minimal `CompiledStateGraph`
  whose single execution step returns `terminal_state` (a `serde_json::Value`) as the terminal
  channel-composed output — no real graph logic, no LLM calls, no checkpointing. NOT public
  API; `#[cfg(test)]` only. Enables `from_graph` to create a real `ConcreteGraphRunner`
  (non-generic) that exercises the production `(self.extract_output)(&final_state_value)` call
  path inside `ConcreteGraphRunner::run`. Consumed by VP-016 harness (BC-2.09.008 {INV-001})
  in S-2.11. ADR-029 §Symbol Grounding row is now ROUTED / SPECCED (round-12).
- [ ] `TestGraphState` derives `proptest_derive::Arbitrary` and `schemars::JsonSchema`
- [ ] `graph_agent_tool_state_isolation` proptest runs without shrinking failures for 10k cases
- [ ] `full_state_differs_from_extract_output` proptest confirms extract_output does not accidentally serialize the full struct
- [ ] BC-2.09.008 {INV-001} verified: `ConcreteGraphRunner::run` in `pregolya-mcp/src/graph_tool.rs` calls ONLY `(self.extract_output)(&final_state)` as the output source before returning `serde_json::Value` to `invoke_dyn` (code review; single call site in `ConcreteGraphRunner::run`; `invoke_dyn` performs no re-filtering per ADR-029 §Decision 3 canonical seam statement)
- [ ] **Canonical Seam Statement at call site:** `ConcreteGraphRunner::run` MUST contain an
  inline comment at the `extract_output` call site: "STATE-ISOLATION: extract_output is the
  sole data-exit path (BC-2.09.008 {INV-001}); invoke_dyn performs no re-filtering."
  Enables grep-based seam verification across review cycles.
- [ ] Integration test: register a graph with an `answer`-only `extract_output`; invoke via mock `mcp::server` `tools/call`; assert `CallToolResult.content[0].text` parses as JSON with only the `answer` key
- [ ] **POL-31 live-violation (Phase 6 gate — formal-verifier obligation):** The formal-verifier
  MUST confirm the harness FAILS when `ConcreteGraphRunner::run` is modified in an isolated
  injected-leak fixture to bypass the `extract_output` call — returning
  `final_state_value.clone()` directly instead of
  `(self.extract_output)(&final_state_value)`. Under this modification, the raw terminal
  channel-value JSON (including `checkpoint_id`, `run_id`, `accumulated_messages`) appears in
  the `serde_json::Value` returned by `invoke_dyn`, and the `prop_assert!` checks fail. A
  harness that passes under this leak-injection fixture is non-falsifiable and MUST be rejected
  before VP-016 can gate Phase 6.

## Realizability Trace

This trace is the load-bearing evidence that F-P2A069-01 is truly closed (not paper-closed).
It follows the 5-step mandate from the round-8 cycle-breaker.

**Representative generated case:** `state = TestGraphState { output: "ok", checkpoint_id: "chk-1", run_id: "run-1", accumulated_messages: ["m1"] }`.

**Step 1 — Input validation SUCCEEDS.**
`input = serde_json::to_value(&state).unwrap()` produces a JSON object with all four fields
present and correctly typed. JSON Schema validation passes (all required fields present).
`CompiledStateGraph::invoke` takes `serde_json::Value` directly (BC-2.02.001 {PC-005}) —
no `from_value::<TestGraphState>` deserialization step exists (F-P2A072-03 closure; ADR-029
§Decision 2). No `Err` is returned at this step.

**Step 2 — extract_output is called and returns only the selected fields.**
`ConcreteGraphRunner::run` executes `stub_graph` (via `stub_terminal`), which
returns `state_value.clone()` as the terminal `serde_json::Value`. `run` then calls
`(self.extract_output)(&final_state)` = `serde_json::json!({ "output": final_state["output"] })`.
The return value is `Ok(serde_json::Value::Object { "output": "ok" })`. Only `"output"` is
present; `checkpoint_id`, `run_id`, and `accumulated_messages` are absent.

**Step 3 — invoke_dyn returns without re-filtering.**
`GraphAgentTool::invoke_dyn` receives `Ok(json!({ "output": "ok" }))` from
`ConcreteGraphRunner::run`. It returns this `serde_json::Value` directly as
`Ok(json!({ "output": "ok" }))` without any further field selection, addition, or removal.
There is no `ToolOutput::Structured { value }` wrapping — `DynTool::invoke_dyn` return type is
`Result<serde_json::Value, PregolyaError>` (canonical per interface-definitions.md §Tool;
F-P2A072-02 closure). The ADR-029 §Decision 3 canonical seam statement holds: STATE-ISOLATION
is enforced solely in `ConcreteGraphRunner::run`; `invoke_dyn` is a pass-through wrapper.

**Step 4 — Ok-arm is reached; prop_assert!s execute.**
The harness enters the `Ok(tool_output)` arm. `tool_output` IS `json!({ "output": "ok" })` —
a `serde_json::Value` returned directly from `invoke_dyn` (no `.as_value()` call needed;
F-P2A072-01 closure). `tool_output.as_object()` returns a single-key map. All STATE-ISOLATION
assertions execute:
- `obj.contains_key("output")` → `true` — PASSES.
- `!obj.contains_key("checkpoint_id")` → `true` — PASSES.
- `!obj.contains_key("run_id")` → `true` — PASSES.
- `!obj.contains_key("accumulated_messages")` → `true` — PASSES.
- `keys == ["output"]` — PASSES.

This executes for EVERY generated `TestGraphState` case. The `Err` arm is NEVER reached under
normal operation; the `prop_assert!(false, …)` guard there is a dead-code safety net.

**Step 5 — Leak-injection variant makes an assertion FAIL.**
Modify `ConcreteGraphRunner::run` in an isolated fixture to bypass the `extract_output` call,
returning `final_state_value.clone()` directly instead of `(self.extract_output)(&final_state_value)`.
The Ok-arm is still reached. `tool_output.as_object()` now contains all four keys.
`prop_assert!(!obj.contains_key("checkpoint_id"), …)` evaluates to `prop_assert!(false, …)` — FAILS.
The test failure is reported. The harness is falsifiable; the POL-31 obligation is satisfiable.

**Conclusion — No reachable vacuous-Err path.**
With `input = state_value.clone()` (complete channel-value JSON), `CompiledStateGraph::invoke`
always succeeds; `stub_terminal` always returns a clean terminal state; `invoke_dyn` always
returns `Ok(serde_json::Value)`. There is no `from_value::<S>` deserialization step in the
non-generic design (F-P2A072-03). The `Err` arm is structurally unreachable under correct
harness operation. If it IS reached, the hard `prop_assert!(false, …)` guard fails the test
explicitly — the prior vacuous-pass behaviour is eliminated.

---

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-26 | architect |
| BC-2.09.008 authored (input hash refresh needed) | | product-owner |
| Proptest harness implemented | | test-writer |
| Harness passes | | implementer |
| Locked (VERIFIED) | | formal-verifier |
