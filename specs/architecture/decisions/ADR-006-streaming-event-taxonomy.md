---
document_type: adr
level: L3
adr_id: "006"
slug: streaming-event-taxonomy
title: "Streaming Event Taxonomy (CONFLICT-5: typed enum vs stringly-typed)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17]
changelog:
  - "rev-1 (ADV-P1D-PASS-29): F-P29-04 rewrite StreamEvent enum to 11 imperative variants (RunStart/Stream/End, StepStart/End, NodeStart/Stream/End, ToolStart/Stream/End) matching BC-2.06.001 lines ~55-65; add NodeStream and ToolStream variants that were missing from rev-0. Wire tokens corrected to snake_case imperative (run_start not run_started). F-P29-05 remove LangChain astream_events v2 wire-compat claim — wire format is ferrochain-native per D13 (consistent with BC-2.06.001 line ~39 and BC-2.12.003 line ~37). Past-tense variant names (RunStarted, NodeStarted, etc.) added to retired-identifier registry."
---

# ADR-006: Streaming Event Taxonomy

**Status:** Accepted

## Context

CONFLICT-5: LangGraph Python emits streaming events as untyped string dictionaries
(`{"event": "on_chain_start", "data": {...}}`). adk-rust emits typed enums per event
category. D17 HYBRID mandate: LangGraph API surface + adk-rust internal quality patterns.

The question is how to represent streaming events in ferrochain's public API:
typed Rust enum (adk-rust pattern) or stringly-typed map (LangGraph Python pattern).

## Decision: Typed Enum in Rust API; JSON-serialized to LangGraph format over HTTP

**Internal representation (ferrochain-core):**

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "event", rename_all = "snake_case")]
pub enum StreamEvent {
    // Run lifecycle (wire: run_start, run_stream, run_end)
    RunStart  { run_id: RunId, parent_ids: Vec<RunId>, data: RunStartData },
    RunStream { run_id: RunId, parent_ids: Vec<RunId>, data: ChunkData },
    RunEnd    { run_id: RunId, parent_ids: Vec<RunId>, data: RunEndData },
    // Super-step lifecycle (wire: step_start, step_end)
    StepStart { run_id: RunId, parent_ids: Vec<RunId>, step: u32 },
    StepEnd   { run_id: RunId, parent_ids: Vec<RunId>, step: u32 },
    // Node lifecycle (wire: node_start, node_stream, node_end)
    NodeStart  { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: NodeData },
    NodeStream { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: ChunkData },
    NodeEnd    { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: NodeData },
    // Tool lifecycle (wire: tool_start, tool_stream, tool_end)
    ToolStart  { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
    ToolStream { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ChunkData },
    ToolEnd    { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
}
```

Authority: **BC-2.06.001** is the canonical source for variant names and wire tokens. Variant names are **imperative** (RunStart, StepStart, NodeStream, ToolEnd, etc.). Wire tokens are snake_case imperative: `run_start`, `run_stream`, `run_end`, `step_start`, `step_end`, `node_start`, `node_stream`, `node_end`, `tool_start`, `tool_stream`, `tool_end`.

**Over HTTP (ferrochain-server SSE):** Events serialize to JSON with `#[serde(tag = "event")]`,
producing ferrochain-native wire format `{"event": "run_start", "data": {...}}` (BC-2.06.001). Wire format is **ferrochain-native per D13** — LangChain Python `.astream_events()` v2 wire compatibility is NOT claimed or guaranteed. (F-P29-05: removed prior LangGraph-compat claim that contradicted D13.)

**Why typed enum:**
- Compile-time exhaustiveness: adding a new event variant forces handling in all match sites.
- `run_id + parent_ids` is present on every variant (BC-2.06.002) — enforced by struct layout.
- Streaming / unary equivalence (DI-011): typed enum makes it impossible to emit a stub event that bypasses the engine — each variant carries actual data, not a string placeholder.
- Pattern matching in user code is idiomatic Rust.

**Wire format posture (D13):** The `serde(tag = "event", rename_all = "snake_case")`
derives produce a ferrochain-native JSON wire format. This is NOT the same as
LangChain Python's `.astream_events()` v2 output. D13 mandates ferrochain-native wire format;
LangGraph Platform wire compatibility is out of scope for ferrochain v1.
See `architecture/system-overview.md` line ~36: "No wire-compatibility with LangGraph Platform."

## Consequences

- `StreamEvent` is a public type in `ferrochain-core`.
- Adding new event types requires updating `StreamEvent` enum in ferrochain-core (breaking change for downstream enum matches; documented in CHANGELOG).
- `ferrochain-server` SSE endpoint serializes `StreamEvent` values to `data: <json>\n\n`.
- BC-2.06.003 (streaming/unary equivalence) enforced: the unary endpoint collects `Vec<StreamEvent>` and returns the final `RunEnd` data payload; same engine path.
