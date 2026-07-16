---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-15T00:00:00Z
phase: 1d
pass: 83
verdict: NOT_CLEAN
finding_count: 3
finding_severity: [HIGH, MED, MED]
novelty: MEDIUM
novelty_class: semantic-mis-anchor-and-partial-fix-residue
sibling_checks: "2/2 PASS"
cycle: v1.0.0-greenfield
traces_to: STATE.md
---

# Adversarial Review — Pass 83 (Phase 1d)

**Verdict:** NOT CLEAN — 3 findings (1 HIGH, 2 MED). All FIXED this burst.

---

## F-P83-03 (HIGH — FIXED)

**Target:** ADR-013 — MCP server module placement

**Finding:** ADR-013 misassigned tools/list vs tools/call responsibilities between its two BCs in both the Context section and the BC Anchors table. Specifically: BC-2.09.006 (which governs tools/list ADVERTISEMENT, discovery-only) was given the description "accept and dispatch inbound tool-call requests" — the responsibility that belongs to BC-2.09.007 (tools/call INVOCATION). Conversely, BC-2.09.007 was under-described as mere "response serialization", obscuring its dispatch role. The swap propagated through both the narrative Context paragraph and the BC Anchors table rows.

**Fix (architect — same burst):** ADR-013 advanced to v1.2. Context paragraph and BC Anchors table rows corrected with explicit MCP method-name discriminators (tools/list for BC-2.09.006; tools/call for BC-2.09.007). Full 14-section cross-read performed; 2 LOW residuals also fixed in the same burst: (1) behavioral-authority note widened to reference BC-2.09.006/007 jointly, (2) inline comment broadened to reflect both BCs. Attribution Note annotated "[completed — BC-2.09.006 v1.1]".

---

## F-P83-01 (MED — FIXED)

**Target:** interface-definitions — ToolCallDialect trait-block anchor (~line 314)

**Finding:** The ToolCallDialect trait-block anchor cited "BC-2.08.013 PC1–PC4" for object-safety, but the object-safe trait contract is actually PC10. Additionally the citation referenced "E-PROV-009" for parse failure, but the correct PCs are PC8/PC9. This was an un-propagated sibling of the pass-78 F-P78-03 omission-note fix — that fix corrected the omission note but did not update the trait-block anchor itself.

**Fix (PO — same burst):** Anchor corrected to: "PC1–PC9 (built-in dialect round-trips; PC8/PC9 = E-PROV-009 on parse failure) + PC10 (object-safe trait contract)".

---

## F-P83-02 (MED — FIXED)

**Target:** interface-definitions — ProviderFallbackPolicy trait-block anchor (~line 336)

**Finding:** The ProviderFallbackPolicy trait-block anchor cited "PC1–PC4" for E-PROV-010 (chain exhaustion), but E-PROV-010 is actually raised at PC5. This was an un-propagated sibling of pass-78 F-P78-02 — that fix corrected the omission note but did not update the trait-block anchor.

**Fix (PO — same burst):** Anchor corrected to: "PC1–PC4 (ordered fallback semantics) + PC5 (E-PROV-010 on chain exhaustion)". interface-definitions advanced to v2.27.

---

## Full Anchor Audit (PO — same burst)

All 16 BC-anchor locations in interface-definitions audited against their cited BCs:
- 2 FAIL → FIXED (F-P83-01 and F-P83-02 above)
- 14 PASS: including SkillStore PC1–PC4, MemoryWriteGuard PC1–PC5, all pagination anchors, RunContext/BudgetInfo block, CheckpointSaver block, and remaining MCP trait anchors.

---

## Clean Verifications (adversary — this pass)

**Sibling-checks 2/2 PASS:**
- BC-2.04.008 v1.4: FTS seam — PC3 correctly specifies query as standalone first parameter; FtsSearchConfig = {thread_id: Option<&str>, limit: usize}. GREEN.
- interface-definitions v2.26 → v2.27: E-CHKPT-008 two-sub-case note confirmed (construction-time PC6/EC-004 vs call-time EC-002). GREEN.

**D20 trait-seam cross-reads — fully clean this pass:**
- SkillStore, MemoryWriteGuard, ADR-012 type sketches match interface-definitions exactly.
- BC-2.15.004/005/006, BC-2.08.013/014: H1 title ↔ BC-INDEX title sync verified 8/8 D20 BCs.

**OBS-P83-A (non-defect observation):** CheckpointSaver trait block omits fts_search method by scoping choice — anchor is scoped to BC-2.04.001–006, and the block is explicitly a representative listing. This is not a defect.

---

## Novelty Assessment

**MEDIUM.** The ADR-013 tools/list vs tools/call swap (F-P83-03) is a new finding class — semantic method-name discriminator misassignment between sibling BCs in an ADR context section. The two anchor PC-citation errors (F-P83-01/02) are residue-class findings (un-propagated siblings of prior fixes), consistent with the novelty class `semantic-mis-anchor-and-partial-fix-residue`.

---

## Trajectory

→3 (P1D-83). Convergence counter: 0/3 (reset by this pass).
