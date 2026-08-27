---
document_type: verification-property
level: L4
vp_id: VP-016
title: "GraphAgentTool State-Isolation — ToolOutput Contains Only extract_output-Selected Fields (No Internal Graph State Leak)"
status: draft
producer: architect
timestamp: 2026-08-26T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.008.md
input-hash: "90e3c45"
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
version: "1.4"
changelog:
  - "1.4 (round-7/F-P2A066-01/2026-08-26): F-P2A066-01 HIGH (seam contradiction closed). Option A adopted per authoritative carriers (BC-2.09.008 {PC-004}, ADR-029 §Decision 3): STATE-ISOLATION is enforced solely by GraphRunner::run via extract_output, NOT by invoke_dyn. §Proof Harness Skeleton rewritten: from_runner/MockGraphRunner approach replaced by from_graph/stub-graph approach; from_graph creates a real ConcreteGraphRunner<TestGraphState> that calls extract_output inside run(); stub_graph (CompiledGraph::stub_terminal) emits the full TestGraphState with extra fields; invoke_dyn wraps the runner's already-filtered result. FALSE-GREEN GUARD updated for Option A. Test Seam Obligation replaced with Stub Graph Obligation (CompiledGraph::stub_terminal). BC-2.09.008 {INV-001} code-review obligation updated to ConcreteGraphRunner::run call site. POL-31 rewritten: removed architecturally-impossible 'patch invoke_dyn to bypass extract_output'; new POL-31 requires formal-verifier to confirm harness FAILS when ConcreteGraphRunner::run bypasses extract_output call. Canonical Seam Statement obligation added. ADR-029 §Decision 3 receives parallel canonical seam statement (same burst)."
  - "1.3 (round-6/F-064-02+O-063-02/2026-08-26): F-064-02 HIGH (triple-confirmed) — §Proof Harness Skeleton: harness relocated from non-compilable integration test path (pregolya-mcp/tests/state_isolation.rs) to IN-CRATE #[cfg(test)] mod tests inside pregolya-mcp/src/graph_tool.rs. Three non-realizability defects fixed: (1) from_runner call now references the #[cfg(test)]-gated constructor seam on GraphAgentTool defined in the same file — not a phantom public API; (2) pub(crate) GraphRunner is reachable inside the crate's own cfg(test) block — E0603 eliminated; (3) extract_output closure corrected from Fn(&serde_json::Value) to Fn(&TestGraphState) -> serde_json::Value per the Fn(&S) -> serde_json::Value contract. 'Target file' line updated to pregolya-mcp/src/graph_tool.rs. §Proof Obligations: explicit §Test Seam Obligation added (impl GraphAgentTool::from_runner<S> must exist under #[cfg(test)] in graph_tool.rs; seam is NOT public). Harness remains load-bearing: MockGraphRunner returns full TestGraphState with EXTRA internal fields; ToolOutput key-set must equal exactly {'output'}; any field leak FAILS. O-063-02 OBS — normalize invoke→invoke_dyn in §Property Statement, formal property, §Source Contract {INV-001} paragraph, §Proof Method table, §Proof Obligations code-review obligation (three occurrences). Input-hash unchanged (source BC unchanged)."
  - "1.2 (P2A-062/2026-08-26): F-P2A-061-01 HIGH — §Proof Harness Skeleton rewritten to invoke the real production path (GraphAgentTool::invoke_dyn via MockGraphRunner test double) rather than a tautological local closure. Harness constructs GraphAgentTool over MockGraphRunner whose terminal state carries checkpoint_id/run_id/accumulated_messages beyond what extract_output selects; asserts returned ToolOutput contains ONLY extract_output-selected fields; any field leak FAILS the proptest. Follows VP-006-B pattern. §Proof Obligations: POL-31 live-violation obligation added (formal-verifier must confirm harness fails under injected-leak fixture at Phase 6). §Feasibility: Async concern row updated (harness calls invoke_dyn via tokio current-thread runtime). Input-hash refreshed to 90e3c45."
  - "1.1 (GAP-01/BC-2.09.008-authored/2026-08-26): BC-2.09.008 authored by PO. Named anchor {INV-STATE-ISOLATION} replaced with numeric ADR-027-compliant stable tag {INV-001} throughout (three occurrences: §Source Contract, §BC Traceability, and §Proof Obligations). BC-2.09.008 {INV-001} is the STATE-ISOLATION invariant. Input-hash refreshed."
  - "1.0 (GAP-01/ADR-029/2026-08-26): VP-016 created — STATE-ISOLATION invariant for GraphAgentTool; proptest P1 Phase 3; anchors BC-2.09.008 (PO to author); harness_fn `graph_agent_tool_state_isolation`; DI-010 Credential Opacity. Minted by architect per ADR-029 §Consequences."
---

# VP-016: GraphAgentTool State-Isolation — ToolOutput Contains Only extract_output-Selected Fields

## Property Statement

For any `GraphAgentTool` construction with an `extract_output` closure that selects a
proper subset of fields from `GraphState S`, the `ToolOutput` returned by
`GraphAgentTool::invoke_dyn` on successful graph completion MUST contain only the JSON fields
returned by `extract_output(&final_state)` — and NO fields from `final_state` that were
not selected by `extract_output`.

**Formal property (DI-010, ADR-029 §Decision 3 STATE-ISOLATION invariant):**

```
∀ S: GraphState,
∀ initial_input: serde_json::Value valid against input_schema(S),
∀ extract_output: Fn(&S) -> serde_json::Value,
∀ extra_field ∉ extract_output(&final_state).as_object().keys():

  let result = GraphAgentTool::invoke_dyn(initial_input);
  match result {
    Ok(ToolOutput::Structured { value }) =>
        value.as_object() does NOT contain extra_field
    Ok(ToolOutput::Text { text }) =>
        // text is already a string — not a JSON object;
        // this arm is structurally bounded by extract_output returning Value::String
    Err(_) => property vacuously satisfied (no output produced)
  }
```

**Corollary:** No checkpoint ID, run ID, intermediate node output, accumulated message
history, or internal graph metadata field can appear in the `ToolOutput` unless
`extract_output` explicitly constructs a `Value` containing it.

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
| BC-2.09.008 | StateGraph-as-MCP-Tool Wrapping | Primary VP obligation; {INV-001} state-isolation invariant — `ToolOutput` is structurally bounded by `extract_output` |

Specific anchors: BC-2.09.008 {INV-001} (only `extract_output(&final_state)` result
returned), {PC-004} (output extraction postcondition), EC-TV-1 (happy-path state isolation
test vector: graph with `answer` field only; other fields absent from response).

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| Property-based test | proptest | Unbounded over GraphState values | For any generated `S` instance with arbitrary extra fields, verify the `invoke_dyn` output contains only the fields selected by a fixed `extract_output` closure |

**Why proptest (not Kani):** The STATE-ISOLATION property ranges over `serde_json::Value`,
which is a recursive open data type. Kani's symbolic reasoning over unbounded JSON trees is
not tractable. Proptest generates concrete `S` instances with arbitrary field values and
verifies the containment property empirically across a large sample. The property is
structural ("output is a subset of extract_output result") — not an arithmetic invariant —
making proptest the appropriate tool.

**Why not Kani:** `extract_output` is an arbitrary closure provided by the caller, not a
fixed-signature function. Kani cannot reason symbolically over closure bodies in general.

## Proof Harness Skeleton

Target file: `pregolya-mcp/src/graph_tool.rs` (inside `#[cfg(test)] mod tests` block)

Harness function: `graph_agent_tool_state_isolation`

**FALSE-GREEN GUARD:** This harness exercises the REAL production path via `from_graph`.
The `stub_graph` (see Stub Graph Obligation in §Proof Obligations) produces a terminal
`TestGraphState` carrying ALL four fields including `checkpoint_id`, `run_id`, and
`accumulated_messages`. `extract_output` runs INSIDE `ConcreteGraphRunner::run` — NOT in
`invoke_dyn` (ADR-029 §Decision 3 canonical seam statement). If `ConcreteGraphRunner::run`
returns raw terminal state instead of calling `extract_output` (a leak-injected scenario),
the extra fields appear in `ToolOutput` and the `prop_assert!` checks FAIL. A harness that
tests only a locally-defined closure (bypassing the production runner) would be tautological.
This harness is non-tautological because `from_graph` binds the production
`ConcreteGraphRunner::run` execution path. Follows the same non-tautology pattern as VP-006-B.

**Harness resides in `#[cfg(test)] mod tests` inside `pregolya-mcp/src/graph_tool.rs`** so that:
- `pub(crate) GraphRunner` and `ConcreteGraphRunner<S>` are visible (crate-internal visibility),
- `from_graph` can construct the production `ConcreteGraphRunner<TestGraphState>` (no
  test-only seam required for the tool construction itself — `from_graph` is the public API), and
- `CompiledGraph::stub_terminal` (from `pregolya-graph`, `#[cfg(test)]` only) is accessible
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
    use pregolya_graph::CompiledGraph;  // stub_terminal is #[cfg(test)] on CompiledGraph
    use proptest::prelude::*;
    use proptest_derive::Arbitrary;
    use serde::{Deserialize, Serialize};
    use schemars::JsonSchema;
    use std::sync::Arc;

    /// GraphState carrying an externally-visible `output` field PLUS three internal fields
    /// that extract_output must NOT select. Any of the three leaking into ToolOutput is a
    /// STATE-ISOLATION violation ({INV-001}).
    #[derive(Debug, Clone, Serialize, Deserialize, JsonSchema, Arbitrary)]
    struct TestGraphState {
        /// The only field exposed to the MCP client.
        output: String,
        /// Internal fields that MUST NOT appear in ToolOutput.
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
        /// any leak of extra fields into ToolOutput FAILS the prop_assert! checks.
        #[test]
        fn graph_agent_tool_state_isolation(state in any::<TestGraphState>()) {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();

            rt.block_on(async {
                // Build a stub CompiledGraph that emits `state` as terminal output.
                // (Stub Graph Obligation — see §Proof Obligations; test-writer implements
                // CompiledGraph::stub_terminal as #[cfg(test)] on CompiledGraph in
                // pregolya-graph.)
                // The stub produces the full TestGraphState — checkpoint_id, run_id,
                // and accumulated_messages are ALL present and MUST NOT appear in
                // ToolOutput after ConcreteGraphRunner::run applies extract_output.
                let stub_graph: Arc<CompiledGraph<TestGraphState>> =
                    CompiledGraph::stub_terminal(state.clone());

                // from_graph creates a ConcreteGraphRunner<TestGraphState> that stores
                // BOTH stub_graph AND the extract_output closure internally.
                // When ConcreteGraphRunner::run is called (via invoke_dyn), it:
                //   1. Executes stub_graph → receives terminal TestGraphState
                //   2. Calls (self.extract_output)(&final_state) → returns ONLY
                //      serde_json::json!({ "output": s.output })
                // invoke_dyn receives the already-filtered serde_json::Value and wraps
                // it in ToolOutput::Structured without further modification.
                // This is the PRODUCTION isolation path per ADR-029 §Decision 3.
                let tool = GraphAgentTool::from_graph(
                    "test-agent".to_string(),
                    "VP-016 state-isolation test agent".to_string(),
                    stub_graph,
                    |s: &TestGraphState| -> serde_json::Value {
                        serde_json::json!({ "output": s.output })
                    },
                );

                // Invoke via the REAL production path:
                // invoke_dyn → ConcreteGraphRunner::run → stub_graph terminal →
                //   extract_output(&final_state) → filtered serde_json::Value.
                let input = serde_json::json!({ "output": state.output });
                let result = tool.invoke_dyn(input).await;

                match result {
                    Ok(tool_output) => {
                        let value = tool_output.as_value();
                        let obj = value.as_object()
                            .expect("ToolOutput must be a JSON object for TestGraphState");

                        // Selected field must be present.
                        prop_assert!(obj.contains_key("output"),
                            "extract_output must include the `output` field");

                        // Extra internal fields must NOT appear — any leak FAILS VP-016.
                        prop_assert!(!obj.contains_key("checkpoint_id"),
                            "checkpoint_id must not appear in ToolOutput \
                             (STATE-ISOLATION {INV-001} violation)");
                        prop_assert!(!obj.contains_key("run_id"),
                            "run_id must not appear in ToolOutput \
                             (STATE-ISOLATION {INV-001} violation)");
                        prop_assert!(!obj.contains_key("accumulated_messages"),
                            "accumulated_messages must not appear in ToolOutput \
                             (STATE-ISOLATION {INV-001} violation)");

                        // Exact key-set check: ToolOutput must contain EXACTLY the
                        // extract_output-selected keys.
                        let keys: Vec<&str> = obj.keys().map(|k| k.as_str()).collect();
                        prop_assert_eq!(
                            keys, vec!["output"],
                            "ToolOutput must contain exactly the extract_output-selected keys; \
                             any extra key is a STATE-ISOLATION leak ({INV-001})"
                        );
                    }
                    Err(_) => {
                        // Err path satisfies VP-016 vacuously — no ToolOutput produced.
                        // Binary interrupt invariant ({INV-002}) is covered by the Red-Gate
                        // test set (BC-2.09.008 TV-002/TV-005, S-2.11 AC-024).
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
| Input space | Open (arbitrary GraphState) | proptest covers via `Arbitrary` derive |
| Proof complexity | Low | Structural containment check on JSON objects; no async, no I/O in the harness |
| Tool support | Supported | `proptest` + `proptest-derive`; no blocking dependencies |
| Async concern | Low | Harness calls `invoke_dyn` which is async; `tokio::runtime::Builder::new_current_thread()` wraps each proptest case; no actual I/O occurs (`CompiledGraph::stub_terminal` resolves synchronously — no network, no checkpoint I/O) |
| Estimated proof time | < 1s per proptest case | 10k cases × negligible per case |

No blocking risks. The `extract_output` closure must be extractable and callable outside the
async context of `GraphRunner::run` for the harness to work — this is guaranteed by the
`Fn(&S) -> serde_json::Value + Send + Sync + 'static` bound.

## Proof Obligations

- [ ] **Stub Graph Obligation:** A `#[cfg(test)]` constructor
  `CompiledGraph::<S>::stub_terminal(state: S) -> Arc<CompiledGraph<S>>` MUST be implemented
  in `pregolya-graph` (exact module location at test-writer discretion). This constructor
  creates a minimal `CompiledGraph<S>` whose single execution step returns `state` as the
  terminal output — no real graph logic, no LLM calls, no checkpointing. NOT public API;
  `#[cfg(test)]` only. Enables `from_graph` to create a real `ConcreteGraphRunner<S>` that
  exercises the production `(self.extract_output)(&final_state)` call path inside
  `ConcreteGraphRunner::run`. This replaces the retired `from_runner` seam (v1.3 and earlier)
  which exercised the wrong architecture (Option B, isolation in `invoke_dyn`).
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
  `serde_json::to_value(&final_state).unwrap()` directly instead of
  `(self.extract_output)(&final_state)`. Under this modification, the raw terminal state
  (including `checkpoint_id`, `run_id`, `accumulated_messages`) appears in `ToolOutput` and
  the `prop_assert!` checks fail. A harness that passes under this leak-injection fixture is
  non-falsifiable and MUST be rejected before VP-016 can gate Phase 6.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-26 | architect |
| BC-2.09.008 authored (input hash refresh needed) | | product-owner |
| Proptest harness implemented | | test-writer |
| Harness passes | | implementer |
| Locked (VERIFIED) | | formal-verifier |
