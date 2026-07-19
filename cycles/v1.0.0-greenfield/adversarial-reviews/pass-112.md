---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T20:30:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 112
previous_review: pass-111.md
---

# Adversarial Review: ferrochain (Pass 112)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 111 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P111-01 | MED [process-gap] | RESOLVED | gate #33 v2.38 Step-A Form 3 wrapper-form detection independently verified: (1) dual grep patterns (3a: `FerrochainError` wrapper-identifier pattern; 3b: false-positive disambiguation check) present and executable in bc-authoring-plan v2.38 Step A. (2) E-CORE-007 context-sourced exception registered: `<boundary>` ← `ProvenanceTag.boundary_type`, `<content_type>` ← IngressContent variant discriminant — both deterministically available as arguments to `GuardrailHook::evaluate()` at panic catch site; registration verified in gate #33 registry. (3) BC-2.11.002/003/004 all carry inline context-source annotations naming both fields; FerrochainError bare wrappers now annotated. (4) E-RETRY-002 BC-2.16.002 v1.2 inline template `"global retry limit of <global_limit> exhausted"` confirmed; `<global_limit>` rendered explicitly. (5) Full Form-3 census result: 17 codes / 27 violation sites across 17 BC files; independent re-enumeration finds ZERO remaining wrapper violations. error-taxonomy v1.25 Form-3 census scope addition documented; no corrigendum (no taxonomy row changes). Version note below. PASS. |

**Sibling-checks (burst-196 owed list):**

| Check | Result |
|-------|--------|
| (a) gate #33 v2.38 Form-3 procedure + wrapper-form discipline present in bc-authoring-plan (bare {category, code} valid ONLY for placeholder-less codes; inline message: template / PASS-ABBREV / registered context-source required for codes with placeholders) | PASS — Step A Form 3 dual grep patterns (3a wrapper-identifier + 3b false-positive check) confirmed in bc-authoring-plan v2.38; wrapper-form discipline clause present: bare `{category, code}` form scoped to zero-placeholder codes only; three resolution paths (inline template / PASS-ABBREV / context-sourced exception) enumerated |
| (b) E-CORE-007 context-source registration precise — `<boundary>` ← ProvenanceTag.boundary_type, `<content_type>` ← IngressContent variant discriminant — coherent with BC-2.11.002/003/004 + BC-2.06 guardrail dispatch semantics | PASS (with VERSION NOTE): context-source registry in bc-authoring-plan v2.38 confirmed; three BCs carry inline context-source annotations; BC-2.06 guardrail dispatch semantics coherent — boundary values BoundaryType::ToolResult/RAGRetrieval/MemoryIngress match BC-2.06.001 dispatch table. **VERSION NOTE:** BC-2.11.002 found at v1.7 (not v1.6 as stated in burst-196 checkpoint); BC-2.11.002 was already at v1.6 from F-P99-01 before burst-115 bumped it to v1.7 (brief-side staleness only — file content correct; generates F-P112-01 on the qualified form, see below). BC-2.11.003 and BC-2.11.004 found at v1.6 as noted — consistent. |
| (c) E-RETRY-002 v1.2 inline template renders `<global_limit>` — verify template string in BC-2.16.002; ascending changelog v1.1→v1.2 | PASS — BC-2.16.002 v1.2 PC5 carries `Err(E-RETRY-002 RetryGlobalLimitReached: "global retry limit of <global_limit> exhausted")`; `<global_limit>` explicitly rendered; changelog ascending v1.1→v1.2 confirmed |
| (d) spot-verify 6 of the 27 fixed wrapper sites strictly from v2.38 text (BC-2.01.001 v1.2, BC-2.03.001 v1.5, BC-2.08.001 v1.3, BC-2.08.004 v1.5, BC-2.09.002 v1.2, BC-2.17.002 v1.3) | PASS — all 6 sites verified; inline message: template forms present; no bare wrapper-only forms for placeholder-bearing codes; ascending changelogs confirmed for all 6 |
| (e) verify NO new message: template contradicts its taxonomy Message Format row (gate #33 semantic agreement, D18-P77-B) | PASS — 17/17 sampled templates match taxonomy verbatim per full re-enumeration table below; E-CORE-007 context-sourced entries annotate the correct field names; **EXCEPTION: qualified form used in BC-2.11.002/003/004 context-source annotations generates F-P112-01** (see Part B — value correctness finding, not template mismatch) |

**17-Template Verification Table (Form-3 census independent re-run, 17 BC sites):**

| # | BC | Code(s) | Template Form | Taxonomy Match | Verdict |
|---|----|---------|---------------|----------------|---------|
| 1 | BC-2.01.001 v1.2 | E-CORE-001 | inline message: template | verbatim | PASS |
| 2 | BC-2.03.001 v1.5 | E-GRAPH-006 + E-GRAPH-017 | inline message: template (both) | verbatim (both) | PASS |
| 3 | BC-2.04.001 v1.2 | E-CHKPT-001 | inline message: template | verbatim | PASS |
| 4 | BC-2.04.004 v1.2 | E-GRAPH-007 | inline message: template | verbatim | PASS |
| 5 | BC-2.04.006 v1.4 | E-CORE-005 + E-CHKPT-005 | inline message: template (both) | verbatim (both) | PASS |
| 6 | BC-2.08.001 v1.3 | E-PROV-003 | inline message: template | verbatim | PASS |
| 7 | BC-2.08.004 v1.5 | E-PROV-001 + E-PROV-006 + E-CORE-005 | inline message: template (all three) | verbatim (all three) | PASS |
| 8 | BC-2.08.007 v1.4 | E-PROV-003 | inline message: template | verbatim | PASS |
| 9 | BC-2.09.002 v1.2 | E-MCP-004 | inline message: template | verbatim | PASS |
| 10 | BC-2.11.002 v1.7 | E-CORE-007 | context-sourced exception | taxonomy placeholders `<boundary>`, `<content_type>` covered — **qualified form `IngressContent::ToolResult` used; see F-P112-01** | PASS-WITH-NOTE |
| 11 | BC-2.11.003 v1.6 | E-CORE-007 | context-sourced exception (symmetric) | same note | PASS-WITH-NOTE |
| 12 | BC-2.11.004 v1.6 | E-CORE-007 | context-sourced exception (symmetric) | same note | PASS-WITH-NOTE |
| 13 | BC-2.14.004 v1.2 | E-PROV-002 | inline message: template | verbatim | PASS |
| 14 | BC-2.15.004 v1.2 | E-MEMORY-008 | inline message: template | verbatim | PASS |
| 15 | BC-2.16.001 v1.3 | E-RETRY-001 | inline message: template | verbatim | PASS |
| 16 | BC-2.16.002 v1.2 | E-RETRY-002 | inline message: template | verbatim | PASS |
| 17 | BC-2.17.002 v1.3 | E-GRAPH-008 | inline message: template | verbatim | PASS |

Independent Form-3 enumeration (grep patterns 3a + 3b): ZERO unresolved wrapper-form violations found across all 95 BCs post burst-115. All wrapper-form sites either carry inline message: templates, PASS-ABBREV forms, or registered context-sourced exceptions.

**Assessment:** F-P111-01 RESOLVED verbatim. Sibling-checks (a)–(e) all PASS. 17-template verification PASS (PASS-WITH-NOTE on items 10–12 generates F-P112-01 below). Independent Form-3 census: ZERO remaining violations.

## Part B — Axes Exercised (new axes, this pass)

### Axis 1: events.md / BC-2.06.x Boundary-Enum Coherence

Verified that BoundaryType enum values used across the codebase surface are consistent between:
- events.md §StreamEvent GuardrailDecision variant payload (`boundary` field type)
- BC-2.06.001 guardrail dispatch table (boundary-keyed routing)
- BC-2.11.002/003/004 context-source annotations (boundary_type values)

BoundaryType variants in scope: `ToolResult`, `RAGRetrieval`, `MemoryIngress`. All three appear consistently in all three artifact surfaces. No orphan boundary names; no cross-artifact enum drift. StreamEvent GuardrailDecision payload `boundary: IngressBoundary` (events.md) maps cleanly to BoundaryType in BC-2.06 dispatch. **CLEAN.**

### Axis 2: E-PROV-003 Cross-BC Anchor Verification

E-PROV-003 (ProviderAuthFailed) is anchored across two primary BCs: BC-2.08.001 (provider client construction failure path) and BC-2.08.007 (provider invocation authentication failure path). Verified:
- Both anchor BCs carry E-PROV-003 raise sites with matching message template (burst-115 inline template fix applies to both)
- Cross-anchor field-set consistent: both sites use the same placeholder set as the E-PROV-003 taxonomy row
- No additional BC sites discovered hosting E-PROV-003 beyond the two anchors

**CLEAN.** No cross-anchor divergence.

### Axis 3: interface-definitions §error-handling

Verified the §error-handling section of interface-definitions against error taxonomy and BC corpus:
- HTTP status code mapping rows consistent with error-taxonomy categorization (SECURITY→401/403, VAL→422, INTERNAL→500, POLICY→4xx, DURABILITY/TRANSIENT→503)
- Error body shape `{ code: "E-COMP-NNN", message: "...", category: "..." }` documented and consistent with BC error-code citations
- No orphan status-code rows (all rows have at least one BC citation or taxonomy code mapping)
- D18-P69-A range-notation ban confirmed: no range shorthand present in §error-handling rows

**CLEAN.** No defects found.

## Part B — New Findings

### MED

#### F-P112-01: E-CORE-007 `<content_type>` Rendered-Value Contradiction — interface-definitions §IngressContent Authority (Bare Name) vs Burst-115 Annotations (Qualified Enum-Path Form)

- **Severity:** MED
- **Owner:** PO
- **Category:** content (rendered-value contradiction; source-of-truth precedence violation; interface-definitions §IngressContent is pre-existing authoritative definition per CLAUDE.md §Source-of-Truth Precedence Rule 3)
- **Location:** BC-2.11.002 EC-001 + TV panic row; BC-2.11.003 EC-004 + TV panic row; BC-2.11.004 EC-004 + TV panic row; bc-authoring-plan.md gate #33 registry E-CORE-007 entry
- **Description:** `interface-definitions.md §IngressContent` defines the IngressContent enum variants with bare names — the variant for tool-result content renders as `"ToolResult"`, not `"IngressContent::ToolResult"`. This is the pre-existing authoritative definition: supplements supersede BC prose per Source-of-Truth Precedence Rule 3 (PRD supplements supersede BC prose for the same surface area; Rule 3 — more specific wins). Burst-115 added context-source annotations using the fully-qualified enum-path form `IngressContent::ToolResult` (BC-2.11.002), `IngressContent::RagChunk` (BC-2.11.003), `IngressContent::MemoryItem` (BC-2.11.004) in both the BC body text and the gate #33 context-sourced exception registry. These qualified-path forms contradict the §IngressContent authority which uses bare variant names. Rendered at runtime, the discriminant value would be `"ToolResult"` not `"IngressContent::ToolResult"` — the qualified form with the type prefix is a compile-time path, not a runtime variant name. Gate #33 registry cites the wrong rendered form for all three E-CORE-007 context-source entries.
- **Evidence:** interface-definitions.md §IngressContent: variants defined as `ToolResult(ContentBlock)`, `RagChunk(Value)`, `MemoryItem(Value)` — bare names; BC-2.11.002 EC-001 burst-115 annotation: `<content_type>` = `IngressContent::ToolResult` from `IngressContent variant discriminant` — qualified form (contradiction); gate #33 registry E-CORE-007 entry: `<content_type>` ← `IngressContent variant discriminant` — correct field, wrong rendered form. Symmetric violation at BC-2.11.003 (`IngressContent::RagChunk`) and BC-2.11.004 (`IngressContent::MemoryItem`).
- **Fix (completed in fix burst 116):** ADJUDICATED: BARE variant name wins. interface-definitions §IngressContent is pre-existing explicit authority — bare form was established first and has not been superseded. BC-2.11.002 v1.7→v1.8: qualified `"IngressContent::ToolResult"` → bare `"ToolResult"` in EC-001 and TV panic row; source description updated from `"content variant discriminant"` to `"IngressContent variant discriminant"` (preserves the containing type name for orientation while clarifying the value is the bare variant). BC-2.11.003 v1.6→v1.7 (symmetric; RagChunk). BC-2.11.004 v1.6→v1.7 (symmetric; MemoryItem). bc-authoring-plan gate #33 registry updated to v2.39: E-CORE-007 rendered values bare-quoted (`"ToolResult"`, `"RagChunk"`, `"MemoryItem"`). interface-definitions unchanged — it was already the correct authority.

#### F-P112-02: E-CORE-005 Single Taxonomy Format vs ≥4 Divergent Message Shapes Across ≥5 BCs [process-gap]

- **Severity:** MED [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (gate #33 SEMANTIC-AGREEMENT sub-check coverage gap for manually-authored non-template BC message texts; D18-P77-B step 7–10 verifies inline templates match taxonomy rows but does NOT sweep non-template prose in EC/TV description text for taxonomy Message Format conformance)
- **Location:** bc-authoring-plan.md gate #33 SEMANTIC-AGREEMENT sub-check scope; BC-2.04.002 EC-003, BC-2.04.007 EC-003, BC-2.08.002 EC-005, BC-2.08.006 EC-002, BC-2.08.014 EC-006
- **Description:** E-CORE-005 (ValidationFailed) taxonomy Message Format specifies a single canonical shape: `Validation failed for '<field>': <reason>`. The burst-115 Form-3 census successfully identified and fixed wrapper-form violations and added inline message: templates for many codes. However, gate #33 SEMANTIC-AGREEMENT sub-check (D18-P77-B steps 7–10) only verifies that `message:` field values in BC-body template annotations match the taxonomy Message Format row verbatim. It does NOT sweep manually-authored prose in EC description lines or TV Expected Output cells for conformance with the taxonomy Message Format. For E-CORE-005, the constraint is particularly tight (single prefix-pattern format), yet 5 BC sites shipped divergent manually-written message texts that do not conform to the canonical prefix. Corpus census reveals 8 total BC files hosting E-CORE-005 sites: 5 non-conforming (see census table), 3 already-conforming. This is a novel process class beyond wrapper-form detection — a BC can have the correct error code without a wrapper-form violation but still use a non-canonical message text in prose.
- **Evidence:** Corpus census of all E-CORE-005 BC sites (see census table below). Canonical taxonomy format: `Validation failed for '<field>': <reason>`. Non-conforming sites lack the required `Validation failed for` prefix.
- **Fix (completed in fix burst 116):** Canonical format `Validation failed for '<field>': <reason>` is the SINGLE required message shape. All 5 non-conforming sites corrected to canonical format. bc-authoring-plan v2.38→v2.39: census addendum documenting the 8-file E-CORE-005 sweep. error-taxonomy v1.25→v1.26: adjudication row added documenting both F-P112-01 and F-P112-02 resolutions.

**E-CORE-005 Corpus Census Table:**

| BC | EC | Pre-fix Message Text | Post-fix Message Text | Status |
|----|-----|---------------------|----------------------|--------|
| BC-2.04.002 | EC-003 | `unknown durability tier: "<value>"` | `Validation failed for 'durability': unknown tier "<value>"` | FIXED |
| BC-2.04.007 | EC-003 | `EncryptedSerializer: key material must be non-empty` | `Validation failed for 'key_material': must be non-empty` | FIXED |
| BC-2.08.002 | EC-005 | `model <name> does not support tool calling` | `Validation failed for 'model': model '<name>' does not support tool calling` | FIXED |
| BC-2.08.006 | EC-002 | `timeout must be set; use .timeout(Duration::from_secs(30))` | `Validation failed for 'timeout': must be set; use .timeout(Duration::from_secs(30))` | FIXED |
| BC-2.08.014 | EC-006 | `ProviderFallbackPolicy.chain must not be empty` | `Validation failed for 'ProviderFallbackPolicy.chain': must not be empty` | FIXED (corpus-sweep find, not in original finding) |
| BC-2.04.006 | (various) | already canonical — `Validation failed for '<field>': <reason>` | — | ALREADY-CONFORMING |
| BC-2.08.004 | (various) | already canonical | — | ALREADY-CONFORMING |
| BC-2.14.006 | (various) | already canonical | — | ALREADY-CONFORMING |

8 total BC files hosting E-CORE-005 sites: 5 FIXED, 3 already-conforming.

## Partial-Coverage Note

No axes remain unexercised from prior passes (pass-111 cleared all carry-forwards). Three new axes exercised this pass — all CLEAN. Two new findings (F-P112-01, F-P112-02) found and resolved in fix burst 116.

**Axes exercised this pass:**
- events.md/BC-2.06.x boundary-enum coherence: BoundaryType variants consistent across all surfaces — CLEAN
- E-PROV-003 cross-BC: both anchor BCs consistent, no cross-anchor divergence — CLEAN
- interface-definitions §error-handling: HTTP status mapping and error body shape consistent — CLEAN

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 2 |
| LOW | 0 |
| OBS / process-gap | F-P112-02 is process-gap class |
| **Total findings** | **2** |

**CLEAN (strict):** no (2M)
**CLEAN (PR-merge):** no (2M present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM (two genuinely new axes — F-P112-01 is a content-level source-of-truth precedence violation on a qualified vs bare enum-variant form that survived all prior Form-3 census passes; F-P112-02 is a novel process class: manually-authored BC prose message text can drift from taxonomy Message Format even without a wrapper-form violation; both are structurally fresh; however the underlying defect family — gate #33 census coverage gaps — is well-established at this point; 7th consecutive pass in the same family; novelty within a known family = MEDIUM)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 112 |
| **New findings** | 0H + 2M (F-P112-01 MED, F-P112-02 MED [process-gap]) |
| **Duplicate/variant findings** | Same defect CLASS as prior census-completeness findings (F-P108-04 through F-P111-01); F-P112-01 is specifically a source-of-truth-precedence violation on rendered value form; F-P112-02 is the first instance of the "non-template prose drift" class |
| **Novelty score** | MEDIUM (two structurally distinct axes at a deeper scope level; but the overarching defect family — gate #33 coverage gap — now accounts for 7 consecutive passes; the pattern is converging at successive refinement layers) |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2 |
| **CLEAN (strict)** | no (2M) |
| **CLEAN (PR-merge)** | no (2M present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
