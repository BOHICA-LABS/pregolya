---
document_type: behavioral-contract
level: L3
bc_id: BC-2.07.003
version: "1.0"
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
  - domain-spec/edge-cases.md#DEC-002
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
input-hash: "fe30408"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.07.003: Short Document (length < chunk_size) — Single Chunk, No Overlap, No Panic

## Description

When the input document's length in Unicode code points is strictly less than `chunk_size`,
the splitter must return a list containing exactly one chunk (the entire document). No
overlap logic is applied (there is nothing to overlap with). No panic, no empty chunk,
no `None`, and no index-out-of-bounds occurs. This is the minimal-document degenerate case.

## Preconditions

1. A splitter is configured with `chunk_size > 0` and `chunk_overlap >= 0` and `chunk_overlap < chunk_size`.
2. The input document's length in Unicode code points `len_codepoints < chunk_size`.
3. The document may be non-empty (length ≥ 1) or empty (length = 0). Both sub-cases are covered.

## Postconditions

1. The returned chunk list contains exactly one element: the original document string, unmodified.
2. **No overlap is applied.** The returned list has length 1, not 2 or more (there are no preceding chunks to overlap with).
3. No panic occurs, no array-index-out-of-bounds, no underflow arithmetic.
4. The chunk's content is byte-identical to the input document (no truncation, no extra whitespace trimming beyond what the separator logic would do).
5. For an empty string input (`len_codepoints = 0`): the splitter returns `[]` (empty list) OR `[""]` — the behavior must be documented and consistent. The preferred behavior is `[]` (consistent with "no chunks if no content") but either is acceptable if consistent with the Python reference.

## Invariants

- The short-document path must not attempt arithmetic that would underflow (e.g., `(len - overlap) / (chunk_size - overlap)` when `len < overlap`).
- The overlap value has no effect on a document shorter than `chunk_size`.
- The overlap value has no effect on the single returned chunk's content.

## Reference Evidence

**Source:** LangChain Python `RecursiveCharacterTextSplitter._split_text`.
- When `_merge_splits` is called with a chunk list where the total length is less than
  `chunk_size`, it returns the single combined chunk without splitting.
- Python's split logic handles this naturally because it never tries to split if the
  current accumulation fits within the limit. The Rust port must not introduce a
  short-document panic.
- DEC-002 in `edge-cases.md`: "Input shorter than `chunk_size`; overlap is greater than
  zero → Single chunk returned; no overlap applied; no panic or empty result."

## Edge Cases

### EC-001: Document exactly 1 code point, chunk_size = 100
**Scenario:** Input is `"a"` (1 code point); `chunk_size=100, overlap=0`.
**Expected behavior:** Returns `["a"]` — one chunk, no splitting needed.

### EC-002: Document exactly (chunk_size - 1) code points
**Scenario:** Input has exactly `chunk_size - 1` code points. `chunk_size=5, overlap=2, input="abcd"` (4 code points).
**Expected behavior:** Returns `["abcd"]` — single chunk, overlap ignored.

### EC-003: overlap > input length (but overlap < chunk_size — valid config)
**Scenario:** `chunk_size=100, overlap=50, input="hello"` (5 code points < 50 overlap).
**Expected behavior:** Returns `["hello"]`. Overlap is 50, but there is no preceding chunk to overlap with. The overlap value does not cause the return to be `["hello", "lo", "o", ...]` or similar nonsense.

### EC-004 (DEC-002): Overlap greater than zero, short document
**Scenario:** `chunk_size=10, overlap=5, input="short"` (5 code points).
**Expected behavior:** Returns `["short"]`. One chunk. The overlap is irrelevant for a document shorter than the chunk size.

### EC-005: Empty string input
**Scenario:** `input=""`, `chunk_size=100`.
**Expected behavior:** Returns `[]` (empty list). An empty document has no chunks. This must not return `[""]` (an empty-string chunk is useless noise). Match Python reference behavior.

### EC-006: Non-ASCII short document
**Scenario:** `input="中文"` (2 CJK, 6 bytes), `chunk_size=10`.
**Expected behavior:** Returns `["中文"]` — 2 code points < 10 chunk_size → single chunk. Byte length (6) is not the measurement used.

## Canonical Test Vectors

| # | Input | chunk_size | overlap | Expected Output | Notes |
|---|-------|-----------|---------|-----------------|-------|
| TV-001 | `"hello"` (5 ASCII) | 100 | 0 | `["hello"]` | Short ASCII document |
| TV-002 | `"hello"` (5 code pts) | 100 | 50 | `["hello"]` | Short doc with non-zero overlap |
| TV-003 | `"中文"` (2 CJK) | 10 | 0 | `["中文"]` | Short non-ASCII document |
| TV-004 | `""` (empty) | 100 | 0 | `[]` | Empty string → no chunks |
| TV-005 | `"a"` (1 code pt) | 100 | 99 | `["a"]` | Minimum-length doc, maximum overlap |
| TV-006 | `"abcd"` (4 code pts) | 5 | 2 | `["abcd"]` | chunk_size - 1 code points |
| TV-007 | `"hello"` (5 code pts) | 5 | 0 | `["hello"]` | Exactly chunk_size — still single chunk |

> **Note on TV-007:** A document with length == chunk_size is NOT "shorter than chunk_size"
> (the postcondition says strictly less), but the splitter should still return a single chunk
> because no split is needed. The exact boundary (len == chunk_size) must not panic.

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-SPLIT-006 | For any input with `len_codepoints < chunk_size`, result has length 1 | Property test (proptest: random short docs) | Phase 1 |
| VP-SPLIT-007 | No panic on any combination of valid `(input, chunk_size, overlap)` where `input` is shorter than `chunk_size` | Property test + fuzz | Phase 1 |
| VP-SPLIT-008 | Empty input returns `[]`, not `[""]` | Unit test | Phase 1 |

## Related BCs

- BC-2.07.001 — Code-point boundary rule (depends on: this BC is a special case of the general splitting rule)
- BC-2.07.002 — Non-ASCII parity (composes with: also applies to short non-ASCII docs)

## Architecture Anchors

- `ferrochain-splitters/src/character.rs`
- `ferrochain-splitters/src/recursive.rs`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-SPLIT-006, VP-SPLIT-007, VP-SPLIT-008

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-008 |
| Capability Anchor Justification | CAP-008 ("Text Splitting with Code-Point Boundary Correctness") per capabilities-p0.md §CAP-008 — the capability requires "configurable overlap" and "explicit test vectors" which implies correct handling of the short-document degenerate case |
| DEC References | DEC-002 |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit) |
| Module | [architect to assign — ferrochain-splitters] |
