---
document_type: spec-changelog
level: governance
version: "1.0"
status: active
producer: spec-steward
project: pregolya
timestamp: 2026-09-18T00:00:00Z
phase: 3
traces_to: .factory/spec-versions.md
inputs: []
input-hash: "d41d8cd"
changelog:
  - "1.0 (D-359/2026-09-17, spec-steward): Initial baseline spec-changelog. Seeded from major spec-evolution milestones recorded in STATE.md decisions log (D-197, D-354, D-356/D-357 cascade, D-359). Going-forward entries are appended per spec change."
---

# Spec Changelog — pregolya

> **Purpose:** Steward-level per-change impact log. Every versioned spec change that affects traceability, BC coverage, VP anchors, or ADR structure gets a changelog entry here. Individual artifact changelogs live in each artifact's frontmatter — this document is the cross-artifact aggregation surface.
>
> **Format:** Each entry records: Changed artifact(s), Version bump, Semver rationale, Added/Changed/Removed, and Impact assessment (which downstream artifacts are affected).
>
> **TD-VSDD-091:** All citations use behavioral-anchor / ID form. No file:line citations.

---

## [Unreleased] / [X.Y.Z] - YYYY-MM-DD

> Placeholder for spec changes in the current open cycle. Entries are appended here until the next release boundary, then moved under a versioned heading.

---

## [1.0.0] - YYYY-MM-DD

> Template anchor — see `[1.0.0] - 2026-09-17` below for the actual baseline entry.

## [1.0.0] - 2026-09-17

> Baseline establishment: pre-Phase-3 governance initialization. All spec artifacts authored and converged through Phase-2 (D-354) and D-356/D-357 amendment cascade. Phase-3 TDD pending.

---

## Entry SC-007 — D-360: pre-Wave-1 Spec Reconciliation Burst (2026-09-17)

**Event:** D-360 pre-Wave-1 reconciliation fix-burst; D-361 confirmation-pass corrections applied in same-day follow-up burst  
**Semver impact:** NONE (no spec content changed; annotation, records, and governance-baseline fixes only)

**Summary:** Three-lens audit of all 43 VP rows, wave-schedule taxonomy, and BC/story cross-references returned 0 blockers. Records and annotation fixes applied across BC-INDEX, STORY-INDEX, traceability-matrix, spec-versions, and spec-changelog. Governance baseline files initialized (traceability-matrix.md, spec-versions.md, spec-changelog.md seeded at D-359 and updated at D-360). D-361 confirmation-pass found four VP priority/tool transposition errors and one VP-2.24.002-A tool error in traceability-matrix, plus stale BC-INDEX and STORY-INDEX version rows in spec-versions.md and missing SC-007 changelog entry — all corrected in the same-day follow-up burst (D-361).

**Added:** Governance baseline files seeded: traceability-matrix.md §Changelog (D-359 baseline), spec-versions.md §Changelog (D-359 baseline), spec-changelog.md §Changelog (D-359 baseline); governance documents updated through D-360/D-361  
**Changed (D-360 burst):**
- traceability-matrix.md §Changelog: S-1.29 DAG edge corrected (depends_on S-1.10 restored); VP-2.11.007-B matrix row added; S-6.01 fuzz-crate story removed from matrix; S-2.05 sources annotation; wave-schedule taxonomy note; BC-INDEX §Red-Gate annotation (cross-reference subset note); BC-INDEX §VP-Seed annotation (body-file vs SEED distinction); STORY-INDEX §SS-24 blockquote annotation; STORY-INDEX §BC-2.12.003 S-console-10 reverse-anchor closure
- BC-INDEX §Changelog bumped (D-360 annotation fixes)
- STORY-INDEX §Changelog bumped (D-360 annotation fixes)
**Changed (D-361 confirmation-pass corrections — spec-steward):**
- spec-versions.md: BC-INDEX §Changelog row synced (2026-09-17); STORY-INDEX §L3-Story-Index row synced (D-360 interim; superseded by state-manager C1 below, 2026-09-18)
- traceability-matrix.md §Changelog (D-361 spec-steward): VP-006 priority P0→P1; VP-007 priority/tool P0/Kani→P1/proptest; VP-009 priority/tool P1/proptest→P0/Kani; VP-010 priority/tool P1/proptest→P0/Kani; VP-2.24.002-A tool Kani→proptest; Forward Traceability VP-006 label updated; VP Priority Distribution by Subsystem SS-16/17/18/other row corrected
- spec-changelog.md §SC-007 entry added

**Changed (D-361 corrective burst — state-manager, 2026-09-18):**
- STORY-INDEX.md §Changelog (C1): S-6.01 §Wave-6 Story Inventory Target Crate cell — removed stale fuzz entry; all three carriers (story frontmatter, sprint-state crate field, STORY-INDEX §Story-Inventory row) now consistent
- sprint-state.yaml S-6.01 vps: [VP-001,VP-002,VP-003,VP-006,VP-009,VP-010,VP-011,VP-012,VP-013,VP-019,VP-2.24.003-B] → [] (C2): sprint-state `vps` = VPs ANCHORED to story; S-6.01 anchors zero VPs per §VP-to-Story Anchor Map
- dependency-graph.md §Changelog (C3): §BC-to-Stories preamble corrected to authoritative census 149 BCs / 53 story files; stale "pending state-manager STATE.md sync" notes removed (2 sites)
- traceability-matrix.md §Changelog (C5): input-hash refreshed post STORY-INDEX §Changelog D-361/C1 edit
- spec-versions.md §L3-Story-Index row updated (2026-09-18)

**Removed:** None

**Impact:** No spec semantic content modified. Census UNCHANGED: BC 149 / VP 43 / EC 147 / TV 844 / stories 53 / pts 377 / ADR 31 / SS 24 / crates 22. VP-INDEX arithmetic invariant confirmed: P0=7 / P1=36 / Kani=10 / proptest=10 / integration=14 / unit=8 / compile-fail=1.

---

## Entry SC-006 — D-359: pre-Phase-3 Reconciliation (2026-09-17)

**Event:** D-359 DEVELOP-DIVERGENCE reconciliation  
**Semver impact:** NONE (no spec content changed; operational reconciliation only)

**Summary:** Non-destructive merge `6a50ebf` reconciles origin/develop PR#1 scaffold (`ae7b803`) with local ops commits (heartbeat cron `bfe0592`/`00d95e2`). settings.json add/add conflict resolved to origin defensive-guard form. `cargo check --workspace` PASS (21 crates + xtask). Pre-commit hooks PASS. CI/CD green on develop (5 required contexts). DTU Wave-1: no partner DTU needed; `dtu_clones_built` pending Wave-3.

**Added:** None  
**Changed:** settings.json (defensive-guard merge), CLAUDE.md heartbeat procedure D-318  
**Removed:** None

**Impact:** No spec artifacts modified. Census UNCHANGED: BC 149 / VP 43 / EC 147 / TV 844 / stories 53 / pts 377 / ADR 31 / SS 24 / crates 22. Phase-3 TDD PENDING after `git push origin develop`.

---

## Entry SC-005 — D-358/DC-71: D-356/D-357 Cascade Converged 3/3 (2026-09-10)

**Event:** D-356/D-357 spec-amendment cascade converged on frozen anchor d17c711  
**Semver impact:** MINOR (final state of cascade MINOR additions; no regressions)

**Summary:** DC-69/DC-70/DC-71 each returned CLEAN(strict)=yes. Three consecutive CLEAN(strict) passes on anchor d17c711 satisfy BC-5.39.001. Convergence declared. PG-DC32/33/34/43/46 all justified-deferral (first self-improvement wave; devops-engineer owner; pipeline-tooling scope).

**Added:** None (all cascade changes already in SC-004 entries)  
**Changed:** None (verification-only pass; no spec mutations)  
**Removed:** None

**Impact:** D-356/D-357 amendment cascade CLOSED. Phase-3 TDD gate OPEN. Census UNCHANGED from D-356 close: BC 149 / VP 43 / EC 147 / TV 844 / stories 53 / pts 377 / ADR 31 / SS 24 / crates 22.

---

## Entry SC-004 — D-356/D-357: SS-24 Developer Console + BC-2.11.007 + S-1.29 Amendment Cascade (2026-09-06 to 2026-09-10)

**Event:** Post-Phase-2 spec-amendment cascade (D-356/D-357); DC-01 through DC-71 fix-burst series  
**Semver impact:** MINOR — new BCs, VPs, stories added (no existing BC semantics broken)

### Phase-2-to-Phase-3 amendment cascade overview

This cascade was authorized as a pre-Phase-3 spec-completeness drive. The major additions are:

#### SS-24 Developer Console (DC-01 through DC-29 primary)

**Added:**
- BC-2.24.001 through BC-2.24.008 (8 new BCs; SS-24 Developer Console; P1; draft→active via POL-14 at PR merge)
- S-console-01 through S-console-10 (10 new Wave-3 ROADMAP-ONLY stories; 56 pts; all P1; pregolya-console / pregolya-graph / pregolya-server)
- VP-2.24.001-A/B/C through VP-2.24.008-A/B (21 new VPs; all P1; integration/unit/proptest/Kani/compile-fail; pregolya-console/pregolya-graph/pregolya-server)
- ADR-031 Developer Console Architecture (architect decision document; 8+ binding decisions DC-01 through DC-31)

**Changed:**
- BC-INDEX: +8 rows SS-24 section; VP Seed BCs table extended
- STORY-INDEX: +10 Wave-3 story rows; VP-to-Story Anchor Map +20 rows; BC-to-Story map §SS-24 section
- VP-INDEX: +21 VP rows (VP-2.24.001..008 A/B/C)
- ARCH-INDEX: +21 VP rows §Verification Properties; SS-24 subsystem section
- verification-architecture, verification-coverage-matrix: +SS-24 VP entries
- capabilities-p1-p2.md: CAP-041 through CAP-047 entries; multiple clarifications

**Impact:** Wave-3 roadmap stories added; pregolya-console crate established in architecture; Phase-3 Wave-3 scope defined. Census delta: BC 140→148, VP 21→40, stories 42→52, pts 316→372.

#### BC-2.11.007 GuardrailJournal Core-Domain Amendment (DC-33; human-authorized)

**Added:**
- BC-2.11.007 SS-11 P0: durable GuardrailJournal behavioral contract (graph::provenance accumulation + checkpoint-backed persistence)
- VP-2.11.007-A P0 integration: GuardrailJournal completeness one-entry-per-successfully-returning-evaluate()
- VP-2.11.007-B P1 integration: GuardrailJournal encryption-at-rest (BC-2.04.007 {INV-006} co-anchor)
- S-1.29 Wave-1 P0 (5 pts; BC-2.11.007 impl; depends_on [S-1.19, S-1.26]; blocks [S-console-10])
- E-CHKPT-012 GuardrailJournalWriteFailed + E-CHKPT-013 GuardrailJournalReadFailed (error taxonomy)
- TV-001 through TV-008 BC-local test vectors for BC-2.11.007

**Changed:**
- BC-2.12.003 §PC-013 projects guardrail_journal? on run-read
- BC-2.24.008 re-pointed to guardrail_journal?
- entities-server.md §GuardrailJournal entity definition
- interface-definitions.md §CheckpointSaver 3 journal ops
- module-decomposition.md graph::provenance + checkpoint::saver rows
- ADR-031 §Decision 8 (multiple revisions; DC-29 model superseded by DC-33; DC-33 model superseded by DC-39 checkpoint-backed model)
- S-console-10: depends_on extended with S-1.29

**Impact:** Wave-1 story count 28→29; total stories 52→53; pts 372→377; BC 148→149; VP 42→43; EC 145→147; TV increases. GuardrailJournal is now a first-class core-domain concept requiring Phase-3 implementation before S-console-10 can deliver.

#### Cascade Correction Bursts (DC-33 through DC-71)

Multiple HIGH/MED/LOW findings addressed through DC-33..DC-71. Key corrections:
- DC-34/DC-39: VP-2.11.007-A persistence model corrected to checkpoint-backed (graph::provenance; NOT RunStore terminal-write)
- DC-46/DC-64: checkpoint::encryption module renamed to checkpoint::serializer throughout
- DC-50: S-1.29 pregolya-checkpoint scope (saver.rs/sqlite.rs/memory.rs MODIFY tasks added)
- DC-62/DC-63/DC-65..DC-68: VP-2.11.007-B mirror propagation to all 10 mirror sites
- DC-07: SecurityConfig.debug_route_key canonical field name (was debug_api_key)
- DC-23: ADR-031 §Decision 6 RwLock for concurrent span readers; BC-2.06.002 INV-001 SAME-run_id semantics

**Impact:** All HIGH/MED corrections; no BC semantic regressions; census stabilized at BC 149 / VP 43 / EC 147 / TV 844 / stories 53 / pts 377 at DC-68 close.

---

## Entry SC-003 — Phase-2 Closed (D-354 / 2026-09-02)

**Event:** Phase-2 Story Decomposition converged; human gate APPROVED  
**Semver impact:** MINOR — story corpus and D-327 praxist additions

**Summary:** 3/3 CLEAN(strict) on frozen anchor 81d16ca (P2A-252/253/254, rounds 80/81/82; axis-diverse: parity/semantics/completeness). Consistency-validator PERIMETER-CONSISTENT. C-2 fixed (STORY-S-MAINT-001 v1.2→v1.3 count-ref sync). 4 deferrals human-authorized: C-1 VP naming pre-Phase-6; PG-1 multi-anchor mirror hook pre-Phase-3-wave-close; PG-2 story-changelog machine-coverage hook; PG-3 BC H1 angle-bracket normalization pre-Phase-6.

**Final Phase-2 census:** BC 140 / VP 21 / EC 143 / TV 795 / stories 42 / pts 316 / ADR 30 / holdout 24 (must-pass 17/24=70.8%) / NFR 15

**Added (D-327 praxist extension, 2026-08-31):**
- BC-2.02.007 LedgerChannel Dedup-Idempotent Append (SS-02)
- BC-2.02.008 LedgerChannel First-Appearance Ordering (SS-02)
- BC-2.02.009 PromoteRetireChannel Promote/Retire Lifecycle (SS-02)
- BC-2.04.009 TrajectoryWriter put_record Durability (SS-04)
- BC-2.04.010 TrajectoryReader replay Ascending step_idx Order (SS-04)
- BC-2.04.011 Trajectory Compaction Isolation (SS-04)
- S-1.28 LedgerChannel Promote/Retire (Wave 1 batch-1e; 5 pts; BC-2.02.007/008/009; VP-017)
- S-2.12 Trajectory Writer/Reader/Compaction (Wave 2 batch-2a; 8 pts; BC-2.04.009/010/011; VP-018/019)
- VP-017 LedgerChannel dedup-idempotency proptest P1
- VP-018 TrajectoryCompactor retention-integrity proptest P1
- VP-019 trajectory compaction crash-isolation integration P1
- VP-020 PromoteRetireChannel idempotency proptest P1 (D-340/round-62)
- ADR-030 Research-Orchestrator Composition
- nfr-catalog NFR-015 trajectory durability P0 (D-340 corrected P1→P0)
- E-TRAJ-005 TrajectoryCompactionStagingFailed / E-TRAJ-006 retracted E-TRAJ-004

**Changed:**
- D-346/round-67 BC-2.14.005 multi-anchor co-anchor S-1.02 + S-2.06 product-owner adjudication
- 200+ story version bumps through 82 adversary passes

**Impact:** Phase-2 story corpus complete; 42 stories (41 product + 1 maint); all 140 BCs covered; Phase-3 gated on human approval (granted D-354).

---

## Entry SC-002 — Phase-1 Closed (D-197 / burst-325 / 2026-08-18)

**Event:** Phase-1 Spec Crystallization converged; Phase-1 gate CLOSED  
**Semver impact:** MAJOR — full spec corpus authored (first MAJOR baseline)

**Summary:** 3/3 CONVERGED on frozen anchor 79eb2f3 (P1-pass-211/212/213; D-195). ~215 adversarial passes total during Phase-1. Input-hash drift resolved (D-196 ruling: input-hash refresh is bookkeeping metadata, not normative spec content). 

**Full spec corpus established at Phase-1 close (major artifacts):**
- prd.md v1.x (L3 PRD with CAP catalog)
- L2-INDEX.md + all domain-spec shards (capabilities, invariants, entities, events, edge-cases, risks, bounded-contexts, ubiquitous-language, assumptions, differentiators, failure-modes)
- BC-INDEX.md + ~119 BC body files (24 subsystems SS-01 through SS-23)
- ARCH-INDEX.md + all architecture sections (api-surface, dependency-graph, module-decomposition, purity-boundary-map, system-overview, tooling-selection, verification-architecture, verification-coverage-matrix)
- ADR-001 through ADR-029 (29 ADRs)
- BC-authoring-plan, error-taxonomy, interface-definitions, module-criticality, nfr-catalog, observability, test-vectors
- VP-INDEX.md + VP-001 through VP-016 (16 VPs; 6 P0 + 10 P1)
- holdout-scenarios 22 files

**Impact:** All Phase-2 artifacts trace back to Phase-1 BCs. Phase-1 is the MAJOR version boundary — all downstream artifacts (stories, VPs, proofs) trace through the Phase-1 BC corpus.

---

## Entry SC-001 — pre-1 Pipeline + semport (D-17 / 2026-07-14)

**Event:** Pipeline initialization; semport analysis complete; project named; briefing finalized  
**Semver impact:** MAJOR — initial project establishment

**Summary:** Pre-1 pipeline: market intelligence, naming decision (pregolya, D-103), adk-rust comparative 3-CLEAN, reference corpus pinned (langchain 1.3.13, langgraph 1.2.9, langchain-community 0.4.2, langchain-mcp-adapters 0.3.0, adk-rust 1.0.0). product-brief.md authored. Phase-1 started 2026-07-14 (D-17 human direction gate PASSED).

**Added:** product-brief.md, semport/ analysis, comparative assessment, planning artifacts  
**Changed:** None (initial establishment)

**Impact:** Establishes project identity, reference corpus, and pipeline mode (greenfield + semport).
