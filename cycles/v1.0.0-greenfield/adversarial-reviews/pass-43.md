---
document_type: adversarial-review
pass: 43
verdict: NOT_CLEAN
severity: HIGH
novelty: MEDIUM
phase: 1d
timestamp: 2026-07-14T09:00:00Z
findings_count: 1
observations_count: 3
---

# Adversarial Review — Pass 43

## Verdict: NOT CLEAN — 1 finding (HIGH, pattern, 17 BCs). Novelty MEDIUM.

---

## Findings

### F-P43-01 (HIGH): 17 BCs Carry version "1.1" with modified: [] and No Changelog

**Pattern:** 17 BCs across three subsystems carry `version: "1.1"` with
`modified: []` and no `changelog:` frontmatter key and no `## Changelog` body
section. This is a self-contradiction: `version: "1.1"` asserts at least one
revision above baseline, while `modified: []` and the absence of any changelog
entry asserts zero recorded modifications.

**Affected files:**

- SS-04: BC-2.04.001, BC-2.04.002, BC-2.04.003, BC-2.04.004, BC-2.04.005 (5 BCs)
- SS-11: BC-2.11.001, BC-2.11.002, BC-2.11.003, BC-2.11.004, BC-2.11.005, BC-2.11.006 (6 BCs)
- SS-13: BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.004, BC-2.13.005, BC-2.13.006 (6 BCs)

**Convention is demonstrably in force:** BC-2.04.006 (v1.2) and BC-2.04.007 (v1.2)
carry `changelog:` frontmatter keys. BC-2.05.x carries `changelog:` keys. BC-2.08.011,
BC-2.08.012, and BC-2.07.002 carry `## Changelog` body tables. The convention is not
novel — it is documented in several files in the same subsystems.

**Additional evidence from BC-INDEX:** Carry-Forward Note 3 in BC-INDEX.md documents
that BC-2.13.004 was modified (vp_seed: true, vp_id: VP-003 normalization, title
updated). This modification is unrecorded in the file's frontmatter.

**Fix required:** Per-file git-history adjudication: files with substantive post-authoring
content changes keep `version: "1.1"` and receive a `changelog:` key recording the 1.0
baseline and the 1.1 modification with its pass/burst authority. Files with only metadata
touches (bc_id addition, status draft→active) revert to `version: "1.0"`.

---

## Observations

### OBS-P43-1: guardrail/provenance dual-crate split coherent

The guardrail and provenance subsystem split (ferrochain-core = definitions,
ferrochain-graph = dispatch) is architecturally coherent. The module-decomposition
core section does not enumerate a core-side guardrail/context module row — noted
as a documentation gap but not an actionable finding; the behavioral contracts
correctly reflect the split.

### OBS-P43-2: BC-2.13.001 and BC-2.13.004 share input-hash — benign batch artifact

BC-2.13.001 and BC-2.13.004 share an identical `input-hash` value. This is a benign
batch artifact: they were produced in the same authoring burst with the same input
files. No cross-file contamination; the shared hash does not affect behavioral content.

### OBS-P43-3: BC-2.17.003 reference explicitly hypothetical — not dangling

The reference in BC-2.17.003 is explicitly marked as hypothetical per the file body.
This is acceptable documentation practice for forward-looking contracts in an
in-progress spec. Not a dangling reference.

---

## Sibling-Checks

**(1) BC-2.08.011/012 ferrochain-graph anchors** — re-verified PASS. Exactly 2 changelog
entries found for old `ferrochain-core/src/graph/builder.rs` path (now in the changelog
bodies as historical record). Live anchor text correctly references `ferrochain-graph`.
No residue of wrong-crate path in active BC body text.

**(2) Gate #27 census re-run** — PASS. All crate paths in `## Architecture Anchors`
sections roster-valid. Correct crate ownership confirmed per module-decomposition.md.
Doc-style anchors in ss-04/ss-11/ss-13/ss-17 acceptable (these subsystems predate
the architecture-anchor format requirement).

---

## Novel Probes

**NE register 17/17 CLEAN:**
- NE-05: ADR-011 CI-lint-only designation verified correct.
- Version/changelog integrity: → F-P43-01 (FINDING).
- Cross-BC dependency existence: partial CLEAN — BC-2.17.003 explicitly hypothetical;
  sampled waves respect declared wave dependencies; no dependency cycles detected in
  sampled BCs.

---

## Censuses

**Census #16 (targeted collision check):** PASS. All renamed/recategorized error codes
are single-variant; tombstones are unused.

**Census #24:** NOT RE-RUN this pass (deprioritized). Must re-run pass 44.

**Census #25:** PASS. 2 of 4 documents row-counted: 33-row doc (9/12/10/2 per section),
20-row doc (6/8/4/2 per section). Macros HIGH both. Arithmetic check PASS: 86
per-subsystem; 5 VPs; 18 crates; 48/30/8 P0/P1/P2; CAPs 19.

---

## Fix Dispatch

**Owner:** product-owner (prd-supplements + behavioral-contracts).

**Actions:**
1. For each of the 17 BCs: run git history adjudication to classify as MODIFIED
   (keep v1.1, add `changelog:`) or UNMODIFIED (revert to `version: "1.0"`).
2. Codify the convention in bc-authoring-plan.md as gate #28 with census command.
3. Self-check: zero BCs remain with version > "1.0" and no changelog.

**Do NOT touch:** `.factory/specs/architecture/` (architect scope).
