---
document_type: behavioral-contract
level: L3
bc_id: BC-2.11.001
version: "1.2"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
input-hash: "ce6131b"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-11
capability: CAP-013
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-22): F-P22-01 — input anchor corrected from `capabilities-p1-p2.md` to `capabilities-p0.md`; Capability Anchor Justification source path updated to match (16-BC re-anchor sweep)."
  - "1.2 (FIX-BURST-257/F-P156-01, 2026-07-24): anchor-class sweep — nonexistent architecture file citations replaced with adjudicated real targets (F-P114-01 pattern)."
modified: []
extracted_from: null
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P0
wave: 1
d17_commitment: Q8
---

# BC-2.11.001: ProvenanceTag Attached at Every Ingress Boundary (Tool-Result, RAG, Memory)

## Description

A `ProvenanceTag` is attached to every unit of content arriving at a tool-result, RAG, or memory
ingress boundary before any consumer (GuardrailHook or model context) can observe the content.
The tag records the boundary type, a unique ingress-event ID, and the sequence position of the
content unit within that event. Tagging is unconditional — it fires regardless of whether a
`GuardrailHook` is registered, providing an always-present provenance record for audit and
downstream hook evaluation.

## Preconditions

1. An `InvocationContext` has been constructed for a graph run (whether or not a `GuardrailHook`
   is registered)
2. Content is arriving from one of the three ingress boundary types: tool-result, RAG document
   retrieval, or memory read
3. The content unit has not yet been passed to any consumer downstream of the boundary

## Postconditions

1. Every `ContentBlock` from a tool-result boundary carries a
   `ProvenanceTag { boundary_type: BoundaryType::ToolResult, ingress_id: <uuid>, sequence_position: N }`
2. Every document chunk from a RAG retrieval boundary carries a
   `ProvenanceTag { boundary_type: BoundaryType::RAGRetrieval, ingress_id: <uuid>, sequence_position: N }`
3. Every item from a memory ingress boundary carries a
   `ProvenanceTag { boundary_type: BoundaryType::MemoryIngress, ingress_id: <uuid>, sequence_position: N }`
4. All content units from a single ingress event share the same `ingress_id`; units within the
   event are distinguished by distinct, zero-indexed `sequence_position` values
5. Content without a `ProvenanceTag` does not proceed to `GuardrailHook` evaluation or model
   context insertion — the pipeline enforces tagged content as a precondition for forwarding

## Invariants

1. `ProvenanceTag` attachment is unconditional: no branch in the ingress pipeline bypasses it,
   regardless of whether a `GuardrailHook` is registered or the run is in debug mode
2. The `boundary_type` field of an attached tag is immutable; no downstream code may alter it
   after attachment
3. An ingress event producing N content units tags all N independently with the same `ingress_id`
   but distinct `sequence_position` values (0 through N-1)
4. An ingress event producing zero content units creates no `ProvenanceTag` objects; the empty
   result does not trigger any downstream guardrail evaluation

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Tool produces zero content units (empty `ToolMessage`) | No `ProvenanceTag` created; the empty result is logged as an ingress event with item_count=0; `GuardrailHook` is not called; empty result forwarded |
| EC-002 | RAG retrieval returns no matching documents | No `ProvenanceTag` created; empty ingress event recorded; no guardrail call; empty list forwarded to model context |
| EC-003 | Memory read returns a partially truncated item (backend storage inconsistency) | `ProvenanceTag` attached to the truncated content unit; guardrail sees the truncated content; truncation is not treated as a tagging failure |
| EC-004 | Ingress content unit arrives from an unrecognized boundary (internal scratch pad) | No `ProvenanceTag` attached; this content does not traverse the DI-012 guardrail path; it is not subject to BC-2.11.002/003/004 |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| A `ToolMessage` `ContentBlock` arrives from a Splunk MCP server query result | `ProvenanceTag { boundary_type: ToolResult, ingress_id: <uuid-A>, sequence_position: 0 }` attached to the block before any consumer is called; tag is readable by `GuardrailHook` | happy-path |
| RAG retrieval returns 3 document chunks in one call | Each chunk carries `ProvenanceTag { boundary_type: RAGRetrieval, ingress_id: <uuid-B>, sequence_position: 0/1/2 }` — same `ingress_id`, distinct `sequence_position` | edge-case (multi-unit ingress) |
| Memory read returns 0 items | Zero `ProvenanceTag` objects created; no guardrail calls triggered; no error raised | edge-case (zero-item ingress) |
| Internal model scratch-pad content (never crossed an ingress boundary) passed to context assembly | No `ProvenanceTag` attached; content does not traverse the BC-2.11.002/003/004 guardrail path | error (boundary violation test) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.11.001-A | For all content units arriving at ToolResult / RAGRetrieval / MemoryIngress boundaries, a `ProvenanceTag` is attached before the unit is passed to any consumer | integration test — inspect tag presence at hook call site |
| VP-2.11.001-B | All content units from a single ingress event share the same `ingress_id` and have distinct, zero-indexed `sequence_position` values | unit test — multi-unit ingress assertion |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-013 |
| Capability Anchor Justification | CAP-013 ("Content Provenance Tagging and Guardrail-on-Ingress") per capabilities-p0.md §CAP-013 |
| L2 Domain Invariants | DI-012 (Guardrail Coverage at Ingress Boundaries) |
| Source Analysis | P-59 REJECT (adk-rust input-path-only guardrails = must-not-inherit); P-55 ADAPT (guardrail trait shape); assessment-parts/part-2-dispositions-p51-p97.md §H4 |
| Reference Evidence | No upstream LangChain/adk-rust equivalent for ProvenanceTag — greenfield design. P-59 is the counter-example driving this; no positive reference implementation. D17-Q8 is the mandate. |
| Binding Decisions | D17-Q8 (content provenance-tag seam is Phase-1 BC), DI-012 |
| Forcing Functions | Domain A SOC analyst §5 ("Prompt-injection isolation of untrusted tool output" marked NEW); Domain C OpenClaw §4 SEC (documented stance on indirect prompt injection + memory-poisoning) |
| Architecture Module | ferrochain-core / ferrochain-graph (InvocationContext seam; filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.11.002 — depends on: tool-result guardrail hook evaluation requires ProvenanceTag to be already attached
- BC-2.11.003 — depends on: RAG guardrail hook evaluation requires ProvenanceTag
- BC-2.11.004 — depends on: memory guardrail hook evaluation requires ProvenanceTag
- BC-2.11.005 — composes with: the no-bypass guarantee relies on ProvenanceTag presence as a gate
- BC-2.11.006 — composes with: WARNING LOG emission per boundary crossing uses the ProvenanceTag ingress_id

## Architecture Anchors

- `prd-supplements/interface-definitions.md §GuardrailHook` — `ProvenanceTag` struct (fields: `boundary_type: BoundaryType`, `ingress_id: Uuid`, `sequence_position: usize`) + `BoundaryType` enum (`ToolResult` | `RAGRetrieval` | `MemoryIngress` — 3 variants, PASS-58 canon)
- `architecture/module-decomposition.md §ferrochain-graph` — `graph::provenance` row: `ProvenanceTag` attachment at ingress boundaries, `GuardrailHook` dispatch (HIGH, SS-11)
- `architecture/module-decomposition.md §ferrochain-core` — `core::guardrail` definitions-only note: `BoundaryType` enum + full trait set (`GuardrailHook`, `GuardrailResult`, `IngressContent`, `GuardrailSeverity`); no execution logic; promoted to core per ADR-014 Decision 6

## Story Anchor

S-N.MM — Content provenance tagging at ingress boundaries (filled by story-writer)

## VP Anchors

- VP-2.11.001-A — ProvenanceTag attached before any consumer (integration test)
- VP-2.11.001-B — ingress_id sharing and sequence_position uniqueness within event (unit test)
