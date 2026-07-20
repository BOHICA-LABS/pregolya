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
pass: 124
previous_review: pass-123.md
---

# Adversarial Review: ferrochain (Pass 124)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 123 produced three findings:
- F-P123-01: Burst-206 CORRIGENDUM rows 2/8 Explanation re-embeds phantom ContentBlock::ToolUse variant with {id,name,input_schema,description} — exact F-P122-02 defect class reintroduced in corrigendum prose; spec corpus CORRECT and unaffected
- OBS-P123-a [process-gap]: Carry-forward axes §Tool/§McpServer/§MemoryStore named non-existent interface-definitions sections; passes 121–122 cleared vacuously; existence-validation mandated; codified as L-023
- OBS-P123-b: MemoryStore trait signature absent from interface-definitions §Public Rust Trait Signatures; promoted to blocker; fixed in burst 208 fix burst 126

Fix burst 126 was dispatched (BA: interface-definitions v2.38→v2.39 §MemoryStore trait block; PO: BC-2.15.006 v1.1→v1.2 PC1+EC-001+Anchors). Verification follows.

### F-P123-01 / OBS-P123-a / OBS-P123-b Verification — CLOSED

**PASS-124 sibling-checks verification (checks a–e from PASS-124 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) interface-definitions v2.39 §MemoryStore trait — every method traces to a BC-2.15.001/002 PC, no invented methods | PARTIAL PASS — 6 methods present (memory_set→BC-2.15.001 PC1; memory_get→BC-2.15.001 PC2; memory_delete→BC-2.15.001 PC3; memory_search/vector_search/hybrid_search→BC-2.15.001 PC4–PC6); no invented methods confirmed. EXCEPTION: E-MEMORY-003 raise site attached to memory_get violates taxonomy; see F-P124-01 |
| (b) BC-2.15.006 v1.2 memory_get notation coherent with interface-definitions v2.39 (MemoryScope::App(spec.namespace)) | PASS — BC-2.15.006 v1.2 PC1 calls memory_get(MemoryScope::App(spec.namespace), &spec.key); EC-001 text updated; Architecture Anchors consistent |
| (c) CORRIGENDUM-2 present in burst-log.md + prior corrigendum rows 2/8 unrewritten (CORRECTED Canon {id,name,args} retained) | PASS — CORRIGENDUM-2 block appended after CORRIGENDUM-1 in burst-log.md; rows 2/8 CORRECTED Canon {id,name,args} per BC-2.08.002 retained; Explanation clause superseded and corrected (no ContentBlock::ToolUse; Tool-entity fields at entities-graph:52 clarified); original audit rows unrewritten per immutable-audit-trail discipline |
| (d) MemoryScope/MemoryEntry types coherent with BC-2.15.002 scope semantics (User/App/Session variants) | PASS — MemoryScope enum User/App/Session variants per BC-2.15.002 PC1/PC2/PC3; MemoryEntry struct scope/key/value/author_id fields per BC-2.15.001 PC4–PC7 + BC-2.15.003 §Invariants; types coherent with scope semantics |
| (e) grep "MemoryStore::get(" zero live hits in active spec body | PASS — zero live hits for MemoryStore::get( in active spec body; all corrected to memory_get in BC-2.15.006 v1.2 |

**F-P123-01 conclusion:** CLOSED — CORRIGENDUM-2 appended; rows 2/8 Explanation clause corrected (ContentBlock::ToolUse phantom eliminated; Tool-entity field attribution at entities-graph:52 clarified); CORRECTED Canon {id,name,args} intact.

**OBS-P123-a conclusion:** CLOSED — L-023 applied; §Tool/§McpServer axis retired; existence-validation before clearing/carrying-forward mandated for all future passes.

**OBS-P123-b conclusion:** CLOSED — §MemoryStore trait block present in interface-definitions v2.39 with 6-method surface, E-MEMORY-001/002/003/004 raise sites, BC-2.15.001/002 traced. NOTE: E-MEMORY-003 placement defect discovered during this verification; see F-P124-01 in Part B.

**Carry-forward axes sweep (from pass-123):**

| Axis | Result |
|------|--------|
| ADR-008/ADR-010/ADR-011 soundness | PASS — reviewed; no gaps or contradictions with current spec corpus |
| ss-14 ↔ nfr-catalog timeout (NFR-009) | PASS — BC-2.14.* performance contracts reviewed against NFR-009; timeout alignment confirmed; no misalignment |
| ss-06 ordering ↔ BC-2.12.007 | PASS — run ordering invariant in ss-06 reviewed against BC-2.12.007; consistent |
| interface-definitions v2.39 §MemoryStore trait soundness (pass-123 NEW) | PARTIAL PASS — method traces and type coherence PASS; E-MEMORY-003 placement defect found → see F-P124-01 |
| BC-2.15.006 v1.2 memory_get notation coherence (pass-123 NEW) | PASS — PC1 + EC-001 + Architecture Anchors all use memory_get(MemoryScope::App(spec.namespace), &spec.key); coherent |

---

## Part B — New Findings

### F-P124-01 — HIGH: E-MEMORY-003 Mis-Anchored to memory_get — Security-Boundary Error Placement Defect

**Severity:** HIGH
**Scope:** `specs/prd-supplements/interface-definitions.md` §MemoryStore trait; E-MEMORY-003 taxonomy anchor vs. method placement

#### Evidence

interface-definitions v2.39 §MemoryStore assigns E-MEMORY-003 as a raise site on the `memory_get` method. However, two separate authorities contradict this placement:

**BC-2.15.002 Invariant — read path = isolation-by-invisibility:** The `memory_get` read path is governed by the isolation-by-invisibility principle: cross-owner reads return `Ok(None)` silently. This is a deliberate security boundary — a caller with User-scope cannot distinguish "key does not exist" from "key exists but is owned by another scope." Raising a domain error on `memory_get` would:
1. Leak information across scope boundaries (cross-owner existence oracle via error signal)
2. Contradict BC-2.15.002 PC1 which mandates silent `Ok(None)` for cross-scope invisible entries
3. Violate TV-001 which asserts `Ok(None)` as the canonical cross-owner read outcome

**Error taxonomy semantic anchor — E-MEMORY-003 = WRITE error:** E-MEMORY-003 is defined in the taxonomy as a WRITE-class error, quota/capacity failure on write operations (anchor: BC-2.15.002 Invariant WRITE path). It is semantically incompatible with a read method.

**memory_set gap:** `memory_set` lacked E-MEMORY-003 in interface-definitions v2.39 despite being the authoritative write-path where quota/capacity failures occur. BC-2.15.002 Invariant explicitly binds the write quota constraint to `memory_set` (PC2/PC3 enforce that writes into a scope that would exceed quota raise a write error).

**Correct E-MEMORY placement table:**

| Code | Method | Class | Semantic |
|------|--------|-------|---------|
| E-MEMORY-001 | vector_search | RETRIEVAL | Vector index / embedding failure |
| E-MEMORY-002 | memory_set | WRITE | Write path storage error (capacity/IO) |
| E-MEMORY-003 | memory_set | WRITE | Quota/capacity exceeded on write (BC-2.15.002 Invariant) |
| E-MEMORY-004 | memory_get | READ | Read/IO failure (distinct from isolation-by-invisibility Ok(None)) |

**Defect table — interface-definitions v2.39 vs. correct placement:**

| Claim in v2.39 | Correct Statement |
|----------------|-------------------|
| E-MEMORY-003 raise site: memory_get | E-MEMORY-003 raise site: memory_set (WRITE error; quota/capacity exceeded) |
| memory_get may raise E-MEMORY-003 | memory_get read path = Ok(None) isolation-by-invisibility (BC-2.15.002 PC1/TV-001); E-MEMORY-004 covers legitimate read errors |
| memory_set has no E-MEMORY-003 | memory_set should raise E-MEMORY-003 per BC-2.15.002 Invariant WRITE path |

**Security note:** Placing a WRITE-class error on a read path creates an owner-detection oracle risk: an adversarial caller could attempt writes to probe whether a quota error vs. absence error would be raised differently on read. The isolation-by-invisibility principle exists precisely to prevent such side-channels. The mis-placement is therefore a security-boundary defect, not merely a semantic mislabeling.

**Root cause:** Fix burst 126 (OBS-P123-b) added the §MemoryStore trait block without a fresh-context adversary review of error code placement against the taxonomy's WRITE/READ class split. The implementer correctly identified the four E-MEMORY codes and added them as raise sites but did not validate that E-MEMORY-003's taxonomy anchor (WRITE class, BC-2.15.002 Invariant) is incompatible with memory_get's read semantics. This is a fix-introduced regression of class MEDIUM-HIGH novelty.

---

### F-P124-02 — MED: VP-001/003/004/005 Remain at L3 Template Level — 1-vs-4 Corpus Split Since Burst-117

**Severity:** MED
**Scope:** `specs/verification-properties/VP-001.md`, `VP-003.md`, `VP-004.md`, `VP-005.md`

#### Evidence

VP-002 was advanced to L4 canonical template conformance in burst-117. The L4 canonical template includes:
- Full extended frontmatter (37-field core: `proof_method`, `red_gate`, `input_hash`, `lifecycle`, `source_contract`, and extended field set)
- Source Contract section
- Proof Method section
- Lifecycle section

VP-001/003/004/005 remained at the pre-burst-117 L3 level: incomplete frontmatter (missing `proof_method`, `red_gate`, `input_hash`, `lifecycle` fields and the full 37-field core) and absent extended sections.

**Corpus split:**

| VP | Current level | Target level | Proof method | Note |
|----|---------------|--------------|-------------|------|
| VP-001 | L3 | L4 | kani | BSP Reducer Determinism; Kani proof target |
| VP-002 | L4 | L4 (already) | kani | Advanced in burst-117; reference VP |
| VP-003 | L3 | L4 | kani | BSP Checkpointer Isolation; Kani proof target |
| VP-004 | L3 | L4 | manual, red_gate=true | MCP Tool Contract Integrity; R11 dependency |
| VP-005 | L3 | L4 | manual, red_gate=true | Memory Store Isolation; R11 dependency |

**Impact on Phase 6 (Formal Hardening):** The formal-verifier agent consumes VP files as specifications. Non-uniform structure means:
- Absent `proof_method` field on VP-001/003: automated tooling cannot resolve Kani vs. manual without parsing prose
- Absent `red_gate: true` on VP-004/005: R11 gate enforcement is invisible to tooling
- Non-uniform section inventory creates parsing inconsistencies in agent context

**Root cause:** Burst-117 template conformance was applied to VP-002 only (the VP that was under immediate adversary scrutiny). No subsequent adversary pass (118–123) included VP structural uniformity as a carry-forward axis. Template-conformance sweeps applied to 1-of-N siblings without explicit corpus-wide scope should be treated as incomplete.

---

## Carry-Forward Axes — No New Findings (for pass-125)

The following axes were swept in pass 124 and produced no new findings beyond F-P124-01/02. Carry forward for pass-125:

- **ADR-008/ADR-010/ADR-011 soundness:** PASS — reviewed; no new gaps.
- **ss-14 ↔ nfr-catalog timeout (NFR-009):** PASS — consistent.
- **ss-06 ordering ↔ BC-2.12.007:** PASS — consistent.
- **interface-definitions v2.40 §MemoryStore E-MEMORY placement (NEW — fixed by burst-127):** Carry forward to verify E-MEMORY placement table (001 vector_search / 002+003 memory_set / 004 memory_get) in v2.40 against BC-2.15.001/002 EC/TV raise sites; memory_get isolation-by-invisibility text present and coherent with PC1/TV-001/PC6.
- **VP corpus L4 uniformity (NEW — fixed by burst-127):** Carry forward to verify all 5 VPs uniform L4 (section inventory + 37-field core frontmatter); proof_method kani (VP-001/003) and manual (VP-004/005); input-hash --check PASS; VP-INDEX level:L3 UNCHANGED (index-doc convention).
- **BC-2.15.006 v1.2 memory_get notation coherence:** PASS — carry forward.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 (F-P124-01: E-MEMORY-003 mis-anchored to memory_get in interface-definitions v2.39; BC-2.15.002 defines memory_get read path as Ok(None) isolation-by-invisibility; E-MEMORY-003 = WRITE error per taxonomy; memory_set lacked E-MEMORY-003; security-boundary mis-anchor — owner-detection oracle risk; introduced by burst-126 §MemoryStore fix) |
| MED | 1 (F-P124-02: VP-001/003/004/005 remain at L3 template level while VP-002 advanced to L4 in burst-117; 1-vs-4 corpus split; absent proof_method/red_gate frontmatter fields; Phase 6 formal-verifier will encounter non-uniform VP contracts) |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **2** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision

**CLEAN (strict):** no (1 HIGH + 1 MED; strict-zero requires ZERO findings of any severity)
**CLEAN (PR-merge):** no (1 HIGH + 1 MED findings present)

**Convergence counter:** 0/3 (counter unchanged — pass 124 NOT CLEAN strict; fix burst 127 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** MEDIUM-HIGH (F-P124-01 is a "fix-introduced regression" class: burst-126 §MemoryStore fix introduced a new higher-severity defect on the same surface it fixed — security-boundary mis-anchor with owner-detection oracle risk; this extends the "correction that needs correction" class from pass-123 to a higher severity with a security dimension; F-P124-02 is a template-conformance-sweep gap: 1-of-N sibling updated without corpus-wide sweep; first VP-level occurrence of this class)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 124 |
| **New findings** | 2 (F-P124-01 HIGH, F-P124-02 MED) |
| **Cleared axes** | F-P123-01 CLOSED (CORRIGENDUM-2 verified; Explanation clause corrected; CORRECTED Canon {id,name,args} intact); OBS-P123-a CLOSED (L-023 applied; phantom axes retired; existence-validation mandated); OBS-P123-b CLOSED (§MemoryStore present; method-trace PARTIAL PASS; E-MEMORY-003 placement defect = F-P124-01 Part B) |
| **Novelty score** | MEDIUM-HIGH — fix-introduced regression with security-boundary dimension (E-MEMORY-003 on read path = owner-detection oracle risk; burst-126's own fix introduced it without fresh-context adversary review); VP sibling sweep gap is a known-class (1-of-N template sweep) but first VP-level occurrence and directly impacts Phase 6 tooling |
| **Median severity** | HIGH (F-P124-01 dominant; security-boundary finding class elevates trajectory above prior pass) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1→1→3→5→3→2 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1H/1M; counter 0/3 unchanged; fix burst 127 dispatched; NEXT: pass 125 on new HEAD after fix burst 127) |
