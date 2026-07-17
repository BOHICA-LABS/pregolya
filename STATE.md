---
document_type: pipeline-state
level: ops
version: "3.13"
status: in-progress
producer: state-manager
timestamp: 2026-07-17T13:40:00Z
phase: 1
inputs: []
input-hash: "[live-state]"
traces_to: ""
project: ferrochain
mode: greenfield+semport
current_step: "Phase 1d burst 174 COMPLETE — pass 92 (1H+1M budget-cluster echo) fixed + D18-P92-A RunnableConfig::budget_config canon; trajectory →2 (P1D-92); BC-2.10.003 v1.6, BC-2.10.004 v1.3, interface-definitions v2.32, api-surface v1.4, module-decomposition v1.10, entities-server v1.6; counter 0/3; adversary pass 93 next; trajectory-tail →4→1→4→2"
current_cycle: v1.0.0-greenfield
pipeline: IN_PROGRESS
dtu_required: true
dtu_assessment: 2026-07-14
dtu_clones_built: pending
dtu_services: [openai, anthropic, ollama]
user_directive_persistent: "Keep going until you hit convergence protocol. Convergence will happen, it can just take some time. Don't ask me if I want to continue — my answer will always be yes." (verbatim, 2026-07-13)
---

<!-- STATE.md SIZE BUDGET: 200-line soft limit / 500-line hard limit. Current: 195 lines (wc-l). margin from soft-target: 5 lines. margin from actual: 305 lines.
  Historical content → cycle files (burst-log, convergence-trajectory, session-checkpoints, lessons, blocking-issues-resolved).
  Run /vsdd-factory:compact-state if this file grows past 200 lines. -->

# Pipeline State: ferrochain

## Project Metadata

| Field | Value |
|-------|-------|
| **Product** | ferrochain (RESOLVED D6 — formerly working name langchain-rs; physical rename pending repo-init B2) |
| **Repository** | /Users/jmagady/Dev/ferrochain |
| **Mode** | greenfield + semport (Python→Rust semantic port) |
| **Language** | Rust (target), Python (reference corpus) |
| **Target Workspace** | Single Cargo workspace (D4) |
| **Reference Corpus** | .reference/ (gitignored) — langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (curated-subset), langchain-mcp-adapters==0.3.0 (SHA a61c783a), adk-rust v1.0.0 (SHA a6c79b6f, Corpus 5 per D16). Full pins: semport/reference-manifest.md v1.4.0 |
| **Started** | 2026-07-12 |
| **Last Updated** | 2026-07-17 — burst 174: pass 92 (1H+1M budget-cluster echo); D18-P92-A RunnableConfig::budget_config canon (per-run override; None=inherit GraphConfig::budget_config); BC-2.10.003 v1.6, BC-2.10.004 v1.3, interface-definitions v2.32, api-surface v1.4, module-decomposition v1.10, entities-server v1.6; trajectory →2 (P1D-92); counter 0/3; trajectory-tail →4→1→4→2 |
| **Current Phase** | 1 (Spec Crystallization) |
| **Current Step** | Burst 174 COMPLETE — pass 92 + fix burst (PO + architect + BA); NEXT: dispatch adversary pass 93. |

## Phase Progress

| Phase | Status | Started | Completed | Gate | Finding Progression |
|-------|--------|---------|-----------|------|---------------------|
| pre-1: Pre-Pipeline | COMPLETE | 2026-07-12 | 2026-07-14 | market-intelligence PASSED; adk-rust comparative cert 3-CLEAN CLOSED (C21-C23); D16 HUMAN DIRECTION GATE PASSED (D17) | — |
| 1: Spec Crystallization | in-progress | 2026-07-14 | | | →14 (P1D-1) →5 (P1D-2) →7 (P1D-3) →13 (P1D-4, re-baseline) →3 (P1D-5, decaying) →3 (P1D-6) →3 (P1D-7) →5 (P1D-8) →2 (P1D-9) →4 (P1D-10) →4 (P1D-11) →1 (P1D-12) →1 (P1D-13) →2 (P1D-14) →1 (P1D-15) →1 (P1D-16) →1 (P1D-17) →4 (P1D-18) →2 (P1D-19) →3 (P1D-20) →1 (P1D-21) →1 (P1D-22) →1 (P1D-23) →2 (P1D-24) →7 (P1D-25) →5 (P1D-26) →6 (P1D-27) →1 (P1D-28) →6 (P1D-29) →1 (P1D-30) →1 (P1D-31) →4 (P1D-32) →2 (P1D-33) →3 (P1D-34) →0 (P1D-35 CLEAN) →3 (P1D-36, reset) →2 (P1D-37) →1 (P1D-38) →2 (P1D-39) →1 (P1D-40) →0 (P1D-41 CLEAN) →1 (P1D-42, reset) →1 (P1D-43) →0 (P1D-44 CLEAN) →2 (P1D-45, reset) →1 (P1D-46) →2 (P1D-47) →1 (P1D-48) →1 (P1D-49; 1 rejected FP) →1 (P1D-50) →0 (P1D-51 CLEAN) →0 (P1D-52 CLEAN) →1 (P1D-53, reset) →0 (P1D-54 CLEAN) →1 (P1D-55, reset) →1 (P1D-56) →1 (P1D-57) →3 (P1D-58) →2 (P1D-59) →3 (P1D-60) →2 (P1D-61) →1 (P1D-62) →1 (P1D-63) →2 (P1D-64) →1 (P1D-65) →3 (P1D-66) →1 (P1D-67) →0 (P1D-68 CLEAN) →1 (P1D-69, reset) →2 (P1D-70) →0 (P1D-71 CLEAN) →[D20 expansion: +9 BCs +2 CAPs +ADR-012] →8 (P1D-72, D20-content scrutiny) →2 (P1D-73) →1 (P1D-74) →1 (P1D-75) →0 (P1D-76 CLEAN) →1 (P1D-77, reset) →4 (P1D-78) →2 (P1D-79) →1 (P1D-80) →1 (P1D-81) →2 (P1D-82) →3 (P1D-83) →1 (P1D-84) →4 (P1D-85) →2 (P1D-86) →2 (P1D-87) →4 (P1D-88) →4 (P1D-89) →1 (P1D-90, census-closure) →4 (P1D-91) →2 (P1D-92) |
| 2: Story Decomposition | not-started | | | | |
| 3: TDD Implementation | not-started | | | | |
| 4: Holdout Evaluation | not-started | | | | |
| 5: Adversarial Refinement | not-started | | | | |
| 6: Formal Hardening | not-started | | | | |
| 7: Convergence | not-started | | | | |
| Adversary pass-92 complete; pass-93 next | in-progress | 2026-07-14 | — | counter 0/3 (P92: NOT CLEAN 1H+1M budget-cluster echo; D18-P92-A RunnableConfig::budget_config; passes 91→92) | trajectory-tail →4→1→4→2 |
| Fix burst 174 complete (96 total) | complete | 2026-07-17 | 2026-07-17 | Pass 92: NOT CLEAN 2 findings (1H+1M); BC-2.10.003 v1.6 + BC-2.10.004 v1.3 (terminal TV/PC sweep) + D18-P92-A (RunnableConfig::budget_config: Option(BudgetConfig)); all fixed; counter 0/3 | trajectory-tail →4→1→4→2 |

## Current Phase Steps

<!-- Keep last 5 rows only. Archive older rows to cycles/v1.0.0-greenfield/burst-log.md. -->

| Step | Agent | Status | Output |
|------|-------|--------|--------|
| Phase 1d burst 170 — verification-architecture v1.3 + D18-P88-A corpus-wide closure | architect + state-manager | COMPLETE | Burst 170 (no adversary pass): verification-architecture.md formally bumped to v1.3; BC-INDEX removed from inputs:; six stable BC inputs + invariants.md + prd.md; input-hash 270a1de→8091abc. D18-P88-A interpretation note: versioned indexes (ARCH-INDEX, L2-INDEX) legitimate; rolling state-manager-authority files (STATE.md, BC-INDEX, STORY-INDEX) forbidden. 30-file corpus closure (29 burst-169 + 1 burst-170). Architecture census 9/9 CLEAN. Counter 0/3. Burst 170. |
| Phase 1d burst 171 — pass 89 + fix burst + corpus hash-currency sweep | adversary + PO + state-manager | COMPLETE | Pass 89: NOT CLEAN — 4 findings (1H+2M+1L) ALL FIXED. Novelty MEDIUM (all provenance-wave echoes). F-P89-01 (HIGH [process-gap], PO): gate #34 census block embedded stale per-file hash values asserting false PASS; STRUCTURAL FIX: per-file hash values NEVER recorded in gate text; frontmatter = single source of truth; bc-authoring-plan → v2.25. F-P89-02 (MED, PO): bc-authoring-plan frontmatter hash e786fea contradicted v2.24 changelog (e238778); reconciled: full chain documented (90d28fa→e238778→e786fea→41c29d9); frontmatter = 41c29d9. F-P89-03 (MED, PO): nfr-catalog "pending recomputation" deferral language + stale pre-removal hash; FIXED: v1.2, hash 2153125→0f05a12, deferral language closed. F-P89-04 (LOW, PO): BC-2.08.006 PC-3 stale "(or SS-TBD is used as a placeholder)" clause dropped; v1.2; hash 8095694→412902d. Corpus hash-currency sweep (D18-P89-A first execution): 4/6 supplements DRIFT + 94/95 BCs STALE refreshed to TOTAL MATCH (coherence verified passes 88-89). D18-P89-A codified. Trajectory →4 (P1D-89). Counter 0/3. Burst 171. |
| Phase 1d burst 172 — pass 90 coverage-caveat census + D18-P90-A hash refresh | adversary + state-manager | COMPLETE | Pass 90 adversary verdict: CLEAN(strict) read-only with coverage caveat. State-manager coverage-caveat closure: ARCH-INDEX.md hash drift found (edabdee vs 065003c computed; inputs prd.md + module-criticality.md staled by burst-171 D18-P89-A PO-scope sweep; ARCH-INDEX last touched burst 169). D18-P90-A adjudication (orchestrator): hash-only refreshes are state-manager-executable corpus-wide; cascade scope extended to files whose inputs: reference edited files. ARCH-INDEX.md refreshed (edabdee→065003c). Full census 126/126 TOTAL MATCH: supplements 6/6, BCs 95/95, arch 9/9, domain-spec 15/15, prd 1, product-brief 1. Effective pass-90 verdict: NOT CLEAN (1 census-closure finding). Trajectory →1 (P1D-90, census-closure). Counter 0/3. Fix bursts 93→94. Burst 172. |
| Phase 1d burst 173 — pass 91 + fix burst (3 specialists) | adversary + PO + BA + architect + state-manager | COMPLETE | Pass 91: NOT CLEAN — 4 findings (1H+1M+2OBS) ALL FIXED. Novelty MEDIUM (first genuine CONTENT-layer finding cluster: budget subsystem semantic mis-anchor). F-P91-01 (HIGH, PO+BA): SS-10 BC trio + CAP-012 attributed on_ceiling to BudgetPolicy TRAIT (impossible — pure trait carries no data field); canon = BudgetConfig STRUCT; FIXED: BC-2.10.001 v1.2, BC-2.10.003 v1.5, BC-2.10.004 v1.2, BC-2.06.003 v1.1, capabilities-p0 v1.2; post-fix corpus grep zero residual. F-P91-02 (MED, architect): OnCeiling + BudgetConfig undefined in interface-definitions; FIXED: v2.29 adds full defs (OnCeiling {Halt,Escalate,Summarize{summarize_prompt}}, BudgetConfig {soft_limit,hard_limit,on_ceiling}) + engine-branches-on-config prose; siblings module-decomposition v1.9, purity-boundary-map v1.4. F-P91-03 (OBS, architect): TOML default_on_ceiling omitted Summarize; ADJUDICATED bare-string default intentionally excludes Summarize (table form documented). F-P91-04 (OBS, PO): BC-2.15.004 EC-004 mapped read failure to E-MEMORY-002 StorageFull (write-semantic); E-MEMORY-008 MemoryStoreReadFailed MINTED (DURABILITY/broken/Maybe; anchor EC-004+TV-008; gate #31 PASS); BC-2.15.004 v1.1; error-taxonomy v1.18; interface-definitions v2.30. ERROR-CODE CENSUS 85→86 = 43+16+27. D18-P91-A + D18-P91-B. D18-P89-A sweep TOTAL MATCH. Trajectory →4 (P1D-91). Counter 0/3. Fix bursts 94→95. Burst 173. |
| Phase 1d burst 174 — pass 92 + fix burst (PO + architect + BA) | adversary + PO + architect + BA + state-manager | COMPLETE | Pass 92: NOT CLEAN — 2 findings (1H+1M) ALL FIXED. Novelty MEDIUM (partial-fix echo of pass-91 budget cluster at previously-unswept sites). F-P92-01 (HIGH, PO): BC-2.10.003 TV-001/007 + BC-2.10.004 PC6 still carried BudgetPolicy-owns-data forms (TV-001 "BudgetPolicy halt at 10k", TV-007 "BudgetPolicy with token ceiling", PC6 "policy's current ceiling"); terminal sweep; BC-2.10.003 v1.6, BC-2.10.004 v1.3. F-P92-02 (MED, D18-P92-A): RunnableConfig had no budget_config field defined despite BC-2.10.003 PC7 + BC-2.10.004 PC6 naming it as resume-patch target; ADJUDICATED OPTION A: RunnableConfig gains budget_config: Option(BudgetConfig) (per-run override; None=inherit GraphConfig::budget_config); interface-definitions v2.32 §RunnableConfig struct (4 fields + BC citations + BudgetResume::Extend); api-surface v1.4; module-decomposition v1.10; entities-server v1.6. Trajectory →2 (P1D-92). Counter 0/3. Fix bursts 95→96. Burst 174. |

## Decisions Log

| ID | Decision | Rationale | Phase | Date | Made By |
|----|----------|-----------|-------|------|---------|
| D1–D17, D18-P46-A–D18-P61-A | *Archived — see `.factory/planning/decisions-archive-pre-p1d.md`* | | pre-1 / phase-1d passes 46-61 | 2026-07-12 to 2026-07-18 | various |
| D18-P61-B | gate #31 near-name extension (step 4 widened): any UNRESOLVED type in a trait signature census must be checked against near-name corpus concepts; minting a new type name requires a near-name corpus search first (name-drift = HIGH). | F-P61-02 BudgetContext as near-name to RunContext | phase-1d | 2026-07-18 | adversary+PO |
| D18-P61-C | architect propagation: module-decomposition v1.3 adds core-definitions note (core/src/budget.rs hosts BudgetPolicy/PolicyDecision/TokenUsage/RunContext; graph::budget hosts dispatch [engine/journal]; guardrail-split precedent; no new criticality row, universe stays 33); ADR-009 v1.2 RunContext canon; BC-2.10.001..004 v1.1 anchors corrected. | F-P61-01 propagation via module-decomposition + BC anchors | phase-1d | 2026-07-18 | architect |
| D18-P62-A | xtask inventory = non-exhaustive + authoritative pointer (BCs BC-2.14.003-006/BC-2.08.007 + ADRs are the lint-gate registry; naming variants resolved at implementation vs governing BC; exhaustive enumeration rejected — false precision from cross-doc naming variants). deny-anyhow-in-lib + deny-description-cache-key added. Universe stays 33. | F-P62-01 via gate #32 first run | phase-1d | 2026-07-18 | adversary+architect |
| D18-P63-A | Fuzz-target canon: BC-2.17.002 defines exactly TWO cargo-fuzz targets (fuzz_checkpoint_serde, fuzz_graph_execution); splitter robustness = proptest + GTV Red Gate (BC-2.07.002) in v1; any post-v1 fuzz addition updates BC + coverage-matrix in the same burst. | F-P63-01: verification-architecture was the outlier vs BC + matrix | phase-1d | 2026-07-18 | adversary+architect |
| D18-P64-A | Default port 7437 mandated (server.port in ferrochain-server.toml); api-surface "no default" claim retired; interface-definitions §Base URL + config schema are the port authority. | F-P64-01 | phase-1d | 2026-07-18 | adversary+architect |
| D18-P64-B | Supplement body-changelog date monotonicity = mandatory check on every supplement-changelog edit (newest-at-top non-increasing; ≤ frontmatter timestamp). Root cause: F-P36-03 edits future-dated by 2 days in two files. | F-P64-02 | phase-1d | 2026-07-18 | adversary+PO |
| D18-P65-A | Gate #28 extended with Rule 4 TEMPORAL-NEIGHBOR SWEEP (all neighboring changelog rows in any edited file date-audited in same burst; pass N dates may not exceed pass N+1 artifact dates) + Rule 5 FRONTMATTER-CURRENCY (frontmatter timestamp must equal newest changelog entry date). Machine enforcement (pre-commit hook + CI lint) DEFERRED to Phase 3 CI hardening — logged as DEFER-002. bc-authoring-plan → v2.16. | F-P64-02 + F-P65-01: sweeps that don't enumerate the sibling set leave residue | phase-1d | 2026-07-18 | adversary+PO |
| D18-P66-A | E-SERVER-005 tombstoned — CORS denial = silent header-omission per BC-2.12.005 (no 403, no error body; removed from 403 row; disposition census 78 = 44+11+23; error-taxonomy v1.9; interface v2.17). | F-P66-03 HIGH — CORS rejection contradicted BC-2.12.005's silent denial canon | phase-1d | 2026-07-18 | adversary+PO |
| D18-P66-B | E-CHKPT-003 home = BC-2.04.005 EC-006+TV-008 [read/deserialize failure in crash recovery; v1.2]; E-MCP-003 re-anchored BC-2.09.001 EC-006/TV-008 [JSON-RPC -32601 method-not-found; v1.1]. | F-P66-02 + F-P66-01 orphan taxonomy codes given BC anchor homes | phase-1d | 2026-07-18 | adversary+PO |
| D18-P66-C | GATE #33 minted — taxonomy anchor reverse-verification: every live code's declared anchor BC must contain that code/variant + its raise condition; trigger: taxonomy edits + rotation; post-fix census 78/78 anchored; bc-authoring-plan v2.7. | OBS-P66-1 [process-gap]: forward+reverse traceability both now gated (#30 forward, #33 reverse) | phase-1d | 2026-07-18 | adversary+PO |
| D18-P67-A | Gate #21 cross-row routing-enumeration completeness sub-check: any code added/removed from a status row requires in-burst sweep of every other row's enumerations referencing that row. | F-P67-01: E-CHKPT-007 500-row add never propagated to the 422-row enumeration | phase-1d | 2026-07-18 | adversary+PO |
| D18-P69-A | Range notation banned in HTTP status rows — explicit enumeration required; gate #20 gains INTERNAL→500 axis (every INTERNAL code → 500 row or documented note; none in VAL-labeled rows) + range-expansion rule. Census 78 = 43+12+23. | F-P69-01: range shorthand hid a category mismatch from every membership census | phase-1d | 2026-07-19 | adversary+PO |
| D18-P70-A | Gate #32 ADR-propagation scope INCLUDES gate enforcement commands in bc-authoring-plan — placement adjudications must update the census tooling in the same burst. Gate #27 = budget-split rule + core/budget carve-out + positive assertion. | F-P70-01: pass-61 updated carriers but not the enforcement command | phase-1d | 2026-07-19 | adversary+PO |
| D18-P70-B | Gate #29 scope INCLUDES taxonomy notes referencing interface-definitions row content (cross-doc row-notes verified on every row edit). 401 note = categorical-fallback phrasing. | F-P70-02: P25-accurate note went stale at P26 | phase-1d | 2026-07-19 | adversary+PO |
| D18-P72-A | SkillStore public API is name-keyed + tag-filtered (fn get_skill(name: &str) → Skill + fn list_skills(tag: Option<&str>) → Vec<SkillRef>). The (namespace, key) compound-keyed interface was impl-internal; BC-2.15.004 + ADR-012 both specify name-keyed. interface-definitions v2.22 corrected. | F-P72-01 HIGH: SkillStore (namespace,key)-keyed vs BC/ADR name-keyed+tag-filtered | phase-1d | 2026-07-19 | adversary+architect |
| D18-P72-B | Replace.old_value type = Option<Value> (not Value). None = unconditional replace; Some(v) = match-based replace (only replaces if current value equals v). Aligns Replace semantics with CAS-style conditional write pattern. interface-definitions v2.22. | F-P72-02 MED: Replace old_value bare Value vs conditional-replace semantics | phase-1d | 2026-07-19 | adversary+PO |
| D18-P72-C | memory::skills has no criticality row in either registry (neither arch-view module-criticality nor PO-view criticality registry). It is a storage sub-module of ferrochain-memory, not a separately tracked module. Criticality governed by ferrochain-memory row (MEDIUM/HIGH split per write_guard). | OBS-P72 gate #32 review: memory::skills not in either registry | phase-1d | 2026-07-19 | adversary+PO |
| D18-P72-D | ADR-013 is the sole authority for mcp::server placement decisions (mcp::server = MEDIUM tier, ferrochain-mcp). ADR-012 scope = self-improvement primitives only (SkillStore, write_guard, context_mutation; 34 modules). Final universe = 35 = ADR-012 scope (34) + mcp::server via ADR-013. ARCH-INDEX v1.4. | F-P72-02 HIGH: mcp::server falsely attributed to ADR-012; ADR-013 minted to close the attribution gap | phase-1d | 2026-07-19 | adversary+architect |
| D18-P74-A | Gate #19 census command extended with retired shared-type names (CheckpointStore, RunConfig, BaseCheckpointSaver, AIMessage [Rust contexts], Checkpointer); gate #19 whole-tree traversal now covers interface-definitions.md on the retired-spelling axis (closing the gate #15 exclusion blind spot); domain-spec/ mapping tables excluded. | F-P74-01 twin in interface-definitions survived because no census covered it (OBS-P74-A [process-gap]: gate #15 excludes interface-definitions.md; gate #19 pattern omitted the retired shared-type names its own table lists) | phase-1d | 2026-07-15 | adversary+PO |
| D18-P75-A | Gate #28 extended with Rule 4 TEMPORAL-NEIGHBOR SWEEP (all neighboring changelog rows in any edited file date-audited in same burst; pass N dates may not exceed pass N+1 artifact dates) + Rule 5 FRONTMATTER-CURRENCY (frontmatter timestamp must equal newest changelog entry date). Machine enforcement (pre-commit hook + CI lint) DEFERRED to Phase 3 CI hardening — logged as DEFER-002. bc-authoring-plan → v2.16. | F-P75-01: 3rd recurrence of future-dated-changelog class (F-P64-02/F-P65-01/F-P75-01); manual gate #28 sweep demonstrably insufficient | phase-1d | 2026-07-15 | adversary+PO |
| D18-P77-A | ADR-local invariants must not squat the DI-NNN domain namespace; "ADR-012 DI-001" renamed → "ADR-012 INV-1"; propagated to BC-2.15.006 v1.1 (2 occurrences) + capabilities-p1-p2 v1.2 (1 occurrence); zero live "ADR-012 DI-001" residue (changelog audit-trail rows exempt). | OBS-P77-C: DI-001 globally = BSP Reducer Determinism; ADR-local squatting creates reference ambiguity | phase-1d | 2026-07-15 | adversary+architect |
| D18-P77-B | Gate #33 SEMANTIC-AGREEMENT sub-check steps 7–10: taxonomy Message Format template + raise-condition annotation must agree with anchor BC message text + EC/TV predicates; BC wins on any divergence; total standing gates unchanged 33; bc-authoring-plan → v2.17. | F-P77-01 survived name/presence-only gates #20+#33 — semantic axis was ungated | phase-1d | 2026-07-15 | adversary+PO |
| D18-P78-A | Universal `<ErrorName>: <detail>` message-prefix convention wins over BC message bodies lacking it; 12 BC-side prefix corrections applied (11 sweep + BC-2.04.008 F-P78-04); the ONLY sanctioned direction of BC-message edits under gate #33 is BC-side addition of the prefix when missing. | F-P78-04 + gate #33 first full sweep — previously implicit convention; 12 BCs lacked prefix | phase-1d | 2026-07-15 | adversary+PO |
| D18-P78-B | Gate #33 step 11 added: omission-note anchor citations in interface-definitions must point at a raising PC/EC; success-path citations (PC/EC that never raises the code) are violations; plan v2.18. Gates stay 33 (step added to existing gate). | F-P78-02/03 copy-paste success-path citations survived all prior passes; no gate checked citation semantics | phase-1d | 2026-07-15 | adversary+PO |
| D18-P84-A | Body citations to living supplements use section anchors only — no version pins; changelog pins exempt. Stale "interface-definitions.md v2.13" pins removed from BC-2.11.002/003/004 bodies; full behavioral-contracts/ grep confirmed zero remaining body-level version pins. | OBS-P84-B: stale version pins in SS-11 BC bodies survived all prior passes | phase-1d | 2026-07-15 | adversary+PO |
| D18-P86-A | Gate #28 Rule 5 (FRONTMATTER-CURRENCY) scoped by document type: supplement documents (`introduced:` field absent) — `timestamp:` must equal newest changelog entry date; BC files (`introduced:` field present) — `timestamp:` is the v1.0 authoring date (stable; currency tracked via version + changelog + introduced). Mechanically checkable single-field predicate for DEFER-002 Phase 3 enforcement. bc-authoring-plan → v2.19. | F-P86-02 [process-gap]: Rule 5 as written (D18-P75-A universal) contradicted consistent BC-corpus convention; Option B chosen for semantic clarity + zero information loss + single-field enforceability | phase-1d | 2026-07-16 | adversary+PO |
| D18-P87-A | Gate #28 Rule 1 scoped to supplement documents only (BC files exempt — `timestamp:` frozen at v1.0 authoring date per D18-P86-A; changelog rows dated after `timestamp:` are Rule-5-compliant, not Rule-1-violations); full 5-rule decision tree keyed on `introduced:` presence written for DEFER-002 linter; bc-authoring-plan → v2.20. | F-P87-01: D18-P86-A Rule-5 scoping created a live Rule-1 contradiction one layer up — universal Rule 1 fires false-positive on every compliant BC with post-v1.0 changelog rows | phase-1d | 2026-07-17 | adversary+PO |
| D18-P87-B | Input-hash canonical format = 7-char truncated MD5 for ALL spec artifacts (compute-input-hash tool + validate-input-hash hook authoritative); gate #34 minted (INPUT-HASH FORMAT CONSISTENCY, zero-exception; BC-INDEX `[live-index]` = sole documented exception); corpus normalized 95/95 BCs + 6/6 supplements; total standing gates 33→34. bc-authoring-plan → v2.22. | F-P87-02: 3-format split (7-char MD5 / 64-char SHA / placeholder) was oscillating without a declared canon; tool is deterministic authority | phase-1d | 2026-07-17 | adversary+PO |
| D18-P88-A | Live/mutable files under state-manager authority (STATE.md, sprint-state.yaml, rolling index files: BC-INDEX, STORY-INDEX) must NOT appear in any spec artifact's frontmatter `inputs:` list; stable facts are baked in at authoring time and cited by decision ID. INTERPRETATION (burst 170): versioned changelog-bearing spec indexes (ARCH-INDEX, L2-INDEX) ARE legitimate inputs — they carry immutable version history; the forbidden class is rolling live-mutable files. Corpus closure: 30 files total (29 burst-169 across PO/BA/architect + 1 burst-170: verification-architecture). | burst-168 process note: STATE.md-as-input re-drifted nfr-catalog/module-criticality hashes on every state write; sweep found the class was corpus-wide; burst-170 clarified interpretation boundary | phase-1d | 2026-07-17 | orchestrator+PO+BA+architect |
| D18-P89-A | END-OF-BURST HASH-CURRENCY SWEEP: every state-manager burst commit is preceded by a corpus-wide input-hash census; any file staled by the burst's edits gets `compute-input-hash --update` in the SAME commit (mechanical refresh sanctioned when the burst's adversary/fix cycle already verified content coherence; otherwise flag for review instead of refreshing). Prevents the pass-89 class: frontmatter/census/changelog hash incoherence from partial propagation. | F-P89-01/02/03: bursts 168-170 updated primary fields but not siblings; 94/95 BCs + 4/6 supplements staled silently | phase-1d | 2026-07-17 | adversary+PO+state-manager |
| D18-P90-A | Mechanical hash-only refreshes (`compute-input-hash --update`; zero content change) are state-manager-executable corpus-wide under the D18-P89-A standing sweep, regardless of content authority — content changes remain owner-authority. D18-P89-A sweep scope EXTENDED: after any burst, refresh not only files edited by the burst but ALL files whose `inputs:` lists reference an edited file (transitive, until census TOTAL MATCH). Root cause of ARCH-INDEX drift: burst-171 D18-P89-A sweep covered PO-scope supplements/BCs but not architect-authority ARCH-INDEX which listed prd.md + module-criticality.md (both swept) as inputs. | burst-172 verify census: ARCH-INDEX.md (architect-authority) staled by burst-171 PO-scope sweep; authority split created blind spot | phase-1d | 2026-07-17 | orchestrator+state-manager |
| D18-P91-A | on_ceiling canon: BudgetConfig struct (GraphConfig.budget_config) owns on_ceiling/soft_limit/hard_limit; BudgetPolicy trait stays pure+data-free (evaluate() only); engine branches on BudgetConfig::on_ceiling after Deny. OnCeiling + BudgetConfig now defined in interface-definitions §BudgetPolicy; TOML bare-string default excludes Summarize (table form [budget.on_ceiling] mode/summarize_prompt documented inline). | F-P91-01/02/03: SS-10 trio + CAP-012 attributed a data field to a pure trait; interface surface was incomplete | phase-1d | 2026-07-17 | adversary+architect+PO+BA |
| D18-P91-B | E-MEMORY-008 MemoryStoreReadFailed minted (DURABILITY/broken/Maybe; anchor BC-2.15.004 EC-004+TV-008). Error-code census 85→86 = 43+16+27. | F-P91-04: MEMORY namespace had no read/IO-failure code; StorageFull was semantically wrong for reads | phase-1d | 2026-07-17 | adversary+PO |
| D18-P92-A | RunnableConfig gains `budget_config: Option(BudgetConfig)` — per-run override, None = inherit GraphConfig::budget_config; resume ceiling changes patch RunnableConfig::budget_config (BudgetResume::Extend); GraphConfig-level mutation rejected (would leak across concurrent runs). §RunnableConfig struct now fully defined in interface-definitions v2.32 (4 fields: recursion_limit, thread_id, budget_config, context_mutations + per-field BC citations + BudgetResume::Extend mechanism prose). | F-P92-02: resume-path sites named RunnableConfig as ceiling-patch target but field was undefined; Option B (GraphConfig mutation) = production-grade race defect across concurrent runs; reference-corpus RunnableConfig = per-call override bag (TypedDict total=False) decisive. | phase-1d | 2026-07-17 | adversary+architect+PO+BA |

## Risk Register

| ID | Risk | Severity | Affects | Notes |
|----|------|----------|---------|-------|
| R1 | langgraph `scheduler-kafka` confirmed removed from langgraph 1.2.9. With D1 amended, treat as out-of-scope unless architecture finds a dependency | Low | Phase 1/3 | Effectively resolved by D1 amendment |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 3 | Phase community work last per D1 roadmap |
| R3 | DTU scope revised per D13 — ferrochain-server is first-party. DTU = OpenAI, Anthropic, provider APIs, Ollama keyless CI. Pass-6 "stateful fake" RETIRED. | Low | Phase 1 | Direction resolved by D13 |
| R4 | langgraph crate 0.2.5 (2026-07-01, pre-1.0) ships Postgres/Sqlite checkpointing. Competitor velocity HIGH confirmed. ferrochain differentiator = GA maturity + conformance suite + formal verification. Watch for their 1.0 release. | Medium | Phase 1/3 | R4 REFRAMED per burst-74 research. Monitor langgraph 1.0 release date. |
| R5 | Three incompatible tag conventions across reference repos — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling must handle all three |
| R6 | crates.io names verified available; GitHub=BOHICA-LABS/ferrochain registered; publish-all.sh prepped — human has NOT yet run publish-all.sh (cargo login required). Time-sensitive. NOTE (burst 79): canonical 18-crate roster established in ARCH-INDEX. publish-all.sh predates sandbox/memory/macros/-sdk additions — MUST BE REGENERATED for all 18 crates before running. | High | pre-1 | Pending human action: `cargo login` + regenerate publish-all.sh for 18 crates + run to reserve all ferrochain-* names |
| R7 | langchain-protocol v0.0.17 — no stable release; schema evolving. Port rationale is version-volatility, not immaturity (v3 streaming has 107 dedicated tests — corrected cert pass 9). | Low | Phase 1/3 | DOWNGRADED from Medium; full schema in .factory/semport/core/ANALYSIS-STATE.md |
| R8 | Splitters code-point vs byte-length parity: upstream `len()` calls on text are code-point counts — different split boundaries on non-ASCII. NOT covered by any upstream test. | High | Phase 1/3 | CRITICAL parity risk. Must become explicit BC + holdout scenario. Route to product-owner at Phase 1. |
| R9 | Platform API churn re-classified per D13 — SDK-1.2.9 endpoint catalog is design reference only; no conformance target. | Low | Phase 1 | Severity downgraded per D13 |
| R10 | Upstream coverage gap: NamedBarrierValue has NO dedicated unit test. EphemeralValue only 3 assert lines. Product-owner must author BCs + tests from behavior. | Medium | Phase 1 | Route to product-owner at Phase 1 |
| R11 | MCP upstream test voids: (1) mcp bare-ToolException re-raise path untested; (2) mcp `__aenter__` NotImplementedError contract untested. Same class as R8 and R10. | Medium | Phase 1/3 | Route to product-owner at Phase 1: must become explicit Red Gate tests |

## Skip Log

| Step | Skipped? | Justification |
|------|----------|---------------|
| Phase 0: Codebase Ingestion | yes | Greenfield — no existing Rust codebase to ingest. Replaced by semport-analyze of Python reference corpus. |

## Blocking Issues

<!-- Open issues only. Move resolved issues to cycles/<cycle>/blocking-issues-resolved.md. -->

| ID | Issue | Severity | Blocking Phase | Owner | Resolution |
|----|-------|----------|----------------|-------|------------|
| B1 | direnv not allowed — .envrc present but unenabled; 4 AWS/Anthropic key names declared | Low | pre-1 | human | Run `direnv allow .` from project root |

## Drift / Deferrals
| ID | Item | Target | Reason |
|----|------|--------|--------|
| DEFER-002 | Machine enforcement of gate #28 date-validity (pre-commit hook + CI lint for changelog-date monotonicity and frontmatter-currency) | Phase 3 CI hardening | 3rd manual-sweep failure (F-P64-02/F-P65-01/F-P75-01); gate #28 Rules 4+5 are prose-only until Phase 3. DEFER-001 archived in cycles/v0.0.0-pre-pipeline/lessons.md |

## Concurrent Cycles
None currently active. Counter 0/3; trajectory-tail →4→1→4→2.

## Convergence Status

| Metric | Value |
|--------|-------|
| Adversary passes completed | 92 (Phase 1d) |
| Fix bursts completed | 96 (Phase 1d: 72 fix + 5 D19/D20 expansion + 1 pass-77 fix + 1 pass-78 fix + full gate #33 sweep + 1 pass-79 fix + 1 pass-80 fix + 1 pass-81 fix + 1 pass-82 fix + 1 pass-83 fix + 1 pass-84 PO-half fix + 1 pass-84 architect-half fix + 1 pass-85 fix + 1 pass-86 fix + 1 pass-87 fix [large] + 1 pass-88 fix + 1 provenance burst + 1 verification-architecture v1.3 burst + 1 pass-89 fix + corpus hash-currency sweep + 1 pass-90 census-closure ARCH-INDEX hash refresh + 1 pass-91 fix [budget cluster] + 1 pass-92 fix [budget echo + D18-P92-A]) |
| Convergence counter | 0 of 3 (Phase 1d; NOT CLEAN pass 92: 1H+1M budget-cluster echo; D18-P92-A fixed; counter stays 0/3; pre-pipeline 3/3 CLOSED) |
| Finding trajectory | →4→2→2→4→4→1→4→2 |


## Session Resume Checkpoint

<!-- Keep ONLY the latest checkpoint. Archive prior checkpoints to cycles/v1.0.0-greenfield/session-checkpoints.md. -->

### RESUME IN ONE BREATH
"ferrochain Phase 1d convergence loop, 92 passes / 96 fix bursts, counter 0/3 (strict-zero D14; baseline 95 BCs 48/39/8, 21 CAPs, universe 35, census 86 = 43+16+27, 13 ADRs, 34 gates, test-vectors 512). trajectory-tail →4→1→4→2. NEXT ACTION: dispatch adversary pass 93 (counter 0/3; D18-P92-A RunnableConfig::budget_config: Option(BudgetConfig) canon; BC-2.10.003 v1.6/BC-2.10.004 v1.3 terminal sweep; interface-definitions v2.32 §RunnableConfig defined). Loop per D15 until 3/3, then /vsdd-factory:check-input-drift then Phase 1 human approval gate."
### HEADS: develop d018d3f (= origin, clean, pushed, CI green); factory-artifacts = burst 174 (run `git -C .factory log -1 --format='%h %s'`); no worktrees; no PRs; no in-flight agents.
### PASS-92 FIX SUMMARY: F-P92-01 HIGH (PO): BC-2.10.003 TV-001/007 + BC-2.10.004 PC6 BudgetPolicy-owns-data forms fixed; BC-2.10.003 v1.6, BC-2.10.004 v1.3; terminal sweep. F-P92-02 MED (D18-P92-A): RunnableConfig gains budget_config: Option(BudgetConfig) (per-run override; None=inherit GraphConfig::budget_config); interface-definitions v2.32 §RunnableConfig 4-field struct + BudgetResume::Extend; api-surface v1.4; module-decomposition v1.10; entities-server v1.6 (BudgetConfig entity + trait split + ER line).
### PASS-93 SIBLING-CHECKS: SS-10 pair (BC-2.10.003 v1.6 TVs/PC7, BC-2.10.004 v1.3 PC6) zero data-bearing-BudgetPolicy or fieldless-RunnableConfig-ceiling residue; interface-definitions v2.32 §RunnableConfig (4 fields + citations); api-surface v1.4 RunnableConfig row; module-decomposition v1.10; entities-server v1.6 (BudgetConfig entity + trait split + ER line); budget-cluster terminal-sweep verification.
### PENDING HUMAN ACTIONS: (1) direnv allow . [B1]; (2) regenerate + run publish-all.sh for 18 crates [R6 time-sensitive]; (3) langgraph 0.2.5 watch [R4]; (4) Phase 1 human approval gate awaiting 3/3 (Domain-D scope, D20 integration, 3 v2 deferrals, ADR-013).
### DECISION DELTA (burst 174): D18-P92-A (RunnableConfig::budget_config: Option(BudgetConfig) — per-run override; resume ceiling patches RunnableConfig::budget_config; GraphConfig mutation rejected; §RunnableConfig struct defined in interface-definitions v2.32).
### STANDING DIRECTIVES: D15 autonomous loop (verbatim in frontmatter); D14 strict-zero 3-consecutive-clean.
### WRAP METADATA: Date 2026-07-17 | Cycle v1.0.0-greenfield | Burst 174 | Counter 0/3 (Phase 1d)

## Historical Content

| Content | Location |
|---------|----------|
| Burst narratives (bursts 1–74, pre-pipeline semport+cert+adk-rust, Phase 1 A–E, Phase 1d P1–P2) | `cycles/v0.0.0-pre-pipeline/burst-log.md` + `cycles/v1.0.0-greenfield/burst-log.md` |
| 95 Behavioral Contracts (ss-01..ss-17/, ~13,800+ lines) + BC-INDEX.md v1.1 (48P0/39P1/8P2) | `.factory/specs/behavioral-contracts/ss-NN/` + `BC-INDEX.md` |
| L3 PRD (index + BC summary tables, 607 lines) + v1.0 Step-E annotation (BC-2.08.009) | `.factory/specs/prd.md` |
| PRD supplements: bc-authoring-plan v2.25, error-taxonomy v1.18, nfr-catalog v1.2, module-criticality v1.4, interface-definitions v2.32, test-vectors v1.7 | `.factory/specs/prd-supplements/` |
| L2 domain spec (15-shard, 1,889 lines) | `.factory/specs/domain-spec/L2-INDEX.md` (+ 14 section shards) |
| Validation report archive (passes 1–10, 3,478 lines) | `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` |
| Session checkpoints bursts 5–78 (archived) | `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` + `cycles/v1.0.0-greenfield/session-checkpoints.md` |
| Lessons learned (12 lessons, 12 codified guardrails incl. Guardrail #12 test-count methodology, Drift/Deferral DEFER-001) | `cycles/v0.0.0-pre-pipeline/lessons.md` |
| Holdout domain briefs A/B/C (SOC analyst, dark factory, OpenClaw) | `.factory/planning/holdout-domains/domain-{a,b,c}-*.md` |
| Reference corpus manifest (v1.4.0 — adk-rust Corpus 5 added) | `.factory/semport/reference-manifest.md` |
| Planning studies (naming decision, file-size standard) | `.factory/planning/naming-decision-study.md` + `file-size-standard-study.md` |
| Semport pass 1 analysis state (deepening items, risks) | `.factory/semport/core/ANALYSIS-STATE.md` |
| D16 comparative assessment + 3 part-files (COMPARATIVE-ASSESSMENT.md synthesis) | `.factory/comparative/COMPARATIVE-ASSESSMENT.md` (+ `assessment-parts/`) |
| Architecture core: ARCH-INDEX v1.4 + 9 section files (module-decomposition v1.10, purity-boundary-map v1.4) + ADR-013 (~1,300+ lines), 13 ADRs | `.factory/specs/architecture/` + `decisions/` |
| VP-INDEX + VP-001..005 (D17-Q7 top-3 BSP invariants + MCP integration VPs) | `.factory/specs/verification-properties/` |
| DTU assessment (DTU_REQUIRED: true; 3 cassette clone sets; pre-Phase-3 gate ≥8/7/3) | `.factory/planning/dtu-assessment.md` |
| ADR tech validation (schemars 1.2.1, rmp-serde 1.3.1, Kani 0.67.0 no-async) | `.factory/planning/adr-tech-validation.md` |
| Module criticality assessment (35 modules, architect version) | `.factory/specs/module-criticality.md` |
| CI/CD setup log (workspace-init; d018d3f; ci.yml; branch protection) | `.factory/planning/cicd-setup.md` |