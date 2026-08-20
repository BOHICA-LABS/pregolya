---
document_type: story
level: ops
story_id: S-1.08
epic_id: E-03
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.001.md
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "78eadd9"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.01]
blocks: []
behavioral_contracts: [BC-2.07.001, BC-2.07.002, BC-2.07.003]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-splitters
subsystems: [SS-07]
estimated_days: 3
assumption_validations: []
risk_mitigations: [R8]
tdd_mode: strict
---

# S-1.08: Recursive Text Splitter — Unicode Boundaries and Non-ASCII Parity

## Narrative

- **As a** pregolya library user splitting documents for embedding and retrieval
- **I want to** use a `RecursiveCharacterTextSplitter` that counts chunk sizes in Unicode code points (not bytes), respects configurable separators, and produces output identical to the Python `langchain-text-splitters==1.1.2` reference for all 11 golden test vectors
- **So that** downstream embedding pipelines receive correctly-sized chunks that round-trip cleanly through Unicode-aware tokenizers, and that parity with the Python reference is formally proved rather than assumed

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.07.001 | Code-Point Chunk Sizing — str.chars().count() NOT str.len() | AC-001..AC-005 |
| BC-2.07.002 | Python Parity — 11 Golden Test Vectors (GTV-001..011) — RED GATE | AC-006..AC-009 |
| BC-2.07.003 | Edge-Case Correctness — Short Doc Single Chunk, Empty Input Returns [] | AC-010..AC-012 |

> **BC-local Verification Properties (VP-SPLIT-01..08):** These VPs are defined in
> BC-2.07.001/002/003 §Verification Properties and are deliberately BC-local — they are NOT
> registered in VP-INDEX (which holds only canonical VP-0NN IDs). VP-SPLIT-01..05 drive
> code-point sizing property tests (BC-2.07.001); VP-SPLIT-06..07 drive proptest/fuzz for
> the short-document path (BC-2.07.003 PC non-empty sub-case); VP-SPLIT-08 drives the
> empty-input unit test (BC-2.07.003 PC5). The `verification_properties` frontmatter field
> holds `[]` for this story because no VP-INDEX-registered VPs anchor here; all formal
> verification for this story is expressed through BC-local VP-SPLIT IDs, documented here
> per story convention (see STORY-INDEX §Conventions).

## RED GATE DISCIPLINE (BC-2.07.002)

**This story requires Red Gate discipline.** The test file for Python parity MUST be committed and failing BEFORE any implementation code is written. The test file is:

```
pregolya-splitters/tests/red_gate/test_BC_2_07_002_python_parity.rs
```

The Red Gate test file must compile but all 11 GTV tests must FAIL (return Err or wrong output) when no implementation exists. The implementer's Step 4 dispatch is blocked until the Red Gate density check passes (≥0.5 failing-to-total ratio).

**Python reference:** `langchain-text-splitters==1.1.2` — version pinned in `.factory/semport/reference-manifest.md` (§langchain-text-splitters). Do NOT use training-data assumptions about langchain behavior — derive all GTV expectations from the pinned reference corpus at `.reference/`.

## Acceptance Criteria

### AC-001 (traces to BC-2.07.001 postcondition 1)
Chunk size is measured in Unicode code points via `str.chars().count()`, NOT byte length (`str.len()`). A test with input containing multi-byte UTF-8 characters (e.g., `"🦀"` = 1 code point, 4 bytes; `"é"` = 1 code point, 2+ bytes depending on normalization) demonstrates that `chunk_size` counts code points. Verified by `test_BC_2_07_001_codepoint_sizing_vs_byte_len()`.

### AC-002 (traces to BC-2.07.001 postcondition 2)
Constructing a `RecursiveCharacterTextSplitter` with `chunk_size: 0` returns `Err(PregolyaError { category: VAL, code: "E-SPLIT-001", message: "InvalidChunkSize: chunk_size must be > 0", .. })`. Verified by `test_BC_2_07_001_zero_chunk_size_error()`.

### AC-003 (traces to BC-2.07.001 postcondition 3)
Constructing with `overlap >= chunk_size` returns `Err(PregolyaError { category: VAL, code: "E-SPLIT-002", message: "InvalidOverlap: overlap must be < chunk_size", .. })`. The check uses code-point counts for both `chunk_size` and `overlap`. Verified by `test_BC_2_07_001_overlap_ge_chunk_size_error()`.

### AC-004 (traces to BC-2.07.001 postcondition 4)
Each separator in the configured list is tried in order. The first separator that produces chunks within the `chunk_size` limit is used. If no separator splits sufficiently, the splitter falls back to hard-splitting at `chunk_size` code-point boundaries. Verified by `test_BC_2_07_001_separator_cascade_order()`.

### AC-005 (traces to BC-2.07.001 invariant 1 — R8 risk mitigation)
No internal size computation uses `str.len()` (byte length) for chunk measurement. The entire chain — separator split, overlap calculation, chunk emission — operates in code points. A test verifying that a purely ASCII-identical string and a multi-byte-identical string with the same code-point count produce the same chunk count closes the R8 code-point/byte confusion risk. Verified by `test_BC_2_07_001_R8_codepoint_byte_invariant()`.

### AC-006 (traces to BC-2.07.002 postcondition 1 — GTV-001..007)
GTV-001 through GTV-007 pass exactly as specified in BC-2.07.002. Each GTV is a separate `#[test]` function in `tests/red_gate/test_BC_2_07_002_python_parity.rs`. The test function names follow the pattern `test_GTV_NNN_<slug>()`. All 7 tests must produce output byte-for-byte identical to the Python reference. Verified by the Red Gate file.

### AC-007 (traces to BC-2.07.002 postcondition 2 — GTV-008..009)
GTV-008 and GTV-009 (separator boundary cases from the Python reference) pass. These vectors test that separator selection does not produce off-by-one splits in the presence of multi-character separators. Verified in the Red Gate file.

### AC-008 (traces to BC-2.07.002 postcondition 3 — GTV-010 grapheme discriminator)
GTV-010: Input is a string containing NFD-normalized `é` (U+0065 U+0301, 2 code points). With `chunk_size: 1`, the splitter produces 2 chunks (one per code point), NOT 1 chunk (as a grapheme-cluster-aware splitter would). This discriminator ensures the implementation counts Unicode code points (scalars), not grapheme clusters. Verified in the Red Gate file as `test_GTV_010_nfd_e_codepoint_not_grapheme()`.

### AC-009 (traces to BC-2.07.002 postcondition 4 — GTV-011 grapheme discriminator)
GTV-011: Input contains a ZWJ family emoji sequence (e.g., `"👨‍👩‍👧"`, which is multiple code points joined by U+200D ZWJ). With a `chunk_size` smaller than the total code-point count of the sequence, the splitter splits within the ZWJ sequence (producing separate emoji fragments), NOT treating the composite as an atomic unit. This discriminator verifies code-point granularity, not grapheme-cluster granularity. Verified in the Red Gate file as `test_GTV_011_zwj_emoji_splits_at_codepoints()`.

### AC-010 (traces to BC-2.07.003 postcondition 1 — short doc single chunk)
A document whose code-point count is ≤ `chunk_size` is returned as a single-element `Vec` containing the entire document. No splitting occurs, no separator search is attempted. Verified by `test_BC_2_07_003_short_doc_single_chunk()`.

### AC-011 (traces to BC-2.07.003 postcondition 5 — empty input returns empty vec)
`split_text("")` returns `Ok(vec![])` — an empty `Vec<String>`, NOT `Ok(vec!["".to_string()])`. The empty string is never emitted as a chunk. Verified by `test_BC_2_07_003_empty_input_returns_empty_vec()`.

### AC-012 (traces to BC-2.07.003 postcondition 3 — no panic)
`split_text` on any valid `RecursiveCharacterTextSplitter` (correctly constructed) never panics. Verified by `test_BC_2_07_003_no_panic_on_valid_splitter()` using proptest with arbitrary string inputs.

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `RecursiveCharacterTextSplitter` struct, `split_text` method | `pregolya_splitters` (`lib.rs` / `splitter.rs`) | pregolya-splitters | Pure (synchronous fn; code-point arithmetic only; no I/O) |
| Constructor `RecursiveCharacterTextSplitter::new` | `pregolya_splitters` (`lib.rs`) | pregolya-splitters | Pure (in-memory validation; no I/O) |
| GTV Red Gate test harness (11 GTV test functions) | `pregolya_splitters::tests::red_gate` | pregolya-splitters | Pure (`#[cfg(test)]`) |
| Proptest no-panic property test | `pregolya_splitters::tests::proptest_tests` | pregolya-splitters | Pure (`#[cfg(test)]`) |

**Subsystem anchor:** SS-07 owns this story's scope because SS-07 is the Text Splitting subsystem (`pregolya-splitters` crate) per ARCH-INDEX Subsystem Registry. Pure-core / effectful-shell boundary: the entire `RecursiveCharacterTextSplitter` is pure core — synchronous, deterministic, no I/O, no async. The crate must not depend on any async runtime.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `RecursiveCharacterTextSplitter::new(chunk_size, overlap, separators)` | Pure | In-memory constructor; validates invariants deterministically; no I/O |
| `RecursiveCharacterTextSplitter::split_text(&self, text: &str) -> Result<Vec<String>, PregolyaError>` | Pure | Deterministic text transform; code-point arithmetic (`str.chars().count()`) only; synchronous; no I/O; R8 risk mitigation |

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~4,500 |
| BC files (3 BCs: BC-2.07.001/002/003) | ~5,000 |
| Architecture module-decomposition.md (SS-07 section) | ~600 |
| Red Gate test file (11 GTV test functions) | ~4,000 |
| pregolya-splitters implementation skeleton | ~2,500 |
| Python reference corpus (langchain-text-splitters source, relevant sections) | ~2,000 |
| proptest test file | ~1,500 |
| **Total** | **~20,100** |

Within the 20-30% agent context window threshold (≈30,000 tokens for 100k context).

## Tasks

- [ ] **RED GATE FIRST**: Create `pregolya-splitters/tests/red_gate/test_BC_2_07_002_python_parity.rs` with all 11 GTV test functions (GTV-001..011). All tests must compile and FAIL before any implementation
- [ ] Verify Red Gate density: `cargo nextest run -p pregolya-splitters --no-fail-fast` → ≥11 failing, 0 passing (except structural compile tests)
- [ ] Create `pregolya-splitters/src/lib.rs` with `RecursiveCharacterTextSplitter` struct definition (all bodies `todo!()`)
- [ ] Implement code-point sizing via `str.chars().count()` — AC-001, AC-005
- [ ] Implement constructor validation: zero `chunk_size` → E-SPLIT-001, overlap ≥ chunk_size → E-SPLIT-002 — AC-002, AC-003
- [ ] Implement separator cascade and fallback hard-split — AC-004
- [ ] Close GTV-001..007 (standard parity vectors) — AC-006
- [ ] Close GTV-008..009 (separator boundary cases) — AC-007
- [ ] Close GTV-010 (NFD é grapheme discriminator) — AC-008
- [ ] Close GTV-011 (ZWJ emoji grapheme discriminator) — AC-009
- [ ] Implement short-doc single-chunk and empty-input returns [] — AC-010, AC-011
- [ ] Add proptest no-panic property test — AC-012
- [ ] Run `just iter pregolya-splitters` — all 11 GTV tests green + all unit tests green

## Previous Story Intelligence

- S-1.01 (PregolyaError Struct) established the error struct, VAL category, and E-SPLIT-001/E-SPLIT-002 error codes used in AC-002/AC-003. The constructor `Result` return pattern was established there via DI-008.
- R8 risk (code-point/byte confusion) is the primary risk for this story. AC-005 is the explicit R8 mitigation test. The test must be written first in the Red Gate file to lock in the boundary before implementation diverges.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-splitters`:

1. `pregolya-splitters` is a standalone crate — no circular dependency on `pregolya-graph` or `pregolya-checkpoint`. It may depend on `pregolya-core` (for PregolyaError).
2. `RecursiveCharacterTextSplitter` is a pure struct (no async, no I/O). `split_text` is a synchronous `fn` — it does not require `async`. Pure/Effectful classification: Pure.
3. All chunk size measurement MUST use `str.chars().count()`. No `str.len()` call may appear in any code path involved in chunk sizing or overlap calculation.
4. The `split_text` method signature: `fn split_text(&self, text: &str) -> Result<Vec<String>, PregolyaError>`. The `Result` wrapper enables future error propagation without breaking the API surface.
5. No `unwrap()` / `expect()` in non-test code paths.
6. No `println!` in the crate — the splitter is a pure library function with no I/O side effects.

## Library & Framework Requirements

Derived from `architecture/dependency-graph.md` external dependency table:

| Library | Version | Usage |
|---------|---------|-------|
| `pregolya-core` | workspace path | `PregolyaError` type |
| `proptest` | 1.x | Proptest for no-panic property test (dev-dependency) |
| `unicode-segmentation` | 1.x | MUST NOT be used for chunk sizing (grapheme-cluster boundary); permitted only for separator matching utilities if needed |

**Forbidden Dependencies:** `pregolya-splitters` MUST NOT depend on `unicode-segmentation` for chunk sizing (that would produce grapheme-cluster counts instead of code-point counts, failing GTV-010/011). If `unicode-segmentation` is added for any reason, an ADR must document why it does not affect chunk size calculation. The build system should flag this as a review-required dependency.

**No async runtime dependency:** `pregolya-splitters` must not depend on `tokio` — the splitter is purely synchronous.

## File Structure Requirements

Files to CREATE:
- `/pregolya-splitters/Cargo.toml` — crate manifest; depends on `pregolya-core`
- `/pregolya-splitters/src/lib.rs` — `RecursiveCharacterTextSplitter` public API
- `/pregolya-splitters/src/splitter.rs` — implementation (if split from lib.rs for size)
- `/pregolya-splitters/tests/red_gate/test_BC_2_07_002_python_parity.rs` — **RED GATE** all 11 GTV tests
- `/pregolya-splitters/tests/unit_tests.rs` — unit tests for AC-001..AC-005, AC-010..AC-012
- `/pregolya-splitters/tests/proptest_tests.rs` — proptest no-panic (AC-012)

Files to MODIFY:
- `/Cargo.toml` — add `"pregolya-splitters"` to `[workspace] members`

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Input is ASCII-only with `chunk_size: 5` | Byte length equals code-point count; behavior identical to naive byte split |
| EC-002 | Input contains only separator characters (e.g., `"\n\n\n"`) | Returns `[]` (empty vec) — separator-only text produces no content chunks |
| EC-003 | chunk_size exactly equals document code-point count | Returns single-element vec with entire document |
| EC-004 | GTV-010: NFD é (U+0065 U+0301) with chunk_size=1 | Returns 2 chunks — one per code point, NOT 1 chunk per grapheme |
| EC-005 | GTV-011: ZWJ family emoji sequence with chunk_size smaller than sequence | Splits within ZWJ sequence — NOT treated as atomic grapheme cluster |
