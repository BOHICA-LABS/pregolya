---
document_type: spec-version-registry
level: governance
version: "1.0"
status: active
producer: spec-steward
timestamp: 2026-09-17T00:00:00Z
baseline_event: "D-359/2026-09-17 — pre-Phase-3 reconciliation; DEVELOP-DIVERGENCE resolved; census BC 149 / VP 43 / EC 147 / TV 844 / stories 53 / pts 377 / ADR 31 / SS 24 / crates 22"
changelog:
  - "1.0 (D-359/2026-09-17, spec-steward): Initial baseline snapshot. Aggregated from frontmatter of all living spec artifacts as of post-reconciliation state. Census: BC 149 / VP 43 / EC 147 / TV 844 / stories 53 / pts 377 / ADR 31 / SS 24 / crates 22."
---

# Spec Version Registry — pregolya

> **Purpose:** Version-of-record snapshot for every spec artifact. This registry is updated by the spec-steward on each spec change. Authoritative versions live in each artifact's own frontmatter `version:` field — this table is the aggregation surface.
>
> **Baseline snapshot:** D-359 / 2026-09-17 — pre-Phase-3 state. D-356/D-357 amendment cascade converged 3/3 CLEAN(strict) on anchor d17c711 (DC-71). DEVELOP-DIVERGENCE reconciled (merge 6a50ebf). Phase-3 TDD pending.

## L1 Vision / Product Brief

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| specs/product-brief.md | pre-versioned | 2026-07-12 | business-analyst |

## L2 Domain Specification

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| specs/domain-spec/L2-INDEX.md | v1.35 | 2026-09-08 | state-manager |
| specs/domain-spec/capabilities-p0.md | v1.10 | Phase-1 close | business-analyst |
| specs/domain-spec/capabilities-p1-p2.md | v1.40 | 2026-09-08 (D-356 cascade) | business-analyst |
| specs/domain-spec/invariants.md | v1.7 | Phase-1 close | business-analyst |
| specs/domain-spec/entities-graph.md | v1.17 | D-356 cascade | business-analyst |
| specs/domain-spec/entities-server.md | v1.27 | D-356 cascade | business-analyst |
| specs/domain-spec/events.md | v1.13 | Phase-1 close | business-analyst |
| specs/domain-spec/edge-cases.md | v1.4 | Phase-1 close | business-analyst |
| specs/domain-spec/bounded-contexts.md | v1.6 | Phase-1 close | business-analyst |
| specs/domain-spec/failure-modes.md | v1.1 | Phase-1 close | business-analyst |
| specs/domain-spec/risks.md | v1.3 | Phase-1 close | business-analyst |
| specs/domain-spec/assumptions.md | v1.3 | Phase-1 close | business-analyst |
| specs/domain-spec/differentiators.md | v1.0 | Phase-1 close | business-analyst |
| specs/domain-spec/ubiquitous-language-core.md | v1.15 | Phase-1 close | business-analyst |
| specs/domain-spec/ubiquitous-language-server.md | v1.7 | D-356 cascade | business-analyst |

## L3 PRD and Supplements

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| specs/prd.md | v1.34 | 2026-07-28 | product-owner |
| specs/prd-supplements/bc-authoring-plan.md | v2.71 | Phase-2 close | product-owner |
| specs/prd-supplements/error-taxonomy.md | v1.77 | D-356 cascade | product-owner |
| specs/prd-supplements/interface-definitions.md | v3.22 | D-356 cascade | architect |
| specs/prd-supplements/module-criticality.md | v1.8 | D-356 cascade | architect |
| specs/prd-supplements/nfr-catalog.md | v1.9 | 2026-09-01 (BC-2.04.011) | architect |
| specs/prd-supplements/observability.md | v1.11 | Phase-2 close | architect |
| specs/prd-supplements/test-vectors.md | v3.28 | D-356 cascade | product-owner |

## L3 Behavioral Contracts

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| specs/behavioral-contracts/BC-INDEX.md | v4.60 | 2026-09-10T08:00:00Z | state-manager |
| specs/behavioral-contracts/ss-NN/BC-S.SS.NNN.md (149 files) | varies | 2026-09-10 latest | product-owner |

> Individual BC body files follow BC-INDEX versioning cadence; canonical current version is the `version:` field in each file's frontmatter. The BC-INDEX §Full BC Catalog is the authoritative roster.

## L3 Architecture and ADRs

### Core Architecture Documents

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| specs/architecture/ARCH-INDEX.md | v1.96 | 2026-09-10T00:00:00Z | architect |
| specs/architecture/api-surface.md | v1.36 | D-356 cascade | architect |
| specs/architecture/dependency-graph.md | v1.15 | D-356 cascade | story-writer |
| specs/architecture/module-decomposition.md | v1.73 | D-356 cascade | architect |
| specs/architecture/purity-boundary-map.md | v1.52 | D-356 cascade | architect |
| specs/architecture/system-overview.md | v1.4 | Phase-1 close | architect |
| specs/architecture/tooling-selection.md | v1.8 | Phase-1 close | architect |
| specs/architecture/verification-architecture.md | v2.58 | D-356 cascade | architect |
| specs/architecture/verification-coverage-matrix.md | v3.50 | D-356 cascade | architect |

### Architecture Decision Records (ADR-001 through ADR-031)

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| specs/architecture/decisions/ADR-001-graph-execution-model.md | rev-5 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-002-checkpoint-format.md | v1.3 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-003-durability-tiers.md | v1.1 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-004-serde-schemars-schema-generation.md | v1.1 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md | v1.22 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-006-streaming-event-taxonomy.md | rev-6 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-007-crate-topology-sdk-split.md | v1.3 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-008-proc-macro-attributes.md | v1.2 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-009-budget-governance-placement.md | v1.3 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-010-error-taxonomy-anyhow-confinement.md | v1.21 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-011-cache-key-content-hash.md | v1.2 | Phase-1 close | architect |
| specs/architecture/decisions/ADR-012-self-improvement-primitives.md | v1.11 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-013-mcp-server-module-placement.md | v1.6 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md | v1.18 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md | v1.14 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md | v1.7 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-017-embeddings-trait-provider-integration.md | v1.7 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-018-per-tool-call-approval-hook.md | v1.7 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-019-rolling-context-compaction.md | v1.8 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-020-first-party-tool-library.md | v1.12 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-021-server-config-surface-runnable-config-configurable.md | v1.3 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-022-section-anchor-citation-convention.md | v1.3 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-023-non-exhaustive-governance.md | v1.11 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-024-writefile-create-path-confinement.md | v1.5 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-025-type-signature-canon.md | v1.5 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-026-lcel-composition-primitives-parallel-passthrough.md | v1.8 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-027-stable-bc-clause-anchors.md | v1.1 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-028-server-run-lifecycle-semantics.md | v1.0 | Phase-2 close | architect |
| specs/architecture/decisions/ADR-029-graph-agent-tool-wrapping.md | v2.20 | D-356 cascade | architect |
| specs/architecture/decisions/ADR-030-research-orchestrator-composition.md | v2.2 | 2026-09-01 | architect |
| specs/architecture/decisions/ADR-031-developer-console-architecture.md | v1.18 | D-356 cascade | architect |

## L3 Story Index

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| stories/STORY-INDEX.md | v1.98 | 2026-09-10T08:00:00Z | state-manager |
| stories/stories/STORY-NNN.md (53 files) | varies | 2026-09-10 latest | story-writer |

## L4 Verification Properties

| Artifact | Version | Last Updated | Changed By |
|----------|---------|-------------|------------|
| specs/verification-properties/VP-INDEX.md | v1.60 | 2026-09-10T00:00:00Z | architect |
| specs/verification-properties/vp-NNN*.md (43 files) | varies | 2026-09-10 latest | architect |

> VP body files VP-001 through VP-020 and VP-2.11.007-A/B and VP-2.24.001-A through VP-2.24.008-B. All status: draft (Phase-6 formal hardening not yet started). Immutability lock (verification_lock: true) not yet applied to any VP.

## Census Summary (Baseline D-359 / 2026-09-17)

| Metric | Count |
|--------|-------|
| Behavioral Contracts (BC) | 149 |
| Verification Properties (VP) | 43 |
| Error Codes (EC) | 147 |
| Test Vectors (TV) | 844 |
| Stories | 53 |
| Story Points | 377 |
| ADRs | 31 |
| Subsystems (SS) | 24 |
| Workspace Crates | 22 |
| Holdout Scenarios | 24 (must-pass 17/24 = 70.8%) |
| NFR Catalog entries | 15 |
