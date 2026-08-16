---
document_type: adversarial-review
level: ops
pass_id: P1D-184
pass_label: FULL-PERIMETER
frozen_head: 43101ef
date: 2026-08-16
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-16T23:59:00Z"
phase: 1
pass: 184
previous_review: pass-183.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P1D-184 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** 5 findings (1 HIGH + 3 MED + 1 LOW). CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak 0/3 (NOT CLEAN; 0 advancement). Route: architect (F-P1D184-02 MED, F-P1D184-03 MED, F-P1D184-04 MED anchor semantics, F-P1D184-05 LOW) + architect + product-owner (F-P1D184-01 HIGH: ADR adjudication → product-owner applies interface-definitions decl). Frozen HEAD: factory-artifacts `43101ef` (spec content frozen at `43101ef`). This is pass #185 total.

## Finding ID Convention

Finding IDs use the format: `F-P1D184-NN` (project-local shorthand). Canonical format per template: `ADV-P1CONV-P184-<SEV>-<SEQ>`.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-184 FULL-PERIMETER |
| Frozen HEAD | `43101ef` (spec content unchanged since burst-292) |
| Date | 2026-08-16 |
| Pass total | 185 passes total in project history |
| Method | FULL-PERIMETER. Deep-read axis targeting residual-coverage-debt artifacts from P1D-183: ADR full bodies 002/003/004/005/006/007/008/011/012/013/014/015/017/021/022/023/024; VP-001/009/011/013 bodies; api-surface.md; BC bodies SS-01/02/07/11/12/15 + remainder of SS-16/17/19. 5 findings (1 HIGH + 3 MED + 1 LOW). STREAK 0/3 (NOT CLEAN). |
| Scope | A: ADR-002/003/004/005/006/007/008/011/012/013/014/015/017/021/022/023/024 deep-read; VP-001/009/011/013 bodies; api-surface.md. B: BC bodies SS-01/02/07 + BC-INDEX. C: BC bodies SS-11/12/15 + remainder of SS-16/17/19. D: interface-definitions §RunnableConfig; ADR-018 Decisions 1–4; BC-2.11.001/BC-2.12.002/BC-2.12.004/BC-2.15.006/BC-2.16.001/BC-2.17.001. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — NOT CLEAN (5 findings; no advancement)** |

## Part A — Fix Verification

burst-292 closed F-P1D183-F1/F2/F3/F4 and OBS-P183-01 LOW. All four fixes verified sound.

| Prior Finding | Status | Evidence |
|---------------|--------|---------|
| F-P183-F2 HIGH ADR-025 §Context/§Decision S1-omission (burst-292) | VERIFIED SOUND | ADR-025 Context + Decision now read "S1, S2, S3, S4 / four canonical forms"; Consequences/Source-Origin/§as_retriever consistent |
| F-P183-F3 MED ARCH-INDEX §ADR-025 registry row (burst-292) | VERIFIED SOUND | ARCH-INDEX ADR-025 row reads "S1/S2/S3/S4"; consistent with body |
| F-P183-F1 MED module-decomposition §VP-012 boolean-trigger (burst-292) | VERIFIED SOUND | VP-012 anchor prose describes trigger-fires-iff condition accurately |
| F-P183-F4 MED tooling-selection §fuzz-target names (burst-292) | VERIFIED SOUND | tooling-selection names `fuzz_checkpoint_serde.rs` + `fuzz_graph_execution.rs` per BC-2.17.002 |
| OBS-P183-01 LOW §Kani async trio (burst-292) | VERIFIED SOUND | Updated to 5-module set per verification-architecture |

## Part B — New Findings

**5 findings: 1 HIGH + 3 MED + 1 LOW.**

### CRITICAL
*(none)*

### HIGH

#### F-P1D184-01 (HIGH) — RunnableConfig `#[non_exhaustive]` posture: ADR-021 vs ADR-023 contradiction with load-bearing backward-compat argument

**Description:** ADR-021 §Decision 2 rationale (approximately line 86) explicitly declares that `RunnableConfig` is NOT `#[non_exhaustive]`, and builds a backward-compatibility argument on that premise (external callers may construct `RunnableConfig` struct literals; removing `#[non_exhaustive]` is the deliberate API choice). ADR-023 Required Non-Exhaustive Inventory (approximately line 145) lists `RunnableConfig` as a MUST-be-`#[non_exhaustive]` type. `interface-definitions.md` §RunnableConfig (approximately line 241) declares the struct WITHOUT `#[non_exhaustive]` — agreeing with ADR-021, contradicting ADR-023.

This is a load-bearing contradiction: the semver commitment differs between the two ADRs. ADR-021 says external struct-literal construction of `RunnableConfig` is permitted (and intended); ADR-023 says it must be prohibited via `#[non_exhaustive]`. The two postures are mutually exclusive. `interface-definitions.md` is the implementation-bearing document; it currently follows ADR-021.

**Affected locations:**

| Location | Current State | Contradiction |
|----------|--------------|---------------|
| ADR-021 §Decision 2 rationale (~line 86) | `RunnableConfig` NOT `#[non_exhaustive]` (backward-compat) | Contradicts ADR-023 §Required Inventory |
| ADR-023 §Decision 3 Required Inventory (~line 145) | `RunnableConfig` MUST be `#[non_exhaustive]` | Contradicts ADR-021 §Decision 2 |
| interface-definitions.md §RunnableConfig (~line 241) | Declared WITHOUT `#[non_exhaustive]` | Follows ADR-021; contradicts ADR-023 |

**Fix:** Requires architect adjudication (ADR vs ADR per CLAUDE.md Source-of-Truth Precedence — same precedence level; route to architect then human if needed). Adjudication determines whether ADR-021 §Decision 2 is superseded by ADR-023 (ADR-023 wins → add `#[non_exhaustive]` to both ADR-021 rationale and interface-definitions), or ADR-023's Required Inventory row for `RunnableConfig` is an error (ADR-021 wins → remove `RunnableConfig` from ADR-023 inventory and add explicit exclusion note). Post-adjudication: product-owner applies the interface-definitions struct declaration per the adjudication verdict.

**Route:** architect (ADR-021 vs ADR-023 adjudication) + product-owner (interface-definitions §RunnableConfig struct declaration, per adjudication verdict).

**Defect class:** Cross-ADR content contradiction on a load-bearing type-shape fact (struct exhaustiveness / semver commitment). Same class family as the ADR-018/ADR-014 decision-reference mis-anchor family (F-P1D184-04 below), but at the ADR-authorship level rather than the cross-reference level.

---

### MEDIUM

#### F-P1D184-02 (MED) — ADR-014 document_index carry-method contradiction: §Consequences/§PO Obligations vs Decision 5

**Description:** ADR-014 §Consequences (approximately line 683) and §PO Obligations (approximately lines 711–712) state that `document_index` is "carried as a structured context field." ADR-014 Decision 5 (approximately lines 397–399), which is the authoritative decision row (F-P174-303 confirmed Decision 5 as authoritative), rejected the context field approach and mandates carry in the message string via `key=value` pairs. The consequence and obligation sections were not updated to match Decision 5. POL-24 sibling-sweep obligation was not discharged on the Decision 5 fix.

**Affected locations:**

| Location | Current Text | Expected (per Decision 5) |
|----------|-------------|--------------------------|
| ADR-014 §Consequences (~line 683) | "carried as a structured context field" | "carried in the message string via key=value pairs" (per Decision 5) |
| ADR-014 §PO Obligations (~lines 711–712) | document_index carry described as structured context field | Updated to message-string carry per Decision 5 |

**Fix:** ADR-014 §Consequences (~line 683) and §PO Obligations (~lines 711–712) — update carry-method description to match Decision 5 (message string via key=value). Architect owns ADR-014.

**Route:** architect.

**Defect class:** Partial-fix propagation within a single ADR — Decision row corrected but §Consequences and §PO Obligations not swept. Recurrence of the dominant mechanism identified in P1D-177 (D-134) and P1D-183 (D-152).

---

#### F-P1D184-03 (MED) — ADR-023 §Decision 3 Exempt Structs: `GuardedDocuments` anchored to wrong module

**Description:** ADR-023 §Decision 3 Exempt Structs table (approximately line 96) lists `GuardedDocuments` with module anchor `core::rag_ingress`. `rag_ingress` is a method name, not a module. The canonical module for `GuardedDocuments` is `core::retriever`, as established by: ADR-014 (approximately line 440, which names `GuardedDocuments` in the retriever context), interface-definitions.md (approximately line 1523, §GuardedDocuments under retriever subsection), module-decomposition.md (approximately line 320, `core::retriever` module entry), module-criticality.md (approximately line 167, `GuardedDocuments` under `core::retriever`), and verification-coverage-matrix.md (approximately line 127, `GuardedDocuments` retriever coverage row). Five independent sources agree on `core::retriever`; ADR-023 §Decision 3 is the sole outlier.

**Fix:** ADR-023 §Decision 3 Exempt Structs table — `GuardedDocuments` module anchor → `core::retriever`.

**Route:** architect (ADR-023 owner).

**Defect class:** Module-anchor mis-attribution in exempt-structs inventory. `rag_ingress` is a method in `core::retriever` that uses `GuardedDocuments`; the ADR conflated the method name with the module name.

---

#### F-P1D184-04 (MED) — BC-INDEX §VP Seed table: VP-011 anchor cites "ADR-018 Decision 1" (trait def) instead of "ADR-018 Decision 3" (fail-closed dispatch)

**Description:** BC-INDEX.md §VP Seed table (approximately line 113) lists VP-011 with source anchor "ADR-018 Decision 1" (the trait definition decision). VP-011 proves the fail-closed dispatch property. ADR-018 Decision 3 (approximately line 136) is the decision that names VP-011 as the proof obligation for fail-closed dispatch. Decision 1 defines the `ToolDispatcher` trait; Decision 3 mandates fail-closed behavior and explicitly ties to VP-011. The anchor should be "ADR-018 Decision 3."

This is the same Decision-1-vs-3/6 mis-anchor family that was fixed once for BC-2.16.001 (burst-271, P1D-169). The BC-INDEX VP Seed table is a sibling site that was not swept at that time.

**Fix:** BC-INDEX.md §VP Seed table VP-011 row — source anchor → "ADR-018 Decision 3".

**Route:** architect (anchor semantics, ADR-018 Decision 3 is the SoT for fail-closed dispatch obligation) + state-manager (BC-INDEX cell update, per routing table: cross-document index row maintenance).

**Defect class:** Decision-number mis-anchor in VP Seed table. Same family as BC-2.16.001 Decision-1-vs-3 mis-anchor fixed at burst-271; sibling site missed by the prior sibling-sweep.

---

### LOW

#### F-P1D184-05 (LOW) — ADR-011 §Source/Origin cites wrong xtask gate name

**Description:** ADR-011 §Source/Origin (approximately line 160) cites the xtask gate `check-client-timeout` as the enforcement gate for ADR-011's decision. `check-client-timeout` is the HTTP-timeout enforcement gate (ADR-007's domain). ADR-011's own gate is `deny-description-cache-key`, which is named three times in ADR-011's body at approximately lines 62, 91, and 134. The §Source/Origin row cites the wrong sibling gate.

**Fix:** ADR-011 §Source/Origin (~line 160) — gate citation → `deny-description-cache-key`.

**Route:** architect (ADR-011 owner).

**Defect class:** Sibling-gate citation error in §Source/Origin. Low impact (advisory gate name; no behavioral content affected) but incorrect cross-reference.

---

### PROCESS-GAP
*(none)*

## Part C — Observations (non-blocking)

*(none — all candidates either confirmed findings or discarded below)*

## Discards (candidates raised, all verified-not-finding)

| Slice | Candidate | Disposition |
|-------|-----------|-------------|
| A | ADR-002/003/005/006/007/008/012/013/015/017/021/022/024 full-body coherence | DISCARDED — all clean; no internal contradiction or cross-doc drift detected |
| A | ADR-006 StreamEvent variant count (16) | DISCARDED — exact; consistent with BC-2.06.001 SoT and all sibling documents |
| A | ADR-007/ADR-012/ADR-013 crate roster (18→21) | DISCARDED — all three ADRs consistent with the 21-crate roster per ADR-007 forward-amendment |
| A | ADR-022/ADR-023 census arithmetic reconciliation | DISCARDED — all census figures verified consistent across both ADRs |
| A | ADR-024 confinement (AS-01..09, PC-1..5, §Consumers) | DISCARDED — internal coherence verified; no contradiction |
| A | VP-001/VP-009/VP-011/VP-013 harness↔BC↔DI traceability | DISCARDED — all four VP files internally consistent; harness anchors correct; DI references valid |
| B/C | api-surface.md full body (StreamEvent 16, ActionRisk 4, Component 18-gate, feature-flags 10) | DISCARDED — all counts consistent; no drift detected |
| C | BC-2.11.001/BC-2.12.002/BC-2.12.004/BC-2.15.006/BC-2.16.001/BC-2.17.001 full bodies | DISCARDED — all internally coherent; no PC/AC/trace anomalies detected |
| A | VP-001 illustrative `matches!` fence (candidate: syntax vs prose) | DISCARDED — illustrative fence is explicitly labeled as such; not a normative code claim; false-positive |
| A | ADR-017 plural namespace candidate (candidate: namespace naming convention) | DISCARDED — ADR-017 uses plural form consistently per ADR-017 §Decision body; convention-consistent; false-positive |
| A | VP-013 bare `VAL` convention candidate | DISCARDED — VP-013 §Convention section defines the bare VAL shorthand explicitly; consistent usage throughout; false-positive |
| C | BC-2.17.001 DI-015 over-attribution candidate | DISCARDED — DI-015 attribution is correct per interface-definitions §DI-015 row; cross-check clean; false-positive |

## Balance Verified-CLEAN

| Axis | Result |
|------|--------|
| ADR-002/003/005/006/007/008/012/013/015/017/021/022/024 full-body coherence | CLEAN |
| ADR-006 StreamEvent variant count (16) | CLEAN — exact across all sibling documents |
| ADR-007/012/013 crate roster (18→21) | CLEAN — consistent post-ADR-007 forward-amendment |
| ADR-022/023 census arithmetic | CLEAN — all figures reconcile |
| ADR-024 confinement (AS-01..09, PC-1..5, §Consumers) | CLEAN |
| VP-001/009/011/013 harness↔BC↔DI traceability | CLEAN |
| api-surface.md (StreamEvent 16, ActionRisk 4, Component 18-gate, feature-flags 10) | CLEAN |
| BC-2.11.001/2.12.002/2.12.004/2.15.006/2.16.001/2.17.001 bodies | CLEAN |

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 1 |

**Overall Assessment:** NOT CLEAN
**Convergence:** FINDINGS_REMAIN (streak 0/3; 5 findings; fix burst-293 queued)
**Readiness:** Dispatch burst-293 (architect adjudicates F-P1D184-01 + fixes F-P1D184-02/03/04/05; product-owner applies F-P1D184-01 interface-definitions decl per adjudication), then dispatch P1D-185.

## Scope-Coverage Honesty

**DEEP-READ (exhaustive this pass):**
- `specs/architecture/decisions/ADR-002.md`, `ADR-003.md`, `ADR-004.md`, `ADR-005.md`, `ADR-006.md`, `ADR-007.md`, `ADR-008.md`, `ADR-011.md`, `ADR-012.md`, `ADR-013.md`, `ADR-014.md`, `ADR-015.md`, `ADR-017.md`, `ADR-021.md`, `ADR-022.md`, `ADR-023.md`, `ADR-024.md` — full bodies
- `specs/verification-properties/VP-001.md`, `VP-009.md`, `VP-011.md`, `VP-013.md` — full bodies
- `specs/architecture/api-surface.md` — full body
- `specs/architecture/decisions/ADR-018.md` §Decisions 1–4 — targeted deep-read for F-P1D184-04 validation
- `interface-definitions.md` §RunnableConfig (~line 241) — targeted deep-read for F-P1D184-01
- `specs/behavioral-contracts/BC-INDEX.md` §VP Seed table — targeted for F-P1D184-04
- `specs/behavioral-contracts/ss-01/` BC bodies, `ss-02/` BC bodies, `ss-07/` BC bodies — full bodies
- `specs/behavioral-contracts/ss-11/` BC bodies (BC-2.11.001), `ss-12/` BC bodies (BC-2.12.002/2.12.004), `ss-15/` BC bodies (BC-2.15.006), `ss-16/` BC bodies (BC-2.16.001), `ss-17/` BC bodies (BC-2.17.001) — full bodies

**RESIDUAL COVERAGE DEBT (next-pass target P1D-185):**
- `specs/behavioral-contracts/ss-16/` full roster not individually deep-read
- `specs/behavioral-contracts/ss-17/` full roster not individually deep-read
- `specs/behavioral-contracts/ss-19/` full roster not individually deep-read
- BC bodies SS-13/SS-14/SS-18/SS-20/SS-21/SS-22/SS-23 — not deep-read this pass

**Novelty:** MODERATE-HIGH — F-P1D184-01 (RunnableConfig `#[non_exhaustive]` ADR vs ADR contradiction) is a new instance of cross-ADR content contradiction on a load-bearing type-shape fact; this class is distinct from the grounded-rule-set-count drift class (P1D-183) but related: both arise from ADRs that were authored in sequence without sufficient sibling-sweep of the prior ADR's content. F-P1D184-02/03/04/05 are variants of known classes (partial-fix propagation, module-anchor mis-attribution, decision-number mis-anchor, sibling-gate citation error) surfaced in less-recently-deep-read ADRs. The machine-gated classes (§-anchors, StreamEvent count, census arithmetic) stayed clean, consistent with the convergence trend on gated axes.

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 184 |
| **New findings** | 5 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 0.65 (new cross-ADR contradiction class on type-shape; 4 variants of known classes in less-recently-touched ADRs) |
| **Median severity** | MEDIUM |
| **Trajectory** | →160→60→5→0→8→0→1→4→5 |
| **Verdict** | FINDINGS_REMAIN (streak 0/3; fix burst-293 queued) |
