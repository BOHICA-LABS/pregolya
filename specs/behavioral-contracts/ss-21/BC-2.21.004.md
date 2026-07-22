---
document_type: behavioral-contract
level: L3
bc_id: BC-2.21.004
version: "1.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-21
capability: CAP-030
crate: ferrochain-vectorstores
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008, DI-014]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-21 VectorStore Abstraction"
  - "1.1 (F-P130-04/2026-07-21): Add DI-014 to di_anchors — PC8 already cited DI-014 in body ('empty result is valid; it is not silently replaced with unfiltered results'); frontmatter anchor was missing."
  - "1.2 (burst-226/F-P131-07/2026-07-21): INV-3 fail-safe default — default similarity_search_with_filter returns Err(E-VS-005 FilterUnsupported) on non-empty filter; empty filter (vacuously true) still delegates to similarity_search. Removes lossy fallback language. EC-005 updated: non-overriding adapter returns Err(E-VS-005), not lossy result. Per ADR-014 v1.5 Decision 2 F-P131-07 adjudication."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-030
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "4415e51"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.21.004: MetadataFilter — Eq / Ne / In FilterClause; Additive similarity_search_with_filter; Native Pre-Filter vs InMemoryVectorStore Post-Filter; #[non_exhaustive]

## Description

`MetadataFilter { filters: Vec<FilterClause> }` is an optional parameter type for metadata-based
filtering in VectorStore searches. `FilterClause` has three variants: `Eq { key, value }`,
`Ne { key, value }`, and `In { key, values }`. The filter is surfaced via an additive method
`similarity_search_with_filter(&self, query, k, filter: MetadataFilter) → Result<Vec<Document>>`
on the `VectorStore` trait — it does NOT replace or modify the base `similarity_search` method.
VectorStore implementations with native backend support apply the filter as a server-side
pre-filter before vector similarity computation; `InMemoryVectorStore` applies it as a
post-filter on the similarity result set. Both `MetadataFilter` and `FilterClause` are
`#[non_exhaustive]` to permit new clause variants without breaking downstream match arms.

## Preconditions

1. A `MetadataFilter` is constructed with at least one `FilterClause`.
2. `similarity_search_with_filter` is called on a `&dyn VectorStore` that implements this
   optional method.
3. Each `FilterClause` clause references a `key` that may or may not exist in a `Document`'s
   `metadata` map.

## Postconditions

1. `FilterClause::Eq { key, value }` — document PASSES the clause iff
   `doc.metadata.get(key) == Some(&value)`. Document FAILS if the key is absent or the value
   does not match.
2. `FilterClause::Ne { key, value }` — document PASSES iff
   `doc.metadata.get(key) != Some(&value)`. Document PASSES if the key is absent (absence ≠ value).
3. `FilterClause::In { key, values }` — document PASSES iff
   `doc.metadata.get(key)` maps to a value contained in `values`. Document FAILS if the key
   is absent or the value is not in `values`.
4. Multiple `FilterClause` entries in `MetadataFilter.filters` are evaluated as logical AND —
   a document must pass ALL clauses to be included in the result.
5. `similarity_search_with_filter(query, k, filter)` returns `Ok(docs)` where each `doc`
   satisfies all filter clauses. The result set contains at most `k` documents.
6. **InMemoryVectorStore post-filter behavior:** the store first computes similarity search
   over ALL documents (up to some internal fetch limit), then applies the filter, then returns
   the top-k from the filtered set. The base `similarity_search` contract is NOT modified.
7. **Native-backend pre-filter behavior:** community adapters (Chroma, Qdrant, etc.) that
   support server-side filtering pass the `MetadataFilter` to the backend before vector
   similarity computation. Result correctness is the adapter's responsibility; the BC specifies
   the filter semantics, not the query translation.
8. `similarity_search_with_filter` returning `Ok(vec![])` is NOT an error when no documents
   match the filter (DI-014 — empty result is valid; it is not silently replaced with
   unfiltered results).

## Invariants

1. `MetadataFilter` and `FilterClause` are BOTH `#[non_exhaustive]`. External match arms on
   `FilterClause` variants MUST include `_ =>` wildcard. This allows adding `Gte`, `Lt`,
   `Contains` variants in future minor versions without breaking existing implementations.
2. `similarity_search_with_filter` is an **additional** method on `VectorStore` — it does NOT
   override or shadow `similarity_search`. Both methods coexist; callers choose which to call.
3. The default implementation returns `Err(E-VS-005 FilterUnsupported)` when `filter.filters` is non-empty. This is a fail-safe default — silently returning unfiltered results as if filtering occurred would be a cross-tenant-exposure hazard. An empty `MetadataFilter` (`filter.filters.is_empty()`) is vacuously true; the default delegates to `similarity_search(query, k)` in that case (EC-004 semantics preserved). Adapters that support native metadata filtering MUST override this method with a native implementation.
4. A `MetadataFilter` with `filters: vec![]` (empty filter) is equivalent to no filter — all
   documents pass a zero-clause AND conjunction (vacuously true).
5. Filter evaluation is exact match using `serde_json::Value`'s `PartialEq` — no type coercion,
   no case folding, no `"42" == 42` equivalence.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `FilterClause::Eq` with a key absent from the document's metadata | Document FAILS the clause (absent key ≠ any value) |
| EC-002 | `FilterClause::Ne` with a key absent from the document's metadata | Document PASSES the clause (absent key is Not Equal to any value) |
| EC-003 | `FilterClause::In` with empty `values` vec | Document FAILS (nothing is "in" an empty set) |
| EC-004 | `MetadataFilter { filters: vec![] }` (empty filter) | All documents pass; result is equivalent to `similarity_search(query, k)` |
| EC-005 | `similarity_search_with_filter` called with a non-empty filter on a backend that has NOT overridden this method | Default impl returns `Err(E-VS-005 FilterUnsupported)` — fail-safe; does NOT silently return unfiltered results |
| EC-006 | Filter narrows result set to 0 documents | `Ok(vec![])` — empty result; NOT silently replaced with unfiltered results |
| EC-007 | Two `Eq` clauses for the same `key` but different values | Document must satisfy BOTH (logical AND) — impossible for a single-valued key; result is always `Ok(vec![])` |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | Store with docs `[{source: "A"}, {source: "B"}]`; filter `Eq { key: "source", value: "A" }` | `Ok(vec![doc_A])` — only doc with source=A | happy-path (Eq filter) |
| TV-002 | Same store; filter `Ne { key: "source", value: "A" }` | `Ok(vec![doc_B])` — doc with source≠A | happy-path (Ne filter) |
| TV-003 | Store with docs `[{category: "X"}, {category: "Y"}, {category: "Z"}]`; filter `In { key: "category", values: ["X", "Z"] }` | `Ok(vec![doc_X, doc_Z])` | happy-path (In filter) |
| TV-004 | Store with doc `{source: "A"}`; filter `Eq { key: "source", value: "A" }` AND `Eq { key: "category", value: "news" }` (AND conjunction) | `Ok(vec![])` — doc has source=A but no category field | edge-case (AND with absent key) |
| TV-005 | `MetadataFilter { filters: vec![] }` → `similarity_search_with_filter("query", 3, empty_filter)` | `Ok(top_3_docs)` — same as similarity_search | edge-case (empty filter) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.21.004-A | `FilterClause::Eq` predicate is consistent: `doc.metadata[key] == value ↔ passes` | unit test — table-driven across all `serde_json::Value` variants |
| VP-2.21.004-B | Empty filter (`filters: vec![]`) produces same result as unfiltered `similarity_search` | unit test — call both; assert identical result sets |
| VP-2.21.004-C | `FilterClause` and `MetadataFilter` are `#[non_exhaustive]` | compile-fail test in `tests/external/metadata-filter-non-exhaustive/` |

## Related BCs

- BC-2.21.001 — composes with: `similarity_search_with_filter` is an optional method on the VectorStore trait defined in BC-2.21.001
- BC-2.21.002 — composes with: InMemoryVectorStore implements the post-filter behavior specified here

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-21, `vectorstores::filter` sub-module
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 §Metadata filter surface (MetadataFilter struct, FilterClause enum, additive method, pre vs post filter semantics, #[non_exhaustive])

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-21 story]_

## VP Anchors

- VP-2.21.004-A, VP-2.21.004-B, VP-2.21.004-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-030 |
| Capability Anchor Justification | CAP-030 ("MetadataFilter — Eq / Ne / In Clause Filtering on Document Metadata During Search") per capabilities-p1-p2.md §CAP-030 — this BC specifies the MetadataFilter and FilterClause types (Eq/Ne/In), the additive similarity_search_with_filter method, and the pre-filter/post-filter behavioral split that CAP-030 identifies as a distinct capability axis from the base VectorStore contract |
| L2 Domain Invariants | DI-008 (similarity_search_with_filter returns Result; no .unwrap()), DI-014 (empty filter result `Ok(vec![])` is valid; NOT silently replaced with unfiltered results — per PC8 and EC-006) |
| Architecture Authority | ADR-014 Decision 2 §Metadata filter surface (MetadataFilter struct, FilterClause variants, additive method, pre vs post filter, #[non_exhaustive]) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-vectorstores / vectorstores::filter |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + compile-fail (#[non_exhaustive] gate) |
