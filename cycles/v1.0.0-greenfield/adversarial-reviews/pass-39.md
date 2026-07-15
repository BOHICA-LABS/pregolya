---
document_type: adversarial-review-pass
phase: 1d
pass: 39
verdict: NOT CLEAN
findings_count: 2
high_count: 0
med_count: 1
low_count: 1
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→0→0→0"
timestamp: 2026-07-14T00:00:00Z
new_class: "reconciliation-table ferrochain-identifier drift; batch-size constraint vs actuals mismatch"
novelty: MEDIUM
routed_to_po: 2
routed_to_architect: 0
---

# Adversarial Review Pass 39 — Phase 1d

**Verdict: NOT CLEAN** — 2 findings (1 MED, 1 LOW). 2 non-blocking observations. Novelty: MEDIUM — genuinely new axes (ubiquitous-language reconciliation table and batch-size constraint consistency), localized bookkeeping/naming findings; core (86-BC/5-VP/26-endpoint/19-CAP) coherent. Convergence counter **reset to 0/3**.

---

## Findings

### F-P39-01 (MED) — ubiquitous-language-server.md Reconciliation Row Uses "Store" Instead of Canonical "MemoryStore"

**Location:** `.factory/specs/domain-spec/ubiquitous-language-server.md:132` — Term Reconciliation Table (LangChain Python → ferrochain), memory store row.

**Claim in table:** ferrochain term column reads `Store (long-horizon KV+vector)`.

**Authoritative canonical name:** `MemoryStore` — established by:
- `BC-2.15.001:151` Architecture Anchors (canonical trait name)
- `module-decomposition.md:149` — "Canonical trait name: MemoryStore per BC-2.15.001 Architecture Anchors"
- Used consistently throughout BC-2.15.001, BC-2.15.002, BC-2.15.003
- Consistent in verification-coverage-matrix and pass-18 census

**Discrepancy:** Every sibling row in the reconciliation table names the exact ferrochain identifier (e.g., `CheckpointSaver`, `RunnableConfig`, `Message`, `FerrochainError 2D struct`, `SendEdge`). The memory store row breaks the pattern by using the generic concept label "Store" rather than the canonical Rust trait name `MemoryStore`. This creates an inconsistency between the reconciliation table (the named cross-reference surface) and the authoritative canonical name documented in BCs and module decomposition.

**Cross-check:** OBS-P39-1 confirms `capabilities-p1-p2.md:132` "LangGraph Store analog" + CAP-017 title "Memory Store" are concept-level references, not canonical identifier references — those are CLEAN. The drift is localized to the reconciliation-table ferrochain-term cell.

**Fix:** Change the ferrochain term cell at line 132 from `Store (long-horizon KV+vector)` to `MemoryStore (long-horizon KV+vector)`.

**Routing:** Product-Owner (domain-spec shard owner).

---

### F-P39-02 (LOW) — bc-authoring-plan.md Batch-Size Constraint Prose and Summary Metric Contradict Documented Batch 9 Exception

**Location:** `.factory/specs/prd-supplements/bc-authoring-plan.md` — line 27 (body prose) and line 40 (Summary table metric).

**Claim in prose (line 27):** "batches of ≤8 BCs each for sequential sub-bursts."

**Claim in Summary metric (line 40):** `BCs per batch (max) | 8`

**Authoritative batch actuals:** Batch 9 header (line 234) reads: `*9 BCs — SS.08 complete (Step-E addition: BC-2.08.009 authored from ADR-004 acceptance, architect feedback)*` — enumerating 9 BCs in the table (BC-2.08.001 through BC-2.08.009).

**Full batch count audit — all correct, no re-batching needed:**
Batches 1..13: 8+8+7+6+6+7+6+6+9+8+7+5+3 = 86 (matches total_bcs frontmatter). Every BC appears in exactly one batch. D17/NE/DI tables consistent — 14/14 DIs covered, 17 NEs anchored.

**Discrepancy:** The constraint statements declare ≤8 as invariant but Batch 9 legitimately carries 9 BCs due to the Step-E ADR-004 acceptance addition. The batch counts are correct; only the constraint prose and summary metric are stale. Intent verification: the 9th BC (BC-2.08.009) is a legitimate documented exception; re-batching would be pure churn.

**Fix:** Document the exception rather than re-batch. (1) Line 27 prose: amend "batches of ≤8 BCs each" to "batches of ≤8 BCs each at initial planning (Batch 9 carries a documented 9th BC — BC-2.08.009, Step-E addition per ADR-004 acceptance)." (2) Summary metric row: change `8` to `9 (Batch 9 only — Step-E exception; planning cap remains 8)`. The three statements — prose constraint, summary metric, and Batch 9 header — must be mutually coherent after the fix.

**Routing:** Product-Owner (bc-authoring-plan shard owner).

---

## Observations (non-blocking)

### OBS-P39-1 [intentional-design] — "LangGraph Store analog" and CAP-017 "Memory Store" Are Concept References, Not Canonical Identifier Drift

`capabilities-p1-p2.md:132` "LangGraph Store analog" and the CAP-017 title "Memory Store" are descriptive concept-level references used in discovery context. They are internally consistent and not naming the Rust trait. The reconciliation table is the only surface that names canonical ferrochain identifiers and is therefore the only drift location (F-P39-01). All other "Store" / "Memory Store" occurrences in domain-spec are CLEAN.

### OBS-P39-2 [census-pass] — FM Coverage: All 14 FMs Trace to At Least One Enforcing BC; Zero Orphans

Full FM-001..FM-014 trace audit: every failure mode has at least one BC in its Scope column and those BCs cite the FM back (DI cross-reference or EC anchor). Count matches STATE claim. No orphan failure modes. FM coverage is CLEAN.

---

## Sibling-Checks Performed (All PASS)

1. **verification-architecture.md v1.1 §Committed VP Obligations:** PASS — heading/intro/table/total coherent after P38 fix; NFR-003 3-Kani scope unchanged in prd.md:365, nfr-catalog.md:32, system-overview.md:93, and VP-INDEX.
2. **Gate #16 two-form census:** PASS — zero collisions; E-RETRY-004 fix holds; E-GRAPH-007 reuse in BC-2.04.004 EC-003 consistent.
3. **Gate #24:** PASS 6/6.
4. **Gate #25 4-doc sibling set:** PASS — 33=9/12/10/2; 20=6/8/4/2; macros HIGH all four; arithmetic consistent.

---

## Census Results

- **Arithmetic:** PASS — 86 BCs per-subsystem (4+6+3+7+6+3+3+12+5+4+6+7+6+6+3+3+2 = 86); 5 VPs; 18 crates; 26 endpoints; CAPs 11/5/3=19; priorities 48/30/8.
- **Batch totals:** PASS — 13 batches (8+8+7+6+6+7+6+6+9+8+7+5+3=86); every BC in exactly one batch.
- **D17/NE/DI tables:** PASS — 14/14 DIs anchored; 17 NEs anchored; DI table counts consistent.

---

## Novel Probes

**(a) FM→BC coverage audit:** CLEAN — 14/14 FMs (FM-001..FM-014) trace to ≥1 enforcing BC; zero orphans; count matches STATE claim.

**(b) Ubiquitous-language reconciliation table identifier consistency:** NOT CLEAN — F-P39-01. Memory store row uses concept label "Store" instead of canonical Rust trait name "MemoryStore" per BC-2.15.001 and module-decomposition.md. All other 12 rows name exact ferrochain identifiers correctly.

**(c) Batch-size constraint vs batch actuals:** NOT CLEAN — F-P39-02. Constraint prose and summary metric say ≤8; Batch 9 legitimately carries 9 BCs due to Step-E ADR-004 exception. Batch counts are correct; constraint statements are stale.

---

## Novelty Assessment

**MEDIUM** — both probes were never previously run: (b) ubiquitous-language reconciliation table identifier fidelity and (c) batch-size constraint vs actuals cross-check. The findings are localized bookkeeping/naming issues; the core spec artifacts (86 BCs, 5 VPs, 26 endpoints, 19 CAPs) are coherent. Neither finding affects implementability. Recommend targeted fixes and re-run.
