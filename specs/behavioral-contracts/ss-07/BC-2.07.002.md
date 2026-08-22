---
document_type: behavioral-contract
level: L3
bc_id: BC-2.07.002
version: "1.8"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-07
capability: CAP-008
wave: 0
phase: 1a
red_gate: true
red_gate_source: R8
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.0 (2026-07-13): initial authoring — Greenfield batch 2"
  - "1.1 (2026-07-14): GTV-008 expected value explicitly marked PROVISIONAL; values marked PROVISIONAL must be Python-verified before Red Gate test is written (F-P36-03)"
  - "1.2 (2026-07-15): Changelog date metadata correction: v1.1 row date corrected from 2026-07-16 to 2026-07-14 (F-P65-01)"
  - "1.3 (2026-07-17): VP-SPLIT-04..005 renumbered to VP-SPLIT-04..05 for corpus digit-width uniformity (OBS-P95-A)"
  - "1.4 (2026-07-17): Module field resolved from placeholder to pregolya-splitters per module-decomposition.md (F-P96-01)"
  - "1.5 (OBS-P148-04/OBS-P148-05/burst-249/2026-07-24): GTV-008 PROVISIONAL resolved (corrected expected value); GTV-003 separator-logic resolved (corrected expected value); Invariant splitter reference reconciled to in-tree langchain-text-splitters==1.1.2 per reference-manifest.md. Note: Form-B v1.5 row contained a false input-hash claim (the claimed value was never written to the frontmatter at any commit) — corrected in v1.7 (FC-5)."
  - "1.6 (F-P152-03/burst-253/2026-07-24): GTV-010 and GTV-011 grapheme-cluster discriminators added; 9 to 11 GTVs Python-verified against pinned in-tree langchain-text-splitters==1.1.2; VP-SPLIT-04 range extended to GTV-001..011"
  - "1.7 (FIX-BURST-277-WAVE-C/FC-5-genuine-fix/2026-07-28): False closure FC-5 resolved. Form-B v1.5 row contained a false input-hash claim; git history confirms the claimed hash value was never written to the frontmatter — the burst-249 commit held a different value, and the dispatcher log from 2026-07-24 recorded a computed-vs-stored mismatch at burst time (the commit landed with a value different from what was computed during the burst). Form-B v1.5 false hash claim removed. input-hash updated to current computed value per frontmatter. Form-A changelog added (migrated from Form-B historical record)."
  - "1.8 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.08 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-008
  - domain-spec/edge-cases.md#DEC-001
  - R8
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
input-hash: "254e69f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.002: Non-ASCII Boundary Parity with Python Reference Implementation (Emoji, CJK) — R8 Red Gate

## Description

For any document containing non-ASCII Unicode code points (emoji, CJK characters, accented
Latin, combining characters, etc.), the chunk boundaries produced by `pregolya-splitters`
must be bit-identical to those produced by the LangChain Python reference implementation
(`langchain_text_splitters.RecursiveCharacterTextSplitter`) with the same `chunk_size`,
`chunk_overlap`, and separators. This is the R8 Red Gate test: a test suite must be written
first (and fail), then the implementation must make it pass.

> **Red Gate test required:** This BC mandates a Red Gate discipline. The test file
> `tests/red_gate/test_BC_2_07_002_python_parity.rs` must be committed and must
> FAIL before any splitter implementation code is written. The implementation is not
> complete until this test passes.

## Preconditions

1. The pregolya-splitters crate is configured with the same `chunk_size`, `chunk_overlap`, and `separators` as the reference Python implementation.
2. The input document contains non-ASCII Unicode: at least one of:
   - Emoji (e.g., U+1F600 GRINNING FACE, 4 bytes in UTF-8)
   - CJK unified ideographs (e.g., U+4E2D, 3 bytes in UTF-8)
   - Combining characters (e.g., `e` + U+0301 COMBINING ACCENT = 2 code points, 3 bytes)
   - Full-width forms (e.g., U+FF01 FULLWIDTH EXCLAMATION, 3 bytes, 1 code point)
3. The Python reference output (chunk boundaries as a list of `(start_codepoint_offset, end_codepoint_offset)` pairs or a list of chunk strings) is pre-computed and stored as golden test vectors.

## Postconditions

1. The Rust splitter produces the same list of chunk strings as the Python reference for all test vectors in the golden table.
2. The test comparison is string-equality on the decoded chunk content (not on byte offsets).
3. For the golden vectors, the Rust chunk list length equals the Python chunk list length.
4. No extra empty chunks appear in the Rust output that are absent in the Python output.

## Invariants

- The golden test vectors in this BC are the normative specification — they take precedence over any ambiguous interpretation of the text-splitter algorithm.
- The Python reference is in-tree `langchain-text-splitters==1.1.2` at `langchain==1.3.13` SHA `42f8f79293cfb7589e5bc1d74a8ae4dfd0bf15e3` per `.factory/semport/reference-manifest.md` (the standalone `langchain-text-splitters==0.3.8` package is superseded — text-splitters is in-tree within the pinned langchain monorepo; no separate package version exists in the manifest). If the reference corpus pin changes, the golden vectors must be regenerated.
- Parity applies to `RecursiveCharacterTextSplitter` and `CharacterTextSplitter` with the `length_function=len` setting (the default, which counts code points in Python).

## Reference Evidence

**Source:** LangChain Python `langchain_text_splitters.RecursiveCharacterTextSplitter`.
- Python `len(str)` counts Unicode code points (not bytes, not grapheme clusters).
- `RecursiveCharacterTextSplitter._split_text` uses `len(chunk)` comparisons throughout.
- The R8 risk in `risks.md`: "Splitter code-point/byte confusion — upstream has no test
  for this on non-ASCII input. A naive Rust port using `str.len()` (byte count) will
  produce different boundaries on emoji/CJK."
- DEC-001 in `edge-cases.md`: "chunk_size=100, emoji input → 100 code points from start,
  not 100 bytes."
- D17-Q9: "Explicit BC + Red Gate test required for code-point vs byte-length boundary
  parity on non-ASCII input."

## Golden Test Vectors

These vectors were derived from running the reference Python implementation. They are
normative. The Rust implementation must produce byte-identical chunk strings.

> **Source:** Computed from `langchain_text_splitters.RecursiveCharacterTextSplitter` with
> `separators=["\n\n", "\n", " ", ""]`, `chunk_size`, `chunk_overlap` as specified.

### Vector Group 1: Emoji (U+1F600 family, 4 bytes each)

| Vector ID | Input | chunk_size | overlap | Expected Chunks |
|-----------|-------|-----------|---------|-----------------|
| GTV-001 | `"😀😃😄😁😆"` (5 emoji = 5 code pts, 20 bytes) | 3 | 0 | `["😀😃😄", "😁😆"]` |
| GTV-002 | `"😀😃😄😁😆"` (5 emoji) | 3 | 1 | `["😀😃😄", "😄😁😆"]` |
| GTV-003 | `"hello 😀 world"` (13 code pts) | 7 | 0 | `["hello 😀", "world"]` (Python-verified against pinned corpus: `cd .reference/langchain/libs/text-splitters && python3 -c "import sys; sys.path.insert(0,'.'); from langchain_text_splitters import RecursiveCharacterTextSplitter; print(RecursiveCharacterTextSplitter(chunk_size=7,chunk_overlap=0,separators=['\n\n','\n',' ','']).split_text('hello 😀 world'))"`) |
| GTV-004 | `"😀" * 100` (100 emoji, 400 bytes) | 10 | 0 | 10 chunks of 10 emoji each |

### Vector Group 2: CJK Unified Ideographs (U+4E00–U+9FFF, 3 bytes each)

| Vector ID | Input | chunk_size | overlap | Expected Chunks |
|-----------|-------|-----------|---------|-----------------|
| GTV-005 | `"中文测试内容"` (6 CJK = 6 code pts, 18 bytes) | 3 | 0 | `["中文测", "试内容"]` |
| GTV-006 | `"中文测试内容"` (6 CJK) | 3 | 1 | `["中文测", "测试内", "内容"]` |
| GTV-007 | `"a中b文c"` (5 code pts: 1+1+1+1+1) | 3 | 0 | `["a中b", "文c"]` |

### Vector Group 3: Mixed ASCII and Multi-Byte

| Vector ID | Input | chunk_size | overlap | Expected Chunks |
|-----------|-------|-----------|---------|-----------------|
| GTV-008 | `"abc" + "🎉" * 5 + "xyz"` (3+5+3=11 code pts) | 5 | 0 | `["abc🎉🎉", "🎉🎉🎉xy", "z"]` (Python-verified against pinned corpus; prior PROVISIONAL value `["abc🎉🎉", "🎉🎉🎉x", "yz"]` was wrong) |
| GTV-009 | `"ñoño"` (4 code pts: ñ=U+00F1, o, ñ, o — 2 bytes each for ñ) | 2 | 0 | `["ño", "ño"]` |

### Vector Group 4: Combining Sequences and ZWJ Emoji (Grapheme-Cluster Discriminators)

> These vectors are specifically designed so that a Rust implementation using
> `unicode-segmentation graphemes()` for length measurement instead of
> `.chars().count()` (code-point counting) would produce **different** output.
> Each row states the wrong (grapheme-aware) output explicitly.

| Vector ID | Input | chunk_size | overlap | Expected Chunks |
|-----------|-------|-----------|---------|-----------------|
| GTV-010 | `"abcéxyz"` (NFD é = e + U+0301 combining acute: 2 code pts, 1 grapheme; total 8 code pts, 7 graphemes) | 4 | 0 | `["abce", "́xyz"]` — code-point boundary 4 falls between e and its combining accent, orphaning U+0301 into chunk 2. **Wrong (grapheme):** `["abcé", "xyz"]` — a grapheme-aware impl counts é as 1 grapheme, keeping it intact in chunk 1 (5 code pts) and shifting the boundary to after the full grapheme cluster. Python-verified: `cd .reference/langchain/libs/text-splitters && python3 -c "import sys; sys.path.insert(0,'.'); from langchain_text_splitters import RecursiveCharacterTextSplitter; print(RecursiveCharacterTextSplitter(chunk_size=4,chunk_overlap=0,separators=['\n\n','\n',' ','']).split_text('abcéxyz'))"` |
| GTV-011 | `"👨‍👩‍👧‍👦 hi"` (ZWJ family: U+1F468+ZWJ+U+1F469+ZWJ+U+1F467+ZWJ+U+1F466 = 7 code pts, 1 grapheme; " hi" = 3 code pts, 3 graphemes; total 10 code pts, 4 graphemes) | 4 | 0 | `["👨‍👩‍", "👧‍👦", "hi"]` — ZWJ sequence (7 code pts > chunk_size=4) is split at code-point boundary 4, producing 3 chunks. **Wrong (grapheme):** `["👨‍👩‍👧‍👦", "hi"]` — a grapheme-aware impl counts the entire ZWJ sequence as 1 grapheme (≤ chunk_size=4), keeping it whole and producing 2 chunks instead of 3. Python-verified: `cd .reference/langchain/libs/text-splitters && python3 -c "import sys; sys.path.insert(0,'.'); from langchain_text_splitters import RecursiveCharacterTextSplitter; print(RecursiveCharacterTextSplitter(chunk_size=4,chunk_overlap=0,separators=['\n\n','\n',' ','']).split_text('\U0001F468‍\U0001F469‍\U0001F467‍\U0001F466 hi'))"` |

> **Note (burst-249/2026-07-24 + burst-253/2026-07-24):** GTV-008 and GTV-003 were **Python-verified** in
> burst-249 against the pinned corpus (`langchain-text-splitters==1.1.2` in-tree at `langchain==1.3.13`
> SHA `42f8f79293cfb7589e5bc1d74a8ae4dfd0bf15e3`). Prior PROVISIONAL markers removed.
> GTV-008 correction: `["abc🎉🎉", "🎉🎉🎉x", "yz"]` (wrong) → `["abc🎉🎉", "🎉🎉🎉xy", "z"]` (verified).
> GTV-003 correction: `["hello", "😀 world"]` (wrong) → `["hello 😀", "world"]` (verified;
> RecursiveCharacterTextSplitter merges "hello" + " " + "😀" = 7 code pts into chunk 1, then
> "world" = 5 code pts as chunk 2 — not a bare space-split).
> GTV-010 and GTV-011 added in burst-253 as grapheme-cluster discriminators — Python-verified
> against same pinned corpus. All 11 GTVs are now verified;
> the test-writer may author Red Gate tests directly from this table.

## Edge Cases

### EC-001: Combining character sequences
**Scenario:** Input contains `"é"` (e + combining acute accent = 2 code points, 3 bytes, 1 grapheme cluster). `chunk_size=1`.
**Expected behavior:** First chunk is `"e"` (1 code point), second chunk starts with `"́"` (the combining mark, which may render oddly but is 1 code point). Pregolya splits by code points, not grapheme clusters — same as Python `len()` semantics.
**Note:** If grapheme cluster splitting is desired, that is a separate capability (not in scope for v1).

### EC-002: Normalization differences
**Scenario:** Input contains a character in NFC vs NFD form (e.g., `"é"` as U+00E9 vs `"e"` + U+0301). Both represent the same displayed character but different code-point counts.
**Expected behavior:** Pregolya does NOT normalize. It splits on the raw code-point sequence as received. Parity with Python: Python also does not normalize.

### EC-003: Surrogate pairs (not applicable to Rust)
**Scenario:** (Not a Rust concern — Rust `String` cannot contain surrogate code points. JavaScript `length` counts UTF-16 code units and would count surrogate pairs as 2.)
**Expected behavior:** N/A — this edge case is only relevant to JavaScript comparisons, not Python or Rust.

### EC-004: BMP-only CJK vs Extension A/B
**Scenario:** Input contains CJK Extension B character (U+20000+, 4 bytes in UTF-8, 1 code point in Python and Rust).
**Expected behavior:** Both Python and Rust count it as 1 code point. Parity maintained.

## Canonical Test Vectors

(See Golden Test Vectors table above — those are the canonical test vectors for this BC.)

Additional baseline:

| # | Input | chunk_size | Expected | Notes |
|---|-------|-----------|----------|-------|
| TV-001 | `"中文"` (2 CJK, 6 bytes) | 1 | `["中", "文"]` | 1 code point per chunk |
| TV-002 | ASCII-only `"abcdef"` | 3 | `["abc", "def"]` | Parity must hold for ASCII too |
| TV-003 | `"a😀b"` (3 code pts, 6 bytes) | 2 | `["a😀", "b"]` | Mixed ASCII+emoji |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-SPLIT-04 | All GTV-001 through GTV-011 produce byte-identical chunk lists to Python reference | Golden-vector unit tests (Red Gate) | Wave 0 (Red Gate first) |
| VP-SPLIT-05 | Property test: arbitrary Unicode input → chunk counts match Python reference (sampled) | proptest + reference Python subprocess | Phase 1 |

> **Red Gate Discipline:** `tests/red_gate/test_BC_2_07_002_python_parity.rs` must be
> committed and failing before splitter implementation begins. This is a D17-Q9 mandate.

## Related BCs

- BC-2.07.001 — Code-point boundary definition (depends on: this BC builds on that fundamental rule)
- BC-2.07.003 — Short document single-chunk (composes with: also tested on non-ASCII short docs)

## Architecture Anchors

- `pregolya-splitters/src/character.rs`
- `pregolya-splitters/tests/red_gate/test_BC_2_07_002_python_parity.rs` (Red Gate file)
- `pregolya-splitters/tests/fixtures/golden_vectors.json` (pre-computed Python outputs)

## Story Anchor

S-1.08

## VP Anchors

- VP-SPLIT-04, VP-SPLIT-05

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-008 |
| Capability Anchor Justification | CAP-008 ("Text Splitting with Code-Point Boundary Correctness") per capabilities-p0.md §CAP-008 — "On non-ASCII text, chunk boundaries must be identical to the reference LangChain Python implementation… Provide explicit test vectors for emoji and CJK inputs" is verbatim in the capability description |
| DEC References | DEC-001 |
| Risk References | R8 |
| D17 Reference | D17-Q9 |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit, golden vectors) |
| Module | pregolya-splitters |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.7 | 2026-07-28 | FIX-BURST-277-WAVE-C/FC-5: False closure FC-5 resolved. Form-B v1.5 row contained a false input-hash claim; git history (burst-249 commit) confirms the claimed value was never written to the frontmatter — the commit held a different hash value. Dispatcher log from 2026-07-24 corroborates: a computed-vs-stored mismatch was recorded at burst time, but the landed commit wrote yet another different value. False hash claim removed from v1.5 row. input-hash updated to current computed value per frontmatter. Form-A changelog added (migrated from Form-B). | FIX-BURST-277-WAVE-C |
| 1.6 | 2026-07-24 | F-P152-03/burst-253: ADD GTV-010 and GTV-011 as grapheme-cluster discriminators. GTV-010: input "abcéxyz" (NFD é = e+U+0301, 8 code pts, 7 graphemes), chunk_size=4 → ["abce", "́xyz"]; wrong grapheme output: ["abcé", "xyz"] — grapheme-aware impl keeps é intact, shifting boundary. GTV-011: input "👨‍👩‍👧‍👦 hi" (ZWJ family 7 code pts + " hi", total 10 code pts), chunk_size=4 → ["👨‍👩‍", "👧‍👦", "hi"] (3 chunks); wrong grapheme output: ["👨‍👩‍👧‍👦", "hi"] (2 chunks — ZWJ treated as 1 grapheme ≤ 4). Both Python-verified against pinned corpus (langchain-text-splitters==1.1.2 in-tree at langchain==1.3.13 SHA 42f8f79). VP-SPLIT-04 range GTV-001..009 → GTV-001..011. GTV count 9→11. | F-P152-03 |
| 1.5 | 2026-07-24 | OBS-P148-04/OBS-P148-05/burst-249: (1) GTV-008 PROVISIONAL resolved — corrected expected value `["abc🎉🎉", "🎉🎉🎉x", "yz"]` → `["abc🎉🎉", "🎉🎉🎉xy", "z"]`; PROVISIONAL marker removed; Python-verified against pinned corpus. (2) GTV-003 separator-logic dependency resolved — corrected expected value `["hello", "😀 world"]` → `["hello 😀", "world"]`; Python-verified. (3) Invariant splitter reference reconciled: `langchain-text-splitters==0.3.8` → in-tree `langchain-text-splitters==1.1.2` at `langchain==1.3.13` SHA per reference-manifest.md §langchain==1.3.13 (no standalone splitters pin exists in the manifest). _(Note: this row originally contained a false input-hash claim; git history confirms the claimed value was never written to the frontmatter — the burst-249 commit held a different hash value. False claim removed; see v1.7 for full FC-5 correction.)_ | OBS-P148-04, OBS-P148-05 |
| 1.4 | 2026-07-17 | F-P96-01: Module field resolved from placeholder to pregolya-splitters per module-decomposition.md v1.10. | F-P96-01 |
| 1.3 | 2026-07-17 | VP-SPLIT-04..005 renumbered to VP-SPLIT-04..05 for corpus digit-width uniformity (OBS-P95-A adjudication: blast radius 3 files only — renumber is the production-grade call). No VP-INDEX registration affected (SPLIT VPs are BC-local). | OBS-P95-A |
| 1.2 | 2026-07-15 | Changelog date metadata correction: v1.1 row date corrected from 2026-07-16 → 2026-07-14 (PASS-36 occurred on 2026-07-14; prior date was a future-date typo sharing the same root cause as F-P64-02 in bc-authoring-plan.md and test-vectors.md). (F-P65-01, pass-65) | F-P65-01 |
| 1.1 | 2026-07-14 | GTV-008 expected value explicitly marked PROVISIONAL; note updated to state values marked PROVISIONAL must be Python-verified before Red Gate test is written (F-P36-03 fix, ADV-P1D-PASS-36) | F-P36-03 |
| 1.0 | 2026-07-13 | Initial authoring | Greenfield batch 2 |
