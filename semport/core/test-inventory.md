---
artifact: semport/core/test-inventory
project: pregolya
port_target: langchain-core (P0)
analyzer_pass: 1
date: 2026-07-12
---

# langchain-core — Test Suite Map (test-as-spec)

Location: `.reference/langchain/libs/core/tests/`. Three roots: `unit_tests/`
(the spec corpus), `integration_tests/` (near-empty — no network in CI),
`benchmarks/` (perf, `pytest-benchmark`/`codspeed`).

**Totals:** 135 test files <!-- [validation-exhaustive]: original said 134; `find tests/unit_tests -name "*.py" ! -name "__init__.py" | wc -l` = 135. Delta +1. -->, **1,766 test functions** <!-- [validation-exhaustive]: grep-based count of `def test_` yields 1,761; the 5-count delta is likely from pytest parametrize expansion counted differently at analysis time; functionally negligible -->, 59,322 unit test LOC <!-- [validation-certification-11]: corrected from ~59,935; propagation of same delta confirmed in core/ANALYSIS-STATE.md and core/module-inventory.md this pass -->,
5 syrupy snapshot files (73 snapshots).

Test infra: `pytest` + `pytest-asyncio` (`asyncio_mode=auto` — bare `async def test_`
is a coroutine test), `syrupy` (`.ambr` snapshots), `freezegun` (time),
`blockbuster` (detects blocking calls in async), `pytest-socket` (blocks network),
`responses` (HTTP mocking), `pytest-xdist` (parallel).

## Test counts per subsystem

| Subsystem | Files | Tests | LOC | Notes |
|---|---|---:|---:|---|
| runnables | 13 | ~275 | ~15,447 | Largest. `test_runnable.py` alone 119 tests / 6,005 LOC |
| messages | 3 (+8 translators) | ~181 | ~6,147 | `test_utils.py` 145; block_translators 8 files/~29 |
| tools (`test_tools.py`) | 1 | 140 | 4,065 | Single largest test file by tests |
| language_models | 13 | ~270 | ~8,017 | chat_models 77, llms 18, top-level 175 |
| prompts | 11 | 164 | 4,373 | + 10 snapshots |
| output_parsers | 8 | 75 | 3,104 | streaming/jsonpatch diffs |
| utils | 14 | 142 | 3,974 | mustache, json, merge, function_calling |
| indexing | 5 | 61 | 3,373 | index() dedup/record-manager |
| load/serde | 4 | ~87 | ~1,685 | serializable 58 + secrets 28 |
| tracers | 8 | 70 | 2,622 | events/log-stream tracers |
| callbacks | 6 | 20 | 833 | manager/handler dispatch |
| _api | 4 | ~? | 1,081 | deprecation/beta decorators |
| _security (ssrf) | 2 | 54 | 665 | SSRF policy + transport |
| vectorstores | 3 | 32 | 681 | in-memory + retriever |
| example_selectors | 4 | 18 | 363 | length + semantic |
| chat_history | 1 | ~ | 110 | in-memory history |
| stores | 1 | 8 | 129 | KV store |
| rate_limiters | 1 | ~ | 110 | token bucket |
| caches | 1 | ~ | 119 | in-memory cache |
| documents | 3 | 5 | 54 | Document basics |
| top-level (test_messages, test_outputs, etc.) | 13 | ~? | 6,778 | test_messages.py 36, test_pydantic_serde |

## Strongest spec candidates (rank-ordered for the Rust port)

1. **`runnables/test_runnable.py`** (119 tests, 6,005 LOC) + snapshots
   `__snapshots__/test_runnable.ambr` (42). Covers invoke/batch/stream/transform,
   `|` composition, RunnableParallel concurrency, passthrough/assign/pick,
   binding, configurable fields, `with_retry`/`with_fallbacks`, input/output schema
   inference, `as_tool`, `map`. **The canonical Runnable behavioral contract.**
   The `.ambr` snapshots freeze serialized Runnable graphs + JSON schemas — port these
   as golden fixtures.

2. **`runnables/test_runnable_events_v2.py`** (36) + `_v1.py` (20). The definitive
   **streaming-events ordering spec**: exact `astream_events` sequence
   (`on_chain_start`→`on_llm_start`→`on_llm_new_token`*→…) for nested chains. Port as
   ordered-event assertions. v3 (`_v3.py`, 2) is a thin placeholder for the new
   `langchain_protocol` content-block stream — nascent, watch for churn.

3. **`messages/test_utils.py`** (145 tests, 3,106 LOC). Locks `trim_messages`,
   `filter_messages`, `merge_message_runs`, `convert_to_messages`,
   `convert_to_openai_messages`. Pure functions with tight I/O — **highest-ROI
   test-as-spec target**, translates almost 1:1 to Rust unit tests.

4. **`test_tools.py`** (140 tests, 4,065 LOC). `@tool` inference (hints/docstring),
   args_schema validation, `_parse_input` (str/dict/ToolCall), ToolMessage output,
   injected args, error handling (`handle_tool_error`), async parity. Big and precise.

5. **`load/test_serializable.py`** (58) + `test_secret_injection.py` (28) +
   `test_pydantic_serde.py`. The **serialization round-trip + secret-redaction spec**.
   Golden `lc`-JSON. Directly informs the Rust serde-tagged-enum design and the
   `Serializable`→`serde` mapping. Highest priority for the serde ADR.

6. **`prompts/test_chat.py` + `test_prompt.py`** with `.ambr` snapshots (10). Freeze
   the serialized template shape and the format() outputs across f-string/mustache/
   jinja2. Port snapshots as golden fixtures.

7. **`messages/block_translators/test_*.py`** (8 files: openai, anthropic,
   google_genai, bedrock, bedrock_converse, groq, langchain_v0, registration; ~29
   tests). The **content-block normalization spec** — provider format ↔ standard
   blocks. Essential once partner crates are ported; defines `.content_blocks`
   behavior per provider. These are the acceptance tests for the ContentBlock enum.

8. **`messages/test_ai.py`** (16) + `test_messages.py` (36). AIMessage/chunk
   concatenation, tool_call accumulation from chunks, usage_metadata summing —
   validates the `merge_dicts`/`add_ai_message_chunks` reducers (critical for streaming).

9. **`runnables/test_config.py`** (21). RunnableConfig merge/propagation via ContextVar,
   recursion_limit, max_concurrency. Defines the config-threading contract.

10. **`indexing/test_*.py`** (61 tests, 3,373 LOC). The `index()` dedup/record-manager
    contract (source-id grouping, cleanup modes incremental/full/scoped_full). Larger
    than expected — flag if indexing is in P0 scope (may be deferrable to P1).

## Snapshot inventory (golden fixtures to port verbatim)

| File | Snapshots | Freezes |
|---|---:|---|
| runnables/`test_runnable.ambr` | 42 | Serialized Runnable graphs + input/output JSON schemas |
| runnables/`test_graph.ambr` | 17 | Graph node/edge structure + ascii/mermaid renders |
| runnables/`test_fallbacks.ambr` | 4 | Fallback runnable serialization |
| prompts/`test_chat.ambr` | 5 | ChatPromptTemplate serialization/format |
| prompts/`test_prompt.ambr` | 5 | PromptTemplate serialization/format |

## Coverage gaps / weak spots

- `test_retrievers.py` is **0 LOC** (empty) — retriever behavior is only implicitly
  covered via runnable/tracing tests. Low direct spec coverage; rely on source.
- `documents/` has just 5 tests — Document is simple, low risk.
- `integration_tests/` effectively empty (network-gated); no live-provider spec in core.
- `_compat_bridge.py` (844 LOC, v0/v1 output-version bridging) coverage is spread
  across language_models + block_translator tests rather than a dedicated file — verify
  coverage before porting; it is subtle.
- v3 protocol streaming (`chat_model_stream.py`, 1,441 LOC) has **107 dedicated tests** across 3 files: `test_chat_model_v3_stream.py` (41 tests / 1,482 LOC — tests `stream_events(version="v3")` sync+async and `ChatModelStream`), `test_chat_model_stream.py` (42 tests / 904 LOC — tests `ChatModelStream`/`AsyncChatModelStream` projections), `test_chat_model_streamer.py` (24 tests / 484 LOC). `test_runnable_events_v3.py` (2 tests / 23 LOC in runnables/) tests v3 from the `Runnable.stream_events` perspective. **Substantial coverage — NOT immature.** The prior "only 2 tests — immature, treat as provisional" was wrong; `test_chat_model_v3_stream.py` was missed. `[validation-certification-9]`

---

# Pass 7 deepening (2026-07-12) — count corrections & verifications

## C-2 CONTRADICTION — `_compat_bridge.py` DOES have a dedicated test file

The "Coverage gaps" note above stated coverage "is spread across language_models +
block_translator tests rather than a dedicated file." **This is wrong.** There is a dedicated
spec: `tests/unit_tests/language_models/test_compat_bridge.py` — **43 tests, 1,403 LOC**. It
directly exercises the 3 bridge functions (`finalize_tool_call_chunk`, `chunks_to_events`,
`message_to_events`) that convert core message chunks ↔ `langchain_protocol` `MessagesData`
events. The subsystem is **well-covered**, not a gap. This raises the language_models line in
the count table: add `test_compat_bridge.py` (43 / 1,403) — the earlier `language_models`
subtotal (~270 tests / ~8,017 LOC) already includes it in the directory glob, but it was not
called out as a strong spec. **Promote it** into the strong-spec list for the v0↔v1 bridge port.

## C-3 CORRECTION — block_translators file/test counts and architecture

- **Source**: 8 provider translator modules + `__init__.py` (Pass 1 module-inventory said "7
  files"; test-inventory said "8"): `anthropic`, `bedrock`, `bedrock_converse`, `google_genai`,
  **`google_vertexai`** (new — not in Pass 1's list), `groq`, `langchain_v0`, `openai`. There is
  **no `registration.py` source module** — registration lives in `__init__.py`
  (`PROVIDER_TRANSLATORS` dict + `register_translator()` + `_register_translators()`).
- **Tests** (`tests/unit_tests/messages/block_translators/`, 8 files): `test_anthropic` 3,
  `test_bedrock` 3, `test_bedrock_converse` 3, `test_google_genai` 5, `test_groq` 7,
  `test_langchain_v0` 2, `test_openai` 5, `test_registration` 1 = **29 tests**. `test_registration`
  is a completeness guard: it walks the package with `pkgutil` and fails if any translator module
  (except `_`-private and `langchain_v0`) is missing from `PROVIDER_TRANSLATORS`. `google_vertexai`
  has a registered translator but **no dedicated test file** (coverage gap — flag for the port).

## Scope note — "trim_messages 145 tests" was file-total, not trim-specific

`messages/test_utils.py` (145 tests total) decomposes as: **trim_messages 21**, convert* 33,
merge* 6, filter* 3, and ~82 other (`convert_to_openai_messages`, `get_buffer_string`,
`count_tokens_approximately`, coercion). Still the single richest message spec, but the "145
trim tests" framing in the deepening checklist over-counted trim's dedicated coverage (21).

## Verified counts (unchanged — Pass 1 was correct)

- **indexing**: 61 tests across 5 files (`test_indexing` 45, `test_in_memory_record_manager` 9,
  `test_hashed_document` 4, `test_in_memory_indexer` 2, `test_public_api` 1), **3,373 test LOC** —
  all confirmed. See rust-strategy Pass 7 deepening for the P1 scope ruling.
- **event v2**: `test_runnable_events_v2.py` 36 tests / 2,918 LOC — confirmed; default version
  `v2` is itself test-asserted (`test_default_is_v2`).
