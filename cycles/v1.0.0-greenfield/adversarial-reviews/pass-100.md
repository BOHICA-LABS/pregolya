---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T00:00:00Z
phase: 1d
pass: 100
previous_review: pass-99.md
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
---

# Adversarial Review: ferrochain (Pass 100)

## Finding ID Convention

Finding IDs use the project-local format: `F-P<PASS>-<SEQ>` (no current-cycle file; cycle prefix omitted per template fallback).

## Part A — Fix Verification (Pass 99 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P99-01 | OBS (adjudicated substantive → D18-P99-A) | RESOLVED | ADR-006 rev-3 + interface-definitions v2.34 + BC-2.06.001 v1.3 + BC-2.11.002 v1.6 + BC-2.11.005 v1.3 + BC-2.06.003 v1.3 + BC-INDEX title cell + events.md v1.3 all verified. Triple-agreement confirmed: 12-variant enum, field shapes, causal ordering exact match across ADR-006/interface-definitions/BC-2.06.001. |

**Pass-99 sibling checks (all PASS):**

| Check | Result |
|-------|--------|
| ADR-006 rev-3 ↔ interface-definitions v2.34 ↔ BC-2.06.001 v1.3 triple-agreement (12-variant enum + GuardrailDecision types + ordering) | PASS |
| BC-2.11.002 v1.6 PC3/PC4 Fail/Transform emission clauses present | PASS |
| BC-2.11.005 v1.3 PC1 streaming-surface extension + INV-5 | PASS |
| BC-2.06.003 v1.3 stream-observer-only invariant | PASS |
| events.md v1.3 StreamEventEmitted + GuardrailChecked + ToolInvoked tool_end note | PASS (see F-P100-01 / F-P100-03 below — partial) |
| BC-INDEX title cell byte-exact sync to BC-2.06.001 new H1 | PASS |
| EC-006 without TV (EC-without-TV convention) | PASS |
| test-vectors UNCHANGED 513 (504+9) | PASS |
| Corpus wire-token census (guardrail_decision present; no phantom tokens) | PASS |
| Enum-mapping probes (IngressContent↔IngressBoundary↔GuardrailSeverity) | PASS |
| DI-012 no-orphan check | PASS |
| prd.md staleness probe | PASS |
| CAP-007 11-token scope | NOT STALE (false-positive discipline; CAP-007 cleared correctly) |

---

## Part B — New Findings

### MEDIUM

#### F-P100-01: events.md StreamEventEmitted Outcome blanket contradicts guardrail_decision unary carve-out

- **Severity:** MEDIUM
- **Category:** contradictions
- **Location:** `.factory/specs/domain-spec/events.md` — `StreamEventEmitted` event `Outcome` field
- **Description:** The `StreamEventEmitted` Outcome carried a blanket clause "identical content delivered to unary callers (DI-011)". BC-2.06.001 v1.3 PC4 explicitly states `StreamEvent::GuardrailDecision` is **not** emitted in unary mode. DI-011 execution-path equivalence applies to execution-path events only; `guardrail_decision` is stream-observer-only. The blanket phrasing contradicted the unary carve-out established by D18-P99-A.
- **Evidence:** `events.md` v1.3 Outcome row: "identical content delivered to unary callers (DI-011)" — no exception for `guardrail_decision`. BC-2.06.003 v1.3 INV: `GuardrailDecision` not emitted in unary mode.
- **Proposed Fix:** Qualify Outcome: execution-lifecycle events observe DI-011 equivalence; `guardrail_decision` is stream-observer-only — unary callers observe via error blocks per BC-2.06.003.

**Fix applied:** `events.md` v1.3 → v1.4. Sole occurrence; no residue.

---

#### F-P100-02: BC-2.11.003 and BC-2.11.004 lack GuardrailDecision emission postconditions (SS-11 boundary asymmetry)

- **Severity:** MEDIUM
- **Category:** missing-edge-cases
- **Location:** `.factory/specs/behavioral-contracts/ss-11/BC-2.11.003.md`, `.factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md`
- **Description:** BC-2.11.002 (ToolResult boundary) gained PC3 (Fail-emission) and PC4 (Transform-emission) in burst 181. Siblings BC-2.11.003 (RAG/RagChunk boundary) and BC-2.11.004 (Memory/MemoryItem boundary) received no corresponding postconditions. The three SS-11 BCs form a symmetry group for guardrail ingress observability; ToolResult was fully specified while RAG and Memory boundaries were silent. D18-P99-A established GuardrailDecision fires at all three boundaries; the omission from two of three siblings was a propagation gap.
- **Evidence:** BC-2.11.003 (v1.4) and BC-2.11.004 (v1.4) — no PC3/PC4 equivalents; BC-2.11.002 v1.6 has both. ADR-006 rev-3 §EmissionOrdering specifies all three ingress boundaries.
- **Proposed Fix:** Add PC3 + PC4 to both BCs with boundary-adapted forms (RagChunk/MemoryItem, NodeStart/NodeEnd window, tool_call_id: None, INV-5 cites). Bump architect ADR-006 to rev-4 (citation-completeness). Bump interface-definitions to v2.35 (/stream row + §StreamEvent anchor extension).

**Fix applied:** BC-2.11.003 v1.4 → v1.5; BC-2.11.004 v1.4 → v1.5; ADR-006 rev-3 → rev-4; interface-definitions v2.34 → v2.35.

**9-dimension symmetry-triple verification (BC-2.11.002 v1.6 / .003 v1.5 / .004 v1.5):**

| Dimension | .002 | .003 | .004 | Status |
|-----------|------|------|------|--------|
| Boundary type | ToolResult | RagChunk | MemoryItem | Symmetric (by design) |
| PC3 Fail-emission present | yes | yes | yes | SYMMETRIC |
| PC4 Transform-emission present | yes | yes | yes | SYMMETRIC |
| tool_call_id field | Some(id) [ToolResult] | None | None | Intentional asymmetry (ADR-006 ordering; design-correct) |
| Emission window | before ToolEnd | within NodeStart/NodeEnd | within NodeStart/NodeEnd | Intentional asymmetry (per boundary class) |
| metadata-only payload | yes | yes | yes | SYMMETRIC |
| INV-5 cite present | yes | yes | yes | SYMMETRIC |
| run_id/parent_ids present | yes | yes | yes | SYMMETRIC |
| No TV rows for emission | yes | yes | yes | Consistent non-gap (noted for awareness; not a defect) |

---

### OBSERVATIONS

#### F-P100-03: events.md GuardrailChecked Outcome used retired Accept/Reject/Redact vocabulary

- **Severity:** OBS
- **Category:** ambiguous-language
- **Location:** `.factory/specs/domain-spec/events.md` — `GuardrailChecked` event `Outcome` field
- **Description:** The `GuardrailChecked` event Outcome field used `Accept/Reject/Redact` vocabulary, which was retired at F-P58-03 (ubiquitous-language-server §GuardrailHook v1.2). Canonical vocabulary is `Pass/Fail/Transform`. `Transform` is the strict superset of the retired `Redact`-only meaning; no semantic narrowing.
- **Evidence:** `events.md` v1.3 `GuardrailChecked` Outcome: "Accept, Reject, or Redact". ubiquitous-language-server §GuardrailHook v1.2 F-P58-03 retirement record: canonical = Pass/Fail/Transform.
- **Proposed Fix:** Align Outcome to Pass/Fail/Transform.

**Fix applied:** Consolidated into `events.md` v1.4 (same version bump as F-P100-01).

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 2 |
| LOW | 0 |
| OBS | 1 |

**Overall Assessment:** pass-with-findings (all fixed in-burst)
**Convergence:** FINDINGS_REMAIN — counter stays 0/3; adversary pass 101 next
**Readiness:** Requires adversary pass 101 to verify fixes and probe new scope (SS-11 triple symmetry, events.md v1.4, ADR-006 rev-4, interface-definitions v2.35)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 100 |
| **New findings** | 3 (F-P100-01, F-P100-02, F-P100-03) |
| **Duplicate/variant findings** | 3 — all are D18-P99-A propagation echoes (ToolResult boundary updated; RAG/memory siblings + events.md GuardrailChecked vocabulary missed) |
| **Novelty score** | 3 / (3 + 3) = 0.50 (MEDIUM; same propagation class, new locations) |
| **Median severity** | MED (2 MED + 1 OBS) |
| **Trajectory** | →…→1 (P1D-98) →1 (P1D-99) →3 (P1D-100) |
| **Verdict** | FINDINGS_REMAIN |

## Process Note

**GuardrailDecision radius CLOSURE expectation:** Pass-100 findings are the last expected echo of D18-P99-A. All three SS-11 ingress-boundary BCs are now symmetric (BC-2.11.002/003/004); events.md vocabulary is canonical; ADR-006 rev-4 cites all three. If pass 101 finds further radius residue, flag as `[process-gap]` on propagation discipline — the radius should be fully closed.

**CLEAN (strict):** no — 2 MED + 1 OBS (all fixed in burst 182)
**CLEAN (PR-merge):** yes — 0 CRIT/HIGH/MED unfixed
