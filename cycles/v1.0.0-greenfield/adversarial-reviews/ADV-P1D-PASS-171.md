---
document_type: adversarial-review-pass
cycle: v1.0.0-greenfield
phase: 1d
pass: 171
verdict: NOT CLEAN
findings_count: 19
crit_count: 0
high_count: 5
med_count: 8
low_count: 4
obs_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→1→1→20→19"
timestamp: 2026-07-25T15:00:00Z
frozen_head: "67468a5477dc69fb17a09522c8c17eb5eb3f39f7"
scope: "narrow — burst-272 ActionRisk relocation audit (sub-pass P1D-171a); 4 axes carried to P1D-172"
novelty: HIGH
fix_burst: 273
---

# Adversarial Review Pass P1D-171 (Sub-Pass P1D-171a) — Phase 1d

**Verdict: NOT CLEAN** — 19 findings (0 CRIT, 5 HIGH, 8 MED, 4 LOW, 2 OBS). Counter: 0/3.

**CLEAN (strict):** no — 19 items present (0C/5H/8M/4L/2OBS)
**CLEAN (PR-merge):** no — 5 HIGH findings present

## Orchestration Deviation

Full-perimeter adversary dispatch died twice on API errors (`Connection closed mid-response`, `Stream idle timeout`) after approximately 316k tokens with zero findings emitted. The orchestrator split the pass into bounded sub-passes with fresh context each, run sequentially.

**Sub-pass P1D-171a executed** (scope: audit of the burst-272 `ActionRisk` relocation and burst-272 carrier changelog hygiene). Sub-passes covering the remaining axes were NOT run and are **carried forward as mandatory directed axes for P1D-172**:
- Governance-gate registry as executable content: ALL census/grep/awk commands in gates #19/#20/#21/#25/#27/#28/#29/#30/#32/#33/#35/#36 verified against current table headers and paths; gate #25 Part B renumbering 1–4→1–3 dangling-reference check; 36-gate count verification.
- Semantic (not existence) citation sweep for ADR-018, ADR-019, ADR-020, ADR-014, ADR-012, ADR-017, ADR-010 families — two validator blind spots: `+`-separated and paren-interleaved multi-Decision citations.
- End-to-end deep read of `specs/architecture/api-surface.md` (only 3 sites corrected in burst 272; rest unaudited), `prd-supplements/interface-definitions.md`, `specs/architecture/verification-coverage-matrix.md`, `specs/architecture/system-overview.md`.
- Broad regression sweep: all derived-count parity both directions; enum membership; error-taxonomy anchoring; wave/phase/priority propagation; observability catalog; VP red_gate uniformity; supersession blast radius; open future-imperative ADR handoffs; FREE HUNT.

## Convergence-Integrity Rule

**The three consecutive CLEAN(strict) passes required by BC-5.39.001 must each be FULL-PERIMETER passes.** A narrowed sub-pass may never advance the 3-CLEAN streak regardless of verdict. P1D-171 returned findings anyway, so the streak question is moot this pass — but the rule is explicit for all future passes.

## Novel Attack Angle

Token-based sweep limitation — burst-272 verification used token-based commands (`grep set_risk`, `grep ActionRisk::Critical`, `grep hitl/action_risk.rs`), so prose asserting the pre-relocation world WITHOUT naming the moved symbol's path was unreachable. The burst also verified the retired identifier was absent but never verified the replacement identifier resolves to a defined type (causing `ToolConfig` to become canonical across 11 sites while undefined). A `#[non_exhaustive]` type moved across a crate boundary silently invalidated every "closed/exhaustive match, no wildcard" invariant and CI gate asserting it.

## Part A — Fix Verification (P1D-170 findings)

All 20 P1D-170 findings were closed in fix-burst 272. Relocation verification confirmed: zero stale `ActionRisk` definition-home claims; zero live-body `set_risk`; zero surviving `ActionRisk::Critical`; purity per-class counts 32/36/12=80 correct; criticality 43 (11/18/12/2) consistent; build order acyclic and feasible. The relocation achieves its dependency-inversion objective cleanly.

## Part B — New Findings (P1D-171a — burst-272 relocation residue)

### F-P171a-01 HIGH (architect)

`ADR-018` §Rationale still justifies hook placement by co-location with `ActionRisk` ("keeps the trait alongside `ActionRisk`, `RiskGatePolicy`, and `GraphConfig`") and simultaneously denies the dependency inversion that its own amended §Decision 1 now asserts ("no such inversion exists here"). §Alternatives Considered Option C language refers to a pre-relocation placement concern that is now moot. The §Rationale must be rewritten to acknowledge the inversion and retire the co-location justification.

**Owner:** architect
**Status:** OPEN — fix-burst 273 pending

### F-P171a-02 HIGH (PO + architect adjudication)

`ToolConfig` is now the canonical risk-floor receiver across 11 live-body sites in 6 documents, but is **DEFINED NOWHERE**: zero `interface-definitions.md` entry, no fields, no `#[non_exhaustive]` declaration, no constructor, no module-decomposition row. The only home-crate mention is one ADR-018 §Decision 1 sentence. BC-2.23.005 defines `BashConfig`, not `ToolConfig`. Gate #32 carrier-3 obligation unmet.

Lifecycle contradiction: BC-2.23.005 §PC-4 says E-TOOLS-007 raised "At `ToolRegistry::register` time", while `interface-definitions.md` §PreToolCallHook and §First-Party Tools say construction time. Per Source-of-Truth Precedence, BC wins on contract semantics.

**Owner:** PO + architect adjudication
**Status:** OPEN — fix-burst 273 pending

### F-P171a-03 HIGH (PO)

`interface-definitions.md` §First-Party Tools BashTool canonical annotation reads `action_risk = ActionRisk::Medium` immediately below its own correct "action_risk floor: `ActionRisk::Medium`". Canon is `High` default / `Medium` floor (BC-2.23.005 §Description, ADR-020 §Decision 2 `tools::shell` table, module-decomposition §ferrochain-tools, capabilities-p1-p2 §CAP-037).

Security-relevant: an implementer copying the annotation ships BashTool at `Medium`, downgrading the BC-2.05.006 §PC-3/PC-4 gate from `RequireApprover(SeniorAnalyst)` to `RequireApprover(Analyst)`. VP-013 would not catch it since `Medium` passes the floor. Sibling to disambiguate: BC-2.08.010 §Related BCs.

**Owner:** PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-04 HIGH (PO)

`BC-2.05.006` §PC-3, §Invariants, and §Verification Properties VP-HITL-13 assert `ActionRisk` is a "closed, exhaustive enum with no wildcard variant" and gate Wave-1 CI on "exhaustive match … no wildcard arm". The canonical type is `#[non_exhaustive]`; post-relocation the enum lives in `ferrochain-core` while matching code is in `ferrochain-graph/src/hitl/policy.rs`, making a wildcard arm **MANDATORY** per CLAUDE.md `#[non_exhaustive]` rule for cross-crate matches. VP-HITL-13 cannot pass as written.

**Owner:** PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-05 HIGH (architect)

`purity-boundary-map.md` §Purity Enforcement Rules item 3 claims all 9 Kani VP harnesses operate only on Pure-Core-listed functions. Three contradict the file's own tables: VP-010 (`core::serializable` = Boundary), VP-011 (`graph::hitl` pre-tool dispatch = Boundary), VP-013 (`tools::shell` = Effectful Shell).

VP-013 is burst-272-implicated: the relocation's rationale was its Kani harness, and the burst added a Pure Core row for the **ENUM** while leaving the **HARNESS TARGET**'s module unclassifiable under Rule 3.

**Owner:** architect
**Status:** OPEN — fix-burst 273 pending

### F-P171a-06 MED (architect)

`dependency-graph.md` self-contradiction authored in burst 272: §Crate DAG annotation says `ferrochain-tools` depends on `+ ferrochain-macros`, but the §Edge Table has no such row and says the macro arrives "via core re-export". §Topological Build Order says "ferrochain-core … depends on macros for re-export" while §Invariant: No Circular Dependencies says "ferrochain-core MUST NOT depend on any other ferrochain crate"; no `ferrochain-core → ferrochain-macros` edge row exists.

Adversary independently **VERIFIED CLEAN**: build-order feasibility (tools@7 sees core@2/sandbox@4/macros@1; graph@8 re-exports from core@2; DAG acyclic). The relocation achieves its objective; the defect is in the explanatory text.

**Owner:** architect
**Status:** OPEN — fix-burst 273 pending

### F-P171a-07 MED (architect)

`purity-boundary-map.md` intro says "All 53 criticality-universe modules"; `module-decomposition.md` module universe has since moved to 55. The `79→80` and `31→32` figures in the same sentence were updated in burst 272 while `53` was left — a Gate #25 Part A miss. Independent recount CONFIRMS 32 Pure Core / 36 Effectful Shell / 12 Boundary = 80 correct. Also: the phrase "criticality-universe modules" collides with `module-criticality.md`'s authoritative 43 and should be renamed to avoid confusion.

**Owner:** architect
**Status:** OPEN — fix-burst 273 pending

### F-P171a-08 MED [process-gap] (PO)

Gate #32 step 4 — as REWRITTEN in burst 272 — declares "a module added by an ADR that does not appear in the arch registry is a gate #32 + gate #25 violation", which makes `core::action_risk`'s legitimate absence from `module-criticality.md` a violation. The definitions-only carve-out the burst relied on is UNWRITTEN, though applied consistently 5 times (`core::context_mutation`, `core::write_guard`, `core::guardrail`, `memory::skills`, `core::action_risk`).

Adversary adjudication: the burst's behavior was CORRECT; the gate text is the defect. Criticality registry independently recounted 11/18/12/2 = 43 CONSISTENT; `verification-coverage-matrix.md` §Per-Module Coverage Status = 43 rows with matching tiers.

**Owner:** PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-09 MED (architect + PO)

`ADR-018` §Decision 6 and §Consequences attribute the `#[tool(action_risk = …)]` macro extension to ADR-008, which contains ZERO `action_risk`/`ActionRisk` content. Validator #6 cannot catch it (no Decision number cited). Materially load-bearing post-relocation: the expansion must emit an absolute path form, which changed to a `::ferrochain_core::action_risk::ActionRisk` form, and NO document states the emitted path (not ADR-008, not ADR-018 §Decision 6, not BC-2.08.010 §Postconditions).

**Owner:** architect + PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-10 MED (architect)

`VP-013.md` §Proof Harness Skeleton defines THREE `#[kani::proof]` fns; `verification-architecture.md` §VP-013 sketch has only TWO (`risk_floor_accepts_at_or_above_medium` absent). Both files were edited in burst 272, so Gate #35 VP PROPERTY-BODY COHERENCE fired and was not satisfied.

Note: the `Critical` purge itself was independently **VERIFIED COMPLETE** and coherent in both files: `kani::assume(idx <= 3)`, `_ => ActionRisk::High`, "4 variants" everywhere, `#[repr(u8)]` ReadOnly=0..High=3, `if idx < 2` floor branch consistent with derived `Ord`; harness confirmed compilable — `matches!` on `pub code: &'static str` per ADR-010 §Decision.

**Owner:** architect
**Status:** OPEN — fix-burst 273 pending

### F-P171a-11 MED (architect + devops)

The same "BC-2.23.005 v1.1 = VAL" claim received THREE different TD-VSDD-091 treatments across two bursts: VP-013 §BC Contradictions was DE-PINNED as "newly-authored, not grandfathered", while the byte-parallel `verification-architecture.md` §VP-013 twin was ALLOWLISTED as "HISTORICAL-RECORD" — both originate from the same burst-233 F-P133-06 sweep. A third instance survives inside VP-013.md itself (§Feasibility Assessment "amended to `VAL` in burst-232 (v1.1)"), evading `verify-no-version-pins` because the version token is not adjacent to a document name.

Also: the allowlist header's "Permitted uses" block still enumerates Red Gate test tables / AC source-of-truth tables / historical before-state quotes — categories CLAUDE.md TD-VSDD-091 RETIRED as of 2026-07-24. That header was rewritten in burst 272 for the pin-text keying migration and should have been reconciled then.

**Owner:** architect + devops
**Status:** OPEN — fix-burst 273 pending

### F-P171a-12 MED [process-gap] (BA + PO + devops)

Gate #28 date-monotonicity violations survive in two burst-272 carriers: `domain-spec/entities-graph.md` has `v1.9 (2026-07-22)` ABOVE `v1.8 (2026-07-23)` (burst-242 is 2026-07-23); `prd-supplements/interface-definitions.md` has `2.49 (burst-240/…/2026-07-22)` ABOVE `2.48 (burst-236/…/2026-07-23)` (burst-240 is 2026-07-23). Both files were edited in burst 272 so Gate #28 Rule 4 TEMPORAL-NEIGHBOR SWEEP fired and was not executed.

Process-gap: Gate #28's census command enumerates only 5 files and is structurally blind to every Form-A frontmatter changelog in `architecture/`, `domain-spec/`, and `prd-supplements/`; the validator suite covers Form-A direction but NOT dates. Recommend a new `verify-changelog-date-monotonicity` validator over `.factory/specs/**/*.md`.

**Owner:** BA + PO + devops
**Status:** OPEN — fix-burst 273 pending

### F-P171a-13 MED (PO)

`BC-2.05.006` §Traceability `Module` row still reads `ferrochain-graph / ferrochain-server` though its first §Architecture Anchor is now `ferrochain-core/src/action_risk.rs`. The BC has no `crate:` frontmatter — this row is its sole crate attribution.

Adversary independently CONFIRMED the SS-05 ↔ `ferrochain-core` subsystem/crate split is LEGITIMATE — matches `core::guardrail`/SS-11, `core::budget`/SS-10, `core::write_guard`/SS-01+SS-15 precedents — and that `api-surface.md` already handles it correctly. Only the BC row is unswept.

**Owner:** PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-14 LOW (BA)

`domain-spec/entities-graph.md` §HITL Approval Hook Domain intro, authored in burst 272, says `ferrochain-tools` needs `ActionRisk` "without a ferrochain-graph **runtime** dep"; every sibling carrier says **compile-time**, which is the entire basis of the adjudication (the dependency-inversion rationale is specifically about compile-time edges, not runtime linking).

**Owner:** BA
**Status:** OPEN — fix-burst 273 pending

### F-P171a-15 LOW (architect)

`VP-013.md` `risk_floor_exhaustive_coverage` doc-comment says "Requires `kani::Arbitrary` derived for ActionRisk", contradicted by its own body which uses a `u8` index encoding precisely to avoid `Arbitrary`. The canonical derive list has no `Arbitrary`. §Proof Method carries the same incorrect conditional.

**Owner:** architect
**Status:** OPEN — fix-burst 273 pending

### F-P171a-16 LOW [process-gap] (PO)

The F-P133-07 "VP-NNN candidate is stale" adjudication was applied to architect-owned files only; approximately 40 PO/BA-owned sites retain the term including two canonical BC H1 titles (`BC-2.19.005`, `BC-2.21.003`) that propagate into BC-INDEX, prd.md, and bc-authoring-plan Batch tables, plus two `red_gate_source` strings. Adversary explicitly did NOT file BC-2.23.005/CAP-037 as defects (they match class siblings). Needs ONE adjudication either way.

**Owner:** PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-17 LOW [process-gap] (PO)

Gate #28 Rule 5 FRONTMATTER-CURRENCY has only two branches keyed on `introduced:` presence; its DEFER-002 pseudo-code applies the supplement rule to ADRs (which have no `introduced:`); 11 amended ADRs would fail it including burst-272 carriers ADR-018 and ADR-020. ADR-010 diverges from its siblings' decision-date convention.

Adversary did NOT file the ADRs as defective — the convention is unadjudicated. This is a process-gap: the gate text should be clarified to exclude ADRs or adjudicate the ADR decision-date convention.

**Owner:** PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-18 OBS (PO)

`interface-definitions.md` rust-labelled code fences contain single-slash comment markers (`/ ferrochain-graph: graph::hitl`, `/ #[ferrochain::tool(name = "list_dir", …)]`, BashTool timeout/output-cap comments, GrepTool match-cap comment, `CheckpointSaver` and `GuardrailHook` doc-comment blocks) — syntax errors that prevent compile-checking the blocks.

**Owner:** PO
**Status:** OPEN — fix-burst 273 pending

### F-P171a-19 OBS (architect)

`api-surface.md` §ferrochain-core Public Types now has an `ActionRisk` row while the three precedent types the relocation cites have no Public-Types rows (`BoundaryType`, `IngressContent`, `GuardrailResult`, `WriteGuardDecision`, `MemoryWriteRequest`, `PolicyDecision`, `OnCeiling` absent). Deferred to the P1D-172 api-surface deep-read axis.

**Owner:** architect
**Status:** OPEN — deferred to P1D-172 api-surface deep-read axis

## Part C — Verified-Clean Surfaces

Record for future pass economy (verified in sub-pass P1D-171a; do not re-check in P1D-172 unless a finding touches these):

| Surface | Verdict |
|---------|---------|
| Zero stale `ActionRisk` definition-home claims | CLEAN |
| Zero live-body `set_risk` | CLEAN |
| Zero surviving `ActionRisk::Critical` | CLEAN |
| Purity per-class counts (32 Pure Core / 36 Effectful Shell / 12 Boundary = 80) | CLEAN |
| Criticality registry 43 (11/18/12/2) consistent with `verification-coverage-matrix.md` | CLEAN |
| Build order acyclic and feasible | CLEAN |
| Three cited type-in-core precedents handled consistently | CLEAN |
| All 10 burst-272 carriers `version`↔newest-changelog-entry parity | CLEAN |
| All 10 burst-272 carriers changelog direction | CLEAN |

## Part D — Retracted Near-Misses

Two findings were raised and retracted via adversary self-validation:

1. **"Stale VP-013 candidate label"** — initially filed; retracted after sibling census showed approximately 40 conforming sites in PO/BA-owned files. Not a single-document defect — escalated as F-P171a-16 (process-gap requiring one adjudication).

2. **"Non-compiling `matches!` on a String code field"** — initially filed; retracted after ADR-010 §Decision confirmed `pub code: &'static str` (static string slice, not owned `String`). `matches!` on `&'static str` is valid.

## Part E — Orchestrator Self-Correction (Routing Lesson)

The orchestrator pre-adjudicated `ToolConfig::override_risk` as canonical in burst 272 on usage-majority evidence without verifying the receiver type was defined — the direct cause of F-P171a-02. Usage consensus across sites does not substitute for verifying the type has a definition, fields, and module placement. The standard after any "new canonical name" adjudication: confirm the type is defined, not just referenced.

## Summary

Sub-pass P1D-171a executed on frozen HEAD `67468a5477dc69fb17a09522c8c17eb5eb3f39f7` (burst-272 commit). 19 findings (0 CRIT / 5 HIGH / 8 MED / 4 LOW / 2 OBS). All OPEN — fix-burst 273 pending. Novelty HIGH.

The dominant finding class is **relocation residue**: prose that justified the pre-relocation world without naming the moved symbol was invisible to burst-272's token-based verification (L-036). The secondary class is **undefined canonical type**: `ToolConfig` became canonical across 11 sites while remaining undefined everywhere (L-037). Tertiary: **`#[non_exhaustive]` cross-crate boundary transition** silently invalidated `closed/exhaustive match, no wildcard` invariants in BCs and VPs (L-038). A further class: **attribute VALUES** (`action_risk = Medium`) are invisible to symbol greps and can silently weaken a security gate (L-039).

Streak: 0/3. Trajectory: →1→1→20→19.
