---
artifact: semport/splitters/test-inventory
project: pregolya
port_target: langchain-text-splitters (1.1.2)
analyzer_pass: 5
date: 2026-07-12
purpose: identify tests that LOCK boundary / off-by-one behavior → become Red-Gate parity vectors
---

# langchain-text-splitters — Test Inventory

## Test corpus scale

| File | LOC | ~Tests | Role |
|---|---|---|---|
| `tests/unit_tests/test_text_splitters.py` | 4,375 | 123 <!-- [validation-certification-14]: ~120 corrected to exact 123; propagation miss from cert-13 (behavioral-intent.md:151 was updated but this table row was not); `grep -c "^def test_" test_text_splitters.py = 123` --> | Primary behavioral spec — **golden parity source** |
| `tests/unit_tests/test_html_security.py` | 130 | XXE / SSRF hardening | Security contract |
| `tests/unit_tests/conftest.py` | 86 | fixtures | — |
| `tests/integration_tests/test_text_splitter.py` | 160 | tiktoken/HF integration | Needs tokenizer |
| `tests/integration_tests/test_nlp_text_splitters.py` | 123 | spacy/nltk | DEFER-tier |
| `tests/integration_tests/test_compile.py` | 6 | import smoke | — |

Total test LOC **4,880** (1.33× production). Tests ARE the spec (CLAUDE.md /
protocol treats tests as first-class behavioral contracts).

## Boundary / off-by-one LOCKING tests (highest port priority → Red-Gate vectors)

These pin the exact behaviors flagged as PORT risk. Each becomes a pregolya
test vector with the SAME input and SAME expected output.

### `_merge_splits` overlap arithmetic
- **`test_merge_splits`** (L411) — `chunk_size=9, overlap=2`, `["foo","bar","baz"]`
  sep `" "` → `["foo bar","baz"]`. Locks the separator-in-total accounting.
- **`test_character_text_splitter`** (L184) — `size=7, overlap=3`,
  `"foo bar baz 123"` → `["foo bar","bar baz","baz 123"]`. Canonical overlap
  window.
- **`test_character_text_splitter_long`** (L211) / **`_short_words_first`** (L220)
  / **`_longer_words`** (L229) — front-pop behavior with tiny chunk sizes.
- **`test_character_text_splitter_handle_chunksize_equal_to_chunkoverlap`** (L248)
  — degenerate `size==overlap` guard (returns whole text).
- **`test_character_text_splitter_empty_doc`** (L193) / **`_separtor_empty_doc`**
  (L202) / **`_empty_input`** (L257) / **`_whitespace_only`** (L266) — empty /
  whitespace → `[]` (strip + empty→None path).

### keep_separator placement (start/end/none)
- **`test_character_text_splitter_keep_separator_regex`** (L278) → `["foo",".bar",".baz",".123"]`
- **`..._keep_separator_regex_start`** (L302) — same (start = default keep)
- **`..._keep_separator_regex_end`** (L326) → `["foo.","bar.","baz.","123"]`
- **`..._discard_separator_regex`** (L350) → `["foo","bar","baz","123"]`
- **`test_recursive_character_text_splitter_keep_separators`** (L371) — start vs
  end on `","`/`"."` cascade; locks capturing-group reassembly.
- **`test_character_text_splitter_discard_regex_separator_on_merge`** (L4329) —
  lookaround-not-reinserted path.

### add_start_index (code-point offset — the str.find hazard)
- **`test_create_documents_with_start_index`** (L478, parametrized ×2) — asserts
  exact `start_index` (0,4,8 and 0,6,12,18,24) AND
  `text[s_i:s_i+len(content)] == content`. **This is THE test that will catch a
  byte-index vs code-point-index bug.** Port with a multi-byte-char variant too.
- **`test_metadata_not_shallow`** (L489) — per-chunk metadata deep-copy.
- **`test_create_documents`** (L420) / **`_with_metadata`** (L433) — basic doc creation.

### Recursive iterative splitter
- **`test_iterative_text_splitter_keep_separator`** (L504) / **`_discard_separator`**
  (L517) — exact chunk lists on `"....5X..3Y...4X....5Y..."`; each asserts
  `len(chunk) <= chunk_size`.
- **`test_iterative_text_splitter`** (L548) — 18-chunk golden on multi-newline text.

### Token splitting (tiktoken-rs MAP verification)
- **`test_split_text_on_tokens`** (L3097) — `overlap=3, tokens_per_chunk=7`,
  ord/chr encode/decode → `["foo bar","bar baz","baz 123"]`. Deterministic,
  tokenizer-independent → port directly (no tiktoken needed).
- **`test_decode_returns_no_chunks`** (L3112) — decode→"" yields `[]` not `[""]`.
- Integration `test_text_splitter.py` — real tiktoken `gpt2`/`cl100k` counts;
  becomes tiktoken-rs parity vectors (verify `r50k_base` == `gpt2`).

### Language / code splitters (28 languages)
- One golden test per language: `test_python_code_splitter` (L787),
  `test_golang_*`, `test_rust_code_splitter` (L1279), `test_typescript_*`,
  `test_csharp_*` (+ `test_csharp_separators_no_java_keywords` L1142),
  `test_elixir_separators_no_while` (L1151), `test_cobol_*`, `test_haskell_*`,
  `test_visualbasic6_code_splitter` (L3587, lookaround regex),
  `test_powershell_*`, etc. Each pins the separator table → port all as vectors.
- **`test_jsx_splitter_separator_not_mutated_across_calls`** (L756) — the
  no-mutation regression; MUST have a Rust equivalent (call `split_text` twice,
  assert identical output).

### Markdown header splitters
- `test_md_header_text_splitter_1/2/3` (L1434+), `_preserve_headers_1/2`,
  `_fenced_code_block` (parametrized fences), `_fenced_code_block_interleaved`,
  `_with_invisible_characters` (isprintable filter), `_with_custom_headers`
  (lookaround pattern), `_mixed_headers`.
- Experimental: `test_experimental_markdown_syntax_text_splitter*` (8 tests incl.
  multi-file state-reset) — lock whitespace preservation + `Code` metadata.

### JSON splitter
- `test_split_json` (L3336), `_with_lists` (L3359), `_many_calls` (L3383),
  and 5 empty-dict edge cases (L3404-L3476). Lock size-based packing and the
  `json.dumps` shape dependency. [validation-exhaustive: corrected from "6
  empty-dict / L3404-3507"; grep confirms 8 total test_split_json* functions;
  L3507 is test_powershell_code_splitter_short_code, not a JSON test]

### HTML (require bs4/lxml)
- `test_html_header_text_splitter` (L2825, parametrized), `_additional_*`,
  `_no_headers_with_multiple_splitters`; HTMLSection `test_section_aware_*`
  (L3129), font-size / whitespace / duplicate-header; HTMLSemanticPreserving
  ~25 tests (L3642-4326) incl. `_preserved_elements_reverse_order` (L4257),
  `_replacement_order` (L4298), keep_separator ×5, media preservation,
  allow/deny lists, normalization. These become second-wave golden fixtures.

### Security (must-preserve contracts)
- `test_html_security.py` (130 LOC) — XXE / network-access denial for the lxml
  XSLT path. The Rust port MUST reproduce equivalent hardening (no entity
  resolution, no network, no DTD load).

### Import structure
- `test_no_heavy_imports_on_package_load` (L57), `test_lazy_getattr_*`,
  `test_missing_optional_dependency_raises_importerror` — Python lazy-import
  contracts. In Rust these map to **feature-gate compile tests**, not runtime.

## Coverage gaps (behaviors with weak/no test lock)
- **No explicit multi-byte / non-ASCII `len` test.** The code-point-vs-byte
  hazard is NOT directly locked by an existing test. **pregolya must ADD**
  non-ASCII vectors for `_merge_splits`, `add_start_index`, and the `""`
  separator (char split) — this is the top production-grade gap to close in the
  port (do NOT defer; per CLAUDE.md write the edge-case test now).
- `chunk_size` soft-exceed warning (`logger.warning`) is not asserted → map to a
  `tracing::warn!` event with a catalog row; add a test if the event is
  contractual.

## State Checkpoint
```yaml
pass: 5
artifact: test-inventory
package: langchain-text-splitters
status: complete
test_loc: 4880
red_gate_vector_families: 9
top_gap: non-ascii/code-point length vectors (ADD in port)
timestamp: 2026-07-12
```
