---
document_type: adversarial-review
pass: 82
phase: 1d
verdict: NOT_CLEAN
finding_count: 2
finding_severity: [MED, MED]
novelty: MEDIUM
novelty_class: fts-seam-signature-and-raise-timing
sibling_checks: "1/1 PASS"
timestamp: 2026-07-15T00:00:00Z
---

# Adversarial Review Pass 82

**Verdict:** NOT CLEAN — 2 findings, both MED, both FIXED same burst.

**F-P82-01 (MED, FIXED)** — BC-2.04.008 PC3 listed `query: &str` as a FIELD of FtsSearchConfig, contradicting the authoritative signature (`fts_search(query: &str, config: FtsSearchConfig)`) and PC1/EC-001/EC-002/TV-001. FIXED: PC3 rewritten — query = standalone first parameter; FtsSearchConfig = exactly {thread_id: Option<&str>, limit: usize}. BC-2.04.008 → v1.4.

**F-P82-02 (MED, FIXED)** — interface-definitions E-CHKPT-008 note blanket-claimed "raised at construction time" for BOTH limit=0 AND malformed-FTS5-query; per BC, EC-002 (malformed query) is SEARCH-TIME (SQLite parse-error propagation at fts_search call). FIXED: note split into sub-case (1) construction-time PC6/EC-004 and sub-case (2) call-time EC-002, with explicit "query is not a config field". interface-definitions → v2.26.

**Post-fix seam audit (PO):** full BC-2.04.008 + E-CHKPT-008/009 notes + CheckpointSaver trait block cross-read — 10/10 seam checks PASS, AIRTIGHT.

**Clean verifications (adversary):** mandatory coverage-debt rotation ALL CLEAN — gate #21 (422→500 routing enumeration exact), #23 (11 StreamEvent variants coherent across BC-2.06.001/ADR-006/interface), #24 (pagination convention + versions ASC exemption), #29 (→F-P82-02), #30 (no codeless mints; category-only mentions are references not mints); census 85 = 43+16+26 recounted; 6 RetryHint divergences; sibling-check BC-2.08.014 v1.1 held; free probes: domain-spec shards (invariants, capabilities-p1-p2) no stale prose vs D20 baseline; domain-b brief = intended pre-design gap framing, no defect.

**Novelty:** MEDIUM — FTS seam never fully cross-read before. **Trajectory:** →2 (P1D-82). Counter 0/3.
