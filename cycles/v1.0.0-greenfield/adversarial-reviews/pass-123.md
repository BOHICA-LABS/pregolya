---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 123
previous_review: pass-122.md
---

# Adversarial Review: ferrochain (Pass 123)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 122 produced five findings:
- F-P122-01: ContentBlock drifted-vocabulary residue at 3 corpus sites outside L2 audit scope — capabilities-p0:42 CAP-001; bounded-contexts:138 Splitters seam; BC-2.11.002:105-106
- F-P122-02: Burst-206 audit rows 2/8 — wrong ToolCall canon {id,name,args} vs cited {id,name,input_schema,description}; phantom §ToolUse cite
- F-P122-03: Burst-206 audit row 34 phantom — edge-cases.md has no OnCeiling section; actual table at entities-server.md:98 §BudgetConfig
- OBS-P122-a [process-gap]: L2 audit scope excluded BC layer + capability enumerations
- OBS-P122-b: Audit row 22 pre-fix depiction fabricated ("get" vs "get_tuple")

Fix burst 125 was dispatched (PO: BC-2.11.002 v1.8→v1.9; BA: capabilities-p0 v1.4→v1.5 + bounded-contexts v1.1→v1.2; burst-206 CORRIGENDUM-1 appended). Verification follows.

### F-P122-01 / F-P122-02 / F-P122-03 Verification — CLOSED

**PASS-123 sibling-checks verification (checks a–e from PASS-123 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) BC-2.11.002 v1.9 EC-002/003 canonical ContentBlock::Image vocabulary — zero image_url in active body | PASS — EC-002 now reads "ContentBlock::Text + ContentBlock::Image"; EC-003 now reads "ContentBlock::Image → ContentBlock::Text error block"; corpus-wide census: 14 hits total — 2 fixed (BC-2.11.002:105-106), 12 exempt (BC-2.08.013 wire-format ×4 + changelog rows); zero non-exempt residue |
| (b) capabilities-p0 v1.5 CAP-001 full 14-variant ContentBlock canon + ToolMessage note present | PASS — CAP-001 lists all 14 ContentBlock variants (Text/Image/Audio/File/ToolUse/ToolCallResult/Thinking/DataContent/ImageUrl/Document/NonStandard/MediaContent/RefusalContent/BinaryContent) per BC-2.01.001 PC2; ToolMessage note present (ToolResult is ToolMessage payload per BC-2.09.002, not a ContentBlock variant) |
| (c) bounded-contexts v1.2 Splitters seam output type Vec\<String\> coherent with BC-2.07.001/002/003 + Document variant absent | PASS — Splitters seam output type is Vec\<String\>; ContentBlock wrapping = caller responsibility; "Document variant" reference removed; BC-2.07.001/002/003 seam contract satisfied |
| (d) Burst-206 CORRIGENDUM present in burst-log.md + original rows 2/8/22/34 unrewritten | PASS — CORRIGENDUM-1 block appended after burst-206 content; rows 2/8/22/34 original text intact per immutable-audit-trail discipline; corrections in separate CORRIGENDUM block |
| (e) Independent token grep — zero non-exempt drift for ToolUse/ImageUrl/Document-variant-name/ContentBlock::ToolResult/image_url (BC-2.08.013 wire-format + changelogs exempt) | PASS — corpus-wide grep confirmed: zero non-exempt active-body hits for deprecated vocabulary; token census independently verifies fix burst 125 corpus-wide coverage |

**F-P122-01 conclusion:** CLOSED — vocabulary residue at 3 sites corrected; corpus-wide census confirmed zero non-exempt drift.

**F-P122-02 conclusion:** CLOSED (audit-log perspective) — CORRIGENDUM-1 rows 2/8 updated the CORRECTED Canon to {id, name, args} per BC-2.08.002 TV-001/TV-003. NOTE: the CORRIGENDUM-1 Explanation text contains a residue defect; see F-P123-01 in Part B.

**F-P122-03 conclusion:** CLOSED — CORRIGENDUM-1 row 34 corrected to entities-server.md §BudgetConfig.

**Carry-forward axes sweep (from pass-122):**

| Axis | Result |
|------|--------|
| ADR-008/ADR-010/ADR-011 soundness | PASS — reviewed clean; no gaps or contradictions with current spec corpus |
| ss-09 §Tool/§McpServer (carry-forward from pass-122) | NOTE: §Tool and §McpServer are NOT defined sections in interface-definitions.md. Pass-122 cleared this axis with "Reviewed — no ContentBlock vocabulary drift; seam types correct" against non-existent sections. The clear was vacuous. No ContentBlock drift found at ss-09 BC-2.09.* Tool/MCP contracts. §ToolCallDialect (the actual relevant interface-definitions section) carries no drift. See OBS-P123-a. |
| ss-14 ↔ nfr-catalog timeout (NFR-009) | PASS — BC-2.14.* performance/reliability contracts reviewed against nfr-catalog.md NFR-009; timeout alignment confirmed; no misalignment found |
| ss-15 ↔ §MemoryStore | NOTE: §MemoryStore section was ABSENT from interface-definitions.md until fix burst 126 (burst 208). The pass-122 carry-forward "ss-15 ↔ §MemoryStore: BC-2.15.* memory store contracts reviewed against entities-server §MemoryStore — no type drift" cleared a phantom section. See OBS-P123-b for blocker finding. |
| ss-06 ordering ↔ BC-2.12.007 | PASS — Run ordering invariant in ss-06 reviewed against BC-2.12.007; consistent |

---

## Part B — New Findings

### F-P123-01 — MED: Burst-206 CORRIGENDUM Rows 2/8 Re-Embed Phantom ContentBlock::ToolUse Assertion

**Severity:** MED
**Scope:** `cycles/v1.0.0-greenfield/burst-log.md` — burst-206 CORRIGENDUM-1 block, rows 2 and 8 Explanation text

#### Evidence

The CORRIGENDUM-1 (issued in burst 207, appended to burst-log.md) correctly updated the CORRECTED Canon for rows 2 and 8 from `{id, name, input_schema, description}` to `{id, name, args}` per BC-2.08.002 TV-001/TV-003. However, the Explanation text for both rows contains:

> "The actual fix in entities-graph v1.2 correctly set ContentBlock::ToolUse variant fields to `{id, name, input_schema, description}` per BC-2.01.001 PC2"

This Explanation clause re-embeds two errors that are the exact F-P122-02 defect class:

**Error 1 — Phantom variant name:** There is no `ContentBlock::ToolUse` variant in entities-graph v1.2's 14-variant ContentBlock enum. The runtime invocation variant is `ContentBlock::ToolCall` with canonical fields `{id, name, args}` per BC-2.08.002 TV-001/TV-003. `ToolUse` is not a canonical ContentBlock variant name.

**Error 2 — Wrong field attribution:** The fields `{id, name, input_schema, description}` are **Tool entity definition fields** at entities-graph.md §Tool (approximately line 52). They describe the schema-specification struct for a tool registered with the LLM (the tool definition). They are NOT fields of any ContentBlock variant.

| Claim in CORRIGENDUM-1 Explanation | Correct Statement |
|------------------------------------|-------------------|
| ContentBlock::ToolUse variant exists with {id,name,input_schema,description} | No ContentBlock::ToolUse variant; ContentBlock::ToolCall = {id,name,args} (BC-2.08.002 TV-001/TV-003) |
| {id,name,input_schema,description} are ContentBlock variant fields | These are Tool entity fields (entities-graph.md §Tool ~line 52) — the tool definition schema |
| Authority: BC-2.01.001 PC2 §ToolUse | No §ToolUse section in BC-2.01.001 PC2 (phantom cite) |

**Spec corpus status:** CORRECT and unaffected. entities-graph v1.2 correctly has `ContentBlock::ToolCall` with `{id, name, args}`. This defect is confined to the audit-log CORRIGENDUM prose in burst-log.md. The CORRECTED Canon row (`{id, name, args}` per BC-2.08.002) is correct and must be preserved; only the Explanation clause requires correction.

**Root cause:** The CORRIGENDUM-1 Explanation was written by the implementer (fix burst 125) without fresh-context adversarial review. The explanation attempted to describe the pre-fix state but used the wrong vocabulary, re-embedding the field-name conflation it was documenting. Corrigendum prose is audit-trail content that subsequent adversary passes read as authoritative; defects in corrigendum explanations propagate false authority.

---

### OBS-P123-a — Process-Gap: Carry-Forward Axis Targets Must Be Existence-Validated Before Clearing or Carrying Forward

**Severity:** OBS [process-gap]
**Scope:** Phase 1d adversarial review methodology; carry-forward axis label protocol

#### Observation

The carry-forward axes inherited from pass-122 included "ss-09 §Tool/§McpServer" and "ss-15 ↔ §MemoryStore." Both axis labels name specific sections in interface-definitions.md.

**§Tool and §McpServer:** No sections with these names exist in interface-definitions.md. interface-definitions.md §Public Rust Trait Signatures contains §CheckpointSaver, §WriteGuard — not §Tool or §McpServer. When pass-122 cleared "ss-09 §Tool/§McpServer — Reviewed — no ContentBlock vocabulary drift; seam types correct," there were no such sections to review. This was a vacuous clear. The axis originated in pass-121 and was inherited unchanged by pass-122.

**§MemoryStore:** This section was absent from interface-definitions.md until fix burst 126 (burst 208) added it. The pass-122 axis "ss-15 ↔ §MemoryStore: BC-2.15.* memory store contracts reviewed against entities-server §MemoryStore — no type drift" cleared against a phantom section.

**Cumulative effect:** Both passes 121 and 122 cleared axes against phantom sections, producing a false "PASS" signal for those axes. The adversary-dispatch model assumes axis labels accurately identify reviewable spec content; when labels reference non-existent sections, the clear provides zero assurance.

**Mandate for future passes:** Before clearing or carrying forward any named-section axis, the adversary MUST:
1. Verify the named section exists in the target document (direct read or grep)
2. If the section is absent: mark the axis `PHANTOM-SECTION` (not PASS) and route to the appropriate specialist to add the section or retire the axis label
3. Record the corrected section name in the carry-forward axis label when the axis is re-established under a new or corrected name

**Codification status:** Tagged [codified] — lesson L-023 added to lessons.md.

---

### OBS-P123-b — MemoryStore Trait Signature Absent from Interface-Definitions §Public Rust Trait Signatures

**Severity:** OBS (promoted to blocker under production-grade lens)
**Scope:** `specs/prd-supplements/interface-definitions.md` §Public Rust Trait Signatures

#### Observation

interface-definitions.md §Public Rust Trait Signatures contains full trait blocks for:
- **CheckpointSaver** (5-method, v2.36+): get_tuple, put_writes, put, list, get_next_version
- **WriteGuard** (BC-2.15.005): write guard decision trait

**Absent:** `MemoryStore` — a P1 SS-15 storage abstraction defined by BC-2.15.001 with a 6-method public surface: memory_set, memory_get, memory_delete, memory_search, vector_search, hybrid_search.

BC-2.15.001 mandates the 6-method trait as a public API surface (`ferrochain-memory` crate). The trait is fully specified at the BC level (BC-2.15.001 PC1–PC7, BC-2.15.002 scope isolation, BC-2.15.003 GDPR erasure constraints). MemoryStore is a first-class P1 public trait on par with CheckpointSaver in terms of implementation complexity and API surface area.

Under the production-grade default, this observation is promoted to a blocker: P1 public traits that define the implementable interface for external consumers require full trait signatures in interface-definitions when their same-subsystem siblings are specified there.

**Fix burst 126 address:**
- interface-definitions.md v2.38→v2.39: §MemoryStore trait block added (6-method surface, MemoryScope/MemoryEntry types inline, error raise sites, BC anchor traces)
- BC-2.15.006.md v1.1→v1.2: PC1 method name corrected (MemoryStore::get → memory_get) and scope parameter made explicit (MemoryScope::App(spec.namespace))

---

## Carry-Forward Axes — No New Findings (for pass-124)

The following axes were swept in pass 123 and produced no findings. They are carried forward into pass-124 sibling-checks for fresh-context confirmation:

- **ADR-008/ADR-010/ADR-011 soundness:** Reviewed — no gaps or contradictions with current spec corpus.
- **ss-14 ↔ nfr-catalog timeout (NFR-009):** BC-2.14.* performance contracts reviewed against NFR-009 — consistent; no misalignment.
- **ss-06 ordering ↔ BC-2.12.007:** Run ordering invariant in ss-06 reviewed against BC-2.12.007 — consistent.
- **interface-definitions v2.39 §MemoryStore trait soundness (NEW):** Fixed by OBS-P123-b; carry forward to verify every method traces to a BC-2.15.001/002 PC, no invented methods; MemoryScope/MemoryEntry types coherent with BC-2.15.002.
- **BC-2.15.006 v1.2 memory_get notation coherence (NEW):** Fixed by fix burst 126; carry forward to verify PC1 + EC-001 + Architecture Anchors all use memory_get(MemoryScope::App(spec.namespace), &spec.key).

Note: ss-09 §Tool/§McpServer axis RETIRED — sections do not exist in interface-definitions.md per OBS-P123-a. §ToolCallDialect (actual relevant section) has no ContentBlock drift and is confirmed clean.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 (F-P123-01: burst-206 CORRIGENDUM rows 2/8 Explanation phantom ContentBlock::ToolUse claim — {id,name,input_schema,description} are Tool-entity fields (entities-graph:52), not ContentBlock variant fields; no ContentBlock::ToolUse variant; ContentBlock::ToolCall = {id,name,args} per BC-2.08.002; spec corpus CORRECT; corrigendum prose defect only) |
| LOW | 0 |
| OBS | 2 (OBS-P123-a [process-gap]: carry-forward axes §Tool/§McpServer/§MemoryStore named non-existent interface-definitions sections; passes 121–122 cleared vacuously; existence-validation mandated. OBS-P123-b: MemoryStore trait signature absent from interface-definitions §Public Rust Trait Signatures while P1 SS-15 siblings present; promoted to blocker; fixed in burst 208 fix burst 126) |
| **Total findings** | **3** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision

**CLEAN (strict):** no (1 MED + 2 OBS; strict-zero requires ZERO findings of any severity)
**CLEAN (PR-merge):** no (1 MED finding present)

**Convergence counter:** 0/3 (counter unchanged — pass 123 NOT CLEAN strict; fix burst 126 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** MEDIUM-HIGH (two novel elements: (1) "correction that needs correction" — the CORRIGENDUM-1 prose re-embedded the exact field-name conflation it was correcting (F-P122-02 defect class) in the Explanation clause, while the CORRECTED Canon row was correct; corrigendum text written without fresh-context review is a new blind-spot class; (2) phantom-section axis-clears — adversary cleared axes against sections that don't exist in the target document, producing vacuous PASS signals across two consecutive passes; these classes are related: both arise when audit-log content (corrigendum prose, axis labels) is written without the fresh-context adversary constraint that governs spec content)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 123 |
| **New findings** | 3 (F-P123-01 MED, OBS-P123-a [process-gap], OBS-P123-b) |
| **Cleared axes** | F-P122-01 CLOSED (BC-2.11.002 v1.9 + capabilities-p0 v1.5 + bounded-contexts v1.2 all PASS); F-P122-02 CLOSED (CORRECTED Canon correct; Explanation clause defect = F-P123-01); F-P122-03 CLOSED (row 34 corrected attribution PASS); OBS-P122-a CLOSED (corpus-wide census demonstrated to work); OBS-P122-b CLOSED (row 22 audit-only) |
| **Novelty score** | MEDIUM-HIGH — "correction that needs correction" class (corrigendum prose defect re-embeds the defect class it corrected) is novel; phantom-section axis-clear is adjacent to prior phantom-cite class (F-P122-03) but specifically targets the adversary's own carry-forward protocol rather than spec content; both arise from absent fresh-context review of audit-trail artifacts |
| **Median severity** | LOW-MED (1M dominant; 2 OBS non-blocking; spec corpus clean; defects confined to audit-log prose) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1→1→3→5→3 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1M/2OBS; counter 0/3 unchanged; fix burst 126 dispatched; NEXT: pass 124 on new HEAD after fix burst 126) |
