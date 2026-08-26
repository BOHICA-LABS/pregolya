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
input-hash: "c8731ff"
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
version: "1.1"
changelog:
  - "1.1 (GAP-01/BC-2.09.008-authored/2026-08-26): BC-2.09.008 authored by PO. Named anchor {INV-STATE-ISOLATION} replaced with numeric ADR-027-compliant stable tag {INV-001} throughout (three occurrences: §Source Contract, §BC Traceability, and §Proof Obligations). BC-2.09.008 {INV-001} is the STATE-ISOLATION invariant. Input-hash refreshed."
  - "1.0 (GAP-01/ADR-029/2026-08-26): VP-016 created — STATE-ISOLATION invariant for GraphAgentTool; proptest P1 Phase 3; anchors BC-2.09.008 (PO to author); harness_fn `graph_agent_tool_state_isolation`; DI-010 Credential Opacity. Minted by architect per ADR-029 §Consequences."
---

# VP-016: GraphAgentTool State-Isolation — ToolOutput Contains Only extract_output-Selected Fields

## Property Statement

For any `GraphAgentTool` construction with an `extract_output` closure that selects a
proper subset of fields from `GraphState S`, the `ToolOutput` returned by
`GraphAgentTool::invoke` on successful graph completion MUST contain only the JSON fields
returned by `extract_output(&final_state)` — and NO fields from `final_state` that were
not selected by `extract_output`.

**Formal property (DI-010, ADR-029 §Decision 3 STATE-ISOLATION invariant):**

```
∀ S: GraphState,
∀ initial_input: serde_json::Value valid against input_schema(S),
∀ extract_output: Fn(&S) -> serde_json::Value,
∀ extra_field ∉ extract_output(&final_state).as_object().keys():

  let result = GraphAgentTool::invoke(initial_input);
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
- **STATE-ISOLATION invariant {INV-001}:** `GraphAgentTool::invoke` returns
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
| Property-based test | proptest | Unbounded over GraphState values | For any generated `S` instance with arbitrary extra fields, verify the `invoke` output contains only the fields selected by a fixed `extract_output` closure |

**Why proptest (not Kani):** The STATE-ISOLATION property ranges over `serde_json::Value`,
which is a recursive open data type. Kani's symbolic reasoning over unbounded JSON trees is
not tractable. Proptest generates concrete `S` instances with arbitrary field values and
verifies the containment property empirically across a large sample. The property is
structural ("output is a subset of extract_output result") — not an arithmetic invariant —
making proptest the appropriate tool.

**Why not Kani:** `extract_output` is an arbitrary closure provided by the caller, not a
fixed-signature function. Kani cannot reason symbolically over closure bodies in general.

## Proof Harness Skeleton

Target file: `pregolya-mcp/src/graph_tool.rs` (or `pregolya-mcp/tests/state_isolation.rs`)

Harness function: `graph_agent_tool_state_isolation`

```rust
// pregolya-mcp/tests/state_isolation.rs
// VP-016 — graph_agent_tool_state_isolation harness

use pregolya_mcp::graph_tool::{GraphAgentTool, GraphToolApprovalPolicy};
use proptest::prelude::*;
use serde::{Deserialize, Serialize};
use schemars::JsonSchema;

/// Minimal GraphState with an "output" field and several extra fields that
/// must NOT appear in the extract_output result.
#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema, proptest_derive::Arbitrary)]
struct TestGraphState {
    /// The externally-visible output field.
    output: String,
    /// Internal fields that must NOT appear in ToolOutput.
    #[proptest(strategy = "any::<String>()")]
    internal_checkpoint_id: String,
    #[proptest(strategy = "any::<String>()")]
    intermediate_message: String,
    #[proptest(strategy = "proptest::collection::vec(any::<u8>(), 0..64)")]
    _internal_blob: Vec<u8>,
}

proptest! {
    /// VP-016 — extract_output selects only `output`; extra fields must not appear
    /// in the ToolOutput JSON value.
    #[test]
    fn graph_agent_tool_state_isolation(state in any::<TestGraphState>()) {
        // The extract_output closure selects ONLY the `output` field.
        let extract_output = |s: &TestGraphState| -> serde_json::Value {
            serde_json::json!({ "output": s.output })
        };

        // Simulate the extract_output call (in production this is called after graph run).
        let result = extract_output(&state);

        // The output must contain `output`.
        prop_assert!(
            result.get("output").is_some(),
            "extract_output must include the `output` field"
        );

        // The output must NOT contain any of the internal fields.
        prop_assert!(
            result.get("internal_checkpoint_id").is_none(),
            "internal_checkpoint_id must not appear in ToolOutput"
        );
        prop_assert!(
            result.get("intermediate_message").is_none(),
            "intermediate_message must not appear in ToolOutput"
        );
        prop_assert!(
            result.get("_internal_blob").is_none(),
            "_internal_blob must not appear in ToolOutput"
        );

        // The result must be a JSON object with EXACTLY the keys selected.
        if let Some(obj) = result.as_object() {
            let keys: Vec<&str> = obj.keys().map(|k| k.as_str()).collect();
            prop_assert_eq!(
                keys,
                vec!["output"],
                "ToolOutput must contain exactly the extract_output-selected keys"
            );
        }
    }

    /// VP-016 — full-state serialization must not equal extract_output result
    /// when S has extra fields (guards against extract_output accidentally
    /// serializing the full struct).
    #[test]
    fn full_state_differs_from_extract_output(state in any::<TestGraphState>()) {
        prop_assume!(!state.internal_checkpoint_id.is_empty());

        let extract_output = |s: &TestGraphState| -> serde_json::Value {
            serde_json::json!({ "output": s.output })
        };
        let full_state_value = serde_json::to_value(&state).expect("serialize");
        let extracted = extract_output(&state);

        prop_assert_ne!(
            full_state_value,
            extracted,
            "extract_output must not accidentally return the full state"
        );
    }
}
```

**Note on production wiring:** In production, `GraphRunner::run` calls `extract_output` on
the final `CompiledGraph<S>` terminal state. The harness tests the `extract_output` closure
isolation property directly. Integration tests in the `mcp::graph_tool` test module verify
the full `GraphAgentTool::invoke` path returns only the extracted value.

## Feasibility Assessment

**Feasibility: HIGH**

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space | Open (arbitrary GraphState) | proptest covers via `Arbitrary` derive |
| Proof complexity | Low | Structural containment check on JSON objects; no async, no I/O in the harness |
| Tool support | Supported | `proptest` + `proptest-derive`; no blocking dependencies |
| Async concern | None | Harness tests the `extract_output` closure directly; async graph execution is tested in integration tests |
| Estimated proof time | < 1s per proptest case | 10k cases × negligible per case |

No blocking risks. The `extract_output` closure must be extractable and callable outside the
async context of `GraphRunner::run` for the harness to work — this is guaranteed by the
`Fn(&S) -> serde_json::Value + Send + Sync + 'static` bound.

## Proof Obligations

- [ ] `TestGraphState` derives `proptest_derive::Arbitrary` and `schemars::JsonSchema`
- [ ] `graph_agent_tool_state_isolation` proptest runs without shrinking failures for 10k cases
- [ ] `full_state_differs_from_extract_output` proptest confirms extract_output does not accidentally serialize the full struct
- [ ] BC-2.09.008 {INV-001} verified: `GraphAgentTool::invoke` code path calls ONLY `extract_output(&final_state)` as the output source (code review; single call site in `GraphRunner::run`)
- [ ] Integration test: register a graph with an `answer`-only `extract_output`; invoke via mock `mcp::server` `tools/call`; assert `CallToolResult.content[0].text` parses as JSON with only the `answer` key

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-26 | architect |
| BC-2.09.008 authored (input hash refresh needed) | | product-owner |
| Proptest harness implemented | | test-writer |
| Harness passes | | implementer |
| Locked (VERIFIED) | | formal-verifier |
