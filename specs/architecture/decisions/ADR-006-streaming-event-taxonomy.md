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
    RunStarted  { run_id: RunId, parent_ids: Vec<RunId>, data: RunStartData },
    RunStreamed { run_id: RunId, parent_ids: Vec<RunId>, data: ChunkData },
    RunEnded    { run_id: RunId, parent_ids: Vec<RunId>, data: RunEndData },
    NodeStarted { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: NodeData },
    NodeEnded   { run_id: RunId, parent_ids: Vec<RunId>, node: String, data: NodeData },
    ToolStarted { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
    ToolEnded   { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
    StepStarted { run_id: RunId, parent_ids: Vec<RunId>, step: u32 },
    StepEnded   { run_id: RunId, parent_ids: Vec<RunId>, step: u32 },
}
```

**Over HTTP (ferrochain-server SSE):** Events serialize to JSON with `#[serde(tag = "event")]`,
producing the LangGraph-compatible `{"event": "run_started", "data": {...}}` format (BC-2.06.001).

**Why typed enum:**
- Compile-time exhaustiveness: adding a new event variant forces handling in all match sites.
- `run_id + parent_ids` is present on every variant (BC-2.06.002) — enforced by struct layout.
- Streaming / unary equivalence (DI-011): typed enum makes it impossible to emit a stub event that bypasses the engine — each variant carries actual data, not a string placeholder.
- Pattern matching in user code is idiomatic Rust.

**LangGraph Python compatibility:** The `serde(tag = "event", rename_all = "snake_case")`
derives produce wire format compatible with LangChain Python's `.astream_events()` v2 output
for the standard event types. Custom event types may differ in field names.

## Consequences

- `StreamEvent` is a public type in `ferrochain-core`.
- Adding new event types requires updating `StreamEvent` enum in ferrochain-core (breaking change for downstream enum matches; documented in CHANGELOG).
- `ferrochain-server` SSE endpoint serializes `StreamEvent` values to `data: <json>\n\n`.
- BC-2.06.003 (streaming/unary equivalence) enforced: the unary endpoint collects `Vec<StreamEvent>` and returns the final `RunEnded` data payload; same engine path.
