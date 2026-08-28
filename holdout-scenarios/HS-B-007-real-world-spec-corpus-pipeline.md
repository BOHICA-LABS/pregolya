---
document_type: holdout-scenario
level: ops
version: "1.2"
status: active
producer: product-owner
timestamp: 2026-08-19T00:00:00Z
phase: 2
domain: B
domain_name: Dark Factory / Autonomous Software Pipeline
id: HS-B-007
title: "Real-World Specification Corpus Pipeline — Known-Good and Known-Incomplete"
category: real-world-corpus
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.01.004
  - BC-2.08.003
  - BC-2.21.001
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "e14b17b"
traces_to: .factory/planning/holdout-domains/domain-b-dark-factory.md
lifecycle_status: active
introduced: v1.0.0-phase-2
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - composition
  - providers
  - retrieval
  - streaming
  - structured_output
changelog:
  - "1.2 (F-P2A114-02/round-26/2026-08-28): §Real-World Corpus Requirement: section heading renamed from '## Category: real-world-corpus' to '## Real-World Corpus Requirement' — category-neutral heading per F-P2A114-02; input-hash refreshed; changelog reordered to DESCENDING per POL-14."
  - "1.1 (F-P2A003-02, P2A-003-fix-burst, 2026-08-19): BC-linkage re-anchoring sweep — 2 BCs re-anchored in frontmatter behavioral_contracts and BC-linkage table to semantically-correct IDs verified against BC-INDEX."
  - "1.0 (initial, 2026-08-18): base scenario authored."
---

# Holdout Scenario HS-B-007: Real-World Specification Corpus Pipeline — Known-Good and Known-Incomplete

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A pipeline processes a real, publicly available specification document and produces a structured analysis report. Two corpora are used: a well-structured, complete specification (known-good), and an intentionally sparse or ambiguous specification (known-incomplete). The pipeline must complete without errors for both and correctly characterize their quality.

**Known-good corpus (tests false-positive rate):** The OpenAPI 3.1 Specification itself — the machine-readable description of the OpenAPI specification language, published as a YAML document at the OpenAPI GitHub repository. This is a thoroughly specified, professionally maintained, highly complete document. A well-functioning analysis pipeline should produce: few or zero `ambiguity` findings, a high `completeness_score`, and a verdict of `well_specified`.

Source: github.com/OAI/OpenAPI-Specification — OpenAPI 3.1.0 schema document (YAML), publicly available.

**Known-incomplete corpus (tests detection rate):** A minimal API specification stub: a hand-authored YAML document containing an API title, two endpoints with no descriptions, no response schemas defined, and no authentication spec. This is a deliberately thin specification. A well-functioning analysis pipeline should produce: multiple `ambiguity` findings (missing descriptions, undefined response schemas), a low `completeness_score`, and a verdict of `needs_refinement`.

This stub document is authored by the evaluator for the test (15–20 lines of YAML).

**Given** a pregolya-based pipeline that accepts a specification document (as text), chunks it if large, runs a structured analysis, and produces a JSON report.

**When** the pipeline is run once on each corpus.

**Then (known-good):**
1. Pipeline runs to completion without error.
2. Output report has `verdict: "well_specified"` or equivalent "passes" result.
3. `ambiguity_count` is ≤ 5 (the OpenAPI spec is authoritative; a few wording observations are acceptable, but should not flag it as poorly specified).
4. `completeness_score` ≥ 0.75.

**Then (known-incomplete):**
5. Pipeline runs to completion without error.
6. Output report has `verdict: "needs_refinement"` or equivalent "needs work" result.
7. `ambiguity_count` is ≥ 3 (at minimum the missing descriptions, undefined response schemas, and absent authentication should be flagged).
8. `completeness_score` ≤ 0.40.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.01.004 | Runnable composition processes a multi-step pipeline | Spec intake → chunking → analysis → report composition |
| BC-2.08.003 | Chat model invocation produces typed structured output | Analysis report returned as typed record |
| BC-2.08.003 | Structured output schema enforced for report fields | verdict, ambiguity_count, completeness_score all typed |
| BC-2.21.001 | Vector store retrieval returns relevant chunks | Large spec chunked and queried by analysis stage |

---

## Verification Approach

1. Download the OpenAPI 3.1.0 YAML schema from the OAI GitHub repository (public, stable URL).
2. Author a 15–20 line minimal API YAML stub (title + 2 endpoints, no descriptions, no response schemas, no auth).
3. Build a pregolya pipeline that: accepts spec text, splits into chunks if > 4K characters, runs a structured analysis query against a DTU mock provider configured to return plausible analysis results, and emits a structured report.
4. Run the pipeline on the OpenAPI spec. Assert `verdict` is a "well_specified"-class value; assert `ambiguity_count ≤ 5`; assert `completeness_score ≥ 0.75`.
5. Run the pipeline on the minimal stub. Assert `verdict` is a "needs_refinement"-class value; assert `ambiguity_count ≥ 3`; assert `completeness_score ≤ 0.40`.
6. Both runs must complete without crash.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Known-good corpus not over-flagged | 0.30 | OpenAPI spec receives well_specified verdict; ambiguity_count ≤ 5 |
| Known-incomplete corpus correctly flagged | 0.30 | Minimal stub receives needs_refinement verdict; ambiguity_count ≥ 3 |
| Completeness score calibration | 0.20 | completeness_score ≥ 0.75 for known-good; ≤ 0.40 for known-incomplete |
| Pipeline stability | 0.20 | Both runs complete without crash; large spec chunked without memory error |

**Threshold for should-pass:** weighted average ≥ 0.55.

---

## Edge Conditions

- OpenAPI spec exceeds a typical context window (it is ~800KB YAML): chunking and retrieval must handle large input without truncating or losing sections.
- Minimal stub has a valid YAML structure but no meaningful content: the pipeline must still produce a verdict rather than returning an empty or error result.

---

## Failure Guidance

"HOLDOUT LOW: HS-B-007 (satisfaction: X.XX) — pipeline either over-flagged the well-maintained OpenAPI spec as poorly specified, or failed to detect obvious gaps in the minimal stub specification."

---

## Real-World Corpus Requirement

### Corpus Details

| Field | Known-Good (OpenAPI Spec) | Known-Incomplete (Minimal Stub) |
|-------|--------------------------|----------------------------------|
| corpus_source | OAI/OpenAPI-Specification — OpenAPI 3.1.0 schema YAML (github.com/OAI/OpenAPI-Specification) | Evaluator-authored minimal API YAML stub (15–20 lines) |
| corpus_size | ~800KB YAML (~18,000 lines) | ~15–20 lines |
| known_edge_cases | Very large document; well-structured but dense; requires chunking | Missing descriptions; undefined response schemas; no authentication section |
| false_positive_threshold | ≤ 5 ambiguity findings for a professionally maintained spec | N/A |
| false_negative_threshold | N/A | ≥ 3 ambiguity findings detected for obviously sparse stub |
