---
document_type: behavioral-contract
level: L3
bc_id: BC-2.20.002
version: "1.4"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-20
capability: CAP-026
crate: ferrochain-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-012, DI-014]
red_gate: true
red_gate_source: "ADR-014 Decision 2 Consequences §DI-012 — 'documents returned by Retriever::get_relevant_documents enter the graph context as BoundaryType::RAGRetrieval'; guardrail coverage test must COMPILE and FAIL before any graph node wires Arc<dyn Retriever>"
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-20 Document Retrieval; SECURITY MANDATORY per architect handoff"
  - "1.1 (F-P224/H-3/2026-07-21): VP-2.20.002-A replaced with typed-wrapper specification per architect handoff (H-5 from F-P129-08). Old VP was non-mechanizable ('code review + unit test per graph node'). New VP: graph nodes accept `&GuardedDocuments`; passing `Vec<Document>` directly is a compile-time type error enforced by the type system (ADR-014 Decision 6 / purity-boundary-map). Red Gate = compile_fail test."
  - "1.2 (F-P130-02/F-P130-04/2026-07-21): (1) Replace 3 nonexistent `ferrochain-guardrail` crate references with canonical `ferrochain-core: core::guardrail` per ADR-014 v1.4 PO Obligations. (2) Add DI-014 to di_anchors — PC2/PC4 and EC-002 already cite DI-014 in body; frontmatter was missing the anchor."
  - "1.3 (burst-226/F-P131-01/2026-07-21): PC2 updated per ADR-014 v1.5 severity-bifurcated Fail semantics: Critical Fail → Err(E-CORE-008) propagated, run failed; Non-Critical Fail → error-entry Document substituted at position, batch continues. VP-2.20.002-B scope narrowed to Critical path only. EC-002 updated to reflect Critical-only abort semantics."
  - "1.4 (F-P149-02/burst-250/2026-07-24): PC2 version pin de-pinned: 'ADR-014 v1.5' → 'ADR-014 Decision 6 §GuardedDocuments' (TD-VSDD-091 stable-anchor enforcement, F-P149-02). input-hash updated to 1b115d2 (drift from burst-226 ADR-014 content changes)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-026
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-012
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "46c445f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.20.002: BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns Entering Graph Context (DI-012 Coverage Obligation)

> **Red Gate test required** — ADR-014 Consequences §DI-012: the guardrail coverage
> test must COMPILE and FAIL before any graph node implementation wires
> `Arc<dyn Retriever>`. This BC does NOT redefine `BoundaryType::RAGRetrieval`
> (that is BC-2.11.001 territory). This BC asserts the **coverage obligation**:
> every document vector returned by `get_relevant_documents` that enters graph
> context is a RAGRetrieval ingress point and must be gated by the existing
> guardrail.

## Description

When a graph node calls `Retriever::get_relevant_documents` and uses the returned
`Vec<Document>` as graph context (e.g., constructs an `HumanMessage` from page content,
appends to a conversation window, or feeds into an LLM chain), each document crosses
the `BoundaryType::RAGRetrieval` ingress boundary defined in BC-2.11.001. The existing
`BoundaryType::RAGRetrieval` variant in `ferrochain-core: core::guardrail` already covers this seam
— no new variant, trait, or guardrail is introduced by this BC. This BC asserts that the
implementation of every graph node that injects retrieved documents into the prompt or
context MUST pass those documents through the guardrail before use. The DI-012 invariant
("guardrail at ingress boundaries") requires this unconditionally.

## Preconditions

1. `BoundaryType::RAGRetrieval` exists in `ferrochain-core: core::guardrail`
   (defined in BC-2.11.001).
2. A graph node holds `Arc<dyn Retriever>` and calls `get_relevant_documents`.
3. The `Ok(docs)` result is about to be consumed as prompt content, context, or any
   form of LLM input.

## Postconditions

1. Before any `Doc.page_content` is incorporated into an `HumanMessage`, `SystemMessage`,
   chat history window, or any other graph-context structure, the graph node MUST call
   the guardrail with `boundary_type: BoundaryType::RAGRetrieval`.
2. The guardrail Fail arm is severity-bifurcated (ADR-014 Decision 6 §GuardedDocuments):
   - `GuardrailSeverity::Critical` Fail → `GuardedDocuments::rag_ingress` returns `Err(E-CORE-008 GuardrailCriticalRejection)`. The graph node propagates the error via `?`; no `GuardedDocuments` is produced; the run transitions to `failed` state.
   - Non-Critical Fail (High/Medium/Low) → error-entry Document substituted at the rejected document's position (with `page_content: "[GUARDRAIL BLOCKED: <reason>]"`, `metadata.ferrochain.guardrail_blocked: true`); batch continues; `GuardedDocuments` is eventually produced containing the error-entry substitution.
   DI-014 applies to the Critical path only — non-critical continuation is explicit batch behavior, not silent error swallowing.
3. The guardrail call occurs BEFORE the document content is used for any purpose in the
   graph context. There is no deferred check or "check at final boundary" alternative
   (DI-012 — guardrail at ingress, not egress).
4. Documents that fail the guardrail do NOT enter the prompt under any condition, including
   partial failure (DI-014 — no `Vec::new()` fallback that silently drops failing documents).

## Invariants

1. This BC does NOT extend or modify `BoundaryType::RAGRetrieval`. The existing variant
   defined in BC-2.11.001 is used verbatim — no subtype, no new boundary variant.
2. The coverage obligation applies to ALL Retriever implementations — `VectorStoreRetriever`,
   custom in-memory retrievers, and community adapters. The obligation is on the graph
   node caller, not on the Retriever implementation.
3. The obligation applies regardless of the document's provenance — even an in-process
   in-memory retriever returns externally ingested content and must be treated as a
   RAGRetrieval boundary.
4. This guardrail is synchronous with respect to the graph execution — it is called in the
   same async task, not deferred to a background check.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Graph node receives empty `Vec<Document>` from retriever | No guardrail call needed (no content to gate); node continues; `Vec::new()` return of zero documents is NOT a policy violation |
| EC-002 | Graph node passes 10 documents to `rag_ingress`; guardrail returns Critical Fail for document at position 3 | `rag_ingress` returns `Err(E-CORE-008)`; graph node propagates via `?`; no `GuardedDocuments` returned; documents 0–2 and 4–9 are NOT accessible |
| EC-003 | Graph node uses `doc.metadata` (not `doc.page_content`) in context | Metadata entering graph context is ALSO gated — RAGRetrieval boundary covers the full Document, not only page_content |
| EC-004 | Graph node stores retrieved documents in a MemoryStore (not directly in prompt) | MemoryStore write is a separate boundary (ADR-012 write guard); RAGRetrieval guardrail still applies to the retrieval ingress; both checks run |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 (Red Gate) | Graph node calls `get_relevant_documents`; skips guardrail; attempts to use doc.page_content as message content | Test compiles and FAILS — the guardrail call is missing; Red Gate: test must fail before implementation adds the guardrail call | error-case (missing guardrail — Red Gate) |
| TV-002 | Graph node calls guardrail with `BoundaryType::RAGRetrieval` and doc content; guardrail returns `Ok(())` | Node proceeds; doc content is used in context | happy-path (guardrail passes) |
| TV-003 | Graph node calls guardrail; guardrail returns `Err(policy_violation)` | Node propagates `Err`; doc content is NOT used; no fallback to alternative content | error-case (guardrail blocks) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.20.002-A | Graph nodes that consume RAG output accept `&GuardedDocuments`; passing `Vec<Document>` directly is a compile-time type error enforced by the type system (ADR-014 Decision 6 / purity-boundary-map) | `compile_fail` test verifying `fn inject_context(docs: Vec<Document>)` does not satisfy the required `fn inject_context(docs: &GuardedDocuments)` signature — the type system enforces the guardrail boundary statically |
| VP-2.20.002-B | Critical-severity guardrail Fail propagates as `Err(E-CORE-008)` — no `GuardedDocuments` produced on Critical path | unit test — mock guardrail returns Critical Fail; assert Err(E-CORE-008) returned and no GuardedDocuments accessible |

## Related BCs

- BC-2.11.001 — depends on: the BoundaryType::RAGRetrieval variant this BC asserts coverage for is defined in BC-2.11.001; this BC does NOT supersede or modify it
- BC-2.20.001 — composes with: the Retriever::get_relevant_documents returns that trigger this BC's coverage obligation
- BC-2.20.003 — composes with: VectorStoreRetriever is a specific Retriever impl; this coverage obligation applies to its callers

## Architecture Anchors

- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 Consequences §DI-012 (RAGRetrieval guardrail coverage confirmation)
- `architecture/decisions/ADR-012-*.md` / BC-2.11.001 — BoundaryType::RAGRetrieval origin and definition (DO NOT modify)
- `architecture/purity-boundary-map.md` — `ferrochain-core: core::guardrail` guardrail boundary enforcement

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-20 security story]_

## VP Anchors

- VP-2.20.002-A, VP-2.20.002-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-026 |
| Capability Anchor Justification | CAP-026 ("Retriever Trait — get_relevant_documents; Arc<dyn Retriever> Seam; DI-012 RAGRetrieval Guardrail Coverage") per capabilities-p1-p2.md §CAP-026 — the DI-012 RAGRetrieval Guardrail Coverage component of CAP-026 is the exact obligation this BC formalizes; CAP-026 explicitly states that all Documents entering graph context via any Retriever pass BoundaryType::RAGRetrieval |
| L2 Domain Invariants | DI-012 (guardrail at ingress boundaries — RAGRetrieval boundary applies to all documents entering graph context from a Retriever, regardless of Retriever backend), DI-014 (no silent error swallowing — guardrail failures propagate via `?`, no `Vec::new()` fallback that drops failing documents) |
| Architecture Authority | ADR-014 Decision 2 Consequences §DI-012 |
| Cross-Reference | BC-2.11.001 (authority for BoundaryType::RAGRetrieval definition — this BC references, does not redefine) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-core / core::retriever (trait); ferrochain-graph / graph-nodes (obligation falls on callers) |
| Priority | P0 |
| Wave | 2 |
| Test Types | unit (Red Gate — guardrail-presence test per graph node) |
