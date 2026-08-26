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
version: "1.3"
changelog:
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

**FALSE-GREEN GUARD:** This harness calls `GraphAgentTool::invoke_dyn` (the real production
path), NOT a locally-defined closure. `MockGraphRunner` returns a terminal `GraphState`
carrying EXTRA fields (`checkpoint_id`, `run_id`, `accumulated_messages`) that `extract_output`
does NOT select. If `invoke_dyn` leaks any of those fields into `ToolOutput`, the
`prop_assert!` calls below will FAIL. A tautological harness that only tests a local closure
would pass even if production code leaks state — this harness does not. Contrast: VP-006-B
calls production `check_fewshot_trust` — this harness follows the same pattern for the
STATE-ISOLATION boundary.

**Harness resides in `#[cfg(test)] mod tests` inside `pregolya-mcp/src/graph_tool.rs`** so that:
- `pub(crate) GraphRunner` is visible (crate-internal visibility; E0603 is avoided),
- The `#[cfg(test)]`-gated `GraphAgentTool::from_runner::<S>` constructor seam is
  accessible (defined via `#[cfg(test)] impl GraphAgentTool` in the same file — see
  §Proof Obligations "Test Seam Obligation"), and
- The `extract_output` closure uses the correct `Fn(&TestGraphState) -> serde_json::Value`
  type per the `Fn(&S) -> serde_json::Value` contract, not `Fn(&serde_json::Value)`.

```rust
// pregolya-mcp/src/graph_tool.rs — #[cfg(test)] mod tests
// VP-016 — graph_agent_tool_state_isolation harness
//
// Invariant: ToolOutput contains ONLY the fields returned by extract_output.
// POL-31 OBLIGATION (Phase 6): formal-verifier must confirm this harness FAILS under
// an injected-leak fixture — see §Proof Obligations.

#[cfg(test)]
mod tests {
    use super::*;  // Sees pub(crate) GraphRunner, GraphAgentTool, GraphToolApprovalPolicy
    use pregolya_core::tool::DynTool;
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

    /// Test double — returns the full serialized TestGraphState as the runner output,
    /// including ALL internal fields. The extra fields simulate internal graph state that
    /// must be filtered by extract_output before reaching ToolOutput. If invoke_dyn bypasses
    /// extract_output, the extra fields leak and the harness FAILS.
    struct MockGraphRunner {
        /// Pre-serialized terminal state; includes ALL TestGraphState fields.
        terminal_state: serde_json::Value,
    }

    #[async_trait::async_trait]
    impl GraphRunner for MockGraphRunner {
        // GraphRunner is pub(crate) — visible here because this mod is inside
        // pregolya-mcp/src/graph_tool.rs (crate-internal, not an integration test).
        async fn run(
            &self,
            _input: serde_json::Value,
            _policy: &GraphToolApprovalPolicy,
        ) -> Result<serde_json::Value, pregolya_core::error::PregolyaError> {
            // Returns ALL fields — extract_output in invoke_dyn is the isolation gate.
            Ok(self.terminal_state.clone())
        }
    }

    proptest! {
        /// VP-016 — STATE-ISOLATION ({INV-001}, BC-2.09.008): GraphAgentTool::invoke_dyn
        /// returns ONLY extract_output-selected fields; extra fields in the runner terminal
        /// state must not leak into ToolOutput.
        #[test]
        fn graph_agent_tool_state_isolation(state in any::<TestGraphState>()) {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();

            rt.block_on(async {
                let full_state_value = serde_json::to_value(&state)
                    .expect("TestGraphState must serialize");

                // Build GraphAgentTool via the #[cfg(test)]-gated from_runner seam
                // (defined in `#[cfg(test)] impl GraphAgentTool` in this file — see
                // §Proof Obligations "Test Seam Obligation").
                // extract_output: Fn(&TestGraphState) -> serde_json::Value — correct type.
                // Selects ONLY the `output` field; all other fields are state-isolated.
                let tool = GraphAgentTool::from_runner::<TestGraphState>(
                    "test-agent".to_string(),
                    "VP-016 state-isolation test agent".to_string(),
                    Arc::new(MockGraphRunner { terminal_state: full_state_value }),
                    |state: &TestGraphState| -> serde_json::Value {
                        serde_json::json!({ "output": state.output })
                    },
                );

                // Invoke the REAL production path (invoke_dyn) — not a local closure.
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

                        // Exact key-set check: output must contain EXACTLY the selected keys.
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
| Async concern | Low | Harness calls `invoke_dyn` which is async; `tokio::runtime::Builder::new_current_thread()` wraps each proptest case; no actual I/O occurs (MockGraphRunner resolves synchronously in practice) |
| Estimated proof time | < 1s per proptest case | 10k cases × negligible per case |

No blocking risks. The `extract_output` closure must be extractable and callable outside the
async context of `GraphRunner::run` for the harness to work — this is guaranteed by the
`Fn(&S) -> serde_json::Value + Send + Sync + 'static` bound.

## Proof Obligations

- [ ] **Test Seam Obligation:** `pregolya-mcp/src/graph_tool.rs` MUST contain a
  `#[cfg(test)] impl GraphAgentTool` block that defines
  `from_runner::<S>(name: String, description: String, runner: Arc<dyn GraphRunner>, extract_output: impl Fn(&S) -> serde_json::Value + Send + Sync + 'static) -> Self`
  where `S: for<'de> serde::Deserialize<'de> + schemars::JsonSchema + Send + Sync + 'static`.
  This seam is NOT public API (no `pub`; `#[cfg(test)]` only). The seam reuses the
  `GraphRunner` trait directly (bypassing the `CompiledGraph<S>` wrapper used by
  `from_graph`) to enable MockGraphRunner injection. Comparable to VP-006-B's obligation
  that `check_fewshot_trust` is an extracted pure function; this seam is the equivalent
  test entry point for the STATE-ISOLATION path.
- [ ] `TestGraphState` derives `proptest_derive::Arbitrary` and `schemars::JsonSchema`
- [ ] `graph_agent_tool_state_isolation` proptest runs without shrinking failures for 10k cases
- [ ] `full_state_differs_from_extract_output` proptest confirms extract_output does not accidentally serialize the full struct
- [ ] BC-2.09.008 {INV-001} verified: `GraphAgentTool::invoke_dyn` code path calls ONLY `extract_output(&final_state)` as the output source (code review; single call site in `GraphRunner::run`)
- [ ] Integration test: register a graph with an `answer`-only `extract_output`; invoke via mock `mcp::server` `tools/call`; assert `CallToolResult.content[0].text` parses as JSON with only the `answer` key
- [ ] **POL-31 live-violation (Phase 6 gate — formal-verifier obligation):** The formal-verifier
  MUST confirm the harness FAILS when a leak-injected `MockGraphRunner` is used that returns
  the full serialized `TestGraphState` (including `checkpoint_id`, `run_id`,
  `accumulated_messages`) AND `invoke_dyn` is patched to bypass `extract_output` (returning
  raw runner output directly). A harness that passes on this injected-leak fixture is
  non-falsifiable and MUST be rejected as tautological before VP-016 can gate Phase 6.

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-26 | architect |
| BC-2.09.008 authored (input hash refresh needed) | | product-owner |
| Proptest harness implemented | | test-writer |
| Harness passes | | implementer |
| Locked (VERIFIED) | | formal-verifier |
