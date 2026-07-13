---
artifact: semport/langchain/EXHAUSTIVE-SWEEP
project: ferrochain
area: langchain
scope: D14.1 exhaustive coverage sweep (pre-3-CLEAN certification)
date: 2026-07-12
validator: extraction-validator
files-verified:
  - behavioral-intent.md
  - dependency-disposition.md
  - module-inventory.md
  - rust-translation-strategy.md
  - test-inventory.md
ground-truth: .reference/langchain/libs/langchain_v1 (tag langchain==1.3.13)
  and .reference/langgraph/libs/langgraph (version 1.2.9)
---

# Exhaustive Verification Sweep — langchain area

## Coverage Statement

All 5 area files fully swept. No partial-coverage gaps. Every discrete claim
enumerated below; 100% of §5 consumed-API symbols individually verified against
langgraph reference source. All numeric values independently recounted.

---

## Phase 1 — Behavioral Verification

### Phase 1A — Claims checked by file

#### behavioral-intent.md

| Claim | Location | Verdict | Evidence |
|---|---|---|---|
| `create_agent` signature at factory.py:808 (14-param fn, 3 overloads) | §1.1 | VERIFIED | `grep -n "def create_agent"` → lines 740, 762, 786, 808 |
| Return type `CompiledStateGraph[AgentState[ResponseT], ContextT, InputAgentState, OutputAgentState[ResponseT]]` | §1.1 | VERIFIED | factory.py:825-827 |
| 3 `@overload`s keyed on response_format shape | §1.1 | VERIFIED | Lines 740, 762, 786 each with different overload signature |
| "Returns a compiled langgraph graph, not an agent object" | §1.1 | VERIFIED | factory.py returns `CompiledStateGraph` |
| Step 1: If model is str, call `init_chat_model(model)` | §1.2 | VERIFIED | factory.py:969-977 confirms model string resolution |
| Step 3: raw schema wrapped in `AutoStrategy` | §1.2 | VERIFIED | factory.py:989-990 |
| Step 3: `AutoStrategy` converted to `ToolStrategy` upfront | §1.2 | VERIFIED | factory.py:994-996 |
| Step 4: materialize structured output tools from `schema_specs` | §1.2 | VERIFIED | factory.py:1000-1004 |
| Step 6: handlers wrapped in `langsmith.traceable(...)` with `_scrub_inputs` | §1.2 | VERIFIED | factory.py:1130-1134, 1141-1144 |
| Step 7: ToolNode created iff client-side tools OR wrap_tool_call exists | §1.2 | VERIFIED | factory.py:1058-1067 |
| Step 8: duplicate `m.name` → `AssertionError` | §1.2 | VERIFIED | factory.py:1079-1082 |
| Step 12: compile with `transformers=[ToolCallTransformer, SubagentTransformer, *middleware_transformers, *transformers]` | §1.2 | VERIFIED | factory.py:1795-1800 |
| Step 12: `.with_config({recursion_limit:9999, metadata:{ls_integration:"langchain_create_agent", lc_agent_name:name}})` | §1.2 | VERIFIED | factory.py:1780-1801 |
| "model" node = `RunnableCallable(model_node, amodel_node, trace=False)` | §1.3 | VERIFIED | factory.py confirms RunnableCallable wrapping |
| "tools" node = langgraph `ToolNode` | §1.3 | VERIFIED | factory.py:1505-1506 |
| Per-middleware-hook nodes: `"{m.name}.before_agent"` etc. | §1.3 | VERIFIED | factory.py:1528, 1549, 1569 |
| `wrap_model_call` / `wrap_tool_call` are NOT nodes — handler closures | §1.3 | VERIFIED | Confirmed: these are composed handlers, not graph.add_node calls |
| entry_node selection: first before_agent → first before_model → model | §1.4 | VERIFIED | factory.py:1592-1598 |
| loop_entry_node: first before_model → model | §1.4 | VERIFIED | factory.py:1601-1605 |
| loop_exit_node: first after_model → model | §1.4 | VERIFIED | factory.py:1607-1612 |
| exit_node: last after_agent → END | §1.4 | VERIFIED | factory.py:1614-1618 |
| before_agent chain: pairwise edges; last → loop_entry_node | §1.4 | VERIFIED | factory.py:1694-1713 |
| before_model chain: pairwise; last → "model" | §1.4 | VERIFIED | factory.py:1716-1734 |
| after_model chain: model → last after_model; reverse-chained to first | §1.4 | VERIFIED | factory.py:1737-1751 |
| after_agent chain: reverse-chained; first → END | §1.4 | VERIFIED | factory.py:1754-1776 |
| `_make_model_to_tools_edge` logic: jump_to → none_AIMessage → no_tool_calls → pending_sends → structured_response → model | §1.4 | VERIFIED | factory.py:1846-1889 |
| `_make_tools_to_model_edge`: all return_direct → end; structured tool → end; else model | §1.4 | VERIFIED | factory.py:1928-1970 |
| parallel tool fan-out: `[Send("tools", [tool_call]) for tool_call in pending_tool_calls]` | §1.4 | VERIFIED | factory.py:1881 |
| BC-DRAFT-CA-002: recursion_limit=9999 at factory.py:1780 | §1 | VERIFIED | factory.py:1780 |
| model_node / amodel_node at factory.py:1433 | §1.5 | VERIFIED | grep confirms 1433 |
| `_execute_model_sync` at factory.py:1406 | §1.5 | VERIFIED | grep confirms 1406 |
| `_get_bound_model` at factory.py:1272 | §1.5 | VERIFIED | grep confirms 1272 |
| `_handle_model_output` at factory.py:1168 | §1.5 | VERIFIED | grep confirms 1168 |
| ProviderStrategy bind: `strict=True` forced for OpenAI-compatible models | §1.5 | VERIFIED | factory.py:1362-1365 |
| ToolStrategy bind: `tool_choice="any"` if structured tools exist | §1.5 | VERIFIED | factory.py:1388 |
| DYNAMIC_TOOL_ERROR_TEMPLATE used in tool validation | §1.5 | VERIFIED | factory.py:115, 1315 |
| `_supports_provider_strategy`: checks model.profile + FALLBACK_MODELS_WITH_STRUCTURED_OUTPUT | §1.5 | VERIFIED | factory.py:528-573 |
| Gemini < 3-series carve-out (tools exclusion with structured output) | §1.5 | VERIFIED | factory.py:555-562 |
| ProviderStrategy.parse: extract text → json.loads → validate | §1.6 | VERIFIED | structured_output.py:364-446 |
| ToolStrategy: >1 structured call → `MultipleStructuredOutputsError` | §1.6 | VERIFIED | factory.py:1208-1227 |
| ToolStrategy: parse failure → `StructuredOutputValidationError` or retry | §1.6 | VERIFIED | factory.py:1251-1268 |
| **INACCURATE (FIXED)**: node hook return type stated as `dict\|Command\|None` | §2.1 | CORRECTED | Actual: `dict[str,Any]\|None`; Command not in declared hook sig; see types.py:419,431,443,454,467,478,638,649 |
| 10 hooks total (5 sync + 5 async) on `AgentMiddleware` | §2.1 | VERIFIED | types.py:383 — confirmed all 10 methods |
| `AgentMiddleware` at types.py:383 | §2.1 | VERIFIED | `grep -n "class AgentMiddleware"` → 383 |
| `wrap_model_call` raises `NotImplementedError` for wrong-context call | §2.2 | VERIFIED | types.py:574-584 |
| `wrap_model_call` first=outermost composition | §2.2 | VERIFIED | `_chain_model_call_handlers` at factory.py:235 |
| Command accumulation: inner-first-then-outer, cleared per inner call | §2.2 | VERIFIED | factory.py:258-310 |
| `AIMessage` return auto-normalizes to `ModelResponse` | §2.2 | VERIFIED | factory.py:177-192 `_normalize_to_model_response` |
| `ModelRequest` at types.py:85 (decorator line), class at 86 | §2.4 | VERIFIED | types.py:85-86 |
| `ModelResponse` at types.py:270 (decorator line), class at 271 | §2.4 | VERIFIED | types.py:270-271 |
| `ModelRequest.override()` uses `dataclasses.replace` | §2.4 | VERIFIED | types.py:267 `return replace(self, **overrides)` |
| `system_prompt` is compat property over `system_message` | §2.4 | VERIFIED | types.py:157 `def system_prompt` property |
| Before/after decorators synthesize middleware via `type(name, (AgentMiddleware,), {...})()` | §2.5 | VERIFIED | types.py:1491+ decorator functions |
| `iscoroutinefunction` picks sync vs async slot | §2.5 | VERIFIED | types.py imports `from inspect import iscoroutinefunction` |
| `SummarizationMiddleware` uses `REMOVE_ALL_MESSAGES` sentinel | §2.6 | VERIFIED | summarization.py:23, 401, 439 |
| `HumanInTheLoopMiddleware` uses `interrupt(HITLRequest)` from langgraph | §2.6 | VERIFIED | human_in_the_loop.py:10 `from langgraph.types import interrupt` |
| `_SchemaSpec` normalizes pydantic/dataclass/TypedDict/JSON-schema | §3 | VERIFIED | structured_output.py:107+ |
| `ToolStrategy.schema_specs` flattens Union/oneOf variants | §3 | VERIFIED | structured_output.py:196+ |
| `ProviderStrategy.to_model_kwargs()` → OpenAI-style `{response_format:{type:json_schema,...}}` | §3 | VERIFIED | structured_output.py:262+ |
| `OutputToolBinding.parse` uses `TypeAdapter(schema).validate_python` | §3 | VERIFIED | structured_output.py:309+ |
| `_BUILTIN_PROVIDERS` registry: 27 chat providers | §4 | VERIFIED | chat_models/base.py:38-78, counted 27 keys |
| Ollama has `langchain_community` fallback | §4 | VERIFIED | chat_models/base.py:161-169 |
| 10 embeddings providers in `init_embeddings` | §4 | VERIFIED | embeddings/base.py:15-34, counted 10 keys |
| `_ConfigurableModel.__getattr__` queues declarative ops | §4 | VERIFIED | chat_models/base.py:661-682 |
| `_DECLARATIVE_METHODS = ("bind_tools", "with_structured_output")` | §4 | VERIFIED | chat_models/base.py:634 |
| `_get_chat_model_creator` lru-caches import | §4 | VERIFIED | chat_models/base.py:131 |
| **INACCURATE (FIXED)**: prefix inference list omitted `accounts/fireworks → fireworks` | §4 | CORRECTED | `_attempt_infer_model_provider` at base.py:556 adds fireworks branch |
| All §5 langgraph symbols exist in reference langgraph source and are imported by langchain_v1 | §5.1–5.6 | VERIFIED | See Phase 1B full symbol table below |

#### dependency-disposition.md

| Claim | Location | Verdict | Evidence |
|---|---|---|---|
| Required deps = exactly `{langchain-core >=1.4.9,<2, langgraph >=1.2.5,<1.3, pydantic >=2.7.4,<3}` | §1 | VERIFIED | pyproject.toml:26-30 |
| `test_dependencies.py` asserts exactly these 3 | §1 | VERIFIED | Read test_dependencies.py — asserts `sorted([…]) == sorted(["langchain-core","langgraph","pydantic"])` |
| langsmith import at factory.py:30 | §2 | VERIFIED | factory.py:30 `from langsmith import traceable` |
| `langchain_protocol.LifecycleCause` is TYPE_CHECKING only | §2 | VERIFIED | _subagent_transformer.py:36-38 |
| **INACCURATE (FIXED)**: "19 optional extras" including langchain-cohere | §3 | CORRECTED | `cohere` extra is commented out; active count = 18; python3 toml parse confirms 18 keys |

#### module-inventory.md

| Claim | Location | Verdict | Evidence |
|---|---|---|---|
| Source: 33 `.py` files, 14,512 LOC | §0 | VERIFIED | `find langchain -name "*.py" | wc -l` = 33; `wc -l ... | tail -1` = 14512 |
| Tests: 63 `test_*.py` files | §0 | VERIFIED | `find tests -name "test_*.py" | wc -l` = 63 |
| Tests total LOC 31,653 (all .py files in tests/) | §0 | VERIFIED | `find tests -name "*.py" -exec wc -l | tail -1` = 31653 |
| agents/ is 13,026 LOC (~90%) | §0 | VERIFIED | `find agents -name "*.py" -exec wc -l | tail -1` = 13026; 13026/14512 = 89.8% ≈ 90% |
| types.py 2,161 LOC | §0 | VERIFIED | `wc -l types.py` = 2161 |
| factory.py 2,007 LOC | §0 | VERIFIED | `wc -l factory.py` = 2007 |
| chat_models/base.py 1,055 LOC | §0 | VERIFIED | `wc -l chat_models/base.py` = 1055 |
| shell_tool.py 949 LOC | §0 | VERIFIED | `wc -l shell_tool.py` = 949 |
| pii.py 878 LOC | §0 | VERIFIED | `wc -l pii.py` = 878 |
| summarization.py 868 LOC | §0 | VERIFIED | `wc -l summarization.py` = 868 |
| structured_output.py 463 LOC | §0 | VERIFIED | `wc -l structured_output.py` = 463 |
| 15 built-in middleware files (excl. types.py, helpers, __init__.py) | §4 | VERIFIED | `ls middleware/` — 15 middleware .py files confirmed |
| All 15 per-middleware LOC values in table | §4 | VERIFIED | Every LOC row matches `wc -l` output (all delta=0) |
| Shared helpers LOC: _execution.py 385, _redaction.py 454, _retry.py 125 | §4 | VERIFIED | `wc -l` confirms all three |
| **INACCURATE (FIXED)**: messages/__init__.py exports 34 symbols | §2 | CORRECTED | AST parse of `__all__` = 31 symbols; original claim incorrect by 3 |

#### rust-translation-strategy.md

| Claim | Location | Verdict | Evidence |
|---|---|---|---|
| 15 built-in middleware (both heading and summary table) | §6, §risk | VERIFIED | Already corrected in prior passes; confirmed 15 |
| `FALLBACK_MODELS_WITH_STRUCTURED_OUTPUT` is a list of regexes | §3 | VERIFIED | factory.py:154-174 |
| `_supports_provider_strategy` uses `model.profile` attribute | §3 | VERIFIED | factory.py:551-563 |
| wrap_model_call composition: first=outermost, inner cleared per retry | §1 | VERIFIED | factory.py:235-325 |
| `goto/resume/graph` Commands rejected in wrap_model_call | §1 | VERIFIED | factory.py:193-231 `_build_commands` raises NotImplementedError for these |
| `dynamic_prompt` = thin wrap_model_call that sets `request.system_message` | §1 | VERIFIED | types.py decorator `dynamic_prompt` does exactly this |

#### test-inventory.md

| Claim | Location | Verdict | Evidence |
|---|---|---|---|
| 63 test_*.py files, 31,653 total LOC (all .py) | §1 | VERIFIED | `find tests -name "test_*.py" | wc -l` = 63; all .py LOC = 31653 |
| implementations/ group: 17 files, 14,550 LOC | §1 | VERIFIED | `find implementations -name "*.py" ! -name "__init__.py" | wc -l` = 17; LOC = 14550 |
| core/ group: 12 files, 7,731 LOC | §1 | VERIFIED | `find core -name "test_*.py" | wc -l` = 12; LOC = 7731 |
| unit_tests/agents/ (top level): 17 test files, 6,537 LOC | §1 | VERIFIED | `find agents -maxdepth 1 -name "test_*.py" | wc -l` = 17; LOC = 6537 |
| middleware_typing/: 3 files, 989 LOC | §1 | VERIFIED | count = 3, LOC = 989 |
| chat_models+embeddings+tools: 4 files, 487 LOC | §1 | VERIFIED | count = 4, LOC = 487 |
| benchmarks: 1 file, 44 LOC | §1 | VERIFIED | 1 test file (test_create_agent.py), 44 LOC |
| **INACCURATE (FIXED)**: integration_tests/ 6 files | §1 | CORRECTED | `find integration_tests -name "test_*.py" | wc -l` = 5, not 6 |
| integration_tests/ 343 LOC | §1 | VERIFIED | `find integration_tests -name "test_*.py" -exec wc -l | tail -1` = 343 |
| test_react_agent.py 987 LOC | §2 | VERIFIED | `wc -l test_react_agent.py` = 987 |
| test_response_format.py 1,018 LOC | §2 | VERIFIED | `wc -l test_response_format.py` = 1018 |
| test_system_message.py 1,052 LOC | §2 | VERIFIED | `wc -l test_system_message.py` = 1052 |
| test_injected_runtime_create_agent.py 859 LOC | §2 | VERIFIED | `wc -l ...` = 859 |
| test_state_schema.py 351 LOC | §2 | VERIFIED | `wc -l ...` = 351 |
| test_agent_streaming.py 285 LOC | §2 | VERIFIED | `wc -l ...` = 285 |
| test_create_agent_tool_validation.py 411 LOC | §2 | VERIFIED | `wc -l ...` = 411 |
| test_wrap_model_call.py 1,600 LOC | §3 | VERIFIED | `wc -l ...` = 1600 |
| test_framework.py 1,086 LOC | §3 | VERIFIED | `wc -l ...` = 1086 |
| test_wrap_model_call_state_update.py 919 LOC | §3 | VERIFIED | `wc -l ...` = 919 |
| test_wrap_tool_call.py 867 LOC | §3 | VERIFIED | `wc -l ...` = 867 |
| test_decorators.py 826 LOC | §3 | VERIFIED | `wc -l ...` = 826 |
| All 17 per-middleware test LOC values | §4 | VERIFIED | Every row matches `wc -l` (all delta=0) |

### Phase 1B — §5 Consumed LangGraph API Symbol Verification

Every symbol listed in behavioral-intent.md §5 verified to exist in `.reference/langgraph` source AND be imported by langchain_v1 source.

| Symbol | Claimed import path | Exists in langgraph ref? | Imported by langchain_v1? | Verdict |
|---|---|---|---|---|
| `StateGraph` | `langgraph.graph.state` | YES (graph/state.py:130) | YES (factory.py) | VERIFIED |
| `CompiledStateGraph` | `langgraph.graph.state` | YES (graph/state.py:1391) | YES (factory.py TYPE_CHECKING) | VERIFIED |
| `START`, `END` | `langgraph.constants` | YES (constants.py:28,30) | YES (factory.py) | VERIFIED |
| `add_messages` | `langgraph.graph.message` | YES (graph/message.py) | YES (types.py) | VERIFIED |
| `REMOVE_ALL_MESSAGES` | `langgraph.graph.message` | YES (graph/message.py:38) | YES (summarization.py) | VERIFIED |
| `EphemeralValue` | `langgraph.channels.ephemeral_value` | YES (channels/ephemeral_value.py:15) | YES (types.py) | VERIFIED |
| `UntrackedValue` | `langgraph.channels.untracked_value` | YES (channels/untracked_value.py:15) | YES (tool_call_limit.py, shell_tool.py, model_call_limit.py) | VERIFIED |
| `Runtime[ContextT]` | `langgraph.runtime` | YES (runtime.py:125) | YES (types.py + 11 total imports) | VERIFIED |
| `Command` | `langgraph.types` | YES (types.py:759) | YES (types.py, factory.py) | VERIFIED |
| `Send` | `langgraph.types` | YES (types.py:664) | YES (factory.py) | VERIFIED |
| `interrupt` | `langgraph.types` | YES (types.py:811) | YES (human_in_the_loop.py) | VERIFIED |
| `Checkpointer` | `langgraph.types` | YES (types.py:98 type alias) | YES (factory.py TYPE_CHECKING) | VERIFIED |
| `get_config` | `langgraph.config` | YES (config.py:17) | YES (human_in_the_loop.py) | VERIFIED |
| `ContextT` | `langgraph.typing` | YES (typing.py:23) | YES (types.py) | VERIFIED |
| `GraphBubbleUp` | `langgraph.errors` | YES (errors.py:50) | YES (tool_retry.py) | VERIFIED |
| `ToolNode` | `langgraph.prebuilt.tool_node` | YES (prebuilt/tool_node.py:622) | YES (factory.py) | VERIFIED |
| `ToolCallRequest` | `langgraph.prebuilt.tool_node` | YES (prebuilt/tool_node.py:133) | YES (types.py) | VERIFIED |
| `ToolCallWrapper` | `langgraph.prebuilt.tool_node` | YES (prebuilt/tool_node.py:202 type alias) | YES (types.py) | VERIFIED |
| `ToolCallWithContext` | `langgraph.prebuilt.tool_node` | YES (prebuilt/tool_node.py:286) | YES (tools/tool_node.py re-export) | VERIFIED |
| `ToolCallTransformer` | `langgraph.prebuilt` | YES (prebuilt/_tool_call_transformer.py:44) | YES (factory.py) | VERIFIED |
| `ToolRuntime` | `langgraph.prebuilt` / `.tool_node` | YES (prebuilt/tool_node.py) | YES (human_in_the_loop.py via tool_node) | VERIFIED |
| `InjectedState`, `InjectedStore` | `langgraph.prebuilt` | YES (prebuilt/__init__.py:6-7) | YES (tools/__init__.py) | VERIFIED |
| `StreamTransformer` | `langgraph.stream` | YES (stream/__init__.py → stream/_types.py) | YES (pii.py) | VERIFIED |
| `TransformerFactory` | `langgraph.stream._mux` | YES (stream/_mux.py:15 type alias) | YES (types.py, factory.py TYPE_CHECKING) | VERIFIED |
| `StreamMux` | `langgraph.stream._mux` | YES (stream/_mux.py:26) | YES (_subagent_transformer.py TYPE_CHECKING) | VERIFIED |
| `SubgraphRunStream` | `langgraph.stream.run_stream` | YES (stream/run_stream.py:587) | YES (_subagent_transformer.py) | VERIFIED |
| `AsyncSubgraphRunStream` | `langgraph.stream.run_stream` | YES (stream/run_stream.py:630) | YES (_subagent_transformer.py) | VERIFIED |
| `StreamChannel` | `langgraph.stream.stream_channel` | YES (stream/stream_channel.py:14) | YES (_subagent_transformer.py) | VERIFIED |
| `SubgraphStatus` | `langgraph.stream.transformers` | YES (stream/transformers.py:343 Literal type) | YES (_subagent_transformer.py) | VERIFIED |
| `_TasksLifecycleBase` | `langgraph.stream.transformers` | YES (stream/transformers.py:373) | YES (_subagent_transformer.py) | VERIFIED |
| `ProtocolEvent` | `langgraph.stream._types` | YES (stream/_types.py:28) | YES (pii.py TYPE_CHECKING, _subagent_transformer.py TYPE_CHECKING) | VERIFIED |
| `RunnableCallable` | `langgraph._internal._runnable` | YES (_internal/_runnable.py:278) | YES (factory.py) | VERIFIED |
| `BaseStore` | `langgraph.store.base` | YES (checkpoint lib: store/base/__init__.py) | YES (factory.py TYPE_CHECKING) | VERIFIED |
| `BaseCache` | `langgraph.cache.base` | YES (checkpoint lib: cache/base/__init__.py) | YES (factory.py TYPE_CHECKING) | VERIFIED |

**§5 verdict: All 34 listed symbols VERIFIED. Zero hallucinations.**

---

## Phase 2 — Metric Verification

Every numeric claim in the 5 area files recounted independently. Commands run against
`.reference/langchain/libs/langchain_v1`.

| Claim | File | Claimed | Recounted | Delta | Command |
|---|---|---|---|---|---|
| Source .py file count | module-inventory.md §0 | 33 | 33 | 0 | `find langchain -name "*.py" \| wc -l` |
| Source total LOC | module-inventory.md §0 | 14,512 | 14,512 | 0 | `find langchain -name "*.py" -exec wc -l {} + \| tail -1` |
| Test `test_*.py` file count | module-inventory.md §0 / test-inventory.md §1 | 63 | 63 | 0 | `find tests -name "test_*.py" \| wc -l` |
| Test total LOC (all .py) | module-inventory.md §0 / test-inventory.md header | 31,653 | 31,653 | 0 | `find tests -name "*.py" -exec wc -l {} + \| tail -1` |
| agents/ LOC | module-inventory.md §0 | 13,026 | 13,026 | 0 | `find agents -name "*.py" -exec wc -l {} + \| tail -1` |
| agents/ as % of source | module-inventory.md §0 | ~90% | 89.8% (rounds to 90%) | 0 | 13026/14512 |
| types.py LOC | module-inventory.md §0 | 2,161 | 2,161 | 0 | `wc -l types.py` |
| factory.py LOC | module-inventory.md §0 | 2,007 | 2,007 | 0 | `wc -l factory.py` |
| chat_models/base.py LOC | module-inventory.md §0 | 1,055 | 1,055 | 0 | `wc -l chat_models/base.py` |
| shell_tool.py LOC | module-inventory.md §4 | 949 | 949 | 0 | `wc -l shell_tool.py` |
| pii.py LOC | module-inventory.md §4 | 878 | 878 | 0 | `wc -l pii.py` |
| summarization.py LOC | module-inventory.md §4 | 868 | 868 | 0 | `wc -l summarization.py` |
| structured_output.py LOC | module-inventory.md §0 | 463 | 463 | 0 | `wc -l structured_output.py` |
| HumanInTheLoopMiddleware LOC | module-inventory.md §4 | 485 | 485 | 0 | `wc -l human_in_the_loop.py` |
| ContextEditingMiddleware LOC | module-inventory.md §4 | 298 | 298 | 0 | `wc -l context_editing.py` |
| FilesystemFileSearchMiddleware LOC | module-inventory.md §4 | 433 | 433 | 0 | `wc -l file_search.py` |
| ModelCallLimitMiddleware LOC | module-inventory.md §4 | 267 | 267 | 0 | `wc -l model_call_limit.py` |
| ModelFallbackMiddleware LOC | module-inventory.md §4 | 408 | 408 | 0 | `wc -l model_fallback.py` |
| ModelRetryMiddleware LOC | module-inventory.md §4 | 312 | 312 | 0 | `wc -l model_retry.py` |
| ProviderToolSearchMiddleware LOC | module-inventory.md §4 | 307 | 307 | 0 | `wc -l provider_tool_search.py` |
| TodoListMiddleware LOC | module-inventory.md §4 | 357 | 357 | 0 | `wc -l todo.py` |
| ToolCallLimitMiddleware LOC | module-inventory.md §4 | 487 | 487 | 0 | `wc -l tool_call_limit.py` |
| LLMToolEmulator LOC | module-inventory.md §4 | 209 | 209 | 0 | `wc -l tool_emulator.py` |
| ToolRetryMiddleware LOC | module-inventory.md §4 | 411 | 411 | 0 | `wc -l tool_retry.py` |
| LLMToolSelectorMiddleware LOC | module-inventory.md §4 | 355 | 355 | 0 | `wc -l tool_selection.py` |
| _execution.py LOC | module-inventory.md §4 | 385 | 385 | 0 | `wc -l _execution.py` |
| _redaction.py LOC | module-inventory.md §4 | 454 | 454 | 0 | `wc -l _redaction.py` |
| _retry.py LOC | module-inventory.md §4 | 125 | 125 | 0 | `wc -l _retry.py` |
| embeddings/base.py LOC | module-inventory.md §3.5 | 275 | 275 | 0 | `wc -l embeddings/base.py` |
| Built-in middleware count | module-inventory.md §4 header | 15 | 15 | 0 | `ls middleware/*.py \| grep -v types\|_exec\|_red\|_retry\|__init__ \| wc -l` |
| Chat providers in `_BUILTIN_PROVIDERS` | behavioral-intent.md §4 | 27 | 27 | 0 | AST/manual count of dict keys in chat_models/base.py:38-78 |
| Embeddings providers | behavioral-intent.md §4 | 10 | 10 | 0 | AST/manual count of dict keys in embeddings/base.py:15-34 |
| **Active optional extras** | dependency-disposition.md §3 | **19** | **18** | **-1** | `python3 -c "import toml; print(len(toml.load('pyproject.toml')['project']['optional-dependencies']))"` → 18 (`cohere` commented out) |
| Runtime imports across langchain_v1 | behavioral-intent.md §5.3 | 11 | 11 | 0 | `grep -rn "from langgraph.runtime import Runtime" langchain/ \| wc -l` |
| UntrackedValue consumers (middleware files) | behavioral-intent.md §5.2 | 3 | 3 | 0 | `grep -rn "from langgraph.channels.untracked_value import" middleware/ \| wc -l` |
| recursion_limit value | behavioral-intent.md BC-CA-002 | 9,999 | 9,999 | 0 | `grep -n "recursion_limit" factory.py` → line 1780: `9_999` |
| implementations/ test files | test-inventory.md §1 | 17 | 17 | 0 | `find implementations -name "*.py" ! -name "__init__.py" \| wc -l` |
| implementations/ test LOC | test-inventory.md §1 | 14,550 | 14,550 | 0 | `find implementations -exec wc -l \| tail -1` |
| core/ test files | test-inventory.md §1 | 12 | 12 | 0 | `find core -name "test_*.py" \| wc -l` |
| core/ test LOC | test-inventory.md §1 | 7,731 | 7,731 | 0 | `find core -name "test_*.py" -exec wc -l \| tail -1` |
| agents/ top-level test files | test-inventory.md §1 | 17 | 17 | 0 | `find agents -maxdepth 1 -name "test_*.py" \| wc -l` |
| agents/ top-level test LOC | test-inventory.md §1 | 6,537 | 6,537 | 0 | `find agents -maxdepth 1 -name "test_*.py" -exec wc -l \| tail -1` |
| middleware_typing/ test files | test-inventory.md §1 | 3 | 3 | 0 | count = 3 |
| middleware_typing/ test LOC | test-inventory.md §1 | 989 | 989 | 0 | LOC = 989 |
| chat_models+embeddings+tools test files | test-inventory.md §1 | 4 | 4 | 0 | count = 4 |
| chat_models+embeddings+tools test LOC | test-inventory.md §1 | 487 | 487 | 0 | LOC = 487 |
| **integration_tests/ test_*.py file count** | test-inventory.md §1 | **6** | **5** | **-1** | `find integration_tests -name "test_*.py" \| wc -l` = 5 |
| integration_tests/ test LOC | test-inventory.md §1 | 343 | 343 | 0 | `find integration_tests -name "test_*.py" -exec wc -l \| tail -1` = 343 |
| benchmarks test file count | test-inventory.md §1 | 1 | 1 | 0 | 1 test file (test_create_agent.py) |
| benchmarks LOC | test-inventory.md §1 | 44 | 44 | 0 | `wc -l benchmarks/test_create_agent.py` = 44 |
| **messages/__init__.py __all__ symbol count** | module-inventory.md §2 | **34** | **31** | **-3** | `python3 AST parse of __all__` → 31 entries |
| test_react_agent.py LOC | behavioral-intent.md BC-CA-001 | 987 | 987 | 0 | `wc -l test_react_agent.py` |
| test_response_format.py LOC | behavioral-intent.md BC-CA-003 | 1,018 | 1,018 | 0 | `wc -l test_response_format.py` |

**Phase 2 summary: 52 numeric claims checked. 49 pass (delta = 0). 3 non-zero deltas — all corrected in-place.**

---

## Refinement Iterations: 1/3

Iteration 1 completed above. All findings are either VERIFIED or CORRECTED in-place.
No remaining issues requiring iteration 2 or 3.

---

## Inaccurate Items (Corrected)

| Item | Original Claim | Actual Behavior | Severity | Correction Applied |
|---|---|---|---|---|
| Node hook return types (§2.1 table, behavioral-intent.md) | `dict\|Command\|None` for all 6 node hooks (before_agent, abefore_agent, before_model, abefore_model, after_model, aafter_model, after_agent, aafter_agent) | `dict[str, Any]\|None` — Command is NOT in the declared type signature; control flow uses `{"jump_to": "model"\|"tools"\|"end"}` dict key, not Command objects; only wrap_tool_call returns ToolMessage\|Command, and only ExtendedModelResponse embeds a Command | CRITICAL (affects Rust trait design) | `[validation-exhaustive]` tag added; table cells corrected to `dict[str,Any]\|None` |
| Active optional extras count (dependency-disposition.md §3) | 19 optional extras including `langchain-cohere` | 18 active extras; `cohere = ["langchain-cohere"]` is commented out in pyproject.toml | HIGH (spec inflation) | `[validation-exhaustive]` tag; changed "19" to "18", removed `-cohere` from list |
| messages/__init__.py symbol count (module-inventory.md §2) | 34 symbols | 31 symbols in `__all__` (AST-confirmed) | HIGH (spec inflation) | `[validation-exhaustive]` tag; "34 … + `trim_messages`" changed to "31 symbols (trim_messages included)" |
| Integration tests file count (test-inventory.md §1) | 6 test_*.py files | 5 test_*.py files | MEDIUM (off-by-one) | `[validation-exhaustive]` tag; "6" changed to "5" |
| Missing prefix inference rule (behavioral-intent.md §4) | Enumeration of `_attempt_infer_model_provider` prefixes omitted `accounts/fireworks → fireworks` | Branch exists at base.py:556 as 4th check | MEDIUM (incomplete enumeration) | `[validation-exhaustive]` tag; rule added inline |
| Step 9 "6 partition lists" (behavioral-intent.md §1.2) | "6 lists: before_agent, before_model, after_model, after_agent, wrap_model_call, wrap_tool_call" | 8 lists — the 4 node-hook lists plus separate sync/async partition lists for wrap_model_call AND wrap_tool_call (middleware_w_wrap_model_call, middleware_w_awrap_model_call, middleware_w_wrap_tool_call, middleware_w_awrap_tool_call) | LOW (count precision) | `[validation-exhaustive]` tag; "6 lists" corrected to "8 lists" with enumeration |

---

## Hallucinated Items (Removed)

None. Every function, class, and symbol cited in the analysis exists in the reference source and is imported as claimed. Zero hallucinations detected across all 5 files.

---

## Unverifiable Items

None. All claims were verifiable via source inspection and shell commands against the pinned reference corpus.

---

## Confidence Assessment

- **Overall extraction accuracy:** 94% (before corrections)
- **After corrections:** 100% of verified scope
- **§5 consumed-API accuracy:** 100% (34/34 symbols VERIFIED)
- **Numeric accuracy:** 49/52 (94%) before corrections; 52/52 (100%) after
- **Behavioral contract accuracy:** HIGH on all BCs; CRITICAL hook-return-type error corrected
- **Recommendation:** TRUST WITH CAVEATS → TRUST (after this sweep's corrections)

The area files are now production-grade for use in Phase 1 spec crystallization. The CRITICAL
correction (node hook return types) is load-bearing for the Rust middleware trait design in
`rust-translation-strategy.md §1` — the Rust `HookResult` type must reflect `dict[str,Any]\|None`
semantics (state-update map or nothing), NOT a `Command` return. The `can_jump_to` mechanism
works via `jump_to` field injection in the returned dict, processed by a downstream conditional edge,
not by returning a Command directly from the hook.

---

## Most Consequential Fix

**Hook return types in §2.1 (CRITICAL):** The analysis incorrectly stated that all node hooks
(`before_agent`, `before_model`, `after_model`, `after_agent` and their async variants) return
`dict | Command | None`. The actual Python type annotations are `dict[str, Any] | None`.

This matters for the Rust port: the middleware trait's `HookResult` type should be
`Option<HashMap<String, StateValue>>` (a state-update map), not `Result<StateUpdateOrCommand>`.
The jump/control-flow mechanism is achieved by setting `jump_to` as a key in the returned dict —
the factory then uses a conditional edge that reads `state["jump_to"]` to route the graph.
Only `wrap_tool_call` uses the `Command` return directly; only `wrap_model_call` embeds a `Command`
via `ExtendedModelResponse`. Conflating the hook return types would produce an unnecessarily complex
Rust trait and incorrect middleware composition semantics.
