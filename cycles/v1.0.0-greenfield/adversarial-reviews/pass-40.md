---
document_type: adversarial-review
pass: 40
verdict: NOT_CLEAN
severity: MED
novelty: MEDIUM
phase: 1d
timestamp: 2026-07-14T00:00:00Z
findings_count: 1
observations_count: 1
---

# Adversarial Review — Pass 40

## Verdict: NOT CLEAN — 1 finding (MED). Novelty MEDIUM.

---

## Findings

### F-P40-01 (MED): BC-2.08.007 Batch-Table DI Cell Missing DI-009

**Location:** `prd-supplements/bc-authoring-plan.md` Batch 9 table row for BC-2.08.007 (line ~244)

**Defect:** The batch-table DI cell for BC-2.08.007 shows only `DI-014`, contradicting FIVE authoritative carriers that include DI-009:

| Carrier | Value |
|---------|-------|
| bc-authoring-plan.md DI coverage table (line ~118) | `DI-009 \| BC-2.08.007, BC-2.14.004` |
| BC-2.08.007 body frontmatter (traces_to) | `domain-spec/invariants.md#DI-014`, `domain-spec/invariants.md#DI-009` |
| BC-2.08.007 body PC5 + Invariants section | "DI-009 (Outbound Connection Timeout (Mandatory))"; "DI-014 (Error Propagation (No Silent Swallowing))" |
| BC-INDEX line 94 | `DI-009,DI-014` |
| PRD §2 table (line ~224) | DI-009 + DI-014 listed for BC-2.08.007 |
| PRD §7 RTM (line ~513) | DI-009 present |

DI-009 = mandatory outbound-timeout invariant, exercised by BC-2.08.007 PC5 ("Zero client timeouts are disallowed (DI-009 / NE-04)"), EC-005 (Client constructed without timeout), and TV-004 (reqwest::Client::new() CI lint).

**Body wins per gate #13.** The batch-table DI cell drops DI-009 — a spurious omission introduced when the batch table was authored.

**Fix:** Batch-table DI cell for BC-2.08.007: `DI-014` → `DI-009, DI-014`.

---

## Observations

### OBS-P40-1 [process-gap]: Gate #13 Carrier Set Does Not Include Batch-Table Anchor Columns

**Location:** `prd-supplements/bc-authoring-plan.md` gate #13 (Anchor-Matrix Census Gate)

**Issue:** Gate #13 defines a four-way consistency check across {BC body ↔ BC-INDEX ↔ PRD §2/§7/§9 ↔ authoritative registry}. The batch-table CAP/DI/NE columns in bc-authoring-plan.md are NOT included as a verified carrier. This is precisely the omission that allowed F-P40-01 to survive 39 adversarial passes — the batch-table DI cell for BC-2.08.007 showed `DI-014` while every other carrier showed `DI-009, DI-014`, but gate #13 never checked the batch-table columns.

**Broader risk:** The batch-table is a planning artifact consumed by sub-burst agents. A drifted DI cell in the batch table could cause sub-burst agents to omit DI citations from newly authored BCs, propagating the drift forward into BC bodies.

**Fix:** Add the bc-authoring-plan batch-table CAP/DI columns as a **fifth verified carrier** in gate #13. The census must diff batch-table anchor cells against BC-INDEX on every anchor-affecting burst.

---

## Sibling Checks

1. **ubiquitous-language-server v1.1 MemoryStore cell** — PASS. MemoryStore canonical spelling confirmed in all checked BCs and prd-supplements.
2. **bc-authoring-plan v1.3 three batch-size statements coherence** — PASS. Sum = 86 BCs, 13 batches; prose, Summary metric, and Batch 9 header are mutually coherent (F-P39-02 fix holds).

---

## Novel Probe Censuses

### Census #22 — RetryHint (PASS)
Registry contains exactly 5 codes with intentional RetryHint divergences. E-RETRY-004 correctly excluded (no divergence). All 5 known-intentional-divergences listed in gate #22 match error-taxonomy.md. No orphan divergences found.

### Census #23 — Streaming event names (PASS)
11 streaming event variants confirmed: RunStart, NodeStart, ToolStart, StepStart, RunEnd, NodeEnd, ToolEnd, StepEnd, RunStream, NodeStream, ToolStream. Wire token `node_stream` confirmed. BC-2.12.007 EC-003/TV-005 use `node_stream` (not retired `node_delta`). No live retired names found.

### Census #26 — Structurally-privileged-line residue (PASS)
Zero live retired canon claims in H1/H2/H3 headings across all checked artifacts.

### Census #25 — 4-doc criticality (PASS)
33 modules = 9 CRITICAL / 12 HIGH / 10 MEDIUM / 2 LOW across all four sibling documents. macro criticality HIGH confirmed in both registry docs.

---

## Novel Probes (New in Pass 40)

### Probe A — Non-list endpoints vs governing PCs (CLEAN)
Checked `state`, `set_latest`, `delete-cascade` endpoint shapes against BC-2.12.003 PC15/PC16/PC18/PC19/PC11. All shapes match. No path drift.

### Probe B — Entity fields vs BC PCs/interface shapes (CLEAN)
Reconciliation: Run / Assistant / Thread / Interrupt entity field sets match BC postconditions and interface-definitions.md JSON schema. FerrochainError.code confirmed String type across BC bodies and entities-server.md.

### Probe C — prd.md vs BC-INDEX counts (DRIFT — batch-table only)
BC-INDEX summary: 86 total = 48 P0 / 30 P1 / 8 P2. Red Gate 5 + VP-seed 3 consistent. Drift found only in bc-authoring-plan.md batch-table DI column (F-P40-01). PRD §2 and BC-INDEX are mutually consistent.

---

## Novelty Assessment: MEDIUM

New drift class discovered: **batch-table anchor cells** can diverge from BC-INDEX and BC body without detection, because gate #13's carrier set historically omitted bc-authoring-plan batch-table columns. F-P40-01 (DI-009 missing from batch-table DI cell for BC-2.08.007) survived 39 passes under this blind spot. The fix (gate #13 widened to 5-way, batch-table added as fifth carrier) closes the class for future bursts.

---

## Fix Burst Summary (Phase 1d)

Applied in this burst:
- **F-P40-01 fix:** bc-authoring-plan.md Batch 9 BC-2.08.007 DI cell corrected: `DI-014` → `DI-009, DI-014`.
- **Batch-table sweep (Task 3):** All 86 batch-table rows audited against BC-INDEX. 8 corrections made (see fix-burst output).
- **Gate #13 widening (OBS-P40-1):** bc-authoring-plan.md gate #13 updated to five-way consistency check; batch-table CAP/DI columns added as fifth verified carrier; motivating instance F-P40-01 cited.
- **Version bump:** bc-authoring-plan.md v1.3 → v1.4; changelog entry added.
