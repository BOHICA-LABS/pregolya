---
artifact: semport/core/test-inventory
project: ferrochain
port_target: langchain-core (P0)
analyzer_pass: 1
date: 2026-07-12
---

# langchain-core — Test Suite Map (test-as-spec)

Location: `.reference/langchain/libs/core/tests/`. Three roots: `unit_tests/`
(the spec corpus), `integration_tests/` (near-empty — no network in CI),
`benchmarks/` (perf, `pytest-benchmark`/`codspeed`).

**Totals:** 134 test files, **1,766 test functions**, ~59,935 unit test LOC,
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
- v3 protocol streaming (`chat_model_stream.py`, 1,441 LOC) has only 2 tests
  (`test_runnable_events_v3.py`) — **immature, expect churn**; treat as provisional.
