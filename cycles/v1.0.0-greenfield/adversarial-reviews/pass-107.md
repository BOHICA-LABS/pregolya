---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T11:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 107
previous_review: pass-106.md
---

# Adversarial Review: ferrochain (Pass 107)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 106 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P106-01 | MED [process-gap] (PO+orchestrator) | RESOLVED | bc-authoring-plan v2.33→v2.34. Verified: (1) BC-INDEX.md present in Known Form-B-only files list under new "Indexes:" bullet; (2) catch-all text updated from "Any ADR or supplement..." to "Any index, ADR, or supplement..."; (3) independent difference-set recompute — files with `## Changelog` body section but no frontmatter `changelog:` key in .factory/specs/: {ADR-007, ADR-009, ADR-012, ADR-013, BC-INDEX.md, BC-2.07.002, BC-2.08.011, BC-2.08.012, bc-authoring-plan.md, test-vectors.md, verification-architecture.md} = 11 files; all 11 covered by explicit list or catch-all — zero omissions; L2-INDEX/ARCH-INDEX/VP-INDEX confirmed Form-A only (no `## Changelog` section, frontmatter `changelog:` key present); (4) v2.34 conventions PASS — descending changelog, timestamp-current 2026-07-18, consistent with D18-P86-A Rule 5. |
| OBS-P106-A | OBS (PO) | RESOLVED (fix correct; sweep-claim false → F-P107-01) | error-taxonomy v1.19→v1.20: E-MEMORY-006 Message Format corrected to `InsufficientPrivilege: operation '<operation>' requires <required>`. Verified: (1) "AdminContext" hardcode absent from Message Format column; (2) `<caller_privilege>` placeholder absent; (3) two remaining placeholders `<operation>` and `<required>` map 1:1 to BC-2.15.003 EC-005 struct fields {operation, required}; (4) BC-2.15.003 EC-005 struct unchanged — struct definition still {operation, required} (correctly). However: the accompanying sweep claim in burst-110 ("22 codes checked, 1 fixed, 21 PASS") is FALSE — adversary independent recompute found E-GRAPH-011 carries the same struct-field defect class. The E-MEMORY-006 fix itself is correct; the "21 PASS" sweep claim is not. See F-P107-01. |

**Sibling-checks (burst-190 owed list):**

| Check | Result |
|-------|--------|
| (a) gate #28 Form-B-only list: BC-INDEX.md present under "Indexes:" bullet; catch-all covers "Any index, ADR, or supplement"; difference-set 11 files zero omissions; L2-INDEX/ARCH-INDEX/VP-INDEX Form-A only | PASS — all four sub-points verified per F-P106-01 resolution above |
| (b) E-MEMORY-006 message is `InsufficientPrivilege: operation '<operation>' requires <required>` — 1:1 with BC-2.15.003 EC-005 struct {operation, required}; no "AdminContext" hardcode; no `<caller_privilege>` placeholder | PASS — per OBS-P106-A resolution above; BC-2.15.003 EC-005 unchanged at {operation, required} |
| (c) 22-code struct-bearing message sweep: sample MEMORY codes: E-MEMORY-002 {backend,path} ↔ `<backend>/<path>` PASS; E-MEMORY-003 {requested_scope,caller_identity} ↔ `<caller_identity>/<requested_scope>` PASS; E-MEMORY-005 {user_id,backend_error} ↔ `<user_id>/<reason>` PASS; E-MEMORY-007 {reason}+ns/key ↔ `<ns>/<key>/<reason>` PASS | PARTIAL PASS (MEMORY codes PASS; E-GRAPH-011 found to carry same-class defect during wider census rerun → F-P107-01; the claim "21 PASS" is therefore FALSE — three further same-class defects in E-GRAPH-007/001/004 also found) |
| (d) bc-authoring-plan v2.34 changelog row covers F-P106-01; error-taxonomy v1.20 changelog row covers OBS-P106-A; both descending and timestamp-current at 2026-07-18 | PASS — changelog conventions verified |

**Additional verification axes (independent probes, this pass):**

| Axis | Check | Result |
|------|-------|--------|
| VP-INDEX arithmetic + DI↔VP anchors | VP-INDEX total count and per-subsystem rows verified consistent; DI↔VP anchor citations in VP-001..VP-005 cross-checked | PASS — VP census 141; DI-001 anchor in VP-001, DI-011 anchor in VP-004/VP-005; no drift |
| NFR measurability | 11 NFR entries verified to carry numeric threshold or named test harness reference | PASS — 11/11 numeric+harness; no vague-only rows found |
| events.md v1.5 vocabulary | GuardrailChecked Outcome vocabulary (Pass/Fail/Transform), GuardrailDecision boundary qualifications (ToolResult vs RagChunk/MemoryItem per BC-2.06.001 PC4), DI-011 execution-vs-stream-observer equivalence clause | PASS — vocabulary verified; v1.5 changelog row consistent |
| Category descriptions | All 12 Error Categories table descriptions verified against current membership post-v1.19 | PASS — no regression; descriptions match full member sets |
| Gate #28 pre-emission check | MANDATORY PRE-EMISSION CHECK block present in bc-authoring-plan v2.34; Form A + Form B steps explicit; "finding is INVALID" gate labeled per form | PASS — block structure present and non-optional |

## Part B — New Findings

### MED

#### F-P107-01: E-GRAPH-011 BC-2.02.005 Struct Has Wrong Field Name and Missing Field; EC-003 Prose Ambiguity Caused Pass-106 Sweep to Pass the Defect

- **Severity:** MED
- **Owner:** PO
- **Category:** error-taxonomy-message-format (taxonomy message ↔ BC struct-field 1:1 parity; gate #33 SEMANTIC-AGREEMENT)
- **Location:** `.factory/specs/behavioral-contracts/ss-02/BC-2.02.005.md` §EC-003, §PC5, §TV-005 struct definitions; and transitively: same census class in BC-2.02.001 §EC-001/TV-005, BC-2.02.002 §PC3/EC-001/EC-002/TV-002, BC-2.02.003 §EC-003/TV-004
- **Description:** The burst-110 sweep of "22 struct-bearing codes, 21 PASS" is contradicted by E-GRAPH-011. The taxonomy message for E-GRAPH-011 ConditionalEdgePanic specifies two distinct placeholders: `<source_node>` (edge source node name) and `<message>` (captured panic text). BC-2.02.005 EC-003, PC5, and TV-005 prior to this fix defined the struct as `{ source: 'source_node' }` — a single-field struct with the field named `source`. Two independent defects existed: (1) **Wrong field name:** struct field `source` vs taxonomy placeholder `<source_node>`; (2) **Missing field:** no `message` field despite taxonomy placeholder `<message>`. The root cause of the pass-106 escape is identifiable in BC-2.02.005 EC-003 prose: "...preserving the panic message as the error source." The phrase `error source` was used loosely to mean "the thing the error is about" — which caused the pass-106 sweep to accept the single `source` field as covering both the source-node context and the panic text, without noticing the taxonomy requires two distinct fields. Census rerun during this pass found three further same-class defects in the SS-02 GRAPH error codes: E-GRAPH-007 (BC-2.02.001 struct `{ key }` missing `<node_id>`), E-GRAPH-001 (BC-2.02.002 struct `{ channel }` or `{ channel, reason }` missing `<task_ids>` and `<n>`), E-GRAPH-004 (BC-2.02.003 struct `{ channel, writer }` missing `<n>`). All four were the same root class.
- **Evidence:** Taxonomy §GRAPH pre-fix: E-GRAPH-011 Message Format `ConditionalEdgePanic: routing function for '<source_node>' panicked: <message>` — two placeholders. BC-2.02.005 EC-003 pre-fix struct: `{ source: 'source_node' }` — one field, wrong name. E-GRAPH-007 taxonomy `<node_id>/<key>` vs BC-2.02.001 struct `{ key }`. E-GRAPH-001 taxonomy `<channel>/<task_ids>/<n>` vs BC-2.02.002 struct `{ channel }`. E-GRAPH-004 taxonomy `<channel>/<writer>/<n>` vs BC-2.02.003 struct `{ channel, writer }`. Gate #33 BC-wins rule: the taxonomy placeholders are the authority for the struct fields; BC structs were under-specified.
- **Fix (completed in burst 191):** (1) BC-2.02.005 v1.1→v1.2: struct corrected to `{ source_node: <edge source node name>, message: <captured panic text> }` at PC5/EC-003/TV-005; ambiguous "preserving the panic message as the error source" prose removed from EC-003. (2) BC-2.02.001 v1.1→v1.2: E-GRAPH-007 struct corrected to `{ node_id, key }` at EC-001/TV-005. (3) BC-2.02.002 v1.1→v1.2: E-GRAPH-001 struct corrected to `{ channel, task_ids, step }` at PC3/EC-001/EC-002/TV-002; static-text `reason` field removed. (4) BC-2.02.003 v1.1→v1.2: E-GRAPH-004 struct corrected to `{ channel, writer, step }` at EC-003/TV-004. (5) error-taxonomy v1.20→v1.21: corrigendum row added documenting false "21 PASS" sweep claim; corrected census: 22 codes checked, 5 FAIL (E-MEMORY-006 fixed v1.20; E-GRAPH-011/007/001/004 fixed this burst), 17 PASS. Taxonomy rows unchanged — defect was BC-side only.

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 |
| LOW | 0 |
| **Total findings** | **1** |
| OBS / process-gap | 0 |

**CLEAN (strict):** no (1 MED)
**CLEAN (PR-merge):** no (1 MED present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** LOW-MEDIUM (same gate #33 struct-field parity class as OBS-P106-A; distinct escape mechanism — ambiguous-prose "error source" causing sweep to conflate two distinct fields into one — rather than the hardcoded-classname pattern of OBS-P106-A)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 107 |
| **New findings** | 1 MED (F-P107-01) |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | LOW-MEDIUM (F-P107-01: same gate #33 struct-field parity class as OBS-P106-A; escape mechanism — ambiguous EC-003 prose "error source" — is a new failure mode within that class; root-cause attribution to a single ambiguous phrase is distinct from the hardcoded-classname pattern of OBS-P106-A) |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1 |
| **CLEAN (strict)** | no (1 MED) |
| **CLEAN (PR-merge)** | no (1 MED present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
