---
document_type: behavioral-contract
level: L3
bc_id: BC-2.21.003
version: "1.9"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-21
capability: CAP-029
crate: pregolya-vectorstores
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
di_anchors: [DI-008, DI-014]
red_gate: true
red_gate_source: "ADR-014 Decision 2 §Hardening note — zero-norm guard must be a failing test BEFORE the cosine implementation exists; a zero-norm vector silently produces NaN that corrupts similarity rankings without the guard; VP-009 Kani candidate"
vp_seed: true
vp_id: VP-009
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-21 VectorStore Abstraction; SECURITY-CRITICAL hardening per ADR-014 v1.1"
  - "1.1 (F-P224/H-4/2026-07-21): Module references corrected — `vectorstores::mmr` → `vectorstores::similarity` for cosine primitive (4 sites: Description, Architecture Anchors ×2, Traceability Module row). The `mmr` module implements the MMR selection algorithm; `cosine_similarity` lives in the dedicated `vectorstores::similarity` module with harness file `pregolya-vectorstores/src/similarity.rs`. Genuine MMR-algorithm references in other BCs/docs are unaffected."
  - "1.2 (burst-238/sweep/2026-07-23): VP Registration (Traceability) and VP Anchors section updated: stale 'ARCH-INDEX candidate — architect assigns VP-INDEX entry after BC authoring completes' and 'pending VP-009 registration in VP-INDEX.md' replaced with 'assigned in VP-INDEX v1.2 as VP-009' (VP-INDEX v1.2 burst-223 seeded VP-009 Kani P0; VP-009.md exists). Completed-handoff residue removal."
  - "1.3 (F-P148-02/burst-249/2026-07-24): De-pinned all three 'ADR-014 v1.1 [§]Hardening Note' sites to 'ADR-014 Decision 2 §Hardening note' per ADR-014 v1.4 labeled anchor: (1) frontmatter red_gate_source, (2) Red Gate body callout, (3) Traceability Architecture Authority row."
  - "1.4 (OBS-P149-01/burst-250/2026-07-24): PC5 VP attribution corrected: 'VP-009's proptest harness' → 'BC-local proptest sub-property VP-2.21.003-B'. VP-009 is the Kani formal-proof VP for the NaN guard (VP-2.21.003-A); the [-1,1] range property is covered by the BC-local proptest VP-2.21.003-B. input-hash updated dda4aa1→1b115d2 (drift from burst-249 ADR-014 content changes)."
  - "1.5 (FIX-BURST-269/F-P167-01/2026-07-25): Fix Category::VALIDATION → Category::VAL at two sites: Description code block (E-VS-001 return inside if-guard) and PC-1 code block (E-VS-001 Err struct). VALIDATION is not in the canonical 12-member Category enum; E-VS-001 is VAL per error-taxonomy.md §E-VS-001. D23 sibling-sweep."
  - "1.6 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B) at 3 sites: Component::VS → Component::Vs (Description code block + PC-1 code block), Category::VAL → Category::Val (Description code block + PC-1 code block, 2 occurrences)."
  - "1.7 (FIX-BURST-276/F-P173-503/2026-07-27): Amend Invariant 3 and Invariant 5 to specify the two-part NaN guard covering both the zero-norm path and the overflow-to-infinity path. Guard condition: `norm == 0.0 || !norm.is_finite()` — zero-norm guard alone is unsatisfiable: individually finite elements (e.g., magnitude ~1e20f32) produce `Σ xᵢ² = +Inf`; `sqrt(+Inf) = +Inf`; `Inf/Inf = NaN`; the zero-norm guard does not fire because norm is +Inf, not 0.0. `kani::assume(x.is_finite())` does NOT prevent this. Aligns BC with VP-009 v1.6 formal invariant and `overflow_norm_triggers_guard` harness. Coherence sweep: Description code block (`if norm == 0.0` → `if norm == 0.0 || !norm.is_finite()`), Red Gate VP callout last sentence, PC-2 (added overflow precondition arm), PostC-1 (full guard condition), PostC-2 (zero OR infinite), PostC-4 (finite and non-zero), PostC-5 (finite non-zero), EC-003 (finite and non-zero), EC-006 added (overflow case), TV-006 added (f32::MAX overflow vector). TV census: 6 canonical (was 5) + 0 GTV = 6 BC-local TVs; project total 675 (664 canonical + 11 GTV)."
  - "1.8 (fix-burst-276/2026-07-27): Propagate E-VS-001 message widening (error-taxonomy.md v1.45, same burst). Human decision: rename conceptual variant ZeroNormEmbedding → DegenerateNormEmbedding; widen STATIC message from 'zero-norm embedding vector' → 'degenerate-norm embedding vector: norm is zero or non-finite'. Three live message-text sites updated: (1) Description code block `message:` field, (2) PC-1 code block `message:` field, (3) Invariant 4 message-text citation. The old message implied zero-norm-only and misdescribed the overflow arm now covered by the v1.7 guard. No guard condition, BC title, BC code, or BC priority changed; Invariant 4 semantics (STATIC, no placeholder) unchanged — only the quoted message string updated."
  - "1.9 (FIX-BURST-278-WAVE-C/D-42-S5-gate/2026-07-28): S5 gate closure — two fence-scoped PregolyaError struct literals (Description rust fence + PC-1 postcondition fence, both missing retry_hint, source fields) → PregolyaError::new(Component::Vs, Category::Val, RetryHint::Never, \"E-VS-001\", msg) constructor form per D-42 canonical ctor. RetryHint::Never: VAL category default per error-taxonomy.md §E-VS-001. Verifiable: grep 'PregolyaError {' specs/behavioral-contracts/ss-21/BC-2.21.003.md returns zero fence-scoped literal occurrences after this edit."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-029
  - architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "d4c75fa"
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

> **Red Gate test required** — ADR-014 Decision 2 §Hardening note: the zero-norm guard test must
> COMPILE and FAIL before the cosine similarity implementation is written. A zero-length
> embedding vector (`norm == 0.0`) produces `0.0 / 0.0 = NaN` which silently corrupts
> similarity ranking — every document appears equally relevant, producing nonsense
> search results without any error signal. The guard is two lines of production code
> and must be unconditional (DI-014 — no silent NaN return). VP-009 Kani candidate:
> prove that for ALL possible Vec<f32> inputs with finite elements, if `norm == 0.0 || !norm.is_finite()`
> for ANY input vector (covering both the all-zero path and the sum-of-squares overflow-to-infinity
> path), the cosine function returns `Err(E-VS-001)` and NEVER produces `f32::NAN` in output.

## Description

Before computing cosine similarity between two `Vec<f32>` vectors in `vectorstores::similarity`
(or any cosine call site in `pregolya-vectorstores`), the implementation computes the
L2 norm of each vector:

```rust
let norm = v.iter().map(|x| x * x).sum::<f32>().sqrt();
if norm == 0.0 || !norm.is_finite() {
    return Err(PregolyaError::new(
        Component::Vs,
        Category::Val,
        RetryHint::Never,
        "E-VS-001",
        "degenerate-norm embedding vector: norm is zero or non-finite",
    ));
}
```

This check fires for BOTH the query vector and each document vector before division. It is
unconditional — no `#[cfg(debug_assertions)]`, no feature flag, no opt-out. The check costs
two lines and has negligible performance overhead compared to the cosine computation itself.

## Preconditions

1. The `cosine_similarity(a: &[f32], b: &[f32]) → Result<f32, PregolyaError>` function
   (or equivalent) is called with vectors `a` and `b`.
2. At least one of `a` or `b` has a degenerate L2 norm: either `norm == 0.0` (all elements
   are `0.0`, or the vector is effectively all-zero due to floating-point underflow to zero)
   OR `!norm.is_finite()` (individually finite elements whose sum-of-squares overflows
   `f32::MAX`, producing `norm = +Inf`).

## Postconditions

1. When `norm_a == 0.0 || !norm_a.is_finite()` OR `norm_b == 0.0 || !norm_b.is_finite()`
   (covers both the all-zero path and the sum-of-squares overflow-to-infinity path):
   ```
   Err(PregolyaError::new(
       Component::Vs,
       Category::Val,
       RetryHint::Never,
       "E-VS-001",
       "degenerate-norm embedding vector: norm is zero or non-finite",
   ))
   ```
2. The division `dot_product / (norm_a * norm_b)` is NEVER reached when either norm is
   degenerate (zero or infinite). The guard fires before division; `f32::NAN` is never
   produced in cosine output.
3. The error propagates via `?` to `similarity_search`, `similarity_search_with_score`, and
   `max_marginal_relevance_search` — callers receive `Err(E-VS-001)` (DI-014 — no silent
   fallthrough to `0.0` or `Vec::new()`).
4. When both norms are finite and non-zero, the guard is a no-op and cosine computation proceeds normally.
5. The output cosine value for finite non-zero vectors is in `[-1.0, 1.0]` — a property
   verified by BC-local proptest sub-property VP-2.21.003-B.

## Invariants

1. The guard is **the first operation** in `cosine_similarity` — it cannot be reordered below
   the dot product computation or any other step.
2. The guard checks BOTH vectors independently — a zero-norm query vector and a zero-norm
   document vector both trigger `Err(E-VS-001)`.
3. **No `NaN` in any output path.** Guard condition: `norm == 0.0 || !norm.is_finite()` —
   covers both the zero-norm path and the overflow-to-infinity path. Overflow mechanism:
   individually finite elements (e.g., elements of magnitude ~1e20f32) can produce
   `Σ xᵢ² = +Inf` during squared-norm computation; `sqrt(+Inf) = +Inf`; `dot(a,b) /
   (Inf * Inf) = NaN`. `kani::assume(x.is_finite())` does NOT prevent this: a finite element
   can square to `+Inf` during the sum-of-squares step. The overflow guard requires
   `!norm.is_finite()` tested after norm computation, not element-wise finiteness before it.
   `f32::NAN` never appears in `Vec<(Document, f32)>` score results returned by any VectorStore method.
4. The `"degenerate-norm embedding vector: norm is zero or non-finite"` message text is fixed
   (no `<placeholder>` interpolation per gate #33 STRUCT-PLACEHOLDER PARITY — the message
   contains no dynamic data; the guard condition is invariant for all degenerate-norm inputs).
5. `norm == 0.0` is checked with exact IEEE-754 equality (not `norm < f32::EPSILON`) because
   the NaN condition for the all-zero path is specifically `0.0 / 0.0`. A near-zero norm
   (e.g., `1e-40`) does not produce NaN from division (it produces a very large cosine value,
   which is a different problem). The overflow arm `!norm.is_finite()` catches the complementary
   case: individually finite elements whose sum-of-squares overflows to `+Inf`, yielding
   `norm = +Inf` rather than `0.0`; `Inf / Inf = NaN` on division. The combined guard
   `norm == 0.0 || !norm.is_finite()` precisely targets the two norm-value classes that produce
   NaN on division, without incorrectly triggering on near-zero (legitimate but large cosine)
   inputs.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Query vector is all-zero `vec![0.0f32; 768]` | `Err(E-VS-001)` — zero-norm query detected before any doc comparison |
| EC-002 | One document vector in the store is all-zero | `Err(E-VS-001)` when that document is compared; search fails rather than returning NaN score |
| EC-003 | Both query and document vectors are finite and non-zero | Guard is no-op; cosine proceeds; result ∈ [-1.0, 1.0] |
| EC-004 | Vector with `vec![0.0f32; 0]` (empty vector) | `norm = 0.0`; `Err(E-VS-001)` — empty vector has norm 0 |
| EC-005 | Vector where all elements are sub-normal floats that sum to exactly 0.0 | `Err(E-VS-001)` — IEEE-754 sum is 0.0; guard fires |
| EC-006 | Vector with large-magnitude elements (e.g., `vec![f32::MAX; 1]`) where sum-of-squares overflows `f32::MAX` | `norm = +Inf`; `Err(E-VS-001)` — overflow-norm detected via `!norm.is_finite()` guard; division never reached |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 (Red Gate) | `cosine_similarity(&vec![0.0f32; 768], &vec![1.0f32; 768])` | `Err(E-VS-001)` — zero-norm query vector | error-case (Red Gate) |
| TV-002 (Red Gate) | `cosine_similarity(&vec![1.0f32; 768], &vec![0.0f32; 768])` | `Err(E-VS-001)` — zero-norm document vector | error-case (Red Gate) |
| TV-003 | `cosine_similarity(&vec![1.0, 0.0, 0.0], &vec![0.0, 1.0, 0.0])` | `Ok(0.0)` — orthogonal vectors; cosine = 0 | happy-path (valid vectors) |
| TV-004 | `cosine_similarity(&vec![1.0, 0.0, 0.0], &vec![1.0, 0.0, 0.0])` | `Ok(1.0)` — identical vectors; cosine = 1 | happy-path (identical) |
| TV-005 | `cosine_similarity(&vec![1.0, 0.0, 0.0], &vec![-1.0, 0.0, 0.0])` | `Ok(-1.0)` — opposite vectors; cosine = -1 | happy-path (anti-parallel) |
| TV-006 | `cosine_similarity(&vec![f32::MAX; 1], &vec![1.0f32])` | `Err(E-VS-001)` — overflow-norm: `f32::MAX` squared = `+Inf`; `norm = sqrt(+Inf) = +Inf`; guard fires via `!norm.is_finite()` path | error-case (overflow guard) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.21.003-A (VP-009 candidate) | For ALL possible `Vec<f32>` pairs with finite elements, if either has `norm == 0.0 \|\| !norm.is_finite()` (zero-norm or overflow-to-infinity), `cosine_similarity` returns `Err(E-VS-001)` and NEVER returns `Ok(f32::NAN)` | proptest (random inputs including zero and overflow vectors) + Kani VP-009 formal proof: enumerate all reachable code paths; prove `Ok(f32::NAN)` is unreachable |
| VP-2.21.003-B | For ALL finite non-zero Vec<f32> pairs, `cosine_similarity` result is in [-1.0, 1.0] | proptest — random finite non-zero pairs; assert -1.0 ≤ result ≤ 1.0 |
| VP-2.21.003-C | MMR output scores in `max_marginal_relevance_search` are monotonically non-increasing (diversity selection preserves relevance ordering) | proptest — assert MMR results are ordered by marginal relevance at each step |

## Related BCs

- BC-2.21.002 — composes with: InMemoryVectorStore calls cosine_similarity in similarity_search; zero-norm guard is part of InMemoryVectorStore's cosine path
- BC-2.21.001 — composes with: all VectorStore trait methods that compute similarity invoke cosine_similarity; this guard applies to all such invocations

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-21, `vectorstores::similarity` module (cosine_similarity pure-core function; harness file `pregolya-vectorstores/src/similarity.rs`)
- `architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md` — Decision 2 §Hardening note (zero-norm guard specification, E-VS-001 error, VP-009 candidacy note)
- `architecture/purity-boundary-map.md` — `vectorstores::similarity` Pure Core; Kani VP-009 candidacy noted

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-21 security-hardening story]_

## VP Anchors

- VP-2.21.003-A (VP-009 assigned VP-INDEX v1.2; VP-009.md exists)
- VP-2.21.003-B
- VP-2.21.003-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-029 |
| Capability Anchor Justification | CAP-029 ("InMemoryVectorStore — Arc<dyn Embeddings> DI; RwLock Interior Mutability; Vec<f32> Cosine; E-VS-001 Zero-Norm Guard") per capabilities-p1-p2.md §CAP-029 — the "E-VS-001 Zero-Norm Guard" in the CAP title is exactly the property this BC specifies; CAP-029 calls it out as a mandatory hardening obligation for the Vec<f32> cosine path and notes the VP-009 connection explicitly |
| L2 Domain Invariants | DI-008 (cosine_similarity returns Result; no .unwrap() on cosine computation), DI-014 (E-VS-001 propagates as Err; no silent NaN or 0.0 fallthrough — cosine_similarity never returns Ok(f32::NAN)) |
| Architecture Authority | ADR-014 Decision 2 §Hardening note (zero-norm guard specification, E-VS-001, VP-009 candidacy) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| VP Registration | VP-009 (assigned in VP-INDEX v1.2 as VP-009 — Kani P0; pregolya-vectorstores zero_norm_guard_fail_closed) |
| Module | pregolya-vectorstores / vectorstores::similarity |
| Priority | P0 |
| Wave | 2 |
| Test Types | unit (Red Gate) + proptest + Kani (VP-009 candidate) |
