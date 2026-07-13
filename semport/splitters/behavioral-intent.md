---
artifact: semport/splitters/behavioral-intent
project: ferrochain
port_target: langchain-text-splitters (1.1.2, shipped in langchain==1.3.13 corpus)
analyzer_pass: 5
date: 2026-07-12
disposition_class: PORT (D5 — behavior-critical; split boundaries must match Python byte-for-byte)
note: analysis only — NO Rust code committed; signatures are illustrative sketches
---

# langchain-text-splitters — Behavioral Intent

## What this package is for

Split large text (and structured text: code, markdown, HTML, JSON) into
bounded-size chunks suitable for embedding / retrieval / LLM context packing.
The **entire value** is deterministic, reproducible chunk boundaries: a
downstream vector store indexes these chunks, and retrieval parity with an
existing LangChain-Python corpus requires that ferrochain produce **identical
chunk strings and identical `start_index` metadata** for the same input and
config. This is why D5 marks it PORT, not MAP: a Rust chunking crate (e.g.
`text-splitter`) with "similar" behavior silently corrupts retrieval parity.

## The core behavioral model (byte-faithful port surface)

Two length-parameterized primitives underlie almost everything:

1. **`_merge_splits(splits, separator)`** (`base.py:167-209`) — the greedy
   chunk-packer. Given already-atomized pieces, it accumulates them into chunks
   of `_length_function`-measured size `<= chunk_size`, re-joining with
   `separator`, then slides a window back by popping from the front until the
   running `total <= chunk_overlap` (and the next piece fits). This is the
   **off-by-one epicenter** — see the "boundary semantics" section.

2. **`split_text_on_tokens(text, tokenizer)`** (`base.py:498-526`) — the
   token-window splitter. Encodes whole text to token IDs, then emits
   `decode(ids[start : start+tokens_per_chunk])` windows, advancing
   `start += tokens_per_chunk - chunk_overlap` each step. Distinct overlap
   model from `_merge_splits` (token-index window vs greedy front-pop).

Everything else is a **splitter strategy** that produces the atomized `splits`
list, then delegates to one of these two.

## Splitter taxonomy and boundary intent

### Character-based (the retrieval-critical core — MUST be byte-faithful)

- **`CharacterTextSplitter`** — split on a single separator (literal or regex),
  optionally keeping it at `start`/`end`, then `_merge_splits`. Lookaround
  regex separators (`(?=`, `(?<!`, `(?<=`, `(?!`) are detected so they are NOT
  re-inserted at merge time (`character.py:47-59`).
- **`RecursiveCharacterTextSplitter`** — the flagship. Tries a **cascade** of
  separators `["\n\n", "\n", " ", ""]` (default). For a given text, it picks
  the *first* separator that occurs, splits on it, and for any resulting piece
  still `>= chunk_size` it recurses with the *remaining* (later) separators.
  Pieces `< chunk_size` are batched and `_merge_splits`-packed. The empty
  string `""` separator is the terminal case: split into individual characters.
  `keep_separator` defaults to `True` here (unlike base's `False`).

### Language-aware code splitters (thin config over Recursive)

`RecursiveCharacterTextSplitter.from_language(lang)` +
`get_separators_for_language` (`character.py:182-801`) return hand-curated
separator cascades for **28 languages** (`Language` enum). `PythonCodeTextSplitter`,
`LatexTextSplitter`, `MarkdownTextSplitter` are trivial subclasses binding a
language's separator list. `JSFrameworkTextSplitter` (`jsx.py`) is the one with
runtime behavior: it regex-extracts opening component tags from the text and
appends them AFTER a fixed JS-separator list to form a per-call cascade (order:
user `_separators` → `js_separators` → `component_tags` → trailing
`["<>", "\n\n", "&&\n", "||\n"]`). JS keywords therefore have HIGHER cascade
priority than extracted component tags. The per-call list must NOT be persisted
back to `self._separators` across calls (locked by a regression test; see
test-inventory). [validation-exhaustive: corrected from "prepends"; jsx.py:103-108
builds `self._separators + js_separators + component_separators + trailing`]

### Token-based (tokenizer-dependency splitters)

- **`TokenTextSplitter`** — tiktoken-backed; encodes with `gpt2` encoding by
  default, windows via `split_text_on_tokens`.
- **`SentenceTransformersTokenTextSplitter`** — HuggingFace/ST tokenizer;
  strips start/stop special tokens (`_encode(text)[1:-1]`), enforces model max
  token limit.
- Base-class factory methods `from_tiktoken_encoder` /
  `from_huggingface_tokenizer` inject a token-counting `length_function` into
  ANY splitter (so a RecursiveCharacterTextSplitter can measure length in
  tiktoken tokens while still splitting on characters).

### NLP sentence splitters (heavy optional deps, lazy-imported)

`NLTKTextSplitter`, `SpacyTextSplitter`, `KonlpyTextSplitter` — tokenize into
sentences via the respective NLP lib, then `_merge_splits`. These are the
`_LAZY_SPLITTERS` deferred behind `__getattr__` to keep base import light.

### Structure-aware splitters (do NOT derive from TextSplitter)

- **`MarkdownHeaderTextSplitter`** — line-by-line state machine tracking a
  header stack; emits `Document`s tagged with the active header hierarchy as
  metadata. Handles fenced code blocks (``` and ~~~), custom header patterns
  (e.g. `**bold**` as level-1), non-printable-char stripping, `strip_headers`.
- **`ExperimentalMarkdownSyntaxTextSplitter`** — whitespace-preserving
  reimplementation; also extracts code-block language into `Code` metadata and
  splits on horizontal rules.
- **`HTMLHeaderTextSplitter`** — BeautifulSoup DFS over the DOM, associating
  text with an active-header dict **keyed by user-defined header name** (e.g., `"Header 1"`), value = `(text, numeric_level, dom_depth)`; depth lives in the value tuple and drives scope eviction (evict headers whose recorded `dom_depth > current`). `[validation-certification-9]` Yields per-element or
  aggregated `Document`s.
- **`HTMLSectionSplitter`** — lxml XSLT transform (font-size→header) +
  BeautifulSoup section slicing, then RecursiveCharacterTextSplitter.
- **`HTMLSemanticPreservingSplitter`** (`@beta`) — the heaviest: preserves
  tables/lists as placeholder tokens, converts links/images/video/audio to
  Markdown, optional stopword removal (NLTK) and text normalization, allow/deny
  tag filtering, then recursive-splits oversized chunks and re-inserts
  preserved elements in reverse order.
- **`RecursiveJsonSplitter`** — recursive dict walk packing key/value subtrees
  into `<= max_chunk_size` (by `len(json.dumps(...))`) JSON chunks; optional
  list→index-dict preprocessing.

## Ubiquitous language

| Term | Meaning |
|---|---|
| chunk | Output string, `length_function`-measured size `<= chunk_size` (soft — oversized indivisible pieces pass through with a `logger.warning`) |
| chunk_overlap | Characters/tokens shared between consecutive chunks (measured by `length_function`) |
| separator | Boundary string; literal or regex (`is_separator_regex`) |
| keep_separator | `False` / `True` / `"start"` / `"end"` — whether and where the separator survives the split |
| length_function | Pluggable size metric; default `len` (Python str char count = Unicode code points) |
| add_start_index | If set, each `Document` records the char offset of its chunk in the source, found via `text.find(chunk, offset)` |
| strip_whitespace | If set (default), joined chunk is `.strip()`ed; empty → dropped |
| Language | Enum of 28 languages, each mapping to a separator cascade |

## The byte-for-byte parity contract (why this is PORT class)

Retrieval parity requires that, for identical `(text, config)`, ferrochain
emits: (a) the same ordered list of chunk strings, and (b) the same
`start_index` values. The three highest-risk fidelity hazards are:

1. **`len` semantics.** Python `len(str)` counts **Unicode code points**, not
   UTF-8 bytes and not grapheme clusters. Rust `str::len()` is **bytes** and
   `.chars().count()` is code points. The port MUST use `chars().count()` as
   the default length function, or all multi-byte-text boundaries diverge.
2. **The `""` (empty) separator = split into characters.** `list(text)` in
   Python yields code points. Rust must split on `char` boundaries, not bytes.
3. **The `_merge_splits` sliding-window arithmetic** (see boundary section) —
   the exact `while total > chunk_overlap or (...)` pop loop and the
   `separator_len if len(current_doc) > 1 else 0` accounting must be reproduced
   operation-for-operation.

## Scale

Production code: **3,671 LOC** across 13 modules (largest: `html.py` 1,099,
`character.py` 801, `base.py` 526, `markdown.py` 482). Tests: **4,880 LOC**
(unit `test_text_splitters.py` alone is 4,375 LOC / ~120 tests). Single external
runtime dep in the base import path: `langchain-core` (for `Document` /
`BaseDocumentTransformer`). All tokenizer/NLP/HTML deps are optional and
lazy-imported.

## State Checkpoint
```yaml
pass: 5
artifact: behavioral-intent
package: langchain-text-splitters
status: complete
timestamp: 2026-07-12
```
