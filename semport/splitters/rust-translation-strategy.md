---
artifact: semport/splitters/rust-translation-strategy
project: ferrochain
port_target: langchain-text-splitters (1.1.2) → ferrochain-splitters
analyzer_pass: 5
date: 2026-07-12
note: strategy only — NO Rust code committed; signatures are illustrative sketches
crate: ferrochain-splitters (already reserved in CLAUDE.md initial crate family)
---

# langchain-text-splitters → Rust (ferrochain-splitters) Translation Strategy

Difficulty scale: 🟢 easy · 🟡 moderate · 🟠 hard · 🔴 very hard.

**Overriding constraint (D5):** this is PORT-class. The success criterion is
*byte-for-byte identical chunk output and start_index metadata* vs Python for
the same `(text, config)`. Every design choice below is subordinate to that.

## 0. The length-function abstraction — the whole ballgame 🟡

Python: `length_function: Callable[[str], int] = len`. `len(str)` = **Unicode
code point count**.

```rust
pub type LengthFn = Arc<dyn Fn(&str) -> usize + Send + Sync>;
// default:
fn default_length(s: &str) -> usize { s.chars().count() }   // NOT s.len()
```

- Default MUST be `chars().count()`. Using `str::len()` (bytes) diverges on any
  non-ASCII text.
- tiktoken / HF length functions are `LengthFn` closures over a `tiktoken-rs`
  `CoreBPE` or a `tokenizers::Tokenizer`.
- **All internal arithmetic** in `_merge_splits` calls `length_function`, incl.
  on the separator. Separator length is measured with the same fn (a tiktoken
  length fn measures `"\n\n"` as its token count, not 2). Preserve this.

## 1. `TextSplitter` core + `_merge_splits` — 🟠 (off-by-one epicenter)

The `_merge_splits` sliding window (base.py:167-209) is the single most
port-risk-laden function. It is NOT "greedy pack + fixed overlap"; the overlap
is realized by a **front-pop loop** with subtle separator accounting. Port it
statement-for-statement:

```
total measured with length_function; separator counted only when current_doc
has >1 element (join semantics). On exceeding chunk_size:
  - if total > chunk_size: emit logger.warning (must map to tracing::warn!)
  - flush current_doc via _join_docs (join + strip + empty→None)
  - pop from front while: total > chunk_overlap
      OR (next piece still won't fit AND total > 0)
    each pop: total -= length(front) + (sep_len if len(current_doc) > 1 else 0)
```

**SCoT for the port:**
- *Sequential:* measure piece → test-fit → (maybe flush + pop) → append → add
  to total.
- *Branch:* the fit test is `total + len_ + (sep_len if current_doc nonempty
  else 0) > chunk_size`. The `sep_len if len(current_doc) > 1 else 0` in the
  ADD step vs `> 0` (nonempty) in the FIT test is an asymmetry — reproduce
  exactly, do not "simplify."
- *Loop:* the pop `while` has a compound condition; both clauses must be kept.

Illustrative shape:
```rust
#[async_trait::async_trait]
pub trait TextSplitter: Send + Sync {
    fn split_text(&self, text: &str) -> Vec<String>;   // abstract
    fn config(&self) -> &SplitterConfig;
    fn merge_splits(&self, splits: impl Iterator<Item=String>, sep: &str) -> Vec<String> { /* port */ }
    fn create_documents(&self, texts: &[String], metadatas: Option<&[Metadata]>) -> Vec<Document> { /* port start_index */ }
}
```
Note: `split_text` is sync in Python and pure-CPU — keep it **sync** in Rust
(no async needed; contradicts nothing in CLAUDE.md's async-first rule, which
targets I/O). Only tokenizer *loading* (model download) is I/O.

**Locked-behavior tests to port as Red-Gate vectors:** `test_merge_splits`,
`test_character_text_splitter*` (11 variants), `test_iterative_text_splitter*`,
`test_create_documents_with_start_index` (parametrized). See test-inventory.

## 2. `create_documents` + `add_start_index` — 🟡 (off-by-one in offset search)

```
offset = index + previous_chunk_len - chunk_overlap
index  = text.find(chunk, max(0, offset))
```
- `text.find` returns a **code-point index in Python** (str.find is by code
  point). Rust `str::find` returns a **byte index**. To reproduce the exact
  integer stored in `start_index`, the port must compute a **code-point offset**
  (e.g. search on a `Vec<char>` or convert byte-index→char-index). The test
  asserts `text[s_i : s_i+len(content)] == content` where slicing is
  code-point-based. **This is a guaranteed silent bug if `str::find`'s byte
  index is stored.** 🟠 flag.
- `metadatas or [{}]*len` and `copy.deepcopy(metadata)` → clone per chunk
  (Python deep-copies; test `test_metadata_not_shallow` locks non-aliasing).

## 3. `RecursiveCharacterTextSplitter` — 🟠 (cascade + recursion)

```rust
fn split_recursive(&self, text: &str, separators: &[String]) -> Vec<String>
```
- Separator selection loop: pick `separators[-1]` as default, then the first
  `s` in the list that (a) is `""` (break, use it) or (b) `regex::search`
  matches in text; capture `new_separators = separators[i+1..]`.
- `keep_separator` default is `True` for this class (base default is `False`)
  — must set in constructor.
- The merge separator toggles: `"" if keep_separator else separator`
  (character.py:133). Reproduce.
- Recursion: pieces `< chunk_size` batch into `good_splits`; on hitting an
  oversized piece, flush the batch via merge, then either append the piece
  (no more separators) or recurse with `new_separators`.
- `_split_text_with_regex` keep-separator reassembly (character.py:64-88) with
  `re.split(f"({sep})", text)` capturing-group even/odd index arithmetic and
  the `len(splits_) % 2 == 0` tail handling — port exactly; the "start" vs
  "end" placement branches are locked by
  `test_character_text_splitter_keep_separator_regex_{start,end}` and
  `test_recursive_character_text_splitter_keep_separators`.

## 4. Language separator tables — 🟢 (mechanical, but exhaustive)

`get_separators_for_language` → a `match Language { .. }` returning
`&'static [&'static str]` (or owned Vec for the VB6 case that builds regex via
format). All 28 language arms are static data; copy verbatim. `from_language`
sets `is_separator_regex=true`. VB6 arm uses lookaround regex → those separators
need `fancy-regex` at match time. Trivial subclasses (`PythonCodeTextSplitter`,
`LatexTextSplitter`, `MarkdownTextSplitter`) = constructor presets.
`JSFrameworkTextSplitter`: build separator list **per call, in a local** (never
mutate `self._separators`) — locked by
`test_jsx_splitter_separator_not_mutated_across_calls`.

## 5. Token splitters — 🟡 (given tiktoken-rs MAP)

- `split_text_on_tokens` (base.py:498-526): straightforward index-window loop;
  guard `tokens_per_chunk > chunk_overlap` (raises). Drops empty decoded
  chunks (`if decoded:`), and the terminal `if cur_idx == len: break` prevents a
  trailing dup — locked by `test_split_text_on_tokens` and
  `test_decode_returns_no_chunks`.
- `Tokenizer` frozen dataclass → struct with `encode: Box<dyn Fn(&str)->Vec<u32>>`,
  `decode: Box<dyn Fn(&[u32])->String>`.
- `TokenTextSplitter`: wrap `tiktoken-rs` `CoreBPE`. Default encoding `"gpt2"` →
  `r50k_base`. `model_name` override → `bpe_for_model(model)`. Reproduce
  `allowed_special`/`disallowed_special="all"` (raise-on-disallowed) semantics.
- Newtype/redaction rules from CLAUDE.md do NOT apply (no secrets here).

## 6. Markdown header splitters — 🟠 (line state machine)

`MarkdownHeaderTextSplitter.split_text` is a line-by-line state machine with a
header stack, code-fence tracking (` ``` ` / `~~~`), `str.isprintable` filtering,
custom header patterns (regex with lookaround), and `strip_headers` /
`return_each_line`. Port the loop verbatim. `aggregate_lines_to_chunks` joins
same-metadata runs with `"  \n"` — that exact double-space-newline is
observable in output; preserve. `ExperimentalMarkdownSyntaxTextSplitter` uses
`splitlines(keepends=True)` (keep line terminators) — Rust has no direct
equivalent; implement a keepends line iterator. Metadata is `dict[str,str]` →
insertion-ordered map (`IndexMap`) because header metadata order is observable
in `Document` equality tests.

## 7. JSON splitter — 🟡 (serialization-shape parity)

`_json_size = len(json.dumps(data))`. As noted in dependency-disposition, the
port MUST serialize with Python's `json.dumps` shape: `", "` item separator,
`": "` key separator, `ensure_ascii=True` default in `split_text` (escapes
non-ASCII to `\uXXXX`). `serde_json`'s compact form differs → boundaries drift.
Implement a small Python-compatible JSON serializer for the SIZE measurement
(and for the emitted chunk strings, honoring the `ensure_ascii` flag).
`min_chunk_size` default = `max(max_chunk_size-200, 50)`. Recursive dict walk
preserves nested structure; `_set_nested_dict` builds paths. Locked by 9
`test_split_json*` tests incl. empty-dict edge cases.

## 8. HTML splitters — 🟠/🔴 (parser-dependent; second wave)

Back with `scraper` (html5ever). The DOM shape WILL differ from BeautifulSoup
`html.parser` on malformed input → this is the biggest non-tokenizer parity
risk. Port `_generate_documents` DFS (explicit stack, `reversed(children)`,
`dom_depth = parents count`, depth-scoped active-header eviction) and
`HTMLSemanticPreservingSplitter`'s placeholder-preservation + reverse-order
reinsertion. Preserve XXE hardening for the lxml path (or DEFER
HTMLSectionSplitter). Recommend: land HTMLHeaderTextSplitter first with a large
golden-fixture set; DEFER HTMLSectionSplitter (XSLT) and gate
HTMLSemanticPreservingSplitter's NLTK stopword feature.

## 9. Feature gating (replaces Python lazy `__getattr__`)

```
[features]
default = ["tiktoken"]
tiktoken = ["dep:tiktoken-rs"]
huggingface = ["dep:tokenizers"]
html = ["dep:scraper"]
sentence-transformers = ["huggingface", ...]   # deferred
nltk = [...]   # deferred
```

## Difficulty / risk summary

| Subsystem | Difficulty | Primary parity risk |
|---|---|---|
| length_function default | 🟡 | code points vs bytes vs graphemes — MUST be `chars().count()` |
| `_merge_splits` window | 🟠 | front-pop loop + asymmetric separator accounting |
| `add_start_index` offset | 🟠 | `str.find` byte-index vs code-point-index divergence |
| RecursiveCharacter cascade | 🟠 | keep-separator reassembly + recursion order |
| JSON size | 🟡 | `json.dumps` shape (`", "`/`": "`, ensure_ascii) vs serde_json |
| Markdown header FSM | 🟠 | code-fence + isprintable + `"  \n"` join + metadata order |
| HTML | 🟠/🔴 | html5ever DOM ≠ BeautifulSoup DOM on messy input |
| tiktoken splitters | 🟡 | disallowed_special="all" raise semantics |
| regex lookaround | 🟡 | `regex` crate can't; need `fancy-regex` for VB6 + custom md headers |

## Cross-cutting open design questions (candidate ADRs)

1. **ADR: length metric contract.** Confirm `chars().count()` default and
   define how tokenizer length fns are injected; define behavior for
   grapheme-cluster inputs (Python uses code points — we match Python).
2. **ADR: Python-compatible JSON serializer for RecursiveJsonSplitter** — build
   a `", "`/`": "` + ensure_ascii serializer vs risk serde_json divergence.
3. **ADR: HTML parser choice + parity strategy** — `scraper` vs `kuchikiki`;
   golden-fixture corpus; which HTML splitters ship in wave 1 vs deferred.
4. **ADR: regex engine** — adopt `fancy-regex` workspace-wide for the lookaround
   patterns, or hand-roll the ~3 lookaround separators/patterns.
5. **ADR: start_index code-point indexing** — mandate char-index arithmetic to
   match Python `str.find`.

## State Checkpoint
```yaml
pass: 5
artifact: rust-translation-strategy
package: langchain-text-splitters
crate: ferrochain-splitters
status: complete
timestamp: 2026-07-12
```
