---
document_type: behavioral-contract
level: L3
bc_id: BC-2.11.006
version: "1.8"
status: active
producer: product-owner
timestamp: 2026-08-26T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
input-hash: "a146822"
traces_to: domain-spec/capabilities-p0.md#CAP-013
origin: greenfield
subsystem: SS-11
capability: CAP-013
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-22): F-P22-01 — input anchor corrected from `capabilities-p1-p2.md` to `capabilities-p0.md`; Capability Anchor Justification source path updated (16-BC re-anchor sweep)."
  - "1.2 (burst-226/F-P131-02/2026-07-21): Canonical no-hook WARN emission adjudicated — unified event_type 'guardrail.unregistered_passthrough' replaces prose-specified-only WARN. Merged field schema: {boundary_type, ingress_id, item_count, timestamp} base + conditional {server_name, tool_name} when ToolResult from MCP. PC2, INV-2, test vectors updated. ONE log line per boundary crossing (no double-logging with BC-2.09.003)."
  - "1.3 (FIX-BURST-257/F-P156-01, 2026-07-24): anchor-class sweep — nonexistent architecture file citations replaced with adjudicated real targets (F-P114-01 pattern)."
  - "1.4 (BURST-315/F-A2/2026-08-17): Normalize traces_to — changed from generic `domain-spec/L2-INDEX.md` to direct-capability anchor `domain-spec/capabilities-p0.md#CAP-013`, matching corpus standard for capability-bearing BCs and aligning with the `capability: CAP-013` frontmatter and Traceability §CAP-013 citations already present."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC-001..PC-005}, {INV-001..INV-004}, {PRE-001..PRE-003} added; purely additive, no content change."
  - "1.6 (burst-B-SS09-11/bc-scan-hardening/2026-08-26): LOW gap — EC-002 cascading-log-failure observable: replaced vague 'tracked separately (cascading log failure)' with unobservable-by-design declaration citing tracing fire-and-forget semantics and operator resilience requirement. ADR-027 stable clause {EC-002} (existing anchor, content updated)."
  - "1.7 (F-P2A123-01/2026-08-28): §Story Anchor backfilled to S-1.19; §Architecture Module confirmed as pregolya-core / pregolya-graph (InvocationContext hook-slot check and WARN emission) — from STORY-INDEX forward map (SS-11 coverage map) and self §Architecture Anchors (module-decomposition.md §pregolya-graph, §pregolya-core). No behavioral change."
  - "1.8 (round-49/F-P2A207-03-sibling/2026-08-31): F-P2A207-03 sibling sweep — §Architecture Module updated with canonical InvocationContext module qualifier: `InvocationContext` struct lives in `core::invocation_context` (`pregolya-core/src/invocation_context.rs`) per interface-definitions.md §InvocationContext v3.02; hook-slot check and WARN emission logic lives in pregolya-graph. No behavioral change."
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
oqr_resolution: OQR-5
---

# BC-2.11.006: No-Hook Default — Content Passes Through with WARNING LOG (Default-Permit)

## Description

When no `GuardrailHook` is registered on the `InvocationContext`, every content unit at every
ingress boundary (tool-result, RAG, memory) passes through to the model context unchanged.
A `WARN`-level structured log entry is emitted once per ingress boundary crossing, alerting the
operator that guardrail evaluation was skipped. The graph run does not fail, and no error is
raised. This is the OQR-5 resolution: default-permit posture was chosen over default-deny because
default-deny would break every RAG and MCP use case that does not need content filtering. Domain A
users who require guardrails must explicitly register a `GuardrailHook`.

## Preconditions

1. {PRE-001} No `GuardrailHook` has been registered on the `InvocationContext` (the hook slot is `None`)
2. {PRE-002} Content is arriving at an ingress boundary (tool-result, RAG, or memory)
3. {PRE-003} `ProvenanceTag` is attached to the content (BC-2.11.001 still fires — tagging is independent
   of hook presence)

## Postconditions

1. {PC-001} Every content unit is forwarded to the model context without modification
2. {PC-002} A `WARN`-level structured log entry is emitted once per ingress boundary crossing:
   - All boundary types: `event_type = "guardrail.unregistered_passthrough"` with required fields `{ boundary_type: <"ToolResult"|"RAGRetrieval"|"MemoryIngress">, ingress_id: <uuid>, item_count: N, timestamp: <ts> }`
   - For ToolResult boundaries originating from MCP tool calls: additionally includes conditional fields `{ server_name: <server>, tool_name: <tool> }`
   - ONE log line per boundary crossing event; no double-logging (BC-2.09.003 no-hook path and BC-2.11.006 share the same canonical emission)
3. {PC-003} The WARNING is emitted once per ingress boundary crossing event, not once per content unit
   within the event (an ingress event with N items produces 1 WARNING, not N)
4. {PC-004} The `ProvenanceTag` remains attached to the forwarded content (unchanged from BC-2.11.001
   behavior)
5. {PC-005} The graph run continues normally; no `Err` is returned; no state transition occurs

## Invariants

1. {INV-001} The WARNING is emitted at `WARN` level — not `INFO`, not `ERROR`; log aggregators configured
   at `WARN` will surface it; operators who silence `WARN` accept the responsibility
2. {INV-002} The WARNING log entry is machine-parseable (canonical `event_type = "guardrail.unregistered_passthrough"` with structured fields: `boundary_type`, `ingress_id`, `item_count`, `timestamp`; conditionally `server_name`, `tool_name` for MCP ToolResult boundaries) to support automated alerting on unguarded ingress
3. {INV-003} `ProvenanceTag` attachment (BC-2.11.001) fires unconditionally — even in the no-hook case,
   content carries a `ProvenanceTag`; the WARNING log entry references the `ingress_id` from the tag
4. {INV-004} If a `GuardrailHook` is registered after run start (hot-registration is implementation-defined;
   this invariant applies only to the `None`-at-construction case): boundary crossings that
   occurred before hot-registration are not retroactively re-evaluated

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Operator explicitly sets hook to `None` (opt-in default-permit) | Behavior identical to absent-hook; `WARN` still emitted; no special-case handling for explicit `None` |
| EC-002 | Logging backend is unavailable (log sink full or panicked) | Content still passes through; WARNING emission failure does not cause ingress to fail. **Unobservable-by-design:** `tracing::warn!` is fire-and-forget in the Tokio tracing-subscriber model — if the subscriber is unavailable, has panicked, or has a full internal buffer, the WARN event is silently dropped with no error propagated to the caller. There is no secondary counter or metric tracking this failure mode; pregolya provides no additional observability layer for log-sink failures on this path. Operators who rely on the `"guardrail.unregistered_passthrough"` WARNING for security decision-making MUST configure a resilient log backend (e.g., a non-blocking ring-buffer subscriber with overflow detection). |
| EC-003 | High-volume run: 10,000 tool-result ingress events with no hook registered | `WARN` emitted once per boundary crossing (10,000 WARNINGs); no artificial rate-limiting or deduplication suppresses them; operator signal is intentionally high-volume |
| EC-004 | Zero-item ingress (RAG returns 0 chunks, memory returns 0 items) | No content forwarded; no `WARN` emitted (no boundary crossing with content occurred); behavior mirrors EC-001 of BC-2.11.003 |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| No `GuardrailHook` registered; `ToolMessage` `ContentBlock` arrives (from MCP server "math-server", tool "add") | `ContentBlock` forwarded unchanged; exactly 1 `WARN` log entry with `event_type = "guardrail.unregistered_passthrough"`, `boundary_type: "ToolResult"`, `ingress_id` matching `ProvenanceTag.ingress_id`, `item_count: 1`, `server_name: "math-server"`, `tool_name: "add"` | happy-path (default-permit for tool-result) |
| No `GuardrailHook` registered; RAG retrieval returns 3 chunks | All 3 chunks forwarded unchanged; exactly 1 `WARN` emitted with `event_type = "guardrail.unregistered_passthrough"`, `boundary_type: "RAGRetrieval"`, `item_count: 3`; no `server_name`/`tool_name` fields (RAG boundary, not MCP) | edge-case (single WARN per crossing, not per chunk) |
| No `GuardrailHook` registered; memory read returns 0 items | 0 items forwarded; 0 `WARN` emitted; no error | edge-case (zero-item — no crossing, no warning) |
| `GuardrailHook` registered mid-run after first tool-result ingress | First ingress: `WARN` emitted, content forwarded (hook was `None`); subsequent ingresses: hook evaluates per BC-2.11.002/003/004; no `WARN` on hook-guarded ingresses | edge-case (hot-registration) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.11.006-A | With no `GuardrailHook` registered, every ingress boundary crossing with N > 0 items emits exactly 1 `WARN` log entry and forwards all N items to model context | unit test — count WARN emissions and forwarded items |
| VP-2.11.006-B | The `WARN` log entry's `ingress_id` field matches the `ProvenanceTag.ingress_id` of the crossing | unit test — assert field value equality |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-013 |
| Capability Anchor Justification | CAP-013 ("Content Provenance Tagging and Guardrail-on-Ingress") per capabilities-p0.md §CAP-013 |
| L2 Domain Invariants | DI-012 (Guardrail Coverage at Ingress Boundaries — this BC defines the no-hook code path) |
| OQR Resolution | OQR-5: "Default-permit with WARNING LOG at WARN level when no GuardrailHook is registered. Graph does not fail. Operator sees a warning." (Resolution adopted; log level is WARN per convention for an operator-actionable alert) |
| Source Analysis | OQR-5 prd.md §OQR table; DI-012 invariant (the default-permit path is within DI-012's scope — DI-012 does not mandate a specific default, only that hooks fire when registered and that rejections block context entry) |
| Reference Evidence | Greenfield. No upstream reference. OQR-5 rationale: "A missing guardrail is valid for most non-SOC use cases. Domain A users must explicitly register a GuardrailHook. default-deny would break every RAG and MCP use case that doesn't need content filtering." |
| Binding Decisions | D17-Q8 (defines the subsystem); OQR-5 (resolves default posture) |
| Forcing Functions | Domain A SOC analyst §5 (forces explicit hook registration by Domain A users; the default-permit posture is justified because the framework must not break general-purpose RAG/MCP use cases) |
| Architecture Module | pregolya-core (`core::invocation_context` — `InvocationContext` struct at `pregolya-core/src/invocation_context.rs`) / pregolya-graph (InvocationContext hook-slot check and WARN emission) |
| Stories | S-1.19 |

## Related BCs

- BC-2.11.001 — composes with: ProvenanceTag still attached in no-hook path; WARN log references ingress_id
- BC-2.11.002 — counterpart: specifies the registered-hook behavior for tool-result ingress
- BC-2.11.003 — counterpart: specifies the registered-hook behavior for RAG ingress
- BC-2.11.004 — counterpart: specifies the registered-hook behavior for memory ingress
- BC-2.11.005 — orthogonal: rejection closure contract; this BC has no Fail path

## Architecture Anchors

- `architecture/module-decomposition.md §pregolya-graph` — `graph::provenance` row: `InvocationContext` hook-slot `None` path; structured `WARN` `event_type = "guardrail.unregistered_passthrough"`; default-permit per OQR-5 (HIGH, SS-11)
- `architecture/module-decomposition.md §pregolya-core` — `core::guardrail` definitions-only note: optional registration seam; `None` hook-slot handled by `graph::provenance` WARN logic

## Story Anchor

S-1.19 — Default-permit WARNING LOG when no GuardrailHook registered

## VP Anchors

- VP-2.11.006-A — no-hook path: 1 WARN per crossing, all items forwarded (unit test)
- VP-2.11.006-B — WARN ingress_id matches ProvenanceTag ingress_id (unit test)
