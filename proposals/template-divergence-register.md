---
document_type: proposal
proposal_id: TDIV-001
title: Template Divergence Authorization Register
status: accepted
author: spec-steward
date: 2026-07-28
version: "1.0"
changelog:
  - "1.0 (fix-burst-280/wave-d/2026-07-28): Initial register — authorizes L2-INDEX §Document Map column divergence per orchestrator decision; sweeps all AUTHORIZED-UNDOCUMENTED divergences across BC, VP, ADR, ARCH-INDEX, and prd-supplement artifacts; surfaces one DEFECT-class process-gap finding (spec-steward output paths unregistered in engine artifact path registry)."
---

# Template Divergence Authorization Register

> **Artifact path:** `.factory/proposals/template-divergence-register.md`
> **Registered as:** `artifact_type: proposal` in engine artifact path registry
> **Discovery trigger:** fix-burst-280 wave-D — business-analyst correction of stale line estimates
> in `L2-INDEX.md §Document Map` exposed a pre-existing, undocumented column-name divergence
> from the upstream template. An undocumented divergence is indistinguishable from a defect;
> this register was created to give the distinction a home.

## Purpose

This register records every place where a pregolya spec artifact deliberately diverges from
its upstream vsdd-factory template. All entries are either **AUTHORIZED-DOCUMENTED** (this
register) or pending authorization. The register exists so that future calls to
`/vsdd-factory:validate-template-compliance` can distinguish intentional divergences from
defects without re-litigating each one.

**Scope of upstream templates consulted:**
- `L2-domain-spec-index-template.md`
- `architecture-index-template.md`
- `behavioral-contract-template.md`
- `L4-verification-property-template.md`
- `adr-template.md`
- `prd-template.md`
- `prd-supplement-error-taxonomy-template.md`
- `prd-supplement-nfr-catalog-template.md`

**What this register covers:**
- Column or section name differences in spec index tables
- Frontmatter fields added beyond template minimum
- Frontmatter fields present in template but omitted in project artifacts
- Project-wide conventions that diverge from template defaults

**What this register does NOT cover:**
- Content of spec artifacts (values, not structure)
- Lifecycle state progression (e.g., `draft` → `active` — normal usage)
- Artifacts not yet reached by the initial sweep (to be appended on discovery)

---

## Pre-Existing Undocumented Divergence — The Finding Itself

The `Lines` column in `L2-INDEX.md §Document Map` diverged from the template's `Tokens` column
before fix-burst-280. Nothing in `.factory/` recorded this as a conscious decision. An
undocumented divergence is invisible to template-compliance auditing — which means
`/vsdd-factory:validate-template-compliance` either flags it as a defect or has been passing
it without detecting it. **The gap between divergence and its documentation is itself the
structural finding.** Lesson: any agent that deliberately diverges from an upstream template
MUST register the divergence at creation time, not retroactively.

---

## Divergence Records

### TDIV-001 — L2-INDEX §Document Map: Size column vs template `Tokens`

| Field | Value |
|-------|-------|
| Artifact | `.factory/specs/domain-spec/L2-INDEX.md §Document Map` |
| Upstream template | `L2-domain-spec-index-template.md §Document Map` |
| Divergence | Template mandates a `Tokens` column with `~NNN` token estimates. L2-INDEX used a `Lines` column with `~NNN` source-file line counts (pre-fix-burst-280). Per orchestrator decision in fix-burst-280, the column is being changed concurrently (by business-analyst) to a `Size` band column (values: S, M, L, XL; thresholds: S < 100 lines, M 100-300, L 300-600, XL > 600). The final authorized state is the `Size` band — a further divergence from `Tokens`, but a more durable one. |
| Classification | AUTHORIZED-DOCUMENTED (this entry) |
| Authorizing decision | Orchestrator, fix-burst-280 wave-D, 2026-07-28 |
| Durability rationale | A precise numeric estimate held in an index file decays silently on every shard edit, with no gate detecting the stale reference. This is structurally equivalent to the TD-VSDD-091 volatile-pin family: the value looks authoritative but goes stale the moment the shard content changes. Four cells were stale by +64 to +174 lines at the time of detection. A size band only changes when a shard crosses a tier boundary, which coincides with the existing DF-021 split review — the maintenance cost is already paid. The `Tokens` column in the upstream template has the same decay problem (a token estimate held outside the shard); replacing it with `Size` bands resolves the decay at lower cost than maintaining per-line or per-token estimates. |
| Engine template notes | The upstream template's `Tokens` column was not amended; amending it from inside a consumer project would affect all other vsdd-factory projects. |
| Date | 2026-07-28 |

### TDIV-002 — ARCH-INDEX §Document Map: `Tokens` column dropped entirely

| Field | Value |
|-------|-------|
| Artifact | `.factory/specs/architecture/ARCH-INDEX.md §Document Map` |
| Upstream template | `architecture-index-template.md §Document Map` |
| Divergence | Template mandates `Tokens` column between `File` and `Primary Consumer`. ARCH-INDEX drops the size column entirely; the Document Map has columns `Section \| File \| Primary Consumer \| Purpose` with no size indicator. |
| Classification | AUTHORIZED-UNDOCUMENTED (undocumented until this entry) |
| Authorizing decision | Architect made a deliberate choice at authoring time, consistent with the same durability rationale as TDIV-001. Not recorded at authoring. |
| Durability rationale | Same as TDIV-001: a numeric token estimate in an index file decays silently as section files are edited. The architect chose to omit the size column entirely rather than maintain stale estimates. This is defensible but should be made consistent with TDIV-001's resolution — consider adding a `Size` band column to ARCH-INDEX in a future burst (architect scope). |
| Routing | No immediate fix required. If alignment is desired, route to `vsdd-factory:architect`. |
| Date | 2026-07-28 |

### TDIV-003 — All versioned spec artifacts: Form-A `changelog:` frontmatter field

| Field | Value |
|-------|-------|
| Artifacts | All versioned spec artifacts: BC files, VP files, ADR files, L2-INDEX.md, ARCH-INDEX.md, BC-INDEX.md, VP-INDEX.md, prd.md, product-brief.md, all prd-supplements |
| Upstream template | All spec templates (none include `changelog:` in frontmatter) |
| Divergence | Templates do not define a frontmatter `changelog:` field. Pregolya standardizes on Form-A changelogs — a YAML list under `changelog:` in frontmatter — for all versioned spec artifacts. Templates support Form B (a `## Changelog` body section) but do not prescribe Form A. The `records-lint.sh §L1` gate enforces Form-A-or-Form-B changelog presence when `version > "1.0"`. |
| Classification | AUTHORIZED-UNDOCUMENTED (project-wide convention; now documented) |
| Authorizing decision | Project-wide gate `records-lint.sh §L1` (lesson L-010 / Gate #28) codifies Form A as the preferred form. The gate was established during adversarial convergence in the v1.0.0-greenfield cycle. |
| Rationale | Form A (frontmatter) is machine-parseable without body-section regex parsing. Agents reading spec metadata can infer version history from frontmatter alone, without loading the full document body. |
| Date | 2026-07-28 |

### TDIV-004 — VP files: Extended frontmatter beyond template minimum

| Field | Value |
|-------|-------|
| Artifacts | All VP files: `.factory/specs/verification-properties/VP-*.md` |
| Upstream template | `L4-verification-property-template.md` |
| Divergence | Template frontmatter defines a base set of VP fields. Pregolya VP files add the following beyond template minimum: `vp_id` (VP identifier), `title` (human-readable title), `bc_anchor` (primary BC linkage shorthand), `di_anchor` (domain invariant anchor), `crate` (implementing crate name), `tool` (proof tool shorthand), `proof_phase` (pipeline phase), `priority` (P0/P1 verification priority), `red_gate` (boolean), `red_gate_source` (architecture anchor for red-gate justification). |
| Classification | AUTHORIZED-UNDOCUMENTED (now documented) |
| Authorizing decision | Architect, v1.0.0-greenfield cycle. Fields added incrementally as traceability requirements emerged. |
| Rationale | The additional fields enable machine-extractable cross-references without loading full VP body content. The `validate-vp-consistency.sh` gate reads several of these fields programmatically. |
| Date | 2026-07-28 |

### TDIV-005 — ADR files: Extended frontmatter and `adr_id` format

| Field | Value |
|-------|-------|
| Artifacts | All ADR files: `.factory/specs/architecture/decisions/ADR-*.md` |
| Upstream template | `adr-template.md` |
| Divergence (a) | Template frontmatter defines: `document_type`, `adr_id`, `status`, `date`, `subsystems_affected`, `supersedes`, `superseded_by`. Pregolya ADR files add: `level`, `slug`, `title`, `gate`, `gate_note`, `producer`, `timestamp`, `version`, `phase`, `traces_to`, `decisions`, `changelog`. |
| Divergence (b) | Template format for `adr_id` is `ADR-NNN` (with prefix). Pregolya stores only the numeric part as a quoted string (e.g., `"001"`) — the `ADR-` prefix is implied by the filename. |
| Classification | AUTHORIZED-UNDOCUMENTED (now documented) |
| Authorizing decision | Architect, v1.0.0-greenfield cycle. Richer frontmatter supports the `verify-adr-decision-refs.sh` gate and the phase-gate tracking model. |
| Rationale | The gate and trace fields support the pipeline's D-series decision-gate system. The `adr_id` numeric format keeps the identifier short in frontmatter while retaining prefix-searchability via filename convention. |
| Date | 2026-07-28 |

### TDIV-006 — BC files: `bc_id`, `priority`, `wave` frontmatter additions; `traces_to` as list

| Field | Value |
|-------|-------|
| Artifacts | All BC files: `.factory/specs/behavioral-contracts/ss-NN/BC-*.md` |
| Upstream template | `behavioral-contract-template.md` |
| Divergence (a) | Template does not define `bc_id`, `priority`, or `wave` in frontmatter. Pregolya adds all three. `bc_id` stores the full identifier (e.g., `BC-2.01.001`) for machine extraction. `priority` stores P0/P1/P2. `wave` stores the implementation wave integer. |
| Divergence (b) | Template defines `traces_to` as a single string (`domain-spec/L2-INDEX.md`). Pregolya uses `traces_to` as a YAML list allowing multiple specific section anchors (e.g., `domain-spec/capabilities-p0.md#CAP-001` and `domain-spec/invariants.md#DI-008`). |
| Classification | AUTHORIZED-UNDOCUMENTED (now documented) |
| Authorizing decision | Product-owner, v1.0.0-greenfield cycle. The extra fields are consumed by validation hooks (`anchor-resolution-validator.sh`, `verify-bc-priority-counts.sh`). |
| Rationale | Multi-anchor `traces_to` provides per-BC granular traceability to specific L2 capabilities and invariants, which is more precise than a single index-level pointer. |
| Date | 2026-07-28 |

### TDIV-007 — prd-supplements: `traces_to` field absent

| Field | Value |
|-------|-------|
| Artifacts | `.factory/specs/prd-supplements/*.md` (error-taxonomy, nfr-catalog, interface-definitions, test-vectors, observability, module-criticality, bc-authoring-plan) |
| Upstream template | `prd-supplement-*-template.md` files — all include `traces_to: prd.md` |
| Divergence | Templates prescribe `traces_to: prd.md` as a required frontmatter field for all PRD supplements. Pregolya prd-supplement files omit this field. The traceability relationship (supplements trace to PRD) is implied by the `document_type: prd-supplement-*` convention. |
| Classification | AUTHORIZED-UNDOCUMENTED (likely intentional omission; now documented for confirmation) |
| Routing | `vsdd-factory:product-owner` — confirm whether omission is intentional or an oversight. If intentional, update this entry to AUTHORIZED-DOCUMENTED. If unintentional, add `traces_to: .factory/specs/prd.md` to all prd-supplement frontmatter. |
| Date | 2026-07-28 |

---

## Process-Gap Finding

### [process-gap] TDIV-008 — spec-steward designated output paths not registered in engine artifact path registry

| Field | Value |
|-------|-------|
| Severity | DEFECT — functional gap |
| Description | The spec-steward agent prompt designates four output paths: `.factory/spec-versions.md`, `.factory/traceability-matrix.md`, `.factory/spec-changelog.md`, and `.factory/drift-reports/`. None of these patterns appear in `plugins/vsdd-factory/config/artifact-path-registry.yaml`. The spec-steward's own Artifact Path Constraint states: "Before any Write under `.factory/`, verify the target path matches a pattern in `plugins/vsdd-factory/config/artifact-path-registry.yaml`. If unsure, use the `register-artifact` skill." This creates a functional deadlock: the spec-steward cannot produce its own designated outputs without triggering `ARTIFACT_PATH_UNREGISTERED`. |
| Consequence | The spec-steward is unable to produce its canonical spec-versions registry, traceability matrix, spec-changelog, or drift reports as standalone `.factory/` documents. Governance artifacts produced by the spec-steward must currently be routed to registered paths (such as this proposals register, or cycle-documents). |
| Recommendation | Route to `vsdd-factory:devops-engineer` to register `spec-versions`, `traceability-matrix`, `spec-changelog`, and `drift-reports/` artifact types in the engine artifact path registry. Until registered, spec governance artifacts should use `.factory/proposals/{filename}.md` (registered, enforcement_level: block) as the interim container. |
| Routing | `vsdd-factory:devops-engineer` for engine registry additions. This requires an engine-level change (not a project-level change) and should be done via the standard vsdd-factory plugin upgrade path. |
| Date | 2026-07-28 |

---

## Divergence Summary Table

| TDIV-ID | Artifact | Template | Divergence | Classification | Owning Specialist |
|---------|----------|----------|------------|----------------|-------------------|
| TDIV-001 | L2-INDEX.md §Document Map | `L2-domain-spec-index-template.md §Document Map` | `Lines` column → `Size` band (concurrent); template mandates `Tokens` | AUTHORIZED-DOCUMENTED | business-analyst (concurrent fix) |
| TDIV-002 | ARCH-INDEX.md §Document Map | `architecture-index-template.md §Document Map` | `Tokens` column dropped entirely | AUTHORIZED-UNDOCUMENTED | architect |
| TDIV-003 | All versioned spec artifacts | All spec templates | Form-A `changelog:` frontmatter field (not in any template) | AUTHORIZED-UNDOCUMENTED | state-manager (owns changelog discipline) |
| TDIV-004 | VP files | `L4-verification-property-template.md` | Extended frontmatter: `vp_id`, `title`, `bc_anchor`, `di_anchor`, `crate`, `tool`, `proof_phase`, `priority`, `red_gate`, `red_gate_source` | AUTHORIZED-UNDOCUMENTED | architect |
| TDIV-005 | ADR files | `adr-template.md` | Extended frontmatter; `adr_id` as numeric string not `ADR-NNN` | AUTHORIZED-UNDOCUMENTED | architect |
| TDIV-006 | BC files | `behavioral-contract-template.md` | `bc_id`, `priority`, `wave` added; `traces_to` as list | AUTHORIZED-UNDOCUMENTED | product-owner |
| TDIV-007 | prd-supplements | `prd-supplement-*-template.md` | `traces_to: prd.md` absent | AUTHORIZED-UNDOCUMENTED (confirm) | product-owner |
| TDIV-008 | spec-steward output paths | Engine artifact path registry | spec-steward designated paths unregistered | DEFECT [process-gap] | devops-engineer |
