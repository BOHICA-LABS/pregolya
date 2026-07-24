---
document_type: behavioral-contract
level: L3
bc_id: BC-2.11.005
version: "1.3"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
input-hash: "67fe835"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-11
capability: CAP-013
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-22): F-P22-01 — input anchor corrected from `capabilities-p1-p2.md` to `capabilities-p0.md`; Capability Anchor Justification source path updated (16-BC re-anchor sweep)."
  - "1.2 (ADV-P1D-PASS-59): F-P59-02 — EC-002 description and TV fixed to typecheck against Transform { new_content: IngressContent }. Bare ContentBlock::text('[REDACTED]') → IngressContent::ToolResult(ContentBlock::text('[REDACTED]')); EC-002 description updated to reflect IngressContent wrapper (same-boundary rule). ToolResult used as the concrete example boundary per BC-2.11.002 EC-003 authority."
  - "1.3 (F-P99-01, 2026-07-17): Architect GuardrailDecision amendments (ADR-006 rev-3). PC1 — extended with streaming surface isolation clause: ToolEnd.data carries post-guardrail content; GuardrailDecision carries metadata only; zero rejected bytes in any StreamEvent payload. New INV-5 — streaming surface subject to same content isolation; GuardrailDecision carries metadata only; enforced structurally via ordering."
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

# BC-2.11.005: Rejected Content Does Not Enter Model Context Under Any Code Path

## Description

This is the architectural closure contract for the DI-012 guardrail subsystem. When a
`GuardrailHook` returns `GuardrailResult::Fail` for any content unit at any ingress boundary
(tool-result, RAG, or memory), that content unit — including every byte of the original — does
not enter the model input buffer under any code path. The rejection is atomically complete before
model inference begins: there is no race between the rejection path and the forwarding path, no
partial insertion window, and no retry mechanism that bypasses this guarantee. The error block
substitution, the audit log record, and the absence from the model context are all part of a
single synchronous operation in the current super-step.

## Preconditions

1. A `GuardrailHook` is registered on the `InvocationContext`
2. The hook has returned `GuardrailResult::Fail { reason, severity }` for at least one content
   unit at a tool-result, RAG, or memory ingress boundary
3. The rejected content unit was tagged with a `ProvenanceTag` identifying an ingress boundary
   (per BC-2.11.001)

## Postconditions

1. The model input buffer (the complete list of messages/content passed to the model on the
   current inference call) contains zero bytes of the rejected content unit's original data.
   The streaming surface enforces the same isolation guarantee: `ToolEnd.data` carries post-guardrail
   content only — raw rejected payloads are never present in any `StreamEvent` payload. This
   includes `StreamEvent::GuardrailDecision` itself, which carries metadata only (reason, severity,
   ingress_id, boundary, tool_call_id) and contains zero bytes of the rejected content (INV-5)
2. An error block is injected at the position where the rejected content unit would have appeared;
   the error block contains `reason` (the rejection reason from the hook) and the
   `ProvenanceTag.ingress_id` — neither of which contains the original content
3. The `ProvenanceTag`, `reason`, and `severity` of every rejected item are recorded in the run's
   audit log atomically with the rejection (before inference proceeds)
4. If `severity == Critical`: the run transitions to `failed` state; model inference is not
   called; no further nodes execute
5. If `severity != Critical`: the run continues with the error block substituted; model inference
   is called with the modified (rejected-content-free) input buffer

## Invariants

1. The rejection is atomic and synchronous: there is no execution window between the
   `GuardrailResult::Fail` return and the model input buffer being finalized in which rejected
   content could slip through
2. The error block may reference the rejection reason by value but must not include any portion
   of the original rejected content in a form observable by the model
3. Audit log records the rejection metadata; however, the audit log record itself does not store
   the raw rejected content in a location that is ever forwarded to the model as context
4. Parallel guardrail composition (two hooks run in parallel): if any hook returns `Fail`,
   the content is treated as rejected — fail-closed parallel composition
5. The streaming surface is subject to the same content isolation guarantee: `GuardrailDecision`
   carries metadata only (reason, severity, ingress_id, boundary, tool_call_id) — zero bytes
   of the rejected content appear in any `StreamEvent` payload. This is enforced structurally
   by the causal ordering: `GuardrailDecision` emits BEFORE `ToolEnd`; `ToolEnd` carries
   post-guardrail content, never the raw rejected payload (ADR-006 rev-3, F-P99-01)

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Two `GuardrailHook` instances composed in parallel: hook-A returns `Pass`, hook-B returns `Fail` | Fail-closed: content does NOT enter model context; `Fail` wins; error block injected |
| EC-002 | `GuardrailResult::Transform` returns `IngressContent::ToolResult(ContentBlock::text(""))` — an empty text replacement (same-boundary rule: ToolResult in, ToolResult out) | `IngressContent::ToolResult(ContentBlock::text(""))` enters model context (not the original); no-bypass guarantee applies to the original only — Transform is not Fail |
| EC-003 | `GuardrailResult::Fail` is followed by a tool-call retry that produces new content | New content unit goes through `GuardrailHook` evaluation independently; the first rejected content never enters model context regardless of the retry outcome |
| EC-004 | Concurrent ingress events (parallel fan-out): event-A content passes, event-B content fails | Each event's rejection/forwarding decision is independent and atomic; event-A content is in the model context; event-B's original content is absent; both audit log entries are written |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| GuardrailHook returns `Fail` for tool-result content; model inference is called | Model input buffer inspected immediately before inference call: zero bytes of rejected content present; error block with `reason` present at same position; audit log contains rejection record | happy-path (the core guarantee) |
| Two composed GuardrailHooks: hook-A returns `Pass`, hook-B returns `Fail` | Content does not enter model context; `Fail` wins fail-closed; error block injected | fail-closed parallel composition edge-case |
| `GuardrailResult::Transform { new_content: IngressContent::ToolResult(ContentBlock::text("[REDACTED]")) }` followed by inference | Model input buffer contains `"[REDACTED]"` only (via `IngressContent::ToolResult` wrapper); original content absent; same-boundary rule satisfied | transform-not-fail edge-case |
| `GuardrailResult::Fail { severity: Critical }` | Run transitions to `failed` state; `ModelInference` not called; no further nodes execute; audit log records rejection | critical-severity error case |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.11.005-A | For every `GuardrailResult::Fail` recorded in the audit log, no content from the rejected item appears in any subsequent model inference call within the same run | audit log cross-reference integration test |
| VP-2.11.005-B | The model input buffer is inspectable immediately before every inference call; rejected content is absent | property test — inject known-fail content; assert buffer does not contain it |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-013 |
| Capability Anchor Justification | CAP-013 ("Content Provenance Tagging and Guardrail-on-Ingress") per capabilities-p0.md §CAP-013 |
| L2 Domain Invariants | DI-012 (Guardrail Coverage at Ingress Boundaries — "Content that fails a guardrail does not enter the model context under any code path") |
| Source Analysis | P-59 REJECT (the entire attack surface is adk-rust's unguarded tool/RAG/memory ingress); P-55 ADAPT (trait shape provides Fail variant with reason + severity); assessment-parts/part-2-dispositions-p51-p97.md §H4 |
| Reference Evidence | Greenfield. DI-012 contains the verbatim requirement text "does not enter the model context under any code path" — this BC specifies the enforcement mechanism. No upstream reference implementation. The atomicity guarantee (no race between rejection and forwarding) is ferrochain-original design. |
| Binding Decisions | D17-Q8 (content provenance/guardrail-on-ingress is Phase-1 BC); DI-012 invariant text |
| Forcing Functions | Domain A SOC analyst §4 "LLM-specific security risks — prompt injection via malicious log/alert content (adversary-controlled text entering the reasoning loop through tool output)"; Domain A §6 "Adversarial tool-content resistance" scenario |
| Architecture Module | ferrochain-core / ferrochain-graph (model input buffer construction; filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.11.001 — depends on: ProvenanceTag provides the ingress_id included in the audit log record
- BC-2.11.002 — composes with: tool-result Fail results are governed by this closure contract
- BC-2.11.003 — composes with: RAG Fail results are governed by this closure contract
- BC-2.11.004 — composes with: memory Fail results are governed by this closure contract
- BC-2.11.006 — orthogonal: the no-hook default permits content (no Fail result); this contract only fires on Fail

## Architecture Anchors

- `architecture/ferrochain-core.md` — model input buffer construction and atomic rejection enforcement (filled by architect)
- `architecture/ferrochain-graph.md` — pre-inference buffer finalization point (filled by architect)

## Story Anchor

S-N.MM — Atomic rejection guarantee — rejected content absent from model context (filled by story-writer)

## VP Anchors

- VP-2.11.005-A — audit log Fail records ↔ no rejected content in subsequent inference (integration test)
- VP-2.11.005-B — model input buffer inspectable pre-inference; rejected content absent (property test)
