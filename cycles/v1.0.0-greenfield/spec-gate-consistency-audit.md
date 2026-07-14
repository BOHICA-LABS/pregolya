---
document_type: consistency-report
level: ops
version: "1.0"
producer: consistency-validator
timestamp: 2026-07-13T00:00:00Z
cycle: v1.0.0-greenfield
gate: spec-gate-phase-1
verdict: FAIL
finding_count: 18
blocking_count: 9
traces_to: .factory/cycles/v1.0.0-greenfield/
---

# Spec-Gate Consistency Audit — ferrochain Phase 1 Spec Package

**Auditor:** consistency-validator (fresh context)
**Gate:** Phase-1 spec crystallization gate (pre-Phase-2 story decomposition)
**Verdict:** **FAIL — 9 blocking findings**
**Consistency score:** 76% (18 findings; 9 Major blocking, 6 Minor, 3 Perimeter gaps)

---

## Summary Table

| Category | Status | Notes |
|----------|--------|-------|
| ID integrity — CAP/DI/ASM/FM/DEC/BC/VP IDs all exist in source-of-truth | PASS with exceptions | NE-05 misattributed in BC-INDEX VP Seed table; CONFLICT-9 dangling in 3 docs |
| Count consistency — BC totals, NFR counts, P0/P1/P2 splits | PARTIAL | bc-authoring-plan stale (82 vs 83); 82 carry-forward in BC-INDEX/PRD |
| Traceability chain — brief→domain-spec→PRD→BC→architecture→VP | FAIL | VP substitution (workspace confinement ≠ delta round-trip checkpoint) not propagated to 6 upstream docs; PRD RTM Module column unfilled |
| Cross-document contradiction | FAIL | PRD §2.09.005 title vs BC file title; NFR-002 wrong risk source; ADR-008 body/frontmatter status mismatch; dual risk ID scheme |
| Perimeter — gate criteria satisfied, no capability gaps | PARTIAL | test-vectors.md missing; NE-05 ADR unwritten; proc-macro BCs unblocked but not authored |
| Frontmatter / convention | PASS with exceptions | PRD stale SS-TBD note; bc-authoring-plan stale frontmatter fields |

---

## Findings Table

| # | Severity | Location | Finding | Suggested Route |
|---|----------|----------|---------|-----------------|
| F-01 | **Major** | product-brief.md §Scope (cross-cutting), §Success Criteria, §Overflow Competitive Differentiator Traceability | VP substitution unpropagated: three locations reference "delta round-trip checkpoint VP (CONFLICT-9)" and "session tenancy partition VP (NE-12)" as the D17-Q7 obligations, but VP-003 is Workspace Path Confinement (BC-2.13.004/DI-007/NE-02), not delta round-trip. The NFR catalog (NFR-003), verification-architecture.md, and BC-2.17.001 correctly reflect the substituted set. Product-brief was never updated. | product-owner |
| F-02 | **Major** | domain-spec/capabilities-p1-p2.md §CAP-019; domain-spec/differentiators.md D-03 row | VP substitution unpropagated (same root as F-01): CAP-019 names "delta round-trip checkpoint VP (CONFLICT-9)" and "session tenancy partition VP (NE-12)"; differentiators.md D-03 Phase-1 BC Anchor says "delta round-trip VP, session tenancy VP." Neither document was updated when workspace-confinement VP replaced delta-round-trip. Note: differentiators.md D-03 DI column is self-consistent (DI-001/DI-005/DI-007 matching the actual VPs) but the BC Anchor text contradicts the DI column. | business-analyst |
| F-03 | **Major** | prd-supplements/module-criticality.md, "Per-task checkpoint store" row | VP substitution unpropagated: row says "VP Count: 1 (delta-round-trip-VP)." No delta-round-trip-VP exists in VP-INDEX. The architecture-view module-criticality.md (authoritative) is correct. The PO-draft supplement was not updated. | product-owner |
| F-04 | **Major** | product-brief.md §Success Criteria; domain-spec/capabilities-p1-p2.md §CAP-019 | CONFLICT-9 is a dangling reference: "delta round-trip checkpoint (CONFLICT-9)" appears in both locations but CONFLICT-9 is not defined anywhere in the domain-spec (L2-INDEX Key Anchors documents CONFLICT-1 through CONFLICT-7 only). No COMPARATIVE-ASSESSMENT section anchor exists for CONFLICT-9 in any spec file. Once F-01/F-02 are resolved by removing the delta-round-trip VP references, CONFLICT-9 becomes irrelevant — but if the delta-round-trip VP is to be kept, its CONFLICT anchor must be documented. | product-owner |
| F-05 | **Major** | BC-INDEX.md, "VP Seed BCs" table, BC-2.04.006 row | Wrong NE anchor: table shows "NE-05" for BC-2.04.006 (Session Triple-Address Uniqueness). NE-05 is the cache-key content-hash CI lint gate, unrelated to session tenancy. The correct anchor is NE-12 (identity triple collapse). Confirmed by: invariants.md DI-005 Source = NE-12; L2-INDEX Key Anchors NE-12 → DI-005/FM-005; PRD §7 RTM BC-2.04.006 row = "CAP-005, DI-005, NE-12"; PRD §9 NE disposition NE-12 → BC-2.04.006. The BC file itself (BC-2.04.006) carries correct `vp_id: VP-002` but the index table NE column is wrong. | state-manager |
| F-06 | **Major** | BC-2.09.005.md, "Verification Properties" internal table | VP ID mismatch: BC-2.09.005's Verification Properties table references "VP-MCP-05" but VP-INDEX registers this BC's VP as VP-005 (VP-005 title: "MultiServerMcpClient Holds No Live Connections"). VP-MCP-05 does not exist in VP-INDEX. This is a stale internal working ID from authoring time, never updated when VP-005 was registered. | state-manager |
| F-07 | **Major** | prd.md §7 Requirements Traceability Matrix | Module column unfilled: all 83 BC rows still show "[architect]" in the Module column. Phase 1b is complete — ARCH-INDEX.md produced, SS-NN IDs backfilled to all BC files. The architect must populate the RTM Module column with the canonical module names from module-decomposition.md / ARCH-INDEX Subsystem Registry. Story-writer and test-writer will need this column in Phase 2. | architect |
| F-08 | **Major** | prd.md §2.09, BC-2.09.005 row | Title mismatch: PRD §2.09 table shows BC-2.09.005 as "MCP __aenter__ NotImplementedError contract (R11)" but BC-INDEX catalog and the actual BC file H1 heading read "MultiServerMcpClient Holds No Live Connections (Red Gate — R11)." These are semantically different descriptions — one focuses on the Python __aenter__ behavior being translated, the other on the Rust type contract. The BC file and BC-INDEX are consistent with each other; the PRD table is stale. Per criterion 75, H1 heading is the source of truth for BC title. | state-manager |
| F-09 | **Major** | prd-supplements/nfr-catalog.md, NFR-002 row | Wrong risk source: NFR-002 ("Tasks completed before process crash must not be lost when sync-tier checkpointing is active") cites "R-004 (correctness)" in the Risk Source column. In domain-spec/risks.md, R-004 = "Splitters code-point vs byte-length parity on non-ASCII input" — a completely different risk. NFR-002 addresses durability/crash recovery, which is not the subject of R-004. Correct source is either no specific domain-spec risk (the requirement derives from DI-002/CONFLICT-2) or R-003 (LangChain API stability). | product-owner |
| F-10 | **Major** | BC files (ss-02/BC-2.02.003, ss-02/BC-2.02.004, ss-07/BC-2.07.002, ss-09/BC-2.09.004, ss-09/BC-2.09.005); BC-INDEX Red Gate table; PRD §7 RTM | Dual risk register ID scheme: BC frontmatter `red_gate_source` fields and BC-INDEX Red Gate BCs table use STATE.md risk IDs (R8, R10, R11); PRD §7 RTM Source column uses domain-spec/risks.md IDs (R-004, R-005, R-006). These refer to the same risks but with different numbering. No document declares which scheme is canonical for BC anchoring. A reader tracing from BC-INDEX R10 to a risk narrative must know to look in STATE.md, not domain-spec/risks.md (where R-010 does not exist). Disambiguation required. | business-analyst |
| F-11 | **Minor** | prd-supplements/bc-authoring-plan.md, frontmatter | Stale counts: `total_bcs: 82`, `p1_count: 26`. BC-2.08.009 was added (PRD changelog Step-E) bringing totals to 83 BCs, 27 P1. The supplement was not updated. Body text also says "Total BCs | 82" in the Summary table. | state-manager |
| F-12 | **Minor** | BC-INDEX.md, Carry-Forward Notes #1 | Stale count: says "All 82 BCs now have `subsystem: SS-NN`" — should be 83 BCs. BC-2.08.009 was added after this note was written. | state-manager |
| F-13 | **Minor** | prd.md §2 intro note (lines ~138-139) | Stale text: "Until then all BCs carry `subsystem: SS-TBD`" — ARCH-INDEX.md was produced in Phase 1b and all SS-NN IDs backfilled. This statement is no longer true. | state-manager |
| F-14 | **Minor** | prd.md §2.04, BC-2.04.007 DI column | Field type mismatch: the PRD §2.04 table "DI" column contains "NE-11" for BC-2.04.007. NE-11 is an NE anchor, not a DI-NNN domain invariant. BC-2.04.007 itself acknowledges: "L2 Domain Invariants: (none — NE-11 is an operational safety requirement, not a named domain invariant)." The column header should reflect that this row's anchor is an NE, or the table should have separate DI and NE columns. | state-manager |
| F-15 | **Minor** | BC-INDEX.md, Full BC Catalog table, BC-2.04.006 row | DI Anchor omitted: the BC-INDEX catalog row for BC-2.04.006 has an empty DI Anchors column, but DI-005 clearly applies (PRD §7 RTM, PRD §2.04 table, VP-INDEX VP-002 DI field, invariants.md DI-005 all confirm DI-005 for this BC). | state-manager |
| F-16 | **Minor** | architecture/decisions/ADR-008-proc-macro-attributes.md, body text | Body/frontmatter status mismatch: frontmatter says `status: accepted` and ARCH-INDEX confirms "accepted — ADR-004 ✓", but the H2 heading in the body reads "**Status:** Proposed — GATED ON ADR-004 (D5, D17-Q6)." The body was not updated when the ADR was accepted. Also, body references "82-BC plan" (stale). | architect |
| F-17 | **Minor** | prd.md §8 OQR-4 | Stale count: OQR-4 says "They are not in the 82-BC plan" and "The 82-BC plan contains no proc-macro BCs." Should be 83-BC plan. | state-manager |
| F-18 | **Minor** | prd.md §9 NE Coverage Summary | Misleading summary: line reads "2 → CI lint gate only (NE-04, NE-05)." NE-04 actually has a BC anchor (BC-2.14.004) in addition to the CI lint gate — PRD §9 table entry for NE-04 shows "BC + CI lint gate." The summary's "CI lint gate only" applies to NE-05, not NE-04. Summary should read "1 → BC + CI lint gate (NE-04); 1 → CI lint gate only (NE-05)." | state-manager |

---

## Perimeter Gaps (Phase-2 Story Decomposition Blockers)

These are items not present in the spec package that Phase-2 will need or that represent
undocumented scope changes.

### PG-01 — Missing `prd-supplements/test-vectors.md` supplement (Criterion 66)

**Severity:** Major  
**What is missing:** prd-supplements/test-vectors.md is required by the 4-supplement
convention (criterion 66) and declared in PRD §5b: "Canonical test vectors will be in
`prd-supplements/test-vectors.md`. Produced in BC authoring sub-bursts. A consolidated
test-vectors.md will be produced after all BC files are authored." All 83 BCs are authored.
The file does not exist. Individual BC files carry per-BC canonical test vectors but no
consolidated supplement exists. PRD frontmatter lists only 5 supplements (omits test-vectors.md).  
**Who creates it:** product-owner, once BCs are complete.  
**Phase-2 impact:** test-writer will need the consolidated test vector catalog.

### PG-02 — NE-05 ADR unwritten (anchor is a declaration without substance)

**Severity:** Major  
**What is missing:** PRD §9 NE Disposition Table anchors NE-05 to "Architecture-phase ADR:
cache keys must be content hash of (resolved instruction bytes + sorted tool declarations)."
None of ADR-001 through ADR-010 covers this. The bc-authoring-plan.md §NE Anchor Summary
lists NE-05 as "CI lint gate (ADR, no BC)" but the ADR itself was never written.  
**Who creates it:** architect (one-paragraph ADR sufficient given it is CI lint gate only).  
**Phase-2 impact:** story-writer cannot anchor the cache-key lint gate to a concrete ADR
commitment; a story that implements the gate will have no spec authority.

### PG-03 — Proc-macro BCs (D5/D17-Q6) unblocked but not authored

**Severity:** Observation (not blocking for Phase-2 if proc-macro stories are deferred)  
**What is missing:** ADR-004 (D5 gate) is accepted. ADR-008 is accepted. PRD OQR-4 states
"If D5 ADR produces an ADOPT disposition, proc-macro BCs become a Phase-1b addition via the
BC authoring plan." ADR-004 header says "Accepted — D5 gate resolved; ADR-008 and proc-macro
BCs unblocked." No proc-macro BCs (#[tool], #[entrypoint], #[task]) are in the current
83-BC set.  
**Decision needed:** Product-owner must explicitly either: (a) author proc-macro BCs as a
Phase-1b amendment before Phase-2 story decomposition begins, or (b) document that proc-macro
BCs are deferred to Phase-2+ with a stated rationale. The current state is a gap in the
Phase-1 gate criteria per D17-Q6: "proc-macro BCs cannot be authored before D5 ADR" — that
precondition is now satisfied.  
**Phase-2 impact:** If proc-macro BCs don't exist, story-writer will produce stories for
#[tool]/#[task] without a behavioral specification, which violates the VSDD Phase-3 TDD
requirement that every story maps to a BC.

---

## Detailed Findings by Dimension

### Dimension 1: ID Integrity

All CAP-NNN (001–019), DI-NNN (001–014), DEC-NNN (001–013), ASM-NNN (001–009),
FM-NNN (001–012) IDs referenced anywhere were verified against their source-of-truth files.
All resolve correctly.

All BC-S.SS.NNN IDs in BC-INDEX catalog match actual files on disk (83 files, 83 rows). ✓

VP-001 through VP-005 in VP-INDEX match VP-001.md through VP-005.md files. ✓

ADR-001 through ADR-010 in ARCH-INDEX match decisions/ directory files. ✓

**Failures:** F-05 (NE-05 misattributed), F-04 (CONFLICT-9 dangling), F-06 (VP-MCP-05 stale).

### Dimension 2: Count Consistency

| Claim | Stated | Actual | Status |
|-------|--------|--------|--------|
| BC-INDEX total BCs | 83 | 83 | ✓ |
| BC-INDEX P0/P1/P2 | 48/27/8 | 48/27/8 | ✓ |
| PRD §7 RTM total | 83 | 83 | ✓ |
| bc-authoring-plan total_bcs | 82 | 83 | ✗ F-11 |
| bc-authoring-plan p1_count | 26 | 27 | ✗ F-11 |
| L2-INDEX CAP count | 19 | 19 | ✓ |
| L2-INDEX DI count | 14 | 14 | ✓ |
| L2-INDEX DEC count | 13 | 13 | ✓ |
| L2-INDEX ASM count | 9 | 9 | ✓ |
| L2-INDEX R count | 8 | 8 (domain-spec scheme) | ✓ |
| L2-INDEX FM count | 12 | 12 | ✓ |
| VP-INDEX total VPs | 5 | 5 | ✓ |
| VP-INDEX P0/P1 | 3/2 | 3/2 | ✓ |
| VP-INDEX Kani/integration | 3/2 | 3/2 | ✓ |
| verification-coverage-matrix totals | 5 (Kani 3 + integration 2) | matches VP-INDEX | ✓ |
| NE coverage | 17/17 | 17/17 (but NE-05 ADR missing — PG-02) | partial |

### Dimension 3: Traceability Chain

**L1 → L2:** product-brief.md → L2-INDEX.md via traces_to ✓  
**L2 → PRD:** L2-INDEX.md → prd.md (prd.md traces_to domain-spec/L2-INDEX.md) ✓  
**PRD → BC:** prd.md → behavioral-contracts/ss-NN/BC-*.md via §2 index ✓  
**BC → architecture:** BC files carry subsystem: SS-NN fields, mapping to ARCH-INDEX ✓  
**BC → VP:** VP seed BCs carry vp_seed: true and vp_id: VP-NNN; VP-INDEX confirms ✓  
**D17 commitments landed:**

| D17-Q | Commitment | BC Coverage | Status |
|-------|-----------|------------|--------|
| Q2 (HITL) | per-task scratchpad, FIFO, node re-execute, Command(resume=value) | BC-2.05.001–006 | ✓ |
| Q3 (per-task durability) | sync-default put_writes | BC-2.04.001–002 | ✓ |
| Q4 (budget governance) | allow/escalate/deny, evidence journal | BC-2.10.001–004 | ✓ |
| Q7 (VP obligations) | 3 Kani VPs committed | VP-001/002/003 exist | ✓ but VP names conflict with brief — F-01/F-02 |
| Q8 (content provenance) | guardrail-on-ingress at tool-result/RAG/memory | BC-2.11.001–006 | ✓ |
| Q9 (R8/R10/R11 Red Gates) | 5 Red Gate BCs authored | BC-2.02.003, BC-2.02.004, BC-2.07.002, BC-2.09.004, BC-2.09.005 | ✓ |

**Failures:** F-01 through F-04 (VP substitution not propagated back); F-07 (RTM Module unfilled).

### Dimension 4: Cross-Document Contradiction

| Pair | Contradiction | Finding |
|------|--------------|---------|
| product-brief VP names vs VP-INDEX VP names | Brief: delta round-trip + session tenancy; Index: session triple-address + workspace confinement | F-01 |
| BC-2.09.005 title in PRD §2.09 vs BC file H1 | PRD: "MCP __aenter__ NotImplementedError"; BC file: "MultiServerMcpClient Holds No Live Connections" | F-08 |
| ADR-008 frontmatter status vs body text | Frontmatter: accepted; Body: "Proposed — GATED ON ADR-004" | F-16 |
| NFR-002 risk source vs domain-spec/risks.md | NFR-002 cites R-004 (splitters); NFR-002 is about crash recovery | F-09 |
| BC-INDEX Red Gate table R-IDs vs PRD RTM R-IDs | BC-INDEX uses R8/R10/R11 (STATE.md); PRD RTM uses R-004/R-005/R-006 (domain-spec) | F-10 |

No contradictions found in: DI-NNN numbers, FM-NNN sources, CAP-to-BC mapping, ADR
decisions accepted vs ARCH-INDEX status, or NFR target values.

### Dimension 5: Perimeter — Gate Criteria

| Criterion | Status | Note |
|-----------|--------|------|
| Provable Properties Catalog (verification-architecture.md) complete | ✓ | 5 VPs cataloged |
| Purity Boundary Map exists and complete | ✓ | purity-boundary-map.md present |
| Verification tooling documented (tooling-selection.md) | ✓ | Kani, cargo-fuzz, cargo-mutants, proptest versions |
| Module criticality written (module-criticality.md architecture-view) | ✓ | 33 modules classified |
| All P0 CAPs have ≥1 BC | ✓ | CAP-001–008, CAP-012, CAP-013, CAP-016 all covered |
| All accepted ADRs anchored in ARCH-INDEX | ✓ | ADR-001–010 all listed |
| NE-05 ADR written | ✗ | PG-02 |
| test-vectors.md supplement exists | ✗ | PG-01 |
| Proc-macro BCs resolved (author or formally defer) | ✗ | PG-03 |

### Dimension 6: Frontmatter / Convention

All L2 domain-spec sections carry: `document_type: domain-spec-section`, `level: L2`,
`version`, `producer`, `timestamp`, `traces_to: L2-INDEX.md`. ✓

All BC files sampled carry: `document_type: behavioral-contract`, `level: L3`,
`subsystem: SS-NN`, `capability: CAP-NNN`, `lifecycle_status: active`. ✓

BC-INDEX header: `document_type: bc-index`, `level: L3`, `traces_to: prd.md`. ✓

VP-INDEX: `document_type: verification-property-index`, `level: L3`,
`traces_to: ARCH-INDEX.md`. ✓

ARCH-INDEX: `document_type: architecture-index`, `level: L3`, `traces_to: prd.md`. ✓

Input-hash present in all major artifacts sampled. BC-INDEX uses `"[live-index]"` placeholder
(acceptable for a live index that aggregates from child files).

---

## Blocking Findings Summary (Gate cannot pass)

| # | Finding | Owner |
|---|---------|-------|
| F-01 | VP substitution not propagated — product-brief (3 locations) | product-owner |
| F-02 | VP substitution not propagated — CAP-019, differentiators.md | business-analyst |
| F-03 | VP substitution not propagated — prd-supplements/module-criticality.md | product-owner |
| F-04 | CONFLICT-9 dangling reference in brief and CAP-019 | product-owner |
| F-05 | BC-INDEX VP Seed table: NE-05 → NE-12 for BC-2.04.006 | state-manager |
| F-06 | BC-2.09.005 internal VP ID: VP-MCP-05 → VP-005 | state-manager |
| F-07 | PRD RTM §7 Module column all "[architect]" — unfilled post-Phase-1b | architect |
| F-08 | BC-2.09.005 title mismatch between PRD §2.09 and BC file H1 | state-manager |
| F-09 | NFR-002 wrong risk source (R-004 = splitters, not crash recovery) | product-owner |

Minor findings F-10 through F-18 are recommended fixes but do not block the gate on their own.
Perimeter gaps PG-01 and PG-02 must be resolved before Phase-2 story decomposition begins.
PG-03 requires an explicit product-owner decision.

---

## Remediation Route Summary

**product-owner (F-01, F-03, F-04, F-09; PG-01):**
1. Update product-brief.md §Scope cross-cutting, §Success Criteria, §Overflow Competitive Differentiator Traceability — replace "delta round-trip checkpoint VP (CONFLICT-9)" with "workspace path confinement VP (DI-007)" and "session tenancy partition VP (NE-12)" → "session triple-address VP (DI-005)."
2. Update prd-supplements/module-criticality.md "Per-task checkpoint store" VP Count: 1 (delta-round-trip-VP) → remove the VP reference or correct to reflect no VP for this specific row.
3. Remove CONFLICT-9 reference from product-brief after VP names are corrected.
4. Correct NFR-002 Risk Source from R-004 to either N/A or the appropriate domain-spec risk entry.
5. Produce prd-supplements/test-vectors.md (PG-01) — consolidate test vectors from individual BC files.

**business-analyst (F-02, F-10):**
1. Update domain-spec/capabilities-p1-p2.md §CAP-019: replace delta round-trip VP (CONFLICT-9) with workspace path confinement VP (NE-02/DI-007); replace session tenancy partition VP (NE-12) with session triple-address VP (NE-12 ✓, name only needs updating to match VP-002 title).
2. Update domain-spec/differentiators.md D-03 Phase-1 BC Anchor: replace "delta round-trip VP" with "workspace path confinement VP." The DI column is already correct (DI-001/DI-005/DI-007).
3. Declare the canonical risk ID scheme: either align domain-spec/risks.md IDs to match STATE.md R-NNN or update PRD RTM Source column to use STATE.md IDs. Publish a cross-reference table if both schemes must coexist.

**state-manager (F-05, F-06, F-08, F-11, F-12, F-13, F-14, F-15, F-17, F-18):**
1. BC-INDEX VP Seed BCs table: change NE-05 → NE-12 for BC-2.04.006.
2. BC-2.09.005.md Verification Properties table: change VP-MCP-05 → VP-005.
3. PRD §2.09 BC-2.09.005 title: update to match BC file H1 "MultiServerMcpClient Holds No Live Connections (Red Gate — R11)."
4. bc-authoring-plan.md frontmatter: total_bcs 82→83, p1_count 26→27; Summary table 82→83.
5. BC-INDEX Carry-Forward Notes: "All 82 BCs" → "All 83 BCs."
6. PRD §2 intro: remove/update stale "SS-TBD" language.
7. PRD §2.04 table BC-2.04.007: add DI/NE annotation clarification or rename column.
8. BC-INDEX catalog BC-2.04.006 row: add DI-005 to DI Anchors column.
9. PRD §8 OQR-4: "82-BC plan" → "83-BC plan" (two instances).
10. PRD §9 NE Coverage Summary: correct the "2 → CI lint gate only" to accurately describe NE-04/NE-05 split.

**architect (F-07, F-16; PG-02):**
1. Fill PRD §7 RTM Module column for all 83 BCs using canonical module names from module-decomposition.md and ARCH-INDEX Subsystem Registry.
2. ADR-008 body text: update "**Status:** Proposed — GATED ON ADR-004" to "**Status:** Accepted" and remove stale "82-BC plan" reference.
3. Author NE-05 ADR (PG-02): one-paragraph ADR asserting that ferrochain cache keys use content hash of resolved instruction bytes + sorted tool declarations; wire as CI lint gate obligation.

**product-owner (decision required for PG-03):**
- Decision: author proc-macro BCs for #[tool], #[entrypoint], #[task] before Phase-2 begins, OR formally record as deferred with an explicit deferral rationale appended to OQR-4.

---

## Pass 2

**Auditor:** consistency-validator (fresh context, pass 2)
**Date:** 2026-07-13
**Scope:** (a) verify all 21 pass-1 findings resolved; (b) sweep for new inconsistencies introduced by remediation; (c) spot-check 5 ID chains pass-1 did not sample.
**Verdict:** PASS — 0 blocking findings. 6 new Minor/Observation items for state-manager.

---

### Pass-1 Resolution Table

| Finding | Severity | Status | Evidence |
|---------|----------|--------|---------|
| F-01 | Major | **RESOLVED** | product-brief.md §Scope cross-cutting now reads "BSP determinism VP (NE-17), session triple-address VP (DI-005/NE-12), workspace path confinement VP (DI-007/NE-02)". No "delta round-trip" or "CONFLICT-9" anywhere in .factory/specs/ (global grep returned zero matches). |
| F-02 | Major | **RESOLVED** | domain-spec/capabilities-p1-p2.md and differentiators.md: grep for "delta round-trip", "CONFLICT-9", "session tenancy partition" — zero matches. |
| F-03 | Major | **RESOLVED** | prd-supplements/module-criticality.md "Per-task checkpoint store" row now shows "VP Count: 0". The delta-round-trip-VP reference is gone. |
| F-04 | Major | **RESOLVED** | CONFLICT-9 reference removed from product-brief.md. Global grep across .factory/specs/ confirms zero occurrences. |
| F-05 | Major | **RESOLVED** | BC-INDEX VP Seed BCs table: BC-2.04.006 row now shows NE-12 (confirmed line 49 of BC-INDEX.md). |
| F-06 | Major | **RESOLVED** | BC-2.09.005 Verification Properties table now shows VP-005 (confirmed line 131 of BC-2.09.005.md). |
| F-07 | Major | **RESOLVED** | PRD §7 RTM Module column fully populated — grep for `[architect]` in prd.md returned zero matches. §7 RTM count = 86 rows matching 86-BC total. |
| F-08 | Major | **RESOLVED** | PRD §2.09 shows "MultiServerMcpClient Holds No Live Connections (Red Gate — R11)" (prd.md line 239), matching BC file H1 heading exactly. |
| F-09 | Major | **RESOLVED** | NFR-002 Risk Source now reads "N/A — DI-002 (per-task durability invariant) / CONFLICT-2" (nfr-catalog.md line 31). R-004 reference removed. |
| F-10 | Major | **RESOLVED** | domain-spec/risks.md §Dual Risk ID Reconciliation (lines 49-55) provides explicit cross-reference table: R-004↔R8, R-005↔R10, R-006↔R11. L2-INDEX.md carries a note (line 93) pointing to this table and declaring R-NNN as canonical for spec artifacts. |
| F-11 | Minor | **RESOLVED** | bc-authoring-plan.md: `total_bcs: 86`, `p1_count: 30`, body table "Total BCs | 86". |
| F-12 | Minor | **RESOLVED** | BC-INDEX header banner now reads "86 BCs total — 48 P0 / 30 P1 / 8 P2". The original "82→83" stale text is gone. Carry-Forward Note 1 says "All 83 BCs now have SS-NN" — this is a new count inconsistency created by the remediation (see NF-01). |
| F-13 | Minor | **RESOLVED** | Grep for "SS-TBD" in prd.md returned zero matches. Stale note removed. §2 intro now says "All BCs carry `subsystem: SS-NN` per ARCH-INDEX.md (backfilled Phase 1b)." |
| F-14 | Minor | **RESOLVED** | PRD §2.04 BC-2.04.007 DI column now shows "— (NE-11)" explicitly flagging NE as distinct from DI. BC file confirms "L2 Domain Invariants: (none — NE-11 is an operational safety requirement)." |
| F-15 | Minor | **RESOLVED** | BC-INDEX Full BC Catalog row for BC-2.04.006 now shows "DI-005" in the DI Anchors column (line 74). |
| F-16 | Minor | **RESOLVED** | ADR-008 body now reads "**Status:** Accepted — ADR-004 gate satisfied (D5 ✓); proc-macro BCs unblocked." (line 20). |
| F-17 | Minor | **RESOLVED** | PRD §8 OQR-4 updated: "the 83-BC base plan contained no proc-macro BCs; 3 were added as Phase-1b amendments … (total: 86 BCs)." No "82-BC plan" text remains. |
| F-18 | Minor | **RESOLVED** | PRD §9 NE Coverage Summary (line 597): "15 → BC; 1 → BC + CI lint gate (NE-04); 1 → CI lint gate only (NE-05)." Correct per-NE breakdown. |
| PG-01 | Major | **RESOLVED** | prd-supplements/test-vectors.md created (198 lines). Indexed as "live-index — aggregated from 86 BC files." All 86 BCs catalogued; 5 Red Gate BCs marked **RG**; GTVs for BC-2.07.002 reproduced inline. PRD frontmatter supplements list updated to include test-vectors.md. |
| PG-02 | Major | **RESOLVED** | ADR-011-cache-key-content-hash.md authored and accepted. Registered in ARCH-INDEX (line 92): "Cache-Key Content-Hash Contract (NE-05) — accepted." Contains full CI lint obligation (`cargo xtask deny-description-cache-key`). ARCH-INDEX ADR count updated to "11 files (ADR-001 to ADR-011)." |
| PG-03 | Observation | **RESOLVED** | BC-2.08.010/011/012 authored in ss-08/. OQR-4 updated: "3 were added as Phase-1b amendments … after ADR-004 and ADR-008 acceptance (total: 86 BCs)." |

**All 21 pass-1 findings RESOLVED.**

---

### New Findings (introduced by or discovered during remediation)

| # | Severity | Location | Finding |
|---|----------|----------|---------|
| NF-01 | Minor | BC-INDEX.md, Carry-Forward Note 1 (line 145) | Stale count: note says "All 83 BCs now have `subsystem: SS-NN`." The current total is 86 (3 proc-macro BCs added as Phase-1b per Note 5). Note 5 correctly records the addition, so no real gap exists, but Note 1's count contradicts the authoritative "86 BCs total" header. Remediation: update Note 1 text to "All 86 BCs" or add a postscript cross-referencing Note 5. |
| NF-02 | Minor | prd-supplements/test-vectors.md, lines 79–81, 125–126 | Stale TBD: TV Count shows "TBD" for BC-2.08.010/011/012 and line 126 reads "test vectors TBD when BCs are authored." BC-2.08.010/011/012 are now authored and each contains 5 canonical test vectors (TV-001..TV-005). The TBD note should be updated to reflect this. |
| NF-03 | Minor | BC-2.08.010.md line 113, BC-2.08.011.md line 100, BC-2.08.012.md line 106 | VP naming convention drift: the proc-macro BCs use VP-MACRO-010/011/012 as in-BC VP IDs. Every other non-VP-seed BC in the package uses the `VP-BC<SSNNNN>-NN` format (e.g., VP-BC208009-01 in the adjacent BC-2.08.009). VP-MACRO-NNN is a non-standard format for this project. Remediation: rename to VP-BC208010-01, VP-BC208011-01, VP-BC208012-01 (or the established SSNNNN pattern). |
| NF-04 | Minor | BC-2.08.010.md line 27, BC-2.08.011.md line 25, BC-2.08.012.md line 25 | Empty input-hash: all three proc-macro BCs carry `input-hash: ""`. All other BC files carry non-empty input-hash values. An empty hash makes spec-drift detection impossible for these three files. Remediation: compute and populate the input-hash before Phase-2 story decomposition begins. |
| NF-05 | Minor | prd.md §9 NE Disposition Table, line 583 | PRD §9 NE-05 row says "Architecture-phase ADR: cache keys must be content hash…" but does not name ADR-011 by number. ADR-011 back-references the PRD, but the forward link from PRD §9 to ADR-011 is implicit only. Story-writer reading PRD §9 cannot directly navigate to ADR-011 without loading ARCH-INDEX. Remediation: change the PRD §9 NE-05 cell to "ADR-011 (cache-key-content-hash); CI lint gate `cargo xtask deny-description-cache-key`." |
| NF-06 | Observation | prd-supplements/module-criticality.md, lines 50, 53, 55 | Informal VP names in VP Count column: "BSP-determinism-VP", "session-tenancy-VP", "workspace-confinement-VP." These are not registered VP IDs. Canonical IDs are VP-001, VP-002, VP-003. The original pass-1 F-03 finding corrected "delta-round-trip-VP" but did not standardize the remaining informal names. No traceability gap (the correct VP-NNN numbers appear in VP-INDEX and BC files); this is a readability/maintenance concern. |

---

### 86-BC Count Consistency Sweep

| Document | Count Stated | Actual | Status |
|----------|-------------|--------|--------|
| BC-INDEX.md header banner | 86 | 86 (verified row count) | PASS |
| prd.md §2 Totals | 86 BCs — 48 P0 / 30 P1 / 8 P2 | 86 (§7 RTM row count = 86) | PASS |
| prd.md §7 RTM rows | (no stated total; implicit) | 86 (awk count) | PASS |
| prd.md frontmatter supplements | test-vectors.md listed | present | PASS |
| bc-authoring-plan.md `total_bcs` | 86 | 86 | PASS |
| bc-authoring-plan.md `p1_count` | 30 | 30 | PASS |
| test-vectors.md input-hash annotation | "86 BC files" | 86 | PASS |
| test-vectors.md body total note | "83 authored BCs" + TBD for 3 | BCs are authored (stale note — NF-02) | MINOR |
| BC-INDEX Carry-Forward Note 1 | "83 BCs" | 86 | MINOR (NF-01) |

All authoritative count fields are consistent at 86. Two legacy notes retain stale counts — NF-01 and NF-02 above.

---

### VP-Substitution Consistency Sweep

Global grep for "delta round-trip", "delta-round-trip", "CONFLICT-9" across all files under .factory/specs/: **zero matches.** VP-substitution is clean.

---

### New BC-2.08.010/011/012 Format Integrity

| Check | Result |
|-------|--------|
| Frontmatter required fields (document_type, level, bc_id, version, status, lifecycle_status, subsystem, capability, priority, traces_to) | PASS — all present |
| subsystem: SS-08 | PASS |
| capability: CAP-002 (BC-2.08.010), CAP-003 (BC-2.08.011, BC-2.08.012) | PASS — matches BC-INDEX and PRD §7 |
| traces_to: domain-spec/capabilities-p0.md#CAP-NNN + ADR-004/ADR-008 | PASS |
| Preconditions, Postconditions, Invariants, Edge Cases, Canonical Test Vectors present | PASS — all sections present, 4+ ECs and 5 TVs each |
| input-hash | FAIL — empty string in all three (NF-04) |
| In-BC VP naming convention | FAIL — VP-MACRO-NNN instead of VP-BC<SSNNNN>-NN (NF-03) |
| Registered in prd.md §2.08 and §7 RTM | PASS — lines 227–229 (§2) and lines 549–551 (§7) |
| Registered in bc-authoring-plan.md Batch 13 | PASS |

---

### ADR-011 Registration and NE-05 Anchor Chain

| Link | Status |
|------|--------|
| ADR-011 file exists and has correct frontmatter | PASS — status: accepted, ne_anchors: [NE-05], traces_to: ARCH-INDEX.md |
| ARCH-INDEX entry for ADR-011 | PASS — line 92: "Cache-Key Content-Hash Contract (NE-05) — accepted — —" |
| ARCH-INDEX ADR count updated to 11 | PASS — "11 files (ADR-001 to ADR-011)" |
| ADR-011 CI lint obligation documented | PASS — `cargo xtask deny-description-cache-key` with scope, failure condition, phase |
| PRD §9 NE-05 → ADR-011 (forward link) | MINOR — PRD §9 says "Architecture-phase ADR" without naming ADR-011 (NF-05) |
| ADR-011 → PRD §9 (back link) | PASS — ADR-011 line 104: "PRD §9 NE Disposition Table anchors NE-05 to this ADR" |

---

### Risk Cross-Walk Coherence

| Check | Status |
|-------|--------|
| risks.md §Dual Risk ID Reconciliation table present (R-004↔R8, R-005↔R10, R-006↔R11) | PASS |
| L2-INDEX.md note citing the cross-reference | PASS — line 93 |
| BC-INDEX Red Gate table uses R8/R10/R11 consistently | PASS |
| PRD §7 RTM Source column uses R-004/R-005/R-006 consistently | PASS |
| BC frontmatter `red_gate_source` fields use R8/R10/R11 | PASS (BC-2.07.002 carries `red_gate_source: R8` per carry-forward note resolution) |
| Dual-scheme coexistence documented | PASS — risks.md explicitly states R-NNN is canonical for spec artifacts; R-N aliases retained for decision-log only |

---

### 5 Spot-Check ID Chains (pass-1 did not sample these)

| Chain | Verified |
|-------|---------|
| CAP-015 → BC-2.13.004 (subsystem SS-13, capability CAP-015) → VP-003 (Workspace Path Confinement, path-guard module, Kani P0) | PASS — BC frontmatter confirms, VP-INDEX line 42 confirms |
| CAP-002 → BC-2.08.010 (subsystem SS-08, capability CAP-002) → ADR-004 (accepted) + ADR-008 (accepted) | PASS — BC traces_to includes both ADRs; both ADRs have status: accepted |
| CAP-010 → BC-2.09.004 (subsystem SS-09, capability CAP-010) → VP-004 (MCP ToolException Type-Identity Preservation, mcp-adapter, integration P1) | PASS — VP-INDEX line 43 confirms |
| CAP-006 → BC-2.05.001..005 (subsystem SS-05, D17-Q2 HITL) — no VP (correct: no Kani target for HITL) | PASS — 5 BCs all carry capability: CAP-006; BC-INDEX confirms 5 rows |
| CAP-014 → BC-2.12.001..005 (subsystem SS-12, ferrochain-server resources) — no VP | PASS — 5 BCs all carry capability: CAP-014; all in ss-12/ directory |

---

### Consistency Score

Pass-2 scope: 21 pass-1 findings verified + 6 new findings swept.

| Category | Pass-1 Count | Resolved | New findings | Net |
|----------|-------------|---------|-------------|-----|
| Blocking (Major/Critical) | 9 | 9 | 0 | 0 blocking |
| Minor | 9 | 9 | 5 Minor | 5 minor open |
| Perimeter gaps | 3 | 3 | 0 | 0 open |
| Observations | 1 (PG-03) | 1 | 1 Observation | 1 observation open |

**Gate verdict: PASS.** Zero blocking findings. 5 minor items (NF-01..NF-05) and 1 observation (NF-06) should be resolved by state-manager before Phase-2 story decomposition to maintain spec hygiene, but none prevents Phase-2 from beginning.

Consistency score (post-remediation): **97%** (6 minor/observation findings against ~200 cross-checked artifact relationships; none blocking).
