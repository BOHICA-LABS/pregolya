---
document_type: behavioral-contract
level: L3
bc_id: BC-2.21.003
version: "1.1"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-21
capability: CAP-029
crate: ferrochain-vectorstores
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008, DI-014]
red_gate: true
red_gate_source: "ADR-014 v1.1 Hardening Note — zero-norm guard must be a failing test BEFORE the cosine implementation exists; a zero-norm vector silently produces NaN that corrupts similarity rankings without the guard; VP-009 Kani candidate"
vp_seed: true
vp_id: VP-009
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-21 VectorStore Abstraction; SECURITY-CRITICAL hardening per ADR-014 v1.1"
  - "1.1 (F-P224/H-4/2026-07-21): Module references corrected — `vectorstores::mmr` → `vectorstores::similarity` for cosine primitive (4 sites: Description, Architecture Anchors ×2, Traceability Module row). The `mmr` module implements the MMR selection algorithm; `cosine_similarity` lives in the dedicated `vectorstores::similarity` module with harness file `ferrochain-vectorstores/src/similarity.rs`. Genuine MMR-algorithm references in other BCs/docs are unaffected."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-029
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "01aec85"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.21.003: Zero-Norm Vector Guard — Vec<f32> Cosine Denominator Check Returns E-VS-001 Before Division (VP-009 Kani Candidate)

> **Red Gate test required** — ADR-014 v1.1 Hardening Note: the zero-norm guard test must
> COMPILE and FAIL before the cosine similarity implementation is written. A zero-length
> embedding vector (`norm == 0.0`) produces `0.0 / 0.0 = NaN` which silently corrupts
> similarity ranking — every document appears equally relevant, producing nonsense
> search results without any error signal. The guard is two lines of production code
> and must be unconditional (DI-014 — no silent NaN return). VP-009 Kani candidate:
> prove that for ALL possible Vec<f32> inputs, if `norm == 0.0` for ANY input vector,
> the cosine function returns `Err(E-VS-001)` and NEVER produces `f32::NAN` in output.

## Description

Before computing cosine similarity between two `Vec<f32>` vectors in `vectorstores::similarity`
(or any cosine call site in `ferrochain-vectorstores`), the implementation computes the
L2 norm of each vector:

```rust
let norm = v.iter().map(|x| x * x).sum::<f32>().sqrt();
if norm == 0.0 {
    return Err(FerrochainError { component: Component::VS, category: Category::VALIDATION,
                                 code: "E-VS-001", message: "zero-norm embedding vector" });
}
```

This check fires for BOTH the query vector and each document vector before division. It is
unconditional — no `#[cfg(debug_assertions)]`, no feature flag, no opt-out. The check costs
two lines and has negligible performance overhead compared to the cosine computation itself.

## Preconditions

1. The `cosine_similarity(a: &[f32], b: &[f32]) → Result<f32, FerrochainError>` function
   (or equivalent) is called with vectors `a` and `b`.
2. At least one of `a` or `b` has L2 norm equal to `0.0` (all elements are `0.0`, or
   the vector is effectively all-zero due to floating-point underflow to zero).

## Postconditions

1. When `norm_a == 0.0` OR `norm_b == 0.0`:
   ```
   Err(FerrochainError {
       component: Component::VS,
       category: Category::VALIDATION,
       code: "E-VS-001",
       message: "zero-norm embedding vector",
   })
   ```
2. The division `dot_product / (norm_a * norm_b)` is NEVER reached when either norm is zero.
   The guard fires before division; `f32::NAN` is never produced in cosine output.
3. The error propagates via `?` to `similarity_search`, `similarity_search_with_score`, and
   `max_marginal_relevance_search` — callers receive `Err(E-VS-001)` (DI-014 — no silent
   fallthrough to `0.0` or `Vec::new()`).
4. When both norms are non-zero, the guard is a no-op and cosine computation proceeds normally.
5. The output cosine value for non-zero vectors is in `[-1.0, 1.0]` — a property verified
   by VP-009's proptest harness.

## Invariants

1. The guard is **the first operation** in `cosine_similarity` — it cannot be reordered below
   the dot product computation or any other step.
2. The guard checks BOTH vectors independently — a zero-norm query vector and a zero-norm
   document vector both trigger `Err(E-VS-001)`.
3. **No `NaN` in any output path** — `f32::NAN` never appears in `Vec<(Document, f32)>` score
   results returned by any VectorStore method.
4. The `"zero-norm embedding vector"` message text is fixed (no `<placeholder>` interpolation
   per gate #33 STRUCT-PLACEHOLDER PARITY — the message contains no dynamic data).
5. `norm == 0.0` is checked with exact IEEE-754 equality (not `norm < f32::EPSILON`) because
   the NaN condition is specifically `0.0 / 0.0`. A near-zero norm (e.g., `1e-40`) does not
   produce NaN (it produces a very large value, which is a different problem). The guard
   targets the NaN production path specifically.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Query vector is all-zero `vec![0.0f32; 768]` | `Err(E-VS-001)` — zero-norm query detected before any doc comparison |
| EC-002 | One document vector in the store is all-zero | `Err(E-VS-001)` when that document is compared; search fails rather than returning NaN score |
| EC-003 | Both query and document vectors are non-zero | Guard is no-op; cosine proceeds; result ∈ [-1.0, 1.0] |
| EC-004 | Vector with `vec![0.0f32; 0]` (empty vector) | `norm = 0.0`; `Err(E-VS-001)` — empty vector has norm 0 |
| EC-005 | Vector where all elements are sub-normal floats that sum to exactly 0.0 | `Err(E-VS-001)` — IEEE-754 sum is 0.0; guard fires |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 (Red Gate) | `cosine_similarity(&vec![0.0f32; 768], &vec![1.0f32; 768])` | `Err(E-VS-001)` — zero-norm query vector | error-case (Red Gate) |
| TV-002 (Red Gate) | `cosine_similarity(&vec![1.0f32; 768], &vec![0.0f32; 768])` | `Err(E-VS-001)` — zero-norm document vector | error-case (Red Gate) |
| TV-003 | `cosine_similarity(&vec![1.0, 0.0, 0.0], &vec![0.0, 1.0, 0.0])` | `Ok(0.0)` — orthogonal vectors; cosine = 0 | happy-path (valid vectors) |
| TV-004 | `cosine_similarity(&vec![1.0, 0.0, 0.0], &vec![1.0, 0.0, 0.0])` | `Ok(1.0)` — identical vectors; cosine = 1 | happy-path (identical) |
| TV-005 | `cosine_similarity(&vec![1.0, 0.0, 0.0], &vec![-1.0, 0.0, 0.0])` | `Ok(-1.0)` — opposite vectors; cosine = -1 | happy-path (anti-parallel) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.21.003-A (VP-009 candidate) | For ALL possible `Vec<f32>` pairs, if either has norm == 0.0, `cosine_similarity` returns `Err(E-VS-001)` and NEVER returns `Ok(f32::NAN)` | proptest (random inputs including zero vectors) + Kani VP-009 formal proof: enumerate all reachable code paths; prove `Ok(f32::NAN)` is unreachable |
| VP-2.21.003-B | For ALL non-zero Vec<f32> pairs, `cosine_similarity` result is in [-1.0, 1.0] | proptest — random non-zero pairs; assert -1.0 ≤ result ≤ 1.0 |
| VP-2.21.003-C | MMR output scores in `max_marginal_relevance_search` are monotonically non-increasing (diversity selection preserves relevance ordering) | proptest — assert MMR results are ordered by marginal relevance at each step |

## Related BCs

- BC-2.21.002 — composes with: InMemoryVectorStore calls cosine_similarity in similarity_search; zero-norm guard is part of InMemoryVectorStore's cosine path
- BC-2.21.001 — composes with: all VectorStore trait methods that compute similarity invoke cosine_similarity; this guard applies to all such invocations

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-21, `vectorstores::similarity` module (cosine_similarity pure-core function; harness file `ferrochain-vectorstores/src/similarity.rs`)
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 §Hardening note (zero-norm guard specification, E-VS-001 error, VP-009 candidacy note)
- `architecture/purity-boundary-map.md` — `vectorstores::similarity` Pure Core; Kani VP-009 candidacy noted

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-21 security-hardening story]_

## VP Anchors

- VP-2.21.003-A (pending VP-009 registration in VP-INDEX.md)
- VP-2.21.003-B
- VP-2.21.003-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-029 |
| Capability Anchor Justification | CAP-029 ("InMemoryVectorStore — Arc<dyn Embeddings> DI; RwLock Interior Mutability; Vec<f32> Cosine; E-VS-001 Zero-Norm Guard") per capabilities-p1-p2.md §CAP-029 — the "E-VS-001 Zero-Norm Guard" in the CAP title is exactly the property this BC specifies; CAP-029 calls it out as a mandatory hardening obligation for the Vec<f32> cosine path and notes the VP-009 connection explicitly |
| L2 Domain Invariants | DI-008 (cosine_similarity returns Result; no .unwrap() on cosine computation), DI-014 (E-VS-001 propagates as Err; no silent NaN or 0.0 fallthrough — cosine_similarity never returns Ok(f32::NAN)) |
| Architecture Authority | ADR-014 v1.1 §Hardening Note (zero-norm guard specification, E-VS-001, VP-009 candidacy) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| VP Registration | VP-009 (ARCH-INDEX candidate — architect assigns VP-INDEX entry after BC authoring completes) |
| Module | ferrochain-vectorstores / vectorstores::similarity |
| Priority | P0 |
| Wave | 2 |
| Test Types | unit (Red Gate) + proptest + Kani (VP-009 candidate) |
