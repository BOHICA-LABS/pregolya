---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T23:59:45Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 99
previous_review: pass-98.md
---

# Adversarial Review: ferrochain (Pass 99)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 98 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P98-01 | LOW [claim-vs-artifact] | RESOLVED | bc-authoring-plan v2.30 gate #27 Exemptions "all 59 legacy placeholders resolved" → "all 60 legacy placeholders resolved — 59 literal + 1 semantic variant"; source ref extended F-P96-01 alone → F-P96-01 + F-P97-01; v2.30 changelog row added; v2.28/v2.29 historical rows untouched; post-fix grep zero other live 59-refs. |

**Sibling-checks (burst-180 owed list):**

| Check | Result |
|-------|--------|
| bc-authoring-plan v2.30 gate #27 body "all 60 legacy placeholders resolved — 59 literal + 1 semantic variant" | PASS |
| v2.30 changelog row present; v2.28/v2.29 historical rows untouched | PASS |
| Zero other live "59" placeholder-total references outside changelogs | PASS — corpus grep confirmed zero additional hits |

**Additional probes (deep risk-selected, fresh context):**

| Probe | Result |
|-------|--------|
| Gate #27 semantic sweep (widened class: `architect to (assign\|confirm\|determine\|resolve)`) | PASS — zero live hits outside changelogs/gate-rules |
| Hedge sweep ("architect to assign", "TODO", "TBD", "placeholder") | PASS — no live unresolved placeholders |
| Gate #28/#33/#34/#13 spot-checks | PASS — no new violations found on selected axes |
| VP-BUDGET collision drain confirmed (VP-BUDGET-01..07 sequence, zero collisions) | PASS |
| RetryHint↔SS-16 coherence (BC-2.16.xxx + interface-definitions §RetryHint alignment) | PASS |
| NFR↔BC harness-string agreement (nfr-catalog v1.2 timeout/retry values vs BC TV assertions) | PASS |
| SS-04 crash-window semantics (checkpoint pre-step vs post-step recovery invariants) | PASS |
| Sibling-check 1/1: StreamEvent variant count STATE.md canon vs BC-2.06.001 PC2 | PASS — both cite 11 variants (pre-burst-181 baseline; finding F-P99-01 upgrades to 12) |

## Part B — New Findings

### OBS (adjudicated substantive — scope expansion)

#### F-P99-01: GuardrailDecision Observability Seam — StreamEvent Taxonomy Gap

- **Severity:** OBS → adjudicated substantive (architect + PO + BA); scope expansion via D18-P99-A
- **Category:** behavioral-observability (cross-subsystem seam: SS-06 guardrail + SS-11 streaming)
- **Location:** BC-2.06.001 (StreamEvent enum), interface-definitions §StreamEvent, BC-2.11.002/BC-2.11.005, BC-2.06.003
- **Description:** Guardrail ingress decisions (IngressGuardrail boundary evaluations per SS-06) were entirely unobservable in the StreamEvent taxonomy. The streaming surface defined 11 variants covering model output, tool calls, node execution, and error paths — but carried no variant for guardrail evaluation outcomes. Downstream consumers (SSE clients, Domain-A SOC live-analyst, audit pipelines) had no way to distinguish rejected tool results, transformed payloads, or denied graph continuations from normal execution without out-of-band polling. Two compounding gaps: (1) ToolEnd content semantics under guardrail evaluation — whether ToolEnd carries pre- or post-guardrail content was unspecified, creating an implicit raw-payload leak risk to SSE consumers; (2) ordering between GuardrailDecision and the sibling events it gates (ToolEnd for ToolResult boundaries, NodeStart/NodeEnd for RAG/Memory) was undefined.
- **Security angle:** A consuming SSE client that assumes ToolEnd always carries sanitized content would be incorrect if pre-guardrail content streamed first. Rejected raw payloads would reach the stream surface, creating an unintended information-disclosure path.
- **Evidence:** BC-2.06.001 PC2 listed 11 StreamEvent variants with no guardrail entry; BC-2.11.002 (IngressGuardrail behavioral contract) contained no streaming-surface clause; BC-2.06.003 (stream-observer invariant) made no mention of guardrail decision emission; interface-definitions §StreamEvent table (v2.33) had 11 rows, none for guardrail outcomes. Domain-A SOC live-analyst use case (holdout domain A brief) requires real-time visibility into guardrail decisions for triage workflows — this gap would break a primary Domain-A forcing function at implementation time.
- **Adjudication (D18-P99-A):** ARCHITECT + PO + BA scope expansion decision:
  - (a) ADD StreamEvent::GuardrailDecision as the 12th variant. Emitted for Fail and Transform decisions only (Pass decisions are not streamed — zero-overhead pass path). Metadata-only payload: `boundary: IngressBoundary`, `decision: GuardrailOutcome` (Fail|Transform), `reason: String` (Fail only), `severity: GuardrailSeverity` (Fail only), `ingress_id: Uuid`, `tool_call_id: Option<Uuid>` (ToolResult boundaries only), `run_id: Uuid`, `parent_ids: Vec<Uuid>`.
  - (b) ToolEnd carries POST-guardrail content exclusively (zero-bytes isolation guarantee extended from model output buffer to streaming surface).
  - (c) Ordering explicit: GuardrailDecision fires BEFORE the sibling event it gates — before ToolEnd (ToolResult boundary), within NodeStart–NodeEnd envelope (RAG/Memory boundary).
  - (d) Unary (non-streaming) mode: GuardrailDecision is NOT emitted (execution-path vs stream-observer equivalence; NOT a DI-011 violation).
- **Files changed (burst 181):**
  - ADR-006 rev-3: 12-variant enum + GuardrailDecision supporting types (IngressBoundary, GuardrailOutcome, GuardrailSeverity) + causal ordering rules + template-conformance sections (superseded_by/date/subsystems_affected frontmatter + Context/Alternatives/Rationale/Source sections).
  - interface-definitions v2.34: §StreamEvent table (11→12 rows, GuardrailDecision row) + /stream SSE endpoint row updated + ToolEnd post-guardrail guarantee note.
  - BC-2.06.001 v1.3: H1 title sync + PC2 12-variant list (GuardrailDecision added) + PC4 causal ordering clause + NEW EC-006 K-of-N scenario (GuardrailDecision K events per graph execution; convention: EC-without-TV; Phase-3 test obligation noted; test-vectors UNCHANGED 513).
  - BC-2.11.002 v1.6: PC3 Fail emission clause + PC4 Transform emission clause.
  - BC-2.11.005 v1.3: PC1 streaming-surface extension (GuardrailDecision emitted to stream on Fail/Transform) + NEW INV-5 (post-guardrail content guarantee on streaming surface).
  - BC-2.06.003 v1.3: stream-observer-only invariant updated (GuardrailDecision: streaming surface only; unary execution path does not emit).
  - BC-2.06.002 v1.2 verified no-change: every-variant guarantee covers GuardrailDecision by construction (variant count is authority; BC-2.06.002 requires all variants handled — no text change needed).
  - BC-INDEX: BC-2.06.001 title cell updated to new H1.
  - events.md v1.3 (BA): StreamEventEmitted trigger line updated to reference GuardrailChecked stream-surface emission + ToolInvoked event tool_end post-guardrail note.
  - **Variant-count sweep:** zero other enumerations in the corpus were affected. Gate #12 unaffected.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |
| OBS | 1 (adjudicated substantive → scope expansion D18-P99-A) |

**Overall Assessment:** pass-with-findings (1 OBS adjudicated to scope expansion — fixed in burst 181)
**Convergence:** FINDINGS_REMAIN (strict — 1 OBS finding present, adjudicated substantive; fixed in burst 181)
**Readiness:** CLEAN (PR-merge) — zero CRIT+HIGH+MED findings

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 99 |
| **New findings** | 1 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | MEDIUM (genuinely new cross-subsystem seam: SS-06↔SS-11 observability gap; not a fix-echo or census-propagation class) |
| **Median severity** | OBS (adjudicated substantive) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1 |
| **CLEAN (strict)** | no (1 OBS finding adjudicated substantive) |
| **CLEAN (PR-merge)** | yes (zero CRIT+HIGH+MED) |
| **Verdict** | FINDINGS_REMAIN (NOT CLEAN strict); CLEAN (PR-merge) |

## Process Note

**Hook false-positive (routed from PO — non-blocking [process-gap]):** The `validate-count-propagation` hook triggered on a BC-INDEX edit during burst-181 fix work by matching "12 BCs" in STATE.md decision row D18-P78-A (text: "12 BCs lacked prefix") as a live count. D18-P78-A is immutable historical audit trail (decisions-log rows record past events; their numeric literals are not live census claims). The hook's context-exemption logic does not distinguish decisions-log literals from live counts. Candidate engine improvement: decisions-log and changelog rows should be pattern-excluded from count-propagation validation. Logged as [process-gap], non-blocking; no fix required in this burst.
