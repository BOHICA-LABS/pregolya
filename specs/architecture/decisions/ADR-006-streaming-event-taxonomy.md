---
document_type: adr
level: L3
adr_id: "006"
slug: streaming-event-taxonomy
title: "Streaming Event Taxonomy (CONFLICT-5: typed enum vs stringly-typed)"
status: accepted
date: 2026-07-14
producer: architect
timestamp: 2026-07-14T12:00:00Z
version: "rev-5"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17, D23]
subsystems_affected: ["SS-06", "SS-11"]
supersedes: null
superseded_by: null
changelog:
  - "rev-5 (FIX-BURST-269/F-P167-03/2026-07-25): Variant-count forward-amendment. The rev-4 'Status' section stated 'The 12-variant StreamEvent enum' reflecting the original D17+rev-3 count. D23 grew the enum to 15 via ADR-018 (+ToolApprovalRequest #13, +ToolApprovalResolved #14) and ADR-019 (+CompactionEvent #15). Add forward-amendment blockquote to Status section; BC-2.06.001 is the canonical enumeration per its existing authority statement. Add D23 to decisions frontmatter."
  - "rev-4 (F-P100-02, 2026-07-17): Citation-completeness amendment — no behavioral change. Downstream-amendments scope note (body §Status + Source/Origin emission citation) extended to include BC-2.11.003 PC3/PC4 (RagChunk boundary) and BC-2.11.004 PC3/PC4 (MemoryItem boundary). Rev-3 correctly added GuardrailDecision for all three ingress boundaries but listed only BC-2.11.002 PC3/PC4 (ToolResult) in the amendment scope; the RagChunk and MemoryItem boundary BCs carry symmetric GuardrailDecision emission postconditions. Sibling fix: BC-2.11.002/003/004 PC3/PC4 alignment propagated to interface-definitions.md v2.34→v2.35 /stream row and §StreamEvent BC anchor."
  - "rev-3 (F-P99-01, 2026-07-17): Axis (a) Add GuardrailDecision (12th variant). Fires for non-Pass guardrail outcomes (Fail/Transform only; Pass not streamed) at tool-result, RAG, and memory ingress boundaries. Rationale: audit-log-only is insufficient for Domain A SOC live-analyst use case (domain-a-soc-analyst.md §5 — 'Prompt-injection isolation of untrusted tool output' NEW); SSE consumer has no in-band signal of rejected/rewritten content without this variant. Axis (b) ToolEnd carries POST-guardrail content — raw rejected payloads must not exit the security boundary via the stream (same isolation guarantee as model input buffer per BC-2.11.005 PC1; streaming a blocked prompt-injection payload to UI/analytics consumers defeats the guardrail). Axis (c) Ordering: GuardrailDecision fires BEFORE ToolEnd within the ToolStart/ToolEnd window for ToolResult boundary; within NodeStart/NodeEnd window for RagChunk/MemoryItem boundaries. Axis (d) StreamEvent variant count 11→12; wire token guardrail_decision added; supporting types IngressBoundary/GuardrailDecisionKind/GuardrailSeverityWire defined. GuardrailDecision events are stream-observer notifications only — not emitted in unary mode; underlying GuardrailHook::evaluate fires on both paths per DI-012. Downstream BC amendments required: BC-2.06.001 PC2/PC4/new-EC-006, BC-2.11.002 PC3/PC4, BC-2.11.005 PC1/new-INV-5, BC-2.06.003 new-INV note."
  - "rev-2 (ADV-P1D-PASS-36): F-P36-01 fix Decision heading — retired residual 'LangGraph format' claim. Heading now reads 'pregolya-native wire format over HTTP', consistent with body (lines 59, 67-71), changelog rev-1 (F-P29-05), and D13 canon. No other live LangGraph-format wire claims found in architecture/ tree."
  - "rev-1 (ADV-P1D-PASS-29): F-P29-04 rewrite StreamEvent enum to 11 imperative variants (RunStart/Stream/End, StepStart/End, NodeStart/Stream/End, ToolStart/Stream/End) matching BC-2.06.001 lines ~55-65; add NodeStream and ToolStream variants that were missing from rev-0. Wire tokens corrected to snake_case imperative (run_start not run_started). F-P29-05 remove LangChain astream_events v2 wire-compat claim — wire format is pregolya-native per D13 (consistent with BC-2.06.001 line ~39 and BC-2.12.003 line ~37). Past-tense variant names (RunStarted, NodeStarted, etc.) added to retired-identifier registry."
---

# ADR-006: Streaming Event Taxonomy

**Status:** Accepted

## Context

CONFLICT-5: LangGraph Python emits streaming events as untyped string dictionaries
(`{"event": "on_chain_start", "data": {...}}`). adk-rust emits typed enums per event
category. D17 HYBRID mandate: LangGraph API surface + adk-rust internal quality patterns.

The question is how to represent streaming events in pregolya's public API:
typed Rust enum (adk-rust pattern) or stringly-typed map (LangGraph Python pattern).

## Decision: Typed Enum in Rust API; JSON-serialized to pregolya-native wire format over HTTP

**Internal representation (pregolya-core):**

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
    // CONTENT SEMANTICS (rev-3, F-P99-01): ToolEnd.data carries POST-guardrail content.
    // Raw rejected payloads are never emitted in any StreamEvent (BC-2.11.005 INV-5).
    ToolStart  { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
    ToolStream { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ChunkData },
    ToolEnd    { run_id: RunId, parent_ids: Vec<RunId>, tool: String, data: ToolData },
    // Guardrail observability (wire: guardrail_decision) — rev-3, F-P99-01
    // Emitted ONLY for Fail and Transform outcomes; Pass is never streamed.
    // Stream-observer notification only: not emitted in unary mode.
    // Underlying GuardrailHook::evaluate fires on both paths per DI-012 (BC-2.06.003).
    GuardrailDecision {
        run_id:       RunId,
        parent_ids:   Vec<RunId>,
        /// Which ingress boundary triggered this decision.
        boundary:     IngressBoundary,
        /// Fail or Transform (Pass is not streamed).
        decision:     GuardrailDecisionKind,
        /// Rejection reason — present for Fail; None for Transform.
        reason:       Option<String>,
        /// Rejection severity — present for Fail; None for Transform.
        severity:     Option<GuardrailSeverityWire>,
        /// Correlates to the audit log entry written by BC-2.11.005 PC3.
        ingress_id:   Uuid,
        /// Correlates to the enclosing ToolStart/ToolEnd — present only when
        /// boundary == ToolResult; None for RagChunk and MemoryItem.
        tool_call_id: Option<String>,
    },
}

/// Supporting types for GuardrailDecision (rev-3, F-P99-01)

/// The ingress boundary at which a guardrail decision was made.
/// Maps to IngressContent variants in GuardrailHook (interface-definitions.md §GuardrailHook).
pub enum IngressBoundary { ToolResult, RagChunk, MemoryItem }

/// The non-trivial guardrail outcome included in a GuardrailDecision event.
/// Pass decisions are not streamed; only Fail and Transform produce events.
pub enum GuardrailDecisionKind { Fail, Transform }

/// Wire-serializable severity level mirroring GuardrailSeverity for stream consumers.
pub enum GuardrailSeverityWire { Critical, High, Medium, Low }
```

Authority: **BC-2.06.001** is the canonical source for variant names and wire tokens. Variant names are **imperative** (RunStart, StepStart, NodeStream, ToolEnd, GuardrailDecision, etc.). Wire tokens are snake_case imperative: `run_start`, `run_stream`, `run_end`, `step_start`, `step_end`, `node_start`, `node_stream`, `node_end`, `tool_start`, `tool_stream`, `tool_end`, `guardrail_decision`.

**Causal ordering (BC-2.06.001 PC4 — updated rev-3, F-P99-01):**

```
RunStart
  → (StepStart
      → (NodeStart
          → GuardrailDecision[RagChunk|MemoryItem]*     // RAG/Memory boundary: fires within
          →                                             // NodeStart/NodeEnd, before inference
          → (ToolStart
              → GuardrailDecision[ToolResult]*          // Tool-result boundary: fires within
              → ToolEnd                                 // ToolStart/ToolEnd, before ToolEnd
            )*
          → NodeEnd
        )*
      → StepEnd
    )*
→ RunEnd
```

`GuardrailDecision*` = zero or more per boundary phase — one per non-Pass ContentBlock/chunk/item. A single tool invocation with N ContentBlocks where K fail produces K `GuardrailDecision` events before `ToolEnd`. `ToolEnd` is always the final event in its window.

**Over HTTP (pregolya-server SSE):** Events serialize to JSON with `#[serde(tag = "event")]`,
producing pregolya-native wire format `{"event": "run_start", "data": {...}}` (BC-2.06.001). Wire format is **pregolya-native per D13** — LangChain Python `.astream_events()` v2 wire compatibility is NOT claimed or guaranteed. (F-P29-05: removed prior LangGraph-compat claim that contradicted D13.)

**Why typed enum:**
- Compile-time exhaustiveness: adding a new event variant forces handling in all match sites.
- `run_id + parent_ids` is present on every variant (BC-2.06.002) — enforced by struct layout.
- Streaming / unary equivalence (DI-011): typed enum makes it impossible to emit a stub event that bypasses the engine — each variant carries actual data, not a string placeholder.
- Pattern matching in user code is idiomatic Rust.

**Wire format posture (D13):** The `serde(tag = "event", rename_all = "snake_case")`
derives produce a pregolya-native JSON wire format. This is NOT the same as
LangChain Python's `.astream_events()` v2 output. D13 mandates pregolya-native wire format;
LangGraph Platform wire compatibility is out of scope for pregolya v1.
See `architecture/system-overview.md` line ~36: "No wire-compatibility with LangGraph Platform."

## Rationale

The typed Rust enum was chosen over stringly-typed maps because pregolya targets Rust library consumers who need compile-time safety. CONFLICT-5 makes the tradeoff explicit: LangGraph Python's `{"event": "on_chain_start"}` approach is convenient in Python where dynamic dispatch is idiomatic but produces no compile-time signal when a new event type is added. In Rust, an exhaustive `match` on a stringly-typed map key is impossible — the compiler cannot verify coverage. adk-rust demonstrated the correct pattern (typed enums per event category) and that pattern is adopted here.

D17 HYBRID mandate reinforces this: pregolya takes LangGraph's API surface semantics (run/step/node/tool phase model) but applies adk-rust's internal quality patterns (typed enums, structured data). The two are not in tension here — pregolya serializes its typed enum to pregolya-native JSON over HTTP, so external callers get a structured wire format without pregolya internalizing Python's stringly-typed representation.

DI-011 (Streaming/Unary Run Equivalence) further constrains the design: a stringly-typed event map would allow a stub implementation to emit synthetic `"event": "run_end"` strings without executing the graph engine. A typed enum carrying actual `RunEndData` forces the emission point to be the real engine path — it is structurally impossible to emit a `StreamEvent::RunEnd { final_output: ... }` without having computed `final_output`.

## Consequences

- `StreamEvent` is a public type in `pregolya-core`.
- Adding new event types requires updating `StreamEvent` enum in pregolya-core (breaking change for downstream enum matches; documented in CHANGELOG).
- `pregolya-server` SSE endpoint serializes `StreamEvent` values to `data: <json>\n\n`.
- BC-2.06.003 (streaming/unary equivalence) enforced: the unary endpoint collects `Vec<StreamEvent>` and returns the final `RunEnd` data payload; same engine path.

### Positive

- Exhaustive match enforcement: any new variant added to `StreamEvent` causes compile errors at all match sites, making omissions impossible to ship undetected.
- `run_id + parent_ids` presence on every variant is a struct-layout guarantee, not a runtime check.
- Security boundary enforcement (rev-3): `ToolEnd.data.output` carries post-guardrail content by design — raw rejected payloads cannot appear in the stream because the emission point is after guardrail evaluation.

### Negative / Trade-offs

- Breaking change on every new variant: adding `GuardrailDecision` (rev-3) requires all existing exhaustive match arms to add a new arm. This is intentional — exhaustiveness is the feature.
- `GuardrailDecision` events are stream-observer only; unary callers observe guardrail outcomes through final output shape (error blocks in graph state), not real-time events. This is correct per DI-011 (execution equivalence, not stream-observer equivalence) but may surprise callers who expect symmetry between the streaming and unary observation surfaces.

### Status as of rev-4 (2026-07-17)

Decision is accepted. The `StreamEvent` enum and the rev-3 additions (`GuardrailDecision` variant, post-guardrail `ToolEnd` semantics, ordering specification) are spec-only; implementation is Phase 3. Rev-4 is a citation-completeness amendment only (F-P100-02). Downstream BC amendments (BC-2.06.001 PC2/PC4/new-EC-006, BC-2.11.002 PC3/PC4, BC-2.11.003 PC3/PC4, BC-2.11.004 PC3/PC4, BC-2.11.005 PC1/new-INV-5, BC-2.06.003 new-INV note) are required before Phase 3 story decomposition for SS-06 and SS-11.

> **Forward Amendment (FIX-BURST-269, 2026-07-25):** The "12-variant" count stated in rev-4 reflected the D17 original (11 variants, rev-1) plus the rev-3 `GuardrailDecision` addition (12 total). D23 grew the enum to **15 variants** via ADR-018 (+`ToolApprovalRequest` #13, +`ToolApprovalResolved` #14) and ADR-019 (+`CompactionEvent` #15). The rev-4 variant count is therefore stale; the current count is 15. **BC-2.06.001 is the canonical enumeration authority for variant names and wire tokens** — this was already stated in the decision body and remains the source of truth. ADR-006 defers enumeration to BC-2.06.001.

## Alternatives Considered

- **Option A — Stringly-typed event map (LangGraph Python pattern):** `HashMap<String, Value>` with a dynamic `"event"` key. Rejected because: no compile-time exhaustiveness; consumers cannot exhaustively match; DI-011 cannot be structurally enforced; a stub emitting synthetic event strings is undetectable at the type level. CONFLICT-5 explicitly names this the rejected counter-example.

- **Option B — Separate typed structs per event (no enum wrapper):** Each event as its own `RunStartEvent`, `ToolEndEvent`, etc., dispatched via trait objects. Rejected because: a stream of `Box<dyn StreamEventTrait>` loses exhaustiveness at the consumer's `match`; pattern matching on trait objects in Rust requires downcasting; BC-2.06.002's requirement that every event carry `run_id + parent_ids` is harder to enforce at the type system level than in a shared enum body.

- **Option C — Audit-log-only for GuardrailDecision (no streaming variant):** Document guardrail outcomes only in the run's audit log (BC-2.11.005 PC3), with no in-band SSE signal. Rejected (rev-3 adjudication): Domain A SOC live-analyst forcing function requires real-time observability of security decisions via the SSE stream. An audit-log entry written atomically with the rejection is correct for forensic/compliance purposes but provides zero signal to an SSE consumer watching a live run. The two channels (audit log + stream) serve different audiences and are non-redundant.

## Source / Origin

- **Master design conflicts:** `semport/core/behavioral-intent.md §D-2` (CONFLICT-5 — astream_events v2 typed taxonomy vs. adk-rust flat Event envelope); `comparative/assessment-parts/part-3-conflicts-negative-evidence.md CONFLICT-5`.
- **PRD binding decision:** D17 (HYBRID mandate: LangGraph API surface + adk-rust quality patterns); D13 (pregolya-native wire format — no LangGraph Platform wire compat).
- **Behavioral contracts:** BC-2.06.001 (canonical variant authority), BC-2.06.002 (run_id + parent_ids on every event), BC-2.06.003 (streaming/unary equivalence), BC-2.11.002/003/004 PC3/PC4 (GuardrailDecision emission on Fail/Transform per boundary — rev-3/rev-4), BC-2.11.005 PC1 (ToolEnd post-guardrail content — rev-3).
- **Domain forcing function (rev-3):** `planning/holdout-domains/domain-a-soc-analyst.md §5` — "Prompt-injection isolation of untrusted tool output" marked NEW; §6 "Adversarial tool-content resistance" evaluation scenario.
