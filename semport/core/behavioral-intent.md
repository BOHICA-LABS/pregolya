---
artifact: semport/core/behavioral-intent
project: ferrochain
port_target: langchain-core (P0)
analyzer_pass: 1
date: 2026-07-12
evidence_base: source + unit tests (test-as-spec)
---

# langchain-core — Behavioral Intent by Subsystem

Confidence tags: **[T]** verified against a unit test, **[S]** read from source,
**[I]** inferred. Line cites are relative to
`.reference/langchain/libs/core/langchain_core/` (source) or
`.reference/langchain/libs/core/tests/unit_tests/` (tests).

---

## 1. Runnables (LCEL) — the execution protocol

**What it does.** Defines `Runnable[Input, Output]` (ABC), the universal
"unit of work" with an invoke/batch/stream/transform surface, plus declarative
composition. `runnables/base.py:133`.

**The contract (surface).** Only **`invoke`** is `@abstractmethod`
(`base.py:873`). Everything else has a default implementation derived from it:
- `ainvoke` → default runs `invoke` in a thread executor via `run_in_executor` [S].
- `batch`/`abatch` → default map `invoke` across inputs using a thread pool bounded
  by `config["max_concurrency"]`; `batch_as_completed`/`abatch_as_completed` yield
  `(index, output)` as each finishes [S] `base.py:919,1054,970,1103`.
- `stream`/`astream` → default yield a **single** chunk equal to `invoke` output
  (non-streaming fallback) [S] `base.py:1182`.
- `transform`/`atransform` → consume an input *iterator* and produce an output
  iterator (used to chain streaming); default buffers input then calls stream [S].
- `astream_log` (`base.py:1225`) and `astream_events` (v1/v2, `base.py:1331`) attach
  a streaming tracer and emit run-tree deltas / typed events.

**Invariant — sync/async duality.** A subclass implements *either* sync or async and
gets the other for free (async wraps sync in an executor; sync of an async-native
Runnable is unusual). **Every method threads an optional `RunnableConfig`.** [S]

**Composition semantics [T].**
- `a | b` builds `RunnableSequence`; `__or__`/`__ror__` coerce dicts→`RunnableParallel`
  and callables→`RunnableLambda` (`base.py:628,3063`). Sequences flatten (a|b|c is one
  RunnableSequence with `first`, `middle[]`, `last`).
- `RunnableParallel` runs branches **concurrently** on the same input and returns a
  dict keyed by branch name; streaming interleaves branch outputs into an `AddableDict`.
- **Streaming through a sequence:** output of one step is `transform`-fed to the next
  so tokens flow end-to-end where every step is transform-capable (e.g.
  `prompt | model | StrOutputParser` streams tokens). Verified extensively in
  `runnables/test_runnable.py` (119 tests) and events v2 (`test_runnable_events_v2.py`,
  36 tests).
- **Batch ordering guarantee:** `batch` returns outputs in input order even though
  execution is concurrent; `batch_as_completed` returns `(idx, out)` out of order but
  idx-tagged. [T] `runnables/test_runnable.py`.

**Standard modifiers (all return a new Runnable) [S/T].**
`.bind(**kwargs)` (partial kwargs → `RunnableBinding`), `.with_config(config)`,
`.with_retry(...)` (tenacity-backed `RunnableRetry`), `.with_fallbacks([...])`
(`RunnableWithFallbacks`), `.with_types(...)`, `.with_listeners`/`.with_alisteners`
(lifecycle hooks via root-listener tracers), `.map()` (`RunnableEach`),
`.assign(...)`/`.pick(...)` (passthrough), `.as_tool(...)` (Runnable→BaseTool),
`.configurable_fields(...)` / `.configurable_alternatives(...)`.

**Configurable Runnables.** `configurable_fields`/`configurable_alternatives` expose
attributes that can be overridden at call time via `config["configurable"][id]`;
resolution happens in `runnables/configurable.py`. [T] `test_configurable.py` (5).

**Error behavior.** Errors propagate through the call; callbacks receive
`on_chain_error`. `RunnableWithFallbacks` catches configured exception types and tries
the next runnable in order; if all fail, raises the last (or a group). `.with_retry`
uses tenacity stop/wait policy. [T] `test_fallbacks.py` (10), `test_runnable.py`.

**Config propagation (RunnableConfig).** `config.py:57`. A `TypedDict(total=False)`
with keys: `tags`, `metadata`, `callbacks`, `run_name`, `max_concurrency`,
`recursion_limit` (default **25**), `configurable`, `run_id`. Propagation rules:
- Child config is **merged** from parent, not replaced (`merge_configs`): `tags` and
  `metadata` accumulate, `callbacks` inherit, `run_name`/`run_id` are consumed once
  (not inherited to children).
- Propagation happens implicitly through a **`ContextVar`**
  (`var_child_runnable_config`, `config.py:174`) so nested Runnables inherit config
  without explicit passing; `ensure_config()` reads the contextvar.
- `recursion_limit` guards against infinite Runnable recursion (raises on exceed) [T].
- LangSmith tracing metadata is derived from scalar `configurable` values
  (`_get_langsmith_inheritable_metadata_from_config`), excluding `api_key`.
Evidence: `runnables/test_config.py` (21 tests), `config.py`.

**Graph introspection.** `get_graph()` builds a `Graph` of nodes/edges; renderable as
ascii/mermaid/png. Snapshot-tested (`test_graph.ambr`, 17 snapshots) — **the graph
shape is a frozen behavioral contract**. [T] `test_graph.py` (21).

---

## 2. Messages + Content Blocks

**What it does.** Typed representation of chat I/O and the **v1 standard content
block** system (the headline langchain-core 1.0 addition).

**Message hierarchy [S].** `BaseMessage(Serializable)` `messages/base.py:93` with
fields: `content: str | list[str | dict]`, `additional_kwargs: dict`,
`response_metadata: dict`, `type: str`, `name: str|None`, `id: str|None`
(`coerce_numbers_to_str=True`). `model_config = extra="allow"`. Subtypes set a fixed
`type` literal: `AIMessage`("ai"), `HumanMessage`("human"), `SystemMessage`("system"),
`ToolMessage`("tool"), `FunctionMessage`("function", legacy), `ChatMessage`
(arbitrary role), `RemoveMessage` (a control token for history editing).

**AIMessage specifics [S].** `messages/ai.py:160` adds `tool_calls: list[ToolCall]`,
`invalid_tool_calls: list[InvalidToolCall]`, `usage_metadata: UsageMetadata | None`.
`lc_attributes` forces tool_calls/invalid_tool_calls into serialization even though
derived. `UsageMetadata` = input/output/total tokens + optional
`input_token_details`/`output_token_details` (audio, cache_read, cache_creation,
reasoning).

**Content blocks [S] `messages/content.py`.** A closed set of TypedDicts, each with a
`type` discriminant literal, unioned into `ContentBlock`:
- Text/reasoning: `TextContentBlock`("text", + `annotations: [Citation|NonStandard]`),
  `ReasoningContentBlock`("reasoning").
- Tools: `ToolCall`("tool_call"), `ToolCallChunk`("tool_call_chunk"),
  `InvalidToolCall`("invalid_tool_call"), `ServerToolCall`/`ServerToolCallChunk`/
  `ServerToolResult`.
- Multimodal `DataContentBlock`: `ImageContentBlock`("image"),
  `VideoContentBlock`("video"), `AudioContentBlock`("audio"),
  `PlainTextContentBlock`("text-plain"), `FileContentBlock`("file"). Each carries one
  of `url` / `base64` / `file_id` + `mime_type`.
- `NonStandardContentBlock`("non_standard", holds provider `value: dict`).
- `KNOWN_BLOCK_TYPES` set (`content.py:856`) governs standard-vs-provider dispatch.
- Every block allows an `extras: dict` for provider metadata (forward path: PEP 728
  `extra_items=Any`).

**Key invariant — `.content_blocks` is a lazy view, not stored state [S/T].**
`content` remains the string/list source of truth; `.content_blocks`
(`base.py:200`, overridden `ai.py:243`) *derives* normalized blocks on access via a
pipeline of best-effort translators (v0 multimodal → openai → anthropic → genai →
converse). If `response_metadata["output_version"]=="v1"` and content is a list, it's
assumed already-normalized (short-circuit). If `model_provider` is set, a
provider-specific translator runs first. Unknown dict types with a `source_type` key
are treated as v0 and wrapped `non_standard`. Evidence: block_translators tests (8
files, ~30 tests), `test_messages.py` (36).

**Streaming / chunk concatenation [S/T].** `BaseMessageChunk.__add__`
(`base.py:412`) concatenates chunks: `content` via `merge_content`,
`additional_kwargs`/`response_metadata` via `merge_dicts`. `AIMessageChunk`
(`ai.py:418`) additionally merges `tool_call_chunks` by index and re-parses partial
JSON args → progressively-materialized `tool_calls`. `add_ai_message_chunks`
(`ai.py:652`) is the reduce function; sums `usage_metadata`.
- **`merge_content` rules** (`base.py:366`): str+str concat; str+list prepends;
  list+list merges by `merge_lists` (index-aware, dedup by `index`).
- **`merge_dicts` rules** (`utils/_merge.py:6`): None-left takes right; str values
  **concatenate** except identity keys (`id`, `output_version`, `model_provider`,
  `lc_`-prefixed `index` are last-wins/keep); int values **sum** except
  `index`/`created`/`timestamp` (last-wins); dict recurses; list uses `merge_lists`;
  **type mismatch on same key raises `TypeError`**. This is an exactly-specified,
  test-locked reducer — a critical porting target.

**Message utilities [T] `messages/utils.py` (2,406 LOC, 145 tests).**
`trim_messages` (token/message-count budgeting, first/last strategy, keep system,
`allow_partial`), `filter_messages` (by type/id/name include/exclude),
`merge_message_runs` (coalesce consecutive same-type messages),
`convert_to_messages` (loose dict/tuple/str → Message coercion),
`convert_to_openai_messages`, `get_buffer_string`, `message_chunk_to_message`.
`test_utils.py` (145) is the single richest message spec.

**Serialization guarantee.** Messages are `is_lc_serializable()==True` with fixed
namespace `["langchain","schema","messages"]` (`base.py:191`) — deserialization must
map that legacy namespace regardless of the actual Python module. `message_to_dict`
= `{"type": msg.type, "data": msg.model_dump()}`.

---

## 3. Language models

**What it does.** Provider-agnostic model interfaces that are Runnables.

**`BaseChatModel(BaseLanguageModel[AIMessage])` `chat_models.py:272` [S].**
Public surface: `invoke`/`ainvoke` (return `AIMessage`), `stream`/`astream` (yield
`AIMessageChunk`), `generate`/`agenerate` (batch prompts → `LLMResult`),
`generate_prompt`, `bind_tools`, `with_structured_output`. Provider subclasses
implement the abstract **`_generate`** (and optionally `_agenerate`, `_stream`,
`_astream`). Input is `LanguageModelInput` = str | list[Message] | PromptValue.

**Caching contract [S].** `_generate_with_cache`/`_agenerate_with_cache`
(`chat_models.py:1864`) wrap `_generate`: if a cache is configured (per-instance or
global `llm_cache`), look up by `(prompt, llm_string)`; on hit return cached
generations and skip provider call. Streaming bypasses cache unless disabled.

**Streaming semantics [S/T].** If a subclass overrides `_stream`, `stream()` yields
`AIMessageChunk`s and emits `on_llm_new_token`; else it falls back to yielding the
full result as one chunk. `astream` similarly. **Three stream-event protocols coexist:**
`astream_events(version="v1")`, `"v2"` (tracers/event_stream.py), and the new
`stream_events`/`astream_events(version="v3")` returning a `ChatModelStream`
(chat_model_stream.py, 1,441 LOC) that emits **content-block protocol events**
(start/delta/finish) from `langchain_protocol`. This v3 stream exposes typed
projections `.text/.reasoning/.tool_calls/.usage/.output` with replay-buffer
semantics (multiple consumers). [S] chat_model_stream.py header.

**`bind_tools` [S].** Attaches tool schemas (converted via
`utils/function_calling.convert_to_openai_tool`) to the model; base raises
`NotImplementedError` (provider must implement). Returns a `_ChatModelBinding`.

**`with_structured_output` [S] `chat_models.py:2357`.** Returns a Runnable that emits
schema-shaped output. `schema` may be a Pydantic class, TypedDict, JSON schema, or
OpenAI tool dict. If Pydantic → output is a validated instance; else a dict.
`include_raw=True` → output dict `{"raw", "parsed", "parsing_error"}` and parse errors
are captured, not raised; `include_raw=False` → parse errors raise. Default
implementation composes `bind_tools` + a tools output parser.

**`BaseLLM`/`LLM` (llms.py 1,569) [S].** Legacy text-completion interface, string
in/out, same caching+streaming machinery. Lower priority for v1 (chat-first).

**`_compat_bridge.py` (844 LOC) [S].** Bridges v0 (`additional_kwargs`-encoded) and v1
(content-block) message representations via `output_version`. Critical for
round-tripping provider outputs. A meaty, translation-heavy module.

**Error behavior.** Model errors trigger `on_llm_error` callbacks and propagate;
`generate` collects per-prompt exceptions when `run_manager` present. Rate limiting via
optional `rate_limiter.acquire()` before the call (not surfaced in tracing).

---

## 4. Prompts

**What it does.** Templated construction of prompt strings and message lists; all are
`RunnableSerializable` (`invoke(dict) -> PromptValue`).

**Contracts [S/T].** `BasePromptTemplate` declares `input_variables`,
`optional_variables`, `partial_variables`, and `format`/`aformat`,
`format_prompt`→`PromptValue`. `PromptTemplate` (string) supports **three template
formats** (`prompts/string.py:30`): `"f-string"` (default, via `utils/formatting`),
`"mustache"` (vendored engine `utils/mustache.py`), `"jinja2"` (**optional dep**,
sandboxed, ImportError if not installed). Input variables are auto-detected from the
template per format. `ChatPromptTemplate` (chat.py 1,495) composes message templates +
`MessagesPlaceholder` (injects a runtime message list, `optional` flag). `.partial()`
pre-binds variables. `+` concatenates templates/messages into a ChatPromptTemplate.
`FewShotPromptTemplate` interpolates examples (optionally via an ExampleSelector).
`StructuredPrompt` binds an output schema. Snapshot-tested (`test_chat.ambr`,
`test_prompt.ambr` — 10 snapshots): serialized template shape is frozen. Tests:
`prompts/` (11 files, 164 tests).

**Error behavior.** Missing required input variable → `KeyError`/`ValueError` at
format time. `check_valid_template` validates variable sets against the format up front.

---

## 5. Output parsers

**What it does.** Runnables that parse model output (str or Message) into structured
values, with streaming support.

**Contract hierarchy [S] `output_parsers/base.py`.**
`BaseLLMOutputParser` (abstract `parse_result(list[Generation]) -> T`) →
`BaseGenerationOutputParser` (Runnable over Generation) and `BaseOutputParser`
(abstract `parse(text) -> T`, Runnable over str/Message). `BaseTransformOutputParser`
(transform.py) parses a **stream** of chunks. `BaseCumulativeTransformOutputParser`
re-parses the **accumulated** text on each chunk and emits diffs.

**Streaming/diff semantics [S].** `JsonOutputParser` and openai tools/functions
parsers use **jsonpatch** to emit only the delta between the previously-parsed partial
object and the newly-parsed one (`output_parsers/json.py`,
`openai_functions.py`, uses `utils/json.parse_partial_json` to tolerate incomplete
JSON mid-stream). This is a key streaming behavior: consumers see incremental object
growth, not repeated full objects.

**Concrete parsers.** `StrOutputParser` (identity→text), `JsonOutputParser`
(+partial), `PydanticOutputParser` (validate into a model, emits format instructions),
`XMLOutputParser`, `CommaSeparatedListOutputParser`/`NumberedListOutputParser`/
`MarkdownListOutputParser`, `JsonOutputToolsParser`/`PydanticToolsParser`/
`JsonOutputKeyToolsParser` (from AIMessage.tool_calls). **Error behavior:** parse
failure raises `OutputParserException` (carries `llm_output`, `observation`,
`send_to_llm` flag for auto-fix loops). Tests: `output_parsers/` (8 files, 75 tests).

---

## 6. Tools

**What it does.** `BaseTool` (`tools/base.py:427`) is a
`RunnableSerializable[str|dict|ToolCall, Any]` — a callable with a validated
`args_schema` (Pydantic) that a model can invoke.

**Contract [S/T].** Subclass implements `_run` (and optionally `_arun`). `run`/`arun`
(`base.py:977,1105`) parse input via `_parse_input` (str→single-arg, dict→kwargs,
ToolCall→kwargs+inject id), validate against `args_schema`, invoke `_run`, and fire
`on_tool_start`/`on_tool_end`/`on_tool_error` callbacks. `invoke`/`ainvoke` delegate to
run/arun. Returns content; when invoked with a `ToolCall`, returns a `ToolMessage`
(with `tool_call_id`). `ToolException` raised inside a tool is handled per
`handle_tool_error` (bool | str | callable) → error string in the ToolMessage rather
than propagating. Tests: `test_tools.py` (**140 tests**, 4,065 LOC — a top-3 spec).

**`@tool` decorator + converters [S] `tools/convert.py`.** Builds `StructuredTool`
from a function: infers `args_schema` from type hints/docstring (Google-style parsed),
name from fn name, description from docstring. `convert_runnable_to_tool` wraps any
Runnable as a tool. `InjectedToolArg`/`InjectedToolCallId` mark params that are
injected by the runtime (not model-provided) and excluded from the model-facing schema.

**Schema generation [S] `utils/function_calling.py` (847 LOC).**
`convert_to_openai_tool`/`convert_to_openai_function` turn a Pydantic model / TypedDict
/ function / BaseTool into an OpenAI-format JSON tool schema. Handles `$ref`
dereferencing (`utils/json_schema.dereference_refs`), title stripping, and
description propagation. **This is where pydantic's JSON-schema generation leaks into
the public contract** — the exact emitted schema shape is model-facing.

---

## 7. Callbacks

**What it does.** Synchronous + asynchronous observer system for the whole execution
lifecycle. `BaseCallbackHandler` (`callbacks/base.py`) + `AsyncCallbackHandler`.

**Event surface [S].** Handler hooks (each sync + async):
`on_llm_start`, `on_chat_model_start`, `on_llm_new_token`, `on_llm_end`,
`on_llm_error`, `on_chain_start/_end/_error`, `on_tool_start/_end/_error`,
`on_retriever_start/_end/_error`, `on_agent_action`, `on_agent_finish`, `on_text`,
`on_retry`, `on_custom_event`, `on_stream_event`. Ignore-flags
(`ignore_llm`/`ignore_chain`/`ignore_agent`/`ignore_retriever`) let a handler opt out.

**Manager contract [S] `callbacks/manager.py` (2,826 LOC).** `CallbackManager` fans an
event out to all registered handlers; `configure()` merges inheritable vs local
handlers/tags/metadata from `RunnableConfig`. On `on_*_start` it returns a scoped
`*ForRun` manager bound to a `run_id`/`parent_run_id` (the run tree). Handler
exceptions are caught and logged (a bad handler shouldn't crash the run) unless
`raise_error`. Async manager runs handlers concurrently. Emits `langchain_protocol`
`MessagesData` on message events (new in 1.4). Tests: `callbacks/` (6 files, 20 tests).

**Invariant.** Every Runnable run creates exactly one run node with a UUID and parent
linkage; this run tree is what tracers materialize.

---

## 8. Documents / Retrievers / VectorStores / Embeddings

**`Document` [S] `documents/`.** `page_content: str`, `metadata: dict`, `id: str|None`;
Serializable. `BaseDocumentTransformer`, `BaseDocumentCompressor`.

**`BaseRetriever` [S] `retrievers.py:55`.** A `RunnableSerializable[str, list[Document]]`,
ABC. Subclass implements `_get_relevant_documents` (+ async). `invoke(query)` wraps it
with retriever callbacks (`on_retriever_start/_end`). LangSmith params exposed for
tracing. `get_relevant_documents` is deprecated alias.

**`VectorStore` [S] `vectorstores/base.py`.** ABC. `add_texts` and `similarity_search`
and `from_texts` are the core abstract-ish methods; `add_documents`,
`similarity_search_with_score`, `similarity_search_with_relevance_scores` (normalizes
via `_select_relevance_score_fn`), `max_marginal_relevance_search` (MMR, needs
embeddings), `similarity_search_by_vector`, `delete`, `as_retriever` →
`VectorStoreRetriever` (supports search_type `similarity`/`mmr`/
`similarity_score_threshold`). `InMemoryVectorStore` uses numpy for cosine.
Tests: `vectorstores/` (3 files, 32 tests).

**`Embeddings` [S] `embeddings/embeddings.py`.** ABC with abstract `embed_documents`
(list[str]→list[list[float]]) and `embed_query` (str→list[float]); default async wraps
sync. `FakeEmbeddings`/`DeterministicFakeEmbedding` for tests.

---

## 9. Rate limiters

`BaseRateLimiter` (`rate_limiters.py:11`) ABC with `acquire(blocking)` + `aacquire`.
`InMemoryRateLimiter` is a **token-bucket**: `requests_per_second` refill,
`max_bucket_size`, `check_every_n_seconds`. `blocking=True` sleeps until a token is
available; `False` returns immediately. **Explicitly documented limitation:** wait time
is *not* surfaced in tracing/callbacks. Thread-safe (lock) + asyncio variant.
Tests: `rate_limiters/` (1 file, ~few tests) + language_models rate-limit tests.

---

## 10. Tracers

**What it does.** Callback handlers that build/emit a run tree. `BaseTracer`
(`tracers/base.py`) accumulates `Run` objects; concrete tracers: `LangChainTracer`
(posts to LangSmith), `ConsoleCallbackHandler`, `LoggingCallbackHandler`,
`RootListenersTracer` (fires on_start/on_end/on_error listeners),
`EvaluatorCallbackHandler`, `RunCollectorCallbackHandler`.

**`astream_events` (v1/v2) [S] `tracers/event_stream.py` (1,105).** Attaches a
streaming tracer to a run and yields typed `StreamEvent` dicts
(`{event, name, run_id, tags, metadata, data}`) for every lifecycle transition of every
nested Runnable, interleaved with token streaming. v2 is the current default. Tested by
`test_runnable_events_v1.py` (20) and `_v2.py` (36) — **large, authoritative streaming
spec**.

**`astream_log` [S] `tracers/log_stream.py` (769).** Uses **jsonpatch** to emit
`RunLogPatch` objects (RFC-6902 patches) that a client applies to reconstruct a
`RunLog` run-tree state incrementally. Ordering of patches is the contract.

**Serialization.** Runs serialize to LangSmith's schema; `tracers/schemas.py` is a thin
re-export. LangSmith is the only external SaaS coupling and is out-of-scope to port
(emit-compatible hooks only).

---

## 11. Load / Serialization (LangChain "lc" format)

**What it does.** `load/serializable.py` `Serializable(BaseModel, ABC)` defines the
`lc`-JSON format. `to_json()` → `{"lc":1, "type":"constructor", "id":[namespace...,
ClassName], "kwargs":{...}}` or `{"type":"not_implemented", ...}` /
`{"type":"secret", "id":[SECRET_ID]}`. Only classes returning
`is_lc_serializable()==True` serialize (opt-in, security-motivated).

**Contract details [S/T] (`load/test_serializable.py`, 58 tests;
`test_secret_injection.py`, 28 tests).**
- `lc_id()` = `get_lc_namespace()` + class name (pydantic-generic aware).
- `lc_secrets` map: constructor arg → secret id; secret values replaced with
  `{"lc":1,"type":"secret","id":[...]}` and can be re-injected from env on load.
- `lc_attributes`: extra derived attrs to include in kwargs (e.g. AIMessage tool_calls).
- Field pruning: only "useful" fields serialized (`_is_field_useful` — required, or
  truthy, or != default; empty dict/list default omitted).
- `load/load.py` `Reviver`: reconstructs objects by looking up id in
  `SERIALIZABLE_MAPPING` (mapping.py 1,085 — maps legacy/renamed namespaces to current
  classes), enforcing `valid_namespaces`/`secrets_map`, guarding against arbitrary code
  execution (`_validation.py`). `loads`/`load` entry points.
This whole subsystem is the **most serde-contract-heavy** part of core and the strongest
candidate for serde-tagged-enum modelling in Rust.

---

## 12. Utils (behaviorally-load-bearing subset)

- `utils/json.parse_partial_json` — tolerant JSON parse for streaming (closes open
  strings/objects). Contract-relevant to parsers.
- `utils/_merge` — chunk reducers (see §2).
- `utils/mustache.py` — full vendored mustache engine (706 LOC) — must be ported or
  replaced by a Rust mustache crate to preserve template behavior.
- `utils/function_calling` — pydantic→OpenAI tool schema (see §6).
- `utils/pydantic.create_model_v2` — dynamic model creation for input/output schema
  inference (used by Runnable.input_schema/output_schema).
- `utils/aiter`/`iter` — `atee`/`safetee` (stream duplication for astream_events/log),
  `py_anext`. Concurrency primitives.

**Note:** a large fraction of `utils` exists to paper over Python dynamism (pydantic
v1/v2 compat, runtime type hint extraction, import utils) and is **ELIMINATE** in Rust.

---

# Pass 7 deepening (2026-07-12) — line-level verification

Deepens §1 (Runnables), §2 (Messages/blocks), §3 (language models), §10 (tracers),
§11 (load). Evidence is now full-read source + specific tests, not sampling.

## D-1. Runnables/base.py full internals (feeds RED-1 Runnable ADR)

Full structural read of all 6,713 lines. `Runnable` ABC declares one `@abstractmethod`
(`invoke`, base.py:874) and ~60 concrete/overloaded methods. Confirmed the concrete
subtype set and their exact composition seams:

**Modifier constructors (all return a new Runnable) — exact targets [S]:**
- `.bind(**kwargs)` → `RunnableBinding(bound=self, kwargs=kwargs, config={})` (base.py:1871).
- `.with_config(config, **kw)` → `RunnableBinding` with merged `{**config, **kw}` into `config`.
- `.with_listeners(on_start/on_end/on_error)` → `RunnableBinding` with a **`config_factories`**
  entry (a `list[Callable[[RunnableConfig], RunnableConfig]]`) that injects a
  `RootListenersTracer` callback (base.py:1954). `.with_alisteners` uses `AsyncRootListenersTracer`.
  **Pass 1 missed the `config_factories` vector entirely** — see contradiction C-6.
- `.with_types(input_type, output_type)` → `RunnableBinding` with `custom_input_type`/
  `custom_output_type`.
- `.with_retry(...)` → `RunnableRetry` (runnables/retry.py). **Defaults:**
  `retry_if_exception_type=(Exception,)`, `wait_exponential_jitter=True`,
  `stop_after_attempt=3`, `exponential_jitter_params=None` (tenacity `initial/max/exp_base/jitter`).
  Pass 1 did not record these defaults.
- `.map()` → `RunnableEach(bound=self)`.
- `.with_fallbacks(fallbacks, exceptions_to_handle=(Exception,), exception_key=None)` →
  `RunnableWithFallbacks`. **`exception_key`**: when set, the handled exception is injected
  into the fallback's *input dict* under that key (so fallbacks can see what failed); requires
  dict input. Pass 1 omitted `exception_key`.
- `.as_tool(args_schema=None, name, description, arg_types)` → `convert_runnable_to_tool`.
  Schema inferred from `get_input_schema` unless `args_schema`/`arg_types` given.
- `.configurable_fields(**kw)` → `RunnableConfigurableFields`; **raises `ValueError`** if a
  key is not in `type(self).model_fields` (validated eagerly at construction, base.py:2891).
- `.configurable_alternatives(which, default_key="default", prefix_keys=False, **alts)` →
  `RunnableConfigurableAlternatives`; alternatives may be a `Runnable` or a
  `Callable[[], Runnable]` (lazy).

**`RunnableBinding` has FOUR override vectors** (base.py:5849-5880), not one: `kwargs`
(call-time kwargs merged into every invoke/stream), `config` (bound config), `config_factories`
(dynamic config derived from the merged config — the listeners seam), and
`custom_input_type`/`custom_output_type`. `_merge_configs` (base.py:5991) applies `config`
then folds each `config_factory(config)` on top. `RunnableBinding.__getattr__` (base.py:6537)
**transparently delegates attribute access to `self.bound`**, and if the delegated attr is a
callable with a `config` parameter, wraps it to merge the binding's config in — a pure Python
dynamic-dispatch trick with **no Rust analog** (ELIMINATE/redesign; see rust-strategy D-1).

**`RunnableGenerator`** (base.py:4387) wraps a generator function
`Iterator[Input]->Iterator[Output]` (or async). Constructor **raises `TypeError`** if the arg
is not a (sync or async) generator function (`inspect.isgeneratorfunction`/`is_async_generator`,
base.py:4504-4515). It is the transform-native primitive: it streams as input arrives.
Contrast `RunnableLambda`, which buffers the full input before emitting (used when a step needs
the whole input, e.g. LLM prompts).

**`coerce_to_runnable`** (base.py:6628) is the universal `|`/dict/callable coercion:
`Runnable`→as-is; generator-fn→`RunnableGenerator`; other callable→`RunnableLambda`;
`dict`→`RunnableParallel`; else `TypeError`. The `@chain` decorator (base.py:6679) is just
`RunnableLambda(func)` with the function name as the runnable name.

**Graph introspection**: `get_graph()` builds `Graph` nodes/edges; `RunnableBinding.get_graph`
delegates to `bound.get_graph(self._merge_configs(config))` — bindings are transparent in the
graph (they do not add a node). Snapshot-frozen (see test-inventory).

## D-2. astream_events v2 ordering — line-level (feeds ORA-3)

Verified against `test_runnable_events_v2.py` (36 tests, 2,918 LOC). **Default `version="v2"`**
is asserted by `test_default_is_v2` (reads the signature default). Each event is a dict with a
**fixed 7-key shape**: `{event, name, run_id, parent_ids, tags, metadata, data}`.

**Event-name taxonomy by run type** (the `on_<type>_<phase>` scheme):
- chain: `on_chain_start` / `on_chain_stream` / `on_chain_end`
- chat model: `on_chat_model_start` / `on_chat_model_stream` / `on_chat_model_end`
- LLM (string): `on_llm_start` / `on_llm_stream` / `on_llm_end`
- tool: `on_tool_start` / `on_tool_end` (**no `on_tool_stream`**), plus `on_tool_error`
- prompt: `on_prompt_start` / `on_prompt_end` (**no `on_prompt_stream`** — prompts don't stream)
- retriever: `on_retriever_start` / `on_retriever_end`
- `on_custom_event` (via `adispatch_custom_event`)

**Ordering invariants [T]:**
1. Parent `on_chain_start` (e.g. `RunnableSequence`) fires **before** the first child start;
   parent `on_chain_end` fires **last**.
2. In a streaming sequence, a downstream step's `on_*_start` fires **before** the upstream
   step's `on_*_end` — because the upstream's streamed chunk is piped into the downstream step
   which starts consuming while the upstream is still open (triple-lambda test lines 283-300:
   step-2 `on_chain_start` precedes step-1 `on_chain_end`). This start-before-end interleave is
   the core streaming-ordering contract the Rust port must reproduce.
3. `seq:step:N` tags mark position within a `RunnableSequence` (1-indexed).
4. **Tags accumulate down the tree** (`["my_chain","my_model","seq:step:2"]`); **metadata is
   inherited and merged** (parent `{foo:bar}` + child `{a:b}`), plus LangSmith-derived scalars:
   `ls_model_type="chat"` and `ls_stop="<stop_token>"` (the latter derived from a `.bind(stop=…)`
   kwarg). test lines 949-960.
5. `on_chat_model_start` `data.input` wraps messages as `{"messages": [[...]]}` (list-of-lists).
6. `run_id` is a UUID (tests normalize to `""`); `parent_ids` is the ordered ancestry list.

**`on_tool_error` carries `tool_call_id`** in `data` (new in 1.4): equals the invoking
ToolCall's `id`, or `None` when invoked with a plain dict (tests 2850, 2890).

**Cancellation semantics [T] (tests 2470 break, 2535 cancel):** breaking out of / cancelling
the `astream_events` consumer must (a) cancel the currently-running node (it receives
`CancelledError`), (b) propagate `CancelledError` into the outer chain generator for cleanup,
and (c) **never start downstream nodes**. Concretely: node running at break-time is cancelled
(`cancelled=True`), the node that already finished is not, and the next node's `started` stays
`False`. Rust maps this to cancellation-on-drop of the stream future, but the **cleanup
ordering** (outer generator observes cancellation and re-raises) is a hard requirement.

## D-3. `.content_blocks` translator architecture — CORRECTED (feeds §2, ORA-1)

Pass 1 described a single best-effort pipeline. The real architecture is a **registry +
fixed-pipeline hybrid** (contradiction C-3):

1. **`PROVIDER_TRANSLATORS` registry** (`block_translators/__init__.py:23`): a
   `dict[str, {translate_content, translate_content_chunk}]` keyed by provider name. Populated
   at import by `_register_translators()` (which calls `register_translator(provider, …)`), and
   **external integration packages call `register_translator` to add their own** — a runtime
   plugin extension seam (partner-crate relevant).
2. **`AIMessage.content_blocks` / `AIMessageChunk.content_blocks` dispatch** (ai.py):
   (a) if `response_metadata["output_version"]=="v1"` **and** `content` is a `list` → short-circuit,
   return content cast as blocks (assumed already normalized); note the guard is list-only
   because some v1 streams keep `content` as a string (OpenAI Chat Completions) and must fall
   through to rebuild blocks from `tool_calls`/`tool_call_chunks` — else tool calls are silently
   dropped. (b) else if `model_provider` is registered → use the provider translator. (c) else →
   fall back to `BaseMessage.content_blocks`.
3. **`BaseMessage.content_blocks` best-effort fallback** (base.py:200): first pass converts
   `str`→`{type:text}`, unknown-`type` dicts or any dict with a `source_type` key →
   `{type:non_standard}`, known v1 types passthrough; then runs a **fixed 5-stage pipeline** over
   the whole block list, in this order: `langchain_v0` (v0 multimodal) → `openai` (chat
   completions) → `anthropic` → `google_genai` → `bedrock_converse`. Each stage attempts to
   unpack remaining `non_standard` blocks.

`langchain_v0` is deliberately **not** in `PROVIDER_TRANSLATORS` (it is v0-input parsing only).
`bedrock`, `groq`, `google_vertexai` translators exist and are registry-only (not in the base
fallback pipeline). Rust port needs BOTH mechanisms: a provider registry (plugin seam) and the
ordered fallback pipeline.

## D-4. trim_messages — verified signature + scope correction (feeds §2)

`trim_messages` (utils.py:1133) has **21 dedicated tests** (not 145 — that is the whole
`test_utils.py` file: 21 trim, 33 convert, 6 merge, 3 filter, ~82 other). Full signature
(all-keyword after `messages`):
`max_tokens: int` (required), `token_counter` (callable-of-list | callable-of-one |
`BaseLanguageModel` | **`Literal["approximate"]`** — a built-in char/4 approximate counter,
`count_tokens_approximately`), `strategy: "first"|"last"="last"`, `allow_partial=False`,
`end_on`/`start_on` (type/name boundary filters — a trimmed window must end/start on these
message kinds), `include_system=False`, `text_splitter` (for splitting a partial message when
`allow_partial`). Pass 1 omitted `token_counter="approximate"`, `start_on`/`end_on`, and
`text_splitter`; these are behavior-bearing and must be ported.

## D-5. _compat_bridge.py — coverage CORRECTED (feeds §3)

There **is** a dedicated spec: `tests/unit_tests/language_models/test_compat_bridge.py`
(**43 tests, 1,403 LOC**) — contradiction C-2. The bridge's public surface is 3 functions:
`finalize_tool_call_chunk` (_compat_bridge.py:359), `chunks_to_events` (:590),
`message_to_events` (:776) — i.e. it converts core `AIMessage`/`AIMessageChunk`
streams ↔ `langchain_protocol` `MessagesData` wire events (message-start / content-block-
start/delta/finish / message-finish). It exists **only** to launder between the two
structurally-near-isomorphic but nominally-distinct `ContentBlock` unions
(`langchain_core.messages.content` vs `langchain_protocol.protocol`); its own docstring says
"when the Unions are unified, this helper can be deleted." **In Rust the two unions should be a
single type, collapsing most of this module** (see rust-strategy D-5).

## D-6. langchain_protocol scope — MASSIVELY understated by Pass 1 (feeds §3, R7)

See dependency-disposition Pass 7 deepening for the full inventory. Bottom line for behavioral
intent: **langchain-core imports only the `MessagesData` content-block subset** (`MessageStartData`,
`ContentBlockStartData/DeltaData/FinishData`, `MessageFinishData`, `MessageErrorData`) plus the
`ContentBlock`/`FinalizedContentBlock`/`UsageInfo`/`MessageMetadata` types, at exactly 6 import
sites (`chat_models.py`, `_compat_bridge.py`, `chat_model_stream.py`, `callbacks/base.py`,
`callbacks/manager.py`). The rest of the package (the full agent-server JSON-RPC protocol) is
**not used by core**.
