---
document_type: adversarial-review-pass
phase: 1d
pass: 21
verdict: NOT CLEAN
findings_count: 1
high_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "...→2→3→3→1"
timestamp: 2026-07-14T00:00:00Z
---

# Adversarial Review Pass 21 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (1 HIGH). Counter reset: 0/3 consecutive clean.

---

## F-P21-01 [HIGH] — Capability-Tier ↔ BC-Priority Cross-Doc Mismatch (CAP-012, CAP-013, CAP-016)

**Finding class (NEW):** capability-tier ↔ BC-priority cross-doc misalignment.

**Scope:** L2-INDEX.md §Priority Distribution (lines 99-101) and capabilities-p1-p2.md §P1 section header and CAP-012:68, CAP-013:81, CAP-016:121.

**Finding:** Three capabilities are listed as P1 (should-have, Wave 2) in the domain-spec (L2-INDEX Priority Distribution and the P1 section grouping in capabilities-p1-p2.md) but their PRD section headers and all constituent BC frontmatter priorities are P0:

| CAP | L2-INDEX tier | PRD §2 section header | BC priorities (RTM) | Elevation mandate |
|-----|--------------|----------------------|---------------------|-------------------|
| CAP-012 | P1 | §2.10 — **P0** | all 4 BCs P0 (BC-2.10.001–004) | D17-Q4 — Domain B dark-factory holdout requires |
| CAP-013 | P1 | §2.11 — **P0** | all 6 BCs P0 (BC-2.11.001–006) | D17-Q8 — Domain A SOC analyst holdout requires |
| CAP-016 | P1 | §2.14 — **P0** | all 6 BCs P0 (BC-2.14.001–006) | D17 CONFLICT-6/NE-07 — Phase-1 BC; all security BCs depend on this error model |

The D17-Q4 and D17-Q8 elevation decisions explicitly mandate these as Phase-1 BCs (PRD §2.10 note: "D17-Q4 mandates these as Phase-1 BCs"; §2.11 note: "D17-Q8 mandates these as Phase-1 BCs"). CAP-016's constituent BCs in SS-14 are all P0 per the RTM. The L2-INDEX and capabilities-p1-p2.md grouping under "P1 — Partners, Conformance, MCP, and Governance (Wave 2)" has not been updated to reflect the D17 elevation.

**Impact:** Any agent consuming the L2-INDEX Priority Distribution or capabilities-p1-p2.md to prioritize story decomposition would under-weight three capabilities whose Phase-1 BC obligations are blocking for holdout evaluation.

**Fix plan:**
1. L2-INDEX.md §Priority Distribution: move CAP-012, CAP-013, CAP-016 to P0 row (P0 count 8→11; P1 count 8→5); update Document Map description for both shard rows.
2. capabilities-p1-p2.md: remove CAP-012, CAP-013, CAP-016 sections from the P1 grouping; update section header (remove "Governance" reference; file now holds 5 P1 + 3 P2).
3. capabilities-p0.md: add new section "P0 — Cross-Cutting: Budget, Security, and Error Taxonomy (D17-Elevated; Wave 0/1)" containing CAP-012, CAP-013, CAP-016 with D17-elevation notes per section.
4. L2-INDEX ID Registry row for CAP-NNN: update shard attribution.

---

## Sibling Width Census — PASS

All 86 BCs reviewed. No new findings in BC bodies.

| Subsystem | BCs | Findings |
|-----------|-----|----------|
| SS-01 through SS-17 | 86 | 0 |

---

## Census Results (4 standing gates) — ALL PASS

| Census | Gate | Result |
|--------|------|--------|
| E-code × variant-name census (§16) | grep E-[A-Z]+-NNN VariantName in BCs vs error-taxonomy.md | PASS — 40 distinct pairings, 0 mismatches |
| Shared-type identifier census (§15) | grep retired spellings (Checkpointer, CheckpointManager, etc.) in BCs | PASS — 0 occurrences |
| Title ↔ CAP-identity census | CAP-NNN in BC traces_to vs §2 section title mapping | PASS — all 86 BCs trace to correct CAP |
| Inputs-arrays frontmatter census | all BC files have inputs: field as YAML array | PASS — all present |

---

## Novel Probes (3) — ALL PASS

| Probe | Target | Result |
|-------|--------|--------|
| Holdout-vs-CAP coverage | holdout-domains/domain-a/b/c.md requirements vs domain-spec CAP coverage | PASS — all holdout forcing functions map to at least one CAP |
| CAP-014 P1 tier consistency | L2 P1 vs PRD §2.12 P1 vs BC-2.12.001–007 P1 | PASS — consistently P1 (bounds blast radius: server is Wave-1 crate but does not carry D17-Q4/Q8 mandate) |
| capability-tier ↔ BC-priority census (NEW axis — see §Future Census) | L2 tier vs PRD §2 section-header priority vs BC RTM priorities for all 19 CAPs | F-P21-01 (see above); 16/19 PASS, 3 MISMATCH |

---

## Observation: CAP-014 P1 — Verified Consistent (Bounds Blast Radius)

CAP-014 (Durable-Run HTTP Server, ferrochain-server) is P1 in both L2-INDEX and PRD §2.12, with all 7 constituent BCs at P1. This is correct: ferrochain-server is a Wave-1 crate that was not covered by any D17-Qx elevation mandate. It is a should-have server layer, not a Phase-1-BC-forced cross-cutting primitive. No fix needed for CAP-014.

---

## Future Census Axis (registered)

**Capability-tier ↔ BC-priority cross-doc census** added as a standing gate. After each BC authoring burst, verify that the L2-INDEX Priority Distribution tier for each CAP matches the majority/max priority of its constituent BCs in the PRD RTM and the PRD §2 section header. Any CAP where all BCs are P0 but the L2 tier is P1 (or vice versa) is a finding.

---

## Trajectory

| Pass | Verdict | Findings |
|------|---------|----------|
| P18 | NOT CLEAN | 2 |
| P19 | NOT CLEAN | 3 |
| P20 | NOT CLEAN | 3 |
| P21 | NOT CLEAN | 1 |

Consecutive clean: **0/3**. Next pass starts fresh.
