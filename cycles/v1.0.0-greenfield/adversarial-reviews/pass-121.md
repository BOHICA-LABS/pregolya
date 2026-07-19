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
pass: 121
previous_review: pass-120.md
---

# Adversarial Review: ferrochain (Pass 121)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 120 produced one finding:
- F-P120-01: Command modeled as 2-variant enum in `entities-server.md:78` + `ubiquitous-language-core.md:142` vs BC-2.05.004 authoritative struct {resume,update,goto,graph}+Command.PARENT; compound commands EC-001/TV-002/TV-003 unrepresentable

Fix burst 123 was dispatched (entities-server v1.9→v1.10; ubiquitous-language-core v1.0→v1.1). Verification follows.

### F-P120-01 Verification — CLOSED

**PASS-121 sibling-checks verification (checks a–e from PASS-121 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) entities-server v1.10 §ResumeValue Command depicted as struct-with-optional-fields — {resume: Option\<ResumeValue\>, update: Option\<UpdateValue\>, goto: Option\<GotoValue\>, graph: Option\<SubgraphValue\>} — matching BC-2.05.004 PC2 exactly, not enum form | PASS — entities-server v1.10 §ResumeValue Command is a struct with four optional fields; enum form absent; combinability invariant prose present |
| (b) ubiquitous-language-core v1.1 §ResumeValue Command same struct form mirrors BC-2.05.004 fields/semantics | PASS — ubiquitous-language-core v1.1 §ResumeValue Command mirrors BC-2.05.004 struct form with same four optional fields |
| (c) grep "Command::" for zero live enum-form depictions in domain-spec (entities-server.md, ubiquitous-language-core.md) | PASS — no live enum-form `Command::Resume(...)` / `Command::Update(...)` depictions in domain-spec; capabilities-p0.md §API-call notation exempt (API-call shorthand, not type definition) |
| (d) E-GRAPH-015 cite in entities-server v1.10 coherent with canonical E-GRAPH-015 definition in error-taxonomy | PASS — E-GRAPH-015 in entities-server v1.10 cites "invalid subgraph dispatch routing" consistent with error-taxonomy canonical definition; no redefinition conflict |
| (e) No BC/supplement drift introduced by the Command struct rewrite (BC-2.05.004 fields/semantics unchanged; domain spec depiction updated only) | PASS — BC-2.05.004 v1.4 unchanged in fix burst 123; ubiquitous-language-core and entities-server updated to mirror BC; no BC or supplement normative content modified |

**F-P120-01 conclusion:** CLOSED — entities-server v1.10 and ubiquitous-language-core v1.1 both correctly depict Command as struct-with-optional-fields; enum form absent; combinability invariant present; BC-2.05.004 semantics preserved.

---

## Part B — New Findings

### F-P121-01 — HIGH: L2 ContentBlock Depictions Drifted from BC-2.01.001 PC2 Canonical 14-Variant Form

**Severity:** HIGH
**Scope:** `specs/domain-spec/entities-graph.md`; `specs/domain-spec/ubiquitous-language-core.md`

#### Evidence

**BC-2.01.001 PC2 canonical 14-variant ContentBlock (normative):**

BC-2.01.001 PC2 defines ContentBlock as a tagged-union type with exactly 14 variants: Text, Image, Audio, File, ToolUse, ToolCallResult, Thinking, DataContent, ImageUrl, Document, NonStandard (DI-008 discriminant), MediaContent, RefusalContent, BinaryContent. Each variant carries a discriminated type tag plus variant-specific payload fields. DI-008 (NonStandard) is the extensibility escape hatch for future upstream variants; its presence in the canon is mandatory per the DI-008 invariant. ToolCallResult (not ToolResult) is the variant name per BC-2.01.001.

**BC-2.09.002 ToolMessage canon (normative):**

BC-2.09.002 establishes ToolMessage as a distinct message type (not a ContentBlock variant). ToolResult is a payload type carried inside ToolMessage, not a standalone ContentBlock enum arm. Any L2 depiction of ToolResult as a ContentBlock variant contradicts BC-2.09.002's structural canon.

**Domain spec depictions (contradictory):**

`entities-graph.md` and `ubiquitous-language-core.md` both depict ContentBlock with approximately 5 variants: ToolUse, ImageUrl, Document, ToolResult (as a ContentBlock arm), and one additional variant. Deviations:

| Axis | BC-2.01.001 / BC-2.09.002 Canon | L2 Depiction | Violation |
|------|---------------------------------|--------------|-----------|
| Variant count | 14 | ~5 | MISSING 9 variants |
| ToolCallResult naming | ToolCallResult (BC-2.01.001) | ToolResult (wrong name) | Name drift |
| ToolResult classification | ToolMessage payload (BC-2.09.002) | ContentBlock variant | Structural contradiction |
| NonStandard / DI-008 | Present (DI-008 mandatory) | Absent | Missing required extensibility hook |
| ToolUse fields | BC-defined field set (id, name, input_schema, description) | Wrong fields (id/type/function — JSON-RPC style) | Field-schema drift |

**Root cause:** entities-graph.md and ubiquitous-language-core.md §ContentBlock sections were authored from an early draft of BC-2.01.001 before the 14-variant hardening and ToolMessage/ToolResult split settled (BC-2.09.002 adjudication). The L2 shards were not updated in parallel with the BC strengthening.

**Impact:** HIGH — entities-graph.md is the normative entity reference for Phase 3 implementers. Phase 3 implementing ContentBlock from entities-graph would produce an incomplete 5-variant type, missing ToolCallResult/Thinking/Audio/File/DataContent/MediaContent/RefusalContent/BinaryContent, would misclassify ToolResult as a ContentBlock arm (violating ToolMessage seam), and would use wrong ToolUse fields (JSON-RPC form vs BC form). Source-of-truth precedence (CLAUDE.md §Source-of-Truth Precedence Rule 1): BC wins on contract semantics; domain spec must mirror BC.

---

### F-P121-02 — MED: L2 Message Role Enum Missing Function/Chat/Remove Extension Roles

**Severity:** MED
**Scope:** `specs/domain-spec/entities-graph.md`; `specs/domain-spec/ubiquitous-language-core.md`

#### Evidence

**BC-2.01.002 PC7 / EC-005 canonical role set (normative):**

BC-2.01.002 PC7 defines the Message role enum as a 7-member union: four primary roles (Human, AI, System, Tool) plus three extension roles (Function, Chat, Remove). EC-005 specifies the Function/Chat/Remove extension roles must be structurally present in the type definition; omitting them creates an incomplete role discriminant that cannot represent extension-role messages in transit.

**Domain spec depictions (contradictory):**

`entities-graph.md` and `ubiquitous-language-core.md` both depict Message role as a closed 4-role enum {Human, AI, System, Tool}, omitting Function, Chat, and Remove. A closed 4-variant enum in Phase 3 implementation would make extension-role messages unrepresentable — any incoming message with role=Function or role=Chat would fail to decode or would default to an incorrect variant.

**Impact:** MED — BC-2.01.002 EC-005 classification mandates Function/Chat/Remove be present in the role discriminant; their absence in both L2 shards is a coverage gap for the extension-role surface. Not CRIT because the three extension roles are lower-traffic than the four primary roles, but MED because the type definition directly affects message decoding in Phase 3.

---

### OBS — Process-Gap: Per-Token Sweeps Too Narrow; Mandate One-Time Comprehensive L2-vs-BC Type Audit

**Severity:** OBS [process-gap]
**Scope:** Phase 1d adversarial review methodology

#### Observation

The L2 domain spec is a 15-shard corpus (~1,889 lines) with entity/glossary sections that depict types from the BC corpus. Prior adversary passes have probed individual BC-vs-L2 alignment only when a specific BC strengthening event occurred (e.g., Command struct hardening triggered a pass-120 sweep of L2 Command depictions). This per-token sweep pattern leaves systemic L2 drift invisible until a BC strengthening event incidentally surfaces the gap.

F-P121-01 and F-P121-02 are not individually novel; they follow the same BC-strengthening-without-L2-propagation pattern as F-P120-01. The root cause is methodological: no pass has ever run a comprehensive census of ALL L2 type depictions against ALL BC-defined canonical forms. The per-token sweep pattern will continue to produce HIGH/MED findings in future passes whenever a new BC strengthening event touches a type also depicted in the L2.

**Mandate:** After fix burst 124 closes F-P121-01/02, a one-time comprehensive L2-vs-BC type audit should be conducted and published as a 37-row table covering all type depictions in all 15 L2 shards. This audit serves as the class-closure deliverable: once the audit table shows MATCH across all rows, the BC-strengthening-without-L2-propagation class is considered converged and this process-gap OBS is closed. Subsequent BC strengthenings must include an L2 propagation check in-burst.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 (F-P121-01: ContentBlock ~5-variant L2 depiction vs BC-2.01.001 PC2 canonical 14; wrong ToolCall fields; ToolResult wrongly a ContentBlock variant; NonStandard/DI-008 absent) |
| MED | 1 (F-P121-02: Message 4-role closed enum vs BC-2.01.002 PC7/EC-005 — Function/Chat/Remove extension roles absent in entities-graph + ubiquitous-language-core) |
| LOW | 0 |
| OBS | 1 (process-gap: per-token sweeps leave systemic L2-vs-BC type drift; mandate comprehensive audit as class-closure deliverable) |
| **Total findings** | **3** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision

**CLEAN (strict):** no (1 HIGH + 1 MED + 1 OBS; strict-zero requires ZERO findings of any severity)
**CLEAN (PR-merge):** no (1 HIGH + 1 MED findings present)

**Convergence counter:** 0/3 (counter unchanged — pass 121 NOT CLEAN strict; fix burst 124 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** HIGH (systematic L2-vs-BC type-depiction audit gap exposed for the first time; ContentBlock 14-variant and Message 7-role gaps are novel finding classes for Phase 1d; prior passes swept individual BC-strengthening events but never the full L2 type registry; OBS process-gap class-closing audit mandated and fulfilled in fix burst 124)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 121 |
| **New findings** | 3 (F-P121-01 HIGH, F-P121-02 MED, OBS process-gap) |
| **Cleared axes** | F-P120-01 CLOSED (Command struct-with-optional-fields; enum form absent; E-GRAPH-015 coherent; no BC/supplement drift) |
| **Novelty score** | HIGH — first comprehensive L2-vs-BC type audit sweep; ContentBlock 14-variant gap and Message 7-role gap are new finding classes; ToolResult/ToolMessage structural mismatch is a novel seam violation in L2 corpus |
| **Median severity** | HIGH (F-P121-01 HIGH anchors; F-P121-02 MED; OBS non-blocking) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1→1→3 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1H/1M/1OBS; counter 0/3 unchanged; fix burst 124 dispatched; NEXT: pass 122 on new HEAD after fix burst 124) |
