---
document_type: adversarial-review
pass: 44
verdict: CLEAN
severity: null
novelty: LOW
phase: 1d
timestamp: 2026-07-16T15:00:00Z
findings_count: 0
observations_count: 1
---

# Adversarial Review — Pass 44

## Verdict: CLEAN — Zero findings. Novelty LOW.

---

## Findings

None.

---

## Observations

### OBS-P44-1: server-resource BC anchor intra-crate module paths inconsistent (api/*.rs vs routes/schedules.rs)

**Location:** `specs/behavioral-contracts/` — server-resource subsystem BCs

**Observation:** Several server-resource BCs cite Architecture Anchor paths inside
ferrochain-server using the `api/` directory convention (e.g., `api/runs.rs`,
`api/threads.rs`) while others cite `routes/schedules.rs`. Both are plausible
pre-implementation path variants within the correct crate (ferrochain-server). Gate #27
crate-resolution census passes because the crate itself is correct and roster-valid per
ADR-007; the intra-crate module path variance is covered by the pre-implementation
divergence exemption documented in OBS-P41-3 (Architecture Anchors include "to be
created" and "[architect to assign]" markers). No fix required pre-implementation.
Recorded for continuity and as a Phase 3 implementation handoff note.

---

## Sibling Checks

**(1) Gate #28 census (bc-authoring-plan v1.6, total 28, lines 909–959)** — PASS.
Gate #28 definition present and correctly specifies: version>1.0 requires changelog
entry per bump; `modified: []` is vestigial, not a substitute; census greps
version≠1.0 vs changelog presence.

**(2) Gate #28 version-distribution census RUN** — PASS. Distribution exact:
55×1.0 + 23×1.1 + 6×1.2 + 2×1.3 = 86. All 31 BCs with version >1.0 carry changelog
entries. Breakdown: v1.2 BCs: BC-2.04.006, BC-2.04.007, BC-2.08.003, BC-2.12.001,
BC-2.12.002, BC-2.12.003 (6 BCs); v1.3 BCs: BC-2.12.005, BC-2.14.002 (2 BCs). All
carry `changelog:` frontmatter key or `## Changelog` body table. No BC has version>1.0
without a changelog entry. Modified: [] confirmed vestigial across all sampled BCs.

**(3) Pass-43 adjudication spot-verify** — PASS. Four reverted BCs (BC-2.13.001,
BC-2.13.002, BC-2.13.003, BC-2.13.005) confirmed at `version: "1.0"` with no changelog
key. Thirteen kept BCs (ss-04/ss-11/ss-13 cohort minus the 4 reverted) confirmed at
`version: "1.1"` with `changelog:` key present in each.

---

## Censuses

### Census #21 — 12-Category Override Map (PASS)

12-category HTTP-status map intact. Exactly 9 documented overrides — no undocumented
overrides found. Override registry covers: E-GRAPH-002 (422), E-SERVER-004 (403),
E-GRAPH-013 (403), E-PROV-004 (401 categorical fallback), E-GRAPH-codes/422,
E-SERVER-016 (503), BC-2.14.002 PC3 8-override registry verified. All entries
cross-referenced to bc-authoring-plan gate #21.

### Census #22 — RetryHint Coherence Registry (PASS)

Registry exactly 5 entries. Both docs agree (error-taxonomy.md + bc-authoring-plan
gate #22). No new divergences found. All 5 per-code divergences documented with
authoritative BC references.

### Census #23 — StreamEvent Imperative Variants (PASS)

11 imperative variants confirmed: RunStart, NodeStart, ToolStart, StepStart, RunEnd,
NodeEnd, ToolEnd, StepEnd, RunStream, NodeStream, ToolStream. `node_stream` canonical
(not `node_delta` — retired). D13 native wire format confirmed (no LangGraph Platform
wire-compat). No live retired variants found.

### Census #24 — Six-Surface Pagination MANDATORY FULL RE-RUN (PASS 6/6)

MANDATORY re-run (skipped in pass 43). All 6 list endpoints fully comply with
D18-P31-A pagination convention. Full surface coverage:

1. GET /threads (BC-2.12.001 PC8/PC9) — limit default 10 / max 100 / CLAMP / offset 0 / created_at DESC. PASS.
2. GET /runs?thread_id (BC-2.12.001 PC17) — paginated per D18-P31-A. PASS.
3. GET /assistants (BC-2.12.002 PC21/PC22/PC23) — shape + pagination + created_at DESC. PASS.
4. GET /schedules (BC-2.12.003 PC18) — paginated per D18-P31-A. PASS.
5. GET /schedule-runs (BC-2.12.004 PC7) — paginated per D18-P31-A. PASS.
6. GET /versions (interface-definitions.md §17-B) — version ASC exemption documented. PASS.

Interface row convention compliance verified for all 6 surfaces. /versions version ASC
exemption entry present and correctly cited. Full convention notation in all rows. PASS 6/6.

### Census #26 — Run State Machine Lifecycle (PASS)

Run state machine lifecycle arrows confirmed: interrupted is NOT terminal (pausable);
terminal set confirmed as {completed, failed, cancelled} — exactly 3 terminal states.
No orphaned or undocumented lifecycle arrows found. Lifecycle-arrow canon intact.

### Census #27 — Crate-Resolution Census (PASS)

Zero live wrong-crate anchors. F-P42-01 propagation verified: BC-2.08.011 and
BC-2.08.012 Architecture Anchors confirmed as ferrochain-graph/src/graph/state.rs.
All other sampled anchor paths roster-valid per ADR-007. OBS-P44-1 intra-crate path
variance (api/*.rs vs routes/schedules.rs) exempted as pre-implementation divergence.

---

## Novel Probes (Pass 44 — Four New Axes)

### Probe A — Full Cross-BC Dependency Graph (CLEAN)

Exhaustive scan of all `traces_to:` fields across all 86 BCs. Every referenced
capability, decision-item, and VP ID resolves to an extant entry in the authoritative
registry. No dangling references found. No dependency cycles: all cross-BC references
are acyclic. Wave ordering respected: all cross-wave dependency edges run exclusively
Wave-1→Wave-0 (foundational); no Wave-0 BC references a Wave-1+ artifact as a
dependency. CLEAN.

### Probe B — Server BC EC HTTP Statuses vs Map + Overrides (CLEAN)

Exhaustive review of all server-subsystem BCs (BC-2.12.x, BC-2.14.x, BC-2.17.x) error
condition HTTP status codes against the 12-category map (gate #21) plus the 9 documented
overrides (gate #21 override registry). Every status code assignment in every server BC
EC is either consistent with the category default or documented in the override registry.
No undocumented HTTP status assignments found. CLEAN.

### Probe C — Inputs: Frontmatter Staleness Spot-Check (CLEAN)

Sampled frontmatter `inputs:` references across spec documents (semport/,
holdout-domains/, and comparative assessment references). All sampled file paths
resolve to extant files in the .factory/ tree. Semport references: resolve to
semport/core/, semport/reference-manifest.md. Holdout references: resolve to
planning/holdout-domains/. Comparative: resolve to comparative/COMPARATIVE-ASSESSMENT.md.
No stale `inputs:` paths found in the sampled set. CLEAN.

### Probe D — Cross-Supplement Version Citations (CLEAN)

Scanned all supplement documents (bc-authoring-plan, test-vectors, error-taxonomy,
nfr-catalog, module-criticality, interface-definitions) for cross-document version
citations. No direct version citations found between supplements (documents use
pass-ID/section references only, e.g., "per D18-P31-A", "per gate #24", "per BC-2.12.001
PC8"). No `v1.X` version-string cross-references between supplements — no risk of
dangling version citations after a supplement version bump. CLEAN.

---

## Propagation Verifications

**E-RETRY-004 propagation verify (S-7.01):** E-RETRY-004 (InvalidRetryLimit, VAL, Never)
fully propagated. Confirmed present in: error-taxonomy.md namespace table, BC-2.16.001
frontmatter + EC body, bc-authoring-plan gate entry. No ghost of old dual-meaning
E-RETRY-003 carrying InvalidRetryLimit semantics found. PASS.

**H1↔INDEX title parity (16+ samples):** Sampled 16+ BCs across ss-01..ss-17. All
sampled BC H1 titles (`# BC-N.NN.NNN — <Title>`) match the BC-INDEX.md row title
exactly. No title drift found. PASS.

---

## Novelty Assessment: LOW

All four novel probes returned CLEAN. Census #24 MANDATORY re-run passed 6/6. Sibling
checks passed. Three additional propagation verifications clean. One non-blocking
observation (OBS-P44-1: intra-crate path variance, exempted pre-implementation).
No new defect classes discovered.

Adversary assessment: "The spec package has converged. Recommend counting this pass
toward the minimum-3-clean-passes convergence gate."

---

## Fix Burst Summary

None. Zero findings — no fixes required. Convergence counter advances: 0/3 → 1/3.
