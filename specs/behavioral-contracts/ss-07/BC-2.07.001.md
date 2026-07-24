---
document_type: behavioral-contract
level: L3
bc_id: BC-2.07.001
version: "1.3"
changelog:
  - "1.1 (OBS-P95-A, 2026-07-17): VP-SPLIT-01..003 renumbered to VP-SPLIT-01..03 for corpus digit-width uniformity (OBS-P95-A adjudication: blast radius 3 files only — below >5 threshold — so renumber is the production-grade correct call over documenting the convention). No VP-INDEX registration affected (SPLIT VPs are BC-local)."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-splitters per module-decomposition.md v1.10."
  - "1.3 (2026-07-22, F-P139-03, burst-239): TV-005 corrected — empty string expected output changed from '[\"\"]` or `[]`' to `[]` only. Sibling fix to BC-2.07.003 PC5 (F-P139-03 same burst): BC-2.07.003 EC-005 and VP-SPLIT-08 already mandate `[]`; BC-2.07.003 PC5 previously hedged 'either acceptable' but that was the internal contradiction. TV-005 now aligns with the mandated `[]` behavior."
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-07
capability: CAP-008
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-008
  - domain-spec/edge-cases.md#DEC-001
  - R8
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/specs/prd-supplements/error-taxonomy.md
input-hash: "6da94e8"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.001: Chunk Boundaries Are Unicode Code-Point Counts (Not Bytes)

## Description

The `ferrochain-splitters` `RecursiveCharacterTextSplitter` and `CharacterTextSplitter`
must measure chunk size and overlap as counts of Unicode scalar values (code points), not
bytes, not UTF-8 code units, and not grapheme clusters. This matches the behavior of the
reference Python implementation (Python `len(str)` counts code points). Any naive Rust
port that uses `str::len()` (byte count) will produce different split boundaries on any
non-ASCII input, which is a correctness regression addressed by R8.

## Preconditions

1. A splitter is configured with `chunk_size: usize` (a code-point count) and `chunk_overlap: usize` (a code-point count).
2. The input document is a valid UTF-8 `String` (the Rust representation).
3. The input may contain multi-byte Unicode code points (e.g., emoji U+1F600 = 4 bytes, CJK U+4E2D = 3 bytes).
4. `chunk_size > 0` (enforced by BC-2.14.006 — a zero chunk_size returns `Err`).
5. `chunk_overlap < chunk_size` (enforced by validation; see EC-001).

## Postconditions

1. Every chunk's length, measured in Unicode code points (via `str.chars().count()` in Rust), is ≤ `chunk_size`.
2. The total number of chunks is `ceil((len_codepoints - overlap) / (chunk_size - overlap))` for a document with no separator splits.
3. The byte length of a chunk may exceed `chunk_size` bytes when the text contains multi-byte code points — this is expected and correct.
4. No chunk begins or ends in the middle of a Unicode code point (no invalid UTF-8).
5. If the document has no separator (single-separator splitter), chunks are sliced at exact code-point boundaries.
6. The boundary computation uses the Rust iterator `str.char_indices()` or equivalent — never `str[0..n]` where `n` is a byte index derived from `chunk_size` directly.

## Invariants

- Chunk size measurement is ALWAYS in code points. The string "hello" (5 ASCII chars, 5 bytes, 5 code points) and the string "中文" (2 CJK chars, 6 bytes, 2 code points) must behave consistently: `chunk_size=2` splits "中文" into one chunk `["中文"]` (2 code points ≤ 2), not one chunk per byte.
- The `chunk_size` and `chunk_overlap` parameters are documented in the public API as "Unicode code point counts" to prevent user confusion.
- No silent truncation or data loss — all code points in the input appear in exactly one chunk (for non-overlapping splits) or in at least one chunk (for overlapping splits).

## Reference Evidence

**Source:** LangChain Python `text_splitter.py`.
- Python `len(text)` counts Unicode code points (code units in Python's internal
  representation, which for BMP characters = code points; Python 3 `str` is always
  decoded Unicode). All Python splitter length checks use `len()` directly.
- The `_split_text_with_regex` helper in `text_splitter.py` uses `len(chunk)` to
  compare against `chunk_size` — this is code-point length.
- Rust `str::len()` returns byte count; `str.chars().count()` returns code-point count.
  The naive port of `len(chunk)` as `chunk.len()` introduces the R8 bug.
- R8 in `risks.md` explicitly names this as "R8: Splitter code-point/byte confusion"
  with High likelihood and High impact.
- DEC-001 in `edge-cases.md`: chunk_size=100, emoji/CJK input → boundaries must be
  100 code points from start, not 100 bytes.

## Edge Cases

### EC-001: Overlap ≥ chunk_size
**Scenario:** `chunk_overlap >= chunk_size` (e.g., `chunk_size=10, overlap=10`).
**Expected behavior:** Validation fails at construction time: `Err(FerrochainError { code: E-SPLIT-002, message: "OverlapExceedsChunk: overlap 10 must be < chunk_size 10" })`. The splitter is not created.

### EC-002: Zero chunk_size
**Scenario:** `chunk_size = 0`.
**Expected behavior:** `Err(FerrochainError { code: E-SPLIT-001, message: "ZeroChunkSize: chunk_size must be > 0 code points; got 0" })`. No splitter created.

### EC-003: Pure ASCII input
**Scenario:** Input is ASCII-only; `chunk_size=100`.
**Expected behavior:** Byte count == code-point count == code-unit count. Output is identical to a byte-based implementation. This is the regression-safe baseline.

### EC-004: Input ends in mid-char (malformed UTF-8)
**Scenario:** Input `String` contains a truncated multi-byte sequence (invalid UTF-8).
**Expected behavior:** This is a precondition violation — Rust `String` is always valid UTF-8, so malformed UTF-8 cannot reach this code as a `String`. If received as `&[u8]`, construction fails before splitting.

### EC-005 (DEC-001): 4-byte emoji at chunk boundary
**Scenario:** Input `"a" * 99 + "🎉"` (99 ASCII + 1 emoji). `chunk_size=100, overlap=0`.
**Expected behavior:** Single chunk `["aaa...a🎉"]` — the emoji is the 100th code point, exactly at the boundary. No split occurs. Byte length of the chunk is 99 + 4 = 103, which is > 100 bytes. This is correct.

### EC-006 (DEC-001): CJK text split
**Scenario:** 200 CJK characters. `chunk_size=100, overlap=0`.
**Expected behavior:** Two chunks, each with 100 CJK characters. Each chunk is 300 bytes (100 × 3 bytes/CJK). Not 100 bytes.

## Canonical Test Vectors

| # | Input | chunk_size | overlap | Expected Output | Notes |
|---|-------|-----------|---------|-----------------|-------|
| TV-001 | `"hello world"` (11 ASCII) | 5 | 0 | `["hello", " worl", "d"]` | ASCII baseline |
| TV-002 | `"中文测试"` (4 CJK, 12 bytes) | 2 | 0 | `["中文", "测试"]` | CJK code-point split |
| TV-003 | `"a" * 99 + "🎉"` (99+1=100 code pts, 103 bytes) | 100 | 0 | `["aaa...a🎉"]` | Emoji at boundary — single chunk |
| TV-004 | `"🎉🎊🎈"` (3 emoji, 12 bytes) | 2 | 0 | `["🎉🎊", "🎈"]` | Emoji code-point split |
| TV-005 | `""` (empty string) | 100 | 0 | `[]` | Empty doc — empty string returns no chunks (BC-2.07.003 PC5) |
| TV-006 | `chunk_size=0` | — | — | `Err(E-SPLIT-001)` | Zero chunk validation |
| TV-007 | `overlap >= chunk_size` | 10 | 10 | `Err(E-SPLIT-002)` | Overlap constraint |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-SPLIT-01 | All chunk lengths measured in code points are ≤ chunk_size | Property test (proptest: random Unicode strings) | Phase 1 |
| VP-SPLIT-02 | No code points are lost between chunks (all input code points appear in output) | Property test: `chunks.join("") == input` (for overlap=0) | Phase 1 |
| VP-SPLIT-03 | Chunk byte lengths may exceed chunk_size for multi-byte inputs | Unit test (CJK/emoji golden vectors) | Phase 1 |

## Related BCs

- BC-2.07.002 — Non-ASCII parity with Python reference (depends on: this BC defines the measurement rule; BC-2.07.002 adds the parity test vectors)
- BC-2.07.003 — Short document single-chunk (composes with: special case of this BC's code-point logic)
- BC-2.14.006 — Validation failure propagation (depends on: zero chunk_size → `Err` per this taxonomy)

## Architecture Anchors

- `ferrochain-splitters/src/character.rs`
- `ferrochain-splitters/src/recursive.rs`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-SPLIT-01, VP-SPLIT-02, VP-SPLIT-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-008 |
| Capability Anchor Justification | CAP-008 ("Text Splitting with Code-Point Boundary Correctness") per capabilities-p0.md §CAP-008 — "Split documents into chunks that respect the configured chunk size as a count of Unicode code points (not bytes)" is verbatim in the capability description |
| DEC References | DEC-001 |
| Risk References | R8 |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit) |
| Module | ferrochain-splitters |
