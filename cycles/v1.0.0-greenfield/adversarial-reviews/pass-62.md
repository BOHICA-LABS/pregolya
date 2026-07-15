---
document_type: adversarial-review-pass
phase: 1d
pass: 62
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 1
low_count: 0
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "→ gate #32 first full run; single enumeration gap"
timestamp: 2026-07-15T00:00:00Z
new_class: "none (gate #32 first full run — xtask enumeration-completeness gap)"
routing: "F-P62-01 → architect (module-decomposition owner)"
---

# Adversarial Review Pass 62 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (0 HIGH, 1 MED, 0 LOW) + 2 observations. Counter reset: 0/3 consecutive clean. Novelty: LOW-MEDIUM.

---

## F-P62-01 [MED] — module-decomposition §xtask Inventory Omits Two CI Lint Subcommands (ADR-010/ADR-011 Sole Enforcers)

**Finding class:** One-directional ADR→module-decomposition enumeration gap (gate #32 first full run).

**Status:** Pending-intent-verified → accepted. Routed to architect.

**Scope:** `.factory/specs/architecture/module-decomposition.md` §xtask CI lint inventory; `ADR-010` line 53; `ADR-011` line 107.

**Finding:** The `module-decomposition.md` §xtask section enumerates three CI lint subcommands:

| Subcommand | Source gate | NE |
|---|---|---|
| `check-file-size` | D12 | — |
| `deny-client-new` | NE-04 | — |
| `deny-expect-in-lib` | NE-07 | — |

Two additional subcommands are absent from this inventory despite being the **sole enforcement carriers** for active NE rules and domain invariants:

| Missing subcommand | Source | Sole enforcer of |
|---|---|---|
| `deny-anyhow-in-lib` | ADR-010 line 53 | NE-03 / DI-014 |
| `deny-description-cache-key` | ADR-011 line 107 | NE-05 |

Neither omission is qualified as a declared subset (unlike `module-criticality.md`'s explicit note that its NE table is a declared subset). The §xtask inventory is presented without a subset qualifier, implying completeness to primary consumers.

**Consumer impact:** Story-writer and implementer reading `module-decomposition.md` as the authoritative xtask build surface would under-build the CI lint layer — omitting two `cargo deny` subcommand stubs from the xtask crate. The omission is silent: no compilation error, no test failure at stub generation time; the gap would surface only when a CI run attempted to call the missing subcommands. NE-03 (no `anyhow` in library crates) and NE-05 (no `description`-keyed `Arc<dyn Any>` cache) would have zero automated enforcement in the delivered CI surface.

**Root cause:** One-directional traceability. ADR-010 and ADR-011 reference the enforcement subcommands, but `module-decomposition.md` §xtask was not updated when those ADRs were authored. The gap was not detectable by previous gate #32 partial scans (which checked crate-placement and type-home coherence, not enumeration completeness of xtask subcommands).

**Severity justification (MED):** The gap does not affect any existing behavioral contract or type spec, but it causes the delivered xtask CI surface to be structurally incomplete relative to the ADR requirements. Two NE rules would silently go unenforced. The fix surface is narrow (two rows in one table in `module-decomposition.md`) — no BC changes, no interface changes, no error-taxonomy changes required.

**Fix route:** Routed to architect (module-decomposition owner). Fix = add `deny-anyhow-in-lib` (NE-03/DI-014, ADR-010:53) and `deny-description-cache-key` (NE-05, ADR-011:107) to the §xtask subcommand inventory table. If a subset qualifier is intended, add explicit scope note (matching module-criticality's pattern). No spec files outside `module-decomposition.md` require changes.

---

## Observations

### OBS-P62-1 [process-gap] — RunContext RESOLVED Note Introduces SubAgentId Type Not Corpus-Defined

**Observation:** The ADR-009 v1.2 RunContext RESOLVED note references `sub_agent_id: Option<SubAgentId>` as a field on the resolved `RunContext` struct. `SubAgentId` is not defined in any corpus type-home document (no entry in `ferrochain-types/src/`, no BC postcondition, no architecture type-registry row). The field is internally consistent with the implementer-scope treatment noted in the pass's sibling checks (the field is within the `RunContext` struct, not exposed at the API surface), and no consumer document cites `SubAgentId` independently.

**Disposition:** Not flagged as a finding. The type is implementer-scope and its absence from a formal type-home document is consistent with the pattern for sub-agent plumbing types in this codebase. However, `SubAgentId` is a near-name candidate for gate #31 (near-name collision checks) due to potential confusion with `AgentId`, `RunId`, and `SubgraphId`. Flag for inclusion in the next gate #31 near-name census sweep.

**Tag:** [process-gap] — future gate #31 near-name candidate.

### OBS-P62-2 — NE-10 Lint Referenced Without Specific Subcommand Name

**Observation:** NE-10 appears in the module-decomposition §xtask section as a lint class reference without naming a specific subcommand. The reference is vaguer than the NE-03/NE-05/NE-04/NE-07 entries, which name concrete `cargo deny` or `cargo clippy` subcommand handles. This is a documentation-precision difference, not an enforcement gap — NE-10's enforcement mechanism (a `clippy` lint rather than a `deny` rule) makes a single subcommand name less applicable.

**Disposition:** Not flagged as a finding. The vagueness class is distinct from the enumeration-completeness gap in F-P62-01. No fix required.

---

## Sibling Checks 1–3 — ALL PASS

| Check | Target | Verdict |
|---|---|---|
| 1a | `module-decomposition.md` v1.3 note present + qualified row | PASS |
| 1b | `module-criticality.md` declared-subset NE table qualifier present | PASS |
| 2 | ADR-009 v1.2 RunContext RESOLVED note coherent with prior passes | PASS |
| 3a | BC-2.10.001–004 v1.1 anchors split, zero placeholders | PASS |
| 3b | `interface-definitions.md` v2.16 precondition-3 citation present | PASS |
| 3c | Zero live `BudgetContext` / `BudgetDecision` references in spec corpus | PASS |

---

## Mandatory Census #24 — Pagination Coherence PASS 6/6

Gate #24 PAGINATION COHERENCE: both carriers (interface-definitions.md and anchor BC postconditions) verified per surface.

| Surface | Interface row | BC postcondition | Verdict |
|---|---|---|---|
| GET /threads list | canonical pagination declared | BC PC present | PASS |
| GET /threads/{id}/history | canonical pagination declared | BC PC present | PASS |
| GET /assistants list | canonical pagination declared | BC-2.12.002 PC21-PC23 | PASS |
| GET /assistants/{id}/versions | canonical pagination + ASC exemption | BC-2.12.002 PC20 | PASS |
| GET /threads/{id}/runs | canonical pagination + status filter | BC-2.12.003 PC18 | PASS |
| GET /runs?schedule_id | canonical pagination + created_at DESC | BC-2.12.004 PC7 | PASS |

**Census verdict: 6/6 PASS — no pagination coherence gap.**

---

## Mandatory Census #25 — Summary Arithmetic A+B+C PASS

Census #25 (summary-arithmetic + criticality-sibling coherence):

| Axis | Count | Source | Verdict |
|---|---|---|---|
| BC Index total | 33 | BC-INDEX.md row count | — |
| BC breakdown | 9 P0 + 12 P1 + 10 P2 + 2 retired | BC-INDEX subsection counts | arithmetic: 9+12+10+2 = 33 PASS |
| retry=core assignment | present in bc-authoring-plan | authoring-plan §retry | PASS |
| Universe unchanged by definitions-note | zero new BCs minted this burst | delta check | PASS |

**Census verdict: ALL COUNTS RECONCILE — 33 = 9/12/10/2 across all four accounting docs; retry=core confirmed; universe unchanged.**

---

## Mandatory Census #28 — Dual-Form Coherence PASS

Gate #28 (dual-form coherence check): two canonical forms of the relevant spec construct verified mutually coherent. Approximately 20 high-traffic documents sampled (Level-2 partial disclosure — full list available on request).

**Census verdict: PASS — two forms coherent across sampled corpus.**

---

## Gate #32 — FIRST FULL RUN: Per-ADR Three-Carrier Crate-Placement/Type-Home Coherence

Gate #32 (per-ADR crate-placement and type-home coherence) ran in full for the first time this pass. All 11 ADRs verified individually across three carriers: (1) module-decomposition.md placement rows, (2) architecture type-home declarations, (3) BC postcondition/invariant anchors.

| ADR | Subject | Three-carrier coherence | Verdict |
|---|---|---|---|
| ADR-001 | Core crate boundaries | Placement + type-home + BC anchors coherent | PASS |
| ADR-002 | Runnable trait placement | Placement + type-home + BC anchors coherent | PASS |
| ADR-003 | Thread/Run state machine | Placement + type-home + BC anchors coherent | PASS |
| ADR-004 | Error taxonomy crate ownership | Placement + type-home + BC anchors coherent | PASS |
| ADR-005 | Config/context propagation | Placement + type-home + BC anchors coherent | PASS |
| ADR-006 | Persistence layer boundary | Placement + type-home + BC anchors coherent | PASS |
| ADR-007 | Workspace crate roster | Placement + type-home + BC anchors coherent | PASS |
| ADR-008 | Streaming architecture | Placement + type-home + BC anchors coherent | PASS |
| ADR-009 | RunContext / SubAgentId | Placement + type-home + BC anchors coherent | PASS |
| ADR-010 | deny-anyhow-in-lib (NE-03/DI-014) | Placement + type-home: PASS; **xtask enumeration: FAIL → F-P62-01** | FAIL (enumeration only) |
| ADR-011 | deny-description-cache-key (NE-05) | Placement + type-home: PASS; **xtask enumeration: FAIL → F-P62-01** | FAIL (enumeration only) |

**Gate #32 verdict:** ADR-001 through ADR-009 ALL PASS. ADR-010 and ADR-011 fail on xtask subcommand enumeration completeness only — the crate placement (xtask crate) and type-home declarations for the underlying deny rules are correct. The failures are enumeration-completeness gaps, not placement errors. Surfaced as F-P62-01.

---

## Rotated Censuses

| Gate | Description | Verdict |
|---|---|---|
| #16 | Title sync — BC H1 titles match BC-INDEX title column | PASS |
| #22 | DI-orphan zero — all domain invariants have at least one enforcing BC | PASS |
| #23 | Subsystem labels — all BC files use SS-NN IDs from ARCH-INDEX | PASS |
| #26 | VP 3-doc coherence — VP-INDEX, verification-architecture.md, verification-coverage-matrix.md mutually coherent | PASS |
| #30 | Disposition count — 79 confirmed active dispositions | PASS |
| #31 | Near-name RunContext RESOLVED — no near-name collision introduced by ADR-009 v1.2 | PASS (OBS-P62-1 flags SubAgentId for future sweep) |

---

## Free Probes

**Dual-layer recursion citation integrity:** Four-artifact coherence check (module-decomposition → architecture overview → BC postconditions → interface-definitions). Citations consistent across all four artifacts. No broken cross-references detected.

**RunContext field-set triangulation:** ADR-009 v1.2 field set (`graph_id`, `run_id`, `thread_id`, `parent_run_id`, `sub_agent_id`) verified against four independent sources: ADR-009 RESOLVED note, BC-2.10.001–004 postconditions, architecture overview §RunContext, interface-definitions.md precondition-3 citation. All four sources coherent. `sub_agent_id: Option<SubAgentId>` present in ADR-009 only (implementer-scope; not yet propagated to type-home docs — see OBS-P62-1).

---

## Novelty Assessment

**Classification: LOW-MEDIUM.**

**Basis:** Single enumeration gap surfaced by gate #32's first full run. The gap is narrow (two missing table rows in one document), local (module-decomposition.md §xtask only), and does not affect any BC, interface, error-taxonomy, or VP artifact. No new finding class — enumeration-completeness gaps are a known subclass of the ADR→module traceability class established in prior passes. The package is otherwise at convergence. The finding's significance is elevated to LOW-MEDIUM (rather than LOW) solely because the two omitted subcommands are each the **sole enforcer** of their respective NE rule/domain invariant — making the gap structurally consequential despite its small fix surface.

**Trajectory note:** Gate #32's first full run is a process milestone. The fact that only one finding emerged (and both failures were enumeration-completeness, not placement errors) confirms the ADR-to-architecture coherence layer is well-formed. Subsequent gate #32 runs will be incremental (new ADRs only).
