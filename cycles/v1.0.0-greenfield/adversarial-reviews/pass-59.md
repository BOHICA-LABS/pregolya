---
document_type: adversarial-review
pass: 59
verdict: NOT_CLEAN
novelty: HIGH
finding_count: 2
high_count: 2
medium_count: 0
low_count: 0
timestamp: 2026-07-15T00:00:00Z
scope: prd-supplements, behavioral-contracts, domain-spec
---

# Adversarial Review — Pass 59

**Verdict:** NOT CLEAN — 2 findings (both HIGH). Novelty HIGH (mis-anchors introduced by pass-57/58 additions — citations one layer above the now-defined types).

---

## F-P59-01 (HIGH): GuardrailSeverity::Critical Authority Cites Ordering Invariants

**Location:** `interface-definitions.md` v2.13 §GuardrailHook — `GuardrailSeverity::Critical` doc-comment authority field.

**Finding:** The `Critical` variant doc-comment cites `"BC-2.11.002 INV-3, BC-2.11.003 INV-2, BC-2.11.004 INV-4, BC-2.11.005 PC4"` as authority. Of these:

- `BC-2.11.003 INV-2` states: "Ordering: ProvenanceTag attachment → GuardrailHook evaluation → model context insertion" — an **ordering invariant**, not a severity rule.
- `BC-2.11.004 INV-4` states: "Ordering: ProvenanceTag attachment → GuardrailHook evaluation → model context insertion" — likewise an **ordering invariant**, not a severity rule.

The Critical severity rule for those BCs lives in their **PC3** (postcondition 3), not INV-2 or INV-4:
- `BC-2.11.003 PC3`: "run continues unless `Critical`"
- `BC-2.11.004 PC3`: "run continues unless `Critical`"

The mis-citations contradict the same document's correct `Fail` variant citation ("BC-2.11.002 PC3, BC-2.11.005 PC4") and `entities-server.md` v1.3's correct citation ("BC-2.11.002 INV-3, BC-2.11.005 PC4/PC5").

**Correct anchors:** `BC-2.11.002 INV-3, BC-2.11.003 PC3, BC-2.11.004 PC3, BC-2.11.005 PC4`

---

## F-P59-02 (HIGH): Transform Type Drift — Bare ContentBlock in BCs + Cross-Boundary Claim in Interface Doc

**Location:** (a) `interface-definitions.md` v2.13 `GuardrailResult::Transform` doc-comment; (b) `BC-2.11.002` v1.3 EC-003/TV; (c) `BC-2.11.005` v1.1 EC-002/TV.

**Finding (a):** The `Transform` variant doc-comment reads: "The replacement may be any `IngressContent` variant, including a different variant from the original (BC-2.11.002 EC-003)." This claim is wrong. `BC-2.11.002 EC-003` authorizes a different **`ContentBlock` variant** within `IngressContent::ToolResult` (e.g., `image_url` → `text`), NOT a cross-`IngressContent`-boundary transform (e.g., `ToolResult` → `RagChunk`). A cross-boundary transform at a fixed ingress boundary (e.g., tool-result evaluator producing a `RagChunk`) is semantically nonsensical — no BC authorizes it.

**Finding (b):** `BC-2.11.002` EC-003 test vector writes `Transform { new_content: ContentBlock::text("[REDACTED: PII]") }`. Since `Transform.new_content: IngressContent` (established pass-57), a bare `ContentBlock` does not typecheck. Correct form: `Transform { new_content: IngressContent::ToolResult(ContentBlock::text("[REDACTED: PII]")) }`.

**Finding (c):** `BC-2.11.005` EC-002 test vector writes `GuardrailResult::Transform { new_content: ContentBlock::text("[REDACTED]") }`. Same typecheck failure — same fix: `Transform { new_content: IngressContent::ToolResult(ContentBlock::text("[REDACTED]")) }`.

**Canonical rule:** Transform stays within the same ingress boundary. `new_content` must be the same `IngressContent` variant as the input content; the inner payload may change freely (e.g., a different `ContentBlock` variant within `ToolResult`).

---

## OBS-P59-1 (Observation): ContentBlock ToolResult Variant Name Nesting

`ContentBlock`'s own `ToolResult` variant name nests inside `IngressContent::ToolResult` — currently unambiguous in context, but the naming co-incidence (both called `ToolResult`) may cause future confusion. Noted for naming clarity consideration. Not a defect at this time.

---

## Sibling Checks

| Check | Result | Note |
|-------|--------|------|
| Type citations coherent (E-CORE-007 linkage) | FAIL | Citations per F-P59-01 wrong; E-CORE-007 linkage otherwise coherent |
| entities-server.md v1.3 | PASS | Citations correct per existing content |
| BC PC1 linkages | PASS | All six ss-11 BCs correctly cite PC1 for evaluate call |
| Gate #31 re-run | PASS | 22 types; implementer-scope notes honored |

## Census Results

| Census | Result |
|--------|--------|
| #16 — Disposition closes (79) | PASS |
| #22 — Distribution confirmed | PASS |
| #24 — pass-58 bumps | PASS |
| #25 — pass-58 bumps | PASS |
| #28 — entities-graph v1.0 stable | PASS |

## Probes

| Probe | Result |
|-------|--------|
| (a) Type bodies coherent vs BC-2.11.003/005/006 corner cases (opacity/fail-closed/no-hook) | PASS — defects are in citations only |
| (b) ContentBlock definition exists, linkage resolves | PASS |
| (c) Authority-citation audit §GuardrailHook block | FAIL → F-P59-01, F-P59-02(a) |
