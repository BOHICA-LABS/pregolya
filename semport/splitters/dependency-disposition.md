---
artifact: semport/splitters/dependency-disposition
project: pregolya
port_target: langchain-text-splitters (1.1.2)
analyzer_pass: 5
date: 2026-07-12
d5_alignment: text-splitters is PORT-class; dependency dispositions below classify each transitive dep
---

# langchain-text-splitters — Dependency Disposition (per D5)

Disposition vocabulary: **PORT** (reimplement behavior in Rust) · **MAP** (adopt
an existing Rust crate as the behavioral substitute, with parity tests) ·
**DEFER** (feature-gate; not in first pregolya wave) · **DROP** (not ported).

## Runtime dependencies (base import path)

| Python dep | Version pin | Used for | Disposition | Rust target | Evidence / risk |
|---|---|---|---|---|---|
| `langchain-core` | >=1.4.7,<2 | `Document`, `BaseDocumentTransformer`, `_api.beta/deprecated`, `_security._transport.ssrf_safe_client` (html url fetch, deprecated) | PORT (internal) | `pregolya-core::Document` | Already in scope of core semport; splitters depend only on `Document` struct + transformer trait. `ssrf_safe_client` used only by the deprecated `split_text_from_url` → DROP that method. |
| Python `re` | stdlib | separator regex, keep-separator split, markdown header patterns | MAP + PARTIAL PORT | `regex` crate + `fancy-regex` | `regex` crate lacks lookaround/backreferences. Lookaround IS used: VB6 separators (`\n(?!End\s)...`), and `MarkdownHeaderTextSplitter._is_custom_header` builds `^{sep}(?!{sep})(.+?)(?<!{sep}){sep}$`. **Must use `fancy-regex` (backtracking, supports lookaround) or hand-roll these few patterns.** Character-splitter separators are lookaround-free → plain `regex` is fine there. |
| Python `json` | stdlib | `RecursiveJsonSplitter` size via `len(json.dumps(data))` | MAP (careful) | `serde_json` | **Parity hazard:** `json.dumps` default separators are `", "` and `": "` (spaces) and `ensure_ascii=True` escapes non-ASCII as `\uXXXX`. `serde_json::to_string` uses NO spaces and emits raw UTF-8. Size measurements will diverge unless a Python-compatible serializer (with `", "`/`": "` separators and ascii-escaping) is used. This directly changes chunk boundaries → PORT the serialization shape, do not use default serde_json. |

## Optional / lazy tokenizer dependencies

| Python dep | Used by | Disposition | Rust target | Evidence |
|---|---|---|---|---|
| `tiktoken` (>=0.8,<1) | `TokenTextSplitter`, `from_tiktoken_encoder` | **MAP** | **`tiktoken-rs` 0.12.0** | crates.io: 11.6M downloads. docs.rs confirms `r50k_base` (= LangChain default `"gpt2"`), `p50k_base`, `cl100k_base`, `o200k_base`, plus `bpe_for_model()` (replaces `encoding_for_model`). Special-token handling: `encode(text, &allowed_special)` maps to LangChain's `allowed_special`. **Gap:** LangChain default `disallowed_special="all"` RAISES on encountering any special token; tiktoken-rs' `encode` with a given allowed set has different error semantics — must reproduce the "raise on disallowed" contract or accept divergence on adversarial inputs. The default `gpt2` encoding maps cleanly to `r50k_base`. HIGH-confidence MAP. |
| `transformers` (HF tokenizers) | `from_huggingface_tokenizer` (`len(tokenizer.tokenize(text))`) | MAP | `tokenizers` crate (HF, Rust-native) | HF `tokenizers` is itself a Rust crate; `.encode(...).get_tokens().len()` reproduces `len(tokenize(text))`. Feature-gated. |
| `sentence-transformers` / `torch` | `SentenceTransformersTokenTextSplitter` | **DEFER** | (feature `sentence-transformers`, later wave) | Pulls a torch-scale ML runtime. Only the tokenizer (`_model.tokenizer`, `[1:-1]` special-token strip, `max_seq_length`) is used for splitting — but model load requires the full ST stack. Defer to a later wave; when built, back it with `tokenizers` + a model-config loader, not torch. |

## Optional / lazy NLP sentence-splitter dependencies

| Python dep | Used by | Disposition | Rust target | Evidence |
|---|---|---|---|---|
| `nltk` (>=3.9) | `NLTKTextSplitter`, HTML stopword removal | **DEFER/MAP** | no drop-in; `punkt`-equivalent needed | NLTK `sent_tokenize` (Punkt) and `span_tokenize` have no faithful Rust port. Sentence segmentation crates (`unicode-segmentation` sentence boundaries, `srx`) are NOT Punkt-equivalent → different boundaries. DEFER; if required, DTU-clone Punkt behavior with parity fixtures. Stopword removal in HTMLSemanticPreservingSplitter → `stop-words` crate (MAP) behind a feature. |
| `spacy` (>=3.8) + `en_core_web_sm` | `SpacyTextSplitter` | **DEFER** | none | Full spaCy pipeline (statistical sentencizer / model download). No Rust equivalent with parity. Defer. |
| `konlpy` (Kkma) | `KonlpyTextSplitter` (Korean) | **DEFER** | none | JVM-backed Korean morphological analyzer. No Rust equivalent. Lowest priority. |

## Optional HTML/XML dependencies

| Python dep | Used by | Disposition | Rust target | Evidence / risk |
|---|---|---|---|---|
| `beautifulsoup4` (`bs4`) w/ `html.parser` | `HTMLHeaderTextSplitter`, `HTMLSectionSplitter`, `HTMLSemanticPreservingSplitter` | **MAP (parity-risky)** | `scraper` (html5ever) or `kuchikiki` | **The parser is behavior-defining.** BeautifulSoup with the stdlib `html.parser` has specific whitespace, tag-recovery, and `.children`/`.next_elements`/`.parents` traversal semantics. html5ever normalizes per the HTML5 spec (implied tbody, etc.) and will produce a DIFFERENT DOM for malformed input. The splitter logic (DFS via `stack`, `dom_depth = len(list(node.parents))`, `_find_all_strings(recursive=False)`) must be reproduced AND the tree shape must match. HIGH divergence risk on real-world messy HTML → extensive golden fixtures required. |
| `lxml` (+ XSLT) | `HTMLSectionSplitter.convert_possible_tags_to_header` | **DEFER/MAP** | `libxml`/`xrust` (immature) | lxml XSLT transform (font-size→header) with `XSLTAccessControl.DENY_ALL` and XXE-hardened parsers. Rust XSLT support is weak (`xrust` limited, or FFI to libxml2). Consider DEFER HTMLSectionSplitter, or port the specific XSLT (`xsl/converting_to_header.xslt`) logic imperatively. Security note: the Python code hardens against XXE (`resolve_entities=False, no_network=True, load_dtd=False`) — the Rust port MUST preserve equivalent hardening. |

## Build/test-only (not ported)

`hatchling`, `ruff`, `ty`, `pytest*`, `freezegun`, `jupyter`, `lxml-stubs`,
`types-requests` — DROP (Rust uses cargo + nextest).

## Disposition summary

- **First-wave PORT (pure, byte-faithful):** base, character (incl. all 28
  language separator tables), python, latex, markdown (both header splitters),
  json, jsx. No external Rust deps except `regex`/`fancy-regex`.
- **First-wave MAP:** tiktoken → **tiktoken-rs 0.12** (HIGH confidence);
  huggingface → `tokenizers`.
- **Second-wave MAP (parity fixtures mandatory):** HTML splitters → `scraper`.
- **DEFER (feature-gated, later):** sentence-transformers, nltk, spacy, konlpy,
  HTMLSectionSplitter (lxml/XSLT).
- **DROP:** `split_text_from_url` (deprecated in Python since 1.1.2, removal
  2.0.0 — do not port; pregolya callers fetch HTML themselves).

## State Checkpoint
```yaml
pass: 5
artifact: dependency-disposition
package: langchain-text-splitters
status: complete
map_high_confidence: [tiktoken-rs, huggingface-tokenizers]
defer: [sentence-transformers, nltk, spacy, konlpy, lxml-xslt]
timestamp: 2026-07-12
```
