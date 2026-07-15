---
document_type: adversarial-review
pass: 41
verdict: CLEAN
severity: null
novelty: LOW
phase: 1d
timestamp: 2026-07-16T03:00:00Z
findings_count: 0
observations_count: 3
---

# Adversarial Review — Pass 41

## Verdict: CLEAN — Zero findings. Novelty LOW.

---

## Findings

None.

---

## Observations

### OBS-P41-1: BC Body Secondary-Capability Representation Style Non-Uniform

**Location:** `specs/behavioral-contracts/` — various BCs

**Observation:** Secondary-capability representation is stylistically non-uniform across BCs: BC-2.10.004 carries a dedicated Secondary row while BC-2.08.001 lumps the secondary capability in the same cell. However, every carrier is correct — primary-capability frontmatter is correct, secondary traces_to fields are correct, BC-INDEX Cap column carries only primary per D18-P40-B convention. This is a stylistic inconsistency, not a defect. No fix required.

### OBS-P41-2: BC-INDEX/Module-Criticality VP Columns Flag Only the 3 Kani Seeds

**Location:** `specs/behavioral-contracts/BC-INDEX.md`, `specs/module-criticality.md`

**Observation:** The VP-seed columns in BC-INDEX and module-criticality highlight only the 3 Kani seeds (vp_seed: true convention). The full 5-VP registry is authoritative in VP-INDEX, ARCH-INDEX, verification-coverage-matrix, and verification-architecture. This is a coherent design: the vp_seed flag marks Kani-committed proofs only; integration VPs (VP-004/005) are tracked in verification-architecture §Committed VP Obligations. No contradiction — the system is coherent. No fix required.

### OBS-P41-3: Pre-Implementation Architecture-Anchor File Paths Diverge Harmlessly

**Location:** `specs/architecture/` — section files, ADR references

**Observation:** Pre-implementation architecture-anchor file paths diverge harmlessly across docs — some are marked "to be created" and others "[architect to assign]". Module names are consistent across all carriers. This is expected pre-implementation state. No fix required.

---

## Sibling Checks

1. **Batch-table five-way census (25+ rows)** — PASS. All 8 pass-40 corrections hold; zero drift found across all 25+ checked rows. Fifth carrier (batch-table CAP/DI columns) compliant with gate #13 five-way definition.
2. **Gate #13 five-way text** — PASS. Fifth carrier (bc-authoring-plan batch-table) present in gate definition; F-P40-01 motivating instance cited in gate prose; all five carrier names in gate description.
3. **Cap-column-primary convention** — PASS. Cap column = primary capability (frontmatter only) convention documented in gate #13 and compliant across checked BCs (BC-2.10.004 CAP-012, BC-2.08.001..005 CAP-009, BC-2.08.007 DI-009+DI-014).

---

## Novel Probe Censuses

### Census #16 — Two-Form E-code/Variant Pairings (PASS)

Zero collisions. Both grep forms checked (space-delimited and colon-delimited E-code↔variant pairings). All pairings cross-checked against error-taxonomy.md authoritative binding. No new collisions beyond the 5 known intentional RetryHint divergences.

### Census #24 — Six-Surface Pagination (PASS)

All six list endpoints confirmed paginated per D18-P31-A canon (limit default 10 / max 100 / silent CLAMP / offset default 0 / created_at DESC or exemption documented). /versions version ASC exemption intact.

### Census #25 — 4-Doc Criticality (PASS)

33 = 9 CRITICAL / 12 HIGH / 10 MEDIUM / 2 LOW across all four sibling documents (arch registry, PO registry, module-decomposition.md, verification-coverage-matrix.md). 20 = 6/8/4/2 in PO-draft registry. ferrochain-macros HIGH confirmed in all four docs. Arch-view and PO-draft self-consistent.

### Arithmetic Census (PASS)

86 BCs = 48 P0 / 30 P1 / 8 P2; 5 VPs = 3 Kani (VP-001/002/003) + 2 integration (VP-004/005); 18 crates; CAPs 11/5/3=19; batch sum 86 across 13 batches (Batch-9 = 9 BCs Step-E exception per D18-P39-B); 14 FMs / 14 DI / 13 DEC / 9 ASM / 8 R per L2-INDEX ID Registry. All arithmetic PASS.

---

## Novel Probes (Pass 41 — Four New Axes)

### Probe A — SSE Wire Examples (CLEAN)

Checked all SSE wire example fragments across spec docs against canon token set. 11 imperative StreamEvent variants confirmed (RunStart, NodeStart, ToolStart, StepStart, RunEnd, NodeEnd, ToolEnd, StepEnd, RunStream, NodeStream, ToolStream). Wire envelope consistent across 4 BCs: `{"__interrupt__": [InterruptPayload]}`. All tokens snake_case. Zero live retired tokens (`node_delta`, `interrupt_raised` as internal-only). CLEAN.

### Probe B — Red-Gate / VP-Seed Cross-Integrity (CLEAN)

5 Red Gate BCs identified. All 5 carry `red_gate: true` frontmatter in BC body. All 3 Kani seeds consistent with VP-INDEX (VP-001 → DI-001, VP-002 → DI-005, VP-003 → DI-007). 2 integration VPs consistent (VP-004 → DI-014, VP-005 → DI-014). VP↔DI matches all 5 VPs. BC-2.09.004 Red Gate test vector (RG TV) present. All 3 Kani seed BCs carry `vp_seed: true`. CLEAN.

### Probe C — L2-INDEX Shard Registry (CLEAN)

14 section shards listed in L2-INDEX header registry. Directory confirmed: 14 shard files present. Bijection exact — no missing shards, no phantom shards. Summary claims (14 FMs, 11 P0 CAPs, 19 CAPs total, shard word counts) match content. CLEAN.

### Probe D — BC Frontmatter Uniformity (CLEAN)

Sampled BCs across all 17 BC subsystem directories (ss-01..ss-17). All 86 BCs carry identical 11 core frontmatter fields: `document_type`, `bc_id`, `capability`, `priority`, `status`, `version`, `traces_to`, `author`, `reviewer`, `red_gate`, `vp_seed`. Conditional fields (`notes`, `provisional`) appear only where designed. No missing core fields, no extra mandatory fields. CLEAN.

---

## Novelty Assessment: LOW

All four novel probes across SSE wire examples, Red-Gate/VP-Seed cross-integrity, L2-INDEX shard bijection, and BC frontmatter uniformity returned CLEAN. No new defect classes discovered. Three observations are non-blocking stylistic or design-coherent notes, not defects.

Adversary assessment: "The spec package has converged. Recommend counting this as a clean pass toward the minimum-3-clean-passes gate."

---

## Fix Burst Summary

None. Zero findings — no fixes required. Convergence counter advances: 0/3 → 1/3.
